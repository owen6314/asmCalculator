.386
.model flat, stdcall
option casemap:none

include C:\masm32\include\windows.inc 
include C:\masm32\include\user32.inc 
include C:\masm32\include\kernel32.inc 
includelib C:\masm32\lib\user32.lib 
includelib C:\masm32\lib\kernel32.lib

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

;----------DATA----------
.data

ErrorTitle	BYTE			"Error",0
Template		BYTE			"Calculator", 0
PopupTitle	BYTE			"Example", 0
PopupText		BYTE			"Example", 0
WndClass		WNDCLASSEX	<NULL,NULL,WinProc,NULL,NULL,NULL,NULL,NULL,COLOR_WINDOW,NULL,NULL,NULL>
hMainWnd		DWORD		?
hEdit		DWORD		?                    
Output		BYTE			"0.",0,30 dup(0)      


;----------CODE----------
.code

WinProc PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
	mov		eax, localMsg
	.IF eax == WM_LBUTTONDOWN
		INVOKE	MessageBox, hWnd, ADDR PopupText, ADDR PopupTitle, MB_OK
		jmp		WinProcExit
	.ELSE
		INVOKE	DefWindowProc, hWnd, localMsg, wParam, lParam
		jmp		WinProcExit
	.ENDIF
WinProcExit:
	ret
WinProc ENDP

WinMain PROC
LOCAL msg:MSG   
; Get a handle to the current process.
	
	INVOKE	GetModuleHandle, NULL
	.IF	eax == 0
		call		ErrorHandler
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
	invoke	RegisterClassEx,addr WndClass 

	INVOKE	CreateDialogParam, WndClass.hInstance, addr Template, 0, addr WinProc, 0
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

Exit_Program:
	INVOKE	ExitProcess,0
WinMain ENDP

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