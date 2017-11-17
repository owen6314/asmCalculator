.386
.model flat, stdcall
option casemap:none


include windows.inc 
include user32.inc 
include kernel32.inc 
include shell32.inc
include masm32.inc
include winmm.inc
includelib user32.lib 
includelib kernel32.lib
includelib masm32.lib
includelib winmm.lib

;--------CONSTANT----------------------
IDC_SIMPLEBTN	equ			3000
IDC_SCIBTN		equ			3001	
ID_HOMEPAGE     equ         40003
ID_DOC			equ			40004
ID_EXIT         equ         40006
ID_SIMPLE       equ         40007
ID_SCI			equ			40008
ID_HELP         equ         40009
ID_FRANCE		equ			40010
ID_GREECE		equ			40011
;----------function declaration-----------
WinMain PROTO
MessageHandler PROTO :DWORD,:DWORD, :DWORD, :DWORD 
ErrorHandler PROTO
ExitProcess PROTO, dwExitCode:DWORD
PlayMidi PROTO :DWORD, :DWORD
DrawBackGround PROTO


