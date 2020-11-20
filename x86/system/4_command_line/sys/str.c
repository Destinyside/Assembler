
char* str_cpy(char* src, char* dst){
	return "";
}

int str_cmp(char* src, char* dst) {
	int pos = -1;
	while(1){
		//printf("%c %c\n", *src, *dst);
		if(*src++ == *dst++){
			pos++;
		} else {
			return -1;
		}
		
		if(*src == '\0'){
			break;
		}
	}
	return pos;
}

/*
int main(int argc, char* argv[]){
	int cmp = strcmpp("clear", "claer");
	printf("%d\n", cmp);
	cmp = strcmpp("clear", "clear");
	printf("%d\n", cmp);
	cmp = strcmpp("clearccr", "clear");
	printf("%d\n", cmp);

}
*/
