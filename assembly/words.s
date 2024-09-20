.global _start

.section .data
buffer:      .space 10485760            @ Espacio de 10MB para almacenar datos leídos

@ Parte de punteros / diccionario (estructura: 8 bytes ubicacion palabra, 2 bytes cantidad caracteres, 6 bytes cantidad apariciones)
dictionary:   .space 1400000 
resulttext:   .space 1000    @ Espacio para escribir el resultado de las palabras con mas frecuencias

@ Para guardar caracteres y palabras
character:    .space 1                   @ Espacio de un byte para un caracter
word:         .space 30                  @ Espacio de 30 bytes para guardar una palabra

@ Manejo del archivo
filename:       .asciz "../cache/text.txt"     @ Ubicacion del archivo
filedata:      .space 48
fileresult:     .asciz "../cache/result.txt"

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
    @bl printword
    @ldr r1, =newline
    @bl print
    
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

endofword:
    @ Imprimir en pantalla la palabra   
    @bl printword
    @ldr r1, =newline
    @bl print

    @ Buscar en el diccionario
    bl pre_searchword  

    @ Reiniciar indice de word
    mov r4, #0


    @ Seguir con el texto del buffer
    b readword

endoftext:
    @ Imprimir en pantalla la palabra
    @bl printword
    @ldr r1, =newline
    @bl print

    @ Buscar en el diccionario
    bl pre_searchword

    @ Crear texto del diccionario
    ldr r0, =dictionary     @ Direccion inicial diccionario
    ldr r2, =resulttext     @ Direccion del resultado (texto del .txt para python)
    b createtext

createtext:
    @ Crear texto de palabras y frecuencias para pasarlo a python por medio de un .txt   
    @ Saber si se llego al final del diccionario
    cmp r0, r10
    beq createtxt

    @ Pasar texto
    ldr r8, [r0]            @ Obtener posicion inicial memoria de palabra 
    ldrb r5, [r0, #8]       @ Obtener cantidad caracteres
    mov r7, #0              @ Indice caracteres
    bl writetext

    @ Escribir espacio
    mov r11, #32
    strb r11, [r2], #1

    @ Pasar frecuencias
    ldr r11, [r0, #10]
    add r11, #32            @ Sumar 32 para que aparezca como un simbolo. En python hay que restarle 32
    str r11, [r2], #6

    @ Escribir salto de linea
    mov r11, #10
    str r11, [r2], #1

    @ Continuar bucle
    add r0, r0, #16
    b end




writetext:
    @ Comparar si llego al final de palabra
    cmp r5, r7
    beq writetext_end

    @ Sumar indice
    add r7, r7, #1

    @ Pasar letra
    ldr r9, [r8], #1        @ Obtener caracter en r8 y sumarle 1 a r8
    strb r9, [r2], #1       @ Guardar caracter en resulttext y sumarle 1 al cursor

    @ Continuar loop
    b writetext

writetext_end:
    bx lr







pre_searchword:
    ldr r6, =dictionary     @ Cargar direccion memoria inicial diccionario
    @ R7: Cursor actual del diccionario ((R7 - R6) / 16) cantidad palabras
    @ Cuando R6 == R10 no hay coincidencias
    
searchword:
    @ Comparar si se llego a la direccion actual de diccionario si no hay coincidencias y agregar nueva palabra
    cmp r6, r10
    beq addword

    @ 1. Comparar #caracteres
    ldrb r8, [r6, #8]    @ Obtener cantidad caracteres de palabra en el diccionario
    @sub r8, r8, #65536

    @ Cantidad de caracteres es la misma: comparar palabra
    cmp r8, r4
    beq compareword

    @ Si no es la misma cantidad caracteres: mover cursor de diccionario de busqueda
    add r6, r6, #16  

    @ Continuar el loop
    b searchword 

compareword:
    @ 2. Comparar palabra
    @ R0: indice letra de palabra (offset)
    @ R4: tamano palabra
    @ R5: word
    @ R6: direccion memoria diccionario de la palabra a comparar 
    @ R8: cargar posicion inicial de palabra en buffer
    @ R12: buffer
    
    mov r0, #0      @ Indice 0 palabra (comparar con r4)
    ldr r5, =word   @ Cargar direccion memoria inicial word
    ldr r8, [r6]    @ Cargar direccion inicial de palabra en buffer

    b bucle_compareword

bucle_compareword:

    @ Si se analizo todos los caracteres se anade 1 a la frecuencia
    cmp r0, r4
    beq addfreq

    ldrb r2, [r5, r0] @ Cargar caracter de word
    ldrb r3, [r8, r0] @ Cargar caracter del buffer

    @ Anade 1 al indice
    add r0, r0, #1

    @ Caracter es igual: seguir comparando caracteres
    cmp r2, r3
    beq bucle_compareword

    @ Caracter no es igual: no seguir comparando y seguir buscando por mas palabras 
    add r6, r6, #16
    b searchword

addfreq:
    @ Anade 1 a frecuencia
    ldr r2, [r6, #10]   @ Obtener la frecuencia actual
    add r2, r2, #1      @ Sumar 1
    str r2, [r6, #10]   @ Escribirla de nuevo en la direccion

    ldr r3, =dictionary
    b freq_order

freq_order:
    @ Reacomodar diccionario en orden de frecuencias con la palabra recien aumentada
    @ R2: frecuencia de la palabra actual en el diccionario
    @ R7: frecuencia de la palabra a la izquierda de la actual en el diccionario
    @ R6: puntero temporal diccionario
    @ R3: puntero temporal diccionario[0]

    @ Saber si se ha llegado al inicio de diccionario
    cmp r6, r3
    beq freq_orderout

    @ Comparar frecuencia con la palabra que este a la izquierda
    sub r6, r6, #16     @ Mover indice diccionario a la izquierda
    ldrb r7, [r6, #10]   @ Obtener la frecuencia palabra izquierda
    ldrb r2, [r6, #26]   @ Obtener la frecuencia palabra actual

    @ Si r7 < r2 se debe mover la palabra
    cmp r7, r2
    blt freq_move

    @ Si no, se sale del programa
    bx lr
    
freq_move:
    @ Intercambiar datos

    @ Indice palabra en buffer
    @ Obtener
    ldr r0, [r6]
    ldr r2, [r6, #16]

    @ Intercambiar
    str r0, [r6, #16]
    str r2, [r6]

    @ #Caracteres
    @ Obtener
    ldrb r0, [r6, #8]
    ldrb r2, [r6, #24]

    @ Intercambiar
    strb r0, [r6, #24]
    strb r2, [r6, #8]

    @ Frecuencias
    @ Obtener
    ldr r0, [r6, #10]
    ldr r2, [r6, #26]

    @ Intercambiar
    str r0, [r6, #26]
    str r2, [r6, #10]

    @ Continuar verificando frecuencias
    b freq_order


freq_orderout:
    bx lr

addword:
    @ Agregar palabra al diccionario ([8B: puntero en el buffer, 2B: #caracteres, 6B: cantidad apariciones])
    @ R10: direccion de diccionario (cursor se mueve)
    @ R12: indice en el buffer (restar cantidad caracteres)
    @ R4: cantidad caracteres
    @ Apariciones = 0
    
    @ Obtener la posicion en memoria de la palabra (Indice buffer - cantidad caracteres - 1)
    mov r8, r12
    sub r8, r8, r4
    sub r8, r8, #1

    @ Guardar direccion memoria del primer caracter de la palabra en el buffer
    str r8, [r10]

    @ Guardar cantidad caracteres de la palabra
    str r4, [r10, #8]

    @ Cantidad apariciones = 1
    mov r8, #1
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

@ ----------------------- Pruebas -----------------------

pruebadiccionarios:
    ldr r0, =dictionary
    b pruebadiccionarios2

pruebadiccionarios2:
    ldr r1, [r0]
    ldrb r2, [r0, #8]
    ldr r3, [r0, #10]
    add r0, r0, #16

    b pruebadiccionarios2

@ -------------------------------------------------------
    

end:

    @ Prueba de diccionarios
    @b pruebadiccionarios

    @ Print
    mov r0, #1  @ STDOUT = 1

    ldr r1, =resulttext  @ r1 contiene la direccion de memoria de lo que se va a imprimir
    mov r2, #1000 @ Cantidad caracteres
    mov r7, #4  @ Para syscall write
    swi 0  
 

    @ Salida sistema
    mov r7, #1          @ Número de syscall para exit
    swi 0
    .end

