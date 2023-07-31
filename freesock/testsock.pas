{$ifndef FPC}{$ifdef win32}{$define DELPHI}{$endif}{$endif}

{$ifdef win32}{$APPTYPE CONSOLE}{$endif}
uses {$ifdef Delphi}SysUtils{$else}Strings{$endif},Sockets;

var WSA: TWSAData;

BEGIN
  if WSAStartup($101,WSA)<>0 then
    begin writeln('Error initalizing sockets interface: ',WSAGetLastError); Halt(1); end;
  writeln('Using: ',StrPas(WSA.szDescription));
  WSACleanup;
END.