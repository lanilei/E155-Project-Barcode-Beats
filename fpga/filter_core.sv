// Leilani Elkaslasy and Thomas Lilygren
//12/2/25
// Barcode Beats - filter_core.sv
// This file applies all filtering logic prior to SPI communication

module filter_core(input logic clk,
	               input logic reset,
	               input logic signal,
				   input logic sample,
			       output logic done,
			       output logic [31:0] filtered);

	logic barcode;

	// synchronize asynchronous barcode signal input 
	sync synchronizer(clk, reset, signal, barcode);
	
	// call decimated FIR filter
	fir filter(clk, reset, sample, barcode, done, filtered);


endmodule
