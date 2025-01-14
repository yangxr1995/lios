# BIOS和boot

##  从BIOS到boot

主板固化的BIOS程序会完成硬件自检，并加载boot，运行boot

        ┌────┐      ┌────────┐        ┌─────┐       ┌───┐
        │BIOS├─────►│BIOS自检├───────►│boot ├──────►│os │
        └────┘      └────────┘        └─────┘       └───┘

具体启动流程
- BIOS启动boot
  - BIOS检查硬盘是否为启动分区
    - 启动分区的第一个block最后两个字节为0xAA, 0x55
  - BIOS加载启动分区第一个block到内存的0x7c00
  - BIOS跳转到0x7c00开始执行boot
- boot启动os
  - boot加载系统镜像的剩余部分到内存
  - boot继续执行

                      最后两个字节为
                      0xAA, 0x55
                          ▲
                          │
                     ┌────├────────────────────────────────────────┐
        硬盘         │    │           剩余部分                     │
                     └──┬─└─────────────────────────┬──────────────┘
                        │          BIOS加载第一块   │    boot加载剩余部分
                        └───────────────┐           └─────┐
                                        ▼                 ▼
                     ┌────────────────┌────┌─────────────────────────────────┌──────────────────────────┐
        内存         │ 栈空间         │    │         剩余部分                │                          │
                     ├────────────────├────└─────────────────────────────────└──────────────────────────┘
                     ▼                ▼
                     0               0x7c00

### 实践
#### 没有设置0xAA 0x55

 若没有将0xAA 0x55 写入磁盘第一个扇区的结尾，则BIOS不j能找到驱动扇区

```bash
qemu-system-i386 -m 128M -drive file=../../image/disk.img,index=0,media=disk,format=raw
```

![找不到启动块](assets/2024-12-05-11-45-41.jpg)

## 如何加载boot剩余部分
通过终端INT13，调用BIOS提供的函数，读取磁盘内容到内存

# i386 体系结构

## 通用寄存器

        32                 16         8        0
         ┌──────────────────┬─────────┬────────┐
         │                  │  AH     │  AL    │  AX(16bit)  EAX(32bit)
         ├──────────────────┼─────────┼────────┤
         │                  │  BH     │  BL    │  BX(16bit)  EBX(32bit)
         ├──────────────────┼─────────┼────────┤
         │                  │  CH     │  CL    │  CX(16bit)  ECX(32bit)
         ├──────────────────┼─────────┼────────┤
         │                  │  DH     │  DL    │  DX(16bit)  EDX(32bit)
         ├──────────────────┼─────────┴────────┤
         │                  │       BP         │  BP(16bit)  EBP(32bit)
         ├──────────────────┼──────────────────┤
         │                  │       SI         │  SI(16bit)  ESI(32bit)
         ├──────────────────┼──────────────────┤
         │                  │       DI         │  DI(16bit)  EDI(32bit)
         ├──────────────────┼──────────────────┤
         │                  │       SP         │  SP(16bit)  ESP(32bit)
         └──────────────────┴──────────────────┘
         
- AX BX CX DX : 用于计算等通用操作
- BP（基址指针）寄存器：
   - BP寄存器通常用作基址寄存器，在函数调用和堆栈操作中非常有用。
   - 它常用于访问局部变量和函数参数，因为它可以保持一个稳定的基址，即使堆栈指针SP移动了。
   - 在函数开始时，通常会将BP寄存器设置为SP的值，这样就可以通过BP加上偏移量来访问局部变量和参数。
- SI（源索引）寄存器：
   - SI寄存器通常用于字符串操作和内存操作。
   - 它可以用来作为源地址的索引，在数据传输或比较操作中指向源数据。
- DI（目的索引）寄存器：
   - DI寄存器通常用于字符串操作和内存操作。
   - 它可以用来作为目的地址的索引，在数据传输或比较操作中指向目标位置。
- SP（堆栈指针）寄存器：
   - SP寄存器指向当前堆栈的顶部。
   - i386是满减栈，即压栈时sp先减4，再往得到的新地址写入内容
   - 在函数调用时，SP会减少以存储返回地址和局部变量。
   - 当函数返回时，SP会增加以释放局部变量和返回地址。

## 段寄存器         
              ┌──────────┐
              │          │
              ├──────────┤
              │          │ 0x7c0:32
    ┌────────►│ 代码段   │◄───────────────┐
    │         │          │                │
    │  0x7c00 ├──────────┤                │
    │         │          │                │            16                  0       
    │         │          │                │             ┌──────────────────┐       
    │         ├──────────┤                └─────────────┤       CS         │ 代码段
    │         │          │ 0x300:44                     ├──────────────────┤       
    │         │ 数据段   │◄─────────────────────────────┤       DS         │ 数据段
    │         │          │                              ├──────────────────┤       
    │  0x3000 ├──────────┤                ┌─────────────┤       SS         │ 栈段  
    │         │          │                │             ├──────────────────┤       
    │         │          │                │             │       ES         │ 数据段
    │         ├──────────┤                │             ├──────────────────┤       
    │         │  栈      │ 0x100:56       │             │       FS         │ 数据段
    │         │          │◄───────────────┘             ├──────────────────┤       
    │  0x1000 ├──────────┤                              │       GS         │ 数据段
    │         │          │                              └──────────────────┘       
    │         │          │
    │       0 └──────────┘                           
    │                                                
    │                       32                  16              0                                                                                                                                           
    │                        ┌──────────────────┬────────────────┐                                                                                                                                          
    └────────────────────────┤                  │   IP           │ 指令指针寄存器 IP(16bit) EIP(32bit) 
                             └──────────────────┴────────────────┘                                     

             ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
             │     │     │ OF  │     │ IF  │     │     │ PF  │     │ CF  │  程序状态和控制寄存器 EFLAGS
             └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘

因为早期寄存器支持16bit，能访问的地址最大为0xffff，最大空间为64k，
所以设计了段加偏移地址的方式访问内存,
实际访问内存的地址: (段寄存器的值左移 << 4) + 通用寄存器


## 保护模式和实模式

### 实模式

 - 实模式（Real Mode）：
   - 实模式是Intel处理器在早期的x86架构中使用的原始模式。
   - 在实模式下，处理器无法使用保护机制，因此它不能区分不同的内存区域，所有的内存都被视为可访问的。
   - 这种模式下，处理器可以访问所有的I/O端口和硬件资源，因此它提供了对硬件的直接控制。
   - 实模式通常用于早期的操作系统，如MS-DOS，它允许程序直接与硬件通信。
   - 由于没有内存保护，实模式下的程序可能会意外地覆盖其他程序或操作系统自身的代码，导致系统不稳定。
   - 运行在16bit
   - 访问的地址根据IP寄存器+段寄存器<<4 直接访问
 
### 保护模式

 - 保护模式（Protected Mode）：
   - 保护模式是Intel处理器在更高级的操作系统（如Windows和Linux）中使用的模式。
   - 在保护模式下，处理器使用内存保护机制，可以创建多个虚拟内存空间，每个空间都有其自己的权限和地址空间。
   - 这种模式下的操作系统可以更好地管理内存和资源，防止程序之间的干扰。
   - 保护模式还支持多任务处理，允许多个程序同时运行，每个程序都有自己的地址空间和内存保护。
   - 为了进入保护模式，操作系统需要首先加载一个称为内存管理单元（MMU）的硬件组件，它负责管理内存映射和保护。
   - 保护模式提供了更高级的内存管理和安全性，但同时也要求操作系统有更复杂的内存管理机制。
   - 运行在32bit
   - 段寄存器功能改变为GPT的索引
 
#### GPT表项


       31          24 23 22 21 20     16 15    12 11     7            0
       ┌────────────┬──┬──┬──┬──┬──────┬──┬────┬──┬─────┬────────────┐
       │            │  │D │  │A │Seq   │  │ D  │  │     │            │
       │ Base 31:24 │G │/ │L │V │Limit │P │ P  │S │Type │ Base 23:16 │     4字节
       │            │  │B │  │L │19:16 │  │ L  │  │     │            │
       └────────────┴──┴──┴──┴──┴──────┴──┴────┴──┴─────┴────────────┘

       31                            16 15                            0
       ┌───────────────────────────────┬─────────────────────────────┐
       │                               │                             │
       │ Base Address 15:00            │     Segment Limit 15:00     │     0字节
       │                               │                             │
       └───────────────────────────────┴─────────────────────────────┘

整个GPT表项共64bit，由于i386只支持32bit，所以分两部分.

每个域的解释:

- Seq Limit
  - 指定段的大小。处理器将两个段界限字段组合起来形成一个20位的值。
  - 处理器根据G（粒度）标志的设置以两种方式解释段界限：
    - 如果粒度标志未设置，段大小可以从1字节到1兆字节，以字节为增量。
    - 如果粒度标志已设置，段大小可以从4千字节到4千兆字节，以4千字节为增量。

- Base address
  - 定义了段在4千兆字节线性地址空间中的字节0的位置。
  - 处理器将三个基地址字段组合成一个单一的32位值。
  - 段基地址应该对齐到16字节边界。尽管不需要16字节对齐，但这种对齐允许程序通过在16字节边界上对齐代码和数据来最大化性能。

- Type
  - 指示段或门类型，并指定可以对段进行哪些类型的访问以及增长的方向。
  - 此字段的解释取决于描述符类型标志是否指定应用程序（代码或数据）描述符还是系统描述符。

- S
  - 指定段描述符是用于系统段（S标志未设置）还是代码或数据段（S标志已设置）。

- DPL
  - 指定段的特权级别。
  - 特权级别可以从0到3，其中0是最高特权级别。

- P
  - 指示该段是否存在于内存中（设置）或不存在（清除）。
  - 如果此标志被清除，当段选择器指向段描述符被加载到段寄存器时，处理器会产生一个段不存在异常（#NP）。
  - 内存管理软件可以使用此标志来控制哪些段在给定时间内实际被加载到物理内存中。

- D/B
  - 此标志对于32位代码和数据段应始终设置为1，对于16位代码和数据段应设置为0。
  - 根据段描述符是可执行代码段、向下扩展数据段还是堆栈段，执行不同的功能。
    - 可执行代码段。
      - 该标志被称为D标志，它指示指令段中引用的有效地址和操作数的默认长度。
      - 如果标志被设置，则假定使用32位地址和32位或8位操作数；如果标志未设置，则假定使用16位地址和16位或8位操作数。
    - 栈段（由SS寄存器指向的数据段）。
      - 该标志被称为B（大）标志，它指定了用于隐式栈操作（如push、pop和call）的栈指针的大小。
      - 如果标志被设置，则使用32位栈指针，存储在32位ESP寄存器中；
      - 如果标志未设置，则使用16位栈指针，存储在16位SP寄存器中。
      - 如果栈段被设置为扩展向下的数据段（在下一段中描述），B标志还指定了栈段的上界。
    - 扩展向下的数据段。该标志被称为B标志，
      - 它指定了段的上界。如果标志被设置，则上界为FFFFFFFFH（4吉字节）；如果标志未设置，则上界为FFFFH（64千字节）。

- G
  - 确定段界限字段的缩放。
  - 当粒度标志清除时，段界限以字节单位解释；
  - 当标志设置时，段界限以4-K字节单位解释。

- L
  - 在IA-32e模式下，段描述符的第二个双字的第21位指示代码段是否包含原生的64位代码。
  - 该位的值为1表示此代码段中的指令在64位模式下执行。
  - 该位的值为0表示此代码段中的指令在兼容模式下执行。

- reserved bit
  - 段描述符的第二个双字的第20位可用于系统软件使用。

#### 保护模式下如何找到地址 


                                           GPT
    ┌───────────────────┐                ┌────────────┐
    │  CS (代码段) = 8  ├──────┐         │ ....       │
    ├───────────────────┤      │         ├────────────┤
    │  DS (数据段) = 16 ├──────┼──┐      │ Task1 LDT  │
    ├───────────────────┤      │  │      ├────────────┤
    │  SS (栈段)   = 16 ├──────┼──┤      │ Task2 LDT  │
    ├───────────────────┤      │  │      ├────────────┤
    │  ES (数据段) = 16 ├──────┼──┤      │ 系统调用门 │
    └───────────────────┘      │  │      ├────────────┤
                               │  │      │ Task1 TSS  │
                               │  │      ├────────────┤
                               │  │      │ Task2 TSS  │  
                               │  │      ├────────────┤
                               │  │      │ 应用数据段 │
                               │  │      ├────────────┤       
                               │  │      │ 应用程序段 │       
                               │  │      ├────────────┤        ┌────────────────┐                                     
                               │  └─────►│ 内核数据段 │        │根据GPT item    │       ┌─────────┐    ┌────────────┐ 
                               │         ├────────────┤        │获得base, limit,│──────►│ 查询页表│───►│得到物理地址│ 
                               └────────►│ 内核程序段 ├───────►│结合ip寄存器得到│       └─────────┘    └────────────┘ 
                                         ├────────────┤        │虚拟地址        │                                     
                                         │     0      │        └────────────────┘                                     
                                         └────────────┘
                                               ▲
                                               │
                                               │                        
                           ┌───────────────────┴─────────────┬───────────────────┐          
                           │             32bit Base Address  │ 16bit Table limit │          
                           └─────────────────────────────────┴───────────────────┘          
                            47                                15                  0
                                                 GDTR寄存器                                 
                                                                        



