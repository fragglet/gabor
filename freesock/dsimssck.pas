{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Microsoft SOCKETS.EXE sockets interface

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
unit DSIMSSCK;

interface

uses Objects, Types, Sockets, DSIIntf, MSSocks;

const
     MSSockForcePush : boolean = true;

type
     PMSSOCKSocketsInterface = ^TMSSOCKSocketsInterface;
     TMSSOCKSocketsInterface = object(TSocketsInterface)
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
       function WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint; virtual;
       function WSACleanup: longint; virtual;
     private
       function GetLastMSSockError: longint;
       function CheckError: longint;
       function CheckErrorBool: boolean;
     end;

procedure RegisterInterface;

implementation

uses Strings,SockCnst,SockUtil;

function TMSSOCKSocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
var len: word;
    news: TMSSocket;
begin
  if assigned(addrlen) then len:=addrlen^ else len:=0;
  news:=mss_INVALID_SOCKET;
  if mss_accept(s,addr,len,news) then
    if assigned(addrlen) then
      addrlen^:=len;
  if CheckErrorBool=false then news:=INVALID_SOCKET;
  accept:=news;
end;

function TMSSOCKSocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
begin
  mss_bind(s,@addr,namelen);
  bind:=CheckError;
end;

function TMSSOCKSocketsInterface.closesocket(s: TSocket): longint;
begin
  mss_closesocket(s);
  closesocket:=CheckError;
end;

function TMSSOCKSocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
begin
  mss_connect(s,@name,namelen);
  connect:=CheckError;
end;

function TMSSOCKSocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
begin
  ioctlsocket:=ISetLastError(WSAEOPNOTSUPP);
end;

function TMSSOCKSocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var w: word;
begin
  w:=namelen;
  mss_getpeername(s,@name,w);
  namelen:=w;
  getpeername:=CheckError;
end;

function TMSSOCKSocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var w: word;
begin
  w:=namelen;
  mss_getsockname(s,@name,w);
  namelen:=w;
  getsockname:=CheckError;
end;

function TMSSOCKSocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
begin
  getsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TMSSOCKSocketsInterface.listen(s: TSocket; backlog: longint): longint;
begin
  mss_listen(s,backlog);
  listen:=CheckError;
end;


function TMSSOCKSocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
var size: word;
    msflags: word;
begin
  size:=0;
  if (Flags and not (MSG_OOB+MSG_PEEK))<>0 then
    ISetLastError(WSAEOPNOTSUPP) else
  begin
    size:=min(len,high(size));
    msflags:=0;
    if (flags and MSG_OOB)<>0 then
      msflags:=msflags or mss_msg_push;
    if (flags and MSG_PEEK)<>0 then
      msflags:=msflags or mss_msg_peek;
    mss_recv(s,Buf,size,msflags);
    CheckError;
  end;
  recv:=size;
end;

function TMSSOCKSocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
         var fromlen: longint): longint;
begin
{  mss_recvfrom(s,@from,fromlen,@Buf,len,flags,0);
  recvfrom:=len;}
  Abstract;
  recvfrom:=-1; { eliminate warning }
end;

function SockToMSSockFDs(const FDs: TFDSet; var MSFDs: TMSFDSET): boolean;
var I: integer;
    OK: boolean;
begin
  FillChar(MSFDs,SizeOf(MSFDs),0);
  OK:=true;
  mss_FD_ZERO(MSFDs);
  for I:=0 to FDs.fd_count-1 do
    OK:=OK and mss_FD_SET(FDs.fd_array[I],MSFDs);
  SockToMSSockFDs:=OK;
end;

procedure MSSockToSockFDs(const MSFDs: TMSFDSET; var FDs: TFDSet);
var I: integer;
    IsSet: boolean;
begin
  FD_ZERO(FDs);
  for I:=mss_firstsocket to mss_lastsocket do
    begin
      mss_FD_ISSET(I,MSFDs,IsSet);
      if IsSet then
        FD_SET(I,FDs);
    end;
end;

function TMSSOCKSocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
var RFDS,WFDS,EFDS: TMSFDSET;
    RP,WP,EP: PMSFDSET;
    MSTO: TMSTimeVal;
    MSTimeout: PMSTimeVal;
    Count: integer;
begin
  RP:=nil; WP:=nil; EP:=nil; MSTimeout:=nil;
  if Assigned(readfds) then
  begin
     SockToMSSockFDs(readfds^,RFDs);
     RP:=@RFDs;
  end;
  if Assigned(writefds) then
  begin
     SockToMSSockFDs(writefds^,WFDs);
     WP:=@WFDs;
  end;
  if Assigned(exceptfds) then
  begin
     SockToMSSockFDs(exceptfds^,EFDs);
     EP:=@EFDs;
  end;
  if Assigned(timeout) then
  begin
    MSTO.tv_sec:=TimeOut^.tv_sec;
    MSTO.tv_usec:=TimeOut^.tv_usec;
    MSTimeout:=@MSTO;
  end;
  mss_select(nfds,RP,WP,EP,MSTimeout,@Count);
  if Assigned(readfds) then MSSockToSockFDs(RFDs,readfds^);
  if Assigned(writefds) then MSSockToSockFDs(WFDs,writefds^);
  if Assigned(exceptfds) then MSSockToSockFDs(EFDs,exceptfds^);
  if CheckError<>0 then
    Count:=-1;
  select:=Count;
end;

function TMSSOCKSocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
var size: word;
    msflags: word;
begin
  size:=min(len,high(size));
  msflags:=0;
  if MSSOCKForcePush then
    msflags:=msflags or mss_msg_Push;
  if (flags and MSG_OOB)<>0 then
    msflags:=msflags or mss_msg_Push;
  mss_send(s,Buf,size,msflags);
  send:=size;
end;

function TMSSOCKSocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr;
         tolen: longint): longint;
begin
{  mss_sendto(s,@addrto,tolen,@Buf,len,flags,0);
  sendto:=len;}
  Abstract;
  sendto:=-1; { eliminate warning }
end;

function TMSSOCKSocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
begin
  setsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TMSSOCKSocketsInterface.shutdown(s: TSocket; how: longint): longint;
begin
{  mss_shutdown(s,how);
  shutdown:=CheckError;}
  Abstract;
  shutdown:=-1; { eliminate warning }
end;

function TMSSOCKSocketsInterface.socket(af, struct, protocol: longint): TSocket;
var s: TMSSocket;
begin
  if mss_socket(af,struct,protocol,s)=false then
    s:=INVALID_SOCKET;
  CheckError;
  socket:=s;
end;

function TMSSOCKSocketsInterface.gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt;
begin
  gethostbyaddr:=inherited gethostbyaddr(addr,len,struct);
end;

function TMSSOCKSocketsInterface.gethostbyname(name: PChar): PHostEnt;
begin
  gethostbyname:=inherited gethostbyname(name);
end;

function TMSSOCKSocketsInterface.gethostname(name: PChar; len: longint): longint;
begin
  mss_gethostname(name,len);
  gethostname:=CheckError;
end;

function TMSSOCKSocketsInterface.getservbyport(port: Integer; proto: PChar): PServEnt;
begin
  getservbyport:=inherited getservbyport(port,proto);
end;

function TMSSOCKSocketsInterface.getservbyname(name, proto: PChar): PServEnt;
begin
  getservbyname:=inherited getservbyname(name,proto);
end;

function TMSSOCKSocketsInterface.getprotobynumber(proto: longint): PProtoEnt;
begin
  getprotobynumber:=inherited getprotobynumber(proto);
end;

function TMSSOCKSocketsInterface.getprotobyname(name: PChar): PProtoEnt;
begin
  getprotobyname:=inherited getprotobyname(name);
end;


{ ------ }

function TMSSOCKSocketsInterface.CheckErrorBool: boolean;
begin
  CheckErrorBool:=CheckError=0;
end;

function TMSSOCKSocketsInterface.CheckError: longint;
begin
  CheckError:=ISetLastError(GetLastMSSockError);
end;

function TMSSOCKSocketsInterface.GetLastMSSockError: longint;
var Err: longint;
begin
  case MSSockError of
    0                          : Err:=WSAOK;
    mss_err_NOTSOCK            : Err:=WSAENOTSOCK;
    mss_err_DESTADDRREQ        : Err:=WSAEDESTADDRREQ;
    mss_err_MSGSIZE            : Err:=WSAEMSGSIZE;
    mss_err_PROTOTYPE          : Err:=WSAEPROTOTYPE;
    mss_err_NOPROTOOPT         : Err:=WSAENOPROTOOPT;
    mss_err_PROTONOSUPPORT     : Err:=WSAEPROTONOSUPPORT;
    mss_err_SOCKTNOSUPPORT     : Err:=WSAESOCKTNOSUPPORT;
    mss_err_OPNOTSUPP          : Err:=WSAEOPNOTSUPP;
    mss_err_PFNOSUPPORT        : Err:=WSAEPFNOSUPPORT;
    mss_err_AFNOSUPPORT        : Err:=WSAEAFNOSUPPORT;

    mss_err_ADDRINUSE          : Err:=WSAEADDRINUSE;
    mss_err_ADDRNOTAVAIL       : Err:=WSAEADDRNOTAVAIL;
    mss_err_NETDOWN            : Err:=WSAENETDOWN;
    mss_err_NETUNREACH         : Err:=WSAENETUNREACH;
    mss_err_NETRESET           : Err:=WSAENETRESET;
    mss_err_CONNABORTED        : Err:=WSAECONNABORTED;
    mss_err_CONNRESET          : Err:=WSAECONNRESET;
    mss_err_NOBUFS             : Err:=WSAENOBUFS;
    mss_err_ISCONN             : Err:=WSAEISCONN;
    mss_err_NOTCONN            : Err:=WSAENOTCONN;

    mss_err_SHUTDOWN           : Err:=WSAESHUTDOWN;
    mss_err_TIMEDOUT           : Err:=WSAETIMEDOUT;
    mss_err_CONNREFUSED        : Err:=WSAECONNREFUSED;
    mss_err_HOSTDOWN           : Err:=WSAEHOSTDOWN;
    mss_err_HOSTUNREACH        : Err:=WSAEHOSTUNREACH;
    mss_err_WOULDBLOCK         : Err:=WSAEWOULDBLOCK;
    mss_err_INPROGRESS         : Err:=WSAEINPROGRESS;
    mss_err_ALREADY            : Err:=WSAEALREADY;
    mss_err_BADVERSION         : Err:=WSAEFAULT;
    mss_err_INVALSOCK          : Err:=WSAEINVAL;

    mss_err_TOOMANYSOCK        : Err:=WSAETOOMANYREFS;
    mss_err_FAULTSOCK          : Err:=WSAEINVAL;

    mss_err_NODOSMEM           : Err:=WSAENOBUFS;
    mss_err_BADRCFILE          : Err:=WSAEFAULT;
  else Err:=WSAEFAULT;
  end;
  GetLastMSSockError:=Err;
end;

function TMSSOCKSocketsInterface.WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint;
var Err: longint;
    ST: TMSSockStatus;
begin
  if SwapW(wVersionRequired)>MSSockVersion then
    Err:=WSAVERNOTSUPPORTED else
  begin
    mss_getstatus(ST);
    FillChar(FSData,SizeOf(FSData),0);
    with FSData do
    begin
      wVersion:=SwapW(Min(SwapW(wVersionRequired),MSSockVersion));
      wHighVersion:=SwapW(MSSockVersion);
      StrPCopy(szDescription,'LAN Manager (MS/IBM/HP/3Com) TCP/IP');
      StrPCopy(szSystemStatus,'Running');
      iMaxSockets:=ST.MaxSockets;
      iMaxUdpDg:=1400;
      lpVendorInfo:=nil;
    end;
    Err:=WSAOK;
  end;
  ISetLastError(Err);
  WSAStartup:=Err;
end;

function TMSSOCKSocketsInterface.WSACleanup: longint;
var Err: longint;
begin
  MSSockDone;
  Err:=WSAOK;
  ISetLastError(Err);
  WSACleanup:=Err;
end;

function CreateInterface(ID: integer): PSocketsInterface; {$ifdef TP}far;{$endif}
begin
  CreateInterface:=New(PMSSOCKSocketsInterface, Init(ID));
end;

procedure RegisterInterface;
begin
  RegisterSocketsInterface(
    {$ifdef FPC}@{$endif}MSSockInit,
    {$ifdef FPC}@{$endif}CreateInterface
  );
end;

END.