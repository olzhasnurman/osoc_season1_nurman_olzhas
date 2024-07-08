/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------
// This is a nonarchitectural register with write enable signal.
// -------------------------------------------------------------

module ysyx_201979054_register_en
// Parameters.
#(
    parameter DATA_WIDTH = 64
)
// Port decleration. 
(   
    // Common clock & enable signal.
    input  logic                      clk,
    input  logic                      write_en,
    input  logic                      arst,

    //Input interface. 
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data
);

    // Write logic.
    always_ff @( posedge clk, posedge arst ) begin 
        if ( arst ) o_read_data <= '0;
        else if ( write_en ) begin
            o_read_data <= i_write_data;
        end
    end
    
endmodule