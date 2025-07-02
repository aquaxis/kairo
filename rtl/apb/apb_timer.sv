`default_nettype none

module apb_timer (
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
    output wire        DONE
);

  localparam A_CTRL = 16'h0000;
  localparam A_COUNTER = 16'h0004;

  wire wr_ena, rd_ena, wr_ack, rd_ack;
  reg rd_ena_d;
  reg [31:0] reg_rdata;

  assign wr_ena = (S_APB_PSEL & S_APB_PENABLE & S_APB_PWRITE) ? 1'b1 : 1'b0;
  assign rd_ena = (S_APB_PSEL & S_APB_PENABLE & ~S_APB_PWRITE) ? 1'b1 : 1'b0;
  assign wr_ack = wr_ena;
  assign rd_ack = rd_ena_d & rd_ena;

  // Register
  reg         reg_ena;
  reg  [31:0] reg_time;

  wire        wire_done;

  always @(posedge CLK) begin
    if (!RST_N) begin
      reg_ena  <= 1'b0;
      reg_time <= 32'd0;
    end else begin
      if (wr_ena) begin
        case (S_APB_PADDR[15:0] & 16'hFFFC)
          A_CTRL: reg_ena <= S_APB_PWDATA[0];
          default: begin
          end
        endcase
      end
      if (wr_ena & ((S_APB_PADDR[15:0] & 16'hFFFC) == A_COUNTER)) begin
        reg_time <= S_APB_PWDATA;
      end else begin
        if (reg_time > 32'd0) begin
          reg_time <= reg_time - 32'd1;
        end
      end
    end
  end

  assign wire_done = (reg_time == 32'd0);

  always @(posedge CLK) begin
    if (!RST_N) begin
      rd_ena_d        <= 1'b0;
      reg_rdata[31:0] <= 32'd0;
    end else begin
      rd_ena_d <= rd_ena & ~rd_ack;
      case (S_APB_PADDR[15:0] & 16'hFFFC)
        A_CTRL: reg_rdata[31:0] <= {30'd0, wire_done, reg_ena};
        A_COUNTER: reg_rdata[31:0] <= reg_time;
        default: reg_rdata[31:0] <= 32'd0;
      endcase
    end
  end

  assign S_APB_PREADY       = (wr_ack | rd_ack);
  assign S_APB_PRDATA[31:0] = (rd_ack) ? reg_rdata[31:0] : 32'd0;
  assign S_APB_PSLVERR      = 1'b0;

  assign DONE               = wire_done & reg_ena;
endmodule
`default_nettype wire
