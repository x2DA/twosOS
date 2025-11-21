org 0x7c00
bits 16
; HJKL - Move
; ` - Switch between normal and insert

; ----
; CONSTANTS
; ----

VGATmem equ 0xb800 ; VGA Text Mode Buffer Start
screen_buffer_size equ 4000d ; (25*80)*2(bytes)
screen_width equ 80d
background_color equ 8f20h

; ----
; SETUP
; ----

mov dx, VGATmem
mov es, dx ; Do NOT change ES in any function

xor dx, dx

mov ds, dx
mov ss, dx
mov sp, 0x7c00

; ----
; MAIN
; ----

main:
	; ---- Clear Screen ----
	mov bx, 0h
	mov ax, background_color
	.cls_loop:
		mov [es:bx], ax
		add bx, 2
	cmp bx, screen_buffer_size
	jl .cls_loop
	; ---- Clear Screen ----


	; ---- Draw Cursor ----
	mov bx, [cursor] ; At
	mov ah, [cursor+2] ; Color
	call xy2dto1d
	mov al, '=' ; Char
	shl bx, 1
	mov [es:bx], ax
	shr bx, 1
	; ---- Draw Cursor ----


	; ---- Draw Buffer ----
	mov si, calcBuffer+2
	mov bx, [calcBuffer]
	call xy2dto1d
	call write_line
	; ---- Draw Buffer ----

	
	; ---- Eval & Draw Buffer Result ----
	mov bx, 0h ; First 4 digit hex
	call dump_to_dx
	mov ax, dx

	mov bx, 6h
	mov cl, [calcBuffer+bx] ; Sign

	push cx
	mov bx, 5h ; Second 4 digit hex (+1 for sign)
	call dump_to_dx
	mov bx, dx
	pop cx


	cmp cl, '*'
	je .op_multiply
	cmp cl, '/'
	je .op_divide
	cmp cl, '+'
	je .op_add
	cmp cl, '-'
	je .op_sub
	jmp .op_done

	.op_multiply:
		mul bx
	jmp .op_done
	
	.op_divide:
		div bx
	jmp .op_done
	
	.op_add:
		add ax, bx
	jmp .op_done

	.op_sub:
		sub ax, bx
	jmp .op_done


	.op_done:
	mov bx, 0h

	push dx
	mov dx, ax
	call dump_dx
	pop dx
	inc bx
	call dump_dx
	mov bx, 80d
	mov si, regnames
	call write_line
	; ---- Eval & Draw Buffer Result ----

	call handle_user_input
jmp main



; ----
; FUNCTIONS
; ----


; IN [BH]: X hex
; IN [BL]: Y hex
; OUT[BX]: Offset from 00
xy2dto1d:
	push ax
	xor ax, ax
	
	mov al, bl
	mov bl, screen_width
	mul bl ; AX = y*width

	xor bl, bl
	xchg bl, bh
	add ax, bx ; AX = y*width+x
	mov bx, ax

	pop ax
ret

; Messes AX and BX
handle_user_input:
	xor ah, ah
	int 16h ; Read key into AL

	cmp al, '`'
	je .togglemode

	mov ah, [cursor+3]
	cmp ah, 1h ; Jump to writemode if the mode byte is set.
	je .key_writemode

	cmp al, 'h'
	je .key_left
	cmp al, 'j'
	je .key_down
	cmp al, 'k'
	je .key_up
	cmp al, 'l'
	je .key_right
	jmp .key_handled


	.togglemode:
		mov ax, [cursor+2] ; toggle: ah mode, al color
		xor ax, 0117h
		mov [cursor+2], ax

		call .loadcursor
		inc ah
		mov [calcBuffer], ax
	jmp .key_handled

	.key_writemode:
		mov bx, [calcBufferWritten]
		cmp bx, 0ah ; buffersize+1
		jle .inbuffer
			mov bx, 2 ; We're out of the buffer, re-set
		.inbuffer:
		mov [calcBuffer+bx], al
		add bx, 1
		mov [calcBufferWritten], bx
	jmp .key_handled



	.loadcursor:
		mov ax, [cursor]
	ret

	.key_left:
		call .loadcursor
		add ah, 0ffh
	jmp .key_move_handled
	.key_down:
		call .loadcursor
		add al, 01h
	jmp .key_move_handled
	.key_up:
		call .loadcursor
		add al, 0ffh
	jmp .key_move_handled
	.key_right:
		call .loadcursor
		add ah, 01h
	jmp .key_move_handled


	.key_move_handled:
		mov [cursor], ax
	.key_handled:
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


; IN [DHl]: Hex nibble to convert to ASCII.
; IN [DHh]: Zero
; OUT[DH]: ASCII output
nibble2asciihexbyte:
	add dh, 30h
	cmp dh, 3ah
	jl .done
	add dh, 07h
	.done:
ret

; IN [DH]: ASCII input.
; OUT[DHh]: Zero
; OUT[DHl]: Converted hex nibble from ASCII.
asciihexbyte2nibble:
	sub dh, 30h
	cmp dh, 0fh
	jl .done
	sub dh, 07h
	.done:
ret


; IN [BX]: Offset from top left.
; OUT[BX]: End of string offset + 1
dump_dx:
	shl bx, 1
	jmp .start

	.dump_nibble:
		call nibble2asciihexbyte

		mov [es:bx], dh
		add bx, 2
	ret

	.start:
	; High DH
	push dx
	and dh, 0xf0
	shr dh, 4 ; dh = 0000xxxx
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

	shr bx, 1
ret


; IN [BX]: Offset from the base of buffer.
; OUT[DX]: Hex word (translated from ASCII) starting at offset.
; Overwrites cx
dump_to_dx:
	mov cx, 0h
	add bx, 2h
	jmp .start

	.dump_ascii:
		mov dh, [calcBuffer+bx]
		call asciihexbyte2nibble
		inc bx
	ret


	.start:
	call .dump_ascii
	shl dh, 4
	or ch, dh

	call .dump_ascii
	or ch, dh

	call .dump_ascii
	shl dh, 4
	or cl, dh

	call .dump_ascii
	or cl, dh

	mov dx, cx

ret



; ----
; VARIABLES
; ----
regnames db "AX:DX",0

cursor db 00h, 09h, 70h, 00h ; Y,X, Color, Mode,Modifier
; Modes: 0 Normal, 1 Write

calcBuffer:
	db 00h
	db 0ah
	times 09h db 2eh
	db 00h
	calcBufferWritten db 02h

times 510 - ($-$$) db 0 ; Pad rest of sector
dw 0xaa55

