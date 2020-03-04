; #########################################################################
;
;   lines.asm - Assembly file for CompEng205 Assignment 2
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc

.DATA

	;; If you need to, you can place global variables here
	
.CODE
	

;; Don't forget to add the USES the directive here
;;   Place any registers that you modify (either explicitly or implicitly)
;;   into the USES list so that caller's values can be preserved
	
;;   For example, if your procedure uses only the eax and ebx registers
;;      DrawLine PROC USES eax ebx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD

DrawLine PROC USES eax ebx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD

	;; Feel free to use local variables...declare them here
	;; For example:
	;; 	LOCAL foo:DWORD, bar:DWORD

	LOCAL delta_x:DWORD, delta_y:DWORD, error:DWORD, inc_x:DWORD, inc_y:DWORD, curr_x:DWORD, curr_y:DWORD

	;; Place your code here


	;;delta_x = abs(x1-x0)
	mov inc_x, 1 ;;Initialize inc_x early
	mov eax, x1
	sub eax, x0
	jge L1 ;;If it's greater than 0, don't negate
	neg eax
	sub inc_x, 2 ;;if (x0 < x1) inc_x = 1 else inc_x = -1
L1: mov delta_x, eax

	;;delta_y = abs(y1-y0)
	mov inc_y, 1
	mov eax, y1
	sub eax, y0
	jge L2 ;;If it's greater than 0, don't negate
	neg eax
	sub inc_y, 2 ;;if (y0 < y1) inc_x = 1 else inc_x = -1
L2: mov delta_y, eax

	;;if (delta_x > delta_y) error = delta_x / 2 else error = - delta_y / 2
	
	cmp delta_x, eax
	jle L3 ;; If delta_x is less than or equal to delta_y go to else
	mov ebx, delta_x
	sar ebx, 1 ;; Divide delta_x by 2
	mov error, ebx
	jmp L4
L3: neg eax
	sar eax, 1 ;; Divide -delta_y by 2
	mov error, eax


	;;curr_x = x0, curr_y = y0
L4:	mov eax, x0
	mov curr_x, eax
	mov eax, y0
	mov curr_y, eax

	;;DrawPixel(curr_x, curr_y, color)
	invoke DrawPixel, curr_x, curr_y, color

	jmp L5;; go to while loop check

	;;Top of while loop
L6: invoke DrawPixel, curr_x, curr_y, color

	;;prev_error = error
	mov ebx, error ;; ebx is prev_error

	;;if (prev_error > - delta_x) error = error - delta_y, curr_x = curr_x + inc_x

	mov eax, delta_x
	neg eax ;;has -delta_x
	cmp ebx, eax
	jle L7

	mov eax, error
	sub eax, delta_y
	mov error, eax

	mov eax, curr_x
	add eax, inc_x
	mov curr_x, eax

	;;if (prev_error < delta_y) error = error + delta_x, curr_y = curr_y + inc_y
L7: mov eax, delta_y
	cmp ebx, eax
	jge L5

	mov eax, error
	add eax, delta_x
	mov error, eax

	mov eax, curr_y
	add eax, inc_y
	mov curr_y, eax

	;;curr_x != x1 OR curr_y != y1
L5: mov eax, x1
	cmp eax, curr_x
	jne L6
	mov eax, y1
	cmp eax, curr_y
	jne L6

	ret        	;;  Don't delete this line...you need it
DrawLine ENDP




END
