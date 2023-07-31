{
    $Id: ipxspx.pas,v 1.0 1998/05/07 12:34:12 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1998-1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    Novell IPX/SPX API routines

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

{.$DEFINE NOSEQCHECK} { define this to do not check packet sequence number }

unit IPXSPX;

interface

uses Objects,PMode;

const
{$ifdef DEBUG}
     debug_event_IPX                  = ord('I')+ord('P')*256+ord('X')*65536+ord('T')*16777216;
     debug_event_IPX_Error            = debug_event_IPX + 1;

     debug_event_IPX_First            = debug_event_IPX_Error;
     debug_event_IPX_Last             = debug_event_IPX_Error;
{$endif}
      addr_IPX        = 1;

      MaxIPXDataSize  = 4096; { max data size sent in 1 packet }
      MaxIPXFragments = 10 {2+(MaxIPXDataSize-546) div 576}; { max number of packet fragments }

      MaxSPXDataSize  = 534;

      ipx_invalid_socket = 0;
      spx_invalid_connection = 0;

      { IPX function code constansts }
      ipx_fc_OpenSocket         = $00;
      ipx_fc_CloseSocket        = $01;
      ipx_fc_GetLocalTarget     = $02;
      ipx_fc_SendPacket         = $03;
      ipx_fc_ListenForPacket    = $04;
      ipx_fc_ScheduleEvent      = $05;
      ipx_fc_CancelEvent        = $06;
      ipx_fc_ScheduleSpecEvent  = $07;
      ipx_fc_GetIntervalMarker  = $08;
      ipx_fc_GetInternetworkAddr= $09;
      ipx_fc_RelinquishCtrl     = $0a;
      ipx_fc_Disconnect         = $0b;
      ipx_fc_GetMaxPacketSize   = $1a;

      ipx_fc_SetInternetworkAddr= $0c;
      ipx_fc_ODISetInternetworkAddr= $24;

      { SPX function code constants }
      spx_fc_InstallCheck       = $10;
      spx_fc_EstablishConnection= $11;
      spx_fc_ListenForConnection= $12;
      spx_fc_TerminateConnection= $13;
      spx_fc_AbortConnection    = $14;
      spx_fc_GetConnectionStatus= $15;
      spx_fc_SendPacket         = $16;
      spx_fc_ListenForPacket    = $17;

      { IPX socket type constansts }
      ipx_st_Normal             = $00; { Open until close or terminate          }
      ipx_st_TSR                = $FF; { Open until close                       }

      { IPX packet type constansts }
      ipx_pt_Unknown            = $00;
      ipx_pt_RoutingInfo        = $01;
      ipx_pt_Echo               = $02;
      ipx_pt_Error              = $03;
      ipx_pt_PacketExchange     = $04;
      ipx_pt_SPX                = $05;
      ipx_pt_NetwareCoreProtocol= $11;
      ipx_pt_Propagated         = $14;
      ipx_pt_Normal             = {ipx_pt_PacketExchange}ipx_pt_Unknown;

      { IPX ECB in-use-flag value constansts }
      ipx_ecb_iu_Available              = $00;
      ipx_ecb_iu_AESTemporary           = $E0;
      ipx_ecb_iu_v302s1                 = $F6;
      ipx_ecb_iu_v302s2                 = $F7;
      ipx_ecb_iu_IPXCriticalSection     = $F8;
      ipx_ecb_iu_SPXListening           = $F9;
      ipx_ecb_iu_Processing             = $FA;
      ipx_ecb_iu_Holding                = $FB;
      ipx_ecb_iu_AESWaiting             = $FC;
      ipx_ecb_iu_AESDelaying            = $FD;
      ipx_ecb_iu_AwaitingReception      = $FE;
      ipx_ecb_iu_SendingPacket          = $FF;

      { IPX ECB completion-flag value constansts }
      ipx_ecb_cc_Success                = $00;
      ipx_ecb_cc_NotAcknowledged        = $EC; { remote terminated connection wihout acknowledging packet }
      ipx_ecb_cc_AbnormalTermination    = $ED; { abnormal connection termination                          }
      ipx_ecb_cc_InvalidConnectionID    = $EE; { invalid connection ID                                    }
      ipx_ecb_cc_SPXConnTableFull       = $EF; { SPX connection table full                                }
      ipx_ecb_cc_CantCancel             = $F9; { event should not be cancelled                            }
      ipx_ecb_cc_CantConnect            = $FA; { cannot establish connection with specified destination   }
      ipx_ecb_cc_Cancelled              = $FC; { cancelled                                                }
      ipx_ecb_cc_MalformedPacket        = $FD; { malformed packet                                         }
      ipx_ecb_cc_CantDeliver            = $FE; { packet undeliverable                                     }
      ipx_ecb_cc_PhysicalError          = $FF; { physical error                                           }
      ipx_ecb_cc_NotProcessed           = $80; { * defined by this unit to mark yet unhandled packets }

      { IPX error code constansts }
      ipx_err_OK                    = $00;
      ipx_err_EventInUse            = $F9;
      ipx_err_EventCancelled        = $FC;
      ipx_err_NoPathToDestination   = $FA; { no way to route packet to dest addr }
      ipx_err_SocketTableFull       = $FE;
      ipx_err_SocketAlreadyOpen     = $FF;

      ipx_err_HardwareError         = -1;

      { SPX error code constants }
      spx_err_OK                    = $00;
      spx_err_NoSuchConnection      = $EE;
      spx_err_ConnectionTableFull   = $EF;
      spx_err_InvalidOpenBuffer     = $FD; { buffer size not 42 or frag. count not 1 }
      spx_err_SendingSocketNotOpen  = $FF; { sending socket is not open              }

      { SPX Connection Control bitfield masks }
      spx_cc_EndOfMessage           = $10;
      spx_cc_AckRequired            = $40; { acknowledgement required }
      spx_cc_SystemPacket           = $80;

      { SPX Status Connection State values }
      spx_st_cs_ListeningForConnection = $01;
      spx_st_cs_StartingConnection     = $02;
      spx_st_cs_Connected              = $03;
      spx_st_cs_Terminating            = $04;

      { SPX Status WatchDog flag }
      spx_st_wd_IsWatchDogActive       = $02;

      { IP address compare bitfield masks }
      ipSameNetwork                 = $01;
      ipSameNode                    = $02;
      ipSameSocket                  = $04;
      ipSame                        = ipSameNetwork+ipSameNode+ipSameSocket;

type
     TIPXSocket = word;
     TSPXConnID = word;

     TIPXNetwork = longint;

     PIPXNodeAddr = ^TIPXNodeAddr;
     TIPXNodeAddr = packed record
 { * } NodeHiL: longint;
 { * } NodeLoW: word;
     end;

     TIPXHostAddress = packed record
 { * } Network  : TIPXNetwork;
 { * } Node     : TIPXNodeAddr;
     end;

     PIPXAddress = ^TIPXAddress;
     TIPXAddress = packed record
       Host     : TIPXHostAddress;
 { * } Socket   : TIPXSocket;
     end;

     PIPXHeader = ^TIPXHeader;
     TIPXHeader = packed record
 { * } CheckSum       : word;
 { * } PacketSize     : word;
       TransportCtrl  : byte;
       PacketType     : byte;
 { * } Destination    : TIPXAddress;
 { * } Source         : TIPXAddress;
     end;

     PIPXPacket = ^TIPXPacket;
     TIPXPacket = packed record
       Header   : TIPXHeader;
       Data     : array[1..576-SizeOf(TIPXHeader)] of byte;
     end;

     TIPXFragDesc = packed record
       FragPtr         : PByteArray;
       FragSize        : word;
     end;

     PXPXECB = ^TXPXECB;
     TXPXECB = packed record
       Link            : longint;
       ESR             : pointer; { Event Service Routine - 00000000h if none          }
       InUse           : byte;    { ipx_ebc_iu_XXXX constants }
       Completion      : byte;    { ipx_ebc_cc_XXXX constants }
 { * } SocketNo        : TIPXSocket;
       IPXWorkspace    : array[1..4] of byte;
       DriverWorkspace : array[1..12] of byte;
       LocalNodeAddr   : TIPXNodeAddr;
       FragmentCount   : word;
       Fragments       : array[1..MaxIPXFragments] of TIPXFragDesc;
     end;

     PECB = ^TECB;
     TECB = object(TObject)
       ECB             : PXPXECB;
       constructor Init;
       destructor  Done; virtual;
     public
       function  FragPtr(Index: integer): pointer;
       function  FragSize(Index: integer): word;
       function  AddFrag(SrcDataPtr: pointer; DataSize: word): boolean;
       procedure ClearFrag(Index: integer);
       procedure FreeFrag(Index: integer);
     public
       function  DosSeg: word;
       function  DosOfs: word;
     private
       ECBM            : MemPtr;
       FragmentMemPtrs : array[1..MaxIPXFragments] of MemPtr;
     end;

     PSPXHeader = ^TSPXHeader;
     TSPXHeader = packed record
 { * } CheckSum         : word;
 { * } PacketSize       : word;
       TransportControl : byte;
       PacketType       : byte;
 { * } Destination      : TIPXAddress;
 { * } Source           : TIPXAddress;
       { --- IPX packet header ends here --- }
       ConnectionControl: byte;
       DataStreamType   : byte;
 { * } SrcConnection    : TSPXConnID;
 { * } DestConnection   : TSPXConnID;
 { * } SequenceNumber   : word;
 { * } AcknowledgeNumber: word;
 { * } AllocationNumber : word;
     end;

     TSPXStatusBuffer = packed record
       ConnectionState    : byte;
       WatchDogFlag       : byte;
 { * } SourceConnection   : TSPXConnID;
 { * } DestConnection     : TSPXConnID;
 { * } SequenceNo         : word; { no of next packet sent         }
 { * } AcknowledgeNo      : word; { expected no of next ack packet }
 { * } MaxRemoteSeqNo     : word; { max seq number remote SPX may send without ACK from local SPX }
 { * } RemoteAcknowledgeNo: word; { next seq number remote SPX expects to receive                 }
 { * } MaxSeqNo           : word; { max seq number local local SPX may send                       }
 { * } SocketNo           : word; { connection socket                                             }
       LocalTarget        : TIPXNodeAddr;
       DestNetwork        : TIPXNetwork;
       DestNode           : TIPXNodeAddr;
 { * } RetransmitCount    : word;
 { * } EstRoundTripDelay  : word;
 { * } RetransmittedPackets: word;
 { * } SuppressedPackets  : word;
       Reserved           : array[1..12] of byte;
     end;

     PECBArray = ^TECBArray;
     TECBArray = array[1..255] of TECB;

     TIPXInformation = packed record
       ServerTime         : longint;
       VConsoleVersion    : word;
       Reserved           : word;
       IPXPacketsSent     : longint;
       MalformedIPXPackets: word;
       IPXGetECBReqs      : longint;
       IPXGetECBReqFails  : longint;
       IPXAESEvents       : longint;
       IPXAESPostPone     : word;
       MaxSockets         : word;
       MaxOpenSockets     : word;
       OpenSocketFails    : word;
       IPXListenECBCount  : longint; { word? }
       IPXCancelECBFails  : word;
       IPXGetLocalTargetCount: word;
       MaxConnections     : word; { SPX }
       MaxOpenConnections : word;
       SPXEstablishReqs   : word;
       SPXEstablishFails  : word;
       SPXListenConnects  : word;
       SPXListenConnectFails: word;
       SPXSendCount       : longint;
       SPXWindowChockes   : longint;
       BadSPXSends        : word;
       FailedSPXSends     : word;
       AbortedSPXSends    : word;
       SPXListenCount     : longint;
       BadSPXListens      : word;
       SPXIncomingCount   : longint;
       BadIncomingSPXCount: word;
       SupressedSPXCount  : word;
       SPXNoSesListenECBCount: word;
       SPXWatchDogDestSesCount: word;
     end;

     PIPXECB = ^TIPXECB;
     TIPXECB = object(TECB)
       constructor Init(ADataBufSize: word);
       function    IPXHeader: PIPXHeader;
       function    Data: pointer;
       function    DataBufSize: word;
       function    DataSize: word;
     end;

     PSPXECB = ^TSPXECB;
     TSPXECB = object(TECB)
       constructor Init(ADataBufSize: word);
       function    SPXHeader: PSPXHeader;
       function    Data: pointer;
       function    DataBufSize: word;
       function    DataSize: word;
     end;

     PECBCollection = ^TECBCollection;
     TECBCollection = object(TCollection)
       function At(Index: Integer): PECB;
     end;

     PIPXECBCollection = ^TIPXECBCollection;
     TIPXECBCollection = object(TECBCollection)
       function At(Index: Integer): PIPXECB;
     end;

     PSPXECBCollection = ^TSPXECBCollection;
     TSPXECBCollection = object(TECBCollection)
       function At(Index: Integer): PSPXECB;
     end;

     PIPXSocketObj = ^TIPXSocketObj;
     TIPXSocketObj = object(TObject)
       constructor Init(ASocket: word; AKeepOpen: boolean);
       destructor  Done; virtual;
     public
       Socket: TIPXSocket;
       {$ifdef DEBUG}
       TotalBytesSent: longint;
       {$endif}
     end;

     PSPXSocket = ^TSPXSocket;
     TSPXSocket = object(TIPXSocketObj)
       constructor Init(ASocket: TIPXSocket; AKeepOpen: boolean; AConnID: TSPXConnID; AMaxSendBufs: word);
       function    IsConnected: boolean;
       function    Abort: boolean;
       function    IsDataAvail: boolean;
       function    GetDataSize: word;
       function    GetData(var Buf; var BufSize: word): boolean;
       function    CanSend: boolean;
       function    SendData(var Buf; BufSize: word): boolean;
       function    GetStatus(var Status: TSPXStatusBuffer): boolean;
       function    Disconnect: boolean;
       destructor  Done; virtual;
     public { private }
       LastSPXError: integer;
       LastECBCC   : byte;
       RemoteSocket: TIPXSocket;
     { private } public
       SendECBs : PSPXECBCollection;
       LastSeq  : longint;
       MaxSendBufs: word;
       ConnID   : TSPXConnID;
       ConnAddr : TIPXAddress;
       function  SetupRecvECB(E: PSPXECB): boolean; virtual;
       function  SetupSendECB(E: PSPXECB): boolean;
       function  WaitForECB(E: PSPXECB; CareAboutState: boolean): byte;
       function  SearchCompletedECB(C: PSPXECBCollection): PSPXECB;
       function  SearchCompletedRecvECB: PSPXECB; virtual;
       function  CheckSendECBs: integer;
     end;

     PSPXClientSocket = ^TSPXClientSocket;
     TSPXClientSocket = object(TSPXSocket)
       constructor Init(ASocket: TIPXSocket; AKeepOpen: boolean; const DestAddr: TIPXAddress; AMaxDataSize, ARecvBufCount,
                   AMaxSendBufs: word; AUseWatchDog: boolean; ARetryCount: byte);
       destructor  Done; virtual;
     { private } public
       UseWatchDog: boolean;
       RetryCount: byte;
       RecvECBs : PSPXECBCollection;
       function  Connect(DestAddr: TIPXAddress): boolean;
       function  SearchCompletedRecvECB: PSPXECB; virtual;
     end;

     PSPXServerClientSocket = ^TSPXServerClientSocket;

     PSPXServerSocket = ^TSPXServerSocket;
     TSPXServerSocket = object(TIPXSocketObj)
       constructor Init(ASocket: TIPXSocket; AKeepOpen: boolean; ABackLog: word);
       function    IncomingConnectionAvail: boolean;
       function    AcceptConnection(AMaxSendBufs: word; AKeepOpen: boolean): PSPXServerClientSocket;
       destructor  Done; virtual;
     { private } public
       BackLog   : word;
       ListenAddr: TIPXAddress;
       ListenECBs: PSPXECBCollection;
       RecvECBs  : PSPXECBCollection;
       ChildSockets: PCollection;
       procedure   AddClient(E: PSPXServerClientSocket);
       procedure   RemoveClient(E: PSPXServerClientSocket);
       function    SetupListenECB(E: PSPXECB): boolean;
       function    SearchCompletedECB: PSPXECB;
       function    SearchCompletedRecvECB(Client: PSPXServerClientSocket): PSPXECB;
       function    GetWorkingRecvECBCount: integer;
       function    SetupRecvECB(E: PSPXECB): boolean;
       procedure   MaintainRecvECBs;
       function    RecvECBCount: integer;
     end;

     TSPXServerClientSocket = object(TSPXSocket)
       constructor Init(AOwner: PSPXServerSocket; ASocket: TIPXSocket; AKeepOpen: boolean; AConnID: TSPXConnID;
                   AMaxSendBufs: word);
       destructor  Done; virtual;
     private
       Owner: PSPXServerSocket;
       function  SetupRecvECB(E: PSPXECB): boolean; virtual;
       function  SearchCompletedRecvECB: PSPXECB; virtual;
       procedure SetParent(AParent: PSPXServerSocket);
     end;

{ Intel -> Motorola & Motorola -> Intel numeric conversion functions }
function  I2MW(IW: word): word; { conv word from Intel -> Motorola format }
function  M2IW(MW: word): word; { conv word from Motorola -> Intel format }
function  I2ML(IL: longint): longint; { conv longint from Intel -> Motorola format }
function  M2IL(ML: longint): longint; { conv longint from Motorola -> Intel format }
procedure I2MNode(INode: TIPXNodeAddr; var MNode: TIPXNodeAddr);
procedure M2INode(MNode: TIPXNodeAddr; var INode: TIPXNodeAddr);
procedure I2MIPXAddr(IIP: TIPXAddress; var MIP: TIPXAddress);
procedure M2IIPXAddr(MIP: TIPXAddress; var IIP: TIPXAddress);

{ IPX functions }
function  IPXInit: boolean;
function  IPXGetInformation(var II: TIPXInformation): boolean;
function  IPXOpenSocketX(SType: byte; var SocketNo: word): boolean;
function  IPXOpenSocket(var SocketNo: word): boolean;
function  IPXOpenTSRSocket(var SocketNo: word): boolean;
function  IPXCloseSocket(SocketNo: word): boolean;
function  IPXGetLocalTarget(Addr: TIPXAddress; var LT: TIPXNodeAddr): boolean;
function  IPXSendPacket(var ECB: TECB): boolean;
function  IPXListenForPacket(var ECB: TECB): boolean;
function  IPXScheduleEvent(DelayTime: word; var ECB: TECB): boolean;
function  IPXCancelEvent(var ECB: TECB): boolean;
function  IPXScheduleSpecEvent(DelayTime: word; var ECB: TECB): boolean;
function  IPXGetIntervalMarker: word;
function  IPXGetInterNetworkAddr(var Addr: TIPXHostAddress): boolean;
procedure IPXRelinquishControl;
function  IPXDisconnectFromTarget(const Addr: TIPXAddress): boolean;
function  IPXGetMaxPacketSize: word;

procedure IPXCreateBroadcastAddr(Network: longint; Socket: word; var Addr: TIPXAddress);
function  IPXCompareAddr(Addr1, Addr2: TIPXAddress): integer;
function  IPXCompareNodes(Node1,Node2: TIPXNodeAddr): boolean;
function  IPXIsNodeBroadcast(Node: TIPXNodeAddr): boolean;
function  IPXIsSameNode(Addr1, Addr2: TIPXAddress): boolean;


{ SPX function }
function  SPXInit: boolean;
function  SPXEstablishConnection(var ECB: TECB; var ConnID: TSPXConnID): boolean;
function  SPXEstablishConnectionS(var ECB: TECB; var ConnID: TSPXConnID; UseWatchDog: boolean; RetryCount: byte): boolean;
function  SPXSendPacket(ConnID: TSPXConnID; var ECB: TECB): boolean;
function  SPXListenForPacket(ConnID: TSPXConnID; var ECB: TECB): boolean;
function  SPXGetConnectionStatus(ConnID: TSPXConnID; var Status: TSPXStatusBuffer): boolean;
function  SPXAbortConnection(ConnID: TSPXConnID): boolean;
function  SPXTerminateConnection(ConnID: TSPXConnID; var ECB: TECB): boolean;
function  SPXListenForConnection(var ECB: TECB): boolean;

procedure IPXSetInternetworkAddr(Net: TIPXNetwork);
procedure IPXODISetInternetworkAddr(Addr: TIPXHostAddress);

const
      IPXError          : integer = 0;
      IPXVersion        : word    = $ffff; { initialized by IPXInstalled }

      SPXVersion        : word    = $0000; { initialized by SPXInstalled }
      SPXMaxConnections : word    = 0;     {      "       "        "     }
      SPXRetryCount     : byte    = 0;     { 0 - default }
      SPXWatchDogFlag   : boolean = false;

var
      SPXError          : integer absolute IPXError;

implementation

uses Dos{$ifdef DEBUG},WDebug{$endif};

const IPXEntryPoint : pointer = nil;

function Min(A,B: longint): longint;
begin
  if A<B then Min:=A else Min:=B;
end;

function SwapW(W: word): word;
begin
  SwapW:=system.Swap(W);
end;

function SwapL(L: longint): longint;
var HiW,LoW: word;
begin
  HiW:=L shr 16; LoW:=L and $ffff;
  HiW:=SwapW(HiW); LoW:=SwapW(LoW);
  SwapL:=longint(LoW) shl 16+HiW;
end;

function I2MW(IW: word): word;
begin
  I2MW:=SwapW(IW);
end;

function M2IW(MW: word): word;
begin
  M2IW:=SwapW(MW);
end;

function I2ML(IL: longint): longint;
begin
  I2ML:=SwapL(IL);
end;

function M2IL(ML: longint): longint;
begin
  M2IL:=SwapL(ML);
end;

procedure SwapNode(Node1: TIPXNodeAddr; var Node2: TIPXNodeAddr);
var I: integer;
begin
  for I:=0 to 5 do
  PByteArray(@Node2)^[I]:=PByteArray(@Node1)^[5-I];
end;

procedure I2MNode(INode: TIPXNodeAddr; var MNode: TIPXNodeAddr);
begin
  SwapNode(INode,MNode);
end;

procedure M2INode(MNode: TIPXNodeAddr; var INode: TIPXNodeAddr);
begin
  SwapNode(MNode,INode);
end;

procedure SwapIPXHostAddr(Host1: TIPXHostAddress; var Host2: TIPXHostAddress);
begin
  Host2.Network:=SwapL(Host1.Network); SwapNode(Host1.Node,Host2.Node);
end;

procedure SwapIPXAddr(IP1: TIPXAddress; var IP2: TIPXAddress);
begin
  SwapIPXHostAddr(IP1.Host,IP2.Host);
  IP2.Socket:=SwapW(IP1.Socket);
end;

procedure M2IIPXAddr(MIP: TIPXAddress; var IIP: TIPXAddress);
begin
  SwapIPXAddr(MIP,IIP);
end;

procedure I2MIPXAddr(IIP: TIPXAddress; var MIP: TIPXAddress);
begin
  SwapIPXAddr(IIP,MIP);
end;

function IntToStr(L: longint): string;
var S: string[20];
begin
  Str(L,S);
  IntToStr:=S;
end;

procedure InitRegisters(var r: registers);
begin
  FillChar(r,SizeOf(r),0);
  r.ds:=0; r.es:=r.ds;
end;

function CallIPX(var r: registers): boolean;
var OK: boolean;
begin
  OK:=(IPXEntryPoint<>nil);
  if OK=false then OK:=IPXInit;

  if OK then
    begin
      realintr($7a,r);
      IPXError:=integer(r.al);
    end
  else
    IPXError:=-1;
  OK:=(IPXError=0);
  CallIPX:=OK;
end;

function IPXInit: boolean;
var OK: boolean;
    r: registers;
begin
  InitRegisters(r);
  r.ax:=$7a00;
  realintr($2f,r);
  OK:=r.al=$ff;
  if OK then
  begin
    IPXError:=0;
    IPXEntryPoint:=ptr(r.es,r.di);
    MoveDosToPM(ptr(r.es,r.bx),@IPXVersion,2);
  end;
  IPXVersion:=IPXVersion shr 4;
  IPXInit:=OK;
end;

function  IPXGetInformation(var II: TIPXInformation): boolean;
var ReqBuf: packed record Len: word; SubCode: byte; end;
    ReqM,ReplyM: MemPtr;
    r: registers;
    OK: boolean;
begin
  ReqBuf.Len:=1; ReqBuf.SubCode:=$06;
  GetDosMem(ReqM,SizeOf(ReqBuf));
  GetDosMem(ReplyM,255);
  ReqM.MoveDataTo(ReqBuf,SizeOf(ReqBuf));
  r.ax:=$f27b; r.cx:=ReqM.Size; r.dx:=ReplyM.Size;
  r.ds:=ReqM.DosSeg; r.si:=ReqM.DosOfs;
  r.es:=ReplyM.DosSeg; r.di:=ReplyM.DosOfs;
  realintr($21,r);
  OK:=((r.flags and fCarry)=0) and (r.al=0);
  if OK then
    ReplyM.MoveDataFrom(SizeOf(II),II)
  else
    FillChar(II,SizeOf(II),0);
  FreeDosMem(ReplyM);
  FreeDosMem(ReqM);
  IPXGetInformation:=OK;
end;

function IPXOpenSocketX(SType: byte; var SocketNo: word): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_OpenSocket; r.al:=SType; r.dx:=I2MW(SocketNo);
  OK:=CallIPX(r);
  if OK then
    SocketNo:=M2IW(r.dx)
  else
    SocketNo:=0;
  IPXOpenSocketX:=OK;
end;

function IPXOpenSocket(var SocketNo: word): boolean;
begin
  IPXOpenSocket:=IPXOpenSocketX(ipx_st_Normal,SocketNo);
end;

function IPXOpenTSRSocket(var SocketNo: word): boolean;
begin
  IPXOpenTSRSocket:=IPXOpenSocketX(ipx_st_TSR,SocketNo);
end;

function IPXCloseSocket(SocketNo: word): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_CloseSocket; r.dx:=I2MW(SocketNo);
  OK:=CallIPX(r);
  IPXCloseSocket:=OK;
end;

function IPXGetLocalTarget(Addr: TIPXAddress; var LT: TIPXNodeAddr): boolean;
{ Addr and LT *MUST* be in the same segment }
type TContainer = record
       A : TIPXAddress;
       LocalTarget : TIPXNodeAddr;
     end;
var r: registers;
    Rec: TContainer;
    M: MemPtr;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_GetLocalTarget;
  Rec.A:=Addr;
  GetDosMem(M,SizeOf(Rec));
  M.MoveDataTo(Rec,Sizeof(Rec));

  r.es:=M.DosSeg; r.si:=M.DosOfs;
  r.di:=M.DosOfs+(Ofs(Rec.LocalTarget)-Ofs(Rec));
  r.cx:=0;
  OK:=CallIPX(r);

  if OK then
    begin
      M.MoveDataFrom(SizeOf(Rec),Rec);
      LT:=Rec.LocalTarget;
    end
  else
    FillChar(LT,SizeOf(LT),0);
  FreeDosMem(M);
  IPXGetLocalTarget:=OK;
end;

function IPXSendPacket(var ECB: TECB): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_SendPacket;
  r.es:=ECB.DosSeg; r.si:=ECB.DosOfs;
  OK:=CallIPX(r);
  IPXSendPacket:=OK;
end;

function IPXListenForPacket(var ECB: TECB): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_ListenForPacket;
  r.es:=ECB.DosSeg; r.si:=ECB.DosOfs;
  OK:=CallIPX(r);
  IPXListenForPacket:=OK;
end;

function IPXScheduleEvent(DelayTime: word; var ECB: TECB): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_ScheduleEvent;
  r.es:=ECB.DosSeg; r.si:=ECB.DosOfs; r.ax:=DelayTime;
  OK:=CallIPX(r);
  IPXScheduleEvent:=OK;
end;

function IPXCancelEvent(var ECB: TECB): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_CancelEvent;
  r.es:=ECB.DosSeg; r.si:=ECB.DosOfs;
  OK:=CallIPX(r);
  IPXCancelEvent:=OK;
end;

function IPXScheduleSpecEvent(DelayTime: word; var ECB: TECB): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_ScheduleSpecEvent;
  r.es:=ECB.DosSeg; r.si:=ECB.DosOfs; r.ax:=DelayTime;
  OK:=CallIPX(r);
  IPXScheduleSpecEvent:=OK;
end;

function IPXGetIntervalMarker: word;
var r: registers;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_GetIntervalMarker;
  CallIPX(r);
  IPXGetIntervalMarker:=r.ax;
end;

function IPXGetInternetworkAddr(var Addr: TIPXHostAddress): boolean;
var r: registers;
    M: MemPtr;
    OK: boolean;
    FAddr: TIPXAddress;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_GetInternetworkAddr;
  GetDosMem(M,SizeOf(FAddr));
  r.es:=M.DosSeg; r.si:=M.DosOfs;
  OK:=CallIPX(r);
  if OK then
    begin
      M.MoveDataFrom(SizeOf(FAddr),FAddr);
      M2IIPXAddr(FAddr,FAddr);
    end
  else
    FillChar(FAddr,SizeOf(FAddr),0);
  Addr:=FAddr.Host;
  FreeDosMem(M);
  IPXGetInternetworkAddr:=OK;
end;

procedure IPXRelinquishControl;
var r: registers;
    E: integer;
begin
  E:=IPXError;
  InitRegisters(r);
  r.bx:=ipx_fc_RelinquishCtrl;
  CallIPX(r);
  IPXError:=E;
end;

function IPXDisconnectFromTarget(const Addr: TIPXAddress): boolean;
var r: registers;
    M: MemPtr;
    OK: boolean;
begin
  GetDosMem(M,SizeOf(Addr));
  M.MoveDataTo(Addr,Sizeof(Addr));
  InitRegisters(r);
  r.bx:=ipx_fc_Disconnect;
  r.es:=M.DosSeg; r.si:=M.DosOfs;
  OK:=CallIPX(r);
  FreeDosMem(M);
  IPXDisconnectFromTarget:=OK;
end;

function IPXGetMaxPacketSize: word;
var r: registers;
    Size: word;
begin
  InitRegisters(r);
  r.bx:=ipx_fc_GetMaxPacketSize;
  CallIPX(r);
  Size:=r.ax;
  IPXGetMaxPacketSize:=Size;
end;

procedure IPXCreateBroadcastAddr(Network: longint; Socket: word; var Addr: TIPXAddress);
begin
  FillChar(Addr, SizeOf(Addr), 0);
  Addr.Host.Network:=Network; Addr.Socket:=Socket;
  with Addr.Host.Node do begin NodeHiL:=$ffffffff; NodeLoW:=$ffff; end;
end;

function IPXCompareAddr(Addr1, Addr2: TIPXAddress): integer;
var Res: integer;
begin
  Res:=0;
  if Addr1.Host.Network=Addr2.Host.Network then Res:=Res or ipSameNetwork;
  if IPXCompareNodes(Addr1.Host.Node,Addr2.Host.Node) then
     Res:=Res or ipSameNode;
  if Addr1.Socket=Addr2.Socket then Res:=Res or ipSameSocket;
  IPXCompareAddr:=Res;
end;

function IPXCompareNodes(Node1,Node2: TIPXNodeAddr): boolean;
begin
  IPXCompareNodes:=(Node1.NodeHiL=Node2.NodeHiL) and (Node1.NodeLoW=Node2.NodeLoW);
end;

function IPXIsSameNode(Addr1, Addr2: TIPXAddress): boolean;
begin
  IPXIsSameNode:=(IPXCompareAddr(Addr1,Addr2) and (ipSameNetwork+ipSameNode))=(ipSameNetwork+ipSameNode);
end;

function IPXIsNodeBroadcast(Node: TIPXNodeAddr): boolean;
var Is: boolean;
begin
  Is:=(Node.NodeHiL=$ffffffff) and (Node.NodeLoW=$ffff);
  IPXIsNodeBroadcast:=Is;
end;

function SPXInit: boolean;
var r: registers;
    OK: boolean;
begin
  OK:=IPXInit;
  if OK then
  begin
    InitRegisters(r);
    r.bx:=spx_fc_InstallCheck; r.al:=0; CallIPX(r);
    OK:=r.al=$ff;
    if OK then
      begin
        SPXError:=0;
        SPXVersion:=r.bx; SPXMaxConnections:=r.cx;
      end;
  end;
  SPXInit:=OK;
end;

function SPXWatchDogFlagB: byte;
var B: byte;
begin
  if SPXWatchDogFlag=true then B:=1 else B:=0;
  SPXWatchDogFlagB:=B;
end;

function SPXEstablishConnection(var ECB: TECB; var ConnID: TSPXConnID): boolean;
begin
  SPXEstablishConnection:=SPXEstablishConnectionS(ECB,ConnID,SPXWatchDogFlag,SPXRetryCount);
end;

function SPXEstablishConnectionS(var ECB: TECB; var ConnID: TSPXConnID; UseWatchDog: boolean; RetryCount: byte): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=spx_fc_EstablishConnection;
  r.es:=ECB.DosSeg; r.si:=ECB.DosOfs; r.al:=RetryCount;
  if UseWatchDog then r.ah:=1 else r.ah:=0;
  OK:=CallIPX(r);
  if OK then
    ConnID:={M2IW}(r.dx)
  else
    ConnID:=0;
  SPXEstablishConnectionS:=OK;
end;

function SPXListenForConnection(var ECB: TECB): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=spx_fc_ListenForConnection; 
  r.es:=ECB.DosSeg; r.si:=ECB.DosOfs; r.al:=SPXRetryCount;
  r.ah:=SPXWatchDogFlagB;
  OK:=CallIPX(r);
  SPXListenForConnection:=OK;
end;

function SPXTerminateConnection(ConnID: TSPXConnid; var ECB: TECB): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=spx_fc_TerminateConnection; r.dx:=ConnID;
  r.es:=ECB.DosSeg; r.si:=ECB.DosOfs;
  OK:=CallIPX(r);
  SPXTerminateConnection:=OK;
end;

function SPXAbortConnection(ConnID: TSPXConnid): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=spx_fc_AbortConnection; r.dx:=ConnID;
  OK:=CallIPX(r);
  SPXAbortConnection:=OK;
end;

function SPXGetConnectionStatus(ConnID: TSPXConnid; var Status: TSPXStatusBuffer): boolean;
var r: registers;
    M: MemPtr;
    OK: boolean;
begin
  OK:=GetDosMem(M,SizeOf(Status));
  if OK=false then IPXError:=-1 else
 begin
  InitRegisters(r);
  r.bx:=spx_fc_GetConnectionStatus; r.dx:=ConnID;
  r.es:=M.DosSeg; r.si:=M.DosOfs;
  OK:=CallIPX(r);
  if OK then
    begin
      M.MoveDataFrom(Sizeof(Status),Status);
      with Status do
      begin
        SourceConnection:=M2IW(SourceConnection);
        DestConnection:=M2IW(DestConnection);
        SequenceNo:=M2IW(SequenceNo);
        AcknowledgeNo:=M2IW(AcknowledgeNo);
        MaxRemoteSeqNo:=M2IW(MaxRemoteSeqNo);
        RemoteAcknowledgeNo:=M2IW(RemoteAcknowledgeNo);
        MaxSeqNo:=M2IW(MaxSeqNo);
        SocketNo:=M2IW(SocketNo);
        M2INode(LocalTarget,LocalTarget);
        DestNetwork:=M2IL(DestNetwork);
        M2INode(DestNode,DestNode);
        RetransmitCount:=M2IW(RetransmitCount);
        EstRoundTripDelay:=M2IW(EstRoundTripDelay);
        RetransmittedPackets:=M2IW(RetransmittedPackets);
        SuppressedPackets:=M2IW(SuppressedPackets);
      end;
    end
  else
    FillChar(Status,SizeOf(Status),0);
  FreeDosMem(M);
 end;
  SPXGetConnectionStatus:=OK;
end;

function SPXSendPacket(ConnID: TSPXConnid; var ECB: TECB): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=spx_fc_SendPacket;
  r.es:=ECB.DosSeg; r.si:=ECB.DosOfs;
  r.dx:=ConnID;
  OK:=CallIPX(r);
  SPXSendPacket:=OK;
end;

function SPXListenForPacket(ConnID: TSPXConnid; var ECB: TECB): boolean;
var r: registers;
    OK: boolean;
begin
  InitRegisters(r);
  r.bx:=spx_fc_ListenForPacket; r.cx:=1; {???}
  r.es:=ECB.DosSeg; r.si:=ECB.DosOfs;
  r.dx:=ConnID;
  OK:=CallIPX(r);
  SPXListenForPacket:=OK;
end;

procedure IPXSetInternetworkAddr(Net: TIPXNetwork);
var r: registers;
    P: pointer;
begin
  Net:=SwapL(Net);
  r.ah:=$34;
  MsDos(r);
  P:=MakePtr(r.es,r.bx);
  InitRegisters(r);
  r.bx:=ipx_fc_SetInternetworkAddr;
  r.es:=PtrRec(P).Seg; r.di:=PtrRec(P).Ofs;
  r.ds:=r.es; r.si:=r.di;
  r.dx:=(Net shr 16); r.cx:=(Net and $ffff);
  CallIPX(r);
  IPXError:=0;
end;

procedure IPXODISetInternetworkAddr(Addr: TIPXHostAddress);
var r: registers;
    M: MemPtr;
begin
  SwapIPXHostAddr(Addr,Addr);
  GetDosMem(M,SizeOf(Addr));
  M.MoveDataTo(Addr,Sizeof(Addr));
  InitRegisters(r);
  r.bx:=ipx_fc_ODISetInternetworkAddr;
  r.es:=M.DosSeg; r.si:=M.DosOfs;
  CallIPX(r);
  IPXError:=0;
  FreeDosMem(M);
end;

function CheckIPX: boolean;
{ Used to avoid unecessary IPX installation checks }
var OK: boolean;
begin
  OK:=IPXVersion<>$ffff;
  if OK=false then OK:=IPXInit;
  CheckIPX:=OK;
end;

constructor TECB.Init;
begin
  inherited Init;
  if GetDosMem(ECBM,SizeOf(ECB^))=false then
    Fail;
  ECB:=ECBM.DataPtr;
end;

destructor TECB.Done;
var I: integer;
begin
  if ECB^.InUse<>ipx_ecb_iu_Available then
    IPXCancelEvent(Self);
  for I:=1 to ECB^.FragmentCount do
    FreeFrag(I);
  FreeDosMem(ECBM);
  inherited Done;
end;

function TECB.FragPtr(Index: integer): pointer;
begin
  FragPtr:=FragmentMemPtrs[Index].DataPtr;
end;

function TECB.FragSize(Index: integer): word;
begin
  FragSize:=ECB^.Fragments[Index].FragSize;
end;

function TECB.AddFrag(SrcDataPtr: pointer; DataSize: word): boolean;
var M: ^MemPtr;
    OK: boolean;
begin
  OK:=DataSize>0;

  if OK then
  begin
    Inc(ECB^.FragmentCount);
    M:=@FragmentMemPtrs[ECB^.FragMentCount];
    OK:=GetDosMem(M^,DataSize);
    if OK then
      begin
        with ECB^.Fragments[ECB^.FragmentCount] do
          begin
            FragSize:=DataSize;
            FragPtr:=M^.DosPtr;
          end;
        if SrcDataPtr<>nil then
          Move(SrcDataPtr^,M^.DataPtr^,DataSize);
      end
    else
      Dec(ECB^.FragmentCount);
  end;
  AddFrag:=OK;
end;

procedure TECB.ClearFrag(Index: integer);
begin
  with FragmentMemPtrs[Index] do
    if DataPtr<>nil then
     FillChar(DataPtr^,Size,0);
end;

procedure TECB.FreeFrag(Index: integer);
begin
  if FragmentMemPtrs[Index].DataPtr<>nil then
    FreeDosMem(FragmentMemPtrs[Index]);
  with ECB^.Fragments[Index] do
  if (FragPtr<>nil) and (FragSize>0) then
   begin
     FragPtr:=nil; FragSize:=0;
   end;
end;

function TECB.DosSeg: word;
begin
  DosSeg:=ECBM.DosSeg;
end;

function TECB.DosOfs: word;
begin
  DosOfs:=ECBM.DosOfs;
end;

constructor TIPXECB.Init(ADataBufSize: word);
begin
  inherited Init;
  if AddFrag(nil,Sizeof(TIPXHeader))=false then
    Fail;
  if ADataBufSize>0 then
    if AddFrag(nil,ADataBufSize)=false then
      begin
        Done;
        Fail;
      end;
end;

function TIPXECB.IPXHeader: PIPXHeader;
begin
  IPXHeader:=FragPtr(1);
end;

function TIPXECB.Data: pointer;
begin
  Data:=FragPtr(2);
end;

function TIPXECB.DataBufSize: word;
begin
  DataBufSize:=FragSize(2);
end;

function TIPXECB.DataSize: word;
var Size: word;
begin
  Size:=M2IW(IPXHeader^.PacketSize);
  if Size>=SizeOf(IPXHeader^) then Size:=Size-Sizeof(IPXHeader^) else Size:=0;
  DataSize:=Size;
end;

constructor TSPXECB.Init(ADataBufSize: word);
var MS: word;
begin
  inherited Init;
  MS:=IPXGetMaxPacketSize;
  if MS<ADataBufSize then
    ADataBufSize:=MS;
  if AddFrag(nil,Sizeof(TSPXHeader))=false then
    Fail;
  if ADataBufSize>0 then
   if AddFrag(nil,ADataBufSize)=false then
     begin
       Done;
       Fail;
     end;
end;

function TSPXECB.SPXHeader: PSPXHeader;
begin
  SPXHeader:=FragPtr(1);
end;

function TSPXECB.Data: pointer;
begin
  Data:=FragPtr(2);
end;

function TSPXECB.DataBufSize: word;
begin
  DataBufSize:=FragSize(2);
end;

function TSPXECB.DataSize: word;
var Size: word;
begin
  Size:=M2IW(SPXHeader^.PacketSize);
  if Size>=SizeOf(SPXHeader^) then Size:=Size-Sizeof(SPXHeader^) else Size:=0;
  DataSize:=Size;
end;

function TECBCollection.At(Index: Integer): PECB;
begin
  At:=inherited At(Index);
end;

function TIPXECBCollection.At(Index: Integer): PIPXECB;
begin
  At:=TCollection.At(Index);
end;

function TSPXECBCollection.At(Index: Integer): PSPXECB;
begin
  At:=TCollection.At(Index);
end;

constructor TIPXSocketObj.Init(ASocket: word; AKeepOpen: boolean);
var OK: boolean;
begin
  inherited Init;
  Socket:=ASocket;
  if AKeepOpen then
    OK:=IPXOpenTSRSocket(Socket)
  else
    OK:=IPXOpenSocket(Socket);
  if OK=false then Fail;
end;

destructor TIPXSocketObj.Done;
begin
  IPXCloseSocket(Socket);
  inherited Done;
end;

constructor TSPXSocket.Init(ASocket: TIPXSocket; AKeepOpen: boolean; AConnID: TSPXConnID; AMaxSendBufs: word);
begin
  if inherited Init(ASocket,AKeepOpen)=false then
    Fail;
  ConnID:=AConnID;
  MaxSendBufs:=AMaxSendBufs;
  LastSeq:=-1;
  New(SendECBs, Init(10,10));
end;

function TSPXSocket.IsConnected: boolean;
var Is: boolean;
    ST: TSPXStatusBuffer;
begin
  Is:=ConnID<>0;
  if Is then Is:=GetStatus(ST);
  Is:=Is and (ST.ConnectionState=spx_st_cs_Connected);
  IsConnected:=Is;
end;

function TSPXSocket.Abort: boolean;
var OK: boolean;
begin
  OK:=SPXAbortConnection(ConnID);
  LastSPXError:=SPXError;
  Abort:=OK;
end;

function TSPXSocket.GetStatus(var Status: TSPXStatusBuffer): boolean;
var OK: boolean;
begin
  OK:=SPXGetConnectionStatus(ConnID,Status);
  LastSPXError:=SPXError;
  GetStatus:=OK;
end;

function TSPXSocket.IsDataAvail: boolean;
var E: PSPXECB;
begin
  E:=SearchCompletedRecvECB;
  IsDataAvail:=Assigned(E);
end;

function TSPXSocket.GetDataSize: word;
var E: PSPXECB;
    Size: word;
begin
  E:=SearchCompletedRecvECB;
  if Assigned(E) then
    Size:=E^.DataSize
  else
    Size:=0;
  GetDataSize:=Size;
end;

function TSPXSocket.GetData(var Buf; var BufSize: word): boolean;
var E: PSPXECB;
    OK: boolean;
begin
  E:=SearchCompletedRecvECB;
  OK:=Assigned(E);
  OK:=OK and (E^.DataSize<=BufSize);
  if OK then
  begin
    BufSize:=E^.DataSize;
    Move(E^.Data^,Buf,BufSize);
    LastSeq:=swap(E^.SPXHeader^.SequenceNumber);
    SetupRecvECB(E);
  end;
  GetData:=OK;
end;

function TSPXSocket.CanSend: boolean;
var Can: boolean;
begin
  Can:=(CheckSendECBs<MaxSendBufs);
  CanSend:=Can;
end;

function TSPXSocket.SendData(var Buf; BufSize: word): boolean;
var E: PSPXECB;
    OK: boolean;
begin
  OK:=BufSize>0;
  if OK then
  begin
    if (MaxSendBufs<>0) then
      while (CheckSendECBs>=MaxSendBufs) do
        begin
          IPXRelinquishControl;
        end;
    New(E, Init(BufSize));
    Move(Buf,E^.Data^,BufSize);
    {$ifdef DEBUG}Inc(TotalBytesSent,BufSize);{$endif}
    SendECBs^.Insert(E);
    OK:=SetupSendECB(E);
    CheckSendECBs;
  end;
  SendData:=OK;
end;

function TSPXSocket.Disconnect: boolean;
var E: PSPXECB;
    OK: boolean;
begin
  New(E, Init(0));
  with E^ do
  begin
    ECB^.SocketNo:=M2IW(Socket);
    SPXHeader^.Destination:=ConnAddr;
  end;
  OK:=SPXTerminateConnection(ConnID,E^);
  LastSPXError:=SPXError;
  if OK then OK:=WaitForECB(E,false)=ipx_ecb_cc_Success;
  if OK then
  begin
    ConnID:=0;
    FillChar(ConnAddr,Sizeof(ConnAddr),0);
  end;
  Dispose(E, Done);
  Disconnect:=OK;
end;

function TSPXSocket.CheckSendECBs: integer;
var Count: integer;
    E: PSPXECB;
begin
  IPXRelinquishControl;
  repeat
    E:=SearchCompletedECB(SendECBs);
    if Assigned(E) then SendECBs^.Free(E);
  until E=nil;
  Count:=SendECBs^.Count;
  CheckSendECBs:=Count;
end;

function TSPXSocket.SearchCompletedECB(C: PSPXECBCollection): PSPXECB;
var E: PSPXECB;
    MinSeq: word;
procedure SearchMin(P: PSPXECB); {$ifndef FPC}far;{$endif}
begin
  with P^, ECB^, SPXHeader^ do
  begin
    if InUse=ipx_ecb_iu_Available then
      if (Completion=ipx_ecb_cc_Success) then
        if swap(SequenceNumber)<=MinSeq then
          begin
            MinSeq:=swap(SequenceNumber);
            E:=P;
          end;
  end;
end;
begin
  MinSeq:=High(MinSeq); E:=nil;
  C^.ForEach(@SearchMin);
  SearchCompletedECB:=E;
end;

function TSPXSocket.SearchCompletedRecvECB: PSPXECB;
begin
  Abstract;
  SearchCompletedRecvECB:=nil;
end;

function TSPXSocket.SetupRecvECB(E: PSPXECB): boolean;
var OK: boolean;
begin
  with E^.ECB^ do
  begin
    SocketNo:=M2IW(Socket);
  end;
  OK:=SPXListenForPacket(ConnID,E^);
  {$ifdef DEBUG}
  if OK=false then DebugStr(debug_event_IPX_Error,'SPXListenForPacket failed');
  {$endif}
  SetupRecvECB:=OK;
end;

function TSPXSocket.SetupSendECB(E: PSPXECB): boolean;
var OK: boolean;
begin
  with E^,ECB^ do
  begin
{    SocketNo:=M2IW(Socket);
    SPXHeader^.Destination:=ConnAddr;}
  end;
  OK:=SPXSendPacket(ConnID,E^);
  {$ifdef DEBUG}
  if OK=false then DebugStr(debug_event_IPX_Error,'SPXSendPacket failed');
  {$endif}
  SetupSendECB:=OK;
end;

function TSPXSocket.WaitForECB(E: PSPXECB; CareAboutState: boolean): byte;
begin
  while (E^.ECB^.InUse<>ipx_ecb_iu_Available) and
        ((CareAboutState=false) or IsConnected) do
    IPXRelinquishControl;
  { wait until async operation completes }
  if E^.ECB^.InUse<>ipx_ecb_iu_Available then
  begin
    IPXCancelEvent(E^);
    while E^.ECB^.InUse<>ipx_ecb_iu_Available do;
  end;
  LastECBCC:=E^.ECB^.Completion;
  WaitForECB:=LastECBCC;
end;

destructor TSPXSocket.Done;
begin
  if IsConnected then Disconnect;
  if Assigned(SendECBs) then Dispose(SendECBs, Done);
  inherited Done;
end;

constructor TSPXClientSocket.Init(ASocket: TIPXSocket; AKeepOpen: boolean; const DestAddr: TIPXAddress;
            AMaxDataSize,ARecvBufCount,AMaxSendBufs: word; AUseWatchDog: boolean; ARetryCount: byte);
var E: PSPXECB;
    I: integer;
begin
  if inherited Init(ASocket,AKeepOpen,0,AMaxSendBufs)=false then
    Fail;
  UseWatchDog:=AUseWatchDog; RetryCount:=ARetryCount;
  New(RecvECBs, Init(10,10));
  for I:=1 to ARecvBufCount do
  begin
    New(E, Init(AMaxDataSize));
    RecvECBs^.Insert(E);
    SetupRecvECB(E);
  end;
  if Connect(DestAddr)=false then
    begin
      Done;
      Fail;
    end;
end;

function TSPXClientSocket.Connect(DestAddr: TIPXAddress): boolean;
var E: PSPXECB;
    OK: boolean;
    ID: TSPXConnID;
begin
  I2MIPXAddr(DestAddr,DestAddr);
  New(E, Init(0));
  with E^ do
  begin
    ECB^.SocketNo:=M2IW(Socket);
    SPXHeader^.Destination:=DestAddr;
  end;
  OK:=SPXEstablishConnectionS(E^,ID,UseWatchDog,RetryCount);
  LastSPXError:=SPXError;
  if OK then OK:=WaitForECB(E,false)=ipx_ecb_cc_Success;
  if OK then
  begin
    ConnAddr:=DestAddr;
    ConnID:=ID;
    RemoteSocket:=M2IW(E^.SPXHeader^.Source.Socket);
  end;
  Dispose(E, Done);
  Connect:=OK;
end;

function GetDosTicks: longint;
var TT: longint absolute $40:$6c;
begin
  GetDosTicks:=TT;
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

function GetElapsedTicks(StartTime: longint): longint;
begin
  GetElapsedTicks:=GetTickDiff(StartTime,GetDosTicks);
end;

function TSPXClientSocket.SearchCompletedRecvECB: PSPXECB;
var E: PSPXECB;
    MinSeq: word;
procedure SearchMin(P: PSPXECB); {$ifndef FPC}far;{$endif}
var H: PSPXHeader;
    EC: PXPXECB;
begin
  with P^, ECB^, SPXHeader^ do
  begin
    EC:=ECB; H:=SPXHeader;
    if InUse=ipx_ecb_iu_Available then
      if (Completion=ipx_ecb_cc_Success) then
        begin
          if (swap(P^.SPXHeader^.PacketSize)<=SizeOf(P^.SPXHeader^)) or (P^.ECB^.FragmentCount=0) then
            begin
              {$ifdef DEBUG}
              DebugStr(debug_event_IPX_Error,'packet size too small. ('+IntToStr(Swap(P^.SPXHeader^.PacketSize))+')');
              {$endif}
              SetupRecvECB(P);
            end
          else
          begin
(*            {$ifdef DEBUGIPX}write('Seq:',swap(SequenceNumber));{$endif}*)
            if swap(SequenceNumber)<MinSeq then
               MinSeq:=swap(SequenceNumber);
            if {$ifndef NOSEQCHECK}swap(SequenceNumber)=((LastSeq+1) and $ffff){$else}E=nil{$endif} then
              begin
  {              MinSeq:=swap(SequenceNumber);}
                E:=P;
              end
            else
              begin
                { order mismatch }
                E:=E;
              end;
          end;
        end
      else
        begin
          {$ifdef DEBUG}
          DebugStr(debug_event_IPX_Error,
            'error receiving packet. (Seq:'+IntToStr(swap(SequenceNumber))+' Err:'+IntToStr(Completion)+')');
          {$endif}
          SetupRecvECB(P); { automatically reuse if error detected }
        end;
  end;
end;
{$ifdef DEBUG}const LastTT: longint = 0;{$endif}
begin
  MinSeq:=High(MinSeq); E:=nil;
  RecvECBs^.ForEach(@SearchMin);
(*  {$ifdef DEBUG}
  if abs(GetDosTicks-LastTT)>18 then
  begin
    DebugStr(0,'Last IPX fragment ofs is '+IntToStr(MinSeq)+' socket: '+IntToStr(Socket));
    LastTT:=GetDosTicks;
  end;
  {$endif}*)
  SearchCompletedRecvECB:=E;
end;

destructor TSPXClientSocket.Done;
begin
  if Assigned(RecvECBs) then Dispose(RecvECBs, Done);
  inherited Done;
end;

constructor TSPXServerClientSocket.Init(AOwner: PSPXServerSocket; ASocket: TIPXSocket; AKeepOpen: boolean; AConnID: TSPXConnID;
            AMaxSendBufs: word);
begin
  if inherited Init(ASocket,AKeepOpen,AConnID,AMaxSendBufs)=false then
    Fail;
  Owner:=AOwner;
  if Assigned(Owner) then Owner^.AddClient(@Self);
end;

function TSPXServerClientSocket.SearchCompletedRecvECB: PSPXECB;
var E: PSPXECB;
begin
  if Assigned(Owner) then
    E:=Owner^.SearchCompletedRecvECB(@Self)
  else
    E:=nil;
  SearchCompletedRecvECB:=E;
end;

function TSPXServerClientSocket.SetupRecvECB(E: PSPXECB): boolean;
var OK: boolean;
begin
  if Assigned(Owner) then
    OK:=Owner^.SetupRecvECB(E)
  else
    OK:=inherited SetupRecvECB(E);
  SetupRecvECB:=OK;
end;

procedure TSPXServerClientSocket.SetParent(AParent: PSPXServerSocket);
begin
  Owner:=AParent;
end;

destructor TSPXServerClientSocket.Done;
begin
  if Assigned(Owner) then Owner^.RemoveClient(@Self);
  inherited Done;
end;

constructor TSPXServerSocket.Init(ASocket: TIPXSocket; AKeepOpen: boolean; ABackLog: word);
var E: PSPXECB;
    I: integer;
begin
  inherited Init(ASocket,AKeepOpen);
  BackLog:=ABackLog;
  New(ChildSockets, Init(10,10));
  New(ListenECBS, Init(10,10));
  New(RecvECBs, Init(10,10));
  for I:=1 to BackLog{*2} do
  begin
    New(E, Init(0));
    ListenECBs^.Insert(E);
    SetupListenECB(E);
  end;
  MaintainRecvECBs;
end;

function TSPXServerSocket.RecvECBCount: integer;
begin
  RecvECBCount:=(ChildSockets^.Count)*4+(BackLog+1);
end;

function TSPXServerSocket.SetupRecvECB(E: PSPXECB): boolean;
var OK: boolean;
begin
  with E^.ECB^ do
  begin
    SocketNo:=M2IW(Socket);
  end;
  OK:=SPXListenForPacket(0,E^);
  {$ifdef DEBUGIPX}if OK=false then writeln('SPXListenForPacket failed');{$endif}
  SetupRecvECB:=OK;
end;

function TSPXServerSocket.IncomingConnectionAvail: boolean;
var E: PSPXECB;
    OK: boolean;
begin
  E:=SearchCompletedECB;
  OK:=Assigned(E);
  if OK=false then MaintainRecvECBs;
  IncomingConnectionAvail:=OK;
end;

function TSPXServerSocket.AcceptConnection(AMaxSendBufs: word; AKeepOpen: boolean): PSPXServerClientSocket;
var OK: boolean;
    E: PSPXECB;
    C: PSPXServerClientSocket;
    ConnID: TSPXConnID;
begin
  C:=nil;
  E:=SearchCompletedECB;
  OK:=Assigned(E);
  if OK then
  begin
    ConnID:=E^.ECB^.IPXWorkSpace[1]+(E^.ECB^.IPXWorkSpace[2] shl 8);
    OK:=(ConnID<>0);
  end;
  if OK then
  begin
    New(C, Init(@Self,{Socket}0,AKeepOpen,ConnID,AMaxSendBufs));
    MaintainRecvECBs;
    SetupListenECB(E);
  end;
  AcceptConnection:=C;
end;

procedure TSPXServerSocket.MaintainRecvECBs;
procedure ReuseIfComplete(P: PSPXECB); {$ifndef FPC}far;{$endif}
begin
  with P^, ECB^, SPXHeader^ do
    if InUse=ipx_ecb_iu_Available then
      begin
        {$ifdef DEBUGIPX}writeln('weird packet encountered.');{$endif}
        SetupRecvECB(P);
      end;
end;
var E: PSPXECB;
    I: integer;
    WorkingRecvECBCount: integer;
begin
  I:=RecvECBCount;
  WorkingRecvECBCount:=GetWorkingRecvECBCount;
  while WorkingRecvECBCount<I do
  begin
    New(E, Init(256));
    RecvECBs^.Insert(E);
    SetupRecvECB(E);
    Inc(WorkingRecvECBCount);
  end;
(*  asm cli end; { disable interrupt to prevent deleting just-state-changed ECBs }
  if SearchCompletedECB=nil then { no connections pending }
    begin
      RecvECBs^.ForEach(@ReuseIfComplete);
      while RecvECBs^.Count>I do
        RecvECBs^.AtFree(RecvECBs^.Count-1);
    end;
  asm sti end;*)
end;

function TSPXServerSocket.SearchCompletedECB: PSPXECB;
function SearchCompleted(P: PSPXECB): boolean; {$ifndef FPC}far;{$endif}
var OK: boolean;
begin
  OK:=false;
  with P^, ECB^, SPXHeader^ do
  begin
    if InUse=ipx_ecb_iu_Available then
      if (Completion=ipx_ecb_cc_Success) then
        OK:=true
      else
        SetupListenECB(P);
  end;
  SearchCompleted:=OK;
end;
begin
  SearchCompletedECB:=ListenECBs^.FirstThat(@SearchCompleted);
end;

function TSPXServerSocket.GetWorkingRecvECBCount: integer;
var Count: integer;
procedure CountWorking(P: PSPXECB); {$ifndef FPC}far;{$endif}
begin
  with P^, ECB^ do
  begin
    if InUse<>ipx_ecb_iu_Available then
      Inc(Count);
  end;
end;
begin
{  SearchCompletedRecvECB(nil);}
  Count:=0;
  RecvECBs^.ForEach(@CountWorking);
  GetWorkingRecvECBCount:=Count;
end;

function TSPXServerSocket.SearchCompletedRecvECB(Client: PSPXServerClientSocket): PSPXECB;
function FindECB(P: PSPXECB): boolean; {$ifndef FPC}far;{$endif}
var Found: boolean;
    H: PSPXHeader;
    EC: PXPXECB;
begin
  Found:=false;
  with P^, ECB^, SPXHeader^ do
  begin
    EC:=ECB; H:=SPXHeader;
    if InUse=ipx_ecb_iu_Available then
      if (Completion=ipx_ecb_cc_Success) then
        begin
          if (P^.SPXHeader^.PacketSize<=SizeOf(P^.SPXHeader^)) or (P^.ECB^.FragmentCount=0) then
            begin
              {$ifdef DEBUG}
              DebugStr(debug_event_IPX_Error,'packet size too small. ('+IntToStr(Swap(P^.SPXHeader^.PacketSize))+')');
              {$endif}
              Client^.SetupRecvECB(P);
            end
          else
           if DestConnection=Client^.ConnID then
            if {$ifndef NOSEQCHECK}swap(SequenceNumber)=((Client^.LastSeq+1) and $ffff){$else}true{$endif} then
              Found:=true;
        end
      else
        begin
          {$ifdef DEBUG}
          DebugStr(debug_event_IPX_Error,
            'error receiving packet. (Seq:'+IntToStr(swap(SequenceNumber))+' Err:'+IntToStr(Completion)+')');
          {$endif}
          Client^.SetupRecvECB(P); { automatically reuse if error detected }
        end;
  end;
  FindECB:=Found;
end;
begin
  SearchCompletedRecvECB:=RecvECBs^.FirstThat(@FindECB);
end;

procedure TSPXServerSocket.AddClient(E: PSPXServerClientSocket);
begin
  ChildSockets^.Insert(E);
  MaintainRecvECBs;
end;

procedure TSPXServerSocket.RemoveClient(E: PSPXServerClientSocket);
begin
  ChildSockets^.Delete(E);
  MaintainRecvECBs;
end;

function TSPXServerSocket.SetupListenECB(E: PSPXECB): boolean;
var OK: boolean;
begin
  with E^, ECB^ do
  begin
    SocketNo:=M2IW(Socket);
    E^.SPXHeader^.Destination:=ListenAddr;
    OK:=SPXListenForConnection(E^);
    {$ifdef DEBUG}
    if OK=false then DebugStr(debug_event_IPX_Error,'SPXListenForConnection failed');
    {$endif}
  end;
  SetupListenECB:=OK;
end;

destructor TSPXServerSocket.Done;
procedure UnRegister(P: PSPXServerClientSocket); {$ifndef FPC}far;{$endif}
begin
  P^.SetParent(nil);
end;
begin
  ChildSockets^.ForEach(@UnRegister);
  ChildSockets^.DeleteAll;
  Dispose(ChildSockets, Done);
  Dispose(ListenECBs, Done);
  Dispose(RecvECBs, Done);
  inherited Done;
end;

END.
{
  $Log: ipxspx.pas,v $

  Revision 1.0  1998/05/07 12:34:12  gabor
     Original implementation

}
