/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------
// This is a nonarchitectural register without write enable signal.
// ----------------------------------------------------------------

module register
// Parameters.
#(
    parameter DATA_WIDTH = 64
)
// Port decleration. 
(   
    // Common clock & enable signal.
    input  logic                      clk,

    //Input interface. 
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data
);

    // Write logic.
    always_ff @( posedge clk ) begin 
        o_read_data <= i_write_data;
    end
    
endmodule