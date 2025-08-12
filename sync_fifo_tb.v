module sync_fifo_tb #(parameter DATA_BITS=8, ADDRESS_BITS=10)(
    input clk_in, n_rst, fifo_empty_in, fifo_full_in, uart_rx_valid_in, uart_tx_ready_in,
    input [DATA_BITS-1:0] uart_rx_data_in, fifo_rd_data_in,    
    output reg fifo_wr_en, fifo_rd_en, uart_tx_en,
    output reg [DATA_BITS-1:0] fifo_wr_data_out, uart_tx_data_out
);

localparam [1:0] IDLE = 2'b00, FILL = 2'b01, EMPTY = 2'b10;

reg [1:0] state, next_state;
reg [DATA_BITS-1:0] wr_counter, next_wr_counter;

always @(posedge clk_in, negedge n_rst) begin
    if (~n_rst) begin
        state <= IDLE;
        wr_counter <= 0;
    end else begin
        state <= next_state;
        wr_counter <= next_wr_counter;
    end
end

always @(*) begin
    next_state = state;
    next_wr_counter = wr_counter;
    fifo_wr_en = 1'b0;
    fifo_rd_en = 1'b0;
    uart_tx_en = 1'b0;
    fifo_wr_data_out = 0;
    uart_tx_data_out = 0;
    
    case (state)
        IDLE: begin
            if (uart_rx_valid_in) begin
                if (uart_rx_data_in == 8'h77) begin  // "w" em ASCII (0x77)
                    next_state = FILL;
                    next_wr_counter = 0;
                end else if (uart_rx_data_in == 8'h72) begin  // "r" em ASCII (0x72)
                    next_state = EMPTY;
                end
            end
        end
        FILL: begin
            if (~fifo_full_in) begin
                fifo_wr_en = 1'b1;
                fifo_wr_data_out = wr_counter;
                next_wr_counter = wr_counter + 1;  // Incrementa e wrap around automático
            end else begin
                next_state = IDLE;
            end
        end
        EMPTY: begin
            if (~fifo_empty_in && uart_tx_ready_in) begin
                fifo_rd_en = 1'b1;
                uart_tx_en = 1'b1;
                uart_tx_data_out = fifo_rd_data_in;
            end
            if (fifo_empty_in) begin
                next_state = IDLE;
            end
        end
    endcase
end

endmodule
