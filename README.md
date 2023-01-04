# riscv memcpy, memset, memmove functions

Optimized memcpy, memset, memmove functions written in RISC-V assembler.
Everyone wants to reduce the size of the code, so in order to comply with
the compressed ISA specification, here preferably s0-s1, a0-a5 registers
are used.
