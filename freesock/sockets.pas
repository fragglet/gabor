{
    $Id: sockets.pas,v 1.0 1999/07/07 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    BSD-sockets compatible interface

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
{$ifdef TP}{$define DOS}{$endif}
{$ifdef GO32V2}{$define DOS}{$endif}
{$ifndef FPC}{$ifdef win32}{$define DELPHI}{$endif}{$endif}
unit Sockets;

{.$define WINSOCK} { define this for 100% WinSock binary compatibility     }
                   { this is not neccessary needed for the Windows target! }
{$define NOWS2}   { define this to prevent including of WinSock 2
                     structures and functions.                             }


{$ifdef NOWS2}
 {$undef WINSOCK2}
 {.$define NOWINSOCK2DEFS}
{$else}
 {$define WINSOCK2}
{$endif}

interface

uses {$ifdef Delphi}SysUtils,{$else}Strings,{$endif}Types;

const
  { Socket type constants }
{
 * The  following  may  be used in place of the address family, socket type, or
 * protocol  in  a  call  to WSASocket to indicate that the corresponding value
 * should  be taken from the supplied WSAPROTOCOL_INFO structure instead of the
 * parameter itself.
}
  FROM_PROTOCOL_INFO = -1;

  SOCK_STREAM        = 1;               { stream socket }
  SOCK_DGRAM         = 2;               { datagram socket }
  SOCK_RAW           = 3;               { raw-protocol interface }
  SOCK_RDM           = 4;               { reliably-delivered message }
  SOCK_SEQPACKET     = 5;               { sequenced packet stream }

  { Address family constants }
  AF_UNSPEC          = 0;               { unspecified }
  AF_UNIX            = 1;               { local to host (pipes, portals) }
  AF_INET            = 2;               { internetwork: UDP, TCP, etc. }
  AF_IMPLINK         = 3;               { arpanet imp addresses }
  AF_PUP             = 4;               { pup protocols: e.g. BSP }
  AF_CHAOS           = 5;               { mit CHAOS protocols }
  AF_IPX             = 6;               { IPX and SPX }
  AF_NS              = AF_IPX;          { XEROX NS protocols }
  AF_ISO             = 7;               { ISO protocols }
  AF_OSI             = AF_ISO;          { OSI is ISO }
  AF_ECMA            = 8;               { european computer manufacturers }
  AF_DATAKIT         = 9;               { datakit protocols }
  AF_CCITT           = 10;              { CCITT protocols, X.25 etc }
  AF_SNA             = 11;              { IBM SNA }
  AF_DECnet          = 12;              { DECnet }
  AF_DLI             = 13;              { Direct data link interface }
  AF_LAT             = 14;              { LAT }
  AF_HYLINK          = 15;              { NSC Hyperchannel }
  AF_APPLETALK       = 16;              { AppleTalk }
  AF_NETBIOS         = 17;              { NetBios-style addresses }
  AF_VOICEVIEW       = 18;              { VoiceView }
  AF_FIREFOX         = 19;              { FireFox }
  AF_UNKNOWN1        = 20;              { Somebody is using this! }
  AF_BAN             = 21;              { Banyan }
  AF_ATM             = 22;              { Native ATM Services }
  AF_INET6           = 23;              { Internetwork Version 6 }

  AF_MAX             = 24;

  { Protocol Family constants }
  PF_UNSPEC          = AF_UNSPEC;
  PF_UNIX            = AF_UNIX;
  PF_INET            = AF_INET;
  PF_IMPLINK         = AF_IMPLINK;
  PF_PUP             = AF_PUP;
  PF_CHAOS           = AF_CHAOS;
  PF_NS              = AF_NS;
  PF_IPX             = AF_IPX;
  PF_ISO             = AF_ISO;
  PF_OSI             = AF_OSI;
  PF_ECMA            = AF_ECMA;
  PF_DATAKIT         = AF_DATAKIT;
  PF_CCITT           = AF_CCITT;
  PF_SNA             = AF_SNA;
  PF_DECnet          = AF_DECnet;
  PF_DLI             = AF_DLI;
  PF_LAT             = AF_LAT;
  PF_HYLINK          = AF_HYLINK;
  PF_APPLETALK       = AF_APPLETALK;
  PF_VOICEVIEW       = AF_VOICEVIEW;
  PF_FIREFOX         = AF_FIREFOX;
  PF_UNKNOWN1        = AF_UNKNOWN1;
  PF_BAN             = AF_BAN;
  PF_ATM             = AF_ATM;
  PF_INET6           = AF_INET6;

  PF_MAX             = AF_MAX;

  { Internet protocol family (PF_INET) protocol constants }
  IPPROTO_IP     =   0;             { dummy for IP }
  IPPROTO_ICMP   =   1;             { control message protocol }
  IPPROTO_IGMP   =   2;             { group management protocol }
  IPPROTO_GGP    =   3;             { gateway^2 (deprecated) }
  IPPROTO_TCP    =   6;             { tcp }
  IPPROTO_PUP    =  12;             { pup }
  IPPROTO_UDP    =  17;             { user datagram protocol }
  IPPROTO_IDP    =  22;             { xns idp }
  IPPROTO_ND     =  77;             { UNOFFICIAL net disk proto }

  IPPROTO_RAW    =  255;            { raw IP packet }
  IPPROTO_MAX    =  256;

  { IPX protocol family (PF_IPX) protocol constants }
  NSPROTO_IPX    = 1000;            { internetwork packet exchange }
  NSPROTO_SPX    = 1256;            { sequenced packet exchange }
  NSPROTO_SPXII  = 1257;            { spx II }

  { NetBIOS protocol family (PF_NETBIOS) protocol constanst }
  NBPROTO_NETBIOS = PF_UNSPEC;

{ Port/socket numbers: network standard functions }
  IPPORT_ECHO           = 7;
  IPPORT_DISCARD        = 9;
  IPPORT_SYSTAT         = 11;
  IPPORT_DAYTIME        = 13;
  IPPORT_NETSTAT        = 15;
  IPPORT_FTP            = 21;
  IPPORT_TELNET         = 23;
  IPPORT_SMTP           = 25;
  IPPORT_TIMESERVER     = 37;
  IPPORT_NAMESERVER     = 42;
  IPPORT_WHOIS          = 43;
  IPPORT_MTP            = 57;

{ Port/socket numbers: host specific functions }
  IPPORT_TFTP           = 69;
  IPPORT_RJE            = 77;
  IPPORT_FINGER         = 79;
  IPPORT_TTYLINK        = 87;
  IPPORT_SUPDUP         = 95;

{ UNIX TCP sockets}
  IPPORT_EXECSERVER     = 512;
  IPPORT_LOGINSERVER    = 513;
  IPPORT_CMDSERVER      = 514;
  IPPORT_EFSSERVER      = 520;

{ UNIX UDP sockets }
  IPPORT_BIFFUDP        = 512;
  IPPORT_WHOSERVER      = 513;
  IPPORT_ROUTESERVER    = 520;
                        { 520+1 also used }

{ Ports < IPPORT_RESERVED are reserved for privileged processes (e.g. root). }
  IPPORT_RESERVED       = 1024;

{ Link numbers }
  IMPLINK_IP            = 155;
  IMPLINK_LOWEXPER      = 156;
  IMPLINK_HIGHEXPER     = 158;

{
 * Definitions of bits in internet address integers.
 * On subnets, the decomposition of addresses to host and net parts
 * is done according to subnet mask, not the masks here.
}
  IN_CLASSA_NET    = $FF000000;
  IN_CLASSA_NSHIFT = 24;
  IN_CLASSA_HOST   = $00FFFFFF;
  IN_CLASSA_MAX    = 128;

  IN_CLASSB_NET    = $FFFF0000;
  IN_CLASSB_NSHIFT = 16;
  IN_CLASSB_HOST   = $0000FFFF;
  IN_CLASSB_MAX    = 65536;

  IN_CLASSC_NET    = $FFFFFF00;
  IN_CLASSC_NSHIFT = 8;
  IN_CLASSC_HOST   = $000000FF;

  IN_CLASSD_NET    = $F0000000;       { These ones aren't really }
  IN_CLASSD_NSHIFT = 28;              { net and host fields, but }
  IN_CLASSD_HOST   = $0FFFFFFF;       { routing needn't know.    }

  INADDR_ANY       = $00000000;
  INADDR_LOOPBACK  = $7F000001;
  INADDR_BROADCAST = $FFFFFFFF;
  INADDR_NONE      = $FFFFFFFF;

  ADDR_ANY         = INADDR_ANY;
  FD_SETSIZE     =   64;

{ Level number for (get/set)sockopt() to apply to socket itself. }

  SOL_SOCKET      = $ffff;          { options for socket level }

  SOMAXCONN       = {$ifdef WINSOCK2}$7fffffff{$else}5{$endif};

  MSG_OOB         = $1;             { process out-of-band data }
  MSG_PEEK        = $2;             { peek at incoming message }
  MSG_DONTROUTE   = $4;             { send without using routing tables }

  MSG_PARTIAL     = $8000;          { partial send or recv for message xport }

  MSG_MAXIOVLEN   = 16;

{
 * WinSock 2 extension -- new flags for WSASend(), WSASendTo(), WSARecv() and
 *                          WSARecvFrom()
}
  MSG_INTERRUPT   = $10;            { send/recv in the interrupt context }

{ Option flags per-socket. }

  SO_DEBUG        = $0001;          { turn on debugging info recording }
  SO_ACCEPTCONN   = $0002;          { socket has had listen() }
  SO_REUSEADDR    = $0004;          { allow local address reuse }
  SO_KEEPALIVE    = $0008;          { keep connections alive }
  SO_DONTROUTE    = $0010;          { just use interface addresses }
  SO_BROADCAST    = $0020;          { permit sending of broadcast msgs }
  SO_USELOOPBACK  = $0040;          { bypass hardware when possible }
  SO_LINGER       = $0080;          { linger on close if data present }
  SO_OOBINLINE    = $0100;          { leave received OOB data in line }

  SO_DONTLINGER  =   $ff7f;

  SO_KEEPOPENAFTEREXIT = $A001;     { supported only by SPX }

{ Additional options. }

  SO_SNDBUF       = $1001;          { send buffer size }
  SO_RCVBUF       = $1002;          { receive buffer size }
  SO_SNDLOWAT     = $1003;          { send low-water mark }
  SO_RCVLOWAT     = $1004;          { receive low-water mark }
  SO_SNDTIMEO     = $1005;          { send timeout }
  SO_RCVTIMEO     = $1006;          { receive timeout }
  SO_ERROR        = $1007;          { get error status and clear }
  SO_TYPE         = $1008;          { get socket type }

{ WinSock 2 extension -- new options }
  SO_GROUP_ID       = $2001;        { ID of a socket group }
  SO_GROUP_PRIORITY = $2002;        { the relative priority within a group }
  SO_MAX_MSG_SIZE   = $2003;        { maximum message size }
  SO_PROTOCOL_INFOA = $2004;        { WSAPROTOCOL_INFOA structure }
  SO_PROTOCOL_INFOW = $2005;        { WSAPROTOCOL_INFOW structure }
{$ifdef UNICODE}
  SO_PROTOCOL_INFO  = SO_PROTOCOL_INFOW;
{$else}
  SO_PROTOCOL_INFO  = SO_PROTOCOL_INFOA;
{$endif UNICODE}
  PVD_CONFIG        = $3001;         { configuration info for service provider }


{ Options for connect and disconnect data and options.  Used only by
  non-TCP/IP transports such as DECNet, OSI TP4, etc. }

  SO_CONNDATA     = $7000;
  SO_CONNOPT      = $7001;
  SO_DISCDATA     = $7002;
  SO_DISCOPT      = $7003;
  SO_CONNDATALEN  = $7004;
  SO_CONNOPTLEN   = $7005;
  SO_DISCDATALEN  = $7006;
  SO_DISCOPTLEN   = $7007;

{ Option for opening sockets for synchronous access. }

  SO_OPENTYPE     = $7008;

  SO_SYNCHRONOUS_ALERT    = $10;
  SO_SYNCHRONOUS_NONALERT = $20;

{ Other NT-specific options. }

  SO_MAXDG        = $7009;
  SO_MAXPATHDG    = $700A;
  SO_UPDATE_ACCEPT_CONTEXT     = $700B; 
  SO_CONNECT_TIME = $700C; 

{ TCP options. }

  TCP_NODELAY     = $0001;
  TCP_BSDURGENT   = $7000;

{ WinSock 2 extension -- bit values and indices for FD_XXX network events }
  FD_READ_BIT     = 0;
  FD_WRITE_BIT    = 1;
  FD_OOB_BIT      = 2;
  FD_ACCEPT_BIT   = 3;
  FD_CONNECT_BIT  = 4;
  FD_CLOSE_BIT    = 5;
  FD_QOS_BIT      = 6;
  FD_GROUP_QOS_BIT= 7;
  FD_MAX_EVENTS   = 8;

  FD_READ         = (1 shl FD_READ_BIT);
  FD_WRITE        = (1 shl FD_WRITE_BIT);
  FD_OOB          = (1 shl FD_OOB_BIT);
  FD_ACCEPT       = (1 shl FD_ACCEPT_BIT);
  FD_CONNECT      = (1 shl FD_CONNECT_BIT);
  FD_CLOSE        = (1 shl FD_CLOSE_BIT);
  FD_QOS          = (1 shl FD_QOS_BIT);
  FD_GROUP_QOS    = (1 shl FD_GROUP_QOS_BIT);
  FD_ALL_EVENTS   = ((1 shl FD_MAX_EVENTS) - 1);
  FD_ALL          = FD_ALL_EVENTS;

{
 * Commands for ioctlsocket()
 *
 * Ioctl's have the command encoded in the lower word,
 * and the size of any in or out parameters in the upper
 * word.  The high 2 bits of the upper word are used
 * to encode the in/out status of the parameter; for now
 * we restrict parameters to at most 128 bytes.
 *
}
  IOCPARM_MASK = $7f;
  IOC_VOID     = $20000000; { no parameters  }
  IOC_OUT      = $40000000; { copy out parameters  }
  IOC_IN       = $80000000; { copy in parameters  }
  IOC_INOUT    = IOC_IN or IOC_OUT; { 0x20000000 distinguishes new & old ioctl's }

  FIONREAD     = IOC_OUT + (sizeof(u_long) and IOCPARM_MASK) shl 16 + ord('f') shl 8 + 127; { get # bytes to read }
  FIONBIO      = IOC_IN  + (sizeof(u_long) and IOCPARM_MASK) shl 16 + ord('f') shl 8 + 126; { set/clear non-blocking i/o }
  FIOASYNC     = IOC_IN  + (sizeof(u_long) and IOCPARM_MASK) shl 16 + ord('f') shl 8 + 125; { set/clear async i/o }

{ Socket I/O Controls }
  SIOCSHIWAT   = IOC_IN  + (sizeof(u_long) and IOCPARM_MASK) shl 16 + ord('s') shl 8 +   0; { set high watermark }
  SIOCGHIWAT   = IOC_OUT + (sizeof(u_long) and IOCPARM_MASK) shl 16 + ord('s') shl 8 +   1; { get high watermark }
  SIOCSLOWAT   = IOC_IN  + (sizeof(u_long) and IOCPARM_MASK) shl 16 + ord('s') shl 8 +   2; { set low watermark }
  SIOCGLOWAT   = IOC_OUT + (sizeof(u_long) and IOCPARM_MASK) shl 16 + ord('s') shl 8 +   3; { get low watermark }
  SIOCATMARK   = IOC_OUT + (sizeof(u_long) and IOCPARM_MASK) shl 16 + ord('s') shl 8 +   7; { at oob mark? }

{ constants local to this interface (ie. non-standard values) }
  DIODUMP      = IOC_IN  + (sizeof(u_long) and IOCPARM_MASK) shl 16 + ord('d') shl 8 +   0; { dump stack contents }

{$ifndef NOWINSOCK2DEFS}
  { WinSock 2 extension -- new error codes and type definition }

type
  TWSAEVENT = THANDLE;
  PWSAEVENT = PHANDLE;

  TWSAOVERLAPPED   = OVERLAPPED;
  PWSAOVERLAPPED   = ^TWSAOVERLAPPED;

{
 * WinSock 2 extension -- WSABUF and QOS struct, include qos.h
 * to pull in FLOWSPEC and related definitions
}
  PWSABuf = ^TWSABuf;
  TWSABUF = packed record
    len     : u_long; { the length of the buffer }
    buf     : PChar;  { the pointer to the buffer }
  end;

  PGroup = ^TGroup;
  TGROUP = u_int;

{$i qos.inc}

  PQualityOfService = ^TQualityOfService;
  TQualityOfService = packed record
    SendingFlowspec  : TFLOWSPEC; { the flow spec for data sending }
    ReceivingFlowspec: TFLOWSPEC; { the flow spec for data receiving }
    ProviderSpecific : TWSABUF;   { additional provider specific stuff }
  end;
  PQOS = PQualityOfService;

const
{  WSA_IO_PENDING         = (ERROR_IO_PENDING);
  WSA_IO_INCOMPLETE      = (ERROR_IO_INCOMPLETE);
  WSA_INVALID_HANDLE     = (ERROR_INVALID_HANDLE);
  WSA_INVALID_PARAMETER  = (ERROR_INVALID_PARAMETER);
  WSA_NOT_ENOUGH_MEMORY  = (ERROR_NOT_ENOUGH_MEMORY);
  WSA_OPERATION_ABORTED  = (ERROR_OPERATION_ABORTED);

  WSA_INVALID_EVENT      = TWSAEVENT(0);
  WSA_MAXIMUM_WAIT_EVENTS= (MAXIMUM_WAIT_OBJECTS);
  WSA_WAIT_FAILED        = ((DWORD)-1L);
  WSA_WAIT_EVENT_0       = (WAIT_OBJECT_0);
  WSA_WAIT_IO_COMPLETION = (WAIT_IO_COMPLETION);
  WSA_WAIT_TIMEOUT       = (WAIT_TIMEOUT);
  WSA_INFINITE           = (INFINITE);}

{ WinSock 2 extension -- manifest constants for return values of the condition function }
  CF_ACCEPT       = $0000;
  CF_REJECT       = $0001;
  CF_DEFER        = $0002;

{ WinSock 2 extension -- manifest constants for shutdown() }
  SD_RECEIVE      = $00;
  SD_SEND         = $01;
  SD_BOTH         = $02;

{ WinSock 2 extension -- data type and manifest constants for socket groups }
  SG_UNCONSTRAINED_GROUP  = $01;
  SG_CONSTRAINED_GROUP    = $02;

{ WinSock 2 extension -- data type for WSAEnumNetworkEvents() }
type
  PWSANetworkEvents = ^TWSANetworkEvents;
  TWSAnetworkEvents = packed record
    lNetworkEvents: u_long;
    iErrorCode: array[0..FD_MAX_EVENTS-1] of u_int;
  end;

{ WinSock 2 extension -- WSAPROTOCOL_INFO structure and associated manifest constants }
  PGUID = ^TGUID;
  TGUID = packed record
    Data1: u_long;
    Data2: u_short;
    Data3: u_short;
    Data4: array[0..7] of u_char;
  end;

const
  MAX_PROTOCOL_CHAIN = 7;

  BASE_PROTOCOL      = 1;
  LAYERED_PROTOCOL   = 0;

  WSAPROTOCOL_LEN    = 255;

type
  TWSAPROTOCOLCHAIN = packed record
    ChainLen  : u_int;   { the length of the chain, }
                         { length = 0 means layered protocol, }
                         { length = 1 means base protocol, }
                         { length > 1 means protocol chain }
    ChainEntries: array [0..MAX_PROTOCOL_CHAIN-1] of dword;
    { a list of dwCatalogEntryIds }
  end;

  PWSAProtocolInfoA = ^TWSAProtocolInfoA;
  TWSAProtocolInfoA = packed record
    dwServiceFlags1: DWORD;
    dwServiceFlags2: DWORD;
    dwServiceFlags3: DWORD;
    dwServiceFlags4: DWORD;
    dwProviderFlags: DWORD;
    ProviderId: TGUID;
    dwCatalogEntryId: DWORD;
    ProtocolChain: TWSAPROTOCOLCHAIN;
    iVersion: u_int;
    iAddressFamily: u_int;
    iMaxSockAddr: u_int;
    iMinSockAddr: u_int;
    iSocketType: u_int;
    iProtocol: u_int;
    iProtocolMaxOffset: u_int;
    iNetworkByteOrder: u_int;
    iSecurityScheme: u_int;
    dwMessageSize: DWORD;
    dwProviderReserved: DWORD;
    szProtocol: array[0..WSAPROTOCOL_LEN] of char;
   end;

  PWSAProtocolInfoW = ^TWSAProtocolInfoW;
  TWSAProtocolInfoW = packed record
    dwServiceFlags1: DWORD;
    dwServiceFlags2: DWORD;
    dwServiceFlags3: DWORD;
    dwServiceFlags4: DWORD;
    dwProviderFlags: DWORD;
    ProviderId: TGUID;
    dwCatalogEntryId: DWORD;
    ProtocolChain: TWSAPROTOCOLCHAIN;
    iVersion: u_int;
    iAddressFamily: u_int;
    iMaxSockAddr: u_int;
    iMinSockAddr: u_int;
    iSocketType: u_int;
    iProtocol: u_int;
    iProtocolMaxOffset: u_int;
    iNetworkByteOrder: u_int;
    iSecurityScheme: u_int;
    dwMessageSize: DWORD;
    dwProviderReserved: DWORD;
    szProtocol: array[0..WSAPROTOCOL_LEN] of WideChar;
  end;

{$ifdef UNICODE}
  TWSAProtocolInfo = TWSAProtocolInfoW;
  PWSAProtocolInfo = PWSAProtocolInfoW;
{$else}
  TWSAProtocolInfo = TWSAProtocolInfoA;
  PWSAProtocolInfo = PWSAProtocolInfoA;
{$endif}

const
{ Flag bit definitions for dwProviderFlags }
  PFL_MULTIPLE_PROTO_ENTRIES   = $00000001;
  PFL_RECOMMENDED_PROTO_ENTRY  = $00000002;
  PFL_HIDDEN                   = $00000004;
  PFL_MATCHES_PROTOCOL_ZERO    = $00000008;

{ Flag bit definitions for dwServiceFlags1 }
  XP1_CONNECTIONLESS           = $00000001;
  XP1_GUARANTEED_DELIVERY      = $00000002;
  XP1_GUARANTEED_ORDER         = $00000004;
  XP1_MESSAGE_ORIENTED         = $00000008;
  XP1_PSEUDO_STREAM            = $00000010;
  XP1_GRACEFUL_CLOSE           = $00000020;
  XP1_EXPEDITED_DATA           = $00000040;
  XP1_CONNECT_DATA             = $00000080;
  XP1_DISCONNECT_DATA          = $00000100;
  XP1_SUPPORT_BROADCAST        = $00000200;
  XP1_SUPPORT_MULTIPOINT       = $00000400;
  XP1_MULTIPOINT_CONTROL_PLANE = $00000800;
  XP1_MULTIPOINT_DATA_PLANE    = $00001000;
  XP1_QOS_SUPPORTED            = $00002000;
  XP1_INTERRUPT                = $00004000;
  XP1_UNI_SEND                 = $00008000;
  XP1_UNI_RECV                 = $00010000;
  XP1_IFS_HANDLES              = $00020000;
  XP1_PARTIAL_MESSAGE          = $00040000;

  BIGENDIAN                     = $0000;
  LITTLEENDIAN                  = $0001;

  SECURITY_PROTOCOL_NONE        = $0000;

{ WinSock 2 extension -- manifest constants for WSAJoinLeaf() }
  JL_SENDER_ONLY    = $01;
  JL_RECEIVER_ONLY  = $02;
  JL_BOTH           = $04;

{ WinSock 2 extension -- manifest constants for WSASocket() }
  WSA_FLAG_OVERLAPPED           = $01;
  WSA_FLAG_MULTIPOINT_C_ROOT    = $02;
  WSA_FLAG_MULTIPOINT_C_LEAF    = $04;
  WSA_FLAG_MULTIPOINT_D_ROOT    = $08;
  WSA_FLAG_MULTIPOINT_D_LEAF    = $10;

{ WinSock 2 extension -- manifest constants for WSAIoctl() }
  IOC_UNIX                      = $00000000;
  IOC_WS2                       = $08000000;
  IOC_PROTOCOL                  = $10000000;
  IOC_VENDOR                    = $18000000;

  SIO_ASSOCIATE_HANDLE          = IOC_WS2 + IOC_IN + 1;
  SIO_ENABLE_CIRCULAR_QUEUEING  = IOC_WS2 + IOC_VOID + 2;
  SIO_FIND_ROUTE                = IOC_WS2 + IOC_OUT + 3;
  SIO_FLUSH                     = IOC_WS2 + IOC_VOID + 4;
  SIO_GET_BROADCAST_ADDRESS     = IOC_WS2 + IOC_OUT + 5;
  SIO_GET_EXTENSION_FUNCTION_POINTER  = IOC_WS2 + IOC_INOUT + 6;
  SIO_GET_QOS                   = IOC_WS2 + IOC_INOUT + 7;
  SIO_GET_GROUP_QOS             = IOC_WS2 + IOC_INOUT + 8;
  SIO_MULTIPOINT_LOOPBACK       = IOC_WS2 + IOC_IN + 9;
  SIO_MULTICAST_SCOPE           = IOC_WS2 + IOC_IN + 10;
  SIO_SET_QOS                   = IOC_WS2 + IOC_IN + 11;
  SIO_SET_GROUP_QOS             = IOC_WS2 + IOC_IN + 12;
  SIO_TRANSLATE_HANDLE          = IOC_WS2 + IOC_INOUT + 13;

{ WinSock 2 extension -- manifest constants for SIO_TRANSLATE_HANDLE ioctl }
  TH_NETDEV        = $00000001;
  TH_TAPI          = $00000002;

{
 * Manifest constants and type definitions related to name resolution and
 * registration (RNR) API
}
type
  PBlob = ^TBlob;
  TBlob = packed record
    cbSize: u_long;
    pBlobData: pointer;
  end;

const
{ Service Install Flags }
  SERVICE_MULTIPLE     =  ($00000001);

{ Name Spaces }
  NS_ALL               = (0);
  NS_SAP               = (1);
  NS_NDS               = (2);
  NS_PEER_BROWSE       = (3);
  NS_TCPIP_LOCAL       = (10);
  NS_TCPIP_HOSTS       = (11);
  NS_DNS               = (12);
  NS_NETBT             = (13);
  NS_WINS              = (14);
  NS_NBP               = (20);
  NS_MS                = (30);
  NS_STDA              = (31);
  NS_NTDS              = (32);
  NS_X500              = (40);
  NS_NIS               = (41);
  NS_NISPLUS           = (42);
  NS_WRQ               = (50);

{
 * Resolution flags for WSAGetAddressByName().
 * Note these are also used by the 1.1 API GetAddressByName, so
 * leave them around.
}

  RES_UNUSED_1         = ($00000001);
  RES_FLUSH_CACHE      = ($00000002);
  RES_SERVICE          = ($00000004);

{ Well known value names for Service Types }

  SERVICE_TYPE_VALUE_IPXPORTA    = 'IpxSocket';
{  SERVICE_TYPE_VALUE_IPXPORTW    = 'IpxSocket';}
  SERVICE_TYPE_VALUE_SAPIDA      =  'SapId';
{  SERVICE_TYPE_VALUE_SAPIDW      = L'SapId';}
  SERVICE_TYPE_VALUE_TCPPORTA    =  'TcpPort';
{  SERVICE_TYPE_VALUE_TCPPORTW    = L'TcpPort';}
  SERVICE_TYPE_VALUE_UDPPORTA    =  'UdpPort';
{  SERVICE_TYPE_VALUE_UDPPORTW    = L'UdpPort';}
  SERVICE_TYPE_VALUE_OBJECTIDA   =  'ObjectId';
{  SERVICE_TYPE_VALUE_OBJECTIDW   = L'ObjectId';}

{$ifdef UNICODE}
  SERVICE_TYPE_VALUE_SAPID       = SERVICE_TYPE_VALUE_SAPIDW;
  SERVICE_TYPE_VALUE_TCPPORT     = SERVICE_TYPE_VALUE_TCPPORTW;
  SERVICE_TYPE_VALUE_UDPPORT     = SERVICE_TYPE_VALUE_UDPPORTW;
  SERVICE_TYPE_VALUE_OBJECTID    = SERVICE_TYPE_VALUE_OBJECTIDW;
{$else}
  SERVICE_TYPE_VALUE_SAPID       = SERVICE_TYPE_VALUE_SAPIDA;
  SERVICE_TYPE_VALUE_TCPPORT     = SERVICE_TYPE_VALUE_TCPPORTA;
  SERVICE_TYPE_VALUE_UDPPORT     = SERVICE_TYPE_VALUE_UDPPORTA;
  SERVICE_TYPE_VALUE_OBJECTID    = SERVICE_TYPE_VALUE_OBJECTIDA;
{$endif}

{$endif}

{ All Sockets error constants are biased by WSABASEERR from the "normal" }

  WSAOK                   = 0;

  WSABASEERR              = 10000;

{ Sockets definitions of regular Microsoft C error constants }

  WSAEINTR                = (WSABASEERR+4);
  WSAEBADF                = (WSABASEERR+9);
  WSAEACCES               = (WSABASEERR+13);
  WSAEFAULT               = (WSABASEERR+14);
  WSAEINVAL               = (WSABASEERR+22);
  WSAEMFILE               = (WSABASEERR+24);

{ Sockets definitions of regular Berkeley error constants }

  WSAEWOULDBLOCK          = (WSABASEERR+35);
  WSAEINPROGRESS          = (WSABASEERR+36);
  WSAEALREADY             = (WSABASEERR+37);
  WSAENOTSOCK             = (WSABASEERR+38);
  WSAEDESTADDRREQ         = (WSABASEERR+39);
  WSAEMSGSIZE             = (WSABASEERR+40);
  WSAEPROTOTYPE           = (WSABASEERR+41);
  WSAENOPROTOOPT          = (WSABASEERR+42);
  WSAEPROTONOSUPPORT      = (WSABASEERR+43);
  WSAESOCKTNOSUPPORT      = (WSABASEERR+44);
  WSAEOPNOTSUPP           = (WSABASEERR+45);
  WSAEPFNOSUPPORT         = (WSABASEERR+46);
  WSAEAFNOSUPPORT         = (WSABASEERR+47);
  WSAEADDRINUSE           = (WSABASEERR+48);
  WSAEADDRNOTAVAIL        = (WSABASEERR+49);
  WSAENETDOWN             = (WSABASEERR+50);
  WSAENETUNREACH          = (WSABASEERR+51);
  WSAENETRESET            = (WSABASEERR+52);
  WSAECONNABORTED         = (WSABASEERR+53);
  WSAECONNRESET           = (WSABASEERR+54);
  WSAENOBUFS              = (WSABASEERR+55);
  WSAEISCONN              = (WSABASEERR+56);
  WSAENOTCONN             = (WSABASEERR+57);
  WSAESHUTDOWN            = (WSABASEERR+58);
  WSAETOOMANYREFS         = (WSABASEERR+59);
  WSAETIMEDOUT            = (WSABASEERR+60);
  WSAECONNREFUSED         = (WSABASEERR+61);
  WSAELOOP                = (WSABASEERR+62);
  WSAENAMETOOLONG         = (WSABASEERR+63);
  WSAEHOSTDOWN            = (WSABASEERR+64);
  WSAEHOSTUNREACH         = (WSABASEERR+65);
  WSAENOTEMPTY            = (WSABASEERR+66);
  WSAEPROCLIM             = (WSABASEERR+67);
  WSAEUSERS               = (WSABASEERR+68);
  WSAEDQUOT               = (WSABASEERR+69);
  WSAESTALE               = (WSABASEERR+70);
  WSAEREMOTE              = (WSABASEERR+71);

  WSAEDISCON              = (WSABASEERR+101);
  WSAENOMORE              = (WSABASEERR+102);
  WSAECANCELLED           = (WSABASEERR+103);
  WSAEINVALIDPROCTABLE    = (WSABASEERR+104);
  WSAEINVALIDPROVIDER     = (WSABASEERR+105);
  WSAEPROVIDERFAILEDINIT  = (WSABASEERR+106);
  WSASYSCALLFAILURE       = (WSABASEERR+107);
  WSASERVICE_NOT_FOUND    = (WSABASEERR+108);
  WSATYPE_NOT_FOUND       = (WSABASEERR+109);
  WSA_E_NO_MORE           = (WSABASEERR+110);
  WSA_E_CANCELLED         = (WSABASEERR+111);
  WSAEREFUSED             = (WSABASEERR+112);

{ Extended Sockets error constant definitions }

  WSASYSNOTREADY          = (WSABASEERR+91);
  WSAVERNOTSUPPORTED      = (WSABASEERR+92);
  WSANOTINITIALISED       = (WSABASEERR+93);

{ Error return codes from gethostbyname() and gethostbyaddr()
  (when using the resolver). Note that these errors are
  retrieved via WSAGetLastError() and must therefore follow
  the rules for avoiding clashes with error numbers from
  specific implementations or language run-time systems.
  For this reason the codes are based at WSABASEERR+1001.
  Note also that [FSA]NO_ADDRESS is defined only for
  compatibility purposes. }

{ Authoritative Answer: Host not found }

  WSAHOST_NOT_FOUND       = (WSABASEERR+1001);
  HOST_NOT_FOUND          = WSAHOST_NOT_FOUND;

{ Non-Authoritative: Host not found, or SERVERFAIL }

  WSATRY_AGAIN            = (WSABASEERR+1002);
  TRY_AGAIN               = WSATRY_AGAIN;

{ Non recoverable errors, FORMERR, REFUSED, NOTIMP }

  WSANO_RECOVERY          = (WSABASEERR+1003);
  NO_RECOVERY             = WSANO_RECOVERY;

{ Valid name, no data record of requested type }

  WSANO_DATA              = (WSABASEERR+1004);
  NO_DATA                 = WSANO_DATA;

{ no address, look for MX record }

  WSANO_ADDRESS           = WSANO_DATA;
  NO_ADDRESS              = WSANO_ADDRESS;

  { Error constants }
  EWOULDBLOCK        =  WSAEWOULDBLOCK;
  EINPROGRESS        =  WSAEINPROGRESS;
  EALREADY           =  WSAEALREADY;
  ENOTSOCK           =  WSAENOTSOCK;
  EDESTADDRREQ       =  WSAEDESTADDRREQ;
  EMSGSIZE           =  WSAEMSGSIZE;
  EPROTOTYPE         =  WSAEPROTOTYPE;
  ENOPROTOOPT        =  WSAENOPROTOOPT;
  EPROTONOSUPPORT    =  WSAEPROTONOSUPPORT;
  ESOCKTNOSUPPORT    =  WSAESOCKTNOSUPPORT;
  EOPNOTSUPP         =  WSAEOPNOTSUPP;
  EPFNOSUPPORT       =  WSAEPFNOSUPPORT;
  EAFNOSUPPORT       =  WSAEAFNOSUPPORT;
  EADDRINUSE         =  WSAEADDRINUSE;
  EADDRNOTAVAIL      =  WSAEADDRNOTAVAIL;
  ENETDOWN           =  WSAENETDOWN;
  ENETUNREACH        =  WSAENETUNREACH;
  ENETRESET          =  WSAENETRESET;
  ECONNABORTED       =  WSAECONNABORTED;
  ECONNRESET         =  WSAECONNRESET;
  ENOBUFS            =  WSAENOBUFS;
  EISCONN            =  WSAEISCONN;
  ENOTCONN           =  WSAENOTCONN;
  ESHUTDOWN          =  WSAESHUTDOWN;
  ETOOMANYREFS       =  WSAETOOMANYREFS;
  ETIMEDOUT          =  WSAETIMEDOUT;
  ECONNREFUSED       =  WSAECONNREFUSED;
  ELOOP              =  WSAELOOP;
  ENAMETOOLONG       =  WSAENAMETOOLONG;
  EHOSTDOWN          =  WSAEHOSTDOWN;
  EHOSTUNREACH       =  WSAEHOSTUNREACH;
  ENOTEMPTY          =  WSAENOTEMPTY;
  EPROCLIM           =  WSAEPROCLIM;
  EUSERS             =  WSAEUSERS;
  EDQUOT             =  WSAEDQUOT;
  ESTALE             =  WSAESTALE;
  EREMOTE            =  WSAEREMOTE;

  WSADESCRIPTION_LEN     =   256;
  WSASYS_STATUS_LEN      =   128;

type
  SunB = packed record
    s_b1, s_b2, s_b3, s_b4: u_char;
  end;

  SunW = packed record
    s_w1, s_w2: u_short;
  end;

  PInAddr = ^TInAddr;
  TInAddr = packed record
    case integer of
      0: (S_un_b: SunB);
      1: (S_un_w: SunW);
      2: (S_addr: u_long);
      3: (S_net  : u_char;
          S_host : u_char;
          S_lh   : u_char;
          S_impno: u_char);
      4: (S_dummyw: u_short;
          S_imp   : u_short);
  end;

  PSockAddrIn = ^TSockAddrIn;
  TSockAddrIn = packed record
    case Integer of
      0: (sin_family: u_short;
          sin_port: u_short;
          sin_addr: TInAddr;
          sin_zero: array[0..7] of Char;
          {$ifndef WINSOCK}sin_pad : array[0..1] of Char;{$endif}
         );
      1: (sa_family: u_short;
          sa_data: array[0..13] of Char;
          {$ifndef WINSOCK}sa_pad : array[0..1] of Char;{$endif}
         )
  end;

  PInAddr6 = ^TInAddr6;
  TInAddr6 = packed record
    s6_addr  : array[0..15] of char;
  end;

  PSockAddrIn6 = ^TSockAddrIn6;
  TSockAddrIn6 = packed record
    sin6_family   : u_short;
    sin6_port     : u_short;
    sin6_flowinfo : u_long;
    sin6_addr     : TInAddr6;
  end;

  PSockAddr = ^TSockAddr;
  TSockAddr = {$ifdef WINSOCK}TSockAddrIn{$else}packed record
    sa_family : u_short;
    sa_data   : array[0..13] of Char;
    sa_pad    : array[0..1] of char;
  end{$endif};

{$ifndef NOWINSOCK2DEFS}
{
 * Structure used by kernel to pass protocol
 * information in raw sockets.
}
  TSockProto = packed record
    sp_family    : u_short; { address family }
    sp_protocol  : u_short; { protocol }
  end;
{$endif}

  TIPXNetNum = longint;
  TIPXNodeNum = packed record
    node_hil: longint;
    node_low: word;
  end;
  PIPXNodeNum = ^TIPXNodeNum;

  PIPXAddr = ^TIPXAddr;
  TIPXAddr = packed record
    ipx_netnum  : TIPXNetNum;
    ipx_nodenum : Sockets.TIPXNodeNum;
  end;

  PSockAddrIPX = ^TSockAddrIPX;
  TSockAddrIPX = packed record
    sipx_family : u_short;
    sipx_addr   : TIPXAddr;
    sipx_socket : u_short;
    sipx_data   : array[0..1] of byte;
  {$ifndef WINSOCK}
    sipx_pad    : array[0..1] of char;
  {$endif}
  end;

  PSockAddrNetbios = ^TSockAddrNetbios;
  TSockAddrNetbios = packed record
    snb_family  : u_short;
    snb_type    : u_short;
    snb_name    : array[0..15] of char;
  end;
  {
    note, that with WINSOCK defined you won't be able to typecast this addr
    to TSockAddr
  }

  PSockAddrUnix = ^TSockAddrUnix;
  TSockAddrUnix = packed record
    sun_family  : u_short;
    sun_path    : array[0..{$ifdef WINSOCK}13{$else}15{$endif}] of char;
  end;
  {
    though this can be typecasted with WINSOCK defined, but will probably
    result in malfunction (because of the shorter name space available)
  }

  TSocket = u_int;

  PFDSet = ^TFDSet;
  TFDSet = packed record
    fd_count: u_int;
    fd_array: array[0..FD_SETSIZE-1] of TSocket;
  end;

  PTimeVal = ^TTimeVal;
  TTimeVal = packed record
    tv_sec: Longint;
    tv_usec: Longint;
  end;

  PProtoEnt = ^TProtoEnt;
  TProtoEnt = packed record
    p_name: PChar;
    p_aliases: ^Pchar;
    p_proto: Smallint;
  end;

  PHostEnt = ^THostEnt;
  THostEnt = packed record
    h_name: PChar;
    h_aliases: ^PChar;
    h_addrtype: Smallint;
    h_length: Smallint;
    case Byte of
      0: (h_addr_list: ^PChar);
      1: (h_addr: ^PChar)
  end;

  PServEnt = ^TServEnt;
  TServEnt = packed record
    s_name: PChar;
    s_aliases: ^PChar;
    s_port: Smallint;
    s_proto: PChar;
  end;

  PWSAData = ^TWSAData;
  TWSAData = packed record
    wVersion: Word;
    wHighVersion: Word;
    szDescription: array[0..WSADESCRIPTION_LEN] of Char;
    szSystemStatus: array[0..WSASYS_STATUS_LEN] of Char;
    iMaxSockets: Word;
    iMaxUdpDg: Word;
    lpVendorInfo: PChar;
  end;

  PTransmitFileBuffers = ^TTransmitFileBuffers;
  TTransmitFileBuffers = packed record
    Head: pointer;
    HeadLength: DWORD;
    Tail: pointer;
    TailLength: DWORD;
  end;

{$ifndef NOWINSOCK2DEFS}
type
{ SockAddr Information }
  TSocketAddress = packed record
    lpSockaddr : PSockAddr;
    iSockaddrLength: u_int;
  end;

{ CSAddr Information }
  PCSAddrInfo = ^TCSAddrInfo;
  TCSAddrInfo = packed record
    LocalAddr: TSocketAddress;
    RemoteAddr: TSocketAddress;
    iSocketType: u_int;
    iProtocol: u_int;
  end;

{ Address Family/Protocol Tuples }
  PAFProtocols = ^TAFProtocols;
  TAFProtocols = packed record
    iAddressFamily: u_int;
    iProtocol: u_int;
  end;

{ Client Query API Typedefs }

{ The comparators }
  TWSAEComparator = (COMP_EQUAL,COMP_NOTLESS);

  PWSAVersion = ^TWSAVersion;
  TWSAVersion = packed record
    dwVersion: dword;
    ecHow: TWSAECOMPARATOR;
  end;

  PWSAQuerySetA = ^TWSAQuerySetA;
  TWSAQuerySetA = packed record
    dwSize: DWORD;
    lpszServiceInstanceName: PChar;
    lpServiceClassId: PGUID;
    lpVersion: PWSAVersion;
    lpszComment: PChar;
    dwNameSpace: dword;
    lpNSProviderId: PGUID;
    lpszContext: PChar;
    dwNumberOfProtocols: dword;
    lpafpProtocols: PAFPROTOCOLS;
    lpszQueryString: PChar;
    dwNumberOfCsAddrs: dword;
    lpcsaBuffer: PCSAddrInfo;
    dwOutputFlags: dword;
    lpBlob: PBlob;
   end;

  PWSAQuerySetW = ^TWSAQuerySetW;
  TWSAQuerySetW = packed record
    dwSize: DWORD;
    lpszServiceInstanceName: PWideChar;
    lpServiceClassId: PGUID;
    lpVersion: PWSAVersion;
    lpszComment: PWideChar;
    dwNameSpace: dword;
    lpNSProviderId: PGUID;
    lpszContext: PWideChar;
    dwNumberOfProtocols: dword;
    lpafpProtocols: PAFPROTOCOLS;
    lpszQueryString: PWideChar;
    dwNumberOfCsAddrs: dword;
    lpcsaBuffer: PCSAddrInfo;
    dwOutputFlags: dword;
    lpBlob: PBlob;
   end;

{$ifdef UNICODE}
   TWSAQuerySet = TWSAQuerySetW;
   PWSAQuerySet = PWSAQuerySetW;
{$else}
   TWSAQuerySet = TWSAQuerySetA;
   PWSAQuerySet = PWSAQuerySetA;
{$endif}

const
  LUP_DEEP                = $0001;
  LUP_CONTAINERS          = $0002;
  LUP_NOCONTAINERS        = $0004;
  LUP_NEAREST             = $0008;
  LUP_RETURN_NAME         = $0010;
  LUP_RETURN_TYPE         = $0020;
  LUP_RETURN_VERSION      = $0040;
  LUP_RETURN_COMMENT      = $0080;
  LUP_RETURN_ADDR         = $0100;
  LUP_RETURN_BLOB         = $0200;
  LUP_RETURN_ALIASES      = $0400;
  LUP_RETURN_QUERY_STRING = $0800;
  LUP_RETURN_ALL          = $0FF0;
  LUP_RES_SERVICE         = $8000;

  LUP_FLUSHCACHE       = $1000;
  LUP_FLUSHPREVIOUS    = $2000;


{ Return flags }

  RESULT_IS_ALIAS      = $0001;

type

{ Service Address Registration and Deregistration Data Types. }

  TWSAESetServiceOp = (
    RNRSERVICE_REGISTER,
    RNRSERVICE_DEREGISTER,
    RNRSERVICE_DELETE
  );

{ Service Installation/Removal Data Types. }

  PWSANSClassInfoA = ^TWSANSClassInfoA;
  TWSANSClassInfoA = packed record
    lpszName: PChar;
    dwNameSpace: dword;
    dwValueType: dword;
    dwValueSize: dword;
    lpValue: pointer;
  end;

  PWSANSClassInfoW = ^TWSANSClassInfoW;
  TWSANSClassInfoW = packed record
    lpszName: PWideChar;
    dwNameSpace: dword;
    dwValueType: dword;
    dwValueSize: dword;
    lpValue: pointer;
  end;

{$ifdef UNICODE}
  TWSANSClassInfo = TWSANSClassInfoW;
  PWSANSClassInfo = PWSANSClassInfoW;
{$else}
  TWSANSClassInfo = TWSANSClassInfoA;
  PWSANSClassInfo = PWSANSClassInfoA;
{$endif}

  PWSAServiceClassInfoA = ^TWSAServiceClassInfoA;
  TWSAServiceClassInfoA = packed record
    lpServiceClassId: PGUID;
    lpszServiceClassName: PChar;
    dwCount: dword;
    lpClassInfos: PWSANSClassInfoA;
  end;

  PWSAServiceClassInfoW = ^TWSAServiceClassInfoW;
  TWSAServiceClassInfoW = packed record
    lpServiceClassId: PGUID;
    lpszServiceClassName: PWideChar;
    dwCount: dword;
    lpClassInfos: PWSANSClassInfoW;
  end;

{$ifdef UNICODE}
  TWSAServiceClassInfo = TWSAServiceClassInfoW;
  PWSAServiceClassInfo = PWSAServiceClassInfoW;
{$else}
  TWSAServiceClassInfo = TWSAServiceClassInfoA;
  PWSAServiceClassInfo = PWSAServiceClassInfoA;
{$endif}

  PWSANameSpaceInfoA = ^TWSANameSpaceInfoA;
  TWSANameSpaceInfoA = packed record
    NSProviderId: TGUID;
    dwNameSpace: dword;
    fActive: bool;
    dwVersion: dword;
    lpszIdentifier: PChar;
  end;

  PWSANameSpaceInfoW = ^TWSANameSpaceInfoW;
  TWSANameSpaceInfoW = packed record
    NSProviderId: TGUID;
    dwNameSpace: dword;
    fActive: bool;
    dwVersion: dword;
    lpszIdentifier: PWideChar;
  end;

{$ifdef UNICODE}
  TWSANameSpaceInfo = ^TWSANameSpaceInfoW;
  PWSANameSpaceInfo = PWSANameSpaceInfoW;
{$else}
  TWSANameSpaceInfo = ^TWSANameSpaceInfoA;
  PWSANameSpaceInfo = PWSANameSpaceInfoA;
{$endif}

{$endif WINSOCK2}

{ C-helper functions }
function IN_CLASSA(i: longint): longbool;
function IN_CLASSB(i: longint): longbool;
function IN_CLASSC(i: longint): longbool;
function IN_CLASSD(i: longint): longbool;
function IN_MULTICAST(i: longint): longbool;

const
  INVALID_SOCKET		= TSocket(NOT(0));
  SOCKET_ERROR			= -1;

  { Define constant based on rfc883, used by gethostbyxxxx() calls. }
  MAXGETHOSTSTRUCT              = 1024;

function accept(s: TSocket; addr: PSockAddr; addrlen: PLongint): TSocket; {$ifdef win32}stdcall;{$endif}
function bind(s: TSocket; var addr: TSockAddr; namelen: longint): longint; {$ifdef win32}stdcall;{$endif}
function closesocket(s: TSocket): longint; {$ifdef win32}stdcall;{$endif}
function connect(s: TSocket; var name: TSockAddr; namelen: longint): longint; {$ifdef win32}stdcall;{$endif}
function ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): longint; {$ifdef win32}stdcall;{$endif}
function getpeername(s: TSocket; var name: TSockAddr; var namelen: longint): longint; {$ifdef win32}stdcall;{$endif}
function getsockname(s: TSocket; var name: TSockAddr; var namelen: longint): longint; {$ifdef win32}stdcall;{$endif}
function getsockopt(s: TSocket; level, optname: longint; optval: PChar; var optlen: longint): longint;
         {$ifdef win32}stdcall;{$endif}
function htonl(hostlong: u_long): u_long; {$ifdef win32}stdcall;{$endif}
function htons(hostshort: u_short): u_short; {$ifdef win32}stdcall;{$endif}
function inet_addr(cp: PChar): u_long; {$ifdef win32}stdcall;{$endif}
function inet_ntoa(inaddr: TInAddr): PChar; {$ifdef win32}stdcall;{$endif}
function ipx_addr(Addr: PChar): PIPXAddr; {$ifdef win32}stdcall;{$endif}
function ipx_ntoa(const IPXAddr: TIPXAddr): PChar; {$ifdef win32}stdcall;{$endif}
function listen(s: TSocket; backlog: longint): longint; {$ifdef win32}stdcall;{$endif}
function ntohl(netlong: u_long): u_long; {$ifdef win32}stdcall;{$endif}
function ntohs(netshort: u_short): u_short; {$ifdef win32}stdcall;{$endif}
function recv(s: TSocket; var Buf; len, flags: longint): longint; {$ifdef win32}stdcall;{$endif}
function recvfrom(s: TSocket; var Buf; len, flags: longint; var from: TSockAddr; var fromlen: longint): longint;
         {$ifdef win32}stdcall;{$endif}
function select(nfds: longint; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal): Longint;{$ifdef win32}stdcall;{$endif}
function send(s: TSocket; var Buf; len, flags: longint): longint; {$ifdef win32}stdcall;{$endif}
function sendto(s: TSocket; var Buf; len, flags: longint; var addrto: TSockAddr; tolen: longint): longint;
         {$ifdef win32}stdcall;{$endif}
function setsockopt(s: TSocket; level, optname: longint; optval: PChar; optlen: longint): longint;
         {$ifdef win32}stdcall;{$endif}
function shutdown(s: TSocket; how: longint): longint; {$ifdef win32}stdcall;{$endif}
function socket(af, struct, protocol: longint): TSocket; {$ifdef win32}stdcall;{$endif}
function gethostbyaddr(addr: Pointer; len, struct: longint): PHostEnt; {$ifdef win32}stdcall;{$endif}
function gethostbyname(name: PChar): PHostEnt; {$ifdef win32}stdcall;{$endif}
function gethostname(name: PChar; len: longint): longint; {$ifdef win32}stdcall;{$endif}
function getservbyport(port: Integer; proto: PChar): PServEnt; {$ifdef win32}stdcall;{$endif}
function getservbyname(name, proto: PChar): PServEnt; {$ifdef win32}stdcall;{$endif}
function getprotobynumber(proto: longint): PProtoEnt; {$ifdef win32}stdcall;{$endif}
function getprotobyname(name: PChar): PProtoEnt; {$ifdef win32}stdcall;{$endif}

function  WSAStartup(wVersionRequired: word; var FSData: TWSAData): longint; {$ifdef win32}stdcall;{$endif}
function  WSACleanup: longint; {$ifdef win32}stdcall;{$endif}
function  WSAGetLastError: longint; {$ifdef win32}stdcall;{$endif}
procedure WSASetLastError(iError: longint); {$ifdef win32}stdcall;{$endif}
function  WSAIsBlocking: BOOL; {$ifdef win32}stdcall;{$endif}
function  WSAUnhookBlockingHook: longint; {$ifdef win32}stdcall;{$endif}
function  WSASetBlockingHook(lpBlockFunc: TFarProc): TFarProc; {$ifdef win32}stdcall;{$endif}
function  WSACancelBlockingCall: longint;
function  WSAAsyncGetServByName(HWindow: HWND; wMsg: u_int; name, proto,
            buf: PChar; buflen: longint): THandle; {$ifdef win32}stdcall;{$endif}
function  WSAAsyncGetServByPort( HWindow: HWND; wMsg, port: u_int; proto,
            buf: PChar; buflen: longint): THandle; {$ifdef win32}stdcall;{$endif}
function  WSAAsyncGetProtoByName(HWindow: HWND; wMsg: u_int; name,
            buf: PChar; buflen: longint): THandle; {$ifdef win32}stdcall;{$endif}
function  WSAAsyncGetProtoByNumber(HWindow: HWND; wMsg: u_int; number: longint;
            buf: PChar; buflen: longint): THandle; {$ifdef win32}stdcall;{$endif}
function  WSAAsyncGetHostByName(HWindow: HWND; wMsg: u_int; name,
            buf: PChar; buflen: longint): THandle; {$ifdef win32}stdcall;{$endif}
function  WSAAsyncGetHostByAddr(HWindow: HWND; wMsg: u_int; addr: PChar; len, struct: longint;
            buf: PChar; buflen: longint): THandle; {$ifdef win32}stdcall;{$endif}
function  WSACancelAsyncRequest(hAsyncTaskHandle: THandle): longint; {$ifdef win32}stdcall;{$endif}
function  WSAAsyncSelect(s: TSocket; HWindow: HWND; wMsg: u_int; lEvent: Longint): longint; {$ifdef win32}stdcall;{$endif}
function  WSARecvEx(s: TSocket; var buf; len: longint; var flags: longint): longint; {$ifdef win32}stdcall;{$endif}
function  __WSAFDIsSet(s: TSocket; var FDSet: TFDSet): Bool; {$ifdef win32}stdcall;{$endif}

function  TransmitFile(hSocket: TSocket; hFile: THandle; nNumberOfBytesToWrite: DWORD;
  nNumberOfBytesPerSend: DWORD; lpOverlapped: POverlapped;
  lpTransmitBuffers: PTransmitFileBuffers; dwReserved: DWORD): BOOL;
 {$ifdef win32}stdcall;{$endif}

function  AcceptEx(sListenSocket, sAcceptSocket: TSocket;
  lpOutputBuffer: Pointer; dwReceiveDataLength, dwLocalAddressLength,
  dwRemoteAddressLength: DWORD; var lpdwBytesReceived: DWORD;
  lpOverlapped: POverlapped): BOOL;
 {$ifdef win32}stdcall;{$endif}

procedure GetAcceptExSockaddrs(lpOutputBuffer: Pointer;
  dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: DWORD;
  var LocalSockaddr: TSockAddr; var LocalSockaddrLength: longint;
  var RemoteSockaddr: TSockAddr; var RemoteSockaddrLength: longint);
 {$ifdef win32}stdcall;{$endif}

function  WSAMakeAsyncReply(Buflen, Error: Word): Longint;
function  WSAMakeSelectReply(Event, Error: Word): Longint;
function  WSAGetAsyncBuflen(Param: Longint): Word;
function  WSAGetAsyncError(Param: Longint): Word;
function  WSAGetSelectEvent(Param: Longint): Word;
function  WSAGetSelectError(Param: Longint): Word;

procedure FD_CLR(Socket: TSocket; var FDSet: TFDSet);
function  FD_ISSET(Socket: TSocket; var FDSet: TFDSet): Boolean;
procedure FD_SET(Socket: TSocket; var FDSet: TFDSet);
procedure FD_ZERO(var FDSet: TFDSet);
procedure FD_COPY(var SrcSet: TFDSet; var DestSet: TFDSet);

{$ifdef WINSOCK2}
type
  TConditionProc = function(lpCallerId, lpCallerData: PWSABuf; lpSQOS, lpGQOS: PQOS;
    plCalleeId, lpCalleeData: PWSABuf; g: PGroup; dwCallbackData: dword): longint;

  TWSAOverlappedCompletionRoutine = procedure(dwError: dword; cbTransferred: dword;
    lpOverlapped: PWSAOverlapped; dwFlags: dword);

function WSAAccept(s: TSocket; addr: PSockAddr; addrlen: plongint;
           lpfnCondition: TConditionProc; dwCallbackData: dword): TSocket;
function WSACloseEvent(hEvent: TWSAEvent): bool;
function WSAConnect(s: TSocket; name: PSockAddr; namelen: longint;
           lpCallerData, lpCaleeData: PWSABuf; lpSQOS, lpGQOS: PQOS): longint;
function WSACreateEvent: TWSAEvent;
function WSADuplicateSocketA(s: TSocket; dwProcessId: dword; lpProtocolInfo: PWSAProtocolInfoA): longint;
function WSADuplicateSocketW(s: TSocket; dwProcessId: dword; lpProtocolInfo: PWSAProtocolInfoW): longint;
function WSADuplicateSocket(s: TSocket; dwProcessId: dword; lpProtocolInfo: PWSAProtocolInfo): longint;
function WSAEnumNetworkEvents(s: TSocket; hEventObject: TWSAEvent; lpNetworkEvents: PWSANetworkEvents): longint;
function WSAEnumProtocolsA(var lpiProtocols: longint; lpProtocolBuffer: PWSAProtocolInfoA;
           var lpdwBufferLength: dword): longint;
function WSAEnumProtocolsW(var lpiProtocols: longint; lpProtocolBuffer: PWSAProtocolInfoW;
           var lpdwBufferLength: dword): longint;
function WSAEnumProtocols(var lpiProtocols: longint; lpProtocolBuffer: PWSAProtocolInfo;
           var lpdwBufferLength: dword): longint;
function WSAEventSelect(s: TSocket; hEventObject: TWSAEvent; lNetworkEvents: u_long): longint;
function WSAGetOverlappedResult(s: TSocket; lpOverlapped: PWSAOverlapped;
           var lpcbTransfer: dword; fWait: BOOL; var lpdwFlags: dword): BOOL;
function WSAGetQOSByName(s: TSocket; lpQOSName: PWSABuf; lpQOS: PQOS): BOOL;
function WSAhtonl(s: TSocket; hostlong: u_long; var lpnetlong: u_long): longint;
function WSAhtons(s: TSocket; hostshort: u_short; var lpnetshort: u_short): longint;
function WSAIoctl(s: TSocket; dwIoControlCode: dword; lpvInBuffer: pointer; cbInBuffer: dword;
           lpvOutBuffer: pointer; cbOutBuffer: dword; var lpcbBytesReturned: dword;
           lpOverlapped: PWSAOverlapped; lpCompletionRoutine: TWSAOverlappedCompletionRoutine): longint;
function WSAJoinLeaf(s: TSocket; name: PSockAddr; namelen: longint; lpCallerData, lpCalleeData: PWSABuf;
           lpSQOS,lpGQOS: PQOS; dwFlags: dword): TSocket;
function WSAntohl(s: TSocket; netlong: u_long; var lphostlong: u_long): longint;
function WSAntohs(s: TSocket; netshort: u_short; var lphostshort: u_short): longint;
function WSARecv(s: TSocket; lpBuffers: PWSABuf; dwBufferCount: dword; var lpNumberOfBytesRecvd: dword;
           var lpFlags: dword; lpOverlapped: PWSAOverlapped; lpCompletionRoutine: TWSAOverlappedCompletionRoutine): longint;
function WSARecvDisconnect(s: TSocket; lpInboundDisconnectData: PWSABuf): longint;
function WSARecvFrom(s: TSocket; lpBuffers: PWSABuf; dwBufferCount: dword; var lpNumberOfBytesRecvd: dword;
           var lpFlags: dword; lpFrom: PSockAddr; lpFromLen: plongint; lpOverlapped: PWSAOverlapped;
           lpCompletionRoutine: TWSAOverlappedCompletionRoutine): longint;
function WSAResetEvent(hEvent: TWSAEvent): BOOL;
function WSASend(s: TSocket; lpBuffers: PWSABuf; dwBufferCount: dword; var lpNumberOfBytesSend: dword; dwFlags: dword;
           lpOverlapped: PWSAOverlapped; lpCompletionRoutine: TWSAOverlappedCompletionRoutine): longint;
function WSASendDisconnect(s: TSocket; lpOutboundDisconnectData: PWSABuf): longint;
function WSASendTo(s: TSocket; lpBuffer: PWSABuf; dwBufferCount: dword; var lpNumberOfBytesSent: dword; dwFlags: dword;
           lpTo: PSockAddr; iToLen: longint; lpOverlapped: PWSAOverlapped;
           lpCompletionRoutine: TWSAOverlappedCompletionRoutine): longint;
function WSASetEvent(hEvent: TWSAEvent): BOOL;
function WSASocketA(af, struct, protocol: longint; lpProtocolInfo: PWSAProtocolInfoA;
           g: TGroup; dwFlags: dword): TSocket;
function WSASocketW(af, struct, protocol: longint; lpProtocolInfo: PWSAProtocolInfoW;
           g: TGroup; dwFlags: dword): TSocket;
function WSASocket(af, struct, protocol: longint; lpProtocolInfo: PWSAProtocolInfo;
           g: TGroup; dwFlags: dword): TSocket;
function WSAWaitForMultipleEvents(cEvents: dword; lphEvents: PWSAEvent; fWaitAll: BOOL;
           dwTimeout: DWORD; fAlertable: BOOL): dword;
function WSAAddressToStringA(lpsaAddress: PSockAddr; dwAddressLength: dword;
           lpProtocolInfo: PWSAProtocolInfoA; lpszAddressString: PChar; var lpdwAddressStringLength: dword): longint;
function WSAAddressToStringW(lpsaAddress: PSockAddr; dwAddressLength: dword;
           lpProtocolInfo: PWSAProtocolInfoW; lpszAddressString: PWideChar; var lpdwAddressStringLength: dword): longint;
function WSAAddressToString(lpsaAddress: PSockAddr; dwAddressLength: dword;
           lpProtocolInfo: PWSAProtocolInfo; lpszAddressString: PAWChar; var lpdwAddressStringLength: dword): longint;
function WSAStringToAddressA(AddressString: PChar; AddressFamily: longint;
           lpProtocolInfo: PWSAProtocolInfoA; lpAddress: PSockAddr; var lpAddressLength: dword): longint;
function WSAStringToAddressW(AddressString: PWideChar; AddressFamily: longint;
           lpProtocolInfo: PWSAProtocolInfoW; lpAddress: PSockAddr; var lpAddressLength: dword): longint;
function WSAStringToAddress(AddressString: PAWChar; AddressFamily: longint;
           lpProtocolInfo: PWSAProtocolInfo; lpAddress: PSockAddr; var lpAddressLength: dword): longint;
function WSALookupServiceBeginA(lpqsRestrictions: PWSAQuerySetA;
           dwControlFlags: dword; var lphLookup: THandle): longint;
function WSALookupServiceBeginW(lpqsRestrictions: PWSAQuerySetW;
           dwControlFlags: dword; var lphLookup: THandle): longint;
function WSALookupServiceBegin(lpqsRestrictions: PWSAQuerySet;
         dwControlFlags: dword; var lphLookup: THandle): longint;
function WSALookupServiceNextA(hLookup: THandle; dwControlFlags: dword;
           var lpdwBufferLength: dword; lpqsResults: PWSAQuerySetA): longint;
function WSALookupServiceNextW(hLookup: THandle; dwControlFlags: dword;
           var lpdwBufferLength: dword; lpqsResults: PWSAQuerySetW): longint;
function WSALookupServiceNext(hLookup: THandle; dwControlFlags: dword;
           var lpdwBufferLength: dword; lpqsResults: PWSAQuerySet): longint;
function WSALookupServiceEnd(hLookup: THandle): longint;
function WSAInstallServiceClassA(lpServiceClassInfo: PWSAServiceClassInfoA): longint;
function WSAInstallServiceClassW(lpServiceClassInfo: PWSAServiceClassInfoW): longint;
function WSAInstallServiceClass(lpServiceClassInfo: PWSAServiceClassInfo): longint;
function WSARemoveServiceClass(lpServiceClassId: PGUID): longint;
function WSAGetServiceClassInfoA(lpProviderId, lpServiceClassId: PGUID;
           var lpdwBufSize: dword; lpServiceClassInfo: PWSAServiceClassInfoA): longint;
function WSAGetServiceClassInfoW(lpProviderId, lpServiceClassId: PGUID;
           var lpdwBufSize: dword; lpServiceClassInfo: PWSAServiceClassInfoW): longint;
function WSAGetServiceClassInfo(lpProviderId, lpServiceClassId: PGUID;
           var lpdwBufSize: dword; lpServiceClassInfo: PWSAServiceClassInfo): longint;
function WSAEnumNameSpaceProvidersA(var lpdwBufferLength: dword; lpnspBuffer: PWSANameSpaceInfoA): longint;
function WSAEnumNameSpaceProvidersW(var lpdwBufferLength: dword; lpnspBuffer: PWSANameSpaceInfoW): longint;
function WSAEnumNameSpaceProviders(var lpdwBufferLength: dword; lpnspBuffer: PWSANameSpaceInfo): longint;
function WSAGetServiceClassNameByClassIdA(lpServiceClassId: PGUID;
         lpszServiceClassName: PChar; var lpdwBufferLength: dword): longint;
function WSAGetServiceClassNameByClassIdW(lpServiceClassId: PGUID;
         lpszServiceClassName: PWideChar; var lpdwBufferLength: dword): longint;
function WSAGetServiceClassNameByClassId(lpServiceClassId: PGUID;
         lpszServiceClassName: PAWChar; var lpdwBufferLength: dword): longint;
function WSASetServiceA(lpqsRegInfo: PWSAQuerySetA;
         essoperation: TWSAESetServiceOp; dwControlFlags: dword): longint;
function WSASetServiceW(lpqsRegInfo: PWSAQuerySetW;
         essoperation: TWSAESetServiceOp; dwControlFlags: dword): longint;
function WSASetService(lpqsRegInfo: PWSAQuerySet;
         essoperation: TWSAESetServiceOp; dwControlFlags: dword): longint;


{$endif}

implementation

{$ifdef DOS}
  {$I SOCKDOS.INC}
{$endif}
{$ifdef Win32}
  {$I SOCKWIN.INC}
{$endif}
{$ifdef Linux}
  {$I SOCKLIN.INC}
{$endif}

function IN_CLASSA(i: longint): longbool; begin IN_CLASSA:=(i and $80000000)=0; end;
function IN_CLASSB(i: longint): longbool; begin IN_CLASSB:=(i and $c0000000)=$80000000; end;
function IN_CLASSC(i: longint): longbool; begin IN_CLASSC:=(i and $e0000000)=$c0000000; end;
function IN_CLASSD(i: longint): longbool; begin IN_CLASSD:=(i and $f0000000)=$e0000000; end;
function IN_MULTICAST(i: longint): longbool; begin IN_MULTICAST:=IN_CLASSD(i); end;

function MakeLong(A,B: word): u_long;
type tlongint = packed record low, hiw: word; end;
var l: tlongint;
begin
  l.low:=A; l.hiw:=B;
  MakeLong:=u_long(l);
end;

function HiWord(L: u_long): word;
type tlongint = packed record low, hiw: word; end;
begin
  HiWord:=tlongint(L).hiw;
end;

function LoWord(L: u_long): word;
type tlongint = packed record low, hiw: word; end;
begin
  LoWord:=tlongint(L).low;
end;

function WSAMakeAsyncReply(Buflen, Error: Word): Longint;
begin
  WSAMakeAsyncReply:=MakeLong(BufLen,Error);
end;

function WSAMakeSelectReply(Event, Error: Word): Longint;
begin
  WSAMakeSelectReply:=MakeLong(Event,Error);
end;

function WSAGetAsyncBuflen(Param: Longint): Word;
begin
  WSAGetAsyncBuflen:=LoWord(Param);
end;

function WSAGetAsyncError(Param: Longint): Word;
begin
  WSAGetAsyncError:=HiWord(Param);
end;

function WSAGetSelectEvent(Param: Longint): Word;
begin
  WSAGetSelectEvent:=LoWord(Param);
end;

function WSAGetSelectError(Param: Longint): Word;
begin
  WSAGetSelectError:=HiWord(Param);
end;


{$ifdef WINSOCK2}

function WSADuplicateSocket(s: TSocket; dwProcessId: dword; lpProtocolInfo: PWSAProtocolInfo): longint;
begin
{$ifdef UNICODE}
  WSADuplicateSocket:=WSADuplicateSocketW(s,dwProcessId,lpProtocolInfo);
{$else}
  WSADuplicateSocket:=WSADuplicateSocketA(s,dwProcessId,lpProtocolInfo);
{$endif}
end;

function WSAEnumProtocols(var lpiProtocols: longint; lpProtocolBuffer: PWSAProtocolInfo;
         var lpdwBufferLength: dword): longint;
begin
{$ifdef UNICODE}
  WSAEnumProtocols:=WSAEnumProtocolsW(lpiProtocols,lpProtocolBuffer,lpdwBufferLength);
{$else}
  WSAEnumProtocols:=WSAEnumProtocolsA(lpiProtocols,lpProtocolBuffer,lpdwBufferLength);
{$endif}
end;

function WSASocket(af, struct, protocol: longint; lpProtocolInfo: PWSAProtocolInfo;
         g: TGroup; dwFlags: dword): TSocket;
begin
{$ifdef UNICODE}
  WSASocket:=WSASocketW(af,struct,protocol,lpProtocolInfo,g,dwFlags);
{$else}
  WSASocket:=WSASocketA(af,struct,protocol,lpProtocolInfo,g,dwFlags);
{$endif}
end;

function WSAAddressToString(lpsaAddress: PSockAddr; dwAddressLength: dword;
         lpProtocolInfo: PWSAProtocolInfo; lpszAddressString: PAWChar; var lpdwAddressStringLength: dword): longint;
begin
{$ifdef UNICODE}
  WSAAddressToString:=WSAAddressToStringW(lpsaAddress,dwAddressLength,
         lpProtocolInfo,lpszAddressString,lpdwAddressStringLength);
{$else}
  WSAAddressToString:=WSAAddressToStringA(lpsaAddress,dwAddressLength,
         lpProtocolInfo,lpszAddressString,lpdwAddressStringLength);
{$endif}
end;

function WSAStringToAddress(AddressString: PAWChar; AddressFamily: longint;
         lpProtocolInfo: PWSAProtocolInfo; lpAddress: PSockAddr; var lpAddressLength: dword): longint;
begin
{$ifdef UNICODE}
  WSAStringToAddress:=WSAStringToAddressW(AddressString,AddressFamily,
         lpProtocolInfo,lpAddress,lpAddressLength);
{$else}
  WSAStringToAddress:=WSAStringToAddressA(AddressString,AddressFamily,
         lpProtocolInfo,lpAddress,lpAddressLength);
{$endif}
end;

function WSALookupServiceBegin(lpqsRestrictions: PWSAQuerySet;
         dwControlFlags: dword; var lphLookup: Types.THandle): longint;
begin
{$ifdef UNICODE}
  WSALookupServiceBegin:=WSALookupServiceBeginW(lpqsRestrictions,
         dwControlFlags,lphLookup);
{$else}
  WSALookupServiceBegin:=WSALookupServiceBeginA(lpqsRestrictions,
         dwControlFlags,lphLookup);
{$endif}
end;

function WSALookupServiceNext(hLookup: Types.THandle; dwControlFlags: dword;
         var lpdwBufferLength: dword; lpqsResults: PWSAQuerySet): longint;
begin
{$ifdef UNICODE}
  WSALookupServiceNext:=WSALookupServiceNextW(hLookup,dwControlFlags,
         lpdwBufferLength,lpqsResults);
{$else}
  WSALookupServiceNext:=WSALookupServiceNextA(hLookup,dwControlFlags,
         lpdwBufferLength,lpqsResults);
{$endif}
end;

function WSAInstallServiceClass(lpServiceClassInfo: PWSAServiceClassInfo): longint;
begin
{$ifdef UNICODE}
  WSAInstallServiceClass:=WSAInstallServiceClassW(lpServiceClassInfo);
{$else}
  WSAInstallServiceClass:=WSAInstallServiceClassA(lpServiceClassInfo);
{$endif}
end;

function WSAGetServiceClassInfo(lpProviderId, lpServiceClassId: PGUID;
         var lpdwBufSize: dword; lpServiceClassInfo: PWSAServiceClassInfo): longint;
begin
{$ifdef UNICODE}
  WSAGetServiceClassInfo:=WSAGetServiceClassInfoW(lpProviderId,lpServiceClassId,
         lpdwBufSize,lpServiceClassInfo);
{$else}
  WSAGetServiceClassInfo:=WSAGetServiceClassInfoA(lpProviderId,lpServiceClassId,
         lpdwBufSize,lpServiceClassInfo);
{$endif}
end;

function WSAEnumNameSpaceProviders(var lpdwBufferLength: dword; lpnspBuffer: PWSANameSpaceInfo): longint;
begin
{$ifdef UNICODE}
  WSAEnumNameSpaceProviders:=WSAEnumNameSpaceProvidersW(lpdwBufferLength,lpnspBuffer);
{$else}
  WSAEnumNameSpaceProviders:=WSAEnumNameSpaceProvidersA(lpdwBufferLength,lpnspBuffer);
{$endif}
end;

function WSAGetServiceClassNameByClassId(lpServiceClassId: PGUID;
         lpszServiceClassName: PAWChar; var lpdwBufferLength: dword): longint;
begin
{$ifdef UNICODE}
  WSAGetServiceClassNameByClassId:=WSAGetServiceClassNameByClassIdW(
         lpServiceClassId,lpszServiceClassName,lpdwBufferLength);
{$else}
  WSAGetServiceClassNameByClassId:=WSAGetServiceClassNameByClassIdA(
         lpServiceClassId,lpszServiceClassName,lpdwBufferLength);
{$endif}
end;

function WSASetService(lpqsRegInfo: PWSAQuerySet;
         essoperation: TWSAESetServiceOp; dwControlFlags: dword): longint;
begin
{$ifdef UNICODE}
  WSASetService:=WSASetServiceW(lpqsRegInfo, essoperation, dwControlFlags);
{$else}
  WSASetService:=WSASetServiceA(lpqsRegInfo, essoperation, dwControlFlags);
{$endif}
end;

{$endif}

END.
{
  $Log: sockets.pas,v $

  Revision 1.0  1999/07/07 09:46:55  gabor
     Original implementation

}
