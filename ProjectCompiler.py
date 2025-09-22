## --------------------------------------------
#
#  ECE2072 Project Assembly Compiler
#  Author : ECE2072 Staff
#  Last Modified : 25/09/2024
#
## --------------------------------------------

from typing import List

LABELS = {}

INSTRUCTION_instructionType = {
    "disp": 2,
    "add" : 1,
    "addi": 2,
    "sub" : 1,
    "mul" : 1,
    "ssi" : 2,
    "bez" : 2,
    "movi": 2
}

OPCODES = {
    "disp": "000",
    "add" : "001",
    "addi": "010",
    "sub" : "011",
    "mul" : "100",
    "ssi" : "101",
    "bez" : "110",
    "movi": "111"
}

REGISTERS = {
    "r0": "000",
    "r1": "001",
    "r2": "010",
    "r3": "011",
    "r4": "100",
    "r5": "101",
    "r6": "110",
    "r7": "111"
}



def process_line(lineText: str, lineNum: int) -> tuple[List[str] | None, int]:
    # Break line up by spaces
    line = lineText.split(" ")

    # remove any empty strings
    line = [x for x in line if x]

    if line[0] in ["\n", "\r\n"]:
        return (None, lineNum)
    
    # Check if the line is a comment
    if "//" in line[0]:
        return (None, lineNum)

    # Check the opcode
    if line[0] not in OPCODES:
        assert ValueError(f"Compilation Failed: Invalid Instruction: \"{lineText}\"")
        
    if line[-1][-1] == "\n":
        line[-1] = line[-1][:-1]

    # Check for labels
    if line[0][-1] == ":":
        # Labels are pre-processed, so we can just return
        return (None, lineNum)

    # Get the opcode
    opcode = OPCODES[line[0]]

    # Check the instruction instructionType
    instructionType = INSTRUCTION_instructionType[line[0]]

    # Get the first argument, always a register for all instructions
    arg1 = line[1]

    if arg1[-1] == ",": arg1 = arg1[:-1] # Remove comma if present

    if arg1 not in REGISTERS:
        assert ValueError(f"Compilation Failed: Invalid First Argument: \"{lineText}\"")

    # If its a register instructionType instruction
    if instructionType == 1:        
        arg2 = line[2]
        if arg2 not in REGISTERS:
            assert ValueError(f"Compilation Failed: Invalid Second Argument: \"{lineText}\"")

        instructionBinary = opcode + REGISTERS[arg1] + REGISTERS[arg2]
        return ([instructionBinary, "000000000"], lineNum + 1)

    # If its an immediate instructionType instruction
    if instructionType == 2:
        if line[0] == "disp":
            if len(line) != 2:
                assert ValueError(f"Compilation Failed: Invalid Number of Arguments for disp: \"{lineText}\"")
            instructionBinary = opcode + REGISTERS[arg1] + "000"
            return ([instructionBinary, "000000000"], lineNum + 1)
        
        imm = ''
        try:
            imm = int(line[2])
        except:
            pass

        if (type(imm) == int):
            imm = imm
        elif line[2] in LABELS:
            imm = (LABELS[line[2]] - lineNum) - 1
        else:
            assert ValueError(f"Compilation Failed: Invalid Immediate Value or Label: \"{lineText}\"")

        if imm > 255 or imm < -256:
            assert ValueError(f"Compilation Failed: Invalid Immediate Value: \"{lineText}\"")
                              
        instructionBinary = opcode + REGISTERS[arg1] + "000"
        immediateBinary = format(imm, "09b")
        # Convert to 2s complement
        if immediateBinary[0] == "-":
            immediateBinary = immediateBinary[1:]
            immediateBinary = "".join(["1" if x == "0" else "0" for x in immediateBinary])
            immediateBinary = bin(int(immediateBinary, 2) + 1)[2:]
            immediateBinary = "1" + immediateBinary
        return ([instructionBinary, immediateBinary], lineNum + 1)

    assert ValueError(f"Compilation Failed: Unknown Instruction Error for: \"{lineText}\"")


def process_labels(lines: list[str]) -> None:
    lineNum = 0
    for line in lines:
        if not line:
            continue

        if line[0:1] == "//":
            continue

        line = line.split(" ")
        line = [x for x in line if x]

        if ":" in line[0]:
            colonPos = line[0].index(":")
            LABELS[line[0][:colonPos]] = lineNum
            continue   

        if line[0] in OPCODES:
            lineNum += 1
            continue
    pass

def process_file(fileName: str) -> list[str]:
    outputCode = []
    
    
    f = open(fileName, "r")

    lines = f.readlines()
    
    # Pre-process labels
    process_labels(lines)

    nextLineNum = 0
    
    for line in lines:
        try:
            instructionBinary, nextLineNum = process_line(line, nextLineNum)
        except ValueError as e:
            print(e)
            return []
        except Exception as e:
            print(f"Compilation Failed: Unknown Error | {e} on line \"{line[::-1]}\"")
            return []
        
        
        if not instructionBinary:
            continue
        
        outputCode += instructionBinary
    
    f.close()
  
    return outputCode


def construct_mif(outputFileName: str, instructionBinary: List[str]) -> None:
    """
        .mif file format: https://www.intel.com/content/www/us/en/programmable/quartushelp/17.0/reference/glossary/def_mif.htm
    """
    f = open(outputFileName, "w")

    # Header information
    headerString = "DEPTH = 32768;\nWIDTH = 9;\nADDRESS_RADIX = DEC;\nDATA_RADIX = BIN;\nCONTENT\nBEGIN\n"

    # Footer information
    footerString = "END;\n"

    # Data Lines
    dataLines = ""
    for i in range(len(instructionBinary)):
        dataLines += f"{i} : {instructionBinary[i]};\n"
    pass

    # Construct File
    f.write(headerString + dataLines + footerString)
    f.close()


if __name__ == "__main__":
    inputFileName = "INSERT INPUT NAME HERE"
    outputFileName = "memory.mif"
    instructionBinary = process_file(inputFileName)
    construct_mif(outputFileName, instructionBinary)
