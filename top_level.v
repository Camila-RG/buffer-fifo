module top_level (
    input  wire       dev_clk, // Clock de 25 MHz (da placa)
    input  wire       rx,      // Entrada UART RX
    output wire       tx,      // Saída UART TX
    output wire       led_D2   // LED para debug (opcional)
);

    wire clk_out, rst_out, n_rst_out;
    wire fifo_empty, fifo_full, fifo_wr_en, fifo_rd_en;
    wire [7:0] fifo_wr_data, fifo_rd_data;
    wire uart_rx_valid, uart_tx_ready, uart_tx_en;
    wire [7:0] uart_rx_data, uart_tx_data;

    // Divisor de clock (ajustado para 25 MHz da placa)
    clock_div #(
        .CLK_IN(25000000),  // Clock da placa (25 MHz)
        .CLK_OUT(153600)    // Para 9600 baud com oversampling 16
    ) clk_div_inst (
        .clk_in(dev_clk),
        .clk_out(clk_out)
    );

    // Reset inicial
    initial_rst rst_inst (
        .clk_in(dev_clk),
        .rst_out(rst_out),
        .n_rst_out(n_rst_out)
    );

    // FIFO síncrono
    sync_fifo #(
        .DATA_BITS(8),
        .ADDRESS_BITS(10)
    ) fifo_inst (
        .clk_in(dev_clk),
        .n_rst(n_rst_out),
        .wr_en(fifo_wr_en),
        .rd_en(fifo_rd_en),
        .wr_data_in(fifo_wr_data),
        .empty(fifo_empty),
        .full(fifo_full),
        .rd_data_out(fifo_rd_data)
    );

    // Receptor UART (usa clock dividido)
    uart_rx #(
        .DATA_BITS(8),
        .STOP_BITS(1),
        .OVERSAMPLING(16)
    ) uart_rx_inst (
        .clk_in(clk_out),
        .n_rst(n_rst_out),
        .rx(rx),
        .ready_out(/* não usado */),
        .valid_out(uart_rx_valid),
        .data_out(uart_rx_data)
    );

    // Transmissor UART (usa clock dividido)
    uart_tx #(
        .DATA_BITS(8),
        .STOP_BITS(1),
        .OVERSAMPLING(16)
    ) uart_tx_inst (
        .clk_in(clk_out),
        .n_rst(n_rst_out),
        .uart_en(uart_tx_en),
        .data_in(uart_tx_data),
        .tx(tx),
        .ready_out(uart_tx_ready)
    );

    // Módulo de teste (testbench)
    sync_fifo_tb #(
        .DATA_BITS(8)
    ) tb_inst (
        .clk_in(dev_clk),
        .n_rst(n_rst_out),
        .fifo_empty_in(fifo_empty),
        .fifo_full_in(fifo_full),
        .uart_rx_valid_in(uart_rx_valid),
        .uart_tx_ready_in(uart_tx_ready),
        .uart_rx_data_in(uart_rx_data),
        .fifo_rd_data_in(fifo_rd_data),
        .fifo_wr_en(fifo_wr_en),
        .fifo_rd_en(fifo_rd_en),
        .uart_tx_en(uart_tx_en),
        .fifo_wr_data_out(fifo_wr_data),
        .uart_tx_data_out(uart_tx_data)
    );

    // LED para debug (pisca quando há escrita/leitura no FIFO)
    reg led_reg = 0;
    always_ff @(posedge dev_clk or negedge n_rst_out) begin
        if (!n_rst_out) led_reg <= 0;
        else if (fifo_wr_en || fifo_rd_en) led_reg <= ~led_reg;
    end
    assign led_D2 = led_reg;

endmodule