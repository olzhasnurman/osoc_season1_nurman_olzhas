# Define the path to the input and output files
input_file_path = 'data_am/am-string.txt'
output_file_path = 'data_am/string.txt'

# Open the input file and read its contents
with open(input_file_path, 'r') as file_in:
    # Open the output file where the modified content will be written
    with open(output_file_path, 'w') as file_out:
        # Iterate over each line in the input file
        for line in file_in:
            # Strip newline characters from the end of the line
            line = line.rstrip()
            # Reorder the characters in each line as per the specified format
            reordered_line = line[6:8] + line[4:6] + line[2:4] + line[0:2]
            # Write the reordered line to the output file, adding a newline character
            file_out.write(reordered_line + '\n')

# Indicate completion
print("File processing complete. Output written to", output_file_path)
