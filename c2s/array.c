#include<stdio.h>
#include<stdlib.h>
int main(){
	int length = 4;
	int* p = (int*)malloc(sizeof(int)*length);
	for(int i=0;i<length;i++){
		p[i] = i;
	}
	for(int i=0;i<length;i++){
		printf("%d\n",p[i]);
	}
	free(p);
}
	



