/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ------------------------------------------------------------------
// This is a nonarchitectural register for storing data from memory.
// It takes into account case when double word is loaded from
// different sets in cache. 
// ------------------------------------------------------------------

module register_mem
// Parameters.
#(
    parameter DATA_WIDTH = 64
)
// Port decleration. 
(   
    // Common clock & enable signal.
    input  logic                      clk,
    input  logic                      arstn,
    input  logic                      write_en,

    //Input interface. 
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data,
    input  logic                      i_partial_ld,
    input  logic                      i_edge_ld,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data
);

    // Write logic.
    always_ff @( posedge clk, negedge arstn ) begin 
        if ( ~arstn ) begin
           o_read_data <= '0; 
        end
        else if ( write_en ) begin
            if ( i_partial_ld ) begin
                o_read_data <= { i_write_data[ 31:0 ], o_read_data[ 31:0 ] };
            end
            else if ( i_edge_ld ) begin
                o_read_data <= { { 32{1'b0} }, i_write_data[63:32] };
            end
            else o_read_data <= i_write_data;
        end
    end
    
endmodule