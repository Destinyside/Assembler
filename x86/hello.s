.equ          SYS_WRITE,	4
.equ          SYS_EXIT,		1
.equ          SYSCALL,		0x80
.equ          STDOUT,		1
.equ          STR_LEN,		12

.section .data    
msg:  
.ascii "hello world!\n"    
len=.-msg                        

.section .text    
.global _start     

_start:                                 
movl 	$len, %edx               
movl 	$msg, %ecx             
movl 	$STDOUT, %ebx                  
movl 	$SYS_WRITE, %eax                  
int 	$SYSCALL                            

movl 	$0, %ebx                
movl 	$SYS_EXIT, %eax                
int 	$0x80                        
