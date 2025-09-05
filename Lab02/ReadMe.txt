Lab02

這次課程主要學 Sequential Circuit，老師從組合邏輯延伸介紹 Flip-Flop、Latch、非同步/同步重置差異，以及 Blocking / Non-blocking assignment 的用法，強調 Combinational 與 Sequential Logic 的分離，避免不必要的 latch 。  

FSM 部分講了 Mealy 與 Moore 設計原則，建議把 Current State、Next State、Output Logic 分開管理，並介紹 Timing Check、Setup/Hold Time、Metastability，讓我們理解時序對可靠性的重要性。  

Lab02 作業 Maze 將時序電路概念和演算法結合：設計 17×17 迷宮導航電路，按 raster scan 輸入迷宮資料，用 Flip-Flop 保存狀態，導航方向輸出 Right/Down/Left/Up 並控制 out_valid。重點在時序控制、路徑搜尋演算法（DFS/BFS）以及 Timing/Performance，需在 1500 cycles 內完成，且不能產生 latch，out_valid 與 in_valid 不可同時高。  

總結來說，這次作業讓我練習 FSM 與時序控制，也體會到演算法仍是解題核心，時序電路則確保硬體上的正確性與可靠性。
