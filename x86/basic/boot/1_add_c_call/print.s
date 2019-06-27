

.code16 #十六位汇编
.text
.globl print

print:
push %bp
mov %sp,%bp

mov $0xe,%ah
mov $0x7,%bx
mov 4(%bp),%al
int $0x10

mov %bp,%sp
pop %bp
ret

