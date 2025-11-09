/* Copyright (c) 2025 Maveric NU. All rights reserved. */


// ---------------------------------------------------------------------------------------
// This is a top WB module for establishing connection between CPU and its peripherals.
// ---------------------------------------------------------------------------------------

module wb_interconnect
// Parameters.
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
// Port declerations.
(
    // Common clock & reset.
    input  logic               clk_i,
    input  logic               rst_i,

    // Master interface: CPU.
    input  logic                      wb_done_i,
    output logic [DATA_WIDTH   - 1:0] M_DAT_I,
    input  logic [ADDR_WIDTH   - 1:0] M_ADR_O,
    input  logic [DATA_WIDTH   - 1:0] M_DAT_O,
    input  logic                      M_WE_O,
    input  logic [DATA_WIDTH/8 - 1:0] M_SEL_O,
    input  logic                      M_STB_O,
    output logic                      M_ACK_I,
    input  logic                      M_CYC_O,

    // Slave 0 interface: Memory.
    output logic [DATA_WIDTH   - 1:0] S0_DAT_I,
    output logic [ADDR_WIDTH   - 1:0] S0_ADR_I,
    input  logic [DATA_WIDTH   - 1:0] S0_DAT_O,
    output logic                      S0_WE_I,
    output logic [DATA_WIDTH/8 - 1:0] S0_SEL_I,
    output logic                      S0_STB_I,
    input  logic                      S0_ACK_O,
    output logic                      S0_CYC_I,

    // Slave 1 interface: UART.
    output logic [DATA_WIDTH   - 1:0] S1_DAT_I,
    output logic [ADDR_WIDTH   - 1:0] S1_ADR_I,
    input  logic [DATA_WIDTH   - 1:0] S1_DAT_O,
    output logic                      S1_WE_I,
    output logic [DATA_WIDTH/8 - 1:0] S1_SEL_I,
    output logic                      S1_STB_I,
    input  logic                      S1_ACK_O,
    output logic                      S1_CYC_I
);

    //------------------------
    // Internal nets.
    //------------------------
    logic memory_access = (M_ADR_O >= 32'h3000_0000);


    //-----------------------------------
    // FSM.
    //-----------------------------------

    // FSM: States.
    typedef enum logic [1:0] {
        IDLE = 2'd0,
        SLV0 = 2'd1,
        SLV1 = 2'd2
    } state_t;

    state_t PS;
    state_t NS;


    // FSM: Next state synchronization.
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) PS <= IDLE;
        else       PS <= NS;
    end


    // FSM: Next state logic.
    always_comb begin
        // Default values.
        NS = PS;

        case (PS)
            IDLE: begin
                if (M_STB_O & M_CYC_O) begin
                    if (memory_access)
                        NS = SLV0;
                    else
                        NS = SLV1;
                end
            end
            SLV0: begin
                if (wb_done_i)
                    NS = IDLE;
            end
            SLV1: begin
                if (wb_done_i)
                    NS = IDLE;
            end
            default: NS = PS;
        endcase
    end


    // FSM: Output logic.
    always_comb begin
        // Default values.
        // Master: CPU
        M_DAT_I = 'd0;
        M_ACK_I = 'd0;
        // Slave 0: Memory.
        S0_DAT_I = 'd0;
        S0_ADR_I = 'd0;
        S0_WE_I  = 'd0;
        S0_SEL_I = 'd0;
        S0_STB_I = 'd0;
        S0_CYC_I = 'd0;
        // Slave 1: UART.
        S1_DAT_I = 'd0;
        S1_ADR_I = 'd0;
        S1_WE_I  = 'd0;
        S1_SEL_I = 'd0;
        S1_STB_I = 'd0;
        S1_CYC_I = 'd0;

        case (PS)
            SLV0: begin
                // Master: CPU
                M_DAT_I = S0_DAT_O;
                M_ACK_I = S0_ACK_O;
                // Slave 0: Memory.
                S0_DAT_I = M_DAT_O;
                S0_ADR_I = M_ADR_O;
                S0_WE_I  = M_WE_O;
                S0_SEL_I = M_SEL_O;
                S0_STB_I = M_STB_O;
                S0_CYC_I = M_CYC_O;
            end
            SLV1: begin
                // Master: CPU
                M_DAT_I = S1_DAT_O;
                M_ACK_I = S1_ACK_O;
                // Slave 1: UART.
                S1_DAT_I = M_DAT_O;
                S1_ADR_I = M_ADR_O;
                S1_WE_I  = M_WE_O;
                S1_SEL_I = M_SEL_O;
                S1_STB_I = M_STB_O;
                S1_CYC_I = M_CYC_O;
            end
            default: begin
                // Default values.
                // Master: CPU
                M_DAT_I = 'd0;
                M_ACK_I = 'd0;
                // Slave 0: Memory.
                S0_DAT_I = 'd0;
                S0_ADR_I = 'd0;
                S0_WE_I  = 'd0;
                S0_SEL_I = 'd0;
                S0_STB_I = 'd0;
                S0_CYC_I = 'd0;
                // Slave 1: UART.
                S1_DAT_I = 'd0;
                S1_ADR_I = 'd0;
                S1_WE_I  = 'd0;
                S1_SEL_I = 'd0;
                S1_STB_I = 'd0;
                S1_CYC_I = 'd0;
            end
        endcase
    end

endmodule
