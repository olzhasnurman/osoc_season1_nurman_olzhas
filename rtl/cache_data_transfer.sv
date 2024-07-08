/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------
// This module facilitates the data transfer between cache and AXI interfaces.
// -----------------------------------------------------------------------------

module ysyx_201979054_cache_data_transfer 
#(
    parameter AXI_DATA_WIDTH = 32,
              AXI_ADDR_WIDTH = 64,
              BLOCK_WIDTH    = 512
) 
(
    // Control signals.
    input  logic                          clk,
    input  logic                          arst,

    // Input interface.
    input  logic                          i_start_read,
    input  logic                          i_start_write,
    input  logic                          i_axi_done,
    input  logic [ BLOCK_WIDTH    - 1:0 ] i_data_block_cache,
    input  logic [ AXI_DATA_WIDTH - 1:0 ] i_data_axi,
    input  logic [ AXI_ADDR_WIDTH - 1:0 ] i_addr_cache,

    // Output interface.
    output logic                          o_count_done,
    output logic [ BLOCK_WIDTH    - 1:0 ] o_data_block_cache,
    output logic [ AXI_DATA_WIDTH - 1:0 ] o_data_axi,
    output logic [ AXI_ADDR_WIDTH - 1:0 ] o_addr_axi
);

    //------------------------
    // INTERNAL NETS.
    //------------------------
    logic s_start;

    assign s_start = i_start_read | i_start_write;

    //-----------------------------------
    // Lower-level module instantiations.
    //-----------------------------------

    // Counter module instance.
    ysyx_201979054_counter COUNT0 (
        .clk      ( clk          ),
        .arst     ( arst         ),
        .run      ( i_axi_done   ),
        .restartn ( s_start      ),
        .o_done   ( o_count_done )
    );

    // Address increment module instance.
    ysyx_201979054_addr_increment ADD_INC0 (
        .clk    ( clk          ),
        .run    ( s_start      ),
        .enable ( i_axi_done   ),
        .i_addr ( i_addr_cache ),
        .o_addr ( o_addr_axi   )
    );

    // FIFO module instance.
    ysyx_201979054_fifo FIFO0 (
        .clk          ( clk                ),
        .arst         ( arst               ),
        .write_en     ( i_axi_done         ),
        .start_write  ( i_start_write      ),
        .start_read   ( i_start_read       ),
        .i_data       ( i_data_axi         ),
        .i_data_block ( i_data_block_cache ),
        .o_data       ( o_data_axi         ),
        .o_data_block ( o_data_block_cache )
    );
    
endmodule