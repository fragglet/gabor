{
    $Id: dsiipx.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Novell IPX (DOS) interface

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
unit DSIIPX;

interface

uses Objects, Types, Sockets, DSIIntf, Streams, IPXSPX;

const
     IPXSocketsVersion = $0101; { this means 1.1 }

     IPXSOCKMaxDataSize       = 1500;
     IPXSOCKRecvBufCount      = 6;
     IPXSOCKMaxSendBufCount   = 10;
     IPXSOCKMaxSocketDataSize = 4096;
     IPXSOCKUseWatchDogForSPX = true;
     IPXSOCKRetryCountForSPX  = 200;

     IPXSOCKFlushTimeout      = 2; { in 1/18.2 sec }
     IPXSOCKDOIOTimeout       = 2;
     IPXSOCKPushAlways        = true; { always send() immediately }

     ipx_flag_KeepOpenAfterExit  = $00000001;

type
     PIPXSocketEntry = ^TIPXSocketEntry;
     TIPXSocketEntry = object
     private
       SocketID    : TSocket;
       SocketType  : TSocketType;
       IPXSocket   : TIPXSocket;
       { --- bind data --- }
       Port        : word;
       { --- socket objects --- }
       DataSocket  : PSPXSocket;
       ListenSocket: PSPXServerSocket;
       { --- stream objects --- }
       RecvStream  : PSeqMemoryStream;
       SendStream  : PSeqMemoryStream;
       { --- timing data --- }
       LastSendTT  : longint;
       LastDoIOTT  : longint;
       {$ifdef DEBUG}
       TotalBytesSentToIPX: longint;
       TotalBytesSentByApp: longint;
       {$endif}
       Flags       : longint;
       function  State: TSocketState;
       function  IsFlagSet(L: longint): boolean;
       procedure SetFlagState(L: longint; SetIt: boolean);
     end;

     PIPXSocketEntryCollection = ^TIPXSocketEntryCollection;
     TIPXSocketEntryCollection = object(TSortedCollection)
     private
       function  At(Index: sw_Integer): PIPXSocketEntry;
       function  Compare(Key1, Key2: Pointer): sw_Integer; virtual;
       function  SearchSocket(ASocketID: TSocket): PIPXSocketEntry;
       procedure FreeItem(Item: Pointer); virtual;
     end;

     PIPXSocketsInterface = ^TIPXSocketsInterface;
     TIPXSocketsInterface = object(TSocketsInterface)
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
       function gethostbyname(name: PChar): PHostEnt; virtual;
       function gethostname(name: PChar; len: longint): longint; virtual;
      { ------ }
       function GetHostNamePrefix: string; virtual;
      { ------ }
       function WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint; virtual;
       function WSACleanup: longint; virtual;
     private
       Sockets: PIPXSocketEntryCollection;
       LastSocketID: TSocket;
       function  irecvfrom(s: TSocket; var Buf; len, flags: longint; from: PSockAddr;
                 fromlen: plongint): longint;
       function  GenNextSocketID: TSocket;
       function  GetLastIPXSockError: longint;
       function  SearchSocket(ASocketID: TSocket): PIPXSocketEntry;
       function  AddSocket(ASocketID: TSocket; ASocketType: TSocketType; AIPXSocket: TIPXSocket): PIPXSocketEntry;
       function  ChangeSocketID(S: PIPXSocketEntry; ANewID: TSocket): TSocket;
       procedure RemoveSocket(S: PIPXSocketEntry);
       function  IPXToSockAddr(IPXAddr: TIPXAddress; addr: PSockAddr): longint;
       procedure SockToIPXAddr(addr: PSockAddr; var IPXAddr: TIPXAddress);
       function  CheckRecvData(E: PIPXSocketEntry): boolean;
       function  CheckSendData(E: PIPXSocketEntry): boolean;
       procedure Idle;
       procedure Flush(E: PIPXSocketEntry);
       procedure DoIO(Force: boolean);
       procedure DoIOSock(E: PIPXSocketEntry);
     end;

procedure RegisterInterface;

implementation

uses Dos,Strings,pmode,SockCnst,SockUtil,SockDB;

function TIPXSocketEntry.IsFlagSet(L: longint): boolean;
begin
  IsFlagSet:=(Flags and L)=L;
end;

procedure TIPXSocketEntry.SetFlagState(L: longint; SetIt: boolean);
begin
  if SetIt then
    Flags:=Flags or L
  else
    Flags:=Flags and not L;
end;

function TIPXSocketEntry.State: TSocketState;
begin
  State:=ssCreated;
  if Assigned(DataSocket) then
    State:=ssConnected
  else
  if Assigned(ListenSocket) then
    begin
      State:=ssListening;
    end else
  if Assigned(DataSocket) then
    begin
      if DataSocket^.IsConnected then
        State:=ssConnected;
    end
  else
  if Port<>0 then
    State:=ssBound;
end;

function NewIPXSocketEntry(ASocketID: TSocket; ASocketType: TSocketType;
           AIPXSocket: TIPXSocket): PIPXSocketEntry;
var P: PIPXSocketEntry;
begin
  New(P); FillChar(P^,SizeOf(P^),0);
  with P^ do
  begin
    SocketID:=ASocketID; SocketType:=ASocketType;
    IPXSocket:=AIPXSocket;
    New(RecvStream, Init(1024,1024));
    New(SendStream, Init(1024,1024));
  end;
  NewIPXSocketEntry:=P;
end;

procedure DisposeIPXSocketEntry(P: PIPXSocketEntry);
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

function TIPXSocketEntryCollection.At(Index: sw_Integer): PIPXSocketEntry;
begin
  At:=inherited At(Index);
end;

function TIPXSocketEntryCollection.Compare(Key1, Key2: Pointer): sw_Integer;
var K1: PIPXSocketEntry absolute Key1;
    K2: PIPXSocketEntry absolute Key2;
    R: integer;
begin
  if K1^.SocketID<K2^.SocketID then R:=-1 else
  if K1^.SocketID>K2^.SocketID then R:= 1 else
  R:=0;
  Compare:=R;
end;

function TIPXSocketEntryCollection.SearchSocket(ASocketID: TSocket): PIPXSocketEntry;
var P: PIPXSocketEntry;
    E: TIPXSocketEntry;
    Idx: sw_integer;
begin
  E.SocketID:=ASocketID;
  if Search(@E,Idx)=false then P:=nil else
    P:=At(Idx);
  SearchSocket:=P;
end;

procedure TIPXSocketEntryCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then
    DisposeIPXSocketEntry(Item);
end;

function TIPXSocketsInterface.accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket;
var E,NewE: PIPXSocketEntry;
    Err: longint;
    NewSock: TSocket;
    ST: TSPXStatusBuffer;
    C: PSPXServerClientSocket;
    len: longint;
begin
  DoIO(false);
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if E^.SocketType=stIPX then
    Err:=WSAEOPNOTSUPP else
  if E^.State<>ssListening then
    Err:=WSAEINVAL else
  if (Assigned(addr) xor Assigned(addrlen))<>false then
    Err:=WSAEINVAL else { act the same way as WinSock }
  if Assigned(addrlen) and (addrlen^<IPXADDRSIZE) then
    Err:=WSAEFAULT
  else
    begin
      while E^.ListenSocket^.IncomingConnectionAvail=false do;
      C:=E^.ListenSocket^.AcceptConnection(IPXSOCKMaxSendBufCount,E^.IsFlagSet(ipx_flag_KeepOpenAfterExit));
      if Assigned(C)=false  then
        Err:=WSAEFAULT else
      if C^.GetStatus(ST)=false then
        begin
          Err:=WSAEDISCON;
          Dispose(C, Done);
        end
      else
        begin
          NewE:=AddSocket(GenNextSocketID,E^.SocketType,{C^.Socket}0);
          NewE^.DataSocket:=C;
          NewSock:=NewE^.SocketID;

          if assigned(addrlen) then addrlen^:=IPXADDRSIZE;
          if assigned(addr) then
            getpeername(NewE^.SocketID,addr^,len);

          Err:=WSAOK;
        end;
    end;
  ISetLastError(Err);
  if Err<>WSAOK then NewSock:=INVALID_SOCKET;
  accept:=NewSock;
end;

function TIPXSocketsInterface.bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint;
var E: PIPXSocketEntry;
    Err: longint;
    addrin: TSockAddr absolute addr;
begin
  DoIO(false);
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if (E^.State in[ssCreated,ssBound,ssDisconnected])=false then
    Err:=WSAEINVAL else
  if (addr.sa_family<>AF_IPX) and (addr.sa_family<>AF_UNSPEC) then
    Err:=WSAEAFNOSUPPORT
  else
    begin
      E^.Port:=swap(TSockAddrIPX(Addr).sipx_socket);
      Err:=WSAOK;
    end;
  bind:=ISetLastError(Err);
end;

function TIPXSocketsInterface.closesocket(s: TSocket): longint;
var Err: longint;
    E: PIPXSocketEntry;
begin
  DoIO(false);
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK
  else
    with E^ do
    begin
      RemoveSocket(E);
      Err:=WSAOK;
    end;
  closesocket:=ISetLastError(Err);
end;

function TIPXSocketsInterface.connect(s: TSocket; var name: TSockAddr; namelen: longint): longint;
var E: PIPXSocketEntry;
    Err: longint;
    IPXAddr: TIPXAddress;
    namein: TSockAddrIn absolute name;
begin
  DoIO(false);
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if E^.SocketType<>stSPX then
    Err:=WSAEOPNOTSUPP else
  if E^.State=ssConnected then
    Err:=WSAEISCONN else
  if (E^.State in[ssCreated,ssBound])=false then
    Err:=WSAEINVAL else
  if (namelen<IPXADDRSIZE) then
    Err:=WSAEFAULT else
  if (namein.sin_family<>AF_IPX) and (namein.sin_family<>AF_UNSPEC) then
    Err:=WSAEAFNOSUPPORT else
  begin
    SockToIPXAddr(@name,IPXAddr);
    E^.DataSocket:=
      New(PSPXClientSocket,
        Init(E^.Port,E^.IsFlagSet(ipx_flag_KeepOpenAfterExit),IPXAddr,IPXSOCKMaxDataSize,IPXSOCKRecvBufCount,
          IPXSOCKMaxSendBufCount,IPXSOCKUseWatchDogForSPX,IPXSOCKRetryCountForSPX)
      );
    if Assigned(E^.DataSocket)=false then
      Err:=WSAEHOSTUNREACH
    else
      Err:={GetLastIPXSockError}WSAOK;
    if Err=WSAOK then
      begin
{        E^.State:=ssConnected;}
        getsockname(s,name,namelen);
      end;
  end;
  connect:=ISetLastError(Err);
end;

function TIPXSocketsInterface.ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint;
function B2S(B: boolean): string; begin B2S:=RExpand(BoolToStr(B,'true','false'),5); end;
function B2H(B: byte): string; begin B2H:=IntToHex(B,2); end;
function W2H(W: word): string; begin W2H:=IntToHex(W,4); end;
procedure Dump(const S: string);
begin
  TStrProc(arg)(S);
end;
procedure DumpECB(const ECBName: string; E: PECB);
var I: integer;
begin
    Dump(' '+ECBName+' info ');
  with E^.ECB^ do
  begin
    Dump('  InUse : '+IntToHex(InUse,2)+'    Completion : '+IntToHex(Completion,2));
    Dump('  Link  : '+IntToHex(longint(Link),8)+'  FragmentCount : '+IntToStrL(FragmentCount,4));
    for I:=1 to FragmentCount do
    with Fragments[I] do
    begin
    Dump('    Fragment '+IntToStrL(I,2)+'   size : '+IntToStrL(FragSize,5));
    end;
  end;
end;
var Err: longint;
    E: PIPXSocketEntry;
    SST: TSPXStatusBuffer;
    IPXAddr: TIPXAddress;
    SB: TSPXStatusBuffer;
    I: integer;
var St: string;
begin
  DoIO(false);
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK
  else
    begin
      if Cmd=DIODUMP then
        begin
          Dump('Socket ID : '+IntToStr(s)+'   IPX socket : '+IntToHex(E^.IPXSocket,4));
          if Assigned(E^.DataSocket) then St:='data' else
          if Assigned(E^.ListenSocket) then St:='listen' else
          St:='none';
          Dump('Socket type : '+St);
          St:='size: '+IntToStr(E^.RecvStream^.GetSize)+' pos: '+IntToStr(E^.RecvStream^.GetPos);
          Dump('RecvStream  '+St);
          St:='size: '+IntToStr(E^.SendStream^.GetSize)+' pos: '+IntToStr(E^.SendStream^.GetPos);
          Dump('SendStream  '+St);
          if Assigned(E^.DataSocket) then
          with E^.DataSocket^ do
          begin
            Dump('IsConnected : '+B2S(IsConnected)+'  IsDataAvail: '+B2S(IsDataAvail)+'  CanSend: '+B2S(CanSend));
            Dump('GetDataSize : '+IntToStrL(GetDataSize,5));
            if GetStatus(SB)=false then
              Dump('failed to get status')
            else
              with SB do
              begin
                Dump('ConnectionState  : '+B2H(ConnectionState) +'      WatchDogFlag : '+B2H(WatchDogFlag));
                Dump('SourceConnection : '+W2H(SourceConnection)+'    DestConnection : '+W2H(DestConnection));
                Dump('Sequence number  : '+W2H(SequenceNo)      +'     AcknowledgeNo : '+W2H(AcknowledgeNo));
                Dump('MaxRemoteSeqNo   : '+W2H(MaxRemoteSeqNo)  +'       RemoteAckNo : '+W2H(RemoteAcknowledgeNo));
                Dump('Max seq. number  : '+W2H(MaxSeqNo)        +'     RetransmitCnt : '+W2H(RetransmitCount));
                Dump('EstRoundTripDly  : '+W2H(EstRoundTripDelay));
                Dump('RetransmitdPckts : '+W2H(RetransmittedPackets)+'   SuppressedPckts : '+W2H(SuppressedPackets));
              end;
            Dump('== Send ECBs : '+IntToStr(SendECBs^.Count)+' == ');
            for I:=0 to SendECBs^.Count-1 do
             DumpECB('Send ECB '+IntToStr(I),SendECBs^.At(I));
            if TypeOf(E^.DataSocket^)=TypeOf(TSPXClientSocket) then
            with PSPXClientSocket(E^.DataSocket)^ do
            begin
              Dump('== Recv ECBs : '+IntToStr(RecvECBs^.Count)+' == ');
              for I:=0 to RecvECBs^.Count-1 do
               DumpECB('Recv ECB '+IntToStr(I),RecvECBs^.At(I));
            end;
          end;
          Err:=WSAOK;
        end else
      Err:=WSAEOPNOTSUPP;
    end;
  ioctlsocket:=ISetLastError(Err);
end;

function TIPXSocketsInterface.getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var Err: longint;
    E: PIPXSocketEntry;
    ST: TSPXStatusBuffer;
    IPXAddr: TIPXAddress;
begin
  DoIO(false);
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if (E^.SocketType<>stSPX) then
    Err:=WSAEOPNOTSUPP else
  if (namelen<IPXADDRSIZE) then
    Err:=WSAEFAULT else
  if (E^.State<>ssConnected) then
    Err:=WSAENOTCONN else
  if E^.DataSocket^.GetStatus(ST)=false then
    Err:={WSAENETUNREACH}GetLastIPXSockError else
  begin
    namelen:=IPXADDRSIZE;
    with TSockAddrIPX(name) do
    begin
      IPXAddr.Socket:=swap(E^.DataSocket^.RemoteSocket);
      IPXAddr.Host.Network:=ST.DestNetwork;
      IPXAddr.Host.Node:=ST.DestNode;
    end;
    IPXToSockAddr(IPXAddr,@name);
    Err:=WSAOK;
  end;
  getpeername:=ISetLastError(Err);
end;

function TIPXSocketsInterface.getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint;
var Err: longint;
    E: PIPXSocketEntry;
    IPXAddr: TIPXAddress;
begin
  DoIO(false);
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if (namelen<IPXADDRSIZE) then
    Err:=WSAEFAULT else
  case E^.SocketType of
    stSPX :
      begin
        if E^.DataSocket=nil then
          begin
            if E^.State in[ssBound,ssListening] then
              begin
                IPXGetInternetworkAddr(IPXAddr.Host);
                if E^.State=ssBound then
                  IPXAddr.Socket:=E^.Port
                else
                  IPXAddr.Socket:=E^.ListenSocket^.Socket;
                namelen:=IPXToSockAddr(IPXAddr,@name);
                Err:=WSAOK;
              end
            else
              Err:=WSAENOTCONN;
          end
        else
          begin
            IPXGetInternetworkAddr(IPXAddr.Host);
            IPXAddr.Socket:=swap(E^.DataSocket^.Socket);
            namelen:=IPXToSockAddr(IPXAddr,@name);
            Err:=WSAOK;
          end;
      end;
    stIPX :
      begin
        Err:=WSAEOPNOTSUPP;
      end;
  end;
  getsockname:=ISetLastError(Err);
end;

function TIPXSocketsInterface.getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
begin
  DoIO(false);
  getsockopt:=ISetLastError(WSAEOPNOTSUPP);
end;

function TIPXSocketsInterface.listen(s: TSocket; backlog: longint): longint;
var E: PIPXSocketEntry;
    Err: longint;
begin
  DoIO(false);
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  if E^.State=ssConnected then
    Err:=WSAEISCONN else
  if (E^.State in[ssCreated,ssBound])=false then
    Err:=WSAEINVAL else
  begin
    New(E^.ListenSocket,Init(E^.Port,E^.IsFlagSet(ipx_flag_KeepOpenAfterExit),BackLog));
    if Assigned(E^.ListenSocket)=false then
      Err:={GetLastIPXSockError}WSAEFAULT
    else
      Err:=WSAOK;
  end;
  listen:=ISetLastError(Err);
end;

function TIPXSocketsInterface.recv(s: TSocket; var Buf; len, flags: longint): longint;
begin
  recv:=irecvfrom(s,Buf,len,flags,nil,nil);
end;

procedure TIPXSocketsInterface.DoIOSock(E: PIPXSocketEntry);
begin
  Mem[SegB800:2]:=ord('R');
  CheckSendData(E);
  Mem[SegB800:2]:=ord('S');
  CheckRecvData(E);
  Mem[SegB800:2]:=ord('T');
  E^.LastDoIOTT:=GetDosTicks;
end;

procedure TIPXSocketsInterface.DoIO(Force: boolean);
var TT: longint;
procedure DoIOSocket(E: PIPXSocketEntry); {$ifndef FPC}far;{$endif}
begin
  if Force or (GetTickDiff(E^.LastDoIOTT,TT)>=IPXSOCKDoIOTimeout) then
    DoIOSock(E);
end;
begin
  TT:=GetDosTicks;
  IPXRelinquishControl;
  Sockets^.ForEach(@DoIOSocket);
end;

function TIPXSocketsInterface.CheckRecvData(E: PIPXSocketEntry): boolean;
var Full,Avail: boolean;
    P: pointer;
    CurSize,W: word;
begin
  with E^ do
  if DataSocket<>nil then
  with DataSocket^ do
  if IsConnected then
  repeat
    with E^.RecvStream^ do
      if Status<>stOK then Reset;
    Avail:=IsDataAvail;
    if Avail then
      begin
        CurSize:=GetDataSize;
        Full:=(RecvStream^.GetSize+CurSize)>IPXSOCKMaxSocketDataSize;
      end;
    if Avail and (Full=false) then
      begin
        GetMem(P,CurSize);
        W:=CurSize;
        GetData(P^,W);
        RecvStream^.Write(P^,W);
        FreeMem(P,CurSize);
      end;
  until Full or (Avail=false);
  CheckRecvData:=E^.RecvStream^.GetSize>0;
end;

procedure TIPXSocketsInterface.Idle;
begin
  IPXRelinquishControl;
end;

function TIPXSocketsInterface.CheckSendData(E: PIPXSocketEntry): boolean;
var Can,Empty: boolean;
    CurSize,W: word;
    P: pointer;
    LastSize,SendSize: longint;
begin
  Can:=false;
  with E^ do
  if DataSocket<>nil then
  with DataSocket^ do
  if IsConnected then
  begin
    SendSize:=-1;
    repeat
      LastSize:=SendSize;
      Can:=CanSend;
      SendSize:=SendStream^.GetSize;
      Empty:=SendSize=0;
      if Can and (Empty=false) then
        begin
          CurSize:=Min(SendStream^.GetSize,MaxSPXDataSize);
          GetMem(P,CurSize);
          W:=CurSize;
          SendStream^.Read(P^,W);
          if W>0 then
            begin
              LastSendTT:=GetDosTicks;
              SendData(P^,W);
              {$ifdef DEBUG}Inc(E^.TotalBytesSentToIPX,W);{$endif}
            end;
          FreeMem(P,CurSize);
        end
      else
        if Can=false then
          Idle;
      if LastSize=SendSize then
        Can:=false;
    until (Can=false) or Empty;
    Mem[SegB800:2]:=ord('U');
    if (GetElapsedTicks(LastSendTT)>=IPXSOCKFlushTimeout) and Can and
       (SendSize>0) then
         Flush(E);
    Mem[SegB800:2]:=ord('V');
  end;
  CheckSendData:=Can;
end;

procedure TIPXSocketsInterface.Flush(E: PIPXSocketEntry);
var LastSize,CurSize: longint;
    A: byte;
begin
  A:=Mem[SegB800:4];
  if Assigned(E^.SendStream) then
  repeat
    CurSize:=E^.SendStream^.GetSize;
    LastSize:=CurSize;
    if CurSize>0 then
      CheckSendData(E);
    CurSize:=E^.SendStream^.GetSize;
    Inc(Mem[SegB800:4]);
  until (CurSize=LastSize) or (CurSize<=0);
  Mem[SegB800:4]:=A;
end;

function TIPXSocketsInterface.recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr;
         var fromlen: longint): longint;
begin
  recvfrom:=irecvfrom(s,Buf,len,flags,@from,@fromlen);
end;

function TIPXSocketsInterface.irecvfrom(s: TSocket; var Buf; len, flags: longint; from: PSockAddr;
         fromlen: plongint): longint;
var Err: longint;
    E: PIPXSocketEntry;
    size: word;
begin
  DoIO(false);
  Size:=0;
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK else
  case E^.SocketType of
    stSPX :
     if (E^.State<>ssConnected) then
       Err:=WSAENOTCONN else
     if (Flags and not(MSG_OOB))<>0 then
       Err:=WSAEOPNOTSUPP else
     begin
{       CheckRecvData(E);}
       while (CheckRecvData(E)=false) and (E^.State=ssConnected) do { block until data available }
         DoIO(false);
       if E^.State<>ssConnected then
         Err:=WSAENOTCONN
       else
         begin
           Size:=Min(len,High(Size));
           Size:=Min(Size,E^.RecvStream^.GetSize);
           if Size>0 then E^.RecvStream^.Read(Buf,Size);
           Err:={GetLastIPXSockError}WSAOK;
           if (Err=WSAOK) and Assigned(from) then
             begin
               getpeername(s,from^,fromlen^);
             end;
           CheckSendData(E);
         end;
     end;
    stIPX :
      begin
        Err:=WSAEOPNOTSUPP;
      end;
  end;
  ISetLastError(Err);
  if Err<>WSAOK then size:=0;
  irecvfrom:=size;
end;

function TIPXSocketsInterface.select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;
var Err: longint;
function SocketDataAvail(S: TSocket): boolean;
var E: PIPXSocketEntry;
    Avail: boolean;
begin
  Avail:=false;
  Mem[SegB800:2]:=ord('H');
  E:=SearchSocket(s);
  Mem[SegB800:2]:=ord('I');
  if Assigned(E)=false then
    Err:=WSAENOTSOCK else
  if Assigned(E^.ListenSocket) then
    begin
      Mem[SegB800:2]:=ord('J');
      Avail:=E^.ListenSocket^.IncomingConnectionAvail;
      Mem[SegB800:2]:=ord('K');
    end else
  if Assigned(E^.DataSocket) then
    begin
      Mem[SegB800:2]:=ord('L');
      Avail:=(Assigned(E^.RecvStream) and (E^.RecvStream^.GetSize>0)) or
             E^.DataSocket^.IsDataAvail;
      Mem[SegB800:2]:=ord('M');
    end;
  SocketDataAvail:=Avail;
end;
function SocketWriteable(S: TSocket): boolean;
var E: PIPXSocketEntry;
    CanWrite: boolean;
begin
  Canwrite:=false;
  E:=SearchSocket(s);
  if Assigned(E)=false then
    Err:=WSAENOTSOCK else
  if Assigned(E^.ListenSocket) then
    CanWrite:=false else
  if Assigned(E^.DataSocket) then
    CanWrite:=E^.DataSocket^.CanSend;
  SocketWriteable:=CanWrite;
end;
function SocketExcept(S: TSocket): boolean;
var E: PIPXSocketEntry;
    IsErr: boolean;
begin
  IsErr:=false;
  E:=SearchSocket(s);
  if Assigned(E)=false then
    Err:=WSAENOTSOCK else
  if Assigned(E^.ListenSocket) then
    IsErr:=false else
  if Assigned(E^.DataSocket) then
    IsErr:=(E^.DataSocket^.IsConnected=false);
  SocketExcept:=IsErr;
end;
var Count,I: integer;
    S: TSocket;
begin
  Err:=WSAOK;
  Mem[SegB800:2]:=ord('N');
  IPXRelinquishControl;
  Mem[SegB800:2]:=ord('O');
  if assigned(readfds) then
    begin
      I:=0;
      while (I<=readfds^.fd_count-1) and (Err=0) do
      begin
        S:=readfds^.fd_array[I];
        if SocketDataAvail(S) then
          Inc(I)
        else
          FD_CLR(S,readfds^);
        Mem[SegB800:2]:=ord('O');
      end;
    end;
  if assigned(writefds) then
    begin
      I:=0;
      Mem[SegB800:2]:=ord('W');
      while (I<=writefds^.fd_count-1) and (Err=0) do
      begin
        S:=writefds^.fd_array[I];
        if SocketWriteable(S) then
          Inc(I)
        else
          FD_CLR(S,writefds^);
      Mem[SegB800:2]:=ord('X');
      end;
    end;
  if assigned(exceptfds) then
    begin
      I:=0;
      Mem[SegB800:2]:=ord('Y');
      while (I<=exceptfds^.fd_count-1) and (Err=0) do
      begin
        S:=exceptfds^.fd_array[I];
        if SocketExcept(S) then
          Inc(I)
        else
          FD_CLR(S,exceptfds^);
      Mem[SegB800:2]:=ord('Z');
      end;
    end;
  Mem[SegB800:2]:=ord('P');
  DoIO(false);
  Mem[SegB800:2]:=ord('Q');
  ISetLastError(Err);
  Count:=0;
  if assigned(readfds) then Inc(Count,readfds^.fd_count);
  if assigned(writefds) then Inc(Count,writefds^.fd_count);
  if assigned(exceptfds) then Inc(Count,exceptfds^.fd_count);
  select:=Count;
end;

function TIPXSocketsInterface.send(s: TSocket; var Buf; len, flags: longint): longint;
var Err: longint;
    size: longint;
    E: PIPXSocketEntry;
    A: byte;
begin
  Mem[SegB800:2]:=ord('@');
  DoIO(false);
  Mem[SegB800:2]:=ord('A');
  send:=0;
  E:=SearchSocket(s);
  Mem[SegB800:2]:=ord('B');
  if E=nil then
    Err:=WSAENOTSOCK else
  case E^.SocketType of
    stSPX :
      if E^.State<>ssConnected then
        Err:=WSAENOTCONN else
      if (Flags and not(MSG_OOB))<>0 then
        Err:=WSAEOPNOTSUPP else
      begin
        Mem[SegB800:2]:=ord('C');
        repeat
          CheckSendData(E);
          DoIO(false);
          size:=E^.SendStream^.GetSize;
        until (size=0) or (size+len<=IPXSOCKMaxSocketDataSize);
        Mem[SegB800:2]:=ord('D');
        size:=Min(len,IPXSOCKMaxSocketDataSize);
        Mem[SegB800:2]:=ord('E');
        E^.SendStream^.Write(Buf,size);
        Mem[SegB800:2]:=ord('F');
        {$ifdef DEBUG}
        Inc(E^.TotalBytesSentByApp,size);
        {$endif}
        if ((Flags and MSG_OOB)<>0) or (IPXSOCKPushAlways) then
          Flush(E);
        Mem[SegB800:2]:=ord('G');
        Err:=WSAOK;
      end;
    stIPX :
       Err:=WSAEOPNOTSUPP;
  end;
  if Err<>WSAOK then size:=0;
  ISetLastError(Err);
  send:=size;
end;

function TIPXSocketsInterface.sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr; tolen: longint): longint;
var size: word;
    Err: longint;
begin
  DoIO(false);
  Err:=WSAEOPNOTSUPP;
  ISetLastError(Err);
  if Err<>WSAOK then size:=0;
  sendto:=size;
end;

function TIPXSocketsInterface.setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
var Err: longint;
    E: PIPXSocketEntry;
    L: longint;
begin
  DoIO(false);
  E:=SearchSocket(s);
  if E=nil then
    Err:=WSAENOTSOCK
  else
    with E^ do
    begin
      if Level=SOL_SOCKET  then
        begin
          if optname=SO_KEEPOPENAFTEREXIT then
           begin
              if (optval=nil) or (optlen>4) then
                Err:=WSAEINVAL else
              if (E^.ListenSocket<>nil) or (E^.DataSocket<>nil) then
                Err:=WSAEISCONN else
              begin
                L:=0;
                Move(optval^,L,optlen);
                E^.SetFlagState(ipx_flag_KeepOpenAfterExit,optlen<>0);
              end;
           end
          else
            Err:=WSAEOPNOTSUPP;
        end
      else
        Err:=WSAEOPNOTSUPP;
    end;
  setsockopt:=ISetLastError(Err);
end;

function TIPXSocketsInterface.shutdown(s: TSocket; how: longint): longint;
begin
  DoIO(false);
  shutdown:=ISetLastError(WSAEOPNOTSUPP);
end;

function TIPXSocketsInterface.socket(af, struct, protocol: longint): TSocket;
var Err: longint;
    Sock: TSocket;
    SType: TSocketType;
    E: PIPXSocketEntry;
begin
  DoIO(false);
  if af<>AF_IPX then
    Err:=WSAEAFNOSUPPORT else
  if (struct<>SOCK_STREAM) and (struct<>SOCK_DGRAM) then
    Err:=WSAESOCKTNOSUPPORT else
  if (protocol<>NSPROTO_IPX) and (protocol<>NSPROTO_SPX) and
     (protocol<>0) then
    Err:=WSAEPROTONOSUPPORT else
  if ( (struct=SOCK_DGRAM) and (protocol<>NSPROTO_IPX) ) or
     ( (struct=SOCK_STREAM) and (protocol<>NSPROTO_SPX) ) then
    Err:=WSAEPROTOTYPE else
  begin
    if protocol=0 then
      case struct of
        SOCK_DGRAM  : protocol:=NSPROTO_IPX;
        SOCK_STREAM : protocol:=NSPROTO_SPX;
      else ;
      end;
    case protocol of
      NSPROTO_IPX : SType:=stIPX;
      NSPROTO_SPX : SType:=stSPX;
    end;
    E:=AddSocket(GenNextSocketID,SType,IPX_invalid_socket);
    Sock:=E^.SocketID;
    Err:=WSAOK;
  end;
  ISetLastError(Err);
  if Err<>WSAOK then Sock:=INVALID_SOCKET;
  socket:=Sock;
end;

function TIPXSocketsInterface.gethostbyname(name: PChar): PHostEnt;
var Err: longint;
    E: PHostEnt;
    H: THostEntry;
    S: string;
    IPXAddr: TIPXAddress;
    namebuf: array[0..127] of char;
begin
  if (UpCaseStr(StrPas(name))=UpCaseStr(strLocalHost)) and
     IPXGetInternetworkAddr(IPXAddr.Host) then
    begin
      FillChar(H,SizeOf(H),0);
      S:=strLocalHost;
      with H do
      begin
        Name:=@S;
        AddrType:=AF_IPX;
        IPXToSockAddr(IPXAddr,@IPX);
      end;
      E:=buildhostent(@H);
    end
  else
    begin
      StrPCopy(@namebuf,{strIPXHostPrefix}'');
      StrCat(@namebuf,name);
      E:=db_gethostbyname(@namebuf);
    end;
  if Assigned(E) then Err:=WSAOK else Err:=WSANO_DATA;
  ISetLastError(Err);
  gethostbyname:=E;
end;

function TIPXSocketsInterface.gethostname(name: PChar; len: longint): longint;
var Err: longint;
begin
  StrPCopy(name,strLocalHost);
  Err:=WSAOK;
  ISetLastError(Err);
end;


function TIPXSocketsInterface.IPXToSockAddr(IPXAddr: TIPXAddress; addr: PSockAddr): longint;
begin
  with PSockAddrIPX(addr)^ do
  begin
    M2IIPXAddr(IPXAddr,IPXAddr);
    IPXAddr.Socket:={M2IW}(IPXAddr.Socket);
    sipx_family:=AF_IPX;
    sipx_socket:=IPXAddr.Socket;
    sipx_addr.ipx_netnum:=IPXAddr.Host.Network;
    with sipx_addr.ipx_nodenum do
    begin
      node_hil:=IPXAddr.Host.Node.NodeHiL;
      node_low:=IPXAddr.Host.Node.NodeLoW;
    end;
  end;
  IPXToSockAddr:=IPXADDRSIZE;
end;

procedure TIPXSocketsInterface.SockToIPXAddr(addr: PSockAddr; var IPXAddr: TIPXAddress);
begin
  with PSockAddrIPX(addr)^ do
  begin
    IPXAddr.Socket:=sipx_socket;
    IPXAddr.Host.Network:=sipx_addr.ipx_netnum;
    with sipx_addr.ipx_nodenum do
    begin
      IPXAddr.Host.Node.NodeHiL:=node_hil;
      IPXAddr.Host.Node.NodeLoW:=node_low;
    end;
    M2IIPXAddr(IPXAddr,IPXAddr);
    IPXAddr.Socket:={M2IW}(IPXAddr.Socket);
  end;
end;

function TIPXSocketsInterface.GetLastIPXSockError: longint;
var Err: longint;
begin
{  case IPXError of
  else Err:=WSAEINVAL;
  end;}
  GetLastIPXSockError:=Err;
end;

function TIPXSocketsInterface.SearchSocket(ASocketID: TSocket): PIPXSocketEntry;
var P: PIPXSocketEntry;
begin
  if assigned(Sockets)=false then P:=nil else
    P:=Sockets^.SearchSocket(ASocketID);
  SearchSocket:=P;
end;

function TIPXSocketsInterface.GenNextSocketID: TSocket;
begin
  Inc(LastSocketID);
  GenNextSocketID:=LastSocketID;
end;

function TIPXSocketsInterface.AddSocket(ASocketID: TSocket; ASocketType: TSocketType;
         AIPXSocket: TIPXSocket): PIPXSocketEntry;
var E: PIPXSocketEntry;
begin
  if ASocketID=-1 then ASocketID:=GenNextSocketID;
  E:=NewIPXSocketEntry(ASocketID,ASocketType,AIPXSocket);
  Sockets^.Insert(E);
  AddSocket:=E;
end;

function TIPXSocketsInterface.ChangeSocketID(S: PIPXSocketEntry; ANewID: TSocket): TSocket;
begin
  ChangeSocketID:=S^.SocketID;
  Sockets^.Delete(S);
  S^.SocketID:=ANewID;
  Sockets^.Insert(S);
end;

procedure TIPXSocketsInterface.RemoveSocket(S: PIPXSocketEntry);
begin
  Sockets^.Delete(S);
  DisposeIPXSocketEntry(S);
end;

function RunningUnderW95: boolean;
const vxd_id_VXDLoader     = $0027;
function GetVXDEntryPoint(VXDID: word): pointer;
var r: registers;
begin
  r.ax:=$1684; r.bx:=VXDID;
  r.es:=0; r.di:=0;
  realintr($2f,r);
  GetVXDEntryPoint:=MakePtr(r.es,r.di);
end;
begin
  RunningUnderW95:=GetVXDEntryPoint(vxd_id_VXDLoader)<>nil;
end;

{ ------ }
function TIPXSocketsInterface.WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint;
var Err: longint;
    IPXAddr,SpecIPXAddr: TIPXAddress;
    H: PHostEnt;
    Addr: TSockAddr;
begin
  if SwapW(wVersionRequired)>IPXSocketsVersion then
    Err:=WSAVERNOTSUPPORTED else
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
    Err:=WSAOK;
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
            { there's a bug in W9X's IPX interface which causes the Dos
              box to hang, so, we better check for it's presence }
            if RunningUnderW95=false then
              IPXODISetInternetworkAddr(IPXAddr.Host);
{            IPXGetInternetworkAddr(IPXAddr.Host);}
          end;
      end;

  end;
  ISetLastError(Err);
  WSAStartup:=Err;
end;

function TIPXSocketsInterface.WSACleanup: longint;
var Err: longint;
begin
  Err:=WSAOK;
  ISetLastError(Err);
  WSACleanup:=Err;
(*  Sockets^.DeleteAll; { !!! remove this when IPX-socket-problem fixed !!! }*)
  if Assigned(Sockets) then Dispose(Sockets, Done); Sockets:=nil;
end;

function TIPXSocketsInterface.GetHostNamePrefix: string;
begin
  GetHostNamePrefix:=strIPXHostPrefix;
end;

function CreateInterface(ID: integer): PSocketsInterface; {$ifdef TP}far;{$endif}
begin
  CreateInterface:=New(PIPXSocketsInterface, Init(ID));
end;

procedure RegisterInterface;
begin
  RegisterSocketsInterface(
    {$ifdef FPC}@{$endif}IPXInit,
    {$ifdef FPC}@{$endif}CreateInterface
  );
end;

END.
{
  $Log: dsiipx.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
