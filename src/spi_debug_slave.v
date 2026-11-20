
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

    reg sck_meta, sck_sync, sck_prev;
    reg cs_meta, cs_sync, cs_prev;
    reg mosi_meta, mosi_sync;

    reg [87:0] rx_shift;
    reg [6:0] bit_count;
    reg [5:0] tx_bit_count;

    wire [47:0] tx_packet;
    wire [87:0] rx_next;

    assign tx_packet = {8'h5A, resp_sts, resp_data};
    assign rx_next = {rx_shift[86:0], mosi_sync};

    assign spi_miso =
        (!cs_sync && tx_bit_count < 6'd48) ?
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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sck_meta <= 0;
            sck_sync <= 0;
            sck_prev <= 0;
            cs_meta <= 1;
            cs_sync <= 1;
            cs_prev <= 1;
            mosi_meta <= 0;
            mosi_sync <= 0;

            rx_shift <= 0;
            bit_count <= 0;
            tx_bit_count <= 0;

            cmd <= 0;
            cmd_addr <= 0;
            cmd_data <= 0;
            cmd_valid <= 0;
        end else begin
            sck_meta <= spi_sck;
            sck_sync <= sck_meta;
            sck_prev <= sck_sync;

            cs_meta <= spi_cs_n;
            cs_sync <= cs_meta;
            cs_prev <= cs_sync;

            mosi_meta <= spi_mosi;
            mosi_sync <= mosi_meta;

            cmd_valid <= 0;

            if (cs_prev && !cs_sync) begin
                rx_shift <= 0;
                bit_count <= 0;
                tx_bit_count <= 0;
            end else if (!cs_sync) begin

                if (!sck_prev && sck_sync) begin
                    if (bit_count < 7'd88) begin
                        rx_shift <= rx_next;
                        bit_count <= bit_count + 1'b1;

                        if (bit_count == 7'd87 &&
                            rx_next[87:80] == 8'hA5 &&
                            packet_checksum(rx_next) == rx_next[7:0]) begin

                            cmd <= rx_next[79:72];
                            cmd_addr <= rx_next[71:40];
                            cmd_data <= rx_next[39:8];
                            cmd_valid <= 1'b1;
                        end
                    end
                end

                if (sck_prev && !sck_sync) begin
                    if (tx_bit_count < 6'd48)
                        tx_bit_count <= tx_bit_count + 1'b1;
                end
            end
        end
    end

endmodule
