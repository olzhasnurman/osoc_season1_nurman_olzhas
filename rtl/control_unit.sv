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
    input  logic       i_negative_flag,
    input  logic       i_slt_flag,
    input  logic       i_sltu_flag,
    input  logic       i_instr_hit,
    input  logic       i_read_last_axi,
    input  logic       i_data_hit,
    input  logic       i_data_dirty,
    input  logic       i_b_resp_axi,

    // Output interface.
    output logic [4:0] o_alu_control,
    output logic [1:0] o_result_src,
    output logic [1:0] o_alu_src_1,
    output logic [1:0] o_alu_src_2,
    output logic [2:0] o_imm_src,
    output logic       o_mem_addr_src,
    output logic       o_reg_write_en,
    output logic       o_pc_write,
    output logic       o_instr_write_en,
    output logic       o_mem_write_en,
    output logic       o_instr_cache_write_en,
    output logic       o_start_read_axi,
    output logic       o_block_write_en,
    output logic       o_data_valid_update,
    output logic       o_data_lru_update,
    output logic       o_start_write_axi

); 

    // Main FSM.
    logic       s_instr_branch;
    logic       s_branch;
    logic       s_pc_update;
    logic [1:0] s_alu_op;
    
    // Instruction cache.
    logic s_stall_instr;
    logic s_start_instr_cache;
    logic s_start_read_instr;

    // Data cache.
    logic s_stall_data;
    logic s_start_read_data;
    logic s_start_data_cache;
    logic s_write_state;

    assign o_pc_write       = s_pc_update | ( s_branch );

    assign o_start_read_axi = s_start_read_data | s_start_read_instr;

    // Branch type decoder. 
    always_comb begin : BRANCH_TYPE
        case ( i_func_3 )
            3'b000: s_branch = s_instr_branch & i_zero_flag;        // BEQ instruction.
            3'b001: s_branch = s_instr_branch & (~i_zero_flag);     // BNE instruction.
            3'b100: s_branch = s_instr_branch & i_slt_flag;    // BLT instruction.
            3'b101: s_branch = s_instr_branch & (~i_slt_flag); // BGE instruction.
            3'b110: s_branch = s_instr_branch & i_sltu_flag;    // BLTU instruction. i_negative_flag calculation is different in ALU.
            3'b111: s_branch = s_instr_branch & (~i_sltu_flag); // BGEU instruction. i_negative_flag calculation is different in ALU.

            default: s_branch = 1'b0;
        endcase
    end

    //-------------------------------------
    // Modulle Instantiations.
    //-------------------------------------

    // Main FSM module instance. 
    main_fsm M_FSM (
        .clk              ( clk                 ),
        .arstn            ( arstn               ),
        .i_op             ( i_op                ),
        .i_func_3         ( i_func_3            ),
        .i_func_7_5       ( i_func_7_5          ), 
        .i_stall_instr    ( s_stall_instr       ),
        .i_stall_data     ( s_stall_data        ),
        .o_alu_op         ( s_alu_op            ),
        .o_result_src     ( o_result_src        ),
        .o_alu_src_1      ( o_alu_src_1         ),
        .o_alu_src_2      ( o_alu_src_2         ),
        .o_mem_addr_src   ( o_mem_addr_src      ),
        .o_reg_write_en   ( o_reg_write_en      ),
        .o_pc_update      ( s_pc_update         ),
        .o_mem_write_en   ( o_mem_write_en      ),
        .o_instr_write_en ( o_instr_write_en    ),
        .o_start_i_cache  ( s_start_instr_cache ),
        .o_start_d_cache  ( s_start_data_cache  ),
        .o_write_state    ( s_write_state       ),
        .o_branch         ( s_instr_branch      ) 
    );

    // Instruction cache FSM.
    instr_cache_fsm I_C_FSM (
        .clk              ( clk                    ),
        .arstn            ( arstn                  ),
        .i_start_check    ( s_start_instr_cache    ),
        .i_hit            ( i_instr_hit            ),
        .i_r_last         ( i_read_last_axi        ),
        .o_stall          ( s_stall_instr          ),
        .o_instr_write_en ( o_instr_cache_write_en ),
        .o_start_read     ( s_start_read_instr     )
    );

    // Data cache FSM.
    data_cache_fsm D_C_FSM (
        .clk                   ( clk                 ),
        .arstn                 ( arstn               ),
        .i_start_check         ( s_start_data_cache  ),
        .i_write               ( s_write_state       ),
        .i_hit                 ( i_data_hit          ),
        .i_dirty               ( i_data_dirty        ),
        .i_r_last              ( i_read_last_axi     ),
        .i_b_resp              ( i_b_resp_axi        ),
        .o_stall               ( s_stall_data        ),
        .o_data_block_write_en ( o_block_write_en    ),
        .o_valid_update        ( o_data_valid_update ),
        .o_lru_update          ( o_data_lru_update   ),
        .o_start_write         ( o_start_write_axi   ),
        .o_start_read          ( s_start_read_data   )
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