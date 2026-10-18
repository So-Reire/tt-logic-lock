// New file

`default_nettype none

module tt_um_so_reire_logic_lock #(
    parameter CLK_HZ = 50000000
) (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    output wire [7:0] uio_oe,
    output wire [7:0] uio_out,
    input  wire clk,
    input  wire rst_n,
    input wire ena,
    input wire [7:0] uio_in
);

    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    localparam LOCKED    = 2'd0;
    localparam UNLOCKED  = 2'd1;
    localparam TIMED_OUT = 2'd2;

    reg [1:0] state;

    wire code   = ~ui_in[2] & ui_in[3] & ui_in[4];  // ui_in[4:2] == 3'b110
    wire relock = ui_in[1];

    localparam OPEN_SECONDS = 2;
    localparam OPEN_CYCLES  = OPEN_SECONDS * CLK_HZ;
    localparam COUNTER_BITS = $clog2(OPEN_CYCLES);
    reg [COUNTER_BITS-1:0] count;

    
    localparam BUZZER_HZ = 1000;                                  
    localparam TONE_HALF = (CLK_HZ / (2*BUZZER_HZ)) < 1 ? 1
                                                       : CLK_HZ / (2*BUZZER_HZ);
    localparam TONE_BITS = $clog2(TONE_HALF + 1);
    reg [TONE_BITS-1:0] tone_cnt;
    reg                 buzzer;

    always @(posedge clk) begin
        if (!rst_n || relock) begin
            state <= LOCKED;
            count <= 0;
        end else begin
            case (state)
                LOCKED: begin
                    if (code) begin
                        state <= UNLOCKED;
                        count <= 0;
                    end
                end
                UNLOCKED: begin
                    if (count == OPEN_CYCLES - 1)
                        state <= TIMED_OUT;
                    else
                        count <= count + 1;
                end
                TIMED_OUT: state <= TIMED_OUT;
                default:   state <= LOCKED;
            endcase
        end
    end

    
    always @(posedge clk) begin
        if (!rst_n || state != UNLOCKED) begin
            tone_cnt <= 0;
            buzzer   <= 1'b0;
        end else if (tone_cnt == TONE_BITS'(TONE_HALF - 1)) begin
            tone_cnt <= 0;
            buzzer   <= ~buzzer;
        end else begin
            tone_cnt <= tone_cnt + 1;
        end
    end

    assign uo_out[0]   = (state == LOCKED) || (state == TIMED_OUT);
    assign uo_out[1]   = (state == UNLOCKED);
    assign uo_out[2]   = buzzer;
    assign uo_out[7:3] = 5'b00000;

wire _unused= &{ena, uio_in};
endmodule
