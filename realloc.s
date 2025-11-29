    .include "constants.s"
    .include "macros.s"

    .section .data
    // .include "data.s"
    // .include "utils.s"

    .section .text
    .p2align 4
    .type realloc, %function
    .global realloc
realloc:
    // x0   void *p
    // x1   size
    stp x29, x30, [sp, #16]!
    mov x29, sp

    stp x19, x20, [sp, #16]!
    stp x21, x22, [sp, #16]!


    mov x21, x0 // save pointer for later

    mov x2, x0
    bl valid_addr  // check if the pointer is valid
    cbz x0, err

    // align the size
    ALIGN8 x1

    mov x20, x1 // callee save size

    // get the block
    mov x0, x2
    sub x0, x0, BLOCK_SIZE

    mov x19, x0


    // coalesce next block for more space
    bl coallesce

    // check if we have enough space where we are, split and return
    // the same address
    ldr x0, [x19, BLOCK_SIZE_FIELD]
    add x1, x20, #BLOCK_SIZE

    cmp x0, x1
    blt 2f
1:
    mov x0, x19
    mov x1, x20
    bl split_block
    mov x0, x21
    b end
2:
    // there wasnt enough space
    mov x0, x20
    bl malloc // ask malloc for some
    cbz x0, err // if this failed return an error
    mov x22, x0 // save the new pointer
    sub x0, x0, BLOCK_SIZE

    // copy contents over to new block if necessary
    mov x1, x19
    bl copy_block

    // release the old memory
    mov x0, x21
    bl free
    mov x0, x22

 err:
    mov x0, xzr   

end:

    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16

    ret
