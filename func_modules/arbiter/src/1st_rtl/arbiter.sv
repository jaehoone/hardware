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

    // Wire:
    logic [NUM_REQUEST-1:0]                         prienc_req;
    logic [REQ_INDEX_WIDTH-1:0]                     prienc_idx;

    logic [NUM_REQUEST-1:0]                         mask_gen;

    logic                                           lock_start;
    logic                                           lock_release;

    logic [NUM_REQUEST-1:0]                         prienc_req_pre;

    logic                                           found;

    // State:
    enum logic {
        IDLE,
        LOCK
    } state_ff, state_nxt;

    // Reg:
    struct packed {
        logic [NUM_REQUEST-1:0]                     mask; // valid: 1
        logic [REQ_INDEX_WIDTH-1:0]                 prienc_idx;
    } regs_ff, regs_nxt;

    assign lock_start                               = en_in && (|req_in);
    assign lock_release                             = (req_in[regs_ff.prienc_idx-1]) ? 1'b0 : 1'b1;

    assign prienc_req_pre                           = regs_ff.mask & req_in;
    assign prienc_req                               = mask_gen & req_in;

    always_comb begin
        if(state_ff == LOCK) begin
            granted_out                             = 1'b1;
            grant_out                               =  'd0;
            grant_out[regs_ff.prienc_idx-1]         = 1'b1;
            grant_idx_out                           = regs_ff.prienc_idx;
        end
        else begin
            granted_out                             = 1'b0;
            grant_out                               =  'd0;
            grant_idx_out                           =  'd0;
        end
    end

    always_comb begin
        mask_gen                                    = '1;
        found                                       = 1'b0;

        case(state_ff)
            IDLE: begin
                if(lock_start) begin
                    if(|prienc_req_pre) begin // Require round-robin strategy
                        for(int i=NUM_REQUEST-1; i>=0; i--) begin
                            if(prienc_req_pre[i]) begin
                                if(found) begin
                                    mask_gen[i]     = 1'b0;
                                end
                                found               = 1'b1;
                            end
                        end
                    end
                end
            end
        endcase
    end

    always_comb begin
        regs_nxt                                    = regs_ff;

        case(state_ff)
            IDLE: begin
                if(lock_start) begin
                    regs_nxt.mask                   = (&mask_gen) ? '1 : ~mask_gen;
                    regs_nxt.prienc_idx             = prienc_idx;
                end
                else begin
                    if(init_in) begin
                        regs_nxt.mask               = '1;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            regs_ff                                 <= '0;
            regs_ff.mask                            <= '1;
        end
        else begin
            regs_ff                                 <= regs_nxt;
        end
    end

    always_comb begin
        state_nxt                                   = state_ff;

        case(state_ff)
            IDLE: begin
                if(lock_start) begin
                    state_nxt                       = LOCK;
                end
            end
            LOCK: begin
                if(lock_release) begin
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

    // Instance:
    prior_encoder
    #(
        .DATA_WIDTH                                 (NUM_REQUEST),
        .INDEX_WIDTH                                (REQ_INDEX_WIDTH)
    )
    Uprior_encoder
    (
        .data_in                                    (prienc_req_pre),
        .idx_out                                    (prienc_idx)
    );

endmodule