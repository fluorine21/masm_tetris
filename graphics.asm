; #########################################################################
;
;   graphics.asm - screen draw routines
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive


include blit.inc
include tetris.inc
include graphics.inc
include game.inc
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib
include images.inc

.DATA

;;This is used to print the score to the screen
fmtStr BYTE "score: %d", 0
outStr BYTE 256 DUP(0)

levelFmtStr BYTE "Level: %d", 0
outLevel BYTE 256 DUP (0)

gameOverStr BYTE "GAME OVER!", 0

gamePausedStr BYTE "GAME PAUSED", 0


colorTable BYTE 224, 28, (3 + 8), (224+28), (224+3), (28+3), 077h, 088h, 099h, 0aah, 0bbh, 0cch, 0ddh, 0eeh, 011h, 022h


.CODE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Draws the game paused message;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawGamePaused PROC USES ebx ecx edx

    invoke DrawStr, offset gamePausedStr, GAME_PAUSED_C, GAME_PAUSED_R, 255
    ret

DrawGamePaused ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Removes the game paused message;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveGamePaused PROC USES ebx ecx edx

    invoke DrawStr, offset gamePausedStr, GAME_PAUSED_C, GAME_PAUSED_R, 0
    ret

RemoveGamePaused ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Draws the game over message;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawGameOver PROC USES ebx ecx edx

    invoke DrawStr, offset gameOverStr, GAME_OVER_C, GAME_OVER_R, 255
    ret

DrawGameOver ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;
;;Draws the Tetris logo;;
;;;;;;;;;;;;;;;;;;;;;;;;;

DrawTetrisLogo PROC USES ebx ecx edx

    invoke BasicBlit, ADDR tetris_logo, TETRIS_LOGO_C, TETRIS_LOGO_R
    ret
DrawTetrisLogo ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Removes the game over message;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveGameOver PROC USES ebx ecx edx

    invoke DrawStr, offset gameOverStr, GAME_OVER_C, GAME_OVER_R, 0
    ret

RemoveGameOver ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Draws the current score;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawScore PROC USES ebx ecx edx esi edi score:DWORD

    ;;First we need to flush the old score
    ;;invoke FlushScore

    ;;First we need to draw over the old score with black text
    invoke DrawStr, offset outStr, SCORE_C, SCORE_R, 0

    ;;Then we'll go ahead and draw in the new score
    push score
    push offset fmtStr
    push offset outStr
    call wsprintf
    add esp, 12
    invoke DrawStr, offset outStr, SCORE_C, SCORE_R, 255
    ret

DrawScore ENDP

;;Draws the current level;;
DrawLevel PROC USES ebx ecx edx esi edi level:DWORD

    invoke DrawStr, offset outLevel, LEVEL_C, LEVEL_R, 0

    push level
    push offset levelFmtStr
    push offset outLevel
    call wsprintf
    add esp, 12
    invoke DrawStr, offset outLevel, LEVEL_C, LEVEL_R, 255
    ret

DrawLevel ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Draws the entire tetris board on the screen;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawBoard PROC USES ebx ecx edx esi edi

    ;;Draw the background first
    invoke DrawBackground
    invoke DrawTetrisLogo

    ;;Loop through the entire board, 24 rows, 10 cols

    ;;ebx and ecx will be loop counters

    mov ebx, 4 ;;row, start at 4 to have the correct size
    mov ecx, 0 ;;col


    L1:
    cmp ebx, 24
    jge END1

        mov ecx, 0
        L2: cmp ecx, 10
        jge END2

            ;;Loop body

            ;;First figure out what color this cell needs to be
            ;;Color will be stored in esi
            invoke GetBoardLoc, ebx, ecx
            and eax, 0ffh;;get rid of everything but the color
            mov esi, eax

            ;;edx and edi will hold the actual screen positions of each block
            ;;Calculate the full position by multiplying the row and col values by cell width

            mov edx, ebx
            mov edi, ecx
            shl edx, CELL_SHIFT
            shl edi, CELL_SHIFT
            add edx, R_OFFSET
            add edi, C_OFFSET

            ;;Draw the cell
            invoke DrawCell, edx, edi, esi

        inc ecx
        jmp L2

    END2:
    inc ebx
    jmp L1

    END1:

    ret


DrawBoard ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Draws a single cell at starting at position x,y, moving to +x -y;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawCell PROC USES eax ebx ecx edx edi x:DWORD, y:DWORD, color:DWORD

    ;;Loop counters will be ebx for outer and ecx for inner

    ;;If the color is 0xff, replace with 0x00
    mov eax, color
    cmp al, 0ffh
    jne SKIP_BACK_REPLACE

    ;;Replace the color with 0
    mov color, 0
    jmp L3

    SKIP_BACK_REPLACE:

    ;;Look up the corresponding color in the table and draw it
    and eax, 15
    movzx eax, [colorTable + eax]
    mov color, eax

    L3:

    mov ebx, 0
    mov ecx, 0

    L1:
    cmp ebx, CELL_SIZE
    jge RT

        mov ecx, 0
        L2:
        cmp ecx, CELL_SIZE
        jge END1

            ;;Calculate the full screen address
            ;;Offset should be added in the DrawBoard function
            mov edx, x
            add edx, ebx

            mov edi, y
            add edi, ecx

            invoke DrawPixel, edi, edx, color

        END2:
        inc ecx
        jmp L2


    END1:
    inc ebx
    jmp L1

RT:
    ret

DrawCell ENDP

;;Draws the background;;

DrawBackground PROC USES eax ebx ecx edx esi edi

    LOCAL curr_r:DWORD, curr_c:DWORD

    cmp game_over, 1
    jne NOT_GAME_OVER;; if the game isn't over then draw the background

    ;;If the game is over draw the skulls
    invoke DrawSkulls
    ret

    NOT_GAME_OVER:


    mov curr_r, 0
    mov curr_c, 0

    ;;Loop over the background pattern
    ;;ebx is outer, ecx is inner
    mov ebx, 0
    L1:
    cmp ebx, BACKGROUND_ROW_NUM
    jge END1

        mov ecx, 0
        L2:
        cmp ecx, BACKGROUND_COL_NUM
        jge END2
                
                ;;Inner body
                ;;check the status of background_tick
                test background_tick, 1
                jz INV_B

                ;;Check if we're on an even row
                test bl, 1
                jz INV1

                invoke BasicBlit, ADDR background_inv, curr_c, curr_r
                jmp END7

                INV1:
                invoke BasicBlit, ADDR background, curr_c, curr_r
                jmp END7

                INV_B:

                 ;;Check if we're on an even row
                test bl, 1
                jz INV2

                invoke BasicBlit, ADDR background, curr_c, curr_r
                jmp END7

                INV2:
                invoke BasicBlit, ADDR background_inv, curr_c, curr_r

                END7:
                add curr_c, 26

        inc ecx
        jmp L2


    END2:
    mov curr_c, 0
    add curr_r, 6
    inc ebx
    jmp L1
    END1:
    ret

DrawBackground ENDP


DrawSkulls PROC USES eax ebx ecx edx

    LOCAL curr_r:DWORD, curr_c:DWORD

    mov curr_r, 0
    mov curr_c, -9

    ;;Loop over the background pattern
    ;;ebx is outer, ecx is inner
    mov ebx, 0
    L1:
    cmp ebx, BACKGROUND_ROW_NUM
    jge END1

        mov ecx, 0
        L2:
        cmp ecx, (BACKGROUND_COL_NUM - 1)
        jge END2
                
                ;;Inner body
                
                invoke BasicBlit, ADDR skull, curr_c, curr_r

                END7:
                add curr_c, 32

        inc ecx
        jmp L2


    END2:
    mov curr_c, -9
    add curr_r, 33
    inc ebx
    jmp L1
    END1:
    ret



DrawSkulls ENDP

END