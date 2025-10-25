/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------------------------------
// This is a top CPU module.
// ---------------------------------------------------------------------------------------

module cpu (
    input        clock,
    input        reset,
    output [3:0] led
);

    //--------------------------------
    // Internal nets.
    //--------------------------------
    logic arst;

    // Memory module signals.
    logic [ 31:0 ] s_mem_addr;
    logic [ 31:0 ] s_mem_data_in;
    logic [ 31:0 ] s_mem_data_out;
    logic          s_mem_we;
    logic          s_successful_access;
    logic          s_successful_read;
    logic          s_successful_write;

    logic s_write_req;
    logic s_read_req;
    logic s_read_req_non_cacheable;
    logic s_write_req_non_cacheable;

    logic [ 511:0 ] s_data_block_write_top;
    logic [ 511:0 ] s_data_block_read_top;
    logic [ 511:0 ] s_data_block_read_top_apb;
    logic [  63:0 ] s_data_non_cacheable_r;
    logic [  31:0 ] s_data_non_cacheable_w;
    logic [  31:0 ] s_addr;
    logic [  31:0 ] s_addr_non_cacheable;
    logic [  31:0 ] s_addr_calc;
    logic [  31:0 ] s_addr_calc_apb;

    logic [ 31:0 ] s_read_axi_fifo;
    logic [ 31:0 ] s_write_axi_fifo;
    logic [ 31:0 ] s_write_axi_fifo_apb;

    logic [ 31:0 ] s_addr_axi;
    logic [ 31:0 ] s_write_axi;
    logic [ 31:0 ] s_read_axi;
    logic [ 31:0 ] s_reg_read_axi;

    logic s_axi_done;
    logic s_axi_handshake;


    logic s_start_read_axi;
    logic s_start_read_axi_cache;
    logic s_start_write_axi;
    logic s_start_write_axi_cache;

    logic s_count_done;
    logic s_count_done_apb;
    logic s_done;

    logic [ 2:0 ] s_axi_size;
    logic [ 2:0 ] s_axi_size_cache;
    logic [ 2:0 ] s_axi_size_non_cache;
    logic [ 7:0 ] s_axi_strb;
    logic [ 7:0 ] s_axi_strb_cache;


    assign s_axi_strb_cache      = 8'h0F;
    assign s_axi_size_cache      = 3'b10;
    assign s_write_axi_fifo      = s_write_axi_fifo_apb;
    assign s_addr_calc           = s_addr_calc_apb;
    assign s_data_block_read_top = s_data_block_read_top_apb;


    assign s_count_done = s_count_done_apb;

    assign s_start_read_axi_cache  = s_read_req  & ( ~ s_count_done );
    assign s_start_read_axi        = s_read_req_non_cacheable | s_start_read_axi_cache;
    assign s_start_write_axi_cache = s_write_req & ( ~ s_count_done );
    assign s_start_write_axi       = s_write_req_non_cacheable | s_start_write_axi_cache;
    
    assign s_addr_axi      = ( s_read_req_non_cacheable | s_write_req_non_cacheable ) ? s_addr_non_cacheable : s_addr_calc;
    assign s_axi_size      = ( s_read_req_non_cacheable | s_write_req_non_cacheable ) ? s_axi_size_non_cache : s_axi_size_cache;
    assign s_axi_strb      = s_write_req_non_cacheable  ? ( 8'h01 << s_addr_non_cacheable [ 2 : 0 ] ) : s_axi_strb_cache;

    assign s_data_non_cacheable_r = { 32'b0 , s_reg_read_axi };
    assign s_write_axi            = s_write_req_non_cacheable ? (s_data_non_cacheable_w << 8*s_addr_non_cacheable [ 2 : 0 ] ) : s_write_axi_fifo;

    assign s_done = ( s_count_done ) | ( s_axi_done & ( s_read_req_non_cacheable | s_write_req_non_cacheable ) ); 



    //-----------------------------------
    // LOWER LEVEL MODULE INSTANTIATIONS.
    //-----------------------------------

    //------------------------------
    // Reset Synchronizer Instance.
    //------------------------------
    reset_sync RST_SYNC (
        .clk       ( clock ),
        .arst      ( reset ),
        .arst_sync ( arst  )
    );



    //-----------------------------
    // Top datapath unit instance.
    //-----------------------------
    datapath TOP0 (
        .clk                  ( clock                     ),
        .arst                 ( arst                      ),
        .i_done_axi           ( s_done                    ),
        .i_data_read_axi      ( s_data_block_read_top     ),
        .i_data_non_cacheable ( s_data_non_cacheable_r    ),
        .o_data_non_cacheable ( s_data_non_cacheable_w    ),
        .o_start_read_axi     ( s_read_req                ),
        .o_start_read_axi_nc  ( s_read_req_non_cacheable  ),
        .o_start_write_axi_nc ( s_write_req_non_cacheable ),
        .o_start_write_axi    ( s_write_req               ),
        .o_addr               ( s_addr                    ),
        .o_addr_non_cacheable ( s_addr_non_cacheable      ),
        .o_size_non_cacheable ( s_axi_size_non_cache      ),
        .o_data_write_axi     ( s_data_block_write_top    )
    );



    wb_top WB_TOP0 (
        .clk_i                   (clock              ),
        .rst_i                   (arst               ),
        .cpu_start_rd_i          (s_start_read_axi   ),
        .cpu_start_wr_i          (s_start_write_axi  ),
        .cpu_data_i              (s_write_axi        ),
        .cpu_addr_i              (s_addr_axi         ),
        .mem_successful_access_i (s_successful_access),
        .mem_successful_rd_i     (s_successful_read  ),
        .mem_successful_wr_i     (s_successful_write ),
        .mem_data_i              (s_mem_data_out     ),
        .cpu_data_o              (s_read_axi         ),
        .cpu_done_o              (s_axi_done         ),
        .mem_rd_req_o            (),
        .mem_wr_en_o             (s_mem_we           ),
        .mem_addr_o              (s_mem_addr         ),
        .mem_data_o              (s_mem_data_in      )
    );

    //---------------------------
    // Memory Unit Instance.
    //---------------------------
    mem_sim MEM_M (
        .clk                 ( clock               ),
        .arst                ( arst                ),
        .write_en            ( s_mem_we            ),
        .i_data              ( s_mem_data_in       ),
        .i_addr              ( s_mem_addr          ),
        .o_data              ( s_mem_data_out      ),
        .o_successful_access ( s_successful_access ),
        .o_successful_read   ( s_successful_read   ),
        .o_successful_write  ( s_successful_write  )
    );


    //-------------------------------------------
    // Cache data transfer unit instance for APB.
    //-------------------------------------------
    cache_data_transfer # (
        .AXI_DATA_WIDTH ( 32      ),
        .AXI_ADDR_WIDTH ( 32      ),
        .BLOCK_WIDTH    ( 512     ),
        .COUNT_LIMIT    ( 4'b1111 ),
        .COUNT_TO       ( 16      ),
        .ADDR_INCR_VAL  ( 32'd4   ) 
    ) DATA_T_APB (
        .clk                ( clock                     ),
        .arst               ( arst                      ),
        .i_start_read       ( s_start_read_axi_cache    ),
        .i_start_write      ( s_start_write_axi_cache   ),
        .i_axi_done         ( s_axi_done                ),
        .i_data_block_cache ( s_data_block_write_top    ),
        .i_data_axi         ( s_read_axi                ),
        .i_addr_cache       ( s_addr                    ),
        .o_count_done       ( s_count_done_apb          ),
        .o_data_block_cache ( s_data_block_read_top_apb ),
        .o_data_axi         ( s_write_axi_fifo_apb      ),
        .o_addr_axi         ( s_addr_calc_apb           )
    );


    //-------------------------
    // Memory Data Register. 
    //-------------------------
    register_en #( .DATA_WIDTH(32) ) REG_AXI_DATA (
        .clk          ( clock           ),
        .arst         ( arst            ),
        .write_en     ( s_axi_done      ),
        .i_write_data ( s_read_axi      ),
        .o_read_data  ( s_reg_read_axi  )
    );
    
endmodule
