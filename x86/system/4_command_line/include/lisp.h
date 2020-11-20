
#ifndef _LISP_H

#define _LISP_H

#define SYM_EMPTY 	"EMPTY"
#define SYM_QUOTE 	"QUOTE"
#define SYM_ATOM 	"ATOM"
#define SYM_EQ 		"EQ"
#define SYM_CAR 	"CAR"
#define SYM_CDR 	"CDR"
#define SYM_CONS 	"CONS"
#define SYM_COND 	"COND"

extern int get_cmd(char* str, char* buffer);
extern char* lisp_cmd(char* cmd, int len);


#endif
