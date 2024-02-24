/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------
// This is a Arithmetic Logic Unit (ALU).
// --------------------------------------

module alu 
// Parameters.
#(
    parameter DATA_WIDTH    = 64,
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
    enum logic [3:0] {
        ADD  = 4'b0000,
        SUB  = 4'b0001,
        AND  = 4'b0010,
        OR   = 4'b0011,
        XOR  = 4'b0100,
        SLL  = 4'b0101,
        SLT  = 4'b0110,
        SLTU = 4'b0111,
        SRL  = 4'b1000,
        SRA  = 4'b1001,
        SUBU = 4'b1010
    } t_operation;

    // Particular operation optputs.
    logic signed [ DATA_WIDTH - 1:0 ] s_add_out;
    logic signed [ DATA_WIDTH - 1:0 ] s_sub_out;
    logic signed [ DATA_WIDTH - 1:0 ] s_and_out;
    logic signed [ DATA_WIDTH - 1:0 ] s_or_out;
    logic signed [ DATA_WIDTH - 1:0 ] s_xor_out;
    logic signed [ DATA_WIDTH - 1:0 ] s_sll_out;
    logic signed [ DATA_WIDTH - 1:0 ] s_srl_out;
    logic signed [ DATA_WIDTH - 1:0 ] s_sra_out;
    logic signed [ DATA_WIDTH - 1:0 ] s_subu_out;

    // Flag signals. 
    logic s_carry_flag_add;
    logic s_carry_flag_sub;
    logic s_overflow;

    // Arithmetic & Logic Operations.
    assign {s_carry_flag_add, s_add_out}  = $signed(i_src_1) + $signed(i_src_2);
    assign {s_carry_flag_sub, s_sub_out}  = $signed(i_src_1) - $signed(i_src_2);

    assign s_and_out  = i_src_1 & i_src_2;
    assign s_or_out   = i_src_1 | i_src_2;
    assign s_xor_out  = i_src_1 ^ i_src_2;
    assign s_sll_out  = i_src_1 << i_src_2[4:0];
    assign s_subu_out = i_src_1 - i_src_2;
    assign s_srl_out  = i_src_1 >> i_src_2[4:0];
    assign s_sra_out  = $signed(i_src_1) >>> i_src_2[4:0];

    // Flags. 
    assign o_negative_flag = o_alu_result[DATA_WIDTH - 1];
    assign s_overflow      = (o_alu_result[DATA_WIDTH - 1] ^ i_src_1[DATA_WIDTH - 1]) & 
                             (i_src_2[DATA_WIDTH - 1] ~^ i_src_1[DATA_WIDTH - 1] ~^ alu_control[0]);

    // ------------
    // Output MUX.
    // ------------
    always_comb begin
        // Default values.
        o_alu_result    = 0;
        o_overflow_flag = 0;
        o_carry_flag    = 0;

        case ( alu_control )
            ADD : begin
                o_alu_result    = s_add_out;
                o_carry_flag    = s_carry_flag_add;
                o_overflow_flag = s_overflow;
            end 
            SUB : begin
                o_alu_result    = s_sub_out;
                o_carry_flag    = s_carry_flag_sub;
                o_overflow_flag = s_overflow;
            end 
            AND  : o_alu_result = s_and_out;
            OR   : o_alu_result = s_or_out;
            XOR  : o_alu_result = s_xor_out;
            SLL  : o_alu_result = s_sll_out;
            SLT  : o_alu_result = { { (DATA_WIDTH - 1) { 1'b0 } }, s_sub_out[DATA_WIDTH - 1] };
            SLTU : o_alu_result = { { (DATA_WIDTH - 1) { 1'b0 } }, s_subu_out[DATA_WIDTH - 1] };
            SRL  : o_alu_result = s_srl_out;
            SRA  : o_alu_result = s_sra_out;
            SUBU : o_alu_result = s_subu_out;
            default: begin
                o_alu_result    = 0;
                o_overflow_flag = 0;
                o_carry_flag    = 0;
            end 
        endcase
    end   
endmodule