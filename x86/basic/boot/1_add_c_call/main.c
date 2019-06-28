

extern void print(const char* pStr);

int putc1(const char* pStr){
    int p=0;
    while(*pStr){
	print(pStr);
	pStr++;
	p++;
    }
    return p;
}

int max(int a, int b){
    if(a>b){
	return a;
    } else {
	return b;
    }
}

int main_init(void){
    const char *msg ="string in c!";
    putc1(msg);
    return 0;
    //puts("aa");
}


