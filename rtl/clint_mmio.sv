/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------
// This is a nonarchitectural register with write enable signal.
// -------------------------------------------------------------

module ysyx_201979054_clint_mmio 
#(
    parameter REG_WIDTH = 64
) 
(
    input  logic                     clk,
    input  logic                     arst,
    input  logic                     write_en_1,
    input  logic                     write_en_2,
    input  logic [ REG_WIDTH - 1:0 ] i_data,
    output logic                     o_timer_int_call
);

    logic [ REG_WIDTH - 1:0 ] mtime;
    logic [ REG_WIDTH - 1:0 ] mtimecmp;

    always_ff @( posedge clk, posedge arst ) begin
        if ( arst ) begin
            mtime    <= '0; 
            mtimecmp <= '0;
        end
        else begin
            if ( write_en_1 ) mtime <= i_data;
            else              mtime <= mtime + 64'b1;

            if ( write_en_2 ) mtimecmp <= i_data;
        end
    end

    assign o_timer_int_call = ( mtime >= mtimecmp );
    
endmodule