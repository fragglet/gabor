uses Dos,pmode;

const
      vxd_id_VXDLoader     = $0027;

function GetVXDEntryPoint(VXDID: word): pointer;
var r: registers;
begin
  r.ax:=$1684; r.bx:=VXDID;
  r.es:=0; r.di:=0;
  realintr($2f,r);
  GetVXDEntryPoint:=MakePtr(r.es,r.di);
end;

function LoadVXD(VXDName: string): boolean;
var r: registers;
    M: MemPtr;
    OK: boolean;
    VXDLoader: pointer;
begin
  VXDName:=VXDName+#0;
  VXDLoader:=GetVXDEntryPoint(vxd_id_VXDLoader);
  OK:=VXDLoader<>nil;
  if OK then
  begin
    GetDosMem(M,256);
    M.MoveDataTo(VXDName[1],length(VXDName)+1);
    r.ax:=1;
    r.ds:=M.DosSeg; r.dx:=M.DosOfs;
    realcall(VXDLoader,r);
    FreeDosMem(M);
    OK:=(r.flags and fCarry)=0;
  end;
  LoadVXD:=OK;
end;

function UnloadVXD(VXDName: string): boolean;
var r: registers;
    M: MemPtr;
    OK: boolean;
    VXDLoader: pointer;
begin
  VXDName:=VXDName+#0;
  VXDLoader:=GetVXDEntryPoint(vxd_id_VXDLoader);
  OK:=VXDLoader<>nil;
  if OK then
  begin
    GetDosMem(M,256);
    M.MoveDataTo(VXDName[1],length(VXDName)+1);
    r.ax:=2;
    r.ds:=M.DosSeg; r.dx:=M.DosOfs;
    realcall(VXDLoader,r);
    FreeDosMem(M);
    OK:=(r.flags and fCarry)=0;
  end;
  UnloadVXD:=OK;
end;

function LoadModule(ModuleName: string): boolean;
var r: registers;
    M: MemPtr;
    OK: boolean;
    VXDLoader: pointer;
begin
  ModuleName:=ModuleName+#0;
  VXDLoader:=GetVXDEntryPoint(vxd_id_VXDLoader);
  OK:=VXDLoader<>nil;
  if OK then
  begin
    GetDosMem(M,256);
    M.MoveDataTo(ModuleName[1],length(ModuleName)+1);
    r.ax:=7;
    r.ds:=M.DosSeg; r.dx:=M.DosOfs;
    realcall(VXDLoader,r);
    FreeDosMem(M);
    OK:=(r.flags and fCarry)=0;
  end;
  LoadModule:=OK;
end;

type
    PDeviceInfo = ^TDeviceInfo;
    TDeviceInfo = packed record
    end;

type TDeviceEnumProc = procedure(DevInfo: PDeviceInfo);

function EnumDevices(EnumProc: TDeviceEnumProc): boolean;
var r: registers;
    OK: boolean;
    VXDLoader: pointer;
begin
  VXDLoader:=GetVXDEntryPoint(vxd_id_VXDLoader);
  OK:=VXDLoader<>nil;
  if OK then
  begin
    r.ax:=5;
    realcall(VXDLoader,r);
    OK:=(r.flags and fCarry)=0;
  end;
  EnumDevices:=OK;
end;


procedure Fatal(const S: string);
begin
  writeln(s);
  halt(1);
end;

const TDI: pointer = nil;
      TDIError: longint = 0;

function CallTCP(Func: word; var Buf): boolean;
var r: registers;
begin
  FillChar(r,sizeof(r),0);
  r.ax:=Func;
  r.es:=seg(buf); r.bx:=ofs(buf);
  realcall(TDI,r);
  TDIError:=r.ax;
  CallTCP:=TDIError=0;
end;

var B: array[0..4095] of byte;

const vxd_VTDI = $488;

var I: word;

BEGIN
{  if EnumDevices(nil)=false then
    Fatal('failed to enumerate devices');}
{  if LoadModule('w2_32.dll')=false then
     Fatal('failed to load module');}
  if LoadVXD('vtdi.386')=false then
    Fatal('failed to load tdi vxd');
  TDI:=GetVXDEntryPoint({vxd_VTDI}$200);
  TDI:=GetVXDEntryPoint({vxd_VTDI}$48a);
  if TDI=nil then Fatal('no entry point');
  writeln('VXD found');
  for I:=0 to 60000 do
  begin
    CallTCP($100,B);
    if TDIError<>$ffff then
      writeln('OK! ',I);
  end;
  UnloadVxd('vtdi.386');
END.