`timescale 1ns/1ps

module tb_barrel_shifter;

    localparam DATA_WIDTH           = 8;
    localparam SHIFT_WIDTH          = (2**$clog2(DATA_WIDTH) == DATA_WIDTH) ? $clog2(DATA_WIDTH) : $clog2(DATA_WIDTH)+1;

    logic [DATA_WIDTH-1:0]          idata;
    logic [SHIFT_WIDTH-1:0]         shift_val;
    logic [DATA_WIDTH-1:0]          odata;

    logic [DATA_WIDTH-1:0]          dw_odata;

    barrel_shifter
    #(
        .DATA_WIDTH                 (DATA_WIDTH)
    )
    ubarrel_shifter
    (
        .data_in                    (idata),
        .shift_val_in               (shift_val),
        .data_out                   (odata)
    );

    DW01_bsh
    #(
        .A_width                    (DATA_WIDTH),
        .SH_width                   (SHIFT_WIDTH)
    )
    U1
    (
        .A                          (idata),
        .SH                         (shift_val),
        .B                          (dw_odata)
    );

    initial $vcdplusfile("vcdplus_rtl.vpd");
    initial $vcdpluson();
    initial $vcdplusmemon();

    initial begin
        idata                       = 'd0;
        shift_val                   = 'd0;
        #10;

        for(int i=0; i<20; i++) begin
            idata                   = $urandom % (2**DATA_WIDTH);
            shift_val               = $urandom % DATA_WIDTH;
            #10;
        end
        
        #100;
        $finish;
    end

endmodule