
module tb_decoder;

reg [15:0] instr;

wire [3:0] rd, rn, rm;
wire [31:0] imm;
wire [3:0] alu_op;

wire use_imm, reg_we;
wire mem_re, mem_we, mem_byte;
wire flag_we;
wire branch;
wire [3:0] branch_cond;
wire valid;

integer tests;
integer errors;

decoder dut(
    .instr(instr),
    .rd(rd),
    .rn(rn),
    .rm(rm),
    .imm(imm),
    .alu_op(alu_op),
    .use_imm(use_imm),
    .reg_we(reg_we),
    .mem_re(mem_re),
    .mem_we(mem_we),
    .mem_byte(mem_byte),
    .flag_we(flag_we),
    .branch(branch),
    .branch_cond(branch_cond),
    .valid(valid)
);

task check;
    input [8*40-1:0] name;
    input [3:0] erd, ern, erm;
    input [31:0] eimm;
    input [3:0] ealu;
    input euimm, erwe, emre, emwe, embyte;
    input efwe, ebranch;
    input [3:0] econd;
    input evalid;

    begin
        tests = tests + 1;

        if (
            rd !== erd || rn !== ern || rm !== erm ||
            imm !== eimm || alu_op !== ealu ||
            use_imm !== euimm || reg_we !== erwe ||
            mem_re !== emre || mem_we !== emwe ||
            mem_byte !== embyte || flag_we !== efwe ||
            branch !== ebranch || branch_cond !== econd ||
            valid !== evalid
        ) begin
            errors = errors + 1;
            $display("FAIL: %0s", name);
            $display("rd=%h rn=%h rm=%h imm=%h alu=%h",
                rd, rn, rm, imm, alu_op);
            $display("use_imm=%b reg_we=%b mem_re=%b mem_we=%b",
                use_imm, reg_we, mem_re, mem_we);
            $display("mem_byte=%b flag_we=%b branch=%b cond=%h valid=%b",
                mem_byte, flag_we, branch, branch_cond, valid);
        end
        else begin
            $display("PASS: %0s", name);
        end
    end
endtask

initial begin
    tests = 0;
    errors = 0;
    instr = 16'h0000;

    instr = 16'h0319;
    #1;
    check("MOVS immediate",
        3, 0, 0, 25, 4,
        1, 1, 0, 0, 0, 1, 0, 14, 1);

    instr = 16'h1245;
    #1;
    check("ADDS registers",
        2, 4, 5, 0, 4,
        0, 1, 0, 0, 0, 1, 0, 14, 1);

    instr = 16'h2678;
    #1;
    check("SUBS registers",
        6, 7, 8, 0, 2,
        0, 1, 0, 0, 0, 1, 0, 14, 1);

    instr = 16'h3123;
    #1;
    check("ANDS registers",
        1, 2, 3, 0, 0,
        0, 1, 0, 0, 0, 1, 0, 14, 1);

    instr = 16'h7499;
    #1;
    check("MVNS registers",
        4, 0, 9, 0, 15,
        0, 1, 0, 0, 0, 1, 0, 14, 1);

    instr = 16'h8037;
    #1;
    check("CMP registers",
        0, 3, 7, 0, 10,
        0, 0, 0, 0, 0, 1, 0, 14, 1);

    instr = 16'h9253;
    #1;
    check("LDR word offset",
        2, 5, 0, 12, 4,
        1, 1, 1, 0, 0, 0, 0, 14, 1);

    instr = 16'hA465;
    #1;
    check("STR word offset",
        4, 6, 0, 20, 4,
        1, 0, 0, 1, 0, 0, 0, 14, 1);

    instr = 16'hB127;
    #1;
    check("LDRB byte offset",
        1, 2, 0, 7, 4,
        1, 1, 1, 0, 1, 0, 0, 14, 1);

    instr = 16'hC349;
    #1;
    check("STRB byte offset",
        3, 4, 0, 9, 4,
        1, 0, 0, 1, 1, 0, 0, 14, 1);

    instr = 16'hD005;
    #1;
    check("B positive offset",
        0, 0, 0, 10, 0,
        0, 0, 0, 0, 0, 0, 1, 14, 1);

    instr = 16'hDFFE;
    #1;
    check("B negative offset",
        0, 0, 0, 32'hFFFFFFFC, 0,
        0, 0, 0, 0, 0, 0, 1, 14, 1);

    instr = 16'hE203;
    #1;
    check("BEQ positive offset",
        0, 0, 0, 6, 0,
        0, 0, 0, 0, 0, 0, 1, 2, 1);

    instr = 16'hE1FF;
    #1;
    check("BNE negative offset",
        0, 0, 0, 32'hFFFFFFFE, 0,
        0, 0, 0, 0, 0, 0, 1, 1, 1);

    instr = 16'hEE00;
    #1;
    check("Invalid condition E",
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 14, 0);

    instr = 16'hF000;
    #1;
    check("Reserved opcode",
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 14, 0);

    $display("----------------------------");
    $display("Tests: %0d", tests);
    $display("Errors: %0d", errors);

    if (errors == 0)
        $display("ALL TESTS PASSED!");
    else
        $display("SOME TESTS FAILED!");

    $finish;
end

endmodule
