/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ------------------------------------------------------
// This is a 2-to-1 mux module to choose Memory address.
// It can choose either PCNext or calculated result.
// ------------------------------------------------------

module ysyx_201979054_mux2to1
// Parameters. 
#(
    parameter ADDR_WIDTH = 64
) 
// Port decleration.
(
    // Control signal.
    input  logic                      control_signal,

    // Input interface.
    input  logic [ ADDR_WIDTH - 1:0 ] i_mux_0,
    input  logic [ ADDR_WIDTH - 1:0 ] i_mux_1,

    // Output interface.
    output logic [ ADDR_WIDTH - 1:0 ] o_mux
);

    // MUX logic.
    always_comb begin
        if ( control_signal ) begin
            o_mux = i_mux_1;
        end
        else o_mux = i_mux_0;
    end
    
endmodule