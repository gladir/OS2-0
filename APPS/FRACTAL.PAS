{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: FRACTAL - Generateur de Fractal pour le Presentation
                Manager d'OS/2-0.
}

Program Fractal;

{$R-,S-,I-}

(* Compilation : OS2PC FRACTAL.PAS FRACTAL.EXE

  Generateur de Fractal (dossier Loisirs du bureau), avec les menus et
  l'apparence d'OS/2 :

    - a gauche, la liste des fractales predefinies (avec une miniature) :
      Mandelbrot, Julia, Burning Ship, Tricorne, Multibrot, Newton,
      Phoenix, fougere de Barnsley, triangle et tapis de Sierpinski,
      courbe du dragon, courbe de Levy, flocon de Koch, courbe de
      Hilbert, arbre fractal, arbre de Pythagore, attracteurs de Lorenz
      et de Clifford ;
    - au centre, l'apercu de la fractale, calcule par etapes (un apercu
      grossier, puis l'image precise) ; un clic agrandit, un rectangle
      trace a la souris devient la vue, le bouton 2 ouvre un menu (dont
      l'ensemble de Julia du point clique) ;
    - a droite, les proprietes de la fractale choisie (vue, iterations,
      rayon, puissance, constante c, points, profondeur, angle, palette,
      coloration...), modifiables une a une ou dans une boite de dialogue ;
    - barre d'outils : nouveau, ouvrir, enregistrer, exporter (BMP),
      generer, arreter, zoom, vue initiale, axes, couleurs animees,
      proprietes, aide.

  L'image est en 256 couleurs : changer de palette, la decaler ou
  l'animer ne refait pas le calcul.

  Parametres : [fichier.FRC] [/F:fractale] [/BMP:fichier] [/W:largeur]
  [/H:hauteur] [/ITER:n] [/PAL:n] ; avec /BMP, l'image est calculee et
  ecrite sans fenetre. *)

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
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
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
{ Moteur : fractales, proprietes, palettes, calcul par etapes           }
{ ==================================================================== }

Const
  AppTitle = 'G'#130'n'#130'rateur de Fractal';
  { fractales }
  NFrac = 18;
  ftMandel = 0; ftJulia = 1; ftShip = 2; ftTricorn = 3; ftMulti = 4; ftNewton = 5; ftPhoenix = 6;
  ftFern = 7; ftSierTri = 8; ftCarpet = 9; ftDragon = 10; ftLevy = 11;
  ftKoch = 12; ftHilbert = 13; ftTree = 14; ftPythag = 15;
  ftLorenz = 16; ftClifford = 17;
  { familles }
  fmEscape = 0; fmIfs = 1; fmLines = 2; fmAttr = 3;
  { proprietes }
  NProp = 28;
  pCx = 0; pCy = 1; pWidth = 2; pIter = 3; pBail = 4; pPower = 5; pCRe = 6; pCIm = 7; pPhx = 8;
  pColMode = 9; pDensity = 10; pPal = 11; pShift = 12; pRev = 13; pBack = 14; pPoints = 15; pPtCol = 16;
  pDepth = 17; pAngle = 18; pRatio = 19; pRot = 20; pA = 21; pB = 22; pC = 23; pD = 24; pThick = 25;
  pLineCol = 26; pRelax = 27;
  { genres de proprietes }
  pkFloat = 0; pkInt = 1; pkEnum = 2; pkBool = 3;
  NPal = 8;
  MaxImgW = 1280; MaxImgH = 1024;

Type
  TProps = Array[0..NProp - 1] Of Double;

Var
  Vals : Array[0..NFrac - 1] Of TProps;     { valeurs de chaque fractale (modifiees) }
  CV : TProps;                              { valeurs du calcul en cours }
  FType : LongInt;                          { fractale du calcul }
  { liste des proprietes de la fractale : NPL, PL }
  NPL : LongInt;
  PL : Array[0..19] Of LongInt;
  { image : 8 bits, lignes de bas en haut (comme une BITMAP d'OS/2) }
  RBuf : PBytes;
  RW, RH, RStride : LongInt;
  RCnt : PLongs;                            { nombre de points par pixel (IFS, attracteurs) }
  CntCap : LongInt;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte; { en-tete et palette de l'image }
  Pal : Array[0..255] Of LongInt;           { couleurs RGB }
  LnTab : Array[0..4095] Of Double;
  { tache de calcul }
  JobOn, JobDone : Boolean;
  JobPass, JobRow, JobStepPx, JobTotal, JobPos, JobT0, JobMs, JobMaxCnt, JobConvT : LongInt;
  JobPx, JobPy, JobPz : Double;
  JobInside, JobIterSum, JobPixels : LongInt;
  { constantes du calcul }
  EIter, EPow, EColMode : LongInt;
  JobCoarse, AllowCoarse : Boolean;
  PKs : Array[0..7] Of LongInt;
  EDens, EB2, ECre, ECim, EPhx, ELnPow, ERelax, EScale, EX0, EY0 : Double;
  { IFS }
  NMap : LongInt;
  IfA, IfB, IfC, IfD, IfE, IfF, IfP : Array[0..7] Of Double;
  RSeed : LongInt;
  OutB : TBuf;
  SegN, SegTotal : LongInt;

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

{ --- reels : lecture et ecriture (point ou virgule, exposant E) --- }

Function ParseF(S : String; Var V : Double) : Boolean;
Var K, E, Es : LongInt; R, F : Double; Neg, Dig, Ok : Boolean;
Begin
  ParseF := False;
  S := Trim(S);
  If S = '' Then Exit;
  K := 1; Neg := False;
  If (S[1] = '-') Or (S[1] = '+') Then
  Begin
    Neg := S[1] = '-';
    K := 2;
  End;
  R := 0; Dig := False;
  While (K <= Length(S)) And (S[K] >= '0') And (S[K] <= '9') Do
  Begin
    R := R * 10 + (Ord(S[K]) - 48); Dig := True; Inc(K);
  End;
  If (K <= Length(S)) And ((S[K] = '.') Or (S[K] = ',')) Then
  Begin
    Inc(K);
    F := 0.1;
    While (K <= Length(S)) And (S[K] >= '0') And (S[K] <= '9') Do
    Begin
      R := R + (Ord(S[K]) - 48) * F; F := F / 10; Dig := True; Inc(K);
    End;
  End;
  If Not Dig Then Exit;
  Ok := True;
  If (K <= Length(S)) And ((S[K] = 'E') Or (S[K] = 'e')) Then
  Begin
    Inc(K);
    Es := 1;
    If (K <= Length(S)) And ((S[K] = '-') Or (S[K] = '+')) Then
    Begin
      If S[K] = '-' Then Es := -1;
      Inc(K);
    End;
    E := 0; Ok := False;
    While (K <= Length(S)) And (S[K] >= '0') And (S[K] <= '9') Do
    Begin
      E := E * 10 + Ord(S[K]) - 48; Ok := True; Inc(K);
    End;
    If E > 300 Then Ok := False;
    While Ok And (E > 0) Do
    Begin
      If Es > 0 Then R := R * 10 Else R := R / 10;
      Dec(E);
    End;
  End;
  If Not Ok Or (K <= Length(S)) Then Exit;
  If Neg Then R := -R;
  V := R;
  ParseF := True;
End;

{ ecriture d'un reel : Dg chiffres significatifs, zeros inutiles retires }
Function FStr(V : Double; Dg : LongInt) : String;
Var R, Ip : String; E, K, D, Dec_ : LongInt; Neg : Boolean; A, T : Double;
Begin
  R := '';
  Neg := V < 0;
  A := Abs(V);
  If A = 0 Then
  Begin
    FStr := '0';
    Exit;
  End;
  E := 0;
  If (A < 0.0001) Or (A >= 1E9) Then
  Begin
    { notation scientifique }
    While A >= 10 Do Begin A := A / 10; Inc(E); End;
    While A < 1 Do Begin A := A * 10; Dec(E); End;
    T := A;
    R := Chr(48 + Trunc(T));
    T := (T - Trunc(T)) * 10;
    R := R + '.';
    For K := 2 To Dg Do
    Begin
      D := Trunc(T + 1E-9);
      If D > 9 Then D := 9;
      R := R + Chr(48 + D);
      T := (T - D) * 10;
    End;
    While R[Length(R)] = '0' Do Delete(R, Length(R), 1);
    If R[Length(R)] = '.' Then Delete(R, Length(R), 1);
    R := R + 'E' + IStr(E);
  End
  Else
  Begin
    { arrondi a Dg chiffres significatifs }
    K := 0; T := A;
    While T >= 1 Do Begin T := T / 10; Inc(K); End;
    Dec_ := Dg - K;
    If Dec_ < 0 Then Dec_ := 0;
    If Dec_ > 15 Then Dec_ := 15;
    T := 1;
    For D := 1 To Dec_ Do T := T * 10;
    A := Int(A * T + 0.5) / T;
    Ip := IStr(Trunc(A));
    A := A - Trunc(A);
    R := '';
    For D := 1 To Dec_ Do
    Begin
      A := A * 10;
      K := Trunc(A + 1E-7);
      If K > 9 Then K := 9;
      R := R + Chr(48 + K);
      A := A - K;
    End;
    While (Length(R) > 0) And (R[Length(R)] = '0') Do Delete(R, Length(R), 1);
    If R <> '' Then R := Ip + '.' + R Else R := Ip;
  End;
  If Neg Then R := '-' + R;
  FStr := R;
End;

{ --- fractales : noms, familles, cles --- }

Function FracName(T : LongInt) : String;
Var R : String;
Begin
  Case T Of
    ftMandel : R := 'Ensemble de Mandelbrot';
    ftJulia : R := 'Ensemble de Julia';
    ftShip : R := 'Burning Ship';
    ftTricorn : R := 'Tricorne';
    ftMulti : R := 'Multibrot';
    ftNewton : R := 'Newton (z^n = 1)';
    ftPhoenix : R := 'Phoenix';
    ftFern : R := 'Foug'#138're de Barnsley';
    ftSierTri : R := 'Triangle de Sierpinski';
    ftCarpet : R := 'Tapis de Sierpinski';
    ftDragon : R := 'Courbe du dragon';
    ftLevy : R := 'Courbe de L'#130'vy';
    ftKoch : R := 'Flocon de Koch';
    ftHilbert : R := 'Courbe de Hilbert';
    ftTree : R := 'Arbre fractal';
    ftPythag : R := 'Arbre de Pythagore';
    ftLorenz : R := 'Attracteur de Lorenz';
  Else
    R := 'Attracteur de Clifford';
  End;
  FracName := R;
End;

{ nom court (liste de gauche) }
Function ShortName(T : LongInt) : String;
Var R : String;
Begin
  Case T Of
    ftMandel : R := 'Mandelbrot';
    ftJulia : R := 'Julia';
    ftNewton : R := 'Newton';
    ftFern : R := 'Foug'#138're Barnsley';
    ftSierTri : R := 'Triangle Sierpinski';
    ftCarpet : R := 'Tapis Sierpinski';
    ftLorenz : R := 'Lorenz';
    ftClifford : R := 'Clifford';
  Else
    R := FracName(T);
  End;
  ShortName := R;
End;


Function FracKey(T : LongInt) : String;
Var R : String;
Begin
  Case T Of
    ftMandel : R := 'MANDELBROT';
    ftJulia : R := 'JULIA';
    ftShip : R := 'BURNINGSHIP';
    ftTricorn : R := 'TRICORNE';
    ftMulti : R := 'MULTIBROT';
    ftNewton : R := 'NEWTON';
    ftPhoenix : R := 'PHOENIX';
    ftFern : R := 'FOUGERE';
    ftSierTri : R := 'SIERPINSKI';
    ftCarpet : R := 'TAPIS';
    ftDragon : R := 'DRAGON';
    ftLevy : R := 'LEVY';
    ftKoch : R := 'KOCH';
    ftHilbert : R := 'HILBERT';
    ftTree : R := 'ARBRE';
    ftPythag : R := 'PYTHAGORE';
    ftLorenz : R := 'LORENZ';
  Else
    R := 'CLIFFORD';
  End;
  FracKey := R;
End;

Function FamilyOf(T : LongInt) : LongInt;
Begin
  If T <= ftPhoenix Then FamilyOf := fmEscape
  Else If T <= ftLevy Then FamilyOf := fmIfs
  Else If T <= ftPythag Then FamilyOf := fmLines
  Else FamilyOf := fmAttr;
End;

Function FamilyName(F : LongInt) : String;
Var R : String;
Begin
  Case F Of
    fmEscape : R := 'Temps d'''#130'chappement';
    fmIfs : R := 'Fonctions it'#130'r'#130'es (IFS)';
    fmLines : R := 'Courbes et arbres';
  Else
    R := 'Attracteurs '#130'tranges';
  End;
  FamilyName := R;
End;

{ formule ou description courte de la fractale }
Function FracInfo(T : LongInt) : String;
Var R : String;
Begin
  Case T Of
    ftMandel : R := 'z <- z^2 + c, z = 0, c = le point de l''image.';
    ftJulia : R := 'z <- z^2 + c, z = le point, c constant.';
    ftShip : R := 'z <- (|Re z| + i |Im z|)^2 + c.';
    ftTricorn : R := 'z <- conj(z)^2 + c (Mandelbar).';
    ftMulti : R := 'z <- z^d + c, puissance d.';
    ftNewton : R := 'M'#130'thode de Newton sur z^n - 1 : une couleur par racine.';
    ftPhoenix : R := 'z <- z^2 + c + p z(n-1).';
    ftFern : R := '4 transformations affines au hasard (Barnsley, 1988).';
    ftSierTri : R := 'Jeu du chaos : 3 sommets, moiti'#130' du chemin.';
    ftCarpet : R := '8 r'#130'ductions de 1/3 du carr'#130'.';
    ftDragon : R := '2 similitudes de rapport 1/racine(2).';
    ftLevy : R := 'Courbe C de L'#130'vy : 2 similitudes '#133' 45 degr'#130's.';
    ftKoch : R := 'Chaque segment devient 4 segments (angle choisi).';
    ftHilbert : R := 'Courbe qui remplit le carr'#130' (4^n segments).';
    ftTree : R := 'Chaque branche porte deux branches plus courtes.';
    ftPythag : R := 'Deux carr'#130's sur chaque carr'#130', triangle d''angle choisi.';
    ftLorenz : R := 'dx = s(y - x), dy = x(r - z) - y, dz = xy - bz.';
  Else
    R := 'x <- sin(a y) + c cos(a x), y <- sin(b x) + d cos(b y).';
  End;
  FracInfo := R;
End;

{ --- proprietes --- }

Function PropKind(P : LongInt) : LongInt;
Begin
  Case P Of
    pIter, pPower, pShift, pPoints, pDepth, pThick : PropKind := pkInt;
    pColMode, pPal, pBack, pPtCol, pLineCol : PropKind := pkEnum;
    pRev : PropKind := pkBool;
  Else
    PropKind := pkFloat;
  End;
End;

Function PropName(P : LongInt) : String;
Var R : String;
Begin
  Case P Of
    pCx : R := 'Centre X';
    pCy : R := 'Centre Y';
    pWidth : R := 'Largeur visible';
    pIter : R := 'It'#130'rations max.';
    pBail : R := 'Rayon de fuite';
    pPower : R := 'Puissance';
    pCRe : R := 'c (partie r'#130'elle)';
    pCIm : R := 'c (partie imag.)';
    pPhx : R := 'p (Phoenix)';
    pColMode : R := 'Coloration';
    pDensity : R := 'Densit'#130' couleurs';
    pPal : R := 'Palette';
    pShift : R := 'D'#130'calage palette';
    pRev : R := 'Palette invers'#130'e';
    pBack : R := 'Fond / int'#130'rieur';
    pPoints : R := 'Points';
    pPtCol : R := 'Couleur des points';
    pDepth : R := 'Profondeur';
    pAngle : R := 'Angle (degr'#130's)';
    pRatio : R := 'Rapport branches';
    pRot : R := 'Rotation (degr'#130's)';
    pA : R := 'Param'#138'tre a';
    pB : R := 'Param'#138'tre b';
    pC : R := 'Param'#138'tre c';
    pD : R := 'Param'#138'tre d';
    pThick : R := 'Epaisseur traits';
    pLineCol : R := 'Couleur des traits';
  Else
    R := 'Relaxation';
  End;
  PropName := R;
End;

{ nom affiche (Lorenz : sigma, rho, beta) }
Function PropLabel(T, P : LongInt) : String;
Var R : String;
Begin
  R := PropName(P);
  If T = ftLorenz Then
  Begin
    If P = pA Then R := 'Sigma'
    Else If P = pB Then R := 'Rho'
    Else If P = pC Then R := 'B'#136'ta';
  End;
  If (T = ftNewton) And (P = pPower) Then R := 'Degr'#130' n';
  PropLabel := R;
End;

Function PropKey(P : LongInt) : String;
Var R : String;
Begin
  Case P Of
    pCx : R := 'CX';
    pCy : R := 'CY';
    pWidth : R := 'LARGEUR';
    pIter : R := 'ITERATIONS';
    pBail : R := 'RAYON';
    pPower : R := 'PUISSANCE';
    pCRe : R := 'CRE';
    pCIm : R := 'CIM';
    pPhx : R := 'P';
    pColMode : R := 'COLORATION';
    pDensity : R := 'DENSITE';
    pPal : R := 'PALETTE';
    pShift : R := 'DECALAGE';
    pRev : R := 'INVERSE';
    pBack : R := 'FOND';
    pPoints : R := 'POINTS';
    pPtCol : R := 'COULEURPOINTS';
    pDepth : R := 'PROFONDEUR';
    pAngle : R := 'ANGLE';
    pRatio : R := 'RAPPORT';
    pRot : R := 'ROTATION';
    pA : R := 'A';
    pB : R := 'B';
    pC : R := 'C';
    pD : R := 'D';
    pThick : R := 'EPAISSEUR';
    pLineCol : R := 'COULEURTRAITS';
  Else
    R := 'RELAXATION';
  End;
  PropKey := R;
End;

Function PalName(K : LongInt) : String;
Var R : String;
Begin
  Case K Of
    0 : R := 'Classique';
    1 : R := 'Feu';
    2 : R := 'Oc'#130'an';
    3 : R := 'Arc-en-ciel';
    4 : R := 'Electrique';
    5 : R := 'For'#136't';
    6 : R := 'Niveaux de gris';
  Else
    R := 'Pastel';
  End;
  PalName := R;
End;

{ choix d'une propriete a liste ('|' entre les choix) }
Function PropChoices(P : LongInt) : String;
Var R : String; K : LongInt;
Begin
  R := '';
  Case P Of
    pColMode : R := 'Liss'#130'e|Bandes';
    pBack : R := 'Noir|Blanc|Bleu nuit';
    pPtCol : R := 'Densit'#130'|Par transformation|Unie';
    pLineCol : R := 'D'#130'grad'#130' le long du trac'#130'|Unie';
    pPal :
      For K := 0 To NPal - 1 Do
      Begin
        If K > 0 Then R := R + '|';
        R := R + PalName(K);
      End;
  End;
  PropChoices := R;
End;

Function Choice(P, V : LongInt) : String;
Var S, R : String; K, N, St : LongInt;
Begin
  S := PropChoices(P) + '|';
  R := ''; N := 0; St := 1;
  For K := 1 To Length(S) Do
    If S[K] = '|' Then
    Begin
      If N = V Then R := Copy(S, St, K - St);
      Inc(N); St := K + 1;
    End;
  Choice := R;
End;

Procedure PropRange(P : LongInt; Var Lo, Hi : Double);
Begin
  Lo := -1E9; Hi := 1E9;
  Case P Of
    pWidth : Begin Lo := 1E-13; Hi := 1E6; End;
    pIter : Begin Lo := 4; Hi := 100000; End;
    pBail : Begin Lo := 2; Hi := 1E6; End;
    pPower : Begin Lo := 2; Hi := 9; End;
    pDensity : Begin Lo := 0.05; Hi := 64; End;
    pShift : Begin Lo := 0; Hi := 254; End;
    pPoints : Begin Lo := 1000; Hi := 20000000; End;
    pDepth : Begin Lo := 0; Hi := 18; End;
    pAngle : Begin Lo := -180; Hi := 180; End;
    pRatio : Begin Lo := 0.1; Hi := 0.95; End;
    pRot : Begin Lo := -360; Hi := 360; End;
    pThick : Begin Lo := 1; Hi := 6; End;
    pRelax : Begin Lo := 0.1; Hi := 2; End;
    pColMode, pBack, pLineCol : Begin Lo := 0; Hi := 1; End;
    pPtCol : Begin Lo := 0; Hi := 2; End;
    pPal : Begin Lo := 0; Hi := NPal - 1; End;
    pRev : Begin Lo := 0; Hi := 1; End;
  End;
  If P = pBack Then Hi := 2;
End;

{ profondeur maximale selon la fractale (le nombre de traits croit vite) }
Function MaxDepth(T : LongInt) : LongInt;
Begin
  Case T Of
    ftKoch : MaxDepth := 7;
    ftHilbert : MaxDepth := 8;
    ftTree : MaxDepth := 16;
  Else
    MaxDepth := 14;
  End;
End;

Function ValStr(T, P : LongInt; V : Double) : String;
Var R : String;
Begin
  Case PropKind(P) Of
    pkInt : R := IStr(Round(V));
    pkEnum : R := Choice(P, Round(V));
    pkBool : If V <> 0 Then R := 'oui' Else R := 'non';
  Else
    R := FStr(V, 10);
  End;
  If T < 0 Then ;
  ValStr := R;
End;

Procedure AddP(P : LongInt);
Begin
  PL[NPL] := P;
  Inc(NPL);
End;

{ proprietes de la fractale T, dans l'ordre affiche }
Procedure BuildPropList(T : LongInt);
Begin
  NPL := 0;
  AddP(pCx); AddP(pCy); AddP(pWidth);
  Case FamilyOf(T) Of
    fmEscape :
      Begin
        If (T = ftJulia) Or (T = ftPhoenix) Then
        Begin
          AddP(pCRe); AddP(pCIm);
        End;
        If T = ftPhoenix Then AddP(pPhx);
        AddP(pIter);
        If (T = ftMulti) Or (T = ftNewton) Then AddP(pPower);
        If T = ftNewton Then AddP(pRelax) Else
        Begin
          AddP(pBail); AddP(pColMode);
        End;
        AddP(pDensity);
      End;
    fmIfs :
      Begin
        AddP(pPoints); AddP(pPtCol);
      End;
    fmLines :
      Begin
        AddP(pDepth);
        If (T = ftKoch) Or (T = ftTree) Or (T = ftPythag) Then AddP(pAngle);
        If T = ftTree Then AddP(pRatio);
        If T <> ftPythag Then AddP(pThick);
        AddP(pLineCol);
      End;
    fmAttr :
      Begin
        AddP(pA); AddP(pB); AddP(pC);
        If T = ftClifford Then AddP(pD);
        If T = ftLorenz Then AddP(pRot);
        AddP(pPoints);
      End;
  End;
  AddP(pPal); AddP(pShift); AddP(pRev); AddP(pBack);
End;

Function HasProp(T, P : LongInt) : Boolean;
Var K : LongInt; R : Boolean;
Begin
  BuildPropList(T);
  R := False;
  For K := 0 To NPL - 1 Do If PL[K] = P Then R := True;
  HasProp := R;
End;

{ valeurs initiales de la fractale T }
Procedure Preset(T : LongInt);
Var V : TProps; K : LongInt;
Begin
  For K := 0 To NProp - 1 Do V[K] := 0;
  V[pCx] := 0; V[pCy] := 0; V[pWidth] := 3.5; V[pIter] := 256; V[pBail] := 4; V[pPower] := 2;
  V[pDensity] := 4; V[pPal] := 0; V[pShift] := 0; V[pRev] := 0; V[pBack] := 0; V[pColMode] := 0;
  V[pPoints] := 200000; V[pPtCol] := 0; V[pDepth] := 5; V[pAngle] := 60; V[pRatio] := 0.7; V[pThick] := 1;
  V[pLineCol] := 0; V[pRelax] := 1; V[pRot] := 0;
  Case T Of
    ftMandel : Begin V[pCx] := -0.6; V[pWidth] := 3.4; End;
    ftJulia : Begin V[pWidth] := 3.4; V[pCRe] := -0.8; V[pCIm] := 0.156; V[pPal] := 2; End;
    ftShip : Begin V[pCx] := -0.45; V[pCy] := 0.5; V[pWidth] := 3.6; V[pPal] := 1; End;
    ftTricorn : Begin V[pCx] := -0.3; V[pWidth] := 4; V[pPal] := 4; End;
    ftMulti : Begin V[pPower] := 3; V[pWidth] := 3.2; V[pPal] := 3; V[pDensity] := 3; End;
    ftNewton : Begin V[pPower] := 3; V[pWidth] := 3.2; V[pIter] := 40; V[pPal] := 3; V[pDensity] := 6; End;
    ftPhoenix : Begin V[pWidth] := 3.4; V[pCRe] := 0.5667; V[pCIm] := 0; V[pPhx] := -0.5; V[pPal] := 5; End;
    ftFern : Begin V[pCx] := 0.2; V[pCy] := 5; V[pWidth] := 11; V[pPal] := 5; V[pPoints] := 300000; End;
    ftSierTri : Begin V[pCx] := 0.5; V[pCy] := 0.43; V[pWidth] := 1.3; V[pPal] := 3; V[pPtCol] := 1; End;
    ftCarpet : Begin V[pCx] := 0.5; V[pCy] := 0.5; V[pWidth] := 1.2; V[pPal] := 2; V[pPoints] := 400000; End;
    ftDragon : Begin V[pCx] := 0.42; V[pCy] := 0.12; V[pWidth] := 1.9; V[pPal] := 1; V[pPtCol] := 1; End;
    ftLevy : Begin V[pCx] := 0.5; V[pCy] := 0.2; V[pWidth] := 2.4; V[pPal] := 4; End;
    ftKoch : Begin V[pCy] := 0.05; V[pWidth] := 1.5; V[pDepth] := 5; V[pThick] := 2; V[pPal] := 2; V[pBack] := 1; End;
    ftHilbert : Begin V[pCx] := 0.5; V[pCy] := 0.5; V[pWidth] := 1.3; V[pDepth] := 6; V[pPal] := 3; V[pBack] := 1; End;
    ftTree : Begin V[pCy] := 1.6; V[pWidth] := 5; V[pDepth] := 12; V[pAngle] := 25; V[pThick] := 3; V[pPal] := 5; V[pBack] := 1; End;
    ftPythag : Begin V[pCy] := 2.6; V[pWidth] := 7.5; V[pDepth] := 10; V[pAngle] := 45; V[pPal] := 5; V[pBack] := 1; End;
    ftLorenz : Begin V[pCy] := 25; V[pWidth] := 62; V[pA] := 10; V[pB] := 28; V[pC] := 8 / 3; V[pPoints] := 400000; V[pPal] := 1; End;
    ftClifford : Begin V[pWidth] := 5; V[pA] := -1.4; V[pB] := 1.6; V[pC] := 1; V[pD] := 0.7; V[pPoints] := 1000000; V[pPal] := 4; End;
  End;
  Vals[T] := V;
End;

{ --- palettes (256 couleurs : 0 = fond, 1 a 255 = degrade) --- }

Function RGB(R, G, B : LongInt) : LongInt;
Begin
  RGB := (R Shl 16) Or (G Shl 8) Or B;
End;

Procedure PalKeys(K : LongInt; Var N : LongInt);
Begin
  N := 0;
  Case K Of
    0 : Begin PKs[0] := RGB(0, 7, 100); PKs[1] := RGB(32, 107, 203); PKs[2] := RGB(237, 255, 255); PKs[3] := RGB(255, 170, 0); PKs[4] := RGB(0, 2, 0); N := 5; End;
    1 : Begin PKs[0] := RGB(20, 0, 0); PKs[1] := RGB(180, 0, 0); PKs[2] := RGB(255, 120, 0); PKs[3] := RGB(255, 230, 60); PKs[4] := RGB(255, 255, 230); PKs[5] := RGB(255, 140, 0); PKs[6] := RGB(120, 0, 0); N := 7; End;
    2 : Begin PKs[0] := RGB(0, 0, 60); PKs[1] := RGB(0, 60, 160); PKs[2] := RGB(0, 170, 220); PKs[3] := RGB(200, 255, 255); PKs[4] := RGB(0, 120, 200); PKs[5] := RGB(0, 20, 100); N := 6; End;
    3 : Begin PKs[0] := RGB(255, 0, 0); PKs[1] := RGB(255, 160, 0); PKs[2] := RGB(255, 255, 0); PKs[3] := RGB(0, 200, 0); PKs[4] := RGB(0, 160, 255); PKs[5] := RGB(80, 0, 200); PKs[6] := RGB(220, 0, 160); N := 7; End;
    4 : Begin PKs[0] := RGB(10, 0, 30); PKs[1] := RGB(120, 0, 200); PKs[2] := RGB(0, 120, 255); PKs[3] := RGB(0, 255, 255); PKs[4] := RGB(255, 255, 255); PKs[5] := RGB(0, 80, 200); N := 6; End;
    5 : Begin PKs[0] := RGB(0, 40, 0); PKs[1] := RGB(0, 120, 20); PKs[2] := RGB(90, 200, 40); PKs[3] := RGB(220, 240, 120); PKs[4] := RGB(120, 90, 30); PKs[5] := RGB(20, 80, 10); N := 6; End;
    6 : Begin PKs[0] := RGB(0, 0, 0); PKs[1] := RGB(255, 255, 255); N := 2; End;
  Else
    Begin PKs[0] := RGB(255, 180, 200); PKs[1] := RGB(180, 210, 255); PKs[2] := RGB(210, 180, 255); PKs[3] := RGB(255, 240, 180); PKs[4] := RGB(180, 255, 210); N := 5; End;
  End;
End;

{ palette de la fractale (valeurs V) : Pal et la table de Bmi }
Procedure BuildPal(Var V : TProps);
Var N, I, J, K, Sh, C1, C2, R, G, B, A : LongInt; T, F : Double; Cyc : Boolean;
    Grad : Array[0..254] Of LongInt;
Begin
  PalKeys(Round(V[pPal]), N);
  { les palettes sont cycliques (degrade qui revient au debut), sauf les niveaux de gris }
  Cyc := Round(V[pPal]) <> 6;
  For I := 0 To 254 Do
  Begin
    If Cyc Then T := I * N / 255 Else T := I * (N - 1) / 254;
    J := Trunc(T);
    F := T - J;
    C1 := PKs[J Mod N]; C2 := PKs[(J + 1) Mod N];
    If Not Cyc And (J >= N - 1) Then C2 := C1;
    R := Round(((C1 Shr 16) And 255) * (1 - F) + ((C2 Shr 16) And 255) * F);
    G := Round(((C1 Shr 8) And 255) * (1 - F) + ((C2 Shr 8) And 255) * F);
    B := Round((C1 And 255) * (1 - F) + (C2 And 255) * F);
    Grad[I] := RGB(R, G, B);
  End;
  Sh := Round(V[pShift]);
  For I := 0 To 254 Do
  Begin
    K := (I + Sh) Mod 255;
    If V[pRev] <> 0 Then K := 254 - K;
    Pal[I + 1] := Grad[K];
  End;
  Case Round(V[pBack]) Of
    1 : Pal[0] := RGB(255, 255, 255);
    2 : Pal[0] := RGB(0, 0, 48);
  Else
    Pal[0] := 0;
  End;
  For I := 0 To 255 Do
  Begin
    A := 16 + I * 4;
    Bmi[A] := Pal[I] And 255; Bmi[A + 1] := (Pal[I] Shr 8) And 255; Bmi[A + 2] := (Pal[I] Shr 16) And 255; Bmi[A + 3] := 0;
  End;
End;

{ --- image --- }

Procedure SetImage(P : PBytes; W, H : LongInt);
Begin
  RBuf := P; RW := W; RH := H; RStride := (W + 3) And Not 3;
  FillChar(Bmi, 16, 0);
  Bmi[0] := 16;
  Bmi[4] := W And 255; Bmi[5] := (W Shr 8) And 255;
  Bmi[8] := H And 255; Bmi[9] := (H Shr 8) And 255;
  Bmi[12] := 1; Bmi[14] := 8;
End;

{ pixel (X, Y), Y vers le bas }
Procedure PutPx(X, Y, C : LongInt);
Begin
  If (X < 0) Or (Y < 0) Or (X >= RW) Or (Y >= RH) Then Exit;
  RBuf^[(RH - 1 - Y) * RStride + X] := C;
End;

Function GetPx(X, Y : LongInt) : LongInt;
Begin
  GetPx := RBuf^[(RH - 1 - Y) * RStride + X];
End;

Procedure FillPx(X1, Y1, X2, Y2, C : LongInt);
Var Y : LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 >= RW Then X2 := RW - 1;
  If Y2 >= RH Then Y2 := RH - 1;
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  For Y := Y1 To Y2 Do FillChar(RBuf^[(RH - 1 - Y) * RStride + X1], X2 - X1 + 1, C);
End;

{ coordonnees : monde -> image }
Function WX(X : Double) : LongInt;
Begin
  WX := Round((X - EX0) / EScale);
End;

Function WY(Y : Double) : LongInt;
Begin
  WY := Round((EY0 - Y) / EScale);
End;

Procedure LinePx(X1, Y1, X2, Y2, C, Th : LongInt);
Var Dx, Dy, Sx, Sy, Er, E2, H, N : LongInt;
Begin
  Dx := Abs(X2 - X1); Dy := Abs(Y2 - Y1);
  If X1 < X2 Then Sx := 1 Else Sx := -1;
  If Y1 < Y2 Then Sy := 1 Else Sy := -1;
  Er := Dx - Dy;
  H := (Th - 1) Div 2;
  N := 0;
  While True Do
  Begin
    If Th <= 1 Then PutPx(X1, Y1, C) Else FillPx(X1 - H, Y1 - H, X1 - H + Th - 1, Y1 - H + Th - 1, C);
    If ((X1 = X2) And (Y1 = Y2)) Or (N > 20000) Then Break;
    E2 := 2 * Er;
    If E2 > -Dy Then Begin Er := Er - Dy; X1 := X1 + Sx; End;
    If E2 < Dx Then Begin Er := Er + Dx; Y1 := Y1 + Sy; End;
    Inc(N);
  End;
End;

Procedure LineW(X1, Y1, X2, Y2 : Double; C, Th : LongInt);
Begin
  LinePx(WX(X1), WY(Y1), WX(X2), WY(Y2), C, Th);
End;

{ quadrilatere convexe plein (coordonnees du monde) }
Procedure QuadW(X1, Y1, X2, Y2, X3, Y3, X4, Y4 : Double; C : LongInt);
Var Px, Py : Array[0..3] Of Double; K, J, Y, Ya, Yb, Xa, Xb : LongInt; Lo, Hi, T, Yc : Double;
Begin
  Px[0] := (X1 - EX0) / EScale; Py[0] := (EY0 - Y1) / EScale;
  Px[1] := (X2 - EX0) / EScale; Py[1] := (EY0 - Y2) / EScale;
  Px[2] := (X3 - EX0) / EScale; Py[2] := (EY0 - Y3) / EScale;
  Px[3] := (X4 - EX0) / EScale; Py[3] := (EY0 - Y4) / EScale;
  Lo := Py[0]; Hi := Py[0];
  For K := 1 To 3 Do
  Begin
    If Py[K] < Lo Then Lo := Py[K];
    If Py[K] > Hi Then Hi := Py[K];
  End;
  If (Hi < 0) Or (Lo > RH) Then Exit;
  Ya := Round(Lo); Yb := Round(Hi);
  If Ya < 0 Then Ya := 0;
  If Yb > RH - 1 Then Yb := RH - 1;
  For Y := Ya To Yb Do
  Begin
    Yc := Y + 0.0;
    Lo := 1E9; Hi := -1E9;
    For K := 0 To 3 Do
    Begin
      J := (K + 1) Mod 4;
      If ((Py[K] <= Yc) And (Py[J] >= Yc)) Or ((Py[J] <= Yc) And (Py[K] >= Yc)) Then
      Begin
        If Abs(Py[J] - Py[K]) < 1E-9 Then
        Begin
          If Px[K] < Lo Then Lo := Px[K];
          If Px[K] > Hi Then Hi := Px[K];
          If Px[J] < Lo Then Lo := Px[J];
          If Px[J] > Hi Then Hi := Px[J];
        End
        Else
        Begin
          T := Px[K] + (Yc - Py[K]) * (Px[J] - Px[K]) / (Py[J] - Py[K]);
          If T < Lo Then Lo := T;
          If T > Hi Then Hi := T;
        End;
      End;
    End;
    If Hi >= Lo Then
    Begin
      Xa := Round(Lo); Xb := Round(Hi);
      FillPx(Xa, Y, Xb, Y, C);
    End;
  End;
End;

{ --- temps d'echappement --- }

Function ArcTan2(Y, X : Double) : Double;
Var R : Double;
Begin
  If X > 0 Then R := ArcTan(Y / X)
  Else If X < 0 Then
  Begin
    If Y >= 0 Then R := ArcTan(Y / X) + Pi Else R := ArcTan(Y / X) - Pi;
  End
  Else If Y > 0 Then R := Pi / 2
  Else If Y < 0 Then R := -Pi / 2
  Else R := 0;
  ArcTan2 := R;
End;

Function EscIdx(X0, Y0 : Double) : LongInt;
Var Zx, Zy, X2, Y2, Cx_, Cy_, T, Px_, Py_, Qx, Qy, Mu, Fx, Fy, Dx, Dy, Dd : Double; N, K, R : LongInt;
Begin
  N := 0; R := 0;
  Zx := 0; Zy := 0; Cx_ := X0; Cy_ := Y0; X2 := 0; Y2 := 0;
  Case FType Of
    ftMandel :
      While N < EIter Do
      Begin
        X2 := Zx * Zx; Y2 := Zy * Zy;
        If X2 + Y2 > EB2 Then Break;
        Zy := 2 * Zx * Zy + Cy_; Zx := X2 - Y2 + Cx_;
        Inc(N);
      End;
    ftJulia :
      Begin
        Zx := X0; Zy := Y0;
        While N < EIter Do
        Begin
          X2 := Zx * Zx; Y2 := Zy * Zy;
          If X2 + Y2 > EB2 Then Break;
          Zy := 2 * Zx * Zy + ECim; Zx := X2 - Y2 + ECre;
          Inc(N);
        End;
      End;
    ftShip :
      Begin
        Cy_ := -Y0;
        While N < EIter Do
        Begin
          X2 := Zx * Zx; Y2 := Zy * Zy;
          If X2 + Y2 > EB2 Then Break;
          Zy := Abs(2 * Zx * Zy) + Cy_; Zx := X2 - Y2 + Cx_;
          Inc(N);
        End;
      End;
    ftTricorn :
      While N < EIter Do
      Begin
        X2 := Zx * Zx; Y2 := Zy * Zy;
        If X2 + Y2 > EB2 Then Break;
        Zy := -2 * Zx * Zy + Cy_; Zx := X2 - Y2 + Cx_;
        Inc(N);
      End;
    ftMulti :
      While N < EIter Do
      Begin
        X2 := Zx * Zx; Y2 := Zy * Zy;
        If X2 + Y2 > EB2 Then Break;
        Px_ := Zx; Py_ := Zy;
        For K := 2 To EPow Do
        Begin
          T := Px_ * Zx - Py_ * Zy; Py_ := Px_ * Zy + Py_ * Zx; Px_ := T;
        End;
        Zx := Px_ + Cx_; Zy := Py_ + Cy_;
        Inc(N);
      End;
    ftPhoenix :
      Begin
        Zx := Y0; Zy := X0; Qx := 0; Qy := 0;
        While N < EIter Do
        Begin
          X2 := Zx * Zx; Y2 := Zy * Zy;
          If X2 + Y2 > EB2 Then Break;
          T := X2 - Y2 + ECre + EPhx * Qx;
          Py_ := 2 * Zx * Zy + ECim + EPhx * Qy;
          Qx := Zx; Qy := Zy;
          Zx := T; Zy := Py_;
          Inc(N);
        End;
      End;
    ftNewton :
      Begin
        Zx := X0; Zy := Y0;
        While N < EIter Do
        Begin
          { P = z^(n-1), f = z^n - 1, f' = n z^(n-1) }
          Px_ := 1; Py_ := 0;
          For K := 1 To EPow - 1 Do
          Begin
            T := Px_ * Zx - Py_ * Zy; Py_ := Px_ * Zy + Py_ * Zx; Px_ := T;
          End;
          Fx := Px_ * Zx - Py_ * Zy - 1; Fy := Px_ * Zy + Py_ * Zx;
          If Fx * Fx + Fy * Fy < 1E-10 Then Break;
          Dx := EPow * Px_; Dy := EPow * Py_;
          Dd := Dx * Dx + Dy * Dy;
          If Dd < 1E-20 Then
          Begin
            N := EIter;
            Break;
          End;
          { z <- z - a f / f' }
          Zx := Zx - ERelax * (Fx * Dx + Fy * Dy) / Dd;
          Zy := Zy - ERelax * (Fy * Dx - Fx * Dy) / Dd;
          Inc(N);
        End;
        If N >= EIter Then
        Begin
          EscIdx := 0;
          Inc(JobInside); JobIterSum := JobIterSum + N;
          Exit;
        End;
        K := Round(ArcTan2(Zy, Zx) * EPow / (2 * Pi));
        K := ((K Mod EPow) + EPow) Mod EPow;
        R := 255 Div EPow;
        T := N * EDens;
        If T > R - 1 Then T := R - 1;
        JobIterSum := JobIterSum + N;
        EscIdx := 1 + K * R + Trunc(T);
        Exit;
      End;
  End;
  JobIterSum := JobIterSum + N;
  If N >= EIter Then
  Begin
    Inc(JobInside);
    EscIdx := 0;
    Exit;
  End;
  If EColMode = 0 Then
  Begin
    T := Zx * Zx + Zy * Zy;
    If T < 1.0001 Then T := 1.0001;
    T := Ln(T) / 2;
    If T < 1E-6 Then T := 1E-6;
    Mu := N + 1 - Ln(T) / ELnPow;
    If Mu < 0 Then Mu := 0;
  End
  Else Mu := N;
  EscIdx := 1 + (Trunc(Mu * EDens) Mod 255);
End;

{ --- IFS --- }

Procedure SetMap(K : LongInt; A, B, C, D, E, F, P : Double);
Begin
  IfA[K] := A; IfB[K] := B; IfC[K] := C; IfD[K] := D; IfE[K] := E; IfF[K] := F; IfP[K] := P;
End;

Procedure IfsMaps;
Var I, J, K : LongInt;
Begin
  NMap := 0;
  Case FType Of
    ftFern :
      Begin
        SetMap(0, 0, 0, 0, 0.16, 0, 0, 0.01);
        SetMap(1, 0.85, 0.04, -0.04, 0.85, 0, 1.6, 0.85);
        SetMap(2, 0.2, -0.26, 0.23, 0.22, 0, 1.6, 0.07);
        SetMap(3, -0.15, 0.28, 0.26, 0.24, 0, 0.44, 0.07);
        NMap := 4;
      End;
    ftSierTri :
      Begin
        SetMap(0, 0.5, 0, 0, 0.5, 0, 0, 1 / 3);
        SetMap(1, 0.5, 0, 0, 0.5, 0.5, 0, 1 / 3);
        SetMap(2, 0.5, 0, 0, 0.5, 0.25, 0.4330127, 1 / 3);
        NMap := 3;
      End;
    ftCarpet :
      Begin
        K := 0;
        For J := 0 To 2 Do
          For I := 0 To 2 Do
            If (I <> 1) Or (J <> 1) Then
            Begin
              SetMap(K, 1 / 3, 0, 0, 1 / 3, I / 3, J / 3, 1 / 8);
              Inc(K);
            End;
        NMap := 8;
      End;
    ftDragon :
      Begin
        SetMap(0, 0.5, -0.5, 0.5, 0.5, 0, 0, 0.5);
        SetMap(1, -0.5, -0.5, 0.5, -0.5, 1, 0, 0.5);
        NMap := 2;
      End;
  Else
    Begin
      SetMap(0, 0.5, -0.5, 0.5, 0.5, 0, 0, 0.5);
      SetMap(1, 0.5, 0.5, -0.5, 0.5, 0.5, 0.5, 0.5);
      NMap := 2;
    End;
  End;
End;

{ --- courbes et arbres --- }

Function SegColor : LongInt;
Begin
  If Round(CV[pLineCol]) = 1 Then SegColor := 170
  Else SegColor := 1 + (SegN * 254) Div MaxI(1, SegTotal);
  Inc(SegN);
End;

Procedure KochSeg(Ax, Ay, Bx, By : Double; D : LongInt);
Var Dx, Dy, S, P1x, P1y, P3x, P3y, Tx, Ty, Ca, Sa : Double;
Begin
  If D <= 0 Then
  Begin
    LineW(Ax, Ay, Bx, By, SegColor, Round(CV[pThick]));
    Exit;
  End;
  Ca := Cos(CV[pAngle] * Pi / 180); Sa := Sin(CV[pAngle] * Pi / 180);
  S := 1 / (2 * (1 + Ca));
  Dx := (Bx - Ax) * S; Dy := (By - Ay) * S;
  P1x := Ax + Dx; P1y := Ay + Dy;
  P3x := Bx - Dx; P3y := By - Dy;
  { pointe : (P1) + rotation de (Dx, Dy) vers l'exterieur }
  Tx := P1x + Dx * Ca - Dy * Sa; Ty := P1y + Dx * Sa + Dy * Ca;
  KochSeg(Ax, Ay, P1x, P1y, D - 1);
  KochSeg(P1x, P1y, Tx, Ty, D - 1);
  KochSeg(Tx, Ty, P3x, P3y, D - 1);
  KochSeg(P3x, P3y, Bx, By, D - 1);
End;

{ point K (0 a N*N-1) de la courbe de Hilbert d'ordre N }
Procedure HilbertD2(N, D : LongInt; Var X, Y : LongInt);
Var Rx, Ry, S, T, Tmp : LongInt;
Begin
  X := 0; Y := 0; T := D; S := 1;
  While S < N Do
  Begin
    Rx := 1 And (T Div 2);
    Ry := 1 And (T Xor Rx);
    If Ry = 0 Then
    Begin
      If Rx = 1 Then
      Begin
        X := S - 1 - X; Y := S - 1 - Y;
      End;
      Tmp := X; X := Y; Y := Tmp;
    End;
    X := X + S * Rx; Y := Y + S * Ry;
    T := T Div 4;
    S := S * 2;
  End;
End;

Procedure TreeBr(X, Y, Ang, Len : Double; Lv, Dp : LongInt);
Var X2, Y2, Th : Double; C : LongInt;
Begin
  X2 := X + Len * Cos(Ang); Y2 := Y + Len * Sin(Ang);
  If Round(CV[pLineCol]) = 1 Then C := 170 Else C := 1 + (Lv * 254) Div MaxI(1, Dp);
  Th := CV[pThick] * (Dp - Lv + 1) / (Dp + 1);
  LineW(X, Y, X2, Y2, C, MaxI(1, Round(Th * 2)));
  If Lv >= Dp Then Exit;
  TreeBr(X2, Y2, Ang + CV[pAngle] * Pi / 180, Len * CV[pRatio], Lv + 1, Dp);
  TreeBr(X2, Y2, Ang - CV[pAngle] * Pi / 180, Len * CV[pRatio], Lv + 1, Dp);
End;

Procedure PythSq(Ax, Ay, Bx, By : Double; Lv, Dp : LongInt);
Var Nx, Ny, Cx_, Cy_, Dx_, Dy_, Ex, Ey, Ca, Sa, Ux, Uy : Double; C : LongInt;
Begin
  { carre sur le cote A -> B, vers la gauche }
  Nx := -(By - Ay); Ny := Bx - Ax;
  Cx_ := Bx + Nx; Cy_ := By + Ny; Dx_ := Ax + Nx; Dy_ := Ay + Ny;
  If Round(CV[pLineCol]) = 1 Then C := 170 Else C := 1 + (Lv * 254) Div MaxI(1, Dp);
  QuadW(Ax, Ay, Bx, By, Cx_, Cy_, Dx_, Dy_, C);
  If Lv >= Dp Then Exit;
  { triangle rectangle sur le cote D -> C, angle choisi en D }
  Ca := Cos(CV[pAngle] * Pi / 180); Sa := Sin(CV[pAngle] * Pi / 180);
  Ux := (Cx_ - Dx_) * Ca; Uy := (Cy_ - Dy_) * Ca;
  Ex := Dx_ + Ux * Ca - Uy * Sa; Ey := Dy_ + Ux * Sa + Uy * Ca;
  PythSq(Dx_, Dy_, Ex, Ey, Lv + 1, Dp);
  PythSq(Ex, Ey, Cx_, Cy_, Lv + 1, Dp);
End;

Procedure DrawLines;
Var N, K, X, Y, Px_, Py_, D : LongInt; H, S : Double;
Begin
  D := Round(CV[pDepth]);
  If D > MaxDepth(FType) Then D := MaxDepth(FType);
  SegN := 0;
  Case FType Of
    ftKoch :
      Begin
        SegTotal := 3;
        For K := 1 To D Do SegTotal := SegTotal * 4;
        H := 0.8660254;
        KochSeg(-0.5, -H / 3, 0, H * 2 / 3, D);
        KochSeg(0, H * 2 / 3, 0.5, -H / 3, D);
        KochSeg(0.5, -H / 3, -0.5, -H / 3, D);
      End;
    ftHilbert :
      Begin
        If D < 1 Then D := 1;
        N := 1;
        For K := 1 To D Do N := N * 2;
        SegTotal := N * N;
        S := 1 / N;
        HilbertD2(N, 0, Px_, Py_);
        For K := 1 To N * N - 1 Do
        Begin
          HilbertD2(N, K, X, Y);
          LineW((Px_ + 0.5) * S, (Py_ + 0.5) * S, (X + 0.5) * S, (Y + 0.5) * S, SegColor, Round(CV[pThick]));
          Px_ := X; Py_ := Y;
        End;
      End;
    ftTree : TreeBr(0, 0, Pi / 2, 1, 0, D);
  Else
    PythSq(-0.5, 0, 0.5, 0, 0, D);
  End;
End;

{ --- tache de calcul --- }

{ valeurs du calcul : CV, image courante (RBuf) }
Procedure JobPrepare;
Var D : Double;
Begin
  EIter := Round(CV[pIter]); EPow := Round(CV[pPower]); EDens := CV[pDensity];
  If EPow < 2 Then EPow := 2;
  EB2 := CV[pBail] * CV[pBail];
  ECre := CV[pCRe]; ECim := CV[pCIm]; EPhx := CV[pPhx]; ERelax := CV[pRelax];
  ELnPow := Ln(EPow);
  If FType = ftNewton Then ELnPow := Ln(2);
  EColMode := Round(CV[pColMode]);
  D := 0;
  If D <> 0 Then ;
  EScale := CV[pWidth] / RW;
  EX0 := CV[pCx] - RW / 2 * EScale;
  EY0 := CV[pCy] + RH / 2 * EScale;
End;

Procedure JobStart;
Var K : LongInt;
Begin
  JobPrepare;
  JobOn := True; JobDone := False;
  JobPass := 0; JobRow := 0; JobPos := 0; JobMaxCnt := 0; JobConvT := 0;
  JobInside := 0; JobIterSum := 0; JobPixels := 0;
  JobT0 := PTicks; JobMs := 0;
  RndInit(1234567);
  JobPx := 0.1; JobPy := 0.1; JobPz := 0.1;
  FillPx(0, 0, RW - 1, RH - 1, 0);
  Case FamilyOf(FType) Of
    fmEscape :
      Begin
        JobTotal := RH;
        If (RW * RH > 20000) And AllowCoarse Then JobStepPx := 4 Else JobStepPx := 1;
        JobCoarse := JobStepPx > 1;
      End;
    fmIfs, fmAttr :
      Begin
        JobTotal := Round(CV[pPoints]);
        { compteurs de points par pixel }
        If CntCap < RStride * RH Then
        Begin
          If RCnt <> Nil Then FreeMem(RCnt, CntCap * 4);
          CntCap := RStride * RH;
          GetMem(RCnt, CntCap * 4);
        End;
        For K := 0 To RStride * RH - 1 Do RCnt^[K] := 0;
        If FType <> ftLorenz Then IfsMaps;
        If FType = ftLorenz Then
        Begin
          JobPx := 0.1; JobPy := 0; JobPz := 0;
        End;
      End;
  Else
    Begin
      JobTotal := 1;
      DrawLines;
      JobPos := 1;
      JobDone := True; JobOn := False;
      JobMs := PTicks - JobT0;
    End;
  End;
End;

{ nombre de points -> couleur (densite en logarithme) }
Procedure ConvertCounts;
Var K, X, Y, C, M, I, Mode : LongInt; L : Double;
Begin
  M := JobMaxCnt;
  If M < 1 Then Exit;
  L := Ln(1 + M);
  Mode := Round(CV[pPtCol]);
  If FamilyOf(FType) = fmAttr Then Mode := 0;
  For Y := 0 To RH - 1 Do
  Begin
    K := (RH - 1 - Y) * RStride;
    For X := 0 To RW - 1 Do
    Begin
      C := RCnt^[K + X] And $FFFFFF;
      If C > 0 Then
      Begin
        If Mode = 0 Then
        Begin
          If C < 4096 Then I := 1 + Trunc(253 * LnTab[C] / L) Else I := 1 + Trunc(253 * Ln(1 + C) / L);
          If I > 255 Then I := 255;
          RBuf^[K + X] := I;
        End
        Else If Mode = 2 Then RBuf^[K + X] := 170
        Else RBuf^[K + X] := 1 + (((RCnt^[K + X] Shr 24) And 7) * 254) Div MaxI(1, NMap) + 127 Div MaxI(1, NMap);
      End;
    End;
  End;
End;

{ un pas du calcul (au plus Budget millisecondes) ; rend True quand c'est fini }
Function JobStep(Budget : LongInt) : Boolean;
Var T0, X, Y, K, M, Sx, Px_, Py_, Idx, N, I : LongInt; R, Xn, Yn, Zn, Wx_, Wy_ : Double;
Begin
  JobStep := True;
  If Not JobOn Then Exit;
  T0 := PTicks;
  Case FamilyOf(FType) Of
    fmEscape :
      Begin
        Sx := JobStepPx;
        Repeat
          Y := JobRow;
          Wy_ := EY0 - (Y + 0.5) * EScale;
          X := 0;
          While X < RW Do
          Begin
            { second passage : les pixels de l'apercu sont deja calcules }
            If Not ((JobPass = 1) And JobCoarse And ((X Mod 4) = 0) And ((Y Mod 4) = 0)) Then
            Begin
              Idx := EscIdx(EX0 + (X + 0.5) * EScale, Wy_);
              Inc(JobPixels);
              If Sx > 1 Then FillPx(X, Y, X + Sx - 1, Y + Sx - 1, Idx) Else PutPx(X, Y, Idx);
            End;
            X := X + Sx;
          End;
          JobRow := JobRow + Sx;
          If JobRow >= RH Then
          Begin
            If (JobPass = 0) And (Sx > 1) Then
            Begin
              JobPass := 1; JobRow := 0; JobStepPx := 1;
              JobInside := 0; JobIterSum := 0; JobPixels := 0;
              Sx := 1;
            End
            Else
            Begin
              JobDone := True;
              Break;
            End;
          End;
        Until PTicks - T0 >= Budget;
        If JobPass = 0 Then JobPos := JobRow Div 4 Else JobPos := RH Div 4 + (JobRow * 3) Div 4;
        JobTotal := RH;
      End;
    fmIfs, fmAttr :
      Begin
        Repeat
          For K := 1 To 5000 Do
          Begin
            If FType = ftLorenz Then
            Begin
              Xn := JobPx + 0.005 * CV[pA] * (JobPy - JobPx);
              Yn := JobPy + 0.005 * (JobPx * (CV[pB] - JobPz) - JobPy);
              Zn := JobPz + 0.005 * (JobPx * JobPy - CV[pC] * JobPz);
              JobPx := Xn; JobPy := Yn; JobPz := Zn;
              R := CV[pRot] * Pi / 180;
              Wx_ := Xn * Cos(R) - Yn * Sin(R);
              Wy_ := Zn;
              M := 0;
            End
            Else If FType = ftClifford Then
            Begin
              Xn := Sin(CV[pA] * JobPy) + CV[pC] * Cos(CV[pA] * JobPx);
              Yn := Sin(CV[pB] * JobPx) + CV[pD] * Cos(CV[pB] * JobPy);
              JobPx := Xn; JobPy := Yn;
              Wx_ := Xn; Wy_ := Yn;
              M := 0;
            End
            Else
            Begin
              { jeu du chaos : une transformation selon sa probabilite }
              R := Rnd(1000000) / 1000000;
              M := 0;
              While (M < NMap - 1) And (R >= IfP[M]) Do
              Begin
                R := R - IfP[M];
                Inc(M);
              End;
              Xn := IfA[M] * JobPx + IfB[M] * JobPy + IfE[M];
              Yn := IfC[M] * JobPx + IfD[M] * JobPy + IfF[M];
              JobPx := Xn; JobPy := Yn;
              Wx_ := Xn; Wy_ := Yn;
            End;
            Inc(JobPos);
            If JobPos > 20 Then
            Begin
              Px_ := Trunc((Wx_ - EX0) / EScale); Py_ := Trunc((EY0 - Wy_) / EScale);
              If (Px_ >= 0) And (Py_ >= 0) And (Px_ < RW) And (Py_ < RH) Then
              Begin
                I := (RH - 1 - Py_) * RStride + Px_;
                N := (RCnt^[I] And $FFFFFF) + 1;
                If N > $FFFFFF Then N := $FFFFFF;
                RCnt^[I] := N Or (M Shl 24);
                If N > JobMaxCnt Then JobMaxCnt := N;
              End;
            End;
            If JobPos >= JobTotal Then Break;
          End;
          If JobPos >= JobTotal Then JobDone := True;
        Until JobDone Or (PTicks - T0 >= Budget);
        If JobDone Or (PTicks - JobConvT > 400) Then
        Begin
          ConvertCounts;
          JobConvT := PTicks;
        End;
      End;
  End;
  JobMs := PTicks - JobT0;
  If JobDone Then JobOn := False;
  JobStep := JobDone;
End;

{ calcul complet (sans fenetre) }
Procedure JobRun;
Begin
  JobStart;
  While JobOn Do
    If JobStep(1000) Then ;
End;

{ --- fichiers --- }

{ parametres de la fractale (texte .FRC) }
Procedure WriteFrc(T : LongInt);
Var K : LongInt;
Begin
  OutB.Len := 0;
  BufAdd(OutB, '; G'#130'n'#130'rateur de Fractal (OS/2-0)'#13#10);
  BufAdd(OutB, 'FRACTALE=' + FracKey(T) + #13#10);
  BuildPropList(T);
  For K := 0 To NPL - 1 Do BufAdd(OutB, PropKey(PL[K]) + '=' + FStr(Vals[T][PL[K]], 15) + #13#10);
End;

{ lecture d'un .FRC : rend la fractale (-1 : erreur) }
Function ReadFrc(Name : String; Var Err : String) : LongInt;
Var H, N, I, T, K, P, Ln_ : LongInt; Bf : Array[0..8191] Of Byte; S, Key, Vs : String; V : Double;
Begin
  ReadFrc := -1;
  Err := 'Fichier illisible.';
  If Not FOpenRead(Name, H) Then Exit;
  N := FRead(H, @Bf, SizeOf(Bf));
  DosClose(H);
  If N <= 0 Then Exit;
  T := -1; I := 0; Ln_ := 0;
  While I < N Do
  Begin
    S := '';
    While (I < N) And (Bf[I] <> 10) And (Bf[I] <> 13) Do
    Begin
      If Length(S) < 250 Then S := S + Chr(Bf[I]);
      Inc(I);
    End;
    While (I < N) And ((Bf[I] = 10) Or (Bf[I] = 13)) Do Inc(I);
    Inc(Ln_);
    S := Trim(S);
    If (S = '') Or (S[1] = ';') Or (S[1] = '#') Then Continue;
    P := Pos('=', S);
    If P = 0 Then Continue;
    Key := UpStr(Trim(Copy(S, 1, P - 1))); Vs := Trim(Copy(S, P + 1, 255));
    If Key = 'FRACTALE' Then
    Begin
      T := -1;
      For K := 0 To NFrac - 1 Do If FracKey(K) = UpStr(Vs) Then T := K;
      If T < 0 Then
      Begin
        Err := 'Fractale inconnue : ' + Vs;
        Exit;
      End;
      Preset(T);
    End
    Else If T >= 0 Then
      For K := 0 To NProp - 1 Do
        If PropKey(K) = Key Then
          If ParseF(Vs, V) Then Vals[T][K] := V;
  End;
  If T < 0 Then
  Begin
    Err := 'Ligne FRACTALE= absente : ce n''est pas un fichier du G'#130'n'#130'rateur de Fractal.';
    Exit;
  End;
  Err := '';
  ReadFrc := T;
End;

{ image BMP (8 bits, 256 couleurs) de l'image courante }
Procedure MakeBmp;
Var Sz, K : LongInt;

  Procedure L32(V : LongInt);
  Begin
    BufAddC(OutB, V); BufAddC(OutB, V Shr 8); BufAddC(OutB, V Shr 16); BufAddC(OutB, V Shr 24);
  End;

Begin
  OutB.Len := 0;
  Sz := 54 + 1024 + RStride * RH;
  BufAdd(OutB, 'BM'); L32(Sz); L32(0); L32(54 + 1024);
  L32(40); L32(RW); L32(RH); BufAddC(OutB, 1); BufAddC(OutB, 0); BufAddC(OutB, 8); BufAddC(OutB, 0);
  L32(0); L32(RStride * RH); L32(2835); L32(2835); L32(256); L32(256);
  For K := 0 To 255 Do
  Begin
    BufAddC(OutB, Pal[K] And 255); BufAddC(OutB, (Pal[K] Shr 8) And 255); BufAddC(OutB, (Pal[K] Shr 16) And 255);
    BufAddC(OutB, 0);
  End;
  BufAddB(OutB, RBuf, RStride * RH);
End;

Procedure InitEngine;
Var K : LongInt;
Begin
  For K := 0 To NFrac - 1 Do Preset(K);
  For K := 0 To 4095 Do LnTab[K] := Ln(1 + K);
  RBuf := Nil; RCnt := Nil; CntCap := 0; RW := 1; RH := 1; RStride := 4;
  JobOn := False; JobDone := False; FType := ftMandel;
  RSeed := 12345;
  BufInit(OutB);
End;
{ ==================================================================== }
{ Fenetre : etat, disposition et dessin                                 }
{ ==================================================================== }

Const
  LsW = 222; PnW = 296; MaxTb = 24;
  ThW = 32; ThH = 24;                    { miniatures de la liste }
  RowPH = 20;                            { hauteur d'une ligne de proprietes }
  { commandes }
  cmNew = 100; cmOpen = 101; cmSave = 102; cmSaveAs = 103; cmExport = 104; cmCopy = 105; cmQuit = 106;
  cmGenerate = 120; cmStop = 121; cmProps = 122; cmDefaults = 123; cmDetails = 124; cmEditProp = 125;
  cmPrevFrac = 126; cmNextFrac = 127;
  cmZoomIn = 130; cmZoomOut = 131; cmHome = 132; cmAxes = 133; cmCycle = 134; cmToolbar = 135;
  cmShowList = 136; cmShowProps = 137; cmCenter = 138; cmJulia = 139;
  cmPal0 = 140;                          { + palette (0 a 7) }
  cmProgressive = 150; cmThumbs = 151; cmExportSize = 152;
  cmHelp = 170; cmAbout = 171;
  cmFrac0 = 200;                         { + fractale (0 a 17) }
  { glisser }
  dRb = 5;

Var
  Hab, Hmq, Frame, Client, MenuHw, Hps, CW, CH : LongInt;
  GQmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..8191] Of Byte;
  MenuLen : LongInt;
  UX1, UY1, UX2, UY2 : LongInt;
  IcX, IcY : LongInt;
  Y0, Y1, LsR, PnX, PvX, PvY, PvW, PvH : LongInt;
  Cur : LongInt;                         { fractale choisie }
  Img : PBytes;                          { image de l'apercu }
  ImgW, ImgH : LongInt;
  ThBuf : PBytes;                        { miniatures (24 bits) }
  ThBmi : Array[0..15] Of Byte;
  ThReady : Boolean;
  ShowAxes, Cycling, ShowToolbar, ShowList, ShowProps, Progressive, ShowThumbs : Boolean;
  SelRow, ListTop : LongInt;
  RbX0, RbY0, RbX1, RbY1 : LongInt;
  MouseIn, RbOn : Boolean;
  MouseWX, MouseWY : Double;
  ExportW, ExportH : LongInt;
  LastMs, LastInside, LastPixels, LastIter : LongInt;
  { barre d'outils }
  NTb, TbDown, TbHot : LongInt;
  TbCmd, TbX, TbW, TbIco : Array[0..MaxTb - 1] Of LongInt;
  TbTxt, TbTip : Array[0..MaxTb - 1] Of String;
  StatusMsg, SavedMsg, FileName : String;
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
        IR(2, 1, 12, 14, cWhite); IB(2, 1, 12, 14, cBlack);
        IR(9, 1, 12, 4, cSilver);
        IR(5, 7, 9, 7, cRed); IR(7, 5, 7, 9, cRed); IR(6, 6, 8, 8, cYellow);
      End;
    2 :
      Begin
        IR(1, 3, 6, 4, cBrown); IR(1, 4, 14, 13, cYellow); IB(1, 4, 14, 13, cBrown);
        IR(3, 7, 15, 13, cYellow); IB(3, 7, 15, 13, cBrown);
      End;
    3 : Begin IR(1, 1, 14, 14, cNavy); IR(4, 1, 11, 5, cSilver); IR(3, 8, 12, 14, cWhite); IB(1, 1, 14, 14, cBlack); End;
    4 :
      Begin
        { exporter l'image : paysage }
        IR(1, 2, 14, 13, cCyan); IB(1, 2, 14, 13, cBlack);
        Disc(IcX + 10, IcY + 5, 2, cYellow);
        For I := 0 To 5 Do IR(2 + I, 12 - I, 9 - I + 2 * I, 12 - I, cDGreen);
        IR(2, 12, 13, 12, cDGreen);
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
    6 : Begin IR(3, 3, 12, 12, cRed); IB(3, 3, 12, 12, cMaroon); End;
    7, 8 :
      Begin
        { loupe }
        Disc(IcX + 6, IcY + 6, 5, cNavy); Disc(IcX + 6, IcY + 6, 4, cWhite);
        Thick(IcX + 9, IcY + 9, IcX + 13, IcY + 13, cBrown);
        IR(4, 6, 8, 6, cBlack);
        If K = 7 Then IR(6, 4, 6, 8, cBlack);
      End;
    9 :
      Begin
        { vue initiale : maison }
        For I := 0 To 6 Do IR(7 - I, 2 + I, 8 + I, 2 + I, cMaroon);
        IR(3, 8, 12, 14, cWhite); IB(3, 8, 12, 14, cBlack); IR(7, 10, 9, 14, cBrown);
      End;
    10 :
      Begin
        { axes }
        IR(1, 8, 14, 8, cBlack); IR(7, 1, 7, 14, cBlack);
        IR(12, 6, 13, 10, cBlack); IR(5, 2, 9, 3, cBlack);
        For I := 0 To 3 Do IR(3 + I * 3, 7, 3 + I * 3, 9, cGray);
      End;
    11 :
      Begin
        { couleurs animees }
        IR(1, 2, 4, 13, cRed); IR(4, 2, 7, 13, cYellow); IR(7, 2, 10, 13, cGreen); IR(10, 2, 13, 13, cBlue);
        IB(1, 2, 13, 13, cBlack);
      End;
    12 :
      Begin
        Disc(IcX + 8, IcY + 8, 6, cGray); Disc(IcX + 8, IcY + 8, 2, cSilver);
        IR(7, 0, 9, 2, cGray); IR(7, 14, 9, 15, cGray); IR(0, 7, 2, 9, cGray); IR(14, 7, 15, 9, cGray);
      End;
    13 :
      Begin
        Disc(IcX + 8, IcY + 8, 7, cBlue);
        IR(6, 4, 9, 4, cWhite); IR(9, 5, 10, 6, cWhite); IR(7, 7, 9, 7, cWhite); IR(7, 8, 8, 9, cWhite);
        IR(7, 11, 8, 12, cWhite);
      End;
  End;
End;

{ ==================================================================== }
{ Disposition                                                           }
{ ==================================================================== }

Var
  NItem : LongInt;
  ItKind, ItY, ItH : Array[0..31] Of LongInt;

{ liste : en-tetes de familles (-1 - famille) et fractales }
Procedure ListLayout;
Var F, T, Y : LongInt;
Begin
  NItem := 0; Y := 0;
  For F := fmEscape To fmAttr Do
  Begin
    ItKind[NItem] := -1 - F; ItY[NItem] := Y; ItH[NItem] := 18; Y := Y + 18; Inc(NItem);
    For T := 0 To NFrac - 1 Do
      If FamilyOf(T) = F Then
      Begin
        ItKind[NItem] := T; ItY[NItem] := Y; ItH[NItem] := ThH + 3; Y := Y + ThH + 3; Inc(NItem);
      End;
  End;
End;

Function ListY0 : LongInt;
Begin
  ListY0 := Y0 + 30 - ListTop;
End;

Procedure Layout;
Begin
  If ShowToolbar Then Y0 := TbH Else Y0 := 0;
  Y1 := CH - SbH - 1;
  If ShowList Then LsR := LsW Else LsR := 0;
  If ShowProps Then PnX := CW - PnW Else PnX := CW;
  PvX := LsR + 10; PvY := Y0 + 10;
  PvW := PnX - 10 - PvX; PvH := Y1 - 10 - PvY + 1;
  If PvW > MaxImgW Then PvW := MaxImgW;
  If PvH > MaxImgH Then PvH := MaxImgH;
  If PvW < 16 Then PvW := 16;
  If PvH < 16 Then PvH := 16;
  ListLayout;
End;

Procedure InvalPreview;
Begin
  InvalBand(PvX - 2, PvY - 2, PvX + PvW + 2, PvY + PvH + 2);
End;

Procedure InvalList;
Begin
  InvalBand(0, Y0, LsR, Y1 + 1);
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
  TbPressed := ((C = cmAxes) And ShowAxes) Or ((C = cmCycle) And Cycling);
End;

Function TbDisabled(C : LongInt) : Boolean;
Begin
  TbDisabled := (C = cmStop) And Not JobOn;
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
{ Liste des fractales (gauche)                                          }
{ ==================================================================== }

Procedure BlitThumb(T, X, Y : LongInt);
Var P : Array[0..7] Of LongInt; Tot : LongInt;
Begin
  If Not ThReady Or Not ShowThumbs Then Exit;
  If (X > UX2) Or (X + ThW < UX1) Or (Y > UY2) Or (Y + ThH < UY1) Then Exit;
  Tot := ThH * NFrac;
  P[0] := X; P[1] := CH - (Y + ThH); P[2] := X + ThW; P[3] := CH - Y;
  P[4] := 0; P[5] := Tot - (T + 1) * ThH; P[6] := ThW; P[7] := Tot - T * ThH;
  Dummy := GpiDrawBits(Hps, LongInt(ThBuf), LongInt(@ThBmi), 4, LongInt(@P), $CC, 0);
End;

Procedure PaintList;
Var I, Y, T, Tx : LongInt;
Begin
  FBar(0, Y0, LsR - 1, Y1, cSilver);
  VLine(LsR - 2, Y0, Y1, cGray); VLine(LsR - 1, Y0, Y1, cWhite);
  OutTxt(12, Y0 + 6, 'Fractales', cNavy, cSilver);
  HLine(12, LsR - 14, Y0 + 24, cNavy);
  Sunken(6, Y0 + 28, LsR - 8, Y1 - 6, cWhite);
  For I := 0 To NItem - 1 Do
  Begin
    Y := ListY0 + ItY[I];
    If (Y < Y0 + 29) Or (Y + ItH[I] > Y1 - 7) Then Continue;
    T := ItKind[I];
    If T < 0 Then
    Begin
      FBar(8, Y, LsR - 10, Y + ItH[I] - 2, cSilver);
      OutTxt(12, Y, Fit(FamilyName(-1 - T), LsR - 24), cNavy, cSilver);
    End
    Else
    Begin
      If T = Cur Then FBar(8, Y, LsR - 10, Y + ItH[I] - 1, cNavy);
      If ShowThumbs Then
      Begin
        Box(11, Y + 1, 12 + ThW, Y + 2 + ThH, cGray);
        BlitThumb(T, 12, Y + 2);
        Tx := 20 + ThW;
      End
      Else Tx := 14;
      If T = Cur Then OutTxt(Tx, Y + (ItH[I] - 16) Div 2, Fit(ShortName(T), LsR - Tx - 12), cWhite, cNavy)
      Else OutTxt(Tx, Y + (ItH[I] - 16) Div 2, Fit(ShortName(T), LsR - Tx - 12), cBlack, cWhite);
    End;
  End;
End;

Function ListHit(X, Y : LongInt) : LongInt;
Var I, Yy : LongInt;
Begin
  ListHit := -1;
  If (X < 8) Or (X > LsR - 10) Then Exit;
  For I := 0 To NItem - 1 Do
  Begin
    Yy := ListY0 + ItY[I];
    If (ItKind[I] >= 0) And (Y >= Yy) And (Y < Yy + ItH[I]) And (Yy >= Y0 + 29) Then ListHit := ItKind[I];
  End;
End;

{ ==================================================================== }
{ Apercu (centre)                                                       }
{ ==================================================================== }

Procedure BlitImage;
Var P : Array[0..7] Of LongInt; Ix1, Iy1, Ix2, Iy2 : LongInt;
Begin
  { partie de l'image dans la zone a repeindre }
  Ix1 := MaxI(0, UX1 - PvX); Iy1 := MaxI(0, UY1 - PvY);
  Ix2 := MinI(ImgW - 1, UX2 - PvX); Iy2 := MinI(ImgH - 1, UY2 - PvY);
  If (Ix2 < Ix1) Or (Iy2 < Iy1) Then Exit;
  P[0] := PvX + Ix1; P[1] := CH - (PvY + Iy2 + 1); P[2] := PvX + Ix2 + 1; P[3] := CH - (PvY + Iy1);
  P[4] := Ix1; P[5] := ImgH - 1 - Iy2; P[6] := Ix2 + 1; P[7] := ImgH - Iy1;
  Dummy := GpiDrawBits(Hps, LongInt(Img), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

{ monde -> fenetre, avec les valeurs de la fractale choisie }
Function ScrX(X : Double) : LongInt;
Var S : Double;
Begin
  S := Vals[Cur][pWidth] / ImgW;
  ScrX := PvX + Round((X - Vals[Cur][pCx]) / S + ImgW / 2);
End;

Function ScrY(Y : Double) : LongInt;
Var S : Double;
Begin
  S := Vals[Cur][pWidth] / ImgW;
  ScrY := PvY + Round(ImgH / 2 - (Y - Vals[Cur][pCy]) / S);
End;

Function WorldX(X : LongInt) : Double;
Begin
  WorldX := Vals[Cur][pCx] + (X - PvX - ImgW / 2) * Vals[Cur][pWidth] / ImgW;
End;

Function WorldY(Y : LongInt) : Double;
Begin
  WorldY := Vals[Cur][pCy] - (Y - PvY - ImgH / 2) * Vals[Cur][pWidth] / ImgW;
End;

Procedure PaintAxes;
Var X, Y, C : LongInt; S : String;
Begin
  If Round(Vals[Cur][pBack]) = 1 Then C := cGray Else C := cSilver;
  X := ScrX(0); Y := ScrY(0);
  If (X >= PvX) And (X < PvX + ImgW) Then VLine(X, PvY, PvY + ImgH - 1, C);
  If (Y >= PvY) And (Y < PvY + ImgH) Then HLine(PvX, PvX + ImgW - 1, Y, C);
  { bornes de la vue }
  S := FStr(WorldX(PvX), 6) + ' ; ' + FStr(WorldY(PvY), 6);
  OutTxt(PvX + 4, PvY + 4, S, cWhite, cBlack);
  S := FStr(WorldX(PvX + ImgW), 6) + ' ; ' + FStr(WorldY(PvY + ImgH), 6);
  OutTxt(PvX + ImgW - 4 - Length(S) * 8, PvY + ImgH - 20, S, cWhite, cBlack);
End;

Procedure PaintPreview;
Var X1, Y1_, X2, Y2 : LongInt;
Begin
  FBar(LsR, Y0, PnX - 1, Y1, cGray);
  Sunken(PvX - 2, PvY - 2, PvX + PvW + 1, PvY + PvH + 1, cBlack);
  If (Img <> Nil) And (ImgW > 0) Then BlitImage;
  If ShowAxes Then PaintAxes;
  If RbOn Then
  Begin
    X1 := MinI(RbX0, RbX1); X2 := MaxI(RbX0, RbX1); Y1_ := MinI(RbY0, RbY1); Y2 := MaxI(RbY0, RbY1);
    Box(X1, Y1_, X2, Y2, cWhite);
    Box(X1 + 1, Y1_ + 1, X2 - 1, Y2 - 1, cBlack);
  End;
End;

{ ==================================================================== }
{ Proprietes (droite)                                                   }
{ ==================================================================== }

Function Z2s(V : LongInt) : String;
Begin
  Z2s := Chr(48 + (V Div 10) Mod 10) + Chr(48 + V Mod 10);
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

Function GridY : LongInt;
Begin
  GridY := Y0 + 54;
End;

Function ValX : LongInt;
Begin
  ValX := PnX + 164;
End;

{ boutons sous la grille : 1 Modifier, 2 Par defaut }
Procedure BtnRect(K : LongInt; Var X1, Y1_, X2, Y2 : LongInt);
Var W : LongInt;
Begin
  BuildPropList(Cur);
  W := (PnW - 34) Div 2;
  X1 := PnX + 12 + (K - 1) * (W + 10); X2 := X1 + W - 1;
  Y1_ := GridY + NPL * RowPH + 8; Y2 := Y1_ + 25;
End;

{ texte coupe aux mots sur la largeur W }
Function WrapOut(X, Y, W : LongInt; S : String; Fg : LongInt) : LongInt;
Var N, K : LongInt; L : String;
Begin
  N := W Div 8;
  While Length(S) > 0 Do
  Begin
    If Length(S) <= N Then
    Begin
      L := S; S := '';
    End
    Else
    Begin
      K := N + 1;
      While (K > 1) And (S[K] <> ' ') Do Dec(K);
      If K <= 1 Then K := N + 1;
      L := Copy(S, 1, K - 1);
      S := Copy(S, K + 1, 255);
    End;
    OutTxt(X, Y, L, Fg, cSilver);
    Y := Y + 16;
  End;
  WrapOut := Y;
End;

Procedure PaintPanel;
Var Y, K, P, X1, Y1_, X2, Y2 : LongInt; S : String;
Begin
  FBar(PnX, Y0, CW - 1, Y1, cSilver);
  VLine(PnX, Y0, Y1, cGray); VLine(PnX + 1, Y0, Y1, cWhite);
  Section(Y0 + 6, 'Propri'#130't'#130's');
  OutTxt(PnX + 12, Y0 + 30, Fit(FracName(Cur), PnW - 24), cBlack, cSilver);
  BuildPropList(Cur);
  Y := GridY;
  Sunken(PnX + 10, Y - 2, CW - 10, Y + NPL * RowPH + 1, cWhite);
  For K := 0 To NPL - 1 Do
  Begin
    P := PL[K];
    S := ValStr(Cur, P, Vals[Cur][P]);
    If K = SelRow Then
    Begin
      FBar(PnX + 12, Y, CW - 12, Y + RowPH - 1, cNavy);
      OutTxt(PnX + 16, Y + 2, Fit(PropLabel(Cur, P), ValX - PnX - 20), cWhite, cNavy);
      OutTxt(ValX + 4, Y + 2, Fit(S, CW - ValX - 18), cWhite, cNavy);
    End
    Else
    Begin
      OutTxt(PnX + 16, Y + 2, Fit(PropLabel(Cur, P), ValX - PnX - 20), cBlack, cWhite);
      OutTxt(ValX + 4, Y + 2, Fit(S, CW - ValX - 18), cBlack, cWhite);
    End;
    VLine(ValX, Y, Y + RowPH - 1, cSilver);
    HLine(PnX + 12, CW - 12, Y + RowPH - 1, cSilver);
    Y := Y + RowPH;
  End;
  For K := 1 To 2 Do
  Begin
    BtnRect(K, X1, Y1_, X2, Y2);
    FBar(X1, Y1_, X2, Y2, cSilver);
    Box(X1, Y1_, X2, Y2, cBlack);
    Edge(X1 + 1, Y1_ + 1, X2 - 1, Y2 - 1, cWhite, cGray);
    If K = 1 Then S := 'Modifier...' Else S := 'Par d'#130'faut';
    OutTxt((X1 + X2) Div 2 - Length(S) * 4, Y1_ + 5, S, cBlack, cSilver);
  End;
  Y := Y2 + 12;
  If Y + 60 < Y1 Then
  Begin
    Section(Y, 'Formule');
    Y := WrapOut(PnX + 14, Y + 24, PnW - 28, FracInfo(Cur), cBlack) + 6;
  End;
  If Y + 80 < Y1 Then
  Begin
    Section(Y, 'Calcul');
    Y := Y + 24;
    InfoLine(Y, 'Image', IStr(ImgW) + ' x ' + IStr(ImgH));
    If JobOn Then InfoLine(Y + 18, 'Temps', 'en cours...')
    Else InfoLine(Y + 18, 'Temps', FStr(LastMs / 1000, 3) + ' s');
    Case FamilyOf(Cur) Of
      fmEscape :
        Begin
          If LastPixels > 0 Then InfoLine(Y + 36, 'Int'#130'rieur', IStr(LastInside * 100 Div LastPixels) + ' %');
          If LastPixels > 0 Then InfoLine(Y + 54, 'It'#130'rations moy.', IStr(LastIter Div LastPixels));
        End;
      fmIfs, fmAttr : InfoLine(Y + 36, 'Points', IStr(Round(Vals[Cur][pPoints])));
    End;
  End;
End;

{ ==================================================================== }
{ Barre d'etat                                                          }
{ ==================================================================== }

Procedure PaintStatus;
Var X, K, W : LongInt; S : String;
Begin
  Raised(0, CH - SbH, CW - 1, CH - 1);
  If JobOn Then
  Begin
    W := 160;
    X := CW - 12 - W;
    Sunken(X - 6, CH - SbH + 2, CW - 4, CH - 3, cSilver);
    K := 0;
    If JobTotal > 0 Then K := (JobPos * (W - 4)) Div JobTotal;
    If K > W - 4 Then K := W - 4;
    Sunken(X, CH - SbH + 4, X + W - 1, CH - 6, cWhite);
    If K > 0 Then FBar(X + 2, CH - SbH + 6, X + 1 + K, CH - 8, cNavy);
  End
  Else
  Begin
    If MouseIn Then S := 'x = ' + FStr(MouseWX, 8) + '  y = ' + FStr(MouseWY, 8)
    Else S := FracName(Cur);
    X := CW - 12 - Length(S) * 8;
    Sunken(X - 6, CH - SbH + 2, CW - 4, CH - 3, cSilver);
    OutTxt(X, CH - SbH + 2, S, cBlack, cSilver);
  End;
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
  If ShowList And (UX1 < LsR) And (UY2 >= Y0) And (UY1 <= Y1) Then PaintList;
  If (UX2 >= LsR) And (UX1 < PnX) And (UY2 >= Y0) And (UY1 <= Y1) Then PaintPreview;
  If ShowProps And (UX2 >= PnX) And (UY2 >= Y0) And (UY1 <= Y1) Then PaintPanel;
  If UY2 >= CH - SbH Then PaintStatus;
  Dummy := WinEndPaint(Hps);
End;
{ ==================================================================== }
{ Boites de dialogue                                                    }
{ ==================================================================== }

Const
  WM_SETFOCUS = $000F;
  WC_COMBOBOX = $FFFF0002;
  MaxDf = 18;
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
  Dummy := WinRegisterClass(Hab, Z('FRDLG'), LongInt(@DlgProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DgClient := 0;
  DgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('FRDLG'), Z2(Title), 0, 0, 0, LongInt(@DgClient));
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
Var H0, H1, H2, K, F : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 80, '~Fichier');
  H1 := MenuOpen;
  It(cmNew, '~Nouveau (valeurs initiales)' + #9 + 'Ctrl+N');
  It(cmOpen, '~Ouvrir des param'#138'tres (.FRC)...' + #9 + 'Ctrl+O');
  It(cmSave, '~Enregistrer' + #9 + 'Ctrl+S');
  It(cmSaveAs, 'Enregistrer ~sous...');
  Sep;
  It(cmExport, 'E~xporter l''image (BMP)...' + #9 + 'Ctrl+E');
  It(cmCopy, 'Co~pier les param'#138'tres' + #9 + 'Ctrl+C');
  Sep;
  It(cmQuit, '~Quitter' + #9 + 'Alt+F4');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 81, 'F~ractale');
  H1 := MenuOpen;
  For F := fmEscape To fmAttr Do
  Begin
    MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 90 + F, '~' + FamilyName(F));
    H2 := MenuOpen;
    For K := 0 To NFrac - 1 Do
      If FamilyOf(K) = F Then ItA(cmFrac0 + K, Chk(Cur = K), FracName(K));
    MenuClose(H2);
  End;
  It(cmPrevFrac, 'Fractale pr'#130'c'#130'~dente' + #9 + 'Pg pr'#130'c');
  It(cmNextFrac, 'Fractale ~suivante' + #9 + 'Pg suiv');
  Sep;
  It(cmGenerate, '~R'#130'g'#130'n'#130'rer' + #9 + 'F5');
  It(cmStop, '~Arr'#136'ter le calcul' + #9 + 'Echap');
  Sep;
  It(cmProps, '~Propri'#130't'#130's...' + #9 + 'F6');
  It(cmEditProp, '~Modifier la propri'#130't'#130' choisie' + #9 + 'Entr'#130'e');
  It(cmDefaults, '~Valeurs par d'#130'faut');
  It(cmDetails, 'D'#130'~tails du calcul...');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 83, '~Affichage');
  H1 := MenuOpen;
  It(cmZoomIn, 'Zoom ~avant' + #9 + '+');
  It(cmZoomOut, 'Zoom a~rri'#138're' + #9 + '-');
  It(cmHome, '~Vue initiale' + #9 + 'Origine');
  Sep;
  ItA(cmAxes, Chk(ShowAxes), 'A~xes et coordonn'#130'es' + #9 + 'A');
  ItA(cmCycle, Chk(Cycling), '~Couleurs anim'#130'es' + #9 + 'C');
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 86, '~Palette');
  H2 := MenuOpen;
  For K := 0 To NPal - 1 Do ItA(cmPal0 + K, Chk(Round(Vals[Cur][pPal]) = K), '~' + PalName(K));
  MenuClose(H2);
  Sep;
  ItA(cmShowList, Chk(ShowList), '~Liste des fractales');
  ItA(cmShowProps, Chk(ShowProps), 'Panneau des pr~opri'#130't'#130's');
  ItA(cmToolbar, Chk(ShowToolbar), '~Barre d''outils');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 84, '~Options');
  H1 := MenuOpen;
  ItA(cmProgressive, Chk(AllowCoarse), 'Aper'#135'u ~rapide, puis image pr'#130'cise');
  ItA(cmThumbs, Chk(ShowThumbs), '~Miniatures dans la liste');
  It(cmExportSize, '~Taille de l''image export'#130'e...');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 85, '~?');
  H1 := MenuOpen;
  It(cmHelp, '~Aide' + #9 + 'F1');
  Sep;
  It(cmAbout, '~A propos...');
  MenuClose(H1);
  MenuClose(H0);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

Procedure SyncMenu;
Var K : LongInt;
Begin
  For K := 0 To NFrac - 1 Do SetCheck(cmFrac0 + K, Cur = K);
  For K := 0 To NPal - 1 Do SetCheck(cmPal0 + K, Round(Vals[Cur][pPal]) = K);
  SetCheck(cmAxes, ShowAxes); SetCheck(cmCycle, Cycling); SetCheck(cmShowList, ShowList);
  SetCheck(cmShowProps, ShowProps); SetCheck(cmToolbar, ShowToolbar); SetCheck(cmProgressive, AllowCoarse);
  SetCheck(cmThumbs, ShowThumbs);
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
  TbAdd(cmNew, 1, '', 'Nouveau : valeurs initiales de la fractale (Ctrl+N)');
  TbAdd(cmOpen, 2, '', 'Ouvrir des param'#138'tres .FRC (Ctrl+O)');
  TbAdd(cmSave, 3, '', 'Enregistrer les param'#138'tres .FRC (Ctrl+S)');
  TbAdd(cmExport, 4, '', 'Exporter l''image en BMP (Ctrl+E)');
  TbAdd(0, 0, '', '');
  TbAdd(cmGenerate, 5, 'G'#130'n'#130'rer', 'R'#130'g'#130'n'#130'rer l''image (F5)');
  TbAdd(cmStop, 6, '', 'Arr'#136'ter le calcul (Echap)');
  TbAdd(0, 0, '', '');
  TbAdd(cmZoomIn, 7, '', 'Zoom avant (+, clic dans l''image)');
  TbAdd(cmZoomOut, 8, '', 'Zoom arri'#138're (-, Maj+clic)');
  TbAdd(cmHome, 9, '', 'Vue initiale (Origine)');
  TbAdd(0, 0, '', '');
  TbAdd(cmAxes, 10, '', 'Axes et coordonn'#130'es (A)');
  TbAdd(cmCycle, 11, 'Couleurs', 'Couleurs anim'#130'es : la palette tourne (C)');
  TbAdd(0, 0, '', '');
  TbAdd(cmProps, 12, '', 'Propri'#130't'#130's (F6)');
  TbAdd(cmHelp, 13, '', 'Aide (F1)');
End;

{ ==================================================================== }
{ Calcul                                                                }
{ ==================================================================== }

Procedure SetTitle;
Var S : String;
Begin
  If FileName <> '' Then S := NameOf(FileName) + ' - ' + AppTitle Else S := FracName(Cur) + ' - ' + AppTitle;
  Dummy := WinSetWindowText(Frame, Z(S));
End;

{ miniatures de la liste : chaque fractale a sa palette, en 24 bits }
Procedure MakeThumbs;
Var T, X, Y, R, Tot, St, A, C : LongInt; Tmp : PBytes;
Begin
  Tot := ThH * NFrac;
  St := ((ThW * 24 + 31) Div 32) * 4;
  GetMem(ThBuf, St * Tot);
  GetMem(Tmp, 64 * ThH);
  FillChar(ThBmi, 16, 0);
  ThBmi[0] := 16; ThBmi[4] := ThW; ThBmi[8] := Tot And 255; ThBmi[9] := Tot Shr 8; ThBmi[12] := 1; ThBmi[14] := 24;
  For T := 0 To NFrac - 1 Do
  Begin
    CV := Vals[T];
    If CV[pIter] > 120 Then CV[pIter] := 120;
    If CV[pPoints] > 40000 Then CV[pPoints] := 40000;
    CV[pThick] := 1;
    If (T = ftHilbert) And (CV[pDepth] > 4) Then CV[pDepth] := 4;
    { la vue est elargie pour la proportion 4:3 }
    FType := T;
    SetImage(Tmp, ThW, ThH);
    BuildPal(CV);
    JobRun;
    For Y := 0 To ThH - 1 Do
    Begin
      R := (Tot - 1) - (T * ThH + Y);
      For X := 0 To ThW - 1 Do
      Begin
        C := Pal[GetPx(X, Y)];
        A := R * St + X * 3;
        ThBuf^[A] := C And 255; ThBuf^[A + 1] := (C Shr 8) And 255; ThBuf^[A + 2] := (C Shr 16) And 255;
      End;
    End;
  End;
  FreeMem(Tmp, 64 * ThH);
  ThReady := True;
End;

Procedure FinishRender;
Begin
  LastMs := JobMs; LastInside := JobInside; LastPixels := JobPixels; LastIter := JobIterSum;
  StatusMsg := FracName(Cur) + ' : image de ' + IStr(ImgW) + ' x ' + IStr(ImgH) + ' calcul'#130'e en ' +
               FStr(JobMs / 1000, 3) + ' s.';
  InvalPanel; InvalStatus;
  InvalBand(0, 0, CW, TbH);
End;

Procedure StartRender;
Begin
  If Img = Nil Then Exit;
  ImgW := PvW; ImgH := PvH;
  CV := Vals[Cur];
  FType := Cur;
  SetImage(Img, ImgW, ImgH);
  BuildPal(CV);
  JobStart;
  If JobOn Then StatusMsg := 'Calcul de ' + FracName(Cur) + '... (Echap : arr'#136'ter)'
  Else FinishRender;
  InvalPreview; InvalPanel; InvalStatus;
  InvalBand(0, 0, CW, TbH);
End;

Procedure CalcTick;
Begin
  If Not JobOn Then Exit;
  If JobStep(70) Then FinishRender;
  InvalPreview; InvalStatus;
End;

Procedure StopRender;
Begin
  If Not JobOn Then Exit;
  JobOn := False;
  If FamilyOf(Cur) <> fmEscape Then ConvertCounts;
  StatusMsg := 'Calcul arr'#136't'#130'.';
  InvalPreview; InvalStatus; InvalPanel;
  InvalBand(0, 0, CW, TbH);
End;

{ couleurs seulement : palette refaite, pas de calcul }
Procedure RecolorOnly;
Begin
  CV[pPal] := Vals[Cur][pPal]; CV[pShift] := Vals[Cur][pShift]; CV[pRev] := Vals[Cur][pRev]; CV[pBack] := Vals[Cur][pBack];
  BuildPal(CV);
  InvalPreview; InvalPanel;
End;

Function IsColorProp(P : LongInt) : Boolean;
Begin
  IsColorProp := (P = pPal) Or (P = pShift) Or (P = pRev) Or (P = pBack);
End;

Procedure ApplyProp(P : LongInt);
Begin
  If IsColorProp(P) Then RecolorOnly Else StartRender;
  SyncMenu;
End;

Procedure EnsureVisible;
Var I, Y, H : LongInt;
Begin
  H := Y1 - 7 - (Y0 + 29);
  For I := 0 To NItem - 1 Do
    If ItKind[I] = Cur Then
    Begin
      Y := ItY[I];
      If Y - ListTop < 0 Then ListTop := Y;
      If Y + ItH[I] - ListTop > H Then ListTop := Y + ItH[I] - H;
    End;
  If ListTop < 0 Then ListTop := 0;
End;

Procedure SelectFrac(T : LongInt);
Begin
  If (T < 0) Or (T >= NFrac) Then Exit;
  If JobOn Then JobOn := False;
  Cur := T;
  BuildPropList(Cur);
  If SelRow >= NPL Then SelRow := 0;
  EnsureVisible;
  SetTitle;
  SyncMenu;
  StartRender;
  InvalList;
End;

{ --- vue --- }

Procedure ResetView;
Var Keep : TProps;
Begin
  Keep := Vals[Cur];
  Preset(Cur);
  Keep[pCx] := Vals[Cur][pCx]; Keep[pCy] := Vals[Cur][pCy]; Keep[pWidth] := Vals[Cur][pWidth];
  Vals[Cur] := Keep;
  StartRender;
End;

Procedure ZoomAt(X, Y : LongInt; F : Double);
Begin
  Vals[Cur][pCx] := WorldX(X); Vals[Cur][pCy] := WorldY(Y);
  Vals[Cur][pWidth] := Vals[Cur][pWidth] * F;
  If Vals[Cur][pWidth] < 1E-13 Then Vals[Cur][pWidth] := 1E-13;
  StartRender;
End;

Procedure ZoomCenter(F : Double);
Begin
  Vals[Cur][pWidth] := Vals[Cur][pWidth] * F;
  If Vals[Cur][pWidth] < 1E-13 Then Vals[Cur][pWidth] := 1E-13;
  StartRender;
End;

Procedure ZoomBox(X1, Y1_, X2, Y2 : LongInt);
Var Wx, Wy : Double;
Begin
  Wx := Abs(WorldX(X2) - WorldX(X1));
  Wy := Abs(WorldY(Y2) - WorldY(Y1_)) * ImgW / MaxI(1, ImgH);
  Vals[Cur][pCx] := (WorldX(X1) + WorldX(X2)) / 2;
  Vals[Cur][pCy] := (WorldY(Y1_) + WorldY(Y2)) / 2;
  If Wy > Wx Then Wx := Wy;
  If Wx < 1E-13 Then Wx := 1E-13;
  Vals[Cur][pWidth] := Wx;
  StartRender;
End;

Procedure Pan(Dx, Dy : Double);
Begin
  Vals[Cur][pCx] := Vals[Cur][pCx] + Dx * Vals[Cur][pWidth];
  Vals[Cur][pCy] := Vals[Cur][pCy] + Dy * Vals[Cur][pWidth];
  StartRender;
End;

{ l'ensemble de Julia du point (X, Y) }
Procedure JuliaAt(X, Y : LongInt);
Var A, B : Double; Keep : TProps;
Begin
  A := WorldX(X); B := WorldY(Y);
  Keep := Vals[ftJulia];
  Preset(ftJulia);
  Keep[pCx] := Vals[ftJulia][pCx]; Keep[pCy] := Vals[ftJulia][pCy]; Keep[pWidth] := Vals[ftJulia][pWidth];
  Keep[pCRe] := A; Keep[pCIm] := B;
  Vals[ftJulia] := Keep;
  SelectFrac(ftJulia);
  StatusMsg := 'Ensemble de Julia de c = ' + FStr(A, 8) + ' + ' + FStr(B, 8) + ' i';
  InvalStatus;
End;

{ --- proprietes --- }

Function RangeStr(P : LongInt) : String;
Var Lo, Hi : Double; R : String;
Begin
  PropRange(P, Lo, Hi);
  If P = pDepth Then Hi := MaxDepth(Cur);
  If (Lo <= -1E8) And (Hi >= 1E8) Then R := ''
  Else R := ' (' + FStr(Lo, 6) + ' '#133' ' + FStr(Hi, 6) + ')';
  RangeStr := R;
End;

{ valeur saisie pour la propriete P ; False si invalide }
Function ReadProp(P : LongInt; S : String; Var V : Double) : Boolean;
Var Lo, Hi, X : Double; Ok : Boolean;
Begin
  PropRange(P, Lo, Hi);
  If P = pDepth Then Hi := MaxDepth(Cur);
  Ok := ParseF(S, X);
  If Ok And (PropKind(P) = pkInt) Then X := Round(X);
  If Ok And ((X < Lo) Or (X > Hi)) Then Ok := False;
  If Ok Then V := X;
  ReadProp := Ok;
End;

Procedure EditProp(K : LongInt);
Var P : LongInt; V : Double; L : String;
Begin
  BuildPropList(Cur);
  If (K < 0) Or (K >= NPL) Then Exit;
  P := PL[K];
  L := PropLabel(Cur, P);
  DlgReset;
  DlgLabel(FracName(Cur));
  Case PropKind(P) Of
    pkEnum : DlgCombo(L + ' :', PropChoices(P), Round(Vals[Cur][P]));
    pkBool : DlgCheck(L, Vals[Cur][P] <> 0);
  Else
    DlgEdit(L + RangeStr(P) + ' :', FStr(Vals[Cur][P], 15));
  End;
  If Not DlgRun('Propri'#130't'#130, 'OK') Then Exit;
  Case PropKind(P) Of
    pkEnum : Vals[Cur][P] := DlgInt(1);
    pkBool : If DlgBool(1) Then Vals[Cur][P] := 1 Else Vals[Cur][P] := 0;
  Else
    If ReadProp(P, DfVal[1], V) Then Vals[Cur][P] := V
    Else
    Begin
      MsgErr('Valeur invalide pour ' + L + RangeStr(P) + '.');
      Exit;
    End;
  End;
  SelRow := K;
  StatusMsg := L + ' = ' + ValStr(Cur, P, Vals[Cur][P]);
  ApplyProp(P);
End;

{ toutes les proprietes de la fractale dans une boite de dialogue }
Procedure PropsDlg;
Var K, P, N : LongInt; V : Double; Bad : String; Lb : Array[0..19] Of String;
Begin
  BuildPropList(Cur);
  N := NPL;
  DlgReset;
  For K := 0 To N - 1 Do
  Begin
    P := PL[K];
    Lb[K] := PropLabel(Cur, P);
    Case PropKind(P) Of
      pkEnum : DlgCombo(Lb[K] + ' :', PropChoices(P), Round(Vals[Cur][P]));
      pkBool : DlgCheck(Lb[K], Vals[Cur][P] <> 0);
    Else
      DlgEdit(Lb[K] + RangeStr(P) + ' :', FStr(Vals[Cur][P], 15));
    End;
  End;
  If Not DlgRun('Propri'#130't'#130's - ' + FracName(Cur), 'Appliquer') Then Exit;
  Bad := '';
  BuildPropList(Cur);
  For K := 0 To N - 1 Do
  Begin
    P := PL[K];
    Case PropKind(P) Of
      pkEnum : Vals[Cur][P] := DlgInt(K);
      pkBool : If DlgBool(K) Then Vals[Cur][P] := 1 Else Vals[Cur][P] := 0;
    Else
      If ReadProp(P, DfVal[K], V) Then Vals[Cur][P] := V
      Else If Bad = '' Then Bad := Lb[K];
    End;
  End;
  If Bad <> '' Then MsgErr('Valeur hors limites (non chang'#130'e) : ' + Bad + '.');
  StartRender;
  SyncMenu;
End;

Procedure Defaults;
Begin
  Preset(Cur);
  StatusMsg := 'Valeurs par d'#130'faut de ' + FracName(Cur) + '.';
  StartRender;
  SyncMenu;
End;

Procedure ShowDetails;
Var S : String;
Begin
  S := FracName(Cur) + #10 + FracInfo(Cur) + #10#10'Image : ' + IStr(ImgW) + ' x ' + IStr(ImgH) + ' points';
  S := S + #10'Vue : centre (' + FStr(Vals[Cur][pCx], 10) + ' ; ' + FStr(Vals[Cur][pCy], 10) + '), largeur ' +
       FStr(Vals[Cur][pWidth], 10);
  S := S + #10'Temps de calcul : ' + FStr(LastMs / 1000, 3) + ' s';
  If (FamilyOf(Cur) = fmEscape) And (LastPixels > 0) Then
    S := S + #10'Points int'#130'rieurs : ' + IStr(LastInside * 100 Div LastPixels) + ' %, it'#130'rations moyennes : ' +
         IStr(LastIter Div LastPixels);
  If (FamilyOf(Cur) = fmIfs) Or (FamilyOf(Cur) = fmAttr) Then
    S := S + #10'Points calcul'#130's : ' + IStr(Round(Vals[Cur][pPoints]));
  Msg(S);
End;
{ ==================================================================== }
{ Fichiers                                                              }
{ ==================================================================== }

Function CanWriteDir(D : String) : Boolean;
Var T, S : String;
Begin
  T := JoinPath(D, 'FRTEST.TMP');
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

Procedure LoadFrc(F : String);
Var T : LongInt; Err : String;
Begin
  T := ReadFrc(F, Err);
  If T < 0 Then
  Begin
    MsgErr('Lecture impossible de ' + F + ' : ' + Err);
    Exit;
  End;
  FileName := F;
  SelectFrac(T);
  StatusMsg := 'Param'#138'tres ouverts : ' + F;
  InvalStatus;
End;

Procedure OpenDlg;
Var L, F : String;
Begin
  DlgReset;
  L := ListFiles(WorkDir, '*.FRC');
  If L = '' Then L := ' (aucun)';
  DlgLabel(Fit('Fichiers de ' + WorkDir + ' :' + L, 590));
  DlgEdit('Fichier de param'#138'tres (.FRC) :', JoinPath(WorkDir, 'FRACTALE.FRC'));
  If Not DlgRun('Ouvrir des param'#138'tres', 'Ouvrir') Then Exit;
  F := FullName(DfVal[1]);
  If ExtOf(F) = '' Then F := F + '.FRC';
  LoadFrc(F);
End;

Procedure SaveDlg(Ask : Boolean);
Var F : String;
Begin
  F := FileName;
  If Ask Or (F = '') Then
  Begin
    DlgReset;
    If F = '' Then F := JoinPath(WorkDir, 'FRACTALE.FRC');
    DlgEdit('Fichier de param'#138'tres (.FRC) :', F);
    DlgLabel('La fractale et ses propri'#130't'#130's, en texte (CLE=valeur).');
    If Not DlgRun('Enregistrer les param'#138'tres', 'Enregistrer') Then Exit;
    F := FullName(DfVal[0]);
    If ExtOf(F) = '' Then F := F + '.FRC';
  End;
  WriteFrc(Cur);
  If WriteAll(F, OutB.P, OutB.Len) Then
  Begin
    FileName := F;
    SetTitle;
    StatusMsg := 'Param'#138'tres enregistr'#130's : ' + F;
  End
  Else MsgErr('Impossible d''enregistrer ' + F + '.');
  InvalStatus;
End;

{ image BMP a la taille W x H (calculee a nouveau si besoin) }
Function ExportBmp(F : String; W, H : LongInt) : Boolean;
Var Tmp : PBytes; Sz : LongInt; Ok : Boolean;
Begin
  { le calcul en cours de l'apercu est termine d'abord }
  While JobOn Do If JobStep(1000) Then FinishRender;
  If (W = ImgW) And (H = ImgH) Then
  Begin
    MakeBmp;
    ExportBmp := WriteAll(F, OutB.P, OutB.Len);
    Exit;
  End;
  Sz := ((W + 3) And Not 3) * H;
  GetMem(Tmp, Sz);
  If Tmp = Nil Then
  Begin
    ExportBmp := False;
    Exit;
  End;
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 3, 0));
  CV := Vals[Cur]; FType := Cur;
  SetImage(Tmp, W, H);
  BuildPal(CV);
  JobRun;
  MakeBmp;
  Ok := WriteAll(F, OutB.P, OutB.Len);
  FreeMem(Tmp, Sz);
  { l'apercu reprend son image }
  SetImage(Img, ImgW, ImgH);
  BuildPal(CV);
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 1, 0));
  ExportBmp := Ok;
End;

Procedure ExportDlg;
Var F : String; W, H : LongInt;
Begin
  DlgReset;
  DlgEdit('Fichier de l''image (.BMP) :', JoinPath(WorkDir, 'FRACTALE.BMP'));
  If ExportW > 0 Then DlgEdit('Largeur (16 '#133' 1280) :', IStr(ExportW)) Else DlgEdit('Largeur (16 '#133' 1280) :', IStr(ImgW));
  If ExportH > 0 Then DlgEdit('Hauteur (16 '#133' 1024) :', IStr(ExportH)) Else DlgEdit('Hauteur (16 '#133' 1024) :', IStr(ImgH));
  DlgLabel('Une autre taille que l''aper'#135'u refait le calcul (256 couleurs).');
  If Not DlgRun('Exporter l''image', 'Exporter') Then Exit;
  F := FullName(DfVal[0]);
  If ExtOf(F) = '' Then F := F + '.BMP';
  If Not ParseNum(DfVal[1], 16, MaxImgW, W) Then W := ImgW;
  If Not ParseNum(DfVal[2], 16, MaxImgH, H) Then H := ImgH;
  StatusMsg := 'Export de ' + F + '...';
  InvalStatus;
  Dummy := WinUpdateWindow(Client);
  If ExportBmp(F, W, H) Then StatusMsg := 'Image export'#130'e : ' + F + ' (' + IStr(W) + ' x ' + IStr(H) + ')'
  Else MsgErr('Impossible d'''#130'crire ' + F + '.');
  InvalPreview; InvalStatus;
End;

Procedure ExportSizeDlg;
Var W, H : LongInt;
Begin
  DlgReset;
  DlgLabel('Rien : la taille de l''aper'#135'u (' + IStr(ImgW) + ' x ' + IStr(ImgH) + ').');
  If ExportW > 0 Then DlgEdit('Largeur (16 '#133' 1280) :', IStr(ExportW)) Else DlgEdit('Largeur (16 '#133' 1280) :', '');
  If ExportH > 0 Then DlgEdit('Hauteur (16 '#133' 1024) :', IStr(ExportH)) Else DlgEdit('Hauteur (16 '#133' 1024) :', '');
  If Not DlgRun('Taille de l''image export'#130'e', 'OK') Then Exit;
  If ParseNum(DfVal[1], 16, MaxImgW, W) Then ExportW := W Else ExportW := 0;
  If ParseNum(DfVal[2], 16, MaxImgH, H) Then ExportH := H Else ExportH := 0;
End;

Procedure CopyParams;
Var T : PBytes; N : LongInt;
Begin
  WriteFrc(Cur);
  N := OutB.Len;
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
  StatusMsg := 'Param'#138'tres copi'#130's dans le presse-papiers.';
  InvalStatus;
End;

Procedure ShowHelp;
Var B : TBuf;
Begin
  BufInit(B);
  BufAdd(B, 'Choisissez une fractale dans la liste de gauche ; ses propri'#130't'#130's sont '#133' droite : un clic ');
  BufAdd(B, 'choisit une ligne, un double clic (ou Entr'#130'e) la modifie ; F6 les montre toutes.'#10#10);
  BufAdd(B, 'Dans l''image : clic = zoom avant au point, Maj+clic = zoom arri'#138're, glisser = rectangle qui ');
  BufAdd(B, 'devient la vue, bouton 2 = menu (centrer, ensemble de Julia du point...). Fl'#138'ches : d'#130'placer ; ');
  BufAdd(B, '+ et - : zoom ; Origine : vue initiale ; Pg pr'#130'c / Pg suiv : fractale pr'#130'c'#130'dente / suivante.'#10#10);
  BufAdd(B, 'F5 : r'#130'g'#130'n'#130'rer ; Echap : arr'#136'ter ; A : axes ; C : couleurs anim'#130'es ; ');
  BufAdd(B, 'Ctrl+O, Ctrl+S : ouvrir, enregistrer les param'#138'tres (.FRC) ; Ctrl+E : exporter l''image (BMP). ');
  BufAdd(B, 'Changer la palette ne refait pas le calcul (image en 256 couleurs).'#10#10);
  BufAdd(B, 'FRACTAL [fichier.FRC] [/F:nom] [/BMP:image] [/W:largeur] [/H:hauteur] [/ITER:n] [/PAL:n] : ');
  BufAdd(B, 'avec /BMP, l''image est calcul'#130'e et '#130'crite sans fen'#136'tre.');
  ShowBuf('Aide du ' + AppTitle, B);
  BufFree(B);
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Procedure DoCmd(C : LongInt);
Begin
  If (C >= cmFrac0) And (C < cmFrac0 + NFrac) Then
  Begin
    SelectFrac(C - cmFrac0);
    Exit;
  End;
  If (C >= cmPal0) And (C < cmPal0 + NPal) Then
  Begin
    Vals[Cur][pPal] := C - cmPal0;
    ApplyProp(pPal);
    Exit;
  End;
  Case C Of
    cmNew : Begin FileName := ''; SetTitle; Defaults; End;
    cmOpen : OpenDlg;
    cmSave : SaveDlg(False);
    cmSaveAs : SaveDlg(True);
    cmExport : ExportDlg;
    cmCopy : CopyParams;
    cmQuit : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    cmGenerate : StartRender;
    cmStop : StopRender;
    cmProps : PropsDlg;
    cmEditProp : EditProp(SelRow);
    cmDefaults : Defaults;
    cmDetails : ShowDetails;
    cmPrevFrac : SelectFrac((Cur + NFrac - 1) Mod NFrac);
    cmNextFrac : SelectFrac((Cur + 1) Mod NFrac);
    cmZoomIn : ZoomCenter(0.5);
    cmZoomOut : ZoomCenter(2);
    cmHome : ResetView;
    cmCenter : ZoomAt(RbX0, RbY0, 1);
    cmJulia : JuliaAt(RbX0, RbY0);
    cmAxes : Begin ShowAxes := Not ShowAxes; SyncMenu; InvalPreview; End;
    cmCycle :
      Begin
        Cycling := Not Cycling;
        If Cycling Then Dummy := WinStartTimer(Hab, Client, 2, 150) Else Dummy := WinStopTimer(Hab, Client, 2);
        SyncMenu;
      End;
    cmShowList : Begin ShowList := Not ShowList; SyncMenu; Layout; StartRender; Redraw; End;
    cmShowProps : Begin ShowProps := Not ShowProps; SyncMenu; Layout; StartRender; Redraw; End;
    cmToolbar : Begin ShowToolbar := Not ShowToolbar; SyncMenu; Layout; StartRender; Redraw; End;
    cmProgressive : Begin AllowCoarse := Not AllowCoarse; SyncMenu; End;
    cmThumbs : Begin ShowThumbs := Not ShowThumbs; SyncMenu; InvalList; End;
    cmExportSize : ExportSizeDlg;
    cmHelp : ShowHelp;
    cmAbout :
      Msg(AppTitle + ' pour OS/2-0' + #10#10 + IStr(NFrac) + ' fractales pr'#130'd'#130'finies : temps d'''#130'chappement, ' +
          'fonctions it'#130'r'#130'es, courbes et arbres, attracteurs '#130'tranges.' + #10#10 + 'Gladir.com');
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

Function InPreview(X, Y : LongInt) : Boolean;
Begin
  InPreview := (X >= PvX) And (Y >= PvY) And (X < PvX + ImgW) And (Y < PvY + ImgH);
End;

{ ligne de la grille des proprietes (-1 : aucune) }
Function PropRowAt(Y : LongInt) : LongInt;
Var K : LongInt;
Begin
  BuildPropList(Cur);
  K := (Y - GridY) Div RowPH;
  If (Y < GridY) Or (K >= NPL) Then K := -1;
  PropRowAt := K;
End;

Procedure MouseDown(X, Y : LongInt; Dbl, Shift : Boolean);
Var T, K, X1, Y1_, X2, Y2 : LongInt;
Begin
  If ShowToolbar And (Y < TbH) Then
  Begin
    ToolbarDown(X);
    Exit;
  End;
  If Y >= CH - SbH Then Exit;
  If ShowList And (X < LsR) Then
  Begin
    T := ListHit(X, Y);
    If (T >= 0) And (T <> Cur) Then SelectFrac(T);
    Exit;
  End;
  If ShowProps And (X >= PnX) Then
  Begin
    K := PropRowAt(Y);
    If K >= 0 Then
    Begin
      SelRow := K;
      InvalPanel;
      If Dbl Or (X >= ValX) Then EditProp(K);
      Exit;
    End;
    For K := 1 To 2 Do
    Begin
      BtnRect(K, X1, Y1_, X2, Y2);
      If (X >= X1) And (X <= X2) And (Y >= Y1_) And (Y <= Y2) Then
      Begin
        If K = 1 Then EditProp(SelRow) Else Defaults;
        Exit;
      End;
    End;
    Exit;
  End;
  If InPreview(X, Y) Then
  Begin
    RbX0 := X; RbY0 := Y; RbX1 := X; RbY1 := Y;
    If Shift Then
    Begin
      ZoomAt(X, Y, 2);
      Exit;
    End;
    Drag := dRb; RbOn := False;
    Dummy := WinSetCapture(HWND_DESKTOP, Client);
  End;
End;

Procedure MouseMove(X, Y : LongInt);
Var I, H, Ox1, Oy1, Ox2, Oy2 : LongInt; Was : Boolean;
Begin
  If Drag = dTool Then Exit;
  If Drag = dRb Then
  Begin
    Ox1 := MinI(RbX0, RbX1); Ox2 := MaxI(RbX0, RbX1); Oy1 := MinI(RbY0, RbY1); Oy2 := MaxI(RbY0, RbY1);
    RbX1 := MaxI(PvX, MinI(PvX + ImgW - 1, X)); RbY1 := MaxI(PvY, MinI(PvY + ImgH - 1, Y));
    If (Abs(RbX1 - RbX0) > 4) Or (Abs(RbY1 - RbY0) > 4) Then RbOn := True;
    If RbOn Then
    Begin
      InvalBand(Ox1 - 1, Oy1 - 1, Ox2 + 2, Oy2 + 2);
      InvalBand(MinI(RbX0, RbX1) - 1, MinI(RbY0, RbY1) - 1, MaxI(RbX0, RbX1) + 2, MaxI(RbY0, RbY1) + 2);
    End;
  End;
  Was := MouseIn;
  MouseIn := InPreview(X, Y);
  If MouseIn Then
  Begin
    MouseWX := WorldX(X); MouseWY := WorldY(Y);
  End;
  If MouseIn Or Was Then InvalStatus;
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
  End
  Else If Drag = dRb Then
  Begin
    Dummy := WinSetCapture(HWND_DESKTOP, 0);
    Drag := dNone;
    If RbOn Then
    Begin
      RbOn := False;
      ZoomBox(RbX0, RbY0, RbX1, RbY1);
    End
    Else ZoomAt(RbX0, RbY0, 0.5);
  End;
End;

Procedure RightClick(X, Y : LongInt);
Var H, K : LongInt;
Begin
  MenuLen := 0;
  If ShowProps And (X >= PnX) Then
  Begin
    K := PropRowAt(Y);
    If K >= 0 Then
    Begin
      SelRow := K;
      InvalPanel;
    End;
    H := MenuOpen;
    It(cmEditProp, '~Modifier...' + #9 + 'Entr'#130'e');
    It(cmProps, 'Toutes les ~propri'#130't'#130's...' + #9 + 'F6');
    It(cmDefaults, '~Valeurs par d'#130'faut');
    MenuClose(H);
    ShowPopup(X, Y);
    Exit;
  End;
  If Not InPreview(X, Y) Then Exit;
  RbX0 := X; RbY0 := Y;
  H := MenuOpen;
  It(cmZoomIn, 'Zoom ~avant' + #9 + '+');
  It(cmZoomOut, 'Zoom a~rri'#138're' + #9 + '-');
  It(cmCenter, '~Centrer ici');
  It(cmHome, '~Vue initiale' + #9 + 'Origine');
  If (Cur = ftMandel) Or (Cur = ftMulti) Or (Cur = ftShip) Or (Cur = ftTricorn) Then
  Begin
    Sep;
    It(cmJulia, 'Ensemble de ~Julia de ce point');
  End;
  Sep;
  It(cmGenerate, 'R'#130'g'#130'~n'#130'rer' + #9 + 'F5');
  It(cmProps, '~Propri'#130't'#130's...' + #9 + 'F6');
  It(cmExport, 'E~xporter l''image...' + #9 + 'Ctrl+E');
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
      VK_F5 : Begin DoCmd(cmGenerate); Exit; End;
      VK_F6 : Begin DoCmd(cmProps); Exit; End;
      VK_ESC : Begin DoCmd(cmStop); Exit; End;
      VK_LEFT : Begin Pan(-0.2, 0); Exit; End;
      VK_RIGHT : Begin Pan(0.2, 0); Exit; End;
      VK_UP : Begin Pan(0, 0.2); Exit; End;
      VK_DOWN : Begin Pan(0, -0.2); Exit; End;
      VK_PAGEUP : Begin DoCmd(cmPrevFrac); Exit; End;
      VK_PAGEDOWN : Begin DoCmd(cmNextFrac); Exit; End;
      VK_HOME : Begin DoCmd(cmHome); Exit; End;
      VK_NEWLINE, VK_ENTER : Begin DoCmd(cmEditProp); Exit; End;
      VK_TAB, VK_BACKTAB :
        Begin
          BuildPropList(Cur);
          If Shift Or (Vk = VK_BACKTAB) Then SelRow := (SelRow + NPL - 1) Mod NPL Else SelRow := (SelRow + 1) Mod NPL;
          InvalPanel;
          Exit;
        End;
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
      Ord('s') : Begin DoCmd(cmSave); Exit; End;
      Ord('e') : Begin DoCmd(cmExport); Exit; End;
      Ord('c') : Begin DoCmd(cmCopy); Exit; End;
    End;
  End;
  If ((Fl_ And KC_CHAR) <> 0) And Not Ctrl And ((Fl_ And KC_ALT) = 0) Then
  Begin
    K := Ch_;
    If (K >= Ord('A')) And (K <= Ord('Z')) Then K := K + 32;
    Case K Of
      Ord('+') : Begin DoCmd(cmZoomIn); Exit; End;
      Ord('-') : Begin DoCmd(cmZoomOut); Exit; End;
      Ord('a') : Begin DoCmd(cmAxes); Exit; End;
      Ord('c') : Begin DoCmd(cmCycle); Exit; End;
    End;
  End;
  Key := False;
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

Function ClientProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; X, Y, Ow, Oh : LongInt;
Begin
  ClientProc := 0;
  Case Msg_ Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
        Ow := PvW; Oh := PvH;
        Layout;
        If (Img <> Nil) And ((Ow <> PvW) Or (Oh <> PvH)) Then StartRender;
        Redraw;
      End;
    WM_PAINT : Paint(H);
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
      Begin
        X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        LastMx := X; LastMy := Y;
        MouseDown(X, Y, Msg_ = WM_BUTTON1DBLCLK, (Hi16(Mp2) And KC_SHIFT) <> 0);
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
      If Lo16(Mp1) = 2 Then
      Begin
        { couleurs animees : la palette tourne, sans calcul }
        Vals[Cur][pShift] := (Round(Vals[Cur][pShift]) + 3) Mod 255;
        RecolorOnly;
      End
      Else CalcTick;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Parametres et mode sans fenetre (/BMP)                                }
{ ==================================================================== }

Var
  CliFile, CliBmp, CliErr, CliSum : String;
  CliW, CliH, CliFrac, CliIter, CliPal : LongInt;

Procedure ParseArgs;
Var I, P, Q, V, K : LongInt; A, U, Name, S : String;
Begin
  CliFile := ''; CliBmp := ''; CliErr := ''; CliSum := ''; CliW := 640; CliH := 480; CliFrac := -1; CliIter := -1; CliPal := -1;
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
      If Name = 'BMP' Then CliBmp := S
      Else If Name = 'SUM' Then CliSum := S
      Else If Name = 'W' Then
      Begin
        If Not ParseNum(S, 16, MaxImgW, CliW) Then CliErr := 'Largeur invalide : ' + S;
      End
      Else If Name = 'H' Then
      Begin
        If Not ParseNum(S, 16, MaxImgH, CliH) Then CliErr := 'Hauteur invalide : ' + S;
      End
      Else If Name = 'ITER' Then
      Begin
        If Not ParseNum(S, 4, 100000, CliIter) Then CliErr := 'It'#130'rations invalides : ' + S;
      End
      Else If Name = 'PAL' Then
      Begin
        If Not ParseNum(S, 0, NPal - 1, CliPal) Then
          For K := 0 To NPal - 1 Do If UpStr(PalName(K)) = UpStr(S) Then CliPal := K;
        If CliPal < 0 Then CliErr := 'Palette invalide : ' + S;
      End
      Else If Name = 'F' Then
      Begin
        If Not ParseNum(S, 0, NFrac - 1, CliFrac) Then
          For K := 0 To NFrac - 1 Do If FracKey(K) = UpStr(S) Then CliFrac := K;
        If CliFrac < 0 Then CliErr := 'Fractale inconnue : ' + S;
      End
      Else If (Name <> '?') And (Name <> 'H') Then CliErr := 'Option inconnue : ' + A;
    End
    Else CliFile := A;
  End;
  If V = 0 Then ;
End;

Procedure ApplyCli;
Begin
  If CliIter > 0 Then Vals[Cur][pIter] := CliIter;
  If CliPal >= 0 Then Vals[Cur][pPal] := CliPal;
End;

Function HexL(V : LongInt) : String;
Var K, D : LongInt; R : String;
Begin
  R := '';
  For K := 7 DownTo 0 Do
  Begin
    D := (V Shr (K * 4)) And 15;
    If D < 10 Then R := R + Chr(48 + D) Else R := R + Chr(55 + D);
  End;
  HexL := R;
End;

Procedure Batch;
Var Buf : PBytes; T, H, N, X, Y, K : LongInt; Err, S : String;
Begin
  Cur := ftMandel;
  If CliFile <> '' Then
  Begin
    T := ReadFrc(CliFile, Err);
    If T < 0 Then Halt(2);
    Cur := T;
  End;
  If CliFrac >= 0 Then Cur := CliFrac;
  ApplyCli;
  GetMem(Buf, ((CliW + 3) And Not 3) * CliH);
  CV := Vals[Cur]; FType := Cur;
  SetImage(Buf, CliW, CliH);
  BuildPal(CV);
  JobRun;
  MakeBmp;
  If Not WriteAll(CliBmp, OutB.P, OutB.Len) Then Halt(2);
  If CliSum <> '' Then
  Begin
    { somme FNV-1a des pixels (lignes sans le remplissage) et proportion de fond }
    H := LongInt($811C9DC5); N := 0;
    For Y := 0 To CliH - 1 Do
      For X := 0 To CliW - 1 Do
      Begin
        K := GetPx(X, Y);
        If K = 0 Then Inc(N);
        H := (H Xor K) * 16777619;
      End;
    S := FracKey(Cur) + ' ' + IStr(CliW) + 'x' + IStr(CliH) + ' SOMME=' + HexL(H) + ' FOND=' + IStr(N * 100 Div (CliW * CliH)) + '%';
    S := S + #13#10;
    If Not WriteAll(CliSum, @S[1], Length(S)) Then Halt(2);
  End;
End;

Procedure Main;
Var Fl0, Sw, Sh, Fw, Fh : LongInt;
Begin
  InitEngine;
  AllowCoarse := True;
  ShowAxes := False; Cycling := False; ShowToolbar := True; ShowList := True; ShowProps := True; ShowThumbs := True;
  ThReady := False; SelRow := 0; ListTop := 0; RbOn := False; MouseIn := False;
  ExportW := 0; ExportH := 0; LastMs := 0; LastInside := 0; LastPixels := 0; LastIter := 0;
  CtxMenu := 0; Drag := dNone; StatusMsg := 'Pr'#136't.'; SavedMsg := ''; FileName := '';
  Img := Nil; ImgW := 0; ImgH := 0; Cur := ftMandel;
  ParseArgs;
  If (CliBmp <> '') Or (CliSum <> '') Then
  Begin
    If CliBmp = '' Then CliBmp := 'D:\FRACTAL.BMP';
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
  Dummy := WinRegisterClass(Hab, Z('FRACTAL'), LongInt(@ClientProc), 0, 0);
  Fl0 := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl0), Z('FRACTAL'), Z2(AppTitle), 0, 0, 0, LongInt(@Client));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Fw := MinI(Sw, 640); Fh := MinI(Sh - 20, 460);
  If Sw >= 1000 Then
  Begin
    Fw := 1000; Fh := MinI(Sh - 40, 700);
  End
  Else If Sw >= 800 Then
  Begin
    Fw := 796; Fh := MinI(Sh - 30, 560);
  End;
  CW := Fw - 8; CH := Fh - 40;
  GetMem(Img, ((MaxImgW + 3) And Not 3) * MaxImgH);
  MakeThumbs;
  If CliFile <> '' Then
  Begin
    If ReadFrc(CliFile, CliErr) >= 0 Then
    Begin
      Cur := ReadFrc(CliFile, CliErr);
      FileName := CliFile;
    End;
  End;
  If CliFrac >= 0 Then Cur := CliFrac;
  ApplyCli;
  BuildMenu;
  SetTitle;
  Layout;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Layout;
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  Dummy := WinStartTimer(Hab, Client, 1, 20);
  If CliErr <> '' Then MsgErr(CliErr);
  EnsureVisible;
  StartRender;
  While WinGetMsg(Hab, LongInt(@GQmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@GQmsg));
  Dummy := WinDestroyWindow(Frame);
End;

BEGIN
  Main;
END.
