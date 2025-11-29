/* ALIGN8 reg
 * Align the value in reg up to an 8-byte boundary (in-place).
 * Effect: reg := (reg + 7) & ~7
 *
 * Usage:
 *    ALIGN8 x0
 *    // x0 now contains the aligned result
 */
.macro ALIGN8 reg:req
    add \reg, \reg, #7
    bic \reg, \reg, #7    /* reg &= ~7  (clear low 3 bits) */
.endm
