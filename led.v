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

endmodule