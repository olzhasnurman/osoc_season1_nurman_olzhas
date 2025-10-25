/* Copyright (c) 2025 Maveric NU. All rights reserved. */


// ---------------------------------------------------------------------------------------
// This is a top WB module for establishing connection between CPU and its peripherals.
// ---------------------------------------------------------------------------------------

module wb_top
// Parameters.
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
// Port declerations.
(
    // Common clock & reset.
    input  logic                    clk_i,
    input  logic                    rst_i,

    // Input interface.
    input  logic                    cpu_start_rd_i,
    input  logic                    cpu_start_wr_i,
    input  logic [DATA_WIDTH - 1:0] cpu_data_i,
    input  logic [ADDR_WIDTH - 1:0] cpu_addr_i,
    input  logic                    mem_successful_access_i,
    input  logic                    mem_successful_rd_i,
    input  logic                    mem_successful_wr_i,
    input  logic [DATA_WIDTH - 1:0] mem_data_i,


    // Output interface.
    output logic [DATA_WIDTH - 1:0] cpu_data_o,
    output logic                    cpu_done_o,
    output logic                    mem_rd_req_o,
    output logic                    mem_wr_en_o,
    output logic [ADDR_WIDTH - 1:0] mem_addr_o,
    output logic [DATA_WIDTH - 1:0] mem_data_o
);

    //------------------------
    // Internal nets.
    //------------------------

    // Master interface.
    logic [DATA_WIDTH   - 1:0] M_DAT_I;
    logic [ADDR_WIDTH   - 1:0] M_ADR_O;
    logic [DATA_WIDTH   - 1:0] M_DAT_O;
    logic                      M_WE_O;
    logic [DATA_WIDTH/8 - 1:0] M_SEL_O;
    logic                      M_STB_O;
    logic                      M_ACK_I;
    logic                      M_CYC_O;

    // Slave interface.
    logic [DATA_WIDTH   - 1:0] S_DAT_I;
    logic [ADDR_WIDTH   - 1:0] S_ADR_I;
    logic [DATA_WIDTH   - 1:0] S_DAT_O;
    logic                      S_WE_I;
    logic [DATA_WIDTH/8 - 1:0] S_SEL_I;
    logic                      S_STB_I;
    logic                      S_ACK_O;
    logic                      S_CYC_I;


    //-----------------------------------
    // Lower-level module instantiations.
    //-----------------------------------

    // WB Master.
    wb_master #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) WB_MASTER0 (
        .clk_i      (clk_i         ),
        .rst_i      (rst_i         ),
        .start_rd_i (cpu_start_rd_i),
        .start_wr_i (cpu_start_wr_i),
        .data_i     (cpu_data_i    ),
        .addr_i     (cpu_addr_i    ),
        .done_o     (cpu_done_o    ),
        .data_o     (cpu_data_o    ),
        .DAT_I      (M_DAT_I       ),
        .ADR_O      (M_ADR_O       ),
        .DAT_O      (M_DAT_O       ),
        .WE_O       (M_WE_O        ),
        .SEL_O      (M_SEL_O       ),
        .STB_O      (M_STB_O       ),
        .ACK_I      (M_ACK_I       ),
        .CYC_O      (M_CYC_O       )
    );

    // WB Slave.
    wb_slave #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) WB_SLAVE0 (
        .clk_i               (clk_i                  ),
        .rst_i               (rst_i                  ),
        .successful_access_i (mem_successful_access_i),
        .successful_rd_i     (mem_successful_rd_i    ),
        .successful_wr_i     (mem_successful_wr_i    ),
        .data_i              (mem_data_i             ),
        .rd_req_o            (mem_rd_req_o           ),
        .wr_en_o             (mem_wr_en_o            ),
        .addr_o              (mem_addr_o             ),
        .data_o              (mem_data_o             ),
        .DAT_I               (S_DAT_I                ),
        .ADR_I               (S_ADR_I                ),
        .DAT_O               (S_DAT_O                ),
        .WE_I                (S_WE_I                 ),
        .SEL_I               (S_SEL_I                ),
        .STB_I               (S_STB_I                ),
        .ACK_O               (S_ACK_O                ),
        .CYC_I               (S_CYC_I                )
    );

    assign M_DAT_I = S_DAT_O;
    assign M_ACK_I = S_ACK_O;

    assign S_DAT_I = M_DAT_O;
    assign S_ADR_I = M_ADR_O;
    assign S_WE_I  = M_WE_O;
    assign S_SEL_I = M_SEL_O;
    assign S_STB_I = M_STB_O;
    assign S_CYC_I = M_CYC_O;


endmodule