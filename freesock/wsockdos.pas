{
    $Id: wsockdos.pas,v 1.0 1999/11/28 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    WinSock VxD interface unit

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
{$ifdef TP}{$C FIXED PRELOAD PERMANENT}{$endif}
unit WSockDOS;

{.$define USEWSOCK2}

interface

type
     dword        = longint;
     TWSockSocket = longint;

const
      vxd_id_VXDLoader     = $0027;
      vxd_id_WinSock1      = $003e;
      vxd_id_WinSock2      = $3b0a;

      WSOCK1VXD            = 'wsock.vxd';
      WSOCK2VXD            = 'wsock2.vxd';

{$ifndef USEWSOCK2}
      WSOCKVXD             = WSOCK1VXD;
      vxd_id_WinSock       = vxd_id_WinSock1;
{$else}
      WSOCKVXD             = WSOCK2VXD;
      vxd_id_WinSock       = vxd_id_WinSock2;
{$endif}

      wsock_max_fd         = 64;

      wsock_cmd_First         = $0100;
      wsock_cmd_Accept        = wsock_cmd_First + $00;
      wsock_cmd_Bind          = wsock_cmd_First + $01;
      wsock_cmd_Close         = wsock_cmd_First + $02;
      wsock_cmd_Connect       = wsock_cmd_First + $03;
      wsock_cmd_GetPeerName   = wsock_cmd_First + $04;
      wsock_cmd_GetSockName   = wsock_cmd_First + $05;
      wsock_cmd_GetSockOpt    = wsock_cmd_First + $06;
      wsock_cmd_IOCTL         = wsock_cmd_First + $07;
      wsock_cmd_Listen        = wsock_cmd_First + $08;
      wsock_cmd_Receive       = wsock_cmd_First + $09;
      wsock_cmd_SelectSetup   = wsock_cmd_First + $0a;
      wsock_cmd_SelectCleanup = wsock_cmd_First + $0b;
      wsock_cmd_AsyncSelect   = wsock_cmd_First + $0c;
      wsock_cmd_Send          = wsock_cmd_First + $0d;
      wsock_cmd_SetSockOpt    = wsock_cmd_First + $0e;
      wsock_cmd_Shutdown      = wsock_cmd_First + $0f;
      wsock_cmd_Socket        = wsock_cmd_First + $10;
      wsock_cmd_Signal        = wsock_cmd_First + $16;
      wsock_cmd_SignalAll     = wsock_cmd_First + $17;
      wsock_cmd_InstallEventHandler= wsock_cmd_First + $19;

      wsock_FD_FAILED_CONNECT = $0100;

type
     TWSock_Accept_Params = packed record
       Address          : pointer;
       ListeningSocket  : TWSockSocket;
       ConnectedSocket  : TWSockSocket;
       AddressLength    : dword;
       ConnectedSocketHandle: dword;
       ApcRoutine       : pointer;
       ApcContext       : word;
     end;

     TWSock_Bind_Params = packed record
       Address          : pointer;
       Socket           : TWSockSocket;
       AddressLength    : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
     end;

     TWSock_Connect_Params = TWSock_Bind_Params;

     TWSock_Close_Params = packed record
       Socket      : TWSockSocket;
     end;

     TWSock_GetPeerName_Params = packed record
       Address          : pointer;
       Socket           : TWSockSocket;
       AddressLength    : dword;
     end;

     TWSock_GetSockName_Params = TWSock_GetPeerName_Params;

     TWSock_GetSocketOpt_Params = packed record
       Value            : pointer;
       Socket           : TWSockSocket;
       OptionLevel      : dword;
       OptionName       : dword;
       ValueLength      : dword;
       IntValue         : dword;
     end;

     TWSock_SetSocketOpt_Params = TWSock_GetSocketOpt_Params;

     TWSock_IOCTL_Params = packed record
       Socket           : TWSockSocket;
       Command          : dword;
       Param            : pointer;
     end;

     TWSock_Listen_Params = packed record
       Socket           : TWSockSocket;
       BackLogSize      : dword;
     end;

     TWSock_Receive_Params = packed record
       Buffer           : pointer;
       Address          : pointer;
       Socket           : TWSockSocket;
       BufferLength     : dword;
       Flags            : dword;
       AddressLength    : dword;
       BytesTransmitted : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
       TimeOut          : dword;
     end;

     TWSock_Send_Params = TWSock_Receive_Params;

     TWSock_Shutdown_Params = packed record
       Socket           : TWSockSocket;
       How              : dword;
     end;

     TWSock_Socket_Params = packed record
       Family      : dword;
       SocketType  : dword;
       Protocol    : dword;
       NewSocket   : TWSockSocket;
       Handle      : dword;
     end;

     TWSock_Signal_Params = packed record
       Socket           : TWSockSocket;
       Event            : dword;
       Status           : dword;
     end;

     TWSock_SignalAll_Params = packed record
       Socket           : TWSockSocket;
       Status           : dword;
     end;

     TWSock_InstallEventHandler_Params = packed record
       PostMessageCallBack  : pointer;
       Pad                  : array[0..15] of byte;
     end;

     TWSock_AsyncSelect_Params = packed record
       Socket           : TWSockSocket;
       Window           : dword;
       Message          : dword;
       Events           : dword;
     end;

     TWSock_Sock_ListItem = packed record
       Socket           : TWSockSocket;
       EventMask        : dword; { see FD_xxxx constants }
       Context          : dword;
     end;

     PWSock_Sock_List = ^TWSock_Sock_List;
     TWSock_Sock_List = array[1..wsock_max_fd] of TWSock_Sock_ListItem;

     TWSock_SelectSetup_Params = packed record
       ReadList         : pointer; { -> array of TWSock_Sock_ListItem }
       WriteList        : pointer;
       ExceptList       : pointer;
       ReadCount        : dword;
       WriteCount       : dword;
       ExceptCount      : dword;
       ApcRoutine       : pointer;
       ApcContext       : word;
     end;

     TWSock_SelectCleanup_Params = packed record
       ReadList         : pointer; { -> array of TWSock_Sock_ListItem }
       WriteList        : pointer;
       ExceptList       : pointer;
       ReadCount        : dword;
       WriteCount       : dword;
       ExceptCount      : dword;
     end;

     TWSock_WSIOStatus = packed record
       IoStatus         : dword;
       IoCompleted      : byte;
       IoCancelled      : byte;
       IoTimedOut       : byte;
       IoSpare1         : byte;
     end;

function  WSOCKInit: boolean;
procedure WSOCKDone;

function  wsock_accept(ListeningSocket: TWSockSocket; Address: pointer; var AddrSize: longint;
          var ConnectedSocket: TWSockSocket): boolean;
function  wsock_bind(Socket: TWSockSocket; Address: pointer; AddrSize: longint): boolean;
function  wsock_close(Socket: TWSockSocket): boolean;
function  wsock_connect(Socket: TWSockSocket; Address: pointer; AddrSize: longint): boolean;
function  wsock_getpeername(Socket: TWSockSocket; Address: pointer; var AddrSize: longint): boolean;
function  wsock_getsockname(Socket: TWSockSocket; Address: pointer; var AddrSize: longint): boolean;
function  wsock_listen(Socket: TWSockSocket; BackLogSize: longint): boolean;
function  wsock_recv(Socket: TWSockSocket; Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
function  wsock_recvfrom(Socket: TWSockSocket; Address: pointer; var AddrSize: longint;
           Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
function  wsock_sendto(Socket: TWSockSocket; Address: pointer; AddrSize: longint;
           Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
function  wsock_send(Socket: TWSockSocket; Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
function  wsock_socket(Family, SocketType, Protocol: longint; var Socket: TWSockSocket): boolean;
function  wsock_shutdown(Socket: TWSockSocket; How: longint): boolean;
function  wsock_signal(Socket: TWSockSocket; Event: longint; Status: longint): boolean;
function  wsock_Signalall(Socket: TWSockSocket; Status: longint): boolean;
function  wsock_installeventhandler(PostMessageCallBack: pointer): boolean;
function  wsock_asyncselect(Socket: TWSockSocket; Window, Message, Events: longint): boolean;
function  wsock_select(nfds: longint; readfds, writefds, exceptfds: PWSock_Sock_List): integer;
function  wsock_selectsocket(Socket: TWSockSocket; FD: dword): integer;

const WSockError      : longint = 0;
      WSockVersion    : word    = 0;

implementation

uses dos,pmode;

const WSockInited     : boolean = false;
      WSockEntryPoint : pointer = nil;

function callwsock(Func: word; var Data; DataSize: word): boolean;
var r: registers;
    M: MemPtr;
begin
  if WSockEntryPoint=nil then
    WSOCKInit;

  if WSockEntryPoint=nil then
    WSockError:=-1
  else
    begin
      if DataSize>0 then GetDosMem(M,DataSize);
      M.MoveDataTo(Data,DataSize);
      r.ax:=Func;
      r.es:=M.DosSeg; r.bx:=M.DosOfs;
      realcall(WSockEntryPoint,r);
      M.MoveDataFrom(DataSize,Data);
      WSockError:=r.ax;
      if DataSize>0 then FreeDosMem(M);
    end;
  callwsock:=(WSockError=0);
end;

function GetVXDEntryPoint(VXDID: word): pointer;
var r: registers;
begin
  r.ax:=$1684; r.bx:=VXDID;
  r.es:=0; r.di:=0;
  realintr($2f,r);
  GetVXDEntryPoint:=MakePtr(r.es,r.di);
end;

function LoadVXD(VXDName: string): boolean;
var r: registers;
    M: MemPtr;
    OK: boolean;
    VXDLoader: pointer;
begin
  VXDName:=VXDName+#0;
  VXDLoader:=GetVXDEntryPoint(vxd_id_VXDLoader);
  OK:=VXDLoader<>nil;
  if OK then
  begin
    GetDosMem(M,256);
    M.MoveDataTo(VXDName[1],length(VXDName)+1);
    r.ax:=1;
    r.ds:=M.DosSeg; r.dx:=M.DosOfs;
    realcall(VXDLoader,r);
    FreeDosMem(M);
    OK:=(r.flags and fCarry)=0;
  end;
  LoadVXD:=OK;
end;

function UnloadVXD(VXDName: string): boolean;
var r: registers;
    M: MemPtr;
    OK: boolean;
    VXDLoader: pointer;
begin
  VXDName:=VXDName+#0;
  VXDLoader:=GetVXDEntryPoint(vxd_id_VXDLoader);
  OK:=VXDLoader<>nil;
  if OK then
  begin
    GetDosMem(M,256);
    M.MoveDataTo(VXDName[1],length(VXDName)+1);
    r.ax:=2;
    r.ds:=M.DosSeg; r.dx:=M.DosOfs;
    realcall(VXDLoader,r);
    FreeDosMem(M);
    OK:=(r.flags and fCarry)=0;
  end;
  UnloadVXD:=OK;
end;

function WSOCKInit: boolean;
var OK: boolean;
begin
  OK:=WSockInited;
  if OK=false then
    OK:=LoadVXD(WSOCKVXD);
  if OK=false then WSockEntryPoint:=nil else
    WSockEntryPoint:=GetVXDEntryPoint(vxd_id_WinSock);
  OK:=OK and (WSockEntryPoint<>nil);
  if OK then WSockVersion:=$0200;
  WSockInited:=OK;
  WSOCKInit:=WSockInited;
end;

procedure WSOCKDone;
begin
  if WSOCKInited then
    UnloadVXD(WSOCKVXD);
  WSockInited:=false; WSockEntryPoint:=nil;
end;

function GetDosTicks: longint;
var TT: longint absolute $40:$6c;
begin
  GetDosTicks:=TT;
end;

function wsock_socket(Family, SocketType, Protocol: longint; var Socket: TWSockSocket): boolean;
var Params: TWSock_Socket_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Family:=Family;
  Params.SocketType:=SocketType;
  Params.Protocol:=Protocol;
  Params.Handle:=GetDosTicks; { <- just a unique value }
  OK:=CallWSock(wsock_cmd_Socket,Params,SizeOf(Params));
  if OK=false then Socket:=0 else
    Socket:=Params.NewSocket;
  wsock_socket:=OK;
end;

function  wsock_accept(ListeningSocket: TWSockSocket; Address: pointer; var AddrSize: longint;
          var ConnectedSocket: TWSockSocket): boolean;
var Params: TWSock_Accept_Params;
    OK: boolean;
    AddrM: MemPtr;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize);
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.ListeningSocket:=ListeningSocket;
  Params.ConnectedSocketHandle:=GetDosTicks; { <- just a unique value }
  OK:=CallWSock(wsock_cmd_Accept,Params,SizeOf(Params));
  if OK=false then ConnectedSocket:=-1 else
  ConnectedSocket:=Params.ConnectedSocket;
  AddrSize:=Params.AddressLength;
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(AddrM);
  wsock_accept:=OK;
end;

function wsock_bind(Socket: TWSockSocket; Address: pointer; AddrSize: longint): boolean;
var Params: TWSock_Bind_Params;
    OK: boolean;
    AddrM: MemPtr;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize);
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.Socket:=Socket;
  OK:=CallWSock(wsock_cmd_Bind,Params,SizeOf(Params));
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(AddrM);
  wsock_bind:=OK;
end;

function wsock_connect(Socket: TWSockSocket; Address: pointer; AddrSize: longint): boolean;
var Params: TWSock_Connect_Params;
    OK: boolean;
    AddrM: MemPtr;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize);
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.Socket:=Socket;
{  Params.ApcRoutine:=ptr($ffff,$ffff);
  Params.ApcContext:=0;}
  OK:=CallWSock(wsock_cmd_Connect,Params,SizeOf(Params));
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(AddrM);
  wsock_connect:=OK;
end;

function wsock_close(Socket: TWSockSocket): boolean;
var Params: TWSock_Close_Params;
    OK: boolean;
begin
  Params.Socket:=Socket;
  OK:=CallWSock(wsock_cmd_Close,Params,SizeOf(Params));
  wsock_close:=OK;
end;

function wsock_getpeername(Socket: TWSockSocket; Address: pointer; var AddrSize: longint): boolean;
var Params: TWSock_GetPeerName_Params;
    OK: boolean;
    AddrM: MemPtr;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize);
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.Socket:=Socket;
  OK:=CallWSock(wsock_cmd_GetPeerName,Params,SizeOf(Params));
  AddrSize:=Params.AddressLength;
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(AddrM);
  wsock_getpeername:=OK;
end;

function wsock_getsockname(Socket: TWSockSocket; Address: pointer; var AddrSize: longint): boolean;
var Params: TWSock_GetSockName_Params;
    OK: boolean;
    AddrM: MemPtr;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize);
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.Socket:=Socket;
  OK:=CallWSock(wsock_cmd_GetSockName,Params,SizeOf(Params));
  AddrSize:=Params.AddressLength;
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(AddrM);
  wsock_getsockname:=OK;
end;

function  wsock_listen(Socket: TWSockSocket; BackLogSize: longint): boolean;
var Params: TWSock_Listen_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Socket:=Socket;
  Params.BackLogSize:=BackLogSize;
  OK:=CallWSock(wsock_cmd_Listen,Params,SizeOf(Params));
  wsock_listen:=OK;
end;

procedure FillLong(var Buf; Count: integer; Value: longint);
type TLongArray = array[0..16382] of longint;
     PLongArray = ^TLongArray;
var I: integer;
begin
  for I:=1 to Count do
    PLongArray(@Buf)^[I-1]:=Value;
end;


function wsock_recvfrom(Socket: TWSockSocket; Address: pointer; var AddrSize: longint;
           Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
var Params: TWSock_Receive_Params;
    OK: boolean;
    AddrM,DataM: MemPtr;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize);
  GetDosMem(DataM,BufSize);
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.Buffer:=DataM.DosPtr;
  Params.BufferLength:=BufSize;
  Params.Socket:=Socket;
  Params.Flags:=Flags;
  Params.TimeOut:=TimeOut;
  OK:=CallWSock(wsock_cmd_Receive,Params,SizeOf(Params));
  AddrSize:=Params.AddressLength;
  BufSize:=Params.BytesTransmitted;
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  if Buffer<>nil then DataM.MoveDataFrom(BufSize,Buffer^);
  FreeDosMem(AddrM);
  FreeDosMem(DataM);
  wsock_recvfrom:=OK;
end;

function wsock_recv(Socket: TWSockSocket; Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
var Addr: array[0..15] of byte;
    AS: longint;
begin
  AS:=SizeOf(Addr);
  FillChar(Addr,SizeOf(Addr),0);
  wsock_recv:=wsock_recvfrom(Socket,@Addr,AS,Buffer,BufSize,Flags,TimeOut);
end;

function wsock_sendto(Socket: TWSockSocket; Address: pointer; AddrSize: longint;
           Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
var Params,O: TWSock_Send_Params;
    OK: boolean;
    AddrM,DataM: MemPtr;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize);
  GetDosMem(DataM,BufSize);
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.Buffer:=DataM.DosPtr;
  Params.BufferLength:=BufSize;
  Params.Socket:=Socket;
  Params.Flags:=Flags;
  Params.TimeOut:=TimeOut;
  if Buffer<>nil then DataM.MoveDataTo(Buffer^,BufSize);
  O:=Params;
  OK:=CallWSock(wsock_cmd_Send,Params,SizeOf(Params));
  BufSize:=Params.BytesTransmitted;
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(AddrM);
  FreeDosMem(DataM);
  wsock_sendto:=OK;
end;

function wsock_send(Socket: TWSockSocket; Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
var Addr: array[0..15] of byte;
begin
  wsock_send:=wsock_sendto(Socket,@Addr,0,Buffer,BufSize,Flags,TimeOut);
end;

function  wsock_shutdown(Socket: TWSockSocket; How: longint): boolean;
var Params: TWSock_Shutdown_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Socket:=Socket;
  Params.How:=How;
  OK:=CallWSock(wsock_cmd_Shutdown,Params,SizeOf(Params));
  wsock_shutdown:=OK;
end;

function  wsock_signal(Socket: TWSockSocket; Event: longint; Status: longint): boolean;
var Params: TWSock_Signal_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Socket:=Socket;
  Params.Event:=Event;
  Params.Status:=Status;
  OK:=CallWSock(wsock_cmd_signal,Params,SizeOf(Params));
  wsock_signal:=OK;
end;

function  wsock_signalall(Socket: TWSockSocket; Status: longint): boolean;
var Params: TWSock_SignalAll_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Socket:=Socket;
  Params.Status:=Status;
  OK:=CallWSock(wsock_cmd_signalall,Params,SizeOf(Params));
  wsock_signalall:=OK;
end;

function  wsock_installeventhandler(PostMessageCallBack: pointer): boolean;
var Params: TWSock_InstallEventHandler_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.PostMessageCallBack:=PostMessageCallback;
  OK:=CallWSock(wsock_cmd_InstallEventHandler,Params,SizeOf(Params));
  wsock_installeventhandler:=OK;
end;

function  wsock_asyncselect(Socket: TWSockSocket; Window, Message, Events: longint): boolean;
var Params: TWSock_AsyncSelect_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Socket:=Socket;
  Params.Window:=Window;
  Params.Message:=Message;
  Params.Events:=Events;
  OK:=CallWSock(wsock_cmd_AsyncSelect,Params,SizeOf(Params));
  wsock_asyncselect:=OK;
end;

function  wsock_selectsocket(Socket: TWSockSocket; FD: dword): integer;
var Params: TWSock_SelectSetup_Params;
    OK: boolean;
    LM: MemPtr;
    LI: TWSock_Sock_ListItem;
    Count: integer;
begin
  FillChar(LI,SizeOf(LI),0);
  LI.Socket:=Socket;
  LI.EventMask:=FD;
  GetDosMem(LM,SizeOf(LI));
  LM.MoveDataTo(LI,SizeOf(LI));
  FillChar(Params,SizeOf(Params),0);
  Params.ReadList:=LM.DosPtr;
  Params.WriteList:=nil;
  Params.ExceptList:=nil;
  Params.ReadCount:=1;
  Params.WriteCount:=0;
  Params.ExceptCount:=0;
  OK:=CallWSock(wsock_cmd_SelectCleanup,Params,SizeOf(Params));
  LM.MoveDataFrom(SizeOf(LI),LI);
  FreeDosMem(LM);
  if OK=false then Count:=0 else
    if LI.Socket=Socket then
      Count:=1
    else
      Count:=0;
  wsock_selectsocket:=Count;
end;

function  wsock_select(nfds: longint; readfds, writefds, exceptfds: PWSock_Sock_List): integer;
var Params: TWSock_SelectSetup_Params;
    OK: boolean;
    RFDsM,WFDsM,EFDsM: MemPtr;
    Count,I: integer;
    SSize: integer;
begin
  SSize:=SizeOf(TWSock_Sock_ListItem)*nfds;
  FillChar(Params,SizeOf(Params),0);
  if Assigned(readfds) then
  begin
    GetDosMem(RFDsM,SSize);
    RFDsM.MoveDataTo(readfds^,SSize);
    Params.ReadList:=RFDsM.DosPtr;
    Params.ReadCount:=nfds;
  end;
  if Assigned(writefds) then
  begin
    GetDosMem(WFDsM,SSize);
    WFDsM.MoveDataTo(writefds^,SSize);
    Params.WriteList:=WFDsM.DosPtr;
    Params.WriteCount:=nfds;
  end;
  if Assigned(exceptfds) then
  begin
    GetDosMem(EFDsM,SSize);
    EFDsM.MoveDataTo(exceptfds^,SSize);
    Params.ExceptList:=EFDsM.DosPtr;
    Params.ExceptCount:=nfds;
  end;
  OK:=CallWSock(wsock_cmd_SelectCleanup,Params,SizeOf(Params));
  if Assigned(readfds) then
  begin
    RFDsM.MoveDataFrom(SSize,readfds^);
    FreeDosMem(RFDsM);
  end;
  if Assigned(writefds) then
  begin
    WFDsM.MoveDataFrom(SSize,writefds^);
    FreeDosMem(WFDsM);
  end;
  if Assigned(exceptfds) then
  begin
    EFDsM.MoveDataFrom(SSize,exceptfds^);
    FreeDosMem(EFDsM);
  end;
  Count:=0;
  if OK then
    for I:=1 to nfds do
     begin
       if assigned(readfds) then
         if readfds^[i].socket<>0 then Inc(Count);
       if assigned(writefds) then
         if writefds^[i].socket<>0 then Inc(Count);
       if assigned(exceptfds) then
         if exceptfds^[i].socket<>0 then Inc(Count);
     end;
  wsock_select:=Count;
end;

END.
{
  $Log: wsockdos.pas,v $

  Revision 1.0  1999/11/28 09:46:55  gabor
     Original implementation

}
