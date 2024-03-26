/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ------------------------------------------------------------
// This is a top AXI module that connects AXI master and slave.
// ------------------------------------------------------------


module moduleName 
#(
    parameter AXI_ADDR_WIDTH = 64,
              AXI_DATA_WIDTH = 32,
              DATA_WIDTH     = 512
) 
(
    input logic clk,
    input logic arstn,

    // Memory interface.
    input  logic [ AXI_DATA_WIDTH - 1:0 ] i_data_mem,
    output logic [ AXI_DATA_WIDTH - 1:0 ] o_data_mem,
    output logic [ AXI_ADDR_WIDTH - 1:0 ] o_addr_mem,
    output logic                          o_we_mem,

    // Cache interface. 
    input  logic i_addr_cache,
    input  logic i_data_cache,
    input  logic i_start_write,
    input  logic i_start_read,
    output logic o_data_cache,
    output logic o_read_last_axi,
    output logic o_b_resp_axi 
);



    //--------------------------------------
    // AXI Interface signals: WRITE
    //--------------------------------------

    // Write Channel: Address. Ignored AW_ID for now.
    logic                            AW_READY,
    logic                            AW_VALID,
    logic [                    2:0 ] AW_PROT,
    logic [ AXI_ADDR_WIDTH   - 1:0 ] AW_ADDR,
    logic [                    7:0 ] AW_LEN,   
    logic [                    2:0 ] AW_SIZE,  
    logic [                    1:0 ] AW_BURST, 

    // Write Channel: Data.
    logic                            W_READY,
    logic [ AXI_DATA_WIDTH   - 1:0 ] W_DATA,
    logic [ AXI_DATA_WIDTH/8 - 1:0 ] W_STRB, 
    logic                            W_LAST,
    logic                            W_VALID,

    // Write Channel: Response. Ignored B_ID for now.
    logic [                    1:0 ] B_RESP, 
    logic                            B_VALID,
    logic                            B_READY,

    //--------------------------------------
    // AXI Interface signals: READ
    //--------------------------------------

    // Read Channel: Address. Ignored AR_ID for now.
    logic                            AR_READY,
    logic                            AR_VALID,
    logic [                    7:0 ] AR_LEN,   
    logic [                    2:0 ] AR_SIZE,  
    logic [                    1:0 ] AR_BURST, 
    logic [ AXI_ADDR_WIDTH   - 1:0 ] AR_ADDR,
    logic [                    2:0 ] AR_PROT,

    // Read Channel: Data. Ignored R_ID for now.
    logic [ AXI_DATA_WIDTH   - 1:0 ] R_DATA,
    logic [                    1:0 ] R_RESP, 
    logic                            R_LAST, 
    logic                            R_VALID,
    logic                            R_READY


    //-----------------------------------
    // Lower-level module instantiations.
    //-----------------------------------

    // AXI master instance.
    axi_master AXI_M (
        .clk             ( clk             ),
        .arstn           ( arstn           ),
        .i_addr          ( i_addr_cache    ),
        .i_data          ( i_data_cache    ),
        .i_start_write   ( i_start_write   ),
        .i_start_read    ( i_start_read    ),
        .o_data          ( o_data_cache    ),
        .o_read_last_axi ( o_read_last_axi ),
        .o_b_resp_axi    ( o_b_resp_axi    ),
        .AW_READY        ( AW_READY        ),
        .AW_VALID        ( AW_VALID        ),
        .AW_PROT         ( AW_PROT         ),
        .AW_ADDR         ( AW_ADDR         ),
        .AW_LEN          ( AW_LEN          ),
        .AW_SIZE         ( AW_SIZE         ),
        .AW_BURST        ( AW_BURST        ),
        .W_READY         ( W_READY         ),
        .W_DATA          ( W_DATA          ),
        .W_STRB          ( W_STRB          ),
        .W_LAST          ( W_LAST          ),
        .W_VALID         ( W_VALID         ),
        .B_RESP          ( B_RESP          ),
        .B_VALID         ( B_VALID         ),
        .B_READY         ( B_READY         ),
        .AR_READY        ( AR_READY        ),
        .AR_VALID        ( AR_VALID        ),
        .AR_LEN          ( AR_LEN          ),
        .AR_SIZE         ( AR_SIZE         ),
        .AR_BURST        ( AR_BURST        ),
        .AR_ADDR         ( AR_ADDR         ),
        .AR_PROT         ( AR_PROT         ),
        .R_DATA          ( R_DATA          ),
        .R_RESP          ( R_RESP          ),
        .R_LAST          ( R_LAST          ),
        .R_VALID         ( R_VALID         ),
        .R_READY         ( R_READY         )
    );


    // AXI slave instance.
    axi_slave AXI_S (
        .clk        ( clk        ),
        .arstn      ( arstn      ),
        .i_data     ( i_data_mem ),
        .o_data     ( o_data_mem ),
        .o_addr     ( o_addr_mem ),
        .o_write_en ( o_we_mem   ),
        .AW_READY   ( AW_READY   ),
        .AW_VALID   ( AW_VALID   ),
        .AW_PROT    ( AW_PROT    ),
        .AW_ADDR    ( AW_ADDR    ),
        .AW_LEN     ( AW_LEN     ),
        .AW_SIZE    ( AW_SIZE    ),
        .AW_BURST   ( AW_BURST   ),
        .W_READY    ( W_READY    ),
        .W_DATA     ( W_DATA     ),
        .W_STRB     ( W_STRB     ),
        .W_LAST     ( W_LAST     ),
        .W_VALID    ( W_VALID    ),
        .B_RESP     ( B_RESP     ),
        .B_VALID    ( B_VALID    ),
        .B_READY    ( B_READY    ),
        .AR_READY   ( AR_READY   ),
        .AR_VALID   ( AR_VALID   ),
        .AR_LEN     ( AR_LEN     ),
        .AR_SIZE    ( AR_SIZE    ),
        .AR_BURST   ( AR_BURST   ),
        .AR_ADDR    ( AR_ADDR    ),
        .AR_PROT    ( AR_PROT    ),
        .R_DATA     ( R_DATA     ),
        .R_RESP     ( R_RESP     ),
        .R_LAST     ( R_LAST     ),
        .R_VALID    ( R_VALID    ),
        .R_READY    ( R_READY    )
    );

    
endmodule