///////////////////////////////////////////////////////////////////////////
//  Copyright 2024 Jaehoon Heo. All rights reserved.
//
//  Name: doorbell.sv
//  Description:
//      This module describes the design of a doorbell.
//
//  Authors: Jaehoon Heo <kd01050@kaist.ac.kr>
//  Version: 1.0
//  Date: 2024-10-16
//
///////////////////////////////////////////////////////////////////////////

module doorbell
(
    input  logic                                clk,
    input  logic                                rstn,
    input  logic                                set_in,
    input  logic                                done_in,
    output logic                                busy_out
);

    // //----- Operation Summary -----//
    // set_in: ready_out >>> 0 to 1
    // done_in: busy_out >>> 1 to 0

    // Regs:
    logic                                       busy_ff, busy_nxt;

    // Logic:
    assign busy_out                             = busy_ff;

    always_comb begin
        busy_nxt                                = busy_ff;

        if(set_in & ~done_in & ~busy_ff) begin
            busy_nxt                            = 1'b1;
        end
        else if(~set_in & done_in & busy_ff) begin
            busy_nxt                            = 1'b0;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            busy_ff                             <= 1'b0;
        end
        else begin
            busy_ff                             <= busy_nxt;
        end
    end

endmodule