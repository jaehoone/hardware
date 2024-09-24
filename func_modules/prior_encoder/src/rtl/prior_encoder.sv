///////////////////////////////////////////////////////////////////////////
//  Copyright 2024 Jaehoon Heo. All rights reserved.
//
//  Name: priority_encoder.sv
//  Description:
//      This module describes the design of a priority encoder, which detects
//      the index of the leading one bit.
//
//  Authors: Jaehoon Heo <kd01050@kaist.ac.kr>
//  Version: 1.0
//  Date: 2024-09-12
//
///////////////////////////////////////////////////////////////////////////

module prior_encoder
#(
    parameter DATA_WIDTH                            = 8,
    parameter INDEX_WIDTH                           = $clog2(DATA_WIDTH)+1
)
(
    input  logic [DATA_WIDTH-1:0]                   data_in,
    output logic [INDEX_WIDTH-1:0]                  idx_out
);

    logic [INDEX_WIDTH-1:0]                         idx;
    logic                                           found;

    assign idx_out                                  = idx;

    always_comb begin
        idx                                         = '0;
        found                                       = 1'b0;

        if(|data_in) begin
            for(int j=DATA_WIDTH-1; j>=0; j--) begin
                if(~found) begin
                    if(data_in[j]) begin
                        idx                         = j+'d1;
                        found                       = 1'b1;
                    end
                end
            end
        end
    end

endmodule