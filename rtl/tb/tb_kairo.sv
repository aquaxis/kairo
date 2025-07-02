`timescale 1ns / 1ps
`default_nettype none

module tb_kairo;

  // Parameters
  parameter START_ADDR = 32'h0000_0000;

  // DUT Signals
  // System
  reg         RST_N;
  reg         CLK;
  // Instruction
  reg         I_MEM_READY;
  wire        I_MEM_VALID;
  wire [31:0] I_MEM_ADDR;
  reg  [31:0] I_MEM_RDATA;
  reg         I_MEM_EXCPT;
  // Memory
  reg         D_MEM_READY;
  wire        D_MEM_VALID;
  wire [3:0]  D_MEM_WSTB;
  wire [31:0] D_MEM_ADDR;
  wire [31:0] D_MEM_WDATA;
  reg  [31:0] D_MEM_RDATA;
  reg         D_MEM_EXCPT;
  // Interrupt
  reg         EXT_INTERRUPT;
  reg         SOFT_INTERRUPT;
  reg         TIMER_EXPIRED;
  // Halt/Resume
  reg         HALTREQ;
  reg         RESUMEREQ;
  wire        HALT;
  wire        RESUME;
  wire        RUNNING;
  // Debug
  reg         AR_EN;
  reg         AR_WR;
  reg  [15:0] AR_AD;
  reg  [31:0] AR_DI;
  wire [31:0] AR_DO;

  // Instantiate the DUT
  kairo #(
      .START_ADDR(START_ADDR)
  ) u_kairo (
      // System
      .RST_N(RST_N),
      .CLK(CLK),
      // Instruction
      .I_MEM_READY(I_MEM_READY),
      .I_MEM_VALID(I_MEM_VALID),
      .I_MEM_ADDR(I_MEM_ADDR),
      .I_MEM_RDATA(I_MEM_RDATA),
      .I_MEM_EXCPT(I_MEM_EXCPT),
      // Memory
      .D_MEM_READY(D_MEM_READY),
      .D_MEM_VALID(D_MEM_VALID),
      .D_MEM_WSTB(D_MEM_WSTB),
      .D_MEM_ADDR(D_MEM_ADDR),
      .D_MEM_WDATA(D_MEM_WDATA),
      .D_MEM_RDATA(D_MEM_RDATA),
      .D_MEM_EXCPT(D_MEM_EXCPT),
      // Interrupt
      .EXT_INTERRUPT(EXT_INTERRUPT),
      .SOFT_INTERRUPT(SOFT_INTERRUPT),
      .TIMER_EXPIRED(TIMER_EXPIRED),
      // Halt/Resume
      .HALTREQ(HALTREQ),
      .RESUMEREQ(RESUMEREQ),
      .HALT(HALT),
      .RESUME(RESUME),
      .RUNNING(RUNNING),
      // Debug
      .AR_EN(AR_EN),
      .AR_WR(AR_WR),
      .AR_AD(AR_AD),
      .AR_DI(AR_DI),
      .AR_DO(AR_DO)
  );

  // Clock generation
  initial begin
    CLK = 0;
    forever #5 CLK = ~CLK;
  end

  // Test sequence
  initial begin
    // Initial values
    RST_N         = 0;
    I_MEM_READY   = 0;
    I_MEM_RDATA   = 32'h00000013; // NOP
    I_MEM_EXCPT   = 0;
    D_MEM_READY   = 0;
    D_MEM_RDATA   = 32'h0;
    D_MEM_EXCPT   = 0;
    EXT_INTERRUPT = 0;
    SOFT_INTERRUPT= 0;
    TIMER_EXPIRED = 0;
    HALTREQ       = 0;
    RESUMEREQ     = 0;
    AR_EN         = 0;
    AR_WR         = 0;
    AR_AD         = 16'h0;
    AR_DI         = 32'h0;

    // Apply reset
    #10;
    RST_N = 1;
    #10;

    // Simple test scenario
    I_MEM_READY = 1;
    #100;

    // Finish simulation
    $finish;
  end

endmodule

`default_nettype wire
