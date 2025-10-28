/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// This is a instruction cache FSM for direct mapped cache.
// -----------------------------------------------------------------------

module instr_cache_fsm
(
    // Clock & Reset.
    input  logic clk,
    input  logic arst,

    // Input Interface.
    input  logic i_start_check,
    input  logic i_hit,
    input  logic i_r_last,

    // Output Interface.
    output logic o_stall,
    output logic o_instr_write_en,
    output logic o_start_read,
    output logic o_in_idle
);

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
    always_ff @( posedge clk, posedge arst ) begin
        if ( arst ) begin
            PS <= IDLE;
        end
        else PS <= NS;
    end

    // FSM: NS Logic.
    always_comb begin
        NS = PS;

        case ( PS )
            IDLE: if ( i_start_check ) begin
                NS = COMPARE_TAG;
            end

            COMPARE_TAG: begin
                if ( i_hit ) begin
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

        // Default values.
        o_stall          = 1'b0;
        o_start_read     = 1'b0;
        o_instr_write_en = 1'b0;

        case ( PS )
            IDLE: begin
                o_stall          = 1'b1;
                o_start_read     = 1'b0;
                o_instr_write_en = 1'b0;
            end

            COMPARE_TAG: begin
                o_stall          = ~i_hit;
                o_start_read     = 1'b0;
                o_instr_write_en = 1'b0;
            end

            ALLOCATE: begin
                o_stall          = 1'b1;
                o_start_read     = 1'b1;
                if ( i_r_last ) begin
                    o_instr_write_en = 1'b1;
                end
                else o_instr_write_en = 1'b0;
            end
            default: begin
                o_stall          = 1'b0;
                o_start_read     = 1'b0;
                o_instr_write_en = 1'b0;
            end
        endcase
    end

    assign o_in_idle = ( PS == IDLE );

endmodule