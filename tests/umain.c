#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// memops.S
void * _memcpy(void *dst, const void *src, unsigned long sz);
void * _memmove(void *dst, const void *src, unsigned long sz);
void * _memset(void *dst, int ch, unsigned long sz);

#define BUFSIZE	256*1024

char a[BUFSIZE] __attribute__((aligned(8)));
char b[BUFSIZE] __attribute__((aligned(8)));

void init()
{
    for (int i=0; i < BUFSIZE; i++)
        a[i] = b[i] = i & 0xff;
}

int eq(int l, int i, int j)
{
    for (int i=0; i < BUFSIZE; i++) {
        if (a[i]!=b[i]) {
            printf("a[%d] (%x) != b[%d] (%x), line=%d, i=%d, j=%d\n", i, a[i], i, b[i], l, i, j);
            exit(-1);
        }
    }
    return 0;
}

int memset_test()
{
    int i,j;

    for (i = 0; i < 513; i++) {
        printf("memset test... %d/513\n", i+1);
        for(j = 0; j < 32; j++) {
            init();
            memset(&a[j], 0x99, i);
            _memset(&b[j], 0x99, i);
            eq(__LINE__, i, j);
        }
    }

    for (i = 0; i < 65536; i+=123) {
        printf("memset test... %d/65536\n", i);
        for(j = 0; j < 15; j++) {
            init();
            memset(&a[j], 0x99, i);
            _memset(&b[j], 0x99, i);
            eq(__LINE__, i, j);
        }
    }
}

int memcpy_test()
{
    int i,j;

    for (i = 0; i < 513; i++) {
        printf("memcpy test 8b aligned... %d/513\n", i+1);
        for(j = 0; j < 33; j++) {
            init();
            memcpy(&a[0 + i], &a[BUFSIZE/2 + i], i);
            _memcpy(&b[0 + i], &b[BUFSIZE/2 + i], i);
            eq(__LINE__, i, j);
        }
    }

    for (i = 0; i < 257; i++) {
        printf("memcpy test 4b aligned... %d/257\n", i+1);
        for(j = 0; j < 33; j++) {
            init();
            memcpy(&a[0 + i], &a[BUFSIZE/2 + i + 4], i);
            _memcpy(&b[0 + i], &b[BUFSIZE/2 + i + 4], i);
            eq(__LINE__, i, j);
        }
    }

    for (i = 0; i < 257; i++) {
        printf("memcpy test 2b aligned... %d/257\n", i+1);
        for(j = 0; j < 33; j++) {
            init();
            memcpy(&a[0 + i], &a[BUFSIZE/2 + i + 6], i);
            _memcpy(&b[0 + i], &b[BUFSIZE/2 + i + 6], i);
            eq(__LINE__, i, j);
        }
    }

    for (i = 0; i < 257; i++) {
        printf("memcpy test 1b aligned... %d/257\n", i+1);
        for(j = 0; j < 33; j++) {
            init();
            memcpy(&a[0 + i], &a[BUFSIZE/2 + i + 7], i);
            _memcpy(&b[0 + i], &b[BUFSIZE/2 + i + 7], i);
            eq(__LINE__, i, j);
        }
    }

    for (i = 0; i < 65536; i+=123) {
        printf("memcpy test... %d/65536\n", i);
        for(j = 0; j < 15; j++) {
            init();
            memcpy(&a[j], &a[BUFSIZE/2 + j], i);
            _memcpy(&b[j], &b[BUFSIZE/2 + j], i);
            eq(__LINE__, i, j);
        }
    }
}

int memmove_test()
{
    int i,j,l = 0;

    init();
    for (l = 0; l < 23; l++) {
        for (j = 0; j < 98; j++) {
            printf("memmove test... offs=%d |dst-src|=%d, lens = 0..65\n", l, j);
            for (i = 0; i < 66; i++) {

                memmove(&a[l+0], &a[l+j], i);
                _memmove(&b[l+0], &b[l+j], i);
                eq(__LINE__, i, j);

//                init();
                memmove(&a[l+j], &a[l+0], i);
                _memmove(&b[l+j], &b[l+0], i);
                eq(__LINE__, i, j);
           }
        }
    }
}

int main()
{
    memmove_test();
    memcpy_test();
    memset_test();
}
