`default_nettype none

module kairo #(
    parameter START_ADDR = 32'h0000_0000
) (
    //System
    input  wire        RST_N,
    input  wire        CLK,
    // Instruction
    input  wire        I_MEM_READY,
    output wire        I_MEM_VALID,
    output wire [31:0] I_MEM_ADDR,
    input  wire [31:0] I_MEM_RDATA,
    input  wire        I_MEM_EXCPT,
    // Memory
    input  wire        D_MEM_READY,
    output wire        D_MEM_VALID,
    output wire [ 3:0] D_MEM_WSTB,
    output wire [31:0] D_MEM_ADDR,
    output wire [31:0] D_MEM_WDATA,
    input  wire [31:0] D_MEM_RDATA,
    input  wire        D_MEM_EXCPT,
    // Interrupt
    input  wire        EXT_INTERRUPT,
    input  wire        SOFT_INTERRUPT,
    input  wire        TIMER_EXPIRED,
    // 
    input  wire        HALTREQ,
    input  wire        RESUMEREQ,
    output wire        HALT,
    output wire        RESUME,
    output wire        RUNNING,
    // Debug
    input  wire        AR_EN,
    input  wire        AR_WR,
    input  wire [15:0] AR_AD,
    input  wire [31:0] AR_DI,
    output wire [31:0] AR_DO
);

  // Program Counter
  reg [31:0] pc;
  reg [31:0] current_pc;

  wire [4:0] id_rd_num, id_rs1_num, id_rs2_num;
  wire [31:0] id_rs1, id_rs2, id_imm;

  wire          id_inst_lui, id_inst_auipc,
                id_inst_jal, id_inst_jalr,
                id_inst_beq, id_inst_bne,
                id_inst_blt, id_inst_bge,
                id_inst_bltu, id_inst_bgeu,
                id_inst_lb, id_inst_lh, id_inst_lw,
                id_inst_lbu, id_inst_lhu,
                id_inst_sb, id_inst_sh, id_inst_sw,
                id_inst_addi, id_inst_slti, id_inst_sltiu,
                id_inst_xori, id_inst_ori, id_inst_andi,
                id_inst_slli, id_inst_srli, id_inst_srai,
                id_inst_add, id_inst_sub,
                id_inst_sll, id_inst_slt, id_inst_sltu,
                id_inst_xor, id_inst_srl, id_inst_sra,
                id_inst_or, id_inst_and,
                id_inst_fence, id_inst_fencei,
                id_inst_ecall, id_inst_ebreak, id_inst_mret,
                id_inst_csrrw, id_inst_csrrs, id_inst_csrrc,
                id_inst_csrrwi, id_inst_csrrsi, id_inst_csrrci,
                id_inst_mul, id_inst_mulh,
                id_inst_mulhsu, id_inst_mulhu,
                id_inst_div, id_inst_divu,
                id_inst_rem, id_inst_remu;

  wire id_ill_inst, id_ill_inst_raw;

  //////////////////////////////////////////////////////////////////////
  // CPU State
  //////////////////////////////////////////////////////////////////////
  reg [1:0] cpu_state;
  localparam S_RESET = 2'd0;
  localparam S_EXEC = 2'd1;
  localparam S_HALT = 2'd2;
  localparam S_RESUME = 2'd3;

  // Boot parameters
  localparam BOOT_ADDR = 32'h00008000;
  localparam BOOT_CYCLES = 1'd1;

  wire ex_wait, ex_cansel;
  wire [31:0] exception_pc;
  reg haltreq_d, resumereq_d;
  reg cpu_exec, cpu_halt, cpu_resume;
  wire ex_halt;

  assign HALT    = cpu_halt;
  assign RESUME  = cpu_resume;
  assign RUNNING = (cpu_state == S_RESET) | cpu_exec;

  // Buffer
  always @(posedge CLK) begin
    if (!RST_N) begin
      haltreq_d   <= 1'b0;
      resumereq_d <= 1'b0;
    end else begin
      haltreq_d   <= HALTREQ;
      resumereq_d <= RESUMEREQ;
    end
  end
  assign ex_halt = cpu_exec & haltreq_d & !ex_wait;

  // CPU state
  always @(posedge CLK) begin
    if (!RST_N) begin
      cpu_state  <= S_RESET;
      cpu_exec   <= 1'b0;
      cpu_halt   <= 1'b0;
      cpu_resume <= 1'b0;
    end else begin
      case (cpu_state)
        S_RESET: begin
          cpu_state  <= S_EXEC;
          cpu_exec   <= 1'b1;
          cpu_halt   <= 1'b0;
          cpu_resume <= 1'b0;
        end
        S_EXEC: begin
          if (ex_halt || id_inst_ebreak) begin
            cpu_state <= S_HALT;
            cpu_halt  <= 1'b1;
            cpu_exec  <= 1'b0;
          end else if (ex_cansel) begin
            cpu_state <= S_RESET;
          end
        end
        S_HALT: begin
          if (RESUMEREQ) begin
            cpu_state  <= S_RESUME;
            cpu_halt   <= 1'b0;
            cpu_resume <= 1'b1;
          end
        end
        S_RESUME: begin
          if (!RESUMEREQ) begin
            cpu_state  <= S_RESET;
            cpu_resume <= 1'b0;
            cpu_exec   <= 1'b1;
          end
        end
        default: cpu_state <= S_RESET;
      endcase
    end
  end

  reg  [ 0:0] bootcnt;
  wire        wb_pc_we;
  wire [31:0] wb_pc;
  reg  [ 0:0] tasknum;

  always @(posedge CLK) begin
    if (!RST_N) begin
      tasknum <= 0;
      pc <= START_ADDR;
      bootcnt <= 0;
    end else begin
      if (bootcnt != 1'b1) bootcnt <= bootcnt + 1;
      tasknum <= tasknum + 1;
      case (bootcnt)
        1'b0: pc <= BOOT_ADDR;
        default: if (wb_pc_we) pc <= wb_pc;
      endcase
    end
  end

  wire [31:0] fetch_data;

  // current PC
  always @(posedge CLK) begin
    if (!RST_N) begin
      current_pc <= START_ADDR;
    end else begin
      if (ex_cansel) begin
        current_pc <= exception_pc;
      end else if (!ex_wait) begin
        current_pc <= pc;
      end
    end
  end

  assign fetch_data  = ((I_MEM_READY) ? I_MEM_RDATA : 32'h0000_0013);  // NOP

  //////////////////////////////////////////////////////////////////////
  // IF:Instruction Fetch
  //////////////////////////////////////////////////////////////////////
  assign I_MEM_VALID = cpu_exec & ~ex_cansel;
  assign I_MEM_ADDR  = (ex_wait) ? current_pc : pc;

  //////////////////////////////////////////////////////////////////////
  // ID:Instruction Decode
  //////////////////////////////////////////////////////////////////////
  kairo_decode u_kairo_decode (
      // インストラクションコード
      .INST_CODE(fetch_data),
      .RS1_NUM  (id_rs1_num),
      .RS2_NUM  (id_rs2_num),

      // レジスタ番号
      .RD_NUM(id_rd_num),

      // イミデート
      .IMM(id_imm),

      // 命令
      .INST_LUI   (id_inst_lui),
      .INST_AUIPC (id_inst_auipc),
      .INST_JAL   (id_inst_jal),
      .INST_JALR  (id_inst_jalr),
      .INST_BEQ   (id_inst_beq),
      .INST_BNE   (id_inst_bne),
      .INST_BLT   (id_inst_blt),
      .INST_BGE   (id_inst_bge),
      .INST_BLTU  (id_inst_bltu),
      .INST_BGEU  (id_inst_bgeu),
      .INST_LB    (id_inst_lb),
      .INST_LH    (id_inst_lh),
      .INST_LW    (id_inst_lw),
      .INST_LBU   (id_inst_lbu),
      .INST_LHU   (id_inst_lhu),
      .INST_SB    (id_inst_sb),
      .INST_SH    (id_inst_sh),
      .INST_SW    (id_inst_sw),
      .INST_ADDI  (id_inst_addi),
      .INST_SLTI  (id_inst_slti),
      .INST_SLTIU (id_inst_sltiu),
      .INST_XORI  (id_inst_xori),
      .INST_ORI   (id_inst_ori),
      .INST_ANDI  (id_inst_andi),
      .INST_SLLI  (id_inst_slli),
      .INST_SRLI  (id_inst_srli),
      .INST_SRAI  (id_inst_srai),
      .INST_ADD   (id_inst_add),
      .INST_SUB   (id_inst_sub),
      .INST_SLL   (id_inst_sll),
      .INST_SLT   (id_inst_slt),
      .INST_SLTU  (id_inst_sltu),
      .INST_XOR   (id_inst_xor),
      .INST_SRL   (id_inst_srl),
      .INST_SRA   (id_inst_sra),
      .INST_OR    (id_inst_or),
      .INST_AND   (id_inst_and),
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

      .ILL_INST(id_ill_inst_raw)
  );

  assign id_ill_inst = id_ill_inst_raw & cpu_exec;

  //////////////////////////////////////////////////////////////////////
  // EX:Excute
  //////////////////////////////////////////////////////////////////////
  wire [31:0] ex_alu_rslt;
  wire [31:0] ex_alu_rslt_a;
  wire        ex_alu_rslt_b;
  wire        is_ex_alu_rslt;
  wire        ex_mul_wait;
  wire        ex_mul_ready;
  wire [31:0] ex_mul_rd;
  wire        ex_div_wait;
  wire        ex_div_ready;
  wire [31:0] ex_div_rd;

  kairo_alu u_kairo_alu (
      .RST_N     (RST_N),
      .CLK       (CLK),
      //
      .INST_ADDI (id_inst_addi),
      .INST_SLTI (id_inst_slti),
      .INST_SLTIU(id_inst_sltiu),
      .INST_XORI (id_inst_xori),
      .INST_ORI  (id_inst_ori),
      .INST_ANDI (id_inst_andi),
      .INST_SLLI (id_inst_slli),
      .INST_SRLI (id_inst_srli),
      .INST_SRAI (id_inst_srai),
      .INST_ADD  (id_inst_add),
      .INST_SUB  (id_inst_sub),
      .INST_SLL  (id_inst_sll),
      .INST_SLT  (id_inst_slt),
      .INST_SLTU (id_inst_sltu),
      .INST_XOR  (id_inst_xor),
      .INST_SRL  (id_inst_srl),
      .INST_SRA  (id_inst_sra),
      .INST_OR   (id_inst_or),
      .INST_AND  (id_inst_and),
      //
      .INST_BEQ  (id_inst_beq),
      .INST_BNE  (id_inst_bne),
      .INST_BLT  (id_inst_blt),
      .INST_BGE  (id_inst_bge),
      .INST_BLTU (id_inst_bltu),
      .INST_BGEU (id_inst_bgeu),
      //
      .INST_LB   (id_inst_lb),
      .INST_LH   (id_inst_lh),
      .INST_LW   (id_inst_lw),
      .INST_LBU  (id_inst_lbu),
      .INST_LHU  (id_inst_lhu),
      .INST_SB   (id_inst_sb),
      .INST_SH   (id_inst_sh),
      .INST_SW   (id_inst_sw),
      //
      .INST_JAL  (id_inst_jal),
      .INST_JALR (id_inst_jalr),
      //
      .INST_AUIPC(id_inst_auipc),
      //
      .RS1       (id_rs1),
      .RS2       (id_rs2),
      .IMM       (id_imm),
      .PC        (current_pc),
      //
      .RSLT_VALID(is_ex_alu_rslt),
      .RSLT      (ex_alu_rslt),
      .RSLT_A    (ex_alu_rslt_a),
      .RSLT_B    (ex_alu_rslt_b)
  );
  /*
  kairo_mul u_kairo_mul (
      // System
      .RST_N      (RST_N),
      .CLK        (CLK),
      //Code
      .INST_MUL   (id_inst_mul & cpu_exec),
      .INST_MULH  (id_inst_mulh & cpu_exec),
      .INST_MULHSU(id_inst_mulhsu & cpu_exec),
      .INST_MULHU (id_inst_mulhu & cpu_exec),
      // Input
      .RS1        (id_rs1),
      .RS2        (id_rs2),
      // Output
      .WAIT       (ex_mul_wait),
      .RD         (ex_mul_rd)
  );

  kairo_div u_kairo_div (
      .RST_N(RST_N),
      .CLK  (CLK),

      .INST_DIV (id_inst_div & cpu_exec),
      .INST_DIVU(id_inst_divu & cpu_exec),
      .INST_REM (id_inst_rem & cpu_exec),
      .INST_REMU(id_inst_remu & cpu_exec),

      .RS1(id_rs1),
      .RS2(id_rs2),

      .WAIT(ex_div_wait),
      .RD  (ex_div_rd)
  );
*/
  assign ex_mul_wait = 0;
  assign ex_div_wait = 0;

  assign ex_wait = ex_mul_wait | ex_div_wait | (D_MEM_VALID & ~D_MEM_READY);

  reg [ 0:0] ex_tasknum;
  reg [31:0] ex_pc_inc;
  reg [11:0] ex_csr_addr;
  reg        ex_csr_we;
  reg [31:0] ex_csr_wdata;
  reg [31:0] ex_csr_wmask;
  reg [31:0] ex_rs2, ex_imm;
  reg [4:0] ex_rd_num;
  reg ex_inst_sb, ex_inst_sh, ex_inst_sw;
  reg ex_inst_lbu, ex_inst_lhu, ex_inst_lb, ex_inst_lh, ex_inst_lw;
  reg ex_inst_lui, is_ex_load, ex_inst_auipc, ex_inst_jal, ex_inst_jalr;
  reg ex_inst_mret;
  reg ex_inst_ecall;
  reg ex_inst_ebreak;
  reg is_ex_csr;
  reg is_ex_mul, is_ex_div;

  always @(posedge CLK) begin
    if (!RST_N) begin
      ex_csr_we <= 1'b0;
      ex_pc_inc <= BOOT_ADDR;
    end else begin
      ex_tasknum <= tasknum;
      ex_pc_inc <= pc + 4;

      ex_csr_addr <= id_imm[11:0];
      ex_csr_we    <= cpu_exec & 
                        ((id_inst_csrrw | id_inst_csrrs | id_inst_csrrc) |
                        ((id_inst_csrrwi | id_inst_csrrsi | id_inst_csrrci) &
                        (id_rs1_num == 5'd0)));
      ex_csr_wdata <= ((id_inst_csrrw)?id_rs1:32'd0) |
                        ((id_inst_csrrs)?id_rs1:32'd0) |
                        ((id_inst_csrrc | id_inst_csrrci)?32'd0:32'd0) |
                        ((id_inst_csrrwi | id_inst_csrrsi)?(32'b1 << id_rs1_num):32'd0) |
                        32'd0;
      ex_csr_wmask <= ((id_inst_csrrw)?32'hffff_ffff:32'd0) |
                        ((id_inst_csrrs | id_inst_csrrc)?id_rs1:32'd0) |
                        ((id_inst_csrrwi | id_inst_csrrsi | id_inst_csrrci)?~(32'b1 << id_rs1_num):32'd0) |
                        32'd0;

      ex_rs2 <= id_rs2;
      ex_imm <= id_imm;
      ex_rd_num <= id_rd_num;
      ex_inst_sb <= id_inst_sb;
      ex_inst_sh <= id_inst_sh;
      ex_inst_sw <= id_inst_sw;
      ex_inst_lbu <= id_inst_lbu;
      ex_inst_lhu <= id_inst_lhu;
      ex_inst_lb <= id_inst_lb;
      ex_inst_lh <= id_inst_lh;
      ex_inst_lw <= id_inst_lw;
      is_ex_load <= id_inst_lb | id_inst_lh | id_inst_lw | id_inst_lbu | id_inst_lhu;
      ex_inst_lui <= id_inst_lui;
      ex_inst_auipc <= id_inst_auipc;
      ex_inst_jal <= id_inst_jal;
      ex_inst_jalr <= id_inst_jalr;
      is_ex_csr <= id_inst_csrrw | id_inst_csrrs | id_inst_csrrc | id_inst_csrrwi | id_inst_csrrsi | id_inst_csrrci;
      ex_inst_mret <= id_inst_mret;
      ex_inst_ecall <= id_inst_ecall;
      ex_inst_ebreak <= id_inst_ebreak;
      is_ex_mul <= id_inst_mul | id_inst_mulh | id_inst_mulhsu | id_inst_mulhu;
      is_ex_div <= id_inst_div | id_inst_divu | id_inst_rem | id_inst_remu;
    end
  end

  //////////////////////////////////////////////////////////////////////
  // MA:Memory Access
  //////////////////////////////////////////////////////////////////////
  // for Store instruction
  assign D_MEM_ADDR = ex_alu_rslt_a;
  assign D_MEM_WDATA = ((ex_inst_sb)?{4{ex_rs2[7:0]}}:32'd0) |
                       ((ex_inst_sh)?{2{ex_rs2[15:0]}}:32'd0) |
                       ((ex_inst_sw)?{ex_rs2}:32'd0) |
                       32'd0;
  assign D_MEM_WSTB[0] = (ex_inst_sb & (ex_alu_rslt_a[1:0] == 2'b00)) |
                          (ex_inst_sh & (ex_alu_rslt_a[1] == 1'b0)) |
                          (ex_inst_sw);
  assign D_MEM_WSTB[1] = (ex_inst_sb & (ex_alu_rslt_a[1:0] == 2'b01)) |
                          (ex_inst_sh & (ex_alu_rslt_a[1] == 1'b0)) |
                          (ex_inst_sw);
  assign D_MEM_WSTB[2] = (ex_inst_sb & (ex_alu_rslt_a[1:0] == 2'b10)) |
                          (ex_inst_sh & (ex_alu_rslt_a[1] == 1'b1)) |
                          (ex_inst_sw);
  assign D_MEM_WSTB[3] = (ex_inst_sb & (ex_alu_rslt_a[1:0] == 2'b11)) |
                          (ex_inst_sh & (ex_alu_rslt_a[1] == 1'b1)) |
                          (ex_inst_sw);
  assign D_MEM_VALID   = cpu_exec &
                            (ex_inst_sb | ex_inst_sh | ex_inst_sw |
                            ex_inst_lbu | ex_inst_lb |
                            ex_inst_lb | ex_inst_lh | ex_inst_lhu | ex_inst_lw);

  wire is_ex_rslt;
  wire [31:0] ex_rslt;

  assign is_ex_rslt = is_ex_alu_rslt | is_ex_mul | is_ex_div;
  assign    ex_rslt = (is_ex_alu_rslt)?ex_alu_rslt:
                      (is_ex_mul)?ex_mul_rd:
                      (is_ex_div)?ex_div_rd:
                      32'd0;

  //////////////////////////////////////////////////////////////////////
  // WB:Write Back
  //////////////////////////////////////////////////////////////////////
  // for Load instruction
  wire [31:0] ex_load;
  assign ex_load[7:0]   = (((ex_inst_lb | ex_inst_lbu) & (ex_alu_rslt_a[1:0] == 2'b00))?D_MEM_RDATA[7:0]:8'd0) |
                          (((ex_inst_lb | ex_inst_lbu) & (ex_alu_rslt_a[1:0] == 2'b01))?D_MEM_RDATA[15:8]:8'd0) |
                          (((ex_inst_lb | ex_inst_lbu) & (ex_alu_rslt_a[1:0] == 2'b10))?D_MEM_RDATA[23:16]:8'd0) |
                          (((ex_inst_lb | ex_inst_lbu) & (ex_alu_rslt_a[1:0] == 2'b11))?D_MEM_RDATA[31:24]:8'd0) |
                          (((ex_inst_lh | ex_inst_lhu) & (ex_alu_rslt_a[1] == 1'b0))?D_MEM_RDATA[7:0]:8'd0) |
                          (((ex_inst_lh | ex_inst_lhu) & (ex_alu_rslt_a[1] == 1'b1))?D_MEM_RDATA[23:16]:8'd0) |
                          ((ex_inst_lw)?D_MEM_RDATA[7:0]:8'd0) |
                          8'd0;
  assign ex_load[15:8]  = ((ex_inst_lb & (ex_alu_rslt_a[1:0] == 2'b00))?{8{D_MEM_RDATA[7]}}:8'd0) |
                          ((ex_inst_lb & (ex_alu_rslt_a[1:0] == 2'b01))?{8{D_MEM_RDATA[15]}}:8'd0) |
                          ((ex_inst_lb & (ex_alu_rslt_a[1:0] == 2'b10))?{8{D_MEM_RDATA[23]}}:8'd0) |
                          ((ex_inst_lb & (ex_alu_rslt_a[1:0] == 2'b11))?{8{D_MEM_RDATA[31]}}:8'd0) |
                          (((ex_inst_lh | ex_inst_lhu) & (ex_alu_rslt_a[1] == 1'b0))?D_MEM_RDATA[15:8]:8'd0) |
                          (((ex_inst_lh | ex_inst_lhu) & (ex_alu_rslt_a[1] == 1'b1))?D_MEM_RDATA[31:24]:8'd0) |
                          ((ex_inst_lw)?D_MEM_RDATA[15:8]:8'd0) |
                          8'd0;
  assign ex_load[31:16] = ((ex_inst_lb & (ex_alu_rslt_a[1:0] == 2'b00))?{16{D_MEM_RDATA[7]}}:16'd0) |
                          ((ex_inst_lb & (ex_alu_rslt_a[1:0] == 2'b01))?{16{D_MEM_RDATA[15]}}:16'd0) |
                          ((ex_inst_lb & (ex_alu_rslt_a[1:0] == 2'b10))?{16{D_MEM_RDATA[23]}}:16'd0) |
                          ((ex_inst_lb & (ex_alu_rslt_a[1:0] == 2'b11))?{16{D_MEM_RDATA[31]}}:16'd0) |
                          ((ex_inst_lh & (ex_alu_rslt_a[1] == 1'b0))?{16{D_MEM_RDATA[15]}}:16'd0) |
                          ((ex_inst_lh & (ex_alu_rslt_a[1] == 1'b1))?{16{D_MEM_RDATA[31]}}:16'd0) |
                          ((ex_inst_lw)?D_MEM_RDATA[31:16]:16'd0) |
                          16'd0;

  wire [ 4:0] wb_rd_num;
  wire        wb_we;
  wire [31:0] wb_rd;
  wire [31:0] ex_csr_rdata;

  assign wb_rd_num = ex_rd_num;
  assign wb_we = (cpu_exec & ~(ex_wait | ex_inst_ebreak));
  assign wb_rd      = ((is_ex_load)?ex_load:32'd0) |
                      ((is_ex_rslt)?ex_rslt:32'd0) |
                      ((ex_inst_lui)?ex_imm:32'd0) |
                      ((ex_inst_auipc)?ex_alu_rslt_a:32'd0) |
                      (((ex_inst_jal | ex_inst_jalr)?pc:32'd0)) |
                      ((is_ex_csr)?ex_csr_rdata:32'd0) |
                      32'd0;

  wire        interrupt;
  wire [31:0] epc;
  wire [31:0] handler_pc;
  wire        exception;
  wire [15:0] exception_code;
  wire [31:0] exception_addr;
  wire        sw_interrupt;
  wire [31:0] sw_interrupt_pc;
  reg         r_ext_int;
  wire        exception_break;

  always @(posedge CLK) begin
    if (!RST_N) begin
      r_ext_int <= 1'b0;
    end else begin
      if (!haltreq_d & !cpu_exec) r_ext_int <= interrupt;
    end
  end

  wire detect_exception, detect_ebreak, detect_branch;
  assign detect_exception = exception | sw_interrupt;
  assign detect_ebreak = ex_inst_ebreak | haltreq_d;
  assign detect_branch = ex_alu_rslt_b | ex_inst_jal | ex_inst_jalr;

  assign exception_break = cpu_exec & ex_inst_ebreak;
  assign exception = cpu_exec & (~r_ext_int & interrupt);
  assign exception_code   =   (D_MEM_EXCPT)?12'd4:
                            | (exception_break)?12'd3:
                            | (id_ill_inst)?12'd2:
                            | (I_MEM_EXCPT)?12'd0:0;
  assign exception_addr = current_pc;
  assign exception_pc     = (detect_exception | interrupt | (cpu_exec & detect_ebreak))?current_pc:
                            (cpu_exec & ex_inst_mret)?epc:
                            (cpu_exec & detect_branch)?ex_alu_rslt_a:
      (~(detect_exception | interrupt | (cpu_exec & (detect_ebreak | ex_inst_mret | detect_branch | ex_inst_jalr))))?current_pc:
                            32'd0;

  assign sw_interrupt = cpu_exec & ex_inst_ecall;
  assign sw_interrupt_pc = current_pc;

  assign wb_pc_we = (cpu_exec & !ex_wait) | (detect_exception);
  assign wb_pc    = (detect_exception)?handler_pc:
                    (cpu_exec & detect_ebreak)?current_pc:
                    (cpu_exec & ex_inst_mret)?epc:
                    (cpu_exec & detect_branch)?ex_alu_rslt_a:
                    (~(detect_exception | (cpu_exec & (detect_ebreak | ex_inst_mret | detect_branch | ex_inst_jalr))))?ex_pc_inc:
                     32'd0;
  assign ex_cansel = (detect_branch | ex_inst_jal | ex_inst_jalr | ex_inst_mret | detect_exception);

  //////////////////////////////////////////////////////////////////////
  // Register
  //////////////////////////////////////////////////////////////////////
  wire [31:0] AR_DO_reg;
  kairo_reg u_kairo_reg (
      // System
      .RST_N   (RST_N),
      .CLK     (CLK),
      // Write Interface
      .WTASKNUM(ex_tasknum),
      .WADDR   (wb_rd_num),
      .WE      (wb_we),
      .WDATA   (wb_rd),
      // Read Interface
      .RTASKNUM(tasknum),
      .RS1ADDR (id_rs1_num),
      .RS1     (id_rs1),
      .RS2ADDR (id_rs2_num),
      .RS2     (id_rs2),
      // Debug
      .AR_EN   (AR_EN & HALT & (AR_AD[15:8] == 8'h10)),
      .AR_WR   (AR_WR),
      .AR_AD   (AR_AD[4:0]),
      .AR_DI   (AR_DI),
      .AR_DO   (AR_DO_reg)
  );

  //////////////////////////////////////////////////////////////////////
  // CSR
  //////////////////////////////////////////////////////////////////////
  wire [31:0] AR_DO_csr;
  kairo_csr u_kairo_csr (
      //
      .RST_N            (RST_N),
      .CLK              (CLK),
      //
      .CSR_ADDR         (ex_csr_addr),
      .CSR_WE           (ex_csr_we),
      .CSR_WDATA        (ex_csr_wdata),
      .CSR_WMASK        (ex_csr_wmask),
      .CSR_RDATA        (ex_csr_rdata),
      //
      .EXT_INTERRUPT    (EXT_INTERRUPT),
      .SW_INTERRUPT     (sw_interrupt | SOFT_INTERRUPT),
      .SW_INTERRUPT_PC  (sw_interrupt_pc),
      .EXCEPTION        (exception),
      .EXCEPTION_CODE   (exception_code[11:0]),
      .EXCEPTION_ADDR   (exception_addr),
      .EXCEPTION_PC     (exception_pc),
      .TIMER_EXPIRED    (TIMER_EXPIRED),
      .RETIRE           (1'b0),
      //
      .HANDLER_PC       (handler_pc),
      .EPC              (epc),
      .INTERRUPT_PENDING(),
      .INTERRUPT        (interrupt),
      //
      .ILLEGAL_ACCESS   (),
      //
      .DPC              (current_pc),
      //
      .RESUMEREQ        (resumereq_d),
      .EBREAK           (ex_inst_ebreak),
      .HALTREQ          (haltreq_d),
      //
      .AR_EN            (AR_EN & HALT),
      .AR_WR            (AR_WR),
      .AR_AD            (AR_AD),
      .AR_DI            (AR_DI),
      .AR_DO            (AR_DO_csr)
  );

  assign AR_DO = AR_DO_reg | AR_DO_csr;

endmodule

`default_nettype wire
