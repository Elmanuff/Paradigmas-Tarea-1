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
    mensajeInvalidLleno db 0Dh,0Ah,"Se ha llegado al limite de estudiantes$"
    mensajeInvalidVacio db 0Dh,0Ah,"No se han ingresado estudiantes$"
    
    salto db 0Dh,0Ah, "$"
    
    aprobados dw 0
    reprobados dw 0
    total_notas dw 15 ;TEMPORAL
     
    array_notas db 15,92,87,12,70,9,21,10,3,100,65,23,44,19,11

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
    mov si,offset bufferEntrada+2 ;inicio del texto
    mov bx,si
    add bx,cx ;fin del texto
    dec bx                         

buscar_espacio:
    cmp byte ptr [bx],' '
    je espacio_encontrado
    dec bx
    loop buscar_espacio
    
    jmp invalidLleno;si no hay espacio se devuelve al menu

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
    ;limitar longitud a 31 caracteres
    cmp cx,31
    jbe nombre_ok
    mov cx,31
    
nombre_ok:
    rep movsb
    mov byte ptr [di],'$'

    ;copiar nota
    inc bx ;primer caracter de la nota
    mov si,bx

    mov cl,[bufferEntrada+1] ;longitud total
    mov ch,0
    mov dx,offset bufferEntrada+2
    add dx,cx ;fin del texto
    sub dx,bx ;longitud nota
    mov cx,dx

    ; calcular destino en arrayNotas
    mov al,contadorEst
    xor ah,ah
    mov dl,10 ;cada nota ocupa 10 bytes
    mul dl                    
    mov di,offset arrayNotas
    add di,ax

    ;limitar longitud nota a 9 caracteres
    cmp cx,9
    jbe nota_ok
    mov cx,9
    
nota_ok:
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

    call fsalto
    xor cx, cx        ; CX = aprobados
    xor dx, dx        ; DX = reprobados
    mov si, offset array_notas
    mov di, 15        ; contador de 15 notas

    contar_loop:
    mov al, [si]
    cmp al, 70
    jl es_reprobado
    inc cx
    jmp siguiente
    es_reprobado:
    inc dx
    siguiente:
    inc si
    dec di
    jnz contar_loop

    ; guardar en memoria (asegúrate de haber declarado estas vars en datos)
    mov [aprobados], cx
    mov [reprobados], dx

    ; --- MOSTRAR APROBADOS ---
    call fsalto
    mov dx, offset mensajeAprobados
    mov ah, 09h
    int 21h

    mov ax, [aprobados]
    call print_num

    ; --- CALCULAR PORCENTAJE DE APROBADOS ---
    mov ax, [aprobados]
    mov cx, 100
    mul cx              
    mov bx,15
    div bx
    
    push ax
    mov dx,offset mensajePorcentaje
    mov ah,09h
    int 21h
    pop ax
    call print_num
    mov dl,'%'
    mov ah,02h
    int 21h
    call fsalto              

    ; --- MOSTRAR REPROBADOS ---
    mov dx, offset mensajeReprobados
    mov ah, 09h
    int 21h

    mov ax, [reprobados]
    call print_num

    ; --- PORCENTAJE REPROBADOS ---   
    mov ax,[reprobados]
    mov cx,100
    mul cx
    mov bx,15
    div bx
    
    push ax
    mov dx,offset mensajePorcentaje
    mov ah,09h
    int 21h
    pop ax
    call print_num
    mov dl,'%'
    mov ah,02h
    int 21h
    call fsalto
    

    jmp menu

    
                  
                  
    



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
    mov dx, offset preguntaSort
    mov ah,09h
    int 21h 
    
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
    call fsalto
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
    ret
     


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


print_num endp
codigo ends
end inicio
