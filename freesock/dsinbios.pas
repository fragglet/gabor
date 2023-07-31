{
    $Id: dsinbios.pas,v 1.0 1999/12/20 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    DOS NetBIOS sockets interface

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
unit DSINBIOS;

interface

uses Objects, Types, Sockets, DSIIntf, NetBIOS;

type
     PNBSocketEntry = ^TNBSocketEntry;
     TNBSocketEntry = object
     private
       SocketID    : TSocket;
       SocketType  : TSocketType;
       NBName      : TNetBIOSName;
       NBNameID    : TNBNameNumber;
       NBSessionID : TNBSessionNumber;
       { --- socket objects --- }
       DataSocket  : PNetBIOSDataSocket;
       ListenSocket: PNetBIOSServerSocket;
       { --- stream objects --- }
       RecvStream  : PSeqMemoryStream;
       SendStream  : PSeqMemoryStream;
       { --- timing data --- }
       LastSendTT  : longint;
       LastDoIOTT  : longint;
       function State: TSocketState;
     end;

     PNBSocketEntryCollection = ^TNBSocketEntryCollection;
     TNBSocketEntryCollection = object(TSortedCollection)
     private
       function  At(Index: sw_Integer): PNBSocketEntry;
       function  Compare(Key1, Key2: Pointer): sw_Integer; virtual;
       function  SearchSocket(ASocketID: TSocket): PNBSocketEntry;
       procedure FreeItem(Item: Pointer); virtual;
     end;

     PNetBIOSSocketsInterface = ^TNetBIOSSocketsInterface;
     TNetBIOSSocketsInterface = object(TSocketsInterface)
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
       function GetHostNamePrefix: string; virtual;
      { ------ }
       function FSAStartup(wVersionRequired: word; var FSData: TFSAData): longint; virtual;
       function FSACleanup: longint; virtual;
       function FSAGetLastError: longint; virtual;
     private
       Sockets: PNBSocketEntryCollection;
       LastSocketID: TSocket;
       function  GenNextSocketID: TSocket;
       function  GetLastNetBIOSSockError: longint;
       function  SearchSocket(ASocketID: TSocket): PNBSocketEntry;
       function  AddSocket(ASocketID: TSocket; ASocketType: TSocketType; const ANBName: TNetBIOSName): PNBSocketEntry;
       function  ChangeSocketID(S: PNBSocketEntry; ANewID: TSocket): TSocket;
       procedure RemoveSocket(S: PNBSocketEntry);
       function  NBToSockAddr(const NBAddr: TNetBIOSName; addr: PSockAddr): longint;
       procedure SockToIPXAddr(addr: PSockAddr; var NBAddr: TNetBIOSName);
       function  CheckRecvData(E: PNBSocketEntry): boolean;
       function  CheckSendData(E: PNBSocketEntry): boolean;
       procedure Flush(E: PNBSocketEntry);
       procedure DoIO(Force: boolean);
       procedure DoIOSock(E: PNBSocketEntry);
     end;

procedure RegisterInterface;

implementation

uses SockCnst,SockUtil;

function NewNBSocketEntry(ASocketID: TSocket; ASocketType: TSocketType;
           const ANBName: TNetBIOSName): PNBSocketEntry;
var P: PNBSocketEntry;
begin
  New(P); FillChar(P^,SizeOf(P^),0);
  with P^ do
  begin
    SocketID:=ASocketID; SocketType:=ASocketType;
    NBName:=ANBName;
    New(RecvStream, Init(1024,1024));
    New(SendStream, Init(1024,1024));
  end;
  NewNBSocketEntry:=P;
end;

procedure DisposeNBSocketEntry(P: PNBSocketEntry);
begin
  if Assigned(P) then
  begin
    if Assigned(P^.DataSocket) then Dispose(P^.DataSocket, Done);
    if Assigned(P^.ListenSocket) then Dispose(P^.ListenSocket, Done);
    if Assigned(P^.RecvStream) then Dispose(P^.RecvStream, Done);
    if Assigned(P^.SendStream) then Dispose(P^.SendStream, Done);
    Dispose(P);
  end;
end;

function TNBSocketEntryCollection.At(Index: sw_Integer): PNBSocketEntry;
begin
  At:=inherited At(Index);
end;

function TNBSocketEntryCollection.Compare(Key1, Key2: Pointer): sw_Integer;
var K1: PNBSocketEntry absolute Key1;
    K2: PNBSocketEntry absolute Key2;
    R: integer;
begin
  if K1^.SocketID<K2^.SocketID then R:=-1 else
  if K1^.SocketID>K2^.SocketID then R:= 1 else
  R:=0;
  Compare:=R;
end;

function TNBSocketEntryCollection.SearchSocket(ASocketID: TSocket): PNBSocketEntry;
var P: PNBSocketEntry;
    E: TNBSocketEntry;
    Idx: sw_integer;
begin
  E.SocketID:=ASocketID;
  if Search(@E,Idx)=false then P:=nil else
    P:=At(Idx);
  SearchSocket:=P;
end;

procedure TNBSocketEntryCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then
    DisposeNBSocketEntry(Item);
end;

function TNetBIOSSocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
begin
end;

function TNetBIOSSocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.closesocket(s: TSocket): longint;
begin
end;

function TNetBIOSSocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
begin
end;

function TNetBIOSSocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.listen(s: TSocket; backlog: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
         var fromlen: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
begin
end;

function TNetBIOSSocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint;
         var addrto: TSockAddr; tolen: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.shutdown(s: TSocket; how: longint): longint;
begin
end;

function TNetBIOSSocketsInterface.socket(af, struct, protocol: longint): TSocket;
begin
end;

function TNetBIOSSocketsInterface.gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt;
var Err: longint;
begin
end;

function TNetBIOSSocketsInterface.gethostbyname(name: PChar): PHostEnt;
var Err: longint;
begin
end;

function TNetBIOSSocketsInterface.gethostname(name: PChar; len: longint): longint;
var Err: longint;
begin
end;

function TNetBIOSSocketsInterface.getservbyport(port: Integer; proto: PChar): PServEnt;
var Err: longint;
begin
end;

function TNetBIOSSocketsInterface.getservbyname(name, proto: PChar): PServEnt;
var Err: longint;
begin
end;

function TNetBIOSSocketsInterface.getprotobynumber(proto: longint): PProtoEnt;
var Err: longint;
begin
end;

function TNetBIOSSocketsInterface.getprotobyname(name: PChar): PProtoEnt;
var Err: longint;
begin
end;

function TNetBIOSSocketsInterface.FSAStartup(wVersionRequired: word; var FSData: TFSAData): longint;
var Err: longint;
    H: PHostEnt;
    Addr: TSockAddr;
begin
  if SwapW(wVersionRequired)>IPXSocketsVersion then
    Err:=FSAVERNOTSUPPORTED else
  begin
    FillChar(FSData,SizeOf(FSData),0);
    with FSData do
    begin
      wVersion:=SwapW(Min(SwapW(wVersionRequired),IPXSocketsVersion));
      wHighVersion:=SwapW(IPXSocketsVersion);
      StrCopy(szDescription,'Novell IPX');
      StrCopy(szSystemStatus,'Running');
      iMaxSockets:=20;
      iMaxUdpDg:=MaxIPXDataSize;
      lpVendorInfo:=nil;
    end;
    Err:=FSAOK;
    New(Sockets, Init(20,10));

    if (IPXGetInternetworkAddr(IPXAddr.Host)=false) or
       (IPXAddr.Host.Network=0) then
      begin
        H:=db_gethostbyname(strIPXHostPrefix+strLocalHost);
        if Assigned(H) then
         if Assigned(H^.h_addr^) then
          begin
            FillChar(Addr,Sizeof(Addr),0);
            Addr.sa_family:=PF_IPX;
            Move(H^.h_addr^^,Addr.sa_data,SizeOf(Addr.sa_data));
            SockToIPXAddr(@Addr,SpecIPXAddr);
            with IPXAddr.Host do
            begin
              if Network=0 then Network:=SpecIPXAddr.Host.Network;
              if (SpecIPXAddr.Host.Node.NodeHiL<>0) or
                 (SpecIPXAddr.Host.Node.NodeHiL<>0) then
                Node:=SpecIPXAddr.Host.Node;
            end;
            IPXSetInternetworkAddr(IPXAddr.Host.Network);
            IPXODISetInternetworkAddr(IPXAddr.Host);
{            IPXGetInternetworkAddr(IPXAddr.Host);}
          end;
      end;

  end;
  SetLastSockError(Err);
  FSAStartup:=Err;
end;

function TNetBIOSSocketsInterface.FSACleanup: longint;
var Err: longint;
begin
  Err:=FSAOK;
  SetLastSockError(Err);
  FSACleanup:=Err;
  if Assigned(Sockets) then Dispose(Sockets, Done); Sockets:=nil;
end;

function TNetBIOSSocketsInterface.FSAGetLastError: longint;
begin
  FSAGetLastError:=GetLastSockError;
end;

function TNetBIOSSocketsInterface.GetHostNamePrefix: string;
begin
  GetHostNamePrefix:=strNetBIOSHostPrefix;
end;

function CreateInterface(ID: integer): PSocketsInterface; far;
begin
  CreateInterface:=New(PNetBIOSSocketsInterface, Init(ID));
end;

procedure RegisterInterface;
begin
  RegisterSocketsInterface(NBInit,CreateInterface);
end;

END.
{
  $Log: dsinbios.pas,v $

  Revision 1.0  1999/12/20 09:46:55  gabor
     Original implementation

}
