/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------------------------------
// This is a top SoC module that connects all lower level modules.
// ---------------------------------------------------------------------------------------

module soc
// Parameters.
#(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 32,
    parameter BLOCK_WIDTH = 512
)
// Port declerations.
(
    input  logic        clock,
    input  logic        reset,

    output logic [ 3:0] led
);

    //--------------------------------
    // Internal nets.
    //--------------------------------
    logic arst;

    logic                      s_start_read_wb;
    logic                      s_start_write_wb;
    logic [DATA_WIDTH/8 - 1:0] s_write_sel_wb;
    logic [DATA_WIDTH   - 1:0] s_write_data_wb;
    logic [ADDR_WIDTH   - 1:0] s_addr_wb;

    logic [DATA_WIDTH - 1:0] s_read_data_wb;
    logic                    s_wb_done;

    // Memory module signals.
    logic [ADDR_WIDTH - 1:0] s_mem_addr;
    logic [DATA_WIDTH - 1:0] s_mem_data_in;
    logic [DATA_WIDTH - 1:0] s_mem_data_out;
    logic                    s_mem_we;
    logic                    s_mem_read_request;
    logic                    s_successful_access;
    logic                    s_successful_read;
    logic                    s_successful_write;


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
    // CPU module.
    //-----------------------------
    cpu #(
        .ADDR_WIDTH  (ADDR_WIDTH ),
        .DATA_WIDTH  (DATA_WIDTH ),
        .BLOCK_WIDTH (BLOCK_WIDTH)
    ) CPU_TOP (
        .clk              (clock           ),
        .arst             (arst            ),
        .i_read_data_wb   (s_read_data_wb  ),
        .i_wb_done        (s_wb_done       ),
        .o_start_read_wb  (s_start_read_wb ),
        .o_start_write_wb (s_start_write_wb),
        .o_write_sel_wb   (s_write_sel_wb  ),
        .o_write_data_wb  (s_write_data_wb ),
        .o_addr_wb        (s_addr_wb       ),
        .led              (led             )
    );


    //-----------------------------
    // WB Master Module.
    //-----------------------------
    wb_top #(
        .ADDR_WIDTH  (ADDR_WIDTH ),
        .DATA_WIDTH  (DATA_WIDTH )
    ) WB_TOP0 (
        .clk_i                   (clock              ),
        .rst_i                   (arst               ),
        .cpu_start_rd_i          (s_start_read_wb    ),
        .cpu_start_wr_i          (s_start_write_wb   ),
        .cpu_write_sel_i         (s_write_sel_wb     ),
        .cpu_data_i              (s_write_data_wb    ),
        .cpu_addr_i              (s_addr_wb          ),
        .mem_successful_access_i (s_successful_access),
        .mem_successful_rd_i     (s_successful_read  ),
        .mem_successful_wr_i     (s_successful_write ),
        .mem_data_i              (s_mem_data_out     ),
        .cpu_data_o              (s_read_data_wb     ),
        .cpu_done_o              (s_wb_done          ),
        .mem_rd_req_o            (s_mem_read_request ),
        .mem_wr_en_o             (s_mem_we           ),
        .mem_addr_o              (s_mem_addr         ),
        .mem_data_o              (s_mem_data_in      )
    );

    //-----------------------------
    // WB Slave Module.
    //-----------------------------


    //---------------------------
    // Memory Unit Instance.
    //---------------------------
    mem_sim #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_W     (14        )
    ) MEM_M (
        .clk                 ( clock               ),
        .arst                ( arst                ),
        .write_en            ( s_mem_we            ),
        .i_read_request      ( s_mem_read_request  ),
        .i_data              ( s_mem_data_in       ),
        .i_addr              ( s_mem_addr          ),
        .o_data              ( s_mem_data_out      ),
        .o_successful_access ( s_successful_access ),
        .o_successful_read   ( s_successful_read   ),
        .o_successful_write  ( s_successful_write  )
    );

endmodule
