// -----------------------------------------------------------------------------
// simple_proc.v — Multi-cycle CPU matching datapath diagram
// Implements MOVI, ADD, ADDI, SUB for DE10-Lite
// -----------------------------------------------------------------------------
// This version matches your diagram: ALU operands are latched from the bus,
// and register writeback happens from the bus (G) in T4.

`timescale 1ns/1ps

module simple_proc(
    input clk,
    input rst,
    input [8:0] din,
    output [15:0] bus,
    output [15:0] R0, R1, R2, R3, R4, R5, R6, R7,
    output [3:0] tick
);

    // Opcodes
    localparam OP_MOVI = 3'b000;
    localparam OP_ADD  = 3'b001;
    localparam OP_ADDI = 3'b010;
    localparam OP_SUB  = 3'b011;

    // Mux selects
    localparam SEL_SIGNEXT = 4'd0;
    localparam SEL_G       = 4'd9;

    // Tick states
    localparam T1 = 4'b0001, T2 = 4'b0010, T3 = 4'b0100, T4 = 4'b1000;

    // Internal registers
    reg [8:0] IR;
    reg [3:0] mux_sel;
    reg [15:0] reg_in_data;
    reg [2:0] opcode;
    reg [15:0] alu_a, alu_b;
    wire [15:0] alu_result;
    reg G_in;

    // Register enables
    reg [7:0] r_en;

    // Pipeline registers for ALU operands
    reg [15:0] src_reg_val, dst_reg_val;

    // --- Components ---
    wire [15:0] sign_ext_din;
    sign_extend u_se(.in(IR), .ext(sign_ext_din));

    tick_FSM u_tick(.rst(rst), .clk(clk), .enable(1'b1), .tick(tick));

    reg [2:0] alu_op;
    ALU u_alu(.input_a(alu_a), .input_b(alu_b), .alu_op(alu_op), .result(alu_result));

    wire [15:0] G;
    register_n #(.N(16)) u_G(.data_in(alu_result), .r_in(G_in), .clk(clk), .rst(rst), .Q(G));

    register_n #(.N(16)) u_R0(.data_in(reg_in_data), .r_in(r_en[0]), .clk(clk), .rst(rst), .Q(R0));
    register_n #(.N(16)) u_R1(.data_in(reg_in_data), .r_in(r_en[1]), .clk(clk), .rst(rst), .Q(R1));
    register_n #(.N(16)) u_R2(.data_in(reg_in_data), .r_in(r_en[2]), .clk(clk), .rst(rst), .Q(R2));
    register_n #(.N(16)) u_R3(.data_in(reg_in_data), .r_in(r_en[3]), .clk(clk), .rst(rst), .Q(R3));
    register_n #(.N(16)) u_R4(.data_in(reg_in_data), .r_in(r_en[4]), .clk(clk), .rst(rst), .Q(R4));
    register_n #(.N(16)) u_R5(.data_in(reg_in_data), .r_in(r_en[5]), .clk(clk), .rst(rst), .Q(R5));
    register_n #(.N(16)) u_R6(.data_in(reg_in_data), .r_in(r_en[6]), .clk(clk), .rst(rst), .Q(R6));
    register_n #(.N(16)) u_R7(.data_in(reg_in_data), .r_in(r_en[7]), .clk(clk), .rst(rst), .Q(R7));

    multiplexer u_mux(
        .SignExtDin(sign_ext_din),
        .R0(R0), .R1(R1), .R2(R2), .R3(R3),
        .R4(R4), .R5(R5), .R6(R6), .R7(R7),
        .G(G), .sel(mux_sel), .Bus(bus)
    );

    // --- Control logic ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            IR <= 9'b0;
            opcode <= 3'b0;
            mux_sel <= SEL_SIGNEXT;
            G_in <= 1'b0;
            r_en <= 8'b0;
            src_reg_val <= 16'b0;
            dst_reg_val <= 16'b0;
            alu_a <= 16'b0;
            alu_b <= 16'b0;
            alu_op <= 3'b001;
            reg_in_data <= 16'b0;
        end else begin
            // Default disables
            G_in <= 1'b0;
            r_en <= 8'b0;

            case (tick)
                T1: begin
                    IR <= din;
                    opcode <= din[8:6];
                    mux_sel <= SEL_SIGNEXT;
                end

                T2: begin
                    case (opcode)
                        OP_ADD, OP_SUB: mux_sel <= {1'b0, IR[2:0]};
                        OP_ADDI: mux_sel <= {1'b0, IR[5:3]};
                        OP_MOVI: mux_sel <= SEL_SIGNEXT;
                    endcase
                end

                T3: begin
                    // Latch src_reg_val from bus (source register value)
                    if (opcode == OP_ADD || opcode == OP_SUB)
                        src_reg_val <= bus;
                    else if (opcode == OP_ADDI)
                        dst_reg_val <= bus;

                    // Set mux_sel to destination register for next tick
                    case (opcode)
                        OP_ADD, OP_SUB: mux_sel <= {1'b0, IR[5:3]};
                        OP_ADDI: mux_sel <= SEL_SIGNEXT;
                        OP_MOVI: mux_sel <= SEL_SIGNEXT;
                    endcase

                    // Latch dst_reg_val from bus (destination register value)
                    if (opcode == OP_ADD || opcode == OP_SUB)
                        dst_reg_val <= bus;

                    // Setup ALU operation and operands
                    case (opcode)
                        OP_ADD, OP_ADDI: alu_op <= 3'b001;
                        OP_SUB: alu_op <= 3'b010;
                        default: alu_op <= 3'b001;
                    endcase

                    if (opcode == OP_ADD)
                        begin alu_a <= dst_reg_val; alu_b <= src_reg_val; end
                    else if (opcode == OP_SUB)
                        begin alu_a <= dst_reg_val; alu_b <= src_reg_val; end
                    else if (opcode == OP_ADDI)
                        begin alu_a <= dst_reg_val; alu_b <= sign_ext_din; end

                    G_in <= 1'b1; // Latch ALU result into G
                end

                T4: begin
                    // Writeback: select G onto bus and write to destination register
                    mux_sel <= SEL_G;
                    reg_in_data <= bus;
                    r_en[IR[5:3]] <= 1'b1;
                end
            endcase
        end
    end

    // --- Register selector helper ---
    function [15:0] select_reg;
        input [2:0] idx;
        begin
            case (idx)
                3'b000: select_reg = R0;
                3'b001: select_reg = R1;
                3'b010: select_reg = R2;
                3'b011: select_reg = R3;
                3'b100: select_reg = R4;
                3'b101: select_reg = R5;
                3'b110: select_reg = R6;
                3'b111: select_reg = R7;
                default: select_reg = 16'b0;
            endcase
        end
    endfunction

endmodule