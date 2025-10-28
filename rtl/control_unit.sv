
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
    input  logic       arst,

    // Input interface.
    input  logic [ 2:0] i_instr_22_20,
    input  logic [ 6:0] i_op,
    input  logic [ 2:0] i_func_3,
    input  logic [ 2:0] i_func7_6_4,
    input  logic [ 1:0] i_func7_1_0,
    input  logic        i_pred_0,
    input  logic        i_zero_flag,
    input  logic        i_slt_flag,
    input  logic        i_sltu_flag,
    input  logic        i_instr_hit,
    input  logic        i_read_last_axi,
    input  logic        i_data_hit,
    input  logic        i_data_dirty,
    input  logic        i_b_resp_axi,
    input  logic        i_instr_addr_ma,
    input logic         i_store_addr_ma,
    input logic         i_load_addr_ma,
    input logic         i_illegal_instr_load,
    input logic         i_timer_int,
    input logic         i_software_int,
    input  logic        i_cacheable_flag,
    input  logic        i_clint_mmio_flag,
    input  logic        i_done_fence,

    // Output interface.
    output logic [ 4:0] o_alu_control,
    output logic [ 2:0] o_result_src,
    output logic [ 1:0] o_alu_src_1,
    output logic [ 1:0] o_alu_src_2,
    output logic [ 2:0] o_imm_src,
    output logic        o_reg_write_en,
    output logic        o_pc_write,
    output logic        o_instr_write_en,
    output logic        o_mem_write_en,
    output logic        o_instr_cache_write_en,
    output logic        o_start_read_axi,
    output logic        o_block_write_en,
    output logic        o_data_valid_update,
    output logic        o_data_lru_update,
    output logic        o_start_write_axi,
    output logic        o_addr_control,
    output logic        o_mem_reg_we,
    output logic        o_fetch_state,
    output logic        o_reg_mem_addr_we,
    output logic        o_start_read_nc,
    output logic        o_start_write_nc,
    output logic        o_invalidate_instr,
    output logic        o_write_en_clint,
    output logic        o_mret_instr,
    output logic        o_interrupt,
    output logic        o_done_wb,
    output logic        o_start_wb,
    output logic        o_csr_writable,
    output logic [ 3:0] o_mcause,
    output logic        o_csr_we_1,
    output logic        o_csr_we_2,
    output logic        o_csr_reg_we,
    output logic [ 2:0] o_csr_write_addr_1,
    output logic [ 2:0] o_csr_write_addr_2,
    output logic [ 2:0] o_csr_read_addr

);

    // Main FSM.
    logic       s_instr_branch;
    logic       s_branch;
    logic       s_pc_update;
    logic [2:0] s_alu_op;

    // Instruction cache.
    logic s_stall_instr;
    logic s_start_instr_cache;
    logic s_start_read_instr;

    // Data cache.
    logic s_stall_data;
    logic s_start_read_data;
    logic s_start_data_cache;

    // Illegalal instruction flag.
    logic s_illegal_instr_alu;
    logic s_illegal_instr_alu_ff;

    logic s_icache_in_idle;

    logic s_start_wb;

    assign o_start_wb = s_start_wb;

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
        .clk                  ( clk                    ),
        .arst                 ( arst                   ),
        .i_instr_22_20        ( i_instr_22_20          ),
        .i_op                 ( i_op                   ),
        .i_func_3             ( i_func_3               ),
        .i_func_7_4           ( i_func7_6_4[0]         ),
        .i_func_7_0           ( i_func7_1_0[0]         ),
        .i_func_7_1           ( i_func7_1_0[1]         ),
        .i_func_7_6           ( i_func7_6_4[2]         ),
        .i_pred_0             ( i_pred_0               ),
        .i_stall_instr        ( s_stall_instr          ),
        .i_stall_data         ( s_stall_data           ),
        .i_instr_addr_ma      ( i_instr_addr_ma        ),
        .i_store_addr_ma      ( i_store_addr_ma        ),
        .i_load_addr_ma       ( i_load_addr_ma         ),
        .i_illegal_instr_load ( i_illegal_instr_load   ),
        .i_illegal_instr_alu  ( s_illegal_instr_alu_ff ),
        .i_timer_int          ( i_timer_int            ),
        .i_software_int       ( i_software_int         ),
        .i_cacheable_flag     ( i_cacheable_flag       ),
        .i_done_axi           ( i_read_last_axi        ),
        .i_clint_mmio_flag    ( i_clint_mmio_flag      ),
        .i_icache_idle        ( s_icache_in_idle       ),
        .i_done_fence         ( i_done_fence           ),
        .o_alu_op             ( s_alu_op               ),
        .o_result_src         ( o_result_src           ),
        .o_alu_src_1          ( o_alu_src_1            ),
        .o_alu_src_2          ( o_alu_src_2            ),
        .o_reg_write_en       ( o_reg_write_en         ),
        .o_pc_update          ( s_pc_update            ),
        .o_mem_write_en       ( o_mem_write_en         ),
        .o_instr_write_en     ( o_instr_write_en       ),
        .o_start_i_cache      ( s_start_instr_cache    ),
        .o_start_d_cache      ( s_start_data_cache     ),
        .o_branch             ( s_instr_branch         ),
        .o_mem_reg_we         ( o_mem_reg_we           ),
        .o_fetch_state        ( o_fetch_state          ),
        .o_reg_mem_addr_we    ( o_reg_mem_addr_we      ),
        .o_start_read_nc      ( o_start_read_nc        ),
        .o_start_write_nc     ( o_start_write_nc       ),
        .o_invalidate_instr   ( o_invalidate_instr     ),
        .o_write_en_clint     ( o_write_en_clint       ),
        .o_mret_instr         ( o_mret_instr           ),
        .o_interrupt          ( o_interrupt            ),
        .o_start_wb           ( s_start_wb             ),
        .o_csr_writable       ( o_csr_writable         ),
        .o_mcause             ( o_mcause               ),
        .o_csr_we_1           ( o_csr_we_1             ),
        .o_csr_we_2           ( o_csr_we_2             ),
        .o_csr_reg_we         ( o_csr_reg_we           ),
        .o_csr_write_addr_1   ( o_csr_write_addr_1     ),
        .o_csr_write_addr_2   ( o_csr_write_addr_2     ),
        .o_csr_read_addr      ( o_csr_read_addr        )
    );

    // Instruction cache FSM.
    instr_cache_fsm I_C_FSM (
        .clk              ( clk                    ),
        .arst             ( arst                   ),
        .i_start_check    ( s_start_instr_cache    ),
        .i_hit            ( i_instr_hit            ),
        .i_r_last         ( i_read_last_axi        ),
        .o_stall          ( s_stall_instr          ),
        .o_instr_write_en ( o_instr_cache_write_en ),
        .o_start_read     ( s_start_read_instr     ),
        .o_in_idle        ( s_icache_in_idle       )
    );

    // Data cache FSM.
    data_cache_fsm D_C_FSM (
        .clk                   ( clk                 ),
        .arst                  ( arst                ),
        .i_start_check         ( s_start_data_cache  ),
        .i_hit                 ( i_data_hit          ),
        .i_dirty               ( i_data_dirty        ),
        .i_r_last              ( i_read_last_axi     ),
        .i_b_resp              ( i_b_resp_axi        ),
        .i_start_wb            ( s_start_wb          ),
        .o_stall               ( s_stall_data        ),
        .o_data_block_write_en ( o_block_write_en    ),
        .o_valid_update        ( o_data_valid_update ),
        .o_lru_update          ( o_data_lru_update   ),
        .o_start_write         ( o_start_write_axi   ),
        .o_start_read          ( s_start_read_data   ),
        .o_addr_control        ( o_addr_control      ),
        .o_done_wb             ( o_done_wb           )
    );


    // ALU decoder module.
    alu_decoder ALU_DECODER (
        .i_alu_op        ( s_alu_op            ),
        .i_func_3        ( i_func_3            ),
        .i_func_7_5      ( i_func7_6_4[1]      ),
        .i_op_5          ( i_op[5]             ),
        .o_alu_control   ( o_alu_control       ),
        .o_illegal_instr ( s_illegal_instr_alu )
    );

    // Instruction decoder.
    instr_decoder INSTR_DECODER (
        .i_op      ( i_op      ),
        .o_imm_src ( o_imm_src )
    );

    // Illegal instruction flag flip-flop.
    register # (.DATA_WIDTH (1) ) II_ALU_FF (
        .clk          ( clk                    ),
        .arst         ( arst                   ),
        .i_write_data ( s_illegal_instr_alu    ),
        .o_read_data  ( s_illegal_instr_alu_ff )
    );

endmodule
