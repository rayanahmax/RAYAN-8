const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell,
  WidthType, AlignmentType, ImageRun, PageBreak, LevelFormat, BorderStyle
} = require("docx");

// ---- helpers ----
const CONTENT_W = 9026; // A4 with 1in margins, in DXA
function P(text, opts = {}) {
  const runs = Array.isArray(text) ? text : [new TextRun({ text, bold: opts.bold, italics: opts.italics })];
  return new Paragraph({ children: runs, alignment: opts.align, spacing: { after: opts.after ?? 120 }, pageBreakBefore: opts.pbb });
}
function H(text, level) {
  return new Paragraph({ text, heading: level, spacing: { before: 240, after: 120 } });
}
function bullet(text) {
  return new Paragraph({ children: [new TextRun(text)], numbering: { reference: "b", level: 0 }, spacing: { after: 60 } });
}
function cell(text, { bold = false, w, shade } = {}) {
  return new TableCell({
    width: { size: w, type: WidthType.DXA },
    shading: shade ? { fill: shade, type: "clear" } : undefined,
    margins: { top: 40, bottom: 40, left: 80, right: 80 },
    children: [new Paragraph({ children: [new TextRun({ text: String(text), bold })], spacing: { after: 0 } })]
  });
}
function table(headers, rows, widths) {
  const total = widths.reduce((a, b) => a + b, 0);
  const headRow = new TableRow({ tableHeader: true, children: headers.map((h, i) => cell(h, { bold: true, w: widths[i], shade: "E8ECF1" })) });
  const bodyRows = rows.map(r => new TableRow({ children: r.map((c, i) => cell(c, { w: widths[i] })) }));
  return new Table({ width: { size: total, type: WidthType.DXA }, columnWidths: widths, rows: [headRow, ...bodyRows] });
}
const img = fs.readFileSync("cpu-datapath.png");

// ---- document ----
const children = [];

// Title block
children.push(new Paragraph({ children: [new TextRun({ text: "RAYAN-8", bold: true, size: 56 })], alignment: AlignmentType.CENTER, spacing: { before: 1200, after: 120 } }));
children.push(new Paragraph({ children: [new TextRun({ text: "A Custom 8-Bit Processor with a C++ Assembler", size: 30 })], alignment: AlignmentType.CENTER, spacing: { after: 400 } }));
children.push(new Paragraph({ children: [new TextRun({ text: "Experiential Learning Report", italics: true, size: 26 })], alignment: AlignmentType.CENTER, spacing: { after: 800 } }));
children.push(new Paragraph({ children: [new TextRun("Course: Computer Organisation and Architecture")], alignment: AlignmentType.CENTER, spacing: { after: 80 } }));
children.push(new Paragraph({ children: [new TextRun("Student: Rayan Ahmad   |   Roll No: 25BTRCN166   |   B.Tech CSE")], alignment: AlignmentType.CENTER, spacing: { after: 80 } }));
children.push(new Paragraph({ children: [new TextRun("Toolchain: Verilog HDL (Icarus Verilog), C++17, GTKWave, WSL")], alignment: AlignmentType.CENTER, spacing: { after: 400 } }));
children.push(new Paragraph({ children: [new TextRun("Version: Architecture Specification v1.0")], alignment: AlignmentType.CENTER }));

// TOC
children.push(new Paragraph({ children: [new TextRun({ text: "Contents", bold: true })], heading: HeadingLevel.HEADING_1, pageBreakBefore: true }));
[
  "1. Introduction and Objectives",
  "2. Problem Statement",
  "3. Architecture and Block Diagram",
  "4. Instruction Set Architecture",
  "5. Hardware Implementation",
  "6. Assembler Implementation",
  "7. Testing Methodology",
  "8. Experimental Results",
  "9. Screenshots and Waveforms",
  "10. Conclusion and Future Scope",
  "11. References"
].forEach(t => children.push(new Paragraph({ children: [new TextRun(t)], spacing: { after: 60 } })));

// 1 Introduction
children.push(H("1. Introduction and Objectives", HeadingLevel.HEADING_1));
children.push(P("RAYAN-8 is a custom 8-bit processor designed in Verilog HDL, together with a C++17 assembler that translates assembly language into the machine code the processor executes. The project was built from an empty repository to a tested, working CPU that runs real programs, following a phased plan."));
children.push(P("The objectives were:"));
["Design a working 8-bit CPU with a defined instruction set.",
 "Implement the datapath: ALU, register file, memory, and program counter.",
 "Build a multi-cycle control unit as a finite-state machine.",
 "Write a two-pass assembler that encodes assembly into machine code.",
 "Simulate and test every module and the whole processor.",
 "Run non-trivial programs (multiplication, Fibonacci, array maximum) and record the clock cycles."
].forEach(t => children.push(bullet(t)));
children.push(P("Version 1.0 deliberately excludes pipelining, cache, and interrupts. Those are future extensions, not part of the first working processor."));

// 2 Problem statement
children.push(H("2. Problem Statement", HeadingLevel.HEADING_1));
children.push(P("Design a processor from scratch: define its architecture and instruction set, implement the hardware, build the software toolchain, and prove the whole system works. The main challenge was not coding but removing ambiguity from the design first, so that later debugging targets code rather than undecided architecture. Every design choice, from the instruction format to the loop mechanism, was fixed and documented before hardware code was written."));

// 3 Architecture
children.push(H("3. Architecture and Block Diagram", HeadingLevel.HEADING_1));
children.push(P("The processor is 8-bit with a 16-bit fixed-length instruction word and an 8-bit address space."));
children.push(table(["Parameter", "Value"], [
  ["Data width", "8 bits"],
  ["Instruction width", "16 bits"],
  ["Address width", "8 bits"],
  ["General-purpose registers", "4 (R0-R3), 8-bit each"],
  ["Instruction memory", "256 x 16 bits"],
  ["Data memory", "256 x 8 bits"],
  ["ALU", "8-bit"],
  ["Status flags", "Zero (Z), Carry (C)"],
  ["Execution model", "Multi-cycle FSM"],
  ["Hardware description", "Verilog HDL"],
  ["Assembler", "C++17"]
], [3600, 5426]));
children.push(P("The datapath contains the program counter, an incrementer, a next-PC selection multiplexer, instruction memory, the instruction register, the control unit, the register file, an ALU operand-B multiplexer, the ALU, the flag register, a write-back multiplexer, and data memory. Figure 1 shows the complete block diagram."));
children.push(new Paragraph({ children: [new ImageRun({ type: "png", data: img, transformation: { width: 620, height: 276 } })], alignment: AlignmentType.CENTER, spacing: { before: 120, after: 60 } }));
children.push(new Paragraph({ children: [new TextRun({ text: "Figure 1. RAYAN-8 CPU datapath.", italics: true })], alignment: AlignmentType.CENTER, spacing: { after: 200 } }));

// 4 ISA
children.push(H("4. Instruction Set Architecture", HeadingLevel.HEADING_1));
children.push(H("4.1 Instruction format", HeadingLevel.HEADING_2));
children.push(table(["Field", "Bits", "Width"], [
  ["Opcode", "15-12", "4"], ["RD", "11-10", "2"], ["RS", "9-8", "2"], ["Operand", "7-0", "8"]
], [3000, 3013, 3013]));
children.push(P("Registers are encoded R0=00, R1=01, R2=10, R3=11. The meaning of RD, RS, and Operand depends on the opcode. Unused fields are set to zero."));
children.push(H("4.2 Opcode map", HeadingLevel.HEADING_2));
children.push(table(["Opcode", "Mnemonic", "Type", "Fields used", "Flags"], [
  ["0000", "LDI", "Immediate", "RD, Operand", "Z"],
  ["0001", "ADD", "ALU reg,reg", "RD, RS", "Z, C"],
  ["0010", "SUB", "ALU reg,reg", "RD, RS", "Z, C"],
  ["0011", "AND", "ALU reg,reg", "RD, RS", "Z"],
  ["0100", "OR", "ALU reg,reg", "RD, RS", "Z"],
  ["0101", "XOR", "ALU reg,reg", "RD, RS", "Z"],
  ["0110", "NOT", "ALU unary", "RD, RS", "Z"],
  ["0111", "MOV", "Data transfer", "RD, RS", "Z"],
  ["1000", "LOAD", "Memory read", "RD, Operand", "Z"],
  ["1001", "STORE", "Memory write", "RD, Operand", "none"],
  ["1010", "JMP", "Branch", "Operand", "none"],
  ["1011", "JZ", "Branch", "Operand", "none"],
  ["1100", "JC", "Branch", "Operand", "none"],
  ["1101", "HALT", "Control", "none", "none"],
  ["1110", "reserved", "-", "-", "-"],
  ["1111", "reserved", "-", "-", "-"]
], [1200, 1400, 1700, 2000, 2726]));
children.push(H("4.3 Example encodings", HeadingLevel.HEADING_2));
children.push(table(["Assembly", "Binary", "Hex"], [
  ["LDI R0, 15", "0000 00 00 00001111", "000F"],
  ["ADD R0, R1", "0001 00 01 00000000", "1100"],
  ["STORE R0, 20", "1001 00 00 00010100", "9014"],
  ["LOAD R2, 20", "1000 10 00 00010100", "8814"],
  ["JZ 8", "1011 00 00 00001000", "B008"]
], [3026, 3500, 2500]));

// 5 Hardware
children.push(H("5. Hardware Implementation", HeadingLevel.HEADING_1));
children.push(H("5.1 Modules", HeadingLevel.HEADING_2));
children.push(table(["File", "Module", "Role"], [
  ["rtl/alu.v", "alu", "8-bit arithmetic/logic, Z and C flags"],
  ["rtl/regfile.v", "regfile", "4 registers, two read ports, clocked write"],
  ["rtl/imem.v", "imem", "256x16 instruction ROM, combinational read"],
  ["rtl/dmem.v", "dmem", "256x8 data RAM, clocked write"],
  ["rtl/pc.v", "pc", "8-bit program counter"],
  ["rtl/pc_inc.v", "pc_inc", "PC + 1 incrementer"],
  ["rtl/ir.v", "ir", "16-bit instruction register"],
  ["rtl/status_flags.v", "status_flags", "Z and C flag register"],
  ["rtl/control_unit.v", "control_unit", "FSM and opcode decoder"],
  ["rtl/cpu.v", "cpu", "top-level datapath integration"]
], [2400, 1800, 4826]));
children.push(H("5.2 Control unit FSM", HeadingLevel.HEADING_2));
children.push(P("The control unit is a six-state Moore machine: FETCH, DECODE, EXEC, MEM, WB, and HALT. Each instruction takes a fixed number of clock cycles."));
children.push(table(["Instruction", "State path", "Cycles"], [
  ["ADD, SUB, AND, OR, XOR, NOT, LDI, MOV", "FETCH DECODE EXEC WB", "4"],
  ["LOAD", "FETCH DECODE EXEC MEM WB", "5"],
  ["STORE", "FETCH DECODE EXEC MEM", "4"],
  ["JMP, JZ, JC", "FETCH DECODE EXEC WB", "4"],
  ["HALT", "FETCH DECODE HALT", "3"]
], [4200, 3326, 1500]));
children.push(H("5.3 Key design decisions", HeadingLevel.HEADING_2));
["A PASS operation was added to the ALU so that LDI and MOV route their value through the ALU, keeping the write-back mux two-input.",
 "The ISA has no jump-if-not-zero. Loops count down with SUB and exit on the Carry (borrow) flag via JC.",
 "Memory uses direct addressing only, so the address is an immediate in the instruction. There is no register-indirect mode, which limits indexed loops.",
 "The register file has a synchronous reset so the CPU starts with all registers at zero.",
 "Control signals that feed a value used in a later state (alu_op, bsel) are driven by the opcode, not gated by the state, so write-back reads the correct value."
].forEach(t => children.push(bullet(t)));

// 6 Assembler
children.push(H("6. Assembler Implementation", HeadingLevel.HEADING_1));
children.push(P("The assembler (asm/assembler.cpp) is written in C++17 and runs in two passes. Pass one collects labels and assigns each instruction an address. Pass two encodes every instruction into a 16-bit word, resolving label references to their addresses. It supports decimal and hexadecimal immediates, register operands R0-R3, and labels for branch targets."));
children.push(P("It reports clear errors for: unknown mnemonic, invalid register, operand out of the 0-255 range, undefined label, and wrong operand count. Its output is a hex file with one 16-bit word per line, which loads directly into the instruction memory. The assembler output was checked to be byte-for-byte identical to the hand-encoded machine code used by the hardware testbenches."));

// 7 Testing
children.push(H("7. Testing Methodology", HeadingLevel.HEADING_1));
children.push(P("Testing was done at three levels, each with a Verilog testbench run by Icarus Verilog. A Makefile target compiles and runs every testbench separately, because a single $finish would otherwise stop the whole simulation."));
["Unit level: each module (ALU, register file, memory, PC, IR, flags, control unit) has a dedicated testbench.",
 "ISA level: a regression runs small programs through the full CPU covering every opcode, including taken and not-taken branches.",
 "Experiment level: multiplication, Fibonacci, and array maximum run as real assembled programs, with the clock-cycle count recorded."
].forEach(t => children.push(bullet(t)));
children.push(P("The interactive debugger (tools/rayan8-debugger.html) reimplements the same ISA and FSM in JavaScript. It was verified to produce identical final states to the Verilog for all four sample programs, so it can be trusted as a visual model of the hardware."));

// 8 Results
children.push(H("8. Experimental Results", HeadingLevel.HEADING_1));
children.push(H("8.1 Verification summary", HeadingLevel.HEADING_2));
children.push(P("Fourteen testbenches run with 166 assertions, all passing."));
children.push(table(["Testbench", "Checks", "Result"], [
  ["alu_tb", "13", "PASS"], ["control_unit_tb", "63", "PASS"], ["regfile_tb", "9", "PASS"],
  ["imem_tb", "6", "PASS"], ["dmem_tb", "5", "PASS"], ["pc_tb", "5", "PASS"],
  ["ir_tb", "5", "PASS"], ["status_flags_tb", "5", "PASS"], ["cpu_tb", "6", "PASS"],
  ["cpu_isa_tb", "24", "PASS"], ["cpu_integration_tb", "6", "PASS"], ["cpu_mult_tb", "5", "PASS"],
  ["cpu_fib_tb", "6", "PASS"], ["cpu_arraymax_tb", "7", "PASS"]
], [4200, 2400, 2426]));
children.push(H("8.2 Program results", HeadingLevel.HEADING_2));
children.push(table(["Program", "Inputs", "Result", "Cycles"], [
  ["Integration", "a=10, b=20", "R0=30, RAM[100]=30, branch taken", "37"],
  ["Multiplication", "7 x 5", "R2 = 35", "108"],
  ["Fibonacci", "fib(10)", "R0 = 55, R1 = 89", "306"],
  ["Array maximum", "[3,42,17,8,25]", "R0 = 42", "133"]
], [2200, 2200, 3026, 1600]));
children.push(P("Cycle counts are measured from reset release to halt. The JavaScript debugger reports the same programs within one cycle, a difference in how the final halt cycle is counted, not a behavioral difference."));

// 9 Screenshots
children.push(H("9. Screenshots and Waveforms", HeadingLevel.HEADING_1));
children.push(P("Figure 1 (section 3) shows the CPU datapath diagram. Two further captures belong here and should be added from your own machine:"));
["GTKWave waveform of the multiplication or Fibonacci run, opened from build/cpu_mult.vcd or build/cpu_fib.vcd, showing PC, opcode, registers, and flags changing per cycle.",
 "A screenshot of the interactive debugger (open tools/rayan8-debugger.html in a browser), showing the datapath highlight, disassembly, registers, and RAM."
].forEach(t => children.push(bullet(t)));
children.push(P("These are left as placeholders rather than fabricated images. The .vcd files are generated by the testbenches and are ready to open in GTKWave."));

// 10 Conclusion
children.push(H("10. Conclusion and Future Scope", HeadingLevel.HEADING_1));
children.push(P("RAYAN-8 v1.0 is complete and verified. A custom 8-bit processor, its instruction set, a multi-cycle control unit, and a working assembler were built and tested end to end, and the system runs real programs correctly with recorded cycle counts."));
children.push(P("Future extensions, in rough order of value:"));
["Register-indirect addressing so arrays can be scanned in a loop rather than unrolled.",
 "More registers by widening the RD and RS fields, or a larger address space.",
 "A signed overflow flag to support signed comparisons.",
 "Pipelining and cache studies as the advanced (Phase 9) extensions.",
 "Interrupts and an I/O model."
].forEach(t => children.push(bullet(t)));

// 11 References
children.push(H("11. References", HeadingLevel.HEADING_1));
[
  "S. Harris and D. Harris, Digital Design and Computer Architecture, 2nd ed., Morgan Kaufmann, 2012.",
  "D. Patterson and J. Hennessy, Computer Organization and Design, 5th ed., Morgan Kaufmann, 2014.",
  "Icarus Verilog simulator documentation, https://steveicarus.github.io/iverilog/.",
  "GTKWave waveform viewer documentation, https://gtkwave.sourceforge.io/.",
  "ISO/IEC 14882:2017, Programming Language C++.",
  "A. Waterman et al., The RISC-V Instruction Set Manual, Vol. I, UC Berkeley."
].forEach(t => children.push(bullet(t)));

const doc = new Document({
  numbering: { config: [{ reference: "b", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 360, hanging: 240 } } } }] }] },
  styles: { default: { document: { run: { font: "Calibri", size: 22 } } } },
  sections: [{ properties: { page: { margin: { top: 1440, bottom: 1440, left: 1440, right: 1440 } } }, children }]
});

Packer.toBuffer(doc).then(buf => { fs.writeFileSync("RAYAN-8_Report.docx", buf); console.log("wrote RAYAN-8_Report.docx", buf.length, "bytes"); });
