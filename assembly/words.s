.global _start

.data
buffer:     .space 10485760            @ Espacio de 10MB para almacenar datos leídos
filename:   .asciz "../cache/text.txt"     @ Ubicacion del archivo
open_fail_text: .asciz "No se pudo abrir el archivo\n"
read_fail_text: .asciz "No se pudo excribir el archivo\n"

.text

_start:
    @ Programa pasa a openfile

openfile:
    @ Abrir archivo con sys_open
    ldr r0, =filename   @ Cargar ubicacion archivo
    mov r1, #0          @ Modo lectura
    mov r7, #5          @ Syscall open
    swi 0               @ Syscall

    @ Verificar si se abrio el archivo
    cmp r0, #0          @ Verifica que se abrio el archivo
    blt open_fail       @ Si r0 < 0 no abrio

    mov r4, r0          @ ??

    @b readfile          @ Se lee el archivo

readfile:
    @ Leer el archivo con sys_read
    mov r0, r4          @ Ubicacion de archivo
    ldr r1, =buffer     @ Direccion de buffer para guardar datos
    mov r2, #256        @ Leer 256 bytes (enviar dato de buffer con python)
    mov r7, #3          @ Syscall de read
    swi 0               @ Syscall

    cmp r0, #0          @ Verifica que se lee el archivo
    blt read_fail       @ Si r0 < 0 no se leyo el archivo

    b end               @ Ir al siguiente paso


open_fail:
    ldr r1, =open_fail_text       @ Mostrar mensaje de error si el archivo no se abre
    b end

read_fail:
    ldr r1, =read_fail_text       @ Mostrar mensaje de error si no se pudo leer

end:
    @ Print
    mov r0, #1
    mov r2, #600
    mov r7, #4
    swi 0

    @ Salida sistema
    mov r7, #1          @ Número de syscall para exit
    swi 0
    .end

