
module memory_controller(
    input wire clk,
    input wire rst,
    input wire program_mode,

    input wire cpu_req,
    input wire cpu_instr,
    input wire cpu_we,
    input wire cpu_byte,
    input wire [31:0] cpu_addr,
    input wire [31:0] cpu_wdata,

    output reg [31:0] cpu_rdata,
    output wire cpu_ready,
    output wire cpu_error,

    input wire loader_we,
    input wire [6:0] loader_addr,
    input wire [7:0] loader_data,
    output wire loader_ready,

    output reg sram_en,
    output reg sram_we,
    output reg [7:0] sram_addr,
    output reg [7:0] sram_wdata,
    input wire [7:0] sram_rdata
);

localparam IDLE = 3'b000;
localparam READ = 3'b001;
localparam READ_WAIT = 3'b010;
localparam WRITE = 3'b011;
localparam DONE = 3'b100;
localparam ERROR = 3'b101;

reg [2:0] state;
reg active_loader;
reg [7:0] base_addr;
reg [31:0] write_buf;
reg [2:0] byte_index;
reg [2:0] byte_count;

assign cpu_ready =
    ((state == DONE) || (state == ERROR)) && !active_loader;

assign cpu_error = (state == ERROR) && !active_loader;

assign loader_ready = (state == DONE) && active_loader;


// SRAM control
always @(*) begin

    sram_en = 1'b0;
    sram_we = 1'b0;
    sram_addr = 8'b0;
    sram_wdata = 8'b0;

    if (state == READ) begin
        sram_en = 1'b1;
        sram_addr = base_addr + byte_index;
    end

    else if (state == WRITE) begin
        sram_en = 1'b1;
        sram_we = 1'b1;
        sram_addr = base_addr + byte_index;
        sram_wdata = write_buf[byte_index*8 +: 8];
    end

end


// FSM
always @(posedge clk) begin

    if (rst) begin
        state <= IDLE;
        active_loader <= 1'b0;
        base_addr <= 8'b0;
        write_buf <= 32'b0;
        byte_index <= 3'b0;
        byte_count <= 3'b0;
        cpu_rdata <= 32'b0;
    end

    else begin

        case (state)

            IDLE: begin

                if (program_mode && loader_we) begin

                    active_loader <= 1'b1;
                    base_addr <= 8'h80 + {1'b0, loader_addr};
                    write_buf <= {24'b0, loader_data};
                    byte_index <= 3'd0;
                    byte_count <= 3'd1;
                    state <= WRITE;

                end

                else if (!program_mode && cpu_req) begin

                    active_loader <= 1'b0;
                    cpu_rdata <= 32'b0;
                    byte_index <= 3'd0;

                    if (cpu_addr[31:7] != 0) begin
                        state <= ERROR;
                    end

                    else if (cpu_instr) begin

                        if (cpu_we || cpu_addr[0] ||
                            cpu_addr[6:0] > 7'd126) begin
                            state <= ERROR;
                        end

                        else begin
                            base_addr <= 8'h80 + {1'b0, cpu_addr[6:0]};
                            byte_count <= 3'd2;
                            state <= READ;
                        end

                    end

                    else if (!cpu_byte && cpu_addr[6:0] > 7'd124) begin
                        state <= ERROR;
                    end

                    else begin

                        base_addr <= {1'b0, cpu_addr[6:0]};

                        if (cpu_byte)
                            byte_count <= 3'd1;
                        else
                            byte_count <= 3'd4;

                        if (cpu_we) begin
                            write_buf <= cpu_wdata;
                            state <= WRITE;
                        end

                        else begin
                            state <= READ;
                        end

                    end

                end

            end


            READ: begin
                state <= READ_WAIT;
            end


            READ_WAIT: begin

                cpu_rdata[byte_index*8 +: 8] <= sram_rdata;

                if (byte_index == byte_count - 1'b1) begin
                    state <= DONE;
                end

                else begin
                    byte_index <= byte_index + 1'b1;
                    state <= READ;
                end

            end


            WRITE: begin

                if (byte_index == byte_count - 1'b1) begin
                    state <= DONE;
                end

                else begin
                    byte_index <= byte_index + 1'b1;
                end

            end


            DONE: begin
                active_loader <= 1'b0;
                state <= IDLE;
            end


            ERROR: begin
                state <= IDLE;
            end


            default: begin
                state <= IDLE;
            end

        endcase

    end

end

endmodule
