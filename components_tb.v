`timescale 1ns/1ns
/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the individual 
    components used in the processor.

Please enter your student ID:

*/
module components_tb;

    // --- sign_extend testbench ---
    reg [8:0] se_in;
    wire [15:0] se_out;
    sign_extend uut_sign_extend(.in(se_in), .ext(se_out));

    // --- tick_FSM testbench ---
    reg clk, rst, enable;
    wire [3:0] tick;
    tick_FSM uut_tick(.rst(rst), .clk(clk), .enable(enable), .tick(tick));

    // --- multiplexer testbench ---
    reg [15:0] SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G;
    reg [3:0] sel;
    wire [15:0] Bus;
    multiplexer uut_mux(.SignExtDin(SignExtDin), .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7), .G(G), .sel(sel), .Bus(Bus));

    // --- ALU testbench ---
    reg [15:0] alu_a, alu_b;
    reg [2:0] alu_op;
    wire [15:0] alu_result;
    ALU uut_alu(.input_a(alu_a), .input_b(alu_b), .alu_op(alu_op), .result(alu_result));

    // --- register_n testbench ---
    reg [15:0] reg_in;
    reg reg_load, reg_rst, reg_clk;
    wire [15:0] reg_out;
    register_n uut_reg(.data_in(reg_in), .r_in(reg_load), .clk(reg_clk), .Q(reg_out), .rst(reg_rst));

    // --- 8-bit register_n test signals ---
    reg [7:0] reg8_in;
    wire [7:0] reg8_out;
    reg reg8_load, reg8_rst, reg8_clk;
    register_n #(.N(8)) uut_reg8(.data_in(reg8_in), .r_in(reg8_load), .clk(reg8_clk), .Q(reg8_out), .rst(reg8_rst));

    // Use finite loops for clock generation to avoid synthesis/simulation errors
    integer i;
    initial begin
        clk = 0;
        for (i = 0; i < 500; i = i + 1) begin
            #5 clk = ~clk;
        end
    end

    initial begin
        reg_clk = 0;
        for (i = 0; i < 500; i = i + 1) begin
            #7 reg_clk = ~reg_clk;
        end
    end

    initial begin
        reg8_clk = 0;
        for (i = 0; i < 500; i = i + 1) begin
            #11 reg8_clk = ~reg8_clk;
        end
    end

    // sign_extend tests
    initial begin
        $display("==== sign_extend tests ====");
        se_in = 9'b000000101; #1;
        $display("sign_extend +5: %b (should be 0000000000000101)", se_out);
        se_in = 9'b111111011; #1;
        $display("sign_extend -5: %b (should be 1111111111111011)", se_out);
        se_in = 9'b000000000; #1;
        $display("sign_extend 0: %b (should be 0000000000000000)", se_out);
        se_in = 9'b100000000; #1;
        $display("sign_extend -256: %b (should be 1111111110000000)", se_out);
        se_in = 9'b011111111; #1;
        $display("sign_extend +255: %b (should be 0000000011111111)", se_out);
    end

    // tick_FSM tests
    initial begin
        $display("==== tick_FSM tests ====");
        rst = 1; enable = 0; #10;
        $display("After reset, tick = %b (should be 0001)", tick);
        rst = 0; enable = 1; #10;
        repeat (1) @(posedge clk);
        $display("Tick after 1 clock: %b (should be 0010)", tick);
        repeat (1) @(posedge clk);
        $display("Tick after 2 clocks: %b (should be 0100)", tick);
        repeat (1) @(posedge clk);
        $display("Tick after 3 clocks: %b (should be 1000)", tick);
        repeat (1) @(posedge clk);
        $display("Tick after 4 clocks: %b (should wrap to 0001)", tick);
        enable = 0; repeat (2) @(posedge clk);
        $display("Tick with enable low: %b (should remain 0001)", tick);
    end

    // multiplexer tests
    initial begin
        $display("==== multiplexer tests ====");
        SignExtDin = 16'hAAAA; R0 = 16'h0001; R1 = 16'h0002; R2 = 16'h0003;
        R3 = 16'h0004; R4 = 16'h0005; R5 = 16'h0006; R6 = 16'h0007; R7 = 16'h0008; G = 16'hFFFF;
        sel = 4'b0000; #1; $display("MUX sel=0000: Bus=%h (should be AAAA, SignExtDin)", Bus);
        sel = 4'b0001; #1; $display("MUX sel=0001: Bus=%h (should be 0001, R0)", Bus);
        sel = 4'b0010; #1; $display("MUX sel=0010: Bus=%h (should be 0002, R1)", Bus);
        sel = 4'b0011; #1; $display("MUX sel=0011: Bus=%h (should be 0003, R2)", Bus);
        sel = 4'b0100; #1; $display("MUX sel=0100: Bus=%h (should be 0004, R3)", Bus);
        sel = 4'b0101; #1; $display("MUX sel=0101: Bus=%h (should be 0005, R4)", Bus);
        sel = 4'b0110; #1; $display("MUX sel=0110: Bus=%h (should be 0006, R5)", Bus);
        sel = 4'b0111; #1; $display("MUX sel=0111: Bus=%h (should be 0007, R6)", Bus);
        sel = 4'b1000; #1; $display("MUX sel=1000: Bus=%h (should be 0008, R7)", Bus);
        sel = 4'b1001; #1; $display("MUX sel=1001: Bus=%h (should be FFFF, G)", Bus);
        sel = 4'b1010; #1; $display("MUX sel=1010: Bus=%h (should be 0000, invalid select)", Bus);
    end

    // ALU tests
    initial begin
        $display("==== ALU tests ====");
        alu_a = 16'd10; alu_b = 16'd3; alu_op = 3'b000; #1;
        $display("ALU MUL: 10*3 = %d (should be 30)", alu_result);
        alu_op = 3'b001; #1;
        $display("ALU ADD: 10+3 = %d (should be 13)", alu_result);
        alu_op = 3'b010; #1;
        $display("ALU SUB: 10-3 = %d (should be 7)", alu_result);
        alu_op = 3'b011; alu_a = 16'd2; alu_b = 16'b0000_0000_0000_1111; #1;
        $display("ALU SHIFT LEFT: 15<<2 = %b (should be 0000000000111100)", alu_result);
        alu_op = 3'b011; alu_a = -2; alu_b = 16'b0000_0000_0000_1111; #1;
        $display("ALU SHIFT RIGHT: 15>>2 = %b (should be 0000000000000011)", alu_result);
        alu_op = 3'b100; #1;
        $display("ALU don't care: result = %d (should be 0)", alu_result);
    end

    // register_n tests
    initial begin
        $display("==== register_n tests ====");
        reg_rst = 1; reg_load = 0; reg_in = 16'h1234; #10;
        $display("register_n after reset: Q=%h (should be 0000)", reg_out);
        reg_rst = 0; reg_load = 1; #10;
        $display("register_n after load: Q=%h (should be 1234)", reg_out);
        reg_load = 0; reg_in = 16'h5678; #10;
        $display("register_n hold: Q=%h (should still be 1234)", reg_out);
        reg_load = 1; #10;
        $display("register_n load new: Q=%h (should be 5678)", reg_out);
        reg8_rst = 1; reg8_load = 0; reg8_in = 8'hAA; #10;
        $display("8-bit register_n after reset: Q=%h (should be 00)", reg8_out);
        reg8_rst = 0; reg8_load = 1; #10;
        $display("8-bit register_n after load: Q=%h (should be AA)", reg8_out);
        reg8_load = 0; reg8_in = 8'h55; #10;
        $display("8-bit register_n hold: Q=%h (should still be AA)", reg8_out);
        reg8_load = 1; #10;
        $display("8-bit register_n load new: Q=%h (should be 55)",reg8_out);
    end

endmodule