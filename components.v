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



module tick_FSM(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  [3:0] tick
);

    always @(posedge clk or posedge rst)
        if (rst)
            tick <= 4'b0001;
        else if (enable)
            tick <= {tick[2:0], tick[3]};
endmodule




module multiplexer(SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G, sel, Bus);
    /* 
     * This module takes 10 inputs and places the correct input onto the bus.
     */
    input [15:0] SignExtDin;
    input [15:0] R0, R1, R2, R3, R4, R5, R6, R7, G;
    input [3:0] sel;
    output reg [15:0] Bus;

    always @(*) begin
        case (sel)
            4'b0000: Bus = SignExtDin;
            4'b0001: Bus = R0;
            4'b0010: Bus = R1;
            4'b0011: Bus = R2;
            4'b0100: Bus = R3;
            4'b0101: Bus = R4;
            4'b0110: Bus = R5;
            4'b0111: Bus = R6;
            4'b1000: Bus = R7;
            4'b1001: Bus = G;
            default: Bus = 16'b0;
        endcase
    end
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
                if ($signed(input_a) >= 0)
        			result = $signed(input_b) <<< $signed(input_a);   // left shift
    			else
        			result = $signed(input_b) >>> -$signed(input_a);  // arithmetic right shift
            end
            default: result = 16'b0; // Don't care
        endcase
    end
endmodule


module register_n(data_in, r_in, clk, Q, rst);

    // To set parameter N during instantiation, you can use:
    // register_n #(.N(num_bits)) reg_IR(.....), 
    // where num_bits is how many bits you want to set N to
    // and "..." is your usual input/output signals

    parameter N = 16;

    /* 
     * This module implements registers that will be used in the processor.
     */

    // Declare inputs and outputs
    input clk;
    input rst;
    input r_in;
    input [N-1:0] data_in;
    output reg [N-1:0] Q;

    // Implement register logic
    always @(posedge clk)
		begin
			 if (rst)
				  Q <= {N{1'b0}};
			 else if (r_in)
				  Q <= data_in;
		end

endmodule
