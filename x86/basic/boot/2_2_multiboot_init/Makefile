


CC=gcc
#CCFLAGS= -Wall -nostdlib -fPIC -g -ffreestanding
CCFLAGS= -g -m32 -Wall  -fno-builtin -fno-stack-protector -fomit-frame-pointer -fstrength-reduce
LD=ld
LDFLAGS=
#-static -nostartfiles -Ttext=0x40000000
LDFLAGS=-m elf_i386  #-s
AS=as 
ASFLAGS=  --32
DD=dd
OBJCOPY=objcopy
INCLUDE=-Iinclude
BOOTSEG=0x7c00

INITSEG=0x10000
TARGET=Image
#OBJS=boot.s setup.s
OBJC=main.c

.c.o: 
	$(CC) $(CCFLAGS) $(INCLUDE) -c -o $*.o $<

.s.o: 
	$(AS) $(ASFLAGS) -c  -o $*.o $<

all: $(TARGET)

$(TARGET): system 
	$(DD) if=/dev/zero of=$(TARGET) bs=512 count=1
	$(DD) if=system of=$(TARGET) bs=512 count=9 seek=1
	$(DD) if=/dev/zero of=$(TARGET) bs=512 count=65526 seek=10
	#rm temp.img

system: ${OBJC:%.c=%.o} entry.o
	$(LD) $(LDFLAGS) -Ttext $(INITSEG) -o system entry.o ${OBJC:%.c=%.o}
	$(OBJCOPY) -O binary -R .note -R .comment system system

clean:
	rm *.o
	rm system
	rm $(TARGET)
