///////////////////////////////////////////////////////////////////////////
//  Copyright 2024 Jaehoon Heo. All rights reserved.
//
//  Name: gearbox_fifo.sv
//  Description:
//      This module describes the design of a gearbox_fifo (synchronous).
//
//  Authors: Jaehoon Heo <kd01050@kaist.ac.kr>
//  Version: 1.0
//  Date: 2024-10-2
//
///////////////////////////////////////////////////////////////////////////

module gearbox_fifo
#(
    parameter IDATA_WIDTH                           = 16,
    parameter ODATA_WIDTH                           = 64,
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
    input  logic [IDATA_WIDTH-1:0]                  data_in,

    // pull:
    input  logic                                    pop_req_in,
    output logic                                    empty_out,
    output logic                                    almost_empty_out,
    output logic [ODATA_WIDTH-1:0]                  data_out,

    // etc.:
    output logic                                    error_out
);

    //----- Operation Summary -----//
    // multiple FIFOs
    // push >> individual full
    // pop >> combined empty
    
    // e.g., out_width > in_width
    //                      p   
    // |  3  |  2  |  1  |  0  |
    // |     |     |     |     |
    // |     |     |     |     |
    // |     |     |     |     |
    // |     |     |     |     |
    //-----------------------------//

    localparam FIFO_NUM                             = (ODATA_WIDTH >= IDATA_WIDTH) ? (((ODATA_WIDTH%IDATA_WIDTH) == 0) ? (ODATA_WIDTH/IDATA_WIDTH) : (ODATA_WIDTH/IDATA_WIDTH)+1)
                                                      : (((IDATA_WIDTH%ODATA_WIDTH) == 0) ? (IDATA_WIDTH/ODATA_WIDTH) : (IDATA_WIDTH/ODATA_WIDTH)+1);
    localparam FIFO_WIDTH                           = (ODATA_WIDTH >= IDATA_WIDTH) ? IDATA_WIDTH : ODATA_WIDTH;
    localparam FIFO_NUM_WIDTH                       = $clog2(FIFO_NUM);

    // Regs:
    logic [FIFO_NUM_WIDTH-1:0]                      data_pnt_ff, data_pnt_nxt;

    // Wire:
    logic [FIFO_NUM-1:0]                            push_req;
    logic [FIFO_NUM-1:0]                            full;
    logic [FIFO_NUM-1:0]                            almost_full;
    logic [FIFO_NUM-1:0][FIFO_WIDTH-1:0]            idata;
    logic [FIFO_NUM*FIFO_WIDTH-1:0]                 idata_upacked;

    logic [FIFO_NUM-1:0]                            pop_req;
    logic [FIFO_NUM-1:0]                            empty;
    logic [FIFO_NUM-1:0]                            almost_empty;
    logic [FIFO_NUM-1:0][FIFO_WIDTH-1:0]            odata;
    logic [FIFO_NUM*FIFO_WIDTH-1:0]                 odata_upacked;

    logic [FIFO_NUM-1:0]                            error;

    generate
        if(ODATA_WIDTH >= IDATA_WIDTH) begin
            // I/O:
            assign full_out                         = full[data_pnt_ff];
            assign almost_full_out                  = almost_full[data_pnt_ff];
            assign empty_out                        = |empty;
            assign almost_empty_out                 = |almost_empty;
            assign data_out                         = odata_upacked[ODATA_WIDTH-1:0];
            assign error_out                        = |error;

            // Logic:
            // push:
            assign idata                            = {(FIFO_NUM){data_in}};
            always_comb begin
                push_req                            = '0;
                push_req[data_pnt_ff]               = push_req_in;
            end

            // pop:
            assign pop_req                          = {(FIFO_NUM){pop_req_in}};
            assign odata_upacked                    = odata;

            // pnt:
            always_comb begin
                data_pnt_nxt                        = data_pnt_ff;

                if(push_req_in) begin
                    data_pnt_nxt                    = (data_pnt_ff == FIFO_NUM-1) ? 'd0 : data_pnt_ff + 'd1;
                end
            end

            always_ff @(posedge clk or negedge rstn) begin
                if(~rstn) begin
                    data_pnt_ff                     <= '0;
                end
                else begin
                    data_pnt_ff                     <= data_pnt_nxt;
                end
            end
        end
        else begin // ODATA_WIDTH < IDATA_WIDTH
            // I/O:
            assign full_out                         = |full;
            assign almost_full_out                  = |almost_full;
            assign empty_out                        = empty[data_pnt_ff];
            assign almost_empty_out                 = almost_empty[data_pnt_ff];
            assign data_out                         = odata[data_pnt_ff];
            assign error_out                        = |error;

            // Logic:
            // push:
            assign idata_upacked                    = {{(IDATA_WIDTH - FIFO_NUM*FIFO_WIDTH){1'b0}}, data_in}; // Pad with 0 when IDATA_WIDTH is not an exact divisor of ODATA_WIDTH
            assign idata                            = idata_upacked;
            assign push_req                         = {(FIFO_NUM){push_req_in}};

            // pop:
            always_comb begin
                pop_req                             = '0;
                pop_req[data_pnt_ff]                = pop_req_in;
            end

            // pnt:
            always_comb begin
                data_pnt_nxt                        = data_pnt_ff;

                if(pop_req_in) begin
                    data_pnt_nxt                    = (data_pnt_ff == FIFO_NUM-1) ? 'd0 : data_pnt_ff + 'd1;
                end
            end

            always_ff @(posedge clk or negedge rstn) begin
                if(~rstn) begin
                    data_pnt_ff                     <= '0;
                end
                else begin
                    data_pnt_ff                     <= data_pnt_nxt;
                end
            end
        end

        // Inst:
        for(genvar i=0; i<FIFO_NUM; i++) begin
            sync_fifo
            #(
                .DATA_WIDTH                         (FIFO_WIDTH),
                .DEPTH                              (DEPTH),
                .AE_LEVEL                           (AE_LEVEL),
                .AF_LEVEL                           (AF_LEVEL)
            )
            Usync_fifo
            (
                .clk                                (clk),
                .rstn                               (rstn),
                .push_req_in                        (push_req[i]),
                .full_out                           (full[i]),
                .almost_full_out                    (almost_full[i]),
                .data_in                            (idata[i]),
                .pop_req_in                         (pop_req[i]),
                .empty_out                          (empty[i]),
                .almost_empty_out                   (almost_empty[i]),
                .data_out                           (odata[i]),
                .error_out                          (error[i])
            );
        end
    endgenerate

endmodule