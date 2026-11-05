# RAYAN-8
## Custom 8-Bit Processor Architecture

### 1. Project Overview
RAYAN-8 is a custom 8-bit processor designed using
Verilog HDL. A C++ assembler will translate assembly
programs into machine code that the processor executes.

### 2. Project Objectives
- Design a custom 8-bit CPU.
- Implement an ALU and register file.
- Design a custom instruction set.
- Implement a control unit and datapath.
- Develop a C++ assembler.
- Simulate and test the processor.

### 3. Initial Architecture Specifications
Status: Architecture specification v0.2

- Data width: 8 bits
- Instruction width: 16 bits
- Address width: 8 bits
- General-purpose registers: 4
- Instruction memory: 256 x 16 bits
- Data memory: 256 x 8 bits
- ALU width: 8 bits
- Program Counter: 8 bits
- Instruction Register: 16 bits
- Initial flags: Zero and Carry
- Execution model: Multi-cycle
- Hardware description: Verilog HDL
- Assembler: C++17


### 4. CPU Components

1. Arithmetic Logic Unit (ALU)
2. Register File
3. Control Unit
4. Program Counter (PC)
5. Instruction Register (IR)
6. Instruction Memory
7. Data Memory
8. Status Flag Register

### 5. Execution Model

RAYAN-8 uses a multi-cycle execution model.

The main execution stages are:

1. Fetch
2. Decode
3. Execute
4. Memory Access
5. Write Back

Not every instruction requires all five stages.

### 6. Instruction Format

RAYAN-8 uses a fixed-length 16-bit instruction format.

| Field   | Bits  |  Width |
|---------|-------|--------|
| Opcode  | 15–12 | 4 bits |
| RD      | 11–10 | 2 bits |
| RS      | 9–8   | 2 bits |
| Operand | 7–0   | 8 bits |

**Total: 16 bits**

#### Register Encoding

| Register | Binary |
|----------| -------|
| R0       | 00     |
| R1       | 01     |
| R2       | 10     |
| R3       | 11     |


#### Instruction Field Interpretation

The meaning of RD, RS and Operand depends on the instruction opcode.

- Immediate instructions use the Operand field for constant values.
- Arithmetic instructions use RD and RS for register selection.
- Memory instructions use the Operand field for memory addresses.
- Jump instructions use the Operand field for the target instruction address.
- Unused fields are set to zero.

#### Example

Assembly instruction:

`LDI R0, 15`

Binary representation:

`0000 00 00 00001111`

Hexadecimal representation:

`000F`

This instruction loads the immediate value 15 into register R0.

