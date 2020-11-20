

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
ISO_DIR=iso
ISO_BOOT=$(ISO_DIR)/boot
GRUB_CONFIG=$(ISO_BOOT)/grub/grub.cfg
INITSEG=0x1000
TARGET=System
INCLUDE=-I./include
#OBJS=boot.s setup.s
OBJC=main.c device/do_keyboard.c device/video.c sys/mm.c

.c.o: 
	$(CC) $(CCFLAGS) $(INCLUDE) -c -o $*.o $<

.s.o: 
	$(AS) $(ASFLAGS) -c  -o $*.o $<

all: $(TARGET).iso

$(TARGET).iso: system
	mkdir -p $(ISO_BOOT)/grub/
	cp $< $(ISO_BOOT)/
	echo 'set timeout=10 ' 			>$(GRUB_CONFIG)
	echo 'set default=0'  			>> $(GRUB_CONFIG)
	echo ''               			>> $(GRUB_CONFIG)
	echo 'menuentry "$(TARGET) OS" {'       >> $(GRUB_CONFIG)
	echo '  multiboot2 /boot/system'    	>> $(GRUB_CONFIG)
	echo '  boot'                           >> $(GRUB_CONFIG)
	echo '}'                                >> $(GRUB_CONFIG)
	grub-mkrescue -o $@ $(ISO_DIR)

device/keyboard.o: device/keyboard.s

system: ${OBJC:%.c=%.o} entry.o device/keyboard.o
	$(LD) $(LDFLAGS) -T ldS.ld -o system entry.o device/keyboard.o ${OBJC:%.c=%.o}
	#$(OBJCOPY) -O binary -R .note -R .comment system system

clean:
	rm *.o
	rm system
	rm *.iso
