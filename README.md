# ARM-32 Micro

### A Custom 32-bit Processor Architecture in Verilog

<p align="center">
  <img src="https://img.shields.io/badge/HDL-Verilog-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/Architecture-32--bit-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/Registers-16-green?style=flat-square" />
  <img src="https://img.shields.io/badge/PDK-GF180MCU-purple?style=flat-square" />
  <img src="https://img.shields.io/badge/Platform-Tiny%20Tapeout-black?style=flat-square" />
</p>

---

## Introduction
<img width="14404" height="7370" alt="gds_render" src="https://github.com/user-attachments/assets/1f9bfc4f-b9a4-4af6-86f9-00d615784132" />
ARM-32 Micro is a custom 32-bit, ARM-inspired processor designed and implemented entirely in Verilog.


The project explores the design and implementation of a processor at the hardware level, covering instruction decoding, arithmetic and logical operations, register management, memory access, control flow and hardware debugging.

Rather than relying on an existing processor IP, ARM-32 Micro implements its own datapath and control logic, bringing together several independently designed hardware modules into a functional processor architecture.

The processor features:

- A 32-bit datapath and 16 general-purpose registers.
- A custom 16-bit instruction encoding.
- An arithmetic and logic unit (ALU).
- A 32-bit barrel shifter.
- Conditional and unconditional branching.
- Byte and word memory operations.
- An external SRAM interface.
- An SPI-based debugging and programming interface.
- Hardware-level execution control, including halt and single-step functionality.

The project is being developed for fabrication through [Tiny Tapeout](https://tinytapeout.com/), using the GF180MCU process.

## Architecture

ARM-32 Micro uses a 32-bit datapath with a 16-bit instruction format.

The architecture separates instruction decoding, register access, arithmetic execution, shifting, memory management and debugging into individual modules.

### Architectural specifications

| Feature | Specification |
|---|---|
| Architecture | Custom ARM-inspired |
| Data width | 32 bits |
| Instruction width | 16 bits |
| General-purpose registers | 16 × 32-bit |
| Program counter | 32-bit |
| Instruction encoding | Fixed-width |
| ALU | 32-bit |
| Barrel shifter | 32-bit |
| Memory interface | 32-bit CPU-side |
| Physical SRAM | 256 × 8-bit |
| Debug interface | SPI |
| RTL language | Verilog |
| Target PDK | GF180MCU |
| Tiny Tapeout allocation | 4 × 4 tiles |
| Target clock | 10 MHz |

The instruction format is designed to provide a compact encoding while retaining access to the processor's 32-bit registers and datapath.

### Processor organisation

The processor consists of the following primary components:

1. **Instruction Fetch:** Retrieves a 16-bit instruction from program memory.
2. **Instruction Decode:** Extracts the opcode, register operands, immediate values and control signals.
3. **Register Access:** Reads operands from the 16-register register file.
4. **Execution:** Performs arithmetic, logical or shift operations.
5. **Memory Access:** Handles load and store instructions through the memory controller.
6. **Writeback:** Commits operation results to the destination register.

The processor is controlled by a finite state machine (FSM), which coordinates instruction execution and memory transactions.

## Instruction Set Architecture

ARM-32 Micro implements a custom instruction set inspired by ARM-style operations. Its instructions are encoded in 16 bits, with the upper four bits identifying the instruction class.

### Instruction encoding

The general instruction layout is:

| Bits | Description |
|---|---|
| `[15:12]` | Opcode |
| `[11:8]` | Destination register / condition |
| `[7:4]` | Source register |
| `[3:0]` | Second source / immediate |

The interpretation of individual fields depends on the instruction class. Some instructions use immediate values, while others use the available fields for shift amounts or branch offsets.

### Instruction classes

| Opcode | Instruction | Operation |
|---|---|---|
| `0x0` | MOV | Move an immediate value into a register |
| `0x1` | ADD | Addition |
| `0x2` | SUB | Subtraction |
| `0x3` | AND | Bitwise AND |
| `0x4` | EOR | Bitwise exclusive OR |
| `0x5` | ORR | Bitwise OR |
| `0x6` | BIC | Bit clear |
| `0x7` | MVN | Bitwise NOT |
| `0x8` | TST | Test bits using AND |
| `0x9` | LDR | Load a 32-bit word |
| `0xA` | STR | Store a 32-bit word |
| `0xB` | LDRB | Load a byte |
| `0xC` | STRB | Store a byte |
| `0xD` | B | Unconditional branch |
| `0xE` | B.cond | Conditional branch |
| `0xF` | SHIFT | Barrel-shifter operation |

### Arithmetic and logical operations

The ALU supports:

- Addition and subtraction.
- Reverse subtraction.
- Addition with carry.
- Subtraction with carry.
- Bitwise AND, OR and XOR.
- Bit clear and bitwise NOT.
- Multiplication.
- Rotate right.
- Comparison and test operations.

The ALU also calculates the processor condition flags:

| Flag | Description |
|---|---|
| N | Negative result |
| Z | Zero result |
| C | Carry / no-borrow |
| V | Signed overflow |

These flags are used by conditional instructions to determine whether a branch should be taken.

### Barrel shifter

The processor includes a dedicated 32-bit barrel shifter.

Supported operations include:

| Operation | Description |
|---|---|
| LSL | Logical shift left |
| LSR | Logical shift right |
| ASR | Arithmetic shift right |
| ROR | Rotate right |

The shifter also produces a carry-out value, allowing shifted operations to update the carry flag.

### Branching

The processor supports unconditional and conditional branching.

Conditional branches evaluate the processor's condition flags before updating the program counter.

Supported conditions include:

- EQ / NE — Equal / Not equal
- CS / CC — Carry set / Carry clear
- MI / PL — Minus / Plus
- VS / VC — Overflow set / Overflow clear
- HI / LS — Higher / Lower or same
- GE / LT — Greater than or equal / Less than
- GT / LE — Greater than / Less than or equal

The unconditional branch instruction uses a signed, PC-relative offset.

## Register Architecture

The processor contains a register file consisting of 16 independently addressable 32-bit registers.

| Register | Description |
|---|---|
| R0–R14 | General-purpose registers |
| R15 | Program counter |

The register file provides:

- Two combinational read ports.
- One synchronous write port.
- A separate debugging read/write interface.
- Synchronous reset.

The debugging interface allows registers to be inspected and modified without executing normal processor instructions, provided the processor is halted.

## Memory Architecture

ARM-32 Micro uses an external SRAM macro as its primary physical storage.

The implemented memory macro is:

`gf180mcu_ocd_ip_sram__sram256x8m8wm1`

It provides 256 locations, each 8 bits wide, for a total capacity of 256 bytes.

The memory controller provides the processor with a 32-bit interface, translating word and byte accesses into individual SRAM transactions.

### Memory organisation

The physical SRAM is divided into two regions:

| Physical SRAM addresses | Purpose | Capacity |
|---|---|---|
| `0x00–0x7F` | Data memory | 128 bytes |
| `0x80–0xFF` | Instruction memory | 128 bytes |

Instruction memory stores 16-bit instructions, while data memory supports both byte and 32-bit word operations.

The instruction fetch interface reads two consecutive SRAM bytes to retrieve an instruction.

### Memory controller

The memory controller handles:

- Instruction fetch requests.
- Data read and write requests.
- Byte and word transfers.
- Program loading through the debugging interface.
- SRAM address generation.
- Transaction completion signalling.
- Invalid address detection.

The controller uses a finite state machine to coordinate SRAM operations and provides `cpu_ready` and `cpu_error` signals to the processor.

This abstraction allows the CPU core to communicate with memory without directly managing individual SRAM transactions.

## SPI Debugging and Programming

ARM-32 Micro incorporates an SPI-based debugging interface through a dedicated SPI slave module.

This interface allows an external controller to interact with the processor without requiring a separate hardware debugging connection.

### Supported commands

| Command | Code | Description |
|---|---|---|
| PROG | `0x01` | Load a byte into program memory |
| RUN | `0x10` | Resume processor execution |
| HALT | `0x11` | Request processor halt |
| STEP | `0x12` | Execute a single instruction |
| RREG | `0x20` | Read a register |
| WREG | `0x21` | Write a register |
| STATUS | `0x40` | Retrieve processor status |

### SPI packet format

The incoming command packet consists of 88 bits (11 bytes):

| Field | Width |
|---|---:|
| Synchronisation byte (`0xA5`) | 8 bits |
| Command | 8 bits |
| Address | 32 bits |
| Data | 32 bits |
| Checksum | 8 bits |

The checksum is calculated by XORing the first ten bytes of the packet.

The response packet consists of 48 bits (6 bytes):

| Field | Width |
|---|---:|
| Synchronisation byte (`0x5A`) | 8 bits |
| Status | 8 bits |
| Response data | 32 bits |

The interface synchronises incoming SPI signals into the processor clock domain before processing commands.

### Debugging capabilities

The SPI interface provides the ability to:

- Load programs into instruction memory.
- Start and stop processor execution.
- Execute individual instructions.
- Inspect register contents.
- Modify register contents.
- Read the program counter.
- Monitor halt and fault status.

The processor also includes a dedicated debug-halt state, allowing execution to be suspended while debug operations are performed.

## Internal Implementation

The design is divided into independent Verilog modules, each responsible for a specific part of the processor.

### Module hierarchy

| Module | Responsibility |
|---|---|
| `tt_um_godofstrategy_arm32` | Top-level integration and Tiny Tapeout interface |
| `core` | Processor control, instruction execution and state management |
| `decoder` | Instruction decoding and control signal generation |
| `register_file` | Storage and access to the 16 general-purpose registers |
| `alu` | Arithmetic and logical operations |
| `barrel_shifter` | Logical and arithmetic shifting and rotation |
| `memory_controller` | SRAM access and program loading |
| `spi_debug_slave` | SPI command reception and response transmission |

### Core control unit

The core is implemented as a finite state machine.

Its primary states include:

| State | Function |
|---|---|
| `FETCH_REQ` | Request an instruction |
| `FETCH_WAIT` | Wait for instruction retrieval |
| `EXECUTE` | Decode and execute the instruction |
| `MEM_REQ` | Initiate a memory transaction |
| `MEM_WAIT` | Wait for memory completion |
| `DEBUG_HALT` | Suspend execution for debugging |
| `HALT` | Permanently halt after an execution fault |

The state machine coordinates instruction fetching, execution, memory operations, register updates and debugging requests.

### Fault handling

The core monitors invalid instructions and memory transaction errors.

When an invalid instruction or memory error is detected, the processor:

1. Sets the fault indicator.
2. Transitions into the `HALT` state.
3. Stops normal instruction execution.

A reset is required to restart the processor after entering this state.

## Tiny Tapeout Implementation

ARM-32 Micro is designed for physical implementation through the Tiny Tapeout platform.

The design targets the GF180MCU process and uses a dedicated SRAM macro for storage.

### Design configuration

| Parameter | Value |
|---|---|
| Platform | Tiny Tapeout |
| PDK | GF180MCU |
| Top module | `tt_um_godofstrategy_arm32` |
| HDL | Verilog |
| Clock frequency | 10 MHz |
| Tile allocation | 4 × 4 |
| SRAM macro | 256 × 8-bit |

### Pin configuration

The SPI debugging interface uses the Tiny Tapeout input and output pins.

| Tiny Tapeout pin | Signal | Direction |
|---|---|---|
| `ui[0]` | SPI_SCK | Input |
| `ui[1]` | SPI_MOSI | Input |
| `ui[2]` | SPI_CS_N | Input |
| `uo[0]` | SPI_MISO | Output |

The remaining pins are currently unused.

### Physical design

The design is processed through the Tiny Tapeout hardening flow, which uses the LibreLane toolchain for ASIC implementation.

The physical implementation includes synthesis, floorplanning, placement, routing and design-rule verification.

[View the GDS layout](https://gds-explorer.tinytapeout.com/viewer?file=https://godofstrategy.github.io/arm-32/tinytapeout.oas&pdk=gf180mcuD)
[Explore the chip in 3D](https://gds-viewer.tinytapeout.com/?model=https://godofstrategy.github.io/arm-32/tinytapeout.oas&pdk=gf180mcuD)

## Verification and Testing

Verification is an important part of the development process.

The project includes RTL simulation and automated testing infrastructure using Cocotb.

The testbench is intended to verify processor functionality, memory transactions, instruction execution and debugging operations.

## Setting up

The testbench uses [Cocotb](https://docs.cocotb.org/en/stable/) and Icarus Verilog. On Windows, the recommended way to run the simulation is through **WSL (Ubuntu)**.

### 1. Install the required tools

Open your WSL terminal and install the simulation tools:

```bash
sudo apt update
sudo apt install make iverilog gtkwave python3 python3-pip python3-venv
```

### 2. Navigate to the test directory

Clone the repository if you have not already, then navigate to its `test` directory:

```bash
cd arm-32/test
```

### 3. Set up the Python environment

Create and activate a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Install the required Python packages:

```bash
pip install -r requirements.txt
```

The requirements file installs the pinned versions of Pytest and Cocotb.

## How to run

### RTL simulation

From the `test` directory, with the virtual environment activated, run:

```bash
make -B
```

This compiles the RTL sources using Icarus Verilog and runs the Cocotb testbench.

The testbench loads a program into the CPU through its SPI debug interface, starts execution, halts the processor, and checks the resulting register and status values.

A successful simulation should complete without compilation errors or failed Cocotb assertions.

**Note:** The design uses the GF180 SRAM macro `gf180mcu_fd_ip_sram__sram256x8m8wm1`. Its simulation model must be available to Icarus Verilog. If compilation reports `Unknown module type`, the SRAM simulation model has not been correctly included or its module name does not match the instantiated macro. The simulation cannot run until this is resolved.

### Gate-level simulation

First, harden the project and copy the generated gate-level netlist into the test directory as `gate_level_netlist.v`.

Then run:

```bash
make -B GATES=yes
```

The GF180 PDK must be configured correctly for gate-level simulation.

## How to view the waveform

The testbench generates an FST waveform file, which can be opened using GTKWave.

### Using GTKWave

From the `test` directory:

```bash
gtkwave tb.fst
```

You can also open an existing GTKWave save file if one is available:

```bash
gtkwave tb.fst tb.gtkw
```
<img width="14404" height="7370" alt="gds_render" src="https://github.com/user-attachments/assets/a021355f-20b1-4fbf-84eb-64e3b5ddc5bf" />
<img width="567" height="433" alt="image" src="https://github.com/user-attachments/assets/bb6c1e18-7a0f-40ff-aedc-6965f3283b30" />


### Saving the waveform in VCD format

If you prefer VCD instead of FST, change the dump-file declaration in `tb.v` to:

```verilog
$dumpfile("tb.vcd");
```

Then run:

```bash
make -B FST=
```

Open the resulting waveform with:

```bash
gtkwave tb.vcd
```

**Important:** A waveform is generated only when the simulation successfully compiles and runs. If compilation fails, an older waveform file may still exist, but it does not represent the latest simulation.

### Automated verification

The repository also uses GitHub Actions to automate parts of the verification and implementation workflow.

See the [Actions tab](https://github.com/GodOfStrategy/arm-32/actions) for workflow results.

## Repository Structure

arm-32/
  .devcontainer/  
  .github/
  workflows/
  src/
    tt_um_godofstrategy_arm32.v
    core.v
    decoder.v
    register_file.v
    alu.v
    barrel_shifter.v
    memory_controller.v
    spi_debug_slave.v
  test/               

  info.yaml           
  README.md


## Future Development

Potential areas of further development include:

- Expanding the instruction set.
- Improving processor performance.
- Increasing available memory.
- Enhancing debugging and program-loading capabilities.
- Expanding automated verification and instruction-level testing.
- Optimising the design for area and timing.
- Exploring hardware-level performance improvements.

## Contributing

Contributions, suggestions and technical discussions are welcome.

If you find a bug or have an idea for improving the architecture, feel free to open an issue or submit a pull request.

## License

This project is licensed under the [Apache License 2.0](LICENSE).
