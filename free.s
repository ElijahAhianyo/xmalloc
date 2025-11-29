    .include "constants.s"

    .section .text
    .p2align 4
    .type free, %function
    .global free
free:
    .Lfunc_free_begin:
    .cfi_startproc
    // x0   pointer
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    stp x19, x20, [sp, #-16]!

    // get full block
    sub x0, x0, #BLOCK_SIZE
    mov x1, #1
    str x1, [x0, BLOCK_FREE_FIELD]
1:
    mov x19, x0
    ldr x0, [x19, BLOCK_PREV_FIELD] // block->prev
    cbz x0, 2f // only coalesce prev if free and valid
    ldr x1, [x0, BLOCK_FREE_FIELD] // block->prev->free
    cbz x1, 2f

    bl coallesce 
2:
    ldr x0, [x19, BLOCK_NEXT_FIELD]  // block->next
    cbz x0, 3f           // only coalesce next if free and valid pointer
    ldr x1, [x0, BLOCK_FREE_FIELD]        // block->next->free
    cbz x1, 3f
    bl coallesce 

3:
    // If we are the last block, then release memory to shrink the heap.
    ldr x0, [x19, BLOCK_NEXT_FIELD] // 
    cbnz x0, .L_free_done
    ldr x0, [x19, BLOCK_PREV_FIELD]
    cbnz x0, 5f

4:
    ldr x0, [x19, BLOCK_PREV_FIELD]
    ldr x0, [x0, BLOCK_NEXT_FIELD]
    str xzr, [x0]
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
    .cfi_endproc

