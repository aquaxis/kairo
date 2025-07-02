`default_nettype none

module kairo_decode (
    // Code
    input wire [31:0] INST_CODE,
    // Register Number
    output wire [4:0] RD_NUM,
    output wire [4:0] RS1_NUM,
    output wire [4:0] RS2_NUM,
    // Immidate
    output wire [31:0] IMM,
    // Instruction
    output wire INST_LUI,
    output wire INST_AUIPC,
    output wire INST_JAL,
    output wire INST_JALR,
    output wire INST_BEQ,
    output wire INST_BNE,
    output wire INST_BLT,
    output wire INST_BGE,
    output wire INST_BLTU,
    output wire INST_BGEU,
    output wire INST_LB,
    output wire INST_LH,
    output wire INST_LW,
    output wire INST_LBU,
    output wire INST_LHU,
    output wire INST_SB,
    output wire INST_SH,
    output wire INST_SW,
    output wire INST_ADDI,
    output wire INST_SLTI,
    output wire INST_SLTIU,
    output wire INST_XORI,
    output wire INST_ORI,
    output wire INST_ANDI,
    output wire INST_SLLI,
    output wire INST_SRLI,
    output wire INST_SRAI,
    output wire INST_ADD,
    output wire INST_SUB,
    output wire INST_SLL,
    output wire INST_SLT,
    output wire INST_SLTU,
    output wire INST_XOR,
    output wire INST_SRL,
    output wire INST_SRA,
    output wire INST_OR,
    output wire INST_AND,
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
    // Illigal Function
    output wire ILL_INST
);

  // Detect Type
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

  // create Immidate
  assign IMM =  (i_type)?{{21{INST_CODE[31]}}, INST_CODE[30:20]}:
                (s_type)?{{21{INST_CODE[31]}}, INST_CODE[30:25], INST_CODE[11:7]}:
                (b_type)?{{20{INST_CODE[31]}}, INST_CODE[7], INST_CODE[30:25], INST_CODE[11:8], 1'b0}:
                (u_type)?{INST_CODE[31:12], 12'b0000_0000_0000}:
                (j_type)?{{12{INST_CODE[31]}}, INST_CODE[19:12], INST_CODE[20], INST_CODE[30:21], 1'b0}:
                32'd0; // Illigal Code

  // create Register Number
  assign RD_NUM = (r_type | i_type | u_type | j_type | c0_type) ? INST_CODE[11:7] : 5'd0;
  assign RS1_NUM = (r_type | i_type | s_type | b_type) ? INST_CODE[19:15] : 5'd0;
  assign RS2_NUM = (r_type | s_type | b_type) ? INST_CODE[24:20] : 5'd0;

  // create Function
  wire [2:0] func3;
  wire [6:0] func7;
  assign func3 = INST_CODE[14:12];
  assign func7 = INST_CODE[31:25];

  assign INST_LUI = (INST_CODE[6:0] == 7'b0110111);
  assign INST_AUIPC = (INST_CODE[6:0] == 7'b0010111);
  assign INST_JAL = (INST_CODE[6:0] == 7'b1101111);
  assign INST_JALR = (INST_CODE[6:0] == 7'b1100111);
  assign INST_BEQ = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b000);
  assign INST_BNE = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b001);
  assign INST_BLT = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b100);
  assign INST_BGE = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b101);
  assign INST_BLTU = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b110);
  assign INST_BGEU = (INST_CODE[6:0] == 7'b1100011) && (func3 == 3'b111);
  assign INST_LB = (INST_CODE[6:0] == 7'b0000011) && (func3 == 3'b000);
  assign INST_LH = (INST_CODE[6:0] == 7'b0000011) && (func3 == 3'b001);
  assign INST_LW = (INST_CODE[6:0] == 7'b0000011) && (func3 == 3'b010);
  assign INST_LBU = (INST_CODE[6:0] == 7'b0000011) && (func3 == 3'b100);
  assign INST_LHU = (INST_CODE[6:0] == 7'b0000011) && (func3 == 3'b101);
  assign INST_SB = (INST_CODE[6:0] == 7'b0100011) && (func3 == 3'b000);
  assign INST_SH = (INST_CODE[6:0] == 7'b0100011) && (func3 == 3'b001);
  assign INST_SW = (INST_CODE[6:0] == 7'b0100011) && (func3 == 3'b010);
  assign INST_ADDI = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b000);
  assign INST_SLTI = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b010);
  assign INST_SLTIU = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b011);
  assign INST_XORI = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b100);
  assign INST_ORI = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b110);
  assign INST_ANDI = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b111);
  assign INST_SLLI = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b001) && (func7 == 7'b0000000);
  assign INST_SRLI = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b101) && (func7 == 7'b0000000);
  assign INST_SRAI = (INST_CODE[6:0] == 7'b0010011) && (func3 == 3'b101) && (func7 == 7'b0100000);
  assign INST_ADD = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b000) && (func7 == 7'b0000000);
  assign INST_SUB = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b000) && (func7 == 7'b0100000);
  assign INST_SLL = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b001) && (func7 == 7'b0000000);
  assign INST_SLT = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b010) && (func7 == 7'b0000000);
  assign INST_SLTU = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b011) && (func7 == 7'b0000000);
  assign INST_XOR = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b100) && (func7 == 7'b0000000);
  assign INST_SRL = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b101) && (func7 == 7'b0000000);
  assign INST_SRA = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b101) && (func7 == 7'b0100000);
  assign INST_OR = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b110) && (func7 == 7'b0000000);
  assign INST_AND = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b111) && (func7 == 7'b0000000);
  assign INST_FENCE = (INST_CODE[6:0] == 7'b0001111) && (func3 == 3'b000);
  assign INST_FENCEI = (INST_CODE[6:0] == 7'b0001111) && (func3 == 3'b001);
  assign INST_ECALL  = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b000) && (INST_CODE[31:20] == 12'b0000_0000_0000);
  assign INST_EBREAK = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b000) && (INST_CODE[31:20] == 12'b0000_0000_0001);
  assign INST_MRET   = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b000) && (INST_CODE[31:20] == 12'b0011_0000_0010);
  assign INST_CSRRW = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b001);
  assign INST_CSRRS = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b010);
  assign INST_CSRRC = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b011);
  assign INST_CSRRWI = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b101);
  assign INST_CSRRSI = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b110);
  assign INST_CSRRCI = (INST_CODE[6:0] == 7'b1110011) && (func3 == 3'b111);
  assign INST_MUL = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b000) && (func7 == 7'b0000001);
  assign INST_MULH = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b001) && (func7 == 7'b0000001);
  assign INST_MULHSU = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b010) && (func7 == 7'b0000001);
  assign INST_MULHU = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b011) && (func7 == 7'b0000001);
  assign INST_DIV = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b100) && (func7 == 7'b0000001);
  assign INST_DIVU = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b101) && (func7 == 7'b0000001);
  assign INST_REM = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b110) && (func7 == 7'b0000001);
  assign INST_REMU = (INST_CODE[6:0] == 7'b0110011) && (func3 == 3'b111) && (func7 == 7'b0000001);

  assign ILL_INST = ~(
                     INST_LUI | INST_AUIPC | INST_JAL | INST_JALR |
                     INST_BEQ | INST_BNE | INST_BLT | INST_BGE |
                     INST_BLTU | INST_BGEU |
                     INST_LB | INST_LH | INST_LW | INST_LBU | INST_LHU |
                     INST_SB | INST_SH | INST_SW |
                     INST_ADDI | INST_SLTI | INST_SLTIU |
                     INST_XORI | INST_ORI | INST_ANDI |
                     INST_SLLI | INST_SRLI | INST_SRAI |
                     INST_ADD | INST_SUB |
                     INST_SLL | INST_SLT | INST_SLTU |
                     INST_XOR | INST_SRL | INST_SRA |
                     INST_OR | INST_AND |
                     INST_FENCE | INST_FENCEI |
                     INST_ECALL | INST_EBREAK |
                     INST_MRET |
                     INST_CSRRW | INST_CSRRS | INST_CSRRC |
                     INST_CSRRWI | INST_CSRRSI | INST_CSRRCI |
                     INST_MUL | INST_MULH | INST_MULHSU | INST_MULHU |
                     INST_DIV | INST_DIVU | INST_REM | INST_REMU
                     );

endmodule

`default_nettype wire
