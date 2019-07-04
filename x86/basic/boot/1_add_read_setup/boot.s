

	.code16 	#十六位汇编
	.global	_start 	#程序开始
	.text
	.equ 	BOOTSEG, 0x07c0 #equ定义常量#被BIOS识别为启动扇区,装载到内存0x07co处
#此时处于实汇编,内存寻址为 (段地址 << 4 +量) 可寻址的线性空间为 20位
	.equ	INITSEG, 0x1000
	.equ 	SYSSEG, 0x1000		    # system 程序的装载地址
	.equ	SETUPSEG, 0x1020
	.equ	SYSLEN, 0x9
	.equ	SYSSIZE, 0x9216

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

	ljmp	$INITSEG, $main

main:
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
	mov 	$SYSLEN, %al				# 读取的扇区数
	int 	$0x13
	jc  	read_err				# 调用BIOS中断读取
	jnc 	demo_load_ok		# 没有异常，加载成功
	mov 	$0x0000, %dx
	mov 	$0x0000, %ax		# Service 0: Reset the Disk
	int 	$0x13
	jmp 	load_setup			# 并一直重试，直到加载成功

demo_load_ok:				# Here will jump to where the demo program is
	mov 	$SETUPSEG, %ax
	mov	%ax, %ds		
	ljmp 	$SETUPSEG, $0		# jump to where the demo program exists (Demo code, removed now)

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



sectors:
	.word 	0

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

