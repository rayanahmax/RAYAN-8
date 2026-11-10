// RAYAN-8 Assembler (C++17)
// Two-pass assembler: pass 1 collects labels and instruction addresses,
// pass 2 encodes each instruction into a 16-bit word.
//
// Instruction format: Opcode[15:12] | RD[11:10] | RS[9:8] | Operand[7:0]
// Usage: assembler <input.asm> [output.hex]
//        (writes to stdout if no output file is given)

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

struct Instr {
    std::string name;
    int opcode;
    enum Form { NOOP, RI, RR, ADDR } form;   // HALT, <op> RD,imm, <op> RD,RS, <op> ADDR
};

static const std::vector<Instr> ISA = {
    {"LDI",   0x0, Instr::RI},
    {"ADD",   0x1, Instr::RR},
    {"SUB",   0x2, Instr::RR},
    {"AND",   0x3, Instr::RR},
    {"OR",    0x4, Instr::RR},
    {"XOR",   0x5, Instr::RR},
    {"NOT",   0x6, Instr::RR},
    {"MOV",   0x7, Instr::RR},
    {"LOAD",  0x8, Instr::RI},
    {"STORE", 0x9, Instr::RI},
    {"JMP",   0xA, Instr::ADDR},
    {"JZ",    0xB, Instr::ADDR},
    {"JC",    0xC, Instr::ADDR},
    {"HALT",  0xD, Instr::NOOP},
};

static std::string trim(const std::string& s) {
    size_t b = s.find_first_not_of(" \t\r\n");
    if (b == std::string::npos) return "";
    size_t e = s.find_last_not_of(" \t\r\n");
    return s.substr(b, e - b + 1);
}

static std::string upper(std::string s) {
    for (auto& c : s) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    return s;
}

static const Instr* lookup(const std::string& name) {
    for (const auto& i : ISA)
        if (i.name == name) return &i;
    return nullptr;
}

// Returns true and sets reg if the token is R0..R3.
static bool parseReg(const std::string& tok, int& reg) {
    std::string t = upper(trim(tok));
    if (t.size() == 2 && t[0] == 'R' && t[1] >= '0' && t[1] <= '3') {
        reg = t[1] - '0';
        return true;
    }
    return false;
}

// Parses a decimal or 0x hex literal into value. Returns false if not a number.
static bool parseNumber(const std::string& tok, int& value) {
    std::string t = trim(tok);
    if (t.empty()) return false;
    try {
        size_t pos = 0;
        int v;
        if (t.rfind("0X", 0) == 0 || t.rfind("0x", 0) == 0)
            v = std::stoi(t.substr(2), &pos, 16);
        else
            v = std::stoi(t, &pos, 10);
        if (pos != t.size()) return false;   // trailing junk
        value = v;
        return true;
    } catch (...) {
        return false;
    }
}

static std::vector<std::string> splitOps(const std::string& s) {
    std::vector<std::string> out;
    std::stringstream ss(s);
    std::string part;
    while (std::getline(ss, part, ',')) out.push_back(trim(part));
    return out;
}

struct Line {
    int addr;
    std::string mnem;
    std::string ops;
};

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "usage: assembler <input.asm> [output.hex]\n";
        return 1;
    }
    std::ifstream in(argv[1]);
    if (!in) {
        std::cerr << "error: cannot open " << argv[1] << "\n";
        return 1;
    }
    std::string text((std::istreambuf_iterator<char>(in)),
                     std::istreambuf_iterator<char>());

    std::map<std::string, int> labels;
    std::vector<Line> lines;
    int addr = 0;
    int lineno = 0;

    std::stringstream ss(text);
    std::string full;
    while (std::getline(ss, full)) {
        ++lineno;
        size_t sc = full.find(';');
        if (sc != std::string::npos) full = full.substr(0, sc);
        std::string s = trim(full);
        if (s.empty()) continue;

        // Leading "label:"
        size_t colon = s.find(':');
        if (colon != std::string::npos) {
            std::string lab = trim(s.substr(0, colon));
            if (lab.empty()) {
                std::cerr << "line " << lineno << ": empty label\n";
                return 1;
            }
            if (labels.count(lab)) {
                std::cerr << "line " << lineno << ": duplicate label '" << lab << "'\n";
                return 1;
            }
            labels[lab] = addr;
            s = trim(s.substr(colon + 1));
            if (s.empty()) continue;
        }

        std::istringstream ws(s);
        std::string mnem, rest;
        ws >> mnem;
        std::getline(ws, rest);
        mnem = upper(mnem);
        const Instr* ins = lookup(mnem);
        if (!ins) {
            std::cerr << "line " << lineno << ": unknown mnemonic '" << mnem << "'\n";
            return 1;
        }
        lines.push_back({addr, mnem, trim(rest)});
        ++addr;
    }

    std::vector<int> code;
    for (const auto& ln : lines) {
        const Instr* ins = lookup(ln.mnem);
        std::vector<std::string> ops = splitOps(ln.ops);
        int rd = 0, rs = 0;
        long imm = 0;

        if (ins->form == Instr::NOOP) {
            if (!ops.empty() && !ops[0].empty()) {
                std::cerr << "line: " << ln.mnem << " takes no operands\n";
                return 1;
            }
        } else if (ins->form == Instr::RR) {
            if (ops.size() != 2) {
                std::cerr << "line: " << ln.mnem << " needs two register operands\n";
                return 1;
            }
            if (!parseReg(ops[0], rd) || !parseReg(ops[1], rs)) {
                std::cerr << "line: " << ln.mnem << " operands must be R0-R3\n";
                return 1;
            }
        } else if (ins->form == Instr::ADDR) {
            if (ops.size() != 1) {
                std::cerr << "line: " << ln.mnem << " needs one address operand\n";
                return 1;
            }
            int num;
            if (parseNumber(ops[0], num)) {
                imm = num;
            } else {
                auto it = labels.find(ops[0]);
                if (it == labels.end()) {
                    std::cerr << "line: undefined label '" << ops[0] << "'\n";
                    return 1;
                }
                imm = it->second;
            }
        } else { // RI
            if (ops.size() != 2) {
                std::cerr << "line: " << ln.mnem << " needs a register and an operand\n";
                return 1;
            }
            if (!parseReg(ops[0], rd)) {
                std::cerr << "line: " << ln.mnem << " first operand must be R0-R3\n";
                return 1;
            }
            int num;
            if (parseNumber(ops[1], num)) {
                imm = num;
            } else {
                auto it = labels.find(ops[1]);
                if (it == labels.end()) {
                    std::cerr << "line: undefined label '" << ops[1] << "'\n";
                    return 1;
                }
                imm = it->second;
            }
        }

        if (imm < 0 || imm > 255) {
            std::cerr << "line: operand " << imm << " out of range 0-255\n";
            return 1;
        }
        int word = (ins->opcode << 12) | (rd << 10) | (rs << 8) | static_cast<int>(imm);
        code.push_back(word & 0xFFFF);
    }

    std::ostringstream out;
    for (int w : code) {
        out << std::uppercase;
        char buf[8];
        std::snprintf(buf, sizeof(buf), "%04X\n", w);
        out << buf;
    }

    if (argc >= 3) {
        std::ofstream ofs(argv[2]);
        if (!ofs) {
            std::cerr << "error: cannot write " << argv[2] << "\n";
            return 1;
        }
        ofs << out.str();
        std::cerr << "assembled " << code.size() << " instructions to " << argv[2] << "\n";
    } else {
        std::cout << out.str();
    }
    return 0;
}
