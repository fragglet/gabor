{
    $Id: sockdnet.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Database managment for DOS interfaces

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
unit SOCKDB;

interface

uses Objects,Types,Sockets;

type
    PUnsortedStringCollection = ^TUnsortedStringCollection;
    TUnsortedStringCollection = object(TCollection)
      procedure FreeItem(Item: Pointer); virtual;
    end;

    PHostEntry = ^THostEntry;
    THostEntry = record
      Name      : PString;
      AddrType  : word;
      case byte of
        0 : (IP        : longint);
        1 : (IPX       : TIPXAddr);
    end;

    PProtocolEntry = ^TProtocolEntry;
    TProtocolEntry = record
      Name      : PString;
      Number    : word;
      Aliases   : PUnsortedStringCollection;
    end;

    PServiceEntry = ^TServiceEntry;
    TServiceEntry = record
      Name      : PString;
      Port      : word;
      Proto     : PString;
      Aliases   : PUnsortedStringCollection;
    end;

    PHostCollection = ^THostCollection;
    THostCollection = object(TSortedCollection)
      function  At(Index: sw_integer): PHostEntry;
      function  Compare(Key1, Key2: Pointer): sw_Integer; virtual;
      procedure FreeItem(Item: Pointer); virtual;
      function  SearchByName(const Name: string): PHostEntry;
      function  SearchByIP(const IP: longint): PHostEntry;
      function  SearchByIPX(const IPX: TIPXAddr): PHostEntry;
    end;

    PProtocolCollection = ^TProtocolCollection;
    TProtocolCollection = object(TSortedCollection)
      function  At(Index: sw_Integer): PProtocolEntry;
      function  Compare(Key1, Key2: Pointer): sw_Integer; virtual;
      procedure FreeItem(Item: Pointer); virtual;
      function  SearchByName(const Name: string): PProtocolEntry;
      function  SearchByNumber(const Number: longint): PProtocolEntry;
    end;

    PServiceCollection = ^TServiceCollection;
    TServiceCollection = object(TSortedCollection)
      function  At(Index: sw_Integer): PServiceEntry;
      function  Compare(Key1, Key2: Pointer): sw_Integer; virtual;
      procedure FreeItem(Item: Pointer); virtual;
      function  SearchByName(const Name, Proto: string): PServiceEntry;
      function  SearchByPort(const Port: longint; const Proto: string): PServiceEntry;
    private
      InSearch: boolean;
    end;

procedure InitNetworkData;
procedure DoneNetworkData;

function db_gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt;
function db_gethostbyname(name: PChar): PHostEnt;
function db_getservbyport(port: Integer; proto: PChar): PServEnt;
function db_getservbyname(name, proto: PChar): PServEnt;
function db_getprotobynumber(proto: longint): PProtoEnt;
function db_getprotobyname(name: PChar): PProtoEnt;

function buildhostent(P: PHostEntry): PHostEnt;
function buildservent(P: PServiceEntry): PServEnt;
function buildprotoent(P: PProtocolEntry): PProtoEnt;

const WSAProtocolFile       : string = 'protocol';
      WSAServicesFile       : string = 'services';
      WSAHostsFile          : string = 'hosts';
      WSALMHostsFile        : string = 'lmhosts';
      WSAReadNetFiles       : boolean = true;

implementation

uses Strings,SockCnst,SockUtil;

const
      Hosts     : PHostCollection = nil;
      Protocols : PProtocolCollection = nil;
      Services  : PServiceCollection = nil;

function NewHostEntryIP(const AName: string; AIP: longint): PHostEntry;
var P: PHostEntry;
begin
  New(P); FillChar(P^,SizeOf(P^),0);
  P^.Name:=NewStr(AName); P^.IP:=AIP;
  P^.AddrType:=AF_INET;
  NewHostEntryIP:=P;
end;

function NewHostEntryIPX(const AName: string; AIPX: TIPXAddr): PHostEntry;
var P: PHostEntry;
begin
  New(P); FillChar(P^,SizeOf(P^),0);
  P^.Name:=NewStr(AName); P^.IPX:=AIPX;
  P^.AddrType:=AF_IPX;
  NewHostEntryIPX:=P;
end;

procedure DisposeHostEntry(P: PHostEntry);
begin
  if Assigned(P) then
  begin
    if Assigned(P^.Name) then DisposeStr(P^.Name);
    Dispose(P);
  end;
end;

function NewProtocolEntry(const AName: string; ANumber: word): PProtocolEntry;
var P: PProtocolEntry;
begin
  New(P); FillChar(P^,SizeOf(P^),0);
  P^.Name:=NewStr(AName); P^.Number:=ANumber;
  New(P^.Aliases, Init(10,10));
  NewProtocolEntry:=P;
end;

procedure DisposeProtocolEntry(P: PProtocolEntry);
begin
  if Assigned(P) then
  begin
    if Assigned(P^.Name) then DisposeStr(P^.Name);
    if Assigned(P^.Aliases) then Dispose(P^.Aliases, Done);
    Dispose(P);
  end;
end;

function NewServiceEntry(const AName: string; APort: word; const AProto: string): PServiceEntry;
var P: PServiceEntry;
begin
  New(P); FillChar(P^,SizeOf(P^),0);
  P^.Name:=NewStr(AName); P^.Port:=APort; P^.Proto:=NewStr(AProto);
  New(P^.Aliases, Init(10,10));
  NewServiceEntry:=P;
end;

procedure DisposeServiceEntry(P: PServiceEntry);
begin
  if Assigned(P) then
  begin
    if Assigned(P^.Name) then DisposeStr(P^.Name);
    if Assigned(P^.Proto) then DisposeStr(P^.Proto);
    if Assigned(P^.Aliases) then Dispose(P^.Aliases, Done);
    Dispose(P);
  end;
end;

procedure TUnsortedStringCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then DisposeStr(Item);
end;

function THostCollection.At(Index: sw_Integer): PHostEntry;
begin
  At:=inherited At(Index);
end;

function THostCollection.Compare(Key1, Key2: Pointer): sw_Integer;
var R: integer;
    K1: PHostEntry absolute Key1;
    K2: PHostEntry absolute Key2;
    S1,S2: string;
begin
  S1:=UpcaseStr(K1^.Name^); S2:=UpcaseStr(K2^.Name^);
  if S1<S2 then R:=-1 else
  if S1>S2 then R:= 1 else
  R:=0;
  Compare:=R;
end;

procedure THostCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then DisposeHostEntry(Item);
end;

function THostCollection.SearchByName(const Name: string): PHostEntry;
var E: THostEntry;
    Index: sw_integer;
    P: PHostEntry;
begin
  E.Name:=@Name;
  if Search(@E,Index) then
    P:=At(Index)
  else
    P:=nil;
  SearchByName:=P;
end;

function THostCollection.SearchByIP(const IP: longint): PHostEntry;
var I: sw_integer;
    P,E: PHostEntry;
begin
  P:=nil;
  for I:=0 to Count-1 do
    begin
      E:=At(I);
      if E^.AddrType=AF_INET then
        if E^.IP=IP then
          begin
            P:=E;
            Break;
          end;
    end;
  SearchByIP:=P;
end;

function THostCollection.SearchByIPX(const IPX: TIPXAddr): PHostEntry;
var I: sw_integer;
    P,E: PHostEntry;
begin
  P:=nil;
  for I:=0 to Count-1 do
    begin
      E:=At(I);
      if E^.AddrType=AF_IPX then
        if (E^.IPX.ipx_netnum=IPX.ipx_netnum) and
           ((E^.IPX.ipx_nodenum.node_hil=IPX.ipx_nodenum.node_hil) and
            (E^.IPX.ipx_nodenum.node_low=IPX.ipx_nodenum.node_low))
         then
          begin
            P:=E;
            Break;
          end;
    end;
  SearchByIPX:=P;
end;

function TProtocolCollection.At(Index: sw_Integer): PProtocolEntry;
begin
  At:=inherited At(Index);
end;

function TProtocolCollection.Compare(Key1, Key2: Pointer): sw_Integer;
var R: integer;
    K1: PProtocolEntry absolute Key1;
    K2: PProtocolEntry absolute Key2;
    S1,S2: string;
begin
  S1:=UpcaseStr(K1^.Name^); S2:=UpcaseStr(K2^.Name^);
  if S1<S2 then R:=-1 else
  if S1>S2 then R:= 1 else
  R:=0;
  Compare:=R;
end;

procedure TProtocolCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then DisposeProtocolEntry(Item);
end;

function TProtocolCollection.SearchByName(const Name: string): PProtocolEntry;
var E: TProtocolEntry;
    Index: sw_integer;
    P: PProtocolEntry;
begin
  E.Name:=@Name;
  if Search(@E,Index) then
    P:=At(Index)
  else
    P:=nil;
  SearchByName:=P;
end;

function TProtocolCollection.SearchByNumber(const Number: longint): PProtocolEntry;
var I: sw_integer;
    P,E: PProtocolEntry;
begin
  P:=nil;
  for I:=0 to Count-1 do
    begin
      E:=At(I);
      if E^.Number=Number then
        begin
          P:=E;
          Break;
        end;
    end;
  SearchByNumber:=P;
end;

function TServiceCollection.At(Index: sw_Integer): PServiceEntry;
begin
  At:=inherited At(Index);
end;

function TServiceCollection.Compare(Key1, Key2: Pointer): sw_Integer;
var R: integer;
    K1: PServiceEntry absolute Key1;
    K2: PServiceEntry absolute Key2;
    S1,S2: string;
    P1,P2: string;
begin
  S1:=UpcaseStr(K1^.Name^); S2:=UpcaseStr(K2^.Name^);
  if S1<S2 then R:=-1 else
  if S1>S2 then R:= 1 else
   begin
     P1:=UpcaseStr(K1^.Proto^); P2:=UpcaseStr(K2^.Proto^);
     if InSearch and (P2='') then
       R:=0 else
     if P1<P2 then R:=-1 else
     if P1>P2 then R:= 1 else
     R:=0;
   end;
  Compare:=R;
end;

procedure TServiceCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then DisposeServiceEntry(Item);
end;

function TServiceCollection.SearchByName(const Name, Proto: string): PServiceEntry;
var E: TServiceEntry;
    Index: sw_integer;
    P: PServiceEntry;
begin
  E.Name:=@Name;
  E.Proto:=@Proto;
  InSearch:=true;
  if Search(@E,Index) then
    P:=At(Index)
  else
    P:=nil;
  InSearch:=false;
  SearchByName:=P;
end;

function TServiceCollection.SearchByPort(const Port: longint; const Proto: string): PServiceEntry;
var I: sw_integer;
    P,E: PServiceEntry;
begin
  P:=nil;
  for I:=0 to Count-1 do
    begin
      E:=At(I);
      if (E^.Port=Port) and ((Proto='') or (CompareText(E^.Proto^,Proto)=0)) then
        begin
          P:=E;
          Break;
        end;
    end;
  SearchByPort:=P;
end;

function EatIO: integer;
begin
  EatIO:=IOResult;
end;

const Spaces : set of char = [#32,#0,#255,#9];

function Trim(const S: string): string;
var R,L,Len: integer;
begin
  Len:=length(S);
  L:=1;
  while (L<=Len) and (S[L] in Spaces) do Inc(L);
  R:=Len;
  while (R>0) and (S[R] in Spaces) do Dec(R);
  Trim:=copy(S,L,R-L+1);
end;

function ReadItem(var S: string; var Item: string): boolean;
var P: sw_integer;
begin
  P:=1;
  while (P<=length(S)) and not (S[P] in Spaces) do
    begin
      if S[P]='#' then
        begin
          S:=copy(S,1,P-1);
          Break;
        end;
      Inc(P);
    end;
  Item:=copy(S,1,P-1);
  Delete(S,1,P);
  S:=Trim(S);
  ReadItem:=Item<>'';
end;

procedure ReadHosts;
var f: text;
    S: string;
    Name, AddrS: string;
    IPL: u_long;
    IPX: TIPXAddr;
    E: PHostEntry;
    C: array[0..127] of char;
begin
{$I-}
  Assign(f,WSAHostsFile);
  Reset(f);
  while (eof(f)=false) and (EatIO=0) do
  begin
    readln(f,S);
    if EatIO<>0 then
      Break
    else
     if S<>'' then
      begin
        S:=Trim(S); if copy(S,1,1)='#' then Continue;
        ReadItem(S,AddrS);
        ReadItem(S,Name);
        if copy(Name,1,1)=strIPXHostPrefix then
          { IPX address }
          begin
            IPX:=ipx_addr(StrPCopy(@C,AddrS))^;
            if (Name<>'') and (IPX.ipx_netnum<>-1) then
            begin
              E:=NewHostEntryIPX(Name,IPX);
              Hosts^.Insert(E);
            end;
          end
        else
          { internet address }
          begin
            IPL:=inet_addr(StrPCopy(@C,AddrS));
            if (Name<>'') and (IPL<>INADDR_NONE) then
            begin
              E:=NewHostEntryIP(Name,IPL);
              Hosts^.Insert(E);
            end;
          end;
      end;
  end;
  Close(f);
{$I+}
  EatIO;
end;

procedure ReadProtocols;
var f: text;
    S: string;
    Name, Number, Alias: string;
    NumberW: word;
    CC: integer;
    E: PProtocolEntry;
begin
{$I-}
  Assign(f,WSAProtocolFile);
  Reset(f);
  while (eof(f)=false) and (EatIO=0) do
  begin
    readln(f,S);
    if EatIO<>0 then
      Break
    else
     if S<>'' then
      begin
        S:=Trim(S); if copy(S,1,1)='#' then Continue;
        ReadItem(S,Name);
        ReadItem(S,Number);
        Val(Number,NumberW,CC);
        if (Name<>'') and (CC=0) then
        begin
          E:=NewProtocolEntry(Name,NumberW);
          while ReadItem(S,Alias) do
            E^.Aliases^.Insert(NewStr(Alias));
          Protocols^.Insert(E);
        end;
      end;
  end;
  Close(f);
{$I+}
  EatIO;
end;

procedure ReadServices;
var f: text;
    S: string;
    P: sw_integer;
    Name, PortProto, Alias: string;
    Port: word;
    Proto: string;
    CC: integer;
    E: PServiceEntry;
begin
{$I-}
  Assign(f,WSAServicesFile);
  Reset(f);
  while (eof(f)=false) and (EatIO=0) do
  begin
    readln(f,S);
    if EatIO<>0 then
      Break
    else
     if S<>'' then
      begin
        S:=Trim(S); if copy(S,1,1)='#' then Continue;
        ReadItem(S,Name);
        ReadItem(S,PortProto);
        P:=Pos('/',PortProto); if P=0 then P:=length(S)+1;
        Proto:=copy(PortProto,P+1,255);
        Val(copy(PortProto,1,P-1),Port,CC);
        if (Name<>'') and (CC=0) and (Proto<>'') then
        begin
          E:=NewServiceEntry(Name,Port,Proto);
          while ReadItem(S,Alias) do
            E^.Aliases^.Insert(NewStr(Alias));
          Services^.Insert(E);
        end;
      end;
  end;
  Close(f);
{$I+}
  EatIO;
end;

var
      db_hostent    : thostent; { hostent is the greatest in size, so .. }
      db_servent    : tservent absolute db_hostent; { we can map others on it }
      db_protoent   : tprotoent absolute db_hostent;

const db_scratchpad : pointer = nil;
      db_scratchpadsize = MAXGETHOSTSTRUCT;

procedure InitNetworkData;
begin
  GetMem(db_scratchpad, db_scratchpadsize);
  New(Hosts, Init(50,10));
  New(Protocols, Init(50,10));
  New(Services, Init(50,10));
  Hosts^.Insert(NewHostEntryIP('localhost',inet_addr('127.0.0.1')));
  if WSAReadNetFiles then
  begin
    ReadHosts;
    ReadProtocols;
{    ReadLMHosts;}
    ReadServices;
  end;
end;

procedure DoneNetworkData;
begin
  if Assigned(Hosts) then Dispose(Hosts, Done); Hosts:=nil;
  if Assigned(Protocols) then Dispose(Protocols, Done); Protocols:=nil;
  if Assigned(Services) then Dispose(Services, Done); Services:=nil;
  if Assigned(db_scratchpad) then FreeMem(db_scratchpad, db_scratchpadsize); db_scratchpad:=nil;
end;

function db_adddata(prevptr: pointer; const Data; DataSize: word; var nextptr: pointer): pointer;
begin
  if prevptr=nil then prevptr:=db_scratchpad;
  Move(Data,prevptr^,DataSize);
  if (@nextptr<>nil) then nextptr:=pointer(longint(prevptr)+DataSize);
  db_adddata:=prevptr;
end;

function db_addstr(prevptr: pointer; const S: string; var nextptr: pointer): pointer;
var C: array[0..256] of char;
begin
  db_addstr:=db_adddata(prevptr,StrPCopy(@C,S)^,StrLen(@C)+1,nextptr);
end;

function db_addptr(prevptr: pointer; P: pointer; var nextptr: pointer): pointer;
begin
  db_addptr:=db_adddata(prevptr,P,SizeOf(P),nextptr);
end;

function db_addnil(prevptr: pointer; var nextptr: pointer): pointer;
begin
  db_addnil:=db_addptr(prevptr,nil,nextptr);
end;

function buildhostent(P: PHostEntry): PHostEnt;
var E: PHostEnt;
    B,X: pointer;
begin
  E:=nil;
  if P<>nil then
    begin
      FillChar(db_hostent,sizeof(db_hostent),0);
      FillChar(db_scratchpad^,sizeof(db_scratchpad^),0);
      case P^.AddrType of
        AF_INET :
          with db_hostent do
          begin
            h_name:=db_addstr(nil,P^.Name^,B);
            h_aliases:=nil;
            h_addrtype:=PF_INET;
            h_length:=sizeof(TInAddr);
            h_addr:=db_addnil(B,B);
            db_addnil(B,B);
            db_adddata(B,P^.IP,SizeOf(P^.IP),X);
            db_addptr(h_addr,B,B);
          end;
        AF_IPX :
          with db_hostent do
          begin
            h_name:=db_addstr(nil,P^.Name^,B);
            h_aliases:=nil;
            h_addrtype:=PF_IPX;
            h_length:=sizeof(TIPXAddr);
            h_addr:=db_addnil(B,B);
            db_addnil(B,B);
            db_adddata(B,P^.IPX,SizeOf(P^.IPX),X);
            db_addptr(h_addr,B,B);
          end;
      else {RunError(255)};
      end;
      E:=@db_hostent;
    end;
  buildhostent:=E;
end;

function buildservent(P: PServiceEntry): PServEnt;
var E: PServEnt;
    B: pointer;
    PChars,Aliases: pointer;
    I: integer;
begin
  E:=nil;
  if P<>nil then
    begin
      FillChar(db_servent,sizeof(db_servent),0);
      FillChar(db_scratchpad^,sizeof(db_scratchpad^),0);
      with db_servent do
      begin
        s_name:=db_addstr(nil,P^.Name^,B);
        s_port:=P^.Port;
        s_proto:=db_addstr(B,P^.Proto^,B);
        with P^.Aliases^ do
         if Count>0 then
          begin
            PChars:=B;
            s_aliases:=PChars;
            for I:=0 to Count-1 do
              db_addnil(B,B);
            db_addnil(B,B);
            Aliases:=B;
            for I:=0 to Count-1 do
             begin
               B:=db_addstr(Aliases,PString(At(I))^,Aliases);
               db_addptr(PChars,B,PChars);
             end;
          end;
      end;
      E:=@db_servent;
    end;
  buildservent:=E;
end;

function buildprotoent(P: PProtocolEntry): PProtoEnt;
var E: PProtoEnt;
    B: pointer;
    PChars,Aliases: pointer;
    I: integer;
begin
  E:=nil;
  if P<>nil then
    begin
      FillChar(db_protoent,sizeof(db_protoent),0);
      FillChar(db_scratchpad^,sizeof(db_scratchpad^),0);
      with db_protoent do
      begin
        p_name:=db_addstr(nil,P^.Name^,B);
        p_proto:=P^.Number;
        with P^.Aliases^ do
         begin
           PChars:=B;
           p_aliases:=PChars;
           for I:=0 to Count-1 do
             db_addnil(B,B);
           db_addnil(B,B);
           Aliases:=B;
           for I:=0 to Count-1 do
            begin
              B:=db_addstr(Aliases,PString(At(I))^,Aliases);
              db_addptr(PChars,B,PChars);
            end;
         end;
      end;
      E:=@db_protoent;
    end;
  buildprotoent:=E;
end;

function db_gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt;
var E: PHostEnt;
    P: PHostEntry;
    Err: longint;
begin
  E:=nil;
  Err:=WSAOK;
  if assigned(Hosts) then
   if assigned(addr) and (len=SizeOf(TInAddr)) and (struct=PF_INET) then
    begin
      P:=Hosts^.SearchByIP(plongint(addr)^);
      E:=buildhostent(P);
    end else
   if assigned(addr) and (len=SizeOf(TIPXAddr)) and (struct=PF_IPX) then
    begin
      P:=Hosts^.SearchByIPX(pipxaddr(addr)^);
      E:=buildhostent(P);
    end
   else
     Err:=WSAEPFNOSUPPORT;
  WSASetLastError(Err);
  db_gethostbyaddr:=E;
end;

function db_gethostbyname(name: PChar): PHostEnt;
var E: PHostEnt;
    P: PHostEntry;
begin
  E:=nil;
  if assigned(Hosts) then
   if assigned(name) then
    begin
      P:=Hosts^.SearchByName(StrPas(name));
      E:=buildhostent(P);
    end;
  db_gethostbyname:=E;
end;

function db_getservbyport(port: Integer; proto: PChar): PServEnt;
var E: PServEnt;
    P: PServiceEntry;
begin
  E:=nil;
  if assigned(Services) then
    begin
      P:=Services^.SearchByPort(port,StrPas(proto));
      E:=buildservent(P);
    end;
  db_getservbyport:=E;
end;

function db_getservbyname(name, proto: PChar): PServEnt;
var E: PServEnt;
    P: PServiceEntry;
begin
  E:=nil;
  if assigned(Services) then
    begin
      P:=Services^.SearchByName(StrPas(Name),StrPas(proto));
      E:=buildservent(P);
    end;
  db_getservbyname:=E;
end;

function db_getprotobynumber(proto: longint): PProtoEnt;
var E: PProtoEnt;
    P: PProtocolEntry;
begin
  E:=nil;
  if assigned(Protocols) then
    begin
      P:=Protocols^.SearchByNumber(proto);
      E:=buildprotoent(P);
    end;
  db_getprotobynumber:=E;
end;

function db_getprotobyname(name: PChar): PProtoEnt;
var E: PProtoEnt;
    P: PProtocolEntry;
begin
  E:=nil;
  if assigned(Protocols) then
    begin
      P:=Protocols^.SearchByName(StrPas(Name));
      E:=buildprotoent(P);
    end;
  db_getprotobyname:=E;
end;

END.
{
  $Log: sockdnet.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
