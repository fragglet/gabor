{
    $Id: nbwin32.inc,v 1.0 1999/12/19 11:30:25 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    NetBIOS interface for Windows

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

function Netbios(NCB: PNCB): Char; stdcall;
   external 'netapi32.dll' name 'Netbios';

function NbNewNCB: PNCB;
var P: PNCB;
begin
  New(P);
  if Assigned(P) then FillChar(P^,sizeof(P^),0);
  NbNewNCB:=P;
end;

procedure NbFreeNCB(P: PNCB);
begin
  if Assigned(P) then Dispose(P);
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
    OK:=Assigned(P^.ncb_Buffer);
    if OK then
      begin
        FreeMem(P^.ncb_Buffer);
        P^.ncb_Buffer:=nil; P^.ncb_Length:=0;
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

{
  $Log: nbwin32.inc,v $

  Revision 1.0  1999/12/19 11:30:25  gabor
     Original implementation

}
