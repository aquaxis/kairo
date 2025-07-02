`default_nettype wire

module mem_ram #(
    parameter AWIDTH   = 8,
    parameter DWIDTH   = 32,
    parameter MEM_FILE = ""
) (
    input  wire              WCK,
    input  wire              WEB,
    input  wire [AWIDTH-1:0] WAD,
    input  wire [DWIDTH-1:0] WDI,
    input  wire              RCK,
    input  wire [AWIDTH-1:0] RAD,
    output wire [DWIDTH-1:0] RDO
);
  reg [DWIDTH -1:0]    ram [0:(2**(AWIDTH-2)) -1];
  reg [DWIDTH -1:0]    rd_reg;
  always @(posedge WCK) begin
    if (WEB) ram[WAD[AWIDTH-1:2]] <= WDI;
  end
  always @(posedge RCK) begin
    rd_reg <= ram[RAD[AWIDTH-1:2]];
  end
  assign RDO = rd_reg;
  initial $readmemh(MEM_FILE, ram);
endmodule

`default_nettype none
