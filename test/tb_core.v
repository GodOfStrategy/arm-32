`timescale 1ns/1ps
module tb_core;
reg clk;
reg rst;
reg program_mode;
wire cpu_req;
wire cpu_instr;
wire cpu_we;
wire cpu_byte;
wire[31:0] cpu_addr;
wire[31:0] cpu_wdata;
wire[31:0]cpu_rdata;
wire cpu_ready;
wire cpu_error;
wire halted;
wire fault;
reg debug_halt_req;
reg debug_step_req;
wire debug_halted;
wire[31:0] debug_pc;
wire debug_fault;
reg debug_reg_we;
reg[31:0]debug_reg_wdata;
wire [31:0] debug_reg_rdata;
reg loader_we;
reg[6:0] loader_addr;
reg[7:0]loader_data;
wire loader_ready;
wire sram_en;;
wire sram_we;
wire [7:0] sram_wdata;
wire[7:0 ] sram_addr;
reg [3:0] debug_reg_addr;
reg [7:0] sram_rdata;
reg[7:0]sram_mem[0:255];
integer errors;
integer i;
core dut(
    .clk(clk),
    .rst(rst),
    .cpu_req(cpu_req),
    .cpu_instr(cpu_instr),
    .cpu_we(cpu_we),
    .cpu_byte(cpu_byte),
    .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata),
    .cpu_rdata(cpu_rdata),
    .cpu_ready(cpu_ready),
    .cpu_error(cpu_error),
    .halted(halted),
    .fault(fault),
    .debug_halt_req(debug_halt_req),
    .debug_step_req(debug_step_req),
    .debug_halted(debug_halted),
    .debug_pc(debug_pc),
    .debug_fault(debug_fault),
    .debug_reg_we(debug_reg_we),
    .debug_reg_wdata(debug_reg_wdata),
    .debug_reg_rdata(debug_reg_rdata),
    .debug_reg_addr(debug_reg_addr)
);
memory_controller mem_ctrl(
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
    .sram_wdata(sram_wdata),
    .sram_addr(sram_addr),
    .sram_rdata(sram_rdata)

);
//clock\
initial begin
    clk=0;
    forever #5 clk=~clk;
end
//snyc ram
always@(posedge clk) begin
    if(sram_en)begin
        if(sram_we)
        sram_mem[sram_addr]<=sram_wdata;
        else
        sram_rdata<=sram_mem[sram_addr];
    end
end
// rst cpu
task reset_system;
begin
    program_mode=1'b1;
    loader_we=1'b0;
    debug_halt_req=1'b1;
    debug_step_req=1'b0;
    debug_reg_we=1'b0;
    debug_reg_addr=4'b0;
    debug_reg_wdata=32'b0;
    rst=1'b1;
    repeat(4)@(posedge clk);
    @(negedge clk);
    rst=1'b0;
    repeat(2)@(posedge clk);
    @(negedge clk);
    if(!debug_halted)
    $display("ERROr: CPU failed to enter DEBUG_HALT");
    else
    $display("PASS: CPU entered DEBUG_HALT");
end
endtask
//use real porgram laoder
task loader_write_byte;
input[6:0] addr;
input[7:0] data;
begin
    @(negedge clk);
    loader_addr=addr;
    loader_data=data;
    loader_we=1'b1;
    @(negedge clk);
    loader_we=1'b0;
    wait(loader_ready==1'b1);
    @(negedge clk);
    wait(loader_ready==1'b0);
end
endtask
//load  a 16 bit instr
task load_instr;
input[6:0] addr;
input[15:0] instr;
begin
    loader_write_byte(addr,instr[7:0]);
    loader_write_byte(addr+1'b1,instr[15:8]);
end
endtask
//step once and halt cpu
task step_cpu;
begin
    @(negedge clk);
    debug_step_req=1'b1;
    @(negedge clk);
    debug_step_req=1'b0;
    wait(debug_halted==1'b0);
    wait(debug_halted==1'b1);
    @(negedge clk);
end
endtask
// step once with no ahlt
task pulse_step;
begin
    @(negedge clk);
    debug_step_req=1'b1;
    @(negedge clk);
    debug_step_req=1'b0;
end
endtask
// wrtie to a register suing the debugger
task debug_write;
input[3:0] addr;
input[31:0] data;
begin
    @(negedge clk);
    debug_reg_addr=addr;
    debug_reg_wdata=data;
    debug_reg_we=1'b1;
    @(negedge clk);
    debug_reg_we=1'b0;
    @(negedge clk);
end
endtask
//check register
task check_reg;
input[3:0] addr;
input[31:0] expected;
input[8*40-1:0] label;
begin
    debug_reg_addr=addr;
    #1;
    if(debug_reg_rdata!=expected)begin
        $display("FAIL: %0s Expected=%h Actual=%h",label,expected,debug_reg_rdata);
        errors=errors+1;
    end
    else begin
        $display("PASS: %0s Expected=%h Actual=%h",label,expected,debug_reg_rdata);
    end
end
endtask
//check pc
task check_pc;
input[31:0] expected;
begin
    #1;
    if(debug_pc!=expected)begin
        $display("FAIL: PC Expected=%h Actual=%h",expected,debug_pc);
        errors=errors+1;
    end
    else begin
        $display("PASS: PC Expected=%h Actual=%h",expected,debug_pc);
    end
end
endtask
//check sram
task check_sram;
input[7:0] addr;
input[7:0] expected;
begin
    if(sram_mem[addr]!=expected)begin
        $display("FAIL: SRAM[%h] Expected=%h Actual=%h",addr,expected,sram_mem[addr]);
        errors=errors+1;
    end
    else begin
        $display("PASS: SRAM[%h] Expected=%h Actual=%h",addr,expected,sram_mem[addr]);
    end
end
endtask
initial begin
    errors=0;
    rst=1'b1;
    program_mode=1'b1;
    debug_halt_req=1'b1;
    debug_step_req=1'b0;
    debug_reg_we=1'b0;
    debug_reg_addr=4'b0;
    loader_we=1'b0;
    debug_reg_wdata=32'b0;
    loader_addr=7'b0;
    loader_data=8'b0;
    sram_rdata=8'b0;
    for(i=0;i<256;i=i+1)
        sram_mem[i]=8'b0;
    $dumpfile("tb_core.vcd");
    $dumpvars(0,tb_core);
    $display("");
    $display("===============================");
    $display("Debug Test");
    $display("===============================");
    reset_system();
    $display("DEBUG DIAGNOSTICS");
    $display("rst          = %b", rst);
    $display("debug_halt_req = %b", debug_halt_req);
    $display("debug_halted = %b", debug_halted);
    $display("CPU state    = %b", dut.state);
    $display("step_active  = %b", dut.step_active);
    $display("PC           = %h", debug_pc);
        if(debug_halted)
        $display("PASS: CPU is halted for debug");
    else begin
        $display("FAIL: CPU is not halted for debug");
        errors=errors+1;
    end

    debug_write(4'd0,32'h12345678);
check_reg(4'd0,32'h12345678,"Debug write");
debug_write(4'd0,32'h00000000);
check_reg(4'd0,32'h00000000,"Debug reg clear");
$display("");
$display("===============================");
$display("Load and Run Test");
$display("===============================");
load_instr(7'd0,16'h010A);//mov R1,#10
load_instr(7'd2,16'h0203);//mov R2,#3
load_instr(7'd4,16'h8012);//CMP r1 r2
load_instr(7'd6,16'hE102);// bne +4
load_instr(7'd8,16'h03EE); //skip
load_instr(7'd10,16'h03DD);//skpiied
load_instr(7'd12,16'h03CC);//skipped
load_instr(7'd14,16'h0355);//mov r3 #55
load_instr(7'd16,16'hE002);//beq +4 (not taken)
load_instr(7'd18,16'h0444);//mov r4 #44
load_instr(7'd20,16'hE202);//bcs +4
load_instr(7'd22,16'h0555);//skip
load_instr(7'd24,16'h0566);//skipped
load_instr(7'd26,16'h0577); //skip
load_instr(7'd28,16'h0101);//mov r1 #1
load_instr(7'd30,16'h0201); //mov r2 #1
load_instr(7'd32,16'hF1F8);//lsl r1 #31
load_instr(7'd34,16'h8012);//cmp r1 r2
load_instr(7'd36,16'hE602);//bvs +4
load_instr(7'd38,16'h03EE);//skipped
load_instr(7'd40,16'h03DD);//skipped
load_instr(7'd42,16'h03CC);//skipped
load_instr(7'd44,16'h0101);// mov r1 #1
load_instr(7'd46,16'h0202);//mov r2 #2
load_instr(7'd48,16'h8012);//cmp r1 r2
load_instr(7'd50,16'hE402); //bmi +4
load_instr(7'd52,16'h03EE);//skipped
load_instr(7'd54,16'h03DD);//skipped
load_instr(7'd56,16'h03CC);//skipped
load_instr(7'd58,16'h010A);  // mov r1 #10
load_instr(7'd60,16'h0203);  // mov r2 #3
load_instr(7'd62,16'h1312);  // add r3 r1 r2
    load_instr(7'd64,16'h2412);  // sub r4 r1 r2
    load_instr(7'd66,16'h3512);  // AND r5 r1 r2
    load_instr(7'd68,16'h4612);  //EOR r6 r1 r2
    load_instr(7'd70,16'h5712);  // ORR R7,R1,R2
    load_instr(7'd72,16'h6812);  // BIC R8,R1,R2
    load_instr(7'd74,16'h7912);  // MVN R9,R2

    load_instr(7'd76,16'hF110);  // LSL R1,#2
    load_instr(7'd78,16'hF20A);  // LSR R2,#1
    load_instr(7'd80,16'hF90C);  // ASR R9,#1
    load_instr(7'd82,16'hF30E);  // ROR R3,#1

    load_instr(7'd84,16'h0A20);  // MOV R10,#32
    load_instr(7'd86,16'h0B5A);  // MOV R11,#90
    load_instr(7'd88,16'hABA0);  // STR R11,[R10]
    load_instr(7'd90,16'h9CA0);  // LDR R12,[R10]

    load_instr(7'd92,16'h0BA5);  // MOV R11,#165
    load_instr(7'd94,16'hCBA1);  // STRB R11,[R10,#1]
    load_instr(7'd96,16'hBDA1);  // LDRB R13,[R10,#1]

    load_instr(7'd98,16'hD000);  // B +0
    load_instr(7'd100,16'h0E11); // Skipped
    load_instr(7'd102,16'h0E77); // MOV R14,#119

    load_instr(7'd104,16'h1EF0); // ADD R14,R15,R0
load_instr(7'd106,16'hF001); // Invalid instr
program_mode=1'b0;
$display("PASS:main prog loaded");
$display("");
$display("================================");
$display("cpu instr test");
$display("================================");
step_cpu(); check_reg(4'd1,32'd10,"MOV R1");
    step_cpu(); check_reg(4'd2,32'd3,"MOV R2");
    step_cpu(); check_pc(32'd6);

    step_cpu(); check_pc(32'd14);  // BNE taken
    step_cpu(); check_reg(4'd3,32'd85,"MOV R3");
    step_cpu(); check_pc(32'd18);  // BEQ not taken
    step_cpu(); check_reg(4'd4,32'd68,"MOV R4");
    step_cpu(); check_pc(32'd28);  // BCS taken

    // Overflow flag and V condition
    step_cpu(); check_reg(4'd1,32'd1,"MOV R1");
    step_cpu(); check_reg(4'd2,32'd1,"MOV R2");
    step_cpu(); check_reg(4'd1,32'h80000000,"LSL R1,#31");
    step_cpu(); check_pc(32'd36);  // CMP
    step_cpu(); check_pc(32'd44);  // BVS taken

    // Negative flag and MI condition
    step_cpu(); check_reg(4'd1,32'd1,"MOV R1");
    step_cpu(); check_reg(4'd2,32'd2,"MOV R2");
    step_cpu(); check_pc(32'd50);  // CMP
    step_cpu(); check_pc(32'd58);  // BMI taken

    // Arithmetic and logical operations
    step_cpu(); check_reg(4'd1,32'd10,"MOV R1");
    step_cpu(); check_reg(4'd2,32'd3,"MOV R2");

    step_cpu(); check_reg(4'd3,32'd13,"ADD");
    step_cpu(); check_reg(4'd4,32'd7,"SUB");
    step_cpu(); check_reg(4'd5,32'd2,"AND");
    step_cpu(); check_reg(4'd6,32'd9,"EOR");
    step_cpu(); check_reg(4'd7,32'd11,"ORR");
    step_cpu(); check_reg(4'd8,32'd8,"BIC");
    step_cpu(); check_reg(4'd9,32'hFFFFFFFC,"MVN");

    // Barrel shifter
    step_cpu(); check_reg(4'd1,32'd40,"LSL");
    step_cpu(); check_reg(4'd2,32'd1,"LSR");
    step_cpu(); check_reg(4'd9,32'hFFFFFFFE,"ASR");
    step_cpu(); check_reg(4'd3,32'h80000006,"ROR");

    // Memory operations
    step_cpu(); check_reg(4'd10,32'd32,"MOV R10");
    step_cpu(); check_reg(4'd11,32'd90,"MOV R11");

    step_cpu(); check_sram(8'd32,8'h5A);  // STR
    step_cpu(); check_reg(4'd12,32'd90,"LDR");

    step_cpu(); check_reg(4'd11,32'd165,"MOV R11");
    step_cpu(); check_sram(8'd33,8'hA5);  // STRB
    step_cpu(); check_reg(4'd13,32'd165,"LDRB");

    // Unconditional branch
    step_cpu(); check_pc(32'd102);
    step_cpu(); check_reg(4'd14,32'd119,"MOV R14");

    // R15 read test
    step_cpu(); check_reg(4'd14,32'd106,"R15 read");

    // Invalid instr must fault
    pulse_step();
    wait(halted==1'b1);

    if(fault && debug_fault)
        $display("PASS: Invalid instr causes CPU fault");
    else begin
        $display("FAIL: Invalid instr fault");
        errors=errors+1;
    end

    if(debug_pc==32'd108)
        $display("PASS: PC after invalid instr");
    else begin
        $display("FAIL: PC after invalid instr: %h",debug_pc);
        errors=errors+1;
    end

    check_sram(8'd32,8'h5A);
    check_sram(8'd33,8'hA5);
    check_sram(8'd34,8'h00);
    check_sram(8'd35,8'h00);
    $display("");
    $display("========================================");
    $display("MEMORY BOUNDARY TEST");
    $display("========================================");

    reset_system();

    load_instr(7'd0,16'h0A7F);  // MOV R10,#127
    load_instr(7'd2,16'h0BA5);  // MOV R11,#165
    load_instr(7'd4,16'hCBA0);  // STRB R11,[R10]
    load_instr(7'd6,16'hBCA0);  // LDRB R12,[R10]
    load_instr(7'd8,16'h017D);  // MOV R1,#125
    load_instr(7'd10,16'h9210); // LDR R2,[R1]

    program_mode=1'b0;

    step_cpu(); check_reg(4'd10,32'd127,"Boundary address");
    step_cpu(); check_reg(4'd11,32'd165,"Boundary byte value");
    step_cpu(); check_sram(8'd127,8'hA5);
    step_cpu(); check_reg(4'd12,32'd165,"Boundary byte read");
    step_cpu(); check_reg(4'd1,32'd125,"Invalid word address");
    pulse_step();
    wait(halted==1'b1);
    if(fault && debug_fault)
        $display("PASS: Out-of-bounds word access detected");
    else begin
        $display("FAIL: Out-of-bounds word access");
        errors=errors+1;
    end
    $display("");
    $display("========================================");
    if(errors==0)
        $display("ALL CPU TESTS PASSED");
    else
        $display("CPU TESTS FAILED: %0d errors",errors);

    $display("========================================");
    $dumpvars(0, tb_core);
    $dumpfile("dump.vcd");
    $finish;
end
//timeout
initial  begin
    #20000;
    $display("ERROR: Simulation timeout");
    $display("CPU: state=%b",dut.state);
    $display("PC=%h",debug_pc);
    $display("Reset=%b",rst);
    $finish;
end
endmodule