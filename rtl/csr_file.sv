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
    input  logic                      write_en_1,
    input  logic                      write_en_2,
    input  logic                      arstn,

    //Input interface. 
    input  logic [ ADDR_WIDTH - 1:0 ] i_read_addr,
    input  logic [ ADDR_WIDTH - 1:0 ] i_write_addr_1,
    input  logic [ ADDR_WIDTH - 1:0 ] i_write_addr_2,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data_1,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data_2,
    
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
        else begin
            if ( write_en_1 ) mem [ i_write_addr_1 ] <= i_write_data_1;
            if ( write_en_2 ) mem [ i_write_addr_2 ] <= i_write_data_2;  
        end
    end

    // Read logic.
    assign o_read_data = mem [ i_read_addr ];
    
endmodule