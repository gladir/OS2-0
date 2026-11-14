{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: PING - echo ICMP vers un hote (TCPIP32.DLL) d'OS/2-0.
}

Program PING;

{$R-,S-,I-}

{ Compilation : OS2PC PING.PAS   (produit PING.EXE)

  PING hote [nombre] : envoie des demandes d'echo ICMP (56 octets de
  donnees, une par seconde, 4 par defaut) par un socket brut et affiche
  les reponses (temps aller-retour, TTL) et le bilan. L'hote est un nom
  (DNS) ou une adresse a.b.c.d. }

Function SockInit : LongInt; External 'TCPIP32' Name 'sock_init';
Function Socket(D, T, P : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function SendTo(S, B, L, F, A, AL : LongInt) : LongInt; External 'TCPIP32' Name 'sendto';
Function RecvFrom(S, B, L, F, A, PAL : LongInt) : LongInt; External 'TCPIP32' Name 'recvfrom';
Function SoClose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function GetHostByName(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';

Var
  Pkt, Rep : Array[0..1599] Of Byte;
  Addr, From : Array[0..15] Of Byte;
  NameB : Array[0..255] Of Byte;
  S, H, A, K, N, Count, Sent, Got, T0, Dt, Ihl, Ttl, Seq, Id, MinT, MaxT, SumT, C, AL, Sum : LongInt;
  Name, IpS : String;

Function RdL(X : LongInt) : LongInt;
Type PL = ^LongInt;
Var Q : PL;
Begin
  Q := Pointer(X);
  RdL := Q^;
End;

Function RdB(X : LongInt) : LongInt;
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(X);
  RdB := Q^;
End;

Function MaxI0(V : LongInt) : LongInt;
Begin
  If V < 1 Then MaxI0 := 1 Else MaxI0 := V;
End;

Function Cks(Len : LongInt) : LongInt;
Var I, V : LongInt;
Begin
  V := 0;
  I := 0;
  While I + 1 < Len Do
  Begin
    V := V + (Pkt[I] Shl 8) + Pkt[I + 1];
    I := I + 2;
  End;
  If I < Len Then V := V + (Pkt[I] Shl 8);
  While (V Shr 16) <> 0 Do V := (V And $FFFF) + (V Shr 16);
  Cks := (Not V) And $FFFF;
End;

BEGIN
  If ParamCount < 1 Then
  Begin
    Writeln('PING hote [nombre] : echo ICMP vers l''hote (nom ou adresse a.b.c.d).');
    Halt(1);
  End;
  Name := ParamStr(1);
  Count := 4;
  If ParamCount >= 2 Then
  Begin
    Val(ParamStr(2), Count, C);
    If (C <> 0) Or (Count < 1) Then Count := 4;
  End;
  If SockInit <> 0 Then
  Begin
    Writeln('PING : le reseau n''est pas disponible (carte, DHCP).');
    Halt(1);
  End;
  For K := 1 To Length(Name) Do NameB[K - 1] := Ord(Name[K]);
  NameB[Length(Name)] := 0;
  H := GetHostByName(LongInt(@NameB));
  If H = 0 Then
  Begin
    Writeln('PING : hote inconnu : ', Name);
    Halt(1);
  End;
  A := RdL(RdL(H + 16));
  For K := 0 To 15 Do Addr[K] := 0;
  Addr[0] := 16; Addr[1] := 2;
  For K := 0 To 3 Do Addr[4 + K] := RdB(A + K);
  Str(Addr[4], IpS); Str(Addr[5], Name); IpS := IpS + '.' + Name;
  Str(Addr[6], Name); IpS := IpS + '.' + Name; Str(Addr[7], Name); IpS := IpS + '.' + Name;
  S := Socket(2, 3, 1);
  If S < 0 Then
  Begin
    Writeln('PING : socket impossible.');
    Halt(1);
  End;
  Writeln('PING ', ParamStr(1), ' (', IpS, ') : 56 octets de donnees');
  Id := KTicks And $FFFF;
  Sent := 0; Got := 0; MinT := 999999; MaxT := 0; SumT := 0;
  For Seq := 0 To Count - 1 Do
  Begin
    { echo demande : type 8, code 0, identifiant, numero, 56 octets }
    For K := 0 To 63 Do Pkt[K] := K And 255;
    Pkt[0] := 8; Pkt[1] := 0; Pkt[2] := 0; Pkt[3] := 0;
    Pkt[4] := Id Shr 8; Pkt[5] := Id And 255; Pkt[6] := Seq Shr 8; Pkt[7] := Seq And 255;
    Sum := Cks(64);
    Pkt[2] := Sum Shr 8; Pkt[3] := Sum And 255;
    T0 := KTicks;
    If SendTo(S, LongInt(@Pkt), 64, 0, LongInt(@Addr), 16) = 64 Then Inc(Sent);
    { reponse : paquet IP entier (socket brut) }
    N := 0;
    Repeat
      AL := 16;
      N := RecvFrom(S, LongInt(@Rep), 1600, 0, LongInt(@From), LongInt(@AL));
      If N > 28 Then
      Begin
        Ihl := (Rep[0] And 15) * 4;
        If (Rep[Ihl] = 0) And (((Rep[Ihl + 4] Shl 8) Or Rep[Ihl + 5]) = Id) And
           (((Rep[Ihl + 6] Shl 8) Or Rep[Ihl + 7]) = Seq) Then
        Begin
          Dt := KTicks - T0;
          Ttl := Rep[8];
          Writeln(N - Ihl, ' octets de ', IpS, ' : icmp_seq=', Seq, ' ttl=', Ttl, ' temps=', Dt, ' ms');
          Inc(Got);
          If Dt < MinT Then MinT := Dt;
          If Dt > MaxT Then MaxT := Dt;
          SumT := SumT + Dt;
          N := -2;
        End;
      End;
    Until (N = -1) Or (N = -2) Or (KTicks - T0 > 3000);
    If N <> -2 Then Writeln('Pas de reponse (icmp_seq=', Seq, ').');
    Dt := KTicks - T0;
    If (Seq < Count - 1) And (Dt < 1000) Then K := DosSleep(1000 - Dt);
  End;
  K := SoClose(S);
  Writeln('--- ', ParamStr(1), ' : ', Sent, ' paquets envoyes, ', Got, ' recus, ',
          ((Sent - Got) * 100) Div MaxI0(Sent), '% perdus');
  If Got > 0 Then Writeln('aller-retour min/moy/max = ', MinT, '/', SumT Div Got, '/', MaxT, ' ms');
  If Got = 0 Then Halt(1);
END.
