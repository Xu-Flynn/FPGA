module led_marquee (
    input wire clk_p,       // 差分时钟正端
    input wire clk_n,       // 差分时钟负端
    input wire rst_n,       // 复位信号，低电平有效
    output reg [3:0] leds   // 4个LED灯
);

    // 差分时钟缓冲器
    wire clk;
    IBUFDS #(
        .DIFF_TERM("TRUE"),  // 差分终端
        .IBUF_LOW_PWR("TRUE") // 低功耗模式
    ) clk_ibufds (
        .O(clk),             // 输出时钟
        .I(clk_p),           // 差分时钟正端
        .IB(clk_n)           // 差分时钟负端
    );

    // 200MHz时钟，每个周期5ns
    // 0.25秒 = 250,000,000 ns
    // 250,000,000 ns / 5 ns = 50,000,000 个时钟周期
    localparam COUNT_MAX = 50_000_000;
    reg [31:0] count;  // 32位计数器

    // 复位和计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;  // 复位计数器
            leds <= 4'b0000; // 复位LED灯
        end else begin
            if (count == COUNT_MAX - 1) begin
                count <= 32'd0;  // 计数器归零
                leds <= {leds[2:0], leds[3]};  // 左移LED灯
            end else begin
                count <= count + 32'd1;  // 计数器递增
            end
        end
    end

endmodulemodule led_marquee #(
    parameter CLK_FREQ = 200_000_000, // 时钟频率，单位为Hz
    parameter LED_INTERVAL = 0.25,    // LED切换间隔，单位为秒
    parameter MODE = 0                // LED控制模式：0-跑马灯，1-闪烁，2-呼吸灯
)(
    input wire clk_p,        // 差分时钟正端
    input wire clk_n,        // 差分时钟负端
    input wire rst_n,        // 复位信号，低电平有效
    output reg [3:0] leds    // 4个LED灯
);

    // 差分时钟缓冲器
    wire clk;
    IBUFDS #(
        .DIFF_TERM("TRUE"),  // 差分终端
        .IOSTANDARD("LVDS")  // LVDS标准
    ) clk_ibufds (
        .O(clk),             // 输出时钟
        .I(clk_p),           // 差分时钟正端
        .IB(clk_n)           // 差分时钟负端
    );

    // 使用PLL生成稳定的时钟信号
    wire pll_clk;
    wire pll_locked;
    PLL_BASE #(
        .CLKIN_PERIOD(5.0),  // 输入时钟周期为5ns（200MHz）
        .CLKFBOUT_MULT(10),  // 倍频系数
        .CLKOUT0_DIVIDE(10)  // 分频系数
    ) pll_inst (
        .CLKIN(clk),         // 输入时钟
        .RST(!rst_n),        // 复位信号
        .CLKFBIN(pll_clk),   // 反馈时钟
        .CLKFBOUT(pll_clk),  // 反馈时钟输出
        .CLKOUT0(pll_clk),   // 输出时钟
        .LOCKED(pll_locked)  // PLL锁定信号
    );

    // 定义状态常量
    parameter S0 = 2'd0;
    parameter S1 = 2'd1;
    parameter S2 = 2'd2;
    parameter S3 = 2'd3;

    // 计算LED切换间隔对应的时钟周期数
    localparam INTERVAL_COUNT = CLK_FREQ * LED_INTERVAL;

    reg [31:0] counter;      // 32位计数器
    reg [1:0] state;         // 状态寄存器，用于控制LED灯
    reg [3:0] led_pattern;   // LED模式控制

    // 同步复位信号
    reg rst_sync;
    always @(posedge pll_clk) begin
        rst_sync <= !rst_n;
    end

    always @(posedge pll_clk or posedge rst_sync) begin
        if (rst_sync) begin
            counter <= 32'd0;
            state <= S0;
            leds <= 4'b0000; // 复位时LED灯全灭
        end else if (pll_locked) begin
            if (counter == INTERVAL_COUNT - 1) begin
                counter <= 32'd0;
                state <= state + 1;
            end else begin
                counter <= counter + 1;
            end

            // 根据模式选择LED控制逻辑
            case (MODE)
                0: begin // 跑马灯模式
                    case (state)
                        S0: leds <= 4'b0001; // 第一个LED亮
                        S1: leds <= 4'b0010; // 第二个LED亮
                        S2: leds <= 4'b0100; // 第三个LED亮
                        S3: leds <= 4'b1000; // 第四个LED亮
                        default: leds <= 4'b0000; // 默认全灭
                    endcase
                end
                1: begin // 闪烁模式
                    leds <= (state[0]) ? 4'b1111 : 4'b0000; // 全亮或全灭
                end
                2: begin // 呼吸灯模式
                    // 呼吸灯逻辑（PWM控制）
                    if (counter < INTERVAL_COUNT / 2) begin
                        leds <= 4'b1111; // 渐亮
                    end else begin
                        leds <= 4'b0000; // 渐灭
                    end
                end
                default: leds <= 4'b0000; // 默认全灭
            endcase
        end
    end

endmodulemodule led_marquee #(
    parameter CLK_FREQ = 200_000_000, // 时钟频率，单位为Hz
    parameter LED_INTERVAL = 0.25,    // LED切换间隔，单位为秒
    parameter MODE = 0                // LED控制模式：0-跑马灯，1-闪烁，2-呼吸灯
)(
    input wire clk_p,        // 差分时钟正端
    input wire clk_n,        // 差分时钟负端
    input wire rst_n,        // 复位信号，低电平有效
    output reg [3:0] leds    // 4个LED灯
);

    // 差分时钟缓冲器
    wire clk;
    IBUFDS #(
        .DIFF_TERM("TRUE"),  // 差分终端
        .IOSTANDARD("LVDS")  // LVDS标准
    ) clk_ibufds (
        .O(clk),             // 输出时钟
        .I(clk_p),           // 差分时钟正端
        .IB(clk_n)           // 差分时钟负端
    );

    // 使用PLL生成稳定的时钟信号
    wire pll_clk;
    wire pll_locked;
    PLL_BASE #(
        .CLKIN_PERIOD(5.0),  // 输入时钟周期为5ns（200MHz）
        .CLKFBOUT_MULT(10),  // 倍频系数
        .CLKOUT0_DIVIDE(10)  // 分频系数
    ) pll_inst (
        .CLKIN(clk),         // 输入时钟
        .RST(!rst_n),        // 复位信号
        .CLKFBIN(pll_clk),   // 反馈时钟
        .CLKFBOUT(pll_clk),  // 反馈时钟输出
        .CLKOUT0(pll_clk),   // 输出时钟
        .LOCKED(pll_locked)  // PLL锁定信号
    );

    // 定义状态常量
    parameter S0 = 2'd0;
    parameter S1 = 2'd1;
    parameter S2 = 2'd2;
    parameter S3 = 2'd3;

    // 计算LED切换间隔对应的时钟周期数
    localparam INTERVAL_COUNT = CLK_FREQ * LED_INTERVAL;

    reg [31:0] counter;      // 32位计数器
    reg [1:0] state;         // 状态寄存器，用于控制LED灯
    reg [3:0] led_pattern;   // LED模式控制

    // 同步复位信号
    reg rst_sync;
    always @(posedge pll_clk) begin
        rst_sync <= !rst_n;
    end

    always @(posedge pll_clk or posedge rst_sync) begin
        if (rst_sync) begin
            counter <= 32'd0;
            state <= S0;
            leds <= 4'b0000; // 复位时LED灯全灭
        end else if (pll_locked) begin
            if (counter == INTERVAL_COUNT - 1) begin
                counter <= 32'd0;
                state <= state + 1;
            end else begin
                counter <= counter + 1;
            end

            // 根据模式选择LED控制逻辑
            case (MODE)
                0: begin // 跑马灯模式
                    case (state)
                        S0: leds <= 4'b0001; // 第一个LED亮
                        S1: leds <= 4'b0010; // 第二个LED亮
                        S2: leds <= 4'b0100; // 第三个LED亮
                        S3: leds <= 4'b1000; // 第四个LED亮
                        default: leds <= 4'b0000; // 默认全灭
                    endcase
                end
                1: begin // 闪烁模式
                    leds <= (state[0]) ? 4'b1111 : 4'b0000; // 全亮或全灭
                end
                2: begin // 呼吸灯模式
                    // 呼吸灯逻辑（PWM控制）
                    if (counter < INTERVAL_COUNT / 2) begin
                        leds <= 4'b1111; // 渐亮
                    end else begin
                        leds <= 4'b0000; // 渐灭
                    end
                end
                default: leds <= 4'b0000; // 默认全灭
            endcase
        end
    end

endmodule
