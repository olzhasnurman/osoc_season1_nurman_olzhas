/* Copyright (c) 2025 Maveric NU. All rights reserved. */


// ----------------------------------------------------------------------------------------
// This is a WB Slave module for establishing connection between WB Master and Peripheral.
// ----------------------------------------------------------------------------------------

module wb_slave
// Parameters.
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
// Port declerations.
(
    // Common clock & reset.
    input  logic                      clk_i,
    input  logic                      rst_i,

    // Input interface.
    input  logic                      successful_access_i,
    input  logic                      successful_rd_i,
    input  logic                      successful_wr_i,
    input  logic [DATA_WIDTH   - 1:0] data_i,

    // Output interface.
    output logic                      rd_req_o,
    output logic                      wr_en_o,
    output logic [ADDR_WIDTH   - 1:0] addr_o,
    output logic [DATA_WIDTH   - 1:0] data_o,

    //-------------------------------
    // WB Interface Signals.
    //-------------------------------
    input  logic [DATA_WIDTH   - 1:0] DAT_I,
    input  logic [ADDR_WIDTH   - 1:0] ADR_I,
    output logic [DATA_WIDTH   - 1:0] DAT_O,
    input  logic                      WE_I,
    input  logic [DATA_WIDTH/8 - 1:0] SEL_I,
    input  logic                      STB_I,
    output logic                      ACK_O,
    input  logic                      CYC_I
);


    //-------------------------------------
    // FSM.
    //-------------------------------------
    // FSM: States.
    typedef enum logic [2:0] {
        IDLE     = 3'd0,
        RD_START = 3'd1,
        RD_DONE  = 3'd2,
        WR_START = 3'd3,
        WR_DONE  = 3'd4
    } state_t;

    state_t PS;
    state_t NS;


    // FSM: Next state logic.
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
                if (STB_I & CYC_I) begin
                    if (WE_I)
                        NS = WR_START;
                    else
                        NS = RD_START;
                end
            end
            RD_START: begin
                if (successful_access_i & successful_rd_i)
                    NS = RD_DONE;
            end
            RD_DONE: begin
                if (~ (STB_I & CYC_I))
                    NS = IDLE;
            end
            WR_START: begin
                if (successful_access_i & successful_wr_i)
                    NS = WR_DONE;
            end
            WR_DONE: begin
                if (~ STB_I)
                    NS = IDLE;
            end
            default: NS = PS;
        endcase
    end

    // FSM: Output logic.
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            DAT_O    <= '0;
            ACK_O    <= '0;
            rd_req_o <= '0;
            wr_en_o  <= '0;
            addr_o   <= '0;
            data_o   <= '0;
        end
        else begin
            case (PS)
                IDLE: begin
                    if (STB_I & CYC_I) begin
                        if (WE_I) begin
                            wr_en_o <= 1'b1;
                            addr_o  <= ADR_I;
                            data_o  <= DAT_I;
                        end
                        else begin
                            rd_req_o <= 1'b1;
                            addr_o   <= ADR_I;
                        end
                    end
                end
                RD_START: begin
                    if (successful_access_i & successful_rd_i) begin
                        DAT_O    <= data_i;
                        ACK_O    <= 1'b1;
                        rd_req_o <= 1'b0;
                    end
                end
                RD_DONE: begin
                    if (~ (STB_I & CYC_I)) begin
                        ACK_O <= 1'b0;
                    end
                end
                WR_START: begin
                    if (successful_access_i & successful_wr_i) begin
                        ACK_O   <= 1'b1;
                        wr_en_o <= 1'b0;
                    end
                end
                WR_DONE: begin
                    if (~ STB_I) begin
                        ACK_O <= 1'b0;
                    end
                end
                default: begin
                    DAT_O    <= DAT_O;
                    ACK_O    <= ACK_O;
                    rd_req_o <= rd_req_o;
                    wr_en_o  <= wr_en_o;
                    addr_o   <= addr_o;
                    data_o   <= data_o;
                end
            endcase
        end
    end

endmodule