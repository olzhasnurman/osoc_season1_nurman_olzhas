/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// This is a instruction cache FSM for direct mapped cache.
// -----------------------------------------------------------------------

module instr_cache_fsm 
(
    // Clock & Reset.
    input  logic clk,
    input  logic arstn,

    // Input Interface.
    input  logic i_start,
    input  logic i_valid,
    input  logic i_tag_match,
    input  logic i_r_last,

    // Output Interface.
    output logic o_stall,
    output logic o_start_read
);

    logic s_cache_hit;

    assign s_cache_hit = i_valid & i_tag_match;

    //------------------------------
    // FSM.
    //------------------------------

    // FSM: States.
    typedef enum logic [1:0 ] {
        IDLE        = 2'b00,
        COMPARE_TAG = 2'b01,
        ALLOCATE    = 2'b10
    } t_state;

    t_state PS;
    t_state NS;

    // FSM: PS Syncronization.
    always_ff @( posedge clk, negedge arstn ) begin
        if ( ~arstn ) begin
            PS <= IDLE;
        end
        else PS <= NS;
    end

    // FSM: NS Logic.
    always_comb begin
        NS = PS;

        case ( PS )
            IDLE: if ( i_start ) begin
                NS = COMPARE_TAG;
            end

            COMPARE_TAG: begin
                if ( s_cache_hit ) begin
                    NS = IDLE;
                end
                else NS = ALLOCATE;
            end

            ALLOCATE: begin
                if ( i_r_last ) begin
                    NS = COMPARE_TAG;
                end
            end
            default: NS = PS;
        endcase
    end

    // FSM: Output Logic.
    always_comb begin
        
        case ( PS )
            IDLE: begin
                o_stall      = 1'b1;
                o_start_read = 1'b0;
            end 

            COMPARE_TAG: begin
                o_stall      = ~s_cache_hit;
                o_start_read = 1'b0;
            end

            ALLOCATE: begin
                o_stall      = 1'b1;
                o_start_read = 1'b1;
            end
            default: begin
                o_stall      = 1'b0;
                o_start_read = 1'b0;
            end
        endcase
    end
    
endmodule