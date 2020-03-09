
;;Function Prototypes
UpdateBoard PROTO STDCALL 
ShiftPiece PROTO STDCALL dir:BYTE
AddPiece PROTO STDCALL 
CementPiece PROTO STDCALL 
RotatePiece PROTO STDCALL dir:DWORD
AddPiece PROTO STDCALL 
GetBoardLoc PROTO STDCALL row:DWORD, col:DWORD
GetBoardLocType PROTO STDCALL row:DWORD, col:DWORD
SetBoardLoc PROTO row:DWORD, col:DWORD, val:DWORD
SetBoardLocType PROTO STDCALL row:DWORD, col:DWORD, val:DWORD
SetBoardLocColor PROTO STDCALL row:DWORD, col:DWORD, val:DWORD
ShiftPieceDown PROTO STDCALL
ShiftBlockDown PROTO STDCALL row:DWORD, col:DWORD
ShiftPieceLR PROTO STDCALL off_set:DWORD
CheckAddr PROTO STDCALL row:DWORD, col:DWORD
CompleteRowsCheck PROTO STDCALL
GameTick PROTO STDCALL
RotatePieceLR PROTO STDCALL dir:DWORD
ShiftRowsDown PROTO STDCALL row_num:DWORD
GameOverCheck PROTO STDCALL
GameOver PROTO STDCALL
ResetGame PROTO STDCALL

;;Struct Definitions

_PIECE_STRUCT STRUCT
r0 DWORD ?
c0 DWORD ?
r1 DWORD ?
c1 DWORD ?
r2 DWORD ?
c2 DWORD ?
r3 DWORD ?
c3 DWORD ?
_PIECE_STRUCT ENDS


PIECE_STRUCT TYPEDEF _PIECE_STRUCT


TICK_CYCLES equ 4294967295 ;; Must be in number of CPU clock cycles
TICK_MAX equ 10 ;;maximum number of cycle ticks before UpdateBoard is called
BACKGROUND_CELL equ 0ffffh

EXTERNDEF game_over:BYTE