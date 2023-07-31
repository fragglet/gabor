{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Virtual Socket Library sockets interface

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
unit DSIVSL;

interface

uses Objects, Types, Sockets, DSIIntf, VSLSocks;

type
     PVSLSocketsInterface = ^TVSLSocketsInterface;
     TVSLSocketsInterface = object(TSocketsInterface)
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
       function GetLastVSLError: longint;
       function CheckError: longint;
       function CheckErrorBool: boolean;
       procedure VSLToSockAddr(VSLAddr: PVSLSockAddr; Addr: PSockAddr; AddrLen: integer);
       procedure SockToVSLAddr(Addr: PSockAddr; AddrLen: integer; VSLAddr: PVSLSockAddr);
     end;

procedure RegisterInterface;

implementation

uses Strings,SockCnst,SockUtil;

function TVSLSocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
var len: word;
    news: TVSLSocket;
    vsladdr: TVSLSockAddr;
begin
  if assigned(addrlen) then len:=addrlen^ else len:=0;
  news:=vsl_INVALID_SOCKET;
  if vsl_accept(s,@vsladdr,len,news) then
    begin
      VSLToSockAddr(@vsladdr,addr,len);
      if assigned(addrlen) then
        addrlen^:=len;
    end;
  if CheckErrorBool=false then news:=INVALID_SOCKET;
  accept:=news;
end;

function TVSLSocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
var vsladdr: TVSLSockAddr;
begin
  SockToVSLAddr(@addr,namelen,@vsladdr);
  vsl_bind(s,vsladdr,namelen);
  VSLToSockAddr(@vsladdr,@addr,namelen);
  bind:=CheckError;
end;

function TVSLSocketsInterface.closesocket(s: TSocket): longint;
begin
  vsl_closesocket(s);
  closesocket:=CheckError;
end;

function TVSLSocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
var vsladdr: TVSLSockAddr;
begin
  SockToVSLAddr(@name,namelen,@vsladdr);
  vsl_connect(s,vsladdr,namelen);
  VSLToSockAddr(@vsladdr,@name,namelen);
  connect:=CheckError;
end;

function TVSLSocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
begin
  ioctlsocket:=ISetLastError(WSAEOPNOTSUPP);
end;

function TVSLSocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var w: word;
    vsladdr: TVSLSockAddr;
begin
  w:=namelen;
  vsl_getpeername(s,vsladdr,w);
  namelen:=w;
  VSLToSockAddr(@vsladdr,@name,namelen);
  getpeername:=CheckError;
end;

function TVSLSocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var w: word;
    vsladdr: TVSLSockAddr;
begin
  w:=namelen;
  vsl_getsockname(s,vsladdr,w);
  namelen:=w;
  VSLToSockAddr(@vsladdr,@name,namelen);
  getsockname:=CheckError;
end;

function TVSLSocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
var w: integer;
begin
  w:=optlen;
  vsl_getsockopt(s,level,optname,optval,w);
  optlen:=w;
  getsockopt:=CheckError;
end;

function TVSLSocketsInterface.listen(s: TSocket; backlog: longint): longint;
begin
  vsl_listen(s,backlog);
  listen:=CheckError;
end;


function TVSLSocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
var size: word;
    msflags: word;
begin
  size:=0;
  if (Flags and not (MSG_OOB+MSG_PEEK))<>0 then
    ISetLastError(WSAEOPNOTSUPP) else
  begin
    size:=min(len,high(size));
    msflags:=0;
{    if (flags and MSG_OOB)<>0 then
      msflags:=msflags or vsl_msg_push;
    if (flags and MSG_PEEK)<>0 then
      msflags:=msflags or vsl_msg_peek;}
    vsl_recv(s,Buf,size,msflags);
    CheckError;
  end;
  recv:=size;
end;

function TVSLSocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
         var fromlen: longint): longint;
begin
{  vsl_recvfrom(s,@from,fromlen,@Buf,len,flags,0);
  recvfrom:=len;}
  Abstract;
  recvfrom:=-1; { eliminate warning }
end;

function SockToVSLFDs(const FDs: TFDSet; var VSLFDs: TVSLFDSET): boolean;
var I: integer;
    OK: boolean;
begin
  FillChar(VSLFDs,SizeOf(VSLFDs),0);
  OK:=true;
  vsl_FD_ZERO(VSLFDs);
  for I:=0 to FDs.fd_count-1 do
    OK:=OK and vsl_FD_SET(FDs.fd_array[I],VSLFDs);
  SockToVSLFDs:=OK;
end;

procedure VSLToSockFDs(const VSLFDs: TVSLFDSET; var FDs: TFDSet);
var I: integer;
    IsSet: boolean;
begin
  FD_ZERO(FDs);
  for I:=vsl_firstsocket to vsl_lastsocket do
    begin
      vsl_FD_ISSET(I,VSLFDs,IsSet);
      if IsSet then
        FD_SET(I,FDs);
    end;
end;

function TVSLSocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
var RFDS,WFDS,EFDS: TVSLFDSET;
    RP,WP,EP: PVSLFDSET;
    VSLTimeout: TVSLTimeVal;
    Count: integer;
begin
  RP:=nil; WP:=nil; EP:=nil;
  if Assigned(readfds) then
  begin
     SockToVSLFDs(readfds^,RFDs);
     RP:=@RFDs;
  end;
  if Assigned(writefds) then
  begin
     SockToVSLFDs(writefds^,WFDs);
     WP:=@WFDs;
  end;
  if Assigned(exceptfds) then
  begin
     SockToVSLFDs(exceptfds^,EFDs);
     EP:=@EFDs;
  end;
  if Assigned(timeout) then
    begin
      VSLTimeout.tv_sec:=TimeOut^.tv_sec;
      VSLTimeout.tv_usec:=TimeOut^.tv_usec;
    end
  else
    begin
      VSLTimeout.tv_sec:=-1;
      VSLTimeout.tv_usec:=-1;
    end;
  vsl_select(nfds,RP,WP,EP,VSLTimeout);
  if Assigned(readfds) then VSLToSockFDs(RFDs,readfds^);
  if Assigned(writefds) then VSLToSockFDs(WFDs,writefds^);
  if Assigned(exceptfds) then VSLToSockFDs(EFDs,exceptfds^);
  if CheckError<>0 then
    Count:=-1;
  select:=Count;
end;

function TVSLSocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
var size: word;
    msflags: word;
begin
  size:=min(len,high(size));
  msflags:=0;
{  if VSLForcePush then
    msflags:=msflags or vsl_msg_Push;
  if (flags and MSG_OOB)<>0 then
    msflags:=msflags or vsl_msg_Push;}
  vsl_send(s,Buf,size,msflags);
  send:=size;
end;

function TVSLSocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr;
         tolen: longint): longint;
begin
{  vsl_sendto(s,@addrto,tolen,@Buf,len,flags,0);
  sendto:=len;}
  Abstract;
  sendto:=-1; { eliminate warning }
end;

function TVSLSocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
begin
  setsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TVSLSocketsInterface.shutdown(s: TSocket; how: longint): longint;
begin
{  vsl_shutdown(s,how);
  shutdown:=CheckError;}
  Abstract;
  shutdown:=-1; { eliminate warning }
end;

function TVSLSocketsInterface.socket(af, struct, protocol: longint): TSocket;
var s: TVSLSocket;
begin
  if vsl_socket(af,struct,protocol,s)=false then
    s:=INVALID_SOCKET;
  CheckError;
  socket:=s;
end;

function TVSLSocketsInterface.gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt;
begin
  gethostbyaddr:=inherited gethostbyaddr(addr,len,struct);
end;

function TVSLSocketsInterface.gethostbyname(name: PChar): PHostEnt;
begin
  gethostbyname:=inherited gethostbyname(name);
end;

function TVSLSocketsInterface.gethostname(name: PChar; len: longint): longint;
begin
  vsl_gethostname(name,len);
  gethostname:=CheckError;
end;

function TVSLSocketsInterface.getservbyport(port: Integer; proto: PChar): PServEnt;
begin
  getservbyport:=inherited getservbyport(port,proto);
end;

function TVSLSocketsInterface.getservbyname(name, proto: PChar): PServEnt;
begin
  getservbyname:=inherited getservbyname(name,proto);
end;

function TVSLSocketsInterface.getprotobynumber(proto: longint): PProtoEnt;
begin
  getprotobynumber:=inherited getprotobynumber(proto);
end;

function TVSLSocketsInterface.getprotobyname(name: PChar): PProtoEnt;
begin
  getprotobyname:=inherited getprotobyname(name);
end;


{ ------ }

procedure TVSLSocketsInterface.VSLToSockAddr(VSLAddr: PVSLSockAddr; Addr: PSockAddr; AddrLen: integer);
begin
  if not Assigned(Addr) then Exit;
  FillChar(Addr^,sizeof(Addr^),0);
  if Assigned(VSLAddr) then
    Move(VSLAddr^,Addr^,AddrLen);
end;

procedure TVSLSocketsInterface.SockToVSLAddr(Addr: PSockAddr; AddrLen: integer; VSLAddr: PVSLSockAddr);
begin
  if not Assigned(VSLAddr) then Exit;
  FillChar(VSLAddr^,sizeof(VSLAddr^),0);
  if Assigned(Addr) then
    Move(Addr^,VSLAddr^,AddrLen);
end;

function TVSLSocketsInterface.CheckErrorBool: boolean;
begin
  CheckErrorBool:=CheckError=0;
end;

function TVSLSocketsInterface.CheckError: longint;
begin
  CheckError:=ISetLastError(GetLastVSLError);
end;

function TVSLSocketsInterface.GetLastVSLError: longint;
var Err: longint;
begin
  case VSLError of
    0                          : Err:=WSAOK;
    vsl_err_WOULDBLOCK	       : Err:=WSAEWOULDBLOCK;
    vsl_err_INPROGRESS	       : Err:=WSAEINPROGRESS;
    vsl_err_ALREADY	       : Err:=WSAEALREADY;
    vsl_err_NOTSOCK	       : Err:=WSAENOTSOCK;
    vsl_err_DESTADDRREQ	       : Err:=WSAEDESTADDRREQ;
    vsl_err_MSGSIZE	       : Err:=WSAEMSGSIZE;
    vsl_err_PROTOTYPE	       : Err:=WSAEPROTOTYPE;
    vsl_err_NOPROTOOPT	       : Err:=WSAENOPROTOOPT;
    vsl_err_PROTONOSUPPORT     : Err:=WSAEPROTONOSUPPORT;
    vsl_err_SOCKTNOSUPPORT     : Err:=WSAESOCKTNOSUPPORT;
    vsl_err_OPNOTSUPP	       : Err:=WSAEOPNOTSUPP;
    vsl_err_PFNOSUPPORT	       : Err:=WSAEPFNOSUPPORT;
    vsl_err_AFNOSUPPORT	       : Err:=WSAEAFNOSUPPORT;
    vsl_err_ADDRINUSE	       : Err:=WSAEADDRINUSE;
    vsl_err_ADDRNOTAVAIL       : Err:=WSAEADDRNOTAVAIL;
    vsl_err_NETDOWN	       : Err:=WSAENETDOWN;
    vsl_err_NETUNREACH	       : Err:=WSAENETUNREACH;
    vsl_err_NETRESET	       : Err:=WSAENETRESET;
    vsl_err_CONNABORTED	       : Err:=WSAECONNABORTED;
    vsl_err_CONNRESET	       : Err:=WSAECONNRESET;
    vsl_err_NOBUFS	       : Err:=WSAENOBUFS;
    vsl_err_ISCONN	       : Err:=WSAEISCONN;
    vsl_err_NOTCONN	       : Err:=WSAENOTCONN;
    vsl_err_SHUTDOWN	       : Err:=WSAESHUTDOWN;
    vsl_err_TOOMANYREFS	       : Err:=WSAETOOMANYREFS;

    vsl_err_TIMEDOUT	       : Err:=WSAETIMEDOUT;
    vsl_err_CONNREFUSED	       : Err:=WSAECONNREFUSED;
    vsl_err_LOOP	       : Err:=WSAELOOP;
    vsl_err_HOSTDOWN	       : Err:=WSAEHOSTDOWN;
    vsl_err_HOSTUNREACH	       : Err:=WSAEHOSTUNREACH;

    vsl_err_PROCLIM	       : Err:=WSAEPROCLIM;
    vsl_err_USERS	       : Err:=WSAEUSERS;
    vsl_err_DQUOT	       : Err:=WSAEDQUOT;
    vsl_err_STALE	       : Err:=WSAESTALE;
    vsl_err_REMOTE 	       : Err:=WSAEREMOTE;
{    vsl_err_NOSTR	       : Err:=WSAENOSTR;}
    vsl_err_TIME	       : Err:=WSAETIMEDOUT;
    vsl_err_NOSR	       : Err:=WSAENOBUFS;
{    vsl_err_NOMSG	       : Err:=WSAENOMSG;}
{    vsl_err_BADMSG 	       : Err:=WSAE;}
    vsl_err_IDRM	       : Err:=WSAEHOSTUNREACH;

{    vsl_err_BADVERSION	       : Err:=WSAE;
    vsl_err_INVALSOCK	       : Err:=WSAE;}

    vsl_err_TOOMANYSOCK	       : Err:=WSAENOBUFS;
    vsl_err_FAULTSOCK	       : Err:=WSAEFAULT;

    vsl_err_RESET	       : Err:=WSAENETRESET;
{    vsl_err_NOTUNIQUE	       : Err:=WSAENOTUNIQUE;
    vsl_err_NOGATEADDR	       : Err:=WSAENOGATEADDR;
    vsl_err_SENDERR	       : Err:=WSAESENDERR;
    vsl_err_NOETHDRVR	       : Err:=WSAENOETHDRVR;
    vsl_err_WRITPENDING	       : Err:=WSAEWRITEPENDING;
    vsl_err_READPENDING	       : Err:=WSAEREADPENDING;
    vsl_err_NOTCPIP	       : Err:=WSAENOTCPIP;
    vsl_err_DRVBUSY	       : Err:=WSAEDRVBUSY;

    vsl_err_UNKNOWN 	       : Err:=WSAEUNKNOWN;}

    vsl_err_ENAMETOOLONG       : Err:=WSAENAMETOOLONG;
    vsl_err_ENOTEMPTY	       : Err:=WSAENOTEMPTY;
{    vsl_err_DEADLK 	       : Err:=WSAEDEADLK;
    vsl_err_NOLCK	       : Err:=WSAENOLCK;}

    vsl_err_NET_MODULE_NOT_LOADED    : Err:=WSANOTINITIALISED;
    vsl_err_NET_TRANSPORT_NOT_LOADED : Err:=WSAEPROVIDERFAILEDINIT;
    vsl_err_LIBRARY_NOT_INITIALISED  : Err:=WSANOTINITIALISED;
    vsl_err_ALREADY_INITIALISED      : Err:=WSAEALREADY;
    vsl_err_UNKNOWN_NETKEY           : Err:=WSAENETUNREACH;
    vsl_err_UNSUPPORTED_NET          : Err:=WSAENETUNREACH;
    vsl_err_UNKNOWN_NET_INTERFACE    : Err:=WSAENETUNREACH;
    vsl_err_UNKNOWN_NET_MODULE       : Err:=WSAENETUNREACH;
    vsl_err_UNSUPPORTED_COMMAND      : Err:=WSAEOPNOTSUPP;
  else Err:=WSAEFAULT;
  end;
  GetLastVSLError:=Err;
end;

function TVSLSocketsInterface.WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint;
var Err: longint;
begin
  if SwapW(wVersionRequired)>VSLSockVersion then
    Err:=WSAVERNOTSUPPORTED else
  begin
    FillChar(FSData,SizeOf(FSData),0);
    with FSData do
    begin
      wVersion:=SwapW(Min(SwapW(wVersionRequired),VSLVersion));
      wHighVersion:=SwapW(VSLVersion);
      StrPCopy(szDescription,'Virtual Sockets Library');
      StrPCopy(szSystemStatus,'Running');
      iMaxSockets:=20;
      iMaxUdpDg:=1400;
      lpVendorInfo:=nil;
    end;
    Err:=WSAOK;
  end;
  ISetLastError(Err);
  WSAStartup:=Err;
end;

function TVSLSocketsInterface.WSACleanup: longint;
var Err: longint;
begin
  VSLDone;
  Err:=WSAOK;
  ISetLastError(Err);
  WSACleanup:=Err;
end;

function CreateInterface(ID: integer): PSocketsInterface; {$ifdef TP}far;{$endif}
begin
  CreateInterface:=New(PVSLSocketsInterface, Init(ID));
end;

procedure RegisterInterface;
begin
  RegisterSocketsInterface(
    {$ifdef FPC}@{$endif}VSLInit,
    {$ifdef FPC}@{$endif}CreateInterface
  );
end;

END.