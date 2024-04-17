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
    output logic [3:0] o_alu_control
);

    logic [1:0] s_op_func_7;

    assign s_op_func_7 = { i_op_5, i_func_7_5 };

    // ALU decoder logic.
    always_comb begin 
        case ( i_alu_op )
            2'b00: o_alu_control = 4'b0000; // ADD for I type instruction: lw, sw.
            2'b01: o_alu_control = 4'b0001; // SUB  for B type instructions: beq, bne.

            // I & R Type.
            2'b10: 
                case (i_func_3)
                    3'b000: if ( s_op_func_7 == 2'b11 ) o_alu_control = 4'b0001; // sub instruciton.
                            else                        o_alu_control = 4'b0000; // add & addi instruciton.

                    3'b001: o_alu_control = 4'b0101; // sll & slli instructions.

                    3'b010: o_alu_control = 4'b0110; // slt instruction. 

                    3'b011: o_alu_control = 4'b0111; // sltu instruction.

                    3'b100: o_alu_control = 4'b0100; // xor instruction.

                    3'b101: 
                        case ( i_func_7_5 )
                            1'b0:   o_alu_control = 4'b1000; // srl & srli instructions.
                            1'b1:   o_alu_control = 4'b1001; // sra & srai instructions. 
                            default: o_alu_control = '0;     // PROBLEM: NEED TO IMPLEMENT ILLEGAL INSTR.
                        endcase

                    3'b110: o_alu_control = 4'b0011; // or instruction.

                    3'b111: o_alu_control = 4'b0010; // and instruction.

                    default: o_alu_control = 4'b0000; // add instrucito for default. 
                endcase

            // I & R Type W.
            2'b11: 
                case ( i_func_3 )
                    3'b000: 
                        case ( s_op_func_7 )
                            2'b11:   o_alu_control = 4'b1011; // SUBW.
                            2'b10:   o_alu_control = 4'b1010; // ADDW.
                            default: o_alu_control = 4'b1111; // ADDIW.
                        endcase
                    3'b001: o_alu_control = 4'b1100; // SLLIW or SLLW
                    3'b101: if ( i_func_7_5 ) o_alu_control = 4'b1110; // SRAIW or SRAW.
                            else              o_alu_control = 4'b1101; // SRLIW or SRLW. 
                    default: o_alu_control = 4'b0000; // PROBLEM: NEED TO IMPLEMENT ILLEGAL INSTR.
                endcase 
            
            default: o_alu_control = 4'b0000; // Default.

        endcase
    end

    
endmodule