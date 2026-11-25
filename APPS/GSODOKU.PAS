{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: GSODOKU - Generateur de Sodoku pour le Presentation Manager
                d'OS/2-0, base sur GSODOKU.PAS et SSODOKU.PAS du depot VIE.
}

Program GSodoku;

{$R-,S-,I-}

(* Compilation : OS2PC GSODOKU.PAS GSODOKU.EXE

  Generateur de Sodoku (dossier Loisirs du bureau), l'interface graphique
  de GSODOKU.PAS (generateur d'une grille 9 x 9) et de SSODOKU.PAS
  (solveur d'un fichier .SDK) du depot VIE (https://github.com/gladir/vie),
  avec les menus et l'apparence d'OS/2.

    - au centre, l'apercu de la grille : chiffres donnes, reponses, notes,
      solution ; on la joue a la souris et au clavier ;
    - a droite, la partie (niveau, cases, erreurs, temps), le pave des
      chiffres et le nombre de chiffres restants ;
    - barre d'outils : nouvelle grille, ouvrir, enregistrer, exporter,
      regenerer, resoudre, solution, verifier, indice, notes, parametres.

  Generation : grille complete (lignes, colonnes et carres 3 x 3, retour
  arriere aleatoire) ou methode d'origine de GSODOKU (lignes et colonnes
  seulement, 5000 essais) ; puis les cases sont retirees selon le niveau,
  en gardant une solution unique. Resolution : exacte (retour arriere) ou
  methode de SSODOKU (essais aleatoires). /SHOWTRY : nombre d'essais.

  Parametres : [fichier.SDK] [/SHOWTRY] [/S:graine] [/LEVEL:F|M|D|E|n]
  [/CLASSIC] [/SOLVE] [/PUZZLE] [/OUT:fichier] ; avec /OUT, la grille (ou
  la solution du fichier, ou la grille a jouer) est ecrite sans fenetre,
  comme les commandes d'origine. *)

Const
  WM_CREATE = $0001; WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024;
  WM_CLOSE = $0029; WM_QUIT = $002A; WM_VSCROLL = $0031;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
  WM_BUTTON2DOWN = $0074; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20;
  FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000;
  WC_BUTTON = $FFFF0003; WC_ENTRYFIELD = $FFFF0006;
  BS_PUSHBUTTON = 0; BS_AUTOCHECKBOX = 2; BS_DEFAULT = $0400; ES_AUTOSCROLL = 4; ES_MARGIN = 8; ES_UNREADABLE = $40;
  EM_SETTEXTLIMIT = $0143; BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_CHECKED = $2000; MIA_DISABLED = $4000; MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_YESNOCANCEL = 5; MB_INFORMATION = $30; MB_WARNING = $20; MB_ERROR = $40;
  MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6; MBID_NO = 7; MBID_CANCEL = 2;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08; VK_ESC = $0F;
  VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14; VK_LEFT = $15; VK_UP = $16;
  VK_RIGHT = $17; VK_DOWN = $18; VK_INSERT = $1A; VK_DELETE = $1B; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21; VK_F3 = $22; VK_F5 = $24; VK_F6 = $25; VK_F8 = $27; VK_F9 = $28; VK_F12 = $2B;
  SB_LINEUP = 1; SB_LINEDOWN = 2;
  { couleurs de PM }
  cBlue = 1; cRed = 2; cPink = 3; cGreen = 4; cCyan = 5; cYellow = 6; cGray = 8; cNavy = 9; cMaroon = 10;
  cDPink = 11; cDGreen = 12; cTeal = 13; cBrown = 14; cSilver = 15; cWhite = -2; cBlack = -1;
  { dimensions }
  TbH = 30; SbH = 20; RowH = 16; ScrW = 16; TabStop = 2;
  { langages de l'editeur }
  lgText = 0; lgPas = 1;
  MaxDoc = 10;

Type
  TBytes = Array[0..$3FFFFFFF] Of Byte;
  PBytes = ^TBytes;
  TLongs = Array[0..$FFFFFFF] Of LongInt;
  PLongs = ^TLongs;
  PByte = ^Byte;
  PLong = ^LongInt;

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
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryFocus(HD : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt; External 'PMWIN';
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysPointer(HD, Id, Ld : LongInt) : LongInt; External 'PMWIN';
Function WinSetPointer(HD, H : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetNamedSharedMem(PPb, PName, Fl : LongInt) : LongInt; External 'DOSCALLS';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function KTaskCtl(Op, P1, P2, P3 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnTaskCtl';

Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosWaitChild(Action, Option, PRes, PPid, Pid : LongInt) : LongInt; External 'DOSCALLS';
Function DosKillProcess(Action, Pid : LongInt) : LongInt; External 'DOSCALLS';
Function SetStdHandle(N, H : LongInt) : LongInt; External 'DOSCALLS';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinUpdateWindow(H : LongInt) : LongInt; External 'PMWIN';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFileInfo(H, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ofs, Meth, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosCopy(PSrc, PDst, Opt : LongInt) : LongInt; External 'DOSCALLS';

Var
  Dummy : LongInt;
  ZBuf, ZBuf2 : Array[0..299] Of Byte;
  TxtBuf : Array[0..511] Of Byte;

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do ZBuf[K - 1] := Ord(S[K]);
  ZBuf[Length(S)] := 0;
  Z := LongInt(@ZBuf);
End;

Function Z2(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do ZBuf2[K - 1] := Ord(S[K]);
  ZBuf2[Length(S)] := 0;
  Z2 := LongInt(@ZBuf2);
End;

Function RdB(A : LongInt) : LongInt;
Var Q : PByte;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Function RdL(A : LongInt) : LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function Z2D(V : LongInt) : String;
Begin
  If V < 10 Then Z2D := '0' + IStr(V) Else Z2D := IStr(V);
End;

Function SVal(S : String) : LongInt;
Var V, E : LongInt;
Begin
  Val(S, V, E);
  If E <> 0 Then V := 0;
  SVal := V;
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

Function LoStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'A') And (S[K] <= 'Z') Then S[K] := Chr(Ord(S[K]) + 32);
  LoStr := S;
End;

Function Trim(S : String) : String;
Begin
  While (Length(S) > 0) And (S[1] <= ' ') Do Delete(S, 1, 1);
  While (Length(S) > 0) And (S[Length(S)] <= ' ') Do Delete(S, Length(S), 1);
  Trim := S;
End;

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
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
  If V >= 32768 Then V := V - 65536;
  S16 := V;
End;

Function ExtOf(N : String) : String;
Var K : LongInt;
Begin
  ExtOf := '';
  K := Length(N);
  While (K > 0) And (N[K] <> '.') And (N[K] <> '\') Do Dec(K);
  If (K > 0) And (N[K] = '.') Then ExtOf := UpStr(Copy(N, K + 1, 10));
End;

Function NameOf(N : String) : String;
Var K : LongInt;
Begin
  K := Length(N);
  While (K > 0) And (N[K] <> '\') And (N[K] <> ':') Do Dec(K);
  NameOf := Copy(N, K + 1, 255);
End;

Function DirOf(N : String) : String;
Var K : LongInt;
Begin
  K := Length(N);
  While (K > 0) And (N[K] <> '\') Do Dec(K);
  If K = 0 Then DirOf := ''
  Else If (K = 3) And (N[2] = ':') Then DirOf := Copy(N, 1, 2)
  Else DirOf := Copy(N, 1, K - 1);
End;

Function EnvStr(Name : String) : String;
Var P, K : LongInt; S : String;
Begin
  P := 0; S := '';
  If DosScanEnv(Z(Name), LongInt(@P)) = 0 Then
  Begin
    K := 0;
    While (RdB(P + K) <> 0) And (K < 250) Do
    Begin
      S := S + Chr(RdB(P + K));
      Inc(K);
    End;
  End;
  EnvStr := S;
End;

Function PTicks : LongInt;
Begin
  PTicks := KTicks;
End;

Procedure PSleep(Ms : LongInt);
Begin
  Dummy := DosSleep(Ms);
End;

{ --- fichiers (DOSCALLS) --- }

Function FOpenRead(Name : String; Var H : LongInt) : Boolean;
Var A : LongInt;
Begin
  H := 0; A := 0;
  FOpenRead := DosOpen(Z(Name), LongInt(@H), LongInt(@A), 0, 0, 1, $40, 0) = 0;
End;

Function FOpenWrite(Name : String; Var H : LongInt) : Boolean;
Var A : LongInt;
Begin
  H := 0; A := 0;
  FOpenWrite := DosOpen(Z(Name), LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0) = 0;
End;

Function FRead(H : LongInt; P : PBytes; N : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := 0;
  If DosRead(H, LongInt(P), N, LongInt(@A)) <> 0 Then FRead := -1 Else FRead := A;
End;

Function FWrite(H : LongInt; P : PBytes; N : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := 0;
  If DosWrite(H, LongInt(P), N, LongInt(@A)) <> 0 Then FWrite := -1 Else FWrite := A;
End;

Function FExists(Name : String) : Boolean;
Var Info : Array[0..63] Of Byte;
Begin
  FExists := DosQueryPathInfo(Z(Name), 1, LongInt(@Info), 64) = 0;
End;

{ tampon d'octets qui grandit }
Type
  TBuf = Record
    P : PBytes;
    Len, Cap : LongInt;
  End;

Procedure BufInit(Var B : TBuf);
Begin
  B.P := Nil; B.Len := 0; B.Cap := 0;
End;

Procedure BufFree(Var B : TBuf);
Begin
  If B.P <> Nil Then FreeMem(B.P, B.Cap);
  BufInit(B);
End;

Function BufGrow(Var B : TBuf; Need : LongInt) : Boolean;
Var NC : LongInt; Q : PBytes;
Begin
  BufGrow := True;
  If B.Len + Need <= B.Cap Then Exit;
  NC := B.Cap * 2;
  If NC < 256 Then NC := 256;
  While NC < B.Len + Need Do NC := NC * 2;
  GetMem(Q, NC);
  If Q = Nil Then
  Begin
    BufGrow := False;
    Exit;
  End;
  If B.Len > 0 Then Move(B.P^[0], Q^[0], B.Len);
  If B.P <> Nil Then FreeMem(B.P, B.Cap);
  B.P := Q; B.Cap := NC;
End;

Procedure BufAddB(Var B : TBuf; P : PBytes; N : LongInt);
Begin
  If N <= 0 Then Exit;
  If Not BufGrow(B, N) Then Exit;
  Move(P^[0], B.P^[B.Len], N);
  B.Len := B.Len + N;
End;

Procedure BufAddC(Var B : TBuf; V : LongInt);
Begin
  If Not BufGrow(B, 1) Then Exit;
  B.P^[B.Len] := V And 255;
  Inc(B.Len);
End;

Procedure BufAdd(Var B : TBuf; S : String);
Begin
  If Length(S) > 0 Then BufAddB(B, @S[1], Length(S));
End;

{ --- CP850 et UTF-8 --- }
Const
  U850 : Array[128..255] Of Word = (
    $C7, $FC, $E9, $E2, $E4, $E0, $E5, $E7, $EA, $EB, $E8, $EF, $EE, $EC, $C4, $C5,
    $C9, $E6, $C6, $F4, $F6, $F2, $FB, $F9, $FF, $D6, $DC, $F8, $A3, $D8, $D7, $192,
    $E1, $ED, $F3, $FA, $F1, $D1, $AA, $BA, $BF, $AE, $AC, $BD, $BC, $A1, $AB, $BB,
    $2591, $2592, $2593, $2502, $2524, $C1, $C2, $C0, $A9, $2563, $2551, $2557, $255D, $A2, $A5, $2510,
    $2514, $2534, $252C, $251C, $2500, $253C, $E3, $C3, $255A, $2554, $2569, $2566, $2560, $2550, $256C, $A4,
    $F0, $D0, $CA, $CB, $C8, $131, $CD, $CE, $CF, $2518, $250C, $2588, $2584, $A6, $CC, $2580,
    $D3, $DF, $D4, $D2, $F5, $D5, $B5, $FE, $DE, $DA, $DB, $D9, $FD, $DD, $AF, $B4,
    $AD, $B1, $2017, $BE, $B6, $A7, $F7, $B8, $B0, $A8, $B7, $B9, $B3, $B2, $25A0, $A0);

{ caractere CP850 d'un point de code Unicode ; -1 : aucun }
Function Uni850(U : LongInt) : LongInt;
Var K : LongInt;
Begin
  Uni850 := -1;
  If U < 128 Then
  Begin
    Uni850 := U;
    Exit;
  End;
  For K := 128 To 255 Do
    If U850[K] = U Then
    Begin
      Uni850 := K;
      Exit;
    End;
End;
{ ==================================================================== }
{ Moteur : GSODOKU (generation), SSODOKU (resolution), grille a jouer   }
{ ==================================================================== }

Const
  VersionStr = '1.00';
  { niveaux : nombre de cases donnees vise }
  lvEasy = 0; lvMedium = 1; lvHard = 2; lvExpert = 3; lvCustom = 4;

Type
  TGrid = Array[1..9, 1..9] Of LongInt;

Var
  Sol : TGrid;              { grille complete (solution) }
  Giv : TGrid;              { cases donnees de la grille a jouer (0 : vide) }
  Usr : TGrid;              { reponses du joueur }
  Notes : TGrid;            { notes : bits 1..9 }
  Bad : Array[1..9, 1..9] Of Boolean;
  Work : TGrid;
  { options (GSODOKU, SSODOKU et grille a jouer) }
  OptBoxes : Boolean;       { regle des carres 3 x 3 (sinon : methode d'origine, lignes et colonnes) }
  OptShowTry : Boolean;     { /SHOWTRY }
  OptUnique : Boolean;      { solution unique }
  OptSym : Boolean;         { cases retirees en symetrie centrale }
  OptLevel, OptGivens : LongInt;
  OptMaxTry : LongInt;      { essais de la methode d'origine (5000) }
  OptSolveTries : LongInt;  { essais de la methode de SSODOKU (2 000 000) }
  OptSolveOrig : Boolean;   { resoudre par la methode de SSODOKU }
  OptSeed, LastSeed : LongInt;
  OptHasSeed : Boolean;
  { resultats }
  GenTries, GenOk, SolveTries, NGiven : LongInt;
  GenMsg : String;
  Ready, FromFile : Boolean;
  { generateur pseudo-aleatoire (meme graine : meme grille) }
  RSeed : LongInt;
  OutB : TBuf;
  NodeCount : LongInt;

Procedure RndInit(S : LongInt);
Begin
  RSeed := S And $7FFFFFFF;
  If RSeed = 0 Then RSeed := 12345;
End;

Function Rnd(N : LongInt) : LongInt;
Begin
  RSeed := (RSeed * 1103515245 + 12345) And $7FFFFFFF;
  If N <= 1 Then Rnd := 0 Else Rnd := (RSeed Shr 8) Mod N;
End;

Function LevelName(L : LongInt) : String;
Var R : String;
Begin
  Case L Of
    lvEasy : R := 'Facile';
    lvMedium : R := 'Moyen';
    lvHard : R := 'Difficile';
    lvExpert : R := 'Expert';
  Else
    R := 'Personnalis'#130;
  End;
  LevelName := R;
End;

Function LevelGivens(L : LongInt) : LongInt;
Begin
  Case L Of
    lvEasy : LevelGivens := 40;
    lvMedium : LevelGivens := 32;
    lvHard : LevelGivens := 27;
    lvExpert : LevelGivens := 23;
  Else
    LevelGivens := OptGivens;
  End;
End;

Procedure ClearGrid(Var G : TGrid);
Var X, Y : LongInt;
Begin
  For Y := 1 To 9 Do
    For X := 1 To 9 Do G[Y, X] := 0;
End;

{ ---------------------------------------------------------------------- }
{ Methode d'origine de GSODOKU : chaque ligne est une permutation de 1 a  }
{ 9, en evitant les chiffres deja dans la colonne (pas les carres 3 x 3)  }
{ ---------------------------------------------------------------------- }

Function VerticalFound(X, YMax, Number : LongInt) : Boolean;
Var J : LongInt;
Begin
  VerticalFound := False;
  For J := 1 To YMax Do
    If Sol[J, X] = Number Then
    Begin
      VerticalFound := True;
      Exit;
    End;
End;

Function FindZero(Var G : TGrid) : Boolean;
Var I, J : LongInt;
Begin
  FindZero := False;
  For J := 1 To 9 Do
    For I := 1 To 9 Do
      If G[J, I] = 0 Then FindZero := True;
End;

Procedure DelAt(Var B : String; P : LongInt);
Begin
  Delete(B, P, 1);
End;

{ rend le nombre d'essais (0 : echec apres OptMaxTry essais) }
Function GenOriginal : LongInt;
Var Base : String; I, J, K, L, R : LongInt; Done : Boolean;
Begin
  GenOriginal := 0;
  For K := 1 To OptMaxTry Do
  Begin
    ClearGrid(Sol);
    For J := 1 To 9 Do
    Begin
      Base := '';
      For I := 1 To 9 Do Base := Base + Chr(I);
      For I := 1 To 9 Do
      Begin
        R := Rnd(Length(Base)) + 1;
        If VerticalFound(I, J, Ord(Base[R])) Then
        Begin
          For L := 1 To Length(Base) Do
            If Not VerticalFound(I, J, Ord(Base[L])) Then
            Begin
              Sol[J, I] := Ord(Base[L]);
              DelAt(Base, L);
              Break;
            End;
        End
        Else
        Begin
          Sol[J, I] := Ord(Base[R]);
          DelAt(Base, R);
        End;
      End;
    End;
    Done := Not FindZero(Sol);
    If Done Then
    Begin
      GenOriginal := K;
      Exit;
    End;
  End;
End;

{ ---------------------------------------------------------------------- }
{ Regles : peut-on mettre V en (Y, X) dans G ?                            }
{ ---------------------------------------------------------------------- }

Function CanPut(Var G : TGrid; Y, X, V : LongInt) : Boolean;
Var K, BX, BY, I, J : LongInt;
Begin
  CanPut := False;
  For K := 1 To 9 Do
  Begin
    If (K <> X) And (G[Y, K] = V) Then Exit;
    If (K <> Y) And (G[K, X] = V) Then Exit;
  End;
  If OptBoxes Then
  Begin
    BY := ((Y - 1) Div 3) * 3; BX := ((X - 1) Div 3) * 3;
    For J := BY + 1 To BY + 3 Do
      For I := BX + 1 To BX + 3 Do
        If ((J <> Y) Or (I <> X)) And (G[J, I] = V) Then Exit;
  End;
  CanPut := True;
End;

{ ---------------------------------------------------------------------- }
{ Grille complete aleatoire par retour arriere                           }
{ ---------------------------------------------------------------------- }

Function FillRandom(Var G : TGrid; Pos : LongInt) : Boolean;
Var Y, X, K, T, V : LongInt; Ord_ : Array[1..9] Of LongInt;
Begin
  If Pos > 81 Then
  Begin
    FillRandom := True;
    Exit;
  End;
  Y := (Pos - 1) Div 9 + 1; X := (Pos - 1) Mod 9 + 1;
  If G[Y, X] <> 0 Then
  Begin
    FillRandom := FillRandom(G, Pos + 1);
    Exit;
  End;
  For K := 1 To 9 Do Ord_[K] := K;
  For K := 9 DownTo 2 Do
  Begin
    T := Rnd(K) + 1;
    V := Ord_[K]; Ord_[K] := Ord_[T]; Ord_[T] := V;
  End;
  Inc(GenTries);
  For K := 1 To 9 Do
    If CanPut(G, Y, X, Ord_[K]) Then
    Begin
      G[Y, X] := Ord_[K];
      If FillRandom(G, Pos + 1) Then
      Begin
        FillRandom := True;
        Exit;
      End;
      G[Y, X] := 0;
    End;
  FillRandom := False;
End;

{ ---------------------------------------------------------------------- }
{ Resolution exacte : nombre de solutions (jusqu'a Limit), la premiere   }
{ dans Work (case la plus contrainte d'abord)                            }
{ ---------------------------------------------------------------------- }

Var
  SolCount, SolLimit : LongInt;
  FirstSol : TGrid;

Procedure SolveRec(Var G : TGrid);
Var Y, X, BY, BX, BestN, N, V : LongInt; Found : Boolean;
Begin
  If SolCount >= SolLimit Then Exit;
  Inc(NodeCount);
  If NodeCount > 400000 Then Exit;
  BestN := 10; BY := 0; BX := 0; Found := False;
  For Y := 1 To 9 Do
    For X := 1 To 9 Do
      If G[Y, X] = 0 Then
      Begin
        Found := True;
        N := 0;
        For V := 1 To 9 Do If CanPut(G, Y, X, V) Then Inc(N);
        If N < BestN Then
        Begin
          BestN := N; BY := Y; BX := X;
          If N = 0 Then Exit;
        End;
      End;
  If Not Found Then
  Begin
    Inc(SolCount);
    If SolCount = 1 Then FirstSol := G;
    Exit;
  End;
  For V := 1 To 9 Do
    If CanPut(G, BY, BX, V) Then
    Begin
      G[BY, BX] := V;
      SolveRec(G);
      G[BY, BX] := 0;
      If SolCount >= SolLimit Then Exit;
    End;
End;

{ nombre de solutions de G (0, 1 ou Limit) ; la premiere dans FirstSol }
Function CountSolutions(G : TGrid; Limit : LongInt) : LongInt;
Begin
  SolCount := 0; SolLimit := Limit; NodeCount := 0;
  SolveRec(G);
  CountSolutions := SolCount;
End;

{ les chiffres donnes respectent-ils les regles ? }
Function GridValid(Var G : TGrid) : Boolean;
Var X, Y, V : LongInt;
Begin
  GridValid := False;
  For Y := 1 To 9 Do
    For X := 1 To 9 Do
    Begin
      V := G[Y, X];
      If V <> 0 Then
      Begin
        G[Y, X] := 0;
        If Not CanPut(G, Y, X, V) Then
        Begin
          G[Y, X] := V;
          Exit;
        End;
        G[Y, X] := V;
      End;
    End;
  GridValid := True;
End;

{ ---------------------------------------------------------------------- }
{ Methode de SSODOKU : lignes completees au hasard avec les chiffres     }
{ manquants, en evitant ceux de la colonne ; essais repetes              }
{ ---------------------------------------------------------------------- }

Function SolveOriginal(Var L : TGrid) : LongInt;
Var Base : String; K, I, J, M, R : LongInt; Skip : Boolean;
Begin
  SolveOriginal := 0;
  For K := 1 To OptSolveTries Do
  Begin
    Work := L;
    For J := 1 To 9 Do
    Begin
      Base := '';
      For I := 1 To 9 Do
      Begin
        Skip := False;
        For M := 1 To 9 Do If L[J, M] = I Then Skip := True;
        If Not Skip Then Base := Base + Chr(I);
      End;
      For I := 1 To 9 Do
        If (Work[J, I] = 0) And (Base <> '') Then
        Begin
          R := Rnd(Length(Base)) + 1;
          { comme SSODOKU : le chiffre ne doit pas deja etre dans la colonne }
          Skip := False;
          For M := 1 To 9 Do If (M <> J) And (Work[M, I] = Ord(Base[R])) Then Skip := True;
          If Skip Then
          Begin
            For M := 1 To Length(Base) Do
            Begin
              Skip := False;
              For R := 1 To 9 Do If (R <> J) And (Work[R, I] = Ord(Base[M])) Then Skip := True;
              If Not Skip Then
              Begin
                Work[J, I] := Ord(Base[M]);
                DelAt(Base, M);
                Break;
              End;
            End;
          End
          Else
          Begin
            Work[J, I] := Ord(Base[R]);
            DelAt(Base, R);
          End;
        End;
    End;
    If Not FindZero(Work) Then
      If (Not OptBoxes) Or GridValid(Work) Then
      Begin
        SolveOriginal := K;
        Exit;
      End;
  End;
End;

{ ---------------------------------------------------------------------- }
{ Grille a jouer : on retire des cases tant que la solution reste unique }
{ ---------------------------------------------------------------------- }

Procedure MakePuzzle;
Var Ord_ : Array[1..81] Of LongInt; K, T, V, Y, X, Y2, X2, Target, N, Keep, Keep2 : LongInt;
Begin
  Giv := Sol;
  Target := LevelGivens(OptLevel);
  If Target < 17 Then Target := 17;
  If Target > 81 Then Target := 81;
  For K := 1 To 81 Do Ord_[K] := K;
  For K := 81 DownTo 2 Do
  Begin
    T := Rnd(K) + 1;
    V := Ord_[K]; Ord_[K] := Ord_[T]; Ord_[T] := V;
  End;
  N := 81;
  For K := 1 To 81 Do
  Begin
    If N <= Target Then Break;
    Y := (Ord_[K] - 1) Div 9 + 1; X := (Ord_[K] - 1) Mod 9 + 1;
    If Giv[Y, X] = 0 Then Continue;
    Y2 := 10 - Y; X2 := 10 - X;
    Keep := Giv[Y, X]; Keep2 := Giv[Y2, X2];
    Giv[Y, X] := 0;
    If OptSym Then Giv[Y2, X2] := 0;
    If OptUnique And (CountSolutions(Giv, 2) <> 1) Then
    Begin
      Giv[Y, X] := Keep;
      Giv[Y2, X2] := Keep2;
    End
    Else
    Begin
      Dec(N);
      If OptSym And ((Y2 <> Y) Or (X2 <> X)) And (Keep2 <> 0) Then Dec(N);
    End;
  End;
  NGiven := 0;
  For Y := 1 To 9 Do
    For X := 1 To 9 Do If Giv[Y, X] <> 0 Then Inc(NGiven);
End;

Procedure ResetPlay;
Var X, Y : LongInt;
Begin
  For Y := 1 To 9 Do
    For X := 1 To 9 Do
    Begin
      Usr[Y, X] := 0; Notes[Y, X] := 0; Bad[Y, X] := False;
    End;
End;

{ nouvelle grille ; rend False en cas d'echec (methode d'origine) }
Function Generate : Boolean;
Begin
  Generate := False;
  If OptHasSeed Then LastSeed := OptSeed Else LastSeed := (PTicks * 7919 + RSeed) And $7FFFFFF;
  RndInit(LastSeed);
  GenTries := 0;
  If OptBoxes Then
  Begin
    ClearGrid(Sol);
    If FillRandom(Sol, 1) Then GenOk := 1 Else GenOk := 0;
    GenMsg := 'Grille compl'#138'te par retour arri'#138're : ' + IStr(GenTries) + ' essais de cases';
  End
  Else
  Begin
    GenTries := GenOriginal;
    If GenTries > 0 Then GenOk := 1 Else GenOk := 0;
    If GenTries > 0 Then GenMsg := 'Nombre d''essais : ' + IStr(GenTries)
    Else GenMsg := 'Nombre d''essais insuffisant ! (' + IStr(OptMaxTry) + ')';
  End;
  If GenOk = 0 Then Exit;
  MakePuzzle;
  ResetPlay;
  FromFile := False;
  Ready := True;
  Generate := True;
End;

{ ---------------------------------------------------------------------- }
{ Fichiers .SDK : 9 lignes, chiffres 1 a 9, autre caractere : case vide   }
{ (accepte aussi les lignes "5 3 4 ..." produites par GSODOKU)            }
{ ---------------------------------------------------------------------- }

Function LoadSdk(Name : String; Var G : TGrid) : Boolean;
Var H, R, St, E, N, Y, K, X : LongInt; B : TBuf; S, T : String;
Begin
  LoadSdk := False;
  If Not FOpenRead(Name, H) Then Exit;
  BufInit(B);
  Repeat
    If Not BufGrow(B, 4096) Then Break;
    R := FRead(H, @B.P^[B.Len], 4096);
    If R > 0 Then B.Len := B.Len + R;
  Until R <= 0;
  DosClose(H);
  ClearGrid(G);
  Y := 0; St := 0;
  For E := 0 To B.Len Do
    If ((E = B.Len) Or (B.P^[E] = 10)) And (Y < 9) Then
    Begin
      N := MinI(E - St, 255);
      S[0] := Chr(MaxI(0, N));
      If N > 0 Then Move(B.P^[St], S[1], N);
      St := E + 1;
      While (Length(S) > 0) And (S[Length(S)] = #13) Do Delete(S, Length(S), 1);
      If (S <> '') And ((S[1] = ';') Or (S[1] = '#')) Then Continue;
      If (E = B.Len) And (Trim(S) = '') Then Continue;
      { "5 3 4 6 ..." : chiffres separes par des espaces }
      T := S;
      If (Length(Trim(S)) >= 17) And (Trim(S)[2] = ' ') Then
      Begin
        T := '';
        For K := 1 To Length(S) Do If S[K] <> ' ' Then T := T + S[K];
      End;
      Inc(Y);
      For X := 1 To 9 Do
        If (X <= Length(T)) And (T[X] >= '1') And (T[X] <= '9') Then G[Y, X] := Ord(T[X]) - 48;
    End;
  BufFree(B);
  LoadSdk := True;
End;

{ grille G en texte : Sdk (9 caracteres, '.' pour une case vide) ou
  "5 3 4 ..." comme GSODOKU et SSODOKU }
Procedure GridText(Var G : TGrid; Sdk : Boolean);
Var X, Y : LongInt; S : String;
Begin
  For Y := 1 To 9 Do
  Begin
    S := '';
    For X := 1 To 9 Do
      If Sdk Then
      Begin
        If G[Y, X] = 0 Then S := S + '.' Else S := S + Chr(48 + G[Y, X]);
      End
      Else
      Begin
        If G[Y, X] = 0 Then S := S + '. ' Else S := S + Chr(48 + G[Y, X]) + ' ';
      End;
    BufAdd(OutB, S + #13#10);
  End;
End;

Function SaveSdk(Name : String; Var G : TGrid) : Boolean;
Var H : LongInt;
Begin
  SaveSdk := False;
  OutB.Len := 0;
  GridText(G, True);
  If FOpenWrite(Name, H) Then
  Begin
    SaveSdk := FWrite(H, OutB.P, OutB.Len) = OutB.Len;
    DosClose(H);
  End;
End;

{ grille dessinee en texte (cadre des carres 3 x 3) }
Procedure GridBox(Var G : TGrid);
Var X, Y : LongInt; S : String;
Begin
  For Y := 1 To 9 Do
  Begin
    If (Y - 1) Mod 3 = 0 Then BufAdd(OutB, '+-------+-------+-------+'#13#10);
    S := '';
    For X := 1 To 9 Do
    Begin
      If (X - 1) Mod 3 = 0 Then S := S + '| ';
      If G[Y, X] = 0 Then S := S + '. ' Else S := S + Chr(48 + G[Y, X]) + ' ';
    End;
    BufAdd(OutB, S + '|'#13#10);
  End;
  BufAdd(OutB, '+-------+-------+-------+'#13#10);
End;

{ page HTML : grille a jouer et solution }
Procedure HtmlGrid(Var G : TGrid);
Var X, Y : LongInt; S : String;
Begin
  BufAdd(OutB, '<table class="sd">'#13#10);
  For Y := 1 To 9 Do
  Begin
    S := '<tr>';
    For X := 1 To 9 Do
    Begin
      S := S + '<td';
      If (X Mod 3 = 0) And (X < 9) Then S := S + ' class="r"';
      If (Y Mod 3 = 0) And (Y < 9) Then S := S + ' style="border-bottom:3px solid #000"';
      S := S + '>';
      If G[Y, X] <> 0 Then S := S + Chr(48 + G[Y, X]);
      S := S + '</td>';
    End;
    BufAdd(OutB, S + '</tr>'#13#10);
  End;
  BufAdd(OutB, '</table>'#13#10);
End;

Procedure ExportText(WithSol, WithPlay : Boolean);
Begin
  OutB.Len := 0;
  BufAdd(OutB, 'Sodoku - niveau ' + LevelName(OptLevel) + ' (' + IStr(NGiven) + ' cases donn'#130'es) - graine ' +
         IStr(LastSeed) + #13#10#13#10);
  If WithPlay Then GridBox(Giv);
  If WithSol Then
  Begin
    BufAdd(OutB, #13#10'Solution'#13#10#13#10);
    GridBox(Sol);
  End;
End;

Procedure ExportHtml(WithSol, WithPlay : Boolean);
Begin
  OutB.Len := 0;
  BufAdd(OutB, '<!DOCTYPE html>'#13#10'<html><head><meta charset="utf-8"><title>Sodoku</title>'#13#10);
  BufAdd(OutB, '<style>body{font-family:sans-serif;margin:20px}table.sd{border-collapse:collapse;border:3px solid #000;');
  BufAdd(OutB, 'margin:10px 0}table.sd td{width:36px;height:36px;border:1px solid #888;text-align:center;');
  BufAdd(OutB, 'font:bold 20px sans-serif}table.sd td.r{border-right:3px solid #000}</style></head><body>'#13#10);
  BufAdd(OutB, '<h1>Sodoku</h1><p>Niveau ' + LevelName(OptLevel) + ', ' + IStr(NGiven) + ' cases donn&eacute;es, graine ' +
         IStr(LastSeed) + '</p>'#13#10);
  If WithPlay Then HtmlGrid(Giv);
  If WithSol Then
  Begin
    BufAdd(OutB, '<h2>Solution</h2>'#13#10);
    HtmlGrid(Sol);
  End;
  BufAdd(OutB, '</body></html>'#13#10);
End;

Function ParseNum(S : String; Lo, Hi : LongInt; Var V : LongInt) : Boolean;
Var N, E : LongInt; Ok : Boolean;
Begin
  S := Trim(S);
  Val(S, N, E);
  Ok := (E = 0) And (S <> '') And (N >= Lo) And (N <= Hi);
  If Ok Then V := N;
  ParseNum := Ok;
End;

Procedure InitDefaults;
Begin
  OptBoxes := True; OptShowTry := False; OptUnique := True; OptSym := True;
  OptLevel := lvMedium; OptGivens := 30; OptMaxTry := 5000; OptSolveTries := 2000000; OptSolveOrig := False;
  OptSeed := 0; OptHasSeed := False; LastSeed := 0;
  GenTries := 0; GenOk := 0; SolveTries := 0; NGiven := 0; GenMsg := '';
  Ready := False; FromFile := False;
  RSeed := 12345;
  ClearGrid(Sol); ClearGrid(Giv); ResetPlay;
End;

{ ==================================================================== }
{ Fenetre : etat, disposition et dessin                                 }
{ ==================================================================== }

Const
  PnW = 270; MaxTb = 24; MaxUndo = 400;
  { commandes }
  cmNew = 100; cmOpen = 101; cmSave = 102; cmSaveAs = 103; cmExport = 104; cmQuit = 105; cmCopyText = 106;
  cmSaveSol = 107;
  cmGenerate = 120; cmSameSeed = 121; cmParams = 122; cmSeed = 123; cmLog = 124; cmSolve = 125; cmEdit = 126;
  cmEditDone = 127;
  cmLvl0 = 130;              { + niveau (0 a 4) }
  cmShowSol = 140; cmPeers = 141; cmAutoCheck = 142; cmToolbar = 143; cmShowNotes = 144; cmSameDigit = 145;
  cmCheck = 150; cmHint = 151; cmClearAns = 152; cmNotesMode = 153; cmUndo = 154; cmAutoNotes = 155; cmRestart = 156;
  cmBoxes = 160; cmShowTry = 161; cmUnique = 162; cmSym = 163;
  cmHelp = 170; cmOpts = 171; cmAbout = 172;
  cmDigit0 = 180;            { + chiffre (pave) }

Var
  Hab, Hmq, Frame, Client, MenuHw, Hps, CW, CH : LongInt;
  GQmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..8191] Of Byte;
  MenuLen : LongInt;
  UX1, UY1, UX2, UY2 : LongInt;
  IcX, IcY : LongInt;
  Y0, Y1, PnX, BX0, BY0, Cs : LongInt;
  ShowSolution, ShowPeers, AutoCheck, ShowToolbar, ShowNotes, SameDigit : Boolean;
  NotesMode, Checked, Solved, EditMode : Boolean;
  CurX, CurY, Errors, Elapsed, Hints : LongInt;
  { annulation }
  UndoN : LongInt;
  UndoY, UndoX, UndoV, UndoNt : Array[0..MaxUndo - 1] Of LongInt;
  { barre d'outils }
  NTb, TbDown, TbHot : LongInt;
  TbCmd, TbX, TbW, TbIco : Array[0..MaxTb - 1] Of LongInt;
  TbTxt, TbTip : Array[0..MaxTb - 1] Of String;
  StatusMsg, SavedMsg, GridName : String;

Procedure PutZ(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do TxtBuf[K - 1] := Ord(S[K]);
  TxtBuf[Length(S)] := 0;
End;

Procedure FBar(X1, Y1_, X2, Y2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (X2 < X1) Or (Y2 < Y1_) Then Exit;
  If (X2 < UX1) Or (X1 > UX2) Or (Y2 < UY1) Or (Y1_ > UY2) Then Exit;
  Rc[0] := X1; Rc[1] := CH - 1 - Y2; Rc[2] := X2 + 1; Rc[3] := CH - Y1_;
  Dummy := WinFillRect(Hps, LongInt(@Rc), C);
End;

Procedure HLine(X1, X2, Y, C : LongInt);
Begin
  FBar(X1, Y, X2, Y, C);
End;

Procedure VLine(X, Y1_, Y2, C : LongInt);
Begin
  FBar(X, Y1_, X, Y2, C);
End;

Procedure Box(X1, Y1_, X2, Y2, C : LongInt);
Begin
  HLine(X1, X2, Y1_, C); HLine(X1, X2, Y2, C);
  VLine(X1, Y1_, Y2, C); VLine(X2, Y1_, Y2, C);
End;

Procedure Edge(X1, Y1_, X2, Y2, Lt, Dk : LongInt);
Begin
  HLine(X1, X2, Y1_, Lt); VLine(X1, Y1_, Y2, Lt);
  HLine(X1, X2, Y2, Dk); VLine(X2, Y1_, Y2, Dk);
End;

Procedure Raised(X1, Y1_, X2, Y2 : LongInt);
Begin
  FBar(X1, Y1_, X2, Y2, cSilver);
  Edge(X1, Y1_, X2, Y2, cWhite, cGray);
End;

Procedure Sunken(X1, Y1_, X2, Y2, F : LongInt);
Begin
  FBar(X1 + 1, Y1_ + 1, X2 - 1, Y2 - 1, F);
  Edge(X1, Y1_, X2, Y2, cGray, cWhite);
End;

Procedure OutTxt(X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  If (Y + 15 < UY1) Or (Y > UY2) Or (X > UX2) Or (X + Length(S) * 8 < UX1) Then Exit;
  PutZ(S);
  Rc[0] := X; Rc[1] := CH - Y - 16; Rc[2] := X + Length(S) * 8; Rc[3] := CH - Y;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

Function Fit(S : String; W : LongInt) : String;
Var N : LongInt;
Begin
  N := W Div 8;
  If N < 0 Then N := 0;
  If Length(S) > N Then
  Begin
    If N > 3 Then S := Copy(S, 1, N - 3) + '...' Else S := Copy(S, 1, N);
  End;
  Fit := S;
End;

Procedure InvalBand(X1, Y1_, X2, Y2 : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[0] := X1; Rc[1] := CH - Y2; Rc[2] := X2; Rc[3] := CH - Y1_;
  Dummy := WinInvalidateRect(Client, LongInt(@Rc), 0);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

Procedure IR(X1, Y1_, X2, Y2, C : LongInt);
Begin
  FBar(IcX + X1, IcY + Y1_, IcX + X2, IcY + Y2, C);
End;

Procedure IB(X1, Y1_, X2, Y2, C : LongInt);
Begin
  IR(X1, Y1_, X2, Y1_, C); IR(X1, Y2, X2, Y2, C); IR(X1, Y1_, X1, Y2, C); IR(X2, Y1_, X2, Y2, C);
End;

Procedure Disc(Cx, Cy, R, C : LongInt);
Var Dy, H : LongInt;
Begin
  For Dy := -R To R Do
  Begin
    H := 0;
    While (H + 1) * (H + 1) + Dy * Dy <= R * R Do Inc(H);
    HLine(Cx - H, Cx + H, Cy + Dy, C);
  End;
End;

Procedure Thick(X1, Y1_, X2, Y2, C : LongInt);
Var K, N, X, Y : LongInt;
Begin
  N := MaxI(Abs(X2 - X1), Abs(Y2 - Y1_));
  If N = 0 Then N := 1;
  For K := 0 To N Do
  Begin
    X := X1 + (X2 - X1) * K Div N; Y := Y1_ + (Y2 - Y1_) * K Div N;
    FBar(X, Y, X + 1, Y + 1, C);
  End;
End;


Procedure PaintVScroll(X, Ya, Yb, Pos_, Max_, Page : LongInt);
Var T, Th, Ty, I : LongInt;
Begin
  Raised(X, Ya, X + ScrW - 1, Ya + ScrW - 1);
  For I := 0 To 3 Do HLine(X + 7 - I, X + 8 + I, Ya + 5 + I, cBlack);
  Raised(X, Yb - ScrW + 1, X + ScrW - 1, Yb);
  For I := 0 To 3 Do HLine(X + 7 - I, X + 8 + I, Yb - 5 - I, cBlack);
  T := Yb - Ya + 1 - 2 * ScrW;
  FBar(X, Ya + ScrW, X + ScrW - 1, Yb - ScrW, cWhite);
  VLine(X, Ya + ScrW, Yb - ScrW, cSilver);
  If (T <= 8) Or (Max_ <= 0) Then Exit;
  Th := MaxI(10, T * Page Div (Max_ + Page));
  If Th > T Then Th := T;
  Ty := Ya + ScrW + (T - Th) * Pos_ Div Max_;
  Raised(X, Ty, X + ScrW - 1, Ty + Th - 1);
End;

{ ==================================================================== }
{ Icones                                                                }
{ ==================================================================== }

Procedure IcoTb(K : LongInt);
Var I : LongInt;
Begin
  Case K Of
    1 :
      Begin
        { nouvelle grille : petite grille }
        IR(1, 1, 14, 14, cWhite); IB(1, 1, 14, 14, cBlack); IR(5, 1, 5, 14, cGray); IR(10, 1, 10, 14, cGray);
        IR(1, 5, 14, 5, cGray); IR(1, 10, 14, 10, cGray); IR(2, 2, 4, 4, cNavy); IR(11, 11, 13, 13, cNavy);
        IR(9, 8, 14, 9, cDGreen); IR(11, 6, 12, 11, cDGreen);
      End;
    2 :
      Begin
        IR(1, 3, 6, 4, cBrown); IR(1, 4, 14, 13, cYellow); IB(1, 4, 14, 13, cBrown);
        IR(3, 7, 15, 13, cYellow); IB(3, 7, 15, 13, cBrown);
      End;
    3 : Begin IR(1, 1, 14, 14, cNavy); IR(4, 1, 11, 5, cSilver); IR(3, 8, 12, 14, cWhite); IB(1, 1, 14, 14, cBlack); End;
    4 :
      Begin
        IR(1, 1, 9, 14, cWhite); IB(1, 1, 9, 14, cBlack);
        IR(3, 4, 7, 4, cGray); IR(3, 7, 7, 7, cGray); IR(3, 10, 6, 10, cGray);
        IR(8, 7, 13, 8, cDGreen); IR(11, 5, 12, 10, cDGreen); IR(13, 6, 13, 9, cDGreen); IR(14, 7, 14, 8, cDGreen);
      End;
    5 :
      Begin
        For I := 0 To 7 Do
        Begin
          IR(3 + I, 2, 3 + I, 3, cDGreen); IR(3 + I, 12, 3 + I, 13, cDGreen);
        End;
        IR(2, 3, 3, 8, cDGreen); IR(12, 7, 13, 12, cDGreen);
        IR(10, 0, 10, 5, cDGreen); IR(11, 1, 11, 4, cDGreen); IR(4, 10, 4, 15, cDGreen); IR(3, 11, 3, 14, cDGreen);
      End;
    6 :
      Begin
        { resoudre : baguette }
        Thick(IcX + 2, IcY + 13, IcX + 10, IcY + 5, cBrown);
        IR(11, 1, 11, 7, cYellow); IR(8, 4, 14, 4, cYellow); IR(9, 2, 13, 6, cYellow);
      End;
    7 :
      Begin
        { solution : grille remplie }
        IR(1, 1, 14, 14, cWhite); IB(1, 1, 14, 14, cBlack); IR(5, 1, 5, 14, cGray); IR(10, 1, 10, 14, cGray);
        IR(1, 5, 14, 5, cGray); IR(1, 10, 14, 10, cGray);
        IR(2, 2, 4, 4, cDGreen); IR(6, 6, 9, 9, cDGreen); IR(11, 11, 13, 13, cDGreen); IR(11, 2, 13, 4, cDGreen);
      End;
    8 :
      Begin
        IR(1, 1, 14, 14, cWhite); IB(1, 1, 14, 14, cGray);
        Thick(IcX + 3, IcY + 7, IcX + 6, IcY + 10, cDGreen); Thick(IcX + 6, IcY + 10, IcX + 12, IcY + 4, cDGreen);
      End;
    9 :
      Begin
        { indice : ampoule }
        Disc(IcX + 8, IcY + 6, 5, cYellow); IR(6, 10, 10, 13, cGray); IR(7, 14, 9, 15, cGray);
      End;
    10 :
      Begin
        Disc(IcX + 8, IcY + 8, 6, cGray); Disc(IcX + 8, IcY + 8, 2, cSilver);
        IR(7, 0, 9, 2, cGray); IR(7, 14, 9, 15, cGray); IR(0, 7, 2, 9, cGray); IR(14, 7, 15, 9, cGray);
      End;
    11 :
      Begin
        Disc(IcX + 8, IcY + 8, 7, cBlue);
        IR(6, 4, 9, 4, cWhite); IR(9, 5, 10, 6, cWhite); IR(7, 7, 9, 7, cWhite); IR(7, 8, 8, 9, cWhite);
        IR(7, 11, 8, 12, cWhite);
      End;
    12 :
      Begin
        { notes : crayon }
        Thick(IcX + 3, IcY + 12, IcX + 12, IcY + 3, cBrown); IR(2, 13, 3, 14, cBlack); IR(12, 2, 13, 3, cPink);
      End;
    13 :
      Begin
        { annuler }
        IR(4, 5, 11, 6, cNavy); IR(11, 6, 12, 11, cNavy); IR(6, 11, 12, 12, cNavy);
        IR(1, 5, 4, 6, cNavy); IR(2, 3, 3, 8, cNavy); IR(3, 2, 3, 9, cNavy);
      End;
  End;
End;

{ chiffres de 5 x 7 points (gros chiffres) et de 3 x 5 points (notes) }
Const
  Big : Array[0..62] Of Byte = (
    $04, $0C, $04, $04, $04, $04, $0E,
    $0E, $11, $01, $02, $04, $08, $1F,
    $1F, $02, $04, $02, $01, $11, $0E,
    $02, $06, $0A, $12, $1F, $02, $02,
    $1F, $10, $1E, $01, $01, $11, $0E,
    $06, $08, $10, $1E, $11, $11, $0E,
    $1F, $01, $02, $04, $08, $08, $08,
    $0E, $11, $11, $0E, $11, $11, $0E,
    $0E, $11, $11, $0F, $01, $02, $0C);
  Small : Array[1..9] Of LongInt = ($2C97, $73E7, $73CF, $5BC9, $79CF, $79EF, $7292, $7BEF, $7BCF);

Procedure BigDigit(X, Y, D, S, C : LongInt);
Var R, Q : LongInt;
Begin
  If (D < 1) Or (D > 9) Then Exit;
  For R := 0 To 6 Do
    For Q := 0 To 4 Do
      If ((Big[(D - 1) * 7 + R] Shr (4 - Q)) And 1) <> 0 Then FBar(X + Q * S, Y + R * S, X + Q * S + S - 1, Y + R * S + S - 1, C);
End;

Procedure SmallDigit(X, Y, D, S, C : LongInt);
Var R, Q : LongInt;
Begin
  If (D < 1) Or (D > 9) Then Exit;
  For R := 0 To 4 Do
    For Q := 0 To 2 Do
      If ((Small[D] Shr (14 - (R * 3 + Q))) And 1) <> 0 Then FBar(X + Q * S, Y + R * S, X + Q * S + S - 1, Y + R * S + S - 1, C);
End;

{ ==================================================================== }
{ Disposition                                                           }
{ ==================================================================== }

Procedure Layout;
Var Aw, Ah : LongInt;
Begin
  If ShowToolbar Then Y0 := TbH Else Y0 := 0;
  Y1 := CH - SbH - 1;
  PnX := CW - PnW;
  Aw := PnX - 40; Ah := Y1 - Y0 - 80;
  Cs := MinI(Aw, Ah) Div 9;
  If Cs > 64 Then Cs := 64;
  If Cs < 20 Then Cs := 20;
  BX0 := (PnX - 9 * Cs) Div 2;
  BY0 := Y0 + 56 + (Y1 - Y0 - 70 - 9 * Cs) Div 2;
  If BY0 < Y0 + 50 Then BY0 := Y0 + 50;
End;

Procedure InvalBoard;
Begin
  InvalBand(0, Y0, PnX, Y1 + 1);
End;

Procedure InvalPanel;
Begin
  InvalBand(PnX, Y0, CW, Y1 + 1);
End;

Procedure InvalStatus;
Begin
  InvalBand(0, CH - SbH, CW, CH);
End;

{ ==================================================================== }
{ Barre d'outils                                                        }
{ ==================================================================== }

Function TbPressed(C : LongInt) : Boolean;
Begin
  TbPressed := ((C = cmShowSol) And ShowSolution) Or ((C = cmNotesMode) And NotesMode);
End;

Function TbDisabled(C : LongInt) : Boolean;
Begin
  TbDisabled := False;
  Case C Of
    cmSave, cmExport, cmShowSol, cmCheck, cmHint, cmNotesMode : TbDisabled := Not Ready Or EditMode;
    cmUndo : TbDisabled := UndoN = 0;
    cmSameSeed : TbDisabled := FromFile Or Not Ready;
  End;
End;

Procedure PaintToolbar;
Var I, X : LongInt; Dis : Boolean;
Begin
  Raised(0, 0, CW - 1, TbH - 1);
  For I := 0 To NTb - 1 Do
  Begin
    X := TbX[I];
    If TbCmd[I] = 0 Then
    Begin
      VLine(X + 2, 4, TbH - 5, cGray); VLine(X + 3, 4, TbH - 5, cWhite);
      Continue;
    End;
    Dis := TbDisabled(TbCmd[I]);
    If ((TbDown = I) Or TbPressed(TbCmd[I])) And Not Dis Then
    Begin
      FBar(X, 3, X + TbW[I] - 1, 26, cSilver);
      Edge(X, 3, X + TbW[I] - 1, 26, cGray, cWhite);
      IcX := X + 5; IcY := 8;
    End
    Else
    Begin
      If (TbHot = I) And Not Dis Then Edge(X, 3, X + TbW[I] - 1, 26, cWhite, cGray);
      IcX := X + 4; IcY := 7;
    End;
    If Dis Then IR(4, 4, 11, 11, cGray) Else IcoTb(TbIco[I]);
    If TbTxt[I] <> '' Then
    Begin
      If Dis Then OutTxt(IcX + 20, IcY - 1, TbTxt[I], cGray, cSilver)
      Else OutTxt(IcX + 20, IcY - 1, TbTxt[I], cBlack, cSilver);
    End;
  End;
End;

{ ==================================================================== }
{ Grille                                                                }
{ ==================================================================== }

Function Peer(X, Y : LongInt) : Boolean;
Begin
  Peer := False;
  If CurX = 0 Then Exit;
  If (X = CurX) Or (Y = CurY) Then Peer := True
  Else If OptBoxes And ((X - 1) Div 3 = (CurX - 1) Div 3) And ((Y - 1) Div 3 = (CurY - 1) Div 3) Then Peer := True;
End;

{ valeur visible d'une case (donnee, reponse ou solution) }
Function CellVal(X, Y : LongInt) : LongInt;
Begin
  If Giv[Y, X] <> 0 Then CellVal := Giv[Y, X]
  Else If ShowSolution And Not EditMode Then CellVal := Sol[Y, X]
  Else CellVal := Usr[Y, X];
End;

{ la reponse est-elle en conflit avec une autre case visible ? }
Function Conflict(X, Y : LongInt) : Boolean;
Var V, K, I, J, BX, BY : LongInt;
Begin
  Conflict := False;
  V := CellVal(X, Y);
  If V = 0 Then Exit;
  For K := 1 To 9 Do
  Begin
    If (K <> X) And (CellVal(K, Y) = V) Then Conflict := True;
    If (K <> Y) And (CellVal(X, K) = V) Then Conflict := True;
  End;
  If OptBoxes Then
  Begin
    BY := ((Y - 1) Div 3) * 3; BX := ((X - 1) Div 3) * 3;
    For J := BY + 1 To BY + 3 Do
      For I := BX + 1 To BX + 3 Do
        If ((J <> Y) Or (I <> X)) And (CellVal(I, J) = V) Then Conflict := True;
  End;
End;

Procedure PaintBoard;
Var X, Y, Sx, Sy, Bg, Fg, V, S, K, Nx, Ny, Ns, W, CurV : LongInt; Tt : String;
Begin
  FBar(0, Y0, PnX - 1, Y1, cGray);
  { feuille de papier }
  FBar(BX0 - 16 + 5, BY0 - 44 + 5, BX0 + 9 * Cs + 16 + 5, BY0 + 9 * Cs + 16 + 5, cBlack);
  FBar(BX0 - 16, BY0 - 44, BX0 + 9 * Cs + 16, BY0 + 9 * Cs + 16, cWhite);
  Box(BX0 - 16, BY0 - 44, BX0 + 9 * Cs + 16, BY0 + 9 * Cs + 16, cBlack);
  If EditMode Then Tt := 'Saisie d''une grille : tapez les chiffres donn'#130's'
  Else If Not Ready Then Tt := 'Aucune grille'
  Else
  Begin
    Tt := 'Sodoku - ' + LevelName(OptLevel);
    If FromFile Then Tt := 'Sodoku - ' + GridName;
    If ShowSolution Then Tt := Tt + ' - solution';
    If Solved Then Tt := Tt + ' - r'#130'solu !';
  End;
  OutTxt(BX0, BY0 - 34, Fit(Tt, 9 * Cs), cNavy, cWhite);
  S := MaxI(2, Cs Div 12);
  W := 5 * S;
  CurV := 0;
  If (CurX > 0) And SameDigit Then CurV := CellVal(CurX, CurY);
  For Y := 1 To 9 Do
    For X := 1 To 9 Do
    Begin
      Sx := BX0 + (X - 1) * Cs; Sy := BY0 + (Y - 1) * Cs;
      If (Sy > UY2) Or (Sy + Cs < UY1) Then Continue;
      V := CellVal(X, Y);
      Bg := cWhite;
      If ShowPeers And Peer(X, Y) Then Bg := cSilver;
      If (CurV <> 0) And (V = CurV) Then Bg := cCyan;
      If (X = CurX) And (Y = CurY) Then Bg := cYellow;
      FBar(Sx, Sy, Sx + Cs - 1, Sy + Cs - 1, Bg);
      If V <> 0 Then
      Begin
        If Giv[Y, X] <> 0 Then Fg := cBlack
        Else If ShowSolution And Not EditMode Then Fg := cDGreen
        Else If Bad[Y, X] Then Fg := cRed
        Else If AutoCheck And Ready And (Usr[Y, X] <> Sol[Y, X]) And (Sol[Y, X] <> 0) Then Fg := cRed
        Else If AutoCheck And Conflict(X, Y) Then Fg := cRed
        Else Fg := cNavy;
        BigDigit(Sx + (Cs - W) Div 2, Sy + (Cs - 7 * S) Div 2, V, S, Fg);
        If Giv[Y, X] <> 0 Then BigDigit(Sx + (Cs - W) Div 2 + 1, Sy + (Cs - 7 * S) Div 2, V, S, Fg);
      End
      Else If ShowNotes And (Notes[Y, X] <> 0) Then
      Begin
        Ns := MaxI(1, Cs Div 20);
        For K := 1 To 9 Do
          If ((Notes[Y, X] Shr K) And 1) <> 0 Then
          Begin
            Nx := Sx + 3 + ((K - 1) Mod 3) * ((Cs - 6) Div 3) + ((Cs - 6) Div 3 - 3 * Ns) Div 2;
            Ny := Sy + 3 + ((K - 1) Div 3) * ((Cs - 6) Div 3) + ((Cs - 6) Div 3 - 5 * Ns) Div 2;
            SmallDigit(Nx, Ny, K, Ns, cGray);
          End;
      End;
    End;
  { lignes : fines, et epaisses autour des carres 3 x 3 }
  For K := 0 To 9 Do
  Begin
    If OptBoxes And (K Mod 3 = 0) Then
    Begin
      FBar(BX0 + K * Cs - 1, BY0 - 1, BX0 + K * Cs + 1, BY0 + 9 * Cs + 1, cBlack);
      FBar(BX0 - 1, BY0 + K * Cs - 1, BX0 + 9 * Cs + 1, BY0 + K * Cs + 1, cBlack);
    End
    Else If (K = 0) Or (K = 9) Then
    Begin
      FBar(BX0 + K * Cs - 1, BY0 - 1, BX0 + K * Cs + 1, BY0 + 9 * Cs + 1, cBlack);
      FBar(BX0 - 1, BY0 + K * Cs - 1, BX0 + 9 * Cs + 1, BY0 + K * Cs + 1, cBlack);
    End
    Else
    Begin
      VLine(BX0 + K * Cs, BY0, BY0 + 9 * Cs, cGray);
      HLine(BX0, BX0 + 9 * Cs, BY0 + K * Cs, cGray);
    End;
  End;
End;

{ ==================================================================== }
{ Panneau de droite : partie, pave des chiffres                         }
{ ==================================================================== }

Function Z2s(V : LongInt) : String;
Begin
  Z2s := Chr(48 + (V Div 10) Mod 10) + Chr(48 + V Mod 10);
End;

Function TimeStr : String;
Begin
  TimeStr := Z2s(Elapsed Div 60) + ':' + Z2s(Elapsed Mod 60);
End;

Function EmptyLeft : LongInt;
Var X, Y, N : LongInt;
Begin
  N := 0;
  For Y := 1 To 9 Do
    For X := 1 To 9 Do
      If (Giv[Y, X] = 0) And (Usr[Y, X] = 0) Then Inc(N);
  EmptyLeft := N;
End;

{ nombre de fois ou le chiffre D est visible }
Function DigitCount(D : LongInt) : LongInt;
Var X, Y, N : LongInt;
Begin
  N := 0;
  For Y := 1 To 9 Do
    For X := 1 To 9 Do
      If (Giv[Y, X] = D) Or ((Giv[Y, X] = 0) And (Usr[Y, X] = D)) Then Inc(N);
  DigitCount := N;
End;

Procedure Section(Y : LongInt; S : String);
Begin
  OutTxt(PnX + 12, Y, S, cNavy, cSilver);
  HLine(PnX + 12, CW - 12, Y + 18, cNavy);
End;

Procedure InfoLine(Y : LongInt; L, V : String);
Begin
  OutTxt(PnX + 14, Y, L, cBlack, cSilver);
  OutTxt(CW - 14 - Length(V) * 8, Y, V, cBlack, cSilver);
End;

{ coordonnees du bouton du pave : 1 a 9, 10 Effacer, 11 Notes }
Procedure PadRect(K : LongInt; Var X1, Y1_, X2, Y2 : LongInt);
Var Bw, Py : LongInt;
Begin
  Bw := (PnW - 40) Div 3;
  Py := Y0 + 222;
  If K <= 9 Then
  Begin
    X1 := PnX + 14 + ((K - 1) Mod 3) * (Bw + 6); Y1_ := Py + ((K - 1) Div 3) * (Bw + 6);
    X2 := X1 + Bw - 1; Y2 := Y1_ + Bw - 1;
  End
  Else
  Begin
    X1 := PnX + 14 + (K - 10) * ((PnW - 34) Div 2 + 6); Y1_ := Py + 3 * (Bw + 6);
    X2 := X1 + (PnW - 34) Div 2 - 1; Y2 := Y1_ + 29;
  End;
End;

Procedure PaintPanel;
Var Y, K, X1, Y1_, X2, Y2, S, N : LongInt; Txt : String; Dis : Boolean;
Begin
  FBar(PnX, Y0, CW - 1, Y1, cSilver);
  VLine(PnX, Y0, Y1, cGray); VLine(PnX + 1, Y0, Y1, cWhite);
  Y := Y0 + 10;
  Section(Y, 'Partie');
  Y := Y + 26;
  If Ready Then
  Begin
    If FromFile Then InfoLine(Y, 'Grille', Fit(GridName, 130)) Else InfoLine(Y, 'Niveau', LevelName(OptLevel));
    InfoLine(Y + 18, 'Cases donn'#130'es', IStr(NGiven));
    InfoLine(Y + 36, 'Cases '#133' remplir', IStr(EmptyLeft));
    InfoLine(Y + 54, 'Erreurs v'#130'rifi'#130'es', IStr(Errors));
    InfoLine(Y + 72, 'Indices', IStr(Hints));
    InfoLine(Y + 90, 'Temps', TimeStr);
    If FromFile Then InfoLine(Y + 108, 'Graine', '-') Else InfoLine(Y + 108, 'Graine', IStr(LastSeed));
    If OptShowTry Then
    Begin
      If FromFile Then InfoLine(Y + 126, 'Essais', IStr(SolveTries)) Else InfoLine(Y + 126, 'Essais', IStr(GenTries));
    End;
    { progression }
    N := 81 - NGiven;
    If N > 0 Then K := ((N - EmptyLeft) * (PnW - 28)) Div N Else K := PnW - 28;
    Sunken(PnX + 12, Y + 148, CW - 12, Y + 160, cWhite);
    If K > 0 Then FBar(PnX + 13, Y + 149, PnX + 13 + K - 2, Y + 159, cDGreen);
  End
  Else OutTxt(PnX + 14, Y, 'Grille - Nouvelle grille (F2)', cGray, cSilver);
  { pave des chiffres }
  For K := 1 To 11 Do
  Begin
    PadRect(K, X1, Y1_, X2, Y2);
    Dis := Not Ready And Not EditMode;
    If (K = 11) And NotesMode Then
    Begin
      FBar(X1, Y1_, X2, Y2, cWhite);
      Box(X1, Y1_, X2, Y2, cBlack);
      Edge(X1 + 1, Y1_ + 1, X2 - 1, Y2 - 1, cGray, cWhite);
    End
    Else
    Begin
      FBar(X1, Y1_, X2, Y2, cSilver);
      Box(X1, Y1_, X2, Y2, cBlack);
      Edge(X1 + 1, Y1_ + 1, X2 - 1, Y2 - 1, cWhite, cGray);
    End;
    If K <= 9 Then
    Begin
      S := MaxI(2, (X2 - X1) Div 18);
      N := 9 - DigitCount(K);
      If Dis Or (N <= 0) Then BigDigit((X1 + X2) Div 2 - 5 * S Div 2, (Y1_ + Y2) Div 2 - 7 * S Div 2 - 4, K, S, cGray)
      Else BigDigit((X1 + X2) Div 2 - 5 * S Div 2, (Y1_ + Y2) Div 2 - 7 * S Div 2 - 4, K, S, cNavy);
      If Ready And Not EditMode Then
      Begin
        If N < 0 Then N := 0;
        SmallDigit(X2 - 8, Y2 - 9, N Mod 10, 1, cGray);
        If N = 0 Then HLine(X2 - 9, X2 - 5, Y2 - 7, cGray);
      End;
    End
    Else
    Begin
      If K = 10 Then Txt := 'Effacer' Else If NotesMode Then Txt := 'Notes : oui' Else Txt := 'Notes : non';
      OutTxt((X1 + X2) Div 2 - Length(Txt) * 4, Y1_ + 7, Txt, cBlack, cSilver);
    End;
  End;
  PadRect(11, X1, Y1_, X2, Y2);
  Y := Y2 + 16;
  If EditMode Then
  Begin
    Section(Y, 'Saisie');
    OutTxt(PnX + 14, Y + 26, 'Grille - Terminer la saisie', cBlack, cSilver);
    OutTxt(PnX + 14, Y + 44, '(F7), puis F7 pour la r'#130'soudre.', cBlack, cSilver);
  End
  Else If Ready And (Y + 60 < Y1) Then
  Begin
    Section(Y, 'R'#138'gles');
    If OptBoxes Then Txt := 'Lignes, colonnes et carr'#130's' Else Txt := 'Lignes et colonnes (GSODOKU)';
    OutTxt(PnX + 14, Y + 26, Fit(Txt, PnW - 28), cBlack, cSilver);
    If OptUnique Then Txt := 'Solution unique' Else Txt := 'Solution non v'#130'rifi'#130'e';
    OutTxt(PnX + 14, Y + 44, Fit(Txt, PnW - 28), cBlack, cSilver);
  End;
End;

Procedure PaintStatus;
Var X : LongInt; S : String;
Begin
  Raised(0, CH - SbH, CW - 1, CH - 1);
  S := '';
  If Ready Then S := IStr(EmptyLeft) + ' case(s) '#133' remplir - ' + TimeStr;
  If S = '' Then S := ' ';
  X := CW - 12 - Length(S) * 8;
  Sunken(X - 6, CH - SbH + 2, CW - 4, CH - 3, cSilver);
  OutTxt(X, CH - SbH + 2, S, cBlack, cSilver);
  OutTxt(6, CH - SbH + 2, Fit(StatusMsg, X - 16), cBlack, cSilver);
End;

Procedure Paint(H : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Hps := WinBeginPaint(H, 0, LongInt(@Rc));
  UX1 := Rc[0]; UX2 := Rc[2] - 1; UY1 := CH - Rc[3]; UY2 := CH - 1 - Rc[1];
  If (UX2 < UX1) Or (UY2 < UY1) Then
  Begin
    UX1 := 0; UY1 := 0; UX2 := CW - 1; UY2 := CH - 1;
  End;
  If ShowToolbar And (UY1 < TbH) Then PaintToolbar;
  If (UX1 < PnX) And (UY2 >= Y0) And (UY1 <= Y1) Then PaintBoard;
  If (UX2 >= PnX) And (UY2 >= Y0) And (UY1 <= Y1) Then PaintPanel;
  If UY2 >= CH - SbH Then PaintStatus;
  Dummy := WinEndPaint(Hps);
End;

{ ==================================================================== }
{ Boites de dialogue                                                    }
{ ==================================================================== }

Const
  WM_SETFOCUS = $000F;
  WC_COMBOBOX = $FFFF0002;
  MaxDf = 14;
  dfEdit = 0; dfCheck = 1; dfCombo = 2; dfLabel = 3;
  dNone = 0; dTool = 1; dVThumb = 2;

Var
  DgFrame, DgClient, DgN, DgW, DgH : LongInt;
  DgDone, DgOk : Boolean;
  DfKind, DfH : Array[0..MaxDf - 1] Of LongInt;
  DfLab, DfVal, DfCh : Array[0..MaxDf - 1] Of String;
  CtxMenu : LongInt;
  MStkN : Array[0..7] Of LongInt;
  MDep : LongInt;
  Drag, DragY0, DragTop, LastMx, LastMy : LongInt;
  WorkDir, ExportName : String;

Function JoinPath(D, N : String) : String;
Begin
  If (D <> '') And (D[Length(D)] <> '\') Then D := D + '\';
  JoinPath := D + N;
End;

Function WinText(H : LongInt) : String;
Var B : Array[0..299] Of Byte; N, K : LongInt; S : String;
Begin
  S := '';
  N := WinQueryWindowText(H, 255, LongInt(@B));
  If N > 255 Then N := 255;
  For K := 0 To N - 1 Do
  Begin
    If B[K] = 0 Then Break;
    S := S + Chr(B[K]);
  End;
  WinText := S;
End;

Procedure Msg(S : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('G'#130'n'#130'rateur de Sodoku'), 0,
                         MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure MsgErr(S : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('G'#130'n'#130'rateur de Sodoku'), 0,
                         MB_OK Or MB_ERROR Or MB_MOVEABLE);
End;

Function Ask3(S : String) : LongInt;
Begin
  Ask3 := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('G'#130'n'#130'rateur de Sodoku'), 0,
                        MB_YESNOCANCEL Or MB_QUERY Or MB_MOVEABLE);
End;

Function AskYes(S : String) : Boolean;
Begin
  AskYes := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('G'#130'n'#130'rateur de Sodoku'), 0,
                          MB_YESNO Or MB_QUERY Or MB_MOVEABLE) = MBID_YES;
End;

Procedure ShowBuf(Title : String; Var B : TBuf);
Begin
  If B.Len > 3500 Then B.Len := 3500;
  BufAddC(B, 0);
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, LongInt(B.P), Z2(Title), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
  Dec(B.Len);
End;

Function WriteAll(Name : String; P : PBytes; N : LongInt) : Boolean;
Var H : LongInt;
Begin
  WriteAll := False;
  If Not FOpenWrite(Name, H) Then Exit;
  WriteAll := (N = 0) Or (FWrite(H, P, N) = N);
  DosClose(H);
End;

{ haut de la ligne K du dialogue (Y vers le bas) }
Function DfY(K : LongInt) : LongInt;
Begin
  DfY := 14 + K * 30;
End;

Function DlgProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Var P, Fl, Vk, K, X, F : LongInt; Rc, Tr : Array[0..3] Of LongInt;
Begin
  DlgProc := 0;
  Case Msg_ Of
    WM_PAINT :
      Begin
        P := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(P, LongInt(@Rc), cSilver);
        For K := 0 To DgN - 1 Do
          If (DfKind[K] = dfEdit) Or (DfKind[K] = dfCombo) Or (DfKind[K] = dfLabel) Then
          Begin
            PutZ(DfLab[K]);
            Tr[0] := 14; Tr[1] := DgH - DfY(K) - 20; Tr[2] := DgW - 12; Tr[3] := Tr[1] + 18;
            If DfKind[K] <> dfLabel Then Tr[2] := 344;
            Dummy := WinDrawText(P, -1, LongInt(@TxtBuf), LongInt(@Tr), cBlack, cSilver, 0);
          End;
        Dummy := WinEndPaint(P);
      End;
    WM_COMMAND :
      Begin
        If Lo16(Mp1) = 1 Then
        Begin
          For K := 0 To DgN - 1 Do
            Case DfKind[K] Of
              dfEdit : DfVal[K] := WinText(DfH[K]);
              dfCheck : DfVal[K] := IStr(WinSendMsg(DfH[K], BM_QUERYCHECK, 0, 0) And 1);
              dfCombo :
                Begin
                  X := WinSendMsg(DfH[K], $0165, $FFFF, 0);
                  If (X < 0) Or (X > 1000) Then X := 0;
                  DfVal[K] := IStr(X);
                End;
            End;
          DgOk := True;
        End;
        DgDone := True;
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_TAB) Or (Vk = VK_BACKTAB)) Then
        Begin
          F := WinQueryFocus(HWND_DESKTOP);
          X := -1;
          For K := 0 To DgN - 1 Do If DfH[K] = F Then X := K;
          Repeat
            If (Vk = VK_BACKTAB) Or ((Fl And KC_SHIFT) <> 0) Then Dec(X) Else Inc(X);
            If X < 0 Then X := DgN - 1;
            If X >= DgN Then X := 0;
          Until DfKind[X] <> dfLabel;
          Dummy := WinSetFocus(HWND_DESKTOP, DfH[X]);
        End
        Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
          Dummy := WinPostMsg(H, WM_COMMAND, 1, 0)
        Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then DgDone := True
        Else DlgProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
      End;
    WM_CLOSE : DgDone := True;
  Else
    DlgProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
  End;
End;

Procedure DlgReset;
Var K : LongInt;
Begin
  DgN := 0;
  For K := 0 To MaxDf - 1 Do
  Begin
    DfLab[K] := ''; DfVal[K] := ''; DfCh[K] := ''; DfH[K] := 0; DfKind[K] := dfEdit;
  End;
End;

Procedure DlgAdd(Kind : LongInt; L, V, Ch : String);
Begin
  If DgN >= MaxDf Then Exit;
  DfKind[DgN] := Kind; DfLab[DgN] := L; DfVal[DgN] := V; DfCh[DgN] := Ch;
  Inc(DgN);
End;

Procedure DlgEdit(L, V : String);
Begin
  DlgAdd(dfEdit, L, V, '');
End;

Procedure DlgCheck(L : String; B : Boolean);
Begin
  If B Then DlgAdd(dfCheck, L, '1', '') Else DlgAdd(dfCheck, L, '0', '');
End;

{ choix separes par | ; V : indice du choix }
Procedure DlgCombo(L, Choices : String; V : LongInt);
Begin
  DlgAdd(dfCombo, L, IStr(V), Choices);
End;

Procedure DlgLabel(L : String);
Begin
  DlgAdd(dfLabel, L, '', '');
End;

Function DlgBool(K : LongInt) : Boolean;
Begin
  DlgBool := DfVal[K] = '1';
End;

Function DlgInt(K : LongInt) : LongInt;
Var V, E : LongInt;
Begin
  Val(Trim(DfVal[K]), V, E);
  If E <> 0 Then V := 0;
  DlgInt := V;
End;

{ boite de dialogue modale ; rend True si OK }
Function DlgRun(Title, OkS : String) : Boolean;
Var Fl, K, Fw, Fh, Sw, Sh, Y, St, A, Hc : LongInt; Rc : Array[0..3] Of LongInt; Q : Array[0..7] Of LongInt;
    S, Itm : String; Ff : Boolean;
Begin
  DlgRun := False;
  DgW := 620;
  DgH := DfY(DgN) + 52;
  Dummy := WinRegisterClass(Hab, Z('CGDLG'), LongInt(@DlgProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DgClient := 0;
  DgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('CGDLG'), Z2(Title), 0, 0, 0, LongInt(@DgClient));
  If DgFrame = 0 Then Exit;
  For K := 0 To DgN - 1 Do
  Begin
    Y := DgH - DfY(K) - 24;
    Case DfKind[K] Of
      dfEdit :
        Begin
          If Length(DfLab[K]) * 8 > 280 Then
          Begin
            { libelle long : le champ va sur toute la largeur, sous le libelle }
            DfH[K] := WinCreateWindow(DgClient, WC_ENTRYFIELD, Z(DfVal[K]), WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or
                                      ES_MARGIN, 350, Y, DgW - 364, 20, DgClient, HWND_TOP, 10 + K, 0, 0);
          End
          Else
            DfH[K] := WinCreateWindow(DgClient, WC_ENTRYFIELD, Z(DfVal[K]), WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or
                                      ES_MARGIN, 350, Y, DgW - 364, 20, DgClient, HWND_TOP, 10 + K, 0, 0);
          Dummy := WinSendMsg(DfH[K], EM_SETTEXTLIMIT, 250, 0);
          Dummy := WinSendMsg(DfH[K], $0142, Length(DfVal[K]) Shl 16, 0);
        End;
      dfCheck :
        Begin
          DfH[K] := WinCreateWindow(DgClient, WC_BUTTON, Z(DfLab[K]), WS_VISIBLE Or WS_TABSTOP Or BS_AUTOCHECKBOX, 14, Y,
                                    DgW - 28, 22, DgClient, HWND_TOP, 10 + K, 0, 0);
          A := 15;
          Dummy := WinSetPresParam(DfH[K], 4, 4, LongInt(@A));
          If DfVal[K] = '1' Then Dummy := WinSendMsg(DfH[K], BM_SETCHECK, 1, 0);
        End;
      dfCombo :
        Begin
          Hc := 22;
          DfH[K] := WinCreateWindow(DgClient, WC_COMBOBOX, 0, WS_VISIBLE Or WS_TABSTOP Or 4, 350, Y, DgW - 364, Hc,
                                    DgClient, HWND_TOP, 10 + K, 0, 0);
          S := DfCh[K] + '|';
          St := 1;
          For A := 1 To Length(S) Do
            If S[A] = '|' Then
            Begin
              Itm := Copy(S, St, A - St);
              Dummy := WinSendMsg(DfH[K], $0161, $FFFF, Z(Itm));
              St := A + 1;
            End;
          Dummy := WinSendMsg(DfH[K], $0164, DlgInt(K), 1);
        End;
    End;
  End;
  Dummy := WinCreateWindow(DgClient, WC_BUTTON, Z(OkS), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                           DgW - 252, 10, 130, 26, DgClient, HWND_TOP, 1, 0, 0);
  Dummy := WinCreateWindow(DgClient, WC_BUTTON, Z('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                           DgW - 112, 10, 100, 26, DgClient, HWND_TOP, 2, 0, 0);
  Rc[0] := 0; Rc[1] := 0; Rc[2] := DgW; Rc[3] := DgH;
  Dummy := WinCalcFrameRect(DgFrame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(DgFrame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, DgFrame);
  Ff := False;
  For K := 0 To DgN - 1 Do
    If (Not Ff) And (DfKind[K] <> dfLabel) Then
    Begin
      Dummy := WinSetFocus(HWND_DESKTOP, DfH[K]);
      Ff := True;
    End;
  Dummy := WinEnableWindow(Frame, 0);
  DgDone := False; DgOk := False;
  While Not DgDone Do
  Begin
    If WinGetMsg(Hab, LongInt(@Q), 0, 0, 0) = 0 Then
    Begin
      DgDone := True;
      Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    End
    Else Dummy := WinDispatchMsg(Hab, LongInt(@Q));
  End;
  Dummy := WinEnableWindow(Frame, 1);
  Dummy := WinDestroyWindow(DgFrame);
  DgFrame := 0;
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  DlgRun := DgOk;
End;

{ ==================================================================== }
{ Menus                                                                 }
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
  If MenuLen = 0 Then MDep := 0;
  MenuOpen := MenuLen;
  MStkN[MDep] := 0;
  Inc(MDep);
  MW(0); MW(0); MW(0);
End;

Procedure MenuClose(H : LongInt);
Var Count : LongInt;
Begin
  Count := 0;
  If MDep > 0 Then
  Begin
    Dec(MDep);
    Count := MStkN[MDep];
  End;
  MenuT[H] := (MenuLen - H) And 255; MenuT[H + 1] := ((MenuLen - H) Shr 8) And 255;
  MenuT[H + 4] := Count And 255; MenuT[H + 5] := (Count Shr 8) And 255;
End;

Procedure MnItem(Style, Attr, Id : LongInt; S : String);
Var K : LongInt;
Begin
  If MDep > 0 Then Inc(MStkN[MDep - 1]);
  MW(Style); MW(Attr); MW(Id);
  If (Style And MIS_SEPARATOR) = 0 Then
  Begin
    For K := 1 To Length(S) Do MB(Ord(S[K]));
    MB(0);
  End;
End;

Procedure It(Id : LongInt; S : String);
Begin
  MnItem(MIS_TEXT, 0, Id, S);
End;

Procedure ItA(Id, Attr : LongInt; S : String);
Begin
  MnItem(MIS_TEXT, Attr, Id, S);
End;

Procedure Sep;
Begin
  MnItem(MIS_SEPARATOR, 0, 0, '');
End;

Function Chk(B : Boolean) : LongInt;
Begin
  If B Then Chk := MIA_CHECKED Else Chk := 0;
End;

Procedure SetCheck(Id : LongInt; On_ : Boolean);
Begin
  If MenuHw = 0 Then Exit;
  If On_ Then Dummy := WinSendMsg(MenuHw, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(MenuHw, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED);
End;

{ ==================================================================== }
{ Menus et barre d'outils                                               }
{ ==================================================================== }

Procedure BuildMenu;
Var H0, H1, H2, K : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 80, '~Fichier');
  H1 := MenuOpen;
  It(cmNew, '~Nouvelle grille' + #9 + 'F2');
  It(cmOpen, '~Ouvrir une grille (.SDK)...' + #9 + 'Ctrl+O');
  It(cmSave, '~Enregistrer la grille' + #9 + 'Ctrl+S');
  It(cmSaveAs, 'Enregistrer la grille ~sous...');
  It(cmSaveSol, 'Enregistrer la so~lution...');
  Sep;
  It(cmExport, 'E~xporter (texte ou page Web)...' + #9 + 'Ctrl+E');
  It(cmCopyText, 'Co~pier la grille (texte)' + #9 + 'Ctrl+C');
  Sep;
  It(cmQuit, '~Quitter' + #9 + 'Alt+F4');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 81, '~Grille');
  H1 := MenuOpen;
  It(cmGenerate, '~R'#130'g'#130'n'#130'rer (nouvelle graine)' + #9 + 'F5');
  It(cmSameSeed, 'R'#130'g'#130'n'#130'rer avec la ~m'#136'me graine' + #9 + 'Maj+F5');
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 89, '~Niveau');
  H2 := MenuOpen;
  For K := lvEasy To lvCustom Do
    If K = lvCustom Then ItA(cmLvl0 + K, Chk(OptLevel = K), LevelName(K) + '...')
    Else ItA(cmLvl0 + K, Chk(OptLevel = K), LevelName(K) + ' (' + IStr(LevelGivens(K)) + ' cases donn'#130'es)');
  MenuClose(H2);
  Sep;
  It(cmSolve, 'R'#130'~soudre la grille (SSODOKU)' + #9 + 'F7');
  It(cmEdit, 'Sa~isir une grille...');
  It(cmEditDone, '~Terminer la saisie');
  Sep;
  It(cmParams, '~Param'#138'tres...' + #9 + 'F6');
  It(cmSeed, '~Graine...');
  It(cmLog, '~D'#130'tail de la g'#130'n'#130'ration...');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 82, '~Jeu');
  H1 := MenuOpen;
  It(cmCheck, '~V'#130'rifier' + #9 + 'F8');
  It(cmHint, '~Indice' + #9 + 'H');
  ItA(cmNotesMode, Chk(NotesMode), 'Mode ~notes' + #9 + 'N');
  It(cmAutoNotes, '~Remplir toutes les notes');
  It(cmUndo, '~Annuler' + #9 + 'Ctrl+Z');
  Sep;
  It(cmClearAns, '~Effacer mes r'#130'ponses');
  It(cmRestart, 'Recommencer (r'#130'ponses et ~temps)');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 83, '~Affichage');
  H1 := MenuOpen;
  ItA(cmShowSol, Chk(ShowSolution), '~Solution' + #9 + 'F9');
  ItA(cmShowNotes, Chk(ShowNotes), '~Notes');
  ItA(cmPeers, Chk(ShowPeers), 'Surligner ligne, colonne et ~carr'#130);
  ItA(cmSameDigit, Chk(SameDigit), 'Surligner les ~chiffres identiques');
  ItA(cmAutoCheck, Chk(AutoCheck), 'Signaler les ~erreurs aussit'#147't');
  Sep;
  ItA(cmToolbar, Chk(ShowToolbar), '~Barre d''outils');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 84, '~Options');
  H1 := MenuOpen;
  ItA(cmBoxes, Chk(OptBoxes), 'R'#138'gle des ~carr'#130's 3 x 3 (sinon : m'#130'thode d''origine)');
  ItA(cmUnique, Chk(OptUnique), 'Solution ~unique');
  ItA(cmSym, Chk(OptSym), 'Cases retir'#130'es en ~sym'#130'trie');
  ItA(cmShowTry, Chk(OptShowTry), 'Afficher le nombre d''~essais (/SHOWTRY)');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 85, '~?');
  H1 := MenuOpen;
  It(cmHelp, '~Aide' + #9 + 'F1');
  It(cmOpts, '~Options de GSODOKU et SSODOKU');
  Sep;
  It(cmAbout, '~A propos...');
  MenuClose(H1);
  MenuClose(H0);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

Procedure SyncMenu;
Var K : LongInt;
Begin
  For K := lvEasy To lvCustom Do SetCheck(cmLvl0 + K, OptLevel = K);
  SetCheck(cmNotesMode, NotesMode); SetCheck(cmShowSol, ShowSolution); SetCheck(cmShowNotes, ShowNotes);
  SetCheck(cmPeers, ShowPeers); SetCheck(cmSameDigit, SameDigit); SetCheck(cmAutoCheck, AutoCheck);
  SetCheck(cmToolbar, ShowToolbar); SetCheck(cmBoxes, OptBoxes); SetCheck(cmUnique, OptUnique);
  SetCheck(cmSym, OptSym); SetCheck(cmShowTry, OptShowTry);
End;

Procedure ShowPopup(X, Y : LongInt);
Begin
  If CtxMenu <> 0 Then Dummy := WinDestroyWindow(CtxMenu);
  CtxMenu := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuT));
  If CtxMenu <> 0 Then Dummy := WinPopupMenu(Client, Client, CtxMenu, X, CH - 1 - Y, 0, 0);
End;

Procedure TbAdd(Cmd, Ico : LongInt; Txt, Tip : String);
Begin
  If NTb >= MaxTb Then Exit;
  TbCmd[NTb] := Cmd; TbIco[NTb] := Ico; TbTxt[NTb] := Txt; TbTip[NTb] := Tip;
  If Cmd = 0 Then TbW[NTb] := 6
  Else If Txt <> '' Then TbW[NTb] := 30 + Length(Txt) * 8
  Else TbW[NTb] := 24;
  If NTb = 0 Then TbX[NTb] := 4 Else TbX[NTb] := TbX[NTb - 1] + TbW[NTb - 1] + 2;
  Inc(NTb);
End;

Procedure ToolbarInit;
Begin
  NTb := 0; TbDown := -1; TbHot := -1;
  TbAdd(cmNew, 1, '', 'Nouvelle grille (F2)');
  TbAdd(cmOpen, 2, '', 'Ouvrir une grille .SDK (Ctrl+O)');
  TbAdd(cmSave, 3, '', 'Enregistrer la grille .SDK (Ctrl+S)');
  TbAdd(cmExport, 4, '', 'Exporter : texte ou page Web (Ctrl+E)');
  TbAdd(0, 0, '', '');
  TbAdd(cmGenerate, 5, 'G'#130'n'#130'rer', 'R'#130'g'#130'n'#130'rer une grille, nouvelle graine (F5)');
  TbAdd(cmSolve, 6, 'R'#130'soudre', 'R'#130'soudre la grille, comme SSODOKU (F7)');
  TbAdd(0, 0, '', '');
  TbAdd(cmShowSol, 7, 'Solution', 'Afficher ou cacher la solution (F9)');
  TbAdd(cmCheck, 8, '', 'V'#130'rifier mes r'#130'ponses (F8)');
  TbAdd(cmHint, 9, '', 'Indice : une case juste (H)');
  TbAdd(cmNotesMode, 12, '', 'Mode notes : petits chiffres (N)');
  TbAdd(cmUndo, 13, '', 'Annuler (Ctrl+Z)');
  TbAdd(0, 0, '', '');
  TbAdd(cmParams, 10, '', 'Param'#138'tres (F6)');
  TbAdd(cmHelp, 11, '', 'Aide (F1)');
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure SetTitle;
Var S : String;
Begin
  If FromFile Then S := GridName + ' - G'#130'n'#130'rateur de Sodoku'
  Else S := 'G'#130'n'#130'rateur de Sodoku';
  Dummy := WinSetWindowText(Frame, Z(S));
End;

Procedure NewGame;
Begin
  ResetPlay;
  UndoN := 0; Errors := 0; Hints := 0; Elapsed := 0;
  Checked := False; Solved := False; ShowSolution := False; EditMode := False;
  CurX := 5; CurY := 5;
  SyncMenu;
  SetTitle;
  Layout;
  Redraw;
End;

Procedure DoGenerate(Same : Boolean);
Var Keep : LongInt; H : Boolean;
Begin
  Keep := OptSeed; H := OptHasSeed;
  If Same And Ready And Not FromFile Then
  Begin
    OptSeed := LastSeed; OptHasSeed := True;
  End;
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 3, 0));
  StatusMsg := 'G'#130'n'#130'ration...';
  InvalStatus;
  Dummy := WinUpdateWindow(Client);
  If Generate Then
  Begin
    NewGame;
    StatusMsg := 'Nouvelle grille : cliquez une case et tapez un chiffre (N : notes, F8 : v'#130'rifier).';
    If OptShowTry Then StatusMsg := GenMsg + '.';
  End
  Else
  Begin
    StatusMsg := GenMsg;
    MsgErr(GenMsg + #10#10'Augmentez le nombre d''essais (Grille - Param'#138'tres) ou r'#130'essayez.');
  End;
  OptSeed := Keep; OptHasSeed := H;
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 1, 0));
  Redraw;
End;

{ toutes les cases sont-elles justes ? }
Procedure TestSolved;
Var X, Y : LongInt; Ok : Boolean;
Begin
  If Solved Or Not Ready Then Exit;
  Ok := True;
  For Y := 1 To 9 Do
    For X := 1 To 9 Do
      If (Giv[Y, X] = 0) And (Usr[Y, X] <> Sol[Y, X]) Then Ok := False;
  If Ok Then
  Begin
    Solved := True;
    StatusMsg := 'Bravo ! Grille r'#130'solue en ' + TimeStr + '.';
    Redraw;
    Msg('Bravo ! La grille est r'#130'solue en ' + TimeStr + ' (' + IStr(Hints) + ' indice(s), ' + IStr(Errors) +
        ' erreur(s) v'#130'rifi'#130'e(s)).');
  End;
End;

Procedure PushUndo(Y, X : LongInt);
Var K : LongInt;
Begin
  If UndoN >= MaxUndo Then
  Begin
    For K := 0 To MaxUndo - 2 Do
    Begin
      UndoY[K] := UndoY[K + 1]; UndoX[K] := UndoX[K + 1]; UndoV[K] := UndoV[K + 1]; UndoNt[K] := UndoNt[K + 1];
    End;
    UndoN := MaxUndo - 1;
  End;
  UndoY[UndoN] := Y; UndoX[UndoN] := X;
  If EditMode Then UndoV[UndoN] := Giv[Y, X] Else UndoV[UndoN] := Usr[Y, X];
  UndoNt[UndoN] := Notes[Y, X];
  Inc(UndoN);
End;

Procedure Undo;
Begin
  If UndoN = 0 Then Exit;
  Dec(UndoN);
  CurY := UndoY[UndoN]; CurX := UndoX[UndoN];
  If EditMode Then Giv[CurY, CurX] := UndoV[UndoN] Else Usr[CurY, CurX] := UndoV[UndoN];
  Notes[CurY, CurX] := UndoNt[UndoN];
  Redraw;
End;

{ un chiffre (0 : effacer) dans la case courante }
Procedure PutDigit(D : LongInt);
Var K, J, I, BY, BX : LongInt;
Begin
  If (CurX = 0) Or (Not Ready And Not EditMode) Then Exit;
  If EditMode Then
  Begin
    PushUndo(CurY, CurX);
    Giv[CurY, CurX] := D;
    InvalBoard; InvalPanel;
    Exit;
  End;
  If (Giv[CurY, CurX] <> 0) Or ShowSolution Or Solved Then Exit;
  PushUndo(CurY, CurX);
  If NotesMode And (D > 0) Then
  Begin
    Notes[CurY, CurX] := Notes[CurY, CurX] Xor (1 Shl D);
    Usr[CurY, CurX] := 0;
  End
  Else
  Begin
    Usr[CurY, CurX] := D;
    If D > 0 Then
    Begin
      { le chiffre quitte les notes de la ligne, de la colonne et du carre }
      For K := 1 To 9 Do
      Begin
        Notes[CurY, K] := Notes[CurY, K] And Not (1 Shl D);
        Notes[K, CurX] := Notes[K, CurX] And Not (1 Shl D);
      End;
      If OptBoxes Then
      Begin
        BY := ((CurY - 1) Div 3) * 3; BX := ((CurX - 1) Div 3) * 3;
        For J := BY + 1 To BY + 3 Do
          For I := BX + 1 To BX + 3 Do Notes[J, I] := Notes[J, I] And Not (1 Shl D);
      End;
    End
    Else Notes[CurY, CurX] := 0;
  End;
  Bad[CurY, CurX] := False;
  InvalBoard; InvalPanel; InvalStatus;
  TestSolved;
End;

Procedure CheckAnswers;
Var X, Y, B, E : LongInt;
Begin
  If Not Ready Then Exit;
  B := 0; E := 0;
  For Y := 1 To 9 Do
    For X := 1 To 9 Do
      If Giv[Y, X] = 0 Then
      Begin
        Bad[Y, X] := (Usr[Y, X] <> 0) And (Usr[Y, X] <> Sol[Y, X]);
        If Usr[Y, X] = 0 Then Inc(E)
        Else If Bad[Y, X] Then Inc(B);
      End;
  Errors := Errors + B;
  Checked := True;
  ShowSolution := False;
  SyncMenu;
  Redraw;
  If (B = 0) And (E = 0) Then TestSolved
  Else
  Begin
    StatusMsg := IStr(B) + ' chiffre(s) faux (en rouge), ' + IStr(E) + ' case(s) vide(s).';
    InvalStatus;
  End;
End;

Procedure Hint;
Var X, Y, Bx, By, Best, N, V : LongInt;
Begin
  If Not Ready Or Solved Then Exit;
  { la case courante si elle est vide ou fausse, sinon la case vide la plus contrainte }
  Bx := 0; By := 0;
  If (CurX > 0) And (Giv[CurY, CurX] = 0) And (Usr[CurY, CurX] <> Sol[CurY, CurX]) Then
  Begin
    Bx := CurX; By := CurY;
  End
  Else
  Begin
    Best := 10;
    For Y := 1 To 9 Do
      For X := 1 To 9 Do
        If (Giv[Y, X] = 0) And (Usr[Y, X] <> Sol[Y, X]) Then
        Begin
          Work := Giv;
          N := 0;
          For V := 1 To 9 Do If CanPut(Work, Y, X, V) Then Inc(N);
          If N < Best Then
          Begin
            Best := N; Bx := X; By := Y;
          End;
        End;
  End;
  If Bx = 0 Then Exit;
  CurX := Bx; CurY := By;
  PushUndo(By, Bx);
  Usr[By, Bx] := Sol[By, Bx];
  Notes[By, Bx] := 0;
  Inc(Hints);
  StatusMsg := 'Indice : ' + IStr(Sol[By, Bx]) + ' en ligne ' + IStr(By) + ', colonne ' + IStr(Bx) + '.';
  Redraw;
  TestSolved;
End;

{ notes : tous les chiffres possibles dans les cases vides }
Procedure AutoNotes;
Var X, Y, V : LongInt;
Begin
  If Not Ready Or ShowSolution Then Exit;
  For Y := 1 To 9 Do
    For X := 1 To 9 Do
      If Giv[Y, X] <> 0 Then Work[Y, X] := Giv[Y, X] Else Work[Y, X] := Usr[Y, X];
  For Y := 1 To 9 Do
    For X := 1 To 9 Do
      If Work[Y, X] = 0 Then
      Begin
        PushUndo(Y, X);
        Notes[Y, X] := 0;
        For V := 1 To 9 Do
          If CanPut(Work, Y, X, V) Then Notes[Y, X] := Notes[Y, X] Or (1 Shl V);
      End;
  ShowNotes := True;
  SyncMenu;
  Redraw;
End;

{ ==================================================================== }
{ Fichiers, resolution, saisie, parametres                              }
{ ==================================================================== }

Function CanWriteDir(D : String) : Boolean;
Var T, S : String;
Begin
  T := JoinPath(D, 'GSTEST.TMP');
  S := 'x';
  CanWriteDir := WriteAll(T, @S[1], 1) And FExists(T);
  Dummy := DosDelete(Z(T));
End;

Function ListFiles(D, Pat : String) : String;
Var Bf : Array[0..299] Of Byte; H, N, K, L : LongInt; S, R : String;
Begin
  R := '';
  H := -1; N := 1;
  If DosFindFirst(Z(JoinPath(D, Pat)), LongInt(@H), $27, LongInt(@Bf), SizeOf(Bf), LongInt(@N), 1) = 0 Then
  Begin
    Repeat
      L := Bf[28];
      S := '';
      For K := 1 To L Do S := S + Chr(Bf[28 + K]);
      If Length(R) + Length(S) < 200 Then R := R + ' ' + S;
      N := 1;
    Until DosFindNext(H, LongInt(@Bf), SizeOf(Bf), LongInt(@N)) <> 0;
    Dummy := DosFindClose(H);
  End;
  ListFiles := R;
End;

Function FullName(N : String) : String;
Begin
  N := Trim(N);
  If (N <> '') And ((Length(N) < 2) Or (N[2] <> ':')) Then N := JoinPath(WorkDir, N);
  FullName := N;
End;

Function CountGiven : LongInt;
Var X, Y, N : LongInt;
Begin
  N := 0;
  For Y := 1 To 9 Do
    For X := 1 To 9 Do If Giv[Y, X] <> 0 Then Inc(N);
  CountGiven := N;
End;

{ solution exacte de Giv dans Sol ; rend le nombre de solutions (0, 1, 2) }
Function SolveExact : LongInt;
Var N : LongInt;
Begin
  ClearGrid(Sol);
  If Not GridValid(Giv) Then
  Begin
    SolveExact := 0;
    Exit;
  End;
  N := CountSolutions(Giv, 2);
  If N > 0 Then Sol := FirstSol;
  SolveTries := NodeCount;
  SolveExact := N;
End;

{ la grille Giv devient la partie (fichier ouvert ou saisie) }
Procedure UseGrid(Name : String);
Var N : LongInt;
Begin
  NGiven := CountGiven;
  N := SolveExact;
  FromFile := True; GridName := Name; Ready := True;
  NewGame;
  If N = 0 Then
  Begin
    StatusMsg := 'Cette grille n''a pas de solution (selon les r'#138'gles choisies).';
    MsgErr(StatusMsg);
  End
  Else If N > 1 Then StatusMsg := 'Grille charg'#130'e : elle a plusieurs solutions (une est gard'#130'e).'
  Else StatusMsg := 'Grille charg'#130'e : ' + IStr(NGiven) + ' cases donn'#130'es, solution unique.';
  InvalStatus;
End;

Procedure OpenDlg;
Var L, F : String; G : TGrid;
Begin
  DlgReset;
  L := ListFiles(WorkDir, '*.SDK');
  If L = '' Then L := ' (aucune)';
  DlgLabel(Fit('Grilles de ' + WorkDir + ' :' + L, 590));
  DlgEdit('Fichier de la grille (.SDK) :', JoinPath(WorkDir, 'GRILLE.SDK'));
  DlgLabel('9 lignes de 9 caract'#138'res : 1 '#133' 9, autre caract'#138're : case vide.');
  If Not DlgRun('Ouvrir une grille', 'Ouvrir') Then Exit;
  F := FullName(DfVal[1]);
  If ExtOf(F) = '' Then F := F + '.SDK';
  If Not LoadSdk(F, G) Then
  Begin
    MsgErr('Erreur de lecture du fichier ' + F + ' !');
    Exit;
  End;
  Giv := G;
  ExportName := F;
  UseGrid(NameOf(F));
End;

Procedure SaveDlg(Solution, Ask : Boolean);
Var F : String;
Begin
  If Not Ready Then Exit;
  F := ExportName;
  If Ask Or (F = '') Or Solution Then
  Begin
    DlgReset;
    If Solution Then F := JoinPath(WorkDir, 'SOLUTION.SDK')
    Else If F = '' Then F := JoinPath(WorkDir, 'GRILLE.SDK');
    DlgEdit('Fichier (.SDK) :', F);
    If Solution Then
    Begin
      If Not DlgRun('Enregistrer la solution', 'Enregistrer') Then Exit;
    End
    Else If Not DlgRun('Enregistrer la grille', 'Enregistrer') Then Exit;
    F := FullName(DfVal[0]);
    If ExtOf(F) = '' Then F := F + '.SDK';
  End;
  If Solution Then
  Begin
    If SaveSdk(F, Sol) Then StatusMsg := 'Solution enregistr'#130'e : ' + F Else MsgErr('Impossible d''enregistrer ' + F + '.');
  End
  Else
  Begin
    If SaveSdk(F, Giv) Then
    Begin
      ExportName := F;
      StatusMsg := 'Grille enregistr'#130'e : ' + F;
    End
    Else MsgErr('Impossible d''enregistrer ' + F + '.');
  End;
  InvalStatus;
End;

Procedure ExportDlg;
Var F : String; K : LongInt; Ok : Boolean;
Begin
  If Not Ready Then Exit;
  DlgReset;
  DlgEdit('Fichier :', JoinPath(WorkDir, 'SODOKU.TXT'));
  DlgCombo('Format :', 'Texte (.TXT)|Page Web (.HTM)', 0);
  DlgCheck('Grille '#133' jouer', True);
  DlgCheck('Solution', True);
  If Not DlgRun('Exporter', 'Exporter') Then Exit;
  K := DlgInt(1);
  F := FullName(DfVal[0]);
  If K = 1 Then
  Begin
    If UpStr(ExtOf(F)) = 'TXT' Then F := Copy(F, 1, Length(F) - 3) + 'HTM';
    ExportHtml(DlgBool(3), DlgBool(2));
  End
  Else ExportText(DlgBool(3), DlgBool(2));
  If ExtOf(F) = '' Then
  Begin
    If K = 1 Then F := F + '.HTM' Else F := F + '.TXT';
  End;
  Ok := WriteAll(F, OutB.P, OutB.Len);
  If Ok Then StatusMsg := 'Export'#130' : ' + F Else MsgErr('Impossible d'''#130'crire ' + F + '.');
  InvalStatus;
End;

Procedure CopyText;
Var T : PBytes; N : LongInt;
Begin
  If Not Ready Then Exit;
  ExportText(False, True);
  N := MinI(OutB.Len, 16000);
  GetMem(T, N + 1);
  If T = Nil Then Exit;
  Move(OutB.P^[0], T^[0], N);
  T^[N] := 0;
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    Dummy := WinSetClipbrdData(Hab, LongInt(T), 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
  FreeMem(T, N + 1);
  StatusMsg := 'Grille copi'#130'e dans le presse-papiers.';
  InvalStatus;
End;

{ Resoudre (SSODOKU) : la grille donnee, par retour arriere ou par la
  methode d'origine (essais aleatoires) }
Procedure DoSolve;
Var N : LongInt;
Begin
  If EditMode Then
  Begin
    { fin de la saisie }
    EditMode := False;
    UseGrid('Grille saisie');
    Exit;
  End;
  If Not Ready Then Exit;
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 3, 0));
  If OptSolveOrig Then
  Begin
    RndInit(PTicks);
    N := SolveOriginal(Giv);
    Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 1, 0));
    If N = 0 Then
    Begin
      MsgErr('Nombre d''essais insuffisant ! (' + IStr(OptSolveTries) + ' essais, m'#130'thode de SSODOKU)');
      Exit;
    End;
    Sol := Work;
    SolveTries := N;
    StatusMsg := 'R'#130'solue par la m'#130'thode de SSODOKU : ' + IStr(N) + ' essai(s).';
  End
  Else
  Begin
    N := SolveExact;
    Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 1, 0));
    If N = 0 Then
    Begin
      MsgErr('Cette grille n''a pas de solution.');
      Exit;
    End;
    StatusMsg := 'R'#130'solue par retour arri'#138're : ' + IStr(SolveTries) + ' positions examin'#130'es';
    If N > 1 Then StatusMsg := StatusMsg + ' (plusieurs solutions)';
    StatusMsg := StatusMsg + '.';
  End;
  ShowSolution := True;
  SyncMenu;
  Redraw;
  If OptShowTry Then Msg(StatusMsg);
End;

Procedure StartEdit;
Begin
  If Not AskYes('Saisir une nouvelle grille ? Les chiffres tap'#130's seront les cases donn'#130'es ; ' +
                'Grille - Terminer la saisie (F7) la r'#130'sout.') Then Exit;
  ClearGrid(Giv); ClearGrid(Sol); ResetPlay;
  EditMode := True; Ready := False; FromFile := True; GridName := 'Grille saisie';
  ShowSolution := False; UndoN := 0; CurX := 1; CurY := 1; NGiven := 0;
  StatusMsg := 'Saisie : tapez les chiffres donn'#130's (fl'#138'ches pour se d'#130'placer), puis F7.';
  SyncMenu;
  Redraw;
End;

Procedure ParamsDlg;
Var Ok : Boolean; V : LongInt; N : String;
Begin
  DlgReset;
  DlgCombo('Niveau :', 'Facile (40)|Moyen (32)|Difficile (27)|Expert (23)|Personnalis'#130, OptLevel);
  DlgEdit('Cases donn'#130'es (personnalis'#130') :', IStr(OptGivens));
  DlgCheck('R'#138'gle des carr'#130's 3 x 3 (sinon : m'#130'thode d''origine de GSODOKU)', OptBoxes);
  DlgEdit('Essais de la m'#130'thode d''origine (GSODOKU) :', IStr(OptMaxTry));
  DlgCheck('Solution unique', OptUnique);
  DlgCheck('Cases retir'#130'es en sym'#130'trie centrale', OptSym);
  DlgCheck('Afficher le nombre d''essais (/SHOWTRY)', OptShowTry);
  If OptSolveOrig Then V := 1 Else V := 0;
  DlgCombo('R'#130'solution (SSODOKU) :', 'Exacte (retour arri'#138're)|Essais al'#130'atoires (SSODOKU)', V);
  DlgEdit('Essais de la r'#130'solution al'#130'atoire :', IStr(OptSolveTries));
  If OptHasSeed Then N := IStr(OptSeed) Else N := '';
  DlgEdit('Graine fixe (rien : hasard) :', N);
  DlgCheck('R'#130'g'#130'n'#130'rer maintenant', True);
  If Not DlgRun('Param'#138'tres', 'OK') Then Exit;
  OptLevel := DlgInt(0);
  Ok := ParseNum(DfVal[1], 17, 80, OptGivens);
  OptBoxes := DlgBool(2);
  Ok := ParseNum(DfVal[3], 1, 1000000, OptMaxTry) And Ok;
  OptUnique := DlgBool(4); OptSym := DlgBool(5); OptShowTry := DlgBool(6);
  OptSolveOrig := DlgInt(7) = 1;
  Ok := ParseNum(DfVal[8], 1, 100000000, OptSolveTries) And Ok;
  If Trim(DfVal[9]) = '' Then OptHasSeed := False
  Else If ParseNum(DfVal[9], 0, 2147483647, OptSeed) Then OptHasSeed := True
  Else Ok := False;
  SyncMenu;
  If Not Ok Then MsgErr('Certaines valeurs sont hors limites ; elles n''ont pas '#130't'#130' chang'#130'es.');
  If DlgBool(10) Then DoGenerate(False) Else Redraw;
End;

Procedure CustomLevel;
Begin
  DlgReset;
  DlgEdit('Cases donn'#130'es (17 '#133' 80) :', IStr(OptGivens));
  If Not DlgRun('Niveau personnalis'#130, 'G'#130'n'#130'rer') Then Exit;
  If Not ParseNum(DfVal[0], 17, 80, OptGivens) Then
  Begin
    MsgErr('Valeur hors limites (17 '#133' 80).');
    Exit;
  End;
  OptLevel := lvCustom;
  SyncMenu;
  DoGenerate(False);
End;

Procedure SeedDlg;
Begin
  DlgReset;
  DlgLabel('Graine de la derni'#138're grille : ' + IStr(LastSeed) + ' (la m'#136'me graine donne la m'#136'me grille).');
  If OptHasSeed Then DlgEdit('Graine (rien : hasard) :', IStr(OptSeed)) Else DlgEdit('Graine (rien : hasard) :', '');
  If Not DlgRun('Graine', 'G'#130'n'#130'rer') Then Exit;
  If Trim(DfVal[1]) = '' Then OptHasSeed := False
  Else If ParseNum(DfVal[1], 0, 2147483647, OptSeed) Then OptHasSeed := True
  Else
  Begin
    MsgErr('Graine invalide.');
    Exit;
  End;
  DoGenerate(False);
End;

Procedure ShowLog;
Var S : String;
Begin
  If FromFile Then S := 'Grille : ' + GridName + #10'Positions examin'#130'es par la r'#130'solution : ' + IStr(SolveTries)
  Else
  Begin
    If OptBoxes Then S := 'M'#130'thode : grille compl'#138'te (lignes, colonnes et carr'#130's 3 x 3)'
    Else S := 'M'#130'thode : d''origine de GSODOKU (lignes et colonnes)';
    S := S + #10 + GenMsg + #10'Graine : ' + IStr(LastSeed) + #10'Niveau : ' + LevelName(OptLevel) + ', ' +
         IStr(NGiven) + ' cases donn'#130'es';
    If OptUnique Then S := S + ', solution unique';
    If OptSym Then S := S + ', sym'#130'trie centrale';
  End;
  Msg(S);
End;

Procedure ShowHelp(Which : LongInt);
Var B : TBuf;
Begin
  BufInit(B);
  If Which = 0 Then
  Begin
    BufAdd(B, 'Sodoku : chaque ligne, chaque colonne et chaque carr'#130' 3 x 3 contiennent les chiffres de 1 '#133' 9 ');
    BufAdd(B, 'une seule fois (avec la m'#130'thode d''origine de GSODOKU : seulement les lignes et les colonnes).'#10#10);
    BufAdd(B, 'Cliquez une case et tapez un chiffre (ou le pav'#130' '#133' droite) ; 0, Suppr ou Retour arri'#138're ');
    BufAdd(B, 'effacent ; N : mode notes (petits chiffres) ; H : indice ; Ctrl+Z : annuler.'#10#10);
    BufAdd(B, 'F2 : nouvelle grille ; F5 : r'#130'g'#130'n'#130'rer ; F6 : param'#138'tres ; F7 : r'#130'soudre ; ');
    BufAdd(B, 'F8 : v'#130'rifier ; F9 : solution ; Ctrl+O, Ctrl+S : ouvrir, enregistrer une grille .SDK.'#10#10);
    BufAdd(B, 'Grille - Saisir une grille : tapez les chiffres donn'#130's d''une grille du journal, puis F7 ');
    BufAdd(B, 'pour la r'#130'soudre et la jouer.');
    ShowBuf('Aide du G'#130'n'#130'rateur de Sodoku', B);
  End
  Else
  Begin
    BufAdd(B, 'GSODOKU [/SHOWTRY] : grille 9 x 9 (option Afficher le nombre d''essais).'#10);
    BufAdd(B, 'SSODOKU fichier.SDK [/SHOWTRY] : r'#130'soudre une grille (Fichier - Ouvrir, puis Grille - ');
    BufAdd(B, 'R'#130'soudre).'#10#10);
    BufAdd(B, 'Param'#138'tres du programme : [fichier.SDK] [/SHOWTRY] [/S:graine] [/LEVEL:F|M|D|E|n] [/CLASSIC] ');
    BufAdd(B, '[/TRY:n] [/SOLVE] [/SSODOKU] [/PUZZLE] [/OUT:fichier].'#10#10);
    BufAdd(B, 'Avec /OUT, rien ne s''affiche : la grille compl'#138'te (comme GSODOKU), la solution du fichier ');
    BufAdd(B, '(/SOLVE, comme SSODOKU) ou la grille '#133' jouer (/PUZZLE, fichier .SDK) est '#130'crite. ');
    BufAdd(B, '/CLASSIC : m'#130'thode d''origine (lignes et colonnes) ; /SSODOKU : r'#130'solution par essais ');
    BufAdd(B, 'al'#130'atoires ; /TRY:n : nombre d''essais.');
    ShowBuf('Options de GSODOKU et SSODOKU', B);
  End;
  BufFree(B);
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Procedure DoCmd(C : LongInt);
Begin
  If (C >= cmLvl0) And (C <= cmLvl0 + lvCustom) Then
  Begin
    If C = cmLvl0 + lvCustom Then CustomLevel
    Else
    Begin
      OptLevel := C - cmLvl0;
      SyncMenu;
      DoGenerate(False);
    End;
    Exit;
  End;
  If (C > cmDigit0) And (C <= cmDigit0 + 9) Then
  Begin
    PutDigit(C - cmDigit0);
    Exit;
  End;
  Case C Of
    cmNew, cmGenerate : DoGenerate(False);
    cmSameSeed : DoGenerate(True);
    cmOpen : OpenDlg;
    cmSave : SaveDlg(False, False);
    cmSaveAs : SaveDlg(False, True);
    cmSaveSol : SaveDlg(True, True);
    cmExport : ExportDlg;
    cmCopyText : CopyText;
    cmQuit : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    cmSolve, cmEditDone : If (C = cmSolve) Or EditMode Then DoSolve;
    cmEdit : StartEdit;
    cmParams : ParamsDlg;
    cmSeed : SeedDlg;
    cmLog : ShowLog;
    cmCheck : CheckAnswers;
    cmHint : Hint;
    cmNotesMode : Begin NotesMode := Not NotesMode; SyncMenu; InvalPanel; End;
    cmAutoNotes : AutoNotes;
    cmUndo : Undo;
    cmClearAns :
      Begin
        ResetPlay;
        Checked := False; Solved := False; UndoN := 0;
        StatusMsg := 'R'#130'ponses effac'#130'es.';
        Redraw;
      End;
    cmRestart :
      Begin
        NewGame;
        StatusMsg := 'Partie recommenc'#130'e.';
        Redraw;
      End;
    cmShowSol : Begin ShowSolution := Not ShowSolution; SyncMenu; Redraw; End;
    cmShowNotes : Begin ShowNotes := Not ShowNotes; SyncMenu; InvalBoard; End;
    cmPeers : Begin ShowPeers := Not ShowPeers; SyncMenu; InvalBoard; End;
    cmSameDigit : Begin SameDigit := Not SameDigit; SyncMenu; InvalBoard; End;
    cmAutoCheck : Begin AutoCheck := Not AutoCheck; SyncMenu; InvalBoard; End;
    cmToolbar : Begin ShowToolbar := Not ShowToolbar; SyncMenu; Layout; Redraw; End;
    cmBoxes :
      Begin
        OptBoxes := Not OptBoxes;
        SyncMenu;
        DoGenerate(False);
      End;
    cmUnique : Begin OptUnique := Not OptUnique; SyncMenu; End;
    cmSym : Begin OptSym := Not OptSym; SyncMenu; End;
    cmShowTry : Begin OptShowTry := Not OptShowTry; SyncMenu; InvalPanel; End;
    cmHelp : ShowHelp(0);
    cmOpts : ShowHelp(1);
    cmAbout :
      Msg('G'#130'n'#130'rateur de Sodoku pour OS/2-0' + #10#10 + 'Interface de GSODOKU et SSODOKU ' +
          '(d'#130'p'#244't VIE de Gladir.com) avec les menus et l''apparence d''OS/2.' + #10#10 + 'Gladir.com');
  End;
  InvalBand(0, 0, CW, TbH);
End;

{ ==================================================================== }
{ Souris                                                                }
{ ==================================================================== }

Procedure ToolbarDown(X : LongInt);
Var I : LongInt;
Begin
  For I := 0 To NTb - 1 Do
    If (TbCmd[I] <> 0) And (X >= TbX[I]) And (X < TbX[I] + TbW[I]) Then
    Begin
      If TbDisabled(TbCmd[I]) Then Exit;
      TbDown := I;
      Drag := dTool;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
      InvalBand(0, 0, CW, TbH);
      Exit;
    End;
End;

Function BoardHit(X, Y : LongInt; Var Cx, Cy : LongInt) : Boolean;
Begin
  BoardHit := False;
  If (X < BX0) Or (Y < BY0) Or (X >= BX0 + 9 * Cs) Or (Y >= BY0 + 9 * Cs) Then Exit;
  Cx := (X - BX0) Div Cs + 1; Cy := (Y - BY0) Div Cs + 1;
  BoardHit := True;
End;

Procedure MouseDown(X, Y : LongInt);
Var Cx, Cy, K, X1, Y1_, X2, Y2 : LongInt;
Begin
  If ShowToolbar And (Y < TbH) Then
  Begin
    ToolbarDown(X);
    Exit;
  End;
  If Y >= CH - SbH Then Exit;
  If X >= PnX Then
  Begin
    For K := 1 To 11 Do
    Begin
      PadRect(K, X1, Y1_, X2, Y2);
      If (X >= X1) And (X <= X2) And (Y >= Y1_) And (Y <= Y2) Then
      Begin
        If K <= 9 Then PutDigit(K)
        Else If K = 10 Then PutDigit(0)
        Else DoCmd(cmNotesMode);
        Exit;
      End;
    End;
    Exit;
  End;
  If BoardHit(X, Y, Cx, Cy) Then
  Begin
    CurX := Cx; CurY := Cy;
    InvalBoard;
  End;
End;

Procedure MouseMove(X, Y : LongInt);
Var I, H : LongInt;
Begin
  If Drag = dTool Then Exit;
  H := -1;
  If ShowToolbar And (Y < TbH) Then
    For I := 0 To NTb - 1 Do
      If (TbCmd[I] <> 0) And (X >= TbX[I]) And (X < TbX[I] + TbW[I]) Then H := I;
  If H <> TbHot Then
  Begin
    If TbHot < 0 Then SavedMsg := StatusMsg;
    TbHot := H;
    If H >= 0 Then StatusMsg := TbTip[H] Else StatusMsg := SavedMsg;
    InvalStatus;
    InvalBand(0, 0, CW, TbH);
  End;
End;

Procedure MouseUp(X, Y : LongInt);
Var I : LongInt;
Begin
  If Drag = dTool Then
  Begin
    Dummy := WinSetCapture(HWND_DESKTOP, 0);
    Drag := dNone;
    I := TbDown;
    TbDown := -1;
    InvalBand(0, 0, CW, TbH);
    If (I >= 0) And (Y < TbH) And (X >= TbX[I]) And (X < TbX[I] + TbW[I]) Then DoCmd(TbCmd[I]);
  End;
End;

Procedure RightClick(X, Y : LongInt);
Var H, Cx, Cy, K : LongInt;
Begin
  If Not BoardHit(X, Y, Cx, Cy) Then Exit;
  CurX := Cx; CurY := Cy;
  InvalBoard;
  MenuLen := 0;
  H := MenuOpen;
  For K := 1 To 9 Do It(cmDigit0 + K, '~' + Chr(48 + K));
  Sep;
  It(cmDigit0, '~Effacer la case');
  It(cmHint, '~Indice' + #9 + 'H');
  ItA(cmNotesMode, Chk(NotesMode), 'Mode ~notes' + #9 + 'N');
  Sep;
  It(cmCheck, '~V'#130'rifier' + #9 + 'F8');
  It(cmShowSol, 'Afficher ou cacher la ~solution' + #9 + 'F9');
  MenuClose(H);
  ShowPopup(X, Y);
End;

{ ==================================================================== }
{ Clavier                                                               }
{ ==================================================================== }

Procedure MoveCur(Dx, Dy : LongInt);
Begin
  If CurX = 0 Then
  Begin
    CurX := 5; CurY := 5;
  End
  Else
  Begin
    CurX := ((CurX - 1 + Dx + 9) Mod 9) + 1;
    CurY := ((CurY - 1 + Dy + 9) Mod 9) + 1;
  End;
  InvalBoard;
End;

Function Key(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch_, Vk, K : LongInt; Ctrl, Shift : Boolean;
Begin
  Key := True;
  Fl := Lo16(Mp1); Ch_ := Lo16(Mp2); Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
    Key := False;
    Exit;
  End;
  Ctrl := (Fl And KC_CTRL) <> 0;
  Shift := (Fl And KC_SHIFT) <> 0;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    Case Vk Of
      VK_F1 : Begin DoCmd(cmHelp); Exit; End;
      VK_F2 : Begin DoCmd(cmNew); Exit; End;
      VK_F5 :
        Begin
          If Shift Then DoCmd(cmSameSeed) Else DoCmd(cmGenerate);
          Exit;
        End;
      VK_F6 : Begin DoCmd(cmParams); Exit; End;
      VK_F8 : Begin DoCmd(cmCheck); Exit; End;
      VK_F9 : Begin DoCmd(cmShowSol); Exit; End;
      VK_LEFT : Begin MoveCur(-1, 0); Exit; End;
      VK_RIGHT : Begin MoveCur(1, 0); Exit; End;
      VK_UP : Begin MoveCur(0, -1); Exit; End;
      VK_DOWN : Begin MoveCur(0, 1); Exit; End;
      VK_DELETE, VK_BACKSPACE : Begin PutDigit(0); Exit; End;
    End;
    If Vk = $26 Then
    Begin
      { F7 }
      DoCmd(cmSolve);
      Exit;
    End;
  End;
  If Ctrl And (Ch_ > 0) And (Ch_ < 128) Then
  Begin
    K := Ch_;
    If (K >= 1) And (K <= 26) Then K := K + 96;
    If (K >= 65) And (K <= 90) Then K := K + 32;
    Case K Of
      Ord('o') : Begin DoCmd(cmOpen); Exit; End;
      Ord('s') : Begin DoCmd(cmSave); Exit; End;
      Ord('e') : Begin DoCmd(cmExport); Exit; End;
      Ord('c') : Begin DoCmd(cmCopyText); Exit; End;
      Ord('z') : Begin DoCmd(cmUndo); Exit; End;
    End;
  End;
  If ((Fl And KC_CHAR) <> 0) And Not Ctrl And ((Fl And KC_ALT) = 0) Then
  Begin
    If (Ch_ >= Ord('1')) And (Ch_ <= Ord('9')) Then
    Begin
      PutDigit(Ch_ - 48);
      Exit;
    End;
    If (Ch_ = Ord('0')) Or (Ch_ = Ord('.')) Or (Ch_ = 32) Then
    Begin
      PutDigit(0);
      Exit;
    End;
    If (Ch_ = Ord('n')) Or (Ch_ = Ord('N')) Then
    Begin
      DoCmd(cmNotesMode);
      Exit;
    End;
    If (Ch_ = Ord('h')) Or (Ch_ = Ord('H')) Then
    Begin
      DoCmd(cmHint);
      Exit;
    End;
  End;
  Key := False;
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

Function ClientProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; X, Y : LongInt;
Begin
  ClientProc := 0;
  Case Msg_ Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
        Layout;
        Redraw;
      End;
    WM_PAINT : Paint(H);
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
      Begin
        X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        LastMx := X; LastMy := Y;
        MouseDown(X, Y);
        ClientProc := 1;
      End;
    WM_BUTTON1UP :
      Begin
        MouseUp(S16(Mp1), CH - 1 - S16(Mp1 Shr 16));
        ClientProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
        LastMx := X; LastMy := Y;
        MouseMove(X, Y);
        ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
      End;
    WM_BUTTON2DOWN :
      Begin
        RightClick(S16(Mp1), CH - 1 - S16(Mp1 Shr 16));
        ClientProc := 1;
      End;
    WM_CHAR :
      If Key(Mp1, Mp2) Then ClientProc := 1
      Else ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
    WM_COMMAND : DoCmd(Lo16(Mp1));
    WM_TIMER :
      If Ready And Not Solved And Not ShowSolution And Not EditMode Then
      Begin
        Inc(Elapsed);
        InvalPanel;
        InvalStatus;
      End;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Parametres et mode sans fenetre (/OUT)                                }
{ ==================================================================== }

Var
  CliFile, CliOut, CliErr : String;
  CliSolve, CliPuzzle : Boolean;

Procedure ParseArgs;
Var I, P, V : LongInt; A, U, Name, S : String;
Begin
  CliFile := ''; CliOut := ''; CliErr := ''; CliSolve := False; CliPuzzle := False;
  For I := 1 To ParamCount Do
  Begin
    A := ParamStr(I);
    U := UpStr(A);
    If (Length(A) > 1) And ((A[1] = '/') Or (A[1] = '-')) Then
    Begin
      P := Pos(':', U);
      If P = 0 Then P := Pos('=', U);
      If P > 0 Then
      Begin
        Name := Copy(U, 2, P - 2); S := Copy(A, P + 1, 255);
      End
      Else
      Begin
        Name := Copy(U, 2, 255); S := '';
      End;
      If Name = 'SHOWTRY' Then OptShowTry := True
      Else If Name = 'CLASSIC' Then OptBoxes := False
      Else If Name = 'SOLVE' Then CliSolve := True
      Else If Name = 'SSODOKU' Then OptSolveOrig := True
      Else If Name = 'PUZZLE' Then CliPuzzle := True
      Else If (Name = 'OUT') Or (Name = 'O') Then CliOut := S
      Else If Name = 'S' Then
      Begin
        If ParseNum(S, 0, 2147483647, OptSeed) Then OptHasSeed := True Else CliErr := 'Graine invalide : ' + S;
      End
      Else If Name = 'TRY' Then
      Begin
        If ParseNum(S, 1, 100000000, V) Then
        Begin
          OptMaxTry := V; OptSolveTries := V;
        End
        Else CliErr := 'Nombre d''essais invalide : ' + S;
      End
      Else If Name = 'LEVEL' Then
      Begin
        S := UpStr(S);
        If S = 'F' Then OptLevel := lvEasy
        Else If S = 'M' Then OptLevel := lvMedium
        Else If S = 'D' Then OptLevel := lvHard
        Else If S = 'E' Then OptLevel := lvExpert
        Else If ParseNum(S, 17, 80, OptGivens) Then OptLevel := lvCustom
        Else CliErr := 'Niveau invalide : ' + S;
      End
      Else If (Name <> '?') And (Name <> 'H') Then CliErr := 'Option inconnue : ' + A;
    End
    Else CliFile := A;
  End;
End;

{ ecriture comme GSODOKU et SSODOKU : "Nombre d'essaie : K", ligne vide, 9 lignes "d d d ..." }
Procedure Batch;
Var N : LongInt;
Begin
  OutB.Len := 0;
  If CliFile <> '' Then
  Begin
    If Not LoadSdk(CliFile, Giv) Then Halt(2);
    Begin
      If OptSolveOrig Then
      Begin
        RndInit(PTicks);
        If OptHasSeed Then RndInit(OptSeed);
        N := SolveOriginal(Giv);
        If N > 0 Then Sol := Work;
      End
      Else
      Begin
        N := SolveExact;
        If N > 0 Then N := MaxI(1, SolveTries);
      End;
      If OptShowTry Then BufAdd(OutB, 'Nombre d''essaie : ' + IStr(N) + #13#10#13#10);
      If N = 0 Then
      Begin
        BufAdd(OutB, 'Nombre d''essaie insuffisant !'#13#10);
        If WriteAll(CliOut, OutB.P, OutB.Len) Then ;
        Halt(3);
      End;
      GridText(Sol, False);
    End;
  End
  Else
  Begin
    If Not Generate Then
    Begin
      BufAdd(OutB, 'Nombre d''essaie insuffisant !'#13#10);
      If WriteAll(CliOut, OutB.P, OutB.Len) Then ;
      Halt(3);
    End;
    If CliPuzzle Then GridText(Giv, True)
    Else
    Begin
      If OptShowTry Then BufAdd(OutB, 'Nombre d''essaie : ' + IStr(GenTries) + #13#10#13#10);
      GridText(Sol, False);
    End;
  End;
  If Not WriteAll(CliOut, OutB.P, OutB.Len) Then Halt(2);
End;

Procedure Main;
Var Fl, Sw, Sh, Fw, Fh : LongInt; G : TGrid;
Begin
  InitDefaults;
  BufInit(OutB);
  ShowSolution := False; ShowPeers := True; AutoCheck := False; ShowToolbar := True; ShowNotes := True;
  SameDigit := True; NotesMode := False; Checked := False; Solved := False; EditMode := False;
  CurX := 5; CurY := 5; Errors := 0; Elapsed := 0; Hints := 0; UndoN := 0;
  CtxMenu := 0; Drag := dNone; StatusMsg := 'Pr'#136't.'; SavedMsg := ''; GridName := ''; ExportName := '';
  ParseArgs;
  If CliOut <> '' Then
  Begin
    If CliErr <> '' Then Halt(1);
    Batch;
    Exit;
  End;
  WorkDir := 'C:\';
  If Not CanWriteDir(WorkDir) Then
    If CanWriteDir('D:\') Then WorkDir := 'D:\';
  ToolbarInit;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('GSODOKU'), LongInt(@ClientProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('GSODOKU'), Z2('G'#130'n'#130'rateur de Sodoku'),
                              0, 0, 0, LongInt(@Client));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Fw := MinI(Sw, 640); Fh := MinI(Sh - 20, 460);
  If Sw >= 1000 Then
  Begin
    Fw := 900; Fh := MinI(Sh - 40, 680);
  End
  Else If Sw >= 800 Then
  Begin
    Fw := 796; Fh := MinI(Sh - 30, 560);
  End;
  CW := Fw - 8; CH := Fh - 40;
  BuildMenu;
  SetTitle;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Layout;
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  Dummy := WinStartTimer(Hab, Client, 1, 1000);
  If CliErr <> '' Then MsgErr(CliErr);
  If (CliFile <> '') And LoadSdk(CliFile, G) Then
  Begin
    Giv := G;
    ExportName := CliFile;
    UseGrid(NameOf(CliFile));
    If CliSolve Then DoSolve;
  End
  Else DoGenerate(False);
  While WinGetMsg(Hab, LongInt(@GQmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@GQmsg));
  Dummy := WinDestroyWindow(Frame);
End;

BEGIN
  Main;
END.
