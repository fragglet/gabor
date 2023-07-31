uses VSLSocks,Sockets;

procedure Fatal(const S: string);
begin
  writeln(s);
  halt(1);
end;

var S: TVSLSocket;
    Addr: TSockAddrIn;
    VSLAddr: TVSLSockAddr absolute Addr;
    B: array[0..2047] of char;
    C: array[0..127] of char;
    W: word;
    HE: TVSLHostEnt;

BEGIN
  if VSLInit=false then
    Fatal('can''t find socket library');
  writeln('VSL found.');
  vsl_gethostname(@C,sizeof(C));
  if vsl_gethostbyname(@C,HE) then
    W:=W;
  if vsl_socket(AF_INET,SOCK_STREAM,IPPROTO_TCP,S)=false then
    writeln('failed to create socket ',VSLError)
  else
    begin
      writeln('socket created');
      fillchar(addr,sizeof(addr),0);
      with addr do
      begin
        sin_family:=AF_INET;
        sin_port:=htons(21);
        sin_addr.s_addr:=inet_addr('127.0.0.1');
      end;
      if vsl_connect(s,vsladdr,sizeof(vsladdr))=false then
        writeln('failed to connect ',VSLError)
      else
        begin
          writeln('connected');
          fillchar(vsladdr,sizeof(vsladdr),0);
          w:=sizeof(vsladdr);
          vsl_getsockname(s,vsladdr,w);
          vsl_getpeername(s,vsladdr,w);
          w:=sizeof(B);
          if vsl_recv(s,B,w,0)=false then
            writeln('recv failed ',VSLError)
          else
            begin
            end;
        end;
      vsl_closesocket(S);
    end;
  VSLDone;
END.