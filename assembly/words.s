.global _start

.section .data
buffer:      .space 10485760            @ Espacio de 10MB para almacenar datos leídos

@ Parte de punteros / diccionario (estructura: 8 bytes ubicacion palabra, 2 bytes cantidad caracteres, 6 bytes cantidad apariciones)
pos_words:    .space 800000            @ Espacio para guardar las palabras encontradas
num_char:     .space 200000            @ Espacio para guardar la cantidad de caracteres de palabra
num_times:    .space 400000            @ Espacio para guardar la cantidad de veces que aparece una palabra
num_words:    .space 6250              @ Cantidad de palabras que existen

dictionary:   .space 1400000 

@ Para guardar caracteres y palabras
character:    .space 1                   @ Espacio de un byte para un caracter
word:         .space 30                  @ Espacio de 30 bytes para guardar una palabra

@ Manejo del archivo
filename:       .asciz "../cache/text.txt"     @ Ubicacion del 
filedata:      .space 48

open_fail_text: .asciz "No se pudo abrir el archivo\n"
read_fail_text: .asciz "No se pudo leer el archivo\n"
newline:        .asciz "\n"

.section .bss
    statbuf: .space 100

.section .text

_start:
    @ Programa pasa a openfile

openfile:
    @ Abrir archivo con sys_open
    ldr r0, =filename   @ Cargar ubicacion archivo
    mov r1, #0          @ Modo lectura
    mov r7, #5          @ Syscall open
    swi 0               @ Syscall

    mov r4, r0          @ Ubicacion de archivo a r4

    @ Verificar si se abrio el archivo
    cmp r0, #0          @ Verifica que se abrio el archivo
    blt open_fail       @ Si r0 < 0 no abrio

    @ Obtener el tamano del archivo
    mov r0, r4          @ Ubicacion de archivo
    ldr r1, =statbuf   @ Puntero a filedata
    mov r7, #108          @ Syscall fstat
    swi 0               @ Syscall

    ldr r2, =statbuf   @ Puntero a filedata
    ldr r11, [r2, #0]  @ Tamano del archivo se encuentra sumando offset de 40

readfile:
    @ Leer el archivo con sys_read
    mov r0, r4        @ Ubicacion de archivo
    ldr r1, =buffer    @ Direccion de buffer para guardar datos
    mov r2, r11      @ Leer 256 bytes (enviar dato de buffer con python)
    mov r7, #3          @ Syscall de read
    swi 0               @ 

    @ Syscall de close
    mov r0, r4
    mov r7, #6
    swi 0

    mov r12, r1         @ Cambiar de registro el buffer

    cmp r0, #0          @ Verifica que se lee el archivo
    blt read_fail       @ Si r0 < 0 no se leyo el archivo

    mov r4, #0
    b pre_readword          @ Ir al siguiente paso

pre_readword:
    ldr r5, =word
    @ r6: Indice de diccionario.
    ldr r10, =dictionary @ Ubicacion en memoria diccionario

read_firstword:
    ldrb r3, [r12], #1  @ Cargar letra en r3, buffer r12, se suma 1 a r12 para mover el cursor

    @ Comparar a ver si es el final del texto
    cmp r3, #0 
    beq endoftext

    @ Comparar si es un salto de linea
    cmp r3, #10
    beq endof_firstword

    @ Ir guardando la palabra en word con offset en el indice r4
    strb r3, [r5, r4]

    @ Sumar el indice de caracteres y mover el offset de word (tambien funciona como cantidad de caracteres)
    add r4, r4, #1    

    @ Continuar loop
    b read_firstword

endof_firstword:
    @ Imprimir en pantalla la palabra   
    bl printword
    ldr r1, =newline
    bl print
    
    @ Agregar palabra en el diccionario
    bl addword
    
    @ Reiniciar indice de word
    mov r4, #0

    @ Seguir con el texto del buffer
    b readword

readword:
    ldrb r3, [r12], #1  @ Cargar letra en r3, buffer r12, se suma 1 a r12 para mover el cursor

    @ Comparar a ver si es el final del texto
    cmp r3, #0 
    beq endoftext

    @ Comparar si es un salto de linea
    cmp r3, #10
    beq endofword

    @ Ir guardando la palabra en word con offset en el indice r4
    strb r3, [r5, r4]

    @ Sumar el indice de caracteres y mover el offset de word (tambien funciona como cantidad de caracteres)
    add r4, r4, #1    

    @ Continuar loop
    b readword

endoftext:
    @ Imprimir en pantalla la palabra
    bl printword
    ldr r1, =newline
    bl print


    b end

endofword:
    @ Imprimir en pantalla la palabra   
    bl printword
    ldr r1, =newline
    bl print

    @ Buscar en el diccionario

    @ Agregar palabra en el diccionario
    bl addword
    
    @ Reiniciar indice de word
    mov r4, #0

    @ Seguir con el texto del buffer
    b readword

addword:
    @ Agregar palabra al diccionario ([8B: puntero en el buffer, 2B: #caracteres, 6B: cantidad apariciones])
    @ R7: direccion de diccionario (cursor se mueve)
    @ R12: indice en el buffer (restar cantidad caracteres)
    @ R4: cantidad caracteres
    @ Apariciones = 0
    
    @ Obtener la posicion en memoria de la palabra (Indice buffer - cantidad caracteres)
    mov r8, r12
    sub r8, r8, r4

    @ Guardar direccion memoria del primer caracter de la palabra en el buffer
    str r8, [r10]

    @ Guardar cantidad caracteres de la palabra
    str r4, [r10, #8]

    @ Cantidad apariciones = 0
    mov r8, #0
    str r8, [r10, #10]

    @ Mover cursor de diccionario:
    add r10, r10, #16

    @ Regresar al branch link
    bx lr 

print:
    @ Print
    mov r0, #1  @ STDOUT = 1
    @ r1 contiene la direccion de memoria de lo que se va a imprimir
    mov r2, #1  @ Cantidad caracteres
    mov r7, #4  @ Para syscall write
    swi 0   
    bx lr 
    
printword:
    @ Print
    mov r0, #1  @ STDOUT = 1
    ldr r1, =word    @ r1 contiene la direccion de memoria de lo que se va a imprimir
    mov r2, r4  @ Cantidad caracteres
    mov r7, #4  @ Para syscall write
    swi 0   
    bx lr



open_fail:
    ldr r1, =open_fail_text       @ Mostrar mensaje de error si el archivo no se abre
    b end

read_fail:
    ldr r1, =read_fail_text       @ Mostrar mensaje de error si no se pudo leer

pruebadiccionarios:
    ldr r0, =dictionary
    b pruebadiccionarios2

pruebadiccionarios2:
    ldr r1, [r0]
    ldr r2, [r0, #8]
    ldr r3, [r0, #10]
    add r0, r0, #16
    b pruebadiccionarios2
    

end:

    @ Prueba de diccionarios
    b pruebadiccionarios

    @ Print
    mov r0, #1  @ STDOUT = 1

    ldr r1, =dictionary   @ r1 contiene la direccion de memoria de lo que se va a imprimir
    mov r2, #30000  @ Cantidad caracteres
    mov r7, #4  @ Para syscall write
    swi 0  
 

    @ Salida sistema
    mov r7, #1          @ Número de syscall para exit
    swi 0
    .end

