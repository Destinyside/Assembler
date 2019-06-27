#!/bin/bash

SFILE=$1
OFILE=$SFILE.o
BFILE=$OFILE.bo
IMGFILE=$OFILE.img
as -32 -o $OFILE $SFILE
ld -m elf_i386 -Ttext 0 -o $BFILE $OFILE
objcopy -O binary $BFILE
qemu-system-i386 $BFILE
#dd if=/dev/zero of=$IMGFILE bs=512 count=2880
#dd if=$BFILE ibs=512 skip=8 of=$IMGFILE obs=512 seek=0 count=1

#qemu-system-x86_64 -fda boot.s.o.img -boot a -m 64
