///////////////////////////////////////////////////////////////////////////
//  Copyright 2024 Jaehoon Heo. All rights reserved.
//
//  Name: arbiter.sv
//  Description:
//      This module describes the design of a arbiter.
//
//  Authors: Jaehoon Heo <kd01050@kaist.ac.kr>
//  Version: 1.0
//  Date: 2024-09-20
//
///////////////////////////////////////////////////////////////////////////

module arbiter
#(
    parameter NUM_REQUEST                           = 4,
    parameter REQ_INDEX_WIDTH                       = $clog2(NUM_REQUEST)+1
)
(
    input  logic                                    clk,
    input  logic                                    rstn,
    input  logic                                    init_in,
    input  logic                                    en_in,
    input  logic [NUM_REQUEST-1:0]                  req_in,
    output logic                                    granted_out,
    output logic [NUM_REQUEST-1:0]                  grant_out,
    output logic [REQ_INDEX_WIDTH-1:0]              grant_idx_out
);

    // Operation Summary:
    // 1100 >> 0011
    // p
    // 00110011 >>> 2 >>> 4-2 = 2+p(1) = 3
    //    n           >>> next pnt: 1+(4-(2-1))

    // 1101 >> 1011
    //    p
    // 10111011 >>> 4 >>> 4-4 = 0+p(4) = 4
    //     n          >>> next pnt: 4+(4-(4-1))

    // 1101 >> 1011
    //     p
    // 10111011 >>> 4 >>> 4-4 = 0+p(5) = 5 [1]
    //  n             >>> next pnt: 5+(4-(4-1))

    // 1101 >> 1011
    //  p
    // 10111011 >>> 3 >>> 4-3 = 1+p(2) = 3
    //    n           >>> next pnt: 2+(4-(3-1))

    // State:
    enum logic {
        IDLE,
        LOCK
    } state_ff, state_nxt;

    // Reg:
    struct packed{
        logic [REQ_INDEX_WIDTH:0]                   rr_pnt;
        logic [NUM_REQUEST-1:0]                     grant;
        logic [REQ_INDEX_WIDTH:0]                   grant_idx;
    } regs_ff, regs_nxt;

    // Wire:
    logic                                           arb_start;
    logic                                           arb_done;

    logic                                           granted;
    logic [NUM_REQUEST-1:0]                         grant;
    logic [REQ_INDEX_WIDTH:0]                       grant_idx;

    logic [2*NUM_REQUEST-1:0]                       req_concat;
    logic [2*NUM_REQUEST-1:0]                       req_concat_rev; // reversed
    logic [NUM_REQUEST-1:0]                         prienc_req;
    logic [REQ_INDEX_WIDTH-1:0]                     prienc_grant_idx;

    //---------- I/O ----------//
    assign granted_out                              = granted;
    assign grant_out                                = grant;
    assign grant_idx_out                            = (state_ff == LOCK) ? regs_ff.grant_idx : 'd0;

    //---------- Logic ----------//
    assign granted                                  = (state_ff == LOCK) ? 1'b1 : 1'b0;
    assign grant                                    = regs_ff.grant;
    assign grant_idx                                = NUM_REQUEST - prienc_grant_idx + regs_ff.rr_pnt;

    // Reg:
    always_comb begin
        regs_nxt                                    = regs_ff;

        case(state_ff)
            IDLE: begin
                if(arb_start) begin
                    if(grant_idx > NUM_REQUEST) begin
                        regs_nxt.grant_idx          = grant_idx-NUM_REQUEST;
                        regs_nxt.grant[grant_idx-NUM_REQUEST-1]     = 1'b1;
                    end
                    else begin
                        regs_nxt.grant_idx          = grant_idx;
                        regs_nxt.grant[grant_idx-1]     = 1'b1;
                    end

                    if(grant_idx >= NUM_REQUEST) begin
                        regs_nxt.rr_pnt             = regs_ff.rr_pnt - (prienc_grant_idx-1);
                    end
                    else begin
                        regs_nxt.rr_pnt             = regs_ff.rr_pnt + (NUM_REQUEST - (prienc_grant_idx-1));
                    end
                end
            end
            LOCK: begin
                if(arb_done) begin
                    regs_nxt.grant                  = '0;
                end
            end
        endcase
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            regs_ff                                 <= '0;
            regs_ff.rr_pnt                          <= 'd1;
        end
        else begin
            if(init_in) begin
                regs_ff                             <= '0;
                regs_ff.rr_pnt                      <= 'd1;
            end
            else begin
                regs_ff                             <= regs_nxt;
            end
        end
    end

    // state:
    assign arb_start                                = (|req_in && en_in);
    assign arb_done                                 = (state_ff == LOCK && ~req_in[regs_ff.grant_idx-1]) ? 1'b1 : 1'b0;

    always_comb begin
        state_nxt                                   = state_ff;

        case(state_ff)
            IDLE: begin
                if(arb_start) begin
                    state_nxt                       = LOCK;
                end
            end
            LOCK: begin
                if(arb_done) begin
                    state_nxt                       = IDLE;
                end
            end
        endcase
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            state_ff                                <= IDLE;
        end
        else begin
            state_ff                                <= state_nxt;
        end
    end

    // prienc:
    assign req_concat                               = {req_in, req_in};
    assign prienc_req                               = req_concat_rev[(2*NUM_REQUEST-regs_ff.rr_pnt)-:NUM_REQUEST];

    genvar i;
    generate
        for(i=0; i<2*NUM_REQUEST; i++) begin
            assign req_concat_rev[i]                = req_concat[(2*NUM_REQUEST-1)-i];
        end
    endgenerate

    prior_encoder
    #(
        .DATA_WIDTH                                 (NUM_REQUEST),
        .INDEX_WIDTH                                (REQ_INDEX_WIDTH)
    )
    Uprior_encoder
    (
        .data_in                                    (prienc_req),
        .idx_out                                    (prienc_grant_idx)
    );

endmodule