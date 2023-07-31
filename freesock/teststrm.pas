uses Objects,Streams,Crt;

procedure Fatal(const S: string);
begin
  writeln(S);
  Halt(1);
end;

var S: PSeqMemoryStream;
    Writeofs,ReadOfs: byte;
    B: array[0..127] of byte;
    Size: longint;
    I: longint;
    TotalBytes: longint;

BEGIN
  Randomize;
  WriteOfs:=0; ReadOfs:=0; TotalBytes:=0;
  New(S, Init(4096,4096));
  repeat
    Size:=round(random(sizeof(B))*0.98);
    for I:=0 to Size-1 do
      begin
        B[I]:=WriteOfs;
        Inc(Writeofs);
      end;
    S^.Write(B,Size);
    if S^.Status<>stOk then
      begin
        asm int 3 end;
        Fatal('error writing stream');
      end;
    Size:=random(sizeof(B));
    if Size>S^.GetSize then Size:=S^.GetSize;
    S^.Read(B,Size);
    if S^.Status<>stOK then
      begin
        asm int 3 end;
        Fatal('error reading stream');
      end;
{    if random(10)=0 then
      B[random(Size)]:=0;}
    for I:=0 to Size-1 do
      begin
        if B[I]<>ReadOfs then
          begin
            asm int 3 end;
            Fatal('data mismatch');
          end;
        Inc(ReadOfs);
        Inc(TotalBytes);
      end;
    write('total bytes: ',TotalBytes:10,'  size: ',S^.GetSize:8,' mem: ',MaxAvail);
    write(#13);
  until keypressed;
  Dispose(S, Done);
END.