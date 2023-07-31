{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Stream objects

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
unit Streams;

interface

uses Objects;

type
    PMemBlock = ^TMemBlock;
    TMemBlock = record
      Size     : word;
      Data     : pointer;
      ReadOfs  : word;
      WriteOfs : word;
      Next     : PMemBlock;
    end;

    PSeqMemoryStream = ^TSeqMemoryStream;
    TSeqMemoryStream = object(TStream)
      constructor Init(AInitSize: longint; ABlockSize: word);
      function    GetPos: Longint; virtual;
      function    GetSize: Longint; virtual;
      procedure   Seek(Pos: Longint); virtual;
      procedure   Truncate; virtual;
      procedure   Read(var Buf; Count: Word); virtual;
      procedure   ReadAHead(var Buf; Count: Word);
      procedure   Write(var Buf; Count: Word); virtual;
    { private } public
      BlockSize: word;
      FirstBlock: PMemBlock;
      function    AllocNextBlock: PMemBlock;
      function    LastBlock: PMemBlock;
      procedure   DisposeFirstBlock;
    end;

implementation

function Min(A,B: longint): longint;
begin
  if A<B then Min:=A else Min:=B;
end;

const BlockCount: integer = 0;

function NewBlock(ASize: word): PMemBlock;
var P: PMemBlock;
begin
  New(P); FillChar(P^,SizeOf(P^),0);
  with P^ do
  begin
    Size:=ASize;
(*    write('|AB:',Size,'|');*)
    GetMem(Data,Size);
    ReadOfs:=0; WriteOfs:=0;
    Next:=nil;
  end;
  NewBlock:=P;
(*  Inc(BlockCount); write('|BC:',BlockCount,'|');*)
end;

procedure DisposeBlock(P: PMemBlock);
begin
  if P<>nil then
  begin
    if (P^.Data<>nil) and (P^.Size>0) then
      FreeMem(P^.Data,P^.Size);
    Dispose(P);
  end;
(*  Dec(BlockCount); write('|BC:',BlockCount,'|');*)
end;

constructor TSeqMemoryStream.Init(AInitSize: longint; ABlockSize: word);
var CurSize: longint;
begin
  inherited Init;
  BlockSize:=ABlockSize;

  CurSize:=0;
{  while (CurSize<AInitSize) do
    begin
      AllocNextBlock;
      Inc(CurSize,BlockSize);
    end;}
end;

function TSeqMemoryStream.GetPos: Longint;
begin
  GetPos:=-1;
end;

function TSeqMemoryStream.GetSize: Longint;
var P: PMemBlock;
    Size: longint;
begin
  Size:=0;
  P:=FirstBlock;
  while P<>nil do
    begin
      Inc(Size,P^.WriteOfs);
      Dec(Size,P^.ReadOfs);
      P:=P^.Next;
    end;
  GetSize:=Size;
end;

procedure TSeqMemoryStream.Seek(Pos: Longint);
var RemSize: longint;
    CurFrag: word;
    P: PMemBlock;
begin
  RemSize:=Pos;
  while (RemSize>0) do
    begin
      P:=FirstBlock;
      if P=nil then
        begin Error(stReadError,0); Exit; end;
      CurFrag:=P^.WriteOfs-P^.ReadOfs;
      if CurFrag>=RemSize then
        DisposeFirstBlock
      else
        Inc(P^.ReadOfs,RemSize);
      Dec(RemSize,CurFrag);
    end;
end;

procedure TSeqMemoryStream.Truncate;
begin
  Abstract;
end;

procedure TSeqMemoryStream.Read(var Buf; Count: Word);
var RemSize,CurFrag,DestOfs: word;
    P: PMemBlock;
begin
  RemSize:=Count; DestOfs:=0;
  while RemSize>0 do
  begin
    P:=FirstBlock;
    if P=nil then
      begin Error(stReadError,0); Exit; end;
    CurFrag:=Min(RemSize,P^.WriteOfs-P^.ReadOfs);
    Move(PByteArray(P^.Data)^[P^.ReadOfs],PByteArray(@Buf)^[DestOfs],CurFrag);
    Inc(P^.ReadOfs,CurFrag);
    if P^.ReadOfs=P^.WriteOfs then { end of block reached? }
      DisposeFirstBlock;
    Dec(RemSize,CurFrag); Inc(DestOfs,CurFrag);
  end;
end;

procedure TSeqMemoryStream.ReadAHead(var Buf; Count: Word);
var RemSize,CurFrag,DestOfs: word;
    PReadOfs: word;
    P: PMemBlock;
begin
  RemSize:=Count; DestOfs:=0;
  P:=FirstBlock;
  while RemSize>0 do
  begin
    if P=nil then
      begin Error(stReadError,0); Exit; end;
    PReadOfs:=P^.ReadOfs;
    CurFrag:=Min(RemSize,P^.WriteOfs-PReadOfs);
    Move(PByteArray(P^.Data)^[PReadOfs],PByteArray(@Buf)^[DestOfs],CurFrag);
    Inc(PReadOfs,CurFrag);
    if PReadOfs=P^.WriteOfs then { end of block reached? }
      P:=P^.Next;
    Dec(RemSize,CurFrag); Inc(DestOfs,CurFrag);
  end;
end;

procedure TSeqMemoryStream.Write(var Buf; Count: Word);
var RemSize,CurFrag,SrcOfs: word;
    P: PMemBlock;
begin
  RemSize:=Count; SrcOfs:=0;
  while RemSize>0 do
  begin
    P:=LastBlock;
    if P<>nil then
      CurFrag:=Min(RemSize,longint(P^.Size)-longint(P^.WriteOfs))
    else
      CurFrag:=0;
    if CurFrag=0 then
      begin
        P:=AllocNextBlock;
        CurFrag:=Min(RemSize,P^.Size);
      end;
    Move(PByteArray(@Buf)^[SrcOfs],PByteArray(P^.Data)^[P^.WriteOfs],CurFrag);
    Inc(P^.WriteOfs,CurFrag);
    Dec(RemSize,CurFrag); Inc(SrcOfs,CurFrag);
  end;
end;

function TSeqMemoryStream.AllocNextBlock: PMemBlock;
var P,I: PMemBlock;
begin
  P:=LastBlock;
  I:=NewBlock(BlockSize);
  if FirstBlock=nil then
    FirstBlock:=I
  else
    P^.Next:=I;
  AllocNextBlock:=I;
end;

procedure TSeqMemoryStream.DisposeFirstBlock;
var P: PMemBlock;
begin
  if FirstBlock=nil then Exit;

  P:=FirstBlock; FirstBlock:=FirstBlock^.Next;
  DisposeBlock(P);
end;

function TSeqMemoryStream.LastBlock: PMemBlock;
var P: PMemBlock;
begin
  P:=FirstBlock;
  if P<>nil then
    while (P^.Next<>nil) do
      P:=P^.Next;
  LastBlock:=P;
end;

END.