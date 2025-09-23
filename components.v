/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement individual components to be used in 
    the CPU.

Please enter your name and student ID:

*/
module sign_extend(in, ext);
    /* 
     * This module sign extends the 9-bit Din to a 16-bit output.
     */
    input [8:0] in;
    output [15:0] ext;
    
    assign ext = {{7{in[8]}}, in};
endmodule



module tick_FSM(rst, clk, enable, tick);
    /* 
     * This module implements a tick FSM that will be used to
     * control the actions of the control unit
     * One-hot encoding: tick = 4'b0001, 4'b0010, 4'b0100, 4'b1000
     */

    input rst, clk, enable;
    output reg [3:0] tick;

    always @(posedge clk or posedge rst) begin
        if (rst)
            tick <= 4'b0001; // Start at tick 1
        else if (enable) begin
            case (tick)
                4'b0001: tick <= 4'b0010; // Tick 2
                4'b0010: tick <= 4'b0100; // Tick 3
                4'b0100: tick <= 4'b1000; // Tick 4
                4'b1000: tick <= 4'b0001; // Back to Tick 1
                default: tick <= 4'b0001; // Default to Tick 1 on error
            endcase
        end
    end
endmodule

module multiplexer(SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G, sel, Bus);
	/* 
	 * This module takes 10 inputs and places the correct input onto the bus.
	 */
	// TODO: Declare inputs and outputs
	
	// TODO: implement logic


endmodule

module ALU (input_a, input_b, alu_op, result);
    /* 
     * This module implements the arithmetic logic unit of the processor.
     * alu_op:
     * 000: input_a * input_b
     * 001: input_a + input_b
     * 010: input_a - input_b
     * 011: input_b shifted by input_a (signed shift)
     * 100-111: don't care (output 0)
     */
    input [15:0] input_a, input_b;
    input [2:0] alu_op;
    output reg [15:0] result;

    always @(*) begin
        case (alu_op)
            3'b000: result = input_a * input_b; // Multiplication
            3'b001: result = input_a + input_b; // Addition
            3'b010: result = input_a - input_b; // Subtraction
            3'b011: begin // Signed shift
                if (input_a[15] == 1'b0)
                    result = input_b << input_a; // Shift left if input_a is positive
                else
                    result = input_b >>> (~input_a + 1'b1); // Shift right if input_a is negative
            end
            default: result = 16'b0; // Don't care
        endcase
    end



module register_n(data_in, r_in, clk, Q, rst);


	// To set parameter N during instantiation, you can use:
	// register_n #(.N(num_bits)) reg_IR(.....), 
	// where num_bits is how many bits you want to set N to
	// and "..." is your usual input/output signals

	parameter N = 16;

	/* 
	 * This module implements registers that will be used in the processor.
	 */
	// TODO: Declare inputs, outputs, and parameter:
	
	// TODO: Implement register logic:
endmodule

