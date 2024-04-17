/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------
// This is a instruction cache for for direct mapped cache.
// -------------------------------------------------------------------

module instr_cache 
#(
    parameter BLOCK_COUNT   = 256,
              WORD_COUNT    = 16,
              WORD_SIZE     = 32,
              BLOCK_WIDTH   = 512,
              TAG_WIDTH     = 50,
              ADDR_WIDTH    = 64
) 
(
    // Control signals.
    input  logic                       clk,
    input  logic                       write_en,
    input  logic                       arstn,
    
    // Input Interface.
    input  logic [ ADDR_WIDTH  - 1:0 ] i_instr_addr,
    input  logic [ BLOCK_WIDTH - 1:0 ] i_inst,

    // Output Interface.
    output logic [ WORD_SIZE   - 1:0 ] o_instr,
    output logic                       o_hit

);
    // Local Parameters.
    localparam WORD_OFFSET_W  = $clog2( WORD_COUNT );  // 4 bit.
    localparam BLOCK_NUMBER_W = $clog2( BLOCK_COUNT ); // 8 bit.
    localparam BYTE_OFFSET_W  = $clog2( WORD_SIZE/8 ); // 2 bit.

    localparam TAG_MSB         = ADDR_WIDTH - 1;                                 // 63.
    localparam TAG_LSB         = BLOCK_NUMBER_W + WORD_OFFSET_W + BYTE_OFFSET_W; // 14.
    localparam INDEX_MSB       = TAG_LSB - 1;                                    // 13.
    localparam INDEX_LSB       = WORD_OFFSET_W + BYTE_OFFSET_W;                  // 6.
    localparam WORD_OFFSET_MSB = INDEX_LSB - 1;                                  // 5.
    localparam WORD_OFFSET_LSB = BYTE_OFFSET_W;                                  // 2.

    // Internal signals.
    logic [ TAG_MSB         - TAG_LSB        :0 ] s_tag_in;
    logic [ INDEX_MSB       - INDEX_LSB      :0 ] s_index;
    logic [ WORD_OFFSET_MSB - WORD_OFFSET_LSB:0 ] s_word_offset;

    logic [ TAG_MSB         - TAG_LSB        :0 ] s_tag;

    logic s_tag_match;
    logic s_valid;


    // Continious assignments.
    assign s_tag_in      = i_instr_addr[ TAG_MSB        :TAG_LSB         ];
    assign s_index       = i_instr_addr[ INDEX_MSB      :INDEX_LSB       ]; 
    assign s_word_offset = i_instr_addr[ WORD_OFFSET_MSB:WORD_OFFSET_LSB ];

    // Tag memory.
    logic [ TAG_WIDTH - 1:0 ] tag_mem [ BLOCK_COUNT - 1:0 ];

    // Valid memory.
    logic [ BLOCK_COUNT - 1:0 ] valid_mem;

    // Instruction memory.
    logic [ BLOCK_WIDTH - 1:0 ] mem [ BLOCK_COUNT - 1:0 ];

    // Write logic.
    always_ff @( posedge clk, negedge arstn ) begin
        if ( ~arstn ) begin
            valid_mem <= '0;
        end
        else if ( write_en ) begin
            tag_mem  [ s_index ] <= s_tag_in;
            valid_mem[ s_index ] <= 1'b1;
            mem      [ s_index ] <= i_inst;
        end
    end

    assign s_tag   = tag_mem  [ s_index ];
    assign s_valid = valid_mem[ s_index ];

    always_comb begin
        case ( s_word_offset )
        // PROBLEM: NEED TO IMPLEMENT Instruction address misaligned.
            4'b0000: o_instr = mem[ s_index ][ 31 :0   ]; 
            4'b0001: o_instr = mem[ s_index ][ 63 :32  ]; 
            4'b0010: o_instr = mem[ s_index ][ 95 :64  ]; 
            4'b0011: o_instr = mem[ s_index ][ 127:96  ]; 
            4'b0100: o_instr = mem[ s_index ][ 159:128 ]; 
            4'b0101: o_instr = mem[ s_index ][ 191:160 ]; 
            4'b0110: o_instr = mem[ s_index ][ 223:192 ]; 
            4'b0111: o_instr = mem[ s_index ][ 255:224 ]; 
            4'b1000: o_instr = mem[ s_index ][ 287:256 ]; 
            4'b1001: o_instr = mem[ s_index ][ 319:288 ]; 
            4'b1010: o_instr = mem[ s_index ][ 351:320 ]; 
            4'b1011: o_instr = mem[ s_index ][ 383:352 ]; 
            4'b1100: o_instr = mem[ s_index ][ 415:384 ]; 
            4'b1101: o_instr = mem[ s_index ][ 447:416 ];
            4'b1110: o_instr = mem[ s_index ][ 479:448 ];
            4'b1111: o_instr = mem[ s_index ][ 511:480 ];
            default: o_instr = '0;
        endcase
    end

    assign s_tag_match = (s_tag == s_tag_in);
    assign o_hit       = s_valid & s_tag_match;
    
endmodule