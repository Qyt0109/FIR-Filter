module delay_pipeline #(
    parameter FILTER_IN_BITS  = 16,
    parameter FILTER_OUT_BITS = 16,
    parameter NUMBER_OF_TAPS  = 64
) (
    input clk,
    input rst,

    input phase_min,
    input [COUNTER_BITS-1:0] current_count,

    input  signed [ FILTER_IN_BITS-1:0] filter_in,
    output signed [FILTER_OUT_BITS-1:0] delay_filter_in
);

  localparam COUNTER_BITS = $clog2(NUMBER_OF_TAPS);

  integer pipe_index;
  reg signed [FILTER_IN_BITS-1:0] delay_pipeline[0:NUMBER_OF_TAPS-1];

  always @(posedge clk, posedge rst) begin : delay_process
    if (rst) begin
      // reset pipeline
      for (pipe_index = 0; pipe_index < NUMBER_OF_TAPS; pipe_index = pipe_index + 1) begin
        delay_pipeline[pipe_index] <= 0;
      end
    end else begin
      // If phase_min is triggered (completed a counter round), shift new filter_in into the pipe
      if (phase_min) begin
        // Load new sample data into the pipe
        delay_pipeline[0] <= filter_in;
        // Shift others
        for (pipe_index = 1; pipe_index < NUMBER_OF_TAPS; pipe_index = pipe_index + 1) begin
          delay_pipeline[pipe_index] <= delay_pipeline[pipe_index-1];
        end
      end
    end
  end

  // MUX
  // current_count loop through any delay_pipeline, which is current and in the past input samples
  // delay_filter_in return each delay_pipeline at current_count index, which is the input sample in a specific delayed time
  assign delay_filter_in = delay_pipeline[current_count];

endmodule
