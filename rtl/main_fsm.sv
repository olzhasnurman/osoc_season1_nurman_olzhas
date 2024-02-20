/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------------------------
// This is a main fsm unit that controls all the control signals based on instruction input. 
// -----------------------------------------------------------------------------------------

module main_fsm  
#(
    parameter 
) 
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
    input  logic       i_carry_flag,
    input  logic       i_overflog_flag,

    // Output interface.
    output logic [3:0] alu_control,
    output logic [1:0] result_src,
    output logic [1:0] alu_src_1,
    output logic [1:0] alu_src_2,
    output logic [1:0] imm_src,
    output logic       mem_addr_src,
    output logic       reg_write_en,
    output logic       pc_write_en,
    output logic       mem_write_en,
    output logic       instr_write_en
);  

    typedef enum logic [3:0] {
        FETCH    = 4'b0000,
        DECODER  = 4'b0001,
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

    typedef enum logic [2:0] {
        I_Type = 3'b000;
        S_Type = 3'b001;
        R_Type = 3'b010;
        B_Type = 3'b011;
        J_Type = 3'b100;
        U_Type = 3'b101;
    } t_instruction;

    t_state PS;
    t_state NS;

    // Instruction deocder signal. 
    t_instruction instr;

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
            default: instr = I_Type;
        endcase
    end


    // FSM: Synchronization.
    always_ff @( posedge clk, negedge arstn ) begin
        if (!arstn) begin
            PS <= FETCH;
        end
        else PS <= NS;
    end

    // FSM: Next State logic.
    always_comb begin
        case ( PS )
            FETCH: begin
                NS = PS;
            end 

            DECODE: begin
                case (instr)
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
                case (instr)
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
        case ( PS )
            FETCH: begin
                
            end 
            default: 
        endcase
    end
    
endmodule