/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------
// This module facilitates the data transfer between cache and AXI interfaces.
// -----------------------------------------------------------------------------

module cache_data_transfer
#(
    parameter AXI_DATA_WIDTH = 32,
              AXI_ADDR_WIDTH = 64,
              BLOCK_WIDTH    = 512,
              COUNT_LIMIT    = 4'b1111,
              COUNT_TO       = 16,
              ADDR_INCR_VAL  = 64'd4
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
    counter # (
        .LIMIT ( COUNT_LIMIT ),
        .SIZE  ( COUNT_TO    )
    ) COUNT0 (
        .clk      ( clk          ),
        .arst     ( arst         ),
        .run      ( i_axi_done   ),
        .restartn ( s_start      ),
        .o_done   ( o_count_done )
    );

    // Address increment module instance.
    addr_increment # (
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .INCR_VAL       ( ADDR_INCR_VAL  )
    ) ADD_INC0 (
        .clk    ( clk          ),
        .arst   ( arst         ),
        .run    ( s_start      ),
        .enable ( i_axi_done   ),
        .i_addr ( i_addr_cache ),
        .o_addr ( o_addr_axi   )
    );

    // FIFO module instance.
    fifo # (
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .FIFO_WIDTH     ( BLOCK_WIDTH    )
    ) FIFO0 (
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