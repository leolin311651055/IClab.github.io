Final Project

這次 Final Project 感覺滿挑戰的，我們要做一個 16-bit 單核心 RISC CPU，從 RTL 到 Gate-Level，再到 APR 與 Post Layout Simulation 都要完整走一遍。

一開始寫指令 decode 與 execute 邏輯時有點混亂，尤其是 branch、jump 還要算 pc，慢慢拆模組就清楚多了。load/store 與 pipeline 的 hazard 也讓我卡了一陣子，學會用 stall 控制和 forward 的概念去解決，對 CPU pipeline 流程理解更深。

AXI4 與 DRAM 的整合也很實務，IO_stall 的 timing 控制讓我體會記憶體存取的實際狀況。整個 RTL → Synthesis → Gate-Level → APR → Post Simulation 流程，任何小錯都可能影響 demo 成績，養成了檢查每個步驟的習慣。

總之，這次專案讓我對 CPU 設計流程、pipeline hazard、memory interface，以及後端 timing/power/area trade-off 都有了實務感受，也學到很多 debug 和整合的技巧。