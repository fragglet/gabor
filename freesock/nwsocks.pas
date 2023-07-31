{
    $Id: nwsocks.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Novell LAN Workplace TCP/IP API routines

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
unit NWSocks;

interface

const
      nws_prot_IP                =  0;
      nws_prot_ICMP              =  1;
      nws_prot_TCP               =  6;
      nws_prot_UDP               = 17;

      nws_cmd_accept             = $01;
      nws_cmd_bind               = $02;
      nws_cmd_close              = $03;
      nws_cmd_connect            = $04;
      nws_cmd_getmyip            = $05;
      nws_cmd_getmymacaddr       = $06;
      nws_cmd_getpeername        = $07;
      nws_cmd_getsockname        = $08;
      nws_cmd_getsockopt         = $09;
      nws_cmd_getsubnetmask      = $0a;
      nws_cmd_ioctl              = $0b;
      nws_cmd_listen             = $0c;
      nws_cmd_select             = $0d;
      nws_cmd_setmyip            = $0e; { obsolete }
      nws_cmd_setsockopt         = $0f;
      nws_cmd_shutdown           = $10;
      nws_cmd_socket             = $11;
      nws_cmd_recv               = $12;
      nws_cmd_recvfrom           = $13;
      nws_cmd_send               = $14;
      nws_cmd_sendto             = $15;
      nws_cmd_getbootp           = $16;
      nws_cmd_getsnmpinfo        = $17;
      nws_cmd_getpathinfo        = $18;
      nws_cmd_getifn             = $19;
      nws_cmd_setipinfo          = $1a;
      nws_cmd_getipinfo          = $1b;
      nws_cmd_setdnsinfo         = $1c;
      nws_cmd_getdnsinfo         = $1d;
      nws_cmd_setroutes          = $1e;
      nws_cmd_getroutes          = $1f;
      nws_cmd_removeroutes       = $20;
      nws_cmd_setarpe            = $21;
      nws_cmd_getarpe            = $22;
      nws_cmd_removearpe         = $23;
      nws_cmd_CallEventHandler   = $80; { flag! }

      nws_flg_RequestInProgress  = $01;
      nws_flg_Posted             = $02;
      nws_flg_Windows            = $04;
      nws_flg_ProtBuf            = $08;
      nws_flg_AbortRCB           = $10;
      nws_flg_CallIdle           = $20; { calls INT21/AX=0B00h while blocking }

      nws_so_ReuseAddr           = $0004;
      nws_so_KeepAlive           = $0008;
      nws_so_Linger              = $0080;

      nws_err_OK                     = $00;
      nws_err_WouldBlock1            = $04;
      nws_err_InvalidSocket          = $09;
      nws_err_WouldBlock             = $23;
      nws_err_OperationInProgress    = $24;
      nws_err_AlreadyInProgress      = $25;
      nws_err_NotASocket             = $26;
      nws_err_DestinationRequired    = $27;
      nws_err_MessageTooLong         = $28;
      nws_err_WrongProtocolType      = $29;
      nws_err_ProtocolUnavailable    = $2a;
      nws_err_ProtocolNotSupported   = $2b;
      nws_err_SocketTypeNotSupported = $2c;
      nws_err_OpNotSupportedOnSocket = $2d;
      nws_err_ProtFamilyNotSupported = $2e;
      nws_err_AddrFamilyNotSuppByProt= $2f;
      nws_err_AddressAlreadyInUse    = $30;
      nws_err_UnableToAssignReqAddr  = $31;
      nws_err_NetworkIsDown          = $32;
      nws_err_NetworkUnreachable     = $33;
      nws_err_NetworkDroppedConnection= $34;
      nws_err_SoftwareCausedConnAbort= $35;
      nws_err_ConnectionResetByPeer  = $36;
      nws_err_NoBufferSpace          = $37;
      nws_err_SocketAlreadyConnected = $38;
      nws_err_SocketNotConnected     = $39;
      nws_err_SocketInShutdown       = $3a;
      nws_err_TooManyReferences      = $3b;
      nws_err_ConnectionTimedOut     = $3c;
      nws_err_ConnectionRefused      = $3d;
      nws_err_TooManyLevelsOfLink    = $3e;
      nws_err_FileNameTooLong        = $3f;
      nws_err_HostIsDown             = $40;
      nws_err_HostUnreachable        = $41;
      nws_err_ProtocolStackNotInstalled= $42;
      nws_err_AsynchOpNotSupported   = $43;
      nws_err_SynchOpNotSupported    = $44;
      nws_err_NoRCBAvailable         = $45;
      nws_err_Blocking               = $ff; { call has not yet returned }

type
     TNWSocket = byte;

     TNWSockAddr = packed record
       Port : word;
       IP   : longint;
     end;

     TNWSocketBitmap = packed array[0..15] of byte;

     TNWBOOTPDataBlock = packed array[1..64] of byte;

     TNWXmitBuf = packed record
       Data     : pointer;
       DataSize : word;
     end;

     TNWMacAddr = packed array[1..6] of byte;

     PNWSocketRCB = ^TNWSocketRCB;
     TNWSocketRCB = packed record
       NextRCB      : PNWSocketRCB;
       PrevRCB      : PNWSocketRCB;
       EventHandler : pointer;
       Flags        : byte;
       Filler       : packed array[1..7] of byte;
       Completition : byte;
       FuncCode     : byte;
       Socket       : byte;
       Error        : byte;
       case byte of
         nws_cmd_accept,
         nws_cmd_bind,
         nws_cmd_connect,
         nws_cmd_getmyip,
         nws_cmd_getpeername,
         nws_cmd_getsockname:
           (SockAddr    : TNWSockAddr);
         nws_cmd_close :
           ();
         nws_cmd_getmymacaddr:
           (MacAddr     : TNWMacAddr);
         nws_cmd_getbootp:
           (BOOTPData   : TNWBOOTPDataBlock);
         nws_cmd_getpathinfo:
           (PathKey     : packed array[1..8] of char;
            Path        : packed array[1..128] of byte;
            PathLen     : word);
         nws_cmd_getsockopt,
         nws_cmd_setsockopt :
           (SockOption      : word;
            SockOptionValue : word;
            SockLinger      : word);
         nws_cmd_getsubnetmask :
           (SubNetUnknown   : byte;
            SubnetMask      : longint);
         nws_cmd_ioctl :
           (IOArgument      : longint;
            IOCtlFunc       : word);
         nws_cmd_listen :
           (ListenMax       : word);
         nws_cmd_select :
           (SelSockCount    : word;
            SelReadFDS	    : TNWSocketBitmap;
            SelWriteFDS	    : TNWSocketBitmap;
            SelExceptFDS    : TNWSocketBitmap;
            SelTimeOut      : longint; { in clock ticks (1/18.2 s) }
           );
         nws_cmd_shutdown :
           (ShutdownType    : word);
         nws_cmd_socket :
           (SocketProtocol  : word);
         nws_cmd_recv,
         nws_cmd_recvfrom:
           (RecvFlags       : word;
            Source          : TNWSockAddr;
            RecvSize        : word;
            RecvFragCount   : word;
            RecvBufs        : packed array[1..8] of TNWXmitBuf);
         nws_cmd_send,
         nws_cmd_sendto :
           (SendFlags       : word;
            Destination     : TNWSockAddr;
            SendSize        : word;
            SendFragCount   : word;
            SendBufs        : packed array[1..8] of TNWXmitBuf);
     end;

function NWSockInit: boolean;
function nws_getmyipaddr(var IP: longint): boolean;
function nws_getmymacaddr(var MACAddr: TNWMACAddr): boolean;
function nws_getsubnetmask(var SubNetMask: longint): boolean;
function nws_socket(Protocol: word; var Socket: TNWSocket): boolean;
function nws_connect(Socket: TNWSocket; DestIP: longint; DestPort: word): boolean;
function nws_accept(Socket: TNWSocket; var RemoteAddr: TNWSockAddr; var NewSocket: TNWSocket): boolean;
function nws_bind(Socket: TNWSocket; const RemoteAddr: TNWSockAddr): boolean;
function nws_listen(Socket: TNWSocket; MaxConnections: word): boolean;
function nws_getsockname(Socket: TNWSocket; var LocalAddr: TNWSockAddr): boolean;
function nws_getpeername(Socket: TNWSocket; var RemoteAddr: TNWSockAddr): boolean;
function nws_getsockopt(Socket: TNWSocket; OptName: word; var OptValue: word; var Linger: word): boolean;
function nws_setsockopt(Socket: TNWSocket; OptName, OptValue: word; Linger: word): boolean;
function nws_select(var ReadFDS, WriteFDS, ExceptFDS: TNWSocketBitmap; TimeOut: longint; var Count: longint): boolean;
function nws_send(Socket: TNWSocket; const Data; const DataSize: word; const Flags: word): boolean;
function nws_sendto(Socket: TNWSocket; const DestAddr: TNWSockAddr; const Data; DataSize: word; Flags: word): boolean;
function nws_recv(Socket: TNWSocket; var Data; var DataSize: word; Flags: word): boolean;
function nws_recvfrom(Socket: TNWSocket; var SrcAddr: TNWSockAddr; var Data; var DataSize: word; Flags: word): boolean;
function nws_close(Socket: TNWSocket): boolean;
function nws_shutdown(Socket: TNWSocket; ShutDownType: word): boolean;

const NWSockVersion : word    = 0;
      NWSockError   : integer = nws_err_OK;

implementation

uses dos,pmode;

const NWSockEntryPoint : pointer = nil; { call it with ES:SI -> TSocketECB }

function SwapW(W: word): word;
begin
  SwapW:=Swap(W);
end;

function SwapL(L: longint): longint;
type TLongint = record LoW,HiW: word; end;
var T: TLongint;
    TW: word;
begin
  T:=Tlongint(L);
  TW:=T.LoW; T.LoW:=SwapW(T.HiW); T.HiW:=SwapW(TW);
  SwapL:=longint(T);
end;

function I2MW(W: word): word; begin I2MW:=SwapW(W); end;
function M2IW(W: word): word; begin M2IW:=SwapW(W); end;
function I2ML(L: longint): longint; begin I2ML:=SwapL(L); end;
function M2IL(L: longint): longint; begin M2IL:=SwapL(L); end;

procedure SwapAddr(const Src: TNWSockAddr; var Dest: TNWSockAddr);
begin
  Dest.Port:=SwapW(Src.Port);
  Dest.IP:=SwapL(Src.IP);
end;

procedure I2MAddr(const Src: TNWSockAddr; var Dest: TNWSockAddr); begin SwapAddr(Src,Dest); end;
procedure M2IAddr(const Src: TNWSockAddr; var Dest: TNWSockAddr); begin SwapAddr(Src,Dest); end;


function ExecRCB(Cmd: byte; var RCB: TNWSocketRCB): boolean;
var r: registers;
    M: MemPtr;
    OK: boolean;
begin
  if NWSockEntryPoint=nil then
    NWSockInit;

  OK:=NwSockEntryPoint<>nil;

  if OK then
  begin
    FillChar(r,SizeOf(r),0);
    RCB.FuncCode:=Cmd;

    GetDosMem(M,SizeOf(RCB));

    M.MoveDataTo(RCB,SizeOf(RCB));

    r.es:=M.DosSeg; r.si:=M.DosOfs; r.di:=M.DosOfs;
    realcall(NWSockEntryPoint,r);

    M.MoveDataFrom(SizeOf(RCB),RCB);

    FreeDosMem(M);

    NWSockError:=RCB.Error;
    OK:=OK and (NWSockError=nws_err_OK);
  end;
  ExecRCB:=OK;
end;

function NWSockInit: boolean;
var r: registers;
    OK: boolean;
begin
  r.ax:=$7a40;
  realintr($2f,r);
  OK:=(r.ax=$7aff);
  if OK then
    begin
      if r.cx=0 then r.cx:=$0100;
      NWSockVersion:=r.cx;
      NWSockEntryPoint:=MakePtr(r.es,r.di);
    end;
  NWSockInit:=OK;
end;

procedure InitRCB(var RCB: TNWSocketRCB);
begin
  FillChar(RCB,SizeOf(RCB),0);
end;

function nws_getmyipaddr(var IP: longint): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
    Addr: TNWSockAddr;
begin
  InitRCB(RCB);
  OK:=ExecRCB(nws_cmd_getmyip,RCB);
  if OK then
    begin
      M2IAddr(RCB.SockAddr,Addr);
(*      with Addr do
        begin
{          Port:=M2IW(Port);
          IP:=M2IL(IP);}
        end;*)
      IP:=Addr.IP;
    end;
  nws_getmyipaddr:=OK;
end;

function nws_socket(Protocol: word; var Socket: TNWSocket): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.SocketProtocol:=Protocol;
  OK:=ExecRCB(nws_cmd_socket,RCB);
  if OK then Socket:=RCB.Socket;
  nws_socket:=OK;
end;

function nws_connect(Socket: TNWSocket; DestIP: longint; DestPort: word): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  with RCB.SockAddr do
    begin
      Port:=I2MW(DestPort);
      IP:=I2ML(DestIP);
    end;
  OK:=ExecRCB(nws_cmd_connect,RCB);
  nws_connect:=OK;
end;

function nws_accept(Socket: TNWSocket; var RemoteAddr: TNWSockAddr; var NewSocket: TNWSocket): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  NewSocket:=0;
  InitRCB(RCB);
  RCB.Socket:=Socket;
  OK:=ExecRCB(nws_cmd_accept,RCB);
  if OK then
    begin
      M2IAddr(RCB.SockAddr,RemoteAddr);
      NewSocket:=RCB.Socket;
    end;
  nws_accept:=OK;
end;

function nws_bind(Socket: TNWSocket; const RemoteAddr: TNWSockAddr): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  I2MAddr(RemoteAddr,RCB.SockAddr);
  OK:=ExecRCB(nws_cmd_bind,RCB);
  nws_bind:=OK;
end;

function nws_listen(Socket: TNWSocket; MaxConnections: word): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  RCB.ListenMax:=MaxConnections;
  OK:=ExecRCB(nws_cmd_listen,RCB);
  nws_listen:=OK;
end;

function nws_getsockname(Socket: TNWSocket; var LocalAddr: TNWSockAddr): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  OK:=ExecRCB(nws_cmd_getsockname,RCB);
  if OK then M2IAddr(RCB.SockAddr,LocalAddr);
  nws_getsockname:=OK;
end;

function nws_getpeername(Socket: TNWSocket; var RemoteAddr: TNWSockAddr): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  OK:=ExecRCB(nws_cmd_getpeername,RCB);
  if OK then M2IAddr(RCB.SockAddr,RemoteAddr);
  nws_getpeername:=OK;
end;

function nws_getsockopt(Socket: TNWSocket; OptName: word; var OptValue: word; var Linger: word): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  OK:=ExecRCB(nws_cmd_getsockopt,RCB);
  if OK then begin OptValue:=RCB.SockOptionValue; Linger:=RCB.SockLinger; end;
  nws_getsockopt:=OK;
end;

function nws_setsockopt(Socket: TNWSocket; OptName, OptValue: word; Linger: word): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  RCB.SockOptionValue:=OptValue;
  RCB.SockLinger:=Linger;
  OK:=ExecRCB(nws_cmd_setsockopt,RCB);
  nws_setsockopt:=OK;
end;

function nws_select(var ReadFDS, WriteFDS, ExceptFDS: TNWSocketBitmap; TimeOut: longint; var Count: longint): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.SelSockCount:=(High(ReadFDS)-Low(ReadFDS)+1)*8;
  RCB.SelTimeOut:=TimeOut;
  RCB.SelReadFDS:=ReadFDS;
  RCB.SelWriteFDS:=WriteFDS;
  RCB.SelExceptFDS:=ExceptFDS;
  OK:=ExecRCB(nws_cmd_select,RCB);
  ReadFDS:=RCB.SelReadFDS;
  WriteFDS:=RCB.SelWriteFDS;
  ExceptFDS:=RCB.SelExceptFDS;
  Count:=RCB.SelSockCount;
  nws_select:=OK;
end;


function nws_dosend(Socket: TNWSocket; const Addr: TNWSockAddr; Cmd: word; const Data; DataSize: word; Flags: word): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
    M: MemPtr;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  RCB.SendFlags:=Flags;
  RCB.SendFragCount:=1;
  RCB.SendSize:=DataSize;
  RCB.Destination:=Addr;

  GetDosMem(M,DataSize);
  M.MoveDataTo(Data,DataSize);

  RCB.SendBufs[1].Data:=M.DosPtr;
  RCB.SendBufs[1].DataSize:=DataSize;

  OK:=ExecRCB(Cmd,RCB);

  FreeDosMem(M);

  nws_dosend:=OK;
end;

function nws_dorecvfrom(Socket: TNWSocket; var Addr: TNWSockAddr; Cmd: word;
           var Data; var DataSize: word; Flags: word): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
    M: MemPtr;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  RCB.RecvFlags:=Flags;
  RCB.RecvFragCount:=1;
  RCB.RecvSize:=DataSize;
  I2MAddr(Addr,RCB.Source);

  GetDosMem(M,DataSize);

  RCB.RecvBufs[1].Data:=M.DosPtr;
  RCB.RecvBufs[1].DataSize:=DataSize;

  OK:=ExecRCB(Cmd,RCB);
  M.MoveDataFrom(DataSize,Data);

  FreeDosMem(M);
  M2IAddr(RCB.Source,Addr);
  DataSize:=RCB.RecvSize;

  nws_dorecvfrom:=OK;
end;

function nws_send(Socket: TNWSocket; const Data; const DataSize: word; const Flags: word): boolean;
var Addr: TNWSockAddr;
begin
  FillChar(Addr,SizeOf(Addr),0);
  nws_send:=nws_dosend(Socket,Addr,nws_cmd_send,Data,DataSize,Flags);
end;

function nws_sendto(Socket: TNWSocket; const DestAddr: TNWSockAddr; const Data; DataSize: word; Flags: word): boolean;
begin
  nws_sendto:=nws_dosend(Socket,DestAddr,nws_cmd_sendto,Data,DataSize,Flags);
end;

function nws_recv(Socket: TNWSocket; var Data; var DataSize: word; Flags: word): boolean;
var Addr: TNWSockAddr;
begin
  FillChar(Addr,SizeOf(Addr),0);
  nws_recv:=nws_dorecvfrom(Socket,Addr,nws_cmd_recv,Data,DataSize,Flags);
end;

function nws_recvfrom(Socket: TNWSocket; var SrcAddr: TNWSockAddr; var Data; var DataSize: word; Flags: word): boolean;
begin
  nws_recvfrom:=nws_dorecvfrom(Socket,SrcAddr,nws_cmd_recvfrom,Data,DataSize,Flags);
end;

function nws_close(Socket: TNWSocket): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  OK:=ExecRCB(nws_cmd_close,RCB);
  nws_close:=OK;
end;

function nws_getmymacaddr(var MACAddr: TNWMACAddr): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  OK:=ExecRCB(nws_cmd_getmymacaddr,RCB);
  if OK then MACAddr:=RCB.macaddr;
  nws_getmymacaddr:=OK;
end;

function nws_getsubnetmask(var SubNetMask: longint): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  OK:=ExecRCB(nws_cmd_getsubnetmask,RCB);
  if OK then SubNetMask:=M2IL(RCB.SubNetMask);
  nws_getsubnetmask:=OK;
end;

function nws_shutdown(Socket: TNWSocket; ShutDownType: word): boolean;
var RCB: TNWSocketRCB;
    OK: boolean;
begin
  InitRCB(RCB);
  RCB.Socket:=Socket;
  RCB.ShutdownType:=ShutDownType;
  OK:=ExecRCB(nws_cmd_shutdown,RCB);
  nws_shutdown:=OK;
end;

END.
{
  $Log: nwsocks.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
