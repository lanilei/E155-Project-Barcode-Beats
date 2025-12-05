// Leilani Elkaslasy and Thomas Lilygren
//12/2/25
// Barcode Beats Synchronizer Module
// This module addresses metastability issues from barcode scanner presses

module sync (input  logic  clk, 
			 input logic reset,
			 input  logic async,
			 output logic synced);

  logic sync1;

  always_ff @(posedge clk, negedge reset) begin
    if (!reset) begin
      sync1  <= '0;
      synced <= '0;
    end else begin
      sync1  <= async;
      synced <= sync1;
    end
  end


endmodule
