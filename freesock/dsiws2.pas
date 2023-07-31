{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    WSOCK2.VXD sockets interface

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
{ !!!! IMPORTANT NOTICE: READ WS2DOS.TXT BEFORE USING THIS INTERFACE !!!! }
unit DSIWS2;

interface

uses Objects, WS2Dos, Types, Sockets, DSIIntf;

type
     PWS2SocketsInterface = ^TWS2SocketsInterface;
     TWS2SocketsInterface = object(TSocketsInterface)
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
      { ------ }
       function WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint; virtual;
       function WSACleanup: longint; virtual;
     private
       function CheckError: longint;
     end;

procedure RegisterInterface;

implementation

uses Strings,SockCnst,SockUtil,pmode;

function TWS2SocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
var len: longint;
    news: TWS2Socket;
begin
  if assigned(addrlen) then len:=addrlen^ else len:=0;
  news:=INVALID_SOCKET;
  ws2_accept(s,addr,len,news);
  if assigned(addrlen) then addrlen^:=len;
  accept:=news;
  CheckError;
end;

function TWS2SocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
begin
  ws2_bind(s,@addr,namelen);
  bind:=CheckError;
end;

function TWS2SocketsInterface.closesocket(s: TSocket): longint;
begin
  ws2_close(s);
  closesocket:=CheckError;
end;

function TWS2SocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
begin
  ws2_asyncselect(s,1,1,FD_ALL);
  ws2_connect(s,@name,min(namelen,16),nil);
  if (WS2Error=$ffff) or (WS2Error=WSAEWOULDBLOCK) then
  while ws2_selectsocket(s,FD_CONNECT)=0 do;
  connect:=CheckError;
end;

function TWS2SocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
begin
  ioctlsocket:=ISetLastError(WSAEOPNOTSUPP);
end;

function TWS2SocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
begin
  ws2_getpeername(s,@name,namelen);
  getpeername:=CheckError;
end;

function TWS2SocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
begin
  ws2_getsockname(s,@name,namelen);
  getsockname:=CheckError;
end;

function TWS2SocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
begin
  getsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TWS2SocketsInterface.listen(s: TSocket; backlog: longint): longint;
begin
  ws2_listen(s,backlog);
  listen:=CheckError;
end;

function TWS2SocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
begin
  ws2_recv(s,@Buf,len,flags,-1);
  recv:=len;
end;

function TWS2SocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
         var fromlen: longint): longint;
begin
  ws2_recvfrom(s,@from,fromlen,@Buf,len,flags,-1);
  recvfrom:=len;
end;

procedure SockToWS2FDs(const FDs: TFDSet; var WFDs: TWS2_Sock_List; FDMask: longint);
var I: integer;
begin
  FillChar(WFDs,SizeOf(WFDs),0);
  for I:=0 to FDs.fd_count-1 do
    with WFDs[I+1] do
    begin
      Socket:=FDs.fd_array[I];
      EventMask:=FDMask;
    end;
end;

procedure WS2ToSockFDs(const WFDs: TWS2_Sock_List; var FDs: TFDSet);
var I: integer;
begin
  FD_ZERO(FDs);
  for I:=Low(WFDs) to High(WFDs) do
    if WFDs[I].Socket<>0 then
      FD_SET(WFDs[I].Socket,FDs);
end;

function TWS2SocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
var RFDS,WFDS,EFDS: TWS2_Sock_List;
    RP,WP,EP: PWS2_Sock_List;
    Count: longint;
begin
  RP:=nil; WP:=nil; EP:=nil;
  if Assigned(readfds) then
  begin
     SockToWS2FDs(readfds^,RFDs,FD_READ);
     RP:=@RFDs;
  end;
  if Assigned(writefds) then
  begin
     SockToWS2FDs(writefds^,WFDs,FD_WRITE);
     WP:=@WFDs;
  end;
  if Assigned(exceptfds) then
  begin
     SockToWS2FDs(exceptfds^,EFDs,ws2_FD_FAILED_CONNECT);
     EP:=@EFDs;
  end;
  Count:=ws2_select(nfds,RP,WP,EP);
  if Assigned(readfds) then WS2ToSockFDs(RFDs,readfds^);
  if Assigned(writefds) then WS2ToSockFDs(WFDs,writefds^);
  if Assigned(exceptfds) then WS2ToSockFDs(EFDs,exceptfds^);
  if CheckError<>0 then
    Count:=-1;
  select:=Count;
end;

function TWS2SocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
begin
  ws2_send(s,@Buf,len,flags);
  send:=len;
end;

function TWS2SocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr;
         tolen: longint): longint;
begin
  ws2_sendto(s,@addrto,tolen,@Buf,len,flags);
  sendto:=len;
end;

function TWS2SocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
begin
  setsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TWS2SocketsInterface.shutdown(s: TSocket; how: longint): longint;
begin
  ws2_shutdown(s,how);
  shutdown:=CheckError;
end;

function TWS2SocketsInterface.socket(af, struct, protocol: longint): TSocket;
var s: TWS2Socket;
begin
  if ws2_socket(af,struct,protocol,0,0,0,s)=false then
    s:=INVALID_SOCKET;
  CheckError;
  socket:=s;
end;

{ ------ }

function TWS2SocketsInterface.CheckError: longint;
begin
  CheckError:=ISetLastError(WS2Error);
end;

{var WS2EventRealRegs: registers32;}
const
    WS2EventHandlerRealAddr: pointer = nil;

procedure WS2EventHandler; {$ifndef FPC}far;{$endif} assembler;
asm
  nop
  iret
end;

function TWS2SocketsInterface.WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint;
var Err: longint;
begin
  if Swap(wVersionRequired)>WS2Version then
    Err:=WSAVERNOTSUPPORTED else
  begin
{    WS2EventHandlerRealAddr:=allocrmcallback(@WS2EventHandler,@WS2EventRealRegs);
    ws2_installeventhandler(WS2EventHandlerRealAddr);}
    FillChar(FSData,SizeOf(FSData),0);
    with FSData do
    begin
      wVersion:=Swap(Min(Swap(wVersionRequired),WS2Version));
      wHighVersion:=Swap(WS2Version);
      StrPCopy(szDescription,'WinSock '+VersionToStr(WS2Version)+' - VXD');
      StrPCopy(szSystemStatus,'Running');
      iMaxSockets:=1023;
      iMaxUdpDg:=576;
      lpVendorInfo:=nil;
    end;
    Err:=WSAOK;
  end;
  ISetLastError(Err);
  WSAStartup:=Err;
end;

function TWS2SocketsInterface.WSACleanup: longint;
var Err: longint;
begin
  Err:=WSAOK;
  ISetLastError(Err);
  WSACleanup:=Err;
  if assigned(WS2EventHandlerRealAddr) then
    freermcallback(WS2EventHandlerRealAddr);
end;

function CreateInterface(ID: integer): PSocketsInterface; {$ifdef TP}far;{$endif}
begin
  CreateInterface:=New(PWS2SocketsInterface, Init(ID));
end;

procedure RegisterInterface;
begin
  RegisterSocketsInterface(
    {$ifdef FPC}@{$endif}WS2Init,
    {$ifdef FPC}@{$endif}CreateInterface
  );
end;

END.
