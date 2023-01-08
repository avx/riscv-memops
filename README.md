# risc-v memcpy, memset, memmove functions

Optimized memcpy, memset, memmove functions written in RISC-V assembler.
Everyone wants to reduce the size of the code, so in order to comply with
the compressed ISA specification, here preferably s0-s1, a0-a5 registers
are used.

Minimal supported risc-v ISA: rv32e

## code size

rv64gc: memset: 148 bytes, memcpy: 192 bytes, memmove: 360 bytes

## performance

- rv64: memcpy(page1, page2, 4096) => 1178 instructions; 3.477 bytes per ins. (tends to 3.66)
- rv64: memset(page, 0, 4096) => 634 instructions; 6.46 bytes per ins. (tends to 6.73)
- memmove: 5 instructions per load/store LEN where LEN is depend on the mutual alignment of src/dst.

