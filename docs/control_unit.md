# RAYAN-8 Control Unit

The control unit is the finite-state machine plus opcode decoder that drives every
control signal in the datapath. It takes the current opcode and the Z/C flags, and
outputs the enables and selects for one clock cycle at a time.

## 1. Interface

Inputs:
- `clk`, `reset`
- `opcode[3:0]` from IR[15:12]
- `z`, `c` from the status flag register

Outputs:
- `ir_en` load instruction register
- `pc_en` load program counter
- `nextpc_sel` 0 selects PC+1, 1 selects jump target
- `rf_wen` register file write enable
- `alu_op[2:0]` ALU operation select
- `bsel` ALU operand B source, 0 = RS, 1 = immediate
- `wb_sel` write-back source, 0 = ALU result, 1 = data memory
- `memwrite` data memory write enable
- `flag_en` capture Z/C into the status register
- `halt` processor stopped

## 2. States

| Code | State | Role |
|------|-------|------|
| 000 | FETCH | Latch instruction into IR, advance PC by 1 |
| 001 | DECODE | Read registers RD and RS, settle opcode |
| 010 | EXEC | ALU operation, or compute address, or decide branch |
| 011 | MEM | Read or write data memory |
| 100 | WB | Write result to register file, or take branch |
| 101 | HALT | Stop |

## 3. State transitions

```
FETCH -> DECODE -> EXEC -> { WB        (ALU / LDI / MOV / branches)
                             MEM       (LOAD / STORE)
                             HALT      (HALT) }
MEM -> WB   (LOAD)
MEM -> FETCH (STORE)
WB -> FETCH
HALT -> HALT
```

## 4. Control signals per state

| State | Asserted |
|-------|----------|
| FETCH | `ir_en=1`, `pc_en=1`, `nextpc_sel=0` |
| DECODE | none |
| EXEC | `alu_op` decoded, `bsel=(opcode==LDI)`, `flag_en=1` for ALU and PASS |
| MEM | `memwrite=1` for STORE only |
| WB | `rf_wen=1` for register-writing ops, `wb_sel=1` for LOAD, and for a taken branch `pc_en=1`, `nextpc_sel=1` |
| HALT | `halt=1` |

## 5. Branch condition

```
taken = (opcode==JMP) || (opcode==JZ && z) || (opcode==JC && c)
```

PC increments in FETCH for every instruction. A taken branch overwrites PC in WB with
the jump target from the Next-PC mux. Not-taken branches leave the incremented PC.

## 6. Cycles per instruction

| Instruction | Path | Cycles |
|-------------|------|--------|
| ADD, SUB, AND, OR, XOR, NOT | FETCH DECODE EXEC WB | 4 |
| LDI, MOV | FETCH DECODE EXEC WB | 4 |
| LOAD | FETCH DECODE EXEC MEM WB | 5 |
| STORE | FETCH DECODE EXEC MEM | 4 |
| JMP, JZ, JC | FETCH DECODE EXEC WB | 4 |
| HALT | FETCH DECODE HALT | 3 |

## 7. ALU op encoding

The control unit maps instruction opcodes to the ALU's 3-bit `alu_op`:

| Instruction | alu_op |
|-------------|--------|
| ADD | 000 |
| SUB | 001 |
| AND | 010 |
| OR | 011 |
| XOR | 100 |
| NOT | 101 |
| LDI, MOV | 110 (PASS, result = b) |

LDI sets `bsel=1` so the ALU passes the immediate. MOV sets `bsel=0` so the ALU passes
the RS operand. Both use PASS, which is why the ALU has a seventh operation.

## 8. Notes

- DECODE is a real cycle. It could be merged into FETCH to save one cycle per
  instruction, but keeping it separate is easier to debug and explain.
- The control unit is a Moore machine: outputs depend on the current state and the
  opcode, not on the next state.
- Flags are captured only in EXEC for ALU and PASS operations, so memory and branch
  instructions do not disturb Z and C.
