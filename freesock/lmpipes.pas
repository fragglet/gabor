{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    LAN Manager named pipe driver interface

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 **********************************************************************}
unit LMPipes;

interface

uses Types;

const
     lm_cmd_CallNamedPipe      = $5f37;
     lm_cmd_WaitForNamedPipe   = $5f38;

type
    TDosCallNmPipe = packed record
      Timeout        : longint;
      BytesReadPtr   : plongint;
      OutBufferSize  : word;
      OutBuffer      : pointer;
      InBufferSize   : word;
      InBuffer       : pointer;
      PipeName       : pointer;
    end;

function DosCallNmPipe(const PipeName: string; const OutBuf; OutBufSize: word;
                       var InBuf; var InBufSize: word; Timeout: longint): boolean;
function DosWaitNmPipe(const PipeName: string; Timeout: longint): boolean;

const PipeError : integer = 0;

implementation

uses Dos,pmode;

procedure InitRegisters(var r: registers);
begin
  FillChar(r,sizeof(r),0);
end;

function CallPipe(Cmd: word; var r: registers): boolean;
var OK: boolean;
begin
  r.ax:=Cmd;
  MsDos(r);
  OK:=(r.flags and fCarry)=0;
  if OK then
    PipeError:=0
  else
   PipeError:=r.ax;
  CallPipe:=OK;
end;

function DosCallNmPipe(const PipeName: string; const OutBuf; OutBufSize: word;
                       var InBuf; var InBufSize: word; Timeout: longint): boolean;
var CallM,NameM,InM,OutM : MemPtr;
    r: registers;
    OK: boolean;
    CB: record C: TDosCallNmPipe; BytesRead: longint end;
begin
  GetDosMem(CallM,SizeOf(CB));
  GetDosMem(NameM,length(PipeName)+1); NameM.MoveDataTo(PipeName[1],length(PipeName));
  GetDosMem(OutM,OutBufSize); OutM.MoveDataTo(OutBuf,OutBufSize);
  GetDosMem(InM,InBufSize);
  FillChar(CB,SizeOf(CB),0);
  CB.C.Timeout:=Timeout;
  CB.C.BytesReadPtr:=MakePtr(CallM.DosSeg,CallM.DosOfs+(ofs(CB.BytesRead)-ofs(CB)));
  CB.C.OutBufferSize:=OutBufSize;
  CB.C.OutBuffer:=OutM.DosPtr;
  CB.C.InBufferSize:=InBufSize;
  CB.C.InBuffer:=InM.DosPtr;
  CB.C.PipeName:=NameM.DosPtr;
  CallM.MoveDataTo(CB,SizeOf(CB));

  InitRegisters(r);
  r.ds:=CallM.DosSeg; r.si:=CallM.DosOfs;
  OK:=CallPipe(lm_cmd_CallNamedPipe,r);

  CallM.MoveDataFrom(SizeOf(CB),CB);
  if OK=false then
    InBufSize:=0
  else
    InBufSize:=r.cx;
  InM.MoveDataFrom(InBufSize,InBuf);

  FreeDosMem(OutM); FreeDosMem(InM);
  FreeDosMem(NameM); FreeDosMem(CallM);

  DosCallNmPipe:=OK;
end;

function DosWaitNmPipe(const PipeName: string; Timeout: longint): boolean;
var r: registers;
    OK: boolean;
    M: MemPtr;
begin
  InitRegisters(r);
  GetDosMem(M, length(PipeName)+1);
  M.MoveDataTo(PipeName[1],length(PipeName));
  r.ds:=M.DosSeg; r.dx:=M.DosOfs;
  r.bx:=(Timeout shr 16); r.cx:=(Timeout and $ffff);

  OK:=CallPipe(lm_cmd_WaitForNamedPipe,r);

  FreeDosMem(M);
  DosWaitNmPipe:=OK;
end;

END.