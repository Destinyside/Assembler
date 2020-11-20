
#include<sys.h>
#include<video.h>
#include<keyboard.h>
#include<str.h>
#include<lisp.h>


void cmd();
void init(){
	char* msg = "hello in main!\n";

	register unsigned char a;
	set_trap_gate(0x21, &keyboard_interrupt);
	video_init();
	func_outb(0x21, func_inb(0x21)&0xfd);
	a = func_inb(0x61);
	func_outb(0x61, a | 0x80);
	func_outb(0x61, a);
	video_putstr_def(msg, 3);

}

int main(void){
	init();	
	sti();
	cmd();
}

void cmd(){
	while(1) {
		if(buffer_read_index > 0){
			//buffer command
			char cmd[100] = "";
			int len = get_cmd(cmd, buffer);
			char* result = lisp_cmd(cmd, len);
			video_putstr(cmd);
			int cmp = str_cmp(cmd, "eeee");
			if(cmp > 0){
				video_putstr("hello\n");
			} else {
				video_putstr("other\n");
			}
			video_putstr(result);
			buffer_read_index = 0;
			buffer_write_index = 0;
		} else {
			video_prompt_def();
		}	
	}
}
