`timescale 1ns / 1ps

module tb_gearbox_fifo;

    localparam CLK_FREQ                         = 200;
    localparam CLK_PERIOD                       = 1000/CLK_FREQ; // ns
    localparam CLK_HALF_PERIOD                  = CLK_PERIOD/2; // ns

    localparam IDATA_WIDTH                      = 64;
    localparam ODATA_WIDTH                      = 16;
    localparam DEPTH                            = 16;
    localparam AE_LEVEL                         = 4;
    localparam AF_LEVEL                         = 4;

    logic                                       clk;
    logic                                       rstn;
    logic                                       push_req;
    logic                                       full;
    logic                                       almost_full;
    logic [IDATA_WIDTH-1:0]                     idata;
    logic                                       pop_req;
    logic                                       empty;
    logic                                       almost_empty;
    logic [ODATA_WIDTH-1:0]                     odata;
    logic                                       error;

    logic                                       w_en;
    logic                                       r_en;

    initial $vcdplusfile("vcdplus_rtl.vpd");
    initial $vcdpluson();
    initial $vcdplusmemon();

    initial begin
        clk                                     = 1'b0;
        #0.1;

        forever clk                             = #(CLK_HALF_PERIOD) ~clk; 
    end

    assign push_req                             = (~full && w_en) ? 1'b1: 1'b0;
    assign pop_req                              = (~empty && r_en) ? 1'b1: 1'b0;

    initial begin
        init();

        for(int i=0; i<30; i++) begin
            if(~full) begin
                #0.1
                idata                           = {i} | (i<<ODATA_WIDTH) | (i<<ODATA_WIDTH*2) | (i<<ODATA_WIDTH*3);
                w_en                            = 1'b1;
            end
            else begin
                w_en                            = 1'b0;
            end
            repeat(1) @(posedge clk);
        end

        w_en                                    = 1'b0;
        repeat(1) @(posedge clk);

        for(int i=0; i<30; i++) begin
            if(~empty) begin
                #0.1
                r_en                            = 1'b1;
            end
            else begin
                r_en                            = 1'b0;
            end
            repeat(1) @(posedge clk);
        end

        w_en                                    = 1'b0;
        r_en                                    = 1'b0;
        repeat(10) @(posedge clk);
        $finish;
    end

    task automatic init();
        rstn                                    = 1'b0;
        w_en                                    = 1'b0;
        r_en                                    = 1'b0;
        idata                                   =  'd0;
        repeat(10) @(posedge clk);

        rstn                                    = 1'b1;
        repeat(1) @(posedge clk);
    endtask

    gearbox_fifo
    #(
        .IDATA_WIDTH                            (IDATA_WIDTH),
        .ODATA_WIDTH                            (ODATA_WIDTH),
        .DEPTH                                  (DEPTH),
        .AE_LEVEL                               (AE_LEVEL),
        .AF_LEVEL                               (AF_LEVEL)
    )
    Ugearbox_fifo
    (
        .clk                                    (clk),
        .rstn                                   (rstn),
        .push_req_in                            (push_req),
        .full_out                               (full),
        .almost_full_out                        (almost_full),
        .data_in                                (idata),
        .pop_req_in                             (pop_req),
        .empty_out                              (empty),
        .almost_empty_out                       (almost_empty),
        .data_out                               (odata),
        .error_out                              (error)
    );

endmodule