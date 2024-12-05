/**
 * 功能：32位代码，完成多任务的运行
 *
 *创建时间：2022年8月31日
 *作者：李述铜
 *联系邮箱: 527676163@qq.com
 *相关信息：此工程为《从0写x86 Linux操作系统》的前置课程，用于帮助预先建立对32位x86体系结构的理解。整体代码量不到200行（不算注释）
 *课程请见：https://study.163.com/course/introduction.htm?courseId=1212765805&_trace_c_p_k2_=0bdf1e7edda543a8b9a0ad73b5100990
 */
#include "os.h"

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

typedef struct  {
    uint16_t limit_low; // segment limit 16:0
    uint16_t base_low;  // base 16:0
    uint16_t base_attr; // base 23:16 和 attr 
    uint16_t limit_base_attr; // limit 19:16 和 base 31:24
} gdt_entry_t;

#define KERNEL_CODE_SEG_INDEX (KERNEL_CODE_SEG_BYTE/sizeof(gdt_entry_t))  
#define KERNEL_DATA_SEG_INDEX (KERNEL_DATA_SEG_BYTE/sizeof(gdt_entry_t))                                                                           

gdt_entry_t gdt_table[GDT_SIZE] __attribute__((aligned(8))) = {
    [KERNEL_CODE_SEG_INDEX] = {.limit_low = 0xFFFF,.base_low = 0, .base_attr = 0x9a00, .limit_base_attr = 0x00cf},
    [KERNEL_DATA_SEG_INDEX] = {.limit_low = 0xFFFF,.base_low = 0, .base_attr = 0x9200, .limit_base_attr = 0x00cf},
};

