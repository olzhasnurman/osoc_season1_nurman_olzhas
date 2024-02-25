/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// This is a module designed to take 64-bit data from memory & adjust it 
// based on different LOAD instruction requirements. 
// -----------------------------------------------------------------------

module load_mux 
#(
    parameter DATA_WIDTH = 64
) 
(
    // Control logic.
    input  logic [              2:0 ] i_func_3,

    // Input interface. 
    input  logic [ DATA_WIDTH - 1:0 ] i_data,

    // Output interface
    output logic [ DATA_WIDTH - 1:0 ] o_data
);

    always_comb begin
        case ( i_func_3 )
            3'b000: o_data = { { 56{i_data[7]} }, i_data[7:0]};   // LB  Instruction.
            3'b001: o_data = { { 48{i_data[15]} }, i_data[15:0]}; // LH  Instruction.
            3'b010: o_data = { { 32{i_data[31]} }, i_data[31:0]}; // LW  Instruction.
            3'b011: o_data = i_data;                              // LD  Instruction.
            3'b100: o_data = { { 56{1'b0} }, i_data[7:0]};        // LBU Instruction.
            3'b101: o_data = { { 48{1'b0} }, i_data[15:0]};       // LHU Instruction.
            3'b110: o_data = { { 32{1'b0} }, i_data[31:0]};       // LWU Instruction.
        
            default:  o_data = '0; // Default

        endcase
    end
    
endmodule