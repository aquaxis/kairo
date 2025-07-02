`default_nettype none

module kairo_bussel (
    // Select
    input  wire        SELECT,
    // Main Bus
    input  wire        M_VALID,
    output wire        M_READY,
    input  wire [ 3:0] M_WSTB,
    input  wire [31:0] M_ADDR,
    input  wire [31:0] M_WDATA,
    output wire [31:0] M_RDATA,
    output wire        M_EXCEPT,
    // Debug Bus
    input  wire        D_VALID,
    output wire        D_READY,
    input  wire [ 3:0] D_WSTB,
    input  wire [31:0] D_ADDR,
    input  wire [31:0] D_WDATA,
    output wire [31:0] D_RDATA,
    output wire        D_EXCEPT,
    // Select Bus
    output wire        O_VALID,
    input  wire        O_READY,
    output wire [ 3:0] O_WSTB,
    output wire [31:0] O_ADDR,
    output wire [31:0] O_WDATA,
    input  wire [31:0] O_RDATA,
    input  wire        O_EXCEPT
);
  assign O_VALID  = (SELECT) ? D_VALID : M_VALID;
  assign O_WSTB   = (SELECT) ? D_WSTB : M_WSTB;
  assign O_ADDR   = (SELECT) ? D_ADDR : M_ADDR;
  assign O_WDATA  = (SELECT) ? D_WDATA : M_WDATA;
  assign M_READY  = (SELECT) ? 1'b0 : O_READY;
  assign M_RDATA  = (SELECT) ? 32'd0 : O_RDATA;
  assign M_EXCEPT = (SELECT) ? 1'b0 : O_EXCEPT;
  assign D_READY  = (SELECT) ? O_READY : 1'b0;
  assign D_RDATA  = (SELECT) ? O_RDATA : 32'd0;
  assign D_EXCEPT = (SELECT) ? O_EXCEPT : 1'b0;

endmodule

`default_nettype wire
