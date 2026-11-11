{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de SESMGR.DLL sous OS/2-0.
}

Program TESTSES;

{$R-,S-,I-}

{ Compilation : OS2PC TESTSES.PAS   (produit TESTSES.EXE)

  TESTSES        verifie les 41 points d'entree de SESMGR.DLL ; les
                 sessions enfants executent TESTSES FIN42 (code de fin
                 42). A la fin, deux touches sont attendues : une pour la
                 session SSF_CONTROL_NOAUTOCLOSE, une pour DosSMPause.
  TESTSES FIN42  programme d'une session enfant : rend le code 42.
  TESTSES APP    application : ses demandes (DosStartSession...) passent
                 par l'interpreteur proprietaire (DosSMGetAppReq) ; rend
                 l'identificateur de la session demandee (+1000 si
                 DosSMInitialize est bien refuse). }

Function DosSMSGDoPopup(Wait : LongInt) : LongInt; External 'SESMGR';
Function DosSMSwitch(S : LongInt) : LongInt; External 'SESMGR';
Function DosSMServeAppReq(B : LongInt) : LongInt; External 'SESMGR';
Function DosGetTimes(PMs : LongInt) : LongInt; External 'SESMGR';
Function DosSMSetTitle(PTitle : LongInt) : LongInt; External 'SESMGR';
Function DosScrUnlock(Reserved : LongInt) : LongInt; External 'SESMGR';
Function DosSMDoAppReq(B : LongInt) : LongInt; External 'SESMGR';
Function DOSSTOPSESSION(Scope, S, Reserved : LongInt) : LongInt; External 'SESMGR';
Function DOSSELECTSESSION(S, Reserved : LongInt) : LongInt; External 'SESMGR';
Function DosScrLock(Wait, PNot : LongInt) : LongInt; External 'SESMGR';
Function DosSavRedrawWait(Ind, PNotify : LongInt) : LongInt; External 'SESMGR';
Function DosSavRedrawUndo(Owner, Kill : LongInt) : LongInt; External 'SESMGR';
Function DosSMSGEndPopup : LongInt; External 'SESMGR';
Function DOSSETSESSION(S, PStat : LongInt) : LongInt; External 'SESMGR';
Function DosSetMNLockTime(Ms : LongInt) : LongInt; External 'SESMGR';
Function DosModeUndo(Owner, Kill : LongInt) : LongInt; External 'SESMGR';
Function DOSSTARTSESSION(P, PSid, PPid : LongInt) : LongInt; External 'SESMGR';
Function DosSMGetStatus(PBuf, Cb, PcbOut : LongInt) : LongInt; External 'SESMGR';
Function DosModeWait(Req, PNotify : LongInt) : LongInt; External 'SESMGR';
Function DosSMTerminate(S : LongInt) : LongInt; External 'SESMGR';
Function DosSMGetAppReq(B, Wait : LongInt) : LongInt; External 'SESMGR';
Function DosSMRealPrtSc : LongInt; External 'SESMGR';
Function DosSMInitialize : LongInt; External 'SESMGR';
Function DosSMStart(P, PSid, PPid : LongInt) : LongInt; External 'SESMGR';
Function DosSMParentSwitch : LongInt; External 'SESMGR';
Function DosSMPause : LongInt; External 'SESMGR';
Function DosSMHDEInit : LongInt; External 'SESMGR';
Function DosSMPMPresent(PFlag : LongInt) : LongInt; External 'SESMGR';
Function DOSSMREGISTERDD(PName : LongInt) : LongInt; External 'SESMGR';
Function DosSMSysInit : LongInt; External 'SESMGR';
Function DosSMNotifyDD(Ev, Ses, PCount : LongInt) : LongInt; External 'SESMGR';
Function DosSMNotifyDD2(Ev, Ses, PCount : LongInt) : LongInt; External 'SESMGR';
Function DosSMOpenDD(PCount : LongInt) : LongInt; External 'SESMGR';
Function DosSMSetSessionType(S, Typ : LongInt) : LongInt; External 'SESMGR';
Function Dos32StartSession(P, PSid, PPid : LongInt) : LongInt; External 'SESMGR';
Function Dos32SelectSession(S : LongInt) : LongInt; External 'SESMGR';
Function Dos32SetSession(S, PStat : LongInt) : LongInt; External 'SESMGR';
Function Dos32StopSession(Scope, S : LongInt) : LongInt; External 'SESMGR';
Function DosRegisterNotification(PMod, PEntry, Mask : LongInt) : LongInt; External 'SESMGR';

Function ReplCalls : LongInt; External 'TESTVIOR';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosExit(Action, Code : LongInt) : LongInt; External 'DOSCALLS';

Const
  ERROR_FILE_NOT_FOUND = 2;
  ERROR_ACCESS_DENIED = 5;
  ERROR_INVALID_PARAMETER = 87;
  ERROR_INTERRUPT = 95;
  ERROR_MOD_NOT_FOUND = 126;
  ERROR_PROC_NOT_FOUND = 127;
  ERROR_BUSY = 170;
  ERROR_QUE_EMPTY = 342;
  ERROR_SMG_INVALID_SESSION_ID = 369;
  ERROR_SMG_INVALID_CALL = 418;
  ERROR_SMG_INVALID_PROGRAM_TYPE = 449;
  ERROR_SMG_INVALID_PGM_CONTROL = 450;
  ERROR_SMG_INVALID_START_MODE = 452;
  ERROR_SMG_INVALID_RELATED_OPT = 453;
  ERROR_SMG_INVALID_TRACE_OPTION = 454;
  ERROR_SMG_INVALID_SELECT_OPT = 455;
  ERROR_SMG_INVALID_BOND_OPTION = 456;
  ERROR_SMG_INVALID_STOP_OPTION = 458;
  ERROR_SMG_INVALID_DATA_LENGTH = 461;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, Sid, Pid, Sid2, Sid3, Sid4, Sid5, Sid6, C0 : LongInt;
  Name, Name2 : Array[0..127] Of Byte;
  Prog, Inputs, Title, ObjBuf : Array[0..127] Of Byte;
  Sd : Array[0..63] Of Byte;          { STARTDATA }
  Stat : Array[0..7] Of Byte;         { STATUSDATA }
  Req : Array[0..31] Of Byte;         { APPREQ }
  Buf : Array[0..511] Of Byte;
  ArgB : Array[0..63] Of Byte;
  Res : Array[0..3] Of LongInt;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

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

{ STARTDATA : Len, Related, FgBg, programme TESTSES.EXE FIN42 }
Procedure SetSd(Len, Rel, FgBg : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 63 Do Sd[K] := 0;
  WrW(LongInt(@Sd), Len);
  WrW(LongInt(@Sd) + 2, Rel);
  WrW(LongInt(@Sd) + 4, FgBg);
  PutZ(LongInt(@Title), 'Session enfant');
  PutZ(LongInt(@Prog), 'C:\TESTSES.EXE');
  PutZ(LongInt(@Inputs), 'FIN42');
  WrL(LongInt(@Sd) + 8, LongInt(@Title));
  WrL(LongInt(@Sd) + 12, LongInt(@Prog));
  WrL(LongInt(@Sd) + 16, LongInt(@Inputs));
End;

{ Entree de DosSMGetStatus de la session S (champ Ofs : mot) }
Function StatW(S, Ofs : LongInt) : LongInt;
Var K, Cb, V : LongInt;
Begin
  V := -1;
  Cb := 0;
  R2 := DosSMGetStatus(LongInt(@Buf), 512, LongInt(@Cb));
  K := 0;
  While K < Cb Do
  Begin
    If RdW(LongInt(@Buf) + K) = S Then
    Begin
      If Ofs = 8 Then V := RdL(LongInt(@Buf) + K + 8) Else V := RdW(LongInt(@Buf) + K + Ofs);
    End;
    K := K + 16;
  End;
  StatW := V;
End;

Function Cell(Row, Col : LongInt) : LongInt;
Begin
  Cell := RdW($B8000 + (Row * 80 + Col) * 2);
End;

{ --- modes secondaires --- }
Procedure ChildMode;
Begin
  WriteLn('Session enfant de TESTSES : fin avec le code 42.');
  A := DosExit(1, 42);
End;

Procedure AppMode;
Var Code : LongInt;
Begin
  Code := 0;
  If DosSMInitialize = ERROR_SMG_INVALID_CALL Then Code := 1000;
  SetSd(32, 1, 0);
  Sid := 0;
  R := Dos32StartSession(LongInt(@Sd), LongInt(@Sid), LongInt(@Pid));
  If R <> 0 Then Sid := 0;
  A := DosExit(1, Code + Sid);
End;

BEGIN
  If (ParamCount > 0) And (ParamStr(1) = 'FIN42') Then ChildMode;
  If (ParamCount > 0) And (ParamStr(1) = 'APP') Then AppMode;
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTSES : essai de SESMGR.DLL');

  { --- module, ordinaux et donnees --- }
  R := DosQueryModuleHandle(Z('SESMGR'), LongInt(@H));
  Check('DosQueryModuleHandle SESMGR', R = 0);
  Check('ordinaux 1 a 14', OrdIs(1, 'DosSMSGDoPopup') And OrdIs(2, 'DosSMSwitch') And OrdIs(3, 'DosSMServeAppReq') And
        OrdIs(4, 'DosGetTimes') And OrdIs(5, 'DosSMSetTitle') And OrdIs(6, 'DosScrUnlock') And
        OrdIs(7, 'DosSMDoAppReq') And OrdIs(8, 'DOSSTOPSESSION') And OrdIs(9, 'DOSSELECTSESSION') And
        OrdIs(10, 'DosScrLock') And OrdIs(11, 'DosSavRedrawWait') And OrdIs(12, 'DosSavRedrawUndo') And
        OrdIs(13, 'DosSMSGEndPopup') And OrdIs(14, 'DOSSETSESSION'));
  Check('ordinaux 15 a 28', OrdIs(15, 'DosSetMNLockTime') And OrdIs(16, 'DosModeUndo') And
        OrdIs(17, 'DOSSTARTSESSION') And OrdIs(18, 'DosSMGetStatus') And OrdIs(19, 'DosModeWait') And
        OrdIs(20, 'DosSMTerminate') And OrdIs(21, 'DosSMGetAppReq') And OrdIs(22, 'DosSMRealPrtSc') And
        OrdIs(23, 'DosSMInitialize') And OrdIs(24, 'DosSMStart') And OrdIs(25, 'DosSMParentSwitch') And
        OrdIs(26, 'DosSMPause') And OrdIs(27, 'DosSMHDEInit') And OrdIs(28, 'DosSMPMPresent'));
  Check('ordinaux 29 a 41', OrdIs(29, 'DOSSMREGISTERDD') And OrdIs(30, 'DosSMSysInit') And
        OrdIs(31, 'DosSMNotifyDD') And OrdIs(32, 'DosSMNotifyDD2') And OrdIs(33, 'DosSMOpenDD') And
        OrdIs(34, 'QhKeybdHandle') And OrdIs(35, 'QhMouseHandle') And OrdIs(36, 'DosSMSetSessionType') And
        OrdIs(37, 'Dos32StartSession') And OrdIs(38, 'Dos32SelectSession') And OrdIs(39, 'Dos32SetSession') And
        OrdIs(40, 'Dos32StopSession') And OrdIs(41, 'DosRegisterNotification'));
  A := 0; B := 0;
  DosQueryProcAddr(H, 34, 0, LongInt(@A));
  DosQueryProcAddr(H, 35, 0, LongInt(@B));
  Check('donnees QhKeybdHandle et QhMouseHandle (0, 0)', (A <> 0) And (B <> 0) And (RdL(A) = 0) And (RdL(B) = 0));
  Check('ordinal 42 inexistant', DosQueryProcAddr(H, 42, 0, LongInt(@A)) <> 0);

  { --- avant DosSMInitialize --- }
  A := 1;
  R := DosSMPMPresent(LongInt(@A));
  Check('DosSMPMPresent : pas de Presentation Manager', (R = 0) And (A = 0));
  R := DosSMGetStatus(LongInt(@Buf), 512, LongInt(@N));
  R2 := DosSetMNLockTime(10);
  Check('DosSMGetStatus et DosSetMNLockTime sans interpreteur proprietaire refuses', (R = ERROR_SMG_INVALID_CALL) And
        (R2 = ERROR_SMG_INVALID_CALL));
  R := DosRegisterNotification(Z('NEXISTE'), Z2('VioReplace'), $3C);
  R2 := DosRegisterNotification(Z('TESTVIOR'), Z2('Inexistante'), $3C);
  Check('DosRegisterNotification module ou point d''entree inconnu refuse', (R = ERROR_MOD_NOT_FOUND) And
        (R2 = ERROR_PROC_NOT_FOUND));
  R := DosRegisterNotification(Z('TESTVIOR'), Z2('VioReplace'), $3C);
  Check('DosRegisterNotification TESTVIOR VioReplace (evenements 2 a 5)', R = 0);

  { --- session au premier plan --- }
  WrW($B8000 + (24 * 80 + 70) * 2, $1E58);         { cellule temoin }
  C0 := ReplCalls;
  SetSd(32, 1, 0);
  Sid := 0; Pid := 0;
  R := Dos32StartSession(LongInt(@Sd), LongInt(@Sid), LongInt(@Pid));
  Check('Dos32StartSession au premier plan (session ' + IStr(Sid) + ', processus ' + IStr(Pid) + ')',
        (R = 0) And (Sid >= 2) And (Pid <> 0));
  Check('ecran de la session d''origine rendu', Cell(24, 70) = $1E58);
  A := ReplCalls - C0;
  Check('notifications : demarrage, premier plan, fin, retour (' + IStr(A) + ')', A = 4);

  { --- interpreteur proprietaire --- }
  R := DosSMInitialize;
  R2 := DosSMInitialize;
  Check('DosSMInitialize, puis deuxieme appel refuse', (R = 0) And (R2 = ERROR_SMG_INVALID_CALL));
  Check('DosSMGetStatus : session 1 au premier plan', StatW(1, 4) = 1);
  Check('DosSMGetStatus : session enfant terminee, code 42, enfant', (StatW(Sid, 4) = 4) And (StatW(Sid, 14) = 42) And
        ((StatW(Sid, 6) And 4) <> 0) And (StatW(Sid, 2) = 1) And (StatW(Sid, 8) = Pid));
  R := DosSetMNLockTime(1500);
  A := 0;
  R2 := DosGetTimes(LongInt(@A));
  Check('DosSetMNLockTime 1500, DosGetTimes', (R = 0) And (R2 = 0) And (A = 1500));
  R := DosSetMNLockTime(-1);
  Check('DosSetMNLockTime negatif refuse', R = ERROR_INVALID_PARAMETER);
  R := DosSetMNLockTime(0);

  { --- session en arriere-plan, DosSetSession, DosSelectSession --- }
  SetSd(50, 1, 1);
  R := Dos32StartSession(LongInt(@Sd), LongInt(@Sid2), LongInt(@Pid));
  Check('Dos32StartSession en arriere-plan : en attente', (R = 0) And (StatW(Sid2, 4) = 3));
  WrW(LongInt(@Stat), 6); WrW(LongInt(@Stat) + 2, 2); WrW(LongInt(@Stat) + 4, 1);
  R := Dos32SetSession(Sid2, LongInt(@Stat));
  Check('Dos32SetSession non selectionnable, liee', (R = 0) And ((StatW(Sid2, 6) And 3) = 2));
  R := DosSMSwitch(Sid2);
  Check('DosSMSwitch d''une session non selectionnable refuse', R = ERROR_ACCESS_DENIED);
  WrW(LongInt(@Stat), 4);
  R := Dos32SetSession(Sid2, LongInt(@Stat));
  WrW(LongInt(@Stat), 6); WrW(LongInt(@Stat) + 2, 3);
  R2 := Dos32SetSession(Sid2, LongInt(@Stat));
  WrW(LongInt(@Stat) + 2, 0); WrW(LongInt(@Stat) + 4, 3);
  A := DOSSETSESSION(Sid2, LongInt(@Stat));
  Check('DosSetSession : longueur, SelectInd et BondInd invalides refuses', (R = ERROR_SMG_INVALID_DATA_LENGTH) And
        (R2 = ERROR_SMG_INVALID_SELECT_OPT) And (A = ERROR_SMG_INVALID_BOND_OPTION));
  WrW(LongInt(@Stat) + 2, 1); WrW(LongInt(@Stat) + 4, 2);
  R := DOSSETSESSION(Sid2, LongInt(@Stat));
  Check('DOSSETSESSION selectionnable, non liee', (R = 0) And ((StatW(Sid2, 6) And 3) = 1));
  R := DOSSELECTSESSION(Sid2, 0);
  Check('DOSSELECTSESSION : la session en attente s''execute (code 42)', (R = 0) And (StatW(Sid2, 4) = 4) And
        (StatW(Sid2, 14) = 42));
  R := Dos32SelectSession(Sid2);
  R2 := Dos32SelectSession(99);
  Check('Dos32SelectSession d''une session terminee ou inconnue refuse', (R = ERROR_SMG_INVALID_SESSION_ID) And
        (R2 = ERROR_SMG_INVALID_SESSION_ID));
  R := Dos32SelectSession(0);
  Check('Dos32SelectSession(0) : la session elle-meme', R = 0);

  { --- DosStopSession --- }
  SetSd(32, 1, 1);
  R := DOSSTARTSESSION(LongInt(@Sd), LongInt(@Sid3), LongInt(@Pid));
  R2 := Dos32StopSession(5, Sid3);
  Check('DOSSTARTSESSION en arriere-plan ; DosStopSession portee invalide refusee', (R = 0) And
        (R2 = ERROR_SMG_INVALID_STOP_OPTION));
  R := DOSSTOPSESSION(0, Sid3, 0);
  Check('DOSSTOPSESSION : session arretee sans avoir ete executee', (R = 0) And (StatW(Sid3, 4) = 4));
  R := Dos32StopSession(0, Sid3);
  Check('Dos32StopSession d''une session terminee refuse', R = ERROR_SMG_INVALID_SESSION_ID);

  { --- STARTDATA invalides --- }
  SetSd(10, 1, 0);
  R := Dos32StartSession(LongInt(@Sd), LongInt(@A), LongInt(@Pid));
  SetSd(60, 1, 0);
  R2 := DOSSTARTSESSION(LongInt(@Sd), LongInt(@A), LongInt(@Pid));
  Check('longueur de STARTDATA invalide (10 ; 60 en OS/2 1.x)', (R = ERROR_SMG_INVALID_DATA_LENGTH) And
        (R2 = ERROR_SMG_INVALID_DATA_LENGTH));
  SetSd(32, 2, 0);
  R := Dos32StartSession(LongInt(@Sd), LongInt(@A), LongInt(@Pid));
  SetSd(32, 1, 3);
  R2 := Dos32StartSession(LongInt(@Sd), LongInt(@A), LongInt(@Pid));
  Check('Related et FgBg invalides refuses', (R = ERROR_SMG_INVALID_RELATED_OPT) And (R2 = ERROR_SMG_INVALID_START_MODE));
  SetSd(32, 1, 0);
  WrW(LongInt(@Sd) + 6, 1);
  R := Dos32StartSession(LongInt(@Sd), LongInt(@A), LongInt(@Pid));
  SetSd(32, 1, 0);
  WrW(LongInt(@Sd) + 30, 3);
  R2 := Dos32StartSession(LongInt(@Sd), LongInt(@A), LongInt(@Pid));
  Check('TraceOpt et session PM refuses', (R = ERROR_SMG_INVALID_TRACE_OPTION) And (R2 = ERROR_SMG_INVALID_PROGRAM_TYPE));
  SetSd(50, 1, 0);
  WrW(LongInt(@Sd) + 40, $0100);
  R := Dos32StartSession(LongInt(@Sd), LongInt(@A), LongInt(@Pid));
  Check('PgmControl invalide refuse', R = ERROR_SMG_INVALID_PGM_CONTROL);
  SetSd(60, 1, 0);
  PutZ(LongInt(@Prog), 'C:\NEXISTE.EXE');
  WrL(LongInt(@Sd) + 52, LongInt(@ObjBuf));
  WrL(LongInt(@Sd) + 56, 128);
  ObjBuf[0] := 0;
  R := Dos32StartSession(LongInt(@Sd), LongInt(@A), LongInt(@Pid));
  Check('programme inexistant : ERROR_FILE_NOT_FOUND, ObjectBuffer', (R = ERROR_FILE_NOT_FOUND) And (ObjBuf[0] = Ord('C')));

  { --- DosSMStart, DosSMSetSessionType, DosSMSwitch, DosSMTerminate --- }
  SetSd(32, 0, 1);
  R := DosSMStart(LongInt(@Sd), LongInt(@Sid4), LongInt(@Pid));
  Check('DosSMStart : session de premier niveau en attente', (R = 0) And (StatW(Sid4, 4) = 3) And (StatW(Sid4, 2) = 0));
  R := DosSMSetSessionType(Sid4, 2);
  B := DosSMSetSessionType(Sid4, 4);
  A := StatW(Sid4, 12);
  Check('DosSMSetSessionType fenetre VIO ; DOS refuse', (R = 0) And (A = 2) And
        (B = ERROR_SMG_INVALID_PROGRAM_TYPE));
  R := DosSMSwitch(Sid4);
  Check('DosSMSwitch : la session s''execute (code 42)', (R = 0) And (StatW(Sid4, 14) = 42));
  R := DosSMTerminate(Sid4);
  R2 := DosSMTerminate(Sid4);
  A := DosSMTerminate(1);
  Check('DosSMTerminate, puis session liberee ; session 1 refusee', (R = 0) And (R2 = ERROR_SMG_INVALID_SESSION_ID) And
        (A = ERROR_SMG_INVALID_SESSION_ID));

  { --- demandes d'une application --- }
  PutZ(LongInt(@ArgB), 'TESTSES');
  PutZ(LongInt(@ArgB) + 8, 'APP');
  ArgB[12] := 0;
  Res[0] := 0; Res[1] := 0;
  R := DosExecPgm(LongInt(@Buf), 64, 0, LongInt(@ArgB), 0, LongInt(@Res), Z('C:\TESTSES.EXE'));
  Sid5 := Res[1] Mod 1000;
  Check('application : DosSMInitialize refuse, Dos32StartSession en attente (session ' + IStr(Sid5) + ')',
        (R = 0) And (Res[1] >= 1000) And (Sid5 >= 2) And (StatW(Sid5, 4) = 3));
  For I := 0 To 31 Do Req[I] := 0;
  R := DosSMGetAppReq(LongInt(@Req), 1);
  Check('DosSMGetAppReq : demande de demarrage de la session ' + IStr(RdL(LongInt(@Req) + 16)), (R = 0) And
        (RdW(LongInt(@Req)) = 1) And (RdW(LongInt(@Req) + 2) = 1) And (RdL(LongInt(@Req) + 16) = Sid5) And
        (RdL(LongInt(@Req) + 12) <> 0));
  R := DosSMServeAppReq(LongInt(@Req));
  Check('DosSMServeAppReq : la session s''execute (code 42)', (R = 0) And (RdW(LongInt(@Req) + 2) = 2) And
        (RdL(LongInt(@Req) + 24) = 0) And (StatW(Sid5, 14) = 42));
  R := DosSMServeAppReq(LongInt(@Req));
  R2 := DosSMGetAppReq(LongInt(@Req), 1);
  Check('demande deja servie refusee ; file vide', (R = ERROR_SMG_INVALID_CALL) And (R2 = ERROR_QUE_EMPTY));

  { --- DosSMDoAppReq --- }
  SetSd(32, 1, 1);
  R := Dos32StartSession(LongInt(@Sd), LongInt(@Sid6), LongInt(@Pid));
  For I := 0 To 31 Do Req[I] := 0;
  WrW(LongInt(@Req), 4);
  WrL(LongInt(@Req) + 16, Sid6);
  WrL(LongInt(@Req) + 20, 2);
  R := DosSMDoAppReq(LongInt(@Req));
  Check('DosSMDoAppReq : reglage (non selectionnable)', (R = 0) And (RdW(LongInt(@Req) + 2) = 2) And
        ((StatW(Sid6, 6) And 1) = 0));
  WrW(LongInt(@Req), 2);
  WrL(LongInt(@Req) + 20, 0);
  R := DosSMDoAppReq(LongInt(@Req));
  Check('DosSMDoAppReq : arret', (R = 0) And (StatW(Sid6, 4) = 4));

  { --- divers --- }
  R := DosSMParentSwitch;
  Check('DosSMParentSwitch dans la session 1 (sans parent) refuse', R = ERROR_SMG_INVALID_CALL);
  C0 := ReplCalls;
  R := DosSMSetTitle(Z('Essai des sessions'));
  Check('DosSMSetTitle (notification du titre)', (R = 0) And (ReplCalls = C0 + 1));
  A := 9;
  R := DosScrLock(0, LongInt(@A));
  R2 := DosScrUnlock(0);
  Check('DosScrLock, DosScrUnlock', (R = 0) And (A = 0) And (R2 = 0));
  R := DosSavRedrawWait(0, LongInt(@A));
  R2 := DosSavRedrawUndo(1, 0);
  Check('DosSavRedrawWait (ERROR_INTERRUPT), DosSavRedrawUndo', (R = ERROR_INTERRUPT) And (R2 = 0));
  R := DosModeWait(0, LongInt(@A));
  R2 := DosModeUndo(1, 0);
  Check('DosModeWait (ERROR_INTERRUPT), DosModeUndo', (R = ERROR_INTERRUPT) And (R2 = 0));
  R := DosSMSGDoPopup(0);
  R2 := DosSMSGDoPopup(0);
  B := R2;
  A := StatW(1, 6);
  Check('DosSMSGDoPopup, puis deuxieme fenetre refusee', (R = 0) And (B = ERROR_BUSY) And ((A And 8) <> 0));
  R := DosSMSGEndPopup;
  R2 := DosSMSGEndPopup;
  Check('DosSMSGEndPopup, puis sans fenetre refuse', (R = 0) And (R2 = ERROR_SMG_INVALID_CALL));
  R := DOSSMREGISTERDD(Z('KBD$'));
  R2 := DOSSMREGISTERDD(Z('MOUSE$'));
  Check('DOSSMREGISTERDD KBD$ et MOUSE$', (R = 0) And (R2 = 0));
  A := -1; B := -1;
  R := DosSMNotifyDD(4, 1, LongInt(@A));
  R2 := DosSMNotifyDD2(4, 1, LongInt(@B));
  Check('DosSMNotifyDD avant DosSMOpenDD : 0 pilote ; DosSMNotifyDD2 : 2', (R = 0) And (A = 0) And (R2 = 0) And (B = 2));
  R := DosSMOpenDD(LongInt(@A));
  R2 := DosSMNotifyDD(4, 1, LongInt(@B));
  Check('DosSMOpenDD (2 pilotes), DosSMNotifyDD : 2', (R = 0) And (A = 2) And (R2 = 0) And (B = 2));
  R := DosSMHDEInit;
  R2 := DosSMSysInit;
  Check('DosSMHDEInit, DosSMSysInit', (R = 0) And (R2 = 0));
  R := DosSMRealPrtSc;
  Check('DosSMRealPrtSc', R = 0);

  { --- touches --- }
  WriteLn('Session SSF_CONTROL_NOAUTOCLOSE : une touche a la fin.');
  SetSd(50, 1, 0);
  WrW(LongInt(@Sd) + 40, 8);
  R := Dos32StartSession(LongInt(@Sd), LongInt(@Sid6), LongInt(@Pid));
  Check('SSF_CONTROL_NOAUTOCLOSE : touche attendue a la fin de la session', (R = 0) And (StatW(Sid6, 14) = 42));
  WriteLn('DosSMPause : tapez une touche.');
  R := DosSMPause;
  Check('DosSMPause (touche)', R = 0);
  R := DosRegisterNotification(Z('TESTVIOR'), Z2('VioReplace'), 0);
  Check('DosRegisterNotification : retrait', R = 0);

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTSES : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
