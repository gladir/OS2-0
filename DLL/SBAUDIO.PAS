{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Pilote audio SBAUDIO.DLL de OS/2-0 : cartes Sound Blaster
                (1.x, 2.0, Pro, 16, AWE32/64 et compatibles).
}

Library SBAUDIO;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC SBAUDIO.PAS   (produit SBAUDIO.DLL)

  Pilote des cartes Creative Sound Blaster et compatibles (bus ISA), pour
  MDM.DLL (la couche multimedia, MMPM/2). Comme un pilote de
  peripherique d'OS/2, il a un seul point d'entree, AUDIOSTRATEGY
  (ordinal 1), qui recoit un paquet de requete (tableau de LongInt) :

    +0  commande          +4  etat rendu (0 : bon, sinon code d'erreur)
    1 DETECTER   +8 parametres (chaine ASCIIZ comme la variable BLASTER :
                 "A220 I5 D1 H5 T6", ou 0) ; rend +12 possibilites (1
                 lecture, 2 enregistrement), +16 adresse du nom de la carte
    2 OUVRIR     +8 sens (0 lecture, 1 enregistrement), +12 frequence,
                 +16 bits, +20 canaux ; rend le format de la carte
                 (+24 frequence, +28 bits, +32 canaux), +36 adresse et +40
                 taille du tampon circulaire
    3 DEMARRER   le transfert (DMA en boucle sur le tampon circulaire)
    4 POSITION   rend +8 : octet du tampon que la carte lit (ou ecrit)
    5 ARRETER    6 VOLUME +8 : 0 a 100 (melangeur de la carte)
    7 FERMER

  Detection : remise a zero du DSP (port base + 6) aux adresses 220h,
  240h, 260h, 280h (ou celle de BLASTER), version du DSP (commande E1h) :
    1.x et 2.0x : Sound Blaster, 8 bits mono (4 000 a 22 050 Hz, 44 100 Hz
                  en grande vitesse a partir du DSP 2.01) ;
    3.x : Sound Blaster Pro, 8 bits, stereo jusqu'a 22 050 Hz (melangeur,
          registre 0Eh) ;
    4.x : Sound Blaster 16 (et AWE32/64), 8 ou 16 bits, mono ou stereo,
          5 000 a 44 100 Hz (commandes 41h/42h, B6h/C6h/BEh/CEh).
  Le DMA 8 bits utilise le canal D (defaut 1), le DMA 16 bits le canal H
  (defaut 5) du controleur 8237, en mode auto-initialise sur un tampon de
  64 Ko du tas du noyau (memoire basse : sous 16 Mo, sans traverser de
  frontiere de 64 Ko). La position est lue dans le compteur du 8237 : le
  pilote n'a pas besoin de l'interruption de la carte. }

Const
  RING = 65536;
  SbPorts : Array[0..3] Of LongInt = ($220, $240, $260, $280);
  { registres de page du 8237, canaux 0 a 7 }
  PageP : Array[0..7] Of LongInt = ($87, $83, $81, $82, $8F, $8B, $89, $8A);

Var
  Base, DmaLo, DmaHi, Irq, DspMaj, DspMin : LongInt;
  Found : LongInt;
  RingMem, RingAddr : LongInt;
  CurDir, CurBits, CurChans, CurRate, CurDma, Running : LongInt;
  NameBuf : Array[0..63] Of Byte;
  Dummy0 : LongInt;

Function HeapAlloc(Heap, Flags, Size : LongInt) : LongInt; External 'DOSCALLS';

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

{ courte attente (lecture d'un port sans effet : environ 1 us) }
Procedure IoDelay(N : LongInt);
Var K : LongInt;
Begin
  For K := 1 To N Do Dummy0 := InB($80);
End;

Procedure PutName(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do NameBuf[K - 1] := Ord(S[K]);
  NameBuf[Length(S)] := 0;
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

{ ==================================================================== }
{ DSP                                                                   }
{ ==================================================================== }

Function DspReset(B : LongInt) : Boolean;
Var K : LongInt;
Begin
  DspReset := False;
  OutB(B + 6, 1);
  IoDelay(10);
  OutB(B + 6, 0);
  { le DSP repond AAh en 100 us au plus }
  For K := 1 To 20000 Do
    If (InB(B + $E) And $80) <> 0 Then
    Begin
      If InB(B + $A) = $AA Then DspReset := True;
      Exit;
    End;
End;

Procedure DspWrite(V : LongInt);
Var K : LongInt;
Begin
  K := 0;
  While ((InB(Base + $C) And $80) <> 0) And (K < 100000) Do Inc(K);
  OutB(Base + $C, V);
End;

Function DspRead : LongInt;
Var K : LongInt;
Begin
  K := 0;
  While ((InB(Base + $E) And $80) = 0) And (K < 100000) Do Inc(K);
  DspRead := InB(Base + $A);
End;

Procedure MixW(R, V : LongInt);
Begin
  OutB(Base + 4, R);
  OutB(Base + 5, V);
End;

Function MixR(R : LongInt) : LongInt;
Begin
  OutB(Base + 4, R);
  MixR := InB(Base + 5);
End;

{ ==================================================================== }
{ Controleur DMA 8237                                                   }
{ ==================================================================== }

{ canal C, adresse physique A, Len octets, Mode (58h lecture de la memoire,
  54h ecriture, auto-initialise) }
Procedure DmaSetup(C, A, Len, Mode : LongInt);
Var Ad, Cnt : LongInt;
Begin
  If C < 4 Then
  Begin
    OutB($0A, $04 Or C);                      { masquer }
    OutB($0C, 0);                             { bascule }
    OutB($0B, Mode Or C);
    OutB(C * 2, A And $FF);
    OutB(C * 2, (A Shr 8) And $FF);
    OutB(PageP[C], (A Shr 16) And $FF);
    Cnt := Len - 1;
    OutB(C * 2 + 1, Cnt And $FF);
    OutB(C * 2 + 1, (Cnt Shr 8) And $FF);
    OutB($0A, C);                             { demasquer }
  End
  Else
  Begin
    OutB($D4, $04 Or (C - 4));
    OutB($D8, 0);
    OutB($D6, Mode Or (C - 4));
    Ad := A Shr 1;
    OutB($C0 + (C - 4) * 4, Ad And $FF);
    OutB($C0 + (C - 4) * 4, (Ad Shr 8) And $FF);
    OutB(PageP[C], (A Shr 16) And $FE);
    Cnt := Len Div 2 - 1;
    OutB($C2 + (C - 4) * 4, Cnt And $FF);
    OutB($C2 + (C - 4) * 4, (Cnt Shr 8) And $FF);
    OutB($D4, C - 4);
  End;
End;

Procedure DmaMask(C : LongInt);
Begin
  If C < 4 Then OutB($0A, $04 Or C) Else OutB($D4, $04 Or (C - 4));
End;

{ octets restant a transferer dans le cycle courant }
Function DmaLeft(C : LongInt) : LongInt;
Var Lo, Hi, Lo2, Hi2, P : LongInt;
Begin
  If C < 4 Then P := C * 2 + 1 Else P := $C2 + (C - 4) * 4;
  Repeat
    If C < 4 Then OutB($0C, 0) Else OutB($D8, 0);
    Lo := InB(P); Hi := InB(P);
    If C < 4 Then OutB($0C, 0) Else OutB($D8, 0);
    Lo2 := InB(P); Hi2 := InB(P);
  Until (Hi = Hi2) And (Abs(Lo - Lo2) < 16);
  P := ((Hi Shl 8) Or Lo) + 1;
  If P > 65536 Then P := 0;
  If C >= 4 Then P := P * 2;
  DmaLeft := P And $1FFFF;
End;

{ ==================================================================== }
{ Requetes                                                              }
{ ==================================================================== }

Procedure ParseBlaster(PS : LongInt);
Var S : String; K, V : LongInt; C : Char;
Begin
  If PS = 0 Then Exit;
  S := '';
  K := 0;
  While (K < 200) And (RdL(PS + K) And 255 <> 0) Do
  Begin
    S := S + Chr(RdL(PS + K) And 255);
    Inc(K);
  End;
  K := 1;
  While K <= Length(S) Do
  Begin
    C := UpCase(S[K]);
    Inc(K);
    V := 0;
    If C = 'A' Then
    Begin
      While (K <= Length(S)) And (UpCase(S[K]) In ['0'..'9', 'A'..'F']) Do
      Begin
        If S[K] <= '9' Then V := V * 16 + Ord(S[K]) - 48 Else V := V * 16 + Ord(UpCase(S[K])) - 55;
        Inc(K);
      End;
      Base := V;
    End
    Else If C In ['I', 'D', 'H'] Then
    Begin
      While (K <= Length(S)) And (S[K] In ['0'..'9']) Do
      Begin
        V := V * 10 + Ord(S[K]) - 48;
        Inc(K);
      End;
      If C = 'I' Then Irq := V Else If C = 'D' Then DmaLo := V Else DmaHi := V;
    End;
  End;
End;

Function SbDetect(PS : LongInt) : Boolean;
Var K : LongInt;
Begin
  SbDetect := False;
  Base := 0; DmaLo := 1; DmaHi := 5; Irq := 5;
  ParseBlaster(PS);
  If (Base <> 0) And Not DspReset(Base) Then Base := 0;
  If Base = 0 Then
    For K := 0 To 3 Do
      If (Base = 0) And DspReset(SbPorts[K]) Then Base := SbPorts[K];
  If Base = 0 Then Exit;
  DspWrite($E1);
  DspMaj := DspRead; DspMin := DspRead;
  If DspMaj >= 4 Then PutName('Sound Blaster 16')
  Else If DspMaj = 3 Then PutName('Sound Blaster Pro')
  Else If (DspMaj = 2) And (DspMin > 0) Then PutName('Sound Blaster 2.0')
  Else PutName('Sound Blaster');
  { tampon circulaire : 64 Ko alignes sur 64 Ko, dans le tas du noyau }
  If RingMem = 0 Then RingMem := HeapAlloc(2, 8, 2 * RING);
  If RingMem = 0 Then Exit;
  RingAddr := (RingMem + RING - 1) And Not (RING - 1);
  If RingAddr + RING > $1000000 Then Exit;
  { melangeur : volume maximal, haut-parleur }
  If DspMaj >= 4 Then
  Begin
    MixW($30, $F8); MixW($31, $F8); MixW($32, $F8); MixW($33, $F8);
  End
  Else If DspMaj = 3 Then
  Begin
    MixW($22, $FF); MixW($04, $FF);
  End;
  Found := 1;
  SbDetect := True;
End;

Function Clamp(V, A, B : LongInt) : LongInt;
Begin
  If V < A Then V := A;
  If V > B Then V := B;
  Clamp := V;
End;

{ format de la carte le plus proche de celui demande }
Procedure OpenFmt(P : LongInt);
Var Dir, Rate, Bits, Ch : LongInt;
Begin
  Dir := RdL(P + 8); Rate := RdL(P + 12); Bits := RdL(P + 16); Ch := RdL(P + 20);
  If (Bits <> 8) And (Bits <> 16) Then Bits := 16;
  If (Ch <> 1) And (Ch <> 2) Then Ch := 1;
  If DspMaj >= 4 Then Rate := Clamp(Rate, 5000, 44100)
  Else
  Begin
    Bits := 8;
    If DspMaj = 3 Then
    Begin
      If Ch = 2 Then Rate := Clamp(Rate, 4000, 22050) Else Rate := Clamp(Rate, 4000, 44100);
    End
    Else
    Begin
      Ch := 1;
      If (DspMaj = 2) And (DspMin > 0) Then Rate := Clamp(Rate, 4000, 44100) Else Rate := Clamp(Rate, 4000, 22050);
    End;
    { enregistrement : 8 bits mono avant le Sound Blaster 16 }
    If (Dir = 1) And (DspMaj < 4) Then
    Begin
      Ch := 1; Rate := Clamp(Rate, 4000, 22050);
    End;
  End;
  CurDir := Dir; CurRate := Rate; CurBits := Bits; CurChans := Ch;
  WrL(P + 24, Rate); WrL(P + 28, Bits); WrL(P + 32, Ch);
  WrL(P + 36, RingAddr); WrL(P + 40, RING);
End;

Procedure StartIo;
Var Half, Tc, Cmd, Mode : LongInt;
Begin
  If CurBits = 16 Then CurDma := DmaHi Else CurDma := DmaLo;
  If CurDir = 0 Then DmaSetup(CurDma, RingAddr, RING, $58) Else DmaSetup(CurDma, RingAddr, RING, $54);
  If DspMaj >= 4 Then
  Begin
    { Sound Blaster 16 : frequence, puis transfert auto-initialise }
    If CurDir = 0 Then DspWrite($41) Else DspWrite($42);
    DspWrite((CurRate Shr 8) And 255);
    DspWrite(CurRate And 255);
    If CurBits = 16 Then
    Begin
      If CurDir = 0 Then Cmd := $B6 Else Cmd := $BE;
      Mode := $10;                                   { signe }
      Half := RING Div 4;                            { demi-tampon en mots }
    End
    Else
    Begin
      If CurDir = 0 Then Cmd := $C6 Else Cmd := $CE;
      Mode := $00;                                   { non signe }
      Half := RING Div 2;
    End;
    If CurChans = 2 Then Mode := Mode Or $20;
    DspWrite(Cmd);
    DspWrite(Mode);
    DspWrite((Half - 1) And 255);
    DspWrite(((Half - 1) Shr 8) And 255);
  End
  Else
  Begin
    { DSP 2.x et 3.x : constante de temps, taille du bloc, 8 bits }
    If CurDir = 0 Then DspWrite($D1);                { haut-parleur }
    If DspMaj = 3 Then
    Begin
      If CurChans = 2 Then MixW($0E, MixR($0E) Or 2) Else MixW($0E, MixR($0E) And Not 2);
    End;
    Tc := 65536 - (256000000 Div (CurRate * CurChans));
    DspWrite($40);
    DspWrite((Tc Shr 8) And 255);
    Half := RING Div 2;
    DspWrite($48);
    DspWrite((Half - 1) And 255);
    DspWrite(((Half - 1) Shr 8) And 255);
    If (CurRate * CurChans > 22050) And (DspMaj >= 2) Then
    Begin
      If CurDir = 0 Then DspWrite($90) Else DspWrite($98);   { grande vitesse }
    End
    Else
    Begin
      If CurDir = 0 Then DspWrite($1C) Else DspWrite($2C);
    End;
  End;
  Running := 1;
End;

Procedure StopIo;
Begin
  If Running = 0 Then Exit;
  If DspMaj >= 4 Then
  Begin
    If CurBits = 16 Then
    Begin
      DspWrite($D5); DspWrite($D9);
    End
    Else
    Begin
      DspWrite($D0); DspWrite($DA);
    End;
  End
  Else
  Begin
    { arret d'un transfert (grande vitesse : remise a zero du DSP) }
    DspWrite($D0);
    Dummy0 := Ord(DspReset(Base));
    If CurDir = 0 Then DspWrite($D3);
  End;
  DmaMask(CurDma);
  { accuser une interruption eventuellement en attente }
  Dummy0 := InB(Base + $E);
  If DspMaj >= 4 Then Dummy0 := InB(Base + $F);
  Running := 0;
End;

Procedure SetVolume(V : LongInt);
Var X : LongInt;
Begin
  V := Clamp(V, 0, 100);
  If DspMaj >= 4 Then
  Begin
    X := (V * 31) Div 100;
    MixW($30, X Shl 3); MixW($31, X Shl 3);
  End
  Else If DspMaj = 3 Then
  Begin
    X := (V * 15) Div 100;
    MixW($22, (X Shl 4) Or X);
  End;
End;

Function AudioStrategy(P : LongInt) : LongInt;
Var Cmd, Left : LongInt; Ok : Boolean;
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
        Ok := SbDetect(RdL(P + 8));
        If Ok Then
        Begin
          WrL(P + 12, 3);                      { lecture et enregistrement }
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
        If Running <> 0 Then
        Begin
          Left := DmaLeft(CurDma);
          WrL(P + 8, (RING - Left) Mod RING);
        End
        Else WrL(P + 8, 0);
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
  Found := 0; RingMem := 0; Running := 0; Base := 0;
  PutName('Sound Blaster');
END.
