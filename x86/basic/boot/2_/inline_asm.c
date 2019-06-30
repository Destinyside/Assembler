#include<stdio.h>
int call(int x,int y)
{
	int sum = 0;
	asm("movl %[val1],%%ebx\n\t"
			"movl %[val2],%%ecx\n\t"
			"addl %%ebx,%%ecx\n\t"
			"movl %%ecx,%[SUM]"
			:[SUM] "=r" (sum)      //这个是output-list
			:[val1] "r" (x),[val2] "r" (y)    //这个是input-list
			:"%ebx","%ecx"          //这个是overwriter list
	   );
	return sum;
}
int main()
{
	int a=15;
	int b=20;
	printf("%d\n",call(a,b));
	return 0;
}
