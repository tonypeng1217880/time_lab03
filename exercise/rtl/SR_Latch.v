`timescale 1ps/1ps

module SR_Latch (
    input  wire set_n,       // Active Low Set Pulse (0有效)
    input  wire rst_n_pulse, // Active Low Reset Pulse (0有效)
    input  wire sys_rst_n,   // System Reset (0有效)
    output wire q_out        // Output Q
);

    // 內部線路
    wire q_int;
    wire qb_int;
    wire final_rst_n;

    // ============================================================
    // 1. Reset 邏輯整合 (Reset Logic Integration)
    // ============================================================
    // 因為 NAND Latch 的 Reset 輸入是 Active Low (0有效)。
    // 我們希望: 當 (系統重置=0) 或 (脈衝重置=0) 時，輸入給 Latch 的訊號為 0。
    // 邏輯方程式: final_rst_n = sys_rst_n & rst_n_pulse
    // 使用元件: AND2X1 (或者 AND2X2)
    AND2X1 U_RST_LOGIC (
        .A(sys_rst_n),
        .B(rst_n_pulse),
        .Y(final_rst_n)
    );

    // ============================================================
    // 2. 核心鎖存器 (Core Cross-coupled Latch)
    // ============================================================
    // 直接使用 Set/Reset 訊號驅動，省去前面的控制級。
    
    // Set Path:
    // 當 set_n 為 0 時 -> q_int 被強制設為 1
    NAND2X4 U_NAND_SET (
        .A (set_n),     // 直接接 Active Low Set
        .B (qb_int),    // 回授輸入
        .Y (q_int)      // 輸出 Q
    );

    // Reset Path:
    // 當 final_rst_n 為 0 時 -> qb_int 被強制設為 1 -> 導致 q_int 變 0
    NAND2X4 U_NAND_RST (
        .A (final_rst_n), // 接整合後的 Active Low Reset
        .B (q_int),       // 回授輸入
        .Y (qb_int)       // 輸出 Qb
    );

    // 輸出連接
    assign q_out = q_int;

endmodule