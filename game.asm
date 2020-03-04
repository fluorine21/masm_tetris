; #########################################################################
;
;   game.asm - Assembly file for CompEng205 Assignment 4/5
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc
include game.inc
include images.inc


;; Has keycodes
include keys.inc
include tetris.inc
include graphics.inc

	
.DATA

;; If you need to, you can place global variables here


bul1 SPRITE<100, 100, 0, 0, 0, bullet>

tur1 SPRITE<200, 200, 0, 0, 0, turtle>


.CODE
	
CheckIntersect PROC USES ebx ecx oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 

	ret

CheckIntersect ENDP

GameInit PROC


	invoke UpdateBoard
	invoke UpdateBoard
	
	ret         ;; Do not delete this line!!!
GameInit ENDP


GamePlay PROC


	invoke DrawBoard

	

	ret         ;; Do not delete this line!!!
GamePlay ENDP







END
