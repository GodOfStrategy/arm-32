
`timescale 1ns/1ps

module tb_memory_controller;

reg clk;
reg rst;
reg program_mode;
reg cpu_req;
reg cpu_instr;
reg cpu_we;
reg cpu_byte;
reg [31:0] cpu_addr;
reg [31:0] cpu_wdata;
wire [31:0] cpu_rdata;
wire cpu_ready;
wire cpu_error;

reg loader_we;
reg [6:0] loader_addr;
reg [7:0] loader_data;
wire loader_ready;

wire sram_en;
wire sram_we;
wire [7:0] sram_addr;
wire [7:0] sram_wdata;
reg [7:0] sram_rdata;

reg [7:0] mem [0:255];

integer i;
integer errors;

memory_controller uut(
    .clk(clk),
    .rst(rst),
    .program_mode(program_mode),
    .cpu_req(cpu_req),
    .cpu_instr(cpu_instr),
    .cpu_we(cpu_we),
    .cpu_byte(cpu_byte),
    .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata),
    .cpu_rdata(cpu_rdata),
    .cpu_ready(cpu_ready),
    .cpu_error(cpu_error),
    .loader_we(loader_we),
    .loader_addr(loader_addr),
    .loader_data(loader_data),
    .loader_ready(loader_ready),
    .sram_en(sram_en),
    .sram_we(sram_we),
    .sram_addr(sram_addr),
    .sram_wdata(sram_wdata),
    .sram_rdata(sram_rdata)
);

always #5 clk = ~clk;

// Synchronous SRAM
always @(posedge clk) begin
    if (sram_en) begin
        if (sram_we)
            mem[sram_addr] <= sram_wdata;
        else
            sram_rdata <= mem[sram_addr];
    end
end

task check;
input condition;
input [255:0] test_name;
begin
    if (condition) begin
        $display("PASS: %0s", test_name);
    end
    else begin
        $display("FAIL: %0s", test_name);
        errors = errors + 1;
    end
end
endtask

task loader_write;
input [6:0] addr;
input [7:0] data;
begin
    @(negedge clk);
    program_mode = 1'b1;
    loader_we = 1'b1;
    loader_addr = addr;
    loader_data = data;

    while (!loader_ready)
        @(negedge clk);

    loader_we = 1'b0;
end
endtask

task cpu_access;
input instr;
input we;
input byte_access;
input [31:0] addr;
input [31:0] data;
begin
    @(negedge clk);
    program_mode = 1'b0;
    cpu_req = 1'b1;
    cpu_instr = instr;
    cpu_we = we;
    cpu_byte = byte_access;
    cpu_addr = addr;
    cpu_wdata = data;

    while (!cpu_ready)
        @(negedge clk);

    cpu_req = 1'b0;
end
endtask

initial begin
    clk = 0;
    rst = 1;
    program_mode = 0;

    cpu_req = 0;
    cpu_instr = 0;
    cpu_we = 0;
    cpu_byte = 0;
    cpu_addr = 0;
    cpu_wdata = 0;

    loader_we = 0;
    loader_addr = 0;
    loader_data = 0;

    sram_rdata = 0;
    errors = 0;

    for (i = 0; i < 256; i = i + 1)
        mem[i] = 0;

    repeat (3) @(posedge clk);
    @(negedge clk);
    rst = 0;

    // TEST1
    loader_write(7'd0, 8'h34);
    check(mem[8'h80] == 8'h34, "Writes first bite");

    loader_write(7'd1, 8'h12);
    check(mem[8'h81] == 8'h12, "Writes second byte");

    // TEST2
    cpu_access(0, 1, 0, 32'd0, 32'h12345678);
    check(
        mem[0] == 8'h78 &&
        mem[1] == 8'h56 &&
        mem[2] == 8'h34 &&
        mem[3] == 8'h12,
        "Writes 32 bit word"
    );

    // TEST3
    cpu_access(0, 0, 0, 32'd0, 32'd0);
    check(cpu_rdata == 32'h12345678, "Reads 32 bits");

    // TEST4
    cpu_access(0, 1, 1, 32'd4, 32'h000000AB);
    check(mem[4] == 8'hAB, "Writes 8 bits");

    // TEST5
    cpu_access(0, 0, 1, 32'd4, 32'd0);
    check(cpu_rdata == 32'h000000AB, "Reads 8 bits");

    // TEST6
    cpu_access(1, 0, 0, 32'd0, 32'd0);
    check(cpu_rdata[15:0] == 16'h1234, "16 bit fetch");

    // TEST7
    loader_write(7'd2, 8'hCD);
    loader_write(7'd3, 8'hAB);
    cpu_access(1, 0, 0, 32'd2, 32'd0);
    check(cpu_rdata[15:0] == 16'hABCD, "Second fecth");

    // TEST8
    cpu_access(0, 0, 0, 32'd125, 32'd0);
    check(cpu_error, "Error on out of bounds read");

    // TEST9
    cpu_access(1, 0, 0, 32'd127, 32'd0);
    check(cpu_error, "Error invalid instrcutions");

    // TEST10
    cpu_access(0, 1, 1, 32'd127, 32'h000000EF);
    check(mem[127] == 8'hEF, "Writes last byte");

    if (errors == 0)
        $display("\nAll tests passed");
    else
        $display("\n%0d tests failed", errors);
    $finish;
end
endmodule
