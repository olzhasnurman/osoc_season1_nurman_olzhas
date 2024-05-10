/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------
// This is a memory module for simulation of outside memory unit. 
// ---------------------------------------------------------------

`define PATH_TO_MEM "./test/tests/instr/am-kernels/load-store-riscv64-nemu.txt"

module mem_sim 
#(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 64
)
(
    // Control signals.
    input  logic clk,
    input  logic arstn,
    input  logic write_en,

    // Input signals.
    input  logic [ DATA_WIDTH - 1:0 ] i_data,
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr,

    // Output signals.
    output logic [ DATA_WIDTH - 1:0 ] o_data
);
    logic [ DATA_WIDTH - 1:0 ] mem [ 524287:0];


    always_ff @( posedge clk, negedge arstn ) begin
        if ( !arstn ) begin
            $readmemh(`PATH_TO_MEM, mem);
        end
        else if ( write_en ) begin
            mem[ i_addr[ 20:2 ] ] <= i_data;
        end
    end

    assign o_data = mem[ i_addr [20:2] ];

    
endmodule

