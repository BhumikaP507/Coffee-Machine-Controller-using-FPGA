module coffee_machine (
    input  wire       clk,             // Onboard 100 MHz system clock
    input  wire       rst,             // Master reset button
    input  wire       btn_select,      // Select coffee button
    input  wire       btn_add_money,   // Add $1 button
    input  wire       btn_refill,      // Refill cup stock button
    output reg  [3:0] an,              // 7-segment display anodes
    output reg  [6:0] seg,             // 7-segment display cathodes
    output reg        led_dispense     // Dispensing LED indicator (LD0)
);

    // FSM State Encoding
    localparam IDLE     = 2'b00;
    localparam PAYMENT  = 2'b01;
    localparam DISPENSE = 2'b10;
    localparam EMPTY    = 2'b11;

    reg [1:0] current_state, next_state;

    // Hardware Registers & Counters
    reg [1:0]  cups;           // Stock tracking (3, 2, 1, 0 remaining cups)
    reg [2:0]  money;          // Balance tracking up to 5 units
    reg [28:0] timer_7s;       // 7-second brewing delay timer (700,000,000 clock cycles @ 100MHz)
    reg [24:0] blink_timer;    // ~3 Hz LED pulse timer
    reg [19:0] clk_div;        // Clock divider for display multiplexing & debouncing

    // Button Debounce Sampling Logic for Money Input
    reg btn_add_reg1, btn_add_reg2;
    wire btn_add_pulse;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_add_reg1 <= 1'b0;
            btn_add_reg2 <= 1'b0;
        end else if (clk_div[16] == 1'b1) begin // Debounce sampling clock
            btn_add_reg1 <= btn_add_money;
            btn_add_reg2 <= btn_add_reg1;
        end
    end
    assign btn_add_pulse = btn_add_reg1 & ~btn_add_reg2;

    // Clock Divider Counter
    always @(posedge clk or posedge rst) begin
        if (rst)
            clk_div <= 20'd0;
        else
            clk_div <= clk_div + 1'b1;
    end

    // 1. FSM Sequential State Register
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // 2. Datapath Execution Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cups         <= 2'd3;
            money        <= 3'd0;
            timer_7s     <= 29'd0;
            blink_timer  <= 25'd0;
            led_dispense <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    money        <= 3'd0;
                    timer_7s     <= 29'd0;
                    led_dispense <= 1'b0;
                    if (btn_refill)
                        cups <= 2'd3;
                end

                PAYMENT: begin
                    if (btn_add_pulse && money < 3'd5)
                        money <= money + 1'b1;
                end

                DISPENSE: begin
                    blink_timer <= blink_timer + 1'b1;
                    if (blink_timer == 25'd16_666_666) begin // ~3 Hz LED toggle
                        led_dispense <= ~led_dispense;
                        blink_timer  <= 25'd0;
                    end

                    if (timer_7s < 29'd700_000_000) begin // 7-second dispense delay
                        timer_7s <= timer_7s + 1'b1;
                    end else begin
                        timer_7s     <= 29'd0;
                        led_dispense <= 1'b0;
                        if (cups > 2'd0)
                            cups <= cups - 1'b1;
                    end
                end

                EMPTY: begin
                    led_dispense <= 1'b0;
                    if (btn_refill)
                        cups <= 2'd3;
                end
            endcase
        end
    end

    // 3. FSM Next-State Logic
    always @(*) begin
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (cups == 2'd0)
                    next_state = EMPTY;
                else if (btn_select)
                    next_state = PAYMENT;
            end

            PAYMENT: begin
                if (money >= 3'd5)
                    next_state = DISPENSE;
            end

            DISPENSE: begin
                if (timer_7s >= 29'd700_000_000) begin
                    if (cups - 1'b1 == 2'd0)
                        next_state = EMPTY;
                    else
                        next_state = IDLE;
                end
            end

            EMPTY: begin
                if (btn_refill)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // 4. Multiplexed 7-Segment Display Output Logic
    always @(posedge clk) begin
        case (clk_div[19:18])
            2'b00: begin
                an <= 4'b0111; // Digit 1
                case (current_state)
                    IDLE:    seg <= 7'b1000110; // 'C'
                    default: seg <= 7'b1111111; // OFF
                endcase
            end
            2'b01: begin
                an <= 4'b1011; // Digit 2
                case (current_state)
                    IDLE:    seg <= 7'b1000001; // 'U'
                    default: seg <= 7'b1111111; // OFF
                endcase
            end
            2'b10: begin
                an <= 4'b1101; // Digit 3
                case (current_state)
                    IDLE:    seg <= 7'b0001100; // 'P'
                    default: seg <= 7'b1111111; // OFF
                endcase
            end
            2'b11: begin
                an <= 4'b1110; // Digit 4 (Rightmost)
                case (current_state)
                    IDLE: begin
                        case (cups)
                            2'd3: seg <= 7'b0000001; // '3'
                            2'd2: seg <= 7'b0010010; // '2'
                            2'd1: seg <= 7'b1001111; // '1'
                            default: seg <= 7'b0000001;
                        endcase
                    end
                    PAYMENT:  seg <= 7'b0001100; // 'P'
                    DISPENSE: seg <= 7'b1000010; // 'd'
                    EMPTY:    seg <= 7'b0110000; // 'E'
                    default:  seg <= 7'b1111111;
                endcase
            end
        endcase
    end

endmodule
