///////////////////////////////////////////////////////////////////////////
//  Copyright 2024 Jaehoon Heo. All rights reserved.
//
//  Name: divider.sv
//  Description:
//      This module describes the design of a divider.
//
//  Authors: Jaehoon Heo <kd01050@kaist.ac.kr>
//  Version: 1.0
//  Date: 2024-09-12
//
///////////////////////////////////////////////////////////////////////////

module divider
#(
    parameter DATA_WIDTH                            = 8
)
(
    input  logic [DATA_WIDTH-1:0]                   numerator_in, // dividend
    input  logic [DATA_WIDTH-1:0]                   denominator_in, // divisor
    input  logic                                    enable_in,
    output logic [DATA_WIDTH-1:0]                   quotient_out,
    output logic [DATA_WIDTH-1:0]                   remainder_out
);

    always_comb begin
        quotient_out                                = '0;
        remainder_out                               = '0;

        if(enable_in) begin
            if(denominator_in != 0) begin
                quotient_out                        = numerator_in / denominator_in;
                remainder_out                       = numerator_in % denominator_in;
            end
            else begin               
                $display("[Error] denominator is zero");
                $fatal;
            end       
        end
    end

endmodule