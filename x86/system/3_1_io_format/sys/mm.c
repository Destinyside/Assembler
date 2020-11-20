
#define PAGE_SIZE 4096
long user_stack[PAGE_SIZE >> 2];
struct {
	long *a;
	short b;
} stack_start = {&user_stack[PAGE_SIZE >> 2], 0x10};

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

