{
      qos.h - QoS definitions for NDIS components.

      This module defines the Quality of Service structures and types used
      by Winsock applications.
}

type
     uint32 = dword;
  { }
  {  Definitions for Service Type for each direction of data flow. }
  { }

     SERVICETYPE = uint32;
  { No data in this direction }

  const
     SERVICETYPE_NOTRAFFIC            = $00000000;
     SERVICETYPE_BESTEFFORT           = $00000001;{ Best Effort }
     SERVICETYPE_CONTROLLEDLOAD       = $00000002;{ Controlled Load }
     SERVICETYPE_GUARANTEED           = $00000003;{ Guaranteed }
     SERVICETYPE_NETWORK_UNAVAILABLE  = $00000004;{ Used to notify change to user }
     SERVICETYPE_GENERAL_INFORMATION  = $00000005;{ corresponds to "General Parameters" defined by IntServ }
     SERVICETYPE_NOCHANGE             = $00000006;{ flow spec contains no change from any previous one }
     { to turn on immediate traffic control, OR ( | ) this flag with the ServiceType field in teh FLOWSPEC }
     SERVICE_IMMEDIATE_TRAFFIC_CONTROL= $80000000;

  {  Flow Specifications for each direction of data flow. }
  { In Bytes/sec  }
  { In Bytes  }
  { In Bytes/sec  }
  { In microseconds  }
  { In microseconds  }
  { In Bytes  }
  { In Bytes  }
  (* far ignored *)

type
  TFLOWSPEC = packed record
    TokenRate : uint32;
    TokenBucketSize : uint32;
    PeakBandwidth : uint32;
    Latency : uint32;
    DelayVariation : uint32;
    ServiceType : SERVICETYPE;
    MaxSduSize : uint32;
    MinimumPolicedSize : uint32;
  end;
  PFLOWSPEC = ^TFLOWSPEC;

