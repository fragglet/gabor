{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    WATT-32 driver interface

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
unit WatSocks;

interface

const
   WatSockIntr = $17;

   WatFDSETSIZE = 512;

   wat_AF_UNSPEC	 = 0;		{ unspecified }
   wat_AF_UNIX		 = 1;		{ local to host (pipes, portals) }
   wat_AF_INET		 = 2;		{ internetwork: UDP, TCP, etc. }
   wat_AF_IMPLINK	 = 3;		{ arpanet imp addresses }
   wat_AF_PUP		 = 4;		{ pup protocols: e.g. BSP }
   wat_AF_CHAOS	         = 5;		{ mit CHAOS protocols }
   wat_AF_NS		 = 6;		{ XEROX NS protocols }
   wat_AF_ISO		 = 7;		{ ISO protocols }
   wat_AF_OSI		 = wat_AF_ISO;
   wat_AF_ECMA		 = 8;		{ european computer manufacturers }
   wat_AF_DATAKIT	 = 9;		{ datakit protocols }
   wat_AF_CCITT	         = 10;		{ CCITT protocols, X.25 etc }
   wat_AF_SNA		 = 11;		{ IBM SNA }
   wat_AF_DECnet	 = 12;		{ DECnet }
   wat_AF_DLI		 = 13;		{ DEC Direct data link interface }
   wat_AF_LAT		 = 14;		{ LAT }
   wat_AF_HYLINK	 = 15;		{ NSC Hyperchannel }
   wat_AF_APPLETALK	 = 16;		{ Apple Talk }
   wat_AF_ROUTE	         = 17;		{ Internal Routing Protocol }
   wat_AF_LINK		 = 18;		{ Link layer interface }
   wat_pseudo_AF_XTP	 = 19;		{ eXpress Transfer Protocol (no AF) }
   wat_AF_MAX		 = 20;

   wat_PF_UNSPEC	 = wat_AF_UNSPEC;
   wat_PF_UNIX		 = wat_AF_UNIX;
   wat_PF_INET		 = wat_AF_INET;
   wat_PF_IMPLINK	 = wat_AF_IMPLINK;
   wat_PF_PUP		 = wat_AF_PUP;
   wat_PF_CHAOS	         = wat_AF_CHAOS;
   wat_PF_NS		 = wat_AF_NS;
   wat_PF_ISO		 = wat_AF_ISO;
   wat_PF_OSI		 = wat_AF_ISO;
   wat_PF_ECMA		 = wat_AF_ECMA;
   wat_PF_DATAKIT	 = wat_AF_DATAKIT;
   wat_PF_CCITT	         = wat_AF_CCITT;
   wat_PF_SNA		 = wat_AF_SNA;
   wat_PF_DECnet	 = wat_AF_DECnet;
   wat_PF_DLI		 = wat_AF_DLI;
   wat_PF_LAT		 = wat_AF_LAT;
   wat_PF_HYLINK	 = wat_AF_HYLINK;
   wat_PF_APPLETALK	 = wat_AF_APPLETALK;
   wat_PF_ROUTE	         = wat_AF_ROUTE;
   wat_PF_LINK		 = wat_AF_LINK;
   wat_PF_XTP		 = wat_pseudo_AF_XTP;	{ really just proto family, no AF }
   wat_PF_MAX		 = wat_AF_MAX;

   wat_SOCK_STREAM	 = 1;		{ stream socket }
   wat_SOCK_DGRAM	 = 2;		{ datagram socket }
   wat_SOCK_RAW	         = 3;		{ raw-protocol interface }
   wat_SOCK_RDM	         = 4;		{ reliably-delivered message }
   wat_SOCK_SEQPACKET	 = 5;		{ sequenced packet stream }

   wat_SO_DEBUG	         = $0001;
   wat_SO_ACCEPTCONN	 = $0002;
   wat_SO_REUSEADDR	 = $0004;
   wat_SO_KEEPALIVE	 = $0008;
   wat_SO_DONTROUTE	 = $0010;		{ just use interface addresses }
   wat_SO_BROADCAST	 = $0020;		{ permit sending of broadcast msgs }
   wat_SO_USELOOPBACK	 = $0040;		{ bypass hardware when possible }
   wat_SO_LINGER	 = $0080;
   wat_SO_OOBINLINE	 = $0100;		{ leave received OOB data in line }
{   wat_SO_DONTLINGER	 = not SO_LINGER;}

   wat_SO_SNDBUF	 = $1001;		{ send buffer size }
   wat_SO_RCVBUF	 = $1002;		{ receive buffer size }
   wat_SO_SNDLOWAT	 = $1003;		{ send low-water mark }
   wat_SO_RCVLOWAT	 = $1004;		{ receive low-water mark }
   wat_SO_SNDTIMEO	 = $1005;		{ send timeout }
   wat_SO_RCVTIMEO	 = $1006;		{ receive timeout }
   wat_SO_ERROR	         = $1007;		{ get error status and clear }
   wat_SO_TYPE		 = $1008;		{ get socket type }

   wat_SOL_SOCKET	 = $ffff;		{ options for socket level }

   wat_INVALID_SOCKET    = $0000;
   wat_SOCKET_ERROR      = $ffff;

   wat_MSG_OOB           = $01; { process out-of-band data }
   wat_MSG_PEEK	         = $02;	{ peek at incoming message }
   wat_MSG_DONTROUTE	 = $04;	{ send without using routing tables }
   wat_MSG_EOR		 = $08;	{ data completes record }
   wat_MSG_TRUNC	 = $10;	{ data discarded before delivery }
   wat_MSG_CTRUNC	 = $20;	{ control data lost before delivery }
   wat_MSG_WAITALL	 = $40;	{ wait for full request or error }

   wat_res_OK            = $0000;
   wat_res_Fail          = $ffff;

   wat_err_OK            =  0;
   wat_err_NOENT	 = 2;	{ No such file or directory	}
   wat_err_NOTDIR        = 3;   { No path                      }
{   wat_err_MFILE	 = 4;}  { Too many open files		}
   wat_err_INTR		 = 4;	{ Interrupted system call }
   wat_err_ACCES	 = 5;	{ Permission denied		}
   wat_err_BADF	         = 6;	{ Bad file number		}
   wat_err_ARENA         = 7;	{ Arena trashed		}
   wat_err_NOMEM	 = 8;	{ Not enough core		}
   wat_err_SEGV          = 9;	{ invalid memory address	}
   wat_err_BADENV        = 10;	{ invalid environment		}
   wat_err_NODEV	 = 15;	{ No such device		}
   wat_err_INVAL	 = 19;	{ Invalid argument		}
   wat_err_2BIG	         = 20;	{ Arg list too long		}
   wat_err_NOEXEC        = 21;	{ Exec format error		}
   wat_err_XDEV	         = 22;	{ Cross-device link		}
   wat_err_DOM	         = 33;	{ Math argument		}
   wat_err_RANGE	 = 34;	{ Result too large		}
{   wat_err_EXIST	 = 35;}	{ File already exists		}
   wat_err_EXIST	 = 17;	{ File already exists		}

   wat_err_NFILE	 = 23;	{ File table overflow }
   wat_err_MFILE	 = 24;	{ Too many open files }
   wat_err_NOTTY	 = 25;	{ Not a typewriter }
   wat_err_TXTBSY	 = 26;	{ Text file busy }
   wat_err_FBIG		 = 27;	{ File too large }
   wat_err_NOSPC	 = 28;	{ No space left on device }
   wat_err_SPIPE	 = 29;	{ Illegal seek }
   wat_err_ROFS		 = 30;	{ Read-only file system }
   wat_err_MLINK	 = 31;	{ Too many links }
   wat_err_PIPE		 = 32;	{ Broken pipe }

{ non-blocking and interrupt i/o }
   wat_err_WOULDBLOCK	 = 35;	{ Operation would block }
   wat_err_INPROGRESS	 = 36;	{ Operation now in progress }
   wat_err_ALREADY	 = 37;	{ Operation already in progress }
{ ipc/network software }

	{ argument errors }
   wat_err_NOTSOCK	 = 38;	{ Socket operation on non-socket }
   wat_err_DESTADDRREQ	 = 39;	{ Destination address required }
   wat_err_MSGSIZE	 = 40;	{ Message too long }
   wat_err_PROTOTYPE	 = 41;	{ Protocol wrong type for socket }
   wat_err_NOPROTOOPT	 = 42;	{ Protocol not available }
   wat_err_PROTONOSUPPORT = 43;	{ Protocol not supported }
   wat_err_SOCKTNOSUPPORT = 44;	{ Socket type not supported }
   wat_err_OPNOTSUPP	 = 45;	{ Operation not supported on socket }
   wat_err_PFNOSUPPORT	 = 46;	{ Protocol family not supported }
   wat_err_AFNOSUPPORT	 = 47;	{ Address family not supported by protocol family }
   wat_err_ADDRINUSE	 = 48;	{ Address already in use }
   wat_err_ADDRNOTAVAIL	 = 49;	{ Can't assign requested address }

	{ operational errors }
   wat_err_NETDOWN	 = 50;	{ Network is down }
   wat_err_NETUNREACH	 = 51;	{ Network is unreachable }
   wat_err_NETRESET	 = 52;	{ Network dropped connection on reset }
   wat_err_CONNABORTED	 = 53;	{ Software caused connection abort }
   wat_err_CONNRESET	 = 54;	{ Connection reset by peer }
   wat_err_NOBUFS	 = 55;	{ No buffer space available }
   wat_err_ISCONN	 = 56;	{ Socket is already connected }
   wat_err_NOTCONN	 = 57;	{ Socket is not connected }
   wat_err_SHUTDOWN	 = 58;	{ Can't send after socket shutdown }
   wat_err_TOOMANYREFS	 = 59;	{ Too many references: can't splice }
   wat_err_TIMEDOUT	 = 60;	{ Connection timed out }
   wat_err_CONNREFUSED	 = 61;	{ Connection refused }

	{ }
   wat_err_LOOP		 = 62;	{ Too many levels of symbolic links }
   wat_err_NAMETOOLONG	 = 63;	{ File name too long }

{ should be rearranged }
   wat_err_HOSTDOWN	 = 64;	{ Host is down }
   wat_err_HOSTUNREACH	 = 65;	{ No route to host }
   wat_err_NOTEMPTY	 = 66;	{ Directory not empty }

{ quotas & mush }
   wat_err_PROCLIM	 = 67;	{ Too many processes }
   wat_err_USERS	 = 68;	{ Too many users }
   wat_err_DQUOT	 = 69;	{ Disc quota exceeded }

   wat_cmd_CheckLoad     = $ffcd;
   wat_cmd_DoIO          = $ffa0;
   wat_cmd_Socket        = $ff01;
   wat_cmd_Bind          = $ff02;
   wat_cmd_Connect       = $ff03;
   wat_cmd_Listen        = $ff04;
   wat_cmd_Accept        = $ff05;
   wat_cmd_RecvFrom      = $ff06;
   wat_cmd_Recv          = $ff07;
   wat_cmd_SendTo        = $ff08;
   wat_cmd_Send          = $ff09;
   wat_cmd_Select        = $ff0a;
   wat_cmd_IOCtl         = $ff0b;
   wat_cmd_Close         = $ff0c;
   wat_cmd_Shutdown      = $ff0d;
   wat_cmd_CheckStatus   = $ff0e;
   wat_cmd_GetSockName   = $ff0f;
   wat_cmd_GetPeerName   = $ff10;

   wat_firstsocket       = 0;
   wat_lastsocket        = WATFDSETSIZE-1;

type
   TWatSocket = integer;

   pinteger = ^integer;

   u_char  = byte;
   u_short = word;
   u_long  = Longint;

   WatSunB = packed record
     s_b1, s_b2, s_b3, s_b4: u_char;
   end;

   WatSunW = packed record
     s_w1, s_w2: u_short;
   end;

   TWATInAddr = packed record
     case integer of
       0: (S_un_b: WatSunB);
       1: (S_un_w: WatSunW);
       2: (S_addr: u_long);
   end;

   PWATSockAddr = ^TWATSockAddr;
   TWATSockAddr = packed record
    case Integer of
      0: (sin_family: u_short;
          sin_port: u_short;
          sin_addr: TWATInAddr;
          sin_zero: array[0..7] of Char);
      1: (sa_family: u_short;
          sa_data: array[0..13] of Char);
   end;

   PWatFDSet = ^TWatFDSet;
   TWatFDSet = array[0..(WatFDSETSIZE+7) div 8-1] of byte; { bit array }

   PWatTimeVal = ^TWatTimeVal;
   TWatTimeVal = packed record
     tv_sec: Longint;
     tv_usec: Longint;
   end;

function  WatInit: boolean;
procedure WatDoIO;
procedure WATInstallTimer;
procedure WATDeInstallTimer;

function wat_socket(Domain, SockType, Protocol: integer; var Socket: TWatSocket): boolean;
function wat_connect(Socket: TWatSocket; const Addr: PWatSockAddr; AddrSize: word): boolean;
function wat_listen(Socket: TWatSocket; BackLog: word): boolean;
function wat_bind(Socket: TWatSocket; Addr: PWatSockAddr; AddrSize: word): boolean;
function wat_accept(Socket: TWatSocket; Addr: PWatSockAddr; var AddrSize: word; var NewS: TWATSocket): boolean;
function wat_recvfrom(Socket: TWatSocket; var Buf; var DataSize: word; Flags: word; Addr: PWatSockAddr;
         var AddrSize: word): boolean;
function wat_recv(Socket: TWatSocket; var Buf; var DataSize: word; Flags: word): boolean;
function wat_sendto(Socket: TWatSocket; var Buf; var DataSize: word; Flags: word; const Addr: PWatSockAddr;
         AddrSize: word): boolean;
function wat_send(Socket: TWatSocket; var Buf; var DataSize: word; Flags: word): boolean;
function wat_getsockname(Socket: TWatSocket; Addr: PWatSockAddr; var AddrSize: word): boolean;
function wat_getpeername(Socket: TWatSocket; Addr: PWatSockAddr; var AddrSize: word): boolean;
function wat_closesocket(Socket: TWatSocket): boolean;
function wat_select(fdcount: word; readfd, writefd, exceptfd: PWatFDSET; timeout: PWatTimeVal; count: pinteger): boolean;
function wat_shutdown(Socket: TWatSocket; how: word): boolean;

function  wat_isvalidsocket(Socket: TWATSocket): boolean;
procedure wat_FD_ZERO(var FDS: TWATFDSET);
function  wat_FD_SET(Socket: TWATSocket; var FDS: TWATFDSET): boolean;
function  wat_FD_ISSET(Socket: TWATSocket; const FDS: TWATFDSET; var IsSet: boolean): boolean;
function  wat_FD_CLEAR(Socket: TWATSocket; var FDS: TWATFDSET): boolean;

const WatSocketError: word = wat_err_OK;

implementation

uses dos,pmode;

const
      WATOnTimer: boolean = false;
      WATInDoIO : boolean = false;
      WatInCall : boolean = false;
      OldInt1C  : procedure = nil;

function CallAPI(Cmd: word; var r: registers): boolean;
var OK: boolean;
    Err: word;
begin
  WATInCall:=true;
  r.ax:=Cmd;
  realintr(WatSockIntr,r);
  OK:=(r.cx=wat_res_OK);
  if OK then
    Err:=wat_err_OK
  else
    Err:=r.cx;
  WatSocketError:=Err;
  CallAPI:=OK;
  WATInCall:=false; 
end;

function WatInit: boolean;
var r: registers;
begin
  FillChar(r,sizeof(r),0);
  CallAPI(wat_cmd_CheckLoad,r);
  WatInit:=(r.cx=$1234);
end;

function wat_socket(Domain, SockType, Protocol: integer; var Socket: TWatSocket): boolean;
var r: registers;
    OK: boolean;
begin
  r.bx:=Domain; r.cx:=SockType; r.dx:=Protocol;
  OK:=CallAPI(wat_cmd_Socket,r);
  if OK=false then
    Socket:=wat_INVALID_SOCKET
  else
    Socket:=r.ax;
  wat_socket:=OK;
end;

function wat_connect(Socket: TWatSocket; const Addr: PWatSockAddr; AddrSize: word): boolean;
var r: registers;
    OK: boolean;
    AddrM: MemPtr;
begin
  GetDosMem(AddrM,AddrSize);
  AddrM.MoveDataTo(Addr^,AddrSize);
  r.bx:=Socket; r.dx:=AddrSize;
  r.ds:=AddrM.DosSeg; r.si:=AddrM.DosOfs;
  OK:=CallAPI(wat_cmd_Connect,r);
  FreeDosMem(AddrM);
  wat_connect:=OK;
end;

function wat_bind(Socket: TWatSocket; Addr: PWatSockAddr; AddrSize: word): boolean;
var r: registers;
    OK: boolean;
    AddrM: MemPtr;
begin
  GetDosMem(AddrM,AddrSize);
  AddrM.MoveDataTo(Addr^,AddrSize);
  r.bx:=Socket; r.dx:=AddrSize;
  r.ds:=AddrM.DosSeg; r.si:=AddrM.DosOfs;
  OK:=CallAPI(wat_cmd_Bind,r);
  AddrM.MoveDataFrom(AddrSize,Addr^);
  FreeDosMem(AddrM);
  wat_bind:=OK;
end;

function wat_listen(Socket: TWatSocket; BackLog: word): boolean;
var r: registers;
    OK: boolean;
begin
  r.bx:=Socket; r.cx:=BackLog;
  OK:=CallAPI(wat_cmd_Listen,r);
  wat_listen:=OK;
end;

type TAddrAndSize = packed record
        Addr     : {TWatSockAddr}array[0..15] of byte;
        AddrSize : word;
     end;

function wat_accept(Socket: TWatSocket; Addr: PWatSockAddr; var AddrSize: word; var NewS: TWATSocket): boolean;
var r: registers;
    OK: boolean;
    AS: TAddrAndSize;
    M: MemPtr;
begin
  FillChar(AS,SizeOf(AS),0);
  AS.AddrSize:=AddrSize;
  GetDosMem(M,SizeOf(AS));
  M.MoveDataTo(AS,SizeOf(AS));
  r.bx:=Socket;
  r.ds:=M.DosSeg; r.si:=M.DosOfs;
  OK:=CallAPI(wat_cmd_Accept,r);
  NewS:=r.ax;
  M.MoveDataFrom(SizeOf(AS),AS);
  AddrSize:=AS.AddrSize; if Assigned(addr) then Move(AS.Addr,Addr^,AddrSize);
  FreeDosMem(M);
  wat_accept:=OK;
end;

function wat_recvfrom(Socket: TWatSocket; var Buf; var DataSize: word; Flags: word; Addr: PWatSockAddr;
         var AddrSize: word): boolean;
var r: registers;
    OK: boolean;
    AS: TAddrAndSize;
    AddrM,DataM: MemPtr;
begin
  FillChar(AS,SizeOf(AS),0);
  Move(Addr^,AS.Addr,AddrSize);
  AS.AddrSize:=AddrSize;
  GetDosMem(AddrM,SizeOf(AS));
  AddrM.MoveDataTo(AS,SizeOf(AS));
  GetDosMem(DataM,DataSize);
  r.bx:=Socket;
  r.ds:=AddrM.DosSeg; r.si:=AddrM.DosOfs;
  r.es:=DataM.DosSeg; r.di:=DataM.DosOfs;
  r.cx:=DataSize; r.dx:=Flags;
  OK:=CallAPI(wat_cmd_RecvFrom,r);
  DataSize:=r.ax;
  AddrM.MoveDataFrom(SizeOf(AS),AS);
  DataM.MoveDataFrom(DataSize,Buf);
  AddrSize:=AS.AddrSize; Move(AS.Addr,Addr^,AddrSize);
  FreeDosMem(DataM);
  FreeDosMem(AddrM);
  wat_recvfrom:=OK;
end;

function wat_recv(Socket: TWatSocket; var Buf; var DataSize: word; Flags: word): boolean;
var r: registers;
    OK: boolean;
    DataM: MemPtr;
begin
  GetDosMem(DataM,DataSize);
  r.bx:=Socket;
  r.es:=DataM.DosSeg; r.di:=DataM.DosOfs;
  r.cx:=DataSize; r.dx:=Flags;
  OK:=CallAPI(wat_cmd_Recv,r);
  if OK then
    DataSize:=r.ax
  else
    DataSize:=0;
  DataM.MoveDataFrom(DataSize,Buf);
  FreeDosMem(DataM);
  wat_recv:=OK;
end;

function wat_sendto(Socket: TWatSocket; var Buf; var DataSize: word; Flags: word; const Addr: PWatSockAddr;
         AddrSize: word): boolean;
var r: registers;
    OK: boolean;
    AS: TAddrAndSize;
    AddrM,DataM: MemPtr;
begin
  FillChar(AS,SizeOf(AS),0);
  Move(Addr^,AS.Addr,AddrSize);
  AS.AddrSize:=AddrSize;
  GetDosMem(AddrM,SizeOf(AS));
  AddrM.MoveDataTo(AS,SizeOf(AS));
  GetDosMem(DataM,DataSize);
  DataM.MoveDataTo(Buf,DataSize);
  r.bx:=Socket;
  r.ds:=AddrM.DosSeg; r.si:=AddrM.DosOfs;
  r.es:=DataM.DosSeg; r.di:=DataM.DosOfs;
  r.cx:=DataSize; r.dx:=Flags;
  OK:=CallAPI(wat_cmd_SendTo,r);
  DataSize:=r.ax;
  AddrM.MoveDataFrom(SizeOf(AS),AS);
{  AddrSize:=AS.AddrSize; Move(AS.Addr,Addr^,AddrSize);}
  FreeDosMem(DataM);
  FreeDosMem(AddrM);
  wat_sendto:=OK;
end;

function wat_send(Socket: TWatSocket; var Buf; var DataSize: word; Flags: word): boolean;
var r: registers;
    OK: boolean;
    DataM: MemPtr;
begin
  GetDosMem(DataM,DataSize);
  r.bx:=Socket;
  r.es:=DataM.DosSeg; r.di:=DataM.DosOfs;
  r.cx:=DataSize; r.dx:=Flags;
  DataM.MoveDataTo(Buf,DataSize);
  OK:=CallAPI(wat_cmd_Send,r);
  DataSize:=r.ax;
  FreeDosMem(DataM);
  wat_send:=OK;
end;

function wat_getsockname(Socket: TWatSocket; Addr: PWatSockAddr; var AddrSize: word): boolean;
var r: registers;
    OK: boolean;
    AS: TAddrAndSize;
    M: MemPtr;
begin
  FillChar(AS,SizeOf(AS),0);
  AS.AddrSize:=AddrSize;
  GetDosMem(M,SizeOf(AS));
  M.MoveDataTo(AS,Sizeof(AS));
  r.bx:=Socket;
  r.ds:=M.DosSeg; r.si:=M.DosOfs;
  OK:=CallAPI(wat_cmd_GetSockName,r);
  M.MoveDataFrom(SizeOf(AS),AS);
  AddrSize:=AS.AddrSize; Move(AS.Addr,Addr^,AddrSize);
  FreeDosMem(M);
  wat_getsockname:=OK;
end;

function wat_getpeername(Socket: TWatSocket; Addr: PWatSockAddr; var AddrSize: word): boolean;
var r: registers;
    OK: boolean;
    AS: TAddrAndSize;
    M: MemPtr;
begin
  FillChar(AS,SizeOf(AS),0);
  AS.AddrSize:=AddrSize;
  GetDosMem(M,SizeOf(AS));
  M.MoveDataTo(AS,Sizeof(AS));
  r.bx:=Socket;
  r.ds:=M.DosSeg; r.si:=M.DosOfs;
  OK:=CallAPI(wat_cmd_GetPeerName,r);
  M.MoveDataFrom(SizeOf(AS),AS);
  AddrSize:=AS.AddrSize; Move(AS.Addr,Addr^,AddrSize);
  FreeDosMem(M);
  wat_getpeername:=OK;
end;

function wat_closesocket(Socket: TWatSocket): boolean;
var r: registers;
    OK: boolean;
begin
  r.bx:=Socket;
  OK:=CallAPI(wat_cmd_Close,r);
  wat_closesocket:=OK;
end;

function wat_select(fdcount: word; readfd, writefd, exceptfd: PWatFDSET; timeout: PWatTimeVal; count: pinteger): boolean;
type TWatSelectRCB = packed record
       preadfd, pwritefd, pexceptfd, ptimeout: pointer;
       readfd,writefd,exceptfd  : TWatFDSet;
       timeout: TWatTimeval;
     end;
var r: registers;
    OK: boolean;
    RCB: TWatSelectRCB;
    M: MemPtr;
    fdsize: word;
    BaseSeg,BaseOfs: word;
begin
  fdsize:=sizeof(TWatFDSET);
  GetDosMem(M,SizeOf(RCB));
  BaseSeg:=M.DosSeg; BaseOfs:=M.DosOfs;
  FillChar(RCB,SizeOf(RCB),0);
  if Assigned(readfd) then
    begin Move(readfd^,RCB.readfd,fdsize); RCB.preadfd:=MakePtr(BaseSeg,BaseOfs+ofs(RCB.readfd)-ofs(RCB)); end;
  if Assigned(writefd) then
    begin Move(writefd^,RCB.writefd,fdsize); RCB.pwritefd:=MakePtr(BaseSeg,BaseOfs+ofs(RCB.writefd)-ofs(RCB)); end;
  if Assigned(exceptfd) then
    begin Move(exceptfd^,RCB.exceptfd,fdsize); RCB.pexceptfd:=MakePtr(BaseSeg,BaseOfs+ofs(RCB.exceptfd)-ofs(RCB)); end;
  if Assigned(timeout) then
    begin Move(timeout^,RCB.timeout,sizeof(timeout^)); RCB.ptimeout:=MakePtr(BaseSeg,BaseOfs+ofs(RCB.timeout)-ofs(RCB)); end;
  M.MoveDataTo(RCB,Sizeof(RCB));
  r.bx:=fdcount;
  r.ds:=M.DosSeg; r.si:=M.DosOfs;
  OK:=CallAPI(wat_cmd_Select,r);
  M.MoveDataFrom(Sizeof(RCB),RCB);
  if Assigned(readfd) then Move(RCB.readfd,readfd^, fdsize);
  if Assigned(writefd) then Move(RCB.writefd,writefd^, fdsize);
  if Assigned(exceptfd) then Move(RCB.exceptfd,exceptfd^, fdsize);
  if Assigned(Count) then
   if OK then
     count^:=r.ax
   else
     count^:=-1;
  FreeDosMem(M);
  wat_select:=OK;
end;

function wat_shutdown(Socket: TWatSocket; how: word): boolean;
var r: registers;
    OK: boolean;
begin
  r.bx:=Socket; r.cx:=how;
  OK:=CallAPI(wat_cmd_Shutdown,r);
  wat_shutdown:=OK;
end;

procedure WatDoIO;
var r: registers;
begin
  CallAPI(wat_cmd_DoIO,r);
  inc(mem[segb800:0]);
end;

function wat_isvalidsocket(Socket: TWATSocket): boolean;
begin
  wat_isvalidsocket:=(wat_firstsocket<=Socket) and (Socket<=wat_lastsocket);
end;

function BytePos(Socket: TWATSocket): integer;
begin
  BytePos:=(Socket and $ff) shr 3; { div 8 }
end;

function BitMask(Socket: TWATSocket): byte;
begin
  BitMask:=1 shl ( Socket and $07 ); { mod 8 }
end;

procedure wat_FD_ZERO(var FDS: TWATFDSET);
begin
  FillChar(FDS,SizeOf(FDS),0);
end;

function  wat_FD_SET(Socket: TWATSocket; var FDS: TWATFDSET): boolean;
var OK: boolean;
begin
  OK:=wat_isvalidsocket(Socket);
  if OK then
    FDS[BytePos(Socket)]:=FDS[BytePos(Socket)] or BitMask(Socket);
  wat_FD_SET:=OK;
end;

function  wat_FD_ISSET(Socket: TWATSocket; const FDS: TWATFDSET; var IsSet: boolean): boolean;
var OK: boolean;
begin
  OK:=wat_isvalidsocket(Socket);
  IsSet:=false;
  if OK then
    IsSet:=(FDS[BytePos(Socket)] and BitMask(Socket))<>0;
  wat_FD_ISSET:=OK;
end;

function  wat_FD_CLEAR(Socket: TWATSocket; var FDS: TWATFDSET): boolean;
var OK: boolean;
begin
  OK:=wat_isvalidsocket(Socket);
  if OK then
    FDS[BytePos(Socket)]:=FDS[BytePos(Socket)] and not BitMask(Socket);
  wat_FD_CLEAR:=OK;
end;

{$ifndef FPC}
procedure WATInt1C; interrupt;
var I: integer;
begin
  if WATInCall=false then
    for I:=1 to 200 do
      WATDoIO;
  if @OldInt1C<>nil then
    begin
      asm pushf; end;
      OldInt1C;
    end;
end;

procedure WATInstallTimer;
begin
  if WATOnTimer then Exit;

  GetIntVec($1c,@OldInt1C);
  SetIntVec($1c,@WATInt1C);
  WATOnTimer:=true;
end;

procedure WATDeInstallTimer;
begin
  if WATOnTimer=false then Exit;

  SetIntVec($1c,@OldInt1C);
  WATOnTimer:=false;
end;
{$endif}

const OldExitProc : pointer = nil;

procedure MyExitProc; {$ifndef FPC}far;{$endif}
begin
  ExitProc:=OldExitProc;
{$ifndef FPC}
  if WATOnTimer then WATDeInstallTimer;
{$endif}
end;

BEGIN
  OldExitProc:=ExitProc;
  ExitProc:=@MyExitProc;
END.
