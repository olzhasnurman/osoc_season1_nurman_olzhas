/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------
// This is a module to extend immediate input depending on type of instruction.
// ----------------------------------------------------------------------------

module extend_imm
// Parameters.
#(
    parameter IMM_WIDTH = 25,
              OUT_WIDTH = 32
) 
// Port decleration.
(
    // Control signal. 
    input  logic [             1:0 ] control_signal,

    // Input interface.
    input  logic [ IMM_WIDTH - 1:0 ] i_imm,
    
    // Output interface.
    output logic [ OUT_WIDTH - 1:0 ] o_imm_ext
);

    logic [ OUT_WIDTH - 1:0 ] s_i_type;
    logic [ OUT_WIDTH - 1:0 ] s_s_type;
    logic [ OUT_WIDTH - 1:0 ] s_b_type;
    logic [ OUT_WIDTH - 1:0 ] s_j_type;

    // Sign extend immediate for different instruction types. 
    assign s_i_type = { {20{i_imm[24]}}, i_imm[24:13] };
    assign s_s_type = { {20{i_imm[24]}}, i_imm[24:18], i_imm[4:0] };
    assign s_b_type = { {20{i_imm[24]}}, i_imm[0] , i_imm[23:18], i_imm[4:1], 1'b0 };
    assign s_j_type = { {12{i_imm[24]}}, i_imm[12:5], i_imm[13], i_imm[23:14], 1'b0 };

    // MUX to choose output based on instruction type.
    //  ___________________________________
    // | control signal | instuction type |
    // |________________|_________________|
    // | 00             | I type          |
    // | 01             | S type          |
    // | 10             | B type          |
    // | 11             | J type          |
    // |__________________________________|
    always_comb begin
        if ( control_signal[1] ) begin
            if ( control_signal[0]) begin
                o_imm_ext = s_j_type;
            end
            else o_imm_ext = s_b_type;
        end
        else begin
            if ( control_signal[0] ) begin
                o_imm_ext = s_s_type;
            end
            else o_imm_ext = s_i_type;
        end
    end

    
endmodule