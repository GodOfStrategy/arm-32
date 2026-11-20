
module tt_um_godofstrategy_arm32(
    input wire clk,
    input wire rst_n,
    input wire ena,
    input wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe
);

wire rst = ~rst_n;
wire miso;
assign uo_out = {7'b0,miso};
assign uio_out = 8'b0;
assign uio_oe = 8'b0;

wire sram_en, sram_we;
wire [7:0] sram_addr, sram_wdata;
wire [7:0] sram_rdata;

gf180mcu_fd_ip_sram_sram256x8m8wm1 ram0(
    .CLK(clk)
    .CEN(~sram_en),
    .GWEN(~sram_we),
    .WEN(sram_we?8'h00:8'hff),
    .A(sram_addr),
    .D(sram_wdata),
    .Q(sram_rdata),
    .VDD(vdd),
    .VSS(vss)
);

wire cpu_req, cpu_instr, cpu_we, cpu_byte;
wire [31:0] cpu_addr, cpu_wdata, cpu_rdata;
wire cpu_ready, cpu_error;
wire halted, fault;
wire debug_halted, debug_fault;
wire [31:0] debug_pc, debug_reg_rdata;

reg debug_halt_req, debug_step_req;
reg debug_reg_we;
reg [3:0] debug_reg_addr;
reg [31:0] debug_reg_wdata;

core cpu(
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
    .debug_reg_addr(debug_reg_addr),
    .debug_reg_wdata(debug_reg_wdata),
    .debug_reg_rdata(debug_reg_rdata)
);

reg program_mode;
reg loader_we;
reg [6:0] loader_addr;
reg [7:0] loader_data;
wire loader_ready;

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

wire cmd_valid;
wire [7:0] cmd;
wire [31:0] cmd_addr, cmd_data;
reg [7:0] rsp_sts;
reg [31:0] rsp_data;

spi_debug_slave spi(
    .clk(clk),
    .rst(rst),
    .spi_sck(ui_in[0]),
    .spi_mosi(ui_in[1]),
    .spi_cs_n(ui_in[2]),
    .spi_miso(miso),
    .cmd_valid(cmd_valid),
    .cmd(cmd),
    .cmd_addr(cmd_addr),
    .cmd_data(cmd_data),
    .resp_sts(rsp_sts),
    .resp_data(rsp_data)
);

localparam CMD_PROG = 8'h01;
localparam CMD_RUN = 8'h10;
localparam CMD_HALT = 8'h11;
localparam CMD_STEP = 8'h12;
localparam CMD_RREG = 8'h20;
localparam CMD_WREG = 8'h21;
localparam CMD_STATUS = 8'h40;

localparam IDLE = 3'd0;
localparam PROG = 3'd1;
localparam WAIT_PROG = 3'd2;
localparam RREG = 3'd3;
localparam WREG = 3'd4;

reg [2:0] st;

always @(posedge clk) begin
    if (rst) begin
        st <= IDLE;
        debug_halt_req <= 1'b1;
        debug_step_req <= 1'b0;
        debug_reg_we <= 1'b0;
        debug_reg_addr <= 0;
        debug_reg_wdata <= 0;
        program_mode <= 1'b0;
        loader_we <= 1'b0;
        loader_addr <= 0;
        loader_data <= 0;
        rsp_sts <= 0;
        rsp_data <= 0;
    end else begin
        debug_step_req <= 1'b0;
        debug_reg_we <= 1'b0;

        case (st)
            IDLE: begin
                loader_we <= 1'b0;
                if (cmd_valid) begin
                    rsp_sts <= 0;
                    rsp_data <= 0;

                    case (cmd)
                        CMD_PROG: begin
                            if (cmd_addr[31:7] == 0) begin
                                debug_halt_req <= 1'b1;
                                program_mode <= 1'b1;
                                loader_addr <= cmd_addr[6:0];
                                loader_data <= cmd_data[7:0];
                                loader_we <= 1'b1;
                                st <= PROG;
                            end else begin
                                rsp_sts <= 1;
                            end
                        end

                        CMD_RUN: begin
                            program_mode <= 1'b0;
                            debug_halt_req <= 1'b0;
                        end

                        CMD_HALT: debug_halt_req <= 1'b1;

                        CMD_STEP: debug_step_req <= 1'b1;

                        CMD_RREG: begin
                            debug_reg_addr <= cmd_addr[3:0];
                            st <= RREG;
                        end

                        CMD_WREG: begin
                            debug_reg_addr <= cmd_addr[3:0];
                            debug_reg_wdata <= cmd_data;
                            debug_reg_we <= 1'b1;
                            st <= WREG;
                        end

                        CMD_STATUS:
                            rsp_data <= {debug_halted,debug_fault,debug_pc[29:0]};

                        default: rsp_sts <= 1;
                    endcase
                end
            end

            PROG: begin
                loader_we <= 1'b0;
                st <= WAIT_PROG;
            end

            WAIT_PROG: begin
                if (loader_ready)
                    st <= IDLE;
            end

            RREG: begin
                rsp_data <= debug_reg_rdata;
                st <= IDLE;
            end

            WREG: st <= IDLE;

            default: st <= IDLE;
        endcase
    end
end

wire unused = ^{ena,uio_in,halted,fault};

endmodule
