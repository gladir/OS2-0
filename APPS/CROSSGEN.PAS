{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: CROSSGEN - Generateur de mots croises pour le Presentation
                Manager d'OS/2-0, base sur CROSSGEN.PAS du depot VIE.
}

Program CrossGen;

{$R-,S-,I-}

(* Compilation : OS2PC CROSSGEN.PAS CROSSGEN.EXE

  Generateur de mots croises (dossier Loisirs du bureau), l'interface
  graphique de CROSSGEN.PAS (depot VIE : https://github.com/gladir/vie),
  avec les menus et l'apparence d'OS/2. Une liste de mots (fichier texte,
  un mot par ligne, avec un indice facultatif : MOT;indice) devient une
  grille de mots croises : plusieurs essais aleatoires, la meilleure grille
  (le plus de mots places, puis le plus de croisements, puis la plus petite
  surface) est gardee.

    - au centre, l'apercu de la grille (a remplir ou solution), numerotee ;
      on peut aussi la remplir au clavier et verifier ses reponses ;
    - a droite, les definitions (horizontalement, verticalement) ou la
      liste des mots (places ou non) avec Ajouter, Modifier, Supprimer ;
    - barre d'outils : nouvelle liste, ouvrir, enregistrer la liste,
      exporter, regenerer, meme graine, solution, verifier, parametres...

  Toutes les options de CROSSGEN ont leur menu ou leur boite de dialogue :
  /F (Ouvrir), /E (Ajouter des mots), /W /HEIGHT /SIZE (Taille), /N /MIN
  /MAX /T /S /I (Parametres), /ORDER (Ordre des mots), /FULL (Garder toute
  la grille), /A /SOLONLY /NOGRID /NOCLUE /FMT /OUT /G /BLOCK /EMPTY /LC
  (Exporter), /CP437 (Encodage), /ALL, /Q, /V (Options, Detail des essais),
  /LANG (Langue). Les memes options sont acceptees en parametres ; avec
  /OUT:fichier la grille est generee, ecrite et le programme se ferme
  (essais automatiques). *)

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
{ Moteur de CROSSGEN (depot VIE) : mots, grille, essais, sorties        }
{ ==================================================================== }

Const
  VersionStr = '1.00';
  MaxW = 60;            { largeur maximale de la grille }
  MaxH = 60;            { hauteur maximale de la grille }
  MaxWords = 250;       { mots places au plus (dictionnaire d'un essai) }
  MaxSrc = 400;         { mots de la liste (source) }
  WordMax = 30;         { longueur maximale d'un mot }
  ClueMax = 79;         { longueur maximale d'un indice }
  DirAcross = 1;        { horizontal }
  DirDown = 2;          { vertical }
  BuiltInCount = 24;
  { encodage des fichiers de mots }
  encAuto = 0; encCp437 = 1; encCp850 = 2;

Type
  TWordRec = Record
    Txt : String[WordMax];
    Src : LongInt;                 { entree de la liste source }
    X, Y, Dir, Num : LongInt;
    Placed : Boolean;
  End;

Var
  { liste source (telle que chargee ou saisie, en CP850) }
  NSrc : LongInt;
  SrcW, SrcC : Array[1..MaxSrc] Of String[80];
  ListName : String;               { fichier de la liste ('' : liste integree ou nouvelle) }
  ListMod : Boolean;
  { dictionnaire de l'essai }
  DCount, DSkipped : LongInt;
  DItems : Array[1..MaxWords] Of TWordRec;
  { grille }
  GW, GH, GUsed : LongInt;
  GCells : Array[1..MaxH, 1..MaxW] Of Char;
  GMask : Array[1..MaxH, 1..MaxW] Of Byte;
  { meilleure solution }
  BValid : Boolean;
  BPlaced, BCross, BArea : LongInt;
  BX, BY, BDir : Array[1..MaxWords] Of LongInt;
  CPlaced, CCross, CArea : LongInt;
  CX_, CY_, CDir : Array[1..MaxWords] Of LongInt;
  { vue (rognee ou complete) }
  VX0, VY0, VX1, VY1, MaxNum : LongInt;
  { options (CROSSGEN) }
  OptW, OptH, OptMaxPlace, OptLenMin, OptLenMax, OptTries, OptMinCross : LongInt;
  OptSeed, LastSeed : LongInt;
  OptHasSeed : Boolean;
  OptOrder, OptFmt : Char;
  OptFull, OptShowSol, OptSolOnly, OptNoClue, OptNoGrid, OptGraphic : Boolean;
  OptLower, OptQuiet, OptVerbose, OptNeedAll, OptUtf8Out : Boolean;
  OptEnc : LongInt;
  OptBlockCh, OptEmptyCh : Char;
  OptBlockSet : Boolean;
  Lang : LongInt;                  { 0 FR, 1 EN, 2 GR (allemand), 3 SP, 4 IT }
  { generateur pseudo-aleatoire (meme graine : meme grille) }
  RSeed : LongInt;
  { journal des essais (/V) et sortie }
  LogB, OutB : TBuf;
  Generated : Boolean;

{ ---------------------------------------------------------------------- }
{ Utilitaires                                                             }
{ ---------------------------------------------------------------------- }

Function PadR(S : String; N : LongInt) : String;
Begin
  While Length(S) < N Do S := S + ' ';
  PadR := S;
End;

Function PadL(S : String; N : LongInt) : String;
Begin
  While Length(S) < N Do S := ' ' + S;
  PadL := S;
End;

Function Max2(A, B : LongInt) : LongInt;
Begin
  If A > B Then Max2 := A Else Max2 := B;
End;

Procedure RndInit(S : LongInt);
Begin
  RSeed := S And $7FFFFFFF;
  If RSeed = 0 Then RSeed := 12345;
End;

{ entier de 0 a N - 1 }
Function Rnd(N : LongInt) : LongInt;
Begin
  RSeed := (RSeed * 1103515245 + 12345) And $7FFFFFFF;
  If N <= 1 Then Rnd := 0 Else Rnd := (RSeed Shr 8) Mod N;
End;

{ ---------------------------------------------------------------------- }
{ Langue des textes produits : francais, anglais, allemand, espagnol,    }
{ italien                                                                 }
{ ---------------------------------------------------------------------- }

Procedure SetLang(S : String);
Begin
  S := UpStr(Copy(S, 1, 2));
  Lang := 0;
  If S = 'EN' Then Lang := 1
  Else If (S = 'GR') Or (S = 'DE') Then Lang := 2
  Else If (S = 'SP') Or (S = 'ES') Then Lang := 3
  Else If S = 'IT' Then Lang := 4;
End;

Function L5(F, E, D, S, I : String) : String;
Var R : String;
Begin
  Case Lang Of
    1 : R := E;
    2 : R := D;
    3 : R := S;
    4 : R := I;
  Else
    R := F;
  End;
  L5 := R;
End;

Function Tx(N : LongInt) : String;
Var R : String;
Begin
  R := '';
  Case N Of
    7 : R := L5('Mots crois'#130's', 'Crossword', 'Kreuzwortr'#132'tsel', 'Crucigrama', 'Cruciverba');
    8 : R := L5('Horizontalement', 'Across', 'Waagerecht', 'Horizontales', 'Orizzontali');
    9 : R := L5('Verticalement', 'Down', 'Senkrecht', 'Verticales', 'Verticali');
    10 : R := L5('Mot de ', 'Word of ', 'Wort mit ', 'Palabra de ', 'Parola di ');
    11 : R := L5(' lettres', ' letters', ' Buchstaben', ' letras', ' lettere');
    20 : R := L5('Solution', 'Solution', 'L'#148'sung', 'Soluci'#162'n', 'Soluzione');
  End;
  Tx := R;
End;

{ ---------------------------------------------------------------------- }
{ Mots integres                                                           }
{ ---------------------------------------------------------------------- }

Const
  BuiltFR : Array[1..BuiltInCount] Of String[70] = (
    'SOLEIL;Etoile au centre du syst'#138'me solaire',
    'LUNE;Satellite naturel de la Terre',
    'OC'#144'AN;Vaste '#130'tendue d''eau sal'#130'e',
    'MONTAGNE;Grande '#130'l'#130'vation de terrain',
    'RIVIERE;Cours d''eau qui se jette dans un fleuve',
    'FORET;Grande '#130'tendue couverte d''arbres',
    'D'#144'SERT;R'#130'gion aride et sablonneuse',
    'NUAGE;Amas de gouttelettes dans le ciel',
    'PLUIE;Eau qui tombe des nuages',
    'VENT;Air en mouvement',
    'NEIGE;Flocons blancs de l''hiver',
    #144'TOILE;Astre brillant dans la nuit',
    'PLANETE;Corps c'#130'leste qui tourne autour du soleil',
    'ARBRE;Grand v'#130'g'#130'tal '#133' tronc',
    'FLEUR;Partie color'#130'e d''une plante',
    'OISEAU;Animal '#133' plumes qui vole',
    'POISSON;Animal qui vit dans l''eau',
    'CHEVAL;Animal que l''on monte',
    'TERRE;Notre plan'#138'te',
    'ILE;Terre entour'#130'e d''eau',
    'LAC;Etendue d''eau entour'#130'e de terre',
    'VOLCAN;Montagne qui crache de la lave',
    'ORAGE;Temp'#136'te avec '#130'clairs et tonnerre',
    'PRAIRIE;Vaste '#130'tendue d''herbe');

  BuiltEN : Array[1..BuiltInCount] Of String[70] = (
    'SUN;Star at the center of our solar system', 'MOON;Natural satellite of the Earth',
    'OCEAN;Vast body of salt water', 'MOUNTAIN;Large natural elevation of land',
    'RIVER;Flowing body of water', 'FOREST;Large area covered with trees', 'DESERT;Dry sandy region',
    'CLOUD;Mass of water droplets in the sky', 'RAIN;Water falling from clouds', 'WIND;Moving air',
    'SNOW;White flakes of winter', 'STAR;Bright point in the night sky', 'PLANET;Body orbiting the sun',
    'TREE;Tall plant with a trunk', 'FLOWER;Colorful part of a plant', 'BIRD;Feathered animal that flies',
    'FISH;Animal that lives in water', 'HORSE;Animal you can ride', 'EARTH;Our planet',
    'ISLAND;Land surrounded by water', 'LAKE;Inland body of water', 'VOLCANO;Mountain that spews lava',
    'STORM;Thunder and lightning weather', 'MEADOW;Field of grass');

  BuiltGR : Array[1..BuiltInCount] Of String[70] = (
    'SONNE;Stern im Zentrum unseres Sonnensystems', 'MOND;Nat'#129'rlicher Satellit der Erde',
    'OZEAN;Riesige Salzwasserfl'#132'che', 'BERG;Gro'#225'e Erhebung im Gel'#132'nde',
    'FLUSS;Flie'#225'endes Gew'#132'sser', 'WALD;Gro'#225'e mit B'#132'umen bedeckte Fl'#132'che',
    'W'#154'STE;Trockene Sandlandschaft', 'WOLKE;Wassertropfen am Himmel',
    'REGEN;Wasser, das aus den Wolken f'#132'llt', 'WIND;Bewegte Luft', 'SCHNEE;Wei'#225'e Flocken im Winter',
    'STERN;Leuchtender Punkt am Nachthimmel', 'PLANET;Himmelsk'#148'rper, der die Sonne umkreist',
    'BAUM;Hohe Pflanze mit Stamm', 'BLUME;Bunter Teil einer Pflanze', 'VOGEL;Tier mit Federn, das fliegt',
    'FISCH;Tier, das im Wasser lebt', 'PFERD;Tier, auf dem man reitet', 'ERDE;Unser Planet',
    'INSEL;Von Wasser umgebenes Land', 'SEE;Von Land umgebenes Gew'#132'sser', 'VULKAN;Berg, der Lava speit',
    'GEWITTER;Sturm mit Blitz und Donner', 'WIESE;Grasbewachsene Fl'#132'che');

  BuiltSP : Array[1..BuiltInCount] Of String[70] = (
    'SOL;Estrella en el centro del sistema solar', 'LUNA;Sat'#130'lite natural de la Tierra',
    'OC'#144'ANO;Gran extensi'#162'n de agua salada', 'MONTA'#165'A;Gran elevaci'#162'n natural del terreno',
    'RIO;Corriente de agua que desemboca en el mar', 'BOSQUE;Terreno cubierto de '#160'rboles',
    'DESIERTO;Regi'#162'n '#160'rida y arenosa', 'NUBE;Masa de gotas de agua en el cielo',
    'LLUVIA;Agua que cae de las nubes', 'VIENTO;Aire en movimiento', 'NIEVE;Copos blancos del invierno',
    'ESTRELLA;Punto brillante en el cielo nocturno', 'PLANETA;Cuerpo que gira alrededor del sol',
    'ARBOL;Planta alta con tronco', 'FLOR;Parte colorida de una planta',
    'PAJARO;Animal con plumas que vuela', 'PEZ;Animal que vive en el agua',
    'CABALLO;Animal que se monta', 'TIERRA;Nuestro planeta', 'ISLA;Tierra rodeada de agua',
    'LAGO;Agua rodeada de tierra', 'VOLCAN;Monta'#164'a que escupe lava',
    'TORMENTA;Tiempo con rayos y truenos', 'PRADO;Terreno cubierto de hierba');

  BuiltIT : Array[1..BuiltInCount] Of String[70] = (
    'SOLE;Stella al centro del sistema solare', 'LUNA;Satellite naturale della Terra',
    'OCEANO;Vasta distesa di acqua salata', 'MONTAGNA;Grande rilievo del terreno',
    'FIUME;Corso d''acqua che sfocia nel mare', 'FORESTA;Grande area coperta di alberi',
    'DESERTO;Regione arida e sabbiosa', 'NUVOLA;Massa di goccioline nel cielo',
    'PIOGGIA;Acqua che cade dalle nuvole', 'VENTO;Aria in movimento', 'NEVE;Fiocchi bianchi dell''inverno',
    'STELLA;Punto luminoso nel cielo notturno', 'PIANETA;Corpo che orbita attorno al sole',
    'ALBERO;Pianta alta con tronco', 'FIORE;Parte colorata di una pianta',
    'UCCELLO;Animale con le piume che vola', 'PESCE;Animale che vive nell''acqua',
    'CAVALLO;Animale che si cavalca', 'TERRA;Il nostro pianeta', 'ISOLA;Terra circondata dall''acqua',
    'LAGO;Acqua circondata dalla terra', 'VULCANO;Montagna che sputa lava',
    'TEMPORALE;Maltempo con lampi e tuoni', 'PRATO;Distesa di erba');

  { lettre de base des codes Latin-1 192..223 ; '*' : ignore }
  Lat1Map : String[32] = 'AAAAAAACEEEEIIIIDNOOOOO*OUUUUY*S';

{ ---------------------------------------------------------------------- }
{ Normalisation : majuscules sans accents (le texte est en CP850)         }
{ ---------------------------------------------------------------------- }

Procedure AddCh(Var D : String; Ch : Char);
Begin
  If Length(D) < 255 Then D := D + Ch;
End;

{ lettre(s) d'un point de code Unicode de Latin-1 }
Procedure MapUni(Var D : String; C : LongInt);
Var Ch : Char;
Begin
  If (C = 198) Or (C = 230) Then
  Begin
    AddCh(D, 'A'); AddCh(D, 'E');
  End
  Else If (C = $152) Or (C = $153) Then
  Begin
    AddCh(D, 'O'); AddCh(D, 'E');
  End
  Else If C = 223 Then
  Begin
    AddCh(D, 'S'); AddCh(D, 'S');
  End
  Else If C = 255 Then AddCh(D, 'Y')
  Else If (C >= 192) And (C <= 255) Then
  Begin
    Ch := Lat1Map[((C - 192) And 31) + 1];
    If Ch <> '*' Then AddCh(D, Ch);
  End;
End;

{ mot en CP850 -> majuscules A-Z et 0-9 }
Function Normalize(Src : String) : String;
Var I, C : LongInt; Ch : Char; D : String;
Begin
  D := '';
  For I := 1 To Length(Src) Do
  Begin
    C := Ord(Src[I]);
    If C < 128 Then
    Begin
      Ch := UpCase(Src[I]);
      If ((Ch >= 'A') And (Ch <= 'Z')) Or ((Ch >= '0') And (Ch <= '9')) Then AddCh(D, Ch);
    End
    Else MapUni(D, U850[C]);
  End;
  Normalize := D;
End;

{ y a-t-il une sequence UTF-8 dans S ? }
Function HasUtf8(S : String) : Boolean;
Var I : LongInt;
Begin
  HasUtf8 := False;
  For I := 1 To Length(S) - 1 Do
    If (Ord(S[I]) >= $C2) And (Ord(S[I]) <= $F4) And (Ord(S[I + 1]) >= $80) And (Ord(S[I + 1]) <= $BF) Then
    Begin
      HasUtf8 := True;
      Exit;
    End;
End;

{ texte d'un fichier -> CP850 : Utf (UTF-8), sinon Latin-1, ou CP437/CP850 tel quel }
Function ToCp850(S : String; Enc : LongInt; Utf : Boolean) : String;
Var I, C, N, U, K : LongInt; D : String;
Begin
  D := '';
  If Enc <> encAuto Then D := S
  Else
  Begin
    I := 1;
    While I <= Length(S) Do
    Begin
      C := Ord(S[I]);
      If C < 128 Then AddCh(D, S[I])
      Else If Utf Then
      Begin
        U := -1; N := 0;
        If (C >= $C2) And (C <= $DF) And (I < Length(S)) Then
        Begin
          U := ((C And $1F) Shl 6) Or (Ord(S[I + 1]) And $3F);
          N := 1;
        End
        Else If (C >= $E0) And (C <= $EF) And (I + 1 < Length(S)) Then
        Begin
          U := ((C And $0F) Shl 12) Or ((Ord(S[I + 1]) And $3F) Shl 6) Or (Ord(S[I + 2]) And $3F);
          N := 2;
        End
        Else If (C >= $F0) And (C <= $F4) Then N := 3;
        If U = $152 Then
        Begin
          AddCh(D, 'O'); AddCh(D, 'E');
        End
        Else If U = $153 Then
        Begin
          AddCh(D, 'o'); AddCh(D, 'e');
        End
        Else If (U = $2019) Or (U = $2018) Then AddCh(D, '''')
        Else If U >= 0 Then
        Begin
          K := Uni850(U);
          If K > 0 Then AddCh(D, Chr(K)) Else AddCh(D, '?');
        End;
        I := I + N;
      End
      Else
      Begin
        K := Uni850(C);
        If K > 0 Then AddCh(D, Chr(K)) Else AddCh(D, '?');
      End;
      Inc(I);
    End;
  End;
  ToCp850 := D;
End;

{ CP850 -> UTF-8 (exportations HTML, et textes en UTF-8) }
Function ToUtf8(S : String) : String;
Var I, U : LongInt; D : String;
Begin
  D := '';
  For I := 1 To Length(S) Do
  Begin
    If Ord(S[I]) < 128 Then AddCh(D, S[I])
    Else
    Begin
      U := U850[Ord(S[I])];
      If U < $800 Then
      Begin
        AddCh(D, Chr($C0 Or (U Shr 6))); AddCh(D, Chr($80 Or (U And $3F)));
      End
      Else
      Begin
        AddCh(D, Chr($E0 Or (U Shr 12))); AddCh(D, Chr($80 Or ((U Shr 6) And $3F)));
        AddCh(D, Chr($80 Or (U And $3F)));
      End;
    End;
  End;
  ToUtf8 := D;
End;

{ ---------------------------------------------------------------------- }
{ Liste source                                                            }
{ ---------------------------------------------------------------------- }

Function SrcAdd(W, C : String) : Boolean;
Begin
  SrcAdd := False;
  W := Trim(W); C := Trim(C);
  If (W = '') Or (NSrc >= MaxSrc) Then Exit;
  Inc(NSrc);
  SrcW[NSrc] := Copy(W, 1, 80);
  SrcC[NSrc] := Copy(C, 1, 80);
  SrcAdd := True;
End;

{ ligne "MOT;indice" ou "MOT<TAB>indice" }
Procedure SrcAddLine(L : String);
Var P, P2 : LongInt;
Begin
  P := Pos(';', L);
  P2 := Pos(#9, L);
  If (P2 > 0) And ((P = 0) Or (P2 < P)) Then P := P2;
  If P > 0 Then
  Begin
    If SrcAdd(Copy(L, 1, P - 1), Copy(L, P + 1, 255)) Then ;
  End
  Else If SrcAdd(L, '') Then ;
End;

{ mots donnes comme /E : MOT ou MOT=indice, separes par des virgules ; rend le nombre }
Function SrcAddInline(S : String) : LongInt;
Var P, Q, N : LongInt; T : String;
Begin
  N := 0;
  While S <> '' Do
  Begin
    P := Pos(',', S);
    If P = 0 Then
    Begin
      T := S; S := '';
    End
    Else
    Begin
      T := Copy(S, 1, P - 1); S := Copy(S, P + 1, 255);
    End;
    T := Trim(T);
    If T <> '' Then
    Begin
      Q := Pos('=', T);
      If Q > 0 Then
      Begin
        If SrcAdd(Copy(T, 1, Q - 1), Copy(T, Q + 1, 255)) Then Inc(N);
      End
      Else If SrcAdd(T, '') Then Inc(N);
    End;
  End;
  SrcAddInline := N;
End;

Procedure SrcDel(I : LongInt);
Var K : LongInt;
Begin
  If (I < 1) Or (I > NSrc) Then Exit;
  For K := I To NSrc - 1 Do
  Begin
    SrcW[K] := SrcW[K + 1]; SrcC[K] := SrcC[K + 1];
  End;
  Dec(NSrc);
End;

Procedure LoadBuiltIn;
Var I : LongInt; S : String;
Begin
  NSrc := 0;
  For I := 1 To BuiltInCount Do
  Begin
    Case Lang Of
      1 : S := BuiltEN[I];
      2 : S := BuiltGR[I];
      3 : S := BuiltSP[I];
      4 : S := BuiltIT[I];
    Else
      S := BuiltFR[I];
    End;
    SrcAddLine(S);
  End;
  ListName := ''; ListMod := False;
End;

{ charge un fichier de mots ; rend False s'il ne peut etre lu }
Function LoadList(Name : String) : Boolean;
Var H, R, St, E, N : LongInt; B : TBuf; S : String; Utf : Boolean;
Begin
  LoadList := False;
  If Not FOpenRead(Name, H) Then Exit;
  BufInit(B);
  Repeat
    If Not BufGrow(B, 32768) Then Break;
    R := FRead(H, @B.P^[B.Len], 32768);
    If R > 0 Then B.Len := B.Len + R;
  Until R <= 0;
  DosClose(H);
  { UTF-8 : une sequence valide dans le fichier }
  Utf := False;
  If OptEnc = encAuto Then
    For E := 0 To B.Len - 2 Do
      If (B.P^[E] >= $C2) And (B.P^[E] <= $F4) And (B.P^[E + 1] >= $80) And (B.P^[E + 1] <= $BF) Then
      Begin
        Utf := True;
        Break;
      End;
  NSrc := 0;
  St := 0;
  If (B.Len >= 3) And (B.P^[0] = $EF) And (B.P^[1] = $BB) And (B.P^[2] = $BF) Then St := 3;
  For E := St To B.Len Do
    If (E = B.Len) Or (B.P^[E] = 10) Then
    Begin
      N := E - St;
      If N > 255 Then N := 255;
      S[0] := Chr(MaxI(0, N));
      If N > 0 Then Move(B.P^[St], S[1], N);
      St := E + 1;
      S := Trim(S);
      While (Length(S) > 0) And (S[Length(S)] = #13) Do Delete(S, Length(S), 1);
      If (S <> '') And (S[1] <> ';') And (S[1] <> '#') Then SrcAddLine(ToCp850(S, OptEnc, Utf));
    End;
  BufFree(B);
  ListName := Name; ListMod := False;
  LoadList := True;
End;

{ enregistre la liste (MOT;indice, CP850) }
Function SaveList(Name : String) : Boolean;
Var B : TBuf; I, H : LongInt;
Begin
  SaveList := False;
  BufInit(B);
  BufAdd(B, '; Liste de mots du G'#130'n'#130'rateur de mots crois'#130's (OS/2-0) : MOT;indice'#13#10);
  For I := 1 To NSrc Do
  Begin
    BufAdd(B, SrcW[I]);
    If SrcC[I] <> '' Then BufAdd(B, ';' + SrcC[I]);
    BufAdd(B, #13#10);
  End;
  If FOpenWrite(Name, H) Then
  Begin
    SaveList := FWrite(H, B.P, B.Len) = B.Len;
    DosClose(H);
  End;
  BufFree(B);
  ListName := Name; ListMod := False;
End;

{ ---------------------------------------------------------------------- }
{ Dictionnaire de l'essai (mots retenus selon les options)                }
{ ---------------------------------------------------------------------- }

Procedure DictAdd(K : LongInt);
Var T : String; I : LongInt;
Begin
  T := Normalize(SrcW[K]);
  If T = '' Then Exit;
  If (Length(T) < OptLenMin) Or (Length(T) > OptLenMax) Or (Length(T) > WordMax) Or (Length(T) > Max2(OptW, OptH)) Then
  Begin
    Inc(DSkipped);
    Exit;
  End;
  For I := 1 To DCount Do If DItems[I].Txt = T Then Exit;
  If DCount >= MaxWords Then
  Begin
    Inc(DSkipped);
    Exit;
  End;
  Inc(DCount);
  DItems[DCount].Txt := T;
  DItems[DCount].Src := K;
  DItems[DCount].X := 0; DItems[DCount].Y := 0; DItems[DCount].Dir := 0; DItems[DCount].Num := 0;
  DItems[DCount].Placed := False;
End;

Procedure BuildDict;
Var K : LongInt;
Begin
  DCount := 0; DSkipped := 0;
  For K := 1 To NSrc Do DictAdd(K);
End;

{ ---------------------------------------------------------------------- }
{ Grille : placement des mots                                             }
{ ---------------------------------------------------------------------- }

Procedure GridInit(W, H : LongInt);
Var X, Y : LongInt;
Begin
  For Y := 1 To MaxH Do
    For X := 1 To MaxW Do
    Begin
      GCells[Y, X] := ' '; GMask[Y, X] := 0;
    End;
  GW := W; GH := H; GUsed := 0;
End;

{ peut-on placer T en (X, Y) dans la direction Dir ? Cross : lettres communes }
Function CanPlace(T : String; X, Y, Dir : LongInt; Var Cross : LongInt) : Boolean;
Var L, DX, DY, I, CX, CY : LongInt; C : Char;
Begin
  CanPlace := False;
  Cross := 0;
  L := Length(T);
  If Dir = DirAcross Then
  Begin
    DX := 1; DY := 0;
  End
  Else
  Begin
    DX := 0; DY := 1;
  End;
  If (X < 1) Or (Y < 1) Or (X + DX * (L - 1) > GW) Or (Y + DY * (L - 1) > GH) Then Exit;
  { les cases avant et apres le mot doivent etre vides }
  CX := X - DX; CY := Y - DY;
  If (CX >= 1) And (CY >= 1) Then If GCells[CY, CX] <> ' ' Then Exit;
  CX := X + DX * L; CY := Y + DY * L;
  If (CX <= GW) And (CY <= GH) Then If GCells[CY, CX] <> ' ' Then Exit;
  For I := 0 To L - 1 Do
  Begin
    CX := X + DX * I; CY := Y + DY * I;
    C := GCells[CY, CX];
    If C = ' ' Then
    Begin
      { case libre : pas de lettre voisine de chaque cote du mot }
      If Dir = DirAcross Then
      Begin
        If CY > 1 Then If GCells[CY - 1, CX] <> ' ' Then Exit;
        If CY < GH Then If GCells[CY + 1, CX] <> ' ' Then Exit;
      End
      Else
      Begin
        If CX > 1 Then If GCells[CY, CX - 1] <> ' ' Then Exit;
        If CX < GW Then If GCells[CY, CX + 1] <> ' ' Then Exit;
      End;
    End
    Else
    Begin
      { croisement : meme lettre, et pas de mot dans le meme sens }
      If C <> T[I + 1] Then Exit;
      If (GMask[CY, CX] And Dir) <> 0 Then Exit;
      Inc(Cross);
    End;
  End;
  If Cross >= L Then Exit;
  CanPlace := True;
End;

Procedure PlaceWord(T : String; X, Y, Dir : LongInt);
Var I, CX, CY : LongInt;
Begin
  CX := X; CY := Y;
  For I := 1 To Length(T) Do
  Begin
    If GCells[CY, CX] = ' ' Then Inc(GUsed);
    GCells[CY, CX] := T[I];
    GMask[CY, CX] := GMask[CY, CX] Or Dir;
    If Dir = DirAcross Then Inc(CX) Else Inc(CY);
  End;
End;

Var
  KX, KY, KDir, KCross, KTies : LongInt;

{ garde la position si elle est meilleure (ou egale : tirage au sort) }
Procedure Consider(X, Y, Dir, C : LongInt);
Begin
  If C > KCross Then
  Begin
    KCross := C; KTies := 1; KX := X; KY := Y; KDir := Dir;
  End
  Else If C = KCross Then
  Begin
    Inc(KTies);
    If Rnd(KTies) = 0 Then
    Begin
      KX := X; KY := Y; KDir := Dir;
    End;
  End;
End;

{ meilleure position du mot Idx (KX, KY, KDir, KCross) ; False : aucune }
Function FindBest(Idx : LongInt) : Boolean;
Var L, I, Dir, CX, CY, X, Y, C, Try : LongInt; T : String;
Begin
  T := DItems[Idx].Txt;
  L := Length(T);
  KCross := -1; KTies := 0; KX := 0; KY := 0; KDir := 0;
  If GUsed = 0 Then
  Begin
    { premier mot : au centre, avec un leger decalage aleatoire }
    If L <= GW Then Dir := DirAcross Else Dir := DirDown;
    For Try := 1 To 6 Do
    Begin
      If Dir = DirAcross Then
      Begin
        X := (GW - L) Div 2 + 1; Y := (GH + 1) Div 2;
      End
      Else
      Begin
        X := (GW + 1) Div 2; Y := (GH - L) Div 2 + 1;
      End;
      If Try < 6 Then
      Begin
        X := X + Rnd(3) - 1; Y := Y + Rnd(3) - 1;
      End;
      If CanPlace(T, X, Y, Dir, C) Then
      Begin
        Consider(X, Y, Dir, 0);
        Break;
      End;
    End;
  End
  Else If OptMinCross > 0 Then
  Begin
    { les lettres de la grille et les lettres identiques du mot }
    For CY := 1 To GH Do
      For CX := 1 To GW Do
        If GCells[CY, CX] <> ' ' Then
          For I := 1 To L Do
            If T[I] = GCells[CY, CX] Then
              For Dir := DirAcross To DirDown Do
                If (GMask[CY, CX] And Dir) = 0 Then
                Begin
                  If Dir = DirAcross Then
                  Begin
                    X := CX - (I - 1); Y := CY;
                  End
                  Else
                  Begin
                    X := CX; Y := CY - (I - 1);
                  End;
                  If CanPlace(T, X, Y, Dir, C) Then
                    If C >= OptMinCross Then Consider(X, Y, Dir, C);
                End;
  End
  Else
  Begin
    { mots isoles permis : toutes les positions }
    For Dir := DirAcross To DirDown Do
      For Y := 1 To GH Do
        For X := 1 To GW Do
          If CanPlace(T, X, Y, Dir, C) Then Consider(X, Y, Dir, C);
  End;
  FindBest := KDir > 0;
End;

Var
  Seq : Array[1..MaxWords] Of LongInt;

{ ordre de traitement des mots }
Procedure BuildOrder(TryNo : LongInt);
Var I, J, K, Tmp : LongInt; Swap : Boolean;
Begin
  For I := 1 To DCount Do Seq[I] := I;
  If OptOrder <> 'A' Then
    For I := DCount DownTo 2 Do
    Begin
      J := Rnd(I) + 1;
      Tmp := Seq[I]; Seq[I] := Seq[J]; Seq[J] := Tmp;
    End;
  If (OptOrder = 'L') Or (OptOrder = 'S') Then
  Begin
    { tri par insertion stable sur la longueur }
    For I := 2 To DCount Do
    Begin
      K := Seq[I];
      J := I - 1;
      Swap := True;
      While (J >= 1) And Swap Do
      Begin
        If OptOrder = 'L' Then Swap := Length(DItems[Seq[J]].Txt) < Length(DItems[K].Txt)
        Else Swap := Length(DItems[Seq[J]].Txt) > Length(DItems[K].Txt);
        If Swap Then
        Begin
          Seq[J + 1] := Seq[J];
          Dec(J);
        End;
      End;
      Seq[J + 1] := K;
    End;
    { apres le premier essai, l'ordre est un peu perturbe }
    If TryNo > 1 Then
      For I := 2 To DCount - 1 Do
        If Rnd(4) = 0 Then
        Begin
          Tmp := Seq[I]; Seq[I] := Seq[I + 1]; Seq[I + 1] := Tmp;
        End;
  End;
End;

{ un essai complet (resultat dans CPlaced, CCross, CArea, CX_, CY_, CDir) }
Procedure RunTry;
Var K, I, J, Cnt, Crs, X0, Y0, X1, Y1, EX, EY : LongInt; Prog : Boolean;
Begin
  GridInit(OptW, OptH);
  For I := 1 To DCount Do
  Begin
    DItems[I].Placed := False; DItems[I].Dir := 0;
  End;
  Cnt := 0; Crs := 0;
  Repeat
    Prog := False;
    For K := 1 To DCount Do
    Begin
      I := Seq[K];
      If (Not DItems[I].Placed) And (Cnt < OptMaxPlace) Then
        If FindBest(I) Then
        Begin
          PlaceWord(DItems[I].Txt, KX, KY, KDir);
          DItems[I].Placed := True;
          DItems[I].X := KX; DItems[I].Y := KY; DItems[I].Dir := KDir;
          Inc(Cnt);
          If KCross > 0 Then Crs := Crs + KCross;
          Prog := True;
        End;
    End;
  Until (Not Prog) Or (Cnt >= OptMaxPlace);
  X0 := MaxW + 1; Y0 := MaxH + 1; X1 := 0; Y1 := 0;
  For I := 1 To DCount Do
  Begin
    CX_[I] := DItems[I].X; CY_[I] := DItems[I].Y; CDir[I] := DItems[I].Dir;
    If DItems[I].Placed Then
    Begin
      J := Length(DItems[I].Txt) - 1;
      EX := DItems[I].X; EY := DItems[I].Y;
      If DItems[I].Dir = DirAcross Then EX := EX + J Else EY := EY + J;
      If DItems[I].X < X0 Then X0 := DItems[I].X;
      If DItems[I].Y < Y0 Then Y0 := DItems[I].Y;
      If EX > X1 Then X1 := EX;
      If EY > Y1 Then Y1 := EY;
    End;
  End;
  CPlaced := Cnt; CCross := Crs;
  If Cnt > 0 Then CArea := (X1 - X0 + 1) * (Y1 - Y0 + 1) Else CArea := 0;
End;

{ l'essai courant est-il meilleur que le meilleur ? }
Function CurBetter : Boolean;
Begin
  If Not BValid Then CurBetter := True
  Else If CPlaced <> BPlaced Then CurBetter := CPlaced > BPlaced
  Else If CCross <> BCross Then CurBetter := CCross > BCross
  Else CurBetter := CArea < BArea;
End;

{ numerote les mots (ordre de lecture) ; rend le dernier numero }
Function NumberWords : LongInt;
Var X, Y, I, N : LongInt; Started : Boolean;
Begin
  N := 0;
  For Y := 1 To GH Do
    For X := 1 To GW Do
      If GCells[Y, X] <> ' ' Then
      Begin
        Started := False;
        For I := 1 To DCount Do
          If DItems[I].Placed And (DItems[I].X = X) And (DItems[I].Y = Y) Then
          Begin
            If Not Started Then
            Begin
              Inc(N);
              Started := True;
            End;
            DItems[I].Num := N;
          End;
      End;
  NumberWords := N;
End;

{ numero de la case (0 : aucune definition n'y commence) }
Function CellNum(CX, CY : LongInt) : LongInt;
Var I : LongInt;
Begin
  CellNum := 0;
  For I := 1 To DCount Do
    If DItems[I].Placed And (DItems[I].X = CX) And (DItems[I].Y = CY) Then
    Begin
      CellNum := DItems[I].Num;
      Exit;
    End;
End;

{ zone affichee (rognee aux mots ou complete) }
Procedure ComputeView;
Var X, Y : LongInt;
Begin
  VX0 := 1; VY0 := 1; VX1 := GW; VY1 := GH;
  If (Not OptFull) And (GUsed > 0) Then
  Begin
    VX0 := GW; VY0 := GH; VX1 := 1; VY1 := 1;
    For Y := 1 To GH Do
      For X := 1 To GW Do
        If GCells[Y, X] <> ' ' Then
        Begin
          If X < VX0 Then VX0 := X;
          If X > VX1 Then VX1 := X;
          If Y < VY0 Then VY0 := Y;
          If Y > VY1 Then VY1 := Y;
        End;
  End;
End;

{ genere la grille : OptTries essais, la meilleure est gardee }
Procedure Generate;
Var T, I : LongInt;
Begin
  If OptLenMax > WordMax Then OptLenMax := WordMax;
  BuildDict;
  If OptHasSeed Then LastSeed := OptSeed Else LastSeed := (PTicks * 7919 + RSeed) And $7FFFFFF;
  RndInit(LastSeed);
  LogB.Len := 0;
  BValid := False; BPlaced := 0; BCross := 0; BArea := 0;
  For T := 1 To OptTries Do
  Begin
    BuildOrder(T);
    RunTry;
    BufAdd(LogB, 'Essai ' + IStr(T) + '/' + IStr(OptTries) + ' : ' + IStr(CPlaced) + ' mots, ' + IStr(CCross) +
           ' croisements, surface ' + IStr(CArea));
    If CurBetter Then
    Begin
      BValid := True; BPlaced := CPlaced; BCross := CCross; BArea := CArea;
      For I := 1 To DCount Do
      Begin
        BX[I] := CX_[I]; BY[I] := CY_[I]; BDir[I] := CDir[I];
      End;
      BufAdd(LogB, '  <- meilleur');
    End;
    BufAdd(LogB, #10);
  End;
  { la meilleure grille }
  GridInit(OptW, OptH);
  For I := 1 To DCount Do
  Begin
    DItems[I].Placed := BValid And (BDir[I] > 0);
    DItems[I].X := BX[I]; DItems[I].Y := BY[I]; DItems[I].Dir := BDir[I]; DItems[I].Num := 0;
    If DItems[I].Placed Then PlaceWord(DItems[I].Txt, DItems[I].X, DItems[I].Y, DItems[I].Dir);
  End;
  MaxNum := NumberWords;
  ComputeView;
  Generated := True;
End;

{ rogner ou non : la vue seule change }
Procedure RefreshView;
Begin
  If Generated Then ComputeView;
End;

{ ---------------------------------------------------------------------- }
{ Sorties : texte, HTML, CSV                                              }
{ ---------------------------------------------------------------------- }

Procedure OW(S : String);
Begin
  If OptUtf8Out Then BufAdd(OutB, ToUtf8(S)) Else BufAdd(OutB, S);
End;

Procedure OL(S : String);
Begin
  OW(S);
  BufAdd(OutB, #13#10);
End;

Function LetterCh(Ch : Char) : Char;
Begin
  If OptLower And (Ch >= 'A') And (Ch <= 'Z') Then LetterCh := Chr(Ord(Ch) + 32) Else LetterCh := Ch;
End;

Function BlockChar : Char;
Begin
  If OptGraphic And Not OptBlockSet Then BlockChar := Chr(178) Else BlockChar := OptBlockCh;
End;

{ ligne de separation : 0 haut, 1 milieu, 2 bas }
Procedure PrintBorder(Kind : LongInt);
Var X : LongInt; HCh, Lf, Md, Rt : Char; S : String;
Begin
  If OptGraphic Then
  Begin
    HCh := Chr(196);
    Case Kind Of
      0 : Begin Lf := Chr(218); Md := Chr(194); Rt := Chr(191); End;
      1 : Begin Lf := Chr(195); Md := Chr(197); Rt := Chr(180); End;
    Else
      Begin Lf := Chr(192); Md := Chr(193); Rt := Chr(217); End;
    End;
  End
  Else
  Begin
    HCh := '-'; Lf := '+'; Md := '+'; Rt := '+';
  End;
  S := Lf;
  BufAdd(OutB, S);
  For X := VX0 To VX1 Do
  Begin
    S := HCh + HCh + HCh + HCh;
    If X < VX1 Then S := S + Md Else S := S + Rt;
    BufAdd(OutB, S);
  End;
  BufAdd(OutB, #13#10);
End;

Procedure PrintGrid(Solution : Boolean);
Var X, Y, Ln, N : LongInt; VCh, BCh, Ch : Char; S : String;
Begin
  If OptGraphic Then VCh := Chr(179) Else VCh := '|';
  BCh := BlockChar;
  For Y := VY0 To VY1 Do
  Begin
    If Y = VY0 Then PrintBorder(0) Else PrintBorder(1);
    For Ln := 1 To 2 Do
    Begin
      S := VCh;
      BufAdd(OutB, S);
      For X := VX0 To VX1 Do
      Begin
        If GCells[Y, X] = ' ' Then S := BCh + BCh + BCh + BCh
        Else If Ln = 1 Then
        Begin
          N := CellNum(X, Y);
          If N > 0 Then S := PadR(IStr(N), 4) Else S := '    ';
        End
        Else
        Begin
          If Solution Then Ch := LetterCh(GCells[Y, X]) Else Ch := OptEmptyCh;
          S := ' ' + Ch + '  ';
        End;
        BufAdd(OutB, S + VCh);
      End;
      BufAdd(OutB, #13#10);
    End;
  End;
  PrintBorder(2);
End;

Function ClueText(I : LongInt) : String;
Var S : String; K : LongInt;
Begin
  K := DItems[I].Src;
  If (K < 1) Or (K > NSrc) Or (SrcC[K] = '') Then S := Tx(10) + IStr(Length(DItems[I].Txt)) + Tx(11)
  Else S := Copy(SrcC[K], 1, ClueMax) + ' (' + IStr(Length(DItems[I].Txt)) + ')';
  ClueText := S;
End;

Procedure PrintClues(Dir : LongInt);
Var N, I : LongInt;
Begin
  If Dir = DirAcross Then OL(Tx(8)) Else OL(Tx(9));
  For N := 1 To MaxNum Do
    For I := 1 To DCount Do
      If DItems[I].Placed And (DItems[I].Dir = Dir) And (DItems[I].Num = N) Then
        OL(PadL(IStr(N), 4) + '. ' + ClueText(I));
  OL('');
End;

Function GridTitle : String;
Begin
  GridTitle := Tx(7) + ' (' + IStr(VX1 - VX0 + 1) + ' x ' + IStr(VY1 - VY0 + 1) + ')';
End;

Procedure WriteText;
Begin
  If Not OptSolOnly Then
  Begin
    OL(GridTitle);
    OL('');
    If Not OptNoGrid Then
    Begin
      PrintGrid(False);
      OL('');
    End;
    If Not OptNoClue Then
    Begin
      PrintClues(DirAcross);
      PrintClues(DirDown);
    End;
  End;
  If OptShowSol Or OptSolOnly Then
  Begin
    OL(GridTitle + ' - ' + Tx(20));
    OL('');
    PrintGrid(True);
    OL('');
  End;
End;

Function HtmlEsc(S : String) : String;
Var I : LongInt; R : String;
Begin
  R := '';
  For I := 1 To Length(S) Do
    Case S[I] Of
      '&' : R := R + '&amp;';
      '<' : R := R + '&lt;';
      '>' : R := R + '&gt;';
      '"' : R := R + '&quot;';
    Else
      R := R + S[I];
    End;
  HtmlEsc := R;
End;

{ HTML : toujours en UTF-8 }
Procedure HL(S : String);
Begin
  BufAdd(OutB, ToUtf8(S));
  BufAdd(OutB, #13#10);
End;

Procedure HtmlTable(Solution : Boolean);
Var X, Y, N : LongInt; S : String;
Begin
  HL('<table class="cw">');
  For Y := VY0 To VY1 Do
  Begin
    BufAdd(OutB, '<tr>');
    For X := VX0 To VX1 Do
      If GCells[Y, X] = ' ' Then BufAdd(OutB, '<td class="b"></td>')
      Else
      Begin
        S := '<td>';
        N := CellNum(X, Y);
        If N > 0 Then S := S + '<span class="n">' + IStr(N) + '</span>';
        If Solution Then S := S + LetterCh(GCells[Y, X]);
        BufAdd(OutB, S + '</td>');
      End;
    HL('</tr>');
  End;
  HL('</table>');
End;

Procedure HtmlClues(Dir : LongInt);
Var N, I : LongInt;
Begin
  If Dir = DirAcross Then HL('<h2>' + HtmlEsc(Tx(8)) + '</h2>') Else HL('<h2>' + HtmlEsc(Tx(9)) + '</h2>');
  HL('<ul class="cl">');
  For N := 1 To MaxNum Do
    For I := 1 To DCount Do
      If DItems[I].Placed And (DItems[I].Dir = Dir) And (DItems[I].Num = N) Then
        HL('<li><b>' + IStr(N) + '.</b> ' + HtmlEsc(ClueText(I)) + '</li>');
  HL('</ul>');
End;

Procedure WriteHtml;
Begin
  HL('<!DOCTYPE html>');
  HL('<html><head>');
  HL('<meta charset="utf-8">');
  HL('<title>' + HtmlEsc(Tx(7)) + '</title>');
  HL('<style>');
  HL('body{font-family:sans-serif;margin:20px}');
  HL('table.cw{border-collapse:collapse;margin:10px 0}');
  HL('table.cw td{width:34px;height:34px;border:1px solid #000;');
  HL(' position:relative;text-align:center;font:bold 18px monospace}');
  HL('td.b{background:#000}');
  HL('span.n{position:absolute;top:1px;left:2px;font:9px sans-serif}');
  HL('ul.cl{list-style:none;padding:0}');
  HL('</style></head><body>');
  HL('<h1>' + HtmlEsc(Tx(7)) + '</h1>');
  If Not OptSolOnly Then
  Begin
    If Not OptNoGrid Then HtmlTable(False);
    If Not OptNoClue Then
    Begin
      HtmlClues(DirAcross);
      HtmlClues(DirDown);
    End;
  End;
  If OptShowSol Or OptSolOnly Then
  Begin
    HL('<h2>' + HtmlEsc(Tx(20)) + '</h2>');
    HtmlTable(True);
  End;
  HL('</body></html>');
End;

{ CSV : numero;sens (H/V);x;y;mot;indice }
Procedure WriteCsv;
Var N, I, P, Dir, K : LongInt; S, Cl, Ch : String;
Begin
  OL('NUM;DIR;X;Y;WORD;CLUE');
  For N := 1 To MaxNum Do
    For Dir := DirAcross To DirDown Do
      For I := 1 To DCount Do
        If DItems[I].Placed And (DItems[I].Dir = Dir) And (DItems[I].Num = N) Then
        Begin
          K := DItems[I].Src;
          Cl := '';
          If (K >= 1) And (K <= NSrc) Then Cl := SrcC[K];
          For P := 1 To Length(Cl) Do If Cl[P] = ';' Then Cl[P] := ',';
          If Dir = DirAcross Then Ch := 'H' Else Ch := 'V';
          S := DItems[I].Txt;
          For P := 1 To Length(S) Do S[P] := LetterCh(S[P]);
          OL(IStr(N) + ';' + Ch + ';' + IStr(DItems[I].X - VX0 + 1) + ';' + IStr(DItems[I].Y - VY0 + 1) + ';' + S + ';' + Cl);
        End;
End;

{ sortie dans OutB selon OptFmt (T, H, C) }
Procedure BuildOutput;
Begin
  OutB.Len := 0;
  Case OptFmt Of
    'H' : WriteHtml;
    'C' : WriteCsv;
  Else
    WriteText;
  End;
End;

Function Density : LongInt;
Var A : LongInt;
Begin
  A := (VX1 - VX0 + 1) * (VY1 - VY0 + 1);
  If A > 0 Then Density := (GUsed * 100) Div A Else Density := 0;
End;

{ mots non places (separes par des virgules) }
Function NotPlaced : String;
Var I : LongInt; S : String;
Begin
  S := '';
  For I := 1 To DCount Do
    If Not DItems[I].Placed Then
    Begin
      If S <> '' Then S := S + ', ';
      If Length(S) < 200 Then S := S + DItems[I].Txt;
    End;
  NotPlaced := S;
End;

{ ---------------------------------------------------------------------- }
{ Options par defaut et options de la ligne de commande                   }
{ ---------------------------------------------------------------------- }

Procedure InitDefaults;
Begin
  OptW := 15; OptH := 15; OptMaxPlace := MaxWords; OptLenMin := 3; OptLenMax := WordMax;
  OptTries := 30; OptMinCross := 1; OptSeed := 0; OptHasSeed := False; LastSeed := 0;
  OptOrder := 'L'; OptFmt := 'T';
  OptFull := False; OptShowSol := False; OptSolOnly := False; OptNoClue := False; OptNoGrid := False;
  OptGraphic := False; OptLower := False; OptQuiet := False; OptVerbose := False; OptNeedAll := False;
  OptUtf8Out := False; OptEnc := encAuto;
  OptBlockCh := '#'; OptEmptyCh := ' '; OptBlockSet := False;
  Lang := 0;
  NSrc := 0; DCount := 0; DSkipped := 0; Generated := False; ListName := ''; ListMod := False;
  RSeed := 12345;
End;

Function ParseNum(S : String; Lo, Hi : LongInt; Var V : LongInt) : Boolean;
Var N, E : LongInt;
Begin
  S := Trim(S);
  Val(S, N, E);
  ParseNum := (E = 0) And (S <> '') And (N >= Lo) And (N <= Hi);
  If (E = 0) And (S <> '') And (N >= Lo) And (N <= Hi) Then V := N;
End;

Var
  CliFile, CliOut, CliErr : String;
  CliInline : Boolean;

Procedure CliBad(Name : String);
Begin
  If CliErr = '' Then CliErr := 'Valeur invalide pour /' + Name;
End;

{ une option de CROSSGEN (Name en majuscules, S : valeur) }
Procedure ApplyOption(Name, S : String; HasVal : Boolean);
Var P, V : LongInt; U : String;
Begin
  U := UpStr(S);
  If Name = 'F' Then CliFile := S
  Else If Name = 'E' Then
  Begin
    If SrcAddInline(S) > 0 Then CliInline := True;
  End
  Else If Name = 'W' Then
  Begin
    If Not ParseNum(S, 5, MaxW, OptW) Then CliBad(Name);
  End
  Else If (Name = 'HEIGHT') Or (Name = 'HT') Then
  Begin
    If Not ParseNum(S, 5, MaxH, OptH) Then CliBad(Name);
  End
  Else If Name = 'SIZE' Then
  Begin
    P := Pos('X', U);
    If P = 0 Then P := Pos(',', S);
    If (P = 0) Or Not ParseNum(Copy(S, 1, P - 1), 5, MaxW, OptW) Or Not ParseNum(Copy(S, P + 1, 255), 5, MaxH, OptH) Then
      CliBad(Name);
  End
  Else If Name = 'N' Then
  Begin
    If Not ParseNum(S, 1, MaxWords, OptMaxPlace) Then CliBad(Name);
  End
  Else If Name = 'MIN' Then
  Begin
    If Not ParseNum(S, 1, WordMax, OptLenMin) Then CliBad(Name);
  End
  Else If Name = 'MAX' Then
  Begin
    If Not ParseNum(S, 1, WordMax, OptLenMax) Then CliBad(Name);
  End
  Else If Name = 'T' Then
  Begin
    If Not ParseNum(S, 1, 10000, OptTries) Then CliBad(Name);
  End
  Else If Name = 'S' Then
  Begin
    If ParseNum(S, 0, 2147483647, OptSeed) Then OptHasSeed := True Else CliBad(Name);
  End
  Else If Name = 'I' Then
  Begin
    If Not ParseNum(S, 0, 4, OptMinCross) Then CliBad(Name);
  End
  Else If Name = 'ORDER' Then
  Begin
    If (U <> '') And ((U[1] = 'L') Or (U[1] = 'S') Or (U[1] = 'R') Or (U[1] = 'A')) Then OptOrder := U[1]
    Else CliBad(Name);
  End
  Else If Name = 'FMT' Then
  Begin
    If (U = 'TXT') Or (U = 'T') Or (U = 'TEXT') Then OptFmt := 'T'
    Else If (U = 'HTML') Or (U = 'HTM') Then OptFmt := 'H'
    Else If U = 'CSV' Then OptFmt := 'C'
    Else CliBad(Name);
  End
  Else If (Name = 'OUT') Or (Name = 'O') Then CliOut := S
  Else If Name = 'BLOCK' Then
  Begin
    If S <> '' Then
    Begin
      OptBlockCh := S[1]; OptBlockSet := True;
    End
    Else CliBad(Name);
  End
  Else If Name = 'EMPTY' Then
  Begin
    If (S = '') Or (U = 'SPACE') Then OptEmptyCh := ' ' Else OptEmptyCh := S[1];
  End
  Else If Name = 'LANG' Then SetLang(S)
  Else If Name = 'FULL' Then OptFull := True
  Else If Name = 'A' Then OptShowSol := True
  Else If Name = 'SOLONLY' Then OptSolOnly := True
  Else If Name = 'NOGRID' Then OptNoGrid := True
  Else If Name = 'NOCLUE' Then OptNoClue := True
  Else If Name = 'G' Then OptGraphic := True
  Else If Name = 'LC' Then OptLower := True
  Else If Name = 'CP437' Then OptEnc := encCp437
  Else If Name = 'CP850' Then OptEnc := encCp850
  Else If Name = 'UTF8' Then OptUtf8Out := True
  Else If Name = 'ALL' Then OptNeedAll := True
  Else If Name = 'V' Then OptVerbose := True
  Else If Name = 'Q' Then OptQuiet := True
  Else If CliErr = '' Then CliErr := 'Option inconnue : /' + Name;
  V := 0;
End;

Function IsOptName(S : String) : Boolean;
Var I : LongInt;
Begin
  IsOptName := False;
  If S = '' Then Exit;
  For I := 1 To Length(S) Do
    If Not (((S[I] >= 'A') And (S[I] <= 'Z')) Or ((S[I] >= 'a') And (S[I] <= 'z')) Or ((S[I] >= '0') And (S[I] <= '9')) Or
       (S[I] = '?')) Then Exit;
  IsOptName := True;
End;

{ les parametres du programme, comme CROSSGEN }
Procedure ParseArgs;
Var I, K, P : LongInt; Arg, Name, S : String; HasVal, IsOpt : Boolean;
Begin
  CliFile := ''; CliOut := ''; CliErr := ''; CliInline := False;
  I := 1;
  While I <= ParamCount Do
  Begin
    Arg := ParamStr(I);
    IsOpt := False;
    Name := ''; S := ''; HasVal := False;
    If (Length(Arg) > 1) And ((Arg[1] = '/') Or (Arg[1] = '-')) Then
    Begin
      K := 1;
      While (K <= Length(Arg)) And ((Arg[K] = '/') Or (Arg[K] = '-')) Do Inc(K);
      P := K;
      While (P <= Length(Arg)) And (Arg[P] <> ':') And (Arg[P] <> '=') Do Inc(P);
      Name := Copy(Arg, K, P - K);
      HasVal := P <= Length(Arg);
      S := Copy(Arg, P + 1, 255);
      IsOpt := IsOptName(Name);
    End;
    If IsOpt Then
    Begin
      Name := UpStr(Name);
      { valeur dans le parametre suivant (/W 20) }
      If (Not HasVal) And (I < ParamCount) And ((Name = 'F') Or (Name = 'E') Or (Name = 'W') Or (Name = 'HEIGHT') Or
         (Name = 'HT') Or (Name = 'SIZE') Or (Name = 'N') Or (Name = 'MIN') Or (Name = 'MAX') Or (Name = 'T') Or
         (Name = 'S') Or (Name = 'I') Or (Name = 'ORDER') Or (Name = 'FMT') Or (Name = 'OUT') Or (Name = 'O') Or
         (Name = 'BLOCK') Or (Name = 'EMPTY') Or (Name = 'LANG')) Then
      Begin
        Inc(I);
        S := ParamStr(I);
        HasVal := True;
      End;
      If (Name <> '?') And (Name <> 'H') And (Name <> 'HELP') And (Name <> 'VERSION') Then ApplyOption(Name, S, HasVal);
    End
    Else If CliFile = '' Then CliFile := Arg
    Else If SrcAddInline(Arg) > 0 Then CliInline := True;
    Inc(I);
  End;
  If OptLenMax > WordMax Then OptLenMax := WordMax;
  If (OptLenMin > OptLenMax) And (CliErr = '') Then CliErr := 'Valeur invalide pour /MIN et /MAX';
End;

{ ==================================================================== }
{ Fenetre : etat, disposition et primitives de dessin                   }
{ ==================================================================== }

Const
  PnWDef = 330; TabH = 24; BtnH = 30; ClueRowH = 16; WordRowH = 18;
  MaxTb = 24;
  MaxClueRows = 700;
  { commandes }
  cmNew = 100; cmOpen = 101; cmSaveList = 102; cmSaveListAs = 103; cmExport = 104; cmQuit = 105;
  cmExportTxt = 106; cmExportHtml = 107; cmExportCsv = 108; cmCopyText = 109;
  cmAddWords = 110; cmAddWord = 111; cmEditWord = 112; cmDelWord = 113; cmClearWords = 114; cmBuiltIn = 115;
  cmEncAuto = 116; cmEnc437 = 117; cmEnc850 = 118;
  cmGenerate = 120; cmSameSeed = 121; cmParams = 122; cmSizeCustom = 123; cmFull = 124; cmLog = 125; cmStats = 126;
  cmOrdL = 127; cmOrdS = 128; cmOrdR = 129; cmOrdA = 130; cmSeed = 131;
  cmShowFill = 140; cmShowSol = 141; cmToggleSol = 142; cmLower = 143; cmTabClues = 144; cmTabWords = 145;
  cmNumbers = 146; cmToolbar = 147;
  cmCheck = 150; cmClearAns = 151; cmRevealLetter = 152; cmRevealWord = 153;
  cmLangFR = 160; cmLangEN = 161; cmLangGR = 162; cmLangSP = 163; cmLangIT = 164;
  cmSummary = 165; cmNeedAll = 166; cmExpOpts = 167;
  cmHelp = 170; cmOpts = 171; cmAbout = 172;
  cmSizeFirst = 180;     { + indice de la taille du sous-menu }
  NSizes = 8;

Var
  Hab, Hmq, Frame, Client, MenuHw, Hps, CW, CH : LongInt;
  GQmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..8191] Of Byte;
  MenuLen : LongInt;
  UX1, UY1, UX2, UY2 : LongInt;
  IcX, IcY : LongInt;
  { disposition (Y vers le bas) }
  Y0, Y1, PnX, PnW, WX1, PageX0, PageY0, PageX1, PageY1, GX0, GY0, Cs, Cols, Rows : LongInt;
  { etat de l'affichage }
  ShowSolution, ShowNums, ShowToolbar : Boolean;
  PanTab : LongInt;               { 0 : definitions, 1 : mots }
  PanTop, WordSel, WordTop : LongInt;
  { jeu : reponses de l'utilisateur }
  UCells : Array[1..MaxH, 1..MaxW] Of Char;
  UBad : Array[1..MaxH, 1..MaxW] Of Boolean;
  CurX, CurY, CurDir : LongInt;
  Checked : Boolean;
  { lignes des definitions (pour le clic) }
  NClueRows : LongInt;
  ClueRowItem, ClueRowY : Array[0..MaxClueRows - 1] Of LongInt;
  ClueTotalH : LongInt;
  { barre d'outils }
  NTb, TbDown, TbHot : LongInt;
  TbCmd, TbX, TbW, TbIco : Array[0..MaxTb - 1] Of LongInt;
  TbTxt, TbTip : Array[0..MaxTb - 1] Of String;
  StatusMsg, SavedMsg : String;
  OptSummary : Boolean;

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
{ Icones de la barre d'outils (16 x 16)                                 }
{ ==================================================================== }

Procedure IcoTb(K : LongInt);
Var I : LongInt;
Begin
  Case K Of
    1 :
      Begin
        { nouvelle liste : page }
        IR(2, 1, 11, 14, cWhite); IB(2, 1, 11, 14, cBlack); IR(9, 1, 11, 3, cSilver);
        IR(4, 5, 9, 5, cGray); IR(4, 8, 9, 8, cGray); IR(4, 11, 7, 11, cGray);
        IR(9, 8, 14, 13, cYellow); IR(11, 6, 12, 15, cYellow);
      End;
    2 :
      Begin
        IR(1, 3, 6, 4, cBrown); IR(1, 4, 14, 13, cYellow); IB(1, 4, 14, 13, cBrown);
        IR(3, 7, 15, 13, cYellow); IB(3, 7, 15, 13, cBrown);
      End;
    3 : Begin IR(1, 1, 14, 14, cNavy); IR(4, 1, 11, 5, cSilver); IR(3, 8, 12, 14, cWhite); IB(1, 1, 14, 14, cBlack); End;
    4 :
      Begin
        { exporter : page et fleche }
        IR(1, 1, 9, 14, cWhite); IB(1, 1, 9, 14, cBlack);
        IR(3, 4, 7, 4, cGray); IR(3, 7, 7, 7, cGray); IR(3, 10, 6, 10, cGray);
        IR(8, 7, 13, 8, cDGreen); IR(11, 5, 12, 10, cDGreen); IR(13, 6, 13, 9, cDGreen); IR(14, 7, 14, 8, cDGreen);
      End;
    5 :
      Begin
        { generer : deux fleches en rond }
        For I := 0 To 7 Do
        Begin
          IR(3 + I, 2, 3 + I, 3, cDGreen);
          IR(3 + I, 12, 3 + I, 13, cDGreen);
        End;
        IR(2, 3, 3, 8, cDGreen); IR(12, 7, 13, 12, cDGreen);
        IR(10, 0, 10, 5, cDGreen); IR(11, 1, 11, 4, cDGreen); IR(4, 10, 4, 15, cDGreen); IR(3, 11, 3, 14, cDGreen);
      End;
    6 :
      Begin
        { meme graine : de }
        IR(2, 2, 13, 13, cWhite); IB(2, 2, 13, 13, cBlack);
        IR(4, 4, 5, 5, cBlack); IR(10, 10, 11, 11, cBlack); IR(7, 7, 8, 8, cBlack); IR(10, 4, 11, 5, cBlack);
        IR(4, 10, 5, 11, cBlack);
      End;
    7 :
      Begin
        { solution : grille et lettre }
        IR(1, 1, 14, 14, cWhite); IB(1, 1, 14, 14, cBlack); IR(1, 7, 14, 7, cBlack); IR(7, 1, 7, 14, cBlack);
        IR(8, 1, 13, 6, cBlack); IR(1, 8, 6, 13, cBlack);
        IR(3, 2, 4, 2, cNavy); IR(2, 3, 2, 6, cNavy); IR(5, 3, 5, 6, cNavy); IR(3, 4, 4, 4, cNavy);
      End;
    8 :
      Begin
        { verifier : coche }
        IR(1, 1, 14, 14, cWhite); IB(1, 1, 14, 14, cGray);
        Thick(IcX + 3, IcY + 7, IcX + 6, IcY + 10, cDGreen); Thick(IcX + 6, IcY + 10, IcX + 12, IcY + 4, cDGreen);
      End;
    9 :
      Begin
        { ajouter des mots : plus }
        IR(2, 2, 11, 13, cWhite); IB(2, 2, 11, 13, cBlack); IR(4, 5, 9, 5, cGray); IR(4, 8, 9, 8, cGray);
        IR(9, 9, 14, 10, cDGreen); IR(11, 7, 12, 12, cDGreen);
      End;
    10 :
      Begin
        { parametres : engrenage }
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
        { effacer les reponses : gomme }
        IR(2, 8, 9, 13, cPink); IR(9, 4, 13, 9, cWhite); IB(2, 4, 13, 13, cBlack);
      End;
  End;
End;

{ chiffres de 3 x 5 points pour les numeros des cases }
Const
  Digit : Array[0..9] Of LongInt = ($7B6F, $2C97, $73E7, $73CF, $5BC9, $79CF, $79EF, $7292, $7BEF, $7BCF);

Procedure TinyNum(X, Y, N, Sc, C : LongInt);
Var S : String; K, D, R, Q, B : LongInt;
Begin
  S := IStr(N);
  For K := 1 To Length(S) Do
  Begin
    D := Ord(S[K]) - 48;
    For R := 0 To 4 Do
      For Q := 0 To 2 Do
      Begin
        B := 14 - (R * 3 + Q);
        If ((Digit[D] Shr B) And 1) <> 0 Then FBar(X + Q * Sc, Y + R * Sc, X + Q * Sc + Sc - 1, Y + R * Sc + Sc - 1, C);
      End;
    X := X + 4 * Sc;
  End;
End;

{ ==================================================================== }
{ Disposition                                                           }
{ ==================================================================== }

Procedure Layout;
Var Aw, Ah : LongInt;
Begin
  If ShowToolbar Then Y0 := TbH Else Y0 := 0;
  Y1 := CH - SbH - 1;
  PnW := PnWDef;
  If CW < 700 Then PnW := 260;
  PnX := CW - PnW;
  WX1 := PnX - 1;
  If Generated And (BPlaced > 0) Then
  Begin
    Cols := VX1 - VX0 + 1; Rows := VY1 - VY0 + 1;
  End
  Else
  Begin
    Cols := OptW; Rows := OptH;
  End;
  Aw := WX1 - 48; Ah := Y1 - Y0 - 96;
  Cs := MinI(Aw Div MaxI(1, Cols), Ah Div MaxI(1, Rows));
  If Cs > 44 Then Cs := 44;
  If Cs < 6 Then Cs := 6;
  PageX0 := MaxI(8, (WX1 - Cols * Cs) Div 2 - 16);
  PageX1 := MinI(WX1 - 10, PageX0 + Cols * Cs + 32);
  PageY0 := Y0 + 12;
  PageY1 := MinI(Y1 - 12, PageY0 + Rows * Cs + 72);
  GX0 := PageX0 + 16 + ((PageX1 - PageX0 - 32) - Cols * Cs) Div 2;
  GY0 := PageY0 + 52;
End;

Procedure InvalGrid;
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
  TbPressed := ((C = cmToggleSol) And ShowSolution);
End;

Function TbDisabled(C : LongInt) : Boolean;
Begin
  TbDisabled := False;
  Case C Of
    cmExport, cmToggleSol, cmCheck, cmClearAns : TbDisabled := Not Generated Or (BPlaced = 0);
    cmSameSeed : TbDisabled := Not Generated;
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

{ mot place (indice) qui contient la case (X, Y) dans la direction Dir ; 0 : aucun }
Function WordAt(X, Y, Dir : LongInt) : LongInt;
Var I, L : LongInt;
Begin
  WordAt := 0;
  For I := 1 To DCount Do
    If DItems[I].Placed And (DItems[I].Dir = Dir) Then
    Begin
      L := Length(DItems[I].Txt);
      If Dir = DirAcross Then
      Begin
        If (Y = DItems[I].Y) And (X >= DItems[I].X) And (X < DItems[I].X + L) Then
        Begin
          WordAt := I;
          Exit;
        End;
      End
      Else If (X = DItems[I].X) And (Y >= DItems[I].Y) And (Y < DItems[I].Y + L) Then
      Begin
        WordAt := I;
        Exit;
      End;
    End;
End;

{ mot courant (celui du curseur) }
Function CurWord : LongInt;
Var I : LongInt;
Begin
  I := 0;
  If (CurX > 0) And (CurY > 0) Then
  Begin
    I := WordAt(CurX, CurY, CurDir);
    If I = 0 Then I := WordAt(CurX, CurY, 3 - CurDir);
  End;
  CurWord := I;
End;

Function InWord(I, X, Y : LongInt) : Boolean;
Var L : LongInt;
Begin
  InWord := False;
  If I <= 0 Then Exit;
  L := Length(DItems[I].Txt);
  If DItems[I].Dir = DirAcross Then InWord := (Y = DItems[I].Y) And (X >= DItems[I].X) And (X < DItems[I].X + L)
  Else InWord := (X = DItems[I].X) And (Y >= DItems[I].Y) And (Y < DItems[I].Y + L);
End;

Procedure PaintPage;
Var X, Y, Sx, Sy, N, Bg, Fg, Sc, W : LongInt; S : String; Ch : Char; CwI : LongInt;
Begin
  FBar(0, Y0, WX1, Y1, cGray);
  { feuille de papier et son ombre }
  FBar(PageX0 + 5, PageY0 + 5, PageX1 + 5, PageY1 + 5, cBlack);
  FBar(PageX0, PageY0, PageX1, PageY1, cWhite);
  Box(PageX0, PageY0, PageX1, PageY1, cBlack);
  If Not Generated Or (BPlaced = 0) Then
  Begin
    OutTxt(PageX0 + 16, PageY0 + 16, Fit(Tx(7), PageX1 - PageX0 - 32), cNavy, cWhite);
    If NSrc = 0 Then S := 'La liste de mots est vide : Mots - Ajouter des mots.'
    Else If Generated Then S := 'Aucun mot n''a pu '#136'tre plac'#130' : voir Grille - Param'#138'tres.'
    Else S := 'Grille - R'#130'g'#130'n'#130'rer (F5).';
    OutTxt(PageX0 + 16, PageY0 + 40, Fit(S, PageX1 - PageX0 - 32), cBlack, cWhite);
    Exit;
  End;
  S := Tx(7) + ' (' + IStr(Cols) + ' x ' + IStr(Rows) + ')';
  If ShowSolution Then S := S + ' - ' + Tx(20);
  OutTxt(PageX0 + 16, PageY0 + 14, Fit(S, PageX1 - PageX0 - 32), cNavy, cWhite);
  HLine(PageX0 + 16, PageX1 - 16, PageY0 + 36, cSilver);
  CwI := 0;
  If Not ShowSolution Then CwI := CurWord;
  Sc := 1;
  If Cs >= 40 Then Sc := 2;
  For Y := VY0 To VY1 Do
    For X := VX0 To VX1 Do
    Begin
      Sx := GX0 + (X - VX0) * Cs; Sy := GY0 + (Y - VY0) * Cs;
      If (Sy > UY2) Or (Sy + Cs < UY1) Then Continue;
      If GCells[Y, X] = ' ' Then
      Begin
        FBar(Sx, Sy, Sx + Cs, Sy + Cs, cBlack);
        Continue;
      End;
      Bg := cWhite;
      If (CwI > 0) And InWord(CwI, X, Y) Then Bg := cSilver;
      If (Not ShowSolution) And (X = CurX) And (Y = CurY) Then Bg := cYellow;
      FBar(Sx + 1, Sy + 1, Sx + Cs - 1, Sy + Cs - 1, Bg);
      Box(Sx, Sy, Sx + Cs, Sy + Cs, cBlack);
      If ShowNums And (Cs >= 14) Then
      Begin
        N := CellNum(X, Y);
        If N > 0 Then TinyNum(Sx + 2, Sy + 2, N, Sc, cBlack);
      End;
      Ch := ' '; Fg := cBlack;
      If ShowSolution Then
      Begin
        Ch := LetterCh(GCells[Y, X]); Fg := cNavy;
      End
      Else If UCells[Y, X] <> ' ' Then
      Begin
        Ch := LetterCh(UCells[Y, X]);
        If Checked And UBad[Y, X] Then Fg := cRed Else Fg := cBlack;
      End;
      If (Ch <> ' ') And (Cs >= 16) Then
      Begin
        W := 8;
        S := Ch;
        OutTxt(Sx + (Cs - W) Div 2 + 1, Sy + (Cs - 16) Div 2 + 2, S, Fg, Bg);
      End;
    End;
End;

{ ==================================================================== }
{ Panneau de droite : definitions et mots                               }
{ ==================================================================== }

Procedure Tab(X, W : LongInt; S : String; Act : Boolean);
Begin
  If Act Then
  Begin
    FBar(X, Y0 + 2, X + W - 1, Y0 + TabH - 1, cWhite);
    HLine(X, X + W - 1, Y0 + 2, cWhite); VLine(X, Y0 + 2, Y0 + TabH - 1, cWhite);
    VLine(X + W - 1, Y0 + 2, Y0 + TabH - 1, cBlack);
    OutTxt(X + 8, Y0 + 5, Fit(S, W - 12), cBlack, cWhite);
  End
  Else
  Begin
    VLine(X + W - 1, Y0 + 5, Y0 + TabH - 3, cGray);
    OutTxt(X + 8, Y0 + 6, Fit(S, W - 12), cGray, cSilver);
  End;
End;

Function PanelY0 : LongInt;
Begin
  PanelY0 := Y0 + TabH;
End;

Function PanelY1 : LongInt;
Begin
  If PanTab = 1 Then PanelY1 := Y1 - BtnH - 6 Else PanelY1 := Y1;
End;

{ lignes d'une definition (coupure aux espaces) ; rend le nombre de lignes }
Function WrapCount(S : String; W : LongInt) : LongInt;
Var N, K, L : LongInt;
Begin
  N := 0;
  L := MaxI(8, W Div 8);
  While S <> '' Do
  Begin
    K := L;
    If Length(S) > K Then
    Begin
      While (K > 1) And (S[K] <> ' ') Do Dec(K);
      If K <= 1 Then K := L;
    End;
    Delete(S, 1, K);
    Inc(N);
  End;
  If N = 0 Then N := 1;
  WrapCount := N;
End;

Procedure WrapPaint(X, Y, W : LongInt; S : String; Fg, Bg, YMin, YMax : LongInt);
Var K, L : LongInt;
Begin
  L := MaxI(8, W Div 8);
  While S <> '' Do
  Begin
    K := L;
    If Length(S) > K Then
    Begin
      While (K > 1) And (S[K] <> ' ') Do Dec(K);
      If K <= 1 Then K := L;
    End;
    If (Y >= YMin) And (Y + 16 <= YMax) Then OutTxt(X, Y, Trim(Copy(S, 1, K)), Fg, Bg);
    Delete(S, 1, K);
    Y := Y + ClueRowH;
  End;
End;

{ disposition des definitions (ClueRowItem : -1 titre horizontal, -2 titre vertical) }
Procedure ClueLayout;
Var Dir, N, I, Y, W : LongInt;
Begin
  NClueRows := 0; Y := 4;
  W := PnW - 56;
  For Dir := DirAcross To DirDown Do
  Begin
    If NClueRows < MaxClueRows Then
    Begin
      ClueRowItem[NClueRows] := -Dir; ClueRowY[NClueRows] := Y;
      Inc(NClueRows);
    End;
    Y := Y + 22;
    For N := 1 To MaxNum Do
      For I := 1 To DCount Do
        If DItems[I].Placed And (DItems[I].Dir = Dir) And (DItems[I].Num = N) And (NClueRows < MaxClueRows) Then
        Begin
          ClueRowItem[NClueRows] := I; ClueRowY[NClueRows] := Y;
          Inc(NClueRows);
          Y := Y + WrapCount(ClueText(I), W) * ClueRowH + 2;
        End;
    Y := Y + 8;
  End;
  ClueTotalH := Y;
End;

{ texte affiche : la police de PM n'a pas les lettres accentuees de CP850
  au-dela de 175 (A grave, E circonflexe...) : lettre de base a l'ecran }
Function DispStr(S : String) : String;
Var K, U : LongInt; D : String;
Begin
  For K := 1 To Length(S) Do
    If Ord(S[K]) >= 176 Then
    Begin
      U := U850[Ord(S[K])];
      If (U >= 192) And (U <= 255) And (U <> 215) And (U <> 247) Then
      Begin
        D := '';
        MapUni(D, U);
        If D <> '' Then
        Begin
          If U >= 224 Then S[K] := Chr(Ord(D[1]) + 32) Else S[K] := D[1];
        End;
      End;
    End;
  DispStr := S;
End;

Procedure PaintClues;
Var K, I, Y, Yt, Yb, Fg, Bg, W, CwI : LongInt; S : String;
Begin
  Yt := PanelY0 + 2; Yb := PanelY1 - 2;
  FBar(PnX + 2, Yt, CW - 3 - ScrW, Yb, cWhite);
  If Not Generated Or (BPlaced = 0) Then
  Begin
    OutTxt(PnX + 10, Yt + 8, 'Aucune grille.', cGray, cWhite);
    PaintVScroll(CW - 2 - ScrW, Yt, Yb, 0, 0, 1);
    Exit;
  End;
  ClueLayout;
  If PanTop > MaxI(0, ClueTotalH - (Yb - Yt)) Then PanTop := MaxI(0, ClueTotalH - (Yb - Yt));
  W := PnW - 56;
  CwI := CurWord;
  For K := 0 To NClueRows - 1 Do
  Begin
    Y := Yt + ClueRowY[K] - PanTop;
    If Y > Yb Then Break;
    I := ClueRowItem[K];
    If I < 0 Then
    Begin
      If (Y >= Yt) And (Y + 18 <= Yb) Then
      Begin
        If I = -DirAcross Then S := Tx(8) Else S := Tx(9);
        OutTxt(PnX + 8, Y + 2, S, cNavy, cWhite);
        HLine(PnX + 8, CW - 8 - ScrW, Y + 19, cNavy);
      End;
      Continue;
    End;
    If (I = CwI) And Not ShowSolution Then
    Begin
      Bg := cNavy; Fg := cWhite;
      FBar(PnX + 4, MaxI(Yt, Y - 1), CW - 5 - ScrW,
           MinI(Yb, Y + WrapCount(ClueText(I), W) * ClueRowH), cNavy);
    End
    Else
    Begin
      Bg := cWhite; Fg := cBlack;
    End;
    If (Y >= Yt) And (Y + 16 <= Yb) Then OutTxt(PnX + 8, Y, PadL(IStr(DItems[I].Num), 3) + '.', Fg, Bg);
    WrapPaint(PnX + 48, Y, W, DispStr(ClueText(I)), Fg, Bg, Yt, Yb);
  End;
  PaintVScroll(CW - 2 - ScrW, Yt, Yb, PanTop, MaxI(0, ClueTotalH - (Yb - Yt)), Yb - Yt);
End;

{ etat d'un mot de la liste : 0 non utilise (longueur), 1 place, 2 non place }
Function SrcState(K : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  For I := 1 To DCount Do
    If DItems[I].Src = K Then
    Begin
      If DItems[I].Placed Then R := 1 Else R := 2;
      Break;
    End;
  SrcState := R;
End;

Function WordRows : LongInt;
Begin
  WordRows := MaxI(1, (PanelY1 - PanelY0 - 6) Div WordRowH);
End;

Procedure PanelButton(X, W : LongInt; S : String; Dis : Boolean);
Var Y : LongInt;
Begin
  Y := Y1 - BtnH - 2;
  FBar(X, Y, X + W - 1, Y + BtnH - 1, cSilver);
  Box(X, Y, X + W - 1, Y + BtnH - 1, cBlack);
  Edge(X + 1, Y + 1, X + W - 2, Y + BtnH - 2, cWhite, cGray);
  If Dis Then OutTxt(X + (W - Length(S) * 8) Div 2, Y + 7, S, cGray, cSilver)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + 7, S, cBlack, cSilver);
End;

Procedure PaintWords;
Var K, Y, Yt, Yb, St, Fg, Bg, R, Bw : LongInt; S : String;
Begin
  Yt := PanelY0 + 2; Yb := PanelY1 - 2;
  FBar(PnX + 2, Yt, CW - 3 - ScrW, Yb, cWhite);
  R := WordRows;
  If WordTop > MaxI(0, NSrc - R) Then WordTop := MaxI(0, NSrc - R);
  If NSrc = 0 Then OutTxt(PnX + 10, Yt + 8, 'Liste vide.', cGray, cWhite);
  For K := WordTop + 1 To NSrc Do
  Begin
    Y := Yt + 2 + (K - WordTop - 1) * WordRowH;
    If Y + WordRowH > Yb Then Break;
    If K = WordSel Then
    Begin
      Bg := cNavy; Fg := cWhite;
    End
    Else
    Begin
      Bg := cWhite; Fg := cBlack;
    End;
    FBar(PnX + 22, Y, CW - 5 - ScrW, Y + WordRowH - 1, Bg);
    St := 0;
    If Generated Then St := SrcState(K);
    If Generated Then
    Begin
      If St = 1 Then
      Begin
        Thick(PnX + 6, Y + 8, PnX + 9, Y + 11, cDGreen); Thick(PnX + 9, Y + 11, PnX + 15, Y + 4, cDGreen);
      End
      Else If St = 2 Then
      Begin
        Thick(PnX + 6, Y + 4, PnX + 14, Y + 12, cRed); Thick(PnX + 14, Y + 4, PnX + 6, Y + 12, cRed);
      End
      Else HLine(PnX + 6, PnX + 14, Y + 8, cGray);
    End;
    S := SrcW[K];
    If SrcC[K] <> '' Then S := S + ' - ' + SrcC[K];
    If (St = 0) And Generated And (K <> WordSel) Then Fg := cGray;
    OutTxt(PnX + 26, Y + 1, Fit(DispStr(S), CW - 34 - ScrW - PnX), Fg, Bg);
  End;
  PaintVScroll(CW - 2 - ScrW, Yt, Yb, WordTop, MaxI(0, NSrc - R), R);
  FBar(PnX, Yb + 1, CW - 1, Y1, cSilver);
  Bw := (PnW - 24) Div 3;
  PanelButton(PnX + 6, Bw, 'Ajouter...', False);
  PanelButton(PnX + 12 + Bw, Bw, 'Modifier...', WordSel = 0);
  PanelButton(PnX + 18 + 2 * Bw, Bw, 'Supprimer', WordSel = 0);
End;

Procedure PaintPanel;
Var W : LongInt;
Begin
  FBar(PnX, Y0, CW - 1, Y0 + TabH - 1, cSilver);
  VLine(PnX, Y0, Y1, cGray); VLine(PnX + 1, Y0, Y1, cWhite);
  HLine(PnX, CW - 1, Y0 + TabH - 1, cGray);
  W := (PnW - 8) Div 2;
  Tab(PnX + 4, W, 'D'#130'finitions', PanTab = 0);
  Tab(PnX + 4 + W, W, 'Mots (' + IStr(NSrc) + ')', PanTab = 1);
  Sunken(PnX + 1, PanelY0, CW - 2, PanelY1, cWhite);
  If PanTab = 0 Then PaintClues Else PaintWords;
End;

{ ==================================================================== }
{ Barre d'etat                                                          }
{ ==================================================================== }

Function StatsText : String;
Var S : String;
Begin
  S := '';
  If Generated Then
  Begin
    S := 'Mots plac'#130's : ' + IStr(BPlaced) + '/' + IStr(DCount);
    If DSkipped > 0 Then S := S + ' (ignor'#130's : ' + IStr(DSkipped) + ')';
    If BPlaced > 0 Then
      S := S + ' - grille ' + IStr(VX1 - VX0 + 1) + ' x ' + IStr(VY1 - VY0 + 1) + ' - croisements : ' + IStr(BCross) +
           ' - densit'#130' : ' + IStr(Density) + ' %';
    S := S + ' - graine : ' + IStr(LastSeed);
  End;
  StatsText := S;
End;

Procedure PaintStatus;
Var X : LongInt; S : String;
Begin
  Raised(0, CH - SbH, CW - 1, CH - 1);
  S := StatsText;
  If S = '' Then S := IStr(NSrc) + ' mot(s) dans la liste';
  X := CW - 12 - Length(S) * 8;
  If X < CW Div 3 Then
  Begin
    S := Fit(S, CW - CW Div 3 - 12);
    X := CW - 12 - Length(S) * 8;
  End;
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
  If (UX1 < PnX) And (UY2 >= Y0) And (UY1 <= Y1) Then PaintPage;
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
  Sizes : Array[1..NSizes] Of LongInt;

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
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('G'#130'n'#130'rateur de mots crois'#130's'), 0,
                         MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure MsgErr(S : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('G'#130'n'#130'rateur de mots crois'#130's'), 0,
                         MB_OK Or MB_ERROR Or MB_MOVEABLE);
End;

Function Ask3(S : String) : LongInt;
Begin
  Ask3 := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('G'#130'n'#130'rateur de mots crois'#130's'), 0,
                        MB_YESNOCANCEL Or MB_QUERY Or MB_MOVEABLE);
End;

Function AskYes(S : String) : Boolean;
Begin
  AskYes := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('G'#130'n'#130'rateur de mots crois'#130's'), 0,
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

Function SizeName(K : LongInt) : String;
Begin
  SizeName := IStr(Sizes[K]) + ' x ' + IStr(Sizes[K]);
End;

Procedure BuildMenu;
Var H0, H1, H2, K : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 80, '~Fichier');
  H1 := MenuOpen;
  It(cmNew, '~Nouvelle liste (liste int'#130'gr'#130'e)' + #9 + 'Ctrl+N');
  It(cmOpen, '~Ouvrir une liste de mots...' + #9 + 'Ctrl+O');
  It(cmSaveList, '~Enregistrer la liste' + #9 + 'Ctrl+S');
  It(cmSaveListAs, 'Enregistrer la liste ~sous...');
  Sep;
  It(cmExport, 'E~xporter la grille...' + #9 + 'Ctrl+E');
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 89, 'Exporter ~rapidement');
  H2 := MenuOpen;
  It(cmExportTxt, '~Texte (.TXT)');
  It(cmExportHtml, '~Page Web (.HTM)');
  It(cmExportCsv, '~CSV (.CSV)');
  MenuClose(H2);
  It(cmCopyText, 'Co~pier la grille (texte)' + #9 + 'Ctrl+C');
  Sep;
  It(cmQuit, '~Quitter' + #9 + 'Alt+F4');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 81, '~Mots');
  H1 := MenuOpen;
  It(cmAddWords, '~Ajouter des mots...' + #9 + 'Ins');
  It(cmAddWord, 'Ajouter ~un mot et son indice...');
  It(cmEditWord, '~Modifier le mot...' + #9 + 'Entr'#130'e');
  It(cmDelWord, '~Supprimer le mot' + #9 + 'Suppr');
  It(cmClearWords, '~Vider la liste');
  Sep;
  It(cmBuiltIn, 'Liste ~int'#130'gr'#130'e (dans la langue choisie)');
  Sep;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 88, '~Encodage des fichiers de mots');
  H2 := MenuOpen;
  ItA(cmEncAuto, Chk(OptEnc = encAuto), '~Automatique (UTF-8 ou Latin-1)');
  ItA(cmEnc437, Chk(OptEnc = encCp437), 'CP~437 (DOS)');
  ItA(cmEnc850, Chk(OptEnc = encCp850), 'CP~850 (OS/2)');
  MenuClose(H2);
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 82, '~Grille');
  H1 := MenuOpen;
  It(cmGenerate, '~R'#130'g'#130'n'#130'rer (nouvelle graine)' + #9 + 'F5');
  It(cmSameSeed, 'R'#130'g'#130'n'#130'rer avec la ~m'#136'me graine' + #9 + 'Maj+F5');
  Sep;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 87, '~Taille');
  H2 := MenuOpen;
  For K := 1 To NSizes Do ItA(cmSizeFirst + K, Chk((OptW = Sizes[K]) And (OptH = Sizes[K])), SizeName(K));
  Sep;
  It(cmSizeCustom, '~Personnalis'#130'e...');
  MenuClose(H2);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 86, '~Ordre des mots');
  H2 := MenuOpen;
  ItA(cmOrdL, Chk(OptOrder = 'L'), '~Longs d''abord');
  ItA(cmOrdS, Chk(OptOrder = 'S'), '~Courts d''abord');
  ItA(cmOrdR, Chk(OptOrder = 'R'), '~Al'#130'atoire');
  ItA(cmOrdA, Chk(OptOrder = 'A'), 'Ordre de la ~liste');
  MenuClose(H2);
  ItA(cmFull, Chk(OptFull), 'Garder ~toute la grille (sans rogner)');
  Sep;
  It(cmParams, '~Param'#138'tres de g'#130'n'#130'ration...' + #9 + 'F6');
  It(cmSeed, '~Graine...');
  Sep;
  It(cmLog, '~D'#130'tail des essais...');
  It(cmStats, '~Statistiques...');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 83, '~Affichage');
  H1 := MenuOpen;
  ItA(cmShowFill, Chk(Not ShowSolution), 'Grille '#133' ~remplir');
  ItA(cmShowSol, Chk(ShowSolution), '~Solution' + #9 + 'F9');
  Sep;
  ItA(cmNumbers, Chk(ShowNums), '~Num'#130'ros des cases');
  ItA(cmLower, Chk(OptLower), 'Lettres en ~minuscules');
  Sep;
  ItA(cmTabClues, Chk(PanTab = 0), '~D'#130'finitions');
  ItA(cmTabWords, Chk(PanTab = 1), 'Liste des ~mots');
  Sep;
  ItA(cmToolbar, Chk(ShowToolbar), '~Barre d''outils');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 84, '~Jeu');
  H1 := MenuOpen;
  It(cmCheck, '~V'#130'rifier mes r'#130'ponses' + #9 + 'F8');
  It(cmRevealLetter, 'R'#130'v'#130'ler la ~lettre');
  It(cmRevealWord, 'R'#130'v'#130'ler le ~mot');
  It(cmClearAns, '~Effacer mes r'#130'ponses');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 85, '~Options');
  H1 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 90, '~Langue des grilles');
  H2 := MenuOpen;
  ItA(cmLangFR, Chk(Lang = 0), '~Fran'#135'ais');
  ItA(cmLangEN, Chk(Lang = 1), '~English');
  ItA(cmLangGR, Chk(Lang = 2), '~Deutsch');
  ItA(cmLangSP, Chk(Lang = 3), 'E~spa'#164'ol');
  ItA(cmLangIT, Chk(Lang = 4), '~Italiano');
  MenuClose(H2);
  ItA(cmSummary, Chk(OptSummary), '~R'#130'sum'#130' apr'#138's chaque g'#130'n'#130'ration');
  ItA(cmNeedAll, Chk(OptNeedAll), '~Avertir si des mots ne sont pas plac'#130's');
  Sep;
  It(cmExpOpts, 'Options d''~exportation...');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 91, '~?');
  H1 := MenuOpen;
  It(cmHelp, '~Aide' + #9 + 'F1');
  It(cmOpts, '~Options de CROSSGEN (ligne de commande)');
  Sep;
  It(cmAbout, '~A propos...');
  MenuClose(H1);
  MenuClose(H0);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

{ remet les coches des menus a jour }
Procedure SyncMenu;
Var K : LongInt;
Begin
  SetCheck(cmEncAuto, OptEnc = encAuto); SetCheck(cmEnc437, OptEnc = encCp437); SetCheck(cmEnc850, OptEnc = encCp850);
  For K := 1 To NSizes Do SetCheck(cmSizeFirst + K, (OptW = Sizes[K]) And (OptH = Sizes[K]));
  SetCheck(cmOrdL, OptOrder = 'L'); SetCheck(cmOrdS, OptOrder = 'S'); SetCheck(cmOrdR, OptOrder = 'R');
  SetCheck(cmOrdA, OptOrder = 'A'); SetCheck(cmFull, OptFull);
  SetCheck(cmShowFill, Not ShowSolution); SetCheck(cmShowSol, ShowSolution);
  SetCheck(cmNumbers, ShowNums); SetCheck(cmLower, OptLower);
  SetCheck(cmTabClues, PanTab = 0); SetCheck(cmTabWords, PanTab = 1); SetCheck(cmToolbar, ShowToolbar);
  SetCheck(cmLangFR, Lang = 0); SetCheck(cmLangEN, Lang = 1); SetCheck(cmLangGR, Lang = 2);
  SetCheck(cmLangSP, Lang = 3); SetCheck(cmLangIT, Lang = 4);
  SetCheck(cmSummary, OptSummary); SetCheck(cmNeedAll, OptNeedAll);
End;

Procedure ShowPopup(X, Y : LongInt);
Begin
  If CtxMenu <> 0 Then Dummy := WinDestroyWindow(CtxMenu);
  CtxMenu := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuT));
  If CtxMenu <> 0 Then Dummy := WinPopupMenu(Client, Client, CtxMenu, X, CH - 1 - Y, 0, 0);
End;

{ ==================================================================== }
{ Barre d'outils                                                        }
{ ==================================================================== }

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
  TbAdd(cmNew, 1, '', 'Nouvelle liste : la liste int'#130'gr'#130'e (Ctrl+N)');
  TbAdd(cmOpen, 2, '', 'Ouvrir une liste de mots (Ctrl+O)');
  TbAdd(cmSaveList, 3, '', 'Enregistrer la liste de mots (Ctrl+S)');
  TbAdd(cmExport, 4, '', 'Exporter la grille : texte, page Web ou CSV (Ctrl+E)');
  TbAdd(0, 0, '', '');
  TbAdd(cmGenerate, 5, 'G'#130'n'#130'rer', 'R'#130'g'#130'n'#130'rer la grille, nouvelle graine (F5)');
  TbAdd(cmSameSeed, 6, '', 'R'#130'g'#130'n'#130'rer avec la m'#136'me graine (Maj+F5)');
  TbAdd(0, 0, '', '');
  TbAdd(cmToggleSol, 7, 'Solution', 'Afficher ou cacher la solution (F9)');
  TbAdd(cmCheck, 8, '', 'V'#130'rifier mes r'#130'ponses (F8)');
  TbAdd(cmClearAns, 12, '', 'Effacer mes r'#130'ponses');
  TbAdd(0, 0, '', '');
  TbAdd(cmAddWords, 9, '', 'Ajouter des mots (Ins)');
  TbAdd(cmParams, 10, '', 'Param'#138'tres de g'#130'n'#130'ration (F6)');
  TbAdd(0, 0, '', '');
  TbAdd(cmHelp, 11, '', 'Aide (F1)');
End;

{ ==================================================================== }
{ Generation et jeu                                                     }
{ ==================================================================== }

Procedure SetTitle;
Var S : String;
Begin
  If ListName <> '' Then S := NameOf(ListName) Else S := 'Liste int'#130'gr'#130'e';
  If ListMod Then S := S + ' *';
  S := S + ' - G'#130'n'#130'rateur de mots crois'#130's';
  Dummy := WinSetWindowText(Frame, Z(S));
End;

Procedure ClearAnswers;
Var X, Y : LongInt;
Begin
  For Y := 1 To MaxH Do
    For X := 1 To MaxW Do
    Begin
      UCells[Y, X] := ' '; UBad[Y, X] := False;
    End;
  Checked := False;
End;

{ curseur au debut du premier mot }
Procedure CursorHome;
Var I, Best : LongInt;
Begin
  CurX := 0; CurY := 0; CurDir := DirAcross;
  Best := 0;
  For I := 1 To DCount Do
    If DItems[I].Placed Then
      If (Best = 0) Or (DItems[I].Num < DItems[Best].Num) Or ((DItems[I].Num = DItems[Best].Num) And
         (DItems[I].Dir = DirAcross)) Then Best := I;
  If Best > 0 Then
  Begin
    CurX := DItems[Best].X; CurY := DItems[Best].Y; CurDir := DItems[Best].Dir;
  End;
End;

Procedure Summary;
Var S, N : String;
Begin
  S := StatsText;
  N := NotPlaced;
  If N <> '' Then S := S + #10#10 + 'Mots non plac'#130's : ' + N;
  Msg(S);
End;

Procedure DoGenerate(Same : Boolean);
Var Keep, KeepHas : LongInt; H : Boolean;
Begin
  If NSrc = 0 Then
  Begin
    MsgErr('La liste de mots est vide : Mots - Ajouter des mots, ou Fichier - Ouvrir une liste de mots.');
    Exit;
  End;
  If OptLenMin > OptLenMax Then
  Begin
    MsgErr('La longueur minimale d'#130'passe la longueur maximale (Grille - Param'#138'tres).');
    Exit;
  End;
  Keep := OptSeed; H := OptHasSeed;
  If Same And Generated Then
  Begin
    OptSeed := LastSeed; OptHasSeed := True;
  End;
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 3, 0));
  StatusMsg := 'G'#130'n'#130'ration (' + IStr(OptTries) + ' essais)...';
  InvalStatus;
  Dummy := WinUpdateWindow(Client);
  Generate;
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 1, 0));
  OptSeed := Keep; OptHasSeed := H;
  KeepHas := 0;
  ClearAnswers;
  CursorHome;
  PanTop := 0;
  If BPlaced = 0 Then StatusMsg := 'Aucun mot plac'#130' : agrandissez la grille ou changez les longueurs.'
  Else StatusMsg := 'Grille g'#130'n'#130'r'#130'e : cliquez une case et tapez les lettres, F8 pour v'#130'rifier.';
  Layout;
  Redraw;
  If OptVerbose Then ShowBuf('D'#130'tail des essais', LogB);
  If OptSummary Then Summary
  Else If OptNeedAll And (BPlaced < DCount) Then
    MsgErr(IStr(DCount - BPlaced) + ' mot(s) n''ont pas pu '#136'tre plac'#130's : ' + NotPlaced);
End;

Procedure CheckAnswers;
Var X, Y, Bad, Empty, Total : LongInt;
Begin
  If Not Generated Or (BPlaced = 0) Then Exit;
  Bad := 0; Empty := 0; Total := 0;
  For Y := VY0 To VY1 Do
    For X := VX0 To VX1 Do
      If GCells[Y, X] <> ' ' Then
      Begin
        Inc(Total);
        UBad[Y, X] := (UCells[Y, X] <> ' ') And (UCells[Y, X] <> GCells[Y, X]);
        If UBad[Y, X] Then Inc(Bad);
        If UCells[Y, X] = ' ' Then Inc(Empty);
      End;
  Checked := True;
  ShowSolution := False;
  SyncMenu;
  Redraw;
  If (Bad = 0) And (Empty = 0) Then Msg('Bravo ! La grille est compl'#138'te et juste.')
  Else
  Begin
    StatusMsg := IStr(Bad) + ' lettre(s) fausse(s) (en rouge), ' + IStr(Empty) + ' case(s) vide(s) sur ' + IStr(Total) + '.';
    InvalStatus;
  End;
End;

Procedure Reveal(All : Boolean);
Var I, L, K, X, Y : LongInt;
Begin
  If (CurX = 0) Or ShowSolution Then Exit;
  If Not All Then
  Begin
    UCells[CurY, CurX] := GCells[CurY, CurX]; UBad[CurY, CurX] := False;
  End
  Else
  Begin
    I := CurWord;
    If I = 0 Then Exit;
    L := Length(DItems[I].Txt);
    X := DItems[I].X; Y := DItems[I].Y;
    For K := 1 To L Do
    Begin
      UCells[Y, X] := GCells[Y, X]; UBad[Y, X] := False;
      If DItems[I].Dir = DirAcross Then Inc(X) Else Inc(Y);
    End;
  End;
  InvalGrid;
End;

{ deplacement du curseur d'une case (dans une case de lettre) }
Procedure MoveCur(Dx, Dy : LongInt);
Var X, Y : LongInt;
Begin
  If CurX = 0 Then
  Begin
    CursorHome;
    InvalGrid;
    Exit;
  End;
  X := CurX; Y := CurY;
  Repeat
    X := X + Dx; Y := Y + Dy;
  Until (X < VX0) Or (X > VX1) Or (Y < VY0) Or (Y > VY1) Or (GCells[Y, X] <> ' ');
  If (X >= VX0) And (X <= VX1) And (Y >= VY0) And (Y <= VY1) Then
  Begin
    CurX := X; CurY := Y;
    If Dx <> 0 Then
    Begin
      If WordAt(X, Y, DirAcross) > 0 Then CurDir := DirAcross;
    End
    Else If WordAt(X, Y, DirDown) > 0 Then CurDir := DirDown;
  End;
  InvalGrid;
  InvalPanel;
End;

{ mot suivant ou precedent (ordre des definitions) }
Procedure NextWord(Back : Boolean);
Var K, I, Best, Key, BestKey, CurKey : LongInt;
Begin
  I := CurWord;
  CurKey := 0;
  If I > 0 Then CurKey := DItems[I].Dir * 1000 + DItems[I].Num;
  Best := 0; BestKey := 0;
  For K := 1 To DCount Do
    If DItems[K].Placed Then
    Begin
      Key := DItems[K].Dir * 1000 + DItems[K].Num;
      If Back Then
      Begin
        If (Key < CurKey) And ((Best = 0) Or (Key > BestKey)) Then
        Begin
          Best := K; BestKey := Key;
        End;
      End
      Else If (Key > CurKey) And ((Best = 0) Or (Key < BestKey)) Then
      Begin
        Best := K; BestKey := Key;
      End;
    End;
  If Best = 0 Then
  Begin
    CursorHome;
    InvalGrid; InvalPanel;
    Exit;
  End;
  CurX := DItems[Best].X; CurY := DItems[Best].Y; CurDir := DItems[Best].Dir;
  InvalGrid;
  InvalPanel;
End;

{ lettre tapee dans la grille }
Procedure TypeLetter(Ch : Char);
Var X, Y : LongInt;
Begin
  If (CurX = 0) Or ShowSolution Or Not Generated Then Exit;
  UCells[CurY, CurX] := Ch; UBad[CurY, CurX] := False;
  X := CurX; Y := CurY;
  If CurDir = DirAcross Then Inc(X) Else Inc(Y);
  If (X <= VX1) And (Y <= VY1) Then
    If GCells[Y, X] <> ' ' Then
    Begin
      CurX := X; CurY := Y;
    End;
  InvalGrid;
End;

Procedure BackLetter;
Var X, Y : LongInt;
Begin
  If (CurX = 0) Or ShowSolution Then Exit;
  If UCells[CurY, CurX] <> ' ' Then UCells[CurY, CurX] := ' '
  Else
  Begin
    X := CurX; Y := CurY;
    If CurDir = DirAcross Then Dec(X) Else Dec(Y);
    If (X >= VX0) And (Y >= VY0) Then
      If GCells[Y, X] <> ' ' Then
      Begin
        CurX := X; CurY := Y;
        UCells[Y, X] := ' ';
      End;
  End;
  UBad[CurY, CurX] := False;
  InvalGrid;
End;

{ ==================================================================== }
{ Fichiers, mots, exportation                                           }
{ ==================================================================== }

Function CanWriteDir(D : String) : Boolean;
Var T, S : String;
Begin
  T := JoinPath(D, 'CGTEST.TMP');
  S := 'x';
  CanWriteDir := WriteAll(T, @S[1], 1) And FExists(T);
  Dummy := DosDelete(Z(T));
End;

{ fichiers d'un repertoire selon un modele (noms separes par des espaces) }
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

Function CanDiscard : Boolean;
Var R : LongInt;
Begin
  CanDiscard := True;
  If Not ListMod Then Exit;
  R := Ask3('La liste de mots a '#130't'#130' modifi'#130'e. L''enregistrer ?');
  If R = MBID_CANCEL Then CanDiscard := False
  Else If R = MBID_YES Then
  Begin
    DlgReset;
    If ListName = '' Then DlgEdit('Fichier de la liste :', JoinPath(WorkDir, 'MOTS.TXT'))
    Else DlgEdit('Fichier de la liste :', ListName);
    If Not DlgRun('Enregistrer la liste de mots', 'Enregistrer') Then
    Begin
      CanDiscard := False;
      Exit;
    End;
    If Not SaveList(FullName(DfVal[0])) Then
    Begin
      MsgErr('Impossible d''enregistrer ' + FullName(DfVal[0]) + '.');
      CanDiscard := False;
    End;
  End;
End;

Procedure AfterListChange;
Begin
  If WordSel > NSrc Then WordSel := NSrc;
  ListMod := True;
  SetTitle;
  InvalPanel;
  InvalStatus;
End;

Procedure OpenDlg;
Var L, F : String;
Begin
  If Not CanDiscard Then Exit;
  DlgReset;
  L := ListFiles(WorkDir, '*.TXT') + ListFiles(WorkDir, '*.LST');
  If L = '' Then L := ' (aucun)';
  DlgLabel(Fit('Listes de ' + WorkDir + ' :' + L, 590));
  F := ListName;
  If F = '' Then F := JoinPath(WorkDir, 'MOTS.TXT');
  DlgEdit('Fichier de mots (MOT;indice) :', F);
  DlgCombo('Encodage du fichier :', 'Automatique (UTF-8 ou Latin-1)|CP437 (DOS)|CP850 (OS/2)', OptEnc);
  DlgCheck('G'#130'n'#130'rer la grille apr'#138's le chargement', True);
  If Not DlgRun('Ouvrir une liste de mots', 'Ouvrir') Then Exit;
  OptEnc := DlgInt(2);
  F := FullName(DfVal[1]);
  If F = '' Then Exit;
  If Not LoadList(F) Then
  Begin
    MsgErr('Fichier introuvable : ' + F);
    Exit;
  End;
  Generated := False; WordSel := 0; WordTop := 0;
  SyncMenu;
  SetTitle;
  StatusMsg := IStr(NSrc) + ' mot(s) lu(s) dans ' + F + '.';
  If DlgBool(3) Then DoGenerate(False) Else
  Begin
    Layout;
    Redraw;
  End;
End;

Procedure SaveListAs(Ask : Boolean);
Var F : String;
Begin
  F := ListName;
  If Ask Or (F = '') Then
  Begin
    DlgReset;
    If F = '' Then F := JoinPath(WorkDir, 'MOTS.TXT');
    DlgEdit('Fichier de la liste (MOT;indice) :', F);
    If Not DlgRun('Enregistrer la liste de mots', 'Enregistrer') Then Exit;
    F := FullName(DfVal[0]);
  End;
  If F = '' Then Exit;
  If SaveList(F) Then StatusMsg := 'Liste enregistr'#130'e : ' + F + ' (' + IStr(NSrc) + ' mots).'
  Else MsgErr('Impossible d''enregistrer ' + F + '.');
  SetTitle;
  InvalStatus;
End;

Procedure AddWordsDlg;
Var N : LongInt;
Begin
  DlgReset;
  DlgLabel('MOT ou MOT=indice, s'#130'par'#130's par des virgules (comme /E de CROSSGEN) :');
  DlgEdit('Mots :', '');
  DlgCheck('R'#130'g'#130'n'#130'rer la grille', True);
  If Not DlgRun('Ajouter des mots', 'Ajouter') Then Exit;
  N := SrcAddInline(DfVal[1]);
  StatusMsg := IStr(N) + ' mot(s) ajout'#130'(s).';
  AfterListChange;
  If (N > 0) And DlgBool(2) Then DoGenerate(False);
End;

Procedure WordDlg(K : LongInt);
Var W, C : String;
Begin
  DlgReset;
  If K > 0 Then
  Begin
    DlgEdit('Mot :', SrcW[K]);
    DlgEdit('Indice (d'#130'finition) :', SrcC[K]);
  End
  Else
  Begin
    DlgEdit('Mot :', '');
    DlgEdit('Indice (d'#130'finition) :', '');
  End;
  If K > 0 Then
  Begin
    If Not DlgRun('Modifier le mot', 'OK') Then Exit;
  End
  Else If Not DlgRun('Ajouter un mot', 'Ajouter') Then Exit;
  W := Trim(DfVal[0]); C := Trim(DfVal[1]);
  If W = '' Then Exit;
  If Normalize(W) = '' Then
  Begin
    MsgErr('Le mot doit contenir des lettres ou des chiffres.');
    Exit;
  End;
  If K > 0 Then
  Begin
    SrcW[K] := Copy(W, 1, 80); SrcC[K] := Copy(C, 1, 80);
  End
  Else If SrcAdd(W, C) Then WordSel := NSrc
  Else
  Begin
    MsgErr('La liste est pleine (' + IStr(MaxSrc) + ' mots).');
    Exit;
  End;
  AfterListChange;
End;

Procedure DelWord;
Begin
  If (WordSel < 1) Or (WordSel > NSrc) Then Exit;
  SrcDel(WordSel);
  AfterListChange;
End;

Function FmtExt(F : Char) : String;
Begin
  If F = 'H' Then FmtExt := 'HTM' Else If F = 'C' Then FmtExt := 'CSV' Else FmtExt := 'TXT';
End;

Function FmtIndex(F : Char) : LongInt;
Begin
  If F = 'H' Then FmtIndex := 1 Else If F = 'C' Then FmtIndex := 2 Else FmtIndex := 0;
End;

Function ExportTo(F : String) : Boolean;
Begin
  BuildOutput;
  ExportTo := WriteAll(F, OutB.P, OutB.Len);
End;

{ options d'exportation (Withfile : avec le nom et le format du fichier) }
Function ExportDlg(WithFile : Boolean) : Boolean;
Var B, E, F : String; I : LongInt;
Begin
  ExportDlg := False;
  DlgReset;
  If ExportName = '' Then ExportName := JoinPath(WorkDir, 'GRILLE.' + FmtExt(OptFmt));
  If WithFile Then
  Begin
    DlgEdit('Fichier :', ExportName);
    DlgCombo('Format (/FMT) :', 'Texte (.TXT)|Page Web (.HTM)|CSV (.CSV)', FmtIndex(OptFmt));
  End;
  DlgCheck('Grille '#133' remplir (sans /NOGRID)', Not OptNoGrid);
  DlgCheck('Liste des d'#130'finitions (sans /NOCLUE)', Not OptNoClue);
  DlgCheck('Grille solution aussi (/A)', OptShowSol);
  DlgCheck('Solution seulement (/SOLONLY)', OptSolOnly);
  DlgCheck('Caract'#138'res graphiques DOS dans le texte (/G)', OptGraphic);
  DlgCheck('Lettres en minuscules (/LC)', OptLower);
  DlgCheck('Texte et CSV en UTF-8 (sinon CP850)', OptUtf8Out);
  B := OptBlockCh; E := OptEmptyCh;
  If E = ' ' Then E := '';
  If (Not OptBlockSet) And OptGraphic Then B := '';
  DlgEdit('Cases noires (/BLOCK) :', B);
  DlgEdit('Cases vides (/EMPTY, rien : espace) :', E);
  If WithFile Then
  Begin
    If Not DlgRun('Exporter la grille', 'Exporter') Then Exit;
  End
  Else If Not DlgRun('Options d''exportation', 'OK') Then Exit;
  I := 0;
  If WithFile Then
  Begin
    ExportName := FullName(DfVal[0]);
    Case DlgInt(1) Of
      1 : OptFmt := 'H';
      2 : OptFmt := 'C';
    Else
      OptFmt := 'T';
    End;
    If ExtOf(ExportName) = '' Then ExportName := ExportName + '.' + FmtExt(OptFmt);
    I := 2;
  End;
  OptNoGrid := Not DlgBool(I); OptNoClue := Not DlgBool(I + 1); OptShowSol := DlgBool(I + 2);
  OptSolOnly := DlgBool(I + 3); OptGraphic := DlgBool(I + 4); OptLower := DlgBool(I + 5); OptUtf8Out := DlgBool(I + 6);
  B := DfVal[I + 7]; E := DfVal[I + 8];
  If B <> '' Then
  Begin
    OptBlockCh := B[1]; OptBlockSet := True;
  End
  Else
  Begin
    OptBlockCh := '#'; OptBlockSet := False;
  End;
  If E = '' Then OptEmptyCh := ' ' Else OptEmptyCh := E[1];
  SyncMenu;
  Redraw;
  ExportDlg := True;
End;

Procedure DoExport;
Begin
  If Not Generated Or (BPlaced = 0) Then Exit;
  If Not ExportDlg(True) Then Exit;
  If ExportTo(ExportName) Then StatusMsg := 'Grille export'#130'e : ' + ExportName
  Else MsgErr('Impossible d'''#130'crire ' + ExportName + '.');
  InvalStatus;
End;

Procedure QuickExport(F : Char);
Begin
  If Not Generated Or (BPlaced = 0) Then Exit;
  DlgReset;
  DlgEdit('Fichier :', JoinPath(WorkDir, 'GRILLE.' + FmtExt(F)));
  If Not DlgRun('Exporter la grille', 'Exporter') Then Exit;
  OptFmt := F;
  ExportName := FullName(DfVal[0]);
  If ExportTo(ExportName) Then StatusMsg := 'Grille export'#130'e : ' + ExportName
  Else MsgErr('Impossible d'''#130'crire ' + ExportName + '.');
  InvalStatus;
End;

{ la grille en texte dans le presse-papiers de PM }
Procedure CopyText;
Var Keep : Char; T : PBytes; N : LongInt;
Begin
  If Not Generated Or (BPlaced = 0) Then Exit;
  Keep := OptFmt;
  OptFmt := 'T';
  BuildOutput;
  OptFmt := Keep;
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

Procedure ParamsDlg;
Var N : String; V : LongInt; Ok : Boolean;
Begin
  DlgReset;
  DlgEdit('Largeur de la grille, 5 '#133' 60 (/W) :', IStr(OptW));
  DlgEdit('Hauteur de la grille, 5 '#133' 60 (/HEIGHT) :', IStr(OptH));
  If OptMaxPlace >= MaxWords Then N := '' Else N := IStr(OptMaxPlace);
  DlgEdit('Mots plac'#130's au plus (/N, rien : tous) :', N);
  DlgEdit('Longueur minimale d''un mot (/MIN) :', IStr(OptLenMin));
  DlgEdit('Longueur maximale d''un mot (/MAX) :', IStr(OptLenMax));
  DlgEdit('Nombre d''essais (/T) :', IStr(OptTries));
  DlgCombo('Croisements minimum par mot (/I) :', '0 (mots isol'#130's permis)|1|2|3|4', OptMinCross);
  Case OptOrder Of
    'S' : V := 1;
    'R' : V := 2;
    'A' : V := 3;
  Else
    V := 0;
  End;
  DlgCombo('Ordre des mots (/ORDER) :', 'Longs d''abord|Courts d''abord|Al'#130'atoire|Ordre de la liste', V);
  If OptHasSeed Then N := IStr(OptSeed) Else N := '';
  DlgEdit('Graine fixe (/S, rien : hasard) :', N);
  DlgCheck('Garder toute la grille, sans rogner les bords vides (/FULL)', OptFull);
  DlgCheck('Avertir si des mots ne sont pas plac'#130's (/ALL)', OptNeedAll);
  DlgCheck('Afficher le d'#130'tail des essais apr'#138's la g'#130'n'#130'ration (/V)', OptVerbose);
  DlgCheck('R'#130'g'#130'n'#130'rer maintenant', True);
  If Not DlgRun('Param'#138'tres de g'#130'n'#130'ration', 'OK') Then Exit;
  Ok := ParseNum(DfVal[0], 5, MaxW, OptW) And ParseNum(DfVal[1], 5, MaxH, OptH);
  If Trim(DfVal[2]) = '' Then OptMaxPlace := MaxWords Else Ok := ParseNum(DfVal[2], 1, MaxWords, OptMaxPlace) And Ok;
  Ok := ParseNum(DfVal[3], 1, WordMax, OptLenMin) And Ok;
  Ok := ParseNum(DfVal[4], 1, WordMax, OptLenMax) And Ok;
  Ok := ParseNum(DfVal[5], 1, 10000, OptTries) And Ok;
  OptMinCross := DlgInt(6);
  Case DlgInt(7) Of
    1 : OptOrder := 'S';
    2 : OptOrder := 'R';
    3 : OptOrder := 'A';
  Else
    OptOrder := 'L';
  End;
  If Trim(DfVal[8]) = '' Then OptHasSeed := False
  Else If ParseNum(DfVal[8], 0, 2147483647, OptSeed) Then OptHasSeed := True
  Else Ok := False;
  OptFull := DlgBool(9); OptNeedAll := DlgBool(10); OptVerbose := DlgBool(11);
  SyncMenu;
  If Not Ok Then MsgErr('Certaines valeurs sont hors limites ; elles n''ont pas '#130't'#130' chang'#130'es.');
  If DlgBool(12) Then DoGenerate(False)
  Else
  Begin
    RefreshView;
    Layout;
    Redraw;
  End;
End;

Procedure SizeDlg;
Var Ok : Boolean;
Begin
  DlgReset;
  DlgEdit('Largeur, 5 '#133' 60 :', IStr(OptW));
  DlgEdit('Hauteur, 5 '#133' 60 :', IStr(OptH));
  If Not DlgRun('Taille de la grille', 'OK') Then Exit;
  Ok := ParseNum(DfVal[0], 5, MaxW, OptW) And ParseNum(DfVal[1], 5, MaxH, OptH);
  If Not Ok Then MsgErr('Taille hors limites (5 '#133' 60).');
  SyncMenu;
  DoGenerate(False);
End;

Procedure SeedDlg;
Begin
  DlgReset;
  DlgLabel('Graine de la derni'#138're grille : ' + IStr(LastSeed) + ' (la m'#136'me graine donne la m'#136'me grille).');
  If OptHasSeed Then DlgEdit('Graine (vide : au hasard) :', IStr(OptSeed)) Else DlgEdit('Graine (vide : au hasard) :', '');
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

Procedure ShowHelp(Which : LongInt);
Var B : TBuf;
Begin
  BufInit(B);
  If Which = 0 Then
  Begin
    BufAdd(B, 'G'#130'n'#130'rateur de mots crois'#130's : une liste de mots (un par ligne, avec un indice facultatif : ');
    BufAdd(B, 'MOT;indice) devient une grille. Plusieurs essais sont faits et la meilleure grille est gard'#130'e ');
    BufAdd(B, '(le plus de mots plac'#130's, puis de croisements, puis la plus petite surface).'#10#10);
    BufAdd(B, 'F5 : r'#130'g'#130'n'#130'rer ; Maj+F5 : m'#136'me graine ; F6 : param'#138'tres ; F9 : solution ; ');
    BufAdd(B, 'F8 : v'#130'rifier ; Ctrl+O : ouvrir une liste ; Ctrl+E : exporter (texte, page Web, CSV).'#10#10);
    BufAdd(B, 'Jouer : cliquez une case et tapez les lettres ; un second clic, ou Espace, change le sens ; ');
    BufAdd(B, 'Tab : mot suivant ; fl'#138'ches : d'#130'placer ; Retour arri'#138're : effacer. Un clic sur une ');
    BufAdd(B, 'd'#130'finition m'#138'ne au mot.'#10#10);
    BufAdd(B, 'Onglet Mots : la liste, avec un crochet vert pour les mots plac'#130's, un X rouge pour les autres ');
    BufAdd(B, 'et un trait pour ceux que la longueur ou la taille de la grille '#130'carte ; Ajouter, Modifier, ');
    BufAdd(B, 'Supprimer (aussi Ins, Entr'#130'e, Suppr).'#10#10);
    BufAdd(B, 'Accents : les mots sont mis en majuscules sans accents (UTF-8, Latin-1, CP437 ou CP850).');
    ShowBuf('Aide du G'#130'n'#130'rateur de mots crois'#130's', B);
  End
  Else
  Begin
    BufAdd(B, 'CROSSGEN [fichier [mot ...]] [options], comme la commande du d'#130'p'#244't VIE :'#10);
    BufAdd(B, '/F:fichier  /E:m1,m2=indice  /W:n  /HEIGHT:n  /SIZE:LxH  /N:n  /MIN:n  /MAX:n  /T:n  /S:n'#10);
    BufAdd(B, '/ORDER:L|S|R|A  /I:n  /FULL  /A  /SOLONLY  /NOGRID  /NOCLUE  /FMT:TXT|HTML|CSV  /OUT:fichier'#10);
    BufAdd(B, '/G  /BLOCK:c  /EMPTY:c  /LC  /CP437 (et /CP850)  /UTF8  /ALL  /LANG:FR|EN|GR|SP|IT  /V  /Q'#10#10);
    BufAdd(B, 'Avec /OUT:fichier, la grille est g'#130'n'#130'r'#130'e et '#130'crite sans ouvrir de fen'#136'tre ');
    BufAdd(B, '(code de sortie 4 avec /ALL si des mots ne sont pas plac'#130's). Sans /OUT, la fen'#136'tre ');
    BufAdd(B, 's''ouvre avec ces options.'#10#10);
    BufAdd(B, 'Dans la fen'#136'tre : /F = Fichier - Ouvrir ; /E = Mots - Ajouter des mots ; /W /HEIGHT /SIZE = ');
    BufAdd(B, 'Grille - Taille ; /N /MIN /MAX /T /S /I /ORDER /FULL /ALL /V = Grille - Param'#138'tres ; ');
    BufAdd(B, '/A /SOLONLY /NOGRID /NOCLUE /FMT /OUT /G /BLOCK /EMPTY /LC = Fichier - Exporter ; ');
    BufAdd(B, '/CP437 = Mots - Encodage ; /LANG = Options - Langue ; /Q = Options - R'#130'sum'#130'.');
    ShowBuf('Options de CROSSGEN', B);
  End;
  BufFree(B);
End;

Procedure SetLangCmd(L : LongInt);
Begin
  Lang := L;
  SyncMenu;
  { la liste integree suit la langue tant qu'elle n'a pas ete modifiee }
  If (ListName = '') And Not ListMod Then
  Begin
    LoadBuiltIn;
    DoGenerate(False);
  End
  Else Redraw;
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Procedure DoCmd(C : LongInt);
Begin
  If (C > cmSizeFirst) And (C <= cmSizeFirst + NSizes) Then
  Begin
    OptW := Sizes[C - cmSizeFirst]; OptH := OptW;
    SyncMenu;
    DoGenerate(False);
    Exit;
  End;
  Case C Of
    cmNew :
      If CanDiscard Then
      Begin
        LoadBuiltIn;
        WordSel := 0; WordTop := 0;
        SetTitle;
        DoGenerate(False);
      End;
    cmOpen : OpenDlg;
    cmSaveList : SaveListAs(False);
    cmSaveListAs : SaveListAs(True);
    cmExport : DoExport;
    cmExportTxt : QuickExport('T');
    cmExportHtml : QuickExport('H');
    cmExportCsv : QuickExport('C');
    cmCopyText : CopyText;
    cmQuit : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    cmAddWords : AddWordsDlg;
    cmAddWord :
      Begin
        PanTab := 1; SyncMenu;
        WordDlg(0);
      End;
    cmEditWord : If WordSel > 0 Then WordDlg(WordSel);
    cmDelWord : DelWord;
    cmClearWords :
      If (NSrc > 0) And AskYes('Vider la liste de ' + IStr(NSrc) + ' mot(s) ?') Then
      Begin
        NSrc := 0; WordSel := 0; WordTop := 0; Generated := False;
        AfterListChange;
        Layout;
        Redraw;
      End;
    cmBuiltIn :
      If CanDiscard Then
      Begin
        LoadBuiltIn;
        SetTitle;
        DoGenerate(False);
      End;
    cmEncAuto, cmEnc437, cmEnc850 :
      Begin
        OptEnc := C - cmEncAuto;
        SyncMenu;
        StatusMsg := 'Encodage pour la prochaine liste ouverte.';
        InvalStatus;
      End;
    cmGenerate : DoGenerate(False);
    cmSameSeed : DoGenerate(True);
    cmParams : ParamsDlg;
    cmSeed : SeedDlg;
    cmSizeCustom : SizeDlg;
    cmFull :
      Begin
        OptFull := Not OptFull;
        SyncMenu;
        RefreshView;
        Layout;
        Redraw;
      End;
    cmOrdL, cmOrdS, cmOrdR, cmOrdA :
      Begin
        Case C Of
          cmOrdL : OptOrder := 'L';
          cmOrdS : OptOrder := 'S';
          cmOrdR : OptOrder := 'R';
        Else
          OptOrder := 'A';
        End;
        SyncMenu;
        DoGenerate(False);
      End;
    cmLog : If Generated Then ShowBuf('D'#130'tail des essais (graine ' + IStr(LastSeed) + ')', LogB);
    cmStats : If Generated Then Summary;
    cmShowFill, cmShowSol, cmToggleSol :
      Begin
        If C = cmShowFill Then ShowSolution := False
        Else If C = cmShowSol Then ShowSolution := True
        Else ShowSolution := Not ShowSolution;
        SyncMenu;
        Redraw;
      End;
    cmNumbers : Begin ShowNums := Not ShowNums; SyncMenu; InvalGrid; End;
    cmLower : Begin OptLower := Not OptLower; SyncMenu; InvalGrid; End;
    cmTabClues, cmTabWords :
      Begin
        PanTab := C - cmTabClues;
        SyncMenu;
        InvalPanel;
      End;
    cmToolbar :
      Begin
        ShowToolbar := Not ShowToolbar;
        SyncMenu;
        Layout;
        Redraw;
      End;
    cmCheck : CheckAnswers;
    cmClearAns :
      Begin
        ClearAnswers;
        StatusMsg := 'R'#130'ponses effac'#130'es.';
        Redraw;
      End;
    cmRevealLetter : Reveal(False);
    cmRevealWord : Reveal(True);
    cmLangFR, cmLangEN, cmLangGR, cmLangSP, cmLangIT : SetLangCmd(C - cmLangFR);
    cmSummary : Begin OptSummary := Not OptSummary; SyncMenu; End;
    cmNeedAll : Begin OptNeedAll := Not OptNeedAll; SyncMenu; End;
    cmExpOpts : If ExportDlg(False) Then ;
    cmHelp : ShowHelp(0);
    cmOpts : ShowHelp(1);
    cmAbout :
      Msg('G'#130'n'#130'rateur de mots crois'#130's pour OS/2-0' + #10#10 +
          'Interface de CROSSGEN ' + VersionStr + ' (d'#130'p'#244't VIE de Gladir.com) avec les menus et l''apparence ' +
          'd''OS/2.' + #10#10 + 'Gladir.com');
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

Procedure GridDown(X, Y : LongInt);
Var Cx, Cy : LongInt;
Begin
  If Not Generated Or (BPlaced = 0) Then Exit;
  If (X < GX0) Or (Y < GY0) Then Exit;
  Cx := VX0 + (X - GX0) Div Cs; Cy := VY0 + (Y - GY0) Div Cs;
  If (Cx > VX1) Or (Cy > VY1) Then Exit;
  If GCells[Cy, Cx] = ' ' Then Exit;
  If (Cx = CurX) And (Cy = CurY) Then
  Begin
    If WordAt(Cx, Cy, 3 - CurDir) > 0 Then CurDir := 3 - CurDir;
  End
  Else
  Begin
    CurX := Cx; CurY := Cy;
    If WordAt(Cx, Cy, CurDir) = 0 Then CurDir := 3 - CurDir;
  End;
  If ShowSolution Then
  Begin
    ShowSolution := False;
    SyncMenu;
  End;
  InvalGrid;
  InvalPanel;
End;

Procedure PanelDown(X, Y : LongInt; Dbl : Boolean);
Var W, K, I, Yt, Bw : LongInt;
Begin
  If Y < Y0 + TabH Then
  Begin
    W := (PnW - 8) Div 2;
    If X < PnX + 4 + W Then PanTab := 0 Else PanTab := 1;
    SyncMenu;
    InvalPanel;
    Exit;
  End;
  If X >= CW - 2 - ScrW Then
  Begin
    { barre de defilement : moitie haute ou basse }
    If PanTab = 0 Then
    Begin
      If Y < (PanelY0 + PanelY1) Div 2 Then PanTop := MaxI(0, PanTop - 120) Else PanTop := PanTop + 120;
    End
    Else If Y < (PanelY0 + PanelY1) Div 2 Then WordTop := MaxI(0, WordTop - WordRows + 1)
    Else WordTop := WordTop + WordRows - 1;
    InvalPanel;
    Exit;
  End;
  If PanTab = 0 Then
  Begin
    If Not Generated Then Exit;
    ClueLayout;
    Yt := PanelY0 + 2 - PanTop;
    I := 0;
    For K := 0 To NClueRows - 1 Do
      If (ClueRowItem[K] > 0) And (Y >= Yt + ClueRowY[K] - 1) Then I := ClueRowItem[K];
    If I > 0 Then
    Begin
      CurX := DItems[I].X; CurY := DItems[I].Y; CurDir := DItems[I].Dir;
      If ShowSolution Then
      Begin
        ShowSolution := False;
        SyncMenu;
      End;
      InvalGrid;
      InvalPanel;
    End;
    Exit;
  End;
  { onglet Mots }
  If Y >= PanelY1 Then
  Begin
    Bw := (PnW - 24) Div 3;
    If (X >= PnX + 6) And (X < PnX + 6 + Bw) Then WordDlg(0)
    Else If (X >= PnX + 12 + Bw) And (X < PnX + 12 + 2 * Bw) Then
    Begin
      If WordSel > 0 Then WordDlg(WordSel);
    End
    Else If (X >= PnX + 18 + 2 * Bw) And (X < PnX + 18 + 3 * Bw) Then DelWord;
    Exit;
  End;
  K := WordTop + 1 + (Y - PanelY0 - 4) Div WordRowH;
  If (K >= 1) And (K <= NSrc) Then
  Begin
    WordSel := K;
    InvalPanel;
    If Dbl Then WordDlg(K);
  End;
End;

Procedure MouseDown(X, Y : LongInt; Dbl : Boolean);
Begin
  If ShowToolbar And (Y < TbH) Then
  Begin
    ToolbarDown(X);
    Exit;
  End;
  If Y >= CH - SbH Then Exit;
  If X >= PnX Then PanelDown(X, Y, Dbl) Else GridDown(X, Y);
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
  MenuLen := 0;
  H := MenuOpen;
  If (X >= PnX) And (PanTab = 1) Then
  Begin
    PanelDown(X, Y, False);
    It(cmAddWord, '~Ajouter un mot...');
    It(cmAddWords, 'Ajouter ~des mots...');
    It(cmEditWord, '~Modifier le mot...');
    It(cmDelWord, '~Supprimer le mot');
    Sep;
    It(cmGenerate, '~R'#130'g'#130'n'#130'rer' + #9 + 'F5');
  End
  Else
  Begin
    If X < PnX Then GridDown(X, Y);
    It(cmCheck, '~V'#130'rifier mes r'#130'ponses' + #9 + 'F8');
    It(cmRevealLetter, 'R'#130'v'#130'ler la ~lettre');
    It(cmRevealWord, 'R'#130'v'#130'ler le ~mot');
    It(cmClearAns, '~Effacer mes r'#130'ponses');
    Sep;
    It(cmToggleSol, 'Afficher ou cacher la ~solution' + #9 + 'F9');
    It(cmGenerate, '~R'#130'g'#130'n'#130'rer' + #9 + 'F5');
    It(cmExport, 'E~xporter...' + #9 + 'Ctrl+E');
  End;
  MenuClose(H);
  ShowPopup(X, Y);
End;

{ ==================================================================== }
{ Clavier                                                               }
{ ==================================================================== }

Function Key(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch_, Vk, K : LongInt; Ctrl, Shift : Boolean; S : String;
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
      VK_F5 :
        Begin
          If Shift Then DoCmd(cmSameSeed) Else DoCmd(cmGenerate);
          Exit;
        End;
      VK_F6 : Begin DoCmd(cmParams); Exit; End;
      VK_F8 : Begin DoCmd(cmCheck); Exit; End;
      VK_F9 : Begin DoCmd(cmToggleSol); Exit; End;
      VK_INSERT : Begin DoCmd(cmAddWords); Exit; End;
      VK_DELETE :
        Begin
          If PanTab = 1 Then DelWord
          Else If (CurX > 0) And Not ShowSolution Then
          Begin
            UCells[CurY, CurX] := ' ';
            InvalGrid;
          End;
          Exit;
        End;
      VK_ENTER, VK_NEWLINE :
        Begin
          If (PanTab = 1) And (WordSel > 0) Then WordDlg(WordSel);
          Exit;
        End;
      VK_UP, VK_DOWN :
        Begin
          If PanTab = 1 Then
          Begin
            If Vk = VK_UP Then WordSel := MaxI(1, WordSel - 1) Else WordSel := MinI(NSrc, WordSel + 1);
            If WordSel < WordTop + 1 Then WordTop := WordSel - 1;
            If WordSel > WordTop + WordRows Then WordTop := WordSel - WordRows;
            InvalPanel;
          End
          Else If Vk = VK_UP Then MoveCur(0, -1) Else MoveCur(0, 1);
          Exit;
        End;
      VK_LEFT : Begin MoveCur(-1, 0); Exit; End;
      VK_RIGHT : Begin MoveCur(1, 0); Exit; End;
      VK_TAB : Begin NextWord(Shift); Exit; End;
      VK_BACKTAB : Begin NextWord(True); Exit; End;
      VK_BACKSPACE : Begin BackLetter; Exit; End;
    End;
  End;
  If Ctrl And (Ch_ > 0) And (Ch_ < 128) Then
  Begin
    K := Ch_;
    If (K >= 1) And (K <= 26) Then K := K + 96;
    If (K >= 65) And (K <= 90) Then K := K + 32;
    Case K Of
      Ord('n') : Begin DoCmd(cmNew); Exit; End;
      Ord('o') : Begin DoCmd(cmOpen); Exit; End;
      Ord('s') : Begin DoCmd(cmSaveList); Exit; End;
      Ord('e') : Begin DoCmd(cmExport); Exit; End;
      Ord('c') : Begin DoCmd(cmCopyText); Exit; End;
    End;
  End;
  If ((Fl And KC_CHAR) <> 0) And Not Ctrl And ((Fl And KC_ALT) = 0) And (Ch_ >= 32) Then
  Begin
    If Ch_ = 32 Then
    Begin
      { espace : changer de sens }
      If (CurX > 0) And (WordAt(CurX, CurY, 3 - CurDir) > 0) Then CurDir := 3 - CurDir;
      InvalGrid;
      InvalPanel;
      Exit;
    End;
    S := Normalize(Chr(Ch_));
    If S <> '' Then
    Begin
      TypeLetter(S[1]);
      Exit;
    End;
  End;
  Key := False;
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

Function ClientProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; X, Y, K : LongInt;
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
        MouseDown(X, Y, Msg_ = WM_BUTTON1DBLCLK);
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
    WM_VSCROLL :
      Begin
        K := 0;
        If Hi16(Mp2) = SB_LINEUP Then K := -1 Else If Hi16(Mp2) = SB_LINEDOWN Then K := 1;
        If LastMx >= PnX Then
        Begin
          If PanTab = 0 Then PanTop := MaxI(0, PanTop + K * 48) Else WordTop := MaxI(0, WordTop + K * 3);
          InvalPanel;
        End;
      End;
    WM_CHAR :
      If Key(Mp1, Mp2) Then ClientProc := 1
      Else ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
    WM_COMMAND : DoCmd(Lo16(Mp1));
    WM_CLOSE :
      If CanDiscard Then Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

{ /OUT : generer et ecrire sans fenetre (comme la commande CROSSGEN) }
Procedure Batch;
Var H : LongInt;
Begin
  If NSrc = 0 Then Halt(3);
  Generate;
  BuildOutput;
  If Not WriteAll(CliOut, OutB.P, OutB.Len) Then Halt(2);
  If OptNeedAll And (BPlaced < DCount) Then Halt(4);
  H := 0;
End;

Procedure Main;
Var Fl, Sw, Sh, Fw, Fh, K : LongInt; Err : String;
Begin
  InitDefaults;
  SetLang(EnvStr('LANGUAGE'));
  BufInit(LogB); BufInit(OutB);
  Sizes[1] := 9; Sizes[2] := 11; Sizes[3] := 13; Sizes[4] := 15; Sizes[5] := 17; Sizes[6] := 19; Sizes[7] := 21;
  Sizes[8] := 25;
  ShowSolution := False; ShowNums := True; ShowToolbar := True; OptSummary := False;
  PanTab := 0; PanTop := 0; WordSel := 0; WordTop := 0; CtxMenu := 0; Drag := dNone;
  StatusMsg := 'Pr'#136't.'; SavedMsg := ''; ExportName := '';
  CurX := 0; CurY := 0; CurDir := DirAcross;
  ClearAnswers;
  ParseArgs;
  Err := CliErr;
  { la liste : fichier, mots en parametres (/E), sinon la liste integree }
  If CliFile <> '' Then
  Begin
    K := NSrc;
    If Not LoadList(CliFile) Then
    Begin
      If CliOut <> '' Then Halt(2);
      If Err = '' Then Err := 'Fichier introuvable : ' + CliFile;
      NSrc := 0;
    End;
  End;
  If (CliFile = '') And Not CliInline Then LoadBuiltIn;
  If CliOut <> '' Then
  Begin
    If Err <> '' Then Halt(1);
    Batch;
    Exit;
  End;
  OptSummary := False;
  { repertoire des fichiers : C:\, ou D:\ quand C: est en lecture seule }
  WorkDir := 'C:\';
  If Not CanWriteDir(WorkDir) Then
    If CanWriteDir('D:\') Then WorkDir := 'D:\';
  ToolbarInit;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('CROSSGEN'), LongInt(@ClientProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('CROSSGEN'), Z2('G'#130'n'#130'rateur de mots crois'#130's'),
                              0, 0, 0, LongInt(@Client));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Fw := MinI(Sw, 640); Fh := MinI(Sh - 20, 460);
  If Sw >= 1000 Then
  Begin
    Fw := 960; Fh := MinI(Sh - 40, 700);
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
  If Err <> '' Then MsgErr(Err);
  If NSrc > 0 Then DoGenerate(False);
  While WinGetMsg(Hab, LongInt(@GQmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@GQmsg));
  Dummy := WinDestroyWindow(Frame);
End;

BEGIN
  Main;
END.
