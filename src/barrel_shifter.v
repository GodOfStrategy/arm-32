module barrel_shifter(
    input wire [31:0] din,
    input wire [4:0]sh_amt,
    input wire[1:0] sh_type,
    input wire cin,
    output reg[31:0] dout,
    output reg cout
);
always @(*) begin
    dout=din;
    cout=cin;
    case(sh_type)
    //LSL
    2'b00:begin
    if(sh_amt==0)begin
        dout=din;
        cout=cin;
    end
    else begin
        dout=din<<sh_amt;
        cout=din[32-sh_amt];
    end
end

//LSR
2'b01:begin
    if(sh_amt==0)begin
        dout=din;
        cout=cin;
    end
    else begin
        dout=din>>sh_amt;
        cout=din[sh_amt-1];
    end
end
//ASRR
2'b10:begin
    if(sh_amt==0)begin
        dout=din;
        cout=cin;
    end
    else begin
        dout=$signed(din)>>>sh_amt;
        cout=din[sh_amt-1];
    end
end
//ROR
2'b11:begin
    if(sh_amt==0) begin
        dout=din;
        cout=cin;
    end
    else begin
        dout=(din>>sh_amt)|
        (din<<(32-sh_amt));
        cout=dout[31];
    end
end
endcase
end
endmodule
