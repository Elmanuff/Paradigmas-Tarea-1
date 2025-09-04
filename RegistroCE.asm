title RegistroCE

datos segment
;Variables aqui------------------------------------------------  
    
    
    mensajeBienvenida db "Bienvenido a RegistroCE",0Dh,0Ah
    db "Digite:$"    
    mensajeMenu db "1.  Ingresar calificaciones (15 estudiantes -Nombre Apellido1 Apellido2 Nota-)",0Dh,0Ah
    db "2.  Mostrar estadisticas",0Dh,0Ah
    db "3.  Buscar estudiante por posicion (indice)",0Dh,0Ah
    db "4.  Ordenar calificaciones (ascendente/descendente)",0Dh,0Ah
    db "5.  Salir$"     
    mensajeNombre db 0Dh,0Ah, "Por favor ingrese su estudiante o digite 9 para salir al menu principal:$"
    mensajeSalida db 0Dh,0Ah, "Gracias por usar Registro CE$"
    mensajeAprobados db "Aprobados Cantidad: $",0Dh,0Ah
    mensajeReprobados db "Reprobados Cantidad: $",0Dh,0Ah
    mensajePorcentaje db "Porcentaje: $",0Dh,0Ah
    cien db 100
    
    
    bufferEntrada db 39,0,39 dup('$') ;max 39 caracteres
    
    arrayNombres db 465 dup('0') ;array de 15 espacios para nombres de 31 bytes. 15*31=465   
    arrayNotas db 150 dup(0) ;array de 15 espacios para notas de 10 bytes. 15*10=150
                                      
    contadorEst db 0
           
    preguntaSort db "Como desea ordenar las calificaciones:",0Dh,0Ah
    db "1.  Asc",0Dh,0Ah
    db "2.  Des$" 
    preguntaIndice db 0Dh,0Ah,"Que estudiante desea mostrar:$"
    
    mensajeInvalid db 0Dh,0Ah,"Por favor ingrese un valor valido$"
    mensajeInvalidIndice db 0Dh,0Ah,"Indice invalido, vacio o fuera de rango$" 
    mensajeInvalidLleno db 0Dh,0Ah,"Se ha llegado al limite de estudiantes$"
    mensajeInvalidVacio db 0Dh,0Ah,"No se han ingresado estudiantes$"
    mensajeInvalidFormato db 0Dh,0Ah,"Entrada invalida. Utilice el formato -Nombre Apellido1 Apellido2 Nota-$"
    
    salto db 0Dh,0Ah, "$"
    espacio db "       $"
    
    aprobados dw 0
    reprobados dw 0  
    
    arrayNotas_num dw 15 dup(0)

datos ends
;-----------------------------------------------------------------------

pila segment
    db 64 dup(0)
pila ends

codigo segment
    
inicio proc far

assume ds:datos, cs:codigo, ss:pila  

push ds
mov ax,0
push ax

mov ax,datos
mov ds,ax
mov es,ax

;Aqui comienza el codigo del programa
                       
mov dx, offset mensajeBienvenida
mov ah,09h
int 21h
call fsalto



;FUNCION MENU                       
menu: 
    call fsalto
    mov dx, offset mensajeMenu 
    mov ah,09h
    int 21h 
    call fsalto
                      
    ;leer opcion
    mov ah,01h
    int 21h       
     
    cmp al,'1'
    je ingresar   
    
    cmp al,'2'
    je estadisticas     
    
    cmp al,'3'
    je buscar
    
    cmp al,'4'
    je sort  
    
    cmp al,'5'
    je exit
    
    jmp invalidMenu



;FUNCION INGRESAR
ingresar:
    mov dx,offset mensajeNombre
    mov ah,09h
    int 21h
    call fsalto

    mov dx,offset bufferEntrada
    mov ah,0Ah
    int 21h

    ;salir si se escribe '9'
    mov al,[bufferEntrada+2]
    cmp al,'9'
    je menu

    ;buscar espacio
    mov cl,[bufferEntrada+1] ;longitud texto
    mov ch,0
    cmp cl,0
    je invalidFormato ;si no se introdujo nada
    
    mov si,offset bufferEntrada+2 ;inicio del texto
    mov bx,si
    add bx,cx ;fin del texto
    dec bx                         

buscar_espacio:
    cmp byte ptr [bx],' '
    je espacio_encontrado
    dec bx
    loop buscar_espacio
    
    jmp invalidFormato ;no se cumple el formato

espacio_encontrado:
    mov dx,bx
    sub dx,si ;con esta resta se obtiene la longitud nombre
    mov cx,dx

    ;calcular donde debe ir en el array
    mov al,contadorEst
    xor ah,ah
    mov dl,31 ;cada nombre ocupa 31 bytes
    mul dl
    mov di,offset arrayNombres
    add di,ax

    ;guardar nombre en array
    mov si,offset bufferEntrada+2

    rep movsb
    mov byte ptr [di],'$'
    
    
    ;call validarNota
    ;cmp ax,0
    ;jne invalidFormato
     
    ;copiar nota
    inc bx ;primer caracter de la nota
    mov si,bx

    mov cl,[bufferEntrada+1] ;longitud total
    mov ch,0
    mov dx,offset bufferEntrada+2
    add dx,cx ;fin del texto
    sub dx,bx ;longitud nota
    mov cx,dx

    ;calcular destino en arrayNotas
    mov al,contadorEst
    xor ah,ah
    mov dl,10 ;cada nota ocupa 10 bytes
    mul dl                    
    mov di,offset arrayNotas
    add di,ax

    rep movsb
    mov byte ptr [di],'$'

    ;incrementar contador de estudiantes
    inc contadorEst
    cmp contadorEst,15 ;si son menos de 15 estudiantes
    jb ingresar ;continuar ingresando

    jmp invalidLleno

   

;FUNCION ESTADISTICAS
estadisticas:
    call fsalto
    call verifyCantidadEst  

    ;Inicializar contadores en memoria
    mov word ptr [aprobados], 0
    mov word ptr [reprobados], 0

    ;Puntero al primer bloque de notas (ascii)
    mov si, offset arrayNotas

    mov al, [contadorEst]
    xor ah, ah
    mov bp, ax   ;bp= numero de estudiantes

contar_loop:
    xor ax, ax  ;Acumulador de la nota actual
    mov di, si  ;Apunta al inicio de la nota actual
    mov cx, 9  ;max caracteres

parse_loop:
    mov bl, [di]        ;caracter actual  
    cmp bl, '$'         ;fin de la cadena
    je parsed_note
    
    cmp bl, '0'
    jb skip_char 
    
    cmp bl, '9'
    ja skip_char

    ;convertir a numero (ax=ax*10+(bl-'0')
    mov dx, ax          
    shl dx, 1
    shl dx, 1
    shl dx, 1          ; DX = AX * 8
    shl ax, 1          ; AX = AX * 2
    add ax, dx         ; AX = AX*10

    sub bl, '0'        
    xor bh, bh
    add ax, bx

skip_char:
    inc di
    dec cx
    jnz parse_loop

parsed_note:
    cmp ax, 70
    jl marcar_reprobado

    mov bx, [aprobados]
    inc bx
    mov [aprobados], bx
    jmp siguiente_est

marcar_reprobado:
    mov bx, [reprobados]
    inc bx
    mov [reprobados], bx

siguiente_est:
    add si, 10      ;pasar al siguiente bloque de 10 bytes
    dec bp
    jnz contar_loop

    ;mostrar aprobados
    call fsalto
    mov dx, offset mensajeAprobados
    mov ah, 09h
    int 21h

    mov ax, [aprobados]
    call print_num

    ;porcentaje aprobados
    mov ax, [aprobados]
    mov bx, 100
    mul bx              ;DX:AX = aprobados * 100
    mov bl, [contadorEst]
    xor bh, bh
    div bx              ;AX = (aprobados*100)/contadorEst

    push ax
    mov dx, offset mensajePorcentaje
    mov ah, 09h
    int 21h
    pop ax
    call print_num
    mov dl, '%'
    mov ah, 02h
    int 21h
    call fsalto

    ;mostrar reprobados 
    mov dx, offset mensajeReprobados
    mov ah, 09h
    int 21h

    mov ax, [reprobados]
    call print_num

    ;porcentaje reprobados
    mov ax, [reprobados]
    mov bx, 100
    mul bx
    mov bl, [contadorEst]
    xor bh, bh
    div bx

    push ax
    mov dx, offset mensajePorcentaje
    mov ah, 09h
    int 21h
    pop ax
    call print_num
    mov dl, '%'
    mov ah,02h
    int 21h
    call fsalto

    jmp menu


;FUNCION BUSCAR
buscar:
    call verifyCantidadEst

    mov dx, offset preguntaIndice
    mov ah, 09h
    int 21h
    call fsalto

    mov dx, offset bufferEntrada
    mov ah, 0Ah
    int 21h
    call fsalto

    mov cl, [bufferEntrada+1]
    cmp cl, 0
    je invalidIndice ;nada escrito
    cmp cl, 2
    ja invalidIndice ;no permite mas de 2 caracteres

    mov si, offset bufferEntrada+2 ;apunta al primer caracter

    ;primer digito
    mov al, [si]
    sub al, '0'
    jc invalidIndice
    cmp al, 9
    ja invalidIndice
    mov bl, al ;bl=primer digito

    cmp cl, 1
    je indice_listo ;solo 1 digito

    ;segundo digito
    mov dl, [si+1]
    sub dl, '0'
    jc invalidIndice
    cmp dl, 9
    ja invalidIndice

    ;indice = primerDigito*10 + segundoDigito
    mov al,bl ;al = primer digito
    mov ah,0
    mov bl,10
    mul bl               
    add al,dl             
    mov bl,al             

indice_listo:
    ;validar rango valido
    cmp bl,1
    jb invalidIndice
    cmp bl,15
    ja invalidIndice
    mov al,contadorEst
    cmp bl,al
    ja invalidIndice

    ;calcular y mostrar nombre
    dec bl                     
    mov bh,0
    mov ax,bx                 
    mov cx,31
    mul cx                     
    mov si,offset arrayNombres
    add si,ax                 

    mov dx,si
    mov ah,09h
    int 21h
    call fespacio

    ;calcular y mostrar nota
    mov ax,bx                 
    mov cx,10
    mul cx                     
    mov di,offset arrayNotas
    add di,ax                 

    mov dx,di
    mov ah,09h
    int 21h
    call fsalto

    jmp menu



;FUNCION SORT
sort: 
    call verifyCantidadEst
    call fsalto 
    mov dx, offset preguntaSort
    mov ah,09h
    int 21h
    call fsalto 
    
    mov ah,01h
    int 21h 
    
    cmp al,'1'
    je asc
    
    cmp al,'2'
    je desc  
    
    jmp invalidSort

;ORDEN ASCENDENTE
asc:
    mov cl, [contadorEst]
    dec cl                 
    jz print_sort         
    mov ch,0
    mov bx,cx             

outer_loop_asc:
    mov si,0               
inner_loop_asc:
    push bx
    push cx
    push si
    
    mov di, offset arrayNotas
    mov bl, [contadorEst]
    xor bh,bh
    
    mov ax, si
    mov bx,10
    mul bx
    add di, ax
    call convertirNota     

    mov dx, ax              
    
    pop si
    inc si
    push si

    mov di, offset arrayNotas
    mov ax, si
    mov bx,10
    mul bx
    add di, ax
    call convertirNota      

    cmp dx, ax
    jbe no_swap_asc
    
    pop si
    dec si
    push si
  
    mov di, offset arrayNombres
    mov ax, si
    mov bx,31
    mul bx
    add di, ax
    mov si, di
   
    mov di, offset arrayNombres
    mov ax, si
    inc ax
    mov bx,31
    mul bx
    add di, ax

    mov cx,31
    call swap_block
   
    pop si
    dec si
    push si

    mov di, offset arrayNotas
    mov ax, si
    mov bx,10
    mul bx
    add di, ax
    mov si, di

    mov di, offset arrayNotas
    mov ax, si
    inc ax
    mov bx,10
    mul bx
    add di, ax

    mov cx,10
    call swap_block

no_swap_asc:
    pop si
    dec si
    pop cx
    pop bx
    loop inner_loop_asc
    dec bx
    jnz outer_loop_asc
    jmp print_sort

;ORDEN DESCENDENTE
desc:  
    jmp print_sort

print_sort:
    mov cl, [contadorEst]
    mov ch,0
    mov si,0

print_loop:
    call fsalto

    ; imprimir nombre[i]
    mov di, offset arrayNombres
    mov ax, si
    mov bx,31
    mul bx
    add di, ax
    mov dx, di
    mov ah,09h
    int 21h

    ; espacio separador
    mov dl,' '
    mov ah,02h
    int 21h

    ; imprimir nota[i]
    mov di, offset arrayNotas
    mov ax, si
    mov bx,10
    mul bx
    add di, ax
    mov dx, di
    mov ah,09h
    int 21h

    inc si
    loop print_loop

    jmp menu

;SUBRUTINAS AUXILIARES

    convertirNota proc ;convierte cadena ASCII de nota en numero
    xor ax, ax 
    
    cn_loop:
    mov bl, [di]
    cmp bl,'$'
    je cn_done
    cmp bl,'0'
    jb cn_skip
    cmp bl,'9'
    ja cn_skip

    ; AX = AX*10 + (bl - '0')
    mov dx, ax
    shl dx,1
    shl dx,1
    shl dx,1
    shl ax,1
    add ax, dx
    sub bl,'0'
    xor bh,bh
    add ax,bx
    
    cn_skip:
    inc di
    jmp cn_loop
    
    cn_done:
    ret
    
    convertirNota endp

;intercambia CX bytes entre [SI] y [DI]
    swap_block proc
    push ax
    push bx
    
    sw_loop:
    mov al,[si]
    mov bl,[di]
    mov [si],bl
    mov [di],al
    inc si
    inc di
    loop sw_loop
    pop bx
    pop ax
    ret
    
    swap_block endp 
    
    print_num proc
    push bx
    push cx
    push dx
    push si

    cmp ax, 0
    jne pn_loop_start

    ; caso 0
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp pn_done
    
    pn_loop_start:
    xor cx, cx        ;contador de digitos

    pn_div_loop:
    xor dx, dx        
    mov bx, 10
    div bx            ; AX = AX/10, DX = AX%10 (residuo)
    push dx           ; guardar residuo
    inc cx
    cmp ax, 0
    jne pn_div_loop

    pn_print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop pn_print_loop

    pn_done:
    pop si
    pop dx
    pop cx
    pop bx
    ret
    
    print_num endp 


;FUNCION EXIT
exit:
    mov dx,offset mensajeSalida
    mov ah,09h
    int 21h

    mov ah, 4Ch      
    mov al, 0         
    int 21h           



;FUNCIONES DE CONDICIONES
verifyCantidadEst:
cmp contadorEst,0
je invalidVacio
ret

validarNota proc
    mov ax,0          ; salida por defecto = válido
    mov bl,0          ; contador de puntos
    mov bh,0          ; contador decimales
    mov dl,0          ; flag punto visto

    mov di,si         ; DI = puntero que usaremos
    mov bp,cx         ; BP = longitud que usaremos

val_loop:
    cmp bp,0
    je val_loop_end
    mov al,[di]

    cmp al,','        ; coma prohibida
    je invalido

    cmp al,'.'        ; punto decimal
    je val_punto

    cmp al,'0'        ; rango de digitos
    jb invalido
    cmp al,'9'
    ja invalido

    cmp dl,0          ; si ya hubo punto, contamos decimales
    je val_no_decimal
    inc bh
    cmp bh,5
    ja invalido
val_no_decimal:

    jmp avanzar

val_punto:
    inc bl
    cmp bl,1
    ja invalido
    mov dl,1
    jmp avanzar

avanzar:
    inc di
    dec bp
    jmp val_loop

val_loop_end:
    cmp bl,1
    jne invalido

    ; verificar parte entera <= 100
    mov dx,0
    mov di,si     ;otra vez desde inicio original
    mov bp,cx

conv_loop:
    cmp bp,0
    je conv_fin
    mov al,[di]
    cmp al,'.'
    je conv_fin
    sub al,'0'
    mov ah,0
    mov bx,10
    mul bx
    add dx,ax
    inc di
    dec bp
    jmp conv_loop

conv_fin:
    cmp dx,100
    ja invalido

valido:
    mov ax,0
    ret

invalido:
    mov ax,1
    ret
validarNota endp


     
invalidSort:
    mov dx, offset mensajeInvalid
    mov ah, 09h
    int 21h 
    jmp sort  

invalidMenu:
    mov dx, offset mensajeInvalid
    mov ah,09h
    int 21h
    jmp menu

invalidIndice:
    mov dx, offset mensajeInvalidIndice
    mov ah,09h
    int 21h
    call fsalto
    jmp buscar

invalidFormato:
    mov dx, offset mensajeInvalidFormato
    mov ah,09h
    int 21h
    call fsalto
    jmp ingresar

invalidLleno:
    mov dx, offset mensajeInvalidLleno
    mov ah,09h
    int 21h
    call fsalto
    jmp menu

invalidVacio:
    mov dx, offset mensajeInvalidVacio
    mov ah,09h
    int 21h
    call fsalto
    jmp menu


fespacio:
    mov dx, offset espacio
    mov ah,09h
    int 21h
    ret

fsalto:
    mov dx, offset salto
    mov ah,09h
    int 21h
    ret


codigo ends
end inicio
