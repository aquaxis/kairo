`default_nettype none

module peak_decode (
    input wire [31:0] INST_CODE,  // instructin code
    output wire [4:0] RD_NUM,  // regsiter number
    output wire [4:0] RS1_NUM,
    output wire [4:0] RS2_NUM,
    output wire [31:0] IMM,  // immidate

    output wire INST_IMM,

    output wire INST_ADD,
    output wire INST_SUB,
    output wire INST_SHL,
    output wire INST_SHR,
    output wire INST_SHRA,
    output wire INST_XOR,
    output wire INST_OR,
    output wire INST_AND,
    output wire INST_BR,
    output wire INST_LTS,
    output wire INST_LTU,
    output wire INST_EQ,
    output wire INST_BR_NOT,

    output wire INST_LUI,
    output wire INST_AUIPC,
    output wire INST_JAL,
    output wire INST_JALR,

    output wire INST_FENCE,
    output wire INST_FENCEI,
    output wire INST_ECALL,
    output wire INST_EBREAK,
    output wire INST_MRET,
    output wire INST_CSRRW,
    output wire INST_CSRRS,
    output wire INST_CSRRC,
    output wire INST_CSRRWI,
    output wire INST_CSRRSI,
    output wire INST_CSRRCI,
    output wire INST_MUL,
    output wire INST_MULH,
    output wire INST_MULHSU,
    output wire INST_MULHU,
    output wire INST_DIV,
    output wire INST_DIVU,
    output wire INST_REM,
    output wire INST_REMU,
    output wire INST_ILL
);

  wire w_inst_lui;
  wire w_inst_auipc;
  wire w_inst_jal;
  wire w_inst_jalr;
  wire w_inst_beq;
  wire w_inst_bne;
  wire w_inst_blt;
  wire w_inst_bge;
  wire w_inst_bltu;
  wire w_inst_bgeu;
  wire w_inst_lb;
  wire w_inst_lh;
  wire w_inst_lw;
  wire w_inst_lbu;
  wire w_inst_lhu;
  wire w_inst_sb;
  wire w_inst_sh;
  wire w_inst_sw;
  wire w_inst_addi;
  wire w_inst_slti;
  wire w_inst_sltiu;
  wire w_inst_xori;
  wire w_inst_ori;
  wire w_inst_andi;
  wire w_inst_slli;
  wire w_inst_srli;
  wire w_inst_srai;
  wire w_inst_add;
  wire w_inst_sub;
  wire w_inst_sll;
  wire w_inst_slt;
  wire w_inst_sltu;
  wire w_inst_xor;
  wire w_inst_srl;
  wire w_inst_sra;
  wire w_inst_or;
  wire w_inst_and;
  wire w_inst_fence;
  wire w_inst_fencei;
  wire w_inst_ecall;
  wire w_inst_ebreak;
  wire w_inst_mret;
  wire w_inst_csrrw;
  wire w_inst_csrrs;
  wire w_inst_csrrc;
  wire w_inst_csrrwi;
  wire w_inst_csrrsi;
  wire w_inst_csrrci;
  wire w_inst_mul;
  wire w_inst_mulh;
  wire w_inst_mulhsu;
  wire w_inst_mulhu;
  wire w_inst_div;
  wire w_inst_divu;
  wire w_inst_rem;
  wire w_inst_remu;
  wire w_inst_ill;

  // タイプ(イミデート)判別
  wire r_type, i_type, s_type, b_type, u_type, j_type;
  wire c0_type;  // custom0
  assign r_type = (INST_CODE[6:5] == 2'b01) && (INST_CODE[4:2] == 3'b100);
  assign i_type   = ((INST_CODE[6:5] == 2'b00) && ((INST_CODE[4:2] == 3'b000) ||
                    (INST_CODE[4:2] == 3'b011) ||
                    (INST_CODE[4:2] == 3'b100))) ||
                    ((INST_CODE[6:5] == 2'b11) && ((INST_CODE[4:2] == 3'b001) ||
                    (INST_CODE[4:2] == 3'b100)));
  assign s_type = (INST_CODE[6:5] == 2'b01) && (INST_CODE[4:2] == 3'b000);
  assign b_type = (INST_CODE[6:5] == 2'b11) && (INST_CODE[4:2] == 3'b000);
  assign u_type   = ((INST_CODE[6:5] == 2'b00) || (INST_CODE[6:5] == 2'b01)) &&
                    (INST_CODE[4:2] == 3'b101);
  assign j_type = (INST_CODE[6:5] == 2'b11) && (INST_CODE[4:2] == 3'b011);
  assign c0_type = (INST_CODE[6:5] == 2'b00) && (INST_CODE[4:2] == 3'b010);

  // イミデート生成
  assign IMM =  (i_type)?{{21{INST_CODE[31]}}, INST_CODE[30:20]}:
                (s_type)?{{21{INST_CODE[31]}}, INST_CODE[30:25], INST_CODE[11:7]}:
                (b_type)?{{20{INST_CODE[31]}}, INST_CODE[7], INST_CODE[30:25], INST_CODE[11:8], 1'b0}:
                (u_type)?{INST_CODE[31:12], 12'b0000_0000_0000}:
                (j_type)?{{12{INST_CODE[31]}}, INST_CODE[19:12], INST_CODE[20], INST_CODE[30:21], 1'b0}:
                32'd0;

  // レジスタ番号生成
  assign RD_NUM = (r_type | i_type | u_type | j_type | c0_type) ? INST_CODE[11:7] : 5'd0;
  assign RS1_NUM = (r_type | i_type | s_type | b_type) ? INST_CODE[19:15] : 5'd0;
  assign RS2_NUM = (r_type | s_type | b_type) ? INST_CODE[24:20] : 5'd0;

  // 各種ファンクション生成
  wire [2:0] func3;
  wire [6:0] func7;
  assign func3 = INST_CODE[14:12];
  assign func7 = INST_CODE[31:25];

  assign w_inst_lui = (INST_CODE[6:0] == 7'b0110111);
  assign w_inst_auipc = (INST_CODE[6:0] == 7'b0010111);
  assign w_inst_jal = (INST_CODE[6:0] == 7'b1101111);
  assign w_inst_jalr = (INST_CODE[6:0] == 7'b1100111);
  assign w_inst_beq = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b000);
  assign w_inst_bne = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b001);
  assign w_inst_blt = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b100);
  assign w_inst_bge = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b101);
  assign w_inst_bltu = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b110);
  assign w_inst_bgeu = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b111);
  assign w_inst_lb = (INST_CODE[6:0] == 7'b0000011) && (func3 == 3'b000);
  assign w_inst_lh = (INST_CODE[6:0] == 7'b0000011) && (func3 == 3'b001);
  assign w_inst_lw = (INST_CODE[6:0] == 7'b0000011) && (func3 == 3'b010);
  assign w_inst_lbu = (INST_CODE[6:0] == 7'b0000011) && (func3 == 3'b100);
  assign w_inst_lhu = (INST_CODE[6:0] == 7'b0000011) && (func3 == 3'b101);
  assign w_inst_sb = (INST_CODE[6:0] == 7'b0100011) && (func3 == 3'b000);
  assign w_inst_sh = (INST_CODE[6:0] == 7'b0100011) && (func3 == 3'b001);
  assign w_inst_sw = (INST_CODE[6:0] == 7'b0100011) && (func3 == 3'b010);
  assign w_inst_addi = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b000);
  assign w_inst_slti = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b010);
  assign w_inst_sltiu = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b011);
  assign w_inst_xori = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b100);
  assign w_inst_ori = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b110);
  assign w_inst_andi = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b111);
  assign w_inst_slli = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b001) && (func7 == 7'b0000000);
  assign w_inst_srli = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b101) && (func7 == 7'b0000000);
  assign w_inst_srai = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b101) && (func7 == 7'b0100000);
  assign w_inst_add = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b000) && (func7 == 7'b0000000);
  assign w_inst_sub = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b000) && (func7 == 7'b0100000);
  assign w_inst_sll = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b001) && (func7 == 7'b0000000);
  assign w_inst_slt = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b010) && (func7 == 7'b0000000);
  assign w_inst_sltu = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b011) && (func7 == 7'b0000000);
  assign w_inst_xor = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b100) && (func7 == 7'b0000000);
  assign w_inst_srl = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b101) && (func7 == 7'b0000000);
  assign w_inst_sra = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b101) && (func7 == 7'b0100000);
  assign w_inst_or = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b110) && (func7 == 7'b0000000);
  assign w_inst_and = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b111) && (func7 == 7'b0000000);
  assign w_inst_fence = (INST_CODE[6:0] == 7'b0001111) && (func3 == 3'b000);
  assign w_inst_fencei = (INST_CODE[6:0] == 7'b0001111) && (func3 == 3'b001);
  assign w_inst_ecall  = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b000) && (INST_CODE[31:20] == 12'b0000_0000_0000);
  assign w_inst_ebreak = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b000) && (INST_CODE[31:20] == 12'b0000_0000_0001);
  assign w_inst_mret   = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b000) && (INST_CODE[31:20] == 12'b0011_0000_0010);
  assign w_inst_csrrw = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b001);
  assign w_inst_csrrs = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b010);
  assign w_inst_csrrc = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b011);
  assign w_inst_csrrwi = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b101);
  assign w_inst_csrrsi = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b110);
  assign w_inst_csrrci = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b111);
  assign w_inst_mul = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b000) && (func7 == 7'b0000001);
  assign w_inst_mulh = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b001) && (func7 == 7'b0000001);
  assign w_inst_mulhsu = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b010) && (func7 == 7'b0000001);
  assign w_inst_mulhu = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b011) && (func7 == 7'b0000001);
  assign w_inst_div = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b100) && (func7 == 7'b0000001);
  assign w_inst_divu = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b101) && (func7 == 7'b0000001);
  assign w_inst_rem = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b110) && (func7 == 7'b0000001);
  assign w_inst_remu = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b111) && (func7 == 7'b0000001);

  assign w_inst_ill = ~(
                     w_inst_lui | w_inst_auipc | w_inst_jal | w_inst_jalr |
                     w_inst_beq | w_inst_bne | w_inst_blt | w_inst_bge |
                     w_inst_bltu | w_inst_bgeu |
                     w_inst_lb | w_inst_lh | w_inst_lw | w_inst_lbu | w_inst_lhu |
                     w_inst_sb | w_inst_sh | w_inst_sw |
                     w_inst_addi | w_inst_slti | w_inst_sltiu |
                     w_inst_xori | w_inst_ori | w_inst_andi |
                     w_inst_slli | w_inst_srli | w_inst_srai |
                     w_inst_add | w_inst_sub |
                     w_inst_sll | w_inst_slt | w_inst_sltu |
                     w_inst_xor | w_inst_srl | w_inst_sra |
                     w_inst_or | w_inst_and |
                     w_inst_fence | w_inst_fencei |
                     w_inst_ecall | w_inst_ebreak |
                     w_inst_mret |
                     w_inst_csrrw | w_inst_csrrs | w_inst_csrrc |
                     w_inst_csrrwi | w_inst_csrrsi | w_inst_csrrci |
                     w_inst_mul | w_inst_mulh | w_inst_mulhsu | w_inst_mulhu |
                     w_inst_div | w_inst_divu | w_inst_rem | w_inst_remu
                     );

  assign INST_IMM = w_inst_addi | w_inst_slti | w_inst_sltiu | w_inst_xori | w_inst_andi | 
                    w_inst_ori | w_inst_slli | w_inst_srli | w_inst_srai | 
                    w_inst_lb | w_inst_lh | w_inst_lw | w_inst_lbu | w_inst_lhu | 
                    w_inst_sb | w_inst_sh | w_inst_sw;
  assign INST_ADD = w_inst_addi | w_inst_add | w_inst_lb | w_inst_lh | w_inst_lw | 
                    w_inst_lbu | w_inst_lhu | w_inst_sb | w_inst_sh | w_inst_sw;
  assign INST_SUB = w_inst_sub;
  assign INST_SHL = w_inst_slli | w_inst_sll;
  assign INST_SHR = w_inst_srli | w_inst_srl;
  assign INST_SHRA = w_inst_srai | w_inst_sra;
  assign INST_XOR = w_inst_xori | w_inst_xor;
  assign INST_OR = w_inst_ori | w_inst_or;
  assign INST_AND = w_inst_andi | w_inst_and;
  assign INST_LTS = w_inst_slti | w_inst_slt | w_inst_bge | w_inst_blt;
  assign INST_LTU = w_inst_sltiu | w_inst_sltu | w_inst_bgeu | w_inst_bltu;
  assign INST_BR = w_inst_beq | w_inst_bne | w_inst_bge | w_inst_bgeu | w_inst_blt | w_inst_bltu;
  assign INST_EQ = w_inst_beq | w_inst_bne;
  assign INST_BR_NOT = w_inst_bne | w_inst_bge | w_inst_bgeu;

  assign INST_LUI = w_inst_lui;
  assign INST_AUIPC = w_inst_auipc;
  assign INST_JAL = w_inst_jal;
  assign INST_JALR = w_inst_jalr;

  assign INST_FENCE = w_inst_fence;
  assign INST_FENCEI = w_inst_fencei;
  assign INST_ECALL = w_inst_ecall;
  assign INST_EBREAK = w_inst_ebreak;
  assign INST_MRET = w_inst_mret;
  assign INST_CSRRW = w_inst_csrrw;
  assign INST_CSRRS = w_inst_csrrs;
  assign INST_CSRRC = w_inst_csrrc;
  assign INST_CSRRWI = w_inst_csrrwi;
  assign INST_CSRRSI = w_inst_csrrsi;
  assign INST_CSRRCI = w_inst_csrrci;
  assign INST_MUL = w_inst_mul;
  assign INST_MULH = w_inst_mulh;
  assign INST_MULHSU = w_inst_mulhsu;
  assign INST_MULHU = w_inst_mulhu;
  assign INST_DIV = w_inst_div;
  assign INST_DIVU = w_inst_divu;
  assign INST_REM = w_inst_rem;
  assign INST_REMU = w_inst_remu;

endmodule
`default_nettype wire
