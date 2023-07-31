
var Module: string;
    InitProc,DispatchProc: string;
    OK: boolean;
    VDDHandle: word;
    Error,X: word;

BEGIN
  Module:='D:\DELPHI\WSOCKVDD\WSOCKVDD.DLL'#0;
  InitProc:='VDDRegisterInit'#0;
  DispatchProc:='VDDDispatch'#0;
  asm
    push ds
    pop  es
    mov si, offset Module.byte[1]
    mov di, offset InitProc.byte[1]
    mov bx, offset DispatchProc.byte[1]
    db  0c4h,0c4h, 58h, 00h
    jc  @Err
    mov OK, true
    mov VDDHandle, ax
    jmp @Done
  @Err:
    mov OK, false
    mov Error, ax
  @Done:
  end;
  if OK=false then
    begin writeln('failed to initalize the VDD'); Halt; end;

  asm
    mov dx, $1234
    mov cx, 0
    mov ax, VDDHandle
    db  0c4h,0c4h, 58h, 02h
    mov X, cx
  end;

  asm
    mov ax, VDDHandle
    db  0c4h,0c4h, 58h, 01h
    jc  @Err
    mov OK, true
    jmp @Done
  @Err:
    mov OK, false
  @Done:
  end;
  if OK=false then
    writeln('failed to deregister the VDD');
END.