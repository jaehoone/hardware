///////////////////////////////////////////////////////////////////////////
//  Copyright 2024 Jaehoon Heo. All rights reserved.
//
//  Name: sync_fifo.sv
//  Description:
//      This module describes the design of a synchronous fifo.
//
//  Authors: Jaehoon Heo <kd01050@kaist.ac.kr>
//  Version: 1.0
//  Date: 2024-10-1
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
    output logic [DATA_WIDTH-1:0]                   data_out,

    // etc.:
    output logic                                    error_out
);

    // //----- Operation Summary -----//
    // wrpnt >> data write +1: (0 - DEPTH-1)
    // rdpnt >> data read +1: (0 - DEPTH-1)
    // cnt >> decide empty & full
    // //-----------------------------//

    // Params:
    localparam DEPTH_WIDTH                          = $clog2(DEPTH)+1;

    // Regs:
    struct packed {
        logic [DEPTH_WIDTH-1:0]                     wrpnt;
        logic [DEPTH_WIDTH-1:0]                     rdpnt;
        logic [DEPTH_WIDTH-1:0]                     cnt;
        logic                                       error;
    }regs_ff, regs_nxt;

    // Mems:
    logic [DATA_WIDTH-1:0]                          mem[DEPTH-1:0];

    // Wires:
    logic                                           wrerror;
    logic                                           rderror;

    // I/O:
    assign data_out                                 = mem[regs_ff.rdpnt];
    assign full_out                                 = (regs_ff.cnt == DEPTH) ? 1'b1 : 1'b0;
    assign almost_full_out                          = (regs_ff.cnt >= DEPTH - AF_LEVEL) ? 1'b1 : 1'b0;
    assign empty_out                                = (regs_ff.cnt == 'd0) ? 1'b1 : 1'b0;
    assign almost_empty_out                         = (regs_ff.cnt <= 'd0 + AE_LEVEL) ? 1'b1 : 1'b0;
    assign error_out                                = regs_ff.error;

    // Logic:
    assign wrerror                                  = (push_req_in && (regs_ff.cnt == DEPTH)) ? 1'b1 : 1'b0;
    assign rderror                                  = (pop_req_in && (regs_ff.cnt == 'd0)) ? 1'b1 : 1'b0;

    always_comb begin
        regs_nxt                                    = regs_ff;

        // pnt:
        if(push_req_in) begin
            regs_nxt.wrpnt                          = (regs_ff.wrpnt == DEPTH-1) ? 'd0 : regs_ff.wrpnt + 'd1;
        end
        if(pop_req_in) begin
            regs_nxt.rdpnt                          = (regs_ff.rdpnt == DEPTH-1) ? 'd0 : regs_ff.rdpnt + 'd1;
        end

        // cnt:
        if(push_req_in && ~pop_req_in) begin
            regs_nxt.cnt                            = regs_ff.cnt + 'd1;
        end
        else if(~push_req_in && pop_req_in) begin
            regs_nxt.cnt                            = regs_ff.cnt - 'd1;
        end

        // error:
        regs_nxt.error                              = (~regs_ff.error) ? (wrerror || rderror) : regs_ff.error;
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            regs_ff                                 <= '0;
        end
        else begin
            regs_ff                                 <= regs_nxt;
        end
    end

    always_ff @(posedge clk) begin
        if(push_req_in) begin
            mem[regs_ff.wrpnt]                      <= data_in;
        end
    end

endmodule