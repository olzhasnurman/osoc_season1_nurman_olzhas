/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------
// This is a Arithmetic Logic Unit (ALU).
// --------------------------------------

module alu 
// Parameters.
#(
    parameter DATA_WIDTH    = 64,
              WORD_WIDTH    = 32,
              CONTROL_WIDTH = 5   
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
    output logic                         o_carry_flag,
    output logic                         o_slt_flag,
    output logic                         o_sltu_flag
);

    // ---------------
    // Oprations.
    // ---------------
    enum logic [4:0] {
        ADD   = 5'b00000,
        SUB   = 5'b00001,
        AND   = 5'b00010,
        OR    = 5'b00011,
        XOR   = 5'b00100,
        SLL   = 5'b00101,
        SLT   = 5'b00110,
        SLTU  = 5'b00111,
        SRL   = 5'b01000,
        SRA   = 5'b01001,

        SLLI  = 5'b01010,
        SRLI  = 5'b01011,
        SRAI  = 5'b01100,

        ADDW  = 5'b01101,
        SUBW  = 5'b01110,
        SLLW  = 5'b01111,
        SRLW  = 5'b10000,
        SRAW  = 5'b10001,

        ADDIW = 5'b10010
    } t_operation;



    //-------------------------
    // Internal nets.
    //-------------------------
    
    // ALU regular & immediate operation outputs.
    logic [ DATA_WIDTH - 1:0 ] s_add_out;
    logic [ DATA_WIDTH - 1:0 ] s_sub_out;
    logic [ DATA_WIDTH - 1:0 ] s_and_out;
    logic [ DATA_WIDTH - 1:0 ] s_or_out;
    logic [ DATA_WIDTH - 1:0 ] s_xor_out;
    logic [ DATA_WIDTH - 1:0 ] s_sll_out;
    logic [ DATA_WIDTH - 1:0 ] s_srl_out;
    logic [ DATA_WIDTH - 1:0 ] s_sra_out;
    logic [ DATA_WIDTH - 1:0 ] s_slli_out;
    logic [ DATA_WIDTH - 1:0 ] s_srli_out;
    logic [ DATA_WIDTH - 1:0 ] s_srai_out;

    logic less_than;
    logic less_than_u;

    // ALU word operation outputs.
    logic [ WORD_WIDTH - 1:0 ] s_addw_out;
    logic [ WORD_WIDTH - 1:0 ] s_subw_out;
    logic [ WORD_WIDTH - 1:0 ] s_srlw_out;
    logic [ WORD_WIDTH - 1:0 ] s_sraw_out;

    // Flag signals. 
    logic s_carry_flag_add;
    logic s_carry_flag_sub;
    logic s_overflow;

    // NOTE: REVIEW SLT & SLTU INSTRUCTIONS. ALSO FLAGS.

    //---------------------------------
    // Arithmetic & Logic Operations.
    //---------------------------------
    
    // ALU regular & immediate operations. 
    assign {s_carry_flag_add, s_add_out}  = i_src_1 + i_src_2;
    assign {s_carry_flag_sub, s_sub_out}  = $signed(i_src_1) - $signed(i_src_2);
    assign s_and_out   = i_src_1 & i_src_2;
    assign s_or_out    = i_src_1 | i_src_2;
    assign s_xor_out   = i_src_1 ^ i_src_2;
    assign s_sll_out   = i_src_1 << i_src_2[4:0];
    assign s_srl_out   = i_src_1 >> i_src_2[4:0];
    assign s_sra_out   = $signed(i_src_1) >>> i_src_2[4:0];
    assign s_slli_out   = i_src_1 << i_src_2[5:0];
    assign s_srli_out   = i_src_1 >> i_src_2[5:0];
    assign s_srai_out   = $signed(i_src_1) >>> i_src_2[5:0];

    assign less_than   = $signed(i_src_1) < $signed(i_src_2);
    assign less_than_u = i_src_1 < i_src_2;

    // ALU word operations.
    assign s_addw_out = i_src_1[31:0] + i_src_2[31:0];
    assign s_subw_out = i_src_1[31:0] - i_src_2[31:0]; 
    assign s_srlw_out = i_src_1[31:0] >> i_src_2[4:0];
    assign s_sraw_out = $signed(i_src_1[31:0]) >>> i_src_2[4:0];


    // Flags. 
    assign o_negative_flag = o_alu_result[DATA_WIDTH - 1];
    assign s_overflow      = (o_alu_result[DATA_WIDTH - 1] ^ i_src_1[DATA_WIDTH - 1]) & 
                             (i_src_2[DATA_WIDTH - 1] ~^ i_src_1[DATA_WIDTH - 1] ~^ alu_control[0]);
    
    assign o_slt_flag  = less_than;
    assign o_sltu_flag = less_than_u;

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
            SLT  : o_alu_result = { { (DATA_WIDTH - 1) { 1'b0 } }, less_than };
            SLTU : o_alu_result = { { (DATA_WIDTH - 1) { 1'b0 } }, less_than_u };
            SRL  : o_alu_result = s_srl_out;
            SRA  : o_alu_result = s_sra_out;

            SLLI : o_alu_result = s_slli_out;
            SRLI : o_alu_result = s_srli_out;
            SRAI : o_alu_result = s_srai_out;

            ADDW : o_alu_result = { { 32{s_addw_out[31]} }, s_addw_out };
            SUBW : o_alu_result = { { 32{s_subw_out[31]} }, s_subw_out };
            SLLW : o_alu_result = { { 32{s_sll_out[31]} }, s_sll_out[31:0] };
            SRLW : o_alu_result = { { 32{s_srlw_out[31]} }, s_srlw_out };
            SRAW : o_alu_result = { { 32{s_sraw_out[31]} }, s_sraw_out };

            ADDIW: o_alu_result = { { 32{s_add_out[31]} }, s_add_out[31:0] };

            default: begin
                o_alu_result    = 0;
                o_overflow_flag = 0;
                o_carry_flag    = 0;
            end 
        endcase

    end   
endmodule