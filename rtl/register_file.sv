/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------
// This is a register file component of processor based on RISC-V architecture.
// ----------------------------------------------------------------------------

module register_file
// Parameters.
#(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 5,
              REG_DEPTH  = 32
)
// Port decleration. 
(   
    // Common clock & enable signal.
    input logic clk,
    input logic write_en_3,

    //Input interface. 
    input logic [ ADDR_WIDTH - 1:0 ] i_addr_1,
    input logic [ ADDR_WIDTH - 1:0 ] i_addr_2,
    input logic [ ADDR_WIDTH - 1:0 ] i_addr_3,
    input logic [ DATA_WIDTH - 1:0 ] i_write_data_3,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data_1,
    output logic [ DATA_WIDTH - 1:0 ] o_read_data_2
);

    // Register block.
    logic [ DATA_WIDTH - 1:0 ] mem [ REG_DEPTH - 1:0 ];

    // Write logic.
    always_ff @( posedge clk ) begin 
        if ( write_en_3 ) begin
            mem[i_addr_3] <= i_write_data_3;
        end
    end

    // Read logic.
    assign o_read_data_1 = mem[i_addr_1];
    assign o_read_data_2 = mem[i_addr_2];

    
endmodule