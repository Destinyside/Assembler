
#define VIDEO_MEM 0xB8000
#define VIDEO_X_SZ 80
#define VIDEO_Y_SZ 25
#define TAB_LEN 8
#define CALC_MEM(x, y) (2*((x) + 80*(y)))

extern int video_x;
extern int video_y;
extern void video_clear();
extern void video_init();
extern void video_putchar(char ch);
extern void video_putchar_at(char ch, int x, int y, char attr);
extern void update_cursor(int row, int col);
extern void roll_screen();
extern void video_putstr(char* buf);
extern void video_putstr_def(char* buf, int plen);
extern void video_prompt_def();
extern void video_prompt(char* msg);
