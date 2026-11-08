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

# Compile all RTL + testbench files, then run the simulation.
sim: build $(RTL) $(TB)
	$(IVERILOG) -o build/sim.vvp $(RTL) $(TB)
	$(VVP) build/sim.vvp

# Build the C++ assembler.
asm: build $(ASM_SRC)
	$(CXX) $(CXXFLAGS) -o build/assembler $(ASM_SRC)

clean:
	rm -rf build/*

help:
	@echo "make sim   - compile rtl/*.v + tb/*.v and run simulation"
	@echo "make asm   - build the C++ assembler from asm/*.cpp"
	@echo "make clean - remove build artifacts"
