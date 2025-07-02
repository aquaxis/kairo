`default_nettype none

module kairo_soc (
    input  wire        RST_N,
    input  wire        CLK,
    input  wire        INTERRUPT,
    // GPIO
    input  wire [31:0] GPIO0_I,
    output wire [31:0] GPIO0_O,
    output wire [31:0] GPIO0_OE,
    // GPIO
    input  wire [31:0] GPIO1_I,
    output wire [31:0] GPIO1_O,
    output wire [31:0] GPIO1_OE,
    // JTAG
    input  wire        TRST_N,
    input  wire        TCK,
    input  wire        TMS,
    input  wire        TDI,
    output wire        TDO
);
  wire        ext_interrupt;
  wire        ext_expired;
  wire        ext_softint;
  wire        mm_apb_valid;
  wire        mm_apb_ready;
  wire [31:0] mm_apb_addr;
  wire [ 3:0] mm_apb_wstb;
  wire [31:0] mm_apb_wdata;
  wire [31:0] mm_apb_rdata;
  wire        mm_apb_excpt;
  wire        m1_apb_valid;
  wire        m1_apb_ready;
  wire [31:0] m1_apb_addr;
  wire [ 3:0] m1_apb_wstb;
  wire [31:0] m1_apb_wdata;
  wire [31:0] m1_apb_rdata;
  wire        m1_apb_excpt;
  wire        m2_apb_valid;
  wire        m2_apb_ready;
  wire [31:0] m2_apb_addr;
  wire [ 3:0] m2_apb_wstb;
  wire [31:0] m2_apb_wdata;
  wire [31:0] m2_apb_rdata;
  wire        m2_apb_excpt;
  wire        m3_apb_valid;
  wire        m3_apb_ready;
  wire [31:0] m3_apb_addr;
  wire [ 3:0] m3_apb_wstb;
  wire [31:0] m3_apb_wdata;
  wire [31:0] m3_apb_rdata;
  wire        m3_apb_excpt;

  wire [31:0] imem_addr;
  wire [31:0] imem_di;
  wire [31:0] imem_waddr_unused;
  wire [ 3:0] imem_web_unused;
  wire [31:0] imem_wdo;
  wire [31:0] imem_wdi;
  wire [31:0] dmem_addr;
  wire [ 3:0] dmem_web_unused;
  wire [31:0] dmem_do;
  wire [31:0] dmem_di;
  wire        debug_ar_en;
  wire        debug_ar_wr;
  wire [15:0] debug_ar_ad;
  wire [31:0] debug_ar_di;
  wire [31:0] debug_ar_do;
  wire        debug_mem_valid;
  wire        debug_mem_ready;
  wire [ 3:0] debug_mem_wstb;
  wire [31:0] debug_mem_addr;
  wire [31:0] debug_mem_wdata;
  wire [31:0] debug_mem_rdata;
  wire        debug_mem_except;

  /* reset */
  wire        internal_reset_n;
  assign internal_reset_n = RST_N;

  wire [31:0] d_mem_bus_mem_addr;
  wire        d_mem_bus_mem_except;
  wire        d_mem_bus_mem_valid;
  wire [31:0] d_mem_bus_mem_rdata;
  wire        d_mem_bus_mem_ready;
  wire [31:0] d_mem_bus_mem_wdata;
  wire [ 3:0] d_mem_bus_mem_wstb;

  wire [31:0] i_mem_bus_mem_addr;
  wire        i_mem_bus_mem_except;
  wire        i_mem_bus_mem_valid;
  wire [31:0] i_mem_bus_mem_rdata;
  wire        i_mem_bus_mem_ready;
  wire [31:0] i_mem_bus_mem_wdata;
  wire [ 3:0] i_mem_bus_mem_wstb;

  wire [31:0] d_mem_addr;
  wire        d_mem_excpt;
  wire        d_mem_valid;
  wire [31:0] d_mem_rdata;
  wire        d_mem_ready;
  wire [31:0] d_mem_wdata;
  wire [ 3:0] d_mem_wstb;

  wire [31:0] i_mem_addr;
  wire        i_mem_excpt;
  wire        i_mem_valid;
  wire [31:0] i_mem_rdata;
  wire        i_mem_ready;

  wire [31:0] m0_apb_addr;
  wire        m0_apb_excpt;
  wire        m0_apb_valid;
  wire [31:0] m0_apb_rdata;
  wire        m0_apb_ready;
  wire [31:0] m0_apb_wdata;
  wire [ 3:0] m0_apb_wstb;

  wire [31:0] w_d_mem_bus_mem_addr;
  wire        w_d_mem_bus_mem_except;
  wire        w_d_mem_bus_mem_valid;
  wire [31:0] w_d_mem_bus_mem_rdata;
  wire        w_d_mem_bus_mem_ready;
  wire [31:0] w_d_mem_bus_mem_wdata;
  wire [ 3:0] w_d_mem_bus_mem_wstb;

  wire [31:0] w_i_mem_bus_mem_addr;
  wire        w_i_mem_bus_mem_except;
  wire        w_i_mem_bus_mem_valid;
  wire [31:0] w_i_mem_bus_mem_rdata;
  wire        w_i_mem_bus_mem_ready;
  wire [31:0] w_i_mem_bus_mem_wdata;
  wire [ 3:0] w_i_mem_bus_mem_wstb;

  wire        w_ar_en;
  wire        w_ar_wr;
  wire [15:0] w_ar_ad;
  wire [31:0] w_ar_di;
  wire [31:0] w_ar_do;

  wire        w_haltreq;
  wire        w_halt;
  wire        w_resumereq;
  wire        w_resume;
  wire        w_running;

  wire [31:0] imem_raddr;
  wire [31:0] imem_rdata;
  wire [31:0] imem_waddr;
  wire [ 3:0] imem_web;
  wire [31:0] imem_wdata;

  wire [31:0] dmem_waddr;
  wire [31:0] dmem_raddr;
  wire [ 3:0] dmem_web;
  wire [31:0] dmem_wdata;
  wire [31:0] dmem_rdata;

  wire core_haltreq, core_resumereq;
  wire core_halt, core_resume;
  wire core_running;

  wire [31:0] w_int_in;
  assign w_int_in = {31'd0, INTERRUPT};
  wire w_int, w_timer_int;

  wire core_reset, ndmreset;

  wire debug_rst_n;
  assign debug_rst_n = TRST_N & RST_N;

  // CPU Core
  kairo u_kairo (
      .RST_N         (internal_reset_n),
      .CLK           (CLK),
      .D_MEM_ADDR    (w_d_mem_bus_mem_addr),
      .D_MEM_VALID   (w_d_mem_bus_mem_valid),
      .D_MEM_RDATA   (w_d_mem_bus_mem_rdata),
      .D_MEM_READY   (w_d_mem_bus_mem_ready),
      .D_MEM_WDATA   (w_d_mem_bus_mem_wdata),
      .D_MEM_WSTB    (w_d_mem_bus_mem_wstb),
      .D_MEM_EXCPT   (1'b0),
      .I_MEM_ADDR    (w_i_mem_bus_mem_addr),
      .I_MEM_VALID   (w_i_mem_bus_mem_valid),
      .I_MEM_RDATA   (w_i_mem_bus_mem_rdata),
      .I_MEM_READY   (w_i_mem_bus_mem_ready),
      .I_MEM_EXCPT   (1'b0),
      .EXT_INTERRUPT (w_int),
      .TIMER_EXPIRED (w_timer_int),
      .SOFT_INTERRUPT(0),
      .HALTREQ       (core_haltreq),
      .RESUMEREQ     (core_resumereq),
      .HALT          (core_halt),
      .RESUME        (core_resume),
      .RUNNING       (core_running),
      .AR_EN         (debug_ar_en),
      .AR_WR         (debug_ar_wr),
      .AR_AD         (debug_ar_ad),
      .AR_DI         (debug_ar_di),
      .AR_DO         (debug_ar_do)
  );

  wire w_debug_mem_ready_i, w_debug_mem_ready_d, w_debug_mem_ready_io;
  wire [31:0] w_debug_mem_rdata_i, w_debug_mem_rdata_d, w_debug_mem_rdata_io;

  kairo_bussel u_kairo_bussel_i (
      .SELECT  (core_halt),
      // Main Bus
      .M_VALID (w_i_mem_bus_mem_valid),
      .M_READY (w_i_mem_bus_mem_ready),
      .M_WSTB  (4'h0),
      .M_ADDR  (w_i_mem_bus_mem_addr),
      .M_WDATA (32'd0),
      .M_RDATA (w_i_mem_bus_mem_rdata),
      .M_EXCEPT(),
      // Debug Bus
      .D_VALID (debug_mem_valid & (debug_mem_addr[31:28] == 4'h0)),
      .D_READY (w_debug_mem_ready_i),
      .D_WSTB  (debug_mem_wstb),
      .D_ADDR  (debug_mem_addr),
      .D_WDATA (debug_mem_wdata),
      .D_RDATA (w_debug_mem_rdata_i),
      .D_EXCEPT(),
      // Select Bus
      .O_VALID (i_mem_bus_mem_valid),
      .O_READY (i_mem_bus_mem_ready),
      .O_WSTB  (i_mem_bus_mem_wstb),
      .O_ADDR  (i_mem_bus_mem_addr),
      .O_WDATA (i_mem_bus_mem_wdata),
      .O_RDATA (i_mem_bus_mem_rdata),
      .O_EXCEPT()
  );

  kairo_bussel u_kairo_bussel_d (
      .SELECT  (core_halt),
      // Main Bus
      .M_VALID (w_d_mem_bus_mem_valid),
      .M_READY (w_d_mem_bus_mem_ready),
      .M_WSTB  (w_d_mem_bus_mem_wstb),
      .M_ADDR  (w_d_mem_bus_mem_addr),
      .M_WDATA (w_d_mem_bus_mem_wdata),
      .M_RDATA (w_d_mem_bus_mem_rdata),
      .M_EXCEPT(),
      // Debug Bus
      .D_VALID (debug_mem_valid & (debug_mem_addr[31:28] != 4'h0)),
      .D_READY (w_debug_mem_ready_d),
      .D_WSTB  (debug_mem_wstb),
      .D_ADDR  (debug_mem_addr),
      .D_WDATA (debug_mem_wdata),
      .D_RDATA (w_debug_mem_rdata_d),
      .D_EXCEPT(),
      // Select Bus
      .O_VALID (d_mem_bus_mem_valid),
      .O_READY (d_mem_bus_mem_ready),
      .O_WSTB  (d_mem_bus_mem_wstb),
      .O_ADDR  (d_mem_bus_mem_addr),
      .O_WDATA (d_mem_bus_mem_wdata),
      .O_RDATA (d_mem_bus_mem_rdata),
      .O_EXCEPT()
  );

  assign debug_mem_rdata = (w_debug_mem_ready_i)?w_debug_mem_rdata_i:(w_debug_mem_ready_d)?w_debug_mem_rdata_d:32'd0;
  assign debug_mem_ready = w_debug_mem_ready_i | w_debug_mem_ready_d;

  kairo_lct u_kairo_lct (
      .S_APB_ADDR  (d_mem_bus_mem_addr),
      .S_APB_VALID (d_mem_bus_mem_valid),
      .S_APB_RDATA (d_mem_bus_mem_rdata),
      .S_APB_READY (d_mem_bus_mem_ready),
      .S_APB_WDATA (d_mem_bus_mem_wdata),
      .S_APB_WSTB  (d_mem_bus_mem_wstb),
      .MM_APB_ADDR (mm_apb_addr),
      .MM_APB_VALID(mm_apb_valid),
      .MM_APB_RDATA(mm_apb_rdata),
      .MM_APB_READY(mm_apb_ready),
      .MM_APB_WDATA(mm_apb_wdata),
      .MM_APB_WSTB (mm_apb_wstb),
      .M0_APB_ADDR (m0_apb_addr),
      .M0_APB_VALID(m0_apb_valid),
      .M0_APB_RDATA(m0_apb_rdata),
      .M0_APB_READY(m0_apb_ready),
      .M0_APB_WDATA(m0_apb_wdata),
      .M0_APB_WSTB (m0_apb_wstb),
      .M1_APB_ADDR (m1_apb_addr),
      .M1_APB_VALID(m1_apb_valid),
      .M1_APB_RDATA(m1_apb_rdata),
      .M1_APB_READY(m1_apb_ready),
      .M1_APB_WDATA(m1_apb_wdata),
      .M1_APB_WSTB (m1_apb_wstb),
      .M2_APB_ADDR (m2_apb_addr),
      .M2_APB_VALID(m2_apb_valid),
      .M2_APB_RDATA(m2_apb_rdata),
      .M2_APB_READY(m2_apb_ready),
      .M2_APB_WDATA(m2_apb_wdata),
      .M2_APB_WSTB (m2_apb_wstb),
      .M3_APB_ADDR (m3_apb_addr),
      .M3_APB_VALID(m3_apb_valid),
      .M3_APB_RDATA(m3_apb_rdata),
      .M3_APB_READY(m3_apb_ready),
      .M3_APB_WDATA(m3_apb_wdata),
      .M3_APB_WSTB (m3_apb_wstb),
      .M4_APB_RDATA(0),
      .M4_APB_READY(0),
      .M5_APB_RDATA(0),
      .M5_APB_READY(0),
      .M6_APB_RDATA(0),
      .M6_APB_READY(0),
      .M7_APB_RDATA(0),
      .M7_APB_READY(0)
  );

  kairo_mif u_kairo_mif (
      .RST_N      (internal_reset_n),
      .CLK        (CLK),
      .I_MEM_ADDR (i_mem_bus_mem_addr),
      .I_MEM_VALID(i_mem_bus_mem_valid),
      .I_MEM_RDATA(i_mem_bus_mem_rdata),
      .I_MEM_READY(i_mem_bus_mem_ready),
      .I_MEM_WDATA(i_mem_bus_mem_wdata),
      .I_MEM_WSTB (i_mem_bus_mem_wstb),
      .I_MEM_EXCPT(i_mem_excpt),
      .D_MEM_ADDR (mm_apb_addr),
      .D_MEM_EXCPT(mm_apb_excpt),
      .D_MEM_VALID(mm_apb_valid),
      .D_MEM_RDATA(mm_apb_rdata),
      .D_MEM_READY(mm_apb_ready),
      .D_MEM_WDATA(mm_apb_wdata),
      .D_MEM_WSTB (mm_apb_wstb),
      .IMEM_RADR  (imem_raddr),
      .IMEM_RDOUT (imem_rdata),
      .IMEM_WADR  (imem_waddr),
      .IMEM_WEB   (imem_web),
      .IMEM_WDIN  (imem_wdata),
      .DMEM_RADR  (dmem_raddr),
      .DMEM_RDOUT (dmem_rdata),
      .DMEM_WADR  (dmem_waddr),
      .DMEM_WEB   (dmem_web),
      .DMEM_WDIN  (dmem_wdata)
  );

  // Memory
  mem_ram #(
      .AWIDTH  (16),
      .MEM_FILE("/home/hidemi/kairo/software/imem_data.hex")
  ) u_mem_imem (
      .WCK(CLK),
      .WAD(imem_waddr[15:0]),
      .WEB(imem_web),
      .WDI(imem_wdata),
      .RCK(CLK),
      .RAD(imem_raddr[15:0]),
      .RDO(imem_rdata)
  );

  mem_ram #(
      .AWIDTH  (16),
      .MEM_FILE("/home/hidemi/kairo/software/dmem_data.hex")
  ) u_mem_dmem (
      .WCK(CLK),
      .WAD(dmem_waddr[15:0]),
      .WEB(dmem_web),
      .WDI(dmem_wdata),
      .RCK(CLK),
      .RAD(dmem_raddr[15:0]),
      .RDO(dmem_rdata)
  );

  // Base: 0x8000_0000
  apb_plic u_apb_plic (
      .RST_N        (internal_reset_n),
      .CLK          (CLK),
      .S_APB_PSEL   (m0_apb_valid),
      .S_APB_PENABLE(m0_apb_valid),
      .S_APB_PWRITE (|m0_apb_wstb),
      .S_APB_PREADY (m0_apb_ready),
      .S_APB_PADDR  (m0_apb_addr[15:0]),
      .S_APB_PWDATA (m0_apb_wdata),
      .S_APB_PRDATA (m0_apb_rdata),
      .INT_IN       (w_int_in),
      .INTERRUPT    (w_int)
  );

  // Base: 0x8001_0000
  apb_timer u_apb_timer (
      .RST_N        (internal_reset_n),
      .CLK          (CLK),
      .S_APB_PSEL   (m1_apb_valid),
      .S_APB_PENABLE(m1_apb_valid),
      .S_APB_PWRITE (|m1_apb_wstb),
      .S_APB_PREADY (m1_apb_ready),
      .S_APB_PADDR  (m1_apb_addr[15:0]),
      .S_APB_PWDATA (m1_apb_wdata),
      .S_APB_PRDATA (m1_apb_rdata),
      .DONE         (w_timer_int)
  );

  // Base: 0x8002_0000
  apb_gpio u_apb_gpio0 (
      .RST_N        (internal_reset_n),
      .CLK          (CLK),
      .S_APB_PSEL   (m2_apb_valid),
      .S_APB_PENABLE(m2_apb_valid),
      .S_APB_PWRITE (|m2_apb_wstb),
      .S_APB_PREADY (m2_apb_ready),
      .S_APB_PADDR  (m2_apb_addr[15:0]),
      .S_APB_PWDATA (m2_apb_wdata),
      .S_APB_PRDATA (m2_apb_rdata),
      .GPIO_I       (GPIO0_I),
      .GPIO_O       (GPIO0_O),
      .GPIO_OE      (GPIO0_OE)
  );

  // Base: 0x8003_0000
  apb_gpio u_apb_gpio1 (
      .RST_N        (internal_reset_n),
      .CLK          (CLK),
      .S_APB_PSEL   (m3_apb_valid),
      .S_APB_PENABLE(m3_apb_valid),
      .S_APB_PWRITE (|m3_apb_wstb),
      .S_APB_PREADY (m3_apb_ready),
      .S_APB_PADDR  (m3_apb_addr[15:0]),
      .S_APB_PWDATA (m3_apb_wdata),
      .S_APB_PRDATA (m3_apb_rdata),
      .GPIO_I       (GPIO1_I),
      .GPIO_O       (GPIO1_O),
      .GPIO_OE      (GPIO1_OE)
  );

  debug_core u_debug_core (
      .TMS             (TMS),
      .TCK             (TCK),
      .TRST_N          (TRST_N),
      .TDI             (TDI),
      .TDO             (TDO),
      // Debug Module Status
      .I_RESUMEACK     (core_resume),
      .I_RUNNING       (core_running),
      .I_HALTED        (core_halt),
      .O_HALTREQ       (core_haltreq),
      .O_RESUMEREQ     (core_resumereq),
      .O_HARTRESET     (core_reset),
      .O_NDMRESET      (ndmreset),
      .SYS_RST_N       (debug_rst_n),
      .SYS_CLK         (CLK),
      .DEBUG_AR_EN     (debug_ar_en),
      .DEBUG_AR_WR     (debug_ar_wr),
      .DEBUG_AR_AD     (debug_ar_ad),
      .DEBUG_AR_DI     (debug_ar_di),
      .DEBUG_AR_DO     (debug_ar_do),
      .DEBUG_MEM_VALID (debug_mem_valid),
      .DEBUG_MEM_READY (debug_mem_ready),
      .DEBUG_MEM_WSTB  (debug_mem_wstb),
      .DEBUG_MEM_ADDR  (debug_mem_addr),
      .DEBUG_MEM_WDATA (debug_mem_wdata),
      .DEBUG_MEM_RDATA (debug_mem_rdata),
      .DEBUG_MEM_EXCEPT(debug_mem_except)
  );

endmodule

`default_nettype wire
