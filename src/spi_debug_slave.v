
module spi_debug_slave(
    input wire clk,
    input wire rst,
    input wire spi_sck,
    input wire spi_mosi,
    input wire spi_cs_n,
    output wire spi_miso,
    output reg cmd_valid,
    output reg [7:0] cmd,
    output reg [31:0] cmd_addr,
    output reg [31:0] cmd_data,
    input wire [7:0] resp_sts,
    input wire [31:0] resp_data
);

reg [87:0] rx;
reg [6:0] cnt;
reg req;
reg s1, s2, seen;
reg [47:0] tx;
reg [5:0] tc;

assign spi_miso = (!spi_cs_n && tc < 6'd48) ? tx[47-tc] : 1'b0;

function [7:0] csum;
    input [87:0] p;
    integer i;
    reg [7:0] v;
    begin
        v = 0;
        for (i=0; i<10; i=i+1)
            v = v ^ p[87-i*8 -: 8];
        csum = v;
    end
endfunction

//cpi commdans
always @(posedge spi_sck or posedge spi_cs_n or posedge rst) begin
    if (rst || spi_cs_n) begin
        rx <= 0;
        cnt <= 0;
    end else if (cnt < 7'd88) begin
        rx <= {rx[86:0],spi_mosi};
        cnt <= cnt + 1'b1;
    end
end

always @(posedge spi_cs_n or posedge rst) begin
    if (rst) begin
        cmd <= 0;
        cmd_addr <= 0;
        cmd_data <= 0;
        req <= 0;
    end else if (cnt == 7'd88 && rx[87:80] == 8'hA5 && csum(rx) == rx[7:0]) begin
        cmd <= rx[79:72];
        cmd_addr <= rx[71:40];
        cmd_data <= rx[39:8];
        req <= ~req;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        s1 <= 0;
        s2 <= 0;
        seen <= 0;
        cmd_valid <= 0;
    end else begin
        s1 <= req;
        s2 <= s1;
        cmd_valid <= 0;
        if (s2 != seen) begin
            seen <= s2;
            cmd_valid <= 1;
        end
    end
end

always @(negedge spi_cs_n or posedge rst) begin
    if (rst)
        tx <= 0;
    else
        tx <= {8'h5A,resp_sts,resp_data};
end

always @(posedge spi_sck or posedge spi_cs_n or posedge rst) begin
    if (rst || spi_cs_n)
        tc <= 0;
    else if (tc < 6'd48)
        tc <= tc + 1'b1;
end

endmodule
