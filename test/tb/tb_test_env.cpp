#include <stdlib.h>
#include <iostream>
#include <cstdlib>
#include <memory>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtest_env.h"

#define MAX_SIM_TIME 10000000
vluint64_t sim_time = 0;
vluint64_t posedge_cnt = 0;


void dut_reset (Vtest_env *dut, vluint64_t &sim_time){
    
    if( sim_time < 100 ){
        dut->arstn = 0;
    }
    else {
        dut->arstn = 1;
    }
}

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Vtest_env *dut = new Vtest_env;

    while (sim_time < MAX_SIM_TIME) {
        dut_reset(dut, sim_time);
        dut->clk ^= 1;
        dut->eval();

        if (dut->clk == 1){
            posedge_cnt++;
        }

        sim_time++;
    }

    delete dut;
    exit(EXIT_SUCCESS);
}
