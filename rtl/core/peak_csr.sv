`default_nettype none

module peak_csr (
    input  wire        RST_N,
    input  wire        CLK,
    input  wire [11:0] CSR_ADDR,
    input  wire        CSR_WE,
    input  wire [31:0] CSR_WDATA,
    input  wire [31:0] CSR_WMASK,
    output reg  [31:0] CSR_RDATA,
    input  wire        EXT_INTERRUPT,
    input  wire        SW_INTERRUPT,
    input  wire [31:0] SW_INTERRUPT_PC,
    input  wire        EXCEPTION,
    input  wire [11:0] EXCEPTION_CODE,
    input  wire [31:0] EXCEPTION_ADDR,
    input  wire [31:0] EXCEPTION_PC,
    input  wire        TIMER_EXPIRED,
    input  wire        RETIRE,
    output wire [31:0] HANDLER_PC,
    output wire [31:0] EPC,
    output wire        INTERRUPT_PENDING,
    output wire        INTERRUPT,
    output wire        ILLEGAL_ACCESS,
    input  wire [31:0] DPC,
    input  wire        RESUMEREQ,
    input  wire        EBREAK,
    input  wire        HALTREQ,
    input  wire        AR_EN,
    input  wire        AR_WR,
    input  wire [15:0] AR_AD,
    input  wire [31:0] AR_DI,
    output reg  [31:0] AR_DO
);

  // ----------------------------------------------------------------------
  // Machine mode register
  // ----------------------------------------------------------------------
  // Machine Information Register
  wire [31:0] mvendorid;
  wire [31:0] marchid;
  wire [31:0] mimpid;
  wire [31:0] mhartid;
  // Machine Trap Setup
  wire [31:0] mstatus;
  wire [31:0] misa;
  reg  [31:0] medeleg;
  reg  [31:0] mideleg;
  wire [31:0] mie;
  reg  [31:0] mtvec;
  // Machine Trap Handlling
  reg  [31:0] mscratch;
  reg  [31:0] mepc;
  wire [31:0] mcause;
  reg  [31:0] mbadaddr;
  wire [31:0] mip;
  // Machine Protction and Trnslation
  wire [31:0] mbase;
  wire [31:0] mbound;
  wire [31:0] mibase;
  wire [31:0] mibound;
  wire [31:0] mdbase;
  wire [31:0] mdbound;
  // Machine Counter/Timer
  reg  [63:0] mcycle;
  reg  [63:0] minstret;
  // Debug Mode Register
  reg  [31:0] dcsr;
  wire [31:0] dpc;

  // mvendorid(F11h), marchid(F12h), mimpid(F13h), mhartid(F14h)
  assign mvendorid = 32'd0;
  assign marchid   = 32'd0;
  assign mimpid    = 32'd0;
  assign mhartid   = 32'd0;

  // mstatus(300h)
  reg [1:0] ms_mpp;
  reg       ms_mpie;
  reg       ms_mie;
  always @(posedge CLK) begin
    if (!RST_N) begin
      ms_mpp  <= 0;
      ms_mpie <= 0;
      ms_mie  <= 0;
    end else begin
      if (CSR_WE & (CSR_ADDR == 12'h300)) begin
        if (CSR_WMASK[12]) ms_mpp[1] <= CSR_WDATA[12];  // MPP[1]
        if (CSR_WMASK[11]) ms_mpp[0] <= CSR_WDATA[11];  // MPP[0]
        if (CSR_WMASK[7]) ms_mpie <= CSR_WDATA[7];  // MPIE
        if (CSR_WMASK[3]) ms_mie <= CSR_WDATA[3];  // MIE
      end
    end
  end
  assign mstatus = {19'd0, ms_mpp[1:0], 3'd0, ms_mpie, 3'd0, ms_mie, 3'd0};

  // misa(301h)
  assign misa = {
    2'b01,  // base 32bit
    4'b0000,  // WIRI
    26'b00_0000_0000_0001_0001_0000_0100
  };

  // medeleg(302h), mideleg(303h)
  always @(posedge CLK) begin
    if (!RST_N) begin
      mideleg <= 0;
      medeleg <= 0;
    end else begin
      if (CSR_WE & (CSR_ADDR == 12'h302)) begin
        medeleg <= CSR_WDATA;
      end
      if (CSR_WE & (CSR_ADDR == 12'h303)) begin
        mideleg <= CSR_WDATA;
      end
    end
  end

  // mie(304h)
  reg meie, mtie, msie;
  always @(posedge CLK) begin
    if (!RST_N) begin
      meie <= 0;
      mtie <= 0;
      msie <= 0;
    end else begin
      if (CSR_WE & (CSR_ADDR == 12'h304)) begin
        if (CSR_WMASK[11]) meie <= CSR_WDATA[11];  // MEIE(M-mode Exception Interrupt Enablee)
        if (CSR_WMASK[7]) mtie <= CSR_WDATA[7];  // MTIE(M-mode Timer Interrupt Enable)
        if (CSR_WMASK[3]) msie <= CSR_WDATA[3];  // MSIE(M-mode Software Interrupt Enable)
      end
    end
  end
  assign mie = {20'd0, meie, 3'd0, mtie, 3'd0, msie, 3'd0};

  // mtvec(305h)
  always @(posedge CLK) begin
    if (!RST_N) begin
      mtvec <= 0;
    end else begin
      if (CSR_WE & (CSR_ADDR == 12'h305)) begin
        mtvec <= CSR_WDATA;
      end
    end
  end
  assign HANDLER_PC = mtvec;

  // mscratch(340h)
  always @(posedge CLK) begin
    if (!RST_N) begin
      mscratch <= 0;
    end else begin
      if (CSR_WE & (CSR_ADDR == 12'h340)) begin
        mscratch <= CSR_WDATA;
      end
    end
  end

  // mepc(341h)
  always @(posedge CLK) begin
    if (!RST_N) begin
      mepc <= 0;
    end else begin
      if (SW_INTERRUPT) begin
        mepc <= (SW_INTERRUPT_PC & {{30{1'b1}}, 2'b0});
      end else if (EXCEPTION) begin
        mepc <= (EXCEPTION_PC & {{30{1'b1}}, 2'b0});
      end else if (CSR_WE & (CSR_ADDR == 12'h341)) begin
        mepc <= (CSR_WDATA & {{30{1'b1}}, 2'b0});
      end
    end
  end
  assign EPC = mepc;

  // mcause(342h)
  assign mcause[31] = EXT_INTERRUPT | TIMER_EXPIRED | SW_INTERRUPT;
  assign mcause[30:0] = (EXT_INTERRUPT) ? 11 : (TIMER_EXPIRED) ? 8 : (SW_INTERRUPT) ? 3 : 0;

  // mbadaddr(343h)
  always @(posedge CLK) begin
    if (!RST_N) begin
      mbadaddr <= 0;
    end else begin
      if (EXCEPTION) begin
        mbadaddr <= (|EXCEPTION_CODE[3:0]) ? EXCEPTION_PC : EXCEPTION_ADDR;
      end else if (CSR_WE & (CSR_ADDR == 12'h343)) begin
        mbadaddr <= CSR_WDATA;
      end
    end
  end

  // mip(344h)
  reg msip;
  wire meip, mtip;
  assign meip = EXT_INTERRUPT;
  assign mtip = TIMER_EXPIRED;
  wire w_int;
  assign w_int = mstatus[3] & (|(mie & mip));
  always @(posedge CLK) begin
    if (!RST_N) begin
      msip <= 0;
    end else begin
      // MSIP
      if (SW_INTERRUPT) begin
        msip <= 1'b1;
      end else if (CSR_WE & (CSR_ADDR == 12'h344)) begin
        msip <= CSR_WDATA[3];
      end
    end
  end
  assign mip = {20'd0, meip, 3'd0, mtip, 3'd0, msip, 3'd0};
  assign INTERRUPT = w_int;
  assign INTERRUPT_PENDING = |mip;

  // mbase(380h), mbound(381h), mibase(382h), mibound(383h), mdbase(384h), mdbound(385h)
  assign mbase = 32'd0;
  assign mbound = 32'd0;
  assign mibase = 32'd0;
  assign mibound = 32'd0;
  assign mdbase = 32'd0;
  assign mdbound = 32'd0;

  // mcycle(B00h,B20h)
  always @(posedge CLK) begin
    if (!RST_N) begin
      mcycle <= 0;
    end else begin
      if (CSR_WE & (CSR_ADDR == 12'hB00)) begin
        mcycle[31:0] <= CSR_WDATA;
      end else if (CSR_WE & (CSR_ADDR == 12'hB20)) begin
        mcycle[63:32] <= CSR_WDATA;
      end else begin
        mcycle <= mcycle + 64'd1;
      end
    end
  end

  // minstret(B02h, B22h)
  always @(posedge CLK) begin
    if (!RST_N) begin
      minstret <= 0;
    end else begin
      if (CSR_WE & (CSR_ADDR == 12'hB02)) begin
        minstret[31:0] <= CSR_WDATA;
      end else if (CSR_WE & (CSR_ADDR == 12'hB20)) begin
        minstret[63:32] <= CSR_WDATA;
      end else begin
        if (RETIRE) begin
          minstret <= minstret + 64'd1;
        end
      end
    end
  end

  // Debug Mode Register
  always @(posedge CLK) begin
    if (!RST_N) begin
      dcsr <= 0;
    end else begin
      if (AR_EN & AR_WR & (AR_AD == 16'h07B0)) begin
        dcsr[15] <= AR_DI[15];
        dcsr[13] <= AR_DI[13];
        dcsr[12] <= AR_DI[12];
      end

      if (RESUMEREQ) begin
        dcsr[8:6] <= 3'b0;
      end else if (EBREAK) begin
        dcsr[8:6] <= 3'b1;
      end else if (HALTREQ) begin
        dcsr[8:6] <= 3'd3;
      end
    end
  end
  assign dpc = DPC;

  always @(posedge CLK) begin
    case (CSR_ADDR)
      // Machine Information
      12'hF11: CSR_RDATA = mvendorid;
      12'hF12: CSR_RDATA = marchid;
      12'hF13: CSR_RDATA = mimpid;
      12'hF14: CSR_RDATA = mhartid;
      // Machine Trap Setup
      12'h300: CSR_RDATA = mstatus;
      12'h301: CSR_RDATA = misa;
      12'h302: CSR_RDATA = medeleg;
      12'h303: CSR_RDATA = mideleg;
      12'h304: CSR_RDATA = mie;
      12'h305: CSR_RDATA = mtvec;
      // Machine Trap Handling
      12'h340: CSR_RDATA = mscratch;
      12'h341: CSR_RDATA = mepc;
      12'h342: CSR_RDATA = mcause;
      12'h343: CSR_RDATA = mbadaddr;
      12'h344: CSR_RDATA = mip;
      // Machine Protection and Translation
      12'h380: CSR_RDATA = mbase;
      12'h381: CSR_RDATA = mbound;
      12'h382: CSR_RDATA = mibase;
      12'h383: CSR_RDATA = mibound;
      12'h384: CSR_RDATA = mdbase;
      12'h385: CSR_RDATA = mdbound;
      // Machine Counter/Timer
      12'hB00: CSR_RDATA = mcycle[31:0];
      12'hB02: CSR_RDATA = minstret[31:0];
      12'hB20: CSR_RDATA = mcycle[63:32];
      12'hB22: CSR_RDATA = minstret[63:32];
      // Debug Mode Register
      12'h7B0: CSR_RDATA = dcsr;
      12'h7B1: CSR_RDATA = dpc;
      default: CSR_RDATA = 32'd0;
    endcase
  end

  // Debug
  always @(posedge CLK) begin
    if (AR_AD[15:12] == 4'b0000) begin
      case (AR_AD[11:0])
        // Machine Information
        12'hF11: AR_DO = mvendorid;
        12'hF12: AR_DO = marchid;
        12'hF13: AR_DO = mimpid;
        12'hF14: AR_DO = mhartid;
        // Machine Trap Setup
        12'h300: AR_DO = mstatus;
        12'h301: AR_DO = misa;
        12'h302: AR_DO = medeleg;
        12'h303: AR_DO = mideleg;
        12'h304: AR_DO = mie;
        12'h305: AR_DO = mtvec;
        // Machine Trap Handling
        12'h340: AR_DO = mscratch;
        12'h341: AR_DO = mepc;
        12'h342: AR_DO = mcause;
        12'h343: AR_DO = mbadaddr;
        12'h344: AR_DO = mip;
        // Machine Protection and Translation
        12'h380: AR_DO = mbase;
        12'h381: AR_DO = mbound;
        12'h382: AR_DO = mibase;
        12'h383: AR_DO = mibound;
        12'h384: AR_DO = mdbase;
        12'h385: AR_DO = mdbound;
        // Machine Counter/Timer
        12'hB00: AR_DO = mcycle[31:0];
        12'hB02: AR_DO = minstret[31:0];
        12'hB20: AR_DO = mcycle[63:32];
        12'hB22: AR_DO = minstret[63:32];
        // Debug Mode Register
        12'h7B0: AR_DO = dcsr;
        12'h7B1: AR_DO = dpc;
        default: AR_DO = 32'd0;
      endcase
    end else begin
      AR_DO = 32'd0;
    end
  end

endmodule
`default_nettype wire
