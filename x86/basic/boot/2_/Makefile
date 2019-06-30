


CC=gcc
CCFLAGS=-O2 -Wall -nostdlib -fPIC
LD=ld
CFLAGS:= -ffreestanding
#LDFLAGS:= -static -nostartfiles -Ttext=0x40000000
LDFLAGS=-m elf_x86_64 -Ttext 0 
AS=as
ASFLAGS=
OBJCOPY=objcopy
INCLUDE=-Iinclude
TARGET=Image
#OBJS=boot.s setup.s
OBJC=main.c

.c.o: 
	$(CC) $(CCFLAGS) $(INCLUDE) -c -o $*.o $<

.s.o: 
	$(AS) $(ASFLAGS) -o $*.o $<

.S.o: 
	$(AS) $(ASFLAGS) -o $*.o $<

all: $(TARGET)

$(TARGET): boot system tools/build
	cat boot system > $(TARGET)
	rm boot
	rm system
	#tools/build boot system > $(TARGET)
	sync
	#$(OBJCOPY) -O binary $(TARGET)

system: ${OBJC:%.c=%.o} setup.o
	$(LD) $(LDFLAGS) -o system setup.o ${OBJC:%.c=%.o}
	rm ${OBJC:%.c=%.o}

boot: boot.o 
	$(LD) $(LDFLAGS) -o boot boot.o
	rm boot.o
	$(OBJCOPY) -O binary boot

tools/build: tools/build.c
	$(CC) $(CFLAGS) \
		-o tools/build tools/build.c
	#chmem +65000 tools/build

clean:
	rm *.o
	rm $(TARGET)
