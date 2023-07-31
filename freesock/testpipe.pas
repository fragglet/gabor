uses Dos,LMPipes;

var S : string;
    C : array[1..16000] of char;
    W : word;
    f: file;
    r: registers;

BEGIN
{  if DosWaitNmPipe('\\.\pipe\lanman',2*1000)=false then
    writeln('failed to connect to pipe (',PipeError,')')
  else
    writeln('pipe found');
  Exit;}

  S:='\\.\pipe\teszt';
  r.ah:=$6c; r.al:=0; r.bx:=7; r.cx:=0; r.dx:=$10;
  r.ds:=seg(S[1]); r.si:=ofs(S[1]);
  MsDos(r);
  Exit;

  W:=sizeof(C);
  S:='Ahoj! Client here!';
  if DosCallNmPipe('\\.\pipe\teszt',S[1],length(S),C,W,2000*1000)=false then
    writeln('failed to call pipe! (',PipeError,')');
END.