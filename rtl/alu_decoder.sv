/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// ALU decoder is a module designed to output alu control signal based on
// op[5], alu_op, func_3, func_7[5] signals. 
// -----------------------------------------------------------------------

module alu_decoder 
// Port delerations. 
(
    // Input interface.
    input  logic [2:0] i_alu_op,
    input  logic [2:0] i_func_3,
    input  logic       i_func_7_5,
    input  logic       i_op_5,

    // Output interface. 
    output logic [4:0] o_alu_control,
    output logic       o_illegal_instr
);

    logic [1:0] s_op_func_7;

    assign s_op_func_7 = { i_op_5, i_func_7_5 };

    // ALU decoder logic.
    always_comb begin 
        o_illegal_instr = 1'b0;

        case ( i_alu_op )
            3'b000: o_alu_control = 5'b00000; // ADD for I type instruction: lw, sw.
            3'b001: o_alu_control = 5'b00001; // SUB  for B type instructions: beq, bne.

            // I & R Type.
            3'b010: 
                case (i_func_3)
                    3'b000: if ( s_op_func_7 == 2'b11 ) o_alu_control = 5'b00001; // sub instruciton.
                            else                        o_alu_control = 5'b00000; // add & addi instruciton.

                    3'b001: o_alu_control = 5'b00101; // sll & slli instructions.

                    3'b010: o_alu_control = 5'b00110; // slt instruction. 

                    3'b011: o_alu_control = 5'b00111; // sltu instruction.

                    3'b100: o_alu_control = 5'b00100; // xor instruction.

                    3'b101: 
                        case ( i_func_7_5 )
                            1'b0:   o_alu_control = 5'b01000; // srl & srli instructions.
                            1'b1:   o_alu_control = 5'b01001; // sra & srai instructions. 
                            default: o_alu_control = '0; 
                        endcase

                    3'b110: o_alu_control = 5'b00011; // or instruction.

                    3'b111: o_alu_control = 5'b00010; // and instruction.

                    default: o_alu_control = 5'b00000; // add instrucito for default. 
                endcase

            // I & R Type W.
            3'b011: 
                case ( i_func_3 )
                    3'b000: 
                        case ( s_op_func_7 )
                            2'b11:   o_alu_control = 5'b01011; // SUBW.
                            2'b10:   o_alu_control = 5'b01010; // ADDW.
                            default: o_alu_control = 5'b01111; // ADDIW.
                        endcase
                    3'b001: o_alu_control = 5'b01100; // SLLIW or SLLW
                    3'b101: if ( i_func_7_5 ) o_alu_control = 5'b01110; // SRAIW or SRAW.
                            else              o_alu_control = 5'b01101; // SRLIW or SRLW. 
                    default: begin
                        o_alu_control   = 5'b00000;
                        o_illegal_instr = 1'b1;                        
                    end
                endcase 

            // CSR.
            3'b100: 
                case ( i_func_3[1:0] ) 
                    2'b01: o_alu_control = 5'b10000;
                    2'b10: o_alu_control = 5'b10001;
                    2'b11: o_alu_control = 5'b10010;
                    default: begin
                        o_alu_control   = '0;
                        o_illegal_instr = 1'b1; 
                    end
                endcase
            
            default: begin
                o_alu_control   = '0;
                o_illegal_instr = 1'b1;
            end

        endcase
    end

    
endmodule