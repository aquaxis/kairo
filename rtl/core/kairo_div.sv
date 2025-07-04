`default_nettype none

module kairo_div (
    input  wire        RST_N,
    input  wire        CLK,
    input  wire        INST_DIV,
    input  wire        INST_DIVU,
    input  wire        INST_REM,
    input  wire        INST_REMU,
    input  wire [31:0] RS1,
    input  wire [31:0] RS2,
    output wire        WAIT,
    output wire        READY,
    output wire [31:0] RD
);

  reg [1:0] state;

  localparam S_IDLE = 2'd0;
  localparam S_EXEC = 2'd1;
  localparam S_FIN = 2'd2;

  wire start;

  assign start = INST_DIV | INST_DIVU | INST_REM | INST_REMU;

  reg [31:0] dividend;
  reg [62:0] divisor;
  reg [31:0] quotient, quotient_mask;
  reg outsign;
  reg reg_inst_div, reg_inst_rem;

  always @(posedge CLK) begin
    if (!RST_N) begin
      state <= S_IDLE;
      dividend <= 0;
      divisor <= 0;
      outsign <= 0;
      quotient <= 0;
      quotient_mask <= 0;
      reg_inst_div <= 0;
      reg_inst_rem <= 0;
    end else begin
      case (state)
        S_IDLE: begin
          if (start) begin
            state <= S_EXEC;
            dividend <= ((INST_DIV | INST_REM) & RS1[31]) ? -RS1 : RS1;
            divisor[62:31] <= ((INST_DIV | INST_REM) & RS2[31]) ? -RS2 : RS2;
            divisor[30:0] <= 31'd0;
            outsign <= ((INST_DIV & (RS1[31] ^ RS2[31])) & |RS2) | (INST_REM & RS1[31]);
            quotient <= 32'd0;
            quotient_mask <= 32'h8000_0000;
            reg_inst_div <= INST_DIV | INST_DIVU;
            reg_inst_rem <= INST_REM | INST_REMU;
          end
        end
        S_EXEC: begin
          if (quotient_mask[0]) begin
            state <= S_FIN;
          end
          if (divisor <= dividend) begin
            dividend <= dividend - divisor;
            quotient <= quotient | quotient_mask;
          end
          divisor <= divisor >> 1;
          quotient_mask <= quotient_mask >> 1;
        end
        S_FIN: begin
          state <= S_IDLE;
        end
      endcase
    end
  end

  assign WAIT = (state != S_FIN) & start;
  assign READY = (state == S_FIN);
  assign RD    = (reg_inst_div)?((outsign)?-quotient:quotient):
      ((outsign)?-dividend:dividend);

endmodule  // fmrv32im_div
`default_nettype wire
