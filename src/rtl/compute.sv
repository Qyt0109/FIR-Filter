module compute #(
    parameter FILTER_IN_BITS = 16,
    parameter FILTER_OUT_BITS = 16,
    parameter NUMBER_OF_TAPS = 64,
    parameter COEFF_BITS = 16,
    parameter COEFF_FRAC_BITS = 16
) (
    input clk,
    input rst,
    input clk_enable,

    input signed [FILTER_IN_BITS-1:0] delay_filter_in,  // from delay pipeline

    input signed [COEFF_BITS-1:0] coeff,  // single coeff extracted from coeffs

    input phase_min,  // from counter

    output reg signed [FILTER_OUT_BITS-1:0] filter_out  // filtered data sample
);

  localparam PRODUCT_BITS = FILTER_IN_BITS + FILTER_OUT_BITS;

  // signed fixed-point 32.16
  wire signed [PRODUCT_BITS-1:0] product = delay_filter_in * coeff;

  // sign extended product 34.16
  wire signed [PRODUCT_BITS-1+2:0] sign_extended_product = $signed(
      {
        {2{product[PRODUCT_BITS-1]}},  // sign extended
        product
      }
  );

  // acc
  reg signed [PRODUCT_BITS-1+2:0] acc_out;
  wire signed [PRODUCT_BITS-1+2:0] next_value_to_add = acc_out;

  wire signed [PRODUCT_BITS-1+3:0] add_temp = sign_extended_product + next_value_to_add;

  wire signed [PRODUCT_BITS-1+2:0] acc_sum = add_temp[PRODUCT_BITS-1+2:0];  // cutoff overflow bit

  wire signed [PRODUCT_BITS-1+2:0] acc_in = phase_min ? sign_extended_product : acc_sum;

  reg signed [PRODUCT_BITS-1+2:0] acc_final;

  // update acc_out each clk cycle
  always @(posedge clk, posedge rst) begin : update_acc_out
    if (rst) acc_out <= 0;
    else if (clk_enable) acc_out <= acc_in;

  end

  // caculate final sum of this round
  always @(posedge clk, posedge rst) begin
    if (rst) acc_final <= 0;
    else if (phase_min) acc_final <= acc_out;
  end


  /* rounding: floor, overflow: saturate
  ┌───────────────────────────────────────────────────────────────────────────┐
  │                                                                           │
  │    ◀─────16──────▶        ◀──8──▶          ◀──────────24─────────▶        │
  │   ┌┐                     ┌┐               ┌┐                              │
  │   S├┬┬┬┬┬┬┬┬┬┬┬┬┬┬┐      S├┬┬┬┬┬┬┐        S├┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┐       │
  │   └┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┘  *   └┴┴┴┴┴┤││    =   └┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┤││       │
  │     ◀────────────▶         ◀──▶└┴┘          ◀──────────────────▶└┴┘       │
  │           int              int ◀─▶                   int        ◀─▶       │
  │                               frac                             frac       │
  │                                                                           │
  │                                                                    frac   │
  │                                       ┌┐         ◀─────16──────▶    ◀─▶   │
  │                              ===>     S├┬┬┬┬┐   ┌┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┐   ┌┬┐   │
  │                                       └┴┴┴┴┴┘...└┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┘...│││   │
  │                                                  ◀─────────────▶    └┴┘   │
  │                                      overflow       coverted        ◀─▶   │
  │                                     (saturate)       result        round  │
  │                                                                   (floor) │
  │                                                                           │
  └───────────────────────────────────────────────────────────────────────────┘
  ┌────────────────────────────────────────────────────────────┐
  │(s)iii_iiii_iiii_iiii * (s)iii_ii.ff                        │
  │=                                                           │
  │(s)iii_ii|ii_iiii_iiii_iiii_ii|.ff                          │
  │                                                            │
  │if ((s == 0) & (iii_ii != 000_00)) => positive overflowed   │
  │=> |01_1111_1111_1111_11|                                   │
  │                                                            │
  │elsif ((s == 1) & (iii_ii) != 111_11) => negative overflowed│
  │=> |10_0000_0000_0000_00|                                   │
  │                                                            │
  │else => not overflowed                                      │
  │=> |ii_iiii_iiii_iiii_ii|                                   │
  └────────────────────────────────────────────────────────────┘
  */

  localparam ACC_FINAL_BITS = PRODUCT_BITS + 2;  // = FILTER_IN_BITS + COEFF_BITS + 2
  localparam ACC_FINAL_SIGN_BIT = ACC_FINAL_BITS - 1;  // Location of Sign bit
  localparam ACC_FINAL_CHECK_BIT_HIGH = ACC_FINAL_SIGN_BIT - 1; // Location of high bit of check region
  localparam ACC_FINAL_CHECK_BIT_LOW = COEFF_FRAC_BITS + FILTER_OUT_BITS; // Location of low bit of check region
  localparam ACC_FINAL_CHECK_BITS = ACC_FINAL_CHECK_BIT_HIGH - ACC_FINAL_CHECK_BIT_LOW + 1; // Number of bits of check region

  localparam ACC_FINAL_CONVERTED_HIGH_BIT = COEFF_FRAC_BITS + FILTER_OUT_BITS - 1;
  localparam ACC_FINAL_CONVERTED_LOW_BIT = COEFF_FRAC_BITS;

  wire acc_final_sign_bit = acc_final[ACC_FINAL_SIGN_BIT];

  // sign = 0 and overflowed part are not all 0
  wire is_positive_overflow = (  //
  (acc_final_sign_bit == 0) &&  //
  (acc_final[ACC_FINAL_CHECK_BIT_HIGH:ACC_FINAL_CHECK_BIT_LOW] != {ACC_FINAL_CHECK_BITS{1'b0}})  //
  );

  // sign = 1 and overflowed part are not all 1
  wire is_negative_overflow = (  //
  (acc_final_sign_bit == 1) &&  //
  (acc_final[ACC_FINAL_CHECK_BIT_HIGH:ACC_FINAL_CHECK_BIT_LOW] != {ACC_FINAL_CHECK_BITS{1'b1}})  //
  );

  // 0111...1
  wire [FILTER_OUT_BITS-1:0] positive_overflow_filter_out = {1'b0, {(FILTER_OUT_BITS - 1) {1'b1}}};

  // 1000...0
  wire [FILTER_OUT_BITS-1:0] negative_overflow_filter_out = {1'b1, {(FILTER_OUT_BITS - 1) {1'b0}}};

  wire [FILTER_OUT_BITS-1:0] rounded_filter_out = acc_final[ACC_FINAL_CONVERTED_HIGH_BIT:ACC_FINAL_CONVERTED_LOW_BIT];

  always_comb begin : rounding_and_overflow_handling
    if (is_positive_overflow) filter_out = positive_overflow_filter_out;
    else if (is_negative_overflow) filter_out = negative_overflow_filter_out;
    else filter_out = rounded_filter_out;
  end

endmodule
