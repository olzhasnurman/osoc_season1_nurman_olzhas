import os

input_root = "./instr"
output_root = "./coe"

for dirpath, dirnames, filenames in os.walk(input_root):
    relative_path = os.path.relpath(dirpath, input_root)
    output_dir = os.path.join(output_root, relative_path)
    os.makedirs(output_dir, exist_ok=True)

    for filename in filenames:
        if filename.endswith(".txt"):
            input_file = os.path.join(dirpath, filename)
            output_file = os.path.join(output_dir, filename.replace(".txt", ".coe"))

            with open(input_file, "r") as f:
                lines = [line.strip() for line in f if line.strip() != ""]

            with open(output_file, "w") as f:
                f.write("memory_initialization_radix=16;\n")
                f.write("memory_initialization_vector=\n")

                if len(lines) == 0:
                    # Empty file — still produce a valid .coe
                    f.write(";\n")
                elif len(lines) == 1:
                    f.write(lines[0] + ";\n")
                else:
                    f.write(",\n".join(lines[:-1]) + ",\n" + lines[-1] + ";\n")

print("✅ Conversion complete. COE files created in ./coe")
