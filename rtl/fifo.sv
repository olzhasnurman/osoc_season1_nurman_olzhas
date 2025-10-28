/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------------------
// This is fifo module that is used to store and output data as a queue in caching system.
// ----------------------------------------------------------------------------------------

module fifo
#(
    parameter AXI_DATA_WIDTH = 32,
              FIFO_WIDTH     = 512
)
(
    // Control signals.
    input  logic                          clk,
    input  logic                          arst,
    input  logic                          write_en,
    input  logic                          start_read,
    input  logic                          start_write,

    // Input interface.
    input  logic [ AXI_DATA_WIDTH - 1:0 ] i_data,
    input  logic [ FIFO_WIDTH     - 1:0 ] i_data_block,

    // Output logic.
    output logic [ AXI_DATA_WIDTH - 1:0 ] o_data,
    output logic [ FIFO_WIDTH     - 1:0 ] o_data_block
);

    always_ff @( posedge clk, posedge arst ) begin
        if      ( arst ) o_data_block <= '0;
        else if ( ( ~start_write ) & ( ~start_read ) ) o_data_block <= i_data_block;
        else if ( write_en ) o_data_block <= { i_data, o_data_block[ FIFO_WIDTH - 1:AXI_DATA_WIDTH ] };
    end

    assign o_data = o_data_block [ AXI_DATA_WIDTH - 1:0 ];

endmodule