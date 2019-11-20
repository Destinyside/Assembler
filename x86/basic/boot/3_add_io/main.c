
typedef struct desc_struct {
	unsigned long a, b;
} desc_table[256];
extern desc_table idt, gdt;
/*
 * 定义了用来在C语言中直接调用的汇编宏函数
 *
 */

#define sti()  __asm__ volatile ("sti"::)
#define cli()  __asm__ volatile ("cli"::)
#define nop()  __asm__ volatile ("nop"::)
#define iret() __asm__ volatile ("iret"::)

// 下面这个宏是通用的设置门描述符的宏，参数分别为
// gate_addr: IDT 描述符的地址; type: 门类型
// dpl: 特权级别; funaddr: 要执行的程序的线性地址
// 设置的过程参考注释
#define _set_gate(gate_addr, type, dpl, funaddr) \
	__asm__ volatile (\
			"movw %%dx, %%ax\n\t"\
			"movw %0, %%dx\n\t"\
			"movl %%eax, %1\n\t"\
			"movl %%edx, %2"\
			:\
			:"i" ((short)(0x8000 + ((dpl) << 13) + ((type) << 8))), \
			"o" (*((char *) (gate_addr))),\
			"o" (*(4 + (char *)(gate_addr))), \
			"a" (0x00080000), \
			"d" ((char*)(funaddr)))

// 陷阱门, Type = 0xF
#define set_trap_gate(n, funaddr) \
	_set_gate(&idt[n], 0xF, 0, funaddr)

// 中断门, Type = 0xE
#define set_intr_gate(n, funaddr) \
	_set_gate(&idt[n], 0xE, 0, funaddr)

#define set_system_gate(n, funaddr) \
	_set_gate(&idt[n], 0xF, 3, funaddr)


#define _set_seg_desc(gate_addr,type,dpl,base,limit) {\
	*(gate_addr) = ((base) & 0xff000000) | \
	(((base) & 0x00ff0000)>>16) | \
	((limit) & 0xf0000) | \
	((dpl)<<13) | \
	(0x00408000) | \
	((type)<<8); \
	*((gate_addr)+1) = (((base) & 0x0000ffff)<<16) | \
	((limit) & 0x0ffff); }

#define _set_tssldt_desc(n,addr,type) \
	__asm__ volatile ("movw $104,%1\n\t" \
			"movw %%ax,%2\n\t" \
			"rorl $16,%%eax\n\t" \
			"movb %%al,%3\n\t" \
			"movb $" type ",%4\n\t" \
			"movb $0x00,%5\n\t" \
			"movb %%ah,%6\n\t" \
			"rorl $16,%%eax" \
			::"a" (addr), "m" (*(n)), "m" (*(n+2)), "m" (*(n+4)), \
			"m" (*(n+5)), "m" (*(n+6)), "m" (*(n+7)) \
			)

#define set_tss_desc(n, addr) _set_tssldt_desc(((char *) (n)), ((int) (addr)), "0x89")
#define set_ldt_desc(n, addr) _set_tssldt_desc(((char *) (n)), ((int) (addr)), "0x82")

int buffer_read_index = 0;
int buffer_write_index = 0;
char buffer[1000] = "";
extern void keyboard_interrupt();

extern void func_cli(void);
extern void func_outb(int port, int data);
extern int func_inb(int port);
extern int func_leflag(void);
extern void func_seflag(int eflags);

void memcpy(char *dest, char *src, int count, int size) {
	int i;
	int j;
	for(i = 0; i < count; i++) {
		for(j = 0; j < size; j++) {
			*(dest + i*size + j) = *(src + i*size + j);
		}
	}
	return ;
}
/*

#######################################################################

*/ 

#define PAGE_SIZE 4096
long user_stack[PAGE_SIZE >> 2];
struct {
	long *a;
	short b;
} stack_start = {&user_stack[PAGE_SIZE >> 2], 0x10};

void video_clear();
void video_putchar(char ch);
void video_putchar_at(char ch, int x, int y, char attr);
void update_cursor(int row, int col);
void roll_screen();
int video_x, video_y;

#define VIDEO_MEM 0xB8000
#define VIDEO_X_SZ 80
#define VIDEO_Y_SZ 25
#define TAB_LEN 8
#define CALC_MEM(x, y) (2*((x) + 80*(y)))
char *video_buffer = (char *)VIDEO_MEM;

void video_init() {
	// struct video_info *info = (struct video_info *)0x9000;

	video_x = 0;
	video_y = 0;
	video_clear();
	update_cursor(video_y, video_x);
}

int video_getx() {
	return video_x;
}

int video_gety() {
	return video_y;
}


void update_cursor(int row, int col) {
	unsigned int pos = ((unsigned int)row * VIDEO_X_SZ) + (unsigned int)col;
	// LOW Cursor port to VGA Index Register
	func_outb(0x3D4, 0x0F);
	func_outb(0x3D5, (unsigned char)(pos & 0xFF));
	// High Cursor port to VGA Index Register
	func_outb(0x3D4, 0x0E);
	func_outb(0x3D5, (unsigned char)((pos >> 8) & 0xFF));
}

int get_cursor() {
	int offset;
	func_outb(0x3D4,0xF);
	offset=func_inb(0x3D5)<<8;
	func_outb(0x3D4,0xE);
	offset+=func_inb(0x3D5);
	return offset;
}


void video_putchar(char ch) {
	if(ch == '\n') {
		video_x = 0;
		video_y++;
	}
	else if(ch == '\t') {
		while(video_x % TAB_LEN) video_x++;
	}
	else if(ch == '\b') {
		video_x--;
		if (video_x < 0) {
			video_x = VIDEO_X_SZ;
			video_y--;
			if (video_y < 0) video_y = 0;
		}
		// erase char
		video_putchar_at(' ', video_x, video_y, 0x0F);
	}
	else {
		video_putchar_at(ch, video_x, video_y, 0x0F);
		video_x++;

	}
	if(video_x >= VIDEO_X_SZ) {
		video_x = 0;
		video_y++;
	}
	if(video_y >= VIDEO_Y_SZ) {
		roll_screen();
		video_x = 0;
		video_y = VIDEO_Y_SZ - 1;
	}

	update_cursor(video_y, video_x);
}

void video_clear() {
	int i;
	int j;
	video_x = 0;
	video_y = 0;
	for(i = 0; i < VIDEO_X_SZ; i++) {
		for(j = 0; j < VIDEO_Y_SZ; j++) {
			video_putchar_at(' ', i, j, 0x0F);  // DO NOT USE 0x00 HERE, YOU WILL LOSE YOUR LOVELY BLINKING CURSOR(
		}
	}
}

void video_putchar_at(char ch, int x, int y, char attr) {
	if(x >= 80)
		x = 80;
	if(y >= 25)
		y = 25;
	*(video_buffer + 2*(x+80*y)) = ch;              // You should write it correct, think carefully
	*(video_buffer + 2*(x+80*y)+1) = attr;          // Previous code : (video_buffer + 2*x + 80*y) (suck)
}

void roll_screen() {
	int i;
	// Copy line A + 1 to line A
	for(i = 1; i < VIDEO_Y_SZ; i++) {
		memcpy(video_buffer + (i - 1) * 80 * 2, video_buffer + i * 80 * 2, VIDEO_X_SZ, 2*sizeof(char));
	}
	// Clear the last line
	for(i = 0; i < VIDEO_X_SZ; i++) {
		video_putchar_at(' ', i, VIDEO_Y_SZ - 1, 0x0F);
	}
}


void video_putstr(char *msg){
	while (*msg != '\n'){
		video_putchar(*msg);
		msg++;
	}
}
/*

##############################################################################

*/

int main(void){

	char* msg = "hello in main!\n";

	register unsigned char a;
	set_trap_gate(0x21, &keyboard_interrupt);
	video_init();
	func_outb(0x21, func_inb(0x21)&0xfd);
	a = func_inb(0x61);
	func_outb(0x61, a | 0x80);
	func_outb(0x61, a);
	video_putstr(msg);
	//InitPalette();	
	while(1) {
		video_putchar_at('#', 1, VIDEO_Y_SZ, 0x0f);
		//keyboard_interrupt();
		if(buffer_read_index > 0){
			video_putstr(buffer);
			buffer_read_index = 0;
			buffer_write_index = 0;
		}	
		sti();
	};
}

#define RELEASE_CHAR(a) ((a) & 0x80)
#define CAPS 0x3A
#define LCTRL 0x1D
#define LALT 0x38
#define LSHIFT 0x2A
#define RCTRL 
#define RALT
#define RSHIFT


// 点代表非可见字符, 或者是"."本身
const char scancode_table[] =       "..1234567890-=\b.qwertyuiop[]\n.asdfghjkl;\'`.\\zxcvbnm,./.*. .............7894561230......";
const char shift_scancode_table[] = "..!@#$%^&*()_+\b.QWERTYUIOP{}\n.ASDFGHJKL:\"~.|ZXCVBNM<>?.*. .............7894561230......";
// const char caps_scancode_table[] =  "..1234567890-=\b.QWERTYUIOP[]\n.ASDFGHJKL;\'`.\\ZXCVBNM,./.*. .............7894561230......";

// This function is not supposed
// to be here but just for convenience
char toupper(char ch) {
	if (ch >= 'a' && ch <= 'z') {
		ch = (char)(ch - 'a' + 'A');
	}
	return ch;
}

void do_keyboard_interrupt(short scancode) {
	// Define some flags
	static char caps = 0;
	static char lshift = 0; 
	static char rshift = 0;
	static char lctrl = 0;
	static char rctrl = 0;
	static char lalt = 0;
	static char ralt = 0;
	static char cap_out = 0;
	char ch = ' ';

	if (RELEASE_CHAR(scancode)) {

		// Check if Shift / Alt / Ctrl / Released
		if (scancode == (LCTRL | 0x80)) {
			lctrl = 0;
		}
		if (scancode == (LALT | 0x80)) {
			lalt = 0;
		}
		if (scancode == (LSHIFT | 0x80)) {
			lshift = 0;
		}
		return ;
	}
	if (!RELEASE_CHAR(scancode)) {
		if (scancode == LCTRL) {
			lctrl = 1;
			return ;
		}
		if (scancode == LALT) {
			lalt = 1;
			return ;
		}
		if (scancode == LSHIFT) {
			lshift = 1;
			return ;
		}
		if (scancode == CAPS) {
			caps = !caps;
			return ;
		}
		cap_out = caps?!(lshift || rshift):(lshift || rshift);
		if (lshift || rshift) {
			ch = shift_scancode_table[scancode];
			if (cap_out) {
				ch = toupper(ch);
			}
		}
		else if (lctrl || rctrl) {
			// here we need ctrl escape
		}
		else if (lalt || ralt) {
			// here we do nothing :/
		}
		else {
			ch = scancode_table[scancode];
			if(cap_out) {
				ch = toupper(ch);
			}
		}
		// TODO: 使得 tty 和进程对应, 当前都是指向 tty_table[0]
		// handle ch
		video_putchar(ch);
		buffer[buffer_write_index] = ch;
		buffer_write_index++;
		if(ch == '\n'){
			buffer_read_index = buffer_write_index;
		} else {
			
		}
		if(buffer_write_index >= 1000){
			buffer_write_index = 0;
		}	
	}
	// Wakeup the buffer queue
	// 我们只有在收到 \n EOF 的时候才唤醒队列
	// wake_up(&tty_table[0].buffer.wait_proc);
	return ;
}

