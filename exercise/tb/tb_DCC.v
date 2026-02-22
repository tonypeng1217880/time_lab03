`timescale 1ps/1ps  // 設定時間單位為 1ps，模擬 1GHz (1000ps)

module tb_DCC;

    // ============================================================
    // 1. 參數與訊號宣告
    // ============================================================
    // 必須與您的 DCC_Top 參數一致
    parameter TDL_STAGES = 64;
    parameter CTRL_WIDTH = 6;
    
    // DUT (Device Under Test) 介面訊號
    reg  clk_in;
    reg  rst_n;
    wire clk_dcc;

    // 測試控制變數
    real duty_cycle;          // 用來動態改變 Duty Cycle (例如 0.3 或 0.7)
    parameter PERIOD = 1000.0; // 1GHz = 1000ps

    // ============================================================
    // 2. 實例化設計 (Instantiate DUT)
    // ============================================================
    // 請確保這裡的參數與您的設計一致
    DCC_Top #(
        .TDL_STAGES(TDL_STAGES),
        .CTRL_WIDTH(CTRL_WIDTH)
    ) U_DUT (
        .clk_in   (clk_in),
        .rst_n    (rst_n),
        .clk_dcc  (clk_dcc)
    );

    // ============================================================
    // 3. 可變 Duty Cycle 時脈產生器
    // ============================================================
    // 這是作業驗證的關鍵：根據 "duty_cycle" 變數動態產生波形
    initial clk_in = 0;

    always begin
        // 1. 輸出 High
        clk_in = 1;
        // 等待 High 的時間 (例如 30% 就是 300ps)
        #(PERIOD * duty_cycle);
        
        // 2. 輸出 Low
        clk_in = 0;
        // 等待 Low 的時間 (例如 30% duty 時，Low 時間為 700ps)
        #(PERIOD * (1.0 - duty_cycle));
    end

    // ============================================================
    // 4. 測試流程控制 (Main Test Flow)
    // ============================================================
    initial begin
        // --- 設定波形輸出 (依據您使用的模擬器選擇) ---
        $fsdbDumpfile("DCC.fsdb"); // For Verdi / nWave
        $fsdbDumpvars(0, tb_DCC);
        // $dumpfile("DCC.vcd");   // For GTKWave / ModelSim
        // $dumpvars(0, tb_DCC);

        // --- 載入 SDF (Gate-Level Simulation 用) ---
        // 當您跑到 (d) 小題做合成後模擬時，請取消下面這行的註解
        // $sdf_annotate("DCC_Top_syn.sdf", U_DUT); 

        $display("==================================================");
        $display("   DCC Homework #3 Simulation Start ");
        $display("==================================================");

        // --------------------------------------------------------
        // 測試階段 1: 輸入 Duty Cycle = 30%
        // --------------------------------------------------------
        $display("[Time: %t] Phase 1: Testing Input Duty Cycle = 30%%", $time);
        duty_cycle = 0.3;  // 設定輸入為 30% (High=300ps)
        rst_n = 0;         // 系統重置
        #2000;             // 等待 2ns
        rst_n = 1;         // 釋放重置，開始鎖定
        
        // 等待足夠長的時間讓 DLL 鎖定
        // 因為是數位控制，需要時間讓 Counter 慢慢爬升
        #5000000; // 跑 5us (5000個週期)

        // --------------------------------------------------------
        // 測試階段 2: 輸入 Duty Cycle = 70%
        // --------------------------------------------------------
        $display("[Time: %t] Phase 2: Switching Input Duty Cycle to 70%%", $time);
        duty_cycle = 0.7;  // 動態切換為 70% (High=700ps)
        
        // 再跑一段時間，觀察電路是否能維持鎖定或重新調整
        #5000000; // 再跑 5us

        $display("==================================================");
        $display("   Simulation Finish ");
        $display("==================================================");
        $finish;
    end

    // ============================================================
    // 5. 自動監測輸出 (Output Monitor)
    // ============================================================
    // 這段邏輯會自動計算 clk_dcc 的 Duty Cycle 並顯示在 Log 中
    // 方便您直接截圖報告數值，不用手動算
    time t_rise, t_fall;
    real t_high, t_low, t_total;
    real measured_duty;
    
    // 偵測上升緣，記錄時間並計算 Low 寬度
    always @(posedge clk_dcc) begin
        t_rise = $time;
        if (t_fall > 0) begin
            t_low = t_rise - t_fall;
            t_total = t_high + t_low;
            
            // 計算 Duty Cycle (%)
            if (t_total > 0)
                measured_duty = (t_high / t_total) * 100.0;
            
            // 每隔 250ns 印出一次狀態，避免 Log 太多
            if ($time % 250000 == 0) begin
                $display("Monitor @ %0t ps: clk_dcc Duty = %0.2f %% (High=%0d ps, Low=%0d ps)", 
                         $time, measured_duty, t_high, t_low);
            end
        end
    end

    // 偵測下降緣，計算 High 寬度
    always @(negedge clk_dcc) begin
        t_fall = $time;
        if (t_rise > 0) begin
            t_high = t_fall - t_rise;
        end
    end

endmodule