uses Crt,IPXSPX;

const ServerSocketNo = 500;

var S : PSPXDataSocket;
    S2: PSPXListenSocket;
    Addr: TIPXAddr;
    B: array[0..1023] of char;
    W: word;
    I: integer;
    St: string;
    Status: TSPXStatusBuffer;

BEGIN
  if SPXInstalled=false then
    begin writeln('Can''t initialize SPX.'); Halt(1); end;
  writeln('IPX/SPX found.');
  New(S, Init($5555,1500,4,4));
  if S=nil then
    writeln('can''t open socket')
  else
    begin
{        begin
          New(S2,Init($5555,nil,1024,4,4));
          writeln('listening for incoming connections...');
          repeat
          until (S2^.IncomingConnectionAvail) or keypressed;
          if S2^.IncomingConnectionAvail=false then
            writeln('no incoming connection')
          else
            begin
              if S2^.AcceptConnection=false then
                writeln('failed to accept connection')
              else
                begin
                  while (S2^.IsDataAvail=false) and (keypressed=false) do
                    IPXRelinquishControl;
                  W:=SizeOf(B);
                  if S2^.GetData(B,W) then
                    begin
                      for I:=0 to W-1 do
                        write(B[I]);
                      writeln;
                    end;
                  writeln('disconnecting from incoming connection...');
                  Delay(1000);
                end;
            end;
          Dispose(S2, Done);
       end;}
      FillChar(Addr,Sizeof(Addr),0);
      IPXGetInternetworkAddr(Addr);
      Addr.Socket:=ServerSocketNo;
      if S^.Connect(Addr)=false then
        writeln('failed to connect ',S^.LastECBCC)
      else
        begin
          writeln('connected...');
          St:='TESTSTRING';
          W:=length(St);
          S^.SendData(St[1],W);
          while (S^.IsDataAvail=false) and (keypressed=false) do
            IPXRelinquishControl;
          W:=SizeOf(B);
          if S^.GetData(B,W) then
            begin
              for I:=0 to W-1 do
                write(B[I]);
              writeln;
            end;
          writeln('disconnecting...');
          Delay(1000);
        end;
      Dispose(S, Done);
    end;
END.