/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------
// This is a data cache implemneted using 4-way set associative cache.
// -------------------------------------------------------------------

module data_cache 
#(
    parameter SET_COUNT   = 256,
              WORD_SIZE   = 32,
              BLOCK_WIDTH = 512,
              N           = 4,
              ADDR_WIDTH  = 64,
              REG_WIDTH   = 64
) 
(
    // Control signals.
    input  logic                       clk,
    input  logic                       arst,
    input  logic                       write_en,
    input  logic                       valid_update,
    input  logic                       lru_update,
    input  logic                       block_write_en,
    
    // Input Interface.
    input  logic [ ADDR_WIDTH  - 1:0 ] i_data_addr,
    input  logic [ REG_WIDTH   - 1:0 ] i_data,
    input  logic [ BLOCK_WIDTH - 1:0 ] i_data_block,
    input  logic [               1:0 ] i_store_type,
    input  logic                       i_addr_control,

    // Output Interface.
    output logic [ REG_WIDTH   - 1:0 ] o_data,
    output logic [ BLOCK_WIDTH - 1:0 ] o_data_block,
    output logic                       o_hit,
    output logic                       o_dirty,
    output logic [ ADDR_WIDTH  - 1:0 ] o_addr_axi,
    output logic                       o_store_addr_ma

);  
    //-------------------------
    // Local Parameters.
    //-------------------------
    localparam WORD_COUNT     = BLOCK_WIDTH/WORD_SIZE; // 16 bits.

    localparam WORD_OFFSET_W  = $clog2( WORD_COUNT  ); // 4 bits.
    localparam BLOCK_NUMBER_W = $clog2( SET_COUNT );   // 8 bits.
    localparam BYTE_OFFSET_W  = $clog2( WORD_SIZE/8 ); // 2 bits.

    localparam TAG_MSB         = ADDR_WIDTH - 1;                                 // 63.
    localparam TAG_LSB         = BLOCK_NUMBER_W + WORD_OFFSET_W + BYTE_OFFSET_W; // 14.
    localparam TAG_WIDTH       = TAG_MSB - TAG_LSB + 1;                          // 50
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
    logic [                                 1:0 ] s_byte_offset;

    logic [ $clog2( N ) - 1:0 ] s_lru;
    logic [           N - 1:0 ] s_lru_found;
    logic [           N - 1:0 ] s_hit;

    logic [ ADDR_WIDTH - 1:0 ] s_addr_wb;
    logic [ ADDR_WIDTH - 1:0 ] s_addr;

    // Store misalignment signals.
    logic s_store_addr_ma_sh;
    logic s_store_addr_ma_sw;
    logic s_store_addr_ma_sd;



    //-------------------------
    // Continious assignments.
    //-------------------------
    assign s_tag_in      = i_data_addr[ TAG_MSB        :TAG_LSB         ];
    assign s_index       = i_data_addr[ INDEX_MSB      :INDEX_LSB       ]; 
    assign s_word_offset = i_data_addr[ WORD_OFFSET_MSB:WORD_OFFSET_LSB ];
    assign s_byte_offset = i_data_addr[               1:0               ];


    assign s_store_addr_ma_sh = s_byte_offset[0];
    assign s_store_addr_ma_sw = | s_byte_offset;
    assign s_store_addr_ma_sd = s_store_addr_ma_sw | s_word_offset[0];


    //----------------------------------------
    // Store address misaligned calculation.
    //----------------------------------------
    always_comb begin
        case ( i_store_type )
            2'b11: o_store_addr_ma = s_store_addr_ma_sd; // SD instruction.
            2'b10: o_store_addr_ma = s_store_addr_ma_sw; // SW instruction.
            2'b01: o_store_addr_ma = s_store_addr_ma_sh; // SH instruction.
            2'b00: o_store_addr_ma = 1'b0;               // SB instruction.
            default: o_store_addr_ma = 1'b0;
        endcase
    end



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
    logic [ $clog2 (N) - 1:0 ] s_match;
    always_comb begin
        s_hit[0] = valid_mem[ 0 ][ s_index ] & ( tag_mem [ s_index ][ 0 ] == s_tag_in );
        s_hit[1] = valid_mem[ 1 ][ s_index ] & ( tag_mem [ s_index ][ 1 ] == s_tag_in );
        s_hit[2] = valid_mem[ 2 ][ s_index ] & ( tag_mem [ s_index ][ 2 ] == s_tag_in );
        s_hit[3] = valid_mem[ 3 ][ s_index ] & ( tag_mem [ s_index ][ 3 ] == s_tag_in );

        o_hit = | s_hit;

        if ( o_hit ) begin
            casez ( s_hit )
                4'bzzz1: s_match = 2'b00;
                4'bzz10: s_match = 2'b01;
                4'bz100: s_match = 2'b10;
                4'b1000: s_match = 2'b11;
                default: s_match = 2'b00;
            endcase  
            
        end
        else s_match = s_lru;
    end

    // Find LRU.
    always_comb begin
        s_lru_found[0] = lru_mem[0][ s_index ] == 2'b00;
        s_lru_found[1] = lru_mem[1][ s_index ] == 2'b00;
        s_lru_found[2] = lru_mem[2][ s_index ] == 2'b00;
        s_lru_found[3] = lru_mem[3][ s_index ] == 2'b00;

        casez ( s_lru_found )
            4'bzzz1: s_lru = 2'b00;
            4'bzz10: s_lru = 2'b01;
            4'bz100: s_lru = 2'b10;
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
                    case ( s_word_offset[3:1] )
                        3'b000:  data_mem[ s_index ][ s_match ][ 63 :0   ] <= i_data; 
                        3'b001:  data_mem[ s_index ][ s_match ][ 127:64  ] <= i_data; 
                        3'b010:  data_mem[ s_index ][ s_match ][ 191:128 ] <= i_data; 
                        3'b011:  data_mem[ s_index ][ s_match ][ 255:192 ] <= i_data; 
                        3'b100:  data_mem[ s_index ][ s_match ][ 319:256 ] <= i_data; 
                        3'b101:  data_mem[ s_index ][ s_match ][ 383:320 ] <= i_data; 
                        3'b110:  data_mem[ s_index ][ s_match ][ 447:384 ] <= i_data; 
                        3'b111:  data_mem[ s_index ][ s_match ][ 511:448 ] <= i_data;
                        default: data_mem[ s_index ][ s_match ][ 63:0    ] <= '0;
                    endcase                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
                end

                // SW Instruction.
                2'b10: begin
                    case ( s_word_offset )
                        4'b0000: data_mem[ s_index ][ s_match ][ 31 :0   ] <= i_data[ 31:0 ]; 
                        4'b0001: data_mem[ s_index ][ s_match ][ 63 :32  ] <= i_data[ 31:0 ]; 
                        4'b0010: data_mem[ s_index ][ s_match ][ 95 :64  ] <= i_data[ 31:0 ]; 
                        4'b0011: data_mem[ s_index ][ s_match ][ 127:96  ] <= i_data[ 31:0 ]; 
                        4'b0100: data_mem[ s_index ][ s_match ][ 159:128 ] <= i_data[ 31:0 ]; 
                        4'b0101: data_mem[ s_index ][ s_match ][ 191:160 ] <= i_data[ 31:0 ]; 
                        4'b0110: data_mem[ s_index ][ s_match ][ 223:192 ] <= i_data[ 31:0 ]; 
                        4'b0111: data_mem[ s_index ][ s_match ][ 255:224 ] <= i_data[ 31:0 ]; 
                        4'b1000: data_mem[ s_index ][ s_match ][ 287:256 ] <= i_data[ 31:0 ]; 
                        4'b1001: data_mem[ s_index ][ s_match ][ 319:288 ] <= i_data[ 31:0 ]; 
                        4'b1010: data_mem[ s_index ][ s_match ][ 351:320 ] <= i_data[ 31:0 ]; 
                        4'b1011: data_mem[ s_index ][ s_match ][ 383:352 ] <= i_data[ 31:0 ]; 
                        4'b1100: data_mem[ s_index ][ s_match ][ 415:384 ] <= i_data[ 31:0 ]; 
                        4'b1101: data_mem[ s_index ][ s_match ][ 447:416 ] <= i_data[ 31:0 ];
                        4'b1110: data_mem[ s_index ][ s_match ][ 479:448 ] <= i_data[ 31:0 ];
                        4'b1111: data_mem[ s_index ][ s_match ][ 511:480 ] <= i_data[ 31:0 ];
                        default: data_mem[ s_index ][ s_match ][ 31:0    ] <= '0;
                    endcase    
                end 

                // SH Instruction.
                2'b01: begin
                    case ( {s_word_offset, s_byte_offset[1]} )
                        5'b00000: data_mem[ s_index ][ s_match ][ 15 :0   ] <= i_data[ 15:0 ]; 
                        5'b00001: data_mem[ s_index ][ s_match ][ 31 :16  ] <= i_data[ 15:0 ]; 
                        5'b00010: data_mem[ s_index ][ s_match ][ 47 :32  ] <= i_data[ 15:0 ]; 
                        5'b00011: data_mem[ s_index ][ s_match ][ 63 :48  ] <= i_data[ 15:0 ]; 
                        5'b00100: data_mem[ s_index ][ s_match ][ 79 :64  ] <= i_data[ 15:0 ]; 
                        5'b00101: data_mem[ s_index ][ s_match ][ 95 :80  ] <= i_data[ 15:0 ]; 
                        5'b00110: data_mem[ s_index ][ s_match ][ 111:96  ] <= i_data[ 15:0 ]; 
                        5'b00111: data_mem[ s_index ][ s_match ][ 127:112 ] <= i_data[ 15:0 ]; 
                        5'b01000: data_mem[ s_index ][ s_match ][ 143:128 ] <= i_data[ 15:0 ]; 
                        5'b01001: data_mem[ s_index ][ s_match ][ 159:144 ] <= i_data[ 15:0 ]; 
                        5'b01010: data_mem[ s_index ][ s_match ][ 175:160 ] <= i_data[ 15:0 ]; 
                        5'b01011: data_mem[ s_index ][ s_match ][ 191:176 ] <= i_data[ 15:0 ]; 
                        5'b01100: data_mem[ s_index ][ s_match ][ 207:192 ] <= i_data[ 15:0 ]; 
                        5'b01101: data_mem[ s_index ][ s_match ][ 223:208 ] <= i_data[ 15:0 ]; 
                        5'b01110: data_mem[ s_index ][ s_match ][ 239:224 ] <= i_data[ 15:0 ];
                        5'b01111: data_mem[ s_index ][ s_match ][ 255:240 ] <= i_data[ 15:0 ]; 
                        5'b10000: data_mem[ s_index ][ s_match ][ 271:256 ] <= i_data[ 15:0 ]; 
                        5'b10001: data_mem[ s_index ][ s_match ][ 287:272 ] <= i_data[ 15:0 ]; 
                        5'b10010: data_mem[ s_index ][ s_match ][ 303:288 ] <= i_data[ 15:0 ]; 
                        5'b10011: data_mem[ s_index ][ s_match ][ 319:304 ] <= i_data[ 15:0 ]; 
                        5'b10100: data_mem[ s_index ][ s_match ][ 335:320 ] <= i_data[ 15:0 ]; 
                        5'b10101: data_mem[ s_index ][ s_match ][ 351:336 ] <= i_data[ 15:0 ]; 
                        5'b10110: data_mem[ s_index ][ s_match ][ 367:352 ] <= i_data[ 15:0 ]; 
                        5'b10111: data_mem[ s_index ][ s_match ][ 383:368 ] <= i_data[ 15:0 ]; 
                        5'b11000: data_mem[ s_index ][ s_match ][ 399:384 ] <= i_data[ 15:0 ]; 
                        5'b11001: data_mem[ s_index ][ s_match ][ 415:400 ] <= i_data[ 15:0 ]; 
                        5'b11010: data_mem[ s_index ][ s_match ][ 431:416 ] <= i_data[ 15:0 ];
                        5'b11011: data_mem[ s_index ][ s_match ][ 447:432 ] <= i_data[ 15:0 ];
                        5'b11100: data_mem[ s_index ][ s_match ][ 463:448 ] <= i_data[ 15:0 ];
                        5'b11101: data_mem[ s_index ][ s_match ][ 479:464 ] <= i_data[ 15:0 ];
                        5'b11110: data_mem[ s_index ][ s_match ][ 495:480 ] <= i_data[ 15:0 ];
                        5'b11111: data_mem[ s_index ][ s_match ][ 511:496 ] <= i_data[ 15:0 ];
                        default:  data_mem[ s_index ][ s_match ][ 31:0    ] <= '0;
                    endcase
                end

                // SB Instruction.
                2'b00: begin
                    case ( {s_word_offset, s_byte_offset} )
                        6'b000000: data_mem[ s_index ][ s_match ][ 7  :0   ] <= i_data[ 7:0 ]; 
                        6'b000001: data_mem[ s_index ][ s_match ][ 15 :8   ] <= i_data[ 7:0 ]; 
                        6'b000010: data_mem[ s_index ][ s_match ][ 23 :16  ] <= i_data[ 7:0 ]; 
                        6'b000011: data_mem[ s_index ][ s_match ][ 31 :24  ] <= i_data[ 7:0 ];

                        6'b000100: data_mem[ s_index ][ s_match ][ 39 :32  ] <= i_data[ 7:0 ]; 
                        6'b000101: data_mem[ s_index ][ s_match ][ 47 :40  ] <= i_data[ 7:0 ]; 
                        6'b000110: data_mem[ s_index ][ s_match ][ 55 :48  ] <= i_data[ 7:0 ]; 
                        6'b000111: data_mem[ s_index ][ s_match ][ 63 :56  ] <= i_data[ 7:0 ]; 

                        6'b001000: data_mem[ s_index ][ s_match ][ 71 :64  ] <= i_data[ 7:0 ]; 
                        6'b001001: data_mem[ s_index ][ s_match ][ 79 :72  ] <= i_data[ 7:0 ]; 
                        6'b001010: data_mem[ s_index ][ s_match ][ 87 :80  ] <= i_data[ 7:0 ]; 
                        6'b001011: data_mem[ s_index ][ s_match ][ 95 :88  ] <= i_data[ 7:0 ]; 

                        6'b001100: data_mem[ s_index ][ s_match ][ 103:96  ] <= i_data[ 7:0 ]; 
                        6'b001101: data_mem[ s_index ][ s_match ][ 111:104 ] <= i_data[ 7:0 ]; 
                        6'b001110: data_mem[ s_index ][ s_match ][ 119:112 ] <= i_data[ 7:0 ]; 
                        6'b001111: data_mem[ s_index ][ s_match ][ 127:120 ] <= i_data[ 7:0 ]; 

                        6'b010000: data_mem[ s_index ][ s_match ][ 135:128 ] <= i_data[ 7:0 ]; 
                        6'b010001: data_mem[ s_index ][ s_match ][ 143:136 ] <= i_data[ 7:0 ]; 
                        6'b010010: data_mem[ s_index ][ s_match ][ 151:144 ] <= i_data[ 7:0 ]; 
                        6'b010011: data_mem[ s_index ][ s_match ][ 159:152 ] <= i_data[ 7:0 ];

                        6'b010100: data_mem[ s_index ][ s_match ][ 167:160 ] <= i_data[ 7:0 ]; 
                        6'b010101: data_mem[ s_index ][ s_match ][ 175:168 ] <= i_data[ 7:0 ]; 
                        6'b010110: data_mem[ s_index ][ s_match ][ 183:176 ] <= i_data[ 7:0 ]; 
                        6'b010111: data_mem[ s_index ][ s_match ][ 191:184 ] <= i_data[ 7:0 ];

                        6'b011000: data_mem[ s_index ][ s_match ][ 199:192 ] <= i_data[ 7:0 ]; 
                        6'b011001: data_mem[ s_index ][ s_match ][ 207:200 ] <= i_data[ 7:0 ]; 
                        6'b011010: data_mem[ s_index ][ s_match ][ 215:208 ] <= i_data[ 7:0 ]; 
                        6'b011011: data_mem[ s_index ][ s_match ][ 223:216 ] <= i_data[ 7:0 ];

                        6'b011100: data_mem[ s_index ][ s_match ][ 231:224 ] <= i_data[ 7:0 ];
                        6'b011101: data_mem[ s_index ][ s_match ][ 239:232 ] <= i_data[ 7:0 ]; 
                        6'b011110: data_mem[ s_index ][ s_match ][ 247:240 ] <= i_data[ 7:0 ]; 
                        6'b011111: data_mem[ s_index ][ s_match ][ 255:248 ] <= i_data[ 7:0 ];

                        6'b100000: data_mem[ s_index ][ s_match ][ 263:256 ] <= i_data[ 7:0 ]; 
                        6'b100001: data_mem[ s_index ][ s_match ][ 271:264 ] <= i_data[ 7:0 ]; 
                        6'b100010: data_mem[ s_index ][ s_match ][ 279:272 ] <= i_data[ 7:0 ]; 
                        6'b100011: data_mem[ s_index ][ s_match ][ 287:280 ] <= i_data[ 7:0 ];

                        6'b100100: data_mem[ s_index ][ s_match ][ 295:288 ] <= i_data[ 7:0 ];  
                        6'b100101: data_mem[ s_index ][ s_match ][ 303:296 ] <= i_data[ 7:0 ]; 
                        6'b100110: data_mem[ s_index ][ s_match ][ 311:304 ] <= i_data[ 7:0 ]; 
                        6'b100111: data_mem[ s_index ][ s_match ][ 319:312 ] <= i_data[ 7:0 ]; 

                        6'b101000: data_mem[ s_index ][ s_match ][ 327:320 ] <= i_data[ 7:0 ]; 
                        6'b101001: data_mem[ s_index ][ s_match ][ 335:328 ] <= i_data[ 7:0 ]; 
                        6'b101010: data_mem[ s_index ][ s_match ][ 343:336 ] <= i_data[ 7:0 ]; 
                        6'b101011: data_mem[ s_index ][ s_match ][ 351:344 ] <= i_data[ 7:0 ]; 

                        6'b101100: data_mem[ s_index ][ s_match ][ 359:352 ] <= i_data[ 7:0 ]; 
                        6'b101101: data_mem[ s_index ][ s_match ][ 367:360 ] <= i_data[ 7:0 ]; 
                        6'b101110: data_mem[ s_index ][ s_match ][ 375:368 ] <= i_data[ 7:0 ]; 
                        6'b101111: data_mem[ s_index ][ s_match ][ 383:376 ] <= i_data[ 7:0 ];

                        6'b110000: data_mem[ s_index ][ s_match ][ 391:384 ] <= i_data[ 7:0 ];
                        6'b110001: data_mem[ s_index ][ s_match ][ 399:392 ] <= i_data[ 7:0 ];
                        6'b110010: data_mem[ s_index ][ s_match ][ 407:400 ] <= i_data[ 7:0 ]; 
                        6'b110011: data_mem[ s_index ][ s_match ][ 415:408 ] <= i_data[ 7:0 ];

                        6'b110100: data_mem[ s_index ][ s_match ][ 423:416 ] <= i_data[ 7:0 ]; 
                        6'b110101: data_mem[ s_index ][ s_match ][ 431:424 ] <= i_data[ 7:0 ];
                        6'b110110: data_mem[ s_index ][ s_match ][ 439:432 ] <= i_data[ 7:0 ]; 
                        6'b110111: data_mem[ s_index ][ s_match ][ 447:440 ] <= i_data[ 7:0 ];

                        6'b111000: data_mem[ s_index ][ s_match ][ 455:448 ] <= i_data[ 7:0 ]; 
                        6'b111001: data_mem[ s_index ][ s_match ][ 463:456 ] <= i_data[ 7:0 ]; 
                        6'b111010: data_mem[ s_index ][ s_match ][ 471:464 ] <= i_data[ 7:0 ]; 
                        6'b111011: data_mem[ s_index ][ s_match ][ 479:472 ] <= i_data[ 7:0 ]; 

                        6'b111100: data_mem[ s_index ][ s_match ][ 487:480 ] <= i_data[ 7:0 ]; 
                        6'b111101: data_mem[ s_index ][ s_match ][ 495:488 ] <= i_data[ 7:0 ]; 
                        6'b111110: data_mem[ s_index ][ s_match ][ 503:496 ] <= i_data[ 7:0 ]; 
                        6'b111111: data_mem[ s_index ][ s_match ][ 511:504 ] <= i_data[ 7:0 ]; 

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
    always_ff @( posedge clk, posedge arst ) begin
        if ( arst ) begin
            // For 4-way set associative cache.
            dirty_mem [ 0 ] <= '0;
            dirty_mem [ 1 ] <= '0;
            dirty_mem [ 2 ] <= '0;
            dirty_mem [ 3 ] <= '0;
        end
        else if ( write_en ) begin
            dirty_mem[ s_match ][ s_index ] <= 1'b1;
        end
        else if ( block_write_en ) begin
            dirty_mem[ s_lru ][ s_index ] <= 1'b0;
        end
    end

    // Write valid bit. 
    always_ff @( posedge clk, posedge arst ) begin
        if ( arst ) begin
            // For 4-way set associative cache.
            valid_mem [ 0 ] <= '0;
            valid_mem [ 1 ] <= '0;
            valid_mem [ 2 ] <= '0;
            valid_mem [ 3 ] <= '0;
        end
        else if ( valid_update ) begin
            valid_mem[ s_lru ][ s_index ] <= 1'b1;
        end
    end

    // Write LRU set.
    always_ff @( posedge clk, posedge arst ) begin
        if ( arst ) begin
            lru_set <= '0;
        end
        else if ( lru_update ) begin
            lru_set[ s_index ] <= 1'b1;
        end
    end

    // Write LRU.
    integer j;
    always_ff @( posedge clk ) begin
        if ( lru_update ) begin
                lru_mem[ s_match ][ s_index ] <= 2'b11;
                for ( j = 0; j < N; j++ ) begin
                    if ( lru_mem[ j ][ s_index ] > lru_mem[ s_match ][ s_index ] ) begin
                        lru_mem[ j ][ s_index ] <= lru_mem[ j ][ s_index ] - 2'b01;
                    end
                end
        end
        else if ( ~ lru_set[ s_index ] ) begin
            // For 4-way set associative cache.
            lru_mem [ 0 ][ s_index ] <= 2'b00;
            lru_mem [ 1 ][ s_index ] <= 2'b01;
            lru_mem [ 2 ][ s_index ] <= 2'b10;
            lru_mem [ 3 ][ s_index ] <= 2'b11;
        end
    end



    //------------------------
    // Read logic.
    //------------------------

    // Read word.
    always_comb begin
        case ( s_word_offset )
            4'b0000: o_data = data_mem[ s_index ][ s_match ][ 63 :0   ]; 
            4'b0001: o_data = data_mem[ s_index ][ s_match ][ 95 :32  ]; 
            4'b0010: o_data = data_mem[ s_index ][ s_match ][ 127:64  ]; 
            4'b0011: o_data = data_mem[ s_index ][ s_match ][ 159:96  ]; 
            4'b0100: o_data = data_mem[ s_index ][ s_match ][ 191:128 ]; 
            4'b0101: o_data = data_mem[ s_index ][ s_match ][ 223:160 ]; 
            4'b0110: o_data = data_mem[ s_index ][ s_match ][ 255:192 ]; 
            4'b0111: o_data = data_mem[ s_index ][ s_match ][ 287:224 ]; 
            4'b1000: o_data = data_mem[ s_index ][ s_match ][ 319:256 ]; 
            4'b1001: o_data = data_mem[ s_index ][ s_match ][ 351:288 ]; 
            4'b1010: o_data = data_mem[ s_index ][ s_match ][ 383:320 ]; 
            4'b1011: o_data = data_mem[ s_index ][ s_match ][ 415:352 ]; 
            4'b1100: o_data = data_mem[ s_index ][ s_match ][ 447:384 ]; 
            4'b1101: o_data = data_mem[ s_index ][ s_match ][ 479:416 ];
            4'b1110: o_data = data_mem[ s_index ][ s_match ][ 511:448 ];
            4'b1111: o_data = { 32'b0, data_mem[ s_index ][ s_match ][ 511:480 ]};
            default: o_data = '0;
        endcase
    end

    //Read dirty bit.
    assign o_dirty      = dirty_mem[ s_lru ][ s_index ];
    assign o_data_block = data_mem[ s_index ][ s_lru ];
    assign s_addr_wb    = { tag_mem[ s_index ][ s_lru ], s_index, 6'b0 };
    assign s_addr       = { i_data_addr[ADDR_WIDTH - 1:INDEX_LSB ], 6'b0 };
    assign o_addr_axi   = i_addr_control ? s_addr : s_addr_wb;

    
endmodule