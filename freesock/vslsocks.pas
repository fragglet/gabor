{
    $Id: vslsocks.pas,v 1.0 2000/08/24 09:46:55 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 2000 by Berczi Gabor ( e-mail: sting@freemail.hu )

    VSL (Virtual Socket Library) API routines

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

unit VSLSocks;

interface

const
      VSLSockVersion  = $101;

      vsl_firstint               = $66;
      vsl_lastint                = $60;

      vsl_maxsharedmemsize       = 4096;

      vsl_cmd_accept             = $01;
      vsl_cmd_bind               = $02;
      vsl_cmd_connect            = $03;
      vsl_cmd_listen             = $04;
      vsl_cmd_recv               = $05;
      vsl_cmd_send               = $06;
      vsl_cmd_closesocket        = $07;
      vsl_cmd_shutdown           = $08;
      vsl_cmd_socket             = $09;
      vsl_cmd_select             = $0a;
      vsl_cmd_fcntl              = $0b;
      vsl_cmd_getsockopt         = $0c;
      vsl_cmd_setsockopt         = $0d;
      vsl_cmd_recvfrom           = $0e;
      vsl_cmd_sendto             = $0f;
      vsl_cmd_recvmsg            = $10;
      vsl_cmd_sendmsg            = $11;
      vsl_cmd_getpeername        = $12;
      vsl_cmd_getsockname        = $13;
      vsl_cmd_ioctlsocket        = $14;

      vsl_cmd_gethostbyname      = $21;
      vsl_cmd_gethostbyaddr      = $22;
      vsl_cmd_sethostent         = $23;
      vsl_cmd_endhostent         = $24;
      vsl_cmd_gethostname        = $25;
      vsl_cmd_sethostname        = $26;
      vsl_cmd_getnetent          = $27;
      vsl_cmd_getnetbyname       = $28;
      vsl_cmd_getnetbyaddr       = $29;
      vsl_cmd_setnetent          = $2a;
      vsl_cmd_endnetent          = $2b;
      vsl_cmd_getprotoent        = $2c;
      vsl_cmd_getprotobyname     = $2d;
      vsl_cmd_getprotobynumber   = $2e;
      vsl_cmd_setprotoent        = $2f;
      vsl_cmd_endprotoent        = $30;
      vsl_cmd_getservent         = $31;
      vsl_cmd_getservbyname      = $32;
      vsl_cmd_getservbyport      = $33;
      vsl_cmd_setservent         = $34;
      vsl_cmd_endservent         = $35;
      vsl_cmd_pgethostbyname     = $36;
      vsl_cmd_vslcall            = $37;
      vsl_cmd_getdiagnostics     = $fd;
      vsl_cmd_getsharedmemptr    = $fe;
      vsl_cmd_getsignature       = $ff;

      vsl_err_WOULDBLOCK	= 35;{ Operation would block	}
      vsl_err_INPROGRESS	= 36;{ Operation now in progress	}
      vsl_err_ALREADY	        = 37;{ Operation already in progress }
      vsl_err_NOTSOCK	        = 38;{ Socket operation on non-socket }
      vsl_err_DESTADDRREQ	= 39;{ Destination address required	}
      vsl_err_MSGSIZE	        = 40;{ Message too long		}
      vsl_err_PROTOTYPE	        = 41;{ Protocol wrong type for socket }
      vsl_err_NOPROTOOPT	= 42;{ Bad protocol option		}
      vsl_err_PROTONOSUPPORT	= 43;{ Protocol not supported	}
      vsl_err_SOCKTNOSUPPORT	= 44;{ Socket type not supported	}
      vsl_err_OPNOTSUPP	        = 45;{ Operation not supported on socket }
      vsl_err_PFNOSUPPORT	= 46;{ Protocol family not supported }
      vsl_err_AFNOSUPPORT	= 47;{ Addr family not supported by prot family }
      vsl_err_ADDRINUSE	        = 48;{ Address already in use	}
      vsl_err_ADDRNOTAVAIL	= 49;{ Can't assign requested address }
      vsl_err_NETDOWN	        = 50;{ Network is down		}
      vsl_err_NETUNREACH	= 51;{ Network is unreachable	}
      vsl_err_NETRESET	        = 52;{ Network dropped connection or reset }
      vsl_err_CONNABORTED	= 53;{ Software caused connection abort }
      vsl_err_CONNRESET	        = 54;{ Connection reset by peer	}
      vsl_err_NOBUFS		= 55;{ No buffer space available	}
      vsl_err_ISCONN		= 56;{ Socket is already connected	}
      vsl_err_NOTCONN	        = 57;{ Socket is not connected	}
      vsl_err_SHUTDOWN	        = 58;{ Can't send after socket shutdown }
      vsl_err_TOOMANYREFS	= 59;{ Too many references: can't splice }

      vsl_err_TIMEDOUT	        = 60;{ Connection timed out 	}
      vsl_err_CONNREFUSED	= 61;{ Connection refused		}
      vsl_err_LOOP		= 62;{ Too many levels of symbolic links }
      vsl_err_HOSTDOWN	        = 64;{ Host is down			}
      vsl_err_HOSTUNREACH	= 65;{ Host is unreachable		}

      vsl_err_PROCLIM	        = 67;{ Too many processes }
      vsl_err_USERS		= 68;{ Too many users }
      vsl_err_DQUOT		= 69;{ Disc quota exceeded }
      vsl_err_STALE		= 70;{ Stale NFS file handle }
      vsl_err_REMOTE 	        = 71;{ Too many levels of remote in path }
      vsl_err_NOSTR		= 72;{ Device is not a stream }
      vsl_err_TIME		= 73;{ Timer expired }
      vsl_err_NOSR		= 74;{ Out of streams resources }
      vsl_err_NOMSG		= 75;{ No message of desired type }
      vsl_err_BADMSG 	        = 76;{ Trying to read unreadable message }
      vsl_err_IDRM		= 77;{ Identifier removed }

      vsl_err_BADVERSION	= 80;{ Library/driver version mismatch }
      vsl_err_INVALSOCK	        = 81;{ Invalid argument }

      vsl_err_TOOMANYSOCK	= 82;{ Too many open sockets }
      vsl_err_FAULTSOCK	        = 83;{ Bad address in sockets call }

      vsl_err_RESET		= 84;{ The socket has reset 	   }
      vsl_err_NOTUNIQUE	        = 85;{ Unique parameter required	   }
      vsl_err_NOGATEADDR	= 86;{ Gateway address required	   }
      vsl_err_SENDERR	        = 87;{ The packet could not be sent    }
      vsl_err_NOETHDRVR	        = 88;{ No driver or card failed init   }
      vsl_err_WRITPENDING	= 89;{ Queued write operation	   }
      vsl_err_READPENDING	= 90;{ Queued read operation	   }
      vsl_err_NOTCPIP	        = 91;{ TCPIP not loaded		   }
      vsl_err_DRVBUSY	        = 92;{ TCPIP busy			   }

      vsl_err_UNKNOWN 	        = 255;    { Unknown native TCP/IP error  }

      vsl_err_ENAMETOOLONG	= 63;{ File name too long		}
      vsl_err_ENOTEMPTY	        = 66;{ Directory not empty		}
      vsl_err_DEADLK 	        = 78;{ Deadlock condition. }
      vsl_err_NOLCK		= 79;{ No record locks available. }

      { #define's for EnumVSLNets() error codes: }
      vsl_err_NET_MODULE_NOT_LOADED    =  -1;
      vsl_err_NET_TRANSPORT_NOT_LOADED =  -2;
      vsl_err_LIBRARY_NOT_INITIALISED  =  -3;
      vsl_err_ALREADY_INITIALISED      =  -4;
      vsl_err_UNKNOWN_NETKEY           =  -5;
      vsl_err_UNSUPPORTED_NET          =  -6;
      vsl_err_UNKNOWN_NET_INTERFACE    =  -7;
      vsl_err_UNKNOWN_NET_MODULE       =  -8;
      vsl_err_UNSUPPORTED_COMMAND      =  -9;

      vsl_invalid_socket         = -1;

      vsl_FD_SETSIZE = 256;

      vsl_firstsocket = 0;
      vsl_lastsocket  = vsl_FD_SETSIZE-1;

      vsl_maxaddrs = 5;
      vsl_addrsize = 20;
      vsl_protosize = 20;
      vsl_namesize = 80;
      vsl_maxalias = 4;
      vsl_aliaslen = 20;
      vsl_aliassize = vsl_maxalias * vsl_aliaslen;

type
     TVSLSocket = integer;

     PVSLSockAddr = ^TVSLSockAddr;
     TVSLSockAddr = packed record
       sa_family : integer;
       sa_addr   : array[0..13] of byte;
     end;

     PVSLFDSET = ^TVSLFDSET;
     TVSLFDSET = packed array[0..(vsl_FD_SETSIZE+7) div 8-1] of byte;
     { each bit means one socket. bitpos = sockhandle }

     PVSLTimeVal = ^TVSLTimeVal;
     TVSLTimeVal = packed record tv_sec, tv_usec: longint; end;

     TVSLHostEnt = packed record
       h_name       : PChar;
       h_aliases    : ^PChar;
       h_addrtype   : integer;
       h_length     : integer;
       h_addr_list  : ^PChar;
       namebuf      : array[0..vsl_namesize] of char;
       aliaslist    : array[0..vsl_maxalias] of PChar;
       addrlist     : array[0..vsl_maxaddrs] of PChar;
       addrbuf      : array[0..vsl_addrsize] of char;
       aliasbuf     : array[0..vsl_aliassize] of char;
     end;

     TVSL_Params_Header = packed record
       RetCode      : integer;
       ErrNo        : integer;
     end;

     TVSL_Accept_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
       AddrLen      : integer;
       Addr         : TVSLSockAddr;
     end;

     TVSL_Bind_Params = TVSL_Accept_Params;

     TVSL_Connect_Params = TVSL_Accept_Params;

     TVSL_Listen_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
       BackLog      : integer;
     end;

     TVSL_Recv_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
       Len          : integer;
       Flags        : integer;
       Buffer       : record end;
     end;

     TVSL_Send_Params = TVSL_Recv_Params;

     TVSL_Select_Params = packed record
       Header       : TVSL_Params_Header;
       nfds         : integer;
       readfds      : TVSLFDSET;
       writefds     : TVSLFDSET;
       exceptfds    : TVSLFDSET;
       timeout      : TVSLTimeVal;
     end;

     TVSL_Socket_Params = packed record
       Header       : TVSL_Params_Header;
       Domain       : integer;
       SType        : integer;
       Protocol     : integer;
     end;

     TVSL_CloseSocket_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
     end;

     TVSL_Shutdown_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
       How          : integer;
     end;

     TVSL_FCntl_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
       Cmd          : integer;
       Arg          : integer;
     end;

     TVSL_IOCTL_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
       Cmd          : integer;
       Buffer       : record end;
     end;

     TVSL_GetSockOpt_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
       Level        : integer;
       OptName      : integer;
       OptLen       : integer;
       Buffer       : record end;
     end;

     TVSL_SetSockOpt_Params = TVSL_GetSockOpt_Params;

     TVSL_RecvFrom_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
       Len          : integer;
       Flags        : integer;
       AddrLen      : integer;
       Addr         : TVSLSockAddr;
       Buffer       : record end;
     end;

     TVSL_SendTo_Params = TVSL_RecvFrom_Params;

     TVSL_RecvMsg_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
       Msg          : pointer;
       Flags        : integer;
     end;

     TVSL_SendMsg_Params = TVSL_RecvMsg_Params;

     TVSL_GetSockName_Params = packed record
       Header       : TVSL_Params_Header;
       Socket       : TVSLSocket;
       NameLen      : integer;
       Name         : TVSLSockAddr;
     end;

     TVSL_GetPeerName_Params = TVSL_GetSockName_Params;

     TVSL_GetHostName_Params = packed record
       Header       : TVSL_Params_Header;
       NameLen      : integer;
       Buffer       : record end;
     end;

     TVSL_GetHostByName_Params = packed record
       Header       : TVSL_Params_Header;
       Buffer       : TVSLHostEnt{record end};
     end;

     TVSL_GetHostByAddr_Params = packed record
       Header       : TVSL_Params_Header;
       Len          : integer;
       AType        : integer;
       Buffer       : TVSLHostEnt{record end};
     end;

     TVSL_GetProtByName_Params = TVSL_GetHostByName_Params;

     TVSL_GetProtByNumber_Params = packed record
       Header       : TVSL_Params_Header;
       Number       : integer;
       Buffer       : record end;
     end;

     TVSL_GetServByName_Params = packed record
       Header       : TVSL_Params_Header;
       Name         : pointer;
       Buffer       : record end;
     end;

     TVSL_GetServByPort_Params = packed record
       Header       : TVSL_Params_Header;
       Port         : integer;
       Buffer       : record end;
     end;

     TVSL_VSLCall_Params = packed record
       Header       : TVSL_Params_Header;
       Command      : integer;
       InLen        : integer;
       OutLen       : integer;
       RunningInPM  : integer;
       Buffer       : record end;
     end;

const VSLError   : integer = 0;
      VSLIntNo   : byte    = 0;
      VSLVersion : byte    = 0;

function  VSLInit: boolean;
procedure VSLDone;

function vsl_socket(Family, SocketType, Protocol: word; var Socket: TVSLSocket): boolean;
function vsl_connect(Socket: TVSLSocket; Address: TVSLSockAddr; AddrSize: longint): boolean;
function vsl_closesocket(Socket: TVSLSocket): boolean;
function vsl_send(Socket: TVSLSocket; var Data; var DataSize: word; Options: word): boolean;
function vsl_recv(Socket: TVSLSocket; var Data; var DataSize: word; Options: word): boolean;
function vsl_sendto(Socket: TVSLSocket; var Data; var DataSize: word; Options: word; To_: TVSLSockAddr; ToLen: word): boolean;
function vsl_recvfrom(Socket: TVSLSocket; var Data; var DataSize: word; Options: word; var From: TVSLSockAddr;
         var FromLen: word): boolean;
function vsl_listen(Socket: TVSLSocket; BackLog: word): boolean;
function vsl_bind(Socket: TVSLSocket; Address: TVSLSockAddr; AddrSize: word): boolean;
function vsl_accept(Socket: TVSLSocket; Address: PVSLSockAddr; var AddrSize: word; var NewSocket: TVSLSocket): boolean;
function vsl_getsockname(Socket: TVSLSocket; var Address: TVSLSockAddr; var AddrSize: word): boolean;
function vsl_getpeername(Socket: TVSLSocket; var Address: TVSLSockAddr; var AddrSize: word): boolean;
function vsl_select(nfds: word; readfds, writefds, exceptfds: PVSLFDSET; timeout: TVSLTimeVal): boolean;
function vsl_getsockopt(Socket: TVSLSocket; Level, OptName: integer; OptVal: PChar; var OptLen: integer): boolean;
function vsl_setsockopt(Socket: TVSLSocket; Level, OptName: integer; OptVal: PChar; OptLen: integer): boolean;
function vsl_gethostname(name: PChar; size: word): boolean;
function vsl_gethostbyname(name: PChar; var hostent: TVSLHostEnt): boolean;

procedure vsl_FD_ZERO(var FDS: TVSLFDSET);
function  vsl_FD_SET(Socket: TVSLSocket; var FDS: TVSLFDSET): boolean;
function  vsl_FD_ISSET(Socket: TVSLSocket; const FDS: TVSLFDSET; var IsSet: boolean): boolean;
function  vsl_FD_CLEAR(Socket: TVSLSocket; var FDS: TVSLFDSET): boolean;

implementation

uses Dos,pmode,Strings;

const VSLSharedMemPtr : pointer = nil;
      VSLSharedMemSize: word    = 0;

function min(a,b: longint): longint;
begin
  if a<b then min:=a else min:=b;
end;

function callvsl(Cmd: byte; var RCB; RCBSize: word): boolean;
var r: registers;
begin
  if VSLIntNo=0 then
    VSLError:=-1
  else
    begin
      MovePMToDos(@RCB,VSLSharedMemPtr,RCBSize);
      r.ah:=Cmd;
      realintr(VSLIntNo,r);
      MoveDosToPM(VSLSharedMemPtr,@RCB,RCBSize);
      VSLError:=TVSL_Params_Header(RCB).ErrNo;
    end;
  callvsl:=(VSLError=0);
end;

function VSLInit: boolean;
var r: registers;
    I: integer;
    OK: boolean;
    P: pointer;
begin
  if VSLIntNo=0 then
  begin
    { check int2f interface here }
    for I:=$C0 to $FF do
    begin
      FillChar(r,sizeof(r),0);
      r.ah:=I;
      r.al:=0; r.bl:=0;
      realintr($2f,r);
      if r.al in[vsl_lastint..vsl_firstint] then
        begin
          VSLIntNo:=r.al;
          Break;
        end;
    end;
  end;
  if VSLIntNo=0 then
  for I:=vsl_firstint downto vsl_lastint do
   begin
     realGetIntVec(I,P);
     if P<>nil then
       begin
         FillChar(r,sizeof(r),0);
         r.ah:=vsl_cmd_GetSignature;
         realintr(I,r);
         if (r.ah=$88) then
           begin
             VSLIntNo:=I;
             VSLVersion:=r.bh;
             Break;
           end;
       end;
   end;
  OK:=(VSLIntNo<>0);
  if OK then
  begin
    FillChar(r,sizeof(r),0);
    r.ah:=vsl_cmd_GetSharedMemPtr;
    intr(VSLIntNo,r);
    VSLSharedMemPtr:=MakePtr(r.dx,r.bx);
    VSLSharedMemSize:=r.ax;
    OK:=(VSLSharedMemPtr<>nil);
  end;
  VSLInit:=OK;
end;

procedure VSLDone;
var r: registers;
begin
  if VSLIntNo=0 then Exit;
  VSLIntNo:=0;
end;

function vsl_socket(Family, SocketType, Protocol: word; var Socket: TVSLSocket): boolean;
var Params: TVSL_Socket_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.Domain:=Family;
  Params.SType:=SocketType;
  Params.Protocol:=Protocol;
  OK:=callvsl(vsl_cmd_socket,Params,sizeof(Params));
  OK:=OK and (Params.Header.RetCode<>-1);
  if OK then
    Socket:=Params.Header.RetCode
  else
    Socket:=vsl_invalid_socket;
  vsl_socket:=OK;
end;

function vsl_connect(Socket: TVSLSocket; Address: TVSLSockAddr; AddrSize: longint): boolean;
var Params: TVSL_Connect_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.Socket:=Socket;
  Params.Addr:=Address;
  Params.AddrLen:=AddrSize;
  OK:=callvsl(vsl_cmd_connect,Params,sizeof(Params));
  vsl_connect:=OK;
end;

function vsl_closesocket(Socket: TVSLSocket): boolean;
var Params: TVSL_CloseSocket_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.Socket:=Socket;
  OK:=callvsl(vsl_cmd_closesocket,Params,sizeof(Params));
  vsl_closesocket:=OK;
end;

function vsl_send(Socket: TVSLSocket; var Data; var DataSize: word; Options: word): boolean;
var Params: record
      P: TVSL_Send_Params;
      Data: array[0..vsl_maxsharedmemsize-1-sizeof(TVSL_Send_Params)] of byte;
    end;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.P.Socket:=Socket;
  Params.P.Len:=Min(DataSize,sizeof(Params.Data));
  Params.P.Flags:=Options;
  Move(Data,Params.Data,Params.P.Len);
  OK:=callvsl(vsl_cmd_send,Params,sizeof(Params));
  if OK=false then DataSize:=0 else
    DataSize:=Params.P.Header.RetCode;
  vsl_send:=OK;
end;

function vsl_recv(Socket: TVSLSocket; var Data; var DataSize: word; Options: word): boolean;
var Params: record
      P: TVSL_Recv_Params;
      Data: array[0..vsl_maxsharedmemsize-1-sizeof(TVSL_Recv_Params)] of byte;
    end;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.P.Socket:=Socket;
  Params.P.Len:=Min(DataSize,sizeof(Params.Data));
  Params.P.Flags:=Options;
  OK:=callvsl(vsl_cmd_recv,Params,sizeof(Params));
  if OK=false then DataSize:=0 else
    DataSize:=Params.P.Header.RetCode;
  if DataSize>0 then
    Move(Params.Data,Data,DataSize);
  vsl_recv:=OK;
end;

function vsl_sendto(Socket: TVSLSocket; var Data; var DataSize: word; Options: word; To_: TVSLSockAddr; ToLen: word): boolean;
var Params: record
      P: TVSL_SendTo_Params;
      Data: array[0..vsl_maxsharedmemsize-1-sizeof(TVSL_SendTo_Params)] of byte;
    end;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.P.Socket:=Socket;
  Params.P.Len:=Min(DataSize,sizeof(Params.Data));
  Params.P.Flags:=Options;
  Params.P.AddrLen:=ToLen;
  Params.P.Addr:=To_;
  Move(Data,Params.Data,Params.P.Len);
  OK:=callvsl(vsl_cmd_sendto,Params,sizeof(Params));
  if OK=false then DataSize:=0 else
    DataSize:=Params.P.Header.RetCode;
  vsl_sendto:=OK;
end;

function vsl_recvfrom(Socket: TVSLSocket; var Data; var DataSize: word; Options: word; var From: TVSLSockAddr;
         var FromLen: word): boolean;
var Params: record
      P: TVSL_RecvFrom_Params;
      Data: array[0..vsl_maxsharedmemsize-1-sizeof(TVSL_RecvFrom_Params)] of byte;
    end;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.P.Socket:=Socket;
  Params.P.Len:=Min(DataSize,sizeof(Params.Data));
  Params.P.Flags:=Options;
  OK:=callvsl(vsl_cmd_recvfrom,Params,sizeof(Params));
  if OK=false then DataSize:=0 else
  begin
    DataSize:=Params.P.Header.RetCode;
    From:=Params.P.Addr;
    FromLen:=Params.P.AddrLen;
  end;
  if DataSize>0 then
    Move(Params.Data,Data,DataSize);
  vsl_recvfrom:=OK;
end;

function vsl_listen(Socket: TVSLSocket; BackLog: word): boolean;
var Params: TVSL_Listen_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.Socket:=Socket;
  Params.BackLog:=BackLog;
  OK:=callvsl(vsl_cmd_listen,Params,sizeof(Params));
  vsl_listen:=OK;
end;

function vsl_bind(Socket: TVSLSocket; Address: TVSLSockAddr; AddrSize: word): boolean;
var Params: TVSL_Bind_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.Socket:=Socket;
  Params.Addr:=Address;
  Params.AddrLen:=AddrSize;
  OK:=callvsl(vsl_cmd_bind,Params,sizeof(Params));
  vsl_bind:=OK;
end;

function vsl_accept(Socket: TVSLSocket; Address: PVSLSockAddr; var AddrSize: word; var NewSocket: TVSLSocket): boolean;
var Params: TVSL_Accept_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.Socket:=Socket;
  Params.AddrLen:=Min(AddrSize,sizeof(Params.Addr));
  OK:=callvsl(vsl_cmd_accept,Params,sizeof(Params));
  if Assigned(Address) then Address^:=Params.Addr;
  if OK=false then
    begin
      AddrSize:=0;
      NewSocket:=vsl_invalid_socket;
    end
  else
    begin
      AddrSize:=Params.AddrLen;
      NewSocket:=Params.Header.RetCode;
    end;
  vsl_accept:=OK;
end;

function vsl_getsockname(Socket: TVSLSocket; var Address: TVSLSockAddr; var AddrSize: word): boolean;
var Params: TVSL_GetSockName_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.Socket:=Socket;
  Params.NameLen:=Min(AddrSize,sizeof(Params.Name));
  OK:=callvsl(vsl_cmd_getsockname,Params,sizeof(Params));
  if OK=false then AddrSize:=0 else
  begin
    AddrSize:=Params.NameLen;
    Address:=Params.Name;
  end;
  vsl_getsockname:=OK;
end;

function vsl_getpeername(Socket: TVSLSocket; var Address: TVSLSockAddr; var AddrSize: word): boolean;
var Params: TVSL_GetPeerName_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.Socket:=Socket;
  Params.NameLen:=Min(AddrSize,sizeof(Params.Name));
  OK:=callvsl(vsl_cmd_getpeername,Params,sizeof(Params));
  if OK=false then AddrSize:=0 else
  begin
    AddrSize:=Params.NameLen;
    Address:=Params.Name;
  end;
  vsl_getpeername:=OK;
end;

function vsl_select(nfds: word; readfds, writefds, exceptfds: PVSLFDSET; timeout: TVSLTimeVal): boolean;
var Params: TVSL_Select_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.nfds:=nfds;
  if assigned(readfds) then Params.readfds:=readfds^;
  if assigned(writefds) then Params.readfds:=writefds^;
  if assigned(exceptfds) then Params.readfds:=exceptfds^;
  Params.timeout:=timeout;
  OK:=callvsl(vsl_cmd_select,Params,sizeof(Params));
  if OK then
  begin
    if assigned(readfds) then readfds^:=Params.readfds;
    if assigned(writefds) then writefds^:=Params.readfds;
    if assigned(exceptfds) then exceptfds^:=Params.readfds;
  end;
  vsl_select:=OK;
end;

function vsl_getsockopt(Socket: TVSLSocket; Level, OptName: integer; OptVal: PChar; var OptLen: integer): boolean;
var Params: record
      P: TVSL_GetSockOpt_Params;
      Data: array[0..1024-1-sizeof(TVSL_GetSockOpt_Params)] of byte;
    end;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.P.Socket:=Socket;
  Params.P.Level:=Level;
  Params.P.OptName:=OptName;
  Params.P.OptLen:=OptLen;
  OK:=callvsl(vsl_cmd_getsockopt,Params,sizeof(Params));
  if OK then
   if Assigned(OptVal) then
    Move(Params.Data,OptVal^,Params.P.OptLen);
  OptLen:=Params.P.OptLen;
  vsl_getsockopt:=OK;
end;

function vsl_setsockopt(Socket: TVSLSocket; Level, OptName: integer; OptVal: PChar; OptLen: integer): boolean;
var Params: record
      P: TVSL_SetSockOpt_Params;
      Data: array[0..1024-1-sizeof(TVSL_SetSockOpt_Params)] of byte;
    end;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.P.Socket:=Socket;
  Params.P.Level:=Level;
  Params.P.OptName:=OptName;
  Params.P.OptLen:=OptLen;
  if Assigned(OptVal) then
   Move(OptVal^,Params.Data,Params.P.OptLen);
  OK:=callvsl(vsl_cmd_setsockopt,Params,sizeof(Params));
  vsl_setsockopt:=OK;
end;

function vsl_gethostname(name: PChar; size: word): boolean;
var Params: record
      P: TVSL_GetHostName_Params;
      Data: array[0..127] of char;
    end;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  Params.P.NameLen:=Min(size,sizeof(Params.Data));
  OK:=callvsl(vsl_cmd_gethostname,Params,sizeof(Params));
  if OK then
    StrCopy(name,@Params.Data);
  vsl_gethostname:=OK;
end;

function vsl_gethostbyname(name: PChar; var hostent: TVSLHostEnt): boolean;
var Params: TVSL_GetHostByName_Params;
    OK: boolean;
begin
  FillChar(Params,sizeof(Params),0);
  StrCopy(@Params.Buffer,name);
  OK:=callvsl(vsl_cmd_gethostbyname,Params,sizeof(Params));
  if OK=false then FillChar(hostent,sizeof(hostent),0) else
    hostent:=Params.Buffer;
  vsl_gethostbyname:=OK;
end;

function vsl_isvalidsocket(Socket: TVSLSocket): boolean;
begin
  vsl_isvalidsocket:=(vsl_firstsocket<=Socket) and (Socket<=vsl_lastsocket);
end;

function BytePos(Socket: TVSLSocket): integer;
begin
  BytePos:=(Socket mod vsl_FD_SETSIZE) shr 3; { div 8 }
end;

function BitMask(Socket: TVSLSocket): byte;
begin
  BitMask:=1 shl ( (Socket mod vsl_FD_SETSIZE) and $07 ); { mod 8 }
end;

procedure vsl_FD_ZERO(var FDS: TVSLFDSET);
begin
  FillChar(FDS,SizeOf(FDS),0);
end;

function  vsl_FD_SET(Socket: TVSLSocket; var FDS: TVSLFDSET): boolean;
var OK: boolean;
begin
  OK:=vsl_isvalidsocket(Socket);
  if OK then
    FDS[BytePos(Socket)]:=FDS[BytePos(Socket)] or BitMask(Socket);
  vsl_FD_SET:=OK;
end;

function  vsl_FD_ISSET(Socket: TVSLSocket; const FDS: TVSLFDSET; var IsSet: boolean): boolean;
var OK: boolean;
begin
  OK:=vsl_isvalidsocket(Socket);
  IsSet:=false;
  if OK then
    IsSet:=(FDS[BytePos(Socket)] and BitMask(Socket))<>0;
  vsl_FD_ISSET:=OK;
end;

function  vsl_FD_CLEAR(Socket: TVSLSocket; var FDS: TVSLFDSET): boolean;
var OK: boolean;
begin
  OK:=vsl_isvalidsocket(Socket);
  if OK then
    FDS[BytePos(Socket)]:=FDS[BytePos(Socket)] and not BitMask(Socket);
  vsl_FD_CLEAR:=OK;
end;
END.
{
  $Log: vslsocks.pas,v $

  Revision 1.0  2000/08/24 09:46:55  gabor
     Original implementation

}
