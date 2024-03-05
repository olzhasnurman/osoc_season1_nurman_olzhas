/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------------------------------------------------------------------------
// This is a AXI Master protocol implementation for communication with outside memory for read operations.
// --------------------------------------------------------------------------------------------------------

module axi_master
#(
    parameter AXI_ADDR_WIDTH = 64,
              AXI_DATA_WIDTH = 32,
              DATA_WIDTH     = 512
) 
(
    // Control signals.
    input logic                          clk,
    input logic                          arstn,

    // Input interface.
    input logic [ AXI_ADDR_WIDTH - 1:0 ] i_addr,
    input logic                          i_start_read,

    // Output interface. 
    output logic [ DATA_WIDTH    - 1:0 ] o_data,
    output logic                         o_valid,

    //--------------------------------------
    // AXI Interface signals.
    //--------------------------------------

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
    //-------------------------
    // Internal signals.
    //-------------------------
    logic                      s_fifo_we;
    logic [ DATA_WIDTH - 1:0 ] s_fifo_out;

    //-------------------------
    // Continious assignments.
    //-------------------------
    assign AR_ADDR  = i_addr;
    assign AR_LEN   = 8'd16;  // 16 in case of 512 bit data out size.
    assign AR_SIZE  = 3'b101; // 32 bit.
    assign AR_BURST = 2'b01;  // Incrementing Burst.
    assign AR_PROT  = 3'b100; // Random value. NOT FINAL VALUE.


    //-------------------------
    // Read FSM.
    //-------------------------

    // FSM: States.
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        READ = 2'b10
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
                if ( i_start_read ) begin
                    if ( AR_VALID & AR_READY ) begin
                        NS = READ;
                    end
                end
            end 

            READ: begin
                if (R_VALID & R_READY) begin
                    if ( R_LAST ) begin
                        NS = IDLE;
                    end
                end
            end
            default: NS = PS;
        endcase
    end

    // FSM: Output Logic.
    always_comb begin
        
        case ( PS )
            IDLE: begin
                if ( i_start_read ) begin
                    AR_VALID = 1'b1;
                end
            end

            READ: begin
                if ( i_start_read ) begin
                    R_READY = 1'b1;
                end
                else R_READY = 1'b0;

                if ( R_VALID & R_READY ) begin
                    s_fifo_we = 1'b1;
                end
                else s_fifo_we = 1'b0;
            end

            default: s_fifo_we = 1'b0;
        endcase
    end


    //-------------------------------------
    // Output FIFO.
    //-------------------------------------
    always_ff @( posedge clk ) begin
        if ( s_fifo_we ) begin
            s_fifo_out <= { R_DATA , s_fifo_out[ DATA_WIDTH - 33:0 ]};
        end
    end

    assign o_data = s_fifo_out;
    
endmodule