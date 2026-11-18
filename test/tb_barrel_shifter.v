module tb_barrel_shifter;
reg[31:0] din;
reg[4:0] sh_amt;
reg[1:0] sh_type;
reg cin;
wire[31:0] dout;
wire cout;
integer errors;
barrel_shifter uut(
    .din(din),
    .sh_amt(sh_amt),
    .sh_type(sh_type),
    .cin(cin),
    .dout(dout),
    .cout(cout)
);
//Task to check the shifter
task check;
input[31:0] exp_d;
input exp_c;
begin
    #1;
    if(dout!==exp_d||cout!==exp_c)begin
        $display("FAIL:TYPE=%b DIN=%h AMT=%d",sh_type,din,sh_amt);
        $display("Expected:DOUT=%h COUT=%b",exp_d,exp_c);
        $display("Actual:DOUT=%h COUT=%b",dout,cout);
        errors=errors+1;
    end
    else begin
        $display("PASS: TYPE=%b DOUT=%h COUT=%b",sh_type,dout,cout);
    end
end
endtask
initial begin
    errors=0;
    cin=0;
    //LSL
    din=32'h00000001;
    sh_amt=1;
    sh_type=2'b00;
    check(32'h00000002,0);
    din=32'h80000000;
    sh_amt=1;
    sh_type=2'b00;
    check(32'h00000000,1);
    din=32'h00000008;
    sh_amt=1;
    sh_type=2'b01;
    check(32'h00000004,0);
    din = 32'h00000003;
    sh_amt = 1;
    sh_type = 2'b01;
    check(32'h00000001, 1);
    din = 32'h80000000;
    sh_amt = 1;
    sh_type = 2'b10;
    check(32'hC0000000, 0);
    din = 32'h40000000;
    sh_amt = 1;
    sh_type = 2'b10;
    check(32'h20000000, 0);
    din = 32'h80000001;
    sh_amt = 1;
    sh_type = 2'b11;
    check(32'hC0000000, 1);
    din = 32'h12345678;
    sh_amt = 4;
    sh_type = 2'b11;
    check(32'h81234567, 1);
    din = 32'h12345678;
    sh_amt = 0;
    sh_type = 2'b00;
    cin = 1;
    check(32'h12345678, 1);
    din = 32'h00000001;
    sh_amt = 31;
    sh_type = 2'b00;
    cin = 0;
    check(32'h80000000, 0);
    din = 32'h80000000;
    sh_amt = 31;
    sh_type = 2'b01;
    check(32'h00000001, 0);
    $display("--------------------------------");

    if(errors == 0)
        $display("ALL TESTS PASSED!");
    else
        $display("TESTS FAILED: %d errors", errors);

    $finish;

end
endmodule