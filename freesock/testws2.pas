uses Crt,Sockets,WS2Dos;

var S,S2: TWS2Socket;
    InAddr: TSockAddrIn;
    B: array[0..2047] of char;
    I,Size: longint;
    P: longint;
    St: string;
    E: dword;

BEGIN
  S:=0;
  if WS2Init=false then
    begin writeln('Could not initialize wsock2.vxd'); Exit; end;
(*  if ws2_socket(AF_INET,SOCK_STREAM,{IPPROTO_TCP}0,0,0,0,S)=false then*)
  if ws2_socket(AF_INET,SOCK_STREAM,{IPPROTO_TCP}0,$3f9,0,{1}0,S)=false then
    writeln('failed to create a socket (',WS2Error,')')
  else
    begin
{      ws2_asyncselect(S,0,0,0);}
{      ws2_getsockprotocol(S,P);}
      writeln('socket created');

{      FillChar(InAddr,sizeof(InAddr),0);
      with InAddr do
      begin
        sin_family:=AF_INET;
        sin_port:=htons(1502);
      end;

      if ws2_bind(s,@InAddr,sizeof(InAddr))=false then
        writeln('failed to bind ',WS2Error) else
      if ws2_listen(s,1)=false then
        writeln('failed to listen ',WS2Error)
      else
        begin
          size:=sizeof(InAddr);
          if ws2_accept(s,@InAddr,size,s2)=false then
            writeln('failed to accept ',WS2Error)
          else
           while ws2_selectsocket(s,FD_CONNECT)=0 do;
        end};

{      Size:=sizeof(B);
      if ws2_recv(S,@B,Size,0,0)=false then
        writeln('failed to read ',WS2Error);}

      FillChar(InAddr,sizeof(InAddr),0);
      with InAddr do
      begin
        sin_family:=AF_INET;
        sin_addr.s_addr:=inet_addr('192.234.116.1');
        sin_port:=htons({80}1234);
      end;

{      ws2_connect(S,@InAddr,16,@E);}

      if ws2_connect(S,@InAddr,16,@E)=false then
        writeln('connect failed... ',WS2Error);

      if (WS2Error=$ffff) or (WS2Error=WSAEWOULDBLOCK) then
        while ws2_selectsocket(s,FD_CONNECT)=0 do;
      if (WS2Error<>0) then
        writeln('failed to connect ',WS2Error)
      else
        begin
          writeln('connected to host...');
          ws2_getsockprotocol(s,Size);
          St:='Hello world!';
          Size:=length(St);
          if ws2_send(S,@St[1],Size,0)=false then
            writeln('failed to send ',WS2Error);


          Delay(1000);

{        S:=$C1500000;
        repeat}


          Size:=sizeof(B);
          if ws2_recv(S,@B,Size,0,0)=false then
            writeln('failed to read ',WS2Error)
          else
            begin
              write('Received:');
              for I:=0 to Size-1 do
                write(B[I]);
              writeln;
            end;
{         if WS2Error<>10038 then
           begin
             writeln('error is:',WS2Error);
             readln;
           end;

        if (S mod 1000)=0 then
          write(S,#13);

        Inc(S);
      until S=MaxLongint;}

        end;
    end;
  ws2_close(S);
  writeln('socket closed...');

  WS2Done;
END.