{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Generic support routines

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
unit SockUtil;

interface

uses Types,Sockets;

type TStrProc = procedure(const S: string);

function swapw(w: word): word;
function swapl(l: longint): longint;

function Max(const A,B: longint): longint;
function MaxR(const A,B: real): real;

{function GetLastSockError: longint;
function SetLastSockError(Err: longint): longint;}

function Min(const A,B: longint): longint;
function CheckRange(const Value,Min,Max: longint): boolean;
function GetDosTicks: longint;
function GetElapsedTicks(StartTime: longint): longint;
function GetTickDiff(StartTime, NowTime: longint): longint;
function TimeValToTicks(const TimeVal: TTimeVal): longint;
function BoolToStr(B: boolean; const TrueS, FalseS: string): string;
function IntToStr(const L: longint): string;
function IntToStrL(const L: longint; MinLen: integer): string;
function BCDToStr(BCD: byte; LeadingZero: boolean): string;
function VersionToStr(Version: word): string;
function HexToInt(const S: string): longint;
function IntToHex(L: longint; MinLen: integer): string;
function StrPCat(Dest: PChar; const Source: string): PChar;
function StrPas(C: PChar): string;
function UpcaseStr(S: string): string;
function CompareText(const S1,S2: string): sw_integer;
function RExpand(S: string; MinLen: integer): string;
function LExpand(S: string; MinLen: integer): string;

implementation

uses Strings;

{const LastSockError : longint = WSAOK;}

function swapw(w: word): word;
begin
  swapw:=swap(w);
end;

function swapl(l: longint): longint;
type TLongRec = packed record LoW, HiW: word; end;
var TempW: word;
begin
  with TLongRec(l) do
    begin
      TempW:=LoW; LoW:=swapw(HiW); HiW:=swapw(TempW);
    end;
  swapl:=l;
end;

function Max(const A,B: longint): longint;
begin
  if A>B then Max:=A else Max:=B;
end;

function MaxR(const A,B: real): real;
begin
  if A>B then MaxR:=A else MaxR:=B;
end;

{function GetLastSockError: longint;
begin
  GetLastSockError:=LastSockError;
end;

function SetLastSockError(Err: longint): longint;
var Result: longint;
begin
  LastSockError:=Err;
  if Err=WSAOK then Result:=0 else Result:=SOCKET_ERROR;
  SetLastSockError:=Result;
end;}

function CheckRange(const Value,Min,Max: longint): boolean;
begin
  CheckRange:=(Min<=Value) and (Value<=Max);
end;

function GetDosTicks: longint;
var TT: longint absolute $40:$6c;
begin
  GetDosTicks:=TT;
end;

function GetElapsedTicks(StartTime: longint): longint;
begin
  GetElapsedTicks:=GetTickDiff(StartTime,GetDosTicks);
end;

function GetTickDiff(StartTime, NowTime: longint): longint;
var Dif: longint;
const TicksPerSec = 1193181/65536; { ~18.2 }
      TicksPerMin = 60*TicksPerSec;
      TicksPerHour= 60*TicksPerMin;
      TicksPerDay = 24*TicksPerHour;
      TicksPerDayI = round(TicksPerDay);
begin
  if StartTime<=NowTime then
    Dif:=NowTime-StartTime
  else
    Dif:=TicksPerDayI-StartTime+NowTime;
  GetTickDiff:=Dif;
end;

function TimeValToTicks(const TimeVal: TTimeVal): longint;
var R: real;
    T: longint;
begin
  R:=((TimeVal.tv_sec*1000+TimeVal.tv_usec)/1000*18.2);
  if R>MaxLongint then T:=MaxLongint else T:=trunc(R);
  TimeValToTicks:=T;
end;

function Min(const A,B: longint): longint;
begin
  if A<B then Min:=A else Min:=B;
end;

function IntToStr(const L: longint): string;
var S: string;
begin
  Str(L,S);
  IntToStr:=S;
end;

function IntToStrL(const L: longint; MinLen: integer): string;
begin
  IntToStrL:=LExpand(IntToStr(L),MinLen);
end;

function BCDToStr(BCD: byte; LeadingZero: boolean): string;
var S: string[2];
const Nums: array[0..15] of char = '0123456789??????';
begin
  S:='';
  if (BCD and $0f)<>0 then
    S:=Nums[BCD and $0f];
  if ((BCD shr 4)<>0) or (LeadingZero) then
    S:=Nums[BCD shr 4]+S;
  if S='' then S:='0';
  BCDToStr:=S;
end;

function VersionToStr(Version: word): string;
begin
  VersionToStr:=BCDToStr(Hi(Version),false)+'.'+BCDToStr(Lo(Version),true);
end;

const HexNums: string[16] = '0123456789ABCDEF';

function HexToInt(const S: string): longint;
var I,P: integer;
    R: longint;
begin
  R:=0;
  for I:=1 to length(S) do
  begin
    P:=Pos(Upcase(S[I]),HexNums);
    if P=0 then
      begin
        R:=-1;
        Break;
      end
    else
      R:=R shl 4+(P-1);
  end;
  HexToInt:=R;
end;

function IntToHex(L: longint; MinLen: integer): string;
var S: string;
begin
  S:='';
  if L=0 then
    S:='0'
  else
    begin
      S:='';
      repeat
        S:=HexNums[(L and $0f)+1]+S;
        L:=L shr 4;
      until L=0;
    end;
  while length(S)<MinLen do S:='0'+S;
  IntToHex:=S;
end;

function StrPCat(Dest: PChar; const Source: string): PChar;
var C: array[0..256] of char;
begin
  StrPCopy(@C,Source);
  StrPCat:=StrCat(Dest,@C);
end;

function StrPas(C: PChar): string;
var S: string;
    I: longint;
begin
  if Assigned(C)=false then
    S:=''
  else
    begin
      I:=StrLen(C); if I>255 then I:=255;
      S[0]:=chr(I); Move(C^,S[1],I);
    end;
  StrPas:=S;
end;

function UpcaseStr(S: string): string;
var I: sw_integer;
begin
  for I:=1 to length(S) do
    if S[I] in['a'..'z'] then
      S[I]:=chr(ord(S[I])-32);
  UpcaseStr:=S;
end;

function CompareText(const S1,S2: string): sw_integer;
var U1,U2: string;
    R: integer;
begin
  U1:=UpcaseStr(S1); U2:=UpcaseStr(S2);
  if U1<U2 then R:=-1 else
  if U1>U2 then R:= 1 else
  R:=0;
  CompareText:=R;
end;

function RExpand(S: string; MinLen: integer): string;
begin
  while length(S)<MinLen do
    S:=S+' ';
  RExpand:=S;
end;

function LExpand(S: string; MinLen: integer): string;
begin
  while length(S)<MinLen do
    S:=' '+S;
  LExpand:=S;
end;

function BoolToStr(B: boolean; const TrueS, FalseS: string): string;
begin
  if B then
    BoolToStr:=TrueS
  else
    BoolToStr:=FalseS;
end;


END.