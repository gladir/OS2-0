{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Pilote audio ESAUDIO.DLL de OS/2-0 : Ensoniq AudioPCI
                (ES1370) et Creative Sound Blaster PCI 64/128 (ES1370).
}

Library ESAUDIO;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC ESAUDIO.PAS   (produit ESAUDIO.DLL)

  Pilote de l'Ensoniq AudioPCI ES1370 (aussi vendu comme Creative Sound
  Blaster PCI 64), bus PCI (fabricant 1274h, modele 5000h), pour
  MDM.DLL. Meme interface que SBAUDIO.DLL : point d'entree AUDIOSTRATEGY
  (ordinal 1) et paquet de requete.

  La puce lit la memoire elle-meme (bus maitre) : lecture par le canal
  DAC2, enregistrement par le canal ADC, en mode boucle sur un tampon
  circulaire de 64 Ko (registres de trame des pages memoire 0Ch et 0Dh :
  adresse, puis taille en mots de 32 bits - 1 ; le mot haut donne la
  position courante). 8 ou 16 bits, mono ou stereo (registre de controle
  serie) ; frequence : diviseur PCLKDIV du registre de controle,
  1 411 200 / (diviseur + 2) Hz (commun a DAC2 et a l'ADC). Le codec
  AK4531 (volumes, melangeur) est programme par le registre 10h. }

Const
  RING = 65536;
  CTRL = $00; STATUS = $04; MEMPAGE = $0C; CODEC = $10; SCTRL = $20;
  DAC2CNT = $28; ADCCNT = $2C;
  CTRL_ADC_EN = $10; CTRL_DAC2_EN = $20; CTRL_CDC_EN = $02;

Var
  Io, PciAddr, Found : LongInt;
  RingMem, RingAddr : LongInt;
  CurDir, CurRate, CurBits, CurCh, Running, CtrlV : LongInt;
  NameBuf : Array[0..63] Of Byte;
  Dummy0 : LongInt;

Function HeapAlloc(Heap, Flags, Size : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';

{ ==================================================================== }
{ Ports                                                                 }
{ ==================================================================== }

Procedure OutB(P, V : LongInt);
Begin
  asm
    mov edx,P
    mov eax,V
    out dx,al
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

Procedure OutL(P, V : LongInt);
Begin
  asm
    mov edx,P
    mov eax,V
    out dx,eax
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

Function PciRead(A, Reg : LongInt) : LongInt;
Begin
  OutL($CF8, A Or (Reg And $FC));
  PciRead := InL($CFC);
End;

Procedure PciWrite(A, Reg, V : LongInt);
Begin
  OutL($CF8, A Or (Reg And $FC));
  OutL($CFC, V);
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

Procedure PutName(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do NameBuf[K - 1] := Ord(S[K]);
  NameBuf[Length(S)] := 0;
End;

{ ==================================================================== }
{ Codec AK4531                                                          }
{ ==================================================================== }

Procedure CodecW(R, V : LongInt);
Var K : LongInt;
Begin
  K := 0;
  While ((InL(Io + STATUS) And $200) <> 0) And (K < 10000) Do Inc(K);
  OutW(Io + CODEC, ((R And 255) Shl 8) Or (V And 255));
End;

{ ==================================================================== }
{ Detection                                                             }
{ ==================================================================== }

Function FindCtl : Boolean;
Var Bus, Dev, Fn, A, Id : LongInt;
Begin
  FindCtl := False;
  For Bus := 0 To 7 Do
    For Dev := 0 To 31 Do
      For Fn := 0 To 7 Do
      Begin
        A := $80000000 Or (Bus Shl 16) Or (Dev Shl 11) Or (Fn Shl 8);
        Id := PciRead(A, 0);
        If (Id = $50001274) And (PciAddr = 0) Then PciAddr := A;
      End;
  FindCtl := PciAddr <> 0;
End;

Function EsDetect : Boolean;
Begin
  EsDetect := False;
  PciAddr := 0;
  If Not FindCtl Then Exit;
  Io := PciRead(PciAddr, $10) And $FFFC;
  If Io = 0 Then Exit;
  PciWrite(PciAddr, 4, PciRead(PciAddr, 4) Or 5);
  { interface du codec, puis AK4531 : remise a zero, volumes au maximum,
    melangeur de sortie (voix, DAC2) et entree d'enregistrement (ligne) }
  CtrlV := CTRL_CDC_EN;
  OutL(Io + CTRL, CtrlV);
  OutL(Io + SCTRL, 0);
  CodecW($16, $02);
  Dummy0 := DosSleep(5);
  CodecW($16, $03);
  CodecW($17, $00);
  CodecW($00, $00); CodecW($01, $00);            { volume general }
  CodecW($02, $00); CodecW($03, $00);            { volume de la voix }
  CodecW($10, $00); CodecW($11, $0C);            { sortie : voix G et D }
  CodecW($12, $10); CodecW($13, $08);            { enregistrement : ligne }
  CodecW($14, $10); CodecW($15, $08);
  If RingMem = 0 Then RingMem := HeapAlloc(2, 8, RING + 4096);
  If RingMem = 0 Then Exit;
  RingAddr := (RingMem + 4095) And Not 4095;
  PutName('Ensoniq AudioPCI ES1370');
  Found := 1;
  EsDetect := True;
End;

{ ==================================================================== }
{ Transfert                                                             }
{ ==================================================================== }

Procedure OpenFmt(P : LongInt);
Var Rate, Bits, Ch, Dv : LongInt;
Begin
  CurDir := RdL(P + 8); Rate := RdL(P + 12); Bits := RdL(P + 16); Ch := RdL(P + 20);
  If (Bits <> 8) And (Bits <> 16) Then Bits := 16;
  If (Ch <> 1) And (Ch <> 2) Then Ch := 1;
  If Rate < 4000 Then Rate := 4000;
  If Rate > 48000 Then Rate := 48000;
  Dv := 1411200 Div Rate - 2;
  CurRate := 1411200 Div (Dv + 2);
  CtrlV := (CtrlV And Not $1FFF0000) Or ((Dv And $1FFF) Shl 16);
  OutL(Io + CTRL, CtrlV);
  CurBits := Bits; CurCh := Ch;
  WrL(P + 24, CurRate); WrL(P + 28, Bits); WrL(P + 32, Ch);
  WrL(P + 36, RingAddr); WrL(P + 40, RING);
End;

Procedure StartIo;
Var Fmt, Sc, Smp : LongInt;
Begin
  Fmt := 0;
  If CurBits = 16 Then Fmt := Fmt Or 2;
  If CurCh = 2 Then Fmt := Fmt Or 1;
  Smp := RING Div ((CurBits Div 8) * CurCh);
  Sc := InL(Io + SCTRL);
  If CurDir = 0 Then
  Begin
    { DAC2 : page 0Ch, adresse 38h, taille 3Ch ; format bits 2-3 }
    OutL(Io + MEMPAGE, $0C);
    OutL(Io + $38, RingAddr);
    OutL(Io + $3C, RING Div 4 - 1);
    Sc := (Sc And Not ($0C Or $1000 Or $4000)) Or (Fmt Shl 2);
    OutL(Io + SCTRL, Sc);
    OutL(Io + DAC2CNT, Smp Div 2 - 1);
    CtrlV := CtrlV Or CTRL_DAC2_EN;
  End
  Else
  Begin
    { ADC : page 0Dh, adresse 30h, taille 34h ; format bits 4-5 }
    OutL(Io + MEMPAGE, $0D);
    OutL(Io + $30, RingAddr);
    OutL(Io + $34, RING Div 4 - 1);
    Sc := (Sc And Not ($30 Or $8000)) Or (Fmt Shl 4);
    OutL(Io + SCTRL, Sc);
    OutL(Io + ADCCNT, Smp Div 2 - 1);
    CtrlV := CtrlV Or CTRL_ADC_EN;
  End;
  OutL(Io + CTRL, CtrlV);
  Running := 1;
End;

Procedure StopIo;
Begin
  If Running = 0 Then Exit;
  CtrlV := CtrlV And Not (CTRL_DAC2_EN Or CTRL_ADC_EN);
  OutL(Io + CTRL, CtrlV);
  Running := 0;
End;

Function Position : LongInt;
Var V : LongInt;
Begin
  If CurDir = 0 Then
  Begin
    OutL(Io + MEMPAGE, $0C);
    V := InL(Io + $3C);
  End
  Else
  Begin
    OutL(Io + MEMPAGE, $0D);
    V := InL(Io + $34);
  End;
  Position := (((V Shr 16) And $FFFF) * 4) Mod RING;
End;

Procedure SetVolume(V : LongInt);
Var A : LongInt;
Begin
  If V < 0 Then V := 0;
  If V > 100 Then V := 100;
  If V = 0 Then A := $80 Else A := ((100 - V) * 31) Div 100;
  CodecW($00, A); CodecW($01, A);
End;

Function AudioStrategy(P : LongInt) : LongInt;
Var Cmd : LongInt; Ok : Boolean;
Begin
  Cmd := RdL(P);
  WrL(P + 4, 0);
  If (Cmd <> 1) And (Found = 0) Then
  Begin
    WrL(P + 4, 19);
    AudioStrategy := 19;
    Exit;
  End;
  Case Cmd Of
    1 :
      Begin
        Ok := EsDetect;
        If Ok Then
        Begin
          WrL(P + 12, 3);
          WrL(P + 16, LongInt(@NameBuf));
        End;
        If Not Ok Then WrL(P + 4, 20);
      End;
    2 :
      Begin
        StopIo;
        OpenFmt(P);
      End;
    3 : StartIo;
    4 :
      Begin
        If Running <> 0 Then WrL(P + 8, Position) Else WrL(P + 8, 0);
      End;
    5, 7 : StopIo;
    6 : SetVolume(RdL(P + 8));
  Else
    WrL(P + 4, 3);
  End;
  AudioStrategy := RdL(P + 4);
End;

Exports
  AudioStrategy Index 1 Name 'AUDIOSTRATEGY';

BEGIN
  Found := 0; RingMem := 0; Running := 0; PciAddr := 0; CtrlV := 0;
  PutName('AudioPCI');
END.
