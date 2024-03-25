/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------------------------
// This is a reset syncronizer module for asynchronous reset, synchronous release implementation.
// It ensures metastability.
// ----------------------------------------------------------------------------------------------

module reset_sync 
(
    input  logic clk,
    input  logic arstn,
    output logic rstn
);

    logic rst_signal;

    always_ff @( posedge clk, negedge arstn ) begin
        if ( !arstn ) { rstn, rst_signal } <= 2'b0;
        else          { rstn, rst_signal } <= { rst_signal, 1'b1 };
    end
    
endmodule