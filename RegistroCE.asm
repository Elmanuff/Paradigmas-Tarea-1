title RegistroCE

datos segment
;declarar variables aqui------------------------------------------------  
    
    
    mensajeBienvenida db "Bienvenido a RegistroCE",0Dh,0Ah
    db "Digite:$"
    
    mensajeMenu db "1. Ingresar calificaciones",0Dh,0Ah
    db "2. Mostrar estadisticas",0Dh,0Ah
    db "3. Buscar estudiante por posicion",0Dh,0Ah
    db "4. Ordenar calificaciones",0Dh,0Ah
    db "5. Salir$" 
    
    mensajeNombre db 0Dh,0Ah, "Por favor ingrese su estudiante o digite 9 para salir al menu principal:$"
    
    
    bufferNombre db 30,0,30 dup ('$') ;max 30 caracteres
    bufferNota db 9,0,9 dup('$') ;max 9 caracteres
    
    arrayNombres db 15 dup(31 dup('$'))   
    arrayNotas db 15 dup (16 dup('$'))
                                       
    contadorEst db 0
    
       
    preguntaSort db 0Dh,0Ah, "Como desea ordenar las calificaciones: $" 
    preguntaSort1 db 0Dh,0Ah,"(1) Ascendente, (2) Descendente$"
    
    mensajeInvalid db 0Dh,0Ah, "Por favor ingrese un valor valido $"
    
    salto db 0Dh,0Ah, "$"
     

    array_notas db 15,2,87,12,4,9,21,10,3,1,65,23,44,19,11

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

;Aqui comienza el codigo del programa------------------------------------
                       
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

cmp al, '2'
je estadisticas     

cmp al, '3'
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

mov dx,offset bufferNombre
mov ah,0Ah
int 21h

mov al,[bufferNombre+2]
cmp al,'9'
je menu

;Se utiliza el largo del nombre+nota para encontrar el espacio que los divide
;empezando de atras para adelante
mov cl,[bufferNombre+1]
mov ch,0
mov si,offset bufferNombre+2 
mov bx,si
add bx,cx                   
dec bx
 
buscar_espacio:
cmp byte ptr [bx],' '
je encontrado
dec bx
loop buscar_espacio


encontrado:
mov di,offset arrayNombres
mov dx,bx                   
sub dx,si                   
mov cx,dx
rep movsb       

mov byte ptr [di],0

;Saltar el espacio
inc bx

;Suardar Nota
mov di,offset arrayNotas
mov dx,si
add dx,cx                   
mov cl,[bufferNombre+1]
mov ch,0
mov ax, dx   
sub ax, si   
sub cx, ax            
mov si,bx
rep movsb

inc contadorEst

mov byte ptr [di],0 

jmp ingresar   





estadisticas:


buscar:



sort: 
 
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
mov al,array_notas[si]
call print_num
inc si
loop print_loop

;salir
mov ah,4Ch
int 21h

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

fsalto:
mov dx, offset salto
mov ah,09h
int 21h
ret




exit:
print_num endp
codigo ends
end inicio
