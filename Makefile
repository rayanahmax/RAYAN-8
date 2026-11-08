# RAYAN-8 build automation
# Run from inside WSL (Fedora) at the repo root.

IVERILOG ?= iverilog
VVP ?= vvp
CXX ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra

RTL := $(wildcard rtl/*.v)
TB  := $(wildcard tb/*.v)
ASM_SRC := $(wildcard asm/*.cpp)

.PHONY: all sim asm clean help

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

clean:
	rm -rf build/*

help:
	@echo "make sim   - compile rtl/*.v + tb/*.v and run simulation"
	@echo "make asm   - build the C++ assembler from asm/*.cpp"
	@echo "make clean - remove build artifacts"
