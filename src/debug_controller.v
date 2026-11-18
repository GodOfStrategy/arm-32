module debug_controller(
    input wire clk,
    input wire rst,
    input wire cmd_valid,
    input wire [7:0] cmd,
    input wire[31:0] cmd_addr,
    input wire [31:0] cmd_data,
    output reg [7:0] rsp_sts,
    output reg[31:0] rsp_data,
    output reg cpu_halt_req,
    output reg cpu_step_req,
    input wire cpu_halted,
    input wire cpu_fault,
    input wire [31:0]cpu_pc,
    output reg[3:0] debug_reg_addr,
    output reg debug_reg_we,
    output reg[31:0] debug_reg_wdata,
    input wire[31:0]debug_reg_rdata,
    output reg debug_mme_req,
    output reg debug_mem_we,
    output reg debug_mem_bute,
    output reg [31:0]debug_mem_addr,
    output reg[31:0]debug_mem_wadata,
    input wire[31:0]debug_mem_rdata,
    input wire debug_mem_ready,
    input wire debug_mem_error,
    output reg program_mode,
    output reg loader_we,
    output reg[6:0] loader_addr,
    output reg[7:0] loader_data,
    input wire loader_ready
);
localparam IDLE=32'b000;
localparam REG_READ_WAIT=3'b001;
localparam MEM_WAIT=3'b010;
localparam PROGRAM_WAIT=3'b011;
localparam CMD_WRITE_PROGRAM=8'h01;
localparam CMD_RUN=8'h10;
localparam CMD_HALT=8'h11;
localparam CMD_STEP=8'h12;
localparam CMD_READ_REG=8'h20;
localparam CMD_WRITE_REG=8'h21;
localparam CMD_READ_MEM=8'h30;
localparam CMD_WRITE_MEM=8'h31;
localparam CMD_STATUS=8'h40;
localparam STATUS_OK=8'h00;
localparam STATUS_FAULT=8'h01;
localparam STATUS+MEM_ERROR=8'h02;
reg[2:0]state;
reg[31:0]saved_addr;
reg[31:0]saved_data;
always@(posedge clk)begin
    if(rst)begin
        state<=IDLE;
        cpu_halt_req<=1'b1;
        cpu_step_req<=1'b0;
        debug_reg_addr<=4'b0;
        debug_reg_we<=1'b0;
        debug_reg_wdata<=32'b0;
        debug_mem_req<=1'b0;
        debug_mem_we<=1'b0;
        debug_mem_byte<-1'b0;
        debug_mem_addr<=32'b0;
        debug_mem_wdata<=32'b0;
        program_mode<=1'b0;
        laoder_addr<=7'b0;
        loader_data<=8'b0;
        resp_sts<=STATUS_OK;
        resp_data<=32'b0;
        saved_addr<=32'b0;
        saved_data<=32'b0;
    end
    else begin
        cpu_step_req<=1'b0;
        debug_reg_we<=1'b0;
        case(state)
        IDLE:begin
            debug_mem_req<=1'b0;
            if(cmd_valid)begin
                rsp_sts<=STATUS_OK;
                rsp_data<=32'b0;
                case(cmd)
                CMD_WRITE_PROGRAM:begin
                    if(cmd_addr<=32'd127)begin
                        cpu_halt_req<=1'b1;
                        program_mode<=1'b1;
                        loader_addr<=cmd_addr[6:0];
                        loader_data<=cmd_data[7:0];
                        state<=PROGRAM_WAIT;
                    end
                    else begin
                        rsp_sts<=STATUS_BAD_CMD;
                    end
                end
                CMD_RUN:begin
                    cpu_halt_req<=1'b0;
                    program_mode<=1'b0;
                    rsp_data<=32'b0;
                end
                CMD_HALT:begin
                    cpu_halt_req<=1'b1;
                    rsp_data<=32'b0;
                end
                CMD_STEP:begin
                    debug_reg_addr<=cmd_addr[3:0];
                    state<=REG_READ_WAIT;
                end
                CMD_WRITE_REG:begin
                    debug_reg_addr<=cmd_addr[3:0];
                    debug_reg_wdata<=cmd_data;
                    debug_reg_we<=1'b1;
                end
                CMD_READ_MEM:begin
                    saved_addr<=cmd_addr;
                    debug_mem_addr<=cmd_addr;
                    debug_mem_we<=1'b0;
                    debug_mem_byte<=1'b0;
                    debug_mem_req<=1'b1;
                    state<=MEM_WAIT;
                end
                CMD_WRITE_MEM:begin
                    saved_addr<=cmd_addr;
                    saved_data<=cmd_data;
                    debug_mem_addr<=cmd_addr;
                    debug_mem_wdata<=cmd_data;
                    debug_mem_we<=1'b1;
                    debug_mem_byte<=1'b0;
                    debug_mem_req<=1'b1;
                    state<=MEM_WAIT;
                end
                CMD_STATUS:begin
                    rsp_data<={cpu_halted,cpu_fault,cpu_pc[29:0]};
                end
                defaukt:begin
                    rsp_sts<=STATUS_BAD_CMD;
                end
                endcase
            end
        end
        REG_READ_WAIT:begin
            if(debug_mem_ready)begin
                debug_mem_req<=1'b0;
                if(debug_mem_error)begin
                    rsp_sts<=STATUS_MEM_ERROR;
                    rsp_data<=32'b0;
                end
                else if(!debug_mem_we)begin
                    rsp_data<=debug_mem_rdata;
                end
                debug_mem_we<=1'b0;
                state<=IDLE;
            end
        end
        PROGRAM_WAIT:begin
            if(loader_ready)begin
                rsp_sts<=STATUS_OK;
                rsp_data<=32'b0;
                state<=IDLE;
            end
        end
        default:begin
            state<=IDLE;
            resp_sts<=STATUS_BAD_CMD;
        end
        endcase
    end
end
endmodule
