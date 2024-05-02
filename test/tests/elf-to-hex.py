import os
import subprocess

# Define the command template
command_template = "riscv64-unknown-elf-objdump -D --start-address=0x1000 -b binary --full-content -m riscv:rv64 -M no-aliases,numeric \"elf/{input_file}\" > \"asm/{output_file}\""

def generate_file_1_path(input_file):
    if input_file.endswith(".elf"):
        return input_file[:-4] + ".txt"
    else:
        return input_file + ".txt"

# Read the list of input files from "str.txt"
with open("str.txt", "r") as file:
    input_files = file.read().strip().split()

# Process each file
for input_file in input_files:
    file_1 = generate_file_1_path(input_file)
    # Format the command with the current input and output file paths
    command = command_template.format(input_file=input_file, output_file=file_1)
    # Run the command
    subprocess.run(command, shell=True)