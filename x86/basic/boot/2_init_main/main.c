


#define VIDEO_MEM 0xB8000
#define VIDEO_X_SZ 80
#define VIDEO_Y_SZ 25

char *video_buffer = (char *)VIDEO_MEM;

int strlen(char* str){
	char* p = str;
	int len = 0;
	while(p++){
		if(*p!='\0'){
			len++;
		} else {

			break;
		}
	}
	return len;
}

int main(void){
	char* msg = "hello in main!\r\n";

	//print_str(msg);
	for(;;){}

}
