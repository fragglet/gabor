{
    $Id: server.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Sample server program

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
uses sockets,strings;

const Port = 1234; { port to listen for connections on }

procedure Fatal(const S: string; ErrCode: longint);
begin
  write('Fatal: ',S); 
  if ErrCode<>0 then write(' (',ErrCode,')'); 
  writeln;
  Halt(1);
end;

var ListenSocket : TSocket;
    DataSocket   : TSocket;
    FSData	 : TFSAData;
    saddr	 : TSockAddr;
    addrsize	 : longint;
    datasize,i   : longint;
    databuf      : array[0..1023] of char;

BEGIN
  if FSAStartup($0101,FSData)<>FSAOK then 
    Fatal('Sockets interface not available.',FSAGetLastError);
  write('Interface found : ');
  writeln(StrPas(@FSData.szDescription));

  ListenSocket:=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
  if ListenSocket=INVALID_SOCKET then
    Fatal('Can''t open listening socket.',FSAGetLastError);

  writeln('Waiting for incoming connection...');

  fillchar(saddr,sizeof(saddr),0); 
  saddr.sin_family:=AF_INET;
  saddr.sin_port:=htons(Port);
  if bind(ListenSocket,saddr,sizeof(saddr))<>FSAOK then
    writeln('Can''t bind() listening socket (',FSAGetLastError,')')
  else
  if listen(ListenSocket,1)<>FSAOK then
    writeln('Can''t listen() on socket (',FSAGetLastError,')')
  else
    begin
      fillchar(saddr,sizeof(saddr),0); addrsize:=sizeof(saddr);
      DataSocket:=accept(ListenSocket,@saddr,@addrsize);
      if DataSocket=INVALID_SOCKET then
        writeln('Can''t accept() connection (',FSAGetLastError,')')
      else
        begin
          getpeername(DataSocket,saddr,addrsize);
          writeln('Connection established. (',inet_ntoa(saddr.sin_addr),':',ntohs(saddr.sin_port),')');

          repeat
            datasize:=recv(DataSocket,databuf,sizeof(databuf),0);
            if (datasize>1) or ((datasize>0) and (databuf[0]<>'*')) then
             begin
               write('>');
               for i:=0 to datasize-1 do
                 write(databuf[i]);
             end;
          until (datasize>0) and (databuf[datasize-1]='*');

          closesocket(DataSocket);
          writeln('Connection dropped.');
        end;
    end;

  closesocket(ListenSocket);
END.
{
  $Log: server.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
