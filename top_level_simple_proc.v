/*
Monash University ECE2072: Assignment
Top-level module for hardware-in-the-loop testing on DE10-Lite.
Connects switches, keys, LEDs, and 7-segment display to the processor.
*/

module top_level_simple_proc(
    input [8:0] SW,         // Switches for instruction/data input
    input [1:0] KEY,        // Pushbuttons for reset and clock
    output [9:0] LEDR,      // LEDs for bus output
    output [6:0] HEX5       // 7-segment display for tick FSM
);

    wire [15:0] bus;
    wire [3:0] tick;
    wire clk, rst;

    // Active-low buttons
    assign clk = ~KEY[1];
    assign rst = ~KEY[0];

    // Instantiate processor
    simple_proc u_proc(
        .clk(clk),
        .rst(rst),
        .din(SW),
        .bus(bus),
        .R0(), .R1(), .R2(), .R3(), .R4(), .R5(), .R6(), .R7(),
        .tick(tick)
    );

    // Connect bus output to LEDs (bottom 10 bits)
    assign LEDR = bus[9:0];

    // 4-to-7-segment decoder for tick FSM
    seg7_tick_decoder u_seg7(
        .tick(tick),
        .seg(HEX5)
    );

endmodule

// Simple 4-to-7-segment decoder for tick FSM (shows 1, 2, 4, or 8)
module seg7_tick_decoder(input [3:0] tick, output reg [6:0] seg);
    always @(*) begin
        case (tick)
            4'b0001: seg = 7'b0000110; // "1"
            4'b0010: seg = 7'b1011011; // "2"
            4'b0100: seg = 7'b1001111; // "4"
            4'b1000: seg = 7'b1111110; // "8"
            default: seg = 7'b1111111; // blank
        endcase
    end
endmodule