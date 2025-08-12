module sync_fifo_tb #(
    parameter DATA_BITS = 8
)(
    input  wire                 clk_in,           // Clock de entrada
    input  wire                 n_rst,           // Reset ativo em nível baixo
    input  wire                 fifo_empty_in,   // Sinal de FIFO vazio
    input  wire                 fifo_full_in,    // Sinal de FIFO cheio
    input  wire                 uart_rx_valid_in,// Sinal de dado recebido válido (UART RX)
    input  wire                 uart_tx_ready_in,// Sinal de transmissor pronto (UART TX)
    input  wire [DATA_BITS-1:0] uart_rx_data_in, // Dados recebidos do UART RX
    input  wire [DATA_BITS-1:0] fifo_rd_data_in, // Dados lidos do FIFO
    output reg                  fifo_wr_en,      // Habilita escrita no FIFO
    output reg                  fifo_rd_en,      // Habilita leitura no FIFO
    output reg                  uart_tx_en,      // Habilita transmissão UART
    output reg  [DATA_BITS-1:0] fifo_wr_data_out,// Dados para escrita no FIFO
    output reg  [DATA_BITS-1:0] uart_tx_data_out // Dados para transmissão UART
);

    // Máquina de estados
    typedef enum reg [1:0] {
        IDLE,       // Estado ocioso, aguardando comando UART
        WRITE_FIFO, // Escrevendo valores sequenciais no FIFO
        READ_FIFO   // Lendo e transmitindo valores do FIFO via UART
    } state_t;

    state_t state, next_state;
    reg [DATA_BITS-1:0] wr_counter; // Contador para valores sequenciais

    // Registradores para controle de estado
    always_ff @(posedge clk_in or negedge n_rst) begin
        if (!n_rst) begin
            state <= IDLE;
            wr_counter <= 0;
        end else begin
            state <= next_state;
            if (state == WRITE_FIFO && fifo_wr_en && !fifo_full_in)
                wr_counter <= wr_counter + 1; // Incrementa contador na escrita
        end
    end

    // Lógica combinacional da máquina de estados
    always_comb begin
        // Valores padrão
        next_state = state;
        fifo_wr_en = 0;
        fifo_rd_en = 0;
        uart_tx_en = 0;
        fifo_wr_data_out = wr_counter;
        uart_tx_data_out = fifo_rd_data_in;

        case (state)
            IDLE: begin
                if (uart_rx_valid_in) begin
                    if (uart_rx_data_in == "w" && !fifo_full_in) begin
                        next_state = WRITE_FIFO;
                    end else if (uart_rx_data_in == "r" && !fifo_empty_in) begin
                        next_state = READ_FIFO;
                    end
                end
            end

            WRITE_FIFO: begin
                if (!fifo_full_in) begin
                    fifo_wr_en = 1; // Habilita escrita no FIFO
                end else begin
                    next_state = IDLE; // Volta ao IDLE quando FIFO cheio
                end
            end

            READ_FIFO: begin
                if (!fifo_empty_in && uart_tx_ready_in) begin
                    fifo_rd_en = 1; // Habilita leitura do FIFO
                    uart_tx_en = 1; // Habilita transmissão UART
                end else if (fifo_empty_in) begin
                    next_state = IDLE; // Volta ao IDLE quando FIFO vazio
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule