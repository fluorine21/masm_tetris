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

;;Game paused state
gamePaused BYTE 0

.CODE
	

KeyboardDispatch PROC USES eax ebx ecx edx esi edi
	
	;;Check to see if the same key is still being pressed
	mov eax, KeyPress
	cmp eax, LastKeyPress
	jne CONT
	ret ;;Just return if this key is still being pressed



CONT:

	;;Saving the last key press
	mov eax, KeyPress
	mov LastKeyPress, eax

	;;If the user wants to paus the game
	cmp KeyPress, VK_P
	jne SKIP_PAUSE

	;;Check the pause state
	cmp gamePaused, 1
	je UNPAUSE

	;;Need to pause here
	mov gamePaused, 1
	invoke DrawGamePaused
	jmp SKIP_Z

	UNPAUSE:
	mov gamePaused, 0
	invoke RemoveGamePaused
	jmp SKIP_Z

SKIP_PAUSE:

	;;Check if the game is paused
	cmp gamePaused, 1
	je SKIP_Z ;; don't let the user update anything if the game is paused

	;;If the game over flag is set then skip these keys
	cmp game_over, 1
	je SKIP_S


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
	
	;;If the 'E' key is being pressed
	cmp KeyPress, VK_E
	jne SKIP_E

	invoke RotatePiece, 0

SKIP_E:

	;;If the 'Q' key is being pressed
	cmp KeyPress, VK_Q
	jne SKIP_Q

	invoke RotatePiece, 1

SKIP_Q:

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

	;;Draw the logo
	invoke DrawTetrisLogo

	;;Need to initially draw the score
	invoke DrawScore, 0
	invoke DrawLevel, 1
	invoke UpdateBoard
	
	ret         ;; Do not delete this line!!!
GameInit ENDP


GamePlay PROC

	invoke KeyboardDispatch

	cmp gamePaused, 1
	je SKIP_TICK ;; Skip game tick if game is paused
	invoke GameTick

	SKIP_TICK:
	invoke DrawBoard

	

	ret         ;; Do not delete this line!!!
GamePlay ENDP



CheckIntersect PROC USES ebx ecx oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 

	;;Going with axis alligned bounding boxes here
	LOCAL x1:DWORD, x2:DWORD, y1:DWORD, y2:DWORD, h1:DWORD, h2:DWORD, w1:DWORD, w2:DWORD

	;;Setting up locals
	mov ecx, oneBitmap
	mov eax, [ecx]
	mov w1, eax
	mov eax, [ecx + 4]
	mov h1, eax

	mov ecx, twoBitmap
	mov eax, [ecx]
	mov w2, eax
	mov eax, [ecx + 4]
	mov h2, eax

	;;Divide the height by two and subtract from y1 to get y corner
	mov eax, h1
	shr eax, 1
	mov ebx, oneY
	sub ebx, eax
	mov y1, ebx

	;;Divide the width by two and subtract from x1 to get x corner
	mov eax, w1
	shr eax, 1
	mov ebx, oneX
	sub ebx, eax
	mov x1, ebx

	;;Divide hgith by two and subtract from y2 to get y corner
	mov eax, h2
	shr eax, 1
	mov ebx, twoY
	sub ebx, eax
	mov y2, ebx

	;;Divide width by two and subtract from x2 to get x corner
	mov eax, w2
	shr eax, 1
	mov ebx, twoX
	sub ebx, eax
	mov x2, ebx

;;Collision checking
	mov eax, x2
	add eax, w2
	cmp x1, eax
	jge NO_COL

	mov eax, x1
	add eax, w1
	cmp x2, eax
	jge NO_COL

	mov eax, y2
	add eax, h2
	cmp y1, eax
	jge NO_COL

	mov eax, y1
	add eax, h1
	cmp y2, eax
	jge NO_COL


	mov eax, 1
	ret

NO_COL:

	mov eax, 0
	ret

CheckIntersect ENDP







END
