{
    $Id: abisocks.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Trumpet TCP/IP protocol stack API routines (TCPDRV)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 **********************************************************************}
unit ABISocks;

interface

const
     abi_cmd_InstallCheck       = $00;
     abi_cmd_UnLoadDriver       = $01;
     abi_cmd_PerformIO          = $02;
     abi_cmd_GetCriticalFlag    = $03;
     abi_cmd_GetDriverInfo      = $04;
     abi_cmd_OpenTCPSession     = $10;
     abi_cmd_CloseTCPSession    = $11;
     abi_cmd_GetTCPData         = $12;
     abi_cmd_PutTCPData         = $13;
     abi_cmd_GetTCPStatus       = $14;

     abi_cmd_AttachEventGlobal  = $40;
     abi_cmd_DetachEventGlobal  = $41;

     abi_err_OK                 = 0;
     abi_err_BadCall            = 1;
     abi_err_Critical           = 2;
     abi_err_NoHandles          = 3;
     abi_err_BadHandle          = 4;
     abi_err_Timeout            = 5;
     abi_err_BadSession         = 6;
     abi_err_NotAttached        = 7; {?? Is it this constant? }
     abi_err_AlreadyAttached    = 8; {?? Is it this constant? }
     abi_err_BufferOverflow     = 9; { Local to this unit }

     timeout_NonBlocking        = 0;
     timeout_Infinite           = $ffff;

     tcp_open_Normal            = 0;
     tcp_open_Listener          = 1;
     tcp_open_Async             = 128;

     tcp_get_WaitTillFull       = 0;
     tcp_get_GetAndReturn       = 1;
     tcp_get_UntilCRLF          = 2; { CRLF will not be included in buffer }
     tcp_get_Async              = 128;

     tcp_put_Normal             = 0; { wait until data delivered }
 {*} tcp_put_PutAndReturn       = 1; { put as much as possible & return }
     tcp_put_AppendCRLF         = 2; { append CRLF to data }
     tcp_put_Push               = 4; { wait till acknowledged }
     tcp_put_UrgentData         = 8; { send as soon as possible }

     tcp_stat_Normal            = 0;
     tcp_stat_Async             = 128;

     tcp_close_Normal           = 0;
     tcp_close_Abort            = 1;
     tcp_close_Async            = 128;

     tcp_state_Closed          = 0;
     tcp_state_Listen          = 1;
     tcp_state_Syn_Sent        = 2;
     tcp_state_Syn_Received    = 3;
     tcp_state_Established     = 4;
     tcp_state_Wait_1          = 5;
     tcp_state_Wait_2          = 6;
     tcp_state_Close_Wait      = 7;
     tcp_state_Closing         = 8;
     tcp_state_Last_ACK        = 9;
     tcp_state_Time_Wait       = 10;

     abi_port_Any              = 0;
     abi_port_Invalid          = $ffff;

     abi_invalid_socket        = $ffff;

type
     TLong = packed record LoW, HiW: word; end;

     TABISocket = word;

     TABIDriverInfo = packed record
       MyIP       : longint;
       NetMask    : longint;
       Gateway    : longint;
       DNSServer  : longint;
       TimeServer : longint;
       MTU        : word;
       DefaultTTL : byte;
       DefaultTOS : byte;
       TCP_MSS    : word;
       TCP_RWIN   : word;
       Debug      : word;
       Domain     : string;
     end;

     TIPSessionInfo = packed record
       SourceIP  : longint;
       SourcePort: word;
       DestIP    : longint;
       DestPort  : word;
       Protocol  : byte;
       Active    : byte;
     end;

     TTCPStatusRec = record
       TCPState     : byte;
       BytesToRead  : word;
       BytesPending : word;
       SessionInfo  : TIPSessionInfo;
     end;

function ABIInit: boolean;
function ABIUnLoad: boolean;
function ABIDoIO: boolean;
function ABIGetCriticalFlag: byte;
function ABIAttachEventGlobal(EventHandler: pointer): boolean;
function ABIDetachEventGlobal(EventHandler: pointer): boolean;

{$ifndef FPC}
procedure ABIInstallTimer;
procedure ABIDeInstallTimer;
{$endif}

function TCPOpen(Flags: byte; LocalPort: word;
                 DestIP: longint; DestPort: word; TimeOut: word; var Handle: TABISocket): word;
function TCPGet(Handle: TABISocket; Flags: byte; var Buffer; var BufSize: word; TimeOut: word): boolean;
function TCPPut(Handle: TABISocket; Flags: byte; var Buffer; var BufSize: word; TimeOut: word): boolean;
function TCPGetStatus(Handle: TABISocket; Flags: byte; var Status: TTCPStatusRec): boolean;
function TCPClose(Handle: TABISocket; Flags: byte; TimeOut: word): boolean;

const ABIDriverInt        : byte = 0;
      ABITimeOutSupported : boolean = false;
      ABIAsyncIOSupported : boolean = false;
      ABIError            : integer = 0;
      ABIFreeInputPackets : integer = 0;
      ABIFreeOutputPackets: integer = 0;
      ABICriticalFlagAddr : pointer = nil;
      ABIInCall           : boolean = false;
      ABIForceIO          : boolean = true;

var ABIDriverInfo : TABIDriverInfo;

function IP(B1,B2,B3,B4: byte): longint;
function IPStr(IP: string): longint;
function FormatIP(IP: longint): string;
procedure SplitIP(IP: longint; var B1,B2,B3,B4: byte);

implementation

uses Dos,PMode;

const ABIInited : boolean = false;
      ABIOnTimer: boolean = false;
      ABIInDoIO : boolean = false;

      OldInt1C  : procedure = nil;

type
    TIPRec = packed record
      Octets: array[1..4] of byte;
    end;

function IntToStr(L: longint): string;
var S: string[20];
begin
  Str(L,S);
  IntToStr:=S;
end;

function StrToInt(const S: string): longint;
var L: longint;
    C: integer;
begin
  Val(S,L,C); if C<>0 then L:=0;
  StrToInt:=L;
end;

function FormatIP(IP: longint): string;
var S: string[20];
    I: integer;
begin
  S:='';
  for I:=1 to 4 do
    begin
      if I<>1 then S:=S+'.';
      S:=S+IntToStr(TIPRec(IP).Octets[I]);
    end;
  FormatIP:=S;
end;

procedure SplitIP(IP: longint; var B1,B2,B3,B4: byte);
begin
  with TIPRec(IP) do
    begin
      B1:=Octets[1];
      B2:=Octets[2];
      B3:=Octets[3];
      B4:=Octets[4];
    end;
end;

function IP(B1,B2,B3,B4: byte): longint;
var L: longint;
begin
  with TIPRec(L) do
    begin
      Octets[1]:=B1;
      Octets[2]:=B2;
      Octets[3]:=B3;
      Octets[4]:=B4;
    end;
  IP:=L;
end;

function IPStr(IP: string): longint;
var Addr: TIPRec;
    I,P: integer;
begin
  for I:=1 to 4 do
    begin
      P:=Pos('.',IP); if P=0 then P:=length(IP)+1;
      Addr.Octets[I]:=StrToInt(copy(IP,1,P-1));
      Delete(IP,1,P);
    end;
  IPStr:=longint(Addr);
end;

function CallABI(Func: byte; var r: registers): boolean;
var OK: boolean;
begin
  if ABIDriverInt=0 then
    ABIInit;
  OK:=(ABIDriverInt<>0);
  if OK then
    begin
      if ABIForceIO and (ABIInDoIO=false) then ABIDoIO;
      ABIInCall:=true;
      r.ah:=Func;
      realintr(ABIDriverInt,r);
      if ABIInDoIO=false then
        begin
          ABIError:=r.dl;
          OK:=(ABIError=abi_err_OK);
        end;
      ABIInCall:=false;
      if ABIForceIO and (ABIInDoIO=false) then ABIDoIO;
    end;
  CallABI:=OK;
end;

procedure ABIInt1C; interrupt;
begin
  if ABIInCall=false then
    ABIDoIO;
  if @OldInt1C<>nil then
    begin
      asm pushf; end;
      OldInt1C;
    end;
end;

function ABIInit: boolean;
function CheckInt(IntNo: byte): boolean;
var P: pointer;
    Sign: array[1..20] of char;
begin
{  MoveDosToPM(Ptr(0,IntNo*4),@P,4);}
  realGetIntVec(IntNo,P);
  MoveDosToPM(P,@Sign,SizeOf(Sign));
  CheckInt:=(Pos('TCP_DRVR',Sign)>0);
end;
var I: byte;
    OK: boolean;
    r: registers;
    P: MemPtr;
begin

  if ABIInited then
    begin
      ABIInit:=true;
      Exit;
    end;

  FillChar(ABIDriverInfo,SizeOf(ABIDriverInfo),0);
  if ABIDriverInt=0 then
    begin
      for I:=$60 to $7f do
        if CheckInt(I) then
          begin
            ABIDriverInt:=I;
            Break;
          end;
    end
  else
    if CheckInt(ABIDriverInt)=false then
      ABIDriverInt:=0;
  OK:=ABIDriverInt<>0;
  if OK then
    begin
      r.al:=$ff;
      OK:=CallABI(abi_cmd_InstallCheck,r) and (r.al<>$ff);
      if OK then
        begin
          ABITimeOutSupported:=(r.dh and 1)<>0;
          ABIAsyncIOSupported:=(r.dh and 2)<>0;

          GetDosMem(P,SizeOf(ABIDriverInfo));
          r.cx:=P.Size;
          r.es:=P.DosSeg; r.di:=P.DosOfs;
          OK:=CallABI(abi_cmd_GetDriverInfo,r);
          P.MoveDataFrom(SizeOf(ABIDriverInfo),ABIDriverInfo);
          FreeDosMem(P);

          if CallABI(abi_cmd_GetCriticalFlag,r) then
            ABICriticalFlagAddr:=MakePtr(r.es,r.di);
        end;
    end;
  ABIInited:=OK;
  ABIInit:=OK;
end;

function ABIUnLoad: boolean;
var r: registers;
begin
  ABIUnLoad:=CallABI(abi_cmd_UnLoadDriver,r);
end;

function ABIDoIO: boolean;
var r: registers;
    OK: boolean;
begin
  ABIInDoIO:=true;
  OK:=CallABI(abi_cmd_PerformIO,r);
  if OK then
    begin
      ABIFreeInputPackets:=r.ax;
      ABIFreeOutputPackets:=r.cx;
    end;
  ABIInDoIO:=false;
  ABIDoIO:=OK;
end;

function ABIGetCriticalFlag: byte;
var B: byte;
begin
  if ABICriticalFlagAddr=nil then
    B:=0
  else
    MoveDosToPM(ABICriticalFlagAddr,@B,1);
  ABIGetCriticalFlag:=B;
end;

function TCPOpen(Flags: byte; LocalPort: word;
                 DestIP: longint; DestPort: word; TimeOut: word; var Handle: TABISocket): word;
var r: registers;
    PortNo: word;
    OK: boolean;
begin
  r.al:=Flags; r.bx:=LocalPort;
  r.si:=TLong(DestIP).HiW; r.di:=TLong(DestIP).LoW; r.cx:=DestPort;
  r.dx:=TimeOut;
  OK:=CallABI(abi_cmd_OpenTCPSession,r);
  if OK=false then PortNo:=$ffff else
    begin
      PortNo:=r.ax; Handle:=r.bx;
    end;
  TCPOpen:=PortNo;
end;

function TCPGet(Handle: TABISocket; Flags: byte; var Buffer; var BufSize: word; TimeOut: word): boolean;
var r: registers;
    OK: boolean;
    P: MemPtr;
begin
  GetDosMem(P,BufSize);
  r.al:=Flags; r.bx:=Handle;
  r.es:=P.DosSeg; r.di:=P.DosOfs;
  r.cx:=BufSize; r.dx:=TimeOut;
  OK:=CallABI(abi_cmd_GetTCPData,r);
  if OK then
    begin
      BufSize:=r.ax;
      { !!! } if r.dh<>0 then BufSize:=0; { !!! }
      if (BufSize>0) then
      P.MoveDataFrom(BufSize,Buffer);
      { !!! r.dh info not stored !!! }
    end
  else
    BufSize:=0;
  FreeDosMem(P);
  TCPGet:=OK;
end;

function TCPPut(Handle: TABISocket; Flags: byte; var Buffer; var BufSize: word; TimeOut: word): boolean;
var r: registers;
    OK: boolean;
    P: MemPtr;
begin
  GetDosMem(P,BufSize);
  if BufSize>0 then
  P.MoveDataTo(Buffer,BufSize);
  r.al:=Flags; r.bx:=Handle;
  r.es:=P.DosSeg; r.di:=P.DosOfs;
  r.cx:=BufSize; r.dx:=TimeOut;
  OK:=CallABI(abi_cmd_PutTCPData,r);
  if OK then
    BufSize:=r.ax
  else
    BufSize:=0;
  FreeDosMem(P);
  TCPPut:=OK;
end;

function TCPGetStatus(Handle: TABISocket; Flags: byte; var Status: TTCPStatusRec): boolean;
var OK: boolean;
    r: registers;
begin
  FillChar(Status,SizeOf(Status),0);
  r.al:=Flags; r.bx:=Handle;
  OK:=CallABI(abi_cmd_GetTCPStatus,r);
  if OK then
    with Status do
    begin
      Status.TCPState:=r.dh;
      Status.BytesToRead:=r.ax;
      Status.BytesPending:=r.cx;
      MoveDosToPM(MakePtr(r.es,r.di),@Status.SessionInfo,SizeOf(Status.SessionInfo));
    end;
  TCPGetStatus:=OK;
end;

function TCPClose(Handle: TABISocket; Flags: byte; TimeOut: word): boolean;
var r: registers;
    OK: boolean;
begin
  r.al:=Flags; r.bx:=Handle; r.dx:=TimeOut;
  OK:=CallABI(abi_cmd_CloseTCPSession,r);
  TCPClose:=OK;
end;

function ABIAttachEventGlobal(EventHandler: pointer): boolean;
var r: registers;
    OK: boolean;
begin
  r.al:=0; r.es:=PtrRec(EventHandler).Seg; r.di:=PtrRec(EventHandler).Ofs;
  OK:=CallABI(abi_cmd_AttachEventGlobal,r);
  ABIAttachEventGlobal:=OK;
end;

function ABIDetachEventGlobal(EventHandler: pointer): boolean;
var r: registers;
    OK: boolean;
begin
  r.al:=0; r.es:=PtrRec(EventHandler).Seg; r.di:=PtrRec(EventHandler).Ofs;
  OK:=CallABI(abi_cmd_DetachEventGlobal,r);
  ABIDetachEventGlobal:=OK;
end;

{$ifndef FPC}
procedure ABIInstallTimer;
begin
  if ABIOnTimer then Exit;

  GetIntVec($1c,@OldInt1C);
  SetIntVec($1c,@ABIInt1C);
  ABIOnTimer:=true;
end;

procedure ABIDeInstallTimer;
begin
  if ABIOnTimer=false then Exit;

  SetIntVec($1c,@OldInt1C);
  ABIOnTimer:=false;
end;
{$endif}

const OldExitProc : pointer = nil;

procedure MyExitProc; {$ifndef FPC}far;{$endif}
begin
  ExitProc:=OldExitProc;
{$ifndef FPC}
  if ABIOnTimer then ABIDeInstallTimer;
{$endif}
end;

BEGIN
  OldExitProc:=ExitProc;
  ExitProc:=@MyExitProc;
END.
{
  $Log: abisocks.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
