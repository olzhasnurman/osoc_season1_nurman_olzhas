/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------------------------
// This is a main control unit that instantiates control fsm, alu and instr decoders to 
//  controls all the control signals based on instruction input. 
// -------------------------------------------------------------------------------------

module control_unit   
// Port decleration. 
(
    // Common clock & reset.
    input  logic       clk,
    input  logic       arstn,

    // Input interface. 
    input  logic [6:0] i_op,
    input  logic [2:0] i_func_3,
    input  logic       i_func_7_5, 
    input  logic       i_zero_flag,

    // Output interface.
    output logic [3:0] o_alu_control,
    output logic [1:0] o_result_src,
    output logic [1:0] o_alu_src_1,
    output logic [1:0] o_alu_src_2,
    output logic [1:0] o_imm_src,
    output logic       o_mem_addr_src,
    output logic       o_reg_write_en,
    output logic       o_pc_write,
    output logic       o_mem_write_en,
    output logic       o_instr_write_en
); 

    logic       s_branch;
    logic       s_pc_update;
    logic [1:0] s_alu_op;

    // --------------------Modulle Instantiations------------------
    // Main fsm module instance. 
    main_fsm M_FSM (
        .clk              ( clk              ),
        .arstn            ( arstn            ),
        .i_op             ( i_op             ),
        .i_func_3         ( i_func_3         ),
        .i_func_7_5       ( i_func_7_5       ), 
        .o_alu_op         ( s_alu_op         ),
        .o_result_src     ( o_result_src     ),
        .o_alu_src_1      ( o_alu_src_1      ),
        .o_alu_src_2      ( o_alu_src_2      ),
        .o_mem_addr_src   ( o_mem_addr_src   ),
        .o_reg_write_en   ( o_reg_write_en   ),
        .o_pc_update      ( s_pc_update      ),
        .o_mem_write_en   ( o_mem_write_en   ),
        .o_instr_write_en ( o_instr_write_en ),
        .o_branch         ( s_branch         ) 
    );


    // ALU decoder module.
    alu_decoder ALU_DECODER (
        .i_alu_op      ( s_alu_op      ),
        .i_func_3      ( i_func_3      ),
        .i_func_7_5    ( i_func_7_5    ),
        .i_op_5        ( i_op[5]       ),
        .o_alu_control ( o_alu_control )
    );

    // Instruction decoder. 
    instr_decoder INSTR_DECODER (
        .i_op      ( i_op      ),
        .o_imm_src ( o_imm_src )
    );

endmodule