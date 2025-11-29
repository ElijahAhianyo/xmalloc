/* ALIGN8 reg
 * Align the value in reg **upward** to the next 8-byte boundary (in-place).
 *
 * Alignment Formula:
 *     aligned = (value + (alignment - 1)) & ~(alignment - 1)
 *
 * For alignment = 8(since we're on a 64 bit machine):
 *     aligned = (value + 7) & ~7
 *
 * So this macro computes:
 *     reg := (reg + 7) & ~7
 *
 * Usage:
 *    ALIGN8 x0
 *    // x0 now contains the 8-byte aligned result
 */
.macro ALIGN8 reg:req
    add \reg, \reg, #7
    bic \reg, \reg, #7    // reg &= ~7  (clear low 3 bits)
.endm
