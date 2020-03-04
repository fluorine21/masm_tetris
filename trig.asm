; #########################################################################
;
;   trig.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include trig.inc

.DATA

;;  These are some useful constants (fixed point values that correspond to important angles)
PI_HALF = 102943           	;;  PI / 2
PI =  205887	                ;;  PI 
TWO_PI	= 411774                ;;  2 * PI 
PI_INC_RECIP =  5340353        	;;  Use reciprocal to find the table entry for a given angle
	                        ;;              (It is easier to use than divison would be)


	;; If you need to, you can place global variables here
	
.CODE

FixedSinQ1 PROC USES edx ebx angle:FXPT ;;This function only works for 0 < angle < pi/2

	;;First we multiply our value by 256 with a left bit shift of 8
	mov eax, angle
	shl eax, 8

	;;Then we divide by pi to get our index
	mov edx, 0 ;; zero out edx
	mov ebx, PI
	div ebx

	;;Result of this calculation is in eax, so we use it as our index
	movzx eax, [SINTAB + eax * 2]

	ret ;;
FixedSinQ1 ENDP

FixedSin PROC USES edx ebx angle:FXPT

	LOCAL pi_negate:BYTE ;; this will be set to 1 if we need to negate our answer because of a pi phase
	LOCAL neg_negate:BYTE ;; this will be set to 1 if we need to negate our answer because our origional angle was negative

	mov pi_negate, 0
	mov neg_negate, 0

	mov eax, angle

	;;If our angle is negative, invert it and remember to invert the answer at the end
	cmp angle, 0
	jge NEG_SKIP
	mov neg_negate, 1
	neg eax

NEG_SKIP:

	;;First we need to take the modulo 2pi
	mov edx, 0
	mov ebx, TWO_PI
	idiv ebx

	;;Now our angle modulo 2pi is in edx, so we need some case checking


	;;If our angle is pi or 0. just return 0
	cmp edx, PI
	je R_0
	cmp edx, 0
	je R_0

	;;If our angle is greater than pi, then set the pi_negate flag
	cmp edx, PI
	jl PI_SKIP
	mov pi_negate, 1
	;;Subtract pi from the angle to get it into the correct range
	sub edx, PI

PI_SKIP:

	;;If our angle is greater than pi/2, then subtract it from pi and call the function on it
	cmp edx, PI_HALF
	jle PHASE_SKIP
	mov eax, PI ;;Move PI into reg so we can subtract from it
	sub eax, edx
	mov edx, eax ;;Move result back into edx for function call

PHASE_SKIP:
	invoke FixedSinQ1, edx

	;;Result is now in eax
	
NEG_CHECKS:

	;;If the neg_negate flag was set
	cmp neg_negate, 0
	je NEXT_NEG
	neg eax

NEXT_NEG:
	;;If the pi_negate flag was set
	cmp pi_negate, 0
	je PRE_RET
	neg eax
	
PRE_RET:

	ret			; Don't delete this line!!!

R_0:
	mov eax, 0 ;;if our angle is some multiple of pi
	ret

FixedSin ENDP 
	
FixedCos PROC angle:FXPT

	;;Add pi over two to our angle
	mov eax, angle
	add eax, PI_HALF

	;;Call sin and return
	invoke FixedSin, eax

	ret			; Don't delete this line!!!	
FixedCos ENDP	
END
