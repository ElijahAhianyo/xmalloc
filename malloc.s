    .include "constants.s"
    .include "macros.s"

    .section .text
    .p2align 4
    .type malloc, %function
    .global malloc
malloc:
    .cfi_startproc
    /* Args
    x0    size_t size
    */
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    stp x19, x20, [sp, #-16]!


    mov x1, x0
    ALIGN8 x1// align size (this should make the size 8bytes alinged)
    
    // Get the base/heap start
    adrp x2, base   // get base
    add x2, x2,  :lo12:base 
    ldr x6, [x2]

    // If there is no base, this is the first ever allocation so ask for heap extension.
    cbz x6, .L_no_base



1:
    mov x0, x6
    bl find_block
    mov x6, x1 // find_block returns the updated last block in x1
    cbz x0, .L_not_found
    mov x19, x0 

    /* decide whether to split the block on the condition:
    remaining = block->size - size(aligned)
    if remaining >= BLOCK_SIZE + 8 then we can split. This practically means
    we have space to store at least one arch/system size data
    */
    ldr x3, [x19, #BLOCK_SIZE_FIELD]    // x3 = block->size
    sub x4, x3, x1                      // remaining(x4) = block->size - aligned_size
    mov x5, #BLOCK_SIZE
    add x5, x5, #8                      // x5 = BLOCK_SIZE + 8
    cmp x4, x5
    blt .L_no_split
    
    // split block
    mov x0, x19
    bl split_block
    b .L_no_split

.L_not_found:
    // Not suitable free block was found, so lets extend the heap to get more space
    mov x0, x6
    bl extend_heap
    cbz x0, ret_error // heap extend failed
    mov x19, x0
    b .L_no_split

.L_no_base:
    // perhaps we can refactor this with 2; since they are literally the same?
    mov x0, xzr
    bl extend_heap
    cbz x0, ret_error // heap extend failed

    mov x19, x0
    // mark field as used
    str xzr, [x19, #BLOCK_FREE_FIELD]
    // update base as the first block(base = x19)
    adrp x3, base
    add  x3, x3, :lo12:base
    str x19, [x3]
    b ret_data

.L_no_split:
    str xzr, [x19, BLOCK_FREE_FIELD]    // set b->free to 0


ret_data:
    // return the pointer(or data section) block->ptr 
    ldr x0, [x19, BLOCK_PTR_FIELD]
    b .L_malloc_done
    
ret_error:
    mov x0, NULL

.L_malloc_done:
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
