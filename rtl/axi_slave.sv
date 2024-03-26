/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------------------------------------------------------------------------
// This is a AXI Slave protocol implementation for communication with outside memory for read operations.
// --------------------------------------------------------------------------------------------------------

module axi_slave
#(
    parameter AXI_ADDR_WIDTH = 64,
              AXI_DATA_WIDTH = 32,
              DATA_WIDTH     = 512
) 
(
    input  logic                         clk,
    input  logic                         arstn,
    input  logic [ AXI_DATA_WIDTH - 1:0] i_data,
    output logic [ AXI_DATA_WIDTH - 1:0] o_data,
    output logic [ AXI_ADDR_WIDTH - 1:0] o_addr,
    output logic                         o_write_en,


    //--------------------------------------
    // AXI Interface signals.
    //--------------------------------------

    // Read Channel: Address. Ignored AR_ID for now.
    output logic                            AR_READY,
    input  logic                            AR_VALID,
    input  logic [                    7:0 ] AR_LEN,   // Optional.
    input  logic [                    2:0 ] AR_SIZE,  // Optional.
    input  logic [                    1:0 ] AR_BURST, // Optional.
    input  logic [ AXI_ADDR_WIDTH   - 1:0 ] AR_ADDR,
    input  logic [                    2:0 ] AR_PROT,

    // Read Channel: Data. Ignored R_ID for now.
    output logic [ AXI_DATA_WIDTH   - 1:0 ] R_DATA,
    output logic [                    1:0 ] R_RESP, // Optional.
    output logic                            R_LAST, // Optional.
    output logic                            R_VALID,
    input  logic                            R_READY,


    //--------------------------------------
    // AXI Interface signals: WRITE
    //--------------------------------------

    // Write Channel: Address. Ignored AW_ID for now.
    output logic                            AW_READY,
    input  logic                            AW_VALID,
    input  logic [                    2:0 ] AW_PROT,
    input  logic [ AXI_ADDR_WIDTH   - 1:0 ] AW_ADDR,
    input  logic [                    7:0 ] AW_LEN,   // Optional.
    input  logic [                    2:0 ] AW_SIZE,  // Optional.
    input  logic [                    1:0 ] AW_BURST, // Optional.

    // Write Channel: Data.
    output logic                            W_READY,
    input  logic [ AXI_DATA_WIDTH   - 1:0 ] W_DATA,
    input  logic [ AXI_DATA_WIDTH/8 - 1:0 ] W_STRB, // Optional.
    input  logic                            W_LAST,
    input  logic                            W_VALID,

    // Write Channel: Response. Ignored B_ID for now.
    output logic [                    1:0 ] B_RESP, // Optional.
    output logic                            B_VALID,
    input  logic                            B_READY
);

    //-------------------------
    // Internal signals.
    //-------------------------
    logic s_count_start;
    logic s_count_done;
    logic [7:0] s_count;

    //-------------------------
    // Continious assignments.
    //-------------------------
    assign R_DATA = i_data;
    assign o_data = W_DATA;

    // FSM: States.
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        READ  = 2'b10,
        WRITE = 2'b01,
        RESP  = 2'b11
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
                if ( AR_VALID & AR_READY ) begin
                    NS = READ;
                end
                else if ( AW_READY & AW_VALID ) begin
                    NS = WRITE;
                end    
            end 

            READ: begin
                if ( R_READY & R_VALID ) begin
                    if ( R_LAST ) begin
                        NS = IDLE;
                    end
                end
            end

            WRITE: begin
                if ( W_READY & W_VALID ) begin
                    if ( W_LAST ) begin
                        NS = RESP;
                    end
                end
            end

            RESP: begin
                if ( B_READY & B_VALID ) begin
                    NS = IDLE;
                end
            end

            default: NS = PS;
        endcase
    end

    // FSM: Output Logic.
    always_comb begin
        
        // Default values.
        R_VALID = 1'b0;
        AR_READY = 1'b0;
        s_count_start = 1'b0;
        o_write_en = 1'b0;
        B_RESP = 2'b11;
        B_VALID = 1'b0;
        
        case ( PS )
            IDLE: begin
                AR_READY = 1'b1;
                AW_READY = 1'b1;
            end

            READ: begin
                R_VALID = 1'b1;
                if ( R_VALID & R_READY ) begin
                   s_count_start = 1'b1; 
                end
                if ( R_LAST ) begin
                    R_RESP = 2'b00;
                end
            end

            WRITE: begin
                W_READY = 1'b1;
                if ( W_READY & W_VALID ) begin
                    o_write_en = 1'b1;
                end
            end

            RESP: begin
                B_VALID = 1'b1;
                B_RESP = 2'b00;
            end

            default: begin
                R_VALID = 1'b0;
                AR_READY = 1'b0;
                s_count_start = 1'b0;
                o_write_en = 1'b0;
                B_RESP = 2'b11;
                B_VALID = 1'b0;
            end

        endcase

    end

    // Counter.
    always_ff @( posedge clk, posedge AR_VALID ) begin
        if ( AR_VALID ) begin 
            s_count <= '0;
            s_count_done <= 1'b0;
        end
        else if ( s_count_start ) begin
            if ( s_count < (AR_LEN - 'd2) ) begin
                s_count <= s_count + 'b1;
                s_count_done <= 1'b0;
            end
            else begin
                s_count <= s_count;
                s_count_done <= 1'b1;
            end
        end
    end

    // Address increment.
    always_ff @( posedge clk ) begin 
        if ( AR_VALID & AR_READY & ( PS == IDLE )) begin
           R_LAST <= 1'b0;
           o_addr <= AR_ADDR;  
        end
        else begin
            if ( R_READY ) begin
                if ( s_count_done ) begin
                    R_LAST <= 1'b1;
                    o_addr <= o_addr;
                end
                else begin
                    R_LAST <= 1'b0;
                    o_addr <= o_addr + 'b100;
                end
            end
            else begin
                R_LAST <= 1'b0;
                o_addr <= o_addr;
            end  
        end
    end
    
endmodule