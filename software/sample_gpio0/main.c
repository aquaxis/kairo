/*
  sample_gpio
    GPIOを順番にHighにするサンプル
 */
#include "common.h"
#include <string.h>

#define CAUSE_MACHINE_EXTERNAL          11
#define MEDELEG_INSTRUCTION_PAGE_FAULT  (1 << 12)
#define MEDELEG_LOAD_PAGE_FAULT         (1 << 13)
#define MEDELEG_STORE_PAGE_FAULT        (1 << 15)
#define MEDELEG_USER_ENVIRONNEMENT_CALL (1 << 8)
#define MIDELEG_SUPERVISOR_SOFTWARE     (1 << 1)
#define MIDELEG_SUPERVISOR_TIMER        (1 << 5)
#define MIDELEG_SUPERVISOR_EXTERNAL     (1 << 9)
#define MIP_STIP                        (1 << 5)
#define MIE_MTIE                        (1 << CAUSE_MACHINE_TIMER)
#define MIE_MEIE                        (1 << CAUSE_MACHINE_EXTERNAL)

#define csr_set(csr, val)                    \
({                                \
    unsigned long __v = (unsigned long)(val);        \
    __asm__ __volatile__ ("csrs " #csr ", %0"        \
                  : : "rK" (__v));            \
})

// 割り込みハンドラー
int handler()
{
/*
  unsigned int rslt;

  reg_read(INT_STATUS, rslt);

  while (rslt)
  {
    reg_read(INT_STATUS, rslt);
    reg_write(INT_STATUS, 0xFFFFFFFF); // 割込要因クリア
  }

  // ToDo: 割込処理を記述する

  reg_read(INT_STATUS, rslt);
*/
  return 0;
}

// メインプログラム
int main()
{
  int i;
  unsigned int rslt = 0x1;

  csr_set(mie, MIE_MEIE);

  // 割り込み要因の初期化
  reg_write(INT_STATUS, 0xFFFFFFFF); // 割込要因クリア
  reg_write(INT_MASK, 0xFFFFFFFE);   // 割込イネーブル

  reg_write(GPIO0_DIR, 0xFFFFFFFF);

  // 永久ループ
  while (1)
  {
    reg_write(GPIO0_OUT, rslt); // GPIO書込(LEDにkの下位4bitを表示)
    reg_read(GPIO0_IN, rslt);  // GPIO読込
    rslt <<= 1;
    if(rslt>=0x100) rslt=1;
    for(i=0;i<10;i++);
  };

  return 0;
}
