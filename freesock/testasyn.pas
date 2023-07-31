uses AsyncTCP;

procedure Fatal(const S: string);
begin
  writeln(S);
  Halt(1);
end;

BEGIN
  if AsyncInit=false then
    Fatal('can''t initialize protocol stack');
  AsyncDone;
END.