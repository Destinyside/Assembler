

	.code16 	#十六位汇编
	
	.equ	SYSSIZE, 0x3000	

	.global	_start 	#程序开始
	.text
	.equ 	BOOTSEG, 0x07c0 #equ定义常量#被BIOS识别为启动扇区,装载到内存0x07co处
#此时处于实汇编,内存寻址为 (段地址 << 4 +量) 可寻址的线性空间为 20位
	.equ 	SYSSEG, 0x1000		    # system 程序的装载地址
	.equ	INITSEG, 0x9000
	.equ	SETUPSEG, 0x9020
	.equ	SETUPLEN, 0x04
	.equ	ROOT_DEV, 0x301
	.equ	ENDSEG, SYSSEG+SYSSIZE

	ljmp 	$BOOTSEG,$_start #修改cs寄存器为BOOTSEG,并跳转到_start处执行代码
_start:

	movw 	$BOOTSEG, %ax    #ax = BOOTSEG
	movw	%ax, %ds
	mov 	$INITSEG, %ax
        mov 	%ax, %es
        mov 	$256, %cx
        xor 	%si, %si
        xor 	%di, %di
        rep 	movsw

	movw	$msg_boot_loader, %si
	callw	print_str

	ljmp	$INITSEG, $go

go:
	movw	%cs, %ax
	movw	%ax, %es
	movw	%ax, %ds
	movw	%ax, %ss
	mov	$0xFF00, %sp

	
load_setup:
	# 这里我们需要将软盘中的内容加载到内存中，并且跳转到相应地址执行代码
	mov 	$0x0000, %dx		# 选择磁盘号0，磁头号0进行读取
	mov 	$0x0002, %cx		# 从二号扇区，0轨道开始读(注意扇区是从1开始编号的)
	mov 	$INITSEG, %ax		# ES:BX 指向装载目的地址
	mov 	%ax, %es
	mov 	$0x0200, %bx		
	mov 	$02, %ah			# Service 2: Read Disk Sectors
	mov 	$SETUPLEN, %al				# 读取的扇区数
	int 	$0x13
	jc  	read_err				# 调用BIOS中断读取
	jnc 	demo_load_ok		# 没有异常，加载成功
	mov 	$0x0000, %dx
	mov 	$0x0000, %ax		# Service 0: Reset the Disk
	int 	$0x13
	jmp 	load_setup			# 并一直重试，直到加载成功

demo_load_ok:				# Here will jump to where the demo program is
	#mov 	$SETUPSEG, %ax
	#mov	%ax, %ds		
	#ljmp 	$SETUPSEG, $0		# jump to where the demo program exists (Demo code, removed now)



##############################################

	mov $0x00, %dl
        mov $0x0800, %ax
        int $0x13
        mov $0x00, %ch
        mov %cx, %cs:sectors+0
        mov $INITSEG, %ax
        mov %ax, %es

# 接下来将整个系统镜像装载到0x1000:0000开始的内存中
        mov $SYSSEG, %ax
        mov %ax, %es                    # ES 作为参数
        call read_it
        call kill_motor

        mov %cs:root_dev,%ax
        cmp $0, %ax
        jne root_defined                # ROOT_DEV != 0, Defined root
        mov %cs:sectors+0, %bx    # else check for the root dev
        mov $0x0208, %ax
        cmp $15, %bx
        je      root_defined            # Sector = 15, 1.2Mb Floopy Driver
        mov $0x021c, %ax
        cmp $18, %bx                    # Sector = 18 1.44Mb Floppy Driver
        je root_defined

undef_root:                                     # If no root found, loop forever
        jmp undef_root

root_defined:

        mov %ax, %cs:root_dev+0

# Now everything loaded into memory, we jump to the setup-routine
# which is now located at 0x9020:0000

        ljmp $SETUPSEG, $0


# Here is the read_it routine and kill_motor routine
# read_it 和 kill_motor 是两个子函数，用来快速读取软盘中的内容，以及关闭软驱
# 电机使用，下面是他们的代码

# 首先定义一些变量， 用于读取软盘信息使用

sread:  .word 1 + SETUPLEN              # 当前轨道读取的扇区数
head:   .word 0                                 # 当前读头
track:  .word 0                                 # 当前轨道


read_it:
        mov %es, %ax
        test $0x0fff, %ax
read_die:
        jne read_die                         # If es is not at 64KB(0x1000) Boundary, then stop here
        xor %bx, %bx
rp_read:
        mov %es, %ax
        cmp $ENDSEG, %ax
        jb ok1_read                     # If $ENDSEG > %ES, then continue reading, else just return
        ret
ok1_read:

        mov %cs:sectors+0, %ax
        sub sread, %ax
        mov %ax, %cx            # Calculate how much sectors left to read
        shl $9, %cx                     # cx = cx * 512B
        add %bx, %cx            # current bytes read in now
        jnc ok2_read            # If not bigger than 64K, continue to ok_2
        je ok2_read
        xor %ax, %ax
        sub %bx, %ax
        shr $9, %ax
ok2_read:
        call read_track
        mov %ax, %cx            # cx = num of sectors read so far
        add sread, %ax

        cmp %cs:sectors+0, %ax
        jne ok3_read
        mov $1, %ax
        sub head, %ax
        jne ok4_read
        incw track
ok4_read:
        mov %ax, head
        xor %ax, %ax
ok3_read:
        mov %ax, sread
        shl $9, %cx
        add %cx, %bx            # HERE!!! I MADE A FAULT HERE!!!
        jnc rp_read                     # If shorter than 64KB, then read the data again, else, adjust ES to next 64KB segment, then read again
        mov %es, %ax
        add $0x1000, %ax
        mov %ax, %es            # Change the Segment to next 64KB
        xor %bx, %bx
        jmp rp_read

# Comment for routine 0x13 service 2
# AH = 02
# AL = number of sectors to read        (1-128 dec.)
# CH = track/cylinder number  (0-1023 dec., see below)
# CL = sector number  (1-17 dec.)
# DH = head number  (0-15 dec.)
# DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
# ES:BX = pointer to buffer

read_track:                             # This routine do the actual read
        push %ax
        push %bx
        push %cx
        push %dx
        mov track, %dx          # Set the track number $track, disk number 0
        mov sread, %cx
        inc %cx
        mov %dl, %ch
        mov head, %dx
        mov %dl, %dh
        mov $0, %dl
        and $0x0100, %dx
        mov $2, %ah
        int $0x13
        jc bad_rt
        pop %dx
        pop %cx
        pop %bx
        pop %ax
        ret

bad_rt:
        mov $0, %ax
        mov $0, %dx
        int $0x13
        pop %dx
        pop %cx
        pop %bx
        pop %ax
        jmp read_track

kill_motor:
        push %dx
        mov $0x3f2, %dx
        mov $0, %al
        outsb
        pop %dx
        ret

##############################################



read_err:
    	mov 	%ax, %bx
	mov 	$msg_read_err, %si
	callw 	print_str
    	jmp 	die
    	ret

chk_err:
	mov	$msg_chk_err, %si
	callw	print_str
	jmp	die
	ret

die:    
	jmp 	die


print_str:
	lodsb
        andb    %al, %al
        jz      print_end
        movb    $0xe, %ah
        movw    $0x000a, %bx
        int     $0x10
	xorw    %ax, %ax  
        jmp	print_str

print_end:
	xorw	%ax, %ax
	ret

root_dev:
        .word ROOT_DEV

sectors:
	.word 0

crlf:	.asciz  "\r\n"
step:	.asciz  "steping\r\n"

msg_boot_loader:	.asciz 	"Bootloader ... ...\r\n"

msg_str:	.asciz "this is a output str!\r\n"

msg_read_err:	.asciz "READ DISK ERROR!"

msg_read_suc:	.asciz "READ DISK SUCCESS!"

msg_chk_err:	.asciz "CHECK READ ERROR!"

msg_chk_suc:	.asciz "CHECK READ SUCCESS!"



.=0x1fe             #对齐语法,等价于.org,表示在该处补0,即第一扇区的最后两字节

#在此填充魔术值,BIOS会识别硬盘中第一扇区,以0xaa55结尾的为启动扇区,于是BIOS会装载
boot_flag:
	.word 0xAA55

