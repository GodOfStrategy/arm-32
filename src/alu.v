module alu(
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,

    input wire [3:0] alu_control,
    input wire carry_in,

    output reg [31:0] result,
    output reg negative,
    output reg zero,
    output reg carry,
    output reg overflow
);
reg [32:0] arithmetic_result;
always @(*) begin 
    //Default
    result=32'b0;
    negative=1'b0;
    zero=1'b0;
    carry=carry_in;
    overflow=1'b0;
    arithmetic_result=33'b0;

    case(alu_control)
        // AND 
        4'b0000:begin
            result=operand_a&operand_b;
        end
        //EOR
        4'b0001:begin
            result=operand_a^operand_b;
        end
        //SUB
        4'b0010:begin
            arithmetic_result=
            {1'b0,operand_a}+
            {1'b0,~operand_b}+33'd1;
            result= arithmetic_result[31:0];
            carry=arithmetic_result[32];
            overflow=
            (operand_a[31]^operand_b[31])&
            (result[31]^operand_a[31]);
        end
        //RSB
        4'b0011:begin
            arithmetic_result=
            {1'b0, operand_b}+
            {1'b0,~operand_a}+33'd1;
            result=arithmetic_result [31:0];
            carry=arithmetic_result[32];
            overflow=
            (operand_b[31]^operand_a[31])&
            (result[31]^operand_b[31]);
        end
        //ADD
        4'b0100:begin
            arithmetic_result=
            {1'b0,operand_a}+
            {1'b0, operand_b};
            result=arithmetic_result[31:0];
            carry=arithmetic_result[32];
            overflow=
            ~(operand_a[31]^operand_b[31])&
            (result[31]^operand_a[31]);
        end
        //ADC
        4'b0101:begin
            arithmetic_result=
            {1'b0,operand_a}+
            {1'b0,operand_b}+
            carry_in;
            result=arithmetic_result[31:0];
            carry=arithmetic_result[32];
            overflow=
            ~(operand_a[31]^operand_b[31])&
            (result[31]^operand_a[31]);
        end
        //SBC
        4'b0110: begin
            arithmetic_result=
            {1'b0,operand_a}+
            {1'b0,~operand_b}+
            carry_in;
            result=arithmetic_result[31:0];
            carry=arithmetic_result[32];
            overflow=
            (operand_a[31]^operand_b[31])&
            (result[31]^operand_a[31]);
        end
        //ROR
        4'b0111:begin
            if(operand_b[4:0]==0) begin
                result=operand_a;
                carry=carry_in;
            end
            else begin
                result=
                (operand_a>>operand_b[4:0])|
                (operand_a<<(32-operand_b[4:0]));

                carry=result[31];
            end
        end
        //TST
        4'b1000:begin
            result=operand_a & operand_b;
        end
        //NEG
        4'b1001:begin
            arithmetic_result=
            {1'b0, ~operand_b}+33'd1;
            result=arithmetic_result[31:0];
            carry=arithmetic_result[32];
            overflow=(operand_b==32'h80000000);
        end
        //CMP
        4'b1010:begin
            arithmetic_result=
            {1'b0,operand_a}+
            {1'b0,~operand_b}+33'd1;
            result=arithmetic_result[31:0];
            carry=arithmetic_result[32];
            overflow=
            (operand_a[31]^operand_b[31])&
            (result[31]^operand_a[31]);
        end//CMN
        4'b1011:begin
            arithmetic_result=
            {1'b0, operand_a}+
            {1'b0, operand_b};
            result=arithmetic_result[31:0];
            carry=arithmetic_result[32];
            overflow=
            ~(operand_a[31]^operand_b[31])&
            (result[31]^operand_a[31]);
        end
        //ORR
        4'b1100:begin
            result=operand_a|operand_b;
        end
        //MUL
        4'b1101:begin
            result=operand_a*operand_b;
        end
        //BIC
        4'b1110:begin
            result=operand_a & ~operand_b;
        end
        //MVN
        4'b1111:begin
            result=~operand_b;
        end
    endcase
    negative=result[31];
    zero=(result==32'b0);
end
endmodule
