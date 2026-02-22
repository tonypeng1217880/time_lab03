`timescale 1ps/1ps
module Phase_Detector (
    input  wire clk_ref,  // 參考時脈 (Reference Clock, 1GHz)
    input  wire clk_fb,   // 回授時脈 (Feedback Clock, 來自 TDL 輸出)
    input  wire rst_n,    // Active Low Reset
    output reg  early     // 輸出: 1 代表太早 (Early), 0 代表太晚 (Late)
);

    // ============================================================
    // Bang-Bang Phase Detector 邏輯
    // ============================================================
    // 原理：使用 D Flip-Flop 進行取樣 (Sampling)
    // 
    // 1. 以 "clk_ref" 的上升緣當作基準點 (裁判)。
    // 2. 在這個瞬間去檢查 "clk_fb" 的狀態：
    //    - 如果 clk_fb 已經是 High (1)，代表它比 clk_ref "早" 到達 -> Early = 1
    //    - 如果 clk_fb 還是 Low  (0)，代表它比 clk_ref "晚" 到達 -> Early = 0 (Late)
    // ============================================================

    always @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n) begin
            early <= 1'b0;
        end else begin
            early <= clk_fb; 
        end
    end

   
endmodule