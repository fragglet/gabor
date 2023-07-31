{
    $Id: nbdos.inc,v 1.0 1999/12/19 11:30:25 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    NetBIOS interface for DOS

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

uses Dos;

const
     NBMagicNo = ord('N')+ord('B')*256+ord('C')*65536+ord('B')*16777216;

const UseInt5C : boolean = false;

function Min(A,B: longint): longint;
begin
  if A<B then Min:=A else Min:=B;
end;

function CallNetBIOS(DosPtr: pointer): char;
var Err: byte;
    r: registers;
begin
  if UseInt5C=false then
    begin
      r.ah:=$04; r.al:=0;
      r.es:=PtrRec(DosPtr).Seg; r.bx:=PtrRec(DosPtr).Ofs;
      realintr($2a,r);
      if r.ax=0 then
        Err:=nrc_GOODRET
      else
        Err:=r.al;
    end
  else
    begin
      r.es:=PtrRec(DosPtr).Seg; r.bx:=PtrRec(DosPtr).Ofs;
      realintr($5c,r);
      Err:=r.al;
    end;
  CallNetBIOS:=chr(Err);
end;

{$ifdef DPMI}
function NbNewNCB: PNCB;
var M: MemPtr;
    P: PNCB;
begin
  GetDosMem(M,Sizeof(TNCB));
  P:=M.DataPtr;
  P^.MNCB:=M;
  P^.MagicNo:=NBMagicNo;
  NbNewNCB:=P;
end;

procedure NbFreeNCB(P: PNCB);
begin
  if Assigned(P) then
  begin
    NbFreeBuffer(P);
    FreeDosMem(P^.MNCB);
  end;
end;

function NbNewBuffer(P: PNCB; Size: word): boolean;
var OK: boolean;
begin
  OK:=Assigned(P);
  if OK then
  begin
    NbFreeBuffer(P);
    OK:=GetDosMem(P^.MData,Size);
    if OK then
      begin
        P^.ncb_Buffer:=P^.MData.DosPtr;
        P^.ncb_Length:=Size;
      end;
  end;
  NbNewBuffer:=OK;
end;

function NbFreeBuffer(P: PNCB): boolean;
var OK: boolean;
begin
  OK:=Assigned(P);
  if OK then
  begin
    OK:=P^.MData.DosPtr<>nil;
    if OK then
      begin
        FreeDosMem(P^.MData);
        P^.ncb_Buffer:=nil;
        P^.ncb_Length:=0;
      end;
  end;
  NbFreeBuffer:=OK;
end;

function NbDataToBuffer(P: PNCB; const Data; DataSize: word): boolean;
var OK: boolean;
    Size: word;
begin
  OK:=Assigned(P);
  if OK then OK:=(P^.MData.DataPtr<>nil);
  if OK then
  begin
    Size:=Min(DataSize,P^.MData.Size);
    OK:=Size=DataSize;
    Move(Data,P^.MData.DataPtr^,Size);
  end;
  NbDataToBuffer:=OK;
end;

function NbDataFromBuffer(P: PNCB; DataSize: word; var Data): boolean;
var OK: boolean;
    Size: word;
begin
  OK:=Assigned(P);
  if OK then OK:=(P^.MData.DataPtr<>nil);
  if OK then
  begin
    Size:=Min(DataSize,P^.MData.Size);
    OK:=Size=DataSize;
    Move(P^.MData.DataPtr^,Data,Size);
  end;
  NbDataFromBuffer:=OK;
end;

function NbSetNCBPostHandler(P: PNCB; NBPostHandler: TNCBPostProc): boolean;
var OK: boolean;
begin
  OK:=false;
  { allocate real-mode callback here and assign to NCB^.nbc_Post }
  NbSetNCBPostHandler:=OK;
end;

function NbGetNCBAddr(P: PNCB): pointer;
begin
  NbGetNCBAddr:=P^.MNCB.DosPtr;
end;

function Netbios(NCB: PNCB): Char;
var r: registers;
    Err: byte;
    DosP: pointer;
    M: MemPtr;
begin
  if (
      ((ord(NCB^.ncb_Command) and nbcAsynchronous)<>0) or
      (NCB^.ncb_Buffer<>nil)
     )
     and
     (NCB^.MagicNo<>NBMagicNo) then
    Err:=nrc_ILLCMD
  else
  begin
    if NCB^.MagicNo=NBMagicNo then
      DosP:=NCB^.MNCB.DosPtr
    else
      begin
        GetDosMem(M,SizeOf(NCB^));
        M.MoveDataTo(NCB^,sizeof(NCB^));
        DosP:=M.DosPtr;
      end;
    Err:=ord(CallNetBIOS(DosP));
    if NCB^.MagicNo<>NBMagicNo then
      begin
        M.MoveDataFrom(sizeof(NCB^),NCB^);
        FreeDosMem(M);
      end;
  end;
  NetBios:=chr(Err);
end;

{$else}

function NbNewNCB: PNCB;
var P: PNCB;
begin
  New(P);
  if Assigned(P) then FillChar(P^,sizeof(P^),0);
  NbNewNCB:=P;
end;

procedure NbFreeNCB(P: PNCB);
begin
  if Assigned(P) then
  begin
    NbFreeBuffer(P);
    Dispose(P);
  end;
end;

function NbNewBuffer(P: PNCB; Size: word): boolean;
var OK: boolean;
begin
  OK:=Assigned(P);
  if OK then
  begin
    NbFreeBuffer(P);
    GetMem(P^.ncb_Buffer,Size);
    OK:=Assigned(P^.ncb_Buffer);
    if OK then
    begin
      P^.DataBufSize:=Size;
      FillChar(P^.ncb_Buffer^,Size,0);
      P^.ncb_Length:=Size;
    end;
  end;
  NbNewBuffer:=OK;
end;

function NbFreeBuffer(P: PNCB): boolean;
var OK: boolean;
begin
  OK:=Assigned(P);
  if OK then
  begin
    OK:=Assigned(P^.ncb_Buffer) and (P^.DataBufSize>0);
    if OK then
      begin
        FreeMem(P^.ncb_Buffer,P^.DataBufSize);
        P^.ncb_Buffer:=nil; P^.ncb_Length:=0;
        P^.DataBufSize:=0;
      end;
  end;
  NbFreeBuffer:=OK;
end;

function NbDataToBuffer(P: PNCB; const Data; DataSize: word): boolean;
var OK: boolean;
begin
  OK:=Assigned(P);
  if OK then OK:=Assigned(P^.ncb_Buffer);
  if OK then Move(Data,P^.ncb_Buffer^,DataSize);
  NbDataToBuffer:=OK;
end;

function NbDataFromBuffer(P: PNCB; DataSize: word; var Data): boolean;
var OK: boolean;
begin
  OK:=Assigned(P);
  if OK then OK:=Assigned(P^.ncb_Buffer);
  if OK then Move(P^.ncb_Buffer^,Data,DataSize);
  NbDataFromBuffer:=OK;
end;

function NbSetNCBPostHandler(P: PNCB; NBPostHandler: TNCBPostProc): boolean;
var OK: boolean;
begin
  OK:=Assigned(P);
  if OK then P^.ncb_Post:=NBPostHandler;
  NbSetNCBPostHandler:=OK;
end;

function NbGetNCBAddr(P: PNCB): pointer;
begin
  NbGetNCBAddr:=P;
end;

function Netbios(NCB: PNCB): Char;
begin
  Netbios:=CallNetbios(NCB);
end;

{$endif}

{
  $Log: nbdos.inc,v $

  Revision 1.0  1999/12/19 11:30:25  gabor
     Original implementation

}
