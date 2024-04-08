import os
import sys

# Define the path to the input and output files
file_path_0     = 'nemu/0.txt'
file_path_1     = 'nemu/1.txt'
file_path_2     = 'nemu/2.txt'
file_path_3     = 'nemu/3.txt'
file_path_4     = 'nemu/4.txt'

# Initialize an empty list to hold the lines to be written to the output file
output_lines = []

# Flag to indicate whether the end of the relevant content has been reached (i.e., after an empty line)
end_of_relevant_content = False
processed_lines = []

# Open the input file and read its contents

def process_file(input_file_name):
    # Construct the input and output paths based on the input file name
    input_path = f"instructions_rvtest/{input_file_name}"
    output_file_name = input_file_name.replace("rv64ui-", "test-")
    output_path = f"instructions_rvtest/{output_file_name}"
    
    # Ensure the output directory exists
    skip_lines = 0
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    line_num = 1
    # Process the file: replace all "..." with "HERE"
    try:
        # Open the input file and read its contents
        with open(input_path, 'r') as file_in:
            # Open the output file where the processed content will be written
            with open(file_path_0, 'w') as file_out:
                # Iterate over each line in the input file
                for line in file_in:
                    # Extract the content from columns 17 to 25 (inclusive) from each line
                    # Note: Python uses 0-based indexing, so column 17 is at index 16
                    if ((line_num > 4) & (line_num < 524)  ): 
                        extracted_content_1 = line[6:14]
                        extracted_content_2 = line[15:23]
                        extracted_content_3 = line[24:32]
                        extracted_content_4 = line[33:41]
                        #extracted_content = line[33:]
                        # Write the extracted content to the output file, adding a newline character
                        file_out.write(extracted_content_1+"\n")
                        file_out.write(extracted_content_2+"\n")
                        file_out.write(extracted_content_3+"\n")
                        file_out.write(extracted_content_4+"\n")
                    line_num = line_num + 1

        with open(file_path_0, 'r') as file_in:
            lines = file_in.readlines()
        
        # Modify lines from 52 to 100 (inclusive)
        for i in range(51, 100):  # Adjusting index for 0-based indexing and inclusive range
            if i < len(lines):  # Check if the current index is within the bounds of the file
                lines[i] = "1b000000\n"  # Replace the line content
        
        # Open (or create) the output file and write the modified content to it
        with open(file_path_1, 'w') as file_out:
            file_out.writelines(lines)        

        with open(file_path_1, 'r') as file_in:
            # Open the output file where the modified content will be written
            with open(output_path, 'w') as file_out:
                # Iterate over each line in the input file
                for line in file_in:
                    # Strip newline characters from the end of the line
                    line = line.rstrip()
                    # Reorder the characters in each line as per the specified format
                    reordered_line = line[6:8] + line[4:6] + line[2:4] + line[0:2]
                    # Write the reordered line to the output file, adding a newline character
                    file_out.write(reordered_line + '\n')
    except FileNotFoundError:
        print(f"File {input_path} does not exist.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        input_file_name = sys.argv[1]
        process_file(input_file_name)
    else:
        print("Please provide the input file name as an argument.")

def clean():
    os.remove(file_path_0)
    os.remove(file_path_1)

clean()