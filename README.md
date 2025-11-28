# bootloader "OS" space-tuned SDK

## Usage:
Cursor: h, j, k, l
Cursor highlight: v (toggle, highlights from position @ the time of toggle to cursor position)

## Build:
```
nasm "bootloader.s" -f bin -o "NAME.img"
```
## Run:
```
qemu-system-i386 -drive file=NAME.img, format=raw
```
