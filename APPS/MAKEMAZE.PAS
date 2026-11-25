{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: MAKEMAZE - Generateur de labyrinthe pour le Presentation
                Manager d'OS/2-0, base sur MAKEMAZE.PAS du depot VIE.
}

Program MakeMaze;

{$R-,S-,I-}

(* Compilation : OS2PC MAKEMAZE.PAS MAKEMAZE.EXE

  Generateur de labyrinthe (dossier Loisirs du bureau), l'interface
  graphique de MAKEMAZE.PAS du depot VIE (https://github.com/gladir/vie),
  avec les menus et l'apparence d'OS/2.

    - au centre, l'apercu du labyrinthe : entree a gauche, sortie a
      droite, chemin parcouru, solution ; on le parcourt au clavier
      (fleches, WASD, ZQSD, IJKM comme l'original) ou a la souris ;
    - a droite, le labyrinthe (dimensions, branche, graine, solution,
      culs-de-sac), la partie (deplacements, temps, distance) et un pave
      de direction ;
    - barre d'outils : nouveau, ouvrir, enregistrer, exporter, regenerer,
      solution, resoudre (anime), indice, retour, recommencer, parametres.

  Generation : l'algorithme de MAKEMAZE (cellules frontieres, branches
  d'au plus /MAXBRANCH cases), sur une grille de 640 / n x 350 / n cases
  (/WIDTH=n, comme l'ecran de l'original) ou de dimensions choisies ;
  resolution : celle de MAKEMAZE (on longe les murs, le bit 7 marque le
  chemin). /SHOWGRAPH : la construction est animee.

  Parametres : [fichier] [/SHOWGRAPH] [/WIDTH=largeur] [/MAXBRANCH=branche]
  [/SOLVE] [/FILE:fichier] [/SAVECSV:fichier] [/S:graine] [/SIZE:LxH]
  [/TEXT:fichier] [/HTML:fichier] [/BMP:fichier] ; avec /FILE ou /SAVECSV
  (ou un format d'export), le labyrinthe est ecrit sans fenetre, comme la
  commande d'origine (avec /SHOWGRAPH, la fenetre s'ouvre ensuite). *)

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
{ Moteur : MAKEMAZE (generation, resolution, fichiers)                  }
{ ==================================================================== }

Const
  AppTitle = 'G'#130'n'#130'rateur de labyrinthe';
  { comme MAKEMAZE : ecran de 640 x 350, au plus 200 x 109 cases }
  ScreenW0 = 640; ScreenH0 = 350;
  MaxX = 200; MaxY = 109; MaxCells = 21800;
  MinBW = 2; MaxBW = 95;
  { murs enleves (bits 0 a 3), type de cellule (bits 4 et 5), chemin (bit 7) }
  dE = $01; dN = $02; dW = $04; dS = $08;
  fUnused = $00; fFrontier = $10; fReserved = $20; fTree = $30; fPath = $80;
  { difficultes : taille des cases (/WIDTH) }
  NDiff = 6;
  DiffBW : Array[0..5] Of LongInt = (48, 32, 16, 8, 4, 2);
  { branches maximales proposees (/MAXBRANCH) }
  NBr = 6;
  BrVal : Array[0..5] Of LongInt = (0, 1, 5, 10, 25, 50);

Var
  MzW, MzH : LongInt;           { dimensions du labyrinthe (cases) }
  FNum, RunSet, MaxRun : LongInt;
  NOrd, StpN : LongInt;         { murs enleves (dans l'ordre), pas de la resolution }
  SX, SY, EX, EY : LongInt;     { entree (colonne 1) et sortie (derniere colonne) }
  Fl : PBytes;                  { drapeaux des cases }
  Pt : PLongs;                  { position dans la liste des frontieres }
  FLst : PLongs;                { liste des frontieres : colonne + rangee * 256 }
  EIx, SIx : PLongs;            { rang de l'enlevement du mur Est / Sud }
  Stp : PLongs;                 { pas de la resolution : case * 2 + bit du chemin }
  Prv : PLongs;                 { vers la sortie : case suivante + distance * 32768 }
  BQ : PLongs;                  { file du parcours en largeur }
  { options }
  OptBW, OptBranch, OptW, OptH : LongInt;
  OptCustom, OptSolveNow, OptAnimate, OptDoors : Boolean;
  OptSeed, LastSeed : LongInt;
  OptHasSeed : Boolean;
  { resultats }
  Ready, FromFile : Boolean;
  PathLen, DeadEnds, Crossings, SolveSteps : LongInt;
  GenMsg : String;
  OutB : TBuf;
  RSeed : LongInt;

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

Function ParseNum(S : String; Lo, Hi : LongInt; Var V : LongInt) : Boolean;
Var N, E : LongInt; Ok : Boolean;
Begin
  S := Trim(S);
  Val(S, N, E);
  Ok := (E = 0) And (S <> '') And (N >= Lo) And (N <= Hi);
  If Ok Then V := N;
  ParseNum := Ok;
End;

{ indice d'une case (colonne X, rangee Y, a partir de 1) }
Function CI(X, Y : LongInt) : LongInt;
Begin
  CI := (Y - 1) * MaxX + X - 1;
End;

Function CX(C : LongInt) : LongInt;
Begin
  CX := C Mod MaxX + 1;
End;

Function CY(C : LongInt) : LongInt;
Begin
  CY := C Div MaxX + 1;
End;

{ dimensions comme GetSize de MAKEMAZE : 640 / n et 350 / n cases }
Procedure SizeOfBW(BW : LongInt; Var W, H : LongInt);
Begin
  W := ScreenW0 Div BW;
  If ScreenW0 Mod BW = 0 Then Dec(W);
  H := ScreenH0 Div BW;
  If ScreenH0 Mod BW = 0 Then Dec(H);
  If (W > MaxX) Or (H > MaxY) Then
  Begin
    W := MaxX; H := MaxY;
  End;
  If W < 1 Then W := 1;
  If H < 1 Then H := 1;
End;

Function DiffName(K : LongInt) : String;
Var R : String;
Begin
  Case K Of
    0 : R := 'Tr'#138's facile';
    1 : R := 'Facile';
    2 : R := 'Moyen';
    3 : R := 'Difficile';
    4 : R := 'Expert';
    5 : R := 'Extr'#136'me';
  Else
    R := 'Personnalis'#130;
  End;
  DiffName := R;
End;

{ difficulte d'apres la taille des cases (NDiff : personnalisee) }
Function CurDiff : LongInt;
Var K, R : LongInt;
Begin
  R := NDiff;
  If Not OptCustom Then
    For K := 0 To NDiff - 1 Do
      If DiffBW[K] = OptBW Then R := K;
  CurDiff := R;
End;

Function DiffLabel(K : LongInt) : String;
Var W, H : LongInt; R : String;
Begin
  SizeOfBW(DiffBW[K], W, H);
  R := DiffName(K) + ' (' + IStr(W) + ' x ' + IStr(H) + ', cases de ' + IStr(DiffBW[K]) + ')';
  DiffLabel := R;
End;

Function BranchName(V : LongInt) : String;
Var R : String;
Begin
  If V <= 0 Then R := 'illimit'#130'e' Else R := IStr(V);
  BranchName := R;
End;

{ --- algorithme de MAKEMAZE --- }

Function Adjust(Var X, Y : LongInt; D : LongInt) : Boolean;
Begin
  Adjust := False;
  Case D Of
    dE : Begin Inc(X); Adjust := X <= MzW; End;
    dN : Begin Dec(Y); Adjust := Y > 0; End;
    dW : Begin Dec(X); Adjust := X > 0; End;
    dS : Begin Inc(Y); Adjust := Y <= MzH; End;
  End;
End;

Procedure Remove(X, Y : LongInt);
Var I, P : LongInt;
Begin
  I := Pt^[CI(X, Y)];
  P := FLst^[FNum];
  Pt^[CI(P And 255, P Shr 8)] := I;
  FLst^[I] := FLst^[FNum];
  Dec(FNum);
End;

Procedure Add(X, Y, D : LongInt);
Var I, C : LongInt;
Begin
  C := CI(X, Y);
  I := Fl^[C];
  Case I And $30 Of
    fUnused :
      Begin
        Fl^[C] := I Or fFrontier;
        Inc(FNum);
        FLst^[FNum] := X + Y Shl 8;
        Pt^[C] := FNum;
        RunSet := RunSet Or D;
      End;
    fFrontier : RunSet := RunSet Or D;
  End;
End;

Procedure AddFront(X, Y : LongInt);
Var J, K, D, C : LongInt;
Begin
  Remove(X, Y);
  RunSet := 0;
  C := CI(X, Y);
  Fl^[C] := Fl^[C] Or fTree;
  D := $01;
  While D <= $08 Do
  Begin
    J := X; K := Y;
    If Adjust(J, K, D) Then Add(J, K, D);
    D := D Shl 1;
  End;
End;

Procedure RemBar(X, Y, D : LongInt);
Var D2, C : LongInt;
Begin
  Inc(NOrd);
  Case D Of
    dE : EIx^[CI(X, Y)] := NOrd;
    dS : SIx^[CI(X, Y)] := NOrd;
    dW : EIx^[CI(X - 1, Y)] := NOrd;
    dN : SIx^[CI(X, Y - 1)] := NOrd;
  End;
  C := CI(X, Y);
  Fl^[C] := Fl^[C] Or D;
  D2 := D Shl 2;
  If D2 > $08 Then D2 := D2 Shr 4;
  If Adjust(X, Y, D) Then
  Begin
    C := CI(X, Y);
    Fl^[C] := Fl^[C] Or D2;
  End;
End;

Function RandomDir : LongInt;
Var R : LongInt;
Begin
  Case Rnd(4) Of
    0 : R := dE;
    1 : R := dN;
    2 : R := dW;
  Else
    R := dS;
  End;
  RandomDir := R;
End;

Procedure Connect(X, Y : LongInt);
Var J, K, D : LongInt; Found : Boolean;
Begin
  Found := False;
  D := dE;
  While Not Found Do
  Begin
    J := X; K := Y;
    D := RandomDir;
    If Adjust(J, K, D) Then Found := (Fl^[CI(J, K)] And fTree) = fTree;
  End;
  RemBar(X, Y, D);
End;

Procedure Branch(X, Y : LongInt);
Var RunNum, D : LongInt;
Begin
  RunNum := MaxRun;
  Connect(X, Y);
  AddFront(X, Y);
  Dec(RunNum);
  While (RunNum > 0) And (FNum > 0) And (RunSet > 0) Do
  Begin
    Repeat
      D := RandomDir;
    Until (D And RunSet) > 0;
    RemBar(X, Y, D);
    If Adjust(X, Y, D) Then ;
    AddFront(X, Y);
    Dec(RunNum);
  End;
End;

{ resolution de MAKEMAZE : on longe les murs ; le bit 7 d'une case
  devient l'inverse de celui de la case suivante (les impasses s'effacent).
  Chaque pas est garde pour l'animation. }
Function SolveMaze : Boolean;
Var X, Y, J, K, D, N, C, Nv, Guard : LongInt;
Begin
  SolveMaze := False;
  For Y := 1 To MzH Do
    For X := 1 To MzW Do
    Begin
      C := CI(X, Y);
      Fl^[C] := Fl^[C] And $7F;
    End;
  StpN := 0;
  X := SX; Y := SY;
  D := dE;
  Guard := 0;
  While (X <> EX) Or (Y <> EY) Do
  Begin
    If D = $01 Then D := $08 Else D := D Shr 1;
    N := 0;
    While (Fl^[CI(X, Y)] And D) = 0 Do
    Begin
      D := D Shl 1;
      If D > $08 Then D := D Shr 4;
      Inc(N);
      If N > 4 Then Exit;
    End;
    J := X; K := Y;
    If Not Adjust(X, Y, D) Then Exit;
    C := CI(J, K);
    Nv := (Fl^[CI(X, Y)] And fPath) Xor fPath;
    Fl^[C] := (Fl^[C] And $7F) Or Nv;
    If StpN < 2 * MaxCells Then
    Begin
      Stp^[StpN] := C * 2 + (Nv Shr 7);
      Inc(StpN);
    End;
    Inc(Guard);
    If Guard > 4 * MaxCells Then Exit;
  End;
  SolveSteps := Guard;
  SolveMaze := True;
End;

Function IsPath(X, Y : LongInt) : Boolean;
Begin
  IsPath := ((Fl^[CI(X, Y)] And fPath) <> 0) Or ((X = EX) And (Y = EY));
End;

Function Openings(X, Y : LongInt) : LongInt;
Var F, N : LongInt;
Begin
  F := Fl^[CI(X, Y)];
  N := 0;
  If (F And dE) <> 0 Then Inc(N);
  If (F And dN) <> 0 Then Inc(N);
  If (F And dW) <> 0 Then Inc(N);
  If (F And dS) <> 0 Then Inc(N);
  Openings := N;
End;

{ parcours en largeur depuis la sortie : Prv = case suivante vers la sortie
  et distance ; rend le nombre de cases atteintes }
Function ComputeToExit : LongInt;
Var Hd, Tl, C, X, Y, J, K, D, Dist : LongInt;
Begin
  For Y := 1 To MzH Do
    For X := 1 To MzW Do Prv^[CI(X, Y)] := -1;
  Hd := 0; Tl := 0;
  C := CI(EX, EY);
  Prv^[C] := C;
  BQ^[Tl] := C; Inc(Tl);
  While Hd < Tl Do
  Begin
    C := BQ^[Hd]; Inc(Hd);
    X := CX(C); Y := CY(C);
    Dist := Prv^[C] Shr 15;
    D := $01;
    While D <= $08 Do
    Begin
      If (Fl^[C] And D) <> 0 Then
      Begin
        J := X; K := Y;
        If Adjust(J, K, D) Then
          If Prv^[CI(J, K)] < 0 Then
          Begin
            Prv^[CI(J, K)] := C + (Dist + 1) Shl 15;
            BQ^[Tl] := CI(J, K); Inc(Tl);
          End;
      End;
      D := D Shl 1;
    End;
  End;
  ComputeToExit := Tl;
End;

Function DistToExit(X, Y : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := Prv^[CI(X, Y)];
  If P < 0 Then DistToExit := -1 Else DistToExit := P Shr 15;
End;

Function NextToExit(C : LongInt) : LongInt;
Begin
  NextToExit := Prv^[C] And $7FFF;
End;

Procedure ComputeStats;
Var X, Y, N : LongInt;
Begin
  PathLen := 0; DeadEnds := 0; Crossings := 0;
  For Y := 1 To MzH Do
    For X := 1 To MzW Do
    Begin
      If IsPath(X, Y) Then Inc(PathLen);
      N := Openings(X, Y);
      If N = 1 Then Inc(DeadEnds);
      If N >= 3 Then Inc(Crossings);
    End;
End;

{ apres une generation ou un chargement : solution, distances, statistiques }
Function Finish : Boolean;
Var Ok : Boolean;
Begin
  Ok := SolveMaze;
  If ComputeToExit < MzW * MzH Then Ok := False;
  ComputeStats;
  Ready := True;
  Finish := Ok;
End;

Procedure SetSize;
Begin
  If OptCustom Then
  Begin
    MzW := OptW; MzH := OptH;
  End
  Else SizeOfBW(OptBW, MzW, MzH);
  MaxRun := OptBranch;
  If MaxRun <= 0 Then MaxRun := 65535;
End;

{ DrawMaze et SolveMaze de MAKEMAZE (le hasard vient de la graine) }
Function Generate : Boolean;
Var X, Y, P : LongInt;
Begin
  SetSize;
  If OptHasSeed Then LastSeed := OptSeed
  Else LastSeed := (PTicks * 7919 + LastSeed * 31 + 1) And $7FFFFFF;
  RndInit(LastSeed);
  FillChar(Fl^, MaxCells, 0);
  FillChar(EIx^, MaxCells * 4, 0);
  FillChar(SIx^, MaxCells * 4, 0);
  NOrd := 0; FNum := 0; RunSet := 0;
  X := Rnd(MzW) + 1;
  Y := Rnd(MzH) + 1;
  Add(X, Y, dE);
  AddFront(X, Y);
  While FNum > 0 Do
  Begin
    P := FLst^[Rnd(FNum) + 1];
    Branch(P And 255, P Shr 8);
  End;
  SX := 1; SY := Rnd(MzH) + 1;
  EX := MzW; EY := Rnd(MzH) + 1;
  FromFile := False;
  Generate := Finish;
  GenMsg := 'Labyrinthe de ' + IStr(MzW) + ' x ' + IStr(MzH) + ' cases, ' + IStr(NOrd) + ' murs enlev'#130's';
End;

{ --- fichiers --- }

Function DoorW(Y : LongInt) : Boolean;
Begin
  DoorW := OptDoors And (Y = SY);
End;

Function DoorE(Y : LongInt) : Boolean;
Begin
  DoorE := OptDoors And (Y = EY);
End;

{ fichier texte de MAKEMAZE (/FILE) : 3 x 3 caracteres par case ;
  WithSol : les points du chemin (bit 7) }
Procedure MazeText(WithSol : Boolean);
Var I, J, F : LongInt;

  Procedure PutC(C : Char);
  Begin
    BufAddC(OutB, Ord(C));
  End;

  Procedure Border;
  Var K : LongInt;
  Begin
    PutC('#');
    For K := 1 To MzW Do
    Begin
      PutC('#'); PutC('#'); PutC('#');
    End;
    PutC('#');
    PutC(#13); PutC(#10);
  End;

Begin
  OutB.Len := 0;
  Border;
  For J := 1 To MzH Do
  Begin
    PutC('#');
    For I := 1 To MzW Do
    Begin
      F := Fl^[CI(I, J)];
      If Not WithSol Then F := F And $7F;
      If (F And dW) = 0 Then PutC('#') Else PutC(' ');
      If (F And dN) = 0 Then PutC('#') Else If (F And fPath) = fPath Then PutC('.') Else PutC(' ');
      If (F And dE) = 0 Then PutC('#') Else PutC(' ');
    End;
    PutC('#'); PutC(#13); PutC(#10);
    If DoorW(J) Then PutC(' ') Else PutC('#');
    For I := 1 To MzW Do
    Begin
      F := Fl^[CI(I, J)];
      If Not WithSol Then F := F And $7F;
      If ((F And dW) = 0) And Not ((I = 1) And DoorW(J)) Then PutC('#')
      Else If (F And fPath) = fPath Then PutC('.') Else PutC(' ');
      If (F And fPath) = fPath Then PutC('.') Else If (F And fTree) = fTree Then PutC('#') Else PutC(' ');
      If ((F And dE) = 0) And Not ((I = MzW) And DoorE(J)) Then PutC('#')
      Else If (F And fPath) = fPath Then PutC('.') Else PutC(' ');
    End;
    If DoorE(J) Then PutC(' ') Else PutC('#');
    PutC(#13); PutC(#10);
    PutC('#');
    For I := 1 To MzW Do
    Begin
      F := Fl^[CI(I, J)];
      If Not WithSol Then F := F And $7F;
      If (F And dW) = 0 Then PutC('#') Else PutC(' ');
      If (F And dS) = 0 Then PutC('#') Else If (F And fPath) = fPath Then PutC('.') Else PutC(' ');
      If (F And dE) = 0 Then PutC('#') Else PutC(' ');
    End;
    PutC('#'); PutC(#13); PutC(#10);
  End;
  Border;
End;

{ fichier CSV de MAKEMAZE (/SAVECSV) : les drapeaux de chaque case }
Procedure MazeCsv(WithSol : Boolean);
Var I, J, F : LongInt;
Begin
  OutB.Len := 0;
  For J := 1 To MzH Do
  Begin
    For I := 1 To MzW Do
    Begin
      If I > 1 Then BufAddC(OutB, Ord(','));
      F := Fl^[CI(I, J)];
      If Not WithSol Then F := F And $7F;
      BufAdd(OutB, IStr(F));
    End;
    BufAdd(OutB, #13#10);
  End;
End;

{ caractere de la grille compacte (2L+1 x 2H+1) ; Mode 1 : HTML (chemin en rouge) }
Function CompactCh(R, Q : LongInt; WithSol : Boolean) : Char;
Var I, J, F : LongInt; C : Char;
Begin
  C := '#';
  I := (Q + 1) Div 2; J := (R + 1) Div 2;
  If Odd(R) And Odd(Q) Then
  Begin
    { une case }
    If WithSol And IsPath(I, J) Then C := '.' Else C := ' ';
  End
  Else If Odd(R) And Not Odd(Q) Then
  Begin
    { mur vertical entre la case Q/2 et Q/2 + 1 }
    I := Q Div 2;
    If I = 0 Then
    Begin
      If J = SY Then
      Begin
        If WithSol Then C := '.' Else C := ' ';
      End;
    End
    Else If I = MzW Then
    Begin
      If J = EY Then
      Begin
        If WithSol Then C := '.' Else C := ' ';
      End;
    End
    Else
    Begin
      F := Fl^[CI(I, J)];
      If (F And dE) <> 0 Then
      Begin
        If WithSol And IsPath(I, J) And IsPath(I + 1, J) Then C := '.' Else C := ' ';
      End;
    End;
  End
  Else If Not Odd(R) And Odd(Q) Then
  Begin
    J := R Div 2;
    If (J > 0) And (J < MzH) Then
    Begin
      F := Fl^[CI(I, J)];
      If (F And dS) <> 0 Then
      Begin
        If WithSol And IsPath(I, J) And IsPath(I, J + 1) Then C := '.' Else C := ' ';
      End;
    End;
  End;
  CompactCh := C;
End;

Procedure MazeCompact(WithSol : Boolean);
Var R, Q : LongInt;
Begin
  OutB.Len := 0;
  For R := 0 To 2 * MzH Do
  Begin
    For Q := 0 To 2 * MzW Do BufAddC(OutB, Ord(CompactCh(R, Q, WithSol)));
    BufAdd(OutB, #13#10);
  End;
End;

Procedure MazeHtml(WithSol : Boolean);
Var R, Q : LongInt; C, Lc : Char;
Begin
  OutB.Len := 0;
  BufAdd(OutB, '<!DOCTYPE html>'#13#10'<html><head><meta charset="ISO-8859-1">'#13#10);
  BufAdd(OutB, '<title>Labyrinthe ' + IStr(MzW) + ' x ' + IStr(MzH) + '</title>'#13#10);
  BufAdd(OutB, '<style>body{font-family:sans-serif;margin:2em}pre{font:10px/10px monospace;letter-spacing:0}');
  BufAdd(OutB, '.m{background:#000;color:#000}.s{color:#c00;font-weight:bold}</style></head><body>'#13#10);
  BufAdd(OutB, '<h1>Labyrinthe ' + IStr(MzW) + ' x ' + IStr(MzH) + '</h1>'#13#10);
  If FromFile Then BufAdd(OutB, '<p>Entr'#233'e '#224' gauche, sortie '#224' droite.</p>'#13#10)
  Else BufAdd(OutB, '<p>Entr'#233'e '#224' gauche, sortie '#224' droite. Graine ' + IStr(LastSeed) +
                    ', branche maximale ' + BranchName(OptBranch) + '.</p>'#13#10);
  BufAdd(OutB, '<pre>');
  For R := 0 To 2 * MzH Do
  Begin
    Lc := ' ';
    For Q := 0 To 2 * MzW Do
    Begin
      C := CompactCh(R, Q, WithSol);
      If C <> Lc Then
      Begin
        If Lc <> ' ' Then BufAdd(OutB, '</span>');
        If C = '#' Then BufAdd(OutB, '<span class="m">')
        Else If C = '.' Then BufAdd(OutB, '<span class="s">');
        Lc := C;
      End;
      If C = '#' Then BufAdd(OutB, '##')
      Else If C = '.' Then BufAdd(OutB, '()')
      Else BufAdd(OutB, '  ');
    End;
    If Lc <> ' ' Then BufAdd(OutB, '</span>');
    BufAdd(OutB, #13#10);
  End;
  BufAdd(OutB, '</pre>'#13#10'<p>G'#233'n'#233'r'#233' par le G'#233'n'#233'rateur de labyrinthe d''OS/2-0 ');
  BufAdd(OutB, '(MAKEMAZE du d'#233'p'#244't VIE).</p></body></html>'#13#10);
End;

{ image BMP (8 bits, 4 couleurs) ; Px : pixels par case }
Procedure MazeBmp(WithSol : Boolean; Px : LongInt);
Var Iw, Ih, Rw, R, Ro, Co, Cl, Sz, K : LongInt;

  Procedure L32(V : LongInt);
  Begin
    BufAddC(OutB, V); BufAddC(OutB, V Shr 8); BufAddC(OutB, V Shr 16); BufAddC(OutB, V Shr 24);
  End;

  Procedure W16(V : LongInt);
  Begin
    BufAddC(OutB, V); BufAddC(OutB, V Shr 8);
  End;

Begin
  OutB.Len := 0;
  If Px < 2 Then Px := 2;
  { la grille compacte, chaque caractere sur Px / 2 pixels (murs et couloirs de meme largeur) }
  Iw := (2 * MzW + 1) * Px Div 2 + 1;
  Ih := (2 * MzH + 1) * Px Div 2 + 1;
  Rw := (Iw + 3) And Not 3;
  Sz := 54 + 16 + Rw * Ih;
  BufAdd(OutB, 'BM'); L32(Sz); L32(0); L32(54 + 16);
  L32(40); L32(Iw); L32(Ih); W16(1); W16(8); L32(0); L32(Rw * Ih); L32(2835); L32(2835); L32(4); L32(4);
  { palette : blanc, noir, rouge, vert }
  L32($FFFFFF); L32($000000); L32($D00000); L32($008000);
  If Not BufGrow(OutB, Rw * Ih) Then Exit;
  For R := Ih - 1 DownTo 0 Do
  Begin
    { rangee R du haut de l'image : position dans la grille compacte }
    Ro := R * 2 Div Px;
    If Ro > 2 * MzH Then Ro := 2 * MzH;
    For K := 0 To Rw - 1 Do
    Begin
      Cl := 0;
      If K < Iw Then
      Begin
        Co := K * 2 Div Px;
        If Co > 2 * MzW Then Co := 2 * MzW;
        Case CompactCh(Ro, Co, WithSol) Of
          '#' : Cl := 1;
          '.' : Cl := 2;
        End;
        If ((Co = 0) And (Ro = 2 * SY - 1)) Or ((Co = 2 * MzW) And (Ro = 2 * EY - 1)) Then Cl := 3;
      End;
      OutB.P^[OutB.Len] := Cl;
      Inc(OutB.Len);
    End;
  End;
End;

{ --- lecture : texte de MAKEMAZE, texte compact ou CSV --- }

Var
  LnOfs, LnLen : Array[0..800] Of LongInt;
  NLn : LongInt;
  InB : TBuf;
  Pth : Array[0..MaxY + 1] Of Byte;  { 1 : chemin en colonne 1, 2 : chemin en derniere colonne }

Function LnCh(L, K : LongInt) : Char;
Begin
  If (L < 0) Or (L >= NLn) Or (K < 0) Or (K >= LnLen[L]) Then LnCh := '#'
  Else LnCh := Chr(InB.P^[LnOfs[L] + K]);
End;

Function ReadFileBuf(Name : String) : Boolean;
Var H, N : LongInt; Tmp : Array[0..4095] Of Byte;
Begin
  ReadFileBuf := False;
  InB.Len := 0;
  If Not FOpenRead(Name, H) Then Exit;
  Repeat
    N := FRead(H, @Tmp, SizeOf(Tmp));
    If N > 0 Then BufAddB(InB, @Tmp, N);
  Until (N <= 0) Or (InB.Len > 2000000);
  DosClose(H);
  NLn := 0;
  N := 0;
  While (N < InB.Len) And (NLn <= 800) Do
  Begin
    LnOfs[NLn] := N;
    While (N < InB.Len) And (InB.P^[N] <> 10) And (InB.P^[N] <> 13) Do Inc(N);
    LnLen[NLn] := N - LnOfs[NLn];
    If N < InB.Len Then
    Begin
      If (InB.P^[N] = 13) And (N + 1 < InB.Len) And (InB.P^[N + 1] = 10) Then Inc(N);
      Inc(N);
    End;
    { lignes vides en fin de fichier ignorees }
    If LnLen[NLn] > 0 Then Inc(NLn);
  End;
  ReadFileBuf := NLn > 0;
End;

{ murs symetriques ; toutes les cases deviennent des cases de l'arbre }
Procedure FixWalls;
Var X, Y, C : LongInt;
Begin
  For Y := 1 To MzH Do
    For X := 1 To MzW Do
    Begin
      C := CI(X, Y);
      Fl^[C] := (Fl^[C] And $0F) Or fTree;
      If X = 1 Then Fl^[C] := Fl^[C] And Not dW;
      If X = MzW Then Fl^[C] := Fl^[C] And Not dE;
      If Y = 1 Then Fl^[C] := Fl^[C] And Not dN;
      If Y = MzH Then Fl^[C] := Fl^[C] And Not dS;
    End;
  For Y := 1 To MzH Do
    For X := 1 To MzW Do
    Begin
      C := CI(X, Y);
      If (X < MzW) And (((Fl^[C] And dE) <> 0) Or ((Fl^[CI(X + 1, Y)] And dW) <> 0)) Then
      Begin
        Fl^[C] := Fl^[C] Or dE; Fl^[CI(X + 1, Y)] := Fl^[CI(X + 1, Y)] Or dW;
      End;
      If (Y < MzH) And (((Fl^[C] And dS) <> 0) Or ((Fl^[CI(X, Y + 1)] And dN) <> 0)) Then
      Begin
        Fl^[C] := Fl^[C] Or dS; Fl^[CI(X, Y + 1)] := Fl^[CI(X, Y + 1)] Or dN;
      End;
    End;
End;

{ entree et sortie d'un fichier : ouverture du bord, sinon le chemin (bit 7),
  sinon la premiere et la derniere rangee }
Procedure GuessDoors(HasDoorW, HasDoorE : LongInt);
Var Y : LongInt;
Begin
  SX := 1; EX := MzW;
  SY := 1; EY := MzH;
  If HasDoorW > 0 Then SY := HasDoorW
  Else
    For Y := MzH DownTo 1 Do If (Pth[Y] And 1) <> 0 Then SY := Y;
  If HasDoorE > 0 Then EY := HasDoorE
  Else
    For Y := MzH DownTo 1 Do If (Pth[Y] And 2) <> 0 Then EY := Y;
End;

Function LoadMaze(Name : String; Var Err : String) : Boolean;
Var L, K, I, J, W, H, F, V, P, DW_, DE_ : LongInt; IsCsv, Mk : Boolean;
    C : Char;
Begin
  LoadMaze := False;
  Err := 'Fichier illisible.';
  If Not ReadFileBuf(Name) Then Exit;
  IsCsv := False;
  For K := 0 To LnLen[0] - 1 Do If LnCh(0, K) = ',' Then IsCsv := True;
  If (LnLen[0] > 0) And (LnCh(0, 0) >= '0') And (LnCh(0, 0) <= '9') Then IsCsv := True;
  FillChar(Fl^, MaxCells, 0);
  FillChar(Pth, SizeOf(Pth), 0);
  DW_ := 0; DE_ := 0;
  If IsCsv Then
  Begin
    { CSV de MAKEMAZE : une rangee par ligne, les drapeaux separes par des virgules }
    H := NLn; W := 0;
    For L := 0 To NLn - 1 Do
    Begin
      I := 0; V := 0; Mk := False;
      For K := 0 To LnLen[L] Do
      Begin
        If K < LnLen[L] Then C := LnCh(L, K) Else C := ',';
        If (C >= '0') And (C <= '9') Then
        Begin
          V := V * 10 + Ord(C) - 48; Mk := True;
        End
        Else If (C = ',') Or (C = ';') Then
        Begin
          If Mk Then
          Begin
            Inc(I);
            If (I <= MaxX) And (L < MaxY) Then Fl^[CI(I, L + 1)] := V And $FF;
          End;
          V := 0; Mk := False;
        End;
      End;
      If L = 0 Then W := I;
    End;
    If (W < 1) Or (W > MaxX) Or (H < 1) Or (H > MaxY) Then
    Begin
      Err := 'Dimensions du CSV invalides (' + IStr(W) + ' x ' + IStr(H) + ', au plus 200 x 109).';
      Exit;
    End;
    MzW := W; MzH := H;
    For J := 1 To H Do
    Begin
      If (Fl^[CI(1, J)] And fPath) <> 0 Then Pth[J] := Pth[J] Or 1;
      If (Fl^[CI(W, J)] And fPath) <> 0 Then Pth[J] := Pth[J] Or 2;
    End;
  End
  Else If LnCh(1, 1) = '#' Then
  Begin
    { texte de MAKEMAZE : 3 x 3 caracteres par case, bord de 1 }
    W := (LnLen[0] - 2) Div 3; H := (NLn - 2) Div 3;
    If (W < 1) Or (W > MaxX) Or (H < 1) Or (H > MaxY) Or ((LnLen[0] - 2) Mod 3 <> 0) Then
    Begin
      Err := 'Ce n''est pas un labyrinthe de MAKEMAZE (3 x 3 caract'#138'res par case).';
      Exit;
    End;
    MzW := W; MzH := H;
    For J := 1 To H Do
    Begin
      L := 1 + 3 * (J - 1);
      If LnCh(L + 1, 0) = ' ' Then DW_ := J;
      If LnCh(L + 1, 3 * W + 1) = ' ' Then DE_ := J;
      For I := 1 To W Do
      Begin
        K := 1 + 3 * (I - 1);
        F := 0;
        If (LnCh(L + 1, K) <> '#') And (I > 1) Then F := F Or dW;
        If (LnCh(L + 1, K + 2) <> '#') And (I < W) Then F := F Or dE;
        If LnCh(L, K + 1) <> '#' Then F := F Or dN;
        If LnCh(L + 2, K + 1) <> '#' Then F := F Or dS;
        If LnCh(L + 1, K + 1) = '.' Then
        Begin
          F := F Or fPath;
          If I = 1 Then Pth[J] := Pth[J] Or 1;
          If I = W Then Pth[J] := Pth[J] Or 2;
        End;
        Fl^[CI(I, J)] := F;
      End;
    End;
  End
  Else
  Begin
    { texte compact : 2L+1 x 2H+1 caracteres }
    W := (LnLen[0] - 1) Div 2; H := (NLn - 1) Div 2;
    If (W < 1) Or (W > MaxX) Or (H < 1) Or (H > MaxY) Then
    Begin
      Err := 'Dimensions du labyrinthe invalides.';
      Exit;
    End;
    MzW := W; MzH := H;
    For J := 1 To H Do
    Begin
      L := 2 * J - 1;
      If LnCh(L, 0) <> '#' Then DW_ := J;
      If LnCh(L, 2 * W) <> '#' Then DE_ := J;
      For I := 1 To W Do
      Begin
        K := 2 * I - 1;
        F := 0;
        If (I > 1) And (LnCh(L, K - 1) <> '#') Then F := F Or dW;
        If (I < W) And (LnCh(L, K + 1) <> '#') Then F := F Or dE;
        If (J > 1) And (LnCh(L - 1, K) <> '#') Then F := F Or dN;
        If (J < H) And (LnCh(L + 1, K) <> '#') Then F := F Or dS;
        If LnCh(L, K) = '.' Then
        Begin
          If I = 1 Then Pth[J] := Pth[J] Or 1;
          If I = W Then Pth[J] := Pth[J] Or 2;
        End;
        Fl^[CI(I, J)] := F;
      End;
    End;
  End;
  FixWalls;
  GuessDoors(DW_, DE_);
  FromFile := True;
  P := 0;
  If Not Finish Then
  Begin
    Err := 'Ce labyrinthe n''a pas de chemin de l''entr'#130'e '#133' la sortie (ou des cases inaccessibles).';
    P := 1;
  End;
  LoadMaze := True;
  If P = 0 Then Err := '';
End;

Procedure InitDefaults;
Begin
  OptBW := 16; OptBranch := 0; OptW := 40; OptH := 25; OptCustom := False;
  OptSolveNow := False; OptAnimate := True; OptDoors := True;
  OptSeed := 0; OptHasSeed := False; LastSeed := 0;
  Ready := False; FromFile := False; GenMsg := '';
  MzW := 1; MzH := 1; SX := 1; SY := 1; EX := 1; EY := 1; StpN := 0; NOrd := 0;
  PathLen := 0; DeadEnds := 0; Crossings := 0; SolveSteps := 0;
  RSeed := 12345;
  GetMem(Fl, MaxCells + 4);
  GetMem(Pt, (MaxCells + 4) * 4);
  GetMem(FLst, (MaxCells + 4) * 4);
  GetMem(EIx, (MaxCells + 4) * 4);
  GetMem(SIx, (MaxCells + 4) * 4);
  GetMem(Stp, (2 * MaxCells + 4) * 4);
  GetMem(Prv, (MaxCells + 4) * 4);
  GetMem(BQ, (MaxCells + 4) * 4);
  FillChar(Fl^, MaxCells, 0);
  BufInit(OutB);
  BufInit(InB);
End;
{ ==================================================================== }
{ Fenetre : etat, disposition et dessin                                 }
{ ==================================================================== }

Const
  PnW = 250; MaxTb = 24;
  { commandes }
  cmNew = 100; cmOpen = 101; cmSave = 102; cmSaveAs = 103; cmSaveCsv = 104; cmExport = 105; cmCopyText = 106;
  cmQuit = 107;
  cmGenerate = 120; cmSameSeed = 121; cmParams = 122; cmSeed = 123; cmStats = 124; cmCustomSize = 125;
  cmBrOther = 126;
  cmDiff0 = 130;             { + difficulte (0 a 5) }
  cmBr0 = 140;               { + branche maximale proposee (0 a 5) }
  cmShowSol = 150; cmSolveAnim = 151; cmTrail = 152; cmVisited = 153; cmToolbar = 154; cmGrid = 155;
  cmStyle0 = 156;            { + style (0 a 2) }
  cmHint = 160; cmBack = 161; cmRestart = 162; cmGiveUp = 163;
  cmUp = 164; cmDown = 165; cmLeft = 166; cmRight = 167;
  cmSolveNow = 170; cmAnimate = 171; cmDoors = 172;
  cmHelp = 180; cmOpts = 181; cmAbout = 182;
  { styles }
  NStyle = 3;
  { animations }
  anNone = 0; anGen = 1; anSolve = 2;
  MaxHint = 12;

Var
  Hab, Hmq, Frame, Client, MenuHw, Hps, CW, CH : LongInt;
  GQmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..8191] Of Byte;
  MenuLen : LongInt;
  UX1, UY1, UX2, UY2 : LongInt;
  IcX, IcY : LongInt;
  Y0, Y1, PnX : LongInt;
  PgX1, PgY1, PgX2, PgY2 : LongInt;     { feuille }
  MX0, MY0, Cs, Tw : LongInt;           { origine du labyrinthe, taille d'une case, epaisseur des murs }
  ShowSolution, ShowTrail, ShowVisited, ShowToolbar, ShowGrid : Boolean;
  Style : LongInt;
  { partie }
  PX, PY : LongInt;                     { position du joueur }
  Moves, Elapsed, Hints, StartDist : LongInt;
  Solved, GaveUp, Playing : Boolean;
  Trail : PLongs;                       { chemin de l'entree au joueur }
  TrailN : LongInt;
  InTrail, Vis, DispB : PBytes;         { case du chemin, case visitee, chemin de l'animation }
  HintC : Array[0..MaxHint - 1] Of LongInt;
  HintN : LongInt;
  { animation }
  Anim, AnimPos, AnimEnd, AnimStep, AnimT0, AnimDur : LongInt;
  { barre d'outils }
  NTb, TbDown, TbHot : LongInt;
  TbCmd, TbX, TbW, TbIco : Array[0..MaxTb - 1] Of LongInt;
  TbTxt, TbTip : Array[0..MaxTb - 1] Of String;
  StatusMsg, SavedMsg, MazeName : String;
  { couleurs du style }
  KBg, KWall, KPath, KTrail, KVis, KHint, KMe, KIn, KOut : LongInt;
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

Procedure IcoMaze(Sol : Boolean);
Begin
  IR(1, 1, 14, 14, cWhite); IB(1, 1, 14, 14, cBlack);
  IR(1, 4, 1, 6, cWhite); IR(14, 9, 14, 11, cWhite);
  IR(4, 1, 4, 10, cBlack); IR(4, 10, 8, 10, cBlack); IR(8, 4, 8, 7, cBlack); IR(8, 4, 11, 4, cBlack);
  IR(11, 4, 11, 13, cBlack); IR(4, 13, 7, 13, cBlack);
  If Sol Then
  Begin
    IR(1, 5, 2, 5, cRed); IR(2, 2, 2, 12, cRed); IR(2, 12, 9, 12, cRed); IR(9, 6, 9, 12, cRed);
    IR(9, 6, 13, 6, cRed); IR(13, 6, 13, 10, cRed); IR(13, 10, 14, 10, cRed);
  End;
End;

Procedure IcoTb(K : LongInt);
Var I : LongInt;
Begin
  Case K Of
    1 :
      Begin
        IcoMaze(False);
        IR(10, 9, 15, 10, cDGreen); IR(12, 7, 13, 12, cDGreen);
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
    6 : IcoMaze(True);
    7 :
      Begin
        { resoudre (anime) : baguette }
        Thick(IcX + 2, IcY + 13, IcX + 10, IcY + 5, cBrown);
        IR(11, 1, 11, 7, cYellow); IR(8, 4, 14, 4, cYellow); IR(9, 2, 13, 6, cYellow);
      End;
    8 :
      Begin
        { indice : ampoule }
        Disc(IcX + 8, IcY + 6, 5, cYellow); IR(6, 10, 10, 13, cGray); IR(7, 14, 9, 15, cGray);
      End;
    9 :
      Begin
        { retour d'un pas }
        IR(4, 5, 11, 6, cNavy); IR(11, 6, 12, 11, cNavy); IR(6, 11, 12, 12, cNavy);
        IR(1, 5, 4, 6, cNavy); IR(2, 3, 3, 8, cNavy); IR(3, 2, 3, 9, cNavy);
      End;
    10 :
      Begin
        { recommencer : drapeau de depart }
        IR(3, 1, 3, 15, cBlack); IR(4, 1, 13, 7, cDGreen); IR(4, 8, 4, 8, cDGreen);
        IR(1, 14, 6, 15, cGray);
      End;
    11 :
      Begin
        Disc(IcX + 8, IcY + 8, 6, cGray); Disc(IcX + 8, IcY + 8, 2, cSilver);
        IR(7, 0, 9, 2, cGray); IR(7, 14, 9, 15, cGray); IR(0, 7, 2, 9, cGray); IR(14, 7, 15, 9, cGray);
      End;
    12 :
      Begin
        Disc(IcX + 8, IcY + 8, 7, cBlue);
        IR(6, 4, 9, 4, cWhite); IR(9, 5, 10, 6, cWhite); IR(7, 7, 9, 7, cWhite); IR(7, 8, 8, 9, cWhite);
        IR(7, 11, 8, 12, cWhite);
      End;
  End;
End;

{ ==================================================================== }
{ Disposition et style                                                  }
{ ==================================================================== }

Procedure SetStyle;
Begin
  Case Style Of
    1 :
      Begin
        { d'origine : murs verts sur fond noir, chemin blanc (MAKEMAZE) }
        KBg := cBlack; KWall := cGreen; KPath := cWhite; KTrail := cYellow; KVis := cGray;
        KHint := cCyan; KMe := cYellow; KIn := cCyan; KOut := cRed;
      End;
    2 :
      Begin
        { plan d'architecte }
        KBg := cNavy; KWall := cWhite; KPath := cYellow; KTrail := cCyan; KVis := cBlue;
        KHint := cPink; KMe := cRed; KIn := cGreen; KOut := cYellow;
      End;
  Else
    Begin
      { papier }
      KBg := cWhite; KWall := cBlack; KPath := cRed; KTrail := cBlue; KVis := cSilver;
      KHint := cPink; KMe := cNavy; KIn := cDGreen; KOut := cRed;
    End;
  End;
End;

Function StyleName(K : LongInt) : String;
Var R : String;
Begin
  Case K Of
    1 : R := 'D''origine (vert sur noir, comme MAKEMAZE)';
    2 : R := 'Plan d''architecte (blanc sur bleu)';
  Else
    R := 'Papier (noir sur blanc)';
  End;
  StyleName := R;
End;

Procedure Layout;
Var Ax1, Ax2, Ay1, Ay2, A, B : LongInt;
Begin
  If ShowToolbar Then Y0 := TbH Else Y0 := 0;
  Y1 := CH - SbH - 1;
  PnX := CW - PnW;
  PgX1 := 12; PgY1 := Y0 + 12; PgX2 := PnX - 16; PgY2 := Y1 - 14;
  Ax1 := PgX1 + 12; Ax2 := PgX2 - 12; Ay1 := PgY1 + 34; Ay2 := PgY2 - 12;
  A := (Ax2 - Ax1 + 1) Div (MzW + 2);
  B := (Ay2 - Ay1 + 1) Div MaxI(1, MzH);
  Cs := MinI(A, B);
  If Cs > 48 Then Cs := 48;
  If Cs < 2 Then Cs := 2;
  Tw := 1;
  If Cs >= 14 Then Tw := 2;
  If Cs >= 30 Then Tw := 3;
  MX0 := Ax1 + ((Ax2 - Ax1 + 1) - MzW * Cs) Div 2;
  MY0 := Ay1 + ((Ay2 - Ay1 + 1) - MzH * Cs) Div 2;
  If MY0 < Ay1 Then MY0 := Ay1;
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

{ une case (et ses voisines) a redessiner }
Procedure InvalCell(X, Y : LongInt);
Begin
  InvalBand(MX0 + (X - 2) * Cs - 2, MY0 + (Y - 2) * Cs - 2, MX0 + (X + 1) * Cs + Tw + 2, MY0 + (Y + 1) * Cs + Tw + 2);
End;

{ ==================================================================== }
{ Barre d'outils                                                        }
{ ==================================================================== }

Function TbPressed(C : LongInt) : Boolean;
Begin
  TbPressed := ((C = cmShowSol) And ShowSolution) Or ((C = cmSolveAnim) And (Anim = anSolve));
End;

Function TbDisabled(C : LongInt) : Boolean;
Begin
  TbDisabled := False;
  Case C Of
    cmSave, cmExport, cmShowSol, cmSolveAnim, cmHint, cmRestart : TbDisabled := Not Ready;
    cmBack : TbDisabled := Not Ready Or (TrailN <= 1) Or Solved;
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
{ Labyrinthe                                                            }
{ ==================================================================== }

{ mur a l'Est de la case (I, J), I de 0 (bord gauche) a MzW (bord droit) }
Function WallV(I, J : LongInt) : Boolean;
Var C : LongInt; R : Boolean;
Begin
  If I = 0 Then R := (J <> SY) Or (Anim = anGen)
  Else If I = MzW Then R := (J <> EY) Or (Anim = anGen)
  Else
  Begin
    C := CI(I, J);
    R := (Fl^[C] And dE) = 0;
    If Not R And (Anim = anGen) Then R := EIx^[C] > AnimPos;
  End;
  WallV := R;
End;

{ mur au Sud de la case (I, J), J de 0 (bord du haut) a MzH (bord du bas) }
Function WallH(I, J : LongInt) : Boolean;
Var C : LongInt; R : Boolean;
Begin
  If (J = 0) Or (J = MzH) Then R := True
  Else
  Begin
    C := CI(I, J);
    R := (Fl^[C] And dS) = 0;
    If Not R And (Anim = anGen) Then R := SIx^[C] > AnimPos;
  End;
  WallH := R;
End;

{ le chemin a tracer : 0 la solution, 1 le chemin du joueur }
Function OnLine(K, I, J : LongInt) : Boolean;
Var C : LongInt; R : Boolean;
Begin
  R := False;
  If (I >= 1) And (I <= MzW) And (J >= 1) And (J <= MzH) Then
  Begin
    C := CI(I, J);
    If K = 0 Then
    Begin
      If Anim = anSolve Then R := DispB^[C] <> 0
      Else R := IsPath(I, J);
    End
    Else R := InTrail^[C] <> 0;
  End;
  OnLine := R;
End;

Procedure CellBox(I, J, C : LongInt);
Var X, Y : LongInt;
Begin
  X := MX0 + (I - 1) * Cs; Y := MY0 + (J - 1) * Cs;
  FBar(X + Tw, Y + Tw, X + Cs - 1, Y + Cs - 1, C);
End;

Procedure DrawLine(K, Ia, Ib, Ja, Jb, Col : LongInt);
Var I, J, Lt, H, Cx_, Cy_, F : LongInt;
Begin
  If K = 0 Then Lt := MaxI(1, (Cs - Tw) Div 3) Else Lt := MaxI(1, (Cs - Tw) Div 4);
  H := Lt Div 2;
  For J := Ja To Jb Do
    For I := Ia To Ib Do
      If OnLine(K, I, J) Then
      Begin
        Cx_ := MX0 + (I - 1) * Cs + (Cs + Tw) Div 2;
        Cy_ := MY0 + (J - 1) * Cs + (Cs + Tw) Div 2;
        FBar(Cx_ - H, Cy_ - H, Cx_ - H + Lt - 1, Cy_ - H + Lt - 1, Col);
        F := Fl^[CI(I, J)];
        If ((F And dE) <> 0) And OnLine(K, I + 1, J) Then FBar(Cx_ - H, Cy_ - H, Cx_ - H + Cs + Lt - 1, Cy_ - H + Lt - 1, Col);
        If ((F And dS) <> 0) And OnLine(K, I, J + 1) Then FBar(Cx_ - H, Cy_ - H, Cx_ - H + Lt - 1, Cy_ - H + Cs + Lt - 1, Col);
        If (I = 1) And (J = SY) Then FBar(MX0 - Cs Div 2, Cy_ - H, Cx_, Cy_ - H + Lt - 1, Col);
        If (I = MzW) And (J = EY) And ((K = 0) Or Solved) Then
          FBar(Cx_, Cy_ - H, MX0 + MzW * Cs + Tw + Cs Div 2, Cy_ - H + Lt - 1, Col);
      End;
End;

{ fleche vers la droite dans la boite (X, Y, taille S) }
Procedure Arrow(X, Y, S, C : LongInt);
Var K, H : LongInt;
Begin
  H := S Div 2;
  If H < 1 Then
  Begin
    FBar(X, Y, X + 1, Y + 1, C);
    Exit;
  End;
  For K := 0 To H Do VLine(X + K, Y + K, Y + S - K, C);
End;

Procedure PaintBoard;
Var Ia, Ib, Ja, Jb, I, J, R0, X, Y, Bx1, By1, Bx2, By2, Rr : LongInt; S : String;
Begin
  FBar(0, Y0, PnX - 1, Y1, cGray);
  { feuille et ombre }
  FBar(PgX1 + 5, PgY1 + 5, PgX2 + 5, PgY2 + 5, cBlack);
  FBar(PgX1, PgY1, PgX2, PgY2, cWhite);
  Box(PgX1, PgY1, PgX2, PgY2, cBlack);
  If Not Ready Then
  Begin
    OutTxt(PgX1 + 16, PgY1 + 10, 'Labyrinthe - Nouveau labyrinthe (F2)', cGray, cWhite);
    Exit;
  End;
  If FromFile Then S := 'Labyrinthe ' + IStr(MzW) + ' x ' + IStr(MzH) + ' - ' + MazeName
  Else If OptCustom Then S := 'Labyrinthe ' + IStr(MzW) + ' x ' + IStr(MzH) + ' - personnalis'#130
  Else S := 'Labyrinthe ' + IStr(MzW) + ' x ' + IStr(MzH) + ' - ' + DiffName(CurDiff);
  If Anim = anGen Then S := S + ' (construction...)'
  Else If Anim = anSolve Then S := S + ' (r'#130'solution...)'
  Else If ShowSolution Then S := S + ' - solution';
  OutTxt(PgX1 + 16, PgY1 + 10, Fit(S, PgX2 - PgX1 - 140), cNavy, cWhite);
  If Not FromFile Then
  Begin
    S := 'Graine ' + IStr(LastSeed);
    OutTxt(PgX2 - 16 - Length(S) * 8, PgY1 + 10, S, cGray, cWhite);
  End;
  { fond du style }
  Bx1 := MX0 - Cs - 4; By1 := MY0 - 4; Bx2 := MX0 + MzW * Cs + Tw + Cs + 3; By2 := MY0 + MzH * Cs + Tw + 3;
  If KBg <> cWhite Then FBar(Bx1, By1, Bx2, By2, KBg);
  { cases visibles }
  Ia := MaxI(1, (UX1 - MX0) Div Cs - 1); Ib := MinI(MzW, (UX2 - MX0) Div Cs + 2);
  Ja := MaxI(1, (UY1 - MY0) Div Cs - 1); Jb := MinI(MzH, (UY2 - MY0) Div Cs + 2);
  If (Ia > Ib) Or (Ja > Jb) Then Exit;
  { cases visitees, indice }
  If ShowVisited And (Anim = anNone) Then
    For J := Ja To Jb Do
    Begin
      R0 := 0;
      For I := Ia To Ib + 1 Do
      Begin
        If (I <= Ib) And (Vis^[CI(I, J)] <> 0) Then
        Begin
          If R0 = 0 Then R0 := I;
        End
        Else If R0 > 0 Then
        Begin
          FBar(MX0 + (R0 - 1) * Cs, MY0 + (J - 1) * Cs, MX0 + (I - 1) * Cs + Tw - 1, MY0 + J * Cs + Tw - 1, KVis);
          R0 := 0;
        End;
      End;
    End;
  For I := 0 To HintN - 1 Do CellBox(CX(HintC[I]), CY(HintC[I]), KHint);
  { quadrillage }
  If ShowGrid Then
  Begin
    For I := Ia - 1 To Ib Do VLine(MX0 + I * Cs, MY0 + (Ja - 1) * Cs, MY0 + Jb * Cs, KVis);
    For J := Ja - 1 To Jb Do HLine(MX0 + (Ia - 1) * Cs, MX0 + Ib * Cs, MY0 + J * Cs, KVis);
  End;
  { solution et chemin du joueur }
  If (ShowSolution And (Anim = anNone)) Or (Anim = anSolve) Then DrawLine(0, Ia, Ib, Ja, Jb, KPath);
  If ShowTrail And (Anim = anNone) Then DrawLine(1, Ia, Ib, Ja, Jb, KTrail);
  { murs verticaux, par troncons }
  For I := Ia - 1 To Ib Do
  Begin
    X := MX0 + I * Cs;
    R0 := 0;
    For J := Ja To Jb + 1 Do
    Begin
      If (J <= Jb) And WallV(I, J) Then
      Begin
        If R0 = 0 Then R0 := J;
      End
      Else If R0 > 0 Then
      Begin
        FBar(X, MY0 + (R0 - 1) * Cs, X + Tw - 1, MY0 + (J - 1) * Cs + Tw - 1, KWall);
        R0 := 0;
      End;
    End;
  End;
  { murs horizontaux }
  For J := Ja - 1 To Jb Do
  Begin
    Y := MY0 + J * Cs;
    R0 := 0;
    For I := Ia To Ib + 1 Do
    Begin
      If (I <= Ib) And WallH(I, J) Then
      Begin
        If R0 = 0 Then R0 := I;
      End
      Else If R0 > 0 Then
      Begin
        FBar(MX0 + (R0 - 1) * Cs, Y, MX0 + (I - 1) * Cs + Tw - 1, Y + Tw - 1, KWall);
        R0 := 0;
      End;
    End;
  End;
  If Anim = anGen Then Exit;
  { entree et sortie }
  Rr := MaxI(2, Cs - Tw - 2);
  Arrow(MX0 - Cs + 1, MY0 + (SY - 1) * Cs + Tw + (Cs - Tw - Rr) Div 2, Rr, KIn);
  Arrow(MX0 + MzW * Cs + Tw + 2, MY0 + (EY - 1) * Cs + Tw + (Cs - Tw - Rr) Div 2, Rr, KOut);
  { le joueur }
  If (Anim = anNone) And Not GaveUp Then
  Begin
    X := MX0 + (PX - 1) * Cs + (Cs + Tw) Div 2; Y := MY0 + (PY - 1) * Cs + (Cs + Tw) Div 2;
    Rr := (Cs - Tw) Div 2 - 1;
    If Rr >= 2 Then Disc(X, Y, Rr, KMe) Else CellBox(PX, PY, KMe);
  End;
End;

{ ==================================================================== }
{ Panneau de droite                                                     }
{ ==================================================================== }

Function Z2s(V : LongInt) : String;
Begin
  Z2s := Chr(48 + (V Div 10) Mod 10) + Chr(48 + V Mod 10);
End;

Function TimeStr : String;
Begin
  TimeStr := Z2s(Elapsed Div 60) + ':' + Z2s(Elapsed Mod 60);
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

{ pave : 1 haut, 2 gauche, 3 indice, 4 droite, 5 bas, 6 retour, 7 recommencer }
Procedure PadRect(K : LongInt; Var X1, Y1_, X2, Y2 : LongInt);
Var Bw, Cx_, Py : LongInt;
Begin
  Bw := 40;
  Cx_ := PnX + PnW Div 2;
  Py := Y0 + 306;
  Case K Of
    1 : Begin X1 := Cx_ - Bw Div 2; Y1_ := Py; End;
    2 : Begin X1 := Cx_ - Bw Div 2 - Bw - 4; Y1_ := Py + Bw + 4; End;
    3 : Begin X1 := Cx_ - Bw Div 2; Y1_ := Py + Bw + 4; End;
    4 : Begin X1 := Cx_ + Bw Div 2 + 4; Y1_ := Py + Bw + 4; End;
    5 : Begin X1 := Cx_ - Bw Div 2; Y1_ := Py + 2 * (Bw + 4); End;
  Else
    Begin
      X1 := PnX + 14 + (K - 6) * ((PnW - 34) Div 2 + 6); Y1_ := Py + 3 * (Bw + 4) + 6;
      X2 := X1 + (PnW - 34) Div 2 - 1; Y2 := Y1_ + 27;
      Exit;
    End;
  End;
  X2 := X1 + Bw - 1; Y2 := Y1_ + Bw - 1;
End;

Procedure PaintPanel;
Var Y, K, X1, Y1_, X2, Y2, D, N, C : LongInt; Txt : String; Dis : Boolean;
Begin
  FBar(PnX, Y0, CW - 1, Y1, cSilver);
  VLine(PnX, Y0, Y1, cGray); VLine(PnX + 1, Y0, Y1, cWhite);
  Y := Y0 + 10;
  Section(Y, 'Labyrinthe');
  Y := Y + 26;
  If Ready Then
  Begin
    InfoLine(Y, 'Dimensions', IStr(MzW) + ' x ' + IStr(MzH));
    InfoLine(Y + 18, 'Cases', IStr(MzW * MzH));
    If FromFile Then InfoLine(Y + 36, 'Fichier', Fit(MazeName, 110))
    Else If OptCustom Then InfoLine(Y + 36, 'Taille des cases', 'perso.')
    Else InfoLine(Y + 36, 'Taille des cases', IStr(OptBW));
    If FromFile Then InfoLine(Y + 54, 'Branche maximale', '-') Else InfoLine(Y + 54, 'Branche maximale', BranchName(OptBranch));
    If FromFile Then InfoLine(Y + 72, 'Graine', '-') Else InfoLine(Y + 72, 'Graine', IStr(LastSeed));
    InfoLine(Y + 90, 'Solution', IStr(PathLen) + ' cases');
    InfoLine(Y + 108, 'Culs-de-sac', IStr(DeadEnds));
  End
  Else OutTxt(PnX + 14, Y, 'Fichier - Nouveau (F2)', cGray, cSilver);
  Y := Y0 + 172;
  Section(Y, 'Partie');
  Y := Y + 26;
  If Ready Then
  Begin
    InfoLine(Y, 'D'#130'placements', IStr(Moves));
    InfoLine(Y + 18, 'Temps', TimeStr);
    InfoLine(Y + 36, 'Indices', IStr(Hints));
    D := DistToExit(PX, PY);
    If GaveUp Then InfoLine(Y + 54, 'Distance '#133' la sortie', '-') Else InfoLine(Y + 54, 'Distance '#133' la sortie', IStr(D));
    N := StartDist;
    If (N > 0) And (D >= 0) Then K := ((N - D) * (PnW - 28)) Div N Else K := PnW - 28;
    If K < 0 Then K := 0;
    Sunken(PnX + 12, Y + 76, CW - 12, Y + 88, cWhite);
    If K > 1 Then FBar(PnX + 13, Y + 77, PnX + 13 + K - 2, Y + 87, cDGreen);
  End;
  { pave de direction }
  Dis := Not Ready Or Solved Or GaveUp Or (Anim <> anNone);
  For K := 1 To 7 Do
  Begin
    PadRect(K, X1, Y1_, X2, Y2);
    FBar(X1, Y1_, X2, Y2, cSilver);
    Box(X1, Y1_, X2, Y2, cBlack);
    Edge(X1 + 1, Y1_ + 1, X2 - 1, Y2 - 1, cWhite, cGray);
    If (K = 3) Or (K >= 6) Then C := cBlack Else C := cNavy;
    If Dis And (K <> 7) Then C := cGray;
    If Not Ready Then C := cGray;
    Case K Of
      1 : For N := 0 To 8 Do HLine((X1 + X2) Div 2 - N, (X1 + X2) Div 2 + N, Y1_ + 11 + N, C);
      5 : For N := 0 To 8 Do HLine((X1 + X2) Div 2 - N, (X1 + X2) Div 2 + N, Y2 - 11 - N, C);
      2 : For N := 0 To 8 Do VLine(X1 + 11 + N, (Y1_ + Y2) Div 2 - N, (Y1_ + Y2) Div 2 + N, C);
      4 : For N := 0 To 8 Do VLine(X2 - 11 - N, (Y1_ + Y2) Div 2 - N, (Y1_ + Y2) Div 2 + N, C);
      3 :
        Begin
          If C = cGray Then Disc((X1 + X2) Div 2, Y1_ + 15, 7, cGray) Else Disc((X1 + X2) Div 2, Y1_ + 15, 7, cYellow);
          FBar((X1 + X2) Div 2 - 3, Y1_ + 23, (X1 + X2) Div 2 + 3, Y1_ + 28, cGray);
        End;
    Else
      Begin
        If K = 6 Then Txt := 'Retour' Else Txt := 'Recommencer';
        OutTxt((X1 + X2) Div 2 - Length(Txt) * 4, Y1_ + 6, Txt, C, cSilver);
      End;
    End;
  End;
  PadRect(7, X1, Y1_, X2, Y2);
  Y := Y2 + 14;
  If Y + 80 < Y1 Then
  Begin
    Section(Y, 'Clavier');
    OutTxt(PnX + 14, Y + 26, 'Fl'#138'ches, WASD, ZQSD, IJKM', cBlack, cSilver);
    OutTxt(PnX + 14, Y + 44, 'Maj : jusqu''au carrefour', cBlack, cSilver);
    OutTxt(PnX + 14, Y + 62, 'X : abandonner (solution)', cBlack, cSilver);
  End;
End;

Procedure PaintStatus;
Var X : LongInt; S : String;
Begin
  Raised(0, CH - SbH, CW - 1, CH - 1);
  S := '';
  If Ready Then S := 'Entr'#130'e (1, ' + IStr(SY) + ') - sortie (' + IStr(EX) + ', ' + IStr(EY) + ') - ' + TimeStr;
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
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2(AppTitle), 0,
                         MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure MsgErr(S : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2(AppTitle), 0,
                         MB_OK Or MB_ERROR Or MB_MOVEABLE);
End;

Function Ask3(S : String) : LongInt;
Begin
  Ask3 := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2(AppTitle), 0,
                        MB_YESNOCANCEL Or MB_QUERY Or MB_MOVEABLE);
End;

Function AskYes(S : String) : Boolean;
Begin
  AskYes := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2(AppTitle), 0,
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
  Dummy := WinRegisterClass(Hab, Z('MZDLG'), LongInt(@DlgProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DgClient := 0;
  DgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('MZDLG'), Z2(Title), 0, 0, 0, LongInt(@DgClient));
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

Function BrLabel(K : LongInt) : String;
Var R : String;
Begin
  Case K Of
    0 : R := '~Illimit'#130'e (d'#130'faut de MAKEMAZE)';
    1 : R := '~1 (facile : branches courtes)';
    5 : R := '~50 (difficile : longs couloirs)';
  Else
    R := '~' + IStr(BrVal[K]);
  End;
  BrLabel := R;
End;

Procedure BuildMenu;
Var H0, H1, H2, K : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 80, '~Fichier');
  H1 := MenuOpen;
  It(cmNew, '~Nouveau labyrinthe' + #9 + 'F2');
  It(cmOpen, '~Ouvrir un labyrinthe (texte ou CSV)...' + #9 + 'Ctrl+O');
  It(cmSave, '~Enregistrer' + #9 + 'Ctrl+S');
  It(cmSaveAs, 'Enregistrer ~sous (texte, /FILE)...');
  It(cmSaveCsv, 'Enregistrer en ~CSV (/SAVECSV)...');
  Sep;
  It(cmExport, 'E~xporter (texte, page Web, image)...' + #9 + 'Ctrl+E');
  It(cmCopyText, 'Co~pier le labyrinthe (texte)' + #9 + 'Ctrl+C');
  Sep;
  It(cmQuit, '~Quitter' + #9 + 'Alt+F4');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 81, '~Labyrinthe');
  H1 := MenuOpen;
  It(cmGenerate, '~R'#130'g'#130'n'#130'rer (nouvelle graine)' + #9 + 'F5');
  It(cmSameSeed, 'R'#130'g'#130'n'#130'rer avec la ~m'#136'me graine' + #9 + 'Maj+F5');
  Sep;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 89, '~Difficult'#130' (/WIDTH)');
  H2 := MenuOpen;
  For K := 0 To NDiff - 1 Do ItA(cmDiff0 + K, Chk(CurDiff = K), '~' + DiffLabel(K));
  Sep;
  ItA(cmCustomSize, Chk(OptCustom), 'Dimensions ~personnalis'#130'es...');
  MenuClose(H2);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 88, '~Branche maximale (/MAXBRANCH)');
  H2 := MenuOpen;
  For K := 0 To NBr - 1 Do ItA(cmBr0 + K, Chk(OptBranch = BrVal[K]), BrLabel(K));
  Sep;
  It(cmBrOther, '~Autre...');
  MenuClose(H2);
  Sep;
  It(cmParams, '~Param'#138'tres...' + #9 + 'F6');
  It(cmSeed, '~Graine...');
  It(cmStats, '~Statistiques...');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 82, '~Jeu');
  H1 := MenuOpen;
  It(cmHint, '~Indice' + #9 + 'H');
  It(cmBack, 'Revenir d''un ~pas' + #9 + 'Retour arri'#138're');
  It(cmRestart, '~Recommencer' + #9 + 'Ctrl+R');
  Sep;
  It(cmSolveAnim, 'R'#130'~soudre (anim'#130', comme MAKEMAZE)' + #9 + 'F7');
  It(cmGiveUp, '~Abandonner (afficher la solution)' + #9 + 'X');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 83, '~Affichage');
  H1 := MenuOpen;
  ItA(cmShowSol, Chk(ShowSolution), '~Solution' + #9 + 'F9');
  ItA(cmTrail, Chk(ShowTrail), '~Chemin parcouru');
  ItA(cmVisited, Chk(ShowVisited), 'Cases ~visit'#130'es');
  ItA(cmGrid, Chk(ShowGrid), '~Quadrillage');
  Sep;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 87, 'S~tyle');
  H2 := MenuOpen;
  For K := 0 To NStyle - 1 Do ItA(cmStyle0 + K, Chk(Style = K), '~' + StyleName(K));
  MenuClose(H2);
  ItA(cmToolbar, Chk(ShowToolbar), '~Barre d''outils');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 84, '~Options');
  H1 := MenuOpen;
  ItA(cmSolveNow, Chk(OptSolveNow), 'Afficher ~imm'#130'diatement la solution (/SOLVE)');
  ItA(cmAnimate, Chk(OptAnimate), '~Animer la construction (/SHOWGRAPH)');
  ItA(cmDoors, Chk(OptDoors), 'Ouvrir l''~entr'#130'e et la sortie dans le fichier texte');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 85, '~?');
  H1 := MenuOpen;
  It(cmHelp, '~Aide' + #9 + 'F1');
  It(cmOpts, '~Options de MAKEMAZE');
  Sep;
  It(cmAbout, '~A propos...');
  MenuClose(H1);
  MenuClose(H0);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

Procedure SyncMenu;
Var K : LongInt;
Begin
  For K := 0 To NDiff - 1 Do SetCheck(cmDiff0 + K, CurDiff = K);
  SetCheck(cmCustomSize, OptCustom);
  For K := 0 To NBr - 1 Do SetCheck(cmBr0 + K, OptBranch = BrVal[K]);
  For K := 0 To NStyle - 1 Do SetCheck(cmStyle0 + K, Style = K);
  SetCheck(cmShowSol, ShowSolution); SetCheck(cmTrail, ShowTrail); SetCheck(cmVisited, ShowVisited);
  SetCheck(cmGrid, ShowGrid); SetCheck(cmToolbar, ShowToolbar);
  SetCheck(cmSolveNow, OptSolveNow); SetCheck(cmAnimate, OptAnimate); SetCheck(cmDoors, OptDoors);
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
  TbAdd(cmNew, 1, '', 'Nouveau labyrinthe (F2)');
  TbAdd(cmOpen, 2, '', 'Ouvrir un labyrinthe : texte de MAKEMAZE ou CSV (Ctrl+O)');
  TbAdd(cmSave, 3, '', 'Enregistrer le labyrinthe (Ctrl+S)');
  TbAdd(cmExport, 4, '', 'Exporter : texte, page Web ou image BMP (Ctrl+E)');
  TbAdd(0, 0, '', '');
  TbAdd(cmGenerate, 5, 'G'#130'n'#130'rer', 'R'#130'g'#130'n'#130'rer un labyrinthe, nouvelle graine (F5)');
  TbAdd(cmShowSol, 6, 'Solution', 'Afficher ou cacher la solution (F9)');
  TbAdd(cmSolveAnim, 7, '', 'R'#130'soudre en longeant les murs, comme MAKEMAZE (F7)');
  TbAdd(0, 0, '', '');
  TbAdd(cmHint, 8, '', 'Indice : les prochaines cases vers la sortie (H)');
  TbAdd(cmBack, 9, '', 'Revenir d''un pas (Retour arri'#138're)');
  TbAdd(cmRestart, 10, '', 'Recommencer depuis l''entr'#130'e (Ctrl+R)');
  TbAdd(0, 0, '', '');
  TbAdd(cmParams, 11, '', 'Param'#138'tres (F6)');
  TbAdd(cmHelp, 12, '', 'Aide (F1)');
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure SetTitle;
Var S : String;
Begin
  If FromFile Then S := MazeName + ' - ' + AppTitle Else S := AppTitle;
  Dummy := WinSetWindowText(Frame, Z(S));
End;

Procedure ClearHint;
Begin
  If HintN > 0 Then
  Begin
    HintN := 0;
    InvalBoard;
  End;
End;

Procedure ResetPlay;
Var C : LongInt;
Begin
  FillChar(InTrail^, MaxCells, 0);
  FillChar(Vis^, MaxCells, 0);
  C := CI(SX, SY);
  Trail^[0] := C; TrailN := 1;
  InTrail^[C] := 1; Vis^[C] := 1;
  PX := SX; PY := SY;
  Moves := 0; Elapsed := 0; Hints := 0; HintN := 0;
  Solved := False; GaveUp := False;
  StartDist := DistToExit(SX, SY);
End;

Procedure StopAnim;
Var K : LongInt;
Begin
  If Anim = anNone Then Exit;
  If Anim = anSolve Then
  Begin
    For K := AnimPos To StpN - 1 Do DispB^[Stp^[K] Shr 1] := Stp^[K] And 1;
    ShowSolution := True;
    StatusMsg := 'R'#130'solu en longeant les murs : ' + IStr(SolveSteps) + ' pas, chemin de ' + IStr(PathLen) + ' cases.';
  End
  Else StatusMsg := GenMsg + '. Allez de l''entr'#130'e (fl'#138'che '#133' gauche) '#133' la sortie (fl'#138'che '#133' droite).';
  Anim := anNone;
  Dummy := WinStopTimer(Hab, Client, 2);
  SyncMenu;
  Redraw;
End;

Procedure AnimTick;
Var N, K : LongInt;
Begin
  If Anim = anNone Then Exit;
  { la duree ne depend pas du rythme du minuteur }
  N := AnimEnd * MaxI(0, PTicks - AnimT0) Div MaxI(1, AnimDur);
  N := MinI(AnimEnd, MaxI(N, AnimPos + 1));
  If Anim = anSolve Then
    For K := AnimPos To N - 1 Do DispB^[Stp^[K] Shr 1] := Stp^[K] And 1;
  AnimPos := N;
  If AnimPos >= AnimEnd Then StopAnim Else InvalBoard;
End;

Procedure StartAnim(Kind : LongInt);
Begin
  If Not Ready Then Exit;
  If Kind = anSolve Then
  Begin
    FillChar(DispB^, MaxCells, 0);
    AnimEnd := StpN;
    StatusMsg := 'R'#130'solution comme MAKEMAZE : on longe les murs, les impasses s''effacent (Echap : fin).';
  End
  Else
  Begin
    AnimEnd := NOrd;
    StatusMsg := 'Construction du labyrinthe (Echap : fin).';
  End;
  Anim := Kind; AnimPos := 0;
  AnimStep := MaxI(1, AnimEnd Div 80);
  AnimT0 := PTicks;
  If Kind = anSolve Then AnimDur := 4000 Else AnimDur := 2500;
  Dummy := WinStartTimer(Hab, Client, 2, 40);
  InvalStatus;
  Redraw;
End;

Procedure NewGame;
Begin
  If Anim <> anNone Then
  Begin
    Anim := anNone;
    Dummy := WinStopTimer(Hab, Client, 2);
  End;
  ResetPlay;
  ShowSolution := OptSolveNow;
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
  If Not Generate Then MsgErr('La r'#130'solution du labyrinthe a '#130'chou'#130' (cas impr'#130'vu).');
  MazeName := ''; ExportName := '';
  NewGame;
  StatusMsg := GenMsg + '. Allez de l''entr'#130'e (fl'#138'che '#133' gauche) '#133' la sortie (fl'#138'che '#133' droite).';
  { une graine fixe ne sert qu'une fois : F5 tire ensuite une nouvelle graine }
  OptSeed := Keep; OptHasSeed := False;
  If H Then ;
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 1, 0));
  If OptAnimate Then StartAnim(anGen);
  Redraw;
End;

Function Opp(D : LongInt) : LongInt;
Begin
  If D <= dN Then Opp := D Shl 2 Else Opp := D Shr 2;
End;

Procedure Win;
Var Best : LongInt; S : String;
Begin
  Solved := True;
  Best := MaxI(1, PathLen - 1);
  StatusMsg := 'Bravo ! Sortie atteinte en ' + IStr(Moves) + ' d'#130'placements (le plus court : ' + IStr(Best) + ').';
  Redraw;
  S := 'Bravo ! Vous '#136'tes sorti du labyrinthe en ' + TimeStr + '.' + #10#10 + 'D'#130'placements : ' + IStr(Moves) +
       #10'Chemin le plus court : ' + IStr(Best) + #10'Efficacit'#130' : ' + IStr(Best * 100 Div MaxI(1, Moves)) + ' %' +
       #10'Indices : ' + IStr(Hints);
  Msg(S);
End;

{ un pas dans la direction D ; rend False si un mur l'empeche }
Function TryMove(D : LongInt) : Boolean;
Var J, K, C, Old : LongInt;
Begin
  TryMove := False;
  If Not Ready Or Solved Or GaveUp Or (Anim <> anNone) Then Exit;
  If (Fl^[CI(PX, PY)] And D) = 0 Then Exit;
  J := PX; K := PY;
  If Not Adjust(J, K, D) Then Exit;
  C := CI(J, K);
  Old := CI(PX, PY);
  If (TrailN >= 2) And (Trail^[TrailN - 2] = C) Then
  Begin
    InTrail^[Old] := 0;
    Dec(TrailN);
  End
  Else If TrailN < MaxCells Then
  Begin
    Trail^[TrailN] := C; Inc(TrailN);
    InTrail^[C] := 1;
  End;
  Vis^[C] := 1;
  InvalCell(PX, PY);
  PX := J; PY := K;
  InvalCell(PX, PY);
  Inc(Moves);
  ClearHint;
  TryMove := True;
  If (PX = EX) And (PY = EY) Then Win;
End;

{ deplacement, ou course jusqu'au prochain carrefour (Maj) }
Procedure MoveDir(D : LongInt; Run : Boolean);
Var N, E, K : LongInt;
Begin
  If Anim <> anNone Then StopAnim;
  If Not TryMove(D) Then
  Begin
    If Ready And Not Solved And Not GaveUp Then
    Begin
      StatusMsg := 'Un mur bloque le passage.';
      InvalStatus;
    End;
    Exit;
  End;
  If Run Then
  Begin
    N := 0;
    While Not Solved And (Openings(PX, PY) = 2) And (N < MaxCells) Do
    Begin
      E := 0;
      K := dE;
      While K <= dS Do
      Begin
        If ((Fl^[CI(PX, PY)] And K) <> 0) And (K <> Opp(D)) Then E := K;
        K := K Shl 1;
      End;
      If (E = 0) Or Not TryMove(E) Then Break;
      D := E;
      Inc(N);
    End;
  End;
  If Not Solved Then
  Begin
    StatusMsg := 'Distance '#133' la sortie : ' + IStr(DistToExit(PX, PY)) + ' cases.';
    InvalStatus;
  End;
  InvalPanel;
  InvalBand(0, 0, CW, TbH);
End;

Procedure StepBack;
Var C, D : LongInt;
Begin
  If (TrailN < 2) Or Solved Or GaveUp Then Exit;
  C := Trail^[TrailN - 2];
  If CX(C) > PX Then D := dE
  Else If CX(C) < PX Then D := dW
  Else If CY(C) < PY Then D := dN
  Else D := dS;
  MoveDir(D, False);
End;

Procedure Hint;
Var C, K : LongInt;
Begin
  If Not Ready Or Solved Or GaveUp Then Exit;
  If Anim <> anNone Then StopAnim;
  C := CI(PX, PY);
  HintN := 0;
  For K := 1 To 8 Do
  Begin
    If C = CI(EX, EY) Then Break;
    C := NextToExit(C);
    HintC[HintN] := C; Inc(HintN);
  End;
  Inc(Hints);
  StatusMsg := 'Indice : les ' + IStr(HintN) + ' prochaines cases vers la sortie sont marqu'#130'es.';
  InvalBoard; InvalPanel; InvalStatus;
End;

Procedure GiveUp;
Begin
  If Not Ready Or Solved Then Exit;
  If Anim <> anNone Then StopAnim;
  GaveUp := True;
  ShowSolution := True;
  HintN := 0;
  StatusMsg := 'Abandon : la solution compte ' + IStr(PathLen) + ' cases (Ctrl+R pour recommencer).';
  SyncMenu;
  Redraw;
End;
{ ==================================================================== }
{ Fichiers, parametres, statistiques                                    }
{ ==================================================================== }

Var
  SaveWithSol, SaveCsv : Boolean;

Function CanWriteDir(D : String) : Boolean;
Var T, S : String;
Begin
  T := JoinPath(D, 'MZTEST.TMP');
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

{ remplace l'extension (ou l'ajoute) }
Function WithExt(N, E : String) : String;
Var K : LongInt; R : String;
Begin
  R := N;
  K := Length(R);
  While (K > 0) And (R[K] <> '.') And (R[K] <> '\') Do Dec(K);
  If (K > 0) And (R[K] = '.') Then R := Copy(R, 1, K - 1);
  R := R + '.' + E;
  WithExt := R;
End;

Procedure UseLoaded(F : String);
Var Err : String;
Begin
  If Not LoadMaze(F, Err) Then
  Begin
    MsgErr('Lecture impossible de ' + F + ' : ' + Err);
    Exit;
  End;
  MazeName := NameOf(F);
  ExportName := F;
  SaveCsv := ExtOf(F) = 'CSV';
  NewGame;
  StatusMsg := 'Labyrinthe ouvert : ' + IStr(MzW) + ' x ' + IStr(MzH) + ' cases, solution de ' + IStr(PathLen) + ' cases.';
  If Err <> '' Then MsgErr(Err);
  InvalStatus;
End;

Procedure OpenDlg;
Var L, F : String;
Begin
  DlgReset;
  L := ListFiles(WorkDir, '*.TXT') + ListFiles(WorkDir, '*.CSV');
  If L = '' Then L := ' (aucun)';
  DlgLabel(Fit('Fichiers de ' + WorkDir + ' :' + L, 590));
  DlgEdit('Fichier du labyrinthe :', JoinPath(WorkDir, 'LABY.TXT'));
  DlgLabel('Texte de MAKEMAZE (/FILE), texte compact ou CSV (/SAVECSV).');
  If Not DlgRun('Ouvrir un labyrinthe', 'Ouvrir') Then Exit;
  F := FullName(DfVal[1]);
  If ExtOf(F) = '' Then F := F + '.TXT';
  UseLoaded(F);
End;

Function WriteMaze(F : String; Csv, WithSol : Boolean) : Boolean;
Begin
  If Csv Then MazeCsv(WithSol) Else MazeText(WithSol);
  WriteMaze := WriteAll(F, OutB.P, OutB.Len);
End;

Procedure SaveDlg(Csv, Ask : Boolean);
Var F : String;
Begin
  If Not Ready Then Exit;
  F := ExportName;
  If Ask Or (F = '') Then
  Begin
    DlgReset;
    If Csv Then F := JoinPath(WorkDir, 'LABY.CSV')
    Else If (F = '') Or (ExtOf(F) = 'CSV') Then F := JoinPath(WorkDir, 'LABY.TXT');
    DlgEdit('Fichier :', F);
    DlgCheck('Avec la solution (/SOLVE : points du chemin, bit 7 dans le CSV)', SaveWithSol Or ShowSolution);
    If Csv Then DlgLabel('Une rang'#130'e par ligne : les drapeaux de chaque case, comme /SAVECSV.')
    Else DlgLabel('3 x 3 caract'#138'res par case, comme /FILE.');
    If Csv Then
    Begin
      If Not DlgRun('Enregistrer en CSV', 'Enregistrer') Then Exit;
    End
    Else If Not DlgRun('Enregistrer le labyrinthe', 'Enregistrer') Then Exit;
    F := FullName(DfVal[0]);
    If ExtOf(F) = '' Then
    Begin
      If Csv Then F := F + '.CSV' Else F := F + '.TXT';
    End;
    SaveWithSol := DlgBool(1);
    SaveCsv := Csv;
  End;
  If WriteMaze(F, SaveCsv, SaveWithSol) Then
  Begin
    ExportName := F;
    StatusMsg := 'Labyrinthe enregistr'#130' : ' + F;
  End
  Else MsgErr('Impossible d''enregistrer ' + F + '.');
  InvalStatus;
End;

Procedure ExportDlg;
Var F, E : String; K, Px : LongInt; Ok, Ws : Boolean;
Begin
  If Not Ready Then Exit;
  DlgReset;
  DlgEdit('Fichier :', JoinPath(WorkDir, 'LABY.TXT'));
  DlgCombo('Format :', 'Texte compact (.TXT)|Page Web (.HTM)|Image BMP (.BMP)|Texte de MAKEMAZE (.TXT)|CSV (.CSV)', 0);
  DlgCheck('Avec la solution', ShowSolution);
  Px := MaxI(2, MinI(16, 1600 Div (2 * MzW + 1) * 2));
  DlgEdit('Image : pixels par case (2 '#133' 32) :', IStr(Px));
  If Not DlgRun('Exporter', 'Exporter') Then Exit;
  K := DlgInt(1);
  Ws := DlgBool(2);
  If Not ParseNum(DfVal[3], 2, 32, Px) Then Px := 8;
  F := FullName(DfVal[0]);
  E := ExtOf(F);
  Case K Of
    1 : If (E = '') Or (E = 'TXT') Or (E = 'BMP') Or (E = 'CSV') Then F := WithExt(F, 'HTM');
    2 : If (E = '') Or (E = 'TXT') Or (E = 'HTM') Or (E = 'CSV') Then F := WithExt(F, 'BMP');
    4 : If (E = '') Or (E = 'TXT') Or (E = 'HTM') Or (E = 'BMP') Then F := WithExt(F, 'CSV');
  Else
    If (E = '') Or (E = 'HTM') Or (E = 'BMP') Or (E = 'CSV') Then F := WithExt(F, 'TXT');
  End;
  Case K Of
    1 : MazeHtml(Ws);
    2 : MazeBmp(Ws, Px);
    3 : MazeText(Ws);
    4 : MazeCsv(Ws);
  Else
    MazeCompact(Ws);
  End;
  Ok := WriteAll(F, OutB.P, OutB.Len);
  If Ok Then StatusMsg := 'Export'#130' : ' + F + ' (' + IStr(OutB.Len) + ' octets)'
  Else MsgErr('Impossible d'''#130'crire ' + F + '.');
  InvalStatus;
End;

Procedure CopyText;
Var T : PBytes; N : LongInt;
Begin
  If Not Ready Then Exit;
  MazeCompact(ShowSolution);
  N := MinI(OutB.Len, 60000);
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
  StatusMsg := 'Labyrinthe copi'#130' dans le presse-papiers (texte compact).';
  InvalStatus;
End;

Function DiffChoices : String;
Var K : LongInt; R : String;
Begin
  R := '';
  For K := 0 To NDiff - 1 Do
  Begin
    R := R + DiffName(K) + ' (' + IStr(DiffBW[K]) + ')';
    R := R + '|';
  End;
  R := R + 'Personnalis'#130'e';
  DiffChoices := R;
End;

Procedure ParamsDlg;
Var Ok : Boolean; D0, D, V : LongInt; N : String;
Begin
  DlgReset;
  D0 := CurDiff;
  DlgCombo('Difficult'#130' (taille des cases) :', DiffChoices, D0);
  DlgEdit('Taille des cases (/WIDTH, 2 '#133' 95) :', IStr(OptBW));
  DlgCheck('Dimensions personnalis'#130'es (sinon : '#130'cran de 640 x 350 de MAKEMAZE)', OptCustom);
  DlgEdit('Largeur personnalis'#130'e (2 '#133' 200 cases) :', IStr(OptW));
  DlgEdit('Hauteur personnalis'#130'e (2 '#133' 109 cases) :', IStr(OptH));
  DlgEdit('Branche max. (/MAXBRANCH, 0 : illimit'#130'e) :', IStr(OptBranch));
  If OptHasSeed Then N := IStr(OptSeed) Else N := '';
  DlgEdit('Graine (rien : hasard) :', N);
  DlgCheck('Afficher imm'#130'diatement la solution (/SOLVE)', OptSolveNow);
  DlgCheck('Animer la construction (/SHOWGRAPH)', OptAnimate);
  DlgCheck('Ouvrir l''entr'#130'e et la sortie dans le fichier texte', OptDoors);
  DlgCheck('R'#130'g'#130'n'#130'rer maintenant', True);
  If Not DlgRun('Param'#138'tres', 'OK') Then Exit;
  Ok := True;
  D := DlgInt(0);
  If (D <> D0) And (D < NDiff) Then
  Begin
    OptBW := DiffBW[D]; OptCustom := False;
  End
  Else
  Begin
    Ok := ParseNum(DfVal[1], MinBW, MaxBW, OptBW);
    OptCustom := DlgBool(2) Or ((D <> D0) And (D = NDiff));
  End;
  If D = D0 Then OptCustom := DlgBool(2);
  If Not ParseNum(DfVal[3], 2, MaxX, OptW) Then Ok := False;
  If Not ParseNum(DfVal[4], 2, MaxY, OptH) Then Ok := False;
  If Not ParseNum(DfVal[5], 0, 65535, V) Then Ok := False Else OptBranch := V;
  If Trim(DfVal[6]) = '' Then OptHasSeed := False
  Else If ParseNum(DfVal[6], 0, 2147483647, OptSeed) Then OptHasSeed := True
  Else Ok := False;
  OptSolveNow := DlgBool(7); OptAnimate := DlgBool(8); OptDoors := DlgBool(9);
  SyncMenu;
  If Not Ok Then MsgErr('Certaines valeurs sont hors limites ; elles n''ont pas '#130't'#130' chang'#130'es.');
  If DlgBool(10) Then DoGenerate(False) Else Redraw;
End;

Procedure CustomSizeDlg;
Var Ok : Boolean;
Begin
  DlgReset;
  DlgEdit('Largeur (2 '#133' 200 cases) :', IStr(OptW));
  DlgEdit('Hauteur (2 '#133' 109 cases) :', IStr(OptH));
  If Not DlgRun('Dimensions personnalis'#130'es', 'G'#130'n'#130'rer') Then Exit;
  Ok := ParseNum(DfVal[0], 2, MaxX, OptW);
  Ok := ParseNum(DfVal[1], 2, MaxY, OptH) And Ok;
  If Not Ok Then MsgErr('Valeurs hors limites (2 '#133' 200 sur 2 '#133' 109).');
  OptCustom := True;
  SyncMenu;
  DoGenerate(False);
End;

Procedure BranchDlg;
Var V : LongInt;
Begin
  DlgReset;
  DlgEdit('Branche maximale (0 : illimit'#130'e, 1 : facile '#133' 50 : difficile) :', IStr(OptBranch));
  If Not DlgRun('Branche maximale', 'G'#130'n'#130'rer') Then Exit;
  If Not ParseNum(DfVal[0], 0, 65535, V) Then
  Begin
    MsgErr('Valeur invalide.');
    Exit;
  End;
  OptBranch := V;
  SyncMenu;
  DoGenerate(False);
End;

Procedure SeedDlg;
Begin
  DlgReset;
  DlgLabel('Graine du dernier labyrinthe : ' + IStr(LastSeed) + ' (la m'#136'me graine donne le m'#136'me labyrinthe).');
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

Procedure ShowStats;
Var S : String; N : LongInt;
Begin
  If Not Ready Then Exit;
  N := MzW * MzH;
  S := 'Dimensions : ' + IStr(MzW) + ' x ' + IStr(MzH) + ' (' + IStr(N) + ' cases)';
  If FromFile Then S := S + #10'Fichier : ' + MazeName
  Else
  Begin
    S := S + #10'Graine : ' + IStr(LastSeed) + ', branche maximale : ' + BranchName(OptBranch);
    S := S + #10'Murs enlev'#130's : ' + IStr(NOrd);
  End;
  S := S + #10'Entr'#130'e : (1, ' + IStr(SY) + '), sortie : (' + IStr(EX) + ', ' + IStr(EY) + ')';
  S := S + #10'Chemin de la solution : ' + IStr(PathLen) + ' cases (' + IStr(PathLen * 100 Div MaxI(1, N)) + ' %)';
  S := S + #10'Culs-de-sac : ' + IStr(DeadEnds) + ', carrefours : ' + IStr(Crossings);
  S := S + #10'R'#130'solution de MAKEMAZE : ' + IStr(SolveSteps) + ' pas';
  Msg(S);
End;

Procedure ShowHelp(Which : LongInt);
Var B : TBuf;
Begin
  BufInit(B);
  If Which = 0 Then
  Begin
    BufAdd(B, 'Allez de l''entr'#130'e (fl'#138'che '#133' gauche) '#133' la sortie (fl'#138'che '#133' droite).'#10#10);
    BufAdd(B, 'D'#130'placements : fl'#138'ches, WASD, ZQSD ou IJKM (comme MAKEMAZE), le pav'#130' '#133' droite, ou un ');
    BufAdd(B, 'clic sur une case du m'#136'me couloir. Maj+fl'#138'che : jusqu''au prochain carrefour. ');
    BufAdd(B, 'Retour arri'#138're : revenir d''un pas ; H : indice ; X : abandonner ; Ctrl+R : recommencer.'#10#10);
    BufAdd(B, 'F2 : nouveau ; F5 : r'#130'g'#130'n'#130'rer (Maj+F5 : m'#136'me graine) ; F6 : param'#138'tres ; ');
    BufAdd(B, 'F7 : r'#130'soudre en longeant les murs (anim'#130') ; F9 : solution ; Echap : fin d''une animation ; ');
    BufAdd(B, 'Ctrl+O, Ctrl+S, Ctrl+E : ouvrir, enregistrer, exporter.');
    ShowBuf('Aide du ' + AppTitle, B);
  End
  Else
  Begin
    BufAdd(B, 'MAKEMAZE [/SHOWGRAPH] [/WIDTH=largeur] [/MAXBRANCH=branche] [/SOLVE] [/FILE:fichier] ');
    BufAdd(B, '[/SAVECSV:fichier]'#10#10);
    BufAdd(B, '/WIDTH : Labyrinthe - Difficult'#130' (taille des cases, 2 '#133' 95, sur 640 x 350).'#10);
    BufAdd(B, '/MAXBRANCH : Labyrinthe - Branche maximale (0 illimit'#130'e, 1 facile '#133' 50 difficile).'#10);
    BufAdd(B, '/SOLVE : Options - Afficher imm'#130'diatement la solution ; Jeu - R'#130'soudre.'#10);
    BufAdd(B, '/SHOWGRAPH : Options - Animer la construction.'#10);
    BufAdd(B, '/FILE : Fichier - Enregistrer sous ; /SAVECSV : Fichier - Enregistrer en CSV.'#10#10);
    BufAdd(B, 'Avec /FILE ou /SAVECSV, le labyrinthe est '#130'crit sans fen'#136'tre (avec /SHOWGRAPH, ');
    BufAdd(B, 'elle s''ouvre ensuite). En plus : [fichier] '#133' ouvrir, /S:graine, /SIZE:LxH, /TEXT:, /HTML:, /BMP:.');
    ShowBuf('Options de MAKEMAZE', B);
  End;
  BufFree(B);
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Procedure DoCmd(C : LongInt);
Begin
  If (C >= cmDiff0) And (C < cmDiff0 + NDiff) Then
  Begin
    OptBW := DiffBW[C - cmDiff0]; OptCustom := False;
    SyncMenu;
    DoGenerate(False);
    Exit;
  End;
  If (C >= cmBr0) And (C < cmBr0 + NBr) Then
  Begin
    OptBranch := BrVal[C - cmBr0];
    SyncMenu;
    DoGenerate(False);
    Exit;
  End;
  If (C >= cmStyle0) And (C < cmStyle0 + NStyle) Then
  Begin
    Style := C - cmStyle0;
    SetStyle;
    SyncMenu;
    InvalBoard;
    Exit;
  End;
  Case C Of
    cmNew, cmGenerate : DoGenerate(False);
    cmSameSeed : DoGenerate(True);
    cmOpen : OpenDlg;
    cmSave : SaveDlg(SaveCsv, False);
    cmSaveAs : SaveDlg(False, True);
    cmSaveCsv : SaveDlg(True, True);
    cmExport : ExportDlg;
    cmCopyText : CopyText;
    cmQuit : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    cmParams : ParamsDlg;
    cmSeed : SeedDlg;
    cmStats : ShowStats;
    cmCustomSize : CustomSizeDlg;
    cmBrOther : BranchDlg;
    cmShowSol :
      Begin
        If Anim <> anNone Then StopAnim
        Else
        Begin
          ShowSolution := Not ShowSolution;
          SyncMenu;
          InvalBoard;
        End;
      End;
    cmSolveAnim : If Anim = anSolve Then StopAnim Else StartAnim(anSolve);
    cmTrail : Begin ShowTrail := Not ShowTrail; SyncMenu; InvalBoard; End;
    cmVisited : Begin ShowVisited := Not ShowVisited; SyncMenu; InvalBoard; End;
    cmGrid : Begin ShowGrid := Not ShowGrid; SyncMenu; InvalBoard; End;
    cmToolbar : Begin ShowToolbar := Not ShowToolbar; SyncMenu; Layout; Redraw; End;
    cmHint : Hint;
    cmBack : StepBack;
    cmRestart :
      If Ready Then
      Begin
        If Anim <> anNone Then StopAnim;
        ResetPlay;
        ShowSolution := OptSolveNow;
        StatusMsg := 'Retour '#133' l''entr'#130'e.';
        SyncMenu;
        Redraw;
      End;
    cmGiveUp : GiveUp;
    cmUp : MoveDir(dN, False);
    cmDown : MoveDir(dS, False);
    cmLeft : MoveDir(dW, False);
    cmRight : MoveDir(dE, False);
    cmSolveNow : Begin OptSolveNow := Not OptSolveNow; SyncMenu; End;
    cmAnimate : Begin OptAnimate := Not OptAnimate; SyncMenu; End;
    cmDoors : Begin OptDoors := Not OptDoors; SyncMenu; End;
    cmHelp : ShowHelp(0);
    cmOpts : ShowHelp(1);
    cmAbout :
      Msg(AppTitle + ' pour OS/2-0' + #10#10 + 'Interface de MAKEMAZE (d'#130'p'#244't VIE de Gladir.com) ' +
          'avec les menus et l''apparence d''OS/2.' + #10#10 + 'Gladir.com');
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

Function BoardHit(X, Y : LongInt; Var Cx_, Cy_ : LongInt) : Boolean;
Begin
  BoardHit := False;
  If (X < MX0) Or (Y < MY0) Or (X >= MX0 + MzW * Cs) Or (Y >= MY0 + MzH * Cs) Then Exit;
  Cx_ := (X - MX0) Div Cs + 1; Cy_ := (Y - MY0) Div Cs + 1;
  BoardHit := True;
End;

{ clic sur une case du meme couloir (meme rangee ou colonne, sans mur) }
Procedure ClickCell(Cx_, Cy_ : LongInt);
Var D, N, K, J, I : LongInt; Ok : Boolean;
Begin
  If Not Ready Or Solved Or GaveUp Then Exit;
  If (Cx_ = PX) And (Cy_ = PY) Then Exit;
  D := 0;
  If (Cy_ = PY) And (Cx_ > PX) Then D := dE
  Else If (Cy_ = PY) And (Cx_ < PX) Then D := dW
  Else If (Cx_ = PX) And (Cy_ < PY) Then D := dN
  Else If (Cx_ = PX) And (Cy_ > PY) Then D := dS;
  Ok := D <> 0;
  If Ok Then
  Begin
    { le couloir est-il libre ? }
    I := PX; J := PY;
    N := Abs(Cx_ - PX) + Abs(Cy_ - PY);
    For K := 1 To N Do
    Begin
      If (Fl^[CI(I, J)] And D) = 0 Then Ok := False;
      If Ok Then If Adjust(I, J, D) Then ;
    End;
  End;
  If Not Ok Then
  Begin
    StatusMsg := 'Cliquez une case du m'#136'me couloir (sans mur entre le joueur et la case).';
    InvalStatus;
    Exit;
  End;
  For K := 1 To N Do
    If Not Solved Then If TryMove(D) Then ;
  If Not Solved Then
  Begin
    StatusMsg := 'Distance '#133' la sortie : ' + IStr(DistToExit(PX, PY)) + ' cases.';
    InvalStatus;
  End;
  InvalPanel;
  InvalBand(0, 0, CW, TbH);
End;

Procedure MouseDown(X, Y : LongInt);
Var Cx_, Cy_, K, X1, Y1_, X2, Y2 : LongInt;
Begin
  If ShowToolbar And (Y < TbH) Then
  Begin
    ToolbarDown(X);
    Exit;
  End;
  If Y >= CH - SbH Then Exit;
  If Anim <> anNone Then
  Begin
    StopAnim;
    Exit;
  End;
  If X >= PnX Then
  Begin
    For K := 1 To 7 Do
    Begin
      PadRect(K, X1, Y1_, X2, Y2);
      If (X >= X1) And (X <= X2) And (Y >= Y1_) And (Y <= Y2) Then
      Begin
        Case K Of
          1 : DoCmd(cmUp);
          2 : DoCmd(cmLeft);
          3 : DoCmd(cmHint);
          4 : DoCmd(cmRight);
          5 : DoCmd(cmDown);
          6 : DoCmd(cmBack);
          7 : DoCmd(cmRestart);
        End;
        Exit;
      End;
    End;
    Exit;
  End;
  If BoardHit(X, Y, Cx_, Cy_) Then ClickCell(Cx_, Cy_);
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
Var H : LongInt;
Begin
  If X >= PnX Then Exit;
  MenuLen := 0;
  H := MenuOpen;
  It(cmHint, '~Indice' + #9 + 'H');
  It(cmBack, 'Revenir d''un ~pas' + #9 + 'Retour arri'#138're');
  It(cmRestart, '~Recommencer' + #9 + 'Ctrl+R');
  Sep;
  ItA(cmShowSol, Chk(ShowSolution), 'Afficher la ~solution' + #9 + 'F9');
  It(cmSolveAnim, 'R'#130's~oudre (anim'#130')' + #9 + 'F7');
  It(cmGiveUp, '~Abandonner' + #9 + 'X');
  Sep;
  It(cmGenerate, 'R'#130'~g'#130'n'#130'rer' + #9 + 'F5');
  It(cmStats, 'S~tatistiques...');
  MenuClose(H);
  ShowPopup(X, Y);
End;

{ ==================================================================== }
{ Clavier                                                               }
{ ==================================================================== }

Function Key(Mp1, Mp2 : LongInt) : Boolean;
Var Fl_, Ch_, Vk, K : LongInt; Ctrl, Shift : Boolean;
Begin
  Key := True;
  Fl_ := Lo16(Mp1); Ch_ := Lo16(Mp2); Vk := Hi16(Mp2);
  If (Fl_ And KC_KEYUP) <> 0 Then
  Begin
    Key := False;
    Exit;
  End;
  Ctrl := (Fl_ And KC_CTRL) <> 0;
  Shift := (Fl_ And KC_SHIFT) <> 0;
  If (Fl_ And KC_VIRTUALKEY) <> 0 Then
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
      VK_F9 : Begin DoCmd(cmShowSol); Exit; End;
      VK_ESC : Begin StopAnim; Exit; End;
      VK_LEFT : Begin MoveDir(dW, Shift); Exit; End;
      VK_RIGHT : Begin MoveDir(dE, Shift); Exit; End;
      VK_UP : Begin MoveDir(dN, Shift); Exit; End;
      VK_DOWN : Begin MoveDir(dS, Shift); Exit; End;
      VK_BACKSPACE : Begin DoCmd(cmBack); Exit; End;
    End;
    If Vk = $26 Then
    Begin
      { F7 }
      DoCmd(cmSolveAnim);
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
      Ord('r') : Begin DoCmd(cmRestart); Exit; End;
    End;
  End;
  If ((Fl_ And KC_CHAR) <> 0) And Not Ctrl And ((Fl_ And KC_ALT) = 0) Then
  Begin
    K := Ch_;
    If (K >= Ord('A')) And (K <= Ord('Z')) Then K := K + 32;
    Case K Of
      Ord('w'), Ord('z'), Ord('i') : Begin MoveDir(dN, False); Exit; End;
      Ord('a'), Ord('q'), Ord('j') : Begin MoveDir(dW, False); Exit; End;
      Ord('s'), Ord('m') : Begin MoveDir(dS, False); Exit; End;
      Ord('d'), Ord('k') : Begin MoveDir(dE, False); Exit; End;
      Ord('h') : Begin DoCmd(cmHint); Exit; End;
      Ord('x') : Begin DoCmd(cmGiveUp); Exit; End;
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
      If Lo16(Mp1) = 2 Then AnimTick
      Else If Ready And Not Solved And Not GaveUp And (Moves > 0) And (Anim = anNone) Then
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
{ Parametres et mode sans fenetre (/FILE, /SAVECSV)                     }
{ ==================================================================== }

Var
  CliFile, CliTxt, CliCsv, CliErr, CliCmp, CliHtm, CliBmp : String;
  CliGraph : Boolean;

Procedure ParseArgs;
Var I, P, Q, V : LongInt; A, U, Name, S : String;
Begin
  CliFile := ''; CliTxt := ''; CliCsv := ''; CliErr := ''; CliGraph := False; CliCmp := ''; CliHtm := ''; CliBmp := '';
  For I := 1 To ParamCount Do
  Begin
    A := ParamStr(I);
    U := UpStr(A);
    If (Length(A) > 1) And ((A[1] = '/') Or (A[1] = '-')) Then
    Begin
      P := Pos(':', U);
      Q := Pos('=', U);
      If (Q > 0) And ((P = 0) Or (Q < P)) Then P := Q;
      If P > 0 Then
      Begin
        Name := Copy(U, 2, P - 2); S := Copy(A, P + 1, 255);
      End
      Else
      Begin
        Name := Copy(U, 2, 255); S := '';
      End;
      If Name = 'SHOWGRAPH' Then
      Begin
        CliGraph := True; OptAnimate := True;
      End
      Else If Name = 'SOLVE' Then OptSolveNow := True
      Else If Name = 'FILE' Then CliTxt := S
      Else If Name = 'SAVECSV' Then CliCsv := S
      Else If Name = 'TEXT' Then CliCmp := S
      Else If Name = 'HTML' Then CliHtm := S
      Else If Name = 'BMP' Then CliBmp := S
      Else If Name = 'WIDTH' Then
      Begin
        { comme MAKEMAZE : une valeur invalide garde la taille par defaut }
        If ParseNum(S, MinBW, MaxBW, V) Then
        Begin
          OptBW := V; OptCustom := False;
        End
        Else CliErr := 'Largeur invalide (2 '#133' 95) : ' + S;
      End
      Else If Name = 'MAXBRANCH' Then
      Begin
        If ParseNum(S, 0, 65535, V) Then OptBranch := V Else CliErr := 'Branche invalide : ' + S;
      End
      Else If (Name = 'S') Or (Name = 'SEED') Then
      Begin
        If ParseNum(S, 0, 2147483647, OptSeed) Then OptHasSeed := True Else CliErr := 'Graine invalide : ' + S;
      End
      Else If Name = 'SIZE' Then
      Begin
        Q := Pos('X', UpStr(S));
        If (Q > 0) And ParseNum(Copy(S, 1, Q - 1), 2, MaxX, OptW) And ParseNum(Copy(S, Q + 1, 255), 2, MaxY, OptH) Then
          OptCustom := True
        Else CliErr := 'Dimensions invalides (LxH, au plus 200x109) : ' + S;
      End
      Else If (Name <> '?') And (Name <> 'H') Then CliErr := 'Option inconnue : ' + A;
    End
    Else CliFile := A;
  End;
End;

{ comme MAKEMAZE avec /FILE ou /SAVECSV : le labyrinthe est ecrit }
Procedure Batch;
Begin
  If Not Generate Then Halt(3);
  If CliTxt <> '' Then
  Begin
    MazeText(OptSolveNow);
    If Not WriteAll(CliTxt, OutB.P, OutB.Len) Then Halt(2);
  End;
  If CliCsv <> '' Then
  Begin
    MazeCsv(OptSolveNow);
    If Not WriteAll(CliCsv, OutB.P, OutB.Len) Then Halt(2);
  End;
  { formats de l'interface : texte compact, page Web, image }
  If CliCmp <> '' Then
  Begin
    MazeCompact(OptSolveNow);
    If Not WriteAll(CliCmp, OutB.P, OutB.Len) Then Halt(2);
  End;
  If CliHtm <> '' Then
  Begin
    MazeHtml(OptSolveNow);
    If Not WriteAll(CliHtm, OutB.P, OutB.Len) Then Halt(2);
  End;
  If CliBmp <> '' Then
  Begin
    MazeBmp(OptSolveNow, MaxI(2, MinI(16, 1600 Div (2 * MzW + 1) * 2)));
    If Not WriteAll(CliBmp, OutB.P, OutB.Len) Then Halt(2);
  End;
End;

Procedure Main;
Var Fl0, Sw, Sh, Fw, Fh : LongInt; Batched : Boolean;
Begin
  InitDefaults;
  ShowSolution := False; ShowTrail := True; ShowVisited := True; ShowToolbar := True; ShowGrid := False;
  Style := 0; SetStyle;
  Moves := 0; Elapsed := 0; Hints := 0; HintN := 0; Solved := False; GaveUp := False; Playing := False;
  Anim := anNone; AnimPos := 0; AnimEnd := 0; AnimStep := 1; TrailN := 0; PX := 1; PY := 1; StartDist := 0;
  CtxMenu := 0; Drag := dNone; StatusMsg := 'Pr'#136't.'; SavedMsg := ''; MazeName := ''; ExportName := '';
  SaveWithSol := False; SaveCsv := False;
  GetMem(Trail, (MaxCells + 4) * 4);
  GetMem(InTrail, MaxCells + 4);
  GetMem(Vis, MaxCells + 4);
  GetMem(DispB, MaxCells + 4);
  FillChar(InTrail^, MaxCells, 0); FillChar(Vis^, MaxCells, 0); FillChar(DispB^, MaxCells, 0);
  OptAnimate := False;
  ParseArgs;
  Batched := False;
  If (CliTxt <> '') Or (CliCsv <> '') Or (CliCmp <> '') Or (CliHtm <> '') Or (CliBmp <> '') Then
  Begin
    If CliErr <> '' Then Halt(1);
    Batch;
    If Not CliGraph Then Exit;
    Batched := True;
  End;
  { dans la fenetre, la construction est animee par defaut (/SHOWGRAPH) }
  If Not Batched Then OptAnimate := True;
  WorkDir := 'C:\';
  If Not CanWriteDir(WorkDir) Then
    If CanWriteDir('D:\') Then WorkDir := 'D:\';
  ToolbarInit;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('MAKEMAZE'), LongInt(@ClientProc), 0, 0);
  Fl0 := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl0), Z('MAKEMAZE'), Z2(AppTitle), 0, 0, 0, LongInt(@Client));
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
  If Batched Then
  Begin
    { /SHOWGRAPH avec /FILE ou /SAVECSV : le labyrinthe ecrit, construit a l'ecran }
    If CliTxt <> '' Then ExportName := CliTxt Else ExportName := CliCsv;
    SaveCsv := CliTxt = '';
    NewGame;
    StartAnim(anGen);
  End
  Else
  Begin
    If CliFile <> '' Then UseLoaded(CliFile);
    If Not Ready Then DoGenerate(False);
  End;
  While WinGetMsg(Hab, LongInt(@GQmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@GQmsg));
  Dummy := WinDestroyWindow(Frame);
End;

BEGIN
  Main;
END.
