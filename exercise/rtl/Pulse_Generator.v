`timescale 1ps/1ps

module Pulse_Generator (
    input  wire clk_in,      // 輸入
    input  wire rst_n,       // 重置
    output wire pulse_out_n  // 輸出 Active Low Pulse
);

    wire q_pulse_high;
    wire dly_out;
    wire fb_rst_n;
    wire final_rst_n;

    // 1. DFF 核心
    DFFRQX1 U_DFF (
        .D  (1'b1),
        .CK (clk_in),
        .RN (final_rst_n),
        .Q  (q_pulse_high)
    );

    // 2. 延遲單元 (加回來了！)
    // 使用 DLY1X1 確保脈寬足夠，不會消失
    DLY1X1 U_DLY_CELL (
        .A (q_pulse_high), 
        .Y (dly_out)
    );

    // 3. 反相器 (回授路徑)
    INVX1 U_INV_FB (
        .A (dly_out), 
        .Y (fb_rst_n)
    );

    // 4. 重置邏輯 (系統重置 + 自我重置)
    AND2X1 U_RST_LOGIC (
        .A (fb_rst_n),
        .B (rst_n),
        .Y (final_rst_n)
    );

    // 5. 輸出轉態 (High -> Low)
    INVX2 U_OUT_INV (
        .A (q_pulse_high),
        .Y (pulse_out_n)
    );

endmodule