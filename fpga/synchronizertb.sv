// Leilani Elkaslasy and Thomas Lilygren
//12/2/25
// Barcode Beats - top module
// This file tests the synchronizer

`timescale 1ns/1ps

module sync_tb;

    // Testbench signals
    logic clk;
    logic reset;
    logic async;
    logic synced;

    // DUT instantiation
    sync dut (
        .clk(clk),
        .reset(reset),
        .async(async),
        .synced(synced)
    );

    // Clock: 10 ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Test stimulus
    initial begin
        // Initialize signals
        reset = 0;
        async = 0;

        // Apply reset
        $display("=== Applying reset ===");
        #20;
        reset = 1;

        // Wait a few clocks
        repeat (3) @(posedge clk);

        $display("=== Toggling async at non-clock times ===");

        // Change async between clock edges (metastability scenario)
        #7  async = 1;   // not aligned with clock
        #13 async = 0;
        #11 async = 1;
        #6  async = 0;

        // Let sync pipeline settle
        repeat (5) @(posedge clk);

        $display("=== End of simulation ===");
        #50;
        $finish;
    end

    // Simple monitor
    initial begin
        $display("   time   | clk async synced");
        $monitor("%8t |  %0b     %0b      %0b", $time, clk, async, synced);
    end

endmodule

