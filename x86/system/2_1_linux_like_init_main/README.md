



# make && qemu-system-x86_64 -fda Image



- 汇编中会先将数据放到寄存器中，然后进行调用

- MBR读取磁盘加载setup到指定位置

- 从[neu-os]: https://github.com/VOID001/neu-os.git  "neu-os"中“借鉴”了boot加载和vga部分代码

- 通过outb、inb等和显存地址显示字符


