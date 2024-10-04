///////////////////////////////////////////////////////////////////////////
//  Copyright 2024 Jaehoon Heo. All rights reserved.
//
//  Name: barrel_shifter.sv
//  Description:
//      This module describes the design of a barrel_shifter.
//
//  Authors: Jaehoon Heo <kd01050@kaist.ac.kr>
//  Version: 1.0
//  Date: 2024-09-12
//
///////////////////////////////////////////////////////////////////////////

module barrel_shifter
#(
    parameter DATA_WIDTH                            = 8,
    parameter SHIFT_WIDTH                           = (2**$clog2(DATA_WIDTH) == DATA_WIDTH) ? $clog2(DATA_WIDTH) : $clog2(DATA_WIDTH)+1
)
(
    input  logic [DATA_WIDTH-1:0]                   data_in,
    input  logic [SHIFT_WIDTH-1:0]                  shift_val_in,
    output logic [DATA_WIDTH-1:0]                   data_out
);

    //----- Operation Summary -----//
    // 1001|1001 << 3
    // 1100|1000

    // Wires:
    logic [2*DATA_WIDTH-1:0]                        data_shifted;

    // I/O:
    assign data_out                                 = data_shifted[(2*DATA_WIDTH-1)-:DATA_WIDTH];

    // Logic:
    assign data_shifted                             = {data_in, data_in} << shift_val_in;

endmodule