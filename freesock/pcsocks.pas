{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    PC/TCP driver interface        

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
unit PCSocks;

interface

const
     PCTCPFDSETSIZE = 32;

     pctcp_cmd_netconfig        =  1;
     pctcp_cmd_getkernelinfo    =  2;
     pctcp_cmd_getaddr          =  5;
     pctcp_cmd_netinfo          =  6;
     pctcp_cmd_globalize        =  7;
     pctcp_cmd_release          =  8;
     pctcp_cmd_releaseall       =  9;
     pctcp_cmd_oldsend          = 10;
     pctcp_cmd_oldsendto        = 11;
     pctcp_cmd_netstat          = 12;
     pctcp_cmd_checkdesc        = 13;
     pctcp_cmd_select           = 14;
     pctcp_cmd_netversion       = 15;
     pctcp_cmd_netshutdown      = 16;
     pctcp_cmd_disableasync     = 17;
     pctcp_cmd_enableasync      = 18;
     pctcp_cmd_connect          = 19;
     pctcp_cmd_oldrecv          = 20;
     pctcp_cmd_oldrecvfrom      = 21;
     pctcp_cmd_peername         = 22;
     pctcp_cmd_reconfig         = 23;
     pctcp_cmd_close            = 24;
     pctcp_cmd_abort            = 25;
     pctcp_cmd_write            = 26;
     pctcp_cmd_read             = 27;
     pctcp_cmd_writeto          = 28;
     pctcp_cmd_readfrom         = 29;
     pctcp_cmd_flush            = 30;
     pctcp_cmd_setasynchandler  = 31;
     pctcp_cmd_setoption        = 32;
     pctcp_cmd_getoption        = 33;
     pctcp_cmd_getdesc          = 34;
     pctcp_cmd_listen           = 35;
     pctcp_cmd_abortall         = 36;
     pctcp_cmd_gethost          = 37;
     pctcp_cmd_gethostlocal     = 38;
     pctcp_cmd_gethostdns       = 39;
     pctcp_cmd_swap             = 40;
     pctcp_cmd_getglobdesc      = 41;
     pctcp_cmd_getconfig        = 42;
     pctcp_cmd_netalarm         = 43;
     pctcp_cmd_ping             = 48;
     pctcp_cmd_netaddroute      = 49;
     pctcp_cmd_netdelroute      = 50;
     pctcp_cmd_netdumproute     = 51;

     pctcp_cmd_parseaddr        = 80;
     pctcp_cmd_resolvebyhosts   = 81;
     pctcp_cmd_resolvebydns     = 82;
     pctcp_cmd_resolvebyien116  = 83;
     pctcp_cmd_resolvename      = 84;

     pctcp_prot_RAW             = 1;
     pctcp_prot_RawIP           = 2;
     pctcp_prot_UDP             = 3;
     pctcp_prot_TCP             = 4;
     pctcp_prot_RawICMP         = 5;

     pctcp_opt_asynchstate      =  1;
     pctcp_opt_timeout          =  2;
     pctcp_opt_cookie           =  3;
     pctcp_opt_windowsize       =  4; { or buffer count for UDP }
     pctcp_opt_keepalive        =  6;
     pctcp_opt_ipprecedence     =  9;
     pctcp_opt_iptos            = 10;
     pctcp_opt_privilegedport   = 11;
     pctcp_opt_dontpush         = 12;

     pctcp_evt_alarm            =  0;
     pctcp_evt_open             =  1;
     pctcp_evt_receive          =  2;
     pctcp_evt_transmit         =  3;
     pctcp_evt_transmitflush    =  4;
     pctcp_evt_remoteclose      =  5;
     pctcp_evt_close            =  6;
     pctcp_evt_error            =  7;

     pctcp_read_prefetch        = $02; { do not remove - just copy }
     pctcp_read_empty           = $04; { do not copy - just remove }
     pctcp_read_donttruncate    = $20; { fail if datagram too large }
     pctcp_read_donotblock      = $30; { return immediately if no date available }

     pctcp_send_urgent          = $01;
     pctcp_send_attemptrerouting= $08;
     pctcp_send_sendwithpush    = $10;
     pctcp_send_donttruncate    = $20;
     pctcp_send_donotblock      = $30;
     pctcp_send_broadcastpacket = $40;

     pctcp_invalid_socket       = $ffff;

     pctcp_err_OK               =  0;
     pctcp_err_INUSE            =  1; { protocol or socket already in use }
     pctcp_err_MSDOS            =  2; { a DOS-error occoured while processing }
     pctcp_err_NOMEM            =  3; { out of memory }
     pctcp_err_NOTNETCONN       =  4; { not a network descriptor }
     pctcp_err_ILLEGALOP        =  5; { invalid op. on given kind of descriptor }
     pctcp_err_BADPKT           =  6; { illegal or corrupted packet }
     pctcp_err_NOHOST           =  7; { no host bound to specified connection }
     pctcp_err_CANTOPEN         =  8; { unable to open file }
     pctcp_err_NETUNREACH       =  9; { network is unreachable }
     pctcp_err_HOSTUNREACH      = 10; { host is unreachable }
     pctcp_err_PROTUNREACH      = 11; { protocol in unreachable }
     pctcp_err_PORTUNREACH      = 12; { port is unreachable }
     pctcp_err_TIMEOUT          = 13; { operation timed out }
     pctcp_err_HOSTUNKNOWN      = 14; { unable to resolve host name }
     pctcp_err_NOSERVERS        = 15; { no name server configured }
     pctcp_err_SERVERERR        = 16; { bad reply from name server }
     pctcp_err_BADFORMAT        = 17; { ivalid IP address }
     pctcp_err_BADARG           = 18; { invalid argument }
     pctcp_err_EOF              = 19; { connection terminated by remote host }
     pctcp_err_RESET            = 20; { connection has been reset }
     pctcp_err_WOULDBLOCK       = 21; { call to recv() when no data was available }
     pctcp_err_UNBOUND          = 22; { insuccifient resources to complete op }
     pctcp_err_NODESC           = 23; { could not allocate network descriptor }
     pctcp_err_BADSYSCALL       = 24; { invalid/unsupported kernel call }
     pctcp_err_CANTBROADCAST    = 25; { unable to broadcast }
     pctcp_err_NOTESTAB         = 26; { illegal operation for unconnected socket }
     pctcp_err_KernelBusy       = 27; { kernel busy, try again later }
     pctcp_err_ICMPMESG         = 28; { an ICMP message has been received (not on streams) }
     pctcp_err_TERMINATING      = 29; { a fatal internal error occoured }
     pctcp_err_TAGLOCKED        = 30; { not allowed to set this flag }
     pctcp_err_BADINTERFACE     = 31; { non-existent interface specified }
     pctcp_err_BADCONFIG        = 32; { can't run kernel because of bad config }
     pctcp_err_EMM              = 33; { expanded memory error }
     pctcp_err_CANTSHUTDOWN     = 34; { can't unload kernel (multitasker running) }
     pctcp_err_PARKEDIN         = 35; { unable to unhook dos interrupt }
     pctcp_err_NOQIOS           = 36; { run out of resources, try again later }
     pctcp_err_WOULDTRUNCATE    = 37; { datagram was too large, but "donttruncate" was set }

     pctcp_firstsocket          = 0;
     pctcp_lastsocket           = PCTCPFDSETSIZE-1;

type
     TPCTCPSocket = word;

     PPCTCPAddr = ^TPCTCPAddr;
     TPCTCPAddr = packed record
       IP         : longint; { in network order }
       RemotePort : word;    { " }
       LocalPort  : word;    { " }
       Protocol   : byte;    { " }
     end;

     TPCTCPFDSET = array[0..(PCTCPFDSETSIZE+7) div 8-1] of byte;
     PPCTCPFDSET = ^TPCTCPFDSET;

     TPCTCPConfigInfo = packed record
       MaxTCPSlots         : byte;
       MaxUDPSlots         : byte;
       MaxIPSlots          : byte;
       MaxRawSlots         : byte;
       CurTCPSlots         : byte;
       CurUDPSlots         : byte;
       CurIPSlots          : byte;
       CurRawSlots         : byte;
       CurLocalDescCount   : word;
       CurGlobalDesc       : word;
       MaxNetHeaderSize    : byte;
       MaxNetTrailerSize   : byte;
       MaxPacketSize       : word;
       CurNetInterfaces    : word;
       KernelRunningSince  : longint; { in ms }
       IPBroadcastAddr     : longint;
     end;

     TPCTCPInterfaceInfo = packed record
       IntfClass           : word;
       IntfType            : word;
       IntfNumber          : word;
       IPAddr              : longint;
       SubnetMask          : longint;
       IntfStatus          : word;
       PacketsReceived     : longint;
       PacketsSent         : longint;
       ReceiveErrors       : longint;
       SendErrors          : longint;
       MACAddrLen          : word; { 6 for Ethernet }
       MACAddrPtr          : pointer;
     end;

function PCTCPInit: boolean;
function PCTCP_GetConfig(var CI: TPCTCPConfigInfo): boolean;
function PCTCP_GetAddr(Socket: TPCTCPSocket; var Addr: longint): boolean;
function PCTCP_Globalize(Socket: TPCTCPSocket; var GlobalSocket: TPCTCPSocket): boolean;
function PCTCP_Release(Socket: TPCTCPSocket): boolean;
function PCTCP_ReleaseAll: boolean;
function PCTCP_IsValid(Socket: TPCTCPSocket): boolean;
function PCTCP_Select(MaxSock: TPCTCPSocket; ReadFDS, WriteFDS: PPCTCPFDSET): boolean;
function PCTCP_NetShutdown: boolean;
function PCTCP_SetAsync(Enable: boolean): boolean;
function PCTCP_Connect(var Socket: TPCTCPSocket; Protocol: word; var Addr: TPCTCPAddr): boolean;
function PCTCP_Eof(Socket: TPCTCPSocket): boolean;
function PCTCP_GetPeerName(Socket: TPCTCPSocket; var Addr: TPCTCPAddr): boolean;
function PCTCP_Abort(Socket: TPCTCPSocket): boolean;
function PCTCP_Write(Socket: TPCTCPSocket; var Data; var DataSize: word; Flags: word): boolean;
function PCTCP_WriteTo(Socket: TPCTCPSocket; var Data; var DataSize: word; Flags: word; var Addr: TPCTCPAddr): boolean;
function PCTCP_Read(Socket: TPCTCPSocket; var Data; var DataSize: word; Flags: word): boolean;
function PCTCP_ReadFrom(Socket: TPCTCPSocket; var Data; var DataSize: word; Flags: word; var Addr: TPCTCPAddr): boolean;
function PCTCP_Flush(Socket: TPCTCPSocket): boolean;
function PCTCP_SetAsyncHandler(Socket: TPCTCPSocket; Events: word; RealHandler: pointer; Hint: longint): boolean;
function PCTCP_SetOption(Socket: TPCTCPSocket; OptName: word; var OptVal; OptSize: word): boolean;
function PCTCP_GetOption(Socket: TPCTCPSocket; OptName: word; var OptVal; OptBufSize: word): boolean;
function PCTCP_GetDesc(var Socket: TPCTCPSocket): boolean;
function PCTCP_Listen(Socket: TPCTCPSocket; Protocol: word; const Addr: TPCTCPAddr; var NewDesc: TPCTCPSocket): boolean;
function PCTCP_GetNetInfo(Socket: TPCTCPSocket; var IntfInfo: TPCTCPInterfaceInfo): boolean;

function  PCTCP_isvalidsocket(Socket: TPCTCPSocket): boolean;
procedure PCTCP_FD_ZERO(var FDS: TPCTCPFDSET);
function  PCTCP_FD_SET(Socket: TPCTCPSocket; var FDS: TPCTCPFDSET): boolean;
function  PCTCP_FD_ISSET(Socket: TPCTCPSocket; const FDS: TPCTCPFDSET; var IsSet: boolean): boolean;
function  PCTCP_FD_CLEAR(Socket: TPCTCPSocket; var FDS: TPCTCPFDSET): boolean;

const PCTCPDriverInt : byte     = 0;
      PCTCPVersion   : word     = 0;
      PCTCPError     : byte     = 0;
      PCTCPSubError  : byte     = 0;

implementation

uses pmode,dos;

function CallPCTCP(Func: byte; var r: registers): boolean;
var OK: boolean;
begin
  if PCTCPDriverInt=0 then
    PCTCPInit;
  OK:=PCTCPDriverInt<>0;
  if OK then
  begin
    r.ah:=Func;
    realintr(PCTCPDriverInt,r);
    OK:=(r.flags and fCarry)=0;
    if OK then
      begin
        PCTCPError:=0; PCTCPSubError:=0
      end
    else
      begin
        PCTCPError:=r.al; PCTCPSubError:=r.ah;
      end;
  end;
  CallPCTCP:=OK;
end;

function PCTCPInit: boolean;
function CheckInt(IntNo: byte): boolean;
var P: pointer;
    Sign: array[1..20] of char;
begin
{  MoveDosToPM(Ptr(0,IntNo*4),@P,4);}
  realGetIntVec(IntNo,P);
  MoveDosToPM(P,@Sign,SizeOf(Sign));
  CheckInt:=(Pos('TCPTSR',Sign)>0);
end;
var I: byte;
    OK: boolean;
    r: registers;
begin
  if PCTCPDriverInt=0 then
    begin
      for I:=$20 to $ff do
        if CheckInt(I) then
          begin
            PCTCPDriverInt:=I;
            Break;
          end;
    end
  else
    if CheckInt(PCTCPDriverInt)=false then
      PCTCPDriverInt:=0;
  OK:=PCTCPDriverInt<>0;
  if OK then
    begin
      OK:=CallPCTCP(pctcp_cmd_netversion,r);
      if OK then
        PCTCPVersion:=r.ax;
    end;
  PCTCPInit:=OK;
end;

function PCTCP_GetConfig(var CI: TPCTCPConfigInfo): boolean;
var r: registers;
    M: MemPtr;
    OK: boolean;
begin
  FillChar(CI,SizeOf(CI),0);
  GetDosMem(M,256);
  r.ds:=M.DosSeg; r.si:=M.DosOfs;
  OK:=CallPCTCP(pctcp_cmd_getconfig,r);
  if OK then
    M.MoveDataFrom(SizeOf(CI),CI);
  FreeDosMem(M);
  PCTCP_GetConfig:=OK;
end;

function PCTCP_GetAddr(Socket: TPCTCPSocket; var Addr: longint): boolean;
var OK: boolean;
    r: registers;
begin
  r.bx:=Socket;
  OK:=CallPCTCP(pctcp_cmd_getaddr,r);
  if OK then
    Addr:=longint(r.dx) shl 16 + r.ax;
  PCTCP_GetAddr:=OK;
end;

function PCTCP_Globalize(Socket: TPCTCPSocket; var GlobalSocket: TPCTCPSocket): boolean;
var OK: boolean;
    r: registers;
begin
  r.bx:=Socket;
  OK:=CallPCTCP(pctcp_cmd_globalize,r);
  if OK=false then GlobalSocket:=pctcp_invalid_socket else
    GlobalSocket:=r.ax;
  PCTCP_Globalize:=OK;
end;

function PCTCP_Release(Socket: TPCTCPSocket): boolean;
var OK: boolean;
    r: registers;
begin
  r.bx:=Socket;
  OK:=CallPCTCP(pctcp_cmd_release,r);
  PCTCP_Release:=OK;
end;

function PCTCP_ReleaseAll: boolean;
var OK: boolean;
    r: registers;
begin
  OK:=CallPCTCP(pctcp_cmd_releaseall,r);
  PCTCP_ReleaseAll:=OK;
end;

function PCTCP_IsValid(Socket: TPCTCPSocket): boolean;
var OK: boolean;
    r: registers;
begin
  r.bx:=Socket;
  OK:=CallPCTCP(pctcp_cmd_checkdesc,r);
  PCTCP_IsValid:=OK;
end;

function RoundTo(L: longint; X: integer): longint;
begin
  RoundTo:=((L+(X-1)) div X)*X;
end;

function PCTCP_Select(MaxSock: TPCTCPSocket; ReadFDS, WriteFDS: PPCTCPFDSET): boolean;
var OK: boolean;
    r: registers;
    RM,WM: MemPtr;
    FDSize: integer;
begin
  FDSize:=(MaxSock+7) div 8;
  GetDosMem(RM,RoundTo(FDSize,4));
  GetDosMem(WM,RoundTo(FDSize,4));
  if Assigned(ReadFDS) then RM.MoveDataTo(ReadFDS^,FDSize);
  if Assigned(WriteFDS) then RM.MoveDataTo(WriteFDS^,FDSize);
  r.bx:=MaxSock-1;
  r.ds:=RM.DosSeg; r.dx:=RM.DosOfs;
  r.es:=WM.DosSeg; r.di:=WM.DosOfs;
  OK:=CallPCTCP(pctcp_cmd_select,r);
  if OK then
  begin
    if Assigned(ReadFDS) then RM.MoveDataFrom(FDSize,ReadFDS^);
    if Assigned(WriteFDS) then WM.MoveDataFrom(FDSize,WriteFDS^);
  end;
  FreeDosMem(RM); FreeDosMem(WM);
  PCTCP_Select:=OK;
end;

function PCTCP_NetShutdown: boolean;
var OK: boolean;
    r: registers;
begin
  OK:=CallPCTCP(pctcp_cmd_netshutdown,r);
  PCTCP_Netshutdown:=OK;
end;

function PCTCP_SetAsync(Enable: boolean): boolean;
var OK: boolean;
    r: registers;
    Cmd: byte;
begin
  if Enable then
    Cmd:=pctcp_cmd_enableasync
  else
    Cmd:=pctcp_cmd_disableasync;
  OK:=CallPCTCP(Cmd,r);
  PCTCP_SetAsync:=OK;
end;

function PCTCP_Connect(var Socket: TPCTCPSocket; Protocol: word; var Addr: TPCTCPAddr): boolean;
var OK: boolean;
    r: registers;
    M: MemPtr;
begin
  GetDosMem(M,SizeOf(Addr));
  r.bx:=Socket; r.dx:=Protocol;
  r.ds:=M.DosSeg; r.si:=M.DosOfs;
  M.MoveDataTo(Addr,SizeOf(Addr));
  OK:=CallPCTCP(pctcp_cmd_connect,r);
  if OK then
    begin
      Socket:=r.ax;
      M.MoveDataFrom(SizeOf(Addr),Addr);
    end;
  FreeDosMem(M);
  PCTCP_Connect:=OK;
end;

function PCTCP_GetPeerName(Socket: TPCTCPSocket; var Addr: TPCTCPAddr): boolean;
var OK: boolean;
    r: registers;
    M: MemPtr;
begin
  GetDosMem(M,SizeOf(Addr));
  r.bx:=Socket;
  r.ds:=M.DosSeg; r.dx:=M.DosOfs;
  OK:=CallPCTCP(pctcp_cmd_peername,r);
  if OK then
    M.MoveDataFrom(SizeOf(Addr),Addr);
  FreeDosMem(M);
  PCTCP_GetPeerName:=OK;
end;

function PCTCP_Eof(Socket: TPCTCPSocket): boolean;
var OK: boolean;
    r: registers;
begin
  r.bx:=Socket;
  OK:=CallPCTCP(pctcp_cmd_close,r);
  PCTCP_Eof:=OK;
end;

function PCTCP_Abort(Socket: TPCTCPSocket): boolean;
var OK: boolean;
    r: registers;
begin
  r.bx:=Socket;
  OK:=CallPCTCP(pctcp_cmd_abort,r);
  PCTCP_Abort:=OK;
end;

function PCTCP_DoWrite(Cmd: word; Socket: TPCTCPSocket; var Data; var DataSize: word; Flags: word; Addr: PPCTCPAddr): boolean;
var OK: boolean;
    r: registers;
    DataM: MemPtr;
    AddrM: MemPtr;
begin
  GetDosMem(DataM,DataSize);
  if Assigned(Addr) then GetDosMem(AddrM,SizeOf(Addr^));
  r.bx:=Socket; r.cx:=DataSize; r.dx:=Flags;
  r.ds:=DataM.DosSeg; r.si:=DataM.DosOfs;
  if Assigned(Addr) then
    begin
      AddrM.MoveDataTo(Addr^,SizeOf(Addr^));
      r.es:=AddrM.DosSeg; r.di:=AddrM.DosOfs;
    end
  else
    begin r.es:=0; r.di:=0; end;
  DataM.MoveDataTo(Data,DataSize);
  OK:=CallPCTCP(Cmd,r);
  if OK=false then DataSize:=0 else
    DataSize:=r.ax;
  if Assigned(Addr) then FreeDosMem(AddrM);
  FreeDosMem(DataM);
  PCTCP_DoWrite:=OK;
end;

function PCTCP_DoRead(Cmd: word; Socket: TPCTCPSocket; var Data; var DataSize: word; Flags: word; Addr: PPCTCPAddr): boolean;
var OK: boolean;
    r: registers;
    DataM: MemPtr;
    AddrM: MemPtr;
begin
  GetDosMem(DataM,DataSize);
  if Assigned(Addr) then GetDosMem(AddrM,SizeOf(Addr^));
  r.bx:=Socket; r.cx:=DataSize; r.dx:=Flags;
  r.ds:=DataM.DosSeg; r.si:=DataM.DosOfs;
  if Assigned(Addr) then
    begin r.es:=AddrM.DosSeg; r.di:=AddrM.DosOfs; end
  else
    begin r.es:=0; r.di:=0; end;
  OK:=CallPCTCP(Cmd,r);
  if OK=false then DataSize:=0 else
    begin
      DataSize:=r.ax;
      DataM.MoveDataFrom(DataSize,Data);
      if Assigned(Addr) then
        AddrM.MoveDataFrom(SizeOf(Addr^),Addr^);
    end;
  if Assigned(Addr) then FreeDosMem(AddrM);
  FreeDosMem(DataM);
  PCTCP_DoRead:=OK;
end;

function PCTCP_Write(Socket: TPCTCPSocket; var Data; var DataSize: word; Flags: word): boolean;
begin
  PCTCP_Write:=PCTCP_DoWrite(pctcp_cmd_write,Socket,Data,DataSize,Flags,nil);
end;

function PCTCP_WriteTo(Socket: TPCTCPSocket; var Data; var DataSize: word; Flags: word; var Addr: TPCTCPAddr): boolean;
begin
  PCTCP_WriteTo:=PCTCP_DoWrite(pctcp_cmd_writeto,Socket,Data,DataSize,Flags,@Addr);
end;

function PCTCP_Read(Socket: TPCTCPSocket; var Data; var DataSize: word; Flags: word): boolean;
begin
  PCTCP_Read:=PCTCP_DoRead(pctcp_cmd_Read,Socket,Data,DataSize,Flags,nil);
end;

function PCTCP_ReadFrom(Socket: TPCTCPSocket; var Data; var DataSize: word; Flags: word; var Addr: TPCTCPAddr): boolean;
begin
  PCTCP_ReadFrom:=PCTCP_DoRead(pctcp_cmd_ReadFrom,Socket,Data,DataSize,Flags,@Addr);
end;

function PCTCP_Flush(Socket: TPCTCPSocket): boolean;
var OK: boolean;
    r: registers;
begin
  r.bx:=Socket;
  OK:=CallPCTCP(pctcp_cmd_flush,r);
  PCTCP_Flush:=OK;
end;

function PCTCP_SetAsyncHandler(Socket: TPCTCPSocket; Events: word; RealHandler: pointer; Hint: longint): boolean;
{ event handler is called with :
   BX - socket
   CX - event
   DS:DX -> arg
   ES:DI - hint value
   STACK: small (DOS) stack
}
var OK: boolean;
    r: registers;
begin
  r.bx:=Socket; r.cx:=Events;
  r.ds:=PtrRec(RealHandler).Seg; r.si:=PtrRec(RealHandler).Ofs;
  r.es:=Hint shr 16; r.di:=Hint and $ffff;
  OK:=CallPCTCP(pctcp_cmd_setasynchandler,r);
  PCTCP_SetAsyncHandler:=OK;
end;

function PCTCP_SetOption(Socket: TPCTCPSocket; OptName: word; var OptVal; OptSize: word): boolean;
var OK: boolean;
    r: registers;
    M: MemPtr;
begin
  GetDosMem(M,OptSize);
  r.bx:=Socket; r.di:=OptName;
  r.cx:=OptSize; r.si:=4;
  r.ds:=M.DosSeg; r.dx:=M.DosOfs;
  M.MoveDataTo(OptVal,OptSize);
  OK:=CallPCTCP(pctcp_cmd_setoption,r);
  FreeDosMem(M);
  PCTCP_SetOption:=OK;
end;

function PCTCP_GetOption(Socket: TPCTCPSocket; OptName: word; var OptVal; OptBufSize: word): boolean;
var OK: boolean;
    r: registers;
    M: MemPtr;
begin
  GetDosMem(M,OptBufSize);
  r.bx:=Socket; r.di:=OptName;
  r.cx:=OptBufSize; r.si:=4;
  r.ds:=M.DosSeg; r.dx:=M.DosOfs;
  OK:=CallPCTCP(pctcp_cmd_getoption,r);
  if OK then M.MoveDataFrom(OptBufSize,OptVal);
  FreeDosMem(M);
  PCTCP_GetOption:=OK;
end;

function PCTCP_GetDesc(var Socket: TPCTCPSocket): boolean;
var OK: boolean;
    r: registers;
begin
  OK:=CallPCTCP(pctcp_cmd_getdesc,r);
  if OK=false then Socket:=pctcp_invalid_socket else
    Socket:=r.ax;
  PCTCP_GetDesc:=OK;
end;

function PCTCP_Listen(Socket: TPCTCPSocket; Protocol: word; const Addr: TPCTCPAddr; var NewDesc: TPCTCPSocket): boolean;
var OK: boolean;
    r: registers;
    M: MemPtr;
begin
  GetDosMem(M,SizeOf(Addr));
  r.bx:=Socket; r.dx:=Protocol;
  r.ds:=M.DosSeg; r.si:=M.DosOfs;
  M.MoveDataTo(Addr,SizeOf(Addr));
  OK:=CallPCTCP(pctcp_cmd_listen,r);
  if OK then
    begin
{      M.MoveDataFrom(SizeOf(Addr),Addr);}
      NewDesc:=r.ax;
    end
  else
    NewDesc:=pctcp_invalid_socket;
  FreeDosMem(M);
  PCTCP_Listen:=OK;
end;

function PCTCP_GetNetInfo(Socket: TPCTCPSocket; var IntfInfo: TPCTCPInterfaceInfo): boolean;
var OK: boolean;
    r: registers;
    M: MemPtr;
begin
  GetDosMem(M,SizeOf(IntfInfo));
  r.bx:=Socket;
  r.ds:=M.DosSeg; r.si:=M.DosOfs;
  OK:=CallPCTCP(pctcp_cmd_netinfo,r);
  if OK then
    begin
      M.MoveDataFrom(sizeof(IntfInfo),IntfInfo);
    end;
  PCTCP_GetNetInfo:=OK;
end;

function PCTCP_AbortAll: boolean;
var OK: boolean;
    r: registers;
begin
  OK:=CallPCTCP(pctcp_cmd_abortall,r);
  PCTCP_AbortAll:=OK;
end;

function ASCIIZToStr(P: pointer): string;
type PCharArray = ^TCharArray; TCharArray = array[0..32767] of char;
var S: string;
    I: integer;
begin
  S:='';
  I:=0;
  while (I<=255) and (PCharArray(P)^[I]<>#0) do
    S:=S+PCharArray(P)^[I];
  ASCIIZToStr:=S;
end;

function PCTCP_GetHostNameByAddr(IP: longint; var HostName: string): boolean;
var OK: boolean;
    r: registers;
    M: MemPtr;
    B: array[0..255] of byte;
begin
  HostName:='';
  GetDosMem(M,256);
  r.dx:=IP shr 16; r.bx:=IP and $ffff;
  r.cx:=M.Size;
  r.ds:=M.DosSeg; r.si:=M.DosOfs;
  OK:=CallPCTCP(pctcp_cmd_gethost,r);
  if OK then
    begin
      M.MoveDataFrom(255,B);
      HostName:=ASCIIZToStr(@B);
    end;
  FreeDosMem(M);
  PCTCP_GetHostNameByAddr:=OK;
end;

function PCTCP_GetHostAddrByName(const HostName: string; var IP: longint): boolean;
var OK: boolean;
    r: registers;
    M: MemPtr;
begin
  GetDosMem(M,256);
  r.cx:=256;
  r.ds:=M.DosSeg; r.dx:=M.DosOfs;
  OK:=CallPCTCP(pctcp_cmd_resolvename,r);
  if OK=false then IP:=0 else
    IP:=r.dx shl 16 + r.ax;
  FreeDosMem(M);
  PCTCP_GetHostAddrByName:=OK;
end;

function PCTCP_isvalidsocket(Socket: TPCTCPSocket): boolean;
begin
  PCTCP_isvalidsocket:=(PCTCP_firstsocket<=Socket) and (Socket<=PCTCP_lastsocket);
end;

function BytePos(Socket: TPCTCPSocket): integer;
begin
  BytePos:=(Socket and $ff) shr 3; { div 8 }
end;

function BitMask(Socket: TPCTCPSocket): byte;
begin
  BitMask:=1 shl ( Socket and $07 ); { mod 8 }
end;

procedure PCTCP_FD_ZERO(var FDS: TPCTCPFDSET);
begin
  FillChar(FDS,SizeOf(FDS),0);
end;

function  PCTCP_FD_SET(Socket: TPCTCPSocket; var FDS: TPCTCPFDSET): boolean;
var OK: boolean;
begin
  OK:=PCTCP_isvalidsocket(Socket);
  if OK then
    FDS[BytePos(Socket)]:=FDS[BytePos(Socket)] or BitMask(Socket);
  PCTCP_FD_SET:=OK;
end;

function  PCTCP_FD_ISSET(Socket: TPCTCPSocket; const FDS: TPCTCPFDSET; var IsSet: boolean): boolean;
var OK: boolean;
begin
  OK:=PCTCP_isvalidsocket(Socket);
  IsSet:=false;
  if OK then
    IsSet:=(FDS[BytePos(Socket)] and BitMask(Socket))<>0;
  PCTCP_FD_ISSET:=OK;
end;

function  PCTCP_FD_CLEAR(Socket: TPCTCPSocket; var FDS: TPCTCPFDSET): boolean;
var OK: boolean;
begin
  OK:=PCTCP_isvalidsocket(Socket);
  if OK then
    FDS[BytePos(Socket)]:=FDS[BytePos(Socket)] and not BitMask(Socket);
  PCTCP_FD_CLEAR:=OK;
end;

END.