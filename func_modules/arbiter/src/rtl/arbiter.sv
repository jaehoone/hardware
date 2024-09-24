///////////////////////////////////////////////////////////////////////////
//  Copyright 2024 Jaehoon Heo. All rights reserved.
//
//  Name: arbiter.sv
//  Description:
//      This module describes the design of an arbiter that implements a
//      round-robin scheduling strategy.
//
//  Authors: Jaehoon Heo <kd01050@kaist.ac.kr>
//  Version: 1.0
//  Date: 2024-09-24
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

    //------------ Operation Summary ------------//
    // 0001
    // 0001,0001
    //         p <<< pnt_ff=0
    // idx=1, idx_wpnt=idx+pnt_ff=1, grant[idx_wpnt-1]=1'b1
    // pnt_nxt=1(idx)

    // 0011
    // 0011,0011
    //        p  <<< pnt_ff=1
    // idx=1, idx_wpnt=idx+pnt_ff=2, grant[idx_wpnt-1]=1'b1
    // pnt_nxt=2(idx_wpnt)

    // 1010
    // 1010,1010
    //       p   <<< pnt_ff=2
    // idx=2, idx_wpnt=idx+pnt_ff=4, grant[idx_wpnt-1]=1'b1
    // pnt_nxt=4(idx_wpnt) > 0, but since 4>=NUM_REQUEST, 4-4=0
    //-------------------------------------------//

    // States:
    enum logic{
        IDLE,
        LOCK
    } state_ff, state_nxt;

    // Regs:
    struct packed{
        logic [REQ_INDEX_WIDTH-1:0]                 pnt;
        logic                                       locked;
        logic [REQ_INDEX_WIDTH-1:0]                 idx_prev;
    } regs_ff, regs_nxt;

    // Wires:
    logic                                           start;
    logic                                           done;
    
    logic [2*NUM_REQUEST-1:0]                       req_concat;

    logic [REQ_INDEX_WIDTH-1:0]                     idx;
    logic                                           idx_found;
    logic [REQ_INDEX_WIDTH-1:0]                     idx_wpnt;

    // I/O:
    assign granted_out                              = regs_ff.locked;
    assign grant_idx_out                            = (state_ff==LOCK) ? regs_ff.idx_prev : 'd0;

    always_comb begin
        grant_out                                   = '0;

        case(state_ff)
            LOCK: begin
                grant_out[regs_ff.idx_prev-1]       = 1'b1;
            end
        endcase
    end

    // Logic:
    assign start                                    = (|req_in && en_in);
    assign done                                     = ((state_ff==LOCK) && ~req_in[regs_ff.idx_prev-1]) ? 1'b1 : 1'b0;

    assign req_concat                               = {req_in, req_in};
    assign idx_wpnt                                 = idx + regs_ff.pnt;

    always_comb begin // Priority encoding starts from LSB
        idx                                         =  'd0;
        idx_found                                   = 1'b0;

        for(int i=0; i<NUM_REQUEST-1; i++) begin
            if(~idx_found && req_concat[i+regs_ff.pnt]) begin
                idx                                 = i+'d1;
                idx_found                           = 1'b1;
            end
        end
    end

    //-- Regs --//
    always_comb begin
        regs_nxt                                    = regs_ff;

        case(state_ff)
            IDLE: begin
                if(start) begin
                    regs_nxt.locked                 = 1'b1;
                    regs_nxt.pnt                    = (idx_wpnt >= NUM_REQUEST) ? idx_wpnt-NUM_REQUEST : idx_wpnt;
                    regs_nxt.idx_prev               = (idx_wpnt > NUM_REQUEST) ? idx_wpnt-NUM_REQUEST : idx_wpnt;
                end
            end
            LOCK: begin
                if(done) begin
                    regs_nxt.locked                 = 1'b0;
                end
            end
        endcase
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            regs_ff                                 <= '0;
        end
        else begin
            if(init_in) begin
                regs_ff                             <= '0;;
            end
            else begin
                regs_ff                             <= regs_nxt;
            end
        end
    end

    //-- States --//
    always_comb begin
        state_nxt                                   = state_ff;

        case(state_ff)
            IDLE: begin
                if(start) begin
                    state_nxt                       = LOCK;
                end
            end
            LOCK: begin
                if(done) begin
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

endmodule