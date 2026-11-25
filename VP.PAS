{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: VP - Visual Pascal, environnement de developpement visuel
                dans l'esprit de Visual Basic 6 pour le Presentation
                Manager d'OS/2-0 ; le code est du Pascal compile par OS2PC.
}

Program VisualPascal;

{$R-,S-,I-}

(* Compilation : OS2PC VP.PAS VP.EXE

  Visual Pascal (dossier Developer Kit du bureau) : on dessine des feuilles
  (fenetres) en y posant des controles, on ecrit en Pascal le code de leurs
  evenements, et Visual Pascal en fait un programme du Presentation Manager
  compile par OS2PC.EXE, le compilateur d'OS/2-0. L'apparence et les menus
  sont ceux d'OS/2 :
    - en haut, les menus et la barre d'icones (nouveau projet, ouvrir,
      enregistrer, ajouter une feuille, couper, copier, coller, executer,
      arreter, code, objet) ;
    - a gauche, la boite a outils verticale des controles : pointeur,
      Label, TextBox, CommandButton, Frame, CheckBox, OptionButton,
      ListBox, ComboBox, Timer ;
    - au centre, la feuille en cours de conception (grille de points,
      poignees pour deplacer et redimensionner) ou la fenetre de code de
      la feuille (listes Objet et Procedure, coloration du Pascal) ;
    - a droite, l'explorateur de projet (les feuilles) et la fenetre des
      proprietes (Name, Caption, Text, Left, Top, Width, Height, Enabled,
      Visible...), avec la description de la propriete choisie.
  Comme en Visual Basic, le code accede aux controles par leurs proprietes
  et methodes : Text1.Text := Text1.Text + '7'; List1.AddItem('x');
  Visual Pascal reecrit ces acces en appels de sa bibliotheque d'execution
  (VPSetText(Text1, ...)), qu'il ajoute au programme genere.

  Fichier d'un projet : .VPP (texte : feuilles, controles, proprietes et
  code). Fichier - Exemples : Calculatrice, Demonstration.

  Parametres : un fichier .VPP ; /EXEMPLE nom ; /MAKE fichier.EXE compile
  le projet et ferme Visual Pascal (essais automatiques), /RUN le compile
  et l'execute ; /LOG fichier y copie la fenetre Messages. *)

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

Function LangOf(N : String) : LongInt;
Begin
  LangOf := lgPas;
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
{ Documents : lignes de longueur quelconque, annuler et retablir        }
{ ==================================================================== }

Const
  opSet = 1; opIns = 2; opDel = 3;
  MaxU = 2000;

Type
  TUndo = Record
    Op, Y, Len, Grp, CX, CY : LongInt;
    P : PBytes;
  End;
  TUndoArr = Array[0..MaxU - 1] Of TUndo;
  PUndoArr = ^TUndoArr;

Var
  DUsed, DMod : Array[0..MaxDoc - 1] Of Boolean;
  DName : Array[0..MaxDoc - 1] Of String;
  DLang, DUtf8, DCrlf, DN, DNCap : Array[0..MaxDoc - 1] Of LongInt;
  DLp, DLn, DLc, DSt : Array[0..MaxDoc - 1] Of PLongs;    { pointeur, longueur, capacite, etat }
  DStOk : Array[0..MaxDoc - 1] Of LongInt;                { etats justes jusqu'a cette ligne }
  DCX, DCY, DAX, DAY, DTop, DLeft, DWant : Array[0..MaxDoc - 1] Of LongInt;
  DSel : Array[0..MaxDoc - 1] Of Boolean;
  DUnd, DRed : Array[0..MaxDoc - 1] Of PUndoArr;
  DUN, DRN, DGrp, DLastKind, DLastY : Array[0..MaxDoc - 1] Of LongInt;
  NDoc, Cur : LongInt;          { documents ouverts, document actif (-1 : aucun) }
  Order : Array[0..MaxDoc - 1] Of LongInt;   { ordre des onglets }
  Tmp : TBuf;

Function LP(D, Y : LongInt) : PBytes;
Begin
  LP := Pointer(DLp[D]^[Y]);
End;

Function LLen(D, Y : LongInt) : LongInt;
Begin
  If (Y < 0) Or (Y >= DN[D]) Then LLen := 0 Else LLen := DLn[D]^[Y];
End;

Function LChar(D, Y, X : LongInt) : LongInt;
Var P : PBytes;
Begin
  If (Y < 0) Or (Y >= DN[D]) Or (X < 0) Or (X >= DLn[D]^[Y]) Then LChar := 0
  Else
  Begin
    P := LP(D, Y);
    LChar := P^[X];
  End;
End;

{ texte d'une ligne (255 premiers caracteres) }
Function LStr(D, Y : LongInt) : String;
Var S : String; N : LongInt; P : PBytes;
Begin
  N := LLen(D, Y);
  If N > 255 Then N := 255;
  S[0] := Chr(N);
  If N > 0 Then
  Begin
    P := LP(D, Y);
    Move(P^[0], S[1], N);
  End;
  LStr := S;
End;

Procedure StInvalid(D, Y : LongInt);
Begin
  If Y < DStOk[D] Then DStOk[D] := Y;
  If DStOk[D] < 0 Then DStOk[D] := 0;
End;

Function ArrGrow(D, Need : LongInt) : Boolean;
Var NC : LongInt; A, B, C, E : PLongs;
Begin
  ArrGrow := True;
  If Need <= DNCap[D] Then Exit;
  NC := DNCap[D] * 2;
  If NC < 256 Then NC := 256;
  While NC < Need Do NC := NC * 2;
  GetMem(A, NC * 4); GetMem(B, NC * 4); GetMem(C, NC * 4); GetMem(E, NC * 4);
  If (A = Nil) Or (B = Nil) Or (C = Nil) Or (E = Nil) Then
  Begin
    ArrGrow := False;
    Exit;
  End;
  If DN[D] > 0 Then
  Begin
    Move(DLp[D]^[0], A^[0], DN[D] * 4); Move(DLn[D]^[0], B^[0], DN[D] * 4);
    Move(DLc[D]^[0], C^[0], DN[D] * 4); Move(DSt[D]^[0], E^[0], DN[D] * 4);
  End;
  If DNCap[D] > 0 Then
  Begin
    FreeMem(DLp[D], DNCap[D] * 4); FreeMem(DLn[D], DNCap[D] * 4);
    FreeMem(DLc[D], DNCap[D] * 4); FreeMem(DSt[D], DNCap[D] * 4);
  End;
  DLp[D] := A; DLn[D] := B; DLc[D] := C; DSt[D] := E;
  DNCap[D] := NC;
End;

{ --- primitives sans memoire d'annulation --- }

Procedure RawSet(D, Y : LongInt; P : PBytes; N : LongInt);
Var Q : PBytes; C : LongInt;
Begin
  If N > DLc[D]^[Y] Then
  Begin
    C := (N + 32) And Not 15;
    GetMem(Q, C);
    If Q = Nil Then Exit;
    If DLc[D]^[Y] > 0 Then FreeMem(Pointer(DLp[D]^[Y]), DLc[D]^[Y]);
    DLp[D]^[Y] := LongInt(Q); DLc[D]^[Y] := C;
  End;
  If N > 0 Then
  Begin
    Q := Pointer(DLp[D]^[Y]);
    Move(P^[0], Q^[0], N);
  End;
  DLn[D]^[Y] := N;
  StInvalid(D, Y);
End;

Procedure RawIns(D, Y : LongInt; P : PBytes; N : LongInt);
Var K : LongInt;
Begin
  If Not ArrGrow(D, DN[D] + 1) Then Exit;
  For K := DN[D] - 1 DownTo Y Do
  Begin
    DLp[D]^[K + 1] := DLp[D]^[K]; DLn[D]^[K + 1] := DLn[D]^[K];
    DLc[D]^[K + 1] := DLc[D]^[K]; DSt[D]^[K + 1] := DSt[D]^[K];
  End;
  DLp[D]^[Y] := 0; DLn[D]^[Y] := 0; DLc[D]^[Y] := 0;
  Inc(DN[D]);
  RawSet(D, Y, P, N);
End;

Procedure RawDel(D, Y : LongInt);
Var K : LongInt;
Begin
  If (Y < 0) Or (Y >= DN[D]) Then Exit;
  If DLc[D]^[Y] > 0 Then FreeMem(Pointer(DLp[D]^[Y]), DLc[D]^[Y]);
  For K := Y To DN[D] - 2 Do
  Begin
    DLp[D]^[K] := DLp[D]^[K + 1]; DLn[D]^[K] := DLn[D]^[K + 1];
    DLc[D]^[K] := DLc[D]^[K + 1]; DSt[D]^[K] := DSt[D]^[K + 1];
  End;
  Dec(DN[D]);
  StInvalid(D, Y);
End;

{ --- annuler, retablir --- }

Procedure UFreeEntry(Var U : TUndo);
Begin
  If (U.P <> Nil) And (U.Len > 0) Then FreeMem(U.P, U.Len);
  U.P := Nil;
End;

Procedure UPush(D : LongInt; Redo : Boolean; Op, Y : LongInt; P : PBytes; N : LongInt);
Var A : PUndoArr; Cnt, K : LongInt; Q : PBytes;
Begin
  If Redo Then
  Begin
    A := DRed[D]; Cnt := DRN[D];
  End
  Else
  Begin
    A := DUnd[D]; Cnt := DUN[D];
  End;
  If A = Nil Then Exit;
  If Cnt >= MaxU Then
  Begin
    { plein : oublier le plus ancien quart }
    For K := 0 To MaxU Div 4 - 1 Do UFreeEntry(A^[K]);
    Move(A^[MaxU Div 4], A^[0], (MaxU - MaxU Div 4) * SizeOf(TUndo));
    Cnt := MaxU - MaxU Div 4;
  End;
  Q := Nil;
  If N > 0 Then
  Begin
    GetMem(Q, N);
    If Q <> Nil Then Move(P^[0], Q^[0], N) Else N := 0;
  End;
  A^[Cnt].Op := Op; A^[Cnt].Y := Y; A^[Cnt].P := Q; A^[Cnt].Len := N; A^[Cnt].Grp := DGrp[D];
  A^[Cnt].CX := DCX[D]; A^[Cnt].CY := DCY[D];
  Inc(Cnt);
  If Redo Then DRN[D] := Cnt Else DUN[D] := Cnt;
End;

Procedure RedoClear(D : LongInt);
Var K : LongInt;
Begin
  If DRed[D] = Nil Then Exit;
  For K := 0 To DRN[D] - 1 Do UFreeEntry(DRed[D]^[K]);
  DRN[D] := 0;
End;

{ nouvelle operation de l'utilisateur ; Kind 1 : frappe (regroupee sur
  la meme ligne) }
Procedure BeginEdit(D, Kind : LongInt);
Begin
  If (Kind = 1) And (DLastKind[D] = 1) And (DLastY[D] = DCY[D]) Then Exit;
  Inc(DGrp[D]);
  DLastKind[D] := Kind; DLastY[D] := DCY[D];
  RedoClear(D);
End;

{ --- primitives avec memoire d'annulation --- }

Procedure USet(D, Y : LongInt; P : PBytes; N : LongInt);
Begin
  UPush(D, False, opSet, Y, LP(D, Y), LLen(D, Y));
  RawSet(D, Y, P, N);
  DMod[D] := True;
End;

Procedure UIns(D, Y : LongInt; P : PBytes; N : LongInt);
Begin
  UPush(D, False, opIns, Y, Nil, 0);
  RawIns(D, Y, P, N);
  DMod[D] := True;
End;

Procedure UDel(D, Y : LongInt);
Begin
  UPush(D, False, opDel, Y, LP(D, Y), LLen(D, Y));
  RawDel(D, Y);
  DMod[D] := True;
End;

{ defaire le dernier groupe (Redo : refaire) }
Procedure UndoRedo(D : LongInt; Redo : Boolean);
Var A : PUndoArr; Cnt, G, Y : LongInt; U : TUndo;
Begin
  If Redo Then
  Begin
    A := DRed[D]; Cnt := DRN[D];
  End
  Else
  Begin
    A := DUnd[D]; Cnt := DUN[D];
  End;
  If (A = Nil) Or (Cnt = 0) Then Exit;
  G := A^[Cnt - 1].Grp;
  DSel[D] := False;
  While (Cnt > 0) And (A^[Cnt - 1].Grp = G) Do
  Begin
    U := A^[Cnt - 1];
    Dec(Cnt);
    If Redo Then DRN[D] := Cnt Else DUN[D] := Cnt;
    Y := U.Y;
    { l'inverse va dans l'autre pile }
    Case U.Op Of
      opSet :
        Begin
          UPush(D, Not Redo, opSet, Y, LP(D, Y), LLen(D, Y));
          RawSet(D, Y, U.P, U.Len);
        End;
      opIns :
        Begin
          UPush(D, Not Redo, opDel, Y, LP(D, Y), LLen(D, Y));
          RawDel(D, Y);
        End;
      opDel :
        Begin
          UPush(D, Not Redo, opIns, Y, Nil, 0);
          RawIns(D, Y, U.P, U.Len);
        End;
    End;
    DCX[D] := U.CX; DCY[D] := U.CY;
    UFreeEntry(U);
  End;
  If DN[D] = 0 Then RawIns(D, 0, Nil, 0);
  If DCY[D] >= DN[D] Then DCY[D] := DN[D] - 1;
  If DCX[D] > LLen(D, DCY[D]) Then DCX[D] := LLen(D, DCY[D]);
  DMod[D] := True;
  DLastKind[D] := 0;
End;

{ --- operations sur le texte --- }

{ inserer N octets en (Y, X) dans la ligne }
Procedure InsChars(D, Y, X : LongInt; P : PBytes; N : LongInt);
Var L : LongInt; Q : PBytes;
Begin
  L := LLen(D, Y);
  If X > L Then X := L;
  Tmp.Len := 0;
  Q := LP(D, Y);
  If X > 0 Then BufAddB(Tmp, Q, X);
  BufAddB(Tmp, P, N);
  If L > X Then BufAddB(Tmp, @Q^[X], L - X);
  USet(D, Y, Tmp.P, Tmp.Len);
End;

Procedure DelChars(D, Y, X, N : LongInt);
Var L : LongInt; Q : PBytes;
Begin
  L := LLen(D, Y);
  If X >= L Then Exit;
  If X + N > L Then N := L - X;
  Tmp.Len := 0;
  Q := LP(D, Y);
  If X > 0 Then BufAddB(Tmp, Q, X);
  If L > X + N Then BufAddB(Tmp, @Q^[X + N], L - X - N);
  USet(D, Y, Tmp.P, Tmp.Len);
End;

{ couper la ligne Y en X (nouvelle ligne Y+1) }
Procedure SplitLine(D, Y, X : LongInt);
Var L : LongInt; Q : PBytes; B : TBuf;
Begin
  L := LLen(D, Y);
  If X > L Then X := L;
  BufInit(B);
  Q := LP(D, Y);
  If L > X Then BufAddB(B, @Q^[X], L - X);
  UIns(D, Y + 1, B.P, B.Len);
  BufFree(B);
  Q := LP(D, Y);
  USet(D, Y, Q, X);
End;

{ joindre la ligne Y+1 a la ligne Y }
Procedure JoinLines(D, Y : LongInt);
Var Q : PBytes;
Begin
  If Y + 1 >= DN[D] Then Exit;
  Tmp.Len := 0;
  Q := LP(D, Y);
  BufAddB(Tmp, Q, LLen(D, Y));
  Q := LP(D, Y + 1);
  BufAddB(Tmp, Q, LLen(D, Y + 1));
  USet(D, Y, Tmp.P, Tmp.Len);
  UDel(D, Y + 1);
End;

{ selection ordonnee }
Procedure SelRange(D : LongInt; Var Y1, X1, Y2, X2 : LongInt);
Begin
  If (DAY[D] < DCY[D]) Or ((DAY[D] = DCY[D]) And (DAX[D] <= DCX[D])) Then
  Begin
    Y1 := DAY[D]; X1 := DAX[D]; Y2 := DCY[D]; X2 := DCX[D];
  End
  Else
  Begin
    Y1 := DCY[D]; X1 := DCX[D]; Y2 := DAY[D]; X2 := DAX[D];
  End;
End;

Function HasSel(D : LongInt) : Boolean;
Begin
  HasSel := DSel[D] And ((DAX[D] <> DCX[D]) Or (DAY[D] <> DCY[D]));
End;

{ supprimer de (Y1, X1) a (Y2, X2) }
Procedure DelRange(D, Y1, X1, Y2, X2 : LongInt);
Var Q : PBytes; K : LongInt; B : TBuf;
Begin
  If Y1 = Y2 Then DelChars(D, Y1, X1, X2 - X1)
  Else
  Begin
    BufInit(B);
    Q := LP(D, Y1);
    BufAddB(B, Q, MinI(X1, LLen(D, Y1)));
    If X2 < LLen(D, Y2) Then
    Begin
      Q := LP(D, Y2);
      BufAddB(B, @Q^[X2], LLen(D, Y2) - X2);
    End;
    For K := Y2 DownTo Y1 + 1 Do UDel(D, K);
    USet(D, Y1, B.P, B.Len);
    BufFree(B);
  End;
  DCY[D] := Y1; DCX[D] := X1;
End;

Function DelSel(D : LongInt) : Boolean;
Var Y1, X1, Y2, X2 : LongInt;
Begin
  DelSel := False;
  If Not HasSel(D) Then
  Begin
    DSel[D] := False;
    Exit;
  End;
  SelRange(D, Y1, X1, Y2, X2);
  DelRange(D, Y1, X1, Y2, X2);
  DSel[D] := False;
  DelSel := True;
End;

{ texte de (Y1, X1) a (Y2, X2) dans B (lignes separees par CR LF) }
Procedure GetRange(D, Y1, X1, Y2, X2 : LongInt; Var B : TBuf);
Var Y, A, E : LongInt; Q : PBytes;
Begin
  For Y := Y1 To Y2 Do
  Begin
    A := 0; E := LLen(D, Y);
    If Y = Y1 Then A := MinI(X1, E);
    If Y = Y2 Then E := MinI(X2, E);
    Q := LP(D, Y);
    If E > A Then BufAddB(B, @Q^[A], E - A);
    If Y < Y2 Then
    Begin
      BufAddC(B, 13); BufAddC(B, 10);
    End;
  End;
End;

{ inserer un texte (CR LF ou LF) au curseur }
Procedure InsText(D : LongInt; P : PBytes; N : LongInt);
Var K, St, Y, X : LongInt; Tail : TBuf; Q : PBytes;
Begin
  Y := DCY[D]; X := MinI(DCX[D], LLen(D, Y));
  { fin de la ligne mise de cote }
  BufInit(Tail);
  Q := LP(D, Y);
  If LLen(D, Y) > X Then BufAddB(Tail, @Q^[X], LLen(D, Y) - X);
  If LLen(D, Y) > X Then DelChars(D, Y, X, LLen(D, Y) - X);
  St := 0;
  For K := 0 To N Do
    If (K = N) Or (P^[K] = 10) Then
    Begin
      If K - St > 0 Then
      Begin
        If (P^[K - 1] = 13) And (K < N) Then InsChars(D, Y, X, @P^[St], K - St - 1)
        Else InsChars(D, Y, X, @P^[St], K - St);
      End;
      If K < N Then
      Begin
        X := LLen(D, Y);
        UIns(D, Y + 1, Nil, 0);
        Inc(Y);
        X := 0;
        St := K + 1;
      End
      Else X := X + (K - St);
    End;
  X := LLen(D, Y);
  If Tail.Len > 0 Then InsChars(D, Y, X, Tail.P, Tail.Len);
  BufFree(Tail);
  DCY[D] := Y; DCX[D] := X;
End;

{ --- colonnes a l'ecran (tabulations) --- }

Function VisCol(D, Y, X : LongInt) : LongInt;
Var K, V, L : LongInt; Q : PBytes;
Begin
  V := 0; L := LLen(D, Y);
  Q := LP(D, Y);
  For K := 0 To X - 1 Do
    If (K < L) And (Q^[K] = 9) Then V := (V Div TabStop + 1) * TabStop
    Else Inc(V);
  VisCol := V;
End;

Function ColToX(D, Y, V : LongInt) : LongInt;
Var K, C, L, N : LongInt; Q : PBytes;
Begin
  C := 0; L := LLen(D, Y); K := 0;
  Q := LP(D, Y);
  While K < L Do
  Begin
    If Q^[K] = 9 Then N := (C Div TabStop + 1) * TabStop Else N := C + 1;
    If N > V Then
    Begin
      If V - C > N - V Then Inc(K);
      ColToX := K;
      Exit;
    End;
    C := N;
    Inc(K);
  End;
  ColToX := L;
End;

{ --- creation, chargement, enregistrement --- }

Function DocNew(Name : String) : LongInt;
Var D, K : LongInt;
Begin
  DocNew := -1;
  D := -1;
  For K := MaxDoc - 1 DownTo 0 Do If Not DUsed[K] Then D := K;
  If D < 0 Then Exit;
  DUsed[D] := True; DMod[D] := False; DName[D] := Name; DLang[D] := LangOf(Name);
  DUtf8[D] := 0; DCrlf[D] := 1; DN[D] := 0; DNCap[D] := 0;
  DLp[D] := Nil; DLn[D] := Nil; DLc[D] := Nil; DSt[D] := Nil; DStOk[D] := 0;
  DCX[D] := 0; DCY[D] := 0; DAX[D] := 0; DAY[D] := 0; DTop[D] := 0; DLeft[D] := 0; DWant[D] := -1;
  DSel[D] := False;
  GetMem(DUnd[D], SizeOf(TUndoArr)); GetMem(DRed[D], SizeOf(TUndoArr));
  DUN[D] := 0; DRN[D] := 0; DGrp[D] := 0; DLastKind[D] := 0; DLastY[D] := -1;
  Order[NDoc] := D;
  Inc(NDoc);
  DocNew := D;
End;

Procedure DocFree(D : LongInt);
Var K : LongInt;
Begin
  If Not DUsed[D] Then Exit;
  For K := 0 To DN[D] - 1 Do
    If DLc[D]^[K] > 0 Then FreeMem(Pointer(DLp[D]^[K]), DLc[D]^[K]);
  If DNCap[D] > 0 Then
  Begin
    FreeMem(DLp[D], DNCap[D] * 4); FreeMem(DLn[D], DNCap[D] * 4);
    FreeMem(DLc[D], DNCap[D] * 4); FreeMem(DSt[D], DNCap[D] * 4);
  End;
  DNCap[D] := 0; DN[D] := 0;
  For K := 0 To DUN[D] - 1 Do UFreeEntry(DUnd[D]^[K]);
  For K := 0 To DRN[D] - 1 Do UFreeEntry(DRed[D]^[K]);
  FreeMem(DUnd[D], SizeOf(TUndoArr)); FreeMem(DRed[D], SizeOf(TUndoArr));
  DUsed[D] := False;
  { onglets }
  For K := 0 To NDoc - 1 Do
    If Order[K] = D Then
    Begin
      Move(Order[K + 1], Order[K], (NDoc - K - 1) * 4);
      Dec(NDoc);
      Break;
    End;
End;

{ octets du fichier -> lignes ; UTF-8 converti en CP850 si possible }
Procedure DocFromBytes(D : LongInt; P : PBytes; N : LongInt);
Var K, St, E, U, C, J : LongInt; Utf, Hi, Ok : Boolean; B : TBuf;
Begin
  { UTF-8 valide ? et tout en CP850 ? }
  Hi := False; Utf := True; Ok := True;
  K := 0;
  If (N >= 3) And (P^[0] = $EF) And (P^[1] = $BB) And (P^[2] = $BF) Then K := 3;   { BOM }
  St := K;
  While K < N Do
  Begin
    C := P^[K];
    If C < $80 Then Inc(K)
    Else
    Begin
      Hi := True;
      If (C >= $C2) And (C <= $DF) And (K + 1 < N) And ((P^[K + 1] And $C0) = $80) Then
      Begin
        U := ((C And $1F) Shl 6) Or (P^[K + 1] And $3F);
        If Uni850(U) < 0 Then Ok := False;
        K := K + 2;
      End
      Else If (C >= $E0) And (C <= $EF) And (K + 2 < N) And ((P^[K + 1] And $C0) = $80) And
              ((P^[K + 2] And $C0) = $80) Then
      Begin
        U := ((C And $0F) Shl 12) Or ((P^[K + 1] And $3F) Shl 6) Or (P^[K + 2] And $3F);
        If Uni850(U) < 0 Then Ok := False;
        K := K + 3;
      End
      Else If (C >= $F0) And (C <= $F4) And (K + 3 < N) Then
      Begin
        Ok := False;
        K := K + 4;
      End
      Else
      Begin
        Utf := False;
        K := N;
      End;
    End;
  End;
  BufInit(B);
  If Hi And Utf And Ok Then
  Begin
    DUtf8[D] := 1;
    K := St;
    While K < N Do
    Begin
      C := P^[K];
      If C < $80 Then
      Begin
        BufAddC(B, C);
        Inc(K);
      End
      Else If C < $E0 Then
      Begin
        BufAddC(B, Uni850(((C And $1F) Shl 6) Or (P^[K + 1] And $3F)));
        K := K + 2;
      End
      Else
      Begin
        BufAddC(B, Uni850(((C And $0F) Shl 12) Or ((P^[K + 1] And $3F) Shl 6) Or (P^[K + 2] And $3F)));
        K := K + 3;
      End;
    End;
  End
  Else
  Begin
    If Hi And Utf Then DUtf8[D] := 2 Else DUtf8[D] := 0;
    BufAddB(B, P, N);
  End;
  { lignes }
  DCrlf[D] := 0;
  St := 0;
  For K := 0 To B.Len Do
    If (K = B.Len) Or (B.P^[K] = 10) Then
    Begin
      E := K;
      If (E > St) And (B.P^[E - 1] = 13) Then
      Begin
        Dec(E);
        DCrlf[D] := 1;
      End;
      If (K < B.Len) Or (E > St) Or (DN[D] = 0) Then RawIns(D, DN[D], @B.P^[St], E - St);
      St := K + 1;
    End;
  If (B.Len > 0) And (B.P^[B.Len - 1] = 10) Then RawIns(D, DN[D], Nil, 0);
  If DN[D] = 0 Then RawIns(D, 0, Nil, 0);
  If (DCrlf[D] = 0) And (N = 0) Then DCrlf[D] := 1;
  BufFree(B);
  J := 0;
End;

Function DocLoad(D : LongInt; Name : String) : Boolean;
Var H, R : LongInt; B : TBuf;
Begin
  DocLoad := False;
  If Not FOpenRead(Name, H) Then Exit;
  BufInit(B);
  Repeat
    If Not BufGrow(B, 65536) Then Break;
    R := FRead(H, @B.P^[B.Len], 65536);
    If R > 0 Then B.Len := B.Len + R;
  Until R <= 0;
  DosClose(H);
  DocFromBytes(D, B.P, B.Len);
  BufFree(B);
  DMod[D] := False;
  DocLoad := True;
End;

Function DocSave(D : LongInt; Name : String) : Boolean;
Var H, Y, K, C, U : LongInt; B : TBuf; Q : PBytes;
Begin
  DocSave := False;
  BufInit(B);
  For Y := 0 To DN[D] - 1 Do
  Begin
    Q := LP(D, Y);
    If DUtf8[D] = 1 Then
    Begin
      For K := 0 To LLen(D, Y) - 1 Do
      Begin
        C := Q^[K];
        If C < 128 Then BufAddC(B, C)
        Else
        Begin
          U := U850[C];
          If U < $800 Then
          Begin
            BufAddC(B, $C0 Or (U Shr 6)); BufAddC(B, $80 Or (U And $3F));
          End
          Else
          Begin
            BufAddC(B, $E0 Or (U Shr 12)); BufAddC(B, $80 Or ((U Shr 6) And $3F)); BufAddC(B, $80 Or (U And $3F));
          End;
        End;
      End;
    End
    Else BufAddB(B, Q, LLen(D, Y));
    If Y < DN[D] - 1 Then
    Begin
      If DCrlf[D] = 1 Then BufAddC(B, 13);
      BufAddC(B, 10);
    End;
  End;
  If FOpenWrite(Name, H) Then
  Begin
    DocSave := (B.Len = 0) Or (FWrite(H, B.P, B.Len) = B.Len);
    DosClose(H);
  End;
  BufFree(B);
End;
{ ==================================================================== }
{ Coloration syntaxique du Pascal                                       }
{ ==================================================================== }

{ Etat d'une ligne (au debut) : 0 code, 1 commentaire entre accolades,
  2 commentaire entre parenthese-etoile, 3 directive de compilation }

Const
  kTxt = 0; kKw = 1; kStr = 2; kCmt = 3; kNum = 4; kOp = 5; kDir = 6; kVp = 7;
  ColTab : Array[0..15] Of LongInt = (cBlack, cNavy, cMaroon, cDGreen, cBrown, cBlack, cTeal, cDPink, cBlack, cBlack,
                                      cBlack, cBlack, cBlack, cBlack, cBlack, cBlack);
  PKw1 = ' and array asm begin case const constructor destructor div do downto else end exports file for function goto if implementation in inherited inline interface label library mod nil not object of or packed ';
  PKw2 = ' procedure program record repeat set shl shr string then to type unit until uses var while with xor absolute external forward private public virtual true false exit break continue ';
  { proprietes et methodes des controles (Visual Pascal) }
  PVp1 = ' caption text left top width height visible enabled value listindex listcount interval additem removeitem clear list setfocus show hide me msgbox msgboxouinon quitter ';
  PVp2 = ' inttostr strtoint floattostr strtofloat ';

Var
  LAttr : PBytes;
  LAttrCap : LongInt;
  LxP : PBytes;
  LxN : LongInt;

Function LxC(I : LongInt) : LongInt;
Begin
  If (I < 0) Or (I >= LxN) Then LxC := 0 Else LxC := LxP^[I];
End;

Function IsAl(C : LongInt) : Boolean;
Begin
  IsAl := ((C >= 65) And (C <= 90)) Or ((C >= 97) And (C <= 122)) Or (C = 95) Or (C >= 128);
End;

Function IsDg(C : LongInt) : Boolean;
Begin
  IsDg := (C >= 48) And (C <= 57);
End;

Procedure LxSet(I, N, A : LongInt);
Var K : LongInt;
Begin
  If LAttr = Nil Then Exit;
  For K := I To I + N - 1 Do If (K >= 0) And (K < LxN) Then LAttr^[K] := A;
End;

Function WordClass(W : String) : LongInt;
Begin
  W := ' ' + LoStr(W) + ' ';
  If (Pos(W, PKw1) > 0) Or (Pos(W, PKw2) > 0) Then WordClass := kKw
  Else If (Pos(W, PVp1) > 0) Or (Pos(W, PVp2) > 0) Then WordClass := kVp
  Else WordClass := kTxt;
End;

{ colore une ligne (LAttr si non nul) ; rend l'etat de la ligne suivante }
Function LexLine(Lang : LongInt; P : PBytes; N, St : LongInt) : LongInt;
Var I, J, C, A : LongInt; W : String;
Begin
  LxP := P; LxN := N;
  If Lang <> lgPas Then
  Begin
    LxSet(0, N, kTxt);
    LexLine := 0;
    Exit;
  End;
  I := 0;
  While I < N Do
  Begin
    C := LxC(I);
    { suite d'un commentaire commence plus haut }
    If (St = 1) Or (St = 3) Then
    Begin
      J := I;
      While (J < N) And (LxC(J) <> 125) Do Inc(J);
      If St = 1 Then A := kCmt Else A := kDir;
      If J < N Then
      Begin
        LxSet(I, J + 1 - I, A);
        I := J + 1;
        St := 0;
      End
      Else
      Begin
        LxSet(I, N - I, A);
        I := N;
      End;
      Continue;
    End;
    If St = 2 Then
    Begin
      J := I;
      While (J < N) And Not ((LxC(J) = 42) And (LxC(J + 1) = 41)) Do Inc(J);
      If J < N Then
      Begin
        LxSet(I, J + 2 - I, kCmt);
        I := J + 2;
        St := 0;
      End
      Else
      Begin
        LxSet(I, N - I, kCmt);
        I := N;
      End;
      Continue;
    End;
    If C = 123 Then
    Begin
      If LxC(I + 1) = 36 Then St := 3 Else St := 1;
      Continue;
    End
    Else If (C = 40) And (LxC(I + 1) = 42) Then
    Begin
      LxSet(I, 2, kCmt);
      I := I + 2;
      St := 2;
    End
    Else If (C = 47) And (LxC(I + 1) = 47) Then
    Begin
      LxSet(I, N - I, kCmt);
      I := N;
    End
    Else If (C = 39) Or (C = 35) Then
    Begin
      J := I;
      While (J < N) And ((LxC(J) = 39) Or (LxC(J) = 35)) Do
      Begin
        If LxC(J) = 39 Then
        Begin
          Inc(J);
          While (J < N) And (LxC(J) <> 39) Do Inc(J);
          Inc(J);
        End
        Else
        Begin
          Inc(J);
          If LxC(J) = 36 Then Inc(J);
          While (J < N) And (IsDg(LxC(J)) Or IsAl(LxC(J))) Do Inc(J);
        End;
      End;
      LxSet(I, J - I, kStr);
      I := J;
    End
    Else If IsDg(C) Or ((C = 36) And IsAl(LxC(I + 1)) Or (C = 36) And IsDg(LxC(I + 1))) Then
    Begin
      J := I + 1;
      While (J < N) And (IsDg(LxC(J)) Or IsAl(LxC(J)) Or (LxC(J) = 46)) Do Inc(J);
      LxSet(I, J - I, kNum);
      I := J;
    End
    Else If IsAl(C) Then
    Begin
      J := I;
      W := '';
      While (J < N) And (IsAl(LxC(J)) Or IsDg(LxC(J))) Do
      Begin
        If Length(W) < 40 Then W := W + Chr(LxC(J));
        Inc(J);
      End;
      A := WordClass(W);
      { apres un point : propriete ou methode d'un controle }
      If (A = kKw) And (LxC(I - 1) = 46) Then A := kTxt;
      If (A = kVp) And (LxC(I - 1) <> 46) And (LoStr(W) <> 'me') And (LoStr(W) <> 'msgbox') And
         (LoStr(W) <> 'msgboxouinon') And (LoStr(W) <> 'quitter') And (Pos(' ' + LoStr(W) + ' ', PVp2) = 0) Then A := kTxt;
      LxSet(I, J - I, A);
      I := J;
    End
    Else If C > 32 Then
    Begin
      LxSet(I, 1, kOp);
      Inc(I);
    End
    Else
    Begin
      LxSet(I, 1, kTxt);
      Inc(I);
    End;
  End;
  LexLine := St;
End;

{ etat au debut de la ligne Y (calcule les lignes manquantes) }
Function LineState(D, Y : LongInt) : LongInt;
Var K, St : LongInt; Sv : PBytes;
Begin
  If DStOk[D] < 1 Then
  Begin
    DSt[D]^[0] := 0;
    DStOk[D] := 1;
  End;
  Sv := LAttr;
  LAttr := Nil;
  K := DStOk[D];
  While K <= Y Do
  Begin
    If K >= DN[D] Then Break;
    St := LexLine(DLang[D], LP(D, K - 1), LLen(D, K - 1), DSt[D]^[K - 1]);
    DSt[D]^[K] := St;
    Inc(K);
  End;
  If K > DStOk[D] Then DStOk[D] := K;
  LAttr := Sv;
  LineState := DSt[D]^[Y];
End;

{ couleurs de la ligne Y dans LAttr }
Procedure LineAttr(D, Y : LongInt);
Var N, C, St : LongInt;
Begin
  { l'etat d'abord : LineState appelle LexLine (pas d'appel imbrique dans les parametres) }
  St := LineState(D, Y);
  N := LLen(D, Y);
  If N + 16 > LAttrCap Then
  Begin
    If LAttrCap > 0 Then FreeMem(LAttr, LAttrCap);
    C := (N + 1024) And Not 1023;
    GetMem(LAttr, C);
    LAttrCap := C;
  End;
  Dummy := LexLine(DLang[D], LP(D, Y), N, St);
End;
{ ==================================================================== }
{ Projet : feuilles, controles et proprietes                            }
{ ==================================================================== }

Const
  MaxCtl = 200;
  vkForm = 1; vkLabel = 2; vkText = 3; vkButton = 4; vkFrame = 5; vkCheck = 6; vkOption = 7; vkList = 8;
  vkCombo = 9; vkTimer = 10;
  NKinds = 10;
  { proprietes }
  ppName = 1; ppCaption = 2; ppText = 3; ppLeft = 4; ppTop = 5; ppWidth = 6; ppHeight = 7; ppEnabled = 8;
  ppVisible = 9; ppAlign = 10; ppLocked = 11; ppValue = 12; ppList = 13; ppInterval = 14;
  NProps = 14;
  MaxGen = 16000;               { lignes du programme genere (correspondance des erreurs) }
  MaxEv = 3;

Var
  NCtl : LongInt;
  CtKind, CtForm, CtX, CtY, CtW, CtH, CtAlign, CtValue, CtIntv, CtDoc : Array[1..MaxCtl] Of LongInt;
  CtEn, CtVis, CtLocked : Array[1..MaxCtl] Of Boolean;
  CtName, CtText, CtItems : Array[1..MaxCtl] Of String;
  PrjName, PrjFile : String;
  PrjMod : Boolean;
  { programme genere }
  GenB : TBuf;
  GenN : LongInt;
  GMapF, GMapL : PLongs;        { ligne generee -> feuille (indice du controle) et ligne de son code }
  GCurF, GCurL : LongInt;       { origine des lignes emises (0 : bibliotheque ou code genere) }

{ --- sortes de controles --- }

Function KindName(K : LongInt) : String;
Begin
  Case K Of
    vkForm : KindName := 'Form';
    vkLabel : KindName := 'Label';
    vkText : KindName := 'TextBox';
    vkButton : KindName := 'CommandButton';
    vkFrame : KindName := 'Frame';
    vkCheck : KindName := 'CheckBox';
    vkOption : KindName := 'OptionButton';
    vkList : KindName := 'ListBox';
    vkCombo : KindName := 'ComboBox';
    vkTimer : KindName := 'Timer';
  Else
    KindName := '?';
  End;
End;

Function KindPrefix(K : LongInt) : String;
Begin
  Case K Of
    vkText : KindPrefix := 'Text';
    vkButton : KindPrefix := 'Command';
    vkCheck : KindPrefix := 'Check';
    vkOption : KindPrefix := 'Option';
    vkList : KindPrefix := 'List';
    vkCombo : KindPrefix := 'Combo';
  Else
    KindPrefix := KindName(K);
  End;
End;

Function KindTip(K : LongInt) : String;
Begin
  Case K Of
    vkLabel : KindTip := 'Label : texte fixe';
    vkText : KindTip := 'TextBox : zone de saisie';
    vkButton : KindTip := 'CommandButton : bouton de commande';
    vkFrame : KindTip := 'Frame : cadre qui regroupe des contr'#147'les';
    vkCheck : KindTip := 'CheckBox : case '#133' cocher';
    vkOption : KindTip := 'OptionButton : bouton d''option (un seul choix par cadre)';
    vkList : KindTip := 'ListBox : liste';
    vkCombo : KindTip := 'ComboBox : liste d'#130'roulante';
    vkTimer : KindTip := 'Timer : minuterie (invisible '#133' l''ex'#130'cution)';
  Else
    KindTip := 'Pointeur : choisir, d'#130'placer et redimensionner';
  End;
End;

Function KindFromName(S : String) : LongInt;
Var K : LongInt;
Begin
  KindFromName := 0;
  S := UpStr(S);
  For K := 1 To NKinds Do
    If UpStr(KindName(K)) = S Then
    Begin
      KindFromName := K;
      Exit;
    End;
End;

{ evenements d'une sorte de controle }
Function EvCount(K : LongInt) : LongInt;
Begin
  Case K Of
    vkForm : EvCount := 2;
    vkList, vkCombo : EvCount := 2;
    vkLabel, vkFrame : EvCount := 0;
  Else
    EvCount := 1;
  End;
End;

Function EvName(K, I : LongInt) : String;
Begin
  EvName := 'Click';
  Case K Of
    vkForm : If I = 1 Then EvName := 'Load' Else EvName := 'Unload';
    vkText : EvName := 'Change';
    vkTimer : EvName := 'Timer';
    vkList, vkCombo : If I = 2 Then EvName := 'DblClick';
  End;
End;

{ code de l'evenement dans la bibliotheque d'execution }
Function EvConst(E : String) : String;
Begin
  EvConst := 'ev' + E;
End;

{ --- noms --- }

Function IsAlC(C : Char) : Boolean;
Begin
  IsAlC := ((C >= 'A') And (C <= 'Z')) Or ((C >= 'a') And (C <= 'z')) Or (C = '_');
End;

Function IsIdent(S : String) : Boolean;
Var K : LongInt;
Begin
  IsIdent := False;
  If (S = '') Or (Length(S) > 40) Or Not IsAlC(S[1]) Then Exit;
  For K := 2 To Length(S) Do
    If Not (IsAlC(S[K]) Or ((S[K] >= '0') And (S[K] <= '9'))) Then Exit;
  IsIdent := True;
End;

{ mots reserves et noms de la bibliotheque qui ne peuvent pas nommer un controle }
Function IsReserved(S : String) : Boolean;
Const
  R1 = ' AND ARRAY BEGIN CASE CONST DIV DO DOWNTO ELSE END FILE FOR FUNCTION GOTO IF IN LABEL MOD NIL NOT OF OR' +
       ' PACKED PROCEDURE PROGRAM RECORD REPEAT SET THEN TO TYPE UNTIL VAR WHILE WITH XOR SHL SHR STRING ';
  R2 = ' ME MSGBOX MSGBOXOUINON QUITTER INTTOSTR STRTOINT STRTOFLOAT FLOATTOSTR INTEGER LONGINT REAL BOOLEAN' +
       ' CHAR BYTE WORD TRUE FALSE HEURE DATEDUJOUR ';
Begin
  S := ' ' + UpStr(S) + ' ';
  IsReserved := (Pos(S, R1) > 0) Or (Pos(S, R2) > 0) Or (Pos(' VP', S) = 1);
End;

Function FindCtl(S : String) : LongInt;
Var K : LongInt;
Begin
  FindCtl := 0;
  S := UpStr(S);
  For K := 1 To NCtl Do
    If UpStr(CtName[K]) = S Then
    Begin
      FindCtl := K;
      Exit;
    End;
End;

Function NewName(K : LongInt) : String;
Var N : LongInt;
Begin
  N := 1;
  While FindCtl(KindPrefix(K) + IStr(N)) > 0 Do Inc(N);
  NewName := KindPrefix(K) + IStr(N);
End;

{ --- controles --- }

Function AddCtl(K, F, X, Y, W, H : LongInt) : LongInt;
Var C : LongInt;
Begin
  AddCtl := 0;
  If NCtl >= MaxCtl Then Exit;
  Inc(NCtl);
  C := NCtl;
  CtKind[C] := K; CtForm[C] := F; CtX[C] := X; CtY[C] := Y; CtW[C] := W; CtH[C] := H;
  CtAlign[C] := 0; CtValue[C] := 0; CtIntv[C] := 0; CtDoc[C] := -1;
  CtEn[C] := True; CtVis[C] := True; CtLocked[C] := False;
  CtName[C] := '';
  CtName[C] := NewName(K);
  CtText[C] := ''; CtItems[C] := '';
  If K = vkForm Then CtForm[C] := C;
  Case K Of
    vkForm, vkLabel, vkButton, vkFrame, vkCheck, vkOption : CtText[C] := CtName[C];
    vkText, vkCombo : CtText[C] := CtName[C];
    vkTimer : CtIntv[C] := 1000;
  End;
  PrjMod := True;
  AddCtl := C;
End;

{ taille par defaut quand on clique sans tirer }
Procedure DefSize(K : LongInt; Var W, H : LongInt);
Begin
  Case K Of
    vkLabel : Begin W := 96; H := 20; End;
    vkText : Begin W := 120; H := 24; End;
    vkButton : Begin W := 96; H := 30; End;
    vkFrame : Begin W := 168; H := 104; End;
    vkCheck, vkOption : Begin W := 128; H := 22; End;
    vkList : Begin W := 128; H := 96; End;
    vkCombo : Begin W := 128; H := 24; End;
    vkTimer : Begin W := 28; H := 28; End;
  Else
    Begin W := 400; H := 300; End;
  End;
End;

Function NewForm : LongInt;
Var F, D : LongInt;
Begin
  NewForm := 0;
  D := DocNew('');
  If D < 0 Then Exit;
  RawIns(D, 0, Nil, 0);
  F := AddCtl(vkForm, 0, 0, 0, 400, 300);
  If F = 0 Then
  Begin
    DocFree(D);
    Exit;
  End;
  CtDoc[F] := D;
  DName[D] := CtName[F];
  NewForm := F;
End;

Procedure DelOne(C : LongInt);
Var K : LongInt;
Begin
  If (CtKind[C] = vkForm) And (CtDoc[C] >= 0) Then DocFree(CtDoc[C]);
  For K := C To NCtl - 1 Do
  Begin
    CtKind[K] := CtKind[K + 1]; CtForm[K] := CtForm[K + 1]; CtX[K] := CtX[K + 1]; CtY[K] := CtY[K + 1];
    CtW[K] := CtW[K + 1]; CtH[K] := CtH[K + 1]; CtAlign[K] := CtAlign[K + 1]; CtValue[K] := CtValue[K + 1];
    CtIntv[K] := CtIntv[K + 1]; CtDoc[K] := CtDoc[K + 1]; CtEn[K] := CtEn[K + 1]; CtVis[K] := CtVis[K + 1];
    CtLocked[K] := CtLocked[K + 1]; CtName[K] := CtName[K + 1]; CtText[K] := CtText[K + 1];
    CtItems[K] := CtItems[K + 1];
  End;
  Dec(NCtl);
  For K := 1 To NCtl Do If CtForm[K] > C Then Dec(CtForm[K]);
  PrjMod := True;
End;

{ supprime un controle (une feuille : avec ses controles et son code) }
Procedure DelCtl(C : LongInt);
Var K : LongInt;
Begin
  If (C < 1) Or (C > NCtl) Then Exit;
  If CtKind[C] = vkForm Then
  Begin
    For K := NCtl DownTo 1 Do
      If (K <> C) And (CtForm[K] = C) Then
      Begin
        DelOne(K);
        If K < C Then Dec(C);
      End;
  End;
  DelOne(C);
End;

Procedure ClearProject;
Begin
  While NCtl > 0 Do DelCtl(NCtl);
  PrjName := 'Projet1'; PrjFile := '';
  PrjMod := False;
End;

Function FormCount : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 1 To NCtl Do If CtKind[K] = vkForm Then Inc(N);
  FormCount := N;
End;

Function FirstForm : LongInt;
Var K : LongInt;
Begin
  FirstForm := 0;
  For K := 1 To NCtl Do
    If CtKind[K] = vkForm Then
    Begin
      FirstForm := K;
      Exit;
    End;
End;

{ --- proprietes --- }

Function PropName(P : LongInt) : String;
Begin
  Case P Of
    ppName : PropName := '(Name)';
    ppCaption : PropName := 'Caption';
    ppText : PropName := 'Text';
    ppLeft : PropName := 'Left';
    ppTop : PropName := 'Top';
    ppWidth : PropName := 'Width';
    ppHeight : PropName := 'Height';
    ppEnabled : PropName := 'Enabled';
    ppVisible : PropName := 'Visible';
    ppAlign : PropName := 'Alignment';
    ppLocked : PropName := 'Locked';
    ppValue : PropName := 'Value';
    ppList : PropName := 'List';
    ppInterval : PropName := 'Interval';
  Else
    PropName := '';
  End;
End;

Function PropFromName(S : String) : LongInt;
Var P : LongInt;
Begin
  PropFromName := 0;
  S := UpStr(S);
  If S = 'NAME' Then S := '(NAME)';
  For P := 1 To NProps Do
    If UpStr(PropName(P)) = S Then
    Begin
      PropFromName := P;
      Exit;
    End;
End;

Function PropHas(K, P : LongInt) : Boolean;
Begin
  Case P Of
    ppName, ppEnabled : PropHas := True;
    ppCaption : PropHas := K In [vkForm, vkLabel, vkButton, vkFrame, vkCheck, vkOption];
    ppText : PropHas := K In [vkText, vkCombo];
    ppLeft, ppTop : PropHas := K <> vkForm;
    ppWidth, ppHeight : PropHas := K <> vkTimer;
    ppVisible : PropHas := (K <> vkForm) And (K <> vkTimer);
    ppAlign : PropHas := K = vkLabel;
    ppLocked : PropHas := K = vkText;
    ppValue : PropHas := K In [vkCheck, vkOption];
    ppList : PropHas := K In [vkList, vkCombo];
    ppInterval : PropHas := K = vkTimer;
  Else
    PropHas := False;
  End;
End;

{ proprietes a choix (liste deroulante dans la fenetre des proprietes) }
Function PropChoices(K, P : LongInt) : LongInt;
Begin
  PropChoices := 0;
  Case P Of
    ppEnabled, ppVisible, ppLocked : PropChoices := 2;
    ppAlign : PropChoices := 3;
    ppValue : PropChoices := 2;
  End;
End;

Function BoolS(B : Boolean) : String;
Begin
  If B Then BoolS := 'True' Else BoolS := 'False';
End;

Function PropChoice(K, P, I : LongInt) : String;
Begin
  PropChoice := '';
  Case P Of
    ppEnabled, ppVisible, ppLocked : PropChoice := BoolS(I = 1);
    ppAlign :
      Case I Of
        0 : PropChoice := '0 - Gauche';
        1 : PropChoice := '1 - Droite';
        2 : PropChoice := '2 - Centre';
      End;
    ppValue :
      If K = vkOption Then PropChoice := BoolS(I = 1)
      Else If I = 0 Then PropChoice := '0 - Non coch'#130
      Else PropChoice := '1 - Coch'#130;
  End;
End;

Function PropGet(C, P : LongInt) : String;
Begin
  PropGet := '';
  Case P Of
    ppName : PropGet := CtName[C];
    ppCaption, ppText : PropGet := CtText[C];
    ppLeft : PropGet := IStr(CtX[C]);
    ppTop : PropGet := IStr(CtY[C]);
    ppWidth : PropGet := IStr(CtW[C]);
    ppHeight : PropGet := IStr(CtH[C]);
    ppEnabled : PropGet := BoolS(CtEn[C]);
    ppVisible : PropGet := BoolS(CtVis[C]);
    ppAlign : PropGet := PropChoice(CtKind[C], P, CtAlign[C]);
    ppLocked : PropGet := BoolS(CtLocked[C]);
    ppValue : PropGet := PropChoice(CtKind[C], P, CtValue[C]);
    ppList : PropGet := CtItems[C];
    ppInterval : PropGet := IStr(CtIntv[C]);
  End;
End;

Function PropDesc(P : LongInt) : String;
Begin
  Case P Of
    ppName : PropDesc := 'Nom utilis'#130' dans le code pour d'#130'signer l''objet (Text1.Text, Form1_Load...).';
    ppCaption : PropDesc := 'Texte affich'#130' dans la barre de titre ou sur le contr'#147'le.';
    ppText : PropDesc := 'Texte contenu dans le contr'#147'le.';
    ppLeft : PropDesc := 'Distance entre le bord gauche de la feuille et le contr'#147'le (pixels).';
    ppTop : PropDesc := 'Distance entre le haut de la feuille et le contr'#147'le (pixels).';
    ppWidth : PropDesc := 'Largeur de l''objet (pixels ; pour une feuille : sa zone client).';
    ppHeight : PropDesc := 'Hauteur de l''objet (pixels ; pour une feuille : sa zone client).';
    ppEnabled : PropDesc := 'Indique si l''objet r'#130'pond aux actions de l''utilisateur (minuterie : si elle tourne).';
    ppVisible : PropDesc := 'Indique si l''objet est visible ou cach'#130'.';
    ppAlign : PropDesc := 'Alignement du texte : 0 - Gauche, 1 - Droite, 2 - Centre.';
    ppLocked : PropDesc := 'Si True, le texte ne peut pas '#136'tre modifi'#130' par l''utilisateur.';
    ppValue : PropDesc := 'Etat du contr'#147'le : coch'#130' ou non (option : choisie ou non). Dans le code : 0 ou 1.';
    ppList : PropDesc := 'El'#130'ments de la liste au d'#130'marrage, s'#130'par'#130's par des points-virgules.';
    ppInterval : PropDesc := 'Intervalle de l'''#130'v'#130'nement Timer, en millisecondes (0 : arr'#136't'#130'e).';
  Else
    PropDesc := '';
  End;
End;

Function ParseBool(S : String; Var B : Boolean) : Boolean;
Begin
  ParseBool := True;
  S := UpStr(Trim(S));
  If (S = 'TRUE') Or (S = 'VRAI') Or (S = '1') Or (S = '-1') Or (S = 'OUI') Then B := True
  Else If (S = 'FALSE') Or (S = 'FAUX') Or (S = '0') Or (S = 'NON') Then B := False
  Else ParseBool := False;
End;

Function ParseNum(S : String; Var V : LongInt) : Boolean;
Var E : LongInt;
Begin
  S := Trim(S);
  Val(S, V, E);
  ParseNum := (E = 0) And (S <> '');
End;

{ renomme les procedures d'evenements Ancien_xxx en Nouveau_xxx dans le code de la feuille }
Procedure RenameHandlers(F : LongInt; Old, New_ : String);
Var D, Y, K, N : LongInt; S, U : String; B : TBuf;
Begin
  D := CtDoc[F];
  If D < 0 Then Exit;
  U := 'PROCEDURE ' + UpStr(Old) + '_';
  For Y := 0 To DN[D] - 1 Do
  Begin
    S := LStr(D, Y);
    K := 1;
    While (K <= Length(S)) And ((S[K] = ' ') Or (S[K] = #9)) Do Inc(K);
    If UpStr(Copy(S, K, Length(U))) = U Then
    Begin
      N := K + 10;
      S := Copy(S, 1, N - 1) + New_ + Copy(S, N + Length(Old), 255);
      BufInit(B);
      BufAdd(B, S);
      USet(D, Y, B.P, B.Len);
      BufFree(B);
    End;
  End;
End;

{ change une propriete ; rend un message d'erreur ('' : correct) }
Function PropSet1(C, P : LongInt; S : String) : String;
Var V : LongInt; B : Boolean; Old, Res : String;
Begin
  Res := '';
  Case P Of
    ppName :
      Begin
        S := Trim(S);
        If S = CtName[C] Then Exit;
        If Not IsIdent(S) Then
        Begin
          PropSet1 := 'Nom incorrect : lettres, chiffres et _ seulement, sans commencer par un chiffre.';
          Exit;
        End;
        If IsReserved(S) Then
        Begin
          PropSet1 := '"' + S + '" est un mot r'#130'serv'#130' de Pascal ou de Visual Pascal.';
          Exit;
        End;
        V := FindCtl(S);
        If (V > 0) And (V <> C) Then
        Begin
          PropSet1 := 'Le nom "' + S + '" est d'#130'j'#133' utilis'#130'.';
          Exit;
        End;
        Old := CtName[C];
        CtName[C] := S;
        RenameHandlers(CtForm[C], Old, S);
        If CtKind[C] = vkForm Then DName[CtDoc[C]] := S;
      End;
    ppCaption, ppText : CtText[C] := S;
    ppList : CtItems[C] := S;
    ppLeft, ppTop, ppWidth, ppHeight, ppInterval :
      Begin
        If Not ParseNum(S, V) Then
        Begin
          PropSet1 := 'Valeur num'#130'rique attendue.';
          Exit;
        End;
        If (P = ppWidth) Or (P = ppHeight) Then
        Begin
          If V < 4 Then V := 4;
          If V > 4000 Then V := 4000;
        End;
        If P = ppInterval Then
        Begin
          If V < 0 Then V := 0;
          If V > 65535 Then V := 65535;
        End;
        Case P Of
          ppLeft : CtX[C] := V;
          ppTop : CtY[C] := V;
          ppWidth : CtW[C] := V;
          ppHeight : CtH[C] := V;
          ppInterval : CtIntv[C] := V;
        End;
      End;
    ppEnabled, ppVisible, ppLocked :
      Begin
        If Not ParseBool(S, B) Then
        Begin
          PropSet1 := 'Valeur True ou False attendue.';
          Exit;
        End;
        If P = ppEnabled Then CtEn[C] := B
        Else If P = ppVisible Then CtVis[C] := B
        Else CtLocked[C] := B;
      End;
    ppAlign :
      Begin
        S := Trim(S);
        If (S <> '') And (S[1] >= '0') And (S[1] <= '2') Then CtAlign[C] := Ord(S[1]) - 48
        Else
        Begin
          PropSet1 := 'Valeur 0, 1 ou 2 attendue.';
          Exit;
        End;
      End;
    ppValue :
      Begin
        S := Trim(S);
        If (S <> '') And ((S[1] = '0') Or (S[1] = '1')) Then CtValue[C] := Ord(S[1]) - 48
        Else If ParseBool(S, B) Then CtValue[C] := Ord(B)
        Else
        Begin
          PropSet1 := 'Valeur 0 ou 1 attendue.';
          Exit;
        End;
      End;
  End;
  PrjMod := True;
  PropSet1 := Res;
End;

{ change une propriete ; rend un message d'erreur ('' : correct) }
Function PropSet(C, P : LongInt; S : String) : String;
Var R : String;
Begin
  R := PropSet1(C, P, S);
  PropSet := R;
End;

{ --- code des feuilles --- }

{ ligne de "Procedure Nom" dans le document D (-1 : absente) }
Function FindProc(D : LongInt; Name : String) : LongInt;
Var Y, K : LongInt; S, U : String;
Begin
  FindProc := -1;
  If D < 0 Then Exit;
  U := 'PROCEDURE ' + UpStr(Name);
  For Y := 0 To DN[D] - 1 Do
  Begin
    S := UpStr(LStr(D, Y));
    K := 1;
    While (K <= Length(S)) And ((S[K] = ' ') Or (S[K] = #9)) Do Inc(K);
    If Copy(S, K, Length(U)) = U Then
      If (K + Length(U) > Length(S)) Or Not (IsAlC(S[K + Length(U)]) Or ((S[K + Length(U)] >= '0') And
         (S[K + Length(U)] <= '9'))) Then
      Begin
        FindProc := Y;
        Exit;
      End;
  End;
End;

Procedure DocAddLine(D : LongInt; S : String);
Begin
  If Length(S) > 0 Then UIns(D, DN[D], @S[1], Length(S)) Else UIns(D, DN[D], Nil, 0);
End;

{ procedure d'evenement : la cree si besoin ; curseur dans son corps }
Procedure GotoHandler(C : LongInt; Ev : String);
Var F, D, Y : LongInt; N : String;
Begin
  F := CtForm[C];
  D := CtDoc[F];
  If D < 0 Then Exit;
  N := CtName[C] + '_' + Ev;
  Y := FindProc(D, N);
  If Y < 0 Then
  Begin
    BeginEdit(D, 2);
    { derniere ligne vide reutilisee }
    If (DN[D] = 1) And (LLen(D, 0) = 0) Then UDel(D, 0)
    Else If LLen(D, DN[D] - 1) > 0 Then DocAddLine(D, '');
    Y := DN[D];
    If DN[D] = 0 Then Y := 0;
    DocAddLine(D, 'Procedure ' + N + ';');
    DocAddLine(D, 'Begin');
    DocAddLine(D, '  ');
    DocAddLine(D, 'End;');
    PrjMod := True;
  End;
  DSel[D] := False;
  DCY[D] := Y + 2;
  If DCY[D] >= DN[D] Then DCY[D] := DN[D] - 1;
  DCX[D] := LLen(D, DCY[D]);
  DWant[D] := -1;
  DTop[D] := MaxI(0, Y - 2);
End;

{ ==================================================================== }
{ Programme genere : emission des lignes                                }
{ ==================================================================== }

Procedure GL(S : String);
Begin
  BufAdd(GenB, S);
  BufAddC(GenB, 13); BufAddC(GenB, 10);
  If (GMapF <> Nil) And (GenN < MaxGen) Then
  Begin
    GMapF^[GenN] := GCurF; GMapL^[GenN] := GCurL;
  End;
  Inc(GenN);
End;

{ ligne de longueur quelconque }
Procedure GLB(P : PBytes; N : LongInt);
Begin
  BufAddB(GenB, P, N);
  BufAddC(GenB, 13); BufAddC(GenB, 10);
  If (GMapF <> Nil) And (GenN < MaxGen) Then
  Begin
    GMapF^[GenN] := GCurF; GMapL^[GenN] := GCurL;
  End;
  Inc(GenN);
End;

{ chaine Pascal entre apostrophes }
Function PasStr(S : String) : String;
Var K : LongInt; R : String;
Begin
  R := '''';
  For K := 1 To Length(S) Do
  Begin
    If S[K] = '''' Then R := R + ''''''
    Else If S[K] < ' ' Then R := R + ''' + #' + IStr(Ord(S[K])) + ' + '''
    Else R := R + S[K];
    If Length(R) > 240 Then Break;
  End;
  PasStr := R + '''';
End;

{ ==================================================================== }
{ Bibliotheque d'execution ajoutee aux programmes generes (vprt)       }
{ ==================================================================== }

Procedure EmitRuntime;
Begin
  GL('(* ===== Bibliotheque d''execution de Visual Pascal (inseree par l''EDI) ===== *)');
  GL('');
  GL('Const');
  GL('  vkForm = 1; vkLabel = 2; vkText = 3; vkButton = 4; vkFrame = 5; vkCheck = 6; vkOption = 7; vkList = 8;');
  GL('  vkCombo = 9; vkTimer = 10;');
  GL('  evClick = 1; evChange = 2; evTimer = 3; evLoad = 4; evDblClick = 5; evUnload = 6;');
  GL('  { options de VPAdd }');
  GL('  voDisabled = 1; voHidden = 2; voRight = 4; voCenter = 8; voLocked = 16; voChecked = 32; voGroup = 64;');
  GL('  VP_WM_CONTROL = $0030; VP_WM_COMMAND = $0020; VP_WM_PAINT = $0023; VP_WM_TIMER = $0024; VP_WM_CLOSE = $0029;');
  GL('  VP_WM_QUIT = $002A; VP_WM_SIZE = $0007;');
  GL('');
  GL('Type');
  GL('  TVPBytes = Array[0..$FFFFFF] Of Byte;');
  GL('  PVPBytes = ^TVPBytes;');
  GL('');
  GL('Function WinInitialize(Fl : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinEndPaint(Hps : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinFillRect(Hps, P, C : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinQueryWindowRect(H, P : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinSetWindowText(H, P : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinSetFocus(HD, H : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinEnableWindow(H, En : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinShowWindow(H, Show : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinDestroyWindow(H : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External ''PMWIN'';');
  GL('Function DosSleep(Ms : LongInt) : LongInt; External ''DOSCALLS'';');
  GL('Function DosGetDateTime(P : LongInt) : LongInt; External ''DOSCALLS'';');
  GL('');
  GL('Var');
  GL('  VPHab, VPHmq, VPStartup, VPDummy : LongInt;');
  GL('  VPMsg : Array[0..7] Of LongInt;');
  GL('  VPKind, VPForm, VPX, VPY, VPW, VPH, VPHw, VPFr, VPOpt, VPIntv : Array[1..VPMax] Of LongInt;');
  GL('  VPTxt, VPItems : Array[1..VPMax] Of String;');
  GL('  VPZb, VPZb2 : Array[0..299] Of Byte;');
  GL('  VPQuitting : Boolean;');
  GL('');
  GL('Function VPZ(S : String) : LongInt;');
  GL('Var K : LongInt;');
  GL('Begin');
  GL('  For K := 1 To Length(S) Do VPZb[K - 1] := Ord(S[K]);');
  GL('  VPZb[Length(S)] := 0;');
  GL('  VPZ := LongInt(@VPZb);');
  GL('End;');
  GL('');
  GL('Function VPZ2(S : String) : LongInt;');
  GL('Var K : LongInt;');
  GL('Begin');
  GL('  For K := 1 To Length(S) Do VPZb2[K - 1] := Ord(S[K]);');
  GL('  VPZb2[Length(S)] := 0;');
  GL('  VPZ2 := LongInt(@VPZb2);');
  GL('End;');
  GL('');
  GL('Function VPLo(V : LongInt) : LongInt;');
  GL('Begin');
  GL('  VPLo := V And $FFFF;');
  GL('End;');
  GL('');
  GL('Function VPHi(V : LongInt) : LongInt;');
  GL('Begin');
  GL('  VPHi := (V Shr 16) And $FFFF;');
  GL('End;');
  GL('');
  GL('{ --- fonctions utiles aux programmes --- }');
  GL('');
  GL('Function IntToStr(V : LongInt) : String;');
  GL('Var S : String;');
  GL('Begin');
  GL('  Str(V, S);');
  GL('  IntToStr := S;');
  GL('End;');
  GL('');
  GL('Function StrToInt(S : String) : LongInt;');
  GL('Var V, E : LongInt;');
  GL('Begin');
  GL('  While (Length(S) > 0) And (S[1] = '' '') Do Delete(S, 1, 1);');
  GL('  While (Length(S) > 0) And (S[Length(S)] = '' '') Do Delete(S, Length(S), 1);');
  GL('  Val(S, V, E);');
  GL('  If E <> 0 Then V := 0;');
  GL('  StrToInt := V;');
  GL('End;');
  GL('');
  GL('Function StrToFloat(S : String) : Real;');
  GL('Var R : Real; E, K : LongInt;');
  GL('Begin');
  GL('  For K := 1 To Length(S) Do If S[K] = '','' Then S[K] := ''.'';');
  GL('  While (Length(S) > 0) And (S[1] = '' '') Do Delete(S, 1, 1);');
  GL('  While (Length(S) > 0) And (S[Length(S)] = '' '') Do Delete(S, Length(S), 1);');
  GL('  If S = '''' Then S := ''0'';');
  GL('  Val(S, R, E);');
  GL('  If E <> 0 Then R := 0;');
  GL('  StrToFloat := R;');
  GL('End;');
  GL('');
  GL('Function FloatToStr(R : Real) : String;');
  GL('Var S : String; L : LongInt;');
  GL('Begin');
  GL('  If (R > -2000000000.0) And (R < 2000000000.0) And (R = Trunc(R)) Then');
  GL('  Begin');
  GL('    L := Trunc(R);');
  GL('    Str(L, S);');
  GL('  End');
  GL('  Else');
  GL('  Begin');
  GL('    Str(R:0:10, S);');
  GL('    While (Length(S) > 0) And (S[Length(S)] = ''0'') Do Delete(S, Length(S), 1);');
  GL('    If (Length(S) > 0) And (S[Length(S)] = ''.'') Then Delete(S, Length(S), 1);');
  GL('  End;');
  GL('  FloatToStr := S;');
  GL('End;');
  GL('');
  GL('Function VPZ2D(V : LongInt) : String;');
  GL('Begin');
  GL('  VPZ2D := Chr(48 + (V Div 10) Mod 10) + Chr(48 + V Mod 10);');
  GL('End;');
  GL('');
  GL('{ heure courante : HH:MM:SS }');
  GL('Function Heure : String;');
  GL('Var T : Array[0..11] Of Byte;');
  GL('Begin');
  GL('  VPDummy := DosGetDateTime(LongInt(@T));');
  GL('  Heure := VPZ2D(T[0]) + '':'' + VPZ2D(T[1]) + '':'' + VPZ2D(T[2]);');
  GL('End;');
  GL('');
  GL('{ date du jour : JJ/MM/AAAA }');
  GL('Function DateDuJour : String;');
  GL('Var T : Array[0..11] Of Byte;');
  GL('Begin');
  GL('  VPDummy := DosGetDateTime(LongInt(@T));');
  GL('  DateDuJour := VPZ2D(T[4]) + ''/'' + VPZ2D(T[5]) + ''/'' + IntToStr(T[6] + T[7] * 256);');
  GL('End;');
  GL('');
  GL('Function VPActiveFrame : LongInt;');
  GL('Begin');
  GL('  If VPStartup > 0 Then VPActiveFrame := VPFr[VPStartup] Else VPActiveFrame := 0;');
  GL('End;');
  GL('');
  GL('Procedure MsgBox(S : String);');
  GL('Var B : Array[0..299] Of Byte; K : LongInt;');
  GL('Begin');
  GL('  For K := 1 To Length(S) Do B[K - 1] := Ord(S[K]);');
  GL('  B[Length(S)] := 0;');
  GL('  VPDummy := WinMessageBox(1, VPActiveFrame, LongInt(@B), VPZ2(VPTitle), 0, $4030);');
  GL('End;');
  GL('');
  GL('{ Oui : vrai }');
  GL('Function MsgBoxOuiNon(S : String) : Boolean;');
  GL('Var B : Array[0..299] Of Byte; K : LongInt;');
  GL('Begin');
  GL('  For K := 1 To Length(S) Do B[K - 1] := Ord(S[K]);');
  GL('  B[Length(S)] := 0;');
  GL('  MsgBoxOuiNon := WinMessageBox(1, VPActiveFrame, LongInt(@B), VPZ2(VPTitle), 0, $4014) = 6;');
  GL('End;');
  GL('');
  GL('Procedure Quitter;');
  GL('Begin');
  GL('  VPQuitting := True;');
  GL('  VPDummy := WinPostMsg(VPHw[VPStartup], VP_WM_QUIT, 0, 0);');
  GL('End;');
  GL('');
  GL('{ --- proprietes --- }');
  GL('');
  GL('Function VPWinText(H : LongInt) : String;');
  GL('Var B : Array[0..299] Of Byte; N, K : LongInt; S : String;');
  GL('Begin');
  GL('  S := '''';');
  GL('  If H <> 0 Then');
  GL('  Begin');
  GL('    N := WinQueryWindowText(H, 255, LongInt(@B));');
  GL('    If N > 255 Then N := 255;');
  GL('    For K := 0 To N - 1 Do');
  GL('    Begin');
  GL('      If B[K] = 0 Then Break;');
  GL('      S := S + Chr(B[K]);');
  GL('    End;');
  GL('  End;');
  GL('  VPWinText := S;');
  GL('End;');
  GL('');
  GL('Function VPCaption(C : LongInt) : String;');
  GL('Begin');
  GL('  If VPKind[C] = vkForm Then VPCaption := VPWinText(VPFr[C])');
  GL('  Else If VPKind[C] = vkTimer Then VPCaption := VPTxt[C]');
  GL('  Else VPCaption := VPWinText(VPHw[C]);');
  GL('End;');
  GL('');
  GL('Procedure VPSetCaption(C : LongInt; S : String);');
  GL('Begin');
  GL('  VPTxt[C] := S;');
  GL('  If VPKind[C] = vkForm Then VPDummy := WinSetWindowText(VPFr[C], VPZ(S))');
  GL('  Else If VPHw[C] <> 0 Then VPDummy := WinSetWindowText(VPHw[C], VPZ(S));');
  GL('End;');
  GL('');
  GL('Function VPText(C : LongInt) : String;');
  GL('Var N : LongInt; B : Array[0..299] Of Byte; K : LongInt; S : String;');
  GL('Begin');
  GL('  If VPKind[C] = vkList Then');
  GL('  Begin');
  GL('    S := '''';');
  GL('    N := WinSendMsg(VPHw[C], $0165, $FFFF, 0);');
  GL('    If N >= 0 Then');
  GL('    Begin');
  GL('      K := WinSendMsg(VPHw[C], $0168, (N And $FFFF) Or (255 Shl 16), LongInt(@B));');
  GL('      If K > 255 Then K := 255;');
  GL('      For N := 0 To K - 1 Do');
  GL('      Begin');
  GL('        If B[N] = 0 Then Break;');
  GL('        S := S + Chr(B[N]);');
  GL('      End;');
  GL('    End;');
  GL('    VPText := S;');
  GL('  End');
  GL('  Else VPText := VPCaption(C);');
  GL('End;');
  GL('');
  GL('Procedure VPSetText(C : LongInt; S : String);');
  GL('Begin');
  GL('  VPSetCaption(C, S);');
  GL('End;');
  GL('');
  GL('Function VPLeft(C : LongInt) : LongInt;');
  GL('Begin');
  GL('  VPLeft := VPX[C];');
  GL('End;');
  GL('');
  GL('Function VPTop(C : LongInt) : LongInt;');
  GL('Begin');
  GL('  VPTop := VPY[C];');
  GL('End;');
  GL('');
  GL('Function VPWidth(C : LongInt) : LongInt;');
  GL('Begin');
  GL('  VPWidth := VPW[C];');
  GL('End;');
  GL('');
  GL('Function VPHeight(C : LongInt) : LongInt;');
  GL('Begin');
  GL('  VPHeight := VPH[C];');
  GL('End;');
  GL('');
  GL('Procedure VPMove(C : LongInt);');
  GL('Begin');
  GL('  If (VPKind[C] = vkForm) Or (VPHw[C] = 0) Then Exit;');
  GL('  VPDummy := WinSetWindowPos(VPHw[C], 0, VPX[C], VPH[VPForm[C]] - VPY[C] - VPH[C], VPW[C], VPH[C], 3);');
  GL('End;');
  GL('');
  GL('Procedure VPSetLeft(C, V : LongInt);');
  GL('Begin');
  GL('  VPX[C] := V; VPMove(C);');
  GL('End;');
  GL('');
  GL('Procedure VPSetTop(C, V : LongInt);');
  GL('Begin');
  GL('  VPY[C] := V; VPMove(C);');
  GL('End;');
  GL('');
  GL('Procedure VPSetWidth(C, V : LongInt);');
  GL('Begin');
  GL('  VPW[C] := V; VPMove(C);');
  GL('End;');
  GL('');
  GL('Procedure VPSetHeight(C, V : LongInt);');
  GL('Begin');
  GL('  VPH[C] := V; VPMove(C);');
  GL('End;');
  GL('');
  GL('Function VPVisible(C : LongInt) : Boolean;');
  GL('Begin');
  GL('  VPVisible := (VPOpt[C] And voHidden) = 0;');
  GL('End;');
  GL('');
  GL('Procedure VPSetVisible(C : LongInt; B : Boolean);');
  GL('Begin');
  GL('  If B Then VPOpt[C] := VPOpt[C] And Not voHidden Else VPOpt[C] := VPOpt[C] Or voHidden;');
  GL('  If VPKind[C] = vkForm Then VPDummy := WinShowWindow(VPFr[C], Ord(B))');
  GL('  Else If VPHw[C] <> 0 Then VPDummy := WinShowWindow(VPHw[C], Ord(B));');
  GL('End;');
  GL('');
  GL('Function VPEnabled(C : LongInt) : Boolean;');
  GL('Begin');
  GL('  VPEnabled := (VPOpt[C] And voDisabled) = 0;');
  GL('End;');
  GL('');
  GL('Procedure VPTimerOn(C : LongInt);');
  GL('Begin');
  GL('  If (VPOpt[C] And voDisabled) = 0 Then');
  GL('    If VPIntv[C] > 0 Then VPDummy := WinStartTimer(VPHab, VPHw[VPForm[C]], 1000 + C, VPIntv[C]);');
  GL('End;');
  GL('');
  GL('Procedure VPSetEnabled(C : LongInt; B : Boolean);');
  GL('Begin');
  GL('  If B Then VPOpt[C] := VPOpt[C] And Not voDisabled Else VPOpt[C] := VPOpt[C] Or voDisabled;');
  GL('  If VPKind[C] = vkTimer Then');
  GL('  Begin');
  GL('    VPDummy := WinStopTimer(VPHab, VPHw[VPForm[C]], 1000 + C);');
  GL('    VPTimerOn(C);');
  GL('  End');
  GL('  Else If VPKind[C] = vkForm Then VPDummy := WinEnableWindow(VPFr[C], Ord(B))');
  GL('  Else If VPHw[C] <> 0 Then VPDummy := WinEnableWindow(VPHw[C], Ord(B));');
  GL('End;');
  GL('');
  GL('Function VPInterval(C : LongInt) : LongInt;');
  GL('Begin');
  GL('  VPInterval := VPIntv[C];');
  GL('End;');
  GL('');
  GL('Procedure VPSetInterval(C, V : LongInt);');
  GL('Begin');
  GL('  VPIntv[C] := V;');
  GL('  If VPHw[VPForm[C]] <> 0 Then');
  GL('  Begin');
  GL('    VPDummy := WinStopTimer(VPHab, VPHw[VPForm[C]], 1000 + C);');
  GL('    VPTimerOn(C);');
  GL('  End;');
  GL('End;');
  GL('');
  GL('{ case a cocher : 0 ou 1 ; bouton d''option : 1 si choisi }');
  GL('Function VPValue(C : LongInt) : LongInt;');
  GL('Begin');
  GL('  If VPHw[C] = 0 Then VPValue := 0 Else VPValue := WinSendMsg(VPHw[C], $0124, 0, 0) And 1;');
  GL('End;');
  GL('');
  GL('Procedure VPSetValue(C, V : LongInt);');
  GL('Begin');
  GL('  If VPHw[C] <> 0 Then VPDummy := WinSendMsg(VPHw[C], $0125, V And 1, 0);');
  GL('End;');
  GL('');
  GL('{ --- listes et listes deroulantes --- }');
  GL('');
  GL('Procedure VPAddItem(C : LongInt; S : String);');
  GL('Begin');
  GL('  If VPHw[C] <> 0 Then VPDummy := WinSendMsg(VPHw[C], $0161, $FFFF, VPZ(S));');
  GL('End;');
  GL('');
  GL('Procedure VPRemoveItem(C, I : LongInt);');
  GL('Begin');
  GL('  If VPHw[C] <> 0 Then VPDummy := WinSendMsg(VPHw[C], $0163, I, 0);');
  GL('End;');
  GL('');
  GL('Procedure VPClear(C : LongInt);');
  GL('Begin');
  GL('  If (VPKind[C] = vkList) Or (VPKind[C] = vkCombo) Then VPDummy := WinSendMsg(VPHw[C], $016E, 0, 0)');
  GL('  Else VPSetText(C, '''');');
  GL('End;');
  GL('');
  GL('Function VPListCount(C : LongInt) : LongInt;');
  GL('Begin');
  GL('  If VPHw[C] = 0 Then VPListCount := 0 Else VPListCount := WinSendMsg(VPHw[C], $0160, 0, 0);');
  GL('End;');
  GL('');
  GL('Function VPListIndex(C : LongInt) : LongInt;');
  GL('Var N : LongInt;');
  GL('Begin');
  GL('  N := -1;');
  GL('  If VPHw[C] <> 0 Then N := WinSendMsg(VPHw[C], $0165, $FFFF, 0);');
  GL('  If (N < 0) Or (N >= 65535) Then N := -1;');
  GL('  VPListIndex := N;');
  GL('End;');
  GL('');
  GL('Procedure VPSetListIndex(C, I : LongInt);');
  GL('Begin');
  GL('  If VPHw[C] <> 0 Then VPDummy := WinSendMsg(VPHw[C], $0164, I, 1);');
  GL('End;');
  GL('');
  GL('Function VPList(C, I : LongInt) : String;');
  GL('Var B : Array[0..299] Of Byte; K, N : LongInt; S : String;');
  GL('Begin');
  GL('  S := '''';');
  GL('  If VPHw[C] <> 0 Then');
  GL('  Begin');
  GL('    K := WinSendMsg(VPHw[C], $0168, (I And $FFFF) Or (255 Shl 16), LongInt(@B));');
  GL('    If K > 255 Then K := 255;');
  GL('    For N := 0 To K - 1 Do');
  GL('    Begin');
  GL('      If B[N] = 0 Then Break;');
  GL('      S := S + Chr(B[N]);');
  GL('    End;');
  GL('  End;');
  GL('  VPList := S;');
  GL('End;');
  GL('');
  GL('{ --- methodes --- }');
  GL('');
  GL('Procedure VPSetFocus(C : LongInt);');
  GL('Begin');
  GL('  If VPHw[C] <> 0 Then VPDummy := WinSetFocus(1, VPHw[C]);');
  GL('End;');
  GL('');
  GL('Procedure VPShow(C : LongInt);');
  GL('Begin');
  GL('  If VPKind[C] = vkForm Then');
  GL('  Begin');
  GL('    VPDummy := WinShowWindow(VPFr[C], 1);');
  GL('    VPDummy := WinSetActiveWindow(1, VPFr[C]);');
  GL('  End');
  GL('  Else VPSetVisible(C, True);');
  GL('End;');
  GL('');
  GL('Procedure VPHide(C : LongInt);');
  GL('Begin');
  GL('  If VPKind[C] = vkForm Then VPDummy := WinShowWindow(VPFr[C], 0) Else VPSetVisible(C, False);');
  GL('End;');
  GL('');
  GL('{ --- construction --- }');
  GL('');
  GL('Procedure VPAdd(C, Kind, Frm, X, Y, W, H : LongInt; Txt : String; Opt : LongInt);');
  GL('Begin');
  GL('  VPKind[C] := Kind; VPForm[C] := Frm; VPX[C] := X; VPY[C] := Y; VPW[C] := W; VPH[C] := H;');
  GL('  VPTxt[C] := Txt; VPOpt[C] := Opt; VPHw[C] := 0; VPFr[C] := 0; VPIntv[C] := 0; VPItems[C] := '''';');
  GL('  If (Kind = vkForm) And (VPStartup = 0) Then VPStartup := C;');
  GL('End;');
  GL('');
  GL('Procedure VPAddList(C : LongInt; S : String);');
  GL('Begin');
  GL('  VPItems[C] := S;');
  GL('End;');
  GL('');
  GL('Procedure VPEvent(C, Ev : LongInt); Forward;');
  GL('');
  GL('{ fenetre d''une feuille -> sa feuille }');
  GL('Function VPFormOf(H : LongInt) : LongInt;');
  GL('Var K : LongInt;');
  GL('Begin');
  GL('  VPFormOf := 0;');
  GL('  For K := 1 To VPMax Do');
  GL('    If (VPKind[K] = vkForm) And (VPHw[K] = H) Then');
  GL('    Begin');
  GL('      VPFormOf := K;');
  GL('      Exit;');
  GL('    End;');
  GL('End;');
  GL('');
  GL('Function VPFormProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;');
  GL('Var Rc : Array[0..3] Of LongInt; P, C, Code, F : LongInt;');
  GL('Begin');
  GL('  VPFormProc := 0;');
  GL('  Case Msg Of');
  GL('    VP_WM_PAINT :');
  GL('      Begin');
  GL('        P := WinBeginPaint(H, 0, LongInt(@Rc));');
  GL('        VPDummy := WinQueryWindowRect(H, LongInt(@Rc));');
  GL('        VPDummy := WinFillRect(P, LongInt(@Rc), 15);');
  GL('        VPDummy := WinEndPaint(P);');
  GL('      End;');
  GL('    VP_WM_COMMAND :');
  GL('      Begin');
  GL('        C := VPLo(Mp1) - 100;');
  GL('        If (C >= 1) And (C <= VPMax) Then VPEvent(C, evClick);');
  GL('      End;');
  GL('    VP_WM_CONTROL :');
  GL('      Begin');
  GL('        C := VPLo(Mp1) - 100;');
  GL('        Code := VPHi(Mp1);');
  GL('        If (C >= 1) And (C <= VPMax) Then');
  GL('          Case VPKind[C] Of');
  GL('            vkCheck, vkOption : If Code = 1 Then VPEvent(C, evClick);');
  GL('            vkText : If Code = 4 Then VPEvent(C, evChange);');
  GL('            vkList, vkCombo :');
  GL('              If Code = 1 Then VPEvent(C, evClick)');
  GL('              Else If Code = 5 Then VPEvent(C, evDblClick);');
  GL('          End;');
  GL('      End;');
  GL('    VP_WM_TIMER :');
  GL('      Begin');
  GL('        C := VPLo(Mp1) - 1000;');
  GL('        If (C >= 1) And (C <= VPMax) And (VPKind[C] = vkTimer) Then VPEvent(C, evTimer);');
  GL('      End;');
  GL('    VP_WM_CLOSE :');
  GL('      Begin');
  GL('        F := VPFormOf(H);');
  GL('        If F > 0 Then VPEvent(F, evUnload);');
  GL('        If (F = VPStartup) Or (F = 0) Then VPDummy := WinPostMsg(H, VP_WM_QUIT, 0, 0)');
  GL('        Else VPDummy := WinShowWindow(VPFr[F], 0);');
  GL('      End;');
  GL('  Else');
  GL('    VPFormProc := WinDefWindowProc(H, Msg, Mp1, Mp2);');
  GL('  End;');
  GL('End;');
  GL('');
  GL('Procedure VPCreateForm(F : LongInt);');
  GL('Var Fl, C, St, Cls, X, Y, K : LongInt; Rc : Array[0..3] Of LongInt; Ctl : Array[0..3] Of LongInt;');
  GL('Begin');
  GL('  Fl := 1 Or 2 Or $10 Or $100 Or $800;');
  GL('  VPHw[F] := 0;');
  GL('  VPFr[F] := WinCreateStdWindow(1, 0, LongInt(@Fl), VPZ(''VPFORM''), VPZ2(VPTxt[F]), 0, 0, 0, LongInt(@VPHw[F]));');
  GL('  Rc[0] := 0; Rc[1] := 0; Rc[2] := VPW[F]; Rc[3] := VPH[F];');
  GL('  VPDummy := WinCalcFrameRect(VPFr[F], LongInt(@Rc), 0);');
  GL('  X := (WinQuerySysValue(1, 20) - (Rc[2] - Rc[0])) Div 2 + VPX[F];');
  GL('  Y := (WinQuerySysValue(1, 21) - (Rc[3] - Rc[1])) Div 2 - VPY[F];');
  GL('  If X < 0 Then X := 0;');
  GL('  If Y < 0 Then Y := 0;');
  GL('  VPDummy := WinSetWindowPos(VPFr[F], 3, X, Y, Rc[2] - Rc[0], Rc[3] - Rc[1], 1 Or 2 Or 4);');
  GL('  For C := 1 To VPMax Do');
  GL('    If (VPForm[C] = F) And (VPKind[C] <> vkForm) Then');
  GL('    Begin');
  GL('      St := 0;');
  GL('      If (VPOpt[C] And voHidden) = 0 Then St := St Or $80000000;');
  GL('      If (VPOpt[C] And voDisabled) <> 0 Then St := St Or $40000000;');
  GL('      If (VPOpt[C] And voGroup) <> 0 Then St := St Or $10000;');
  GL('      Cls := 0;');
  GL('      Case VPKind[C] Of');
  GL('        vkButton : Begin Cls := $FFFF0003; St := St Or $20000; End;');
  GL('        vkCheck : Begin Cls := $FFFF0003; St := St Or 2 Or $20000; End;');
  GL('        vkOption : Begin Cls := $FFFF0003; St := St Or 4 Or $20000; End;');
  GL('        vkText :');
  GL('          Begin');
  GL('            Cls := $FFFF0006; St := St Or 4 Or 8 Or $20000;');
  GL('            If (VPOpt[C] And voRight) <> 0 Then St := St Or 2;');
  GL('            If (VPOpt[C] And voCenter) <> 0 Then St := St Or 1;');
  GL('            If (VPOpt[C] And voLocked) <> 0 Then St := St Or $20;');
  GL('          End;');
  GL('        vkLabel :');
  GL('          Begin');
  GL('            Cls := $FFFF0005; St := St Or 1 Or $400;');
  GL('            If (VPOpt[C] And voRight) <> 0 Then St := St Or $200;');
  GL('            If (VPOpt[C] And voCenter) <> 0 Then St := St Or $100;');
  GL('          End;');
  GL('        vkFrame : Begin Cls := $FFFF0005; St := St Or 2; End;');
  GL('        vkList : Begin Cls := $FFFF0007; St := St Or $20000; End;');
  GL('        vkCombo : Begin Cls := $FFFF0002; St := St Or 4 Or $20000; End;');
  GL('      End;');
  GL('      If Cls = 0 Then Continue;');
  GL('      Ctl[0] := VPH[C];');
  GL('      VPHw[C] := WinCreateWindow(VPHw[F], Cls, VPZ(VPTxt[C]), St, VPX[C], VPH[F] - VPY[C] - Ctl[0], VPW[C], Ctl[0],');
  GL('                                 VPHw[F], 4, 100 + C, 0, 0);');
  GL('      If VPKind[C] = vkText Then VPDummy := WinSendMsg(VPHw[C], $0143, 250, 0);');
  GL('      { fond gris de la feuille pour les libelles, cadres, cases et options }');
  GL('      If (VPKind[C] = vkLabel) Or (VPKind[C] = vkFrame) Or (VPKind[C] = vkCheck) Or (VPKind[C] = vkOption) Then');
  GL('      Begin');
  GL('        K := 15;');
  GL('        VPDummy := WinSetPresParam(VPHw[C], 4, 4, LongInt(@K));');
  GL('      End;');
  GL('      If ((VPKind[C] = vkCheck) Or (VPKind[C] = vkOption)) And ((VPOpt[C] And voChecked) <> 0) Then');
  GL('        VPDummy := WinSendMsg(VPHw[C], $0125, 1, 0);');
  GL('      If ((VPKind[C] = vkList) Or (VPKind[C] = vkCombo)) And (VPItems[C] <> '''') Then');
  GL('      Begin');
  GL('        X := 1;');
  GL('        For K := 1 To Length(VPItems[C]) + 1 Do');
  GL('          If (K > Length(VPItems[C])) Or (VPItems[C][K] = '';'') Then');
  GL('          Begin');
  GL('            If K > X Then VPAddItem(C, Copy(VPItems[C], X, K - X));');
  GL('            X := K + 1;');
  GL('          End;');
  GL('        If VPKind[C] = vkCombo Then VPDummy := WinSetWindowText(VPHw[C], VPZ(VPTxt[C]));');
  GL('      End;');
  GL('    End;');
  GL('  For C := 1 To VPMax Do');
  GL('    If (VPForm[C] = F) And (VPKind[C] = vkTimer) Then VPTimerOn(C);');
  GL('End;');
  GL('');
  GL('Procedure VPBuild; Forward;');
  GL('');
  GL('Procedure VPRun;');
  GL('Var K : LongInt;');
  GL('Begin');
  GL('  VPStartup := 0; VPQuitting := False;');
  GL('  For K := 1 To VPMax Do');
  GL('  Begin');
  GL('    VPKind[K] := 0; VPHw[K] := 0; VPFr[K] := 0;');
  GL('  End;');
  GL('  VPBuild;');
  GL('  VPHab := WinInitialize(0);');
  GL('  VPHmq := WinCreateMsgQueue(VPHab, 0);');
  GL('  VPDummy := WinRegisterClass(VPHab, VPZ(''VPFORM''), LongInt(@VPFormProc), 0, 0);');
  GL('  For K := 1 To VPMax Do');
  GL('    If VPKind[K] = vkForm Then VPCreateForm(K);');
  GL('  For K := 1 To VPMax Do');
  GL('    If VPKind[K] = vkForm Then VPEvent(K, evLoad);');
  GL('  If VPStartup > 0 Then');
  GL('  Begin');
  GL('    VPDummy := WinShowWindow(VPFr[VPStartup], 1);');
  GL('    VPDummy := WinSetActiveWindow(1, VPFr[VPStartup]);');
  GL('  End;');
  GL('  If Not VPQuitting Then');
  GL('    While WinGetMsg(VPHab, LongInt(@VPMsg), 0, 0, 0) <> 0 Do VPDummy := WinDispatchMsg(VPHab, LongInt(@VPMsg));');
  GL('  For K := 1 To VPMax Do');
  GL('    If (VPKind[K] = vkForm) And (VPFr[K] <> 0) Then VPDummy := WinDestroyWindow(VPFr[K]);');
  GL('End;');
  GL('');
  GL('(* ===== fin de la bibliotheque d''execution ===== *)');
End;

{ ==================================================================== }
{ Reecriture du code des feuilles : proprietes et methodes des          }
{ controles (Text1.Text := ...) -> appels de la bibliotheque            }
{ ==================================================================== }

Const
  MaxProcs = 300;

Var
  RwOut, RwHold : TBuf;
  RwPend : Boolean;
  RwDepth, RwSetDepth : LongInt;
  RL : PBytes;
  RN : LongInt;
  NProcs : LongInt;
  ProcNm : Array[0..MaxProcs - 1] Of String[40];
  CtUp : Array[1..MaxCtl] Of String[40];
  GOrd : Array[1..MaxCtl] Of LongInt;
  GFirst : Array[1..MaxCtl] Of Boolean;
  NGOrd : LongInt;

Function RCh(I : LongInt) : LongInt;
Begin
  If (I >= 0) And (I < RN) Then RCh := RL^[I] Else RCh := 0;
End;

Function IsIdC(C : LongInt) : Boolean;
Begin
  IsIdC := ((C >= 65) And (C <= 90)) Or ((C >= 97) And (C <= 122)) Or (C = 95) Or ((C >= 48) And (C <= 57));
End;

Function SkipSp(I : LongInt) : LongInt;
Begin
  While (I < RN) And ((RL^[I] = 32) Or (RL^[I] = 9)) Do Inc(I);
  SkipSp := I;
End;

{ identificateur a partir de I ; E : position qui le suit }
Function ReadId(I : LongInt; Var E : LongInt) : String;
Var S : String;
Begin
  S := '';
  E := I;
  If (I < RN) And IsIdC(RL^[I]) And Not ((RL^[I] >= 48) And (RL^[I] <= 57)) Then
    While (E < RN) And IsIdC(RL^[E]) Do
    Begin
      If Length(S) < 250 Then S := S + Chr(RL^[E]);
      Inc(E);
    End;
  ReadId := S;
End;

Procedure RwEmit(S : String);
Begin
  If RwHold.Len > 0 Then
  Begin
    BufAddB(RwOut, RwHold.P, RwHold.Len);
    RwHold.Len := 0;
  End;
  BufAdd(RwOut, S);
End;

Procedure RwEmitB(P : PBytes; N : LongInt);
Begin
  If RwHold.Len > 0 Then
  Begin
    BufAddB(RwOut, RwHold.P, RwHold.Len);
    RwHold.Len := 0;
  End;
  BufAddB(RwOut, P, N);
End;

{ blancs, commentaires et fins de ligne : mis de cote pendant une affectation }
Procedure RwWsC(C : LongInt);
Begin
  If RwPend Then BufAddC(RwHold, C) Else BufAddC(RwOut, C);
End;

{ fin d'une affectation de propriete : parenthese fermante }
Procedure RwClose;
Begin
  If Not RwPend Then Exit;
  BufAddC(RwOut, Ord(')'));
  RwPend := False;
  If RwHold.Len > 0 Then BufAddB(RwOut, RwHold.P, RwHold.Len);
  RwHold.Len := 0;
End;

{ 1 : propriete lue et ecrite ; 2 : lue seulement ; 3 : methode ; 0 : inconnue }
Function MemberKind(M : String; Var R : String) : LongInt;
Const
  L1 = ' CAPTION TEXT LEFT TOP WIDTH HEIGHT VISIBLE ENABLED INTERVAL VALUE LISTINDEX ';
  L2 = ' LISTCOUNT LIST ';
  L3 = ' ADDITEM REMOVEITEM CLEAR SETFOCUS SHOW HIDE ';
Var U : String;
Begin
  U := ' ' + UpStr(M) + ' ';
  MemberKind := 0; R := '';
  If (M = '') Or (Pos('  ', U) > 0) Then Exit;
  If Pos(U, L1) > 0 Then MemberKind := 1
  Else If Pos(U, L2) > 0 Then MemberKind := 2
  Else If Pos(U, L3) > 0 Then MemberKind := 3
  Else Exit;
  U := UpStr(M);
  If U = 'CAPTION' Then R := 'Caption' Else If U = 'TEXT' Then R := 'Text'
  Else If U = 'LEFT' Then R := 'Left' Else If U = 'TOP' Then R := 'Top'
  Else If U = 'WIDTH' Then R := 'Width' Else If U = 'HEIGHT' Then R := 'Height'
  Else If U = 'VISIBLE' Then R := 'Visible' Else If U = 'ENABLED' Then R := 'Enabled'
  Else If U = 'INTERVAL' Then R := 'Interval' Else If U = 'VALUE' Then R := 'Value'
  Else If U = 'LISTINDEX' Then R := 'ListIndex' Else If U = 'LISTCOUNT' Then R := 'ListCount'
  Else If U = 'LIST' Then R := 'List' Else If U = 'ADDITEM' Then R := 'AddItem'
  Else If U = 'REMOVEITEM' Then R := 'RemoveItem' Else If U = 'CLEAR' Then R := 'Clear'
  Else If U = 'SETFOCUS' Then R := 'SetFocus' Else If U = 'SHOW' Then R := 'Show'
  Else R := 'Hide';
End;

Function CtlByUp(U : String) : LongInt;
Var K : LongInt;
Begin
  CtlByUp := 0;
  For K := 1 To NCtl Do
    If CtUp[K][1] = U[1] Then
      If CtUp[K] = U Then
      Begin
        CtlByUp := K;
        Exit;
      End;
End;

Procedure AddProc(S : String);
Begin
  If NProcs < MaxProcs Then
  Begin
    ProcNm[NProcs] := Copy(UpStr(S), 1, 40);
    Inc(NProcs);
  End;
End;

Function HasProc(S : String) : Boolean;
Var K : LongInt;
Begin
  HasProc := False;
  S := UpStr(S);
  For K := 0 To NProcs - 1 Do
    If ProcNm[K] = S Then
    Begin
      HasProc := True;
      Exit;
    End;
End;

{ reecrit le code de la feuille F dans RwOut (lignes separees par LF) }
Procedure RewriteForm(F : LongInt);
Var D, Y, I, J, K, E, E2, A, A2, C, C2, MK, St, Ch : LongInt; W, U, P2, R, Nm : String; WaitName : Boolean;
Begin
  RwOut.Len := 0; RwHold.Len := 0;
  RwPend := False; RwDepth := 0; RwSetDepth := 0;
  WaitName := False; St := 0;
  D := CtDoc[F];
  If D < 0 Then Exit;
  For Y := 0 To DN[D] - 1 Do
  Begin
    If Y > 0 Then RwWsC(10);
    RL := LP(D, Y); RN := LLen(D, Y);
    I := 0;
    While I < RN Do
    Begin
      Ch := RL^[I];
      If St = 1 Then
      Begin
        RwWsC(Ch);
        If Ch = 125 Then St := 0;
        Inc(I);
        Continue;
      End;
      If St = 2 Then
      Begin
        If (Ch = 42) And (RCh(I + 1) = 41) Then
        Begin
          RwWsC(42); RwWsC(41);
          I := I + 2;
          St := 0;
        End
        Else
        Begin
          RwWsC(Ch);
          Inc(I);
        End;
        Continue;
      End;
      If (Ch = 32) Or (Ch = 9) Then
      Begin
        RwWsC(Ch);
        Inc(I);
      End
      Else If Ch = 123 Then
      Begin
        St := 1;
        RwWsC(Ch);
        Inc(I);
      End
      Else If (Ch = 40) And (RCh(I + 1) = 42) Then
      Begin
        St := 2;
        RwWsC(40); RwWsC(42);
        I := I + 2;
      End
      Else If (Ch = 47) And (RCh(I + 1) = 47) Then
      Begin
        While I < RN Do
        Begin
          RwWsC(RL^[I]);
          Inc(I);
        End;
      End
      Else If Ch = 39 Then
      Begin
        { chaine }
        J := I + 1;
        While J < RN Do
        Begin
          If RL^[J] = 39 Then
          Begin
            If RCh(J + 1) = 39 Then J := J + 2
            Else Break;
          End
          Else Inc(J);
        End;
        If J < RN Then Inc(J);
        RwEmitB(@RL^[I], J - I);
        I := J;
      End
      Else If (Ch = 35) Or (Ch = 36) Or ((Ch >= 48) And (Ch <= 57)) Then
      Begin
        { nombre ou caractere #nn }
        J := I + 1;
        While (J < RN) And (IsIdC(RL^[J]) Or ((RL^[J] = 46) And (RCh(J + 1) >= 48) And (RCh(J + 1) <= 57))) Do Inc(J);
        RwEmitB(@RL^[I], J - I);
        I := J;
      End
      Else If IsIdC(Ch) Then
      Begin
        W := ReadId(I, E);
        U := UpStr(W);
        If RwPend And (RwDepth = RwSetDepth) And ((U = 'END') Or (U = 'ELSE') Or (U = 'UNTIL')) Then RwClose;
        If WaitName Then
        Begin
          AddProc(W);
          WaitName := False;
        End;
        If (U = 'PROCEDURE') Or (U = 'FUNCTION') Then WaitName := True;
        If U = 'ME' Then C := F Else C := CtlByUp(Copy(U, 1, 40));
        If C = 0 Then
        Begin
          RwEmit(W);
          I := E;
          Continue;
        End;
        J := SkipSp(E);
        If RCh(J) <> 46 Then
        Begin
          RwEmit(CtName[C]);
          I := E;
          Continue;
        End;
        K := SkipSp(J + 1);
        P2 := ReadId(K, E2);
        { Form2.Text1 : controle d'une feuille }
        If (P2 <> '') And (CtKind[C] = vkForm) Then
        Begin
          C2 := CtlByUp(Copy(UpStr(P2), 1, 40));
          If (C2 > 0) And (C2 <> C) And (CtForm[C2] = C) Then
          Begin
            C := C2;
            A := SkipSp(E2);
            If RCh(A) <> 46 Then
            Begin
              RwEmit(CtName[C]);
              I := E2;
              Continue;
            End;
            K := SkipSp(A + 1);
            P2 := ReadId(K, E2);
          End;
        End;
        MK := MemberKind(P2, R);
        If MK = 0 Then
        Begin
          { membre inconnu : laisse tel quel (le compilateur le signalera) }
          RwEmit(W);
          I := E;
          Continue;
        End;
        Nm := CtName[C];
        A := SkipSp(E2);
        If (MK = 1) And (RCh(A) = 58) And (RCh(A + 1) = 61) Then
        Begin
          RwEmit('VPSet' + R + '(' + Nm + ',');
          I := A + 2;
          RwPend := True;
          RwSetDepth := RwDepth;
          Continue;
        End;
        If MK = 3 Then
        Begin
          If RCh(A) = 40 Then
          Begin
            A2 := SkipSp(A + 1);
            If RCh(A2) = 41 Then
            Begin
              RwEmit('VP' + R + '(' + Nm + ')');
              I := A2 + 1;
            End
            Else
            Begin
              RwEmit('VP' + R + '(' + Nm + ', ');
              I := A + 1;
              Inc(RwDepth);
            End;
          End
          Else
          Begin
            RwEmit('VP' + R + '(' + Nm + ')');
            I := E2;
          End;
          Continue;
        End;
        If (R = 'List') And (RCh(A) = 40) Then
        Begin
          RwEmit('VPList(' + Nm + ', ');
          I := A + 1;
          Inc(RwDepth);
        End
        Else
        Begin
          RwEmit('VP' + R + '(' + Nm + ')');
          I := E2;
        End;
      End
      Else
      Begin
        If (Ch = 40) Or (Ch = 91) Then Inc(RwDepth)
        Else If (Ch = 41) Or (Ch = 93) Then Dec(RwDepth)
        Else If (Ch = 59) And RwPend And (RwDepth = RwSetDepth) Then RwClose;
        RwEmitB(@RL^[I], 1);
        Inc(I);
      End;
    End;
  End;
  RwClose;
End;

{ ==================================================================== }
{ Generation du programme                                               }
{ ==================================================================== }

Function KindConst(K : LongInt) : String;
Begin
  Case K Of
    vkText : KindConst := 'vkText';
    vkButton : KindConst := 'vkButton';
    vkCheck : KindConst := 'vkCheck';
    vkOption : KindConst := 'vkOption';
    vkList : KindConst := 'vkList';
    vkCombo : KindConst := 'vkCombo';
  Else
    KindConst := 'vk' + KindName(K);
  End;
End;

{ cadre qui contient le controle C (le plus petit) ; 0 : la feuille }
Function ContainerOf(C : LongInt) : LongInt;
Var K, Cx, Cy, Best, A : LongInt;
Begin
  ContainerOf := 0;
  If (CtKind[C] = vkForm) Or (CtKind[C] = vkFrame) Then Exit;
  Cx := CtX[C] + CtW[C] Div 2; Cy := CtY[C] + CtH[C] Div 2;
  Best := MaxLongInt;
  For K := 1 To NCtl Do
    If (CtKind[K] = vkFrame) And (CtForm[K] = CtForm[C]) Then
      If (Cx >= CtX[K]) And (Cx < CtX[K] + CtW[K]) And (Cy >= CtY[K]) And (Cy < CtY[K] + CtH[K]) Then
      Begin
        A := CtW[K] * CtH[K];
        If A < Best Then
        Begin
          Best := A;
          ContainerOf := K;
        End;
      End;
End;

Procedure OrdAdd(C : LongInt; Var First : Boolean);
Begin
  Inc(NGOrd);
  GOrd[NGOrd] := C;
  GFirst[C] := First;
  First := False;
End;

{ ordre de creation : feuille, controles hors cadre, contenu de chaque
  cadre (un groupe d'options par cadre), puis les cadres (dessous) }
Procedure BuildOrder;
Var F, C, Fr : LongInt; First : Boolean;
Begin
  NGOrd := 0;
  For F := 1 To NCtl Do
    If CtKind[F] = vkForm Then
    Begin
      First := True;
      OrdAdd(F, First);
      First := True;
      For C := 1 To NCtl Do
        If (CtForm[C] = F) And (C <> F) And (CtKind[C] <> vkFrame) And (ContainerOf(C) = 0) Then OrdAdd(C, First);
      For Fr := 1 To NCtl Do
        If (CtForm[Fr] = F) And (CtKind[Fr] = vkFrame) Then
        Begin
          First := True;
          For C := 1 To NCtl Do
            If (CtForm[C] = F) And (C <> F) And (CtKind[C] <> vkFrame) And (ContainerOf(C) = Fr) Then OrdAdd(C, First);
        End;
      For Fr := 1 To NCtl Do
        If (CtForm[Fr] = F) And (CtKind[Fr] = vkFrame) Then
        Begin
          First := True;
          OrdAdd(Fr, First);
        End;
    End;
End;

Function OptStr(C : LongInt) : String;
Var S : String;
Begin
  S := '';
  If Not CtEn[C] Then S := S + ' Or voDisabled';
  If (Not CtVis[C]) And (CtKind[C] <> vkForm) And (CtKind[C] <> vkTimer) Then S := S + ' Or voHidden';
  If CtKind[C] = vkLabel Then
  Begin
    If CtAlign[C] = 1 Then S := S + ' Or voRight'
    Else If CtAlign[C] = 2 Then S := S + ' Or voCenter';
  End;
  If (CtKind[C] = vkText) And CtLocked[C] Then S := S + ' Or voLocked';
  If ((CtKind[C] = vkCheck) Or (CtKind[C] = vkOption)) And (CtValue[C] = 1) Then S := S + ' Or voChecked';
  If GFirst[C] And (CtKind[C] <> vkForm) And (CtKind[C] <> vkTimer) Then S := S + ' Or voGroup';
  If S = '' Then OptStr := '0' Else OptStr := Copy(S, 5, 255);
End;

Function CodeName : String;
Begin
  If IsIdent(PrjName) Then CodeName := PrjName Else CodeName := 'ProjetVP';
End;

{ fabrique le programme Pascal complet dans GenB }
Procedure GenProgram;
Var K, C, F, E, St, N : LongInt; S, T : String; Any : Boolean;
Begin
  If GMapF = Nil Then
  Begin
    GetMem(GMapF, MaxGen * 4);
    GetMem(GMapL, MaxGen * 4);
  End;
  GenB.Len := 0; GenN := 0; GCurF := 0; GCurL := 0; NProcs := 0;
  For K := 1 To NCtl Do CtUp[K] := Copy(UpStr(CtName[K]), 1, 40);
  BuildOrder;
  F := FirstForm;
  GL('Program ' + CodeName + ';');
  GL('{$R-,S-,I-}');
  GL('(* Programme g'#130'n'#130'r'#130' par Visual Pascal (OS/2-0) '#133' partir du projet ' + PrjName + '. *)');
  GL('Const');
  GL('  VPMax = ' + IStr(MaxI(1, NGOrd)) + ';');
  If F > 0 Then GL('  VPTitle = ' + PasStr(CtText[F]) + ';') Else GL('  VPTitle = ''Visual Pascal'';');
  GL('');
  EmitRuntime;
  GL('');
  If NGOrd > 0 Then
  Begin
    GL('Const');
    For K := 1 To NGOrd Do GL('  ' + CtName[GOrd[K]] + ' = ' + IStr(K) + ';');
    GL('');
  End;
  GL('Procedure VPBuild;');
  GL('Begin');
  For K := 1 To NGOrd Do
  Begin
    C := GOrd[K];
    If CtKind[C] = vkForm Then
      GL('  VPAdd(' + CtName[C] + ', vkForm, 0, 0, 0, ' + IStr(CtW[C]) + ', ' + IStr(CtH[C]) + ', ' + PasStr(CtText[C]) +
         ', ' + OptStr(C) + ');')
    Else
      GL('  VPAdd(' + CtName[C] + ', ' + KindConst(CtKind[C]) + ', ' + CtName[CtForm[C]] + ', ' + IStr(CtX[C]) + ', ' +
         IStr(CtY[C]) + ', ' + IStr(CtW[C]) + ', ' + IStr(CtH[C]) + ', ' + PasStr(CtText[C]) + ', ' + OptStr(C) + ');');
    If ((CtKind[C] = vkList) Or (CtKind[C] = vkCombo)) And (CtItems[C] <> '') Then
      GL('  VPAddList(' + CtName[C] + ', ' + PasStr(CtItems[C]) + ');');
    If CtKind[C] = vkTimer Then GL('  VPIntv[' + CtName[C] + '] := ' + IStr(CtIntv[C]) + ';');
  End;
  GL('End;');
  { code des feuilles }
  For K := 1 To NGOrd Do
  Begin
    F := GOrd[K];
    If CtKind[F] <> vkForm Then Continue;
    GL('');
    GL('{ ===== ' + CtName[F] + ' ===== }');
    RewriteForm(F);
    St := 0; N := 0;
    For E := 0 To RwOut.Len Do
      If (E = RwOut.Len) Or (RwOut.P^[E] = 10) Then
      Begin
        GCurF := F; GCurL := N;
        If E > St Then GLB(@RwOut.P^[St], E - St) Else GL('');
        Inc(N);
        St := E + 1;
      End;
    GCurF := 0; GCurL := 0;
  End;
  { aiguillage des evenements }
  GL('');
  GL('Procedure VPEvent(C, Ev : LongInt);');
  GL('Begin');
  Any := False;
  For K := 1 To NGOrd Do
  Begin
    C := GOrd[K];
    N := 0;
    For E := 1 To EvCount(CtKind[C]) Do
      If HasProc(CtName[C] + '_' + EvName(CtKind[C], E)) Then Inc(N);
    If N = 0 Then Continue;
    If Not Any Then GL('  Case C Of');
    Any := True;
    GL('    ' + CtName[C] + ' :');
    GL('      Begin');
    For E := 1 To EvCount(CtKind[C]) Do
    Begin
      T := EvName(CtKind[C], E);
      If HasProc(CtName[C] + '_' + T) Then GL('        If Ev = ' + EvConst(T) + ' Then ' + CtName[C] + '_' + T + ';');
    End;
    GL('      End;');
  End;
  If Any Then GL('  End;');
  GL('End;');
  GL('');
  GL('BEGIN');
  GL('  VPRun;');
  GL('END.');
End;

{ ==================================================================== }
{ Fichier du projet (.VPP)                                              }
{ ==================================================================== }

Procedure SaveToBuf(Var B : TBuf);
Var F, C, P, Y, D : LongInt;
Begin
  BufAdd(B, 'VisualPascal 1'#13#10);
  BufAdd(B, 'Projet = ' + PrjName + #13#10);
  For F := 1 To NCtl Do
    If CtKind[F] = vkForm Then
    Begin
      BufAdd(B, 'Begin Form ' + CtName[F] + #13#10);
      For P := 2 To NProps Do
        If PropHas(vkForm, P) Then BufAdd(B, '   ' + PropName(P) + ' = ' + PropGet(F, P) + #13#10);
      For C := 1 To NCtl Do
        If (CtForm[C] = F) And (C <> F) Then
        Begin
          BufAdd(B, '   Begin ' + KindName(CtKind[C]) + ' ' + CtName[C] + #13#10);
          For P := 2 To NProps Do
            If PropHas(CtKind[C], P) Then BufAdd(B, '      ' + PropName(P) + ' = ' + PropGet(C, P) + #13#10);
          BufAdd(B, '   End'#13#10);
        End;
      BufAdd(B, 'End'#13#10);
      D := CtDoc[F];
      If D >= 0 Then
        For Y := 0 To DN[D] - 1 Do
        Begin
          BufAddC(B, Ord('|'));
          BufAddB(B, LP(D, Y), LLen(D, Y));
          BufAdd(B, #13#10);
        End;
    End;
End;

Function SaveProject(Name : String) : Boolean;
Var B : TBuf; H, K : LongInt;
Begin
  SaveProject := False;
  BufInit(B);
  SaveToBuf(B);
  If FOpenWrite(Name, H) Then
  Begin
    SaveProject := FWrite(H, B.P, B.Len) = B.Len;
    DosClose(H);
  End;
  BufFree(B);
  PrjFile := Name;
  PrjMod := False;
  For K := 1 To NCtl Do If (CtKind[K] = vkForm) And (CtDoc[K] >= 0) Then DMod[CtDoc[K]] := False;
End;

{ ligne [St, E) du tampon -> chaine (255 premiers caracteres) }
Function BufLine(Var B : TBuf; St, E : LongInt) : String;
Var S : String; N : LongInt;
Begin
  N := E - St;
  If (N > 0) And (B.P^[E - 1] = 13) Then Dec(N);
  If N > 255 Then N := 255;
  If N < 0 Then N := 0;
  S[0] := Chr(N);
  If N > 0 Then Move(B.P^[St], S[1], N);
  BufLine := S;
End;

{ charge un projet ; rend un message d'erreur ('' : correct) }
Function LoadFromBuf(Var B : TBuf) : String;
Var St, E, F, C, K, P, N, D, Ln : LongInt; S, T, W1, W2, V, Er, Res : String; Fresh : Boolean;
Begin
  Res := '';
  ClearProject;
  F := 0; C := 0; Fresh := False; Ln := 0;
  St := 0;
  For E := 0 To B.Len Do
    If (E = B.Len) Or (B.P^[E] = 10) Then
    Begin
      Inc(Ln);
      If (E > St) And (B.P^[St] = Ord('|')) Then
      Begin
        { ligne de code de la feuille F }
        If F > 0 Then
        Begin
          D := CtDoc[F];
          N := E - St - 1;
          If (N > 0) And (B.P^[E - 1] = 13) Then Dec(N);
          If Fresh Then
          Begin
            RawDel(D, 0);
            Fresh := False;
          End;
          If N > 0 Then RawIns(D, DN[D], @B.P^[St + 1], N) Else RawIns(D, DN[D], Nil, 0);
        End;
        St := E + 1;
        Continue;
      End;
      S := BufLine(B, St, E);
      St := E + 1;
      T := Trim(S);
      If T = '' Then Continue;
      If UpStr(Copy(T, 1, 6)) = 'BEGIN ' Then
      Begin
        T := Trim(Copy(T, 7, 255));
        K := Pos(' ', T);
        If K = 0 Then K := Length(T) + 1;
        W1 := Copy(T, 1, K - 1); W2 := Trim(Copy(T, K + 1, 255));
        K := KindFromName(W1);
        If K = 0 Then
        Begin
          Res := 'Ligne ' + IStr(Ln) + ' : sorte de contr'#147'le inconnue (' + W1 + ').';
          Break;
        End;
        If K = vkForm Then
        Begin
          F := NewForm;
          If F = 0 Then
          Begin
            Res := 'Trop de feuilles.';
            Break;
          End;
          C := F;
          Fresh := True;
        End
        Else
        Begin
          If F = 0 Then
          Begin
            Res := 'Ligne ' + IStr(Ln) + ' : contr'#147'le hors d''une feuille.';
            Break;
          End;
          C := AddCtl(K, F, 0, 0, 0, 0);
          If C = 0 Then
          Begin
            Res := 'Trop de contr'#147'les.';
            Break;
          End;
          DefSize(K, CtW[C], CtH[C]);
        End;
        If (W2 <> '') And IsIdent(W2) And (FindCtl(W2) = 0) Then
        Begin
          CtName[C] := W2;
          If K = vkForm Then DName[CtDoc[C]] := W2;
          If (K <> vkTimer) And (K <> vkList) Then CtText[C] := W2;
        End;
      End
      Else If UpStr(T) = 'END' Then C := F
      Else
      Begin
        K := Pos('=', S);
        If K = 0 Then Continue;
        W1 := Trim(Copy(S, 1, K - 1));
        V := Copy(S, K + 1, 255);
        If (V <> '') And (V[1] = ' ') Then Delete(V, 1, 1);
        If UpStr(W1) = 'PROJET' Then PrjName := Trim(V)
        Else If C > 0 Then
        Begin
          P := PropFromName(W1);
          If (P > ppName) And PropHas(CtKind[C], P) Then
          Begin
            Er := PropSet(C, P, V);
            If Er <> '' Then
            Begin
              Res := 'Ligne ' + IStr(Ln) + ' : ' + W1 + ' : ' + Er;
              Break;
            End;
          End;
        End;
      End;
    End;
  If FormCount = 0 Then
  Begin
    If NewForm = 0 Then ;
  End;
  For K := 1 To NCtl Do
    If (CtKind[K] = vkForm) And (CtDoc[K] >= 0) Then
    Begin
      D := CtDoc[K];
      If DN[D] = 0 Then RawIns(D, 0, Nil, 0);
      DMod[D] := False; DUN[D] := 0; DRN[D] := 0; DStOk[D] := 0;
      DCX[D] := 0; DCY[D] := 0; DTop[D] := 0; DLeft[D] := 0; DSel[D] := False;
    End;
  PrjMod := False;
  LoadFromBuf := Res;
End;

Function LoadProject(Name : String) : String;
Var B : TBuf; H, R : LongInt; Er : String;
Begin
  If Not FOpenRead(Name, H) Then
  Begin
    LoadProject := 'Impossible d''ouvrir ' + Name + '.';
    Exit;
  End;
  BufInit(B);
  Repeat
    If Not BufGrow(B, 65536) Then Break;
    R := FRead(H, @B.P^[B.Len], 65536);
    If R > 0 Then B.Len := B.Len + R;
  Until R <= 0;
  DosClose(H);
  Er := LoadFromBuf(B);
  BufFree(B);
  If Er = '' Then PrjFile := Name;
  LoadProject := Er;
End;

{ ==================================================================== }
{ Exemples integres : Calculatrice, Demonstration                       }
{ ==================================================================== }

Var
  SampB : TBuf;

Procedure L(S : String);
Begin
  BufAdd(SampB, S);
  BufAddC(SampB, 13); BufAddC(SampB, 10);
End;

Procedure SampleCalc;
Begin
  SampB.Len := 0;
  L('VisualPascal 1');
  L('Projet = Calculatrice');
  L('Begin Form Form1');
  L('   Caption = Calculatrice');
  L('   Width = 384');
  L('   Height = 264');
  L('   Begin TextBox Text1');
  L('      Text = 0');
  L('      Left = 8');
  L('      Top = 8');
  L('      Width = 232');
  L('      Height = 26');
  L('      Locked = True');
  L('   End');
  L('   Begin CommandButton Cmd7');
  L('      Caption = 7');
  L('      Left = 8');
  L('      Top = 44');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton Cmd8');
  L('      Caption = 8');
  L('      Left = 68');
  L('      Top = 44');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton Cmd9');
  L('      Caption = 9');
  L('      Left = 128');
  L('      Top = 44');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton CmdDiv');
  L('      Caption = /');
  L('      Left = 188');
  L('      Top = 44');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton Cmd4');
  L('      Caption = 4');
  L('      Left = 8');
  L('      Top = 88');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton Cmd5');
  L('      Caption = 5');
  L('      Left = 68');
  L('      Top = 88');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton Cmd6');
  L('      Caption = 6');
  L('      Left = 128');
  L('      Top = 88');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton CmdMul');
  L('      Caption = *');
  L('      Left = 188');
  L('      Top = 88');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton Cmd1');
  L('      Caption = 1');
  L('      Left = 8');
  L('      Top = 132');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton Cmd2');
  L('      Caption = 2');
  L('      Left = 68');
  L('      Top = 132');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton Cmd3');
  L('      Caption = 3');
  L('      Left = 128');
  L('      Top = 132');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton CmdMoins');
  L('      Caption = -');
  L('      Left = 188');
  L('      Top = 132');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton Cmd0');
  L('      Caption = 0');
  L('      Left = 8');
  L('      Top = 176');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton CmdPoint');
  L('      Caption = .');
  L('      Left = 68');
  L('      Top = 176');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton CmdEgal');
  L('      Caption = =');
  L('      Left = 128');
  L('      Top = 176');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton CmdPlus');
  L('      Caption = +');
  L('      Left = 188');
  L('      Top = 176');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton CmdC');
  L('      Caption = C');
  L('      Left = 8');
  L('      Top = 220');
  L('      Width = 112');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton CmdSigne');
  L('      Caption = +/-');
  L('      Left = 128');
  L('      Top = 220');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin CommandButton CmdRacine');
  L('      Caption = Rac');
  L('      Left = 188');
  L('      Top = 220');
  L('      Width = 52');
  L('      Height = 36');
  L('   End');
  L('   Begin Label Label1');
  L('      Caption = Ruban :');
  L('      Left = 256');
  L('      Top = 8');
  L('      Width = 120');
  L('      Height = 20');
  L('   End');
  L('   Begin ListBox List1');
  L('      Left = 256');
  L('      Top = 30');
  L('      Width = 120');
  L('      Height = 166');
  L('   End');
  L('   Begin CheckBox Check1');
  L('      Caption = Conserver');
  L('      Left = 256');
  L('      Top = 200');
  L('      Width = 120');
  L('      Height = 22');
  L('      Value = 1');
  L('   End');
  L('   Begin CommandButton CmdEffacer');
  L('      Caption = Effacer');
  L('      Left = 256');
  L('      Top = 226');
  L('      Width = 120');
  L('      Height = 30');
  L('   End');
  L('End');
  L('|(* Calculatrice : exemple de Visual Pascal.');
  L('|   Les controles sont utilises comme en Visual Basic : Text1.Text,');
  L('|   List1.AddItem(...), Check1.Value... *)');
  L('|');
  L('|Var');
  L('|  Acc : Real;        { resultat en cours }');
  L('|  Op : Char;         { operation en attente ('' '' : aucune) }');
  L('|  Nouveau : Boolean; { le prochain chiffre commence un nombre }');
  L('|');
  L('|{ ajoute une ligne au ruban si la case est cochee }');
  L('|Procedure Ruban(S : String);');
  L('|Begin');
  L('|  If Check1.Value = 1 Then');
  L('|  Begin');
  L('|    List1.AddItem(S);');
  L('|    List1.ListIndex := List1.ListCount - 1;');
  L('|  End;');
  L('|End;');
  L('|');
  L('|Procedure Chiffre(C : String);');
  L('|Begin');
  L('|  If Nouveau Or (Text1.Text = ''0'') Then Text1.Text := C');
  L('|  Else Text1.Text := Text1.Text + C;');
  L('|  Nouveau := False;');
  L('|End;');
  L('|');
  L('|Procedure Calculer;');
  L('|Var V : Real;');
  L('|Begin');
  L('|  V := StrToFloat(Text1.Text);');
  L('|  Case Op Of');
  L('|    ''+'' : Acc := Acc + V;');
  L('|    ''-'' : Acc := Acc - V;');
  L('|    ''*'' : Acc := Acc * V;');
  L('|    ''/'' :');
  L('|      If V <> 0 Then Acc := Acc / V');
  L('|      Else');
  L('|      Begin');
  L('|        MsgBox(''Division par z''#130''ro !'');');
  L('|        Acc := 0;');
  L('|      End;');
  L('|  Else');
  L('|    Acc := V;');
  L('|  End;');
  L('|  If Op <> '' '' Then Ruban(Op + '' '' + FloatToStr(V));');
  L('|  Text1.Text := FloatToStr(Acc);');
  L('|  Nouveau := True;');
  L('|End;');
  L('|');
  L('|Procedure Operation(O : Char);');
  L('|Begin');
  L('|  If Not Nouveau Then Calculer;');
  L('|  Op := O;');
  L('|  Nouveau := True;');
  L('|End;');
  L('|');
  L('|Procedure Form1_Load;');
  L('|Begin');
  L('|  Acc := 0;');
  L('|  Op := '' '';');
  L('|  Nouveau := True;');
  L('|End;');
  L('|');
  L('|Procedure Cmd0_Click; Begin Chiffre(''0''); End;');
  L('|Procedure Cmd1_Click; Begin Chiffre(''1''); End;');
  L('|Procedure Cmd2_Click; Begin Chiffre(''2''); End;');
  L('|Procedure Cmd3_Click; Begin Chiffre(''3''); End;');
  L('|Procedure Cmd4_Click; Begin Chiffre(''4''); End;');
  L('|Procedure Cmd5_Click; Begin Chiffre(''5''); End;');
  L('|Procedure Cmd6_Click; Begin Chiffre(''6''); End;');
  L('|Procedure Cmd7_Click; Begin Chiffre(''7''); End;');
  L('|Procedure Cmd8_Click; Begin Chiffre(''8''); End;');
  L('|Procedure Cmd9_Click; Begin Chiffre(''9''); End;');
  L('|');
  L('|Procedure CmdPoint_Click;');
  L('|Begin');
  L('|  If Nouveau Then Chiffre(''0.'')');
  L('|  Else If Pos(''.'', Text1.Text) = 0 Then Chiffre(''.'');');
  L('|End;');
  L('|');
  L('|Procedure CmdPlus_Click; Begin Operation(''+''); End;');
  L('|Procedure CmdMoins_Click; Begin Operation(''-''); End;');
  L('|Procedure CmdMul_Click; Begin Operation(''*''); End;');
  L('|Procedure CmdDiv_Click; Begin Operation(''/''); End;');
  L('|');
  L('|Procedure CmdEgal_Click;');
  L('|Begin');
  L('|  If Op <> '' '' Then');
  L('|  Begin');
  L('|    Calculer;');
  L('|    Ruban(''= '' + Text1.Text);');
  L('|  End;');
  L('|  Op := '' '';');
  L('|End;');
  L('|');
  L('|Procedure CmdC_Click;');
  L('|Begin');
  L('|  Text1.Text := ''0'';');
  L('|  Acc := 0;');
  L('|  Op := '' '';');
  L('|  Nouveau := True;');
  L('|End;');
  L('|');
  L('|Procedure CmdSigne_Click;');
  L('|Begin');
  L('|  Text1.Text := FloatToStr(-StrToFloat(Text1.Text));');
  L('|End;');
  L('|');
  L('|Procedure CmdRacine_Click;');
  L('|Begin');
  L('|  If StrToFloat(Text1.Text) < 0 Then MsgBox(''Racine d''''un nombre n''#130''gatif !'')');
  L('|  Else Text1.Text := FloatToStr(Sqrt(StrToFloat(Text1.Text)));');
  L('|  Nouveau := True;');
  L('|End;');
  L('|');
  L('|Procedure CmdEffacer_Click;');
  L('|Begin');
  L('|  List1.Clear;');
  L('|End;');
End;

Procedure SampleDemo;
Begin
  SampB.Len := 0;
  L('VisualPascal 1');
  L('Projet = Demonstration');
  L('Begin Form Form1');
  L('   Caption = D'#130'monstration de Visual Pascal');
  L('   Width = 440');
  L('   Height = 300');
  L('   Begin Label Label1');
  L('      Caption = Votre nom :');
  L('      Left = 12');
  L('      Top = 14');
  L('      Width = 88');
  L('      Height = 20');
  L('   End');
  L('   Begin TextBox Text1');
  L('      Text = ');
  L('      Left = 104');
  L('      Top = 12');
  L('      Width = 200');
  L('      Height = 24');
  L('   End');
  L('   Begin CommandButton CmdBonjour');
  L('      Caption = Bonjour');
  L('      Left = 316');
  L('      Top = 10');
  L('      Width = 112');
  L('      Height = 28');
  L('   End');
  L('   Begin Frame Frame1');
  L('      Caption = Couleur pr'#130'f'#130'r'#130'e');
  L('      Left = 12');
  L('      Top = 48');
  L('      Width = 200');
  L('      Height = 112');
  L('   End');
  L('   Begin OptionButton OptRouge');
  L('      Caption = Rouge');
  L('      Left = 24');
  L('      Top = 70');
  L('      Width = 176');
  L('      Height = 22');
  L('      Value = True');
  L('   End');
  L('   Begin OptionButton OptVert');
  L('      Caption = Vert');
  L('      Left = 24');
  L('      Top = 98');
  L('      Width = 176');
  L('      Height = 22');
  L('   End');
  L('   Begin OptionButton OptBleu');
  L('      Caption = Bleu');
  L('      Left = 24');
  L('      Top = 126');
  L('      Width = 176');
  L('      Height = 22');
  L('   End');
  L('   Begin CheckBox Check1');
  L('      Caption = Afficher l''heure');
  L('      Left = 228');
  L('      Top = 52');
  L('      Width = 200');
  L('      Height = 22');
  L('      Value = 1');
  L('   End');
  L('   Begin Label LblHeure');
  L('      Caption = ');
  L('      Left = 228');
  L('      Top = 78');
  L('      Width = 200');
  L('      Height = 20');
  L('   End');
  L('   Begin ComboBox Combo1');
  L('      Text = Lundi');
  L('      Left = 228');
  L('      Top = 108');
  L('      Width = 200');
  L('      Height = 24');
  L('      List = Lundi;Mardi;Mercredi;Jeudi;Vendredi;Samedi;Dimanche');
  L('   End');
  L('   Begin ListBox List1');
  L('      Left = 12');
  L('      Top = 170');
  L('      Width = 300');
  L('      Height = 118');
  L('   End');
  L('   Begin CommandButton CmdAjouter');
  L('      Caption = Ajouter');
  L('      Left = 320');
  L('      Top = 170');
  L('      Width = 108');
  L('      Height = 28');
  L('   End');
  L('   Begin CommandButton CmdVider');
  L('      Caption = Vider');
  L('      Left = 320');
  L('      Top = 204');
  L('      Width = 108');
  L('      Height = 28');
  L('   End');
  L('   Begin CommandButton CmdQuitter');
  L('      Caption = Quitter');
  L('      Left = 320');
  L('      Top = 260');
  L('      Width = 108');
  L('      Height = 28');
  L('   End');
  L('   Begin Timer Timer1');
  L('      Left = 400');
  L('      Top = 140');
  L('      Interval = 1000');
  L('   End');
  L('End');
  L('|(* Demonstration : les controles de Visual Pascal et leurs evenements. *)');
  L('|');
  L('|{ couleur choisie dans le cadre (un seul bouton d''option par cadre) }');
  L('|Function Couleur : String;');
  L('|Begin');
  L('|  If OptRouge.Value = 1 Then Couleur := ''rouge''');
  L('|  Else If OptVert.Value = 1 Then Couleur := ''vert''');
  L('|  Else Couleur := ''bleu'';');
  L('|End;');
  L('|');
  L('|Procedure Form1_Load;');
  L('|Begin');
  L('|  List1.AddItem(''Bienvenue dans Visual Pascal !'');');
  L('|  List1.AddItem(''Nous sommes le '' + DateDuJour + ''.'');');
  L('|  LblHeure.Caption := ''Il est '' + Heure;');
  L('|End;');
  L('|');
  L('|Procedure CmdBonjour_Click;');
  L('|Begin');
  L('|  If Text1.Text = '''' Then');
  L('|  Begin');
  L('|    MsgBox(''Entrez d''''abord votre nom.'');');
  L('|    Text1.SetFocus;');
  L('|  End');
  L('|  Else MsgBox(''Bonjour '' + Text1.Text + '' ! Votre couleur pr''#130''f''#130''r''#130''e : '' + Couleur + ''.'');');
  L('|End;');
  L('|');
  L('|Procedure Text1_Change;');
  L('|Begin');
  L('|  If Text1.Text = '''' Then Me.Caption := ''D''#130''monstration de Visual Pascal''');
  L('|  Else Me.Caption := ''D''#130''monstration - '' + Text1.Text;');
  L('|End;');
  L('|');
  L('|Procedure CmdAjouter_Click;');
  L('|Begin');
  L('|  List1.AddItem(Combo1.Text + '' : '' + Text1.Text + '' ('' + Couleur + '')'');');
  L('|End;');
  L('|');
  L('|Procedure CmdVider_Click;');
  L('|Begin');
  L('|  List1.Clear;');
  L('|End;');
  L('|');
  L('|Procedure List1_DblClick;');
  L('|Begin');
  L('|  If List1.ListIndex >= 0 Then MsgBox(''Ligne '' + IntToStr(List1.ListIndex + 1) + '' : '' + List1.Text);');
  L('|End;');
  L('|');
  L('|Procedure Check1_Click;');
  L('|Begin');
  L('|  LblHeure.Visible := Check1.Value = 1;');
  L('|  Timer1.Enabled := Check1.Value = 1;');
  L('|End;');
  L('|');
  L('|Procedure Timer1_Timer;');
  L('|Begin');
  L('|  LblHeure.Caption := ''Il est '' + Heure;');
  L('|End;');
  L('|');
  L('|Procedure CmdQuitter_Click;');
  L('|Begin');
  L('|  If MsgBoxOuiNon(''Quitter la d''#130''monstration ?'') Then Quitter;');
  L('|End;');
End;

{ ==================================================================== }
{ Fenetre de l'EDI : etat, disposition et primitives de dessin          }
{ ==================================================================== }

Const
  TbxW = 58; RpW = 256; PeH = 132; PrRowH = 18; DescH = 70; MsgH = 104; CbH = 28;
  TitH = 20; BrdW = 4; GridSz = 8; HdrH = 20;
  MaxTb = 24;
  MaxMsg = 80;
  { commandes }
  cmNew = 100; cmOpen = 101; cmSave = 102; cmSaveAs = 103; cmQuit = 104; cmSampleCalc = 105; cmSampleDemo = 106;
  cmMakeExe = 107;
  cmUndo = 110; cmRedo = 111; cmCut = 112; cmCopy = 113; cmPaste = 114; cmDelete = 115; cmSelAll = 116;
  cmFind = 117; cmFindNext = 118;
  cmCode = 130; cmObject = 131; cmShowProj = 132; cmShowProps = 133; cmShowTbx = 134; cmShowMsgs = 135;
  cmShowGen = 136; cmNums = 137;
  cmAddForm = 140; cmDelForm = 141; cmPrjProps = 142;
  cmSnap = 150; cmCenterH = 151; cmCenterV = 152; cmToFront = 153; cmToBack = 154;
  cmRun = 160; cmStop = 161; cmCompile = 162;
  cmHelp = 170; cmLang = 171; cmAbout = 172;
  cmChoice = 300;      { + valeur d'une propriete a choix }
  cmObjFirst = 400;    { + controle (liste Objet de la fenetre de code) }
  cmEvFirst = 700;     { + evenement (liste Procedure) }
  cmFormFirst = 800;   { + feuille (menu de l'explorateur) }

Var
  Hab, Hmq, Frame, Client, MenuHw, Hps, CW, CH : LongInt;
  GQmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..8191] Of Byte;
  MenuLen : LongInt;
  UX1, UY1, UX2, UY2 : LongInt;
  IcX, IcY : LongInt;
  { decoupage du dessin (concepteur) }
  KX1, KY1, KX2, KY2 : LongInt;
  { disposition (Y vers le bas) }
  Y0, Y1, WX0, WX1, WY0, WY1, RpX, PrY0, PgY0, PgY1, MsY0 : LongInt;
  FX, FY, FCX, FCY : LongInt;     { cadre de la feuille dessinee et origine de sa zone client }
  { editeur de code }
  EdX0, EdTop, TxX0, TxY0, GutW, VsX, HsY, Rows, Cols : LongInt;
  InsMode, CaretOn, HasFocus, ShowNums : Boolean;
  { etat }
  CodeView, ShowMsgs, ShowTbx, ShowProps, ShowProj : Boolean;
  CurForm, Sel, Tool, DsX, DsY : LongInt;
  PropRow, PropTop : LongInt;
  PropList : Array[0..NProps - 1] Of LongInt;
  NPropL : LongInt;
  GenDoc : LongInt;
  { barre d'outils }
  NTb, TbDown, TbHot : LongInt;
  TbCmd, TbX, TbW, TbIco : Array[0..MaxTb - 1] Of LongInt;
  TbTip : Array[0..MaxTb - 1] Of String;
  StatusMsg : String;
  { fenetre Messages }
  MsgN, MsgTop, MsgSel : LongInt;
  MsgTx : Array[0..MaxMsg - 1] Of String;
  MsgF, MsgL : Array[0..MaxMsg - 1] Of LongInt;
  { execution }
  RunPid, CompPid : LongInt;
  CompBusy, RunAfter : Boolean;

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

{ --- dessin decoupe (concepteur de feuilles) --- }

Procedure KBar(X1, Y1_, X2, Y2, C : LongInt);
Begin
  If X1 < KX1 Then X1 := KX1;
  If Y1_ < KY1 Then Y1_ := KY1;
  If X2 > KX2 Then X2 := KX2;
  If Y2 > KY2 Then Y2 := KY2;
  FBar(X1, Y1_, X2, Y2, C);
End;

Procedure KBox(X1, Y1_, X2, Y2, C : LongInt);
Begin
  KBar(X1, Y1_, X2, Y1_, C); KBar(X1, Y2, X2, Y2, C);
  KBar(X1, Y1_, X1, Y2, C); KBar(X2, Y1_, X2, Y2, C);
End;

Procedure KEdge(X1, Y1_, X2, Y2, Lt, Dk : LongInt);
Begin
  KBar(X1, Y1_, X2, Y1_, Lt); KBar(X1, Y1_, X1, Y2, Lt);
  KBar(X1, Y2, X2, Y2, Dk); KBar(X2, Y1_, X2, Y2, Dk);
End;

{ texte coupe au rectangle de decoupage et a la largeur W }
Procedure KOut(X, Y, W : LongInt; S : String; Fg, Bg : LongInt);
Var N, K : LongInt;
Begin
  If (Y < KY1) Or (Y + 15 > KY2) Then Exit;
  N := W Div 8;
  If N < Length(S) Then S := Copy(S, 1, MaxI(0, N));
  If X < KX1 Then
  Begin
    K := (KX1 - X + 7) Div 8;
    Delete(S, 1, K);
    X := X + K * 8;
  End;
  If X + Length(S) * 8 > KX2 + 1 Then S := Copy(S, 1, MaxI(0, (KX2 + 1 - X) Div 8));
  OutTxt(X, Y, S, Fg, Bg);
End;

{ ==================================================================== }
{ Icones                                                                }
{ ==================================================================== }

Procedure IcoTb(K : LongInt);
Begin
  Case K Of
    1 :
      Begin
        { nouveau projet : page }
        IR(2, 1, 11, 14, cWhite); IB(2, 1, 11, 14, cBlack); IR(9, 1, 11, 3, cSilver);
        IR(9, 8, 14, 13, cYellow); IR(11, 6, 12, 15, cYellow);
      End;
    2 :
      Begin
        IR(1, 3, 6, 4, cBrown); IR(1, 4, 14, 13, cYellow); IB(1, 4, 14, 13, cBrown);
        IR(3, 7, 15, 13, cYellow); IB(3, 7, 15, 13, cBrown);
      End;
    3 : Begin IR(1, 1, 14, 14, cNavy); IR(4, 1, 11, 5, cSilver); IR(3, 8, 12, 14, cWhite); IB(1, 1, 14, 14, cBlack); End;
    4, 5 :
      If K = 4 Then
      Begin
        IR(4, 5, 11, 6, cNavy); IR(11, 6, 12, 11, cNavy); IR(6, 11, 12, 12, cNavy);
        IR(1, 5, 4, 6, cNavy); IR(2, 3, 3, 8, cNavy); IR(3, 2, 3, 9, cNavy);
      End
      Else
      Begin
        IR(4, 5, 11, 6, cNavy); IR(3, 6, 4, 11, cNavy); IR(3, 11, 9, 12, cNavy);
        IR(11, 5, 14, 6, cNavy); IR(12, 3, 13, 8, cNavy); IR(12, 2, 12, 9, cNavy);
      End;
    6 :
      Begin
        IR(4, 1, 5, 8, cGray); IR(10, 1, 11, 8, cGray); IR(6, 8, 9, 9, cGray);
        IR(2, 10, 6, 14, cBlack); IR(3, 11, 5, 13, cSilver); IR(9, 10, 13, 14, cBlack); IR(10, 11, 12, 13, cSilver);
      End;
    7 :
      Begin
        IR(1, 1, 8, 10, cWhite); IB(1, 1, 8, 10, cBlack);
        IR(6, 5, 14, 14, cWhite); IB(6, 5, 14, 14, cBlack); IR(8, 8, 12, 8, cGray); IR(8, 10, 12, 10, cGray);
      End;
    8 : Begin IR(2, 2, 12, 14, cBrown); IR(5, 1, 9, 3, cGray); IR(6, 6, 14, 15, cWhite); IB(6, 6, 14, 15, cBlack); End;
    10 :
      Begin
        { executer : triangle vert }
        IR(3, 2, 4, 13, cDGreen); IR(5, 3, 6, 12, cDGreen); IR(7, 4, 8, 11, cDGreen); IR(9, 5, 10, 10, cDGreen);
        IR(11, 6, 12, 9, cDGreen); IR(13, 7, 13, 8, cDGreen);
      End;
    12 : IR(3, 3, 12, 12, cNavy);
    13 :
      Begin
        { code }
        IR(2, 1, 13, 14, cWhite); IB(2, 1, 13, 14, cBlack);
        IR(4, 4, 11, 4, cNavy); IR(4, 6, 9, 6, cDGreen); IR(6, 8, 12, 8, cNavy); IR(6, 10, 10, 10, cMaroon);
        IR(4, 12, 8, 12, cNavy);
      End;
    14 :
      Begin
        Disc(IcX + 8, IcY + 8, 7, cBlue);
        IR(6, 4, 9, 4, cWhite); IR(9, 5, 10, 6, cWhite); IR(7, 7, 9, 7, cWhite); IR(7, 8, 8, 9, cWhite);
        IR(7, 11, 8, 12, cWhite);
      End;
    16, 17 :
      Begin
        { feuille (ajouter une feuille / afficher l'objet) }
        IR(1, 2, 14, 14, cSilver); IB(1, 2, 14, 14, cBlack); IR(2, 3, 13, 5, cNavy);
        If K = 16 Then
        Begin
          IR(10, 9, 15, 10, cDGreen); IR(12, 7, 13, 12, cDGreen);
        End
        Else
        Begin
          IR(4, 8, 9, 11, cWhite); IB(4, 8, 9, 11, cGray);
        End;
      End;
    18 :
      Begin
        { creer l'EXE : engrenage }
        Disc(IcX + 8, IcY + 8, 6, cGray); Disc(IcX + 8, IcY + 8, 2, cSilver);
        IR(7, 0, 9, 2, cGray); IR(7, 14, 9, 15, cGray); IR(0, 7, 2, 9, cGray); IR(14, 7, 15, 9, cGray);
      End;
  End;
End;

{ icone de la boite a outils (0 : pointeur), 20 x 20 }
Procedure IcoTool(K : LongInt);
Var I : LongInt;
Begin
  Case K Of
    0 :
      Begin
        For I := 0 To 9 Do IR(6, 3 + I, 6 + I Div 2 + 1, 3 + I, cBlack);
        IR(8, 12, 9, 16, cBlack); IR(10, 13, 11, 17, cBlack);
      End;
    vkLabel :
      Begin
        { A }
        IR(9, 3, 11, 4, cBlack); IR(8, 5, 9, 9, cBlack); IR(11, 5, 12, 9, cBlack); IR(7, 10, 8, 16, cBlack);
        IR(12, 10, 13, 16, cBlack); IR(8, 11, 12, 12, cBlack);
      End;
    vkText :
      Begin
        IR(2, 5, 17, 15, cWhite); IB(2, 5, 17, 15, cGray);
        OutTxt(IcX + 3, IcY + 2, 'ab', cBlack, cWhite);
        IR(14, 7, 14, 13, cBlack);
      End;
    vkButton :
      Begin
        IR(2, 6, 17, 14, cSilver); IB(2, 6, 17, 14, cBlack); IR(3, 7, 16, 7, cWhite); IR(3, 7, 3, 13, cWhite);
        IR(3, 13, 16, 13, cGray); IR(16, 7, 16, 13, cGray);
      End;
    vkFrame :
      Begin
        IB(2, 6, 17, 17, cGray); IR(4, 3, 12, 8, cSilver);
        OutTxt(IcX + 3, IcY - 1, 'xy', cBlack, cSilver);
      End;
    vkCheck :
      Begin
        IR(4, 4, 15, 15, cWhite); IB(4, 4, 15, 15, cGray);
        Thick(IcX + 6, IcY + 9, IcX + 8, IcY + 11, cBlack); Thick(IcX + 8, IcY + 11, IcX + 12, IcY + 6, cBlack);
      End;
    vkOption :
      Begin
        Disc(IcX + 10, IcY + 10, 7, cGray); Disc(IcX + 10, IcY + 10, 6, cWhite); Disc(IcX + 10, IcY + 10, 2, cBlack);
      End;
    vkList :
      Begin
        IR(2, 2, 17, 17, cWhite); IB(2, 2, 17, 17, cGray); IR(13, 3, 16, 16, cSilver);
        For I := 0 To 3 Do IR(4, 5 + I * 3, 11, 5 + I * 3, cNavy);
      End;
    vkCombo :
      Begin
        IR(1, 5, 18, 14, cWhite); IB(1, 5, 18, 14, cGray); IR(12, 6, 17, 13, cSilver);
        IR(13, 8, 16, 8, cBlack); IR(14, 9, 15, 9, cBlack); IR(3, 9, 9, 9, cNavy);
      End;
    vkTimer :
      Begin
        Disc(IcX + 10, IcY + 10, 8, cBlack); Disc(IcX + 10, IcY + 10, 7, cWhite);
        IR(10, 5, 10, 10, cBlack); IR(10, 10, 13, 10, cBlack); IR(8, 1, 12, 2, cBlack);
      End;
  End;
End;

{ ==================================================================== }
{ Disposition                                                           }
{ ==================================================================== }

Procedure Layout;
Var D, N : LongInt;
Begin
  Y0 := TbH;
  Y1 := CH - SbH - 1;
  If ShowTbx Then WX0 := TbxW Else WX0 := 0;
  If ShowProps Or ShowProj Then RpX := CW - RpW Else RpX := CW;
  If RpX < WX0 + 200 Then RpX := MaxI(WX0 + 100, CW - 160);
  WX1 := RpX - 1;
  WY0 := Y0;
  If ShowMsgs Then MsY0 := MaxI(Y0 + 120, Y1 - MsgH + 1) Else MsY0 := Y1 + 1;
  WY1 := MsY0 - 1;
  If ShowProj Then PrY0 := Y0 + PeH Else PrY0 := Y0;
  PgY0 := PrY0 + HdrH + 24;
  PgY1 := Y1 - DescH;
  { feuille en conception }
  FX := WX0 + 12 - DsX; FY := WY0 + 12 - DsY;
  FCX := FX + BrdW; FCY := FY + BrdW + TitH;
  { editeur de code }
  EdX0 := WX0;
  EdTop := WY0 + CbH;
  VsX := WX1 - ScrW + 1;
  HsY := WY1 - ScrW + 1;
  D := 3; N := 1000;
  If Cur >= 0 Then
    While (DN[Cur] >= N) And (D < 9) Do
    Begin
      Inc(D);
      N := N * 10;
    End;
  If ShowNums Then GutW := D * 8 + 10 Else GutW := 4;
  TxX0 := EdX0 + 1 + GutW + 2;
  TxY0 := EdTop + 2;
  Rows := MaxI(1, (HsY - TxY0 - 1) Div RowH);
  Cols := MaxI(1, (VsX - TxX0 - 1) Div 8);
End;

Function MaxTop : LongInt;
Begin
  If Cur < 0 Then MaxTop := 0 Else MaxTop := MaxI(0, DN[Cur] - Rows + 1);
End;

Procedure ScrollToCaret;
Var V : LongInt;
Begin
  If Cur < 0 Then Exit;
  If DCY[Cur] < DTop[Cur] Then DTop[Cur] := DCY[Cur];
  If DCY[Cur] >= DTop[Cur] + Rows Then DTop[Cur] := DCY[Cur] - Rows + 1;
  If DTop[Cur] > MaxTop Then DTop[Cur] := MaxTop;
  If DTop[Cur] < 0 Then DTop[Cur] := 0;
  V := VisCol(Cur, DCY[Cur], DCX[Cur]);
  If V < DLeft[Cur] Then DLeft[Cur] := MaxI(0, V - 8);
  If V >= DLeft[Cur] + Cols Then DLeft[Cur] := V - Cols + 8;
End;

Procedure InvalWork;
Begin
  InvalBand(WX0, WY0, WX1 + 1, WY1 + 1);
End;

Procedure InvalEditor;
Begin
  InvalBand(EdX0, EdTop, WX1 + 1, WY1 + 1);
End;

Procedure InvalProps;
Begin
  InvalBand(RpX, PrY0, CW, Y1 + 1);
End;

Procedure InvalProj;
Begin
  InvalBand(RpX, Y0, CW, PrY0);
End;

Procedure InvalStatus;
Begin
  InvalBand(0, CH - SbH, CW, CH);
End;

Procedure InvalMsgs;
Begin
  InvalBand(WX0, MsY0, WX1 + 1, Y1 + 1);
End;

{ ==================================================================== }
{ Barre d'outils, boite a outils                                        }
{ ==================================================================== }

Function TbDisabled(C : LongInt) : Boolean;
Begin
  TbDisabled := False;
  Case C Of
    cmStop : TbDisabled := (RunPid = 0) And Not CompBusy;
    cmRun, cmMakeExe : TbDisabled := CompBusy Or (RunPid <> 0);
    cmCode : TbDisabled := CodeView And (Cur <> GenDoc);
    cmObject : TbDisabled := Not CodeView;
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
    If (TbDown = I) And Not Dis Then
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
  End;
End;

Procedure PaintToolbox;
Var K, X, Y : LongInt;
Begin
  Raised(0, Y0, TbxW - 1, Y0 + HdrH - 1);
  OutTxt(4, Y0 + 2, 'G'#130'n'#130'ral', cBlack, cSilver);
  FBar(0, Y0 + HdrH, TbxW - 1, Y1, cSilver);
  VLine(TbxW - 1, Y0 + HdrH, Y1, cGray);
  For K := 0 To NKinds - 1 Do
  Begin
    X := 4 + (K Mod 2) * 26; Y := Y0 + HdrH + 4 + (K Div 2) * 26;
    If Tool = K Then
    Begin
      FBar(X, Y, X + 24, Y + 24, cWhite);
      Edge(X, Y, X + 24, Y + 24, cGray, cWhite);
    End
    Else Edge(X, Y, X + 24, Y + 24, cWhite, cGray);
    IcX := X + 3; IcY := Y + 3;
    If K = 0 Then IcoTool(0) Else IcoTool(K + 1);
  End;
End;

{ ==================================================================== }
{ Concepteur de feuilles                                                }
{ ==================================================================== }

{ position d'un controle a l'ecran }
Function SXc(C : LongInt) : LongInt;
Begin
  SXc := FCX + CtX[C];
End;

Function SYc(C : LongInt) : LongInt;
Begin
  SYc := FCY + CtY[C];
End;

Procedure DrawCheckMark(X, Y : LongInt);
Begin
  KBar(X + 3, Y + 6, X + 4, Y + 8, cBlack); KBar(X + 5, Y + 8, X + 6, Y + 9, cBlack);
  KBar(X + 7, Y + 6, X + 7, Y + 8, cBlack); KBar(X + 8, Y + 4, X + 8, Y + 6, cBlack); KBar(X + 9, Y + 3, X + 9, Y + 4, cBlack);
End;

Procedure DrawCtl(C : LongInt);
Var X, Y, W, H, Fg, K, St, Ty, Tw : LongInt; S, It : String;
Begin
  X := SXc(C); Y := SYc(C); W := CtW[C]; H := CtH[C];
  If CtEn[C] Then Fg := cBlack Else Fg := cGray;
  Ty := Y + (H - 16) Div 2;
  { libelles, cases et options : fond de la feuille (opaque, comme a l'execution) }
  If CtKind[C] In [vkLabel, vkCheck, vkOption] Then KBar(X, Y, X + W - 1, Y + H - 1, cSilver);
  Case CtKind[C] Of
    vkLabel :
      Begin
        S := CtText[C];
        Tw := Length(S) * 8;
        If Tw > W Then Tw := W;
        If CtAlign[C] = 1 Then KOut(X + W - Tw, Y + 2, W, S, Fg, cSilver)
        Else If CtAlign[C] = 2 Then KOut(X + (W - Tw) Div 2, Y + 2, W, S, Fg, cSilver)
        Else KOut(X, Y + 2, W, S, Fg, cSilver);
      End;
    vkText :
      Begin
        KBar(X, Y, X + W - 1, Y + H - 1, cWhite);
        KEdge(X, Y, X + W - 1, Y + H - 1, cGray, cWhite);
        KEdge(X + 1, Y + 1, X + W - 2, Y + H - 2, cBlack, cSilver);
        KOut(X + 4, Ty, W - 8, CtText[C], Fg, cWhite);
      End;
    vkButton :
      Begin
        KBar(X, Y, X + W - 1, Y + H - 1, cSilver);
        KBox(X, Y, X + W - 1, Y + H - 1, cBlack);
        KEdge(X + 1, Y + 1, X + W - 2, Y + H - 2, cWhite, cGray);
        KEdge(X + 2, Y + 2, X + W - 3, Y + H - 3, cWhite, cGray);
        S := CtText[C];
        Tw := MinI(Length(S) * 8, W - 6);
        KOut(X + (W - Tw) Div 2, Ty, W - 6, S, Fg, cSilver);
      End;
    vkFrame :
      Begin
        KEdge(X, Y + 7, X + W - 1, Y + H - 1, cGray, cWhite);
        KEdge(X + 1, Y + 8, X + W - 2, Y + H - 2, cWhite, cGray);
        S := CtText[C];
        If S <> '' Then KOut(X + 8, Y, W - 16, ' ' + S + ' ', Fg, cSilver);
      End;
    vkCheck :
      Begin
        K := Y + (H - 13) Div 2;
        KBar(X, K, X + 12, K + 12, cWhite);
        KEdge(X, K, X + 12, K + 12, cGray, cWhite);
        If CtValue[C] = 1 Then DrawCheckMark(X, K);
        KOut(X + 18, Ty, W - 18, CtText[C], Fg, cSilver);
      End;
    vkOption :
      Begin
        K := Y + H Div 2;
        If (X + 6 >= KX1) And (X + 6 <= KX2) And (K - 6 >= KY1) And (K + 6 <= KY2) Then
        Begin
          Disc(X + 6, K, 6, cGray); Disc(X + 6, K, 5, cWhite);
          If CtValue[C] = 1 Then Disc(X + 6, K, 2, cBlack);
        End;
        KOut(X + 18, Ty, W - 18, CtText[C], Fg, cSilver);
      End;
    vkList :
      Begin
        KBar(X, Y, X + W - 1, Y + H - 1, cWhite);
        KEdge(X, Y, X + W - 1, Y + H - 1, cGray, cWhite);
        S := CtItems[C]; St := 1; K := 0;
        If S = '' Then KOut(X + 4, Y + 3, W - 8, CtName[C], cGray, cWhite);
        While (S <> '') And (St <= Length(S)) And (Y + 3 + K * 16 + 16 < Y + H) Do
        Begin
          Tw := St;
          While (Tw <= Length(S)) And (S[Tw] <> ';') Do Inc(Tw);
          It := Copy(S, St, Tw - St);
          KOut(X + 4, Y + 3 + K * 16, W - 8, It, Fg, cWhite);
          Inc(K);
          St := Tw + 1;
        End;
      End;
    vkCombo :
      Begin
        KBar(X, Y, X + W - 1, Y + H - 1, cWhite);
        KEdge(X, Y, X + W - 1, Y + H - 1, cGray, cWhite);
        KBar(X + W - 18, Y + 2, X + W - 3, Y + H - 3, cSilver);
        KEdge(X + W - 18, Y + 2, X + W - 3, Y + H - 3, cWhite, cGray);
        K := Y + H Div 2 - 2;
        KBar(X + W - 14, K, X + W - 7, K, cBlack); KBar(X + W - 13, K + 1, X + W - 8, K + 1, cBlack);
        KBar(X + W - 12, K + 2, X + W - 9, K + 2, cBlack); KBar(X + W - 11, K + 3, X + W - 10, K + 3, cBlack);
        KOut(X + 4, Ty, W - 24, CtText[C], Fg, cWhite);
      End;
    vkTimer :
      Begin
        KBar(X, Y, X + 27, Y + 27, cSilver);
        KEdge(X, Y, X + 27, Y + 27, cWhite, cGray);
        If (X + 4 >= KX1) And (X + 24 <= KX2) And (Y + 4 >= KY1) And (Y + 24 <= KY2) Then
        Begin
          IcX := X + 4; IcY := Y + 4;
          IcoTool(vkTimer);
        End;
      End;
  End;
End;

{ poignees de la selection }
Procedure Handle(X, Y : LongInt; Act : Boolean);
Begin
  If Act Then KBar(X - 3, Y - 3, X + 3, Y + 3, cNavy)
  Else
  Begin
    KBar(X - 3, Y - 3, X + 3, Y + 3, cWhite);
    KBox(X - 3, Y - 3, X + 3, Y + 3, cGray);
  End;
End;

Procedure DrawHandles(C : LongInt);
Var X1, Y1_, X2, Y2, W, H : LongInt;
Begin
  If C = CurForm Then
  Begin
    X1 := FCX; Y1_ := FCY; X2 := FCX + CtW[C]; Y2 := FCY + CtH[C];
    Handle(X2 + 2, (Y1_ + Y2) Div 2, True); Handle((X1 + X2) Div 2, Y2 + 2, True); Handle(X2 + 2, Y2 + 2, True);
    Exit;
  End;
  X1 := SXc(C); Y1_ := SYc(C); W := CtW[C]; H := CtH[C];
  If CtKind[C] = vkTimer Then
  Begin
    W := 28; H := 28;
  End;
  X2 := X1 + W - 1; Y2 := Y1_ + H - 1;
  Handle(X1 - 1, Y1_ - 1, True); Handle((X1 + X2) Div 2, Y1_ - 1, True); Handle(X2 + 1, Y1_ - 1, True);
  Handle(X1 - 1, (Y1_ + Y2) Div 2, True); Handle(X2 + 1, (Y1_ + Y2) Div 2, True);
  Handle(X1 - 1, Y2 + 1, True); Handle((X1 + X2) Div 2, Y2 + 1, True); Handle(X2 + 1, Y2 + 1, True);
End;

Var
  RubX1, RubY1, RubX2, RubY2 : LongInt;   { rectangle en cours de trace (ecran) }
  RubOn : Boolean;

Procedure PaintDesigner;
Var F, C, X, Y, Xe, Ye, Fw, Fh : LongInt; S : String;
Begin
  FBar(WX0, WY0, WX1, WY1, cGray);
  F := CurForm;
  If F <= 0 Then
  Begin
    OutTxt(WX0 + 20, WY0 + 20, 'Aucune feuille : Projet - Ajouter une feuille.', cWhite, cGray);
    Exit;
  End;
  KX1 := WX0; KY1 := WY0; KX2 := WX1; KY2 := WY1;
  Fw := CtW[F]; Fh := CtH[F];
  { cadre de la fenetre (style OS/2) }
  KBar(FX, FY, FX + Fw + 2 * BrdW - 1, FY + Fh + 2 * BrdW + TitH - 1, cSilver);
  KBox(FX, FY, FX + Fw + 2 * BrdW - 1, FY + Fh + 2 * BrdW + TitH - 1, cBlack);
  KEdge(FX + 1, FY + 1, FX + Fw + 2 * BrdW - 2, FY + Fh + 2 * BrdW + TitH - 2, cWhite, cGray);
  KBar(FX + BrdW, FY + BrdW, FX + BrdW + Fw - 1, FY + BrdW + TitH - 2, cNavy);
  { menu systeme et boutons }
  KBar(FX + BrdW + 2, FY + BrdW + 2, FX + BrdW + 15, FY + BrdW + TitH - 4, cSilver);
  KBar(FX + BrdW + 4, FY + BrdW + 8, FX + BrdW + 13, FY + BrdW + 10, cBlack);
  X := FX + BrdW + Fw - 18;
  If X > FX + 60 Then
  Begin
    KBar(X, FY + BrdW + 2, X + 15, FY + BrdW + TitH - 4, cSilver);
    KEdge(X, FY + BrdW + 2, X + 15, FY + BrdW + TitH - 4, cWhite, cGray);
    KBox(X + 4, FY + BrdW + 5, X + 11, FY + BrdW + 12, cBlack);
    KBar(X - 17, FY + BrdW + 2, X - 2, FY + BrdW + TitH - 4, cSilver);
    KEdge(X - 17, FY + BrdW + 2, X - 2, FY + BrdW + TitH - 4, cWhite, cGray);
    KBar(X - 12, FY + BrdW + 8, X - 7, FY + BrdW + 9, cBlack);
  End;
  S := CtText[F];
  KOut(FX + BrdW + 20, FY + BrdW + 1, MaxI(0, Fw - 60), S, cWhite, cNavy);
  { zone client et grille }
  KBar(FCX, FCY, FCX + Fw - 1, FCY + Fh - 1, cSilver);
  KX1 := MaxI(WX0, FCX); KY1 := MaxI(WY0, FCY); KX2 := MinI(WX1, FCX + Fw - 1); KY2 := MinI(WY1, FCY + Fh - 1);
  If (KX2 >= KX1) And (KY2 >= KY1) Then
  Begin
    Y := GridSz;
    Ye := MinI(Fh - 1, KY2 - FCY + 1);
    Xe := MinI(Fw - 1, KX2 - FCX + 1);
    If UY1 - FCY > Y Then Y := ((UY1 - FCY) Div GridSz) * GridSz;
    If UY2 - FCY < Ye Then Ye := UY2 - FCY;
    While Y <= Ye Do
    Begin
      If FCY + Y >= KY1 Then
      Begin
        X := GridSz;
        If UX1 - FCX > X Then X := ((UX1 - FCX) Div GridSz) * GridSz;
        While X <= MinI(Xe, UX2 - FCX) Do
        Begin
          If FCX + X >= KX1 Then FBar(FCX + X, FCY + Y, FCX + X, FCY + Y, cBlack);
          X := X + GridSz;
        End;
      End;
      Y := Y + GridSz;
    End;
    { cadres d'abord (dessous), puis les autres controles }
    For C := 1 To NCtl Do
      If (CtForm[C] = F) And (CtKind[C] = vkFrame) Then DrawCtl(C);
    For C := 1 To NCtl Do
      If (CtForm[C] = F) And (C <> F) And (CtKind[C] <> vkFrame) Then DrawCtl(C);
    If RubOn Then
    Begin
      KBox(MinI(RubX1, RubX2), MinI(RubY1, RubY2), MaxI(RubX1, RubX2), MaxI(RubY1, RubY2), cBlack);
    End;
  End;
  KX1 := WX0; KY1 := WY0; KX2 := WX1; KY2 := WY1;
  If (Sel > 0) And (Sel <= NCtl) And ((CtForm[Sel] = F)) Then DrawHandles(Sel);
End;

{ ==================================================================== }
{ Editeur de code                                                       }
{ ==================================================================== }

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

Procedure PaintHScroll(Xa, Xb, Y, Pos_, Max_, Page : LongInt);
Var T, Th, Tx, I : LongInt;
Begin
  Raised(Xa, Y, Xa + ScrW - 1, Y + ScrW - 1);
  For I := 0 To 3 Do VLine(Xa + 5 + I, Y + 7 - I, Y + 8 + I, cBlack);
  Raised(Xb - ScrW + 1, Y, Xb, Y + ScrW - 1);
  For I := 0 To 3 Do VLine(Xb - 5 - I, Y + 7 - I, Y + 8 + I, cBlack);
  T := Xb - Xa + 1 - 2 * ScrW;
  FBar(Xa + ScrW, Y, Xb - ScrW, Y + ScrW - 1, cWhite);
  HLine(Xa + ScrW, Xb - ScrW, Y, cSilver);
  If (T <= 8) Or (Max_ <= 0) Then Exit;
  Th := MaxI(10, T * Page Div (Max_ + Page));
  If Th > T Then Th := T;
  Tx := Xa + ScrW + (T - Th) * Pos_ Div Max_;
  Raised(Tx, Y, Tx + Th - 1, Y + ScrW - 1);
End;

Function HMax : LongInt;
Begin
  If Cur < 0 Then HMax := 0 Else HMax := MaxI(256, DLeft[Cur] + Cols) - Cols;
End;

Procedure PaintLine(R : LongInt);
Var D, Y, Yy, K, N, V, A, Nv, Fg, Bg, X, Y1s, X1s, Y2s, X2s, Ca, Sx : LongInt; Q : PBytes; S : String;
    InSel, Sl, Has : Boolean; Cs : String;
Begin
  D := Cur;
  Y := DTop[D] + R;
  Yy := TxY0 + R * RowH;
  If (Yy + RowH - 1 < UY1) Or (Yy > UY2) Then Exit;
  If ShowNums Then
  Begin
    FBar(EdX0 + 1, Yy, EdX0 + GutW, Yy + RowH - 1, cSilver);
    If Y < DN[D] Then
    Begin
      Cs := IStr(Y + 1);
      OutTxt(EdX0 + GutW - 4 - Length(Cs) * 8, Yy, Cs, cGray, cSilver);
    End;
  End
  Else FBar(EdX0 + 1, Yy, EdX0 + GutW, Yy + RowH - 1, cWhite);
  FBar(EdX0 + GutW + 1, Yy, VsX - 1, Yy + RowH - 1, cWhite);
  If Y >= DN[D] Then Exit;
  LineAttr(D, Y);
  Has := HasSel(D);
  Y1s := 0; X1s := 0; Y2s := 0; X2s := 0;
  If Has Then SelRange(D, Y1s, X1s, Y2s, X2s);
  N := LLen(D, Y);
  Q := LP(D, Y);
  V := 0; K := 0;
  S := ''; Ca := -1; Sl := False;
  X := TxX0;
  While (K < N) And (V < DLeft[D] + Cols) Do
  Begin
    If Q^[K] = 9 Then Nv := (V Div TabStop + 1) * TabStop Else Nv := V + 1;
    InSel := Has And ((Y > Y1s) Or ((Y = Y1s) And (K >= X1s))) And ((Y < Y2s) Or ((Y = Y2s) And (K < X2s)));
    A := LAttr^[K];
    While V < Nv Do
    Begin
      If V >= DLeft[D] Then
      Begin
        If (Length(S) > 0) And ((A <> Ca) Or (InSel <> Sl) Or (Length(S) >= 200)) Then
        Begin
          If Sl Then
          Begin
            Fg := cWhite; Bg := cNavy;
          End
          Else
          Begin
            Fg := ColTab[Ca And 15]; Bg := cWhite;
          End;
          OutTxt(X, Yy, S, Fg, Bg);
          X := X + Length(S) * 8;
          S := '';
        End;
        Ca := A; Sl := InSel;
        If Q^[K] = 9 Then S := S + ' ' Else If Q^[K] < 32 Then S := S + '?' Else S := S + Chr(Q^[K]);
      End;
      Inc(V);
    End;
    Inc(K);
  End;
  If Length(S) > 0 Then
  Begin
    If Sl Then
    Begin
      Fg := cWhite; Bg := cNavy;
    End
    Else
    Begin
      Fg := ColTab[Ca And 15]; Bg := cWhite;
    End;
    OutTxt(X, Yy, S, Fg, Bg);
  End;
  If Has And (Y >= Y1s) And (Y < Y2s) And (K >= N) Then
  Begin
    Sx := TxX0 + (VisCol(D, Y, N) - DLeft[D]) * 8;
    If Sx >= TxX0 Then FBar(Sx, Yy, Sx + 7, Yy + RowH - 1, cNavy);
  End;
  If (Y = DCY[D]) And CaretOn And HasFocus Then
  Begin
    Sx := TxX0 + (VisCol(D, Y, DCX[D]) - DLeft[D]) * 8;
    If (Sx >= TxX0) And (Sx < VsX - 1) Then
    Begin
      If InsMode Then FBar(Sx, Yy, Sx + 1, Yy + RowH - 1, cBlack)
      Else FBar(Sx, Yy + RowH - 3, Sx + 7, Yy + RowH - 1, cBlack);
    End;
  End;
End;

{ objet et procedure de la ligne du curseur (listes en haut de la fenetre de code) }
Function CaretProc : String;
Var D, Y, K : LongInt; S, U, R : String;
Begin
  R := '(D'#130'clarations)';
  D := Cur;
  If (D < 0) Or (D = GenDoc) Then
  Begin
    CaretProc := R;
    Exit;
  End;
  For Y := DCY[D] DownTo 0 Do
  Begin
    S := LStr(D, Y);
    U := UpStr(Trim(S));
    If (Pos('PROCEDURE ', U) = 1) Or (Pos('FUNCTION ', U) = 1) Then
    Begin
      S := Trim(S);
      K := Pos(' ', S);
      S := Trim(Copy(S, K + 1, 255));
      K := 1;
      While (K <= Length(S)) And (IsAlC(S[K]) Or ((S[K] >= '0') And (S[K] <= '9'))) Do Inc(K);
      R := Copy(S, 1, K - 1);
      Break;
    End;
  End;
  CaretProc := R;
End;

Procedure ComboBox(X1, X2 : LongInt; S : String);
Var K : LongInt;
Begin
  Sunken(X1, WY0 + 4, X2, WY0 + CbH - 5, cWhite);
  Raised(X2 - 17, WY0 + 5, X2 - 1, WY0 + CbH - 6);
  K := WY0 + CbH Div 2 - 2;
  HLine(X2 - 13, X2 - 6, K, cBlack); HLine(X2 - 12, X2 - 7, K + 1, cBlack);
  HLine(X2 - 11, X2 - 8, K + 2, cBlack); HLine(X2 - 10, X2 - 9, K + 3, cBlack);
  OutTxt(X1 + 4, WY0 + 6, Fit(S, X2 - X1 - 26), cBlack, cWhite);
End;

Procedure CodeCombos(Var Xa, Xb, Xc : LongInt);
Begin
  Xa := WX0 + 6;
  Xb := WX0 + (WX1 - WX0) Div 2 - 3;
  Xc := Xb + 6;
End;

Procedure PaintEditor;
Var R, Xa, Xb, Xc, K : LongInt; P, O : String;
Begin
  FBar(WX0, WY0, WX1, EdTop - 1, cSilver);
  If Cur = GenDoc Then
  Begin
    OutTxt(WX0 + 8, WY0 + 6, Fit('Programme g'#130'n'#130'r'#130' (lecture seule) : ' + CodeName + '.PAS', WX1 - WX0 - 16),
           cNavy, cSilver);
  End
  Else
  Begin
    CodeCombos(Xa, Xb, Xc);
    P := CaretProc;
    O := '(G'#130'n'#130'ral)';
    K := Pos('_', P);
    If K > 0 Then
      If FindCtl(Copy(P, 1, K - 1)) > 0 Then
      Begin
        O := Copy(P, 1, K - 1);
        P := Copy(P, K + 1, 255);
      End;
    ComboBox(Xa, Xb, O);
    ComboBox(Xc, WX1 - 6, P);
  End;
  Box(EdX0, EdTop, VsX - 1, HsY - 1, cGray);
  If Cur < 0 Then Exit;
  FBar(EdX0 + 1, EdTop + 1, VsX - 1, TxY0 - 1, cWhite);
  If ShowNums Then FBar(EdX0 + 1, EdTop + 1, EdX0 + GutW, TxY0 - 1, cSilver);
  For R := 0 To Rows - 1 Do PaintLine(R);
  R := TxY0 + Rows * RowH;
  If ShowNums Then FBar(EdX0 + 1, R, EdX0 + GutW, HsY - 1, cSilver) Else FBar(EdX0 + 1, R, EdX0 + GutW, HsY - 1, cWhite);
  FBar(EdX0 + GutW + 1, R, VsX - 1, HsY - 1, cWhite);
  PaintVScroll(VsX, EdTop, HsY - 1, DTop[Cur], MaxTop, Rows);
  PaintHScroll(EdX0, VsX - 1, HsY, DLeft[Cur], HMax, Cols);
  FBar(VsX, HsY, WX1, WY1, cSilver);
End;

Procedure InvalCaret;
Var R : LongInt;
Begin
  If Cur < 0 Then Exit;
  R := DCY[Cur] - DTop[Cur];
  If (R < 0) Or (R >= Rows) Then Exit;
  InvalBand(EdX0, TxY0 + R * RowH, VsX, TxY0 + (R + 1) * RowH);
End;

{ ==================================================================== }
{ Explorateur de projet, proprietes, messages, barre d'etat             }
{ ==================================================================== }

Procedure PanelTitle(Y : LongInt; S : String);
Begin
  FBar(RpX, Y, CW - 1, Y + HdrH - 1, cNavy);
  OutTxt(RpX + 6, Y + 2, Fit(S, RpW - 12), cWhite, cNavy);
End;

Procedure PaintProject;
Var K, Y, Bg, Fg : LongInt;
Begin
  PanelTitle(Y0, 'Projet - ' + PrjName);
  Sunken(RpX, Y0 + HdrH, CW - 1, PrY0 - 3, cWhite);
  FBar(RpX, PrY0 - 2, CW - 1, PrY0 - 1, cSilver);
  Y := Y0 + HdrH + 4;
  { racine : le projet }
  IcX := RpX + 6; IcY := Y;
  IR(0, 2, 13, 13, cYellow); IB(0, 2, 13, 13, cBrown); IR(0, 0, 5, 2, cBrown);
  If PrjFile = '' Then OutTxt(RpX + 24, Y, Fit(PrjName, RpW - 30), cBlack, cWhite)
  Else OutTxt(RpX + 24, Y, Fit(PrjName + ' (' + NameOf(PrjFile) + ')', RpW - 30), cBlack, cWhite);
  Y := Y + 18;
  For K := 1 To NCtl Do
    If CtKind[K] = vkForm Then
    Begin
      If Y + 16 > PrY0 - 4 Then Break;
      VLine(RpX + 12, Y - 4, Y + 7, cGray); HLine(RpX + 12, RpX + 20, Y + 7, cGray);
      IcX := RpX + 22; IcY := Y;
      IR(0, 1, 13, 13, cSilver); IB(0, 1, 13, 13, cBlack); IR(1, 2, 12, 4, cNavy);
      If K = CurForm Then
      Begin
        Bg := cNavy; Fg := cWhite;
      End
      Else
      Begin
        Bg := cWhite; Fg := cBlack;
      End;
      OutTxt(RpX + 40, Y, Fit(CtName[K] + ' (' + CtName[K] + '.frm)', RpW - 46), Fg, Bg);
      Y := Y + 18;
    End;
End;

{ proprietes affichees pour le controle choisi (ordre alphabetique, (Name) en tete) }
Const
  PropOrd : Array[0..NProps - 1] Of LongInt = (ppName, ppAlign, ppCaption, ppEnabled, ppHeight, ppInterval, ppLeft,
                                               ppList, ppLocked, ppText, ppTop, ppValue, ppVisible, ppWidth);

Procedure BuildPropList;
Var K : LongInt;
Begin
  NPropL := 0;
  If (Sel < 1) Or (Sel > NCtl) Then Exit;
  For K := 0 To NProps - 1 Do
    If PropHas(CtKind[Sel], PropOrd[K]) Then
    Begin
      PropList[NPropL] := PropOrd[K];
      Inc(NPropL);
    End;
  If PropRow >= NPropL Then PropRow := NPropL - 1;
  If PropRow < 0 Then PropRow := 0;
End;

Function PropRows : LongInt;
Begin
  PropRows := MaxI(1, (PgY1 - PgY0) Div PrRowH);
End;

Function PropColX : LongInt;
Begin
  PropColX := RpX + 100;
End;

Procedure WrapOut(X, Y, W, MaxL : LongInt; S : String; Fg, Bg : LongInt);
Var L, K : LongInt;
Begin
  L := 0;
  While (S <> '') And (L < MaxL) Do
  Begin
    K := W Div 8;
    If Length(S) > K Then
    Begin
      While (K > 1) And (S[K] <> ' ') Do Dec(K);
      If K <= 1 Then K := W Div 8;
    End;
    OutTxt(X, Y + L * 16, Trim(Copy(S, 1, K)), Fg, Bg);
    Delete(S, 1, K);
    Inc(L);
  End;
End;

Procedure PaintProps;
Var I, Y, P, Cx, Fg, Bg : LongInt; S : String;
Begin
  If Sel > 0 Then PanelTitle(PrY0, 'Propri'#130't'#130's - ' + CtName[Sel]) Else PanelTitle(PrY0, 'Propri'#130't'#130's');
  FBar(RpX, PrY0 + HdrH, CW - 1, PgY0 - 1, cSilver);
  If Sel > 0 Then
  Begin
    Sunken(RpX + 2, PrY0 + HdrH + 2, CW - 3, PgY0 - 3, cWhite);
    OutTxt(RpX + 6, PrY0 + HdrH + 3, Fit(CtName[Sel] + ' ' + KindName(CtKind[Sel]), RpW - 12), cBlack, cWhite);
  End;
  FBar(RpX, PgY0, CW - 1, PgY1, cWhite);
  Cx := PropColX;
  BuildPropList;
  If PropTop > MaxI(0, NPropL - PropRows) Then PropTop := MaxI(0, NPropL - PropRows);
  For I := PropTop To NPropL - 1 Do
  Begin
    Y := PgY0 + (I - PropTop) * PrRowH;
    If Y + PrRowH > PgY1 Then Break;
    P := PropList[I];
    If I = PropRow Then
    Begin
      Fg := cWhite; Bg := cNavy;
    End
    Else
    Begin
      Fg := cBlack; Bg := cWhite;
    End;
    FBar(RpX, Y, Cx - 1, Y + PrRowH - 2, Bg);
    OutTxt(RpX + 4, Y + 1, Fit(PropName(P), Cx - RpX - 6), Fg, Bg);
    S := PropGet(Sel, P);
    OutTxt(Cx + 4, Y + 1, Fit(S, CW - Cx - 8), cBlack, cWhite);
    HLine(RpX, CW - 1, Y + PrRowH - 1, cSilver);
    VLine(Cx - 1, Y, Y + PrRowH - 1, cSilver);
    If (I = PropRow) And (PropChoices(CtKind[Sel], P) > 0) Then
    Begin
      Raised(CW - 18, Y, CW - 2, Y + PrRowH - 2);
      HLine(CW - 14, CW - 7, Y + 6, cBlack); HLine(CW - 13, CW - 8, Y + 7, cBlack);
      HLine(CW - 12, CW - 9, Y + 8, cBlack); HLine(CW - 11, CW - 10, Y + 9, cBlack);
    End;
  End;
  { description }
  Raised(RpX, PgY1 + 1, CW - 1, Y1);
  Sunken(RpX + 2, PgY1 + 3, CW - 3, Y1 - 2, cSilver);
  If (Sel > 0) And (NPropL > 0) Then
  Begin
    P := PropList[PropRow];
    OutTxt(RpX + 6, PgY1 + 5, PropName(P), cBlack, cSilver);
    WrapOut(RpX + 6, PgY1 + 21, RpW - 14, 3, PropDesc(P), cBlack, cSilver);
  End;
End;

Procedure PaintMsgs;
Var K, Y, Fg, Bg : LongInt;
Begin
  Raised(WX0, MsY0, WX1, MsY0 + HdrH - 1);
  OutTxt(WX0 + 6, MsY0 + 2, 'Messages', cBlack, cSilver);
  OutTxt(WX1 - 20, MsY0 + 2, 'x', cBlack, cSilver);
  Sunken(WX0, MsY0 + HdrH, WX1, Y1, cWhite);
  Y := MsY0 + HdrH + 2;
  For K := MsgTop To MsgN - 1 Do
  Begin
    If Y + 16 > Y1 - 1 Then Break;
    If K = MsgSel Then
    Begin
      Fg := cWhite; Bg := cNavy;
      FBar(WX0 + 2, Y, WX1 - 2, Y + 15, cNavy);
    End
    Else
    Begin
      Bg := cWhite;
      If Pos('Erreur', MsgTx[K]) > 0 Then Fg := cRed Else Fg := cBlack;
    End;
    OutTxt(WX0 + 6, Y, Fit(MsgTx[K], WX1 - WX0 - 12), Fg, Bg);
    Y := Y + 16;
  End;
End;

Procedure PaintStatus;
Var X : LongInt; S : String;
Begin
  Raised(0, CH - SbH, CW - 1, CH - 1);
  S := '';
  If CodeView And (Cur >= 0) Then S := 'Ligne ' + IStr(DCY[Cur] + 1) + ', col. ' + IStr(VisCol(Cur, DCY[Cur], DCX[Cur]) + 1)
  Else If (Sel > 0) And (Sel <> CurForm) Then
    S := IStr(CtX[Sel]) + ', ' + IStr(CtY[Sel]) + '   ' + IStr(CtW[Sel]) + ' x ' + IStr(CtH[Sel])
  Else If Sel > 0 Then S := IStr(CtW[Sel]) + ' x ' + IStr(CtH[Sel]);
  If S = '' Then S := ' ';
  X := CW - 12 - MaxI(Length(S), 18) * 8;
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
  If UY1 < Y0 Then PaintToolbar;
  If ShowTbx And (UX1 < TbxW) Then PaintToolbox;
  If (UX2 >= WX0) And (UX1 <= WX1) And (UY1 <= WY1) Then
  Begin
    If CodeView Then PaintEditor Else PaintDesigner;
  End;
  If ShowMsgs And (UY2 >= MsY0) And (UX2 >= WX0) And (UX1 <= WX1) Then PaintMsgs;
  If (RpX < CW) And (UX2 >= RpX) Then
  Begin
    If ShowProj Then PaintProject;
    If ShowProps Then PaintProps Else FBar(RpX, PrY0, CW - 1, Y1, cSilver);
  End;
  If UY2 >= CH - SbH Then PaintStatus;
  Dummy := WinEndPaint(Hps);
End;

{ ==================================================================== }
{ Edition                                                               }
{ ==================================================================== }

Var
  Clip : TBuf;                 { copie interne (le presse-papiers de PM garde 16 Ko) }
  FindS, ReplS : String;
  FindCase : Boolean;

Function DocRO : Boolean;
Begin
  DocRO := (Cur < 0) Or (Cur = GenDoc);
End;

Procedure Changed;
Begin
  ScrollToCaret;
  InvalEditor;
  InvalBand(WX0, WY0, WX1 + 1, EdTop);
  InvalStatus;
End;

{ avant un deplacement : selection avec Maj }
Procedure PreMove(Shift : Boolean);
Var D : LongInt;
Begin
  D := Cur;
  If Shift Then
  Begin
    If Not DSel[D] Then
    Begin
      DSel[D] := True; DAX[D] := DCX[D]; DAY[D] := DCY[D];
    End;
  End
  Else DSel[D] := False;
  DLastKind[D] := 0;
End;

Procedure ClampCaret;
Var D : LongInt;
Begin
  D := Cur;
  If DCY[D] < 0 Then DCY[D] := 0;
  If DCY[D] >= DN[D] Then DCY[D] := DN[D] - 1;
  If DCX[D] < 0 Then DCX[D] := 0;
  If DCX[D] > LLen(D, DCY[D]) Then DCX[D] := LLen(D, DCY[D]);
End;

Procedure VertMove(Dy : LongInt);
Var D : LongInt;
Begin
  D := Cur;
  If DWant[D] < 0 Then DWant[D] := VisCol(D, DCY[D], DCX[D]);
  DCY[D] := DCY[D] + Dy;
  If DCY[D] < 0 Then DCY[D] := 0;
  If DCY[D] >= DN[D] Then DCY[D] := DN[D] - 1;
  DCX[D] := ColToX(D, DCY[D], DWant[D]);
End;

Function IsWordC(C : LongInt) : Boolean;
Begin
  IsWordC := IsAl(C) Or IsDg(C);
End;

Procedure WordLeft;
Var D : LongInt;
Begin
  D := Cur;
  If DCX[D] = 0 Then
  Begin
    If DCY[D] > 0 Then
    Begin
      Dec(DCY[D]);
      DCX[D] := LLen(D, DCY[D]);
    End;
    Exit;
  End;
  While (DCX[D] > 0) And Not IsWordC(LChar(D, DCY[D], DCX[D] - 1)) Do Dec(DCX[D]);
  While (DCX[D] > 0) And IsWordC(LChar(D, DCY[D], DCX[D] - 1)) Do Dec(DCX[D]);
End;

Procedure WordRight;
Var D, L : LongInt;
Begin
  D := Cur;
  L := LLen(D, DCY[D]);
  If DCX[D] >= L Then
  Begin
    If DCY[D] < DN[D] - 1 Then
    Begin
      Inc(DCY[D]);
      DCX[D] := 0;
    End;
    Exit;
  End;
  While (DCX[D] < L) And IsWordC(LChar(D, DCY[D], DCX[D])) Do Inc(DCX[D]);
  While (DCX[D] < L) And Not IsWordC(LChar(D, DCY[D], DCX[D])) Do Inc(DCX[D]);
End;

{ retrait de la ligne (espaces et tabulations du debut) }
Function IndentOf(D, Y : LongInt) : LongInt;
Var K, L : LongInt;
Begin
  K := 0; L := LLen(D, Y);
  While (K < L) And ((LChar(D, Y, K) = 32) Or (LChar(D, Y, K) = 9)) Do Inc(K);
  IndentOf := K;
End;

Procedure TypeChar(C : LongInt);
Var D : LongInt; B : Array[0..0] Of Byte;
Begin
  If DocRO Then Exit;
  D := Cur;
  If D < 0 Then Exit;
  BeginEdit(D, 1);
  If DelSel(D) Then DLastKind[D] := 0;
  ClampCaret;
  B[0] := C;
  If Not InsMode And (DCX[D] < LLen(D, DCY[D])) Then DelChars(D, DCY[D], DCX[D], 1);
  InsChars(D, DCY[D], DCX[D], @B, 1);
  Inc(DCX[D]);
  DWant[D] := -1;
  Changed;
End;

Procedure NewLine;
Var D, N, Y : LongInt; B : TBuf; Q : PBytes;
Begin
  If DocRO Then Exit;
  D := Cur;
  If D < 0 Then Exit;
  BeginEdit(D, 2);
  Dummy := Ord(DelSel(D));
  ClampCaret;
  Y := DCY[D];
  { retrait automatique }
  N := MinI(IndentOf(D, Y), DCX[D]);
  BufInit(B);
  Q := LP(D, Y);
  If N > 0 Then BufAddB(B, Q, N);
  SplitLine(D, Y, DCX[D]);
  Inc(DCY[D]);
  DCX[D] := 0;
  If B.Len > 0 Then
  Begin
    InsChars(D, DCY[D], 0, B.P, B.Len);
    DCX[D] := B.Len;
  End;
  BufFree(B);
  DWant[D] := -1;
  Changed;
End;

Procedure BackSpace;
Var D, X : LongInt;
Begin
  If DocRO Then Exit;
  D := Cur;
  If D < 0 Then Exit;
  If HasSel(D) Then
  Begin
    BeginEdit(D, 2);
    Dummy := Ord(DelSel(D));
  End
  Else
  Begin
    ClampCaret;
    If DCX[D] > 0 Then
    Begin
      BeginEdit(D, 1);
      DelChars(D, DCY[D], DCX[D] - 1, 1);
      Dec(DCX[D]);
    End
    Else If DCY[D] > 0 Then
    Begin
      BeginEdit(D, 2);
      X := LLen(D, DCY[D] - 1);
      JoinLines(D, DCY[D] - 1);
      Dec(DCY[D]);
      DCX[D] := X;
    End;
  End;
  DSel[D] := False;
  DWant[D] := -1;
  Changed;
End;

Procedure DeleteKey;
Var D : LongInt;
Begin
  If DocRO Then Exit;
  D := Cur;
  If D < 0 Then Exit;
  BeginEdit(D, 2);
  If Not DelSel(D) Then
  Begin
    ClampCaret;
    If DCX[D] < LLen(D, DCY[D]) Then DelChars(D, DCY[D], DCX[D], 1)
    Else If DCY[D] < DN[D] - 1 Then JoinLines(D, DCY[D]);
  End;
  DWant[D] := -1;
  Changed;
End;

{ inserer un texte au curseur (remplace la selection) }
Procedure InsertStr(P : PBytes; N : LongInt);
Var D : LongInt;
Begin
  If DocRO Then Exit;
  D := Cur;
  If D < 0 Then Exit;
  BeginEdit(D, 2);
  Dummy := Ord(DelSel(D));
  ClampCaret;
  If N > 0 Then InsText(D, P, N);
  DWant[D] := -1;
  Changed;
End;

{ lignes touchees par la selection (ou la ligne du curseur) }
Procedure SelLines(Var A, B : LongInt);
Var Y1, X1, Y2, X2 : LongInt;
Begin
  If HasSel(Cur) Then
  Begin
    SelRange(Cur, Y1, X1, Y2, X2);
    A := Y1; B := Y2;
    If (X2 = 0) And (Y2 > Y1) Then B := Y2 - 1;
  End
  Else
  Begin
    A := DCY[Cur]; B := DCY[Cur];
  End;
End;

{ retrait (Tab) ou desindentation (Maj+Tab) des lignes choisies }
Procedure IndentLines(Dir : LongInt);
Var D, A, B, Y, N : LongInt; T : Array[0..0] Of Byte;
Begin
  If DocRO Then Exit;
  D := Cur;
  If D < 0 Then Exit;
  SelLines(A, B);
  BeginEdit(D, 2);
  T[0] := 9;
  For Y := A To B Do
    If Dir > 0 Then
    Begin
      If LLen(D, Y) > 0 Then InsChars(D, Y, 0, @T, 1);
    End
    Else
    Begin
      If LChar(D, Y, 0) = 9 Then DelChars(D, Y, 0, 1)
      Else
      Begin
        N := 0;
        While (N < TabStop) And (LChar(D, Y, N) = 32) Do Inc(N);
        If N > 0 Then DelChars(D, Y, 0, N);
      End;
    End;
  If A <> B Then
  Begin
    DSel[D] := True; DAY[D] := A; DAX[D] := 0;
    DCY[D] := B + 1; DCX[D] := 0;
    If DCY[D] >= DN[D] Then
    Begin
      DCY[D] := DN[D] - 1; DCX[D] := LLen(D, DCY[D]);
    End;
  End;
  ClampCaret;
  Changed;
End;

{ majuscules ou minuscules de la selection }
Procedure CaseSel(Up : Boolean);
Var D, Y1, X1, Y2, X2, Y, A, E, K, C : LongInt; Q : PBytes; B : TBuf;
Begin
  If DocRO Then Exit;
  D := Cur;
  If (D < 0) Or Not HasSel(D) Then Exit;
  SelRange(D, Y1, X1, Y2, X2);
  BeginEdit(D, 2);
  BufInit(B);
  For Y := Y1 To Y2 Do
  Begin
    A := 0; E := LLen(D, Y);
    If Y = Y1 Then A := MinI(X1, E);
    If Y = Y2 Then E := MinI(X2, E);
    If E <= A Then Continue;
    B.Len := 0;
    Q := LP(D, Y);
    BufAddB(B, Q, LLen(D, Y));
    For K := A To E - 1 Do
    Begin
      C := B.P^[K];
      If Up And (C >= 97) And (C <= 122) Then B.P^[K] := C - 32
      Else If Not Up And (C >= 65) And (C <= 90) Then B.P^[K] := C + 32;
    End;
    USet(D, Y, B.P, B.Len);
  End;
  BufFree(B);
  Changed;
End;

Procedure SelectAll;
Var D : LongInt;
Begin
  D := Cur;
  If D < 0 Then Exit;
  DSel[D] := True; DAY[D] := 0; DAX[D] := 0;
  DCY[D] := DN[D] - 1; DCX[D] := LLen(D, DCY[D]);
  Changed;
End;

{ --- presse-papiers --- }

Procedure CopySel;
Var D, Y1, X1, Y2, X2, N : LongInt; T : PBytes;
Begin
  D := Cur;
  If (D < 0) Or Not HasSel(D) Then Exit;
  SelRange(D, Y1, X1, Y2, X2);
  Clip.Len := 0;
  GetRange(D, Y1, X1, Y2, X2, Clip);
  { texte CP850 termine par un nul pour PM }
  N := MinI(Clip.Len, 16383);
  GetMem(T, N + 1);
  If T = Nil Then Exit;
  If N > 0 Then Move(Clip.P^[0], T^[0], N);
  T^[N] := 0;
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    Dummy := WinSetClipbrdData(Hab, LongInt(T), 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
  FreeMem(T, N + 1);
  If Clip.Len > 16383 Then StatusMsg := 'Copi'#130' : ' + IStr(Clip.Len) + ' caract'#138'res.'
  Else StatusMsg := '';
End;

Procedure CutSel;
Begin
  If DocRO Then Exit;
  If (Cur < 0) Or Not HasSel(Cur) Then Exit;
  CopySel;
  BeginEdit(Cur, 2);
  Dummy := Ord(DelSel(Cur));
  Changed;
End;

Procedure PasteClip;
Var A, N, K : LongInt; Same : Boolean;
Begin
  If DocRO Then Exit;
  If Cur < 0 Then Exit;
  If WinOpenClipbrd(Hab) = 0 Then Exit;
  A := WinQueryClipbrdData(Hab, 1);
  If A <> 0 Then
  Begin
    N := 0;
    While (N < 1048576) And (RdB(A + N) <> 0) Do Inc(N);
    { le presse-papiers de PM ne garde que 16 Ko : la copie interne est complete }
    Same := (Clip.Len > 16383) And (N = 16383);
    If Same Then
      For K := 0 To N - 1 Do
        If RdB(A + K) <> Clip.P^[K] Then
        Begin
          Same := False;
          Break;
        End;
    If Same Then InsertStr(Clip.P, Clip.Len) Else InsertStr(Pointer(A), N);
  End;
  Dummy := WinCloseClipbrd(Hab);
End;

{ --- recherche --- }

Function UpC(C : LongInt) : LongInt;
Begin
  If (C >= 97) And (C <= 122) Then UpC := C - 32 Else UpC := C;
End;

{ cherche FindS a partir de (Y, X) ; True : trouve (selection) }
Function FindFrom(Y, X : LongInt; Wrap : Boolean) : Boolean;
Var D, L, K, J, N, Cnt : LongInt; Q : PBytes; Ok : Boolean;
Begin
  FindFrom := False;
  D := Cur;
  N := Length(FindS);
  If (D < 0) Or (N = 0) Then Exit;
  Cnt := 0;
  While Cnt <= DN[D] Do
  Begin
    L := LLen(D, Y);
    Q := LP(D, Y);
    K := X;
    While K + N <= L Do
    Begin
      Ok := True;
      For J := 1 To N Do
        If FindCase Then
        Begin
          If Q^[K + J - 1] <> Ord(FindS[J]) Then
          Begin
            Ok := False;
            Break;
          End;
        End
        Else If UpC(Q^[K + J - 1]) <> UpC(Ord(FindS[J])) Then
        Begin
          Ok := False;
          Break;
        End;
      If Ok Then
      Begin
        DSel[D] := True; DAY[D] := Y; DAX[D] := K;
        DCY[D] := Y; DCX[D] := K + N;
        FindFrom := True;
        Exit;
      End;
      Inc(K);
    End;
    Inc(Y);
    X := 0;
    Inc(Cnt);
    If Y >= DN[D] Then
    Begin
      If Not Wrap Then Exit;
      Y := 0;
    End;
  End;
End;

Procedure FindNext;
Begin
  If (Cur < 0) Or (FindS = '') Then Exit;
  If FindFrom(DCY[Cur], DCX[Cur], True) Then StatusMsg := ''
  Else StatusMsg := '"' + FindS + '" introuvable.';
  Changed;
End;

{ remplace toutes les occurrences ; rend le nombre }
Function ReplaceAll : LongInt;
Var D, Cnt : LongInt; R : TBuf;
Begin
  ReplaceAll := 0;
  If DocRO Then Exit;
  ReplaceAll := 0;
  D := Cur;
  If (D < 0) Or (FindS = '') Then Exit;
  Cnt := 0;
  BufInit(R);
  BufAdd(R, ReplS);
  BeginEdit(D, 2);
  DCY[D] := 0; DCX[D] := 0;
  While FindFrom(DCY[D], DCX[D], False) Do
  Begin
    Dummy := Ord(DelSel(D));
    If R.Len > 0 Then InsChars(D, DCY[D], DCX[D], R.P, R.Len);
    DCX[D] := DCX[D] + R.Len;
    Inc(Cnt);
    If Cnt > 100000 Then Break;
  End;
  BufFree(R);
  DSel[D] := False;
  ReplaceAll := Cnt;
  Changed;
End;

{ --- position de la souris dans le texte --- }
Procedure HitText(Mx, My : LongInt; Var Y, X : LongInt);
Var D, V : LongInt;
Begin
  D := Cur;
  Y := DTop[D] + (My - TxY0) Div RowH;
  If My < TxY0 Then Y := DTop[D] - 1;
  If Y < 0 Then Y := 0;
  If Y >= DN[D] Then Y := DN[D] - 1;
  V := DLeft[D] + (Mx - TxX0 + 4) Div 8;
  If Mx < TxX0 Then V := DLeft[D];
  If V < 0 Then V := 0;
  X := ColToX(D, Y, V);
End;

Procedure SelectWord;
Var D, A, E, L : LongInt;
Begin
  D := Cur;
  L := LLen(D, DCY[D]);
  A := DCX[D]; E := DCX[D];
  While (A > 0) And IsWordC(LChar(D, DCY[D], A - 1)) Do Dec(A);
  While (E < L) And IsWordC(LChar(D, DCY[D], E)) Do Inc(E);
  If E = A Then Exit;
  DSel[D] := True; DAY[D] := DCY[D]; DAX[D] := A; DCX[D] := E;
End;

{ --- clavier de l'editeur --- }
Function EditKey(Fl, Ch_, Vk : LongInt) : Boolean;
Var D, Ya, Xa, Yb, Xb : LongInt; Shift, Ctrl : Boolean;
Begin
  EditKey := True;
  D := Cur;
  If D < 0 Then
  Begin
    EditKey := False;
    Exit;
  End;
  Shift := (Fl And KC_SHIFT) <> 0;
  Ctrl := (Fl And KC_CTRL) <> 0;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    Case Vk Of
      VK_LEFT :
        Begin
          If Not Shift And HasSel(D) Then
          Begin
            SelRange(D, Ya, Xa, Yb, Xb);
            DCY[D] := Ya; DCX[D] := Xa;
            ClampCaret;
            DSel[D] := False;
          End
          Else
          Begin
            PreMove(Shift);
            If Ctrl Then WordLeft
            Else If DCX[D] > 0 Then Dec(DCX[D])
            Else If DCY[D] > 0 Then
            Begin
              Dec(DCY[D]);
              DCX[D] := LLen(D, DCY[D]);
            End;
          End;
          DWant[D] := -1;
        End;
      VK_RIGHT :
        Begin
          PreMove(Shift);
          If Ctrl Then WordRight
          Else If DCX[D] < LLen(D, DCY[D]) Then Inc(DCX[D])
          Else If DCY[D] < DN[D] - 1 Then
          Begin
            Inc(DCY[D]);
            DCX[D] := 0;
          End;
          DWant[D] := -1;
        End;
      VK_UP :
        If Ctrl Then
        Begin
          If DTop[D] > 0 Then Dec(DTop[D]);
          If DCY[D] >= DTop[D] + Rows Then VertMove(-1);
        End
        Else
        Begin
          PreMove(Shift);
          VertMove(-1);
        End;
      VK_DOWN :
        If Ctrl Then
        Begin
          If DTop[D] < MaxTop Then Inc(DTop[D]);
          If DCY[D] < DTop[D] Then VertMove(1);
        End
        Else
        Begin
          PreMove(Shift);
          VertMove(1);
        End;
      VK_PAGEUP :
        Begin
          PreMove(Shift);
          DTop[D] := MaxI(0, DTop[D] - Rows + 1);
          VertMove(-(Rows - 1));
        End;
      VK_PAGEDOWN :
        Begin
          PreMove(Shift);
          DTop[D] := MinI(MaxTop, DTop[D] + Rows - 1);
          VertMove(Rows - 1);
        End;
      VK_HOME :
        Begin
          PreMove(Shift);
          If Ctrl Then
          Begin
            DCY[D] := 0; DCX[D] := 0;
          End
          Else If (DCX[D] = IndentOf(D, DCY[D])) Then DCX[D] := 0
          Else DCX[D] := IndentOf(D, DCY[D]);
          DWant[D] := -1;
        End;
      VK_END :
        Begin
          PreMove(Shift);
          If Ctrl Then DCY[D] := DN[D] - 1;
          DCX[D] := LLen(D, DCY[D]);
          DWant[D] := -1;
        End;
      VK_BACKSPACE : BackSpace;
      VK_DELETE :
        If Shift Then CutSel Else DeleteKey;
      VK_INSERT :
        If Shift Then PasteClip
        Else If Ctrl Then CopySel
        Else InsMode := Not InsMode;
      VK_ENTER, VK_NEWLINE : NewLine;
      VK_TAB :
        If Ctrl Then
        Begin
          EditKey := False;
          Exit;
        End
        Else If Shift Then IndentLines(-1)
        Else If HasSel(D) And (DAY[D] <> DCY[D]) Then IndentLines(1)
        Else TypeChar(9);
      VK_BACKTAB : IndentLines(-1);
    Else
      Begin
        { touche virtuelle qui porte aussi un caractere (espace...) }
        If ((Fl And KC_CHAR) = 0) Or Ctrl Or ((Fl And KC_ALT) <> 0) Or (Ch_ < 32) Or (Ch_ = 127) Then
        Begin
          EditKey := False;
          Exit;
        End;
        TypeChar(Ch_);
        Exit;
      End;
    End;
    ClampCaret;
    Changed;
    Exit;
  End;
  If ((Fl And KC_CHAR) <> 0) And Not Ctrl And ((Fl And KC_ALT) = 0) And (Ch_ >= 32) And (Ch_ <> 127) Then
  Begin
    TypeChar(Ch_);
    Exit;
  End;
  EditKey := False;
End;
{ ==================================================================== }
{ Boites de dialogue et messages                                        }
{ ==================================================================== }

Const
  WM_SETFOCUS = $000F;
  WM_MOUSEWHEEL_DUMMY = 0;
  MaxDlg = 6;
  dNone = 0; dTool = 1; dCreate = 2; dMove = 3; dSize = 4; dTxSel = 5; dVThumb = 6; dHThumb = 7; dMoveWait = 8;
  MaxSnap = 12;
  cmProcFirst = 1000;  { + procedure de (General) }
  MaxPopL = 100;

Var
  DgFrame, DgClient, DgN, DgW, DgH : LongInt;
  DgDone, DgOk : Boolean;
  DgLab, DgV : Array[0..MaxDlg - 1] Of String;
  DgEf : Array[0..MaxDlg - 1] Of LongInt;
  Drag, DragX0, DragY0, DragOX, DragOY, DragHd, DragC, LastMx, LastMy : LongInt;
  DragR : Array[0..3] Of LongInt;
  CtxMenu : LongInt;
  MStkN : Array[0..7] Of LongInt;
  MDep : LongInt;
  WorkDir, ExeDir, CompilerPath, MakeExe, LastExe, CompErr, CompSrc : String;
  AutoMake, AutoRun, AutoQuit : Boolean;
  LogFile : String;
  CompH, CompT0 : LongInt;
  CompEF : Text;
  ArgBuf : Array[0..599] Of Byte;
  FailBuf : Array[0..63] Of Byte;
  { proprietes }
  PropEf, PropEfP : LongInt;
  PopObjFor : LongInt;           { 1 : liste Objet de la fenetre de code ; 2 : objet des proprietes }
  PopLine : Array[0..MaxPopL - 1] Of LongInt;
  NPopL : LongInt;
  { presse-papiers des controles }
  CbKind : LongInt;
  CbProp : Array[1..NProps] Of String;
  { annulation de la conception }
  SnapB : Array[0..MaxSnap - 1] Of TBuf;
  SnapN : LongInt;
  CtxCtl : LongInt;
  SavedMsg : String;

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
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Visual Pascal'), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure MsgErr(S : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Visual Pascal'), 0, MB_OK Or MB_ERROR Or MB_MOVEABLE);
End;

Function Ask3(S : String) : LongInt;
Begin
  Ask3 := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Visual Pascal'), 0, MB_YESNOCANCEL Or MB_QUERY Or MB_MOVEABLE);
End;

Function AskYes(S : String) : Boolean;
Begin
  AskYes := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Visual Pascal'), 0, MB_YESNO Or MB_QUERY Or MB_MOVEABLE) =
            MBID_YES;
End;

Procedure ShowBuf(Title : String; Var B : TBuf);
Begin
  If B.Len > 3500 Then B.Len := 3500;
  BufAddC(B, 0);
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, LongInt(B.P), Z2(Title), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
  Dec(B.Len);
End;

Function DlgProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Var P, Fl, Vk, K, X : LongInt; Rc, Tr : Array[0..3] Of LongInt;
Begin
  DlgProc := 0;
  Case Msg_ Of
    WM_PAINT :
      Begin
        P := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(P, LongInt(@Rc), cSilver);
        For K := 0 To DgN - 1 Do
        Begin
          PutZ(DgLab[K]);
          Tr[0] := 12; Tr[1] := DgH - 30 - K * 46; Tr[2] := DgW - 12; Tr[3] := Tr[1] + 18;
          Dummy := WinDrawText(P, -1, LongInt(@TxtBuf), LongInt(@Tr), cBlack, cSilver, 0);
        End;
        Dummy := WinEndPaint(P);
      End;
    WM_COMMAND :
      Begin
        If Lo16(Mp1) = 1 Then
        Begin
          For K := 0 To DgN - 1 Do DgV[K] := WinText(DgEf[K]);
          DgOk := True;
        End;
        DgDone := True;
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_TAB) Or (Vk = VK_BACKTAB) Or
           (Vk = VK_DOWN) Or (Vk = VK_UP)) Then
        Begin
          P := WinQueryFocus(HWND_DESKTOP);
          X := 0;
          For K := 0 To DgN - 1 Do If DgEf[K] = P Then X := K;
          If (Vk = VK_BACKTAB) Or (Vk = VK_UP) Or ((Fl And KC_SHIFT) <> 0) Then Dec(X) Else Inc(X);
          If X < 0 Then X := DgN - 1;
          If X >= DgN Then X := 0;
          If DgN > 0 Then Dummy := WinSetFocus(HWND_DESKTOP, DgEf[X]);
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
  For K := 0 To MaxDlg - 1 Do
  Begin
    DgLab[K] := ''; DgV[K] := '';
  End;
End;

Procedure DlgField(L, V : String);
Begin
  If DgN >= MaxDlg Then Exit;
  DgLab[DgN] := L; DgV[DgN] := V;
  Inc(DgN);
End;

Function InputBox(Title, OkS : String) : Boolean;
Var Fl, K, Fw, Fh, Sw, Sh : LongInt; Rc : Array[0..3] Of LongInt; Q : Array[0..7] Of LongInt;
Begin
  InputBox := False;
  DgW := 520;
  DgH := 56 + DgN * 46;
  Dummy := WinRegisterClass(Hab, Z('VPDLG'), LongInt(@DlgProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DgClient := 0;
  DgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('VPDLG'), Z2(Title), 0, 0, 0, LongInt(@DgClient));
  If DgFrame = 0 Then Exit;
  For K := 0 To DgN - 1 Do
  Begin
    DgEf[K] := WinCreateWindow(DgClient, WC_ENTRYFIELD, Z(DgV[K]), WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or
                               ES_MARGIN, 14, DgH - 54 - K * 46, DgW - 28, 20, DgClient, HWND_TOP, 10 + K, 0, 0);
    Dummy := WinSendMsg(DgEf[K], EM_SETTEXTLIMIT, 250, 0);
    { tout le texte choisi : la frappe le remplace }
    Dummy := WinSendMsg(DgEf[K], $0142, Length(DgV[K]) Shl 16, 0);
  End;
  Dummy := WinCreateWindow(DgClient, WC_BUTTON, Z(OkS), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                           DgW - 232, 10, 120, 26, DgClient, HWND_TOP, 1, 0, 0);
  Dummy := WinCreateWindow(DgClient, WC_BUTTON, Z('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                           DgW - 102, 10, 90, 26, DgClient, HWND_TOP, 2, 0, 0);
  Rc[0] := 0; Rc[1] := 0; Rc[2] := DgW; Rc[3] := DgH;
  Dummy := WinCalcFrameRect(DgFrame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(DgFrame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, DgFrame);
  If DgN > 0 Then Dummy := WinSetFocus(HWND_DESKTOP, DgEf[0]);
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
  InputBox := DgOk;
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

Procedure BuildMenu;
Var H0, H1, H2 : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 80, '~Fichier');
  H1 := MenuOpen;
  It(cmNew, '~Nouveau projet' + #9 + 'Ctrl+N');
  It(cmOpen, '~Ouvrir un projet...' + #9 + 'Ctrl+O');
  It(cmSave, '~Enregistrer le projet' + #9 + 'Ctrl+S');
  It(cmSaveAs, 'Enregistrer le projet ~sous...');
  Sep;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 89, 'E~xemples');
  H2 := MenuOpen;
  It(cmSampleCalc, '~Calculatrice');
  It(cmSampleDemo, '~D'#130'monstration des contr'#147'les');
  MenuClose(H2);
  Sep;
  It(cmMakeExe, 'C~r'#130'er l''EXE...');
  Sep;
  It(cmQuit, '~Quitter' + #9 + 'Alt+F4');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 81, '~Edition');
  H1 := MenuOpen;
  It(cmUndo, '~Annuler' + #9 + 'Ctrl+Z');
  It(cmRedo, '~R'#130'tablir' + #9 + 'Ctrl+Y');
  Sep;
  It(cmCut, '~Couper' + #9 + 'Ctrl+X');
  It(cmCopy, 'C~opier' + #9 + 'Ctrl+C');
  It(cmPaste, 'Co~ller' + #9 + 'Ctrl+V');
  It(cmDelete, '~Supprimer' + #9 + 'Suppr');
  Sep;
  It(cmSelAll, 'S'#130'lectionner ~tout' + #9 + 'Ctrl+A');
  It(cmFind, '~Rechercher...' + #9 + 'Ctrl+F');
  It(cmFindNext, 'Rechercher le s~uivant' + #9 + 'F3');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 82, '~Affichage');
  H1 := MenuOpen;
  It(cmCode, '~Code' + #9 + 'F7');
  It(cmObject, '~Objet' + #9 + 'Maj+F7');
  Sep;
  ItA(cmShowProj, Chk(ShowProj), '~Explorateur de projets' + #9 + 'Ctrl+R');
  ItA(cmShowProps, Chk(ShowProps), 'Fen'#136'tre ~Propri'#130't'#130's' + #9 + 'F4');
  ItA(cmShowTbx, Chk(ShowTbx), '~Bo'#140'te '#133' outils');
  ItA(cmShowMsgs, Chk(ShowMsgs), 'Fen'#136'tre ~Messages' + #9 + 'Ctrl+G');
  ItA(cmNums, Chk(ShowNums), '~Num'#130'ros de ligne');
  Sep;
  It(cmShowGen, 'Programme ~g'#130'n'#130'r'#130' (Pascal complet)');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 83, '~Projet');
  H1 := MenuOpen;
  It(cmAddForm, '~Ajouter une feuille');
  It(cmDelForm, '~Supprimer la feuille');
  Sep;
  It(cmPrjProps, '~Propri'#130't'#130's du projet...');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 84, 'F~ormat');
  H1 := MenuOpen;
  It(cmSnap, '~Aligner sur la grille');
  It(cmCenterH, 'Centrer ~horizontalement dans la feuille');
  It(cmCenterV, 'Centrer ~verticalement dans la feuille');
  Sep;
  It(cmToFront, 'Mettre au ~premier plan');
  It(cmToBack, 'Mettre '#133' l''~arri'#138're-plan');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 85, 'E~x'#130'cution');
  H1 := MenuOpen;
  It(cmRun, '~Ex'#130'cuter' + #9 + 'F5');
  It(cmStop, '~Arr'#136'ter');
  Sep;
  It(cmCompile, '~Compiler (v'#130'rifier le code)' + #9 + 'Ctrl+F5');
  It(cmMakeExe, 'C~r'#130'er l''EXE...');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 86, '~?');
  H1 := MenuOpen;
  It(cmHelp, '~Aide' + #9 + 'F1');
  It(cmLang, '~Propri'#130't'#130's et m'#130'thodes des contr'#147'les');
  Sep;
  It(cmAbout, '~A propos de Visual Pascal...');
  MenuClose(H1);
  MenuClose(H0);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
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

Procedure TbAdd(Cmd, Ico : LongInt; Tip : String);
Begin
  If NTb >= MaxTb Then Exit;
  TbCmd[NTb] := Cmd; TbIco[NTb] := Ico; TbTip[NTb] := Tip;
  If Cmd = 0 Then TbW[NTb] := 6 Else TbW[NTb] := 24;
  If NTb = 0 Then TbX[NTb] := 4 Else TbX[NTb] := TbX[NTb - 1] + TbW[NTb - 1] + 2;
  Inc(NTb);
End;

Procedure ToolbarInit;
Begin
  NTb := 0; TbDown := -1; TbHot := -1;
  TbAdd(cmNew, 1, 'Nouveau projet (Ctrl+N)');
  TbAdd(cmAddForm, 16, 'Ajouter une feuille');
  TbAdd(0, 0, '');
  TbAdd(cmOpen, 2, 'Ouvrir un projet (Ctrl+O)');
  TbAdd(cmSave, 3, 'Enregistrer le projet (Ctrl+S)');
  TbAdd(0, 0, '');
  TbAdd(cmCut, 6, 'Couper (Ctrl+X)');
  TbAdd(cmCopy, 7, 'Copier (Ctrl+C)');
  TbAdd(cmPaste, 8, 'Coller (Ctrl+V)');
  TbAdd(0, 0, '');
  TbAdd(cmUndo, 4, 'Annuler (Ctrl+Z)');
  TbAdd(cmRedo, 5, 'R'#130'tablir (Ctrl+Y)');
  TbAdd(0, 0, '');
  TbAdd(cmRun, 10, 'Ex'#130'cuter (F5)');
  TbAdd(cmStop, 12, 'Arr'#136'ter');
  TbAdd(0, 0, '');
  TbAdd(cmCode, 13, 'Afficher le code (F7)');
  TbAdd(cmObject, 17, 'Afficher l''objet (Maj+F7)');
  TbAdd(0, 0, '');
  TbAdd(cmMakeExe, 18, 'Cr'#130'er l''EXE');
  TbAdd(cmHelp, 14, 'Aide (F1)');
End;

{ ==================================================================== }
{ Fenetre Messages                                                      }
{ ==================================================================== }

Procedure MsgClear;
Begin
  MsgN := 0; MsgTop := 0; MsgSel := -1;
End;

Procedure MsgAdd(S : String; F, L : LongInt);
Begin
  If MsgN >= MaxMsg Then Exit;
  MsgTx[MsgN] := S; MsgF[MsgN] := F; MsgL[MsgN] := L;
  Inc(MsgN);
  If MsgN > 5 Then MsgTop := MsgN - 5;
End;

{ ==================================================================== }
{ Selection, vues                                                       }
{ ==================================================================== }

Procedure SetTitle;
Var S, M : String;
Begin
  M := '';
  If PrjMod Then M := ' *';
  If CodeView And (Cur = GenDoc) Then S := ' [programme g'#130'n'#130'r'#130']'
  Else If CodeView Then S := ' [code]'
  Else S := ' [conception]';
  S := PrjName + M + ' - Visual Pascal' + S;
  Dummy := WinSetWindowText(Frame, Z(S));
End;

Procedure PropKill;
Begin
  If PropEf <> 0 Then Dummy := WinDestroyWindow(PropEf);
  PropEf := 0;
End;

Procedure PropCommit; Forward;

Procedure SelectCtl(C : LongInt);
Begin
  PropCommit;
  If C <> Sel Then PropTop := 0;
  Sel := C;
  If (C > 0) And (C <= NCtl) Then
    If CtKind[C] = vkForm Then CurForm := C Else CurForm := CtForm[C];
  InvalWork;
  InvalProps;
  InvalProj;
  InvalStatus;
End;

Procedure ShowDesign;
Begin
  If Not CodeView Then Exit;
  CodeView := False;
  Layout;
  SetTitle;
  Redraw;
End;

Procedure ShowCodeOf(F : LongInt);
Begin
  PropCommit;
  If (F <= 0) Or (F > NCtl) Then Exit;
  CurForm := F;
  Cur := CtDoc[F];
  CodeView := True;
  Layout;
  ScrollToCaret;
  SetTitle;
  Redraw;
End;

{ code de l'evenement par defaut d'un controle (double clic du concepteur) }
Procedure CodeFor(C : LongInt);
Begin
  If (C <= 0) Or (C > NCtl) Then Exit;
  If EvCount(CtKind[C]) = 0 Then
  Begin
    ShowCodeOf(CtForm[C]);
    StatusMsg := CtName[C] + ' (' + KindName(CtKind[C]) + ') n''a pas d'''#130'v'#130'nement.';
    Exit;
  End;
  GotoHandler(C, EvName(CtKind[C], 1));
  ShowCodeOf(CtForm[C]);
  StatusMsg := 'Proc'#130'dure ' + CtName[C] + '_' + EvName(CtKind[C], 1);
End;

Procedure Changed2;
Begin
  PrjMod := True;
  SetTitle;
  InvalWork;
  InvalProps;
  InvalStatus;
End;

{ --- annulation des modifications de la conception (instantanes du projet) --- }

Procedure Snapshot;
Var K : LongInt;
Begin
  If SnapN >= MaxSnap Then
  Begin
    BufFree(SnapB[0]);
    For K := 0 To MaxSnap - 2 Do SnapB[K] := SnapB[K + 1];
    BufInit(SnapB[MaxSnap - 1]);
    SnapN := MaxSnap - 1;
  End;
  BufInit(SnapB[SnapN]);
  SaveToBuf(SnapB[SnapN]);
  Inc(SnapN);
End;

Procedure SnapClear;
Var K : LongInt;
Begin
  For K := 0 To SnapN - 1 Do BufFree(SnapB[K]);
  SnapN := 0;
End;

Procedure DesignUndo;
Var Nf, Ns, Pf, Er : String; K : LongInt;
Begin
  If SnapN = 0 Then
  Begin
    StatusMsg := 'Rien '#133' annuler.';
    InvalStatus;
    Exit;
  End;
  Nf := ''; Ns := '';
  If CurForm > 0 Then Nf := CtName[CurForm];
  If Sel > 0 Then Ns := CtName[Sel];
  Pf := PrjFile;
  Dec(SnapN);
  Er := LoadFromBuf(SnapB[SnapN]);
  BufFree(SnapB[SnapN]);
  PrjFile := Pf;
  PrjMod := True;
  CurForm := FindCtl(Nf);
  If (CurForm = 0) Or (CtKind[CurForm] <> vkForm) Then CurForm := FirstForm;
  Sel := FindCtl(Ns);
  If Sel = 0 Then Sel := CurForm;
  K := 0;
  StatusMsg := 'Modification annul'#130'e.';
  SetTitle;
  Redraw;
End;

{ ==================================================================== }
{ Fenetre des proprietes                                                }
{ ==================================================================== }

Procedure PropCommit;
Var S, E : String; C, P : LongInt;
Begin
  If PropEf = 0 Then Exit;
  S := WinText(PropEf);
  C := Sel; P := PropEfP;
  PropKill;
  If (C < 1) Or (C > NCtl) Then Exit;
  If S = PropGet(C, P) Then Exit;
  Snapshot;
  E := PropSet(C, P, S);
  If E <> '' Then
  Begin
    Dec(SnapN);
    BufFree(SnapB[SnapN]);
    MsgErr(PropName(P) + ' : ' + E);
  End;
  Changed2;
  InvalProj;
End;

Procedure PropCancel;
Begin
  PropKill;
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  InvalProps;
End;

{ ouvre la saisie de la propriete de la ligne I }
Procedure PropEdit(I : LongInt);
Var Y, P, X : LongInt;
Begin
  PropCommit;
  BuildPropList;
  If (Sel < 1) Or (I < 0) Or (I >= NPropL) Then Exit;
  PropRow := I;
  If PropRow < PropTop Then PropTop := PropRow;
  If PropRow >= PropTop + PropRows Then PropTop := PropRow - PropRows + 1;
  P := PropList[I];
  Y := PgY0 + (I - PropTop) * PrRowH;
  X := PropColX;
  PropEfP := P;
  PropEf := WinCreateWindow(Client, WC_ENTRYFIELD, Z(PropGet(Sel, P)), WS_VISIBLE Or ES_AUTOSCROLL, X + 1,
                            CH - (Y + PrRowH - 1), CW - X - 3, PrRowH - 2, Client, HWND_TOP, 50, 0, 0);
  If PropEf <> 0 Then
  Begin
    Dummy := WinSendMsg(PropEf, EM_SETTEXTLIMIT, 250, 0);
    Dummy := WinSendMsg(PropEf, $0142, Length(PropGet(Sel, P)) Shl 16, 0);
    Dummy := WinSetFocus(HWND_DESKTOP, PropEf);
  End;
  InvalProps;
End;

{ valeur suivante d'une propriete a choix (double clic) }
Procedure PropCycle(I : LongInt);
Var P, N, V : LongInt; S, E : String;
Begin
  BuildPropList;
  If (Sel < 1) Or (I < 0) Or (I >= NPropL) Then Exit;
  P := PropList[I];
  N := PropChoices(CtKind[Sel], P);
  If N = 0 Then Exit;
  S := PropGet(Sel, P);
  For V := 0 To N - 1 Do
    If PropChoice(CtKind[Sel], P, V) = S Then
    Begin
      Snapshot;
      E := PropSet(Sel, P, PropChoice(CtKind[Sel], P, (V + 1) Mod N));
      Changed2;
      Exit;
    End;
End;

Procedure PropChoicePopup(I, X, Y : LongInt);
Var P, N, V, H : LongInt;
Begin
  BuildPropList;
  If (Sel < 1) Or (I < 0) Or (I >= NPropL) Then Exit;
  P := PropList[I];
  N := PropChoices(CtKind[Sel], P);
  If N = 0 Then Exit;
  PropEfP := P;
  MenuLen := 0;
  H := MenuOpen;
  For V := 0 To N - 1 Do
    ItA(cmChoice + V, Chk(PropChoice(CtKind[Sel], P, V) = PropGet(Sel, P)), PropChoice(CtKind[Sel], P, V));
  MenuClose(H);
  ShowPopup(X, Y);
End;

{ liste des objets de la feuille (popup) }
Procedure ObjPopup(X, Y, Mode : LongInt);
Var C, H : LongInt;
Begin
  If CurForm <= 0 Then Exit;
  PopObjFor := Mode;
  MenuLen := 0;
  H := MenuOpen;
  If Mode = 1 Then It(cmObjFirst, '(G'#130'n'#130'ral)');
  It(cmObjFirst + CurForm, CtName[CurForm] + '  (Form)');
  For C := 1 To NCtl Do
    If (CtForm[C] = CurForm) And (C <> CurForm) Then It(cmObjFirst + C, CtName[C] + '  (' + KindName(CtKind[C]) + ')');
  MenuClose(H);
  ShowPopup(X, Y);
End;

{ liste Procedure : evenements de l'objet de la ligne du curseur, ou procedures du code }
Procedure ProcPopup(X, Y : LongInt);
Var P, S, U : String; K, C, H, D, Ln : LongInt;
Begin
  D := Cur;
  If (D < 0) Or (D = GenDoc) Then Exit;
  P := CaretProc;
  C := 0;
  K := Pos('_', P);
  If K > 0 Then C := FindCtl(Copy(P, 1, K - 1));
  If (C > 0) And (EvCount(CtKind[C]) = 0) Then C := 0;
  MenuLen := 0;
  H := MenuOpen;
  NPopL := 0;
  If C > 0 Then
  Begin
    PopObjFor := C;
    For K := 1 To EvCount(CtKind[C]) Do
    Begin
      S := EvName(CtKind[C], K);
      If FindProc(D, CtName[C] + '_' + S) >= 0 Then It(cmEvFirst + K, S + '  *') Else It(cmEvFirst + K, S);
    End;
  End
  Else
  Begin
    It(cmProcFirst + MaxPopL, '(D'#130'clarations)');
    For Ln := 0 To DN[D] - 1 Do
    Begin
      U := UpStr(Trim(LStr(D, Ln)));
      If ((Pos('PROCEDURE ', U) = 1) Or (Pos('FUNCTION ', U) = 1)) And (NPopL < MaxPopL) Then
      Begin
        PopLine[NPopL] := Ln;
        It(cmProcFirst + NPopL, Copy(Trim(LStr(D, Ln)), 1, 60));
        Inc(NPopL);
      End;
    End;
  End;
  MenuClose(H);
  ShowPopup(X, Y);
End;

{ ==================================================================== }
{ Projet : nouveau, ouvrir, enregistrer, exemples                       }
{ ==================================================================== }

Function Modified : Boolean;
Var K : LongInt; M : Boolean;
Begin
  M := PrjMod;
  For K := 1 To NCtl Do
    If (CtKind[K] = vkForm) And (CtDoc[K] >= 0) Then If DMod[CtDoc[K]] Then M := True;
  Modified := M;
End;

Procedure FreeGen;
Begin
  If GenDoc >= 0 Then DocFree(GenDoc);
  GenDoc := -1;
End;

Procedure AfterLoad;
Begin
  PropKill;
  FreeGen;
  SnapClear;
  CurForm := FirstForm;
  Sel := CurForm;
  CodeView := False;
  Cur := -1;
  If CurForm > 0 Then Cur := CtDoc[CurForm];
  DsX := 0; DsY := 0; PropRow := 0; PropTop := 0; Tool := 0;
  Layout;
  SetTitle;
  Redraw;
End;

Procedure NewProject;
Var F : LongInt;
Begin
  ClearProject;
  F := NewForm;
  If F > 0 Then
  Begin
    CtW[F] := 400; CtH[F] := 300;
  End;
  PrjMod := False;
  AfterLoad;
  StatusMsg := 'Nouveau projet : choisissez un contr'#147'le dans la bo'#140'te '#133' outils et tracez-le sur la feuille.';
End;

Function SaveTo(Name : String) : Boolean;
Begin
  SaveTo := False;
  If ExtOf(Name) = '' Then Name := Name + '.VPP';
  If Not SaveProject(Name) Then
  Begin
    MsgErr('Impossible d''enregistrer ' + Name + '.');
    Exit;
  End;
  StatusMsg := 'Projet enregistr'#130' : ' + Name;
  SaveTo := True;
  SetTitle;
  Redraw;
End;

Function SaveAsDlg : Boolean;
Var N : String;
Begin
  SaveAsDlg := False;
  DlgReset;
  N := PrjFile;
  If N = '' Then N := JoinPath(WorkDir, Copy(UpStr(CodeName), 1, 8) + '.VPP');
  DlgField('Fichier du projet (.VPP) :', N);
  If Not InputBox('Enregistrer le projet sous', 'Enregistrer') Then Exit;
  N := Trim(DgV[0]);
  If N = '' Then Exit;
  If (Length(N) < 2) Or (N[2] <> ':') Then N := JoinPath(WorkDir, N);
  SaveAsDlg := SaveTo(N);
End;

Function SaveCur : Boolean;
Begin
  PropCommit;
  If PrjFile = '' Then SaveCur := SaveAsDlg Else SaveCur := SaveTo(PrjFile);
End;

Function CanDiscard : Boolean;
Var R : LongInt;
Begin
  CanDiscard := True;
  PropCommit;
  If Not Modified Then Exit;
  R := Ask3('Le projet ' + PrjName + ' a '#130't'#130' modifi'#130'. L''enregistrer ?');
  If R = MBID_CANCEL Then CanDiscard := False
  Else If R = MBID_YES Then CanDiscard := SaveCur;
End;

Function OpenFile(N : String) : Boolean;
Var E : String;
Begin
  OpenFile := False;
  If (ExtOf(N) = '') And Not FExists(N) Then N := N + '.VPP';
  E := LoadProject(N);
  If E <> '' Then
  Begin
    MsgErr(E);
    NewProject;
    Exit;
  End;
  AfterLoad;
  StatusMsg := 'Projet ouvert : ' + N;
  OpenFile := True;
End;

{ fichiers .VPP d'un repertoire (noms separes par des espaces) }
Function VppList(D : String; Var First : String) : String;
Var Bf : Array[0..299] Of Byte; H, N, K, L : LongInt; S, R : String;
Begin
  R := ''; First := '';
  H := -1; N := 1;
  If DosFindFirst(Z(JoinPath(D, '*.VPP')), LongInt(@H), $27, LongInt(@Bf), SizeOf(Bf), LongInt(@N), 1) = 0 Then
  Begin
    Repeat
      L := Bf[28];
      S := '';
      For K := 1 To L Do S := S + Chr(Bf[28 + K]);
      If First = '' Then First := S;
      If Length(R) + Length(S) < 200 Then R := R + ' ' + S;
      N := 1;
    Until DosFindNext(H, LongInt(@Bf), SizeOf(Bf), LongInt(@N)) <> 0;
    Dummy := DosFindClose(H);
  End;
  VppList := R;
End;

Procedure OpenDlg;
Var N, L, F : String;
Begin
  If Not CanDiscard Then Exit;
  DlgReset;
  L := VppList(WorkDir, F);
  If L = '' Then L := ' (aucun)';
  N := PrjFile;
  If (N = '') And (F <> '') Then N := JoinPath(WorkDir, F);
  DlgField(Fit('Projets de ' + WorkDir + ' :' + L, 496), N);
  If Not InputBox('Ouvrir un projet', 'Ouvrir') Then Exit;
  N := Trim(DgV[0]);
  If N = '' Then Exit;
  If (Length(N) < 2) Or (N[2] <> ':') Then N := JoinPath(WorkDir, N);
  If OpenFile(N) Then ;
End;

Procedure LoadSample(I : LongInt);
Var E : String;
Begin
  If I = 1 Then SampleCalc Else SampleDemo;
  E := LoadFromBuf(SampB);
  If E <> '' Then
  Begin
    MsgErr('Exemple : ' + E);
    NewProject;
    Exit;
  End;
  PrjFile := '';
  AfterLoad;
  StatusMsg := 'Exemple ' + PrjName + ' : F5 pour l''ex'#130'cuter, F7 pour voir son code.';
End;

{ ==================================================================== }
{ Compilation (OS2PC.EXE) et execution                                  }
{ ==================================================================== }

Procedure SetArgs(Prog, Args : String);
Var K, N : LongInt;
Begin
  N := 0;
  For K := 1 To Length(Prog) Do
  Begin
    ArgBuf[N] := Ord(Prog[K]);
    Inc(N);
  End;
  ArgBuf[N] := 0; Inc(N);
  For K := 1 To Length(Args) Do
  Begin
    ArgBuf[N] := Ord(Args[K]);
    Inc(N);
  End;
  ArgBuf[N] := 0; ArgBuf[N + 1] := 0;
End;

Function WriteAll(Name : String; P : PBytes; N : LongInt) : Boolean;
Var H : LongInt;
Begin
  WriteAll := False;
  If Not FOpenWrite(Name, H) Then Exit;
  WriteAll := (N = 0) Or (FWrite(H, P, N) = N);
  DosClose(H);
End;

Function NumAfter(S, Key : String) : LongInt;
Var K, V : LongInt;
Begin
  NumAfter := -1;
  K := Pos(Key, S);
  If K = 0 Then Exit;
  K := K + Length(Key);
  While (K <= Length(S)) And (S[K] = ' ') Do Inc(K);
  V := 0;
  If (K > Length(S)) Or (S[K] < '0') Or (S[K] > '9') Then Exit;
  While (K <= Length(S)) And (S[K] >= '0') And (S[K] <= '9') Do
  Begin
    V := V * 10 + Ord(S[K]) - 48;
    Inc(K);
  End;
  NumAfter := V;
End;

Var
  CompErrs : LongInt;

{ ligne de sortie d'OS2PC -> fenetre Messages }
Procedure CompLine(S : String);
Var L, P, F, Fl : LongInt; T, W : String; Err : Boolean;
Begin
  Err := Pos('OS2PC: FATAL:', S) = 1;
  If Err Or (Pos('OS2PC: warning:', S) = 1) Or (Pos('OS2PC: avertissement', S) = 1) Then
  Begin
    P := Pos(':', S);
    T := Trim(Copy(S, P + 1, 255));
    P := Pos(':', T);
    T := Trim(Copy(T, P + 1, 255));
    L := -1;
    If Pos('ligne ', T) = 1 Then
    Begin
      L := NumAfter(T, 'ligne ');
      P := Pos(':', T);
      If P > 0 Then T := Trim(Copy(T, P + 1, 255));
    End;
    F := 0; Fl := -1;
    If (L >= 1) And (L <= GenN) And (L <= MaxGen) Then
    Begin
      F := GMapF^[L - 1]; Fl := GMapL^[L - 1];
    End;
    { identificateur non declare : erreur (variables declarees obligatoires) }
    If Pos('non declare', T) > 0 Then
    Begin
      Err := True;
      P := Pos('(variable implicite)', T);
      If P > 0 Then Delete(T, P, 21);
    End;
    If Err Then
    Begin
      Inc(CompErrs);
      W := 'Erreur';
    End
    Else W := 'Avertissement';
    If (F > 0) And (F <= NCtl) Then MsgAdd(W + ' : ' + CtName[F] + ', ligne ' + IStr(Fl + 1) + ' : ' + T, F, Fl)
    Else If L >= 1 Then MsgAdd(W + ' (programme g'#130'n'#130'r'#130', ligne ' + IStr(L) + ') : ' + T, -1, L - 1)
    Else MsgAdd(W + ' : ' + T, 0, -1);
  End
  Else If (Pos('OS2PC', S) = 1) And (Pos('OS2PC v', S) <> 1) Then
  Begin
    Inc(CompErrs);
    MsgAdd('Erreur : ' + Trim(S), 0, -1);
  End
  Else If Pos('Runtime error', S) > 0 Then
  Begin
    Inc(CompErrs);
    MsgAdd('Erreur interne du compilateur : ' + Trim(S), 0, -1);
  End;
End;

{ va a la ligne d'un message }
Procedure MsgGo(K : LongInt);
Var D, F : LongInt;
Begin
  If (K < 0) Or (K >= MsgN) Then Exit;
  MsgSel := K;
  F := MsgF[K];
  If (F > 0) And (F <= NCtl) And (MsgL[K] >= 0) Then
  Begin
    D := CtDoc[F];
    ShowCodeOf(F);
    DSel[D] := False;
    DCY[D] := MinI(MsgL[K], DN[D] - 1); DCX[D] := 0;
    DTop[D] := MaxI(0, DCY[D] - Rows Div 2);
    ScrollToCaret;
  End
  Else If (F = -1) And (MsgL[K] >= 0) And (GenDoc >= 0) Then
  Begin
    PropCommit;
    Cur := GenDoc; CodeView := True;
    Layout;
    DCY[GenDoc] := MinI(MsgL[K], DN[GenDoc] - 1); DCX[GenDoc] := 0;
    DTop[GenDoc] := MaxI(0, DCY[GenDoc] - Rows Div 2);
    SetTitle;
  End;
  Redraw;
End;

{ programme genere dans une fenetre de code en lecture seule }
Procedure ShowGenerated;
Begin
  PropCommit;
  GenProgram;
  FreeGen;
  GenDoc := DocNew(CodeName + '.PAS');
  If GenDoc < 0 Then
  Begin
    MsgErr('Trop de documents ouverts.');
    Exit;
  End;
  DocFromBytes(GenDoc, GenB.P, GenB.Len);
  DMod[GenDoc] := False; DUN[GenDoc] := 0;
  Cur := GenDoc;
  CodeView := True;
  Layout;
  SetTitle;
  Redraw;
End;

Procedure SetWait(On : Boolean);
Begin
  If On Then Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 3, 0))
  Else Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, 1, 0));
End;

{ lance OS2PC.EXE sur le programme genere ; Exe : executable a produire }
Procedure StartCompile(Exe : String; Run : Boolean);
Var Res : Array[0..1] Of LongInt; R : LongInt; Src : String;
Begin
  PropCommit;
  If CompBusy Or (RunPid <> 0) Then Exit;
  If Not FExists(CompilerPath) Then
  Begin
    MsgErr('Le compilateur OS2PC.EXE est introuvable (' + CompilerPath + ').');
    AutoQuit := False;
    Exit;
  End;
  If FirstForm = 0 Then
  Begin
    MsgErr('Le projet n''a aucune feuille.');
    Exit;
  End;
  GenProgram;
  Src := Copy(Exe, 1, Length(Exe) - Length(ExtOf(Exe))) + 'PAS';
  If Not WriteAll(Src, GenB.P, GenB.Len) Then
  Begin
    MsgErr('Impossible d'''#130'crire ' + Src + '.');
    AutoQuit := False;
    Exit;
  End;
  CompErr := JoinPath(DirOf(Src), 'VP.ERR');
  { fichier de la sortie du compilateur : descripteur de l'unite d'execution
    (SetStdHandle n'accepte que ceux-la) }
  Assign(CompEF, CompErr);
  {$I-} Rewrite(CompEF); {$I+}
  If IOResult <> 0 Then
  Begin
    MsgErr('Impossible de cr'#130'er ' + CompErr + '.');
    AutoQuit := False;
    Exit;
  End;
  If FExists(Exe) Then Dummy := DosDelete(Z(Exe));
  CompSrc := Src; LastExe := Exe; RunAfter := Run;
  MsgClear;
  MsgAdd('Compilation de ' + Src + ' -> ' + Exe + ' (' + IStr(GenN) + ' lignes)...', 0, -1);
  If Not ShowMsgs Then
  Begin
    ShowMsgs := True;
    SetCheck(cmShowMsgs, True);
    Layout;
  End;
  StatusMsg := 'Compilation par OS2PC...';
  Redraw;
  Dummy := WinUpdateWindow(Client);
  SetWait(True);
  SetArgs(CompilerPath, '-v -w -DOS2PM ' + Src + ' ' + Exe);
  CompH := PLong(@CompEF)^;
  Dummy := SetStdHandle(-11, CompH);
  Res[0] := 0; Res[1] := 0;
  CompT0 := PTicks;
  R := DosExecPgm(LongInt(@FailBuf), 64, 2, LongInt(@ArgBuf), 0, LongInt(@Res), Z(CompilerPath));
  Dummy := SetStdHandle(-11, 0);
  If R <> 0 Then
  Begin
    Close(CompEF);
    SetWait(False);
    MsgAdd('Erreur : impossible de lancer le compilateur (code ' + IStr(R) + ').', 0, -1);
    StatusMsg := 'Compilation impossible.';
    AutoQuit := False;
    Redraw;
    Exit;
  End;
  CompPid := Res[0];
  CompBusy := True;
  Dummy := WinStartTimer(Hab, Client, 7, 150);
  InvalBand(0, 0, CW, TbH);
End;

Procedure RunExe(Exe : String);
Var Res : Array[0..1] Of LongInt; R : LongInt;
Begin
  SetArgs(Exe, '');
  Res[0] := 0; Res[1] := 0;
  R := DosExecPgm(LongInt(@FailBuf), 64, 2, LongInt(@ArgBuf), 0, LongInt(@Res), Z(Exe));
  If R <> 0 Then
  Begin
    MsgAdd('Erreur : impossible de lancer ' + Exe + ' (code ' + IStr(R) + ').', 0, -1);
    Exit;
  End;
  RunPid := Res[0];
  MsgAdd('Ex'#130'cution de ' + NameOf(Exe) + '...', 0, -1);
  StatusMsg := 'Ex'#130'cution de ' + NameOf(Exe) + ' (Arr'#136'ter pour la terminer).';
  Dummy := WinStartTimer(Hab, Client, 8, 300);
  Redraw;
End;

Procedure CompileDone(Code : LongInt);
Var B : TBuf; H, R, St, E : LongInt; S : String; Ok : Boolean;
Begin
  Close(CompEF);
  SetWait(False);
  CompErrs := 0;
  BufInit(B);
  If FOpenRead(CompErr, H) Then
  Begin
    Repeat
      If Not BufGrow(B, 16384) Then Break;
      R := FRead(H, @B.P^[B.Len], 16384);
      If R > 0 Then B.Len := B.Len + R;
    Until R <= 0;
    DosClose(H);
  End;
  St := 0;
  For E := 0 To B.Len Do
    If (E = B.Len) Or (B.P^[E] = 10) Then
    Begin
      S := BufLine(B, St, E);
      If S <> '' Then CompLine(S);
      St := E + 1;
    End;
  BufFree(B);
  Dummy := DosDelete(Z(CompErr));
  If (Code <> 0) And (CompErrs = 0) Then
  Begin
    Inc(CompErrs);
    MsgAdd('Erreur : le compilateur s''est termin'#130' avec le code ' + IStr(Code) + '.', 0, -1);
  End;
  Ok := (CompErrs = 0) And FExists(LastExe);
  If Ok Then
  Begin
    MsgAdd('Compilation r'#130'ussie : ' + LastExe + ' (' + IStr((PTicks - CompT0) Div 100) + ' s environ).', 0, -1);
    StatusMsg := 'Compilation r'#130'ussie : ' + NameOf(LastExe);
    If RunAfter Then RunExe(LastExe);
  End
  Else
  Begin
    If CompErrs = 0 Then MsgAdd('Erreur : ' + LastExe + ' n''a pas '#130't'#130' produit.', 0, -1);
    StatusMsg := 'Compilation '#130'chou'#130'e : voir la fen'#136'tre Messages.';
    AutoQuit := False;
    For E := 0 To MsgN - 1 Do
      If (Pos('Erreur', MsgTx[E]) = 1) And (MsgF[E] > 0) Then
      Begin
        MsgGo(E);
        Break;
      End;
  End;
  WriteLog;
  If AutoQuit Then
  Begin
    If Not (AutoRun And Ok) Then Dummy := WinPostMsg(Client, WM_QUIT, 0, 0);
  End;
  Redraw;
End;

{ /LOG : la fenetre Messages copiee dans un fichier (essais automatiques) }
Procedure WriteLog;
Var B : TBuf; K : LongInt;
Begin
  If LogFile = '' Then Exit;
  BufInit(B);
  For K := 0 To MsgN - 1 Do
  Begin
    BufAdd(B, MsgTx[K]);
    BufAdd(B, #13#10);
  End;
  If WriteAll(LogFile, B.P, B.Len) Then ;
  BufFree(B);
End;

Procedure CompilePoll;
Var Res : Array[0..1] Of LongInt; Pid, R : LongInt;
Begin
  If Not CompBusy Then Exit;
  Res[0] := 0; Res[1] := 0; Pid := 0;
  R := DosWaitChild(0, 1, LongInt(@Res), LongInt(@Pid), CompPid);
  If R = 129 Then Exit;
  CompBusy := False;
  CompPid := 0;
  Dummy := WinStopTimer(Hab, Client, 7);
  If R <> 0 Then Res[1] := 0;
  CompileDone(Res[1]);
End;

Procedure RunPoll;
Var Res : Array[0..1] Of LongInt; Pid, R : LongInt;
Begin
  If RunPid = 0 Then Exit;
  Res[0] := 0; Res[1] := 0; Pid := 0;
  R := DosWaitChild(0, 1, LongInt(@Res), LongInt(@Pid), RunPid);
  If R = 129 Then Exit;
  RunPid := 0;
  Dummy := WinStopTimer(Hab, Client, 8);
  MsgAdd('Fin de l''ex'#130'cution.', 0, -1);
  StatusMsg := 'Pr'#136't.';
  Redraw;
End;

Procedure StopAll;
Begin
  If CompBusy Then
  Begin
    Dummy := DosKillProcess(1, CompPid);
    MsgAdd('Compilation interrompue.', 0, -1);
  End;
  If RunPid <> 0 Then
  Begin
    Dummy := DosKillProcess(1, RunPid);
    MsgAdd('Ex'#130'cution arr'#136't'#130'e.', 0, -1);
  End;
  Redraw;
End;

Function RunExeName : String;
Begin
  RunExeName := JoinPath(WorkDir, Copy(UpStr(CodeName), 1, 8) + '.EXE');
End;

Procedure MakeExeDlg;
Var N : String;
Begin
  DlgReset;
  N := JoinPath(WorkDir, Copy(UpStr(CodeName), 1, 8) + '.EXE');
  If PrjFile <> '' Then N := Copy(PrjFile, 1, Length(PrjFile) - Length(ExtOf(PrjFile))) + 'EXE';
  DlgField('Fichier ex'#130'cutable '#133' cr'#130'er :', N);
  If Not InputBox('Cr'#130'er l''EXE', 'Cr'#130'er') Then Exit;
  N := Trim(DgV[0]);
  If N = '' Then Exit;
  If (Length(N) < 2) Or (N[2] <> ':') Then N := JoinPath(WorkDir, N);
  If ExtOf(N) = '' Then N := N + '.EXE';
  StartCompile(N, False);
End;

{ ==================================================================== }
{ Edition des controles                                                 }
{ ==================================================================== }

Function Snap(V : LongInt) : LongInt;
Begin
  If V >= 0 Then Snap := ((V + GridSz Div 2) Div GridSz) * GridSz
  Else Snap := -(((-V + GridSz Div 2) Div GridSz) * GridSz);
End;

Procedure SwapCtl(A, B : LongInt);
Var T : LongInt; S : String; Bo : Boolean; J : LongInt;
Begin
  T := CtKind[A]; CtKind[A] := CtKind[B]; CtKind[B] := T;
  T := CtForm[A]; CtForm[A] := CtForm[B]; CtForm[B] := T;
  T := CtX[A]; CtX[A] := CtX[B]; CtX[B] := T;
  T := CtY[A]; CtY[A] := CtY[B]; CtY[B] := T;
  T := CtW[A]; CtW[A] := CtW[B]; CtW[B] := T;
  T := CtH[A]; CtH[A] := CtH[B]; CtH[B] := T;
  T := CtAlign[A]; CtAlign[A] := CtAlign[B]; CtAlign[B] := T;
  T := CtValue[A]; CtValue[A] := CtValue[B]; CtValue[B] := T;
  T := CtIntv[A]; CtIntv[A] := CtIntv[B]; CtIntv[B] := T;
  T := CtDoc[A]; CtDoc[A] := CtDoc[B]; CtDoc[B] := T;
  Bo := CtEn[A]; CtEn[A] := CtEn[B]; CtEn[B] := Bo;
  Bo := CtVis[A]; CtVis[A] := CtVis[B]; CtVis[B] := Bo;
  Bo := CtLocked[A]; CtLocked[A] := CtLocked[B]; CtLocked[B] := Bo;
  S := CtName[A]; CtName[A] := CtName[B]; CtName[B] := S;
  S := CtText[A]; CtText[A] := CtText[B]; CtText[B] := S;
  S := CtItems[A]; CtItems[A] := CtItems[B]; CtItems[B] := S;
  For J := 1 To NCtl Do
    If CtForm[J] = A Then CtForm[J] := B
    Else If CtForm[J] = B Then CtForm[J] := A;
  If Sel = A Then Sel := B Else If Sel = B Then Sel := A;
  If CurForm = A Then CurForm := B Else If CurForm = B Then CurForm := A;
End;

Procedure ZOrder(Front : Boolean);
Var C : LongInt;
Begin
  C := Sel;
  If (C <= 0) Or (CtKind[C] = vkForm) Then Exit;
  Snapshot;
  If Front Then
    While C < NCtl Do
    Begin
      SwapCtl(C, C + 1);
      Inc(C);
    End
  Else
    While (C > 1) And (C - 1 <> CtForm[C]) Do
    Begin
      SwapCtl(C - 1, C);
      Dec(C);
    End;
  Changed2;
End;

{ nouveau controle de sorte K dans la feuille courante (coordonnees de la feuille) }
Function CreateCtl(K, X, Y, W, H : LongInt) : LongInt;
Var C : LongInt;
Begin
  CreateCtl := 0;
  If CurForm <= 0 Then Exit;
  Snapshot;
  C := AddCtl(K, CurForm, X, Y, W, H);
  If C = 0 Then
  Begin
    MsgErr('Trop de contr'#147'les (' + IStr(MaxCtl) + ' au plus).');
    Exit;
  End;
  If K = vkTimer Then
  Begin
    CtW[C] := 28; CtH[C] := 28;
  End;
  SelectCtl(C);
  StatusMsg := CtName[C] + ' ajout'#130'. Double-cliquez-le pour '#130'crire le code de son '#130'v'#130'nement.';
  Changed2;
  CreateCtl := C;
End;

Procedure DeleteSel;
Var F : LongInt;
Begin
  If (Sel <= 0) Or (Sel > NCtl) Then Exit;
  If CtKind[Sel] = vkForm Then
  Begin
    StatusMsg := 'Pour supprimer la feuille : Projet - Supprimer la feuille.';
    InvalStatus;
    Exit;
  End;
  Snapshot;
  F := CtForm[Sel];
  DelCtl(Sel);
  If F > Sel Then Dec(F);
  CurForm := F;
  Sel := F;
  Changed2;
  InvalProj;
End;

Procedure CopyCtl;
Var P : LongInt;
Begin
  If (Sel <= 0) Or (CtKind[Sel] = vkForm) Then Exit;
  CbKind := CtKind[Sel];
  For P := 1 To NProps Do
    If PropHas(CbKind, P) Then CbProp[P] := PropGet(Sel, P) Else CbProp[P] := '';
  StatusMsg := CtName[Sel] + ' copi'#130'.';
  InvalStatus;
End;

Procedure PasteCtl;
Var C, P : LongInt; E : String;
Begin
  If (CbKind = 0) Or (CurForm <= 0) Then Exit;
  C := CreateCtl(CbKind, 0, 0, 0, 0);
  If C = 0 Then Exit;
  For P := 2 To NProps Do
    If PropHas(CbKind, P) Then E := PropSet(C, P, CbProp[P]);
  CtX[C] := CtX[C] + GridSz; CtY[C] := CtY[C] + GridSz;
  If (CbKind = vkLabel) Or (CbKind = vkButton) Or (CbKind = vkFrame) Or (CbKind = vkCheck) Or (CbKind = vkOption) Then
    If FindCtl(CbProp[ppCaption]) > 0 Then CtText[C] := CtName[C];
  If CbKind = vkTimer Then
  Begin
    CtW[C] := 28; CtH[C] := 28;
  End;
  CbProp[ppLeft] := IStr(CtX[C]); CbProp[ppTop] := IStr(CtY[C]);
  Changed2;
End;

Procedure AddFormCmd;
Var F : LongInt;
Begin
  PropCommit;
  Snapshot;
  F := NewForm;
  If F = 0 Then
  Begin
    MsgErr('Trop de feuilles.');
    Exit;
  End;
  CodeView := False;
  SelectCtl(F);
  Layout;
  Changed2;
  Redraw;
End;

Procedure DelFormCmd;
Var F : LongInt;
Begin
  F := CurForm;
  If F <= 0 Then Exit;
  If FormCount <= 1 Then
  Begin
    MsgErr('Le projet doit garder au moins une feuille.');
    Exit;
  End;
  If Not AskYes('Supprimer la feuille ' + CtName[F] + ', ses contr'#147'les et son code ?') Then Exit;
  PropKill;
  SnapClear;
  If Cur = CtDoc[F] Then Cur := -1;
  DelCtl(F);
  CurForm := FirstForm;
  Sel := CurForm;
  CodeView := False;
  Layout;
  Changed2;
  Redraw;
End;

Procedure PrjPropsDlg;
Var S : String;
Begin
  DlgReset;
  DlgField('Nom du projet (nom du programme Pascal g'#130'n'#130'r'#130') :', PrjName);
  If Not InputBox('Propri'#130't'#130's du projet', 'OK') Then Exit;
  S := Trim(DgV[0]);
  If Not IsIdent(S) Then
  Begin
    MsgErr('Le nom du projet doit '#136'tre un identificateur Pascal (lettres, chiffres, _).');
    Exit;
  End;
  PrjName := S;
  PrjMod := True;
  SetTitle;
  Redraw;
End;

Procedure FindDlg;
Begin
  If Not CodeView Then Exit;
  DlgReset;
  DlgField('Rechercher :', FindS);
  If Not InputBox('Rechercher', 'Rechercher') Then Exit;
  FindS := DgV[0];
  FindNext;
End;

Procedure ShowHelp(Which : LongInt);
Var B : TBuf;
Begin
  BufInit(B);
  If Which = 0 Then
  Begin
    BufAdd(B, 'Visual Pascal : on dessine des feuilles et on '#130'crit le code de leurs '#130'v'#130'nements en Pascal.'#10#10);
    BufAdd(B, '1. Choisissez un contr'#147'le dans la bo'#140'te '#133' outils (a gauche) et tracez-le sur la feuille ');
    BufAdd(B, '(ou double-cliquez l''outil).'#10);
    BufAdd(B, '2. Changez ses propri'#130't'#130's dans la fen'#136'tre Propri'#130't'#130's (a droite) : cliquez la valeur ');
    BufAdd(B, 'et tapez, Entr'#130'e pour valider ; double clic sur une valeur a choix pour passer a la suivante.'#10);
    BufAdd(B, '3. Double-cliquez un contr'#147'le : Visual Pascal cr'#130'e la proc'#130'dure de son '#130'v'#130'nement ');
    BufAdd(B, '(Command1_Click, Text1_Change, Form1_Load, Timer1_Timer...).'#10);
    BufAdd(B, '4. F5 : Visual Pascal g'#130'n'#130're le programme Pascal, le compile avec OS2PC.EXE et l''ex'#130'cute. ');
    BufAdd(B, 'Les erreurs s''affichent dans la fen'#136'tre Messages : un clic va a la ligne.'#10#10);
    BufAdd(B, 'Grille de 8 pixels ; fl'#138'ches : d'#130'placer, Maj+fl'#138'ches : redimensionner ; Suppr : supprimer.'#10);
    BufAdd(B, 'Les boutons d''option d''un m'#136'me cadre (Frame) forment un groupe.'#10);
    BufAdd(B, 'Fichier - Exemples : Calculatrice, D'#130'monstration.');
    ShowBuf('Aide de Visual Pascal', B);
  End
  Else
  Begin
    BufAdd(B, 'Propri'#130't'#130's (lecture et '#130'criture) : Caption, Text, Left, Top, Width, Height, Visible, ');
    BufAdd(B, 'Enabled, Value (0 ou 1), ListIndex, Interval.'#10);
    BufAdd(B, 'Lecture seule : ListCount, List(i).'#10);
    BufAdd(B, 'M'#130'thodes : AddItem(texte), RemoveItem(i), Clear, SetFocus, Show, Hide (feuilles).'#10#10);
    BufAdd(B, 'Exemples : Text1.Text := Text1.Text + ''7''; List1.AddItem(''Ligne''); Form2.Show; ');
    BufAdd(B, 'If Check1.Value = 1 Then Label1.Caption := ''Oui''; Me.Caption := ''Titre'';'#10#10);
    BufAdd(B, 'Fonctions : MsgBox(texte), MsgBoxOuiNon(texte) : Boolean, Quitter, IntToStr, StrToInt, ');
    BufAdd(B, 'StrToFloat, FloatToStr, Heure, DateDuJour.'#10#10);
    BufAdd(B, 'Ev'#130'nements : Form : Load, Unload ; CommandButton, CheckBox, OptionButton : Click ; ');
    BufAdd(B, 'TextBox : Change ; ListBox, ComboBox : Click, DblClick ; Timer : Timer.'#10#10);
    BufAdd(B, 'Le code est du Pascal (Var, Procedure, Function...). Visual Pascal r'#130#130'crit les acc'#138's ');
    BufAdd(B, 'aux contr'#147'les en appels de sa biblioth'#138'que (Affichage - Programme g'#130'n'#130'r'#130').');
    ShowBuf('Propri'#130't'#130's et m'#130'thodes', B);
  End;
  BufFree(B);
End;

{ ==================================================================== }
{ Souris                                                                }
{ ==================================================================== }

{ controle sous (X, Y) dans la feuille courante (0 : aucun ; CurForm : la feuille) }
Function HitCtl(X, Y : LongInt) : LongInt;
Var C, W, H, Pass : LongInt;
Begin
  HitCtl := 0;
  If CurForm <= 0 Then Exit;
  For Pass := 0 To 1 Do
    For C := NCtl DownTo 1 Do
      If (CtForm[C] = CurForm) And (C <> CurForm) And ((CtKind[C] = vkFrame) = (Pass = 1)) Then
      Begin
        W := CtW[C]; H := CtH[C];
        If CtKind[C] = vkTimer Then
        Begin
          W := 28; H := 28;
        End;
        If (X >= SXc(C)) And (X < SXc(C) + W) And (Y >= SYc(C)) And (Y < SYc(C) + H) Then
        Begin
          HitCtl := C;
          Exit;
        End;
      End;
  If (X >= FX) And (X < FX + CtW[CurForm] + 2 * BrdW) And (Y >= FY) And (Y < FY + CtH[CurForm] + 2 * BrdW + TitH) Then
    HitCtl := CurForm;
End;

{ poignee de la selection sous (X, Y) : 1..8 (HG, H, HD, G, D, BG, B, BD) ; 0 : aucune }
Function HitHandle(X, Y : LongInt) : LongInt;
Var X1, Y1_, X2, Y2, K, Hx, Hy : LongInt;
Begin
  HitHandle := 0;
  If (Sel <= 0) Or (Sel > NCtl) Or (CtForm[Sel] <> CurForm) Then Exit;
  If Sel = CurForm Then
  Begin
    X1 := FCX; Y1_ := FCY; X2 := FCX + CtW[Sel] + 2; Y2 := FCY + CtH[Sel] + 2;
  End
  Else
  Begin
    If CtKind[Sel] = vkTimer Then Exit;
    X1 := SXc(Sel) - 1; Y1_ := SYc(Sel) - 1; X2 := SXc(Sel) + CtW[Sel]; Y2 := SYc(Sel) + CtH[Sel];
  End;
  For K := 1 To 8 Do
  Begin
    Case K Of
      1, 4, 6 : Hx := X1;
      2, 7 : Hx := (X1 + X2) Div 2;
    Else
      Hx := X2;
    End;
    Case K Of
      1, 2, 3 : Hy := Y1_;
      4, 5 : Hy := (Y1_ + Y2) Div 2;
    Else
      Hy := Y2;
    End;
    If (Sel = CurForm) And Not ((K = 5) Or (K = 7) Or (K = 8)) Then Continue;
    If (Abs(X - Hx) <= 4) And (Abs(Y - Hy) <= 4) Then
    Begin
      HitHandle := K;
      Exit;
    End;
  End;
End;

Procedure ToolboxClick(X, Y : LongInt; Dbl : Boolean);
Var K, W, H : LongInt;
Begin
  If (Y < Y0 + HdrH + 4) Or (X < 4) Or (X > 56) Then Exit;
  K := ((Y - Y0 - HdrH - 4) Div 26) * 2 + (X - 4) Div 26;
  If (K < 0) Or (K >= NKinds) Then Exit;
  If K = 0 Then Tool := 0 Else Tool := K + 1;
  If Dbl And (Tool > 0) And (CurForm > 0) Then
  Begin
    DefSize(Tool, W, H);
    If CreateCtl(Tool, Snap(MaxI(0, (CtW[CurForm] - W) Div 2)), Snap(MaxI(0, (CtH[CurForm] - H) Div 2)), W, H) > 0 Then ;
    Tool := 0;
  End;
  If CodeView And (Tool > 0) Then ShowDesign;
  StatusMsg := KindTip(Tool);
  InvalBand(0, Y0, TbxW, Y1 + 1);
  InvalStatus;
End;

Procedure DesignDown(X, Y : LongInt; Dbl : Boolean);
Var C, Hd : LongInt;
Begin
  If CurForm <= 0 Then Exit;
  If Tool > 0 Then
  Begin
    If (X >= FCX) And (X < FCX + CtW[CurForm]) And (Y >= FCY) And (Y < FCY + CtH[CurForm]) Then
    Begin
      Drag := dCreate;
      RubX1 := FCX + Snap(X - FCX); RubY1 := FCY + Snap(Y - FCY);
      RubX2 := RubX1; RubY2 := RubY1;
      RubOn := True;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
    End;
    Exit;
  End;
  Hd := HitHandle(X, Y);
  If (Hd > 0) And Not Dbl Then
  Begin
    Snapshot;
    Drag := dSize; DragHd := Hd; DragC := Sel; DragX0 := X; DragY0 := Y;
    DragR[0] := CtX[Sel]; DragR[1] := CtY[Sel]; DragR[2] := CtW[Sel]; DragR[3] := CtH[Sel];
    Dummy := WinSetCapture(HWND_DESKTOP, Client);
    Exit;
  End;
  C := HitCtl(X, Y);
  If C = 0 Then Exit;
  If Dbl Then
  Begin
    CodeFor(C);
    Exit;
  End;
  SelectCtl(C);
  If C <> CurForm Then
  Begin
    Drag := dMoveWait; DragC := C; DragX0 := X; DragY0 := Y;
    DragR[0] := CtX[C]; DragR[1] := CtY[C];
    Dummy := WinSetCapture(HWND_DESKTOP, Client);
  End;
End;

Procedure DesignMove(X, Y : LongInt);
Var C, Dx, Dy, Nx, Ny, Nw, Nh : LongInt;
Begin
  C := DragC;
  Case Drag Of
    dCreate :
      Begin
        RubX2 := FCX + Snap(MinI(MaxI(X, FCX), FCX + CtW[CurForm]) - FCX);
        RubY2 := FCY + Snap(MinI(MaxI(Y, FCY), FCY + CtH[CurForm]) - FCY);
        InvalWork;
      End;
    dMoveWait :
      If (Abs(X - DragX0) > 3) Or (Abs(Y - DragY0) > 3) Then
      Begin
        Snapshot;
        Drag := dMove;
      End;
    dMove :
      Begin
        Nx := Snap(DragR[0] + X - DragX0); Ny := Snap(DragR[1] + Y - DragY0);
        If (Nx <> CtX[C]) Or (Ny <> CtY[C]) Then
        Begin
          CtX[C] := Nx; CtY[C] := Ny;
          PrjMod := True;
          InvalWork;
          InvalStatus;
        End;
      End;
    dSize :
      Begin
        Dx := X - DragX0; Dy := Y - DragY0;
        Nx := DragR[0]; Ny := DragR[1]; Nw := DragR[2]; Nh := DragR[3];
        If DragHd In [1, 4, 6] Then
        Begin
          Nx := Snap(DragR[0] + Dx);
          Nw := DragR[0] + DragR[2] - Nx;
        End;
        If DragHd In [3, 5, 8] Then Nw := Snap(DragR[0] + DragR[2] + Dx) - DragR[0];
        If DragHd In [1, 2, 3] Then
        Begin
          Ny := Snap(DragR[1] + Dy);
          Nh := DragR[1] + DragR[3] - Ny;
        End;
        If DragHd In [6, 7, 8] Then Nh := Snap(DragR[1] + DragR[3] + Dy) - DragR[1];
        If C = CurForm Then
        Begin
          Nw := Snap(DragR[2] + Dx); Nh := Snap(DragR[3] + Dy);
          If DragHd = 5 Then Nh := DragR[3];
          If DragHd = 7 Then Nw := DragR[2];
          Nx := 0; Ny := 0;
          If Nw < 80 Then Nw := 80;
          If Nh < 40 Then Nh := 40;
        End;
        If Nw < GridSz Then Nw := GridSz;
        If Nh < GridSz Then Nh := GridSz;
        If (Nx <> CtX[C]) Or (Ny <> CtY[C]) Or (Nw <> CtW[C]) Or (Nh <> CtH[C]) Then
        Begin
          CtX[C] := Nx; CtY[C] := Ny; CtW[C] := Nw; CtH[C] := Nh;
          PrjMod := True;
          InvalWork;
          InvalProps;
          InvalStatus;
        End;
      End;
  End;
End;

Procedure DesignUp(X, Y : LongInt);
Var X1, Y1_, W, H, K : LongInt;
Begin
  Dummy := WinSetCapture(HWND_DESKTOP, 0);
  If Drag = dCreate Then
  Begin
    RubOn := False;
    X1 := MinI(RubX1, RubX2) - FCX; Y1_ := MinI(RubY1, RubY2) - FCY;
    W := Abs(RubX2 - RubX1); H := Abs(RubY2 - RubY1);
    K := Tool;
    If (W < GridSz) Or (H < GridSz) Then DefSize(K, W, H);
    Tool := 0;
    If CreateCtl(K, X1, Y1_, W, H) > 0 Then ;
    InvalBand(0, Y0, TbxW, Y1 + 1);
  End
  Else If (Drag = dMove) Or (Drag = dSize) Then
  Begin
    SetTitle;
    InvalProps;
  End;
  Drag := dNone;
  InvalWork;
End;

{ clic dans la fenetre des proprietes }
Procedure PropsDown(X, Y : LongInt; Dbl : Boolean);
Var I : LongInt;
Begin
  If (Y >= PrY0 + HdrH) And (Y < PgY0) Then
  Begin
    PropCommit;
    ObjPopup(RpX + 4, PgY0, 2);
    Exit;
  End;
  If (Y < PgY0) Or (Y >= PgY1) Or (Sel <= 0) Then Exit;
  BuildPropList;
  I := PropTop + (Y - PgY0) Div PrRowH;
  If (I < 0) Or (I >= NPropL) Then Exit;
  If PropChoices(CtKind[Sel], PropList[I]) > 0 Then
  Begin
    PropCommit;
    PropRow := I;
    InvalProps;
    If Dbl Then PropCycle(I)
    Else If X >= PropColX Then PropChoicePopup(I, PropColX, PgY0 + (I - PropTop + 1) * PrRowH);
    Exit;
  End;
  If (X >= PropColX) Or Dbl Then PropEdit(I)
  Else
  Begin
    PropCommit;
    PropRow := I;
    InvalProps;
  End;
End;

Procedure ProjDown(X, Y : LongInt; Dbl : Boolean);
Var K, R, N : LongInt;
Begin
  R := (Y - (Y0 + HdrH + 4 + 18)) Div 18;
  If (Y < Y0 + HdrH + 4 + 18) Then Exit;
  N := 0;
  For K := 1 To NCtl Do
    If CtKind[K] = vkForm Then
    Begin
      If N = R Then
      Begin
        If CodeView And Not Dbl Then ShowCodeOf(K)
        Else
        Begin
          CodeView := False;
          Layout;
          SelectCtl(K);
          SetTitle;
          Redraw;
        End;
        Exit;
      End;
      Inc(N);
    End;
End;

Procedure CodeDown(X, Y : LongInt; Dbl, Shift : Boolean);
Var D, Ya, Xa, Xb, Xc, T, Th, Ty : LongInt;
Begin
  D := Cur;
  If D < 0 Then Exit;
  If Y < EdTop Then
  Begin
    If D = GenDoc Then Exit;
    CodeCombos(Xa, Xb, Xc);
    If (X >= Xa) And (X <= Xb) Then ObjPopup(Xa, WY0 + CbH - 4, 1)
    Else If X >= Xc Then ProcPopup(Xc, WY0 + CbH - 4);
    Exit;
  End;
  If X >= VsX Then
  Begin
    { barre de defilement verticale }
    If Y < EdTop + ScrW Then DTop[D] := MaxI(0, DTop[D] - 1)
    Else If Y >= HsY - ScrW Then DTop[D] := MinI(MaxTop, DTop[D] + 1)
    Else
    Begin
      T := HsY - EdTop - 2 * ScrW;
      Th := MaxI(10, T * Rows Div (MaxTop + Rows));
      Ty := EdTop + ScrW + (T - Th) * DTop[D] Div MaxI(1, MaxTop);
      If Y < Ty Then DTop[D] := MaxI(0, DTop[D] - Rows + 1)
      Else If Y >= Ty + Th Then DTop[D] := MinI(MaxTop, DTop[D] + Rows - 1)
      Else
      Begin
        Drag := dVThumb; DragY0 := Y; DragR[0] := DTop[D];
        Dummy := WinSetCapture(HWND_DESKTOP, Client);
      End;
    End;
    InvalEditor;
    Exit;
  End;
  If Y >= HsY Then
  Begin
    If X < EdX0 + ScrW Then DLeft[D] := MaxI(0, DLeft[D] - 4)
    Else If X >= VsX - ScrW Then DLeft[D] := MinI(HMax, DLeft[D] + 4)
    Else If X < EdX0 + (VsX - EdX0) Div 2 Then DLeft[D] := MaxI(0, DLeft[D] - Cols Div 2)
    Else DLeft[D] := MinI(HMax, DLeft[D] + Cols Div 2);
    InvalEditor;
    Exit;
  End;
  HitText(X, Y, Ya, Xa);
  If Shift Then
  Begin
    If Not DSel[D] Then
    Begin
      DSel[D] := True; DAX[D] := DCX[D]; DAY[D] := DCY[D];
    End;
  End
  Else
  Begin
    DSel[D] := True; DAX[D] := Xa; DAY[D] := Ya;
  End;
  DCY[D] := Ya; DCX[D] := Xa; DWant[D] := -1;
  DLastKind[D] := 0;
  If Dbl Then SelectWord
  Else
  Begin
    Drag := dTxSel;
    Dummy := WinSetCapture(HWND_DESKTOP, Client);
  End;
  CaretOn := True;
  Changed;
  InvalBand(WX0, WY0, WX1 + 1, EdTop);
End;

Procedure CodeMove(X, Y : LongInt);
Var D, Ya, Xa, T, Th : LongInt;
Begin
  D := Cur;
  If D < 0 Then Exit;
  If Drag = dTxSel Then
  Begin
    HitText(X, Y, Ya, Xa);
    If (Ya <> DCY[D]) Or (Xa <> DCX[D]) Then
    Begin
      DCY[D] := Ya; DCX[D] := Xa;
      Changed;
    End;
  End
  Else If Drag = dVThumb Then
  Begin
    T := HsY - EdTop - 2 * ScrW;
    Th := MaxI(10, T * Rows Div (MaxTop + Rows));
    If T - Th > 0 Then
    Begin
      DTop[D] := MinI(MaxTop, MaxI(0, DragR[0] + (Y - DragY0) * MaxTop Div (T - Th)));
      InvalEditor;
    End;
  End;
End;

Procedure MsgsDown(X, Y : LongInt; Dbl : Boolean);
Var K : LongInt;
Begin
  If Y < MsY0 + HdrH Then
  Begin
    If X >= WX1 - 24 Then
    Begin
      ShowMsgs := False;
      SetCheck(cmShowMsgs, False);
      Layout;
      Redraw;
    End;
    Exit;
  End;
  K := MsgTop + (Y - MsY0 - HdrH - 2) Div 16;
  If (K >= 0) And (K < MsgN) Then MsgGo(K);
End;

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

Procedure DoCmd(C : LongInt); Forward;

Procedure MouseDown(X, Y : LongInt; Dbl, Shift : Boolean);
Begin
  If Y < TbH Then
  Begin
    ToolbarDown(X);
    Exit;
  End;
  If (Y >= CH - SbH) Then Exit;
  If ShowTbx And (X < TbxW) Then
  Begin
    PropCommit;
    ToolboxClick(X, Y, Dbl);
    Exit;
  End;
  If X >= RpX Then
  Begin
    If ShowProj And (Y < PrY0) Then
    Begin
      PropCommit;
      ProjDown(X, Y, Dbl);
    End
    Else If ShowProps Then PropsDown(X, Y, Dbl);
    Exit;
  End;
  PropCommit;
  If ShowMsgs And (Y >= MsY0) Then
  Begin
    MsgsDown(X, Y, Dbl);
    Exit;
  End;
  If CodeView Then CodeDown(X, Y, Dbl, Shift) Else DesignDown(X, Y, Dbl);
End;

Procedure MouseMove(X, Y : LongInt);
Var I, H : LongInt;
Begin
  If Drag = dTool Then Exit;
  If (Drag = dTxSel) Or (Drag = dVThumb) Then
  Begin
    CodeMove(X, Y);
    Exit;
  End;
  If Drag <> dNone Then
  Begin
    DesignMove(X, Y);
    Exit;
  End;
  { survol de la barre d'outils : bulle dans la barre d'etat }
  H := -1;
  If Y < TbH Then
    For I := 0 To NTb - 1 Do
      If (TbCmd[I] <> 0) And (X >= TbX[I]) And (X < TbX[I] + TbW[I]) Then H := I;
  If H <> TbHot Then
  Begin
    { bulle dans la barre d'etat ; le message precedent revient ensuite }
    If TbHot < 0 Then SavedMsg := StatusMsg;
    TbHot := H;
    If H >= 0 Then StatusMsg := TbTip[H] Else StatusMsg := SavedMsg;
    InvalStatus;
    InvalBand(0, 0, CW, TbH);
  End;
End;

Procedure MouseUp(X, Y : LongInt);
Var I, C : LongInt;
Begin
  If Drag = dTool Then
  Begin
    Dummy := WinSetCapture(HWND_DESKTOP, 0);
    Drag := dNone;
    I := TbDown;
    TbDown := -1;
    InvalBand(0, 0, CW, TbH);
    If (I >= 0) And (Y < TbH) And (X >= TbX[I]) And (X < TbX[I] + TbW[I]) Then
    Begin
      C := TbCmd[I];
      DoCmd(C);
    End;
    Exit;
  End;
  If (Drag = dTxSel) Or (Drag = dVThumb) Then
  Begin
    Dummy := WinSetCapture(HWND_DESKTOP, 0);
    Drag := dNone;
    Exit;
  End;
  If Drag <> dNone Then DesignUp(X, Y)
  Else Drag := dNone;
End;

Procedure RightClick(X, Y : LongInt);
Var C, H : LongInt;
Begin
  PropCommit;
  If (X >= RpX) And ShowProj And (Y < PrY0) Then
  Begin
    MenuLen := 0;
    H := MenuOpen;
    It(cmObject, 'Afficher l''~objet');
    It(cmCode, 'Afficher le ~code');
    Sep;
    It(cmAddForm, '~Ajouter une feuille');
    It(cmDelForm, '~Supprimer la feuille');
    Sep;
    It(cmPrjProps, '~Propri'#130't'#130's du projet...');
    MenuClose(H);
    ShowPopup(X, Y);
    Exit;
  End;
  If (X < WX0) Or (X > WX1) Or (Y < WY0) Or (Y > WY1) Then Exit;
  MenuLen := 0;
  H := MenuOpen;
  If CodeView Then
  Begin
    It(cmCut, '~Couper' + #9 + 'Ctrl+X');
    It(cmCopy, 'C~opier' + #9 + 'Ctrl+C');
    It(cmPaste, 'Co~ller' + #9 + 'Ctrl+V');
    Sep;
    It(cmObject, 'Afficher l''~objet' + #9 + 'Maj+F7');
  End
  Else
  Begin
    C := HitCtl(X, Y);
    If C > 0 Then SelectCtl(C);
    It(cmCode, 'Afficher le ~code' + #9 + 'F7');
    Sep;
    It(cmCut, '~Couper' + #9 + 'Ctrl+X');
    It(cmCopy, 'C~opier' + #9 + 'Ctrl+C');
    It(cmPaste, 'Co~ller' + #9 + 'Ctrl+V');
    It(cmDelete, '~Supprimer' + #9 + 'Suppr');
    Sep;
    It(cmToFront, 'Mettre au ~premier plan');
    It(cmToBack, 'Mettre '#133' l''~arri'#138're-plan');
    It(cmSnap, 'Aligner sur la ~grille');
    Sep;
    It(cmShowProps, 'Pr~opri'#130't'#130's' + #9 + 'F4');
  End;
  MenuClose(H);
  ShowPopup(X, Y);
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Procedure DoCmd(C : LongInt);
Var K, V : LongInt; E : String;
Begin
  { valeurs des listes deroulantes }
  If (C >= cmChoice) And (C < cmChoice + 10) Then
  Begin
    If Sel > 0 Then
    Begin
      Snapshot;
      E := PropSet(Sel, PropEfP, PropChoice(CtKind[Sel], PropEfP, C - cmChoice));
      Changed2;
    End;
    Exit;
  End;
  If (C >= cmObjFirst) And (C <= cmObjFirst + MaxCtl) Then
  Begin
    K := C - cmObjFirst;
    If PopObjFor = 2 Then
    Begin
      If K > 0 Then SelectCtl(K);
    End
    Else If K = 0 Then
    Begin
      If Cur >= 0 Then
      Begin
        DSel[Cur] := False; DCY[Cur] := 0; DCX[Cur] := 0; DTop[Cur] := 0;
        Changed;
      End;
    End
    Else
    Begin
      Sel := K;
      If EvCount(CtKind[K]) > 0 Then GotoHandler(K, EvName(CtKind[K], 1));
      ShowCodeOf(CtForm[K]);
    End;
    Exit;
  End;
  If (C > cmEvFirst) And (C < cmEvFirst + 10) Then
  Begin
    K := PopObjFor;
    If (K > 0) And (K <= NCtl) Then
    Begin
      GotoHandler(K, EvName(CtKind[K], C - cmEvFirst));
      ShowCodeOf(CtForm[K]);
    End;
    Exit;
  End;
  If (C >= cmProcFirst) And (C <= cmProcFirst + MaxPopL) Then
  Begin
    If Cur < 0 Then Exit;
    K := C - cmProcFirst;
    If K = MaxPopL Then V := 0 Else V := PopLine[K];
    DSel[Cur] := False; DCY[Cur] := MinI(V, DN[Cur] - 1); DCX[Cur] := 0;
    DTop[Cur] := MaxI(0, DCY[Cur] - 2);
    Changed;
    Exit;
  End;
  Case C Of
    cmNew : If CanDiscard Then NewProject;
    cmOpen : OpenDlg;
    cmSave : If SaveCur Then ;
    cmSaveAs : If SaveAsDlg Then ;
    cmSampleCalc, cmSampleDemo : If CanDiscard Then LoadSample(C - cmSampleCalc + 1);
    cmQuit : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    cmMakeExe : MakeExeDlg;
    cmUndo :
      If CodeView Then
      Begin
        If Not DocRO Then
        Begin
          UndoRedo(Cur, False);
          ClampCaret;
          Changed;
        End;
      End
      Else DesignUndo;
    cmRedo :
      If CodeView And Not DocRO Then
      Begin
        UndoRedo(Cur, True);
        ClampCaret;
        Changed;
      End;
    cmCut : If CodeView Then CutSel Else Begin CopyCtl; DeleteSel; End;
    cmCopy : If CodeView Then CopySel Else CopyCtl;
    cmPaste : If CodeView Then PasteClip Else PasteCtl;
    cmDelete : If CodeView Then DeleteKey Else DeleteSel;
    cmSelAll : If CodeView Then SelectAll;
    cmFind : FindDlg;
    cmFindNext : If CodeView Then FindNext;
    cmCode :
      If Not CodeView Or (Cur = GenDoc) Then
      Begin
        If (Sel > 0) And (Sel <> CurForm) And (CodeView = False) Then CodeFor(Sel)
        Else If CurForm > 0 Then ShowCodeOf(CurForm);
      End;
    cmObject : ShowDesign;
    cmShowProj, cmShowProps, cmShowTbx, cmShowMsgs, cmNums :
      Begin
        PropCommit;
        Case C Of
          cmShowProj : ShowProj := Not ShowProj;
          cmShowProps : ShowProps := Not ShowProps;
          cmShowTbx : ShowTbx := Not ShowTbx;
          cmShowMsgs : ShowMsgs := Not ShowMsgs;
          cmNums : ShowNums := Not ShowNums;
        End;
        SetCheck(cmShowProj, ShowProj); SetCheck(cmShowProps, ShowProps); SetCheck(cmShowTbx, ShowTbx);
        SetCheck(cmShowMsgs, ShowMsgs); SetCheck(cmNums, ShowNums);
        Layout;
        Redraw;
      End;
    cmShowGen : ShowGenerated;
    cmAddForm : AddFormCmd;
    cmDelForm : DelFormCmd;
    cmPrjProps : PrjPropsDlg;
    cmSnap, cmCenterH, cmCenterV :
      If (Sel > 0) And (Sel <> CurForm) Then
      Begin
        Snapshot;
        If C = cmSnap Then
        Begin
          CtX[Sel] := Snap(CtX[Sel]); CtY[Sel] := Snap(CtY[Sel]);
          CtW[Sel] := MaxI(GridSz, Snap(CtW[Sel])); CtH[Sel] := MaxI(GridSz, Snap(CtH[Sel]));
        End
        Else If C = cmCenterH Then CtX[Sel] := (CtW[CurForm] - CtW[Sel]) Div 2
        Else CtY[Sel] := (CtH[CurForm] - CtH[Sel]) Div 2;
        Changed2;
      End;
    cmToFront : ZOrder(True);
    cmToBack : ZOrder(False);
    cmRun :
      If RunPid = 0 Then StartCompile(RunExeName, True);
    cmCompile : StartCompile(RunExeName, False);
    cmStop : StopAll;
    cmHelp : ShowHelp(0);
    cmLang : ShowHelp(1);
    cmAbout :
      Msg('Visual Pascal pour OS/2-0' + #10#10 + 'Environnement visuel dans l''esprit de Visual Basic 6 : feuilles, ' +
          'contr'#147'les, propri'#130't'#130's et '#130'v'#130'nements, programm'#130's en Pascal et compil'#130's par OS2PC.' +
          #10#10 + 'Gladir.com');
  End;
  InvalBand(0, 0, CW, TbH);
End;

{ ==================================================================== }
{ Clavier                                                               }
{ ==================================================================== }

Procedure NudgeSel(Dx, Dy : LongInt; Size : Boolean);
Begin
  If (Sel <= 0) Or (Sel > NCtl) Then Exit;
  If (Sel = CurForm) And Not Size Then Exit;
  Snapshot;
  If Size Then
  Begin
    CtW[Sel] := MaxI(GridSz, CtW[Sel] + Dx);
    CtH[Sel] := MaxI(GridSz, CtH[Sel] + Dy);
  End
  Else
  Begin
    CtX[Sel] := CtX[Sel] + Dx;
    CtY[Sel] := CtY[Sel] + Dy;
  End;
  Changed2;
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
  { saisie d'une propriete }
  If (PropEf <> 0) And (WinQueryFocus(HWND_DESKTOP) = PropEf) And ((Fl And KC_VIRTUALKEY) <> 0) Then
  Begin
    Case Vk Of
      VK_ENTER, VK_NEWLINE :
        Begin
          PropCommit;
          Dummy := WinSetFocus(HWND_DESKTOP, Client);
          Exit;
        End;
      VK_ESC :
        Begin
          PropCancel;
          Exit;
        End;
      VK_UP, VK_DOWN, VK_TAB, VK_BACKTAB :
        Begin
          K := PropRow;
          If (Vk = VK_UP) Or (Vk = VK_BACKTAB) Then Dec(K) Else Inc(K);
          PropCommit;
          BuildPropList;
          If (K >= 0) And (K < NPropL) Then
          Begin
            If PropChoices(CtKind[Sel], PropList[K]) > 0 Then
            Begin
              PropRow := K;
              Dummy := WinSetFocus(HWND_DESKTOP, Client);
              InvalProps;
            End
            Else PropEdit(K);
          End
          Else Dummy := WinSetFocus(HWND_DESKTOP, Client);
          Exit;
        End;
    End;
    Key := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    Case Vk Of
      VK_F1 : Begin DoCmd(cmHelp); Exit; End;
      VK_F3 : Begin DoCmd(cmFindNext); Exit; End;
      VK_F5 :
        Begin
          If Ctrl Then DoCmd(cmCompile) Else DoCmd(cmRun);
          Exit;
        End;
      VK_F6 :
        Begin
          { F4 et F7 sont pris par PM sur certains claviers : F6 bascule code / objet }
          If CodeView Then DoCmd(cmObject) Else DoCmd(cmCode);
          Exit;
        End;
    End;
    If Vk = $23 Then
    Begin
      { F4 }
      If Not ShowProps Then DoCmd(cmShowProps);
      If (Sel > 0) Then PropEdit(PropRow);
      Exit;
    End;
    If Vk = $26 Then
    Begin
      { F7 / Maj+F7 }
      If Shift Then DoCmd(cmObject) Else DoCmd(cmCode);
      Exit;
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
      Ord('z') : Begin DoCmd(cmUndo); Exit; End;
      Ord('y') : Begin DoCmd(cmRedo); Exit; End;
      Ord('x') : Begin DoCmd(cmCut); Exit; End;
      Ord('c') : Begin DoCmd(cmCopy); Exit; End;
      Ord('v') : Begin DoCmd(cmPaste); Exit; End;
      Ord('a') : Begin DoCmd(cmSelAll); Exit; End;
      Ord('f') : Begin DoCmd(cmFind); Exit; End;
      Ord('r') : Begin DoCmd(cmShowProj); Exit; End;
      Ord('g') : Begin DoCmd(cmShowMsgs); Exit; End;
    End;
  End;
  If CodeView Then
  Begin
    If EditKey(Fl, Ch_, Vk) Then
    Begin
      CaretOn := True;
      If Not DocRO Then SetTitle;
      Exit;
    End;
    Key := False;
    Exit;
  End;
  { concepteur }
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    Case Vk Of
      VK_DELETE : Begin DeleteSel; Exit; End;
      VK_ESC :
        Begin
          Tool := 0;
          If (Sel > 0) And (Sel <> CurForm) Then SelectCtl(CurForm);
          InvalBand(0, Y0, TbxW, Y1 + 1);
          Exit;
        End;
      VK_LEFT : Begin NudgeSel(-GridSz, 0, Shift); Exit; End;
      VK_RIGHT : Begin NudgeSel(GridSz, 0, Shift); Exit; End;
      VK_UP : Begin NudgeSel(0, -GridSz, Shift); Exit; End;
      VK_DOWN : Begin NudgeSel(0, GridSz, Shift); Exit; End;
      VK_TAB, VK_BACKTAB :
        Begin
          { controle suivant de la feuille }
          K := Sel;
          Repeat
            If (Vk = VK_BACKTAB) Or Shift Then Dec(K) Else Inc(K);
            If K > NCtl Then K := 1;
            If K < 1 Then K := NCtl;
          Until (CtForm[K] = CurForm) Or (K = Sel);
          SelectCtl(K);
          Exit;
        End;
      VK_ENTER, VK_NEWLINE :
        Begin
          If Sel > 0 Then PropEdit(PropRow);
          Exit;
        End;
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
        PropCommit;
        Layout;
        If CodeView Then ScrollToCaret;
        Redraw;
      End;
    WM_PAINT : Paint(H);
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
      Begin
        X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
        If Not ((X >= PropColX) And (X >= RpX) And (PropEf <> 0)) Then Dummy := WinSetFocus(HWND_DESKTOP, H);
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
    WM_VSCROLL :
      Begin
        K := 0;
        If Hi16(Mp2) = SB_LINEUP Then K := -3 Else If Hi16(Mp2) = SB_LINEDOWN Then K := 3;
        If (LastMx >= RpX) And (LastMy >= PgY0) And (LastMy < PgY1) Then
        Begin
          PropCommit;
          PropTop := MaxI(0, MinI(MaxI(0, NPropL - PropRows), PropTop + K Div 3));
          InvalProps;
        End
        Else If ShowMsgs And (LastMy >= MsY0) And (LastMx < RpX) Then
        Begin
          MsgTop := MaxI(0, MinI(MsgN - 1, MsgTop + K Div 3));
          InvalMsgs;
        End
        Else If CodeView And (Cur >= 0) Then
        Begin
          DTop[Cur] := MaxI(0, MinI(MaxTop, DTop[Cur] + K));
          InvalEditor;
        End;
      End;
    WM_CHAR :
      If Key(Mp1, Mp2) Then ClientProc := 1
      Else ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
    WM_COMMAND : DoCmd(Lo16(Mp1));
    WM_TIMER :
      Case Lo16(Mp1) Of
        1 :
          If CodeView Then
          Begin
            CaretOn := Not CaretOn;
            InvalCaret;
          End;
        7 : CompilePoll;
        8 : RunPoll;
        9 :
          Begin
            Dummy := WinStopTimer(Hab, Client, 9);
            If AutoMake Then
            Begin
              If MakeExe <> '' Then StartCompile(MakeExe, AutoRun) Else StartCompile(RunExeName, AutoRun);
            End;
          End;
      End;
    WM_SETFOCUS :
      Begin
        HasFocus := Lo16(Mp2) <> 0;
        InvalCaret;
      End;
    WM_CLOSE :
      If AutoQuit Or CanDiscard Then
      Begin
        If CompBusy Then Dummy := DosKillProcess(1, CompPid);
        Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
      End;
  Else
    ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

Function CanWriteDir(D : String) : Boolean;
Var T : String; S : String;
Begin
  T := JoinPath(D, 'VPTEST.TMP');
  S := 'x';
  CanWriteDir := WriteAll(T, @S[1], 1) And FExists(T);
  Dummy := DosDelete(Z(T));
End;

Procedure Main;
Var Fl, Sw, Sh, Fw, Fh, K : LongInt; A, U, Fn, Smp : String;
Begin
  NCtl := 0; Cur := -1; NDoc := 0; GenDoc := -1;
  For K := 0 To MaxDoc - 1 Do DUsed[K] := False;
  LAttr := Nil; LAttrCap := 0;
  BufInit(GenB); BufInit(RwOut); BufInit(RwHold); BufInit(SampB); BufInit(Clip); BufInit(Tmp);
  GMapF := Nil; GMapL := Nil;
  SnapN := 0; CbKind := 0; PropEf := 0; CtxMenu := 0; RubOn := False;
  ShowTbx := True; ShowProps := True; ShowProj := True; ShowMsgs := False; ShowNums := False;
  InsMode := True; CaretOn := True; HasFocus := True; CodeView := False;
  Drag := dNone; Tool := 0; RunPid := 0; CompPid := 0; CompBusy := False;
  FindS := ''; ReplS := ''; FindCase := False;
  MsgClear;
  StatusMsg := 'Pr'#136't.'; SavedMsg := '';
  { repertoires : compilateur a cote de VP.EXE (ou C:\), projets dans C:\ ou D:\ }
  ExeDir := DirOf(ParamStr(0));
  CompilerPath := JoinPath(ExeDir, 'OS2PC.EXE');
  If Not FExists(CompilerPath) Then CompilerPath := 'C:\OS2PC.EXE';
  WorkDir := 'C:\';
  If Not CanWriteDir(WorkDir) Then
    If CanWriteDir('D:\') Then WorkDir := 'D:\';
  Fn := ''; Smp := ''; MakeExe := ''; LogFile := '';
  AutoMake := False; AutoRun := False; AutoQuit := False;
  K := 1;
  While K <= ParamCount Do
  Begin
    A := ParamStr(K);
    U := UpStr(A);
    If (U = '/EXEMPLE') And (K < ParamCount) Then
    Begin
      Inc(K);
      Smp := UpStr(ParamStr(K));
    End
    Else If (U = '/MAKE') And (K < ParamCount) Then
    Begin
      Inc(K);
      MakeExe := ParamStr(K);
      AutoMake := True; AutoQuit := True;
    End
    Else If (U = '/LOG') And (K < ParamCount) Then
    Begin
      Inc(K);
      LogFile := ParamStr(K);
    End
    Else If U = '/RUN' Then
    Begin
      AutoMake := True; AutoRun := True;
    End
    Else Fn := A;
    Inc(K);
  End;
  ToolbarInit;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('VISUALPASCAL'), LongInt(@ClientProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('VISUALPASCAL'), Z2('Visual Pascal'), 0, 0, 0,
                              LongInt(@Client));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Fw := MinI(Sw, 640); Fh := MinI(Sh - 20, 460);
  If Sw >= 1000 Then
  Begin
    Fw := 1010; Fh := MinI(Sh - 40, 720);
  End
  Else If Sw >= 800 Then
  Begin
    Fw := 796; Fh := MinI(Sh - 30, 560);
  End;
  CW := Fw - 8; CH := Fh - 40;
  BuildMenu;
  If Smp <> '' Then
  Begin
    If Pos('DEMO', Smp) = 1 Then LoadSample(2) Else LoadSample(1);
  End
  Else If Fn <> '' Then
  Begin
    If (Length(Fn) < 2) Or (Fn[2] <> ':') Then Fn := JoinPath(WorkDir, Fn);
    If Not OpenFile(Fn) Then AutoMake := False;
  End
  Else NewProject;
  If (MakeExe <> '') And ((Length(MakeExe) < 2) Or (MakeExe[2] <> ':')) Then MakeExe := JoinPath(WorkDir, MakeExe);
  SetTitle;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Layout;
  Dummy := WinStartTimer(Hab, Client, 1, 500);
  If AutoMake Then Dummy := WinStartTimer(Hab, Client, 9, 800);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@GQmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@GQmsg));
  PropKill;
  Dummy := WinDestroyWindow(Frame);
End;

BEGIN
  Main;
END.
