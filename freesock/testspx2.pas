uses Crt,IPXSPX;

var S: PSPXClientSocket;
    L: PSPXServerSocket;
    C: PSPXServerClientSocket;
    Addr: TIPXAddress;
    St: string;
    W: word;
    B: array[0..1023] of char;
    I: longint;

BEGIN
  IPXGetInternetworkAddr(Addr.Host);
  Addr.Socket:=500;
  New(S, Init(0,Addr,1024,4,4));
  if Assigned(S)=false then
    writeln('failed to connect')
  else
    begin
      writeln('connected...');
      Delay(500);
      W:=SizeOf(B);
      if S^.GetData(B,W) then
        begin
          for I:=0 to W-1 do
            write(B[I]);
          writeln;
        end;

{      writeln('disconnecting...');
      Delay(500);
      Dispose(S, Done);}
    end;
  New(L, Init($5555,4));
  if Assigned(L)=false then
    writeln('failed to listen')
  else
    begin
      repeat
        if L^.IncomingConnectionAvail then
          begin
            writeln('accepting connection...');
            C:=L^.AcceptConnection(4);
            if Assigned(C)=false then
              writeln('can''t accept')
            else
              begin
                writeln('connection accepted...');

          St:='TESTSTRING';
          W:=length(St);
          C^.SendData(St[1],W);
          while (C^.IsDataAvail=false) and (keypressed=false) do
            IPXRelinquishControl;
          W:=SizeOf(B);
          if C^.GetData(B,W) then
            begin
              for I:=0 to W-1 do
                write(B[I]);
              writeln;
            end;
          Delay(500);
          C^.GetData(B,W);

                writeln('closing accepted connection...');
                Delay(500);
                Dispose(C, Done);
              end;
          end;
      until {keypressed}C<>nil;
      Dispose(L, Done);
    end;
END.