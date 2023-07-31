{
    $Id: dsiintf.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Abstract DOS sockets interface

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
unit DSIIntf;

interface

uses Objects, Types, Sockets;

type
     TSocketState = (ssEmpty,ssCreated,ssBound,ssListening,ssConnected,ssDisconnected);
     TSocketType = (stTCP,stUDP,stRaw,stIPX,stSPX,stNBUnique,stNBGroup);

type
     PSocketsInterface = ^TSocketsInterface;
     TSocketsInterface = object(TObject)
       constructor Init(AInterfaceID: integer);
       function accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket; virtual;
       function bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint; virtual;
       function closesocket(s: TSocket): longint; virtual;
       function connect(s: TSocket; var name: TSockAddr; namelen: longint): longint; virtual;
       function ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint; virtual;
       function getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint; virtual;
       function getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint; virtual;
       function getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint; virtual;
       function listen(s: TSocket; backlog: longint): longint; virtual;
       function recv(s: TSocket; var Buf; len, flags: longint): longint; virtual;
       function recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
                var fromlen: longint): longint; virtual;
       function select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint; virtual;
       function send(s: TSocket; var Buf; len, flags: longint): longint; virtual;
       function sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr; tolen: longint): longint; virtual;
       function setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint; virtual;
       function shutdown(s: TSocket; how: longint): longint; virtual;
       function socket(af, struct, protocol: longint): TSocket; virtual;
       function gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt; virtual;
       function gethostbyname(name: PChar): PHostEnt; virtual;
       function gethostname(name: PChar; len: longint): longint; virtual;
       function getservbyport(port: Integer; proto: PChar): PServEnt; virtual;
       function getservbyname(name, proto: PChar): PServEnt; virtual;
       function getprotobynumber(proto: longint): PProtoEnt; virtual;
       function getprotobyname(name: PChar): PProtoEnt; virtual;
      { ------ }
       function GetHostNamePrefix: string; virtual;
      { ------ }
       function  WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint; virtual;
       function  WSACleanup: longint; virtual;
       function  WSAGetLastError: longint; virtual;
       procedure WSASetLastError(iError: longint); virtual;
     public
       InterfaceID: integer;
     public { protected }
       LastSockError: longint;
       function ISetLastError(iError: longint): longint;
     end;

     TDetectProc = function: boolean;
     TCreateProc = function(ID: integer): PSocketsInterface;

     PSocketsInterfaceInfo = ^TSocketsInterfaceInfo;
     TSocketsInterfaceInfo = record
       DetectProc     : TDetectProc;
       CreateProc     : TCreateProc;
     end;

function GetRegisteredInterfaceCount: integer;
function GetRegisteredInterfaceInfo(Index: integer; var I: TSocketsInterfaceInfo): boolean;
function RegisterSocketsInterface(ADetectProc: TDetectProc; ACreateProc: TCreateProc): boolean;

implementation

uses SockUtil;

type
     PSocketsInterfaceCollection = ^TSocketsInterfaceCollection;
     TSocketsInterfaceCollection = object(TCollection)
       function  At(Index: Integer): PSocketsInterfaceInfo;
       procedure FreeItem(Item: Pointer); virtual;
     end;

const SocketsInterfaces : PSocketsInterfaceCollection = nil;

function NewSocketsInterfaceInfo(ADetectProc: TDetectProc; ACreateProc: TCreateProc): PSocketsInterfaceInfo;
var P: PSocketsInterfaceInfo;
begin
  New(P); FillChar(P^,sizeof(P^),0);
  with P^ do
  begin
    DetectProc:=ADetectProc;
    CreateProc:=ACreateProc;
  end;
  NewSocketsInterfaceInfo:=P;
end;

procedure DisposeSocketsInterfaceInfo(P: PSocketsInterfaceInfo);
begin
  if Assigned(P) then Dispose(P);
end;

function TSocketsInterfaceCollection.At(Index: Integer): PSocketsInterfaceInfo;
begin
  At:=inherited At(Index);
end;

procedure TSocketsInterfaceCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then DisposeSocketsInterfaceInfo(Item);
end;

function GetRegisteredInterfaceCount: integer;
var Count: integer;
begin
  if Assigned(SocketsInterfaces)=false then Count:=0 else
    Count:=SocketsInterfaces^.Count;
  GetRegisteredInterfaceCount:=Count;
end;

function GetRegisteredInterfaceInfo(Index: integer; var I: TSocketsInterfaceInfo): boolean;
var OK: boolean;
begin
  FillChar(I,sizeof(I),0);
  OK:=(0<=Index) and (Index<GetRegisteredInterfaceCount);
  if OK then
    I:=SocketsInterfaces^.At(Index)^;
  GetRegisteredInterfaceInfo:=OK;
end;

function RegisterSocketsInterface(ADetectProc: TDetectProc; ACreateProc: TCreateProc): boolean;
var OK: boolean;
    P: PSocketsInterfaceInfo;
begin
  if Assigned(SocketsInterfaces)=false then
    New(SocketsInterfaces, Init(10,10));
  P:=NewSocketsInterfaceInfo(ADetectProc,ACreateProc);
  SocketsInterfaces^.Insert(P);
  OK:=true;
  RegisterSocketsInterface:=OK;
end;

constructor TSocketsInterface.Init(AInterfaceID: integer);
begin
  inherited Init;
  InterfaceID:=AInterfaceID;
end;

function TSocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
begin
  Abstract;
  accept:=-1; { eliminate warning }
end;

function TSocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
begin
  Abstract;
  bind:=-1; { eliminate warning }
end;

function TSocketsInterface.closesocket(s: TSocket): longint;
begin
  Abstract;
  closesocket:=-1; { eliminate warning }
end;

function TSocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
begin
  Abstract;
  connect:=-1; { eliminate warning }
end;

function TSocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
begin
  Abstract;
  ioctlsocket:=-1; { eliminate warning }
end;

function TSocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
begin
  Abstract;
  getpeername:=-1; { eliminate warning }
end;

function TSocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
begin
  Abstract;
  getsockname:=-1; { eliminate warning }
end;

function TSocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
begin
  Abstract;
  getsockopt:=-1; { eliminate warning }
end;

function TSocketsInterface.listen(s: TSocket; backlog: longint): longint;
begin
  Abstract;
  listen:=-1; { eliminate warning }
end;

function TSocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
begin
  Abstract;
  recv:=-1; { eliminate warning }
end;

function TSocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
         var fromlen: longint): longint;
begin
  Abstract;
  recvfrom:=-1; { eliminate warning }
end;

function TSocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
begin
  Abstract;
  select:=-1; { eliminate warning }
end;

function TSocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
begin
  Abstract;
  send:=-1; { eliminate warning }
end;

function TSocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr; tolen: longint): longint;
begin
  Abstract;
  sendto:=-1; { eliminate warning }
end;

function TSocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
begin
  Abstract;
  setsockopt:=-1; { eliminate warning }
end;

function TSocketsInterface.shutdown(s: TSocket; how: longint): longint;
begin
  Abstract;
  shutdown:=-1; { eliminate warning }
end;

function TSocketsInterface.socket(af, struct, protocol: longint): TSocket;
begin
  Abstract;
  socket:=-1; { eliminate warning }
end;

function TSocketsInterface.gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt;
var Err: longint;
begin
  Err:=WSANO_DATA;
  WSASetLastError(Err);
  gethostbyaddr:=nil;
end;

function TSocketsInterface.gethostbyname(name: PChar): PHostEnt;
var Err: longint;
begin
  Err:=WSANO_DATA;
  WSASetLastError(Err);
  gethostbyname:=nil;
end;

function TSocketsInterface.gethostname(name: PChar; len: longint): longint;
var Err: longint;
begin
  Err:=WSANO_DATA;
  WSASetLastError(Err);
  gethostname:=0;
end;

function TSocketsInterface.getservbyport(port: Integer; proto: PChar): PServEnt;
var Err: longint;
begin
  Err:=WSANO_DATA;
  WSASetLastError(Err);
  getservbyport:=nil;
end;

function TSocketsInterface.getservbyname(name, proto: PChar): PServEnt;
var Err: longint;
begin
  Err:=WSANO_DATA;
  WSASetLastError(Err);
  getservbyname:=nil;
end;

function TSocketsInterface.getprotobynumber(proto: longint): PProtoEnt;
var Err: longint;
begin
  if CheckRange(proto,0,PF_MAX)=false then
    Err:=WSANO_DATA
  else
    Err:=WSANO_RECOVERY;
  WSASetLastError(Err);
  getprotobynumber:=nil;
end;

function TSocketsInterface.getprotobyname(name: PChar): PProtoEnt;
var Err: longint;
begin
  Err:=WSANO_DATA;
  WSASetLastError(Err);
  getprotobyname:=nil;
end;

function TSocketsInterface.WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint;
begin
  Abstract;
  WSAStartup:=-1; { eliminate warning }
end;

function TSocketsInterface.WSACleanup: longint;
begin
  Abstract;
  WSACleanup:=-1; { eliminate warning }
end;

function TSocketsInterface.WSAGetLastError: longint;
begin
  WSAGetLastError:=LastSockError;
end;

procedure TSocketsInterface.WSASetLastError(iError: longint);
begin
  LastSockError:=iError;
end;

function TSocketsInterface.ISetLastError(iError: longint): longint;
begin
  WSASetLastError(iError);
  if iError=WSAOK then
    iError:=0
  else
    iError:=SOCKET_ERROR;
  ISetLastError:=iError;
end;

function TSocketsInterface.GetHostNamePrefix: string;
begin
  GetHostNamePrefix:='';
end;

END.
{
  $Log: dsiintf.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
