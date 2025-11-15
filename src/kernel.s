org 0x7e00
VGATmem equ 0xb800 ; VGA text mode buffer start

mov ax, 0
mov ds, ax
mov di, ax
mov ss, ax

main:
	

	mov al, 40h ; @
	mov ah, 1ch
	mov bx, 0002h
	call write_char

	mov dh, 00h
	mov dl, 00h
	call set_cursor

	jmp halt_cpu



jmp main


; Expects ax(stringZ offset), bx (offset from top left), dl (bg|fg)
write_line:


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


; Expects: dh(row) dl(col)
set_cursor:
	push ax
	push bx

	mov ah, 0x02 ; Set cursor position
	mov bh, 0 ; Page number (0 in graphics)
	int 0x10 ; dh (row), dl (col), starting top left

	pop bx
	pop ax
ret


halt_cpu:
	cli
	hlt
jmp halt_cpu

times 9216 - ($-$$) db 0 ; Pad out remaining 18 sectors

