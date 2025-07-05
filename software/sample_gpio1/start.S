 #define STACK_TOP (_end + 1024)

    .section .text.init
    .align 6
    .globl _start
    .globl _bss_end
_start:
    j reset_vector
    .align 2
trap_vector:
#    <<<割込みハンドラの内容>>>
handle_exception:
#    csrw  mie,0     # mieを割り込みディセーブルにセット
#    csrw  mip,0     # mipの割り込み要因をクリア

    addi	sp,sp,-64
    sw	    a0,60(sp)
    sw	    a1,56(sp)
    sw	    a2,52(sp)
    sw	    a3,48(sp)
    sw	    a4,44(sp)
    sw	    a5,40(sp)
    sw	    s0,36(sp)
    sw	    ra,32(sp)

#    csrr    s0,mcause

    call  handler   # handlerへジャンプ

    lw	    a0,60(sp)
    lw	    a1,56(sp)
    lw	    a2,52(sp)
    lw	    a3,48(sp)
    lw	    a4,44(sp)
    lw	    a5,40(sp)
    lw	    s0,36(sp)
    lw	    ra,32(sp)
    addi	sp,sp,64

#    li    t0,0x800  # 割り込みセット
#    csrw  mie,t0 # mieを割り込みイネーブルにセット

#    li    t0,0x800  # 割り込みセット
#    csrw  mie,t0    # mieに割り込みイネーブルをセット

#    li    t0,0x8    # 割り込みセット
#    csrw  mstatus,t0 # mieに割り込みイネーブルをセット

    mret            # MEPCへ飛んでいく
#    <<<割込みハンドラの内容>>>
other_exception:
#    <<<他のハンドラの内容>>>
reset_vector:
#    <<<初期化内容>>>
#    li sp, 4096     # スタックポインタのアドレス
    la sp, STACK_TOP # スタックポインタのアドレス

    auipc t0,0x0    # PCをレジスタに退避
    addi  t0,t0,16  # mretのアドレス
    csrw  mepc,t0   # MEPCにアドレスをセット

    li    t0,0x4    # 0x4をセット
    csrw  mtvec,t0  # MTVECにアドレスをセット

#    li    t0,0x800  # 割り込みセット
#    csrw  mie,t0    # mieに割り込みイネーブルをセット

    li    t0,0x8    # 割り込みセット
    csrw  mstatus,t0 # mieに割り込みイネーブルをセット

    call  main      # mainへジャンプ

    mret            # MEPCへ飛んでいく
