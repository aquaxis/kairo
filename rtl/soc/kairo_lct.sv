`default_nettype none

module kairo_lct (
    input  wire        RST_N,
    input  wire        CLK,
    // Slave
    output wire        S_APB_READY,
    input  wire        S_APB_VALID,
    input  wire [ 3:0] S_APB_WSTB,
    input  wire [31:0] S_APB_ADDR,
    input  wire [31:0] S_APB_WDATA,
    output wire [31:0] S_APB_RDATA,
    // Master
    input  wire        MM_APB_READY,
    output wire        MM_APB_VALID,
    output wire [ 3:0] MM_APB_WSTB,
    output wire [31:0] MM_APB_ADDR,
    output wire [31:0] MM_APB_WDATA,
    input  wire [31:0] MM_APB_RDATA,
    // Master
    input  wire        M0_APB_READY,
    output wire        M0_APB_VALID,
    output wire [ 3:0] M0_APB_WSTB,
    output wire [31:0] M0_APB_ADDR,
    output wire [31:0] M0_APB_WDATA,
    input  wire [31:0] M0_APB_RDATA,
    input  wire        M1_APB_READY,
    output wire        M1_APB_VALID,
    output wire [ 3:0] M1_APB_WSTB,
    output wire [31:0] M1_APB_ADDR,
    output wire [31:0] M1_APB_WDATA,
    input  wire [31:0] M1_APB_RDATA,
    input  wire        M2_APB_READY,
    output wire        M2_APB_VALID,
    output wire [ 3:0] M2_APB_WSTB,
    output wire [31:0] M2_APB_ADDR,
    output wire [31:0] M2_APB_WDATA,
    input  wire [31:0] M2_APB_RDATA,
    input  wire        M3_APB_READY,
    output wire        M3_APB_VALID,
    output wire [ 3:0] M3_APB_WSTB,
    output wire [31:0] M3_APB_ADDR,
    output wire [31:0] M3_APB_WDATA,
    input  wire [31:0] M3_APB_RDATA,
    input  wire        M4_APB_READY,
    output wire        M4_APB_VALID,
    output wire [ 3:0] M4_APB_WSTB,
    output wire [31:0] M4_APB_ADDR,
    output wire [31:0] M4_APB_WDATA,
    input  wire [31:0] M4_APB_RDATA,
    input  wire        M5_APB_READY,
    output wire        M5_APB_VALID,
    output wire [ 3:0] M5_APB_WSTB,
    output wire [31:0] M5_APB_ADDR,
    output wire [31:0] M5_APB_WDATA,
    input  wire [31:0] M5_APB_RDATA,
    input  wire        M6_APB_READY,
    output wire        M6_APB_VALID,
    output wire [ 3:0] M6_APB_WSTB,
    output wire [31:0] M6_APB_ADDR,
    output wire [31:0] M6_APB_WDATA,
    input  wire [31:0] M6_APB_RDATA,
    input  wire        M7_APB_READY,
    output wire        M7_APB_VALID,
    output wire [ 3:0] M7_APB_WSTB,
    output wire [31:0] M7_APB_ADDR,
    output wire [31:0] M7_APB_WDATA,
    input  wire [31:0] M7_APB_RDATA
);

  // メモリマップ判定
  wire msel;
  wire [7:0] dsel;
  assign msel = (S_APB_ADDR[31:30] == 2'b00);
  assign dsel[0] = (S_APB_ADDR[31:28] == 4'b1000) & (S_APB_ADDR[18:16] == 3'd0);
  assign dsel[1] = (S_APB_ADDR[31:28] == 4'b1000) & (S_APB_ADDR[18:16] == 3'd1);
  assign dsel[2] = (S_APB_ADDR[31:28] == 4'b1000) & (S_APB_ADDR[18:16] == 3'd2);
  assign dsel[3] = (S_APB_ADDR[31:28] == 4'b1000) & (S_APB_ADDR[18:16] == 3'd3);
  assign dsel[4] = (S_APB_ADDR[31:28] == 4'b1000) & (S_APB_ADDR[18:16] == 3'd4);
  assign dsel[5] = (S_APB_ADDR[31:28] == 4'b1000) & (S_APB_ADDR[18:16] == 3'd5);
  assign dsel[6] = (S_APB_ADDR[31:28] == 4'b1000) & (S_APB_ADDR[18:16] == 3'd6);
  assign dsel[7] = (S_APB_ADDR[31:28] == 4'b1000) & (S_APB_ADDR[18:16] == 3'd7);

  wire w_msel;
  wire [7:0] w_dsel;
  assign w_msel = msel & S_APB_VALID;
  assign w_dsel[0] = dsel[0] & S_APB_VALID;
  assign w_dsel[1] = dsel[1] & S_APB_VALID;
  assign w_dsel[2] = dsel[2] & S_APB_VALID;
  assign w_dsel[3] = dsel[3] & S_APB_VALID;
  assign w_dsel[4] = dsel[4] & S_APB_VALID;
  assign w_dsel[5] = dsel[5] & S_APB_VALID;
  assign w_dsel[6] = dsel[6] & S_APB_VALID;
  assign w_dsel[7] = dsel[7] & S_APB_VALID;

  reg r_msel;
  reg [7:0] r_dsel;
  always @(posedge CLK) begin
    r_msel <= msel & ~(|(S_APB_WSTB));
    r_dsel[0] <= dsel[0] & ~(|(S_APB_WSTB));
    r_dsel[1] <= dsel[1] & ~(|(S_APB_WSTB));
    r_dsel[2] <= dsel[2] & ~(|(S_APB_WSTB));
    r_dsel[3] <= dsel[3] & ~(|(S_APB_WSTB));
    r_dsel[4] <= dsel[4] & ~(|(S_APB_WSTB));
    r_dsel[5] <= dsel[5] & ~(|(S_APB_WSTB));
    r_dsel[6] <= dsel[6] & ~(|(S_APB_WSTB));
    r_dsel[7] <= dsel[7] & ~(|(S_APB_WSTB));
  end

  assign MM_APB_VALID = (msel & S_APB_VALID) | r_msel;
  assign MM_APB_ADDR = S_APB_ADDR;
  assign MM_APB_WSTB = S_APB_WSTB;
  assign MM_APB_WDATA = S_APB_WDATA;

  assign M0_APB_VALID = (dsel[0] & S_APB_VALID) | r_dsel[0];
  assign M0_APB_ADDR = S_APB_ADDR;
  assign M0_APB_WSTB = S_APB_WSTB;
  assign M0_APB_WDATA = S_APB_WDATA;

  assign M1_APB_VALID = (dsel[1] & S_APB_VALID) | r_dsel[1];
  assign M1_APB_ADDR = S_APB_ADDR[31:0];
  assign M1_APB_WSTB = S_APB_WSTB[3:0];
  assign M1_APB_WDATA = S_APB_WDATA[31:0];

  assign M2_APB_VALID = (dsel[2] & S_APB_VALID) | r_dsel[2];
  assign M2_APB_ADDR = S_APB_ADDR[31:0];
  assign M2_APB_WSTB = S_APB_WSTB[3:0];
  assign M2_APB_WDATA = S_APB_WDATA[31:0];

  assign M3_APB_VALID = (dsel[3] & S_APB_VALID) | r_dsel[3];
  assign M3_APB_ADDR = S_APB_ADDR[31:0];
  assign M3_APB_WSTB = S_APB_WSTB[3:0];
  assign M3_APB_WDATA = S_APB_WDATA[31:0];

  assign S_APB_READY = 
    S_APB_VALID &
      (
        (msel & MM_APB_READY ) |
        (dsel[0] & M0_APB_READY) |
        (dsel[1] & M1_APB_READY) |
        (dsel[2] & M2_APB_READY) |
        (dsel[3] & M3_APB_READY) |
        (dsel[4] & M4_APB_READY) |
        (dsel[5] & M5_APB_READY) |
        (dsel[6] & M6_APB_READY) |
        (dsel[7] & M7_APB_READY) |

        (r_msel & MM_APB_READY ) |
        (r_dsel[0] & M0_APB_READY) |
        (r_dsel[1] & M1_APB_READY) |
        (r_dsel[2] & M2_APB_READY) |
        (r_dsel[3] & M3_APB_READY) |
        (r_dsel[4] & M4_APB_READY) |
        (r_dsel[5] & M5_APB_READY) |
        (r_dsel[6] & M6_APB_READY) |
        (r_dsel[7] & M7_APB_READY)
      );
  assign S_APB_RDATA = 
    {32{S_APB_VALID}} &
      (
        ((r_msel)?MM_APB_RDATA:32'd0) |
        ((r_dsel[0])?M0_APB_RDATA:32'd0) |
        ((r_dsel[1])?M1_APB_RDATA:32'd0) |
        ((r_dsel[2])?M2_APB_RDATA:32'd0) |
        ((r_dsel[3])?M3_APB_RDATA:32'd0) |
        ((r_dsel[4])?M4_APB_RDATA:32'd0) |
        ((r_dsel[5])?M5_APB_RDATA:32'd0) |
        ((r_dsel[6])?M6_APB_RDATA:32'd0) |
        ((r_dsel[7])?M7_APB_RDATA:32'd0)
      );

endmodule
`default_nettype wire
