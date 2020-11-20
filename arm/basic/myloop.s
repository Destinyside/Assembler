

	.arch armv7-a
	.fpu vfpv3-d16
	.data
msg:
	.ascii "hello world!\n"
len = . - msg
	.text
	.global _start
_start:
	/* syscall write(int fd, const void* buf, size_t count) */
	mov	r0,	$1	/* fd -> stdout */
	ldr	r1,	=msg	/* buf -> msg */
	ldr	%r2,	=len	/* count -> len(msg) */
	mov	%r7,	$4	/* write is syscall #4 */
	swi	$0		/* invoke syscall */
	mov	%r3,	#9
	b	.L1
.L1:
	cmp	r3,	#0
	beq	.L3
	b	.L2
.L2:
	mov	r0,	$1	/* fd -> stdout */
	ldr	r1,	=msg	/* buf -> msg */
	ldr	%r2,	=len	/* count -> len(msg) */
	mov	%r7,	$4	/* write is syscall #4 */
	swi	$0		/* invoke syscall */
	sub	r3,	r3,	#1
	b	.L1
.L3:	
	/* syscall exit(int status) */
	mov 	%r0,	$0
	mov 	%r7,	$1
	swi 	$0


