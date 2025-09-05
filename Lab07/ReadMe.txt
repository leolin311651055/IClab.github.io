Lab07 

這次作業主要是挑戰跨時脈域設計和 timing analysis，一開始覺得 PRNG 本身不難，Xorshift 實作很直覺，但真正的麻煩在於三個時脈域之間的同步。seed 要在 clk1 傳過去、隨機數要在 clk2 計算，再丟到 clk3 domain 輸出，整個過程中 handshake 和 FIFO 都是關鍵，稍微沒顧好就可能遇到 metastability。實作時才發現 CDC 的 tricky 之處，尤其是在同步訊號的設計上，光靠直覺常常會踩坑。

後來靠 Jasper Gold 來驗證 CDC，幫助很大，可以在早期就看到跨時脈域的隱患，這讓我更放心 FIFO 的設計。用 dual port SRAM 做 FIFO 也學到模組重用的價值，因為不同 clk3 週期都能適配，省下不少麻煩。不過在調整 latency 和 area 時，也意識到沒有「一體適用」的設計，很多時候要做取捨。

Timing analysis 的部分讓我真正感受到 STA 比 DTA 更有用，因為可以預測所有可能的 timing path，而不是等模擬才發現問題。透過 dc_shell 去設定 clock latency、uncertainty 和 multicycle path，一開始很生疏，但練習後發現能有效控制 slack，這比單純跑 simulation 可靠得多。setup/hold 的 violation 如果提早處理，就不會在最後階段手忙腳亂。

整體來說，這次 Lab07 讓我最大的收穫是理解到硬體設計不只是把演算法寫對，更重要的是如何讓它能在不同時脈下穩定工作。跨時脈域、時序分析、模組重用，這些挑戰逼我把視野從單純 coding 拉高到系統層級的思考。雖然過程有點卡關，但最後能看到正確輸出的隨機數，還是很有成就感。
