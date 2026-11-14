{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Pilote reseau E1000.DLL de OS/2-0 : Intel PRO/1000
                (82540EM, 82543GC, 82545EM : cartes de VirtualBox et QEMU).
}

Library E1000;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC E1000.PAS   (produit E1000.DLL)

  Pilote des cartes Ethernet Intel PRO/1000 sur le bus PCI : 82540EM
  (VirtualBox "Intel PRO/1000 MT Desktop", carte par defaut, et QEMU
  e1000), 82543GC (VirtualBox "PRO/1000 T Server"), 82545EM (VirtualBox
  "PRO/1000 MT Server", QEMU e1000-82545em), 82544GC, 82574L. Pour la
  pile TCP/IP (TCPIP32.DLL) : point d'entree unique NETREQUEST (ordinal
  1), paquet de LongInt :
    +0 commande, +4 etat rendu (0 bon)
    1 DETECTER  : rend +8 adresse de l'adresse MAC (6 octets), +12 nom
                  de la carte (ASCIIZ), +16 lien (1 actif)
    2 ENVOYER   : +8 adresse de la trame Ethernet, +12 longueur
    3 RECEVOIR  : +8 tampon, +12 taille ; rend +16 longueur (0 : rien)
    4 LIEN      : rend +8 (1 actif)
    5 DESCRIPTION : +8 tampon, +12 taille (gestionnaire de peripheriques)
    6 ARRETER
  Registres en memoire (BAR0) ; anneaux de descripteurs (16 en reception,
  8 en emission, tampons de 2 Ko) dans le tas du noyau, lus et ecrits par
  la carte (bus maitre) ; l'adresse MAC est celle que la carte a lue dans
  son EEPROM (registres RAL/RAH). Sans interruption : la pile interroge
  l'anneau de reception. }

Const
  NRX = 16; NTX = 8; BUFSZ = 2048;
  CTRL = $0000; STATUS = $0008; IMC = $00D8; RCTL = $0100; TCTL = $0400; TIPG = $0410;
  RDBAL = $2800; RDBAH = $2804; RDLEN = $2808; RDH = $2810; RDT = $2818;
  TDBAL = $3800; TDBAH = $3804; TDLEN = $3808; TDH = $3810; TDT = $3818;
  MTA = $5200; RAL0 = $5400; RAH0 = $5404;
  NIds = 7;
  Ids : Array[0..NIds - 1] Of LongInt = ($100E8086, $10048086, $100F8086, $10088086, $10098086, $10D38086,
                                         $100C8086);

Var
  Mmio, PciAddr, Irq, Found, DevId : LongInt;
  MemBlk, RxRing, TxRing, RxBuf, TxBuf, RxIdx, TxIdx : LongInt;
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

Function Reg(R : LongInt) : LongInt;
Begin
  Reg := RdL(Mmio + R);
End;

Procedure SetReg(R, V : LongInt);
Begin
  WrL(Mmio + R, V);
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
  Case DevId Of
    $100E : CardName := 'Intel PRO/1000 MT Desktop (82540EM)';
    $1004 : CardName := 'Intel PRO/1000 T Server (82543GC)';
    $100F : CardName := 'Intel PRO/1000 MT Server (82545EM)';
    $1008, $1009 : CardName := 'Intel PRO/1000 (82544)';
    $10D3 : CardName := 'Intel 82574L Gigabit';
  Else
    CardName := 'Intel PRO/1000';
  End;
End;

Function FindCard : Boolean;
Var Bus, Dev, A, Id, K : LongInt;
Begin
  FindCard := False;
  PciAddr := 0;
  For Bus := 0 To 7 Do
    For Dev := 0 To 31 Do
    Begin
      A := $80000000 Or (Bus Shl 16) Or (Dev Shl 11);
      Id := PciRead(A, 0);
      If (Id <> -1) And (PciAddr = 0) Then
        For K := 0 To NIds - 1 Do
          If Id = Ids[K] Then
          Begin
            PciAddr := A;
            DevId := (Id Shr 16) And $FFFF;
          End;
    End;
  If PciAddr = 0 Then Exit;
  Mmio := PciRead(PciAddr, $10) And $FFFFFFF0;
  Irq := PciRead(PciAddr, $3C) And 255;
  { memoire et bus maitre }
  PciWrite(PciAddr, 4, PciRead(PciAddr, 4) Or 6);
  FindCard := Mmio <> 0;
End;

Function CardInit : Boolean;
Var K, V : LongInt;
Begin
  CardInit := False;
  If Not FindCard Then Exit;
  { remise a zero }
  SetReg(IMC, -1);
  SetReg(CTRL, Reg(CTRL) Or $04000000);
  WaitIo(2000);
  K := 0;
  While ((Reg(CTRL) And $04000000) <> 0) And (K < 100000) Do Inc(K);
  SetReg(IMC, -1);
  { lien : SLU, ASDE ; sans remise a zero du lien ni du PHY }
  V := Reg(CTRL);
  V := (V Or $60) And Not ($08 Or $80 Or $80000000);
  SetReg(CTRL, V);
  { adresse MAC (chargee de l'EEPROM) }
  V := Reg(RAL0);
  Mac[0] := V And 255; Mac[1] := (V Shr 8) And 255; Mac[2] := (V Shr 16) And 255; Mac[3] := (V Shr 24) And 255;
  V := Reg(RAH0);
  Mac[4] := V And 255; Mac[5] := (V Shr 8) And 255;
  SetReg(RAH0, Reg(RAH0) Or $80000000);           { adresse valable }
  For K := 0 To 127 Do SetReg(MTA + K * 4, 0);
  { anneaux et tampons : 16 et 8 descripteurs de 16 octets, alignes }
  If MemBlk = 0 Then MemBlk := HeapAlloc(2, 8, 4096 + NRX * 16 + NTX * 16 + (NRX + NTX) * BUFSZ);
  If MemBlk = 0 Then Exit;
  RxRing := (MemBlk + 255) And Not 255;
  TxRing := RxRing + NRX * 16;
  RxBuf := (TxRing + NTX * 16 + 15) And Not 15;
  TxBuf := RxBuf + NRX * BUFSZ;
  For K := 0 To NRX - 1 Do
  Begin
    WrL(RxRing + K * 16, RxBuf + K * BUFSZ); WrL(RxRing + K * 16 + 4, 0);
    WrL(RxRing + K * 16 + 8, 0); WrL(RxRing + K * 16 + 12, 0);
  End;
  For K := 0 To NTX - 1 Do
  Begin
    WrL(TxRing + K * 16, TxBuf + K * BUFSZ); WrL(TxRing + K * 16 + 4, 0);
    WrL(TxRing + K * 16 + 8, 0); WrL(TxRing + K * 16 + 12, 1);          { DD : libre }
  End;
  SetReg(RDBAL, RxRing); SetReg(RDBAH, 0); SetReg(RDLEN, NRX * 16);
  SetReg(RDH, 0); SetReg(RDT, NRX - 1);
  SetReg(TDBAL, TxRing); SetReg(TDBAH, 0); SetReg(TDLEN, NTX * 16);
  SetReg(TDH, 0); SetReg(TDT, 0);
  RxIdx := 0; TxIdx := 0;
  { reception : EN, BAM (diffusion), MPE, tampons de 2 Ko, sans CRC }
  SetReg(RCTL, $02 Or $10 Or $8000 Or $04000000);
  { emission : EN, PSP, CT = 0Fh, COLD = 40h }
  SetReg(TIPG, $0060200A);
  SetReg(TCTL, $02 Or $08 Or ($0F Shl 4) Or ($40 Shl 12));
  PutStr(LongInt(@NameBuf), CardName, 64);
  Found := 1;
  CardInit := True;
End;

Function LinkUp : LongInt;
Begin
  If (Reg(STATUS) And 2) <> 0 Then LinkUp := 1 Else LinkUp := 0;
End;

Function SendFrame(A, N : LongInt) : LongInt;
Var D, K : LongInt;
Begin
  SendFrame := 1;
  If (N <= 0) Or (N > 1514) Then Exit;
  D := TxRing + TxIdx * 16;
  { descripteur libre (DD) ? }
  K := 0;
  While ((RdL(D + 12) And 1) = 0) And (K < 200000) Do Inc(K);
  If (RdL(D + 12) And 1) = 0 Then Exit;
  MoveMem(A, TxBuf + TxIdx * BUFSZ, N);
  If N < 60 Then
  Begin
    For K := N To 59 Do WrB(TxBuf + TxIdx * BUFSZ + K, 0);
    N := 60;
  End;
  WrL(D + 4, 0);
  { longueur, CMD = EOP (1) + IFCS (2) + RS (8) ; etat efface }
  WrL(D + 8, N Or ($0B Shl 24));
  WrL(D + 12, 0);
  TxIdx := (TxIdx + 1) Mod NTX;
  SetReg(TDT, TxIdx);
  Inc(TxCount);
  SendFrame := 0;
End;

Function RecvFrame(A, Max : LongInt) : LongInt;
Var D, St, N : LongInt;
Begin
  RecvFrame := 0;
  D := RxRing + RxIdx * 16;
  St := RdL(D + 12);
  If (St And 1) = 0 Then Exit;                     { DD : rien de recu }
  N := RdL(D + 8) And $FFFF;
  If ((St And 2) <> 0) And ((St And $FF00) = 0) And (N > 0) Then
  Begin
    If N > Max Then N := Max;
    MoveMem(RxBuf + RxIdx * BUFSZ, A, N);
    RecvFrame := N;
    Inc(RxCount);
  End;
  WrL(D + 8, 0); WrL(D + 12, 0);
  SetReg(RDT, RxIdx);
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
        PutStr(RdL(P + 8), CardName + ' (PCI 8086:' + HexN(DevId, 4) + '), memoire ' + HexN(Mmio, 8) + 'h, IRQ ' +
               IStr(Irq) + ', MAC ' + HexN(Mac[0], 2) + ':' + HexN(Mac[1], 2) + ':' + HexN(Mac[2], 2) + ':' +
               HexN(Mac[3], 2) + ':' + HexN(Mac[4], 2) + ':' + HexN(Mac[5], 2) + ', trames recues ' +
               IStr(RxCount) + ', envoyees ' + IStr(TxCount), RdL(P + 12))
      Else PutStr(RdL(P + 8), 'Carte Intel PRO/1000 absente', RdL(P + 12));
    6 :
      Begin
        SetReg(RCTL, 0); SetReg(TCTL, 0);
      End;
  Else
    WrL(P + 4, 3);
  End;
  NetRequest := RdL(P + 4);
End;

Exports
  NetRequest Index 1 Name 'NETREQUEST';

BEGIN
  Found := 0; MemBlk := 0; RxCount := 0; TxCount := 0;
  PutStr(LongInt(@NameBuf), 'Intel PRO/1000', 64);
END.
