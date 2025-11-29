

    .include "constants.s"

 .section .text
    .p2align 4
    .type find_block, %function
    .global find_block
find_block:
    .Lfunc_find_block_begin:
    .cfi_startproc
    // x0-> last block
    // x1-> size we want
    mov x3, xzr
    adrp x3, base;
    add x3, x3, :lo12:base
loop:
    cbz x3, end_loop
    ldr x4, [x3, BLOCK_FREE_FIELD] // get the free block
    cbz x4, end_loop
    mov x0, x3
    ldr x3, [x3, BLOCK_NEXT_FIELD] // get the next block
    b loop


end_loop:
    mov x0, x3
    ret 
    .Lfunc_find_block_end:
    .cfi_endproc

    .section .text
    .type extend_heap, %function
    .global extend_heap
extend_heap:
    .cfi_startproc
    stp x29, x30, [sp, #-16]!
    .cfi_def_cfa_offset 16
    .cfi_offset 29, -16
    .cfi_offset 30, -8
    mov x29, sp
    stp x19, x20, [sp, #-16]!   //save x19, x20
    stp x21, x22, [sp, #-16]!    // save x21, x22 (we'll use x21 for size)
    .cfi_def_cfa_offset 48
    /* Args:
     x0 -> last (prev block pointer) (may be zero)
     x1 -> size to extend by (in bytes)
    */

    // calle save the args
    mov x19, x0     // x19 = last
    mov x21, x1     //  x21 = size

    // get the current program brk(sbrk(0))
    mov x0, #0
    bl sbrk
    mov x20, x0 // x20 = old_brk (block header start for new block)

    // compute new brk = old_brk + size + BLOCK_SIZE
    add x0, x21, BLOCK_SIZE // increase the current brk by the size + BLOCK_FiELD
    bl sbrk
    
    // check for error: -1 return means failure!
    cmp x0, #-1
    beq error

    // initialize the new block starting at the old_brk
    str x21, [x20]                  // block->size = size
    str x19, [x20, BLOCK_PREV_FIELD] // block->prev = last
    mov x5, #1
    str x5, [x20, BLOCK_FREE_FIELD] // block->free = 1
    add x4, x20, BLOCK_SIZE         // calculate the data start point
    str x4, [x20, BLOCK_PTR_FIELD]  // block->ptr = data(block + BLOCK_SIZE)

    // if this is the first block(last==0), set the base (base = x20)
    cbnz x19, .L_extend_skip_set_base
    adrp x0, base
    add x0, x0, :lo12:base
    str x20, [x0]   // base = x20

.L_extend_skip_set_base:
    // if the last node is not null, we update its 
    // next node (last->next = new block)
    cbz x19, .L_extend_after_link
    str x20, [x19, BLOCK_NEXT_FIELD]

.L_extend_after_link:
    mov x0, x20 // return the current brk(which should be the start of the newly alloc block)
    b epilogue

error:
    // return NULL
    mov x0, NULL
    b epilogue


epilogue:
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    .cfi_restore 19
    .cfi_restore 29
    .cfi_restore 30
    .cfi_endproc
    ret
    .size extend_heap, (. - extend_heap)



    .section .text
    .p2align 4
    .type split_block, %function
    .global split_block
split_block:
    .Lfunc_split_block_begin:
    .cfi_startproc
    // x0 -> block
    // x1 -> size

    /*
    create a new block whose size is old_block->size - size - BLOCK_SIZE
    then link the old block to it
    */

    // mov x2, x0 // block
    mov x2, x1 // size
    ldr x3, [x0, BLOCK_SIZE_FIELD]
    sub x2, x3, x2 //new size

    // new block
    add x3, x0, x2      // block + size = new_block 
    add x3, x3, BLOCK_SIZE

    // fill in the details of the new block
    str x2, [x3] // size (should we move an extra byte here?)
    mov x4, #1
    str x4, [x3, BLOCK_FREE_FIELD]
    // newblock->next should point to block->next
    ldr x4, [x0, BLOCK_NEXT_FIELD]
    str x4, [x3, BLOCK_NEXT_FIELD]

    // new_block->prev = block
    str x0, [x3, BLOCK_PREV_FIELD] 

    // new_block->ptr = new_block->data
    add x5, x0, BLOCK_SIZE
    str x5, [x3, BLOCK_PTR_FIELD]

    str x2, [x0]
    str x3, [x0, BLOCK_NEXT_FIELD]

    //if the new_block has a next node, we should update that.
    ldr x4, [x3, BLOCK_NEXT_FIELD]
    cmp x4, xzr
    beq .L_split_block_done

update_new_block_next:
    ldr x4, [x4]
    str x3, [x4, BLOCK_PREV_FIELD]
    b .L_split_block_done

.L_split_block_done:
    mov x0, xzr

    ret
    .cfi_endproc
    .Lfunc_split_block_end:

    //To validate an address or a pointer, it must meet the ff conditions:
    // 1. It should be within the acceptable heap range. i.e higher than the base and 
    // lower than sbrk(0).
    // 2. The pointer should be the same as its ptr/data member.

    .section .text
    .p2align 4
    .type valid_addr, %function
    .global valid_addr
valid_addr:
    .Lfunc_valid_addr_begin:
    .cfi_startproc
    //  x0  pointer to data(*p)

    stp x29, x30, [sp, #-16]!
    .cfi_def_cfa_offset 16
    .cfi_offset 29, -16
    .cfi_offset 30, -16
    mov x29, sp

    str x19, [sp, #16]!

    mov x2, xzr
    adrp x2, base
    add x2, x2, :lo12:base // heap start

    mov x19, x0 // calle save data
    cbz x19, ret_zero // check if *p is valid

    mov x0, xzr // get heap end
    bl sbrk

    mov x3, x0 // save heap end 

    cmp x19, x2
    blt ret_zero // if *p < heap_start, that's an error!

    cmp x19, x3
    bgt ret_zero // if *p > heap_end, that's an error!

    sub x4, x19, BLOCK_SIZE // get the full block(data including metadata)
    ldr x5, [x4, BLOCK_PTR_FIELD]
    cmp x4, x5   // compare block->ptr == p (this should ensure that the point to the same loc)
    bne ret_zero
    mov x0, #1

    b .L_valid_addr_done
ret_zero:
    mov x0, NULL
    b .L_valid_addr_done

.L_valid_addr_done:
    ldp x29, x30, [sp], #16
    .cfi_restore 29
    .cfi_restore 30
    .cfi_def_cfa_offset 0
    ret
    .cfi_endproc
    .Lfunc_valid_addr_end:


    .section .text 
    .p2align 4
    .type copy_block, %function
    .global copy_block
copy_block:
    .cfi_startproc
    // xo -> destination
    // x1-> src

    // get the data/ptr start
    add x2, x0, BLOCK_PTR_FIELD // dst
    add x3, x1, BLOCK_PTR_FIELD // src

    //obtain sizes
    ldr x4, [x2]
    ldr x5, [x3]
    lsr x4, x4, #8
    lsr x5, x5, #8

    cmp x4, x5
    csel x4, x4, x5, lt

    mov x5, #0
.L_copy_block_loop:
    cmp x4, x5
    beq .L_copy_block_done
    ldr x6, [x3, x5]
    str x6, [x2, x5]
    add x5, x5, #1
    b .L_copy_block_loop

.L_copy_block_done:
    mov x0, xzr
    ret
    .cfi_endproc
    


    .section .text
    .p2align 4
    .type coallesce, %function
    .global coallesce
coallesce:
    .Lfunc_coallesce_begin:
    .cfi_startproc

    // x0 -> block
    ldr x1, [x0, BLOCK_NEXT_FIELD] // block->next(next block)
    cmp x1, xzr
    beq return_block
    ldr x2, [x1, BLOCK_FREE_FIELD]
    cmp x2, #1
    bne return_block
    mov x3, #0
    ldr x4, [x0, BLOCK_SIZE_FIELD]
    add x3, x4, BLOCK_SIZE

    ldr x5, [x1]
    add x3, x5, x3
    str x3, [x0]

    //block->next = block->next->next
    ldr x4, [x1, BLOCK_NEXT_FIELD] // block->next->next
    str x4, [x1, BLOCK_NEXT_FIELD]

    // if the new block->next, we should update its prev too
    cmp x1, xzr
    beq return_block
    str x0, [x1, BLOCK_PREV_FIELD]

return_block:
    ret 
    .cfi_endproc
    .Lfunc_coallesce_end:



