{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 OS2SM.DLL de OS/2-0 (gestionnaire de
                sessions de l'interpreteur de Presentation Manager : liste
                des taches).
}

Library OS2SM;

{$IMAGEBASE $00850000}
{$R-,S-,I-}

{ Compilation : OS2PC OS2SM.PAS   (produit OS2SM.DLL)

  OS2SM.DLL est la partie gestion des sessions de l'interpreteur de
  commandes de Presentation Manager : la liste des taches (switch list,
  Win*SwitchEntry, WinQuerySwitchList), le demarrage et l'arret des
  programmes (WinStartApp, SheStartProgram), le passage d'un programme a
  l'autre (WinSwitchToProgram, raccourcis Ctrl+Echap et Alt+Echap), les
  titres des taches, le fichier OS2SM.INI de l'interpreteur (programmes
  et polices de demarrage, bureau) et l'arret du systeme.

  OS/2-0 n'a pas Presentation Manager : les handles de fenetres (HWND)
  sont des valeurs conservees telles quelles ; les sessions sont celles
  de SESMGR.DLL (une entree de la liste designe une session : la
  choisir l'execute, voir SESMGR.PAS). WinInitSessionMgr fait du
  processus appelant l'interpreteur proprietaire du gestionnaire de
  sessions (DosSMInitialize).

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires ; un pointeur vers une valeur simple designe un LongInt. Les
  fonctions BOOL rendent 1 (vrai) ou 0 ; les autres un code (0 : succes ;
  PMERR_*) ou un handle (0 : echec). Structures de Presentation Manager :
    SWCNTRL   hwnd, hwndIcon, hprog, idProcess, idSession, uchVisibility
              (1 invisible, 2 grisee, 4 visible), fbJump (1 non, 2
              accessible par Alt+Echap), szSwtitle (64 octets), bProgType
                                                                96 octets
    SWENTRY   hswitch, SWCNTRL                                 100 octets
    SWBLOCK   cswentry, SWENTRY[]
    SWP       fl, cy, cx, y, x, hwndInsertBehind, hwnd, 2 reserves
                                                                36 octets
    PROGDETAILS Length, progc, fbVisible, pszTitle, pszExecutable,
              pszParameters, pszStartupDir, pszIcon, pszEnvironment,
              swpInitial                                        72 octets
    STARTDATA voir SESMGR.PAS
  Fichier OS2SM.INI (texte, C:\OS2SM.INI par defaut) : lignes RUN=programme
  parametres (StartSystemExecutables), FONT=fichier (ShlLoadPublicFonts) ;
  WinSave ecrit la section [Bureau] (une ligne ENTRY=titre par entree).

  Fonctions exportees (ordinaux d'origine d'OS2SM.DLL) :
     1 WININITSESSIONMGR      16 WINREMOVESWITCHENTRY  31 WININITSESSION
     2 WINSETFGNDWINDOW       17 WINSWITCHTOPROGRAM    32 WINENDSESSION
     3 SHLUNLOADPUBLICFONTS   18 WINSWITCHPROGRAMREGISTER 33 WININITSWENTRY
     4 WINSTPREGISTER         19 WINEXECPROGRAM        34 WINSETSWENTRY
     5 WININSTSTARTAPP        20 SHESTARTPROGRAM       35 WINQUERYEXTIDFOCUS
     6 WINTERMINATEAPP        21 WINENDPROGRAM         36 WINSETEXTIDFOCUS
     7 WINCREATESWITCHENTRY   22 WINSTOPPROGRAM        37 SHESYSTEMSHUTDOWN
     8 WINQUERYSESSIONTITLE   23 WINENDWINDOWSESSION   38 STARTSYSTEMEXECUTABLES
     9 WINADDSWITCHENTRY      24 LPFNSHELLWNDPROC      39 SHLLOADPUBLICFONTS
    10 WINCHANGESWITCHENTRY   25 LPFNICONWNDPROC       40 WINNOSHUTDOWN
    11 WINQUERYSWITCHENTRY    26 WINSWITCHTOTASKMANAGER 41 SHEINITIALIZEINIFILE
    12 WINQUERYSWITCHHANDLE   27 FNBADAPPDLGPROC       42 WINSETTITLE
    13 WINQUERYTASKTITLE      28 WINSWITCHTOPROGRAM2   43 WINCPLREGISTER
    14 WINQUERYTASKSIZEPOS    29 WINPROCESSHOTKEY      44 WINPMFILEREGISTER
    15 WINQUERYSWITCHLIST     30 WINSAVE               45 SHESTARTLONGPROGRAM
   103 SHELLWINDOW (donnee : handle de la fenetre de l'interpreteur)
  LPFNSHELLWNDPROC, LPFNICONWNDPROC et FNBADAPPDLGPROC sont les procedures
  de fenetre (hwnd, msg, mp1, mp2) : leur adresse est le pointeur exporte.
  OS2SMNOTIFY (ordinal 200, interne a OS/2-0) est la fonction que SESMGR
  appelle (DosRegisterNotification) au demarrage, a la fin et au passage
  au premier plan d'une session : la liste des taches suit ainsi toutes
  les sessions (une session terminee quitte la liste).

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services des autres DLL
    Partie 3 - Utilitaires
    Partie 4 - Liste des taches
    Partie 5 - Sessions et programmes
    Partie 6 - Fichier OS2SM.INI
    Partie 7 - Fonctions
    Exportations et initialisation }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  NO_ERROR = 0;
  { codes de Presentation Manager }
  PMERR_INVALID_HWND           = $1001;
  PMERR_PARAMETER_OUT_OF_RANGE = $1003;
  PMERR_INVALID_SWITCH_HANDLE  = $1207;
  PMERR_INVALID_SESSION_ID     = $120B;
  PMERR_STARTED_IN_BACKGROUND  = $1532;
  ERROR_SMG_INVALID_CALL       = 418;
  ERROR_SMG_START_IN_BACKGROUND = 457;

  SWL_INVISIBLE  = 1;
  SWL_GRAYED     = 2;
  SWL_VISIBLE    = 4;
  SWL_NOTJUMPABLE = 1;
  SWL_JUMPABLE   = 2;

  { WinStartApp }
  SAF_INSTALLEDCMDLINE = 1;
  SAF_STARTCHILDAPP    = 2;
  SAF_BACKGROUND       = 16;
  PROG_PM              = 3;

  { messages }
  WM_CREATE        = $0001;
  WM_COMMAND       = $0020;
  WM_CLOSE         = $0029;
  WM_INITDLG       = $003B;
  WM_BUTTON1DBLCLK = $0073;

  MaxSw   = 32;              { entrees de la liste des taches }
  MaxReg  = 8;               { fenetres et modules inscrits }
  MaxFont = 16;
  HappBase = $1000;          { HAPP = HappBase + session }
  DefIni  = 'C:\OS2SM.INI';

  { donnee exportee }
  SHELLWINDOW = $00010001;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  EUsed   : Array[0..MaxSw - 1] Of Boolean;
  EGen    : Array[0..MaxSw - 1] Of LongInt;
  EHwnd, EIcon, EProg, EPid, ESes, EVis, EJump, EType : Array[0..MaxSw - 1] Of LongInt;
  ETitle  : Array[0..MaxSw - 1] Of String[63];
  CurSes  : LongInt;                       { session courante (vue d'OS2SM) }
  Initialized : Boolean;
  OwnerPid : LongInt;
  ExtFocus : LongInt;
  NoShut  : Boolean;
  ShutDone : Boolean;
  Regd    : Boolean;                       { avertissements de SESMGR }
  PendTitle : String[63];                  { titre de la session demarree }
  PendType : LongInt;
  { inscriptions }
  RegH    : Array[0..2 * MaxReg - 1] Of LongInt;   { 0 : WinStpRegister ; MaxReg : WinSwitchProgramRegister }
  CplName, PmfName : Array[0..MaxReg - 1] Of String[63];
  FontName : Array[0..MaxFont - 1] Of String[63];
  FontCount : LongInt;
  IniPath : String[127];

  Sd      : Array[0..63] Of Byte;          { STARTDATA }
  NameZ, Name2, Name3, Name4 : Array[0..259] Of Byte;
  RegMod, RegEnt : Array[0..15] Of Byte;
  Info    : Array[0..63] Of Byte;
  IoBuf   : Array[0..8191] Of Byte;
  IoLen   : LongInt;
  Res     : Array[0..3] Of LongInt;
  Dummy   : LongInt;

{ ==================================================================== }
{ Partie 2 - Services des autres DLL                                   }
{ ==================================================================== }

Function Dos32StartSession(P, PSid, PPid : LongInt) : LongInt; External 'SESMGR' Name 'Dos32StartSession';
Function Dos32StopSession(Scope, S : LongInt) : LongInt; External 'SESMGR' Name 'Dos32StopSession';
Function Dos32SelectSession(S : LongInt) : LongInt; External 'SESMGR' Name 'Dos32SelectSession';
Function DosSMInitialize : LongInt; External 'SESMGR' Name 'DosSMInitialize';
Function DosSMStart(P, PSid, PPid : LongInt) : LongInt; External 'SESMGR' Name 'DosSMStart';
Function DosRegisterNotification(PMod, PEntry, Mask : LongInt) : LongInt; External 'SESMGR' Name 'DosRegisterNotification';
Function DosSMSwitch(S : LongInt) : LongInt; External 'SESMGR' Name 'DosSMSwitch';
Function DosSMTerminate(S : LongInt) : LongInt; External 'SESMGR' Name 'DosSMTerminate';
Function DosSMSetTitle(P : LongInt) : LongInt; External 'SESMGR' Name 'DosSMSetTitle';
Function DcExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS' Name 'DosExecPgm';
Function DcShutdown(Reserved : LongInt) : LongInt; External 'DOSCALLS' Name 'DosShutdown';
Function DcOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS' Name 'DosOpen';
Function DcRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRead';
Function DcWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWrite';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';
Function DcQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryPathInfo';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';

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

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
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

{ Copier un titre dans un tampon de Cb octets (tronque, termine par 0) }
Procedure PutTitle(A, Cb : LongInt; S : String);
Begin
  If (A = 0) Or (Cb <= 0) Then Exit;
  If Length(S) > Cb - 1 Then S := Copy(S, 1, Cb - 1);
  PutZ(A, S);
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

Function BaseName(S : String) : String;
Var K, P : LongInt;
Begin
  P := 0;
  For K := 1 To Length(S) Do
    If (S[K] = '\') Or (S[K] = ':') Then P := K;
  BaseName := Copy(S, P + 1, 255);
End;

{ ==================================================================== }
{ Partie 4 - Liste des taches                                          }
{ ==================================================================== }

Function HSw(I : LongInt) : LongInt;
Begin
  HSw := (EGen[I] Shl 8) Or (I + 1);
End;

Function SwIdx(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  I := (H And $FF) - 1;
  If (I >= 0) And (I < MaxSw) Then
    If EUsed[I] And (EGen[I] = (H Shr 8)) Then R := I;
  SwIdx := R;
End;

{ SWCNTRL valide ? (visibilite, saut) }
Function SwValid(P : LongInt) : Boolean;
Var V, J : LongInt;
Begin
  V := RdL(P + 20);
  J := RdL(P + 24);
  SwValid := ((V = SWL_INVISIBLE) Or (V = SWL_GRAYED) Or (V = SWL_VISIBLE)) And
             ((J = SWL_NOTJUMPABLE) Or (J = SWL_JUMPABLE));
End;

Procedure SwFromCtl(I, P : LongInt);
Begin
  EHwnd[I] := RdL(P);
  EIcon[I] := RdL(P + 4);
  EProg[I] := RdL(P + 8);
  EPid[I] := RdL(P + 12);
  ESes[I] := RdL(P + 16);
  EVis[I] := RdL(P + 20);
  EJump[I] := RdL(P + 24);
  ETitle[I] := Copy(GetZ(P + 28), 1, 63);
  EType[I] := RdL(P + 92);
  If EPid[I] = 0 Then EPid[I] := MyPid;
  If ESes[I] = 0 Then ESes[I] := CurSes;
End;

Procedure SwToCtl(I, P : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 95 Do WrB(P + K, 0);
  WrL(P, EHwnd[I]);
  WrL(P + 4, EIcon[I]);
  WrL(P + 8, EProg[I]);
  WrL(P + 12, EPid[I]);
  WrL(P + 16, ESes[I]);
  WrL(P + 20, EVis[I]);
  WrL(P + 24, EJump[I]);
  PutZ(P + 28, ETitle[I]);
  WrL(P + 92, EType[I]);
End;

{ Nouvelle entree ; rend l'indice ou -1 }
Function NewEntry : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxSw - 1 DownTo 0 Do
    If Not EUsed[I] Then F := I;
  If F >= 0 Then EUsed[F] := True;
  NewEntry := F;
End;

Procedure FreeEntry(I : LongInt);
Begin
  EUsed[I] := False;
  Inc(EGen[I]);
  If EGen[I] > $FFFFFF Then EGen[I] := 1;
End;

{ Entree d'une session (-1 : aucune) }
Function SesEntry(S : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := MaxSw - 1 DownTo 0 Do
    If EUsed[I] And (ESes[I] = S) Then R := I;
  SesEntry := R;
End;

{ Entree simple d'une session (titre, visible, accessible) }
Function AddSesEntry(S : LongInt; T : String; Typ : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := NewEntry;
  If I >= 0 Then
  Begin
    EHwnd[I] := 0; EIcon[I] := 0; EProg[I] := 0;
    EPid[I] := 0;
    ESes[I] := S;
    EVis[I] := SWL_VISIBLE;
    EJump[I] := SWL_JUMPABLE;
    ETitle[I] := Copy(T, 1, 63);
    EType[I] := Typ;
  End;
  AddSesEntry := I;
End;

{ Retirer toutes les entrees de la session S }
Procedure RemoveSes(S : LongInt);
Var I : LongInt;
Begin
  For I := 0 To MaxSw - 1 Do
    If EUsed[I] And (ESes[I] = S) Then FreeEntry(I);
End;

{ ==================================================================== }
{ Partie 5 - Sessions et programmes                                    }
{ ==================================================================== }

{ Avertissement de SESMGR.DLL (DosRegisterNotification) :
  Ev 2 demarrage (entree de la session), 3 fin (ses entrees sont
  retirees), 4 premier plan (session courante) }
Function SmNotify(Ev, S, Pid : LongInt) : LongInt;
Var I : LongInt; T : String;
Begin
  If Ev = 2 Then
  Begin
    If SesEntry(S) < 0 Then
    Begin
      T := PendTitle;
      If T = '' Then T := 'Session ' + Chr(48 + S Div 10) + Chr(48 + S Mod 10);
      I := AddSesEntry(S, T, PendType);
    End;
  End
  Else If Ev = 3 Then
  Begin
    RemoveSes(S);
    If ExtFocus = S Then ExtFocus := 0;
  End
  Else If Ev = 4 Then
  Begin
    CurSes := S;
    I := SesEntry(S);
    If (I >= 0) And (Pid <> 0) Then EPid[I] := Pid;
  End;
  SmNotify := 0;
End;

{ S'inscrire une fois aupres de SESMGR (evenements 2 a 4) }
Procedure EnsureReg;
Begin
  If Regd Then Exit;
  PutZ(LongInt(@RegMod), 'OS2SM');
  PutZ(LongInt(@RegEnt), 'OS2SMNOTIFY');
  If DosRegisterNotification(LongInt(@RegMod), LongInt(@RegEnt), $1C) = NO_ERROR Then Regd := True;
End;

{ Passer a la session S (elle s'execute si elle est en attente) :
  DosSMSwitch pour l'interpreteur, sinon Dos32SelectSession (session
  enfant) }
Function SwitchSes(S : LongInt) : LongInt;
Var R : LongInt;
Begin
  EnsureReg;
  If S = CurSes Then R := NO_ERROR
  Else
  Begin
    R := DosSMSwitch(S);
    If R = ERROR_SMG_INVALID_CALL Then R := Dos32SelectSession(S);
  End;
  SwitchSes := R;
End;

{ Demarrer une session (STARTDATA PStd) ; son entree est creee a son
  demarrage (SmNotify). PSid <- session. Une session au premier plan
  s'execute aussitot ; l'interpreteur demarre des sessions de premier
  niveau (DosSMStart), les autres processus des sessions enfants. }
Function StartSes(PStd, PSid : LongInt; Title : String; Typ : LongInt) : LongInt;
Var R, S, Pid, I : LongInt;
Begin
  EnsureReg;
  S := 0; Pid := 0;
  PendTitle := Copy(Title, 1, 63);
  PendType := Typ;
  R := DosSMStart(PStd, LongInt(@S), LongInt(@Pid));
  If R = ERROR_SMG_INVALID_CALL Then R := Dos32StartSession(PStd, LongInt(@S), LongInt(@Pid));
  PendTitle := '';
  PendType := 1;
  If (R = NO_ERROR) And (S <> 0) Then
  Begin
    I := SesEntry(S);
    If (I >= 0) And (Pid <> 0) Then EPid[I] := Pid;
  End;
  If R = ERROR_SMG_START_IN_BACKGROUND Then R := PMERR_STARTED_IN_BACKGROUND;
  WrL(PSid, S);
  StartSes := R;
End;

{ STARTDATA de 50 octets }
Procedure BuildSd(Prog, Params, Title : String; Rel, Bg, Typ : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 63 Do Sd[K] := 0;
  WrW(LongInt(@Sd), 50);
  WrW(LongInt(@Sd) + 2, Rel);
  WrW(LongInt(@Sd) + 4, Bg);
  PutZ(LongInt(@Name2), Title);
  PutZ(LongInt(@Name3), Prog);
  PutZ(LongInt(@Name4), Params);
  WrL(LongInt(@Sd) + 8, LongInt(@Name2));
  WrL(LongInt(@Sd) + 12, LongInt(@Name3));
  WrL(LongInt(@Sd) + 16, LongInt(@Name4));
  WrW(LongInt(@Sd) + 30, Typ);
End;

{ Arreter le programme de l'entree I : session en attente arretee,
  session terminee liberee ; une session en cours d'execution (la
  courante ou une parente) ne peut l'etre. Force : l'entree est retiree
  meme si la session ne peut etre arretee. }
Function EndEntry(I : LongInt; Force : Boolean) : LongInt;
Var S, R : LongInt;
Begin
  S := ESes[I];
  R := NO_ERROR;
  If S = 1 Then R := PMERR_INVALID_SESSION_ID           { session de l'interpreteur }
  Else If S = CurSes Then R := PMERR_INVALID_SESSION_ID
  Else
  Begin
    R := DosSMTerminate(S);                                { interpreteur }
    If R = ERROR_SMG_INVALID_CALL Then R := Dos32StopSession(0, S);   { session enfant }
    If (R = NO_ERROR) Or Force Then RemoveSes(S);
    If R <> NO_ERROR Then R := PMERR_INVALID_SESSION_ID;
  End;
  EndEntry := R;
End;

{ ==================================================================== }
{ Partie 6 - Fichier OS2SM.INI                                         }
{ ==================================================================== }

Function IniName(P : LongInt) : String;
Begin
  If (P <> 0) And (GetZ(P) <> '') Then IniName := GetZ(P) Else IniName := IniPath;
End;

{ Lire le fichier dans IoBuf (IoLen) ; faux s'il n'existe pas }
Function ReadIni(Name : String) : Boolean;
Var H, Act, D : LongInt;
Begin
  IoLen := 0;
  PutZ(LongInt(@NameZ), Name);
  If DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) <> NO_ERROR Then
  Begin
    ReadIni := False;
    Exit;
  End;
  D := DcRead(H, LongInt(@IoBuf), 8190, LongInt(@IoLen));
  D := DcClose(H);
  ReadIni := True;
End;

Function WriteIni(Name : String) : LongInt;
Var H, Act, W, R : LongInt;
Begin
  PutZ(LongInt(@NameZ), Name);
  R := DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), 0, 0, $12, $41, 0);
  If R = NO_ERROR Then
  Begin
    R := DcWrite(H, LongInt(@IoBuf), IoLen, LongInt(@W));
    Dummy := DcClose(H);
  End;
  WriteIni := R;
End;

Procedure AddLine(S : String);
Var K : LongInt;
Begin
  S := S + Chr(13) + Chr(10);
  For K := 1 To Length(S) Do
    If IoLen < 8190 Then
    Begin
      IoBuf[IoLen] := Ord(S[K]);
      Inc(IoLen);
    End;
End;

{ Ligne N (a partir de la position P) ; P avance }
Function NextLine(Var P : LongInt) : String;
Var S : String;
Begin
  S := '';
  While (P < IoLen) And (IoBuf[P] <> 10) Do
  Begin
    If (IoBuf[P] <> 13) And (Length(S) < 250) Then S := S + Chr(IoBuf[P]);
    Inc(P);
  End;
  If P < IoLen Then Inc(P);
  NextLine := S;
End;

{ ==================================================================== }
{ Partie 7 - Fonctions                                                 }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  WININITSESSIONMGR(ulReserved) : initialiser le gestionnaire de
  sessions de l'interpreteur : le processus devient le proprietaire du
  gestionnaire (DosSMInitialize) et la session 1 recoit son entree }
Function WinInitSessionMgr(Reserved : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Initialized And (OwnerPid = MyPid) Then
  Begin
    WinInitSessionMgr := 1;
    Exit;
  End;
  EnsureReg;
  R := DosSMInitialize;
  If R <> NO_ERROR Then
  Begin
    WinInitSessionMgr := 0;
    Exit;
  End;
  Initialized := True;
  OwnerPid := MyPid;
  If SesEntry(1) < 0 Then R := AddSesEntry(1, 'Interpreteur de commandes', 1);
  WinInitSessionMgr := 1;
End;

{ ---------------------------------------------------------------------
  WINADDSWITCHENTRY(pswctl) : ajouter une entree a la liste des taches
  (idProcess 0 : le processus appelant ; idSession 0 : la session
  courante) ; rend son handle (0 : erreur) }
Function WinAddSwitchEntry(P : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinAddSwitchEntry := 0;
  If (P = 0) Or Not SwValid(P) Then Exit;
  I := NewEntry;
  If I < 0 Then Exit;
  SwFromCtl(I, P);
  WinAddSwitchEntry := HSw(I);
End;

{ WINCREATESWITCHENTRY(hab, pswctl) : comme WinAddSwitchEntry }
Function WinCreateSwitchEntry(Hab, P : LongInt) : LongInt;
Begin
  WinCreateSwitchEntry := WinAddSwitchEntry(P);
End;

{ ---------------------------------------------------------------------
  WINCHANGESWITCHENTRY(hswitch, pswctl) : changer le titre, la
  visibilite, le saut, les fenetres et le type de l'entree (le processus
  et la session ne changent pas) ; WINSETSWENTRY : changer tous les
  champs }
Function WinChangeSwitchEntry(H, P : LongInt) : LongInt;
Var I, Pid, S : LongInt;
Begin
  I := SwIdx(H);
  If I < 0 Then WinChangeSwitchEntry := PMERR_INVALID_SWITCH_HANDLE
  Else If (P = 0) Or Not SwValid(P) Then WinChangeSwitchEntry := PMERR_PARAMETER_OUT_OF_RANGE
  Else
  Begin
    Pid := EPid[I]; S := ESes[I];
    SwFromCtl(I, P);
    EPid[I] := Pid; ESes[I] := S;
    WinChangeSwitchEntry := NO_ERROR;
  End;
End;

Function WinSetSwEntry(H, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SwIdx(H);
  If I < 0 Then WinSetSwEntry := PMERR_INVALID_SWITCH_HANDLE
  Else If (P = 0) Or Not SwValid(P) Then WinSetSwEntry := PMERR_PARAMETER_OUT_OF_RANGE
  Else
  Begin
    SwFromCtl(I, P);
    WinSetSwEntry := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  WINQUERYSWITCHENTRY(hswitch, pswctl) : lire l'entree (SWCNTRL) }
Function WinQuerySwitchEntry(H, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SwIdx(H);
  If I < 0 Then WinQuerySwitchEntry := PMERR_INVALID_SWITCH_HANDLE
  Else If P = 0 Then WinQuerySwitchEntry := PMERR_PARAMETER_OUT_OF_RANGE
  Else
  Begin
    SwToCtl(I, P);
    WinQuerySwitchEntry := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  WINQUERYSWITCHHANDLE(hwnd, pid) : entree de la fenetre hwnd, ou (hwnd
  = 0) du processus pid (0 : appelant) ; 0 si aucune }
Function WinQuerySwitchHandle(Hwnd, Pid : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  If (Hwnd = 0) And (Pid = 0) Then Pid := MyPid;
  For I := MaxSw - 1 DownTo 0 Do
    If EUsed[I] Then
    Begin
      If (Hwnd <> 0) And (EHwnd[I] = Hwnd) Then R := HSw(I);
      If (Hwnd = 0) And (EPid[I] = Pid) Then R := HSw(I);
    End;
  { programme de la session courante dont l'identificateur n'est pas
    encore connu (il s'execute) }
  If (R = 0) And (Hwnd = 0) And (Pid = MyPid) Then
  Begin
    I := SesEntry(CurSes);
    If (I >= 0) And (EPid[I] = 0) Then
    Begin
      EPid[I] := Pid;
      R := HSw(I);
    End;
  End;
  WinQuerySwitchHandle := R;
End;

{ ---------------------------------------------------------------------
  WINREMOVESWITCHENTRY(hswitch) : retirer l'entree }
Function WinRemoveSwitchEntry(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SwIdx(H);
  If I < 0 Then WinRemoveSwitchEntry := PMERR_INVALID_SWITCH_HANDLE
  Else
  Begin
    FreeEntry(I);
    WinRemoveSwitchEntry := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  WINQUERYSWITCHLIST(hab, pswblk, cbData) : liste des taches (SWBLOCK :
  autant d'entrees que le tampon en contient) ; rend le nombre total
  d'entrees (pswblk = 0 ou cbData = 0 : seulement ce nombre) }
Function WinQuerySwitchList(Hab, PBlk, Cb : LongInt) : LongInt;
Var I, N, Fit : LongInt;
Begin
  N := 0;
  For I := 0 To MaxSw - 1 Do
    If EUsed[I] Then Inc(N);
  If (PBlk <> 0) And (Cb >= 4) Then
  Begin
    Fit := 0;
    For I := 0 To MaxSw - 1 Do
      If EUsed[I] And (4 + (Fit + 1) * 100 <= Cb) Then
      Begin
        WrL(PBlk + 4 + Fit * 100, HSw(I));
        SwToCtl(I, PBlk + 8 + Fit * 100);
        Inc(Fit);
      End;
    WrL(PBlk, Fit);
  End;
  WinQuerySwitchList := N;
End;

{ ---------------------------------------------------------------------
  WINSWITCHTOPROGRAM(hswitch) : passer au programme de l'entree (sa
  session passe au premier plan ; en attente, elle s'execute) ;
  WINSWITCHTOPROGRAM2(hswitch, fl) : idem, fl 0 a 3 (normal,
  restaurer, agrandir, reduire) }
Function WinSwitchToProgram(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  I := SwIdx(H);
  If I < 0 Then WinSwitchToProgram := PMERR_INVALID_SWITCH_HANDLE
  Else
  Begin
    R := SwitchSes(ESes[I]);
    If R <> NO_ERROR Then R := PMERR_INVALID_SESSION_ID;
    WinSwitchToProgram := R;
  End;
End;

Function WinSwitchToProgram2(H, Fl : LongInt) : LongInt;
Begin
  If (Fl < 0) Or (Fl > 3) Then WinSwitchToProgram2 := PMERR_PARAMETER_OUT_OF_RANGE
  Else WinSwitchToProgram2 := WinSwitchToProgram(H);
End;

{ WINSWITCHTOTASKMANAGER : passer a la liste des taches (session 1) }
Function WinSwitchToTaskManager : LongInt;
Begin
  WinSwitchToTaskManager := SwitchSes(1);
End;

{ WINSETFGNDWINDOW(hwnd) : la fenetre passe au premier plan (BOOL) }
Function WinSetFgndWindow(Hwnd : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := 0;
  If Hwnd <> 0 Then H := WinQuerySwitchHandle(Hwnd, 0);
  If H = 0 Then WinSetFgndWindow := 0
  Else If WinSwitchToProgram(H) = NO_ERROR Then WinSetFgndWindow := 1
  Else WinSetFgndWindow := 0;
End;

{ ---------------------------------------------------------------------
  WINPROCESSHOTKEY(chScan, fsState) : raccourcis de l'interpreteur :
  Ctrl+Echap (liste des taches), Alt+Echap ou Alt+Tab (programme
  accessible suivant) ; rend 1 si la touche est traitee }
Function WinProcessHotKey(Scan, State : LongInt) : LongInt;
Var I, K, Cur, R : LongInt;
Begin
  R := 0;
  If (Scan = $01) And ((State And $0004) <> 0) Then
  Begin
    K := WinSwitchToTaskManager;
    R := 1;
  End
  Else If ((Scan = $01) Or (Scan = $0F)) And ((State And $0008) <> 0) Then
  Begin
    Cur := SesEntry(CurSes);
    For I := 1 To MaxSw Do
      If R = 0 Then
      Begin
        K := (Cur + I + MaxSw) Mod MaxSw;
        If EUsed[K] And (EJump[K] = SWL_JUMPABLE) And (ESes[K] <> CurSes) And (EVis[K] <> SWL_INVISIBLE) Then
        Begin
          If WinSwitchToProgram(HSw(K)) = NO_ERROR Then R := 1;
        End;
      End;
    R := 1;
  End;
  WinProcessHotKey := R;
End;

{ ---------------------------------------------------------------------
  WINQUERYTASKTITLE(idSession, pszTitle, cbTitle) : titre de la tache
  (session 0 : la courante) ; WINQUERYSESSIONTITLE(hab, idSession,
  pszTitle, cbTitle) : idem }
Function WinQueryTaskTitle(S, PTitle, Cb : LongInt) : LongInt;
Var I : LongInt;
Begin
  If S = 0 Then S := CurSes;
  I := SesEntry(S);
  If I < 0 Then WinQueryTaskTitle := PMERR_INVALID_SESSION_ID
  Else If (PTitle = 0) Or (Cb <= 0) Then WinQueryTaskTitle := PMERR_PARAMETER_OUT_OF_RANGE
  Else
  Begin
    PutTitle(PTitle, Cb, ETitle[I]);
    WinQueryTaskTitle := NO_ERROR;
  End;
End;

Function WinQuerySessionTitle(Hab, S, PTitle, Cb : LongInt) : LongInt;
Begin
  WinQuerySessionTitle := WinQueryTaskTitle(S, PTitle, Cb);
End;

{ ---------------------------------------------------------------------
  WINQUERYTASKSIZEPOS(hab, idSession, pswp) : taille et position de la
  tache (SWP ; ecran texte de 80 x 25 en cellules de 8 x 16 : 640 x 400) }
Function WinQueryTaskSizePos(Hab, S, P : LongInt) : LongInt;
Var I, K : LongInt;
Begin
  If S = 0 Then S := CurSes;
  I := SesEntry(S);
  If I < 0 Then WinQueryTaskSizePos := PMERR_INVALID_SESSION_ID
  Else If P = 0 Then WinQueryTaskSizePos := PMERR_PARAMETER_OUT_OF_RANGE
  Else
  Begin
    For K := 0 To 35 Do WrB(P + K, 0);
    WrL(P, $000B);                         { SWP_SIZE, SWP_MOVE, SWP_SHOW }
    WrL(P + 4, 400);
    WrL(P + 8, 640);
    WrL(P + 20, 3);                        { HWND_TOP }
    WrL(P + 24, EHwnd[I]);
    WinQueryTaskSizePos := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  WINSETTITLE(pszTitle) : titre de la session courante (liste des taches
  et SESMGR) ; BOOL }
Function WinSetTitle(PTitle : LongInt) : LongInt;
Var I : LongInt;
Begin
  If PTitle = 0 Then
  Begin
    WinSetTitle := 0;
    Exit;
  End;
  I := SesEntry(CurSes);
  If I < 0 Then I := AddSesEntry(CurSes, '', 1);
  If I >= 0 Then ETitle[I] := Copy(GetZ(PTitle), 1, 63);
  Dummy := DosSMSetTitle(PTitle);
  If I >= 0 Then WinSetTitle := 1 Else WinSetTitle := 0;
End;

{ ---------------------------------------------------------------------
  WININITSESSION(idSession, pszTitle) : entree de la session (creee si
  besoin) ; rend son handle. WINENDSESSION(idSession) : retirer les
  entrees de la session. WININITSWENTRY(pswctl) : SWCNTRL par defaut
  (processus et session courants, visible, accessible, titre de la
  session) ; BOOL }
Function WinInitSession(S, PTitle : LongInt) : LongInt;
Var I : LongInt;
Begin
  If S = 0 Then S := CurSes;
  I := SesEntry(S);
  If I < 0 Then I := AddSesEntry(S, GetZ(PTitle), 1)
  Else If GetZ(PTitle) <> '' Then ETitle[I] := Copy(GetZ(PTitle), 1, 63);
  If I < 0 Then WinInitSession := 0 Else WinInitSession := HSw(I);
End;

Function WinEndSession(S : LongInt) : LongInt;
Begin
  If SesEntry(S) < 0 Then WinEndSession := PMERR_INVALID_SESSION_ID
  Else
  Begin
    RemoveSes(S);
    WinEndSession := NO_ERROR;
  End;
End;

Function WinInitSwEntry(P : LongInt) : LongInt;
Var K, I : LongInt;
Begin
  If P = 0 Then
  Begin
    WinInitSwEntry := 0;
    Exit;
  End;
  For K := 0 To 95 Do WrB(P + K, 0);
  WrL(P + 12, MyPid);
  WrL(P + 16, CurSes);
  WrL(P + 20, SWL_VISIBLE);
  WrL(P + 24, SWL_JUMPABLE);
  I := SesEntry(CurSes);
  If I >= 0 Then PutZ(P + 28, ETitle[I]);
  WinInitSwEntry := 1;
End;

{ ---------------------------------------------------------------------
  WININSTSTARTAPP(hwndNotify, pDetails, pszParams, pReserved, fbOptions)
  : demarrer un programme (PROGDETAILS) dans une session et l'ajouter a
  la liste des taches ; rend son HAPP (0 : echec). fbOptions :
  SAF_INSTALLEDCMDLINE (parametres de PROGDETAILS), SAF_STARTCHILDAPP
  (session enfant), SAF_BACKGROUND. WINTERMINATEAPP(happ) : arreter ce
  programme (BOOL). }
Function WinInstStartApp(HNotify, PDet, PParams, PRes, Opt : LongInt) : LongInt;
Var Prog, Prm, T : String; Typ, R, S, Rel, Bg : LongInt;
Begin
  WinInstStartApp := 0;
  If (PDet = 0) Or (RdL(PDet) < 36) Then Exit;
  Typ := RdL(PDet + 4);
  If Typ = PROG_PM Then Exit;                { Presentation Manager absent }
  Prog := GetZ(RdL(PDet + 16));
  If (Opt And SAF_INSTALLEDCMDLINE) <> 0 Then Prm := GetZ(RdL(PDet + 20)) Else Prm := GetZ(PParams);
  T := GetZ(RdL(PDet + 12));
  If T = '' Then T := UpStr(BaseName(Prog));
  If (Opt And SAF_STARTCHILDAPP) <> 0 Then Rel := 1 Else Rel := 0;
  If (Opt And SAF_BACKGROUND) <> 0 Then Bg := 1 Else Bg := 0;
  If Typ > 2 Then Typ := 0;
  BuildSd(Prog, Prm, T, Rel, Bg, Typ);
  R := StartSes(LongInt(@Sd), LongInt(@S), T, Typ);
  If ((R = NO_ERROR) Or (R = PMERR_STARTED_IN_BACKGROUND)) And (S <> 0) Then
    WinInstStartApp := HappBase + S;
End;

Function WinTerminateApp(Happ : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SesEntry(Happ - HappBase);
  If (Happ <= HappBase) Or (I < 0) Then WinTerminateApp := 0
  Else If EndEntry(I, True) = NO_ERROR Then WinTerminateApp := 1
  Else WinTerminateApp := 0;
End;

{ ---------------------------------------------------------------------
  SHESTARTPROGRAM(pStartData, pidSession) : l'interpreteur demarre un
  programme (STARTDATA de SESMGR) et l'ajoute a la liste des taches ;
  SHESTARTLONGPROGRAM(pszProgram, pszParams, pszTitle, fBackground,
  pidSession) : idem a partir des chaines (parametres de 255 caracteres
  au plus) }
Function SheStartProgram(PStd, PSid : LongInt) : LongInt;
Var T : String;
Begin
  If PStd = 0 Then
  Begin
    SheStartProgram := PMERR_PARAMETER_OUT_OF_RANGE;
    Exit;
  End;
  T := GetZ(RdL(PStd + 8));
  If T = '' Then T := UpStr(BaseName(GetZ(RdL(PStd + 12))));
  SheStartProgram := StartSes(PStd, PSid, T, 1);
End;

Function SheStartLongProgram(PProg, PParams, PTitle, Bg, PSid : LongInt) : LongInt;
Var T : String;
Begin
  If PProg = 0 Then
  Begin
    SheStartLongProgram := PMERR_PARAMETER_OUT_OF_RANGE;
    Exit;
  End;
  T := GetZ(PTitle);
  If T = '' Then T := UpStr(BaseName(GetZ(PProg)));
  If Bg <> 0 Then Bg := 1;
  BuildSd(GetZ(PProg), GetZ(PParams), T, 0, Bg, 0);
  SheStartLongProgram := StartSes(LongInt(@Sd), PSid, T, 1);
End;

{ ---------------------------------------------------------------------
  WINEXECPROGRAM(pszProgram, pszParams, pulResult) : executer un
  programme dans la session courante et attendre sa fin (DosExecPgm) ;
  *pulResult <- son code de fin }
Function WinExecProgram(PProg, PParams, PResult : LongInt) : LongInt;
Var N, R : LongInt; P : String;
Begin
  If PProg = 0 Then
  Begin
    WinExecProgram := PMERR_PARAMETER_OUT_OF_RANGE;
    Exit;
  End;
  P := GetZ(PProg);
  PutZ(LongInt(@Name3), BaseName(P));
  N := Length(BaseName(P)) + 1;
  PutZ(LongInt(@Name3) + N, GetZ(PParams));
  N := N + Length(GetZ(PParams)) + 1;
  WrB(LongInt(@Name3) + N, 0);
  PutZ(LongInt(@NameZ), P);
  Res[0] := 0; Res[1] := 0;
  R := DcExecPgm(LongInt(@Name4), 64, 0, LongInt(@Name3), 0, LongInt(@Res), LongInt(@NameZ));
  WrL(PResult, Res[1]);
  WinExecProgram := R;
End;

{ ---------------------------------------------------------------------
  WINENDPROGRAM(hswitch) : fermer le programme de l'entree (session en
  attente arretee, session terminee liberee ; l'entree est retiree) ;
  WINSTOPPROGRAM(hswitch) : arret force ; WINENDWINDOWSESSION(hswitch) :
  fin de la session de la fenetre (entree et session) }
Function WinEndProgram(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SwIdx(H);
  If I < 0 Then WinEndProgram := PMERR_INVALID_SWITCH_HANDLE
  Else WinEndProgram := EndEntry(I, False);
End;

Function WinStopProgram(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SwIdx(H);
  If I < 0 Then WinStopProgram := PMERR_INVALID_SWITCH_HANDLE
  Else WinStopProgram := EndEntry(I, True);
End;

Function WinEndWindowSession(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SwIdx(H);
  If I < 0 Then WinEndWindowSession := PMERR_INVALID_SWITCH_HANDLE
  Else WinEndWindowSession := EndEntry(I, True);
End;

{ ---------------------------------------------------------------------
  WINQUERYEXTIDFOCUS(pidFocus), WINSETEXTIDFOCUS(idFocus) : session ayant
  le focus du clavier etendu (fenetres VIO) }
Function WinQueryExtIdFocus(PId : LongInt) : LongInt;
Begin
  If PId = 0 Then WinQueryExtIdFocus := PMERR_PARAMETER_OUT_OF_RANGE
  Else
  Begin
    If ExtFocus = 0 Then WrL(PId, CurSes) Else WrL(PId, ExtFocus);
    WinQueryExtIdFocus := NO_ERROR;
  End;
End;

Function WinSetExtIdFocus(Id : LongInt) : LongInt;
Begin
  If (Id <> 0) And (SesEntry(Id) < 0) Then WinSetExtIdFocus := PMERR_INVALID_SESSION_ID
  Else
  Begin
    ExtFocus := Id;
    WinSetExtIdFocus := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  Inscriptions (BOOL) : WINSTPREGISTER(hwnd) fenetre du programme de
  demarrage, WINSWITCHPROGRAMREGISTER(hwnd) fenetre avertie des
  changements de programme, WINCPLREGISTER(pszModule) module du panneau
  de configuration, WINPMFILEREGISTER(pszFile) fichier du gestionnaire
  de programmes }
Function RegHwnd(Base, Hwnd : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxReg - 1 DownTo 0 Do
    If RegH[Base + I] = Hwnd Then F := I;
  If F < 0 Then
    For I := MaxReg - 1 DownTo 0 Do
      If RegH[Base + I] = 0 Then F := I;
  If (F < 0) Or (Hwnd = 0) Then RegHwnd := 0
  Else
  Begin
    RegH[Base + F] := Hwnd;
    RegHwnd := 1;
  End;
End;

Function WinStpRegister(Hwnd : LongInt) : LongInt;
Begin
  WinStpRegister := RegHwnd(0, Hwnd);
End;

Function WinSwitchProgramRegister(Hwnd : LongInt) : LongInt;
Begin
  WinSwitchProgramRegister := RegHwnd(MaxReg, Hwnd);
End;

Function WinCplRegister(PName : LongInt) : LongInt;
Var I, F : LongInt; N : String;
Begin
  N := UpStr(GetZ(PName));
  F := -1;
  If N <> '' Then
  Begin
    For I := 0 To MaxReg - 1 Do
      If CplName[I] = N Then F := I;
    If F < 0 Then
      For I := MaxReg - 1 DownTo 0 Do
        If CplName[I] = '' Then F := I;
  End;
  If F < 0 Then WinCplRegister := 0
  Else
  Begin
    CplName[F] := Copy(N, 1, 63);
    WinCplRegister := 1;
  End;
End;

Function WinPMFileRegister(PName : LongInt) : LongInt;
Var I, F : LongInt; N : String;
Begin
  N := UpStr(GetZ(PName));
  F := -1;
  If N <> '' Then
  Begin
    For I := 0 To MaxReg - 1 Do
      If PmfName[I] = N Then F := I;
    If F < 0 Then
      For I := MaxReg - 1 DownTo 0 Do
        If PmfName[I] = '' Then F := I;
  End;
  If F < 0 Then WinPMFileRegister := 0
  Else
  Begin
    PmfName[F] := Copy(N, 1, 63);
    WinPMFileRegister := 1;
  End;
End;

{ ---------------------------------------------------------------------
  SHEINITIALIZEINIFILE(pszIniFile) : fichier de l'interpreteur (0 :
  C:\OS2SM.INI) cree avec ses sections s'il n'existe pas ; il devient le
  fichier courant }
Function SheInitializeIniFile(PIni : LongInt) : LongInt;
Var N : String;
Begin
  N := IniName(PIni);
  IniPath := Copy(N, 1, 127);
  If ReadIni(N) Then SheInitializeIniFile := NO_ERROR
  Else
  Begin
    IoLen := 0;
    AddLine('; ' + BaseName(N) + ' : interpreteur de commandes d''OS/2-0 (OS2SM.DLL)');
    AddLine('[Demarrage]');
    AddLine('; RUN=programme parametres');
    AddLine('[Polices]');
    AddLine('; FONT=fichier');
    AddLine('[Bureau]');
    SheInitializeIniFile := WriteIni(N);
  End;
End;

{ ---------------------------------------------------------------------
  STARTSYSTEMEXECUTABLES(pszIniFile) : demarrer, en arriere-plan, les
  programmes des lignes RUN= du fichier (0 : courant) ; rend leur nombre }
Function StartSystemExecutables(PIni : LongInt) : LongInt;
Var P, N, K, S, R : LongInt; L, Prog, Prm : String;
Begin
  N := 0;
  If ReadIni(IniName(PIni)) Then
  Begin
    P := 0;
    While P < IoLen Do
    Begin
      L := NextLine(P);
      If UpStr(Copy(L, 1, 4)) = 'RUN=' Then
      Begin
        L := Copy(L, 5, 255);
        K := Pos(' ', L);
        If K = 0 Then
        Begin
          Prog := L; Prm := '';
        End
        Else
        Begin
          Prog := Copy(L, 1, K - 1); Prm := Copy(L, K + 1, 255);
        End;
        BuildSd(Prog, Prm, UpStr(BaseName(Prog)), 0, 1, 0);
        R := StartSes(LongInt(@Sd), LongInt(@S), UpStr(BaseName(Prog)), 1);
        If (R = NO_ERROR) Or (R = PMERR_STARTED_IN_BACKGROUND) Then Inc(N);
      End;
    End;
  End;
  StartSystemExecutables := N;
End;

{ ---------------------------------------------------------------------
  SHLLOADPUBLICFONTS(pszIniFile) : polices publiques des lignes FONT= du
  fichier (celles qui existent) ; rend leur nombre.
  SHLUNLOADPUBLICFONTS : les retirer ; rend leur nombre. }
Function ShlLoadPublicFonts(PIni : LongInt) : LongInt;
Var P : LongInt; L : String;
Begin
  FontCount := 0;
  If ReadIni(IniName(PIni)) Then
  Begin
    P := 0;
    While P < IoLen Do
    Begin
      L := NextLine(P);
      If (UpStr(Copy(L, 1, 5)) = 'FONT=') And (FontCount < MaxFont) Then
      Begin
        L := Copy(L, 6, 255);
        PutZ(LongInt(@NameZ), L);
        If DcQueryPathInfo(LongInt(@NameZ), 1, LongInt(@Info), 24) = NO_ERROR Then
        Begin
          FontName[FontCount] := Copy(UpStr(L), 1, 63);
          Inc(FontCount);
        End;
      End;
    End;
  End;
  ShlLoadPublicFonts := FontCount;
End;

Function ShlUnloadPublicFonts : LongInt;
Begin
  ShlUnloadPublicFonts := FontCount;
  FontCount := 0;
End;

{ ---------------------------------------------------------------------
  WINSAVE(pszIniFile) : ecrire le bureau (titres de la liste des taches)
  dans la section [Bureau] du fichier (0 : courant) }
Function WinSave(PIni : LongInt) : LongInt;
Var P, Q, I : LongInt; N, L : String; Found : Boolean;
Begin
  N := IniName(PIni);
  If Not ReadIni(N) Then IoLen := 0;
  { garder ce qui precede [Bureau] }
  P := 0; Found := False;
  While (P < IoLen) And Not Found Do
  Begin
    Q := P;
    L := NextLine(P);
    If UpStr(L) = '[BUREAU]' Then
    Begin
      Found := True;
      IoLen := Q;
    End;
  End;
  AddLine('[Bureau]');
  For I := 0 To MaxSw - 1 Do
    If EUsed[I] Then AddLine('ENTRY=' + ETitle[I]);
  WinSave := WriteIni(N);
End;

{ ---------------------------------------------------------------------
  WINNOSHUTDOWN(fBlock) : empecher (1) ou permettre (0) l'arret du
  systeme ; rend l'etat precedent.
  SHESYSTEMSHUTDOWN(fl) : arret du systeme par l'interpreteur : bureau
  sauve (WinSave), tampons des fichiers vides (DosShutdown) ; BOOL (0 si
  l'arret est empeche) }
Function WinNoShutdown(Block : LongInt) : LongInt;
Begin
  If NoShut Then WinNoShutdown := 1 Else WinNoShutdown := 0;
  NoShut := Block <> 0;
End;

Function SheSystemShutdown(Fl : LongInt) : LongInt;
Begin
  If NoShut Then SheSystemShutdown := 0
  Else
  Begin
    Dummy := WinSave(0);
    Dummy := DcShutdown(0);
    ShutDone := True;
    SheSystemShutdown := 1;
  End;
End;

{ ---------------------------------------------------------------------
  Procedures de fenetre (hwnd, msg, mp1, mp2) : leur adresse est le
  pointeur exporte.
  LPFNSHELLWNDPROC : fenetre de l'interpreteur (WM_CLOSE refuse,
  WM_COMMAND 1 : liste des taches).
  LPFNICONWNDPROC : icone d'un programme (WM_BUTTON1DBLCLK : passer au
  programme dont l'icone est hwnd).
  FNBADAPPDLGPROC : dialogue d'un programme defaillant (WM_COMMAND :
  rend le bouton choisi, DID_OK 1 arrete le programme de la session
  courante a sa fin) }
Function ShellWndProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If (Msg = WM_COMMAND) And ((Mp1 And $FFFF) = 1) Then R := WinSwitchToTaskManager;
  ShellWndProc := R;
End;

Function IconWndProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  If Msg = WM_BUTTON1DBLCLK Then
    For I := 0 To MaxSw - 1 Do
      If EUsed[I] And (EIcon[I] = Hwnd) And (Hwnd <> 0) And (R = 0) Then
        If WinSwitchToProgram(HSw(I)) = NO_ERROR Then R := 1;
  IconWndProc := R;
End;

Function BadAppDlgProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  If Msg = WM_COMMAND Then BadAppDlgProc := Mp1 And $FFFF
  Else BadAppDlgProc := 0;
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  WinInitSessionMgr Index 1 Name 'WININITSESSIONMGR',
  WinSetFgndWindow Index 2 Name 'WINSETFGNDWINDOW',
  ShlUnloadPublicFonts Index 3 Name 'SHLUNLOADPUBLICFONTS',
  WinStpRegister Index 4 Name 'WINSTPREGISTER',
  WinInstStartApp Index 5 Name 'WININSTSTARTAPP',
  WinTerminateApp Index 6 Name 'WINTERMINATEAPP',
  WinCreateSwitchEntry Index 7 Name 'WINCREATESWITCHENTRY',
  WinQuerySessionTitle Index 8 Name 'WINQUERYSESSIONTITLE',
  WinAddSwitchEntry Index 9 Name 'WINADDSWITCHENTRY',
  WinChangeSwitchEntry Index 10 Name 'WINCHANGESWITCHENTRY',
  WinQuerySwitchEntry Index 11 Name 'WINQUERYSWITCHENTRY',
  WinQuerySwitchHandle Index 12 Name 'WINQUERYSWITCHHANDLE',
  WinQueryTaskTitle Index 13 Name 'WINQUERYTASKTITLE',
  WinQueryTaskSizePos Index 14 Name 'WINQUERYTASKSIZEPOS',
  WinQuerySwitchList Index 15 Name 'WINQUERYSWITCHLIST',
  WinRemoveSwitchEntry Index 16 Name 'WINREMOVESWITCHENTRY',
  WinSwitchToProgram Index 17 Name 'WINSWITCHTOPROGRAM',
  WinSwitchProgramRegister Index 18 Name 'WINSWITCHPROGRAMREGISTER',
  WinExecProgram Index 19 Name 'WINEXECPROGRAM',
  SheStartProgram Index 20 Name 'SHESTARTPROGRAM',
  WinEndProgram Index 21 Name 'WINENDPROGRAM',
  WinStopProgram Index 22 Name 'WINSTOPPROGRAM',
  WinEndWindowSession Index 23 Name 'WINENDWINDOWSESSION',
  ShellWndProc Index 24 Name 'LPFNSHELLWNDPROC',
  IconWndProc Index 25 Name 'LPFNICONWNDPROC',
  WinSwitchToTaskManager Index 26 Name 'WINSWITCHTOTASKMANAGER',
  BadAppDlgProc Index 27 Name 'FNBADAPPDLGPROC',
  WinSwitchToProgram2 Index 28 Name 'WINSWITCHTOPROGRAM2',
  WinProcessHotKey Index 29 Name 'WINPROCESSHOTKEY',
  WinSave Index 30 Name 'WINSAVE',
  WinInitSession Index 31 Name 'WININITSESSION',
  WinEndSession Index 32 Name 'WINENDSESSION',
  WinInitSwEntry Index 33 Name 'WININITSWENTRY',
  WinSetSwEntry Index 34 Name 'WINSETSWENTRY',
  WinQueryExtIdFocus Index 35 Name 'WINQUERYEXTIDFOCUS',
  WinSetExtIdFocus Index 36 Name 'WINSETEXTIDFOCUS',
  SheSystemShutdown Index 37 Name 'SHESYSTEMSHUTDOWN',
  StartSystemExecutables Index 38 Name 'STARTSYSTEMEXECUTABLES',
  ShlLoadPublicFonts Index 39 Name 'SHLLOADPUBLICFONTS',
  WinNoShutdown Index 40 Name 'WINNOSHUTDOWN',
  SheInitializeIniFile Index 41 Name 'SHEINITIALIZEINIFILE',
  WinSetTitle Index 42 Name 'WINSETTITLE',
  WinCplRegister Index 43 Name 'WINCPLREGISTER',
  WinPMFileRegister Index 44 Name 'WINPMFILEREGISTER',
  SheStartLongProgram Index 45 Name 'SHESTARTLONGPROGRAM',
  SHELLWINDOW Index 103,
  SmNotify Index 200 Name 'OS2SMNOTIFY';

Var
  InitI : LongInt;

BEGIN
  For InitI := 0 To MaxSw - 1 Do
  Begin
    EUsed[InitI] := False;
    EGen[InitI] := 1;
  End;
  For InitI := 0 To MaxReg - 1 Do
  Begin
    RegH[InitI] := 0; RegH[MaxReg + InitI] := 0;
    CplName[InitI] := ''; PmfName[InitI] := '';
  End;
  CurSes := 1;
  Initialized := False;
  OwnerPid := 0;
  ExtFocus := 0;
  NoShut := False;
  ShutDone := False;
  FontCount := 0;
  Regd := False;
  PendTitle := '';
  PendType := 1;
  IniPath := DefIni;
END.
