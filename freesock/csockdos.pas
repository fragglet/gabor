{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    CODA SOCK.VXD interface

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
unit CSockDOS;

interface

type
     dword        = longint;
     TCSockSocket = longint;

const
      vxd_id_VXDLoader     = $0027;
      vxd_id_CodaSock      = $1235;

      CSOCKVXD             = 'csock.vxd';

      csock_cmd_First         = $0100;
      csock_cmd_Accept        = csock_cmd_First + $00;
      csock_cmd_Bind          = csock_cmd_First + $01;
      csock_cmd_Close         = csock_cmd_First + $02;
      csock_cmd_Connect       = csock_cmd_First + $03;
      csock_cmd_GetPeerName   = csock_cmd_First + $04;
      csock_cmd_GetSockName   = csock_cmd_First + $05;
      csock_cmd_GetSockOpt    = csock_cmd_First + $06;
      csock_cmd_IOCTL         = csock_cmd_First + $07;
      csock_cmd_Listen        = csock_cmd_First + $08;
      csock_cmd_Receive       = csock_cmd_First + $09;
      csock_cmd_SelectSetup   = csock_cmd_First + $0a;
      csock_cmd_SelectCleanup = csock_cmd_First + $0b;
      csock_cmd_Send          = csock_cmd_First + $0d;
      csock_cmd_SetSockOpt    = csock_cmd_First + $0e;
      csock_cmd_Shutdown      = csock_cmd_First + $0f;
      csock_cmd_Socket        = csock_cmd_First + $10;
      csock_cmd_Signal        = csock_cmd_First + $16;
      csock_cmd_SignalAll     = csock_cmd_First + $17;
      csock_cmd_InstallEventHandler= csock_cmd_First + $19;

type
     TCSock_Accept_Params = packed record
       Address          : pointer;
       ListeningSocket  : TCSockSocket;
       ConnectedSocket  : TCSockSocket;
       AddressLength    : dword;
       ConnectedSocketHandle: dword;
       ApcRoutine       : pointer;
       ApcContext       : word;
     end;

     TCSock_Bind_Params = packed record
       Address          : pointer;
       Socket           : TCSockSocket;
       AddressLength    : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
     end;

     TCSock_Connect_Params = TCSock_Bind_Params;

     TCSock_Close_Params = packed record
       Socket      : TCSockSocket;
     end;

     TCSock_GetPeerName_Params = packed record
       Address          : pointer;
       Socket           : TCSockSocket;
       AddressLength    : dword;
     end;

     TCSock_GetSockName_Params = TCSock_GetPeerName_Params;

     TCSock_GetSocketOpt_Params = packed record
       Value            : pointer;
       Socket           : TCSockSocket;
       OptionLevel      : dword;
       OptionName       : dword;
       ValueLength      : dword;
       IntValue         : dword;
     end;

     TCSock_IOCTL_Params = packed record
       Socket           : TCSockSocket;
       Command          : dword;
       Param            : pointer;
     end;

     TCSock_Listen_Params = packed record
       Socket           : TCSockSocket;
       BackLogSize      : dword;
     end;

     TCSock_Receive_Params = packed record
       Buffer           : pointer;
       Address          : pointer;
       Socket           : TCSockSocket;
       BufferLength     : dword;
       Flags            : dword;
       AddressLength    : dword;
       BytesTransmitted : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
       TimeOut          : dword;
     end;

     TCSock_Send_Params = TCSock_Receive_Params;

     TCSock_Shutdown_Params = packed record
       Socket           : TCSockSocket;
       How              : dword;
     end;

     TCSock_Socket_Params = packed record
       Family      : dword;
       SocketType  : dword;
       Protocol    : dword;
       NewSocket   : TCSockSocket;
       Handle      : dword;
     end;

     TCSock_Signal_Params = packed record
       Socket           : TCSockSocket;
       Event            : dword;
       Status           : dword;
     end;

     TCSock_SignalAll_Params = packed record
       Socket           : TCSockSocket;
       Status           : dword;
     end;

     TCSock_InstallEventHandler_Params = packed record
       PostMessageCallBack  : pointer;
     end;

function  csock_Init: boolean;
procedure csock_Done;

const CSockError      : longint = 0;
      CSockVersion    : word    = 0;

implementation

uses dos,pmode;

const CSockInited     : boolean = false;
      CSockEntryPoint : pointer = nil;

function callcsock(Func: word; var r: registers32): boolean;
begin
  r.eax:=Func;
{  realintr32(CSockEntryPoint,r);}
  CSockError:=r.eax;
  callcsock:=(CSockError=0);
end;

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

function csock_Init: boolean;
var OK: boolean;
begin
  OK:=CSockInited;
  if OK=false then
    OK:=LoadVXD(CSOCKVXD);
  if OK=false then CSockEntryPoint:=nil else
    CSockEntryPoint:=GetVXDEntryPoint(vxd_id_CodaSock);
  OK:=OK and (CSockEntryPoint<>nil);
  if OK then CSockVersion:=$0101;
  CSockInited:=OK;
  csock_Init:=CSockInited;
end;

procedure csock_Done;
begin
  if CSockInited then
    UnloadVXD(CSOCKVXD);
  CSockInited:=false; CSockEntryPoint:=nil;
end;

END.