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
    
    
    bufferEntrada db 39,0,39 dup('$') ;max 39 caracteres
    
    arrayNombres db 465 dup('0') ;array de 15 espacios para nombres de 31 bytes. 15*31=465   
    arrayNotas db 150 dup(0) ;array de 15 espacios para notas de 10 bytes. 15*10=150
                                      
    contadorEst db 0
           
    preguntaSort db "Como desea ordenar las calificaciones:",0Dh,0Ah
    db "1.  Asc",0Dh,0Ah
    db "2.  Des$" 
    preguntaIndice db 0Dh,0Ah,"Que estudiante desea mostrar:$"
    
    mensajeInvalid db 0Dh,0Ah,"Por favor ingrese un valor valido$"
    mensajeInvalidLleno db 0Dh,0Ah,"Se ha llegado al limite de estudiantes$"
    mensajeInvalidVacio db 0Dh,0Ah,"No se han ingresado estudiantes$"
    mensajeInvalidFormato db 0Dh,0Ah,"Entrada invalida. Utilice el formato -Nombre Apellido1 Apellido2 Nota-$"
    
    salto db 0Dh,0Ah, "$"
     
    array_notas db 15,2,87,12,4,9,21,10,3,100,65,23,44,19,11

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
    
    
    call validarNota
    cmp ax,0
    jne invalidFormato
     
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

    dec contadorEst ;evitar que se pase
    jmp invalidLleno

   

;FUNCION ESTADISTICAS
estadisticas:
    call verifyCantidadEst



;FUNCION BUSCAR
buscar:
    call verifyCantidadEst
    mov dx,offset preguntaIndice
    mov ah,09h
    int 21h
    call fsalto
    
    mov cl,contadorEst
    mov ch,0
    mov si, offset arrayNombres
    mov di, offset arrayNotas
    cmp contadorEst,0
    jg buscarloop
    
    jmp menu

buscarLoop:    
    call fsalto
    
    ;imprimir nombre
    mov dx, si
    mov ah, 09h
    int 21h
    
    ;imprimir nota
    mov dx, di
    mov ah, 09h
    int 21h
    
    add si,31
    add di,10
    
    loop buscarloop
    
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
        
asc:
    mov cx,14 ;cantidad de comparaciones
    mov si,0
    mov di,0
    
    ciclo1asc:
    push cx
    lea si, array_notas ;pasa la direccion efectiva
    mov di,si 
    
    ciclo2asc:
    inc di;incrementa posicion
    mov al,[si]  
    cmp al, [di]
    ja switch ;short jump
    jb menor
    
    switch: 
    mov ah,[di]
    mov [di],al
    mov [si],ah
    
    menor:   
    inc si
    loop ciclo2asc  
    pop cx
    loop ciclo1asc 
    jmp print
                 
desc:
    mov cx,14
    mov si,0
    mov di,0 
    
    ciclo1desc:
    push cx
    lea si, array_notas
    mov di,si
    
    ciclo2desc:
    inc di
    mov al,[si]
    cmp al, [di]
    jb switchD
    ja mayor
    
    switchD:
    mov ah,[di]
    mov [di],al
    mov [si],ah
    
    mayor:
    inc si
    loop ciclo2desc
    pop cx
    loop ciclo1desc  
    jmp print 
                              
print:
    mov cx,15
    mov si,0
    
    print_loop:
    mov al,array_notas[si]
    call print_num
    inc si
    loop print_loop
    
    jmp menu
    
    print_num proc 
    push cx
    xor ah,ah
    mov bx,10
    xor cx,cx 
    
    pn1:
    xor dx,dx
    div bx
    push dx
    inc cx
    cmp ax,0
    jne pn1
       
    pn2:
    pop dx
    add dl,'0'
    mov ah,02h
    int 21h
    loop pn2 
    pop cx
    call fsalto
    ret
print_num endp 


;FUNCION EXIT
exit:
    mov dx, offset mensajeSalida
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

    cmp al,'0'        ; rango de dígitos
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


fsalto:
mov dx, offset salto
mov ah,09h
int 21h
ret


codigo ends
end inicio
