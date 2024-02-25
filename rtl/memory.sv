/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------------------------------
// This is a instruction and data memory component of processor based on RISC-V architecture.
// -------------------------------------------------------------------------------------------
/* verilator lint_off WIDTH */
module memory
// Parameters.
#(
    parameter DATA_WIDTH  = 64,
              ADDR_WIDTH  = 64,
              INSTR_WIDTH = 32,
              MEM_DEPTH   = 1024
)
// Port decleration. 
(   
    // Common clock & enable signal.
    input  logic                       clk,
    input  logic                       write_en,
    input  logic [               1:0 ] i_store_type,
                     
    //Input interface. 
    input  logic [ ADDR_WIDTH  - 1:0 ] i_addr,
    input  logic [ DATA_WIDTH  - 1:0 ] i_write_data,
    
    // Output interface.
    output logic [ DATA_WIDTH  - 1:0 ] o_read_data,
    output logic [ INSTR_WIDTH - 1:0 ] o_read_instr
);

    // Register block.
    logic [ DATA_WIDTH - 1:0 ] mem [ MEM_DEPTH - 1:0 ];

    // Write logic.
    always_ff @( posedge clk ) begin 
        if ( write_en ) begin
            case ( i_store_type )
                2'b11: mem [ i_addr [ ADDR_WIDTH - 1:3 ] ]        <= i_write_data;        // SD Instruction.
                2'b10: mem [ i_addr [ ADDR_WIDTH - 1:3 ] ] [31:0] <= i_write_data[31:0];  // SW Instruction.
                2'b01: mem [ i_addr [ ADDR_WIDTH - 1:3 ] ] [15:0] <= i_write_data[15:0];  // SH Instruction.
                2'b00: mem [ i_addr [ ADDR_WIDTH - 1:3 ] ] [7:0 ] <= i_write_data[7:0];   // SB Instruction.

                default: mem[ i_addr[ ADDR_WIDTH - 1:3 ] ] <= i_write_data;
            endcase
        end
    end

    // Read logic.
    assign o_read_data = mem [ i_addr[ ADDR_WIDTH - 1:3 ] ];

    assign o_read_instr = i_addr[2] ? mem [ i_addr[ ADDR_WIDTH - 1:3 ] ] [63:32] : mem [ i_addr[ ADDR_WIDTH - 1:3 ] ] [31:0];

    
endmodule