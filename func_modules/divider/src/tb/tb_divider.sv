`timescale 1ns/1ps

module tb_divider;

    localparam DATA_WIDTH           = 8;

    logic [DATA_WIDTH-1:0]          numerator; // dividend
    logic [DATA_WIDTH-1:0]          denominator; // divisor
    logic                           enable;
    logic [DATA_WIDTH-1:0]          quotient;
    logic [DATA_WIDTH-1:0]          remainder;

    divider
    #(
        .DATA_WIDTH                 (DATA_WIDTH)
    )
    Udivider
    (
        .numerator_in               (numerator),
        .denominator_in             (denominator),
        .enable_in                  (enable),
        .quotient_out               (quotient),
        .remainder_out              (remainder)
    );

    initial $vcdplusfile("vcdplus_rtl.vpd");
    initial $vcdpluson();
    initial $vcdplusmemon();

    integer random_denom;
    initial begin
        numerator                   =  'd0;
        denominator                 =  'd0;
        enable                      = 1'b0;
        #10;

        for(int i=0; i<10; i++) begin
            enable                  = 1'b1;
            numerator               = $urandom % DATA_WIDTH;

            random_denom            = $urandom % DATA_WIDTH;
            denominator             = (random_denom == 0) ? 'd1 : random_denom;
            #10;
        end
        
        enable                  = 1'b0;
        #100;
        $finish;
    end

endmodule