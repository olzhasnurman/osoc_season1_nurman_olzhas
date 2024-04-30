/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------
// This is a 3-to-1 mux module to choose ALU Src & Result Src.
// -----------------------------------------------------------

module mux3to1
// Parameters. 
#(
    parameter DATA_WIDTH = 64
) 
// Port decleration.
(
    // Control signal.
    input  logic [              1:0 ] control_signal,

    // Input interface.
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_0,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_1,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_2,

    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_mux
);

    // MUX logic.
    always_comb begin
        case ( control_signal )
            2'b00: o_mux = i_mux_0;
            2'b01: o_mux = i_mux_1;
            2'b10: o_mux = i_mux_2;
            default: o_mux = '0;
        endcase
    end
    
endmodule