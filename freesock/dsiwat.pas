{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    WATT-32 TSR sockets interface

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
unit DSIWAT;

interface

uses Objects, Types, Sockets, DSIIntf, WATSocks;

const WATVersion = $101;

type
     PWATSocketsInterface = ^TWATSocketsInterface;
     TWATSocketsInterface = object(TSocketsInterface)
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
       function FSAStartup(wVersionRequired: word; var FSData: TFSAData): longint; virtual;
       function FSACleanup: longint; virtual;
       function FSAGetLastError: longint; virtual;
     private
       function  WATToSockAddr(const WATAddr: TWATSockAddr; var addr: TSockAddr): longint;
       procedure SockToWATAddr(const addr: TSockAddr; var WATAddr: TWATSockAddr);
       function  GetLastWATError: longint;
       function  CheckError: longint;
       function  CheckErrorBool: boolean;
     end;

procedure RegisterInterface;

implementation

uses Strings,SockCnst,SockUtil;

function TWATSocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
var len: word;
    neww: TWATSocket;
    news: TSocket;
    wataddr: TWATSockAddr;
begin
  if assigned(addrlen) then len:=addrlen^ else len:=0;
  neww:=wat_INVALID_SOCKET;
  if wat_accept(s,@wataddr,len,neww)=false then
    if assigned(addrlen) then
      addrlen^:=len;
  if assigned(addr) then
    WATToSockAddr(wataddr,addr^);
  news:=neww;
  if CheckErrorBool=false then news:=INVALID_SOCKET;
  accept:=news;
end;

function TWATSocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
begin
  wat_bind(s,@addr,namelen);
  bind:=CheckError;
end;

function TWATSocketsInterface.closesocket(s: TSocket): longint;
begin
  wat_closesocket(s);
  closesocket:=CheckError;
end;

function TWATSocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
begin
  wat_connect(s,@name,namelen);
  connect:=CheckError;
end;

function TWATSocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
begin
  ioctlsocket:=SetLastSockError(FSAEOPNOTSUPP);
end;

function TWATSocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var w: word;
begin
  w:=namelen;
  wat_getpeername(s,@name,w);
  namelen:=w;
  getpeername:=CheckError;
end;

function TWATSocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var w: word;
begin
  w:=namelen;
  wat_getsockname(s,@name,w);
  namelen:=w;
  getsockname:=CheckError;
end;

function TWATSocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
begin
  getsockopt:=SetLastSockError(FSAEOPNOTSUPP);
end;

function TWATSocketsInterface.listen(s: TSocket; backlog: longint): longint;
begin
  wat_listen(s,backlog);
  listen:=CheckError;
end;

function TWATSocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
var size: word;
    watflags: word;
    Err: longint;
begin
  size:=0;
  if (Flags and not (MSG_OOB+MSG_PEEK))<>0 then
    SetLastSockError(FSAEOPNOTSUPP) else
  begin
    size:=min(len,high(size));
    watflags:=0;
    if (flags and MSG_OOB)<>0 then
      watflags:=watflags or wat_MSG_OOB;
    if (flags and MSG_PEEK)<>0 then
      watflags:=watflags or wat_MSG_PEEK;
    watflags:=watflags or (wat_MSG_EOR+wat_MSG_OOB);
    wat_recv(s,Buf,size,watflags);
    CheckError;
  end;
  recv:=size;
end;

function TWATSocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
         var fromlen: longint): longint;
var w: word;
    size: word;
    watfrom: TWatSockAddr;
begin
  size:=len;
  wat_recvfrom(s,Buf,size,flags,@watfrom,w);
  fromlen:=w;
  WATToSockAddr(watfrom,from);
  recvfrom:=size;
end;

function TWATSocketsInterface.WATToSockAddr(const WATAddr: TWATSockAddr; var addr: TSockAddr): longint;
begin
  FillChar(Addr,SizeOf(Addr),0);
  with TSockAddrIn(Addr) do
  begin
    sin_family:=wataddr.sin_family;
    sin_port:=wataddr.sin_port;
    sin_addr.s_addr:=wataddr.sin_addr.s_addr;
  end;
end;

procedure TWATSocketsInterface.SockToWATAddr(const addr: TSockAddr; var WATAddr: TWATSockAddr);
begin
  FillChar(WatAddr,SizeOf(WatAddr),0);
  with WatAddr do
  begin
    sin_family:=TSockAddrIn(addr).sin_family;
    sin_port:=TSockAddrIn(addr).sin_port;
    sin_addr.s_addr:=TSockAddrIn(addr).sin_addr.s_addr;
  end;
end;

function SockToWATFDs(const FDs: TFDSet; var WATFDs: TWATFDSET): boolean;
var I: integer;
    OK: boolean;
begin
  FillChar(WATFDs,SizeOf(WATFDs),0);
  OK:=true;
  wat_FD_ZERO(WATFDs);
  for I:=0 to FDs.fd_count-1 do
    OK:=OK and wat_FD_SET(FDs.fd_array[I],WATFDs);
  SockToWATFDs:=OK;
end;

procedure WATToSockFDs(const WATFDs: TWATFDSET; var FDs: TFDSet);
var I: integer;
    IsSet: boolean;
begin
  FD_ZERO(FDs);
  for I:=wat_firstsocket to wat_lastsocket do
    begin
      wat_FD_ISSET(I,WATFDs,IsSet);
      if IsSet then
        FD_SET(I,FDs);
    end;
end;

function TWATSocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
var RFDS,WFDS,EFDS: TWATFDSET;
    RP,WP,EP: PWATFDSET;
    WATTO: TWATTimeVal;
    WATTimeout: PWATTimeVal;
    Count: integer;
begin
  RP:=nil; WP:=nil; EP:=nil; WATTimeout:=nil;
  if Assigned(readfds) then
  begin
     SockToWATFDs(readfds^,RFDs);
     RP:=@RFDs;
  end;
  if Assigned(writefds) then
  begin
     SockToWATFDs(writefds^,WFDs);
     WP:=@WFDs;
  end;
  if Assigned(exceptfds) then
  begin
     SockToWATFDs(exceptfds^,EFDs);
     EP:=@EFDs;
  end;
  if Assigned(timeout) then
  begin
    WATTO.tv_sec:=TimeOut^.tv_sec;
    WATTO.tv_usec:=TimeOut^.tv_usec;
    WATTimeout:=@WATTO;
  end;
  nfds:=WATFDSETSIZE; { set to maximum index }
  wat_select(nfds,RP,WP,EP,WATTimeout,@Count);
  if Assigned(readfds) then WATToSockFDs(RFDs,readfds^);
  if Assigned(writefds) then WATToSockFDs(WFDs,writefds^);
  if Assigned(exceptfds) then WATToSockFDs(EFDs,exceptfds^);
  if CheckError<>0 then
    Count:=-1;
  select:=Count;
end;

function TWATSocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
var size: word;
    watflags: word;
begin
  size:=min(len,high(size));
  watflags:=0;
  if (flags and MSG_OOB)<>0 then
    watflags:=watflags or wat_MSG_OOB;
{  watflags:=watflags or wat_MSG_EOR;}
  wat_send(s,Buf,size,watflags);
  send:=size;
end;

function TWATSocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr;
         tolen: longint): longint;
var size: word;
    wataddrto: TWATSockAddr;
begin
  size:=len;
  SockToWATAddr(addrto,wataddrto);
  wat_sendto(s,Buf,size,flags,@wataddrto,tolen);
  len:=size;
  sendto:=len;
end;

function TWATSocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
begin
  setsockopt:=SetLastSockError(FSAEOPNOTSUPP);
end;

function TWATSocketsInterface.shutdown(s: TSocket; how: longint): longint;
var wathow: word;
begin
  wathow:=how;
  wat_shutdown(s,wathow);
  shutdown:=CheckError;
end;

function TWATSocketsInterface.socket(af, struct, protocol: longint): TSocket;
var ws: TWATSocket;
    s: TSocket;
begin
  if wat_socket(af,struct,protocol,ws)=false then
    s:=INVALID_SOCKET
  else
    s:=ws;
  CheckError;
  socket:=s;
end;

function TWATSocketsInterface.gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt;
begin
  gethostbyaddr:=inherited gethostbyaddr(addr,len,struct);
end;

function TWATSocketsInterface.gethostbyname(name: PChar): PHostEnt;
begin
  gethostbyname:=inherited gethostbyname(name);
end;

function TWATSocketsInterface.gethostname(name: PChar; len: longint): longint;
begin
{  wat_gethostname(name,len);}
  gethostname:=CheckError;
end;

function TWATSocketsInterface.getservbyport(port: Integer; proto: PChar): PServEnt;
begin
  getservbyport:=inherited getservbyport(port,proto);
end;

function TWATSocketsInterface.getservbyname(name, proto: PChar): PServEnt;
begin
  getservbyname:=inherited getservbyname(name,proto);
end;

function TWATSocketsInterface.getprotobynumber(proto: longint): PProtoEnt;
begin
  getprotobynumber:=inherited getprotobynumber(proto);
end;

function TWATSocketsInterface.getprotobyname(name: PChar): PProtoEnt;
begin
  getprotobyname:=inherited getprotobyname(name);
end;


{ ------ }

function TWATSocketsInterface.CheckErrorBool: boolean;
begin
  CheckErrorBool:=CheckError=0;
end;

function TWATSocketsInterface.CheckError: longint;
begin
  CheckError:=SetLastSockError(GetLastWATError);
end;

function TWATSocketsInterface.GetLastWATError: longint;
var Err: longint;
begin
  case WATSocketError of
    wat_err_OK               : Err:=FSAOK;
    wat_err_NOENT	     : Err:=FSAEINVAL;	{ No such file or directory	}
    wat_err_NOTDIR           : Err:=FSAEINVAL;   { No path                      }
 {   wat_err_MFILE	     : Err:=FSAE;}  { Too many open files		}
    wat_err_INTR	     : Err:=FSAEINTR;	{ Interrupted system call }
    wat_err_ACCES	     : Err:=FSAEACCES;	{ Permission denied		}
    wat_err_BADF	     : Err:=FSAEBADF;	{ Bad file number		}
    wat_err_ARENA            : Err:=FSAEFAULT;	{ Arena trashed		}
    wat_err_NOMEM	     : Err:=FSAENOBUFS;	{ Not enough core		}
    wat_err_SEGV             : Err:=FSAEFAULT;	{ invalid memory address	}
    wat_err_BADENV           : Err:=FSAEFAULT;	{ invalid environment		}
    wat_err_NODEV	     : Err:=FSAEFAULT;	{ No such device		}
    wat_err_INVAL	     : Err:=FSAEINVAL;	{ Invalid argument		}
    wat_err_2BIG	     : Err:=FSAENOBUFS;	{ Arg list too long		}
    wat_err_NOEXEC           : Err:=FSAEFAULT;	{ Exec format error		}
    wat_err_XDEV	     : Err:=FSAEFAULT;	{ Cross-device link		}
    wat_err_DOM	             : Err:=FSAEFAULT;	{ Math argument		}
    wat_err_RANGE	     : Err:=FSAEFAULT;	{ Result too large		}
 {   wat_err_EXIST	     : Err:=FSAE;}	{ File already exists		}
    wat_err_EXIST	     : Err:=FSAEFAULT;	{ File already exists		}

    wat_err_NFILE	     : Err:=FSAENOBUFS;	{ File table overflow }
    wat_err_MFILE	     : Err:=FSAENOBUFS;	{ Too many open files }
    wat_err_NOTTY	     : Err:=FSAEFAULT;	{ Not a typewriter }
    wat_err_TXTBSY	     : Err:=FSAEFAULT;	{ Text file busy }
    wat_err_FBIG	     : Err:=FSAENOBUFS;	{ File too large }
    wat_err_NOSPC	     : Err:=FSAENOBUFS;	{ No space left on device }
    wat_err_SPIPE	     : Err:=FSAEFAULT;	{ Illegal seek }
    wat_err_ROFS	     : Err:=FSAEFAULT;	{ Read-only file system }
    wat_err_MLINK	     : Err:=FSAENOBUFS;	{ Too many links }
    wat_err_PIPE	     : Err:=FSAEFAULT;	{ Broken pipe }

 { non-blocking and interrupt i/o }
    wat_err_WOULDBLOCK	     : Err:=FSAEWOULDBLOCK;	{ Operation would block }
    wat_err_INPROGRESS	     : Err:=FSAEINPROGRESS;	{ Operation now in progress }
    wat_err_ALREADY	     : Err:=FSAEALREADY;	{ Operation already in progress }
 { ipc/network software }

	 { argument errors }
    wat_err_NOTSOCK	     : Err:=FSAENOTSOCK;	{ Socket operation on non-socket }
    wat_err_DESTADDRREQ	     : Err:=FSAEDESTADDRREQ;	{ Destination address required }
    wat_err_MSGSIZE	     : Err:=FSAEMSGSIZE;	{ Message too long }
    wat_err_PROTOTYPE	     : Err:=FSAEPROTOTYPE;	{ Protocol wrong type for socket }
    wat_err_NOPROTOOPT	     : Err:=FSAENOPROTOOPT;	{ Protocol not available }
    wat_err_PROTONOSUPPORT   : Err:=FSAEPROTONOSUPPORT;	{ Protocol not supported }
    wat_err_SOCKTNOSUPPORT   : Err:=FSAESOCKTNOSUPPORT;	{ Socket type not supported }
    wat_err_OPNOTSUPP	     : Err:=FSAEOPNOTSUPP;	{ Operation not supported on socket }
    wat_err_PFNOSUPPORT	     : Err:=FSAEPFNOSUPPORT;	{ Protocol family not supported }
    wat_err_AFNOSUPPORT	     : Err:=FSAEAFNOSUPPORT;	{ Address family not supported by protocol family }
    wat_err_ADDRINUSE	     : Err:=FSAEADDRINUSE;	{ Address already in use }
    wat_err_ADDRNOTAVAIL     : Err:=FSAEADDRNOTAVAIL;	{ Can't assign requested address }

	 { operational errors }
    wat_err_NETDOWN	     : Err:=FSAENETDOWN;	{ Network is down }
    wat_err_NETUNREACH	     : Err:=FSAENETUNREACH;	{ Network is unreachable }
    wat_err_NETRESET	     : Err:=FSAENETRESET;	{ Network dropped connection on reset }
    wat_err_CONNABORTED	     : Err:=FSAECONNABORTED;	{ Software caused connection abort }
    wat_err_CONNRESET	     : Err:=FSAECONNRESET;	{ Connection reset by peer }
    wat_err_NOBUFS	     : Err:=FSAENOBUFS;	{ No buffer space available }
    wat_err_ISCONN	     : Err:=FSAEISCONN;	{ Socket is already connected }
    wat_err_NOTCONN	     : Err:=FSAENOTCONN;	{ Socket is not connected }
    wat_err_SHUTDOWN	     : Err:=FSAESHUTDOWN;	{ Can't send after socket shutdown }
    wat_err_TOOMANYREFS	     : Err:=FSAETOOMANYREFS;	{ Too many references: can't splice }
    wat_err_TIMEDOUT	     : Err:=FSAETIMEDOUT;	{ Connection timed out }
    wat_err_CONNREFUSED	     : Err:=FSAECONNREFUSED;	{ Connection refused }

	 { }
    wat_err_LOOP	     : Err:=FSAELOOP;	{ Too many levels of symbolic links }
    wat_err_NAMETOOLONG	     : Err:=FSAENAMETOOLONG;	{ File name too long }

 { should be rearranged }
    wat_err_HOSTDOWN	     : Err:=FSAEHOSTDOWN;	{ Host is down }
    wat_err_HOSTUNREACH	     : Err:=FSAEHOSTUNREACH;	{ No route to host }
    wat_err_NOTEMPTY	     : Err:=FSAENOTEMPTY;	{ Directory not empty }

 { quotas & mush }
    wat_err_PROCLIM	     : Err:=FSAEPROCLIM;	{ Too many processes }
    wat_err_USERS	     : Err:=FSAEUSERS;	{ Too many users }
    wat_err_DQUOT	     : Err:=FSAEDQUOT;	{ Disc quota exceeded }
  else Err:=FSAEFAULT;
  end;
  GetLastWATError:=Err;
end;

function TWATSocketsInterface.FSAStartup(wVersionRequired: word; var FSData: TFSAData): longint;
var Err: longint;
begin
  if SwapW(wVersionRequired)>WATVersion then
    Err:=FSAVERNOTSUPPORTED else
  begin
    WATInstallTimer;
    FillChar(FSData,SizeOf(FSData),0);
    with FSData do
    begin
      wVersion:=SwapW(Min(SwapW(wVersionRequired),WATVersion));
      wHighVersion:=SwapW(WATVersion);
      StrPCopy(szDescription,'Waterloo TCP (TSR)');
      StrPCopy(szSystemStatus,'Running');
      iMaxSockets:=6;
      iMaxUdpDg:=1400;
      lpVendorInfo:=nil;
    end;
    Err:=FSAOK;
  end;
  SetLastSockError(Err);
  FSAStartup:=Err;
end;

function TWATSocketsInterface.FSACleanup: longint;
var Err: longint;
begin
{  WATDone;}
  WATDeInstallTimer;
  Err:=FSAOK;
  SetLastSockError(Err);
  FSACleanup:=Err;
end;

function TWATSocketsInterface.FSAGetLastError: longint;
begin
  FSAGetLastError:=GetLastSockError;
end;

function CreateInterface(ID: integer): PSocketsInterface; far;
begin
  CreateInterface:=New(PWATSocketsInterface, Init(ID));
end;

procedure RegisterInterface;
begin
  RegisterSocketsInterface(WatInit,CreateInterface);
end;

END.
