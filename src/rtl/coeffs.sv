module coeffs #(
    parameter NUMBER_OF_TAPS = 64,  // number of coeffs
    parameter COEFF_BITS     = 16   // coeff bits
) (
    input [             COUNTER_BITS-1:0] current_count,  // which coeff to access
    input [COEFF_BITS*NUMBER_OF_TAPS-1:0] coeffs,         // all coeffs joined together

    output signed [COEFF_BITS-1:0] coeff  // single coeff extracted from coeffs
);

  localparam COUNTER_BITS = $clog2(NUMBER_OF_TAPS);

  // region extract each coeff from coeffs
  wire signed [COEFF_BITS-1:0] r_coeffs[0:NUMBER_OF_TAPS-1];

  genvar r_coeffs_index;
  generate
    for (
        r_coeffs_index = 0;  //
        r_coeffs_index < NUMBER_OF_TAPS;  //
        r_coeffs_index = r_coeffs_index + 1
    ) begin : gen_r_coeffs
      assign r_coeffs[r_coeffs_index] = coeffs[(r_coeffs_index+1)*COEFF_BITS-1:r_coeffs_index*COEFF_BITS];
    end
  endgenerate
  // region extract each coeff from coeffs

  // region access single coeff
  assign coeff = r_coeffs[current_count];
  // endregion access single coeff

endmodule
