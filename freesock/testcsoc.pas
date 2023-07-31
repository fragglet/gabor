uses Sockets,CSockDos;

var S: TCSockSocket;

BEGIN
  if csock_Init=false then
    begin writeln('Could not initiazlie sock.vxd'); Exit; end;
  if csock_socket(AF_INET,SOCK_STREAM,IPPROTO_TCP,S)=false then
    writeln('failed to create a socket (',CWSockError,')')
  else
    writeln('socket created');

  csock_Done;
END.