module top_level (
    input dev_clk,  // Clock da placa (25 MHz)
    input rx,       // Entrada UART RX
    output tx,      // Saída UART TX
    output led_D2   // LED opcional (pode ignorar na simulação)
);

wire clk;  // Clock dividido (153600 Hz)
wire rst, n_rst;

clock_div #(.CLK_IN(25000000), .CLK_OUT(153600)) clkdiv (
    .clk_in(dev_clk),
    .clk_out(clk)
);

initial_rst rstgen (
    .clk_in(clk),
    .rst_out(rst),
    .n_rst_out(n_rst)
);

wire uart_rx_ready, uart_rx_valid;
wire [7:0] uart_rx_data;
uart_rx uart_rx_inst (
    .clk_in(clk), .n_rst(n_rst), .rx(rx),
    .ready_out(uart_rx_ready), .valid_out(uart_rx_valid), .data_out(uart_rx_data)
);

wire uart_tx_ready, uart_tx_en;
wire [7:0] uart_tx_data;
uart_tx uart_tx_inst (
    .clk_in(clk), .n_rst(n_rst), .uart_en(uart_tx_en), .data_in(uart_tx_data),
    .tx(tx), .ready_out(uart_tx_ready)
);

wire fifo_empty, fifo_full, fifo_wr_en, fifo_rd_en;
wire [7:0] fifo_wr_data, fifo_rd_data;
sync_fifo fifo_inst (
    .clk_in(clk), .n_rst(n_rst), .wr_en(fifo_wr_en), .rd_en(fifo_rd_en),
    .wr_data_in(fifo_wr_data), .empty(fifo_empty), .full(fifo_full), .rd_data_out(fifo_rd_data)
);

sync_fifo_tb controller (
    .clk_in(clk), .n_rst(n_rst),
    .fifo_empty_in(fifo_empty), .fifo_full_in(fifo_full),
    .uart_rx_valid_in(uart_rx_valid), .uart_tx_ready_in(uart_tx_ready),
    .uart_rx_data_in(uart_rx_data), .fifo_rd_data_in(fifo_rd_data),
    .fifo_wr_en(fifo_wr_en), .fifo_rd_en(fifo_rd_en),
    .uart_tx_en(uart_tx_en),
    .fifo_wr_data_out(fifo_wr_data), .uart_tx_data_out(uart_tx_data)
);

assign led_D2 = 1'b0;  // LED desligado (opcional)

endmodule
