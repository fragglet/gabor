{
    $Id: dsinw.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Novell LAN Workplace TCP/IP (DOS) interface

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
unit DSINW;

interface

uses Objects, Types, Sockets, DSIIntf, NWSocks;

const
     NWSocketsVersion = $0101; { this means 1.1 (1.2 would be $0102) }

type
     PNWSocketsInterface = ^TNWSocketsInterface;
     TNWSocketsInterface = object(TSocketsInterface)
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
       function  NWToSockAddr(const NWAddr: TNWSockAddr; var addr: TSockAddr): longint;
       procedure SockToNWAddr(const addr: TSockAddr; var NWAddr: TNWSockAddr);
       function  GetLastNWSockError: longint;
       function  SockToNWOptName(const OptLevel, SockOpt: longint; var NWOpt: word; var NWOptValue: word): boolean;
       procedure NWToSockFD(const NWSockBitmap: TNWSocketBitmap; var FD: TFDSet);
       procedure SockToNWFD(const FD: TFDSet; var NWSockBitmap: TNWSocketBitmap);
       function  NWCheckSockAddrFamily(const addr: TSockAddr): boolean;
     end;

procedure RegisterInterface;

implementation

uses Strings,SockCnst,SockUtil;

const
     NWSOCK_MIN  = 0;
     NWSOCK_MAX  = 255;

function TNWSocketsInterface.GetLastNWSockError: longint;
var Err: longint;
begin
  case NWSockError of
    nws_err_OK                     : Err:=WSAOK;
    nws_err_WouldBlock1            : Err:=WSAEWOULDBLOCK;
    nws_err_InvalidSocket          : Err:=WSAEINVAL;
    nws_err_WouldBlock             : Err:=WSAEWOULDBLOCK;
    nws_err_OperationInProgress    : Err:=WSAEINPROGRESS;
    nws_err_AlreadyInProgress      : Err:=WSAEALREADY;
    nws_err_NotASocket             : Err:=WSAENOTSOCK;
    nws_err_DestinationRequired    : Err:=WSAEDESTADDRREQ;
    nws_err_MessageTooLong         : Err:=WSAEMSGSIZE;
    nws_err_WrongProtocolType      : Err:=WSAEPROTOTYPE;
    nws_err_ProtocolUnavailable    : Err:=WSAENOPROTOOPT;
    nws_err_ProtocolNotSupported   : Err:=WSAEPROTONOSUPPORT;
    nws_err_SocketTypeNotSupported : Err:=WSAESOCKTNOSUPPORT;
    nws_err_OpNotSupportedOnSocket : Err:=WSAEOPNOTSUPP;
    nws_err_ProtFamilyNotSupported : Err:=WSAEPFNOSUPPORT;
    nws_err_AddrFamilyNotSuppByProt: Err:=WSAEAFNOSUPPORT;
    nws_err_AddressAlreadyInUse    : Err:=WSAEADDRINUSE;
    nws_err_UnableToAssignReqAddr  : Err:=WSAEADDRNOTAVAIL;
    nws_err_NetworkIsDown          : Err:=WSAENETDOWN;
    nws_err_NetworkUnreachable     : Err:=WSAENETUNREACH;
    nws_err_NetworkDroppedConnection: Err:=WSAENETRESET;
    nws_err_SoftwareCausedConnAbort: Err:=WSAECONNABORTED;
    nws_err_ConnectionResetByPeer  : Err:=WSAECONNRESET;
    nws_err_NoBufferSpace          : Err:=WSAENOBUFS;
    nws_err_SocketAlreadyConnected : Err:=WSAEISCONN;
    nws_err_SocketNotConnected     : Err:=WSAENOTCONN;
    nws_err_SocketInShutdown       : Err:=WSAESHUTDOWN;
    nws_err_TooManyReferences      : Err:=WSAETOOMANYREFS;
    nws_err_ConnectionTimedOut     : Err:=WSAETIMEDOUT;
    nws_err_ConnectionRefused      : Err:=WSAECONNREFUSED;
    nws_err_TooManyLevelsOfLink    : Err:=WSAELOOP;
    nws_err_FileNameTooLong        : Err:=WSAENAMETOOLONG;
    nws_err_HostIsDown             : Err:=WSAEHOSTDOWN;
    nws_err_HostUnreachable        : Err:=WSAEHOSTUNREACH;
    { ---- }
    nws_err_ProtocolStackNotInstalled: Err:=WSAEPROTONOSUPPORT;
    nws_err_AsynchOpNotSupported   : Err:=WSAEOPNOTSUPP;
    nws_err_SynchOpNotSupported    : Err:=WSAEOPNOTSUPP;
    nws_err_NoRCBAvailable         : Err:=WSAETOOMANYREFS;
    nws_err_Blocking               : Err:=WSAEWOULDBLOCK;
  else  Err:=WSAEFAULT;
  end;
  GetLastNWSockError:=Err;
end;

function TNWSocketsInterface.NWToSockAddr(const NWAddr: TNWSockAddr; var addr: TSockAddr): longint;
begin
  with TSockAddrIn(addr) do
  begin
    sin_family:=AF_INET;
    sin_port:=swapw(NWAddr.Port);
    sin_addr.s_addr:=swapl(NWAddr.IP);
  end;
  NWToSockAddr:=INETADDRSIZE;
end;

procedure TNWSocketsInterface.SockToNWAddr(const addr: TSockAddr; var NWAddr: TNWSockAddr);
begin
  with TSockAddrIn(addr) do
  begin
    NWAddr.Port:=swapw(sin_port);
    NWAddr.IP:=swapl(sin_addr.s_addr);
  end;
end;

function TNWSocketsInterface.SockToNWOptName(const OptLevel, SockOpt: longint; var NWOpt: word; var NWOptValue: word): boolean;
var OK: boolean;
begin
  if (OptLevel=SOL_SOCKET) then
      begin
        OK:=true;
        case SockOpt of
          SO_REUSEADDR : NWOpt:=nws_so_ReuseAddr;
          SO_KEEPALIVE : NWOpt:=nws_so_KeepAlive;
          SO_LINGER    : NWOpt:=nws_so_Linger;
        else OK:=false;
        end;
      end else
  if (OptLevel=IPPROTO_TCP) then
      begin
        OK:=false;
      end else
   OK:=false;
  SockToNWOptName:=OK;
end;

procedure TNWSocketsInterface.NWToSockFD(const NWSockBitmap: TNWSocketBitmap; var FD: TFDSet);
var I: integer;
    BitMask,BytePos: byte;
begin
  FD_Zero(FD);
  for I:=0 to (High(NWSockBitmap)+1)*8-1 do
    begin
      BytePos:=I shr 3; { = I div 8 }
      BitMask:=1 shl (I and $07); { = 1 shl (I mod 8) }
      if (NWSockBitmap[BytePos] and BitMask)<>0 then
        FD_Set(TSocket(I),FD);
    end;
end;

procedure TNWSocketsInterface.SockToNWFD(const FD: TFDSet; var NWSockBitmap: TNWSocketBitmap);
var I: u_int;
    Sock,BytePos,BitMask: byte;
begin
  FillChar(NWSockBitmap,SizeOf(NWSockBitmap),0);
  if FD.fd_count>0 then
  for I:=0 to FD.fd_count-1 do
    begin
      Sock:=FD.fd_array[I];
      BytePos:=Sock shr 3; { = Sock div 8 }
      BitMask:=1 shl (Sock and $07);
      NWSockBitmap[BytePos]:=NWSockBitmap[BytePos] or BitMask;
    end;
end;

function TNWSocketsInterface.NWCheckSockAddrFamily(const addr: TSockAddr): boolean;
begin
  NWCheckSockAddrFamily:=(TSockAddrIn(addr).sin_family=AF_INET);
end;

function TNWSocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
var Sock: TSocket;
    NWSock: TNWSocket;
    Err: longint;
    NWAddr: TNWSockAddr;
begin
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if assigned(addrlen) and (addrlen^<INETADDRSIZE) then
    Err:=WSAEFAULT else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  begin
    if Assigned(Addr) then
      SockToNWAddr(Addr^,NWAddr)
    else
      FillChar(NWAddr,SizeOf(NWAddr),0);
    if nws_accept(S,NWAddr,NWSock) then
      begin
        if Assigned(addrlen) then addrlen^:=6;
        if Assigned(addr) then NWToSockAddr(NWAddr,addr^);
      end;
    Sock:=NWSock;
    Err:=GetLastNWSockError;
  end;
  if Err<>WSAOK then Sock:=SOCKET_ERROR;
  ISetLastError(Err);
  accept:=Sock;
end;

function TNWSocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
var Err: longint;
    NWAddr: TNWSockAddr;
begin
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if (namelen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  begin
    SockToNWAddr(addr,NWAddr);
    nws_bind(S,NWAddr);
    Err:=GetLastNWSockError;
  end;
  bind:=ISetLastError(Err);
end;

function TNWSocketsInterface.closesocket(s: TSocket): longint;
var Err: longint;
begin
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  begin
    nws_close(S);
    Err:=GetLastNWSockError;
  end;
  closesocket:=ISetLastError(Err);
end;

function TNWSocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
var Err: longint;
    NWAddr: TNWSockAddr;
begin
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if (namelen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  if NWCheckSockAddrFamily(name)=false then
    Err:=WSAEAFNOSUPPORT else
  begin
    SockToNWAddr(name,NWAddr);
    if nws_connect(S,NWAddr.IP,NWAddr.Port) then
      NWToSockAddr(NWAddr,name);
    Err:=GetLastNWSockError;
  end;
  connect:=ISetLastError(Err);
end;

function TNWSocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
begin
  Abstract;
  ioctlsocket:=-1; { eliminate warning }
end;

function TNWSocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var Err: longint;
    NWAddr: TNWSockAddr;
begin
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if (namelen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  begin
    if nws_getpeername(S,NWAddr) then
      namelen:=NWToSockAddr(NWAddr,name);
    Err:=GetLastNWSockError;
  end;
  getpeername:=ISetLastError(Err);
end;

function TNWSocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var Err: longint;
    NWAddr: TNWSockAddr;
begin
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if (namelen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  begin
    if nws_getsockname(S,NWAddr) then
      namelen:=NWToSockAddr(NWAddr,name);
    Err:=GetLastNWSockError;
  end;
  getsockname:=ISetLastError(Err);
end;

function TNWSocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
var Err: longint;
begin
  if (level<>SOL_SOCKET) and (level<>IPPROTO_TCP) then
    Err:=WSAEINVAL
  else
    Err:=WSAENOPROTOOPT;
  getsockopt:=ISetLastError(Err);
end;

function TNWSocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
var Err: longint;
begin
  if (level<>SOL_SOCKET) and (level<>IPPROTO_TCP) then
    Err:=WSAEINVAL
  else
    Err:=WSAENOPROTOOPT;
  setsockopt:=ISetLastError(Err);
end;

function TNWSocketsInterface.listen(s: TSocket; backlog: longint): longint;
var Err: longint;
begin
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  if CheckRange(backlog,1,65535)=false then
    Err:=WSAEFAULT else
  begin
    nws_listen(S,backlog);
    Err:=GetLastNWSockError;
  end;
  listen:=ISetLastError(Err);
end;

function TNWSocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
var addr: tsockaddr;
    size: longint;
begin
  size:=sizeof(addr);
  fillchar(addr,sizeof(addr),0);
  recv:=recvfrom(s,Buf,Len,flags,addr,size);
end;

function TNWSocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint;
  var from: TSockAddr; var fromlen: longint): longint;
var Err: longint;
    NWAddr: TNWSockAddr;
    W: word;
    nwflags: word;
begin
  W:=0;
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if (fromlen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  begin
    W:=Min(len,65535);
    SockToNWAddr(from,NWAddr);
    nwflags:=0;
    if nws_recvfrom(S,NWAddr,Buf,W,nwflags) then
      fromlen:=NWToSockAddr(NWAddr,from);
    Err:=GetLastNWSockError;
    if (Err=WSAOK) and (W<len) then Err:=WSAEMSGSIZE;
  end;
  ISetLastError(Err);
  recvfrom:=W;
end;

function TNWSocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
var Err: longint;
    W: word;
begin
  W:=0;
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  begin
    W:=Min(len,65535);
    nws_send(S,Buf,W,flags);
    Err:=GetLastNWSockError;
    if Err<>WSAOK then W:=0 else
    if (Err=WSAOK) and (W<len) then Err:=WSAEMSGSIZE;
  end;
  ISetLastError(Err);
  send:=W;
end;

function TNWSocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr; tolen: longint): longint;
var Err: longint;
    NWAddr: TNWSockAddr;
    W: word;
begin
  W:=0;
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if (tolen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  begin
    W:=Min(len,65535);
    SockToNWAddr(addrto,NWAddr);
    nws_sendto(S,NWAddr,Buf,W,flags);
    Err:=GetLastNWSockError;
    if Err<>WSAOK then W:=0 else
    if (Err=WSAOK) and (W<len) then Err:=WSAEMSGSIZE;
  end;
  ISetLastError(Err);
  sendto:=W;
end;

function TNWSocketsInterface.shutdown(s: TSocket; how: longint): longint;
var Err: longint;
begin
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if CheckRange(S,NWSOCK_MIN,NWSOCK_MAX)=false then
    Err:=WSAENOTSOCK else
  begin
    nws_shutdown(S,how);
    Err:=GetLastNWSockError;
  end;
  shutdown:=ISetLastError(Err);
end;

function TNWSocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
var Err: longint;
    NWReadFDS,NWWriteFDS,NWExceptFDS: TNWSocketBitmap;
    NWTimeOut,NWCount: longint;
begin
  FillChar(NWReadFDS,SizeOf(NWReadFDS),0);
  FillChar(NWWriteFDS,SizeOf(NWWriteFDS),0);
  FillChar(NWExceptFDS,SizeOf(NWExceptFDS),0);
 
  if assigned(readfds) then
    SockToNWFD(readfds^,NWReadFDS);
  if assigned(writefds) then
    SockToNWFD(writefds^,NWWriteFDS);
  if assigned(exceptfds) then
    SockToNWFD(exceptfds^,NWExceptFDS);
  if assigned(timeout) then
    nwtimeout:=TimeValToTicks(timeout^)
  else
    nwtimeout:=-MaxLongint-1; { $ffffffff }

  if nws_select(NWReadFDS,NWWriteFDS,NWExceptFDS,nwtimeout,nwcount)=false then
    begin
      NWCount:=0;
      if assigned(readfds) then FD_ZERO(readfds^);
      if assigned(writefds) then FD_ZERO(writefds^);
      if assigned(exceptfds) then FD_ZERO(exceptfds^);
    end
  else
    begin
      if assigned(readfds) then NWToSockFD(NWReadFDS,readfds^);
      if assigned(writefds) then NWToSockFD(NWWriteFDS,writefds^);
      if assigned(exceptfds) then NWToSockFD(NWExceptFDS,exceptfds^);
    end;

  Err:=GetLastNWSockError;
  ISetLastError(Err);
  select:=nwcount;
end;

function TNWSocketsInterface.socket(af, struct, protocol: longint): TSocket;
var Sock: TSocket;
    NWSock: TNWSocket;
    Err: longint;
begin
  Sock:=INVALID_SOCKET;
  Err:=WSAOK;
  if NWSockVersion=0 then
    Err:=WSANOTINITIALISED else
  if (af<>AF_INET) then
    Err:=WSAEAFNOSUPPORT else
  begin
    nws_socket(protocol,NWSock);
    Sock:=NWSock;
    Err:=GetLastNWSockError;
  end;
  ISetLastError(Err);
  socket:=Sock;
end;

function TNWSocketsInterface.WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint;
var Err: longint;
begin
  if SwapW(wVersionRequired)>NWSocketsVersion then
    Err:=WSAVERNOTSUPPORTED else
  if NWSockInit=false then
    Err:=WSASYSNOTREADY else
  begin
    FillChar(FSData,SizeOf(FSData),0);
    with FSData do
    begin
      wVersion:=SwapW(Min(SwapW(wVersionRequired),NWSocketsVersion));
      wHighVersion:=SwapW(NWSocketsVersion);
      StrCopy(szDescription,'LAN Workplace TCP/IP');
      StrCopy(szSystemStatus,'Running');
      iMaxSockets:=31;
      iMaxUdpDg:=576;
      lpVendorInfo:=nil;
    end;
    Err:=WSAOK;
  end;
  ISetLastError(Err);
  WSAStartup:=Err;
end;

function TNWSocketsInterface.WSACleanup: longint;
var Err: longint;
begin
  Err:=WSAOK;
  ISetLastError(Err);
  WSACleanup:=Err;
end;

function CreateInterface(ID: integer): PSocketsInterface; {$ifdef TP}far;{$endif}
begin
  CreateInterface:=New(PNWSocketsInterface, Init(ID));
end;

procedure RegisterInterface;
begin
  RegisterSocketsInterface(
    {$ifdef FPC}@{$endif}NWSockInit,
    {$ifdef FPC}@{$endif}CreateInterface
  );
end;

END.

{
  $Log: dsipas.inc,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
