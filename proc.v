/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement the CPU.

Please enter your student ID:

*/
module simple_proc(
    input clk,
    input rst,
    input [8:0] din,
    output [15:0] bus,
    output [15:0] R0, R1, R2, R3, R4, R5, R6, R7,
    output [3:0] tick // <-- Added tick output for top-level module
);

    // Internal wires and registers
    wire [15:0] sign_ext_din;
    wire [15:0] mux_bus;
    wire [15:0] alu_result;
    wire [3:0] mux_sel;
    wire [2:0] alu_op;
    wire [15:0] reg_G;
    reg r0_en, r1_en, r2_en, r3_en, r4_en, r5_en, r6_en, r7_en;
    reg [15:0] reg_in_data;
    reg [15:0] alu_a, alu_b;
    reg [8:0] IR; // Instruction Register
    reg IR_in;    // IR load enable
    reg A_in;     // Accumulator load enable
    reg G_in;     // G register load enable
    wire [15:0] A_out;
    reg [15:0] A_data;

    // Register instantiations
    register_n #(.N(16)) u_R0(.data_in(reg_in_data), .r_in(r0_en), .clk(clk), .Q(R0), .rst(rst));
    register_n #(.N(16)) u_R1(.data_in(reg_in_data), .r_in(r1_en), .clk(clk), .Q(R1), .rst(rst));
    register_n #(.N(16)) u_R2(.data_in(reg_in_data), .r_in(r2_en), .clk(clk), .Q(R2), .rst(rst));
    register_n #(.N(16)) u_R3(.data_in(reg_in_data), .r_in(r3_en), .clk(clk), .Q(R3), .rst(rst));
    register_n #(.N(16)) u_R4(.data_in(reg_in_data), .r_in(r4_en), .clk(clk), .Q(R4), .rst(rst));
    register_n #(.N(16)) u_R5(.data_in(reg_in_data), .r_in(r5_en), .clk(clk), .Q(R5), .rst(rst));
    register_n #(.N(16)) u_R6(.data_in(reg_in_data), .r_in(r6_en), .clk(clk), .Q(R6), .rst(rst));
    register_n #(.N(16)) u_R7(.data_in(reg_in_data), .r_in(r7_en), .clk(clk), .Q(R7), .rst(rst));

    // Accumulator register
    register_n #(.N(16)) u_A(.data_in(A_data), .r_in(A_in), .clk(clk), .Q(A_out), .rst(rst));

    // G register
    register_n #(.N(16)) u_G(.data_in(alu_result), .r_in(G_in), .clk(clk), .Q(reg_G), .rst(rst));

    // Instruction Register
    always @(posedge clk or posedge rst) begin
        if (rst)
            IR <= 9'b0;
        else if (IR_in)
            IR <= din;
    end

    // Sign extender
    sign_extend u_sign_extend(.in(IR), .ext(sign_ext_din));

    // Multiplexer
    multiplexer u_mux(
        .SignExtDin(sign_ext_din),
        .R0(R0), .R1(R1), .R2(R2), .R3(R3),
        .R4(R4), .R5(R5), .R6(R6), .R7(R7),
        .G(reg_G),
        .sel(mux_sel),
        .Bus(mux_bus)
    );

    // ALU
    ALU u_alu(
        .input_a(alu_a),
        .input_b(alu_b),
        .alu_op(alu_op),
        .result(alu_result)
    );

    // Tick FSM
    tick_FSM u_tick(.rst(rst), .clk(clk), .enable(1'b1), .tick(tick));

    // Control Unit
    always @(*) begin
        // Default: turn off all enables and set default values
        r0_en = 0; r1_en = 0; r2_en = 0; r3_en = 0;
        r4_en = 0; r5_en = 0; r6_en = 0; r7_en = 0;
        IR_in = 0; A_in = 0; G_in = 0;
        mux_sel = 4'b0000;
        alu_op = 3'b100; // Default to don't care
        alu_a = 16'b0;
        alu_b = 16'b0;
        reg_in_data = 16'b0;
        A_data = 16'b0;

        // Decode instruction fields
        // opcode: IR[8:6], dest: IR[5:3], src/immed: IR[2:0] or IR[5:0]
        case (tick)
            4'b0001: begin // Tick 1: Fetch
                IR_in = 1;
            end
            4'b0010: begin // Tick 2: Decode
                case (IR[8:6])
                    3'b000: begin // movi: Move immediate to register
                        mux_sel = 4'b0000; // Select sign_ext_din
                        reg_in_data = mux_bus;
                        case (IR[5:3])
                            3'b000: r0_en = 1;
                            3'b001: r1_en = 1;
                            3'b010: r2_en = 1;
                            3'b011: r3_en = 1;
                            3'b100: r4_en = 1;
                            3'b101: r5_en = 1;
                            3'b110: r6_en = 1;
                            3'b111: r7_en = 1;
                        endcase
                    end
                    3'b001: begin // add: Add two registers
                        mux_sel = {1'b0, IR[2:0]}; // Select source register
                        alu_a = mux_bus; // Source register
                        mux_sel = {1'b0, IR[5:3]}; // Select destination register
                        alu_b = mux_bus; // Destination register
                        alu_op = 3'b001; // ADD
                        A_data = alu_a;
                        A_in = 1;
                    end
                    3'b010: begin // addi: Add immediate to register
                        mux_sel = {1'b0, IR[5:3]}; // Select destination register
                        alu_a = mux_bus;
                        alu_b = sign_ext_din;
                        alu_op = 3'b001; // ADD
                        A_data = alu_a;
                        A_in = 1;
                    end
                    3'b011: begin // sub: Subtract two registers
                        mux_sel = {1'b0, IR[5:3]}; // Select destination register
                        alu_a = mux_bus;
                        mux_sel = {1'b0, IR[2:0]}; // Select source register
                        alu_b = mux_bus;
                        alu_op = 3'b010; // SUB
                        A_data = alu_a;
                        A_in = 1;
                    end
                endcase
            end
            4'b0100: begin // Tick 3: Execute
                G_in = 1;
            end
            4'b1000: begin // Tick 4: Writeback
                mux_sel = 4'b1001; // Select G register
                reg_in_data = mux_bus;
                case (IR[5:3])
                    3'b000: r0_en = 1;
                    3'b001: r1_en = 1;
                    3'b010: r2_en = 1;
                    3'b011: r3_en = 1;
                    3'b100: r4_en = 1;
                    3'b101: r5_en = 1;
                    3'b110: r6_en = 1;
                    3'b111: r7_en = 1;
                endcase
            end
            default: begin
                // Do nothing
            end
        endcase
    end

    assign bus = mux_bus;

endmodule