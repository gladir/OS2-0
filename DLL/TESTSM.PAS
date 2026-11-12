{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de OS2SM.DLL sous OS/2-0.
}

Program TESTSM;

{$R-,S-,I-}

{ Compilation : OS2PC TESTSM.PAS   (produit TESTSM.EXE)

  TESTSM             verifie les 46 points d'entree de OS2SM.DLL (liste
                     des taches, sessions, OS2SM.INI) ; les sessions
                     executent TESTSM KID titre.
  TESTSM KID titre   programme d'une session : rend 42 si le titre de sa
                     tache (WinQueryTaskTitle) est titre et s'il a une
                     entree dans la liste des taches, sinon 7. }

Function WinInitSessionMgr(Reserved : LongInt) : LongInt; External 'OS2SM' Name 'WININITSESSIONMGR';
Function WinSetFgndWindow(Hwnd : LongInt) : LongInt; External 'OS2SM' Name 'WINSETFGNDWINDOW';
Function ShlUnloadPublicFonts : LongInt; External 'OS2SM' Name 'SHLUNLOADPUBLICFONTS';
Function WinStpRegister(Hwnd : LongInt) : LongInt; External 'OS2SM' Name 'WINSTPREGISTER';
Function WinInstStartApp(HNotify, PDet, PParams, PRes, Opt : LongInt) : LongInt; External 'OS2SM' Name 'WININSTSTARTAPP';
Function WinTerminateApp(Happ : LongInt) : LongInt; External 'OS2SM' Name 'WINTERMINATEAPP';
Function WinCreateSwitchEntry(Hab, P : LongInt) : LongInt; External 'OS2SM' Name 'WINCREATESWITCHENTRY';
Function WinQuerySessionTitle(Hab, S, PTitle, Cb : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYSESSIONTITLE';
Function WinAddSwitchEntry(P : LongInt) : LongInt; External 'OS2SM' Name 'WINADDSWITCHENTRY';
Function WinChangeSwitchEntry(H, P : LongInt) : LongInt; External 'OS2SM' Name 'WINCHANGESWITCHENTRY';
Function WinQuerySwitchEntry(H, P : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYSWITCHENTRY';
Function WinQuerySwitchHandle(Hwnd, Pid : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYSWITCHHANDLE';
Function WinQueryTaskTitle(S, PTitle, Cb : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYTASKTITLE';
Function WinQueryTaskSizePos(Hab, S, P : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYTASKSIZEPOS';
Function WinQuerySwitchList(Hab, PBlk, Cb : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYSWITCHLIST';
Function WinRemoveSwitchEntry(H : LongInt) : LongInt; External 'OS2SM' Name 'WINREMOVESWITCHENTRY';
Function WinSwitchToProgram(H : LongInt) : LongInt; External 'OS2SM' Name 'WINSWITCHTOPROGRAM';
Function WinSwitchProgramRegister(Hwnd : LongInt) : LongInt; External 'OS2SM' Name 'WINSWITCHPROGRAMREGISTER';
Function WinExecProgram(PProg, PParams, PResult : LongInt) : LongInt; External 'OS2SM' Name 'WINEXECPROGRAM';
Function SheStartProgram(PStd, PSid : LongInt) : LongInt; External 'OS2SM' Name 'SHESTARTPROGRAM';
Function WinEndProgram(H : LongInt) : LongInt; External 'OS2SM' Name 'WINENDPROGRAM';
Function WinStopProgram(H : LongInt) : LongInt; External 'OS2SM' Name 'WINSTOPPROGRAM';
Function WinEndWindowSession(H : LongInt) : LongInt; External 'OS2SM' Name 'WINENDWINDOWSESSION';
Function ShellWndProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'OS2SM' Name 'LPFNSHELLWNDPROC';
Function IconWndProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'OS2SM' Name 'LPFNICONWNDPROC';
Function WinSwitchToTaskManager : LongInt; External 'OS2SM' Name 'WINSWITCHTOTASKMANAGER';
Function BadAppDlgProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'OS2SM' Name 'FNBADAPPDLGPROC';
Function WinSwitchToProgram2(H, Fl : LongInt) : LongInt; External 'OS2SM' Name 'WINSWITCHTOPROGRAM2';
Function WinProcessHotKey(Scan, State : LongInt) : LongInt; External 'OS2SM' Name 'WINPROCESSHOTKEY';
Function WinSave(PIni : LongInt) : LongInt; External 'OS2SM' Name 'WINSAVE';
Function WinInitSession(S, PTitle : LongInt) : LongInt; External 'OS2SM' Name 'WININITSESSION';
Function WinEndSession(S : LongInt) : LongInt; External 'OS2SM' Name 'WINENDSESSION';
Function WinInitSwEntry(P : LongInt) : LongInt; External 'OS2SM' Name 'WININITSWENTRY';
Function WinSetSwEntry(H, P : LongInt) : LongInt; External 'OS2SM' Name 'WINSETSWENTRY';
Function WinQueryExtIdFocus(PId : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYEXTIDFOCUS';
Function WinSetExtIdFocus(Id : LongInt) : LongInt; External 'OS2SM' Name 'WINSETEXTIDFOCUS';
Function SheSystemShutdown(Fl : LongInt) : LongInt; External 'OS2SM' Name 'SHESYSTEMSHUTDOWN';
Function StartSystemExecutables(PIni : LongInt) : LongInt; External 'OS2SM' Name 'STARTSYSTEMEXECUTABLES';
Function ShlLoadPublicFonts(PIni : LongInt) : LongInt; External 'OS2SM' Name 'SHLLOADPUBLICFONTS';
Function WinNoShutdown(Block : LongInt) : LongInt; External 'OS2SM' Name 'WINNOSHUTDOWN';
Function SheInitializeIniFile(PIni : LongInt) : LongInt; External 'OS2SM' Name 'SHEINITIALIZEINIFILE';
Function WinSetTitle(PTitle : LongInt) : LongInt; External 'OS2SM' Name 'WINSETTITLE';
Function WinCplRegister(PName : LongInt) : LongInt; External 'OS2SM' Name 'WINCPLREGISTER';
Function WinPMFileRegister(PName : LongInt) : LongInt; External 'OS2SM' Name 'WINPMFILEREGISTER';
Function SheStartLongProgram(PProg, PParams, PTitle, Bg, PSid : LongInt) : LongInt; External 'OS2SM' Name 'SHESTARTLONGPROGRAM';

Function DosSMGetStatus(PBuf, Cb, PcbOut : LongInt) : LongInt; External 'SESMGR';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosExit(Action, Code : LongInt) : LongInt; External 'DOSCALLS';
Function GetCurrentProcessId : LongInt; External 'DOSCALLS';

Const
  PMERR_PARAMETER_OUT_OF_RANGE = $1003;
  PMERR_INVALID_SWITCH_HANDLE  = $1207;
  PMERR_INVALID_SESSION_ID     = $120B;
  WM_COMMAND       = $0020;
  WM_BUTTON1DBLCLK = $0073;
  IniFile = 'C:\TSM.INI';

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, C, Sid, Sid2, Sid3, Sid4, Pid, H1, H2, H3, N0, Happ : LongInt;
  Name, Name2, Name3 : Array[0..127] Of Byte;
  Ctl, Ctl2 : Array[0..99] Of Byte;     { SWCNTRL }
  Blk : Array[0..4095] Of Byte;         { SWBLOCK }
  Swp : Array[0..35] Of Byte;           { SWP }
  Det : Array[0..79] Of Byte;           { PROGDETAILS }
  Sd : Array[0..63] Of Byte;            { STARTDATA }
  TBuf : Array[0..79] Of Byte;
  Buf : Array[0..1023] Of Byte;
  Info : Array[0..63] Of Byte;
  Title, Prog, Inputs : Array[0..63] Of Byte;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;
  Txt : String;

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

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
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

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  K := 0;
  While (RdB(A + K) <> 0) And (K < 200) Do
  Begin
    S := S + Chr(RdB(A + K));
    Inc(K);
  End;
  GetZ := S;
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

Function Z3(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name3), S);
  Z3 := LongInt(@Name3);
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

{ SWCNTRL : fenetre, icone, visibilite, saut, titre }
Procedure SetCtl(P, Hwnd, Icon, Vis, Jump : LongInt; T : String);
Var K : LongInt;
Begin
  For K := 0 To 99 Do WrB(P + K, 0);
  WrL(P, Hwnd);
  WrL(P + 4, Icon);
  WrL(P + 20, Vis);
  WrL(P + 24, Jump);
  PutZ(P + 28, T);
End;

{ Etat d'une session (DosSMGetStatus, champ Ofs : mot) ; -1 si libre }
Function StatW(S, Ofs : LongInt) : LongInt;
Var K, Cb, V, D : LongInt;
Begin
  V := -1;
  Cb := 0;
  D := DosSMGetStatus(LongInt(@Buf), 1024, LongInt(@Cb));
  K := 0;
  While K < Cb Do
  Begin
    If RdW(LongInt(@Buf) + K) = S Then V := RdW(LongInt(@Buf) + K + Ofs);
    K := K + 16;
  End;
  StatW := V;
End;

{ Nombre d'entrees de la liste des taches }
Function Count : LongInt;
Begin
  Count := WinQuerySwitchList(0, 0, 0);
End;

{ Premiere entree de la session S dans la liste des taches (0 : aucune) }
Function SesHandle(S : LongInt) : LongInt;
Var K, N, V : LongInt;
Begin
  V := 0;
  N := WinQuerySwitchList(0, LongInt(@Blk), 4096);
  For K := 0 To RdL(LongInt(@Blk)) - 1 Do
    If (V = 0) And (RdL(LongInt(@Blk) + 4 + K * 100 + 4 + 16) = S) Then V := RdL(LongInt(@Blk) + 4 + K * 100);
  SesHandle := V;
End;

{ Titre de l'entree de la session S }
Function SesTitle(S : LongInt) : String;
Var D : LongInt;
Begin
  WrB(LongInt(@TBuf), 0);
  D := WinQueryTaskTitle(S, LongInt(@TBuf), 64);
  SesTitle := GetZ(LongInt(@TBuf));
End;

{ STARTDATA : TESTSM KID titre en arriere-plan }
Procedure SetSd(T : String; FgBg : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 63 Do Sd[K] := 0;
  WrW(LongInt(@Sd), 50);
  WrW(LongInt(@Sd) + 4, FgBg);
  PutZ(LongInt(@Title), T);
  PutZ(LongInt(@Prog), 'C:\TESTSM.EXE');
  PutZ(LongInt(@Inputs), 'KID ' + T);
  WrL(LongInt(@Sd) + 8, LongInt(@Title));
  WrL(LongInt(@Sd) + 12, LongInt(@Prog));
  WrL(LongInt(@Sd) + 16, LongInt(@Inputs));
End;

{ Ecrire un fichier texte }
Function WriteText(F, T : String) : LongInt;
Var Hf, Act, W, D : LongInt;
Begin
  PutZ(LongInt(@Buf), T);
  D := DosOpen(Z(F), LongInt(@Hf), LongInt(@Act), 0, 0, $12, $41, 0);
  If D = 0 Then
  Begin
    D := DosWrite(Hf, LongInt(@Buf), Length(T), LongInt(@W));
    A := DosClose(Hf);
  End;
  WriteText := D;
End;

{ Lire un fichier texte (1000 octets au plus) }
Function ReadText(F : String) : String;
Var Hf, Act, Got, D, K : LongInt; S : String;
Begin
  S := '';
  Got := 0;
  If DosOpen(Z(F), LongInt(@Hf), LongInt(@Act), 0, 0, 1, $40, 0) = 0 Then
  Begin
    D := DosRead(Hf, LongInt(@Buf), 1000, LongInt(@Got));
    D := DosClose(Hf);
  End;
  For K := 0 To Got - 1 Do
    If (Length(S) < 250) And (Buf[K] <> 13) Then
    Begin
      If Buf[K] = 10 Then S := S + '|' Else S := S + Chr(Buf[K]);
    End;
  ReadText := S;
End;

{ --- programme d'une session --- }
Procedure KidMode;
Var T : String; Code, Hs, D : LongInt;
Begin
  Code := 7;
  WrB(LongInt(@TBuf), 0);
  D := WinQueryTaskTitle(0, LongInt(@TBuf), 64);
  T := GetZ(LongInt(@TBuf));
  Hs := WinQuerySwitchHandle(0, 0);
  If (D = 0) And (T = ParamStr(2)) And (Hs <> 0) Then Code := 42;
  WriteLn('TESTSM KID : tache "', T, '", entree ', Hs, ', code ', Code);
  A := DosExit(1, Code);
End;

BEGIN
  If (ParamCount > 0) And (ParamStr(1) = 'KID') Then KidMode;
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTSM : essai de OS2SM.DLL');

  { --- module, ordinaux, donnee SHELLWINDOW --- }
  R := DosQueryModuleHandle(Z('OS2SM'), LongInt(@H));
  Check('DosQueryModuleHandle OS2SM', R = 0);
  Check('ordinaux 1 a 15', OrdIs(1, 'WININITSESSIONMGR') And OrdIs(2, 'WINSETFGNDWINDOW') And
        OrdIs(3, 'SHLUNLOADPUBLICFONTS') And OrdIs(4, 'WINSTPREGISTER') And OrdIs(5, 'WININSTSTARTAPP') And
        OrdIs(6, 'WINTERMINATEAPP') And OrdIs(7, 'WINCREATESWITCHENTRY') And OrdIs(8, 'WINQUERYSESSIONTITLE') And
        OrdIs(9, 'WINADDSWITCHENTRY') And OrdIs(10, 'WINCHANGESWITCHENTRY') And OrdIs(11, 'WINQUERYSWITCHENTRY') And
        OrdIs(12, 'WINQUERYSWITCHHANDLE') And OrdIs(13, 'WINQUERYTASKTITLE') And OrdIs(14, 'WINQUERYTASKSIZEPOS') And
        OrdIs(15, 'WINQUERYSWITCHLIST'));
  Check('ordinaux 16 a 30', OrdIs(16, 'WINREMOVESWITCHENTRY') And OrdIs(17, 'WINSWITCHTOPROGRAM') And
        OrdIs(18, 'WINSWITCHPROGRAMREGISTER') And OrdIs(19, 'WINEXECPROGRAM') And OrdIs(20, 'SHESTARTPROGRAM') And
        OrdIs(21, 'WINENDPROGRAM') And OrdIs(22, 'WINSTOPPROGRAM') And OrdIs(23, 'WINENDWINDOWSESSION') And
        OrdIs(24, 'LPFNSHELLWNDPROC') And OrdIs(25, 'LPFNICONWNDPROC') And OrdIs(26, 'WINSWITCHTOTASKMANAGER') And
        OrdIs(27, 'FNBADAPPDLGPROC') And OrdIs(28, 'WINSWITCHTOPROGRAM2') And OrdIs(29, 'WINPROCESSHOTKEY') And
        OrdIs(30, 'WINSAVE'));
  Check('ordinaux 31 a 45', OrdIs(31, 'WININITSESSION') And OrdIs(32, 'WINENDSESSION') And
        OrdIs(33, 'WININITSWENTRY') And OrdIs(34, 'WINSETSWENTRY') And OrdIs(35, 'WINQUERYEXTIDFOCUS') And
        OrdIs(36, 'WINSETEXTIDFOCUS') And OrdIs(37, 'SHESYSTEMSHUTDOWN') And OrdIs(38, 'STARTSYSTEMEXECUTABLES') And
        OrdIs(39, 'SHLLOADPUBLICFONTS') And OrdIs(40, 'WINNOSHUTDOWN') And OrdIs(41, 'SHEINITIALIZEINIFILE') And
        OrdIs(42, 'WINSETTITLE') And OrdIs(43, 'WINCPLREGISTER') And OrdIs(44, 'WINPMFILEREGISTER') And
        OrdIs(45, 'SHESTARTLONGPROGRAM'));
  A := 0;
  R := DosQueryProcAddr(H, 103, 0, LongInt(@A));
  Check('donnee SHELLWINDOW (ordinal 103)', (R = 0) And OrdIs(103, 'SHELLWINDOW') And (RdL(A) = $00010001));
  Check('ordinal 46 inexistant', DosQueryProcAddr(H, 46, 0, LongInt(@A)) <> 0);

  { --- session au premier plan avant WinInitSessionMgr (Dos32StartSession) --- }
  Sid := 0;
  R := SheStartLongProgram(Z('C:\TESTSM.EXE'), Z2('KID ENFANT'), Z3('ENFANT'), 0, LongInt(@Sid));
  Check('SheStartLongProgram au premier plan (session ' + IStr(Sid) + ')', (R = 0) And (Sid >= 2));
  Check('session terminee : retiree de la liste des taches', SesHandle(Sid) = 0);

  { --- WinInitSessionMgr --- }
  R := WinInitSessionMgr(0);
  R2 := WinInitSessionMgr(0);
  Check('WinInitSessionMgr (deux fois)', (R = 1) And (R2 = 1));
  A := StatW(Sid, 14);
  Check('programme de la session : titre ENFANT et entree vus (code 42)', A = 42);
  N0 := Count;
  Check('liste des taches : entree de la session 1', (N0 = 1) And (SesHandle(1) <> 0) And
        (SesTitle(1) = 'Interpreteur de commandes'));

  { --- entrees --- }
  R := WinInitSwEntry(LongInt(@Ctl));
  Check('WinInitSwEntry : processus, session 1, visible, accessible', (R = 1) And
        (RdL(LongInt(@Ctl) + 12) = GetCurrentProcessId) And (RdL(LongInt(@Ctl) + 16) = 1) And
        (RdL(LongInt(@Ctl) + 20) = 4) And (RdL(LongInt(@Ctl) + 24) = 2) And
        (GetZ(LongInt(@Ctl) + 28) = 'Interpreteur de commandes'));
  SetCtl(LongInt(@Ctl), $1234, $5678, 9, 2, 'Essai');
  R := WinAddSwitchEntry(LongInt(@Ctl));
  SetCtl(LongInt(@Ctl), $1234, $5678, 4, 0, 'Essai');
  R2 := WinAddSwitchEntry(LongInt(@Ctl));
  Check('WinAddSwitchEntry : visibilite ou saut invalide refuse', (R = 0) And (R2 = 0));
  SetCtl(LongInt(@Ctl), $1234, $5678, 4, 2, 'Essai');
  H1 := WinAddSwitchEntry(LongInt(@Ctl));
  SetCtl(LongInt(@Ctl), $4321, 0, 2, 1, 'Deuxieme');
  H2 := WinCreateSwitchEntry(0, LongInt(@Ctl));
  Check('WinAddSwitchEntry, WinCreateSwitchEntry', (H1 <> 0) And (H2 <> 0) And (H1 <> H2) And (Count = N0 + 2));
  R := WinQuerySwitchEntry(H1, LongInt(@Ctl2));
  Check('WinQuerySwitchEntry : fenetre, icone, processus, session, titre', (R = 0) And
        (RdL(LongInt(@Ctl2)) = $1234) And (RdL(LongInt(@Ctl2) + 4) = $5678) And
        (RdL(LongInt(@Ctl2) + 12) = GetCurrentProcessId) And (RdL(LongInt(@Ctl2) + 16) = 1) And
        (GetZ(LongInt(@Ctl2) + 28) = 'Essai'));
  A := WinQuerySwitchHandle($4321, 0);
  B := WinQuerySwitchHandle(0, GetCurrentProcessId);
  C := WinQuerySwitchHandle($9999, 0);
  Check('WinQuerySwitchHandle par fenetre, par processus ; inconnue : 0', (A = H2) And (B = H1) And (C = 0));
  SetCtl(LongInt(@Ctl), $1234, $5678, 4, 2, 'Modifie');
  WrL(LongInt(@Ctl) + 12, 999);
  R := WinChangeSwitchEntry(H1, LongInt(@Ctl));
  R2 := WinQuerySwitchEntry(H1, LongInt(@Ctl2));
  Check('WinChangeSwitchEntry : titre change, processus garde', (R = 0) And (R2 = 0) And
        (GetZ(LongInt(@Ctl2) + 28) = 'Modifie') And (RdL(LongInt(@Ctl2) + 12) = GetCurrentProcessId));
  R := WinSetSwEntry(H1, LongInt(@Ctl));
  R2 := WinQuerySwitchEntry(H1, LongInt(@Ctl2));
  Check('WinSetSwEntry : tous les champs (processus 999)', (R = 0) And (R2 = 0) And (RdL(LongInt(@Ctl2) + 12) = 999));
  WrL(LongInt(@Ctl) + 12, GetCurrentProcessId);
  R := WinSetSwEntry(H1, LongInt(@Ctl));
  R := WinChangeSwitchEntry($7777, LongInt(@Ctl));
  R2 := WinQuerySwitchEntry($7777, LongInt(@Ctl2));
  Check('handle d''entree invalide refuse', (R = PMERR_INVALID_SWITCH_HANDLE) And (R2 = PMERR_INVALID_SWITCH_HANDLE));

  { --- liste --- }
  R := WinQuerySwitchList(0, LongInt(@Blk), 4 + 2 * 100);
  Check('WinQuerySwitchList tampon de 2 entrees (3 au total)', (R = 3) And (RdL(LongInt(@Blk)) = 2));
  R := WinQuerySwitchList(0, LongInt(@Blk), 4096);
  Check('WinQuerySwitchList complete', (R = 3) And (RdL(LongInt(@Blk)) = 3) And (RdL(LongInt(@Blk) + 104) = H1) And
        (GetZ(LongInt(@Blk) + 104 + 32) = 'Modifie') And (RdL(LongInt(@Blk) + 204) = H2));
  R := WinRemoveSwitchEntry(H2);
  R2 := WinRemoveSwitchEntry(H2);
  A := WinQuerySwitchEntry(H2, LongInt(@Ctl2));
  Check('WinRemoveSwitchEntry ; handle perime refuse', (R = 0) And (R2 = PMERR_INVALID_SWITCH_HANDLE) And
        (A = PMERR_INVALID_SWITCH_HANDLE) And (Count = N0 + 1));
  SetCtl(LongInt(@Ctl), 0, 0, 4, 2, 'Reutilise');
  H3 := WinAddSwitchEntry(LongInt(@Ctl));
  Check('entree reutilisee : nouveau handle', (H3 <> 0) And (H3 <> H2) And ((H3 And $FF) = (H2 And $FF)));
  R := WinRemoveSwitchEntry(H3);

  { --- titres, taille et position --- }
  R := WinSetTitle(Z('PRINCIPAL'));
  Check('WinSetTitle, WinQueryTaskTitle(0)', (R = 1) And (SesTitle(0) = 'PRINCIPAL'));
  R := WinQuerySessionTitle(0, 1, LongInt(@TBuf), 6);
  Check('WinQuerySessionTitle tronque (6 octets)', (R = 0) And (GetZ(LongInt(@TBuf)) = 'PRINC'));
  R := WinQueryTaskTitle(77, LongInt(@TBuf), 64);
  R2 := WinQueryTaskTitle(1, 0, 64);
  Check('WinQueryTaskTitle : session inconnue, tampon nul refuses', (R = PMERR_INVALID_SESSION_ID) And
        (R2 = PMERR_PARAMETER_OUT_OF_RANGE));
  R := WinQueryTaskSizePos(0, 1, LongInt(@Swp));
  Check('WinQueryTaskSizePos : 640 x 400, SWP_SIZE|MOVE|SHOW', (R = 0) And (RdL(LongInt(@Swp)) = $0B) And
        (RdL(LongInt(@Swp) + 4) = 400) And (RdL(LongInt(@Swp) + 8) = 640));
  R := WinQueryTaskSizePos(0, 77, LongInt(@Swp));
  Check('WinQueryTaskSizePos session inconnue refuse', R = PMERR_INVALID_SESSION_ID);
  A := WinInitSession(0, Z(''));
  B := WinInitSession(1, Z('PRINCIPAL'));
  Check('WinInitSession : entree de la session 1', (A <> 0) And (A = B) And (A = SesHandle(1)));
  R := WinEndSession(77);
  Check('WinEndSession session inconnue refuse', R = PMERR_INVALID_SESSION_ID);

  { --- focus etendu, inscriptions, procedures de fenetre --- }
  A := 0;
  R := WinQueryExtIdFocus(LongInt(@A));
  R2 := WinSetExtIdFocus(77);
  Check('WinQueryExtIdFocus (1) ; WinSetExtIdFocus session inconnue refuse', (R = 0) And (A = 1) And
        (R2 = PMERR_INVALID_SESSION_ID));
  R := WinSetExtIdFocus(1);
  Check('WinSetExtIdFocus(1)', R = 0);
  Check('WinStpRegister, WinSwitchProgramRegister (fenetre nulle refusee)', (WinStpRegister($100) = 1) And
        (WinStpRegister(0) = 0) And (WinSwitchProgramRegister($200) = 1) And (WinSwitchProgramRegister($200) = 1));
  Check('WinCplRegister, WinPMFileRegister (nom vide refuse)', (WinCplRegister(Z('MAIN.CPL')) = 1) And
        (WinCplRegister(Z('')) = 0) And (WinPMFileRegister(Z('PROGMAN.INI')) = 1));
  Check('FNBADAPPDLGPROC : WM_COMMAND rend le bouton', (BadAppDlgProc(0, WM_COMMAND, 2, 0) = 2) And
        (BadAppDlgProc(0, 1, 2, 0) = 0));
  Check('LPFNICONWNDPROC : double clic sur l''icone, icone inconnue', (IconWndProc($5678, WM_BUTTON1DBLCLK, 0, 0) = 1) And
        (IconWndProc($9999, WM_BUTTON1DBLCLK, 0, 0) = 0));
  Check('LPFNSHELLWNDPROC, WinSwitchToTaskManager (deja la liste)', (ShellWndProc(0, WM_COMMAND, 1, 0) = 0) And
        (WinSwitchToTaskManager = 0));
  Check('WinSetFgndWindow : fenetre de la liste, fenetre inconnue', (WinSetFgndWindow($1234) = 1) And
        (WinSetFgndWindow($9999) = 0));

  { --- programmes --- }
  R := WinExecProgram(Z('C:\TESTSM.EXE'), Z2('KID PRINCIPAL'), LongInt(@A));
  Check('WinExecProgram dans la session courante (code ' + IStr(A) + ')', (R = 0) And (A = 42));
  N0 := Count;
  Sid2 := 0;
  R := SheStartLongProgram(Z('C:\TESTSM.EXE'), Z2('KID FOND'), Z3('FOND'), 1, LongInt(@Sid2));
  H2 := SesHandle(Sid2);
  Check('SheStartLongProgram en arriere-plan : en attente, entree FOND', (R = 0) And (Sid2 >= 2) And
        (StatW(Sid2, 4) = 3) And (H2 <> 0) And (SesTitle(Sid2) = 'FOND') And (Count = N0 + 1));
  R := WinSwitchToProgram2(H2, 5);
  Check('WinSwitchToProgram2 option invalide refusee', R = PMERR_PARAMETER_OUT_OF_RANGE);
  R := WinSwitchToProgram(H2);
  Check('WinSwitchToProgram : la session s''execute (code 42), entree retiree', (R = 0) And (StatW(Sid2, 14) = 42) And
        (SesHandle(Sid2) = 0) And (Count = N0));
  R := WinSwitchToProgram(H2);
  Check('WinSwitchToProgram entree retiree refuse', R = PMERR_INVALID_SWITCH_HANDLE);
  SetSd('SHE', 1);
  R := SheStartProgram(LongInt(@Sd), LongInt(@Sid3));
  H3 := SesHandle(Sid3);
  Check('SheStartProgram (STARTDATA) en arriere-plan, entree SHE', (R = 0) And (H3 <> 0) And (SesTitle(Sid3) = 'SHE'));
  R := WinSwitchToProgram2(H3, 1);
  Check('WinSwitchToProgram2 : la session s''execute (code 42)', (R = 0) And (StatW(Sid3, 14) = 42) And (SesHandle(Sid3) = 0));
  SetSd('ARRET', 1);
  R := SheStartProgram(LongInt(@Sd), LongInt(@Sid3));
  R2 := WinEndProgram(SesHandle(Sid3));
  Check('WinEndProgram : session en attente arretee, entree retiree', (R = 0) And (R2 = 0) And
        (StatW(Sid3, 4) = -1) And (SesHandle(Sid3) = 0));
  R := SheStartLongProgram(Z('C:\TESTSM.EXE'), Z2('KID A'), Z3('A'), 1, LongInt(@Sid3));
  R2 := SheStartLongProgram(Z('C:\TESTSM.EXE'), Z2('KID B'), Z3('B'), 1, LongInt(@Sid4));
  A := WinStopProgram(SesHandle(Sid3));
  B := WinEndWindowSession(SesHandle(Sid4));
  Check('WinStopProgram, WinEndWindowSession', (R = 0) And (R2 = 0) And (A = 0) And (B = 0) And
        (SesHandle(Sid3) = 0) And (SesHandle(Sid4) = 0) And (Count = N0));
  R := WinEndProgram(SesHandle(1));
  R2 := WinStopProgram($7777);
  Check('WinEndProgram de la session courante, WinStopProgram handle invalide refuses',
        (R = PMERR_INVALID_SESSION_ID) And (R2 = PMERR_INVALID_SWITCH_HANDLE));

  { --- WinInstStartApp, WinTerminateApp --- }
  For I := 0 To 79 Do Det[I] := 0;
  WrL(LongInt(@Det), 72);
  WrL(LongInt(@Det) + 4, 3);                        { PROG_PM }
  PutZ(LongInt(@Title), 'APPLI');
  PutZ(LongInt(@Prog), 'C:\TESTSM.EXE');
  PutZ(LongInt(@Inputs), 'KID APPLI');
  WrL(LongInt(@Det) + 12, LongInt(@Title));
  WrL(LongInt(@Det) + 16, LongInt(@Prog));
  WrL(LongInt(@Det) + 20, LongInt(@Inputs));
  Happ := WinInstStartApp(0, LongInt(@Det), 0, 0, 1 + 16);
  Check('WinInstStartApp programme PM refuse (pas de Presentation Manager)', Happ = 0);
  WrL(LongInt(@Det) + 4, 0);
  Happ := WinInstStartApp(0, LongInt(@Det), 0, 0, 1 + 16);
  Sid3 := Happ - $1000;
  Check('WinInstStartApp en arriere-plan (SAF_INSTALLEDCMDLINE) : entree APPLI', (Happ > $1000) And
        (SesTitle(Sid3) = 'APPLI') And (StatW(Sid3, 4) = 3));
  R := WinTerminateApp(Happ);
  R2 := WinTerminateApp(Happ);
  Check('WinTerminateApp, puis deuxieme appel refuse', (R = 1) And (R2 = 0) And (SesHandle(Sid3) = 0));
  Happ := WinInstStartApp(0, LongInt(@Det), Z('KID APPLI'), 0, 0);
  Sid3 := Happ - $1000;
  Check('WinInstStartApp au premier plan (parametres pszParams) : code 42', (Happ > $1000) And (StatW(Sid3, 14) = 42) And
        (SesHandle(Sid3) = 0));

  { --- OS2SM.INI --- }
  A := DosDelete(Z(IniFile));
  R := SheInitializeIniFile(Z(IniFile));
  Txt := ReadText(IniFile);
  Check('SheInitializeIniFile cree ' + IniFile, (R = 0) And (Pos('[Demarrage]', Txt) > 0));
  R := WriteText(IniFile, '[Demarrage]' + Chr(13) + Chr(10) + 'RUN=C:\TESTSM.EXE KID TESTSM.EXE' + Chr(13) + Chr(10) +
                 'RUN=C:\TESTSM.EXE KID TESTSM.EXE' + Chr(13) + Chr(10) + '[Polices]' + Chr(13) + Chr(10) +
                 'FONT=C:\CONFIG.SYS' + Chr(13) + Chr(10) + 'FONT=C:\NEXISTE.FON' + Chr(13) + Chr(10));
  R := SheInitializeIniFile(Z(IniFile));
  Txt := ReadText(IniFile);
  Check('SheInitializeIniFile fichier existant garde', (R = 0) And (Pos('RUN=', Txt) > 0));
  R := ShlLoadPublicFonts(Z(IniFile));
  A := ShlUnloadPublicFonts;
  B := ShlUnloadPublicFonts;
  Check('ShlLoadPublicFonts (1 police existante), ShlUnloadPublicFonts', (R = 1) And (A = 1) And (B = 0));
  N0 := Count;
  R := StartSystemExecutables(0);
  Check('StartSystemExecutables : 2 programmes en arriere-plan', (R = 2) And (Count = N0 + 2));
  Check('WinProcessHotKey touche ordinaire, Ctrl+Echap', (WinProcessHotKey($1E, 0) = 0) And
        (WinProcessHotKey($01, 4) = 1));
  R := WinProcessHotKey($01, 8);
  Check('WinProcessHotKey Alt+Echap : programme suivant execute', (R = 1) And (Count = N0 + 1));
  R := WinProcessHotKey($0F, 8);
  Check('WinProcessHotKey Alt+Tab : programme suivant execute', (R = 1) And (Count = N0));
  R := WinSave(0);
  Txt := ReadText(IniFile);
  Check('WinSave : section [Bureau]', (R = 0) And (Pos('[Bureau]|ENTRY=PRINCIPAL|ENTRY=Modifie|', Txt) > 0) And
        (Pos('RUN=', Txt) > 0));

  { --- arret --- }
  A := WinNoShutdown(1);
  R := SheSystemShutdown(0);
  B := WinNoShutdown(0);
  Check('WinNoShutdown : SheSystemShutdown empeche', (A = 0) And (R = 0) And (B = 1));
  R := SheSystemShutdown(0);
  Check('SheSystemShutdown (bureau sauve, tampons vides)', R = 1);
  R := WinRemoveSwitchEntry(H1);
  A := DosDelete(Z(IniFile));

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTSM : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
