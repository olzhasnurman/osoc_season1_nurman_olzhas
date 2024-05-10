/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------------------------------------------------------------------------
// This is a AXI Master protocol implementation for communication with outside memory for read operations.
// --------------------------------------------------------------------------------------------------------
/* verilator lint_off UNUSED */

module axi_master
#(
    parameter AXI_ADDR_WIDTH = 64,
              AXI_DATA_WIDTH = 32,
              DATA_WIDTH     = 512
) 
(
    // Control signals.
    input logic clk,
    input logic arstn,

    // Input interface.
    input logic [ AXI_ADDR_WIDTH - 1:0 ] i_addr,
    input logic [ DATA_WIDTH     - 1:0 ] i_data,
    input logic                          i_start_write,
    input logic                          i_start_read,

    // Output interface. 
    output logic [ DATA_WIDTH    - 1:0 ] o_data,
    output logic                         o_read_last_axi,
    output logic                         o_b_resp_axi,

    //--------------------------------------
    // AXI Interface signals: WRITE
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

    //--------------------------------------
    // AXI Interface signals: READ
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
    logic                          s_fifo_we;
    logic [ DATA_WIDTH     - 1:0 ] s_fifo_out;

    logic s_shift;
    logic [ DATA_WIDTH - 1:0 ]s_data;
    logic s_count_start;
    logic s_count_done;
    logic [7:0] s_count;

    //-------------------------
    // Continious assignments.
    //-------------------------
    assign AR_LEN   = 8'd16;  // 16 in case of 512 bit data out size.
    assign AR_SIZE  = 3'b010; // 32 bit / 4 bytes. 
    assign AR_BURST = 2'b01;  // Incrementing Burst.
    assign AR_PROT  = 3'b100; // Random value. NOT FINAL VALUE.


    assign AW_PROT  = 3'b001; // Priviledged access.
    assign AW_LEN   = 8'd16;  // 16 in case of 512 bit data out size with burst size of 32 bits.
    assign AW_SIZE  = 3'b010; // 32 bit / 4 bytes.
    assign AW_BURST = 2'b01;  // Incrementing Burst.

    assign W_STRB   = W_VALID ? 4'b1111 : 4'b0000; // All bytes are valid whenever W_VALID is High.

    assign o_read_last_axi = R_LAST;


    //-------------------------
    // Read FSM.
    //-------------------------

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
                if ( i_start_read & AR_READY ) begin
                    NS = READ;
                end
                else if ( i_start_write & AW_READY ) begin
                    NS = WRITE;
                end
            end 

            READ: begin
                if (R_VALID & R_READY ) begin
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

            RESP: if ( B_VALID & B_READY & ( B_RESP == 2'b00 )) begin
                NS = IDLE;
            end

            default: NS = PS;
        endcase
    end

    // FSM: Output Logic.
    always_comb begin

        // Default values.
        s_fifo_we     = 1'b0;
        R_READY       = 1'b0;
        W_VALID       = 1'b0;
        AR_VALID      = 1'b0;
        AW_VALID      = 1'b0;
        B_READY       = 1'b0;
        o_b_resp_axi  = 1'b0;
        s_count_start = 1'b0;
        s_shift       = 1'b0;
        AR_ADDR       = i_addr;
        AW_ADDR       = i_addr;
        
        case ( PS )
            IDLE: begin
                if ( i_start_read ) begin
                    AR_VALID = 1'b1;
                    AR_ADDR  = i_addr;
                end
                else if ( i_start_write ) begin
                    AW_VALID = 1'b1;
                    AW_ADDR  = i_addr;
                    s_shift  = 1'b1;
                end
            end

            READ: begin
                AR_ADDR = i_addr;
                if ( i_start_read ) begin
                    R_READY = 1'b1;
                end
                else R_READY = 1'b0;

                if ( R_VALID & i_start_read ) begin
                    s_fifo_we = 1'b1;
                end
                else s_fifo_we = 1'b0;
            end

            WRITE: begin
                AW_ADDR = i_addr;
                if ( i_start_write ) begin
                    W_VALID = 1'b1;
                    if ( W_LAST ) begin
                        s_shift       = 1'b0;
                        s_count_start = 1'b0;
                    end
                    else begin
                        s_shift       = 1'b1;
                        s_count_start = 1'b1;
                    end
                end
                else begin
                    W_VALID = 1'b0;
                    s_shift = 1'b0;
                end
            end

            RESP: begin
                B_READY = 1'b1;
                if ( B_READY & B_VALID ) begin
                    if ( B_RESP == 2'b00 ) begin
                        o_b_resp_axi = 1'b1;
                    end
                end
            end

            default: begin
                s_fifo_we     = 1'b0;
                R_READY       = 1'b0;
                W_VALID       = 1'b0;
                AR_VALID      = 1'b0;
                AW_VALID      = 1'b0;
                B_READY       = 1'b0;
                o_b_resp_axi  = 1'b0;
                s_count_start = 1'b0;
                s_shift       = 1'b0;
            end 
        endcase
    end


    //-------------------------------------
    // Output FIFO.
    //-------------------------------------
    always_ff @( posedge clk ) begin
        if ( s_fifo_we ) begin
            s_fifo_out <= { R_DATA , s_fifo_out[ DATA_WIDTH - 1:32 ]};
        end
    end

    //----------------------------------
    // Shift register.
    //----------------------------------
    always_ff @( posedge clk ) begin
        if ( AW_VALID ) begin
            s_data <= { 32'b0, i_data[DATA_WIDTH - 1:32]};
            W_DATA <= i_data[31:0];
        end
        else if ( s_shift ) begin
            { s_data, W_DATA } <= { 32'b0, s_data[DATA_WIDTH - 1:0] };
        end
    end

    // Counter.
    always_ff @( posedge clk ) begin
        if ( AW_VALID ) begin 
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

    // Write last bit. 
    always_ff @( posedge clk ) begin 
        if ( s_count_done ) W_LAST <= 1'b1;
        else                W_LAST <= 1'b0;
    end

    assign o_data = s_fifo_out;
    
endmodule

/* verilator lint_on UNUSED */