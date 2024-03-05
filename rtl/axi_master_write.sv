/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ------------------------------------------------------------------------------------
// This is a AXI Master protocol implementation for communication with outside memory.
// ------------------------------------------------------------------------------------

module axi_master
#(
    parameter AXI_ADDR_WIDTH = 64,
              AXI_DATA_WIDTH = 32
) 
(
    // Control signals.
    input logic clk,
    input logic arstn,

    // Input interface.
    input logic [ AXI_ADDR_WIDTH - 1:0 ] i_addr,
    input logic [ AXI_DATA_WIDTH - 1:0 ] i_data,
    input logic                          i_start_write,
    input logic                          i_start_read,

    // Output interface. 
    output logic [ AXI_DATA_WIDTH - 1:0 ] o_data,
    output logic                          o_valid,

    //--------------------------------------
    // AXI Interface signals.
    //--------------------------------------

    // Write Channel: Address. Ignored AW_ID for now.
    input  logic                            AW_READY,
    output logic                            AW_VALID,
    output logic [                    2:0 ] AW_PROT,
    output logic [ AXI_ADDR_WIDTH   - 1:0 ] AW_ADDR,
    output logic [                    7:0 ] AW_LEN,   // Optional.
    output logic [                    2:0 ] AW_SIZE,  // Optional.
    output logic [                    1:0 ] AW_BURST, // Optional.

    // Write Channel: Data.
    input  logic                            W_READY,
    output logic [ AXI_DATA_WIDTH   - 1:0 ] W_DATA,
    output logic [ AXI_DATA_WIDTH/8 - 1:0 ] W_STRB, // Optional.
    output logic                            W_LAST,
    output logic                            W_VALID,

    // Write Channel: Response. Ignored B_ID for now.
    input  logic [                    1:0 ] B_RESP, // Optional.
    input  logic                            B_VALID,
    output logic                            B_READY,

    // Read Channel: Address. Ignored AR_ID for now.
    input  logic                            AR_READY,
    output logic                            AR_VALID,
    output logic [                    7:0 ] AR_LEN,   // Optional.
    output logic [                    2:0 ] AR_SIZE,  // Optional.
    output logic [                    1:0 ] AR_BURST, // Optional.
    output logic [ AXI_ADDR_WIDTH   - 1:0 ] AR_ADDR,
    output logic [                    2:0 ] AR_PROT,

    // Read Channel: Data. Ignored R_ID for now.
    input  logic [ AXI_DATA_WIDTH   - 1:0 ] R_DATA,
    input  logic [                    1:0 ] R_RESP, // Optional.
    input  logic                            R_LAST, // Optional.
    input  logic                            R_VALID,
    output logic                            R_READY
);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        ADDRESS = 
    } t_state;

    //------------------------
    // Write FSM.
    //------------------------
    
    // FSM: State Synchronization 
    always_ff @( posedge clk, negedge arstn ) begin
        if ( ~arstn ) begin
            W_PS <= IDLE;
        end
        else W_PS <= W_NS;
    end

    // FSM: Next State Logic.
    always_comb begin
        W_NS = W_PS;

        case ( W_PS )
            IDLE: begin
                if ( i_start_write ) W_NS = 
            end 
            default: 
        endcase
    end

    // FSM: Output Logic.



    //------------------------
    // Read FSM.
    //------------------------
    
    // FSM: State Synchronization 
    always_ff @( posedge clk, negedge arstn ) begin 
        if ( ~arstn ) begin
            R_PS <= IDLE;
        end
        else R_PS <= R_NS;
    end

    // FSM: Next State Logic.
    always_comb begin
        R_NS = R_PS;

        case ( R_PS )
            IDLE: begin
                if ( i_start_read ) R_NS = 
            end 
            default: 
        endcase
    end

    // FSM: Output Logic.

    
endmodule