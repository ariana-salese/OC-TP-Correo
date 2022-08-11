;-------------------------------------ENTREGA-------------------------------------  
;
;                       TP 6 - ORGANIZACIÓN DEL COMPUTADOR
;   
;              Alumna: Ariana Magalí Salese D'Assaro (Padrón = 105558) 
;----------------------------------------------------------------------------------
global 	main

extern 	sscanf
extern printf
extern gets
extern puts

section	.data
    ;Mensajes para ingreso de input y sus posibles errores
    mensajeFormatoInputObjeto   db  "Cada objeto debe ser ingresado con cada dato separado con un espacio:",10
                                db  "",10
                                db  "                          ID DESTINO PESO",10
                                db  "",10
                                db  "cumpliendo que:",10
                                db  "  > ID: numero natural",10
                                db  "  > DESTINO: un caracter",10
                                db  "         - M (Mar Del Plata)",10
                                db  "         - B (Bariloche)",10
                                db  "         - P (Posadas)",10
                                db  "  > PESO(kilos): número entero entre 1 y 11 inclusive",10,10,0
                  
    mensajeIngresarObjeto       db  "Ingrese objeto (o el caracter * para terminar): ",0

    mensajeLimiteInput          db  "Se alacanzó la cantidad limite de objetos",0

    mensajeInputInvalido        db  "El input es invalido",0
    mensajeIdInvalido           db  "El ID ingresado es invalido",0
    mensajePesoInvalido         db  "El PESO ingresado es invalido",0
    mensajeDestinoInvalido      db  "El DESTINO ingresado es invalido",0

    ;Mensajes para imprimir paquetes
    mensajeNumeroPaquete        db  "%li - ",0 
    mensajePaquetesDestino      db  "PAQUETES CON DESTINO %c",10,0
    mensajeObjeto               db  "Id: %hi, Peso: %hi |",0
    mensajeNoHayPaquetes        db  "No hay paquetes para el destino %c",0
    saltoDeLinea                db  '',0

    ;Información destinos
    destinos                    db  " MPB",0 ;agrego espacio al comienzo para que el primer caracter sea el
                                             ;de la posicion 1 al igual que en las matrices y vectores
    cantidadPorDestino          times   3   dq  0  
    cantidadTotal               dq  0

    formatoInputObjeto          db  "%hi %c %hi",0 

section	.bss    
    inputObjeto                 resb    50 

    id                          resw    1    
    destino                     resb    1
    peso                        resw    1

    indiceDestino               resb    1
    fila                        resb    1
    columna                     resq    1 
    
    cantidadObjetos             resq    1
    contadorPaquetes            resq    1
    cantidadEmpaquetados        resq    1
    suma                        resb    1

    inputValido                 resb    1   ;S valido, N invalido

    matrizPesos                 times   20  resw   1   ;pesos Mar del Plata
                                times   20  resw   1   ;pesos Posadas
                                times   20  resw   1   ;pesos Bariloche

    ;Incluyo para cada producto un ID identificatorio 
    matrizIds                   times   20  resw   1   ;ids Mar del Plata
                                times   20  resw   1   ;ids Posadas
                                times   20  resw   1   ;ids Bariloche

    desplazamientoMatriz        resq    1
    desplazamientoInicial       resq    1 
    desplazamientoEnFila        resq    1   
    desplazamientoVector        resq    1

    ;checkAlign
    plusRsp                     resq 1

section	.text
main:
;PIDE OBJETOS POR INPUT
    ;Indica intrucciones para ingresar cada objeto
    mov     rdi, mensajeFormatoInputObjeto
    sub     rax, rax
    call    printf

pedirObjeto:
    cmp     qword[cantidadTotal], 20
    jge     limiteDeInput

    ;Pide objeto
    mov     rdi, mensajeIngresarObjeto
    sub     rax, rax
    call    printf
    mov     rdi, inputObjeto 
    call    gets

    ;Fin ingreso de objetos si input = *
    mov     al, '*'
    cmp     al, [inputObjeto]
    je      ordenarObjetos

    ;Valida objeto ingresado
    call    validarInputObjeto

    cmp     byte[inputValido], 'N'
    je      pedirObjeto

    ;Actualiza cantidad de objetos del destino
    call    calcularDesplazamientoVector
    mov     rbx, [desplazamientoVector]

    mov     rax, [cantidadPorDestino + rbx]
    inc     rax
    mov     [cantidadPorDestino + rbx], rax

    ;Almacena objeto
    mov     qword[columna], rax
    mov     bx, [indiceDestino]
    mov     byte[fila], bl

    call    calcularDesplazamientoMatriz
    mov     rbx, [desplazamientoMatriz]

    mov     ax, [peso]
    mov     [matrizPesos + rbx], ax

    mov     ax, [id]
    mov     [matrizIds + rbx], ax   

    inc     qword[cantidadTotal]

    jmp     pedirObjeto

limiteDeInput:
    mov     rdi, mensajeLimiteInput
    call    puts

;ORDENA OBJETOS DE MAYOR A MENOR 
ordenarObjetos:
    mov     byte[indiceDestino], 0

ordenarSiguienteDestino:
    ;Actualiza índice de destino
    inc     byte[indiceDestino]

    ;Si indiceDestino > 3 se ordenaron todos, arma paquetes
    cmp     byte[indiceDestino], 3
    jg      armarPaquetes

    ;Si no hay objetos o solo uno termina la rutina
    call    calcularDesplazamientoVector
    mov     rbx, [desplazamientoVector]

    cmp     qword[cantidadPorDestino + rbx], 2
    jl      ordenarSiguienteDestino

    mov     rax, [cantidadPorDestino + rbx]
    mov     [cantidadObjetos], rax

    ;Calcula desplazamiento desde segundo objeto de la fila para comezar a intercambiar posiciones
    mov     qword[columna], 2
    mov     bl, [indiceDestino]
    mov     byte[fila], bl

    call    calcularDesplazamientoMatriz

    ;Almacena copia de desplazamiento inicial para no perderlo
    mov     rax, [desplazamientoMatriz]
    mov     [desplazamientoInicial], rax

    dec     qword[cantidadObjetos]
    jmp     intercambiarObjetos

ordenarSiguienteObjeto:
    ;Si ordenó todos los objetos termina
    dec     qword[cantidadObjetos]
    cmp     qword[cantidadObjetos], 0
    jle     ordenarSiguienteDestino 

    ;Actualiza posición de próximo objeto a ordenar
    add     qword[desplazamientoInicial], 2
    mov     rax, [desplazamientoInicial]
    mov     [desplazamientoMatriz], rax

intercambiarObjetos:
    ;Obtiene desplazamiento de objeto en posición anterior
    mov     rbx, [desplazamientoMatriz]
    sub     rbx, 2

    ;Si ese deplazamiento es menor al comienzo de la fila, según destino, busca siguiente a ordear
    cmp     rbx, [desplazamientoEnFila]
    jl      ordenarSiguienteObjeto

    mov     rbx, [desplazamientoMatriz] 

    ;Si peso anterior > peso actual paso a siguiente objeto
    mov     ax, [matrizPesos + rbx]
    cmp     word[matrizPesos + rbx - 2], ax
    jg      ordenarSiguienteObjeto

    ;Intercambia posición de objetos
    mov     [peso], ax
    mov     ax, [matrizPesos + rbx - 2]

    mov     [matrizPesos + rbx], ax
    mov     ax, [peso]
    mov     [matrizPesos + rbx - 2], ax

    mov     ax, [matrizIds + rbx]
    mov     [id], ax
    mov     ax, [matrizIds + rbx - 2]

    mov     [matrizIds + rbx], ax
    mov     ax, [id]
    mov     [matrizIds + rbx - 2], ax

    sub     qword[desplazamientoMatriz], 2
    jmp     intercambiarObjetos

;ARMA PAQUETES POR DESTINO
armarPaquetes:
    mov     byte[indiceDestino], 0

armarPaquetesSiguienteDestino:
    mov     rdi, saltoDeLinea
    call    puts

    ;Actualiza índice de destino
    inc     byte[indiceDestino]

    ;Si indiceDestino > 3 termina el programa
    cmp     byte[indiceDestino], 3
    jg      fin

    ;Indica de que destino se trata
    sub     ebx, ebx
    mov     bl, [indiceDestino]

    mov     rdi, mensajePaquetesDestino
    mov     rsi, qword[destinos + ebx]
    sub     rax, rax
    call    printf

    ;Obtiene cantidad de objetos del destino
    call    calcularDesplazamientoVector
    mov     rbx, [desplazamientoVector]

    ;Si no hay objetos, indica que no hay paquetes para el destino
    cmp     qword[cantidadPorDestino + rbx], 0
    je      noHayPaquetes

    mov     rax, [cantidadPorDestino + rbx]
    mov     [cantidadObjetos], rax

    ;Obtiene desplazamiento según destino
    mov     rax, [cantidadPorDestino + rbx]
    mov     qword[columna], rax
    mov     bl, [indiceDestino]
    mov     byte[fila], bl

    call    calcularDesplazamientoMatriz    ;desplazamientoEnFila = desplazamiento inicial
                                            ;desplazamientoMatriz = ultimo desplazamiento disponible

    ;Inicializa contador de paquetes y empaquetados
    mov     qword[contadorPaquetes], 0
    mov     qword[cantidadEmpaquetados], 0

armarSiguietePaquete:
    ;Si cantidad de empaquetados = cantidad de objetos pasa a próximo destino
    mov     rax, qword[cantidadEmpaquetados]
    cmp     rax, qword[cantidadObjetos]
    jge     armarPaquetesSiguienteDestino

    ;Actualiza número de paquete
    inc     qword[contadorPaquetes]

    ;Indica número de paquete actual
    mov     rdi, saltoDeLinea
    call    puts

    mov     rdi, mensajeNumeroPaquete
    mov     rsi, qword[contadorPaquetes]
    sub     rax, rax 
    call    printf 

    ;Setea nuevamente desplazamiento inicial y suma en 0
    mov     rbx, [desplazamientoEnFila]
    mov     byte[suma], 0

    jmp    empaquetarSiguienteObjeto 
buscarProximoAEmpaquetar:
    add     ebx, 2

empaquetarSiguienteObjeto:
    ;Si el desplazamiento es mayor al último disponible arma próximo paquete
    cmp     rbx, [desplazamientoMatriz]
    jg      armarSiguietePaquete   

    ;Almacena peso
    mov     ax, [matrizPesos + rbx]

    ;Si el peso es 0 se busca próximo objeto a empaquetar
    cmp     ax, 0
    je      buscarProximoAEmpaquetar

    ;Si la suma de los pesos es mayor a 11 no se agrega a paquete, se busca próximo objeto
    add     al, [suma]

    cmp     al, 11
    jg      buscarProximoAEmpaquetar

    ;Actualiza suma
    mov     [suma], al

    ;Imprime objeto
    mov     rdi, mensajeObjeto
    mov     rsi, qword[matrizIds + rbx]
    mov     rdx, qword[matrizPesos + rbx]
    sub     rax, rax
    call    printf

    ;Setea el peso en 0 para indicar que ya se le asigno un paquete
    mov     word[matrizPesos + rbx], 0

    ;Actualiza cantidad de empaquetados
    inc     byte[cantidadEmpaquetados]

    ;Si la suma del paquete es 11, se arma nuevo paquete
    cmp     byte[suma], 11
    je      armarSiguietePaquete

    jmp     buscarProximoAEmpaquetar

noHayPaquetes:  
    mov     rdi, saltoDeLinea
    call    puts

    mov     rdi, mensajeNoHayPaquetes
    sub     ebx, ebx
    mov     bl, [indiceDestino]
    mov     rsi, qword[destinos + ebx]
    sub     rax, rax
    call    printf
    jmp     armarPaquetesSiguienteDestino

fin: 
ret

;*********************************************************************************
;                                 RUTINAS INTERNAS
;*********************************************************************************

;---------------------------------------------------------------------------------
; Valida los datos del objeto ingresado por input. Almacena 'N' en inputValido
; si es invalido, 'S' en caso contrario. 
;
validarInputObjeto: 
    mov     byte[inputValido], 'N'

    mov     rdi, inputObjeto
    mov     rsi, formatoInputObjeto
    mov     rdx, id
    mov     rcx, destino
    mov     r8,  peso

    call    checkAlign
    sub     rsp, [plusRsp]
    call    sscanf
    add     rsp, [plusRsp]

    ;Verifica que se convirtieron 3 elementos 
    mov     rdi, mensajeInputInvalido
    cmp     rax, 3
    jl      invalido

    ;Verifica que el ID sea mayor o igual a 0
    mov     rdi, mensajeIdInvalido
    cmp     word[id], 0
    jl      invalido

    ;Verifica que sea un PESO valido 
    mov     rdi, mensajePesoInvalido
    cmp     word[peso], 0
    jle     invalido

    cmp     word[peso], 11
    jg      invalido

    ;Verifica que sea un DESTINO valido
    sub     rsi, rsi
    mov     sil, 1
    mov     rdi, mensajeDestinoInvalido

verificarDestino:
    cmp     sil, 3
    jg      invalido

    mov     byte[indiceDestino], sil

    mov     al, [destinos + rsi]
    cmp     al, [destino]
    je      valido

    inc     sil
    jmp     verificarDestino

valido:
    mov     byte[inputValido], 'S' 
    jmp     finValidarInput

invalido: 
    call    puts

finValidarInput:
ret
;---------------------------------------------------------------------------------
; Almacena en desplazamientoMatriz el desplazamiento necesario para acceder a un 
; elemento en matrizPesos o matrizIds y en desplzamientoEnFila el desplazamiento
; al primer elemento de la fila. 
calcularDesplazamientoMatriz:
    sub     rbx, rbx
    mov     bl, [fila]
    dec     bl 
    imul    rbx, rbx, 200 

    mov     [desplazamientoMatriz], rbx
    mov     [desplazamientoEnFila], rbx

    sub     rbx, rbx
    mov     ebx, [columna]
    dec     ebx               
    imul    rbx, rbx, 2      

    add     [desplazamientoMatriz], rbx  
ret
;---------------------------------------------------------------------------------
; Almacena en desplazamientoVector el desplazamiento necesario para acceder a la 
; posición indiceDestino  del vector cantidadPorDestino
calcularDesplazamientoVector:
    sub     rbx, rbx     
    mov     bl, [indiceDestino]
    dec     bl
    imul    rbx, rbx, 8
    mov     [desplazamientoVector], rbx

ret
;---------------------------------------------------------------------------------
;                                   CHECK ALIGN
checkAlign:
    push    rax
    push    rbx
    push    rdx
    push    rdi

    mov     qword[plusRsp], 0
    mov     rdx, 0

    mov     rax, rsp
    add     rax, 8
    add     rax, 32

    mov     rbx, 16
    idiv    rbx

    cmp     rdx, 0
    je      finCheckAlign

    mov     qword[plusRsp], 8

finCheckAlign:
    pop rdi
    pop rdx
    pop rbx
    pop rax 
ret