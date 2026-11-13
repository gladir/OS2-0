{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de PMSHAPI.DLL sous OS/2-0.
}

Program TESTSHA;

{$R-,S-,I-}

{ Compilation : OS2PC TESTSHA.PAS   (produit TESTSHA.EXE)

  TESTSHA verifie PMSHAPI.DLL : ses 144 ordinaux et leurs noms (noms en
  majuscules des ordinaux 16 bits), les profils (ecriture par PMSHAPI,
  lecture par PMMERGE et inversement, entiers, donnees, relecture apres
  fermeture), le crochet des profils (SheSetProfileHook, SheProfileHook),
  la liste des programmes et des groupes (Prf* et Win* de PM 1.x), la
  liste des taches (WinAddSwitchEntry, WinQuerySwitchList,
  WinHAPPfromPID...) et quelques points d'entree de l'interpreteur. }

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function GetCurrentProcessId : LongInt; External 'DOSCALLS';

{ ordinaux 16 bits (noms en majuscules) et 32 bits }
Function PRFOPENPROFILE(Hab, P : LongInt) : LongInt; External 'PMSHAPI';
Function PrfCloseProfile(H : LongInt) : LongInt; External 'PMSHAPI';
Function PRFWRITEPROFILESTRING(H, A, K, D : LongInt) : LongInt; External 'PMSHAPI';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMSHAPI';
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMSHAPI';
Function PRFQUERYPROFILEINT(H, A, K, Df : LongInt) : LongInt; External 'PMSHAPI';
Function PrfQueryProfileInt(H, A, K, Df : LongInt) : LongInt; External 'PMSHAPI';
Function PrfQueryProfileSize(H, A, K, P : LongInt) : LongInt; External 'PMSHAPI';
Function PrfQueryProfileData(H, A, K, B, P : LongInt) : LongInt; External 'PMSHAPI';
Function PrfWriteProfileData(H, A, K, D, C : LongInt) : LongInt; External 'PMSHAPI';
Function PrfQueryProfile(Hab, P : LongInt) : LongInt; External 'PMSHAPI';
Function PrfChangeWriteThru(H, F : LongInt) : LongInt; External 'PMSHAPI';
Function WinWriteProfileString(Hab, A, K, D : LongInt) : LongInt; External 'PMSHAPI';
Function WinQueryProfileString(Hab, A, K, Df, B, M : LongInt) : LongInt; External 'PMSHAPI';
Function WinQueryProfileInt(Hab, A, K, Df : LongInt) : LongInt; External 'PMSHAPI';
Function WinWriteProfileData(Hab, A, K, D, C : LongInt) : LongInt; External 'PMSHAPI';
Function WinQueryProfileSize(Hab, A, K, P : LongInt) : LongInt; External 'PMSHAPI';
Function SheSetProfileHook(P : LongInt) : LongInt; External 'PMSHAPI';
Function SheProfileHook(F, A, K : LongInt) : LongInt; External 'PMSHAPI';
Function PrfCreateGroup(H, T, V : LongInt) : LongInt; External 'PMSHAPI';
Function PrfDestroyGroup(H, G : LongInt) : LongInt; External 'PMSHAPI';
Function PrfAddProgram(H, D, G : LongInt) : LongInt; External 'PMSHAPI';
Function PRFCHANGEPROGRAM(H, P, D : LongInt) : LongInt; External 'PMSHAPI';
Function PrfRemoveProgram(H, P : LongInt) : LongInt; External 'PMSHAPI';
Function PrfQueryDefinition(H, P, D, M : LongInt) : LongInt; External 'PMSHAPI';
Function PrfQueryProgramTitles(H, G, B, M, PC : LongInt) : LongInt; External 'PMSHAPI';
Function PrfQueryProgramHandle(H, E, B, M, PC : LongInt) : LongInt; External 'PMSHAPI';
Function PrfQueryProgramCategory(H, E : LongInt) : LongInt; External 'PMSHAPI';
Function WinCreateGroup(Hab, T, V, R1, R2 : LongInt) : LongInt; External 'PMSHAPI';
Function WinDestroyGroup(Hab, G : LongInt) : LongInt; External 'PMSHAPI';
Function WinAddProgram(Hab, D, G : LongInt) : LongInt; External 'PMSHAPI';
Function WinRemoveProgram(Hab, P : LongInt) : LongInt; External 'PMSHAPI';
Function WinQueryProgramTitles(Hab, G, B, M, PC : LongInt) : LongInt; External 'PMSHAPI';
Function WinAddToGroup(Hab, G, P : LongInt) : LongInt; External 'PMSHAPI';
Function WinRemoveFromGroup(Hab, P : LongInt) : LongInt; External 'PMSHAPI';
Function WinQueryProgramUse(Hab, E : LongInt) : LongInt; External 'PMSHAPI';
Function WinQueryProgramType(Hab, E : LongInt) : LongInt; External 'PMSHAPI';
Function ShpLockProgramList : LongInt; External 'PMSHAPI';
Function ShpUnlockProgramList : LongInt; External 'PMSHAPI';
Function WinAddSwitchEntry(P : LongInt) : LongInt; External 'PMSHAPI';
Function WINCREATESWITCHENTRY(Hab, P : LongInt) : LongInt; External 'PMSHAPI';
Function WinQuerySwitchEntry(H, P : LongInt) : LongInt; External 'PMSHAPI';
Function WinChangeSwitchEntry(H, P : LongInt) : LongInt; External 'PMSHAPI';
Function WinQuerySwitchHandle(Hw, Pid : LongInt) : LongInt; External 'PMSHAPI';
Function WinQuerySwitchList(Hab, P, Cb : LongInt) : LongInt; External 'PMSHAPI';
Function WinRemoveSwitchEntry(H : LongInt) : LongInt; External 'PMSHAPI';
Function WinQueryTaskTitle(S, P, Cb : LongInt) : LongInt; External 'PMSHAPI';
Function WinInitSwEntry(P : LongInt) : LongInt; External 'PMSHAPI';
Function WINHAPPFROMPID(Pid : LongInt) : LongInt; External 'PMSHAPI';
Function WinHSWITCHfromHAPP(H : LongInt) : LongInt; External 'PMSHAPI';
Function WinSetFileExtOpts(V : LongInt) : LongInt; External 'PMSHAPI';
Function WinQueryFileExtOpts : LongInt; External 'PMSHAPI';
Function ShellWindow : LongInt; External 'PMSHAPI';

{ les memes donnees vues par PMMERGE.DLL }
Function M_PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryProfileString';
Function M_PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE' Name 'PrfWriteProfileString';
Function M_WinQueryFileExtOpts : LongInt; External 'PMMERGE' Name 'WinQueryFileExtOpts';
Function M_WinQuerySwitchList(Hab, P, Cb : LongInt) : LongInt; External 'PMMERGE' Name 'WinQuerySwitchList';

Const
  HINI_USERPROFILE = -1; SGH_ROOT = -1;
  NOrd = 144;
  Ords : Array[0..143] Of Word = (
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
    33, 34, 35, 36, 37, 38, 39, 42, 43, 44, 45, 46, 47, 48, 49, 50,
    51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66,
    67, 68, 69, 70, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84,
    85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 100, 101, 102,
    103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118,
    119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134,
    151, 152, 153, 154, 155, 156, 157, 158, 160, 201, 208, 209, 210, 211, 212, 213);

Var
  Ok, Fail, R, R2, I, N, A, B, P, Hmod, Ini, Grp, Prg, H1, H2, Happ : LongInt;
  NHook, HkFl, HkRet : LongInt;
  HkApp, HkKey : String;
  Name, Name2, Buf : Array[0..1023] Of Byte;
  Blk : Array[0..4095] Of Byte;
  Det : Array[0..17] Of LongInt;
  Rc1 : Array[0..3] Of LongInt;
  Ctl, Ctl2 : Array[0..99] Of Byte;
  OutBuf : Array[0..8191] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function RdL(A : LongInt) : LongInt;
Type PLong = ^LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Procedure WrL(A, V : LongInt);
Type PLong = ^LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Function RdB(A : LongInt) : LongInt;
Type PByte = ^Byte;
Var Q : PByte;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrB(A, V : LongInt);
Type PByte = ^Byte;
Var Q : PByte;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := ''; K := 0;
  If A <> 0 Then
    While (K < 255) And (RdB(A + K) <> 0) Do
    Begin
      S := S + Chr(RdB(A + K));
      Inc(K);
    End;
  GetZ := S;
End;

Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Name[K - 1] := Ord(S[K]);
  Name[Length(S)] := 0;
  Z := LongInt(@Name);
End;

Function Z2(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Name2[K - 1] := Ord(S[K]);
  Name2[Length(S)] := 0;
  Z2 := LongInt(@Name2);
End;

Function Zb(Ofs : LongInt; S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Buf[Ofs + K - 1] := Ord(S[K]);
  Buf[Ofs + Length(S)] := 0;
  Zb := LongInt(@Buf) + Ofs;
End;

Procedure SetCtl(P, Hwnd, Icon, Vis, Jump : LongInt; T : String);
Var K : LongInt;
Begin
  For K := 0 To 99 Do WrB(P + K, 0);
  WrL(P, Hwnd);
  WrL(P + 4, Icon);
  WrL(P + 20, Vis);
  WrL(P + 24, Jump);
  For K := 1 To Length(T) Do WrB(P + 27 + K, Ord(T[K]));
End;

Procedure OutStr(T : String);
Var K : LongInt;
Begin
  For K := 1 To Length(T) Do
    If OutLen < 8190 Then
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

{ crochet des profils (programme OS2PC : convention Pascal) }
Function ProfHook(Fl, PApp, PKey : LongInt) : LongInt;
Begin
  Inc(NHook);
  HkFl := Fl;
  HkApp := GetZ(PApp);
  HkKey := GetZ(PKey);
  ProfHook := HkRet;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTSHA : essai de PMSHAPI.DLL');

  { --- ordinaux et noms --- }
  Hmod := 0;
  R := DosQueryModuleHandle(Z('PMSHAPI'), LongInt(@Hmod));
  N := 0;
  For I := 0 To NOrd - 1 Do
  Begin
    P := 0;
    If DosQueryProcAddr(Hmod, Ords[I], 0, LongInt(@P)) = 0 Then
      If P <> 0 Then Inc(N);
  End;
  Check('144 ordinaux de PMSHAPI (' + IStr(N) + ')', N = 144);
  P := 0; A := 0;
  R := DosQueryProcAddr(Hmod, 0, Z('WINSTARTAPP'), LongInt(@P));
  R2 := DosQueryProcAddr(Hmod, 0, Z('WinStartApp'), LongInt(@A));
  Check('noms WINSTARTAPP (119) et WinStartApp (201)', (R = 0) And (R2 = 0) And (P <> 0) And (A <> 0));
  P := 0; A := 0; B := 0;
  R := DosQueryProcAddr(Hmod, 0, Z('startSystemExecutables'), LongInt(@P));
  R := DosQueryProcAddr(Hmod, 0, Z('StartSystemExecutables'), LongInt(@A));
  R := DosQueryProcAddr(Hmod, 0, Z('SheSetProfileHook'), LongInt(@B));
  Check('noms startSystemExecutables (89), StartSystemExecutables (152), SheSetProfileHook', (P <> 0) And
        (A <> 0) And (B <> 0));

  { --- profils --- }
  R := DosDelete(Z('D:\SHAPI.INI'));
  Ini := PRFOPENPROFILE(0, Z('D:\SHAPI.INI'));
  Check('PRFOPENPROFILE (ordinal 38)', (Ini Shr 16) = $494E);
  R := PRFWRITEPROFILESTRING(Ini, Z('Shell'), Z2('Nom'), Zb(0, 'PMSHAPI'));
  R2 := PrfWriteProfileString(Ini, Z('Shell'), Z2('Taille'), Zb(0, '123'));
  Check('PRFWRITEPROFILESTRING (34), PrfWriteProfileString (116)', (R = 1) And (R2 = 1));
  R := M_PrfQueryProfileString(Ini, Z('Shell'), Z2('Nom'), 0, LongInt(@Buf), 100);
  Check('lecture par PMMERGE (' + GetZ(LongInt(@Buf)) + ')', (R = 8) And (GetZ(LongInt(@Buf)) = 'PMSHAPI'));
  R := M_PrfWriteProfileString(Ini, Z('Shell'), Z2('Merge'), Zb(0, 'oui'));
  R2 := PrfQueryProfileString(Ini, Z('Shell'), Z2('Merge'), 0, LongInt(@Buf), 100);
  Check('ecriture par PMMERGE, lecture par PMSHAPI', (R = 1) And (GetZ(LongInt(@Buf)) = 'oui'));
  R := PRFQUERYPROFILEINT(Ini, Z('Shell'), Z2('Taille'), 5);
  R2 := PrfQueryProfileInt(Ini, Z('Shell'), Z2('Absente'), 5);
  Check('PRFQUERYPROFILEINT (123), PrfQueryProfileInt (defaut 5)', (R = 123) And (R2 = 5));
  For I := 0 To 7 Do Buf[I] := I + 10;
  R := PrfWriteProfileData(Ini, Z('Bin'), Z2('Octets'), LongInt(@Buf), 8);
  N := 0;
  R2 := PrfQueryProfileSize(Ini, Z('Bin'), Z2('Octets'), LongInt(@N));
  Check('PrfWriteProfileData, PrfQueryProfileSize (' + IStr(N) + ')', (R = 1) And (R2 = 1) And (N = 8));
  R := PrfChangeWriteThru(Ini, 0);
  R := PrfWriteProfileString(Ini, Z('Shell'), Z2('Retard'), Zb(0, 'x'));
  R := PrfCloseProfile(Ini);
  Ini := PRFOPENPROFILE(0, Z('D:\SHAPI.INI'));
  For I := 0 To 9 Do Buf[I] := 0;
  N := 10;
  R := PrfQueryProfileData(Ini, Z('Bin'), Z2('Octets'), LongInt(@Buf), LongInt(@N));
  R2 := PrfQueryProfileString(Ini, Z('Shell'), Z2('Retard'), 0, LongInt(@Buf) + 100, 100);
  Check('PrfChangeWriteThru, PrfCloseProfile, relecture', (R = 1) And (N = 8) And (Buf[7] = 17) And
        (GetZ(LongInt(@Buf) + 100) = 'x'));
  For I := 0 To 3 Do Det[I] := 0;
  Det[0] := 100; Det[1] := LongInt(@Buf); Det[2] := 100; Det[3] := LongInt(@Buf) + 100;
  R := PrfQueryProfile(0, LongInt(@Det));
  Check('PrfQueryProfile (' + GetZ(LongInt(@Buf)) + ')', (R = 1) And (Pos('OS2.INI', GetZ(LongInt(@Buf))) > 0));

  { --- crochet des profils --- }
  NHook := 0; HkRet := 77;
  R := SheSetProfileHook(LongInt(@ProfHook));
  R2 := PrfWriteProfileString(Ini, Z('Crochet'), Z2('Cle'), Zb(0, 'a'));
  Check('SheSetProfileHook, appel apres PrfWriteProfileString (' + IStr(NHook) + ', ' + HkApp + ', ' + HkKey + ')',
        (R = 1) And (R2 = 1) And (NHook = 1) And (HkFl = Ini) And (HkApp = 'Crochet') And (HkKey = 'Cle'));
  R := WinWriteProfileString(0, Z('TESTSHA'), Z2('Essai'), Zb(0, '42'));
  R2 := WinQueryProfileInt(0, Z('TESTSHA'), Z2('Essai'), 0);
  Check('WinWriteProfileString : crochet (HINI_USERPROFILE), WinQueryProfileInt', (R = 1) And (R2 = 42) And
        (NHook = 2) And (HkFl = HINI_USERPROFILE) And (HkApp = 'TESTSHA'));
  R := WinWriteProfileData(0, Z('TESTSHA'), Z2('Bloc'), LongInt(@Rc1), 16);
  N := 0;
  R2 := WinQueryProfileSize(0, Z('TESTSHA'), Z2('Bloc'), LongInt(@N));
  Check('WinWriteProfileData, WinQueryProfileSize (' + IStr(N) + ')', (R = 1) And (N = 16) And (NHook = 3) And
        (HkKey = 'Bloc'));
  R := WinWriteProfileString(0, Z('TESTSHA'), 0, 0);
  R2 := WinQueryProfileString(0, Z('TESTSHA'), Z2('Essai'), Zb(200, 'non'), LongInt(@Buf), 100);
  Check('suppression de l''application (crochet : cle nulle)', (R = 1) And (GetZ(LongInt(@Buf)) = 'non') And
        (NHook = 4) And (HkKey = ''));
  R := SheProfileHook(5, Z('App'), Z2('Key'));
  Check('SheProfileHook appelle le crochet (' + IStr(R) + ')', (R = 77) And (NHook = 5) And (HkFl = 5) And
        (HkApp = 'App') And (HkKey = 'Key'));
  R := SheSetProfileHook(0);
  R2 := PrfWriteProfileString(Ini, Z('Crochet'), Z2('Cle'), Zb(0, 'b'));
  Check('SheSetProfileHook(0) : crochet retire', (R = 1) And (R2 = 1) And (NHook = 5) And
        (SheProfileHook(5, 0, 0) = 0));
  R := PrfCloseProfile(Ini);

  { --- programmes et groupes --- }
  Ini := PRFOPENPROFILE(0, Z('D:\SHPROG.INI'));
  Grp := PrfCreateGroup(Ini, Z('Outils'), 0);
  For I := 0 To 17 Do Det[I] := 0;
  Det[0] := 72; Det[1] := 2; Det[3] := Zb(0, 'Copie'); Det[4] := Zb(20, 'C:\XCOPY.EXE');
  Prg := PrfAddProgram(Ini, LongInt(@Det), Grp);
  N := 0;
  R := PrfQueryProgramTitles(Ini, Grp, LongInt(@Buf), 1024, LongInt(@N));
  Check('PrfCreateGroup, PrfAddProgram, PrfQueryProgramTitles (' + IStr(N) + ')', (Grp <> 0) And (Prg <> 0) And
        (N = 1) And (GetZ(RdL(LongInt(@Buf) + 12)) = 'Copie'));
  R := PrfQueryDefinition(Ini, Prg, LongInt(@Buf), 1024);
  N := 0;
  R2 := PrfQueryProgramHandle(Ini, Z('c:\xcopy.exe'), LongInt(@Rc1), 16, LongInt(@N));
  Check('PrfQueryDefinition, PrfQueryProgramHandle, PrfQueryProgramCategory', (R > 72) And
        (GetZ(RdL(LongInt(@Buf) + 16)) = 'C:\XCOPY.EXE') And (R2 = 1) And (N = 1) And (Rc1[0] = Prg) And
        (PrfQueryProgramCategory(Ini, Z('C:\XCOPY.EXE')) = 2));
  Det[3] := Zb(0, 'Xcopy');
  R := PRFCHANGEPROGRAM(Ini, Prg, LongInt(@Det));
  R2 := PrfQueryDefinition(Ini, Prg, LongInt(@Buf), 1024);
  Check('PRFCHANGEPROGRAM (52)', (R = 1) And (GetZ(RdL(LongInt(@Buf) + 12)) = 'Xcopy'));
  R := PrfRemoveProgram(Ini, Prg);
  R2 := PrfDestroyGroup(Ini, Grp);
  A := PrfQueryProgramTitles(Ini, SGH_ROOT, 0, 0, LongInt(@N));
  Check('PrfRemoveProgram, PrfDestroyGroup', (R = 1) And (R2 = 1) And (N = 0));
  R := PrfCloseProfile(Ini);
  R := ShpLockProgramList;
  Grp := WinCreateGroup(0, Z('Groupe PM 1.x'), 0, 0, 0);
  For I := 0 To 17 Do Det[I] := 0;
  Det[0] := 72; Det[1] := 1; Det[3] := Zb(0, 'Sauvegarde'); Det[4] := Zb(20, 'C:\BACKUP.EXE');
  Prg := WinAddProgram(0, LongInt(@Det), SGH_ROOT);
  R := WinAddToGroup(0, Grp, Prg);
  N := 0;
  R2 := WinQueryProgramTitles(0, Grp, LongInt(@Buf), 1024, LongInt(@N));
  Check('WinCreateGroup, WinAddProgram, WinAddToGroup, WinQueryProgramTitles', (Grp <> 0) And (Prg <> 0) And
        (R = 1) And (N = 1) And (RdL(LongInt(@Buf)) = Prg));
  Check('WinQueryProgramUse, WinQueryProgramType', (WinQueryProgramUse(0, Z('C:\BACKUP.EXE')) = 1) And
        (WinQueryProgramType(0, Z('C:\BACKUP.EXE')) = 1));
  R := WinRemoveFromGroup(0, Prg);
  R2 := WinQueryProgramTitles(0, Grp, 0, 0, LongInt(@N));
  Check('WinRemoveFromGroup', (R = 1) And (N = 0));
  R := WinRemoveProgram(0, Prg);
  R2 := WinDestroyGroup(0, Grp);
  Check('WinRemoveProgram, WinDestroyGroup, ShpUnlockProgramList', (R = 1) And (R2 = 1) And
        (ShpUnlockProgramList = 1));

  { --- liste des taches --- }
  N := WinQuerySwitchList(0, 0, 0);
  R := WinInitSwEntry(LongInt(@Ctl));
  Check('WinQuerySwitchList (nombre : ' + IStr(N) + '), WinInitSwEntry', (N >= 0) And (R = 1) And
        (RdL(LongInt(@Ctl) + 12) = GetCurrentProcessId));
  SetCtl(LongInt(@Ctl), $2345, 0, 4, 2, 'Shell');
  H1 := WinAddSwitchEntry(LongInt(@Ctl));
  SetCtl(LongInt(@Ctl), $3456, 0, 4, 2, 'Second');
  H2 := WINCREATESWITCHENTRY(0, LongInt(@Ctl));
  R := WinQuerySwitchEntry(H1, LongInt(@Ctl2));
  Check('WinAddSwitchEntry, WINCREATESWITCHENTRY (46), WinQuerySwitchEntry', (H1 <> 0) And (H2 <> 0) And
        (H1 <> H2) And (R = 0) And (GetZ(LongInt(@Ctl2) + 28) = 'Shell'));
  SetCtl(LongInt(@Ctl), $2345, 0, 4, 2, 'Shell modifie');
  R := WinChangeSwitchEntry(H1, LongInt(@Ctl));
  R2 := WinQuerySwitchEntry(H1, LongInt(@Ctl2));
  Check('WinChangeSwitchEntry, WinQuerySwitchHandle', (R = 0) And (GetZ(LongInt(@Ctl2) + 28) = 'Shell modifie') And
        (WinQuerySwitchHandle($3456, 0) = H2));
  R := WinQuerySwitchList(0, LongInt(@Blk), 4096);
  R2 := M_WinQuerySwitchList(0, LongInt(@Blk) + 2048, 2048);
  Check('WinQuerySwitchList (' + IStr(R) + ' entrees, PMMERGE : ' + IStr(R2) + ')', (R = N + 2) And (R2 = R) And
        (RdL(LongInt(@Blk)) = R));
  Happ := WINHAPPFROMPID(GetCurrentProcessId);
  A := WinHSWITCHfromHAPP(Happ);
  Check('WINHAPPFROMPID (154), WinHSWITCHfromHAPP (' + IStr(Happ) + ', ' + IStr(A) + ')', (Happ <> 0) And (A <> 0));
  R := WinQueryTaskTitle(0, LongInt(@Buf), 64);
  Check('WinQueryTaskTitle (' + GetZ(LongInt(@Buf)) + ')', R = 0);
  R := WinRemoveSwitchEntry(H1);
  R2 := WinRemoveSwitchEntry(H2);
  Check('WinRemoveSwitchEntry', (R = 0) And (R2 = 0) And (WinQuerySwitchList(0, 0, 0) = N));

  { --- divers --- }
  A := WinQueryFileExtOpts;
  R := WinSetFileExtOpts(5);
  Check('WinSetFileExtOpts, WinQueryFileExtOpts (vu par PMMERGE)', (R = 1) And (WinQueryFileExtOpts = 5) And
        (M_WinQueryFileExtOpts = 5));
  R := WinSetFileExtOpts(A);
  P := ShellWindow;
  Check('ShellWindow (adresse de la donnee)', (P <> 0) And (RdL(P) = $00010001));

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTSHA : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
