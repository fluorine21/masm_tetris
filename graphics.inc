
;;Functions
DrawCell PROTO STDCALL x:DWORD, y:DWORD, color:DWORD
DrawBoard PROTO STDCALL

CELL_SIZE equ 16 ;; number of pixels used by a cell, should be power of 2
CELL_SHIFT equ 4 ;; ammount we need to shift to multiply by cell size
CELL_PAD equ 1 ;; number of pixels between each cell

;;Offsets for drawing the board
R_OFFSET equ 30
C_OFFSET equ 10
