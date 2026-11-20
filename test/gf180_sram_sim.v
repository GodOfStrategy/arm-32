module gf180mcu_ocd_ip_sram__sram256x8m8wm1 (
    inout VDD,
    inout VSS,
    input wire CLK,
    input wire CEN,
    input wire GWEN,
    input wire [7:0] WEN,
    input wire [7:0] A,
    input wire [7:0] D,
    output reg [7:0] Q
);
    reg [7:0] mem [0:255];
    integer i;

    initial begin
        Q = 0;
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 0;
    end

    always @(posedge CLK) begin
        if (!CEN) begin
            if (!GWEN) begin
                if (!WEN[0]) mem[A][0] <= D[0];
                if (!WEN[1]) mem[A][1] <= D[1];
                if (!WEN[2]) mem[A][2] <= D[2];
                if (!WEN[3]) mem[A][3] <= D[3];
                if (!WEN[4]) mem[A][4] <= D[4];
                if (!WEN[5]) mem[A][5] <= D[5];
                if (!WEN[6]) mem[A][6] <= D[6];
                if (!WEN[7]) mem[A][7] <= D[7];
            end else begin
                Q <= mem[A];
            end
        end
    end
endmodule
