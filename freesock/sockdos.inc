{
    $Id: sockdos.inc,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Generic DOS sockets interface

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

{ directives used to avoid compiling/linking of never used interface code }

{.$DEFINE NOABISOCKS}   { Trumpet ABI (TCPDRV.EXE) interface            }
{.$DEFINE NOIPXSOCKS}   { Novell IPX (IPXODI.COM,PDIPX.COM) interface   }
{.$DEFINE NOMSSOCKS}    { Microsoft LAN Manager (SOCKETS.EXE) interface }
{$DEFINE NONETBIOS}    { NetBIOS (INT 5ch) interface                   }
{.$DEFINE NONWSOCKS}    { Novell TCP/IP (TCPIP.EXE/TCPIP.NLM) interface }
{.$DEFINE NOPCSOCKS}    { PC/TCP (???DRV.EXE) interface                 }
{.$DEFINE NOVSLSOCKS}   { VSL (Virtual Sockets Library) interface       }
{$DEFINE NOWATSOCKS}   { Waterloo TCP TSR (WATTSR.EXE) interface       }
{.$DEFINE NOWSOCKS}     { Windows Sockets VXD (WSOCK.VXD) interface     }
{.$DEFINE NOWS2SOCKS}   { Windows Sockets 2 VXD (WSOCK2.VXD) interface  }

uses Objects,SockCnst,SockUtil,SockDB,
     {$ifndef NOABISOCKS}DSIABI  ,{$endif}
     {$ifndef NOIPXSOCKS}DSIIPX  ,{$endif}
     {$ifndef NOMSSOCKS }DSIMSSck,{$endif}
     {$ifndef NONETBIOS }DSINBIOS,{$endif}
     {$ifndef NONWSOCKS }DSINW   ,{$endif}
     {$ifndef NOPCSOCKS }DSIPCTCP,{$endif}
     {$ifndef NOWATSOCKS}DSIWAT  ,{$endif}
     {$ifndef NOVSLSOCKS}DSIVSL  ,{$endif}
     {$ifndef NOWSOCKS  }DSIWSOCK,{$endif}
     {$ifndef NOWS2SOCKS}DSIWS2  ,{$endif}
     DSIIntf;

const
     FSSocketsVersion = $101;

type
     PSocketEntry = ^TSocketEntry;
     TSocketEntry = record
       Socket          : TSocket;
       InterfaceID     : integer;
       InterfaceSocket : TSocket;
     end;

     PSocketCollection = ^TSocketCollection;
     TSocketCollection = object(TSortedCollection)
       function  Compare(Key1, Key2: Pointer): sw_Integer; virtual;
       function  At(Index: sw_Integer): PSocketEntry;
       procedure FreeItem(Item: Pointer); virtual;
       function  SearchSocket(Socket: TSocket): PSocketEntry;
       function  LookupSocketInfo(Socket: TSocket; var InterfaceID: integer; var InterfaceSocket: TSocket): boolean;
     end;

     PSocketsInterfaceCollection = ^TSocketsInterfaceCollection;
     TSocketsInterfaceCollection = object(TSortedCollection)
       function  Compare(Key1, Key2: Pointer): sw_Integer; virtual;
       function  At(Index: sw_Integer): PSocketsInterface;
       function  SearchInterfaceByID(ID: integer): PSocketsInterface;
     end;

const
     Interfaces    : PSocketsInterfaceCollection = nil;
     GlobalSockets : PSocketCollection           = nil;

     WSAStartupFlag: longint                     = 0;
     WSALastError  : longint                     = WSAOK;
     LastSocketID  : longint                     = 0;

function NewSocketEntry(ASocket: TSocket; AInterfaceID: integer; AInterfaceSocket: TSocket): PSocketEntry;
var P: PSocketEntry;
begin
  New(P); FillChar(P^,Sizeof(P^),0);
  with P^ do
  begin
    Socket:=ASocket; InterfaceID:=AInterfaceID; InterfaceSocket:=AInterfaceSocket;
  end;
  NewSocketEntry:=P;
end;

procedure DisposeSocketEntry(P: PSocketEntry);
begin
  if Assigned(P) then Dispose(P);
end;

function TSocketCollection.Compare(Key1, Key2: Pointer): sw_Integer;
var K1: PSocketEntry absolute Key1;
    K2: PSocketEntry absolute Key2;
    R: integer;
begin
  if K1^.Socket<K2^.Socket then R:=-1 else
  if K1^.Socket>K2^.Socket then R:= 1 else
  R:=0;
  Compare:=R;
end;

function TSocketCollection.At(Index: sw_Integer): PSocketEntry;
begin
  At:=inherited At(Index);
end;

procedure TSocketCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then DisposeSocketEntry(Item);
end;

function TSocketCollection.SearchSocket(Socket: TSocket): PSocketEntry;
var E: TSocketEntry;
    Index: sw_integer;
    P: PSocketEntry;
begin
  FillChar(E,SizeOf(E),0);
  E.Socket:=Socket;
  if Search(@E,Index)=false then P:=nil else
    P:=At(Index);
  SearchSocket:=P;
end;

function TSocketCollection.LookupSocketInfo(Socket: TSocket; var InterfaceID: integer; var InterfaceSocket: TSocket): boolean;
var E: PSocketEntry;
    OK: boolean;
begin
  E:=SearchSocket(Socket);
  OK:=Assigned(E);
  if OK=false then
    begin
      InterfaceID:=-1;
      InterfaceSocket:=INVALID_SOCKET;
    end
  else
    begin
      InterfaceID:=E^.InterfaceID;
      InterfaceSocket:=E^.InterfaceSocket;
    end;
  LookupSocketInfo:=OK;
end;

function TSocketsInterfaceCollection.Compare(Key1, Key2: Pointer): sw_Integer;
var K1: PSocketsInterface absolute Key1;
    K2: PSocketsInterface absolute Key2;
    R: integer;
begin
  if K1^.InterfaceID<K2^.InterfaceID then R:=-1 else
  if K1^.InterfaceID>K2^.InterfaceID then R:= 1 else
  R:=0;
  Compare:=R;
end;

function TSocketsInterfaceCollection.At(Index: sw_Integer): PSocketsInterface;
begin
  At:=inherited At(Index);
end;

function TSocketsInterfaceCollection.SearchInterfaceByID(ID: integer): PSocketsInterface;
var Index: sw_integer;
    I: TSocketsInterface;
    P: PSocketsInterface;
begin
  I.Init(ID);
  if Search(@I,Index)=false then P:=nil else
    P:=At(Index);
  SearchInterfaceByID:=P;
end;

function FindSocketEntry(Socket: TSocket): PSocketEntry;
var E: PSocketEntry;
begin
  if Assigned(GlobalSockets)=false then E:=nil else
    E:=GlobalSockets^.SearchSocket(Socket);
  FindSocketEntry:=E;
end;

function FindSocket(Socket: TSocket; var Intf: PSocketsInterface; var IntfSocket: TSocket): boolean;
var OK: boolean;
    IID: integer;
begin
  OK:=Assigned(GlobalSockets);
  if OK then OK:=GlobalSockets^.LookupSocketInfo(Socket,IID,IntfSocket);
  if OK then
    begin
      Intf:=Interfaces^.SearchInterfaceByID(IID);
      OK:=(Intf<>nil);
    end;
  if OK=false then begin Intf:=nil; IntfSocket:=INVALID_SOCKET; end;
  FindSocket:=OK;
end;

function AddSocket(Intf: PSocketsInterface; IntfSocket: TSocket): TSocket;
var IP: PSocketsInterface;
    IS: TSocket;
    P: PSocketEntry;
begin
  repeat
    Inc(LastSocketID);
  until (FindSocket(LastSocketID,IP,IS)=false) and (LastSocketID<>INVALID_SOCKET);
  P:=NewSocketEntry(LastSocketID,Intf^.InterfaceID,IntfSocket);
  GlobalSockets^.Insert(P);
  AddSocket:=P^.Socket;
end;

procedure RemoveSocket(ASocket: TSocket);
var P: PSocketEntry;
begin
  P:=GlobalSockets^.SearchSocket(ASocket);
  if Assigned(P) then
    GlobalSockets^.Free(P);
end;

procedure InitInterfaces;
begin
  New(Interfaces, Init(10,10));
  New(GlobalSockets, Init(100,100));
end;

procedure DoneInterfaces;
begin
  if Assigned(Interfaces) then Dispose(Interfaces, Done); Interfaces:=nil;
  if Assigned(GlobalSockets) then Dispose(GlobalSockets, Done); GlobalSockets:=nil;
end;

function inet_addr(cp: PChar): u_long; {PInAddr;}  { TInAddr }
var addr: u_long;
    S: string[30];
    Octets: array[1..4] of longint;
    B: byte;
    OctetCount: integer;
    P,CC: integer;
begin
  addr:=INADDR_NONE;
  if Assigned(cp) then
    begin
      FillChar(Octets,SizeOf(Octets),0);
      S:=StrPas(cp);
      OctetCount:=0;
      while (OctetCount<=5) and (S<>'') do
      begin
        P:=Pos('.',S); if P=0 then P:=length(S)+1;
        Val(copy(S,1,P-1),B,CC);
        Delete(S,1,P);
        if CC=0 then
          begin
            Inc(OctetCount);
            Octets[OctetCount]:=B;
          end
        else
          begin OctetCount:=-1; Break; end;
      end;
      case OctetCount of
        4 : addr:=htonl(Octets[1] shl 24 + Octets[2] shl 16 + Octets[3] shl 8 + Octets[4]);
      end;
    end;
  inet_addr:=addr;
end;

var AddrBuf : array[0..127] of char;

function inet_ntoa(inaddr: TInAddr): PChar;
var S: string[20];
begin
  with inaddr.S_un_b do
  S:=IntToStr(ord(s_b1))+'.'+IntToStr(ord(s_b2))+'.'+IntToStr(ord(s_b3))+'.'+IntToStr(ord(s_b4));
  StrPCopy(@AddrBuf,S);
  inet_ntoa:=@AddrBuf;
end;

var  IPXNN: Sockets.TIPXNodeNum;

function ipx_nodenum(S: string): PIPXNodeNum;
var LoS,HiS: string;
begin
  FillChar(IPXNN,Sizeof(IPXNN),0);
  if length(S)<=4 then
    begin
      LoS:=S;
      HiS:='';
    end
  else
    begin
      LoS:=copy(S,length(S)-3,4);
      HiS:=copy(S,1,length(S)-4);
    end;
  IPXNN.node_low:=ntohs(HexToInt(LoS));
  if HiS<>'' then
    IPXNN.node_hil:=ntohl(HexToInt(HiS));
  ipx_nodenum:=@IPXNN;
end;

var IPXA: Sockets.TIPXAddr;

function ipx_addr(Addr: PChar): PIPXAddr;
var S: string;
    P: integer;
begin
  S:=StrPas(Addr);
  FillChar(IPXA,SizeOf(IPXA),0);
  P:=Pos(':',S);
  if P=0 then
    IPXA.ipx_nodenum:=ipx_nodenum(S)^
  else
    begin
      IPXA.ipx_netnum:=ntohl(HexToInt(copy(S,1,P-1)));
      IPXA.ipx_nodenum:=ipx_nodenum(copy(S,P+1,length(S)))^;
    end;
  ipx_addr:=@IPXA;
end;

function ipx_ntoa(const IPXAddr: TIPXAddr): PChar;
begin
  FillChar(AddrBuf,Sizeof(AddrBuf),0);
  StrPCat(@AddrBuf,IntToHex(htonl(IPXAddr.ipx_netNum),8));
  StrPCat(@AddrBuf,':');
  StrPCat(@AddrBuf,IntToHex(htonl(IPXAddr.ipx_nodenum.node_hil),8));
  StrPCat(@AddrBuf,IntToHex(htons(IPXAddr.ipx_nodenum.node_low),4));
  ipx_ntoa:=@AddrBuf;
end;

function ISetLastError(iError: longint): longint;
begin
  WSASetLastError(iError);
  if iError=WSAOK then
    iError:=0
  else
    iError:=SOCKET_ERROR;
  ISetLastError:=iError;
end;

function accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
var Err: longint;
    SocketsInterface: PSocketsInterface;
    NewSock: TSocket;
begin
  NewSock:=INVALID_SOCKET;
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       NewSock:=SocketsInterface^.accept(s,addr,addrlen);
       if NewSock<>INVALID_SOCKET then
         begin
           NewSock:=AddSocket(SocketsInterface,NewSock);
           Err:=WSAOK;
         end
       else
         Err:=SocketsInterface^.WSAGetLastError;
     end;
  if Err<>WSAOK then NewSock:=INVALID_SOCKET;
  WSASetLastError(Err);
  accept:=NewSock;
end;

function bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
var Err: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       if SocketsInterface^.bind(s,addr,namelen)=SOCKET_ERROR then
         Err:=SocketsInterface^.WSAGetLastError
       else
         Err:=WSAOK;
     end;
  bind:=ISetLastError(Err);
end;

function closesocket(s: TSocket): longint;
var Err: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       if SocketsInterface^.closesocket(s)=SOCKET_ERROR then
         Err:=SocketsInterface^.WSAGetLastError
       else
         begin
           Err:=WSAOK;
           RemoveSocket(s);
         end;
     end;
  closesocket:=ISetLastError(Err);
end;

function connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
var Err: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       if SocketsInterface^.connect(s,name,namelen)=SOCKET_ERROR then
         Err:=SocketsInterface^.WSAGetLastError
       else
         Err:=WSAOK;
     end;
  connect:=ISetLastError(Err);
end;

function ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
var Err: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       if SocketsInterface^.ioctlsocket(s,cmd,arg)=SOCKET_ERROR then
         Err:=SocketsInterface^.WSAGetLastError
       else
         Err:=WSAOK;
     end;
  ioctlsocket:=ISetLastError(Err);
end;

function getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var Err: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       if SocketsInterface^.getpeername(s,name,namelen)=SOCKET_ERROR then
         Err:=SocketsInterface^.WSAGetLastError
       else
         Err:=WSAOK;
     end;
  getpeername:=ISetLastError(Err);
end;

function getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var Err: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       if SocketsInterface^.getsockname(s,name,namelen)=SOCKET_ERROR then
         Err:=SocketsInterface^.WSAGetLastError
       else
         Err:=WSAOK;
     end;
  getsockname:=ISetLastError(Err);
end;

function getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
var Err: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       if SocketsInterface^.getsockopt(s,level,optname,optval,optlen)=SOCKET_ERROR then
         Err:=SocketsInterface^.WSAGetLastError
       else
         Err:=WSAOK;
     end;
  getsockopt:=ISetLastError(Err);
end;

function htonl(hostlong: u_long): u_long;
begin
  htonl:=swapl(hostlong);
end;

function htons(hostshort: u_short): u_short;
begin
  htons:=swapw(hostshort);
end;

function ntohl(netlong: u_long): u_long;
begin
  ntohl:=swapl(netlong);
end;

function ntohs(netshort: u_short): u_short;
begin
  ntohs:=swapw(netshort);
end;

function listen(s: TSocket; backlog: longint): longint;
var Err: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       if SocketsInterface^.listen(s,backlog)=SOCKET_ERROR then
         Err:=SocketsInterface^.WSAGetLastError
       else
         Err:=WSAOK;
     end;
  listen:=ISetlastError(Err);
end;

function recv(s: TSocket; var Buf; len, flags: longint): longint;
var Err: longint;
    Size: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       Size:=SocketsInterface^.recv(s,Buf,len,flags);
       Err:=SocketsInterface^.WSAGetLastError;
     end;
  if ISetlastError(Err)=SOCKET_ERROR then Size:=SOCKET_ERROR;
  recv:=Size;
end;

function recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr; var fromlen: longint): longint;
var Err: longint;
    Size: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       Size:=SocketsInterface^.recvfrom(s,Buf,len,flags,from,fromlen);
       Err:=SocketsInterface^.WSAGetLastError;
     end;
  if ISetlastError(Err)=SOCKET_ERROR then Size:=SOCKET_ERROR;
  recvfrom:=Size;
end;

function select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
var Err,Count: longint;
    S: TSocket;
    SocketsInterface: PSocketsInterface;
begin
  {
    Warning!!! Currently there's no provision for supporting select() on
    sockets originating from DIFFERENT interfaces in a single call.
    This should be solved in the near future...
  }
  Count:=SOCKET_ERROR;
  if nfds=0 then nfds:=FD_SETSIZE;
  s:=INVALID_SOCKET;

  if assigned(readfds) and (readfds^.fd_count>0) then
    s:=readfds^.fd_array[0] else
  if assigned(writefds) and (writefds^.fd_count>0) then
    s:=writefds^.fd_array[0] else
  if assigned(exceptfds) and (exceptfds^.fd_count>0) then
    s:=exceptfds^.fd_array[0];

  if s=INVALID_SOCKET then
    Err:=WSAEINVAL else
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       Count:=SocketsInterface^.select(nfds,readfds,writefds,exceptfds,timeout);
       Err:=SocketsInterface^.WSAGetLastError;
     end;
  if ISetlastError(Err)=SOCKET_ERROR then Count:=SOCKET_ERROR;
  select:=Count;
end;

function send(s: TSocket; var Buf; len, flags: longint): longint;
var Err: longint;
    Size: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       Size:=SocketsInterface^.send(s,Buf,len,flags);
       Err:=SocketsInterface^.WSAGetLastError;
     end;
  if ISetlastError(Err)=SOCKET_ERROR then Size:=SOCKET_ERROR;
  send:=Size;
end;

function sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr; tolen: longint): longint;
var Err: longint;
    Size: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       Size:=SocketsInterface^.sendto(s,Buf,len,flags,addrto,tolen);
       Err:=SocketsInterface^.WSAGetLastError;
     end;
  if ISetlastError(Err)=SOCKET_ERROR then Size:=SOCKET_ERROR;
  sendto:=Size;
end;

function setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
var Err: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       if SocketsInterface^.setsockopt(s,level,optname,optval,optlen)=SOCKET_ERROR then
         Err:=SocketsInterface^.WSAGetLastError
       else
         Err:=WSAOK;
     end;
  setsockopt:=ISetLastError(Err);
end;

function shutdown(s: TSocket; how: longint): longint;
var Err: longint;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
   if FindSocket(s,SocketsInterface,s)=false then
     Err:=WSAENOTSOCK
   else
     begin
       if SocketsInterface^.shutdown(s,how)=SOCKET_ERROR then
         Err:=SocketsInterface^.WSAGetLastError
       else
         Err:=WSAOK;
     end;
  shutdown:=ISetLastError(Err);
end;

function socket(af, struct, protocol: longint): TSocket;
var Sock: TSocket;
    Err: longint;
    I: integer;
    SocketsInterface: PSocketsInterface;
begin
  Sock:=INVALID_SOCKET;
  if assigned(Interfaces)=false then
    Err:=WSANOTINITIALISED
  else
    begin
      for I:=0 to Interfaces^.Count-1 do
        begin
          SocketsInterface:=Interfaces^.At(I);
          Sock:=SocketsInterface^.socket(af,struct,protocol);
          if Sock<>INVALID_SOCKET then
            Break;
        end;
      if Sock<>INVALID_SOCKET then
        begin
          Sock:=AddSocket(SocketsInterface,Sock);
          Err:=WSAOK;
        end
      else
        Err:=SocketsInterface^.WSAGetLastError;
    end;
  if Err<>WSAOK then Sock:=INVALID_SOCKET;
  WSASetLastError(Err);
  socket:=Sock;
end;

function gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt;
var P: PHostEnt;
    Err: longint;
    I: integer;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces) then
    begin
      Err:=WSANO_DATA;
      P:=db_gethostbyaddr(addr,len,struct);
      if Assigned(P) then
        Err:=WSAOK
      else
        for I:=0 to Interfaces^.Count-1 do
          begin
            SocketsInterface:=Interfaces^.At(I);
            P:=SocketsInterface^.gethostbyaddr(addr,len,struct);
            if Assigned(P)=false then
              Err:=SocketsInterface^.WSAGetLastError
            else
              begin
                Err:=WSAOK;
                Break;
              end;
          end;
    end
  else
    begin
      Err:=WSANOTINITIALISED;
      P:=nil;
    end;
  WSASetLastError(Err);
  gethostbyaddr:=P;
end;

function gethostbyname(name: PChar): PHostEnt;
var P: PHostEnt;
    Err: longint;
    I: integer;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces) then
    begin
      Err:=WSANO_DATA;
      P:=db_gethostbyname(name);
      if Assigned(P) then
        Err:=WSAOK
      else
        for I:=0 to Interfaces^.Count-1 do
          begin
            SocketsInterface:=Interfaces^.At(I);
            P:=SocketsInterface^.gethostbyname(name);
            if Assigned(P)=false then
              Err:=SocketsInterface^.WSAGetLastError
            else
              begin
                Err:=WSAOK;
                Break;
              end;
          end;
    end
  else
    begin
      Err:=WSANOTINITIALISED;
      P:=nil;
    end;
  WSASetLastError(Err);
  gethostbyname:=P;
end;

function gethostname(name: PChar; len: longint): longint;
var Err: longint;
    L: longint;
    I: integer;
    SocketsInterface: PSocketsInterface;
begin
  if assigned(Interfaces) then
    begin
      Err:=WSANO_DATA; L:=0;
      for I:=0 to Interfaces^.Count-1 do
        begin
          SocketsInterface:=Interfaces^.At(I);
          L:=SocketsInterface^.gethostname(name,len);
          if L>0 then
            begin
              Err:=WSAOK;
              Break;
            end;
        end;
      if L=0 then
        if len<=length(strLocalHost)+1 then
          begin
            L:=length(strLocalHost)+1;
            StrPCopy(name,strLocalHost);
          end
        else
          Err:=WSAEFAULT;
    end
  else
    begin
      Err:=WSANOTINITIALISED;
      L:=0;
    end;
  WSASetLastError(Err);
  gethostname:=L;
end;

function getservbyport(port: Integer; proto: PChar): PServEnt;
var P: PServEnt;
    Err: longint;
begin
  if assigned(Interfaces) then
    begin
      Err:=WSANO_DATA;
      P:=db_getservbyport(port,proto);
      if Assigned(P) then
        Err:=WSAOK;
    end
  else
    begin
      Err:=WSANOTINITIALISED;
      P:=nil;
    end;
  WSASetLastError(Err);
  getservbyport:=P;
end;

function getservbyname(name, proto: PChar): PServEnt;
var P: PServEnt;
    Err: longint;
begin
  if assigned(Interfaces) then
    begin
      Err:=WSANO_DATA;
      P:=db_getservbyname(name,proto);
      if Assigned(P) then
        Err:=WSAOK;
    end
  else
    begin
      Err:=WSANOTINITIALISED;
      P:=nil;
    end;
  WSASetLastError(Err);
  getservbyname:=P;
end;

function getprotobynumber(proto: longint): PProtoEnt;
var P: PProtoEnt;
    Err: longint;
begin
  if assigned(Interfaces) then
    begin
      Err:=WSANO_DATA;
      P:=db_getprotobynumber(proto);
      if Assigned(P) then
        Err:=WSAOK;
    end
  else
    begin
      Err:=WSANOTINITIALISED;
      P:=nil;
    end;
  WSASetLastError(Err);
  getprotobynumber:=P;
end;

function getprotobyname(name: PChar): PProtoEnt;
var P: PProtoEnt;
    Err: longint;
begin
  if assigned(Interfaces) then
    begin
      Err:=WSANO_DATA;
      P:=db_getprotobyname(name);
      if Assigned(P) then
        Err:=WSAOK;
    end
  else
    begin
      Err:=WSANOTINITIALISED;
      P:=nil;
    end;
  WSASetLastError(Err);
  getprotobyname:=P;
end;

procedure FD_CLR(Socket: TSocket; var FDSet: TFDSet);
var
  I: Integer;
begin
  I := 0;
  while I < FDSet.fd_count do
  begin
    if FDSet.fd_array[I] = Socket then
    begin
      while I < FDSet.fd_count - 1 do
      begin
        FDSet.fd_array[I] := FDSet.fd_array[I + 1];
        Inc(I);
      end;
      Dec(FDSet.fd_count);
      Break;
    end;
    Inc(I);
  end;
end;

function FD_ISSET(Socket: TSocket; var FDSet: TFDSet): Boolean;
var IsSet: boolean;
    I: u_int;
begin
  IsSet:=false; I:=0;
  while (IsSet=false) and (I<FDSet.fd_count) do
  begin
    IsSet:=(FDSet.fd_array[I]=Socket);
    Inc(I);
  end;
  FD_ISSET := IsSet;
end;

procedure FD_SET(Socket: TSocket; var FDSet: TFDSet);
begin
  if FDSet.fd_count < FD_SETSIZE then
  begin
    FDSet.fd_array[FDSet.fd_count] := Socket;
    Inc(FDSet.fd_count);
  end;  
end;

procedure FD_ZERO(var FDSet: TFDSet);
begin
  FDSet.fd_count := 0;
end;

procedure FD_COPY(var SrcSet: TFDSet; var DestSet: TFDSet);
var I: u_int;
begin
  DestSet.fd_count:=SrcSet.fd_count;
  for I:=1 to SrcSet.fd_count do
    DestSet.fd_array[I-1]:=SrcSet.fd_array[I-1];
end;

function WSACleanup: longint;
var Err: longint;
    I: integer;
    SocketsInterface: PSocketsInterface;
begin
  if WSAStartupFlag=0 then
    Err:=WSANOTINITIALISED
  else
   begin
    Dec(WSAStartupFlag);
    if WSAStartupFlag>0 then
      Err:=WSAOK
    else
      begin
        Err:=WSAOK;
        if assigned(Interfaces) then
          begin
            for I:=Interfaces^.Count-1 downto 0 do
              begin
                SocketsInterface:=Interfaces^.At(I);
                {Err:=}SocketsInterface^.WSACleanup;
              end;
            DoneInterfaces;
            DoneNetworkData;
          end;
      end;
   end;
  WSACleanup:=Err;
end;

function WSAGetLastError: longint;
var Err: longint;
begin
  if assigned(Interfaces)=false then
    Err:=WSASYSNOTREADY
  else
    Err:=WSALastError;
  WSAGetLastError:=Err;
end;

procedure WSASetLastError(iError: longint);
begin
  WSALastError:=iError;
end;

function WSAIsBlocking: BOOL;
begin
  WSAIsBlocking:=false;
end;

function WSAUnhookBlockingHook: longint;
begin
  WSAUnhookBlockingHook:=ISetLastError(WSAEOPNOTSUPP);
end;

function WSASetBlockingHook(lpBlockFunc: TFarProc): TFarProc;
begin
  WSASetLastError(WSAEOPNOTSUPP);
  WSASetBlockingHook:=nil;
end;

function WSACancelBlockingCall: longint;
begin
  WSACancelBlockingCall:=ISetLastError(WSAEOPNOTSUPP);
end;

function WSAAsyncGetServByName(HWindow: HWND; wMsg: u_int; name, proto, buf: PChar; buflen: longint): Types.THandle;
begin
  WSASetLastError(WSAEOPNOTSUPP);
  WSAAsyncGetServByName:=0;
end;

function WSAAsyncGetServByPort(HWindow: HWND; wMsg, port: u_int; proto, buf: PChar; buflen: longint): Types.THandle;
begin
  WSASetLastError(WSAEOPNOTSUPP);
  WSAAsyncGetServByPort:=0;
end;

function WSAAsyncGetProtoByName(HWindow: HWND; wMsg: u_int; name, buf: PChar; buflen: longint): Types.THandle;
begin
  WSASetLastError(WSAEOPNOTSUPP);
  WSAAsyncGetProtoByName:=0;
end;

function WSAAsyncGetProtoByNumber(HWindow: HWND; wMsg: u_int; number: longint; buf: PChar; buflen: longint): Types.THandle;
begin
  WSASetLastError(WSAEOPNOTSUPP);
  WSAAsyncGetProtoByNumber:=0;
end;

function WSAAsyncGetHostByName(HWindow: HWND; wMsg: u_int; name, buf: PChar; buflen: longint): Types.THandle;
begin
  WSASetLastError(WSAEOPNOTSUPP);
  WSAAsyncGetHostByName:=0;
end;

function WSAAsyncGetHostByAddr(HWindow: HWND; wMsg: u_int; addr: PChar; len, struct: longint;
          buf: PChar; buflen: longint): Types.THandle;
begin
  WSASetLastError(WSAEOPNOTSUPP);
  WSAAsyncGetHostByAddr:=0;
end;

function WSACancelAsyncRequest(hAsyncTaskHandle: Types.THandle): longint;
begin
  WSACancelAsyncRequest:=ISetLastError(WSAEOPNOTSUPP);
end;

function WSAAsyncSelect(s: TSocket; HWindow: HWND; wMsg: u_int; lEvent: Longint): longint;
begin
  WSAAsyncSelect:=ISetLastError(WSAEOPNOTSUPP);
end;

function WSARecvEx(s: TSocket; var buf; len: longint; var flags: longint): longint;
begin
  WSASetLastError(WSAEOPNOTSUPP);
  WSARecvEx:=0;
end;

function __WSAFDIsSet(s: TSOcket; var FDSet: TFDSet): Bool;
begin
  __WSAFDIsSet:=FD_ISSET(s,FDSet);
end;

function TransmitFile(hSocket: TSocket; hFile: Types.THandle; nNumberOfBytesToWrite: DWORD;
  nNumberOfBytesPerSend: DWORD; lpOverlapped: POverlapped;
  lpTransmitBuffers: PTransmitFileBuffers; dwReserved: DWORD): BOOL;
begin
  WSASetLastError(WSAEOPNOTSUPP);
  TransmitFile:=false;
end;


function AcceptEx(sListenSocket, sAcceptSocket: TSocket;
  lpOutputBuffer: Pointer; dwReceiveDataLength, dwLocalAddressLength,
  dwRemoteAddressLength: DWORD; var lpdwBytesReceived: DWORD;
  lpOverlapped: POverlapped): BOOL;
begin
  WSASetLastError(WSAEOPNOTSUPP);
  AcceptEx:=false;
end;


procedure GetAcceptExSockaddrs(lpOutputBuffer: Pointer;
  dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: DWORD;
  var LocalSockaddr: TSockAddr; var LocalSockaddrLength: longint;
  var RemoteSockaddr: TSockAddr; var RemoteSockaddrLength: longint);
begin
  WSASetLastError(WSAEOPNOTSUPP);
  LocalSockaddrLength:=0;
  RemoteSockaddrLength:=0;
end;

procedure RegisterStandardInterfaces;
begin
  {$ifndef NOABISOCKS}DSIABI.RegisterInterface;{$endif}
  {$ifndef NOIPXSOCKS}DSIIPX.RegisterInterface;{$endif}
  {$ifndef NOMSSOCKS }DSIMSSCK.RegisterInterface;{$endif}
  {$ifndef NONETBIOS }DSINBIOS.RegisterInterface;{$endif}
  {$ifndef NONWSOCKS }DSINW.RegisterInterface;{$endif}
  {$ifndef NOPCSOCKS }DSIPCTCP.RegisterInterface;{$endif}
  {$ifndef NOVSLSOCKS}DSIVSL.RegisterInterface;{$endif}
  {$ifndef NOWATSOCKS}DSIWAT.RegisterInterface;{$endif}
  {$ifndef NOWSOCKS  }DSIWSOCK.RegisterInterface;{$endif}
  {$ifndef NOWS2SOCKS}DSIWS2.RegisterInterface;{$endif}
end;

function WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint;
var Err: longint;
    I,ID: integer;
    II: TSocketsInterfaceInfo;
    SocketsInterface: PSocketsInterface;
    NetDataInited: boolean;
    MinHighVersion,MinMaxSockets,MinMaxUdpDg: word;
begin
  if WSAStartupFlag>0 then
    Err:=WSAOK
  else
    begin
      NetDataInited:=false;
      MinHighVersion:=High(MinHighVersion); MinMaxSockets:=High(MinMaxSockets);
      MinMaxUdpDg:=High(MinMaxUdpDg);

      RegisterStandardInterfaces;
      InitInterfaces;

      ID:=0;
      for I:=0 to GetRegisteredInterfaceCount-1 do
        if GetRegisteredInterfaceInfo(I,II) then
          if II.DetectProc{$ifdef FPC}(){$endif} then
            begin
              Inc(ID);
              SocketsInterface:=II.CreateProc(ID);
              if Assigned(SocketsInterface) then
                begin
                  if NetDataInited=false then
                  begin
                    InitNetworkData;
                    NetDataInited:=true;
                  end;
                  Err:=SocketsInterface^.WSAStartup(wVersionRequired,FSData);
                  if Err=WSAOK then
                    begin
                      Interfaces^.Insert(SocketsInterface);
                      if swapw(FSData.wHighVersion)<swapw(MinHighVersion) then
                        MinHighVersion:=FSData.wHighVersion;
                      if FSData.iMaxSockets<MinMaxSockets then
                        MinMaxSockets:=FSData.iMaxSockets;
                      if FSData.iMaxUdpDg<MinMaxUdpDg then
                        MinMaxUdpDg:=FSData.iMaxUdpDg;
                    end
                  else
                    Dispose(SocketsInterface, Done);
                end;
            end;

      if Interfaces^.Count=0 then
        DoneInterfaces;

      if assigned(Interfaces) then
        begin
          if Interfaces^.Count>1 then
            begin
              FillChar(FSData,SizeOf(FSData),0);
              with FSData do
              begin
                wVersion:=SwapW(Min(SwapW(wVersionRequired),FSSocketsVersion));
                wHighVersion:=MinHighVersion;
                StrCopy(szDescription,'FreeSock multiprotocol stack');
                StrCopy(szSystemStatus,'Running');
                iMaxSockets:=MinMaxSockets;
                iMaxUdpDg:=MinMaxUdpDg;
                lpVendorInfo:=nil;
              end;
            end;
          Err:=WSAOK;
        end
      else
        Err:=WSASYSNOTREADY;
    end;
  if Err=WSAOK then Inc(WSAStartupFlag);
  WSAStartup:=Err;
end;

{
  $Log: sockdos.inc,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
