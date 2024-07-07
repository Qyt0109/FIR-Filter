`timescale 1ns / 1ps

`define VCD_FILE "./vcds/delay_pipeline_tb.vcd"


module delay_pipeline_tb ();

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
  ;

  initial begin
    print_dut();
    reset(3);
    print_dut();
    test(5);
    print_dut();
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
    input integer number_of_tests;
    begin
      repeat (number_of_tests) push_data($urandom);
    end
  endtask  //automatic

  task automatic print_dut;
    integer delay_pipeline_index;
    begin
      for (
          delay_pipeline_index = 0;  //
          delay_pipeline_index < NUMBER_OF_TAPS;  //
          delay_pipeline_index = delay_pipeline_index + 1
      ) begin
        $display("index: %d, pipe value: %h",  //
                 delay_pipeline_index,  //
                 delay_pipeline_inst.delay_pipeline[delay_pipeline_index]);
      end
    end
  endtask  //automatic

  task automatic push_data;
    input [FILTER_IN_BITS-1:0] in_data;
    begin
      @(negedge clk);
      clk_enable <= 1;
      filter_in  <= in_data;
      $display("Pushed data: %h", in_data);
      repeat (NUMBER_OF_TAPS) #(CLK_PERIOD);
      clk_enable <= 0;
    end
  endtask  //automatic

  parameter FILTER_IN_BITS = 16;
  parameter FILTER_OUT_BITS = 16;
  parameter NUMBER_OF_TAPS = 64;

  reg clk;
  reg rst;
  //   reg phase_min;
  //   reg [COUNTER_BITS-1:0] current_count;
  reg signed [FILTER_IN_BITS-1:0] filter_in;
  wire signed [FILTER_OUT_BITS-1:0] delay_filter_in;

  delay_pipeline #(
      .FILTER_IN_BITS (FILTER_IN_BITS),
      .FILTER_OUT_BITS(FILTER_OUT_BITS),
      .NUMBER_OF_TAPS (NUMBER_OF_TAPS)
  ) delay_pipeline_inst (
      .clk(clk),
      .rst(rst),
      .phase_min(phase_min),
      .current_count(current_count),
      .filter_in(filter_in),
      .delay_filter_in(delay_filter_in)
  );

  //   parameter NUMBER_OF_TAPS = 64;
  localparam COUNTER_BITS = $clog2(NUMBER_OF_TAPS);
  localparam COUNTER_MIN = 0;
  localparam COUNTER_MAX = NUMBER_OF_TAPS - 1;

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
