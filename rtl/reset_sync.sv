/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------------------------
// This is a reset syncronizer module.
// ----------------------------------------------------------------------------------------------

module reset_sync
(
    input  logic clk,
    input  logic arst,
    output logic arst_sync
);

    logic rst_signal;

    always_ff @( posedge clk, posedge arst ) begin
        if ( arst ) { arst_sync, rst_signal } <= 2'b11;
        else        { arst_sync, rst_signal } <= { rst_signal, 1'b0 };
    end

endmodule