
#include<sys.h>
#include<video.h>
#include<keyboard.h>

void handle_keyboard();

int main(void){

	char* msg = "hello in main!\n";

	register unsigned char a;
	set_trap_gate(0x21, &keyboard_interrupt);
	video_init();
	func_outb(0x21, func_inb(0x21)&0xfd);
	a = func_inb(0x61);
	func_outb(0x61, a | 0x80);
	func_outb(0x61, a);
	video_putstr_def(msg, 3);
	//InitPalette();	
	while(1) {
		//keyboard_interrupt();
		if(buffer_read_index > 0){
			handle_keyboard();
		} else {
			video_prompt_def();
		}	
		sti();
	};
}


void handle_keyboard(){
	video_putstr(buffer);
	buffer_read_index = 0;
	buffer_write_index = 0;
}
