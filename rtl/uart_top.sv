

//-------------------------------------------
// This is a top UART WB module.
//-------------------------------------------

// synopsys translate_off
// `timescale 1ns/1ns
// synopsys translate_on

module uart_top
#(
    parameter WB_DATA_WIDTH   = 32,
    parameter WB_ADDR_WIDTH   = 32,
    parameter UART_DATA_WIDTH = 8,
    parameter UART_ADDR_WIDTH = 3
)
(
    input  logic clk,
    input  logic arst,

    // Wishbone interface.
    input  logic [WB_DATA_WIDTH   - 1:0] S_DAT_I,
    input  logic [WB_ADDR_WIDTH   - 1:0] S_ADR_I,
    output logic [WB_DATA_WIDTH   - 1:0] S_DAT_O,
    input  logic                         S_WE_I,
    input  logic [WB_DATA_WIDTH/8 - 1:0] S_SEL_I,
    input  logic                         S_STB_I,
    output logic                         S_ACK_O,
    input  logic                         S_CYC_I,

    // UART interface.
    input  logic uart_rx,
    output logic uart_tx
);

    //---------------------------
    // Internal nets.
    //---------------------------

    // Unused.
    logic rtsn;
    logic ctsn = 1'b0;
    logic dtr_pad_o;
    logic dsr_pad_i =1'b0;
    logic ri_pad_i  =1'b0;
    logic dcd_pad_i =1'b0;
    logic interrupt;
    logic rts_internal;
    assign rtsn = ~rts_internal;


    // Wishbone.
    logic [UART_DATA_WIDTH - 1:0] wb_dat_i;
    logic [UART_DATA_WIDTH - 1:0] wb_dat_o;
    logic [UART_DATA_WIDTH - 1:0] wb_dat8_i;
    logic [UART_DATA_WIDTH - 1:0] wb_dat8_o;
    logic [UART_ADDR_WIDTH - 1:0] wb_adr_i;
    logic [UART_ADDR_WIDTH - 1:0] wb_adr_int;
    logic                         we_o;
    logic                         re_o;



    //---------------------------
    // Convert data width.
    //---------------------------
    assign wb_adr_i = S_ADR_I[UART_ADDR_WIDTH - 1:0];
    assign S_DAT_O = {4{wb_dat_o}};

    always_comb begin
        case (wb_adr_i[1:0])
            2'b00: wb_dat_i = S_DAT_I[ 7:0];
            2'b01: wb_dat_i = S_DAT_I[15:8];
            2'b10: wb_dat_i = S_DAT_I[23:16];
            2'b11: wb_dat_i = S_DAT_I[31:24];
            default: wb_dat_i = S_DAT_I[7:0];
        endcase
    end


    //---------------------------
    // Lower-level modules.
    //---------------------------
    uart_wb wb_interface (
        .clk        (clk       ),
        .wb_rst_i   (arst      ),
        .wb_dat_i   (wb_dat_i  ),
        .wb_dat_o   (wb_dat_o  ),
        .wb_dat8_i  (wb_dat8_i ),
        .wb_dat8_o  (wb_dat8_o ),
        .wb_dat32_o (32'b0     ),
        .wb_sel_i   (4'b0      ),
        .wb_we_i    (S_WE_I    ),
        .wb_stb_i   (S_STB_I   ),
        .wb_cyc_i   (S_CYC_I   ),
        .wb_ack_o   (S_ACK_O   ),
        .wb_adr_i   (wb_adr_i  ),
        .wb_adr_int (wb_adr_int),
        .we_o       (we_o      ),
        .re_o       (re_o      )
    );


    uart_regs regs(
        .clk          (clk                                    ),
        .wb_rst_i     (arst                                   ),
        .wb_addr_i    (wb_adr_int                             ),
        .wb_dat_i     (wb_dat8_i                              ),
        .wb_dat_o     (wb_dat8_o                              ),
        .wb_we_i      (we_o                                   ),
        .wb_re_i      (re_o                                   ),
        .modem_inputs ({~ctsn, dsr_pad_i, ri_pad_i, dcd_pad_i}),
        .stx_pad_o    (uart_tx                                ),
        .srx_pad_i    (uart_rx                                ),
        .rts_pad_o    (rts_internal                           ),
        .dtr_pad_o    (dtr_pad_o                              ),
        .int_o        (interrupt                              )
    );

endmodule