`timescale 1ns / 1ps

`define VCD_FILE "./vcds/coeffs_tb.vcd"
`define COEFFS_FILE "filter_coeffs/filter_coeffs.txt"

module coeffs_tb ();
  parameter NUMBER_OF_TAPS = 64;
  parameter COEFF_BITS = 16;

  localparam COUNTER_BITS = $clog2(NUMBER_OF_TAPS);

  parameter CLK_PERIOD = 10;
  parameter CLK_PERIOD_HALF = CLK_PERIOD / 2;

  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars;
  end

  initial begin
    test({32'h89abcdef, {(NUMBER_OF_TAPS * COEFF_BITS - 16 * 4) / 4{4'he}}, 32'h01234567});
    $finish;
  end

  task automatic test;
    input [COEFF_BITS*NUMBER_OF_TAPS-1:0] i_coeffs;
    integer current_count_index;
    begin
      coeffs = i_coeffs;
      for (
          current_count_index = 0;  //
          current_count_index < NUMBER_OF_TAPS;  //
          current_count_index = current_count_index + 1
      ) begin
        extract_coeff(current_count_index);
      end
    end
  endtask  //automatic

  task automatic extract_coeff;
    input integer i_current_count;
    begin
      current_count <= i_current_count;
      #(CLK_PERIOD);
      $display("index: %d, value: %h", current_count, coeff);
    end
  endtask  //automatic

  reg [COUNTER_BITS-1:0] current_count;
  reg [COEFF_BITS*NUMBER_OF_TAPS-1:0] coeffs;
  wire signed [COEFF_BITS-1:0] coeff;

  coeffs #(
      .NUMBER_OF_TAPS(NUMBER_OF_TAPS),
      .COEFF_BITS    (COEFF_BITS)
  ) coeffs_inst (
      .current_count(current_count),
      .coeffs       (coeffs),
      .coeff        (coeff)
  );

endmodule
