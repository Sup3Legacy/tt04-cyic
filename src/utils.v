// 4-way multiplexer
module mux4 (
    input [3:0] i,
    input [1:0] sel,

    output o
);
    assign o = i[sel];
endmodule

// Outputs a signal upon input change
module change_detector(
  input clk,
  input [1:0] sel_in,

  output reg change_out
);
reg [1:0] last_value;

initial begin
  change_out = 1;
  last_value = 0;
end

always @(posedge clk) begin
  change_out = (sel_in != last_value);
  last_value = sel_in;
end
endmodule

module req_singleshot(
  input clk,
  input req,
  input is_ss,

  output o_req
);
  reg req_state;
  reg req_ss;

  initial begin
    req_state = 0;
    req_ss = 0;
  end

  always @ (posedge clk) begin
    req_ss <= (req & !req_state);
    req_state <= req;
  end

  assign o_req = is_ss ? req_ss : req;

endmodule
