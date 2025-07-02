`default_nettype none

module apb_gpio (
    input wire RST_N,
    input wire CLK,

    input  wire        S_APB_PSEL,
    input  wire        S_APB_PENABLE,
    input  wire        S_APB_PWRITE,
    output wire        S_APB_PREADY,
    input  wire [15:0] S_APB_PADDR,
    input  wire [31:0] S_APB_PWDATA,
    output wire [31:0] S_APB_PRDATA,
    output wire        S_APB_PSLVERR,

    input  wire [31:0] GPIO_I,
    output wire [31:0] GPIO_O,
    output wire [31:0] GPIO_OE
);

  localparam A_DIN = 16'h0000;
  localparam A_DOUT = 16'h0004;
  localparam A_DIR = 16'h0008;

  wire wr_ena, rd_ena, wr_ack, rd_ack;
  reg rd_ena_d;
  reg [31:0] reg_rdata;

  assign wr_ena = (S_APB_PSEL & S_APB_PENABLE & S_APB_PWRITE) ? 1'b1 : 1'b0;
  assign rd_ena = (S_APB_PSEL & S_APB_PENABLE & ~S_APB_PWRITE) ? 1'b1 : 1'b0;
  assign wr_ack = wr_ena;
  assign rd_ack = rd_ena_d & rd_ena;

  // Register
  reg [31:0] reg_dir, reg_dout;

  // Write
  always @(posedge CLK) begin
    if (!RST_N) begin
      reg_dir  <= 0;
      reg_dout <= 0;
    end else begin
      if (wr_ena) begin
        case (S_APB_PADDR[15:0] & 16'hFFFC)
          A_DOUT: reg_dout <= S_APB_PWDATA;
          A_DIR:  reg_dir <= S_APB_PWDATA;
          default: begin
          end
        endcase
      end
    end
  end

  // Read
  always @(posedge CLK) begin
    if (!RST_N) begin
      rd_ena_d        <= 1'b0;
      reg_rdata[31:0] <= 32'd0;
    end else begin
      rd_ena_d <= rd_ena & ~rd_ack;
      case (S_APB_PADDR[15:0] & 16'hFFFC)
        A_DIN:   reg_rdata[31:0] <= GPIO_I;
        A_DOUT:  reg_rdata[31:0] <= reg_dout;
        A_DIR:   reg_rdata[31:0] <= reg_dir;
        default: reg_rdata[31:0] <= 32'd0;
      endcase
    end
  end

  assign S_APB_PREADY       = (wr_ack | rd_ack);
  assign S_APB_PRDATA[31:0] = (rd_ack) ? reg_rdata[31:0] : 32'd0;
  assign S_APB_PSLVERR      = 1'b0;

  // GPIO
  assign GPIO_O             = reg_dout;
  assign GPIO_OE            = reg_dir;

endmodule
`default_nettype wire
