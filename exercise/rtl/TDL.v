`timescale 1ps/1ps
module TDL #(
    parameter STAGES = 64,      // 延遲線的總階數 (建議 32 或 64)
    parameter SEL_WIDTH = 6     // 控制碼寬度，需對應 log2(STAGES)
)(
    input  wire                 clk_in,   // 輸入時脈
    input  wire [SEL_WIDTH-1:0] sel,      // 路徑選擇控制碼 (由 Controller 提供)
    output wire                 clk_out   // 經過延遲後的輸出時脈
);

    // 宣告內部線路：用來連接每一階延遲單元的輸出
    // tap_wire[0] 接輸入，tap_wire[1] 接第1階輸出，以此類推
    wire [STAGES:0] tap_wire;

    // 第 0 階直接連接輸入訊號 (無延遲)
    assign tap_wire[0] = clk_in;

    // ============================================================
    // 1. Delay Chain (延遲鏈) - 物理層實作
    // ============================================================
    // 說明：
    // 這裡使用 generate 迴圈來 "手動實例化" (Instantiate) 標準單元。
    // 我們選用 TSMC 90nm 的 INVX1 (最小驅動力的反相器)，
    // 每一階由 "兩顆" INVX1 串聯組成，以確保輸出訊號與輸入同相 (Non-inverting)。
    // 這樣做可以確保每一階的延遲量 (Resolution) 是物理固定的。
    // ============================================================
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : delay_stage
            
            wire internal_net; // 連接兩顆 Inverter 中間的線
            
            // 第一顆 Inverter (Cell Name: INVX1)
            // 來自 tsmc090g.pdf 標準單元庫
            INVX1 U_INV_1 (
                .A (tap_wire[i]), 
                .Y (internal_net)
            );
            
            // 第二顆 Inverter (Cell Name: INVX1)
            // 串聯後抵消反相效果，僅保留延遲
            INVX1 U_INV_2 (
                .A (internal_net), 
                .Y (tap_wire[i+1])
            );
            
        end
    endgenerate

    // ============================================================
    // 2. Path Selector (路徑選擇器) - 混合模式
    // ============================================================
   
    assign clk_out = tap_wire[sel];

endmodule