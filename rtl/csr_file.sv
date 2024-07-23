/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------------
// This is a csr file component of processor based on RISC-V architecture.
// ----------------------------------------------------------------------------

module ysyx_201979054_csr_file
// Parameters.
#(
    parameter DATA_WIDTH = 64,
              ADDR_WIDTH = 3,
              REG_DEPTH  = 8
)
// Port decleration. 
(   
    // Common clock & enable signal.
    input  logic                      clk,
    input  logic                      write_en_1,
    input  logic                      write_en_2,
    input  logic                      arst,

    //Input interface. 
    input  logic [ ADDR_WIDTH - 1:0 ] i_read_addr,
    input  logic [ ADDR_WIDTH - 1:0 ] i_write_addr_1,
    input  logic [ ADDR_WIDTH - 1:0 ] i_write_addr_2,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data_1,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data_2,
    input  logic                      i_timer_int_call,
    input  logic                      i_software_int_call,
    input  logic                      i_interrupt_jump,
    input  logic                      i_mret_instr,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data,
    output logic                      o_mie_mstatus,
    output logic                      o_mtip_mip,
    output logic                      o_msip_mip,
    output logic                      o_mtie_mie,
    output logic                      o_msie_mie
);

    // Register block.
    logic [ DATA_WIDTH - 1:0 ] mem [ REG_DEPTH - 1:0 ];

    // Write logic.
    always_ff @( posedge clk, posedge arst ) begin 
        if ( arst ) begin
            mem[ 0 ] <= '0; // Mstatus
            mem[ 1 ] <= '0; // Mhartid.
            mem[ 2 ] <= '0; // Mie.
            mem[ 3 ] <= '0; // Mtvec.
            mem[ 4 ] <= '0; // Mcause.
            mem[ 5 ] <= '0; // Mepc.
            mem[ 6 ] <= '0; // Mip.
            mem[ 7 ] <= '0; // Reserved.
        end
        else begin
            if ( i_timer_int_call ) mem[ 6 ][ 7 ] <= 1'b1; // mip MTIP bit set.
            else                    mem[ 6 ][ 7 ] <= 1'b0; // mip MTIP bit clear.

            if ( i_software_int_call ) mem [ 6 ][ 3 ] <= 1'b1; // mip MSIP bit set.
            else                       mem [ 6 ][ 3 ] <= 1'b0; // mip MSIP bit clear.

            if ( i_interrupt_jump ) begin 
                mem[ 0 ][ 3 ] <= 1'b0; // mstatus MIE bit clear.
                mem[ 0 ][ 7 ] <= mem[ 0 ][ 3 ]; // mstatus MPIE = MIE when jump to interrupt handler is taken.
            end

            if ( i_mret_instr     ) mem[ 0 ][ 3 ] <= mem[ 0 ][ 7 ]; // mstatus MIE = MPIE in case of MRET instruction.

            if ( write_en_1 ) begin
                case ( i_write_addr_1 )
                    6: mem [ 6 ] <= { i_write_data_1[ DATA_WIDTH - 1:8 ], i_timer_int_call, i_write_data_1 [ 6:4 ], i_software_int_call, i_write_data_1 [ 2:0 ] };
                    0: if ( i_interrupt_jump ) mem [ 0 ] <= {i_write_data_1[ DATA_WIDTH - 1:1 ], 1'b0 };
                       else                                          mem [ 0 ] <= i_write_data_1;
                    default: mem[ i_write_addr_1 ] <= i_write_data_1;
                endcase
            end
    
            if ( write_en_2 ) begin
                case ( i_write_addr_2 )
                    6: mem [ 6 ] <= { i_write_data_2[ DATA_WIDTH - 1:8 ], i_timer_int_call, i_write_data_2[ 6:4 ], i_software_int_call, i_write_data_2[ 2:0 ] };
                    0: if ( i_interrupt_jump ) mem [ 0 ] <= { i_write_data_2 [ DATA_WIDTH - 1:1 ], 1'b0 };
                       else                                         mem [ 0 ] <= i_write_data_2;
                    default: mem [ i_write_addr_2 ] <= i_write_data_2;
                endcase
            end
        end
    end

    // Read logic.
    assign o_read_data   = mem [ i_read_addr ];
    assign o_mie_mstatus = mem [ 0 ][ 3 ];
    assign o_mtip_mip    = mem [ 6 ][ 7 ];
    assign o_msip_mip    = mem [ 6 ][ 3 ];
    assign o_mtie_mie    = mem [ 2 ][ 7 ];  
    assign o_msie_mie    = mem [ 2 ][ 3 ];  
    
endmodule