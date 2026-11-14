{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Pilote reseau PCNET.DLL de OS/2-0 : AMD PCnet-PCI II
                (Am79C970A) et PCnet-FAST III (Am79C973) : VirtualBox, QEMU.
}

Library PCNET;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC PCNET.PAS   (produit PCNET.DLL)

  Pilote des cartes Ethernet AMD PCnet du bus PCI (1022h:2000h) :
  PCnet-PCI II Am79C970A (VirtualBox "PCnet-PCI II", QEMU pcnet) et
  PCnet-FAST III Am79C973 (VirtualBox "PCnet-FAST III", carte par defaut
  des machines OS/2 et DOS). Meme interface que E1000.DLL (point d'entree
  NETREQUEST, ordinal 1, paquet de requete).
  La carte passe en mode 32 bits (ecriture d'un mot double dans RDP),
  structures du style 2 (BCR20 = 2 : descripteurs de 16 octets) ; bloc
  d'initialisation (adresse MAC lue dans l'APROM, anneaux de 16
  descripteurs en reception et 8 en emission, tampons de 1,5 Ko) ; CSR0 :
  INIT puis STRT, TDMD pour envoyer. Sans interruption (IENA a 0). }

Const
  NRX = 16; NTX = 8; BUFSZ = 1544;
  RDP = $10; RAP = $14; RST = $18; BDP = $1C;

Var
  Io, PciAddr, Irq, Found, Chip : LongInt;
  MemBlk, Init, RxRing, TxRing, RxBuf, TxBuf, RxIdx, TxIdx : LongInt;
  Mac : Array[0..7] Of Byte;
  NameBuf : Array[0..63] Of Byte;
  RxCount, TxCount : LongInt;
  Dummy0 : LongInt;

Function HeapAlloc(Heap, Flags, Size : LongInt) : LongInt; External 'DOSCALLS';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Procedure OutL(P, V : LongInt);
Begin
  asm
    mov edx,P
    mov eax,V
    out dx,eax
  end;
End;

Function InL(P : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  asm
    mov edx,P
    in eax,dx
    mov R,eax
  end;
  InL := R;
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

Procedure OutW(P, V : LongInt);
Begin
  asm
    mov edx,P
    mov eax,V
    out dx,ax
  end;
End;

Function InB(P : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  asm
    mov edx,P
    xor eax,eax
    in al,dx
    mov R,eax
  end;
  InB := R;
End;

Function InW(P : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  asm
    mov edx,P
    xor eax,eax
    in ax,dx
    mov R,eax
  end;
  InW := R;
End;

Function Csr(N : LongInt) : LongInt;
Begin
  OutL(Io + RAP, N);
  Csr := InL(Io + RDP) And $FFFF;
End;

Procedure SetCsr(N, V : LongInt);
Begin
  OutL(Io + RAP, N);
  OutL(Io + RDP, V);
End;

Function Bcr(N : LongInt) : LongInt;
Begin
  OutL(Io + RAP, N);
  Bcr := InL(Io + BDP) And $FFFF;
End;

Procedure SetBcr(N, V : LongInt);
Begin
  OutL(Io + RAP, N);
  OutL(Io + BDP, V);
End;

Function PciRead(A, R : LongInt) : LongInt;
Begin
  OutL($CF8, A Or (R And $FC));
  PciRead := InL($CFC);
End;

Procedure PciWrite(A, R, V : LongInt);
Begin
  OutL($CF8, A Or (R And $FC));
  OutL($CFC, V);
End;

Procedure PutStr(A : LongInt; S : String; Max : LongInt);
Var K : LongInt;
Begin
  If Length(S) > Max - 1 Then S := Copy(S, 1, Max - 1);
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function HexN(V, N : LongInt) : String;
Var S : String; K, D : LongInt;
Begin
  S := '';
  For K := N - 1 DownTo 0 Do
  Begin
    D := (V Shr (K * 4)) And 15;
    If D < 10 Then S := S + Chr(48 + D) Else S := S + Chr(55 + D);
  End;
  HexN := S;
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Procedure WaitIo(N : LongInt);
Var K : LongInt;
Begin
  For K := 1 To N Do Dummy0 := InL($80);
End;

{ ==================================================================== }
{ Carte                                                                 }
{ ==================================================================== }

Function CardName : String;
Begin
  If Chip = $2625 Then CardName := 'AMD PCnet-FAST III (Am79C973)'
  Else If Chip = $2624 Then CardName := 'AMD PCnet-FAST (Am79C972)'
  Else If Chip = $2621 Then CardName := 'AMD PCnet-PCI II (Am79C970A)'
  Else CardName := 'AMD PCnet-PCI';
End;

Function FindCard : Boolean;
Var Bus, Dev, A : LongInt;
Begin
  FindCard := False;
  PciAddr := 0;
  For Bus := 0 To 7 Do
    For Dev := 0 To 31 Do
    Begin
      A := $80000000 Or (Bus Shl 16) Or (Dev Shl 11);
      If (PciAddr = 0) And (PciRead(A, 0) = $20001022) Then PciAddr := A;
    End;
  If PciAddr = 0 Then Exit;
  Io := PciRead(PciAddr, $10) And $FFFC;
  Irq := PciRead(PciAddr, $3C) And 255;
  { entrees-sorties et bus maitre }
  PciWrite(PciAddr, 4, PciRead(PciAddr, 4) Or 5);
  FindCard := Io <> 0;
End;

Function CardInit : Boolean;
Var K, V : LongInt;
Begin
  CardInit := False;
  If Not FindCard Then Exit;
  { remise a zero (lectures du registre RESET en 16 puis 32 bits), puis
    mode 32 bits (DWIO) : ecriture d'un mot double dans RDP }
  Dummy0 := InW(Io + $14);
  Dummy0 := InL(Io + RST);
  WaitIo(200);
  OutL(Io + RDP, 0);
  { arret ; structures de 32 bits (style 2) ; puce (CSR88/89) }
  SetCsr(0, 4);
  SetBcr(20, (Bcr(20) And Not $FF) Or 2);
  Chip := ((Csr(89) Shl 16) Or Csr(88)) Shr 12 And $FFFF;
  { adresse MAC : APROM }
  For K := 0 To 5 Do Mac[K] := InB(Io + K);
  { memoire : bloc d'initialisation, anneaux, tampons }
  If MemBlk = 0 Then MemBlk := HeapAlloc(2, 8, 256 + 32 + (NRX + NTX) * 16 + (NRX + NTX) * BUFSZ);
  If MemBlk = 0 Then Exit;
  Init := (MemBlk + 15) And Not 15;
  RxRing := Init + 32;
  TxRing := RxRing + NRX * 16;
  RxBuf := TxRing + NTX * 16;
  TxBuf := RxBuf + NRX * BUFSZ;
  For K := 0 To NRX - 1 Do
  Begin
    WrL(RxRing + K * 16, RxBuf + K * BUFSZ);
    WrL(RxRing + K * 16 + 4, $80000000 Or $F000 Or ((-BUFSZ) And $FFF));    { OWN : a la carte }
    WrL(RxRing + K * 16 + 8, 0); WrL(RxRing + K * 16 + 12, 0);
  End;
  For K := 0 To NTX - 1 Do
  Begin
    WrL(TxRing + K * 16, TxBuf + K * BUFSZ);
    WrL(TxRing + K * 16 + 4, $F000);
    WrL(TxRing + K * 16 + 8, 0); WrL(TxRing + K * 16 + 12, 0);
  End;
  { bloc d'initialisation : MODE 0, RLEN = log2(16) = 4, TLEN = log2(8) = 3 }
  WrL(Init, 0 Or ((4 Shl 4) Shl 16) Or ((3 Shl 4) Shl 24));
  For K := 0 To 5 Do WrB(Init + 4 + K, Mac[K]);
  WrB(Init + 10, 0); WrB(Init + 11, 0);
  WrL(Init + 12, 0); WrL(Init + 16, 0);              { pas de multidiffusion }
  WrL(Init + 20, RxRing); WrL(Init + 24, TxRing);
  SetCsr(1, Init And $FFFF);
  SetCsr(2, (Init Shr 16) And $FFFF);
  { CSR4 : remplissage automatique des trames courtes (APAD_XMT) }
  SetCsr(4, Csr(4) Or $0800);
  SetCsr(0, 1);                                      { INIT }
  K := 0;
  While ((Csr(0) And $0100) = 0) And (K < 100000) Do Inc(K);
  If (Csr(0) And $0100) = 0 Then Exit;
  SetCsr(0, $0102);                                  { STRT, IDON efface }
  RxIdx := 0; TxIdx := 0;
  PutStr(LongInt(@NameBuf), CardName, 64);
  Found := 1;
  CardInit := True;
End;

Function LinkUp : LongInt;
Begin
  { BCR4 : bit 15 = lien (LNKST) ; sans PHY lisible : actif si la carte
    tourne }
  If ((Bcr(4) And $8000) <> 0) Or ((Csr(0) And $0002) <> 0) Then LinkUp := 1 Else LinkUp := 0;
End;

Function SendFrame(A, N : LongInt) : LongInt;
Var D, K : LongInt;
Begin
  SendFrame := 1;
  If (N <= 0) Or (N > 1514) Then Exit;
  D := TxRing + TxIdx * 16;
  K := 0;
  While ((RdL(D + 4) And $80000000) <> 0) And (K < 200000) Do Inc(K);
  If (RdL(D + 4) And $80000000) <> 0 Then Exit;
  MoveMem(A, TxBuf + TxIdx * BUFSZ, N);
  If N < 60 Then
  Begin
    For K := N To 59 Do WrB(TxBuf + TxIdx * BUFSZ + K, 0);
    N := 60;
  End;
  WrL(D + 8, 0);
  { OWN, STP, ENP, longueur en complement a deux }
  WrL(D + 4, $80000000 Or $02000000 Or $01000000 Or $F000 Or ((-N) And $FFF));
  TxIdx := (TxIdx + 1) Mod NTX;
  SetCsr(0, $0008 Or $0002);                         { TDMD }
  Inc(TxCount);
  SendFrame := 0;
End;

Function RecvFrame(A, Max : LongInt) : LongInt;
Var D, St, N : LongInt;
Begin
  RecvFrame := 0;
  D := RxRing + RxIdx * 16;
  St := RdL(D + 4);
  If (St And $80000000) <> 0 Then Exit;              { encore a la carte }
  N := (RdL(D + 8) And $FFF) - 4;                     { sans le CRC }
  If ((St And $40000000) = 0) And ((St And $03000000) = $03000000) And (N > 0) Then
  Begin
    If N > Max Then N := Max;
    MoveMem(RxBuf + RxIdx * BUFSZ, A, N);
    RecvFrame := N;
    Inc(RxCount);
  End;
  WrL(D + 8, 0);
  WrL(D + 4, $80000000 Or $F000 Or ((-BUFSZ) And $FFF));
  RxIdx := (RxIdx + 1) Mod NRX;
End;

Function NetRequest(P : LongInt) : LongInt;
Var Cmd : LongInt; Ok : Boolean;
Begin
  Cmd := RdL(P);
  WrL(P + 4, 0);
  If (Cmd <> 1) And (Cmd <> 5) And (Found = 0) Then
  Begin
    WrL(P + 4, 19);
    NetRequest := 19;
    Exit;
  End;
  Case Cmd Of
    1 :
      Begin
        Ok := (Found <> 0) Or CardInit;
        If Ok Then
        Begin
          WrL(P + 8, LongInt(@Mac)); WrL(P + 12, LongInt(@NameBuf)); WrL(P + 16, LinkUp);
        End;
        If Not Ok Then WrL(P + 4, 20);
      End;
    2 : WrL(P + 4, SendFrame(RdL(P + 8), RdL(P + 12)));
    3 : WrL(P + 16, RecvFrame(RdL(P + 8), RdL(P + 12)));
    4 : WrL(P + 8, LinkUp);
    5 :
      If Found <> 0 Then
        PutStr(RdL(P + 8), CardName + ' (PCI 1022:2000), port ' + HexN(Io, 4) + 'h, IRQ ' + IStr(Irq) + ', MAC ' +
               HexN(Mac[0], 2) + ':' + HexN(Mac[1], 2) + ':' + HexN(Mac[2], 2) + ':' + HexN(Mac[3], 2) + ':' +
               HexN(Mac[4], 2) + ':' + HexN(Mac[5], 2) + ', trames recues ' + IStr(RxCount) + ', envoyees ' +
               IStr(TxCount), RdL(P + 12))
      Else PutStr(RdL(P + 8), 'Carte AMD PCnet absente', RdL(P + 12));
    6 : SetCsr(0, 4);
  Else
    WrL(P + 4, 3);
  End;
  NetRequest := RdL(P + 4);
End;

Exports
  NetRequest Index 1 Name 'NETREQUEST';

BEGIN
  Found := 0; MemBlk := 0; RxCount := 0; TxCount := 0; Chip := 0;
  PutStr(LongInt(@NameBuf), 'AMD PCnet', 64);
END.
