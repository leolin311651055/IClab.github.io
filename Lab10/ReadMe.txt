Lab10

這次 SystemVerilog Verification 的課收穫蠻大的，重點就是學怎麼寫 testbench 來驗證設計。Functional Coverage 一開始聽起來很複雜，什麼 coverpoint、covergroup、bins、cross coverage，剛開始還有點搞不懂，但實際做例子後發現邏輯蠻直覺的，就是把設計行為拆成事件，再去追蹤有沒有被測到。  

Assertion 部分更讓我覺得實用，Immediate assertion 可以立刻檢查條件，Concurrent assertion 則能看跨 cycle 的行為，加上 $rose、$fell 這些 function，讓檢查寫起來更簡單。剛開始常常寫錯 timing 或語法，不過慢慢調整後就覺得掌握度越來越好。  

Lab10 算是一次完整驗證的挑戰，把之前的系統拿來做測資生成、寫 checker、跑 coverage 和 assertion。過程中最卡的是怎麼讓 coverage 都 hit 到，還有 assertion 不會誤判，但反覆 debug 後就找到訣竅，也更懂 testbench 的設計思維。  

整體來說，這次練習讓我不只是懂理論，而是能真的把 verification 串起來。最大的收穫是學會怎麼把複雜設計拆成可以驗證的事件，遇到卡關也能靠實驗和調整去解決，做完會有種成就感。
