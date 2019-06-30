

	#.code16 	#十六位汇编
	.global	_start 	#程序开始
	.text
	.word   0xABCD
	.equ 	INITSEG, 0x1000 #equ定义常量；被BIOS识别为启动扇区，装载到内存0x07co处
#此时处于实汇编，内存寻址为 (段地址 << 4 +量) 可寻址的线性空间为 20位


	#ljmp 	$BOOTSEG,$_start #修改cs寄存器为BOOTSEG，并跳转到_start处执行代码

	#ljmp	$INITSEG, $_start
_start:
	mov 	$0x10, %ax    #ax = BOOTSEG
        movw    %ax, %es         #设置ES寄存器，为输出字符串作准备
        movw    %ax, %ds
        movw    %ax, %ss
        xorw    %sp, %sp
        sti
        cld

        movw    $msg1, %si
        callw   print_str

	jmp	go

go:
	movw    $__bss_start, %di
        movw    $_end+3, %cx
        xorl    %eax, %eax
        subw    %di, %cx
        shrw    $2, %cx

# Jump to C code (should not return)
        jmp   main
	#ljmp	$INITSEG, $0x0

die:
        jmp     die

.globl print_str
print_str:
        lodsb
        andb    %al, %al
        jz      bs_die
        movb    $0xe, %ah
        movw    $7, %bx
        int     $0x10
        jmp     print_str

bs_die:
        xorw    %ax, %ax
        #int     $0x16
        #int     $0x19

        # int 0x19 should never return.  In case it does anyway,
        # invoke the BIOS reset code...
        ret
        #ljmp    $0xf000,$0xfff0

sectors:
	.word 	0

crlf:
	.ascii	"\n"

msg1:
	.byte 	13, 10
	.ascii 	"Hello world!"
	.byte 	13,10,13,10
	
.=0x1fe             #对齐语法，等价于.org，表示在该处补0，即第一扇区的最后两字节

#在此填充魔术值，BIOS会识别硬盘中第一扇区，以0xaa55结尾的为启动扇区，于是BIOS会装载
boot_flag:
        .word 0xAA55

