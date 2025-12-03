    .include "constants.s"
    .include "macros.s"

    .section .data

    .section .text
    .p2align 4
    .type calloc, %function
    .global calloc
calloc:
    /*
        x0   n
        x1   size
    */


    stp x29, x30, [sp, #-16]!

    mul x0, x0, x1

    ALIGN8 x0  // align size
    

    mov x1, x0 // we still need size for later

    bl malloc
    cmp x0, NULL
    beq .L_calloc_ret_error
    
    //malloc returns the data pointer, so get the block start
    sub x2, x0, BLOCK_SIZE
    ldr x2, [x2] // get size


    lsr x2, x2, #3 // get number of iterations per pointer size(size/ 8)
    mov x3, #0

    // zero the data portion
1:  
    cmp x3, x2
    bge .L_calloc_done
    str xzr, [x0, x3, lsl #3]
    add x3, x3, #1
    b 1b


.L_calloc_ret_error:
    mov x0, NULL

.L_calloc_done:
    ldp x29, x30, [sp], #16
    ret
 