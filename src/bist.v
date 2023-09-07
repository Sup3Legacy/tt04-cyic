// Built-In Self Test unit

module bist (
    input clk,
    input rst,

    input entropy_bit,

    output is_broken,
    output is_init
);
  reg [63:0] bitvec;
  reg is_filling;
  reg [7:0] filling_status;

  initial begin
    bitvec = 0;
    is_filling = 1;
    filling_status = 0;
  end

  always @ (posedge clk) begin
    if (is_filling) begin
      filling_status = filling_status + 1;
      if (filling_status == 0) begin
          is_filling = 0;
      end
    end
    bitvec = (bitvec << 1) | { 63'b0, entropy_bit};
  end

endmodule

module bist_wrapper (
  input clk,
  input rst,

  input entropy_bit,

  output [1:0] state
);

endmodule
