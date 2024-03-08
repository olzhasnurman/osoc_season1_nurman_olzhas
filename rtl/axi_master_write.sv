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
    output logic                            B_READY
);

    //------------------------
    // Write FSM.
    //------------------------
    
    // FSM: States
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        ADDRESS = 
    } t_state;

    t_state PS;
    t_state NS;
    
    // FSM: State Synchronization 
    always_ff @( posedge clk, negedge arstn ) begin
        if ( ~arstn ) begin
            PS <= IDLE;
        end
        else PS <= NS;
    end

    // FSM: Next State Logic.
    always_comb begin
        NS = PS;

        case ( PS )
            IDLE: begin
                if ( i_start_write ) NS = 
            end 
            default: 
        endcase
    end

    // FSM: Output Logic.
    always_comb begin
        
    end

    
endmodule