uses PCSocks;

var CI: TPCTCPConfigInfo;
    S,S2: TPCTCPSocket;
    Addr: TPCTCPAddr;
    I,L: longint;
    W: word;
    B: array[0..1023] of char;
    St: string;

procedure AsyncHandler; far;
begin
end;

procedure DoRecv;
begin
  W:=SizeOf(B);
  if PCTCP_Read(S,B,W,0)=false then
    writeln('failed to read()')
  else
    begin
      for I:=0 to W-1 do
        write(B[I]);
      writeln;
    end;
end;

BEGIN
  writeln('============================================================');
  if PCTCP_Init=false then
    begin writeln('Can''t find PC/TCP...'); Halt; end;
  if PCTCP_GetConfig(CI)=false then
    writeln('Can''t get config info');
{  PCTCP_SetAsync(true);}
  if PCTCP_GetDesc(S)= false then
    writeln('Can''t allocate desc')
  else
    begin
{      if PCTCP_SetAsyncHandler(S,pctcp_evt_open,@AsyncHandler,0)=false then
         writeln('failed to set async handler');
      if PCTCP_SetAsyncHandler(S,pctcp_evt_receive,@AsyncHandler,0)=false then
         writeln('failed to set async handler');}

      FillChar(Addr,SizeOf(Addr),0);
      Addr.IP:=192 + 234 shl 8 + 116 shl 16 + 50 shl 24;
      Addr.RemotePort:=21;
      if PCTCP_Connect(S,pctcp_prot_TCP,Addr)=false then
        writeln('can''t connect()');
      DoRecv;
      St:='USER ABCD'#13#10;
      W:=length(St);
      if PCTCP_Write(S,St[1],W,0)=false then
        writeln('write() failed')
      else
        begin
          DoRecv;
        end;
{      L:=0;
      if PCTCP_SetOption(S,pctcp_opt_asynchstate,L,SizeOf(L))=false then
        writeln('failed to set option');
      FillChar(Addr,SizeOf(Addr),0);
      Addr.Protocol:=pctcp_prot_TCP;
      Addr.LocalPort:=1024;
      if PCTCP_Listen(S,pctcp_prot_TCP,Addr,S2)=false then
        writeln('Listen failed');}
      PCTCP_Release(S);
    end;
END.