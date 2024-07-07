module counter #(
    parameter NUMBER_OF_TAPS = 64
) (
    input clk,
    input rst,

    input clk_enable,  // enable clk

    output reg [COUNTER_BITS-1:0] current_count,  // unsigned integer

    output phase_min
);

  localparam COUNTER_BITS = $clog2(NUMBER_OF_TAPS);
  localparam COUNTER_MIN = 0;
  localparam COUNTER_MAX = NUMBER_OF_TAPS - 1;

  always @(posedge clk, posedge rst) begin : count_process
    if (rst) begin
      // reset count to MIN
      current_count <= COUNTER_MIN;
    end else begin
      // if enable clk, start counting to max (NUMBER OF TAPS)
      if (clk_enable) begin
        // if count to MAX
        if (current_count == COUNTER_MAX) begin
          // next count value is set to MIN
          current_count <= COUNTER_MIN;
        end else begin
          current_count = current_count + 1;
        end
      end
    end
  end

  // Detect when done counting a round of taps
  assign phase_min = (clk_enable && (current_count == COUNTER_MIN));

endmodule
