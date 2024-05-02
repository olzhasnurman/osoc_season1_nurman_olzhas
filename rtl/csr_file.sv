/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------
// This is a csr file component of processor based on RISC-V architecture.
// ----------------------------------------------------------------------------

module csr_file
// Parameters.
#(
    parameter DATA_WIDTH = 64,
              ADDR_WIDTH = 2,
              REG_DEPTH  = 4
)
// Port decleration. 
(   
    // Common clock & enable signal.
    input  logic                      clk,
    input  logic                      write_en,
    input  logic                      arstn,

    //Input interface. 
    input  logic [ ADDR_WIDTH - 1:0 ] i_read_addr,
    input  logic [ ADDR_WIDTH - 1:0 ] i_write_addr,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data
);

    // Register block.
    logic [ DATA_WIDTH - 1:0 ] mem [ REG_DEPTH - 1:0 ];

    // Write logic.
    always_ff @( posedge clk, negedge arstn ) begin 
        if ( ~arstn ) begin
            mem[0] <= '0; // Mepc.
            mem[1] <= '0; // Mcause.
            mem[2] <= '0; // Mtvec.
            mem[3] <= '0; // Reserved.
        end
        if ( write_en ) begin
            mem[i_write_addr] <= i_write_data;
        end
    end

    // Read logic.
    assign o_read_data = mem[i_read_addr];
    
endmodule