# RAYAN-8 build automation
# Run from inside WSL (Fedora) at the repo root.

IVERILOG ?= iverilog
VVP ?= vvp
CXX ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra

RTL := $(wildcard rtl/*.v)
TB  := $(wildcard tb/*.v)
ASM_SRC := $(wildcard asm/*.cpp)
ASM_PROGS = integration mult

.PHONY: all sim asm asmgen clean help

all: sim asm

build:
	@mkdir -p build

# Compile and run each testbench separately, together with all RTL.
# Each *_tb.v is built into its own simulator binary so one $finish
# does not stop the others.
sim: build $(RTL)
	@status=0; \
	for t in tb/*_tb.v; do \
		name=`basename $$t .v`; \
		echo "=== $$name ==="; \
		$(IVERILOG) -o build/$$name.vvp $(RTL) $$t \
			&& $(VVP) build/$$name.vvp \
			|| status=1; \
	done; \
	exit $$status

# Build the C++ assembler.
asm: build $(ASM_SRC)
	$(CXX) $(CXXFLAGS) -o build/assembler $(ASM_SRC)

# Regenerate the integration program hex from its assembly source.
# This is the software-to-hardware step: assembler output feeds the CPU ROM.
asmgen: asm
	@for p in $(ASM_PROGS); do \
		build/assembler tests/programs/$$p.asm tests/programs/$$p.hex; \
	done

clean:
	rm -rf build/*

help:
	@echo "make sim    - compile rtl/*.v + tb/*.v and run all testbenches"
	@echo "make asm    - build the C++ assembler from asm/*.cpp"
	@echo "make asmgen - assemble integration.asm into integration.hex"
	@echo "make clean  - remove build artifacts"
