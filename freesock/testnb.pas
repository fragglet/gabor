uses NB30,NetBIOS;

const NN: TNBNameNumber = #0;

      MyName = 'HELLO';

procedure Fatal(const S: string);
begin
  if NN<>#0 then NBDeleteName(MyName);
  writeln(S);
  Halt(1);
end;

{var S: PNetBIOSSession;}

BEGIN
  if NBInit=false then
    Fatal('NetBIOS interface not found');

  NBDeleteName(MyName);

  if NBAddUniqueName(MyName,NN)<>0 then
    Fatal('failed to allocate unique name');
{  New(S, Init(0,NN,'TAURUS',3));
  if S=nil then
    Fatal('failed to connect')
  else
    begin
      Dispose(S, Done);
    end;}

  NBDeleteName(MyName);
END.