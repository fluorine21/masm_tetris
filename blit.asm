; #########################################################################
;
;   blit.asm - Assembly file for CompEng205 Assignment 3
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


.DATA

	;; If you need to, you can place global variables here
	
.CODE

DrawPixel PROC USES eax ebx ecx edx x:DWORD, y:DWORD, color:DWORD

	;;Need to do boundary checking first
	cmp x, 0
	jl BOUNDS_BAD
	cmp x, 639
	jg BOUNDS_BAD
	cmp y, 0
	jl BOUNDS_BAD
	cmp y, 479
	jg BOUNDS_BAD


	;;Multiply our y value by 640
	mov eax, y
	mov ebx, 640
	mul ebx

	;;Add it to our x value to get the index (yval in eax now)
	add eax, x

	;;Use this to index ScreenBitsPtr
	mov ebx, color
	mov ecx, ScreenBitsPtr
	add ecx, eax
	mov BYTE PTR [ecx], bl


BOUNDS_BAD:

	ret 			; Don't delete this line!!!
DrawPixel ENDP

BasicBlit PROC ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD

	invoke RotateBlit, ptrBitmap, xcenter, ycenter, 0

	ret 			; Don't delete this line!!!	
BasicBlit ENDP


RotateBlit PROC USES eax ebx ecx edx ptrBitmap:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT


	;;Angle variables, eight and width extracted from struct
	LOCAL sina:DWORD
	LOCAL cosa:DWORD
	LOCAL img_w:DWORD
	LOCAL img_h:DWORD

	;;Shift variables
	LOCAL shiftX:DWORD
	LOCAL shiftY:DWORD

	;;Loop limits
	LOCAL dst_w:DWORD
	LOCAL dst_h:DWORD

	;;Loop counters
	LOCAL dstX:DWORD
	LOCAL dstY:DWORD

	;;Inner loop variables
	LOCAL srcX:DWORD
	LOCAL srcY:DWORD

	;;Final pixel location in DirectX buffer
	LOCAL xf:DWORD
	LOCAL yf:DWORD

	;;Transparent pixel color
	LOCAL trans_pix:DWORD


	;;Load the value of the transparent pixel
	mov esi, ptrBitmap
	add esi, 8
	mov ebx, [esi]
	mov trans_pix, ebx


	;;Get sina and cosa next
	invoke FixedSin, angle
	mov sina, eax
	invoke FixedCos, angle
	mov cosa, eax

	;;Load the width and height from the struct
	mov ebx, ptrBitmap
	mov eax, [ebx]
	mov img_w, eax
	add ebx, 4
	mov eax, [ebx]
	mov img_h, eax

	;;shiftX = (width * cosa / 2) - (height * sina / 2)
	mov eax, cosa
	sar eax, 2
	imul img_w
	mov ebx, eax ;;Saving eax to ebx to use eax again in next mul

	mov eax, sina
	sar eax, 2
	imul img_h
	sub ebx, eax
	;;Divide by 2^16 to get back correct answer
	sar ebx, 16
	mov shiftX, ebx

	;;shiftY = (height * cosa / 2) + (width * sina / 2)
	mov eax, cosa
	sar eax, 2
	imul img_h
	mov ebx, eax

	mov eax, sina
	sar eax, 2
	imul img_w
	add ebx, eax
	;;Divide by 2^16 to get back correct answer
	sar ebx, 16
	mov shiftY, ebx

	;;Origional method of setting w and h
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;dst_w = img_w + img_h
	mov eax, img_w
	add eax, img_h
	mov dst_w, eax

	;;dst_h = dst_w
	mov dst_h, eax
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;;Initializing for loop one
	mov eax, dst_w
	neg eax
	mov dstX, eax

LOOP_1_CHECK:
	mov eax, dst_w
	cmp eax, dstX
	jl LOOP_1_END


	;;Initializing for loop two
	mov eax, dst_h
	neg eax
	mov dstY, eax

LOOP_2_CHECK:
	mov eax, dst_h
	cmp eax, dstY
	jl LOOP_2_END
	

	;;Inner body

	;;srcX = dstX*cosa + dstY*sina
	mov eax, dstX
	imul cosa
	mov ebx, eax

	mov eax, dstY
	imul sina
	add ebx, eax
	;;Need to right shift by 16 to get final answer
	sar ebx, 16
	mov srcX, ebx


	;;srcY = dstY*cosa – dstX*sina
	mov eax, dstY
	imul cosa
	mov ebx, eax

	mov eax, dstX
	imul sina
	sub ebx, eax
	;;Need to right shift by 16 to get final answer
	sar ebx, 16
	mov srcY, ebx

	;;srcX >= 0 && srcX < (EECS205BITMAP PTR [esi]).dwWidth
	mov eax, srcX
	cmp eax, 0
	jl BODY_END
	cmp eax, img_w
	jge BODY_END


	;;srcY >= 0 && srcY < (EECS205BITMAP PTR [esi]).dwHeight
	mov eax, srcY
	cmp eax, 0
	jl BODY_END
	cmp eax, img_h
	jge BODY_END

	;;xf = xcenter+dstX-shiftX
	mov eax, xcenter
	add eax, dstX
	sub eax, shiftX
	mov xf, eax

	;;yf = ycenter+dstY-shiftY
	mov eax, ycenter
	add eax, dstY
	sub eax, shiftY
	mov yf, eax

	;;xf >= 0 && xf < 639
	cmp xf, 0
	jl BODY_END
	cmp xf, 639
	jge BODY_END

	;;yf >= 0 && yf < 479
	cmp yf, 0
	jl BODY_END
	cmp yf, 479
	jge BODY_END

	;;Load the address of the pixel color matrix
	mov esi, ptrBitmap
	add esi, 12
	mov ebx, [esi]
	
	;;Calculate the pixel address
	mov eax, srcY
	mov ecx, img_w
	mul ecx
	add eax, srcX

	mov edx, 0
	mov ecx, eax
	add ecx, ebx
	mov dl, BYTE PTR [ecx] ;;This moves our target color into edx

	;;Don't draw if its transparent
	cmp edx, trans_pix
	je BODY_END 

	invoke DrawPixel, xf, yf, edx



BODY_END:
	inc dstY
	jmp LOOP_2_CHECK
LOOP_2_END:
	inc dstX
	jmp LOOP_1_CHECK
LOOP_1_END:

	ret 			; Don't delete this line!!!		
RotateBlit ENDP



END
