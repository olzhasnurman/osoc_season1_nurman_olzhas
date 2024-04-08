import subprocess

# Open the file containing the list of file names
with open("list_rv.txt", "r") as file_list:
    # Iterate over each line in the file
    for file_name in file_list:
        # Strip whitespace and newline characters
        file_name = file_name.strip()

        # Construct the input and output file paths based on the file name
        input_file_path = f"rvtest/{file_name}"
        output_file_path = f"rvtest/{file_name}.txt"

        # Construct the objdump command
        command = f"riscv64-unknown-elf-objdump -D  --start-address=0x1000 --stop-address=0x3070 -b binary --full-content -m riscv:rv64 -M no-aliases,numeric {input_file_path} > {output_file_path}"

        # Execute the command
        subprocess.run(command, shell=True)

print("Disassembly complete for all files listed in list_am.txt.")

