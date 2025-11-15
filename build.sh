#!/usr/bin/env bash
SOURCEFOLDER="src"
BUILDFOLDER="cache"

nasm "${SOURCEFOLDER}/bootloader.s" -f bin -o "${BUILDFOLDER}/bootloader.bin"
nasm "${SOURCEFOLDER}/kernel.s" -f bin -o "${BUILDFOLDER}/kernel.bin"
cat "${BUILDFOLDER}/bootloader.bin" "${BUILDFOLDER}/kernel.bin" > os.img

