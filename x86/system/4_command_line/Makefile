


CC=gcc
#CCFLAGS= -Wall -nostdlib -fPIC -g -ffreestanding
CCFLAGS= -g -m32 -Wall  -fno-builtin -fno-stack-protector -fomit-frame-pointer -fstrength-reduce
LD=ld
LDFLAGS=
#-static -nostartfiles -Ttext=0x40000000
LDFLAGS= -m elf_i386 #-s
AS=as 
ASFLAGS= --32
DD=dd
OBJCOPY=objcopy
INCLUDE=-I./include
TARGET=Image
#OBJS=boot.s setup.s
OBJC=main.c device/do_keyboard.c device/video.c sys/mm.c sys/str.c sys/lisp.c

.c.o: 
	$(CC) $(CCFLAGS) $(INCLUDE) -c -o $*.o $<

.s.o: 
	$(AS) $(ASFLAGS) -c  -o $*.o $<

all: $(TARGET)

$(TARGET): boot/boot boot/setup system 
	$(DD) if=boot/boot of=$(TARGET) bs=512 count=1
	$(DD) if=boot/setup of=$(TARGET) bs=512 count=4 seek=1
	$(DD) if=system of=$(TARGET) bs=512 seek=5
	#rm temp.img

system: ${OBJC:%.c=%.o} boot/head.o device/keyboard.o
	$(LD) $(LDFLAGS) -T ldS.ld -o system boot/head.o device/keyboard.o ${OBJC:%.c=%.o} 
	$(OBJCOPY) -O binary -R .note -R .comment system system

device/keyboard.o: device/keyboard.s

boot/boot: boot/boot.s
	$(AS) $(ASFLAGS) -n -g -o boot/boot.o boot/boot.s
	$(LD) $(LDFLAGS) -T boot/ldS.ld -o boot/boot boot/boot.o
	$(OBJCOPY) -j .text -S -O binary boot/boot

boot/setup: boot/setup.s
	$(AS) $(ASFLAGS) -n -g -o boot/setup.o boot/setup.s
	$(LD) $(LDFLAGS) -T boot/ldS.ld -o boot/setup boot/setup.o
	$(OBJCOPY) -j .text -S -O binary boot/setup

boot/head.o: boot/head.s
	$(AS) $(ASFLAGS) -n -g -o boot/head.o boot/head.s

clean:
	rm ${OBJC:%.c=%.o}
	rm boot/boot
	rm boot/setup
	rm boot/head.o
	rm system
	rm $(TARGET)
