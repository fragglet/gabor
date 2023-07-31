{
    $Id: ws2dos.pas,v 1.0 2000/01/28 10:04:10 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor

    WinSock2 VxD interface unit

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
unit WS2DOS;

interface

type
     dword        = longint;
     TWS2Socket = longint;

     plongint = ^longint;

const
      vxd_id_VXDLoader     = $0027;
      vxd_id_WinSock2      = $3b0a;

      WSOCK2VXD            = 'wsock2.vxd';

      ws2_max_fd         = 64;

      ws2_cmd_First         = $0100;
      ws2_cmd_Accept        = ws2_cmd_First + $00;
      ws2_cmd_Bind          = ws2_cmd_First + $01;
      ws2_cmd_Close         = ws2_cmd_First + $02;
      ws2_cmd_Connect       = ws2_cmd_First + $03;
      ws2_cmd_GetPeerName   = ws2_cmd_First + $04;
      ws2_cmd_GetSockName   = ws2_cmd_First + $05;
      ws2_cmd_GetSockOpt    = ws2_cmd_First + $06;
      ws2_cmd_IOCTL         = ws2_cmd_First + $07;
      ws2_cmd_Listen        = ws2_cmd_First + $08;
      ws2_cmd_Receive       = ws2_cmd_First + $09;
      ws2_cmd_SelectSetup   = ws2_cmd_First + $0a;
      ws2_cmd_SelectCleanup = ws2_cmd_First + $0b;
      ws2_cmd_AsyncSelect   = ws2_cmd_First + $0c;
      ws2_cmd_Send          = ws2_cmd_First + $0d;
      ws2_cmd_SetSockOpt    = ws2_cmd_First + $0e;
      ws2_cmd_Shutdown      = ws2_cmd_First + $0f;
      ws2_cmd_Socket        = ws2_cmd_First + $10;
      ws2_cmd_cancelevent  = ws2_cmd_First + $11;
      ws2_cmd_InstallEventHandler= ws2_cmd_First + $13;
      ws2_cmd_GetThreadHandle = ws2_cmd_First + $16;
      ws2_cmd_CallThreadProc = ws2_cmd_First + $17;
      ws2_cmd_GetSockProtocol = ws2_cmd_First + $1a;
      ws2_cmd_GetSockInfo     = ws2_cmd_First + $1b;

      ws2_FD_FAILED_CONNECT = $0100;

      ws2_FD_READ_BIT     = 0;
      ws2_FD_WRITE_BIT    = 1;
      ws2_FD_OOB_BIT      = 2;
      ws2_FD_ACCEPT_BIT   = 3;
      ws2_FD_CONNECT_BIT  = 4;
      ws2_FD_CLOSE_BIT    = 5;
      ws2_FD_QOS_BIT      = 6;
      ws2_FD_GROUP_QOS_BIT= 7;
      ws2_FD_MAX_EVENTS   = 8;

      ws2_FD_READ         = (1 shl ws2_FD_READ_BIT);
      ws2_FD_WRITE        = (1 shl ws2_FD_WRITE_BIT);
      ws2_FD_OOB          = (1 shl ws2_FD_OOB_BIT);
      ws2_FD_ACCEPT       = (1 shl ws2_FD_ACCEPT_BIT);
      ws2_FD_CONNECT      = (1 shl ws2_FD_CONNECT_BIT);
      ws2_FD_CLOSE        = (1 shl ws2_FD_CLOSE_BIT);
      ws2_FD_QOS          = (1 shl ws2_FD_QOS_BIT);
      ws2_FD_GROUP_QOS    = (1 shl ws2_FD_GROUP_QOS_BIT);
      ws2_FD_ALL_EVENTS   = ((1 shl ws2_FD_MAX_EVENTS) - 1);
      ws2_FD_ALL          = ws2_FD_ALL_EVENTS;
type
     PWSABuffer = ^TWSABuffer;
     TWSABuffer = packed record
       Length  : dword;
       Buffer  : pointer;
     end;

     TWSABuffers = array[1..8191] of TWSABuffer;
     PWSABuffers = ^TWSABuffers;

     PWSAOverlapped = ^TWSAOverlapped;
     TWSAOverlapped = packed record
       Internal      : dword;
       InternalHigh  : dword;
       Offset        : dword;
       OffsetHigh    : dword;
       hEvent        : dword;
     end;

     TWS2_Sock_ListItem = packed record
       Socket           : TWS2Socket;
       EventMask        : dword; { see FD_xxxx constants }
       Context          : dword;
     end;

     PWS2_Sock_List = ^TWS2_Sock_List;
     TWS2_Sock_List = array[1..ws2_max_fd] of TWS2_Sock_ListItem;

     TWS2_Accept_Params = packed record
       Address          : pointer;
       ListeningSocket  : TWS2Socket;
       ConnectedSocket  : TWS2Socket;
       AddressLength    : dword;
       ConnectedSocketHandle: dword;
       ApcRoutine       : pointer;
       ApcContext       : word;
       AcceptFamily     : dword;
       GetExtInfo       : dword;
       Unknown          : dword;
       LocalNamePtr     : pointer;
       LocalNameLen     : dword;
       PeerNamePtr      : pointer;
       PeerNameLen      : dword;
       Unknown2         : dword;
     end;

     TWS2_Bind_Params = packed record
       Address          : pointer;
       Socket           : TWS2Socket;
       AddressLength    : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
       ConnFamily       : dword;
     end;

     TWS2_Connect_Params = packed record
       Address          : pointer;
       Socket           : TWS2Socket;
       AddressLength    : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
       ConnEvent        : dword;
     end;

     TWS2_Close_Params = packed record
       Socket      : TWS2Socket;
     end;

     TWS2_GetPeerName_Params = packed record
       Address          : pointer;
       Socket           : TWS2Socket;
       AddressLength    : dword;
     end;

     TWS2_GetSockName_Params = TWS2_GetPeerName_Params;

     TWS2_GetSocketOpt_Params = packed record
       Value            : pointer;
       Socket           : TWS2Socket;
       OptionLevel      : dword;
       OptionName       : dword;
       ValueLength      : dword;
       IntValue         : dword;
     end;

     TWS2_SetSocketOpt_Params = TWS2_GetSocketOpt_Params;

     TWS2_IOCTL_Params = packed record
       Socket           : TWS2Socket;
       Command          : dword;
       Param            : pointer;
       Unknown          : array[1..8] of dword;
       Buffer           : pointer;
     end;

     TWS2_Listen_Params = packed record
       Socket           : TWS2Socket;
       BackLogSize      : dword;
     end;

     TWS2_Receive_Params = packed record
       Buffers          : PWSABuffers;
       Address          : pointer;
       AddrLenPtr       : pointer;
       Socket           : TWS2Socket;
       BufferCount      : dword;
       AddressLength    : dword;
       Flags            : dword;
       BytesReceived    : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
       Unknown3         : array[1..2] of dword;
       Overlapped       : PWSAOverlapped;
     end;

     TWS2_Send_Params = packed record
       Buffers          : PWSABuffers;
       Address          : pointer;
       Socket           : TWS2Socket;
       BufferCount      : dword;
       AddrLenPtr       : pointer;
       Flags            : dword;
       AddressLength    : dword;
       BytesSent        : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
       Unknown4         : array[1..3] of dword;
     end;

     TWS2_Shutdown_Params = packed record
       Socket           : TWS2Socket;
       How              : dword;
     end;

     TWS2_Socket_Params = packed record
       Family           : dword;
       SocketType       : dword;
       Protocol         : dword;
       NewSocket        : TWS2Socket;
       Handle           : dword;
       ProtocolCatalogID: dword;
       GroupID          : dword;
       Flags            : dword;
     end;

     TWS2_InstallEventHandler_Params = packed record
       PostMessageCallBack  : pointer;
       Pad                  : array[0..15] of byte;
     end;

     TWS2_GetThreadHandle_Params = packed record
       ThreadHandle         : dword;
     end;

     TWS2_GetSockProtocol_Params = packed record
       Socket               : TWS2Socket;
       ProtocolCatalogID    : dword;
       Unknown              : dword;
     end;

     TWS2_GetSockInfo_Params = packed record
       Socket               : TWs2Socket;
       Buffer               : pointer;
       Length               : dword;
     end;

     TWS2_AsyncSelect_Params = packed record
       Socket           : TWS2Socket;
       Window           : dword;
       Message          : dword;
       Events           : dword;
     end;

     TWS2_SelectSetup_Params = packed record
       ReadList         : pointer; { -> array of TWS2_Sock_ListItem }
       WriteList        : pointer;
       ExceptList       : pointer;
       ReadCount        : dword;
       WriteCount       : dword;
       ExceptCount      : dword;
       ApcRoutine       : pointer;
       ApcContext       : word;
     end;

     TWS2_SelectCleanup_Params = packed record
       ReadList         : pointer; { -> array of TWS2_Sock_ListItem }
       WriteList        : pointer;
       ExceptList       : pointer;
       ReadCount        : dword;
       WriteCount       : dword;
       ExceptCount      : dword;
     end;

     TWS2_cancelevent_Params = packed record
       Socket           : TWS2Socket;
       Event            : dword;
     end;

function  WS2Init: boolean;
procedure WS2Done;

function  ws2_accept(ListeningSocket: TWS2Socket; Address: pointer; var AddrSize: longint;
          var ConnectedSocket: TWS2Socket): boolean;
function  ws2_bind(Socket: TWS2Socket; Address: pointer; AddrSize: longint): boolean;
function  ws2_close(Socket: TWS2Socket): boolean;
function  ws2_connect(Socket: TWS2Socket; Address: pointer; AddrSize: longint; ConnectEvent: plongint): boolean;
function  ws2_getpeername(Socket: TWS2Socket; Address: pointer; var AddrSize: longint): boolean;
function  ws2_getsockname(Socket: TWS2Socket; Address: pointer; var AddrSize: longint): boolean;
function  ws2_listen(Socket: TWS2Socket; BackLogSize: longint): boolean;
function  ws2_recv(Socket: TWS2Socket; Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
function  ws2_recvfrom(Socket: TWS2Socket; Address: pointer; var AddrSize: longint;
           Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
function ws2_send(Socket: TWS2Socket; Buffer: pointer; var BufSize: longint; Flags: longint): boolean;
function ws2_sendto(Socket: TWS2Socket; Address: pointer; AddrSize: longint;
           Buffer: pointer; var BufSize: longint; Flags: longint): boolean;
function  ws2_socket(Family, SocketType, Protocol, ProtocolCatalogID, GroupID, Flags : longint;
          var Socket: TWS2Socket): boolean;
function  ws2_shutdown(Socket: TWS2Socket; How: longint): boolean;
function  ws2_installeventhandler(PostMessageCallBack: pointer): boolean;
function  ws2_asyncselect(Socket: TWS2Socket; Window, Message, Events: longint): boolean;
function  ws2_cancelevent(Socket: TWS2Socket; Event: dword): boolean;
function  ws2_selectsocket(Socket: TWS2Socket; FD: dword): integer;
function  ws2_select(nfds: longint; readfds, writefds, exceptfds: PWS2_Sock_List): integer;
function ws2_getsockprotocol(Socket: TWS2Socket; var ProtocolCatalogID: longint): boolean;

const WS2Error      : longint = 0;
      WS2Version    : word    = 0;

implementation

uses dos,pmode;

const WS2Inited     : boolean = false;
      WS2EntryPoint : pointer = nil;

function callws2(Func: word; var Data; DataSize: word): boolean;
var r: registers;
    M: MemPtr;
begin
  if WS2EntryPoint=nil then
    WS2Init;

  if WS2EntryPoint=nil then
    WS2Error:=-1
  else
    begin
      if DataSize>0 then GetDosMem(M,DataSize);
      M.MoveDataTo(Data,DataSize);
      r.ax:=Func;
      r.es:=M.DosSeg; r.bx:=M.DosOfs;
      realcall(WS2EntryPoint,r);
      M.MoveDataFrom(DataSize,Data);
      WS2Error:=r.ax;
      if DataSize>0 then FreeDosMem(M);
    end;
  callws2:=(WS2Error=0) or (WS2Error=$ffff);
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

function WS2Init: boolean;
var OK: boolean;
begin
  OK:=WS2Inited;
  if OK=false then
    OK:=LoadVXD(WSOCK2VXD);
  if OK=false then WS2EntryPoint:=nil else
    WS2EntryPoint:=GetVXDEntryPoint(vxd_id_WinSock2);
  OK:=OK and (WS2EntryPoint<>nil);
  if OK then WS2Version:=$0200;
  WS2Inited:=OK;
  WS2Init:=WS2Inited;
end;

procedure WS2Done;
begin
  if WS2Inited then
    UnloadVXD(WSOCK2VXD);
  WS2Inited:=false; WS2EntryPoint:=nil;
end;

function GetDosTicks: longint;
var TT: longint absolute $40:$6c;
begin
  GetDosTicks:=TT;
end;

function ws2_socket(Family, SocketType, Protocol, ProtocolCatalogID, GroupID, Flags : longint;
         var Socket: TWS2Socket): boolean;
var Params: TWS2_Socket_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Family:=Family;
  Params.SocketType:=SocketType;
  Params.Protocol:=Protocol;
  Params.ProtocolCatalogID:=ProtocolCatalogID;
  Params.GroupID:=GroupID;
  Params.Flags:=Flags;
  Params.Handle:=GetDosTicks; { <- just a unique value }
  OK:=CallWS2(ws2_cmd_Socket,Params,SizeOf(Params));
  if OK=false then Socket:=0 else
    Socket:=Params.NewSocket;
  ws2_socket:=OK;
end;

function  ws2_accept(ListeningSocket: TWS2Socket; Address: pointer; var AddrSize: longint;
          var ConnectedSocket: TWS2Socket): boolean;
var Params: TWS2_Accept_Params;
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
  OK:=CallWS2(ws2_cmd_Accept,Params,SizeOf(Params));
  if OK=false then ConnectedSocket:=-1 else
  ConnectedSocket:=Params.ConnectedSocket;
  AddrSize:=Params.AddressLength;
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(AddrM);
  ws2_accept:=OK;
end;

function ws2_bind(Socket: TWS2Socket; Address: pointer; AddrSize: longint): boolean;
var Params: TWS2_Bind_Params;
    OK: boolean;
    AddrM: MemPtr;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize);
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.Socket:=Socket;
  OK:=CallWS2(ws2_cmd_Bind,Params,SizeOf(Params));
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(AddrM);
  ws2_bind:=OK;
end;

function ws2_connect(Socket: TWS2Socket; Address: pointer; AddrSize: longint; ConnectEvent: plongint): boolean;
var Params: TWS2_Connect_Params;
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
  OK:=CallWS2(ws2_cmd_Connect,Params,SizeOf(Params));
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  if Assigned(ConnectEvent) then
    if OK then
      ConnectEvent^:=Params.ConnEvent
    else
      ConnectEvent^:=0;
  FreeDosMem(AddrM);
  ws2_connect:=OK;
end;

function ws2_close(Socket: TWS2Socket): boolean;
var Params: TWS2_Close_Params;
    OK: boolean;
begin
  Params.Socket:=Socket;
  OK:=CallWS2(ws2_cmd_Close,Params,SizeOf(Params));
  ws2_close:=OK;
end;

function ws2_getpeername(Socket: TWS2Socket; Address: pointer; var AddrSize: longint): boolean;
var Params: TWS2_GetPeerName_Params;
    OK: boolean;
    AddrM: MemPtr;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize);
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.Socket:=Socket;
  OK:=CallWS2(ws2_cmd_GetPeerName,Params,SizeOf(Params));
  AddrSize:=Params.AddressLength;
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(AddrM);
  ws2_getpeername:=OK;
end;

function ws2_getsockname(Socket: TWS2Socket; Address: pointer; var AddrSize: longint): boolean;
var Params: TWS2_GetSockName_Params;
    OK: boolean;
    AddrM: MemPtr;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize);
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.Socket:=Socket;
  OK:=CallWS2(ws2_cmd_GetSockName,Params,SizeOf(Params));
  AddrSize:=Params.AddressLength;
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(AddrM);
  ws2_getsockname:=OK;
end;

function  ws2_listen(Socket: TWS2Socket; BackLogSize: longint): boolean;
var Params: TWS2_Listen_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Socket:=Socket;
  Params.BackLogSize:=BackLogSize;
  OK:=CallWS2(ws2_cmd_Listen,Params,SizeOf(Params));
  ws2_listen:=OK;
end;

procedure FillLong(var Buf; Count: integer; Value: longint);
type TLongArray = array[0..16382] of longint;
     PLongArray = ^TLongArray;
var I: integer;
begin
  for I:=1 to Count do
    PLongArray(@Buf)^[I-1]:=Value;
end;

function ws2_MapFlatPtr(P: pointer): pointer;
var Params: TWS2_GetPeerName_Params;
begin
  { we use this trick to let the VxD itself  }
  { map real-mode addresses to flat addrs    }
  FillChar(Params,sizeof(Params),0);
  Params.Address:=P;
  CallWS2(ws2_cmd_GetPeerName,Params,SizeOf(Params));
  { this will return an error (as Params.Socket = 0), but we simply do not
    care about this. however, we do care about the mapped buffer address... }
  ws2_MapFlatPtr:=Params.Address;
end;

function ws2_recvfrom(Socket: TWS2Socket; Address: pointer; var AddrSize: longint;
           Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
var Params: TWS2_Receive_Params;
    OK: boolean;
    AddrM,DataM: MemPtr;
    BuffersM: MemPtr;
    WSAB: TWSABuffer;
begin
  FillChar(Params,SizeOf(Params),0);
  GetDosMem(AddrM,AddrSize+4);
  GetDosMem(DataM,BufSize);
  GetDosMem(BuffersM,sizeof(WSAB));
  if Address<>nil then AddrM.MoveDataTo(Address^,AddrSize);
  FillChar(WSAB,sizeof(WSAB),0);
  WSAB.Length:=DataM.Size;
  WSAB.Buffer:=ws2_MapFlatPtr(DataM.DosPtr);
  { ^^^ buffers aren't mapped by the VxD, so, we've to map them ourselves }
  BuffersM.MoveDataTo(WSAB,sizeof(WSAB));
  Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  Params.AddrLenPtr:=MakePtr(AddrM.DosSeg,AddrM.DosOfs+AddrSize);
  Params.Buffers:=BuffersM.DosPtr;
  Params.BufferCount:=1;
  Params.Flags:=Flags;
  Params.Socket:=Socket;
  OK:=CallWS2(ws2_cmd_Receive,Params,SizeOf(Params));
  AddrSize:=Params.AddressLength;
  BufSize:=Params.BytesReceived;
  if Address<>nil then AddrM.MoveDataFrom(AddrSize,Address^);
  if Buffer<>nil then DataM.MoveDataFrom(BufSize,Buffer^);
  FreeDosMem(BuffersM);
  FreeDosMem(AddrM);
  FreeDosMem(DataM);
  ws2_recvfrom:=OK;
end;

function ws2_recv(Socket: TWS2Socket; Buffer: pointer; var BufSize: longint; Flags: longint; TimeOut: longint): boolean;
var Addr: array[0..15] of byte;
    AS: longint;
begin
  AS:=SizeOf(Addr);
  FillChar(Addr,SizeOf(Addr),0);
  ws2_recv:=ws2_recvfrom(Socket,@Addr,AS,Buffer,BufSize,Flags,TimeOut);
end;

function ws2_sendto(Socket: TWS2Socket; Address: pointer; AddrSize: longint;
           Buffer: pointer; var BufSize: longint; Flags: longint): boolean;
var Params: TWS2_Send_Params;
    OK: boolean;
    AddrM,DataM: MemPtr;
    BuffersM: MemPtr;
    WSAB: TWSABuffer;
begin
  FillChar(Params,SizeOf(Params),0);
  FillChar(AddrM,sizeof(AddrM),0);
  if Assigned(Address) then GetDosMem(AddrM,AddrSize+sizeof(AddrSize));
  GetDosMem(DataM,BufSize);
  if Buffer<>nil then DataM.MoveDataTo(Buffer^,BufSize);
  GetDosMem(BuffersM,sizeof(WSAB));
  if (Address<>nil) and (AddrSize>0) then
   begin
     AddrM.MoveDataTo(Address^,AddrSize);
     AddrM.MoveDataToOfs(AddrSize,AddrSize,sizeof(AddrSize));
   end;
  FillChar(WSAB,sizeof(WSAB),0);
  WSAB.Length:=DataM.Size;
  WSAB.Buffer:=ws2_MapFlatPtr(DataM.DosPtr);
  { ^^^ buffers aren't mapped by the VxD, so, we've to map them ourselves }
  BuffersM.MoveDataTo(WSAB,sizeof(WSAB));
  if Assigned(Address) then Params.Address:=AddrM.DosPtr;
  Params.AddressLength:=AddrSize;
  if Assigned(Address) then
    Params.AddrLenPtr:=MakePtr(AddrM.DosSeg,AddrM.DosOfs+AddrSize);
  Params.Buffers:=BuffersM.DosPtr;
  Params.BufferCount:=1;
  Params.Socket:=Socket;
  Params.BytesSent:=BufSize;
  Params.Flags:=Flags;
  OK:=CallWS2(ws2_cmd_Send,Params,SizeOf(Params));
  BufSize:=Params.BytesSent;
  if (Address<>nil) and (AddrSize>0) then AddrM.MoveDataFrom(AddrSize,Address^);
  FreeDosMem(BuffersM);
  if Assigned(Address) then FreeDosMem(AddrM);
  FreeDosMem(DataM);
  ws2_sendto:=OK;
end;

function ws2_send(Socket: TWS2Socket; Buffer: pointer; var BufSize: longint; Flags: longint): boolean;
begin
  ws2_send:=ws2_sendto(Socket,nil,0,Buffer,BufSize,Flags);
end;

function  ws2_cancelevent(Socket: TWS2Socket; Event: dword): boolean;
var Params: TWS2_cancelevent_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Socket:=Socket;
  Params.Event:=Event;
  OK:=CallWS2(ws2_cmd_cancelevent,Params,SizeOf(Params));
  ws2_cancelevent:=OK;
end;

function  ws2_shutdown(Socket: TWS2Socket; How: longint): boolean;
var Params: TWS2_Shutdown_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Socket:=Socket;
  Params.How:=How;
  OK:=CallWS2(ws2_cmd_Shutdown,Params,SizeOf(Params));
  ws2_shutdown:=OK;
end;

function  ws2_installeventhandler(PostMessageCallBack: pointer): boolean;
var Params: TWS2_InstallEventHandler_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.PostMessageCallBack:=PostMessageCallback;
  OK:=CallWS2(ws2_cmd_InstallEventHandler,Params,SizeOf(Params));
  ws2_installeventhandler:=OK;
end;

function  ws2_asyncselect(Socket: TWS2Socket; Window, Message, Events: longint): boolean;
var Params: TWS2_AsyncSelect_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Socket:=Socket;
  Params.Window:=Window;
  Params.Message:=Message;
  Params.Events:=Events;
  OK:=CallWS2(ws2_cmd_AsyncSelect,Params,SizeOf(Params));
  ws2_asyncselect:=OK;
end;

function  ws2_selectsocket(Socket: TWS2Socket; FD: dword): integer;
var Params: TWS2_SelectSetup_Params;
    OK: boolean;
    LM: MemPtr;
    LI: TWS2_Sock_ListItem;
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
  OK:=CallWS2(ws2_cmd_SelectCleanup,Params,SizeOf(Params));
  LM.MoveDataFrom(SizeOf(LI),LI);
  FreeDosMem(LM);
  if OK=false then Count:=0 else
    if LI.Socket=Socket then
      Count:=1
    else
      Count:=0;
  ws2_selectsocket:=Count;
end;

function ws2_select(nfds: longint; readfds, writefds, exceptfds: PWS2_Sock_List): integer;
procedure InitFDList(fds: PWS2_Sock_List; var AMemPtr: MemPtr; var RealPtr: pointer; var FDCount: longint; AFD: longint);
var I: integer;
begin
  if Assigned(fds) then
    begin
      GetDosMem(AMemPtr,sizeof(fds^));
      RealPtr:=AMemPtr.DosPtr;
      I:=Low(fds^); FDCount:=0;
      while fds^[I].Socket<>0 do
      begin
        fds^[I].EventMask:=AFD;
        Inc(FDCount); Inc(I);
      end;
      AMemPtr.MoveDataTo(fds^,AMemPtr.Size);
    end
  else
    begin
      FillChar(AMemPtr,sizeof(AMemPtr),0);
      RealPtr:=nil;
      FDCount:=0;
    end;
end;
procedure DoneFDList(fds: PWS2_Sock_List; var AMemPtr: MemPtr; var Count: integer);
var I: integer;
begin
  if Assigned(fds) then
  begin
    AMemPtr.MoveDataFrom(AMemPtr.Size,fds^);
    for I:=Low(fds^) to High(fds^) do
      if fds^[I].Socket<>0 then
        Inc(Count);
    FreeDosMem(AMemPtr);
  end;
end;
var Params: TWS2_SelectSetup_Params;
    OK: boolean;
    LM: MemPtr;
    FDRM,FDWM,FDEM: MemPtr;
    Count: integer;
begin
  FillChar(Params,SizeOf(Params),0);
{  if assigned(exceptfds) then
    fillchar(exceptfds^,sizeof(exceptfds^),0);}
  InitFDList(readfds,FDRM,Params.ReadList,Params.ReadCount,ws2_FD_CONNECT+ws2_FD_ACCEPT+ws2_FD_READ);
  InitFDList(writefds,FDWM,Params.WriteList,Params.WriteCount,ws2_FD_WRITE);
  InitFDList(exceptfds,FDEM,Params.ExceptList,Params.ExceptCount,ws2_FD_CLOSE);
  OK:=CallWS2(ws2_cmd_SelectCleanup,Params,SizeOf(Params));
  Count:=0;
  DoneFDList(readfds,FDRM,Count);
  DoneFDList(writefds,FDWM,Count);
  DoneFDList(exceptfds,FDEM,Count);
  if OK=false then Count:=-1;
  ws2_select:=Count;
end;

{function  ws2_select(nfds: longint; readfds, writefds, exceptfds: PWS2_Sock_List): integer;
var Params: TWS2_SelectSetup_Params;
    OK: boolean;
    RFDsM,WFDsM,EFDsM: MemPtr;
    Count,I: integer;
    SSize: integer;
begin
  SSize:=SizeOf(TWS2_Sock_ListItem)*nfds;
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
  OK:=CallWS2(ws2_cmd_SelectCleanup,Params,SizeOf(Params));
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
  ws2_select:=Count;
end;}

function ws2_getsockprotocol(Socket: TWS2Socket; var ProtocolCatalogID: longint): boolean;
var Params: TWS2_GetSockProtocol_Params;
    OK: boolean;
begin
  FillChar(Params,SizeOf(Params),0);
  Params.Socket:=Socket;
  OK:=CallWS2(ws2_cmd_GetSockProtocol,Params,SizeOf(Params));
  if OK then
    ProtocolCatalogID:=Params.ProtocolCatalogID
  else
    ProtocolCatalogID:=0;
  ws2_getsockprotocol:=OK;
end;

END.
{
  $Log: ws2dos.pas,v $

  Revision 1.0  2000/01/28 10:04:10  gabor
     Original implementation

}
