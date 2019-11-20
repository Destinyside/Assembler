
#include<sys.h>
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

int prompt_len = 3;
int old_plen = 0;

void video_init() {
	// struct video_info *info = (struct video_info *)0x9000;

	video_x = prompt_len;
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
		video_x = prompt_len;
		video_y++;
	}
	else if(ch == '\t') {
		while(video_x % TAB_LEN) video_x++;
	}
	else if(ch == '\b') {
		video_x--;
		if (video_x < prompt_len) {
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
		video_x = prompt_len;
		video_y++;
	}
	if(video_y >= VIDEO_Y_SZ) {
		roll_screen();
		video_x = prompt_len;
		video_y = VIDEO_Y_SZ - 1;
	}

	update_cursor(video_y, video_x);
}

void video_clear() {
	int i;
	int j;
	video_x = prompt_len;
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
	for(i = prompt_len; i < VIDEO_X_SZ; i++) {
		video_putchar_at(' ', i, VIDEO_Y_SZ - 1, 0x0F);
	}
}

void video_putstr_def(char *msg, int plen){
	old_plen = prompt_len;
	prompt_len = plen;
	video_x = video_x - old_plen;
	while (*msg != '\n'){
		video_putchar(*msg);
		msg++;
	}
	prompt_len = old_plen;
	video_putchar('\n');
}

void video_putstr(char *msg){
	video_putstr_def(msg, 0);
}

void video_prompt(char* msg) {
	int i=0;
	for(;*msg != '\0';msg++,i++){
		video_putchar_at(*msg, i, video_y, 0x0F);
	}	
}

void video_prompt_def(){
	prompt_len = 3;
	video_prompt(" # ");
}
