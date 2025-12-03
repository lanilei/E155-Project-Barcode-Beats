// Leilani Elkaslasy and Thomas Lilygren
//12/2/25
// Barcode Beats - top module
// This file incorporates all aspects of the FPGA design to apply ADSR enveloping on the input barcode signal

module top(input  logic sck, 
		   input  logic reset,
           input  logic ce,
		   input  logic signal,
           output logic sdo,
           output logic done);

	logic clk, sample;
	logic [8:0] samp_count;
	logic [31:0] filtered;

	// Internal high-speed oscillator
	HSOSC #(.CLKHF_DIV(2'b01))
		hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));

	// Get 48 kHz sampling rate
	always_ff @(posedge clk) begin
		if(!reset) begin
			samp_count <= 0;
			sample <=0;
		end else if(samp_count == 9'd500) begin
			samp_count <= 0;
			sample <= ~sample;
		end else samp_count <= samp_count + 1'b1;
	end

	// Call all filter SPI functions
	filter_spi spi(sck, ce, sdo, filtered);
	
	// Call filter core
	filter_core core(clk, reset, signal, sample, done, filtered);

endmodule