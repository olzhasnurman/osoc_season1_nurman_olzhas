/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------
// This is a instruction cache for for direct mapped cache.
// -------------------------------------------------------------------

module instr_cache 
#(
    parameter BLOCK_COUNT   = 256,
              WORD_COUNT    = 16,
              WORD_SIZE     = 32,
              TAG_WIDTH     = 50,
              ADDR_WIDTH    = 64
) 
(
    // Control signals.
    input  logic                                clk,
    input  logic                                write_en,
    input  logic                                arstn,
    
    // Input Interface.
    input  logic [ ADDR_WIDTH - 1:0 ] i_instr_addr,
    input  logic [ WORD_SIZE  - 1:0 ] i_inst,

    // Output Interface.
    output logic [ WORD_SIZE  - 1:0 ] o_instr,
    output logic [ TAG_WIDTH  - 1:0 ] o_tag,
    output logic                      o_valid

);
    // Local Parameters.
    localparam WORD_OFFSET_W  = $clog2( WORD_COUNT );   // 4 bit.
    localparam BLOCK_NUMBER_W = $clog2( BLOCK_COUNT );  // 8 bit.
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


    // Continious assignments.
    assign s_tag_in      = i_instr_addr[ TAG_MSB        :TAG_LSB         ];
    assign s_index       = i_instr_addr[ INDEX_MSB      :INDEX_LSB       ]; 
    assign s_word_offset = i_instr_addr[ WORD_OFFSET_MSB:WORD_OFFSET_LSB ];

    // Tag memory.
    logic [ TAG_WIDTH - 1:0 ] tag_mem [ BLOCK_COUNT - 1:0 ];

    // Valid memory.
    logic [ BLOCK_COUNT - 1:0 ] valid_mem;

    // Instruction memory.
    logic [ WORD_SIZE - 1:0 ] mem [ BLOCK_COUNT - 1:0 ][ WORD_COUNT - 1:0 ];

    // Write logic.
    always_ff @( posedge clk, negedge arstn ) begin
        if ( ~arstn ) begin
            valid_mem <= '0;
        end
        else if ( write_en ) begin
            tag_mem  [ s_index ]                 <= s_tag_in;
            valid_mem[ s_index ]                 <= 1'b1;
            mem      [ s_index ][s_word_offset ] <= i_inst;
        end
    end

    assign o_tag   = tag_mem[ s_index ];
    assign o_valid = valid_mem[ s_index ];
    assign o_instr = mem[ s_index ][ s_word_offset ];
    
endmodule