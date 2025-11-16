org 0x200
VGATmem equ 0xb800 ; VGA text mode buffer start
screendim equ 77fh ; 24*80-1, starting from the VGATmem

xor ax, ax
xor di, di
xor si, si

mov ds, ax
mov es, ax
mov ss, ax

mov ax, 0x200
mov sp, ax
mov bp, sp
xor ax, ax

jmp main

; Data goes here

welcome db "Welcome to 2Sos!", 0



jmp main

main:

	mov al, 20h ; ' '
	mov ah, 07h
	call fill_screen

	mov si, welcome
	mov ah, 07h
	mov bx, 0h
	call write_line

	mov dh, 00h
	mov dl, 10h
	call set_cursor

	jmp force_shutdown

jmp main



;	SI (Zero terminated string),
;	BX (Offset from top left)
;	AH (BG|FG)
; The offset shouldn't be a power of two, it is accounted for :)
write_line:
	push ax
	push bx
	push si

	call set_es_to_vidmem

	shl bx, 1
	.loop:
		mov al, [si]
		cmp al, 0
		je .done
		mov [es:bx], ax

		inc si
		add bx, 2
	jmp .loop

	.done:
	pop si
	pop bx
	pop ax
ret


;	AX ( [(BG|FG)] [Char] )
; Where ( [AH] [AL] )
fill_screen:
	push bx
	push cx
	push es

	call set_es_to_vidmem

	mov bx, 0
	.loop:
		cmp bx, screendim
		jge .done

		mov [es:bx], ax
		add bx, 2
	jmp .loop

	.done:
	pop es
	pop cx
	pop bx
ret


;	AX ( [(BG|FG)] [Char] )
; Where ( [AH] [AL] )
;	BX (Offset from top left)
; The offset shouldn't be a power of two, it is accounted for :)
write_char:
	push bx

	call set_es_to_vidmem

	shl bx, 1

	mov [es:bx], ax
	pop bx
ret


;	DH (row)
;	DL (col)
set_cursor:
	push ax
	push bx

	mov ah, 0x02 ; Set cursor position
	mov bh, 0 ; Page number
	int 0x10

	pop bx
	pop ax
ret


set_es_to_vidmem:
	push ax
	mov ax, VGATmem
	mov es, ax
	pop ax
ret



jmp main
force_shutdown:
	; int 15, AX 5307h (APM state)
	; BX (Device ID), CX (System State ID)

	mov ax, 5307h
	mov bx, 0001h ; All
	mov cx, 0003h ; Off
	int 15


	; Support for APM 1.0, where SysID OFF not supporting DevID ALL

	; Re-set AH since the error code is written there, AL and CX shouldn't be modified
	mov ah, 53h;
	mov bx, 02ffh ; Storage (all secondary)
	int 15

	mov ah, 53h
	mov bx, 01ffh ; Display (all)
	int 15

	mov ah, 53h
	mov bx, 04ffh ; Serial ports (all)
	int 15

	mov ah, 53h
	mov bx, 03ffh ; Parallel ports (all)
	int 15

	cli
	halt_cpu:
		hlt
	jmp halt_cpu

jmp force_shutdown


times 9216 - ($-$$) db 0 ; Pad out remaining 18 sectors

