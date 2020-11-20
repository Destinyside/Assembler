

	.code16 	#十六位汇编
	.global _start, show_text
	.text
	.equ 	SYSSEG, 0x1000 #equ定义常量；被BIOS识别为启动扇区，装载到内存0x07co处#此时处于实汇编，内存寻址为 (段地址 << 4 +量) 可寻址的线性空间为 20位
	.equ	INITSEG, 0x1000
	.equ	SETUPSEG, 0x1020


	#ljmp 	$BOOTSEG,$_start #修改cs寄存器为BOOTSEG，并跳转到_start处执行代码

	ljmp	$SETUPSEG, $_start

_start:
	mov 	$INITSEG, %ax    #ax = BOOTSEG
        movw    %ax, %es         #设置ES寄存器，为输出字符串作准备
        movw    %ax, %ds
        movw    %ax, %ss
        xorw    %sp, %sp
        sti
        cld
	rep stosw
	
	
        mov 	$SETUPSEG, %ax
        mov 	%ax, %es

	call	show_text
	
	
show_text:

        mov 	$0x03, %ah
        xor 	%bh, %bh
        int 	$0x10                                       # these two line read the cursor position
        mov 	$0x000a, %bx                        # Set video parameter
        mov 	$0x1301, %ax
        mov 	$0x11, %cx
        mov 	$msg1, %bp
        int 	$0x10


	ljmp	$INITSEG, $main

	#call main

        #ljmp   $0x0, $main
	#ljmp	$INITSEG, $main

#clear_screen:                           # 清屏函数
#        movb    $0x06,  %ah             # 功能号0x06
#        movb    $0x00,  %al             # 上卷全部行,即清屏
#        movb    $0x00,  %ch             # 左上角行
#        movb    $0x00,  %ch             # 左上角列
#        movb    $0x4F,  %dh             # 右下角行
#        movb    $0x4F,  %dl             # 右下角列
#        movb    $0x07,  %bh             # 空白区域属性
#        int             $0x10

#        ret

die:
        jmp     die

sectors:
	.word 	0

crlf:
	.ascii	"\n"

msg1:	.asciz 	"Setting ... ...\r\n"
	
