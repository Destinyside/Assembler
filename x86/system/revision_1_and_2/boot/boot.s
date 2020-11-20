

	.code16									#   十六位汇编
	.global	_start							# 程序开始
.text										# 代码段
	.equ 	SYSSIZE, 	0x3000				#   系统段长度3000
	.equ 	BOOTSEG, 	0x07c0				# equ定义常量#被BIOS识别为启动扇区,装载到内存0x07co处,
											# 此时处于实汇编,内存寻址为 (段地址 << 4 +量) 可寻址的线性空间为 20位
    .equ 	SYSSEG, 	0x1000				# system 程序的装载地址
    .equ 	INITSEG, 	0x9000				#   初始化位置
    .equ 	SETUPSEG, 	0x9020				#   初始化开始执行位置
    .equ 	SETUPLEN, 	0x04				#   初始化程序长度
    .equ 	ROOT_DEV, 	0x301				# ROOT_DEV
    .equ 	ENDSEG, 	SYSSEG+SYSSIZE		# 结束位置

    ljmp 	$BOOTSEG,	$_start 			# 修改cs寄存器为BOOTSEG,并跳转到_start处执行代码

_start:
	movw	$BOOTSEG,	%ax					# ax = BOOTSEG
	movw	%ax, 		%ds					# ds = ax
	mov		$INITSEG,	%ax					# ax = INITSEG
	mov		%ax, 		%es					# es = ax
	mov		$256, 		%cx					# cx = 256
	xor		%si, 		%si					# si清零
	xor		%di, 		%di					# di清零
	rep		movsw							# 将DS：(E)SI规定的源串元素复制到ES：(E)DI规定的目的串单元中

	movw    $msg_boot_loader,	%si			# 将字符串地址放到SI，源变址寄存器，可用来存放相对于DS段之源变址指针
	callw	print_str						# 调用输出程序

	ljmp	$INITSEG,	$go					# 长跳转，段间跳转，以段开始为0，go距离

go:
	movw	%cs,		%ax					# ax = cs
	movw	%ax,		%es					# es = ax，扩展段寄存器
	movw	%ax,		%ds					# ds = ax，数据段寄存器，一般用于存放数据；相当于c语言中的全局变量
	movw	%ax,		%ss					# ss = ax，栈段寄存器，一般作为栈使用 和sp搭档；ss相当于堆栈段的首地址  sp相当于堆栈段的偏移地址
											# cs，代码段寄存器，一般用于存放代码；通常和IP 使用用于处理下一条执行的代码 cs:IP基地址：偏移地址
	mov		$0xFF00, 	%sp					# 不跳转继续向下执行

#################### 读取软盘加载setup,start 	####################

load_setup:									# 这里我们需要将软盘中的内容加载到内存中，并且跳转到相应地址执行代码
	mov		$0x0000,	%dx					# 选择磁盘号0，磁头号0进行读取，dh 磁头[0, 1]，DL 驱动器（0x0 ~ 0x7f表示软盘，0x80 ~ 0xff表示硬盘）
	mov		$0x0002,	%cx					# 从二号扇区，0轨道开始读(注意扇区是从1开始编号的)，CH 柱面[0, 79]， CL 扇区[1, 18]
	mov		$INITSEG,	%ax					# ES:BX 指向装载目的地址
	mov		%ax,		%es					# es = ax = INITSEG
	mov		$0x0200,	%bx					# es:BX 数据装载到 INITSEG:0200
	mov		$02,		%ah					# BIOS中断0x13功能号02，读取扇区到内存
	mov		$SETUPLEN,	%al					# al存入读取的扇区数
	int		$0x13							#   调用BIOS中断0x13读取软盘
	jc		read_err						# 读取出错
	jnc		load_ok							# 没有异常，加载成功
	mov		$0x0000,	%dx					# 磁盘号0，磁头号0
	mov		$0x0000,	%ax					# BIOS中断0x13功能号00复位驱动器
	int		$0x13							#   调用BIOS中断0x13读取软盘
	jmp		load_setup						# 一直重试，直到加载成功

load_ok:                           			# Here will jump to where the demo program is
	mov		$0x00,		%dl					#
	mov		$0x0800,	%ax					#
	int		$0x13							#
	mov		$0x00,		%ch					#
	mov		%cx,		%cs:sectors+0		#
	mov		$INITSEG,	%ax					#
	mov		%ax,		%es					#
	mov 	$SYSSEG,	%ax					# 接下来将整个系统镜像装载到0x1000:0000开始的内存中
	mov		%ax,		%es					# ES = ax = SYSSEG
	call 	read_it							#
	call 	kill_motor						#

	mov		%cs:root_dev,	%ax				#
	cmp		$0,			%ax					#
	jne		root_defined					# ROOT_DEV != 0, Defined root
	mov		%cs:sectors+0,	%bx				# else check for the root dev
	mov		$0x0208,	%ax					#
	cmp		$15,		%bx					# Sector = 15, 1.2Mb Floopy Driver
	je      root_defined					#
	mov		$0x021c,	%ax					#
	cmp		$18,		%bx					# Sector = 18 1.44Mb Floppy Driver
	je		root_defined					#

undef_root:									# If no root found, loop forever
	jmp		undef_root_error				#
	jmp		die

root_defined:
	mov		%ax,		%cs:root_dev+0
	ljmp	$SETUPSEG,	$0					#   所有加载完毕，跳转到setup加载的位置开始执行

sread:										#
	.word 1 + SETUPLEN              		# 当前轨道读取的扇区数
head:										#
	.word 0                                 # 当前读头
track:										#
	.word 0                                 # 当前轨道

read_it:									# 读取setup.s之后的head.s
	mov		%es, 		%ax					#
	test 	$0x0fff,	%ax					#

read_die:									#
	jne		read_die						# If es is not at 64KB(0x1000) Boundary, then stop here
	xor		%bx,		%bx					#

rp_read:									#
	mov		%es,		%ax					#
	cmp		$ENDSEG,	%ax					#
	jb		ok1_read						# If $ENDSEG > %ES, then continue reading, else just return
	ret

ok1_read:									#
	mov		%cs:sectors+0,	%ax				#
	sub		sread,		%ax					#
	mov		%ax,		%cx					# Calculate how much sectors left to read
	shl		$9,			%cx					# cx = cx * 512B 2^9 = 512
	add		%bx,		%cx					# current bytes read in now
	jnc		ok2_read						# If not bigger than 64K, continue to ok_2
	je		ok2_read						#
	xor		%ax,		%ax					#
	sub		%bx,		%ax					#
	shr		$9,			%ax					#

ok2_read:									#
	call	read_track						#
	mov		%ax,		%cx					# cx = num of sectors read so far
	add		sread,		%ax					#
	cmp		%cs:sectors+0,	%ax				#
	jne		ok3_read						#
	mov		$1,			%ax					#
	sub		head,		%ax					#
	jne		ok4_read						#
	incw	track							#

ok4_read:									#
	mov		%ax,		head				#
	xor		%ax,		%ax					#

ok3_read:									#
	mov		%ax,		sread				#
	shl		$9,			%cx					#
	add		%cx,		%bx					# HERE!!! I MADE A FAULT HERE!!!
	jnc		rp_read							# If shorter than 64KB, then read the data again, else, adjust ES to next 64KB segment, then read again
	mov		%es,		%ax					#
	add		$0x1000,	%ax					#
	mov		%ax,		%es					# Change the Segment to next 64KB
	xor		%bx,		%bx					#
	jmp		rp_read							#

read_track:									# This routine do the actual read
	push	%ax								#
	push	%bx								#
	push	%cx								#
	push	%dx								#
	mov		track,		%dx					# Set the track number $track, disk number 0
	mov		sread,		%cx					#
	inc		%cx								#
	mov		%dl,		%ch					#
	mov		head,		%dx					#
	mov		%dl,		%dh					#
	mov		$0,			%dl					#
	and		$0x0100,	%dx					#
	mov 	$2,			%ah					#
	int		$0x13							#
	jc		bad_rt							#
	pop		%dx								#
	pop		%cx								#
	pop		%bx								#
	pop		%ax								#
	ret										#

bad_rt:										#
	mov		$0,			%ax					#
	mov		$0,			%dx					#
	int		$0x13							#
	pop		%dx								#
	pop		%cx								#
	pop		%bx								#
	pop		%ax								#
	jmp		read_track						#

kill_motor:									#
	push	%dx								#
	mov		$0x3f2,		%dx					#
	mov		$0,			%al					#
	outsb									#
	pop		%dx								#
	ret										#

undef_root_error:							# 读取错误输出错误信息
	mov		%ax,		%bx					# bx = ax
	mov		$msg_undef_root,	%si			# 把si指向msg_undef_root的地址
	callw	print_str						# 调用print_str
	jmp		die								# 死循环
	ret

read_err:									# 读取错误输出错误信息
	mov		%ax,		%bx					# bx = ax
	mov		$msg_read_err,		%si			# 把si指向msg_read_error的地址
	callw	print_str						# 调用print_str
	jmp		die								# 死循环
	ret

msg_str:									# 输出字符串
	.asciz "this is a output str!\r\n"

msg_undef_root:								#
	.asciz "ROOT DEV UNDEFINED!\r\n"

msg_read_err:								# 读取磁盘错误字符串
	.asciz "READ DISK ERROR!\n"

msg_read_suc:								# 读取磁盘成功字符串
	.asciz "READ DISK SUCCESS!\n"

root_dev:
	.word ROOT_DEV

sectors:
	.word 0

#################### 读取软盘加载setup,end 		####################

print_str:									# 输出函数，需要将输出移动到si，1.mov $msg_chk_err, %si 2.callw print_str 3.ret
	lodsb									#
	andb	%al, 		%al					#
	jz		print_end						# BIOS中断0x10功能号0xe，
											# 在Teletype模式下显示字符，具体说就是在屏幕的光标处写一个字符，并推进光标的位置。
	movb	$0xe,		%ah					# AH＝0EH，AL＝字符，BH＝页码，BL＝前景色(图形模式)；
	movw	$0x000a,	%bx					# 注意，仅在图形模式下，设置BL才会改变前景色；在文本模式下，这个参数不起作用
	int		$0x10							# BIOS中断0x10显示字符
	xorw	%ax,		%ax					# ax清零
	jmp		print_str						# 循环print_str

print_end:
	xorw	%ax,		%ax					# ax清零
	ret										#

die:										# 死循环
	jmp		die

msg_boot_loader:							# ascii字符串
	.asciz	"Bootloader ... ...\r\n"

	.org	0x1fe             				# 对齐语法,等价于.=0x1fe,表示在该处补0,即第一扇区的最后两字节，(attempt to move .org backwards)

boot_flag:									# 在此填充魔术值,BIOS会识别硬盘中第一扇区,以0xaa55结尾的为启动扇区,于是BIOS会装载
    .word	0xAA55
