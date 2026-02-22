`timescale 1ps/1ps
module Controller #(
    parameter WIDTH = 6,      // 控制碼位元數
    parameter WAIT_CYCLES = 4  
)(
    input  wire             clk,      
    input  wire             rst_n,    
    input  wire             early,    
    output reg  [WIDTH-1:0] code_out  
);

    // 內部計數器，用來降速
    reg [3:0] wait_cnt; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset
            code_out <= {1'b1, {(WIDTH-1){1'b0}}}; // 設為中間值 (32)
            wait_cnt <= 0;
        end else begin
            // 每個 Cycle 計數器 +1
            wait_cnt <= wait_cnt + 1'b1;

            // 只有當計數器數到設定值時，才允許更新 Code
            if (wait_cnt == (WAIT_CYCLES - 1)) begin
                wait_cnt <= 0; // 重置計數器

                if (early) begin
                    // 增加延遲 (防溢位)
                    if (code_out != {WIDTH{1'b1}}) begin
                        code_out <= code_out + 1'b1;
                    end
                end else begin
                    // 減少延遲 (防下溢)
                    if (code_out != {WIDTH{1'b0}}) begin
                        code_out <= code_out - 1'b1;
                    end
                end
            end 
            // 如果還沒數到，code_out 保持不變 (Hold)
        end
    end

endmodule