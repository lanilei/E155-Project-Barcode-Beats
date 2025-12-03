// Leilani Elkaslasy and Thomas Lilygren
//12/2/25
// Barcode Beats - top module
// This file incorporates all aspects of the FPGA design to apply ADSR enveloping on the input barcode signal

// Testbench for top module
`timescale 1ns/1ns

module toptb();

    // DUT interface signals
    logic sck;       // SPI clock from MCU
    logic reset;     // Active–low reset
    logic ce;        // Chip enable (active–low)
    logic signal;    // Barcode square-wave input
    logic sdo;       // SPI MISO (tuning word out)
    logic done;      // New tuning word ready

    // Instantiate the device under test
    top dut (
        .sck    (sck),
        .reset  (reset),
        .ce     (ce),
        .signal (signal),
        .sdo    (sdo),
        .done   (done)
    );

    // ------------------------------------------------------------
    // SPI clock generation (sck)
    // ------------------------------------------------------------
    initial begin
        sck = 1'b0;
        forever #5 sck = ~sck;     // 10 ns period = 100 MHz
    end

    // ------------------------------------------------------------
    // Square-wave generator for input 'signal'
    // ------------------------------------------------------------
  // ------------------------------------------------------------
// Square-wave generator for input 'signal'
// ------------------------------------------------------------
	initial begin
    signal = 1'b0;
    #50;               // wait until after reset deassertion
    forever begin
        #40 signal = ~signal;
    end
end
    // ------------------------------------------------------------
    // Reset and SPI stimulus
    // ------------------------------------------------------------
    initial begin
        // Initial values
        reset = 1'b0; // assert reset (active–low)
        ce    = 1'b1; // deassert chip enable (device not selected)

        // Optional: waveform dump for simulation
        $dumpfile("toptb.vcd");
        $dumpvars(0, toptb);

        // Hold reset for a few sck cycles
        repeat (10) @(posedge sck);
        reset = 1'b1; // release reset                            

        // Let the filter pipeline fill
        repeat (2000) @(posedge sck);

        // Do 10 SPI read transactions
        for (int i = 0; i < 10; i++) begin
            // Select SPI (active–low CE)
            ce = 1'b0;

            // Wait 32 sck edges to shift out a 32-bit word on sdo
            repeat (32) @(posedge sck);

            // De-select
            ce = 1'b1;

            // Idle between transfers
            repeat (200) @(posedge sck);
        end

        $display("=== End of simulation ===");
		#2_000_000;  // 2,000,000 ns = 2 ms
        $finish;
    end

    // ------------------------------------------------------------
    // Simple monitor
    // ------------------------------------------------------------
    initial begin
        $display(" time      reset ce sck signal done sdo");
        $monitor("%8t   %0b     %0b  %0b    %0b      %0b   %0b",
                  $time, reset, ce, sck, signal, done, sdo);
    end

endmodule
