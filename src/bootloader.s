org 0x7c00
bits 16
VGATmem equ 0xb800 ; VGA Text Mode Buffer Start
scrdim equ 4000d ; (24*80)*2(bytes)
scrwidth equ 80d

; ----
; SETUP
; ----

mov ax, VGATmem
mov es, ax ; Set ES to the text buffer, since we won't use it anywhere else


xor bx, bx ; TODO: Figure what gets overwritten initially
xor cx, cx ; And remove from here to save a few words
xor dx, dx

mov ah, 02h
int 10h ; Set real cursor to start

xor ax, ax

mov ds, ax
mov ss, ax
mov sp, 0x7c00
; Not setting si and di to 0 saves about 2 words
; Which I think outweights the space efficiency of using them.

jmp main

; ----
; VARIABLES
; ----

cursor db 06h, 06h, 0ch, 00h ; Y,X, Color, Mode,Modifier
; Cursor modes: 00 normal
; Cursor controls: hjkl: left, down, up, right
; space - toggle mode


; ----
; MAIN
; ----

main:
	call clear_screen
	call draw_cursor


	mov si, savebuffer ; Show buffer
	mov bx, 0018h
	call xy2dto1d
	call write_line


	call handle_user_input

	mov cx, 10d
	call sys_wait
jmp main

; ----
; FUNCTIONS
; ----

; TODO: Implement basic hex calc


; Note: Memory uses little endian
; IN [BH]: X hex
; IN [BL]: Y hex
; OUT[BX]: Offset from 00
; TODO: Check for vid mem bounds, if we have enough space left in the sector
xy2dto1d:
	push ax
	xor ax, ax
	
	mov al, bl
	mov bl, scrwidth
	mul bl ; AX = y*width

	xor bl, bl
	xchg bl, bh
	add ax, bx ; AX = y*width+x
	mov bx, ax

	pop ax
ret

handle_user_input:
	xor ah, ah
	int 16h ; Read key into AL

	; TODO: Optimize for space
	cmp al, 'h'
	je .left
	cmp al, 'j'
	je .down
	cmp al, 'k'
	je .up
	cmp al, 'l'
	je .right
	cmp al, ' '
	je .togglemode
	jmp .keyhandled

	.left:
		mov ah, [cursor+1]
		sub ah, 01h
		mov [cursor+1], ah
	jmp .keyhandled
	.down:
		mov ah, [cursor]
		add ah, 01h
		mov [cursor], ah
	jmp .keyhandled
	.up:
		mov ah, [cursor]
		sub ah, 01h
		mov [cursor], ah
	jmp .keyhandled
	.right:
		mov ah, [cursor+1]
		add ah, 01h
		mov [cursor+1], ah
	jmp .keyhandled

	.togglemode:
		mov ax, [cursor+2] ; toggle: ah mode, al color
		xor ax, 0101h
		mov [cursor+2], ax
	jmp .keyhandled
	.keyhandled:
ret


draw_cursor:
	mov bx, [cursor] ; Position
	push bx
	mov dx, bx
	mov bx, 0
	call dump_dx
	pop bx

	mov ah, [cursor+2] ; Color
	call xy2dto1d ; Convert from xy to x

	mov al, '.'
	inc cl
	shl bx, 1
	mov [es:bx], ax
	shr bx, 1
	add bx, 1

ret


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


; IN [DHl]: Hex nibble to convert to ASCII.
; IN [DHh]: Zero
; OUT[DH]: ASCII output
nibble2asciihexval:
	add dh, 30h
	cmp dh, 3ah
	jl .done
	add dh, 07h
	.done:
ret


; IN [BX]: Offset from top left.
; OUT[BX]: End of string offset + 1
; OUT[AL]: Lower nibble of DL
dump_dx:
	jmp .start

	.dump_nibble:
		call nibble2asciihexval

		mov al, dh
		call write_char
	ret

	.start:
	; High DH
	push dx
	and dh, 0xf0
	shr dh, 4 ; cl = 0000xxxx
	call .dump_nibble
	pop dx

	; Low DH
	push dx
	and dh, 0x0f
	call .dump_nibble
	pop dx

	; High DL
	push dx
	and dl, 0xf0
	shr dl, 4
	xchg dh, dl
	call .dump_nibble
	pop dx

	; Low DL
	push dx
	and dl, 0x0f
	xchg dh, dl
	call .dump_nibble
	pop dx
ret


; OUT[BX]: About 77fh.
; OUT[AX]: 0720h. (Grey on white, space) 
clear_screen:
	mov bx, 0h
	mov ax, 8720h
	.loop:
		mov [es:bx], ax
		add bx, 2
	cmp bx, scrdim
	jl .loop
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

saveBufferSize db 50h ; CurrentWritten, MaxSize
savebuffer:
	times 50h db 2eh
	saveBufferSZ db 00h
savebufferEnd:

times 510 - ($-$$) db 0 ; Pad rest of sector
dw 0xaa55

