/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// ALU decoder is a module designed to output alu control signal based on
// op[5], alu_op, func_3, func_7[5] signals. 
// -----------------------------------------------------------------------

module alu_decoder 
// Port delerations. 
(
    // Input interface.
    input  logic [1:0] i_alu_op,
    input  logic [2:0] i_func_3,
    input  logic       i_func_7_5,
    input  logic       i_op_5,

    // Output interface. 
    output logic [4:0] o_alu_control
);

    logic [1:0] s_op_func_7;

    assign s_op_func_7 = { i_op_5, i_func_7_5 };

    // ALU decoder logic.
    always_comb begin 
        case ( i_alu_op )
            2'b00: o_alu_control = 5'b00000; // ADD for I type instruction: lw, sw.
            2'b01: o_alu_control = 5'b00001; // SUB  for B type instructions: beq, bne.

            // I & R Type.
            2'b010: 
                case (i_func_3)
                    3'b000: if ( s_op_func_7 == 2'b11 ) o_alu_control = 5'b00001; // sub instruciton.
                            else                        o_alu_control = 5'b00000; // add instruciton.

                    3'b001: if ( i_func_7_5 ) o_alu_control = 5'b00101; // sll instruction.
                            else              o_alu_control = 5'b01010; // slli instruction. 

                    3'b010: o_alu_control = 5'b00110; // slt instruction. 

                    3'b011: o_alu_control = 5'b00111; // sltu instruction.

                    3'b100: o_alu_control = 5'b00100; // xor instruction.

                    3'b101: 
                        case ( s_op_func_7 )
                            2'b00:   o_alu_control = 5'b01011; // srli instruction.
                            2'b01:   o_alu_control = 5'b01100; // srai instruction. 
                            2'b10:   o_alu_control = 5'b01000; // srl instruction. 
                            2'b11:   o_alu_control = 5'b01001; // sra instruction. 
                            default: o_alu_control = 5'b01000; // srl instruction for default. 
                        endcase

                    3'b110: o_alu_control = 5'b00011; // or instruction.

                    3'b111: o_alu_control = 5'b00010; // and instruction.

                    default: o_alu_control = 5'b00000; // add instrucito for default. 
                endcase

            // I & R Type W.
            2'b11: 
                case ( i_func_3 )
                    3'b000: if ( i_op_5 ) o_alu_control = 5'b01101; // ADDW
                            else          o_alu_control = 5'b10010; // ADDIW
                    3'b001: o_alu_control = 5'b01111; // SLLIW or SLLW
                    3'b101: if ( i_func_7_5 ) o_alu_control = 5'b10001; // SRAIW or SRAW.
                            else              o_alu_control = 5'b10000; // SRLIW or SRLW. 
                    default: o_alu_control = 5'b00000; // Default.
                endcase 
            
            default: o_alu_control = 5'b00000; // Default.

        endcase
    end

    
endmodule