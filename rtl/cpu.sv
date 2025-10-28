/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------------------------------
// This is a top CPU module.
// ---------------------------------------------------------------------------------------

module cpu
// Parameters.
#(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 32,
    parameter BLOCK_WIDTH = 512
)
// Port declerations.
(
    input  logic                      clk,
    input  logic                      arst,

    input  logic [DATA_WIDTH   - 1:0] i_read_data_wb,
    input  logic                      i_wb_done,

    output logic                      o_start_read_wb,
    output logic                      o_start_write_wb,
    output logic [DATA_WIDTH/8 - 1:0] o_write_sel_wb,
    output logic [DATA_WIDTH   - 1:0] o_write_data_wb,
    output logic [ADDR_WIDTH   - 1:0] o_addr_wb,
    output logic [               3:0] led
);

    //--------------------------------
    // Internal nets.
    //--------------------------------

    logic s_write_req;
    logic s_read_req;
    logic s_read_req_non_cacheable;
    logic s_write_req_non_cacheable;

    logic [BLOCK_WIDTH - 1:0] s_data_block_write_top;
    logic [BLOCK_WIDTH - 1:0] s_data_block_read_top;
    logic [BLOCK_WIDTH - 1:0] s_data_block_read_top_apb;
    logic [             63:0] s_data_non_cacheable_r;
    logic [DATA_WIDTH  - 1:0] s_data_non_cacheable_w;
    logic [ADDR_WIDTH  - 1:0] s_addr;
    logic [ADDR_WIDTH  - 1:0] s_addr_non_cacheable;
    logic [ADDR_WIDTH  - 1:0] s_addr_calc_apb;

    logic [DATA_WIDTH - 1:0] s_write_wb_fifo_apb;

    logic [DATA_WIDTH - 1:0] s_reg_read_wb;



    logic s_start_read_wb_cache;
    logic s_start_write_wb_cache;

    logic s_count_done_apb;
    logic s_done;

    logic [DATA_WIDTH/8 - 1:0] s_wb_sel;
    logic [DATA_WIDTH/8 - 1:0] s_wb_sel_cache;


    assign s_wb_sel_cache      = 4'hF;
    assign s_data_block_read_top = s_data_block_read_top_apb;



    assign s_start_read_wb_cache  = s_read_req  & ( ~ s_count_done_apb );
    assign o_start_read_wb        = (s_read_req_non_cacheable & (~ i_wb_done)) | s_start_read_wb_cache;
    assign s_start_write_wb_cache = s_write_req & ( ~ s_count_done_apb );
    assign o_start_write_wb       = (s_write_req_non_cacheable & (~ i_wb_done)) | s_start_write_wb_cache;

    assign o_addr_wb      = ( s_read_req_non_cacheable | s_write_req_non_cacheable ) ? s_addr_non_cacheable : s_addr_calc_apb;
    assign s_wb_sel       = s_write_req_non_cacheable  ? (4'h1 << s_addr_non_cacheable[2:0]) : s_wb_sel_cache;
    assign o_write_sel_wb = s_wb_sel;

    assign s_data_non_cacheable_r = { 32'b0 , s_reg_read_wb };
    assign o_write_data_wb       = s_write_req_non_cacheable ? (s_data_non_cacheable_w << 8*s_addr_non_cacheable[2:0]) : s_write_wb_fifo_apb;

    assign s_done = ( s_count_done_apb ) | ( i_wb_done & ( s_read_req_non_cacheable | s_write_req_non_cacheable ) );



    //-----------------------------------
    // LOWER LEVEL MODULE INSTANTIATIONS.
    //-----------------------------------

    //------------------------------
    // Reset Synchronizer Instance.
    //------------------------------

    //-----------------------------
    // Top datapath unit instance.
    //-----------------------------
    datapath TOP0 (
        .clk                  (clk                      ),
        .arst                 (arst                     ),
        .i_done_axi           (s_done                   ),
        .i_data_read_axi      (s_data_block_read_top    ),
        .i_data_non_cacheable (s_data_non_cacheable_r   ),
        .o_data_non_cacheable (s_data_non_cacheable_w   ),
        .o_start_read_axi     (s_read_req               ),
        .o_start_read_axi_nc  (s_read_req_non_cacheable ),
        .o_start_write_axi_nc (s_write_req_non_cacheable),
        .o_start_write_axi    (s_write_req              ),
        .o_addr               (s_addr                   ),
        .led (led),
        .o_addr_non_cacheable (s_addr_non_cacheable     ),
        .o_size_non_cacheable (),
        .o_data_write_axi     (s_data_block_write_top   )
    );


    //-------------------------------------------
    // Cache data transfer unit instance for APB.
    //-------------------------------------------
    cache_data_transfer # (
        .AXI_DATA_WIDTH (DATA_WIDTH ),
        .AXI_ADDR_WIDTH (ADDR_WIDTH ),
        .BLOCK_WIDTH    (BLOCK_WIDTH),
        .COUNT_LIMIT    ( 4'b1111   ),
        .COUNT_TO       ( 16        ),
        .ADDR_INCR_VAL  ( 32'd4     )
    ) DATA_T_APB (
        .clk                (clk                      ),
        .arst               (arst                     ),
        .i_start_read       (s_start_read_wb_cache    ),
        .i_start_write      (s_start_write_wb_cache   ),
        .i_axi_done         (i_wb_done                ),
        .i_data_block_cache (s_data_block_write_top   ),
        .i_data_axi         (i_read_data_wb           ),
        .i_addr_cache       (s_addr                   ),
        .o_count_done       (s_count_done_apb         ),
        .o_data_block_cache (s_data_block_read_top_apb),
        .o_data_axi         (s_write_wb_fifo_apb      ),
        .o_addr_axi         (s_addr_calc_apb          )
    );


    //-------------------------
    // Memory Data Register.
    //-------------------------
    register_en #(
        .DATA_WIDTH(DATA_WIDTH)
    ) REG_AXI_DATA (
        .clk          (clk           ),
        .arst         (arst          ),
        .write_en     (i_wb_done     ),
        .i_write_data (i_read_data_wb),
        .o_read_data  (s_reg_read_wb )
    );

endmodule
