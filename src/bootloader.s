org 0x7c00
bits 16

; ----
; CONSTANTS
; ----

VGA_text_mode_buffer_start equ 0xb800 ; VGA Text Mode Buffer Start
screen_buffer_size equ 4000d ; (25*80)*2(bytes)
screen_width equ 80d

data_size equ 16d

background_color equ 0420h
highlight_color equ 8a20h

; ----
; SETUP
; ----

mov bx, VGA_text_mode_buffer_start
mov es, bx ; Do NOT change ES


mov sp, 0x7c00


; ---- MAIN ----
main:
	; ---- Clear Screen ----
	xor bx, bx

	.cls_loop:
		mov [es:bx], word background_color
		add bx, 2
	cmp bx, screen_buffer_size
	jl .cls_loop
	; ---- Clear Screen ----

	; ---- Do Cursor & Highlights ----
	mov bl, [cursor+4]
	cmp bl, 1
	jne .hl_dont
		mov bx, [cursor+2]
		.hl_do:
		mov [es:bx], word highlight_color
		add bx, 2
		cmp bx, [cursor]	
		jl .hl_do
	.hl_dont:

	mov bx, [cursor]
	mov [es:bx], ax;word cursor_color
	; ---- Do Cursor & Highlights ----
	xor ax, ax
	xor bx, bx
	xor dx, dx
	; Pray these get initialized to 0.
	;; Sux 4 Speed, Gr8 4 Space
	;mov ds, bx
	;mov ss, ax









	; ---- Running program ----
	jmp prog_start

	; -- prog_vars --


	prog_start:


	; ---- Running program ----










	; ---- Dump Memory 2 Screen ----
	push bx
	xor bx, bx

	call dump_dx ; dx
	mov dx, cx
	call dump_dx ; cx
	pop dx
	call dump_dx ; bx
	mov dx, ax
	call dump_dx ; ax

	mov cx, data_size
	mov ax, bx
	mov bx, 0
	.oneword:
	mov dx, [data+bx]
	add bx, 2
	xchg ax, bx
	call dump_dx
	sub bx, 150d
	xchg ax, bx
	loop .oneword

	; ---- Dump Memory 2 Screen ----

	; ---- Handle Input ----
	xor ah, ah
	int 16h ; Read key into AL

	mov bx, [cursor] ; Cursor Pos

	cmp al, 'h'
	je .key_left
	cmp al, 'j'
	je .key_down
	cmp al, 'k'
	je .key_up
	cmp al, 'l'
	je .key_right
	cmp al, 'v'
	je .key_visual
	jmp .keys_done

	.key_left:
	sub bx, 02h
	jmp .keys_done

	.key_down:
	add bx, 160d
	jmp .keys_done

	.key_up:
	sub bx, 160d
	jmp .keys_done

	.key_right:
	add bx, 02h
	jmp .keys_done

	.key_visual:
	mov al, [cursor+4] ; Visual toggle
	xor al, 1h

	cmp al, 1h
	mov [cursor+4], al ; Visual toggle
	jne .keys_done
	mov [cursor+2], bx ; Set highlight start to cursor pos

	.keys_done:
	mov [cursor], bx ; Cursor Pos
	; ---- Handle Input -----

jmp main
; --- MAIN ---	


; ----
; FUNCTIONS
; ----


; IN: BX - Position on screen; Char + attr. size not accounted for
; OUT: BX - Initial position + 160
dump_dx:
	call onedigit
	call onedigit
	call onedigit
	call onedigit
	add bx, 152d
ret

onedigit:
	push dx

	and dh, 0xf0
	shr dx, 4

	add dh, 30h
	cmp dh, 3ah
	jl .converted
	add dh, 27h ; 07 for uppercase
	.converted:

	mov [es:bx], dh

	pop dx
	rol dx, 4
	add bx, 2
ret



; ----
; VARIABLES
; ----

; cursor pos1,2, highlight pos3,4, highlight
cursor db 00h, 00h, 00h, 00h, 00h

data: times data_size dw 0000h

times 510 - ($-$$) db 0 ; Pad rest of sector
dw 0xaa55

