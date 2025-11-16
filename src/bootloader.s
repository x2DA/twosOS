org 0x7c00
bits 16

main:

	; Initial setup
	mov ax, 0
	mov ds, ax
	mov es, ax
	mov si, ax
	mov ss, ax
	mov sp, 0x7c00

	; TL;DR: Load ~9kB of kernel positioned RIGHT after the bootloader

	; 512 per sector
	; 1024 cylinders (max BIOS)
	; Floppy: 2 heads, 80 cylinders, 18 sectors: 1474560 bytes 
	mov ah, 0x02 ; Disk access
	mov dh, 0x00 ; Head
	mov ch, 0x00 ; Cylinder
	mov al, 0x12 ; No. sectors to read (18) 9216 bytes
	mov cl, 0x02 ; Starting at sector (1 based)
	mov bx, 0x200 ; Buffer starting at address 0x7e00 (x7c00+x200)

	int 0x13
	jmp bx ; Off to the kernel :D

times 510 - ($-$$) db 0 ; Pad rest of sector
dw 0xaa55

