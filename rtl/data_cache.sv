/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------
// This is a data cache implemneted using 4-way set associative cache.
// -------------------------------------------------------------------

module data_cache 
#(
    parameter SET_COUNT   = 32,
              WORD_COUNT  = 16,
              WORD_SIZE   = 32,
              BLOCK_WIDTH = 512,
              TAG_WIDTH   = 50,
              N           = 4,
              ADDR_WIDTH  = 64,
              REG_WIDTH   = 64
) 
(
    // Control signals.
    input  logic                       clk,
    input  logic                       arstn,
    input  logic                       write_en,
    input  logic                       valid_update,
    input  logic                       lru_update,
    input  logic                       block_write_en,
    
    // Input Interface.
    input  logic [ ADDR_WIDTH  - 1:0 ] i_data_addr,
    input  logic [ REG_WIDTH   - 1:0 ] i_data,
    input  logic [ BLOCK_WIDTH - 1:0 ] i_data_block,
    input  logic [               1:0 ] i_store_type,

    // Output Interface.
    output logic [ REG_WIDTH   - 1:0 ] o_data,
    output logic [ BLOCK_WIDTH - 1:0 ] o_data_block,
    output logic                       o_hit,
    output logic                       o_dirty

);  
    //-------------------------
    // Local Parameters.
    //-------------------------
    localparam WORD_OFFSET_W  = $clog2( WORD_COUNT  ); // 4 bit.
    localparam BLOCK_NUMBER_W = $clog2( SET_COUNT );   // 8 bit.
    localparam BYTE_OFFSET_W  = $clog2( WORD_SIZE/8 ); // 2 bit.

    localparam TAG_MSB         = ADDR_WIDTH - 1;                                 // 63.
    localparam TAG_LSB         = BLOCK_NUMBER_W + WORD_OFFSET_W + BYTE_OFFSET_W; // 14.
    localparam INDEX_MSB       = TAG_LSB - 1;                                    // 13.
    localparam INDEX_LSB       = WORD_OFFSET_W + BYTE_OFFSET_W;                  // 6.
    localparam WORD_OFFSET_MSB = INDEX_LSB - 1;                                  // 5.
    localparam WORD_OFFSET_LSB = BYTE_OFFSET_W;                                  // 2.



    //------------------------
    // Internal signals.
    //------------------------
    logic [ TAG_MSB         - TAG_LSB        :0 ] s_tag_in;
    logic [ INDEX_MSB       - INDEX_LSB      :0 ] s_index;
    logic [ WORD_OFFSET_MSB - WORD_OFFSET_LSB:0 ] s_word_offset;

    logic [ TAG_MSB         - TAG_LSB        :0 ] s_tag;

    logic [ $clog2( N ) - 1:0 ] s_lru;
    logic [           N - 1:0 ] s_lru_found;
    logic [           N - 1:0 ] s_hit;



    //-------------------------
    // Continious assignments.
    //-------------------------
    assign s_tag_in      = i_data_addr[ TAG_MSB        :TAG_LSB         ];
    assign s_index       = i_data_addr[ INDEX_MSB      :INDEX_LSB       ]; 
    assign s_word_offset = i_data_addr[ WORD_OFFSET_MSB:WORD_OFFSET_LSB ];


    //-------------------------------------
    // Memory
    //-------------------------------------

    // Tag memory.
    logic [ TAG_WIDTH - 1:0 ] tag_mem [ SET_COUNT - 1:0 ][ N - 1:0 ];

    // Valid & Dirty & LRU memories.
    logic [ SET_COUNT   - 1:0 ] valid_mem [ N - 1:0 ];
    logic [ SET_COUNT   - 1:0 ] dirty_mem [ N - 1:0 ];
    logic [ $clog2( N ) - 1:0 ] lru_mem   [ N - 1:0 ][ SET_COUNT - 1:0 ];
    logic [ SET_COUNT   - 1:0 ] lru_set;

    // Instruction memory.
    logic [ BLOCK_WIDTH - 1:0 ] data_mem [ SET_COUNT - 1:0 ][ N - 1:0 ];



    //------------------------------
    // Check 
    //------------------------------

    // Check for hit.
    logic [ $clog2 (N) - 1:0 ] match;
    always_comb begin
        s_hit[0] = valid_mem[ 0 ][ s_index ] & ( tag_mem [ s_index ][ 0 ] == s_tag_in );
        s_hit[1] = valid_mem[ 1 ][ s_index ] & ( tag_mem [ s_index ][ 1 ] == s_tag_in );
        s_hit[2] = valid_mem[ 2 ][ s_index ] & ( tag_mem [ s_index ][ 2 ] == s_tag_in );
        s_hit[3] = valid_mem[ 3 ][ s_index ] & ( tag_mem [ s_index ][ 3 ] == s_tag_in );

        o_hit = | s_hit;

        if ( o_hit ) begin
            case ( s_hit )
                4'b0001: match = 2'b00;
                4'b0010: match = 2'b01;
                4'b0100: match = 2'b10;
                4'b1000: match = 2'b11;
                default: match = 2'b00;
            endcase  
            
        end
        else match = '0;
    end

    // Find LRU.
    always_comb begin
        s_lru_found[0] = lru_mem[0][ s_index ] == 2'b00;
        s_lru_found[1] = lru_mem[1][ s_index ] == 2'b00;
        s_lru_found[2] = lru_mem[2][ s_index ] == 2'b00;
        s_lru_found[3] = lru_mem[3][ s_index ] == 2'b00;

        case ( s_lru_found )
            4'b0001: s_lru = 2'b00;
            4'b0010: s_lru = 2'b01;
            4'b0100: s_lru = 2'b10;
            4'b1000: s_lru = 2'b11;
            default: s_lru = 2'b00;
        endcase  
    end



    //-------------------------
    // Write logic.
    //-------------------------

    // Write data logic.
    always_ff @( posedge clk ) begin
        if ( write_en ) begin
            case ( i_store_type )
                // SD Instruction.
                2'b11: begin
                    case ( s_word_offset )
                        4'b0000: data_mem[ s_index ][ match ][ 63 :0   ] <= i_data; 
                        4'b0001: data_mem[ s_index ][ match ][ 95 :32  ] <= i_data; 
                        4'b0010: data_mem[ s_index ][ match ][ 127:64  ] <= i_data; 
                        4'b0011: data_mem[ s_index ][ match ][ 159:96  ] <= i_data; 
                        4'b0100: data_mem[ s_index ][ match ][ 191:128 ] <= i_data; 
                        4'b0101: data_mem[ s_index ][ match ][ 223:160 ] <= i_data; 
                        4'b0110: data_mem[ s_index ][ match ][ 255:192 ] <= i_data; 
                        4'b0111: data_mem[ s_index ][ match ][ 287:224 ] <= i_data; 
                        4'b1000: data_mem[ s_index ][ match ][ 319:256 ] <= i_data; 
                        4'b1001: data_mem[ s_index ][ match ][ 351:288 ] <= i_data;
                        4'b1010: data_mem[ s_index ][ match ][ 383:320 ] <= i_data; 
                        4'b1011: data_mem[ s_index ][ match ][ 415:352 ] <= i_data; 
                        4'b1100: data_mem[ s_index ][ match ][ 447:384 ] <= i_data; 
                        4'b1101: data_mem[ s_index ][ match ][ 479:416 ] <= i_data;
                        4'b1110: data_mem[ s_index ][ match ][ 511:448 ] <= i_data;
                        4'b1111: data_mem[ s_index ][ match ][ 511:480 ] <= i_data[31:0]; //NOT FINISHED.
                        default: data_mem[ s_index ][ match ][ 31:0    ] <= '0;
                    endcase                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
                end

                // SW Instruction.
                2'b10: begin
                    case ( s_word_offset )
                        4'b0000: data_mem[ s_index ][ match ][ 31 :0   ] <= i_data[ 31:0 ]; 
                        4'b0001: data_mem[ s_index ][ match ][ 63 :32  ] <= i_data[ 31:0 ]; 
                        4'b0010: data_mem[ s_index ][ match ][ 95 :64  ] <= i_data[ 31:0 ]; 
                        4'b0011: data_mem[ s_index ][ match ][ 127:96  ] <= i_data[ 31:0 ]; 
                        4'b0100: data_mem[ s_index ][ match ][ 159:128 ] <= i_data[ 31:0 ]; 
                        4'b0101: data_mem[ s_index ][ match ][ 191:160 ] <= i_data[ 31:0 ]; 
                        4'b0110: data_mem[ s_index ][ match ][ 223:192 ] <= i_data[ 31:0 ]; 
                        4'b0111: data_mem[ s_index ][ match ][ 255:224 ] <= i_data[ 31:0 ]; 
                        4'b1000: data_mem[ s_index ][ match ][ 287:256 ] <= i_data[ 31:0 ]; 
                        4'b1001: data_mem[ s_index ][ match ][ 319:288 ] <= i_data[ 31:0 ]; 
                        4'b1010: data_mem[ s_index ][ match ][ 351:320 ] <= i_data[ 31:0 ]; 
                        4'b1011: data_mem[ s_index ][ match ][ 383:352 ] <= i_data[ 31:0 ]; 
                        4'b1100: data_mem[ s_index ][ match ][ 415:384 ] <= i_data[ 31:0 ]; 
                        4'b1101: data_mem[ s_index ][ match ][ 447:416 ] <= i_data[ 31:0 ];
                        4'b1110: data_mem[ s_index ][ match ][ 479:448 ] <= i_data[ 31:0 ];
                        4'b1111: data_mem[ s_index ][ match ][ 511:480 ] <= i_data[ 31:0 ];
                        default: data_mem[ s_index ][ match ][ 31:0    ] <= '0;
                    endcase    
                end 

                // SH Instruction.
                2'b01: begin
                    case ( s_word_offset )
                        4'b0000: data_mem[ s_index ][ match ][ 15 :0   ] <= i_data[ 15:0 ]; 
                        4'b0001: data_mem[ s_index ][ match ][ 47 :32  ] <= i_data[ 15:0 ]; 
                        4'b0010: data_mem[ s_index ][ match ][ 79 :64  ] <= i_data[ 15:0 ]; 
                        4'b0011: data_mem[ s_index ][ match ][ 111:96  ] <= i_data[ 15:0 ]; 
                        4'b0100: data_mem[ s_index ][ match ][ 143:128 ] <= i_data[ 15:0 ]; 
                        4'b0101: data_mem[ s_index ][ match ][ 175:160 ] <= i_data[ 15:0 ]; 
                        4'b0110: data_mem[ s_index ][ match ][ 207:192 ] <= i_data[ 15:0 ]; 
                        4'b0111: data_mem[ s_index ][ match ][ 239:224 ] <= i_data[ 15:0 ]; 
                        4'b1000: data_mem[ s_index ][ match ][ 271:256 ] <= i_data[ 15:0 ]; 
                        4'b1001: data_mem[ s_index ][ match ][ 303:288 ] <= i_data[ 15:0 ]; 
                        4'b1010: data_mem[ s_index ][ match ][ 335:320 ] <= i_data[ 15:0 ]; 
                        4'b1011: data_mem[ s_index ][ match ][ 367:352 ] <= i_data[ 15:0 ]; 
                        4'b1100: data_mem[ s_index ][ match ][ 399:384 ] <= i_data[ 15:0 ]; 
                        4'b1101: data_mem[ s_index ][ match ][ 431:416 ] <= i_data[ 15:0 ];
                        4'b1110: data_mem[ s_index ][ match ][ 463:448 ] <= i_data[ 15:0 ];
                        4'b1111: data_mem[ s_index ][ match ][ 495:480 ] <= i_data[ 15:0 ];
                        default: data_mem[ s_index ][ match ][ 31:0    ] <= '0;
                    endcase
                end

                // SB Instruction.
                2'b00: begin
                    case ( s_word_offset )
                        4'b0000: data_mem[ s_index ][ match ][ 7  :0   ] <= i_data[ 7:0 ]; 
                        4'b0001: data_mem[ s_index ][ match ][ 39 :32  ] <= i_data[ 7:0 ]; 
                        4'b0010: data_mem[ s_index ][ match ][ 71 :64  ] <= i_data[ 7:0 ]; 
                        4'b0011: data_mem[ s_index ][ match ][ 103:96  ] <= i_data[ 7:0 ]; 
                        4'b0100: data_mem[ s_index ][ match ][ 135:128 ] <= i_data[ 7:0 ]; 
                        4'b0101: data_mem[ s_index ][ match ][ 167:160 ] <= i_data[ 7:0 ]; 
                        4'b0110: data_mem[ s_index ][ match ][ 199:192 ] <= i_data[ 7:0 ]; 
                        4'b0111: data_mem[ s_index ][ match ][ 231:224 ] <= i_data[ 7:0 ]; 
                        4'b1000: data_mem[ s_index ][ match ][ 263:256 ] <= i_data[ 7:0 ]; 
                        4'b1001: data_mem[ s_index ][ match ][ 295:288 ] <= i_data[ 7:0 ]; 
                        4'b1010: data_mem[ s_index ][ match ][ 327:320 ] <= i_data[ 7:0 ]; 
                        4'b1011: data_mem[ s_index ][ match ][ 359:352 ] <= i_data[ 7:0 ]; 
                        4'b1100: data_mem[ s_index ][ match ][ 391:384 ] <= i_data[ 7:0 ]; 
                        4'b1101: data_mem[ s_index ][ match ][ 423:416 ] <= i_data[ 7:0 ];
                        4'b1110: data_mem[ s_index ][ match ][ 455:448 ] <= i_data[ 7:0 ];
                        4'b1111: data_mem[ s_index ][ match ][ 487:480 ] <= i_data[ 7:0 ];
                        default: data_mem[ s_index ][ match ][ 7  :0    ] <= '0;
                    endcase
                end
            endcase

        end
        else if ( block_write_en ) begin
            data_mem[ s_index ][ s_lru ] <= i_data_block;
            tag_mem [ s_index ][ s_lru ] <= s_tag_in; 
        end
    end

    // Modify dirty bit. 
    always_ff @( posedge clk, negedge arstn ) begin
        if ( ~ arstn ) begin
            // For 4-way set associative cache.
            dirty_mem [ 0 ] <= '0;
            dirty_mem [ 1 ] <= '0;
            dirty_mem [ 2 ] <= '0;
            dirty_mem [ 3 ] <= '0;
        end
        else if ( write_en ) begin
            dirty_mem[ match ][ s_index ] <= 1'b1;
        end
        else if ( block_write_en ) begin
            dirty_mem[ match ][ s_index ] <= 1'b0;
        end
    end

    // Write valid bit. 
    always_ff @( posedge clk, negedge arstn ) begin
        if ( ~ arstn ) begin
            // For 4-way set associative cache.
            valid_mem [ 0 ] <= '0;
            valid_mem [ 1 ] <= '0;
            valid_mem [ 2 ] <= '0;
            valid_mem [ 3 ] <= '0;
        end
        else if ( valid_update ) begin
            valid_mem[ match ][ s_index ] <= 1'b1;
        end
    end

    // Write LRU set.
    always_ff @( posedge clk, negedge arstn ) begin
        if ( ~arstn ) begin
            lru_set <= '0;
        end
        else if ( lru_update ) begin
            lru_set[ s_index ] <= 1'b1;
        end
    end

    // Write LRU.
    integer j;
    always_ff @( posedge clk ) begin
        if ( ~ lru_set[ s_index ] ) begin
            // For 4-way set associative cache.
            lru_mem [ 0 ][ s_index ] <= 2'b00;
            lru_mem [ 1 ][ s_index ] <= 2'b01;
            lru_mem [ 2 ][ s_index ] <= 2'b10;
            lru_mem [ 3 ][ s_index ] <= 2'b11;
        end
        else if ( lru_update ) begin
            if ( o_hit ) begin
                lru_mem[ match ][ s_index ] <= 2'b11;
                for ( j = 0; j < N; j++ ) begin
                    if ( lru_mem[ j ][ s_index ] > lru_mem[ match ][ s_index ] ) begin
                        lru_mem[ j ][ s_index ] <= lru_mem[ j ][ s_index ] - 2'b01;
                    end
                end
            end
        end
    end



    //------------------------
    // Read logic.
    //------------------------

    // Read word.
    always_comb begin
        case ( s_word_offset )
            4'b0000: o_data = data_mem[ s_index ][ match ][ 63 :0   ]; 
            4'b0001: o_data = data_mem[ s_index ][ match ][ 95 :32  ]; 
            4'b0010: o_data = data_mem[ s_index ][ match ][ 127:64  ]; 
            4'b0011: o_data = data_mem[ s_index ][ match ][ 159:96  ]; 
            4'b0100: o_data = data_mem[ s_index ][ match ][ 191:128 ]; 
            4'b0101: o_data = data_mem[ s_index ][ match ][ 223:160 ]; 
            4'b0110: o_data = data_mem[ s_index ][ match ][ 255:192 ]; 
            4'b0111: o_data = data_mem[ s_index ][ match ][ 287:224 ]; 
            4'b1000: o_data = data_mem[ s_index ][ match ][ 319:256 ]; 
            4'b1001: o_data = data_mem[ s_index ][ match ][ 351:288 ]; 
            4'b1010: o_data = data_mem[ s_index ][ match ][ 383:320 ]; 
            4'b1011: o_data = data_mem[ s_index ][ match ][ 415:352 ]; 
            4'b1100: o_data = data_mem[ s_index ][ match ][ 447:384 ]; 
            4'b1101: o_data = data_mem[ s_index ][ match ][ 479:416 ];
            4'b1110: o_data = data_mem[ s_index ][ match ][ 511:448 ];
            4'b1111: o_data = { { 32{1'b0}} , data_mem[ s_index ][ match ][ 511:480 ] }; // NOT FINISHED.
            default: o_data = '0;
        endcase
    end

    //Read dirty bit.
    assign o_dirty      = dirty_mem[ match ][ s_index ];
    assign o_data_block = data_mem[ s_index ][ match ];

    
endmodule