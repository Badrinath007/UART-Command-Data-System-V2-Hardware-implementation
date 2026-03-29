module uart_top_with_fifo #(
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD       = 115200,
    parameter FIFO_DEPTH = 16,
    parameter LOOPBACK   = 1
)(
    input  wire       clk, rst_n,
    input  wire       uart_rx,
    output wire       uart_tx,
    output reg [4:0]  leds,           // 5 LEDs for rich debug info
    output wire       rx_fifo_full, rx_fifo_empty,
    output wire       tx_fifo_full, tx_fifo_empty,
    input  wire       user_rd_en,
    output wire [7:0] user_rx_data,
    input  wire       user_wr_en,
    input  wire [7:0] user_tx_data
	
);

    // Internal Signals
    wire [7:0] rx_data_raw;
    wire       rx_done_tick, tx_done_tick, tick;
    reg        tx_start, fsm_rx_pop;
    wire [7:0] tx_fifo_out;
    wire       framing_err;
    wire       tx_busy;
    wire [$clog2(FIFO_DEPTH):0] rx_data_count, tx_data_count;
    
    // Loopback signal
    wire uart_rx_internal;
	
    
    // FSM States
    localparam ST_IDLE   = 2'd0, ST_CMD = 2'd1, ST_DATA = 2'd2, ST_CHKSUM = 2'd3;
    reg [1:0] p_state;
    reg [7:0] hold_cmd, hold_data, reg_file;
    reg checksum_error;
    
    // The Sync Fix
    reg wait_fifo; 

    // Arbitration Logic
    wire actual_rx_pop = user_rd_en || fsm_rx_pop;

    // ========== LOOPBACK CONNECTION ==========
    assign uart_rx_internal = LOOPBACK ? uart_tx : uart_rx;

    // --- Sub-Modules ---
    baud_gen_fixed #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) baud_gen_inst (
        .clk(clk), .rst_n(rst_n), .tick(tick)
    );

    uart_rx rx_inst (
        .clk(clk), .rst_n(rst_n), .rx(uart_rx_internal), .s_tick(tick),
        .rx_done(rx_done_tick), .rx_data(rx_data_raw),.framing_err(framing_err)
    );

    uart_tx_fixed tx_inst (
        .clk(clk), .rst_n(rst_n), .tx_start(tx_start), .s_tick(tick),
        .tx_data(tx_fifo_out), .tx_done(tx_done_tick), .tx(uart_tx),.tx_busy(tx_busy)
    );

    fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH)) rx_fifo_inst (
        .clk(clk), .rst_n(rst_n),
        .wr_en(rx_done_tick), .wr_data(rx_data_raw),
        .rd_en(actual_rx_pop), .rd_data(user_rx_data),
        .full(rx_fifo_full), .empty(rx_fifo_empty),
        .almost_full(),
        .almost_empty(),
        .data_count(rx_data_count)
    );

    fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH)) tx_fifo_inst (
        .clk(clk), .rst_n(rst_n),
        .wr_en(user_wr_en), .wr_data(user_tx_data),
        .rd_en(tx_done_tick || (!tx_start && !tx_fifo_empty)),
        .rd_data(tx_fifo_out),
        .full(tx_fifo_full), .empty(tx_fifo_empty),
        .almost_full(),
        .almost_empty(),
        .data_count(tx_data_count)
    );

    // TX Startup Logic
    always @(posedge clk) begin
        if (!rst_n) tx_start <= 0;
        else tx_start <= (!tx_fifo_empty && !tx_start);
    end

    // --- THE FIX: WAIT-STATE FSM ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_state    <= ST_IDLE;
            fsm_rx_pop <= 1'b0;
            reg_file   <= 8'h00;
            checksum_error <= 1'b0;
            wait_fifo  <= 1'b0;
            hold_data  <= 8'h0;
            hold_cmd   <= 8'h0;
        end else begin
            fsm_rx_pop <= 1'b0;

            if (wait_fifo) begin
                wait_fifo <= 1'b0;
            end 
            else if (!rx_fifo_empty) begin
                case (p_state)
                    ST_IDLE: begin
                        if (user_rx_data == 8'h55) begin
                            fsm_rx_pop <= 1'b1;
                            wait_fifo  <= 1'b1;
                            p_state    <= ST_CMD;
                        end else begin
                            fsm_rx_pop <= 1'b1;
                            wait_fifo  <= 1'b1;
                        end
                    end

                    ST_CMD: begin
                        hold_cmd   <= user_rx_data;
                        fsm_rx_pop <= 1'b1;
                        wait_fifo  <= 1'b1;
                        p_state    <= ST_DATA;
                    end

                    ST_DATA: begin
                        hold_data  <= user_rx_data;
                        fsm_rx_pop <= 1'b1;
                        wait_fifo  <= 1'b1;
                        p_state    <= ST_CHKSUM;
                    end

                    ST_CHKSUM: begin
                        if (user_rx_data == (hold_cmd + hold_data)) begin
                           if (hold_cmd == 8'h01) begin
										reg_file <= hold_data;  
									end
									checksum_error <= 1'b0;
                        end 
                        else begin
                            checksum_error <= 1'b1;
                        end
                        fsm_rx_pop <= 1'b1;
                        wait_fifo  <= 1'b1;
                        p_state    <= ST_IDLE;
                    end
                endcase
            end
        end
    end

    // ========== RICH DEBUG LED LOGIC ==========
    // PATH 3: Time-multiplexed debug display
    
    reg [25:0] debug_counter;
    reg [2:0]  debug_mode;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debug_counter <= 26'h0;
            debug_mode <= 3'h0;
        end else begin
            debug_counter <= debug_counter + 1'b1;
            
            // Switch debug mode every ~1 second (2^26 clocks)
            if (debug_counter == 26'h0) begin
                debug_mode <= debug_mode + 1'b1;
            end
        end
    end

    // ========== LED MULTIPLEXER ==========
    // Cycle through different debug views every second
    always @(*) begin
        case(debug_mode)
            // Mode 0: Status Flags
            // LED[4]=Heartbeat, LED[3]=TX FIFO has data, LED[2]=RX FIFO has data, LED[1:0]=Error status
            3'd0: begin
                leds[4] = ~debug_counter[25];           // Heartbeat: slow blink
                leds[3] = ~tx_fifo_empty;               // TX FIFO activity
                leds[2] = ~rx_fifo_empty;               // RX FIFO activity
                leds[1] = ~framing_err;                 // Framing error
                leds[0] = ~checksum_error;              // Checksum error
            end
            
            // Mode 1: FSM State (2-bit state on LED[1:0])
            // LED[4]=Heartbeat, LED[3:2]=padding, LED[1:0]=FSM state
            3'd1: begin
                leds[4] = ~debug_counter[25];           // Heartbeat
                leds[3] = 1'b1;                         // Off
                leds[2] = 1'b1;                         // Off
                leds[1] = ~p_state[1];                  // FSM state bit 1
                leds[0] = ~p_state[0];                  // FSM state bit 0
            end
            
            // Mode 2: Activity Counter (5 MSBs of counter)
            // Shows clock divider bits - fast blinking pattern
            3'd2: begin
                leds[4] = ~debug_counter[25];
                leds[3] = ~debug_counter[24];
                leds[2] = ~debug_counter[23];
                leds[1] = ~debug_counter[22];
                leds[0] = ~debug_counter[21];
            end
            
            // Mode 3: FIFO Status
            // LED[4]=Heartbeat, LED[3:0]=FIFO flags (full/empty)
            3'd3: begin
                leds[4] = ~debug_counter[25];           // Heartbeat
                leds[3] = ~tx_fifo_full;                // TX FIFO full
                leds[2] = ~tx_fifo_empty;               // TX FIFO empty
                leds[1] = ~rx_fifo_full;                // RX FIFO full
                leds[0] = ~rx_fifo_empty;               // RX FIFO empty
            end
            
            // Mode 4: RX Activity (pulsing pattern when data arrives)
            3'd4: begin
                leds[4] = ~debug_counter[25];
                leds[3] = ~rx_done_tick;                // RX byte received
                leds[2] = ~tx_done_tick;                // TX byte sent
                leds[1] = ~rx_fifo_empty;               // RX data available
                leds[0] = ~wait_fifo;                   // FSM waiting
            end
            
            // Mode 5: Full Debug View
            // LED[4]=Clock, LED[3]=FSM[1], LED[2]=FSM[0], LED[1]=RX_data, LED[0]=Error
            3'd5: begin
                leds[4] = ~debug_counter[24];
                leds[3] = ~p_state[1];
                leds[2] = ~p_state[0];
                leds[1] = ~rx_fifo_empty;
                leds[0] = ~(checksum_error | framing_err);
            end
            
            // Mode 6: Data Flow Visualization
            // Shows UART activity in real-time
            3'd6: begin
                leds[4] = ~debug_counter[25];           // Heartbeat
                leds[3] = ~rx_done_tick;                // RX receiving
                leds[2] = ~tx_done_tick;                // TX transmitting
                leds[1] = ~(rx_fifo_full | rx_fifo_empty);  // RX FIFO mid-level
                leds[0] = ~(tx_fifo_full | tx_fifo_empty);  // TX FIFO mid-level
            end
            
            // Mode 7: Reserved / All Off
            default: leds = 5'b11111;
        endcase
    end

    // Simulation-only safety checks
    // synthesis translate_off
    always @(posedge clk) begin
        if (rst_n) begin
            if (fsm_rx_pop && rx_fifo_empty) begin
                $display("!!! ASSERTION FAILED: FSM TRIED TO POP EMPTY FIFO at %0t", $time);
                $stop;
            end
            if (tx_start && tx_busy) begin
                $display("!!! ASSERTION FAILED: TX START ISSUED WHILE BUSY at %0t", $time);
                $stop;
            end
        end
    end
    // synthesis translate_on

endmodule