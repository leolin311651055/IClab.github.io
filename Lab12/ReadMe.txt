Lab12 

這次其實就是把 Lab11 的 APR 流程再往下推一層，重點放在 timing analysis 跟 power/IR drop。前面只是單純把設計放進 layout，這次就多了更多現實條件要考慮。最有感的是，設計跑出來不只是要能 work，還要沒有 timing violation、沒有 DRV，甚至還要考慮電源供應的穩定性。

在做的過程中我特別注意到，很多問題不是單一階段就能解決的，像 timing 跟 IR drop 其實會互相影響。stripe 配置不夠會造成 IR drop，但加太多又可能影響 routing 跟 timing。這讓我意識到 backend flow 本質上就是不斷在 trade-off 裡找平衡。

另一個心得是，工具跑出來的結果不代表就真的沒問題，像 DRC/LVS 通常 nanoRoute 之後會過，但加 filler 還是有可能出現意想不到的 open。這時候就會體會到「自我驗證」的重要，必須反覆檢查才能放心。

總結來說，這次練習讓我比較清楚 backend 的思路，不只是照著流程跑，而是要開始理解為什麼要做這些檢查，為什麼 IR drop 要限制這麼嚴格。感覺這就是把設計拉近實際製程的一步，從純邏輯世界走到物理實現的過程。
