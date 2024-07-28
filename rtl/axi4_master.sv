/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------------------------------------------------
// This is a AXI4 Master module implementation for communication with outside memory.
// -------------------------------------------------------------------------------------------------------------

module ysyx_201979054_axi4_master
(
    // Control signals.
    input  logic clk,
    input  logic arst,
    input  logic io_interrupt,

    // Interface with CPU.
    input  logic          i_write_req,
    input  logic          i_read_req,
    input  logic [ 31:0 ] i_addr,
    input  logic [ 63:0 ] i_write_data,
    input  logic [  7:0 ] i_axi_len,
    input  logic [  2:0 ] i_axi_size,
    input  logic [  1:0 ] i_axi_burst,
    input  logic [  7:0 ] i_axi_strb,
    output logic [ 63:0 ] o_read_data,
    output logic          o_axi_done,
    output logic          o_axi_handshake,

    // AXI4 Master Bus: Write Interface.
    input  logic 	      i_awready,   // +
    output logic 	      o_awvalid,   // +
    output logic [  3:0 ] o_awid,      // +
    output logic [ 31:0 ] o_awaddr,    // +
    output logic [  7:0 ] o_awlen,     // +
    output logic [  2:0 ] o_awsize,    // +
    output logic [  1:0 ] o_awburst,   // +
    input  logic 	      i_wready,    // +
    output logic 	      o_wvalid,    // +
    output logic [ 63:0 ] o_wdata,     // +
    output logic [  7:0 ] o_wstrb,     // + 
    output logic 	      o_wlast,     // +
    output logic 	      o_bready,    // +
    input  logic 	      i_bvalid,    // +
    input  logic [  3:0 ] i_bid,       // +
    input  logic [  1:0 ] i_bresp,     // +
    
    // AXI4 Master Bus: Write Interface.
    input  logic 	      i_arready, // +
    output logic 	      o_arvalid, // +
    output logic [  3:0 ] o_arid,    // +
    output logic [ 31:0 ] o_araddr,  // +
    output logic [  7:0 ] o_arlen,   // +
    output logic [  2:0 ] o_arsize,  // +
    output logic [  1:0 ] o_arburst, // +
    output logic 	      o_rready,  // +
    input  logic 	      i_rvalid,  // +
    input  logic [  3:0 ] i_rid,     // 
    input  logic [  1:0 ] i_rresp,   // 
    input  logic [ 63:0 ] i_rdata,   // +
    input  logic 	      i_rlast    // +

);
    logic s_wlast;

    //---------------------------
    // Continious assignments.
    //---------------------------
    assign o_read_data = i_rdata;
    assign o_arlen     = i_axi_len;
    assign o_arsize    = i_axi_size;
    assign o_arburst   = i_axi_burst;
    assign o_awlen     = i_axi_len;
    assign o_awsize    = i_axi_size;
    assign o_awburst   = i_axi_burst;
    assign o_wdata     = i_write_data;

    //-------------------------
    // Write FSM.
    //-------------------------

    // FSM: States.
    typedef enum logic [ 2:0 ] {
        IDLE      = 3'b000,
        AW_WRITE  = 3'b001,
        WRITE     = 3'b010,
        BRESP     = 3'b011,
        AR_READ   = 3'b100,
        READ      = 3'b101
    } t_state;

    t_state PS;
    t_state NS;

    // FSM: State Synchronization 
    always_ff @( posedge clk, posedge arst ) begin 
        if ( arst ) begin
            PS <= IDLE;
        end
        else PS <= NS;
    end

    // FSM: Next State Logic.
    always_comb begin
        NS = PS;

        case ( PS )
            IDLE    : if ( i_write_req           ) NS = AW_WRITE;
                 else if ( i_read_req            ) NS = AR_READ;
            AW_WRITE: if ( o_awvalid & i_awready ) NS = WRITE;
            WRITE   : if ( o_wlast & i_wready    ) NS = BRESP;
            BRESP   : if ( i_bvalid & o_bready   ) NS = IDLE;
            AR_READ : if ( o_arvalid & i_arready ) NS = READ;
            READ    : if ( s_rlast               ) NS = IDLE;
            default : NS = PS;
        endcase

    end

    // FSM: Output Logic.
    always_ff @( posedge clk, posedge arst ) begin
        if ( arst ) begin
            o_awvalid <= 1'b0;
            o_awid    <= '0;
            o_awaddr  <= '0;

            o_wvalid  <= 1'b0;
            o_wstrb   <= '0;

            o_bready  <= 1'b0;

            o_arvalid <= 1'b0;
            o_arid    <= '0;
            o_araddr  <= '0;

            o_rready  <= 1'b0;
        end

        else begin
            
        
            case ( PS )
                IDLE: begin
                    o_awvalid <= 1'b0;
                    o_awaddr  <= '0;
        
                    o_wvalid  <= 1'b0;
                    o_wstrb   <= i_axi_strb;
        
                    o_bready  <= 1'b0;
        
                    o_arvalid <= 1'b0;
                    o_araddr  <= '0;
        
                    o_rready  <= 1'b0;
    
                    if ( i_write_req ) begin
                        o_awvalid <= 1'b1;
                        o_awaddr  <= i_addr;
                    end
                    else if  ( i_read_req ) begin
                        o_arvalid <= 1'b1;
                        o_araddr  <= i_addr; 
                    end 
                end
    
                AW_WRITE: begin
                    if ( i_awready ) o_awvalid <= 1'b0;
                    o_wvalid  <= 1'b1;
                end 
    
                WRITE: begin
                    if ( o_wlast & i_wready ) begin
                        o_wvalid <= 1'b0;
                        o_bready <= 1'b1;
                    end
                end 
    
                BRESP: if ( i_bvalid ) begin 
                    o_bready <= 1'b0;
                    o_awid   <= o_awid + 4'b1;
                end
    
                AR_READ: begin
                    if ( i_arready ) o_arvalid <= 1'b0;
                    o_rready  <= 1'b1;
                end
    
                READ: if ( s_rlast ) begin
                    o_rready  <= 1'b0; 
                    o_arid    <= o_arid + 4'b1; 
                end
                  
                default: begin
                    o_awvalid <= 1'b0;
                    o_awid    <= '0;
                    o_awaddr  <= '0;
    
                    o_wvalid  <= 1'b0;
                    o_wstrb   <= '0;
    
                    o_bready  <= 1'b0;
    
                    o_arvalid <= 1'b0;
                    o_arid    <= '0;
                    o_araddr  <= '0;
        
                    o_rready  <= 1'b0;
                end
            endcase
        end
    end


    // o_wlast calculation.

    logic [ 7:0 ] s_count;
    always_ff @( posedge clk ) begin
        if      ( PS == AW_WRITE ) s_count <= i_axi_len + 8'd0;
        else if ( i_wready & o_wvalid            ) s_count <= s_count - 8'b1;
    end

    assign s_wlast = ( s_count == 8'b0 ) & ( PS == WRITE );
    assign o_wlast = s_wlast | ( ( i_axi_len == 8'b0 ) & ( PS == WRITE ) );

    assign o_axi_done = ( ( i_bvalid ) & ( i_bresp == 2'b0 ) & ( o_bready ) ) | ( ( s_rlast ) );
    assign o_axi_handshake = ( i_wready & o_wvalid ) | ( o_rready & i_rvalid );

    logic s_rlast;
    always_ff @( posedge clk ) begin
        s_rlast <= i_rlast;
    end
    
endmodule