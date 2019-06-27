

extern void print(const char* pStr);

int main_init(void){
    const char *msg ="string in c!";
    while(*msg)
    {
	print(*msg);
	print(*msg);
	msg++;
    }
    return 0;
    //puts("aa");
}


int max(int a, int b){
    if(a>b){
	return a;
    } else {
	return b;
    }
}
