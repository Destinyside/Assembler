.section .data
msg:
.ascii "hello world!\n"
len=.-msg

.section .text
.global _start

_start:
movl $0, %edi
jmp _loop

_loop:
movl $len, %edx
movl $msg, %ecx
movl $1, %ebx
movl $4, %eax
int $0x80
incl %edi
cmpl %edi, %edx
je _exit
jmp _loop

_exit:
movl $0, %ebx
movl $1, %eax
int $0x80
