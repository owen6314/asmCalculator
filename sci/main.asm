.386
.model flat, stdcall
.stack 4096
option casemap:none

;INCLUDE C:/masm32/include/masm32.inc
;INCLUDE C:/masm32/include/kernel32.inc
;INCLUDE C:/masm32/include/shell32.inc
;INCLUDELIB C:/masm32/lib/masm32.lib
;INCLUDELIB C:/masm32/lib/kernel32.lib

include C:\masm32\include\windows.inc 
include C:\masm32\include\user32.inc 
include C:\masm32\include\kernel32.inc 
include C:\masm32\include\shell32.inc
include C:\masm32\include\masm32.inc

includelib C:\masm32\lib\user32.lib 
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\masm32.lib
;--------CONST ID--------
IDC_NUM0		equ		1000
IDC_NUM1		equ		1001
IDC_NUM2		equ		1002
IDC_NUM3		equ		1003
IDC_NUM4		equ		1004
IDC_NUM5		equ		1005
IDC_NUM6		equ		1006
IDC_NUM7		equ		1007
IDC_NUM8		equ		1008
IDC_NUM9		equ		1009
IDC_ADD		equ		1010
IDC_SUB		equ		1011
IDC_MUL		equ		1012
IDC_DIV		equ		1013

IDC_GAME		equ		1030

IDC_BACKSPACE	equ		1040
IDC_C		equ		1041
IDC_MUSIC		equ		1042
IDC_SHIFT		equ		1043
IDC_EQU		equ		1044
IDC_POINT		equ		1045
IDD_CAL		equ		2000
IDC_DISPLAY	equ		2001
IDC_RESULT	equ		2002

IDC_LN		equ		1050
IDC_LOG		equ		1051
IDC_EXP		equ		1052
IDC_SQRT		equ		1053
IDC_NP		equ		1054

IDC_PI		equ		1100
IDC_E		equ		1101

IDC_SIN		equ		1060
IDC_TAN		equ		1061
IDC_COS		equ		1062

IDC_LBRACKET	equ		1070
IDC_RBRACKET	equ		1071

IDC_MS		equ		1204
IDC_MSUB		equ		1203
IDC_MC		equ		1200
IDC_MADD		equ		1202
IDC_MR		equ		1201
;----------CONST---------
PRE_ADD	equ	1
PRE_SUB	equ	1
PRE_MUL	equ	2
PRE_DIV	equ	2
PRE_POW	equ	3
PRE_SIN	equ	4
PRE_COS	equ	4
PRE_TAN	equ	4
PRE_LN	equ	4
PRE_LOG	equ	4
PRE_SQRT	equ	4
;----------PROTO---------
RPN			PROTO		:PTR BYTE, :PTR BYTE, :PTR BYTE
GetPreOrder	PROTO		:BYTE
GetChar		PROTO		:DWORD
PreProcess	PROTO		:PTR BYTE, :PTR BYTE
IsDigitOrP	PROTO		:BYTE
Calculate		PROTO		:PTR BYTE, :PTR BYTE
C2R			PROTO		:PTR BYTE, :PTR BYTE
R2C			PROTO		:PTR BYTE, :PTR BYTE
MessageHandler	PROTO		:DWORD, :DWORD, :DWORD, :DWORD 
NumHandler	PROTO		:DWORD, :PTR BYTE
ShowOutput	PROTO		:PTR BYTE
ShowResult	PROTO		:PTR BYTE
BackspaceHandler	PROTO	:PTR BYTE
;PointHandler	PROTO		:PTR BYTE
;PiHandler	PROTO		:PTR BYTE
EqualHandler	PROTO		:PTR BYTE
;AddHandler	PROTO		:PTR BYTE
;SubHandler	PROTO		:PTR BYTE
;MulHanlder	PROTO		:PTR BYTE
;DivHandler	PROTO		:PTR BYTE
GeneralHandler	PROTO		:PTR BYTE, :BYTE
SingleOpHandler	PROTO		:PTR BYTE, :BYTE
NPHandler		PROTO		:PTR BYTE

MCHandler		PROTO		
MRHandler		PROTO		:PTR BYTE
MAddHandler	PROTO
MSubHandler	PROTO
MSHandler		PROTO

;----------DATA----------
.DATA
	Info		BYTE		"Run", 0
	Input	BYTE		1024 dup(0)
	;Infix	BYTE		"l(-2+s(p*1.1)+t(p/2.1))/l(3)", 128 dup(0)
	Infix	BYTE		"l(2.71)", 1024 dup(0)
	Postfix	BYTE		1024 dup(0)
	CharStack	BYTE		'$', 1024 dup(0)
	Char		BYTE		'+', '-', '*', '/', '^', 's', 'c', 't', 'l', 'g', 'r', '(', ')', '.', 'p', 'e', 0
	ID		DWORD	IDC_ADD, IDC_SUB, IDC_MUL, IDC_DIV, IDC_EXP, IDC_SIN, 
					IDC_COS, IDC_TAN, IDC_LN, IDC_LOG, IDC_SQRT, IDC_LBRACKET, IDC_RBRACKET, 
					IDC_POINT, IDC_PI, IDC_E, 0
	Operator	BYTE		'+', '-', '*', '/', '^', 's', 'c', 't', 'l', 'g', 'r', 0
	PreOrder	BYTE		 1 ,  1 ,  2 ,  2 ,  3 ,  4 ,  4 ,  4 ,  4 ,  4 ,  4 , 0
	Buffer	BYTE		1024	dup(0)
	FloatS	QWORD	1024 dup(0)
	Output	BYTE		1024 dup(0)
	Com		BYTE		1024 dup(0)

	;----------Float Cal Tmp----------
	fCtrlWord		WORD			?
	fStatusWord	WORD			?
	fTmp			WORD			?
	fResult		QWORD		0
	fMemory		QWORD		0

	SyntaxError	BYTE			"Syntax Error!", 0
	UnderflowError	BYTE			"Underflow!", 0
	OverflowError	BYTE			"Overflow!", 0
	ZeroDividError	BYTE			"Ma Error!", 0
	InvalidError	BYTE			"Invalid!", 0
	LengthError	BYTE			"Too Long!", 0

	ErrorTitle	BYTE			"Error",0
	Template		BYTE			"CALCULATO", 0
	PopupTitle	BYTE			"Example", 0
	PopupText		BYTE			"Example", 0
	WndClass		WNDCLASSEX	<NULL,NULL,MessageHandler,NULL,NULL,NULL,NULL,NULL,COLOR_WINDOW,NULL,NULL,NULL>

	hMainWnd		DWORD		?
	hEdit		DWORD		?
	hResult		DWORD		?
;----------CODE----------

.CODE

WinMain PROC
	LOCAL msg:MSG   
	INVOKE	GetModuleHandle, NULL
	.IF	eax == 0
		call		ErrorHandler
		jmp		Exit_Program
	.ENDIF

	mov		WndClass.hInstance, eax
	mov		WndClass.cbSize,sizeof WNDCLASSEX 
	mov		WndClass.style,CS_BYTEALIGNWINDOW ;or CS_BYTEALIGNWINDOW 
	mov		WndClass.cbClsExtra,0 
	mov		WndClass.cbWndExtra,DLGWINDOWEXTRA
	mov		WndClass.hbrBackground,COLOR_BTNFACE+1  
	mov		WndClass.lpszMenuName,NULL              
	mov		WndClass.lpszClassName, OFFSET Template 
	
	INVOKE	RegisterClassEx,addr WndClass 

	INVOKE	CreateDialogParam, WndClass.hInstance, addr Template, 0, addr MessageHandler, 0
	mov		hMainWnd, eax
	.IF	eax == 0
		call		ErrorHandler
		jmp		Exit_Program
	.ENDIF

	INVOKE	ShowWindow,hMainWnd,SW_SHOWNORMAL
	INVOKE	UpdateWindow,hMainWnd  

StartLoop:
	INVOKE	GetMessage,addr msg,0,0,0
	cmp		eax,0
	je		ExitLoop
	INVOKE	TranslateMessage,addr msg
	INVOKE	DispatchMessage,addr msg    
	jmp		StartLoop
ExitLoop:   

	INVOKE	R2C, addr Infix, addr Com
	INVOKE	PreProcess, addr Infix, addr Infix
	INVOKE	RPN, addr Infix, addr Postfix, addr CharStack
	INVOKE	Calculate, addr Postfix, addr Output
Exit_Program:
	INVOKE	ExitProcess, 0
WinMain ENDP



GetPreOrder PROC USES esi edi, 
	operator: BYTE
	mov		esi, OFFSET Operator
	mov		edi, OFFSET PreOrder
	.WHILE BYTE PTR [esi] != 0
		mov		al, operator
		.IF BYTE PTR [esi] == al
			sub		esi, OFFSET Operator
			add		edi, esi
			mov		al, [edi]
			jmp		ExitGetPreOrder
		.ENDIF
		inc		esi
	.ENDW
	mov		eax, 0
ExitGetPreOrder:
	ret
GetPreOrder ENDP

GetChar PROC USES esi,
	id: DWORD
	mov		esi, 0
	mov		eax, id
	.WHILE DWORD PTR ID[esi * 4] != 0
		
		mov		ebx, DWORD PTR ID[esi * 4]
		.IF DWORD PTR ID[esi * 4] == eax
			mov		al, BYTE PTR Char[esi]
			jmp		ReturnGetChar
		.ENDIF
		inc		esi
	.ENDW
ReturnGetChar:
	ret
GetChar ENDP

PreProcess PROC USES esi,
	infix: PTR BYTE,
	sepInfix: PTR BYTE		; infix with number separeted by '#'
	LOCAL buffer[1024]:BYTE
	mov		esi, infix
	mov		edi, 0
	.WHILE BYTE PTR [esi] != 0
		mov		al, [esi]
		mov		buffer[edi], al
		INVOKE	IsDigitOrP, buffer[edi]
		.IF eax
			INVOKE	IsDigitOrP, [esi + 1]
			.IF !eax
				inc		edi
				mov		al, '#'
				mov		buffer[edi], al
			.ENDIF
		.ELSE
			.IF (buffer[edi] == '-' || buffer[edi] == '+') && (edi == 0 || buffer[edi - 1] == '(')
				mov		al, buffer[edi]
				mov		buffer[edi + 2] ,al
				mov		buffer[edi], '0'
				inc		edi
				mov		buffer[edi], '#'
				inc		edi
			.ENDIF
		.ENDIF
		inc		edi
		inc		esi
	.ENDW
	mov		buffer[edi], 0
	mov		esi, sepInfix
	mov		edi, 0
	.WHILE buffer[edi] != 0
		mov		al, buffer[edi]
		mov		[esi], al
		inc		edi
		inc		esi
	.ENDW
	mov		BYTE PTR [esi], 0
	ret
PreProcess ENDP

; Determine the type of a character
; Return 1[eax]: '0'-'9', '.', 'p'(PI), 'e'(2^log2e)
; Return 0[eax]: Other
IsDigitOrP PROC,
	char:BYTE
	.IF	char <= '9' && char >= '0'
		mov		eax, 1
		jmp		ExitIsDigitOrP
	.ELSEIF char == '.'
		mov		eax, 1
		jmp		ExitIsDigitOrP
	.ELSEIF char == 'p'
		mov		eax, 1
		jmp		ExitIsDigitOrP
	.ELSEIF char == 'e'
		mov		eax, 1
		jmp		ExitIsDigitOrP
	.ELSE
		mov		eax, 0
		jmp		ExitIsDigitOrP
	.ENDIF
ExitIsDigitOrP:
	ret
IsDigitOrP ENDP

Calculate PROC USES esi edi edx,
	postfix: PTR BYTE,
	output: PTR BYTE
	
	mov		esi, postfix
	mov		edi, OFFSET Buffer
	mov		edx, OFFSET FloatS
	.WHILE BYTE PTR [esi] != 0
		mov		al, [esi]	
		INVOKE	IsDigitOrP, al
		.IF	eax
			mov		al, [esi]
			mov		[edi], al
			inc		esi
			inc		edi
		.ELSEIF BYTE PTR [esi] == '#'

			; Convert the num string in buffer to float,
			; then push into the stack
			
			; PI
			.IF BYTE PTR Buffer[0] == 'p'
				fldpi
				fstp		QWORD PTR [edx]

			; e
			.ELSEIF BYTE PTR Buffer[0] == 'e'
				fstcw	fCtrlWord
				or		fCtrlWord, 1100000000000000b
				fldcw	fCtrlWord

				fld1							; base 2
				fld1
				fadd
				fldl2e						; power log2e
				fxch
					
				fyl2x						; b * log2(a)

				fist		fTmp					; tmp = int(b * log2(a))

				fild		fTmp					; load tmp

				fsub							; r = tmp - b * log(2)
				f2xm1						; pow(2, r) - 1
				fld1							; load 1
				fadd							; pow(2, r)
				fild		fTmp					; load tmp
				fxch							; exchange tmp, pow(2, r)
				fscale						; pow(2, r) * pow(2, tmp) = pow(2, b * log2(a))
				fstp		QWORD PTR [edx]

			; Other number
			.ELSE
				mov		BYTE PTR [edi], 0
				inc		edi
				pushad
				INVOKE	StrToFloat, OFFSET Buffer, edx		
				popad
			
			.ENDIF
			
			add		edx, 8
			mov		edi, OFFSET Buffer
			inc		esi

		.ELSE
			mov		al, [esi]
			.IF	al == '+'
				finit
				fld		QWORD PTR [edx - 16]
				fadd		QWORD PTR [edx - 8]
				fstp		QWORD PTR [edx - 16]
				sub		edx, 8
			.ELSEIF al == '-'
				finit
				fld		QWORD PTR [edx - 16]
				fsub		QWORD PTR [edx - 8]
				fstp		QWORD PTR [edx - 16]
				sub		edx, 8
			.ELSEIF al == '*'
				finit
				fld		QWORD PTR [edx - 16]
				fmul		QWORD PTR [edx - 8]
				fstp		QWORD PTR [edx - 16]
				sub		edx, 8
			.ELSEIF al == '/'
				finit
				fld		QWORD PTR [edx - 16]
				fdiv		QWORD PTR [edx - 8]
				fstp		QWORD PTR [edx - 16]
				sub		edx, 8
			; Square Root
			.ELSEIF al == 'r'
				finit
				fld		QWORD PTR [edx - 8]
				fsqrt
				fstp		QWORD PTR [edx - 8]

			.ELSEIF al == '^'
				finit
				fstcw	fCtrlWord
				or		fCtrlWord, 1100000000000000b
				fldcw	fCtrlWord

				fld		QWORD PTR [edx - 8]		; power b
				fld		QWORD PTR [edx - 16]	; base a
				fyl2x						; b * log2(a)

				fist		fTmp					; tmp = int(b * log2(a))

				fild		fTmp					; load tmp

				fsub							; r = tmp - b * log(2)
				f2xm1						; pow(2, r) - 1
				fld1							; load 1
				fadd							; pow(2, r)
				fild		fTmp					; load tmp
				fxch							; exchange tmp, pow(2, r)
				fscale						; pow(2, r) * pow(2, tmp) = pow(2, b * log2(a))

				fstp		QWORD PTR [edx - 16]
				sub		edx, 8

			; Sine
			.ELSEIF al == 's'
				finit
				fld		QWORD PTR [edx - 8]
				fsin
				fstp		QWORD PTR [edx - 8]

			; Cosine
			.ELSEIF al == 'c'
				finit
				fld		QWORD PTR [edx - 8]
				fcos
				fstp		QWORD PTR [edx - 8]
			
			; Tangeent
			.ELSEIF al == 't'
				finit
				fld		QWORD PTR [edx - 8]
				fptan
				fstp		QWORD PTR [edx - 8]

			; ln
			.ELSEIF al == 'l'
				finit
				fld1
				fldl2e
				fdiv

				fld		QWORD PTR [edx - 8]
				fyl2x

				fstp		QWORD PTR [edx - 8]

			; log
			.ELSEIF al == 'g'
				finit
				fld1
				fldl2t
				fdiv

				fld		QWORD PTR [edx - 8]
				fyl2x

				fstp		QWORD PTR [edx - 8]

			.ENDIF
			inc		esi

			.IF edx < OFFSET FloatS
				mov		eax, 5
				jmp		ReturnCalculate
			.ENDIF

			fstsw	fStatusWord
			mov		ax, fStatusWord
			and		ax, 0010h
			.IF ax != 0
				mov		eax, 1
				jmp		ReturnCalculate
			.ENDIF
			mov		ax, fStatusWord
			and		ax, 0008h
			.IF ax != 0
				mov		eax, 2
				jmp		ReturnCalculate
			.ENDIF
			mov		ax, fStatusWord
			and		ax, 0004h
			.IF ax != 0
				mov		eax, 3
				jmp		ReturnCalculate
			.ENDIF
			mov		ax, fStatusWord
			and		ax, 0001h
			.IF ax != 0
				mov		eax, 4
				jmp		ReturnCalculate
			.ENDIF
			mov		eax, 0
		.ENDIF
	.ENDW
	sub		edx, 8
	.IF edx != OFFSET FloatS
		mov		eax, 5
		jmp		ReturnCalculate
	.ENDIF
	fld		QWORD PTR FloatS[0]
	fstp		QWORD PTR fResult
	INVOKE	FloatToStr2, QWORD PTR FloatS[0], output
ReturnCalculate:
	ret
Calculate ENDP

R2C PROC,
	source: PTR BYTE,
	dest: PTR BYTE

	mov		esi, source
	mov		edi, dest

	.WHILE BYTE PTR [esi] != 0
		.IF BYTE PTR [esi] == 'l'
			mov		BYTE PTR [edi], 'l'
			inc		edi
			mov		BYTE PTR [edi], 'n'
		.ELSEIF BYTE PTR [esi] == 'g'
			mov		BYTE PTR [edi], 'l'
			inc		edi
			mov		BYTE PTR [edi], 'o'
			inc		edi
			mov		BYTE PTR [edi], 'g'
		.ELSEIF BYTE PTR [esi] == 's'
			mov		BYTE PTR [edi], 's'
			inc		edi
			mov		BYTE PTR [edi], 'i'
			inc		edi
			mov		BYTE PTR [edi], 'n'
		.ELSEIF BYTE PTR [esi] == 'c'
			mov		BYTE PTR [edi], 'c'
			inc		edi
			mov		BYTE PTR [edi], 'o'
			inc		edi
			mov		BYTE PTR [edi], 's'
		.ELSEIF BYTE PTR [esi] == 't'
			mov		BYTE PTR [edi], 't'
			inc		edi
			mov		BYTE PTR [edi], 'a'
			inc		edi
			mov		BYTE PTR [edi], 'n'
		.ELSEIF BYTE PTR [esi] == 'r'
			mov		BYTE PTR [edi], 's'
			inc		edi
			mov		BYTE PTR [edi], 'q'
			inc		edi
			mov		BYTE PTR [edi], 'r'
			inc		edi
			mov		BYTE PTR [edi], 't'
		.ELSEIF BYTE PTR [esi] == 'p'
			mov		BYTE PTR [edi], 'p'
			inc		edi
			mov		BYTE PTR [edi], 'i'
		.ELSE
			mov		al, BYTE PTR [esi]
			mov		BYTE PTR [edi], al
		.ENDIF

		inc		edi
		inc		esi

	.ENDW
	mov		BYTE PTR [edi], 0
	inc		edi
	ret
R2C ENDP

C2R PROC,
	source: PTR BYTE,
	dest: PTR BYTE
C2R ENDP

InitCal PROC
	finit
	
	mov		BYTE PTR Infix[0], 0
	mov		BYTE PTR Infix[256], 0
	mov		BYTE PTR Postfix[0], 0
	mov		BYTE PTR Output[0], 0

	INVOKE	ShowResult, addr Output
	INVOKE	ShowOutput, addr Infix
	ret
InitCal ENDP

;mem pushbutton
; clear memory
MCHandler PROC
	finit
	fld1
	fld1
	fsub
	fstp		fMemory
	ret
MCHandler ENDP

; show memory
MRHandler PROC USES esi edi,
	infix: PTR BYTE
	LOCAL buffer[1024]: BYTE
	mov		BYTE PTR buffer[0], 0
	INVOKE	FloatToStr2, QWORD PTR fMemory, addr buffer
	mov		edi, infix
	.WHILE BYTE PTR [edi] != 0
		inc		edi
	.ENDW
	mov		esi, 0
	.WHILE BYTE PTR buffer[esi] != 0
		mov		al, buffer[esi]
		mov		BYTE PTR [edi], al
		inc		esi
		inc		edi
	.ENDW
	mov		BYTE PTR [edi], 0
	ret
MRHandler ENDP

; add current number to cal mem
MAddHandler PROC
	finit
	fld		fMemory
	fld		fResult
	fadd
	fstp		fMemory
	ret
MAddHandler ENDP

; sub current number from cal mem
MSubHandler PROC
	finit
	fld		fMemory
	fld		fResult
	fsub
	fstp		fMemory
	ret
MSubHandler ENDP


; store current result
MSHandler PROC
	finit
	fld		fResult
	fstp		fMemory
	ret
MSHandler ENDP

NPHandler  PROC USES esi edi,
	infix: PTR BYTE
	LOCAL buffer[1024]: BYTE
	
	mov		BYTE PTR buffer[0], '-'
	mov		BYTE PTR buffer[1], '('

	mov		edi, infix
	mov		esi, 2
	.WHILE BYTE PTR [edi] != 0
		mov		al, [edi]
		mov		buffer[esi], al
		inc		edi
		inc		esi
	.ENDW
	mov		buffer[esi], 0

	mov		edi, infix
	mov		esi, 0
	.WHILE BYTE PTR buffer[esi] != 0
		mov		al, buffer[esi]
		mov		[edi], al
		inc		edi
		inc		esi
	.ENDW
	mov		BYTE PTR [edi], ')'
	inc		edi
	mov		BYTE PTR [edi], 0
	ret
NPHandler ENDP

.CODE
ErrorHandler PROC
.data
	pErrorMsg		DWORD ?
	messageID		DWORD ?

.code
	INVOKE	GetLastError
	mov		messageID,eax

	; Get the corresponding message string.
	INVOKE	FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
	  FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
	  ADDR pErrorMsg,NULL,NULL

	; Display the error message.
	INVOKE	MessageBox,NULL, pErrorMsg, ADDR ErrorTitle,
	  MB_ICONERROR+MB_OK

	; Free the error message string.
	INVOKE	LocalFree, pErrorMsg

	ret
ErrorHandler ENDP

MessageHandler PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD

	mov eax, localMsg
	.IF eax == WM_INITDIALOG
		;get components' handler
		INVOKE  GetDlgItem, hWnd, IDC_DISPLAY
		mov		hEdit, eax
		.IF	eax == 0
			call ErrorHandler
		.ENDIF

		INVOKE  GetDlgItem, hWnd, IDC_RESULT
		mov		hResult, eax
		.IF	eax == 0
			call ErrorHandler
		.ENDIF

		INVOKE InitCal

		mov Output[0], '0'
		mov Output[1], 0
		jmp Show

	.ELSEIF eax == WM_COMMAND
		mov eax, wParam
		.IF (eax >= IDC_NUM0) && (eax <= IDC_NUM9)
			INVOKE NumHandler, eax, addr Infix
			jmp Show
		;.ELSEIF eax == IDC_POINT
			;INVOKE PointHandler, addr Infix
			;jmp Show
		;.ELSEIF eax == IDC_PI
			;INVOKE PiHandler, addr Infix
			;jmp Show
		.ELSEIF eax == IDC_BACKSPACE
			INVOKE BackspaceHandler, addr Infix
			jmp Show
		;.ELSEIF eax == IDC_ADD
			;INVOKE AddHandler, addr Infix
			;jmp Show
		;.ELSEIF eax == IDC_SUB
			;INVOKE SubHandler, addr Infix
			;jmp Show
		;.ELSEIF eax == IDC_MUL
			;INVOKE MulHandler, addr Infix
			;jmp Show
		;.ELSEIF eax == IDC_DIV
			;INVOKE DivHandler, addr Infix
			;jmp Show
		.ELSEIF eax == IDC_EQU
			INVOKE EqualHandler, addr Infix
			jmp Show
		.ELSEIF eax == IDC_C
			INVOKE InitCal
			jmp Show
		.ELSEIF eax == IDC_LN || eax == IDC_SIN || eax == IDC_COS || eax == IDC_TAN || eax == IDC_SQRT || eax == IDC_LOG
			INVOKE	GetChar, eax
			INVOKE	SingleOpHandler, addr Infix, al
			jmp Show
		.ELSEIF eax == IDC_ADD || eax == IDC_SUB || eax == IDC_MUL || eax == IDC_DIV 
			INVOKE	GetChar, eax
			INVOKE	GeneralHandler, addr Infix, al
			jmp Show
		.ELSEIF eax == IDC_POINT || eax == IDC_PI || eax == IDC_E || eax == IDC_LBRACKET || eax == IDC_RBRACKET || eax == IDC_EXP
			INVOKE	GetChar, eax
			INVOKE	GeneralHandler, addr Infix, al
			jmp Show
		.ELSEIF eax == IDC_MC
			INVOKE MCHandler
			jmp Show
		.ELSEIF eax == IDC_MR
			INVOKE MRHandler, addr Infix
			jmp Show
		.ELSEIF eax == IDC_MS
			INVOKE MSHandler
			jmp Show
		.ELSEIF eax == IDC_MADD
			INVOKE MAddHandler
			jmp Show
		.ELSEIF eax == IDC_MSUB
			INVOKE MSubHandler
			jmp Show
		.ELSEIF eax == IDC_NP
			INVOKE NPHandler, addr Infix
			jmp Show
		.ELSE
			mov		eax, 0
			jmp WinProcExit
		.ENDIF

	;input char via keyboard
	.ELSEIF eax == WM_CHAR
		INVOKE MessageBox, hWnd, ADDR PopupText, ADDR PopupTitle, MB_OK
	.ELSEIF eax == WM_CLOSE
		INVOKE		EndDialog, hWnd, NULL  
		INVOKE		PostQuitMessage, 0
	.ELSE
		INVOKE	DefWindowProc, hWnd, localMsg, wParam, lParam
		jmp		WinProcExit
	.ENDIF
Show:
	INVOKE ShowOutput, addr Infix
WinProcExit:
	ret
MessageHandler ENDP

;Show Output in text edit
ShowOutput PROC,
	infix: PTR BYTE

	LOCAL output[1024]: BYTE
	INVOKE	R2C, infix, addr output
	INVOKE	SendMessage, hEdit, WM_SETTEXT, 0, addr output
	ret
ShowOutput ENDP

ShowResult PROC,
	result: PTR BYTE
	INVOKE	SendMessage, hResult, WM_SETTEXT, 0, result
	ret
ShowResult ENDP

;pushbutton number, Num is Macro of Button
;If is start of number, clear output and input number
;Or add number at the end of output
NumHandler PROC USES eax esi, 
	Num:DWORD,
	infix: PTR BYTE 

	mov eax, Num
	sub eax, 952

	mov		esi, infix
	.WHILE  BYTE PTR [esi] != 0
		inc		esi
	.ENDW

	mov		BYTE PTR [esi], al
	mov		BYTE PTR [esi + 1], 0

	ret
NumHandler ENDP

GeneralHandler PROC USES esi,
	infix: PTR BYTE,
	op: BYTE

	mov		esi, infix
	.WHILE BYTE PTR [esi] != 0
		inc		esi
	.ENDW

	mov		al, op
	mov		BYTE PTR [esi], al
	mov		BYTE PTR [esi + 1], 0
	ret
GeneralHandler ENDP

SingleOpHandler PROC USES esi,
	infix: PTR BYTE,
	op: BYTE

	mov		esi, infix
	.WHILE BYTE PTR [esi] != 0
		inc		esi
	.ENDW

	mov		al, op
	mov		BYTE PTR [esi], al
	inc		esi
	mov		BYTE PTR [esi], '('
	inc		esi
	mov		BYTE PTR [esi], 0
	
	ret
SingleOpHandler ENDP

;pushbutton backspace
;If there is only one '0', return
;Or delete one number
BackspaceHandler PROC USES esi,
	infix: PTR BYTE

	;find the end of infix
	mov		esi, infix
	.WHILE BYTE PTR [esi] != 0
		inc		esi
	.ENDW

	; the infix string is empty
	.IF esi == infix
		jmp		BackspaceReturn
	; not empty
	.ELSEIF esi > infix
		mov		BYTE PTR [esi - 1], 0
	.ENDIF
BackspaceReturn:
	ret
BackspaceHandler ENDP

EqualHandler PROC USES eax,
	infix: PTR BYTE
	LOCAL preprocessed[1024]: BYTE

	.IF	BYTE PTR Infix[256] != 0
		INVOKE	ShowResult, addr LengthError
		jmp		ReturnEqual
	.ENDIF

	INVOKE	PreProcess, infix, addr preprocessed
	.IF eax == 0
		INVOKE	ShowResult, addr SyntaxError
		jmp		ReturnEqual
	.ENDIF
	INVOKE	RPN, addr preprocessed, addr Postfix, addr CharStack
	.IF eax == 0
		INVOKE	ShowResult, addr SyntaxError
		jmp		ReturnEqual
	.ENDIF
	INVOKE	Calculate, addr Postfix, addr Output
	.IF eax == 0
	.ELSEIF eax == 1
		INVOKE	ShowResult, addr UnderflowError
		jmp		ReturnEqual
	.ELSEIF eax == 2
		INVOKE	ShowResult, addr OverflowError
		jmp		ReturnEqual
	.ELSEIF eax == 3
		INVOKE	ShowResult, addr ZeroDividError
		jmp		ReturnEqual
	.ELSEIF eax == 4
		INVOKE	ShowResult, addr UnderflowError
		jmp		ReturnEqual
	.ELSEIF eax == 5
		INVOKE	ShowResult, addr SyntaxError
		jmp		ReturnEqual
	.ENDIF
	INVOKE	ShowResult, addr Output
ReturnEqual:
	ret
EqualHandler ENDP

RPN PROC	USES esi edi edx,
	infix: PTR BYTE, 
	postfix: PTR BYTE,
	buffer: PTR BYTE
	; Pointer for infix address
	mov		esi, infix	
	; Pointer for postfix address
	mov		edi, postfix
	; Pointer for the top of operator stack
	; The first symbol in the stack is a '$'.
	mov		edx, buffer
	inc		edx
	.WHILE BYTE PTR [esi] != 0
		.IF BYTE PTR [esi] == '('
			mov		al, [esi]
			mov		[edx], al
			inc		esi
			inc		edx
		.ELSEIF BYTE PTR [esi] == ')'
			dec		edx
			.WHILE BYTE PTR [edx] != '('
				; Pop to the bottom and '(' still not found
				; Brackets mismatch
				.IF BYTE PTR [edx] == '$'
					mov		eax, 0
					jmp		ReturnRPN
				.ENDIF
				mov		al, [edx]
				mov		[edi], al
				dec		edx
				inc		edi
			.ENDW
			; move to next character in infix
			inc		esi

		.ELSEIF BYTE PTR [esi] == '+'
			; move the stack pointer to the top operator
			dec		edx
			.WHILE 1

				; Stack is empty
				.IF BYTE PTR [edx] == '$'
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF


				mov		al, [edx]
				INVOKE	GetPreOrder, al
				; If the top operator in the stack has a higher or equal
				; precedence order, pop it and put it to the postfix string.
				.IF al >= PRE_ADD
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			; move the stack pointer to a blank address
			inc		edx
			; move to next character in infix
			inc		esi

		.ELSEIF BYTE PTR [esi] == '-'
			; move the stack pointer to the top operator
			dec		edx
			.WHILE 1

				; Stack is empty
				.IF BYTE PTR [edx] == '$'
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF


				mov		al, [edx]
				INVOKE	GetPreOrder, al
				; If the top operator in the stack has a higher or equal
				; precedence order, pop it and put it to the postfix string.
				.IF al >= PRE_SUB
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			; move the stack pointer to a blank address
			inc		edx
			; move to next character in infix
			inc		esi


		.ELSEIF BYTE PTR [esi] == '*'
			; move the stack pointer to the top operator
			dec		edx
			.WHILE 1

				; Stack is empty
				.IF BYTE PTR [edx] == '$'
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF


				mov		al, [edx]
				INVOKE	GetPreOrder, al
				; If the top operator in the stack has a higher or equal
				; precedence order, pop it and put it to the postfix string.
				.IF al >= PRE_MUL
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					; move the stack pointer to a blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			; move the stack pointer to a blank address
			inc		edx
			; move to next character in infix
			inc		esi

		.ELSEIF BYTE PTR [esi] == '/'
			; move the stack pointer to the top operator
			dec		edx
			.WHILE 1

				; Stack is empty
				.IF BYTE PTR [edx] == '$'
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF


				mov		al, [edx]
				INVOKE	GetPreOrder, al
				; If the top operator in the stack has a higher or equal
				; precedence order, pop it and put it to the postfix string.
				.IF al >= PRE_DIV
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					; move the stack pointer to a blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			; move the stack pointer to a blank address
			inc		edx
			; move to next character in infix
			inc		esi

		.ELSEIF BYTE PTR [esi] == '^'
			; move the stack pointer to the top operator
			dec		edx
			.WHILE 1

				; Stack is empty
				.IF BYTE PTR [edx] == '$'
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF


				mov		al, [edx]
				INVOKE	GetPreOrder, al
				; If the top operator in the stack has a higher or equal
				; precedence order, pop it and put it to the postfix string.
				.IF al >= PRE_POW
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					; move the stack pointer to a blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			; move the stack pointer to a blank address
			inc		edx
			; move to next character in infix
			inc		esi

		.ELSEIF BYTE PTR [esi] == 's'
			; move the stack pointer to the top operator
			dec		edx
			.WHILE 1

				; Stack is empty
				.IF BYTE PTR [edx] == '$'
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF


				mov		al, [edx]
				INVOKE	GetPreOrder, al
				; If the top operator in the stack has a higher or equal
				; precedence order, pop it and put it to the postfix string.
				.IF al >= PRE_SIN
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					; move the stack pointer to a blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			; move the stack pointer to a blank address
			inc		edx
			; move to next character in infix
			inc		esi

		.ELSEIF BYTE PTR [esi] == 'c'
			; move the stack pointer to the top operator
			dec		edx
			.WHILE 1

				; Stack is empty
				.IF BYTE PTR [edx] == '$'
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF


				mov		al, [edx]
				INVOKE	GetPreOrder, al
				; If the top operator in the stack has a higher or equal
				; precedence order, pop it and put it to the postfix string.
				.IF al >= PRE_COS
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					; move the stack pointer to a blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			; move the stack pointer to a blank address
			inc		edx
			; move to next character in infix
			inc		esi

		.ELSEIF BYTE PTR [esi] == 't'
			; move the stack pointer to the top operator
			dec		edx
			.WHILE 1

				; Stack is empty
				.IF BYTE PTR [edx] == '$'
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF


				mov		al, [edx]
				INVOKE	GetPreOrder, al
				; If the top operator in the stack has a higher or equal
				; precedence order, pop it and put it to the postfix string.
				.IF al >= PRE_TAN
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					; move the stack pointer to a blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			; move the stack pointer to a blank address
			inc		edx
			; move to next character in infix
			inc		esi


		.ELSEIF BYTE PTR [esi] == 'l'
			; move the stack pointer to the top operator
			dec		edx
			.WHILE 1

				; Stack is empty
				.IF BYTE PTR [edx] == '$'
					; move the stack pointer to the blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF


				mov		al, [edx]
				INVOKE	GetPreOrder, al
				; If the top operator in the stack has a higher or equal
				; precedence order, pop it and put it to the postfix string.
				.IF al >= PRE_LN
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					; move the stack pointer to a blank address
					inc		edx
					; put new operator into the stack
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			; move the stack pointer to a blank address
			inc		edx
			; move to next character in infix
			inc		esi

		.ELSEIF BYTE PTR [esi] == 'r'
			dec		edx
			.WHILE 1
				.IF BYTE PTR [edx] == '$'
					inc		edx
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
				mov		al, [edx]
				INVOKE	GetPreOrder, al
				.IF al >= PRE_SQRT
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					inc		edx
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			inc		edx
			inc		esi

		.ELSEIF BYTE PTR [esi] == 'g'
			dec		edx
			.WHILE 1
				.IF BYTE PTR [edx] == '$'
					inc		edx
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
				mov		al, [edx]
				INVOKE	GetPreOrder, al
				.IF al >= PRE_LOG
					mov		al, [edx]
					mov		[edi], al
					dec		edx
					inc		edi
				.ELSE
					inc		edx
					mov		al, [esi]
					mov		[edx], al
					.BREAK
				.ENDIF
			.ENDW
			inc		edx
			inc		esi
		; If the character in infix is digit or point, 
		; just pass it to postfix
		.ELSE
			mov		al, [esi]
			mov		[edi], al
			inc		esi
			inc		edi
		

		.ENDIF
	.ENDW
	dec		edx
	.WHILE BYTE PTR [edx] != '$'
		.IF BYTE PTR [edx] == '('
			mov		eax, 0
			jmp		ReturnRPN
		.ENDIF
		mov		al, [edx]
		mov		[edi], al
		dec		edx
		inc		edi
	.ENDW
	mov		BYTE PTR [edi], 0
ReturnRPN:
	ret
RPN ENDP

END WinMain
