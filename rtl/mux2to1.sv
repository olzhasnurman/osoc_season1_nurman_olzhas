/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ------------------------------------------------------
// This is a 2-to-1 mux module to choose Memory address.
// It can choose either PCNext or calculated result.
// ------------------------------------------------------

module mux3to1
// Parameters. 
#(
    parameter ADDR_WIDTH = 32
) 
// Port decleration.
(
    // Control signal.
    input  logic                      control_signal,

    // Input interface.
    input  logic [ ADDR_WIDTH - 1:0 ] i_pc_next,
    input  logic [ ADDR_WIDTH - 1:0 ] i_result,

    // Output interface.
    output logic [ ADDR_WIDTH - 1:0 ] o_addr
);

    // MUX logic.
    always_comb begin
        if ( control_signal ) begin
            o_addr = i_result;
        end
        else o_addr = i_pc_next;
    end
    
endmodule