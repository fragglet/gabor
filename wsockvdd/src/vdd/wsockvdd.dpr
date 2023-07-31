{
    $Id: wsockvdd.pas,v 1.1 1999/12/11 09:46:55 gabor Exp $
    This file is part of the Free Component Library
    Copyright (c) 1999 by Berczi Gabor

    WinSock VDD driver

    See the file COPYING.WSD, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{

 This .DLL is the actual implementor of all the wsock.vxd calls.
 The VDD gets installed by the TSR component and gets all the native and
 emulated wsock.vxd calls. It reads the appropriate parameters directly
 from the registers passed and from the VM memory, executes the appropriate
 Winsock calls, and then passes data and the result back to the VM.

}

library wsockvdd;

uses
  SysUtils,windows,winsock,VDDSvc,NTVDD;

const
      wsock_max_fd         = 64;

      wsock_cmd_First         = $0100;
      wsock_cmd_Accept        = wsock_cmd_First + $00;
      wsock_cmd_Bind          = wsock_cmd_First + $01;
      wsock_cmd_Close         = wsock_cmd_First + $02;
      wsock_cmd_Connect       = wsock_cmd_First + $03;
      wsock_cmd_GetPeerName   = wsock_cmd_First + $04;
      wsock_cmd_GetSockName   = wsock_cmd_First + $05;
      wsock_cmd_GetSockOpt    = wsock_cmd_First + $06;
      wsock_cmd_IOCTL         = wsock_cmd_First + $07;
      wsock_cmd_Listen        = wsock_cmd_First + $08;
      wsock_cmd_Receive       = wsock_cmd_First + $09;
      wsock_cmd_SelectSetup   = wsock_cmd_First + $0a;
      wsock_cmd_SelectCleanup = wsock_cmd_First + $0b;
      wsock_cmd_AsyncSelect   = wsock_cmd_First + $0c;
      wsock_cmd_Send          = wsock_cmd_First + $0d;
      wsock_cmd_SetSockOpt    = wsock_cmd_First + $0e;
      wsock_cmd_Shutdown      = wsock_cmd_First + $0f;
      wsock_cmd_Socket        = wsock_cmd_First + $10;
      wsock_cmd_Signal        = wsock_cmd_First + $16;
      wsock_cmd_SignalAll     = wsock_cmd_First + $17;
      wsock_cmd_InstallEventHandler= wsock_cmd_First + $19;

      wsock_FD_FAILED_CONNECT = $0100;

type
     TWSockSocket = dword;

     TWSock_Accept_Params = packed record
       Address          : pointer;
       ListeningSocket  : TWSockSocket;
       ConnectedSocket  : TWSockSocket;
       AddressLength    : dword;
       ConnectedSocketHandle: dword;
       ApcRoutine       : pointer;
       ApcContext       : word;
     end;

     TWSock_Bind_Params = packed record
       Address          : pointer;
       Socket           : TWSockSocket;
       AddressLength    : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
     end;

     TWSock_Connect_Params = TWSock_Bind_Params;

     TWSock_Close_Params = packed record
       Socket      : TWSockSocket;
     end;

     TWSock_GetPeerName_Params = packed record
       Address          : pointer;
       Socket           : TWSockSocket;
       AddressLength    : dword;
     end;

     TWSock_GetSockName_Params = TWSock_GetPeerName_Params;

     TWSock_GetSocketOpt_Params = packed record
       Value            : pointer;
       Socket           : TWSockSocket;
       OptionLevel      : dword;
       OptionName       : dword;
       ValueLength      : dword;
       IntValue         : dword;
     end;

     TWSock_SetSocketOpt_Params = TWSock_GetSocketOpt_Params;

     TWSock_IOCTL_Params = packed record
       Socket           : TWSockSocket;
       Command          : dword;
       Param            : pointer;
     end;

     TWSock_Listen_Params = packed record
       Socket           : TWSockSocket;
       BackLogSize      : dword;
     end;

     TWSock_Receive_Params = packed record
       Buffer           : pointer;
       Address          : pointer;
       Socket           : TWSockSocket;
       BufferLength     : dword;
       Flags            : dword;
       AddressLength    : dword;
       BytesTransmitted : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
       TimeOut          : dword;
     end;

     TWSock_Send_Params = TWSock_Receive_Params;

     TWSock_Shutdown_Params = packed record
       Socket           : TWSockSocket;
       How              : dword;
     end;

     TWSock_Socket_Params = packed record
       Family      : dword;
       SocketType  : dword;
       Protocol    : dword;
       NewSocket   : TWSockSocket;
       Handle      : dword;
     end;

     TWSock_Signal_Params = packed record
       Socket           : TWSockSocket;
       Event            : dword;
       Status           : dword;
     end;

     TWSock_SignalAll_Params = packed record
       Socket           : TWSockSocket;
       Status           : dword;
     end;

     TWSock_InstallEventHandler_Params = packed record
       PostMessageCallBack  : pointer;
       Pad                  : array[0..15] of byte;
     end;

     TWSock_AsyncSelect_Params = packed record
       Socket           : TWSockSocket;
       Window           : dword;
       Message          : dword;
       Events           : dword;
     end;

     TWSock_Sock_ListItem = packed record
       Socket           : TWSockSocket;
       EventMask        : dword; { see FD_xxxx constants }
       Context          : dword;
     end;

     PWSock_Sock_List = ^TWSock_Sock_List;
     TWSock_Sock_List = array[1..wsock_max_fd] of TWSock_Sock_ListItem;

     TWSock_SelectSetup_Params = packed record
       ReadList         : pointer; { -> array of TWSock_Sock_ListItem }
       WriteList        : pointer;
       ExceptList       : pointer;
       ReadCount        : dword;
       WriteCount       : dword;
       ExceptCount      : dword;
       ApcRoutine       : pointer;
       ApcContext       : dword;
     end;

     TWSock_SelectCleanup_Params = packed record
       ReadList         : pointer; { -> array of TWSock_Sock_ListItem }
       WriteList        : pointer;
       ExceptList       : pointer;
       ReadCount        : dword;
       WriteCount       : dword;
       ExceptCount      : dword;
     end;

     TWSock_WSIOStatus = packed record
       IoStatus         : dword;
       IoCompleted      : byte;
       IoCancelled      : byte;
       IoTimedOut       : byte;
       IoSpare1         : byte;
     end;

var WSAData: TWSAData;

function VDDInitialize(hVdd: THandle; dwReason: dword; lpReserved: pointer): longbool; stdcall;
begin
  Result:=false;
  try
    case dwReason of
      DLL_PROCESS_ATTACH :
        Result:=WSAStartup($101,WSAData)=0;
      DLL_PROCESS_DETACH :
        Result:=(WSACleanUp=0);
    else
      Result:=true;
    end;
  except
    Result:=false;
  end;
end;

procedure VDDRegisterInit; stdcall;
var Err: integer;
begin
  Err:=WSAStartup($101,WSAData);
  if Err<>0 then Err:=1;
  setCF(Err);
end;

const LastSockHandle : integer = 0;

function GenSocketHandle: integer;
begin
  Inc(LastSockHandle);
  Result:=LastSockHandle;
end;

procedure SockListToFD(SockList: PWSock_Sock_List; FDCount: integer; var FD: TFDSET);
var I: integer;
begin
  FD_ZERO(FD);
  for I:=1 to FDCount do
    FD_SET(SockList^[I].Socket,FD);
end;

procedure FDToSockList(const FD: TFDSET; SockList: PWSock_Sock_List; var FDCount: integer);
var I: integer;
begin
  FDCount:=FD.fd_count;
  FillChar(SockList^,sizeof(SockList^[1])*FDCount,0);
  for I:=1 to FDCount do
    SockList^[I].Socket:=FD.fd_array[I-1];
end;

procedure ConvFDTo(FDListVMPtr: PWSock_Sock_List; FDCount: integer; var FD: TFDSET; var FDP: PFDSET);
var SockList: PWSock_Sock_List;
begin
  if FDListVMPtr<>nil then
    begin
      SockList:=GetVDMPointer(integer(FDListVMPtr),FDCount*sizeof(TWSock_Sock_ListItem),0);
      SockListToFD(SockList,FDCount,FD);
      FDP:=@FD;
    end
  else
    FDP:=nil;
end;

procedure ConvFDFrom(FDP: PFDSET; FDListVMPtr: PWSock_Sock_List; var FDCount: integer);
var SockList: PWSock_Sock_List;
begin
  if FDListVMPtr=nil then Exit;
  SockList:=GetVDMPointer(integer(FDListVMPtr),FDCount*sizeof(TWSock_Sock_ListItem),0);
  if FDP=nil then { this shouldn't ever occour }
    FillChar(SockList^,FDCount*sizeof(TWSock_Sock_ListItem),0)
  else
    FDToSockList(FDP^,SockList,FDCount);
end;

const ReportErrors: boolean = true;

procedure ErrorBox(const S: string);
begin
  if ReportErrors=false then Exit;
  ReportErrors:=
  windows.MessageBox(0,PChar(S+#13+#13+
    'Do you want to be notified of errors in the future?'),
    'WSOCKVDD',
    MB_ICONEXCLAMATION+MB_YESNO+MB_TASKMODAL+MB_SETFOREGROUND)<>IDNO;
end;

procedure VDDDispatch; stdcall;
var VDD: THandle;
    Func: integer;
    Err: integer;
    P: pointer;
    AddrP: PSockAddr;
    BufP,ValueP: pointer;
    RetValue,ParamSize: integer;
    RFD,WFD,EFD: TFDSET;
    RFDP,WFDP,EFDP: PFDSET;
begin
{  Err:=WSAEOPNOTSUPP;}
  try
    VDD:=getAX;
    setAX(getBP);
    Func:=getAX;
    case Func of
      wsock_cmd_Accept        :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_Accept_Params),0);
          with TWSock_Accept_Params(P^) do
          if (ApcRoutine<>nil) or (ApcContext<>0) then
            Err:=WSAEOPNOTSUPP else
          begin
            ConnectedSocketHandle:=0;
            if AddressLength<>0 then
              AddrP:=GetVDMPointer(integer(Address),AddressLength,0)
            else
              AddrP:=nil;
            ConnectedSocket:=accept(ListeningSocket,AddrP,@AddressLength);
            if ConnectedSocket=INVALID_SOCKET then
              begin
                Err:=WSAGetLastError;
                AddressLength:=0;
              end
            else
              begin
                Err:=0;
                ConnectedSocketHandle:=ConnectedSocket;
              end;
          end;
        end;
      wsock_cmd_Bind          :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_Bind_Params),0);
          with TWSock_Bind_Params(P^) do
          if (ApcRoutine<>nil) or (ApcContext<>0) then
            Err:=WSAEOPNOTSUPP else
          begin
            if AddressLength<>0 then
              AddrP:=GetVDMPointer(integer(Address),AddressLength,0)
            else
              AddrP:=nil;
            if bind(Socket,AddrP^,AddressLength)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_Close         :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_Close_Params),0);
          with TWSock_Close_Params(P^) do
          begin
            if closesocket(Socket)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_Connect       :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_Connect_Params),0);
          with TWSock_Connect_Params(P^) do
          if (ApcRoutine<>nil) or (ApcContext<>0) then
            Err:=WSAEOPNOTSUPP else
          begin
            if AddressLength<>0 then
              AddrP:=GetVDMPointer(integer(Address),AddressLength,0)
            else
              AddrP:=nil;
            if connect(Socket,AddrP^,AddressLength)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_GetPeerName   :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_GetPeerName_Params),0);
          with TWSock_GetPeerName_Params(P^) do
          begin
            if AddressLength<>0 then
              AddrP:=GetVDMPointer(integer(Address),AddressLength,0)
            else
              AddrP:=nil;
            if getpeername(Socket,AddrP^,AddressLength)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_GetSockName   :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_GetSockName_Params),0);
          with TWSock_GetSockName_Params(P^) do
          begin
            if AddressLength<>0 then
              AddrP:=GetVDMPointer(integer(Address),AddressLength,0)
            else
              AddrP:=nil;
            if getsockname(Socket,AddrP^,AddressLength)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_GetSockOpt    :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_GetSocketOpt_Params),0);
          with TWSock_GetSocketOpt_Params(P^) do
          begin
            if Value<>nil then
              ValueP:=GetVDMPointer(integer(getES) shl 16 + getBX + 20,ValueLength,0)
            else
              ValueP:=GetVDMPointer(integer(Value),ValueLength,0); { ptr to IntValue }
            if getsockopt(Socket,OptionLevel,OptionName,ValueP,ValueLength)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_IOCTL         :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_IOCTL_Params),0);
          with TWSock_IOCTL_Params(P^) do
          begin
            ParamSize:=4;
            if Param<>nil then
              ValueP:=GetVDMPointer(integer(getES) shl 16 + getBX + 20,ParamSize,0)
            else
              ValueP:=nil;
            if ioctlsocket(Socket,Command,pinteger(ValueP)^)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_Listen        :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_Listen_Params),0);
          with TWSock_Listen_Params(P^) do
          begin
            if listen(Socket,BackLogSize)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_Receive       :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_Receive_Params),0);
          with TWSock_Receive_Params(P^) do
          if (ApcRoutine<>nil) or (ApcContext<>0) or
             (Timeout<>-1) then
            Err:=WSAEOPNOTSUPP else
          begin
            if AddressLength<>0 then
              AddrP:=GetVDMPointer(integer(Address),AddressLength,0)
            else
              AddrP:=nil;
            if BufferLength<>0 then
              BufP:=GetVDMPointer(integer(Buffer),BufferLength,0)
            else
              BufP:=nil;
            if AddrP<>nil then
              RetValue:=recvfrom(Socket,BufP^,BufferLength,Flags,AddrP^,AddressLength)
            else
              RetValue:=recv(Socket,BufP^,BufferLength,Flags);
            if RetValue=SOCKET_ERROR then
              begin
                Err:=WSAGetLastError;
                BytesTransmitted:=0;
              end
            else
              begin
                Err:=0;
                BytesTransmitted:=RetValue;
              end;
          end;
        end;
      wsock_cmd_SelectSetup   :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_SelectSetup_Params),0);
          with TWSock_SelectSetup_Params(P^) do
          if (ApcRoutine<>nil) or (ApcContext<>0) then
            Err:=WSAEOPNOTSUPP else
          begin
            ConvFDTo(ReadList,ReadCount,RFD,RFDP);
            ConvFDTo(WriteList,WriteCount,WFD,WFDP);
            ConvFDTo(ExceptList,ExceptCount,EFD,EFDP);
            if select(0,RFDP,WFDP,EFDP,nil)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
            ConvFDFrom(RFDP,ReadList,ReadCount);
            ConvFDFrom(WFDP,WriteList,WriteCount);
            ConvFDFrom(EFDP,ExceptList,ExceptCount);
          end;
        end;
      wsock_cmd_SelectCleanup :
        begin
          Err:=0;
        end;
      wsock_cmd_AsyncSelect   :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_AsyncSelect_Params),0);
          with TWSock_AsyncSelect_Params(P^) do
          begin
            if WSAAsyncSelect(Socket,Window,Message,Events)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_Send          :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_Send_Params),0);
          with TWSock_Send_Params(P^) do
          if (ApcRoutine<>nil) or (ApcContext<>0) or
             (Timeout<>-1) then
            Err:=WSAEOPNOTSUPP else
          begin
            if AddressLength<>0 then
              AddrP:=GetVDMPointer(integer(Address),AddressLength,0)
            else
              AddrP:=nil;
            if BufferLength<>0 then
              BufP:=GetVDMPointer(integer(Buffer),BufferLength,0)
            else
              BufP:=nil;
            if AddrP<>nil then
              RetValue:=sendto(Socket,BufP^,BufferLength,Flags,AddrP^,AddressLength)
            else
              RetValue:=send(Socket,BufP^,BufferLength,Flags);
            if RetValue=SOCKET_ERROR then
              begin
                Err:=WSAGetLastError;
                BytesTransmitted:=0;
              end
            else
              begin
                Err:=0;
                BytesTransmitted:=RetValue;
              end;
          end;
        end;
      wsock_cmd_SetSockOpt    :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_SetSocketOpt_Params),0);
          with TWSock_SetSocketOpt_Params(P^) do
          begin
            if Value<>nil then
              ValueP:=GetVDMPointer(integer(getES) shl 16 + getBX + 20,ValueLength,0)
            else
              ValueP:=GetVDMPointer(integer(Value),ValueLength,0); { ptr to IntValue }
            if setsockopt(Socket,OptionLevel,OptionName,ValueP,ValueLength)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_Shutdown      :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_Shutdown_Params),0);
          with TWSock_Shutdown_Params(P^) do
          begin
            if shutdown(Socket,How)=SOCKET_ERROR then
              Err:=WSAGetLastError
            else
              Err:=0;
          end;
        end;
      wsock_cmd_Socket        :
        begin
          P:=GetVDMPointer(integer(getES) shl 16 + getBX,sizeof(TWSock_Socket_Params),0);
          with TWSock_Socket_Params(P^) do
          begin
            Handle:=0;
            NewSocket:=socket(Family,SocketType,Protocol);
            if NewSocket=INVALID_SOCKET then
              Err:=WSAGetLastError
            else
              begin
                Err:=0;
                Handle:=NewSocket;
              end
          end;
        end;
    else
      begin
        ErrorBox('Unhandled WSOCK.VXD call:'+IntToStr(Func));
        Err:=WSAEBADF;
      end;
    end;
  except
    on E: Exception do
      begin
        ErrorBox('Exception in WSOCKVDD:'+E.Message);
        Err:=WSANO_RECOVERY;
      end;
  end;
  setAX(Err);
end;

exports
  VDDInitialize,
  VDDRegisterInit,
  VDDDispatch;

begin
end.
{
  $Log: wsockvdd.pas,v $

  Revision 1.0  1999/11/27 09:46:55  gabor
     Original implementation
  Revision 1.1  1999/12/11 09:46:55  gabor
     Startup fix

}

