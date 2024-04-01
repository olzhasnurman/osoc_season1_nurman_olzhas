import os

# Define the path to the input and output files
file_path       = 'nemu/1.txt'
file_path_2     = 'nemu/2.txt'
file_path_3     = 'nemu/3.txt'

# Initialize an empty list to hold the lines to be written to the output file
output_lines = []

# Flag to indicate whether the end of the relevant content has been reached (i.e., after an empty line)
end_of_relevant_content = False

# Open the input file and read its contents


import sys
import os

def hex_diff(hex1, hex2):
    """Calculate the difference between two hex values, subtract 1, and return the result."""
    return int(hex2, 16) - int(hex1, 16) - 4
        

def process_file(input_file_name):
    # Construct the input and output paths based on the input file name
    input_path = f"nemu/{input_file_name}"
    output_file_name = input_file_name.replace("-riscv64-nemu", "")
    output_path = f"instructions/{output_file_name}"
    
    # Ensure the output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Process the file: replace all "..." with "HERE"
    try:
        with open(input_path, 'r') as file:
            skip_next_line = True  # Mark to skip the next line
            for line in file:
                if line.strip() == "":  # Check if the line is empty
                    skip_next_line = True  # Mark to skip the next line
                elif skip_next_line:
                    skip_next_line = False  # Reset skip flag but skip this line
                else:
                    output_lines.append(line)  # Add non-empty and non-skipped lines to the list
        
        # Open (or create) the output file and write the relevant lines to it
        with open(file_path, 'w') as file:
            file.writelines(output_lines)
        
        with open(file_path, 'r') as file_in:
            # Open the output file where the processed content will be written
        
            with open(file_path_2, 'w') as file_out:
                # Iterate over each line in the input file
                for line in file_in:
                    # Replace "..." with "HERE" in the line
                    modified_line = line.replace("...", "HERE")
                    # Write the modified line to the output file
                    file_out.write(modified_line)
        
        # Initialize an empty list to hold all lines from the input file for easy access
        lines = []
        
        # Read all lines from the input file into the list
        with open(file_path_2, 'r') as file_in:
            lines = file_in.readlines()
        
        # Open the output file where the processed content will be written
        with open(file_path_3, 'w') as file_out:
            for i in range(len(lines)):
                if "HERE" in lines[i]:
                    # Ensure there's a next and previous line to work with
                    if i > 0 and i < len(lines) - 1:
                        # Calculate n based on the difference in hex values between the next and current line
                        n = int(int(hex_diff(lines[i-1][3:12], lines[i+1][3:12]))/4)
                        # Write "0000001b" n times to the output file
                        for _ in range(n):
                            file_out.write("              0000001b\n")
                else:
                    # Write the original line to the output file if it doesn't contain "HERE"
                    file_out.write(lines[i])
        
        # Open the input file and read its contents
        with open(file_path_3, 'r') as file_in:
            # Open the output file where the processed content will be written
            with open(output_path, 'w') as file_out:
                # Iterate over each line in the input file
                for line in file_in:
                    # Extract the content from columns 17 to 25 (inclusive) from each line
                    # Note: Python uses 0-based indexing, so column 17 is at index 16
        
                    extracted_content = line[14:22]
                    # Write the extracted content to the output file, adding a newline character
                    file_out.write(extracted_content + '\n')
    except FileNotFoundError:
        print(f"File {input_path} does not exist.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        input_file_name = sys.argv[1]
        process_file(input_file_name)
    else:
        print("Please provide the input file name as an argument.")

def clean():
    os.remove(file_path)
    os.remove(file_path_2) 
    os.remove(file_path_3) 

clean()
 
