`timescale 1ns / 1ps `default_nettype none

module tb_kairo_soc;

  // Clock and reset signals
  reg         RST_N;
  reg         CLK;
  reg         INTERRUPT;

  // GPIO signals
  wire [31:0] GPIO0_I;
  wire [31:0] GPIO0_O;
  wire [31:0] GPIO0_OE;
  wire [31:0] GPIO1_I;
  wire [31:0] GPIO1_O;
  wire [31:0] GPIO1_OE;

  // JTAG signals
  reg         TRST_N;
  reg         TCK;
  reg         TMS;
  reg         TDI;
  wire        TDO;

  // Clock generation
  localparam CLK_PERIOD = 10;  // 100MHz
  localparam TCK_PERIOD = 100;  // 10MHz JTAG clock

  initial begin
    CLK = 1'b0;
    forever #(CLK_PERIOD / 2) CLK = ~CLK;
  end

  initial begin
    TCK = 1'b0;
    forever #(TCK_PERIOD / 2) TCK = ~TCK;
  end

  // DUT instantiation
  kairo_soc dut (
      .RST_N    (RST_N),
      .CLK      (CLK),
      .INTERRUPT(INTERRUPT),
      // GPIO0
      .GPIO0_I  (GPIO0_I),
      .GPIO0_O  (GPIO0_O),
      .GPIO0_OE (GPIO0_OE),
      // GPIO1
      .GPIO1_I  (GPIO1_I),
      .GPIO1_O  (GPIO1_O),
      .GPIO1_OE (GPIO1_OE),
      // JTAG
      .TRST_N   (TRST_N),
      .TCK      (TCK),
      .TMS      (TMS),
      .TDI      (TDI),
      .TDO      (TDO)
  );

  assign GPIO0_I = (GPIO0_OE) ? GPIO0_O : 32'hZZZZZZZZ;
  assign GPIO1_I = (GPIO1_OE) ? GPIO1_O : 32'hZZZZZZZZ;

  // Dump waveform
  initial begin
    if ($test$plusargs("wave")) begin
      $dumpfile("tb_kairo_soc.vcd");
      $dumpvars(0, tb_kairo_soc);
    end
  end

  // Timeout watchdog
  integer timeout_cycles;
  initial begin
    if ($value$plusargs("timeout=%d", timeout_cycles)) begin
      #(timeout_cycles * CLK_PERIOD);
      $display("ERROR: Simulation timeout after %d cycles", timeout_cycles);
      $finish(1);
    end else begin
      // Default timeout: 1ms
      #1_000_000;
      $display("ERROR: Simulation timeout (default 1ms)");
      $finish(1);
    end
  end

  // Main test sequence
  initial begin
    // Initialize signals
    RST_N = 1'b0;
    INTERRUPT = 1'b0;
    TRST_N = 1'b0;
    TMS = 1'b0;
    TDI = 1'b0;

    // Wait for initial stabilization
    #100;

    // Release JTAG reset
    TRST_N = 1'b1;
    #100;

    // Release system reset
    RST_N = 1'b1;
    $display("System reset released at %t", $time);

    // Wait for boot sequence
    #1000;

    if ($test$plusargs("test_interrupt")) begin
      test_interrupt();
    end

    // Wait for program completion
    wait_for_completion();

    $display("Simulation completed successfully at %t", $time);
    $finish(0);
  end

  task test_interrupt;
    begin
      $display("Starting interrupt test at %t", $time);

      // Generate interrupt pulse
      @(posedge CLK);
      INTERRUPT = 1'b1;
      repeat (5) @(posedge CLK);
      INTERRUPT = 1'b0;

      // Wait for interrupt handling
      #1000;

      // Generate multiple interrupts
      repeat (3) begin
        @(posedge CLK);
        INTERRUPT = 1'b1;
        @(posedge CLK);
        INTERRUPT = 1'b0;
        #500;
      end
    end
  endtask

  task wait_for_completion;
    integer completion_addr;
    integer max_wait_cycles;
    begin
      max_wait_cycles = 100000;  // Default max wait

      if ($value$plusargs("completion_addr=%h", completion_addr)) begin
        // Wait for specific memory location to be written
        $display("Waiting for write to completion address 0x%08x", completion_addr);

        fork
          begin
            // Monitor data memory writes
            forever begin
              @(posedge CLK);
              if (dut.u_mem_dmem.WEB != 4'h0 && dut.u_mem_dmem.WAD == completion_addr[15:2]) begin
                $display("Completion detected: wrote 0x%08x to 0x%08x at %t", dut.u_mem_dmem.WDI,
                         completion_addr, $time);
                disable wait_timeout;
              end
            end
          end

          begin : wait_timeout
            repeat (max_wait_cycles) @(posedge CLK);
            $display("WARNING: Completion address not written within %d cycles", max_wait_cycles);
          end
        join_any

        disable fork;
      end else begin
        // Just wait for a fixed number of cycles
        repeat (10000) @(posedge CLK);
      end
    end
  endtask

  // Performance monitoring
  integer cycle_count;
  integer instr_count;

  always @(posedge CLK) begin
    if (RST_N) begin
      cycle_count <= cycle_count + 1;

      // Count valid instruction fetches
      if (dut.u_kairo.I_MEM_VALID && dut.u_kairo.I_MEM_READY) begin
        instr_count <= instr_count + 1;
      end
    end else begin
      cycle_count <= 0;
      instr_count <= 0;
    end
  end

  // Final statistics
  final begin
    $display("\n=== Simulation Statistics ===");
    $display("Total cycles: %d", cycle_count);
    $display("Instructions executed: %d", instr_count);
    if (cycle_count > 0) begin
      $display("Average CPI: %.2f", real'(cycle_count) / real'(instr_count));
    end
    $display("=============================\n");
  end

  // Monitor important signals
  always @(posedge CLK) begin
    if ($test$plusargs("debug")) begin
      if (dut.u_kairo.I_MEM_VALID && dut.u_kairo.I_MEM_READY) begin
        $display("[%t] PC: 0x%08x, Instr: 0x%08x", $time, dut.u_kairo.I_MEM_ADDR,
                 dut.u_kairo.I_MEM_RDATA);
      end

      if (dut.u_kairo.D_MEM_VALID && dut.u_kairo.D_MEM_READY && |dut.u_kairo.D_MEM_WSTB) begin
        $display("[%t] MEM Write: Addr=0x%08x, Data=0x%08x, Strb=0x%x", $time,
                 dut.u_kairo.D_MEM_ADDR, dut.u_kairo.D_MEM_WDATA, dut.u_kairo.D_MEM_WSTB);
      end
    end
  end

  // Helper function to load memory from file
  string mem_file;

endmodule

`default_nettype wire
