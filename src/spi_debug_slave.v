
module spi_debug_slave (
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

    reg [87:0] rx_shift;
    reg [6:0] bit_count;
    reg req_toggle;
    reg req_sync1;
    reg req_sync2;
    reg req_seen;
    reg [5:0] tx_bit_count;
    wire [47:0] tx_packet;
    assign tx_packet = {8'h5A, resp_sts, resp_data};
    assign spi_miso =
        (!spi_cs_n && tx_bit_count < 6'd48) ?
        tx_packet[47-tx_bit_count] : 1'b0;
    function [7:0] packet_checksum;
        input [87:0] packet;
        integer i;
        reg [7:0] value;
        begin
            value = 8'h00;

            for (i = 0; i < 10; i = i + 1)
                value = value ^ packet[87-(i*8) -: 8];

            packet_checksum = value;
        end
    endfunction
    always @(posedge spi_sck or posedge spi_cs_n or posedge rst) begin
        if (rst || spi_cs_n) begin
            rx_shift <= 88'b0;
            bit_count <= 7'b0;
        end else if (bit_count < 7'd88) begin
            rx_shift <= {rx_shift[86:0], spi_mosi};
            bit_count <= bit_count + 1'b1;
        end
    end
 always @(posedge spi_cs_n or posedge rst) begin
        if (rst) begin
            cmd <= 8'b0;
            cmd_addr <= 32'b0;
            cmd_data <= 32'b0;
            req_toggle <= 1'b0;
        end else if (
            bit_count == 7'd88 &&
            rx_shift[87:80] == 8'hA5 &&
            packet_checksum(rx_shift) == rx_shift[7:0]
        ) begin
            cmd <= rx_shift[79:72];
            cmd_addr <= rx_shift[71:40];
            cmd_data <= rx_shift[39:8];

            req_toggle <= ~req_toggle;
        end
    end
always @(posedge clk or posedge rst) begin
        if (rst) begin
            req_sync1 <= 1'b0;
            req_sync2 <= 1'b0;
            req_seen <= 1'b0;
            cmd_valid <= 1'b0;
        end else begin
            req_sync1 <= req_toggle;
            req_sync2 <= req_sync1;

            cmd_valid <= 1'b0;

            if (req_sync2 != req_seen) begin
                req_seen <= req_sync2;
                cmd_valid <= 1'b1;
            end
        end
    end
always @(posedge spi_sck or posedge spi_cs_n or posedge rst) begin
        if (rst || spi_cs_n)
            tx_bit_count <= 6'b0;
        else if (tx_bit_count < 6'd63)
            tx_bit_count <= tx_bit_count + 1'b1;
    end

endmodule
