{
    $Id: nb30.pas,v 1.0 1999/12/19 11:30:25 gabor Exp $
    This file is part of the Free Sockets Interface
    Copyright (c) 1999 by Berczi Gabor ( e-mail: sting@freemail.hu )

    NetBIOS low-level interface

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
unit NB30;

interface

uses Objects,Types{$ifdef DOS},pmode{$endif};

const
     NCBNAMSZ   = 16;  { NetBIOS name length }
     MAX_LANA   = 254; { valid LAN adapter numbers are 0-254 }

     NB_MAXDGSIZE = 512; { maximum datagram length }

     nb_invalid_name_number = chr($ff);
     nb_invalid_adapter_number = chr($ff);
     nb_invalid_session_number = chr($ff);

     { NetBIOS Command codes }
     nbcCall                    = $10; { open session with another name      }
     nbcListen                  = $11; {*waits for a call                    }
     nbcHangup                  = $12; { ends a session                      }
     nbcSend                    = $14; { send data to a session              }
     nbcRecv                    = $15; {*receive data on a session           }
     nbcRecvAny                 = $16; {*receive data on any session         }
     nbcChainSend               = $17; { send two buffers of data in one cmd }
     nbcDgSend                  = $20; { send a specific datagram            }
     nbcDgRecv                  = $21; {*receive a specific datagram         }
     nbcDgSendBc                = $22; { send a broadcast datagram           }
     nbcDgRecvBc                = $23; {*receive a broadcast datagram        }
     nbcAddName                 = $30; { add unique name to local table      }
     nbcDelName                 = $31; { delete unique name from local table }
     nbcReset                   = $32; { reset adapter, clear local table    }
     nbcAStat                   = $33; { get status of local adapter         }
     nbcSStat                   = $34; { get status of all active sessions   }
     nbcCancel                  = $35; { cancel a not yet completed ncb      }
     nbcAddGrName               = $36; { add group name to local table       }
     nbcEnum                    = $37; { enumerate all local adapters        }
     nbcNCBUnLink               = $70; { used by network software at init.   }
     nbcSendNA                  = $71; { send no ACK                         }
     nbcChainSendNA             = $72; { chained send no ACK                 }
     nbcLANStAlert              = $73; { LAN status alert                    }
     nbcAction                  = $77; {                                     }
     nbcFindName                = $78; { searches for a name on network      }
     nbcTrace                   = $79; { enable/disable ncb tracing          }
     nbcAsynchronous            = $80; { flag! - used for asynch execution   }
     {   only commands marked with '*' can be cancelled with 'cancel' ($35)  }

     { NetBIOS Error codes }
     nrc_GOODRET                = $00; { good return                         }
                            { also returned when ASYNCH request accepted     }
     nrc_BUFLEN                 = $01; { illegal buffer length               }
     nrc_ILLCMD                 = $03; { illegal command                     }
     nrc_CMDTMO                 = $05; { command timed out                   }
     nrc_INCOMP                 = $06; { message incomplete, issue another command}
     nrc_BADDR                  = $07; { illegal buffer address              }
     nrc_SNUMOUT                = $08; { session number out of range         }
     nrc_NORES                  = $09; { no resource available               }
     nrc_SCLOSED                = $0a; { session closed                      }
     nrc_CMDCAN                 = $0b; { command cancelled                   }
     nrc_DUPNAME                = $0d; { duplicate name                      }
     nrc_NAMTFUL                = $0e; { name table full                     }
     nrc_ACTSES                 = $0f; { no deletions, name has active sessions}
     nrc_LOCTFUL                = $11; { local session table full            }
     nrc_REMTFUL                = $12; { remote session table full           }
     nrc_ILLNN                  = $13; { illegal name number                 }
     nrc_NOCALL                 = $14; { no callname                         }
     nrc_NOWILD                 = $15; { cannot put * in NCB_NAME            }
     nrc_INUSE                  = $16; { name in use on remote adapter       }
     nrc_NAMERR                 = $17; { name deleted                        }
     nrc_SABORT                 = $18; { session ended abnormally            }
     nrc_NAMCONF                = $19; { name conflict detected              }
     nrc_IFBUSY                 = $21; { interface busy, IRET before retrying}
     nrc_TOOMANY                = $22; { too many commands outstanding, retry later}
     nrc_BRIDGE                 = $23; { NCB_lana_num field invalid          }
     nrc_CANOCCR                = $24; { command completed while cancel occurring}
     nrc_CANCEL                 = $26; { command not valid to cancel         }
     nrc_DUPENV                 = $30; { name defined by anther local process}
     nrc_ENVNOTDEF              = $34; { environment undefined. RESET required}
     nrc_OSRESNOTAV             = $35; { required OS resources exhausted     }
     nrc_MAXAPPS                = $36; { max number of applications exceeded }
     nrc_NOSAPS                 = $37; { no saps available for netbios       }
     nrc_NORESOURCES            = $38; { requested resources are not available}
     nrc_INVADDRESS             = $39; { invalid ncb address or length > segment}
     nrc_INVDDID                = $3B; { invalid NCB DDID                    }
     nrc_LOCKFAIL               = $3C; { lock of user area failed            }
     nrc_OPENERR                = $3f; { NETBIOS not loaded                  }
     nrc_SYSTEM                 = $40; { system error                        }
     nrc_PENDING                = $ff; { asynchronous command is not yet finished}
     { $40 - $4f  network failure conditions    }
     { $50 - $fe  adapter/interface malfunction }

     { NetBIOS Adapter Type constants }
     TOKENRING                  = $ff;
     ETHERNET                   = $fe;

     { NetBIOS Name entry Status commands }
     REGISTERING                = $00; { add in progress                     }
     REGISTERED                 = $04; { active                              }
     DEREGISTERED               = $05; { delete pending                      }
     DUPLICATE                  = $06; { improper duplicate                  }
     DUPLICATE_DEREG            = $07; { duplicate delete pending            }

     NAME_FLAGS_MASK            = $87;

     GROUP_NAME                 = $80;
     UNIQUE_NAME                = $00;

type
     TNBAdapterNumber = char;
     TNBNameNumber = char;
     TNBSessionNumber = char;
     TNBName = array[0..NCBNAMSZ - 1] of Char;

     PNCB = ^TNCB;

     TNCBPostProc = procedure(P: PNCB);

     TNCB = packed record
       ncb_Command  : char;            { see nbc_XXXX constants              }
       ncb_RetCode  : char;            { see nb_err_XXXX constants           }
       ncb_LSN      : TNBSessionNumber;{ local session number                }
       ncb_Num      : TNBNameNumber;   { name number                         }
       ncb_Buffer   : PChar;           { data buffer pointer                 }
       ncb_Length   : word;            { data buffer size                    }
       ncb_CallName : TNBName;         { (remote) call name                  }
       ncb_Name     : TNBName;         { local name                          }
       ncb_RTO      : byte;            { receive timeout (in 500ms)          }
       ncb_STO      : byte;            { send timeout (in 500ms)             }
       ncb_Post     : TNCBPostProc;    { routine called after completion     }
       ncb_LanA_Num : TNBAdapterNumber;{ adapter id                          }
       ncb_Cmd_CPLT : char;            { completion status ($ff=pending)     }
       ncb_reserve  : array[0..13] of byte;
       { --- non-standard fields --- }
     {$ifdef DOS}
       MagicNo      : longint;
       {$ifdef DPMI}
       MNCB         : MemPtr;
       MData        : MemPtr;
       {$else}
       DataBufSize  : word;
       {$endif}
     {$endif}
     end;

     { Structure returned to the NCB command NCBASTAT is ADAPTER_STATUS followed }
     { by an array of NAME_BUFFER structures.                                    }
     PAdapterStatus = ^TAdapterStatus;
     TAdapterStatus = packed record
       adapter_address   : array[0..5] of Char; { MAC address                }
       rev_major         : Char; { external jumper status / version          }
       reserved0         : Char; { power-on-self-test result code (0)        }
       adapter_type      : Char; { adapter type / software version ver hi    }
       rev_minor         : Char; { software version ver lo                   }
       duration          : Word; { period (in minutes) of the status report  }
       frmr_recv         : Word; { number of receive CRC errors               }
       frmr_xmit         : Word; { number of other receive errors             }
       iframe_recv_err   : Word; { number of transmit collision errors        }
       xmit_aborts       : Word; { number of other transmit errors            }
       xmit_success      : DWORD;{ number of successful transmissions         }
       recv_success      : DWORD;{ number of successful receives              }
       iframe_xmit_err   : Word; { number of transmit retries (collisions)    }
       recv_buff_unavail : Word; { number of packet missed (no recv buffers)  }
       t1_timeouts       : Word;
       ti_timeouts       : Word;
       reserved1         : DWORD;
       free_ncbs         : Word; { number of free NCBs                        }
       max_cfg_ncbs      : Word; { number of NCBs specified in last reset cmd }
       max_ncbs          : Word; { max. no of NCBs that can be specfd at RESET}
       xmit_buf_unavail  : Word;
       max_dgram_size    : Word;
       pending_sess      : Word; { number of active or pending sessions       }
       max_cfg_sess      : Word; { number of poss. session spec. in last RESET}
       max_sess          : Word; { max. no of session that can be spec. at RST}
       max_sess_pkt_size : Word; { maximum physical (!) packet size supported }
       name_count        : Word; { number of names in local name table        }
     end;

     PNameBuffer = ^TNameBuffer;
     TNameBuffer = packed record
       name       : TNBName;
       name_num   : TNBNameNumber;
       name_flags : Char;
     end;

     { Structure returned to the NCB command NCBSSTAT is SESSION_HEADER followed }
     { by an array of SESSION_BUFFER structures. If the NCB_NAME starts with an  }
     { asterisk then an array of these structures is returned containing the     }
     { status for all names.                                                     }
     PSessionHeader = ^TSessionHeader;
     TSessionHeader = packed record
       sess_name          : Char;
       num_sess           : Char;
       rcv_dg_outstanding : Char;
       rcv_any_outstanding: Char;
     end;

     PSessionBuffer = ^TSessionBuffer;
     TSessionBuffer = packed record
       lsn               : Char;
       state             : Char;
       local_name        : TNBName;
       remote_name       : TNBName;
       rcvs_outstanding  : Char;
       sends_outstanding : Char;
     end;

     { Structure returned to the NCB command NCBENUM.                            }
     { On a system containing lana's 0, 2 and 3, a structure with                }
     { length =3, lana[0]=0, lana[1]=2 and lana[2]=3 will be returned.}
     PLanaEnum = ^TLanaEnum;
     TLanaEnum = packed record
       length : Char;         {  Number of valid entries in lana[]     }
       lana   : array[0..MAX_LANA] of Char;
     end;

     { Structure returned to the NCB command NCBFINDNAME is FIND_NAME_HEADER followed }
     { by an array of FIND_NAME_BUFFER structures.                                    }
     PFindNameHeader = ^TFindNameHeader;
     TFindNameHeader = packed record
       node_count   : Word;
       reserved     : Char;
       unique_group : Char;
     end;

     PFindNameBuffer = ^TFindNameBuffer;
     TFindNameBuffer = packed record
       length           : Char;
       access_control   : Char;
       frame_control    : Char;
       destination_addr : array[0..5] of Char;
       source_addr      : array[0..5] of Char;
       routing_info     : array[0..17] of Char;
     end;

     { Structure provided with NCBACTION. The purpose of NCBACTION is to provide }
     { transport specific extensions to netbios.                                 }
     PActionHeader = ^TActionHeader;
     TActionHeader = packed record
       transport_id : Longint;
       action_code  : Word;
       reserved     : Word;
     end;


function Netbios(NCB: PNCB): Char;

function NbIsNCBBusy(NCB: PNCB): boolean;

{
  these additional routines are required to create programs that must be able
  to run under DOS in protected mode, too.if you do not want to create a DOS
  version of your program that runs in DPMI, then you won't need to use them.
}

function  NbNewNCB: PNCB;
function  NbNewBuffer(P: PNCB; Size: word): boolean;
function  NbDataToBuffer(P: PNCB; const Data; DataSize: word): boolean;
function  NbDataFromBuffer(P: PNCB; DataSize: word; var Data): boolean;
function  NbFreeBuffer(P: PNCB): boolean;
procedure NbFreeNCB(P: PNCB);
function  NbSetNCBPostHandler(P: PNCB; NBPostHandler: TNCBPostProc): boolean;
function  NbGetNCBAddr(P: PNCB): pointer;

implementation

{$ifdef DOS}
  {$I NBDOS.INC}
{$endif}
{$ifdef Win32}
  {$I NBWIN32.INC}
{$endif}
{$ifdef Linux}
  {$I NBLINUX.INC}
{$endif}

function NbIsNCBBusy(NCB: PNCB): boolean;
begin
  NbIsNCBBusy:=Assigned(NCB) and (NCB^.ncb_RetCode=chr(nrc_PENDING));
end;

END.
{
  $Log: nb30.pas,v $

  Revision 1.0  1999/12/19 11:30:25  gabor
     Original implementation

}
