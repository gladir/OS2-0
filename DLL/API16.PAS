{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque API16.DLL de OS/2-0 : les fonctions du
                systeme appelees par les programmes 16 bits d'OS/2 1.x
                (format NE).
}

Library API16;

{$IMAGEBASE $00FC0000}
{$R-,S-,I-}

{ Compilation : OS2PC API16.PAS   (produit API16.DLL)

  Le noyau (partie 13d) charge les programmes 16 bits d'OS/2 1.x (NE) et
  relie leurs importations de DOSCALLS, KBDCALLS, VIOCALLS, NLS, MSG
  (ordinaux d'OS/2 1.x) a de petites souches 16 bits ; un appel passe
  par une porte d'appel vers le noyau, qui appelle ici la fonction
  F<module>_<ordinal>(A) : A est l'adresse lineaire des arguments sur la
  pile 16 bits (convention Pascal : le dernier argument est en A). Les
  pointeurs 16:16 sont convertis par le noyau (KrnTaskCtl 30), les
  structures de 16 bits (FILESTATUS, FILEFINDBUF...) traduites vers et
  depuis celles d'OS/2-0, puis les fonctions 32 bits de DOSCALLS.DLL,
  VIOCALLS.DLL, KBDCALLS.DLL, NLS.DLL et MSG.DLL sont appelees. La valeur
  rendue (AX) est le code d'erreur d'OS/2.

  API16ARGS(module, ordinal) donne la taille des arguments (pour le RETF
  de la souche), -1 si la fonction n'est pas fournie. Modules : 1
  DOSCALLS, 2 KBDCALLS, 3 VIOCALLS, 4 NLS, 5 MSG.

  DosAllocSeg, DosReallocSeg, DosFreeSeg, DosCreateThread et DosExit
  sont faits par le noyau (selecteurs de la LDT, fils). Les attributs
  etendus ne sont pas geres (listes vides), comme dans DOSCALLS.DLL. }

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Function KTask(Op, P1, P2, P3 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnTaskCtl';
Function DcOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS' Name 'DosOpen';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';
Function DcRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRead';
Function DcWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWrite';
Function DcSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSetFilePtr';
Function DcDelete(PName : LongInt) : LongInt; External 'DOSCALLS' Name 'DosDelete';
Function DcCreateDir(PName, PEaop2 : LongInt) : LongInt; External 'DOSCALLS' Name 'DosCreateDir';
Function DcQueryCurrentDir(Disk, PBuf, PCb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryCurrentDir';
Function DcQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryCurrentDisk';
Function DcQueryHType(H, PType, PAttr : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryHType';
Function DcFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS' Name 'DosFindFirst';
Function DcFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS' Name 'DosFindNext';
Function DcFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS' Name 'DosFindClose';
Function DcQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryPathInfo';
Function DcQueryFileInfo(H, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryFileInfo';
Function DcSetFileInfo(H, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSetFileInfo';
Function DcSetPathInfo(PName, Level, PInfo, Cb, Flags : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSetPathInfo';
Function DcSleep(Msec : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSleep';
Function DcBeep(Freq, Duration : LongInt) : LongInt; External 'DOSCALLS' Name 'DosBeep';
Function KbCharIn(PInfo, Wait, Hkbd : LongInt) : LongInt; External 'KBDCALLS' Name 'KbdCharIn';
Function KbPeek(PInfo, Hkbd : LongInt) : LongInt; External 'KBDCALLS' Name 'KbdPeek';
Function KbFlushBuffer(Hkbd : LongInt) : LongInt; External 'KBDCALLS' Name 'KbdFlushBuffer';
Function KbGetStatus(PInfo, Hkbd : LongInt) : LongInt; External 'KBDCALLS' Name 'KbdGetStatus';
Function KbSetStatus(PInfo, Hkbd : LongInt) : LongInt; External 'KBDCALLS' Name 'KbdSetStatus';
Function ViGetCurType(PInfo, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetCurType';
Function ViSetCurType(PInfo, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioSetCurType';
Function ViWrtCharStr(PStr, Cb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioWrtCharStr';
Function ViWrtNChar(PCh, Cb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioWrtNChar';
Function ViWrtNAttr(PAttr, Cb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioWrtNAttr';
Function ViWrtNCell(PCell, Cb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioWrtNCell';
Function ViWrtTty(PCh, Cb, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioWrtTty';
Function ViGetConfig(ConfigId, PInfo, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetConfig';
Function NlCaseMap(Len, Pcc, PCh : LongInt) : LongInt; External 'NLS' Name 'DosCaseMap';
Function NlGetDBCSEv(Cb, Pcc, PBuf : LongInt) : LongInt; External 'NLS' Name 'DosGetDBCSEv';
Function MsPutMessage(H, Cb, PBuf : LongInt) : LongInt; External 'MSG' Name 'Dos16PutMessage';
Function MsTrueGetMessage(PTable, CTable, PBuf, CbBuf, Num, PFile, PcbMsg, PSeg : LongInt) : LongInt; External 'MSG' Name 'DosTrueGetMessage';

Var
  Tmp : Array[0..15] Of LongInt;
  Tab : Array[0..15] Of LongInt;
  St  : Array[0..15] Of LongInt;           { FILESTATUS3/4 }
  FBuf : Array[0..2047] Of LongInt;        { 8 Ko : entrees FILEFINDBUF3/4 }

Function PeekL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  PeekL := P^;
End;

Procedure PokeL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V;
End;

Function PeekW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  PeekW := P^ And $FFFF;
End;

Procedure PokeW(A, V : LongInt);
Var P : PWord;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FFFF;
End;

Function PeekB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  PeekB := P^ And $FF;
End;

Procedure PokeB(A, V : LongInt);
Var P : PByte;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FF;
End;

Procedure MoveB(Src, Dst, N : LongInt);
Var I : LongInt;
Begin
  If (Src = 0) Or (Dst = 0) Then Exit;
  For I := 0 To N - 1 Do PokeB(Dst + I, PeekB(Src + I));
End;

{ argument de 16 bits, de 32 bits, pointeur 16:16 (adresse lineaire) a
  la position O de la pile }
Function W(A, O : LongInt) : LongInt;
Begin
  W := PeekW(A + O);
End;

Function L(A, O : LongInt) : LongInt;
Begin
  L := PeekL(A + O);
End;

Function P(A, O : LongInt) : LongInt;
Begin
  P := KTask(30, PeekW(A + O + 2), PeekW(A + O), 0);
End;

{ entier de 16 bits signe }
Function S16(V : LongInt) : LongInt;
Begin
  If (V And $8000) <> 0 Then S16 := V Or LongInt($FFFF0000) Else S16 := V And $FFFF;
End;

{ FILESTATUS3 (St) -> FILESTATUS (16 bits, niveau 1 ou 2) }
Procedure PutStatus16(D, Level, Cb : LongInt);
Var N : LongInt;
Begin
  If Level = 2 Then N := 26 Else N := 22;
  If N > Cb Then N := Cb;
  MoveB(LongInt(@St), D, 12);
  If N >= 16 Then PokeL(D + 12, St[3]);
  If N >= 20 Then PokeL(D + 16, St[4]);
  If N >= 22 Then PokeW(D + 20, St[5]);
  If N >= 26 Then PokeL(D + 22, 4);
End;

{ ------------------------------------------------------------------ }
{ DOSCALLS                                                           }
{ ------------------------------------------------------------------ }

{ 3 DosEnterCritSec() }
Function F1_3(A : LongInt) : LongInt;
Begin
  F1_3 := 0;
End;

{ 14 DosSetSigHandler(pfn, ppfnPrev, pfAction, fAction, usSigNum) }
Function F1_14(A : LongInt) : LongInt;
Begin
  If P(A, 8) <> 0 Then PokeL(P(A, 8), 0);
  If P(A, 4) <> 0 Then PokeW(P(A, 4), 0);
  F1_14 := 0;
End;

{ semaphores en memoire (RAM) : un mot double, 0 = libre }
Function SemWait(H, T : LongInt) : LongInt;
Var N : LongInt;
Begin
  SemWait := 0;
  If H = 0 Then Exit;
  N := 0;
  While PeekL(H) <> 0 Do
  Begin
    If T = 0 Then
    Begin
      SemWait := 121;                 { ERROR_SEM_TIMEOUT }
      Exit;
    End;
    DcSleep(10);
    N := N + 10;
    If (T > 0) And (N >= T) Then
    Begin
      SemWait := 121;
      Exit;
    End;
  End;
End;

{ 20 DosSemSetWait(hsem, lTimeout) }
Function F1_20(A : LongInt) : LongInt;
Begin
  PokeL(P(A, 4), 1);
  F1_20 := SemWait(P(A, 4), L(A, 0));
End;

{ 49 DosGetMachineMode(pMode) }
Function F1_49(A : LongInt) : LongInt;
Begin
  PokeB(P(A, 0), 1);
  F1_49 := 0;
End;

{ 50 DosBeep(usFreq, usDuration) }
Function F1_50(A : LongInt) : LongInt;
Begin
  F1_50 := DcBeep(W(A, 2), W(A, 0));
End;

{ 58 DosChgFilePtr(hf, lDistance, usMethod, pulNewPtr) }
Function F1_58(A : LongInt) : LongInt;
Begin
  Tmp[0] := 0;
  F1_58 := DcSetFilePtr(W(A, 10), L(A, 6), W(A, 4), LongInt(@Tmp));
  PokeL(P(A, 0), Tmp[0]);
End;

{ 59 DosClose(hf) }
Function F1_59(A : LongInt) : LongInt;
Begin
  F1_59 := DcClose(W(A, 0));
End;

{ 60 DosDelete(pszFile, ulReserved) }
Function F1_60(A : LongInt) : LongInt;
Begin
  F1_60 := DcDelete(P(A, 4));
End;

{ 63 DosFindClose(hdir) }
Function F1_63(A : LongInt) : LongInt;
Begin
  F1_63 := DcFindClose(W(A, 0));
End;

{ entrees FILEFINDBUF3/4 (FBuf, N) -> FILEFINDBUF/FILEFINDBUF2 de 16 bits ;
  rend le nombre d'entrees ecrites }
Function PutFind16(D, Cb, N, Level : LongInt) : LongInt;
Var K, S, Q, Nl, Ofs, Sz : LongInt;
Begin
  S := LongInt(@FBuf);
  Q := D;
  K := 0;
  While K < N Do
  Begin
    If Level = 1 Then Ofs := 28 Else Ofs := 32;
    Nl := PeekB(S + Ofs);
    If Level = 1 Then Sz := 23 + Nl + 1 Else Sz := 27 + Nl + 1;
    If Q + Sz > D + Cb Then Break;
    MoveB(S + 4, Q, 12);
    PokeL(Q + 12, PeekL(S + 16));
    PokeL(Q + 16, PeekL(S + 20));
    PokeW(Q + 20, PeekL(S + 24));
    If Level = 1 Then
    Begin
      PokeB(Q + 22, Nl);
      MoveB(S + Ofs + 1, Q + 23, Nl + 1);
    End
    Else
    Begin
      PokeL(Q + 22, 4);
      PokeB(Q + 26, Nl);
      MoveB(S + Ofs + 1, Q + 27, Nl + 1);
    End;
    Q := Q + Sz;
    Inc(K);
    If PeekL(S) = 0 Then Break;
    S := S + PeekL(S);
  End;
  PutFind16 := K;
End;

{ nombre d'entrees demandees (16 bits) qui tiennent sans doute dans Cb }
Function FindWant(Cb, Want : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := Cb Div 40;
  If M < 1 Then M := 1;
  If Want > M Then Want := M;
  If Want > 30 Then Want := 30;
  If Want < 1 Then Want := 1;
  FindWant := Want;
End;

{ 65 DosFindNext(hdir, pfindbuf, cbBuf, pcSearch) }
Function F1_65(A : LongInt) : LongInt;
Var R, Lv : LongInt;
Begin
  Tmp[0] := FindWant(W(A, 4), PeekW(P(A, 0)));
  R := DcFindNext(W(A, 10), LongInt(@FBuf), SizeOf(FBuf), LongInt(@Tmp));
  If R = 0 Then
    PokeW(P(A, 0), PutFind16(P(A, 6), W(A, 4), Tmp[0], 1))
  Else PokeW(P(A, 0), 0);
  F1_65 := R;
End;

{ 66 DosMkDir(pszDir, ulReserved) }
Function F1_66(A : LongInt) : LongInt;
Begin
  F1_66 := DcCreateDir(P(A, 4), 0);
End;

{ 71 DosQCurDir(usDrive, pchBuf, pcbBuf) }
Function F1_71(A : LongInt) : LongInt;
Begin
  Tmp[0] := PeekW(P(A, 0));
  F1_71 := DcQueryCurrentDir(W(A, 8), P(A, 4), LongInt(@Tmp));
  PokeW(P(A, 0), Tmp[0]);
End;

{ 72 DosQCurDisk(pusDrive, pulMap) }
Function F1_72(A : LongInt) : LongInt;
Begin
  Tmp[0] := 0; Tmp[1] := 0;
  F1_72 := DcQueryCurrentDisk(LongInt(@Tmp), LongInt(@Tmp) + 4);
  PokeW(P(A, 4), Tmp[0]);
  PokeL(P(A, 0), Tmp[1]);
End;

{ 74 DosQFileInfo(hf, usLevel, pBuf, cbBuf) }
Function F1_74(A : LongInt) : LongInt;
Var R, Lv : LongInt;
Begin
  Lv := W(A, 6);
  If Lv = 3 Then
  Begin
    { EAOP : liste FEA vide }
    If P(P(A, 2), 4) <> 0 Then PokeL(P(P(A, 2), 4), 4);
    F1_74 := 0;
    Exit;
  End;
  R := DcQueryFileInfo(W(A, 8), 1, LongInt(@St), 24);
  If R = 0 Then PutStatus16(P(A, 2), Lv, W(A, 0));
  F1_74 := R;
End;

{ 75 DosQFileMode(pszFile, pusAttr, ulReserved) }
Function F1_75(A : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := DcQueryPathInfo(P(A, 8), 1, LongInt(@St), 24);
  If R = 0 Then PokeW(P(A, 4), St[5]);
  F1_75 := R;
End;

{ 77 DosQHandType(hf, pusType, pusFlags) }
Function F1_77(A : LongInt) : LongInt;
Begin
  Tmp[0] := 0; Tmp[1] := 0;
  F1_77 := DcQueryHType(W(A, 8), LongInt(@Tmp), LongInt(@Tmp) + 4);
  PokeW(P(A, 4), Tmp[0]);
  PokeW(P(A, 0), Tmp[1]);
End;

{ 83 DosSetFileInfo(hf, usLevel, pBuf, cbBuf) }
Function F1_83(A : LongInt) : LongInt;
Var R : LongInt;
Begin
  If W(A, 6) <> 1 Then
  Begin
    F1_83 := 0;               { attributs etendus : ignores }
    Exit;
  End;
  R := DcQueryFileInfo(W(A, 8), 1, LongInt(@St), 24);
  If R = 0 Then
  Begin
    MoveB(P(A, 2), LongInt(@St), 12);
    R := DcSetFileInfo(W(A, 8), 1, LongInt(@St), 24);
  End;
  F1_83 := R;
End;

{ 84 DosSetFileMode(pszFile, usAttr, ulReserved) }
Function F1_84(A : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := DcQueryPathInfo(P(A, 6), 1, LongInt(@St), 24);
  If R = 0 Then
  Begin
    St[5] := W(A, 4) And $37;
    R := DcSetPathInfo(P(A, 6), 1, LongInt(@St), 24, 0);
  End;
  F1_84 := R;
End;

{ 86 DosSetVerify(fVerify) }
Function F1_86(A : LongInt) : LongInt;
Begin
  F1_86 := 0;
End;

{ 89 DosSetVec(usVecNum, pfnFun, ppfnPrev) }
Function F1_89(A : LongInt) : LongInt;
Begin
  If P(A, 0) <> 0 Then PokeL(P(A, 0), 0);
  F1_89 := 0;
End;

{ 92 DosGetVersion(pVersion) : 20.00 (OS/2 2.0) }
Function F1_92(A : LongInt) : LongInt;
Begin
  PokeW(P(A, 0), $1400);
  F1_92 := 0;
End;

{ 95 DosOpen2(pszFname, phf, pusAction, ulFSize, usAttr, usOpenFlags,
     ulOpenMode, pEABuf, ulReserved) }
Function F1_95(A : LongInt) : LongInt;
Var R : LongInt;
Begin
  Tmp[0] := 0; Tmp[1] := 0;
  R := DcOpen(P(A, 28), LongInt(@Tmp), LongInt(@Tmp) + 4, L(A, 16), W(A, 14), W(A, 12),
              L(A, 8), 0);
  If R = 0 Then
  Begin
    PokeW(P(A, 24), Tmp[0]);
    PokeW(P(A, 20), Tmp[1]);
  End;
  F1_95 := R;
End;

{ 98 DosQPathInfo(pszPath, usLevel, pBuf, cbBuf, ulReserved) }
Function F1_98(A : LongInt) : LongInt;
Var R, Lv : LongInt;
Begin
  Lv := W(A, 10);
  If Lv = 3 Then
  Begin
    If P(P(A, 6), 4) <> 0 Then PokeL(P(P(A, 6), 4), 4);
    F1_98 := DcQueryPathInfo(P(A, 12), 1, LongInt(@St), 24);
    Exit;
  End;
  If (Lv = 5) Or (Lv = 6) Then
  Begin
    F1_98 := DcQueryPathInfo(P(A, 12), 5, P(A, 6), W(A, 4));
    Exit;
  End;
  R := DcQueryPathInfo(P(A, 12), 1, LongInt(@St), 24);
  If R = 0 Then PutStatus16(P(A, 6), Lv, W(A, 4));
  F1_98 := R;
End;

{ 120 DosError(fEnable) }
Function F1_120(A : LongInt) : LongInt;
Begin
  F1_120 := 0;
End;

{ 137 DosRead(hf, pBuf, cbBuf, pcbBytesRead) }
Function F1_137(A : LongInt) : LongInt;
Begin
  Tmp[0] := 0;
  F1_137 := DcRead(W(A, 10), P(A, 6), W(A, 4), LongInt(@Tmp));
  PokeW(P(A, 0), Tmp[0]);
End;

{ 138 DosWrite(hf, pBuf, cbBuf, pcbBytesWritten) }
Function F1_138(A : LongInt) : LongInt;
Begin
  Tmp[0] := 0;
  F1_138 := DcWrite(W(A, 10), P(A, 6), W(A, 4), LongInt(@Tmp));
  PokeW(P(A, 0), Tmp[0]);
End;

{ 141 DosSemClear(hsem) }
Function F1_141(A : LongInt) : LongInt;
Begin
  PokeL(P(A, 0), 0);
  F1_141 := 0;
End;

{ 142 DosSemWait(hsem, lTimeout) }
Function F1_142(A : LongInt) : LongInt;
Begin
  F1_142 := SemWait(P(A, 4), L(A, 0));
End;

{ 143 DosSemSet(hsem) }
Function F1_143(A : LongInt) : LongInt;
Begin
  PokeL(P(A, 0), 1);
  F1_143 := 0;
End;

{ 184 DosFindFirst2(pszFSpec, phdir, usAttr, pBuf, cbBuf, pcSearch, usInfoLevel,
      ulReserved) }
Function F1_184(A : LongInt) : LongInt;
Var R, Lv, Hd, Q, Room : LongInt;
Begin
  Lv := W(A, 4);
  Hd := PeekW(P(A, 18));
  If Hd = $FFFF Then Hd := -1;
  Tmp[1] := Hd;
  Tmp[0] := FindWant(W(A, 10), PeekW(P(A, 6)));
  Q := P(A, 12); Room := W(A, 10);
  If Lv = 3 Then
  Begin
    { EAOP en tete (12 octets), puis des entrees de niveau 2 }
    Q := Q + 12; Room := Room - 12;
  End;
  If Lv = 1 Then
    R := DcFindFirst(P(A, 22), LongInt(@Tmp) + 4, W(A, 16), LongInt(@FBuf), SizeOf(FBuf), LongInt(@Tmp), 1)
  Else
    R := DcFindFirst(P(A, 22), LongInt(@Tmp) + 4, W(A, 16), LongInt(@FBuf), SizeOf(FBuf), LongInt(@Tmp), 2);
  If R = 0 Then
  Begin
    PokeW(P(A, 18), Tmp[1]);
    If Lv = 1 Then PokeW(P(A, 6), PutFind16(Q, Room, Tmp[0], 1))
    Else PokeW(P(A, 6), PutFind16(Q, Room, Tmp[0], 2));
  End
  Else PokeW(P(A, 6), 0);
  F1_184 := R;
End;

{ 204 DosEnumAttribute(...) : aucun attribut etendu }
Function F1_204(A : LongInt) : LongInt;
Begin
  If P(A, 8) <> 0 Then PokeL(P(A, 8), 0);
  F1_204 := 0;
End;

{ ------------------------------------------------------------------ }
{ KBDCALLS, VIOCALLS, NLS, MSG (structures identiques)                }
{ ------------------------------------------------------------------ }

{ 4 KbdCharIn(pkbci, fWait, hkbd) }
Function F2_4(A : LongInt) : LongInt;
Begin
  F2_4 := KbCharIn(P(A, 4), W(A, 2), W(A, 0));
End;

{ 10 KbdGetStatus(pkbdinfo, hkbd) }
Function F2_10(A : LongInt) : LongInt;
Begin
  F2_10 := KbGetStatus(P(A, 2), W(A, 0));
End;

{ 11 KbdSetStatus(pkbdinfo, hkbd) }
Function F2_11(A : LongInt) : LongInt;
Begin
  F2_11 := KbSetStatus(P(A, 2), W(A, 0));
End;

{ 13 KbdFlushBuffer(hkbd) }
Function F2_13(A : LongInt) : LongInt;
Begin
  F2_13 := KbFlushBuffer(W(A, 0));
End;

{ 22 KbdPeek(pkbci, hkbd) }
Function F2_22(A : LongInt) : LongInt;
Begin
  F2_22 := KbPeek(P(A, 2), W(A, 0));
End;

{ 13 VioWrtCharStr(pchStr, cb, usRow, usCol, hvio) }
Function F3_13(A : LongInt) : LongInt;
Begin
  F3_13 := ViWrtCharStr(P(A, 8), W(A, 6), W(A, 4), W(A, 2), W(A, 0));
End;

{ 19 VioWrtTTY(pch, cb, hvio) }
Function F3_19(A : LongInt) : LongInt;
Begin
  F3_19 := ViWrtTty(P(A, 4), W(A, 2), W(A, 0));
End;

{ 26 VioWrtNAttr(pAttr, cb, usRow, usCol, hvio) }
Function F3_26(A : LongInt) : LongInt;
Begin
  F3_26 := ViWrtNAttr(P(A, 8), W(A, 6), W(A, 4), W(A, 2), W(A, 0));
End;

{ 27 VioGetCurType(pvioCursorInfo, hvio) }
Function F3_27(A : LongInt) : LongInt;
Begin
  F3_27 := ViGetCurType(P(A, 2), W(A, 0));
End;

{ 32 VioSetCurType(pvioCursorInfo, hvio) }
Function F3_32(A : LongInt) : LongInt;
Begin
  F3_32 := ViSetCurType(P(A, 2), W(A, 0));
End;

{ 46 VioGetConfig(usConfigId, pvioin, hvio) }
Function F3_46(A : LongInt) : LongInt;
Begin
  F3_46 := ViGetConfig(W(A, 6), P(A, 2), W(A, 0));
End;

{ 52 VioWrtNCell(pCell, cb, usRow, usCol, hvio) }
Function F3_52(A : LongInt) : LongInt;
Begin
  F3_52 := ViWrtNCell(P(A, 8), W(A, 6), W(A, 4), W(A, 2), W(A, 0));
End;

{ 53 VioWrtNChar(pch, cb, usRow, usCol, hvio) }
Function F3_53(A : LongInt) : LongInt;
Begin
  F3_53 := ViWrtNChar(P(A, 8), W(A, 6), W(A, 4), W(A, 2), W(A, 0));
End;

{ 1 DosCaseMap(usLen, pctryc, pchStr) }
Function F4_1(A : LongInt) : LongInt;
Begin
  F4_1 := NlCaseMap(W(A, 8), P(A, 4), P(A, 0));
End;

{ 4 DosGetDBCSEv(cbBuf, pctryc, pchBuf) }
Function F4_4(A : LongInt) : LongInt;
Begin
  F4_4 := NlGetDBCSEv(W(A, 8), P(A, 4), P(A, 0));
End;

{ 1 DosPutMessage(hf, cbMsg, pchMsg) }
Function F5_1(A : LongInt) : LongInt;
Begin
  F5_1 := MsPutMessage(W(A, 6), W(A, 4), P(A, 0));
End;

{ 2 DosTrueGetMessage(ppchVTable, usVCount, pchBuf, cbBuf, usMsgNum,
    pszFileName, pcbMsg, pMsgSeg) : DosGetMessage d'OS/2 1.x ; pMsgSeg
    designe le segment de messages lie au programme (MSGBIND) }
Function F5_2(A : LongInt) : LongInt;
Var I, N, T, R : LongInt;
Begin
  N := W(A, 20);
  If N > 9 Then N := 9;
  T := P(A, 22);
  For I := 0 To N - 1 Do
    If T <> 0 Then Tab[I] := KTask(30, PeekW(T + I * 4 + 2), PeekW(T + I * 4), 0)
    Else Tab[I] := 0;
  Tmp[0] := 0;
  R := MsTrueGetMessage(LongInt(@Tab), N, P(A, 16), W(A, 14), W(A, 12), P(A, 8),
                        LongInt(@Tmp), P(A, 0));
  PokeW(P(A, 4), Tmp[0]);
  F5_2 := R;
End;

{ ------------------------------------------------------------------ }
{ taille des arguments (octets) ; -1 : non fournie                     }
{ ------------------------------------------------------------------ }
Function Api16Args(Md, Od : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := -1;
  If Md = 1 Then
    Case Od Of
      3 : R := 0;
      14 : R := 16;
      20 : R := 8;
      49 : R := 4;
      50 : R := 4;
      58 : R := 12;
      59 : R := 2;
      60 : R := 8;
      63 : R := 2;
      65 : R := 12;
      66 : R := 8;
      71 : R := 10;
      72 : R := 8;
      74 : R := 10;
      75 : R := 12;
      77 : R := 10;
      83 : R := 10;
      84 : R := 10;
      86 : R := 2;
      89 : R := 10;
      92 : R := 4;
      95 : R := 32;
      98 : R := 16;
      120 : R := 2;
      137 : R := 12;
      138 : R := 12;
      141 : R := 4;
      142 : R := 8;
      143 : R := 4;
      184 : R := 26;
      204 : R := 30;
    End
  Else If Md = 2 Then
    Case Od Of
      4 : R := 8;
      10, 11, 22 : R := 6;
      13 : R := 2;
    End
  Else If Md = 3 Then
    Case Od Of
      13, 26, 52, 53 : R := 12;
      19 : R := 8;
      27, 32 : R := 6;
      46 : R := 8;
    End
  Else If Md = 4 Then
    Case Od Of
      1, 4 : R := 10;
    End
  Else If Md = 5 Then
    Case Od Of
      1 : R := 8;
      2 : R := 26;
    End;
  Api16Args := R;
End;

exports
  Api16Args Name 'API16ARGS',
  F1_3 Name 'F1_3', F1_14 Name 'F1_14', F1_20 Name 'F1_20', F1_49 Name 'F1_49',
  F1_50 Name 'F1_50', F1_58 Name 'F1_58', F1_59 Name 'F1_59', F1_60 Name 'F1_60',
  F1_63 Name 'F1_63', F1_65 Name 'F1_65', F1_66 Name 'F1_66', F1_71 Name 'F1_71',
  F1_72 Name 'F1_72', F1_74 Name 'F1_74', F1_75 Name 'F1_75', F1_77 Name 'F1_77',
  F1_83 Name 'F1_83', F1_84 Name 'F1_84', F1_86 Name 'F1_86', F1_89 Name 'F1_89',
  F1_92 Name 'F1_92', F1_95 Name 'F1_95', F1_98 Name 'F1_98', F1_120 Name 'F1_120',
  F1_137 Name 'F1_137', F1_138 Name 'F1_138', F1_141 Name 'F1_141',
  F1_142 Name 'F1_142', F1_143 Name 'F1_143', F1_184 Name 'F1_184',
  F1_204 Name 'F1_204',
  F2_4 Name 'F2_4', F2_10 Name 'F2_10', F2_11 Name 'F2_11', F2_13 Name 'F2_13',
  F2_22 Name 'F2_22',
  F3_13 Name 'F3_13', F3_19 Name 'F3_19', F3_26 Name 'F3_26', F3_27 Name 'F3_27',
  F3_32 Name 'F3_32', F3_46 Name 'F3_46', F3_52 Name 'F3_52', F3_53 Name 'F3_53',
  F4_1 Name 'F4_1', F4_4 Name 'F4_4',
  F5_1 Name 'F5_1', F5_2 Name 'F5_2';

BEGIN
END.
