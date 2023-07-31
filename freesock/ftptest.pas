{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Network throughput benchmark program

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
uses crt,strings,Sockets{$ifdef win32},windows{$endif};

const CR        = #$0d;
      LF        = #$0a;
      CRLF      = CR+LF;

      Debug = {false}true;

var s: TSocket;
    PI: TWSAProtocolInfo;
    addr: TSockAddr;
    addrin: tsockaddrin absolute addr;
    C: array[0..256] of char;
    FS: TWSAData;
    FileName,UserName,Password: string;
    LocalIP: string;
    T,Reply: string;
    CC,I: integer;
    W: word;
    OK: boolean;
    B: array[0..4095] of byte;
    Trumpet: boolean;

function GetDosTicks: longint;
{$ifndef Win32}
var TT: longint absolute $40:$6c;
begin
  GetDosTicks:=TT;
end;
{$else}
begin
  GetDosTicks:=(windows.GetTickCount*5484) div 100;
end;
{$endif}

procedure SendCmd(Cmd: string);
begin
  if Debug then writeln('>',Cmd);
  Cmd:=Cmd+CRLF;
  send(s,Cmd[1],length(Cmd),0);
end;

(*function GetReply(var Reply: string; Timeout: longint): integer;
var StartTT: longint;
    CurOfs: integer;
    Code: integer;
    CC: integer;
begin
  repeat
    Reply:='';
    StartTT:=GetDosTicks;
    CurOfs:=1;
    repeat
      CurOfs:=CurOfs+recv(s,Reply[CurOfs],1,0);
      Reply[0]:=chr(CurOfs-1);
    until (copy(Reply,length(Reply),1)=LF) or (Timeout=0) or (GetDosTicks-StartTT>Timeout);
    CC:=Pos(CRLF,Reply); if CC=0 then CC:=Pos(LF,Reply);
    if CC>0 then Delete(Reply,CC,255);
    Code:=-1;
    CC:={Pos(' ',Reply)}4;
    if CC>0 then
      begin
        Val(copy(Reply,1,CC-1),Code,CC);
        if CC<>0 then Code:=-1;
      end;
    GetReply:=Code;
    if Debug and (Reply<>'') then
      writeln(Reply);
  until (Code<0) or (copy(Reply,4,1)<>'-');
end;*)

function StrToInt(const S: string): longint;
var L: longint;
    C: integer;
begin
  Val(S,L,C); if C<>0 then L:=-1;
  StrToInt:=L;
end;

function GetReply(var ReplyString: openstring; GetTimeOut: longint): integer;
var W: word;
    RC: integer;
{    ST: TTCPStatusRec;}
    OK: boolean;
    RFD,EFD: TFDSet;
    CurOfs: integer;
    StartTT: longint;
    TimeVal: TTimeVal;
    Count: integer;
    FirstReply: string;
    Timeout: longint;
const DontCheck = -MaxLongint-1;
begin
  Count:=0;
  repeat
    Inc(Count);
    ReplyString:='<no reply>';
    W:=High(ReplyString); RC:=-1;
    if GetTimeOut<>0 then
      begin
        OK:=true;
        TimeOut:=GetTimeOut;
      end
    else
      begin
        FD_ZERO(RFD); FD_SET(S,RFD);
        FD_ZERO(EFD); FD_SET(S,EFD);
        FillChar(TimeVal,SizeOf(TimeVal),0);
        select(1,@RFD,nil,@EFD,@TimeVal);
        OK:=(WSAGetLastError=0) and (FD_ISSET(s,EFD)=false);
        if OK then
         if FD_ISSET(s,RFD) then
           Timeout:=3*18
         else
           Timeout:=DontCheck;
      end;
    if OK=false then
      RC:=-3 else
    if Timeout<>DontCheck then
    begin
      CurOfs:=1;
  {    StartTT:=GetDosTicks;
      while GetDosTicks-StartTT<3 do;}
      StartTT:=GetDosTicks;
      ReplyString:='';
      repeat
        FD_ZERO(RFD); FD_SET(S,RFD);
        FD_ZERO(EFD); FD_SET(S,EFD);
        FillChar(TimeVal,SizeOf(TimeVal),0);
        select(1,@RFD,nil,@EFD,@TimeVal);
        OK:={(FD_ISSET(S,EFD)=false)}true;
        if OK and FD_ISSET(S,RFD) then
          begin
            CurOfs:=CurOfs+recv(s,ReplyString[CurOfs],{255-CurOfs}1,{MSG_OOB}0);
            ReplyString[0]:=chr(CurOfs-1);
          end;
      until (OK=false) or (copy(ReplyString,length(ReplyString)-1,2)=CRLF) or
            (abs(GetDosTicks-StartTT)>TimeOut) or (TimeOut=0);
      {$ifdef DEBUG}
      if OK=false then
        DebugStr(0,'reply loop exited with error (loop duration='+IntToStr(GetDosTicks-StartTT)+
                 ' ticks, timeout='+IntToStr(Timeout)+' ticks)');
      {$endif}
      if OK then
      begin
        OK:=(copy(ReplyString,length(ReplyString)-1,2)=CRLF);
        {$ifdef DEBUG}
        if OK=false then DebugStr(0,'bad reply (no CRLF)');
        {$endif}
      end;
  {    if OK then
      writeln('Rep in:',GetDosTicks-StartTT,' ',S);}
      if OK then ReplyString:=copy(ReplyString,1,length(ReplyString)-2); { trim CRLF }
      if OK then
        if (ReplyString<>'') and (length(ReplyString)>=3) then
          begin
            RC:=StrToInt(copy(ReplyString,1,3));
            if RC=-1 then
              RC:=-2;
          end;
    end;
    GetReply:=RC;
    if (TimeOut>0) and (Count=1) then
      begin
{        LastReplyCode:=RC;
        if RC<0 then LastReplyText:='' else
          LastReplyText:=copy(ReplyString,5,255);}
      end;
    if Count=1 then FirstReply:=ReplyString;
    if Debug and (ReplyString<>'') then
      writeln(ReplyString);
  until (RC<0) or (copy(ReplyString,4,1)=' ');
  ReplyString:=FirstReply;
end;



function Login: boolean;
var OK: boolean;
    Rep: integer;
begin
  SendCmd('USER '+UserName);
  Rep:=GetReply(Reply,3*18);
  OK:=(Rep=331) or (Rep=230);
  if OK and (Rep=331) then SendCmd('PASS '+Password);
  OK:=OK and (GetReply(Reply,8*18)=230);
  Login:=OK;
end;

function i2s(I: longint): string;
var S: string;
begin
  str(I,S);
  i2s:=S;
end;

function waitforread(s: tsocket; timeout: longint): boolean;
var StartTT: longint;
    rfd: TFDSET;
    tv: ttimeval;
begin
  StartTT:=GetDosTicks;
  repeat
    FillChar(tv,sizeof(tv),0);
    FD_ZERO(rfd); FD_SET(s,rfd);
    OK:=select(1,@rfd,nil,nil,@tv)>0;
  until OK or (timeout=0) or (GetDosTicks-StartTT>timeout);
  waitforread:=OK;
end;

function isclosed(s: tsocket): boolean;
var rfd,efd: TFDSET;
    tv: ttimeval;
begin
  FillChar(tv,sizeof(tv),0);
  FD_ZERO(rfd); FD_SET(s,rfd);
  FD_ZERO(efd); FD_SET(s,efd);
  select(1,@rfd,nil,@efd,@tv);
  isclosed:=(WSAGetLastError<>WSAOK) or ((FD_ISSET(s,rfd)=false) and FD_ISSET(s,efd));
  { ^^^ no data to read but exception occoured }
end;

function CalcBPS(StartTT,EndTT,Size: longint): real;
var R: real;
begin
  if StartTT=EndTT then
    R:=0
  else
    R:=(size/1024/((EndTT-StartTT)/18.2));
  CalcBPS:=R;
end;

var TS: array[0..256] of char;
function TempCopy(const S: string): PChar;
begin
  StrPCopy(@TS,S);
  TempCopy:=@TS;
end;

const NextPort: integer = 2000;

function TransferFile: boolean;
var ds,rs: tsocket;
    addr: tsockaddr;
    addrin: tsockaddrin absolute addr;
    OK: boolean;
    size,w: longint;
    StartTT,EndTT: longint;
begin
  size:=0;
  OK:=false;
  ds:=socket(PF_INET,SOCK_STREAM,IPPROTO_TCP);
  if ds=INVALID_SOCKET then
    writeln('can''t create data socket ',WSAGetLastError)
  else
    begin
      fillchar(addr,sizeof(addr),0);
      with addrin do
      begin
        sin_family:=AF_INET;
        sin_port:=htons(NextPort);
      end;
      Inc(NextPort);
      if bind(ds,addr,sizeof(addr))<>0 then
        writeln('can''t bind() to data socket ',WSAGetLastError) else
      if listen(ds,1)<>0 then
        writeln('can''t listen() on data socket ',WSAGetLastError)
      else
        begin
          w:=sizeof(addr);
          if getsockname(ds,addr,w)<>0 then
            writeln('can''t get local socket name ',WSAGetLastError)
          else
            begin
(*              {!!!!}addrin.sin_addr.s_addr:=inet_addr('127.0.0.1');
              {!!!!}addrin.sin_addr.s_addr:=inet_addr('192.234.116.1');*)
              if LocalIP<>'' then
                 addrin.sin_addr.s_addr:=inet_addr(TempCopy(LocalIP));
              with addrin, sin_addr.s_un_b do
              SendCmd('PORT '+i2s(byte(s_b1))+','+i2s(byte(s_b2))+','+
                      i2s(byte(s_b3))+','+i2s(byte(s_b4))+','+
                      i2s(hi(ntohs(sin_port)))+','+i2s(lo(ntohs(sin_port))));
              if GetReply(Reply,3*18)<>200 then
                writeln('PORT command failed')
              else
                begin
                  SendCmd('RETR '+FileName);
                  if GetReply(Reply,3*18)<>150 then
                    writeln('error accessing file')
                  else
{                    if waitforread(ds,3*18)=false then
                      writeln('can't}
                    begin
                      w:=sizeof(addr); fillchar(addr,sizeof(addr),0);
                      rs:=accept(ds,@addr,@w);
                      if rs=INVALID_SOCKET then
                        writeln('no incoming connection to accept() ',WSAGetLastError)
                      else
                        begin
                          write('starting transfer...',#13);
                          size:=0;
                          StartTT:=GetDosTicks;
                          repeat
                            w:=recv(rs,B,sizeof(B),0);
                            if W<>SOCKET_ERROR then
                            begin
                              size:=size+w;
                              write(size div 1024:5,'kbytes... ');
                              if GetDosTicks<>StartTT then
                                write('(',CalcBPS(StartTT,GetDosTicks,Size):0:1,'kb/sec)');
                              clreol;
                              write(#13);
                            end;
                          until isclosed(rs) or (w<=0) or keypressed;
                          EndTT:=GetDosTicks;
                          if keypressed then
                            begin writeln; writeln('!!!interrupted by user!!!') end
                          else
                            clreol;
                          closesocket(rs);
                          if keypressed=false then
                            OK:=GetReply(Reply,3*18)=226;
                        end;
                    end;
                end;
            end;
        end;
      closesocket(ds);
    end;
  if ok then
    writeln(size,' bytes transferred (',CalcBPS(StartTT,EndTT,Size):0:1,' kb/s)');
  TransferFile:=OK;
end;

procedure Usage;
begin
  writeln('Usage: ftptest <hostip>[:<port>] <filename> [<username> [<password>]] [<local IP address>]');
  Halt(1);
end;

BEGIN
  Randomize;
  NextPort:=4000+random(2000);
  writeln('þ FTPTest v0.9');
  if (ParamCount<2) or (ParamCount>5) then Usage;
  FileName:=ParamStr(2);
  if ParamCount>=3 then
    begin
      UserName:=ParamStr(3);
      if ParamCount>=4 then
        Password:=ParamStr(4);
    end
  else
    begin
      UserName:='anonymous';
      Password:='someone@whatever.com';
    end;
  LocalIP:=ParamStr(5);

  if WSAStartup($101,FS)<>0 then
    begin writeln('Can''t initialize sockets interface. ',WSAGetLastError); Halt(1); end;
  writeln('Using: ',StrPas(@FS.szDescription));
  Trumpet:=Pos('Trumpet',StrPas(@FS.szDescription))>0;

  fillchar(addr,sizeof(addr),0);
  with addrin do
  begin
    sin_family:=AF_INET;
    sin_port:=htons(21);
  end;
  T:=ParamStr(1);
  I:=Pos(':',T);
  if I>0 then
  begin
    Val(copy(T,I+1,255),W,CC);
    if CC>0 then
      begin writeln('error parsing port number'); Halt(1); end;
    addrin.sin_port:=htons(W);
    Delete(T,I,255);
  end;
  StrPCopy(@C,T);
  addrin.sin_addr.s_addr:=inet_addr(@C);
  if addrin.sin_addr.s_addr=INADDR_NONE then
    begin writeln('error parsing ip addr'); Halt(1); end;

  s:=socket(PF_INET,SOCK_STREAM,IPPROTO_TCP);
  if s=INVALID_SOCKET then
    writeln('failed to open a socket ',WSAGetLastError)
  else
    begin
      writeln('trying to connect to ',inet_ntoa(addrin.sin_addr),' at port ',ntohs(addrin.sin_port));
      if connect(s,addr,sizeof(addr))<>0 then
        writeln('failed to connect() ',WSAGetLastError)
      else
        begin
          writeln('connected...');
          if GetReply(Reply,3*18)<>220 then
            writeln('service not ready')
          else
            begin
              if Login=false then
                writeln('failed to log in')
              else
               begin
                 writeln('starting benchmark');
                 repeat
                   OK:=TransferFile;
                   if OK=false then
                     writeln('transfer failed');
                 until (OK=false) or keypressed;
                 while keypressed do readkey;
               end;
            end;
          writeln('disconnecting...');
        end;
      closesocket(s);
    end;

  WSACleanup;
END.