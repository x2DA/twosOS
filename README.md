# bootloader OS

# How to build
## Dependencies
`nasm, qemu` (Though, any other assembler and virtualizer with BIOS support should work, but you'll have to tweak the build script)

## Compiling
Boils down to assembling the bootloader into a flat-form binary. With nasm this becomes:
```
nasm "bootloader.s" -f bin -o "bOS.img"
```
## Running
```
qemu-system-i386 -drive file=bOS.img, format=raw
```
