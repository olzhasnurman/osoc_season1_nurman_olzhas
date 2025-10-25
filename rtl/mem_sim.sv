/* Copyright (c) 2025 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------
// This is a memory module for simulation of outside memory unit. 
// ---------------------------------------------------------------

// `define PATH_TO_MEM "./test/tests/instr/riscv-tests/rv64ui-p-xori.txt"

module mem_sim 
#(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 32,
              ADDR_W = 7
)
(
    // Control signals.
    input  logic clk,
    input  logic arst,
    input  logic write_en,

    // Input signals.
    input  logic [ DATA_WIDTH - 1:0 ] i_data,
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr,

    // Output signals.
    output logic [ DATA_WIDTH - 1:0 ] o_data,
    output logic                      o_successful_access,
    output logic                      o_successful_read,
    output logic                      o_successful_write
);
    logic [ADDR_W - 1:0] s_addr;

    assign s_addr = i_addr[ADDR_W + 1:2];

    assign o_successful_read   = 1'b1;
    assign o_successful_write  = 1'b1;

    // Simulating multiple clock cycle memory access.
    logic [ 6:0 ] s_count;
    always_ff @( posedge clk, posedge arst ) begin
        if ( arst ) s_count <= '0;
        else        s_count <= s_count + 7'b1;
    end

    assign o_successful_access = (s_count == 7'b1111111);


    // mem_blk0 K_MEM_BLK0 (
    //     .clka  (clk        ),
    //     .addra (s_addr     ),
    //     .wea   (write_en   ),
    //     .dina  (i_data     ),
    //     .douta (o_data     )
    // );

    
endmodule
