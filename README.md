# risc-v memcpy, memset, memmove functions

Optimized memcpy, memset, memmove functions written in RISC-V assembler.
Everyone wants to reduce the size of the code, so in order to comply with
the compressed ISA specification, here preferably s0-s1, a0-a5 registers
are used.

Minimal supported risc-v ISA: rv32e

## code size

rv64gc: memset: 190 bytes, memcpy: 186 bytes, memmove: 264 bytes (322 with lh/sh)

## performance

- rv64: memcpy(page1, page2, 4096) => 1178 instructions; 3.477 bytes per ins. (tends to 3.66)
- rv64: memset(page, 0, 4096) => 574 instructions; 7.13 bytes per ins. (tends to 7.31)
- memmove: 5 instructions per load/store LEN where LEN is depend on the mutual alignment of src/dst.

