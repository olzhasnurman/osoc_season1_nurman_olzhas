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
    input  logic [6:0] i_op,
    input  logic [2:0] i_func_3,
    input  logic       i_func_7_5, 

    // Output interface.
    output logic [1:0] o_alu_op,
    output logic [1:0] o_result_src,
    output logic [1:0] o_alu_src_1,
    output logic [1:0] o_alu_src_2,
    output logic       o_mem_addr_src,
    output logic       o_reg_write_en,
    output logic       o_pc_update,
    output logic       o_mem_write_en,
    output logic       o_instr_write_en,
    output logic       o_branch
);  
    // State type.
    typedef enum logic [3:0] {
        FETCH    = 4'b0000,
        DECODE   = 4'b0001,
        MEMADDR  = 4'b0010,
        MEMREAD  = 4'b0011,
        MEMWB    = 4'b0100,
        MEMWRITE = 4'b0101,
        EXECUTER = 4'b0110,
        ALUWB    = 4'b0111,
        EXECUTEI = 4'b1000,
        JAL      = 4'b1001,
        BEQ      = 4'b1010
    } t_state;

    // State variables. 
    t_state PS;
    t_state NS;

    // Instruction type.
    typedef enum logic [3:0] {
        I_Type      = 4'b0000,
        I_Type_ALU  = 4'b0001,
        I_Type_JALR = 4'b0010,
        S_Type      = 4'b0011,
        R_Type      = 4'b0100,
        B_Type      = 4'b0101,
        J_Type      = 4'b0110,
        U_Type_ALU  = 4'b0111,
        U_Type_LOAD = 4'b1000
    } t_instruction;

    // Instruction decoder signal. 
    t_instruction instr;

    // Instruction decoder. 
    always_comb begin
        case ( i_op )
            7'b0000011: instr = I_Type;
            7'b0010011: instr = I_Type_ALU;
            7'b1100111: instr = I_Type_JALR;
            7'b0100011: instr = S_Type;
            7'b0110011: instr = R_Type;
            7'b1100011: instr = B_Type;
            7'b1101111: instr = J_Type;
            7'b0110111: instr = U_Type_ALU;
            7'b0010111: instr = U_Type_LOAD; 
            default:    instr = I_Type;
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
                NS = DECODE;
            end 

            DECODE: begin
                case ( instr )
                    I_Type: NS = MEMADDR;
                    I_Type_ALU: NS = EXECUTEI;
                    I_Type_JALR: NS = FETCH; // NOT FINISHED.
                    S_Type: NS = MEMADDR;
                    R_Type: NS = EXECUTER; 
                    B_Type: NS = BEQ;
                    J_Type: NS = JAL;
                    U_Type_ALU: NS = FETCH; // NOT FINISHED.
                    U_Type_LOAD: NS = FETCH; // NOT FINSHED. 

                    default: NS = PS; 
                endcase
            end

            MEMADDR: begin
                case ( instr )
                    I_Type: NS = MEMREAD;
                    S_Type: NS = MEMWRITE; 
                    default: NS = PS;
                endcase
            end

            MEMREAD: NS = MEMWB;

            MEMWB: NS = FETCH;

            MEMWRITE: NS = FETCH;

            EXECUTER: NS = ALUWB;

            ALUWB: NS = FETCH;

            EXECUTEI: NS = ALUWB;

            JAL: NS = ALUWB;

            BEQ:NS = FETCH;

            default: NS = PS;
        endcase
    end


    // FSM: Ouput logic.
    always_comb begin
        // Default values. 
        o_alu_op         = 2'b00;
        o_result_src     = 2'b00;
        o_alu_src_1      = 2'b00;
        o_alu_src_2      = 2'b00;
        o_mem_addr_src   = 1'b0;
        o_reg_write_en   = 1'b0;
        o_pc_update      = 1'b0;
        o_mem_write_en   = 1'b0;
        o_instr_write_en = 1'b0;
        o_branch         = 1'b0;

        case ( PS )
            FETCH: begin
                o_mem_addr_src     = 1'b0;  
                o_instr_write_en   = 1'b1;
                o_alu_src_1        = 2'b00;
                o_alu_src_2        = 2'b10;
                o_result_src       = 2'b10;
                o_pc_update        = 1'b1;
                o_alu_op           = 2'b00;
            end 

            DECODE: begin
                o_alu_src_1 = 2'b01;
                o_alu_src_2 = 2'b01;
                o_alu_op    = 2'b00;
            end

            MEMADDR: begin
                o_alu_src_1 = 2'b10;
                o_alu_src_2 = 2'b01;
                o_alu_op    = 2'b10;
            end

            MEMREAD: begin
                o_result_src   = 2'b00;
                o_mem_addr_src = 1'b1;
            end

            MEMWB: begin
                o_result_src   = 2'b01;
                o_reg_write_en = 1'b1;
            end

            MEMWRITE: begin
                o_result_src = 2'b00;
                o_mem_addr_src = 1'b1;
                o_mem_write_en = 1'b1;
            end

            EXECUTER: begin
                o_alu_src_1 = 2'b10;
                o_alu_src_2 = 2'b00;
                o_alu_op    = 2'b10;
            end

            ALUWB: begin
                o_result_src   = 2'b00;
                o_reg_write_en = 1'b1;
            end

            EXECUTEI: begin
                o_alu_src_1 = 2'b10;
                o_alu_src_2 = 2'b01;
                o_alu_op    = 2'b10;
            end

            JAL: begin
                o_alu_src_1  = 2'b01;
                o_alu_src_2  = 2'b10;
                o_alu_op     = 2'b00;
                o_result_src = 2'b00;
                o_pc_update  = 1'b1;
            end

            BEQ: begin
                o_alu_src_1  = 2'b10;
                o_alu_src_2  = 2'b00;
                o_alu_op     = 2'b01;
                o_result_src = 2'b00;
                o_branch     = 1'b1;
            end


            default: begin
                o_alu_op         = 2'b00;
                o_result_src     = 2'b00;
                o_alu_src_1      = 2'b00;
                o_alu_src_2      = 2'b00;
                o_mem_addr_src   = 1'b0;
                o_reg_write_en   = 1'b0;
                o_pc_update      = 1'b0;
                o_mem_write_en   = 1'b0;
                o_instr_write_en = 1'b0;
                o_branch         = 1'b0;
            end
        endcase
    end
    
endmodule