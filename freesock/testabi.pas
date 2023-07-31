uses ABISocks;


BEGIN
  if ABIInit=false then
    begin writeln('ABI interface not found'); Exit; end;
END.