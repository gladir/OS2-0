{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de MOUCALLS.DLL sous OS/2-0.
}

Program TESTMOU;

{$R-,S-,I-}

{ Compilation : OS2PC TESTMOU.PAS   (produit TESTMOU.EXE)

  TESTMOU        verifie les 29 fonctions de MOUCALLS.DLL ; la seconde
                 partie attend des evenements de la souris (20 secondes
                 au plus) : deplacer la souris de 2 colonnes vers la
                 droite, cliquer le bouton gauche, cliquer le bouton
                 droit, deplacer la souris avec le bouton gauche enfonce,
                 puis la deplacer encore une fois (mode mickeys). Avec
                 QEMU : mouse_move 16 0 ; mouse_button 1 ; mouse_button 0 ;
                 mouse_button 2 ; mouse_button 0 ; mouse_button 1 ;
                 mouse_move 8 0 ; mouse_button 0 ; puis mouse_move 5 3.
  TESTMOU VOIR   suit ensuite la souris a l'ecran (Echap ou clic droit
                 pour terminer). }

Function MouGetPtrShape(PBuf, PShape, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetPtrShape(PBuf, PShape, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouGetNumMickeys(PCount, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouGetHotKey(PButtons, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouShellInit : LongInt; External 'MOUCALLS';
Function MouGetScaleFact(PScale, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouFlushQue(Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouGetNumButtons(PCount, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouClose(Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetHotKey(PButtons, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetScaleFact(PScale, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouFree(Reserved : LongInt) : LongInt; External 'MOUCALLS';
Function MouGetNumQueEl(PQue, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouDeRegister : LongInt; External 'MOUCALLS';
Function MouGetEventMask(PMask, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetEventMask(PMask, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouOpen(PDrv, PHmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouRemovePtr(PRect, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouGetPtrPos(PPos, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouReadEventQue(PEvent, PWait, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetPtrPos(PPos, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouGetDevStatus(PStatus, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSynch(FWait : LongInt) : LongInt; External 'MOUCALLS';
Function MouRegister(PMod, PEntry, Funs : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetDevStatus(PStatus, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouDrawPtr(Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouInitReal(PDrv : LongInt) : LongInt; External 'MOUCALLS';
Function MouGetThreshold(PThr, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetThreshold(PThr, Hmou : LongInt) : LongInt; External 'MOUCALLS';

Function ReplCalls : LongInt; External 'TESTVIOR';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';

Const
  ERROR_MOUSE_INV_HANDLE = 386;
  ERROR_MOUSE_INV_PARMS = 387;
  ERROR_MOUSE_INV_MODULE = 390;
  ERROR_MOUSE_INV_MASK = 392;
  ERROR_MOUSE_INVALID_MASK = 414;
  ERROR_MOUSE_DEREGISTER = 416;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, J, N, H, A, B, Hm, Hm2, C0, C1, Wait, NEv, T0 : LongInt;
  Name : Array[0..127] Of Byte;
  Name2 : Array[0..127] Of Byte;
  Info : Array[0..63] Of Byte;
  Ev : Array[0..15] Of Byte;
  EvFs, EvRow, EvCol : Array[0..31] Of LongInt;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;
  S : String;

Function IStr(V : LongInt) : String;
Var T : String;
Begin
  Str(V, T);
  IStr := T;
End;

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
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

Function Z2(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name2), S);
  Z2 := LongInt(@Name2);
End;

{ Cellule de l'ecran (caractere + attribut * 256) }
Function Scr(Row, Col : LongInt) : LongInt;
Begin
  Scr := RdW($B8000 + (Row * 80 + Col) * 2);
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

Function SetPos(Row, Col : LongInt) : LongInt;
Begin
  WrW(LongInt(@Info) + 48, Row);
  WrW(LongInt(@Info) + 50, Col);
  SetPos := MouSetPtrPos(LongInt(@Info) + 48, Hm);
End;

Procedure GetPos(Var Row, Col : LongInt);
Begin
  MouGetPtrPos(LongInt(@Info) + 52, Hm);
  Row := RdW(LongInt(@Info) + 52);
  Col := RdW(LongInt(@Info) + 54);
End;

{ Attendre au moins Need evenements (Secs secondes au plus) puis les lire }
Procedure Collect(Need, Secs : LongInt);
Var K : LongInt;
Begin
  K := 0;
  Repeat
    MouGetNumQueEl(LongInt(@Info) + 40, Hm);
    If RdW(LongInt(@Info) + 40) < Need Then DosSleep(100);
    Inc(K);
  Until (RdW(LongInt(@Info) + 40) >= Need) Or (K > Secs * 10);
  { attendre que la file ne grossisse plus }
  Repeat
    K := RdW(LongInt(@Info) + 40);
    DosSleep(500);
    MouGetNumQueEl(LongInt(@Info) + 40, Hm);
  Until RdW(LongInt(@Info) + 40) = K;
  Wait := 0;
  NEv := 0;
  MouGetNumQueEl(LongInt(@Info) + 40, Hm);
  While (RdW(LongInt(@Info) + 40) > 0) And (NEv < 32) Do
  Begin
    MouReadEventQue(LongInt(@Ev), LongInt(@Wait), Hm);
    EvFs[NEv] := RdW(LongInt(@Ev));
    EvRow[NEv] := RdW(LongInt(@Ev) + 6);
    EvCol[NEv] := RdW(LongInt(@Ev) + 8);
    Inc(NEv);
    MouGetNumQueEl(LongInt(@Info) + 40, Hm);
  End;
End;

{ Les etats Seq apparaissent-ils dans cet ordre parmi les evenements ? }
Function InOrder(Seq : String) : Boolean;
Var K, P, V, Q : LongInt;
Begin
  P := 0;
  K := 1;
  While K <= Length(Seq) Do
  Begin
    V := Ord(Seq[K]) - 48;
    If Seq[K] = 'a' Then V := $10;
    If Seq[K] = 'b' Then V := $20;
    Q := -1;
    While (P < NEv) And (Q < 0) Do
    Begin
      If EvFs[P] = V Then Q := P;
      Inc(P);
    End;
    If Q < 0 Then
    Begin
      InOrder := False;
      Exit;
    End;
    Inc(K);
  End;
  InOrder := True;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTMOU : essai de MOUCALLS.DLL');

  { --- module et ordinaux --- }
  R := DosQueryModuleHandle(Z('MOUCALLS'), LongInt(@H));
  Check('DosQueryModuleHandle MOUCALLS', R = 0);
  Check('ordinaux 1 MouGetPtrShape, 17 MouOpen, 27 MouInitReal, 29, 30',
        OrdIs(1, 'MouGetPtrShape') And OrdIs(17, 'MouOpen') And OrdIs(27, 'MouInitReal') And
        OrdIs(29, 'MouGetThreshold') And OrdIs(30, 'MouSetThreshold'));
  Check('ordinal 28 inexistant', DosQueryProcAddr(H, 28, 0, LongInt(@A)) <> 0);
  Check('MouShellInit', MouShellInit = 0);

  { --- ouverture --- }
  R := MouOpen(Z('BIDON$'), LongInt(@Hm));
  Check('MouOpen pilote inconnu refuse', R = ERROR_MOUSE_INV_MODULE);
  R := MouOpen(0, LongInt(@Hm));
  Check('MouOpen', (R = 0) And (Hm <> 0));
  R := MouOpen(Z('POINTER$'), LongInt(@Hm2));
  Check('MouOpen POINTER$ (seconde ouverture)', (R = 0) And (Hm2 <> Hm));
  Check('MouClose', MouClose(Hm2) = 0);
  Check('MouClose handle ferme refuse', MouClose(Hm2) = ERROR_MOUSE_INV_HANDLE);

  { --- caracteristiques --- }
  R := MouGetNumButtons(LongInt(@A), Hm);
  Check('MouGetNumButtons = 3', (R = 0) And (A = 3));
  R := MouGetNumMickeys(LongInt(@A), Hm);
  Check('MouGetNumMickeys = 40 par cm', (R = 0) And (A = 40));
  R := MouGetDevStatus(LongInt(@A), Hm);
  Check('MouGetDevStatus = 0', (R = 0) And (A = 0));
  R := MouGetEventMask(LongInt(@A), Hm);
  Check('MouGetEventMask = 7Fh', (R = 0) And (A = $7F));
  B := 6;
  R := MouSetEventMask(LongInt(@B), Hm);
  MouGetEventMask(LongInt(@A), Hm);
  Check('MouSetEventMask 06h', (R = 0) And (A = 6));
  B := $80;
  R := MouSetEventMask(LongInt(@B), Hm);
  Check('MouSetEventMask 80h refuse', R = ERROR_MOUSE_INV_MASK);
  B := $7F;
  MouSetEventMask(LongInt(@B), Hm);
  R := MouGetScaleFact(LongInt(@Info), Hm);
  Check('MouGetScaleFact (16, 8)', (R = 0) And (RdW(LongInt(@Info)) = 16) And (RdW(LongInt(@Info) + 2) = 8));
  WrW(LongInt(@Info), 8); WrW(LongInt(@Info) + 2, 4);
  R := MouSetScaleFact(LongInt(@Info), Hm);
  WrW(LongInt(@Info), 0);
  MouGetScaleFact(LongInt(@Info), Hm);
  Check('MouSetScaleFact (8, 4)', (R = 0) And (RdW(LongInt(@Info)) = 8) And (RdW(LongInt(@Info) + 2) = 4));
  WrW(LongInt(@Info), 0);
  Check('MouSetScaleFact 0 refuse', MouSetScaleFact(LongInt(@Info), Hm) = ERROR_MOUSE_INV_PARMS);
  WrW(LongInt(@Info), 16); WrW(LongInt(@Info) + 2, 8);
  MouSetScaleFact(LongInt(@Info), Hm);
  WrW(LongInt(@Info), 10);
  R := MouGetThreshold(LongInt(@Info), Hm);
  Check('MouGetThreshold (4 x1, 12 x1)', (R = 0) And (RdW(LongInt(@Info) + 2) = 4) And
        (RdW(LongInt(@Info) + 4) = 1) And (RdW(LongInt(@Info) + 6) = 12));
  WrW(LongInt(@Info), 10); WrW(LongInt(@Info) + 2, 2); WrW(LongInt(@Info) + 4, 2);
  WrW(LongInt(@Info) + 6, 6); WrW(LongInt(@Info) + 8, 3);
  R := MouSetThreshold(LongInt(@Info), Hm);
  WrW(LongInt(@Info) + 8, 0);
  MouGetThreshold(LongInt(@Info), Hm);
  Check('MouSetThreshold (2 x2, 6 x3)', (R = 0) And (RdW(LongInt(@Info) + 8) = 3));
  WrW(LongInt(@Info) + 6, 1);
  Check('MouSetThreshold niveau 2 < niveau 1 refuse', MouSetThreshold(LongInt(@Info), Hm) = ERROR_MOUSE_INV_PARMS);
  WrW(LongInt(@Info), 10); WrW(LongInt(@Info) + 2, 4); WrW(LongInt(@Info) + 4, 1);
  WrW(LongInt(@Info) + 6, 12); WrW(LongInt(@Info) + 8, 1);
  MouSetThreshold(LongInt(@Info), Hm);
  B := 3;
  R := MouSetHotKey(LongInt(@B), Hm);
  MouGetHotKey(LongInt(@A), Hm);
  Check('MouSetHotKey / MouGetHotKey (boutons 1 et 2)', (R = 0) And (A = 3));
  B := 8;
  Check('MouSetHotKey 8 refuse', MouSetHotKey(LongInt(@B), Hm) = ERROR_MOUSE_INV_PARMS);
  B := 0;
  MouSetHotKey(LongInt(@B), Hm);
  Check('MouSynch', (MouSynch(0) = 0) And (MouSynch(1) = 0));
  Check('MouInitReal', (MouInitReal(0) = 0) And (MouInitReal(Z('POINTER$')) = 0));
  Check('MouInitReal pilote inconnu refuse', MouInitReal(Z('XYZ')) = ERROR_MOUSE_INV_MODULE);

  { --- position et pointeur --- }
  GetPos(A, B);
  Check('position initiale au centre (12, 40)', (A = 12) And (B = 40));
  C0 := Scr(5, 10);
  R := SetPos(5, 10);
  GetPos(A, B);
  Check('MouSetPtrPos / MouGetPtrPos (5, 10)', (R = 0) And (A = 5) And (B = 10));
  Check('MouSetPtrPos ligne 25 refusee', SetPos(25, 0) = ERROR_MOUSE_INV_PARMS);
  Check('pointeur non dessine avant MouDrawPtr', Scr(5, 10) = C0);
  R := MouDrawPtr(Hm);
  Check('MouDrawPtr (cellule : attribut inverse)', (R = 0) And (Scr(5, 10) = C0 Xor $7700));
  WrW(LongInt(@Info), 4); WrW(LongInt(@Info) + 4, 0);
  WrW(LongInt(@Info) + 16, 0);
  R := MouGetPtrShape(LongInt(@Info) + 16, LongInt(@Info) + 20, Hm);
  Check('MouGetPtrShape cb trop petit : taille rendue (4)', (R = ERROR_MOUSE_INV_PARMS) And (RdW(LongInt(@Info) + 20) = 4));
  R := MouGetPtrShape(LongInt(@Info) + 16, LongInt(@Info) + 20, Hm);
  Check('MouGetPtrShape (FFFFh, 7700h)', (R = 0) And (RdW(LongInt(@Info) + 16) = $FFFF) And
        (RdW(LongInt(@Info) + 18) = $7700) And (RdW(LongInt(@Info) + 22) = 1));
  WrW(LongInt(@Info) + 16, $00FF); WrW(LongInt(@Info) + 18, $4F00);
  R := MouSetPtrShape(LongInt(@Info) + 16, LongInt(@Info) + 20, Hm);
  Check('MouSetPtrShape (ET 00FFh, OU exclusif 4F00h : blanc sur rouge)', (R = 0) And
        (Scr(5, 10) = ((C0 And $FF) Or $4F00)));
  WrW(LongInt(@Info) + 24, 3);
  Check('MouSetPtrShape 3 lignes refuse', MouSetPtrShape(LongInt(@Info) + 16, LongInt(@Info) + 20, Hm) = ERROR_MOUSE_INV_PARMS);
  WrW(LongInt(@Info) + 24, 1);
  WrW(LongInt(@Info) + 16, $FFFF); WrW(LongInt(@Info) + 18, $7700);
  MouSetPtrShape(LongInt(@Info) + 16, LongInt(@Info) + 20, Hm);
  WrW(LongInt(@Info), 4); WrW(LongInt(@Info) + 2, 8); WrW(LongInt(@Info) + 4, 2); WrW(LongInt(@Info) + 6, 4);
  R := MouRemovePtr(LongInt(@Info), Hm);
  Check('MouRemovePtr (zone 4-5, 8-11 : pointeur efface)', (R = 0) And (Scr(5, 10) = C0));
  C1 := Scr(7, 20);
  SetPos(7, 20);
  Check('hors de la zone d''exclusion : pointeur dessine', (Scr(7, 20) = C1 Xor $7700) And (Scr(5, 10) = C0));
  SetPos(5, 10);
  Check('dans la zone d''exclusion : pointeur cache', (Scr(5, 10) = C0) And (Scr(7, 20) = C1));
  R := MouDrawPtr(Hm);
  Check('MouDrawPtr leve la zone d''exclusion', (R = 0) And (Scr(5, 10) = C0 Xor $7700));
  A := $100;
  R := MouSetDevStatus(LongInt(@A), Hm);
  MouGetDevStatus(LongInt(@B), Hm);
  Check('MouSetDevStatus 100h (pointeur desactive)', (R = 0) And (B = $100) And (Scr(5, 10) = C0));
  A := 0;
  MouSetDevStatus(LongInt(@A), Hm);
  Check('MouSetDevStatus 0 (pointeur reaffiche)', Scr(5, 10) = C0 Xor $7700);
  A := 1;
  Check('MouSetDevStatus 01h refuse', MouSetDevStatus(LongInt(@A), Hm) = ERROR_MOUSE_INV_PARMS);

  { --- file d'evenements sans souris --- }
  R := MouFlushQue(Hm);
  MouGetNumQueEl(LongInt(@Info), Hm);
  Check('MouFlushQue / MouGetNumQueEl (0 sur 64)', (R = 0) And (RdW(LongInt(@Info)) = 0) And (RdW(LongInt(@Info) + 2) = 64));
  Wait := 0;
  FillChar(Ev, 16, $FF);
  R := MouReadEventQue(LongInt(@Ev), LongInt(@Wait), Hm);
  Check('MouReadEventQue sans attente, file vide (fs = 0, Time = 0)', (R = 0) And (RdW(LongInt(@Ev)) = 0) And
        (RdL(LongInt(@Ev) + 2) = 0));
  Wait := 2;
  Check('MouReadEventQue attente 2 refusee', MouReadEventQue(LongInt(@Ev), LongInt(@Wait), Hm) = ERROR_MOUSE_INV_PARMS);

  { --- remplacement du sous-systeme --- }
  R := MouRegister(Z('TESTVIOR'), Z2('VioReplace'), 0);
  Check('MouRegister masque vide refuse', R = ERROR_MOUSE_INVALID_MASK);
  R := MouRegister(Z('TESTVIOR'), Z2('Inexistante'), 2);
  Check('MouRegister point d''entree inconnu refuse', R <> 0);
  A := ReplCalls;
  R := MouRegister(Z('TESTVIOR'), Z2('VioReplace'), 2);
  R2 := MouGetNumMickeys(LongInt(@B), Hm);
  Check('MouRegister MR_MOUGETNUMMICKEYS (le remplacant rend 99)', (R = 0) And (R2 = 99) And (ReplCalls = A + 1));
  R := MouDeRegister;
  R2 := MouGetNumMickeys(LongInt(@B), Hm);
  Check('MouDeRegister (fonction de base)', (R = 0) And (R2 = 0) And (B = 40));
  Check('MouDeRegister sans remplacement refuse', MouDeRegister = ERROR_MOUSE_DEREGISTER);

  { --- evenements de la souris --- }
  WriteLn('TESTMOU : deplacer la souris et cliquer (20 secondes au plus)...');
  MouFlushQue(Hm);
  SetPos(12, 40);
  Collect(8, 20);
  J := -1;
  For I := 0 To NEv - 1 Do
    If (J < 0) And (EvFs[I] = 1) Then J := I;
  Check('evenements recus : ' + IStr(NEv), NEv >= 8);
  Check('deplacement (fs 01h) jusqu''a la colonne 42', (J >= 0) And (EvCol[J] = 42) And (EvRow[J] = 12));
  Check('bouton gauche enfonce puis relache (04h, 00h)', InOrder('40'));
  Check('bouton droit enfonce puis relache (10h, 00h)', InOrder('40a0'));
  Check('deplacement avec le bouton gauche (04h, 02h, 00h)', InOrder('40a0420'));
  GetPos(A, B);
  Check('MouGetPtrPos apres les deplacements (12, 43)', (A = 12) And (B = 43));
  A := $200;
  MouSetDevStatus(LongInt(@A), Hm);
  Collect(1, 15);
  Check('mode mickeys (MOUSE_MICKEYS) : deplacement relatif (3, 5)', (NEv >= 1) And (EvFs[0] = 1) And
        (EvRow[0] = 3) And (EvCol[0] = 5));
  A := 0;
  MouSetDevStatus(LongInt(@A), Hm);

  If (ParamCount > 0) And ((ParamStr(1) = 'VOIR') Or (ParamStr(1) = 'voir')) Then
  Begin
    WriteLn('Deplacez la souris ; clic droit pour terminer.');
    Wait := 1;
    Repeat
      MouReadEventQue(LongInt(@Ev), LongInt(@Wait), Hm);
    Until (RdW(LongInt(@Ev)) And $18) <> 0;
  End;

  { --- fin --- }
  SetPos(20, 70);
  C1 := Scr(20, 70);
  R := MouClose(Hm);
  Check('MouClose (pointeur efface)', (R = 0) And (Scr(20, 70) = C1 Xor $7700));
  Check('MouFree', MouFree(0) = 0);
  Check('MouShellInit', MouShellInit = 0);

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTMOU : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
