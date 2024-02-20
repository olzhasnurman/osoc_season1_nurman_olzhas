/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// ALU decoder is a module designed to output alu control signal based on
// op[5], alu_op, func_3, func_7[5] signals. 
// -----------------------------------------------------------------------

module alu_decoder 
// Paramaters.
#(
    parameters
) 
// Port delerations. 
(
    // Input interface.
    input  logic [6:0] i_alu_op,
    input  logic [2:0] i_func_3,
    input  logic       i_func_7_5,
    input  logic       i_op_5,

    // Output interface. 
    output logic [3:0] o_alu_control
);

    logic [1:0] s_op_func_7;

    assign s_op_func_7 = {i_op_5, i_func_7_5}

// | ALU Control | Function |
// |_____________|__________|
// | 0000        | ADD      |
// | 0001        | SUB      |
// | 0010        | AND      |
// | 0011        | OR       |
// | 0100        | XOR      |
// | 0101        | SLL      |
// | 0110        | SLT      |
// | 0111        | SLTU     |
// | 1000        | SRL      |
// | 1001        | SRA      |
//___________________________

    // ALU decoder logic.
    always_comb begin 
        if ( i_alu_op[1] ) begin
            case (func_3)
                3'b000: if (s_op_func_7 == 2'b11) begin
                            o_alu_control = 4'b0001; // sub instruciton.
                        end 
                        else o_alu_control = 4'b0000; // add instruciton.

                3'b001: o_alu_control = 4'b0101; // sll instruction.

                3'b010: o_alu_control = 4'b0110; // slt instruction. 

                3'b011: o_alu_control = 4'b0111; // sltu instruction.

                3'b100: o_alu_control = 4'b0100; // xor instruction.

                3'b101: if (s_op_func_7 == 2'b11) begin
                            o_alu_control = 4'b1001; // sra instruction.
                        end 
                        else o_alu_control = 4'b1000; // srl instruction.  

                3'b110: o_alu_control = 4'b0011; // or instruction.

                3'b111: o_alu_control = 4'b0010; // and instruction.
                default: o_alu_control = 4'b0000; // add instrucito for default. 
            endcase
        end
        else 
            if ( i_alu_op[0] ) begin
                o_alu_control = 4'b0001; // SUB for B type instructions: beq, bne, bge and etc.
            end
            else o_alu_control = 4'b0000; // ADD for I type instruction: lw, sw.
    end

    
endmodule