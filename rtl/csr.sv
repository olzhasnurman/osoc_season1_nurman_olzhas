/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------------------
// This is a top CSR module that contains instances of control & status register.
// -------------------------------------------------------------------------------

module csr
// Parameters. 
#(
    parameter REG_DATA_WIDTH  = 64
)
// Port declerations. 
(
    // Clock & Reset.
    input  logic                          clk,
    input  logic                          arstn,

    // Input Interface.
    input  logic                          i_mtvec_we,
    input  logic [ REG_DATA_WIDTH - 1:0 ] i_mtvec_data,
    input  logic                          i_mepc_we,
    input  logic [ REG_DATA_WIDTH - 1:0 ] i_mepc_data,
    input  logic                          i_mcause_we,
    input  logic [ REG_DATA_WIDTH - 1:0 ] i_mcause_data,

    // Output Interface. 
    output logic [ REG_DATA_WIDTH - 1:0 ] o_mtvec_data,
    output logic [ REG_DATA_WIDTH - 1:0 ] o_mepc_data,
    output logic [ REG_DATA_WIDTH - 1:0 ] o_mcause_data
);

    //-----------------------
    // REGISTER INSTANCES.
    //-----------------------


    //--------------------------
    // mtvec register instance.
    //--------------------------
    register_en_rst MTVEC0 (
        .clk          ( clk          ),
        .write_en     ( i_mtvec_we   ),
        .arstn        ( arstn        ),
        .i_write_data ( i_mtvec_data ),
        .o_read_data  ( o_mtvec_data ) 
    );


    //-------------------------
    // mepc register instance.
    //-------------------------
    register_en MEPC0 (
        .clk          ( clk         ),
        .write_en     ( i_mepc_we   ),
        .arstn        ( arstn       ),
        .i_write_data ( i_mepc_data ),
        .o_read_data  ( o_mepc_data ) 
    );


    //---------------------------
    // mcause register instance.
    //---------------------------
    register_en MCAUSE0 (
        .clk          ( clk           ),
        .write_en     ( i_mcause_we   ),
        .arstn        ( arstn         ),
        .i_write_data ( i_mcause_data ),
        .o_read_data  ( o_mcause_data ) 
    );


    //---------------------------------------------
    // Template.
    //----------------------------------------------
    // register_en module_name (
    //     .clk          (  ),
    //     .write_en     (  ),
    //     .arstn        (  ),
    //     .i_write_data (  ),
    //     .o_read_data  (  ) 
    // );



endmodule