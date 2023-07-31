uses Sockets,MSSocks;

var S: TMSSocket;
    Addr: TSockAddr;
    W: word;
    B: array[0..2047] of char;
    I: integer;

BEGIN
  S:=0;
  if MSSockInit=false then
    begin writeln('Could not initialize Microsoft Sockets API'); Exit; end;
  if mss_socket(AF_INET,SOCK_STREAM,IPPROTO_TCP,S)=false then
    writeln('failed to create a socket (',MSSockError,')')
  else
    begin
      writeln('socket created');
      with Addr do
      begin
        sin_family:=AF_INET;
        sin_port:=4; { htonl(1024) }
        sin_addr.s_addr:=192 + 234 shl 8 + 116 shl 16 + 50 shl 24;
      end;
      if mss_connect(S,@Addr,SizeOf(Addr))=false then
        writeln('failed to connect')
      else
        begin
          writeln('connected');
          w:=sizeOf(B);
          if mss_recv(S,B,w,0) then
            begin
              writeln('receive ok');
              write('>');
              for I:=0 to w-1 do
                write(B[I]);
              writeln('<');
            end;
        end;
    end;
  mss_closesocket(S);

  MSSockDone;
END.