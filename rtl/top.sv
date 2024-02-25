/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------------------------------
// This is a top module in RISC-V architecture. It connects datapath units & control unit.
// ---------------------------------------------------------------------------------------

module top
// Parameters. 
#(
    parameter REG_DATA_WIDTH  = 64,
              REG_ADDR_WIDTH  = 5,
              MEM_DATA_WIDTH  = 64,
              MEM_INSTR_WIDTH = 32,
              MEM_ADDR_WIDTH  = 64


)
// Port declerations. 
(
    //Clock & Reset signals. 
    input logic clk,
    input logic arstn
);

    //------------------------
    // INTERNAL NETS.
    //------------------------

    // ALU flags.
    logic s_zero_flag;
    logic s_overflow_flag;
    logic s_negative_flag;
    logic s_carry_flag;

    // Control unit signals. 
    logic [6:0] s_op;
    logic [2:0] s_func_3;
    logic       s_func_7_5;
    logic [3:0] s_alu_control;
    logic [1:0] s_result_src;
    logic [1:0] s_alu_src_control_1;
    logic [1:0] s_alu_src_control_2;
    logic [2:0] s_imm_src;
    logic       s_mem_addr_src;
    logic       s_reg_write_en;
    logic       s_pc_write_en;
    logic       s_mem_write_en;
    logic       s_instr_write_en;

    // Memory signals.
    logic [ MEM_ADDR_WIDTH  - 1:0 ] s_mem_addr;
    logic [ MEM_DATA_WIDTH  - 1:0 ] s_mem_write_data;
    logic [ MEM_DATA_WIDTH  - 1:0 ] s_mem_read_data;
    logic [ MEM_INSTR_WIDTH - 1:0 ] s_mem_read_instr;

    // Register file signals. 
    logic [ REG_ADDR_WIDTH - 1:0 ] s_reg_addr_1;
    logic [ REG_ADDR_WIDTH - 1:0 ] s_reg_addr_2;
    logic [ REG_ADDR_WIDTH - 1:0 ] s_reg_addr_3;
    logic [ REG_DATA_WIDTH - 1:0 ] s_reg_read_data_1;
    logic [ REG_DATA_WIDTH - 1:0 ] s_reg_read_data_2;
    logic [ REG_DATA_WIDTH - 1:0 ] s_reg_write_data_3;

    // ALU signals.
    logic [ REG_DATA_WIDTH - 1:0 ] s_alu_src_data_1;
    logic [ REG_DATA_WIDTH - 1:0 ] s_alu_src_data_2;
    logic [ REG_DATA_WIDTH - 1:0 ] s_alu_result;

    // Registered signals. 
    logic [ MEM_INSTR_WIDTH - 1:0 ] s_reg_instr;
    logic [ MEM_ADDR_WIDTH  - 1:0 ] s_reg_pc;
    logic [ MEM_ADDR_WIDTH  - 1:0 ] s_reg_old_pc;
    logic [ REG_DATA_WIDTH  - 1:0 ] s_reg_data_1;
    logic [ REG_DATA_WIDTH  - 1:0 ] s_reg_data_2;
    logic [ REG_DATA_WIDTH  - 1:0 ] s_reg_alu_result;
    logic [ MEM_DATA_WIDTH  - 1:0 ] s_reg_mem_data;

    // MUX signals.
    logic [ REG_DATA_WIDTH - 1:0 ] s_result;

    // Immediate extend unit signals. 
    logic [                  24:0 ] s_imm;
    logic [ REG_DATA_WIDTH  - 1:0 ] s_imm_ext;

    // LOAD instruction mux unit signal.
    logic [ MEM_DATA_WIDTH - 1:0] s_mem_load_data;



    //----------------------------------
    // Continious assignmnets. 
    //----------------------------------
    assign s_imm        = s_reg_instr[31:7];
    assign s_op         = s_reg_instr[6:0];
    assign s_func_3     = s_reg_instr[14:12];
    assign s_func_7_5   = s_reg_instr[30]; 
    assign s_reg_addr_1 = s_reg_instr[19:15];
    assign s_reg_addr_2 = s_reg_instr[24:20];
    assign s_reg_addr_3 = s_reg_instr[11:7];
 
    assign s_reg_write_data_3 = s_result;
    assign s_mem_write_data   = s_reg_data_2[MEM_DATA_WIDTH - 1:0];



    //-----------------------------------
    // LOWER LEVEL MODULE INSTANTIATIONS.
    //-----------------------------------

    //---------------------------
    // Control Unit Instance.
    //---------------------------
    control_unit CU  (
        .clk              ( clk                 ), 
        .arstn            ( arstn               ),
        .i_op             ( s_op                ),
        .i_func_3         ( s_func_3            ),
        .i_func_7_5       ( s_func_7_5          ),
        .i_zero_flag      ( s_zero_flag         ),
        .i_negative_flag  (s_negative_flag      ),
        .o_alu_control    ( s_alu_control       ),
        .o_result_src     ( s_result_src        ),
        .o_alu_src_1      ( s_alu_src_control_1 ),
        .o_alu_src_2      ( s_alu_src_control_2 ),
        .o_imm_src        ( s_imm_src           ),
        .o_mem_addr_src   ( s_mem_addr_src      ),
        .o_reg_write_en   ( s_reg_write_en      ),
        .o_pc_write       ( s_pc_write_en       ),
        .o_mem_write_en   ( s_mem_write_en      ),
        .o_instr_write_en ( s_instr_write_en    )
    );



    //--------------------------------
    // Data Storage Unit Instances. 
    //--------------------------------

    // Register File Instance.
    register_file REG_FILE (
        .clk            ( clk                ),
        .write_en_3     ( s_reg_write_en     ),
        .i_addr_1       ( s_reg_addr_1       ),
        .i_addr_2       ( s_reg_addr_2       ),
        .i_addr_3       ( s_reg_addr_3       ),
        .i_write_data_3 ( s_reg_write_data_3 ),
        .o_read_data_1  ( s_reg_read_data_1  ),
        .o_read_data_2  ( s_reg_read_data_2  )
    );

    // Memory Unit Instance. 
    memory MEM (
        .clk          ( clk              ),
        .write_en     ( s_mem_write_en   ),
        .i_store_type ( s_func_3[1:0]    ),
        .i_addr       ( s_mem_addr       ),
        .i_write_data ( s_mem_write_data ),
        .o_read_data  ( s_mem_read_data  ),
        .o_read_instr ( s_mem_read_instr )
    );



    //------------------------------
    // ALU Instance. 
    //------------------------------
    alu ALU (   
        .alu_control     ( s_alu_control    ),
        .i_src_1         ( s_alu_src_data_1 ),
        .i_src_2         ( s_alu_src_data_2 ),
        .o_alu_result    ( s_alu_result     ),
        .o_overflow_flag ( s_overflow_flag  ),
        .o_zero_flag     ( s_zero_flag      ),
        .o_negative_flag ( s_negative_flag  ),
        .o_carry_flag    ( s_carry_flag     )
    );



    //-----------------------------------------
    // Nonarchitectural Register Instances. 
    //-----------------------------------------

    // Instruction Register Instance. 
    register_en # (.DATA_WIDTH (MEM_INSTR_WIDTH)) INSTR_REG (
        .clk          ( clk              ),
        .write_en     ( s_instr_write_en ),
        .arstn        ( arstn            ),
        .i_write_data ( s_mem_read_instr ),
        .o_read_data  ( s_reg_instr      )
    );

    // PC Register Instance.
    register_en # (.DATA_WIDTH (MEM_ADDR_WIDTH)) PC_REG (
        .clk          ( clk           ),
        .write_en     ( s_pc_write_en ),
        .arstn        ( arstn         ),
        .i_write_data ( s_result      ),
        .o_read_data  ( s_reg_pc      )
    ); 

    // Old PC Register Instance.
    register_en # (.DATA_WIDTH (MEM_ADDR_WIDTH)) OLD_PC_REG (
        .clk          ( clk              ),
        .write_en     ( s_instr_write_en ),
        .arstn        ( arstn            ),
        .i_write_data ( s_reg_pc         ),
        .o_read_data  ( s_reg_old_pc     )
    ); 

    // R1 Register Instance.
    register R1 (
        .clk          ( clk               ),
        .arstn        ( arstn             ),
        .i_write_data ( s_reg_read_data_1 ),
        .o_read_data  ( s_reg_data_1      )
    );

    // R2 Register Instance.
    register R2 (
        .clk          ( clk               ),
        .arstn        ( arstn             ),
        .i_write_data ( s_reg_read_data_2 ),
        .o_read_data  ( s_reg_data_2      )
    );

    // ALU Result Register Instance.
    register REG_ALU_RESULT (
        .clk          ( clk              ),
        .arstn        ( arstn            ),
        .i_write_data ( s_alu_result     ),
        .o_read_data  ( s_reg_alu_result )
    );

    // Memory Data Register. 
    register # (.DATA_WIDTH (MEM_DATA_WIDTH)) MEM_DATA (
        .clk          ( clk             ),
        .arstn        ( arstn           ),
        .i_write_data ( s_mem_read_data ),
        .o_read_data  ( s_reg_mem_data  )
    );



    //----------------------
    // MUX Instances.
    //----------------------

    // 3-to-1 ALU Source 1 MUX Instance.
    mux3to1 ALU_MUX_1 (
        .control_signal ( s_alu_src_control_1 ),
        .i_mux_1        ( s_reg_pc            ),
        .i_mux_2        ( s_reg_old_pc        ),
        .i_mux_3        ( s_reg_data_1        ),
        .o_mux          ( s_alu_src_data_1    )
    );

    // 3-to-1 ALU Source 2 MUX Instance.
    mux3to1 ALU_MUX_2 (
        .control_signal ( s_alu_src_control_2 ),
        .i_mux_1        ( s_reg_data_2        ),
        .i_mux_2        ( s_imm_ext           ),
        .i_mux_3        ( 64'b0100            ),
        .o_mux          ( s_alu_src_data_2    )
    );

    // 3-to-1 Result Source MUX Instance.
    mux3to1 RESULT_MUX (
        .control_signal ( s_result_src     ),
        .i_mux_1        ( s_reg_alu_result ),
        .i_mux_2        ( s_mem_load_data  ), 
        .i_mux_3        ( s_alu_result     ),
        .o_mux          ( s_result         )
    );

    // 2-to-1 Memory Address Source MUX Instance.
    mux2to1 MEM_ADDR_MUX (
        .control_signal  ( s_mem_addr_src ),
        .i_pc_next       ( s_reg_pc       ),
        .i_result        ( s_result       ),
        .o_addr          ( s_mem_addr     )
    );


    //---------------------------------------
    // Immiediate Extension Module Instance.
    //---------------------------------------
    extend_imm I_EXT (
        .control_signal ( s_imm_src ),
        .i_imm          ( s_imm     ),
        .o_imm_ext      ( s_imm_ext )
    );

    //------------------------------
    // LOAD Instruction mux. 
    //------------------------------
    load_mux LOAD_MUX (
        .i_func_3 ( s_func_3        ),
        .i_data   ( s_reg_mem_data  ),
        .o_data   ( s_mem_load_data )
    );

    
endmodule