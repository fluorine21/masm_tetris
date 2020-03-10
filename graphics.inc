
;;Functions
DrawCell PROTO STDCALL x:DWORD, y:DWORD, color:DWORD
DrawBoard PROTO STDCALL
DrawScore PROTO STDCALL score:DWORD
DrawGameOver PROTO STDCALL
RemoveGameOver PROTO STDCALL
DrawGamePaused PROTO STDCALL
RemoveGamePaused PROTO STDCALL
DrawTetrisLogo PROTO STDCALL
DrawLevel PROTO STDCALL level:DWORD
DrawBackground PROTO STDCALL
DrawSkulls PROTO STDCALL

CELL_SIZE equ 16 ;; number of pixels used by a cell, should be power of 2
CELL_SHIFT equ 4 ;; ammount we need to shift to multiply by cell size
CELL_PAD equ 1 ;; number of pixels between each cell

;;Offsets for drawing the board
R_OFFSET equ 40
C_OFFSET equ 10

;;Offsets for drawing the score
SCORE_R equ 50
SCORE_C equ 200

;;Offsets for drawing the level
LEVEL_R equ 70
LEVEL_C equ 200

;;Offsets for drawing game over message
GAME_OVER_R equ 90
GAME_OVER_C equ 200

;;Offsets for drawing game paused message
GAME_PAUSED_R equ 110
GAME_PAUSED_C equ 200

;;Offsets for drawing tetris logo
TETRIS_LOGO_R equ 20
TETRIS_LOGO_C equ 50

;;Background offsets
BACKGROUND_ROW_NUM equ 100
BACKGROUND_COL_NUM equ 7

