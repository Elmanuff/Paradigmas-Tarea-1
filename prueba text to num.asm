TITLE PROCESADOR_DE_NOTAS_FINAL_Y_CORRECTO

DATOS SEGMENT
    arrayNotas DB "18.5$     ", "7$        ", "12.75$    ", "9.25$     ", "20$       "
               DB "15.333$   ", "8.75$     ", "11$       ", "16.8$     ", "13.5$     "
               DB "10.25$    ", "19.9$     ", "6.5$      ", "17.125$   ", "14$       "
    
    CANTIDAD_NOTAS EQU 15
    LONGITUD_NOTA  EQU 10

    notasNumericas DD CANTIDAD_NOTAS DUP(0)
    potenciaDiez   DD 100000, 10000, 1000, 100, 10, 1

    msgTitulo      DB '--- Iniciando Prueba de Conversion ---', 13, 10, '$'
    msgConvirtiendo DB 'Convirtiendo: ', '$'
    msgResultado   DB ' -> Resultado (Entero Escalado): ', '$'
    msgFin         DB 13, 10, '--- Prueba Finalizada ---', 13, 10, '$'
    
    bufferNumero   DB 11 DUP(' '), 13, 10, '$'
DATOS ENDS

PILA SEGMENT STACK
    DB 64 DUP(0)
PILA ENDS

CODIGO SEGMENT

;-----------------------------------------------------------------------------
; Subrutina: Multiplicar32x16
;-----------------------------------------------------------------------------
Multiplicar32x16 PROC NEAR
    PUSH SI
    MOV SI, AX
    MOV AX, DX
    MUL BX
    MOV CX, AX
    MOV AX, SI
    MUL BX
    ADD DX, CX
    POP SI
    RET
Multiplicar32x16 ENDP

;-----------------------------------------------------------------------------
; Subrutina: ConvertirStringAEntero (REESCRITA PARA SER 100% SEGURA)
; Entrada: DI -> Puntero a la cadena a convertir
; Salida:  DX:AX -> Numero convertido
;-----------------------------------------------------------------------------
ConvertirStringAEntero PROC NEAR
    PUSH SI
    PUSH CX
    PUSH BX
    PUSH BP

    MOV SI, DI              ; Usar SI como puntero local para no tocar DI

    XOR AX, AX              ; Acumulador parte entera (baja)
    XOR DX, DX              ; Acumulador parte entera (alta)
    XOR BX, BX              ; Acumulador parte decimal (baja)
    XOR CX, CX              ; Acumulador parte decimal (alta)
    XOR BP, BP              ; Contador de decimales

LeerEntero:
    MOV AL, [SI]
    INC SI
    CMP AL, '.'
    JE EncontradoPunto
    CMP AL, '$'
    JE FinString
    
    SUB AL, '0'
    XOR AH, AH
    PUSH AX
    MOV BX, 10
    CALL Multiplicar32x16
    POP BX
    ADD AX, BX
    ADC DX, 0
    JMP LeerEntero

EncontradoPunto:
LeerDecimal:
    MOV AL, [SI]
    INC SI
    CMP AL, '$'
    JE FinString
    
    SUB AL, '0'
    XOR AH, AH
    
    PUSH AX                 ; Guardar digito
    PUSH AX                 ; Espacio reservado en pila
    PUSH DX                 ; Guardar DX:AX
    MOV AX, BX
    MOV DX, CX
    MOV BX, 10
    CALL Multiplicar32x16
    MOV BX, AX
    MOV CX, DX
    POP DX                  ; Restaurar DX:AX
    POP AX                  
    POP AX                  ; Recuperar digito
    ADD BX, AX
    ADC CX, 0
    INC BP
    JMP LeerDecimal
    
FinString:
    MOV BX, 10000
    CALL Multiplicar32x16
    MOV BX, 10
    CALL Multiplicar32x16

    CMP BP, 0
    JE Hecho
    
    PUSH DX                 ; Guardar parte entera escalada
    PUSH AX

    MOV AX, 5
    SUB AX, BP
    MOV SI, AX
    SHL SI, 1
    SHL SI, 1
    LEA BP, potenciaDiez
    ADD BP, SI
    
    MOV AX, BX
    MOV DX, CX
    MOV BX, [BP]
    CALL Multiplicar32x16
    
    POP BP                  ; Recuperar parte entera (baja) en BP
    POP SI                  ; Recuperar parte entera (alta) en SI
    ADD AX, BP
    ADC DX, SI

Hecho:
    POP BP
    POP BX
    POP CX
    POP SI
    RET
ConvertirStringAEntero ENDP

;-----------------------------------------------------------------------------
; Subrutina: ImprimirString
;-----------------------------------------------------------------------------
ImprimirString PROC NEAR
    MOV AH, 09h
    INT 21h
    RET
ImprimirString ENDP

;-----------------------------------------------------------------------------
; Subrutina: ImprimirNumeroEntero32
;-----------------------------------------------------------------------------
ImprimirNumeroEntero32 PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    LEA DI, bufferNumero + 10
    MOV BYTE PTR [DI], '$'
    DEC DI
    
    MOV BX, 10

    MOV CX, DX
    OR CX, AX
    JNZ ConvertirLoop
    MOV BYTE PTR [DI], '0'
    DEC DI
    JMP Imprimir

ConvertirLoop:
    PUSH AX
    MOV AX, DX
    XOR DX, DX
    DIV BX
    MOV CX, AX
    POP AX
    DIV BX
    
    ADD DL, '0'
    MOV [DI], DL
    DEC DI
    
    MOV DX, CX
    
    OR AX, DX
    JNZ ConvertirLoop

Imprimir:
    INC DI
    MOV DX, DI
    CALL ImprimirString

    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ImprimirNumeroEntero32 ENDP

;--- PROCEDIMIENTO PRINCIPAL (FINAL) ---
INICIO PROC FAR
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA
    
    MOV AX, DATOS
    MOV DS, AX

    LEA DX, msgTitulo
    CALL ImprimirString
    
    MOV CX, CANTIDAD_NOTAS
    LEA SI, notasNumericas
    LEA DI, arrayNotas

BucleDePrueba:
    ; Imprimir "Convirtiendo: [nota]"
    LEA DX, msgConvirtiendo
    CALL ImprimirString

    PUSH DI
    MOV BP, DI
    ADD BP, 10
    MOV AL, [BP]
    MOV BYTE PTR [BP], '$'
    MOV DX, DI
    CALL ImprimirString
    MOV BYTE PTR [BP], AL
    POP DI

    ; Convertir la nota.
    CALL ConvertirStringAEntero

    ; Guardar el resultado en el arreglo
    MOV [SI], AX
    MOV [SI+2], DX

    ; Imprimir el resultado
    LEA DX, msgResultado
    CALL ImprimirString
    CALL ImprimirNumeroEntero32
    
    ; Avanzar punteros para la siguiente iteracion
    ADD SI, 4
    ADD DI, LONGITUD_NOTA
    
    LOOP BucleDePrueba

    LEA DX, msgFin
    CALL ImprimirString

    MOV AX, 4C00h
    INT 21h

INICIO ENDP
CODIGO ENDS

END INICIO