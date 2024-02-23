/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------------------------------
// This is a instruction and data memory component of processor based on RISC-V architecture.
// -------------------------------------------------------------------------------------------
/* verilator lint_off WIDTH */
module memory
// Parameters.
#(
    parameter BLOCK_WIDTH = 8,
              DATA_WIDTH  = 32,
              ADDR_WIDTH  = 64,
              MEM_DEPTH   = 1024
)
// Port decleration. 
(   
    // Common clock & enable signal.
    input  logic                      clk,
    input  logic                      write_en,
                     
    //Input interface. 
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data
);

    // Register block.
    logic [ BLOCK_WIDTH - 1:0 ] mem [ MEM_DEPTH - 1:0 ];

    // Write logic.
    always_ff @( posedge clk ) begin 
        if ( write_en ) begin
            mem[i_addr    ] <= i_write_data[7 :0 ];
            mem[i_addr + 1] <= i_write_data[15:8 ];
            mem[i_addr + 2] <= i_write_data[23:16];
            mem[i_addr + 3] <= i_write_data[31:24];
        end
    end

    // Read logic.
    assign o_read_data = {mem[i_addr + 3], mem[i_addr + 2], mem[i_addr + 1], mem[i_addr]};

    
endmodule