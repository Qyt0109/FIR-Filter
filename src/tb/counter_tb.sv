`timescale 1ns / 1ps

`define VCD_FILE "./vcds/counter_tb.vcd"


module counter_tb ();

  parameter CLK_PERIOD = 10;
  parameter CLK_PERIOD_HALF = CLK_PERIOD / 2;

  always #(CLK_PERIOD_HALF) clk = !clk;

  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars;
  end

  initial begin
    clk        <= 0;
    rst        <= 0;
    clk_enable <= 0;
  end

  initial begin
    reset(3);
    test(NUMBER_OF_TAPS * 3);
    $finish;
  end

  task automatic reset;
    input integer clk_periods;
    begin
      @(negedge clk);
      rst <= 1;
      repeat (clk_periods) #(CLK_PERIOD);
      $display("reset hold for %d clk", clk_periods);
      rst <= 0;
    end
  endtask  //automatic

  task automatic test;
    input integer clk_periods;
    begin
      @(negedge clk);
      clk_enable <= 1;
      repeat (clk_periods) begin
        #(CLK_PERIOD);
        $display("current count: %d, phase_min: %d", current_count, phase_min);
      end
      clk_enable <= 0;
    end
  endtask  //automatic

  parameter NUMBER_OF_TAPS = 64;
  localparam COUNTER_BITS = $clog2(NUMBER_OF_TAPS);
  localparam COUNTER_MIN = 0;
  localparam COUNTER_MAX = NUMBER_OF_TAPS - 1;

  reg clk;
  reg rst;
  reg clk_enable;
  wire [COUNTER_BITS-1:0] current_count;
  wire phase_min;


  counter #(
      .NUMBER_OF_TAPS(NUMBER_OF_TAPS)
  ) counter_inst (
      .clk(clk),
      .rst(rst),

      .clk_enable(clk_enable),

      .current_count(current_count),

      .phase_min(phase_min)
  );

endmodule
