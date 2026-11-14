{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Pilote audio ICHAUDIO.DLL de OS/2-0 : controleurs AC'97
                Intel ICH (82801AA ... ICH7) et compatibles.
}

Library ICHAUDIO;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC ICHAUDIO.PAS   (produit ICHAUDIO.DLL)

  Pilote des controleurs audio AC'97 des jeux de composants Intel (ICH,
  ICH0, ICH2 a ICH7, 440MX) et des compatibles (nVidia nForce, AMD-8111),
  sur le bus PCI, pour MDM.DLL. Meme interface que SBAUDIO.DLL : point
  d'entree AUDIOSTRATEGY (ordinal 1) et paquet de requete (DETECTER,
  OUVRIR, DEMARRER, POSITION, ARRETER, VOLUME, FERMER).

  Detection : recherche sur le bus PCI (ports CF8h/CFCh) d'un appareil de
  classe 0401h (audio) d'un fabricant et d'un modele connus ; BAR0 :
  registres du codec (NAMBAR), BAR1 : maitre du bus (NABMBAR). Le pilote
  active les entrees-sorties et le bus maitre, fait la remise a zero a
  froid du lien AC'97, attend le codec, regle les volumes et la frequence
  variable (VRA : registres 2Ch et 32h, sinon 48 000 Hz).

  Transfert : 16 bits stereo (MDM convertit les autres formats). Le
  tampon circulaire (64 Ko du tas du noyau) est decrit par une liste de
  32 descripteurs de 2 Ko (BDL) ; le controleur la parcourt en boucle : a
  chaque lecture de la position (CIV, PICB), le pilote recule le dernier
  descripteur valide (LVI) juste derriere le courant, sans interruption.
  Lecture : registres PCM Out (NABMBAR + 10h), enregistrement : PCM In
  (NABMBAR + 00h, entree ligne). }

Const
  RING = 65536;
  NDESC = 32;
  CHUNK = RING Div NDESC;
  NIds = 12;
  Ids : Array[0..NIds - 1] Of LongInt = (
    $24158086, $24258086, $24458086, $24858086, $24C58086, $24D58086, $266E8086, $27DE8086,
    $71958086, $746D1022, $006A10DE, $00DA10DE);

Var
  Nam, Nabm, PciAddr, Found, Vra : LongInt;
  RingMem, RingAddr, Bdl : LongInt;
  CurDir, CurRate, Regs, Running : LongInt;
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
{ Codec AC'97                                                           }
{ ==================================================================== }

Procedure CodecW(R, V : LongInt);
Begin
  OutW(Nam + R, V);
End;

Function CodecR(R : LongInt) : LongInt;
Begin
  CodecR := InW(Nam + R);
End;

{ ==================================================================== }
{ Detection                                                             }
{ ==================================================================== }

Function FindCtl : Boolean;
Var Bus, Dev, Fn, A, Id, Cls, K : LongInt;
Begin
  FindCtl := False;
  For Bus := 0 To 7 Do
    For Dev := 0 To 31 Do
      For Fn := 0 To 7 Do
      Begin
        A := $80000000 Or (Bus Shl 16) Or (Dev Shl 11) Or (Fn Shl 8);
        Id := PciRead(A, 0);
        If (Id <> -1) And (Id <> 0) Then
        Begin
          Cls := (PciRead(A, 8) Shr 16) And $FFFF;
          If Cls = $0401 Then
            For K := 0 To NIds - 1 Do
              If (Id = Ids[K]) And (PciAddr = 0) Then PciAddr := A;
        End;
      End;
  FindCtl := PciAddr <> 0;
End;

Function IchDetect : Boolean;
Var K, V : LongInt;
Begin
  IchDetect := False;
  PciAddr := 0;
  If Not FindCtl Then Exit;
  Nam := PciRead(PciAddr, $10) And $FFFC;
  Nabm := PciRead(PciAddr, $14) And $FFFC;
  If (Nam = 0) Or (Nabm = 0) Then Exit;
  { entrees-sorties et bus maitre }
  PciWrite(PciAddr, 4, PciRead(PciAddr, 4) Or 5);
  { remise a zero a froid du lien AC'97, puis codec pret (bit 8) }
  OutL(Nabm + $2C, 2);
  Dummy0 := DosSleep(20);
  K := 0;
  While ((InL(Nabm + $30) And $100) = 0) And (K < 100) Do
  Begin
    Dummy0 := DosSleep(10);
    Inc(K);
  End;
  CodecW($00, 0);                                { remise a zero du codec }
  Dummy0 := DosSleep(10);
  CodecW($02, $0000);                            { volume general }
  CodecW($04, $0000);                            { casque }
  CodecW($18, $0808);                            { sortie PCM }
  CodecW($1A, $0404);                            { enregistrement : entree ligne }
  CodecW($1C, $0000);                            { gain d'enregistrement }
  { frequence variable }
  Vra := 0;
  If (CodecR($28) And 1) <> 0 Then
  Begin
    CodecW($2A, CodecR($2A) Or 1);
    Vra := 1;
  End;
  { tampon circulaire et liste des descripteurs }
  If RingMem = 0 Then RingMem := HeapAlloc(2, 8, RING + 4096 + NDESC * 8);
  If RingMem = 0 Then Exit;
  RingAddr := (RingMem + 4095) And Not 4095;
  Bdl := RingAddr + RING;
  For K := 0 To NDESC - 1 Do
  Begin
    WrL(Bdl + K * 8, RingAddr + K * CHUNK);
    WrL(Bdl + K * 8 + 4, CHUNK Div 2);           { echantillons de 16 bits }
  End;
  V := PciRead(PciAddr, 0);
  If (V And $FFFF) = $8086 Then PutName('Intel AC''97 (ICH)')
  Else If (V And $FFFF) = $10DE Then PutName('nVidia nForce AC''97')
  Else PutName('AMD-8111 AC''97');
  Found := 1;
  IchDetect := True;
End;

{ ==================================================================== }
{ Transfert                                                             }
{ ==================================================================== }

Procedure ResetRegs(R : LongInt);
Var K : LongInt;
Begin
  OutB(R + $0B, 0);
  OutB(R + $0B, 2);
  K := 0;
  While ((InB(R + $0B) And 2) <> 0) And (K < 1000) Do Inc(K);
  OutW(R + $06, $1C);
End;

Procedure OpenFmt(P : LongInt);
Var Rate : LongInt;
Begin
  CurDir := RdL(P + 8);
  Rate := RdL(P + 12);
  If Rate < 8000 Then Rate := 8000;
  If Rate > 48000 Then Rate := 48000;
  If Vra <> 0 Then
  Begin
    If CurDir = 0 Then
    Begin
      CodecW($2C, Rate);
      Rate := CodecR($2C);
    End
    Else
    Begin
      CodecW($32, Rate);
      Rate := CodecR($32);
    End;
    If Rate = 0 Then Rate := 48000;
  End
  Else Rate := 48000;
  CurRate := Rate;
  If CurDir = 0 Then Regs := Nabm + $10 Else Regs := Nabm;
  WrL(P + 24, Rate); WrL(P + 28, 16); WrL(P + 32, 2);
  WrL(P + 36, RingAddr); WrL(P + 40, RING);
End;

Procedure StartIo;
Begin
  ResetRegs(Regs);
  OutL(Regs + $00, Bdl);
  OutB(Regs + $05, NDESC - 1);
  OutB(Regs + $0B, 1);                            { marche }
  Running := 1;
End;

Procedure StopIo;
Begin
  If Running = 0 Then Exit;
  OutB(Regs + $0B, 0);
  ResetRegs(Regs);
  Running := 0;
End;

{ octet du tampon en cours de transfert ; garde la liste en boucle }
Function Position : LongInt;
Var Civ, Picb, Sr : LongInt;
Begin
  Civ := InB(Regs + $04) And 31;
  Picb := InW(Regs + $08);
  If Picb > CHUNK Div 2 Then Picb := CHUNK Div 2;
  { le dernier descripteur valide reste juste derriere le courant }
  OutB(Regs + $05, (Civ + NDESC - 1) And 31);
  Sr := InW(Regs + $06);
  If (Sr And 1) <> 0 Then
  Begin
    { arrete (fin de liste atteinte) : relancer }
    OutW(Regs + $06, $1C);
    OutB(Regs + $0B, 1);
  End
  Else If (Sr And $1C) <> 0 Then OutW(Regs + $06, Sr And $1C);
  Position := (Civ * CHUNK + CHUNK - Picb * 2) Mod RING;
End;

Procedure SetVolume(V : LongInt);
Var A : LongInt;
Begin
  If V < 0 Then V := 0;
  If V > 100 Then V := 100;
  If V = 0 Then CodecW($02, $8000)
  Else
  Begin
    A := ((100 - V) * 31) Div 100;
    CodecW($02, (A Shl 8) Or A);
  End;
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
        Ok := IchDetect;
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
  Found := 0; RingMem := 0; Running := 0; PciAddr := 0;
  PutName('AC''97');
END.
