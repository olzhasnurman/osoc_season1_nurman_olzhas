/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------------------
// This is a 8-to-1 mux module to choose Result Src.
// ---------------------------------------------------

module ysyx_201979054_mux8to1
// Parameters. 
#(
    parameter DATA_WIDTH = 64
) 
// Port decleration.
(
    // Control signal.
    input  logic [              2:0 ] control_signal,

    // Input interface.
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_0,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_1,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_2,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_3,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_4,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_5,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_6,
    input  logic [ DATA_WIDTH - 1:0 ] i_mux_7,

    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_mux
);

    // MUX logic.
    always_comb begin
        case ( control_signal )
            3'b000: o_mux = i_mux_0;
            3'b001: o_mux = i_mux_1;
            3'b010: o_mux = i_mux_2;
            3'b011: o_mux = i_mux_3;
            3'b100: o_mux = i_mux_4;
            3'b101: o_mux = i_mux_5;
            3'b110: o_mux = i_mux_6;
            3'b111: o_mux = i_mux_7;
            default: o_mux = '0;
        endcase
    end
    
endmodule