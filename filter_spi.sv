// Leilani Elkaslasy and Thomas Lilygren
//12/2/25
// Barcode Beats - top module
// filter_spi.sv
// This file controls the SPI communication protocol between the FPGA and MCU on the FPGA side 

module filter_spi(input  logic sck, 			// Spi clk
				  input  logic ce,  			// chip enable from mcu 
                  output logic sdo, 			// miso
                  input logic [31:0] filtered); //data send
	
	// shift register holds transmitted word 
    logic [31:0] tuning_word_captured;
	logic [5:0] sck_count;
	
	//   // 2-flop synchronizer: bring 'done' safely into sck domain                                  

	
	always_ff @(posedge sck)
		// chip enable active low, when high reset count and transmitted word 
		if(ce) begin
			sck_count <= 6'b0;
			tuning_word_captured <= 32'b0;
		end else begin
			if(sck_count == 0) begin
				tuning_word_captured <= filtered; 
			end else begin
				tuning_word_captured <= {tuning_word_captured[30:0], 1'b0};
			end
			sck_count <= sck_count + 1'b1;
		end                                     	
			
	// send sdo on the negative edge of sck
    always_ff @(negedge sck)
        if(!ce) begin
			sdo <= tuning_word_captured[31];
		end else begin 
			sdo <= 1'b0; // idle when not selected 
		end
endmodule