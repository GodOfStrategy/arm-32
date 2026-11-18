module tt_um_godofstrategy_arm32(
    input wire clk,
    input wire rst_n,
    input wire ena,
    input wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input wire[7:0]uio_in,
    output wire[7:0]uio_out,
    output wire[7:0]uio_oe
);
//ui_in[0]=sck
//ui_in[1]=mosi
//ui_in[2]=cS_n
//uo_out[0]=miso
while rst=~rst_n;
wire spi_miso;
assign uo_out={7'b0,spi_miso};
assign uio_out=8'b0;
assign uio_oe=8'b0;
reg[7:0] ram[0:255];
wire sram_en;
wire[7:0] sram_addr;
wire[7:0]sram_wdata;
wire[7:0]sram_rdata;
always@(*)begin
    sram_rdata=ram[sram_addr];
end
always@(posedge clk)begin
    if(sram_en && sram_we)
    ram[sram_addr]<=sram_wdata;
end
//memorry interface
wire cpu_req;
wire cpu_instr;
wire cpu_we;
wire cpu_byte;
wire cpu_error;
wire halted;
wire fault;
wire debug_halted;
wire debug_fault;
wire[31:0] debug_pc;
reg debug_halt_req;
reg debug_step_req;
reg debug_reg_we;
reg[3:0] debug_reg_addr;
reg[31:0] debug_reg_wdata;
wire[31:0] debug_reg_rdata;
core cpu(
    .clk(clk),
    .rst(rst),
    .cpu_req(cpu_req),
    .cpu_instr(cpu_instr),
    .cpu_we(cpu_we),
    .cpu_byte(cpu_byte),
    .cpu_addr(sram_addr),
    .cpu_wdata(sram_wdata),
    .cpu_rdata(sram_rdata),
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
    .debug_reg_addr(debug_reg_addr),
    .debug_reg_wdata(debug_reg_wdata),
    .debug_reg_rdata(debug_reg_rdata)
);
reg program_mode;
reg loader_we;
reg[6:0] loader_addr;
reg[7:0]loader_data;
wire loadeR_ready;
memory_controller mem(
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
// spi cmd
wire cmd_valid;
wire[7:0]cmd;
wire[31:0]cmd_addr;
wire[31:0]cmd_data;
wire[7:0]rsp_sts;
reg[31:0]rsp_data;
spi_debug_slave spi(
    .clk(clk),
    .rst(rst),
    .spi_sck(ui_in[0]),
    .spi_mosi(ui_in[1]),
    .spi_cs_n(ui_in[2]),
    .spi_miso(spi_miso),
    .cmd_valid(cmd_valid),
    .cmd(cmd),
    .cmd_addr(cmd_addr),
    .cmd_data(cmd_data),
    .resp_sts(rsp_sts),
    .resp_data(rsp_data)
);
localparam CMD_WRITE_PROGRAM=8'h01;
localparam CMD_RUN=8'h10;
localparam CMD_HALT=8'h11;
localparam CMD_STEP=8'h12;
localparam CMD_REd_reg=8'h20;
localparam CMD_WRITE_REG=8'h21;
localparam CMD_STATUS=8'h40;
localparam ST_IDLE=3'd0;
localparam ST_PORG_PULSE=3'd1;
localparam ST_PROG_WAIT=3'd2;
localparam ST_REG_READ=3'd3;
localparam ST_REG_WRITE=3'd4;
reg[2:0] dbg_state;
always@(posedge clk)begin
    if(rst)begin
        dbg_state<=ST_IDLE;
        debug_halt_req<=1'b1;
        debug_step_req<=1'b0;
        debug_reg_we<=1'b0;
        debug_reg_addr<=4'0;
        debug_wdata<=32'b0;
        program_mode<=1'b0;
        loader_we<=4'b0;
        loader_addr<=7'b0;
        loader_data<=8'b0;
        rsp_sts<=8'h00;
        rsp_data<=32'b0;
    end else begin
        debug_step_req<=1'b0;
        debug_reg_we<=1'b0;
        case(dbg_state)
        ST_IDLE:begin
            loader_we<=1'b0;
            if(cmd_valid)begin
                rsp_sts<=8'h00;
                sdp_data<=32'b0;
                case(cmd)
                CMD_WRITE_PROGRAM:begin
                    if(cmd_addr[31:7]==0)begin
                        debug_halt_req<=1'b1;
                        program_mode<=1'b1;
                        loader_addr<=cmd_addr[6:0];
                        loader_data<=cmd_data[7:0];
                        loader_we<=1'b1;
                        dbg_state<=ST_PORG_PULSE;
                    end else begin
                        rsp_sts<=8'h01;
                    end
                end
                CMD_RUN:begin
                    program_mode<=1'b0;
                    debug_halt_req<=1'b0;
                end
                CMD_HALT:begin
                    debug_halt_req<=1'b1;
                end
                CMD_STEP:begin
                    debug_step_req<=1'b1;
                end
                CMD_READ_REG:begin
                    debug_reg_addr<=cmd_addr[3:0];
                    dbg_state<=ST_REG_READ;
                end
                CMD_WRITE_REG:begin
                    debug_reg_addr<=cmd_addr[3:0];
                    debug_reg_wdata<=cmd_data;
                    debug_reg_we<=1'b1;
                    dbg_state<=ST_REG_WRITE;
                end
                CMD_STATUS:begin
                    rsp_data<={debug_halted,debug_fault,debug_pc[29:0]};
                end
                default: begin
                    rsp_sts<=8'h01;
                end
                endcase
            end
        end
        ST_PROG_PULSE:begin
            loader_we<=1'b0;
            dbg_state<=ST_PROG_WAIT;
            END
            sT_PROG_WAIT:begin
                if(loader_ready)begin
                    dbg_state<=ST_IDLE;
                end
            end
            ST_REG_READ:begin
                rsp_data<=debug_reg_rdata;
                dbg_state<=ST_IDLE;
            end
            ST_REG_WRITE:begin
                debug_reg_we<=1'b0;
                dbg_state<=ST_IDLE;
            end
            default:begin
                dbg_state<=ST_IDLE;
            end
        endcase
    end
end
wire_unused=&{ena,uio_in,halted,fault,1'b0};
endmodule


