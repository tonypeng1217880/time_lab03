`timescale 1ps/1ps

module DCC (
    input  wire clk_in,   // 輸入時脈 (1GHz)
    input  wire rst_n,    // 系統重置 (Active Low)
    output wire clk_dcc   // 校正後的輸出時脈 (50% Duty Cycle)
);

    // ============================================================
    // 參數設定
    // ============================================================
    parameter TDL_STAGES = 64;  // TDL 總階數
    parameter CTRL_WIDTH = 6;   // 控制碼寬度

    // ============================================================
    // 內部訊號宣告
    // ============================================================
    wire [CTRL_WIDTH-1:0] ctrl_code; // 控制碼 (兩個 TDL 共用)
    wire        pd_early;            // PD 輸出
    
    wire        clk_mid;             // 第一級輸出 (半週期延遲, 180度)
    wire        clk_end;             // 第二級輸出 (全週期延遲, 360度)

    wire        pulse_set_n;         // Set 脈衝 (Active Low)
    wire        pulse_rst_n;         // Reset 脈衝 (Active Low)

    // ============================================================
    // 1. 控制迴路 (Control Loop)
    // ============================================================
    
    // Phase Detector: 比較 "輸入(0度)" 與 "終點(360度)"
    // 這裡抓的是第二級 TDL 的輸出 (clk_end)
    Phase_Detector U_PD (
        .clk_ref  (clk_in),
        .clk_fb   (clk_end),
        .rst_n    (rst_n),
        .early    (pd_early)
    );

    // Controller: 計算控制碼
    Controller #( .WIDTH(CTRL_WIDTH) ) U_CTRL (
        .clk      (clk_in),
        .rst_n    (rst_n),
        .early    (pd_early),
        .code_out (ctrl_code)
    );

    // ============================================================
    // 2. 延遲線 (TDL Units) - 採用講義的串聯架構
    // ============================================================
    // 這種架構不需要將 code 除以 2，而是串聯兩個一樣的 TDL
    // 當總延遲鎖定在 360 度時，中間點自然就是 180 度
    
    // TDL-1: 產生 0 -> 180度
    TDL #( .STAGES(TDL_STAGES), .SEL_WIDTH(CTRL_WIDTH) ) U_TDL_1 (
        .clk_in   (clk_in),
        .sel      (ctrl_code),
        .clk_out  (clk_mid)    // 輸出給下一級，也給 Pulse Gen 2
    );

    // TDL-2: 產生 180 -> 360度
    TDL #( .STAGES(TDL_STAGES), .SEL_WIDTH(CTRL_WIDTH) ) U_TDL_2 (
        .clk_in   (clk_mid),   // 接上一級的輸出
        .sel      (ctrl_code),
        .clk_out  (clk_end)    // 輸出給 PD 做回授
    );

    // ============================================================
    // 3. 波形合成 (Waveform Synthesis)
    // ============================================================

    // One-Shot 1: 偵測 clk_in 上升緣 -> 產生 Set 脈衝
    // [重要] 這裡加入了 .rst_n 連接，因為新的 Pulse Generator 需要它來消除紅線
    Pulse_Generator U_OS_1 (
        .clk_in      (clk_in),
        .rst_n       (rst_n),       // <--- 新增連接
        .pulse_out_n (pulse_set_n)
    );

    // One-Shot 2: 偵測 clk_mid (半週期) 上升緣 -> 產生 Reset 脈衝
    Pulse_Generator U_OS_2 (
        .clk_in      (clk_mid),
        .rst_n       (rst_n),       // <--- 新增連接
        .pulse_out_n (pulse_rst_n)
    );

    // SR Latch: 根據 Set/Reset 脈衝合成 50% Duty Cycle
    SR_Latch U_LATCH (
        .set_n       (pulse_set_n),
        .rst_n_pulse (pulse_rst_n),  // 注意這裡名稱對應
        .sys_rst_n   (rst_n),        // <--- 把系統 Reset 接進來！
        .q_out       (clk_dcc)
    );

endmodule