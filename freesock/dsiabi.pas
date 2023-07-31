{
    $Id: dsiabi.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Trumpet TCPDRV/ABI (DOS) interface

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
unit DSIABI;

interface

uses Objects, Types, Sockets, DSIIntf, ABISocks;

const
     ABISocketsVersion = $0101; { this means 1.1 }

     ABIConnectTimeout = round(5*18.2);
     ABICloseTimeout   = round(5*18.2);

     ABIHookTimer   : boolean = false;
     { newer TCPDRV's do not require to be called periodally (they hook
       int $1c themself), so, this causes only unnecessary overhead }

type
     PABISocketEntry = ^TABISocketEntry;
     TABISocketEntry = record
       SocketID    : TSocket;
       SocketType  : TSocketType;
       ABISocket   : TABISocket;
       State       : TSocketState;
       { --- bind data --- }
       Port        : word;
       IP          : longint;
     end;

     PABISocketEntryCollection = ^TABISocketEntryCollection;
     TABISocketEntryCollection = object(TSortedCollection)
       function  At(Index: sw_Integer): PABISocketEntry;
       function  Compare(Key1, Key2: Pointer): sw_Integer; virtual;
       function  SearchSocket(ASocketID: TSocket): PABISocketEntry;
       procedure FreeItem(Item: Pointer); virtual;
     end;

     PABISocketsInterface = ^TABISocketsInterface;
     TABISocketsInterface = object(TSocketsInterface)
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
       Sockets: PABISocketEntryCollection;
       LastSocketID: TSocket;
       function  GenNextSocketID: TSocket;
       function  GetLastABISockError: longint;
       function  SearchSocket(ASocketID: TSocket): PABISocketEntry;
       function  AddSocket(ASocketID: TSocket; ASocketType: TSocketType; AABISocket: TABISocket): PABISocketEntry;
       function  ChangeSocketID(S: PABISocketEntry; ANewID: TSocket): TSocket;
       procedure RemoveSocket(S: PABISocketEntry);
     end;

procedure RegisterInterface;

implementation

uses Strings,SockCnst,SockUtil;

function NewABISocketEntry(ASocketID: TSocket; ASocketType: TSocketType;
           AABISocket: TABISocket): PABISocketEntry;
var P: PABISocketEntry;
begin
  New(P); FillChar(P^,SizeOf(P^),0);
  with P^ do
  begin
    SocketID:=ASocketID; SocketType:=ASocketType;
    ABISocket:=AABISocket;
    State:=ssCreated;
  end;
  NewABISocketEntry:=P;
end;

procedure DisposeABISocketEntry(P: PABISocketEntry);
begin
  if Assigned(P) then Dispose(P);
end;

function TABISocketEntryCollection.At(Index: sw_Integer): PABISocketEntry;
begin
  At:=inherited At(Index);
end;

function TABISocketEntryCollection.Compare(Key1, Key2: Pointer): sw_Integer;
var K1: PABISocketEntry absolute Key1;
    K2: PABISocketEntry absolute Key2;
    R: integer;
begin
  if K1^.SocketID<K2^.SocketID then R:=-1 else
  if K1^.SocketID>K2^.SocketID then R:= 1 else
  R:=0;
  Compare:=R;
end;

function TABISocketEntryCollection.SearchSocket(ASocketID: TSocket): PABISocketEntry;
var P: PABISocketEntry;
    E: TABISocketEntry;
    Idx: sw_integer;
begin
  E.SocketID:=ASocketID;
  if Search(@E,Idx)=false then P:=nil else
    P:=At(Idx);
  SearchSocket:=P;
end;

procedure TABISocketEntryCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then
    DisposeABISocketEntry(Item);
end;

function TABISocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
var E,NewE: PABISocketEntry;
    Err: longint;
    NewSock: TSocket;
    TS: TTCPStatusRec;
    OK: boolean;
    ID: TSocket;
    tempaddr: TSockAddrIn;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if E^.SocketType=stUDP then
    Err:=WSAEOPNOTSUPP else
  if E^.State<>ssListening then
    Err:=WSAEINVAL else
  if (Assigned(addr) xor Assigned(addrlen))<>false then
    Err:=WSAEINVAL else { act the same way as WinSock }
  if Assigned(addrlen) and (addrlen^<INETADDRSIZE) then
    Err:=WSAEFAULT
  else
    begin
      repeat
        OK:=TCPGetStatus(E^.ABISocket,tcp_stat_Normal,TS);
      until (OK=false) or (TS.TCPState in[tcp_state_Established,tcp_state_Close_Wait]);
      if (OK=false) then
        Err:=GetLastABISockError else
      if (TS.TCPState<tcp_state_Established) then
        Err:=WSAEMFILE
      else
        begin
          E^.State:=ssConnected;
          if assigned(addrlen) then addrlen^:=INETADDRSIZE;
          if assigned(addr) then
            with TSockAddrIn(addr^) do
            begin
              sin_family:=AF_INET;
              sin_port:=TS.SessionInfo.DestPort;
              sin_addr.s_addr:=TS.SessionInfo.DestIP;
            end;

          ID:=ChangeSocketID(E,GenNextSocketID);
          NewE:=AddSocket(ID,E^.SocketType,abi_invalid_socket);

          tempaddr.sin_family:=AF_INET;
          tempaddr.sin_port:=E^.Port; E^.Port:=0;
          tempaddr.sin_addr.s_addr:=0;

          Err:=bind(NewE^.SocketID,TSockAddr(tempaddr),sizeof(tempaddr));
          Err:=listen(NewE^.SocketID,1);

          NewSock:=E^.SocketID;
          Err:=WSAOK;
        end;
    end;
  WSASetLastError(Err);
  if Err<>WSAOK then NewSock:=INVALID_SOCKET;
  accept:=NewSock;
end;

function TABISocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
var E: PABISocketEntry;
    Err: longint;
    inaddr: TSockAddrIn absolute Addr;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
{  if E^.SocketType=stUDP then
    Err:=WSAEOPNOTSUPP else  !!! default target for send() }
  if (E^.State in[ssCreated,ssBound,ssDisconnected])=false then
    Err:=WSAEINVAL else
  if (inaddr.sin_family<>AF_INET) and (inaddr.sin_family<>AF_UNSPEC) then
    Err:=WSAEAFNOSUPPORT
  else
    begin
      E^.Port:=swapw(inaddr.sin_port);
      E^.IP:=swapl(inaddr.sin_addr.s_addr);
      E^.State:=ssBound;
      Err:=WSAOK;
    end;
  bind:=ISetLastError(Err);
end;

function TABISocketsInterface.closesocket(s: TSocket): longint;
var Err: longint;
    E: PABISocketEntry;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK
  else
    begin
      case E^.SocketType of
        stTCP :
          begin
            if E^.ABISocket<>abi_invalid_socket then
              TCPClose(E^.ABISocket,0,ABICloseTimeout);
            Err:=GetLastABISockError;
            if Err=WSAOK then
              RemoveSocket(E);
          end;
      else
        Err:=WSAESOCKTNOSUPPORT;
      end;
    end;
  closesocket:=ISetLastError(Err);
end;

function TABISocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
var E: PABISocketEntry;
    Err: longint;
    tempaddr: TSockAddrIn;
    inname: TSockAddrIn absolute name;
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
  if (namelen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  if (inname.sin_family<>AF_INET) and (inname.sin_family<>AF_UNSPEC) then
    Err:=WSAEAFNOSUPPORT else
  begin
    tempaddr:=TSockAddrIn(name);
    with tempaddr do
    begin
      sin_port:=swapw(sin_port);
      sin_addr.s_addr:=sin_addr.s_addr;
    end;
    TCPOpen(tcp_open_Normal,E^.Port,tempaddr.sin_addr.s_addr,tempaddr.sin_port,ABIConnectTimeout,E^.ABISocket);
    Err:=GetLastABISockError;
    if Err=WSAOK then
      begin
        E^.State:=ssConnected;
        getsockname(s,name,namelen);
      end;
  end;
  connect:=ISetLastError(Err);
end;

function TABISocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
begin
  ioctlsocket:=ISetLastError(WSAEOPNOTSUPP);
end;

function TABISocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var Err: longint;
    E: PABISocketEntry;
    TS: TTCPStatusRec;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if (E^.SocketType<>stTCP) then
    Err:=WSAEOPNOTSUPP else
  if (namelen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  if TCPGetStatus(E^.ABISocket,tcp_stat_Normal,TS)=false then
    Err:={WSAENETUNREACH}GetLastABISockError else
  if TS.TCPState<tcp_state_Established then
    Err:=WSAENOTCONN else
  begin
    namelen:=INETADDRSIZE;
    with TSockAddrIn(name) do
    begin
      sin_family:=AF_INET;
      sin_port:=TS.SessionInfo.DestPort;
      sin_addr.s_addr:=TS.SessionInfo.DestIP;
    end;
    Err:=WSAOK;
  end;
  getpeername:=ISetLastError(Err);
end;

function TABISocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var Err: longint;
    E: PABISocketEntry;
    TS: TTCPStatusRec;
    inname: TSockAddrIn absolute name;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if (namelen<INETADDRSIZE) then
    Err:=WSAEFAULT else
  case E^.SocketType of
    stTCP :
      begin
        if E^.ABISocket=abi_invalid_socket then
          begin
            if E^.State=ssBound then
              begin
                inname.sin_family:=AF_INET;
                inname.sin_port:=swapw(E^.Port);
                inname.sin_addr.s_addr:=swapl(E^.IP);
                namelen:=INETADDRSIZE;
                Err:=WSAOK;
              end
            else
              Err:=WSAENOTCONN;
          end
        else
        if TCPGetStatus(E^.ABISocket,tcp_stat_Normal,TS)=false then
          Err:=WSAENETUNREACH else
        if (E^.State<>ssListening) and (TS.TCPState<tcp_state_Established) then
          Err:=WSAENOTCONN else
        begin
          namelen:=INETADDRSIZE;
          with TSockAddrIn(name) do
          begin
            sin_family:=AF_INET;
            sin_port:=TS.SessionInfo.SourcePort;
            sin_addr.s_addr:=TS.SessionInfo.SourceIP;
          end;
          Err:=WSAOK;
        end;
      end;
    stUDP :
      begin
        Err:=WSAEOPNOTSUPP;
      end;
  end;
  getsockname:=ISetLastError(Err);
end;

function TABISocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
begin
  getsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TABISocketsInterface.listen(s: TSocket; backlog: longint): longint;
var E: PABISocketEntry;
    Err: longint;
    addr: TSockAddrIn;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if (E^.State in[ssCreated,ssBound])=false then
    Err:=WSAEINVAL else
  begin
    with addr do
    begin
      sin_port:=0;
      sin_addr.s_addr:=0;
    end;
    TCPOpen(tcp_open_Listener,E^.Port,addr.sin_addr.s_addr,addr.sin_port,timeout_infinite,E^.ABISocket);
    Err:=GetLastABISockError;
    if Err=WSAOK then
      begin
        E^.State:=ssListening;
      end;
  end;
  listen:=ISetLastError(Err);
end;

function TABISocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
var addr: TSockAddr;
    addrsize: longint;
begin
  addrsize:=sizeof(addr);
  recv:=recvfrom(s,Buf,len,flags,addr,addrsize);
end;

function TABISocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
         var fromlen: longint): longint;
var Err: longint;
    E: PABISocketEntry;
    abiflags: byte;
    size: word;
    OK: boolean;
    TS: TTCPStatusRec;
begin
  Size:=0;
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  case E^.SocketType of
    stTCP :
     if (E^.State<>ssConnected) then
       Err:=WSAENOTCONN else
     if (Flags and not(MSG_OOB))<>0 then
       Err:=WSAEOPNOTSUPP else
     begin
       abiflags:=0;
       abiflags:=abiflags or tcp_get_GetAndReturn;
       repeat
         size:=Min(len,High(Size));
         OK:=TCPGet(E^.ABISocket,abiflags,Buf,size,{timeout_infinite}0);
         if OK and (size=0) then
         begin
          OK:=TCPGetStatus(E^.ABISocket,tcp_stat_Normal,TS);
          if OK then
          OK:=(TS.TCPState in[tcp_state_Syn_Sent..tcp_state_Wait_2]);
         end;
       until (OK=false) or (Size>0); { block until data recvd or error }
       if OK=false then
         size:=0;
       Err:=GetLastABISockError;
       if Err=WSAOK then
         begin
           getpeername(s,from,fromlen);
         end;
     end;
    stUDP :
      begin
        Err:=WSAEOPNOTSUPP;
      end;
  end;
  WSASetLastError(Err);
  if Err<>WSAOK then size:=0;
  recvfrom:=size;
end;

function TABISocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
var Err: longint;
    Count: longint;
    I: u_int;
    E: PABISocketEntry;
    Leave: boolean;
    TS: TTCPStatusRec;
begin
  Err:=WSAOK;

  if assigned(readfds) then
  with readfds^ do
    for I:=1 to fd_count do
    begin
      Leave:=false;
      E:=SearchSocket(fd_array[I-1]);
      if E=nil then
        Err:=WSAENOTSOCK
      else
        case E^.SocketType of
          stTCP :
            begin
              if TCPGetStatus(E^.ABISocket,tcp_stat_Normal,TS) then
                Leave:=TS.TCPState in[tcp_state_Syn_Received..tcp_state_Close_Wait];
              if E^.State<>ssListening then
               Leave:=Leave and (TS.BytesToRead>0);
            end;
          stUDP : ;
        end;
      if Leave=false then FD_CLR(fd_array[I-1],readfds^);
    end;

  if assigned(writefds) then
  with writefds^ do
    for I:=1 to fd_count do
    begin
      Leave:=false;
      E:=SearchSocket(fd_array[I-1]);
      if E=nil then
        Err:=WSAENOTSOCK
      else
        case E^.SocketType of
          stTCP :
            begin
              if TCPGetStatus(E^.ABISocket,tcp_stat_Normal,TS) then
                Leave:=TS.TCPState=tcp_state_Established;
              if E^.State<>ssListening then
                Leave:=Leave and (TS.BytesPending=0);
            end;
          stUDP : ;
        end;
      if Leave=false then FD_CLR(fd_array[I-1],writefds^);
    end;

  if assigned(exceptfds) then
  with exceptfds^ do
    for I:=1 to fd_count do
    begin
      Leave:=false;
      E:=SearchSocket(fd_array[I-1]);
      if E=nil then
        Err:=WSAENOTSOCK
      else
        case E^.SocketType of
          stTCP :
            begin
              if TCPGetStatus(E^.ABISocket,tcp_stat_Normal,TS) then
                Leave:=TS.TCPState in[tcp_state_Closed,tcp_state_Close_Wait,tcp_state_Closing];
            end;
          stUDP : ;
        end;
      if Leave=false then FD_CLR(fd_array[I-1],exceptfds^);
    end;

  WSASetLastError(Err);
  Count:=0;
  if assigned(readfds) then Inc(Count,readfds^.fd_count);
  if assigned(writefds) then Inc(Count,writefds^.fd_count);
  if assigned(exceptfds) then Inc(Count,exceptfds^.fd_count);
  select:=Count;
end;

function TABISocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
var addr: TSockAddr;
    addrsize: longint;
    Err: longint;
    E: PABISocketEntry;
    size: longint;
begin
  send:=0;
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  case E^.SocketType of
    stTCP :
      begin
        addrsize:=sizeof(addr); fillchar(addr,sizeof(addr),0);
        with TSockAddrIn(addr) do
        begin
          sin_family:=AF_INET;
          sin_port:=0; sin_addr.s_addr:=INADDR_ANY;
        end;
        Err:=WSAOK;
        size:=sendto(s,Buf,len,flags,addr,addrsize);
      end;
    stUDP :
       Err:=WSAEOPNOTSUPP;
  end;
  if Err<>WSAOK then size:=0;
  WSASetLastError(Err);
  send:=size;
end;

function TABISocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr; tolen: longint): longint;
var Err: longint;
    E: PABISocketEntry;
    abiflags: byte;
    size: word;
begin
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  case E^.SocketType of
    stTCP :
     if (E^.State<>ssConnected) then
       Err:=WSAENOTCONN else
     if (Flags and not(0))<>0 then
       Err:=WSAEOPNOTSUPP else
     begin
       abiflags:=0;
{       if (flags and MSG_OOB)<>0 then
         abiflags:=abiflags or tcp_put_UrgentData;}
       abiflags:=abiflags or tcp_put_Push;
       size:=Min(len,High(Size));
       TCPPut(E^.ABISocket,abiflags,Buf,size,timeout_infinite);
       Err:=GetLastABISockError;
     end;
    stUDP :
      begin
        Err:=WSAEOPNOTSUPP;
      end;
  end;
  WSASetLastError(Err);
  if Err<>WSAOK then size:=0;
  sendto:=size;
end;

function TABISocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
begin
  setsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TABISocketsInterface.shutdown(s: TSocket; how: longint): longint;
begin
  shutdown:=ISetLastError(WSAEOPNOTSUPP);
end;

function TABISocketsInterface.socket(af, struct, protocol: longint): TSocket;
var Err: longint;
    Sock: TSocket;
    SType: TSocketType;
    E: PABISocketEntry;
begin
  if af<>AF_INET then
    Err:=WSAEAFNOSUPPORT else
  if (struct<>SOCK_STREAM) and (struct<>SOCK_DGRAM) then
    Err:=WSAESOCKTNOSUPPORT else
  if (protocol<>IPPROTO_UDP) and (protocol<>IPPROTO_TCP) and
     (protocol<>0) then
    Err:=WSAEPROTONOSUPPORT else
  if ( (struct=SOCK_DGRAM) and (protocol<>IPPROTO_UDP) ) or
     ( (struct=SOCK_STREAM) and (protocol<>IPPROTO_TCP) ) then
    Err:=WSAEPROTOTYPE else
  begin
    if protocol=0 then
      case struct of
        SOCK_DGRAM  : protocol:=IPPROTO_UDP;
        SOCK_STREAM : protocol:=IPPROTO_TCP;
      else ;
      end;
    case protocol of
      IPPROTO_UDP : SType:=stUDP;
      IPPROTO_TCP : SType:=stTCP;
    end;
    E:=AddSocket(GenNextSocketID,SType,abi_invalid_socket);
    Sock:=E^.SocketID;
    Err:=WSAOK;
  end;
  WSASetLastError(Err);
  if Err<>WSAOK then Sock:=INVALID_SOCKET;
  socket:=Sock;
end;

function TABISocketsInterface.GetLastABISockError: longint;
var Err: longint;
begin
  case ABIError of
     abi_err_OK                 : Err:=WSAOK;
     abi_err_BadCall            : Err:=WSAEOPNOTSUPP;
     abi_err_Critical           : Err:=-1;
     abi_err_NoHandles          : Err:=WSAENOBUFS;
     abi_err_BadHandle          : Err:=WSAENOTSOCK;
     abi_err_Timeout            : Err:=WSAETIMEDOUT;
     abi_err_BadSession         : Err:=-1;
     abi_err_NotAttached        : Err:=WSAENOTCONN;
     abi_err_AlreadyAttached    : Err:=WSAEINVAL;
     abi_err_BufferOverflow     : Err:=WSAENOBUFS;
  else Err:=WSAEINVAL;
  end;
  GetLastABISockError:=Err;
end;

function TABISocketsInterface.SearchSocket(ASocketID: TSocket): PABISocketEntry;
var P: PABISocketEntry;
begin
  if assigned(Sockets)=false then P:=nil else
    P:=Sockets^.SearchSocket(ASocketID);
  SearchSocket:=P;
end;

function TABISocketsInterface.GenNextSocketID: TSocket;
begin
  Inc(LastSocketID);
  GenNextSocketID:=LastSocketID;
end;

function TABISocketsInterface.AddSocket(ASocketID: TSocket; ASocketType: TSocketType;
         AABISocket: TABISocket): PABISocketEntry;
var E: PABISocketEntry;
begin
  if ASocketID=-1 then ASocketID:=GenNextSocketID;
  E:=NewABISocketEntry(ASocketID,ASocketType,AABISocket);
  Sockets^.Insert(E);
  AddSocket:=E;
end;

function TABISocketsInterface.ChangeSocketID(S: PABISocketEntry; ANewID: TSocket): TSocket;
begin
  ChangeSocketID:=S^.SocketID;
  Sockets^.Delete(S);
  S^.SocketID:=ANewID;
  Sockets^.Insert(S);
end;

procedure TABISocketsInterface.RemoveSocket(S: PABISocketEntry);
begin
  Sockets^.Delete(S);
  DisposeABISocketEntry(S);
end;

{ ------ }
function TABISocketsInterface.WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint;
var Err: longint;
begin
  if SwapW(wVersionRequired)>ABISocketsVersion then
    Err:=WSAVERNOTSUPPORTED else
  begin
{$ifndef FPC}
    if ABIHookTimer then ABIInstallTimer;
{$endif}
    FillChar(FSData,SizeOf(FSData),0);
    with FSData do
    begin
      wVersion:=SwapW(Min(SwapW(wVersionRequired),ABISocketsVersion));
      wHighVersion:=SwapW(ABISocketsVersion);
      StrCopy(szDescription,'Trumpet TCPDRV TCP/IP');
      StrCopy(szSystemStatus,'Running');
      iMaxSockets:=20; { ??? }
      iMaxUdpDg:=ABIDriverInfo.MTU;
      lpVendorInfo:=nil;
    end;
    Err:=WSAOK;
    New(Sockets, Init(20,10));
  end;
  WSASetLastError(Err);
  WSAStartup:=Err;
end;

function TABISocketsInterface.WSACleanup: longint;
var Err: longint;
begin
{$ifndef FPC}
  ABIDeInstallTimer;
{$endif}
  Err:=WSAOK;
  WSASetLastError(Err);
  WSACleanup:=Err;
  if Assigned(Sockets) then Dispose(Sockets, Done); Sockets:=nil;
end;

function CreateInterface(ID: integer): PSocketsInterface; {$ifdef TP}far;{$endif}
begin
  CreateInterface:=New(PABISocketsInterface, Init(ID));
end;

procedure RegisterInterface;
begin
  RegisterSocketsInterface(
    {$ifdef FPC}@{$endif}ABIInit,
    {$ifdef FPC}@{$endif}CreateInterface
  );
end;

END.
{
  $Log: dsiabi.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
