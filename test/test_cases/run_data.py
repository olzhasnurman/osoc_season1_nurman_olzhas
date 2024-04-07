import subprocess

# Open the file containing the list of file names
with open("list_am_data.txt", "r") as file_list:
    # Iterate over each line in the file
    for file_name in file_list:
        # Strip whitespace and newline characters
        file_name = file_name.strip()

        # Construct the input and output file paths based on the file name
        input_file_path = f"build/{file_name}.bin"
        output_file_path = f"data/am-{file_name}.txt"

        # Construct the objdump command
        command = f"riscv64-unknown-elf-objdump -D -b binary -m riscv:rv64 -M no-aliases,numeric {input_file_path} > {output_file_path}"

        # Execute the command
        subprocess.run(command, shell=True)

print("Disassembly complete for all files listed in list_am.txt.")

