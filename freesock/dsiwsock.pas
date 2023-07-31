{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    WSOCK.VXD sockets interface

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
unit DSIWSock;

interface

uses Objects, Types, Sockets, DSIIntf, WSOCKDOS;

type
     PWSOCKSocketsInterface = ^TWSOCKSocketsInterface;
     TWSOCKSocketsInterface = object(TSocketsInterface)
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

uses Strings,SockCnst,SockUtil, pmode;

function TWSOCKSocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
var len: longint;
    news: TWSockSocket;
begin
  if assigned(addrlen) then len:=addrlen^ else len:=0;
  news:=INVALID_SOCKET;
  wsock_accept(s,addr,len,news);
  if assigned(addrlen) then addrlen^:=len;
  accept:=news;
  CheckError;
end;

function TWSOCKSocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
begin
  wsock_bind(s,@addr,namelen);
  bind:=CheckError;
end;

function TWSOCKSocketsInterface.closesocket(s: TSocket): longint;
begin
  wsock_close(s);
  closesocket:=CheckError;
end;

function TWSOCKSocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
begin
  wsock_asyncselect(s,1,1,FD_ALL);
  wsock_connect(s,@name,namelen);
  if (WSockError=$ffff) or (WSockError=WSAEWOULDBLOCK) then
  while wsock_selectsocket(s,FD_CONNECT)=0 do;
  connect:=CheckError;
end;

function TWSOCKSocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
begin
  ioctlsocket:=ISetLastError(WSAEOPNOTSUPP);
end;

function TWSOCKSocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
begin
  wsock_getpeername(s,@name,namelen);
  getpeername:=CheckError;
end;

function TWSOCKSocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
begin
  wsock_getsockname(s,@name,namelen);
  getsockname:=CheckError;
end;

function TWSOCKSocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
begin
  getsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TWSOCKSocketsInterface.listen(s: TSocket; backlog: longint): longint;
begin
  wsock_listen(s,backlog);
  listen:=CheckError;
end;

function TWSOCKSocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
begin
  wsock_recv(s,@Buf,len,flags,-1);
  recv:=len;
end;

function TWSOCKSocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
         var fromlen: longint): longint;
begin
  wsock_recvfrom(s,@from,fromlen,@Buf,len,flags,-1);
  recvfrom:=len;
end;

procedure SockToWSockFDs(const FDs: TFDSet; var WFDs: TWSock_Sock_List; FDMask: longint);
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

procedure WSockToSockFDs(const WFDs: TWSock_Sock_List; var FDs: TFDSet);
var I: integer;
begin
  FD_ZERO(FDs);
  for I:=Low(WFDs) to High(WFDs) do
    if WFDs[I].Socket<>0 then
      FD_SET(WFDs[I].Socket,FDs);
end;

function TWSOCKSocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
var RFDS,WFDS,EFDS: TWSock_Sock_List;
    RP,WP,EP: PWSock_Sock_List;
    Count: longint;
begin
  RP:=nil; WP:=nil; EP:=nil;
  if Assigned(readfds) then
  begin
     SockToWSockFDs(readfds^,RFDs,FD_READ);
     RP:=@RFDs;
  end;
  if Assigned(writefds) then
  begin
     SockToWSockFDs(writefds^,WFDs,FD_WRITE);
     WP:=@WFDs;
  end;
  if Assigned(exceptfds) then
  begin
     SockToWSockFDs(exceptfds^,EFDs,wsock_FD_FAILED_CONNECT);
     EP:=@EFDs;
  end;
  Count:=wsock_select(nfds,RP,WP,EP);
  if Assigned(readfds) then WSockToSockFDs(RFDs,readfds^);
  if Assigned(writefds) then WSockToSockFDs(WFDs,writefds^);
  if Assigned(exceptfds) then WSockToSockFDs(EFDs,exceptfds^);
  if CheckError<>0 then
    Count:=-1;
  select:=Count;
end;

function TWSOCKSocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
begin
  wsock_send(s,@Buf,len,flags,-1);
  send:=len;
end;

function TWSOCKSocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr;
         tolen: longint): longint;
begin
  wsock_sendto(s,@addrto,tolen,@Buf,len,flags,-1);
  sendto:=len;
end;

function TWSOCKSocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
begin
  setsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TWSOCKSocketsInterface.shutdown(s: TSocket; how: longint): longint;
begin
  wsock_shutdown(s,how);
  shutdown:=CheckError;
end;

function TWSOCKSocketsInterface.socket(af, struct, protocol: longint): TSocket;
var s: TWSockSocket;
begin
  if wsock_socket(af,struct,protocol,s)=false then
    s:=INVALID_SOCKET;
  CheckError;
  socket:=s;
end;

{ ------ }

function TWSOCKSocketsInterface.CheckError: longint;
begin
  CheckError:=ISetLastError(WSockError);
end;

{var WSockEventRealRegs: registers32;}
const
    WSockEventHandlerRealAddr: pointer = nil;

procedure WSockEventHandler; {$ifndef FPC}far;{$endif} assembler;
asm
  nop
  iret
end;

function TWSOCKSocketsInterface.WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint;
var Err: longint;
begin
  if Swap(wVersionRequired)>WSOCKVersion then
    Err:=WSAVERNOTSUPPORTED else
  begin
{    WSockEventHandlerRealAddr:=allocrmcallback(@WSockEventHandler,@WSockEventRealRegs);
    wsock_installeventhandler(WSockEventHandlerRealAddr);}
    FillChar(FSData,SizeOf(FSData),0);
    with FSData do
    begin
      wVersion:=Swap(Min(Swap(wVersionRequired),WSockVersion));
      wHighVersion:=Swap(WSockVersion);
      StrPCopy(szDescription,'WinSock '+VersionToStr(WSockVersion)+' - VXD');
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

function TWSOCKSocketsInterface.WSACleanup: longint;
var Err: longint;
begin
  Err:=WSAOK;
  ISetLastError(Err);
  WSACleanup:=Err;
  if assigned(WSockEventHandlerRealAddr) then
    freermcallback(WSockEventHandlerRealAddr);
end;

function CreateInterface(ID: integer): PSocketsInterface; {$ifdef TP}far;{$endif}
begin
  CreateInterface:=New(PWSOCKSocketsInterface, Init(ID));
end;

procedure RegisterInterface;
begin
  RegisterSocketsInterface(
    {$ifdef FPC}@{$endif}WSockInit,
    {$ifdef FPC}@{$endif}CreateInterface
  );
end;

END.
