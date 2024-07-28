/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------------------------------
// This is a top CPU module.
// ---------------------------------------------------------------------------------------

module ysyx_201979054 (
    input clock,
    input reset,
    input io_interrupt,
    input io_master_awready,
    output io_master_awvalid,
    output [3:0] io_master_awid,
    output [31:0] io_master_awaddr,
    output [7:0] io_master_awlen,
    output [2:0] io_master_awsize,
    output [1:0] io_master_awburst,
    input io_master_wready,
    output io_master_wvalid,
    output [63:0] io_master_wdata,
    output [7:0] io_master_wstrb,
    output io_master_wlast,
    output io_master_bready,
    input io_master_bvalid,
    input [3:0] io_master_bid,
    input [1:0] io_master_bresp,
    input io_master_arready,
    output io_master_arvalid,
    output [3:0] io_master_arid,
    output [31:0] io_master_araddr,
    output [7:0] io_master_arlen,
    output [2:0] io_master_arsize,
    output [1:0] io_master_arburst,
    output io_master_rready,
    input io_master_rvalid,
    input [3:0] io_master_rid,
    input [1:0] io_master_rresp,
    input [63:0] io_master_rdata,
    input io_master_rlast,
    output io_slave_awready,
    input io_slave_awvalid,
    input [3:0] io_slave_awid,
    input [31:0] io_slave_awaddr,
    input [7:0] io_slave_awlen,
    input [2:0] io_slave_awsize,
    input [1:0] io_slave_awburst,
    output io_slave_wready,
    input io_slave_wvalid,
    input [63:0] io_slave_wdata,
    input [7:0] io_slave_wstrb,
    input io_slave_wlast,
    input io_slave_bready,
    output io_slave_bvalid,
    output [3:0] io_slave_bid,
    output [1:0] io_slave_bresp,
    output io_slave_arready,
    input io_slave_arvalid,
    input [3:0] io_slave_arid,
    input [31:0] io_slave_araddr,
    input [7:0] io_slave_arlen,
    input [2:0] io_slave_arsize,
    input [1:0] io_slave_arburst,
    input io_slave_rready,
    output io_slave_rvalid,
    output [3:0] io_slave_rid,
    output [1:0] io_slave_rresp,
    output [63:0] io_slave_rdata,
    output io_slave_rlast,
    output [5:0] io_sram0_addr,
    output io_sram0_cen,
    output io_sram0_wen,
    output [127:0] io_sram0_wmask,
    output [127:0] io_sram0_wdata,
    input [127:0] io_sram0_rdata,
    output [5:0] io_sram1_addr,
    output io_sram1_cen,
    output io_sram1_wen,
    output [127:0] io_sram1_wmask,
    output [127:0] io_sram1_wdata,
    input [127:0] io_sram1_rdata,
    output [5:0] io_sram2_addr,
    output io_sram2_cen,
    output io_sram2_wen,
    output [127:0] io_sram2_wmask,
    output [127:0] io_sram2_wdata,
    input [127:0] io_sram2_rdata,
    output [5:0] io_sram3_addr,
    output io_sram3_cen,
    output io_sram3_wen,
    output [127:0] io_sram3_wmask,
    output [127:0] io_sram3_wdata,
    input [127:0] io_sram3_rdata,
    output [5:0] io_sram4_addr,
    output io_sram4_cen,
    output io_sram4_wen,
    output [127:0] io_sram4_wmask,
    output [127:0] io_sram4_wdata,
    input [127:0] io_sram4_rdata,
    output [5:0] io_sram5_addr,
    output io_sram5_cen,
    output io_sram5_wen,
    output [127:0] io_sram5_wmask,
    output [127:0] io_sram5_wdata,
    input [127:0] io_sram5_rdata,
    output [5:0] io_sram6_addr,
    output io_sram6_cen,
    output io_sram6_wen,
    output [127:0] io_sram6_wmask,
    output [127:0] io_sram6_wdata,
    input [127:0] io_sram6_rdata,
    output [5:0] io_sram7_addr,
    output io_sram7_cen,
    output io_sram7_wen,
    output [127:0] io_sram7_wmask,
    output [127:0] io_sram7_wdata,
    input [127:0] io_sram7_rdata
);

    //--------------------------------
    // Internal nets.
    //--------------------------------
    logic arst;

    logic s_write_req;
    logic s_read_req;
    logic s_read_req_non_cacheable;
    logic s_write_req_non_cacheable;

    logic [ 511:0 ] s_data_block_write_top;
    logic [ 511:0 ] s_data_block_read_top;
    logic [ 511:0 ] s_data_block_read_top_axi4;
    logic [ 511:0 ] s_data_block_read_top_apb;
    logic [  63:0 ] s_data_non_cacheable_r;
    logic [   7:0 ] s_data_non_cacheable_w;
    logic [  31:0 ] s_addr;
    logic [  31:0 ] s_addr_non_cacheable;
    logic [  31:0 ] s_addr_calc;
    logic [  31:0 ] s_addr_calc_apb;

    logic [ 31:0 ] s_read_axi_fifo;
    logic [ 63:0 ] s_write_axi_fifo;
    logic [ 63:0 ] s_write_axi_fifo_axi4;
    logic [ 31:0 ] s_write_axi_fifo_apb;

    logic [ 31:0 ] s_addr_axi;
    logic [ 63:0 ] s_write_axi;
    logic [ 63:0 ] s_read_axi;
    logic [  7:0 ] s_reg_read_axi;

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
    logic [ 7:0 ] s_axi_strb;
    logic [ 7:0 ] s_axi_strb_cache;
    logic [ 7:0 ] s_axi_len;

    logic s_axi4_access;

    assign s_axi4_access = ( s_addr >= 32'h4000_0000 );

    assign s_axi_strb_cache      = s_axi4_access ? 8'hFF : 8'h0F;
    assign s_axi_size_cache      = s_axi4_access ? 3'b11 : 3'b10;
    assign s_write_axi_fifo      = s_axi4_access ? s_write_axi_fifo_axi4 : { s_write_axi_fifo_apb, s_write_axi_fifo_apb };
    assign s_addr_calc           = s_axi4_access ? s_addr : s_addr_calc_apb;
    assign s_data_block_read_top = s_axi4_access ? s_data_block_read_top_axi4 : s_data_block_read_top_apb;


    assign s_count_done = s_count_done_apb;

    assign s_start_read_axi_cache  = s_read_req  & ( ~ s_count_done );
    assign s_start_read_axi        = s_read_req_non_cacheable | s_start_read_axi_cache;
    assign s_start_write_axi_cache = s_write_req & ( ~ s_count_done );
    assign s_start_write_axi       = s_write_req_non_cacheable | s_start_write_axi_cache;
    
    assign s_addr_axi      = ( s_read_req_non_cacheable | s_write_req_non_cacheable ) ? s_addr_non_cacheable : s_addr_calc;
    assign s_axi_size      = ( s_read_req_non_cacheable | s_write_req_non_cacheable ) ? 3'b00 : s_axi_size_cache;
    assign s_axi_strb      = s_write_req_non_cacheable  ? 8'h01 : s_axi_strb_cache;
    assign s_axi_len       = s_axi4_access ? 8'b111 : 8'b000;

    assign s_read_axi_fifo        = s_read_axi [ 31:0 ];
    assign s_data_non_cacheable_r = { 56'b0 , s_reg_read_axi };
    assign s_write_axi            = s_write_req_non_cacheable ? { 8 { s_data_non_cacheable_w } } : s_write_axi_fifo;

    assign s_done = ( s_count_done ) | ( s_axi_done & ( s_read_req_non_cacheable | s_write_req_non_cacheable ) ) | ( s_axi4_access & s_axi_done ); 



    //-----------------------------------
    // LOWER LEVEL MODULE INSTANTIATIONS.
    //-----------------------------------

    //------------------------------
    // Reset Synchronizer Instance.
    //------------------------------
    ysyx_201979054_reset_sync RST_SYNC (
        .clk       ( clock ),
        .arst      ( reset ),
        .arst_sync ( arst  )
    );



    //-----------------------------
    // Top datapath unit instance.
    //-----------------------------
    ysyx_201979054_datapath TOP0 (
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
        .o_data_write_axi     ( s_data_block_write_top    )
    );



    //-----------------------
    // AXI4 Master Instance.
    //-----------------------
    ysyx_201979054_axi4_master AXI4_M0 (
        .clk          ( clock             ),
        .arst         ( arst              ),
        .io_interrupt ( io_interrupt      ),
        .i_write_req  ( s_start_write_axi ),
        .i_read_req   ( s_start_read_axi  ),
        .i_addr       ( s_addr_axi        ),
        .i_write_data ( s_write_axi       ),
        .i_axi_len    ( s_axi_len         ),
        .i_axi_size   ( s_axi_size        ), 
        .i_axi_burst  ( 2'b01             ), 
        .i_axi_strb   ( s_axi_strb        ), 
        .o_read_data  ( s_read_axi        ),
        .o_axi_done   ( s_axi_done        ),
        .o_axi_handshake ( s_axi_handshake ),
        .i_awready    ( io_master_awready ),
        .o_awvalid    ( io_master_awvalid ),
        .o_awid       ( io_master_awid    ),
        .o_awaddr     ( io_master_awaddr  ),
        .o_awlen      ( io_master_awlen   ),
        .o_awsize     ( io_master_awsize  ),
        .o_awburst    ( io_master_awburst ),
        .i_wready     ( io_master_wready  ),
        .o_wvalid     ( io_master_wvalid  ),
        .o_wdata      ( io_master_wdata   ),
        .o_wstrb      ( io_master_wstrb   ), 
        .o_wlast      ( io_master_wlast   ),
        .o_bready     ( io_master_bready  ),
        .i_bvalid     ( io_master_bvalid  ),
        .i_bid        ( io_master_bid     ),
        .i_bresp      ( io_master_bresp   ),
        .i_arready    ( io_master_arready ),
        .o_arvalid    ( io_master_arvalid ),
        .o_arid       ( io_master_arid    ),
        .o_araddr     ( io_master_araddr  ),
        .o_arlen      ( io_master_arlen   ),
        .o_arsize     ( io_master_arsize  ),
        .o_arburst    ( io_master_arburst ),
        .o_rready     ( io_master_rready  ),
        .i_rvalid     ( io_master_rvalid  ),
        .i_rid        ( io_master_rid     ),
        .i_rresp      ( io_master_rresp   ),
        .i_rdata      ( io_master_rdata   ),
        .i_rlast      ( io_master_rlast   )
    );


    //-------------------------------------------
    // Cache data transfer unit instance for APB.
    //-------------------------------------------
    ysyx_201979054_cache_data_transfer # (
        .AXI_DATA_WIDTH ( 32      ),
        .AXI_ADDR_WIDTH ( 32      ),
        .BLOCK_WIDTH    ( 512     ),
        .COUNT_LIMIT    ( 4'b1111 ),
        .COUNT_TO       ( 16      ),
        .ADDR_INCR_VAL  ( 32'd4   ) 
    ) DATA_T_APB (
        .clk                ( clock                     ),
        .arst               ( arst                      ),
        .i_start_read       ( s_start_read_axi_cache & ( ~s_axi4_access )    ),
        .i_start_write      ( s_start_write_axi_cache & ( ~s_axi4_access )   ),
        .i_axi_done         ( s_axi_handshake                ),
        .i_data_block_cache ( s_data_block_write_top    ),
        .i_data_axi         ( s_read_axi_fifo           ),
        .i_addr_cache       ( s_addr [ 31:0 ]           ),
        .o_count_done       ( s_count_done_apb          ),
        .o_data_block_cache ( s_data_block_read_top_apb ),
        .o_data_axi         ( s_write_axi_fifo_apb      ),
        .o_addr_axi         ( s_addr_calc_apb           )
    );


    //--------------------------------------------------------
    // FIFO for accumilating the data coming from AXI4 burst.
    //--------------------------------------------------------
    ysyx_201979054_fifo # (
        .AXI_DATA_WIDTH ( 64  ),
        .FIFO_WIDTH     ( 512 )
    ) FIFO_0 (
        .clk          ( clock                                       ),
        .arst         ( arst                                        ),
        .write_en     ( s_axi_handshake                             ),
        .start_read   ( s_start_read_axi_cache  & ( s_axi4_access ) ),
        .start_write  ( s_start_write_axi_cache & ( s_axi4_access ) ),
        .i_data       ( s_read_axi                                  ),
        .i_data_block ( s_data_block_write_top                      ),
        .o_data       ( s_write_axi_fifo_axi4                       ),
        .o_data_block ( s_data_block_read_top_axi4                  )
    );


    //-------------------------
    // Memory Data Register. 
    //-------------------------
    ysyx_201979054_register_en #( .DATA_WIDTH(8) ) REG_AXI_DATA (
        .clk          ( clock           ),
        .arst         ( arst            ),
        .write_en     ( s_axi_handshake ),
        .i_write_data ( s_read_axi[7:0] ),
        .o_read_data  ( s_reg_read_axi  )
    );


    //---------------------------------------------
    // Redundant outputs.
    //---------------------------------------------
    assign io_slave_awready = '0;
    assign io_slave_wready = '0;
    assign io_slave_bvalid = '0;
    assign io_slave_bid = '0;
    assign io_slave_bresp = '0;
    assign io_slave_arready = '0;
    assign io_slave_rvalid = '0;
    assign io_slave_rid = '0;
    assign io_slave_rresp = '0;
    assign io_slave_rdata = '0;
    assign io_slave_rlast = '0;
    assign io_sram0_addr = '0;
    assign io_sram0_cen = '0;
    assign io_sram0_wen = '0;
    assign io_sram0_wmask = '0;
    assign io_sram0_wdata = '0;
    assign io_sram1_addr = '0;
    assign io_sram1_cen = '0;
    assign io_sram1_wen = '0;
    assign io_sram1_wmask = '0;
    assign io_sram1_wdata = '0;
    assign io_sram2_addr = '0;
    assign io_sram2_cen = '0;
    assign io_sram2_wen = '0;
    assign io_sram2_wmask = '0;
    assign io_sram2_wdata = '0;
    assign io_sram3_addr = '0;
    assign io_sram3_cen = '0;
    assign io_sram3_wen = '0;
    assign io_sram3_wmask = '0;
    assign io_sram3_wdata = '0;
    assign io_sram4_addr = '0;
    assign io_sram4_cen = '0;
    assign io_sram4_wen = '0;
    assign io_sram4_wmask = '0;
    assign io_sram4_wdata = '0;
    assign io_sram5_addr = '0;
    assign io_sram5_cen = '0;
    assign io_sram5_wen = '0;
    assign io_sram5_wmask = '0;
    assign io_sram5_wdata = '0;
    assign io_sram6_addr = '0;
    assign io_sram6_cen = '0;
    assign io_sram6_wen = '0;
    assign io_sram6_wmask = '0;
    assign io_sram6_wdata = '0;
    assign io_sram7_addr = '0;
    assign io_sram7_cen = '0;
    assign io_sram7_wen = '0;
    assign io_sram7_wmask = '0;
    assign io_sram7_wdata = '0;
    
endmodule