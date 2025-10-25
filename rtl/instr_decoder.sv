/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// This is a module designed to assign ImmSrc based on instruction opcode.
// ImmSrc is a signal designed to control immediate extension logic.
// -----------------------------------------------------------------------

module instr_decoder 
// Parameters.
#(
    parameter OP_WIDTH  = 7,
              OUT_WIDTH = 3
)
// Ports. 
(
    input  logic [ OP_WIDTH  - 1:0 ] i_op,
    output logic [ OUT_WIDTH - 1:0 ] o_imm_src
); 

    //Decoder logic.
    /*
    __________________
    | OP      | Type |
    |---------|------|
    | 0000011 | I    |
    | 0010011 | I    |
    | 1100111 | I    |
    | 0100011 | S    |
    | 1100011 | B    |
    | 1101111 | J    |
    |________________|

     ___________________________________
    | control signal | instuction type |
    |________________|_________________|
    | 000            | I type          |
    | 001            | S type          |
    | 010            | B type          |
    | 011            | J type          |
    | 100            | U type          |
    |__________________________________|
    */

    always_comb begin
        case ( i_op )
            7'b1101111: o_imm_src = 3'b011; // J type.
            7'b1100011: o_imm_src = 3'b010; // B type.
            7'b0100011: o_imm_src = 3'b001; // S type.
            7'b0010111: o_imm_src = 3'b100; // U type.
            7'b0110111: o_imm_src = 3'b100; // U type. 
            7'b0000011: o_imm_src = 3'b000; // I type.
            7'b0010011: o_imm_src = 3'b000; // I type.
            7'b1100111: o_imm_src = 3'b000; // I type.
            7'b0011011: o_imm_src = 3'b000; // I type.
            7'b1110011: o_imm_src = 3'b101; // CSR. 
            default:    o_imm_src = 3'b000; // Default = for I type.
        endcase
    end

endmodule