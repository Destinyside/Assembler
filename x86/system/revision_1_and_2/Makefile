#eclipse
PROJECT_ROOT = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

ifeq ($(OS),Windows_NT)
	PLATFORM="Windows"
else
	ifeq ($(shell uname),Darwin)
		PLATFORM="MacOS"
	else
		PLATFORM="Unix-Like"
	endif
endif
 
CC=gcc
#CCFLAGS= -Wall -nostdlib -fPIC -g -ffreestanding
CCFLAGS= -g -m32 -Wall  -fno-builtin -fno-stack-protector -fomit-frame-pointer -fstrength-reduce
LD=ld
LDFLAGS= 
#-static -nostartfiles -Ttext=0x40000000
ifeq ($(PLATFORM), "Windows")
	LDFLAGS+= -m i386pe #-s 
else
	LDFLAGS+= -m elf_i386 #-s
endif
RPATH=../../
AS=as 
ASFLAGS= --32 -n -g -o 
DD=dd
OBJCOPY=objcopy
INCLUDE=-I$(RPATH)include
BPATH=
TARGET=Image
BOOTS=$(RPATH)boot/boot.s
SETUPS=$(RPATH)boot/setup.s
HEADS=$(RPATH)boot/head.s
BOOTLDS=$(RPATH)boot/ldS.ld
OBJS=$(RPATH)boot/boot.s
OBJC=$(RPATH)main.c
OBJLDS=$(RPATH)ldS.ld
SYS=$(RPATH)system
ifeq ($(PLATFORM), "Windows")
	QEMU=qemu-system-x86_64.exe
else
	QEMU=qemu-system-x86_64
endif


.c.o: 
	$(CC) $(CCFLAGS) $(INCLUDE) -c -o $*.o $<

.s.o: 
	$(AS) $(ASFLAGS) -c  -o $*.o $<

all: $(TARGET)
	
$(TARGET): $(BOOTS:%.s=%) $(SETUPS:%.s=%) $(SYS) 
	$(DD) if=$(BOOTS:%.s=%) of=$(TARGET) bs=512 count=1
	$(DD) if=$(SETUPS:%.s=%) of=$(TARGET) bs=512 count=4 seek=1
	$(DD) if=$(SYS) of=$(TARGET) bs=512 seek=5
	exec $(QEMU) -fda $(TARGET)

$(SYS): ${OBJC:%.c=%.o} $(HEADS:%.s=%.o)
	$(LD) $(LDFLAGS) -T $(OBJLDS) -o $(SYS) $(HEADS:%.s=%.o) ${OBJC:%.c=%.o} 
	$(OBJCOPY) -O binary -R .note -R .comment $(SYS) $(SYS)

$(BOOTS:%.s=%): $(BOOTS)
	$(AS) $(ASFLAGS) $(BOOTS:%.s=%.o) $(BOOTS)
	$(LD) $(LDFLAGS) -T $(BOOTLDS) -o $(BOOTS:%.s=%) $(BOOTS:%.s=%.o)
	$(OBJCOPY) -j .text -S -O binary $(BOOTS:%.s=%)

$(SETUPS:%.s=%): $(SETUPS)
	$(AS) $(ASFLAGS) $(SETUPS:%.s=%.o) $(SETUPS)
	$(LD) $(LDFLAGS) -T $(BOOTLDS) -o $(SETUPS:%.s=%) $(SETUPS:%.s=%.o)
	$(OBJCOPY) -j .text -S -O binary $(SETUPS:%.s=%)

$(HEADS:%.s=%.o): $(HEADS)
	$(AS) $(ASFLAGS) $(HEADS:%.s=%.o) $(HEADS)

clean:
	rm -f ${OBJC:%.c=%.o}
	rm -f $(BOOTS:%.s=%) $(BOOTS:%.s=%.o) $(SETUPS:%.s=%) $(SETUPS:%.s=%.o) $(HEADS:%.s=%.o)
	rm -f $(SYS)
	rm -f $(TARGET)
