module uart_tx #(
    parameter DATA_BITS = 8,
    parameter STOP_BITS = 1,
    parameter OVERSAMPLING = 16
)(
    input clk_in,
    input n_rst,
    input uart_en,
    input [DATA_BITS-1:0] data_in,
    output tx,
    output ready_out
);

// Declaração dos estados simbólicos
localparam 
    idle  = 2'b00,
    start = 2'b01,
    data  = 2'b10,
    stop  = 2'b11;

// Declaração dos sinais
reg tx_reg = 1'b1;
reg next_tx;
reg ready_reg, next_ready;
reg [DATA_BITS-1:0] data_reg, next_data;
reg [1:0] state, next_state;
reg [$clog2((OVERSAMPLING*2)-1)-1:0] clk_cnt, next_clk;
reg [2:0] bit_cnt, next_bit;

// Registradores da máquina de estados para o transmissor UART
always @(posedge clk_in or negedge n_rst) begin
    if (~n_rst) begin
        state     <= idle;
        tx_reg    <= 1'b1;
        ready_reg <= 1'b0;
        data_reg  <= 0;
        clk_cnt   <= 0;
        bit_cnt   <= 0;
    end else begin
        state     <= next_state;
        tx_reg    <= next_tx;
        ready_reg <= next_ready;
        clk_cnt   <= next_clk;
        bit_cnt   <= next_bit;
        data_reg  <= next_data;
    end
end

// Lógica combinacional da máquina de estados para o transmissor UART
always @(*) begin
    next_state = state;
    next_tx = tx_reg;
    next_ready = ready_reg;
    next_clk = clk_cnt;
    next_bit = bit_cnt;
    next_data = data_reg;

    case (state)
        idle: begin
            next_tx = 1'b1;
            next_ready = 1'b1;
            if (uart_en) begin
                next_data = data_in;
                next_clk = 0;
                next_state = start;
            end
        end

        start: begin
            next_ready = 1'b0;
            next_tx = 1'b0; // bit de start
            if (clk_cnt == OVERSAMPLING - 1) begin
                next_clk = 0;
                next_bit = 0;
                next_state = data;
            end else begin
                next_clk = clk_cnt + 1;
            end
        end

        data: begin
            next_tx = data_reg[0];
            if (clk_cnt == OVERSAMPLING - 1) begin
                next_clk = 0;
                next_data = data_reg >> 1;
                if (bit_cnt == DATA_BITS - 1) begin
                    next_state = stop;
                end else begin
                    next_bit = bit_cnt + 1;
                end
            end else begin
                next_clk = clk_cnt + 1;
            end
        end

        stop: begin
            next_tx = 1'b1; // bit de stop
            if (clk_cnt == (OVERSAMPLING * STOP_BITS) - 1) begin
                next_state = idle;
            end else begin
                next_clk = clk_cnt + 1;
            end
        end
    endcase
end

// Direcionamento dos registradores para as saídas
assign tx = tx_reg;
assign ready_out = ready_reg;

endmodule
