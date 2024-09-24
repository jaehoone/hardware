`timescale 1ns/1ps

module tb_arbiter;

    // System:
    localparam CLK_FREQ                             = 200; // MHz
    localparam CLK_PERIOD                           = 1000/200; // ns
    localparam CLK_HALF_PERIOD                      = CLK_PERIOD/2; // ns

    localparam NUM_REQUEST                          = 4;
    localparam REQ_INDEX_WIDTH                      = $clog2(NUM_REQUEST)+1;

    logic                                           clk;
    logic                                           rstn;
    logic                                           init;
    logic                                           en;
    logic [NUM_REQUEST-1:0]                         req;

    logic                                           granted;
    logic [NUM_REQUEST-1:0]                         grant;
    logic [REQ_INDEX_WIDTH-1:0]                     grant_idx;

    logic                                           dw_granted;
    logic [NUM_REQUEST-1:0]                         dw_grant;
    logic [REQ_INDEX_WIDTH-1:0]                     dw_grant_idx;

    arbiter
    #(
        .NUM_REQUEST                                (NUM_REQUEST),
        .REQ_INDEX_WIDTH                            (REQ_INDEX_WIDTH)
    )
    Uarbiter
    (
        .clk                                        (clk),
        .rstn                                       (rstn),
        .init_in                                    (init),
        .en_in                                      (en),
        .req_in                                     (req),
        .granted_out                                (granted),
        .grant_out                                  (grant),
        .grant_idx_out                              (grant_idx)
    );

    DW_arb_rr
    #(
        .n                                          (NUM_REQUEST),
        .index_mode                                 (1)
    )
    UDW_arb_rr
    (
        .clk                                        (clk),
        .rst_n                                      (rstn),
        .init_n                                     (~init),
        .enable                                     (en),
        .request                                    (req),
        .mask                                       ('0),
        .granted                                    (dw_granted),
        .grant                                      (dw_grant),
        .grant_index                                (dw_grant_idx)
    );

    initial $vcdplusfile("vcdplus_rtl.vpd");
    initial $vcdpluson();
    initial $vcdplusmemon();

    initial begin
        clk                                         = 1'b0;
        #1;

        forever clk                                 = #(CLK_HALF_PERIOD) ~clk;
    end

    initial begin
        rstn                                        = 1'b0;
        init                                        = 1'b0;
        en                                          = 1'b0;
        req                                         =   '0;
        repeat (20) @(posedge clk);

        rstn                                        = 1'b1;
        en                                          = 1'b1;
        repeat (2) @(posedge clk);

        for(int i=0; i<20; i++) begin
            req                                     = $urandom % NUM_REQUEST;
            // req                                     = $urandom % (2**NUM_REQUEST);
            // req                                     = '1;
            repeat (10) @(posedge clk);

            req                                     = '0;
            repeat (10) @(posedge clk);
        end

        repeat (10) @(posedge clk);
        $finish;
    end

endmodule