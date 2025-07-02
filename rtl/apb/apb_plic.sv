`default_nettype none

module apb_plic (
    input  wire        RST_N,
    input  wire        CLK,
    input  wire        S_APB_PSEL,
    input  wire        S_APB_PENABLE,
    input  wire        S_APB_PWRITE,
    output wire        S_APB_PREADY,
    input  wire [15:0] S_APB_PADDR,
    input  wire [31:0] S_APB_PWDATA,
    output wire [31:0] S_APB_PRDATA,
    output wire        S_APB_PSLVERR,
    input  wire [31:0] INT_IN,
    output wire        INTERRUPT
);

  localparam A_STAT = 16'h0000;
  localparam A_MASK = 16'h0004;
  localparam A_SET = 16'h0008;
  localparam A_SIG = 16'h000C;
  localparam A_FLIP = 16'h001C;

  wire wr_ena, rd_ena, wr_ack, rd_ack;
  reg rd_ena_d;
  reg [31:0] reg_rdata;

  assign wr_ena = (S_APB_PSEL & S_APB_PENABLE & S_APB_PWRITE) ? 1'b1 : 1'b0;
  assign rd_ena = (S_APB_PSEL & S_APB_PENABLE & ~S_APB_PWRITE) ? 1'b1 : 1'b0;
  assign wr_ack = wr_ena;
  assign rd_ack = rd_ena_d & rd_ena;

  // Register
  reg [31:0] reg_int, reg_mask, reg_flip;

  always @(posedge CLK) begin
    if (!RST_N) begin
      reg_mask <= 0;
      reg_flip <= 0;
    end else begin
      if (wr_ena) begin
        case (S_APB_PADDR[15:0] & 16'hFFFC)
          A_MASK: reg_mask <= S_APB_PWDATA;
          A_FLIP: reg_flip <= S_APB_PWDATA;
          default: begin
          end
        endcase
      end
    end
  end

  generate
    for (genvar i = 0; i < 32; i = i + 1) begin
      always @(posedge CLK) begin
        if (!RST_N) begin
          reg_int[i] <= 0;
        end else begin
          if (INT_IN[i] ^ reg_flip[i]) begin
            reg_int[i] <= 1'b1;
          end else if(wr_ena && ((S_APB_PADDR[15:0] & 16'hFFFC) == A_STAT) && S_APB_PWDATA[i]) begin
            reg_int[i] <= 1'b0;
          end else if (wr_ena && ((S_APB_PADDR[15:0] & 16'hFFFC) == A_SET)) begin
            reg_int[i] <= S_APB_PWDATA[i];
          end
        end
      end
    end
  endgenerate

  always @(posedge CLK) begin
    if (!RST_N) begin
      rd_ena_d        <= 1'b0;
      reg_rdata[31:0] <= 32'd0;
    end else begin
      rd_ena_d <= rd_ena & ~rd_ack;
      case (S_APB_PADDR[15:0] & 16'hFFFC)
        A_STAT:  reg_rdata[31:0] <= reg_int;
        A_MASK:  reg_rdata[31:0] <= reg_mask;
        A_SIG:   reg_rdata[31:0] <= INT_IN;
        A_FLIP:  reg_rdata[31:0] <= reg_flip;
        default: reg_rdata[31:0] <= 32'd0;
      endcase
    end
  end

  assign S_APB_PREADY       = (wr_ack | rd_ack);
  assign S_APB_PRDATA[31:0] = (rd_ack) ? reg_rdata[31:0] : 32'd0;
  assign S_APB_PSLVERR      = 1'b0;

  // INTERRUPT
  assign INTERRUPT          = ((reg_int & reg_mask) != 0) ? 1'b1 : 1'b0;

endmodule
`default_nettype wire
