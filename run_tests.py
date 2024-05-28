import os
import argparse

AM_TEST_DIR = "./test/tests/list/list-am.txt"
RV_ARCH_TEST_DIR = "./test/tests/list/list-rv-arch-test.txt"
RV_TESTS_DIR = "./test/tests/list/list-rv-tests.txt"
TEST_DIR = "./test/tests/list/list.txt"

MEMORY_FILE = "./rtl/mem_sim.sv"
RESULT_FILE = "result.txt"

TEST_AM = []
TEST_RV_ARCH= []
TEST_RV = []
TEST = {}

with open(AM_TEST_DIR, 'r') as file_in:
    for line in file_in:
                TEST_AM.append(line.strip())

with open(RV_ARCH_TEST_DIR, 'r') as file_in:
    for line in file_in:
                TEST_RV_ARCH.append(line.strip())

with open(RV_TESTS_DIR, 'r') as file_in:
    for line in file_in:
                TEST_RV.append(line.strip())


with open(TEST_DIR, 'r') as file_in:
    for line in file_in:
            # Strip newlines and whitespace
            line = line.strip()
            # Check if the line contains a colon
            if ':' in line:
                # Split the line at the first colon
                parts = line.split(':', 1)
                key = parts[0].strip()
                directory = parts[1].strip()
                TEST[key] = directory
            else:
                print("No colon found in the line.")



COMPILE_C_COMMAND = "gcc -c -o ./check.o ./test/tb/check.c"
VERILATE_COMMAND = "verilator --assert -I./rtl --Wall --cc ./rtl/test_env.sv --exe ./test/tb/tb_test_env.cpp ./test/tb/check.c"
MAKE_COMMAND = "make -C obj_dir -f Vtest_env.mk"
SAVE_COMMAND = "./obj_dir/Vtest_env | tee -a res.txt"
CLEAN_COMMAND = "rm -r ./obj_dir check.o"
CLEAN_RESULT = "rm result.txt"


def clean_before():
    os.system(CLEAN_RESULT)
    with open (RESULT_FILE, 'w') as file_out:
        file_out.write("")


def compile_single(test):
    modify_memory(TEST[test])
    os.system(COMPILE_C_COMMAND)
    os.system(VERILATE_COMMAND)
    os.system(MAKE_COMMAND)
    save_result(test)
    clean_after()

def compile_all():
    for key in TEST.keys():
        compile_single(key)

def compile_group(group):
    if group == 'am':
        for test in TEST_AM:
             compile_single(test)
    elif group == 'rv-arch-test':
        for test in TEST_RV_ARCH:
             compile_single(test)
    elif group == 'rv-tests':
        for test in TEST_RV:
             compile_single(test)
    else:
        print("Unrecognized test group")

def save_result(test):
    os.system(SAVE_COMMAND)
    with open (RESULT_FILE, 'r') as file_in:
         lines = file_in.readlines()

    old_lines = []
    for line in lines:
        old_lines.append(line)

    with open(RESULT_FILE, 'w') as file_out:
         file_out.writelines(old_lines)
         file_out.write(test + ': ')
         with open('res.txt', 'r') as file_in:
            i = 0
            lines = file_in.readlines()
            for line in lines:
                file_out.write(line)
                i += 1
            if i == 0:
                 file_out.write("\n")
                 

                 
    os.system("rm res.txt")

def clean_after():
    os.system(CLEAN_COMMAND)

def print_all_tests():
    for key in TEST.keys():
         print(key)

def modify_memory(mem_directory):
    with open (MEMORY_FILE, 'r') as file_in:
          lines = file_in.readlines()
    new_lines = []
    for line in lines:
         if '`define' in line:
              new_line = '`define PATH_TO_MEM ' + "\"" +mem_directory + "\""
              new_lines.append(new_line)
              new_lines.append("\n")
         else:
              new_lines.append(line)
    with open (MEMORY_FILE, 'w') as file_out:
          file_out.writelines(new_lines)

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--compile-all', action='store_true', default=False)
    parser.add_argument('-l', '--list-tests', action='store_true', default=False)
    parser.add_argument('-s', '--compile-single', type=str)
    parser.add_argument('-g', '--compile-group', type=str)
    parser.add_argument('-c', '--clean', action='store_true', default=False)

    return parser.parse_args()

def main():
    clean_before()
    args = parse_arguments()

    if args.compile_single:
        compile_single(args.compile_single)
    elif args.list_tests:
         print_all_tests()
    elif args.compile_all:
         compile_all()
    elif args.compile_group:
         compile_group(args.compile_group)
    elif args.clean:
         clean_after()
    else:
         print("Invalid arguments")
         

main()
