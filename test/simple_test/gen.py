import random
import struct

reg_values = [0] + list(range(5, 31))

# Function to generate a random R-type instruction
def generate_r_type():
    opcode = 0x33  # Opcode for R-type instructions
    rd = random.choice(reg_values)
    funct3 = random.randint(0, 7)
    rs1 = random.choice(reg_values)
    rs2 = random.choice(reg_values)
    if (funct3 == 0x0 or funct3 == 0x5):
        funct7 = random.randint(0, 1) * 0x20  # Either 0x00 or 0x20
    else: 
        funct7 = 0
    
    instruction = (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    return instruction

def generate_r_type_w():
    opcode = 0x3b  # Opcode for R-type instructions
    rd = random.choice(reg_values)
    funct3 = random.choice([0, 1, 5])
    rs1 = random.choice(reg_values)
    rs2 = random.choice(reg_values)
    if (funct3 == 0x0 or funct3 == 0x5):
        funct7 = random.randint(0, 1) * 0x20  # Either 0x00 or 0x20
    else: 
        funct7 = 0
    
    instruction = (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    return instruction

# Function to generate a random I-type instruction
def generate_i_type_l():
    opcode = 0x03  # Opcode for I-type instructions
    rd = random.choice(reg_values)
    funct3 = random.randint(0, 6)
    rs1 = random.choice(reg_values)
    imm = random.randint(0, 0xfff)  # 12-bit immediate
    instruction = (((imm & 0xffc )<< 20)) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    return instruction

def generate_i_type_i():
    opcode = 0x13  # Opcode for I-type instructions
    rd = random.choice(reg_values)
    funct3 = random.randint(0, 7)
    rs1 = random.choice(reg_values)
    if (funct3 == 0x1 or funct3 == 0x5):
        imm = random.randint(0, 0x3f)  # 6-bit immediate
    else: 
        imm = random.randint(0, 0xfff)  # 12-bit immediate
    instruction = (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    return instruction

def generate_i_type_iw():
    opcode = 0x1b  # Opcode for I-type instructions
    rd = random.choice(reg_values)
    funct3 = random.choice([0, 1, 5])
    rs1 = random.choice(reg_values)
    if (funct3 == 0x1):
        imm = random.randint(0, 0x1f)  # 5-bit immediate
    elif (funct3 == 0x5):
        x = random.randint(0, 1) * 0x20
        imm = (x << 5 ) | random.randint(0, 0x1f)
    else: 
        imm = random.randint(0, 0xfff)  # 12-bit immediate
    instruction = (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    return instruction

# Function to generate a random S-type instruction
def generate_s_type():
    opcode = 0x23  # Opcode for S-type instructions
    imm = random.randint(0, 0xfff)
    funct3 = random.randint(0, 3)
    rs1 = random.choice(reg_values)
    rs2 = random.choice(reg_values)
    instruction = ((imm & 0xfe0) << 20) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm & 0x1c) << 7) | opcode
    return instruction

# Function to generate a random B-type instruction
def generate_b_type():
    opcode = 0x63  # Opcode for B-type instructions
    imm = random.randint(0, 0xfff)
    funct3 = random.randint(0, 7)
    rs1 = random.choice(reg_values)
    rs2 = random.choice(reg_values)
    instruction = ((imm & 0x800) << 20) | ((imm & 0x1e) << 7) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((imm & 0x7e0) << 20) | ((imm & 0x1f) << 7) | opcode
    return instruction

# Function to generate a random U-type instruction
def generate_u_type():
    opcode = random.choice([0x37, 0x17])  # Opcode for U-type (LUI or AUIPC)
    rd = random.choice(reg_values)
    imm = random.randint(0, 0xfffff) << 12  # 20-bit immediate shifted left by 12 bits
    instruction = (imm) | (rd << 7) | opcode
    return instruction

# Function to generate a random J-type instruction
def generate_j_type():
    opcode = 0x6f  # Opcode for J-type instructions (JAL)
    rd = random.choice(reg_values)
    imm = random.randint(0, 0xfffff)
    instruction = ((imm & 0x80000) << 11) | ((imm & 0xff) << 12) | ((imm & 0x100) << 3) | ((imm & 0x7fe00) >> 8) | (rd << 7) | opcode
    return instruction

def gen_empty_data(x, filename="data.txt"):
    with open(filename, "w") as file:
        for _ in range(x):
            data = 0x00000000
            file.write(f"{data:08x}\n")

def gen_reg_clean(x):
    opcode = 0x1b  # Opcode for I-type instructions
    rd = x
    funct3 = 0
    rs1 = 0
    imm = 0
    instruction = (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    return instruction


# Main function to generate x random instructions and write them to a file
def generate_instructions(x, z, filename="instructions.txt"):
    with open(filename, "w") as file:
        i = 0
        for _ in range(z):
            instruction = gen_reg_clean(i)
            file.write(f"{instruction:08x}\n")
            i = i + 1
        for _ in range(x):
            instruction_type = random.choice([generate_r_type, generate_r_type_w, generate_i_type_i, generate_i_type_iw])
            instruction = instruction_type()
            file.write(f"{instruction:08x}\n")

# R and I type functions remain unchanged from the previous example

# Example usage
x = int(input("Enter the number of instructions to generate: "))
generate_instructions(x, 32, "instructions.txt")
y = int(input("Enter the number of data to generate: "))
gen_empty_data(y)


