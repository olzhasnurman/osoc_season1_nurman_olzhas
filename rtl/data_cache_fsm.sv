/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// This is a data cache FSM for N-way set associative cache.
// -----------------------------------------------------------------------

module data_cache_fsm
#(
    parameter N = 4
)
(
    // Clock & Reset.
    input  logic clk,
    input  logic arst,

    // Input Interface.
    input  logic i_start_check,
    input  logic i_start_wb,
    input  logic i_hit,
    input  logic i_dirty,
    input  logic i_r_last,
    input  logic i_b_resp,

    // Output Interface.
    output logic o_stall,
    output logic o_data_block_write_en,
    output logic o_valid_update,
    output logic o_lru_update,
    output logic o_start_write,
    output logic o_start_read,
    output logic o_addr_control,
    output logic o_done_wb
);

    //------------------------------
    // FSM.
    //------------------------------

    // FSM: States.
    typedef enum logic [2:0 ] {
        IDLE        = 3'b000,
        COMPARE_TAG = 3'b001,
        ALLOCATE    = 3'b010,
        WRITE_BACK  = 3'b011,
        CHECK_DIRTY = 3'b100
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
            IDLE: if ( i_start_check ) NS = COMPARE_TAG;
             else if ( i_start_wb    ) NS = CHECK_DIRTY;

            COMPARE_TAG: begin
                if ( i_hit ) begin
                    NS = IDLE;
                end
                else if ( i_dirty ) begin
                    NS = WRITE_BACK;
                end
                else NS = ALLOCATE;
            end

            ALLOCATE: begin
                if ( i_r_last ) begin
                    NS = COMPARE_TAG;
                end
            end

            WRITE_BACK: begin
                if ( i_b_resp ) begin
                    if ( i_start_wb ) NS = IDLE;
                    else              NS = ALLOCATE;
                end
            end

            CHECK_DIRTY: begin
                if ( i_dirty ) NS = WRITE_BACK;
                else           NS = IDLE;
            end

            default: NS = PS;
        endcase
    end

    // FSM: Output Logic.
    always_comb begin
        o_stall               = 1'b1;
        o_data_block_write_en = 1'b0;
        o_valid_update        = 1'b0;
        o_lru_update          = 1'b0;
        o_start_write         = 1'b0;
        o_start_read          = 1'b0;
        o_addr_control        = 1'b1;
        o_done_wb             = 1'b0;

        case ( PS )
            IDLE: begin
                o_stall = 1'b1;
            end

            COMPARE_TAG: begin
                o_stall          = ~i_hit;
                if      ( i_hit   ) o_lru_update   = 1'b1;
                else if ( i_dirty ) o_addr_control = 1'b0;
            end

            ALLOCATE: begin
                o_start_read     = 1'b1;
                if ( i_r_last ) begin
                    o_data_block_write_en = 1'b1;
                    o_valid_update        = 1'b1;
                end
                else o_data_block_write_en = 1'b0;
            end

            WRITE_BACK: begin
                o_start_write  = 1'b1;
                o_done_wb      = i_b_resp & i_start_wb;
                if ( i_b_resp ) o_addr_control = 1'b1;
                else            o_addr_control = 1'b0;
            end

            CHECK_DIRTY: begin
                o_done_wb = ~i_dirty;
            end

            default: begin
                o_stall               = 1'b1;
                o_data_block_write_en = 1'b0;
                o_valid_update        = 1'b0;
                o_lru_update          = 1'b0;
                o_start_write         = 1'b0;
                o_start_read          = 1'b0;
                o_addr_control        = 1'b1;
            end
        endcase
    end

endmodule