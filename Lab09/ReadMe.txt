Lab9  

這次課真的讓我感受到「設計」和「驗證」的距離被縮短了很多。以前在 Verilog 階段，常覺得 testbench 只是輔助，但老師一講 SystemVerilog 的優勢，加上 Lab09 的實作，真的有種 “驗證才是系統完整性的核心” 的體會。  

SystemVerilog 的抽象能力（OOP、randomization、UVM 架構）比起 Verilog 直觀很多，像是 always_comb/ff/latch 區分清楚，typedef/struct/enum/union 整理資料結構更乾淨，interface/modport 讓模組溝通不再混亂。尤其是 OOP class 配合 randomize()，在 Lab09 我第一次實際感受到「驗證的自動化」帶來的便利：能快速產生各種 corner case，而不是手動硬寫測資。  

Lab09 Autonomous Flower Shop 作業挑戰很大：不只是功能實作（買花、補貨、檢查有效日期），還要面對很多真實限制——像 1~4 cycles 延遲、DRAM 資料格式、AXI Lite interface、六個 valid signal 與 out_valid timing 的對應。如果沒事先規劃清楚，很容易卡死在 edge case 或訊號對不準。更何況作業還規定不能用 DesignWare IP、SRAM、latch、甚至某些命名方式或 display/print，讓 debug 難度直接上升。  

整個過程中最大的收穫是「如何在限制裡找到彈性」。我發現要先把流程拆解成小模組，明確規劃 interface，再逐步整合，這樣出問題時才容易定位。另一個心得是：驗證環境要早早搭好，不然設計到一半才發現資料對不上，會花更多時間返工。  

總結來說，這堂課不只是學語法，而是真正把 SystemVerilog 的設計與驗證方法落地，逼我去思考完整性、穩健性和 edge case 的處理。Lab09 對我來說像是一次 mini project，把抽象概念變成能操作的技能，雖然挑戰很大，但真的有種能力被拉升一個層級的感覺。  
