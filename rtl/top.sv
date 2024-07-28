/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ---------------------------------------------------------------------------------------
// This is a top module in RISC-V architecture. It connects datapath units & control unit.
// ---------------------------------------------------------------------------------------

module ysyx_201979054_datapath
// Parameters. 
#(
    parameter REG_DATA_WIDTH   = 64,
              REG_ADDR_WIDTH   = 5,
              MEM_DATA_WIDTH   = 64,
              MEM_INSTR_WIDTH  = 32,
              MEM_ADDR_WIDTH   = 64,
              OUT_ADDR_WIDTH   = 32,
              BLOCK_DATA_WIDTH = 512


)
// Port declerations. 
(
    //Clock & Reset signals. 
    input  logic                            clk,
    input  logic                            arst,
    input  logic                            i_done_axi,   // NEEDS TO BE CONNECTED TO AXI 
    input  logic [ BLOCK_DATA_WIDTH - 1:0 ] i_data_read_axi,   // NEEDS TO BE CONNECTED TO AXI
    input  logic [ REG_DATA_WIDTH   - 1:0 ] i_data_non_cacheable,
    output logic [                    7:0 ] o_data_non_cacheable,
    output logic                            o_start_read_axi,  // NEEDS TO BE CONNECTED TO AXI
    output logic                            o_start_write_axi, // NEEDS TO BE CONNECTED TO AXI
    output logic                            o_start_read_axi_nc,
    output logic                            o_start_write_axi_nc,
    output logic [ OUT_ADDR_WIDTH   - 1:0 ] o_addr, // JUST FOR SIMULATION
    output logic [ OUT_ADDR_WIDTH   - 1:0 ] o_addr_non_cacheable,
    output logic [ BLOCK_DATA_WIDTH - 1:0 ] o_data_write_axi   // NEEDS TO BE CONNECTED TO AXI
);

    //------------------------
    // INTERNAL NETS.
    //------------------------

    // Instruction cache signals.
    logic s_instr_cache_we;
    logic s_instr_hit;
    logic [ MEM_INSTR_WIDTH - 1:0 ] s_instr_read;

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
    logic [ OUT_ADDR_WIDTH - 1:0 ] s_addr_axi;
    logic [ OUT_ADDR_WIDTH - 1:0 ] s_out_addr;
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
    logic [ MEM_ADDR_WIDTH  - 1:0 ] s_reg_pc_val;
    logic [ REG_DATA_WIDTH  - 1:0 ] s_reg_data_1;
    logic [ REG_DATA_WIDTH  - 1:0 ] s_reg_data_2;
    logic [ REG_DATA_WIDTH  - 1:0 ] s_reg_alu_result;
    logic [ MEM_DATA_WIDTH  - 1:0 ] s_reg_mem_data;
    logic                           s_reg_mem_we;

    // MUX signals.
    logic [ REG_DATA_WIDTH - 1:0 ] s_result;
    logic [ REG_DATA_WIDTH - 1:0 ] s_mem_data;

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
    logic                          s_mret_instr;

    // Cacheable mark.
    logic s_cacheable_flag;
    logic s_invalidate_instr;

    // CLINT Signals.
    logic s_clint_mmio_flag;
    logic s_clint_write_en;
    logic [ REG_DATA_WIDTH - 1:0 ] s_clint_read_data;

    // CLINT machine timer interrupt.
    logic s_interrupt;
    logic s_timer_int_call;
    logic s_software_int_call;
    logic s_timer_int;
    logic s_software_int;
    logic s_mie_mstatus;
    logic s_mtip_mip;
    logic s_msip_mip;
    logic s_mtie_mie;
    logic s_msie_mie;

    // Exception cause signals.
    logic s_instr_addr_ma;
    logic s_store_addr_ma;
    logic s_load_addr_ma;
    logic s_illegal_instr_load;

    // Fence WB signals.
    logic s_start_wb;
    logic s_done_wb;
    logic s_done_fence;




    //----------------------------------
    // Continious assignmnets. 
    //----------------------------------
    assign s_imm         = s_reg_instr[31:7 ];
    assign s_op          = s_reg_instr[ 6:0 ];
    assign s_func_3      = s_reg_instr[14:12];   
    assign s_reg_addr_1  = s_reg_instr[19:15];
    assign s_reg_addr_2  = s_reg_instr[24:20];
    assign s_reg_addr_3  = s_reg_instr[11:7 ];

    assign s_addr_offset = s_reg_mem_addr[2:0];
    
    assign s_csr_jamp_addr  = ( s_csr_read_data >> 2 ) << 2;
    assign s_csr_mcause     = { s_interrupt, 59'b0, s_mcause };
    assign s_timer_int      = s_mie_mstatus & s_mtip_mip & s_mtie_mie;
    assign s_software_int   = s_mie_mstatus & s_msip_mip & s_msie_mie;


    assign s_cacheable_flag  = ( s_reg_mem_addr >= 64'h3000_0000 );
    assign s_clint_mmio_flag = ( s_reg_mem_addr >= 64'h0200_0000 ) & ( s_reg_mem_addr <= 64'h0200_ffff );

    assign o_addr_non_cacheable = s_reg_mem_addr [ OUT_ADDR_WIDTH - 1:0 ];
    assign o_data_non_cacheable = s_reg_data_2 [ 7:0 ];

    assign s_mem_data = s_cacheable_flag ? s_reg_mem_data : ( s_clint_mmio_flag ? s_clint_read_data : i_data_non_cacheable);

    assign s_reg_pc_val = s_fetch_state ? s_reg_pc : s_reg_old_pc;


 


    //-----------------------------------
    // LOWER LEVEL MODULE INSTANTIATIONS.
    //-----------------------------------


    //---------------------------
    // Control Unit Instance.
    //---------------------------
    ysyx_201979054_control_unit CU (
        .clk                    ( clk                   ), 
        .arst                   ( arst                  ),
        .i_instr_22             ( s_reg_instr[22]       ),
        .i_instr_20             ( s_reg_instr[20]       ),
        .i_op                   ( s_op                  ),
        .i_func_3               ( s_func_3              ),
        .i_func7_6_3            ( s_reg_instr[31:28]    ),
        .i_func7_1_0            ( s_reg_instr[26:25]    ),
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
        .i_timer_int            ( s_timer_int           ),
        .i_software_int         ( s_software_int        ),
        .i_cacheable_flag       ( s_cacheable_flag      ),
        .i_clint_mmio_flag      ( s_clint_mmio_flag     ),
        .i_done_fence           ( s_done_fence          ),
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
        .o_start_read_nc        ( o_start_read_axi_nc   ),
        .o_start_write_nc       ( o_start_write_axi_nc  ),
        .o_invalidate_instr     ( s_invalidate_instr    ),
        .o_write_en_clint       ( s_clint_write_en      ),
        .o_mret_instr           ( s_mret_instr          ),
        .o_interrupt            ( s_interrupt           ),
        .o_done_wb              ( s_done_wb             ),
        .o_start_wb             ( s_start_wb            ),
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
    ysyx_201979054_register_file REG_FILE (
        .clk            ( clk               ),
        .write_en_3     ( s_reg_write_en    ),
        .arst           ( arst              ),
        .i_addr_1       ( s_reg_addr_1      ),
        .i_addr_2       ( s_reg_addr_2      ),
        .i_addr_3       ( s_reg_addr_3      ),
        .i_write_data_3 ( s_result          ),
        .o_read_data_1  ( s_reg_read_data_1 ),
        .o_read_data_2  ( s_reg_read_data_2 )
    );

    // Data Cache.
    ysyx_201979054_data_cache D_CACHE (
        .clk             ( clk                   ),
        .arst            ( arst                  ),
        .write_en        ( s_mem_write_en        ),
        .valid_update    ( s_data_valid_update   ),
        .lru_update      ( s_data_lru_update     ),
        .block_write_en  ( s_data_block_write_en ),
        .i_data_addr     ( s_reg_mem_addr        ),
        .i_data          ( s_reg_data_2          ),
        .i_data_block    ( i_data_read_axi       ),
        .i_store_type    ( s_func_3[1:0]         ),
        .i_addr_control  ( s_addr_control        ),
        .i_start_wb      ( s_start_wb            ),
        .i_done_wb       ( s_done_wb             ),
        .o_data          ( s_mem_read_data       ),
        .o_data_block    ( o_data_write_axi      ),
        .o_hit           ( s_data_hit            ),
        .o_dirty         ( s_data_dirty          ),
        .o_addr_axi      ( s_addr_axi            ),
        .o_done_fence    ( s_done_fence          ),
        .o_store_addr_ma ( s_store_addr_ma       )
    );

    // Instruction Cache.
    ysyx_201979054_instr_cache I_CACHE (
        .clk                ( clk                ),
        .write_en           ( s_instr_cache_we   ),
        .arst               ( arst               ),
        .i_instr_addr       ( s_reg_pc           ),
        .i_inst             ( i_data_read_axi    ),
        .i_invalidate_instr ( s_invalidate_instr ),
        .o_instr            ( s_instr_read       ),
        .o_hit              ( s_instr_hit        ),
        .o_instr_addr_ma    ( s_instr_addr_ma    )
    );


    // Control & Status Registers.
    ysyx_201979054_csr_file CSR0 (
        .clk                 ( clk                 ),
        .write_en_1          ( s_csr_we_1          ),
        .write_en_2          ( s_csr_we_2          ),
        .arst                ( arst                ),
        .i_read_addr         ( s_csr_read_addr     ),
        .i_write_addr_1      ( s_csr_write_addr_1  ),
        .i_write_addr_2      ( s_csr_write_addr_2  ),
        .i_write_data_1      ( s_csr_mcause        ),
        .i_write_data_2      ( s_result            ),
        .i_timer_int_call    ( s_timer_int_call    ),
        .i_software_int_call ( s_software_int_call ),
        .i_interrupt_jump    ( s_interrupt         ),
        .i_mret_instr        ( s_mret_instr        ),
        .o_read_data         ( s_csr_read_data     ),
        .o_mie_mstatus       ( s_mie_mstatus       ),
        .o_mtip_mip          ( s_mtip_mip          ),
        .o_msip_mip          ( s_msip_mip          ),
        .o_mtie_mie          ( s_mtie_mie          ),
        .o_msie_mie          ( s_msie_mie          )
    );


    // CLINT MMIO.
    ysyx_201979054_clint_mmio CLINT0 (
        .clk                 ( clk                     ),
        .arst                ( arst                    ),
        .write_en            ( s_clint_write_en        ),
        .i_addr              ( s_reg_mem_addr[ 14:13 ] ),
        .i_data              ( s_reg_data_2            ),
        .o_data              ( s_clint_read_data       ),
        .o_timer_int_call    ( s_timer_int_call        ),
        .o_software_int_call ( s_software_int_call     )
    );



    //------------------------------
    // ALU Instance. 
    //------------------------------
    ysyx_201979054_alu ALU (   
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
    ysyx_201979054_register_en # (.DATA_WIDTH (MEM_INSTR_WIDTH)) INSTR_REG (
        .clk          ( clk              ),
        .write_en     ( s_instr_write_en ),
        .arst         ( arst             ),
        .i_write_data ( s_instr_read     ),
        .o_read_data  ( s_reg_instr      )
    );

    // PC Register Instance.
    ysyx_201979054_register_pc # (.DATA_WIDTH (MEM_ADDR_WIDTH)) PC_REG (
        .clk          ( clk           ),
        .write_en     ( s_pc_write_en ),
        .arst         ( arst          ),
        .i_write_data ( s_result      ),
        .o_read_data  ( s_reg_pc      )
    ); 

    // Old PC Register Instance.
    ysyx_201979054_register_en # (.DATA_WIDTH (MEM_ADDR_WIDTH)) OLD_PC_REG (
        .clk          ( clk              ),
        .write_en     ( s_instr_write_en ),
        .arst         ( arst             ),
        .i_write_data ( s_reg_pc         ),
        .o_read_data  ( s_reg_old_pc     )
    );

    // MEM ADDR Register Instance.
    ysyx_201979054_register_en MEM_ADDR_REG (
        .clk          ( clk               ),
        .write_en     ( s_reg_mem_addr_we ),
        .arst         ( arst              ),
        .i_write_data ( s_result          ),
        .o_read_data  ( s_reg_mem_addr    )   
    ); 

    // CSR Register Instance.
    ysyx_201979054_register_en # (.DATA_WIDTH (REG_DATA_WIDTH)) CSR_REG (
        .clk          ( clk                 ),
        .write_en     ( s_csr_reg_we        ),
        .arst         ( arst                ),
        .i_write_data ( s_csr_read_data     ),
        .o_read_data  ( s_csr_read_data_reg )
    );  

    // Output addr Register Instance.
    ysyx_201979054_register #(.DATA_WIDTH (OUT_ADDR_WIDTH)) OUTADDR_REG (
        .clk          ( clk        ),
        .arst         ( arst       ),
        .i_write_data ( s_out_addr ),
        .o_read_data  ( o_addr     )
    ); 

    // R1 Register Instance.
    ysyx_201979054_register R1 (
        .clk          ( clk               ),
        .arst         ( arst              ),
        .i_write_data ( s_reg_read_data_1 ),
        .o_read_data  ( s_reg_data_1      )
    );

    // R2 Register Instance.
    ysyx_201979054_register R2 (
        .clk          ( clk               ),
        .arst         ( arst              ),
        .i_write_data ( s_reg_read_data_2 ),
        .o_read_data  ( s_reg_data_2      )
    );

    // ALU Result Register Instance.
    ysyx_201979054_register REG_ALU_RESULT (
        .clk          ( clk              ),
        .arst         ( arst             ),
        .i_write_data ( s_alu_result     ),
        .o_read_data  ( s_reg_alu_result )
    );

    // Memory Data Register. 
    ysyx_201979054_register_en REG_MEM_DATA (
        .clk          ( clk                ),
        .arst         ( arst               ),
        .write_en     ( s_reg_mem_we       ),
        .i_write_data ( s_mem_load_data    ),
        .o_read_data  ( s_reg_mem_data     )
    );



    //----------------------
    // MUX Instances.
    //----------------------

    // 4-to-1 ALU Source 1 MUX Instance.
    ysyx_201979054_mux4to1 ALU_MUX_1 (
        .control_signal ( s_alu_src_control_1 ),
        .i_mux_0        ( s_reg_pc            ),
        .i_mux_1        ( s_reg_old_pc        ),
        .i_mux_2        ( s_reg_data_1        ),
        .i_mux_3        ( s_imm_ext           ),
        .o_mux          ( s_alu_src_data_1    )
    );

    // 4-to-1 ALU Source 2 MUX Instance.
    ysyx_201979054_mux4to1 ALU_MUX_2 (
        .control_signal ( s_alu_src_control_2 ),
        .i_mux_0        ( s_reg_data_2        ),
        .i_mux_1        ( s_imm_ext           ),
        .i_mux_2        ( 64'b0100            ),
        .i_mux_3        ( s_csr_read_data     ),
        .o_mux          ( s_alu_src_data_2    )
    );

    // 8-to-1 Result Source MUX Instance.
    ysyx_201979054_mux8to1 RESULT_MUX (
        .control_signal ( s_result_src        ),
        .i_mux_0        ( s_reg_alu_result    ),
        .i_mux_1        ( s_mem_data          ), 
        .i_mux_2        ( s_alu_result        ),
        .i_mux_3        ( s_imm_ext           ),
        .i_mux_4        ( s_csr_read_data     ),
        .i_mux_5        ( s_csr_read_data_reg ),
        .i_mux_6        ( s_reg_pc_val        ),
        .i_mux_7        ( s_csr_jamp_addr     ),
        .o_mux          ( s_result            ) 
    );




    //---------------------------------------
    // Immiediate Extension Module Instance.
    //---------------------------------------
    ysyx_201979054_extend_imm I_EXT (
        .control_signal ( s_imm_src ),
        .i_imm          ( s_imm     ),
        .o_imm_ext      ( s_imm_ext )
    );

    //------------------------------
    // LOAD Instruction mux. 
    //------------------------------
    ysyx_201979054_load_mux LOAD_MUX (
        .i_func_3        ( s_func_3             ),
        .i_data          ( s_mem_read_data      ),
        .i_addr_offset   ( s_addr_offset        ),
        .o_data          ( s_mem_load_data      ),
        .o_load_addr_ma  ( s_load_addr_ma       ),
        .o_illegal_instr ( s_illegal_instr_load )
    );


    // FOR SIMULATION. 
    assign s_out_addr = s_fetch_state ? { s_reg_pc[ OUT_ADDR_WIDTH - 1:6 ], 6'b0 } : s_addr_axi; // For a cache line size of 512 bits. e.g. 16 words in 1 line.
    
endmodule