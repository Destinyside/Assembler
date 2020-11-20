


CC=gcc
CCFLAGS=-O2 -Wall -nostdlib -fPIC
LD=ld
CFLAGS:= -ffreestanding
#LDFLAGS:= -static -nostartfiles -Ttext=0x40000000
LDFLAGS=-m elf_x86_64 -Ttext 0
AS=as
ASFLAGS=
OBJCOPY=objcopy
INCLUDE=-I./
TARGET=boot.bin
OBJS=boot.s

.s.o: 
	$(AS) $(ASFLAGS) -o $*.o $<

$(TARGET): ${OBJS:%.s=%.o}
	$(LD) $(LDFLAGS) -o $(TARGET) ${OBJS:%.s=%.o}
	$(OBJCOPY) -O binary $(TARGET)

clean:
	rm *.o
	rm $(TARGET)
