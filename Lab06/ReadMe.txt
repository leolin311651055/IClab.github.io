Lab06  

這次上課主要是在操作 Synopsys Design Compiler，把 RTL 轉成 gate-level netlist。一開始我對 compile strategy 和 constraint 的設定還蠻不習慣的，常常 compile 後還是會出現 timing violation，需要花時間去 debug。最讓我頭疼的是多重實例的處理，如果沒有用 uniquify 或 compile-once-don’t-touch，同一個模組重複使用就容易出錯。  

做 SDF timing simulation 的時候才真的感受到 gate-level 電路的 delay，不再只是抽象的 always block，看著模擬結果跟理論不同，才明白 timing 的重要性。generate 和 for loop 真的很方便，可以動態產生多個 module，但剛開始寫 parameter 動態產生 module 時很容易弄錯 index，需要小心檢查。  

整堂課下來，雖然 compile 常常失敗、debug 很久，但慢慢地我對 Design Compiler 的流程越來越熟悉，從 RTL 到 gate 到 timing simulation 的每一步都可以自己操作，成功 compile 後有種把抽象電路「實體化」的成就感。
