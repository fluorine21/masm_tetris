; #########################################################################
;
;   tetris.asm - Core tetris game
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

;;Arnoldo?
;;Test change
include tetris.inc
include graphics.inc
include keys.inc
include game.inc

.DATA

;;This is the main state of the tetris game
;;Upper half of the word is the state, lower half of the word is the color
;;Grid size is 24 rows 10 cols, so we'll store it as effective addr = col*24 + row
;;Starting upper left moving down
;;Initializing with BACKGROUND_CELL to create white background and empty type field
tetris_board WORD (24*10) DUP (BACKGROUND_CELL)

;;States:
;;-1 = empty
;;0 = static (non-moving) block
;;'L' = L block center
;;'T' = T block center
;;'I' = I block center
;;'Z' = Z block center
;;'S' = S block center
;;'O' = O block center
;;'J' = J block center
;;'1' = active piece

;;Before we do a rotation we check the state


;; Stores the row and col of the center of the block, this is used to quickly find the block in the board
;; = -1 if no block is present (about to add another)
curr_row DWORD -1 
curr_col DWORD -1


;;Stores the default locations for creating new pieces

;;L piece coordinates (row,col): (0, 3), (1, 3), (0, 4), (0, 5)
L_piece PIECE_STRUCT<0, 3, 1, 3, 0, 4, 0, 5>

;;I Piece coordinates (row,col): (0, 2), (0, 3), (0, 4), (0, 5)
I_piece PIECE_STRUCT<0, 2, 0, 3, 0, 4, 0, 5>

;;T Piece coordinates (row,col): (0, 3), (1, 4), (0, 4), (0, 5)
T_piece PIECE_STRUCT<0, 3, 1, 4, 0, 4, 0, 5>

;;Z Piece coordinates (row,col): (0, 3), (0, 4), (1, 4), (1, 5)
Z_piece PIECE_STRUCT<0, 3, 0, 4, 1, 4, 1, 5>

;;S Piece coordinates (row,col): (1, 3), (1, 4), (0, 4), (0, 5)
S_piece PIECE_STRUCT<1, 3, 1, 4, 0, 4, 0, 5>

;;O Piece coordinates (row,col): (1, 3), (0, 3), (1, 4), (0, 4)
O_piece PIECE_STRUCT<1, 3, 0, 3, 1, 4, 0, 4>

;;J Piece coordinates (row,col): (1, 5), (0, 5), (0, 4), (0, 3)
J_piece PIECE_STRUCT<1, 5, 0, 5, 0, 4, 0, 3>


;;Global variables used to time when pieces move down
TICK_HIGH DWORD 0
TICK_LOW DWORD 0
TICK_COUNT DWORD 0

;;Grid for rotation
newGrid DWORD 25 DUP (0)

;;Score counter 
row_score DWORD 0

;;Level counter
level_num DWORD 1

;;Tells us if the game is over
game_over BYTE 0

;;Tick for changing background
background_tick BYTE 0


.CODE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Checks if the game is over;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Game is over if any cemented pieces appear in second row (1);;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameOverCheck PROC USES ebx ecx edx esi edi

    ;;Loop through the second row
    mov ebx, 0
    L1:
    cmp ebx, 10
    jge END1

        ;;Load the value here
        invoke GetBoardLocType, 4, ebx
        cmp eax, 0
        jne END2 ;;If this isn't a cemented piece then we don't care

        ;;Game over conditon has been met 
        invoke GameOver


    END2:

    inc ebx
    jmp L1
    END1:


    ret

GameOverCheck ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Displays game over message and calls reset when user presses esc;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameOver PROC USES ebx ecx edx esi edi

    ;;Draw the game over message
    invoke DrawGameOver

    ;;set the game over flag
    mov game_over, 1

    ret

GameOver ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;
;;Resets the game state;;
;;;;;;;;;;;;;;;;;;;;;;;;;

ResetGame PROC USES ebx ecx edx

    cmp game_over, 1 ;;If the game is actually over
    je GAME_OVER
    ret

    GAME_OVER:
    ;;Reset the game over flag
    mov game_over, 0

    ;;Remove the game over text
    invoke RemoveGameOver

    ;;Reset the row col pointers
    mov curr_row, -1
    mov curr_col, -1

    ;;Reset the score counter
    mov row_score, 0
    mov level_num, 1

    ;;Draw the score
    invoke DrawScore, 0
    invoke DrawLevel, 1

    ;;Write a background pixel to all board locations
    mov ebx, 0
    L1:
    cmp ebx, (24*10)
    jge END1
        
        mov [tetris_board + (ebx * 2)], BACKGROUND_CELL

    inc ebx
    jmp L1
    END1:


    ;;Call UpdateBoard to add the first piece
    invoke UpdateBoard
    ret


ResetGame ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Checks if there are any completed rows that need to be removed;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CompleteRowsCheck PROC USES ebx ecx edx esi edi

    ;;Need to loop through all of the rows and see if we find a complete row
    ;;If we find a complete row, we need to shift the above rows down, and then call this function again

    mov ebx, 23
    L1:
    cmp ebx, 0
    jl END1

        ;;Checking one of the rows here

        mov ecx, 0
        L2:
        cmp ecx, 10
        jge END2

            ;;Check if this cell is static (0)
            invoke GetBoardLocType, ebx, ecx
            cmp eax, 0
            jne END2 ;; If this cell isn't static then skip this row

            ;;This cell must be static

            ;;Check if we're on the last cell, if we are, we must be at the end of a complete row
            cmp ecx, 9
            jne END3 ;; Need to keep checking, just jump to end of inner loop

            ;;If we're here, the row is complete
            ;;Remove it, call this function again and return
            invoke ShiftRowsDown, ebx

            ;;If the score is a multiple of 10 then reset it and increment the level
            mov eax, row_score
            xor edx, edx
            mov esi, 10
            div esi
            cmp edx, 0
            jne L8
            cmp row_score, 0
            je L8 ;; Make sure the score isn't just 0

            ;;Must be a multiple of 20
            inc level_num
            mov row_score, 0
            jmp L9

            L8:
            inc row_score

            L9:

            invoke DrawScore, row_score
            invoke DrawLevel, level_num

            invoke CompleteRowsCheck

            ret

        END3:
        inc ecx
        jmp L2
        END2:

    dec ebx
    jmp L1
    END1:



    ret

CompleteRowsCheck ENDP


ShiftRowsDown PROC USES ebx ecx edx esi edi row_num:DWORD

    ;;make two loops, rows outside cols inside
    ;;start at row_num and go to 0, copying everything down 1

    mov ebx, row_num
    L1:
    cmp ebx, 0 
    jl END1

        mov ecx, 0
        L2:
        cmp ecx, 10
        jge END2

            ;;Inner loop body
            mov edx, ebx
            dec edx ;; copying from upper row

            ;;Copy the cell value down one row
            invoke GetBoardLoc, edx, ecx

            cmp ebx, 0
            jne SKIP_BACKGROUND

            mov eax, 0
            mov ax, BACKGROUND_CELL 

            SKIP_BACKGROUND:

            invoke SetBoardLoc, ebx, ecx, eax

        inc ecx
        jmp L2
        END2:

    dec ebx
    jmp L1
    END1:


    ret

ShiftRowsDown ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Takes the current dynamic piece and turns it into a static piece;;
;;Also sets curr_row and curr_col to -1;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CementPiece PROC USES eax ebx ecx edx esi edi

;;Need another 5x5 loop to go through all positions and set their type to 0
;;ecx and edx will be the outer and inner loop counters
;;esi and edi will hold the full row/col positions respectively

    mov ecx, -2

L1:
    cmp ecx, 2
    jg END1

        mov edx, -2

    L2:
        cmp edx, 2
        jg END2

            ;;Inner loop body
            ;;Calculat the full row col addresses
            mov esi, curr_row
            add esi, ecx
            mov edi, curr_col
            add edi, edx

            ;;Check to make sure this address is in bounds
            invoke CheckAddr, esi, edi
            cmp eax, 0
            je END3

            ;;Must be a valid address, look-up the block type
            invoke GetBoardLocType, esi, edi
            
            ;;If the board type is not 1, we don't care
            cmp eax, 1
            jne END3

            ;;We're here, so we must be looking at an active piece
            ;;Just set the piece type to 0 and continue
            invoke SetBoardLocType, esi, edi, 0

    END3:
        inc edx
        jmp L2

END2:
    inc ecx
    jmp L1

END1:

    ;;Set curr_row and curr_col to -1
    mov curr_row, -1
    mov curr_col, -1

    ;;Check if the game is over
    invoke GameOverCheck

    ;;Check if there are any completed rows
    invoke CompleteRowsCheck
    
    ret



CementPiece ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Adds a new piece to the top of the board;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPiece PROC USES eax ebx ecx edx esi edi

    LOCAL color:DWORD

    ;;Need to add another local for the piece pointer
    LOCAL piece_ptr:PTR PIECE_STRUCT

    ;;Generate a random number to select the new piece
    rdtsc ;; get the cycle count in {edx, eax}
    xor edx, edx ;; zero out edx
    mov ebx, 7 ;;take modulo 7 to choose one piece
    div ebx ;; result is in edx

    ;;Store a random color
    mov color, eax
    ;;mov color, 0aah

    ;;LTIZSOJ

    ;;Need only I pieces
    ;;mov edx, 1

    ;;Multiply the value in edx by the size of the piece struct
    mov eax, edx
    shl eax, 5;;offset to correct piece is now in eax

    mov piece_ptr, offset L_piece
    add piece_ptr, eax ;;Now piece_ptr should point to our randomly selected piece


    ;;Now we just need to loop through all of the elements of the struct to set the locations correctly
    ;;TODO

    ;;ebx will be our loop counter
    mov ebx, 0

L1: cmp ebx, 4
    jge END1

        ;;Loop body

        ;;Need to calculate the effective row col addresses

        ;;Multiply ebx by 8 first
        mov ecx, ebx
        shl ecx, 3

        ;;Then add the starting address of our chosen shape
        add ecx, piece_ptr

        ;;edi and esi will hold the row and col
        mov edi, [ecx]
        mov esi, [ecx+4]

        ;;Set the piece and color values
        invoke SetBoardLocColor, edi, esi, color
        invoke SetBoardLocType, edi, esi, 1

        cmp ebx, 1
        jne L2
        mov curr_row, edi
        mov curr_col, esi

    L2:

    inc ebx
    jmp L1

END1:
    

    
    ret
AddPiece ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Takes the row/col val and returns the value of the cell type at that location;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetBoardLocType PROC USES ebx edx row:DWORD, col:DWORD

    mov eax, col
    mov ebx, 24
    mul ebx
    add eax, row

    movsx ebx, [tetris_board + (eax * 2)]
    sar ebx, 8 ;; get rid of the color value, arithmetic shift to preserve leading ones if cell is empty
    mov eax, ebx
    ret

GetBoardLocType ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Takes the row/col val and returns the value of the entire cell at that location;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetBoardLoc PROC USES ebx edx row:DWORD, col:DWORD

    mov eax, col
    mov ebx, 24
    mul ebx
    add eax, row

    movsx eax, [tetris_board + (eax * 2)]
    ret

GetBoardLoc ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Sets the entire cell of a specific row col board location;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetBoardLoc PROC USES eax ebx ecx edx row:DWORD, col:DWORD, val:DWORD

    mov eax, col
    mov ebx, 24
    mul ebx
    add eax, row

    mov ebx, val
    mov [tetris_board + (eax * 2)], bx

    ret

SetBoardLoc ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Sets the cell type of a specific row col board location;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetBoardLocType PROC USES ebx ecx edx row:DWORD, col:DWORD, val:DWORD

    mov eax, col
    mov ebx, 24
    mul ebx
    add eax, row

    xor ebx, ebx
    movsx ebx, [tetris_board + (eax * 2)]

    ;;Now get val into the correct position in ch
    mov ecx, val
    shl ecx, 8

    ;;Now move in the new value and write it back to the board
    mov bh, ch
    mov [tetris_board + (eax * 2)], bx
    ret

SetBoardLocType ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Sets the cell color of a specific row col board location;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetBoardLocColor PROC USES ebx ecx edx row:DWORD, col:DWORD, val:DWORD

    mov eax, col
    mov ebx, 24
    mul ebx
    add eax, row

    movsx ebx, [tetris_board + (eax * 2)]

    ;;Now get val into the correct position in ch
    mov ecx, val
    

    ;;Now move in the new value and write it back to the board
    mov bl, cl
    mov [tetris_board + (eax * 2)], bx
    ret

SetBoardLocColor ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Updates the current state of the tetris board either by moving a block;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateBoard PROC USES eax ebx ecx edx esi edi

;;If the piece cannot be moved down further, we just change the state to 0 and the current row to -1 and return
;;If the piece can be moved down (nothing below), then we just move it down
;;If the current row is -1, we need to spawn a piece


NOT_GAME_OVER:

    ;;If we need to add a piece
    cmp curr_row, -1
    jne SKIP_ADD

    invoke AddPiece;;Just need to add a piece and return
    ret

    

SKIP_ADD:

    ;;Form a 5x5 search grid originating from the center
    ;;Search for any value that isnt empty or static
    ;;If we find that any of these values is directly above a static piece, 
    ;;then cement the block and call RowCheck to see if we need to remove a row

    ;;

    ;;edi will be row offset, ebx will be col offset
    mov edi, -2


L1: ;;Outer 5x5 loop check
    cmp edi, 2
    jg END1

        mov ebx, -2
    L2: ;;Inner loop check
        cmp ebx, 2
        jg END2

            ;;5x5 inner loop body
            ;;ecx and edx will hold the full row and col position respectively
            ;;Make sure that spot to check falls within board

            mov ecx, edi
            add ecx, curr_row

            mov edx, ebx
            add edx, curr_col

            invoke CheckAddr, ecx, edx
            cmp eax, 1
            jne END3

            ;;Must be in bounds and not at the bottom of the row
            ;;Get the value of the piece at this location
            invoke GetBoardLocType, ecx, edx

            ;;Value is in eax

            ;;If this value is empty or has a static block
            cmp eax, 1
            jne END3;;then skip this location

            ;;This value must be an active game piece

            ;;If we're at the bottom of the bord (row 24)
            cmp ecx, 23
            je CEMENT ;; Then we need to cement the piece

            
            ;;Get the value of the block below it
            add ecx, 1
            invoke GetBoardLocType, ecx, edx
            ;;Answer is in eax

            ;;If the block below is 0 (static block)
            cmp eax, 0
            je CEMENT ;;Then we need to cement it


            ;;All is well, continue to next loop iteration
            jmp END3


        CEMENT: ;; sets the current block in its place and sets curr_row and curr_col to -1
            invoke CementPiece
            ret;;We're done, no need to do anything else


        END3: ;;End of inner loop body
        ;;Increment of inner 5x5 loop
            inc ebx
            jmp L2
    END2: ;;End of inner 5x5 loop
        inc edi
        jmp L1


END1: ;;End of 5x5 loop


    ;;Don't need to cement, just need to shift piece down by 1
    ;;Need to start search grid from bottom left, row offset > 0 and col offset < 0
    invoke ShiftPieceDown
    ret

UpdateBoard ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Shifts a single board block down by 1;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ShiftBlockDown PROC USES eax ebx edx row:DWORD, col:DWORD

    ;;Addr calculation
    mov eax, col
    mov ebx, 24
    mul ebx
    add eax, row

    movsx ebx, [tetris_board + (eax * 2)] ;; ebx holds the value we need to write to one below
    mov [tetris_board + (eax * 2)], BACKGROUND_CELL ;;overwrite old spot with a -1
    inc eax
    mov [tetris_board + (eax * 2)], bx ;;move the block down 1
    ret

ShiftBlockDown ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Shifts the active piece down by 1;;
;;    Also increments curr_row     ;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShiftPieceDown PROC USES ebx ecx edx esi edi

    ;;Need to start search grid from bottom left, row offset > 0 and col offset < 0
    mov edi, 2
    mov ebx, -2

L1: ;;Outer 5x5 loop check
    cmp edi, -2
    jl END1

    mov ebx, -2
L2: ;;Inner loop check
    cmp ebx, 2
    jg END2

    ;;Inner loop body
    ;;ecx and edx will hold the full row and col position respectively
    ;;Make sure that spot to check falls within board

    mov ecx, edi
    add ecx, curr_row

    mov edx, ebx
    add edx, curr_col

    invoke CheckAddr, ecx, edx
    cmp eax, 1
    jne END3


    ;;row and col are within the board
    invoke GetBoardLocType, ecx, edx

    ;;If this piece is not a the active board piece
    cmp eax, 1
    jne END3

    ;;Must be an active board piece
    ;;Just shift it down 1
    invoke ShiftBlockDown, ecx, edx

    ;;Need to check if we're at the upper boundary here
    ;;If so, write 0 to the cells this piece is leaving

    ;;Or we can just write a 0 to the current location now that we've shifted it down
    invoke SetBoardLocType, ecx, edx, -1 ;;Set it to be empty


END3:
    inc ebx
    jmp L2

END2:
    dec edi
    jmp L1

END1:

;;increment curr_row
    inc curr_row

    ret


ShiftPieceDown ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Shifts a piece either left or right;;
;;Left if dir is 0, right otherwise;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShiftPiece PROC USES eax ebx ecx edx esi edi dir:BYTE

    LOCAL off_set:DWORD

    ;;Check if we're moving left or right
    movsx eax, dir
    cmp eax, 0
    je LEFT
    mov off_set, 1
    jmp END_CHECK
LEFT:
    mov off_set, -1

END_CHECK:

;;First we need to check to make sure we're allowed to shift the piece
;;Loop through the 5x5 grid and check for anything to the left or right of a block

;;edi will be outer loop, ebx will be inner loop
    mov edi, -2

L1: ;;Outer loop check
    cmp edi, 2
    jg END1

    mov ebx, -2
    L2: ;;Inner loop check
    cmp ebx, 2
    jg END2

            ;;Inner loop body
            ;;Need to calculate the actual row col address based on the edi and ebx offsets
            ;;ecx will hold full row, edx will hold full col
            mov ecx, edi
            add ecx, curr_row

            mov edx, ebx
            add edx, curr_col

            invoke CheckAddr, ecx, edx
            cmp eax, 1
            jne OUT_OF_BOUNDS

            ;;Not trying to read from a cell that is out of bounds
            ;;Now we need to check the current cell value and make sure it corresponds to the active piece
            invoke GetBoardLocType, ecx, edx

            ;;Result is in eax
            cmp eax, 1 ;;Skip this ine if it's not an active piece
            jne OUT_OF_BOUNDS

            ;;We're here, so the cell must contain an active piece
            ;;Add the col offset to edx and check to see if it's in bounds

            mov esi, edx
            add esi, off_set

            cmp esi, -1 ;;If we're out of bounds here we just need to return
            je SKIP_SHIFT
            cmp esi, 10
            je SKIP_SHIFT

            ;;If we're here, we need to load in the piece and check the value
            invoke GetBoardLocType, ecx, esi

            cmp eax, 0 ;;If eax has a 0 in it, then there is a static piece adjacent to the dynamic piece
            je SKIP_SHIFT


    OUT_OF_BOUNDS: ;;Jump here if current offset is not within the board

    END3: ;;end of inner loop body
        inc ebx
        jmp L2

END2: ;;End of inner for loop
    inc edi
    jmp L1

;;Then we need to actually shift the piece

END1: ;;End of checking loop
    ;;If we got here, then we need to shift the piece left or right
    
    invoke ShiftPieceLR, off_set
    mov ebx, off_set
    add curr_col, ebx

SKIP_SHIFT:

    ret

ShiftPiece ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Function which performs the actual shift after ShiftPiece has checked to make sure it is ok to do so;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShiftPieceLR PROC USES eax ebx ecx edx esi edi off_set:DWORD

    ;;edi and ebx will be the outer and inner loop variables

    mov edi, -2

    L1:
    cmp edi, 2
    jg RT

        mov ebx, -2

        L2: cmp ebx, 2
        jg END1

            mov edx, curr_col
            ;;To calculate the current col, we need to check off_set
            ;;If offset is -1 (left), then we need to add ebx to curr_col, otherwise subtract
            cmp off_set, -1
            jne SUB_OFF
            add edx, ebx
            jmp END_OFF
SUB_OFF:
            sub edx, ebx
END_OFF:

            ;;Now calculate the current row
            mov ecx, curr_row
            add ecx, edi

            ;;Do the constraint checking to make sure we're in bounds
            invoke CheckAddr, ecx, edx

            ;;If the address is bad, go to END2 to get next addr
            cmp eax, 1
            jne END2

            ;;Check if this is an active piece
            invoke GetBoardLocType, ecx, edx
            cmp eax, 1
            jne END2 ;; If this isn't an active piece then skip it

            invoke GetBoardLoc, ecx, edx;;Save the old location value
            mov esi, eax ;;Save eax

            invoke SetBoardLoc, ecx, edx, -1

            add edx, off_set
            
            invoke SetBoardLoc, ecx, edx, esi


        END2:

        inc ebx
        jmp L2

    END1:
    inc edi
    jmp L1

RT:
    ret

ShiftPieceLR ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Rotates a piece either clockwise or counterclockwise;;
;;clockwise if dir is 0, counterclockwise otherwise;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RotatePiece PROC USES eax ebx ecx edx esi edi dir:DWORD


    ;;Clockwise: xn = y, yn = -x
    ;;Conterclockwise: xn = -y, yn = x

    ;;These hold the future location of a cell after rotation
    LOCAL R_N:DWORD, C_N:DWORD


    ;;Make a 5x5 loop with ebx and ecx as loop conters
    mov ebx, -2

    L1:
    cmp ebx, 2
    jg END0

        mov ecx, -2
        L2:
        cmp ecx, 2
        jg END1

            ;;Loop body

            ;;First we need to get the current cell to see if it is active
            mov esi, curr_row
            add esi, ebx
            mov edi, curr_col
            add edi, ecx
            invoke CheckAddr, esi, edi
            cmp eax, 1
            jne END3 ;; If this address is out of bounds then skip it

            ;;Check the value at this cell
            invoke GetBoardLocType, esi, edi
            cmp eax, 1
            jne END3 ;; If this cell does not contain an active piece then skip it

            ;;This cell has an active piece, we need to compute the address of where it is going
            cmp dir, 0
            jne CCLOCK

            ;;We are rotating clockwise
            ;;eax is next row offset, edx is next col offset
            ;;Clockwise: xn = y, yn = -x
            mov eax, ecx
            mov edx, ebx
            neg edx
            jmp CALC_END

        CCLOCK:

            ;;We are rotating clockwise
            ;;eax is next row offset, edx is next col offset
            ;;Conterclockwise: xn = -y, yn = x
            mov eax, ecx
            neg eax
            mov edx, ebx

        CALC_END:

            ;;Don't need esi or edi any more
            mov esi, curr_row
            mov R_N, esi
            add R_N, eax
            mov esi, curr_col
            mov C_N, esi
            add C_N, edx

            ;;R_N and C_N now contain the address of our destination
            ;;Check to see if the address is in bounds
            invoke CheckAddr, R_N, C_N
            cmp eax, 1
            jne SKIP_ROT

            ;;Check to see if there is an cemented piece at this address
            invoke GetBoardLocType, R_N, C_N
            cmp eax, 0
            je SKIP_ROT

            ;;Must be able to rotate this particular cell

        END3:
        inc ecx
        jmp L2
    END1:

    inc ebx
    jmp L1
END0:

    ;;If we're here, we can safetly rotate the piece
    invoke RotatePieceLR, dir

SKIP_ROT:

    ret
RotatePiece ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Clears the newGrid array;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ClearNewGrid PROC USES ebx ecx

    mov ebx, 0
    L1:
    cmp ebx, 25
    jge END1

        mov [newGrid + (ebx * 4)], 0

    inc ebx
    jmp L1
    END1:
    ret

ClearNewGrid ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Implements the actual rotation of a piece;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RotatePieceLR PROC USES eax ebx ecx edx esi edi dir:DWORD




    ;;This is temp storage for a cell value
    LOCAL tempCell:DWORD


    ;;Don't try rotating if we're close to the top
    cmp curr_row, 1
    jg CONT
    ret

CONT:

    ;;Clear the newGrid array
    invoke ClearNewGrid

    ;;Make a 5x5 loop with ebx and ecx as loop conters
    mov ebx, -2

    L1:
    cmp ebx, 2
    jg END0

        mov ecx, -2
        L2:
        cmp ecx, 2
        jg END1

            ;;Loop body

            ;;First we need to get the current cell to see if it is active
            mov esi, curr_row
            add esi, ebx
            mov edi, curr_col
            add edi, ecx
            invoke CheckAddr, esi, edi
            cmp eax, 1
            jne END3 ;; If this address is out of bounds then skip it

            ;;Check if the cell is active
            invoke GetBoardLocType, esi, edi
            cmp eax, 1
            jne END3 ;; If it is inactive then skip it

            ;;This cell is in bounds and is active, we need to compute the address of where it is going
            cmp dir, 0
            jne CCLOCK

            ;;We are rotating clockwise
            ;;eax is next row offset, edx is next col offset
            ;;Clockwise: xn = y, yn = -x
            mov eax, ecx
            mov edx, ebx
            neg edx
            jmp CALC_END

        CCLOCK:

            ;;We are rotating clockwise
            ;;eax is next row offset, edx is next col offset
            ;;Conterclockwise: xn = -y, yn = x
            mov eax, ecx
            neg eax
            mov edx, ebx

        CALC_END:

            ;;Save the value of the old cell
            push eax
            invoke GetBoardLoc, esi, edi
            mov tempCell, eax
            pop eax

            ;;eax and edx contain the new offsets we need to use to rotate the piece
            ;;Need to use them to calculate the matrix address
            ;;Address defined as ((col+2)*5) + row + 2
            mov esi, eax
            mov edi, edx
            mov eax, 2
            add eax, edi
            imul eax, 5
            add eax, esi
            add eax, 2

            ;;store the value of tempCell at newGrid[eax]
            mov esi, tempCell
            mov [newGrid + (eax * 4)], esi

        END3:
        inc ecx
        jmp L2
    END1:

    inc ebx
    jmp L1
END0:

;;Here we need to remove the old piece from the board

invoke RemoveOldPiece

;;Now we need to do another 5x5 loop to actually write the grid

   mov ebx, -2
   L3:
   cmp ebx, 2
   jg END4

        mov ecx, -2
        L4:
        cmp ecx, 2
        jg END5

            ;;Loop body

            ;;First we need to get the current cell to see if it is active
            mov esi, curr_row
            add esi, ebx
            mov edi, curr_col
            add edi, ecx
            invoke CheckAddr, esi, edi
            cmp eax, 1
            jne END6 ;; If this address is out of bounds then skip it

            ;;Address must be in bounds
            ;;Address defined as ((col+2)*5) + row + 2
            mov eax, ecx
            add eax, 2
            imul eax, 5
            add eax, ebx
            add eax, 2

            ;;Value we need to write to this location is in edx
            mov edx, [newGrid + (eax * 4)]

            ;;Check if the cell is active
            cmp dh, 1
            jne END6 ;; Skip this cell if it is inactive
            
            ;;Cell must be active, write it into the board
            invoke SetBoardLoc, esi, edi, edx

        END6:
        inc ecx
        jmp L4
    END5:
    inc ebx    
    jmp L3
END4:

    
ret

    
RotatePieceLR ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Removes the old un-rotated piece from the board;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveOldPiece PROC USES eax ebx ecx edx esi edi

    ;;Loop over the whole board and replace all active cells with the background cell
    mov ebx, 0
    L1:
    cmp ebx, (24*10)
    jge END1

        ;;Check if this piece is active
        mov ax, [tetris_board + (ebx * 2)]
        cmp ah, 1
        jne END2 ;; Skip if this cell is inactive

        ;;Must be active, overrite with BACKGROUND_CELL
        mov [tetris_board + (ebx * 2)], BACKGROUND_CELL

    END2:
    inc ebx
    jmp L1
    END1:

    ret
RemoveOldPiece ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Checks to make sure the address is in bounds, returns 1 if yes;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckAddr PROC row:DWORD, col:DWORD

    mov eax, 1
    cmp row, 0
    jl RT
    cmp row, 24
    jge RT
    cmp col, 0
    jl RT
    cmp col, 10
    jge RT
    ret

RT:
    mov eax, 0
    ret

CheckAddr ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Calls UpdateBoard if a set ammount of time has passed;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameTick PROC USES eax ebx ecx edx esi edi

    cmp game_over, 1 ;;If we're in the game over state just return
    jne NOT_GAME_OVER
    ret

    NOT_GAME_OVER:

    ;;If TICK_HIGH is 0, then this is the first function call
    ;;We need to set up the tick counter
    cmp TICK_HIGH, 0
    jne SKIP_SETUP

    ;;Set up the counter
    rdtsc
    mov TICK_LOW, eax
    mov TICK_HIGH, edx
    ret

SKIP_SETUP:

    rdtsc
    sub eax, TICK_LOW
    ;;If the counter has not been triggered
    cmp eax, TICK_CYCLES
    jl RT

    ;;Counter must be triggered

    ;;Increment the global counter
    inc TICK_COUNT

    ;;Reset the local counter
    rdtsc
    mov TICK_LOW, eax
    mov TICK_HIGH, edx

    invoke GetTickMax
    cmp TICK_COUNT, eax
    jl RT

    ;;Reset the tick count
    mov TICK_COUNT, 0

    ;;Invoke UpdateBoard
    invoke UpdateBoard
    inc background_tick


RT:
    ret


GameTick ENDP



GetTickMax PROC USES ebx ecx edx

    mov ebx, level_num
    ;;add ebx, 1
    dec ebx
    shr ebx, 1
    mov eax, TICK_MAX
    sub eax, ebx
    ret

GetTickMax ENDP




END