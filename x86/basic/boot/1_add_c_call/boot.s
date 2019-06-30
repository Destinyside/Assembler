

	.code16 	#十六位汇编
	.global	_start 	#程序开始
	.text
	.equ 	BOOTSEG, 0x07c0 #equ定义常量；被BIOS识别为启动扇区，装载到内存0x07co处
#此时处于实汇编，内存寻址为 (段地址 << 4 +量) 可寻址的线性空间为 20位
	.equ	INITSEG, 0x1000
	.equ	MOVESEG, 0x9000
	.equ	SYSLEN, 0x16
	.equ	SYSSIZE, 0x9216
	#ljmp 	$BOOTSEG,$_start #修改cs寄存器为BOOTSEG，并跳转到_start处执行代码


_start:
	movw 	$BOOTSEG, %ax    #ax = BOOTSEG
	movw 	%ax, %es         #设置ES寄存器，为输出字符串作准备
	movw	%ax, %ds
	movw	%ax, %ss
	xorw	%sp, %sp
	sti
	cld
	rep stosw

	movw	$msg_boot_loader, %si
	callw	print_str

	movw	$msg_str, %si
	callw 	print_str
	
	ljmp 	$MOVESEG,$main

clear_screen:				# 清屏函数
	movb	$0x06,	%ah		# 功能号0x06
	movb	$0x00,	%al		# 上卷全部行，即清屏
	movb	$0x00,	%ch		# 左上角行
	movb	$0x00,	%ch		# 左上角列	
	movb	$0x18,	%dh		# 右下角行
	movb	$0x4F,	%dl		# 右下角列
	movb	$0x07,	%bh		# 空白区域属性
	int		$0x10
	
	ret


read_a_sect:
       movb    $36,    %dl
       divb    %dl
       movb    %al,    %ch             # 柱面号=N / 36, 假设x = N % 36
       movb    %ah,    %al             # AL = N % 36
       xorb    %ah,    %ah             # AH = 0, 则AX = AL = N % 36
       movb    $18,    %dl
       divb    %dl
       movb    %al,    %dh             # 磁头号DH = x / 18
       movb    %ah,    %cl             # CL = x % 18
       incb    %cl                             # 扇区号CL = x % 18 + 1

       movb    $0x00,  %dl             # 驱动器号DL = 0，表示第一个软盘即floppya
       movb    $0x02,  %ah             # 功能号0x02表示读软盘
       movb    $0x01,  %al             # 读取一个扇区数

re_read:                                       # 若调用失败（可能是软盘忙损坏等）则重新调用
       int             $0x13
       jc              re_read                 # 若进位位（CF）被置位，表示调用失败##
       ret
#
#-------------------------------------------------------------------
# 读取内核到内存
#       该函数读取baby OS 的内核到内存，第一个扇区为引导扇区，需要读取
#       的是从第二个扇区（相对扇区号1）开始的KERNEL_SECT_NUM个扇区
#       ES：BX为缓冲区，为读取内核的临时位置0x10000
#-------------------------------------------------------------------
read_kernel:
       movw    $INITSEG>>4,%si
       movw    %si,                            %es             # ES:BX 为缓冲区地址
       xorw    %bx,                            %bx
       movw    $0x01,                          %di             # 相对扇区号
1:
       movw    %di,                            %ax             # 将相对扇区号传给AX作为参数
       call    read_a_sect

       addw    $0x512>>4,          %si
       movw    %si,  %es
       incw    %di
       cmpw    $SYSLEN+1,     %di
       jne             1b

       ret


# load the setup-sectors directly after the bootblock.

# Note that 'es' is already set up.
disk_addr_packet:
    	.byte   0x10                        # [0] size of packet 16 bytes
    	.byte   0x00                        # [1] reserved always 0
    	.word   0x01                        # [2] blocks to read
    	.word   0x00                        # [4] transfer buffer(16 bit offset)
    	.word   0x00                        # [6] transfer buffer(16 bit segment)
    	.long   0x01                        # [8] starting LBA
    	.long   0x00                        # [12]used for upper part of 48 bit LBAs

read_a_sect_hd:
    	lea     disk_addr_packet,   %si
    	movb    $0x42,              %ah
    	movb    $0x80,              %dl
    	int     $0x13

    	ret


read_kernel_hd:
    	lea     disk_addr_packet,   %si
    	movw    $INITSEG>>4,6(%si)
    	xorw    %cx,                %cx

read_sect:
    	call    read_a_sect_hd

    	lea     disk_addr_packet,   %si
    	movl    8(%si),             %eax
    	addl    $0x01,              %eax
    	movl    %eax,               (disk_addr_packet + 8)

    	movl    6(%si),             %eax
    	addl    $512>>4,            %eax
    	movl    %eax,               (disk_addr_packet + 6)

	incw	%cx
	cmpw	$SYSLEN+1,	%cx
	jne	read_sect

    	ret

move_loader:
	cli									# 指明SI，DI递增
	movw	$INITSEG>>4,%ax
	movw	%ax,				%ds		# DS:SI 为源地址
	xorw	%si,				%si
	movw	$0x00,				%ax
	movw	%ax,				%es		# ES:DI 为目标地址
	xorw	%di,				%di
	movw	$0x512 * SYSLEN >> 2,	%cx		# 移动512/4 次
	rep	movsl						# 每次移动4个byte

	ret

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
        jz      bs_die
        movb    $0xe, %ah
        movw    $7, %bx
        int     $0x10
        jmp	print_str

bs_die:
	xorw    %ax, %ax
        #int     $0x16
        #int     $0x19

        # int 0x19 should never return.  In case it does anyway,
        # invoke the BIOS reset code...
        ret
	#ljmp    $0xf000,$0xfff0

enter_protected_mode:
	cli									# 关中断
	lgdt	gdt_ptr						# 加载GDT

enable_a20:	
	inb	$0x64,			%al			# 从端口0x64读取数据
	testb	$0x02,			%al			# 测试读取数据第二个bit
	jnz	enable_a20					# 忙等待

	movb	$0xdf,			%al
	outb	%al,			$0x60		# 将0xdf写入端口0x60

	movl	%cr0,			%eax		# 读取cr0寄存器
	orl	$0x01,			%eax		# 置位最后以为即PE位
	movl	%eax,			%cr0		# 写cr0寄存器

	ljmp	$0x8, $0x0		# 跳转到代码段，即load.s处开始执行
	
	ret 

main:
       	#call    clear_screen
        call    read_kernel_hd
        #call    move_loader
        call    enter_protected_mode            # 进入保护模式
	#jmp die
	#jmp	*INITSEG
	#ljmp	$0x8, $0x0

1:
        jmp             1b

gdt:
	.quad	0x0000000000000000			# 空描述符
	.quad	0x00cf9a000000ffff			# 代码段描述符
	.quad	0x00cf92000000ffff			# 数据段描述符
	.quad	0x0000000000000000			# 留待以后使用
	.quad	0x0000000000000000			# 留待以后使用

gdt_ptr:								# 用与lgdt 加载GDT
	.word	0 - gdt - 1		# GDT段限长
	.long	(0x90000 + (256*8))					# GDT基地址

sectors:
	.word 	0

crlf:
        .asciz  "\r\n"

msg_boot_loader:	.asciz 	"Bootloader ... ...\r\n"

msg_str:	.asciz "this is a output str!\r\n"

msg_read_err:	.asciz "READ DISK ERROR!"

msg_read_suc:	.asciz "READ DISK SUCCESS!"

msg_chk_err:	.asciz "CHECK READ ERROR!"

msg_chk_suc:	.asciz "CHECK READ SUCCESS!"



	.=0x1fe             #对齐语法，等价于.org，表示在该处补0，即第一扇区的最后两字节

#在此填充魔术值，BIOS会识别硬盘中第一扇区，以0xaa55结尾的为启动扇区，于是BIOS会装载
boot_flag:
	.word 0xAA55

