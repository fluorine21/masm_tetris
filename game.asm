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




.CODE
	
CheckIntersect PROC USES ebx ecx oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 

	ret

CheckIntersect ENDP

GameInit PROC USES ebx 


	invoke UpdateBoard

	mov ebx, 0

	L1:
	cmp ebx, 30
	jg END1

		invoke UpdateBoard

	inc ebx
	jmp L1

END1:

	
	ret         ;; Do not delete this line!!!
GameInit ENDP


GamePlay PROC


	invoke DrawBoard

	

	ret         ;; Do not delete this line!!!
GamePlay ENDP







END
