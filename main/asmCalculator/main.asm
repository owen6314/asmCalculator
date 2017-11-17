include calculator.inc

;----------DATA----------------
.data
ErrorTitle		BYTE			"Error",0
ClassName		BYTE			"WinClass", 0
BtnClassName    BYTE			"button", 0
MenuName		BYTE			"MainMenu", 0
SimpleBtnText	BYTE			"Simple", 0
SciBtnText		BYTE			"Science", 0
MainProcName	BYTE			"Calculator", 0

SimpleCalPath	BYTE			"simpleCalculator.exe", 0
SciCalPath		BYTE			"sciCalculator.exe", 0
DocUrl			BYTE			"https://hackmd.io/CYBgLAhhCMCm0FoBmckLAJgEYA4FYwE5CEA2LJAZmFMMp1lkqA==", 0
HomepageUrl		BYTE			"https://github.com/owen6314/asmCalculator", 0
HelpTxt			BYTE			"像用普通的计算器那样用", 0

MidDeviceID		dd				0
szMIDISeqr		db				"Sequencer", 0
FranceMidiName	db				"twotigers.mid", 0
GreeceMidiName	db				"background.midi", 0
szOpen			BYTE			"open", 0
;application handler
hParentWnd		DWORD			?
;main window handler
hWindow			DWORD			?
hSimpleBtn		DWORD			?
hSciBtn			DWORD			?
hMenu			DWORD			?
processInfo		PROCESS_INFORMATION<>

;----------CODE----------
.code
WinMain PROC
	LOCAL msg:MSG  
	LOCAL WndClass:WNDCLASSEX
	INVOKE	GetModuleHandle, NULL
	.IF	eax == 0
		call	ErrorHandler
		jmp		ExitLoop
	.ENDIF
	mov	hParentWnd, eax
	mov		WndClass.cbSize, sizeof WNDCLASSEX 
	mov		WndClass.style, CS_HREDRAW or CS_VREDRAW
	mov		WndClass.lpfnWndProc, OFFSET MessageHandler
	mov		WndClass.cbClsExtra, 0 
	mov		WndClass.cbWndExtra, 0
	;why use push/pop here?
	push	hParentWnd
	pop		WndClass.hInstance
	mov	    WndClass.cbWndExtra, DLGWINDOWEXTRA
	mov		WndClass.hbrBackground, COLOR_BTNFACE + 1  
	mov		WndClass.lpszMenuName, OFFSET MenuName          
	mov		WndClass.lpszClassName, OFFSET ClassName
	;TODO: still need to change the icon
	;INVOKE  LoadIcon, 0, IDB_PNG1
	;mov		WndClass.hIcon, eax
	;mov		WndClass.hIconSm, eax
	INVOKE	RegisterClassEx,addr WndClass 
	INVOKE  CreateWindowEx, NULL, addr ClassName , addr MainProcName, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT,
	600, 400, 0, 0, hParentWnd, 0

	mov hWindow, eax
	INVOKE	ShowWindow, hWindow, SW_SHOWNORMAL
	INVOKE	UpdateWindow, hWindow 

StartLoop:
	INVOKE	GetMessage,addr msg,0,0,0
	cmp		eax,0
	je		ExitLoop
	INVOKE	TranslateMessage,addr msg
	INVOKE	DispatchMessage,addr msg    
	jmp		StartLoop  
ExitLoop:
	INVOKE ExitProcess, 0
WinMain ENDP
;-----------------------------------function----------------------------
DrawBackGround PROC

	ret
DrawBackGround ENDP

;play midi file, need current window handler
PlayMidi PROC hWin:DWORD, FileName:DWORD
LOCAL mciOpenParms:MCI_OPEN_PARMS, mciPlayParms:MCI_PLAY_PARMS
	mov eax, hWin
	mov mciPlayParms.dwCallback, eax
	mov eax, OFFSET szMIDISeqr
	mov mciOpenParms.lpstrDeviceType, eax
	mov eax, FileName
	mov mciOpenParms.lpstrElementName, eax
	invoke mciSendCommand, 0, MCI_OPEN,MCI_OPEN_TYPE or MCI_OPEN_ELEMENT, ADDR mciOpenParms
	mov eax, mciOpenParms.wDeviceID
	mov MidDeviceID, eax
	invoke mciSendCommand, MidDeviceID, MCI_PLAY, MCI_NOTIFY, ADDR mciPlayParms 
	ret 
PlayMidi endp
;-----------------------------------main message handler--------------------------
MessageHandler PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
	LOCAL startInfo:STARTUPINFO
	mov eax, localMsg
	.IF eax == WM_CREATE
		;INVOKE CreateWindowEx, NULL, addr BtnClassName, addr SimpleBtnText, WS_CHILD or WS_VISIBLE, 100, 100, 100, 60, hWnd, IDC_SIMPLEBTN, hParentWnd, 0
		;mov hSimpleBtn, eax
		;INVOKE CreateWindowEx, NULL, addr BtnClassName, addr SciBtnText, WS_CHILD or WS_VISIBLE, 400, 100, 100, 60, hWnd, IDC_SCIBTN, hParentWnd, 0
		;mov hSciBtn, eax
		jmp WinProcExit

	.ELSEIF eax == WM_PAINT
		INVOKE DrawBackGround
		jmp WinProcExit
	.ELSEIF eax == WM_COMMAND
		mov eax, wParam
		.IF eax == IDC_SIMPLEBTN || eax == ID_SIMPLE
			.IF processInfo.hProcess != 0
				INVOKE CloseHandle, processInfo.hProcess
				mov processInfo.hProcess, 0
			.ENDIF
			INVOKE GetStartupInfo, addr startInfo
			INVOKE CreateProcess, addr SimpleCalPath, NULL, NULL, NULL, FALSE, NORMAL_PRIORITY_CLASS, NULL, NULL, addr startInfo, addr processInfo
			jmp WinProcExit
		.ELSEIF eax == IDC_SCIBTN || eax == ID_SCI
			.IF processInfo.hProcess != 0
			INVOKE CloseHandle, processInfo.hProcess
			mov processInfo.hProcess, 0
			.ENDIF
			INVOKE GetStartupInfo, addr startInfo
			INVOKE CreateProcess, addr SciCalPath, NULL, NULL, NULL, FALSE, NORMAL_PRIORITY_CLASS, NULL, NULL, addr startInfo, addr processInfo
			jmp WinProcExit
		.ELSEIF eax == ID_DOC
			INVOKE ShellExecute, NULL, addr szOpen, addr DocUrl, NULL, NULL, SW_SHOWNORMAL
			jmp WinProcExit
		.ELSEIF eax == ID_HOMEPAGE
			INVOKE ShellExecute, NULL, addr szOpen, addr HomepageUrl, NULL, NULL, SW_SHOWNORMAL
			jmp WinProcExit
		.ELSEIF eax == ID_HELP
			INVOKE MessageBox, NULL, addr HelpTxt, addr MainProcName, MB_OK
			jmp WinProcExit
		.ELSEIF eax == ID_FRANCE
			INVOKE PlayMidi, hWindow, addr FranceMidiName
			jmp WinProcExit
		.ELSEIF eax == ID_GREECE
			INVOKE PlayMidi, hWindow, addr GreeceMidiName
			jmp WinProcExit
		.ELSEIF eax == ID_EXIT
			INVOKE DestroyWindow, hWindow
		.ENDIF
	.ELSEIF eax == WM_DESTROY
		INVOKE DestroyWindow, hWindow
		jmp	WinProcExit
	.ELSE
		INVOKE	DefWindowProc, hWnd, localMsg, wParam, lParam
		jmp		WinProcExit
	.ENDIF

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