org 0x7e00
VGATmem equ 0xb800 ; VGA text mode buffer start
screendim equ 1920 ; 24x80

xor ax, ax
xor di, di
xor si, si

mov ds, ax
mov es, ax
mov ss, ax

mov ax, 0x7e00
mov sp, ax
mov bp, sp
xor ax, ax

main:
	

	mov al, 40h ; @
	mov ah, 1ch
	mov bx, 0002h
	call write_char

	mov dh, 00h
	mov dl, 00h
	call set_cursor

	jmp force_shutdown



jmp main


; Expects ax(stringZ offset), bx (offset from top left), dl (bg|fg)
write_line:
ret


; Expects ah(bg|fg) al(char), bx(offset from top left)
; The offset should not be a power of two, we account for that :)
write_char:
	push bx

	push ax
	mov ax, VGATmem
	mov es, ax
	pop ax

	shl bx, 1

	mov [es:bx], ax
	pop bx
ret


; Expects: dh(row) dl(col) (starting top left)
set_cursor:
	push ax
	push bx

	mov ah, 0x02 ; Set cursor position
	mov bh, 0 ; Page number
	int 0x10

	pop bx
	pop ax
ret



force_shutdown:
	; int 15, ax 5307h (apm state)
	; bx (Device ID) cx (System State ID)

	mov ax, 5307h
	mov bx, 0001h ; All
	mov cx, 0003h ; Off
	int 15

	; Support for APM 1.0, where SysID OFF not supporting DevID ALL

	; Re-set ah since the err code is written there, al and cx shouldn't be modified
	mov ah, 53h;
	mov bx, 02ffh ; storage (all secondary)
	int 15

	mov ah, 53h
	mov bx, 01ffh ; display (all)
	int 15

	mov ah, 53h
	mov bx, 04ffh ; serial ports (all)
	int 15

	mov ah, 53h
	mov bx, 03ffh ; parallel ports (all)
	int 15

	cli
	halt_cpu:
		hlt
	jmp halt_cpu

jmp force_shutdown


times 9216 - ($-$$) db 0 ; Pad out remaining 18 sectors

