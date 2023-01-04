/*
 * Copyright 2023 (C) Alexander Vysokovskikh
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//#define USE_HALF_WORD_LOAD_STORES

#if __riscv_xlen == 32
# define REG_S sw
# define REG_L lw
# define SZREG 4
#elif __riscv_xlen == 64
# define REG_S sd
# define REG_L ld
# define SZREG 8
#else
# error unsupported __riscv_xlen
#endif

.section .text
    # we want to reduce the size of the code, so in order
    # to comply with the compressed ISA specification,
    # we will use preferably s0-s1, a0-a5 registers.
.globl _memcpy
    # void *memcpy(void *dst, void *src, size_t sz)
    # Copies sz bytes from memory area src to memory area dst.
    # The memory areas must not overlap. Uses XLEN load/store operations.
    # For mutual misaligned buffers does byte-by-byte coping.
_memcpy:
    # save initial dst value
    mv t6, a0

    # threshold for byte-by-byte copying
    li a7, 2*SZREG
    bltu a2, a7, .Lmemcpy_bytes

    # the src and dst buffers must have the same
    # alignment for load/store operations
    and a4, a0, SZREG-1
    and a5, a1, SZREG-1
    bne a4, a5, .Lmemcpy_bytes
    beqz a4, .Lmemcpy_16r

    # handle head misalignments
    sub a4, a7, a4
    sub a2, a2, a4
    add a3, a0, a4
0:  lb a5, 0(a1)
    sb a5, 0(a0)
    addi a1, a1, 1
    addi a0, a0, 1
    blt a0, a3, 0b

.Lmemcpy_16r:
    # s0, s1 must be stored by callee (according to convention)
    mv t5, s0
    mv t4, s1

    # copy 16/8/4/2/1*SZREG at one cycle iteration
0:  li a3, 16*SZREG
    bgeu a2, a3, 1f
    srli a3, a3, 1
    bgeu a2, a3, 2f
    srli a3, a3, 1
    bgeu a2, a3, 3f
    srli a3, a3, 1
    bgeu a2, a3, 4f
    srli a3, a3, 1
    bgeu a2, a3, 5f
    j .Lmemcpy_bytes

1:  REG_L a4, 8*SZREG(a1)
    REG_L a5, 9*SZREG(a1)
    REG_L s0, 10*SZREG(a1)
    REG_L s1, 11*SZREG(a1)
    REG_S a4, 8*SZREG(a0)
    REG_S a5, 9*SZREG(a0)
    REG_S s0, 10*SZREG(a0)
    REG_S s1, 11*SZREG(a0)
    REG_L a4, 12*SZREG(a1)
    REG_L a5, 13*SZREG(a1)
    REG_L s0, 14*SZREG(a1)
    REG_L s1, 15*SZREG(a1)
    REG_S a4, 12*SZREG(a0)
    REG_S a5, 13*SZREG(a0)
    REG_S s0, 14*SZREG(a0)
    REG_S s1, 15*SZREG(a0)
2:  REG_L a4, 4*SZREG(a1)
    REG_L a5, 5*SZREG(a1)
    REG_L s0, 6*SZREG(a1)
    REG_L s1, 7*SZREG(a1)
    REG_S a4, 4*SZREG(a0)
    REG_S a5, 5*SZREG(a0)
    REG_S s0, 6*SZREG(a0)
    REG_S s1, 7*SZREG(a0)
3:  REG_L a4, 2*SZREG(a1)
    REG_L a5, 3*SZREG(a1)
    REG_S a4, 2*SZREG(a0)
    REG_S a5, 3*SZREG(a0)
4:  REG_L s0, 1*SZREG(a1)
    REG_S s0, 1*SZREG(a0)
5:  REG_L s1, 0*SZREG(a1)
    REG_S s1, 0*SZREG(a0)
    add a0, a0, a3
    add a1, a1, a3
    sub a2, a2, a3
    bgeu a2, a7, 0b

    # restore s0, s1
    mv s1, t4
    mv s0, t5

.Lmemcpy_bytes:
    # byte-by-byte coping
    beqz a2, 1f
    add a3, a0, a2
0:  lb a4, 0(a1)
    sb a4, 0(a0)
    addi a1, a1, 1
    addi a0, a0, 1
    bltu a0, a3, 0b

    # return initial dst
1:  mv a0, t6
    ret


.globl _memset
    # void *memset(void *dst, int ch, size_t sz)
    #
    # Function fills the first sz bytes of the memory area
    # pointed to by dst with the constant byte ch.
    # Uses XLEN size load/stores operations.
_memset:
    # save return value
    mv t6, a0

    # threshold for byte-by-byte copying
    li a7, 2*SZREG
    bltu a2, a7, .Lmemset_bytes

    # propagate set value to whole register
    slli a5, a1, 8
    or a1, a1, a5
    slli a5, a1, 16
    or a1, a1, a5
#if __riscv_xlen == 64
    slli a5, a1, 32
    or a1, a1, a5
#endif

    # is dst aligned to register size
    and a4, a0, SZREG-1
    beqz a4, .Lmemset_16r

    # handle dst head misalignment
    sub a4, a7, a4
    sub a2, a2, a4
    add a3, a0, a4
0:  sb a1, 0(a0)
    addi a0, a0, 1
    blt a0, a3, 0b

    # store 16/8/4/2/1*SZREG at one cycle iteration
.Lmemset_16r:
    li a3, 16*SZREG
    bgeu a2, a3, 1f
    srli a3, a3, 1
    bgeu a2, a3, 2f
    srli a3, a3, 1
    bgeu a2, a3, 3f
    srli a3, a3, 1
    bgeu a2, a3, 4f
    srli a3, a3, 1
    bgeu a2, a3, 5f
    j .Lmemset_bytes

1:  REG_S a1, 8*SZREG(a0)
    REG_S a1, 9*SZREG(a0)
    REG_S a1, 10*SZREG(a0)
    REG_S a1, 11*SZREG(a0)
    REG_S a1, 12*SZREG(a0)
    REG_S a1, 13*SZREG(a0)
    REG_S a1, 14*SZREG(a0)
    REG_S a1, 15*SZREG(a0)
2:  REG_S a1, 4*SZREG(a0)
    REG_S a1, 5*SZREG(a0)
    REG_S a1, 6*SZREG(a0)
    REG_S a1, 7*SZREG(a0)
3:  REG_S a1, 2*SZREG(a0)
    REG_S a1, 3*SZREG(a0)
4:  REG_S a1, 1*SZREG(a0)
5:  REG_S a1, 0*SZREG(a0)
    add a0, a0, a3
    sub a2, a2, a3
    bgeu a2, a7, .Lmemset_16r

.Lmemset_bytes:
    # handle tail misalignment
    beqz a2, 1f
    add a3, a0, a2
0:  sb a1, 0(a0)
    addi a0, a0, 1
    bltu a0, a3, 0b

    # return initial a0
1:  mv a0, t6
    ret


.globl _memmove
    # void *memmove(void *dst, void *src, size_t sz)
    #
    # Function copies sz bytes from memory area src to memory area dst.
    # The memory areas may overlap. Copies using 8/4/2/1 bytes load/stores
_memmove:
    # save a0, s1, ra
    mv t6, a0
    mv t4, s1
    mv t3, ra

    # threshold for byte-by-byte copying
    li s1, 2*SZREG

    # copy from the end if dst > src
    bltu a1, a0, .Lmemmove_r

    bltu a2, s1, .Lmemmove_1b

    # a5 = src - dst
    sub a5, a1, a0

#if __riscv_xlen == 64
    # use 8 bytes load/stores if buffers mutual
    # aligned and src - dst > 8 bytes
    li s1, 8
    bltu a5, s1, 1f
    and a3, a0, 7
    and a4, a1, 7
    beq a3, a4, .Lmemmove_8b
#endif
    # use 4 bytes load/stores if buffers mutual
    # aligned and src - dst > 4 bytes
1:  li s1, 4
    bltu a5, s1, 1f
    and a3, a0, 3
    and a4, a1, 3
    beq a3, a4, .Lmemmove_4b

#ifdef USE_HALF_WORD_LOAD_STORES
    # use 2 bytes load/stores if buffers mutual
    # aligned and src - dst > 2 bytes
1:  li s1, 2
    bltu a5, s1, 1f
    and a3, a0, 1
    and a4, a1, 1
    beq a3, a4, .Lmemmove_2b
#endif

.Lmemmove_1b:
    # copying byte-by-byte
1:  beqz a2, .Lmemmove_end
    add a4, a0, a2
0:  lb a3, 0(a1)
    sb a3, 0(a0)
    addi a1, a1, 1
    addi a0, a0, 1
    bltu a0, a4, 0b

.Lmemmove_end:
    # restore saved registers
    mv a0, t6
    mv s1, t4
    mv ra, t3
    ret

.Lmemmove_r:
    # start from the end: src += sz, dst += sz
    add a0, a0, a2
    add a1, a1, a2

    # s1 = threshold for byte-by-byte copying
    bltu a2, s1, .Lmemmove_r_1b

    # a5 = dst - src
    sub a5, a0, a1

#if __riscv_xlen == 64
    # use 8 bytes load/stores if buffers mutual
    # aligned and src - dst > 8 bytes
    li s1, 8
    bltu a5, s1, 1f
    and a3, a0, 7
    and a4, a1, 7
    beq a3, a4, .Lmemmove_r_8b
#endif

    # use 4 bytes load/stores if buffers mutual
    # aligned and src - dst > 4 bytes
1:  li s1, 4
    bltu a5, s1, 1f
    and a3, a0, 3
    and a4, a1, 3
    beq a3, a4, .Lmemmove_r_4b

#ifdef USE_HALF_WORD_LOAD_STORES
    # use 2 bytes load/stores if buffers mutual
    # aligned and src - dst > 2 bytes
1:  li s1, 2
    bltu a5, s1, 1f
    and a3, a0, 1
    and a4, a1, 1
    beq a3, a4, .Lmemmove_r_2b
#endif

.Lmemmove_r_1b:
    # copy byte-by-byte
1:  beqz a2, .Lmemmove_end
    sub a5, a0, a2
0:  addi a1, a1, -1
    addi a0, a0, -1
    lb a3, 0(a1)
    sb a3, 0(a0)
    bgtu a0, a5, 0b
    j .Lmemmove_end

    # handle head misalignment
.Lmemmove_h1b:
    sub a4, s1, a4
    sub a2, a2, a4
    add a5, a0, a4
0:  lb a3, 0(a1)
    sb a3, 0(a0)
    addi a1, a1, 1
    addi a0, a0, 1
    bltu a0, a5, 0b
    ret

.Lmemmove_r_h1b:
    sub a2, a2, a4
    sub a5, a0, a4
0:  addi a1, a1, -1
    addi a0, a0, -1
    lb a3, 0(a1)
    sb a3, 0(a0)
    bgtu a0, a5, 0b
    ret

    # macros for forward and reverse copy
    # cycles of 8/4/2 bytes at a time
.macro MM_F_CYCLE load, store
    la ra, 0f
    bnez a4, .Lmemmove_h1b
0:  div a4, a2, s1
    mul a4, a4, s1
    sub a2, a2, a4
    add a4, a0, a4
1:  \load a3, 0(a1)
    \store a3, 0(a0)
    add a1, a1, s1
    add a0, a0, s1
    bltu a0, a4, 1b
    j .Lmemmove_1b
.endm

.macro MM_R_CYCLE load, store
    la ra, 0f
    bnez a4, .Lmemmove_r_h1b
0:  div a4, a2, s1
    mul a4, a4, s1
    sub a2, a2, a4
    sub a4, a0, a4
1:  sub a1, a1, s1
    sub a0, a0, s1
    \load a3, 0(a1)
    \store a3, 0(a0)
    bltu a4, a0, 1b
    j .Lmemmove_r_1b
.endm

#if __riscv_xlen == 64
.Lmemmove_8b:   MM_F_CYCLE ld, sd
.Lmemmove_r_8b: MM_R_CYCLE ld, sd
#endif
.Lmemmove_4b:   MM_F_CYCLE lw, sw
.Lmemmove_r_4b: MM_R_CYCLE lw, sw
#ifdef USE_HALF_WORD_LOAD_STORES
.Lmemmove_2b:   MM_F_CYCLE lh, sh
.Lmemmove_r_2b: MM_R_CYCLE lh, sh
#endif
