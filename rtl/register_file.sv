/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------
// This is a register file component of processor based on RISC-V architecture.
// ----------------------------------------------------------------------------

module register_file
// Parameters.
#(
    parameter DATA_WIDTH = 64,
              ADDR_WIDTH = 5,
              REG_DEPTH  = 32
)
// Port decleration. 
(   
    // Common clock & enable signal.
    input  logic                      clk,
    input  logic                      write_en_3,
    input  logic                      arst,

    //Input interface. 
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr_1,
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr_2,
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr_3,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data_3,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data_1,
    output logic                      o_a0_reg_lsb, // FOR SIMULATION ONLY.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data_2
);

    // Register block.
    logic [ DATA_WIDTH - 1:0 ] mem [ REG_DEPTH - 1:0 ];

    // Write logic.
    always_ff @( posedge clk, posedge arst ) begin 
        if ( arst ) begin
            mem[0] <= '0;
            mem[1] <= '0;
            mem[2] <= '0;
            mem[3] <= '0;
            mem[4] <= '0;
            mem[5] <= '0;
            mem[6] <= '0;
            mem[7] <= '0;
            mem[8] <= '0;
            mem[9] <= '0;
            mem[10] <= '0;
            mem[11] <= '0;
            mem[12] <= '0;
            mem[13] <= '0;
            mem[14] <= '0;
            mem[15] <= '0;
            mem[16] <= '0;
            mem[17] <= '0;
            mem[18] <= '0;
            mem[19] <= '0;
            mem[20] <= '0;
            mem[21] <= '0;
            mem[22] <= '0;
            mem[23] <= '0;
            mem[24] <= '0;
            mem[25] <= '0;
            mem[26] <= '0;
            mem[27] <= '0;
            mem[28] <= '0;
            mem[29] <= '0;
            mem[30] <= '0;
            mem[31] <= '0;
        end
        else if ( write_en_3 ) begin
            mem[i_addr_3] <= i_write_data_3;
            mem[ 0 ] <= '0;
        end
    end

    // Read logic.
    assign o_read_data_1 = mem[i_addr_1];
    assign o_read_data_2 = mem[i_addr_2];
    assign o_a0_reg_lsb  = mem[10][0];

    
endmodule