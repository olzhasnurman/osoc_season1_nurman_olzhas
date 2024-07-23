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
    input  logic                     write_en,
    input  logic [             1:0 ] i_addr,
    input  logic [ REG_WIDTH - 1:0 ] i_data,
    output logic [ REG_WIDTH - 1:0 ] o_data,
    output logic                     o_timer_int_call,
    output logic                     o_software_int_call
);


    logic [ REG_WIDTH - 1:0 ] msip;
    logic [ REG_WIDTH - 1:0 ] mtime;
    logic [ REG_WIDTH - 1:0 ] mtimecmp;

    logic [ REG_WIDTH - 1:0 ] mem [ 3 :0 ];

    always_ff @( posedge clk, posedge arst ) begin
        if ( arst ) begin
            mem [ 0 ] <= '0; // MSIP.
            mem [ 1 ] <= '0; // MTIME
            mem [ 2 ] <= '0; // MTIMECMP.
            mem [ 3 ] <= '0; // Reserved.
        end
        else begin
            mem [ 1 ] <= mem [ 1 ] + 64'b1;
            
            if ( write_en ) mem [ i_addr ] <= i_data;
        end
    end

    assign msip     = mem [ 0 ]; 
    assign mtime    = mem [ 1 ];
    assign mtimecmp = mem [ 2 ];

    assign o_timer_int_call     = ( mtime >= mtimecmp );
    assign o_software_int_call  = ( msip != '0 );

    assign o_data = mem [ i_addr ];
    
endmodule