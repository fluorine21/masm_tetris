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

.DATA

;;This is the main state of the tetris game
;;Upper half of the word is the state, lower half of the word is the color
;;Grid size is 24 rows 10 cols, so we'll store it as effective addr = col*24 + row
;;Starting upper left moving down
tetris_board WORD (24*10) DUP (0ffffh)

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

;;Z Piece coordinates (row,col): (2, 3), (1, 3), (1, 4), (0, 4)
Z_piece PIECE_STRUCT<2, 3, 1, 3, 1, 4, 0, 4>

;;S Piece coordinates (row,col): (2, 4), (1, 4), (1, 3), (0, 3)
S_piece PIECE_STRUCT<2, 3, 1, 3, 1, 3, 0, 3>

;;O Piece coordinates (row,col): (1, 3), (0, 3), (1, 4), (0, 4)
O_piece PIECE_STRUCT<1, 3, 0, 3, 1, 4, 0, 4>

;;J Piece coordinates (row,col): (1, 5), (0, 5), (0, 4), (0, 3)
J_piece PIECE_STRUCT<1, 5, 0, 5, 0, 4, 0, 3>




.CODE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Takes the current dynamic piece and turns it into a static piece;;
;;Also sets curr_row and curr_col to -1;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CementPiece PROC USES eax ebx ecx edx



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
    ;;mov color, eax
    mov color, 0aah

    ;;LTIZSOJ

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
GetBoardLocType PROC USES ebx row:DWORD, col:DWORD

    mov eax, col
    mov ebx, 24
    mul ebx
    add eax, row
    xor ebx, ebx
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

SetBoardLoc PROC USES ebx ecx edx row:DWORD, col:DWORD, val:DWORD

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
            invoke GetBoardLoc, ecx, edx

            ;;Value is in eax

            ;;If this value is empty or has a static block
            cmp eax, 0
            jle END3;;then skip this location

            ;;This value must be an active game piece

            ;;If we're at the bottom of the bord (row 24)
            cmp ecx, 23
            je CEMENT ;; Then we need to cement the piece

            
            ;;Get the value of the block below it
            add ecx, 1
            invoke GetBoardLoc, ecx, edx
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
ShiftBlockDown PROC USES eax ebx row:DWORD, col:DWORD

    ;;Addr calculation
    mov eax, col
    mov ebx, 24
    mul ebx
    add eax, row

    movsx ebx, [tetris_board + (eax * 2)] ;; ebx holds the value we need to write to one below
    mov [tetris_board + (eax * 2)], 0ffffh ;;overwrite old spot with a -1
    inc eax
    mov [tetris_board + (eax * 2)], bx ;;move the block down 1
    ret

ShiftBlockDown ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Shifts the active piece down by 1;;
;;    Also increments curr_row     ;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShiftPieceDown PROC USES eax ebx ecx edx esi

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
    invoke GetBoardLoc, ecx, edx

    ;;If this piece is not a the active board piece
    cmp eax, 0
    jle END3

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

ShiftPiece PROC USES eax ebx ecx edx esi dir:BYTE

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
    mov ebx, -2

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
            invoke GetBoardLoc, ecx, edx

            ;;Result is in eax
            cmp eax, 0
            je OUT_OF_BOUNDS ;;skip if this cell is static
            cmp eax, -1
            je OUT_OF_BOUNDS ;;Skip if this cell is empty

            ;;We're here, so the cell must contain an active piece
            ;;Add the col offset to edx and check to see if it's in bounds

            ;;TODO

            mov esi, edx
            add esi, off_set

            cmp esi, -1 ;;If we're out of bounds here we just need to return
            je SKIP_SHIFT
            cmp esi, 10
            je SKIP_SHIFT

            ;;If we're here, we need to load in the piece and check the value
            invoke GetBoardLoc, ecx, esi

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

SKIP_SHIFT:

    ret

ShiftPiece ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Function which performs the actual shift after ShiftPiece has checked to make sure it is ok to do so;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShiftPieceLR PROC USES eax ebx ecx edx esi edi off_set:DWORD

    ;;edi and ebx will be the outer and inner loop variables

    mov edi, -2
    mov ebx, -2

    L1:
    cmp edi, 2
    jg RT

        mov ebx, -2
        L2: cmp ebx, 2
        jg END1

            mov ecx, curr_row
            ;;To calculate the current row, we need to check off_set
            ;;If offset is -1 (left), then we need to add edi to curr_row, otherwise subtract
            cmp off_set, -1
            jne SUB_OFF
            add ecx, edi
            jmp END_OFF
SUB_OFF:
            sub ecx, edi
END_OFF:

            ;;Now calculate the current column
            mov edx, curr_col
            add edx, ebx

            ;;Do the constraint checking to make sure we're in bounds
            invoke CheckAddr, ecx, edx

            ;;If the address is bad, go to END2 to get next addr
            cmp eax, 1
            jne END2

            ;;Address is good, we just need to move the current value over by off_set and write a 0 to the old location
            invoke GetBoardLoc, ecx, edx

            mov esi, eax ;;Save eax

            invoke SetBoardLoc, ecx, edx, -1

            add ecx, off_set
            
            invoke SetBoardLoc, ecx, edx, esi


        END2:

        inc ebx
        jmp L2

    END1:
    inc eax

RT:
    ret

ShiftPieceLR ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Rotates a piece either clockwise or counterclockwise;;
;;clockwise if dir is 0, counterclockwise otherwise;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RotatePiece PROC USES eax ebx ecx edx dir:BYTE

;;Need to define rotation matricies and use them with forloop for this function


RotatePiece ENDP

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




END