{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: TASKMGR - Gestionnaire des taches du Presentation
                Manager d'OS/2-0 (applications, processus, performances,
                reseau, utilisateurs).
}

Program TASKMGR;

{$R-,S-,I-}

{ Compilation : OS2PC TASKMGR.PAS   (produit TASKMGR.EXE)

  Le Gestionnaire des taches : la presentation et les fonctions du
  Gestionnaire des taches de Windows XP, avec l'apparence d'OS/2 Warp 3
  (fond gris, reliefs, onglets de carnet). L'OS/2 d'origine n'en avait
  pas : seule la Liste des fenetres (Ctrl+Echap) permettait de passer
  d'un programme a l'autre. Cinq onglets :

    Applications  fenetres principales des programmes et sessions plein
                  ecran ; Fin de tache (WM_CLOSE), Basculer vers,
                  Nouvelle tache (lancer un programme) ;
    Processus     processus en cours (nom, PID, utilisation du
                  processeur, memoire, fils, session, type) tries par
                  colonne ; Terminer le processus (DosKillProcess) ;
    Performances  jauges et historiques de l'utilisation du processeur
                  (temps du noyau en rouge, option) et de la memoire ;
                  totaux (handles, fils, processus), memoire physique,
                  charge dediee et memoire du noyau ;
    Reseau        historique des trames de l'interface lan0 (TCPIP32.DLL)
                  et etat de la carte ;
    Utilisateurs  sessions de l'utilisateur (premier plan, arriere-plan) ;
                  Basculer vers, Fermer la session.

  Les chiffres viennent du noyau (KrnTaskCtl 34 : etat du systeme, temps
  inactif et temps du noyau comptes par la minuterie ; KrnTaskCtl 35 :
  processus), des sessions (KrnSesCtl 7) et de PMWIN (fenetres).
  Clavier : F5 actualiser, Suppr terminer, fleches, Ctrl+Tab onglet
  suivant, F1 aide. }

Const
  WM_CREATE = $0001; WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024;
  WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_BUTTON1DBLCLK = $0073; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $200; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80; SWP_RESTORE = $1000;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_CHECKED = $2000; MM_SETITEMATTR = $0192; FID_MENU = $8005;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_WARNING = $20; MB_ERROR = $40; MB_MOVEABLE = $4000;
  MBID_YES = 6;
  KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_KEYUP = $40;
  VK_TAB = $06; VK_NEWLINE = $08; VK_ESC = $0F; VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14;
  VK_UP = $16; VK_DOWN = $18; VK_DELETE = $1B; VK_ENTER = $1E; VK_F1 = $20; VK_F5 = $24;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000;
  WC_BUTTON = $FFFF0003; WC_ENTRYFIELD = $FFFF0006;
  BS_PUSHBUTTON = 0; BS_DEFAULT = $0400; ES_AUTOSCROLL = 4; ES_MARGIN = 8; EM_SETTEXTLIMIT = $0143;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_GREEN = 4; CLR_CYAN = 5; CLR_YELLOW = 6;
  CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12; CLR_DARKCYAN = 13; CLR_BROWN = 14;
  CLR_PALEGRAY = 15;
  DRO_OUTLINE = 2;
  { commandes }
  CM_NEWTASK = 101; CM_QUIT = 102; CM_REFRESH = 111; CM_SPHIGH = 112; CM_SPNORM = 113; CM_SPLOW = 114;
  CM_SPPAUSE = 115; CM_KERNEL = 121; CM_HELP = 201; CM_ABOUT = 202;
  ID_OK = 1; ID_CANCEL = 2; ID_EF = 10;
  { onglets }
  TB_APPS = 0; TB_PROCS = 1; TB_PERF = 2; TB_NET = 3; TB_USERS = 4; NTAB = 5;
  TABH = 22; STATH = 20; ROWH = 16; HDRH = 18; BTNW = 150; BTNH = 24;
  MAXP = 72; MAXA = 64; MAXS = 32; HISTN = 240;
  { colonnes de l'onglet Processus }
  NPCOL = 6;

Type
  PLong = ^LongInt;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps, MenuHw : LongInt;
  Tab, Interval, Paused, KernOn : LongInt;
  NameZ, NameZ2, TxtBuf, FailBuf, ArgBuf : Array[0..511] Of Byte;
  ExeBuf : Array[0..16383] Of Byte;
  MenuT : Array[0..2047] Of Byte;
  MenuLen : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  { etat du systeme (KrnTaskCtl 34) }
  SysI : Array[0..15] Of LongInt;
  LastT, LastIdle, LastKrn, LastSys, SysPct : LongInt;
  CpuPct, KrnPct, MemUsedKb, MemPeakKb, LimitKb, AvailKb : LongInt;
  CpuH, KrnH, MemH, NetH : Array[0..HISTN - 1] Of LongInt;
  HistCount, GridOff : LongInt;
  { processus }
  PB : Array[0..63] Of LongInt;
  NP : LongInt;
  PSer, PThr, PMem, PSes, PFlg, PPct, PCpuT : Array[0..MAXP - 1] Of LongInt;
  PName : Array[0..MAXP - 1] Of String[40];
  Ord_ : Array[0..MAXP - 1] Of LongInt;
  OldSer, OldCpu : Array[0..MAXP - 1] Of LongInt;
  SortCol, SortDesc : LongInt;
  { applications }
  NA : LongInt;
  AHw, ASes : Array[0..MAXA - 1] Of LongInt;
  ATitle : Array[0..MAXA - 1] Of String[60];
  { sessions }
  NS : LongInt;
  SNo, SFg, SMode, SProcs : Array[0..MAXS - 1] Of LongInt;
  STitle : Array[0..MAXS - 1] Of String[48];
  SesInfo : Array[0..31] Of LongInt;
  { selection et defilement de chaque liste (Applications, Processus,
    Utilisateurs) ; cle de la ligne choisie pour la retrouver }
  Sel, Top, SelKey : Array[0..NTAB - 1] Of LongInt;
  { couleurs RGB (ecran de plus de 16 couleurs : -1 inconnu, 0 non, 1 oui) }
  RgbOk : LongInt;
  { reseau (TCPIP32.DLL, TCPIPINFO) }
  NetOn, NetFn, NetLastPk, NetPkS, NetMax : LongInt;
  NetInfo : Array[0..15] Of LongInt;
  NetTxt : Array[0..255] Of Byte;
  NetCard : String;
  { fenetre Nouvelle tache }
  InFr, InCl, InEf : LongInt;

Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinBeginEnumWindows(H : LongInt) : LongInt; External 'PMWIN';
Function WinGetNextWindow(He : LongInt) : LongInt; External 'PMWIN';
Function WinEndEnumWindows(He : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClassName(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindowVisible(H : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiCreateLogColorTable(Hps, Opt, Fmt, St, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryColorData(Hps, N, P : LongInt) : LongInt; External 'PMGPI';
Function DosLoadModule(PObj, Cb, PName, PH : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(P, Lev, Buf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosKillProcess(Action, Pid : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryAppType(PName, PFl : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function KTask(Op, P1, P2, P3 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnTaskCtl';
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Function RdB(A : LongInt) : LongInt;
Type PB_ = ^Byte;
Var Q : PB_;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrB(A, V : LongInt);
Type PB_ = ^Byte;
Var Q : PB_;
Begin
  Q := Pointer(A);
  Q^ := V And 255;
End;

Function RdL(A : LongInt) : LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  RdL := Q^;
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
  While (K < 255) And (RdB(A + K) <> 0) Do
  Begin
    S := S + Chr(RdB(A + K));
    Inc(K);
  End;
  GetZ := S;
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@NameZ), S);
  Z := LongInt(@NameZ);
End;

Function Z2(S : String) : LongInt;
Begin
  PutZ(LongInt(@NameZ2), S);
  Z2 := LongInt(@NameZ2);
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

{ nombre avec separateur des milliers (espace) }
Function NStr(V : LongInt) : String;
Var S, R : String; K, N : LongInt;
Begin
  Str(V, S);
  R := '';
  N := 0;
  For K := Length(S) DownTo 1 Do
  Begin
    If (N > 0) And (N Mod 3 = 0) And (S[K] <> '-') Then R := ' ' + R;
    R := S[K] + R;
    Inc(N);
  End;
  NStr := R;
End;

Function Lo16(V : LongInt) : LongInt;
Begin
  Lo16 := V And $FFFF;
End;

Function Hi16(V : LongInt) : LongInt;
Begin
  Hi16 := (V Shr 16) And $FFFF;
End;

Function S16(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V >= $8000 Then V := V - $10000;
  S16 := V;
End;

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'a') And (S[K] <= 'z') Then S[K] := Chr(Ord(S[K]) - 32);
  UpStr := S;
End;

Function FileExists(S : String) : Boolean;
Var B : Array[0..63] Of Byte;
Begin
  FileExists := DosQueryPathInfo(Z(S), 1, LongInt(@B), 64) = 0;
End;

Function GetEnvS(N : String) : String;
Var P : LongInt;
Begin
  P := 0;
  If DosScanEnv(Z(N), LongInt(@P)) = 0 Then GetEnvS := GetZ(P) Else GetEnvS := '';
End;

Function CallPtr1(F, A1 : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  asm
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,4
    mov R,eax
  end;
  CallPtr1 := R;
End;

{ ==================================================================== }
{ Mesures                                                               }
{ ==================================================================== }

{ historiques : 0 processeur, 1 noyau, 2 memoire, 3 reseau }
Procedure AddHist(W, V : LongInt);
Var K : LongInt;
Begin
  For K := 0 To HISTN - 2 Do
    Case W Of
      0 : CpuH[K] := CpuH[K + 1];
      1 : KrnH[K] := KrnH[K + 1];
      2 : MemH[K] := MemH[K + 1];
    Else
      NetH[K] := NetH[K + 1];
    End;
  Case W Of
    0 : CpuH[HISTN - 1] := V;
    1 : KrnH[HISTN - 1] := V;
    2 : MemH[HISTN - 1] := V;
  Else
    NetH[HISTN - 1] := V;
  End;
End;

Function HistAt(W, K : LongInt) : LongInt;
Begin
  Case W Of
    0 : HistAt := CpuH[K];
    1 : HistAt := KrnH[K];
    2 : HistAt := MemH[K];
  Else
    HistAt := NetH[K];
  End;
End;

{ processus (KrnTaskCtl 35) et pourcentage du processeur depuis la
  mesure precedente (Dt tops) }
Procedure ScanProcs(Dt : LongInt);
Var K, D, Ser, Cpu : LongInt; Nm : String;
Begin
  NP := 0;
  For K := 0 To 63 Do
    If KTask(35, K, LongInt(@PB), 0) = 1 Then
    Begin
      If NP >= MAXP - 2 Then Break;
      Ser := PB[0]; Cpu := PB[3];
      If OldSer[K] = Ser Then D := Cpu - OldCpu[K] Else D := Cpu;
      OldSer[K] := Ser; OldCpu[K] := Cpu;
      PSer[NP] := Ser; PThr[NP] := PB[2]; PCpuT[NP] := Cpu; PMem[NP] := PB[4]; PSes[NP] := PB[5];
      PFlg[NP] := PB[6];
      If Dt > 0 Then PPct[NP] := MinI(100, (D * 100 + Dt Div 2) Div Dt) Else PPct[NP] := 0;
      Nm := GetZ(LongInt(@PB) + 32);
      If Nm = '' Then Nm := '?';
      PName[NP] := UpStr(Nm);
      Inc(NP);
    End
    Else OldSer[K] := 0;
  { processus inactif du systeme et noyau }
  PSer[NP] := 0; PThr[NP] := 1; PCpuT[NP] := SysI[1]; PMem[NP] := 0; PSes[NP] := -1; PFlg[NP] := 256;
  PPct[NP] := 100 - CpuPct; PName[NP] := 'Processus inactif';
  Inc(NP);
  PSer[NP] := 0; PThr[NP] := 1; PCpuT[NP] := SysI[14]; PMem[NP] := SysI[7] - SysI[8]; PSes[NP] := -1;
  PFlg[NP] := 512; PPct[NP] := SysPct; PName[NP] := 'OS2KRNL';
  Inc(NP);
End;

{ fenetres principales (cadres visibles avec un titre, sauf le bureau) et
  sessions plein ecran }
Procedure ScanApps;
Var He, H, K : LongInt; S, C : String;
Begin
  NA := 0;
  He := WinBeginEnumWindows(HWND_DESKTOP);
  If He <> 0 Then
  Begin
    H := WinGetNextWindow(He);
    While (H <> 0) And (NA < MAXA) Do
    Begin
      Dummy := WinQueryClassName(H, 64, LongInt(@TxtBuf));
      C := GetZ(LongInt(@TxtBuf));
      If (C = '#1') And (WinIsWindowVisible(H) <> 0) Then
      Begin
        Dummy := WinQueryWindowText(H, 60, LongInt(@TxtBuf));
        S := GetZ(LongInt(@TxtBuf));
        If (S <> '') And (S <> 'Bureau') And (S <> 'Desktop') Then
        Begin
          AHw[NA] := H; ASes[NA] := -1; ATitle[NA] := S;
          Inc(NA);
        End;
      End;
      H := WinGetNextWindow(He);
    End;
    Dummy := WinEndEnumWindows(He);
  End;
  For K := 0 To MAXS - 1 Do
    If (NA < MAXA) And (KSes(7, K, LongInt(@SesInfo)) = 1) Then
      If (SesInfo[3] > 0) And (K <> KSes(10, 0, 0)) Then
      Begin
        AHw[NA] := 0; ASes[NA] := K;
        ATitle[NA] := GetZ(LongInt(@SesInfo) + 16) + ' (plein '#130'cran)';
        Inc(NA);
      End;
End;

Procedure ScanSessions;
Var K : LongInt;
Begin
  NS := 0;
  For K := 0 To MAXS - 1 Do
    If (NS < MAXS) And (KSes(7, K, LongInt(@SesInfo)) = 1) Then
    Begin
      SNo[NS] := K; SFg[NS] := SesInfo[1]; SMode[NS] := SesInfo[2]; SProcs[NS] := SesInfo[3];
      STitle[NS] := GetZ(LongInt(@SesInfo) + 16);
      Inc(NS);
    End;
End;

{ reseau : TCPIPINFO de TCPIP32.DLL (charge a la premiere visite de
  l'onglet Reseau, car la configuration DHCP peut prendre du temps) }
Procedure ScanNet;
Var Hm, Pk : LongInt;
Begin
  If NetOn = 0 Then Exit;
  If NetFn = 0 Then
  Begin
    NetOn := 2;
    Hm := 0;
    If DosLoadModule(LongInt(@FailBuf), 64, Z('TCPIP32'), LongInt(@Hm)) = 0 Then
      Dummy := DosQueryProcAddr(Hm, 900, 0, LongInt(@NetFn));
    If NetFn = 0 Then Exit;
  End;
  NetInfo[10] := LongInt(@NetTxt); NetInfo[11] := 255;
  NetTxt[0] := 0;
  Dummy := CallPtr1(NetFn, LongInt(@NetInfo));
  NetCard := GetZ(LongInt(@NetTxt));
  Pk := NetInfo[7] + NetInfo[8];
  If NetLastPk >= 0 Then NetPkS := MaxI(0, Pk - NetLastPk) Else NetPkS := 0;
  NetLastPk := Pk;
End;

Procedure Sample;
Var T, Dt, D : LongInt;
Begin
  Dummy := KTask(34, LongInt(@SysI), 0, 0);
  T := SysI[0];
  Dt := T - LastT;
  If (LastT <> 0) And (Dt > 0) Then
  Begin
    D := SysI[1] - LastIdle;
    CpuPct := MaxI(0, MinI(100, 100 - (D * 100 + Dt Div 2) Div Dt));
    D := SysI[2] - LastKrn;
    KrnPct := MaxI(0, MinI(CpuPct, (D * 100 + Dt Div 2) Div Dt));
    D := SysI[14] - LastSys;
    SysPct := MaxI(0, MinI(CpuPct, (D * 100 + Dt Div 2) Div Dt));
  End
  Else Dt := 0;
  LastT := T; LastIdle := SysI[1]; LastKrn := SysI[2]; LastSys := SysI[14];
  { memoire : disponible (memoire libre des processus et du tas du
    noyau) ; charge dediee : le reste de la memoire physique (noyau, DLL,
    programmes) ; limite : memoire physique }
  AvailKb := SysI[4] + (SysI[6] - SysI[7]) Div 1024;
  LimitKb := SysI[3];
  MemUsedKb := MaxI(0, LimitKb - AvailKb);
  If MemUsedKb > MemPeakKb Then MemPeakKb := MemUsedKb;
  ScanProcs(Dt);
  ScanApps;
  ScanSessions;
  ScanNet;
  If Dt > 0 Then
  Begin
    AddHist(0, CpuPct);
    AddHist(1, KrnPct);
    If LimitKb > 0 Then AddHist(2, (MemUsedKb * 100) Div LimitKb) Else AddHist(2, 0);
    AddHist(3, NetPkS);
    If HistCount < HISTN Then Inc(HistCount);
    GridOff := (GridOff + 3) Mod 12;
  End;
End;

{ ==================================================================== }
{ Tri des processus                                                     }
{ ==================================================================== }

Function PKey(I, C : LongInt) : LongInt;
Begin
  Case C Of
    1 : PKey := PSer[I];
    2 : PKey := PPct[I];
    3 : PKey := PMem[I];
    4 : PKey := PThr[I];
    5 : PKey := PSes[I];
  Else
    PKey := 0;
  End;
End;

Function PLess(A, B : LongInt) : Boolean;
Var R : Boolean;
Begin
  If SortCol = 0 Then R := PName[A] < PName[B]
  Else If PKey(A, SortCol) <> PKey(B, SortCol) Then R := PKey(A, SortCol) < PKey(B, SortCol)
  Else R := PName[A] < PName[B];
  If SortDesc <> 0 Then
  Begin
    If SortCol = 0 Then R := PName[A] > PName[B]
    Else If PKey(A, SortCol) <> PKey(B, SortCol) Then R := PKey(A, SortCol) > PKey(B, SortCol)
    Else R := PName[A] < PName[B];
  End;
  PLess := R;
End;

Procedure SortProcs;
Var I, J, V : LongInt;
Begin
  For I := 0 To NP - 1 Do Ord_[I] := I;
  For I := 1 To NP - 1 Do
  Begin
    V := Ord_[I];
    J := I - 1;
    While (J >= 0) And PLess(V, Ord_[J]) Do
    Begin
      Ord_[J + 1] := Ord_[J];
      Dec(J);
    End;
    Ord_[J + 1] := V;
  End;
End;

{ ==================================================================== }
{ Listes : nombre de lignes, cle d'une ligne (selection conservee)      }
{ ==================================================================== }

Function ListCount(T : LongInt) : LongInt;
Begin
  Case T Of
    TB_APPS : ListCount := NA;
    TB_PROCS : ListCount := NP;
    TB_USERS : ListCount := NS;
  Else
    ListCount := 0;
  End;
End;

Function RowKey(T, R : LongInt) : LongInt;
Begin
  RowKey := -1;
  If (R < 0) Or (R >= ListCount(T)) Then Exit;
  Case T Of
    TB_APPS : If AHw[R] <> 0 Then RowKey := AHw[R] Else RowKey := $10000 + ASes[R];
    TB_PROCS : If PFlg[Ord_[R]] >= 256 Then RowKey := $20000 + PFlg[Ord_[R]] Else RowKey := PSer[Ord_[R]];
    TB_USERS : RowKey := SNo[R];
  End;
End;

Procedure KeepSel;
Var T, R : LongInt;
Begin
  For T := 0 To NTAB - 1 Do
    If (T = TB_APPS) Or (T = TB_PROCS) Or (T = TB_USERS) Then
    Begin
      If SelKey[T] <> -1 Then
      Begin
        Sel[T] := -1;
        For R := 0 To ListCount(T) - 1 Do
          If RowKey(T, R) = SelKey[T] Then Sel[T] := R;
      End;
      If Sel[T] >= ListCount(T) Then Sel[T] := ListCount(T) - 1;
      If Top[T] > MaxI(0, ListCount(T) - 1) Then Top[T] := 0;
    End;
End;

{ ==================================================================== }
{ Dessin (coordonnees Yt comptees depuis le haut de la fenetre)         }
{ ==================================================================== }

Procedure Fill(X1, Yt1, X2, Yt2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[0] := X1; Rc[1] := CH - Yt2; Rc[2] := X2; Rc[3] := CH - Yt1;
  Dummy := WinFillRect(Hps, LongInt(@Rc), C);
End;

Procedure GLn(X1, Yt1, X2, Yt2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := CH - 1 - Yt1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := CH - 1 - Yt2;
  Dummy := GpiLine(Hps, LongInt(@P));
End;

{ relief de Warp 3 : saillant (blanc en haut a gauche, gris fonce et noir
  en bas a droite) ou creux }
Procedure Bevel(X1, Yt1, X2, Yt2 : LongInt; Raised : Boolean);
Begin
  If Raised Then
  Begin
    GLn(X1, Yt1, X2 - 1, Yt1, CLR_WHITE);
    GLn(X1, Yt1, X1, Yt2 - 1, CLR_WHITE);
    GLn(X1, Yt2, X2, Yt2, CLR_BLACK);
    GLn(X2, Yt1, X2, Yt2, CLR_BLACK);
    GLn(X1 + 1, Yt2 - 1, X2 - 1, Yt2 - 1, CLR_DARKGRAY);
    GLn(X2 - 1, Yt1 + 1, X2 - 1, Yt2 - 1, CLR_DARKGRAY);
  End
  Else
  Begin
    GLn(X1, Yt1, X2, Yt1, CLR_DARKGRAY);
    GLn(X1, Yt1, X1, Yt2, CLR_DARKGRAY);
    GLn(X1, Yt2, X2, Yt2, CLR_WHITE);
    GLn(X2, Yt1, X2, Yt2, CLR_WHITE);
  End;
End;

{ couleurs RGB pour les graphiques (comme Windows XP : grille vert
  sombre, courbe vert vif) ; en 16 couleurs : couleurs de la palette }
Procedure RgbOn;
Var V : Array[0..3] Of LongInt;
Begin
  If RgbOk < 0 Then
  Begin
    V[3] := 16;
    { taille de la table du peripherique : 0 en vraies couleurs }
    If GpiQueryColorData(Hps, 4, LongInt(@V)) = 0 Then V[3] := 16;
    If (V[3] = 0) Or (V[3] > 16) Then RgbOk := 1 Else RgbOk := 0;
  End;
  If RgbOk = 1 Then Dummy := GpiCreateLogColorTable(Hps, 0, 3, 0, 0, 0);
End;

Procedure RgbOff;
Begin
  If RgbOk = 1 Then Dummy := GpiCreateLogColorTable(Hps, 1, 0, 0, 0, 0);
End;

Function Cl(Rgb, Pal : LongInt) : LongInt;
Begin
  If RgbOk = 1 Then Cl := Rgb Else Cl := Pal;
End;

Procedure TextT(X, Yt : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := CH - Yt - 16; Rc[2] := X + Length(S) * 8; Rc[3] := CH - Yt;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ texte aligne a droite sur Xr }
Procedure TextR(Xr, Yt : LongInt; S : String; Fg, Bg : LongInt);
Begin
  TextT(Xr - Length(S) * 8, Yt, S, Fg, Bg);
End;

{ texte tronque a N caracteres }
Function Cut(S : String; N : LongInt) : String;
Begin
  If N < 1 Then Cut := ''
  Else If Length(S) > N Then Cut := Copy(S, 1, MaxI(0, N - 1)) + '>'
  Else Cut := S;
End;

{ cadre de groupe grave (gris fonce et blanc) avec son titre }
Procedure Group(X1, Yt1, X2, Yt2 : LongInt; Title : String);
Begin
  GLn(X1, Yt1 + 8, X2 - 1, Yt1 + 8, CLR_DARKGRAY);
  GLn(X1, Yt1 + 8, X1, Yt2 - 1, CLR_DARKGRAY);
  GLn(X1, Yt2 - 1, X2 - 1, Yt2 - 1, CLR_DARKGRAY);
  GLn(X2 - 1, Yt1 + 8, X2 - 1, Yt2 - 1, CLR_DARKGRAY);
  GLn(X1 + 1, Yt1 + 9, X2 - 2, Yt1 + 9, CLR_WHITE);
  GLn(X1 + 1, Yt1 + 9, X1 + 1, Yt2 - 2, CLR_WHITE);
  GLn(X1, Yt2, X2, Yt2, CLR_WHITE);
  GLn(X2, Yt1 + 8, X2, Yt2, CLR_WHITE);
  Fill(X1 + 6, Yt1, X1 + 10 + Length(Title) * 8, Yt1 + 16, CLR_PALEGRAY);
  TextT(X1 + 8, Yt1, Title, CLR_DARKBLUE, CLR_PALEGRAY);
End;

{ bouton de commande dessine (Warp 3) }
Procedure Button(X1, Yt1, X2, Yt2 : LongInt; S : String; Enabled : Boolean);
Var C : LongInt;
Begin
  Fill(X1, Yt1, X2 + 1, Yt2 + 1, CLR_PALEGRAY);
  GLn(X1 - 1, Yt1 - 1, X2 + 1, Yt1 - 1, CLR_BLACK);
  GLn(X1 - 1, Yt2 + 1, X2 + 1, Yt2 + 1, CLR_BLACK);
  GLn(X1 - 1, Yt1 - 1, X1 - 1, Yt2 + 1, CLR_BLACK);
  GLn(X2 + 1, Yt1 - 1, X2 + 1, Yt2 + 1, CLR_BLACK);
  Bevel(X1, Yt1, X2, Yt2, True);
  If Enabled Then C := CLR_BLACK Else C := CLR_DARKGRAY;
  TextT((X1 + X2) Div 2 - Length(S) * 4, (Yt1 + Yt2) Div 2 - 8, S, C, CLR_PALEGRAY);
End;

{ --- onglets du carnet --- }

Function TabName(T : LongInt) : String;
Begin
  Case T Of
    TB_APPS : TabName := 'Applications';
    TB_PROCS : TabName := 'Processus';
    TB_PERF : TabName := 'Performances';
    TB_NET : TabName := 'R'#130'seau';
  Else
    TabName := 'Utilisateurs';
  End;
End;

Function TabX(T : LongInt) : LongInt;
Var K, X : LongInt;
Begin
  X := 6;
  For K := 0 To T - 1 Do X := X + Length(TabName(K)) * 8 + 14;
  TabX := X;
End;

Procedure DrawTabs;
Var T, X1, X2, Y1 : LongInt;
Begin
  For T := 0 To NTAB - 1 Do
  Begin
    X1 := TabX(T); X2 := X1 + Length(TabName(T)) * 8 + 12;
    If T = Tab Then
    Begin
      Y1 := 4;
      Fill(X1 - 2, Y1, X2 + 3, 4 + TABH + 2, CLR_PALEGRAY);
      GLn(X1 - 2, 4 + TABH, X1 - 2, Y1 + 2, CLR_WHITE);
      GLn(X1 - 2, Y1 + 2, X1, Y1, CLR_WHITE);
      GLn(X1, Y1, X2, Y1, CLR_WHITE);
      GLn(X2, Y1, X2 + 2, Y1 + 2, CLR_BLACK);
      GLn(X2 + 2, Y1 + 2, X2 + 2, 4 + TABH, CLR_BLACK);
      GLn(X2 + 1, Y1 + 2, X2 + 1, 4 + TABH, CLR_DARKGRAY);
      TextT(X1 + 6, Y1 + 4, TabName(T), CLR_BLACK, CLR_PALEGRAY);
    End
    Else
    Begin
      Y1 := 7;
      GLn(X1, 4 + TABH, X1, Y1 + 2, CLR_WHITE);
      GLn(X1, Y1 + 2, X1 + 2, Y1, CLR_WHITE);
      GLn(X1 + 2, Y1, X2 - 2, Y1, CLR_WHITE);
      GLn(X2 - 2, Y1, X2, Y1 + 2, CLR_BLACK);
      GLn(X2, Y1 + 2, X2, 4 + TABH, CLR_BLACK);
      GLn(X2 - 1, Y1 + 2, X2 - 1, 4 + TABH, CLR_DARKGRAY);
      TextT(X1 + 6, Y1 + 3, TabName(T), CLR_BLACK, CLR_PALEGRAY);
    End;
  End;
End;

{ page du carnet sous les onglets }
Function PgTop : LongInt;
Begin
  PgTop := 4 + TABH;
End;

Function PgBot : LongInt;
Begin
  PgBot := CH - STATH - 6;
End;

Procedure DrawPage;
Var X1, X2 : LongInt;
Begin
  GLn(4, PgTop, 4, PgBot, CLR_WHITE);
  GLn(4, PgBot, CW - 5, PgBot, CLR_BLACK);
  GLn(5, PgBot - 1, CW - 6, PgBot - 1, CLR_DARKGRAY);
  GLn(CW - 5, PgTop, CW - 5, PgBot, CLR_BLACK);
  GLn(CW - 6, PgTop + 1, CW - 6, PgBot - 1, CLR_DARKGRAY);
  { bord superieur, interrompu sous l'onglet actif }
  X1 := TabX(Tab) - 2; X2 := TabX(Tab) + Length(TabName(Tab)) * 8 + 14;
  GLn(4, PgTop, X1, PgTop, CLR_WHITE);
  GLn(X2, PgTop, CW - 5, PgTop, CLR_WHITE);
End;

{ --- listes a colonnes --- }

Function ListTop : LongInt;
Begin
  ListTop := PgTop + 10;
End;

Function ListBot : LongInt;
Begin
  If Tab = TB_PROCS Then ListBot := PgBot - BTNH - 16
  Else ListBot := PgBot - BTNH - 16;
End;

Function VisRows : LongInt;
Begin
  VisRows := MaxI(1, (ListBot - ListTop - HDRH - 4) Div ROWH);
End;

Procedure ColHead(X1, X2 : LongInt; S : String; Mark : String; Right : Boolean);
Var Yt : LongInt;
Begin
  Yt := ListTop + 2;
  Fill(X1, Yt, X2, Yt + HDRH, CLR_PALEGRAY);
  Bevel(X1, Yt, X2 - 1, Yt + HDRH - 1, True);
  S := Cut(S + Mark, (X2 - X1 - 8) Div 8);
  If Right Then TextR(X2 - 6, Yt + 1, S, CLR_BLACK, CLR_PALEGRAY)
  Else TextT(X1 + 4, Yt + 1, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure ListFrame;
Var R, L, K, N : LongInt;
Begin
  Fill(10, ListTop, CW - 10, ListBot, CLR_WHITE);
  Bevel(9, ListTop - 1, CW - 10, ListBot, False);
  GLn(10, ListTop, CW - 11, ListTop, CLR_BLACK);
  GLn(10, ListTop, 10, ListBot - 1, CLR_BLACK);
  { barre de defilement simple }
  N := ListCount(Tab);
  If N > VisRows Then
  Begin
    R := ListTop + HDRH + 4;
    Fill(CW - 18, R, CW - 12, ListBot - 2, CLR_PALEGRAY);
    L := MaxI(10, ((ListBot - 2 - R) * VisRows) Div N);
    K := R + ((ListBot - 2 - R - L) * Top[Tab]) Div MaxI(1, N - VisRows);
    Fill(CW - 18, K, CW - 12, K + L, CLR_DARKGRAY);
  End;
End;

Function RowYt(R : LongInt) : LongInt;
Begin
  RowYt := ListTop + HDRH + 4 + (R - Top[Tab]) * ROWH;
End;

Function RowVisible(R : LongInt) : Boolean;
Begin
  RowVisible := (R >= Top[Tab]) And (R < Top[Tab] + VisRows);
End;

{ fond de la ligne R (selection en bleu fonce) ; couleurs du texte }
Procedure RowBack(R : LongInt; Var Fg, Bg : LongInt);
Begin
  If R = Sel[Tab] Then
  Begin
    Fill(12, RowYt(R), CW - 20, RowYt(R) + ROWH, CLR_DARKBLUE);
    Fg := CLR_WHITE; Bg := CLR_DARKBLUE;
  End
  Else
  Begin
    Fg := CLR_BLACK; Bg := CLR_WHITE;
  End;
End;

Function BtnYt : LongInt;
Begin
  BtnYt := PgBot - BTNH - 8;
End;

{ boutons de la page : jusqu'a trois, alignes a droite }
Function BtnCount : LongInt;
Begin
  Case Tab Of
    TB_APPS : BtnCount := 3;
    TB_PROCS : BtnCount := 1;
    TB_USERS : BtnCount := 2;
  Else
    BtnCount := 0;
  End;
End;

Function BtnText(K : LongInt) : String;
Begin
  BtnText := '';
  Case Tab Of
    TB_APPS :
      Case K Of
        0 : BtnText := 'Fin de t'#131'che';
        1 : BtnText := 'Basculer vers';
        2 : BtnText := 'Nouvelle t'#131'che...';
      End;
    TB_PROCS : BtnText := 'Terminer le processus';
    TB_USERS :
      Case K Of
        0 : BtnText := 'Basculer vers';
        1 : BtnText := 'Fermer la session';
      End;
  End;
End;

Function BtnW_(K : LongInt) : LongInt;
Begin
  BtnW_ := MaxI(110, Length(BtnText(K)) * 8 + 20);
End;

Function BtnX(K : LongInt) : LongInt;
Var X, J : LongInt;
Begin
  X := CW - 12;
  For J := BtnCount - 1 DownTo K Do X := X - BtnW_(J) - 8;
  BtnX := X + 8;
End;

Procedure DrawButtons;
Var K : LongInt; En : Boolean;
Begin
  For K := 0 To BtnCount - 1 Do
  Begin
    En := (Sel[Tab] >= 0) Or ((Tab = TB_APPS) And (K = 2));
    Button(BtnX(K), BtnYt, BtnX(K) + BtnW_(K) - 1, BtnYt + BTNH - 1, BtnText(K), En);
  End;
End;

{ --- onglet Applications --- }
Procedure PaintApps;
Var R, Fg, Bg, W : LongInt; St : String;
Begin
  ListFrame;
  W := CW - 20;
  ColHead(11, W - 120, 'T'#131'che', '', False);
  ColHead(W - 120, W, #144'tat', '', False);
  For R := 0 To NA - 1 Do
    If RowVisible(R) Then
    Begin
      RowBack(R, Fg, Bg);
      { petite fenetre (cadre) ou ecran plein }
      If AHw[R] <> 0 Then
      Begin
        Fill(16, RowYt(R) + 3, 28, RowYt(R) + 13, CLR_WHITE);
        Fill(16, RowYt(R) + 3, 28, RowYt(R) + 6, CLR_DARKBLUE);
        GLn(16, RowYt(R) + 3, 27, RowYt(R) + 3, CLR_BLACK);
        GLn(16, RowYt(R) + 12, 27, RowYt(R) + 12, CLR_BLACK);
        GLn(16, RowYt(R) + 3, 16, RowYt(R) + 12, CLR_BLACK);
        GLn(27, RowYt(R) + 3, 27, RowYt(R) + 12, CLR_BLACK);
      End
      Else
      Begin
        Fill(16, RowYt(R) + 3, 28, RowYt(R) + 13, CLR_BLACK);
        GLn(18, RowYt(R) + 9, 22, RowYt(R) + 9, CLR_WHITE);
      End;
      TextT(34, RowYt(R), Cut(ATitle[R], (W - 160) Div 8), Fg, Bg);
      St := 'En cours';
      TextT(W - 114, RowYt(R), St, Fg, Bg);
    End;
  If NA = 0 Then TextT(34, RowYt(0), 'Aucune t'#131'che', CLR_DARKGRAY, CLR_WHITE);
  DrawButtons;
End;

{ --- onglet Processus --- }
Function PColX(C : LongInt) : LongInt;
Var W : LongInt;
Begin
  W := CW - 20;
  Case C Of
    0 : PColX := 11;
    1 : PColX := W - 296;
    2 : PColX := W - 244;
    3 : PColX := W - 200;
    4 : PColX := W - 112;
    5 : PColX := W - 64;
  Else
    PColX := W;
  End;
End;

Function PColName(C : LongInt) : String;
Begin
  Case C Of
    0 : PColName := 'Nom de l''image';
    1 : PColName := 'PID';
    2 : PColName := 'UC';
    3 : PColName := 'M'#130'moire';
    4 : PColName := 'Fils';
  Else
    PColName := 'Ses.';
  End;
End;

Function PType(I : LongInt) : String;
Begin
  If PFlg[I] >= 256 Then PType := ''
  Else If (PFlg[I] And 4) <> 0 Then PType := 'DOS'
  Else If (PFlg[I] And 2) <> 0 Then PType := 'PM'
  Else If (PFlg[I] And 1) <> 0 Then PType := 'LX'
  Else PType := 'VIO';
End;

Procedure PaintProcs;
Var R, I, C, Fg, Bg : LongInt; M, S : String;
Begin
  ListFrame;
  For C := 0 To NPCOL - 1 Do
  Begin
    M := '';
    If C = SortCol Then
    Begin
      If SortDesc <> 0 Then M := ' '#31 Else M := ' '#30;
    End;
    ColHead(PColX(C), PColX(C + 1), PColName(C), M, C > 0);
  End;
  For R := 0 To NP - 1 Do
    If RowVisible(R) Then
    Begin
      I := Ord_[R];
      RowBack(R, Fg, Bg);
      S := PName[I];
      If PType(I) <> '' Then S := S + ' (' + PType(I) + ')';
      TextT(15, RowYt(R), Cut(S, (PColX(1) - 18) Div 8), Fg, Bg);
      If PFlg[I] = 512 Then S := '-' Else S := IStr(PSer[I]);
      TextR(PColX(2) - 6, RowYt(R), S, Fg, Bg);
      S := IStr(PPct[I]);
      If Length(S) < 2 Then S := '0' + S;
      TextR(PColX(3) - 6, RowYt(R), S, Fg, Bg);
      TextR(PColX(4) - 6, RowYt(R), NStr((PMem[I] + 1023) Div 1024) + ' Ko', Fg, Bg);
      TextR(PColX(5) - 6, RowYt(R), IStr(PThr[I]), Fg, Bg);
      If PSes[I] >= 0 Then TextR(PColX(6) - 6, RowYt(R), IStr(PSes[I]), Fg, Bg);
    End;
  DrawButtons;
End;

{ --- onglet Performances --- }

{ jauge a segments (vert vif allume, vert fonce eteint) sur fond noir }
Procedure Meter(X1, Yt1, X2, Yt2, Pct : LongInt; Lbl : String);
Var Yb, Rows, Lit, K, Y, Xm : LongInt;
Begin
  Fill(X1, Yt1, X2 + 1, Yt2 + 1, CLR_BLACK);
  Bevel(X1 - 1, Yt1 - 1, X2 + 1, Yt2 + 1, False);
  Yb := Yt2 - 20;
  Rows := (Yb - Yt1 - 6) Div 3;
  Lit := (Pct * Rows + 50) Div 100;
  If (Pct > 0) And (Lit = 0) Then Lit := 1;
  Xm := (X1 + X2) Div 2;
  RgbOn;
  For K := 0 To Rows - 1 Do
  Begin
    Y := Yb - K * 3;
    If K < Lit Then
    Begin
      GLn(Xm - 18, Y, Xm - 2, Y, Cl($00FF00, CLR_GREEN));
      GLn(Xm + 2, Y, Xm + 18, Y, Cl($00FF00, CLR_GREEN));
    End
    Else
    Begin
      GLn(Xm - 18, Y, Xm - 2, Y, Cl($005000, CLR_DARKGREEN));
      GLn(Xm + 2, Y, Xm + 18, Y, Cl($005000, CLR_DARKGREEN));
    End;
  End;
  RgbOff;
  TextT(Xm - Length(Lbl) * 4, Yt2 - 18, Lbl, CLR_GREEN, CLR_BLACK);
End;

{ historique : grille vert fonce qui defile, courbes des valeurs (0 a
  Max) des HistCount dernieres mesures }
Procedure Graph(X1, Yt1, X2, Yt2, H1, C1, H2, C2, Max : LongInt; Two : Boolean);
Var X, Y, K, N, Hh, Px, Py, Qx, Qy, Step : LongInt;
Begin
  Fill(X1, Yt1, X2 + 1, Yt2 + 1, CLR_BLACK);
  Bevel(X1 - 1, Yt1 - 1, X2 + 1, Yt2 + 1, False);
  RgbOn;
  X := X2 - GridOff;
  While X > X1 Do
  Begin
    GLn(X, Yt1, X, Yt2, Cl($008040, CLR_DARKGREEN));
    X := X - 12;
  End;
  Y := Yt2 - 12;
  While Y > Yt1 Do
  Begin
    GLn(X1, Y, X2, Y, Cl($008040, CLR_DARKGREEN));
    Y := Y - 12;
  End;
  If Max <= 0 Then Max := 1;
  Hh := Yt2 - Yt1 - 2;
  Step := 3;
  N := MinI(HistCount, (X2 - X1) Div Step + 1);
  If Two Then
  Begin
    Px := -1; Py := 0;
    For K := 0 To N - 1 Do
    Begin
      Qx := X2 - K * Step;
      Qy := Yt2 - 1 - (MinI(HistAt(H2, HISTN - 1 - K), Max) * Hh) Div Max;
      If Px >= 0 Then GLn(Px, Py, Qx, Qy, C2);
      Px := Qx; Py := Qy;
    End;
  End;
  Px := -1; Py := 0;
  For K := 0 To N - 1 Do
  Begin
    Qx := X2 - K * Step;
    Qy := Yt2 - 1 - (MinI(HistAt(H1, HISTN - 1 - K), Max) * Hh) Div Max;
    If Px >= 0 Then GLn(Px, Py, Qx, Qy, C1);
    Px := Qx; Py := Qy;
  End;
  RgbOff;
End;

{ couleurs des courbes (apres RgbOn : RgbOk est connu) }
Function CRgbG : LongInt;
Begin
  If RgbOk < 0 Then RgbOn;
  RgbOff;
  CRgbG := Cl($00FF00, CLR_GREEN);
End;

Function CRgbR : LongInt;
Begin
  If RgbOk < 0 Then RgbOn;
  RgbOff;
  CRgbR := Cl($FF0000, CLR_RED);
End;

Function CRgbY : LongInt;
Begin
  If RgbOk < 0 Then RgbOn;
  RgbOff;
  CRgbY := Cl($FFFF00, CLR_YELLOW);
End;

Procedure InfoLine(X1, X2, Yt : LongInt; L, V : String);
Begin
  TextT(X1, Yt, L, CLR_BLACK, CLR_PALEGRAY);
  TextR(X2, Yt, V, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintPerf;
Var X1, X2, Xm, Yt, Gh, Lw, Y2, Gb, S : LongInt;
Begin
  X1 := 12; X2 := CW - 12; Xm := CW Div 2;
  Lw := 92;
  Gb := PgBot - 2 * 84 - 8;
  Gh := (Gb - (PgTop + 8)) Div 2;
  { utilisation du processeur }
  Yt := PgTop + 6;
  Y2 := Yt + Gh - 4;
  Group(X1, Yt, X1 + Lw, Y2, 'UC');
  Meter(X1 + 10, Yt + 20, X1 + Lw - 10, Y2 - 8, CpuPct, IStr(CpuPct) + ' %');
  Group(X1 + Lw + 8, Yt, X2, Y2, 'Historique de l''utilisation UC');
  Graph(X1 + Lw + 18, Yt + 20, X2 - 10, Y2 - 8, 0, CRgbG, 1, CRgbR, 100, KernOn <> 0);
  { memoire }
  Yt := Yt + Gh;
  Y2 := Yt + Gh - 4;
  Group(X1, Yt, X1 + Lw, Y2, 'M'#130'moire');
  If LimitKb > 0 Then S := (MemUsedKb * 100) Div LimitKb Else S := 0;
  Meter(X1 + 10, Yt + 20, X1 + Lw - 10, Y2 - 8, S, IStr((MemUsedKb + 512) Div 1024) + ' Mo');
  Group(X1 + Lw + 8, Yt, X2, Y2, 'Historique de la m'#130'moire utilis'#130'e');
  Graph(X1 + Lw + 18, Yt + 20, X2 - 10, Y2 - 8, 2, CRgbY, 2, CRgbY, 100, False);
  { totaux et memoire (Ko) }
  Yt := Gb;
  Group(X1, Yt, Xm - 4, Yt + 80, 'Totaux');
  InfoLine(X1 + 10, Xm - 14, Yt + 16, 'Handles', NStr(SysI[11]));
  InfoLine(X1 + 10, Xm - 14, Yt + 32, 'Fils', NStr(SysI[9]));
  InfoLine(X1 + 10, Xm - 14, Yt + 48, 'Processus', NStr(SysI[10]));
  Group(Xm + 4, Yt, X2, Yt + 80, 'M'#130'moire physique (Ko)');
  InfoLine(Xm + 14, X2 - 10, Yt + 16, 'Totale', NStr(SysI[3]));
  InfoLine(Xm + 14, X2 - 10, Yt + 32, 'Disponible', NStr(AvailKb));
  InfoLine(Xm + 14, X2 - 10, Yt + 48, 'Disque virtuel', NStr((SysI[12] + 1023) Div 1024));
  Yt := Gb + 84;
  Group(X1, Yt, Xm - 4, Yt + 80, 'Charge d'#130'di'#130'e (Ko)');
  InfoLine(X1 + 10, Xm - 14, Yt + 16, 'Totale', NStr(MemUsedKb));
  InfoLine(X1 + 10, Xm - 14, Yt + 32, 'Limite', NStr(LimitKb));
  InfoLine(X1 + 10, Xm - 14, Yt + 48, 'Maximale', NStr(MemPeakKb));
  Group(Xm + 4, Yt, X2, Yt + 80, 'M'#130'moire du noyau (Ko)');
  InfoLine(Xm + 14, X2 - 10, Yt + 16, 'Totale', NStr(SysI[7] Div 1024));
  InfoLine(Xm + 14, X2 - 10, Yt + 32, 'Processus', NStr(SysI[8] Div 1024));
  InfoLine(Xm + 14, X2 - 10, Yt + 48, 'Noyau', NStr((SysI[7] - SysI[8]) Div 1024));
End;

{ --- onglet Reseau --- }
Function IpStr(V : LongInt) : String;
Begin
  IpStr := IStr((V Shr 24) And 255) + '.' + IStr((V Shr 16) And 255) + '.' + IStr((V Shr 8) And 255) + '.' +
           IStr(V And 255);
End;

Procedure PaintNet;
Var X1, X2, Yt, Y2, M, K, W : LongInt; S : String;
Begin
  X1 := 12; X2 := CW - 12;
  Yt := PgTop + 6;
  Y2 := PgBot - 112;
  Group(X1, Yt, X2, Y2, 'lan0 : trames par seconde');
  M := 10;
  For K := 0 To HISTN - 1 Do
    If NetH[K] > M Then M := NetH[K];
  M := ((M + 9) Div 10) * 10;
  Graph(X1 + 46, Yt + 20, X2 - 10, Y2 - 8, 3, CRgbG, 3, CRgbG, M, False);
  TextR(X1 + 42, Yt + 18, IStr(M), CLR_BLACK, CLR_PALEGRAY);
  TextR(X1 + 42, (Yt + Y2) Div 2 - 4, IStr(M Div 2), CLR_BLACK, CLR_PALEGRAY);
  TextR(X1 + 42, Y2 - 24, '0', CLR_BLACK, CLR_PALEGRAY);
  { tableau de l'interface }
  Yt := Y2 + 6;
  Fill(X1, Yt, X2, PgBot - 8, CLR_WHITE);
  Bevel(X1 - 1, Yt - 1, X2, PgBot - 8, False);
  W := X2 - X1;
  Fill(X1 + 1, Yt, X2 - 1, Yt + HDRH, CLR_PALEGRAY);
  Bevel(X1 + 1, Yt, X1 + 140, Yt + HDRH - 1, True);
  Bevel(X1 + 141, Yt, X1 + 260, Yt + HDRH - 1, True);
  Bevel(X1 + 261, Yt, X2 - 2, Yt + HDRH - 1, True);
  TextT(X1 + 5, Yt + 1, 'Interface', CLR_BLACK, CLR_PALEGRAY);
  TextT(X1 + 145, Yt + 1, 'Trames/s', CLR_BLACK, CLR_PALEGRAY);
  TextT(X1 + 265, Yt + 1, #144'tat', CLR_BLACK, CLR_PALEGRAY);
  Yt := Yt + HDRH + 2;
  If NetOn = 0 Then
    TextT(X1 + 5, Yt, 'Choisissez cet onglet pour interroger TCPIP32', CLR_DARKGRAY, CLR_WHITE)
  Else If NetFn = 0 Then TextT(X1 + 5, Yt, 'TCPIP32.DLL introuvable', CLR_DARKRED, CLR_WHITE)
  Else If NetInfo[0] = 0 Then TextT(X1 + 5, Yt, 'Aucune carte r'#130'seau', CLR_DARKGRAY, CLR_WHITE)
  Else
  Begin
    TextT(X1 + 5, Yt, 'lan0', CLR_BLACK, CLR_WHITE);
    TextR(X1 + 250, Yt, IStr(NetPkS), CLR_BLACK, CLR_WHITE);
    If NetInfo[6] = 0 Then S := 'D'#130'connect'#130'e'
    Else If NetInfo[0] = 2 Then S := 'Connect'#130'e, ' + IpStr(NetInfo[1])
    Else S := 'Connect'#130'e, sans adresse';
    TextT(X1 + 265, Yt, Cut(S, (X2 - X1 - 270) Div 8), CLR_BLACK, CLR_WHITE);
    TextT(X1 + 5, Yt + 18, Cut(NetCard, (W - 10) Div 8), CLR_DARKBLUE, CLR_WHITE);
    TextT(X1 + 5, Yt + 36, 'Trames re'#135'ues : ' + NStr(NetInfo[7]) + '   envoy'#130'es : ' + NStr(NetInfo[8]),
          CLR_DARKGRAY, CLR_WHITE);
  End;
End;

{ --- onglet Utilisateurs --- }
Procedure PaintUsers;
Var R, Fg, Bg, W : LongInt; S, U : String;
Begin
  ListFrame;
  W := CW - 20;
  ColHead(11, 131, 'Utilisateur', '', False);
  ColHead(131, 171, 'ID', '', True);
  ColHead(171, 283, #144'tat', '', False);
  ColHead(283, W, 'Session', '', False);
  U := GetEnvS('USER');
  If U = '' Then U := 'Utilisateur';
  For R := 0 To NS - 1 Do
    If RowVisible(R) Then
    Begin
      RowBack(R, Fg, Bg);
      TextT(15, RowYt(R), Cut(U, 14), Fg, Bg);
      TextR(165, RowYt(R), IStr(SNo[R]), Fg, Bg);
      If SFg[R] <> 0 Then S := 'Actif' Else If SProcs[R] > 0 Then S := 'Arri'#138're-plan' Else S := 'Inactif';
      TextT(175, RowYt(R), S, Fg, Bg);
      S := STitle[R];
      If SNo[R] = KSes(10, 0, 0) Then S := 'Presentation Manager';
      TextT(287, RowYt(R), Cut(S, (W - 290) Div 8), Fg, Bg);
    End;
  DrawButtons;
End;

{ --- barre d'etat --- }
Procedure Panel(X1, X2 : LongInt; S : String);
Var Yt : LongInt;
Begin
  Yt := CH - STATH;
  Bevel(X1, Yt, X2, CH - 3, False);
  TextT(X1 + 4, Yt + 1, Cut(S, (X2 - X1 - 6) Div 8), CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintStatus;
Var A, B : LongInt;
Begin
  A := 4 + (CW - 8) * 27 Div 100;
  B := 4 + (CW - 8) * 56 Div 100;
  Panel(4, A - 2, 'Processus : ' + IStr(SysI[10]));
  Panel(A + 2, B - 2, 'UC : ' + IStr(CpuPct) + ' %');
  Panel(B + 2, CW - 5, 'Charge : ' + IStr((MemUsedKb + 512) Div 1024) + ' / ' + IStr((LimitKb + 512) Div 1024) + ' Mo');
End;

Procedure PaintAll(H : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  If Hps = 0 Then Exit;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  CW := Rc[2]; CH := Rc[3];
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
  DrawTabs;
  DrawPage;
  Case Tab Of
    TB_APPS : PaintApps;
    TB_PROCS : PaintProcs;
    TB_PERF : PaintPerf;
    TB_NET : PaintNet;
    TB_USERS : PaintUsers;
  End;
  PaintStatus;
  Dummy := WinEndPaint(Hps);
End;

{ ==================================================================== }
{ Actions                                                               }
{ ==================================================================== }

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 1);
End;

Procedure Refresh;
Begin
  Sample;
  SortProcs;
  KeepSel;
  Redraw;
End;

Procedure ShowMsg(T, C : String; Fl : LongInt);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(T), Z2(C), 0, Fl Or MB_MOVEABLE);
End;

{ messages de plus de 255 caracteres (limite des chaines) : texte cumule
  dans LBuf par LAdd, puis affiche par LMsgBox }
Var
  LBuf : Array[0..4095] Of Byte;
  LLen : LongInt;

Procedure LClr;
Begin
  LLen := 0;
  LBuf[0] := 0;
End;

Procedure LAdd(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If LLen < 4094 Then
    Begin
      LBuf[LLen] := Ord(S[K]);
      Inc(LLen);
    End;
  LBuf[LLen] := 0;
End;

Function LMsgBox(Cap : String; Fl : LongInt) : LongInt;
Begin
  LMsgBox := WinMessageBox(HWND_DESKTOP, Frame, LongInt(@LBuf), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

Function Ask(T, C : String) : Boolean;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(T), Z2(C), 0, MB_YESNO Or MB_WARNING Or MB_MOVEABLE) = MBID_YES;
End;

Procedure SetTimer;
Begin
  Dummy := WinStopTimer(Hab, Client, 1);
  If Paused = 0 Then Dummy := WinStartTimer(Hab, Client, 1, Interval);
End;

Procedure CheckItem(Id, On : LongInt);
Begin
  If MenuHw = 0 Then Exit;
  If On <> 0 Then Dummy := WinSendMsg(MenuHw, MM_SETITEMATTR, Id Or (1 Shl 16), MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(MenuHw, MM_SETITEMATTR, Id Or (1 Shl 16), MIA_CHECKED);
End;

Function B2I(B : Boolean) : LongInt;
Begin
  If B Then B2I := 1 Else B2I := 0;
End;

Procedure CheckSpeed;
Begin
  CheckItem(CM_SPHIGH, B2I((Paused = 0) And (Interval = 500)));
  CheckItem(CM_SPNORM, B2I((Paused = 0) And (Interval = 1000)));
  CheckItem(CM_SPLOW, B2I((Paused = 0) And (Interval = 4000)));
  CheckItem(CM_SPPAUSE, Paused);
  CheckItem(CM_KERNEL, KernOn);
End;

Procedure SelectTab(T : LongInt);
Begin
  If (T < 0) Or (T >= NTAB) Then Exit;
  Tab := T;
  If (Tab = TB_NET) And (NetOn = 0) Then
  Begin
    NetOn := 1;
    ScanNet;
  End;
  Redraw;
End;

{ lancer un programme dans une nouvelle session (comme le bureau) ; un
  programme de PM la quitte pour la session de Presentation Manager }
Function FindProg(S : String) : String;
Var P, D : String; K : LongInt;
Begin
  FindProg := '';
  If Pos('.', S) = 0 Then S := S + '.EXE';
  If (Pos('\', S) > 0) Or (Pos(':', S) > 0) Then
  Begin
    If FileExists(S) Then FindProg := S;
    Exit;
  End;
  If FileExists(S) Then
  Begin
    FindProg := S;
    Exit;
  End;
  P := GetEnvS('PATH') + ';C:\';
  While P <> '' Do
  Begin
    K := Pos(';', P);
    If K = 0 Then K := Length(P) + 1;
    D := Copy(P, 1, K - 1);
    Delete(P, 1, K);
    If D <> '' Then
    Begin
      If D[Length(D)] <> '\' Then D := D + '\';
      If FileExists(D + S) Then
      Begin
        FindProg := D + S;
        Exit;
      End;
    End;
  End;
End;

{ programme de Presentation Manager ? LX ou NE de type PM, ou programme
  PE (OS2PC) qui importe PMWIN.DLL }
Function IsPmProg(P : String) : Boolean;
Var Fl, H, Act, Got, K, Off : LongInt;
Begin
  IsPmProg := False;
  Fl := 0;
  If (DosQueryAppType(Z(P), LongInt(@Fl)) = 0) And ((Fl And 7) = 3) Then
  Begin
    IsPmProg := True;
    Exit;
  End;
  H := 0; Act := 0;
  If DosOpen(Z(P), LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) <> 0 Then Exit;
  Off := 0;
  Repeat
    Got := 0;
    If DosRead(H, LongInt(@ExeBuf), SizeOf(ExeBuf), LongInt(@Got)) <> 0 Then Got := 0;
    For K := 0 To Got - 6 Do
      If ((ExeBuf[K] = 80) Or (ExeBuf[K] = 112)) And ((ExeBuf[K + 1] = 77) Or (ExeBuf[K + 1] = 109)) And
         ((ExeBuf[K + 2] = 87) Or (ExeBuf[K + 2] = 119)) And ((ExeBuf[K + 3] = 73) Or (ExeBuf[K + 3] = 105)) And
         ((ExeBuf[K + 4] = 78) Or (ExeBuf[K + 4] = 110)) And (ExeBuf[K + 5] = 46) Then
        IsPmProg := True;
    Off := Off + Got;
  Until (Got < SizeOf(ExeBuf)) Or (Off >= 1048576);
  Dummy := DosClose(H);
End;

Procedure RunTask(Cmd : String);
Var Res : Array[0..1] Of LongInt; Rc, K, S : LongInt; Prog, Params, E, T : String;
Begin
  While (Cmd <> '') And (Cmd[1] = ' ') Do Delete(Cmd, 1, 1);
  If Cmd = '' Then Exit;
  K := Pos(' ', Cmd);
  If K > 0 Then
  Begin
    Prog := Copy(Cmd, 1, K - 1); Params := Copy(Cmd, K + 1, 255);
  End
  Else
  Begin
    Prog := Cmd; Params := '';
  End;
  E := UpStr(Prog);
  If (Pos('.CMD', E) > 0) Or (Pos('.BAT', E) > 0) Then
  Begin
    Params := '/C ' + Prog + ' ' + Params;
    Prog := GetEnvS('COMSPEC');
    If (Prog = '') Or (Pos('PMSHELL', UpStr(Prog)) > 0) Then Prog := 'C:\CMD.EXE';
  End
  Else
  Begin
    T := FindProg(Prog);
    If T = '' Then
    Begin
      ShowMsg('OS/2-0 ne trouve pas "' + Prog + '". V'#130'rifiez le nom, puis r'#130'essayez.',
              'Cr'#130'er une nouvelle t'#131'che', MB_OK Or MB_ERROR);
      Exit;
    End;
    Prog := T;
  End;
  PutZ(LongInt(@ArgBuf), Prog);
  K := Length(Prog) + 1;
  PutZ(LongInt(@ArgBuf) + K, Params);
  WrB(LongInt(@ArgBuf) + K + Length(Params) + 1, 0);
  { programme de PM : dans la session de Presentation Manager, comme les
    objets programmes du bureau }
  If IsPmProg(Prog) Then
  Begin
    PutZ(LongInt(@NameZ2), Prog);
    Res[0] := 0; Res[1] := 0;
    Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), LongInt(@NameZ2));
    If Rc <> 0 Then
      ShowMsg('SYS1041: Impossible de lancer ' + Prog + ' (erreur ' + IStr(Rc) + ').', 'Cr'#130'er une nouvelle t'#131'che',
              MB_OK Or MB_ERROR);
    Exit;
  End;
  T := UpStr(Prog);
  While Pos('\', T) > 0 Do Delete(T, 1, Pos('\', T));
  S := KSes(4, Z(T), 0);
  If S < 0 Then
  Begin
    ShowMsg('Trop de sessions : fermez un programme.', 'Gestionnaire des t'#131'ches', MB_OK Or MB_WARNING);
    Exit;
  End;
  Dummy := KSes(12, S, 0);
  PutZ(LongInt(@NameZ2), Prog);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), LongInt(@NameZ2));
  If Rc <> 0 Then
  Begin
    Dummy := KSes(12, -1, 0);
    Dummy := KSes(17, S, 0);
    ShowMsg('SYS1041: Impossible de lancer ' + Prog + ' (erreur ' + IStr(Rc) + ').', 'Cr'#130'er une nouvelle t'#131'che',
            MB_OK Or MB_ERROR);
  End
  Else Dummy := KSes(3, S, 0);
End;

{ --- fenetre Creer une nouvelle tache --- }
Procedure CloseInput;
Begin
  If InFr <> 0 Then Dummy := WinDestroyWindow(InFr);
  InFr := 0; InCl := 0; InEf := 0;
End;

Procedure InputDone;
Var S : String;
Begin
  Dummy := WinQueryWindowText(InEf, 200, LongInt(@TxtBuf));
  S := GetZ(LongInt(@TxtBuf));
  CloseInput;
  RunTask(S);
  Refresh;
End;

Procedure NewTask;
Var Fl, Sw, Sh : LongInt;
Begin
  If InFr <> 0 Then
  Begin
    Dummy := WinSetActiveWindow(HWND_DESKTOP, InFr);
    Exit;
  End;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  InCl := 0;
  InFr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('TMInput'), Z2('Cr'#130'er une nouvelle t'#131'che'),
                             0, 0, 0, LongInt(@InCl));
  If InFr = 0 Then Exit;
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(InFr, HWND_TOP, MaxI(0, (Sw - 420) Div 2), MaxI(0, (Sh - 160) Div 2), 420, 160,
                           SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, InFr);
  Dummy := WinSetFocus(HWND_DESKTOP, InEf);
End;

Function InputProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk, Ps : LongInt; Rc, Tr : Array[0..3] Of LongInt;
Begin
  InputProc := 0;
  Case Msg Of
    WM_CREATE :
      Begin
        InCl := H;
        InEf := WinCreateWindow(H, WC_ENTRYFIELD, 0, WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
                                80, 44, 320, 18, H, HWND_TOP, ID_EF, 0, 0);
        Dummy := WinSendMsg(InEf, EM_SETTEXTLIMIT, 200, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                                 220, 8, 84, 24, H, HWND_TOP, ID_OK, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                 312, 8, 88, 24, H, HWND_TOP, ID_CANCEL, 0, 0);
      End;
    WM_PAINT :
      Begin
        Ps := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Ps, LongInt(@Rc), CLR_PALEGRAY);
        Tr[0] := 12; Tr[2] := Rc[2] - 8;
        Tr[1] := Rc[3] - 24; Tr[3] := Rc[3] - 8;
        PutZ(LongInt(@TxtBuf), 'Tapez le nom d''un programme ; OS/2-0');
        Dummy := WinDrawText(Ps, -1, LongInt(@TxtBuf), LongInt(@Tr), CLR_BLACK, CLR_PALEGRAY, 0);
        Tr[1] := Rc[3] - 40; Tr[3] := Rc[3] - 24;
        PutZ(LongInt(@TxtBuf), 'le lancera dans une nouvelle session.');
        Dummy := WinDrawText(Ps, -1, LongInt(@TxtBuf), LongInt(@Tr), CLR_BLACK, CLR_PALEGRAY, 0);
        Tr[0] := 8; Tr[1] := 44; Tr[2] := 74; Tr[3] := 62;
        PutZ(LongInt(@TxtBuf), 'Ouvrir :');
        Dummy := WinDrawText(Ps, -1, LongInt(@TxtBuf), LongInt(@Tr), CLR_BLACK, CLR_PALEGRAY, 0);
        Dummy := WinEndPaint(Ps);
      End;
    WM_COMMAND :
      If Lo16(Mp1) = ID_OK Then InputDone
      Else If Lo16(Mp1) = ID_CANCEL Then CloseInput;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
          InputDone
        Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then CloseInput
        Else InputProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE : CloseInput;
  Else
    InputProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ --- boutons des pages --- }
Procedure EndTask;
Var R : LongInt;
Begin
  R := Sel[TB_APPS];
  If (R < 0) Or (R >= NA) Then Exit;
  If AHw[R] <> 0 Then Dummy := WinPostMsg(AHw[R], WM_CLOSE, 0, 0)
  Else If Ask('La session ' + ATitle[R] + ' et ses programmes vont '#136'tre arr'#136't'#130's. Continuer ?',
              'Fin de t'#131'che') Then
  Begin
    For R := 0 To NP - 1 Do
      If (PFlg[R] < 256) And (PSes[R] = ASes[Sel[TB_APPS]]) Then Dummy := DosKillProcess(1, PSer[R]);
  End;
  Dummy := WinStartTimer(Hab, Client, 2, 400);
End;

Procedure SwitchTo;
Var R : LongInt;
Begin
  R := Sel[TB_APPS];
  If (R < 0) Or (R >= NA) Then Exit;
  If AHw[R] <> 0 Then
  Begin
    Dummy := WinSetWindowPos(AHw[R], HWND_TOP, 0, 0, 0, 0, SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE Or SWP_RESTORE);
    Dummy := WinSetActiveWindow(HWND_DESKTOP, AHw[R]);
  End
  Else Dummy := KSes(3, ASes[R], 0);
End;

Procedure KillProc;
Var I : LongInt; S : String;
Begin
  If (Sel[TB_PROCS] < 0) Or (Sel[TB_PROCS] >= NP) Then Exit;
  I := Ord_[Sel[TB_PROCS]];
  If PFlg[I] >= 256 Then
  Begin
    ShowMsg('Impossible de terminer ce processus : il fait partie du noyau d''OS/2-0.',
            'Impossible de terminer le processus', MB_OK Or MB_ERROR);
    Exit;
  End;
  S := 'AVERTISSEMENT : Terminer un processus peut provoquer la perte de donn'#130'es non enregistr'#130'es.';
  If (PName[I] = 'PMSHELL.EXE') Or (PName[I] = 'PMSHELL') Then
    S := S + ' PMSHELL est le bureau : il sera arr'#136't'#130'.';
  If Not Ask(S + ' Voulez-vous vraiment terminer ' + PName[I] + ' (PID ' + IStr(PSer[I]) + ') ?',
             'Avertissement du Gestionnaire des t'#131'ches') Then Exit;
  If DosKillProcess(1, PSer[I]) <> 0 Then
    ShowMsg('Impossible de terminer le processus (il est peut-'#136'tre d'#130'j'#133' termin'#130').',
            'Impossible de terminer le processus', MB_OK Or MB_ERROR);
  Refresh;
End;

Procedure SessSwitch;
Begin
  If (Sel[TB_USERS] >= 0) And (Sel[TB_USERS] < NS) Then Dummy := KSes(3, SNo[Sel[TB_USERS]], 0);
End;

Procedure SessClose;
Var R, S : LongInt;
Begin
  If (Sel[TB_USERS] < 0) Or (Sel[TB_USERS] >= NS) Then Exit;
  S := SNo[Sel[TB_USERS]];
  If S = KSes(10, 0, 0) Then
  Begin
    ShowMsg('La session de Presentation Manager ne peut pas '#136'tre ferm'#130'e ici : utilisez Arr'#136't sur le bureau.',
            'Fermer la session', MB_OK Or MB_INFORMATION);
    Exit;
  End;
  If Not Ask('Les programmes de la session ' + IStr(S) + ' vont '#136'tre arr'#136't'#130's. Continuer ?', 'Fermer la session') Then
    Exit;
  For R := 0 To NP - 1 Do
    If (PFlg[R] < 256) And (PSes[R] = S) Then Dummy := DosKillProcess(1, PSer[R]);
  Refresh;
End;

Procedure PressButton(K : LongInt);
Begin
  Case Tab Of
    TB_APPS :
      Case K Of
        0 : EndTask;
        1 : SwitchTo;
        2 : NewTask;
      End;
    TB_PROCS : KillProc;
    TB_USERS :
      Case K Of
        0 : SessSwitch;
        1 : SessClose;
      End;
  End;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEWTASK : NewTask;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_REFRESH : Refresh;
    CM_SPHIGH, CM_SPNORM, CM_SPLOW :
      Begin
        Paused := 0;
        If Id = CM_SPHIGH Then Interval := 500 Else If Id = CM_SPNORM Then Interval := 1000 Else Interval := 4000;
        SetTimer;
        CheckSpeed;
      End;
    CM_SPPAUSE :
      Begin
        Paused := 1;
        SetTimer;
        CheckSpeed;
      End;
    CM_KERNEL :
      Begin
        KernOn := 1 - KernOn;
        CheckSpeed;
        Redraw;
      End;
    CM_HELP : Begin
      LClr;
      LAdd('' +
           'Applications : fen'#136'tres et sessions ; Processus : programmes en cours (cliquez un titre de ' +
           'colonne pour trier) ; Performances : processeur et m'#130'moire ; R'#130'seau : interface lan0 ; ');
      LAdd('' + 'Utilisateurs : sessions. F5 actualise, Suppr termine, Ctrl+Tab change d''onglet.');
      Dummy := LMsgBox('Gestionnaire des t'#131'ches - Aide', MB_OK Or MB_INFORMATION);
    End;
    CM_ABOUT : ShowMsg('Gestionnaire des t'#131'ches d''OS/2-0 : applications, processus, performances, r'#130'seau et ' +
                       'utilisateurs, avec l''apparence d''OS/2 Warp 3. Programme '#130'crit en Pascal et compil'#130' par OS2PC.',
                       'A propos du Gestionnaire des t'#131'ches', MB_OK Or MB_INFORMATION);
  End;
End;

{ --- souris et clavier --- }
Procedure Click(X, Yt : LongInt; Dbl : Boolean);
Var T, K, R, C : LongInt;
Begin
  { onglets }
  If (Yt >= 4) And (Yt < 4 + TABH) Then
  Begin
    For T := 0 To NTAB - 1 Do
      If (X >= TabX(T)) And (X < TabX(T) + Length(TabName(T)) * 8 + 12) Then SelectTab(T);
    Exit;
  End;
  { boutons }
  For K := 0 To BtnCount - 1 Do
    If (X >= BtnX(K)) And (X < BtnX(K) + BtnW_(K)) And (Yt >= BtnYt) And (Yt < BtnYt + BTNH) Then
    Begin
      PressButton(K);
      Exit;
    End;
  If ListCount(Tab) = 0 Then Exit;
  If (Tab <> TB_APPS) And (Tab <> TB_PROCS) And (Tab <> TB_USERS) Then Exit;
  If (X < 10) Or (X > CW - 10) Then Exit;
  { titres de colonnes : tri des processus }
  If (Yt >= ListTop + 2) And (Yt < ListTop + 2 + HDRH) Then
  Begin
    If Tab = TB_PROCS Then
      For C := 0 To NPCOL - 1 Do
        If (X >= PColX(C)) And (X < PColX(C + 1)) Then
        Begin
          If SortCol = C Then SortDesc := 1 - SortDesc
          Else
          Begin
            SortCol := C;
            If C >= 2 Then SortDesc := 1 Else SortDesc := 0;
          End;
          SortProcs;
          KeepSel;
          Redraw;
        End;
    Exit;
  End;
  If (Yt >= ListTop + HDRH + 4) And (Yt < ListBot) Then
  Begin
    R := Top[Tab] + (Yt - ListTop - HDRH - 4) Div ROWH;
    If R < ListCount(Tab) Then
    Begin
      Sel[Tab] := R;
      SelKey[Tab] := RowKey(Tab, R);
      Redraw;
      If Dbl And (Tab = TB_APPS) Then SwitchTo;
      If Dbl And (Tab = TB_USERS) Then SessSwitch;
    End;
  End;
End;

Procedure MoveSel(D : LongInt);
Var N : LongInt;
Begin
  N := ListCount(Tab);
  If N = 0 Then Exit;
  Sel[Tab] := MaxI(0, MinI(N - 1, Sel[Tab] + D));
  SelKey[Tab] := RowKey(Tab, Sel[Tab]);
  If Sel[Tab] < Top[Tab] Then Top[Tab] := Sel[Tab];
  If Sel[Tab] >= Top[Tab] + VisRows Then Top[Tab] := Sel[Tab] - VisRows + 1;
  Redraw;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Fl, Vk : LongInt;
Begin
  MainProc := 0;
  Case Msg Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
      End;
    WM_PAINT : PaintAll(H);
    WM_TIMER :
      Begin
        If Lo16(Mp1) = 2 Then Dummy := WinStopTimer(Hab, Client, 2);
        Refresh;
      End;
    WM_BUTTON1DOWN :
      Begin
        { activation de la fenetre (WinDefWindowProc), puis le clic }
        Dummy := WinDefWindowProc(H, Msg, Mp1, Mp2);
        Click(S16(Mp1), CH - 1 - S16(Mp1 Shr 16), False);
        MainProc := 1;
      End;
    WM_BUTTON1DBLCLK :
      Begin
        { activation de la fenetre (WinDefWindowProc), puis le clic }
        Dummy := WinDefWindowProc(H, Msg, Mp1, Mp2);
        Click(S16(Mp1), CH - 1 - S16(Mp1 Shr 16), True);
        MainProc := 1;
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) Then
          Case Vk Of
            VK_UP : MoveSel(-1);
            VK_DOWN : MoveSel(1);
            VK_PAGEUP : MoveSel(-VisRows);
            VK_PAGEDOWN : MoveSel(VisRows);
            VK_HOME : MoveSel(-1000);
            VK_END : MoveSel(1000);
            VK_F5 : Refresh;
            VK_F1 : Command(CM_HELP);
            VK_DELETE : If Tab = TB_PROCS Then KillProc Else If Tab = TB_APPS Then EndTask;
            VK_ENTER, VK_NEWLINE : If Tab = TB_APPS Then SwitchTo Else If Tab = TB_USERS Then SessSwitch;
            VK_TAB : If (Fl And KC_CTRL) <> 0 Then SelectTab((Tab + 1) Mod NTAB)
                     Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
          Else
            MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
          End
        Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE :
      Begin
        Dummy := WinStopTimer(Hab, Client, 1);
        CloseInput;
        Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
      End;
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Menu (gabarit MENUTEMPLATE)                                           }
{ ==================================================================== }

Procedure MB(V : LongInt);
Begin
  MenuT[MenuLen] := V And 255;
  Inc(MenuLen);
End;

Procedure MW(V : LongInt);
Begin
  MB(V And 255); MB((V Shr 8) And 255);
End;

Function MenuOpen : LongInt;
Begin
  MenuOpen := MenuLen;
  MW(0); MW(0); MW(0);
End;

Procedure MenuClose(H, Count : LongInt);
Begin
  MenuT[H] := (MenuLen - H) And 255; MenuT[H + 1] := ((MenuLen - H) Shr 8) And 255;
  MenuT[H + 4] := Count And 255; MenuT[H + 5] := 0;
End;

Procedure MItem(Style, Id : LongInt; S : String);
Var K : LongInt;
Begin
  MW(Style); MW(0); MW(Id);
  If (Style And MIS_SEPARATOR) = 0 Then
  Begin
    For K := 1 To Length(S) Do MB(Ord(S[K]));
    MB(0);
  End;
End;

Var
  Fl, H0, H1, H2, Sw, Sh, Ww, Wh, K : LongInt;

BEGIN
  Tab := TB_PERF; Interval := 1000; Paused := 0; KernOn := 0;
  LastT := 0; LastIdle := 0; LastKrn := 0; LastSys := 0; SysPct := 0; MemPeakKb := 0; HistCount := 0; GridOff := 0;
  NetOn := 0; NetFn := 0; NetLastPk := -1; NetPkS := 0; NetCard := '';
  SortCol := 2; SortDesc := 1;
  InFr := 0; InCl := 0; InEf := 0; MenuHw := 0; RgbOk := -1;
  For K := 0 To NTAB - 1 Do
  Begin
    Sel[K] := -1; Top[K] := 0; SelKey[K] := -1;
  End;
  For K := 0 To MAXP - 1 Do
  Begin
    OldSer[K] := 0; OldCpu[K] := 0;
  End;
  For K := 0 To HISTN - 1 Do
  Begin
    CpuH[K] := 0; KrnH[K] := 0; MemH[K] := 0; NetH[K] := 0;
  End;
  For K := 0 To 15 Do NetInfo[K] := 0;
  { premier argument : onglet de depart (APPS, PROCS, PERF, NET, USERS) }
  If ParamCount > 0 Then
  Begin
    If UpStr(ParamStr(1)) = 'APPS' Then Tab := TB_APPS
    Else If UpStr(ParamStr(1)) = 'PROCS' Then Tab := TB_PROCS
    Else If UpStr(ParamStr(1)) = 'NET' Then Tab := TB_NET
    Else If UpStr(ParamStr(1)) = 'USERS' Then Tab := TB_USERS;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  Dummy := WinRegisterClass(Hab, Z('TASKMGR'), LongInt(@MainProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('TMInput'), LongInt(@InputProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('TASKMGR'), Z2('Gestionnaire des t'#131'ches d''OS/2-0'),
                              0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 100, '~Fichier');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_NEWTASK, '~Nouvelle t'#131'che (Ex'#130'cuter...)');
  MItem(MIS_SEPARATOR, 0, '');
  MItem(MIS_TEXT, CM_QUIT, '~Quitter le Gestionnaire des t'#131'ches');
  MenuClose(H1, 3);
  MItem(MIS_TEXT Or MIS_SUBMENU, 110, '~Affichage');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_REFRESH, '~Actualiser maintenant' + Chr(9) + 'F5');
  MItem(MIS_TEXT Or MIS_SUBMENU, 116, '~Fr'#130'quence d''actualisation');
  H2 := MenuOpen;
  MItem(MIS_TEXT, CM_SPHIGH, '~Haute (0,5 s)');
  MItem(MIS_TEXT, CM_SPNORM, '~Normale (1 s)');
  MItem(MIS_TEXT, CM_SPLOW, '~Basse (4 s)');
  MItem(MIS_TEXT, CM_SPPAUSE, '~Suspendue');
  MenuClose(H2, 4);
  MItem(MIS_SEPARATOR, 0, '');
  MItem(MIS_TEXT, CM_KERNEL, 'Afficher les temps du ~noyau');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 200, 'A~ide');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_HELP, '~Rubriques d''aide' + Chr(9) + 'F1');
  MItem(MIS_SEPARATOR, 0, '');
  MItem(MIS_TEXT, CM_ABOUT, '~A propos du Gestionnaire des t'#131'ches');
  MenuClose(H1, 3);
  MenuClose(H0, 3);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Ww := MinI(Sw, 504); Wh := MinI(Sh, 540);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - Ww) Div 2), MaxI(0, (Sh - Wh) Div 2), Ww, Wh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  CheckSpeed;
  If Tab = TB_NET Then NetOn := 1;
  Sample;
  SortProcs;
  SetTimer;
  Redraw;
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
