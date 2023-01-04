    .section .text
    .global entry
entry:
.option push
.option norelax
    lla gp, __global_pointer$
.option pop
    # set up a stack for C
    lla sp, stack
    call c_start
    j .
