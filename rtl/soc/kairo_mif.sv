`default_nettype none

module kairo_mif (
    input  wire        RST_N,
    input  wire        CLK,
    // Instruction Memory
    output wire        I_MEM_READY,
    input  wire        I_MEM_VALID,
    input  wire [31:0] I_MEM_ADDR,
    output wire [31:0] I_MEM_RDATA,
    input  wire [31:0] I_MEM_WDATA,
    input  wire [ 3:0] I_MEM_WSTB,
    output wire        I_MEM_EXCPT,
    // Data Memory
    output wire        D_MEM_READY,
    input  wire        D_MEM_VALID,
    input  wire [ 3:0] D_MEM_WSTB,
    input  wire [31:0] D_MEM_ADDR,
    input  wire [31:0] D_MEM_WDATA,
    output wire [31:0] D_MEM_RDATA,
    output wire        D_MEM_EXCPT,
    // imem
    output wire [31:0] IMEM_RADR,
    input  wire [31:0] IMEM_RDOUT,
    output wire [31:0] IMEM_WADR,
    output wire [ 3:0] IMEM_WEB,
    output wire [31:0] IMEM_WDIN,
    // dmem
    output wire [31:0] DMEM_RADR,
    input  wire [31:0] DMEM_RDOUT,
    output wire [31:0] DMEM_WADR,
    output wire [ 3:0] DMEM_WEB,
    output wire [31:0] DMEM_WDIN
);

  wire sel_inst_wd, sel_inst_wi, sel_data;
  assign sel_inst_wi = (I_MEM_VALID & (I_MEM_ADDR[31:28] == 4'h0)) & (|I_MEM_WSTB[3:0]);
  assign sel_inst_wd = (D_MEM_VALID & (D_MEM_ADDR[31:28] == 4'h0)) & (|D_MEM_WSTB[3:0]);
  assign sel_data    = (D_MEM_VALID & (D_MEM_ADDR[31:28] == 4'h1));

  // delay for ready
  reg i_valid_d;
  always @(posedge CLK) begin
    if (!RST_N) begin
      i_valid_d <= 1'b0;
    end else begin
      i_valid_d <= I_MEM_VALID;
    end
  end

  // imem
  wire imem_wr;
  wire [3:0] imem_st;
  wire [31:0] imem_ad;
  wire [31:0] imem_di;

  assign imem_wr =  (sel_inst_wi)?(I_MEM_WSTB[3] | I_MEM_WSTB[2] | I_MEM_WSTB[1] | I_MEM_WSTB[0])
                    : (sel_inst_wd)?(D_MEM_WSTB[3] | D_MEM_WSTB[2] | D_MEM_WSTB[1] | D_MEM_WSTB[0])
                    : 1'b0;
  assign imem_st = (sel_inst_wi) ? I_MEM_WSTB : (sel_inst_wd) ? 4'b1111 : 4'd0;
  assign imem_ad = (sel_inst_wi) ? I_MEM_ADDR[31:0] : (sel_inst_wd) ? D_MEM_ADDR[31:0] : 32'd0;
  assign imem_di = (sel_inst_wi) ? I_MEM_WDATA[31:0] : (sel_inst_wd) ? D_MEM_WDATA[31:0] : 32'd0;

  // sram signal
  assign IMEM_WEB[0] = (!i_valid_d) ? (imem_wr & imem_st[0]) : 1'b0;
  assign IMEM_WEB[1] = (!i_valid_d) ? (imem_wr & imem_st[1]) : 1'b0;
  assign IMEM_WEB[2] = (!i_valid_d) ? (imem_wr & imem_st[2]) : 1'b0;
  assign IMEM_WEB[3] = (!i_valid_d) ? (imem_wr & imem_st[3]) : 1'b0;
  assign IMEM_WADR[31:0] = imem_ad[31:0];
  assign IMEM_WDIN[31:0] = imem_di[31:0];
  assign IMEM_RADR[31:0] = I_MEM_ADDR[31:0];
  assign I_MEM_RDATA = IMEM_RDOUT[31:0];
  assign I_MEM_READY = i_valid_d;
  assign I_MEM_EXCPT = 1'b0;

  // dmem
  wire dmem_wr;
  wire [3:0] dmem_st;
  wire [31:0] dmem_ad;
  wire [31:0] dmem_di;

  // delay for ready
  reg d_valid_d;
  always @(posedge CLK) begin
    d_valid_d <= D_MEM_VALID;
  end
  assign dmem_wr = (sel_data)?D_MEM_WSTB[3] | D_MEM_WSTB[2] | D_MEM_WSTB[1] | D_MEM_WSTB[0] : 1'b0;
  assign dmem_st = (sel_data) ? {D_MEM_WSTB[3], D_MEM_WSTB[2], D_MEM_WSTB[1], D_MEM_WSTB[0]} : 4'd0;
  assign dmem_ad = (sel_data) ? D_MEM_ADDR[31:0] : 32'd0;
  assign dmem_di = (sel_data) ? D_MEM_WDATA : 32'd0;

  // sram signal
  assign DMEM_WEB[0] = dmem_wr & dmem_st[0];
  assign DMEM_WEB[1] = dmem_wr & dmem_st[1];
  assign DMEM_WEB[2] = dmem_wr & dmem_st[2];
  assign DMEM_WEB[3] = dmem_wr & dmem_st[3];
  assign DMEM_WADR[31:0] = dmem_ad[31:0];
  assign DMEM_RADR[31:0] = dmem_ad[31:0];
  assign DMEM_WDIN[31:0] = dmem_di[31:0];
  assign D_MEM_RDATA = DMEM_RDOUT[31:0];
  assign D_MEM_READY = d_valid_d;
  assign D_MEM_EXCPT = 1'b0;

endmodule

`default_nettype wire
