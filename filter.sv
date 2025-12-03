// Leilani Elkaslasy and Thomas Lilygren
// Barcode Beats - FIR Filter
// This module implements and FIR filter to modulate the frequency of the original barcode square wave signal

module fir#(parameter NUM_TAPS = 8,     // Number of taps
            parameter COEFF_WIDTH = 8,  // Bit-width of tap coefficients
            parameter DATA_WIDTH = 16,  // Size of shifter bits - to be multiplied by tap coefficients
			parameter OUT_WIDTH = 32,   // output data and accumulator length (large enough to prevent overflow)
			parameter DECIMATE = 4)     // Decimation factor
           (input logic clk,
		    input logic reset,
			input logic sample,
			input logic signal,
			output logic done,
			output logic [OUT_WIDTH-1:0] data_out);
			
	// Array to store coefficients
	logic signed [COEFF_WIDTH-1:0] coeffs[0:NUM_TAPS-1];
	
	// Filter coefficients
	assign coeffs[0] = 8'sd10; 
	assign coeffs[1] = 8'sd32;
	assign coeffs[2] = 8'sd84;
	assign coeffs[3] = 8'sd127;
	assign coeffs[4] = 8'sd127;
	assign coeffs[5] = 8'sd84;
	assign coeffs[6] = 8'sd32;
	assign coeffs[7] = 8'sd10;
	
	
	// Array to store sample data and shift it
	logic signed [DATA_WIDTH-1:0] shifter[0:NUM_TAPS-1];
	
	// Array to store output data
	logic signed [OUT_WIDTH-1:0] accumulator;
	logic signed [OUT_WIDTH-1:0] acc_next;
	
	// Signal Extension
	logic signed [DATA_WIDTH-1:0] signal_extend;
	
	// Decimation
	logic [DECIMATE-1:0] decimate_count;
	
	// every other decimation loop, assert done to send to MCU 
	logic done_ready;
	
	always_comb begin
		signal_extend = signal ? 16'sd1 : 16'sd0; // extend one bit signal to 16 bits
		
		acc_next = coeffs[0]*shifter[0]   // calculate the accumulation for each round
				   + coeffs[1]*shifter[1]
				   + coeffs[2]*shifter[2]
				   + coeffs[3]*shifter[3]
				   + coeffs[4]*shifter[4]
				   + coeffs[5]*shifter[5]
				   + coeffs[6]*shifter[6]
				   + coeffs[7]*shifter[7];
	end
	
	always_ff @(posedge clk) begin
		// when reset active, reset shift register and outputs
		if(!reset) begin
			shifter[0] 		<= '0;  
			shifter[1] 		<= '0;
			shifter[2] 		<= '0;
			shifter[3] 		<= '0;
			shifter[4] 		<= '0;
			shifter[5]	    <= '0;
			shifter[6] 		<= '0;
			shifter[7] 		<= '0;
			accumulator 	<= '0;
			data_out 		<= '0;
			decimate_count  <= '0;	
			done            <= '0;
			done_ready      <= '0;
		end 
		
		// at each rising edge of sampling frequency, apply shifting 
		else if(sample) begin 
			 done <= 1'b0;  // default each sample
			// shifting
			shifter[0] <= signal_extend; 
			shifter[1] <= shifter[0];
			shifter[2] <= shifter[1];
			shifter[3] <= shifter[2];
			shifter[4] <= shifter[3];
			shifter[5] <= shifter[4];
			shifter[6] <= shifter[5];
			shifter[7] <= shifter[6];
			
			// computation
			accumulator <= acc_next;
			
			// decimation incrimenting
			decimate_count <= decimate_count + 1'b1;
			
			// decimation logic: send output when decimation loop complete 
            if (decimate_count == DECIMATE-1) begin
                decimate_count <= '0;
                data_out       <= accumulator;   
				accumulator    <= acc_next;
				done_ready       <= ~done_ready;
				if(done_ready) begin
					done <= 1'b1;
				end else begin
					done <= 1'b0;
				end
            end 
		end else begin 
			// make sure done is low when there is no sample clock 
			done <= 1'b0;
		end
	end
	
	
endmodule
	
	
	
			