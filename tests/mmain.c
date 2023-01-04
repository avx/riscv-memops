
void * _memcpy(void *dst, const void *src, unsigned long sz);
void * _memmove(void *dst, const void *src, unsigned long sz);
void * _memset(void *dst, int ch, unsigned long sz);

void *memset(void *dst, int ch, unsigned long sz);
void *memcpy(void *dst, const void *src, unsigned long sz);
void *memmove(void *dst, const void *src, unsigned long sz);

char mem0[1024*64] __attribute__((aligned(8)));
char mem1[1024*64] __attribute__((aligned(8)));

unsigned long c_start(unsigned long a0, unsigned a1)
{
    asm volatile("nop");
    _memset(mem1, 0xa5, 16);
    asm volatile("nop");
    _memmove(&mem1[2], &mem1[0], 14);
    asm volatile("nop");
    _memcpy(&mem1[0], &mem1[2048], 1024);
    asm volatile("nop");
}
