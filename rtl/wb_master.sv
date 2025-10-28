/* Copyright (c) 2025 Maveric NU. All rights reserved. */


// ---------------------------------------------------------------------------------------
// This is a WB Master module for establishing connection between CPU and WB Slave.
// ---------------------------------------------------------------------------------------

module wb_master
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
    input  logic                      start_rd_i,
    input  logic                      start_wr_i,
    input  logic [DATA_WIDTH/8 - 1:0] sel_i,
    input  logic [DATA_WIDTH   - 1:0] data_i,
    input  logic [ADDR_WIDTH   - 1:0] addr_i,

    // Output interface.
    output logic                      done_o,
    output logic [DATA_WIDTH   - 1:0] data_o,

    //-------------------------------
    // WB Interface Signals.
    //-------------------------------
    input  logic [DATA_WIDTH   - 1:0] DAT_I,
    output logic [ADDR_WIDTH   - 1:0] ADR_O,
    output logic [DATA_WIDTH   - 1:0] DAT_O,
    output logic                      WE_O,
    output logic [DATA_WIDTH/8 - 1:0] SEL_O,
    output logic                      STB_O,
    input  logic                      ACK_I,
    output logic                      CYC_O
);


    //-------------------------------------
    // FSM.
    //-------------------------------------
    // FSM: States.
    typedef enum logic [1:0] {
        IDLE    = 2'd0,
        RD_DONE = 2'd1,
        WR_DONE = 2'd2
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
                if (~ ACK_I) begin
                    if (start_rd_i)
                        NS = RD_DONE;
                    else if (start_wr_i)
                        NS = WR_DONE;
                end
            end
            RD_DONE,
            WR_DONE: begin
                if (ACK_I)
                    NS = IDLE;
            end
            default: NS = PS;
        endcase
    end

    // FSM: Output logic.
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            ADR_O  <= '0;
            DAT_O  <= '0;
            WE_O   <= '0;
            SEL_O  <= '0;
            STB_O  <= '0;
            CYC_O  <= '0;
            data_o <= '0;
            done_o <= '0;
        end
        else begin
            case (PS)
                IDLE: begin
                    STB_O  <= 1'b0;
                    CYC_O  <= 1'b0;
                    done_o <= 1'b0;
                    if (~ ACK_I) begin
                        if (start_rd_i) begin
                            ADR_O <= addr_i;
                            WE_O  <= 1'b0; // read.
                            STB_O <= 1'b1;
                            CYC_O <= 1'b1;
                        end
                        else if (start_wr_i) begin
                            ADR_O <= addr_i;
                            DAT_O <= data_i;
                            WE_O  <= 1'b1; // write.
                            SEL_O <= sel_i;
                            STB_O <= 1'b1;
                            CYC_O <= 1'b1;
                        end
                    end
                end
                RD_DONE: begin
                    if (ACK_I) begin
                        data_o <= DAT_I;
                        done_o <= 1'b1;
                        STB_O  <= 1'b0;
                        CYC_O  <= 1'b0;
                    end
                end
                WR_DONE: begin
                    if (ACK_I) begin
                        done_o <= 1'b1;
                        STB_O  <= 1'b0;
                        CYC_O  <= 1'b0;
                    end
                end
                default: begin
                    ADR_O  <= ADR_O;
                    DAT_O  <= DAT_O;
                    WE_O   <= WE_O;
                    SEL_O  <= SEL_O;
                    STB_O  <= STB_O;
                    CYC_O  <= CYC_O;
                    data_o <= data_o;
                    done_o <= done_o;
                end
            endcase
        end
    end


endmodule