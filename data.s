.section .data
.p2align 3 // as a rule data sections should be 8 bytes aligned and text should be 16 to satisfy the ABI
.global base
base:
    .skip 8
