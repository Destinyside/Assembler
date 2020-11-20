
//#include<sys.h>
//#include<video.h>
#include<stdio.h>
#include<string.h>
//#include<str.h>
#define SYM_EMPTY       "EMPTY"
#define SYM_QUOTE       "QUOTE"
#define SYM_ATOM        "ATOM"
#define SYM_EQ          "EQ"
#define SYM_CAR         "CAR"
#define SYM_CDR         "CDR"
#define SYM_CONS        "CONS"
#define SYM_COND        "COND"

int get_cmd(char* str, char* buffer){
	char ch;
	char *p = str;
	int len = 0;
	int i = 0;
	while(ch != '\n' && ch != EOF) {
		ch = buffer[i++];
		*p++ = ch;
		len++;
	}
	*(p - 1) = '\0';
	return len - 1;     // remove the \n
}
char** get_cmd_list(char* cmd, int len){
	char** cmd_list = {0};
	char** base = cmd_list;
	for(int i=0; i<len;){
		if(cmd[i]=='(' || cmd[i]==')' || cmd[i]==',' || cmd[i]=='\''||
				cmd[i]=='`' || cmd[i]=='@'){
			char* elem = "";
			char* base_elem = elem;
			*elem++ = cmd[i++];
			*elem = '\0';
			*cmd_list++ = base_elem;
		} else if(cmd[i] == ' '){
			while(cmd[i] == ' '){
				i++;
			}
		} else {
			char* elem = "";
			char* base_elem = elem;
			while((cmd[i] <= 'z' && cmd[i] >= 'a' ) || 
					(cmd[i] <= 'Z' && cmd[i] >= 'A' ) ||
					(cmd[i] <= '9' && cmd[i] >= '0' ) ||
					cmd[i] == '_'){
				*elem++ = cmd[i++];
			}
			*elem = '\0';
			*cmd_list++ = base_elem;
		}
	}
	*cmd_list = "EOF";
}

char* lisp_cmd(char* cmd, int len){
	char** cmd_list = get_cmd_list(cmd, len);
	while(strcmp(*cmd_list, "EOF") != -1){
		printf("%s\n", *cmd_list++);
	}
	return "askdhaksdhkhebeye";
}


int main(){
	char* test = "(hello a b c d)";
	printf("%s\n", test);
	lisp_cmd(test, strlen(test));

}

