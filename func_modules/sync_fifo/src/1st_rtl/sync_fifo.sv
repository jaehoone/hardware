///////////////////////////////////////////////////////////////////////////
//  Copyright 2024 Jaehoon Heo. All rights reserved.
//
//  Name: sync_fifo.sv
//  Description:
//      This module describes the design of a synchronous fifo.
//
//  Authors: Jaehoon Heo <kd01050@kaist.ac.kr>
//  Version: 1.0
//  Date: 2024-09-30
//
///////////////////////////////////////////////////////////////////////////

module sync_fifo
#(
    parameter DATA_WIDTH                            = 16,
    parameter DEPTH                                 = 64,
    parameter AE_LEVEL                              = 4,
    parameter AF_LEVEL                              = 4
)
(
    input  logic                                    clk,
    input  logic                                    rstn,
    
    // push:
    input  logic                                    push_req_in,
    output logic                                    full_out,
    output logic                                    almost_full_out,
    input  logic [DATA_WIDTH-1:0]                   data_in,

    // pull:
    input  logic                                    pop_req_in,
    output logic                                    empty_out,
    output logic                                    almost_empty_out,
    output logic [DATA_WIDTH-1:0]                   data_out

    // etc.:
    // input  logic                                    diag_n_in,
    // output logic                                    error_out
);

    // //----- Operation Summary -----//
    // wr_pnt >> data write +1: (0 - DEPTH-1)
    // rd_pnt >> data read +1: (0 - DEPTH-1)

    // wr_pnt - rd_pnt = left_data
    // 3b 3b
    // 7  3  4

    // 8  3  5
    // 0  3  -3
    // signed left_num.
    // if negative add 8
    // if positive 5

    // left_data == DEPTH-1: full
    // left_data == 0: empty

    // wr_pnt < rd_pnt >>> error
    // //-----------------------------//

    // Params:
    localparam DEPTH_WIDTH                          = $clog2(DEPTH)+1;

    // Mem:
    logic [DATA_WIDTH-1:0]                          mem[DEPTH-1:0];

    // Regs:
    logic [DEPTH_WIDTH-1:0]                         wr_pnt_ff, wr_pnt_nxt;
    logic [DEPTH_WIDTH-1:0]                         rd_pnt_ff, rd_pnt_nxt;
    logic                                           full_ff;
    logic                                           empty_ff;

    // Wires:
    logic                                           wr_en;
    logic signed [DEPTH_WIDTH:0]                    left_num;

    // I/O:
    assign full_out                                 = full_ff;
    assign almost_full_out                          = (left_num >=  (DEPTH - AF_LEVEL)) ? 1'b1 : 1'b0;
    assign empty_out                                = empty_ff;
    assign almost_empty_out                         = (left_num <= 'd0 + AE_LEVEL) ? 1'b1 : 1'b0;

    assign data_out                                 = mem[rd_pnt_ff];

    // Logic:
    assign left_num                                 = (wr_pnt_ff - rd_pnt_ff < 0) ? wr_pnt_ff - rd_pnt_ff + DEPTH : wr_pnt_ff - rd_pnt_ff;

    always_comb begin
        wr_pnt_nxt                                  = wr_pnt_ff;

        if(push_req_in) begin
            wr_pnt_nxt                              = (wr_pnt_ff == DEPTH-1) ? 'd0 : wr_pnt_ff + 'd1;
        end
    end

    always_comb begin
        rd_pnt_nxt                                  = rd_pnt_ff;

        if(pop_req_in) begin
            rd_pnt_nxt                              = (rd_pnt_ff == DEPTH-1) ? 'd0 : rd_pnt_ff + 'd1;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            full_ff                                 <= 1'b0;
            empty_ff                                <= 1'b0;
        end
        else begin
            full_ff                                 <= (left_num == DEPTH-1) ? 1'b1 : 1'b0;
            empty_ff                                <= (left_num == 'd0) ? 1'b1 : 1'b0;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            wr_pnt_ff                               <= '0;
            rd_pnt_ff                               <= '0;
        end
        else begin
            wr_pnt_ff                               <= wr_pnt_nxt;
            rd_pnt_ff                               <= rd_pnt_nxt;
        end
    end

    always_ff @(posedge clk) begin
        if(push_req_in) begin
            mem[wr_pnt_ff]                          <= data_in;
        end
    end

endmodule