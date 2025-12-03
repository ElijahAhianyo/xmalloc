    .include "constants.s"

    .section .text
    .p2align 4
    .type free, %function
    .global free
free:
    // x0   pointer
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    stp x19, x20, [sp, #-16]!

    // get full block
    sub x0, x0, #BLOCK_SIZE
    mov x19, x0

    mov x1, #1
    str x1, [x19, BLOCK_FREE_FIELD] // mark the block as free

1:
    // coalesce the prev block if possible
    ldr x20, [x19, BLOCK_PREV_FIELD] // block->prev
    cbz x20, 2f // only coalesce prev if free and valid
    ldr x1, [x20, BLOCK_FREE_FIELD] // block->prev->free
    cbz x1, 2f

    mov x0, x20
    bl coallesce 
    mov x19, x0

2:
    ldr x20, [x19, BLOCK_NEXT_FIELD]  // block->next
    cbz x20, 3f           // only coalesce next if free and valid pointer
    ldr x1, [x20, BLOCK_FREE_FIELD]        // block->next->free
    cbz x1, 3f
    mov x0, x19
    bl coallesce 
    mov x19, x0
3:
    // If we are the last block, release memory to shrink the heap.
    ldr x20, [x19, BLOCK_NEXT_FIELD] // get the next block
    cbnz x20, .L_free_done           // if there's a next, we're done
    ldr x20, [x19, BLOCK_PREV_FIELD] // get prev block
    cbz x20, 5f                     

4:
    // set block->prev->next to NULL
    ldr x0, [x19, BLOCK_PREV_FIELD]
    str xzr, [x0, #BLOCK_NEXT_FIELD]
    b 6f

5:
    // we are at the base
    adrp x0, base
    add x0, x0, :lo12:base
    str xzr, [x0]

6:
    // move the brk backwards to the block start
    mov x0, x19
    mov x8, SYS_BRK
    svc #0 // might need some error handling here if brk fails

.L_free_done:
    mov x0, xzr
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret 

