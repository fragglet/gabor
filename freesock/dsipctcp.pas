{
    $Id: dsipctcp.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    PC/TCP (DOS) interface

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
unit DSIPCTCP;

interface

uses Objects, Types, Sockets, DSIIntf, PCSocks;

const
     PCTCPSocketsVersion = $0101; { this means 1.1 }

type
     PPCTCPSocketEntry = ^TPCTCPSocketEntry;
     TPCTCPSocketEntry = record
       SocketID    : TSocket;
       SocketType  : TSocketType;
       PCTCPSocket : TPCTCPSocket;
       State       : TSocketState;
       { --- bind data --- }
       Port        : word;
       IP          : longint;
       { --- listen data --- }
       AcceptSock  : TPCTCPSocket;
     end;

     PPCTCPSocketEntryCollection = ^TPCTCPSocketEntryCollection;
     TPCTCPSocketEntryCollection = object(TSortedCollection)
       function At(Index: sw_Integer): PPCTCPSocketEntry;
       function Compare(Key1, Key2: Pointer): sw_Integer; virtual;
       function SearchSocket(ASocketID: TSocket): PPCTCPSocketEntry;
       procedure FreeItem(Item: Pointer); virtual;
     end;

     PPCTCPSocketsInterface = ^TPCTCPSocketsInterface;
     TPCTCPSocketsInterface = object(TSocketsInterface)
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
       PCTCPCI: TPCTCPConfigInfo;
       Sockets: PPCTCPSocketEntryCollection;
       LastSocketID: TSocket;
       function  GenNextSocketID: TSocket;
       function  GetLastPCTCPSockError: longint;
       function  CheckError: longint;
       function  SearchSocket(ASocketID: TSocket): PPCTCPSocketEntry;
       function  SearchPCTCPSocket(APCTCPSocket: TPCTCPSocket): PPCTCPSocketEntry;
       function  AddSocket(ASocketID: TSocket; ASocketType: TSocketType; APCTCPSocket: TPCTCPSocket): PPCTCPSocketEntry;
       function  ChangeSocketID(S: PPCTCPSocketEntry; ANewID: TSocket): TSocket;
       procedure RemoveSocket(S: PPCTCPSocketEntry);
       function  SetAsync(Sock: TPCTCPSocket; Enabled: boolean): boolean;
       function  DoListen(E: PPCTCPSocketEntry): boolean;
       procedure setdefsocketparms(Sock: TPCTCPSocket);
       function  SockToPCTCPFDs(const FDs: TFDSet; var PCTCPFDs: TPCTCPFDSET): boolean;
       function  PCTCPToSockFDs(const PCTCPFDs: TPCTCPFDSET; var FDs: TFDSet): boolean;
     end;

procedure RegisterInterface;

implementation

uses Strings,SockCnst,SockUtil;

function NewPCTCPSocketEntry(ASocketID: TSocket; ASocketType: TSocketType;
           APCTCPSocket: TPCTCPSocket): PPCTCPSocketEntry;
var P: PPCTCPSocketEntry;
begin
  New(P); FillChar(P^,SizeOf(P^),0);
  with P^ do
  begin
    SocketID:=ASocketID; SocketType:=ASocketType;
    PCTCPSocket:=APCTCPSocket;
    State:=ssCreated;
    AcceptSock:=pctcp_invalid_socket;
  end;
  NewPCTCPSocketEntry:=P;
end;

procedure DisposePCTCPSocketEntry(P: PPCTCPSocketEntry);
begin
  if Assigned(P) then Dispose(P);
end;

function TPCTCPSocketEntryCollection.At(Index: sw_Integer): PPCTCPSocketEntry;
begin
  At:=inherited At(Index);
end;

function TPCTCPSocketEntryCollection.Compare(Key1, Key2: Pointer): sw_Integer;
var K1: PPCTCPSocketEntry absolute Key1;
    K2: PPCTCPSocketEntry absolute Key2;
    R: integer;
begin
  if K1^.SocketID<K2^.SocketID then R:=-1 else
  if K1^.SocketID>K2^.SocketID then R:= 1 else
  R:=0;
  Compare:=R;
end;

function TPCTCPSocketEntryCollection.SearchSocket(ASocketID: TSocket): PPCTCPSocketEntry;
var P: PPCTCPSocketEntry;
    E: TPCTCPSocketEntry;
    Idx: sw_integer;
begin
  E.SocketID:=ASocketID;
  if Search(@E,Idx)=false then P:=nil else
    P:=At(Idx);
  SearchSocket:=P;
end;

procedure TPCTCPSocketEntryCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then
    DisposePCTCPSocketEntry(Item);
end;

function TPCTCPSocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
var Err: longint;
    NewSock: TSocket;
    E,NewE: PPCTCPSocketEntry;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if E^.SocketType<>stTCP then
    Err:=WSAEOPNOTSUPP else
  if E^.State<>ssListening then
    Err:=WSAEINVAL else
  if (Assigned(addr) xor Assigned(addrlen))<>false then
    Err:=WSAEINVAL else { act the same way as WinSock }
  if Assigned(addrlen) and (addrlen^<INETADDRSIZE) then
    Err:=WSAEFAULT
  else
    begin
      NewE:=AddSocket(GenNextSocketID,E^.SocketType,E^.AcceptSock);
      NewSock:=E^.SocketID;
      E^.AcceptSock:=pctcp_invalid_socket;
      Err:={GetLastPCTCPSockError}WSAOK;
      setdefsocketparms(E^.PCTCPSocket);
      DoListen(E);
    end;
  if Err<>WSAOK then NewSock:=INVALID_SOCKET;
  accept:=NewSock;
end;

function TPCTCPSocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
var E: PPCTCPSocketEntry;
    Err: longint;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if (E^.State in[ssCreated,ssBound,ssDisconnected])=false then
    Err:=WSAEINVAL else
  if TSockAddrIn(addr).sin_family<>AF_INET then
    Err:=WSAEAFNOSUPPORT
  else
    begin
      E^.Port:=swapw(TSockAddrIn(addr).sin_port);
      E^.IP:=swapl(TSockAddrIn(addr).sin_addr.s_addr);
      E^.State:=ssBound;
      Err:=WSAOK;
    end;
  bind:=ISetLastError(Err);
end;

function TPCTCPSocketsInterface.closesocket(s: TSocket): longint;
var Err: longint;
    E: PPCTCPSocketEntry;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK
  else
    begin
      case E^.SocketType of
        stTCP :
          begin
            if E^.PCTCPSocket<>PCTCP_invalid_socket then
             if PCTCP_Abort(E^.PCTCPSocket) then
{               PCTCP_Release(E^.PCTCPSocket)};
            Err:=GetLastPCTCPSockError;
            if Err=WSAOK then
              RemoveSocket(E);
          end;
      else
        Err:=WSAESOCKTNOSUPPORT;
      end;
    end;
  closesocket:=ISetLastError(Err);
end;

function TPCTCPSocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
var E: PPCTCPSocketEntry;
    Err: longint;
    PCAddr: TPCTCPAddr;
    prot: word;
begin
  Err:=WSAOK;
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if E^.SocketType<>stTCP then
    Err:=WSAEOPNOTSUPP else
  if E^.State=ssConnected then
    Err:=WSAEISCONN else
  if (E^.State in[ssCreated,ssBound])=false then
    Err:=WSAEINVAL else
  if (namelen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  if (TSockAddrIn(name).sin_family<>AF_INET) and (TSockAddrIn(name).sin_family<>AF_UNSPEC) then
    Err:=WSAEAFNOSUPPORT else
  begin
    with PCAddr do
    begin
      RemotePort:=swapw(TSockAddrIn(name).sin_port);
      IP:=TSockAddrIn(name).sin_addr.s_addr;
    end;
    case E^.SocketType of
      stTCP : prot:=pctcp_prot_TCP;
      stUDP : prot:=pctcp_prot_UDP;
      stRaw : prot:=pctcp_prot_Raw;
    else Err:=WSAEPROTONOSUPPORT;
    end;
    if Err=WSAOK then
    begin
      PCTCP_Connect(E^.PCTCPSocket,prot,PCAddr);
      Err:=GetLastPCTCPSockError;
      if Err=WSAOK then
        begin
          E^.State:=ssConnected;
          getsockname(s,name,namelen);
          setdefsocketparms(E^.PCTCPSocket);
        end;
    end;
  end;
  connect:=ISetLastError(Err);
end;

function TPCTCPSocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
begin
  ioctlsocket:=ISetLastError(WSAEOPNOTSUPP);
end;

function TPCTCPSocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var Err: longint;
    E: PPCTCPSocketEntry;
    PCAddr: TPCTCPAddr;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if (E^.SocketType<>stTCP) then
    Err:=WSAEOPNOTSUPP else
  if (namelen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  begin
    PCTCP_GetPeerName(E^.PCTCPSocket,PCAddr);
    Err:=GetLastPCTCPSockError;
    if Err=WSAOK then
    begin
      FillChar(name,Sizeof(name),0);
      namelen:=INETADDRSIZE;
      with TSockAddrIn(name) do
      begin
        sin_family:=AF_INET;
        sin_port:=swap(PCAddr.RemotePort);
        sin_addr.s_addr:=PCAddr.IP;
      end;
    end;
  end;
  getpeername:=ISetLastError(Err);
end;

function TPCTCPSocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var Err: longint;
    E: PPCTCPSocketEntry;
    PCAddr: TPCTCPAddr;
    LAddr: longint;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if (E^.SocketType<>stTCP) then
    Err:=WSAEOPNOTSUPP else
  if (namelen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  begin
    PCTCP_GetPeerName(E^.PCTCPSocket,PCAddr);
    Err:=GetLastPCTCPSockError;
    if Err=WSAOK then
    begin
      PCTCP_GetAddr(E^.PCTCPSocket,LAddr);
      Err:=GetLastPCTCPSockError;
    end;
    if Err=WSAOK then
    begin
      FillChar(name,Sizeof(name),0);
      namelen:=INETADDRSIZE;
      with TSockAddrIn(name) do
      begin
        sin_family:=AF_INET;
        sin_port:=swap(PCAddr.LocalPort);
        sin_addr.s_addr:=LAddr;
      end;
    end;
    Err:=WSAOK;
  end;
  getsockname:=ISetLastError(Err);
end;

function TPCTCPSocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
begin
  getsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TPCTCPSocketsInterface.listen(s: TSocket; backlog: longint): longint;
var E: PPCTCPSocketEntry;
    Err: longint;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if E^.SocketType<>stTCP then
    Err:=WSAEOPNOTSUPP else
  if E^.State=ssConnected then
    Err:=WSAEISCONN else
  if (E^.State in[ssCreated,ssBound])=false then
    Err:=WSAEINVAL else
  begin
    DoListen(E);
    Err:=WSAGetLastError;
  end;
  listen:=ISetLastError(Err);
end;

procedure TPCTCPSocketsInterface.setdefsocketparms(Sock: TPCTCPSocket);
var L: TTimeVal;
begin
{  L:=500;
  if pctcp_setoption(Sock,pctcp_opt_windowsize,L,sizeof(L))=false then
    writeln('set windowsize failed');}
  L.tv_sec:=0; L.tv_usec:=1;
  if pctcp_setoption(Sock,pctcp_opt_timeout,L,sizeof(L))=false then
    writeln('set windowsize failed');
end;

function TPCTCPSocketsInterface.DoListen(E: PPCTCPSocketEntry): boolean;
var PCAddr: TPCTCPAddr;
    prot: word;
    Err: longint;
begin
  if setasync(E^.PCTCPSocket,true)=false then
    Err:=WSAEFAULT
  else
    begin
      FillChar(PCAddr,SizeOf(PCAddr),0);
      case E^.SocketType of
        stTCP : prot:=pctcp_prot_TCP;
      end;
      PCAddr.Protocol:=prot;
      PCAddr.LocalPort:=E^.Port;
      PCTCP_Listen(E^.PCTCPSocket,prot,PCAddr,E^.AcceptSock);
      Err:=GetLastPCTCPSockError;
      if Err=WSAOK then
        E^.State:=ssListening
      else
        setasync(E^.PCTCPSocket,false);
    end;
  DoListen:=ISetLastError(Err)=0;
end;

function TPCTCPSocketsInterface.SetAsync(Sock: TPCTCPSocket; Enabled: boolean): boolean;
var L: longint;
begin
  if Enabled then L:=0 else L:=1;
  PCTCP_SetOption(Sock,pctcp_opt_asynchstate,L,SizeOf(L));
  setasync:=CheckError=0;
end;

function TPCTCPSocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
var Err: longint;
    E: PPCTCPSocketEntry;
    pcflags: word;
    size: word;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  begin
    pctcp_flush(E^.PCTCPSocket); { !!!!! }
    size:=Min(len,high(size));
    pcflags:=0;
    PCTCP_Read(E^.PCTCPSocket,Buf,size,pcflags);
    Err:=GetLastPCTCPSockError;
  end;
  ISetLastError(Err);
  if Err<>WSAOK then size:=0;
  recv:=size;
end;

function TPCTCPSocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
         var fromlen: longint): longint;
var Err: longint;
    E: PPCTCPSocketEntry;
    pcflags: word;
    size: word;
    PCAddr: TPCTCPAddr;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  begin
    size:=Min(len,high(size));
    pcflags:=0;
    PCTCP_ReadFrom(E^.PCTCPSocket,Buf,size,pcflags,PCAddr);
    Err:=GetLastPCTCPSockError;
    if Err=WSAOK then
    begin
      fromlen:=INETADDRSIZE;
      fillchar(from,sizeof(from),0);
      TSockAddrIn(from).sin_addr.s_addr:=PCAddr.IP;
      TSockAddrIn(from).sin_port:=swap(PCAddr.RemotePort);
    end;
  end;
  ISetLastError(Err);
  if Err<>WSAOK then size:=0;
  recvfrom:=size;
end;

function TPCTCPSocketsInterface.SockToPCTCPFDs(const FDs: TFDSet; var PCTCPFDs: TPCTCPFDSET): boolean;
var I: integer;
    OK: boolean;
    S: TSocket;
    E: PPCTCPSocketEntry;
begin
  FillChar(PCTCPFDs,SizeOf(PCTCPFDs),0);
  OK:=true;
  PCTCP_FD_ZERO(PCTCPFDs);
  for I:=0 to FDs.fd_count-1 do
    begin
      S:=FDs.fd_array[I];
      E:=SearchSocket(S);
      if Assigned(E)=false then
        OK:=false
      else
        S:=E^.PCTCPSocket;
      OK:=OK and PCTCP_FD_SET(S,PCTCPFDs);
    end;
  SockToPCTCPFDs:=OK;
end;

function TPCTCPSocketsInterface.PCTCPToSockFDs(const PCTCPFDs: TPCTCPFDSET; var FDs: TFDSet): boolean;
var I: integer;
    IsSet: boolean;
    E: PPCTCPSocketEntry;
begin
  FD_ZERO(FDs);
  for I:=PCTCP_firstsocket to PCTCP_lastsocket do
    begin
      PCTCP_FD_ISSET(I,PCTCPFDs,IsSet);
      if IsSet then
      begin
        E:=SearchPCTCPSocket(I);
        if Assigned(E) then
          FD_SET(E^.SocketID,FDs);
      end;
    end;
  PCTCPToSockFDs:=true;
end;

function TPCTCPSocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
var RFDS,WFDS,EFDS: TPCTCPFDSET;
    RP,WP,EP: PPCTCPFDSET;
    PCTCPTimeout: longint;
    Count: integer;
    StartTT,Diff: longint;
begin
  if Assigned(timeout)=false then
    PCTCPTimeout:=-1
  else
    PCTCPTimeout:=TimeValToTicks(timeout^);
  StartTT:=GetDosTicks;
  repeat
    RP:=nil; WP:=nil; EP:=nil;
    if Assigned(readfds) then
    begin
       SockToPCTCPFDs(readfds^,RFDs);
       RP:=@RFDs;
    end;
    if Assigned(writefds) then
    begin
       SockToPCTCPFDs(writefds^,WFDs);
       WP:=@WFDs;
    end;
    if Assigned(exceptfds) then
    begin
       SockToPCTCPFDs(exceptfds^,EFDs);
       EP:=@EFDs;
    end;
    nfds:=PCTCPFDSETSIZE; { set to maximum index }
    PCTCP_select(nfds,RP,WP);
    { don't forget to implement exceptfds checking here !!!!! }
    PCTCP_FD_ZERO(EFDs);
    if Assigned(readfds) then PCTCPToSockFDs(RFDs,readfds^);
    if Assigned(writefds) then PCTCPToSockFDs(WFDs,writefds^);
    if Assigned(exceptfds) then PCTCPToSockFDs(EFDs,exceptfds^);
    if CheckError<>0 then
      Count:=-1
    else
      begin
        Count:=0;
        if Assigned(readfds) then Inc(Count,readfds^.fd_count);
        if Assigned(writefds) then Inc(Count,writefds^.fd_count);
        if Assigned(exceptfds) then Inc(Count,exceptfds^.fd_count);
      end;
    Diff:=GetElapsedTicks(StartTT);
  until ((Diff>PCTCPTimeout) and (PCTCPTimeout<>-1)) or
        (Count<>0);
  select:=Count;
end;


function TPCTCPSocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
var Err: longint;
    E: PPCTCPSocketEntry;
    pcflags: word;
    size: word;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  begin
    size:=Min(len,high(size));
    pcflags:=0;
    PCTCP_Write(E^.PCTCPSocket,Buf,size,pcflags);
    Err:=GetLastPCTCPSockError;
    pctcp_flush(E^.PCTCPSocket); { !!!!! }
  end;
  ISetLastError(Err);
  if Err<>WSAOK then size:=0;
  send:=size;
end;

function TPCTCPSocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr;
         tolen: longint): longint;
var Err: longint;
    E: PPCTCPSocketEntry;
    pcflags: word;
    size: word;
    PCAddr: TPCTCPAddr;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  begin
    size:=Min(len,high(size));
    pcflags:=0;
    fillchar(PCAddr,sizeof(PCAddr),0);
    with TSockAddrIn(addrto) do
    begin
      PCAddr.IP:=sin_addr.s_addr;
      PCAddr.RemotePort:=swap(sin_port);
    end;
    PCTCP_WriteTo(E^.PCTCPSocket,Buf,size,pcflags,PCAddr);
    Err:=GetLastPCTCPSockError;
  end;
  ISetLastError(Err);
  if Err<>WSAOK then size:=0;
  sendto:=size;
end;

function TPCTCPSocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
begin
  setsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TPCTCPSocketsInterface.shutdown(s: TSocket; how: longint): longint;
var Err: longint;
    E: PPCTCPSocketEntry;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK
  else
    begin
      PCTCP_Eof(s);
      Err:=GetLastPCTCPSockError;
    end;
  shutdown:=ISetLastError(Err);
end;

function TPCTCPSocketsInterface.socket(af, struct, protocol: longint): TSocket;
var Err: longint;
    Sock: TSocket;
    SType: TSocketType;
    E: PPCTCPSocketEntry;
    PCSock: TPCTCPSocket;
begin
  if af<>AF_INET then
    Err:=WSAEAFNOSUPPORT else
  if (struct<>SOCK_STREAM) and (struct<>SOCK_DGRAM) then
    Err:=WSAESOCKTNOSUPPORT else
  if (protocol<>IPPROTO_UDP) and (protocol<>IPPROTO_TCP) then
    Err:=WSAEPROTONOSUPPORT else
  if ( (struct=SOCK_DGRAM) and (protocol<>IPPROTO_UDP) ) or
     ( (struct=SOCK_STREAM) and (protocol<>IPPROTO_TCP) ) then
    Err:=WSAEPROTOTYPE else
  begin
    if PCTCP_GetDesc(PCSock)=false then
      Err:=GetLastPCTCPSockError
    else
      begin
        case protocol of
          IPPROTO_UDP : SType:=stUDP;
          IPPROTO_TCP : SType:=stTCP;
        end;
        E:=AddSocket(GenNextSocketID,SType,PCSock);
        Sock:=E^.SocketID;
        Err:=WSAOK;
      end;
  end;
  ISetLastError(Err);
  if Err<>WSAOK then Sock:=INVALID_SOCKET;
  socket:=Sock;
end;

function TPCTCPSocketsInterface.GetLastPCTCPSockError: longint;
var Err: longint;
begin
  case PCTCPError of
     pctcp_err_OK               : Err:=WSAOK;
     pctcp_err_INUSE            : Err:=WSAEISCONN; { protocol or socket already in use }
     pctcp_err_MSDOS            : Err:=WSAENETDOWN; { a DOS-error occoured while processing }
     pctcp_err_NOMEM            : Err:=WSAENOBUFS; { out of memory }
     pctcp_err_NOTNETCONN       : Err:=WSAENOTSOCK; { not a network descriptor }
     pctcp_err_ILLEGALOP        : Err:=WSAEOPNOTSUPP; { invalid op. on given kind of descriptor }
     pctcp_err_BADPKT           : Err:=WSAENETDOWN; { illegal or corrupted packet }
     pctcp_err_NOHOST           : Err:=WSAEINVAL; { no host bound to specified connection }
     pctcp_err_CANTOPEN         : Err:=WSAENETDOWN; { unable to open file }
     pctcp_err_NETUNREACH       : Err:=WSAENETUNREACH; { network is unreachable }
     pctcp_err_HOSTUNREACH      : Err:=WSAEHOSTUNREACH; { host is unreachable }
     pctcp_err_PROTUNREACH      : Err:=WSAEPROTONOSUPPORT; { protocol in unreachable }
     pctcp_err_PORTUNREACH      : Err:=WSAEADDRINUSE; { port is unreachable }
     pctcp_err_TIMEOUT          : Err:=WSAETIMEDOUT; { operation timed out }
     pctcp_err_HOSTUNKNOWN      : Err:=WSAEHOSTUNREACH; { unable to resolve host name }
     pctcp_err_NOSERVERS        : Err:=WSAEHOSTUNREACH; { no name server configured }
     pctcp_err_SERVERERR        : Err:=WSAEHOSTUNREACH; { bad reply from name server }
     pctcp_err_BADFORMAT        : Err:=WSAEADDRNOTAVAIL; { ivalid IP address }
     pctcp_err_BADARG           : Err:=WSAEINVAL; { invalid argument }
     pctcp_err_EOF              : Err:=WSAECONNRESET; { connection terminated by remote host }
     pctcp_err_RESET            : Err:=WSAENETRESET; { connection has been reset }
     pctcp_err_WOULDBLOCK       : Err:=WSAEWOULDBLOCK; { call to recv() when no data was available }
     pctcp_err_UNBOUND          : Err:=WSAENOBUFS; { insuccifient resources to complete op }
     pctcp_err_NODESC           : Err:=WSAENOBUFS; { could not allocate network descriptor }
     pctcp_err_BADSYSCALL       : Err:=WSAEOPNOTSUPP; { invalid/unsupported kernel call }
     pctcp_err_CANTBROADCAST    : Err:=WSAEACCES; { unable to broadcast }
     pctcp_err_NOTESTAB         : Err:=WSAENOTCONN; { illegal operation for unconnected socket }
     pctcp_err_KernelBusy       : Err:=WSAENOBUFS; { kernel busy, try again later }
     pctcp_err_ICMPMESG         : Err:=WSAENETDOWN; { an ICMP message has been received (not on streams) }
     pctcp_err_TERMINATING      : Err:=WSAENETDOWN; { a fatal internal error occoured }
     pctcp_err_TAGLOCKED        : Err:=WSAEINVAL; { not allowed to set this flag }
     pctcp_err_BADINTERFACE     : Err:=WSAEINVAL; { non-existent interface specified }
     pctcp_err_BADCONFIG        : Err:=WSAENETDOWN; { can't run kernel because of bad config }
     pctcp_err_EMM              : Err:=WSAENETDOWN; { expanded memory error }
     pctcp_err_CANTSHUTDOWN     : Err:=WSAENETDOWN; { can't unload kernel (multitasker running) }
     pctcp_err_PARKEDIN         : Err:=WSAENETDOWN; { unable to unhook dos interrupt }
     pctcp_err_NOQIOS           : Err:=WSAENOBUFS; { run out of resources, try again later }
     pctcp_err_WOULDTRUNCATE    : Err:=WSAENOBUFS; { datagram was too large, but "donttruncate" was set }
  else Err:=WSAEINVAL;
  end;
  GetLastPCTCPSockError:=Err;
end;

function TPCTCPSocketsInterface.CheckError: longint;
begin
  CheckError:=ISetLastError(GetLastPCTCPSockError);
end;

function TPCTCPSocketsInterface.SearchSocket(ASocketID: TSocket): PPCTCPSocketEntry;
var P: PPCTCPSocketEntry;
begin
  if assigned(Sockets)=false then P:=nil else
    P:=Sockets^.SearchSocket(ASocketID);
  SearchSocket:=P;
end;

function TPCTCPSocketsInterface.SearchPCTCPSocket(APCTCPSocket: TPCTCPSocket): PPCTCPSocketEntry;
var P,E: PPCTCPSocketEntry;
    I: integer;
begin
  E:=nil;
  for I:=0 to Sockets^.Count-1 do
  begin
    P:=Sockets^.At(I);
    if P^.PCTCPSocket=APCTCPSocket then
      begin
        E:=P;
        Break;
      end;
  end;
  SearchPCTCPSocket:=E;
end;

function TPCTCPSocketsInterface.GenNextSocketID: TSocket;
begin
  Inc(LastSocketID);
  GenNextSocketID:=LastSocketID;
end;

function TPCTCPSocketsInterface.AddSocket(ASocketID: TSocket; ASocketType: TSocketType;
         APCTCPSocket: TPCTCPSocket): PPCTCPSocketEntry;
var E: PPCTCPSocketEntry;
begin
  if ASocketID=-1 then ASocketID:=GenNextSocketID;
  E:=NewPCTCPSocketEntry(ASocketID,ASocketType,APCTCPSocket);
  Sockets^.Insert(E);
  AddSocket:=E;
end;

function TPCTCPSocketsInterface.ChangeSocketID(S: PPCTCPSocketEntry; ANewID: TSocket): TSocket;
begin
  ChangeSocketID:=S^.SocketID;
  Sockets^.Delete(S);
  S^.SocketID:=ANewID;
  Sockets^.Insert(S);
end;

procedure TPCTCPSocketsInterface.RemoveSocket(S: PPCTCPSocketEntry);
begin
  Sockets^.Delete(S);
  DisposePCTCPSocketEntry(S);
end;

{ ------ }
function TPCTCPSocketsInterface.WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint;
var Err: longint;
begin
  if Swap(wVersionRequired)>PCTCPSocketsVersion then
    Err:=WSAVERNOTSUPPORTED else
  begin
    PCTCP_GetConfig(PCTCPCI);
    FillChar(FSData,SizeOf(FSData),0);
    with FSData do
    begin
      wVersion:=Swap(Min(Swap(wVersionRequired),PCTCPSocketsVersion));
      wHighVersion:=Swap(PCTCPSocketsVersion);
      StrCopy(szDescription,'PC/TCP TCP/IP');
      StrCopy(szSystemStatus,'Running');
      iMaxSockets:=PCTCPCI.MaxTCPSlots+PCTCPCI.MaxUDPSlots+PCTCPCI.MaxIPSlots;
      iMaxUdpDg:=PCTCPCI.MaxPacketSize;
      lpVendorInfo:=nil;
    end;
    Err:=WSAOK;
    New(Sockets, Init(20,10));
  end;
  ISetLastError(Err);
  WSAStartup:=Err;
end;

function TPCTCPSocketsInterface.WSACleanup: longint;
var Err: longint;
begin
  Err:=WSAOK;
  ISetLastError(Err);
  WSACleanup:=Err;
  if Assigned(Sockets) then Dispose(Sockets, Done); Sockets:=nil;
end;

function CreateInterface(ID: integer): PSocketsInterface; {$ifdef TP}far;{$endif}
begin
  CreateInterface:=New(PPCTCPSocketsInterface, Init(ID));
end;

procedure RegisterInterface;
begin
  RegisterSocketsInterface(
    {$ifdef FPC}@{$endif}PCTCPInit,
    {$ifdef FPC}@{$endif}CreateInterface
  );
end;

END.
{
  $Log: dsipctcp.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
