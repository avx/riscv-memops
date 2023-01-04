CC ?= riscv64-unknown-elf-gcc

RISCV32_ABI = ilp32
RISCV32_ISA = rv32imafdc_zicsr_zifencei
RISCV32_CODE_MODEL = medany

RISCV64_ABI = lp64
RISCV64_ISA = rv64imafdc_zicsr_zifencei
RISCV64_CODE_MODEL = medany

CFLAGS = -g3 -ggdb -O2 -mrelax
CFLAGS64 = $(CFLAGS) -mabi=$(RISCV64_ABI) -march=$(RISCV64_ISA) -mcmodel=$(RISCV64_CODE_MODEL)
CFLAGS32 = $(CFLAGS) -mabi=$(RISCV32_ABI) -march=$(RISCV32_ISA) -mcmodel=$(RISCV32_CODE_MODEL)

all: u64 u32 m64 m32

m64: memops.S tests/mmain.c tests/entry.S tests/memops.c
	riscv64-unknown-elf-gcc $(CFLAGS64) -Wl,-T tests/main.ld -nostdlib \
	tests/entry.S tests/mmain.c memops.S tests/memops.c -o m64

m32: memops.S tests/mmain.c tests/entry.S
	riscv64-unknown-elf-gcc $(CFLAGS32) -Wl,-T tests/main.ld -nostdlib \
	tests/entry.S tests/mmain.c memops.S tests/memops.c -o m32

u64: memops.S tests/umain.c
	riscv64-unknown-elf-gcc $(CFLAGS64) tests/umain.c memops.S -o u64

u32: memops.S tests/umain.c
	riscv64-unknown-elf-gcc $(CFLAGS32) tests/umain.c memops.S -o u32

qu64:
	qemu-riscv64 ./u64
qu32:
	qemu-riscv32 ./u32
spike64:
	spike --isa=RV64IMAFDC -l ./m64
spike32:
	spike --isa=RV32IMAFDC -l ./m32

clean:
	rm -rf u64 u32 m64 m32

.PHONY: clean qu64 qu32 spike64 spike32
