{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Async Systems TCP driver interface   

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
unit AsyncTCP;

interface

const
      AsyncSignature = 'TCP V2.00';

      async_cmd_RegisterClient          = $0001;
      async_cmd_DeregisterClient        = $0101;

      async_cmd_GetIPConfig             = $0003;

      async_cmd_OpenTCP                 = $0006;

type
    TAsyncClientID = word;

    TAsync_Generic_Params = packed record
      Size                 : word;
      ClientID             : TAsyncClientID;
      Command              : word;
      Error                : integer;
    end;

    TAsync_RegisterClient_Params = packed record
      Header               : TAsync_Generic_Params;
      TCPStatusNotify      : pointer;
      TCPReceiveNotify     : pointer;
      TCPTransmitNotify    : pointer;
      PPPNotify            : pointer;
      PingNotify           : pointer;
      DNSNotify            : pointer;
      UDPNotify            : pointer;
      State                : word;
      WindowsMode          : word;
      StackDS              : word;
      StackVector          : word;
      NewClientID          : word;
      ClientVM             : word;
    end;

    TAsync_DeregisterClient_Params = packed record
      Header               : TAsync_Generic_Params;
    end;

    TAsync_GetIPConfig_Params = packed record
      Header               : TAsync_Generic_Params;
      Param1               : byte;
      Dunno                : word;
      X                    : byte;
    end;

    TAsync_OpenTCP_Params = packed record { 62 }
      Header               : TAsync_Generic_Params;
    end;

function  AsyncInit: boolean;
function  AsyncDone: boolean;

const AsyncError : integer = 0;

implementation

uses dos,pmode;

const AsyncInited      : boolean = false;
      AsyncDriverInt   : byte    = 0;
      AsyncClientID    : TAsyncClientID = 0;

function CallAsync(Cmd: word; var Params; ParamSize: word): boolean;
var M: MemPtr;
    r: registers;
begin
  if AsyncDriverInt=0 then
    AsyncError:=-1
  else
    begin
      if GetDosMem(M,ParamSize)=false then
        AsyncError:=-2
      else
        begin
          with TAsync_Generic_Params(Params) do
          begin
            Size:=ParamSize;
            ClientID:=AsyncClientID;
            Command:=Cmd;
            Error:=-1;
          end;

          M.MoveDataTo(Params,ParamSize);
          FillChar(r,sizeof(r),0);
          r.es:=M.DosSeg; r.ds:=M.DosSeg;
          r.dx:=M.DosSeg; r.cx:=M.DosOfs;
          intr(AsyncDriverInt,r);
          M.MoveDataFrom(ParamSize,Params);
          FreeDosMem(M);

          AsyncError:=TAsync_Generic_Params(Params).Error;
        end;
    end;
  CallAsync:=(AsyncError=0);
end;

function AsyncRegisterClient(var ClientID: TAsyncClientID): boolean; forward;
function AsyncDeRegisterClient(ClientID: TAsyncClientID): boolean; forward;

function AsyncInit: boolean;
function CheckInt(IntNo: byte): boolean;
var P: pointer;
    Sign: array[1..30] of char;
begin
  realGetIntVec(IntNo,P);
  MoveDosToPM(P,@Sign,SizeOf(Sign));
  CheckInt:=(Pos(AsyncSignature,Sign)>0);
end;
var I: byte;
    OK: boolean;
    r: registers;
    P: MemPtr;
begin

  if AsyncInited then
    begin
      AsyncInit:=true;
      Exit;
    end;

  if AsyncDriverInt=0 then
    begin
      for I:=$60 to $7f do
        if CheckInt(I) then
          begin
            AsyncDriverInt:=I;
            Break;
          end;
    end
  else
    if CheckInt(AsyncDriverInt)=false then
      AsyncDriverInt:=0;
  OK:=AsyncDriverInt<>0;
  if OK then
    begin
      OK:=AsyncRegisterClient(AsyncClientID);
    end;
  AsyncInited:=OK;
  AsyncInit:=OK;
end;

function AsyncDone: boolean;
var OK: boolean;
begin
  OK:=AsyncInited;
  if OK then
  begin
    OK:=AsyncDeregisterClient(AsyncClientID);
    AsyncClientID:=0;
  end;
  AsyncDone:=OK;
end;

function AsyncRegisterClient(var ClientID: TAsyncClientID): boolean;
var Params: TAsync_RegisterClient_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  OK:=CallAsync(async_cmd_RegisterClient,Params,sizeof(Params));
  if OK then
    ClientID:=Params.NewClientID
  else
    ClientID:=0;
  AsyncRegisterClient:=OK;
end;

function AsyncDeRegisterClient(ClientID: TAsyncClientID): boolean;
var Params: TAsync_DeregisterClient_Params;
    OK: boolean;
    CI: TAsyncClientID;
begin
  FillChar(Params,sizeof(Params),0);
  CI:=AsyncClientID; AsyncClientID:=ClientID;
  OK:=CallAsync(async_cmd_DeregisterClient,Params,sizeof(Params));
  AsyncClientID:=CI;
  if (CI=AsyncClientID) and OK then AsyncClientID:=0;
  AsyncDeregisterClient:=OK;
end;

END.