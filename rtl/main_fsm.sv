/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------------------------
// This is a main fsm unit that controls all the control signals based on instruction input. 
// -----------------------------------------------------------------------------------------

module main_fsm   
// Port decleration. 
(
    // Common clock & reset.
    input  logic       clk,
    input  logic       arstn,

    // Input interface. 
    input  logic [31:0] i_instr,
    input  logic [ 6:0] i_op,
    input  logic [ 2:0] i_func_3,
    input  logic        i_func_7_5, 
    input  logic        i_stall_instr,
    input  logic        i_stall_data,
    input  logic        i_instr_addr_ma,
    input logic         i_store_addr_ma,
    input logic         i_load_addr_ma,
    input logic         i_illegal_instr,

    // Output interface.
    output logic [ 1:0] o_alu_op,
    output logic [ 2:0] o_result_src,
    output logic [ 1:0] o_alu_src_1,
    output logic [ 1:0] o_alu_src_2,
    output logic        o_reg_write_en,
    output logic        o_pc_update,
    output logic        o_mem_write_en,
    output logic        o_instr_write_en, 
    output logic        o_start_i_cache,
    output logic        o_start_d_cache, 
    output logic        o_branch,
    output logic        o_addr_write_en,
    output logic        o_mem_reg_we,
    output logic        o_fetch_state,
    output logic        o_mepc_we,  
    output logic        o_mtvec_we,  
    output logic        o_mcause_we,
    output logic [ 3:0] o_mcause 
);  
    // State type.
    typedef enum logic [3:0] {
        FETCH      = 4'b0000,
        DECODE     = 4'b0001,
        MEMADDR    = 4'b0010,
        MEMREAD    = 4'b0011,
        MEMWB      = 4'b0100,
        MEMWRITE   = 4'b0101,
        EXECUTER   = 4'b0110,
        ALUWB      = 4'b0111,
        EXECUTEI   = 4'b1000,
        JAL        = 4'b1001,
        BRANCH     = 4'b1010,
        LOADI      = 4'b1011,
        MEMWRITE_D = 4'b1100,
        MEMREAD_D  = 4'b1101,
        CALL       = 4'b1110,
        STOP       = 4'b1111
    } t_state;

    // State variables. 
    t_state PS;
    t_state NS;

    // Instruction type.
    typedef enum logic [3:0] {
        I_Type      = 4'b0000,
        I_Type_ALU  = 4'b0001,
        I_Type_JALR = 4'b0010,
        I_Type_IW   = 4'b0011,
        S_Type      = 4'b0100,
        R_Type      = 4'b0101,
        R_Type_W    = 4'b0110,
        B_Type      = 4'b0111,
        J_Type      = 4'b1000,
        U_Type_ALU  = 4'b1001,
        U_Type_LOAD = 4'b1010,
        FENCE_Type  = 4'b1011,
        E_Type      = 4'b1100,
        ILLEGAL     = 4'b1101
    } t_instruction;

    // Instruction decoder signal. 
    t_instruction instr;

    // Instruction decoder. 
    always_comb begin
        case ( i_op )
            7'b0000011: instr = I_Type;
            7'b0010011: instr = I_Type_ALU;
            7'b1100111: instr = I_Type_JALR;
            7'b0011011: instr = I_Type_IW;
            7'b0100011: instr = S_Type;
            7'b0110011: instr = R_Type;
            7'b0111011: instr = R_Type_W;
            7'b1100011: instr = B_Type;
            7'b1101111: instr = J_Type;
            7'b0010111: instr = U_Type_ALU;
            7'b0110111: instr = U_Type_LOAD; 
            7'b0001111: instr = FENCE_Type;
            7'b1110011: instr = E_Type;
            default:    instr = ILLEGAL;
        endcase
    end


    // -----------------------------------
    // FSM 
    // -----------------------------------
    // FSM: Synchronization.
    always_ff @( posedge clk, negedge arstn ) begin
        if (!arstn) begin
            PS <= FETCH;
        end
        else PS <= NS;
    end

    // FSM: Next State logic.
    always_comb begin
        NS = PS;

        case ( PS )
            FETCH: begin
                if ( i_instr_addr_ma )    NS = CALL;
                else if ( i_stall_instr ) NS = PS;
                else                      NS = DECODE;
            end 

            DECODE: begin
                if ( i_illegal_instr ) NS = CALL;
                else begin
                    case ( instr )
                        I_Type     : NS = MEMADDR;
                        I_Type_ALU : NS = EXECUTEI;
                        I_Type_JALR: NS = MEMADDR;
                        I_Type_IW  : NS = EXECUTEI; 
                        S_Type     : NS = MEMADDR;
                        R_Type     : NS = EXECUTER; 
                        R_Type_W   : NS = EXECUTER;
                        B_Type     : NS = BRANCH;
                        J_Type     : NS = JAL;
                        U_Type_ALU : NS = ALUWB;
                        U_Type_LOAD: NS = LOADI; 
                        FENCE_Type : NS = FETCH; // NOT IMPLEMENTED.
                        E_Type     : NS = CALL; // PROBLEM: NOT FINISHED.
                        ILLEGAL    : NS = CALL;
                        default:     NS = CALL; 
                    endcase
                end
            end

            MEMADDR: begin
                case ( instr )
                    I_Type     : NS = MEMREAD;
                    S_Type     : NS = MEMWRITE; 
                    I_Type_JALR: NS = JAL;
                    default: NS = PS;
                endcase
            end

            MEMREAD: begin
                if ( i_load_addr_ma )       NS = CALL; 
                else if ( i_stall_data )    NS = PS;
                else                        NS = MEMWB;
            end

            MEMWB: NS = FETCH;

            MEMWRITE: begin
                if ( i_store_addr_ma )      NS = CALL;
                else if ( i_stall_data )    NS = PS;
                else                        NS = FETCH;
            end

            EXECUTER: NS = ALUWB;

            ALUWB: NS = FETCH;

            EXECUTEI: NS = ALUWB;

            JAL: NS = ALUWB;

            BRANCH: NS = FETCH;
            
            LOADI: NS = FETCH;

            CALL: NS = STOP;

            STOP: NS = FETCH;

            default: NS = PS;
        endcase
    end


    // FSM: Ouput logic.
    always_comb begin

        // Default values. 
        o_alu_op         = 2'b00;
        o_result_src     = 3'b000;
        o_alu_src_1      = 2'b00;
        o_alu_src_2      = 2'b00;
        o_reg_write_en   = 1'b0;
        o_pc_update      = 1'b0;
        o_mem_write_en   = 1'b0;
        o_instr_write_en = 1'b0;
        o_addr_write_en  = 1'b0;
        o_start_i_cache  = 1'b0;
        o_branch         = 1'b0;
        o_start_d_cache  = 1'b0;
        o_mem_reg_we     = 1'b0;
        o_fetch_state    = 1'b0;
        o_mepc_we        = 1'b0;
        o_mtvec_we       = 1'b0;
        o_mcause_we      = 1'b0;
        o_mcause         = 4'b0000;

        case ( PS )
            FETCH: begin
                if ( i_stall_instr ) begin
                    o_instr_write_en   = 1'b0;
                    o_pc_update        = 1'b0;
                end
                else begin
                    o_instr_write_en   = 1'b1;
                    o_addr_write_en    = 1'b1;
                    o_pc_update        = 1'b1;      
                end
                
                o_start_i_cache    = 1'b1;
                o_fetch_state      = 1'b1; 
                o_alu_src_1        = 2'b00;
                o_alu_src_2        = 2'b10;
                o_result_src       = 3'b010;
                o_alu_op           = 2'b00;
            end 

            DECODE: begin
                o_alu_src_1 = 2'b01;
                o_alu_src_2 = 2'b01;
                o_alu_op    = 2'b00;
            end

            MEMADDR: begin
                o_alu_src_1    = 2'b10;
                o_alu_src_2    = 2'b01;
                o_alu_op       = 2'b00;
            end

            MEMREAD: begin
                o_result_src    = 3'b000;
                o_start_d_cache = 1'b1;
                o_alu_op        = 2'b00;

                if ( i_stall_data ) begin
                    o_addr_write_en = 1'b1;
                    o_mem_reg_we    = 1'b0;
                    o_alu_src_1     = 2'b10;
                    o_alu_src_2     = 2'b01;
                end
                else begin
                    o_addr_write_en = 1'b0;
                    o_mem_reg_we    = 1'b1;
                    o_alu_src_1 = 2'b10;
                    o_alu_src_2 = 2'b01;     
                end
            end

            MEMWB: begin
                o_result_src   = 3'b001;
                o_reg_write_en = 1'b1;
            end

            MEMWRITE: begin
                if ( i_stall_data ) begin
                    o_mem_write_en  = 1'b0;
                    o_addr_write_en = 1'b1;
                    o_alu_src_1     = 2'b10;
                    o_alu_src_2     = 2'b01;
                    o_mem_reg_we    = 1'b0;
                end
                else begin
                    o_mem_write_en  = 1'b1;
                    o_addr_write_en = 1'b0;
                    o_mem_reg_we    = 1'b1;
                    o_alu_src_1 = 2'b10;
                    o_alu_src_2 = 2'b01;      
                end
                
                o_start_d_cache = 1'b1;
                o_result_src    = 3'b000;
                o_alu_op    = 2'b00;
                
            end

            EXECUTER: begin
                o_alu_src_1 = 2'b10;
                o_alu_src_2 = 2'b00;
                case ( instr )
                    R_Type  : o_alu_op = 2'b10;
                    R_Type_W: o_alu_op = 2'b11;
                    default:  o_alu_op = 2'b10;
                endcase
            end

            ALUWB: begin
                o_result_src   = 3'b000;
                o_reg_write_en = 1'b1;
            end

            EXECUTEI: begin
                o_alu_src_1 = 2'b10;
                o_alu_src_2 = 2'b01;
                case ( instr )
                    I_Type_ALU: o_alu_op = 2'b10;
                    I_Type_IW : o_alu_op = 2'b11;
                    default:    o_alu_op = 2'b10;
                endcase
            end

            JAL: begin
                o_alu_src_1  = 2'b01;
                o_alu_src_2  = 2'b10;
                o_alu_op     = 2'b00;
                o_result_src = 3'b000;
                o_pc_update  = 1'b1;
            end

            BRANCH: begin
                o_alu_src_1  = 2'b10;
                o_alu_src_2  = 2'b00;
                o_alu_op     = 2'b01;
                o_result_src = 3'b000;
                o_branch     = 1'b1;
            end

            LOADI: begin
                o_result_src   = 3'b011;
                o_reg_write_en = 1'b1; 
            end

            // FOR SIMULATION ONLY..
            // BREAK: begin
            //     $display("Breakpoint");
            //     $stop();
            // end

            CALL: begin
                o_mepc_we   = 1'b1;
                o_mcause_we = 1'b1;
                if ( (instr == ILLEGAL) | i_illegal_instr ) o_mcause = 4'd2; // Illegal instruction.

                //  An instruction-address-misaligned exception is generated on a taken branch or unconditional jump
                // if the target address is not four-byte aligned. This exception is reported on the branch or jump
                // instruction, not on the target instruction.
                else if ( i_instr_addr_ma ) o_mcause = 4'd0; // Instruction address misaligned.
                else if ( instr == E_Type ) begin
                    if ( ~i_instr[20] ) o_mcause = 4'd11; // Env call from M-mode.
                    else                o_mcause = 4'd3; // Env breakpoint.
                end
                else if ( i_load_addr_ma  ) o_mcause = 4'd4; // Load address misaligned.
                else if ( i_store_addr_ma ) o_mcause = 4'd6; // Store address misaligned.
                else o_mcause = 4'd10; // Reserved.

                o_result_src = 3'b100; // s_mtvec_out.
                o_pc_update  = 1'b1;
            end

            STOP: $stop(); // FOR SIMULATION ONLY


            default: begin
                o_alu_op         = 2'b00;
                o_result_src     = 3'b000;
                o_alu_src_1      = 2'b00;
                o_alu_src_2      = 2'b00;
                o_reg_write_en   = 1'b0;
                o_pc_update      = 1'b0;
                o_mem_write_en   = 1'b0;
                o_instr_write_en = 1'b0;
                o_addr_write_en  = 1'b0;
                o_start_i_cache  = 1'b0;
                o_branch         = 1'b0;
                o_start_d_cache  = 1'b0;
                o_mem_reg_we     = 1'b0;
                o_fetch_state    = 1'b0;
                o_mepc_we        = 1'b0;
                o_mtvec_we       = 1'b0;
                o_mcause_we      = 1'b0;
                o_mcause         = 4'b0000;
            end
        endcase
    end
    
endmodule