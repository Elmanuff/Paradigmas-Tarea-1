title RegistroCE

datos segment
;declarar variables aqui------------------------------------------------  
    mensaje1 db 0Dh,0Ah, "(A)scendente o (D)escendent: $" 
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

;mostrar menu
mov dx, offset mensaje1
mov ah,09h
int 21h 

;leer opcion
mov ah,01h
int 21h
cmp al, 'A'
je asc
cmp al, 'D'
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
