/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------
// This is a memory module for simulation of outside memory unit. 
// ---------------------------------------------------------------

`define PATH_TO_MEM "./test/tests/instr/riscv-tests/rv64ui-p-xori.txt"

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
    output logic [ DATA_WIDTH - 1:0 ] o_data,
    output logic                      o_successful_access,
    output logic                      o_successful_read,
    output logic                      o_successful_write
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

    assign o_data              = mem[ i_addr [20:2] ];
    assign o_successful_read   = 1'b1;
    assign o_successful_write  = 1'b1;

    // Simulating multiple clock cycle memory access.
    logic [ 6:0 ] s_count;
    always_ff @( posedge clk, negedge arstn ) begin
        if ( ~arstn ) s_count <= '0;
        else          s_count <= s_count + '1;
    end

    assign o_successful_access = (s_count == 7'b1111111); 

    
endmodule

