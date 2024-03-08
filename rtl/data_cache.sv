/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------
// This is a data cache implemneted using 4-way set associative cache.
// -------------------------------------------------------------------

module data_cache 
#(
    parameter SET_COUNT   = 256,
              WORD_COUNT  = 8,
              WORD_SIZE   = 64,
              BLOCK_WIDTH = 512,
              TAG_WIDTH   = 50,
              N           = 4,
              ADDR_WIDTH  = 64
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
    input  logic [ WORD_SIZE   - 1:0 ] i_data,
    input  logic [ BLOCK_WIDTH - 1:0 ] i_data_block,

    // Output Interface.
    output logic [ WORD_SIZE   - 1:0 ] o_data,
    output logic [ BLOCK_WIDTH - 1:0 ] o_data_block,
    output logic                       o_hit,
    output logic                       o_dirty

);  
    //-------------------------
    // Local Parameters.
    //-------------------------
    localparam WORD_OFFSET_W  = $clog2( WORD_COUNT  ); // 3 bit.
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
    integer i;
    logic [ $clog2 (N) - 1:0 ] match;
    always_comb begin
        for ( i = 0; i < N; i++) begin
            if ( valid_mem[ i ][ s_index ] & ( tag_mem [ s_index ][ i ] == s_tag_in ) ) begin
                match = i[ $clog2 (N) - 1:0 ];
                o_hit = 1'b1;
            end
            else begin
                match = '0;
                o_hit = 1'b0;
            end
        end
    end

    // Find LRU.
    integer k;
    always_comb begin
        for ( k = 0; k < N; k++ ) begin
            if ( lru_mem[k][ s_index ] == 2'b00 ) begin
                s_lru = k[ $clog2 (N) - 1:0 ];
            end
            else s_lru = '0;
        end
    end



    //-------------------------
    // Write logic.
    //-------------------------

    // Write data logic.
    always_ff @( posedge clk ) begin
        if ( write_en ) begin
            case ( s_word_offset )
                3'b000:  data_mem[ s_index ][ match ][ 63 :0   ] <= i_data; 
                3'b001:  data_mem[ s_index ][ match ][ 127:64  ] <= i_data; 
                3'b010:  data_mem[ s_index ][ match ][ 191:128 ] <= i_data; 
                3'b011:  data_mem[ s_index ][ match ][ 255:192 ] <= i_data;  
                3'b100:  data_mem[ s_index ][ match ][ 319:256 ] <= i_data; 
                3'b101:  data_mem[ s_index ][ match ][ 383:320 ] <= i_data; 
                3'b110:  data_mem[ s_index ][ match ][ 447:384 ] <= i_data;
                3'b111:  data_mem[ s_index ][ match ][ 511:448 ] <= i_data;
                default: data_mem[ s_index ][ match ][ 63:0    ] <= '0;
            endcase   
        end
        else if ( block_write_en ) begin
            data_mem[ s_index ][ s_lru ] <= i_data_block;
            tag_mem [ s_index ][ s_lru ] <= s_tag_in; 
        end
    end

    // Modify dirty bit. 
    always_ff @( posedge clk ) begin
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
    always_ff @( posedge clk ) begin
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
    always_ff @( posedge clk ) begin
        if ( ~arstn ) begin
            lru_set <= '0;
        end
        else if ( lru_update ) begin
            lru_set[ s_index ] <= 1'b1;
        end
    end

    // Write LRU. NOT FINISHED.
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
                for ( j = 0; j < N; j++ ) begin
                    if ( j[ $clog2 (N) - 1:0 ] == match ) begin
                        lru_mem[ match ][ s_index ] <= 2'b11;
                    end
                    else if ( j > match ) begin
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
            3'b000:  o_data =  data_mem[ s_index ][ match ][ 63 :0   ]; 
            3'b001:  o_data =  data_mem[ s_index ][ match ][ 127:64  ]; 
            3'b010:  o_data =  data_mem[ s_index ][ match ][ 191:128 ]; 
            3'b011:  o_data =  data_mem[ s_index ][ match ][ 255:192 ];  
            3'b100:  o_data =  data_mem[ s_index ][ match ][ 319:256 ]; 
            3'b101:  o_data =  data_mem[ s_index ][ match ][ 383:320 ]; 
            3'b110:  o_data =  data_mem[ s_index ][ match ][ 447:384 ];
            3'b111:  o_data =  data_mem[ s_index ][ match ][ 511:448 ];
            default: o_data = '0;
        endcase
    end

    //Read dirty bit.
    assign o_dirty = dirty_mem[ match ][ s_index ];
    assign o_data_block = data_mem[ s_index ][ match ];

    
endmodule