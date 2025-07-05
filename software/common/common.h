#ifndef _COMMON_H_
#define _COMMON_H_

// INTERRUPT
#define INT_BASE      (0x80000000)

#define INT_STATUS    (INT_BASE+0x0000)
#define INT_MASK      (INT_BASE+0x0004)

// TIMER
#define TIMER_BASE    (0x80010000)
#define TIMER_COUNT   (TIMER_BASE+0x0000)

// GPIO0
#define GPIO0_BASE     (0x80020000)

#define GPIO0_IN       (GPIO0_BASE+0x0)
#define GPIO0_OUT      (GPIO0_BASE+0x4)
#define GPIO0_DIR      (GPIO0_BASE+0x8)

// GPIO1
#define GPIO1_BASE     (0x80030000)

#define GPIO1_IN       (GPIO1_BASE+0x0)
#define GPIO1_OUT      (GPIO1_BASE+0x4)
#define GPIO1_DIR      (GPIO1_BASE+0x8)

// メモリの書き込み
#define mem_write(x, y) \
    *(volatile int *)(x) = y;

// メモリの読み込み
#define mem_read(x, y) \
    y  = *(volatile int *)(x);

// CPUレジスタの書き込み
#define reg_write(x, y) \
    *(volatile int *)(x) = y;

// CPUレジスタの読み込み
#define reg_read(x, y) \
    y  = *(volatile int *)(x);

#endif
