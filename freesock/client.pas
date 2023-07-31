{
    $Id: client.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Sample client program

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
uses crt,sockets,strings;

const Port = 21; { port to connect to }
      IP   = 192 shl 24 + 234 shl 16 + 116 shl 8 + 50 shl 0; { IP = 192.234.116.50 }
      { ^^^^^^^ place your own server's IP address here ^^^^ }

procedure Fatal(const S: string; ErrCode: longint);
begin
  write('Fatal: ',S);
  if ErrCode<>0 then write(' (',ErrCode,')');
  writeln;
  Halt(1);
end;

var DataSocket   : TSocket;
    FSData	 : TFSAData;
    saddr	 : TSockAddr;
    addrsize     : longint;
    S            : string;
    Disconnected : boolean;
    FD           : TFDSet;
    FDE          : TFDSet;
    TimeVal      : TTimeVal;
    C            : array[0..127] of char;

procedure Receive;
var s: string;
    i: integer;
begin
  repeat
    FD_Zero(FD);
    FD_Set(DataSocket,FD);
    with TimeVal do begin tv_sec:=0; tv_usec:=100; end;
    if select(1,@FD,nil,nil,@TimeVal)=1 then
      begin
        s[0]:=chr(recv(DataSocket,S[1],SizeOf(S)-1,MSG_OOB));
        if S<>'' then
          S:=S;
        for I:=1 to length(S) do
          write(S[I]);
        if S='' then Break;
      end
    else
      Break;
  until 1=2;
end;

BEGIN
  if FSAStartup($0101,FSData)<>FSAOK then
    Fatal('Sockets interface not available.',FSAGetLastError);
  write('Interface found : ');
  writeln(StrPas(@FSData.szDescription));

  gethostname(@C,SizeOf(C));

  DataSocket:=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
  if DataSocket=INVALID_SOCKET then
    Fatal('Can''t open data socket.',FSAGetLastError);

  writeln('Connecting to server...');

  fillchar(saddr,sizeof(saddr),0);
  saddr.sin_family:=AF_INET;
  saddr.sin_addr.s_addr:=htonl(IP);
  saddr.sin_port:=htons(Port);
  if connect(DataSocket,saddr,sizeof(saddr))<>FSAOK then
    writeln('Can''t connect to server (',FSAGetLastError,')')
  else
    begin
      addrsize:=sizeof(saddr); getpeername(DataSocket,saddr,addrsize);
      addrsize:=sizeof(saddr); getsockname(DataSocket,saddr,addrsize);
      writeln('Connection established.');
      writeln('Enter text to transmit (empty line ends session):');
      writeln('-------------------------------------------------');
      repeat
        while keypressed=false do
          Receive;
        readln(S);
        if S<>'' then S:=S+#13#10 else S:=S+'*';

        FD_Zero(FD);
        FD_Set(DataSocket,FD);
        with TimeVal do begin tv_sec:=0; tv_usec:=100; end;
        Disconnected:=(select(1,nil,nil,@FD,@TimeVal)=1) or (FSAGetLastError<>FSAOK);

        if Disconnected=false then
          send(DataSocket,S[1],length(S),0);
        Receive;
      until (S='*') or Disconnected;
      if Disconnected then
        writeln('Connection terminated by remote host')
      else
        writeln('Closing connection');
    end;

  closesocket(DataSocket);
END.

{
  $Log: client.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
