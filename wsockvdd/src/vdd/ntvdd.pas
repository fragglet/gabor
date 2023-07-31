{
    $Id: ntvdd.pas,v 1.0 1999/11/24 09:46:55 gabor Exp $

    Windows NT VDD hook routines

    Converted from NTVDD.H with H2PAS

 **********************************************************************}
unit NTVDD;

  interface

  uses windows;

  type
     HANDLE = THANDLE;
     PVOID = pointer;
     PPVOID = ^pointer;
     USHORT = word;

  { C default packing is dword }

{.$PACKRECORDS 4}
  {
      nt_vdd.h

      VDD services exports and defines

    }
  {
     IO port service prototypes and data structure definitions
     }
  {  Basic typedefs of VDD IO hooks   }

  type

     PFNVDD_INB = procedure (iport:WORD; data:pBYTE);stdcall;

     PFNVDD_INW = procedure (iport:WORD; data:pWORD);stdcall;

     PFNVDD_INSB = procedure (iport:WORD; data:pBYTE; count:WORD);stdcall;

     PFNVDD_INSW = procedure (iport:WORD; data:pWORD; count:WORD);stdcall;

     PFNVDD_OUTB = procedure (iport:WORD; data:BYTE);stdcall;

     PFNVDD_OUTW = procedure (iport:WORD; data:WORD);stdcall;

     PFNVDD_OUTSB = procedure (iport:WORD; data:pBYTE; count:WORD);stdcall;

     PFNVDD_OUTSW = procedure (iport:WORD; data:pWORD; count:WORD);stdcall;
  {   Array of handlers for VDD IO hooks.   }

     VDD_IO_HANDLERS = record
          inb_handler : PFNVDD_INB;
          inw_handler : PFNVDD_INW;
          insb_handler : PFNVDD_INSB;
          insw_handler : PFNVDD_INSW;
          outb_handler : PFNVDD_OUTB;
          outw_handler : PFNVDD_OUTW;
          outsb_handler : PFNVDD_OUTSB;
          outsw_handler : PFNVDD_OUTSW;
       end;

     PVDD_IO_HANDLERS = ^VDD_IO_HANDLERS;

     _VDD_IO_HANDLERS = VDD_IO_HANDLERS;
  {  Port Range structure   }

     VDD_IO_PORTRANGE = record
          First : WORD;
          Last : WORD;
       end;

     PVDD_IO_PORTRANGE = ^VDD_IO_PORTRANGE;

     _VDD_IO_PORTRANGE = VDD_IO_PORTRANGE;

  function VDDInstallIOHook(hVDD:HANDLE; cPortRange:WORD; pPortRange:PVDD_IO_PORTRANGE; IOhandler:PVDD_IO_HANDLERS):BOOL;stdcall;

  procedure VDDDeInstallIOHook(hVdd:HANDLE; cPortRange:WORD; pPortRange:PVDD_IO_PORTRANGE);stdcall;

  function VDDReserveIrqLine(hVdd:HANDLE; IrqLine:WORD):WORD;stdcall;

  function VDDReleaseIrqLine(hVdd:HANDLE; IrqLine:WORD):BOOL;stdcall;

  { 
     DMA service prototypes and data structure definitions
     }
  {  Buffer definition for returning DMA information   }

  type

     VDD_DMA_INFO = record
          addr : WORD;
          count : WORD;
          page : WORD;
          status : BYTE;
          mode : BYTE;
          mask : BYTE;
       end;

     PVDD_DMA_INFO = ^VDD_DMA_INFO;

     _VDD_DMA_INFO = VDD_DMA_INFO;
  {  bits for querying the DMA information   }

  const
     VDD_DMA_ADDR = $01;
     VDD_DMA_COUNT = $02;
     VDD_DMA_PAGE = $04;
     VDD_DMA_STATUS = $08;
     VDD_DMA_ALL = VDD_DMA_ADDR or VDD_DMA_COUNT or VDD_DMA_PAGE or VDD_DMA_STATUS;

    function VDDRequestDMA(hVDD:HANDLE; iChannel:WORD; Buffer:PVOID; length:DWORD):DWORD;stdcall;

    function VDDSetDMA(hVDD:HANDLE; iChannel:WORD; fDMA:WORD; Buffer:PVDD_DMA_INFO):BOOL;stdcall;

    function VDDQueryDMA(hVDD:HANDLE; iChannel:WORD; pDmaInfo:PVDD_DMA_INFO):BOOL;stdcall;

    {
       Memory mapped I/O service prototypes and data structure definitions
       }

    type

       PVDD_MEMORY_HANDLER = procedure (FaultAddress:PVOID; RWMode:ULONG);stdcall;

    function VDDInstallMemoryHook(hVDD:HANDLE; pStart:PVOID; count:DWORD; MemoryHandler:PVDD_MEMORY_HANDLER):BOOL;stdcall;

    function VDDDeInstallMemoryHook(hVDD:HANDLE; pStart:PVOID; count:DWORD):BOOL;stdcall;

    function VDDAllocMem(hVDD:HANDLE; Address:PVOID; Size:DWORD):BOOL;stdcall;

    function VDDFreeMem(hVDD:HANDLE; Address:PVOID; Size:DWORD):BOOL;stdcall;

    { 
       Misc. service prototypes and data structure definitions
       }
    function VDDIncludeMem(hVDD:HANDLE; Address:PVOID; Size:DWORD):BOOL;stdcall;

    procedure VDDTerminateVDM;stdcall;

    {  Basic typedefs of VDD User hooks   }

    type

       PFNVDD_UCREATE = procedure (DosPDB:USHORT);stdcall;

       PFNVDD_UTERMINATE = procedure (DosPDB:USHORT);stdcall;

       PFNVDD_UBLOCK = procedure ;stdcall;

       PFNVDD_URESUME = procedure ;stdcall;
    {   Array of handlers for VDD User hooks.   }

       PVDD_USER_HANDLERS = ^VDD_USER_HANDLERS;
       VDD_USER_HANDLERS = record
            hvdd : HANDLE;
            ucr_handler : PFNVDD_UCREATE;
            uterm_handler : PFNVDD_UTERMINATE;
            ublock_handler : PFNVDD_UBLOCK;
            uresume_handler : PFNVDD_URESUME;
            next : PVDD_USER_HANDLERS;
         end;


    {  Function prototypes   }

    function VDDInstallUserHook(hVDD:HANDLE; Ucr_Handler:PFNVDD_UCREATE; Uterm_Handler:PFNVDD_UTERMINATE; Ublock_handler:PFNVDD_UBLOCK; Uresume_handler:PFNVDD_URESUME):BOOL;stdcall;

    function VDDDeInstallUserHook(hVdd:HANDLE):BOOL;stdcall;

    procedure VDDTerminateUserHook(DosPDB:USHORT);stdcall;

    procedure VDDCreateUserHook(DosPDB:USHORT);stdcall;

    procedure VDDBlockUserHook;stdcall;

    procedure VDDResumeUserHook;stdcall;

    procedure VDDSimulate16;stdcall;

    function VDDAllocateDosHandle(pPDB:ULONG; ppSFT:pPVOID; ppJFT:pPVOID):SHORT;stdcall;

    procedure VDDAssociateNtHandle(pSFT:PVOID; h32File:HANDLE; wAccess:WORD);stdcall;

    function VDDReleaseDosHandle(pPDB:ULONG; hFile:SHORT):BOOL;stdcall;

    function VDDRetrieveNtHandle(pPDB:ULONG; hFile:SHORT; ppSFT:pPVOID; ppJFT:pPVOID):HANDLE;stdcall;


  implementation

const External_library='ntvdm.exe'; {Setup as you need!}

  function VDDInstallIOHook(hVDD:HANDLE; cPortRange:WORD; pPortRange:PVDD_IO_PORTRANGE; IOhandler:PVDD_IO_HANDLERS):BOOL;stdcall;external External_library name 'VDDInstallIOHook';

  procedure VDDDeInstallIOHook(hVdd:HANDLE; cPortRange:WORD; pPortRange:PVDD_IO_PORTRANGE);stdcall;external External_library name 'VDDDeInstallIOHook';

  function VDDReserveIrqLine(hVdd:HANDLE; IrqLine:WORD):WORD;stdcall;external External_library name 'VDDReserveIrqLine';

  function VDDReleaseIrqLine(hVdd:HANDLE; IrqLine:WORD):BOOL;stdcall;external External_library name 'VDDReleaseIrqLine';

    function VDDRequestDMA(hVDD:HANDLE; iChannel:WORD; Buffer:PVOID; length:DWORD):DWORD;stdcall;external External_library name 'VDDRequestDMA';

    function VDDSetDMA(hVDD:HANDLE; iChannel:WORD; fDMA:WORD; Buffer:PVDD_DMA_INFO):BOOL;stdcall;external External_library name 'VDDSetDMA';

    function VDDQueryDMA(hVDD:HANDLE; iChannel:WORD; pDmaInfo:PVDD_DMA_INFO):BOOL;stdcall;external External_library name 'VDDQueryDMA';

    function VDDInstallMemoryHook(hVDD:HANDLE; pStart:PVOID; count:DWORD; MemoryHandler:PVDD_MEMORY_HANDLER):BOOL;stdcall;external External_library name 'VDDInstallMemoryHook';

    function VDDDeInstallMemoryHook(hVDD:HANDLE; pStart:PVOID; count:DWORD):BOOL;stdcall;external External_library name 'VDDDeInstallMemoryHook';

    function VDDAllocMem(hVDD:HANDLE; Address:PVOID; Size:DWORD):BOOL;stdcall;external External_library name 'VDDAllocMem';

    function VDDFreeMem(hVDD:HANDLE; Address:PVOID; Size:DWORD):BOOL;stdcall;external External_library name 'VDDFreeMem';

    function VDDIncludeMem(hVDD:HANDLE; Address:PVOID; Size:DWORD):BOOL;stdcall;external External_library name 'VDDIncludeMem';

    procedure VDDTerminateVDM;stdcall;external External_library name 'VDDTerminateVDM';

    function VDDInstallUserHook(hVDD:HANDLE; Ucr_Handler:PFNVDD_UCREATE; Uterm_Handler:PFNVDD_UTERMINATE; Ublock_handler:PFNVDD_UBLOCK; Uresume_handler:PFNVDD_URESUME):BOOL;stdcall;external External_library name 'VDDInstallUserHook';

    function VDDDeInstallUserHook(hVdd:HANDLE):BOOL;stdcall;external External_library name 'VDDDeInstallUserHook';

    procedure VDDTerminateUserHook(DosPDB:USHORT);stdcall;external External_library name 'VDDTerminateUserHook';

    procedure VDDCreateUserHook(DosPDB:USHORT);stdcall;external External_library name 'VDDCreateUserHook';

    procedure VDDBlockUserHook;stdcall;external External_library name 'VDDBlockUserHook';

    procedure VDDResumeUserHook;stdcall;external External_library name 'VDDResumeUserHook';

    procedure VDDSimulate16;stdcall;external External_library name 'VDDSimulate16';

    function VDDAllocateDosHandle(pPDB:ULONG; ppSFT:pPVOID; ppJFT:pPVOID):SHORT;stdcall;external External_library name 'VDDAllocateDosHandle';

    procedure VDDAssociateNtHandle(pSFT:PVOID; h32File:HANDLE; wAccess:WORD);stdcall;external External_library name 'VDDAssociateNtHandle';

    function VDDReleaseDosHandle(pPDB:ULONG; hFile:SHORT):BOOL;stdcall;external External_library name 'VDDReleaseDosHandle';

    function VDDRetrieveNtHandle(pPDB:ULONG; hFile:SHORT; ppSFT:pPVOID; ppJFT:pPVOID):HANDLE;stdcall;external External_library name 'VDDRetrieveNtHandle';


end.
{
  $Log: ntvdd.pas,v $

  Revision 1.0  1999/11/24 09:46:55  gabor
     Original version

}

