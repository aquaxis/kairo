`default_nettype none

module peak (
    input  wire        RST_N,
    input  wire        CLK,
    input  wire        I_MEM_READY,
    output wire        I_MEM_VALID,
    output wire [31:0] I_MEM_ADDR,
    input  wire [31:0] I_MEM_RDATA,
    input  wire        I_MEM_EXCPT,
    input  wire        D_MEM_READY,
    output wire        D_MEM_VALID,
    output wire [ 3:0] D_MEM_WSTB,
    output wire [31:0] D_MEM_ADDR,
    output wire [31:0] D_MEM_WDATA,
    input  wire [31:0] D_MEM_RDATA,
    input  wire        D_MEM_EXCPT,
    input  wire        EXT_INTERRUPT,
    input  wire        TIMER_EXPIRED,
    input  wire        SOFT_INTERRUPT,
    input  wire        HALTREQ,
    input  wire        RESUMEREQ,
    output wire        HALT,
    output wire        RESUME,
    output wire        RUNNING,
    input  wire        AR_EN,
    input  wire        AR_WR,
    input  wire [15:0] AR_AD,
    input  wire [31:0] AR_DI,
    output wire [31:0] AR_DO
);

  reg [ 2:0] st0_task_num;
  reg [ 2:0] st1_task_num;
  reg [ 2:0] st2_task_num;
  reg [ 2:0] st3_task_num;
  reg [ 2:0] st4_task_num;
  reg [ 2:0] st5_task_num;
  reg [ 2:0] st6_task_num;
  reg [ 2:0] st7_task_num;

  reg        st0_task_exec;
  reg        st1_task_exec;
  reg        st2_task_exec;
  reg        st3_task_exec;
  reg        st4_task_exec;
  reg        st5_task_exec;
  reg        st6_task_exec;
  reg        st7_task_exec;

  reg [31:0] st0_task_pc;
  reg [31:0] st1_task_pc;
  reg [31:0] st2_task_pc;
  reg [31:0] st3_task_pc;
  reg [31:0] st4_task_pc;
  reg [31:0] st5_task_pc;
  reg [31:0] st6_task_pc;
  reg [31:0] st7_task_pc;

  // ----------------------------------------------------------------------
  //  Stage.Pre
  // ----------------------------------------------------------------------
  assign I_MEM_VALID = 1'b1;
  assign I_MEM_ADDR  = pc;

  wire [31:0] w_inst;
  assign w_inst = (I_MEM_READY) ? I_MEM_RDATA : 32'h0000_0000;

  // ----------------------------------------------------------------------
  //  Stage.1(IF:Instruction Fetch)
  //  Stage.2(DE:Instruction Decode)
  // ----------------------------------------------------------------------

  // Process Number Register
  always @(posedge CLK) begin
    if (!RST_N) begin
      st1_task_num[2:0] <= 3'd0;
      st1_task_exec     <= 1'd0;
      st1_task_pc[31:0] <= 32'd0;
    end else begin
      st1_task_num[2:0] <= st0_task_num[2:0] + 3'd1;
      st1_task_exec     <= I_MEM_READY;
      st1_task_pc[31:0] <= pc[31:0];
    end
  end

  wire [4:0] id_rd_num, id_rs1_num, id_rs2_num;
  wire [31:0] id_rs1, id_rs2, id_imm;

  wire        id_inst_lui, id_inst_auipc,
              id_inst_jal, id_inst_jalr,
              id_inst_fence, id_inst_fencei,
              id_inst_ecall, id_inst_ebreak, id_inst_mret,
              id_inst_csrrw, id_inst_csrrs, id_inst_csrrc,
              id_inst_csrrwi, id_inst_csrrsi, id_inst_csrrci,
              id_inst_mul, id_inst_mulh,
              id_inst_mulhsu, id_inst_mulhu,
              id_inst_div, id_inst_divu,
              id_inst_rem, id_inst_remu,
              id_inst_ill;

  wire        id_inst_imm,
              id_inst_add, id_inst_sub,
              id_inst_shl, id_inst_shr, id_inst_shra,
              id_inst_xor, id_inst_or, id_inst_and,
              id_inst_br, id_inst_lts, id_inst_ltu,
              id_inst_eq, id_inst_br_not;

  peak_rv32im_decode u_peak_rv32im_decode (
      .INST_CODE(w_inst),
      .RS1_NUM  (id_rs1_num),
      .RS2_NUM  (id_rs2_num),
      .RD_NUM   (id_rd_num),
      .IMM      (id_imm),

      .INST_IMM(id_inst_imm),

      .INST_ADD(id_inst_add),
      .INST_SUB(id_inst_sub),
      .INST_SHL(id_inst_shl),
      .INST_SHR(id_inst_shr),
      .INST_SHRA(id_inst_shra),
      .INST_XOR(id_inst_xor),
      .INST_OR(id_inst_or),
      .INST_AND(id_inst_and),
      .INST_BR(id_inst_br),
      .INST_LTS(id_inst_lts),
      .INST_LTU(id_inst_ltu),
      .INST_EQ(id_inst_eq),
      .INST_BR_NOT(id_inst_br_not),

      .INST_LUI  (id_inst_lui),
      .INST_AUIPC(id_inst_auipc),
      .INST_JAL  (id_inst_jal),
      .INST_JALR (id_inst_jalr),

      .INST_FENCE (id_inst_fence),
      .INST_FENCEI(id_inst_fencei),
      .INST_ECALL (id_inst_ecall),
      .INST_EBREAK(id_inst_ebreak),
      .INST_MRET  (id_inst_mret),
      .INST_CSRRW (id_inst_csrrw),
      .INST_CSRRS (id_inst_csrrs),
      .INST_CSRRC (id_inst_csrrc),
      .INST_CSRRWI(id_inst_csrrwi),
      .INST_CSRRSI(id_inst_csrrsi),
      .INST_CSRRCI(id_inst_csrrci),
      .INST_MUL   (id_inst_mul),
      .INST_MULH  (id_inst_mulh),
      .INST_MULHSU(id_inst_mulhsu),
      .INST_MULHU (id_inst_mulhu),
      .INST_DIV   (id_inst_div),
      .INST_DIVU  (id_inst_divu),
      .INST_REM   (id_inst_rem),
      .INST_REMU  (id_inst_remu),
      .INST_ILL   (id_inst_ill)
  );

  // ----------------------------------------------------------------------
  //  Stage.3(RR:Read Register)
  // ----------------------------------------------------------------------
  // Process Number Register
  always @(posedge CLK) begin
    if (!RST_N) begin
      st2_task_num[2:0] <= 3'd0;
      st2_task_exec     <= 1'd0;
      st2_task_pc[31:0] <= 32'd0;
    end else begin
      st2_task_num[2:0] <= st1_task_num[2:0];
      st2_task_exec     <= st1_task_exec;
      st2_task_pc[31:0] <= st1_task_pc[31:0];
    end
  end

  reg [31:0] r_imm;
  reg [4:0] r_id_rs1_num, r_id_rs2_num;
  reg r_inst_imm;
  reg r_inst_add;
  reg r_inst_sub;
  reg r_inst_shl;
  reg r_inst_shr;
  reg r_inst_shra;
  reg r_inst_xor;
  reg r_inst_or;
  reg r_inst_and;
  reg r_inst_br;
  reg r_inst_lts;
  reg r_inst_ltu;
  reg r_inst_eq;
  reg r_inst_br_not;
  always @(posedge CLK) begin
    r_imm <= id_imm;
    r_id_rs1_num <= id_rs1_num;
    r_id_rs2_num <= id_rs2_num;
    r_inst_imm <= id_inst_imm;
    r_inst_add <= id_inst_add;
    r_inst_sub <= id_inst_sub;
    r_inst_shl <= id_inst_shl;
    r_inst_shr <= id_inst_shr;
    r_inst_shra <= id_inst_shra;
    r_inst_xor <= id_inst_xor;
    r_inst_or <= id_inst_or;
    r_inst_and <= id_inst_and;
    r_inst_lts <= id_inst_lts;
    r_inst_ltu <= id_inst_ltu;
    r_inst_br <= id_inst_br;
    r_inst_eq <= id_inst_eq;
    r_inst_br_not <= id_inst_br_not;
  end

  always @(posedge CLK) begin
    if (!RST_N) begin
      st3_task_num[2:0] <= 3'd0;
      st3_task_exec     <= 1'd0;
      st3_task_pc[31:0] <= 32'd0;
    end else begin
      st3_task_num[2:0] <= st2_task_num[2:0];
      st3_task_exec     <= st2_task_exec;
      st3_task_pc[31:0] <= st2_task_pc[31:0];
    end
  end

  // ----------------------------------------------------------------------
  //  Stage.4(EX:Execute)
  // ----------------------------------------------------------------------
  // Process Number Register
  always @(posedge CLK) begin
    if (!RST_N) begin
      st4_task_num[2:0] <= 3'd0;
      st4_task_exec     <= 1'd0;
      st4_task_pc[31:0] <= 32'd0;
    end else begin
      st4_task_num[2:0] <= st3_task_num[2:0];
      st4_task_exec     <= st3_task_exec;
      st4_task_pc[31:0] <= st3_task_pc[31:0];
    end
  end

  wire [31:0] w_inst_rs1, w_inst_rs2;
  wire w_alu_valid;
  wire [31:0] w_alu;

  peak_rv32im_alu u_peak_rv32im_alu (
      .INST_IMM(r_inst_imm),
      .INST_ADD(r_inst_add),
      .INST_SUB(r_inst_sub),
      .INST_SHL(r_inst_shl),
      .INST_SHR(r_inst_shr),
      .INST_SHRA(r_inst_shra),
      .INST_XOR(r_inst_xor),
      .INST_OR(r_inst_or),
      .INST_AND(r_inst_and),
      .INST_LTS(r_inst_lts),
      .INST_LTU(r_inst_ltu),
      .INST_EQ(r_inst_eq),
      .INST_BR_NOT(r_inst_br_not),
      .INST_JAL(r_inst_jal),
      .RS1(w_inst_rs1),
      .RS2(w_inst_rs2),
      .IMM(r_imm),
      .PC(pc),
      .RSLT_VALID(w_alu_valid),
      .RSLT(w_alu),
      .RSLT_A(w_alu_a),
      .RSLT_B(w_alu_b)
  );

  reg r_alu_valid;
  reg [31:0] r_alu;

  always @(posedge CLK) begin
    r_alu_valid <= w_alu_valid;
    r_alu <= w_alu;
  end

  peak_rv32im_mul u_peak_rv32em_mul (
      .RST_N(RST_N),
      .CLK  (CLK),

      .INST_MUL   (id_inst_mul & cpu_exec),
      .INST_MULH  (id_inst_mulh & cpu_exec),
      .INST_MULHSU(id_inst_mulhsu & cpu_exec),
      .INST_MULHU (id_inst_mulhu & cpu_exec),

      .RS1(id_rs1),
      .RS2(id_rs2),

      .WAIT (ex_mul_wait),
      .READY(ex_mul_ready),
      .RD   (ex_mul_rd)
  );

  peak_rv32im_div u_peak_rv32im_div (
      .RST_N(RST_N),
      .CLK  (CLK),

      .INST_DIV (id_inst_div & cpu_exec),
      .INST_DIVU(id_inst_divu & cpu_exec),
      .INST_REM (id_inst_rem & cpu_exec),
      .INST_REMU(id_inst_remu & cpu_exec),

      .RS1(id_rs1),
      .RS2(id_rs2),

      .WAIT (ex_div_wait),
      .READY(ex_div_ready),
      .RD   (ex_div_rd)
  );

  // ----------------------------------------------------------------------
  //  Stage.5(MA:Memory Access)
  // ----------------------------------------------------------------------
  // Process Number Register
  always @(posedge CLK) begin
    if (!RST_N) begin
      st5_task_num[2:0] <= 3'd0;
      st5_task_exec     <= 1'd0;
      st5_task_pc[31:0] <= 32'd0;
    end else begin
      st5_task_num[2:0] <= st4_task_num[2:0];
      st5_task_exec     <= st4_task_exec;
      st5_task_pc[31:0] <= st4_task_pc[31:0];
    end
  end

  // ----------------------------------------------------------------------
  //  Stage.6(MA:Memory Access)
  // ----------------------------------------------------------------------
  // Process Number Register
  always @(posedge CLK) begin
    if (!RST_N) begin
      st6_task_num[2:0] <= 3'd0;
      st6_task_exec     <= 1'd0;
      st6_task_pc[31:0] <= 32'd0;
    end else begin
      st6_task_num[2:0] <= st5_task_num[2:0];
      st6_task_exec     <= st5_task_exec;
      st6_task_pc[31:0] <= st5_task_pc[31:0];
    end
  end

  // ----------------------------------------------------------------------
  //  Stage.7(WB:Write Back)
  // ----------------------------------------------------------------------
  // Process Number Register
  always @(posedge CLK) begin
    if (!RST_N) begin
      st7_task_num[2:0] <= 3'd0;
      st7_task_exec     <= 1'd0;
      st7_task_pc[31:0] <= 32'd0;
    end else begin
      st7_task_num[2:0] <= st6_task_num[2:0];
      st7_task_exec     <= st6_task_exec;
      st7_task_pc[31:0] <= st6_task_pc[31:0];
    end
  end



endmodule

`default_nettype wire
