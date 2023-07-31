uses Strings,Sockets;

var FSA: TFSAData;
    H: PHostEnt;
    P: PProtoEnt;
    SE: PServEnt;
    Addr: TSockAddrIPX;
    S,ConnS: TSocket;
    B: array[0..1023] of char;
    W: longint;
    I: integer;
    St: string;

    Proto: word;
    ServerPort: word;
    ServerAddr: TIPXAddr;

BEGIN
  FSAPreferredInterface:=intf_IPX;
  if FSAStartup($101,FSA)<>0 then
    begin writeln('Error initalizing sockets interface: ',FSAGetLastError); Halt(1); end;
  writeln('Using: ',StrPas(FSA.szDescription));
  H:=gethostbyname('*TaUrUs'); if Assigned(H) then Move(H^.h_addr^^,ServerAddr,SizeOf(ServerAddr));
  P:=getprotobyname('spx'); if Assigned(P) then Proto:=P^.p_proto;
  SE:=getservbyname('dap','spx'); if Assigned(SE) then ServerPort:=SE^.s_port;
  if Assigned(H)=false then writeln('can''t find host') else
  if Assigned(P)=false then writeln('can''t find protocol') else
  if Assigned(SE)=false then writeln('can''t find service') else
    begin
      S:=socket(PF_IPX,SOCK_STREAM,Proto);
      if S=INVALID_SOCKET then
        writeln('can''t create socket')
      else
        begin
{          FillChar(Addr,SizeOf(Addr),0);
          Addr.sipx_family:=PF_IPX;
          Addr.sipx_addr:=ServerAddr;
          Addr.sipx_socket:=ServerPort;
          if connect(s,TSockAddr(Addr),SizeOf(Addr))<>0 then
            writeln('failed to connect')}
          FillChar(Addr,SizeOf(Addr),0);
          Addr.sipx_family:=PF_IPX;
          Addr.sipx_socket:=$5555;
          w:=sizeof(addr);
          ConnS:=$ffff;
          if bind(s,TSockAddr(addr),sizeof(addr))<>0 then
            writeln('can''t bind') else
          if listen(s,1)<>0 then
            writeln('can''t listen') else
          ConnS:=accept(s,@TSockAddr(addr),@W);
          if ConnS=INVALID_SOCKET then
            writeln('can''t accept')
          else
          if ConnS<>$ffff then
            begin
              writeln('connected...');
              w:=recv(ConnS,B,SizeOf(B),0);
              write('received ',w,' byte(s) : ');
              if w>0 then
                begin
                  for I:=0 to w-1 do
                    write(B[I]);
                end;
              writeln;

              St:='Ahojjj'; w:=length(St);
              send(ConnS,St[1],w,0);

              writeln('disconnecting...');
              closesocket(conns);
            end;
          closesocket(s);
        end;
    end;

  FSACleanup;
END.