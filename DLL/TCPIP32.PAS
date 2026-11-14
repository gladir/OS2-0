{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque TCPIP32.DLL de OS/2-0 : pile TCP/IP (ARP, IP,
                ICMP, UDP, DHCP, DNS, TCP) et interface des sockets.
}

Library TCPIP32;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC TCPIP32.PAS   (produit TCPIP32.DLL)

  Pile TCP/IP d'OS/2-0 (le "TCP/IP" d'OS/2 Warp : interface des sockets
  de SO32DLL.DLL et TCP32DLL.DLL), sur une carte Ethernet :
    pilote : variable NETDRIVER de CONFIG.SYS (E1000, PCNET ou NONE), sinon
             le premier qui trouve sa carte (E1000.DLL : Intel PRO/1000,
             carte par defaut de VirtualBox ; PCNET.DLL : AMD PCnet) ;
    adresse : DHCP (au premier usage), ou SET IP_ADDRESS=a.b.c.d avec
             IP_NETMASK, IP_GATEWAY et IP_DNS (adresse fixe) ;
    ARP (cache de 16 adresses), IPv4 (sans fragmentation), ICMP (reponse
    aux echos ; sockets bruts pour PING), UDP, DNS (gethostbyname), TCP
    client (ouverture en trois temps, option MSS, envoi segment par
    segment avec accuse de reception et reemission, reception en ordre
    dans un tampon de 64 Ko par socket, fenetre annoncee, fermeture FIN,
    RST).
  La pile n'utilise pas les interruptions : les trames recues sont lues
  dans l'anneau de la carte chaque fois qu'un programme attend (connect,
  recv, recvfrom...).

  Interface (comme la bibliotheque des sockets d'OS/2, adresses et ports
  dans l'ordre du reseau) : sock_init, socket (AF_INET ; SOCK_STREAM,
  SOCK_DGRAM, SOCK_RAW + IPPROTO_ICMP), bind, connect, send, recv, sendto,
  recvfrom, soclose, shutdown, sock_errno, gethostbyname, gethostid,
  inet_addr ; points d'entree internes TCPIPINFO (etat de l'interface
  lan0 : IFCONFIG, gestionnaire de peripheriques) et TCPIPRENEW (refaire
  la configuration). Codes d'erreur (sock_errno) : SOCBASEERR (10000) +
  code BSD. }

Const
  MAXS = 16;
  RXCAP = 65536;
  MSS = 1400;
  SOCK_STREAM = 1; SOCK_DGRAM = 2; SOCK_RAW = 3;
  T_TCP = 1; T_UDP = 2; T_RAW = 3;
  { etats TCP }
  TS_CLOSED = 0; TS_SYNSENT = 1; TS_ESTAB = 2; TS_FINWAIT = 3; TS_CLOSEWAIT = 4; TS_RESET = 5;
  SOCEINVAL = 10022; SOCEMFILE = 10024; SOCENOTSOCK = 10038; SOCENETDOWN = 10050; SOCENOBUFS = 10055;
  SOCENOTCONN = 10057; SOCETIMEDOUT = 10060; SOCECONNREFUSED = 10061; SOCECONNRESET = 10054;
  SOCEHOSTUNREACH = 10065; SOCEADDRINUSE = 10048;

Var
  { pilote de la carte }
  DrvTried, DrvFn : LongInt;
  DrvName, CardName : String;
  Mac : Array[0..5] Of Byte;
  NPk : Array[0..7] Of LongInt;
  { configuration }
  Ready, Dhcp : LongInt;
  MyIp, Mask, Gw, Dns, DhcpSrv, Lease : LongInt;
  IpId, NextPort, Errno, HErr : LongInt;
  RxPkts, TxPkts : LongInt;
  { trames }
  TxF, RxF : Array[0..1599] Of Byte;
  Seg : Array[0..1599] Of Byte;
  { cache ARP }
  ArpIp : Array[0..15] Of LongInt;
  ArpMac : Array[0..95] Of Byte;
  ArpNext : LongInt;
  { sockets }
  SType, SState, SLPort, SRIp, SRPort, SSeq, SUna, SAck, SBuf, SHead, SLen, SPWin, SBound : Array[0..MAXS - 1] Of LongInt;
  { gethostbyname }
  HostEnt : Array[0..7] Of LongInt;
  HostAddr : Array[0..1] Of LongInt;
  HostList : Array[0..1] Of LongInt;
  HostName : Array[0..255] Of Byte;
  NameZ, FailBuf : Array[0..259] Of Byte;
  DnsAns : LongInt;
  Dummy : LongInt;

Function DosLoadModule(PObj, Cb, PName, PH : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeModule(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeMem(Pb : LongInt) : LongInt; External 'DOSCALLS';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Function RdB(A : LongInt) : LongInt;
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrB(A, V : LongInt);
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(A);
  Q^ := V And 255;
End;

Function RdL(A : LongInt) : LongInt;
Type PL = ^LongInt;
Var Q : PL;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Procedure WrL(A, V : LongInt);
Type PL = ^LongInt;
Var Q : PL;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

{ entiers dans l'ordre du reseau (gros-boutiste) }
Function Get16(A : LongInt) : LongInt;
Begin
  Get16 := (RdB(A) Shl 8) Or RdB(A + 1);
End;

Function Get32(A : LongInt) : LongInt;
Begin
  Get32 := (RdB(A) Shl 24) Or (RdB(A + 1) Shl 16) Or (RdB(A + 2) Shl 8) Or RdB(A + 3);
End;

Procedure Put16(A, V : LongInt);
Begin
  WrB(A, V Shr 8); WrB(A + 1, V);
End;

Procedure Put32(A, V : LongInt);
Begin
  WrB(A, V Shr 24); WrB(A + 1, V Shr 16); WrB(A + 2, V Shr 8); WrB(A + 3, V);
End;

{ adresse en memoire (ordre du reseau) <-> entier a.b.c.d = a shl 24... }
Function Swap32(V : LongInt) : LongInt;
Begin
  Swap32 := ((V And 255) Shl 24) Or (((V Shr 8) And 255) Shl 16) Or (((V Shr 16) And 255) Shl 8) Or
            ((V Shr 24) And 255);
End;

Function Swap16(V : LongInt) : LongInt;
Begin
  Swap16 := ((V And 255) Shl 8) Or ((V Shr 8) And 255);
End;

Procedure MoveMem(S, D, N : LongInt);
Begin
  If N <= 0 Then Exit;
  asm
    push esi
    push edi
    mov esi,S
    mov edi,D
    mov ecx,N
    cld
    rep movsb
    pop edi
    pop esi
  end;
End;

Procedure ZeroMem(D, N : LongInt);
Var K : LongInt;
Begin
  For K := 0 To N - 1 Do WrB(D + K, 0);
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@NameZ), S);
  Z := LongInt(@NameZ);
End;

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  K := 0;
  While (A <> 0) And (K < 255) And (RdB(A + K) <> 0) Do
  Begin
    S := S + Chr(RdB(A + K));
    Inc(K);
  End;
  GetZ := S;
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function Env(Name : String) : String;
Var P : LongInt;
Begin
  P := 0;
  If DosScanEnv(Z(Name), LongInt(@P)) = 0 Then Env := GetZ(P) Else Env := '';
End;

{ "a.b.c.d" -> entier (0 : invalide) }
Function ParseIp(S : String) : LongInt;
Var K, V, N, R : LongInt;
Begin
  ParseIp := 0;
  R := 0; N := 0; V := -1;
  S := S + '.';
  For K := 1 To Length(S) Do
    If (S[K] >= '0') And (S[K] <= '9') Then
    Begin
      If V < 0 Then V := 0;
      V := V * 10 + Ord(S[K]) - 48;
      If V > 255 Then Exit;
    End
    Else If S[K] = '.' Then
    Begin
      If V < 0 Then Exit;
      R := (R Shl 8) Or V;
      Inc(N); V := -1;
    End
    Else Exit;
  If N = 4 Then ParseIp := R;
End;

Function IpStr(V : LongInt) : String;
Begin
  IpStr := IStr((V Shr 24) And 255) + '.' + IStr((V Shr 16) And 255) + '.' + IStr((V Shr 8) And 255) + '.' +
           IStr(V And 255);
End;

Function Hex2(V : LongInt) : String;
Var A, B : LongInt;
Begin
  A := (V Shr 4) And 15; B := V And 15;
  If A < 10 Then A := A + 48 Else A := A + 55;
  If B < 10 Then B := B + 48 Else B := B + 55;
  Hex2 := Chr(A) + Chr(B);
End;

{ somme de controle d'Internet (complement a un) }
Function Sum16(A, N, Init : LongInt) : LongInt;
Var S, K : LongInt;
Begin
  S := Init;
  K := 0;
  While K + 1 < N Do
  Begin
    S := S + Get16(A + K);
    K := K + 2;
  End;
  If K < N Then S := S + (RdB(A + K) Shl 8);
  Sum16 := S;
End;

Function Fold(S : LongInt) : LongInt;
Begin
  While (S Shr 16) <> 0 Do S := (S And $FFFF) + ((S Shr 16) And $FFFF);
  Fold := (Not S) And $FFFF;
End;

Function CallPtr1(F, A1 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,4
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPtr1 := R;
End;

{ ==================================================================== }
{ Pilote de la carte                                                    }
{ ==================================================================== }

Function TryDriver(N : String) : Boolean;
Var H, F, K : LongInt;
Begin
  TryDriver := False;
  H := 0; F := 0;
  If DosLoadModule(LongInt(@FailBuf), 128, Z(N), LongInt(@H)) <> 0 Then Exit;
  If (DosQueryProcAddr(H, 1, 0, LongInt(@F)) <> 0) Or (F = 0) Then Exit;
  NPk[0] := 1; NPk[1] := 0;
  If (CallPtr1(F, LongInt(@NPk)) = 0) And (NPk[1] = 0) Then
  Begin
    DrvFn := F;
    For K := 0 To 5 Do Mac[K] := RdB(NPk[2] + K);
    CardName := GetZ(NPk[3]);
    DrvName := UpStr(N);
    TryDriver := True;
  End
  Else Dummy := DosFreeModule(H);
End;

Function DriverReady : Boolean;
Var S : String;
Begin
  If DrvTried = 0 Then
  Begin
    DrvTried := 1;
    S := UpStr(Env('NETDRIVER'));
    If Pos('.', S) > 0 Then S := Copy(S, 1, Pos('.', S) - 1);
    If S = 'NONE' Then
    Else If S <> '' Then Dummy := Ord(TryDriver(S))
    Else If Not TryDriver('E1000') Then Dummy := Ord(TryDriver('PCNET'));
  End;
  DriverReady := DrvFn <> 0;
End;

Procedure RawSend(A, N : LongInt);
Begin
  NPk[0] := 2; NPk[2] := A; NPk[3] := N;
  If CallPtr1(DrvFn, LongInt(@NPk)) = 0 Then Inc(TxPkts);
End;

Function RawRecv : LongInt;
Begin
  NPk[0] := 3; NPk[2] := LongInt(@RxF); NPk[3] := 1600; NPk[4] := 0;
  Dummy := CallPtr1(DrvFn, LongInt(@NPk));
  RawRecv := NPk[4];
End;

Function LinkState : LongInt;
Begin
  NPk[0] := 4; NPk[2] := 0;
  Dummy := CallPtr1(DrvFn, LongInt(@NPk));
  LinkState := NPk[2];
End;

{ ==================================================================== }
{ Ethernet et ARP                                                       }
{ ==================================================================== }

Procedure EthHeader(Dst : LongInt; Typ : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 5 Do
  Begin
    TxF[K] := RdB(Dst + K); TxF[6 + K] := Mac[K];
  End;
  TxF[12] := Typ Shr 8; TxF[13] := Typ And 255;
End;

Procedure ArpLearn(Ip, PMac : LongInt);
Var K, I : LongInt;
Begin
  If Ip = 0 Then Exit;
  I := -1;
  For K := 0 To 15 Do
    If ArpIp[K] = Ip Then I := K;
  If I < 0 Then
  Begin
    I := ArpNext;
    ArpNext := (ArpNext + 1) And 15;
  End;
  ArpIp[I] := Ip;
  For K := 0 To 5 Do ArpMac[I * 6 + K] := RdB(PMac + K);
End;

Function ArpFind(Ip : LongInt) : LongInt;
Var K : LongInt;
Begin
  ArpFind := -1;
  For K := 0 To 15 Do
    If ArpIp[K] = Ip Then ArpFind := K;
End;

Procedure ArpSend(Op, TIp, TMac : LongInt);
Var Bc : Array[0..5] Of Byte; K : LongInt;
Begin
  For K := 0 To 5 Do Bc[K] := 255;
  If Op = 1 Then EthHeader(LongInt(@Bc), $0806) Else EthHeader(TMac, $0806);
  Put16(LongInt(@TxF) + 14, 1); Put16(LongInt(@TxF) + 16, $0800);
  TxF[18] := 6; TxF[19] := 4; Put16(LongInt(@TxF) + 20, Op);
  For K := 0 To 5 Do TxF[22 + K] := Mac[K];
  Put32(LongInt(@TxF) + 28, MyIp);
  For K := 0 To 5 Do
    If Op = 1 Then TxF[32 + K] := 0 Else TxF[32 + K] := RdB(TMac + K);
  Put32(LongInt(@TxF) + 38, TIp);
  RawSend(LongInt(@TxF), 42);
End;

{ ==================================================================== }
{ Reception                                                             }
{ ==================================================================== }

Procedure TcpIn(Ip, Th, N, Src : LongInt); Forward;
Procedure DhcpIn(A, N : LongInt); Forward;

{ file d'un socket : enregistrement [longueur 2][adresse 4][port 2][donnees] }
Procedure QueueDgram(S, Src, SPort, A, N : LongInt);
Var Need, P, K : LongInt;
Begin
  Need := N + 8;
  If SLen[S] + Need > RXCAP Then Exit;
  P := (SHead[S] + SLen[S]) Mod RXCAP;
  { les enregistrements ne sont pas coupes : recommencer au debut }
  If P + Need > RXCAP Then
  Begin
    If SLen[S] > 0 Then Exit;
    SHead[S] := 0; P := 0;
  End;
  Put16(SBuf[S] + P, N); Put32(SBuf[S] + P + 2, Src); Put16(SBuf[S] + P + 6, SPort);
  MoveMem(A, SBuf[S] + P + 8, N);
  SLen[S] := SLen[S] + Need;
  K := 0;
End;

Procedure IpIn(A, N : LongInt);
Var Ihl, Tot, Proto, Src, Dst, P, L, K, S, Typ, SPort, DPort : LongInt;
Begin
  If (RdB(A) Shr 4) <> 4 Then Exit;
  Ihl := (RdB(A) And 15) * 4;
  Tot := Get16(A + 2);
  If (Tot > N) Or (Tot < Ihl) Then Exit;
  Proto := RdB(A + 9);
  Src := Get32(A + 12); Dst := Get32(A + 16);
  If (Dst <> MyIp) And (Dst <> -1) And (MyIp <> 0) And (Dst <> (MyIp Or Not Mask)) Then Exit;
  P := A + Ihl; L := Tot - Ihl;
  Case Proto Of
    1 :
      Begin
        Typ := RdB(P);
        { echo demande : reponse }
        If (Typ = 8) And (Dst = MyIp) And (L <= 1400) Then
        Begin
          MoveMem(A, LongInt(@Seg), Tot);
          { adresses echangees, type 0 }
          Put32(LongInt(@Seg) + 12, MyIp); Put32(LongInt(@Seg) + 16, Src);
          Seg[Ihl] := 0;
          Put16(LongInt(@Seg) + Ihl + 2, 0);
          Put16(LongInt(@Seg) + Ihl + 2, Fold(Sum16(LongInt(@Seg) + Ihl, L, 0)));
          Put16(LongInt(@Seg) + 10, 0);
          Put16(LongInt(@Seg) + 10, Fold(Sum16(LongInt(@Seg), Ihl, 0)));
          K := ArpFind(Src);
          If K >= 0 Then
          Begin
            EthHeader(LongInt(@ArpMac) + K * 6, $0800);
            MoveMem(LongInt(@Seg), LongInt(@TxF) + 14, Tot);
            RawSend(LongInt(@TxF), 14 + Tot);
          End;
        End;
        { sockets bruts ICMP : le paquet IP entier }
        For S := 0 To MAXS - 1 Do
          If SType[S] = T_RAW Then QueueDgram(S, Src, 0, A, Tot);
      End;
    17 :
      Begin
        SPort := Get16(P); DPort := Get16(P + 2);
        If DPort = 68 Then DhcpIn(P + 8, L - 8)
        Else
          For S := 0 To MAXS - 1 Do
            If (SType[S] = T_UDP) And (SLPort[S] = DPort) Then QueueDgram(S, Src, SPort, P + 8, Get16(P + 4) - 8);
      End;
    6 : TcpIn(A, P, L, Src);
  End;
End;

Procedure EthIn(N : LongInt);
Var Typ, Op, SIp, TIp : LongInt;
Begin
  If N < 14 Then Exit;
  Inc(RxPkts);
  Typ := Get16(LongInt(@RxF) + 12);
  If Typ = $0806 Then
  Begin
    Op := Get16(LongInt(@RxF) + 20);
    SIp := Get32(LongInt(@RxF) + 28); TIp := Get32(LongInt(@RxF) + 38);
    If (MyIp <> 0) And (TIp = MyIp) Then
    Begin
      ArpLearn(SIp, LongInt(@RxF) + 22);
      If Op = 1 Then ArpSend(2, SIp, LongInt(@RxF) + 22);
    End
    Else If (Op = 2) Then ArpLearn(SIp, LongInt(@RxF) + 22);
  End
  Else If Typ = $0800 Then IpIn(LongInt(@RxF) + 14, N - 14);
End;

{ lire les trames recues }
Procedure NetPoll;
Var K, N : LongInt;
Begin
  If DrvFn = 0 Then Exit;
  K := 0;
  Repeat
    N := RawRecv;
    If N > 0 Then EthIn(N);
    Inc(K);
  Until (N = 0) Or (K > 64);
End;

Procedure Idle;
Begin
  NetPoll;
  Dummy := DosSleep(5);
  NetPoll;
End;

{ ==================================================================== }
{ Emission IP                                                           }
{ ==================================================================== }

{ adresse MAC du prochain saut (ARP) ; faux : injoignable }
Function Resolve(Ip : LongInt; Var M : LongInt) : Boolean;
Var Hop, K, T, Try_ : LongInt;
Begin
  Resolve := False;
  If (Ip = -1) Or ((Mask <> 0) And ((Ip Or Mask) = -1) And ((Ip And Not Mask) = Not Mask)) Then
  Begin
    M := -1;
    Resolve := True;
    Exit;
  End;
  If ((Ip And Mask) = (MyIp And Mask)) Or (Gw = 0) Then Hop := Ip Else Hop := Gw;
  For Try_ := 1 To 4 Do
  Begin
    K := ArpFind(Hop);
    If K >= 0 Then
    Begin
      M := K;
      Resolve := True;
      Exit;
    End;
    ArpSend(1, Hop, 0);
    T := KTicks;
    While (KTicks - T < 500) And (ArpFind(Hop) < 0) Do Idle;
  End;
  K := ArpFind(Hop);
  If K >= 0 Then
  Begin
    M := K;
    Resolve := True;
  End;
End;

{ envoyer un paquet IP (Proto) de N octets de donnees en Data }
Function IpSend(Dst, Proto, Data, N : LongInt) : Boolean;
Var M, K : LongInt; Bc : Array[0..5] Of Byte;
Begin
  IpSend := False;
  If Not Resolve(Dst, M) Then Exit;
  If M < 0 Then
  Begin
    For K := 0 To 5 Do Bc[K] := 255;
    EthHeader(LongInt(@Bc), $0800);
  End
  Else EthHeader(LongInt(@ArpMac) + M * 6, $0800);
  TxF[14] := $45; TxF[15] := 0;
  Put16(LongInt(@TxF) + 16, 20 + N);
  Inc(IpId);
  Put16(LongInt(@TxF) + 18, IpId And $FFFF);
  Put16(LongInt(@TxF) + 20, $4000);
  TxF[22] := 64; TxF[23] := Proto;
  Put16(LongInt(@TxF) + 24, 0);
  Put32(LongInt(@TxF) + 26, MyIp); Put32(LongInt(@TxF) + 30, Dst);
  Put16(LongInt(@TxF) + 24, Fold(Sum16(LongInt(@TxF) + 14, 20, 0)));
  MoveMem(Data, LongInt(@TxF) + 34, N);
  RawSend(LongInt(@TxF), 34 + N);
  IpSend := True;
End;

{ UDP (somme de controle 0 : permise en IPv4) }
Function UdpSend(Dst, SPort, DPort, Data, N : LongInt) : Boolean;
Begin
  Put16(LongInt(@Seg), SPort); Put16(LongInt(@Seg) + 2, DPort);
  Put16(LongInt(@Seg) + 4, 8 + N); Put16(LongInt(@Seg) + 6, 0);
  MoveMem(Data, LongInt(@Seg) + 8, N);
  UdpSend := IpSend(Dst, 17, LongInt(@Seg), 8 + N);
End;

{ ==================================================================== }
{ DHCP                                                                  }
{ ==================================================================== }

Var
  DhcpXid, DhcpGot, DhcpOffer : LongInt;
  DhcpPkt : Array[0..599] Of Byte;

Procedure DhcpBuild(MsgType : LongInt);
Var A, K, O : LongInt;
Begin
  A := LongInt(@DhcpPkt);
  ZeroMem(A, 600);
  DhcpPkt[0] := 1; DhcpPkt[1] := 1; DhcpPkt[2] := 6;
  Put32(A + 4, DhcpXid);
  Put16(A + 10, $8000);                                { reponse en diffusion }
  For K := 0 To 5 Do DhcpPkt[28 + K] := Mac[K];
  Put32(A + 236, $63825363);
  O := 240;
  DhcpPkt[O] := 53; DhcpPkt[O + 1] := 1; DhcpPkt[O + 2] := MsgType; O := O + 3;
  If MsgType = 3 Then
  Begin
    DhcpPkt[O] := 50; DhcpPkt[O + 1] := 4; Put32(A + O + 2, DhcpOffer); O := O + 6;
    DhcpPkt[O] := 54; DhcpPkt[O + 1] := 4; Put32(A + O + 2, DhcpSrv); O := O + 6;
  End;
  DhcpPkt[O] := 12; DhcpPkt[O + 1] := 5;
  DhcpPkt[O + 2] := Ord('O'); DhcpPkt[O + 3] := Ord('S'); DhcpPkt[O + 4] := Ord('2'); DhcpPkt[O + 5] := Ord('-');
  DhcpPkt[O + 6] := Ord('0'); O := O + 7;
  DhcpPkt[O] := 55; DhcpPkt[O + 1] := 4; DhcpPkt[O + 2] := 1; DhcpPkt[O + 3] := 3; DhcpPkt[O + 4] := 6;
  DhcpPkt[O + 5] := 15; O := O + 6;
  DhcpPkt[O] := 255;
End;

Procedure DhcpIn(A, N : LongInt);
Var O, Typ, Len, Sm, Rt, Dn, Sv, Ls : LongInt;
Begin
  If (N < 244) Or (RdB(A) <> 2) Or (Get32(A + 4) <> DhcpXid) Or (Get32(A + 236) <> $63825363) Then Exit;
  Typ := 0; Sm := 0; Rt := 0; Dn := 0; Sv := 0; Ls := 0;
  O := 240;
  While (O < N) And (RdB(A + O) <> 255) Do
  Begin
    If RdB(A + O) = 0 Then Inc(O)
    Else
    Begin
      Len := RdB(A + O + 1);
      Case RdB(A + O) Of
        53 : Typ := RdB(A + O + 2);
        1 : Sm := Get32(A + O + 2);
        3 : Rt := Get32(A + O + 2);
        6 : Dn := Get32(A + O + 2);
        54 : Sv := Get32(A + O + 2);
        51 : Ls := Get32(A + O + 2);
      End;
      O := O + 2 + Len;
    End;
  End;
  If (Typ = 2) And (DhcpGot = 0) Then
  Begin
    DhcpOffer := Get32(A + 16); DhcpSrv := Sv;
    DhcpGot := 1;
  End
  Else If (Typ = 5) And (DhcpGot = 1) Then
  Begin
    MyIp := Get32(A + 16);
    Mask := Sm; Gw := Rt; Dns := Dn; Lease := Ls;
    If Mask = 0 Then Mask := -256;
    DhcpGot := 2;
  End
  Else If Typ = 6 Then DhcpGot := 3;
End;

Function DhcpRun : Boolean;
Var Try_, T : LongInt;
Begin
  DhcpRun := False;
  MyIp := 0; Mask := 0; Gw := 0;
  For Try_ := 1 To 4 Do
  Begin
    DhcpXid := KTicks * 2654435 + Try_ * 7919 + Mac[5];
    DhcpGot := 0;
    DhcpBuild(1);
    Dummy := Ord(UdpSend(-1, 68, 67, LongInt(@DhcpPkt), 300));
    T := KTicks;
    While (DhcpGot = 0) And (KTicks - T < 2000) Do Idle;
    If DhcpGot = 1 Then
    Begin
      DhcpBuild(3);
      Dummy := Ord(UdpSend(-1, 68, 67, LongInt(@DhcpPkt), 300));
      T := KTicks;
      While (DhcpGot = 1) And (KTicks - T < 2000) Do Idle;
      If DhcpGot = 2 Then
      Begin
        DhcpRun := True;
        Exit;
      End;
    End;
  End;
End;

{ configuration de l'interface (au premier usage) }
Function NetReady : Boolean;
Var S : String; K : LongInt;
Begin
  If Ready = 0 Then
  Begin
    Ready := -1;
    If DriverReady Then
    Begin
      For K := 0 To 15 Do ArpIp[K] := 0;
      S := Env('IP_ADDRESS');
      If (S <> '') And (UpStr(S) <> 'DHCP') And (ParseIp(S) <> 0) Then
      Begin
        Dhcp := 0;
        MyIp := ParseIp(S);
        Mask := ParseIp(Env('IP_NETMASK'));
        If Mask = 0 Then Mask := -256;
        Gw := ParseIp(Env('IP_GATEWAY'));
        Dns := ParseIp(Env('IP_DNS'));
        Ready := 1;
      End
      Else
      Begin
        Dhcp := 1;
        If DhcpRun Then Ready := 1;
      End;
      If (Ready = 1) And (Env('IP_DNS') <> '') And (ParseIp(Env('IP_DNS')) <> 0) Then Dns := ParseIp(Env('IP_DNS'));
    End;
  End;
  NetReady := Ready = 1;
End;

{ ==================================================================== }
{ TCP                                                                   }
{ ==================================================================== }

Function SeqLess(A, B : LongInt) : Boolean;
Begin
  SeqLess := (A - B) < 0;
End;

{ espace libre du tampon de reception }
Function RxFree(S : LongInt) : LongInt;
Begin
  RxFree := RXCAP - SLen[S];
End;

Procedure TcpSend(S, Flags, Data, N : LongInt);
Var Hl, Sum, Win : LongInt; Ph : Array[0..11] Of Byte;
Begin
  If (Flags And 2) <> 0 Then Hl := 24 Else Hl := 20;
  Put16(LongInt(@Seg), SLPort[S]); Put16(LongInt(@Seg) + 2, SRPort[S]);
  Put32(LongInt(@Seg) + 4, SSeq[S]); Put32(LongInt(@Seg) + 8, SAck[S]);
  Seg[12] := (Hl Div 4) Shl 4; Seg[13] := Flags;
  Win := RxFree(S);
  If Win > 65535 Then Win := 65535;
  Put16(LongInt(@Seg) + 14, Win);
  Put16(LongInt(@Seg) + 16, 0); Put16(LongInt(@Seg) + 18, 0);
  If Hl = 24 Then
  Begin
    Seg[20] := 2; Seg[21] := 4; Put16(LongInt(@Seg) + 22, 1460);
  End;
  MoveMem(Data, LongInt(@Seg) + Hl, N);
  { pseudo-en-tete }
  Put32(LongInt(@Ph), MyIp); Put32(LongInt(@Ph) + 4, SRIp[S]);
  Ph[8] := 0; Ph[9] := 6; Put16(LongInt(@Ph) + 10, Hl + N);
  Sum := Sum16(LongInt(@Ph), 12, 0);
  Put16(LongInt(@Seg) + 16, Fold(Sum16(LongInt(@Seg), Hl + N, Sum)));
  Dummy := Ord(IpSend(SRIp[S], 6, LongInt(@Seg), Hl + N));
End;

Procedure TcpIn(Ip, Th, N, Src : LongInt);
Var S, K, SPort, DPort, Sq, Ak, Fl, Off, DLen, D, Take, P, Part : LongInt;
Begin
  If N < 20 Then Exit;
  SPort := Get16(Th); DPort := Get16(Th + 2);
  Sq := Get32(Th + 4); Ak := Get32(Th + 8);
  Off := (RdB(Th + 12) Shr 4) * 4; Fl := RdB(Th + 13);
  DLen := N - Off;
  S := -1;
  For K := 0 To MAXS - 1 Do
    If (SType[K] = T_TCP) And (SLPort[K] = DPort) And (SRPort[K] = SPort) And (SRIp[K] = Src) And
       (SState[K] <> TS_CLOSED) Then S := K;
  If S < 0 Then Exit;
  If (Fl And 4) <> 0 Then
  Begin
    SState[S] := TS_RESET;
    Exit;
  End;
  If SState[S] = TS_SYNSENT Then
  Begin
    If ((Fl And $12) = $12) And (Ak = SSeq[S]) Then
    Begin
      SAck[S] := Sq + 1; SUna[S] := Ak;
      SPWin[S] := Get16(Th + 14);
      SState[S] := TS_ESTAB;
      TcpSend(S, $10, 0, 0);
    End;
    Exit;
  End;
  If (Fl And $10) <> 0 Then
  Begin
    If SeqLess(SUna[S], Ak) And Not SeqLess(SSeq[S], Ak) Then SUna[S] := Ak;
    SPWin[S] := Get16(Th + 14);
  End;
  { donnees en ordre seulement (les autres seront reemises) }
  If DLen > 0 Then
  Begin
    If Sq = SAck[S] Then
    Begin
      Take := DLen;
      If Take > RxFree(S) Then Take := RxFree(S);
      D := Th + Off;
      P := (SHead[S] + SLen[S]) Mod RXCAP;
      Part := Take;
      If P + Part > RXCAP Then Part := RXCAP - P;
      MoveMem(D, SBuf[S] + P, Part);
      MoveMem(D + Part, SBuf[S], Take - Part);
      SLen[S] := SLen[S] + Take;
      SAck[S] := SAck[S] + Take;
      If Take < DLen Then Fl := Fl And Not 1;
    End;
    TcpSend(S, $10, 0, 0);
  End;
  If ((Fl And 1) <> 0) And (Sq + DLen = SAck[S]) Then
  Begin
    SAck[S] := SAck[S] + 1;
    If SState[S] = TS_FINWAIT Then SState[S] := TS_CLOSED Else SState[S] := TS_CLOSEWAIT;
    TcpSend(S, $10, 0, 0);
  End;
End;

{ ==================================================================== }
{ Sockets                                                               }
{ ==================================================================== }

Function SockOf(D : LongInt) : LongInt;
Begin
  If (D < 3) Or (D >= 3 + MAXS) Or (SType[D - 3] = 0) Then
  Begin
    Errno := SOCENOTSOCK;
    SockOf := -1;
  End
  Else SockOf := D - 3;
End;

Function NewPort : LongInt;
Begin
  Inc(NextPort);
  If NextPort > 60000 Then NextPort := 1025;
  NewPort := NextPort;
End;

{ adresse d'une structure sockaddr_in : famille (16 bits, ou longueur et
  famille de 8 bits), port, adresse }
Procedure SockAddr(P : LongInt; Var Ip, Port : LongInt);
Begin
  Port := Get16(P + 2);
  Ip := Get32(P + 4);
End;

Procedure PutSockAddr(P, Ip, Port : LongInt);
Begin
  If P = 0 Then Exit;
  WrB(P, 16); WrB(P + 1, 2);
  Put16(P + 2, Port); Put32(P + 4, Ip);
  ZeroMem(P + 8, 8);
End;

Function Sock_Init : LongInt;
Begin
  If NetReady Then Sock_Init := 0
  Else
  Begin
    Errno := SOCENETDOWN;
    Sock_Init := 1;
  End;
End;

Function Socket(Domain, Typ, Proto : LongInt) : LongInt;
Var S, K, B : LongInt;
Begin
  Socket := -1;
  If Domain <> 2 Then
  Begin
    Errno := SOCEINVAL;
    Exit;
  End;
  If Not NetReady Then
  Begin
    Errno := SOCENETDOWN;
    Exit;
  End;
  S := -1;
  For K := MAXS - 1 DownTo 0 Do
    If SType[K] = 0 Then S := K;
  If S < 0 Then
  Begin
    Errno := SOCEMFILE;
    Exit;
  End;
  B := 0;
  If DosAllocMem(LongInt(@B), RXCAP, $13) <> 0 Then
  Begin
    Errno := SOCENOBUFS;
    Exit;
  End;
  SBuf[S] := B; SHead[S] := 0; SLen[S] := 0;
  SState[S] := TS_CLOSED; SRIp[S] := 0; SRPort[S] := 0; SBound[S] := 0;
  If Typ = SOCK_STREAM Then SType[S] := T_TCP
  Else If Typ = SOCK_DGRAM Then SType[S] := T_UDP
  Else If (Typ = SOCK_RAW) And (Proto = 1) Then SType[S] := T_RAW
  Else
  Begin
    Dummy := DosFreeMem(B);
    Errno := SOCEINVAL;
    Exit;
  End;
  SLPort[S] := NewPort;
  Socket := S + 3;
End;

Function Bind(D, PAddr, Len : LongInt) : LongInt;
Var S, Ip, Port : LongInt;
Begin
  Bind := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  SockAddr(PAddr, Ip, Port);
  If Port <> 0 Then SLPort[S] := Port;
  SBound[S] := 1;
  Bind := 0;
End;

Function Connect(D, PAddr, Len : LongInt) : LongInt;
Var S, Ip, Port, Try_, T : LongInt;
Begin
  Connect := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  SockAddr(PAddr, Ip, Port);
  SRIp[S] := Ip; SRPort[S] := Port;
  If SType[S] <> T_TCP Then
  Begin
    Connect := 0;
    Exit;
  End;
  SSeq[S] := KTicks * 64000 + Port; SUna[S] := SSeq[S]; SAck[S] := 0;
  SState[S] := TS_SYNSENT;
  For Try_ := 1 To 4 Do
  Begin
    SSeq[S] := SUna[S];
    TcpSend(S, 2, 0, 0);
    SSeq[S] := SUna[S] + 1;
    T := KTicks;
    While (SState[S] = TS_SYNSENT) And (KTicks - T < 1500) Do Idle;
    If SState[S] = TS_ESTAB Then
    Begin
      Connect := 0;
      Exit;
    End;
    If SState[S] = TS_RESET Then
    Begin
      SState[S] := TS_CLOSED;
      Errno := SOCECONNREFUSED;
      Exit;
    End;
  End;
  SState[S] := TS_CLOSED;
  Errno := SOCETIMEDOUT;
End;

{ envoyer : segment par segment, chacun accuse avant le suivant }
Function TcpWrite(S, Buf, Len : LongInt) : LongInt;
Var Done_, N, Try_, T : LongInt;
Begin
  TcpWrite := -1;
  Done_ := 0;
  While Done_ < Len Do
  Begin
    If (SState[S] <> TS_ESTAB) And (SState[S] <> TS_CLOSEWAIT) Then
    Begin
      If SState[S] = TS_RESET Then Errno := SOCECONNRESET Else Errno := SOCENOTCONN;
      If Done_ > 0 Then TcpWrite := Done_;
      Exit;
    End;
    N := Len - Done_;
    If N > MSS Then N := MSS;
    If (SPWin[S] > 0) And (N > SPWin[S]) Then N := SPWin[S];
    For Try_ := 1 To 8 Do
    Begin
      SSeq[S] := SUna[S];
      TcpSend(S, $18, Buf + Done_, N);
      SSeq[S] := SUna[S] + N;
      T := KTicks;
      While SeqLess(SUna[S], SSeq[S]) And (SState[S] <> TS_RESET) And (KTicks - T < 1000) Do Idle;
      If Not SeqLess(SUna[S], SSeq[S]) Then Break;
    End;
    If SeqLess(SUna[S], SSeq[S]) Then
    Begin
      SSeq[S] := SUna[S];
      Errno := SOCETIMEDOUT;
      If Done_ > 0 Then TcpWrite := Done_;
      Exit;
    End;
    Done_ := Done_ + N;
  End;
  TcpWrite := Done_;
End;

Function Send(D, Buf, Len, Flags : LongInt) : LongInt;
Var S : LongInt;
Begin
  Send := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If SType[S] = T_TCP Then Send := TcpWrite(S, Buf, Len)
  Else If SType[S] = T_UDP Then
  Begin
    If UdpSend(SRIp[S], SLPort[S], SRPort[S], Buf, Len) Then Send := Len Else Errno := SOCEHOSTUNREACH;
  End
  Else If IpSend(SRIp[S], 1, Buf, Len) Then Send := Len
  Else Errno := SOCEHOSTUNREACH;
End;

Function SendTo(D, Buf, Len, Flags, PAddr, ALen : LongInt) : LongInt;
Var S, Ip, Port : LongInt;
Begin
  SendTo := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If SType[S] = T_TCP Then
  Begin
    SendTo := Send(D, Buf, Len, Flags);
    Exit;
  End;
  SockAddr(PAddr, Ip, Port);
  If SType[S] = T_UDP Then
  Begin
    If UdpSend(Ip, SLPort[S], Port, Buf, Len) Then SendTo := Len Else Errno := SOCEHOSTUNREACH;
  End
  Else If IpSend(Ip, 1, Buf, Len) Then SendTo := Len
  Else Errno := SOCEHOSTUNREACH;
End;

{ recevoir (TCP) : attend des donnees ou la fermeture (60 s au plus) }
Function TcpRead(S, Buf, Len : LongInt) : LongInt;
Var T, N, Part, Before : LongInt;
Begin
  T := KTicks;
  NetPoll;
  While (SLen[S] = 0) And (SState[S] = TS_ESTAB) And (KTicks - T < 60000) Do Idle;
  If SLen[S] = 0 Then
  Begin
    If SState[S] = TS_RESET Then
    Begin
      Errno := SOCECONNRESET;
      TcpRead := -1;
    End
    Else If SState[S] = TS_ESTAB Then
    Begin
      Errno := SOCETIMEDOUT;
      TcpRead := -1;
    End
    Else TcpRead := 0;
    Exit;
  End;
  Before := RxFree(S);
  N := Len;
  If N > SLen[S] Then N := SLen[S];
  Part := N;
  If SHead[S] + Part > RXCAP Then Part := RXCAP - SHead[S];
  MoveMem(SBuf[S] + SHead[S], Buf, Part);
  MoveMem(SBuf[S], Buf + Part, N - Part);
  SHead[S] := (SHead[S] + N) Mod RXCAP;
  SLen[S] := SLen[S] - N;
  { fenetre rouverte : la dire a l'autre bout }
  If (Before < 8192) And (RxFree(S) >= 8192) And (SState[S] = TS_ESTAB) Then TcpSend(S, $10, 0, 0);
  TcpRead := N;
End;

{ datagramme suivant (UDP, ICMP brut), attendu 10 s au plus }
Function DgramRead(S, Buf, Len, PAddr, PALen : LongInt; Wait : LongInt) : LongInt;
Var T, N, Src, Port, P : LongInt;
Begin
  DgramRead := -1;
  T := KTicks;
  NetPoll;
  While (SLen[S] = 0) And (KTicks - T < Wait) Do Idle;
  If SLen[S] = 0 Then
  Begin
    Errno := SOCETIMEDOUT;
    Exit;
  End;
  P := SBuf[S] + SHead[S];
  N := Get16(P); Src := Get32(P + 2); Port := Get16(P + 6);
  If N > Len Then MoveMem(P + 8, Buf, Len) Else MoveMem(P + 8, Buf, N);
  SHead[S] := SHead[S] + N + 8; SLen[S] := SLen[S] - N - 8;
  If SLen[S] = 0 Then SHead[S] := 0;
  PutSockAddr(PAddr, Src, Port);
  If PALen <> 0 Then WrL(PALen, 16);
  If N > Len Then N := Len;
  DgramRead := N;
End;

Function Recv(D, Buf, Len, Flags : LongInt) : LongInt;
Var S : LongInt;
Begin
  Recv := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If SType[S] = T_TCP Then Recv := TcpRead(S, Buf, Len)
  Else Recv := DgramRead(S, Buf, Len, 0, 0, 10000);
End;

Function RecvFrom(D, Buf, Len, Flags, PAddr, PALen : LongInt) : LongInt;
Var S : LongInt;
Begin
  RecvFrom := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If SType[S] = T_TCP Then
  Begin
    RecvFrom := TcpRead(S, Buf, Len);
    PutSockAddr(PAddr, SRIp[S], SRPort[S]);
  End
  Else RecvFrom := DgramRead(S, Buf, Len, PAddr, PALen, 10000);
End;

Function Shutdown(D, How : LongInt) : LongInt;
Var S, T : LongInt;
Begin
  Shutdown := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If (SType[S] = T_TCP) And ((SState[S] = TS_ESTAB) Or (SState[S] = TS_CLOSEWAIT)) And (How >= 1) Then
  Begin
    SSeq[S] := SUna[S];
    TcpSend(S, $11, 0, 0);
    SSeq[S] := SUna[S] + 1;
    If SState[S] = TS_ESTAB Then SState[S] := TS_FINWAIT Else SState[S] := TS_CLOSED;
    T := KTicks;
    While SeqLess(SUna[S], SSeq[S]) And (KTicks - T < 1500) Do Idle;
  End;
  Shutdown := 0;
End;

Function SoClose(D : LongInt) : LongInt;
Var S : LongInt;
Begin
  SoClose := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If (SType[S] = T_TCP) And ((SState[S] = TS_ESTAB) Or (SState[S] = TS_CLOSEWAIT)) Then Dummy := Shutdown(D, 2);
  If SBuf[S] <> 0 Then Dummy := DosFreeMem(SBuf[S]);
  SBuf[S] := 0; SType[S] := 0; SState[S] := TS_CLOSED;
  SoClose := 0;
End;

Function Sock_Errno : LongInt;
Begin
  Sock_Errno := Errno;
End;

Function GetHostId : LongInt;
Begin
  If NetReady Then GetHostId := Swap32(MyIp) Else GetHostId := 0;
End;

Function Inet_Addr(P : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := ParseIp(GetZ(P));
  If V = 0 Then Inet_Addr := -1 Else Inet_Addr := Swap32(V);
End;

{ ==================================================================== }
{ DNS                                                                   }
{ ==================================================================== }

{ adresse de Name par le serveur DNS (0 : introuvable) }
Function DnsQuery(Name : String) : LongInt;
Var S, K, L, O, N, Qd, An, Typ, RdLen, Try_, Id : LongInt; Q : Array[0..299] Of Byte; R : Array[0..1023] Of Byte;
    Lab : String;
Begin
  DnsQuery := 0;
  If Dns = 0 Then Exit;
  S := Socket(2, SOCK_DGRAM, 0) - 3;
  If S < 0 Then Exit;
  Id := KTicks And $FFFF;
  { en-tete : identifiant, recursion voulue, une question }
  For K := 0 To 11 Do Q[K] := 0;
  Put16(LongInt(@Q), Id); Q[2] := 1; Q[5] := 1;
  O := 12;
  Name := Name + '.';
  Lab := '';
  For K := 1 To Length(Name) Do
    If Name[K] = '.' Then
    Begin
      If Lab <> '' Then
      Begin
        Q[O] := Length(Lab);
        For L := 1 To Length(Lab) Do Q[O + L] := Ord(Lab[L]);
        O := O + Length(Lab) + 1;
      End;
      Lab := '';
    End
    Else If Length(Lab) < 63 Then Lab := Lab + Name[K];
  Q[O] := 0; Q[O + 1] := 0; Q[O + 2] := 1; Q[O + 3] := 0; Q[O + 4] := 1;
  O := O + 5;
  For Try_ := 1 To 3 Do
  Begin
    Dummy := Ord(UdpSend(Dns, SLPort[S], 53, LongInt(@Q), O));
    N := DgramRead(S, LongInt(@R), 1024, 0, 0, 2500);
    If (N > 12) And (Get16(LongInt(@R)) = Id) Then
    Begin
      Qd := Get16(LongInt(@R) + 4); An := Get16(LongInt(@R) + 6);
      K := 12;
      { questions : nom, type, classe }
      While (Qd > 0) And (K < N) Do
      Begin
        While (K < N) And (R[K] <> 0) And (R[K] < $C0) Do K := K + R[K] + 1;
        If (K < N) And (R[K] >= $C0) Then K := K + 2 Else K := K + 1;
        K := K + 4;
        Dec(Qd);
      End;
      { reponses : la premiere adresse A }
      While (An > 0) And (K + 10 < N) Do
      Begin
        While (K < N) And (R[K] <> 0) And (R[K] < $C0) Do K := K + R[K] + 1;
        If (K < N) And (R[K] >= $C0) Then K := K + 2 Else K := K + 1;
        Typ := Get16(LongInt(@R) + K); RdLen := Get16(LongInt(@R) + K + 8);
        If (Typ = 1) And (RdLen = 4) And (K + 14 <= N) Then
        Begin
          DnsQuery := Get32(LongInt(@R) + K + 10);
          Dummy := SoClose(S + 3);
          Exit;
        End;
        K := K + 10 + RdLen;
        Dec(An);
      End;
      Break;
    End;
  End;
  Dummy := SoClose(S + 3);
End;

Function GetHostByName(PName : LongInt) : LongInt;
Var S : String; Ip : LongInt;
Begin
  GetHostByName := 0;
  HErr := 1;
  S := GetZ(PName);
  If S = '' Then Exit;
  If Not NetReady Then Exit;
  Ip := ParseIp(S);
  If Ip = 0 Then
  Begin
    If UpStr(S) = 'LOCALHOST' Then Ip := $7F000001 Else Ip := DnsQuery(S);
  End;
  If Ip = 0 Then Exit;
  PutZ(LongInt(@HostName), S);
  HostAddr[0] := Swap32(Ip); HostAddr[1] := 0;
  HostList[0] := LongInt(@HostAddr); HostList[1] := 0;
  HostEnt[0] := LongInt(@HostName); HostEnt[1] := LongInt(@HostList) + 4;
  HostEnt[2] := 2; HostEnt[3] := 4; HostEnt[4] := LongInt(@HostList);
  HErr := 0;
  GetHostByName := LongInt(@HostEnt);
End;

{ ==================================================================== }
{ Points d'entree internes                                              }
{ ==================================================================== }

{ etat de l'interface lan0 : P[0] etat (0 pas de carte, 1 carte sans
  adresse, 2 configuree), P[1] adresse, P[2] masque, P[3] passerelle,
  P[4] DNS, P[5] DHCP (1) ou fixe, P[6] lien, P[7] trames recues,
  P[8] envoyees, P[9] bail (s) ; P[10] tampon et P[11] taille : texte
  "carte (pilote), adresse MAC" }
Function TcpipInfo(P : LongInt) : LongInt;
Var S : String; K : LongInt;
Begin
  Dummy := Ord(NetReady);
  If DrvFn = 0 Then WrL(P, 0) Else If Ready = 1 Then WrL(P, 2) Else WrL(P, 1);
  WrL(P + 4, MyIp); WrL(P + 8, Mask); WrL(P + 12, Gw); WrL(P + 16, Dns); WrL(P + 20, Dhcp);
  If DrvFn <> 0 Then WrL(P + 24, LinkState) Else WrL(P + 24, 0);
  WrL(P + 28, RxPkts); WrL(P + 32, TxPkts); WrL(P + 36, Lease);
  If DrvFn <> 0 Then
  Begin
    S := CardName + ' (' + DrvName + '.DLL), MAC ';
    For K := 0 To 5 Do
    Begin
      S := S + Hex2(Mac[K]);
      If K < 5 Then S := S + ':';
    End;
  End
  Else S := 'Aucune carte reseau (E1000.DLL, PCNET.DLL)';
  If (RdL(P + 40) <> 0) And (RdL(P + 44) > 0) Then
  Begin
    If Length(S) > RdL(P + 44) - 1 Then S := Copy(S, 1, RdL(P + 44) - 1);
    PutZ(RdL(P + 40), S);
  End;
  TcpipInfo := RdL(P);
End;

{ refaire la configuration (DHCP) }
Function TcpipRenew : LongInt;
Begin
  If Ready <> 0 Then Ready := 0;
  If NetReady Then TcpipRenew := 0 Else TcpipRenew := 1;
End;

Exports
  Sock_Init Index 26 Name 'sock_init',
  Socket Index 16 Name 'socket',
  Bind Index 2 Name 'bind',
  Connect Index 3 Name 'connect',
  Send Index 13 Name 'send',
  Recv Index 10 Name 'recv',
  SendTo Index 14 Name 'sendto',
  RecvFrom Index 11 Name 'recvfrom',
  SoClose Index 17 Name 'soclose',
  Shutdown Index 25 Name 'shutdown',
  Sock_Errno Index 20 Name 'sock_errno',
  GetHostByName Index 211 Name 'gethostbyname',
  GetHostId Index 213 Name 'gethostid',
  Inet_Addr Index 105 Name 'inet_addr',
  TcpipInfo Index 900 Name 'TCPIPINFO',
  TcpipRenew Index 901 Name 'TCPIPRENEW';

Var
  InitK : LongInt;

BEGIN
  DrvTried := 0; DrvFn := 0; Ready := 0; Dhcp := 0;
  MyIp := 0; Mask := 0; Gw := 0; Dns := 0; Lease := 0;
  IpId := 1; NextPort := 1100; Errno := 0; ArpNext := 0; RxPkts := 0; TxPkts := 0;
  For InitK := 0 To MAXS - 1 Do
  Begin
    SType[InitK] := 0; SBuf[InitK] := 0;
  End;
END.
