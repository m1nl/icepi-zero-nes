#include <stddef.h>
#include <stdio.h>

#include "tlsf.h"
#include "heap.h"

__attribute__((noreturn)) void __assert_no_args(void);
__attribute__((noreturn)) void __assert_no_args(void)
{
    printf("assert failed\n");
    while (1);
}

extern char _fheap;
extern char _eheap;

static tlsf_t _tlsf;

void heap_init(void)
{
    size_t size = (size_t)(&_eheap - &_fheap);
    _tlsf = tlsf_create_with_pool(&_fheap, size);
    printf("heap: %u bytes at 0x%08lx\n", (unsigned)size, (unsigned long)&_fheap);
}

void *malloc(size_t size)
{
    return tlsf_malloc(_tlsf, size);
}

void *realloc(void *ptr, size_t size)
{
    return tlsf_realloc(_tlsf, ptr, size);
}

void free(void *ptr)
{
    tlsf_free(_tlsf, ptr);
}
