.386
.model flat, stdcall
option casemap:none

;include Irvine32.inc

include C:\masm32\include\windows.inc 
include C:\masm32\include\user32.inc 
include C:\masm32\include\kernel32.inc 
include C:\masm32\include\shell32.inc
include C:\masm32\include\masm32.inc

includelib C:\masm32\lib\user32.lib 
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\masm32.lib



;--------CONSTANT--------
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
IDC_FAC		equ		1014
IDC_PULSMINUS	equ		1015
IDC_PI		equ		1016
IDC_RBRACKET	equ		1030
IDC_LBRACKET	equ		1031
IDC_BACKSPACE	equ		1040
IDC_C		equ		1041
IDC_CE		equ		1042
IDC_SHIFT		equ		1043
IDC_EQU		equ		1044
IDC_POINT		equ		1045
IDD_CAL		equ		2000
IDC_DISPLAY	equ		2001
;----------function declaration-----------
InitCal PROTO
ShowOutput PROTO
GetCurNum PROTO :DWORD
GetResult PROTO
ShowResult PROTO
MessageHandler PROTO :DWORD,:DWORD, :DWORD, :DWORD 
NumHandler PROTO: DWORD
ErrorHandler PROTO

;----------DATA----------
.data

ErrorTitle		BYTE			"Error",0
Template		BYTE			"Calculator", 0
PopupTitle		BYTE			"Example", 0
PopupText		BYTE			"Example", 0
WndClass		WNDCLASSEX		<NULL,NULL,MessageHandler,NULL,NULL,NULL,NULL,NULL,COLOR_WINDOW,NULL,NULL,NULL>

hMainWnd		DWORD			?
hEdit			DWORD			?
                    
Output			BYTE			"0", 0, 50 dup(0)   
Operator		BYTE			'.'   

;operands stored in calculator
lOperand		dq				0.0
rOperand		dq				0.0
Result			dq				0.0
;use to decide if two floats are equal
Epsilon			dq				1.0E-18
Zero			dq				0.0

IsStart			BYTE			1
;error code: divided by zero = 1
ErrorCode		BYTE			0

;error message
DividedByZero   BYTE			"Divided by Zero!", 0

;----------CODE----------
.code

WinMain PROC
LOCAL msg:MSG   
	
	; Get a handle to the current process.
	INVOKE	GetModuleHandle, NULL
	.IF	eax == 0
		call	ErrorHandler
		jmp		Exit_Program
	.ENDIF

	mov		WndClass.hInstance, eax
	mov		WndClass.cbSize,sizeof WNDCLASSEX 
	mov		WndClass.style,CS_BYTEALIGNWINDOW or CS_BYTEALIGNWINDOW 
	mov		WndClass.cbClsExtra,0 
	mov		WndClass.cbWndExtra,DLGWINDOWEXTRA
	mov		WndClass.hbrBackground,COLOR_BTNFACE+1  
	mov		WndClass.lpszMenuName,NULL              
	mov		WndClass.lpszClassName,OFFSET  Template    
	;INVOKE LoadIcon,hInst,addr IconName 
	;mov WndClass.hIcon,eax
	;INVOKE LoadCursor,NULL,IDC_ARROW
	;mov WndClass.hCursor,eax
	;mov WndClass.hIconSm,0
	INVOKE	RegisterClassEx,addr WndClass 

	INVOKE	CreateDialogParam, WndClass.hInstance, addr Template, 0, addr MessageHandler, 0
	mov		hMainWnd, eax
	.IF	eax == 0
		call	ErrorHandler
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

Exit_Program:
	INVOKE	ExitProcess,0
WinMain ENDP

;----------------------------------funcitonal procedure------------------------
;init calculator
InitCal PROC
	mov IsStart, 1
	mov ErrorCode, 0
	finit
	fldz
	fst lOperand
	fst rOperand
	fst Result
	INVOKE ShowResult
	INVOKE ShowOutput
	ret
InitCal ENDP

;Show Output in text edit
ShowOutput PROC
	.IF ErrorCode == 1
		INVOKE SendMessage, hEdit, WM_SETTEXT, 0, addr DividedByZero
		mov IsStart, 1
	.ELSE
		INVOKE SendMessage, hEdit, WM_SETTEXT, 0, addr Output
	.ENDIF
	ret
ShowOutput ENDP

;get current number in Output, store it in rOperand
GetCurNum PROC, Dest:DWORD
	INVOKE StrToFloat, addr Output, Dest
	ret
GetCurNum ENDP

;get result using Operator and l,roperand
GetResult PROC
	finit
	.IF Operator == '+'
		fld lOperand
		fadd rOperand
		fstp Result
	.ELSEIF Operator == '*'
		fld lOperand
		fmul rOperand
		fstp Result
	.ELSEIF Operator == '-'
		fld lOperand
		fsub rOperand
		fstp Result
	;TODO:Divide by zero
	.ELSEIF Operator == '/'
		fld rOperand
		fldz
		fcomi ST(0), ST(1)
		jnz Divide
		mov ErrorCode, 1
		ret
	Divide:
		finit
		fld lOperand
		fdiv rOperand
		fstp Result
	.ENDIF
	ret
GetResult ENDP

;set output to result and show output
;warning: floattostring uses esi and edi
ShowResult PROC
	INVOKE FloatToStr2, Result, addr Output
	INVOKE ShowOutput
	ret
ShowResult ENDP

;----------------------------------specific handler-------------------------------

;pushbutton number, Num is Macro of Button
;If is start of number, clear output and input number
;Or add number at the end of output
NumHandler PROC, Num:DWORD
	.IF ErrorCode != 0
		mov ErrorCode, 0
	.ENDIF
	;eax: current number
	mov eax, Num
	sub eax, 952
	;start new number
	.IF IsStart == 1
		mov esi, offset Output
		mov [esi], eax
		inc esi
		mov BYTE PTR[esi], 0
		mov IsStart, 0
	;continue with origin number
	.ELSE
		mov esi, offset Output
		.WHILE BYTE PTR[esi] != 0
			inc esi
		.ENDW
		mov [esi], eax
		inc esi
		mov BYTE PTR[esi], 0
	.ENDIF
	ret
NumHandler ENDP

;pushbutton point
;If already have point, return
;Or add point at the end of Output
PointHandler PROC
	.IF IsStart == 0
		mov esi, offset Output
		.WHILE BYTE PTR[esi] != 0
			.IF BYTE PTR[esi] == '.'
				jmp PointReturn
			.ENDIF
			inc esi
		.ENDW
		mov BYTE PTR[esi], '.'
		mov BYTE PTR[esi + 1], 0
	.ENDIF
PointReturn:
	ret
PointHandler ENDP

;pushbutton backspace
;If there is only one '0', return
;Or delete one number
BackspaceHandler PROC
	mov esi, offset Output
	.IF (BYTE PTR[esi] == '0') && (BYTE PTR[esi + 1] == 0)
		jmp BackspaceReturn
	.ELSE
		.WHILE BYTE PTR[esi] != 0
			inc esi
		.ENDW
		mov BYTE PTR[esi - 1], 0
	.ENDIF
	;update IsStart
	mov esi, offset Output
	.IF BYTE PTR[esi] == 0
		mov BYTE PTR[esi], '0'
		mov BYTE PTR[esi + 1], 0
		mov IsStart, 1
	.ENDIF
BackspaceReturn:
	ret
BackspaceHandler ENDP

;four operators handler
;If Operator is not '.' while pushing button, calculate and update Output first
AddHandler PROC
	.IF Operator == '.'
		INVOKE GetCurNum, addr lOperand
		mov Operator, '+'
		mov IsStart, 1
	.ELSE
		INVOKE GetCurNum, addr rOperand
		INVOKE GetResult
		INVOKE ShowResult
		INVOKE GetCurNum, addr lOperand
		mov Operator, '+'
		mov IsStart, 1
	.ENDIF
	ret
AddHandler ENDP

SubHandler PROC
	.IF Operator == '.'
		INVOKE GetCurNum, addr lOperand
		mov Operator, '-'
		mov IsStart, 1
	.ELSE
		INVOKE GetCurNum, addr rOperand
		INVOKE GetResult
		INVOKE ShowResult
		INVOKE GetCurNum, addr lOperand
		mov Operator, '-'
		mov IsStart, 1
	.ENDIF
	ret
SubHandler ENDP

MulHandler PROC
	.IF Operator == '.'
		INVOKE GetCurNum, addr lOperand
		mov Operator, '*'
		mov IsStart, 1
	.ELSE
		INVOKE GetCurNum, addr rOperand
		INVOKE GetResult
		INVOKE ShowResult
		INVOKE GetCurNum, addr lOperand
		mov Operator, '*'
		mov IsStart, 1
	.ENDIF
	ret
MulHandler ENDP

DivHandler PROC
	.IF Operator == '.'
		INVOKE GetCurNum, addr lOperand
		mov Operator, '/'
		mov IsStart, 1
	.ELSE
		INVOKE GetCurNum, addr rOperand
		INVOKE GetResult
		INVOKE ShowResult
		INVOKE GetCurNum, addr lOperand
		mov Operator, '/'
		mov IsStart, 1
	.ENDIF
	ret
DivHandler ENDP

;pushbutton equal
EqualHandler PROC
	.IF Operator == '.'
	.ELSE
		INVOKE GetCurNum, addr rOperand
		INVOKE GetResult
		INVOKE ShowResult
		INVOKE GetCurNum, addr lOperand
		mov IsStart, 1
		mov Operator, '.'
	.ENDIF
	ret
EqualHandler ENDP

;pushbutton clear
ClearHandler PROC
	INVOKE InitCal
	ret
ClearHandler ENDP


;-----------------------------------main message handler--------------------------
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
		;init
		mov IsStart, 1
		jmp Show

	.ELSEIF eax == WM_COMMAND
		mov eax, wParam
		.IF (eax >= IDC_NUM0) && (eax <= IDC_NUM9)
			INVOKE NumHandler, eax
			jmp Show
		.ELSEIF eax == IDC_POINT
			INVOKE PointHandler
			jmp Show
		.ELSEIF eax == IDC_BACKSPACE
			INVOKE BackspaceHandler
			jmp Show
		.ELSEIF eax == IDC_ADD
			INVOKE AddHandler
			jmp Show
		.ELSEIF eax == IDC_SUB
			INVOKE SubHandler
			jmp Show
		.ELSEIF eax == IDC_MUL
			INVOKE MulHandler
			jmp Show
		.ELSEIF eax == IDC_DIV
			INVOKE DivHandler
			jmp Show
		.ELSEIF eax == IDC_EQU
			INVOKE EqualHandler
			jmp Show
		.ELSEIF eax == IDC_C
			INVOKE ClearHandler
			jmp Show
		.ELSE
			jmp WinProcExit
		.ENDIF

	;input char via keyboard
	.ELSEIF eax == WM_CHAR
		INVOKE MessageBox, hWnd, ADDR PopupText, ADDR PopupTitle, MB_OK

	.ELSE
		INVOKE	DefWindowProc, hWnd, localMsg, wParam, lParam
		jmp		WinProcExit
	.ENDIF
Show:
	INVOKE ShowOutput
WinProcExit:
	ret
MessageHandler ENDP

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


END WinMain