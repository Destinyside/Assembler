
# boot.S  
   


.equ MAGIC, 0xe85250d6 
.equ ARCH, 0 /* i386 */
.equ HEADER_LEN, header_end - header_start
.equ CHECKSUM, -(MAGIC + ARCH + HEADER_LEN)
.equ STACK_SIZE, 0x4000

.section .multiboot
header_start:
	.long MAGIC
	.long ARCH 
	.long HEADER_LEN 
	.long CHECKSUM

	/* multiboot tags are here */

	/* end tag */
	.short 0 /* end tag type */
	.short 0 /* flags */
	.long 8 /* size of the tag including itself */
header_end:

.text  
        .global  start, _start  
   
start:  
_start:  
        jmp     multiboot_entry  
   
multiboot_entry:  
        /* 初始化堆栈指针。 */  
        movl    $(stack + STACK_SIZE), %esp  
   
        /* 重置 EFLAGS。 */  
        pushl   $0  
        popf  
   
        pushl   %ebx  
        pushl   %eax  
   
        /* 现在进入 C main 函数... */  
        call    main  
   
loop:   hlt  
        jmp     loop  
   
.global func_hlt
.global func_outb, func_outw, func_outl
.global func_inb, func_inw, func_inl
.global func_cli, func_sti
.global func_leflag, func_seflag

func_hlt:    #void FunctionHlt(void)
    hlt
    ret

func_outb:   #void FunctionOut8(int port, int data)
    movl    4(%esp),    %edx
    movb    8(%esp),    %al
    outb    %al,        %dx
    ret

func_outw:  #void FunctionOut16(int port, int data)
    movl    4(%esp),    %edx
    movw    8(%esp),    %ax
    outw    %ax,        %dx
    ret

func_outl:  #void FunctionOut32(int port, int data)
    movl    4(%esp),    %edx
    movl    8(%esp),    %eax
    outl    %eax,       %dx
    ret

func_inb: #int FunctionIn8(int port)
    movl    4(%esp),    %edx
    movb    $0,        %al
    inb %dx,        %al
    ret

func_inw:    #int FunctionIn16(int port)
    movl    4(%esp),    %edx
    movw    $0,        %ax
    inw %dx,        %ax
    ret

func_inl:    #int FunctionIn32(int port)
    movl    4(%esp),    %edx
    movl    $0,        %eax
    inl %dx,        %eax
    ret

func_cli:    #void FunctionCli(void)
    cli
    ret

func_sti: #void FunctionSti(void)
    sti
    ret

func_leflag: #int FunctionLoadEflags(void)
    pushf
    pop %eax
    ret

func_seflag:    #void FunctionStoreEflags(int eflags)
    mov 4(%esp),    %eax
    push    %eax
    popf
    ret

        .comm   stack, STACK_SIZE  
