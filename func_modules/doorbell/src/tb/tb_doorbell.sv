`timescale 1ns/1ps

module tb_doorbell;

    localparam CLK_FREQ                 = 200;
    localparam CLK_PERIOD               = 1000/CLK_FREQ; // ns
    localparam CLK_HALF_PERIOD          = CLK_PERIOD/2; // ns

    logic                                clk;
    logic                                rstn;
    logic                                set;
    logic                                done;
    logic                                busy;

    doorbell Udoorbell
    (
        .clk                            (clk),
        .rstn                           (rstn),
        .set_in                         (set),
        .done_in                        (done),
        .busy_out                       (busy)
    );

    initial $vcdplusfile("vcdplus_rtl.vpd");
    initial $vcdpluson();
    initial $vcdplusmemon();

    initial begin
        clk                             = 1'b0;

        #0.1;
        forever clk                     = #(CLK_HALF_PERIOD) ~clk;
    end

    initial begin
        rstn                            = 1'b0;
        set                             = 1'b0;
        done                            = 1'b0;
        repeat (1) @(posedge clk);

        rstn                            = 1'b1;
        repeat (1) @(posedge clk);

        set                             = 1'b1;
        done                            = 1'b0;
        repeat (1) @(posedge clk);

        set                             = 1'b0;
        done                            = 1'b0;
        repeat (5) @(posedge clk);

        set                             = 1'b0;
        done                            = 1'b1;
        repeat (1) @(posedge clk);

        set                             = 1'b0;
        done                            = 1'b0;
        repeat (5) @(posedge clk);
        $finish;
    end

endmodule