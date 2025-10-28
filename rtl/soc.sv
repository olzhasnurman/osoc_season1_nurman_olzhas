/* Copyright (c) 2025 Maveric NU. All rights reserved. */

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
    input  logic        uart_rx,

    output logic        uart_tx,
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


    // WB Master interface: CPU.
    logic [DATA_WIDTH   - 1:0] M_DAT_I;
    logic [ADDR_WIDTH   - 1:0] M_ADR_O;
    logic [DATA_WIDTH   - 1:0] M_DAT_O;
    logic                      M_WE_O;
    logic [DATA_WIDTH/8 - 1:0] M_SEL_O;
    logic                      M_STB_O;
    logic                      M_ACK_I;
    logic                      M_CYC_O;

    // WB Slave 0 interface: Memory.
    logic [DATA_WIDTH   - 1:0] S0_DAT_I;
    logic [ADDR_WIDTH   - 1:0] S0_ADR_I;
    logic [DATA_WIDTH   - 1:0] S0_DAT_O;
    logic                      S0_WE_I;
    logic [DATA_WIDTH/8 - 1:0] S0_SEL_I;
    logic                      S0_STB_I;
    logic                      S0_ACK_O;
    logic                      S0_CYC_I;

    // WB Slave 1 interface: UART.
    logic [DATA_WIDTH   - 1:0] S1_DAT_I;
    logic [ADDR_WIDTH   - 1:0] S1_ADR_I;
    logic [DATA_WIDTH   - 1:0] S1_DAT_O;
    logic                      S1_WE_I;
    logic [DATA_WIDTH/8 - 1:0] S1_SEL_I;
    logic                      S1_STB_I;
    logic                      S1_ACK_O;
    logic                      S1_CYC_I;


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
    wb_master #(
        .ADDR_WIDTH  (ADDR_WIDTH ),
        .DATA_WIDTH  (DATA_WIDTH )
    ) WB_MASTER0 (
        .clk_i      (clock           ),
        .rst_i      (arst            ),
        .start_rd_i (s_start_read_wb ),
        .start_wr_i (s_start_write_wb),
        .sel_i      (s_write_sel_wb  ),
        .data_i     (s_write_data_wb ),
        .addr_i     (s_addr_wb       ),
        .done_o     (s_wb_done       ),
        .data_o     (s_read_data_wb  ),
        .DAT_I      (M_DAT_I         ),
        .ADR_O      (M_ADR_O         ),
        .DAT_O      (M_DAT_O         ),
        .WE_O       (M_WE_O          ),
        .SEL_O      (M_SEL_O         ),
        .STB_O      (M_STB_O         ),
        .ACK_I      (M_ACK_I         ),
        .CYC_O      (M_CYC_O         )
    );


    //-----------------------------
    // WB Interconnect.
    //-----------------------------
    wb_interconnect #(
        .ADDR_WIDTH  (ADDR_WIDTH ),
        .DATA_WIDTH  (DATA_WIDTH )
    ) WB_INT0 (
        .clk_i     (clock    ),
        .rst_i     (arst     ),
        .wb_done_i (s_wb_done),
        .M_DAT_I   (M_DAT_I  ),
        .M_ADR_O   (M_ADR_O  ),
        .M_DAT_O   (M_DAT_O  ),
        .M_WE_O    (M_WE_O   ),
        .M_SEL_O   (M_SEL_O  ),
        .M_STB_O   (M_STB_O  ),
        .M_ACK_I   (M_ACK_I  ),
        .M_CYC_O   (M_CYC_O  ),
        .S0_DAT_I  (S0_DAT_I ),
        .S0_ADR_I  (S0_ADR_I ),
        .S0_DAT_O  (S0_DAT_O ),
        .S0_WE_I   (S0_WE_I  ),
        .S0_SEL_I  (S0_SEL_I ),
        .S0_STB_I  (S0_STB_I ),
        .S0_ACK_O  (S0_ACK_O ),
        .S0_CYC_I  (S0_CYC_I ),
        .S1_DAT_I  (S1_DAT_I ),
        .S1_ADR_I  (S1_ADR_I ),
        .S1_DAT_O  (S1_DAT_O ),
        .S1_WE_I   (S1_WE_I  ),
        .S1_SEL_I  (S1_SEL_I ),
        .S1_STB_I  (S1_STB_I ),
        .S1_ACK_O  (S1_ACK_O ),
        .S1_CYC_I  (S1_CYC_I )
    );


    //-----------------------------
    // WB Memory Slave Module.
    //-----------------------------
    wb_slave #(
        .ADDR_WIDTH  (ADDR_WIDTH ),
        .DATA_WIDTH  (DATA_WIDTH )
    ) WB_SLAVE0 (
        .clk_i               (clock              ),
        .rst_i               (arst               ),
        .successful_access_i (s_successful_access),
        .successful_rd_i     (s_successful_read  ),
        .successful_wr_i     (s_successful_write ),
        .data_i              (s_mem_data_out     ),
        .rd_req_o            (s_mem_read_request ),
        .wr_en_o             (s_mem_we           ),
        .addr_o              (s_mem_addr         ),
        .data_o              (s_mem_data_in      ),
        .DAT_I               (S0_DAT_I           ),
        .ADR_I               (S0_ADR_I           ),
        .DAT_O               (S0_DAT_O           ),
        .WE_I                (S0_WE_I            ),
        .SEL_I               (S0_SEL_I           ),
        .STB_I               (S0_STB_I           ),
        .ACK_O               (S0_ACK_O           ),
        .CYC_I               (S0_CYC_I           )
    );


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


    //---------------------------
    // UART Instance.
    //---------------------------
    uart_top #(
        .WB_ADDR_WIDTH (ADDR_WIDTH),
        .WB_DATA_WIDTH (DATA_WIDTH)
    ) UART_TOP0 (
        .clk     (clock   ),
        .arst    (arst    ),
        .S_DAT_I (S1_DAT_I),
        .S_ADR_I (S1_ADR_I),
        .S_DAT_O (S1_DAT_O),
        .S_WE_I  (S1_WE_I ),
        .S_SEL_I (S1_SEL_I),
        .S_STB_I (S1_STB_I),
        .S_ACK_O (S1_ACK_O),
        .S_CYC_I (S1_CYC_I),
        .uart_rx (uart_rx ),
        .uart_tx (uart_tx )
    );

endmodule
