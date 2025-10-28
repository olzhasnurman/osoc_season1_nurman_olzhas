/* Copyright (c) 2025 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------
// This is a memory module for simulation of outside memory unit.
// ---------------------------------------------------------------

// `define PATH_TO_MEM "./test/tests/instr/riscv-tests/rv64ui-p-xori.txt"

module mem_sim
#(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 32,
              ADDR_W = 14
)
(
    // Control signals.
    input  logic clk,
    input  logic arst,
    input  logic write_en,
    input  logic i_read_request,

    // Input signals.
    input  logic [ DATA_WIDTH - 1:0 ] i_data,
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr,

    // Output signals.
    output logic [ DATA_WIDTH - 1:0 ] o_data,
    output logic                      o_successful_access,
    output logic                      o_successful_read,
    output logic                      o_successful_write
);
    logic [ADDR_W - 1:0] s_addr;

    assign s_addr = i_addr[ADDR_W + 1:2];

    logic access_s;
    logic access_request_s;

    assign access_request_s = i_read_request | write_en;

    assign o_successful_read   = 1'b1;
    assign o_successful_write  = 1'b1;


    // Simulating random multiple clock cycle memory access.
    logic [7:0] count_s;

    always_ff @(posedge clk, posedge arst) begin
        if (arst  )
            count_s <= '0;
        else if (access_s)
            count_s <= '0;
        else if (access_request_s)
            count_s <= count_s + 8'b1;
    end

    assign access_s            = (count_s == lfsr_s);
    assign o_successful_access = access_s;


    //---------------------------------------------
    // LFSR for generating pseudo-random sequence.
    //---------------------------------------------
    logic [7:0] lfsr_s;
    logic         lfsr_msb_s;

    assign lfsr_msb_s = lfsr_s [7] ^ lfsr_s [5] ^ lfsr_s [4] ^ lfsr_s [3];

    // Primitive Polynomial: x^8+x^6+x^5+x^4+1
    always_ff @(posedge clk, posedge arst) begin
        if      (arst    ) lfsr_s <= 8'b00010101; // Initial value.
        else if (access_s) lfsr_s <= {lfsr_msb_s, lfsr_s [7:1]};
    end


    // blk_mem_gen_0 K_MEM_BLK0 (
    //     .clka  (clk        ),
    //     .addra (s_addr     ),
    //     .wea   (write_en   ),
    //     .dina  (i_data     ),
    //     .douta (o_data     )
    // );


endmodule
