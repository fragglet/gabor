{
    $Id: netbios.pas,v 1.1 1999/12/19 20:02:30 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    High-level NetBIOS interface

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
unit NetBIOS;

interface

uses Objects,NB30;

type
     TNetBIOSName = string[16];

{     PNetBIOSSession = ^TNetBIOSSession;
     TNetBIOSSession = object(TObject)
       Adapter    : TNBAdapterNumber;
       Status     : byte;
       RemoteName : TNetBIOSName;
       LocalName  : TNBNameNumber;
       TimeOut    : byte;
       Session    : TNBSessionNumber;
       constructor Init(AdapterNo: byte; ALocalName: byte; ARemoteName: TNetBIOSName; ATimeOut: byte);
       destructor  Done; virtual;
     private
       AdapterSave : byte;
       NCBSave     : PNCB;
     end;}

function  NBInit: boolean;
{ [ Name commands ]                              }
function  NBAddUniqueName(const Name: TNetBIOSName; var NameNumber: TNBNameNumber): integer;
function  NBAddGroupName(const Name: TNetBIOSName; var NameNumber: TNBNameNumber): integer;
function  NBDeleteName(const Name: TNetBIOSName): integer;
{ [ Datagram-oriented (connectionless) commands] }
function  NBSendDatagram(SourceNameNumber: TNBNameNumber; const DestName: TNetBIOSName; DataPtr: pointer;
          DataSize: word): integer;
function  NBReceiveDatagram(OnNameNumber: TNBNameNumber; BufPtr: pointer; BufSize: word): integer;
{ [ Session (connection-oriented) commands]      }
function  NBCall(LocalNameNumber: TNBNameNumber; const RemoteName: TNetBIOSName; STimeOut, RTimeOut: byte;
          var SessionNumber: TNBSessionNumber): integer;
function  NBListen(LocalNameNumber: TNBNameNumber; const CallerName: TNetBIOSName; STimeOut, RTimeOut: byte;
          var SessionNumber: TNBSessionNumber): integer;
function  NBHangup(SessionNumber: TNBSessionNumber): integer;
function  NBSend(SessionNumber: TNBSessionNumber; DataPtr: pointer; DataSize: word): integer;
{ [ Miscellenous commands ]                      }
function  NBReset(MaxSessions, MaxCmds: byte): integer;
function  NBGetAdapterStatus(const Name: TNetBIOSName; var AS: TAdapterStatus): integer;
function  NBCancel(NCBtoCancel: PNCB): integer;

{ commands available only in LAN Manager / Windows Networking and LANtastic }
{function  NBGetMachineName: TNetBIOSName;
procedure NBSetMachineName(Name: TNetBIOSName);}

const NBNCB          : PNCB = nil;
      NBAdapter      : TNBAdapterNumber = #0;
      NBPostHandler  : TNCBPostProc = nil;
      NBError        : byte = nrc_GOODRET;

implementation

uses Dos;

function Min(A,B: longint): longint; begin if A<B then Min:=A else Min:=B; end;

procedure PutString(const S: string; var Buf; BufSize: word; Filler: char);
begin
  FillChar(Buf,BufSize,Filler);
  Move(S[1],Buf,Min(length(S),BufSize));
end;

function InitNCB: boolean;
var OK: boolean;
begin
  NBNCB:=NbNewNCB;
  NBNCB^.ncb_LanA_Num:=NBAdapter;
  OK:=NbSetNCBPostHandler(NBNCB,NBPostHandler);
  InitNCB:=OK;
end;

procedure DoneNCB;
begin
  if NbIsNCBBusy(NBNCB)=false then
    begin
      NbFreeBuffer(NBNCB);
      NbFreeNCB(NBNCB);
      NBNCB:=nil;
    end;
  NBAdapter:=#0;
  NBPostHandler:=nil;
end;

function ExecNCB(Cmd: byte; var NCB: TNCB): integer;
var Err: char;
begin
  if @NCB.ncb_Post<>nil then
    Cmd:=Cmd or nbcAsynchronous;
  if Assigned(NBNCB)=false then
    Err:=chr(nrc_NORES)
  else
    begin
      NBNCB^.ncb_Command:=chr(Cmd);
      Err:=NB30.NetBios(NBNCB);
    end;
  NBError:=ord(Err);
  ExecNCB:=NBError;
end;

function NBInit: boolean;
var AS: TAdapterStatus;
begin
  NBInit:=NBGetAdapterStatus('*',AS)=nrc_GOODRET;
end;

function NBReset(MaxSessions, MaxCmds: byte): integer;
begin
  InitNCB;
  NBNCB^.ncb_LSN:=chr(MaxSessions);
  NBNCB^.ncb_NUM:=chr(MaxCmds);
  NBReset:=ExecNCB(nbcReset,NBNCB^);
  DoneNCB;
end;

function NBCancel(NCBtoCancel: PNCB): integer;
begin
  InitNCB;
  NBNCB^.ncb_Buffer:=NbGetNCBAddr(NCBToCancel);
  NBCancel:=ExecNCB(nbcCancel,NBNCB^);
  DoneNCB;
end;

function NBGetAdapterStatus(const Name: TNetBIOSName; var AS: TAdapterStatus): integer;
var Err: integer;
begin
  FillChar(AS,SizeOf(AS),0);
  InitNCB;
  PutString(Name,NBNCB^.ncb_CallName,SizeOf(NBNCB^.ncb_CallName),#32);
  NbNewBuffer(NBNCB,sizeof(AS));
  Err:=ExecNCB(nbcAStat,NBNCB^);
  NbDataFromBuffer(NBNCB,sizeof(AS),AS);
  if NbIsNCBBusy(NBNCB)=false then
    NbFreeBuffer(NBNCB);
  DoneNCB;
  NBGetAdapterStatus:=Err;
end;

function NBAddUniqueName(const Name: TNetBIOSName; var NameNumber: TNBNameNumber): integer;
var Err: integer;
begin
  InitNCB;
  PutString(Name,NBNCB^.ncb_Name,SizeOf(NBNCB^.ncb_Name),#32);
  Err:=ExecNCB(nbcAddName,NBNCB^);
  if Err=nrc_GOODRET then
    NameNumber:=NBNCB^.ncb_Num
  else
    NameNumber:=nb_invalid_name_number;
  DoneNCB;
  NBAddUniqueName:=Err;
end;

function NBAddGroupName(const Name: TNetBIOSName; var NameNumber: TNBNameNumber): integer;
var Err: integer;
begin
  InitNCB;
  PutString(Name,NBNCB^.ncb_Name,SizeOf(NBNCB^.ncb_Name),#32);
  Err:=ExecNCB(nbcAddGrName,NBNCB^);
  if Err=nrc_GOODRET then
    NameNumber:=NBNCB^.ncb_Num
  else
    NameNumber:=nb_invalid_name_number;
  DoneNCB;
  NBAddGroupName:=Err;
end;

function NBDeleteName(const Name: TNetBIOSName): integer;
begin
  InitNCB;
  PutString(Name,NBNCB^.ncb_Name,SizeOf(NBNCB^.ncb_Name),#32);
  NBDeleteName:=ExecNCB(nbcDelName,NBNCB^);
  DoneNCB;
end;

function NBSendDatagram(SourceNameNumber: TNBNameNumber; const DestName: TNetBIOSName; DataPtr: pointer;
         DataSize: word): integer;
begin
  InitNCB;
  NBNCB^.ncb_Num:=SourceNameNumber;
  PutString(DestName,NBNCB^.ncb_Name,SizeOf(NBNCB^.ncb_Name),#32);
  NbNewBuffer(NBNCB,DataSize);
  NBDataToBuffer(NBNCB,DataPtr^,DataSize);
  NBSendDatagram:=ExecNCB(nbcDgSend,NBNCB^);
  if NbIsNCBBusy(NBNCB)=false then
    NbFreeBuffer(NBNCB);
  DoneNCB;
end;

function NBReceiveDatagram(OnNameNumber: TNBNameNumber; BufPtr: pointer; BufSize: word): integer;
begin
  InitNCB;
  NBNCB^.ncb_Num:=OnNameNumber;
  NbNewBuffer(NBNCB,BufSize);
  NBReceiveDatagram:=ExecNCB(nbcDgRecv,NBNCB^);
  NbDataFromBuffer(NBNCB,BufSize,BufPtr^);
  if NbIsNCBBusy(NBNCB)=false then
    NbFreeBuffer(NBNCB);
  DoneNCB;
end;

function NBCall(LocalNameNumber: TNBNameNumber; const RemoteName: TNetBIOSName;
         STimeOut, RTimeOut: byte; var SessionNumber: TNBSessionNumber): integer;
var Err: integer;
begin
  InitNCB;
  NBNCB^.ncb_Num:=LocalNameNumber;
  PutString(RemoteName,NBNCB^.ncb_Name,SizeOf(NBNCB^.ncb_Name),#32);
  NBNCB^.ncb_STO:=STimeOut;
  NBNCB^.ncb_RTO:=RTimeOut;
  Err:=ExecNCB(nbcCall,NBNCB^);
  if Err=nrc_GOODRET then
    SessionNumber:=NBNCB^.ncb_LSN
  else
    SessionNumber:=nb_invalid_session_number;
  DoneNCB;
  NBCall:=Err;
end;

function NBListen(LocalNameNumber: TNBNameNumber; const CallerName: TNetBIOSName;
         STimeOut, RTimeOut: byte; var SessionNumber: TNBSessionNumber): integer;
var Err: integer;
begin
  InitNCB;
  NBNCB^.ncb_Num:=LocalNameNumber;
  PutString(CallerName,NBNCB^.ncb_Name,SizeOf(NBNCB^.ncb_Name),#32);
  NBNCB^.ncb_STO:=STimeOut;
  NBNCB^.ncb_RTO:=RTimeOut;
  Err:=ExecNCB(nbcListen,NBNCB^);
  if Err=nrc_GOODRET then
    SessionNumber:=NBNCB^.ncb_LSN
  else
    SessionNumber:=nb_invalid_session_number;
  DoneNCB;
  NBListen:=Err;
end;

function NBHangup(SessionNumber: TNBSessionNumber): integer;
begin
  InitNCB;
  NBNCB^.ncb_LSN:=SessionNumber;
  NBHangup:=ExecNCB(nbcHangup,NBNCB^);
  DoneNCB;
end;

function NBSend(SessionNumber: TNBSessionNumber; DataPtr: pointer; DataSize: word): integer;
begin
  InitNCB;
  NBNCB^.ncb_LSN:=SessionNumber;
  NbNewBuffer(NBNCB,DataSize);
  NbDataToBuffer(NBNCB,DataPtr^,DataSize);
  NBSend:=ExecNCB(nbcSend,NBNCB^);
  if NbIsNCBBusy(NBNCB)=false then
    NbFreeBuffer(NBNCB);
  DoneNCB;
end;
{
function NBGetMachineName: TNetBIOSName;
var r: registers;
    OK: boolean;
    N: TNetBIOSName;
    I: integer;
begin
  MachineNameID:=$ff; MachineName:='';
  FillChar(N,SizeOf(N),0);
  r.ax:=$5e00;
  r.ds:=seg(N); r.dx:=ofs(N);
  intr($21,r);
  OK:=((r.flags and fCarry)=0) and (r.ch<>0);
  if OK then
  begin
    I:=1; MachineName:='';
    while (N[I]<>#0) and (I<=16) do
    begin
      MachineName:=MachineName+N[I];
      Inc(I);
    end;
    MachineNameID:=r.cl;
  end;
  NBGetMachineName:=MachineName;
end;

procedure NBSetMachineName(Name: TNetBIOSName);
var N: TNetBIOSName;
    L: byte;
    r: registers;
begin
  if MachineNameID=$ff then NBGetMachineName;
  if MachineNameID=$ff then Exit;
  FillChar(N,SizeOf(N),0);
  L:=length(Name); if L>15 then L:=15;
  Move(Name[1],N,L);
  r.ax:=$5e01; r.ch:=L; r.cl:=MachineNameID;
  r.ds:=seg(N); r.dx:=ofs(N);
  intr($21,r);
end;
}
{constructor TNetBIOSSession.Init(AdapterNo: byte; ALocalName: byte; ARemoteName: TNetBIOSName; ATimeOut: byte);
begin
  inherited Init;
  Adapter:=AdapterNo; TimeOut:=ATimeOut;
  RemoteName:=ARemoteName; LocalName:=ALocalName;
  Prolog(Synchronous);
  Status:=NBCall(LocalName,RemoteName,TimeOut,TimeOut,Session);
  Epilog;
  if Status<>nb_err_OK then Fail;
end;

destructor TNetBIOSSession.Done;
begin
  inherited Done;
  NBHangup(Session);
end;
}

END.
{
  $Log: netbios.pas,v $

  Revision 1.0  1998/11/01 11:30:25  gabor
     Original implementation
  Revision 1.1  1999/12/19 20:02:30  gabor
     Re-written to use NB30

}
