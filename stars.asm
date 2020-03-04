; #########################################################################
;
;   stars.asm - Assembly file for CompEng205 Assignment 1
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive


include stars.inc

.DATA


	

.CODE

DrawStarField proc

	;; Place your code here

    ;;Top of the J
    invoke DrawStar, 100, 200 
    invoke DrawStar, 110, 200 
    invoke DrawStar, 120, 200 
    invoke DrawStar, 130, 200 
    invoke DrawStar, 140, 200 
    invoke DrawStar, 150, 200 
    invoke DrawStar, 160, 200 
    invoke DrawStar, 170, 200 
    invoke DrawStar, 180, 200 
    invoke DrawStar, 190, 200 
    invoke DrawStar, 200, 200 

    ;;Stem of the J
    invoke DrawStar, 150, 200 
    invoke DrawStar, 150, 210 
    invoke DrawStar, 150, 220 
    invoke DrawStar, 150, 230 
    invoke DrawStar, 150, 240 
    invoke DrawStar, 150, 250 


    ;;Curve of the J
    invoke DrawStar, 140, 260 
    invoke DrawStar, 130, 270 
    invoke DrawStar, 120, 260 
    invoke DrawStar, 110, 250 
    invoke DrawStar, 100, 240 

	ret  			; Careful! Don't remove this line
DrawStarField endp



END
