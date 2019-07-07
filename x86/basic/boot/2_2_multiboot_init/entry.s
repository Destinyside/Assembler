
# boot.S  
   
	.equ	MULTIBOOT_HEADER_MAGIC, 0x1BADB002  
	.equ	MULTIBOOT_HEADER_FLAGS, 0x00000003  
	.equ 	STACK_SIZE, 0x4000  
   
.text  
        .globl  start, _start  
   
start:  
_start:  
        jmp     multiboot_entry  
   
        .align  4  
   
multiboot_header:  
        .long   MULTIBOOT_HEADER_MAGIC  
        .long   MULTIBOOT_HEADER_FLAGS  
        .long   -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)  
   
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
   
        .comm   stack, STACK_SIZE  
