{
    $Id: vddsvc.pas,v 1.0 1999/11/24 09:46:55 gabor Exp $

    Windows NT VDD service routines

    Converted from VDD_SVC.H with H2PAS

 **********************************************************************}
{$define i386}
unit VDDSVC;

interface

uses windows;

type USHORT = word;

  { C default packing is dword }

{.$PACKRECORDS 4}
  {++

  Copyright (c) 1992 Microsoft Corporation

  Module Name:

      VDDSVC.H

  Abstract:
  
      Include file contains VDM services provided for installable VDDs.


  -- }
  {
     This file contains VDM services prototype defintions only; their
     related structures and macros are defined in NT_VDD.H.
     If we have not included the file yet, include it and set a signal
     to tell anybody the fact.
    }

  {  Memory Accessing services   }
{  function GetVDMAddress(usSeg,usOff : longint) : longint; stdcall;}
  function GetVDMPointer(Address:ULONG; Size:ULONG; ProtectedMode:UCHAR): pointer; stdcall;
{  function FlushVDMPointer(Address:ULONG; Size:USHORT; Buffer:PBYTE; ProtectedMode:BOOLEAN):BOOLEAN; stdcall;}
{  function FreeVDMPointer(Address:ULONG; Size:USHORT; Buffer:PBYTE; ProtectedMode:BOOLEAN):BOOLEAN; stdcall;}

  {  interrupt simualtion services   }

  const
     ICA_MASTER = 0;
     ICA_SLAVE = 1;

    {  Register manipulation services   }

    function getEAX : ULONG; stdcall;
    function getAX : USHORT; stdcall;
    function getAL : UCHAR; stdcall;
    function getAH : UCHAR; stdcall;
    function getEBX : ULONG; stdcall;
    function getBX : USHORT; stdcall;
    function getBL : UCHAR; stdcall;
    function getBH : UCHAR; stdcall;
    function getECX : ULONG; stdcall;
    function getCX : USHORT; stdcall;
    function getCL : UCHAR; stdcall;
    function getCH : UCHAR; stdcall;
    function getEDX : ULONG; stdcall;
    function getDX : USHORT; stdcall;
    function getDL : UCHAR; stdcall;
    function getDH : UCHAR; stdcall;
    function getESP : ULONG; stdcall;
    function getSP : USHORT; stdcall;
    function getEBP : ULONG; stdcall;
    function getBP : USHORT; stdcall;
    function getESI : ULONG; stdcall;
    function getSI : USHORT; stdcall;
    function getEDI : ULONG; stdcall;
    function getDI : USHORT; stdcall;
    function getEIP : ULONG; stdcall;
    function getIP : USHORT; stdcall;
    function getCS : USHORT; stdcall;
    function getSS : USHORT; stdcall;
    function getDS : USHORT; stdcall;
    function getES : USHORT; stdcall;
    function getCF : longint; stdcall;
    function getPF : longint; stdcall;
    function getAF : longint; stdcall;
    function getZF : longint; stdcall;
    function getSF : longint; stdcall;
    function getIF : longint; stdcall;
    function getDF : longint; stdcall;
    function getOF : longint; stdcall;
    function getMSW : USHORT; stdcall;
    procedure setEAX(value : ULONG); stdcall;
    procedure setAX(value : USHORT); stdcall;
    procedure setAH(value : UCHAR); stdcall;
    procedure setAL(value : UCHAR); stdcall;
    procedure setEBX(value : ULONG); stdcall;
    procedure setBX(value : USHORT); stdcall;
    procedure setBH(value : UCHAR); stdcall;
    procedure setBL(value : UCHAR); stdcall;
    procedure setECX(value : ULONG); stdcall;
    procedure setCX(value : USHORT); stdcall;
    procedure setCH(value : UCHAR); stdcall;
    procedure setCL(value : UCHAR); stdcall;
    procedure setEDX(value : ULONG); stdcall;
    procedure setDX(value : USHORT); stdcall;
    procedure setDH(value : UCHAR); stdcall;
    procedure setDL(value : UCHAR); stdcall;
    procedure setESP(value : ULONG); stdcall;
    procedure setSP(value : USHORT); stdcall;
    procedure setEBP(value : ULONG); stdcall;
    procedure setBP(value : USHORT); stdcall;
    procedure setESI(value : ULONG); stdcall;
    procedure setSI(value : USHORT); stdcall;
    procedure setEDI(value : ULONG); stdcall;
    procedure setDI(value : USHORT); stdcall;
    procedure setEIP(value : ULONG); stdcall;
    procedure setIP(value : USHORT); stdcall;
    procedure setCS(value : USHORT); stdcall;
    procedure setSS(value : USHORT); stdcall;
    procedure setDS(value : USHORT); stdcall;
    procedure setES(value : USHORT); stdcall;
    procedure setCF(value : longint); stdcall;
    procedure setPF(value : longint); stdcall;
    procedure setAF(value : longint); stdcall;
    procedure setZF(value : longint); stdcall;
    procedure setSF(value : longint); stdcall;
    procedure setIF(value : longint); stdcall;
    procedure setDF(value : longint); stdcall;
    procedure setOF(value : longint); stdcall;
    procedure setMSW(value : USHORT); stdcall;

    {  Real function prototype declarations   }
    {  interrupt simulation functions   }

    procedure call_ica_hw_interrupt(ms:longint; line:BYTE; count:longint); stdcall;

    {  memory address manipulation functions   }
    function MGetVdmPointer(Address:ULONG; Size:ULONG; ProtectedMode:UCHAR):pointer;stdcall;


implementation

const External_library='ntvdm.exe'; {Setup as you need!}


    function GetVDMPointer(Address:ULONG; Size:ULONG; ProtectedMode:UCHAR):pointer; stdcall;
    begin
      Result:=MGetVDMPointer(Address,Size,ProtectedMode);
    end;

    procedure call_ica_hw_interrupt(ms:longint; line:BYTE; count:longint);stdcall;external External_library name 'call_ica_hw_interrupt';

    function MGetVdmPointer(Address:ULONG; Size:ULONG; ProtectedMode:UCHAR):pointer;stdcall;external External_library name 'MGetVdmPointer';

    function getEAX:ULONG; stdcall;external External_library name 'getEAX';

    function getAX:USHORT;stdcall;external External_library name 'getAX';

    function getAL:UCHAR;stdcall;external External_library name 'getAL';

    function getAH:UCHAR;stdcall;external External_library name 'getAH';

    function getEBX:ULONG;stdcall;external External_library name 'getEBX';

    function getBX:USHORT;stdcall;external External_library name 'getBX';

    function getBL:UCHAR;stdcall;external External_library name 'getBL';

    function getBH:UCHAR;stdcall;external External_library name 'getBH';

    function getECX:ULONG;stdcall;external External_library name 'getECX';

    function getCX:USHORT;stdcall;external External_library name 'getCX';

    function getCL:UCHAR;stdcall;external External_library name 'getCL';

    function getCH:UCHAR;stdcall;external External_library name 'getCH';

    function getEDX:ULONG;stdcall;external External_library name 'getEDX';

    function getDX:USHORT;stdcall;external External_library name 'getDX';

    function getDL:UCHAR;stdcall;external External_library name 'getDL';

    function getDH:UCHAR;stdcall;external External_library name 'getDH';

    function getESP:ULONG;stdcall;external External_library name 'getESP';

    function getSP:USHORT;stdcall;external External_library name 'getSP';

    function getEBP:ULONG;stdcall;external External_library name 'getEBP';

    function getBP:USHORT;stdcall;external External_library name 'getBP';

    function getESI:ULONG;stdcall;external External_library name 'getESI';

    function getSI:USHORT;stdcall;external External_library name 'getSI';

    function getEDI:ULONG;stdcall;external External_library name 'getEDI';

    function getDI:USHORT;stdcall;external External_library name 'getDI';

    function getEIP:ULONG;stdcall;external External_library name 'getEIP';

    function getIP:USHORT;stdcall;external External_library name 'getIP';

    function getCS:USHORT;stdcall;external External_library name 'getCS';

    function getSS:USHORT;stdcall;external External_library name 'getSS';

    function getDS:USHORT;stdcall;external External_library name 'getDS';

    function getES:USHORT;stdcall;external External_library name 'getES';

    function getFS:USHORT;stdcall;external External_library name 'getFS';

    function getGS:USHORT;stdcall;external External_library name 'getGS';

    function getCF:ULONG;stdcall;external External_library name 'getCF';

    function getPF:ULONG;stdcall;external External_library name 'getPF';

    function getAF:ULONG;stdcall;external External_library name 'getAF';

    function getZF:ULONG;stdcall;external External_library name 'getZF';

    function getSF:ULONG;stdcall;external External_library name 'getSF';

    function getIF:ULONG;stdcall;external External_library name 'getIF';

    function getDF:ULONG;stdcall;external External_library name 'getDF';

    function getOF:ULONG;stdcall;external External_library name 'getOF';

    function getMSW:USHORT;stdcall;external External_library name 'getMSW';

    procedure setEAX(value:ULONG);stdcall;external External_library name 'setEAX';

    procedure setAX(value:USHORT);stdcall;external External_library name 'setAX';

    procedure setAH(value:UCHAR);stdcall;external External_library name 'setAH';

    procedure setAL(value:UCHAR);stdcall;external External_library name 'setAL';

    procedure setEBX(value:ULONG);stdcall;external External_library name 'setEBX';

    procedure setBX(value:USHORT);stdcall;external External_library name 'setBX';

    procedure setBH(value:UCHAR);stdcall;external External_library name 'setBH';

    procedure setBL(value:UCHAR);stdcall;external External_library name 'setBL';

    procedure setECX(value:ULONG);stdcall;external External_library name 'setECX';

    procedure setCX(value:USHORT);stdcall;external External_library name 'setCX';

    procedure setCH(value:UCHAR);stdcall;external External_library name 'setCH';

    procedure setCL(value:UCHAR);stdcall;external External_library name 'setCL';

    procedure setEDX(value:ULONG);stdcall;external External_library name 'setEDX';

    procedure setDX(value:USHORT);stdcall;external External_library name 'setDX';

    procedure setDH(value:UCHAR);stdcall;external External_library name 'setDH';

    procedure setDL(value:UCHAR);stdcall;external External_library name 'setDL';

    procedure setESP(value:ULONG);stdcall;external External_library name 'setESP';

    procedure setSP(value:USHORT);stdcall;external External_library name 'setSP';

    procedure setEBP(value:ULONG);stdcall;external External_library name 'setEBP';

    procedure setBP(value:USHORT);stdcall;external External_library name 'setBP';

    procedure setESI(value:ULONG);stdcall;external External_library name 'setESI';

    procedure setSI(value:USHORT);stdcall;external External_library name 'setSI';

    procedure setEDI(value:ULONG);stdcall;external External_library name 'setEDI';

    procedure setDI(value:USHORT);stdcall;external External_library name 'setDI';

    procedure setEIP(value:ULONG);stdcall;external External_library name 'setEIP';

    procedure setIP(value:USHORT);stdcall;external External_library name 'setIP';

    procedure setCS(value:USHORT);stdcall;external External_library name 'setCS';

    procedure setSS(value:USHORT);stdcall;external External_library name 'setSS';

    procedure setDS(value:USHORT);stdcall;external External_library name 'setDS';

    procedure setES(value:USHORT);stdcall;external External_library name 'setES';

    procedure setFS(value:USHORT);stdcall;external External_library name 'setFS';

    procedure setGS(value:USHORT);stdcall;external External_library name 'setGS';

    procedure setCF(value:ULONG);stdcall; external External_library name 'setCF';

    procedure setPF(value:ULONG);stdcall;external External_library name 'setPF';

    procedure setAF(value:ULONG);stdcall;external External_library name 'setAF';

    procedure setZF(value:ULONG);stdcall;external External_library name 'setZF';

    procedure setSF(value:ULONG);stdcall;external External_library name 'setSF';

    procedure setIF(value:ULONG);stdcall;external External_library name 'setIF';

    procedure setDF(value:ULONG);stdcall;external External_library name 'setDF';

    procedure setOF(value:ULONG);stdcall;external External_library name 'setOF';

    procedure setMSW(value:USHORT);stdcall;external External_library name 'setMSW';


end.
{
  $Log: vddsvc.pas,v $

  Revision 1.0  1999/11/24 09:46:55  gabor
     Original version

}

