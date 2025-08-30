title RegistroCE

datos segment
;declarar variables aqui------------------------------------------------  
   
    mensaje1 db 0Dh,0Ah,"(1) Ingresar nuevo estudiante,(2)Mostrar estadisticas$"
    mensaje2 db 0Dh,0Ah,"(3)Buscar estudiante por posicion,(4)Ordenar calificaciones, (5)Salir $"  
    
    mensajeNombre db 0Dh,0Ah, "Nombre del estudiante: $"
    mensajeNota db 0Dh,0Ah, "Calificacion: $" 
    mensajeExito db 0Dh,0Ah, "Calificacion agregada con exito $"
    
    bufferNombre db 30,0,30 dup ('$') ;max 30 caracteres
    bufferNota db 9,0,9 dup('$') ;max 9 caracteres
    
    arrayNombres db 15 dup(31 dup('$'))   
    arrayNotas db 15 dup (16 dup('$'))
                                       
    contadorEst db 0
    
       
    preguntaSort db 0Dh,0Ah, "(A)scendente o (D)escendente: $" 
    mensajeResul db 0Dh,0Ah, "Resultado: $"
    salto db 0Dh,0Ah,"$"
     

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

;mostrar menu principal
mov dx, offset mensaje1 
mov ah,09h
int 21h 

mov dx,offset mensaje2
mov ah,09h
int 21h
         
         
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

jmp exit

  



ingresar: 
mov dx, offset mensajeNombre
mov ah,09h
int 21h  

mov dx,offset bufferNombre
mov ah,0Ah
int 21h

;copiar nombre a arreglo
mov si,offset bufferNombre+2
mov bl,contadorEst
mov bh,0
mov di,offset arrayNombres
mov ax,31
mul bx
add di,ax
mov cl,[bufferNombre+1]
xor ch,ch
rep movsb 




mov dx,offset mensajeNota
mov ah,09h
int 21h    

mov dx,offset bufferNota
mov ah,0Ah
int 21h
       
;copiar nota a arreglo
mov si,offset bufferNota+2
mov bl,contadorEst
mov bh,0
mov di,offset arrayNotas
mov ax,16
mul bx
add di,ax
mov cl,[bufferNota+1]
xor ch,ch
rep movsb

   






estadisticas:


buscar:



sort:  
mov dx, offset preguntaSort
mov ah,09h
int 21h 

mov ah,01h
int 21h 

cmp al,'A'
je asc

cmp al,'D'
je desc


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
mov dx, offset mensajeResul  
mov ah,09h
int 21h

mov cx,15
mov si,0

print_loop:
mov al,array_notas[si]
call print_num
mov dx,offset salto
mov ah,09h
int 21h
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






exit:
print_num endp
codigo ends
end inicio
