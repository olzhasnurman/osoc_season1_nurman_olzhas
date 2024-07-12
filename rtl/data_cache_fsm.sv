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
    output logic o_addr_control
);

    //------------------------------
    // FSM.
    //------------------------------

    // FSM: States.
    typedef enum logic [1:0 ] {
        IDLE        = 2'b00,
        COMPARE_TAG = 2'b01,
        ALLOCATE    = 2'b10,
        WRITE_BACK  = 2'b11
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
                    NS = ALLOCATE;
                end
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
                if ( i_b_resp ) o_addr_control = 1'b1;
                else            o_addr_control = 1'b0;
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