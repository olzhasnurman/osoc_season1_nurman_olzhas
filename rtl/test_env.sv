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

    // Memory module signals.
    logic [ AXI_ADDR_WIDTH - 1:0 ] s_mem_addr;
    logic [ AXI_DATA_WIDTH - 1:0 ] s_mem_data_in;
    logic [ AXI_DATA_WIDTH - 1:0 ] s_mem_data_out;
    logic                          s_mem_we;
    logic                          s_successful_access;
    logic                          s_successful_read;
    logic                          s_successful_write;

    // Top module signals.
    logic                          s_count_done;
    logic                          s_start_read;
    logic                          s_start_write;
    logic [ DATA_WIDTH     - 1:0 ] s_cache_data_in;
    logic [ DATA_WIDTH     - 1:0 ] s_cache_data_out;
    logic [ AXI_ADDR_WIDTH - 1:0 ] s_cache_addr;

    // AXI module signals.
    logic [ AXI_ADDR_WIDTH - 1:0 ] s_axi_addr;
    logic [ AXI_DATA_WIDTH - 1:0 ] s_axi_data_in;
    logic [ AXI_DATA_WIDTH - 1:0 ] s_axi_data_out;
    logic                          s_axi_done;

    // Signalling messages.
    logic s_read_fault;
    logic s_write_fault;

    logic s_start_read_axi;
    logic s_start_write_axi;

    assign s_start_read_axi  = s_start_read  & ( ~s_count_done );
    assign s_start_write_axi = s_start_write & ( ~s_count_done );



    //-----------------------------------
    // LOWER LEVEL MODULE INSTANTIATIONS.
    //-----------------------------------

    //--------------------------------
    // Top processing module Instance.
    //--------------------------------
    top TOP_M (
        .clk               ( clk              ),
        .i_arstn           ( arstn            ),
        .i_done_axi        ( s_count_done     ),
        .i_data_read_axi   ( s_cache_data_in  ),
        .o_start_read_axi  ( s_start_read     ),
        .o_start_write_axi ( s_start_write    ),
        .o_addr            ( s_cache_addr     ),
        .o_data_write_axi  ( s_cache_data_out )
    );


    //---------------------------
    // AXI module Instance.
    //---------------------------
    axi4_lite_top AXI4_LITE_T (
        .clk                 ( clk                 ),
        .arstn               ( arstn               ),
        .i_data_mem          ( s_mem_data_out      ),
        .i_successful_access ( s_successful_access ),
        .i_successful_read   ( s_successful_read   ),
        .i_successful_write  ( s_successful_write  ),
        .o_data_mem          ( s_mem_data_in       ),
        .o_addr_mem          ( s_mem_addr          ),
        .o_we_mem            ( s_mem_we            ),
        .i_addr_cache        ( s_axi_addr          ),
        .i_data_cache        ( s_axi_data_in       ),
        .i_start_write       ( s_start_write_axi   ),
        .i_start_read        ( s_start_read_axi    ),
        .o_data_cache        ( s_axi_data_out      ),
        .o_done              ( s_axi_done          ),
        .o_read_fault        ( s_read_fault        ),
        .o_write_fault       ( s_write_fault       )
    );

    //---------------------------
    // Memory Unit Instance.
    //---------------------------
    mem_sim MEM_M (
        .clk                 ( clk                 ),
        .arstn               ( arstn               ),
        .write_en            ( s_mem_we            ),
        .i_data              ( s_mem_data_in       ),
        .i_addr              ( s_mem_addr          ),
        .o_data              ( s_mem_data_out      ),
        .o_successful_access ( s_successful_access ),
        .o_successful_read   ( s_successful_read   ),
        .o_successful_write  ( s_successful_write  )
    );


    //------------------------------------
    // Cache data transfer unit instance.
    //------------------------------------
    cache_data_transfer DATA_T0 (
        .clk                ( clk              ),
        .arstn              ( arstn            ),
        .i_start_read       ( s_start_read     ),
        .i_start_write      ( s_start_write    ),
        .i_axi_done         ( s_axi_done       ),
        .i_data_block_cache ( s_cache_data_out ),
        .i_data_axi         ( s_axi_data_out   ),
        .i_addr_cache       ( s_cache_addr     ),
        .o_count_done       ( s_count_done     ),
        .o_data_block_cache ( s_cache_data_in  ),
        .o_data_axi         ( s_axi_data_in    ),
        .o_addr_axi         ( s_axi_addr       )
    );



    
endmodule