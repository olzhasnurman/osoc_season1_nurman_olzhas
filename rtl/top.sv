/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------------------------------
// This is a top module in RISC-V architecture. It connects datapath units & control unit.
// ---------------------------------------------------------------------------------------

module top
// Parameters. 
#(
    parameter REG_DATA_WIDTH   = 64,
              REG_ADDR_WIDTH   = 5,
              MEM_DATA_WIDTH   = 64,
              MEM_INSTR_WIDTH  = 32,
              MEM_ADDR_WIDTH   = 64,
              BLOCK_DATA_WIDTH = 512


)
// Port declerations. 
(
    //Clock & Reset signals. 
    input  logic                            clk,
    input  logic                            i_arstn,
    input  logic                            i_done_axi,   // NEEDS TO BE CONNECTED TO AXI 
    input  logic [ BLOCK_DATA_WIDTH - 1:0 ] i_data_read_axi,   // NEEDS TO BE CONNECTED TO AXI
    // input  logic [ REG_DATA_WIDTH   - 1:0 ] i_data_non_cachable,
    output logic                            o_start_read_axi,  // NEEDS TO BE CONNECTED TO AXI
    output logic                            o_start_write_axi, // NEEDS TO BE CONNECTED TO AXI
    output logic [ MEM_ADDR_WIDTH   - 1:0 ] o_addr, // JUST FOR SIMULATION
    // output logic [ REG_DATA_WIDTH   - 1:0 ] o_data_non_cacheable
    output logic [ BLOCK_DATA_WIDTH - 1:0 ] o_data_write_axi   // NEEDS TO BE CONNECTED TO AXI
);

    //------------------------
    // INTERNAL NETS.
    //------------------------

    // Reset signal.
    logic arstn;

    // Instruction cache signals.
    logic s_instr_cache_we;
    logic s_instr_hit;
    logic [31:0] s_instr_read;

    // Data cache signals.
    logic       s_data_hit;
    logic       s_data_dirty;
    logic       s_data_block_write_en;
    logic       s_data_valid_update;
    logic       s_data_lru_update;
    logic       s_addr_control;
    logic [2:0] s_addr_offset;

    // ALU flags.
    logic s_zero_flag;
    logic s_slt_flag;
    logic s_sltu_flag;

    // Control unit signals. 
    logic [6:0] s_op;
    logic [2:0] s_func_3;
    logic [6:0] s_func_7;
    logic [4:0] s_alu_control;
    logic [2:0] s_result_src;
    logic [1:0] s_alu_src_control_1;
    logic [1:0] s_alu_src_control_2;
    logic [2:0] s_imm_src;
    logic       s_reg_write_en;
    logic       s_pc_write_en;
    logic       s_mem_write_en;
    logic       s_instr_write_en;
    logic       s_fetch_state;

    // Memory signals.
    logic [ MEM_DATA_WIDTH  - 1:0 ] s_mem_read_data;
    logic [ MEM_ADDR_WIDTH  - 1:0 ] s_addr_axi;
    logic [ MEM_ADDR_WIDTH  - 1:0 ] s_reg_mem_addr;
    logic                           s_reg_mem_addr_we;

    // Register file signals. 
    logic [ REG_ADDR_WIDTH - 1:0 ] s_reg_addr_1;
    logic [ REG_ADDR_WIDTH - 1:0 ] s_reg_addr_2;
    logic [ REG_ADDR_WIDTH - 1:0 ] s_reg_addr_3;
    logic [ REG_DATA_WIDTH - 1:0 ] s_reg_read_data_1;
    logic [ REG_DATA_WIDTH - 1:0 ] s_reg_read_data_2;

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
    logic                           s_reg_mem_we;

    // MUX signals.
    logic [ REG_DATA_WIDTH - 1:0 ] s_result;

    // Immediate extend unit signals. 
    logic [                  24:0 ] s_imm;
    logic [ REG_DATA_WIDTH  - 1:0 ] s_imm_ext;

    // LOAD instruction mux unit signal.
    logic [ MEM_DATA_WIDTH - 1:0] s_mem_load_data;

    // CSR signals.
    logic [                  2:0 ] s_csr_write_addr_1;
    logic [                  2:0 ] s_csr_write_addr_2;
    logic                          s_csr_we_1;
    logic                          s_csr_we_2;
    logic                          s_csr_reg_we;
    logic [                  2:0 ] s_csr_read_addr;
    logic [ REG_DATA_WIDTH - 1:0 ] s_csr_read_data;
    logic [ REG_DATA_WIDTH - 1:0 ] s_csr_read_data_reg;
    logic [ REG_DATA_WIDTH - 1:0 ] s_csr_jamp_addr;
    logic [ REG_DATA_WIDTH - 1:0 ] s_csr_mcause;
    logic [                  3:0 ] s_mcause;

    // Cacheable mark.
    logic s_cacheable;

    // CLINT machine timer interrupt.
    logic s_interrupt;
    logic s_timer_int_call;
    logic s_timer_int;
    logic s_mie_mstatus;
    logic s_mtip_mip;
    logic s_mtie_mie;

    // Exception cause signals.
    logic s_instr_addr_ma;
    logic s_store_addr_ma;
    logic s_load_addr_ma;
    logic s_illegal_instr_load;

    logic s_a0_reg_lsb; // FOR SIMULATION ONLY.



    //----------------------------------
    // Continious assignmnets. 
    //----------------------------------
    assign s_imm         = s_reg_instr[31:7];
    assign s_op          = s_reg_instr[6:0];
    assign s_func_3      = s_reg_instr[14:12];   
    assign s_func_7      = s_reg_instr[31:25]; 
    assign s_reg_addr_1  = s_reg_instr[19:15];
    assign s_reg_addr_2  = s_reg_instr[24:20];
    assign s_reg_addr_3  = s_reg_instr[11:7];

    assign s_addr_offset = s_reg_mem_addr[2:0];
    
    assign s_csr_jamp_addr  = s_csr_read_data >> 2;
    assign s_csr_mcause     = { s_interrupt, 59'b0, s_mcause };
    assign s_timer_int      = s_mie_mstatus & s_mtip_mip & s_mtie_mie;


    assign s_cacheable = ( s_reg_mem_addr >= 64'h3000_0000 );


 


    //-----------------------------------
    // LOWER LEVEL MODULE INSTANTIATIONS.
    //-----------------------------------

    //------------------------------
    // Reset Synchronizer Instance.
    //------------------------------
    reset_sync RST_SYNC (
        .clk   ( clk     ),
        .arstn ( i_arstn ),
        .rstn  ( arstn   )
    );


    //---------------------------
    // Control Unit Instance.
    //---------------------------
    control_unit CU (
        .clk                    ( clk                   ), 
        .arstn                  ( arstn                 ),
        .i_instr_22             ( s_reg_instr[22]       ),
        .i_instr_20             ( s_reg_instr[20]       ),
        .i_op                   ( s_op                  ),
        .i_func_3               ( s_func_3              ),
        .i_func_7               ( s_func_7              ),
        .i_zero_flag            ( s_zero_flag           ),
        .i_slt_flag             ( s_slt_flag            ),
        .i_sltu_flag            ( s_sltu_flag           ),
        .i_instr_hit            ( s_instr_hit           ),
        .i_read_last_axi        ( i_done_axi            ),
        .i_data_hit             ( s_data_hit            ),
        .i_data_dirty           ( s_data_dirty          ),
        .i_b_resp_axi           ( i_done_axi            ),
        .i_instr_addr_ma        ( s_instr_addr_ma       ),
        .i_store_addr_ma        ( s_store_addr_ma       ),
        .i_load_addr_ma         ( s_load_addr_ma        ),
        .i_illegal_instr_load   ( s_illegal_instr_load  ),
        .i_a0_reg_lsb           ( s_a0_reg_lsb          ), // FOR SIMULATION ONLY.
        .i_timer_int            ( s_timer_int           ),
        .o_alu_control          ( s_alu_control         ),
        .o_result_src           ( s_result_src          ),
        .o_alu_src_1            ( s_alu_src_control_1   ),
        .o_alu_src_2            ( s_alu_src_control_2   ),
        .o_imm_src              ( s_imm_src             ),
        .o_reg_write_en         ( s_reg_write_en        ),
        .o_pc_write             ( s_pc_write_en         ),
        .o_instr_write_en       ( s_instr_write_en      ),
        .o_mem_write_en         ( s_mem_write_en        ),
        .o_instr_cache_write_en ( s_instr_cache_we      ),
        .o_start_read_axi       ( o_start_read_axi      ),
        .o_block_write_en       ( s_data_block_write_en ),
        .o_data_valid_update    ( s_data_valid_update   ),
        .o_data_lru_update      ( s_data_lru_update     ),
        .o_start_write_axi      ( o_start_write_axi     ),
        .o_addr_control         ( s_addr_control        ),
        .o_mem_reg_we           ( s_reg_mem_we          ),
        .o_fetch_state          ( s_fetch_state         ),
        .o_reg_mem_addr_we      ( s_reg_mem_addr_we     ),
        .o_interrupt            ( s_interrupt           ),
        .o_mcause               ( s_mcause              ),
        .o_csr_we_1             ( s_csr_we_1            ),
        .o_csr_we_2             ( s_csr_we_2            ),
        .o_csr_reg_we           ( s_csr_reg_we          ),
        .o_csr_write_addr_1     ( s_csr_write_addr_1    ),
        .o_csr_write_addr_2     ( s_csr_write_addr_2    ),
        .o_csr_read_addr        ( s_csr_read_addr       )
    );



    //--------------------------------
    // Data Storage Unit Instances. 
    //--------------------------------

    // Register File Instance.
    register_file REG_FILE (
        .clk            ( clk               ),
        .write_en_3     ( s_reg_write_en    ),
        .arstn          ( arstn             ),
        .i_addr_1       ( s_reg_addr_1      ),
        .i_addr_2       ( s_reg_addr_2      ),
        .i_addr_3       ( s_reg_addr_3      ),
        .i_write_data_3 ( s_result          ),
        .o_read_data_1  ( s_reg_read_data_1 ),
        .o_a0_reg_lsb   ( s_a0_reg_lsb      ), // FOR SIMULATION ONLY.
        .o_read_data_2  ( s_reg_read_data_2 )
    );

    // Data Cache.
    data_cache D_CACHE (
        .clk             ( clk                   ),
        .arstn           ( arstn                 ),
        .write_en        ( s_mem_write_en        ),
        .valid_update    ( s_data_valid_update   ),
        .lru_update      ( s_data_lru_update     ),
        .block_write_en  ( s_data_block_write_en ),
        .i_data_addr     ( s_reg_mem_addr        ),
        .i_data          ( s_reg_data_2          ),
        .i_data_block    ( i_data_read_axi       ),
        .i_store_type    ( s_func_3[1:0]         ),
        .i_addr_control  ( s_addr_control        ),
        .o_data          ( s_mem_read_data       ),
        .o_data_block    ( o_data_write_axi      ),
        .o_hit           ( s_data_hit            ),
        .o_dirty         ( s_data_dirty          ),
        .o_addr_axi      ( s_addr_axi            ),
        .o_store_addr_ma ( s_store_addr_ma       )
    );

    // Instruction Cache.
    instr_cache I_CACHE (
        .clk             ( clk              ),
        .write_en        ( s_instr_cache_we ),
        .arstn           ( arstn            ),
        .i_instr_addr    ( s_reg_pc         ),
        .i_inst          ( i_data_read_axi  ),
        .o_instr         ( s_instr_read     ),
        .o_hit           ( s_instr_hit      ),
        .o_instr_addr_ma ( s_instr_addr_ma  )
    );


    // Control & Status Registers.
    csr_file CSR0 (
        .clk              ( clk                ),
        .write_en_1       ( s_csr_we_1         ),
        .write_en_2       ( s_csr_we_2         ),
        .arstn            ( arstn              ),
        .i_read_addr      ( s_csr_read_addr    ),
        .i_write_addr_1   ( s_csr_write_addr_1 ),
        .i_write_addr_2   ( s_csr_write_addr_2 ),
        .i_write_data_1   ( s_csr_mcause       ),
        .i_write_data_2   ( s_result           ),
        .i_timer_int_call ( s_timer_int_call   ),
        .i_timer_int_jump ( s_interrupt        ),
        .o_read_data      ( s_csr_read_data    ),
        .o_mie_mstatus    ( s_mie_mstatus      ),
        .o_mtip_mip       ( s_mtip_mip         ),
        .o_mtie_mie       ( s_mtie_mie         )
    );


    // CLINT MMIO.
    clint_mmio CLINT0 (
        .clk              ( clk              ),
        .arstn            ( arstn            ),
        .write_en_1       ( 1'b0             ),
        .write_en_2       ( 1'b0             ),
        .i_data           ( '0               ),
        .o_timer_int_call ( s_timer_int_call )
    );



    //------------------------------
    // ALU Instance. 
    //------------------------------
    alu ALU (   
        .alu_control     ( s_alu_control    ),
        .i_src_1         ( s_alu_src_data_1 ),
        .i_src_2         ( s_alu_src_data_2 ),
        .o_alu_result    ( s_alu_result     ),
        .o_zero_flag     ( s_zero_flag      ),
        .o_slt_flag      ( s_slt_flag       ),
        .o_sltu_flag     ( s_sltu_flag      )
    );



    //-----------------------------------------
    // Nonarchitectural Register Instances. 
    //-----------------------------------------

    // Instruction Register Instance. 
    register_en # (.DATA_WIDTH (MEM_INSTR_WIDTH)) INSTR_REG (
        .clk          ( clk              ),
        .write_en     ( s_instr_write_en ),
        .arstn        ( arstn            ),
        .i_write_data ( s_instr_read     ),
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

    // MEM ADDR Register Instance.
    register_en MEM_ADDR_REG (
        .clk          ( clk               ),
        .write_en     ( s_reg_mem_addr_we ),
        .arstn        ( arstn             ),
        .i_write_data ( s_result          ),
        .o_read_data  ( s_reg_mem_addr    )   
    ); 

    // CSR Register Instance.
    register_en # (.DATA_WIDTH (REG_DATA_WIDTH)) CSR_REG (
        .clk          ( clk                 ),
        .write_en     ( s_csr_reg_we        ),
        .arstn        ( arstn               ),
        .i_write_data ( s_csr_read_data     ),
        .o_read_data  ( s_csr_read_data_reg )
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
    register_en MEM_DATA (
        .clk          ( clk                ),
        .arstn        ( arstn              ),
        .write_en     ( s_reg_mem_we       ),
        .i_write_data ( s_mem_load_data    ),
        .o_read_data  ( s_reg_mem_data     )
    );



    //----------------------
    // MUX Instances.
    //----------------------

    // 4-to-1 ALU Source 1 MUX Instance.
    mux4to1 ALU_MUX_1 (
        .control_signal ( s_alu_src_control_1 ),
        .i_mux_0        ( s_reg_pc            ),
        .i_mux_1        ( s_reg_old_pc        ),
        .i_mux_2        ( s_reg_data_1        ),
        .i_mux_3        ( s_imm_ext           ),
        .o_mux          ( s_alu_src_data_1    )
    );

    // 4-to-1 ALU Source 2 MUX Instance.
    mux4to1 ALU_MUX_2 (
        .control_signal ( s_alu_src_control_2 ),
        .i_mux_0        ( s_reg_data_2        ),
        .i_mux_1        ( s_imm_ext           ),
        .i_mux_2        ( 64'b0100            ),
        .i_mux_3        ( s_csr_read_data     ),
        .o_mux          ( s_alu_src_data_2    )
    );

    // 8-to-1 Result Source MUX Instance.
    mux8to1 RESULT_MUX (
        .control_signal ( s_result_src        ),
        .i_mux_0        ( s_reg_alu_result    ),
        .i_mux_1        ( s_reg_mem_data      ), 
        .i_mux_2        ( s_alu_result        ),
        .i_mux_3        ( s_imm_ext           ),
        .i_mux_4        ( s_csr_read_data     ),
        .i_mux_5        ( s_csr_read_data_reg ),
        .i_mux_6        ( s_reg_old_pc        ),
        .i_mux_7        ( s_csr_jamp_addr     ),
        .o_mux          ( s_result            ) 
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
        .i_func_3        ( s_func_3             ),
        .i_data          ( s_mem_read_data      ),
        .i_addr_offset   ( s_addr_offset        ),
        .o_data          ( s_mem_load_data      ),
        .o_load_addr_ma  ( s_load_addr_ma       ),
        .o_illegal_instr ( s_illegal_instr_load )
    );


    // FOR SIMULATION. 
    assign o_addr = s_fetch_state ? { s_reg_pc[MEM_ADDR_WIDTH - 1:6 ], 6'b0 } : s_addr_axi; // For a cache line size of 512 bits. e.g. 16 words in 1 line.

    
endmodule