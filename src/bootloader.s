org 0x7c00
bits 16
VGATmem equ 0xb800 ; VGA Text Mode Buffer Start
scrdim equ 77fh ; 24*80 + 1
scrwidth equ 80h

	; Initial setup

	mov ax, VGATmem
	mov es, ax ; Set ES to the text buffer, since we won't use it anywhere else

	xor ax, ax
	mov ds, ax
	mov si, ax
	mov di, ax ;
	mov ss, ax
	mov sp, 0x7c00


jmp main
; Data goes here.
; Remember to zero terminate strings!
ypressed db "You pressed: ", 0
axt db "a", 0
bxt db "b", 0
cxt db "c", 0
dxt db "d", 0
bpt db "BP", 0
spt db "SP", 0


main:

	call clear_screen

	mov bx, 0h
	mov si, ypressed
	call write_line

	mov ah, 00h
	int 16h
	call write_char

	mov cx, 10d
	call sys_wait
jmp main

; Functions go here.
; All functions that use interrupts (directly) will follow 'sys_func_name:'

; Most functions that write text to the vidmem won't set the bg/fg, rather,
; they leave it as is.

; IN [SI]: Zero terminated string.
; OUT[SI]: End of zero terminated string.
; IN [BX]: Offset from top left.
; OUT[BX]: Offset strlen+1 of initial offset.
; OUT[AL]: Zero, probably.
write_line:
	shl bx, 1
	.loop:
		mov al, [si]
		cmp al, 0h
		je .done ; Exit if we're at the end

		mov [es:bx], al
		inc si
		add bx, 2h
	jmp .loop
	.done:
	shr bx, 1h

ret


; IN [AL]: Char.
; IN [BX]: Offset from top left.
; OUT[BX]: Offset +1 of initial offset.
write_char:
	shl bx, 1
	mov [es:bx], al
	shr bx, 1
	add bx, 1
ret


; OUT[BX]: About 77fh.
; OUT[AX]: 0720h. (Grey on white, space) 
clear_screen:
	mov bx, 0h
	mov ax, 0720h
	.loop:
		mov [es:bx], ax
		add bx, 2
	cmp bx, scrdim
	jl .loop
ret



; OUT[AH]: Read BIOS scancode.
; OUT[AL]: Read ASCII char.
sys_get_key:

ret


; IN [CX]: Time in ms.
; OUT[CX:DX]: Overwritten with time in microseconds.
; Stops system for CX ms.
sys_wait:
	push ax

	xchg ax, cx
	mov cx, 1000d ; 1ms = 1k microsecs
	mul cx ; [DX:AX] Holds the result, move to [CX:DX]

	mov cx, dx
	mov dx, ax

	pop ax

	mov ah, 86h
	int 15h
ret

times 510 - ($-$$) db 0 ; Pad rest of sector
dw 0xaa55

