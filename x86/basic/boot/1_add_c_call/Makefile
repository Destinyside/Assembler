


CC=gcc
CCFLAGS=-O2 -Wall -nostdlib -fPIC -g -ffreestanding
LD=ld
LDFLAGS:= --oformat binary -N 
#-static -nostartfiles -Ttext=0x40000000
LDFLAGS=-m elf_x86_64 -s -x
AS=as
ASFLAGS=
DD=dd
OBJCOPY=objcopy
INCLUDE=-Iinclude
BOOTSEG=0x7c00
INITSEG=0
TARGET=Image
#OBJS=boot.s setup.s
OBJC=main.c

.c.o: 
	$(CC) $(CCFLAGS) $(INCLUDE) -c -o $*.o $<

.s.o: 
	$(AS) $(ASFLAGS) -c  -o $*.o $<

all: $(TARGET)

$(TARGET): boot system 
	$(DD) if=boot of=$(TARGET) ibs=512 count=1 conv=notrunc
	$(DD) if=system of=$(TARGET) ibs=512 seek=1 #count=2879
	#rm temp.img

system: ${OBJC:%.c=%.o} setup.o
	$(LD) $(LDFLAGS) -Ttext $(INITSEG)  -o system setup.o ${OBJC:%.c=%.o}

boot: boot.o
	$(LD) $(LDFLAGS) -Ttext 0 -o boot $<
	$(OBJCOPY) -O binary boot

tools/build: tools/build.c
	$(CC) $(CFLAGS) \
		        -o tools/build tools/build.c
	#chmem +65000 tools/build

clean:
	rm *.o
	rm boot
	rm system
	rm $(TARGET)
