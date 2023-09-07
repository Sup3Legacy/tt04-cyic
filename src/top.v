`include "utils.v"
`include "vn_unbiaser.v"
`include "mock_rngs.v"
`include "bist.v"
`include "vector_buffer.v"
`include "ring_oscillator.v"

module tt_um_sup3legacy_trng (
  input clk,
  input ena,
  input rst_n,
  input [7:0] ui_in,
  input [7:0] uio_in,
  output [7:0] uio_oe,
  output [7:0] uio_out,
  output [7:0] uo_out
);
  reg enabled;
  wire [3:0] entropy_valid;
  wire [3:0] entropy_bit;
  wire entropy_valid_muxed;
  wire entropy_bit_muxed;
  wire bit_valid;

  wire req;
  wire req_ss;
  wire req_rectified;
  wire [7:0] vector;
  wire vector_valid;

  wire vn_valid;
  wire vn_bit;

  wire user_entropy;
  wire user_entropy_valid;
  wire [1:0] entropy_selector;
  wire entropy_source_changed;
  wire bist_enabled;
  wire vn_enable;

  wire [1:0] wrapper_state;

  // Inputs

  // Input user entropy
  assign user_entropy = ui_in[0];
  // Input user entropy bit clock:
  // entropy bit is safe to read at clock posedge
  assign user_entropy_valid = ui_in[1];
  // Select between all 4 RNGs
  assign entropy_selector = ui_in[3:2];
  // Enable the BIST
  assign bist_enabled = ui_in[4];
  // Enable the Von Neumann debiaser
  assign vn_enable = ui_in[5];
  // Request entropy
  assign req = ui_in[6];
  // Whether the request should be single-shot
  // only trigger request on `(posedge req)`
  assign req_ss = ui_in[7];

  // Outputs
  assign uo_out = vector;
  assign uio_oe = 8'b00000000;
  assign uio_out = {6'b0, wrapper_state};

  // Temp
  assign wrapper_state = 2'b10;

  assign bit_valid = enabled;

  initial begin
      enabled = 0;
  end

  always @ (posedge clk) begin
      enabled = 1;
  end

  // All 4 RNGs
  ring_oscillator oscillator (enabled, entropy_valid[0], entropy_bit[0]);
  alternating_rng alternator (clk, entropy_valid[1], entropy_bit[1]);
  repeating_rng repeater (clk, entropy_valid[2], entropy_bit[2]);
  user_rng user (clk, user_entropy_valid, user_entropy, entropy_valid[3], entropy_bit[3]);

  // Mux all 4 entropy sources
  mux4 entropy_bit_mux(entropy_bit, entropy_selector, entropy_bit_muxed);
  mux4 entropy_valid_mux(entropy_valid, entropy_selector, entropy_valid_muxed);

  // The source change detector
  change_detector entropy_source_change_detector (clk, entropy_selector, entropy_source_changed);

  // Unbias the entropy
  vn_unbiaser_wrapper vn (clk, rst_n | entropy_source_changed, vn_enable, entropy_valid_muxed, entropy_valid_muxed, vn_valid, vn_bit);

  // TODO: BIST
  // The BIST's output validity bit should be further fed into the entropy
  // vector module

  // Request handling
  req_singleshot ss (clk, req, req_ss, req_rectified);

  // Collect the entropy into buffer
  vector_buffer entropy_buffer (clk, vn_bit, vn_valid, req, vector, vector_valid);
endmodule
