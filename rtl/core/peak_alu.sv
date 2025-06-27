`default_nettype none

module peak_alu (
    input  wire        INST_IMM,
    input  wire        INST_ADD,
    input  wire        INST_SUB,
    input  wire        INST_SHL,
    input  wire        INST_SHR,
    input  wire        INST_SHRA,
    input  wire        INST_XOR,
    input  wire        INST_OR,
    input  wire        INST_AND,
    input  wire        INST_BR,
    input  wire        INST_LTS,
    input  wire        INST_LTU,
    input  wire        INST_EQ,
    input  wire        INST_BR_NOT,
    input  wire        INST_JAL,
    input  wire [31:0] RS1,
    input  wire [31:0] RS2,
    input  wire [31:0] IMM,
    input  wire [31:0] PC,
    output wire        RSLT_VALID,
    output wire [31:0] RSLT,
    output wire [31:0] RSLT_A,
    output wire        RSLT_B
);

  wire [31:0] reg_op1, reg_op2;
  assign reg_op1 = (INST_BR | INST_JAL) ? PC : RS1;
  assign reg_op2 = (INST_IMM) ? IMM : RS2;

  wire [31:0] alu_add, alu_sub, alu_shl, alu_shr, alu_shra, alu_xor, alu_or, alu_and;
  wire alu_eq, alu_ltu, alu_lts;

  assign alu_add = RS1 + reg_op2;
  assign alu_sub = RS1 - reg_op2;
  assign alu_shl = RS1 << reg_op2[4:0];
  assign alu_shr = $signed({1'b0, RS1}) >>> reg_op2[4:0];
  assign alu_shra = $signed({RS1[31], RS1}) >>> reg_op2[4:0];
  assign alu_xor = RS1 ^ reg_op2;
  assign alu_or = RS1 | reg_op2;
  assign alu_and = RS1 & reg_op2;
  assign alu_eq = (RS1 == reg_op2);
  assign alu_lts = ($signed(RS1) < $signed(reg_op2));
  assign alu_ltu = (RS1 < reg_op2);

  assign RSLT_A = alu_add;
  assign RSLT_B = ((INST_EQ & !INST_BR_NOT)?alu_eq:1'd0) |
                  ((INST_LTS & !INST_BR_NOT)?alu_lts:1'd0) |
                  ((INST_LTU & !INST_BR_NOT)?alu_ltu:1'd0) |
                  ((INST_EQ & INST_BR_NOT)?!alu_eq:1'd0) |
                  ((INST_LTS & INST_BR_NOT)?!alu_lts:1'd0) |
                  ((INST_LTU & INST_BR_NOT)?!alu_ltu:1'd0) |
                  1'd0;

  assign RSLT = ((INST_ADD)?alu_add:32'd0) | 
                ((INST_SUB)?alu_sub:32'd0) |
                ((INST_SHL)?alu_shl:32'd0) |
                ((INST_SHR)?alu_shr:32'd0) |
                ((INST_SHRA)?alu_shra:32'd0) |
                ((INST_XOR)?alu_xor:32'd0) |
                ((INST_OR)?alu_or:32'd0) |
                ((INST_AND)?alu_and:32'd0) |
                ((INST_EQ & !INST_BR_NOT)?{31'd0, alu_eq}:32'd0) |
                ((INST_LTS & !INST_BR_NOT)?{31'd0, alu_lts}:32'd0) |
                ((INST_LTU & !INST_BR_NOT)?{31'd0, alu_ltu}:32'd0) |
                ((INST_EQ & INST_BR_NOT)?{31'd0, !alu_eq}:32'd0) |
                ((INST_LTS & INST_BR_NOT)?{31'd0, !alu_lts}:32'd0) |
                ((INST_LTU & INST_BR_NOT)?{31'd0, !alu_ltu}:32'd0) |
                32'd0;
  assign RSLT_VALID = INST_ADD | INST_SUB | INST_SHL | INST_SHR | INST_SHRA | INST_XOR | INST_OR | INST_AND | INST_EQ | INST_LTS | INST_LTU;

endmodule
`default_nettype wire
