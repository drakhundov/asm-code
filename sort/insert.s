@ ARM Cortex-M0+ / Thumb-1 / GNU syntax (armclang or arm-none-eabi-as)

        .syntax unified
        .cpu cortex-m0plus
        .thumb

        .equ DIGITS, 150220926

        .data
        .balign 4
ARRAY:  .space 36                @ Nine 32-bit words

        .text
        .global __main
        .type __main, %function
        .type INSERTION_SORT, %function

__main:
        LDR  R0, =DIGITS
        LDR  R1, =DIVISORS
        LDR  R2, =ARRAY
        MOVS R5, #9

NEXT_DIGIT:
        LDR  R4, [R1]
        MOVS R3, #0
EXTRACT_DIGIT:
        CMP  R0, R4
        BLO  DIGIT_READY
        SUBS R0, R0, R4
        ADDS R3, R3, #1
        B    EXTRACT_DIGIT
DIGIT_READY:
        STR  R3, [R2]
        ADDS R1, R1, #4
        ADDS R2, R2, #4
        SUBS R5, R5, #1
        BNE  NEXT_DIGIT

        LDR  R0, =ARRAY           @ R0: base address
        MOVS R1, #9              @ R1: element count
        BL   INSERTION_SORT

STOP:
        B    STOP                @ Inspect ARRAY in Memory window

@ =============================================================
@ Register roles:
@   R0 = &A[0]  base address (input, never changed)
@   R1 = n      element count (input, never changed)
@   R2 = i      outer index, 1 .. n-1
@   R3 = key    A[i], the value being inserted
@   R4 = &A[j]  address of the element compared against the key;
@               j = -1 is reached when R4 = base - 4
@   R5 = A[j]   value loaded from R4
@ R4 and R5 are callee-saved, so they are pushed and popped.
@ All comparisons are unsigned (BHS/BLO/BLS): elements are unsigned words.

@Optimized Insertion Sort.

INSERTION_SORT:
        PUSH {R4, R5}            @ save callee-saved regs we use
        
        @ Use memory addresses instead of counters
        @   to avoid conversion at each step.
        LSLS R1, R1, #2          @ R1 = n*4
        ADDS R1, R0, R1          @ R1 = &A[n]
        ADDS R2, R0, #4          @ R2 = &A[1], i=1

        @ Outer loop: insert A[i] into the sorted prefix A[0..i-1]
OUTER_LOOP:
        CMP  R2, R1              @ i < n ?
        BHS  SORT_DONE           @ i >= n -> whole array sorted

        LDR  R3, [R2]            @ key = A[i]
        SUBS R4, R2, #4          @ R4 = &A[j], j = i - 1
        LDR R5, [R4]             @ R5 = A[j]
        
        @ If alredy in order, no shift.
        @ Use this condition because on average
        @   array is going to be unordered.
        CMP R5, R3
        BLS NEXT_OUTER

        @ Inner loop: shift elements greater than key one word right
SHIFT_LOOP:
        STR R5, [R4, #4]         @ A[j + 1] = A[j]
        CMP  R4, R0              @ j == 0 ?
        BEQ  INSERT_AT_FRONT     @ A[0] = A[i]
        SUBS R4, R4, #4          @ ptr_j--
        LDR R5, [R4]             @ R5 = A[j]
        CMP  R5, R3              @ A[j] > key ?
        BHI SHIFT_LOOP

        @ Found the right place.
        STR R3, [R4, #4]
        B NEXT_OUTER

INSERT_AT_FRONT:
        STR R3, [R0]

NEXT_OUTER:
        ADDS R2, R2, #4          @ R2 = &A[i++]
        B OUTER_LOOP

SORT_DONE:
        POP  {R4, R5}            @ restore R4, R5
        BX LR

        .balign 4
DIVISORS:
        .word 100000000, 10000000, 1000000
        .word 100000, 10000, 1000, 100, 10, 1

        .end
