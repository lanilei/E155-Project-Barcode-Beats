// Leilani Elkaslasy and Thomas Lilygren
//12/2/25
// Barcode Beats - filter test bench 
// This file incorporates all aspects of the FPGA design to apply ADSR enveloping on the input barcode signal


`timescale 1ns/1ns
//`default_nettype none
//`define N_TV 10

module filtertb();
	// Set up test signals
	logic clk;
	logic reset;
	logic sample;
	logic signal;
	logic [31:0] data_out;
	logic [31:0] expected;
	logic [7:0] signaltest;
			
			
	// Instantiate the device under test
	fir dut(clk, reset, sample, signal, data_out);

	// Generate clock signal with a period of 10 timesteps.
	always begin
		clk = 1'b1; #5; clk = 1'b0; #5;
	end

	// Test vectors 
	assign signaltest = 8'b10010110; 
	/*assign signaltest[1] = 8'b00000000;
	assign signaltest[2] = 8'b11111111;
	assign signaltest[3] = 8'b00000001;
	assign signaltest[4] = 8'b00000010;
	assign signaltest[5] = 8'b00000100;
	assign signaltest[6] = 8'b00001000;
	assign signaltest[7] = 8'b00010000;
	assign signaltest[8] = 8'b00100000;
	assign signaltest[9] = 8'b01000000;
	assign signaltest[10] = 8'b10000000;*/
	
	// Expected vectors
	assign expected  = 32'b00000000000000000000000100011110; // 286
	/*assign expected[1]  = 32'b00000000000000000000000001110100; // 116
	assign expected[2]  = 32'b00000000000000000000000011111101; // 253
	assign expected[3]  = 32'b00000000000000000000000000101010; //  42
	assign expected[4]  = 32'b00000000000000000000000001111111; // 127
	assign expected[5]  = 32'b00000000000000000000000001010100; //  84
	assign expected[6]  = 32'b00000000000000000000000000001010; //  10
	assign expected[7]  = 32'b00000000000000000000000001010100; //  84
	assign expected[8]  = 32'b00000000000000000000000000001010; //  10
	assign expected[9]  = 32'b00000000000000000000000000000000; //   0
	assign expected[10] = 32'b00000000000000000000000000100000; //  32 */
	
initial begin 
	signal = 0; sample = 0; reset = 0; #5; reset = 1; sample = 1; #5;

	for(int i = 0; i < 8; i++) begin
		signal = signaltest[i];
		@(posedge clk)
		
		if(i >=

	end
endmodule
		
