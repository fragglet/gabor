; **********************************************************************}
;
;    $Id: wsockvdd.asm,v 1.1 1999/12/09 09:46:55 gabor Exp $
;    This file is part of the Free Component Library
;    Copyright (c) 1999 by Berczi Gabor
;
;    WinSock DOS TSR driver (interfaces the WinSock VDD)
;
;    See the file COPYING.WSD, included in this distribution,
;    for details about the copyright.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;
; **********************************************************************}
;
; This small TSR 
; - loads and installs the VDD
; - hooks the Windows VxD manager calls and emulates managing of the wsock.vxd
; - in addition provides a native API to access the same functions
; - forwards all wsock.vxd and native calls directly to the VDD
;

.model TINY                       ; use tiny memory model (CS=DS=ES=SS)
jumps                             ; enable automatic jump sizing

; global constants

   STACKSIZE     = 100            ; internal stack size
   INTNoFirst    = 60h            ; first interrupt number to use for native API
   INTNoLast     = 6Fh            ; last      "        "    "  "    "    "    "
   INTNoDefault  = 65h            ; default interrupt number to use for  "    "
   INTNoEMS      = 67h            ; Interrupt to exclude from range

   PSP_OFFSET_CMDLINE = 81h       ; offset of command line in PSP

;  VxD IDs

   vxdid_VXDLoader     =  0027h   ; VXD Loader 
   vxdid_WinSock       =  003eh   ; wsock.vxd 

.code 
.8086

print MACRO text                  ; print macro (destroys dx & ah !!!)
	mov    dx, offset text    ; load text string offset in dx
	mov    ah, 09h            ; print text func
	int    21h	
ENDM

LowCaseAL MACRO
        cmp    al, 'A'            ; is char in range 'A'..'Z'?
        jb     $+8
        cmp    al, 'Z'
        ja     $+4
        add    al, 32             ; if yes, then inc. ASCII code with 32
ENDM

ORG 100h                          ; start code at offset 100h

Entry:                            ; execution of the .COM file start here
    jmp realstart                 ; jump to real startup code

.386

VDDDispatch proc
        push   bp
        mov    bp, ax
	mov    ax, cs:VDDHandle   ; ax = VDD handle
	db  0c4h,0c4h, 58h, 02h   ; DispatchCall() WinAPI call
        pop    bp
	ret
VDDDispatch endp


VDDUnLoad proc
	mov    ax, VDDHandle      ; ax = VDD handle
	db  0c4h,0c4h, 58h, 01h   ; UnRegisterModule() WinAPI call
	ret
VDDUnLoad endp

IntProc proc
	jmp short go              ; jump over signature
DrvSign:db  'WSOCKDRVR'           ; driver signature for install check
DrvSignLen: dw  offset DrvSignLen - offset DrvSign
go:
	call   VDDDispatch        ; simply dispatch the call to the VDD
	iret                      ; return from the interrupt
IntProc endp

CheckVXDName proc
        push   es                 ; save used regs
        push   di
        push   si
        push   cx
        push   ax 

        mov    si, dx             ; (caller passed vxd name in ds:[dx])
        mov    di, cs             ; set up es:[di] to point to our vxd-name
        mov    es, di             ; and ds:[si] to point to the name passed
        mov    di, offset vxdname ; by the user program
        mov    cx, cs:vxdnamelen
        
checkloop:
        mov    al, byte ptr ds:[si]
        inc    si                 
        LowCaseAL
        cmp    al, byte ptr es:[di]
        jne    nomatch            ; if a non-matching char is found then abort
        inc    di
        dec    cx
        or     cx, cx             ; end of loop reached?
        jne    checkloop
        clc                       ; signal match
        jmp    checkdone          ; and exit

nomatch:
        stc                       ; signal mismatch
        jmp    checkdone          ; and exit
checkdone:
        pop    ax                 ; restore destroyed regs
        pop    cx
        pop    si
        pop    di  
        pop    es
        ret
CheckVXDName endp

MyVXDLoader proc far
        cmp    ax, 1              ; function code is loadvxd?
        je     loadvxd
        cmp    ax, 2              ; function code is unloadvxd?
        je     unloadvxd
        jmp    calloldvxdloader   ; if not call original VXD manager
loadvxd:
        call   checkvxdname       ; is it the Winsock VXD ?
        jc     calloldvxdloader   ; if not the call original VXD manager
        clc                       ; signal successful load
        jmp    vxdloaddone
unloadvxd:
        call   checkvxdname       ; is it the Winsock VXD ?
        jc     calloldvxdloader   ; if not the call original VXD manager
        clc                       ; signal successful unload
        jmp    vxdloaddone
calloldvxdloader:
        cmp    dword ptr cs:[oldvxdloader], 0
        je     notfound           ; if no original handler available, then exit
        call   dword ptr cs:[oldvxdloader]
notfound:
        stc
vxdloaddone:
        ret
MyVXDLoader endp

MyWinSock proc far
	call   VDDDispatch
        ret
MyWinSock endp

Int2fProc proc
        cmp    ax, 1684h          ; VxD Manager API call ?
	jne    callold2f          ; if not call old int2f handler
GetVXDEntryPoint:
        cmp    bx, vxdid_VXDLoader; VXD Loader call ?
        je     GetVXDLoaderEntryPoint
        cmp    bx, vxdid_WinSock  ; WinSock VXD call ?
        je     GetWinSockEntryPoint
        jmp    callold2f          ; if none of the above, then call old int2f
GetVXDLoaderEntryPoint:
        mov    di, cs
        mov    es, di             ; return address of own VXD Loader
        mov    di, offset MyVXDLoader
        clc
        jmp    int2fdone
GetWinSockEntryPoint:
        mov    di, cs
        mov    es, di             ; return address of own WinSock VXD handler
        mov    di, offset MyWinSock
        clc                       ; signal successful execution
        jmp    int2fdone 
callold2f:
        pushf                     ; call original int2f handler
        call   dword ptr cs:[oldint2f]
int2fdone:
	iret
Int2fProc endp

VDDHandle        dw  0            ; VDD handle
intused          db  0            ; interrupt number hooked
myss             dw  0            ; internal stack segment
mysp             dw  0            ; initial internal stack pointer
userss           dw  0            ; user stack segment
usersp           dw  0            ; user stack pointer
oldint2f         dd  0            ; address original int2f handler
oldvxdloader     dd  0            ; address of original VXD loader
vxdname          db  'wsock.vxd',0; name of the emulated VxD
vxdnamelen       dw  offset vxdnamelen - offset vxdname
stackstart       db  StackSize DUP(0)
stackend         db  0            ; dummy byte used for determinging the end of stack
LastResidentByte db  0            ; dummy byte for determining the offset of the last resident byte

;
; all routines beyond this point are used only 
; in the initialization and DO NOT STAY RESIDENT !!!
;

VDDLoad proc
	mov    si, offset DllName ; ds:si->VDD dll name
	mov    di, offset InitProcName; es:di->initialization routine name (optional)
	mov    bx, offset DispatchProcName; ds:bx->dispatch routine name
	db  0c4h,0c4h, 58h, 00h   ; RegisterModule() WinAPI call
        jc     VDDLoadDone        ; failed to load? (in this case ax contains error code)
	mov    VDDHandle, ax      ; if not, then store the VDD handle get in ax
VDDLoadDone:
        ret
VDDLoad endp

PrintIntUsed proc
        xor    bx, bx
        mov    cl, byte ptr cs:[IntUsed]
        mov    bl, cl
        shr    bl, 4
        mov    al, byte ptr cs:[HexChars+bx]
        mov    cs:[SingleChar], al
        print singlechar
        xor    bx, bx
        mov    bl, cl
        and    bl, 0fh
        mov    al, byte ptr cs:[HexChars+bx]
        mov    cs:[SingleChar], al
        print singlechar
        ret
PrintIntUsed endp

.8086
;IsHexChar proc
;        cmp    al, '0'
;        jb     HCFail
;        cmp    al, 'f'
;        ja     HCFail
;        cmp    al, 'a'
;        jae    HCOK
;        cmp    al, '9'
;        jbe    HCOK
;        jmp    HCFail
;       
;HCOK:
;        clc
;        jmp    HCDone
;HCFail:
;        stc
;HCDone:
;        ret
;IsHexChar endp

ProcessParams proc
        push   ds

        mov    ah, 62h            ; get PSP segment
        int    21h                ; (this is actually not neccessary as this..
        mov    ds, bx             ; is a .COM file, ie. PSP segment = cs )

        mov    si, PSP_OFFSET_CMDLINE
ScanLoop:
        lodsb
        cmp    al, 0dh
        je     DoneScan
        cmp    al, ' '
        jne    NonSpace
        mov    byte ptr cs:[CharCount], 00h
        mov    byte ptr cs:[InSwitch], 00h
        jmp    ScanLoop
NonSpace:
        LowCaseAL
        cmp    byte ptr cs:[CharCount], 00h
        jnz    InString
        cmp    byte ptr cs:[InSwitch], 00h
        jnz    ProcessSwitch
        cmp    al, '-'
        je     SwitchStart
        cmp    al, '/'
        je     SwitchStart
        cmp    al, '?'
        je     SwitchHelp
        jmp    InString

SwitchStart:
        mov    byte ptr cs:[InSwitch], 01h
        jmp    ScanLoop

ProcessSwitch:    
        cmp     al, 'f'
        je      SwitchForceLoad
        cmp     al, 'h'
        je      SwitchHelp
        cmp     al, '?'
        je      SwitchHelp
        jmp     InvalidParam

SwitchForceLoad:
        mov     byte ptr cs:[fForceRun], 01h
        jmp     ScanLoop
SwitchHelp:
        jmp     ShowHelp

InString:
        inc     byte ptr cs:[CharCount]
        mov     ah, byte ptr cs:[CharCount]
        cmp     ah, 1
        je      IntChar1
        cmp     ah, 2
        je      IntChar2
        cmp     ah, 3
        je      IntChar34
        cmp     ah, 4 
        je      IntChar34
        jmp     InvalidParam

IntChar1:
        cmp     al, '0'
        jne     InvalidParam
        mov     cs:[fIntToUse], 0
        jmp     ScanLoop 
IntChar2:
        cmp     al, 'x'
        jne     InvalidParam
        jmp     ScanLoop 

IntChar34:
        cmp     al, '0'
        jb      InvalidParam
        cmp     al, 'f'
        ja      InvalidParam
        cmp     al, 'a'
        jae     HexAlpha
        cmp     al, '9'
        jbe     HexNum
        jmp     InvalidParam

HexAlpha:
        sub     al, ('a'+'0'-10)   ; al := (al-'a')+10 - '0'
HexNum:
        sub     al, '0'
        mov     ah, byte ptr cs:[fIntToUse]
        shl     ah, 4
        or      ah, al
        mov     byte ptr cs:[fIntToUse], ah
        jmp     ScanLoop

DoneScan:
        clc
        jmp    DoneParams
InvalidParam:
        stc
DoneParams:
        pop    ds
        ret
ProcessParams endp

.8086                             ; startup code should run on all processors
realstart:  
        mov    ax, cs             ; initialize segment registers
        mov    ds, ax             ; DS:=CS
        mov    es, ax             ; ES:=CS
        cli                       ; disable ints while switching stack
        mov    ss, ax             ; set up own stack 
        mov    sp, offset stackend; SS:=CS SP:=[stackend]
        and    sp, not 3          ; align stack to avoid AC fault
        sti                       ; re-enable ints
        mov    word ptr cs:[myss], ss
        mov    word ptr cs:[mysp], sp

	print tsrtitle            ; print program name
	print copyright           ; and copyright

        call   ProcessParams
        jnc    ParamsOK
        print InvalidParamStr
        jmp    Terminate

ParamsOK:
        cmp    cs:[fShowHelp], 00h
        jz     NoHelp
        jmp    ShowHelp
NoHelp:
        cmp    cs:[fForceRun], 00h
        jnz    OSOK

        mov    ax, 3306h
        xor    bx, bx
        int    21h
        cmp    al, 0ffh
        je     NoWinNT
        cmp    bl, 05h
        jb     NoWinNT
        cmp    bx, 3205h          ; WinNT DOS box (will this work for W2000+?)
        jne    NoWinNT
        jmp    OSOK

NoWinNT:
        print winntrequired
        jmp   Terminate

OSOK:                             ; operating system is OK

.386                              ; secure to execute 386 instructions 
                                  ; (as WinNT requires at least a 486)

        mov    byte ptr cs:[IntUsed], IntNoFirst
IntCheckLoop:
        push   es
        mov    ah, 35h
        mov    al, byte ptr cs:[IntUsed]
        int    21h                ; get native interrupt vector
        mov    ax, es
        or     ax, ax             ; assigned?
        jz     NotInstalledAtInt  ; if not the continue scan
        mov    di, bx
        add    di, 2
        mov    si, offset DrvSign ; check for signature
        mov    cx, word ptr cs:[DrvSignLen]
        repne cmpsb
        jnz NotInstalledAtInt
        pop    es
        print  alreadyloaded
        call   PrintIntUsed
        print  CRLF
	jmp    Terminate
NotInstalledAtInt:
        pop    es
        inc    byte ptr cs:[IntUsed]
        cmp    byte ptr cs:[IntUsed], IntNoLast
        ja     Load
        jmp    IntCheckLoop

Load:
        mov    al, byte ptr cs:[fIntToUse]

        cmp    al, INTNoEMS
        je     InvalidInt
        cmp    al, INTNoFirst
        jb     InvalidInt
        cmp    al, INTNoLast
        ja     InvalidInt

        mov    byte ptr cs:[IntUsed], al

	call   VDDLoad            ; try to load the VDD
	jc     FailedToLoad

        print vddinitialized

        print usingint
        call  PrintIntUsed
        print CRLF
        
        push   es

        mov    ax, 1684h          
        mov    bx, vxdid_VXDLoader
        int    2fh                ; get address of original VXD loader
        mov    word ptr cs:[oldvxdloader], di
        mov    word ptr cs:[oldvxdloader+2], es

        mov    ah, 35h
        mov    al, 2fh
        int    21h                ; store original int2f handler
        mov    word ptr cs:[OldInt2f], bx
        mov    word ptr cs:[OldInt2f+2], es

        pop    es

        mov    ah, 25h
        mov    al, 2fh
        mov    dx, offset Int2fProc
        int    21h                ; set up our own int2f handler

        mov    ah, 25h
	mov    al, cs:[IntUsed]
        mov    dx, offset IntProc
	int    21h                ; set up native handler

        mov    ah, 4ah
        mov    bx, offset LastResidentByte
        shr    bx, 4
        inc    bx
        int    21h                ; resize memory block allocated for the TSR

        mov    ah, 31h
        mov    dx, offset LastResidentByte
        shr    dx, 4
        inc    dx
        mov    al, 0
        int    21h                ; Terminate-but-Stay-Resident
        jmp    Terminate          ; (this is actually redundant)

InvalidInt:
        print  InvalidIntNo
        jmp    Terminate

ShowHelp:
        print  HelpMsg            ; print help text
        jmp    ExitNow            ; then exit

FailedToLoad:
	print failedtoinitvdd     ; display error message
Terminate:
        print notloaded
ExitNow:
        mov    ax,4c01h           ; terminate program (error code 1)
        int    21h


tsrtitle         db  "WSOCKVDD 1.1",13,10,'$'
copyright        db  "Copyright (c) 1999 B‚rczi G bor",13,10,'$'
failedtoinitvdd  db  "failed to initialize the VDD",13,10,'$'
VDDInitialized	 db  "VDD successfully loaded.",13,10,'$'
UsingInt         db  "Using software interrupt 0x",'$'
CRLF             db  13,10,'$'
SingleChar       db  "?",'$'
HexChars         db  "0123456789ABCDEF"
alreadyloaded	 db  "WSOCKVDD already installed at interrupt 0x",'$'
winntrequired    db  "Run this program in a DOS box under Windows NT!",13,10,'$'
notloaded        db  "Program not loaded.",13,10,'$'
helpmsg          db  13,10
                 db  "Usage: WSOCKVDD [options] [intno]",13,10
;                 db  "  <intno> should be specified in C hex format",13,10
                 db  "   -h -- display this help screen",13,10
                 db  "   -f -- Force to load TSR (even if WinNT is not detected)",13,10
                 db  13,10
                 db  "Example: WSOCKVDD -f 0x60",13,10
                 db  '$'
invalidparamstr  db  "Invalid parameter specified",13,10,'$'
invalidintno     db  "Invalid interrupt number specified",13,10,'$'

DllName		 db  "wsockvdd.dll",0
InitProcName	 db  "VDDRegisterInit",0
DispatchProcName db  "VDDDispatch",0

CharCount        db  0
InSwitch         db  0
fIntToUse        db  IntNoDefault
fShowHelp        db  0
fForceRun        db  0

end Entry

end
;
;  $Log: wsockvdd.asm,v $
;
;  Revision 1.0  1999/11/27 09:46:55  gabor
;     Original implementation
;
;  Revision 1.1  1999/12/09 09:46:55  gabor
;     [+] Added command line parameter handling 
;     [+] Added check for WinNT on startup 
;     [*] Native API moved (default int is 65h, but customizable in range 60h-6fh)
;
