/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------
// This is a 3-to-1 mux module to choose ALU Src & Result Src.
// -----------------------------------------------------------

module mux3to1
// Parameters. 
#(
    parameter DATA_WIDTH = 32
) 
// Port decleration.
(
    // Control signal.
    input  logic [              1:0 ] control_signal,

    // Input interface.
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_1,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_2,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_3,

    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_mux
);

    // MUX logic.
    always_comb begin
        if ( control_signal[1] ) begin
            o_mux = i_mux_3;
        end
        else if ( control_signal[0] ) begin
            o_mux = i_mux_2;
        end
        else 
            o_mux = i_mux_1;
    end
    
endmodule