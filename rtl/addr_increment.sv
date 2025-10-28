/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------
// This is a address increment module that increments the address
// by 4 when seding data in burst using AXI4-Lite protocol.
// ---------------------------------------------------------------

module addr_increment
#(
    parameter AXI_ADDR_WIDTH = 64,
              INCR_VAL       = 64'd4
)
(
    // Control Signal.
    input  logic clk,
    input  logic run,
    input  logic arst,
    input  logic enable,

    // Input interface.
    input  logic [ AXI_ADDR_WIDTH - 1:0 ] i_addr,

    // Output interface.
    output logic [ AXI_ADDR_WIDTH - 1:0 ] o_addr
);

    logic [ AXI_ADDR_WIDTH - 1:0 ] s_count;

    always_ff @( posedge clk, posedge arst ) begin
        if      ( arst   ) s_count <= '0;
        else if ( ~run   ) s_count <= '0;
        else if ( enable ) s_count <= s_count + INCR_VAL;
    end

    assign o_addr = i_addr + s_count;

endmodule