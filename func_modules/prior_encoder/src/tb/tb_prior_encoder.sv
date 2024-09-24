`timescale 1ns/1ps

module tb_prior_encoder;

    localparam DATA_WIDTH           = 8;
    localparam INDEX_WIDTH          = $clog2(DATA_WIDTH)+1;

    logic [DATA_WIDTH-1:0]          data;
    logic [INDEX_WIDTH-1:0]         idx;

    prior_encoder
    #(
        .DATA_WIDTH                 (DATA_WIDTH),
        .INDEX_WIDTH                (INDEX_WIDTH)
    )
    Uprior_encoder
    (
        .data_in                    (data),
        .idx_out                    (idx)
    );

    initial $vcdplusfile("vcdplus_rtl.vpd");
    initial $vcdpluson();
    initial $vcdplusmemon();

    initial begin
        data                        = 'd0;
        #10;

        for(int i=0; i<10; i++) begin
            data                    = $urandom % (2**DATA_WIDTH);
            #10;
        end

        data                        = 8'b00000001;
        #10;

        data                        = 'd0;
        #10;
        
        #100;
    end

endmodule