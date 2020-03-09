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

;;Music includes
include \masm32\include\windows.inc
include \masm32\include\winmm.inc
includelib \masm32\lib\winmm.lib

	
.DATA

LastKeyPress DWORD 0

;;Path for the tetris music
SndPath BYTE "music_fixed.wav", 0

.CODE
	
CheckIntersect PROC USES ebx ecx oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 

	ret

CheckIntersect ENDP


KeyboardDispatch PROC USES eax ebx ecx edx esi edi
	
	;;Check to see if the same key is still being pressed
	mov eax, KeyPress
	cmp eax, LastKeyPress
	jne CONT
	ret ;;Just return if this key is still being pressed

	;;If the game over flag is set then skip these keys
	cmp game_over, 1
	je SKIP_S

CONT:
	mov eax, KeyPress
	mov LastKeyPress, eax

	;;If 'A' key is being pressed
	cmp KeyPress, VK_A
	jne SKIP_A

	;;A key is being pressed, need to shift left (0)
	invoke ShiftPiece, 0

SKIP_A:

	;;If the 'D' key is being pressed
	cmp KeyPress, VK_D
	jne SKIP_D

	invoke ShiftPiece, 1

SKIP_D:
	
	;;If the 'W" key is being pressed
	cmp KeyPress, VK_W
	jne SKIP_W

	invoke RotatePiece, 0

SKIP_W:

	;;If the 'S' key is being pressed
	cmp KeyPress, VK_S
	jne SKIP_S

	invoke UpdateBoard

SKIP_S:

	;;Check if the Z key is being pressed
	cmp KeyPress, VK_Z
	jne SKIP_Z

	invoke ResetGame

SKIP_Z:

	ret

KeyboardDispatch ENDP

GameInit PROC USES ebx 

	;;Start the music
	invoke PlaySound, offset SndPath, 0, SND_FILENAME OR SND_ASYNC OR SND_LOOP

	;;Need to initially draw the score
	invoke DrawScore, 0
	invoke UpdateBoard
	
	ret         ;; Do not delete this line!!!
GameInit ENDP


GamePlay PROC

	invoke KeyboardDispatch
	invoke GameTick
	invoke DrawBoard

	

	ret         ;; Do not delete this line!!!
GamePlay ENDP







END
