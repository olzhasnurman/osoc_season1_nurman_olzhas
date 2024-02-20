/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------
// This is a Arithmetic Logic Unit (ALU).
// --------------------------------------

// OPERATIONS.
// __________________________
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

module alu 
// Parameters.
#(
    parameter DATA_WIDTH    = 32,
              CONTROL_WIDTH = 4   
) 
// Port decleration.
(
    // ALU control signal.
    input  logic [ CONTROL_WIDTH - 1:0 ] alu_control,

    // Input interface.
    input  logic [ DATA_WIDTH    - 1:0 ] i_src_1,
    input  logic [ DATA_WIDTH    - 1:0 ] i_src_2,

    // Output interface.
    output logic [ DATA_WIDTH    - 1:0 ] o_alu_result,
    output logic                         o_overflow_flag,
    output logic                         o_zero_flag,
    output logic                         o_negative_flag,
    output logic                         o_carry_flag
);

    // ---------------
    // Internal nets.
    // ---------------

    // Particular operation optputs.
    logic signed [ DATA_WIDTH    - 1:0 ] s_add_out;
    logic signed [ DATA_WIDTH    - 1:0 ] s_sub_out;
    logic signed [ DATA_WIDTH    - 1:0 ] s_and_out;
    logic signed [ DATA_WIDTH    - 1:0 ] s_or_out;
    logic signed [ DATA_WIDTH    - 1:0 ] s_xor_out;
    logic signed [ DATA_WIDTH    - 1:0 ] s_sll_out;
    logic signed [ DATA_WIDTH    - 1:0 ] s_slt_out;
    logic        [ DATA_WIDTH    - 1:0 ] s_sltu_out;
    logic signed [ DATA_WIDTH    - 1:0 ] s_srl_out;
    logic signed [ DATA_WIDTH    - 1:0 ] s_sra_out;

    // Arithmetic & Logic Operations.
    assign {s_carry_flag_add, s_add_out}  = $signed(i_src_1) + $signed(i_src_2);
    assign {s_carrY_flag_sub, s_sub_out}  = $signed(i_src_1) - $signed(i_src_2);

    assign s_and_out  = i_src_1 & i_src_2;
    assign s_or_out   = i_src_1 | i_src_2;
    assign s_xor_out  = i_src_1 ^ i_src_2;
    assign s_sll_out  = i_src_1 << i_src_2[4:0];
    // NOT FINISHED.
    assign s_slt_out  = i_src_1 + i_src_2; 
    assign s_sltu_out = i_src_1 + i_src_2;
    assign s_srl_out  = i_src_1 + i_src_2;
    assign s_sra_out  = i_src_1 + i_src_2;

    // Flags. 
    assign o_negative_flag = o_alu_result[DATA_WIDTH - 1];
    assign s_overflow      = (o_alu_result[DATA_WIDTH - 1] ^ i_src_1[DATA_WIDTH - 1]) & 
                             (i_src_2[DATA_WIDTH - 1] ~^ i_src_1[DATA_WIDTH - 1] ~^ alu_control[0])

    // ------------
    // Output MUX.
    // ------------
    always_comb begin
        // Default values.
        o_alu_result    = 0;
        o_overflow_flag = 0;
        o_carry_flag    = 0;

        case (alu_control)
            4'b0000: begin
                o_alu_result    = s_add_out;
                o_carry_flag    = s_carry_flag_add;
                o_overflow_flag = s_overflow;
            end 
            4'b0001: begin
                o_alu_result    = s_sub_out;
                o_carry_flag    = s_carry_flag_sub;
                o_overflow_flag = s_overflow;
            end 
            4'b0010: o_alu_result = s_and_out;
            4'b0011: o_alu_result = s_or_out;
            4'b0100: o_alu_result = s_xor_out;
            4'b0101: o_alu_result = s_sll_out;
            4'b0110: o_alu_result = s_slt_out;
            4'b0111: o_alu_result = s_sltu_out;
            4'b1000: o_alu_result = s_srl_out;
            4'b1001: o_alu_result = s_sra_out;
            default: begin
                o_alu_result    = 0;
                o_overflow_flag = 0;
                o_carry_flag    = 0;
            end 
        endcase
    end   
endmodule