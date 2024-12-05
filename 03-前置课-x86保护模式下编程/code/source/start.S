/**
 * 功能：16位与32位的启动混合代码
 *
 *创建时间：2022年8月31日
 *作者：李述铜
 *联系邮箱: 527676163@qq.com
 *相关信息：此工程为《从0写x86 Linux操作系统》的前置课程，用于帮助预先建立对32位x86体系结构的理解。整体代码量不到200行（不算注释）
 *课程请见：https://study.163.com/course/introduction.htm?courseId=1212765805&_trace_c_p_k2_=0bdf1e7edda543a8b9a0ad73b5100990
 */
	#include "os.h"

	// 声明本地以下符号是全局的，在其它源文件中可以访问
	.global _start

	// 指定以下的代码生成16位的机器指令，这样才能在启动时的实模式下运行
  	.code16

	// 以下是代码区
 	.text
_start: 
    // 确保段寄存器全为0，以简化编程，只使用64K的空间
    mov $0, %ax
    mov %ax, %es
    mov %ax, %ds
    mov %ax, %ss

	// 计算机上电启动后，只取512字节到0x7c00处，即相当于自己只有个头在内存，所以下面全部出来
	// 将自己的其余部分读取到0x7E00处，即0x7c00的后512字节
read_self_all:
	mov $_start_32, %bx	// 读取到的内存地址
	mov $0x2, %cx		// ch:磁道号，cl起始扇区号
	mov $0x0240, %ax	// ah: 0x42读磁盘命令, al=0x40 64个扇区，多读一些, 32KB
	mov $0x80, %dx		// dh: 磁头号，dl驱动器号0x80(磁盘1)
	int $0x0013
	jc read_self_all	// 读取失败，则重复

    cli
    lgdt gdt_desc  // 加载全局描述符表
    mov $1, %ax
    lmsw %ax      // 开启PE(保护模式)

    //------------------- 进入保护模式 -
    // 设置CS位KERNEL_CODE_SEG_BYTE，并进行跳转
    jmp $KERNEL_CODE_SEG_BYTE, $_start_32  

    .org 0x1fe   // 510
    .byte 0x55, 0xaa  // 511 512写为0x55, 0xaa，表示引导扇区结束

    // 保护模式运行32bit代码
    .code32
    .text
_start_32:
    mov $KERNEL_DATA_SEG_BYTE, %eax
    mov %eax, %ds
    mov %eax, %es
    mov %eax, %ss
    mov %eax, %gs
    mov %eax, %fs
    mov $_start, %esp

    jmp .

gdt_desc:
    .word (256*8)-1
    .long gdt_table



