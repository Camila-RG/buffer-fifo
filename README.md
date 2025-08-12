# Projeto FIFO com UART

Este projeto implementa um buffer FIFO síncrono integrado com módulos UART para comunicação serial, conforme especificado na aula de 29/07 e 05/08. O sistema preenche o FIFO com valores sequenciais ao receber "w" via UART e esvazia o FIFO transmitindo os dados via UART ao receber "r". O projeto foi desenvolvido para a placa FPGA Colorlight com clock de 25 MHz.

## Estrutura do Projeto
- **Arquivos**:
  - `sync_fifo.v`: Módulo do buffer FIFO síncrono (8 bits, profundidade 1024).
  - `clock_div.v`: Divisor de clock (25 MHz para 153600 Hz, compatível com 9600 baud).
  - `initial_rst.v`: Gerador de reset inicial.
  - `uart_rx.v`: Receptor UART (8N1, 9600 baud, oversampling 16).
  - `uart_tx.v`: Transmissor UART (8N1, 9600 baud, oversampling 16).
  - `sync_fifo_tb.v`: Módulo de teste que gerencia o FIFO com comandos "w" (escrever) e "r" (ler).
  - `top_level.v`: Módulo top-level que conecta todos os componentes.
  - `colorlight.xdc`: Arquivo de constraints para pinos da placa Colorlight (clock, UART, LED).


## Licença
Este projeto é para fins educacionais, baseado nas especificações da aula de 29/07.

