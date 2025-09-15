Lab02

這次課程主要學 Sequential Circuit，老師從組合邏輯延伸介紹 Flip-Flop、Latch、非同步/同步重置差異，以及 Blocking / Non-blocking assignment 的用法，強調 Combinational 與 Sequential Logic 的分離，避免不必要的 latch 。  

FSM 部分講了 Mealy 與 Moore 設計原則，建議把 Current State、Next State、Output Logic 分開管理，並介紹 Timing Check、Setup/Hold Time、Metastability，讓我們理解時序對可靠性的重要性。  

Lab02 作業 Maze 將時序電路概念和演算法結合：設計 17×17 迷宮導航電路，按 raster scan 輸入迷宮資料，用 Flip-Flop 保存狀態，導航方向輸出 Right/Down/Left/Up 並控制 out_valid。重點在時序控制、路徑搜尋演算法（DFS/BFS）以及 Timing/Performance，需在 1500 cycles 內完成，且不能產生 latch，out_valid 與 in_valid 不可同時高。  

總結來說，這次作業讓我練習 FSM 與時序控制，也體會到演算法仍是解題核心，時序電路則確保硬體上的正確性與可靠性。

Algorithm: 

/**************************************************************************
 * NOTE TITLE   : Maze Solver Algorithm Design
 * AUTHOR       : Leo Lin
 * DATE         : 2025/09/15
 * DESCRIPTION  : This note summarizes the design and implementation 
 *                of a maze-solving algorithm using a FSM-based approach.
 *                The design supports path traversal with/without a sword,
 *                handles backtracking, and outputs movement directions.
 **************************************************************************/

/**************************************************************************
 * 1. Problem Description
 * ------------------------------------------------------------------------
 * - Given a maze represented as a 2D grid (NxN), where each cell can be:
 *     0 : empty path
 *     2 : sword
 *     3/4/5 : path already walked
 * - The task is to traverse from a starting point (0,0) to the exit (N-1,N-1)
 * - Outputs required:
 *     - out_valid : whether a valid move exists
 *     - out       : movement direction (RIGHT/LEFT/UP/DOWN)
 * - Special constraint:
 *     - Sword acquisition may unlock new traversal rules
 **************************************************************************/

/**************************************************************************
 * 2. Algorithm Design
 * ------------------------------------------------------------------------
 * Step 1: Initialize
 *   - Create a NxN 2D array to represent the maze
 *   - Set all cells to 0 (unvisited)
 *   - Set pointer_row = 0, pointer_column = 0
 *   - Initialize FSM state to IDLE
 *
 * Step 2: Input Handling
 *   - While in INPUT state, read in maze data
 *   - Update graph[row][col] with input value
 *   - Move pointer_column; if row end reached, increment pointer_row
 *
 * Step 3: Path Traversal (FSM NO_SWORD / SWORD)
 *   - At each step:
 *       1. Check possible moves in four directions
 *           - right, down, left, up
 *           - Avoid reversing previous move
 *           - Check if cell is walkable (0, 2, or visited)
 *       2. Prioritize sword acquisition if present
 *       3. Update pointer_row/pointer_column according to valid move
 *       4. Mark current cell as visited in graph
 *
 * Step 4: Feedback Handling
 *   - If the next cell is already walked (feedback 4), allow revisiting
 *   - Maintain path consistency and prevent infinite loops
 *
 * Step 5: Output Generation
 *   - Set out_valid = 1 if a valid move exists
 *   - Set out according to movement direction
 *   - If maze completed, set out_valid = 0
 **************************************************************************/

/**************************************************************************
 * 3. FSM State Description
 * ------------------------------------------------------------------------
 * States:
 *   IDLE      : waiting for input
 *   INPUT     : reading maze data
 *   NO_SWORD  : traversing maze without sword
 *   SWORD     : traversing maze with sword
 *   OUTDIRECT : optional state for direct output or special handling
 *
 * Transition Conditions:
 *   - IDLE -> INPUT : in_valid
 *   - INPUT -> NO_SWORD : pointer_row == N-1 && pointer_column == N-1
 *   - NO_SWORD -> SWORD : sword found in adjacent cell
 *   - NO_SWORD/SWORD -> IDLE : exit reached
 **************************************************************************/

/**************************************************************************
 * 4. Pseudocode
 * ------------------------------------------------------------------------
 * function MazeSolver(graph, N):
 *     pointer_row, pointer_column = 0, 0
 *     state = IDLE
 *     while state != IDLE or not finished:
 *         if state == INPUT:
 *             graph[pointer_row][pointer_column] = input_value
 *             move pointer_column (and pointer_row if needed)
 *         elif state in (NO_SWORD, SWORD):
 *             moves = check_valid_moves(graph, pointer_row, pointer_column)
 *             if sword in moves:
 *                 state = SWORD
 *             if moves:
 *                 choose move based on priority
 *                 update pointer_row / pointer_column
 *                 mark graph cell visited
 *             else:
 *                 backtrack if needed
 *         update out_valid and out
 *     return traversal_path
 **************************************************************************/

/**************************************************************************
 * 5. Complexity Analysis
 * ------------------------------------------------------------------------
 * Time Complexity:
 *   - Worst case: O(N^2) for an NxN maze, visiting all cells once
 *   - Backtracking may revisit some cells
 *
 * Space Complexity:
 *   - O(N^2) for the maze graph
 *   - O(1) for pointer registers and FSM state
 **************************************************************************/

/**************************************************************************
 * 6. Notes / Design Considerations
 * ------------------------------------------------------------------------
 * - Use FSM to simplify maze traversal logic and control flow
 * - Maintain direction wires to avoid reversing and infinite loops
 * - Use graph feedback to handle already visited paths
 * - Prioritize sword acquisition to unlock SWORD state traversal
 * - Pointer update logic can be modularized for readability
 **************************************************************************/

/**************************************************************************
 * 7. Example
 * ------------------------------------------------------------------------
 * Maze:
 * 0 0 2
 * 0 3 0
 * 0 0 0
 *
 * Traversal path:
 * Start at (0,0)
 * Move RIGHT -> (0,1)
 * Move RIGHT -> (0,2) (sword acquired)
 * Move DOWN  -> (1,2)
 * Move LEFT  -> (1,1)
 * Move DOWN  -> (2,1)
 * Move RIGHT -> (2,2) (exit)
 **************************************************************************/
