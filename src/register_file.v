
module register_file(
    input wire clk,
    input wire rst,

    input wire [3:0] read_addr_a,
    input wire [3:0] read_addr_b,
    output wire [31:0] read_data_a,
    output wire [31:0] read_data_b,

    input wire write_enable,
    input wire [3:0] write_addr,
    input wire [31:0] write_data,

    //Debug interface
    input wire debug_we,
    input wire [3:0] debug_addr,
    input wire [31:0] debug_wdata,
    output wire [31:0] debug_rdata
);
reg [31:0] registers[0:15];
integer i;
assign read_data_a=registers[read_addr_a];
assign read_data_b=registers[read_addr_b];
assign debug_rdata=registers[debug_addr];
always @(posedge clk) begin
    if(rst) begin
        for(i=0;i<16;i=i+1)
            registers[i]<=32'b0;
    end
    else if(debug_we) begin
        registers[debug_addr]<=debug_wdata;
    end
    else if(write_enable) begin
        registers[write_addr]<=write_data;
    end
end
endmodule
