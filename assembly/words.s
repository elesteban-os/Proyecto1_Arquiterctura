.text
.global _start
_start:
    mov r0, #4
    mov r1, #7
    mov r5, #0

    # Salida sistema
    mov r7, #1
    swi 0