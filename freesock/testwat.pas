uses WatSocks;

var S: TWatSocket;
    Addr: TWatSockAddr;
    B: array[0..2047] of char;
    W: word;
    I: longint;
    St: string;

BEGIN
  if WatInit=false then
   begin writeln('WatTCP sockets not installed...'); Halt; end;
  if Wat_Socket(wat_AF_INET,wat_SOCK_STREAM,0,S)=false then
    begin writeln('failed to create a socket'); Halt; end;

(*  FillChar(Addr,SizeOf(Addr),0);
  Addr.sin_family:=wat_AF_inet;
  Addr.sin_port:=1024;
  if WatBind(S,Addr,SizeOf(Addr))=false then
    begin
      writeln('failed to bind()');
      Halt;
    end;
  if WatListen(S,1)=false then
    begin
      writeln('failed to listen()');
      Halt;
    end;*)

  FillChar(Addr,Sizeof(Addr),0);
  Addr.sin_family:=wat_AF_INET;
  Addr.sin_port:=swap(1024);
  with Addr.sin_addr.s_un_b do begin
    s_b1:=192; s_b2:=234; s_b3:=116; s_b4:=50; end;
  if Wat_Connect(S,@Addr,SizeOf(Addr))=false then
    writeln('failed to connect()')
  else
    begin
      FillChar(Addr,SizeOf(Addr),0);
      W:=SizeOf(Addr); Wat_GetSockName(S,@Addr,W);
      W:=SizeOf(Addr); Wat_GetPeerName(S,@Addr,W);
      W:=SizeOf(B);
      Wat_Recv(S,B,W,0);
      for I:=0 to W-1 do
        write(B[I]);
      writeln;
      St:='hello world'#$0d#$0a;
      W:=length(St);
      Wat_Send(S,St[1],W,0);
    end;
  Wat_CloseSocket(S);
END.