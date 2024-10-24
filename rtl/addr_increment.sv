/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------
// This is a address increment module that increments the address 
// by 4 when seding data in burst using AXI4-Lite protocol.
// ---------------------------------------------------------------

module addr_increment 
#(
    parameter AXI_ADDR_WIDTH = 64
) 
(
    // Control Signal.
    input  logic clk,
    input  logic run,
    input  logic enable,

    // Input interface.
    input  logic [ AXI_ADDR_WIDTH - 1:0 ] i_addr,

    // Output interface. 
    output logic [ AXI_ADDR_WIDTH - 1:0 ] o_addr
);

    logic [ AXI_ADDR_WIDTH - 1:0 ] s_addr;

    always_ff @( posedge clk ) begin
        if      ( ~run   ) s_addr <= i_addr;
        else if ( enable ) s_addr <= s_addr + 64'd4;
    end

    assign o_addr = s_addr;
    
endmodule