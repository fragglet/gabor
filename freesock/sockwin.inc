{
    $Id: sockwin.inc,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Windows Sockets interface  

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
const
  winsocket = {$ifdef WINSOCK2}'ws2_32.dll'{$else}'wsock32.dll'{$endif};

function accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket; stdcall;
         external    winsocket name 'accept';
function bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint; stdcall;
         external    winsocket name 'bind';
function closesocket(s: TSocket): longint; stdcall;
         external    winsocket name 'closesocket';
function connect(s: TSocket; var name: TSockAddr; namelen: longint): longint; stdcall;
         external    winsocket name 'connect';
function getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint; stdcall;
         external    winsocket name 'getpeername';
function getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint; stdcall;
         external    winsocket name 'getsockname';
function getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint; stdcall;
         external    winsocket name 'getsockopt';
function htonl(hostlong: u_long): u_long; stdcall;
         external    winsocket name 'htonl';
function htons(hostshort: u_short): u_short; stdcall;
         external    winsocket name 'htons';
function inet_addr(cp: PChar): u_long; stdcall;
         external    winsocket name 'inet_addr';
function inet_ntoa(inaddr: TInAddr): pchar; stdcall;
         external    winsocket name 'inet_ntoa';
function ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint; stdcall;
         external    winsocket name 'ioctlsocket';
function listen(s: TSocket; backlog: longint): longint; stdcall;
         external    winsocket name 'listen';
function ntohl(netlong: u_long): u_long; stdcall;
         external    winsocket name 'ntohl';
function ntohs(netshort: u_short): u_short; stdcall;
         external    winsocket name 'ntohs';
function recv(s: TSocket; var Buf; len, flags: longint): longint; stdcall;
         external    winsocket name 'recv';
function recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr; var fromlen: longint): longint; stdcall;
         external    winsocket name 'recvfrom';
function select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): longint; stdcall;
         external    winsocket name 'select';
function send(s: TSocket; var Buf; len, flags: longint): longint; stdcall;
         external    winsocket name 'send';
function sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr; tolen: longint): longint; stdcall;
         external    winsocket name 'sendto';
function setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint; stdcall;
         external    winsocket name 'setsockopt';
function shutdown(s: TSocket; how: longint): longint; stdcall;
         external    winsocket name 'shutdown';
function socket(af, struct, protocol: longint): TSocket; stdcall;
         external    winsocket name 'socket';

function gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt; stdcall;
         external    winsocket name 'gethostbyaddr';
function gethostbyname(name: PChar): PHostEnt; stdcall;
         external    winsocket name 'gethostbyname';
function getprotobyname(name: PChar): PProtoEnt; stdcall;
         external    winsocket name 'getprotobyname';
function getprotobynumber(proto: longint): PProtoEnt; stdcall;
         external    winsocket name 'getprotobynumber';
function getservbyname(name, proto: PChar): PServEnt; stdcall;
         external    winsocket name 'getservbyname';
function getservbyport(port: Integer; proto: PChar): PServEnt; stdcall;
         external    winsocket name 'getservbyport';
function gethostname(name: PChar; len: longint): longint; stdcall;
         external    winsocket name 'gethostname';

function WSAGetLastError: longint; stdcall;
         external    winsocket name 'WSAGetLastError';
procedure WSASetLastError(iError: longint); stdcall;
         external    winsocket name 'WSASetLastError';
function WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint; stdcall;
         external     winsocket name 'WSAStartup';
function WSACleanup: longint; stdcall;
         external     winsocket name 'WSACleanup';

function  WSAIsBlocking: BOOL; stdcall;
         external     winsocket name 'WSAIsBlocking';
function  WSAUnhookBlockingHook: longint; stdcall;
         external     winsocket name 'WSAUnhookBlockingHook';
function  WSASetBlockingHook(lpBlockFunc: TFarProc): TFarProc; stdcall;
         external     winsocket name 'WSASetBlockingHook';
function  WSACancelBlockingCall: longint;
         external     winsocket name 'WSACancelBlockingCall';
function  WSAAsyncGetServByName(HWindow: HWND; wMsg: u_int; name, proto,
            buf: PChar; buflen: longint): THandle; stdcall;
         external     winsocket name 'WSAAsyncGetServByName';
function  WSAAsyncGetServByPort( HWindow: HWND; wMsg, port: u_int; proto,
            buf: PChar; buflen: longint): THandle; stdcall;
         external     winsocket name 'WSAAsyncGetServByPort';
function  WSAAsyncGetProtoByName(HWindow: HWND; wMsg: u_int; name,
            buf: PChar; buflen: longint): THandle; stdcall;
         external     winsocket name 'WSAAsyncGetProtoByName';
function  WSAAsyncGetProtoByNumber(HWindow: HWND; wMsg: u_int; number: longint;
            buf: PChar; buflen: longint): THandle; stdcall;
         external     winsocket name 'WSAAsyncGetProtoByNumber';
function  WSAAsyncGetHostByName(HWindow: HWND; wMsg: u_int; name,
            buf: PChar; buflen: longint): THandle; stdcall;
         external     winsocket name 'WSAAsyncGetHostByName';
function  WSAAsyncGetHostByAddr(HWindow: HWND; wMsg: u_int; addr: PChar; len, struct: longint;
            buf: PChar; buflen: longint): THandle; stdcall;
         external     winsocket name 'WSAAsyncGetHostByAddr';
function  WSACancelAsyncRequest(hAsyncTaskHandle: THandle): longint; stdcall;
         external     winsocket name 'WSACancelAsyncRequest';
function  WSAAsyncSelect(s: TSocket; HWindow: HWND; wMsg: u_int; lEvent: Longint): longint; stdcall;
         external     winsocket name 'WSAAsyncSelect';
function  WSARecvEx(s: TSocket; var buf; len: longint; var flags: longint): longint; stdcall;
         external     winsocket name 'WSARecvEx';

function  TransmitFile(hSocket: TSocket; hFile: THandle; nNumberOfBytesToWrite: DWORD;
  nNumberOfBytesPerSend: DWORD; lpOverlapped: POverlapped;
  lpTransmitBuffers: PTransmitFileBuffers; dwReserved: DWORD): BOOL; stdcall;
         external     winsocket name 'TransmitFile';

function  AcceptEx(sListenSocket, sAcceptSocket: TSocket;
  lpOutputBuffer: Pointer; dwReceiveDataLength, dwLocalAddressLength,
  dwRemoteAddressLength: DWORD; var lpdwBytesReceived: DWORD;
  lpOverlapped: POverlapped): BOOL; stdcall;
         external     winsocket name 'AcceptEx';

procedure GetAcceptExSockaddrs(lpOutputBuffer: Pointer;
  dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: DWORD;
  var LocalSockaddr: TSockAddr; var LocalSockaddrLength: longint;
  var RemoteSockaddr: TSockAddr; var RemoteSockaddrLength: longint); stdcall;
         external     winsocket name 'GetAcceptExSockaddrs';

function __WSAFDIsSet(s:TSocket; var FDSet:TFDSet): Bool; stdcall;
         external winsocket name '__WSAFDIsSet';

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
begin
  FD_ISSET := __WSAFDIsSet(Socket, FDSet);
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

const HexNums: string[16] = '0123456789ABCDEF';

function HexToInt(const S: string): longint;
var I,P: integer;
    R: longint;
begin
  R:=0;
  for I:=1 to length(S) do
  begin
    P:=Pos(Upcase(S[I]),HexNums);
    if P=0 then
      begin
        R:=-1;
        Break;
      end
    else
      R:=R shl 4+(P-1);
  end;
  HexToInt:=R;
end;

function IntToHex(L: longint; MinLen: integer): string;
var S: string;
begin
  S:='';
  if L=0 then
    S:='0'
  else
    begin
      S:='';
      repeat
        S:=HexNums[(L and $0f)+1]+S;
        L:=L shr 4;
      until L=0;
    end;
  while length(S)<MinLen do S:='0'+S;
  IntToHex:=S;
end;

function StrPCat(Dest: PChar; const Source: string): PChar;
var C: array[0..256] of char;
begin
  StrPCopy(@C,Source);
  StrPCat:=StrCat(Dest,@C);
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

function ipx_addr(Addr: PChar): PIPXAddr; stdcall;
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

var AddrBuf : array[0..127] of char;

function ipx_ntoa(const IPXAddr: TIPXAddr): PChar; stdcall;
begin
  FillChar(AddrBuf,Sizeof(AddrBuf),0);
  StrPCat(@AddrBuf,IntToHex(htonl(IPXAddr.ipx_netNum),8));
  StrPCat(@AddrBuf,':');
  StrPCat(@AddrBuf,IntToHex(htonl(IPXAddr.ipx_nodenum.node_hil),8));
  StrPCat(@AddrBuf,IntToHex(htons(IPXAddr.ipx_nodenum.node_low),4));
  ipx_ntoa:=@AddrBuf;
end;


{
  $Log: sockwin.inc,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
