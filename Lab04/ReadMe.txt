Lab04

這次課核心還是 IP 運用，聚焦 Advanced Sequential Circuit Design，重點在 Timing / Setup-Hold / Pipeline，以及 DesignWare IP 的使用。老師講了 D Flip-Flop 的 timing 概念（setup/hold、propagation/contamination delay），示範如何檢查與修正 timing violation。Pipeline 的重要性透過 area vs timing trade-off 案例呈現得很直觀。  

作業是 Two-Head Attention 模組，雖然簡化了 token 數與 embedding 維度，但流程完整：算 K/Q/V、分頭、計算 attention、concat、linear projection。挑戰在完全對齊 raster scan order，以及 in_valid/out_valid、reset、latency 的 timing 控制。  

DesignWare IP 的使用讓我更直觀體會到，現成 IP 如何幫助提升效率、控制 area 與 timing。
