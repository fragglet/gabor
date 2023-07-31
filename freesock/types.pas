{
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Global types

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
{$ifdef VER70}{$define TP}{$endif}
{$ifndef FPC}{$ifdef win32}{$define DELPHI}{$endif}{$endif}
unit Types;

interface

{$ifdef win32}uses windows;{$endif}

type
   {$ifdef TP}
    sw_integer=integer;
   {$else}
    sw_integer=longint;
   {$endif}

   {$ifndef Delphi}
    WideChar=word;
    PWideChar=^WideChar;
   {$endif}

    {$ifdef UNICODE}
    AWChar = WideChar;
    PAWChar = PWideChar;
    {$else}
    AWChar = char;
    PAWChar = PChar;
    {$endif}

    smallint = integer;
    plongint = ^longint;

    u_char = byte;
    u_short = Word;
    u_int = {Integer}longint;
    u_long = Longint;

    uint = u_int;
    ulong = u_long;
    ushort = u_short;
    uchar = u_char;

    LRESULT = longint;

    dword = longint;
    pdword = ^dword;

    BOOL = longbool;

    FARPROC = Pointer;
    TFarProc = Pointer;

    HANDLE = {$ifdef win32}windows.THANDLE{$else}dword{$endif};
    THANDLE = HANDLE;
    PHANDLE = ^THANDLE;

    EVENT = HANDLE;
    TEVENT = EVENT;
    PEVENT = ^TEVENT;

    HWND = HANDLE;

    OVERLAPPED = {$ifdef win32}windows.TOVERLAPPED{$else}packed record
      Internal     : DWORD;
      InternalHigh : DWORD;
      Offset       : DWORD;
      OffsetHigh   : DWORD;
      hEvent       : TEVENT;
    end{$endif};
    TOverlapped = OVERLAPPED;
    POverlapped = ^TOverlapped;

implementation

END.