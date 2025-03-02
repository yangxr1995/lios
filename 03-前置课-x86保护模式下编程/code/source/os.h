/**
 * 功能：公共头文件
 *
 *创建时间：2022年8月31日
 *作者：李述铜
 *联系邮箱: 527676163@qq.com
 *相关信息：此工程为《从0写x86 Linux操作系统》的前置课程，用于帮助预先建立对32位x86体系结构的理解。整体代码量不到200行（不算注释）
 *课程请见：https://study.163.com/course/introduction.htm?courseId=1212765805&_trace_c_p_k2_=0bdf1e7edda543a8b9a0ad73b5100990
 */
#ifndef OS_H
#define OS_H

#define GDT_SIZE 256   // GDT的大小

#define KERNEL_CODE_SEG_BYTE  0x08  // 内核代码段gpt entry的偏移字节数
#define KERNEL_DATA_SEG_BYTE  0x16  // 内核数据段gpt entry的偏移字节数

#endif // OS_H
