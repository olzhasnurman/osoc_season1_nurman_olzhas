def decode_instruction(instruction):
    opcode = instruction & 0x7f
    rd = (instruction >> 7) & 0x1f
    funct3 = (instruction >> 12) & 0x7
    rs1 = (instruction >> 15) & 0x1f
    rs2 = (instruction >> 20) & 0x1f
    funct7 = (instruction >> 25)
    imm_i = ((instruction >> 20) & 0xfff) - (0x1000 if instruction & 0x80000000 else 0)
    imm_s = (((instruction >> 25) << 5) | ((instruction >> 7) & 0x1f)) - (0x1000 if instruction & 0x80000000 else 0)
    imm_b = (((instruction >> 31) << 12) | ((instruction & 0x80) << 4) | ((instruction >> 20) & 0x7e0) | ((instruction >> 7) & 0x1e)) - (0x1000 if instruction & 0x80000000 else 0)
    imm_u = instruction & 0xfffff000
    imm_j = (((instruction >> 31) << 20) | ((instruction >> 12) & 0xff) | ((instruction >> 20) & 0x1) | ((instruction >> 21) & 0x3ff)) - (0x100000 if instruction & 0x80000000 else 0)

    if opcode == 0x33:  # R-type
        if funct3 == 0x0:
            if funct7 == 0x00:
                return f"add x{rd}, x{rs1}, x{rs2}"
            elif funct7 == 0x20:
                return f"sub x{rd}, x{rs1}, x{rs2}"
        elif funct3 == 0x1:
            return f"sll x{rd}, x{rs1}, x{rs2}"
        elif funct3 == 0x2:
            return f"slt x{rd}, x{rs1}, x{rs2}"
        elif funct3 == 0x3:
            return f"sltu x{rd}, x{rs1}, x{rs2}"
        elif funct3 == 0x4:
            return f"xor x{rd}, x{rs1}, x{rs2}"
        elif funct3 == 0x5:
            if funct7 == 0x00:
                return f"srl x{rd}, x{rs1}, x{rs2}"
            elif funct7 == 0x20:
                return f"sra x{rd}, x{rs1}, x{rs2}"
        elif funct3 == 0x6:
            return f"or x{rd}, x{rs1}, x{rs2}"
        elif funct3 == 0x7:
            return f"and x{rd}, x{rs1}, x{rs2}"
    

    elif opcode == 0x3b: # R-type
        if funct3 == 0x0:
            if funct7 == 0x00:
                return f"addw x{rd}, x{rs1}, x{rs2}"
            elif funct7 == 0x20:
                return f"subw x{rd}, x{rs1}, x{rs2}"
        elif funct3 == 0x1:
            return f"sllw x{rd}, x{rs1}, x{rs2}"
        elif funct3 == 0x5:
            if funct7 == 0x00:
                return f"srlw x{rd}, x{rs1}, x{rs2}"
            elif funct7 == 0x20:
                return f"sraw x{rd}, x{rs1}, x{rs2}"
            
    elif opcode == 0x1b: # I-Type IW
        if funct3 == 0x0:
            return f"addiw x{rd}, x{rs1}, {imm_i}"
        elif funct3 == 0x1:
            return f"slliw x{rd}, x{rs1}, {imm_i}"
        elif funct3 == 0x5:
            if funct7 == 0x00:
                return f"srliw x{rd}, x{rs1}, { imm_i }"
            elif funct7 == 0x20:
                return f"sraiw x{rd}, x{rs1}, {(imm_i & 0x1f)}"


    elif opcode == 0x03:  # I-type load
        if funct3 == 0x0:
            return f"lb x{rd}, {imm_i}(x{rs1})"
        elif funct3 == 0x1:
            return f"lh x{rd}, {imm_i}(x{rs1})"
        elif funct3 == 0x2:
            return f"lw x{rd}, {imm_i}(x{rs1})"
        elif funct3 == 0x3:
            return f"ld x{rd}, {imm_i}(x{rs1})"
        elif funct3 == 0x4:
            return f"lbu x{rd}, {imm_i}(x{rs1})"
        elif funct3 == 0x5:
            return f"lhu x{rd}, {imm_i}(x{rs1})"
        elif funct3 == 0x6:
            return f"lwu x{rd}, {imm_i}(x{rs1})"
        

    elif opcode == 0x13:  # I-type immediate
        if funct3 == 0x0:
            return f"addi x{rd}, x{rs1}, {imm_i}"
        elif funct3 == 0x1:
            return f"slli x{rd}, x{rs1}, {imm_i}"
        elif funct3 == 0x2:
            return f"slti x{rd}, x{rs1}, {imm_i}"
        elif funct3 == 0x3:
            return f"sltiu x{rd}, x{rs1}, {imm_i}"
        elif funct3 == 0x4:
            return f"xori x{rd}, x{rs1}, {imm_i}"
        elif funct3 == 0x5:
            funct7 = funct7 & 0xfe
            if funct7 == 0x00:
                return f"srli x{rd}, x{rs1}, {imm_i}"
            elif funct7 == 0x20:
                return f"srai x{rd}, x{rs1}, {imm_i}"
        elif funct3 == 0x6:
            return f"ori x{rd}, x{rs1}, {imm_i}"
        elif funct3 == 0x7:
            return f"andi x{rd}, x{rs1}, {imm_i}"
        

    elif opcode == 0x23:  # S-type
        if funct3 == 0x0:
            return f"sb x{rs2}, {imm_s}(x{rs1})"
        elif funct3 == 0x1:
            return f"sh x{rs2}, {imm_s}(x{rs1})"
        elif funct3 == 0x2:
            return f"sw x{rs2}, {imm_s}(x{rs1})"
        elif funct3 == 0x3:
            return f"sd x{rs2}, {imm_s}(x{rs1})"
        
    # elif opcode == 0x63:  # B-type
    #     if funct3 == 0x0:
    #         return f"beq x{rs1}, x{rs2}, {imm_b}"
    # elif opcode == 0x37:  # U-type
    #     return f"lui x{rd}, {imm_u >> 12}"
    # elif opcode == 0x6f:  # J-type
    #     return f"jal x{rd}, {imm_j}"
    print(hex(instruction), "Not found")
    return "Unsupported instruction"

def read_instructions_from_file(file_path):
    with open(file_path, 'r') as file:
        return [line.strip() for line in file]

def write_assembly_to_file(assembly_instructions, file_path):
    with open(file_path, 'w') as file:
        for instruction in assembly_instructions:
            file.write(instruction + '\n')

def convert_machine_code_to_assembly():
    machine_codes = read_instructions_from_file("instructions.txt")
    assembly_instructions = []

    for code in machine_codes:
        instruction = int(code, 16)  # Convert hex to int
        decoded_asm = decode_instruction(instruction)
        assembly_instructions.append(decoded_asm)

    write_assembly_to_file(assembly_instructions, "asm.txt")

# Run the conversion
convert_machine_code_to_assembly()

