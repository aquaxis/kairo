`default_nettype none

module kairo_alu (
    //
    input  wire        RST_N,
    input  wire        CLK,
    //
    input  wire        INST_ADDI,
    input  wire        INST_SLTI,
    input  wire        INST_SLTIU,
    input  wire        INST_XORI,
    input  wire        INST_ORI,
    input  wire        INST_ANDI,
    input  wire        INST_SLLI,
    input  wire        INST_SRLI,
    input  wire        INST_SRAI,
    input  wire        INST_ADD,
    input  wire        INST_SUB,
    input  wire        INST_SLL,
    input  wire        INST_SLT,
    input  wire        INST_SLTU,
    input  wire        INST_XOR,
    input  wire        INST_SRL,
    input  wire        INST_SRA,
    input  wire        INST_OR,
    input  wire        INST_AND,
    //
    input  wire        INST_BEQ,
    input  wire        INST_BNE,
    input  wire        INST_BLT,
    input  wire        INST_BGE,
    input  wire        INST_BLTU,
    input  wire        INST_BGEU,
    //
    input  wire        INST_LB,
    input  wire        INST_LH,
    input  wire        INST_LW,
    input  wire        INST_LBU,
    input  wire        INST_LHU,
    input  wire        INST_SB,
    input  wire        INST_SH,
    input  wire        INST_SW,
    //
    input  wire        INST_AUIPC,
    //
    input  wire        INST_JAL,
    input  wire        INST_JALR,
    //
    input  wire [31:0] RS1,
    input  wire [31:0] RS2,
    input  wire [31:0] IMM,
    input  wire [31:0] PC,
    //
    output reg         RSLT_VALID,
    output reg  [31:0] RSLT,
    output reg  [31:0] RSLT_A,
    output reg         RSLT_B
);

  wire [31:0] reg_op1, reg_op2;
  assign reg_op1 = (INST_BEQ | INST_BNE | INST_BLT | INST_BGE | INST_BLTU | INST_BGEU | INST_JAL | INST_AUIPC) ? PC : RS1;
  assign reg_op2 = (INST_ADDI | INST_SLTI | INST_SLTIU |
                     INST_XORI | INST_ANDI | INST_ORI |
                     INST_SLLI | INST_SRLI | INST_SRAI |
                     INST_LB | INST_LH | INST_LW | INST_LBU | INST_LHU |
                     INST_SB | INST_SH | INST_SW |
                     INST_BEQ | INST_BNE | INST_BLT | INST_BGE | INST_BLTU | INST_BGEU | INST_JAL | INST_JALR |
                     INST_AUIPC
                     )?IMM:RS2;

  wire [31:0] alu_add, alu_sub, alu_shl, alu_shr, alu_shra;
  wire [31:0] alu_xor, alu_or, alu_and;
  wire alu_eq, alu_ltu, alu_lts;

  assign alu_add  = reg_op1 + reg_op2;
  assign alu_sub  = RS1 - reg_op2;
  assign alu_shl  = RS1 << reg_op2[4:0];
  assign alu_shr  = $signed({1'b0, RS1}) >>> reg_op2[4:0];
  assign alu_shra = $signed({RS1[31], RS1}) >>> reg_op2[4:0];
  assign alu_xor  = RS1 ^ reg_op2;
  assign alu_or   = RS1 | reg_op2;
  assign alu_and  = RS1 & reg_op2;
  assign alu_eq   = (RS1 == RS2);
  assign alu_lts  = ($signed(RS1) < $signed(RS2));
  assign alu_ltu  = (RS1 < RS2);

  always @(posedge CLK) begin
    RSLT_A <= alu_add;
    RSLT_B <= ((INST_BEQ)?alu_eq:1'd0) |
                  ((INST_BNE)?!alu_eq:1'd0) |
                  ((INST_BGE)?!alu_lts:1'd0) |
                  ((INST_BGEU)?!alu_ltu:1'd0) |
                  ((INST_BLT)?alu_lts:1'd0) |
                  ((INST_BLTU)?alu_ltu:1'd0) |
                  1'd0;
    RSLT <= ((INST_ADDI | INST_ADD | INST_LB | INST_LH | INST_LW | INST_LBU | INST_LHU | INST_SB | INST_SH | INST_SW)?alu_add:32'd0) | 
                ((INST_SUB)?alu_sub:32'd0) |
                ((INST_SLTI | INST_SLT)?{31'd0, alu_lts}:32'd0) |
                ((INST_SLTIU | INST_SLTU)?{31'd0, alu_ltu}:32'd0) |
                ((INST_SLLI | INST_SLL)?alu_shl:32'd0) |
                ((INST_SRLI | INST_SRL)?alu_shr:32'd0) |
                ((INST_SRAI | INST_SRA)?alu_shra:32'd0) |
                ((INST_XORI | INST_XOR)?alu_xor:32'd0) |
                ((INST_ORI | INST_OR)?alu_or:32'd0) |
                ((INST_ANDI | INST_AND)?alu_and:32'd0) |
                32'd0;
    RSLT_VALID <= INST_ADDI | INST_ADD | INST_SUB |
                      INST_LB | INST_LH | INST_LW | INST_LBU | INST_LHU |
                      INST_SB | INST_SH | INST_SW |
                      INST_SLTI | INST_SLT | INST_SLTIU | INST_SLTU |
                      INST_SLLI | INST_SLL |
                      INST_SRLI | INST_SRAI | INST_SRL | INST_SRA |
                      INST_XORI | INST_XOR |
                      INST_ORI | INST_OR |
                      INST_ANDI | INST_AND;
  end

endmodule
`default_nettype wire
