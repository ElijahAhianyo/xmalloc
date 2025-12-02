    .include "constants.s"
    .include "macros.s"

    .section .data

    .section .text
    .p2align 4
    .type calloc, %function
    .global calloc
calloc:
    .cfi_startproc
    // x0   n
    // x1   size


    stp x29, x30, [sp, #-16]!
    .cfi_def_cfa_offset 16
    .cfi_offset 29, -8
    .cfi_offset 30, -16

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

    // mov x4, x0
    // ldr x5, [x4, #BLOCK_SIZE]
    // add x4, x4, x5

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
    .cfi_restore 29
    .cfi_restore 30
    .cfi_def_cfa_offset 0
    ret
    .cfi_endproc
 