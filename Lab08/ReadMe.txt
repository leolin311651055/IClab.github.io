Lab08 

這次核心挑戰其實不是把 SNN pipeline 做出來，而是怎麼把功耗降下來。以前做 CNN 或其他 accelerator，比較多是 timing、latency 的問題，這次則是第一次需要認真去看功耗報告，想辦法在設計上動手腳。  

最一開始卡住的地方是 clock gating，要判斷哪些 block 在特定時段不需要動，並且讓時脈能安全地停掉。設計過程中最怕的就是 glitch 或 timing 問題，光是把 cg_en 的條件釐清就花了不少時間。最後有找到合適的切分方式，讓運算還是正確，但切掉的 switching power 明顯下降。  

跑 PrimeTime 的時候，也遇到過 VCD/FSDB 沒有正確對應，導致 report 出來的功耗數字怪怪的。後來才發現要把 clock gating 的控制訊號確實帶進去，模擬結果才會反映真實情況。這個過程算是把之前課堂講的「動態功耗主要來自不必要的 switching」體驗得很深刻。  

整體下來，這次 Lab 讓我對低功耗設計的理解不只是停留在公式，而是真的在 RTL 設計、模擬驗證中感受到 trade-off。感覺自己未來在做 ASIC/FPGA 時，如果遇到 power bottleneck，至少會知道該從哪裡下手去調整。  
