/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------
// This is a csr file component of processor based on RISC-V architecture.
// ----------------------------------------------------------------------------

module csr_file
// Parameters.
#(
    parameter DATA_WIDTH = 64,
              ADDR_WIDTH = 3,
              REG_DEPTH  = 8
)
// Port decleration. 
(   
    // Common clock & enable signal.
    input  logic                      clk,
    input  logic                      write_en_1,
    input  logic                      write_en_2,
    input  logic                      arst,

    //Input interface. 
    input  logic [ ADDR_WIDTH - 1:0 ] i_read_addr,
    input  logic [ ADDR_WIDTH - 1:0 ] i_write_addr_1,
    input  logic [ ADDR_WIDTH - 1:0 ] i_write_addr_2,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data_1,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data_2,
    input  logic                      i_timer_int_call,
    input  logic                      i_timer_int_jump,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data,
    output logic                      o_mie_mstatus,
    output logic                      o_mtip_mip,
    output logic                      o_mtie_mie
);

    // Register block.
    logic [ DATA_WIDTH - 1:0 ] mem [ REG_DEPTH - 1:0 ];

    // Write logic.
    always_ff @( posedge clk, posedge arst ) begin 
        if ( arst ) begin
            mem[ 0 ] <= '0; // Mstatus
            mem[ 1 ] <= '0; // Reserved.
            mem[ 2 ] <= '0; // Mie.
            mem[ 3 ] <= '0; // Mtvec.
            mem[ 4 ] <= '0; // Mcause.
            mem[ 5 ] <= '0; // Mepc.
            mem[ 6 ] <= '0; // Mip.
            mem[ 7 ] <= '0; // Reserved.
        end
        else begin
            if ( i_timer_int_call ) mem[ 6 ][ 7 ] <= 1'b1; // mip MTIP bit set.
            else                    mem[ 6 ][ 7 ] <= 1'b0; // mip MTIP bit clear. 
            if ( i_timer_int_jump ) mem[ 0 ][ 3 ] <= 1'b0; // mstatus MIE bit clear.
            if ( write_en_1 ) mem [ i_write_addr_1 ] <= i_write_data_1;
            if ( write_en_2 ) mem [ i_write_addr_2 ] <= i_write_data_2;  
        end
    end

    // Read logic.
    assign o_read_data   = mem [ i_read_addr ];
    assign o_mie_mstatus = mem [ 0 ][ 3 ];
    assign o_mtip_mip    = mem [ 6 ][ 7 ];
    assign o_mtie_mie    = mem [ 2 ][ 7 ];  
    
endmodule