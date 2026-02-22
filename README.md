# Timing Lab03 – Duty Cycle Corrector (DCC)

課程：時序電路設計及應用  
指導教授：黃錫瑜 教授  
作者：彭冠傑  
製程：TSMC 90nm Standard Cell  
工具流程：Synopsys Design Compiler  

---

## 一、專案簡介

本專案實作一個閉迴路 Duty Cycle Corrector (DCC)，  
透過 Tapped Delay Line (TDL) 與 Bang-Bang Phase Detector 建立回授控制機制，  
動態調整延遲量，使輸出時脈收斂至 50% Duty Cycle。

設計重點包含：

- Cell-based 延遲建模
- Bang-bang 相位誤差控制
- 閉迴路數位控制
- 可合成 RTL 設計
- Gate-level 驗證

---

## 二、系統架構

```text
clk_in
│
▼
TDL ─────► TDL ─────► clk_end
│            ▲
│            │
clk_mid      │
│            │
Pulse Gen    │
│            │
▼            │
SR Latch ◄── PD ◄── clk_in
│
▼
Controller
## 架構說明

- 兩級相同 TDL 串聯，共用同一組控制碼 ctrl_code  
- Phase Detector 比較 clk_in 與 clk_end  
- Controller 根據 early 訊號動態調整延遲  
- 第一級 TDL 輸出 clk_mid 對應半週期 (180°)  
- Pulse Generator 產生 Active-Low 脈衝  
- SR Latch 合成最終 duty-corrected clock  

---

## 三、模組設計

### 1. Tapped Delay Line (TDL)

- 64-stage Path-selection 架構  
- 每 stage 使用 2 顆 INVX1 (TSMC 90nm)  
- Time Resolution ≈ 0.0214 ns  

設計特點：

- 延遲量固定且可預測  
- 使用 assign 選擇 tap  
- 合成工具可最佳化 MUX Tree  

---

### 2. Phase Detector

- D Flip-Flop 於 clk_ref 上升緣取樣 clk_fb  
- High → Early  
- Low → Late  
- 輸出單位元誤差信號 early  

---

### 3. Controller

控制規則：

- early = 1 → code +1  
- early = 0 → code -1  

設計考量：

- 邊界保護避免 overflow / underflow  
- WAIT_CYCLES 控制更新頻率  
- 降低震盪避免不穩定  

---

### 4. Pulse Generator

元件：

- DFFRQX1  
- DLY1X1  
- INVX1  
- AND2X1  

特點：

- Rising edge 觸發  
- 延遲決定 pulse width  
- 閉迴路自動重置  

---

### 5. SR Latch

- Cross-coupled NAND2X4  
- Active-Low 架構  
- 上電 reset 保護  

優點：

- 無額外反相器  
- 降低延遲  
- 避免 glitch  

---

## 四、合成結果

- Gate count：571  
- Combinational：549  
- Sequential：13  
- Total area：約 1944.63  
- 製程：TSMC 90nm  

設計可完全合成。

---

## 五、Gate-Level 驗證

### 輸入 Duty = 30%

- ctrl_code 收斂於 30~32  
- 系統穩定鎖定  

### 輸入 Duty = 70%

- ctrl_code 收斂於 40~41  
- Controller 正常收斂  

---

## 六、Glitch 分析

當 Low Time 僅 300ps：

- 延遲過大導致邊緣重疊  
- clk_mid 出現短暫 glitch  

屬物理延遲交疊現象，  
非控制邏輯錯誤。

---

## 七、技術重點

- Cell-based delay modeling  
- Closed-loop clock alignment  
- Bang-bang digital control  
- Standard-cell synthesis flow  
- Gate-level timing awareness  
- 邊界保護設計  
- 可預測延遲解析度  

---

## 八、結論

本設計成功實作可合成之 DCC：

- 可在極端 duty 下收斂  
- 控制邏輯穩定  
- 完成合成與 gate-level 驗證  
- 延遲解析度可預測  

展現對時序電路、標準元件延遲模型、  
閉迴路控制與實體效應的理解。