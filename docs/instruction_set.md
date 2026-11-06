# RAYAN-8 Instruction Set

RAYAN-8 uses a fixed 16-bit instruction format:

| Field   | Bits  | Width |
|---------|-------|-------|
| Opcode  | 15–12 | 4 bits |
| RD      | 11–10 | 2 bits |
| RS      | 9–8   | 2 bits |
| Operand | 7–0   | 8 bits |

RD [11:10] identifies the destination or source register used by the instruction. RS [9:8] identifies the second register operand. Operand [7:0] carries an immediate value, a memory address, or a jump target, depending on the opcode.

Register encoding: R0 = `00`, R1 = `01`, R2 = `10`, R3 = `11`.

Unused fields are set to zero.

---

## 1. Opcode Map

| Opcode | Mnemonic | Type | Fields Used | Flags |
|--------|----------|------|-------------|-------|
| `0000` | LDI      | Immediate | RD, Operand | Z |
| `0001` | ADD      | ALU (reg,reg) | RD, RS | Z, C |
| `0010` | SUB      | ALU (reg,reg) | RD, RS | Z, C |
| `0011` | AND      | ALU (reg,reg) | RD, RS | Z |
| `0100` | OR       | ALU (reg,reg) | RD, RS | Z |
| `0101` | XOR      | ALU (reg,reg) | RD, RS | Z |
| `0110` | NOT      | ALU (unary) | RD, RS | Z |
| `0111` | MOV      | Data transfer | RD, RS | Z |
| `1000` | LOAD     | Memory read | RD, Operand | Z |
| `1001` | STORE    | Memory write | RD, Operand | none |
| `1010` | JMP      | Unconditional branch | Operand | none |
| `1011` | JZ       | Conditional branch | Operand | none |
| `1100` | JC       | Conditional branch | Operand | none |
| `1101` | HALT     | Control | none | none |
| `1110` | reserved | — | — | — |
| `1111` | reserved | — | — | — |

14 instructions defined, 2 opcodes reserved for future use.

---

## 2. Immediate Instructions

### LDI

**Syntax:** `LDI RD, IMM`

**Operation:** `RD = IMM`

**Description:** Loads the 8-bit immediate value into the destination register.

**Encoding:**
- Opcode: `0000`
- RD: Destination register
- RS: `00` (unused)
- Operand: 8-bit immediate value

**Flags:** Sets Z if the loaded value is zero.

**Example:**

```asm
LDI R0, 15
```

Machine code: `0000 00 00 00001111` = `0x000F`.

---

## 3. ALU Instructions

Arithmetic and logical instructions use the form `OP RD, RS`, meaning the result is written to RD using RS as the source.

### ADD

**Syntax:** `ADD RD, RS`

**Operation:** `RD = RD + RS`

**Encoding:** Opcode `0001`, RD = destination, RS = source, Operand = `00000000`.

**Flags:** Sets Z if the result is zero, sets C on unsigned overflow.

### SUB

**Syntax:** `SUB RD, RS`

**Operation:** `RD = RD - RS`

**Encoding:** Opcode `0010`, RD = destination, RS = source, Operand = `00000000`.

**Flags:** Sets Z if the result is zero, sets C on borrow.

### AND

**Syntax:** `AND RD, RS`

**Operation:** `RD = RD & RS`

**Encoding:** Opcode `0011`, RD = destination, RS = source, Operand = `00000000`.

**Flags:** Sets Z if the result is zero.

### OR

**Syntax:** `OR RD, RS`

**Operation:** `RD = RD | RS`

**Encoding:** Opcode `0100`, RD = destination, RS = source, Operand = `00000000`.

**Flags:** Sets Z if the result is zero.

### XOR

**Syntax:** `XOR RD, RS`

**Operation:** `RD = RD ^ RS`

**Encoding:** Opcode `0101`, RD = destination, RS = source, Operand = `00000000`.

**Flags:** Sets Z if the result is zero.

### NOT

**Syntax:** `NOT RD, RS`

**Operation:** `RD = ~RS`

**Description:** Writes the one's complement of RS into RD.

**Encoding:** Opcode `0110`, RD = destination, RS = source, Operand = `00000000`.

**Flags:** Sets Z if the result is zero.

---

## 4. Data Transfer Instructions

### MOV

**Syntax:** `MOV RD, RS`

**Operation:** `RD = RS`

**Encoding:** Opcode `0111`, RD = destination, RS = source, Operand = `00000000`.

**Flags:** Sets Z if the value is zero.

---

## 5. Memory Instructions

### LOAD

**Syntax:** `LOAD RD, ADDR`

**Operation:** `RD = RAM[ADDR]`

**Description:** Reads the 8-bit value at the data memory address given by the operand and writes it into the destination register. Uses MemRead.

**Encoding:**
- Opcode: `1000`
- RD: Destination register
- RS: `00` (unused)
- Operand: 8-bit memory address

**Flags:** Sets Z if the loaded value is zero.

**Example:**

```asm
LOAD R1, 20
```

Machine code: `1000 01 00 00010100` = `0x8414`.

### STORE

**Syntax:** `STORE RD, ADDR`

**Operation:** `RAM[ADDR] = RD`

**Description:** Stores the 8-bit value held in the specified register into the data memory address provided by the operand field. Uses MemWrite.

**Encoding:**
- Opcode: `1001`
- RD: Source register identifier
- RS: `00` (unused)
- Operand: 8-bit memory address

**Flags:** None.

**Example:**

```asm
STORE R2, 20
```

Machine code: `1001 10 00 00010100` = `0x9814`.

---

## 6. Branch Instructions

Branches take an 8-bit target address in the Operand field, so the target range is 0 to 255, matching the instruction memory size.

### JMP

**Syntax:** `JMP ADDR`

**Operation:** `PC = ADDR`

**Description:** Unconditional jump. The Next-PC Selection mux always takes the jump target.

**Encoding:** Opcode `1010`, RD = `00` (unused), RS = `00` (unused), Operand = target address.

### JZ

**Syntax:** `JZ ADDR`

**Operation:** `if (Z == 1) PC = ADDR`

**Description:** Jump if zero. Taken only when the Zero flag is set.

**Encoding:** Opcode `1011`, RD = `00` (unused), RS = `00` (unused), Operand = target address.

### JC

**Syntax:** `JC ADDR`

**Operation:** `if (C == 1) PC = ADDR`

**Description:** Jump if carry. Taken only when the Carry flag is set.

**Encoding:** Opcode `1100`, RD = `00` (unused), RS = `00` (unused), Operand = target address.

---

## 7. Control Instructions

### HALT

**Syntax:** `HALT`

**Operation:** Stops instruction fetch and execution.

**Description:** The control unit enters the halt state and the processor stops advancing the PC.

**Encoding:** Opcode `1101`, RD = `00`, RS = `00`, Operand = `00000000`.

---

## 8. Open Decisions

- Reserved opcodes `1110` and `1111` are held for future instructions.
- SUB sets C on borrow. If subtraction is later used for signed compare, an overflow (V) flag may need to be added. Not required for v1.0.
- No dedicated compare instruction. Conditional branches rely on the flags set by the preceding ADD or SUB.
