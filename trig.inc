; #########################################################################
;
;   trig.inc - Includes for CompEng205 Assignment 3
;
;
; #########################################################################

FXPT TYPEDEF SDWORD

EXTERNDEF SINTAB:WORD

FixedSinQ1 PROTO STDCALL angle:FXPT
FixedSin PROTO STDCALL angle:FXPT
FixedCos PROTO STDCALL angle:FXPT