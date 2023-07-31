{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Debug support routines

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
{.$DEFINE NODEBUG}  { define do disable debugging }
unit WDebug;

interface

const
    debug_event_All      = 0;

type
    TDebugEventID = longint;

    TDebugInfoType = (itLongString,itInteger,itFloat,itPointer);

    TDebugProc = function(EventID: TDebugEventID; InfoType: TDebugInfoType; Info: pointer): boolean;

procedure DebInit;
procedure DebRegisterEvent(EventID: TDebugEventID; const EventName: string);
procedure DebDeRegisterEvent(EventID: TDebugEventID);
procedure DebEnableEvent(EventID: TDebugEventID);
procedure DebDisableEvent(EventID: TDebugEventID);
procedure DebHook(EventID: TDebugEventID; Proc: TDebugProc);
procedure DebUnHook(EventID: TDebugEventID; Proc: TDebugProc);
function  DebIsEventEnabled(EventID: TDebugEventID): boolean;
procedure DebDone;

procedure DebugStr(EventID: TDebugEventID; const S: string);
procedure DebugStrP(EventID: TDebugEventID; S: PChar);
procedure DebugInt(EventID: TDebugEventID; L: longint);
procedure DebugFloat(EventID: TDebugEventID; D: double);
procedure DebugPtr(EventID: TDebugEventID; P: pointer);

implementation

uses Objects,Strings;

{$ifndef NODEBUG}

type
    PDebugEventInfo = ^TDebugEventInfo;
    TDebugEventInfo = record
      EventID   : TDebugEventID;
      Name      : PString;
      Count     : longint;
    end;

    PDebugEventCollection = ^TDebugEventCollection;
    TDebugEventCollection = object(TSortedCollection)
      function Compare(Key1, Key2: Pointer): Integer; virtual;
      function SearchEvent(EventID: TDebugEventID): PDebugEventInfo;
      procedure FreeItem(Item: Pointer); virtual;
    end;

    PDebugHookInfo = ^TDebugHookInfo;
    TDebugHookInfo = record
      EventID    : TDebugEventID;
      Proc       : TDebugProc;
      Serial     : longint;
    end;

    PDebugHookCollection = ^TDebugHookCollection;
    TDebugHookCollection = object(TSortedCollection)
      function  Compare(Key1, Key2: Pointer): Integer; virtual;
      function  SearchHook(EventID: TDebugEventID; Proc: TDebugProc): PDebugHookInfo;
      procedure FreeItem(Item: Pointer); virtual;
    end;

const DebugHooks    : PDebugHookCollection = nil;
      DebugEvents  : PDebugEventCollection = nil;
      HookSerial    : longint = 0;

function NewDebugEventInfo(AEventID: TDebugEventID): PDebugEventInfo;
var P: PDebugEventInfo;
begin
  New(P); FillChar(P^,Sizeof(P^),0);
  with P^ do
  begin
    EventID:=AEventID;
  end;
  NewDebugEventInfo:=P;
end;

procedure DisposeDebugEventInfo(P: PDebugEventInfo);
begin
  if Assigned(P) then
  begin
    if Assigned(P^.Name) then DisposeStr(P^.Name);
    Dispose(P);
  end;
end;

function NewDebugHookInfo(AEventID: TDebugEventID; AProc: TDebugProc): PDebugHookInfo;
var P: PDebugHookInfo;
begin
  New(P); FillChar(P^,Sizeof(P^),0);
  with P^ do
  begin
    EventID:=AEventID;
    Proc:=AProc;
    Inc(HookSerial);
    Serial:=HookSerial;
  end;
  NewDebugHookInfo:=P;
end;

procedure DisposeDebugHookInfo(P: PDebugHookInfo);
begin
  if Assigned(P) then Dispose(P);
end;

procedure TDebugEventCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then DisposeDebugEventInfo(Item);
end;

function TDebugEventCollection.Compare(Key1, Key2: Pointer): Integer;
var K1: PDebugEventInfo absolute Key1;
    K2: PDebugEventInfo absolute Key2;
    R: integer;
begin
  if K1^.EventID<K2^.EventID then R:=-1 else
  if K1^.EventID>K2^.EventID then R:= 1 else
  R:=0;
  Compare:=R;
end;

function TDebugEventCollection.SearchEvent(EventID: TDebugEventID): PDebugEventInfo;
var P: PDebugEventInfo;
    I: TDebugEventInfo;
    Index: integer;
begin
  FillChar(I,SizeOf(I),0); I.EventID:=EventID;
  if Search(@I,Index)=false then P:=nil else
    P:=At(Index);
  SearchEvent:=P;
end;

procedure TDebugHookCollection.FreeItem(Item: Pointer);
begin
  if Assigned(Item) then DisposeDebugHookInfo(Item);
end;

function TDebugHookCollection.Compare(Key1, Key2: Pointer): Integer;
var K1: PDebugHookInfo absolute Key1;
    K2: PDebugHookInfo absolute Key2;
    R: integer;
begin
  if (K1=K2) then R:=0 else
  if K1^.EventID<K2^.EventID then R:=-1 else
  if K1^.EventID>K2^.EventID then R:= 1 else
  if K1^.Serial<K2^.Serial then R:=1 else
  if K1^.Serial>K2^.Serial then R:=-1 else
  R:=0; { this can't happen }
  Compare:=R;
end;

function TDebugHookCollection.SearchHook(EventID: TDebugEventID; Proc: TDebugProc): PDebugHookInfo;
function Match(P: PDebugHookInfo): boolean; {$ifndef FPC}far;{$endif}
begin
  Match:=(EventID=P^.EventID) and (@Proc=@P^.Proc);
end;
begin
  SearchHook:=FirstThat(@Match);
end;

procedure DebugEvent(EventID: TDebugEventID; InfoType: TDebugInfoType; Info: pointer);
   forward;

procedure DebugStr(EventID: TDebugEventID; const S: string);
var C: array[0..255] of char;
begin
  StrPCopy(@C,S);
  DebugStrP(EventID,@C);
end;

procedure DebugStrP(EventID: TDebugEventID; S: PChar);
begin
  DebugEvent(EventID,itLongString,S);
end;

procedure DebugInt(EventID: TDebugEventID; L: longint);
begin
  DebugEvent(EventID,itInteger,@L);
end;

procedure DebugFloat(EventID: TDebugEventID; D: double);
begin
  DebugEvent(EventID,itFloat,@D);
end;

procedure DebugPtr(EventID: TDebugEventID; P: pointer);
begin
  DebugEvent(EventID,itPointer,P);
end;

function DebSearchEventID(EventID: TDebugEventID): PDebugEventInfo;
var P: PDebugEventInfo;
begin
  if Assigned(DebugEvents)=false then
    P:=nil
  else
    P:=DebugEvents^.SearchEvent(EventID);
end;

function DebIsEventEnabled(EventID: TDebugEventID): boolean;
var P: PDebugEventInfo;
    E: boolean;
begin
  E:=(EventID=0);
  if E=false then
  begin
    P:=DebSearchEventID(EventID);
    if P=nil then E:=false else
      E:=(P^.Count>0);
  end;
  DebIsEventEnabled:=E;
end;

procedure DebEnableEvent(EventID: TDebugEventID);
var P: PDebugEventInfo;
begin
  if Assigned(DebugEvents)=false then Exit;

  P:=DebSearchEventID(EventID);
  if P=nil then
    begin
      P:=NewDebugEventInfo(EventID);
      DebugEvents^.Insert(P);
    end;
  Inc(P^.Count);
end;

procedure DebCheckEventDispose(P: PDebugEventInfo);
begin
  if P<>nil then
    begin
      Dec(P^.Count);
      if (P^.Count<=0) and (P^.Name=nil) then
        begin
          DebugEvents^.Delete(P);
          DisposeDebugEventInfo(P);
        end;
    end;
end;

procedure DebDisableEvent(EventID: TDebugEventID);
var P: PDebugEventInfo;
begin
  if Assigned(DebugEvents)=false then Exit;

  P:=DebSearchEventID(EventID);
  DebCheckEventDispose(P);
end;

function DebSearchHook(EventID: TDebugEventID; Proc: TDebugProc): PDebugHookInfo;
var P: PDebugHookInfo;
begin
  if Assigned(DebugHooks)=false then
    P:=nil
  else
    P:=DebugHooks^.SearchHook(EventID,Proc);
end;

procedure DebHook(EventID: TDebugEventID; Proc: TDebugProc);
var P: PDebugHookInfo;
begin
  if Assigned(DebugHooks)=false then Exit;

  P:=NewDebugHookInfo(EventID,Proc);
  DebugHooks^.Insert(P);
end;

procedure DebUnHook(EventID: TDebugEventID; Proc: TDebugProc);
var P: PDebugHookInfo;
begin
  if Assigned(DebugHooks)=false then Exit;

  P:=DebSearchHook(EventID,Proc);
  if P<>nil then
  begin
    DebugHooks^.Delete(P);
    DisposeDebugHookInfo(P);
  end;
end;

procedure DebugEvent(EventID: TDebugEventID; InfoType: TDebugInfoType; Info: pointer);
var EventEnabled: boolean;
function Dispatch(P: PDebugHookInfo): boolean; {$ifndef FPC}far;{$endif}
begin
  if P^.EventID=debug_Event_All then
    Dispatch:=not P^.Proc(EventID,InfoType,Info)
  else
    if (P^.EventID=EventID) and EventEnabled then
      Dispatch:=not P^.Proc(EventID,InfoType,Info)
    else
      Dispatch:=P^.EventID>EventID;
end;
begin
  if Assigned(DebugHooks) then
  begin
    EventEnabled:=DebIsEventEnabled(EventID);
    DebugHooks^.FirstThat(@Dispatch);
  end;
end;

procedure DebRegisterEvent(EventID: TDebugEventID; const EventName: string);
var P: PDebugEventInfo;
begin
  if Assigned(DebugEvents)=false then Exit;

  P:=DebSearchEventID(EventID);
  if P=nil then
    begin
      P:=NewDebugEventInfo(EventID);
      P^.Name:=NewStr(EventName);
      DebugEvents^.Insert(P);
    end
  else
    if P^.Name=nil then
      P^.Name:=NewStr(EventName);
end;

procedure DebDeRegisterEvent(EventID: TDebugEventID);
var P: PDebugEventInfo;
begin
  if Assigned(DebugEvents)=false then Exit;

  P:=DebSearchEventID(EventID);
  if Assigned(P) then
    if Assigned(P^.Name) then
      begin
        DisposeStr(P^.Name);
        P^.Name:=nil;
      end;
  DebCheckEventDispose(P);
end;

procedure DebInit;
begin
  if Assigned(DebugHooks)=false then New(DebugHooks, Init(10,10));
{  if Assigned(DebugEvents)=false then New(DebugEvents, Init(10,10));}
end;

procedure DebDone;
begin
  if Assigned(DebugHooks) then Dispose(DebugHooks, Done); DebugHooks:=nil;
{  if Assigned(DebugEvents) then Dispose(DebugEvents, Done); DebugEvents:=nil;}
end;

procedure InitDebugEvents;
begin
  New(DebugEvents, Init(0,200));
end;

procedure DoneDebugEvents;
begin
  if Assigned(DebugEvents) then Dispose(DebugEvents, Done); DebugEvents:=nil;
end;

{$else}

procedure DebInit; begin end;
procedure DebRegisterEvent(EventID: TDebugEventID; const EventName: string); begin end;
procedure DebDeRegisterEvent(EventID: TDebugEventID); begin end;
procedure DebEnableEvent(EventID: TDebugEventID); begin end;
procedure DebDisableEvent(EventID: TDebugEventID); begin end;
procedure DebHook(EventID: TDebugEventID; Proc: TDebugProc); begin end;
procedure DebUnHook(EventID: TDebugEventID; Proc: TDebugProc); begin end;
function  DebIsEventEnabled(EventID: TDebugEventID): boolean; begin end;
procedure DebDone; begin end;

procedure DebugStr(EventID: TDebugEventID; const S: string); begin end;
procedure DebugStrP(EventID: TDebugEventID; S: PChar); begin end;
procedure DebugInt(EventID: TDebugEventID; L: longint); begin end;
procedure DebugFloat(EventID: TDebugEventID; D: double); begin end;
procedure DebugPtr(EventID: TDebugEventID; P: pointer); begin end;

{$endif}

{$ifndef NODEBUG}
var OldExitProc: pointer;

procedure MyExitProc; far;
begin
  ExitProc:=OldExitProc;
  DoneDebugEvents;
end;

BEGIN
  OldExitProc:=ExitProc; ExitProc:=@MyExitProc;
  InitDebugEvents;
{$endif}
END.
