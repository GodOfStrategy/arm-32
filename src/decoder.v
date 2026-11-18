
module decoder(
    input wire [15:0] instr,
    output reg [3:0] rd,
    output reg [3:0] rn,
    output reg [3:0] rm,
    output reg [31:0] imm,
    output reg [3:0] alu_op,
    output reg use_imm,
    output reg reg_we,
    output reg mem_re,
    output reg mem_we,
    output reg mem_byte,
    output reg flag_we,
    output reg branch,
    output reg [3:0] branch_cond,
    output reg valid,
    output reg shift_enable,
    output reg [1:0] shift_type,
    output reg [4:0] shift_amount
);

always @(*) begin
    rd = instr[11:8];
    rn = instr[7:4];
    rm = instr[3:0];

    imm = 32'b0;
    alu_op = 4'b0100;

    use_imm = 1'b0;
    reg_we = 1'b0;
    mem_re = 1'b0;
    mem_we = 1'b0;
    mem_byte = 1'b0;
    flag_we = 1'b0;
    branch = 1'b0;
    branch_cond = 4'b1110;
    valid = 1'b0;

    shift_enable = 1'b0;
    shift_type = 2'b00;
    shift_amount = 5'b0;

    case (instr[15:12])
        // MOV
        4'h0: begin
            imm = {24'b0, instr[7:0]};
            alu_op = 4'h4;
            use_imm = 1'b1;
            reg_we = 1'b1;
            flag_we = 1'b0;
            valid = 1'b1;
        end
        // ADD
        4'h1: begin
            alu_op = 4'h4;
            reg_we = 1'b1;
            flag_we = 1'b1;
            valid = 1'b1;
        end
        // SUB
        4'h2: begin
            alu_op = 4'h2;
            reg_we = 1'b1;
            flag_we = 1'b1;
            valid = 1'b1;
        end
        // AND
        4'h3: begin
            alu_op = 4'h0;
            reg_we = 1'b1;
            flag_we = 1'b1;
            valid = 1'b1;
        end
        // EOR
        4'h4: begin
            alu_op = 4'h1;
            reg_we = 1'b1;
            flag_we = 1'b1;
            valid = 1'b1;
        end
        // ORR
        4'h5: begin
            alu_op = 4'hC;
            reg_we = 1'b1;
            flag_we = 1'b1;
            valid = 1'b1;
        end
        4'h6: begin
            alu_op = 4'hE;
            reg_we = 1'b1;
            flag_we = 1'b1;
            valid = 1'b1;
        end
        4'h7: begin
            alu_op = 4'hF;
            reg_we = 1'b1;
            flag_we = 1'b1;
            valid = 1'b1;
        end
        4'h8: begin
            alu_op = 4'hA;
            flag_we = 1'b1;
            valid = 1'b1;
        end
        4'h9: begin
            imm = {28'b0, instr[3:0], 2'b00};
            alu_op = 4'h4;
            use_imm = 1'b1;
            reg_we = 1'b1;
            mem_re = 1'b1;
            valid = 1'b1;
        end
        4'hA: begin
            imm = {28'b0, instr[3:0], 2'b00};
            alu_op = 4'h4;
            use_imm = 1'b1;
            mem_we = 1'b1;
            valid = 1'b1;
        end
        4'hB: begin
            imm = {28'b0, instr[3:0]};
            alu_op = 4'h4;
            use_imm = 1'b1;
            reg_we = 1'b1;
            mem_re = 1'b1;
            mem_byte = 1'b1;
            valid = 1'b1;
        end
        4'hC: begin
            imm = {28'b0, instr[3:0]};
            alu_op = 4'h4;
            use_imm = 1'b1;
            mem_we = 1'b1;
            mem_byte = 1'b1;
            valid = 1'b1;
        end

        // Unconditional branch
        4'hD: begin
            imm = {{19{instr[11]}}, instr[11:0], 1'b0};
            branch = 1'b1;
            branch_cond = 4'hE;
            valid = 1'b1;
        end
        4'hE: begin
            branch_cond = instr[11:8];
            imm = {{23{instr[7]}}, instr[7:0], 1'b0};
            branch = 1'b1;

            if (instr[11:8] <= 4'hD)
                valid = 1'b1;
        end
        4'hF: begin
            if (instr[0] == 1'b0) begin
                shift_enable = 1'b1;
                shift_type = instr[2:1];
                shift_amount = instr[7:3];
                reg_we = 1'b1;
                flag_we = 1'b1;
                valid = 1'b1;
            end
        end

        default: begin
            valid = 1'b0;
        end

    endcase
end

endmodule
