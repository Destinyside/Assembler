


extern void show_text();

int cstrlen(char* str){
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

int print(char* str){
	int len = cstrlen(str);
	__asm__(
			"mov	$0x0, %%ax\r\n"
			"mov	%%ax, %%es\r\n"
			"mov     $0x03, %%ah\r\n"
			"xor     %%bh, %%bh\r\n"
			"int     $0x10\r\n"
			"mov     $0x000a, %%bx\r\n"
			"mov     $0x1301, %%ax\r\n"
			"mov     %[MSG_LEN], %%cx\r\n"
			"mov     %[MSG], %%bp\r\n"
			"int     $0x10\r\n"
			:[MSG] "=m" (str),[MSG_LEN] "=m" (len)      //这个是output-list
			:    //这个是input-list
			:"%ax"          //这个是overwriter list
	   );
	return len;

}

int main(void){
	char* msg = "hello in main!\r\n";
	print(msg);

	//print_str(msg);
	for(;;){}

}
