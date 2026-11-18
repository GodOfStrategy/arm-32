
module core(
    input wire clk,
    input wire rst,
    output reg cpu_req,
    output reg cpu_instr,
    output reg cpu_we,
    output reg cpu_byte,
    output reg [31:0] cpu_addr,
    output reg [31:0] cpu_wdata,
    input wire [31:0] cpu_rdata,
    input wire cpu_ready,
    input wire cpu_error,
    output wire halted,
    output reg fault,
    input wire debug_halt_req,
    input wire debug_step_req,
    output wire debug_halted,
    output wire [31:0] debug_pc,
    output wire debug_fault,
    input wire debug_reg_we,
    input wire [3:0] debug_reg_addr,
    input wire [31:0] debug_reg_wdata,
    output wire [31:0] debug_reg_rdata
);
localparam FETCH_REQ=3'b000;
localparam FETCH_WAIT=3'b001;
localparam EXECUTE=3'b010;
localparam MEM_REQ=3'b011;
localparam MEM_WAIT=3'b100;
localparam DEBUG_HALT=3'b110;
localparam HALT=3'b101;
reg step_active;
reg[2:0] state;
reg[31:0] pc;
reg[31:0] instr_pc;
reg[15:0] instr;
reg[31:0] mem_addr;
reg[31:0] mem_wdata;
reg[3:0] mem_rd;
reg mem_byte_reg;
reg mem_write;
reg mem_load;
reg flag_n;
reg flag_z;
reg flag_c;
reg flag_v;
wire[3:0] rd;
wire[3:0] rn;
wire[3:0] rm;
wire[31:0] imm;
wire[3:0] alu_op;
wire use_imm;
wire reg_we;
wire mem_re;
wire mem_we;
wire mem_byte;
wire flag_we;
wire branch;
wire[3:0] branch_cond;
wire valid;
wire shift_enable;
wire[1:0] shift_type;
wire[4:0] shift_amount;
wire[3:0] read_addr_a;
wire[3:0] read_addr_b;
wire[31:0] read_data_a;
wire[31:0] read_data_b;
wire[31:0] operand_a;
wire[31:0] operand_b;
wire[31:0] alu_result;
wire alu_n;
wire alu_z;
wire alu_c;
wire alu_v;
wire[31:0] shift_result;
wire shift_carry;
wire[31:0] addr_result;
wire condition_result;
reg rf_write_enable;
reg[3:0] rf_write_addr;
reg[31:0] rf_write_data;
assign halted=(state==HALT);
assign debug_halted=(state==DEBUG_HALT);
assign debug_pc=pc;
assign debug_fault=fault;
//Decode
decoder dec(
    .instr(instr),
    .rd(rd),
    .rn(rn),
    .rm(rm),
    .imm(imm),
    .alu_op(alu_op),
    .use_imm(use_imm),
    .reg_we(reg_we),
    .mem_re(mem_re),
    .mem_we(mem_we),
    .mem_byte(mem_byte),
    .flag_we(flag_we),
    .branch(branch),
    .branch_cond(branch_cond),
    .valid(valid),
    .shift_enable(shift_enable),
    .shift_type(shift_type),
    .shift_amount(shift_amount)
);

//read addr
assign read_addr_a=(instr[15:12]==4'h0) ? 4'd0 : (shift_enable) ? rd:rn;
assign read_addr_b=(mem_we) ? rd:rm;
//file register
register_file rf(
    .clk(clk),
    .rst(rst),
    .read_addr_a(read_addr_a),
    .read_addr_b(read_addr_b),
    .read_data_a(read_data_a),
    .read_data_b(read_data_b),
    .write_enable(rf_write_enable),
    .write_addr(rf_write_addr),
    .write_data(rf_write_data),
    .debug_we(debug_reg_we && debug_halted),
    .debug_addr(debug_reg_addr),
    .debug_wdata(debug_reg_wdata),
    .debug_rdata(debug_reg_rdata)
);
//R15
assign operand_a=(read_addr_a==4'd15) ? instr_pc+32'd2 : ((instr[15:12]==4'h0) ? 32'b0:read_data_a);
assign operand_b=use_imm ? imm:((read_addr_b==4'd15) ? instr_pc+32'd2:read_data_b);
assign addr_result=operand_a+operand_b;
//alu
alu alu_unit(
    .operand_a(operand_a),
    .operand_b(operand_b),
    .alu_control(alu_op),
    .carry_in(flag_c),
    .result(alu_result),
    .negative(alu_n),
    .zero(alu_z),
    .carry(alu_c),
    .overflow(alu_v)
);
//shifter
barrel_shifter shifter(
    .din(read_data_a),
    .sh_amt(shift_amount),
    .sh_type(shift_type),
    .cin(flag_c),
    .dout(shift_result),
    .cout(shift_carry)
);
//wreit control
always @(*) begin
    rf_write_enable=1'b0;
    rf_write_addr=4'b0;
    rf_write_data=32'b0;
    if(state==EXECUTE && reg_we && !mem_re && !mem_we && !branch && rd!=4'd15) begin
        rf_write_enable=1'b1;
        rf_write_addr=rd;
        if(shift_enable)
            rf_write_data=shift_result;
        else
            rf_write_data=alu_result;
    end
    else if(state==MEM_WAIT && mem_load && cpu_ready && !cpu_error && mem_rd!=4'd15) begin
        rf_write_enable=1'b1;
        rf_write_addr=mem_rd;
        rf_write_data=cpu_rdata;
    end
end
//bracnch chek
function condition_pass;
input[3:0] cond;
begin
    case(cond)
        4'h0:condition_pass=flag_z;
        4'h1:condition_pass=!flag_z;
        4'h2:condition_pass=flag_c;
        4'h3:condition_pass=!flag_c;
        4'h4:condition_pass=flag_n;
        4'h5:condition_pass=!flag_n;
        4'h6:condition_pass=flag_v;
        4'h7:condition_pass=!flag_v;
        4'h8:condition_pass=flag_c && !flag_z;
        4'h9:condition_pass=!flag_c || flag_z;
        4'hA:condition_pass=flag_n==flag_v;
        4'hB:condition_pass=flag_n!=flag_v;
        4'hC:condition_pass=!flag_z && (flag_n==flag_v);
        4'hD:condition_pass=flag_z || (flag_n!=flag_v);
        4'hE:condition_pass=1'b1;
        default:condition_pass=1'b0;
    endcase
end
endfunction
assign condition_result=condition_pass(branch_cond);
//controller
always@(*)begin
    cpu_req=1'b0;
    cpu_instr=1'b0;
    cpu_we=1'b0;
    cpu_byte=1'b0;
    cpu_addr=32'b0;
    cpu_wdata=32'b0;
    case(state)
    FETCH_REQ,FETCH_WAIT:begin
        cpu_req=1'b1;
        cpu_instr=1'b1;
        cpu_addr=pc;
    end
    MEM_REQ,MEM_WAIT:begin
        cpu_req=1'b1;
        cpu_instr=1'b0;
        cpu_we=mem_write;
        cpu_byte=mem_byte_reg;
        cpu_addr=mem_addr;
        cpu_wdata=mem_wdata;
    end
    default:begin
    end
    endcase
end
//FSM
always@(posedge clk)begin
    if(rst)begin
        state<=FETCH_REQ;
        pc<=32'b0;
        step_active<=0;
        instr_pc<=32'b0;
        instr<=16'b0;
        mem_addr<=32'b0;
        mem_wdata<=32'b0;
        mem_rd<=4'b0;
        mem_byte_reg<=1'b0;
        mem_write<=1'b0;
        mem_load<=1'b0;
        flag_n<=1'b0;
        flag_z<=1'b0;
        flag_c<=1'b0;
        flag_v<=1'b0;
        fault<=1'b0;
    end
    else begin
        case(state)
                DEBUG_HALT:begin
            if(debug_step_req)begin
                step_active<=1'b1;
                state<=FETCH_REQ;
            end
            else if(!debug_halt_req)begin
                step_active<=1'b0;
                state<=FETCH_REQ;
            end
        end
        FETCH_REQ:begin
            if(debug_halt_req && !step_active)begin
                state<=DEBUG_HALT;
            end
            else begin
                instr_pc<=pc;
                state<=FETCH_WAIT;
            end
        end
        FETCH_WAIT:begin
            if(cpu_ready)begin
                if(cpu_error)begin
                    fault<=1'b1;
                    state<=HALT;
                end
                else begin
                    instr<=cpu_rdata[15:0];
                    pc<=pc+32'd2;
                    state<=EXECUTE;
                end
            end
        end
        EXECUTE:begin
            if(!valid)begin
                fault<=1'b1;
                state<=HALT;
            end
            else if(branch)begin
                if(condition_result)
                    pc<=instr_pc+32'd4+imm;
                if(step_active)begin
                    step_active<=1'b0;
                    state<=DEBUG_HALT;
                end
                else if(debug_halt_req)begin
                    state<=DEBUG_HALT;
                end
                else begin
                    state<=FETCH_REQ;
                end
            end
            else if(mem_re || mem_we)begin
                mem_addr<=addr_result;
                mem_wdata<=read_data_b;
                mem_rd<=rd;
                mem_byte_reg<=mem_byte;
                mem_write<=mem_we;
                mem_load<=mem_re;
                state<=MEM_REQ;
            end
            else begin
                if(flag_we)begin
                    if(shift_enable)begin
                        flag_n<=shift_result[31];
                        flag_z<=(shift_result==32'b0);
                        flag_c<=shift_carry;
                    end
                    else begin
                        flag_n<=alu_n;
                        flag_z<=alu_z;
                        flag_c<=alu_c;
                        flag_v<=alu_v;
                    end
                end
                if(reg_we && rd==4'd15)
                    pc<=shift_enable ? shift_result:alu_result;
                                if(step_active)begin
                    step_active<=1'b0;
                    state<=DEBUG_HALT;
                end
                else if(debug_halt_req)begin
                    state<=DEBUG_HALT;
                end
                else begin
                    state<=FETCH_REQ;
                end
            end
        end
        MEM_REQ:begin
            state<=MEM_WAIT;
        end
        MEM_WAIT:begin
            if(cpu_ready)begin
                if(cpu_error)begin
                    fault<=1'b1;
                    state<=HALT;
                end
                else begin
                    if(mem_load && mem_rd==4'd15)
                        pc<=cpu_rdata;
                                        if(step_active)begin
                        step_active<=1'b0;
                        state<=DEBUG_HALT;
                    end
                    else if(debug_halt_req)begin
                        state<=DEBUG_HALT;
                    end
                    else begin
                        state<=FETCH_REQ;
                    end
                end
            end
        end
        HALT:begin
            state<=HALT;
        end
        default:begin
            fault<=1'b1;
            state<=HALT;
        end
    endcase
    end
end
endmodule
