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
  inet_addr, select (ordinal 12, select d'OS/2 : tableau de sockets,
  delai en millisecondes) et bsdselect (ordinal 32, select de BSD :
  masques fd_set, struct timeval) ; points d'entree internes TCPIPINFO (etat de l'interface
  lan0 : IFCONFIG, gestionnaire de peripheriques) et TCPIPRENEW (refaire
  la configuration). Codes d'erreur (sock_errno) : SOCBASEERR (10000) +
  code BSD. }

Const
  MAXS = 96;
  RXCAP = 65536;      { socket ordinaire : reception }
  TXCAP = 32768;      { socket ordinaire : emission }
  CRX = 8192;         { connexion d'un socket d'ecoute : reception }
  CTX = 24576;        { connexion d'un socket d'ecoute : emission }
  SYSRX = 32768;      { socket du systeme (sosystem) : reception }
  SYSTX = 16384;      { socket du systeme : emission }
  MAXPOOL = 48;       { connexions simultanees d'un socket d'ecoute }
  MSS = 1400;
  CWND = 16 * 1400;   { octets en vol au plus }
  RTO0 = 700;         { delai de reemission initial (ms) }
  SOCK_STREAM = 1; SOCK_DGRAM = 2; SOCK_RAW = 3;
  T_TCP = 1; T_UDP = 2; T_RAW = 3; T_DEAD = 4;
  { etats TCP }
  TS_CLOSED = 0; TS_SYNSENT = 1; TS_ESTAB = 2; TS_FINWAIT = 3; TS_CLOSEWAIT = 4; TS_RESET = 5;
  TS_LISTEN = 6; TS_SYNRCVD = 7; TS_LASTACK = 8; TS_TIMEWAIT = 9;
  SOCEWOULDBLOCK = 10035;
  LBCAP = 131072;            { file de la boucle locale }
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
  RxBytes, TxBytes : LongInt;      { octets des trames (TCPIPSTATS) }
  AbortGen : LongInt;              { soabort(-1) : attentes en cours abandonnees }
  { trames }
  TxF, RxF : Array[0..1599] Of Byte;
  Seg : Array[0..1599] Of Byte;
  { cache ARP }
  ArpIp : Array[0..63] Of LongInt;
  ArpMac : Array[0..383] Of Byte;
  ArpNext : LongInt;
  { sockets }
  SType, SState, SLPort, SRIp, SRPort, SSeq, SUna, SAck, SBuf, SHead, SLen, SPWin, SBound : Array[0..MAXS - 1] Of LongInt;
  SSys : Array[0..MAXS - 1] Of Boolean;   { tampon du tas partage (sosystem) }
  { emission (anneau STx de STxCap octets : STxLen octets depuis SUna),
    FIN (0, 1 demande, 2 envoye), reemission, non bloquant, ecoute }
  SRxCap, STx, STxCap, STxHead, STxLen, SFin, SRtxT, SRto, SRetry, SNb, SMss, SDup : Array[0..MAXS - 1] Of LongInt;
  SOwner, SParent, SPSlot, SAccQ, SBack, SPool, SOrphT : Array[0..MAXS - 1] Of LongInt;
  SFinAck, SOrphan : Array[0..MAXS - 1] Of Boolean;
  PoolUse : Array[0..MAXS * MAXPOOL - 1] Of Byte;
  IsnGen, AccGen, LastGc, LastTmr : LongInt;
  InPoll : Boolean;
  { boucle locale (127.x.x.x et notre propre adresse) : paquets IP en file,
    relus par NetPoll comme s'ils arrivaient de la carte }
  LbBuf : Array[0..LBCAP - 1] Of Byte;
  LbHead, LbTail, LbUsed : LongInt;
  LbPkt : Array[0..1599] Of Byte;
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
Function KHeapAlloc(Heap, Flags, Size : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapAlloc';
Function KHeapFree(Heap, Flags, P : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapFree';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function KTaskCtl(Op, P1, P2, P3 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnTaskCtl';
Function KPid : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';

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
  If CallPtr1(DrvFn, LongInt(@NPk)) = 0 Then
  Begin
    Inc(TxPkts);
    TxBytes := TxBytes + N;
  End;
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
  For K := 0 To 63 Do
    If ArpIp[K] = Ip Then I := K;
  If I < 0 Then
  Begin
    I := ArpNext;
    ArpNext := (ArpNext + 1) And 63;
  End;
  ArpIp[I] := Ip;
  For K := 0 To 5 Do ArpMac[I * 6 + K] := RdB(PMac + K);
End;

Function ArpFind(Ip : LongInt) : LongInt;
Var K : LongInt;
Begin
  ArpFind := -1;
  For K := 0 To 63 Do
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
Procedure TcpTimers; Forward;
Function Alive(S : LongInt) : Boolean; Forward;

Function MyPid : LongInt;
Begin
  MyPid := KPid;
End;

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
  If (Dst <> MyIp) And (Dst <> -1) And (MyIp <> 0) And (Dst <> (MyIp Or Not Mask)) And
     (((Dst Shr 24) And 255) <> 127) Then Exit;
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
          If (SType[S] = T_RAW) And Alive(S) Then QueueDgram(S, Src, 0, A, Tot);
      End;
    17 :
      Begin
        SPort := Get16(P); DPort := Get16(P + 2);
        If DPort = 68 Then DhcpIn(P + 8, L - 8)
        Else
          For S := 0 To MAXS - 1 Do
            If (SType[S] = T_UDP) And (SLPort[S] = DPort) And Alive(S) Then
              QueueDgram(S, Src, SPort, P + 8, Get16(P + 4) - 8);
      End;
    6 : TcpIn(A, P, L, Src);
  End;
End;

Procedure EthIn(N : LongInt);
Var Typ, Op, SIp, TIp : LongInt;
Begin
  If N < 14 Then Exit;
  Inc(RxPkts);
  RxBytes := RxBytes + N;
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
  Else If Typ = $0800 Then
  Begin
    { adresse MAC d'un hote du reseau local (clients d'un serveur) }
    SIp := Get32(LongInt(@RxF) + 26);
    If (MyIp <> 0) And (Mask <> 0) And ((SIp And Mask) = (MyIp And Mask)) And (SIp <> MyIp) And
       (ArpFind(SIp) < 0) Then ArpLearn(SIp, LongInt(@RxF) + 6);
    IpIn(LongInt(@RxF) + 14, N - 14);
  End;
End;

{ --- boucle locale --- }

Function IsLocal(Ip : LongInt) : Boolean;
Begin
  IsLocal := (((Ip Shr 24) And 255) = 127) Or ((Ip = MyIp) And (MyIp <> 0));
End;

{ mettre un paquet IP (deja forme) dans la file ; faux : file pleine }
Function LbPut(A, N : LongInt) : Boolean;
Var K : LongInt;
Begin
  LbPut := False;
  If (N <= 0) Or (N > 1600) Or (LbUsed + N + 2 > LBCAP) Then Exit;
  LbBuf[LbTail] := N And 255; LbTail := (LbTail + 1) Mod LBCAP;
  LbBuf[LbTail] := (N Shr 8) And 255; LbTail := (LbTail + 1) Mod LBCAP;
  For K := 0 To N - 1 Do
  Begin
    LbBuf[LbTail] := RdB(A + K);
    LbTail := (LbTail + 1) Mod LBCAP;
  End;
  LbUsed := LbUsed + N + 2;
  LbPut := True;
End;

{ relire les paquets de la boucle locale }
Procedure LbPoll;
Var N, K, C : LongInt;
Begin
  C := 0;
  While (LbUsed > 0) And (C < 64) Do
  Begin
    N := LbBuf[LbHead]; LbHead := (LbHead + 1) Mod LBCAP;
    N := N + LbBuf[LbHead] * 256; LbHead := (LbHead + 1) Mod LBCAP;
    For K := 0 To N - 1 Do
    Begin
      LbPkt[K] := LbBuf[LbHead];
      LbHead := (LbHead + 1) Mod LBCAP;
    End;
    LbUsed := LbUsed - N - 2;
    Inc(RxPkts);
    RxBytes := RxBytes + N;
    IpIn(LongInt(@LbPkt), N);
    Inc(C);
  End;
End;

{ lire les trames recues }
Procedure NetPoll;
Var K, N : LongInt;
Begin
  If InPoll Then Exit;
  InPoll := True;
  K := 0;
  If DrvFn <> 0 Then
    Repeat
      N := RawRecv;
      If N > 0 Then EthIn(N);
      Inc(K);
    Until (N = 0) Or (K > 64);
  If LbUsed > 0 Then LbPoll;
  If KTicks - LastTmr >= 20 Then
  Begin
    LastTmr := KTicks;
    TcpTimers;
  End;
  InPoll := False;
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
Var Hop, K, T, Try_, G0 : LongInt;
Begin
  Resolve := False;
  G0 := AbortGen;
  If IsLocal(Ip) Then
  Begin
    M := -2;
    Resolve := True;
    Exit;
  End;
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
    { pendant la lecture des trames : pas d'attente (le segment sera
      reemis) }
    If InPoll Then Exit;
    T := KTicks;
    While (KTicks - T < 500) And (ArpFind(Hop) < 0) And (AbortGen = G0) Do Idle;
    If AbortGen <> G0 Then Exit;
  End;
  K := ArpFind(Hop);
  If K >= 0 Then
  Begin
    M := K;
    Resolve := True;
  End;
End;

Function ResolveNow(Ip : LongInt) : Boolean;
Var M : LongInt;
Begin
  ResolveNow := Resolve(Ip, M);
End;

{ envoyer un paquet IP (Proto) de N octets de donnees en Data }
Function IpSend(Dst, Proto, Data, N : LongInt) : Boolean;
Var M, K : LongInt; Bc : Array[0..5] Of Byte;
Begin
  IpSend := False;
  If Not Resolve(Dst, M) Then Exit;
  If M = -2 Then
  Begin
    { boucle locale : l'en-tete IP seul (source 127.0.0.1 pour 127.x) }
    TxF[14] := $45; TxF[15] := 0;
    Put16(LongInt(@TxF) + 16, 20 + N);
    Inc(IpId);
    Put16(LongInt(@TxF) + 18, IpId And $FFFF);
    Put16(LongInt(@TxF) + 20, $4000);
    TxF[22] := 64; TxF[23] := Proto;
    Put16(LongInt(@TxF) + 24, 0);
    If ((Dst Shr 24) And 255) = 127 Then Put32(LongInt(@TxF) + 26, Dst) Else Put32(LongInt(@TxF) + 26, MyIp);
    Put32(LongInt(@TxF) + 30, Dst);
    Put16(LongInt(@TxF) + 24, Fold(Sum16(LongInt(@TxF) + 14, 20, 0)));
    MoveMem(Data, LongInt(@TxF) + 34, N);
    IpSend := LbPut(LongInt(@TxF) + 14, 20 + N);
    Inc(TxPkts);
    TxBytes := TxBytes + 20 + N;
    Exit;
  End;
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
Var S : String; K, T : LongInt;
Begin
  { configuration en cours dans un autre processus (DHCP du serveur Web
    lance au demarrage, par exemple) : l'attendre au lieu d'echouer }
  If Ready = 2 Then
  Begin
    T := KTicks;
    While (Ready = 2) And (KTicks - T < 20000) Do Idle;
    If Ready = 2 Then Ready := 0;
  End;
  If Ready = 0 Then
  Begin
    Ready := 2;
    If DriverReady Then
    Begin
      For K := 0 To 63 Do ArpIp[K] := 0;
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
        If DhcpRun Then Ready := 1 Else Ready := -1;
      End;
      If (Ready = 1) And (Env('IP_DNS') <> '') And (ParseIp(Env('IP_DNS')) <> 0) Then Dns := ParseIp(Env('IP_DNS'));
    End
    Else Ready := -1;
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

{ le processus proprietaire du socket existe encore (sinon ses tampons
  ont ete rendus : ne plus y ecrire) }
Function Alive(S : LongInt) : Boolean;
Begin
  If SSys[S] Or (SOwner[S] <= 1) Then Alive := True
  Else Alive := KTaskCtl(3, SOwner[S], 0, 0) = 1;
End;

{ espace libre du tampon de reception }
Function RxFree(S : LongInt) : LongInt;
Begin
  RxFree := SRxCap[S] - SLen[S];
End;

{ en-tete TCP + donnees prises dans un anneau (Base, Cap, Off) ou a
  l'adresse Data (Cap = 0) ; numero de sequence SSeq }
Procedure TcpSendX(S, Flags, Base, Cap, Off, N : LongInt);
Var Hl, Sum, Win, Part : LongInt; Ph : Array[0..11] Of Byte;
Begin
  If Not ResolveNow(SRIp[S]) Then Exit;
  If (Flags And 2) <> 0 Then Hl := 24 Else Hl := 20;
  Put16(LongInt(@Seg), SLPort[S]); Put16(LongInt(@Seg) + 2, SRPort[S]);
  Put32(LongInt(@Seg) + 4, SSeq[S]); Put32(LongInt(@Seg) + 8, SAck[S]);
  Seg[12] := (Hl Div 4) Shl 4; Seg[13] := Flags;
  Win := RxFree(S);
  If Win > 65535 Then Win := 65535;
  If Win < 0 Then Win := 0;
  Put16(LongInt(@Seg) + 14, Win);
  Put16(LongInt(@Seg) + 16, 0); Put16(LongInt(@Seg) + 18, 0);
  If Hl = 24 Then
  Begin
    Seg[20] := 2; Seg[21] := 4; Put16(LongInt(@Seg) + 22, 1460);
  End;
  If N > 0 Then
  Begin
    If Cap = 0 Then MoveMem(Base + Off, LongInt(@Seg) + Hl, N)
    Else
    Begin
      Part := N;
      If Off + Part > Cap Then Part := Cap - Off;
      MoveMem(Base + Off, LongInt(@Seg) + Hl, Part);
      MoveMem(Base, LongInt(@Seg) + Hl + Part, N - Part);
    End;
  End;
  { pseudo-en-tete }
  Put32(LongInt(@Ph), MyIp); Put32(LongInt(@Ph) + 4, SRIp[S]);
  Ph[8] := 0; Ph[9] := 6; Put16(LongInt(@Ph) + 10, Hl + N);
  Sum := Sum16(LongInt(@Ph), 12, 0);
  Put16(LongInt(@Seg) + 16, Fold(Sum16(LongInt(@Seg), Hl + N, Sum)));
  Dummy := Ord(IpSend(SRIp[S], 6, LongInt(@Seg), Hl + N));
End;

Procedure TcpSend(S, Flags, Data, N : LongInt);
Begin
  TcpSendX(S, Flags, Data, 0, 0, N);
End;

{ RST pour un segment qui n'appartient a aucun socket (port ferme) }
Procedure TcpRst(Dst, SPort, DPort, Sq, Ak, Fl : LongInt);
Var Sum : LongInt; Ph : Array[0..11] Of Byte;
Begin
  If Not ResolveNow(Dst) Then Exit;
  Put16(LongInt(@Seg), SPort); Put16(LongInt(@Seg) + 2, DPort);
  Put32(LongInt(@Seg) + 4, Sq); Put32(LongInt(@Seg) + 8, Ak);
  Seg[12] := $50; Seg[13] := Fl;
  Put16(LongInt(@Seg) + 14, 0); Put16(LongInt(@Seg) + 16, 0); Put16(LongInt(@Seg) + 18, 0);
  Put32(LongInt(@Ph), MyIp); Put32(LongInt(@Ph) + 4, Dst);
  Ph[8] := 0; Ph[9] := 6; Put16(LongInt(@Ph) + 10, 20);
  Sum := Sum16(LongInt(@Ph), 12, 0);
  Put16(LongInt(@Seg) + 16, Fold(Sum16(LongInt(@Seg), 20, Sum)));
  Dummy := Ord(IpSend(Dst, 6, LongInt(@Seg), 20));
End;

{ MSS annonce par l'autre bout (option 2 d'un SYN) }
Function PeerMss(Th, Off : LongInt) : LongInt;
Var P, K, L, V : LongInt;
Begin
  PeerMss := 536;
  P := Th + 20;
  While P < Th + Off Do
  Begin
    K := RdB(P);
    If K = 0 Then Exit;
    If K = 1 Then Inc(P)
    Else
    Begin
      L := RdB(P + 1);
      If L < 2 Then Exit;
      If (K = 2) And (L = 4) Then
      Begin
        V := Get16(P + 2);
        If V > 0 Then PeerMss := V;
      End;
      P := P + L;
    End;
  End;
End;

{ emettre ce que la fenetre permet : donnees du tampon d'emission pas
  encore envoyees, puis le FIN demande quand tout est parti }
Procedure TcpOutput(S : LongInt);
Var Inf, Avail, Win, N, Fl, Lim, Mss_ : LongInt;
Begin
  If (SState[S] <> TS_ESTAB) And (SState[S] <> TS_CLOSEWAIT) And (SState[S] <> TS_FINWAIT) And
     (SState[S] <> TS_LASTACK) Then Exit;
  If (SFin[S] = 2) Or (STxCap[S] = 0) Then Exit;
  Lim := SPWin[S];
  If Lim > CWND Then Lim := CWND;
  Mss_ := SMss[S];
  If (Mss_ <= 0) Or (Mss_ > MSS) Then Mss_ := MSS;
  Repeat
    Inf := SSeq[S] - SUna[S];
    Avail := STxLen[S] - Inf;
    If Avail <= 0 Then Break;
    Win := Lim - Inf;
    If Win <= 0 Then Break;
    N := Avail;
    If N > Win Then N := Win;
    If N > Mss_ Then N := Mss_;
    If Inf = 0 Then SRtxT[S] := KTicks;
    If N = Avail Then Fl := $18 Else Fl := $10;
    TcpSendX(S, Fl, STx[S], STxCap[S], (STxHead[S] + Inf) Mod STxCap[S], N);
    SSeq[S] := SSeq[S] + N;
  Until False;
  If (SFin[S] = 1) And (STxLen[S] = SSeq[S] - SUna[S]) Then
  Begin
    If SSeq[S] = SUna[S] Then SRtxT[S] := KTicks;
    TcpSend(S, $11, 0, 0);
    SSeq[S] := SSeq[S] + 1;
    SFin[S] := 2;
    If SState[S] = TS_ESTAB Then SState[S] := TS_FINWAIT
    Else If SState[S] = TS_CLOSEWAIT Then SState[S] := TS_LASTACK;
  End;
End;

{ liberer l'emplacement d'un socket (sans toucher a sa memoire) }
Procedure ReleaseSlot(S : LongInt);
Var P, K : LongInt; Left : Boolean;
Begin
  P := SParent[S];
  SType[S] := 0; SState[S] := TS_CLOSED; SOrphan[S] := False; SAccQ[S] := 0;
  SParent[S] := -1; SBuf[S] := 0; STx[S] := 0;
  If (P >= 0) And (SPSlot[S] >= 0) Then
  Begin
    PoolUse[P * MAXPOOL + SPSlot[S]] := 0;
    SPSlot[S] := -1;
    { socket d'ecoute ferme dont c'etait la derniere connexion }
    If SType[P] = T_DEAD Then
    Begin
      Left := False;
      For K := 0 To MAXS - 1 Do
        If (SType[K] <> 0) And (SParent[K] = P) Then Left := True;
      If Not Left Then
      Begin
        If (SPool[P] <> 0) And (SOwner[P] = MyPid) Then Dummy := DosFreeMem(SPool[P]);
        SPool[P] := 0; SType[P] := 0;
      End;
    End;
  End;
End;

{ processus disparu : ses sockets sont oublies }
Procedure SockGc;
Var S, K : LongInt;
Begin
  For S := 0 To MAXS - 1 Do
    If (SType[S] <> 0) And Not Alive(S) Then
    Begin
      If (SType[S] = T_TCP) Or (SType[S] = T_DEAD) Then
        For K := 0 To MAXPOOL - 1 Do PoolUse[S * MAXPOOL + K] := 0;
      SParent[S] := -1; SPSlot[S] := -1;
      SType[S] := 0; SState[S] := TS_CLOSED; SBuf[S] := 0; STx[S] := 0; SPool[S] := 0;
      SOrphan[S] := False; SAccQ[S] := 0;
    End;
End;

{ nouvelle connexion sur un socket d'ecoute L (SYN recu) }
Procedure TcpAcceptSyn(L, Th, Off, SPort, DPort, Sq, Src : LongInt);
Var S, K, P, B : LongInt;
Begin
  P := -1;
  For K := SBack[L] - 1 DownTo 0 Do
    If PoolUse[L * MAXPOOL + K] = 0 Then P := K;
  S := -1;
  For K := MAXS - 1 DownTo 0 Do
    If SType[K] = 0 Then S := K;
  { complet : le client renverra son SYN }
  If (P < 0) Or (S < 0) Then Exit;
  PoolUse[L * MAXPOOL + P] := 1;
  B := SPool[L] + P * (CRX + CTX);
  SType[S] := T_TCP; SState[S] := TS_SYNRCVD;
  SLPort[S] := DPort; SRIp[S] := Src; SRPort[S] := SPort; SBound[S] := 1;
  SBuf[S] := B; SRxCap[S] := CRX; SHead[S] := 0; SLen[S] := 0;
  STx[S] := B + CRX; STxCap[S] := CTX; STxHead[S] := 0; STxLen[S] := 0;
  SFin[S] := 0; SFinAck[S] := False; SSys[S] := False; SNb[S] := 0;
  SOwner[S] := SOwner[L]; SParent[S] := L; SPSlot[S] := P; SOrphan[S] := False; SAccQ[S] := 0;
  SBack[S] := 0; SPool[S] := 0;
  SMss[S] := PeerMss(Th, Off);
  SPWin[S] := Get16(Th + 14);
  SAck[S] := Sq + 1;
  Inc(IsnGen);
  SUna[S] := KTicks * 64000 + IsnGen * 7919 + SPort;
  SSeq[S] := SUna[S];
  SRetry[S] := 0; SRto[S] := RTO0; SDup[S] := 0;
  TcpSend(S, $12, 0, 0);
  SSeq[S] := SUna[S] + 1;
  SRtxT[S] := KTicks;
End;

Procedure TcpIn(Ip, Th, N, Src : LongInt);
Var S, K, SPort, DPort, Sq, Ak, Fl, Off, DLen, D, Take, P, Part, Acked : LongInt;
Begin
  If N < 20 Then Exit;
  SPort := Get16(Th); DPort := Get16(Th + 2);
  Sq := Get32(Th + 4); Ak := Get32(Th + 8);
  Off := (RdB(Th + 12) Shr 4) * 4; Fl := RdB(Th + 13);
  If (Off < 20) Or (Off > N) Then Exit;
  DLen := N - Off;
  S := -1;
  For K := 0 To MAXS - 1 Do
    If (SType[K] = T_TCP) And (SLPort[K] = DPort) And (SRPort[K] = SPort) And (SRIp[K] = Src) And
       (SState[K] <> TS_CLOSED) And (SState[K] <> TS_LISTEN) Then S := K;
  If (S >= 0) And Not Alive(S) Then
  Begin
    SockGc;
    S := -1;
  End;
  If S < 0 Then
  Begin
    { SYN vers un socket d'ecoute }
    If ((Fl And $02) <> 0) And ((Fl And $14) = 0) Then
    Begin
      For K := 0 To MAXS - 1 Do
        If (SType[K] = T_TCP) And (SState[K] = TS_LISTEN) And (SLPort[K] = DPort) Then S := K;
      If (S >= 0) And Alive(S) Then
      Begin
        TcpAcceptSyn(S, Th, Off, SPort, DPort, Sq, Src);
        Exit;
      End;
    End;
    { port ferme : RST }
    If (Fl And 4) = 0 Then
    Begin
      If (Fl And $10) <> 0 Then TcpRst(Src, DPort, SPort, Ak, 0, 4)
      Else
      Begin
        K := Sq + DLen;
        If (Fl And 2) <> 0 Then Inc(K);
        If (Fl And 1) <> 0 Then Inc(K);
        TcpRst(Src, DPort, SPort, 0, K, $14);
      End;
    End;
    Exit;
  End;
  If (Fl And 4) <> 0 Then
  Begin
    If (SState[S] = TS_SYNRCVD) Or SOrphan[S] Then ReleaseSlot(S)
    Else SState[S] := TS_RESET;
    Exit;
  End;
  If SState[S] = TS_SYNSENT Then
  Begin
    If ((Fl And $12) = $12) And (Ak = SSeq[S]) Then
    Begin
      SAck[S] := Sq + 1; SUna[S] := Ak;
      SPWin[S] := Get16(Th + 14);
      SMss[S] := PeerMss(Th, Off);
      SState[S] := TS_ESTAB;
      TcpSend(S, $10, 0, 0);
    End;
    Exit;
  End;
  If SState[S] = TS_SYNRCVD Then
  Begin
    { SYN repete : renvoyer SYN+ACK }
    If ((Fl And 2) <> 0) And ((Fl And $10) = 0) Then
    Begin
      SSeq[S] := SUna[S];
      TcpSend(S, $12, 0, 0);
      SSeq[S] := SUna[S] + 1;
      Exit;
    End;
    If ((Fl And $10) = 0) Or (Ak <> SSeq[S]) Then Exit;
    SUna[S] := Ak;
    SState[S] := TS_ESTAB;
    SRtxT[S] := 0; SRetry[S] := 0; SRto[S] := RTO0;
    Inc(AccGen);
    SAccQ[S] := AccGen;
  End;
  If (Fl And $10) <> 0 Then
  Begin
    If SeqLess(SUna[S], Ak) And Not SeqLess(SSeq[S], Ak) Then
    Begin
      Acked := Ak - SUna[S];
      D := Acked;
      If D > STxLen[S] Then D := STxLen[S];
      If (STxCap[S] > 0) And (D > 0) Then
      Begin
        STxHead[S] := (STxHead[S] + D) Mod STxCap[S];
        STxLen[S] := STxLen[S] - D;
      End;
      SUna[S] := Ak;
      If (SFin[S] = 2) And (Ak = SSeq[S]) Then
      Begin
        SFinAck[S] := True;
        If SState[S] = TS_LASTACK Then SState[S] := TS_CLOSED;
      End;
      SRetry[S] := 0; SRto[S] := RTO0; SDup[S] := 0;
      If SSeq[S] <> SUna[S] Then SRtxT[S] := KTicks Else SRtxT[S] := 0;
    End
    Else If (Ak = SUna[S]) And (DLen = 0) And (SSeq[S] <> SUna[S]) And ((Fl And 3) = 0) Then
    Begin
      { trois accuses en double : segment perdu, reemission immediate }
      Inc(SDup[S]);
      If SDup[S] = 3 Then
      Begin
        SSeq[S] := SUna[S];
        If SFin[S] = 2 Then SFin[S] := 1;
        SRtxT[S] := KTicks;
      End;
    End;
    SPWin[S] := Get16(Th + 14);
  End;
  { donnees en ordre seulement (les autres seront reemises) }
  If DLen > 0 Then
  Begin
    If (Sq = SAck[S]) And ((SState[S] = TS_ESTAB) Or (SState[S] = TS_FINWAIT)) Then
    Begin
      Take := DLen;
      If Take > RxFree(S) Then Take := RxFree(S);
      If SOrphan[S] Then Take := DLen
      Else If Take > 0 Then
      Begin
        D := Th + Off;
        P := (SHead[S] + SLen[S]) Mod SRxCap[S];
        Part := Take;
        If P + Part > SRxCap[S] Then Part := SRxCap[S] - P;
        MoveMem(D, SBuf[S] + P, Part);
        MoveMem(D + Part, SBuf[S], Take - Part);
        SLen[S] := SLen[S] + Take;
      End;
      SAck[S] := SAck[S] + Take;
      If Take < DLen Then Fl := Fl And Not 1;
    End;
    TcpSend(S, $10, 0, 0);
  End;
  If ((Fl And 1) <> 0) And (Sq + DLen = SAck[S]) Then
  Begin
    SAck[S] := SAck[S] + 1;
    If SState[S] = TS_FINWAIT Then SState[S] := TS_TIMEWAIT
    Else If SState[S] = TS_ESTAB Then SState[S] := TS_CLOSEWAIT;
    TcpSend(S, $10, 0, 0);
  End
  Else If ((Fl And 1) <> 0) And (Sq + DLen = SAck[S] - 1) Then
    TcpSend(S, $10, 0, 0);       { FIN reemis : le reconfirmer }
  If SState[S] <> TS_CLOSED Then TcpOutput(S);
  If SOrphan[S] And ((SState[S] = TS_CLOSED) Or (SState[S] = TS_TIMEWAIT)) Then ReleaseSlot(S);
End;

{ minuteries : reemission, SYN+ACK, sonde de fenetre nulle, fin des
  connexions abandonnees par leur programme }
Procedure TcpTimers;
Var S, Now_, Inf : LongInt;
Begin
  Now_ := KTicks;
  If Now_ - LastGc >= 1000 Then
  Begin
    LastGc := Now_;
    SockGc;
  End;
  For S := 0 To MAXS - 1 Do
    If SType[S] = T_TCP Then
    Begin
      If SState[S] = TS_SYNRCVD Then
      Begin
        If Now_ - SRtxT[S] > SRto[S] Then
        Begin
          Inc(SRetry[S]);
          If SRetry[S] > 5 Then ReleaseSlot(S)
          Else
          Begin
            SSeq[S] := SUna[S];
            TcpSend(S, $12, 0, 0);
            SSeq[S] := SUna[S] + 1;
            SRtxT[S] := Now_;
            SRto[S] := SRto[S] * 2;
          End;
        End;
      End
      Else If (SState[S] = TS_ESTAB) Or (SState[S] = TS_CLOSEWAIT) Or (SState[S] = TS_FINWAIT) Or
              (SState[S] = TS_LASTACK) Then
      Begin
        Inf := SSeq[S] - SUna[S];
        If (Inf <> 0) And (SRtxT[S] <> 0) And (Now_ - SRtxT[S] > SRto[S]) Then
        Begin
          Inc(SRetry[S]);
          If SRetry[S] > 10 Then
          Begin
            If SOrphan[S] Then ReleaseSlot(S) Else SState[S] := TS_RESET;
          End
          Else
          Begin
            { tout reprendre depuis le dernier octet confirme }
            SSeq[S] := SUna[S];
            If SFin[S] = 2 Then SFin[S] := 1;
            SRto[S] := SRto[S] * 2;
            If SRto[S] > 8000 Then SRto[S] := 8000;
            SRtxT[S] := Now_;
            TcpOutput(S);
          End;
        End
        Else If (Inf = 0) And (STxLen[S] > 0) And (SPWin[S] = 0) Then
        Begin
          { fenetre nulle : sonde d'un octet }
          If SRtxT[S] = 0 Then SRtxT[S] := Now_
          Else If Now_ - SRtxT[S] > SRto[S] Then
          Begin
            TcpSendX(S, $10, STx[S], STxCap[S], STxHead[S], 1);
            SSeq[S] := SSeq[S] + 1;
            SRtxT[S] := Now_;
          End;
        End;
      End;
      If (SType[S] = T_TCP) And SOrphan[S] Then
      Begin
        If (SState[S] = TS_CLOSED) Or (SState[S] = TS_TIMEWAIT) Or (SState[S] = TS_RESET) Or
           ((SState[S] = TS_FINWAIT) And SFinAck[S] And (Now_ - SOrphT[S] > 5000)) Or
           (Now_ - SOrphT[S] > 60000) Then ReleaseSlot(S);
      End;
    End;
End;

{ ==================================================================== }
{ Sockets                                                               }
{ ==================================================================== }

Function SockOf(D : LongInt) : LongInt;
Begin
  If (D < 3) Or (D >= 3 + MAXS) Then
  Begin
    Errno := SOCENOTSOCK;
    SockOf := -1;
  End
  Else If (SType[D - 3] = 0) Or (SType[D - 3] = T_DEAD) Or SOrphan[D - 3] Then
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
    SockGc;
    For K := MAXS - 1 DownTo 0 Do
      If SType[K] = 0 Then S := K;
  End;
  If S < 0 Then
  Begin
    Errno := SOCEMFILE;
    Exit;
  End;
  If (Typ <> SOCK_STREAM) And (Typ <> SOCK_DGRAM) And Not ((Typ = SOCK_RAW) And (Proto = 1)) Then
  Begin
    Errno := SOCEINVAL;
    Exit;
  End;
  B := 0;
  If Typ = SOCK_STREAM Then K := RXCAP + TXCAP Else K := RXCAP;
  If DosAllocMem(LongInt(@B), K, $13) <> 0 Then
  Begin
    Errno := SOCENOBUFS;
    Exit;
  End;
  SBuf[S] := B; SRxCap[S] := RXCAP; SHead[S] := 0; SLen[S] := 0; SSys[S] := False;
  If Typ = SOCK_STREAM Then
  Begin
    STx[S] := B + RXCAP; STxCap[S] := TXCAP;
  End
  Else
  Begin
    STx[S] := 0; STxCap[S] := 0;
  End;
  STxHead[S] := 0; STxLen[S] := 0; SFin[S] := 0; SFinAck[S] := False;
  SState[S] := TS_CLOSED; SRIp[S] := 0; SRPort[S] := 0; SBound[S] := 0;
  SOwner[S] := MyPid; SParent[S] := -1; SPSlot[S] := -1; SNb[S] := 0; SOrphan[S] := False;
  SAccQ[S] := 0; SBack[S] := 0; SPool[S] := 0; SMss[S] := MSS; SRto[S] := RTO0; SRetry[S] := 0;
  SRtxT[S] := 0; SPWin[S] := 0;
  If Typ = SOCK_STREAM Then SType[S] := T_TCP
  Else If Typ = SOCK_DGRAM Then SType[S] := T_UDP
  Else SType[S] := T_RAW;
  SLPort[S] := NewPort;
  Socket := S + 3;
End;

Function Bind(D, PAddr, Len : LongInt) : LongInt;
Var S, Ip, Port, K : LongInt;
Begin
  Bind := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  SockAddr(PAddr, Ip, Port);
  If Port <> 0 Then
  Begin
    For K := 0 To MAXS - 1 Do
      If (K <> S) And (SType[K] = SType[S]) And (SLPort[K] = Port) And
         ((SType[K] <> T_TCP) Or (SState[K] = TS_LISTEN)) And Alive(K) Then
      Begin
        Errno := SOCEADDRINUSE;
        Exit;
      End;
    SLPort[S] := Port;
  End;
  SBound[S] := 1;
  Bind := 0;
End;

{ listen : le socket attend les connexions ; Backlog * 4 connexions
  simultanees au plus (16 a 48), chacune avec ses tampons pris dans une
  reserve du programme (8 Ko en reception, 24 Ko en emission) }
Function Listen(D, Backlog : LongInt) : LongInt;
Var S, N, B, K : LongInt;
Begin
  Listen := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If (SType[S] <> T_TCP) Or ((SState[S] <> TS_CLOSED) And (SState[S] <> TS_LISTEN)) Then
  Begin
    Errno := SOCEINVAL;
    Exit;
  End;
  If SState[S] = TS_LISTEN Then
  Begin
    Listen := 0;
    Exit;
  End;
  For K := 0 To MAXS - 1 Do
    If (K <> S) And (SType[K] = T_TCP) And (SState[K] = TS_LISTEN) And (SLPort[K] = SLPort[S]) And Alive(K) Then
    Begin
      Errno := SOCEADDRINUSE;
      Exit;
    End;
  N := Backlog * 4;
  If N < 16 Then N := 16;
  If N > MAXPOOL Then N := MAXPOOL;
  B := 0;
  If DosAllocMem(LongInt(@B), N * (CRX + CTX), $13) <> 0 Then
  Begin
    Errno := SOCENOBUFS;
    Exit;
  End;
  If (SBuf[S] <> 0) And Not SSys[S] Then Dummy := DosFreeMem(SBuf[S]);
  SBuf[S] := 0; STx[S] := 0; STxCap[S] := 0; SRxCap[S] := 0;
  SPool[S] := B; SBack[S] := N;
  For K := 0 To MAXPOOL - 1 Do PoolUse[S * MAXPOOL + K] := 0;
  SState[S] := TS_LISTEN;
  Listen := 0;
End;

{ accept : prochaine connexion etablie du socket d'ecoute }
Function Accept(D, PAddr, PLen : LongInt) : LongInt;
Var S, K, C, Best : LongInt;
Begin
  Accept := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If SState[S] <> TS_LISTEN Then
  Begin
    Errno := SOCEINVAL;
    Exit;
  End;
  Repeat
    NetPoll;
    C := -1; Best := 0;
    For K := 0 To MAXS - 1 Do
      If (SType[K] = T_TCP) And (SParent[K] = S) And (SAccQ[K] > 0) And Not SOrphan[K] Then
        If (C < 0) Or (SAccQ[K] < Best) Then
        Begin
          C := K; Best := SAccQ[K];
        End;
    If C >= 0 Then
    Begin
      SAccQ[C] := 0;
      PutSockAddr(PAddr, SRIp[C], SRPort[C]);
      If PLen <> 0 Then WrL(PLen, 16);
      Accept := C + 3;
      Exit;
    End;
    If SNb[S] <> 0 Then
    Begin
      Errno := SOCEWOULDBLOCK;
      Exit;
    End;
    Idle;
  Until SState[S] <> TS_LISTEN;
  Errno := SOCEINVAL;
End;

Function Connect(D, PAddr, Len : LongInt) : LongInt;
Var S, Ip, Port, Try_, T, G0 : LongInt;
Begin
  Connect := -1;
  G0 := AbortGen;
  S := SockOf(D);
  If S < 0 Then Exit;
  SockAddr(PAddr, Ip, Port);
  SRIp[S] := Ip; SRPort[S] := Port;
  If SType[S] <> T_TCP Then
  Begin
    Connect := 0;
    Exit;
  End;
  Inc(IsnGen);
  SSeq[S] := KTicks * 64000 + IsnGen * 7919 + Port; SUna[S] := SSeq[S]; SAck[S] := 0;
  STxHead[S] := 0; STxLen[S] := 0; SFin[S] := 0; SFinAck[S] := False; SRto[S] := RTO0; SRetry[S] := 0;
  SDup[S] := 0;
  SState[S] := TS_SYNSENT;
  For Try_ := 1 To 4 Do
  Begin
    SSeq[S] := SUna[S];
    TcpSend(S, 2, 0, 0);
    SSeq[S] := SUna[S] + 1;
    T := KTicks;
    While (SState[S] = TS_SYNSENT) And (KTicks - T < 1500) And (AbortGen = G0) Do Idle;
    If AbortGen <> G0 Then SState[S] := TS_RESET;
    If SState[S] = TS_ESTAB Then
    Begin
      SRtxT[S] := 0;
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

{ envoyer : les donnees passent dans le tampon d'emission (fenetre
  glissante : plusieurs segments en vol, reemis par la minuterie) ; non
  bloquant : ce qui tient, sinon SOCEWOULDBLOCK }
Function TcpWrite(S, Buf, Len : LongInt) : LongInt;
Var Done_, N, P, Part, T : LongInt;
Begin
  TcpWrite := -1;
  Done_ := 0;
  T := KTicks;
  While Done_ < Len Do
  Begin
    If ((SState[S] <> TS_ESTAB) And (SState[S] <> TS_CLOSEWAIT)) Or (SFin[S] <> 0) Then
    Begin
      If SState[S] = TS_RESET Then Errno := SOCECONNRESET Else Errno := SOCENOTCONN;
      If Done_ > 0 Then TcpWrite := Done_;
      Exit;
    End;
    N := STxCap[S] - STxLen[S];
    If N > Len - Done_ Then N := Len - Done_;
    If N > 0 Then
    Begin
      P := (STxHead[S] + STxLen[S]) Mod STxCap[S];
      Part := N;
      If P + Part > STxCap[S] Then Part := STxCap[S] - P;
      MoveMem(Buf + Done_, STx[S] + P, Part);
      MoveMem(Buf + Done_ + Part, STx[S], N - Part);
      STxLen[S] := STxLen[S] + N;
      Done_ := Done_ + N;
      TcpOutput(S);
      T := KTicks;
    End
    Else
    Begin
      If SNb[S] <> 0 Then Break;
      If KTicks - T > 60000 Then
      Begin
        Errno := SOCETIMEDOUT;
        If Done_ > 0 Then TcpWrite := Done_;
        Exit;
      End;
      Idle;
    End;
  End;
  If (Done_ = 0) And (Len > 0) Then Errno := SOCEWOULDBLOCK
  Else TcpWrite := Done_;
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

{ recevoir (TCP) : attend des donnees ou la fermeture (60 s au plus) ;
  non bloquant : SOCEWOULDBLOCK s'il n'y a rien }
Function TcpRead(S, Buf, Len : LongInt) : LongInt;
Var T, N, Part, Before, Half : LongInt;
Begin
  T := KTicks;
  NetPoll;
  If (SLen[S] = 0) And ((SState[S] = TS_ESTAB) Or (SState[S] = TS_FINWAIT)) And (SNb[S] <> 0) Then
  Begin
    Errno := SOCEWOULDBLOCK;
    TcpRead := -1;
    Exit;
  End;
  While (SLen[S] = 0) And ((SState[S] = TS_ESTAB) Or (SState[S] = TS_FINWAIT)) And (KTicks - T < 60000) Do Idle;
  If SLen[S] = 0 Then
  Begin
    If SState[S] = TS_RESET Then
    Begin
      Errno := SOCECONNRESET;
      TcpRead := -1;
    End
    Else If (SState[S] = TS_ESTAB) Or (SState[S] = TS_FINWAIT) Then
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
  If SHead[S] + Part > SRxCap[S] Then Part := SRxCap[S] - SHead[S];
  MoveMem(SBuf[S] + SHead[S], Buf, Part);
  MoveMem(SBuf[S], Buf + Part, N - Part);
  SHead[S] := (SHead[S] + N) Mod SRxCap[S];
  SLen[S] := SLen[S] - N;
  { fenetre rouverte : la dire a l'autre bout }
  Half := SRxCap[S] Div 2;
  If Half > 8192 Then Half := 8192;
  If (Before < Half) And (RxFree(S) >= Half) And ((SState[S] = TS_ESTAB) Or (SState[S] = TS_FINWAIT)) Then
    TcpSend(S, $10, 0, 0);
  TcpRead := N;
End;

{ datagramme suivant (UDP, ICMP brut), attendu 10 s au plus }
Function DgramRead(S, Buf, Len, PAddr, PALen : LongInt; Wait : LongInt) : LongInt;
Var T, N, Src, Port, P, G0 : LongInt;
Begin
  DgramRead := -1;
  T := KTicks;
  G0 := AbortGen;
  NetPoll;
  If (SLen[S] = 0) And (SNb[S] <> 0) Then
  Begin
    Errno := SOCEWOULDBLOCK;
    Exit;
  End;
  While (SLen[S] = 0) And (KTicks - T < Wait) And (AbortGen = G0) Do Idle;
  If SLen[S] = 0 Then
  Begin
    If AbortGen <> G0 Then Errno := 10004 Else Errno := SOCETIMEDOUT;    { SOCEINTR : soabort(-1) }
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

{ fin de l'emission : le FIN part quand tout le tampon est envoye ;
  bloquant : attendre qu'il soit confirme (10 s au plus) }
Function Shutdown(D, How : LongInt) : LongInt;
Var S, T : LongInt;
Begin
  Shutdown := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If (SType[S] = T_TCP) And ((SState[S] = TS_ESTAB) Or (SState[S] = TS_CLOSEWAIT)) And (How >= 1) And
     (SFin[S] = 0) Then
  Begin
    SFin[S] := 1;
    TcpOutput(S);
    If SNb[S] = 0 Then
    Begin
      T := KTicks;
      While Not SFinAck[S] And (SState[S] <> TS_RESET) And (SState[S] <> TS_CLOSED) And
            (KTicks - T < 10000) Do Idle;
    End;
  End;
  Shutdown := 0;
End;

Function SoClose(D : LongInt) : LongInt;
Var S, K : LongInt; Left : Boolean;
Begin
  SoClose := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If (SType[S] = T_TCP) And (SState[S] = TS_LISTEN) Then
  Begin
    { connexions pas encore acceptees : refusees }
    Left := False;
    For K := 0 To MAXS - 1 Do
      If (SType[K] = T_TCP) And (SParent[K] = S) Then
      Begin
        If (SState[K] = TS_SYNRCVD) Or (SAccQ[K] > 0) Then
        Begin
          TcpSend(K, $14, 0, 0);
          ReleaseSlot(K);
        End
        Else Left := True;
      End;
    If Left Then
    Begin
      SType[S] := T_DEAD;
      SState[S] := TS_CLOSED;
    End
    Else
    Begin
      If SPool[S] <> 0 Then Dummy := DosFreeMem(SPool[S]);
      SPool[S] := 0;
      SType[S] := 0; SState[S] := TS_CLOSED;
    End;
    SoClose := 0;
    Exit;
  End;
  { connexion d'un socket d'ecoute : la pile finit d'envoyer, puis
    l'emplacement est libere (le programme n'attend pas) }
  If (SType[S] = T_TCP) And (SParent[S] >= 0) Then
  Begin
    If (SState[S] = TS_ESTAB) Or (SState[S] = TS_CLOSEWAIT) Or (SState[S] = TS_FINWAIT) Or
       (SState[S] = TS_LASTACK) Then
    Begin
      If SFin[S] = 0 Then SFin[S] := 1;
      SOrphan[S] := True;
      SOrphT[S] := KTicks;
      TcpOutput(S);
    End
    Else ReleaseSlot(S);
    SoClose := 0;
    Exit;
  End;
  If (SType[S] = T_TCP) And ((SState[S] = TS_ESTAB) Or (SState[S] = TS_CLOSEWAIT)) Then
  Begin
    SNb[S] := 0;
    Dummy := Shutdown(D, 2);
  End;
  If SBuf[S] <> 0 Then
  Begin
    If SSys[S] Then Dummy := KHeapFree(2, 0, SBuf[S]) Else Dummy := DosFreeMem(SBuf[S]);
  End;
  SBuf[S] := 0; STx[S] := 0; SType[S] := 0; SState[S] := TS_CLOSED; SSys[S] := False;
  SoClose := 0;
End;

{ sosystem(s) : socket du systeme (lecteurs reseau de SMB.IFS) ; ses
  tampons passent dans le tas partage et survivent au processus qui l'a
  cree (les objets de DosAllocMem sont liberes a la fin du processus) }
Function SoSystem(D : LongInt) : LongInt;
Var S, B, N, Part : LongInt;
Begin
  SoSystem := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If SSys[S] Then
  Begin
    SoSystem := 0;
    Exit;
  End;
  If (SLen[S] > SYSRX) Or (STxLen[S] > SYSTX) Then
  Begin
    Errno := SOCENOBUFS;
    Exit;
  End;
  B := KHeapAlloc(2, 8, SYSRX + SYSTX);
  If B = 0 Then
  Begin
    Errno := SOCENOBUFS;
    Exit;
  End;
  { recopie dans l'ordre (les anneaux recommencent a 0) }
  N := SLen[S];
  If N > 0 Then
  Begin
    Part := N;
    If SHead[S] + Part > SRxCap[S] Then Part := SRxCap[S] - SHead[S];
    MoveMem(SBuf[S] + SHead[S], B, Part);
    MoveMem(SBuf[S], B + Part, N - Part);
  End;
  N := STxLen[S];
  If (N > 0) And (STxCap[S] > 0) Then
  Begin
    Part := N;
    If STxHead[S] + Part > STxCap[S] Then Part := STxCap[S] - STxHead[S];
    MoveMem(STx[S] + STxHead[S], B + SYSRX, Part);
    MoveMem(STx[S], B + SYSRX + Part, N - Part);
  End;
  If SBuf[S] <> 0 Then Dummy := DosFreeMem(SBuf[S]);
  SBuf[S] := B; SRxCap[S] := SYSRX; SHead[S] := 0;
  If SType[S] = T_TCP Then
  Begin
    STx[S] := B + SYSRX; STxCap[S] := SYSTX;
  End;
  STxHead[S] := 0;
  SSys[S] := True;
  SoSystem := 0;
End;

{ ioctl (ordinal 8) : FIONBIO (non bloquant), FIONREAD (octets a lire) }
Function Ioctl(D, Cmd, PArg, Len : LongInt) : LongInt;
Var S : LongInt;
Begin
  Ioctl := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If (Cmd And $FFFF) = $667E Then
  Begin
    If (PArg <> 0) And (RdL(PArg) <> 0) Then SNb[S] := 1 Else SNb[S] := 0;
    Ioctl := 0;
  End
  Else If (Cmd And $FFFF) = $667F Then
  Begin
    NetPoll;
    If PArg <> 0 Then
    Begin
      If SType[S] = T_TCP Then WrL(PArg, SLen[S])
      Else If SLen[S] > 0 Then WrL(PArg, Get16(SBuf[S] + SHead[S]))
      Else WrL(PArg, 0);
    End;
    Ioctl := 0;
  End
  Else Errno := SOCEINVAL;
End;

{ setsockopt / getsockopt (ordinaux 15 et 7) : acceptes (SO_REUSEADDR,
  TCP_NODELAY... sont sans effet) ; SO_ERROR rend 0 }
Function SetSockOpt(D, Level, Opt, PVal, Len : LongInt) : LongInt;
Begin
  SetSockOpt := -1;
  If SockOf(D) < 0 Then Exit;
  SetSockOpt := 0;
End;

Function GetSockOpt(D, Level, Opt, PVal, PLen : LongInt) : LongInt;
Var S : LongInt;
Begin
  GetSockOpt := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If PVal <> 0 Then
  Begin
    If Opt = $1008 Then
    Begin
      If SType[S] = T_TCP Then WrL(PVal, 1) Else If SType[S] = T_UDP Then WrL(PVal, 2) Else WrL(PVal, 3);
    End
    Else WrL(PVal, 0);
  End;
  If PLen <> 0 Then WrL(PLen, 4);
  GetSockOpt := 0;
End;

Function GetSockName(D, PAddr, PLen : LongInt) : LongInt;
Var S : LongInt;
Begin
  GetSockName := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  PutSockAddr(PAddr, MyIp, SLPort[S]);
  If PLen <> 0 Then WrL(PLen, 16);
  GetSockName := 0;
End;

Function GetPeerName(D, PAddr, PLen : LongInt) : LongInt;
Var S : LongInt;
Begin
  GetPeerName := -1;
  S := SockOf(D);
  If S < 0 Then Exit;
  If (SType[S] = T_TCP) And (SState[S] <> TS_ESTAB) And (SState[S] <> TS_CLOSEWAIT) And
     (SState[S] <> TS_FINWAIT) Then
  Begin
    Errno := SOCENOTCONN;
    Exit;
  End;
  PutSockAddr(PAddr, SRIp[S], SRPort[S]);
  If PLen <> 0 Then WrL(PLen, 16);
  GetPeerName := 0;
End;

{ ==================================================================== }
{ select : attente de plusieurs sockets                                 }
{ ==================================================================== }

{ donnees a lire (ou fin de la connexion : recv rend 0 ou une erreur) ;
  socket d'ecoute : une connexion a accepter }
Function SockReadable(S : LongInt) : Boolean;
Var K : LongInt;
Begin
  If SType[S] = T_TCP Then
  Begin
    If SState[S] = TS_LISTEN Then
    Begin
      SockReadable := False;
      For K := 0 To MAXS - 1 Do
        If (SType[K] = T_TCP) And (SParent[K] = S) And (SAccQ[K] > 0) And Not SOrphan[K] Then
          SockReadable := True;
    End
    Else
      SockReadable := (SLen[S] > 0) Or ((SState[S] <> TS_ESTAB) And (SState[S] <> TS_SYNSENT) And
                      (SState[S] <> TS_FINWAIT));
  End
  Else SockReadable := SLen[S] > 0;
End;

Function SockWritable(S : LongInt) : Boolean;
Begin
  If SType[S] = T_TCP Then
    SockWritable := (((SState[S] = TS_ESTAB) Or (SState[S] = TS_CLOSEWAIT)) And (STxLen[S] < STxCap[S])) Or
                    (SState[S] = TS_RESET)
  Else SockWritable := True;
End;

{ select d'OS/2 (ordinal 12) : int select(int *s, int noreads, int
  nowrites, int noexcepts, long timeout) ; S : noreads sockets a lire,
  puis nowrites a ecrire, puis noexcepts ; Timeout en millisecondes (-1 :
  sans limite, 0 : interrogation). Les sockets qui ne sont pas prets sont
  remplaces par -1 dans le tableau ; rend le nombre de sockets prets (0 :
  delai ecoule, -1 : erreur) }
Function Os2Select(PS, NR, NW, NE, Timeout : LongInt) : LongInt;
Var T, I, N, D, S, Tot : LongInt; Rd : Boolean;
Begin
  Os2Select := -1;
  Tot := NR + NW + NE;
  If (Tot < 0) Or ((Tot > 0) And (PS = 0)) Then
  Begin
    Errno := SOCEINVAL;
    Exit;
  End;
  For I := 0 To Tot - 1 Do
    If SockOf(RdL(PS + I * 4)) < 0 Then Exit;
  T := KTicks;
  Repeat
    NetPoll;
    N := 0;
    For I := 0 To Tot - 1 Do
    Begin
      S := SockOf(RdL(PS + I * 4));
      If S < 0 Then Rd := True
      Else If I < NR Then Rd := SockReadable(S)
      Else If I < NR + NW Then Rd := SockWritable(S)
      Else Rd := SState[S] = TS_RESET;
      If Rd Then Inc(N);
    End;
    If (N > 0) Or (Timeout = 0) Or ((Timeout > 0) And (KTicks - T >= Timeout)) Then Break;
    Idle;
  Until False;
  { les sockets pas prets : -1 }
  For I := 0 To Tot - 1 Do
  Begin
    D := RdL(PS + I * 4);
    S := SockOf(D);
    If S < 0 Then Rd := True
    Else If I < NR Then Rd := SockReadable(S)
    Else If I < NR + NW Then Rd := SockWritable(S)
    Else Rd := SState[S] = TS_RESET;
    If Not Rd Then WrL(PS + I * 4, -1);
  End;
  Os2Select := N;
End;

{ bsdselect (ordinal 32) : select de BSD, int bsdselect(int nfds, fd_set
  *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout) ;
  fd_set : masque de bits (un LongInt par 32 descripteurs) ; timeout :
  secondes et microsecondes (pointeur nul : sans limite). Les ensembles
  ne gardent que les descripteurs prets ; rend leur nombre }
Function BsdSelect(Nfds, PR, PW, PE, PTv : LongInt) : LongInt;
Var T, Ms, D, S, N, K, W : LongInt; Sets : Array[0..2] Of LongInt;
    Want, Got : Array[0..2, 0..3] Of LongInt; Rd : Boolean;
Begin
  BsdSelect := -1;
  If (Nfds < 0) Or (Nfds > 128) Then
  Begin
    Errno := SOCEINVAL;
    Exit;
  End;
  Sets[0] := PR; Sets[1] := PW; Sets[2] := PE;
  For K := 0 To 2 Do
    For W := 0 To 3 Do
    Begin
      If (Sets[K] <> 0) And (W * 32 < Nfds) Then Want[K, W] := RdL(Sets[K] + W * 4) Else Want[K, W] := 0;
      Got[K, W] := 0;
    End;
  For K := 0 To 2 Do
    For D := 0 To Nfds - 1 Do
      If ((Want[K, D Shr 5] Shr (D And 31)) And 1) <> 0 Then
        If SockOf(D) < 0 Then Exit;
  If PTv = 0 Then Ms := -1 Else Ms := RdL(PTv) * 1000 + RdL(PTv + 4) Div 1000;
  T := KTicks;
  Repeat
    NetPoll;
    N := 0;
    For K := 0 To 2 Do
      For D := 0 To Nfds - 1 Do
        If ((Want[K, D Shr 5] Shr (D And 31)) And 1) <> 0 Then
        Begin
          S := SockOf(D);
          If S < 0 Then Rd := True
          Else
            Case K Of
              0 : Rd := SockReadable(S);
              1 : Rd := SockWritable(S);
            Else
              Rd := SState[S] = TS_RESET;
            End;
          If Rd Then
          Begin
            Got[K, D Shr 5] := Got[K, D Shr 5] Or (1 Shl (D And 31));
            Inc(N);
          End;
        End;
    If (N > 0) Or (Ms = 0) Or ((Ms > 0) And (KTicks - T >= Ms)) Then Break;
    Idle;
  Until False;
  For K := 0 To 2 Do
    If Sets[K] <> 0 Then
      For W := 0 To 3 Do
        If W * 32 < Nfds Then WrL(Sets[K] + W * 4, Got[K, W]);
  BsdSelect := N;
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
    If (N <= 0) And (Errno <> SOCETIMEDOUT) Then Break;
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

{ compteurs de la carte : P[0] trames recues, P[1] envoyees, P[2] octets
  recus, P[3] octets envoyes (boite de progression de l'Explorateur) }
Function TcpipStats(P : LongInt) : LongInt;
Begin
  WrL(P, RxPkts); WrL(P + 4, TxPkts); WrL(P + 8, RxBytes); WrL(P + 12, TxBytes);
  TcpipStats := 0;
End;

{ abandonner les attentes (Annuler d'une boite de progression, depuis un
  autre fil) : D >= 0 : le socket TCP D passe a l'etat RESET (connect,
  recv et send rendent aussitot une erreur ; rien n'est emis ici : les
  tampons de trame sont peut-etre en cours d'usage par le fil qui attend) ;
  D = -1 : les attentes en cours (DNS, ARP, connect) s'arretent }
Function SoAbort(D : LongInt) : LongInt;
Var S : LongInt;
Begin
  SoAbort := 0;
  If D < 0 Then
  Begin
    Inc(AbortGen);
    Exit;
  End;
  S := SockOf(D);
  If S < 0 Then
  Begin
    SoAbort := -1;
    Exit;
  End;
  If (SType[S] = T_TCP) And ((SState[S] = TS_SYNSENT) Or (SState[S] = TS_ESTAB) Or (SState[S] = TS_CLOSEWAIT) Or
     (SState[S] = TS_FINWAIT)) Then SState[S] := TS_RESET;
End;

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
  { [12] serveur DHCP (IPCONFIG /ALL) ; 0 : adresse fixe }
  WrL(P + 48, DhcpSrv);
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
  TcpipRenew Index 901 Name 'TCPIPRENEW',
  SoSystem Index 902 Name 'sosystem',
  SoAbort Index 903 Name 'soabort',
  TcpipStats Index 904 Name 'TCPIPSTATS',
  Os2Select Index 12 Name 'select',
  BsdSelect Index 32 Name 'bsdselect',
  Accept Index 1 Name 'accept',
  GetPeerName Index 5 Name 'getpeername',
  GetSockName Index 6 Name 'getsockname',
  GetSockOpt Index 7 Name 'getsockopt',
  Ioctl Index 8 Name 'ioctl',
  Listen Index 9 Name 'listen',
  SetSockOpt Index 15 Name 'setsockopt';

Var
  InitK : LongInt;

BEGIN
  DrvTried := 0; DrvFn := 0; Ready := 0; Dhcp := 0;
  MyIp := 0; Mask := 0; Gw := 0; Dns := 0; Lease := 0;
  IpId := 1; NextPort := 1100; Errno := 0; ArpNext := 0; RxPkts := 0; TxPkts := 0; RxBytes := 0; TxBytes := 0; AbortGen := 0;
  IsnGen := 0; AccGen := 0; LastGc := 0; LastTmr := 0; InPoll := False;
  For InitK := 0 To MAXS - 1 Do
  Begin
    SType[InitK] := 0; SBuf[InitK] := 0; SSys[InitK] := False; STx[InitK] := 0; STxCap[InitK] := 0;
    SParent[InitK] := -1; SPSlot[InitK] := -1; SOrphan[InitK] := False; SAccQ[InitK] := 0; SPool[InitK] := 0;
    SOwner[InitK] := 0; SNb[InitK] := 0;
  End;
  For InitK := 0 To MAXS * MAXPOOL - 1 Do PoolUse[InitK] := 0;
END.
