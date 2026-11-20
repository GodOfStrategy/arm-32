module tb_alu;
reg[31:0] operand_a;
reg[31:0] operand_b;
reg[3:0] alu_control;
reg carry_in;
wire[31:0] result;
wire negative;
wire zero;
wire carry;
wire overflow;
integer errors;
alu uut(
    .operand_a(operand_a),
    .operand_b(operand_b),
    .alu_control(alu_control),
    .carry_in(carry_in),
    .result(result),
    .negative(negative),
    .zero(zero),
    .carry(carry),
    .overflow(overflow)
);
//Task
task check;
    input[31:0] expected_result;
    input[3:0] expected_flags;
    begin
        #1;
        if(result!==expected_result||
        {negative,zero,carry,overflow}!==expected_flags) begin
            $display("FAIL: A=%h B=%h OP=%b", operand_a,operand_b,alu_control);
            $display("Expected: result=%h flags=%b", expected_result, expected_flags);
            $display("Actual result=%h flags=%b",result,{negative,zero,carry,overflow});
            errors=errors+1;
        end
        else begin
            $display("PASS: OP%b RESULT=%h", alu_control,result);
        end
    end
endtask
initial begin
    errors=0;
    carry_in=0;
    //ADD 5+3
    operand_a=32'd5;
    operand_b=32'd3;
    alu_control=4'b0100;
    check(32'd8,4'b0000);

    operand_a=32'hFFFFFFFF;
    operand_b=32'd1;
    alu_control=4'b0100;
    check(32'd0,4'b0110);

    //sub
    operand_a=32'd3;
    operand_b=32'd5;
    alu_control=4'b0010;
    check(32'hFFFFFFFE,4'b1000);

    operand_a=32'h7FFFFFFF;
    operand_b=32'd1;
    alu_control=4'b0100;
    check(32'h80000000,4'b1001);
    operand_a=32'hF0;
    operand_b=32'h0F;
    alu_control=4'b1100;
    check(32'hFF,4'b0000);
    operand_a=32'hFF00;
    operand_b=32'h0FF0;
    alu_control=4'b0001;
    check(32'hF0F0,4'b0000);
    operand_a=32'd6;
    operand_b=32'd7;
    alu_control=4'b1101;
    check(32'd42,4'b0000);

    operand_a=32'h80000001;
    operand_b=32'd1;
    alu_control=4'b0111;
    check(32'hC0000000,4'b1010);
    operand_b=32'd5;
    alu_control=4'b1001;
    check(32'hFFFFFFFB,4'b1000);
    //ADC
    operand_a=32'd5;
    operand_b=32'd3;
    carry_in=1;
    alu_control=4'b0101;
    check(32'd9,4'b0000);
    //SBC
    operand_a=32'd5;
    operand_b=32'd3;
    carry_in=1;
    alu_control=4'b0110;
    check(32'd2,4'b0010);
    operand_a=32'd3;
    operand_b=32'd5;
    carry_in=0;
    alu_control=4'b0110;
    check(32'hFFFFFFFD,4'b1000);
    //RSB
    operand_a=32'd5;
    operand_b=32'd3;
    alu_control=4'b0011;
    check(32'hFFFFFFFE,4'b1000);
    //CMN
    operand_a=32'h7FFFFFFF;
    operand_b=32'd1;
    alu_control=4'b1011;
    check(32'h80000000,4'b1001);
    //BIC
    operand_a=32'hF0;
    operand_b=32'h0F;
    alu_control=4'b1110;
    check(32'hF0,4'b0000);
    //MVN
    operand_a=32'd0;
    operand_b=32'd0;
    alu_control=4'b1111;
    check(32'hFFFFFFFF,4'b1000);
    //CMP
    operand_a=32'd5;
    operand_b=32'd5;
    alu_control=4'b1010;
    check(32'd0,4'b0110);
    //TST
    operand_a=32'hF0;
    operand_b=32'h0F;
    alu_control=4'b1000;
    check(32'd0,4'b0100);
    $display("---------------------------------------------------");
    if(errors==0)
        $display("All tests passed");
    else
        $display("Tests failed: %d tests failed", errors);
        $finish;
end
endmodule
