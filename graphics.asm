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

.DATA


.CODE

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Draws the current score;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawScore PROC USES ebx ecx edx esi edi score:DWORD


    ret

DrawScore ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Draws the entire tetris board on the screen;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawBoard PROC USES ebx ecx edx esi edi

    ;;Loop through the entire board, 24 rows, 10 cols

    ;;ebx and ecx will be loop counters

    mov ebx, 0 ;;row
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

DrawCell PROC USES ebx ecx edx edi x:DWORD, y:DWORD, color:DWORD

    ;;Loop counters will be ebx for outer and ecx for inner

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


END