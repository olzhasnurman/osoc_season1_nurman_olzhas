/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ------------------------------------------------------------------------------------------------------------------
// This is a top test environment module that connects top processor module, simlated memory & AXI interface module.
// ------------------------------------------------------------------------------------------------------------------

module test_env 
#(
    parameter AXI_ADDR_WIDTH = 64,
              AXI_DATA_WIDTH = 32,
              DATA_WIDTH     = 512
) 
(
    input logic clk,
    input logic arstn
);

    //------------------------
    // INTERNAL NETS.
    //------------------------

    logic [ AXI_DATA_WIDTH - 1:0 ] s_data_mem_in;
    logic [ AXI_DATA_WIDTH - 1:0 ] s_data_mem_out;
    logic [ AXI_ADDR_WIDTH - 1:0 ] s_addr_mem;
    logic                          s_we_mem;
    logic [ AXI_ADDR_WIDTH - 1:0 ] s_addr_cache;
    logic [ DATA_WIDTH     - 1:0 ] s_data_cache_in;
    logic                          s_start_write;
    logic                          s_start_read;
    logic [ DATA_WIDTH     - 1:0 ] s_data_cache_out;
    logic                          s_read_last_axi;
    logic                          s_b_resp_axi;
    logic                          s_access;



    //-----------------------------------
    // LOWER LEVEL MODULE INSTANTIATIONS.
    //-----------------------------------

    //--------------------------------
    // Top processing module Instance.
    //--------------------------------
    top TOP_M (
        .clk               ( clk              ),
        .i_arstn           ( arstn            ),
        .i_read_last_axi   ( s_read_last_axi  ),
        .i_data_read_axi   ( s_data_cache_in  ),
        .i_b_resp_axi      ( s_b_resp_axi     ),
        .o_start_read_axi  ( s_start_read     ),
        .o_start_write_axi ( s_start_write    ),
        .o_access          ( s_access         ),
        .o_data_write_axi  ( s_data_cache_out )
    );


    //---------------------------
    // AXI module Instance.
    //---------------------------
    axi_top AXI_M (
        .clk             ( clk              ),
        .arstn           ( arstn            ),
        .i_data_mem      ( s_data_mem_out   ),
        .o_data_mem      ( s_data_mem_in    ),
        .o_addr_mem      ( s_addr_mem       ),
        .o_we_mem        ( s_we_mem         ),
        .i_addr_cache    ( s_addr_cache     ),
        .i_data_cache    ( s_data_cache_out ),
        .i_start_write   ( s_start_write    ),
        .i_start_read    ( s_start_read     ),
        .o_data_cache    ( s_data_cache_in  ),
        .o_read_last_axi ( s_read_last_axi  ),
        .o_b_resp_axi    ( s_b_resp_axi     )
    );

    //---------------------------
    // Memory Unit Instance.
    //---------------------------
    mem_sim MEM_M (
        .clk      ( clk            ),
        .arstn    ( arstn          ),
        .write_en ( s_we_mem       ),
        .access   ( s_access       ),
        .i_data   ( s_data_mem_in  ),
        .i_addr   ( s_addr_mem     ),
        .o_data   ( s_data_mem_out )
    );



    
endmodule