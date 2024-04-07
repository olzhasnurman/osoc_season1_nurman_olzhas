import subprocess

# Path to the list.txt file
list_file_path = "list_am_data.txt"

# Open the list.txt file and read all file names
with open(list_file_path, 'r') as list_file:
    for file_name in list_file:
        # Strip whitespace and newline characters from the file name
        file_name = file_name.strip()
        # Check if the file name is not empty
        if file_name:
            # Construct the command to run the dis2instr.py script with the current file name
            command = ["python3", "dis2instr.py", file_name]
            # Execute the command
            subprocess.run(command)
