{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 SESMGR.DLL de OS/2-0 (gestionnaire de
                sessions).
}

Library SESMGR;

{$IMAGEBASE $00FA0000}
{$R-,S-,I-}

{ Compilation : OS2PC SESMGR.PAS   (produit SESMGR.DLL)

  SESMGR.DLL est le gestionnaire de sessions d'OS/2 : demarrage, choix,
  reglage et arret des sessions (DosStartSession, DosSelectSession,
  DosSetSession, DosStopSession), fonctions de l'interpreteur proprietaire
  du gestionnaire (DosSM*), verrou de l'ecran, fenetres surgissantes,
  sauvegarde et retracage, notification des pilotes et des DLL.

  Modele : un seul ecran ; la session 1 est la session initiale (celle de
  CMD.EXE). Les processus s'executant un a la fois, une session au
  premier plan execute son programme aussitot (DosExecPgm), sur un ecran
  propre ; a sa fin, l'ecran, le curseur et le clavier de la session
  d'origine sont rendus. Une session demarree en arriere-plan attend :
  son programme s'execute quand elle passe au premier plan
  (DosSelectSession, DosSMSwitch, demande servie par l'interpreteur).
  Une session terminee garde son code de fin (DosSMGetStatus) jusqu'a
  DosSMTerminate. A la fin d'une session, ses sessions enfants en attente
  sont arretees et, si elle a une file de fin (TermQ) et que QUECALLS.DLL
  est presente, l'element (code de requete 0 ; donnees en memoire
  partagee : identificateur de la session et code de fin, 2 mots) y est
  ecrit.

  Interpreteur proprietaire : le premier processus qui appelle
  DosSMInitialize. Tant qu'il existe, les DosStartSession,
  DosSelectSession, DosSetSession et DosStopSession des autres processus
  deviennent des demandes (la session demarree est creee en attente) que
  l'interpreteur recoit par DosSMGetAppReq et execute par
  DosSMServeAppReq ; sans interpreteur, SESMGR les execute lui-meme.

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires ; un pointeur vers une valeur simple (pidSession, ppid...)
  designe un LongInt, pour les points d'entree d'OS/2 1.x (DOSSTARTSESSION
  ...) comme pour ceux d'OS/2 2.x (Dos32StartSession...).
    STARTDATA   Length (2 : 24, 30, 32, 50 ; 60 en 2.x), Related, FgBg,
                TraceOpt (mots), PgmTitle, PgmName, PgmInputs, TermQ,
                Environment (pointeurs), InheritOpt, SessionType (mots),
                IconFile, PgmHandle, PgmControl (mot), InitXPos, InitYPos,
                InitXSize, InitYSize, Reserved, ObjectBuffer,
                ObjectBuffLen
    STATUSDATA  Length (6), SelectInd, BondInd (mots)
    APPREQ      (demandes, 28 octets) : type (mot : 1 demarrer, 2 arreter,
                3 choisir, 4 regler), etat (mot : 1 en attente, 2 servie),
                numero (double mot), session demandeuse, processus
                demandeur, session visee, parametre (arret : portee ;
                reglage : SelectInd + BondInd shl 16), resultat
    SMSTATUS    (DosSMGetStatus, 16 octets par session) : identificateur,
                parent, etat (1 premier plan, 2 suspendue, 3 en attente,
                4 terminee), indicateurs (1 selectionnable, 2 liee,
                4 enfant, 8 fenetre surgissante), processus, type, code
                de fin
  Notifications (DosRegisterNotification) : Entree(evenement, session,
  processus) ; 2 demarrage, 3 fin, 4 premier plan, 5 titre.

  Fonctions exportees (ordinaux d'origine de SESMGR.DLL) :
     1 DosSMSGDoPopup       15 DosSetMNLockTime    29 DOSSMREGISTERDD
     2 DosSMSwitch          16 DosModeUndo         30 DosSMSysInit
     3 DosSMServeAppReq     17 DOSSTARTSESSION     31 DosSMNotifyDD
     4 DosGetTimes          18 DosSMGetStatus      32 DosSMNotifyDD2
     5 DosSMSetTitle        19 DosModeWait         33 DosSMOpenDD
     6 DosScrUnlock         20 DosSMTerminate      34 QhKeybdHandle
     7 DosSMDoAppReq        21 DosSMGetAppReq      35 QhMouseHandle
     8 DOSSTOPSESSION       22 DosSMRealPrtSc      36 DosSMSetSessionType
     9 DOSSELECTSESSION     23 DosSMInitialize     37 Dos32StartSession
    10 DosScrLock           24 DosSMStart          38 Dos32SelectSession
    11 DosSavRedrawWait     25 DosSMParentSwitch   39 Dos32SetSession
    12 DosSavRedrawUndo     26 DosSMPause          40 Dos32StopSession
    13 DosSMSGEndPopup      27 DosSMHDEInit        41 DosRegisterNotification
    14 DOSSETSESSION        28 DosSMPMPresent
  QhKeybdHandle et QhMouseHandle sont des donnees (double mot) : handle du
  clavier logique du gestionnaire (0, clavier par defaut de KBDCALLS) et
  de la souris (0 : ouverte a la demande par MOUCALLS).

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services des autres DLL
    Partie 3 - Utilitaires
    Partie 4 - Ecrans, notifications et pilotes
    Partie 5 - Sessions
    Partie 6 - Demandes des applications
    Partie 7 - Fonctions des sessions
    Partie 8 - Fonctions de l'interpreteur (DosSM*)
    Partie 9 - Ecran, fenetres surgissantes, sauvegarde
    Exportations }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  NO_ERROR                  = 0;
  ERROR_FILE_NOT_FOUND      = 2;
  ERROR_ACCESS_DENIED       = 5;
  ERROR_NOT_ENOUGH_MEMORY   = 8;
  ERROR_INVALID_PARAMETER   = 87;
  ERROR_INTERRUPT           = 95;
  ERROR_BUFFER_OVERFLOW     = 111;
  ERROR_MOD_NOT_FOUND       = 126;
  ERROR_PROC_NOT_FOUND      = 127;
  ERROR_BUSY                = 170;
  ERROR_QUE_EMPTY           = 342;
  { codes du gestionnaire de sessions (bseerr.h) }
  ERROR_SMG_INVALID_SESSION_ID   = 369;
  ERROR_SMG_INVALID_CALL         = 418;
  ERROR_SMG_INVALID_PROGRAM_TYPE = 449;
  ERROR_SMG_INVALID_PGM_CONTROL  = 450;
  ERROR_SMG_INVALID_INHERIT_OPT  = 451;
  ERROR_SMG_INVALID_START_MODE   = 452;
  ERROR_SMG_INVALID_RELATED_OPT  = 453;
  ERROR_SMG_INVALID_TRACE_OPTION = 454;
  ERROR_SMG_INVALID_SELECT_OPT   = 455;
  ERROR_SMG_INVALID_BOND_OPTION  = 456;
  ERROR_SMG_START_IN_BACKGROUND  = 457;
  ERROR_SMG_INVALID_STOP_OPTION  = 458;
  ERROR_SMG_PROCESS_NOT_PARENT   = 460;
  ERROR_SMG_INVALID_DATA_LENGTH  = 461;
  ERROR_SMG_SESSION_NOT_PARENT   = 463;

  { etats des sessions }
  SS_FREE    = 0;
  SS_FORE    = 1;            { premier plan (execute son programme) }
  SS_SUSP    = 2;            { suspendue (attend une session enfant) }
  SS_PENDING = 3;            { en attente (pas encore executee) }
  SS_ENDED   = 4;

  { notifications }
  SN_START = 2;
  SN_END   = 3;
  SN_FORE  = 4;
  SN_TITLE = 5;

  { demandes }
  RQ_START  = 1;
  RQ_STOP   = 2;
  RQ_SELECT = 3;
  RQ_SET    = 4;

  MaxS     = 16;             { sessions }
  MaxReq   = 16;             { demandes en attente }
  MaxNotif = 8;
  MaxDD    = 8;
  ScrBytes = 4000;
  ScrBase  = $000B8000;

  { donnees exportees }
  QhKeybdHandle = 0;
  QhMouseHandle = 0;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  { sessions (indice = identificateur) }
  SState    : Array[1..MaxS] Of LongInt;
  SParent   : Array[1..MaxS] Of LongInt;
  SRelated  : Array[1..MaxS] Of Boolean;
  SSelect   : Array[1..MaxS] Of Boolean;
  SBond     : Array[1..MaxS] Of Boolean;
  SPid      : Array[1..MaxS] Of LongInt;
  SType     : Array[1..MaxS] Of LongInt;
  SCtl      : Array[1..MaxS] Of LongInt;    { PgmControl }
  SResult   : Array[1..MaxS] Of LongInt;
  SParentSw : Array[1..MaxS] Of Boolean;
  SProg     : Array[1..MaxS] Of String[127];
  SArgs     : Array[1..MaxS] Of String[127];
  STitle    : Array[1..MaxS] Of String[63];
  STermQ    : Array[1..MaxS] Of String[63];
  SCurR, SCurC : Array[1..MaxS] Of LongInt;
  SScreen   : Array[0..MaxS * ScrBytes - 1] Of Byte;
  CurSes    : LongInt;                     { session du code qui s'execute }
  FgSince   : LongInt;                     { premier plan depuis (ms) }

  { interpreteur proprietaire }
  OwnerPid, OwnerSes : LongInt;
  MNLockTime : LongInt;
  HardErrPid : LongInt;
  SysInitDone : Boolean;

  { demandes des applications }
  QType, QReqId, QFromSes, QFromPid, QTarget, QParam : Array[0..MaxReq - 1] Of LongInt;
  QCount, NextReq : LongInt;
  Served    : Array[0..MaxReq - 1] Of LongInt;  { numeros remis, a servir }

  { notifications et pilotes }
  NEntry, NMask : Array[0..MaxNotif - 1] Of LongInt;
  DDName    : Array[0..MaxDD - 1] Of String[15];
  DDOpen    : Array[0..MaxDD - 1] Of Boolean;
  DDCount   : LongInt;

  { fenetre surgissante }
  PopSes    : LongInt;

  Ki        : Array[0..15] Of Byte;
  ArgBuf    : Array[0..511] Of Byte;
  NameZ     : Array[0..259] Of Byte;
  Info      : Array[0..63] Of Byte;
  Res       : Array[0..3] Of LongInt;
  FailBuf   : Array[0..63] Of Byte;
  QueMod    : LongInt;
  ExecErr   : LongInt;

{ ==================================================================== }
{ Partie 2 - Services des autres DLL                                   }
{ ==================================================================== }

Function DcExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS' Name 'DosExecPgm';
Function DcWaitChild(Action, Option, PRes, PPid, Pid : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWaitChild';
Function DcLoadModule(PObj, CbObj, PName, PHmod : LongInt) : LongInt; External 'DOSCALLS' Name 'DosLoadModule';
Function DcQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryProcAddr';
Function DcQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryPathInfo';
Function DcScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS' Name 'DosScanEnv';
Function DcAllocSharedMem(PPb, PName, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS' Name 'DosAllocSharedMem';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KGetTickCount : LongInt; External 'DOSCALLS' Name 'GetTickCount';

Function VioScrLock(FWait, PNot, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioScrLock';
Function VioScrUnlock(Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioScrUnlock';
Function VioSavRedrawWait(Ind, PNotify, Res : LongInt) : LongInt; External 'VIOCALLS' Name 'VioSavRedrawWait';
Function VioSavRedrawUndo(Owner, Kill, Res : LongInt) : LongInt; External 'VIOCALLS' Name 'VioSavRedrawUndo';
Function VioModeWait(Req, PNotify, Res : LongInt) : LongInt; External 'VIOCALLS' Name 'VioModeWait';
Function VioModeUndo(Owner, Kill, Res : LongInt) : LongInt; External 'VIOCALLS' Name 'VioModeUndo';
Function VioPrtSc(Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioPrtSc';
Function VioGetCurPos(PRow, PCol, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetCurPos';
Function VioSetCurPos(Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioSetCurPos';
Function VioWrtTty(P, N, Hvio : LongInt) : LongInt; External 'VIOCALLS' Name 'VioWrtTty';

Function KbdCharIn(PInfo, Wait, Hkbd : LongInt) : LongInt; External 'KBDCALLS' Name 'KbdCharIn';
Function KbdSwitchFgnd(Sess : LongInt) : LongInt; External 'KBDCALLS' Name 'KbdSwitchFgnd';

{ ==================================================================== }
{ Partie 3 - Utilitaires                                               }
{ ==================================================================== }

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V;
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
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FFFF;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FF;
End;

Function GetZ(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (RdB(A + N) <> 0) And (N < 255) Do
    Begin
      S := S + Chr(RdB(A + N));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

Function Alive(Pid : LongInt) : Boolean;
Begin
  Alive := KrnMonIo(0, 4, Pid) <> 0;
End;

{ Le processus appelant est-il l'interpreteur proprietaire ? }
Function IsOwner : Boolean;
Begin
  If (OwnerPid <> 0) And Not Alive(OwnerPid) Then OwnerPid := 0;
  IsOwner := (OwnerPid <> 0) And (OwnerPid = MyPid);
End;

{ Les demandes des applications passent-elles par l'interpreteur ? }
Function Deferred : Boolean;
Begin
  If (OwnerPid <> 0) And Not Alive(OwnerPid) Then OwnerPid := 0;
  Deferred := (OwnerPid <> 0) And (OwnerPid <> MyPid);
End;

Function ValidSes(Id : LongInt) : Boolean;
Begin
  ValidSes := (Id >= 1) And (Id <= MaxS);
  If (Id >= 1) And (Id <= MaxS) Then ValidSes := SState[Id] <> SS_FREE;
End;

Function CallPtr3(F, A1, A2, A3 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A3
    push eax
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,12
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPtr3 := R;
End;

Function CallPtr5(F, A1, A2, A3, A4, A5 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A5
    push eax
    mov eax,A4
    push eax
    mov eax,A3
    push eax
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,20
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPtr5 := R;
End;

{ ==================================================================== }
{ Partie 4 - Ecrans, notifications et pilotes                          }
{ ==================================================================== }

Procedure SaveScreen(S : LongInt);
Var K : LongInt; P : PByte;
Begin
  For K := 0 To ScrBytes - 1 Do
  Begin
    P := Pointer(ScrBase + K);
    SScreen[(S - 1) * ScrBytes + K] := P^;
  End;
  VioGetCurPos(LongInt(@SCurR[S]), LongInt(@SCurC[S]), 0);
End;

Procedure RestoreScreen(S : LongInt);
Var K : LongInt; P : PByte;
Begin
  For K := 0 To ScrBytes - 1 Do
  Begin
    P := Pointer(ScrBase + K);
    P^ := SScreen[(S - 1) * ScrBytes + K];
  End;
  VioSetCurPos(SCurR[S], SCurC[S], 0);
End;

Procedure ClearScreen;
Var K : LongInt;
Begin
  For K := 0 To ScrBytes Div 2 - 1 Do WrW(ScrBase + K * 2, $0720);
  VioSetCurPos(0, 0, 0);
End;

{ Avertir les DLL inscrites (DosRegisterNotification) }
Procedure Notify(Ev, Ses, Pid : LongInt);
Var I, D : LongInt;
Begin
  For I := 0 To MaxNotif - 1 Do
    If (NEntry[I] <> 0) And (((NMask[I] Shr Ev) And 1) <> 0) Then
      D := CallPtr3(NEntry[I], Ev, Ses, Pid);
End;

{ Avertir les pilotes inscrits (DosSMRegisterDD) d'un evenement d'ecran ;
  OnlyOpen : seulement ceux ouverts par DosSMOpenDD. Rend le nombre de
  pilotes avertis. }
Function NotifyDDs(Ev, Ses : LongInt; OnlyOpen : Boolean) : LongInt;
Var I, N, D : LongInt;
Begin
  N := 0;
  For I := 0 To DDCount - 1 Do
    If (Not OnlyOpen) Or DDOpen[I] Then
    Begin
      If (DDName[I] = 'KBD$') And (Ev = SN_FORE) Then D := KbdSwitchFgnd(Ses);
      Inc(N);
    End;
  NotifyDDs := N;
End;

{ La session S passe au premier plan }
Procedure GoFore(S : LongInt);
Var D : LongInt;
Begin
  CurSes := S;
  SState[S] := SS_FORE;
  FgSince := KGetTickCount;
  D := KbdSwitchFgnd(S);
  D := NotifyDDs(SN_FORE, S, False);
  Notify(SN_FORE, S, SPid[S]);
End;

{ ==================================================================== }
{ Partie 5 - Sessions                                                  }
{ ==================================================================== }

Function NewSes : LongInt;
Var I, F : LongInt;
Begin
  F := 0;
  For I := MaxS DownTo 2 Do
    If SState[I] = SS_FREE Then F := I;
  NewSes := F;
End;

{ Element de fin dans la file TermQ (QUECALLS.DLL) }
Procedure PostTermQ(S : LongInt);
Var H, F, Pid, Q, P, D : LongInt;
Begin
  If STermQ[S] = '' Then Exit;
  If QueMod = 0 Then
  Begin
    PutZ(LongInt(@NameZ), 'QUECALLS');
    If DcLoadModule(LongInt(@FailBuf), 64, LongInt(@NameZ), LongInt(@QueMod)) <> NO_ERROR Then QueMod := -1;
  End;
  If QueMod <= 0 Then Exit;
  F := 0;
  PutZ(LongInt(@NameZ), 'Dos32OpenQueue');
  If DcQueryProcAddr(QueMod, 0, LongInt(@NameZ), LongInt(@F)) <> NO_ERROR Then Exit;
  PutZ(LongInt(@NameZ), STermQ[S]);
  Q := 0; Pid := 0;
  If CallPtr3(F, LongInt(@Pid), LongInt(@Q), LongInt(@NameZ)) <> NO_ERROR Then Exit;
  P := 0;
  If DcAllocSharedMem(LongInt(@P), 0, 4, $213) <> NO_ERROR Then Exit;   { PAG_COMMIT, lecture, ecriture, OBJ_GIVEABLE }
  WrW(P, S);
  WrW(P + 2, SResult[S]);
  PutZ(LongInt(@NameZ), 'Dos32WriteQueue');
  If DcQueryProcAddr(QueMod, 0, LongInt(@NameZ), LongInt(@F)) = NO_ERROR Then
    D := CallPtr5(F, Q, 0, 4, P, 0);
End;

{ Fin de la session S : code, file de fin, sessions enfants en attente }
Procedure EndSession(S : LongInt);
Var I : LongInt;
Begin
  SState[S] := SS_ENDED;
  If PopSes = S Then PopSes := 0;
  For I := 1 To MaxS Do
    If (SState[I] = SS_PENDING) And (SParent[I] = S) And SRelated[I] Then
    Begin
      SResult[I] := 0;
      SState[I] := SS_ENDED;
      PostTermQ(I);
    End;
  PostTermQ(S);
  Notify(SN_END, S, SPid[S]);
End;

{ Executer la session S au premier plan, puis rendre le premier plan a
  la session d'origine. Rend le code de DosExecPgm. }
Function RunSession(S : LongInt) : LongInt;
Var Prev, R, K, N, D : LongInt; A : String;
Begin
  Prev := CurSes;
  SaveScreen(Prev);
  If SState[Prev] = SS_FORE Then SState[Prev] := SS_SUSP;
  ClearScreen;
  GoFore(S);
  { arguments : nom ASCIIZ puis parametres ASCIIZ, double zero }
  A := SProg[S];
  PutZ(LongInt(@ArgBuf), A);
  N := Length(A) + 1;
  PutZ(LongInt(@ArgBuf) + N, SArgs[S]);
  N := N + Length(SArgs[S]) + 1;
  WrB(LongInt(@ArgBuf) + N, 0);
  PutZ(LongInt(@NameZ), SProg[S]);
  { EXEC_ASYNCRESULT : le processus s'execute jusqu'a sa fin (un a la
    fois) ; Res[0] <- son identificateur, DosWaitChild <- son code }
  Res[0] := 0; Res[1] := 0;
  R := DcExecPgm(LongInt(@FailBuf), 64, 2, LongInt(@ArgBuf), 0, LongInt(@Res), LongInt(@NameZ));
  SResult[S] := R;
  If R = NO_ERROR Then
  Begin
    SPid[S] := Res[0];
    Res[0] := 0; Res[1] := 0; Res[2] := 0;
    If DcWaitChild(0, 0, LongInt(@Res), LongInt(@Res[2]), SPid[S]) = NO_ERROR Then SResult[S] := Res[1]
    Else SResult[S] := 0;
  End;
  If (SCtl[S] And 8) <> 0 Then
  Begin
    { SSF_CONTROL_NOAUTOCLOSE : attendre une touche }
    PutZ(LongInt(@NameZ), Chr(13) + Chr(10) + 'Session terminee : appuyez sur une touche.');
    D := VioWrtTty(LongInt(@NameZ), 44, 0);
    D := KbdCharIn(LongInt(@Ki), 0, 0);
  End;
  EndSession(S);
  { retour : la session parente (DosSMParentSwitch) ou d'origine }
  K := Prev;
  If SParentSw[S] And ValidSes(SParent[S]) And (SState[SParent[S]] = SS_SUSP) Then K := SParent[S];
  RestoreScreen(K);
  GoFore(K);
  ExecErr := R;
  RunSession := R;
End;

{ Le programme existe-t-il ? (sinon C:\nom) }
Function FindProg(Var Name : String) : Boolean;
Var Ok : Boolean;
Begin
  PutZ(LongInt(@NameZ), Name);
  Ok := DcQueryPathInfo(LongInt(@NameZ), 1, LongInt(@Info), 24) = NO_ERROR;
  If (Not Ok) And (Pos('\', Name) = 0) And (Pos(':', Name) = 0) Then
  Begin
    PutZ(LongInt(@NameZ), 'C:\' + Name);
    Ok := DcQueryPathInfo(LongInt(@NameZ), 1, LongInt(@Info), 24) = NO_ERROR;
    If Ok Then Name := 'C:\' + Name;
  End;
  FindProg := Ok;
End;

{ DosStartSession commune. Is32 : point d'entree 2.x (STARTDATA de 60
  octets accepte) ; Top : session de premier niveau (DosSMStart) }
Function StartSes(P, PSid, PPid : LongInt; Is32, Top : Boolean) : LongInt;
Var Len, Rel, FgBg, Trace, Inh, Typ, Ctl, S, R, D : LongInt; Prog, Args, T : String;
Begin
  WrL(PSid, 0);
  WrL(PPid, 0);
  If P = 0 Then
  Begin
    StartSes := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Len := RdW(P);
  If Not ((Len = 24) Or (Len = 30) Or (Len = 32) Or (Len = 50) Or (Is32 And (Len = 60))) Then
  Begin
    StartSes := ERROR_SMG_INVALID_DATA_LENGTH;
    Exit;
  End;
  Rel := RdW(P + 2);
  FgBg := RdW(P + 4);
  Trace := RdW(P + 6);
  Inh := 0; Typ := 0; Ctl := 0;
  If Len >= 30 Then Inh := RdW(P + 28);
  If Len >= 32 Then Typ := RdW(P + 30);
  If Len >= 50 Then Ctl := RdW(P + 40);
  R := NO_ERROR;
  If (Rel <> 0) And (Rel <> 1) Then R := ERROR_SMG_INVALID_RELATED_OPT
  Else If (FgBg <> 0) And (FgBg <> 1) Then R := ERROR_SMG_INVALID_START_MODE
  Else If Trace <> 0 Then R := ERROR_SMG_INVALID_TRACE_OPTION
  Else If (Inh <> 0) And (Inh <> 1) Then R := ERROR_SMG_INVALID_INHERIT_OPT
  Else If (Typ <> 0) And (Typ <> 1) And (Typ <> 2) Then R := ERROR_SMG_INVALID_PROGRAM_TYPE
  Else If (Ctl And Not $800F) <> 0 Then R := ERROR_SMG_INVALID_PGM_CONTROL;
  If R <> NO_ERROR Then
  Begin
    StartSes := R;
    Exit;
  End;
  { programme : PgmName, sinon l'interpreteur de commandes }
  Prog := GetZ(RdL(P + 12));
  If Prog = '' Then
  Begin
    Prog := 'C:\CMD.EXE';
    PutZ(LongInt(@NameZ), 'COMSPEC');
    D := 0;
    If DcScanEnv(LongInt(@NameZ), LongInt(@D)) = NO_ERROR Then
      If GetZ(D) <> '' Then Prog := GetZ(D);
  End;
  If Not FindProg(Prog) Then
  Begin
    If (Len = 60) And (RdL(P + 52) <> 0) Then PutZ(RdL(P + 52), Copy(Prog, 1, 60));
    StartSes := ERROR_FILE_NOT_FOUND;
    Exit;
  End;
  S := NewSes;
  If S = 0 Then
  Begin
    StartSes := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  Args := GetZ(RdL(P + 16));
  T := GetZ(RdL(P + 8));
  If T = '' Then T := UpStr(Prog);
  SProg[S] := UpStr(Prog);
  SArgs[S] := Args;
  STitle[S] := Copy(T, 1, 63);
  STermQ[S] := '';
  If (Rel = 1) And Not Top Then STermQ[S] := Copy(GetZ(RdL(P + 20)), 1, 63);
  If Top Then SParent[S] := 0 Else SParent[S] := CurSes;
  SRelated[S] := (Rel = 1) And Not Top;
  SSelect[S] := True;
  SBond[S] := False;
  SPid[S] := 0;
  SResult[S] := 0;
  If Typ = 0 Then Typ := 1;
  SType[S] := Typ;
  SCtl[S] := Ctl;
  SParentSw[S] := False;
  SState[S] := SS_PENDING;
  WrL(PSid, S);
  Notify(SN_START, S, 0);
  If (FgBg = 0) And Not Deferred Then
  Begin
    R := RunSession(S);
    If SRelated[S] Then WrL(PPid, SPid[S]);
    If R <> NO_ERROR Then
    Begin
      If (Len = 60) And (RdL(P + 52) <> 0) Then PutZ(RdL(P + 52), Copy(SProg[S], 1, 60));
      StartSes := R;
      Exit;
    End;
  End;
  StartSes := NO_ERROR;
End;

{ La session S est-elle une session enfant de la session Who ? }
Function ChildOf(S, Who : LongInt) : Boolean;
Begin
  ChildOf := ValidSes(S) And SRelated[S] And (SParent[S] = Who);
End;

{ Choisir la session S (au nom de la session Who) }
Function SelectSes(S, Who : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If (S = 0) Or (S = Who) Then
    R := NO_ERROR                                { la session elle-meme }
  Else If (Not ValidSes(S)) Or (SState[S] = SS_ENDED) Then R := ERROR_SMG_INVALID_SESSION_ID
  Else If Not ChildOf(S, Who) Then R := ERROR_SMG_SESSION_NOT_PARENT
  Else If SState[S] = SS_PENDING Then R := RunSession(S);
  SelectSes := R;
End;

Function StopSes(Scope, S, Who : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := NO_ERROR;
  If (Scope <> 0) And (Scope <> 1) Then R := ERROR_SMG_INVALID_STOP_OPTION
  Else If Scope = 1 Then
  Begin
    { toutes les sessions enfants }
    For I := 1 To MaxS Do
      If ChildOf(I, Who) And (SState[I] = SS_PENDING) Then EndSession(I);
  End
  Else If (Not ValidSes(S)) Or (SState[S] = SS_ENDED) Then R := ERROR_SMG_INVALID_SESSION_ID
  Else If Not ChildOf(S, Who) Then R := ERROR_SMG_SESSION_NOT_PARENT
  Else If SState[S] = SS_PENDING Then EndSession(S);
  StopSes := R;
End;

{ STATUSDATA (Length 6, SelectInd, BondInd) ou SelectInd + BondInd shl
  16 (PStat = 0) }
Function SetSes(S, PStat, Packed, Who : LongInt) : LongInt;
Var R, Sel, Bnd : LongInt;
Begin
  R := NO_ERROR;
  If PStat <> 0 Then
  Begin
    If RdW(PStat) <> 6 Then
    Begin
      SetSes := ERROR_SMG_INVALID_DATA_LENGTH;
      Exit;
    End;
    Sel := RdW(PStat + 2);
    Bnd := RdW(PStat + 4);
  End
  Else
  Begin
    Sel := Packed And $FFFF;
    Bnd := (Packed Shr 16) And $FFFF;
  End;
  If Sel > 2 Then R := ERROR_SMG_INVALID_SELECT_OPT
  Else If Bnd > 2 Then R := ERROR_SMG_INVALID_BOND_OPTION
  Else If (Not ValidSes(S)) Or (SState[S] = SS_ENDED) Then R := ERROR_SMG_INVALID_SESSION_ID
  Else If Not ChildOf(S, Who) Then R := ERROR_SMG_SESSION_NOT_PARENT
  Else
  Begin
    If Sel = 1 Then SSelect[S] := True;
    If Sel = 2 Then SSelect[S] := False;
    If Bnd = 1 Then SBond[S] := True;
    If Bnd = 2 Then SBond[S] := False;
  End;
  SetSes := R;
End;

{ ==================================================================== }
{ Partie 6 - Demandes des applications                                 }
{ ==================================================================== }

{ Mettre une demande en file ; rend NO_ERROR ou ERROR_NOT_ENOUGH_MEMORY }
Function Enqueue(Typ, Target, Param : LongInt) : LongInt;
Begin
  If QCount >= MaxReq Then
  Begin
    Enqueue := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  Inc(NextReq);
  QType[QCount] := Typ;
  QReqId[QCount] := NextReq;
  QFromSes[QCount] := CurSes;
  QFromPid[QCount] := MyPid;
  QTarget[QCount] := Target;
  QParam[QCount] := Param;
  Inc(QCount);
  Enqueue := NO_ERROR;
End;

{ Executer la demande du bloc APPREQ B (Who : session demandeuse) }
Function DoRequest(B : LongInt) : LongInt;
Var R, Typ, Who, S, Prm : LongInt;
Begin
  Typ := RdW(B);
  Who := RdL(B + 8);
  S := RdL(B + 16);
  Prm := RdL(B + 20);
  Case Typ Of
    RQ_START  :
      Begin
        If (Not ValidSes(S)) Or (SState[S] <> SS_PENDING) Then R := ERROR_SMG_INVALID_SESSION_ID
        Else If Prm = 1 Then R := NO_ERROR               { en arriere-plan : reste en attente }
        Else R := RunSession(S);
      End;
    RQ_STOP   : R := StopSes(Prm, S, Who);
    RQ_SELECT : R := SelectSes(S, Who);
    RQ_SET    : R := SetSes(S, 0, Prm, Who);
  Else
    R := ERROR_INVALID_PARAMETER;
  End;
  WrW(B + 2, 2);
  WrL(B + 24, R);
  DoRequest := R;
End;

{ ==================================================================== }
{ Partie 7 - Fonctions des sessions                                    }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  Dos32StartSession(pStartData, pidSession, ppid) : demarrer une session
  (STARTDATA). Au premier plan, son programme s'execute aussitot ;
  en arriere-plan (FgBg = 1), la session attend d'etre choisie.
  *pidSession <- identificateur ; *ppid <- processus (session enfant
  executee). Related 1 : session enfant (TermQ : file de fin). }
Function Dos32StartSession(P, PSid, PPid : LongInt) : LongInt;
Var R, S : LongInt;
Begin
  R := StartSes(P, PSid, PPid, True, False);
  If (R = NO_ERROR) And Deferred Then
  Begin
    S := RdL(PSid);
    R := Enqueue(RQ_START, S, RdW(P + 4));
  End;
  Dos32StartSession := R;
End;

{ DOSSTARTSESSION (OS/2 1.x) : STARTDATA de 24 a 50 octets }
Function DosStartSession16(P, PSid, PPid : LongInt) : LongInt;
Var R, S : LongInt;
Begin
  R := StartSes(P, PSid, PPid, False, False);
  If (R = NO_ERROR) And Deferred Then
  Begin
    S := RdL(PSid);
    R := Enqueue(RQ_START, S, RdW(P + 4));
  End;
  DosStartSession16 := R;
End;

{ ---------------------------------------------------------------------
  Dos32SelectSession(idSession) : faire passer au premier plan une
  session enfant (0 : la session elle-meme) ; une session en attente
  s'execute alors }
Function Dos32SelectSession(S : LongInt) : LongInt;
Begin
  If Deferred And (S <> 0) Then
  Begin
    If (Not ValidSes(S)) Or (SState[S] = SS_ENDED) Then Dos32SelectSession := ERROR_SMG_INVALID_SESSION_ID
    Else If Not ChildOf(S, CurSes) Then Dos32SelectSession := ERROR_SMG_SESSION_NOT_PARENT
    Else Dos32SelectSession := Enqueue(RQ_SELECT, S, 0);
  End
  Else
    Dos32SelectSession := SelectSes(S, CurSes);
End;

Function DosSelectSession16(S, Reserved : LongInt) : LongInt;
Begin
  DosSelectSession16 := Dos32SelectSession(S);
End;

{ ---------------------------------------------------------------------
  Dos32SetSession(idSession, pStatusData) : rendre une session enfant
  selectionnable ou non (SelectInd 1/2) et la lier ou non (BondInd 1/2) }
Function Dos32SetSession(S, PStat : LongInt) : LongInt;
Var R : LongInt;
Begin
  If PStat = 0 Then R := ERROR_INVALID_PARAMETER
  Else If Deferred Then
  Begin
    R := NO_ERROR;
    If RdW(PStat) <> 6 Then R := ERROR_SMG_INVALID_DATA_LENGTH
    Else If RdW(PStat + 2) > 2 Then R := ERROR_SMG_INVALID_SELECT_OPT
    Else If RdW(PStat + 4) > 2 Then R := ERROR_SMG_INVALID_BOND_OPTION
    Else If Not ChildOf(S, CurSes) Then R := ERROR_SMG_SESSION_NOT_PARENT;
    If R = NO_ERROR Then R := Enqueue(RQ_SET, S, RdW(PStat + 2) Or (RdW(PStat + 4) Shl 16));
  End
  Else
    R := SetSes(S, PStat, 0, CurSes);
  Dos32SetSession := R;
End;

Function DosSetSession16(S, PStat : LongInt) : LongInt;
Begin
  DosSetSession16 := Dos32SetSession(S, PStat);
End;

{ ---------------------------------------------------------------------
  Dos32StopSession(ulScope, idSession) : arreter une session enfant
  (ulScope 0) ou toutes (1) ; une session en attente est arretee sans
  avoir ete executee }
Function Dos32StopSession(Scope, S : LongInt) : LongInt;
Begin
  If Deferred Then
  Begin
    If (Scope <> 0) And (Scope <> 1) Then Dos32StopSession := ERROR_SMG_INVALID_STOP_OPTION
    Else Dos32StopSession := Enqueue(RQ_STOP, S, Scope);
  End
  Else
    Dos32StopSession := StopSes(Scope, S, CurSes);
End;

Function DosStopSession16(Scope, S, Reserved : LongInt) : LongInt;
Begin
  DosStopSession16 := Dos32StopSession(Scope, S);
End;

{ ==================================================================== }
{ Partie 8 - Fonctions de l'interpreteur (DosSM*)                      }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  DosSMInitialize : le premier processus appelant devient l'interpreteur
  proprietaire du gestionnaire de sessions ; les appels suivants
  echouent (ERROR_SMG_INVALID_CALL) }
Function DosSMInitialize : LongInt;
Begin
  If (OwnerPid <> 0) And Not Alive(OwnerPid) Then OwnerPid := 0;
  If OwnerPid <> 0 Then DosSMInitialize := ERROR_SMG_INVALID_CALL
  Else
  Begin
    OwnerPid := MyPid;
    OwnerSes := CurSes;
    QCount := 0;
    DosSMInitialize := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  DosSMStart(pStartData, pidSession, ppid) : l'interpreteur demarre une
  session de premier niveau (sans parent) }
Function DosSMStart(P, PSid, PPid : LongInt) : LongInt;
Begin
  If Not IsOwner Then DosSMStart := ERROR_SMG_INVALID_CALL
  Else DosSMStart := StartSes(P, PSid, PPid, True, True);
End;

{ ---------------------------------------------------------------------
  DosSMSwitch(idSession) : faire passer une session au premier plan
  (interpreteur) ; refuse avant la duree de DosSetMNLockTime
  (ERROR_BUSY) et pour une session non selectionnable }
Function DosSMSwitch(S : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If Not IsOwner Then R := ERROR_SMG_INVALID_CALL
  Else If (Not ValidSes(S)) Or (SState[S] = SS_ENDED) Then R := ERROR_SMG_INVALID_SESSION_ID
  Else If S = CurSes Then R := NO_ERROR
  Else If Not SSelect[S] Then R := ERROR_ACCESS_DENIED
  Else If (MNLockTime > 0) And (KGetTickCount - FgSince < MNLockTime) Then R := ERROR_BUSY
  Else If SState[S] = SS_SUSP Then R := ERROR_BUSY       { attend une session enfant }
  Else R := RunSession(S);
  DosSMSwitch := R;
End;

{ ---------------------------------------------------------------------
  DosSMParentSwitch : a la fin de la session courante, revenir a sa
  session parente }
Function DosSMParentSwitch : LongInt;
Begin
  If (CurSes < 1) Or (SParent[CurSes] = 0) Then DosSMParentSwitch := ERROR_SMG_INVALID_CALL
  Else
  Begin
    SParentSw[CurSes] := True;
    DosSMParentSwitch := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  DosSMTerminate(idSession) : terminer une session (interpreteur) : une
  session en attente est arretee, une session terminee est liberee }
Function DosSMTerminate(S : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If Not IsOwner Then R := ERROR_SMG_INVALID_CALL
  Else If (Not ValidSes(S)) Or (S = 1) Then R := ERROR_SMG_INVALID_SESSION_ID
  Else If (SState[S] = SS_FORE) Or (SState[S] = SS_SUSP) Then R := ERROR_BUSY
  Else
  Begin
    If SState[S] = SS_PENDING Then EndSession(S);
    SState[S] := SS_FREE;
  End;
  DosSMTerminate := R;
End;

{ ---------------------------------------------------------------------
  DosSMGetStatus(pBuf, cbBuf, pcbOut) : etat des sessions (SMSTATUS,
  16 octets par session ; interpreteur) }
Function DosSMGetStatus(PBuf, Cb, PcbOut : LongInt) : LongInt;
Var I, O, F, R : LongInt;
Begin
  R := NO_ERROR;
  O := 0;
  If Not IsOwner Then R := ERROR_SMG_INVALID_CALL
  Else If PBuf = 0 Then R := ERROR_INVALID_PARAMETER
  Else
    For I := 1 To MaxS Do
      If SState[I] <> SS_FREE Then
      Begin
        If O + 16 > Cb Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          F := 0;
          If SSelect[I] Then F := F Or 1;
          If SBond[I] Then F := F Or 2;
          If SRelated[I] Then F := F Or 4;
          If PopSes = I Then F := F Or 8;
          WrW(PBuf + O, I);
          WrW(PBuf + O + 2, SParent[I]);
          WrW(PBuf + O + 4, SState[I]);
          WrW(PBuf + O + 6, F);
          WrL(PBuf + O + 8, SPid[I]);
          WrW(PBuf + O + 12, SType[I]);
          WrW(PBuf + O + 14, SResult[I]);
          O := O + 16;
        End;
      End;
  WrL(PcbOut, O);
  DosSMGetStatus := R;
End;

{ ---------------------------------------------------------------------
  DosSMGetAppReq(pReq, fWait) : prendre la demande suivante des
  applications (APPREQ) ; ERROR_QUE_EMPTY s'il n'y en a pas (une attente
  ne peut aboutir : aucun autre processus ne s'execute) }
Function DosSMGetAppReq(B, Wait : LongInt) : LongInt;
Var I, K : LongInt;
Begin
  If Not IsOwner Then DosSMGetAppReq := ERROR_SMG_INVALID_CALL
  Else If B = 0 Then DosSMGetAppReq := ERROR_INVALID_PARAMETER
  Else If QCount = 0 Then DosSMGetAppReq := ERROR_QUE_EMPTY
  Else
  Begin
    WrW(B, QType[0]);
    WrW(B + 2, 1);
    WrL(B + 4, QReqId[0]);
    WrL(B + 8, QFromSes[0]);
    WrL(B + 12, QFromPid[0]);
    WrL(B + 16, QTarget[0]);
    WrL(B + 20, QParam[0]);
    WrL(B + 24, 0);
    { numero remis : a servir }
    K := -1;
    For I := MaxReq - 1 DownTo 0 Do
      If Served[I] = 0 Then K := I;
    If K >= 0 Then Served[K] := QReqId[0];
    For I := 0 To QCount - 2 Do
    Begin
      QType[I] := QType[I + 1]; QReqId[I] := QReqId[I + 1];
      QFromSes[I] := QFromSes[I + 1]; QFromPid[I] := QFromPid[I + 1];
      QTarget[I] := QTarget[I + 1]; QParam[I] := QParam[I + 1];
    End;
    Dec(QCount);
    DosSMGetAppReq := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  DosSMServeAppReq(pReq) : executer une demande recue par DosSMGetAppReq
  (le resultat est range dans le bloc) }
Function DosSMServeAppReq(B : LongInt) : LongInt;
Var I, K, R : LongInt;
Begin
  If Not IsOwner Then
  Begin
    DosSMServeAppReq := ERROR_SMG_INVALID_CALL;
    Exit;
  End;
  If B = 0 Then
  Begin
    DosSMServeAppReq := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  K := -1;
  For I := 0 To MaxReq - 1 Do
    If (Served[I] <> 0) And (Served[I] = RdL(B + 4)) Then K := I;
  If (K < 0) Or (RdW(B + 2) <> 1) Then
  Begin
    DosSMServeAppReq := ERROR_SMG_INVALID_CALL;    { demande inconnue ou deja servie }
    Exit;
  End;
  Served[K] := 0;
  R := DoRequest(B);
  DosSMServeAppReq := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  DosSMDoAppReq(pReq) : l'interpreteur execute une demande (APPREQ) pour
  une session enfant de sa session ; resultat dans le bloc et rendu }
Function DosSMDoAppReq(B : LongInt) : LongInt;
Begin
  If Not IsOwner Then DosSMDoAppReq := ERROR_SMG_INVALID_CALL
  Else If B = 0 Then DosSMDoAppReq := ERROR_INVALID_PARAMETER
  Else
  Begin
    WrL(B + 8, CurSes);
    WrL(B + 12, MyPid);
    DosSMDoAppReq := DoRequest(B);
  End;
End;

{ ---------------------------------------------------------------------
  DosSMSetSessionType(idSession, usType) : changer le type d'une session
  (1 plein ecran, 2 fenetre VIO ; interpreteur) }
Function DosSMSetSessionType(S, Typ : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If Not IsOwner Then R := ERROR_SMG_INVALID_CALL
  Else If (Not ValidSes(S)) Or (SState[S] = SS_ENDED) Then R := ERROR_SMG_INVALID_SESSION_ID
  Else If (Typ <> 1) And (Typ <> 2) Then R := ERROR_SMG_INVALID_PROGRAM_TYPE
  Else SType[S] := Typ;
  DosSMSetSessionType := R;
End;

{ ---------------------------------------------------------------------
  DosSetMNLockTime(ulMs) : duree minimale (ms) pendant laquelle une
  session passee au premier plan y reste (interpreteur) ;
  DosGetTimes(pMs) : la rendre }
Function DosSetMNLockTime(Ms : LongInt) : LongInt;
Begin
  If Not IsOwner Then DosSetMNLockTime := ERROR_SMG_INVALID_CALL
  Else If Ms < 0 Then DosSetMNLockTime := ERROR_INVALID_PARAMETER
  Else
  Begin
    MNLockTime := Ms;
    DosSetMNLockTime := NO_ERROR;
  End;
End;

Function DosGetTimes(PMs : LongInt) : LongInt;
Begin
  If PMs = 0 Then DosGetTimes := ERROR_INVALID_PARAMETER
  Else
  Begin
    WrL(PMs, MNLockTime);
    DosGetTimes := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  DosSMSetTitle(pszTitle) : titre de la session courante }
Function DosSMSetTitle(PTitle : LongInt) : LongInt;
Begin
  If PTitle = 0 Then DosSMSetTitle := ERROR_INVALID_PARAMETER
  Else
  Begin
    STitle[CurSes] := Copy(GetZ(PTitle), 1, 63);
    Notify(SN_TITLE, CurSes, MyPid);
    DosSMSetTitle := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  DosSMPause : Ctrl+Verr num (PAUSE) : la session est suspendue jusqu'a
  la touche suivante (consommee) }
Function DosSMPause : LongInt;
Begin
  DosSMPause := KbdCharIn(LongInt(@Ki), 0, 0);
End;

{ ---------------------------------------------------------------------
  DosSMHDEInit : initialisation de HARDERR.EXE (processus des erreurs
  materielles) ; DosSMSysInit : synchronisation de HARDERR et de
  l'interpreteur }
Function DosSMHDEInit : LongInt;
Begin
  If (HardErrPid <> 0) And (HardErrPid <> MyPid) And Alive(HardErrPid) Then
    DosSMHDEInit := ERROR_SMG_INVALID_CALL
  Else
  Begin
    HardErrPid := MyPid;
    DosSMHDEInit := NO_ERROR;
  End;
End;

Function DosSMSysInit : LongInt;
Begin
  SysInitDone := True;
  DosSMSysInit := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  DosSMPMPresent(pfPresent) : Presentation Manager est-il present ?
  (*pfPresent <- 0 : non) }
Function DosSMPMPresent(PFlag : LongInt) : LongInt;
Begin
  If PFlag = 0 Then DosSMPMPresent := ERROR_INVALID_PARAMETER
  Else
  Begin
    WrL(PFlag, 0);
    DosSMPMPresent := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  DosSMRegisterDD(pszDDName) : inscrire un pilote (KBD$, MOUSE$...) pour
  etre averti des changements de session ; DosSMOpenDD(pcCount) : ouvrir
  les pilotes inscrits ; DosSMNotifyDD(ulEvent, idSession, pcCount) :
  avertir les pilotes ouverts (par HARDERR) ; DosSMNotifyDD2 : avertir
  tous les pilotes inscrits. KBD$ recoit KbdSwitchFgnd au passage au
  premier plan (evenement 4). }
Function DosSMRegisterDD(PName : LongInt) : LongInt;
Var I : LongInt; N : String; Found : Boolean;
Begin
  N := UpStr(GetZ(PName));
  If (PName = 0) Or (N = '') Or (Length(N) > 15) Then
  Begin
    DosSMRegisterDD := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Found := False;
  For I := 0 To DDCount - 1 Do
    If DDName[I] = N Then Found := True;
  If Found Then DosSMRegisterDD := NO_ERROR
  Else If DDCount >= MaxDD Then DosSMRegisterDD := ERROR_NOT_ENOUGH_MEMORY
  Else
  Begin
    DDName[DDCount] := N;
    DDOpen[DDCount] := False;
    Inc(DDCount);
    DosSMRegisterDD := NO_ERROR;
  End;
End;

Function DosSMOpenDD(PCount : LongInt) : LongInt;
Var I : LongInt;
Begin
  For I := 0 To DDCount - 1 Do DDOpen[I] := True;
  WrL(PCount, DDCount);
  DosSMOpenDD := NO_ERROR;
End;

Function DosSMNotifyDD(Ev, Ses, PCount : LongInt) : LongInt;
Begin
  WrL(PCount, NotifyDDs(Ev, Ses, True));
  DosSMNotifyDD := NO_ERROR;
End;

Function DosSMNotifyDD2(Ev, Ses, PCount : LongInt) : LongInt;
Begin
  WrL(PCount, NotifyDDs(Ev, Ses, False));
  DosSMNotifyDD2 := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  DosRegisterNotification(pszModule, pszEntry, flEvents) : la fonction
  pszEntry du module est appelee (_System) par Entree(evenement,
  session, processus) pour les evenements choisis (bit n : evenement n ;
  2 demarrage, 3 fin, 4 premier plan, 5 titre) ; flEvents = 0 : retirer }
Function DosRegisterNotification(PMod, PEntry, Mask : LongInt) : LongInt;
Var H, E, I, F : LongInt;
Begin
  If (PMod = 0) Or (PEntry = 0) Then
  Begin
    DosRegisterNotification := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If DcLoadModule(LongInt(@FailBuf), 64, PMod, LongInt(@H)) <> NO_ERROR Then
  Begin
    DosRegisterNotification := ERROR_MOD_NOT_FOUND;
    Exit;
  End;
  E := 0;
  If (DcQueryProcAddr(H, 0, PEntry, LongInt(@E)) <> NO_ERROR) Or (E = 0) Then
  Begin
    DosRegisterNotification := ERROR_PROC_NOT_FOUND;
    Exit;
  End;
  F := -1;
  For I := MaxNotif - 1 DownTo 0 Do
    If NEntry[I] = E Then F := I;
  If F < 0 Then
    For I := MaxNotif - 1 DownTo 0 Do
      If NEntry[I] = 0 Then F := I;
  If (F < 0) And (Mask <> 0) Then
  Begin
    DosRegisterNotification := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  If F >= 0 Then
  Begin
    If Mask = 0 Then NEntry[F] := 0
    Else
    Begin
      NEntry[F] := E;
      NMask[F] := Mask;
    End;
  End;
  DosRegisterNotification := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 9 - Ecran, fenetres surgissantes, sauvegarde                  }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  DosSMSGDoPopup(fWait) : la session courante veut une fenetre
  surgissante (ERROR_BUSY si une autre est ouverte : l'attente ne peut
  aboutir) ; DosSMSGEndPopup : fin de la fenetre surgissante }
Function DosSMSGDoPopup(Wait : LongInt) : LongInt;
Begin
  If (Wait <> 0) And (Wait <> 1) Then DosSMSGDoPopup := ERROR_INVALID_PARAMETER
  Else If PopSes <> 0 Then DosSMSGDoPopup := ERROR_BUSY
  Else
  Begin
    PopSes := CurSes;
    DosSMSGDoPopup := NO_ERROR;
  End;
End;

Function DosSMSGEndPopup : LongInt;
Begin
  If PopSes <> CurSes Then DosSMSGEndPopup := ERROR_SMG_INVALID_CALL
  Else
  Begin
    PopSes := 0;
    DosSMSGEndPopup := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  DosScrLock(fWait, pfNotLocked) et DosScrUnlock : verrou de l'ecran
  (celui de VIOCALLS.DLL, VioScrLock et VioScrUnlock) }
Function DosScrLock(Wait, PNot : LongInt) : LongInt;
Begin
  DosScrLock := VioScrLock(Wait, PNot, 0);
End;

Function DosScrUnlock(Reserved : LongInt) : LongInt;
Begin
  DosScrUnlock := VioScrUnlock(0);
End;

{ ---------------------------------------------------------------------
  DosSavRedrawWait(usRedrawInd, pNotifyType), DosSavRedrawUndo
  (usOwnerInd, usKillInd), DosModeWait(usReqType, pNotifyType),
  DosModeUndo(usOwnerInd, usKillInd) : processus leger de sauvegarde et
  de retracage de l'ecran (VIOCALLS.DLL) ; le gestionnaire sauvegarde
  lui-meme l'ecran du mode texte a chaque changement de session : les
  attentes rendent ERROR_INTERRUPT }
Function DosSavRedrawWait(Ind, PNotify : LongInt) : LongInt;
Begin
  DosSavRedrawWait := VioSavRedrawWait(Ind, PNotify, 0);
End;

Function DosSavRedrawUndo(Owner, Kill : LongInt) : LongInt;
Begin
  DosSavRedrawUndo := VioSavRedrawUndo(Owner, Kill, 0);
End;

Function DosModeWait(Req, PNotify : LongInt) : LongInt;
Begin
  DosModeWait := VioModeWait(Req, PNotify, 0);
End;

Function DosModeUndo(Owner, Kill : LongInt) : LongInt;
Begin
  DosModeUndo := VioModeUndo(Owner, Kill, 0);
End;

{ ---------------------------------------------------------------------
  DosSMRealPrtSc : impression de l'ecran de la session (VioPrtSc) }
Function DosSMRealPrtSc : LongInt;
Begin
  DosSMRealPrtSc := VioPrtSc(0);
End;

{ ==================================================================== }
{ Exportations                                                         }
{ ==================================================================== }

exports
  DosSMSGDoPopup Index 1, DosSMSwitch Index 2, DosSMServeAppReq Index 3,
  DosGetTimes Index 4, DosSMSetTitle Index 5, DosScrUnlock Index 6,
  DosSMDoAppReq Index 7, DosStopSession16 Index 8 Name 'DOSSTOPSESSION',
  DosSelectSession16 Index 9 Name 'DOSSELECTSESSION', DosScrLock Index 10,
  DosSavRedrawWait Index 11, DosSavRedrawUndo Index 12,
  DosSMSGEndPopup Index 13, DosSetSession16 Index 14 Name 'DOSSETSESSION',
  DosSetMNLockTime Index 15, DosModeUndo Index 16,
  DosStartSession16 Index 17 Name 'DOSSTARTSESSION',
  DosSMGetStatus Index 18, DosModeWait Index 19, DosSMTerminate Index 20,
  DosSMGetAppReq Index 21, DosSMRealPrtSc Index 22,
  DosSMInitialize Index 23, DosSMStart Index 24,
  DosSMParentSwitch Index 25, DosSMPause Index 26, DosSMHDEInit Index 27,
  DosSMPMPresent Index 28, DosSMRegisterDD Index 29 Name 'DOSSMREGISTERDD',
  DosSMSysInit Index 30, DosSMNotifyDD Index 31, DosSMNotifyDD2 Index 32,
  DosSMOpenDD Index 33, QhKeybdHandle Index 34, QhMouseHandle Index 35,
  DosSMSetSessionType Index 36, Dos32StartSession Index 37,
  Dos32SelectSession Index 38, Dos32SetSession Index 39,
  Dos32StopSession Index 40, DosRegisterNotification Index 41;

Var
  InitI : LongInt;

BEGIN
  For InitI := 1 To MaxS Do SState[InitI] := SS_FREE;
  { session 1 : la session initiale (CMD.EXE) }
  SState[1] := SS_FORE;
  SParent[1] := 0;
  SRelated[1] := False;
  SSelect[1] := True;
  SBond[1] := False;
  SPid[1] := 0;
  SType[1] := 1;
  SProg[1] := 'C:\CMD.EXE';
  SArgs[1] := '';
  STitle[1] := 'OS/2-0';
  STermQ[1] := '';
  CurSes := 1;
  FgSince := 0;
  OwnerPid := 0; OwnerSes := 0;
  MNLockTime := 0;
  HardErrPid := 0;
  SysInitDone := False;
  QCount := 0; NextReq := 0;
  For InitI := 0 To MaxReq - 1 Do Served[InitI] := 0;
  For InitI := 0 To MaxNotif - 1 Do NEntry[InitI] := 0;
  DDCount := 0;
  PopSes := 0;
  QueMod := 0;
END.
