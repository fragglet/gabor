uses Sockets,WSockDos;

var S: TWSockSocket;
    InAddr: TSockAddrIn;

BEGIN
  S:=0;
  if WSockInit=false then
    begin writeln('Could not initiazlie winsock.vxd'); Exit; end;
  if wsock_socket(AF_INET,SOCK_STREAM,{IPPROTO_TCP}0,S)=false then
    writeln('failed to create a socket (',WSockError,')')
  else
    begin
      writeln('socket created');
      FillChar(InAddr,sizeof(InAddr),0);
      with InAddr do
      begin
        sin_family:=AF_INET;
        sin_addr.s_addr:=inet_addr('192.234.116.50');
        sin_port:=htons(21);
      end;
      if wsock_connect(S,@InAddr,SizeOf(InAddr))=false then
        writeln('failed to connect ',WSockError);
    end;
  wsock_close(S);

  WSockDone;
END.