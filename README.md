# **Systolic Array Matrix Multiplier**
###  Project Overview
This project implements a parameterized systolic array in Verilog for high-performance matrix multiplication. It features a scalable architecture with double-buffered I/O, full handshaking protocols, and a comprehensive testbench using Cocotb. This design demonstrates key principles of high-throughput digital signal processing and parallel computing hardware.

### Architecture & Design
The core of the design is an N x M array of Processing Elements (PEs). Data and weights flow synchronously through the array in a pipelined fashion, enabling efficient computation of matrix products.

#### Key Components:

systolic_top.v: The top-level module integrating the systolic array with double buffers.

systolic.v: Instantiates and connects the N x M grid of PEs.

pe.v: The Processing Element (PE) that performs multiply-accumulate (MAC) operations.

dobule_buffer.v: A dual-buffer module for seamless streaming I/O, decoupling external memory bandwidth from the array's processing rate.

Dataflow: The array computes one column of the resulting N x M matrix per cycle. Input matrices are fed column by column.

### Parameters
The design is fully parameterized in systolic_top.v:

DATAWIDTH: Bit-width of each data element (default: 32).

N: Height of the systolic array (number of rows).

M: Width of the systolic array (number of columns).

### Getting Started
Prerequisites
Verilog Simulator: Icarus Verilog (iverilog) is used by the Makefile.

Python 3 with Cocotb: For running the advanced testbench.

GTKWave: For viewing waveform dumps (optional but recommended).

Simulation & Testing
The project uses a Makefile for automation.

1. Clone the repository:

        git clone https://github.com/hossein-mokarian/systolic_array.git
        cd systolic_array

2. Run the complete test suite (Cleans, Simulates, Views Waves):

        make myall

Other useful commands:

make myrun : Clean and run the simulation.

make myclean : Clean all build artifacts.

make myview : Open GTKWave to view the latest waveform.

3. Understand the Testbench (test_systolic.py):
The Cocotb testbench (tb/test_systolic.py) feeds test matrices into the design and validates the output. You can modify the data_mat and weight_mat NumPy arrays to test different cases.

### Performance & Characteristics
Throughput: After an initial latency, the array produces one result column per clock cycle.

Area: Scales with O(N x M).

Control Overhead: Minimal; computation is driven by dataflow and a simple start signal.

### Repository Structure

    systolic_array/
    ├── src/                 # Verilog Source Files
    │   ├── pe.v            # Processing Element
    │   ├── systolic.v      # Systolic Array
    │   ├── dobule_buffer.v # Double Buffer
    │   └── systolic_top.v  # Top Module
    ├── tb/                  # Testbench Directory
    │   └── test_systolic.py # Cocotb Testbench
    ├── img/                 # Images for Documentation
    ├── Makefile            # Build & Simulation Automation
    └── README.md           # This file

### Future Work
Quantization: Experiment with fixed-point arithmetic to optimize for area/power.

Extended Precision: Modify the PE to handle accumulation without overflow for larger matrices.

System Integration: Wrap the array with AXI-Stream interfaces for easy integration into larger SoCs.

Synthesis: Target an FPGA board and analyze timing/area reports.
