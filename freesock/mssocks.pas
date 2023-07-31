{
    $Id: mssocks.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Microsoft (HP) Lan Manager Sockets API routines

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

unit MSSocks;

interface

const
      MSSockDriverName : string[12] = 'TCPDRV$';
      MSSockSignature  = ord('S')+ord('O') shl 8;

      MSSockVersion    = $101;

      mss_cmd_accept             = $00;
      mss_cmd_bind               = $01;
      mss_cmd_closesocket        = $02;
      mss_cmd_connect            = $04;
      mss_cmd_gethostname        = $05;
      mss_cmd_getpeername        = $06;
      mss_cmd_getsockname        = $07;
      mss_cmd_listen             = $0a;
      mss_cmd_recv               = $0b;
      mss_cmd_select             = $0c;
      mss_cmd_send               = $0d;
      mss_cmd_socket             = $10;
      mss_cmd_status             = $12;

      { option flags for recv() and send() }
      mss_msg_peek               = $02;
      mss_msg_push               = $04;

      mss_fionbio                = $01;
      mss_fionread               = $02;

      mss_err_NOTSOCK            = 100;       { Socket operation on non-socket }
      mss_err_DESTADDRREQ        = 101;       { Destination address required }
      mss_err_MSGSIZE            = 102;       { Message too long }
      mss_err_PROTOTYPE          = 103;       { Protocol wrong type for socket }
      mss_err_NOPROTOOPT         = 104;       { Protocol not available }
      mss_err_PROTONOSUPPORT     = 105;       { Protocol not supported }
      mss_err_SOCKTNOSUPPORT     = 106;       { Socket type not supported }
      mss_err_OPNOTSUPP          = 107;       { Operation not supported on socket }
      mss_err_PFNOSUPPORT        = 108;       { Protocol family not supported }
      mss_err_AFNOSUPPORT        = 109;       { Address family not supported by protocol family }

      mss_err_ADDRINUSE          = 110;       { Address already in use }
      mss_err_ADDRNOTAVAIL       = 111;       { Can't assign requested address }
      mss_err_NETDOWN            = 112;       { Network is down }
      mss_err_NETUNREACH         = 113;       { Network is unreachable }
      mss_err_NETRESET           = 114;       { Network dropped connection or reset }
      mss_err_CONNABORTED        = 115;       { Software caused connection abort }
      mss_err_CONNRESET          = 116;       { Connection reset by peer }
      mss_err_NOBUFS             = 117;       { No buffer space available }
      mss_err_ISCONN             = 118;       { Socket is already connected }
      mss_err_NOTCONN            = 119;       { Socket is not connected }

      mss_err_SHUTDOWN           = 120;       { Can't send after socket shutdown }
      mss_err_TIMEDOUT           = 121;       { Connection timed out }
      mss_err_CONNREFUSED        = 122;       { Connection refused }
      mss_err_HOSTDOWN           = 123;       { Networking subsystem not started }
      mss_err_HOSTUNREACH        = 124;       { No route to host }
      mss_err_WOULDBLOCK         = 125;       { Operation would block }
      mss_err_INPROGRESS         = 126;       { Operation now in progress }
      mss_err_ALREADY            = 127;       { Operation already in progress }
      mss_err_BADVERSION         = 128;       { Library/driver version mismatch }
      mss_err_INVALSOCK          = 129;       { Invalid argument }

      mss_err_TOOMANYSOCK        = 130;       { Too many open sockets }
      mss_err_FAULTSOCK          = 131;       { Bad address in sockets call }

      mss_err_NODOSMEM           = 132;       { windows GlobalDosAlloc call failed }
      mss_err_BADRCFILE          = 133;       { strings file did not load properly }

      mss_invalid_socket         = -1;

      mss_firstsocket            = $100;
      mss_lastsocket             = $13f;

type
     TMSSocket = integer;

     PMSFDSET = ^TMSFDSET;
     TMSFDSET = packed array[0..7] of byte;
     { each bit means one socket. bitpos = (sockhandle-$100) }

     PMSTimeVal = ^TMSTimeVal;
     TMSTimeVal = packed record tv_sec, tv_usec: longint; end;

     TMSSockStatus = packed record
       Dunno       : array[1..3] of word;
       MaxSockets  : word;
       Dunno2      : word;
     end;

     TMSSocketRCB = packed record
       FuncCode     : byte;
       StatusPtr    : pointer;
       ResultPtr    : pointer;
       ProcessID    : word;
       case byte of
         mss_cmd_socket :
           ( SockFamily  : word;
             SockType    : word;
             SockProtocol: word; );
         mss_cmd_connect :
           ( ConnSocket  : TMSSocket;
             ConnAddr    : pointer;
             ConnAddrSize: integer; );
         mss_cmd_send,
         mss_cmd_recv :
           ( XferSocket  : TMSSocket;
             XferData    : pointer;
             XferSize    : word;
             XferOpts    : word);
         mss_cmd_closesocket :
           ( ClosSocket  : TMSSocket);
         mss_cmd_listen :
           ( ListSocket  : TMSSocket;
             ListBackLog : word);
         mss_cmd_accept :
           ( AccSocket   : TMSSocket;
             AccAddr     : pointer;
             AccAddrSize : pointer);
         mss_cmd_bind :
           ( BindSocket  : TMSSocket;
             BindAddr    : pointer;
             BindAddrSize: word);
         mss_cmd_getpeername,
         mss_cmd_getsockname :
           ( NameSocket  : TMSSocket;
             NameAddr    : pointer;
             NameAddrSize: pointer);
         mss_cmd_select :
           ( SelCount    : word;
             SelReadFD   : pointer;
             SelWriteFD  : pointer;
             SelExceptFD : pointer;
             SelTimeout  : pointer);
         mss_cmd_status :
           ( StatStatus  : TMSSockStatus);
         mss_cmd_gethostname :
           ( HostName    : pointer;
             HostNameSize: word);
         255 :
           ( Pad         : array[0..31] of byte;
             Status      : word;
             Result      : word; );
     end;

     TMSSockIOCTLBlock = packed record
       Func     : byte;
       Error    : byte;
       Signature: word;
       case byte of
         2 : (EntryPoint: pointer);
     end;

     pinteger = ^integer;

const MSSockError : integer = 0;

function  MSSockInit: boolean;
procedure MSSockDone;

function mss_socket(Family, SocketType, Protocol: word; var Socket: TMSSocket): boolean;
function mss_connect(Socket: TMSSocket; Address: pointer; AddrSize: longint): boolean;
function mss_closesocket(Socket: TMSSocket): boolean;
function mss_send(Socket: TMSSocket; var Data; var DataSize: word; Options: word): boolean;
function mss_recv(Socket: TMSSocket; var Data; var DataSize: word; Options: word): boolean;
function mss_listen(Socket: TMSSocket; BackLog: word): boolean;
function mss_bind(Socket: TMSSocket; Address: pointer; AddrSize: word): boolean;
function mss_accept(Socket: TMSSocket; Address: pointer; var AddrSize: word; var NewSocket: TMSSocket): boolean;
function mss_getsockname(Socket: TMSSocket; Address: pointer; var AddrSize: word): boolean;
function mss_getpeername(Socket: TMSSocket; Address: pointer; var AddrSize: word): boolean;
function mss_select(nfds: word; readfds, writefds, exceptfds: PMSFDSET; timeout: PMSTimeVal; Count: pinteger): boolean;
function mss_gethostname(name: PChar; size: word): boolean;

function mss_getstatus(var ST: TMSSockStatus): boolean;

procedure mss_FD_ZERO(var FDS: TMSFDSET);
function  mss_FD_SET(Socket: TMSSocket; var FDS: TMSFDSET): boolean;
function  mss_FD_ISSET(Socket: TMSSocket; const FDS: TMSFDSET; var IsSet: boolean): boolean;
function  mss_FD_CLEAR(Socket: TMSSocket; var FDS: TMSFDSET): boolean;

implementation

uses Dos,pmode,Strings;

const MSSockHandle     : integer = 0;
      MSSockEntryPoint : pointer = nil;
      MSSockProcessID  : word    = 0;

procedure InitRCB(var RCB: TMSSocketRCB);
begin
  FillChar(RCB,SizeOf(RCB),0);
end;

function callmssock(Cmd: byte; var RCB: TMSSocketRCB): boolean;
var M: MemPtr;
    r: registers;
begin
  if MSSockEntryPoint=nil then
    MSSockInit;
  if MSSockEntryPoint=nil then
    MSSockError:=-1
  else
    begin
      RCB.FuncCode:=Cmd;
      GetDosMem(M,SizeOf(RCB));
      RCB.StatusPtr:=MakePtr(M.DosSeg,M.DosOfs+ofs(RCB.Status)-ofs(RCB));
      RCB.ResultPtr:=MakePtr(M.DosSeg,M.DosOfs+ofs(RCB.Result)-ofs(RCB));
      RCB.ProcessID:=MSSockProcessID;
      M.MoveDataTo(RCB,SizeOf(RCB));
      r.es:=M.DosSeg; r.bx:=M.DosOfs;
      r.ax:=0;
      realcall(MSSockEntryPoint,r);
      M.MoveDataFrom(SizeOf(RCB),RCB);
      FreeDosMem(M);
      MSSockError:=RCB.Status;
    end;
  callmssock:=(MSSockError=0);
end;

function MSSockInit: boolean;
var r: registers;
    C: array[0..128] of char;
    OK: boolean;
    M: MemPtr;
    ReqBlock: TMSSockIOCTLBlock;
begin
  r.ax:=$6200;
  realintr($21,r);
  MSSockProcessID:=r.bx;

  StrPCopy(@C,MSSockDriverName);
  GetDosMem(M,SizeOf(C));
  M.MoveDataTo(C,SizeOf(C));
  r.ax:=$3d00;
  r.ds:=M.DosSeg; r.dx:=M.DosOfs;
  realintr($21,r);
  OK:=((r.flags and fCarry)=0) and (r.ax<>0);
  if OK then
  begin
    MSSockHandle:=r.ax;

    GetDosMem(M,SizeOf(ReqBlock));

    FillChar(ReqBlock,SizeOf(ReqBlock),0);
    ReqBlock.Func:=2; { bind }
    ReqBlock.Signature:=MSSockSignature;
    M.MoveDataTo(ReqBlock,SizeOf(ReqBlock));
    r.ax:=$4402; r.bx:=MSSockHandle;
    r.cx:=$0019;
    r.ds:=M.DosSeg; r.dx:=M.DosOfs;
    realintr($21,r);
    M.MoveDataFrom(SizeOf(ReqBlock),ReqBlock);
    OK:=((r.flags and fCarry)=0) and (ReqBlock.Error=0);

    if OK then
    begin
      MSSockEntryPoint:=ReqBlock.EntryPoint;

      FillChar(ReqBlock,SizeOf(ReqBlock),0);
      ReqBlock.Func:=3; { unbind }
      ReqBlock.Signature:=MSSockSignature;
      M.MoveDataTo(ReqBlock,SizeOf(ReqBlock));
      r.ax:=$4402; r.bx:=MSSockHandle;
      r.cx:=$0019;
      r.ds:=M.DosSeg; r.dx:=M.DosOfs;
      realintr($21,r);
      M.MoveDataFrom(SizeOf(ReqBlock),ReqBlock);
{      OK:=((r.flags and fCarry)=0) and (ReqBlock.Error=0);}
    end;

    FreeDosMem(M);

    OK:=OK and (MSSockEntryPoint<>nil);

    if OK=false then MSSockDone;
  end;
  MSSockInit:=OK;
end;

procedure MSSockDone;
var r: registers;
begin
  if MSSockHandle=0 then Exit;
  r.ax:=$3e00; r.bx:=MSSockHandle;
  realintr($21,r);
  MSSockHandle:=0; MSSockEntryPoint:=nil;
end;

function mss_socket(Family, SocketType, Protocol: word; var Socket: TMSSocket): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.SockFamily:=Family;
  RCB.SockType:=SocketType;
  RCB.SockProtocol:=Protocol;
  OK:=callmssock(mss_cmd_socket,RCB);
  OK:=OK and (RCB.Result>0);
  if OK then
    Socket:=RCB.Result
  else
    Socket:=mss_invalid_socket;
  mss_socket:=OK;
end;

function mss_connect(Socket: TMSSocket; Address: pointer; AddrSize: longint): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
    AddrM: MemPtr;
begin
  GetDosMem(AddrM,AddrSize);
  AddrM.MoveDataTo(Address^,AddrSize);
  InitRCB(RCB);
  RCB.ConnSocket:=Socket;
  RCB.ConnAddr:=AddrM.DosPtr;
  RCB.ConnAddrSize:=AddrSize;
  OK:=callmssock(mss_cmd_connect,RCB);
  OK:=OK and (RCB.Result=0);
  FreeDosMem(AddrM);
  mss_connect:=OK;
end;

function mss_closesocket(Socket: TMSSocket): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.ClosSocket:=Socket;
  OK:=callmssock(mss_cmd_closesocket,RCB);
  mss_closesocket:=OK;
end;

type TXferDir = (xSend,xRecv);

function mss_xfer(Cmd: byte; Dir: TXferDir; Socket: TMSSocket; var Data; var DataSize: word; Options: word): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
    DataM: MemPtr;
begin
  GetDosMem(DataM,DataSize);
  if Dir=xSend then
    DataM.MoveDataTo(Data,DataSize);
  InitRCB(RCB);
  RCB.XferSocket:=Socket;
  RCB.XferData:=DataM.DosPtr;
  RCB.XferSize:=DataSize;
  RCB.XferOpts:=Options;
  OK:=callmssock(Cmd,RCB);
  DataSize:=RCB.Result;
  if Dir=xRecv then
    DataM.MoveDataFrom(DataSize,Data);
  FreeDosMem(DataM);
  mss_xfer:=OK;
end;

function mss_send(Socket: TMSSocket; var Data; var DataSize: word; Options: word): boolean;
begin
  mss_send:=mss_xfer(mss_cmd_send,xSend,Socket,Data,DataSize,Options);
end;

function mss_recv(Socket: TMSSocket; var Data; var DataSize: word; Options: word): boolean;
begin
  mss_recv:=mss_xfer(mss_cmd_recv,xRecv,Socket,Data,DataSize,Options);
end;

function mss_listen(Socket: TMSSocket; BackLog: word): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.ListSocket:=Socket;
  RCB.ListBackLog:=BackLog;
  OK:=callmssock(mss_cmd_listen,RCB);
  mss_listen:=OK;
end;

function mss_bind(Socket: TMSSocket; Address: pointer; AddrSize: word): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
    AddrM: MemPtr;
begin
  GetDosMem(AddrM,AddrSize);
  AddrM.MoveDataTo(Address^,AddrSize);
  InitRCB(RCB);
  RCB.BindSocket:=Socket;
  RCB.BindAddr:=AddrM.DosPtr;
  RCB.BindAddrSize:=AddrSize;
  OK:=callmssock(mss_cmd_bind,RCB);
  OK:=OK and (RCB.Result=0);
  if OK then
    AddrM.MoveDataFrom(AddrSize, Address^);
  FreeDosMem(AddrM);
  mss_bind:=OK;
end;

function mss_accept(Socket: TMSSocket; Address: pointer; var AddrSize: word; var NewSocket: TMSSocket): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
    AddrM: MemPtr;
    AddrSizeM: MemPtr;
begin
  GetDosMem(AddrM,AddrSize); GetDosMem(AddrSizeM,16);
  AddrM.MoveDataTo(Address^,AddrSize); AddrSizeM.MoveDataTo(AddrSize,SizeOf(AddrSize));
  InitRCB(RCB);
  RCB.AccSocket:=Socket;
  RCB.AccAddr:=AddrM.DosPtr;
  RCB.AccAddrSize:=AddrSizeM.DosPtr;
  OK:=callmssock(mss_cmd_accept,RCB);
  OK:=OK and (RCB.Result<>mss_invalid_socket);
  if OK then
    begin
      AddrM.MoveDataFrom(AddrSize, Address^);
      AddrSizeM.MoveDataFrom(SizeOf(AddrSize),AddrSize);
      NewSocket:=RCB.Result;
    end
  else
    NewSocket:=mss_invalid_socket;
  FreeDosMem(AddrM); FreeDosMem(AddrSizeM);
  mss_accept:=OK;
end;

function mss_getsockname(Socket: TMSSocket; Address: pointer; var AddrSize: word): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
    AddrM: MemPtr;
    AddrSizeM: MemPtr;
begin
  GetDosMem(AddrM,AddrSize); GetDosMem(AddrSizeM,16);
  AddrM.MoveDataTo(Address^,AddrSize); AddrSizeM.MoveDataTo(AddrSize,SizeOf(AddrSize));
  InitRCB(RCB);
  RCB.NameSocket:=Socket;
  RCB.NameAddr:=AddrM.DosPtr;
  RCB.NameAddrSize:=AddrSizeM.DosPtr;
  OK:=callmssock(mss_cmd_getsockname,RCB);
  OK:=OK and (RCB.Result=0);
  if OK then
    begin
      AddrM.MoveDataFrom(AddrSize, Address^);
      AddrSizeM.MoveDataFrom(SizeOf(AddrSize),AddrSize);
    end;
  FreeDosMem(AddrM); FreeDosMem(AddrSizeM);
  mss_getsockname:=OK;
end;

function mss_getpeername(Socket: TMSSocket; Address: pointer; var AddrSize: word): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
    AddrM: MemPtr;
    AddrSizeM: MemPtr;
begin
  GetDosMem(AddrM,AddrSize); GetDosMem(AddrSizeM,16);
  AddrM.MoveDataTo(Address^,AddrSize); AddrSizeM.MoveDataTo(AddrSize,SizeOf(AddrSize));
  InitRCB(RCB);
  RCB.NameSocket:=Socket;
  RCB.NameAddr:=AddrM.DosPtr;
  RCB.NameAddrSize:=AddrSizeM.DosPtr;
  OK:=callmssock(mss_cmd_getpeername,RCB);
  OK:=OK and (RCB.Result=0);
  if OK then
    begin
      AddrM.MoveDataFrom(AddrSize, Address^);
      AddrSizeM.MoveDataFrom(SizeOf(AddrSize),AddrSize);
    end;
  FreeDosMem(AddrM); FreeDosMem(AddrSizeM);
  mss_getpeername:=OK;
end;

function mss_select(nfds: word; readfds, writefds, exceptfds: PMSFDSET; timeout: PMSTimeVal; Count: Pinteger): boolean;
procedure PutFD(Src: PMSFDSET; var M: MemPtr);
begin
  if Assigned(Src)=false then FillChar(M,SizeOf(M),0) else
    begin
      GetDosMem(M,SizeOf(Src^));
      M.MoveDataTo(Src^,SizeOf(Src^));
    end;
end;
procedure GetFD(var M: MemPtr; Dest: PMSFDSET);
begin
  if (M.Seg<>0) and Assigned(Dest) then
    begin
      M.MoveDataFrom(SizeOf(Dest^),Dest^);
      FreeDosMem(M);
    end;
end;
var RCB: TMSSocketRCB;
    OK: boolean;
    ReadM,WriteM,ExceptM,TimeM: MemPtr;
begin
  nfds:=64;
  InitRCB(RCB);
  RCB.SelCount:=nfds;
  PutFD(readfds,ReadM); RCB.SelReadFD:=ReadM.DosPtr;
  PutFD(writefds,WriteM); RCB.SelWriteFD:=WriteM.DosPtr;
  PutFD(exceptfds,ExceptM); RCB.SelExceptFD:=ExceptM.DosPtr;
  if Assigned(timeout) then
    begin
      GetDosMem(TimeM,Sizeof(timeout^));
      TimeM.MoveDataTo(timeout^,sizeof(timeout^));
      RCB.SelTimeout:=TimeM.DosPtr;
    end;
  OK:=callmssock(mss_cmd_select,RCB);
  GetFD(ReadM,readfds);
  GetFD(WriteM,writefds);
  GetFD(ExceptM,exceptfds);
  if Assigned(timeout) then
    FreeDosMem(TimeM);
  if assigned(count) then count^:=RCB.Result;
  mss_select:=OK;
end;

function mss_gethostname(name: PChar; size: word): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
    NameM: MemPtr;
begin
  GetDosMem(NameM,Size);
  InitRCB(RCB);
  RCB.HostName:=NameM.DosPtr;
  RCB.HostNameSize:=Size;
  OK:=callmssock(mss_cmd_gethostname,RCB);
  if OK then
    NameM.MoveDataFrom(size,name^);
  FreeDosMem(NameM);
  mss_gethostname:=OK;
end;

function mss_getstatus(var ST: TMSSockStatus): boolean;
var RCB: TMSSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  OK:=callmssock(mss_cmd_status,RCB);
  if OK then ST:=RCB.StatStatus;
  mss_getstatus:=OK;
end;

function mss_isvalidsocket(Socket: TMSSocket): boolean;
begin
  mss_isvalidsocket:=(mss_firstsocket<=Socket) and (Socket<=mss_lastsocket);
end;

function BytePos(Socket: TMSSocket): integer;
begin
  BytePos:=(Socket and $ff) shr 3; { div 8 }
end;

function BitMask(Socket: TMSSocket): byte;
begin
  BitMask:=1 shl ( (Socket and $ff) and $07 ); { mod 8 }
end;

procedure mss_FD_ZERO(var FDS: TMSFDSET);
begin
  FillChar(FDS,SizeOf(FDS),0);
end;

function  mss_FD_SET(Socket: TMSSocket; var FDS: TMSFDSET): boolean;
var OK: boolean;
begin
  OK:=mss_isvalidsocket(Socket);
  if OK then
    FDS[BytePos(Socket)]:=FDS[BytePos(Socket)] or BitMask(Socket);
  mss_FD_SET:=OK;
end;

function  mss_FD_ISSET(Socket: TMSSocket; const FDS: TMSFDSET; var IsSet: boolean): boolean;
var OK: boolean;
begin
  OK:=mss_isvalidsocket(Socket);
  IsSet:=false;
  if OK then
    IsSet:=(FDS[BytePos(Socket)] and BitMask(Socket))<>0;
  mss_FD_ISSET:=OK;
end;

function  mss_FD_CLEAR(Socket: TMSSocket; var FDS: TMSFDSET): boolean;
var OK: boolean;
begin
  OK:=mss_isvalidsocket(Socket);
  if OK then
    FDS[BytePos(Socket)]:=FDS[BytePos(Socket)] and not BitMask(Socket);
  mss_FD_CLEAR:=OK;
end;

END.
{
  $Log: mssocks.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
