{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de MONCALLS.DLL sous OS/2-0.
}

Program TESTMON;

{$R-,S-,I-}

{ Compilation : OS2PC TESTMON.PAS   (produit TESTMON.EXE)

  TESTMON  verifie les 5 fonctions de MONCALLS.DLL :
    - imprimante (LPT1) : chaine de trois moniteurs ; le port parallele
      recoit "BONJOUR (M2)", "FIN" puis "DIRECT" (avec QEMU :
      -parallel file:lpt.txt), jamais "SECRET" (supprime par un
      moniteur) ;
    - clavier (KBD$) : taper  a  x  c  Maj+y  puis  q  ; le moniteur
      change a en b, supprime x, ajoute Z apres c ;
    - souris (MOUSE$) : deplacer la souris de 2 colonnes vers la droite
      (QEMU : mouse_move 16 0) ; le moniteur double le deplacement. }

Function DosMonWrite(POut, PData, Cb : LongInt) : LongInt; External 'MONCALLS';
Function DosMonRead(PIn, Wait, PData, PcbData : LongInt) : LongInt; External 'MONCALLS';
Function DosMonClose(H : LongInt) : LongInt; External 'MONCALLS';
Function DosMonOpen(PName, PH : LongInt) : LongInt; External 'MONCALLS';
Function DosMonReg(H, PIn, POut, Pos, Index : LongInt) : LongInt; External 'MONCALLS';

Function DcMonOpen(PName, PH : LongInt) : LongInt; External 'DOSCALLS' Name 'DosMonOpen';
Function DcMonClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosMonClose';

Function KbdCharIn(PInfo, Wait, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function MouOpen(PDrv, PHmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouClose(Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetPtrPos(PPos, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouGetPtrPos(PPos, Hmou : LongInt) : LongInt; External 'MOUCALLS';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';

Const
  ERROR_MON_INVALID_PARMS = 379;
  ERROR_MON_INVALID_DEVNAME = 380;
  ERROR_MON_INVALID_HANDLE = 381;
  ERROR_MON_BUFFER_TOO_SMALL = 382;
  ERROR_MON_BUFFER_EMPTY = 383;
  ERROR_MON_DATA_TOO_LARGE = 384;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, Hk, Hm, Hp1, Hp2, Hd, Hf, Act, Hmou : LongInt;
  Name : Array[0..127] Of Byte;
  In1, Out1, In2, Out2, In3, Out3, InK, OutK, InM, OutM : Array[0..127] Of Byte;
  Small : Array[0..63] Of Byte;
  Pk : Array[0..127] Of Byte;
  Ki : Array[0..15] Of Byte;
  Pos : Array[0..7] Of Byte;
  Txt : Array[0..127] Of Byte;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;
  Shf : Boolean;

Function IStr(V : LongInt) : String;
Var T : String;
Begin
  Str(V, T);
  IStr := T;
End;

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name), S);
  Z := LongInt(@Name);
End;

Procedure OutStr(T : String);
Var K : LongInt;
Begin
  For K := 1 To Length(T) Do
    If OutLen < 16380 Then
    Begin
      OutBuf[OutLen] := Ord(T[K]);
      Inc(OutLen);
    End;
End;

Procedure Check(What : String; Cond : Boolean);
Begin
  If Cond Then
  Begin
    Inc(Ok);
    OutStr('  OK     ' + What + Chr(13) + Chr(10));
  End
  Else
  Begin
    Inc(Fail);
    OutStr('  ECHEC  ' + What + '  (code ' + IStr(R) + ')' + Chr(13) + Chr(10));
  End;
End;

Function OrdIs(Ordinal : LongInt; S : String) : Boolean;
Var Pa, Pb : LongInt;
Begin
  Pa := 0; Pb := 0;
  DosQueryProcAddr(H, 0, Z(S), LongInt(@Pa));
  DosQueryProcAddr(H, Ordinal, 0, LongInt(@Pb));
  OrdIs := (Pa <> 0) And (Pa = Pb);
End;

{ Lire un paquet (N <- longueur) }
Function Rd(PIn, Wait : LongInt) : LongInt;
Begin
  N := 128;
  Rd := DosMonRead(PIn, Wait, LongInt(@Pk), LongInt(@N));
End;

{ Donnees d'un paquet de l'imprimante }
Function PkText : String;
Var T : String; K : LongInt;
Begin
  T := '';
  For K := 2 To N - 1 Do T := T + Chr(Pk[K]);
  PkText := T;
End;

{ Paquet de l'imprimante a partir d'un texte }
Function SetText(T : String) : LongInt;
Var K : LongInt;
Begin
  Pk[0] := 0; Pk[1] := 0;
  For K := 1 To Length(T) Do Pk[K + 1] := Ord(T[K]);
  SetText := Length(T) + 2;
End;

Procedure Print(T : String);
Var K, W : LongInt;
Begin
  For K := 1 To Length(T) Do Txt[K - 1] := Ord(T[K]);
  DosWrite(Hf, LongInt(@Txt), Length(T), LongInt(@W));
End;

{ Paquet suivant du clavier ; les relachements et les touches de
  changement d'etat sont rendus au flux (Shf <- touche Maj vue) }
Procedure NextMake;
Var Done : Boolean;
Begin
  Done := False;
  Repeat
    R := Rd(LongInt(@InK), 0);
    If R <> 0 Then Done := True
    Else If ((RdW(LongInt(@Pk) + 12) And $40) <> 0) Or ((RdW(LongInt(@Pk) + 12) And $3F) = 7) Then
    Begin
      If ((RdW(LongInt(@Pk) + 12) And $3F) = 7) And (Pk[3] = $2A) And (Pk[4] = 1) Then Shf := True;
      R2 := DosMonWrite(LongInt(@OutK), LongInt(@Pk), N);
    End
    Else
      Done := True;
  Until Done;
End;

Function KeyNow : LongInt;
Begin
  Ki[0] := 0; Ki[2] := 0;
  R := KbdCharIn(LongInt(@Ki), 1, 0);
  If Ki[2] = 0 Then KeyNow := -1 Else KeyNow := Ki[0];
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTMON : essai de MONCALLS.DLL');

  { --- module et ordinaux --- }
  R := DosQueryModuleHandle(Z('MONCALLS'), LongInt(@H));
  Check('DosQueryModuleHandle MONCALLS', R = 0);
  Check('ordinaux 1 DosMonWrite, 2 DosMonRead, 3 DosMonClose, 4 DosMonOpen, 5 DosMonReg',
        OrdIs(1, 'DosMonWrite') And OrdIs(2, 'DosMonRead') And OrdIs(3, 'DosMonClose') And
        OrdIs(4, 'DosMonOpen') And OrdIs(5, 'DosMonReg'));

  { --- DosMonOpen --- }
  R := DosMonOpen(Z('XYZ$'), LongInt(@Hd));
  Check('DosMonOpen peripherique inconnu refuse', R = ERROR_MON_INVALID_DEVNAME);
  R := DosMonOpen(Z('LPT9'), LongInt(@Hd));
  Check('DosMonOpen LPT9 refuse', R = ERROR_MON_INVALID_DEVNAME);
  R := DosMonOpen(Z('KBD$'), 0);
  Check('DosMonOpen phmon nul refuse', R = ERROR_MON_INVALID_PARMS);
  R := DosMonOpen(Z('KBD$'), LongInt(@Hk));
  R2 := DosMonOpen(Z('mouse$'), LongInt(@Hm));
  Check('DosMonOpen KBD$ et MOUSE$', (R = 0) And (R2 = 0) And (Hk <> Hm));
  R := DosMonOpen(Z('LPT1'), LongInt(@Hp1));
  R2 := DosMonOpen(Z('PRN'), LongInt(@Hp2));
  Check('DosMonOpen LPT1 et PRN', (R = 0) And (R2 = 0) And (Hp1 <> Hp2));
  R := DcMonOpen(Z('LPT1:'), LongInt(@Hd));
  R2 := DcMonClose(Hd);
  Check('DosMonOpen et DosMonClose de DOSCALLS.DLL (transmis a MONCALLS)', (R = 0) And (R2 = 0) And (Hd >= 1));

  { --- DosMonReg --- }
  WrW(LongInt(@In1), 128); WrW(LongInt(@Out1), 128);
  WrW(LongInt(@In2), 128); WrW(LongInt(@Out2), 128);
  WrW(LongInt(@In3), 128); WrW(LongInt(@Out3), 128);
  WrW(LongInt(@InK), 128); WrW(LongInt(@OutK), 128);
  WrW(LongInt(@InM), 128); WrW(LongInt(@OutM), 128);
  WrW(LongInt(@Small), 32);
  R := DosMonReg(99, LongInt(@In1), LongInt(@Out1), 0, 0);
  Check('DosMonReg handle invalide refuse', R = ERROR_MON_INVALID_HANDLE);
  R := DosMonReg(Hp1, LongInt(@In1), LongInt(@Small), 0, 0);
  Check('DosMonReg tampon de 32 octets refuse', R = ERROR_MON_BUFFER_TOO_SMALL);
  R := DosMonReg(Hp1, LongInt(@In1), LongInt(@Out1), 3, 0);
  Check('DosMonReg fPosition invalide refuse', R = ERROR_MON_INVALID_PARMS);
  R := DosMonReg(Hk, LongInt(@InK), LongInt(@OutK), 0, 7);
  Check('DosMonReg session invalide refusee', R = ERROR_MON_INVALID_PARMS);
  R := DosMonReg(Hp1, LongInt(@In1), LongInt(@In1), 0, 0);
  Check('DosMonReg meme tampon en entree et en sortie refuse', R = ERROR_MON_INVALID_PARMS);

  { --- imprimante : chaine M1 (debut), M3 (defaut), M2 (fin) --- }
  R := DosMonReg(Hp2, LongInt(@In2), LongInt(@Out2), 2, 0);
  R2 := DosMonReg(Hp1, LongInt(@In1), LongInt(@Out1), 1, 0);
  A := DosMonReg(Hp1, LongInt(@In3), LongInt(@Out3), 0, 0);
  Check('DosMonReg trois moniteurs de LPT1 (fin, debut, defaut)', (R = 0) And (R2 = 0) And (A = 0));
  R := DosMonReg(Hp1, LongInt(@In1), LongInt(@Out3), 0, 0);
  Check('DosMonReg tampon deja enregistre refuse', R = ERROR_MON_INVALID_PARMS);
  Check('DosMonReg : en-tete du tampon (cb garde)', RdW(LongInt(@In1)) = 128);
  R := Rd(LongInt(@In1), 1);
  Check('DosMonRead DCWW_NOWAIT, tampon vide', R = ERROR_MON_BUFFER_EMPTY);
  R := Rd(LongInt(@Small), 1);
  Check('DosMonRead tampon non enregistre refuse', R = ERROR_MON_INVALID_PARMS);
  R := Rd(LongInt(@In1), 5);
  Check('DosMonRead fWaitFlag invalide refuse', R = ERROR_MON_INVALID_PARMS);

  R := DosOpen(Z('LPT1'), LongInt(@Hf), LongInt(@Act), 0, 0, 1, $41, 0);
  Check('DosOpen LPT1', R = 0);
  Print('Bonjour');
  R := Rd(LongInt(@In2), 1);
  R2 := Rd(LongInt(@In3), 1);
  Check('les moniteurs suivants n''ont encore rien recu', (R = ERROR_MON_BUFFER_EMPTY) And (R2 = ERROR_MON_BUFFER_EMPTY));
  R := Rd(LongInt(@In1), 1);
  Check('DosMonRead M1 (debut de chaine) : "' + PkText + '"', (R = 0) And (N = 9) And (PkText = 'Bonjour'));
  R := DosMonWrite(LongInt(@Out1), LongInt(@Pk), SetText('BONJOUR'));
  Check('DosMonWrite M1 : BONJOUR', R = 0);
  R := Rd(LongInt(@In3), 1);
  Check('DosMonRead M3 (defaut, au milieu) : "' + PkText + '"', (R = 0) And (PkText = 'BONJOUR'));
  R := DosMonWrite(LongInt(@Out3), LongInt(@Pk), N);
  R := Rd(LongInt(@In2), 1);
  Check('DosMonRead M2 (fin de chaine) : "' + PkText + '"', (R = 0) And (PkText = 'BONJOUR'));
  R := DosMonWrite(LongInt(@Out2), LongInt(@Pk), SetText('BONJOUR (M2)'));
  Check('DosMonWrite M2 : vers le port parallele', R = 0);
  Print('SECRET');
  R := Rd(LongInt(@In1), 1);
  Check('M1 lit SECRET et le supprime (pas de DosMonWrite)', (R = 0) And (PkText = 'SECRET'));
  R := DosMonWrite(LongInt(@Out1), LongInt(@Pk), 67);
  Check('DosMonWrite paquet de 67 octets refuse', R = ERROR_MON_DATA_TOO_LARGE);
  R := DosMonWrite(LongInt(@In1), LongInt(@Pk), 4);
  Check('DosMonWrite tampon non enregistre en sortie refuse', R = ERROR_MON_INVALID_PARMS);
  Print('XY');
  N := 3;
  R := DosMonRead(LongInt(@In1), 1, LongInt(@Pk), LongInt(@N));
  Check('DosMonRead tampon de donnees trop petit refuse', R = ERROR_MON_DATA_TOO_LARGE);
  R := Rd(LongInt(@In1), 1);
  Check('DosMonRead apres le refus : XY', (R = 0) And (PkText = 'XY'));
  Print('FIN');
  R := DosMonClose(Hp1);
  Check('DosMonClose M1 et M3 (FIN en attente passe a M2)', R = 0);
  R := DosMonClose(Hp1);
  Check('DosMonClose handle ferme refuse', R = ERROR_MON_INVALID_HANDLE);
  R := Rd(LongInt(@In2), 1);
  Check('DosMonRead M2 : "' + PkText + '"', (R = 0) And (PkText = 'FIN'));
  R := DosMonWrite(LongInt(@Out2), LongInt(@Pk), N);
  R := DosMonClose(Hp2);
  Check('DosMonClose M2 (fin de la surveillance de LPT1)', R = 0);
  Print('DIRECT');
  DosClose(Hf);

  { --- clavier --- }
  R := DosMonReg(Hk, LongInt(@InK), LongInt(@OutK), 0, 0);
  Check('DosMonReg KBD$', R = 0);
  R := Rd(LongInt(@InK), 1);
  Check('DosMonRead KBD$ DCWW_NOWAIT : rien', R = ERROR_MON_BUFFER_EMPTY);
  WriteLn('Tapez : a x c Maj+y');
  Shf := False;
  NextMake;
  Check('paquet du clavier : a, code 1Eh, 14 octets', (R = 0) And (N = 14) And (Pk[2] = Ord('a')) And
        (Pk[3] = $1E) And (Pk[4] = $40) And (Pk[1] = $1E));
  Pk[2] := Ord('b');
  R := DosMonWrite(LongInt(@OutK), LongInt(@Pk), 14);
  A := KeyNow;
  Check('le moniteur change a en b : KbdCharIn rend ' + Chr(A), (R = 0) And (A = Ord('b')));
  NextMake;
  Check('paquet du clavier : x (supprime)', (R = 0) And (Pk[2] = Ord('x')));
  NextMake;
  Check('paquet du clavier : c', (R = 0) And (Pk[2] = Ord('c')));
  R := DosMonWrite(LongInt(@OutK), LongInt(@Pk), 14);
  Pk[2] := Ord('Z'); Pk[3] := $2C;
  R2 := DosMonWrite(LongInt(@OutK), LongInt(@Pk), 14);
  A := KeyNow;
  B := KeyNow;
  I := KeyNow;
  Check('KbdCharIn : c puis Z ajoute, x absent', (R = 0) And (R2 = 0) And (A = Ord('c')) And (B = Ord('Z')) And (I = -1));
  NextMake;
  Check('paquet du clavier : Maj (changement d''etat) puis Y', (R = 0) And Shf And (Pk[2] = Ord('Y')) And
        ((RdW(LongInt(@Pk) + 6) And 3) <> 0));
  R := DosMonWrite(LongInt(@OutK), LongInt(@Pk), 14);
  A := KeyNow;
  Check('KbdCharIn : Y', A = Ord('Y'));
  R := DosMonWrite(LongInt(@OutK), LongInt(@Pk), 13);
  Check('DosMonWrite paquet du clavier de 13 octets refuse', R = ERROR_MON_INVALID_PARMS);
  R := DosMonClose(Hk);
  Check('DosMonClose KBD$', R = 0);
  WriteLn('Tapez : q');
  R := KbdCharIn(LongInt(@Ki), 0, 0);
  Check('apres DosMonClose, KbdCharIn lit directement : q', (R = 0) And (Ki[0] = Ord('q')));

  { --- souris --- }
  R := MouOpen(0, LongInt(@Hmou));
  WrW(LongInt(@Pos), 10);
  WrW(LongInt(@Pos) + 2, 10);
  R2 := MouSetPtrPos(LongInt(@Pos), Hmou);
  Check('MouOpen, MouSetPtrPos (10, 10)', (R = 0) And (R2 = 0));
  R := DosMonReg(Hm, LongInt(@InM), LongInt(@OutM), 0, 1);
  Check('DosMonReg MOUSE$ (session 1)', R = 0);
  WriteLn('Deplacez la souris de 2 colonnes vers la droite');
  R := Rd(LongInt(@InM), 0);
  A := RdW(LongInt(@Pk) + 10);
  Check('paquet de la souris : deplacement (fs = 1, col = ' + IStr(A) + ')', (R = 0) And (N = 12) And
        (RdW(LongInt(@Pk) + 2) = 1) And (A > 0));
  WrW(LongInt(@Pk) + 10, A * 2);
  R := DosMonWrite(LongInt(@OutM), LongInt(@Pk), 12);
  DosSleep(100);
  R2 := MouGetPtrPos(LongInt(@Pos), Hmou);
  A := RdW(LongInt(@Pos));
  B := RdW(LongInt(@Pos) + 2);
  Check('le moniteur double le deplacement : MouGetPtrPos (' + IStr(A) + ', ' + IStr(B) + ')',
        (R = 0) And (A = 10) And (B = 14));
  R := DosMonClose(Hm);
  R2 := MouClose(Hmou);
  Check('DosMonClose MOUSE$, MouClose', (R = 0) And (R2 = 0));

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTMON : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
