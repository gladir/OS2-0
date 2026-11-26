{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: NC - North Commander pour le Presentation Manager d'OS/2-0,
                base sur NC.PAS du depot NORTONCOMMANDER-0.
}

Program NorthCommander;

{$R-,S-,I-}

(* Compilation : OS2PC NC.PAS NC.EXE

  North Commander (dossier Systeme OS/2 du bureau) : le gestionnaire de
  fichiers a deux panneaux de NC.PAS (depot NORTONCOMMANDER-0), dans une
  fenetre de Presentation Manager avec les menus et l'apparence d'OS/2.

    - deux panneaux : bref, complet, info, arbre, vue rapide, desactive ;
      tri par nom, extension, heure, taille ou non trie ; filtre ;
    - ligne de commande et historique (Ctrl+E, Ctrl+X, Alt+F8), ecran de
      sortie des commandes (Ctrl+O) ;
    - touches de fonction en bas : F1 Aide, F2 Menu, F3 Voir (ASCII et
      hexadecimal), F4 Editer, F5 Copier, F6 Renommer/deplacer, F7 Creer
      un repertoire, F8 Supprimer, F9 Menu deroulant, F10 Quitter ; avec
      Alt, Ctrl et Maj, comme Norton Commander ;
    - visualiseur (F3) : texte avec ou sans coupure, hexadecimal (F4),
      recherche (F7), atteindre (F5) ; editeur interne (F4) ;
    - menu utilisateur (NC.MNU), extensions (NC.EXT), recherche de
      fichiers (Alt+F7), arbre NCD (Alt+F10), comparaison des
      repertoires, attributs, selection par groupe (Gris+, Gris-, Gris*),
      configuration enregistree dans NC.INI.

  Parametres : [repertoire_gauche] [repertoire_droit] *)

Const
  WM_CREATE = $0001; WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024;
  WM_CLOSE = $0029; WM_QUIT = $002A; WM_VSCROLL = $0031;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
  WM_BUTTON2DOWN = $0074; WM_CHAR = $007A; WM_SYSCOMMAND = $0021;
  SC_MINIMIZE = $8002; SC_MAXIMIZE = $8003; SC_APPMENU = $8006; SC_RESTORE = $8008; CMDSRC_ACCELERATOR = 3;
  SWP_MAXIMIZE = $0800; SWP_RESTORE = $1000;
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
  VK_F1 = $20; VK_F2 = $21; VK_F3 = $22; VK_F4 = $23; VK_F5 = $24; VK_F6 = $25; VK_F7 = $26; VK_F8 = $27; VK_F9 = $28;
  VK_F10 = $29; VK_F11 = $2A; VK_F12 = $2B; VK_SHIFT = $09; VK_CTRL = $0A; VK_ALT = $0B; VK_SPACE = $04;
  PM_REMOVE = 1; SPTR_ARROW = 1; SPTR_WAIT = 3;
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
Function DosQueryFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosQuerySysInfo(IStart, ILast, PBuf, CbBuf : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetPathInfo(PName, Level, PInfo, Cb, Flags : LongInt) : LongInt; External 'DOSCALLS';
Function DosMove(POld, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosDeleteDir(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetDefaultDisk(Disk : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetCurrentDir(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDir(Disk, PBuf, PCb : LongInt) : LongInt; External 'DOSCALLS';
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';
Function WinInitShield(Hab, Hmq : LongInt) : LongInt; External 'PMVIOP' Name 'WININITSHIELD';
Function WinCreateConsole(Own, PTitle, Fl, PH : LongInt) : LongInt; External 'PMVIOP' Name 'WINCREATECONSOLE';
Function WinSubclassWindow(H, Proc : LongInt) : LongInt; External 'PMWIN';
Function WinSysClassProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WINSYSCLASSPROC';
Function WinGetKeyState(HD, Vk : LongInt) : LongInt; External 'PMWIN';
Function KrnKbdCtl(Op, V : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnKbdCtl';
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
Function WinPeekMsg(Hab, P, HF, First, Last, Fl : LongInt) : LongInt; External 'PMWIN';
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
{ Fichiers : panneaux, tri, masques, disques, copie et suppression      }
{ ==================================================================== }

Const
  AppTitle = 'North Commander';
  NcVersion = '2.0';
  MaxEnt = 4000;
  MaxTree = 3000;
  MaxFound = 1000;
  MaxHist = 60;
  { modes des panneaux }
  pmBrief = 0; pmFull = 1; pmInfo = 2; pmTree = 3; pmQuick = 4; pmOff = 5;
  { tris }
  srName = 0; srExt = 1; srTime = 2; srSize = 3; srNone = 4;
  { attributs }
  faRO = $01; faHidden = $02; faSys = $04; faDir = $10; faArch = $20;

Type
  TEntry = Record
    Name : String;
    Size, Attr, FDate, FTime, Ord_ : LongInt;
    Sel : Boolean;
  End;
  TEntArr = Array[0..MaxEnt - 1] Of TEntry;
  PEntArr = ^TEntArr;
  TStrArr = Array[0..MaxTree - 1] Of String;
  PStrArr = ^TStrArr;

Var
  Ent : Array[0..1] Of PEntArr;
  NEnt, CurI, TopI : Array[0..1] Of LongInt;
  PPath : Array[0..1] Of String;
  PMode, PSort, PFiltK : Array[0..1] Of LongInt;
  PFilter : Array[0..1] Of String;
  PLast : Array[0..1] Of String;           { mode du panneau avant Info/Arbre/Vue rapide }
  { arbre des repertoires (Arbre, NCD) }
  TreeP : PStrArr;
  TreeD : Array[0..MaxTree - 1] Of Byte;   { profondeur }
  NTree, TreeCur, TreeTop : LongInt;
  TreeDrive : Char;
  { recherche de fichiers }
  FoundP : PStrArr;
  NFound : LongInt;
  { historique des commandes }
  Hist : Array[0..MaxHist - 1] Of String;
  NHist, HistPos : LongInt;
  { options (NC.INI) }
  OptHidden, OptConfDel, OptConfCopy, OptConfOver, OptKeyBar, OptMiniStatus, OptClock : Boolean;
  OptInsMoves, OptDirsFirst, OptAutoMenu, OptSaveOnExit, OptExecWin : Boolean;
  OptStyle, OptEditor, OptViewer : LongInt;
  OptEditCmd, OptViewCmd : String;
  IniName : String;
  { donnees de travail }
  FindBuf : Array[0..299] Of Byte;
  Stop_ : Boolean;

{ --- chaines --- }

Function PadR(S : String; N : LongInt) : String;
Var R : String;
Begin
  R := S;
  If Length(R) > N Then R := Copy(R, 1, N);
  While Length(R) < N Do R := R + ' ';
  PadR := R;
End;

Function PadL(S : String; N : LongInt) : String;
Var R : String;
Begin
  R := S;
  If Length(R) > N Then R := Copy(R, Length(R) - N + 1, N);
  While Length(R) < N Do R := ' ' + R;
  PadL := R;
End;

Function Z2s(V : LongInt) : String;
Begin
  Z2s := Chr(48 + (V Div 10) Mod 10) + Chr(48 + V Mod 10);
End;

{ nombre avec separateur des milliers (espace) }
Function Thou(V : Double) : String;
Var S, R : String; K, N : LongInt; T : Double;
Begin
  If V < 0 Then V := 0;
  S := '';
  T := Int(V + 0.5);
  If T < 1 Then S := '0';
  While T >= 1 Do
  Begin
    K := Trunc(T - Int(T / 10) * 10 + 0.5);
    If K > 9 Then K := 9;
    S := Chr(48 + K) + S;
    T := Int(T / 10);
  End;
  R := ''; N := 0;
  For K := Length(S) DownTo 1 Do
  Begin
    R := S[K] + R;
    Inc(N);
    If (N Mod 3 = 0) And (K > 1) Then R := ' ' + R;
  End;
  Thou := R;
End;

Function DStr(V : Double) : String;
Var S : String; K : LongInt; T : Double;
Begin
  S := '';
  T := Int(V + 0.5);
  If T < 1 Then S := '0';
  While T >= 1 Do
  Begin
    K := Trunc(T - Int(T / 10) * 10 + 0.5);
    If K > 9 Then K := 9;
    S := Chr(48 + K) + S;
    T := Int(T / 10);
  End;
  DStr := S;
End;

{ taille d'un fichier dans la colonne (10 caracteres au plus) }
Function FmtSize(V : LongInt) : String;
Var R : String; D : Double;
Begin
  D := V;
  If V < 0 Then D := D + 4294967296.0;
  If D < 1000000000.0 Then R := DStr(D)
  Else R := DStr(D / 1024) + 'K';
  FmtSize := R;
End;

Function FmtDate(D : LongInt) : String;
Var Y : LongInt;
Begin
  Y := ((D Shr 9) And $7F) + 1980;
  FmtDate := Z2s(D And 31) + '-' + Z2s((D Shr 5) And 15) + '-' + Z2s(Y Mod 100);
End;

Function FmtTime(T : LongInt) : String;
Begin
  FmtTime := Z2s((T Shr 11) And 31) + ':' + Z2s((T Shr 5) And 63);
End;

{ --- masques (* ?), plusieurs separes par ; , ou espace --- }

Function Match1(N, M : String) : Boolean;
Var I, J, Si, Sj : LongInt;
Begin
  I := 1; J := 1; Si := 0; Sj := 0;
  N := UpStr(N); M := UpStr(M);
  { *.* et * : tout ; NOM. : sans extension }
  If (M = '*.*') Or (M = '*') Then
  Begin
    Match1 := True;
    Exit;
  End;
  If (Pos('.', N) = 0) And (Length(M) > 0) And (M[Length(M)] = '.') Then N := N + '.';
  While I <= Length(N) Do
  Begin
    If (J <= Length(M)) And ((M[J] = '?') Or (M[J] = N[I])) Then
    Begin
      Inc(I); Inc(J);
    End
    Else If (J <= Length(M)) And (M[J] = '*') Then
    Begin
      Si := I; Sj := J; Inc(J);
    End
    Else If Sj > 0 Then
    Begin
      Inc(Si); I := Si; J := Sj + 1;
    End
    Else
    Begin
      Match1 := False;
      Exit;
    End;
  End;
  While (J <= Length(M)) And (M[J] = '*') Do Inc(J);
  Match1 := J > Length(M);
End;

Function MatchMask(N, Masks : String) : Boolean;
Var K, St : LongInt; M : String; R : Boolean;
Begin
  R := False;
  Masks := Masks + ';';
  St := 1;
  For K := 1 To Length(Masks) Do
    If (Masks[K] = ';') Or (Masks[K] = ',') Or (Masks[K] = ' ') Then
    Begin
      M := Trim(Copy(Masks, St, K - St));
      If (M <> '') And Match1(N, M) Then R := True;
      St := K + 1;
    End;
  MatchMask := R;
End;

Function ExtName(N : String) : String;
Var K : LongInt; R : String;
Begin
  R := '';
  K := Length(N);
  While (K > 0) And (N[K] <> '.') Do Dec(K);
  If K > 1 Then R := UpStr(Copy(N, K + 1, 255));
  ExtName := R;
End;

Function BaseNoExt(N : String) : String;
Var K : LongInt; R : String;
Begin
  R := N;
  K := Length(N);
  While (K > 0) And (N[K] <> '.') Do Dec(K);
  If K > 1 Then R := Copy(N, 1, K - 1);
  BaseNoExt := R;
End;

Function AddSl(P : String) : String;
Begin
  If (P <> '') And (P[Length(P)] <> '\') Then P := P + '\';
  AddSl := P;
End;

Function JoinP(P, N : String) : String;
Begin
  JoinP := AddSl(P) + N;
End;

Function IsRoot(P : String) : Boolean;
Begin
  IsRoot := (Length(P) <= 3) And (Length(P) >= 2) And (P[2] = ':');
End;

Function ParentOf(P : String) : String;
Var K : LongInt; R : String;
Begin
  R := P;
  If Not IsRoot(P) Then
  Begin
    K := Length(P);
    While (K > 0) And (P[K] <> '\') Do Dec(K);
    If K <= 3 Then R := Copy(P, 1, 3) Else R := Copy(P, 1, K - 1);
  End;
  ParentOf := R;
End;

Function LastPart(P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> '\') Do Dec(K);
  LastPart := Copy(P, K + 1, 255);
End;

Function IsDirE(Var E : TEntry) : Boolean;
Begin
  IsDirE := (E.Attr And faDir) <> 0;
End;

Function DirExists(P : String) : Boolean;
Var Info : Array[0..63] Of Byte; R : Boolean;
Begin
  R := False;
  If IsRoot(P) Then R := DosQueryPathInfo(Z(AddSl(P)), 1, LongInt(@Info), 64) = 0
  Else If DosQueryPathInfo(Z(P), 1, LongInt(@Info), 64) = 0 Then R := (Info[20] And faDir) <> 0;
  DirExists := R;
End;

{ attributs (-1 : absent) }
Function GetAttr(P : String) : LongInt;
Var Info : Array[0..63] Of Byte;
Begin
  If DosQueryPathInfo(Z(P), 1, LongInt(@Info), 64) = 0 Then GetAttr := Info[20] Or (Info[21] Shl 8)
  Else GetAttr := -1;
End;

Function SetAttr(P : String; A : LongInt) : Boolean;
Var Info : Array[0..63] Of Byte;
Begin
  SetAttr := False;
  If DosQueryPathInfo(Z(P), 1, LongInt(@Info), 64) <> 0 Then Exit;
  Info[20] := A And $27; Info[21] := 0; Info[22] := 0; Info[23] := 0;
  SetAttr := DosSetPathInfo(Z(P), 1, LongInt(@Info), 24, 0) = 0;
End;

{ --- disques --- }

Function DriveMap : LongInt;
Var D, M : LongInt;
Begin
  D := 0; M := 0;
  Dummy := DosQueryCurrentDisk(LongInt(@D), LongInt(@M));
  DriveMap := M;
End;

Function DriveOk(C : Char) : Boolean;
Begin
  C := UpCase(C);
  DriveOk := (C >= 'A') And (C <= 'Z') And (((DriveMap Shr (Ord(C) - 65)) And 1) <> 0);
End;

{ espace total et libre (octets) }
Function DiskSpace(C : Char; Var Total, Free : Double) : Boolean;
Var B : Array[0..31] Of Byte; Spc, Tot, Fr, Bps : LongInt;
Begin
  DiskSpace := False;
  Total := 0; Free := 0;
  If DosQueryFSInfo(Ord(UpCase(C)) - 64, 1, LongInt(@B), 18) <> 0 Then Exit;
  Spc := RdL(LongInt(@B) + 4); Tot := RdL(LongInt(@B) + 8); Fr := RdL(LongInt(@B) + 12);
  Bps := B[16] Or (B[17] Shl 8);
  Total := 1.0 * Spc * Bps * Tot;
  Free := 1.0 * Spc * Bps * Fr;
  DiskSpace := True;
End;

Function VolLabel(C : Char) : String;
Var B : Array[0..63] Of Byte; N, K : LongInt; R : String;
Begin
  R := '';
  If DosQueryFSInfo(Ord(UpCase(C)) - 64, 2, LongInt(@B), 40) = 0 Then
  Begin
    N := B[4];
    If N > 11 Then N := 11;
    For K := 0 To N - 1 Do
      If B[5 + K] <> 0 Then R := R + Chr(B[5 + K]);
  End;
  VolLabel := Trim(R);
End;

Function SetVolLabel(C : Char; L : String) : Boolean;
Var B : Array[0..31] Of Byte; K : LongInt;
Begin
  FillChar(B, SizeOf(B), 0);
  L := Copy(UpStr(L), 1, 11);
  B[0] := Length(L);
  For K := 1 To Length(L) Do B[K] := Ord(L[K]);
  SetVolLabel := DosSetFSInfo(Ord(UpCase(C)) - 64, 2, LongInt(@B), Length(L) + 2) = 0;
End;

Function MemKb(Ix : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := 0;
  If DosQuerySysInfo(Ix, Ix, LongInt(@V), 4) = 0 Then MemKb := V Div 1024 Else MemKb := 0;
End;

{ --- recherche de fichiers (niveau 1) --- }

Function FindName : String;
Var N, K : LongInt; R : String;
Begin
  N := FindBuf[28];
  R := '';
  For K := 1 To N Do R := R + Chr(FindBuf[28 + K]);
  FindName := R;
End;

Function FindFirst_(Spec : String; Attr : LongInt; Var H : LongInt) : Boolean;
Var N : LongInt;
Begin
  H := -1; N := 1;
  FindFirst_ := DosFindFirst(Z(Spec), LongInt(@H), Attr, LongInt(@FindBuf), SizeOf(FindBuf), LongInt(@N), 1) = 0;
End;

Function FindNext_(H : LongInt) : Boolean;
Var N : LongInt;
Begin
  N := 1;
  FindNext_ := DosFindNext(H, LongInt(@FindBuf), SizeOf(FindBuf), LongInt(@N)) = 0;
End;

{ --- panneaux : lecture et tri --- }

Function UpKey(Var E : TEntry) : String;
Begin
  UpKey := UpStr(E.Name);
End;

{ A avant B ? (le parent, puis les repertoires, puis les fichiers) }
Function Before(Var A, B : TEntry; Mode : LongInt) : Boolean;
Var Ra, Rb : LongInt; R : Boolean; Ea, Eb : String;
Begin
  If A.Name = '..' Then
  Begin
    Before := True;
    Exit;
  End;
  If B.Name = '..' Then
  Begin
    Before := False;
    Exit;
  End;
  If OptDirsFirst Or (Mode <> srNone) Then
  Begin
    If IsDirE(A) <> IsDirE(B) Then
    Begin
      Before := IsDirE(A);
      Exit;
    End;
  End;
  R := False;
  Case Mode Of
    srExt :
      Begin
        Ea := ExtName(A.Name); Eb := ExtName(B.Name);
        If Ea <> Eb Then R := Ea < Eb Else R := UpKey(A) < UpKey(B);
      End;
    srTime :
      Begin
        Ra := (A.FDate Shl 16) Or A.FTime; Rb := (B.FDate Shl 16) Or B.FTime;
        If Ra <> Rb Then R := Ra > Rb Else R := UpKey(A) < UpKey(B);
      End;
    srSize :
      If A.Size <> B.Size Then R := A.Size > B.Size Else R := UpKey(A) < UpKey(B);
    srNone : R := A.Ord_ < B.Ord_;
  Else
    R := UpKey(A) < UpKey(B);
  End;
  Before := R;
End;

Procedure SortPanel(S : LongInt);
Var Gap, I, J, N : LongInt; T : TEntry; P : PEntArr;
Begin
  P := Ent[S];
  N := NEnt[S];
  Gap := N Div 2;
  While Gap > 0 Do
  Begin
    For I := Gap To N - 1 Do
    Begin
      T := P^[I];
      J := I;
      While (J >= Gap) And Before(T, P^[J - Gap], PSort[S]) Do
      Begin
        P^[J] := P^[J - Gap];
        J := J - Gap;
      End;
      P^[J] := T;
    End;
    Gap := Gap Div 2;
  End;
End;

Function FilterOk(S : LongInt; Var E : TEntry) : Boolean;
Begin
  If IsDirE(E) Then FilterOk := True
  Else
    Case PFiltK[S] Of
      1 : FilterOk := MatchMask(E.Name, '*.EXE;*.COM;*.CMD;*.BAT');
      2 : FilterOk := MatchMask(E.Name, PFilter[S]);
    Else
      FilterOk := True;
    End;
End;

{ lire le repertoire du panneau ; garder la selection et le curseur sur Keep }
Procedure ReadPanel(S : LongInt; Keep : String);
Var H, N, K, A : LongInt; Nm : String; E : TEntry; HasUp : Boolean; Old : PEntArr;
    SelN : Array[0..99] Of String; NSel : LongInt;
Begin
  { selection a garder (200 noms au plus) }
  NSel := 0;
  For K := 0 To NEnt[S] - 1 Do
    If Ent[S]^[K].Sel And (NSel < 100) Then
    Begin
      SelN[NSel] := Ent[S]^[K].Name; Inc(NSel);
    End;
  NEnt[S] := 0; N := 0; HasUp := False;
  If Not IsRoot(PPath[S]) Then
  Begin
    E.Name := '..'; E.Size := 0; E.Attr := faDir; E.FDate := 0; E.FTime := 0; E.Sel := False; E.Ord_ := 0;
    Ent[S]^[0] := E; N := 1; HasUp := True;
  End;
  If FindFirst_(JoinP(PPath[S], '*'), $37, H) Then
  Begin
    Repeat
      Nm := FindName;
      A := FindBuf[24];
      If (Nm <> '.') And (Nm <> '..') And (N < MaxEnt) Then
        If OptHidden Or ((A And (faHidden Or faSys)) = 0) Then
        Begin
          E.Name := Nm;
          E.Size := RdL(LongInt(@FindBuf) + 16);
          E.Attr := A;
          E.FDate := FindBuf[12] Or (FindBuf[13] Shl 8);
          E.FTime := FindBuf[14] Or (FindBuf[15] Shl 8);
          E.Sel := False; E.Ord_ := N;
          If FilterOk(S, E) Then
          Begin
            For K := 0 To NSel - 1 Do If SelN[K] = Nm Then E.Sel := True;
            Ent[S]^[N] := E; Inc(N);
          End;
        End;
    Until Not FindNext_(H);
    Dummy := DosFindClose(H);
  End;
  NEnt[S] := N;
  SortPanel(S);
  If HasUp Then ;
  CurI[S] := 0;
  If Keep <> '' Then
    For K := 0 To NEnt[S] - 1 Do
      If UpStr(Ent[S]^[K].Name) = UpStr(Keep) Then CurI[S] := K;
  If CurI[S] >= NEnt[S] Then CurI[S] := NEnt[S] - 1;
  If CurI[S] < 0 Then CurI[S] := 0;
  Old := Nil;
  If Old = Nil Then ;
End;

Function CurName(S : LongInt) : String;
Begin
  If (NEnt[S] > 0) And (CurI[S] < NEnt[S]) Then CurName := Ent[S]^[CurI[S]].Name Else CurName := '';
End;

Function NSelected(S : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To NEnt[S] - 1 Do If Ent[S]^[K].Sel Then Inc(N);
  NSelected := N;
End;

Function SelBytes(S : LongInt) : Double;
Var K : LongInt; D : Double;
Begin
  D := 0;
  For K := 0 To NEnt[S] - 1 Do
    If Ent[S]^[K].Sel And Not IsDirE(Ent[S]^[K]) Then
    Begin
      If Ent[S]^[K].Size >= 0 Then D := D + Ent[S]^[K].Size Else D := D + Ent[S]^[K].Size + 4294967296.0;
    End;
  SelBytes := D;
End;

Procedure DirStats(S : LongInt; Var NFiles : LongInt; Var Bytes : Double);
Var K : LongInt;
Begin
  NFiles := 0; Bytes := 0;
  For K := 0 To NEnt[S] - 1 Do
    If Not IsDirE(Ent[S]^[K]) Then
    Begin
      Inc(NFiles);
      If Ent[S]^[K].Size >= 0 Then Bytes := Bytes + Ent[S]^[K].Size Else Bytes := Bytes + Ent[S]^[K].Size + 4294967296.0;
    End;
End;

{ --- operations sur les fichiers --- }

{ reserve de noms partagee par les parcours recursifs : chaque niveau y
  range ses noms au-dessus de ceux des niveaux superieurs (PoolTop) }
Var
  LstP : PStrArr;
  LstA : Array[0..MaxTree - 1] Of LongInt;
  PoolTop : LongInt;

{ noms du repertoire P ajoutes a la reserve ; DirsOnly : repertoires seulement }
Function ListDir(P : String; DirsOnly : Boolean) : LongInt;
Var H, N, A : LongInt; Nm : String;
Begin
  N := 0;
  If FindFirst_(JoinP(P, '*'), $37, H) Then
  Begin
    Repeat
      Nm := FindName;
      A := FindBuf[24];
      If (Nm <> '.') And (Nm <> '..') And (PoolTop + N < MaxTree) Then
        If Not DirsOnly Or ((A And faDir) <> 0) Then
        Begin
          LstP^[PoolTop + N] := Nm; LstA[PoolTop + N] := A; Inc(N);
        End;
    Until Not FindNext_(H);
    Dummy := DosFindClose(H);
  End;
  ListDir := N;
End;

{ taille et nombre de fichiers d'un repertoire (recursif) }
Procedure DirSize(P : String; Var NF, ND : LongInt; Var Bytes : Double; Depth : LongInt);
Var H, A, K, Base, N : LongInt; Nm : String;
Begin
  If (Depth > 30) Or Stop_ Then Exit;
  Base := PoolTop; N := 0;
  If FindFirst_(JoinP(P, '*'), $37, H) Then
  Begin
    Repeat
      Nm := FindName;
      A := FindBuf[24];
      If (Nm <> '.') And (Nm <> '..') Then
      Begin
        If (A And faDir) <> 0 Then
        Begin
          Inc(ND);
          If Base + N < MaxTree Then
          Begin
            LstP^[Base + N] := Nm; Inc(N);
          End;
        End
        Else
        Begin
          Inc(NF);
          K := RdL(LongInt(@FindBuf) + 16);
          If K >= 0 Then Bytes := Bytes + K Else Bytes := Bytes + K + 4294967296.0;
        End;
      End;
    Until Not FindNext_(H);
    Dummy := DosFindClose(H);
  End;
  PoolTop := Base + N;
  For K := Base To Base + N - 1 Do DirSize(JoinP(P, LstP^[K]), NF, ND, Bytes, Depth + 1);
  PoolTop := Base;
End;

{ copie d'un fichier ; 0 = bien }
Function CopyOne(Src, Dst : String) : LongInt;
Begin
  CopyOne := DosCopy(Z(Src), Z2(Dst), 1);
End;

{ copie d'un repertoire et de son contenu ; rend le nombre d'erreurs }
Function CopyTree(Src, Dst : String; Depth : LongInt; Var NFiles : LongInt) : LongInt;
Var K, N, Base, Err : LongInt;
Begin
  Err := 0;
  If Depth > 30 Then
  Begin
    CopyTree := 1;
    Exit;
  End;
  If Not DirExists(Dst) Then
    If DosCreateDir(Z(Dst), 0) <> 0 Then
    Begin
      CopyTree := 1;
      Exit;
    End;
  Base := PoolTop;
  N := ListDir(Src, False);
  PoolTop := Base + N;
  For K := Base To Base + N - 1 Do
  Begin
    If Stop_ Then Break;
    If (LstA[K] And faDir) <> 0 Then Err := Err + CopyTree(JoinP(Src, LstP^[K]), JoinP(Dst, LstP^[K]), Depth + 1, NFiles)
    Else
    Begin
      If CopyOne(JoinP(Src, LstP^[K]), JoinP(Dst, LstP^[K])) <> 0 Then Inc(Err) Else Inc(NFiles);
    End;
  End;
  PoolTop := Base;
  CopyTree := Err;
End;

Function DeleteTree(P : String; Depth : LongInt; Var NFiles : LongInt) : LongInt;
Var K, N, Base, Err : LongInt;
Begin
  Err := 0;
  If Depth > 30 Then
  Begin
    DeleteTree := 1;
    Exit;
  End;
  Base := PoolTop;
  N := ListDir(P, False);
  PoolTop := Base + N;
  For K := Base To Base + N - 1 Do
  Begin
    If Stop_ Then Break;
    If (LstA[K] And faDir) <> 0 Then Err := Err + DeleteTree(JoinP(P, LstP^[K]), Depth + 1, NFiles)
    Else
    Begin
      If (LstA[K] And faRO) <> 0 Then
        If SetAttr(JoinP(P, LstP^[K]), LstA[K] And Not faRO) Then ;
      If DosDelete(Z(JoinP(P, LstP^[K]))) <> 0 Then Inc(Err) Else Inc(NFiles);
    End;
  End;
  PoolTop := Base;
  If DosDeleteDir(Z(P)) <> 0 Then Inc(Err);
  DeleteTree := Err;
End;

{ deplacer (meme disque : DosMove ; sinon copie puis suppression) }
Function MoveOne(Src, Dst : String; IsDir : Boolean) : LongInt;
Var R, N : LongInt;
Begin
  R := DosMove(Z(Src), Z2(Dst));
  If (R <> 0) And (UpCase(Src[1]) <> UpCase(Dst[1])) Then
  Begin
    N := 0;
    If IsDir Then
    Begin
      R := CopyTree(Src, Dst, 0, N);
      If R = 0 Then R := DeleteTree(Src, 0, N);
    End
    Else
    Begin
      R := CopyOne(Src, Dst);
      If R = 0 Then R := DosDelete(Z(Src));
    End;
  End;
  MoveOne := R;
End;

{ --- arbre des repertoires --- }

{ arbre complet, dans l'ordre en profondeur }
Procedure TreeWalk(P : String; Depth : LongInt);
Var A, K, N, Base : LongInt; Nm : String;
Begin
  If (Depth > 30) Or (NTree >= MaxTree) Or Stop_ Then Exit;
  Base := PoolTop;
  N := ListDir(P, True);
  { sans les repertoires caches, sauf si l'option les montre }
  K := Base;
  While K < Base + N Do
  Begin
    If Not OptHidden And ((LstA[K] And (faHidden Or faSys)) <> 0) Then
    Begin
      LstP^[K] := LstP^[Base + N - 1]; LstA[K] := LstA[Base + N - 1];
      Dec(N);
    End
    Else Inc(K);
  End;
  For K := Base + 1 To Base + N - 1 Do
  Begin
    Nm := LstP^[K]; A := K;
    While (A > Base) And (UpStr(LstP^[A - 1]) > UpStr(Nm)) Do
    Begin
      LstP^[A] := LstP^[A - 1];
      Dec(A);
    End;
    LstP^[A] := Nm;
  End;
  PoolTop := Base + N;
  For K := Base To Base + N - 1 Do
    If NTree < MaxTree Then
    Begin
      TreeP^[NTree] := JoinP(P, LstP^[K]); TreeD[NTree] := Depth;
      Inc(NTree);
      TreeWalk(JoinP(P, LstP^[K]), Depth + 1);
    End;
  PoolTop := Base;
End;

Procedure BuildTree(C : Char);
Begin
  NTree := 0;
  TreeDrive := UpCase(C);
  TreeP^[0] := TreeDrive + ':\'; TreeD[0] := 0; NTree := 1;
  PoolTop := 0;
  TreeWalk(TreeDrive + ':\', 1);
End;

{ --- recherche de fichiers (Alt+F7) --- }

Var
  FindMask, FindText : String;
  FindCase : Boolean;
  FindMaxD : LongInt;

Function FileHasText(P, T : String) : Boolean;
Var H, N, K, J, M : LongInt; Bf : Array[0..8191] Of Byte; R : Boolean; Up : String;
Begin
  R := False;
  FileHasText := False;
  If T = '' Then
  Begin
    FileHasText := True;
    Exit;
  End;
  If Not FOpenRead(P, H) Then Exit;
  If FindCase Then Up := T Else Up := UpStr(T);
  M := 0;
  Repeat
    N := FRead(H, @Bf, SizeOf(Bf));
    For K := 0 To N - 1 Do
    Begin
      J := Bf[K];
      If Not FindCase And (J >= 97) And (J <= 122) Then J := J - 32;
      If Chr(J) = Up[M + 1] Then
      Begin
        Inc(M);
        If M >= Length(Up) Then
        Begin
          R := True;
          Break;
        End;
      End
      Else If Chr(J) = Up[1] Then M := 1
      Else M := 0;
    End;
  Until R Or (N <= 0);
  DosClose(H);
  FileHasText := R;
End;

Procedure FindWalk(P : String; Depth : LongInt);
Var K, N, Base : LongInt; Nm : String;
Begin
  If (Depth > FindMaxD) Or (NFound >= MaxFound) Or Stop_ Then Exit;
  Base := PoolTop;
  N := ListDir(P, False);
  PoolTop := Base + N;
  For K := Base To Base + N - 1 Do
  Begin
    Nm := LstP^[K];
    If (LstA[K] And faDir) <> 0 Then
    Begin
      If MatchMask(Nm, FindMask) And (FindText = '') And (NFound < MaxFound) Then
      Begin
        FoundP^[NFound] := JoinP(P, Nm) + '\'; Inc(NFound);
      End;
    End
    Else If MatchMask(Nm, FindMask) And (NFound < MaxFound) Then
      If FileHasText(JoinP(P, Nm), FindText) Then
      Begin
        FoundP^[NFound] := JoinP(P, Nm); Inc(NFound);
      End;
  End;
  For K := Base To Base + N - 1 Do
    If (LstA[K] And faDir) <> 0 Then FindWalk(JoinP(P, LstP^[K]), Depth + 1);
  PoolTop := Base;
End;

{ --- historique --- }

Procedure AddHist(S : String);
Var K : LongInt;
Begin
  S := Trim(S);
  If S = '' Then Exit;
  For K := 0 To NHist - 1 Do
    If Hist[K] = S Then
    Begin
      While K < NHist - 1 Do
      Begin
        Hist[K] := Hist[K + 1];
        Inc(K);
      End;
      Dec(NHist);
      Break;
    End;
  If NHist >= MaxHist Then
  Begin
    For K := 0 To MaxHist - 2 Do Hist[K] := Hist[K + 1];
    NHist := MaxHist - 1;
  End;
  Hist[NHist] := S;
  Inc(NHist);
  HistPos := NHist;
End;

{ --- configuration (NC.INI) --- }

Function BoolS(B : Boolean) : String;
Begin
  If B Then BoolS := '1' Else BoolS := '0';
End;

Procedure SaveIni;
Var B : TBuf; K : LongInt;
Begin
  BufInit(B);
  BufAdd(B, '; North Commander (OS/2-0)'#13#10);
  BufAdd(B, 'CACHES=' + BoolS(OptHidden) + #13#10 + 'CONFSUPPR=' + BoolS(OptConfDel) + #13#10);
  BufAdd(B, 'CONFCOPIE=' + BoolS(OptConfCopy) + #13#10 + 'CONFECRASE=' + BoolS(OptConfOver) + #13#10);
  BufAdd(B, 'TOUCHES=' + BoolS(OptKeyBar) + #13#10 + 'MINISTATUT=' + BoolS(OptMiniStatus) + #13#10);
  BufAdd(B, 'HORLOGE=' + BoolS(OptClock) + #13#10 + 'INSDESCEND=' + BoolS(OptInsMoves) + #13#10);
  BufAdd(B, 'REPDABORD=' + BoolS(OptDirsFirst) + #13#10 + 'MENUAUTO=' + BoolS(OptAutoMenu) + #13#10);
  BufAdd(B, 'ENREGQUITTER=' + BoolS(OptSaveOnExit) + #13#10 + 'FENETRE=' + BoolS(OptExecWin) + #13#10);
  BufAdd(B, 'STYLE=' + IStr(OptStyle) + #13#10 + 'EDITEUR=' + IStr(OptEditor) + #13#10);
  BufAdd(B, 'EDITCMD=' + OptEditCmd + #13#10 + 'VISU=' + IStr(OptViewer) + #13#10 + 'VISUCMD=' + OptViewCmd + #13#10);
  For K := 0 To 1 Do
  Begin
    BufAdd(B, 'PANNEAU' + IStr(K) + '=' + PPath[K] + #13#10);
    BufAdd(B, 'MODE' + IStr(K) + '=' + IStr(PMode[K]) + #13#10 + 'TRI' + IStr(K) + '=' + IStr(PSort[K]) + #13#10);
    BufAdd(B, 'FILTRE' + IStr(K) + '=' + IStr(PFiltK[K]) + #13#10 + 'MASQUE' + IStr(K) + '=' + PFilter[K] + #13#10);
  End;
  For K := 0 To NHist - 1 Do BufAdd(B, 'HIST=' + Hist[K] + #13#10);
  If B.Len > 0 Then Dummy := LongInt(WriteAll(IniName, B.P, B.Len));
  BufFree(B);
End;

Procedure LoadIni;
Var H, N, I, P, V, E : LongInt; Bf : Array[0..16383] Of Byte; S, Key, Vs : String;
Begin
  If Not FOpenRead(IniName, H) Then Exit;
  N := FRead(H, @Bf, SizeOf(Bf));
  DosClose(H);
  I := 0;
  While I < N Do
  Begin
    S := '';
    While (I < N) And (Bf[I] <> 10) And (Bf[I] <> 13) Do
    Begin
      If Length(S) < 250 Then S := S + Chr(Bf[I]);
      Inc(I);
    End;
    While (I < N) And ((Bf[I] = 10) Or (Bf[I] = 13)) Do Inc(I);
    If (S = '') Or (S[1] = ';') Then Continue;
    P := Pos('=', S);
    If P = 0 Then Continue;
    Key := UpStr(Copy(S, 1, P - 1)); Vs := Copy(S, P + 1, 255);
    Val(Vs, V, E);
    If E <> 0 Then V := 0;
    If Key = 'CACHES' Then OptHidden := V <> 0
    Else If Key = 'CONFSUPPR' Then OptConfDel := V <> 0
    Else If Key = 'CONFCOPIE' Then OptConfCopy := V <> 0
    Else If Key = 'CONFECRASE' Then OptConfOver := V <> 0
    Else If Key = 'TOUCHES' Then OptKeyBar := V <> 0
    Else If Key = 'MINISTATUT' Then OptMiniStatus := V <> 0
    Else If Key = 'HORLOGE' Then OptClock := V <> 0
    Else If Key = 'INSDESCEND' Then OptInsMoves := V <> 0
    Else If Key = 'REPDABORD' Then OptDirsFirst := V <> 0
    Else If Key = 'MENUAUTO' Then OptAutoMenu := V <> 0
    Else If Key = 'ENREGQUITTER' Then OptSaveOnExit := V <> 0
    Else If Key = 'FENETRE' Then OptExecWin := V <> 0
    Else If Key = 'STYLE' Then OptStyle := V
    Else If Key = 'EDITEUR' Then OptEditor := V
    Else If Key = 'EDITCMD' Then OptEditCmd := Vs
    Else If Key = 'VISU' Then OptViewer := V
    Else If Key = 'VISUCMD' Then OptViewCmd := Vs
    Else If Key = 'HIST' Then AddHist(Vs)
    Else If (Copy(Key, 1, 7) = 'PANNEAU') And ((Key[8] = '0') Or (Key[8] = '1')) Then
    Begin
      If DirExists(Vs) Then PPath[Ord(Key[8]) - 48] := Vs;
    End
    Else If (Copy(Key, 1, 4) = 'MODE') And (Length(Key) = 5) Then
    Begin
      If (V >= 0) And (V <= pmOff) Then PMode[Ord(Key[5]) - 48] := V;
    End
    Else If (Copy(Key, 1, 3) = 'TRI') And (Length(Key) = 4) Then
    Begin
      If (V >= 0) And (V <= srNone) Then PSort[Ord(Key[4]) - 48] := V;
    End
    Else If (Copy(Key, 1, 6) = 'FILTRE') And (Length(Key) = 7) Then PFiltK[Ord(Key[7]) - 48] := V
    Else If (Copy(Key, 1, 6) = 'MASQUE') And (Length(Key) = 7) Then PFilter[Ord(Key[7]) - 48] := Vs;
  End;
  For I := 0 To 1 Do
  Begin
    If (PFiltK[I] < 0) Or (PFiltK[I] > 2) Then PFiltK[I] := 0;
    If PMode[I] = pmInfo Then PMode[I] := pmFull;
    If PMode[I] = pmQuick Then PMode[I] := pmFull;
  End;
  If (OptStyle < 0) Or (OptStyle > 2) Then OptStyle := 0;
End;

Procedure InitFs;
Var K : LongInt;
Begin
  For K := 0 To 1 Do
  Begin
    GetMem(Ent[K], SizeOf(TEntry) * MaxEnt);
    NEnt[K] := 0; CurI[K] := 0; TopI[K] := 0;
    PMode[K] := pmFull; PSort[K] := srName; PFiltK[K] := 0; PFilter[K] := '*.*'; PLast[K] := '';
  End;
  PMode[0] := pmFull; PMode[1] := pmFull;
  GetMem(TreeP, SizeOf(TStrArr));
  GetMem(FoundP, SizeOf(TStrArr));
  GetMem(LstP, SizeOf(TStrArr));
  PoolTop := 0;
  NTree := 0; TreeCur := 0; TreeTop := 0; TreeDrive := 'C';
  NFound := 0; NHist := 0; HistPos := 0;
  OptHidden := False; OptConfDel := True; OptConfCopy := True; OptConfOver := True; OptKeyBar := True;
  OptMiniStatus := True; OptClock := True; OptInsMoves := True; OptDirsFirst := True; OptAutoMenu := False;
  OptSaveOnExit := True; OptExecWin := False; FindMaxD := 30;
  OptStyle := 0; OptEditor := 0; OptViewer := 0; OptEditCmd := 'NOTEPAD !.!'; OptViewCmd := '';
  FindMask := '*.*'; FindText := ''; FindCase := False;
  Stop_ := False;
End;
{ ==================================================================== }
{ Fenetre : etat                                                        }
{ ==================================================================== }

Const
  ChW = 8; ChH = 16;                     { cellule de la police systeme }
  KbH = 24; CmdH = 20;                   { barre des touches, ligne de commande }
  MaxEdL = 16000;                        { lignes de l'editeur }
  MaxOut = 1500;                         { lignes de l'ecran de sortie }
  { modes de la fenetre }
  mdPanels = 0; mdView = 1; mdEdit = 2; mdHelp = 3; mdOutput = 4; mdList = 5; mdDrive = 6;
  { listes (mdList) }
  lkHist = 0; lkMenu = 1; lkFound = 2; lkNcd = 3;
  { touches de modification (barre des touches) }
  kmNone = 0; kmShift = 1; kmCtrl = 2; kmAlt = 3;
  { commandes des menus }
  cmLeft0 = 100;    { + 0..15 : panneau de gauche }
  cmRight0 = 120;   { + 0..15 : panneau de droite }
  pcBrief = 0; pcFull = 1; pcInfo = 2; pcTree = 3; pcQuick = 4; pcOnOff = 5; pcName = 6; pcExt = 7;
  pcTime = 8; pcSize = 9; pcUnsorted = 10; pcReread = 11; pcFilter = 12; pcDrive = 13;
  cmHelp = 200; cmUserMenu = 201; cmView = 202; cmEdit = 203; cmCopy = 204; cmRenMov = 205; cmMkDir = 206;
  cmDelete = 207; cmAttrib = 208; cmSelGroup = 209; cmUnselGroup = 210; cmInvertSel = 211; cmRestoreSel = 212;
  cmQuit = 213; cmEditNew = 214; cmCopyHere = 215; cmRenHere = 216; cmDirSize = 217;
  cmDiskCopy = 230; cmFormat = 231; cmLabel = 232; cmDiskInfo = 233;
  cmNcd = 240; cmFind = 241; cmHistory = 242; cmMaximize = 243; cmSwap = 244; cmPanelsOnOff = 245;
  cmCompare = 246; cmRunWin = 247; cmEditMenu = 248; cmEditExt = 249; cmOutput = 250; cmTogglePanel = 251;
  cmConfig = 260; cmEditors = 261; cmStyle0 = 262; cmKeyBar = 266; cmClock = 267; cmMiniStatus = 268;
  cmHidden = 269; cmSaveCfg = 270;
  cmAbout = 280; cmKeys = 281;
  cmF0 = 300;       { + 1..10 : touche de fonction (barre des touches) }

Type
  TEdLines = Array[0..MaxEdL - 1] Of String;
  PEdLines = ^TEdLines;

Var
  Hab, Hmq, Frame, Client, MenuHw, Hps, CW, CH : LongInt;
  GQmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..8191] Of Byte;
  MenuLen : LongInt;
  UX1, UY1, UX2, UY2 : LongInt;
  IcX, IcY : LongInt;
  Mode, Side, KeyMod : LongInt;
  PanY2, CmdY, KbY : LongInt;            { bas des panneaux, ligne de commande, touches }
  PanelsOn : Boolean;                     { Ctrl+O : ecran de sortie }
  CmdLine : String;
  CmdPos : LongInt;
  StatusMsg : String;
  Busy : Boolean;
  { ecran de sortie (commandes) }
  OutL : PEdLines;
  NOut : LongInt;
  { visualiseur }
  VBuf : TBuf;
  VName : String;
  VHex, VWrap, VTrunc : Boolean;
  VTop, VCol, VHiOfs, VHiLen, VSize : LongInt;
  VSearch : String;
  VCase : Boolean;
  VIsHelp : Boolean;
  { editeur }
  EdL : PEdLines;
  EdN, EdX, EdY, EdTop, EdLeft : LongInt;
  EdName : String;
  EdMod, EdIns : Boolean;
  EdSearch : String;
  { liste modale (historique, menu utilisateur, fichiers trouves, NCD) }
  LsKind, LsCur, LsTop, LsN : LongInt;
  LsTitle : String;
  LsItem : Array[0..299] Of String;
  LsCmd : Array[0..299] Of String;       { menu utilisateur : commandes (lignes separees par #13) }
  LsQuick : String;                       { recherche rapide (NCD) }
  { choix du lecteur (Alt+F1, Alt+F2) }
  DrvSide, DrvCur, NDrv : LongInt;
  DrvL : Array[0..25] Of Char;
  { recherche rapide dans le panneau }
  Quick : String;
  { selection a restaurer }
  PrevSel : Array[0..1, 0..99] Of String;
  NPrevSel : Array[0..1] Of LongInt;
  { execution d'une commande (sortie capturee) }
  ExecPid, ExecT0 : LongInt;
  ExecOn : Boolean;
  ExecOutName, ExecCmd : String;
  ExecF : Text;
  ShieldOk : Boolean;
  { vue rapide }
  QvName : String;
  QvBuf : TBuf;
  LastClock : String;
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
{ Dessin                                                                }
{ ==================================================================== }

Var
  KPBg, KPFg, KPDir, KPSel, KCurBg, KCurFg, KLine, KCmdBg, KCmdFg, KExe : LongInt;
  KbDown : LongInt;

Procedure SetStyle;
Begin
  Case OptStyle Of
    1 :
      Begin
        { OS/2 : listes blanches, curseur bleu marine }
        KPBg := cWhite; KPFg := cBlack; KPDir := cNavy; KPSel := cRed; KCurBg := cNavy; KCurFg := cWhite;
        KLine := cSilver; KCmdBg := cWhite; KCmdFg := cBlack; KExe := cDGreen;
      End;
    2 :
      Begin
        { noir : comme un ecran monochrome }
        KPBg := cBlack; KPFg := cSilver; KPDir := cWhite; KPSel := cYellow; KCurBg := cSilver; KCurFg := cBlack;
        KLine := cGray; KCmdBg := cBlack; KCmdFg := cSilver; KExe := cWhite;
      End;
  Else
    Begin
      { Norton : panneaux bleus, texte cyan, selection jaune, curseur cyan }
      KPBg := cNavy; KPFg := cCyan; KPDir := cWhite; KPSel := cYellow; KCurBg := cTeal; KCurFg := cBlack;
      KLine := cCyan; KCmdBg := cBlack; KCmdFg := cSilver; KExe := cWhite;
    End;
  End;
End;

Function StyleName(K : LongInt) : String;
Var R : String;
Begin
  Case K Of
    1 : R := 'OS/2 (listes blanches)';
    2 : R := 'Noir et blanc';
  Else
    R := 'Norton (panneaux bleus)';
  End;
  StyleName := R;
End;

{ --- disposition --- }

Procedure Layout;
Begin
  If OptKeyBar Then KbY := CH - KbH Else KbY := CH;
  CmdY := KbY - CmdH;
  PanY2 := CmdY - 1;
End;

Procedure PanRect(S : LongInt; Var X1, Y1_, X2, Y2 : LongInt);
Begin
  If S = 0 Then
  Begin
    X1 := 0; X2 := CW Div 2 - 1;
  End
  Else
  Begin
    X1 := CW Div 2; X2 := CW - 1;
  End;
  Y1_ := 0; Y2 := PanY2;
End;

{ zone de la liste du panneau (lignes de fichiers) }
Procedure ListRect(S : LongInt; Var X1, Y1_, X2, Y2 : LongInt);
Var A, B, C, D : LongInt;
Begin
  PanRect(S, A, B, C, D);
  X1 := A + 6; X2 := C - 6;
  Y1_ := B + 25;
  If PMode[S] = pmFull Then Y1_ := Y1_ + 18;
  If OptMiniStatus Then Y2 := D - 26 Else Y2 := D - 6;
End;

Function ListRows(S : LongInt) : LongInt;
Var X1, Y1_, X2, Y2, N : LongInt;
Begin
  ListRect(S, X1, Y1_, X2, Y2);
  N := (Y2 - Y1_ + 1) Div ChH;
  If N < 1 Then N := 1;
  ListRows := N;
End;

Function PageSize(S : LongInt) : LongInt;
Begin
  If PMode[S] = pmBrief Then PageSize := 3 * ListRows(S) Else PageSize := ListRows(S);
End;

Function PanChars(S : LongInt) : LongInt;
Var X1, Y1_, X2, Y2 : LongInt;
Begin
  ListRect(S, X1, Y1_, X2, Y2);
  PanChars := (X2 - X1 - 4) Div ChW;
End;

Procedure EnsureVis(S : LongInt);
Var P : LongInt;
Begin
  P := PageSize(S);
  If CurI[S] < TopI[S] Then TopI[S] := CurI[S];
  If PMode[S] = pmBrief Then
  Begin
    If CurI[S] >= TopI[S] + P Then TopI[S] := CurI[S] - P + 1;
  End
  Else If CurI[S] >= TopI[S] + P Then TopI[S] := CurI[S] - P + 1;
  If TopI[S] > NEnt[S] - 1 Then TopI[S] := MaxI(0, NEnt[S] - 1);
  If TopI[S] < 0 Then TopI[S] := 0;
End;

Function IsFilePanel(S : LongInt) : Boolean;
Begin
  IsFilePanel := (PMode[S] = pmBrief) Or (PMode[S] = pmFull);
End;

Procedure InvalPanel(S : LongInt);
Var X1, Y1_, X2, Y2 : LongInt;
Begin
  PanRect(S, X1, Y1_, X2, Y2);
  InvalBand(X1, Y1_, X2 + 1, Y2 + 1);
End;

Procedure InvalPanels;
Begin
  InvalBand(0, 0, CW, PanY2 + 1);
End;

Procedure InvalCmd;
Begin
  InvalBand(0, CmdY, CW, CmdY + CmdH);
End;

Procedure InvalKeys;
Begin
  InvalBand(0, KbY, CW, CH);
End;

{ texte sur une ligne de cellules, fond rempli }
Procedure CellTxt(X, Y, W : LongInt; S : String; Fg, Bg : LongInt);
Begin
  FBar(X, Y, X + W - 1, Y + ChH - 1, Bg);
  OutTxt(X, Y, Fit(S, W), Fg, Bg);
End;

{ --- panneau de fichiers --- }

Function EntColor(S : LongInt; Var E : TEntry) : LongInt;
Var C : LongInt; X : String;
Begin
  C := KPFg;
  If IsDirE(E) Then C := KPDir
  Else
  Begin
    X := ExtName(E.Name);
    If (X = 'EXE') Or (X = 'COM') Or (X = 'CMD') Or (X = 'BAT') Then C := KExe;
  End;
  If E.Sel Then C := KPSel;
  If S < 0 Then ;
  EntColor := C;
End;

Function SizeText(Var E : TEntry) : String;
Var R : String;
Begin
  If E.Name = '..' Then R := '<R'#144'P-SUP>'
  Else If IsDirE(E) Then R := '<SOUS-R'#144'P>'
  Else R := FmtSize(E.Size);
  SizeText := R;
End;

Function NameCol(Nm : String; W : LongInt) : String;
Var R : String;
Begin
  If Length(Nm) > W Then R := Copy(Nm, 1, W - 1) + '}' Else R := Nm;
  NameCol := R;
End;

Procedure PaintFileRows(S : LongInt);
Var X1, Y1_, X2, Y2, Rows, R, C, I, Fg, Bg, Cw_, Nw, X, Y, Px : LongInt; Cur : Boolean; T : String;
Begin
  ListRect(S, X1, Y1_, X2, Y2);
  Rows := ListRows(S);
  If PMode[S] = pmBrief Then
  Begin
    Cw_ := (X2 - X1 + 1) Div 3;
    For C := 0 To 2 Do
      For R := 0 To Rows - 1 Do
      Begin
        I := TopI[S] + C * Rows + R;
        X := X1 + C * Cw_; Y := Y1_ + R * ChH;
        If I < NEnt[S] Then
        Begin
          Cur := (I = CurI[S]) And (S = Side) And (Mode <> mdOutput);
          Fg := EntColor(S, Ent[S]^[I]); Bg := KPBg;
          If Cur Then
          Begin
            Bg := KCurBg;
            If Not Ent[S]^[I].Sel Then Fg := KCurFg;
          End;
          T := NameCol(Ent[S]^[I].Name, (Cw_ - 8) Div ChW);
          FBar(X + 1, Y, X + Cw_ - 3, Y + ChH - 1, Bg);
          OutTxt(X + 4, Y, T, Fg, Bg);
        End;
      End;
    For C := 1 To 2 Do VLine(X1 + C * Cw_ - 1, Y1_, Y1_ + Rows * ChH - 1, KLine);
  End
  Else
  Begin
    Nw := PanChars(S) - 26;
    If Nw < 6 Then Nw := 6;
    For R := 0 To Rows - 1 Do
    Begin
      I := TopI[S] + R;
      Y := Y1_ + R * ChH;
      If I < NEnt[S] Then
      Begin
        Cur := (I = CurI[S]) And (S = Side) And (Mode <> mdOutput);
        Fg := EntColor(S, Ent[S]^[I]); Bg := KPBg;
        If Cur Then
        Begin
          Bg := KCurBg;
          If Not Ent[S]^[I].Sel Then Fg := KCurFg;
        End;
        FBar(X1 + 1, Y, X2 - 1, Y + ChH - 1, Bg);
        Px := X1 + 4;
        OutTxt(Px, Y, NameCol(Ent[S]^[I].Name, Nw), Fg, Bg);
        Px := Px + Nw * ChW + 8;
        OutTxt(Px, Y, PadL(SizeText(Ent[S]^[I]), 10), Fg, Bg);
        Px := Px + 10 * ChW + 8;
        If Ent[S]^[I].Name <> '..' Then
        Begin
          OutTxt(Px, Y, FmtDate(Ent[S]^[I].FDate), Fg, Bg);
          OutTxt(Px + 9 * ChW, Y, FmtTime(Ent[S]^[I].FTime), Fg, Bg);
        End;
      End;
    End;
    Px := X1 + 4 + Nw * ChW + 3;
    VLine(Px, Y1_ - 18, Y1_ + Rows * ChH - 1, KLine);
    Px := Px + 10 * ChW + 8;
    VLine(Px, Y1_ - 18, Y1_ + Rows * ChH - 1, KLine);
    VLine(Px + 9 * ChW - 4, Y1_ - 18, Y1_ + Rows * ChH - 1, KLine);
  End;
End;

Procedure PaintColHead(S : LongInt);
Var X1, Y1_, X2, Y2, Nw, Px : LongInt;
Begin
  If PMode[S] <> pmFull Then Exit;
  ListRect(S, X1, Y1_, X2, Y2);
  Nw := PanChars(S) - 26;
  If Nw < 6 Then Nw := 6;
  Px := X1 + 4 + Nw * ChW + 3;
  Raised(X1, Y1_ - 18, Px - 1, Y1_ - 2);
  OutTxt((X1 + Px) Div 2 - 12, Y1_ - 18, 'Nom', cBlack, cSilver);
  Raised(Px, Y1_ - 18, Px + 10 * ChW + 7, Y1_ - 2);
  OutTxt(Px + 16, Y1_ - 18, 'Taille', cBlack, cSilver);
  Px := Px + 10 * ChW + 8;
  Raised(Px, Y1_ - 18, Px + 9 * ChW - 5, Y1_ - 2);
  OutTxt(Px + 12, Y1_ - 18, 'Date', cBlack, cSilver);
  Raised(Px + 9 * ChW - 4, Y1_ - 18, X2, Y1_ - 2);
  OutTxt(Px + 9 * ChW + 2, Y1_ - 18, 'Heure', cBlack, cSilver);
End;

Procedure PaintMiniStatus(S : LongInt);
Var X1, Y1_, X2, Y2, N, W : LongInt; T : String; E : TEntry;
Begin
  If Not OptMiniStatus Then Exit;
  PanRect(S, X1, Y1_, X2, Y2);
  Sunken(X1 + 4, Y2 - 23, X2 - 4, Y2 - 4, KPBg);
  W := (X2 - X1 - 16) Div ChW;
  N := NSelected(S);
  If N > 0 Then
  Begin
    T := Thou(SelBytes(S)) + ' octets dans ' + IStr(N) + ' fichier(s) s'#130'lectionn'#130'(s)';
    OutTxt((X1 + X2) Div 2 - MinI(Length(T), W) * ChW Div 2, Y2 - 22, Fit(T, W * ChW), KPSel, KPBg);
  End
  Else If (NEnt[S] > 0) And (CurI[S] < NEnt[S]) Then
  Begin
    E := Ent[S]^[CurI[S]];
    OutTxt(X1 + 8, Y2 - 22, NameCol(E.Name, MaxI(6, W - 26)), KPFg, KPBg);
    If E.Name <> '..' Then
      T := PadL(SizeText(E), 10) + ' ' + FmtDate(E.FDate) + ' ' + FmtTime(E.FTime)
    Else T := PadL(SizeText(E), 10);
    OutTxt(X2 - 8 - Length(T) * ChW, Y2 - 22, T, KPFg, KPBg);
  End;
End;

Procedure PanelTitle(S : LongInt; T : String);
Var X1, Y1_, X2, Y2, W : LongInt; Act : Boolean;
Begin
  PanRect(S, X1, Y1_, X2, Y2);
  Act := (S = Side) And (Mode <> mdOutput);
  W := X2 - X1 - 12;
  If Length(T) * ChW > W Then T := '...' + Copy(T, Length(T) - W Div ChW + 4, 255);
  If Act Then
  Begin
    FBar(X1 + 3, Y1_ + 3, X2 - 3, Y1_ + 20, cNavy);
    OutTxt((X1 + X2) Div 2 - Length(T) * ChW Div 2, Y1_ + 4, T, cWhite, cNavy);
  End
  Else
  Begin
    FBar(X1 + 3, Y1_ + 3, X2 - 3, Y1_ + 20, cGray);
    OutTxt((X1 + X2) Div 2 - Length(T) * ChW Div 2, Y1_ + 4, T, cSilver, cGray);
  End;
End;

Procedure PaintFilePanel(S : LongInt);
Var X1, Y1_, X2, Y2, A, B, C, D : LongInt; T : String;
Begin
  PanRect(S, X1, Y1_, X2, Y2);
  Raised(X1, Y1_, X2, Y2);
  T := PPath[S];
  If PFiltK[S] = 1 Then T := T + ' [ex'#130'cutables]'
  Else If PFiltK[S] = 2 Then T := T + ' [' + PFilter[S] + ']';
  PanelTitle(S, T);
  ListRect(S, A, B, C, D);
  Sunken(A - 2, B - 2, C + 2, D + 2, KPBg);
  PaintColHead(S);
  PaintFileRows(S);
  PaintMiniStatus(S);
End;

{ --- panneau d'information (decrit l'autre panneau) --- }

Procedure InfoLn(X, Y, W : LongInt; S : String; C : LongInt);
Begin
  OutTxt(X, Y, Fit(S, W), C, KPBg);
End;

Procedure PaintInfoPanel(S : LongInt);
Var X1, Y1_, X2, Y2, A, B, C, D, Y, W, O, NF, H, N, K : LongInt; Tot, Fr, By : Double; Dr : Char;
    Bf : Array[0..1023] Of Byte; L : String;
Begin
  PanRect(S, X1, Y1_, X2, Y2);
  Raised(X1, Y1_, X2, Y2);
  PanelTitle(S, 'Information');
  A := X1 + 6; B := Y1_ + 25; C := X2 - 6; D := Y2 - 6;
  Sunken(A - 2, B - 2, C + 2, D + 2, KPBg);
  O := 1 - S;
  W := C - A - 12;
  Y := B + 6;
  InfoLn(A + 8, Y, W, AppTitle + ' ' + NcVersion + ' pour OS/2-0', KPDir); Y := Y + 18;
  InfoLn(A + 8, Y, W, '(d''apr'#138's NC.PAS de NORTONCOMMANDER-0)', KPFg); Y := Y + 28;
  InfoLn(A + 8, Y, W, 'M'#130'moire totale     : ' + Thou(MemKb(17)) + ' Ko', KPFg); Y := Y + 18;
  InfoLn(A + 8, Y, W, 'M'#130'moire disponible : ' + Thou(MemKb(19)) + ' Ko', KPFg); Y := Y + 28;
  Dr := UpCase(PPath[O][1]);
  L := VolLabel(Dr);
  If L = '' Then L := '(sans nom)';
  InfoLn(A + 8, Y, W, 'Disque ' + Dr + ': - volume ' + L, KPDir); Y := Y + 18;
  If DiskSpace(Dr, Tot, Fr) Then
  Begin
    InfoLn(A + 8, Y, W, 'Taille totale : ' + Thou(Tot) + ' octets', KPFg); Y := Y + 18;
    If Tot > 0 Then InfoLn(A + 8, Y, W, 'Espace libre  : ' + Thou(Fr) + ' octets (' + IStr(Round(Fr * 100 / Tot)) + ' %)', KPFg)
    Else InfoLn(A + 8, Y, W, 'Espace libre  : ' + Thou(Fr) + ' octets', KPFg);
    Y := Y + 18;
    { barre d'occupation }
    If Tot > 0 Then
    Begin
      Sunken(A + 8, Y + 2, C - 8, Y + 12, cWhite);
      K := Round((C - A - 20) * (Tot - Fr) / Tot);
      If K > 0 Then FBar(A + 9, Y + 3, A + 9 + K, Y + 11, cRed);
      Y := Y + 20;
    End;
  End;
  Y := Y + 10;
  InfoLn(A + 8, Y, W, 'R'#130'pertoire ' + PPath[O], KPDir); Y := Y + 18;
  DirStats(O, NF, By);
  InfoLn(A + 8, Y, W, IStr(NF) + ' fichier(s), ' + Thou(By) + ' octets', KPFg); Y := Y + 18;
  N := NSelected(O);
  If N > 0 Then
  Begin
    InfoLn(A + 8, Y, W, 'S'#130'lection : ' + IStr(N) + ' fichier(s), ' + Thou(SelBytes(O)) + ' octets', KPSel);
    Y := Y + 18;
  End;
  { DIRINFO : description du repertoire, comme Norton Commander }
  If FOpenRead(JoinP(PPath[O], 'DIRINFO'), H) Then
  Begin
    N := FRead(H, @Bf, SizeOf(Bf));
    DosClose(H);
    Y := Y + 10;
    L := '';
    For K := 0 To N - 1 Do
    Begin
      If (Bf[K] = 10) Or (K = N - 1) Then
      Begin
        If (Bf[K] <> 10) And (Bf[K] <> 13) Then L := L + Chr(Bf[K]);
        If Y + ChH < D Then InfoLn(A + 8, Y, W, L, KPFg);
        Y := Y + ChH; L := '';
      End
      Else If Bf[K] <> 13 Then L := L + Chr(Bf[K]);
    End;
  End;
End;

{ --- arbre --- }

Procedure PaintTreePanel(S : LongInt);
Var X1, Y1_, X2, Y2, A, B, C, D, Rows, R, I, X, Y, Fg, Bg, Dp : LongInt; T : String;
Begin
  PanRect(S, X1, Y1_, X2, Y2);
  Raised(X1, Y1_, X2, Y2);
  PanelTitle(S, 'Arbre ' + TreeDrive + ':');
  A := X1 + 6; B := Y1_ + 25; C := X2 - 6; D := Y2 - 6;
  Sunken(A - 2, B - 2, C + 2, D + 2, KPBg);
  Rows := (D - B) Div ChH;
  If TreeCur < TreeTop Then TreeTop := TreeCur;
  If TreeCur >= TreeTop + Rows Then TreeTop := TreeCur - Rows + 1;
  For R := 0 To Rows - 1 Do
  Begin
    I := TreeTop + R;
    If I >= NTree Then Break;
    Y := B + R * ChH;
    Dp := TreeD[I];
    X := A + 6 + Dp * 2 * ChW;
    If I = 0 Then T := TreeP^[0] Else T := LastPart(TreeP^[I]);
    Fg := KPFg; Bg := KPBg;
    If I = TreeCur Then
    Begin
      If S = Side Then
      Begin
        Fg := KCurFg; Bg := KCurBg;
      End
      Else Fg := KPSel;
    End;
    If Dp > 0 Then
    Begin
      HLine(X - 2 * ChW + 4, X - 3, Y + 8, KLine);
      VLine(X - 2 * ChW + 4, Y, Y + 8, KLine);
      If (I + 1 < NTree) And (TreeD[I + 1] >= Dp) Then VLine(X - 2 * ChW + 4, Y + 8, Y + ChH - 1, KLine);
    End;
    FBar(X, Y, X + Length(T) * ChW + 3, Y + ChH - 1, Bg);
    OutTxt(X + 2, Y, Fit(T, C - X - 4), Fg, Bg);
  End;
End;

{ --- vue rapide (le fichier sous le curseur de l'autre panneau) --- }

Procedure LoadQuick(O : LongInt);
Var N, H : LongInt; Nm : String; Tmp : Array[0..8191] Of Byte;
Begin
  Nm := '';
  If (NEnt[O] > 0) And IsFilePanel(O) Then Nm := JoinP(PPath[O], CurName(O));
  If Nm = QvName Then Exit;
  QvName := Nm;
  QvBuf.Len := 0;
  If (Nm = '') Or (CurName(O) = '..') Or IsDirE(Ent[O]^[CurI[O]]) Then Exit;
  If FOpenRead(Nm, H) Then
  Begin
    N := FRead(H, @Tmp, SizeOf(Tmp));
    If N > 0 Then BufAddB(QvBuf, @Tmp, N);
    DosClose(H);
  End;
End;

Function HexB(V : LongInt) : String;
Const Hx : Array[0..15] Of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
  HexB := Hx[(V Shr 4) And 15] + Hx[V And 15];
End;

Function HexL(V : LongInt) : String;
Begin
  HexL := HexB(V Shr 24) + HexB(V Shr 16) + HexB(V Shr 8) + HexB(V);
End;

Procedure PaintQuickPanel(S : LongInt);
Var X1, Y1_, X2, Y2, A, B, C, D, Rows, R, K, P, W, O, NF, ND : LongInt; L : String; Bin : Boolean; By : Double;
Begin
  O := 1 - S;
  PanRect(S, X1, Y1_, X2, Y2);
  Raised(X1, Y1_, X2, Y2);
  PanelTitle(S, 'Vue rapide');
  A := X1 + 6; B := Y1_ + 25; C := X2 - 6; D := Y2 - 6;
  Sunken(A - 2, B - 2, C + 2, D + 2, KPBg);
  Rows := (D - B) Div ChH;
  W := (C - A - 8) Div ChW;
  LoadQuick(O);
  If (NEnt[O] = 0) Or Not IsFilePanel(O) Then Exit;
  If IsDirE(Ent[O]^[CurI[O]]) Then
  Begin
    OutTxt(A + 8, B + 8, Fit('R'#130'pertoire ' + CurName(O), W * ChW), KPDir, KPBg);
    If CurName(O) <> '..' Then
    Begin
      NF := 0; ND := 0; By := 0;
      PoolTop := 0;
      DirSize(JoinP(PPath[O], CurName(O)), NF, ND, By, 0);
      OutTxt(A + 8, B + 34, Fit(IStr(NF) + ' fichier(s), ' + IStr(ND) + ' sous-r'#130'pertoire(s)', W * ChW), KPFg, KPBg);
      OutTxt(A + 8, B + 52, Fit(Thou(By) + ' octets', W * ChW), KPFg, KPBg);
    End;
    Exit;
  End;
  Bin := False;
  For K := 0 To MinI(QvBuf.Len, 512) - 1 Do If QvBuf.P^[K] = 0 Then Bin := True;
  P := 0;
  For R := 0 To Rows - 1 Do
  Begin
    If P >= QvBuf.Len Then Break;
    L := '';
    If Bin Then
    Begin
      L := HexB(P Shr 8) + HexB(P) + ' ';
      For K := 0 To 7 Do If P + K < QvBuf.Len Then L := L + ' ' + HexB(QvBuf.P^[P + K]);
      L := L + '  ';
      For K := 0 To 7 Do
        If P + K < QvBuf.Len Then
          If QvBuf.P^[P + K] >= 32 Then L := L + Chr(QvBuf.P^[P + K]) Else L := L + '.';
      P := P + 8;
    End
    Else
    Begin
      While (P < QvBuf.Len) And (QvBuf.P^[P] <> 10) Do
      Begin
        K := QvBuf.P^[P];
        If K = 9 Then L := L + '    '
        Else If (K >= 32) And (Length(L) < 250) Then L := L + Chr(K);
        Inc(P);
      End;
      Inc(P);
    End;
    OutTxt(A + 6, B + 4 + R * ChH, Fit(L, W * ChW), KPFg, KPBg);
  End;
End;

{ --- ecran de sortie (commandes) --- }

Procedure PaintOutput(X1, Y1_, X2, Y2 : LongInt);
Var Rows, R, I : LongInt;
Begin
  FBar(X1, Y1_, X2, Y2, cBlack);
  Rows := (Y2 - Y1_ + 1) Div ChH;
  For R := 0 To Rows - 1 Do
  Begin
    I := NOut - Rows + R;
    If (I >= 0) And (I < NOut) Then OutTxt(X1 + 4, Y1_ + R * ChH, Fit(OutL^[I], X2 - X1 - 8), cSilver, cBlack);
  End;
End;

Procedure PaintPanel(S : LongInt);
Var X1, Y1_, X2, Y2 : LongInt;
Begin
  PanRect(S, X1, Y1_, X2, Y2);
  If (UX2 < X1) Or (UX1 > X2) Then Exit;
  Case PMode[S] Of
    pmInfo : PaintInfoPanel(S);
    pmTree : PaintTreePanel(S);
    pmQuick : PaintQuickPanel(S);
    pmOff : PaintOutput(X1, Y1_, X2, Y2);
  Else
    PaintFilePanel(S);
  End;
End;

{ --- ligne de commande --- }

Procedure PaintCmd;
Var P, T, X, Mx : LongInt; Cl : String;
Begin
  FBar(0, CmdY, CW - 1, CmdY + CmdH - 1, KCmdBg);
  P := 0;
  If (Mode = mdPanels) Or (Mode = mdList) Or (Mode = mdDrive) Then
  Begin
    T := Length(PPath[Side]) + 1;
    OutTxt(4, CmdY + 2, PPath[Side] + '>', KCmdFg, KCmdBg);
    X := 4 + T * ChW;
    Mx := (CW - X - 120) Div ChW;
    If CmdPos > Mx Then P := CmdPos - Mx;
    OutTxt(X, CmdY + 2, Copy(CmdLine, P + 1, Mx), KCmdFg, KCmdBg);
    { curseur }
    FBar(X + (CmdPos - P) * ChW, CmdY + 15, X + (CmdPos - P) * ChW + ChW - 1, CmdY + 17, KCmdFg);
  End
  Else If Mode = mdOutput Then
  Begin
    OutTxt(4, CmdY + 2, PPath[Side] + '>' + CmdLine, KCmdFg, KCmdBg);
    X := 4 + (Length(PPath[Side]) + 1 + CmdPos) * ChW;
    FBar(X, CmdY + 15, X + ChW - 1, CmdY + 17, KCmdFg);
  End;
  { message et horloge a droite }
  Cl := '';
  If OptClock Then Cl := LastClock;
  If Cl <> '' Then
  Begin
    If OptStyle = 1 Then OutTxt(CW - 8 - Length(Cl) * ChW, CmdY + 2, Cl, cNavy, KCmdBg)
    Else OutTxt(CW - 8 - Length(Cl) * ChW, CmdY + 2, Cl, cYellow, KCmdBg);
  End;
  If (StatusMsg <> '') And ((Mode = mdPanels) Or (Mode = mdOutput)) Then
  Begin
    X := 4 + (Length(PPath[Side]) + 2 + Length(CmdLine)) * ChW + 24;
    Mx := CW - 24 - Length(Cl) * ChW - X;
    If Mx > 80 Then OutTxt(CW - 16 - Length(Cl) * ChW - MinI(Length(StatusMsg) * ChW, Mx), CmdY + 2,
                           Fit(StatusMsg, Mx), cGray, KCmdBg);
  End;
End;

{ --- barre des touches de fonction --- }

Function KeyLabel(K : LongInt) : String;
Var R : String;
Begin
  R := '';
  Case Mode Of
    mdView, mdHelp :
      Case K Of
        1 : R := 'Aide';
        2 : If VHex Then R := '' Else If VWrap Then R := 'Entier' Else R := 'Coup'#130;
        3 : R := 'Quitter';
        4 : If VHex Then R := 'ASCII' Else R := 'Hexa';
        5 : R := 'Atteind';
        7 : R := 'Cherche';
        8 : R := 'Suivant';
        10 : R := 'Quitter';
      End;
    mdEdit :
      Case K Of
        1 : R := 'Aide';
        2 : R := 'Enreg';
        5 : R := 'Atteind';
        7 : R := 'Cherche';
        8 : R := 'SupLign';
        10 : R := 'Quitter';
      End;
  Else
    Case KeyMod Of
      kmShift :
        Case K Of
          4 : R := 'Nouveau';
          5 : R := 'Copier';
          6 : R := 'Renomm';
          9 : R := 'Config';
        End;
      kmAlt :
        Case K Of
          1 : R := 'Gauche';
          2 : R := 'Droite';
          7 : R := 'Cherche';
          8 : R := 'Histor';
          9 : R := 'Agrandi';
          10 : R := 'Arbre';
        End;
      kmCtrl :
        Case K Of
          1 : R := 'Gauche';
          2 : R := 'Droite';
          3 : R := 'Nom';
          4 : R := 'Exten';
          5 : R := 'Heure';
          6 : R := 'Taille';
          7 : R := 'NonTri';
        End;
    Else
      Case K Of
        1 : R := 'Aide';
        2 : R := 'Menu';
        3 : R := 'Voir';
        4 : R := #144'diter';
        5 : R := 'Copier';
        6 : R := 'RenD'#130'p';
        7 : R := 'R'#130'pCr'#130;
        8 : R := 'Suppr';
        9 : R := 'MenuD'#130'r';
        10 : R := 'Quitter';
      End;
    End;
  End;
  KeyLabel := R;
End;

Procedure KeyRect(K : LongInt; Var X1, X2 : LongInt);
Begin
  X1 := (K - 1) * CW Div 10; X2 := K * CW Div 10 - 2;
End;

Procedure PaintKeys;
Var K, X1, X2 : LongInt; L : String;
Begin
  If Not OptKeyBar Then Exit;
  FBar(0, KbY, CW - 1, CH - 1, cSilver);
  For K := 1 To 10 Do
  Begin
    KeyRect(K, X1, X2);
    L := KeyLabel(K);
    If KbDown = K Then
    Begin
      FBar(X1 + 1, KbY + 2, X2, CH - 2, cSilver);
      Edge(X1 + 1, KbY + 2, X2, CH - 2, cGray, cWhite);
    End
    Else Raised(X1 + 1, KbY + 2, X2, CH - 2);
    OutTxt(X1 + 5, KbY + 4, IStr(K), cNavy, cSilver);
    If L <> '' Then OutTxt(X1 + 5 + Length(IStr(K)) * ChW + 4, KbY + 4, Fit(L, X2 - X1 - 24), cBlack, cSilver)
    Else OutTxt(X1 + 5 + Length(IStr(K)) * ChW + 4, KbY + 4, '', cGray, cSilver);
  End;
End;

{ --- visualiseur --- }

Function VByte(P : LongInt) : LongInt;
Begin
  If (P >= 0) And (P < VBuf.Len) Then VByte := VBuf.P^[P] Else VByte := 0;
End;

Function ViewCols : LongInt;
Begin
  ViewCols := (CW - 16) Div ChW;
End;

Function ViewRows : LongInt;
Begin
  ViewRows := (KbY - 24 - 4) Div ChH;
End;

{ fin de la ligne affichee qui commence en P (coupure a W colonnes si VWrap) }
Function LineEnd(P : LongInt) : LongInt;
Var C, W : LongInt;
Begin
  W := ViewCols;
  C := 0;
  While (P < VBuf.Len) And (VBuf.P^[P] <> 10) Do
  Begin
    If VBuf.P^[P] = 9 Then C := (C Div 8 + 1) * 8 Else If VBuf.P^[P] <> 13 Then Inc(C);
    If VWrap And (C > W) Then
    Begin
      LineEnd := P;
      Exit;
    End;
    Inc(P);
  End;
  LineEnd := P;
End;

Function NextLineOf(P : LongInt) : LongInt;
Var E : LongInt;
Begin
  If VHex Then
  Begin
    NextLineOf := P + 16;
    Exit;
  End;
  E := LineEnd(P);
  If (E < VBuf.Len) And (VBuf.P^[E] = 10) Then Inc(E);
  NextLineOf := E;
End;

Function PrevLineOf(P : LongInt) : LongInt;
Var S, Q, Last : LongInt;
Begin
  If VHex Then
  Begin
    PrevLineOf := MaxI(0, P - 16);
    Exit;
  End;
  If P <= 0 Then
  Begin
    PrevLineOf := 0;
    Exit;
  End;
  { debut de la ligne logique precedente }
  S := P - 1;
  If (S >= 0) And (VBuf.P^[S] = 10) Then Dec(S);
  While (S >= 0) And (VBuf.P^[S] <> 10) Do Dec(S);
  S := S + 1;
  { avec coupure : le dernier morceau avant P }
  Last := S; Q := S;
  While Q < P Do
  Begin
    Last := Q;
    Q := NextLineOf(Q);
    If Q <= Last Then Break;
  End;
  PrevLineOf := Last;
End;

Function ByteShown(K : LongInt) : Char;
Begin
  If (K < 32) And (K <> 9) Then ByteShown := '.' Else ByteShown := Chr(K);
End;

Procedure PaintViewer;
Var Rows, R, P, K, E, C, X, Y, Pct, Fg, Bg : LongInt; L, T : String;
Begin
  { titre }
  FBar(0, 0, CW - 1, 21, cSilver);
  Edge(0, 0, CW - 1, 21, cWhite, cGray);
  If VIsHelp Then T := 'Aide de North Commander'
  Else T := 'Voir : ' + VName;
  OutTxt(8, 3, Fit(T, CW Div 2), cBlack, cSilver);
  P := VTop;
  For R := 1 To ViewRows Do If P < VBuf.Len Then P := NextLineOf(P);
  If VBuf.Len > 0 Then Pct := Round(100.0 * MinI(P, VBuf.Len) / VBuf.Len) Else Pct := 100;
  If VHex Then T := 'Hexa' Else If VWrap Then T := 'Texte coup'#130 Else T := 'Texte';
  T := T + '   Octet ' + IStr(VTop) + ' / ' + IStr(VSize) + '   ' + IStr(Pct) + ' %';
  If VTrunc Then T := T + ' (tronqu'#130')';
  OutTxt(CW - 12 - Length(T) * ChW, 3, T, cNavy, cSilver);
  { texte }
  FBar(0, 22, CW - 1, KbY - 1, KPBg);
  Rows := ViewRows;
  P := VTop;
  For R := 0 To Rows - 1 Do
  Begin
    If P >= VBuf.Len Then Break;
    Y := 26 + R * ChH;
    If VHex Then
    Begin
      L := HexL(P) + ':  ';
      For K := 0 To 15 Do
      Begin
        If P + K < VBuf.Len Then L := L + HexB(VBuf.P^[P + K]) + ' ' Else L := L + '   ';
        If K = 7 Then L := L + ' ';
      End;
      L := L + ' ';
      For K := 0 To 15 Do If P + K < VBuf.Len Then L := L + ByteShown(VBuf.P^[P + K]);
      OutTxt(8, Y, L, KPFg, KPBg);
      { surlignage de la recherche }
      If (VHiLen > 0) And (VHiOfs >= P) And (VHiOfs < P + 16) Then
      Begin
        K := VHiOfs - P;
        X := 8 + (11 + K * 3 + Ord(K > 7)) * ChW;
        FBar(X, Y, X + 2 * ChW - 1, Y + ChH - 1, KPSel);
        OutTxt(X, Y, HexB(VBuf.P^[VHiOfs]), KCurFg, KPSel);
      End;
      P := P + 16;
    End
    Else
    Begin
      E := LineEnd(P);
      L := ''; C := 0;
      K := P;
      While (K < E) And (Length(L) < 250) Do
      Begin
        If VBuf.P^[K] = 9 Then
        Begin
          Repeat
            L := L + ' '; Inc(C);
          Until (C Mod 8 = 0) Or (Length(L) >= 250);
        End
        Else If VBuf.P^[K] <> 13 Then
        Begin
          L := L + ByteShown(VBuf.P^[K]); Inc(C);
        End;
        Inc(K);
      End;
      If Not VWrap Then L := Copy(L, VCol + 1, 255);
      Fg := KPFg; Bg := KPBg;
      OutTxt(8, Y, Fit(L, CW - 16), Fg, Bg);
      If (VHiLen > 0) And (VHiOfs >= P) And (VHiOfs < E) Then
      Begin
        X := 8 + (VHiOfs - P - VCol) * ChW;
        If X >= 8 Then
        Begin
          T := '';
          For K := VHiOfs To MinI(VHiOfs + VHiLen, E) - 1 Do T := T + ByteShown(VBuf.P^[K]);
          FBar(X, Y, X + Length(T) * ChW - 1, Y + ChH - 1, KPSel);
          OutTxt(X, Y, T, KCurFg, KPSel);
        End;
      End;
      P := NextLineOf(P);
    End;
  End;
End;

{ --- editeur --- }

Function EdRows : LongInt;
Begin
  EdRows := (KbY - 24 - 4) Div ChH;
End;

Function EdCols : LongInt;
Begin
  EdCols := (CW - 16) Div ChW;
End;

Procedure PaintEditor;
Var Rows, R, I, Y, X : LongInt; T : String;
Begin
  FBar(0, 0, CW - 1, 21, cSilver);
  Edge(0, 0, CW - 1, 21, cWhite, cGray);
  T := #144'diter : ' + EdName;
  If EdMod Then T := T + ' *';
  OutTxt(8, 3, Fit(T, CW Div 2), cBlack, cSilver);
  T := 'Ligne ' + IStr(EdY + 1) + '/' + IStr(EdN) + '   Colonne ' + IStr(EdX + 1) + '   ';
  If EdIns Then T := T + 'Insertion' Else T := T + 'Remplacement';
  OutTxt(CW - 12 - Length(T) * ChW, 3, T, cNavy, cSilver);
  FBar(0, 22, CW - 1, KbY - 1, KPBg);
  Rows := EdRows;
  For R := 0 To Rows - 1 Do
  Begin
    I := EdTop + R;
    If I >= EdN Then Break;
    Y := 26 + R * ChH;
    OutTxt(8, Y, Fit(Copy(EdL^[I], EdLeft + 1, 255), CW - 16), KPFg, KPBg);
  End;
  { curseur }
  X := 8 + (EdX - EdLeft) * ChW;
  Y := 26 + (EdY - EdTop) * ChH;
  If EdIns Then FBar(X, Y + 13, X + ChW - 1, Y + 15, KPSel)
  Else FBar(X, Y + 8, X + ChW - 1, Y + 15, KPSel);
End;

{ --- liste modale --- }

Procedure ListBox(Var X1, Y1_, X2, Y2 : LongInt);
Var W, H, Rows : LongInt;
Begin
  W := MinI(CW - 60, 640);
  If LsKind = lkNcd Then W := MinI(CW - 60, 560);
  Rows := MinI(LsN, (PanY2 - 120) Div ChH);
  If Rows < 4 Then Rows := 4;
  H := Rows * ChH + 62;
  X1 := (CW - W) Div 2; Y1_ := MaxI(10, (PanY2 - H) Div 2);
  X2 := X1 + W - 1; Y2 := Y1_ + H - 1;
End;

Function ListRowsN : LongInt;
Var X1, Y1_, X2, Y2 : LongInt;
Begin
  ListBox(X1, Y1_, X2, Y2);
  ListRowsN := (Y2 - Y1_ + 1 - 62) Div ChH;
End;

Procedure PaintList;
Var X1, Y1_, X2, Y2, Rows, R, I, Y, Fg, Bg : LongInt; T : String;
Begin
  ListBox(X1, Y1_, X2, Y2);
  FBar(X1 + 6, Y1_ + 6, X2 + 6, Y2 + 6, cBlack);
  Raised(X1, Y1_, X2, Y2);
  FBar(X1 + 3, Y1_ + 3, X2 - 3, Y1_ + 21, cNavy);
  OutTxt((X1 + X2) Div 2 - Length(LsTitle) * ChW Div 2, Y1_ + 4, LsTitle, cWhite, cNavy);
  Sunken(X1 + 8, Y1_ + 26, X2 - 8, Y2 - 26, cWhite);
  Rows := ListRowsN;
  If LsCur < LsTop Then LsTop := LsCur;
  If LsCur >= LsTop + Rows Then LsTop := LsCur - Rows + 1;
  For R := 0 To Rows - 1 Do
  Begin
    I := LsTop + R;
    If I >= LsN Then Break;
    Y := Y1_ + 28 + R * ChH;
    Fg := cBlack; Bg := cWhite;
    If I = LsCur Then
    Begin
      Fg := cWhite; Bg := cNavy;
    End;
    If LsKind = lkNcd Then
    Begin
      FBar(X1 + 10, Y, X2 - 10, Y + ChH - 1, cWhite);
      If I = 0 Then T := TreeP^[0] Else T := LastPart(TreeP^[I]);
      FBar(X1 + 14 + TreeD[I] * 2 * ChW, Y, X1 + 14 + (TreeD[I] * 2 + Length(T)) * ChW + 3, Y + ChH - 1, Bg);
      OutTxt(X1 + 16 + TreeD[I] * 2 * ChW, Y, Fit(T, X2 - X1 - 40 - TreeD[I] * 2 * ChW), Fg, Bg);
    End
    Else CellTxt(X1 + 10, Y, X2 - X1 - 19, ' ' + LsItem[I], Fg, Bg);
  End;
  Case LsKind Of
    lkHist : T := 'Entr'#130'e : reprendre la commande   Echap : fermer';
    lkMenu : T := 'Entr'#130'e ou la touche : ex'#130'cuter   F4 : modifier NC.MNU   Echap : fermer';
    lkFound : T := 'Entr'#130'e : aller au fichier   F3 : voir   Echap : fermer';
    lkNcd : T := 'Entr'#130'e : aller   F2 : relire   F7 : cr'#130'er   Echap   ' + LsQuick;
  Else
    T := 'Entr'#130'e : choisir   Echap : fermer';
  End;
  OutTxt(X1 + 12, Y2 - 22, Fit(T, X2 - X1 - 24), cBlack, cSilver);
End;

{ --- choix du lecteur (Alt+F1, Alt+F2) : boite au milieu du panneau --- }

Procedure DriveBox(Var X1, Y1_, X2, Y2 : LongInt);
Var A, B, C, D, W : LongInt;
Begin
  PanRect(DrvSide, A, B, C, D);
  W := MaxI(220, NDrv * 36 + 24);
  If W > C - A - 10 Then W := C - A - 10;
  X1 := (A + C) Div 2 - W Div 2; X2 := X1 + W - 1;
  Y1_ := (B + D) Div 2 - 60; Y2 := Y1_ + 112;
End;

Procedure DriveCell(K : LongInt; Var X1, Y1_ : LongInt);
Var A, B, C, D, Pr, Row : LongInt;
Begin
  DriveBox(A, B, C, D);
  Pr := (C - A - 16) Div 36;
  If Pr < 1 Then Pr := 1;
  Row := K Div Pr;
  X1 := A + 12 + (K Mod Pr) * 36; Y1_ := B + 30 + Row * 28;
End;

Procedure PaintDrive;
Var X1, Y1_, X2, Y2, K, X, Y : LongInt; T : String; Tot, Fr : Double;
Begin
  DriveBox(X1, Y1_, X2, Y2);
  FBar(X1 + 6, Y1_ + 6, X2 + 6, Y2 + 6, cBlack);
  Raised(X1, Y1_, X2, Y2);
  FBar(X1 + 3, Y1_ + 3, X2 - 3, Y1_ + 21, cNavy);
  If DrvSide = 0 Then T := 'Lecteur du panneau gauche' Else T := 'Lecteur du panneau droit';
  OutTxt((X1 + X2) Div 2 - Length(T) * ChW Div 2, Y1_ + 4, T, cWhite, cNavy);
  For K := 0 To NDrv - 1 Do
  Begin
    DriveCell(K, X, Y);
    If K = DrvCur Then
    Begin
      FBar(X, Y, X + 31, Y + 23, cNavy);
      Edge(X, Y, X + 31, Y + 23, cGray, cWhite);
      OutTxt(X + 8, Y + 4, DrvL[K] + ':', cWhite, cNavy);
    End
    Else
    Begin
      Raised(X, Y, X + 31, Y + 23);
      OutTxt(X + 8, Y + 4, DrvL[K] + ':', cBlack, cSilver);
    End;
  End;
  T := '';
  If (DrvCur >= 0) And (DrvCur < NDrv) And (DrvL[DrvCur] > 'B') Then
    If DiskSpace(DrvL[DrvCur], Tot, Fr) Then T := Thou(Fr) + ' octets libres';
  OutTxt(X1 + 12, Y2 - 22, Fit(T, X2 - X1 - 24), cBlack, cSilver);
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
  Case Mode Of
    mdView, mdHelp : If UY1 < KbY Then PaintViewer;
    mdEdit : If UY1 < KbY Then PaintEditor;
  Else
    Begin
      If UY1 <= PanY2 Then
      Begin
        If Mode = mdOutput Then PaintOutput(0, 0, CW - 1, PanY2)
        Else
        Begin
          PaintPanel(0); PaintPanel(1);
        End;
        If Mode = mdList Then PaintList;
        If Mode = mdDrive Then PaintDrive;
      End;
      If (UY2 >= CmdY) And (UY1 < CmdY + CmdH) Then PaintCmd;
    End;
  End;
  If OptKeyBar And (UY2 >= KbY) Then PaintKeys;
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
  DgBtns : String;        { boutons personnalises ('|' entre eux) }
  DgBtn : LongInt;        { bouton choisi (0, 1, ...) }

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
Var P, Fl, Vk, K, X, F, A_ : LongInt; Rc, Tr : Array[0..3] Of LongInt;
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
        If (Lo16(Mp1) = 1) Or (Lo16(Mp1) >= 100) Then
        Begin
          If Lo16(Mp1) >= 100 Then DgBtn := Lo16(Mp1) - 100 Else DgBtn := 0;
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
          A_ := 0;
          For K := 0 To DgN - 1 Do If DfKind[K] <> dfLabel Then Inc(A_);
          If A_ > 0 Then
          Repeat
            If (Vk = VK_BACKTAB) Or ((Fl And KC_SHIFT) <> 0) Then Dec(X) Else Inc(X);
            If X < 0 Then X := DgN - 1;
            If X >= DgN Then X := 0;
          Until DfKind[X] <> dfLabel;
          If A_ > 0 Then Dummy := WinSetFocus(HWND_DESKTOP, DfH[X]);
        End
        Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
        Begin
          If DgBtns <> '' Then Dummy := WinPostMsg(H, WM_COMMAND, 100, 0) Else Dummy := WinPostMsg(H, WM_COMMAND, 1, 0);
        End
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
  Dummy := WinRegisterClass(Hab, Z('NCDLG'), LongInt(@DlgProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DgClient := 0;
  DgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('NCDLG'), Z2(Title), 0, 0, 0, LongInt(@DgClient));
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
  If DgBtns = '' Then
  Begin
    Dummy := WinCreateWindow(DgClient, WC_BUTTON, Z(OkS), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                             DgW - 252, 10, 130, 26, DgClient, HWND_TOP, 1, 0, 0);
    Dummy := WinCreateWindow(DgClient, WC_BUTTON, Z('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                             DgW - 112, 10, 100, 26, DgClient, HWND_TOP, 2, 0, 0);
  End
  Else
  Begin
    { boutons personnalises, centres (comme les boites de Norton Commander) }
    S := DgBtns + '|';
    A := 0;
    For K := 1 To Length(S) Do If S[K] = '|' Then Inc(A);
    Y := (DgW - A * 120 + 10) Div 2;
    St := 1; Hc := 0;
    For K := 1 To Length(S) Do
      If S[K] = '|' Then
      Begin
        Itm := Copy(S, St, K - St);
        If Hc = 0 Then
          Dummy := WinCreateWindow(DgClient, WC_BUTTON, Z(Itm), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                                   Y, 10, 110, 26, DgClient, HWND_TOP, 100 + Hc, 0, 0)
        Else
          Dummy := WinCreateWindow(DgClient, WC_BUTTON, Z(Itm), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                   Y, 10, 110, 26, DgClient, HWND_TOP, 100 + Hc, 0, 0);
        Y := Y + 120; Inc(Hc); St := K + 1;
      End;
  End;
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
  If Not Ff Then Dummy := WinSetFocus(HWND_DESKTOP, DgClient);
  Dummy := WinEnableWindow(Frame, 0);
  DgDone := False; DgOk := False; DgBtn := -1;
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
{ Execution des programmes et des commandes                            }
{ ==================================================================== }

Var
  ArgBuf : Array[0..1023] Of Byte;
  FailBuf : Array[0..63] Of Byte;
  PPrev : Array[0..1] Of LongInt;          { mode avant Info, Arbre, Vue rapide, desactive }
  DrvLast : Array[0..25] Of String;        { dernier repertoire de chaque lecteur }

Procedure SetArgs(Prog, Args : String);
Var K, J : LongInt;
Begin
  For K := 1 To Length(Prog) Do ArgBuf[K - 1] := Ord(Prog[K]);
  ArgBuf[Length(Prog)] := 0;
  J := Length(Prog) + 1;
  For K := 1 To Length(Args) Do ArgBuf[J + K - 1] := Ord(Args[K]);
  ArgBuf[J + Length(Args)] := 0;
  ArgBuf[J + Length(Args) + 1] := 0;
End;

Procedure SetWait(On_ : Boolean);
Begin
  If On_ Then Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, SPTR_WAIT, 0))
  Else Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, SPTR_ARROW, 0));
End;

Function Comspec : String;
Var S : String;
Begin
  S := EnvStr('COMSPEC');
  If (S = '') Or (Pos('PMSHELL', UpStr(S)) > 0) Or Not FExists(S) Then
  Begin
    If FExists('C:\CMD.EXE') Then S := 'C:\CMD.EXE'
    Else If FExists('D:\CMD.EXE') Then S := 'D:\CMD.EXE'
    Else S := 'CMD.EXE';
  End;
  Comspec := S;
End;

{ repertoire courant du processus = repertoire du panneau (herite par les programmes) }
Procedure GoDir(D : String);
Begin
  If (Length(D) >= 2) And (D[2] = ':') Then
  Begin
    Dummy := DosSetDefaultDisk(Ord(UpCase(D[1])) - 64);
    If Length(D) = 2 Then D := D + '\';
    Dummy := DosSetCurrentDir(Z(D));
  End;
End;

{ --- programme de Presentation Manager ? (en-tete LX/LE, NE ou PE) --- }

Var
  PmH, PmNSec, PmOptEnd : LongInt;
  PmB : Array[0..255] Of Byte;

Function PmReadAt(Ps, N : LongInt) : Boolean;
Var A : LongInt;
Begin
  A := 0;
  PmReadAt := False;
  If DosSetFilePtr(PmH, Ps, 0, LongInt(@A)) <> 0 Then Exit;
  A := 0;
  If DosRead(PmH, LongInt(@PmB), N, LongInt(@A)) <> 0 Then Exit;
  PmReadAt := A = N;
End;

Function PmW(I : LongInt) : LongInt;
Begin
  PmW := PmB[I] Or (PmB[I + 1] Shl 8);
End;

Function PmD(I : LongInt) : LongInt;
Begin
  PmD := PmW(I) Or (PmW(I + 2) Shl 16);
End;

Function PmFileOfs(R : LongInt) : LongInt;
Var I, VS, VA, Raw, RS : LongInt;
Begin
  PmFileOfs := -1;
  For I := 0 To PmNSec - 1 Do
    If PmReadAt(PmOptEnd + I * 40, 40) Then
    Begin
      VS := PmD(8); VA := PmD(12); RS := PmD(16); Raw := PmD(20);
      If VS < RS Then VS := RS;
      If (R >= VA) And (R < VA + VS) Then
      Begin
        PmFileOfs := R - VA + Raw;
        Exit;
      End;
    End;
End;

Function IsPmProgram(Path : String) : Boolean;
Var A, Ne, Imp, Off, K, J, Rva, NmOff, Opt : LongInt; S : String; R : Boolean;
Begin
  IsPmProgram := False;
  R := False;
  PmH := 0; A := 0;
  If DosOpen(Z(Path), LongInt(@PmH), LongInt(@A), 0, 0, 1, $40, 0) <> 0 Then Exit;
  If PmReadAt(0, 64) And (PmB[0] = Ord('M')) And (PmB[1] = Ord('Z')) Then
  Begin
    Ne := PmD($3C);
    If (Ne > 0) And PmReadAt(Ne, 248) Then
    Begin
      If (PmB[0] = Ord('L')) And ((PmB[1] = Ord('X')) Or (PmB[1] = Ord('E'))) Then
        R := (PmD($10) And $700) = $300
      Else If (PmB[0] = Ord('N')) And (PmB[1] = Ord('E')) Then
        R := (PmW($0C) And $300) = $300
      Else If (PmB[0] = Ord('P')) And (PmB[1] = Ord('E')) And (PmB[2] = 0) And (PmB[3] = 0) Then
      Begin
        PmNSec := PmW(6); Opt := Ne + 24; PmOptEnd := Opt + PmW(20);
        If PmW(24) = $20B Then Imp := PmD(24 + 120) Else Imp := PmD(24 + 104);
        Off := -1;
        If (Imp <> 0) And (PmNSec > 0) And (PmNSec < 64) Then Off := PmFileOfs(Imp);
        K := 0;
        While (Off > 0) And (K < 64) Do
        Begin
          If Not PmReadAt(Off + K * 20, 20) Then K := 64
          Else
          Begin
            Rva := PmD(12);
            If Rva = 0 Then K := 64
            Else
            Begin
              NmOff := PmFileOfs(Rva);
              S := '';
              If (NmOff > 0) And PmReadAt(NmOff, 16) Then
              Begin
                J := 0;
                While (J < 16) And (PmB[J] <> 0) Do
                Begin
                  S := S + UpCase(Chr(PmB[J]));
                  Inc(J);
                End;
              End;
              If (Copy(S, 1, 5) = 'PMWIN') Or (Copy(S, 1, 5) = 'PMGPI') Or (Copy(S, 1, 7) = 'PMMERGE') Then
              Begin
                R := True;
                K := 64;
              End;
              Inc(K);
            End;
          End;
        End;
      End;
    End;
  End;
  DosClose(PmH);
  IsPmProgram := R;
End;

{ --- recherche d'un programme : repertoire du panneau, PATH, C:\ --- }

Function TryExe(P : String) : String;
Var R : String; X : String;
Begin
  R := '';
  X := ExtName(P);
  If X <> '' Then
  Begin
    If FExists(P) And Not DirExists(P) Then R := P;
  End
  Else If FExists(P + '.EXE') Then R := P + '.EXE'
  Else If FExists(P + '.COM') Then R := P + '.COM'
  Else If FExists(P + '.CMD') Then R := P + '.CMD'
  Else If FExists(P + '.BAT') Then R := P + '.BAT';
  TryExe := R;
End;

Function FindExe(N : String) : String;
Var R, PathV, D : String; K, St : LongInt;
Begin
  R := '';
  If (Pos('\', N) > 0) Or (Pos(':', N) > 0) Then
  Begin
    If (Length(N) >= 2) And (N[2] <> ':') And (N[1] <> '\') Then N := JoinP(PPath[Side], N)
    Else If N[1] = '\' Then N := Copy(PPath[Side], 1, 2) + N;
    R := TryExe(N);
  End
  Else
  Begin
    R := TryExe(JoinP(PPath[Side], N));
    If R = '' Then
    Begin
      PathV := EnvStr('PATH') + ';';
      St := 1;
      For K := 1 To Length(PathV) Do
        If (PathV[K] = ';') And (R = '') Then
        Begin
          D := Trim(Copy(PathV, St, K - St));
          If D <> '' Then R := TryExe(JoinP(D, N));
          St := K + 1;
        End;
    End;
    If R = '' Then R := TryExe('C:\' + N);
  End;
  FindExe := R;
End;

{ premier mot d'une commande (guillemets possibles) }
Procedure SplitCmd(C : String; Var Prog, Rest : String);
Var K : LongInt;
Begin
  C := Trim(C);
  Prog := ''; Rest := '';
  If C = '' Then Exit;
  If C[1] = '"' Then
  Begin
    K := 2;
    While (K <= Length(C)) And (C[K] <> '"') Do Inc(K);
    Prog := Copy(C, 2, K - 2);
    Rest := Trim(Copy(C, K + 1, 255));
  End
  Else
  Begin
    K := 1;
    While (K <= Length(C)) And (C[K] <> ' ') And (C[K] <> '/') Do Inc(K);
    Prog := Copy(C, 1, K - 1);
    Rest := Trim(Copy(C, K, 255));
  End;
End;

Function QArg(S : String) : String;
Begin
  If (Pos(' ', S) > 0) And (Copy(S, 1, 1) <> '"') Then QArg := '"' + S + '"' Else QArg := S;
End;

{ programme de PM : il ouvre ses propres fenetres }
Function RunPm(Exe, Args : String) : Boolean;
Var Res : Array[0..1] Of LongInt; Rc : LongInt;
Begin
  GoDir(PPath[Side]);
  SetArgs(Exe, Args);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), Z(Exe));
  If Rc <> 0 Then MsgErr('Impossible de lancer ' + Exe + ' (erreur ' + IStr(Rc) + ').')
  Else StatusMsg := 'Lancement de ' + NameOf(Exe);
  RunPm := Rc = 0;
End;

{ commande dans une fenetre OS/2 (nouvelle session) ; PAUSE a la fin }
Function RunWindow(Cmd, Title : String) : Boolean;
Var Res : Array[0..1] Of LongInt; Rc, S, Hc : LongInt; Ci : String;
Begin
  RunWindow := False;
  GoDir(PPath[Side]);
  Ci := Comspec;
  SetArgs(Ci, '/C ' + Cmd + ' /C PAUSE');
  S := KSes(4, Z(UpStr(Title)), 0);
  If S < 0 Then
  Begin
    MsgErr('Trop de sessions : fermez un programme.');
    Exit;
  End;
  Dummy := KSes(12, S, 0);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), Z(Ci));
  If Rc <> 0 Then
  Begin
    Dummy := KSes(12, -1, 0);
    Dummy := KSes(17, S, 0);
    MsgErr('Impossible de lancer ' + Cmd + ' (erreur ' + IStr(Rc) + ').');
    Exit;
  End;
  If Not ShieldOk Then
  Begin
    Dummy := WinInitShield(Hab, Hmq);
    ShieldOk := True;
  End;
  Hc := 0;
  If WinCreateConsole(HWND_DESKTOP, Z(Title), 1 Or 2 Or (S Shl 8), LongInt(@Hc)) <> 0 Then Dummy := KSes(3, S, 0);
  StatusMsg := Title + ' : fen'#136'tre OS/2';
  RunWindow := True;
End;

{ --- ecran de sortie --- }

Procedure AddOut(S : String);
Begin
  If OutL = Nil Then Exit;
  If NOut >= MaxOut Then
  Begin
    Move(OutL^[200], OutL^[0], (MaxOut - 200) * SizeOf(String));
    NOut := MaxOut - 200;
  End;
  OutL^[NOut] := S;
  Inc(NOut);
End;

Procedure AddOutFile(N : String);
Var H, K, R : LongInt; Bf : Array[0..4095] Of Byte; L : String;
Begin
  If Not FOpenRead(N, H) Then Exit;
  L := '';
  Repeat
    R := FRead(H, @Bf, SizeOf(Bf));
    For K := 0 To R - 1 Do
    Begin
      If Bf[K] = 10 Then
      Begin
        AddOut(L); L := '';
      End
      Else If Bf[K] = 9 Then
      Begin
        Repeat
          L := L + ' ';
        Until (Length(L) Mod 8 = 0) Or (Length(L) >= 250);
      End
      Else If (Bf[K] <> 13) And (Bf[K] <> 26) And (Length(L) < 250) Then
      Begin
        If Bf[K] < 32 Then L := L + '.' Else L := L + Chr(Bf[K]);
      End;
    End;
  Until R <= 0;
  If L <> '' Then AddOut(L);
  DosClose(H);
End;

Procedure ReReadAll;
Var S : LongInt;
Begin
  For S := 0 To 1 Do
    If IsFilePanel(S) Then
    Begin
      If Not DirExists(PPath[S]) Then PPath[S] := Copy(PPath[S], 1, 3);
      ReadPanel(S, CurName(S));
      EnsureVis(S);
    End;
  QvName := '#';
  InvalPanels;
End;

Procedure SetTitle;
Begin
  Dummy := WinSetWindowText(Frame, Z(AppTitle + ' - ' + PPath[Side]));
End;

{ commande avec sortie capturee (fichier de travail), asynchrone : le
  minuteur attend la fin (Echap : arreter) }
Function RunCaptured(Cmd : String) : Boolean;
Var Res : Array[0..1] Of LongInt; Rc : LongInt; Ci : String; PL : PLong;
Begin
  RunCaptured := False;
  If ExecOn Then
  Begin
    MsgErr('Une commande est d'#130'j'#133' en cours (Echap : l''arr'#136'ter).');
    Exit;
  End;
  GoDir(PPath[Side]);
  ExecOutName := JoinPath(WorkDir, 'NCOUT.TMP');
  Assign(ExecF, ExecOutName);
  {$I-} Rewrite(ExecF); {$I+}
  If IOResult <> 0 Then
  Begin
    { pas de fichier de travail : fenetre OS/2 }
    RunCaptured := RunWindow(Cmd, 'Commande');
    Exit;
  End;
  Ci := Comspec;
  SetArgs(Ci, '/C ' + Cmd);
  PL := @ExecF;
  Dummy := SetStdHandle(-11, PL^);
  Dummy := SetStdHandle(-12, PL^);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@FailBuf), 64, 2, LongInt(@ArgBuf), 0, LongInt(@Res), Z(Ci));
  Dummy := SetStdHandle(-11, 0);
  Dummy := SetStdHandle(-12, 0);
  If Rc <> 0 Then
  Begin
    {$I-} Close(ExecF); {$I+}
    If IOResult <> 0 Then ;
    AddOut('SYS1041: commande impossible (erreur ' + IStr(Rc) + ')');
    Exit;
  End;
  ExecPid := Res[0];
  ExecT0 := KTicks;
  ExecOn := True;
  ExecCmd := Cmd;
  StatusMsg := 'Ex'#130'cution... (Echap : arr'#136'ter)';
  SetWait(True);
  RunCaptured := True;
End;

Procedure ExecFinished(Code : LongInt);
Var N0 : LongInt;
Begin
  ExecOn := False;
  SetWait(False);
  {$I-} Close(ExecF); {$I+}
  If IOResult <> 0 Then ;
  N0 := NOut;
  AddOutFile(ExecOutName);
  Dummy := DosDelete(Z(ExecOutName));
  If Code <> 0 Then AddOut('(code de retour ' + IStr(Code) + ')');
  StatusMsg := '';
  ReReadAll;
  { la sortie s'affiche (comme l'ecran sous les panneaux de NC) ; Ctrl+O ou Echap : panneaux }
  If (NOut > N0) And (Mode = mdPanels) Then Mode := mdOutput;
  Redraw;
End;

Procedure ExecPoll;
Var Res : Array[0..1] Of LongInt; Pid, R : LongInt;
Begin
  If Not ExecOn Then Exit;
  Res[0] := 0; Res[1] := 0; Pid := 0;
  R := DosWaitChild(0, 1, LongInt(@Res), LongInt(@Pid), ExecPid);
  If R = 129 Then Exit;
  If R <> 0 Then Res[1] := 0;
  ExecFinished(Res[1]);
End;

Procedure ExecStop;
Begin
  If Not ExecOn Then Exit;
  Dummy := DosKillProcess(0, ExecPid);
  AddOut('^C (commande arr'#136't'#130'e)');
  ExecFinished(0);
End;

{ --- substitutions du menu utilisateur et des extensions (comme NC) ---
  !.! nom complet   !  nom sans extension   !: lecteur   !\ repertoire }
Function Subst(S, FName : String) : String;
Var R : String; K : LongInt;
Begin
  R := '';
  K := 1;
  While K <= Length(S) Do
  Begin
    If S[K] = '!' Then
    Begin
      If Copy(S, K, 3) = '!.!' Then
      Begin
        R := R + FName; K := K + 3;
      End
      Else If Copy(S, K, 2) = '!:' Then
      Begin
        R := R + Copy(PPath[Side], 1, 2); K := K + 2;
      End
      Else If Copy(S, K, 2) = '!\' Then
      Begin
        R := R + AddSl(Copy(PPath[Side], 3, 255)); K := K + 2;
      End
      Else If Copy(S, K, 2) = '!!' Then
      Begin
        R := R + '!'; K := K + 2;
      End
      Else
      Begin
        R := R + BaseNoExt(FName); Inc(K);
      End;
    End
    Else
    Begin
      R := R + S[K]; Inc(K);
    End;
  End;
  Subst := R;
End;

{ commande interne de CMD.EXE dont la sortie peut etre capturee (les
  programmes externes en mode texte vont dans une fenetre OS/2 : sans
  fenetre, un programme VIO prendrait l'ecran de Presentation Manager) }
Function IsInternal(P : String) : Boolean;
Const L = ' CD CHDIR COPY DEL DELETE DIR ECHO ERA ERASE HELP MD MKDIR PATH RD REN RENAME RMDIR SET TRUENAME TYPE VER VERIFY VOL ';
Begin
  P := UpStr(P);
  If (P <> '') And (P[Length(P)] = '.') Then P := Copy(P, 1, Length(P) - 1);
  IsInternal := (P <> '') And (Pos(' ' + P + ' ', L) > 0);
End;

{ lancer une commande : programme de PM directement ; sinon capture ou fenetre }
Procedure RunCommand(Cmd : String; InWin : Boolean);
Var Prog, Rest, Exe, X : String;
Begin
  Cmd := Trim(Cmd);
  If Cmd = '' Then Exit;
  SplitCmd(Cmd, Prog, Rest);
  Exe := FindExe(Prog);
  X := ExtName(Exe);
  If (Exe <> '') And ((X = 'EXE') Or (X = 'COM')) And IsPmProgram(Exe) Then
  Begin
    AddOut(PPath[Side] + '>' + Cmd);
    If RunPm(Exe, Rest) Then ;
    InvalCmd;
    Exit;
  End;
  AddOut(PPath[Side] + '>' + Cmd);
  If InWin Or OptExecWin Or Not IsInternal(Prog) Then
  Begin
    If Exe <> '' Then
    Begin
      If RunWindow(Cmd, NameOf(Exe)) Then ;
    End
    Else If RunWindow(Cmd, UpStr(Prog)) Then ;
  End
  Else If RunCaptured(Cmd) Then ;
  InvalCmd;
End;

Procedure CmdChanged;
Begin
  InvalCmd;
End;
{ ==================================================================== }
{ Panneaux : navigation et operations sur les fichiers                  }
{ ==================================================================== }

Procedure UpdPanel(S : LongInt);
Begin
  EnsureVis(S);
  InvalPanel(S);
  If (PMode[1 - S] = pmQuick) Or (PMode[1 - S] = pmInfo) Then InvalPanel(1 - S);
End;

Procedure ChDirPanel(S : LongInt; P, Keep : String);
Begin
  If (Length(P) > 3) And (P[Length(P)] = '\') Then P := Copy(P, 1, Length(P) - 1);
  If Length(P) = 2 Then P := P + '\';
  If Not DirExists(P) Then
  Begin
    MsgErr('R'#130'pertoire introuvable : ' + P);
    Exit;
  End;
  If UpStr(P) <> UpStr(PPath[S]) Then NPrevSel[S] := 0;
  PPath[S] := P;
  DrvLast[Ord(UpCase(P[1])) - 65] := P;
  ReadPanel(S, Keep);
  TopI[S] := 0;
  EnsureVis(S);
  If S = Side Then SetTitle;
  QvName := '#';
  InvalPanels;
  InvalCmd;
End;

Procedure GoParent(S : LongInt);
Begin
  If IsRoot(PPath[S]) Then Exit;
  ChDirPanel(S, ParentOf(PPath[S]), LastPart(PPath[S]));
End;

Procedure GoRoot(S : LongInt);
Begin
  ChDirPanel(S, Copy(PPath[S], 1, 2) + '\', '');
End;

Procedure MoveCur(S, D : LongInt);
Begin
  If NEnt[S] = 0 Then Exit;
  CurI[S] := CurI[S] + D;
  If CurI[S] < 0 Then CurI[S] := 0;
  If CurI[S] >= NEnt[S] Then CurI[S] := NEnt[S] - 1;
  UpdPanel(S);
End;

Procedure SetCur(S, I : LongInt);
Begin
  CurI[S] := I;
  MoveCur(S, 0);
End;

{ panneau de fichiers de l'autre cote (pour Arbre, Info, Vue rapide) }
Function OtherFile : LongInt;
Begin
  If IsFilePanel(1 - Side) Then OtherFile := 1 - Side Else OtherFile := -1;
End;

Procedure SaveSel(S : LongInt);
Var K : LongInt;
Begin
  If NSelected(S) = 0 Then Exit;
  NPrevSel[S] := 0;
  For K := 0 To NEnt[S] - 1 Do
    If Ent[S]^[K].Sel And (NPrevSel[S] < 100) Then
    Begin
      PrevSel[S, NPrevSel[S]] := Ent[S]^[K].Name;
      Inc(NPrevSel[S]);
    End;
End;

{ --- nom de destination --- }

Function FullPath(D : String) : String;
Var R : String;
Begin
  D := Trim(D);
  If (Length(D) >= 2) And (D[1] = '"') And (D[Length(D)] = '"') Then D := Copy(D, 2, Length(D) - 2);
  If D = '' Then R := ''
  Else If (Length(D) >= 2) And (D[2] = ':') Then
  Begin
    If Length(D) = 2 Then R := D + '\' Else R := D;
  End
  Else If D[1] = '\' Then R := Copy(PPath[Side], 1, 2) + D
  Else If D = '..' Then R := ParentOf(PPath[Side])
  Else R := JoinP(PPath[Side], D);
  If (Length(R) > 3) And (R[Length(R)] = '\') Then R := Copy(R, 1, Length(R) - 1);
  FullPath := R;
End;

Function MkDirs(P : String) : Boolean;
Var K : LongInt; Part : String;
Begin
  MkDirs := DirExists(P);
  If DirExists(P) Then Exit;
  For K := 4 To Length(P) + 1 Do
    If (K > Length(P)) Or (P[K] = '\') Then
    Begin
      Part := Copy(P, 1, K - 1);
      If Not DirExists(Part) Then Dummy := DosCreateDir(Z(Part), 0);
    End;
  MkDirs := DirExists(P);
End;

Function FileInfoStr(P : String) : String;
Var H : LongInt; R : String;
Begin
  R := '';
  If FindFirst_(P, $37, H) Then
  Begin
    R := Thou(RdL(LongInt(@FindBuf) + 16)) + ' octets, ' + FmtDate(FindBuf[12] Or (FindBuf[13] Shl 8)) + ' ' +
         FmtTime(FindBuf[14] Or (FindBuf[15] Shl 8));
    Dummy := DosFindClose(H);
  End;
  FileInfoStr := R;
End;

{ 0 ecraser, 1 tous, 2 sauter, 3 annuler }
Function AskOverwrite(Src, Dst : String) : LongInt;
Var R : LongInt;
Begin
  DlgReset;
  DlgLabel('Le fichier existe d'#130'j'#133' :');
  DlgLabel('   ' + Dst);
  DlgLabel('Nouveau  : ' + FileInfoStr(Src));
  DlgLabel('Existant : ' + FileInfoStr(Dst));
  DgBtns := #144'craser|Tous|Sauter|Annuler';
  If DlgRun('Confirmation', '') Then R := DgBtn Else R := 3;
  DgBtns := '';
  If (R < 0) Or (R > 3) Then R := 3;
  AskOverwrite := R;
End;

Procedure Progress(S : String);
Begin
  StatusMsg := S;
  InvalCmd;
  Dummy := WinUpdateWindow(Client);
End;

{ Echap pendant une longue operation }
Function UserStop : Boolean;
Var Q : Array[0..7] Of LongInt;
Begin
  While WinPeekMsg(Hab, LongInt(@Q), 0, WM_CHAR, WM_CHAR, PM_REMOVE) <> 0 Do
    If ((Lo16(Q[2]) And KC_KEYUP) = 0) And ((Lo16(Q[2]) And KC_VIRTUALKEY) <> 0) And (Hi16(Q[3]) = VK_ESC) Then Stop_ := True;
  UserStop := Stop_;
End;

{ elements touches par une operation : la selection, sinon le fichier sous le curseur }
Function OpCount(S : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := NSelected(S);
  If (N = 0) And (NEnt[S] > 0) And (CurName(S) <> '..') Then N := 1;
  OpCount := N;
End;

Var
  OpSel : Boolean;    { l'operation porte sur la selection (fixe au debut) }

Procedure OpBegin(S : LongInt);
Begin
  OpSel := NSelected(S) > 0;
End;

Function OpItem(S, I : LongInt) : Boolean;
Begin
  If OpSel Then OpItem := Ent[S]^[I].Sel
  Else OpItem := (I = CurI[S]) And (Ent[S]^[I].Name <> '..');
End;

Function OpWhat(S : LongInt) : String;
Var N : LongInt; R : String;
Begin
  N := OpCount(S);
  If NSelected(S) = 0 Then R := '"' + CurName(S) + '"'
  Else R := IStr(N) + ' fichier(s) s'#130'lectionn'#130'(s)';
  OpWhat := R;
End;

{ --- F5 copier, F6 renommer ou deplacer --- }

Procedure CopyMove(DoMove, Here : Boolean);
Var S, I, N, R, Err, Done, NF : LongInt; Def, Dst, Src, T, Nm, Verb : String; All, Conf, DstDir : Boolean;
Begin
  S := Side;
  If Not IsFilePanel(S) Then Exit;
  N := OpCount(S);
  If N = 0 Then Exit;
  If DoMove Then Verb := 'Renommer ou d'#130'placer' Else Verb := 'Copier';
  Def := '';
  If Here Then Def := CurName(S)
  Else If IsFilePanel(1 - S) Then Def := PPath[1 - S]
  Else Def := PPath[S];
  Conf := OptConfOver;
  If OptConfCopy Or Here Or Not IsFilePanel(1 - S) Then
  Begin
    DlgReset;
    DlgLabel(Verb + ' ' + OpWhat(S));
    DlgEdit('vers :', Def);
    DlgCheck('Confirmer l'''#130'crasement des fichiers', OptConfOver);
    If Not DlgRun(Verb, Verb) Then Exit;
    Dst := FullPath(DfVal[1]);
    Conf := DlgBool(2);
  End
  Else Dst := FullPath(Def);
  If Dst = '' Then Exit;
  DstDir := DirExists(Dst);
  If (N > 1) And Not DstDir Then
  Begin
    If Not AskYes('Le r'#130'pertoire ' + Dst + ' n''existe pas. Le cr'#130'er ?') Then Exit;
    If Not MkDirs(Dst) Then
    Begin
      MsgErr('Impossible de cr'#130'er ' + Dst);
      Exit;
    End;
    DstDir := True;
  End;
  SaveSel(S);
  OpBegin(S);
  SetWait(True);
  Stop_ := False;
  All := Not Conf;
  Err := 0; Done := 0;
  For I := 0 To NEnt[S] - 1 Do
  Begin
    If Not OpItem(S, I) Then Continue;
    If UserStop Then Break;
    Nm := Ent[S]^[I].Name;
    Src := JoinP(PPath[S], Nm);
    If DstDir Then T := JoinP(Dst, Nm) Else T := Dst;
    If UpStr(Src) = UpStr(T) Then
    Begin
      MsgErr('Impossible de ' + LoStr(Verb) + ' un fichier sur lui-m'#136'me : ' + Nm);
      Inc(Err);
      Continue;
    End;
    Progress(Verb + ' ' + Nm + '...');
    If IsDirE(Ent[S]^[I]) Then
    Begin
      If Pos(UpStr(AddSl(Src)), UpStr(AddSl(T))) = 1 Then
      Begin
        MsgErr('Impossible de ' + LoStr(Verb) + ' un r'#130'pertoire dans lui-m'#136'me : ' + Nm);
        Inc(Err);
        Continue;
      End;
      NF := 0;
      PoolTop := 0;
      If DoMove Then R := MoveOne(Src, T, True)
      Else R := CopyTree(Src, T, 0, NF);
    End
    Else
    Begin
      If FExists(T) And Not DirExists(T) Then
      Begin
        If Not All Then
        Begin
          R := AskOverwrite(Src, T);
          If R = 3 Then
          Begin
            Stop_ := True;
            Break;
          End;
          If R = 2 Then Continue;
          If R = 1 Then All := True;
        End;
        If (GetAttr(T) And faRO) <> 0 Then
          If SetAttr(T, GetAttr(T) And Not faRO) Then ;
        If DoMove Then Dummy := DosDelete(Z(T));
      End;
      If DoMove Then R := MoveOne(Src, T, False) Else R := CopyOne(Src, T);
    End;
    If R <> 0 Then
    Begin
      Inc(Err);
      If Not AskYes('Erreur ' + IStr(R) + ' : ' + Nm + '. Continuer ?') Then Break;
    End
    Else
    Begin
      Inc(Done);
      Ent[S]^[I].Sel := False;
    End;
  End;
  SetWait(False);
  If Stop_ Then StatusMsg := 'Op'#130'ration interrompue'
  Else If Err = 0 Then StatusMsg := IStr(Done) + ' '#130'l'#130'ment(s) trait'#130'(s)'
  Else StatusMsg := IStr(Done) + ' trait'#130'(s), ' + IStr(Err) + ' erreur(s)';
  Stop_ := False;
  If Here And (Done > 0) And DoMove Then
  Begin
    If Pos('\', Copy(Dst, 4, 255)) >= 0 Then ;
    If UpStr(ParentOf(Dst)) = UpStr(PPath[S]) Then
    Begin
      ReadPanel(S, LastPart(Dst));
      ReReadAll;
      Exit;
    End;
  End;
  ReReadAll;
End;

{ --- F7 creer un repertoire --- }

Procedure DoMkDir;
Var P, Nm : String;
Begin
  If Not IsFilePanel(Side) Then Exit;
  DlgReset;
  DlgEdit('Cr'#130'er le r'#130'pertoire :', '');
  If Not DlgRun('Cr'#130'er un r'#130'pertoire', 'Cr'#130'er') Then Exit;
  P := FullPath(DfVal[0]);
  If P = '' Then Exit;
  If DirExists(P) Then
  Begin
    MsgErr('Le r'#130'pertoire existe d'#130'j'#133' : ' + P);
    Exit;
  End;
  If Not MkDirs(P) Then
  Begin
    MsgErr('Impossible de cr'#130'er le r'#130'pertoire ' + P);
    Exit;
  End;
  Nm := '';
  If UpStr(ParentOf(P)) = UpStr(PPath[Side]) Then Nm := LastPart(P)
  Else Nm := CurName(Side);
  ReadPanel(Side, Nm);
  ReReadAll;
  StatusMsg := 'R'#130'pertoire cr'#130#130' : ' + P;
End;

{ --- F8 supprimer --- }

Function DirEmpty(P : String) : Boolean;
Begin
  PoolTop := 0;
  DirEmpty := ListDir(P, False) = 0;
End;

Procedure DoDelete;
Var S, I, N, R, Err, Done, NF : LongInt; Nm, P : String; AllDirs, AllRO : Boolean;
Begin
  S := Side;
  If Not IsFilePanel(S) Then Exit;
  N := OpCount(S);
  If N = 0 Then Exit;
  If OptConfDel Then
    If Not AskYes('Supprimer ' + OpWhat(S) + ' ?') Then Exit;
  SaveSel(S);
  OpBegin(S);
  SetWait(True);
  Stop_ := False;
  AllDirs := False; AllRO := False;
  Err := 0; Done := 0;
  For I := 0 To NEnt[S] - 1 Do
  Begin
    If Not OpItem(S, I) Then Continue;
    If UserStop Then Break;
    Nm := Ent[S]^[I].Name;
    P := JoinP(PPath[S], Nm);
    Progress('Suppression de ' + Nm + '...');
    If IsDirE(Ent[S]^[I]) Then
    Begin
      If Not DirEmpty(P) Then
      Begin
        If Not AllDirs Then
        Begin
          DlgReset;
          DlgLabel('Le r'#130'pertoire suivant n''est pas vide :');
          DlgLabel('   ' + P);
          DlgLabel('Supprimer le r'#130'pertoire et tout son contenu ?');
          DgBtns := 'Supprimer|Tous|Sauter|Annuler';
          If DlgRun('Suppression', '') Then R := DgBtn Else R := 3;
          DgBtns := '';
          If (R < 0) Or (R = 3) Then
          Begin
            Stop_ := True;
            Break;
          End;
          If R = 2 Then Continue;
          If R = 1 Then AllDirs := True;
        End;
        NF := 0;
        PoolTop := 0;
        R := DeleteTree(P, 0, NF);
      End
      Else R := DosDeleteDir(Z(P));
    End
    Else
    Begin
      If (Ent[S]^[I].Attr And faRO) <> 0 Then
      Begin
        If Not AllRO And OptConfDel Then
        Begin
          DlgReset;
          DlgLabel('Le fichier est en lecture seule :');
          DlgLabel('   ' + P);
          DlgLabel('Le supprimer quand m'#136'me ?');
          DgBtns := 'Supprimer|Tous|Sauter|Annuler';
          If DlgRun('Suppression', '') Then R := DgBtn Else R := 3;
          DgBtns := '';
          If (R < 0) Or (R = 3) Then
          Begin
            Stop_ := True;
            Break;
          End;
          If R = 2 Then Continue;
          If R = 1 Then AllRO := True;
        End;
        If SetAttr(P, Ent[S]^[I].Attr And Not faRO) Then ;
      End;
      R := DosDelete(Z(P));
    End;
    If R <> 0 Then
    Begin
      Inc(Err);
      If Not AskYes('Impossible de supprimer ' + Nm + ' (erreur ' + IStr(R) + '). Continuer ?') Then Break;
    End
    Else Inc(Done);
  End;
  SetWait(False);
  If Stop_ Then StatusMsg := 'Suppression interrompue'
  Else If Err = 0 Then StatusMsg := IStr(Done) + ' '#130'l'#130'ment(s) supprim'#130'(s)'
  Else StatusMsg := IStr(Done) + ' supprim'#130'(s), ' + IStr(Err) + ' erreur(s)';
  Stop_ := False;
  { curseur : l'element qui suit }
  I := CurI[S];
  While (I < NEnt[S]) And OpItem(S, I) Do Inc(I);
  If I < NEnt[S] Then Nm := Ent[S]^[I].Name Else Nm := '';
  ReadPanel(S, Nm);
  If Nm = '' Then CurI[S] := NEnt[S] - 1;
  ReReadAll;
End;

{ --- attributs --- }

Procedure DoAttrib;
Var S, I, A, NA, Err : LongInt; Nm : String;
Begin
  S := Side;
  If Not IsFilePanel(S) Or (OpCount(S) = 0) Then Exit;
  I := CurI[S];
  A := Ent[S]^[I].Attr;
  DlgReset;
  DlgLabel('Attributs de ' + OpWhat(S));
  DlgCheck('Lecture seule', (A And faRO) <> 0);
  DlgCheck('Archive', (A And faArch) <> 0);
  DlgCheck('Cach'#130, (A And faHidden) <> 0);
  DlgCheck('Syst'#138'me', (A And faSys) <> 0);
  If NSelected(S) = 0 Then
    DlgLabel('Date : ' + FmtDate(Ent[S]^[I].FDate) + '   heure : ' + FmtTime(Ent[S]^[I].FTime));
  If Not DlgRun('Attributs', 'Appliquer') Then Exit;
  OpBegin(S);
  Err := 0;
  For I := 0 To NEnt[S] - 1 Do
    If OpItem(S, I) Then
    Begin
      Nm := JoinP(PPath[S], Ent[S]^[I].Name);
      NA := Ent[S]^[I].Attr And faDir;
      If DlgBool(1) Then NA := NA Or faRO;
      If DlgBool(2) Then NA := NA Or faArch;
      If DlgBool(3) Then NA := NA Or faHidden;
      If DlgBool(4) Then NA := NA Or faSys;
      If Not SetAttr(Nm, NA And Not faDir) Then Inc(Err);
    End;
  If Err > 0 Then MsgErr(IStr(Err) + ' fichier(s) sans changement (erreur).');
  ReReadAll;
End;

{ --- selection par groupe (Gris+, Gris-, Gris*) --- }

Var
  GroupMask : String;

Procedure SelGroup(On_ : Boolean);
Var S, K, N : LongInt; T : String;
Begin
  S := Side;
  If Not IsFilePanel(S) Then Exit;
  DlgReset;
  If On_ Then T := 'S'#130'lectionner' Else T := 'D'#130's'#130'lectionner';
  DlgEdit(T + ' les fichiers :', GroupMask);
  DlgCheck('Inclure les r'#130'pertoires', False);
  If Not DlgRun(T + ' un groupe', T) Then Exit;
  GroupMask := Trim(DfVal[0]);
  If GroupMask = '' Then GroupMask := '*.*';
  N := 0;
  For K := 0 To NEnt[S] - 1 Do
    If (Ent[S]^[K].Name <> '..') And (DlgBool(1) Or Not IsDirE(Ent[S]^[K])) Then
      If MatchMask(Ent[S]^[K].Name, GroupMask) Then
      Begin
        Ent[S]^[K].Sel := On_;
        Inc(N);
      End;
  StatusMsg := IStr(N) + ' fichier(s) correspondent a ' + GroupMask;
  UpdPanel(S);
  InvalCmd;
End;

Procedure InvertSel;
Var S, K : LongInt;
Begin
  S := Side;
  If Not IsFilePanel(S) Then Exit;
  For K := 0 To NEnt[S] - 1 Do
    If Not IsDirE(Ent[S]^[K]) Then Ent[S]^[K].Sel := Not Ent[S]^[K].Sel;
  UpdPanel(S);
End;

Procedure RestoreSel;
Var S, K, J : LongInt;
Begin
  S := Side;
  If Not IsFilePanel(S) Then Exit;
  If NPrevSel[S] = 0 Then
  Begin
    StatusMsg := 'Aucune s'#130'lection '#133' restaurer';
    InvalCmd;
    Exit;
  End;
  For K := 0 To NEnt[S] - 1 Do
  Begin
    Ent[S]^[K].Sel := False;
    For J := 0 To NPrevSel[S] - 1 Do
      If PrevSel[S, J] = Ent[S]^[K].Name Then Ent[S]^[K].Sel := True;
  End;
  UpdPanel(S);
End;

Procedure ToggleSel(S, I : LongInt);
Begin
  If (I < 0) Or (I >= NEnt[S]) Then Exit;
  If Ent[S]^[I].Name = '..' Then Exit;
  Ent[S]^[I].Sel := Not Ent[S]^[I].Sel;
End;

{ --- comparer les repertoires : selectionne ce qui manque ou est plus recent --- }

Function Stamp(Var E : TEntry) : LongInt;
Begin
  Stamp := (E.FDate Shl 16) Or E.FTime;
End;

Procedure CompareDirs;
Var S, K, J, Found, N0, N1 : LongInt; Diff : Boolean;
Begin
  If Not IsFilePanel(0) Or Not IsFilePanel(1) Then
  Begin
    MsgErr('Les deux panneaux doivent montrer des fichiers.');
    Exit;
  End;
  For S := 0 To 1 Do
    For K := 0 To NEnt[S] - 1 Do Ent[S]^[K].Sel := False;
  N0 := 0; N1 := 0;
  For S := 0 To 1 Do
    For K := 0 To NEnt[S] - 1 Do
    Begin
      If IsDirE(Ent[S]^[K]) Then Continue;
      Found := -1;
      For J := 0 To NEnt[1 - S] - 1 Do
        If UpStr(Ent[1 - S]^[J].Name) = UpStr(Ent[S]^[K].Name) Then Found := J;
      Diff := Found < 0;
      If Not Diff Then
        Diff := (Stamp(Ent[S]^[K]) > Stamp(Ent[1 - S]^[Found])) Or
                ((Stamp(Ent[S]^[K]) = Stamp(Ent[1 - S]^[Found])) And (Ent[S]^[K].Size <> Ent[1 - S]^[Found].Size));
      If Diff Then
      Begin
        Ent[S]^[K].Sel := True;
        If S = 0 Then Inc(N0) Else Inc(N1);
      End;
    End;
  If (N0 = 0) And (N1 = 0) Then Msg('Les r'#130'pertoires sont identiques.')
  Else StatusMsg := 'Diff'#130'rences : ' + IStr(N0) + ' ' + #133' gauche, ' + IStr(N1) + ' '#133' droite';
  InvalPanels;
  InvalCmd;
End;

{ --- taille des repertoires (F3 sur un repertoire, comme NC) --- }

Procedure ShowDirSize;
Var S, NF, ND : LongInt; By : Double; Nm : String;
Begin
  S := Side;
  If Not IsFilePanel(S) Or (NEnt[S] = 0) Then Exit;
  Nm := CurName(S);
  If Nm = '..' Then Nm := '' ;
  SetWait(True);
  NF := 0; ND := 0; By := 0;
  PoolTop := 0;
  If Nm = '' Then DirSize(PPath[S], NF, ND, By, 0) Else DirSize(JoinP(PPath[S], Nm), NF, ND, By, 0);
  SetWait(False);
  If Nm = '' Then Nm := PPath[S];
  Msg('R'#130'pertoire ' + Nm + #13#13 + IStr(NF) + ' fichier(s) dans ' + IStr(ND) + ' sous-r'#130'pertoire(s)' + #13 +
      Thou(By) + ' octets');
End;

{ --- permuter les panneaux (Ctrl+U) --- }

Procedure SwapPanels;
Var Pe : PEntArr; T : LongInt; St : String;
Begin
  Pe := Ent[0]; Ent[0] := Ent[1]; Ent[1] := Pe;
  T := NEnt[0]; NEnt[0] := NEnt[1]; NEnt[1] := T;
  T := CurI[0]; CurI[0] := CurI[1]; CurI[1] := T;
  T := TopI[0]; TopI[0] := TopI[1]; TopI[1] := T;
  T := PMode[0]; PMode[0] := PMode[1]; PMode[1] := T;
  T := PSort[0]; PSort[0] := PSort[1]; PSort[1] := T;
  T := PFiltK[0]; PFiltK[0] := PFiltK[1]; PFiltK[1] := T;
  T := PPrev[0]; PPrev[0] := PPrev[1]; PPrev[1] := T;
  T := NPrevSel[0]; NPrevSel[0] := NPrevSel[1]; NPrevSel[1] := T;
  St := PPath[0]; PPath[0] := PPath[1]; PPath[1] := St;
  St := PFilter[0]; PFilter[0] := PFilter[1]; PFilter[1] := St;
  Side := 1 - Side;
  If Not IsFilePanel(Side) And (PMode[Side] <> pmTree) Then Side := 1 - Side;
  SetTitle;
  InvalPanels;
  InvalCmd;
End;

{ --- modes des panneaux --- }

Procedure TreeFollow;
Var O : LongInt;
Begin
  O := OtherFile;
  If (O >= 0) And (TreeCur >= 0) And (TreeCur < NTree) Then
    If UpStr(TreeP^[TreeCur]) <> UpStr(PPath[O]) Then
    Begin
      PPath[O] := TreeP^[TreeCur];
      ReadPanel(O, '');
      TopI[O] := 0;
      InvalPanel(O);
    End;
End;

Procedure TreeSync(S : LongInt);
Var K : LongInt; P : String;
Begin
  P := PPath[1 - S];
  If Not IsFilePanel(1 - S) Then P := PPath[S];
  If (NTree = 0) Or (TreeDrive <> UpCase(P[1])) Then
  Begin
    SetWait(True);
    BuildTree(P[1]);
    SetWait(False);
  End;
  TreeCur := 0;
  For K := 0 To NTree - 1 Do If UpStr(TreeP^[K]) = UpStr(P) Then TreeCur := K;
End;

Procedure SetPanelMode(S, M : LongInt);
Begin
  If (M = pmInfo) Or (M = pmTree) Or (M = pmQuick) Or (M = pmOff) Then
  Begin
    If PMode[S] = M Then
    Begin
      { deuxieme choix : retour au mode precedent }
      M := PPrev[S];
      If (M <> pmBrief) And (M <> pmFull) Then M := pmFull;
    End
    Else If IsFilePanel(S) Then PPrev[S] := PMode[S];
  End;
  If PMode[S] = pmTree Then
    If (M = pmBrief) Or (M = pmFull) Then
      If (TreeCur >= 0) And (TreeCur < NTree) Then PPath[S] := TreeP^[TreeCur];
  PMode[S] := M;
  If M = pmTree Then TreeSync(S);
  If IsFilePanel(S) Then
  Begin
    ReadPanel(S, CurName(S));
    EnsureVis(S);
  End;
  { le panneau actif doit montrer des fichiers ou l'arbre }
  If Not IsFilePanel(Side) And (PMode[Side] <> pmTree) Then
    If IsFilePanel(1 - Side) Or (PMode[1 - Side] = pmTree) Then Side := 1 - Side;
  QvName := '#';
  SetTitle;
  InvalPanels;
  InvalCmd;
End;

Procedure SetSort(S, M : LongInt);
Var Nm : String;
Begin
  If Not IsFilePanel(S) Then Exit;
  Nm := CurName(S);
  PSort[S] := M;
  SortPanel(S);
  CurI[S] := 0;
  For M := 0 To NEnt[S] - 1 Do If Ent[S]^[M].Name = Nm Then CurI[S] := M;
  UpdPanel(S);
End;

Procedure FilterDlg(S : LongInt);
Begin
  DlgReset;
  DlgCombo('Fichiers montr'#130's :', 'Tous les fichiers|Programmes (EXE, COM, CMD, BAT)|Personnalis'#130, PFiltK[S]);
  DlgEdit('Masques personnalis'#130's (s'#130'par'#130's par ;) :', PFilter[S]);
  If Not DlgRun('Filtre du panneau', 'OK') Then Exit;
  PFiltK[S] := DlgInt(0);
  If Trim(DfVal[1]) <> '' Then PFilter[S] := Trim(DfVal[1]);
  If IsFilePanel(S) Then
  Begin
    ReadPanel(S, CurName(S));
    EnsureVis(S);
  End;
  InvalPanels;
End;

{ --- choix du lecteur --- }

Procedure DriveOpen(S : LongInt);
Var K, M : LongInt;
Begin
  DrvSide := S;
  M := DriveMap;
  NDrv := 0; DrvCur := 0;
  For K := 0 To 25 Do
    If ((M Shr K) And 1) <> 0 Then
    Begin
      DrvL[NDrv] := Chr(65 + K);
      If Chr(65 + K) = UpCase(PPath[S][1]) Then DrvCur := NDrv;
      Inc(NDrv);
    End;
  If NDrv = 0 Then Exit;
  Mode := mdDrive;
  InvalPanels;
End;

Procedure DriveChoose;
Var C : Char; P : String;
Begin
  Mode := mdPanels;
  InvalPanels;
  If (DrvCur < 0) Or (DrvCur >= NDrv) Then Exit;
  C := DrvL[DrvCur];
  P := DrvLast[Ord(C) - 65];
  If (P = '') Or Not DirExists(P) Then P := C + ':\';
  If Not DirExists(P) Then
  Begin
    MsgErr('Le lecteur ' + C + ': n''est pas pr'#136't.');
    Exit;
  End;
  If Not IsFilePanel(DrvSide) Then PMode[DrvSide] := pmFull;
  Side := DrvSide;
  ChDirPanel(DrvSide, P, '');
End;

{ --- Entree sur un element --- }

Var
  ExtL : Array[0..99] Of String;           { NC.EXT : 'EXT' ou 'EXT1 EXT2' }
  ExtC : Array[0..99] Of String;
  NExt : LongInt;

Function ExtFileName : String;
Begin
  ExtFileName := JoinPath(WorkDir, 'NC.EXT');
End;

Procedure ExtDefaults;
Var K : LongInt;
Begin
  NExt := 0;
  For K := 0 To 8 Do
  Begin
    Case K Of
      0 : Begin ExtL[NExt] := 'TXT INI LOG DOC ME 1ST'; ExtC[NExt] := 'C:\NOTEPAD.EXE !.!'; End;
      1 : Begin ExtL[NExt] := 'PAS INC'; ExtC[NExt] := 'C:\PASDEV.EXE !.!'; End;
      2 : Begin ExtL[NExt] := 'BMP'; ExtC[NExt] := 'C:\PAINT.EXE !.!'; End;
      3 : Begin ExtL[NExt] := 'HTM HTML'; ExtC[NExt] := 'C:\BROWSER.EXE !.!'; End;
      4 : Begin ExtL[NExt] := 'MP3'; ExtC[NExt] := 'C:\MP3PLAY.EXE !.!'; End;
      5 : Begin ExtL[NExt] := 'WAV'; ExtC[NExt] := 'C:\DIGAUDIO.EXE !.!'; End;
      6 : Begin ExtL[NExt] := 'PDF'; ExtC[NExt] := 'C:\ACROBAT.EXE !.!'; End;
      7 : Begin ExtL[NExt] := 'XLC'; ExtC[NExt] := 'C:\EXCELSIO.EXE !.!'; End;
      8 : Begin ExtL[NExt] := 'SON MID'; ExtC[NExt] := 'C:\NOTATOR.EXE !.!'; End;
    End;
    Inc(NExt);
  End;
End;

{ NC.EXT : lignes "ext: commande" (plusieurs extensions separees par des espaces) }
Procedure LoadExt;
Var H, N, I, P : LongInt; Bf : Array[0..8191] Of Byte; S : String;
Begin
  If Not FOpenRead(ExtFileName, H) Then
  Begin
    ExtDefaults;
    Exit;
  End;
  N := FRead(H, @Bf, SizeOf(Bf));
  DosClose(H);
  NExt := 0;
  I := 0;
  While (I < N) And (NExt < 100) Do
  Begin
    S := '';
    While (I < N) And (Bf[I] <> 10) Do
    Begin
      If (Bf[I] <> 13) And (Length(S) < 250) Then S := S + Chr(Bf[I]);
      Inc(I);
    End;
    Inc(I);
    S := Trim(S);
    If (S = '') Or (S[1] = ';') Then Continue;
    P := Pos(':', S);
    If P < 2 Then Continue;
    ExtL[NExt] := UpStr(Trim(Copy(S, 1, P - 1)));
    ExtC[NExt] := Trim(Copy(S, P + 1, 255));
    Inc(NExt);
  End;
End;

Function ExtCommand(Nm : String) : String;
Var K : LongInt; X, L, R : String;
Begin
  R := '';
  LoadExt;
  X := ExtName(Nm);
  If X <> '' Then
    For K := 0 To NExt - 1 Do
    Begin
      L := ' ' + ExtL[K] + ' ';
      If (R = '') And ((Pos(' ' + X + ' ', L) > 0) Or (Pos(' *.' + X + ' ', L) > 0)) Then R := ExtC[K];
    End;
  ExtCommand := R;
End;

Procedure ViewFile(P : String); Forward;

Procedure EnterItem;
Var S : LongInt; Nm, P, X, C, Prog, Rest, Exe : String;
Begin
  S := Side;
  If PMode[S] = pmTree Then
  Begin
    TreeFollow;
    If OtherFile >= 0 Then Side := OtherFile;
    SetTitle;
    InvalPanels;
    Exit;
  End;
  If Not IsFilePanel(S) Or (NEnt[S] = 0) Then Exit;
  Nm := CurName(S);
  If Nm = '..' Then
  Begin
    GoParent(S);
    Exit;
  End;
  P := JoinP(PPath[S], Nm);
  If IsDirE(Ent[S]^[CurI[S]]) Then
  Begin
    ChDirPanel(S, P, '');
    Exit;
  End;
  X := ExtName(Nm);
  AddHist(Nm);
  If (X = 'EXE') Or (X = 'COM') Then
  Begin
    If IsPmProgram(P) Then
    Begin
      AddOut(PPath[S] + '>' + Nm);
      If RunPm(P, '') Then ;
    End
    Else
    Begin
      AddOut(PPath[S] + '>' + Nm);
      If RunWindow(QArg(P), Nm) Then ;
    End;
    InvalCmd;
    Exit;
  End;
  If (X = 'CMD') Or (X = 'BAT') Then
  Begin
    RunCommand(QArg(Nm), False);
    Exit;
  End;
  C := ExtCommand(Nm);
  If C = '' Then
  Begin
    { pas d'association : le visualiseur, comme Norton Commander qui ne fait rien }
    StatusMsg := 'Aucune association pour .' + X + ' (NC.EXT) : F3 pour voir';
    InvalCmd;
    Exit;
  End;
  C := Subst(C, Nm);
  SplitCmd(C, Prog, Rest);
  Exe := FindExe(Prog);
  If Exe = '' Then
  Begin
    MsgErr('Programme introuvable : ' + Prog + #13'(association de .' + X + ' dans NC.EXT)');
    Exit;
  End;
  If (ExtName(Exe) <> 'CMD') And (ExtName(Exe) <> 'BAT') And IsPmProgram(Exe) Then
  Begin
    If RunPm(Exe, Rest) Then ;
  End
  Else RunCommand(C, True);
  InvalCmd;
End;

{ --- ligne de commande --- }

Procedure ExecLine;
Var C, U, Arg : String; D : String;
Begin
  C := Trim(CmdLine);
  If C = '' Then Exit;
  AddHist(C);
  CmdLine := ''; CmdPos := 0;
  U := UpStr(C);
  { commandes internes, dans le panneau }
  If (Length(U) = 2) And (U[2] = ':') And (U[1] >= 'A') And (U[1] <= 'Z') Then
  Begin
    AddOut(PPath[Side] + '>' + C);
    D := DrvLast[Ord(U[1]) - 65];
    If (D = '') Or Not DirExists(D) Then D := U + '\';
    If Not IsFilePanel(Side) Then PMode[Side] := pmFull;
    ChDirPanel(Side, D, '');
    Exit;
  End;
  If (U = 'CD') Or (Copy(U, 1, 3) = 'CD ') Or (Copy(U, 1, 3) = 'CD\') Or (Copy(U, 1, 4) = 'CD..') Or
     (U = 'CHDIR') Or (Copy(U, 1, 6) = 'CHDIR ') Then
  Begin
    AddOut(PPath[Side] + '>' + C);
    If Copy(U, 1, 5) = 'CHDIR' Then Arg := Trim(Copy(C, 6, 255)) Else Arg := Trim(Copy(C, 3, 255));
    If Arg = '' Then
    Begin
      AddOut(PPath[Side]);
      InvalCmd;
      Exit;
    End;
    D := FullPath(Arg);
    If DirExists(D) Then
    Begin
      If Not IsFilePanel(Side) Then PMode[Side] := pmFull;
      ChDirPanel(Side, D, '');
    End
    Else
    Begin
      AddOut('SYS0003: Chemin introuvable.');
      StatusMsg := 'Chemin introuvable : ' + Arg;
      InvalCmd;
    End;
    Exit;
  End;
  If U = 'CLS' Then
  Begin
    NOut := 0;
    InvalPanels;
    InvalCmd;
    Exit;
  End;
  If U = 'EXIT' Then
  Begin
    Dummy := WinPostMsg(Client, WM_COMMAND, cmQuit, 0);
    Exit;
  End;
  RunCommand(C, False);
End;

Procedure CmdInsert(S : String);
Begin
  If Length(CmdLine) + Length(S) > 250 Then Exit;
  Insert(S, CmdLine, CmdPos + 1);
  CmdPos := CmdPos + Length(S);
  InvalCmd;
End;

Procedure HistStep(D : LongInt);
Begin
  If NHist = 0 Then Exit;
  HistPos := HistPos + D;
  If HistPos < 0 Then HistPos := 0;
  If HistPos >= NHist Then
  Begin
    HistPos := NHist;
    CmdLine := '';
  End
  Else CmdLine := Hist[HistPos];
  CmdPos := Length(CmdLine);
  InvalCmd;
End;

{ --- recherche rapide (Ctrl+S, Alt+lettre) --- }

Function QuickFind(S : LongInt; Q : String; From : LongInt) : Boolean;
Var K, I : LongInt; R : Boolean;
Begin
  R := False;
  Q := UpStr(Q);
  For K := 0 To NEnt[S] - 1 Do
  Begin
    I := (From + K) Mod NEnt[S];
    If Not R And (Copy(UpStr(Ent[S]^[I].Name), 1, Length(Q)) = Q) Then
    Begin
      CurI[S] := I;
      R := True;
    End;
  End;
  QuickFind := R;
End;

Var
  QuickOn : Boolean;

Procedure QuickKey(C : Char);
Begin
  If Not IsFilePanel(Side) Then Exit;
  QuickOn := True;
  If QuickFind(Side, Quick + C, CurI[Side]) Then
  Begin
    Quick := Quick + C;
    UpdPanel(Side);
  End
  Else Dummy := WinAlarm(HWND_DESKTOP, 0);
  StatusMsg := 'Recherche rapide : ' + Quick;
  InvalCmd;
End;

Procedure QuickEnd;
Begin
  If Not QuickOn And (Quick = '') Then Exit;
  QuickOn := False;
  Quick := '';
  StatusMsg := '';
  InvalCmd;
End;
{ ==================================================================== }
{ Visualiseur (F3), editeur (F4), listes                                }
{ ==================================================================== }

Const
  MaxView = 16 * 1024 * 1024;

Var
  VHexS : Boolean;            { recherche d'octets en hexadecimal }

Function FileSize_(P : String) : LongInt;
Var H, R : LongInt; Info : Array[0..15] Of LongInt;
Begin
  R := -1;
  If FOpenRead(P, H) Then
  Begin
    If DosQueryFileInfo(H, 1, LongInt(@Info), 24) = 0 Then R := Info[4];
    DosClose(H);
  End;
  FileSize_ := R;
End;

Function LoadView(P : String) : Boolean;
Var H, N, Sz, Want : LongInt; Tmp : Array[0..16383] Of Byte;
Begin
  LoadView := False;
  If Not FOpenRead(P, H) Then
  Begin
    MsgErr('Impossible d''ouvrir ' + P);
    Exit;
  End;
  BufFree(VBuf);
  Sz := FileSize_(P);
  VSize := Sz;
  VTrunc := False;
  Want := MaxView;
  If (Sz > 0) And (Sz < MaxView) Then
    If BufGrow(VBuf, Sz + 16) Then ;
  SetWait(True);
  Repeat
    N := FRead(H, @Tmp, SizeOf(Tmp));
    If N > 0 Then
    Begin
      If VBuf.Len + N > Want Then
      Begin
        N := Want - VBuf.Len;
        VTrunc := True;
      End;
      BufAddB(VBuf, @Tmp, N);
    End;
  Until (N <= 0) Or VTrunc;
  SetWait(False);
  DosClose(H);
  If VSize < 0 Then VSize := VBuf.Len;
  LoadView := True;
End;

{ debut de la ligne affichee qui contient la position P }
Function LineStartOf(P : LongInt) : LongInt;
Var S, Q, Last : LongInt;
Begin
  If VHex Then
  Begin
    LineStartOf := P And Not 15;
    Exit;
  End;
  S := P;
  While (S > 0) And (VBuf.P^[S - 1] <> 10) Do Dec(S);
  Last := S; Q := S;
  While Q <= P Do
  Begin
    Last := Q;
    Q := NextLineOf(Q);
    If Q <= Last Then Break;
  End;
  LineStartOf := Last;
End;

{ derniere page : VTop tel que la fin du fichier soit en bas }
Function LastTop : LongInt;
Var P, K : LongInt;
Begin
  If VHex Then
  Begin
    P := ((VBuf.Len + 15) Div 16 - ViewRows) * 16;
    If P < 0 Then P := 0;
    LastTop := P;
    Exit;
  End;
  P := VBuf.Len;
  If (P > 0) And (VBuf.P^[P - 1] = 10) Then Dec(P);
  P := LineStartOf(MaxI(0, P - 1));
  If VBuf.Len = 0 Then P := 0;
  For K := 2 To ViewRows Do P := PrevLineOf(P);
  LastTop := P;
End;

Procedure InvalView;
Begin
  InvalBand(0, 0, CW, KbY);
End;

Procedure ViewOpen(P, Title : String);
Begin
  If Not LoadView(P) Then Exit;
  VName := Title;
  VTop := 0; VCol := 0; VHiOfs := 0; VHiLen := 0;
  VIsHelp := False;
  Mode := mdView;
  Redraw;
End;

Procedure ViewFile(P : String);
Begin
  ViewOpen(P, P);
End;

Procedure ViewScroll(N : LongInt);
Var K, Q : LongInt;
Begin
  If N > 0 Then
    For K := 1 To N Do
    Begin
      Q := NextLineOf(VTop);
      If (Q >= VBuf.Len) Or (VTop >= LastTop) Then Break;
      VTop := Q;
    End
  Else
    For K := 1 To -N Do VTop := PrevLineOf(VTop);
  InvalView;
End;

Procedure ViewSetHex(H : Boolean);
Begin
  VHex := H;
  VTop := LineStartOf(MinI(VTop, MaxI(0, VBuf.Len - 1)));
  If VBuf.Len = 0 Then VTop := 0;
  InvalView; InvalKeys;
End;

Function HexVal(S : String; Var V : LongInt) : Boolean;
Var K, D : LongInt; R : Boolean;
Begin
  V := 0; R := S <> '';
  For K := 1 To Length(S) Do
  Begin
    D := Pos(UpCase(S[K]), '0123456789ABCDEF') - 1;
    If D < 0 Then R := False Else V := V * 16 + D;
  End;
  HexVal := R;
End;

Procedure ViewGoto;
Var S : String; V, E, K : LongInt;
Begin
  DlgReset;
  DlgEdit('Position (ligne, $hexa ou nn%) :', '');
  If Not DlgRun('Atteindre', 'Atteindre') Then Exit;
  S := Trim(DfVal[0]);
  If S = '' Then Exit;
  If S[Length(S)] = '%' Then
  Begin
    Val(Copy(S, 1, Length(S) - 1), V, E);
    If (E <> 0) Or (V < 0) Or (V > 100) Then Exit;
    VTop := LineStartOf(MinI(MaxI(0, VBuf.Len - 1), Round(VBuf.Len / 100.0 * V)));
  End
  Else If S[1] = '$' Then
  Begin
    If Not HexVal(Copy(S, 2, 255), V) Then Exit;
    VTop := LineStartOf(MinI(MaxI(0, VBuf.Len - 1), V));
  End
  Else
  Begin
    Val(S, V, E);
    If (E <> 0) Or (V < 1) Then Exit;
    If VHex Then VTop := MinI(LastTop, (V - 1) * 16)
    Else
    Begin
      VTop := 0;
      For K := 2 To V Do
      Begin
        E := NextLineOf(VTop);
        If E >= VBuf.Len Then Break;
        VTop := E;
      End;
    End;
  End;
  If VBuf.Len = 0 Then VTop := 0;
  InvalView;
End;

{ octets cherches (texte ou hexadecimal) }
Function SearchBytes(S : String; Var B : String) : Boolean;
Var K, V : LongInt; T : String; R : Boolean;
Begin
  B := ''; R := True;
  If Not VHexS Then
  Begin
    B := S;
    SearchBytes := S <> '';
    Exit;
  End;
  T := '';
  S := S + ' ';
  For K := 1 To Length(S) Do
    If S[K] = ' ' Then
    Begin
      If T <> '' Then
      Begin
        If HexVal(T, V) And (V < 256) Then B := B + Chr(V) Else R := False;
        T := '';
      End;
    End
    Else T := T + S[K];
  SearchBytes := R And (B <> '');
End;

Procedure ViewFindNext(Fwd : Boolean);
Var P, K, N, L, Start : LongInt; B : String; Ok : Boolean; C, D : LongInt;
Begin
  If VSearch = '' Then Exit;
  If Not SearchBytes(VSearch, B) Then
  Begin
    MsgErr('Cha'#140'ne hexad'#130'cimale invalide : ' + VSearch);
    Exit;
  End;
  L := Length(B);
  If VHiLen > 0 Then Start := VHiOfs Else Start := VTop - 1;
  SetWait(True);
  P := -1;
  N := VBuf.Len;
  If Fwd Then K := Start + 1 Else K := Start - 1;
  While (K >= 0) And (K + L <= N) Do
  Begin
    Ok := True;
    C := 1;
    While Ok And (C <= L) Do
    Begin
      D := VBuf.P^[K + C - 1];
      If (Not VCase) And (Not VHexS) Then
      Begin
        If (D >= 97) And (D <= 122) Then D := D - 32;
        If UpCase(B[C]) <> Chr(D) Then Ok := False;
      End
      Else If B[C] <> Chr(D) Then Ok := False;
      Inc(C);
    End;
    If Ok Then
    Begin
      P := K;
      Break;
    End;
    If Fwd Then Inc(K) Else Dec(K);
  End;
  SetWait(False);
  If P < 0 Then
  Begin
    Msg('Cha'#140'ne introuvable : ' + VSearch);
    Exit;
  End;
  VHiOfs := P; VHiLen := L;
  If VHex Then VTop := MinI(LastTop, MaxI(0, (P And Not 15) - 16 * 3))
  Else
  Begin
    VTop := LineStartOf(P);
    For K := 1 To 3 Do VTop := PrevLineOf(VTop);
    If Not VWrap Then
    Begin
      C := P - LineStartOf(P);
      If C < VCol Then VCol := MaxI(0, C - 8)
      Else If C + L > VCol + ViewCols Then VCol := C + L - ViewCols + 8;
    End;
  End;
  InvalView;
End;

Procedure ViewSearch;
Begin
  DlgReset;
  DlgEdit('Chercher :', VSearch);
  DlgCheck('Respecter la casse', VCase);
  DlgCheck('Octets en hexad'#130'cimal (ex. : 4D 5A 90)', VHexS);
  DlgCheck('Vers le d'#130'but du fichier', False);
  If Not DlgRun('Recherche', 'Chercher') Then Exit;
  VSearch := DfVal[0];
  VCase := DlgBool(1);
  VHexS := DlgBool(2);
  VHiLen := 0;
  If DlgBool(3) Then
  Begin
    VHiOfs := VBuf.Len; VHiLen := 1;
    ViewFindNext(False);
  End
  Else ViewFindNext(True);
End;

Procedure ViewClose;
Begin
  BufFree(VBuf);
  Mode := mdPanels;
  QvName := '#';
  Redraw;
End;

Function ViewKey(Vk, Ch_ : LongInt; Ctrl, Shift : Boolean) : Boolean;
Begin
  ViewKey := True;
  Case Vk Of
    VK_UP : ViewScroll(-1);
    VK_DOWN : ViewScroll(1);
    VK_PAGEUP : ViewScroll(-(ViewRows - 1));
    VK_PAGEDOWN : ViewScroll(ViewRows - 1);
    VK_HOME :
      Begin
        If Ctrl Or VHex Or VWrap Then VTop := 0;
        VCol := 0;
        InvalView;
      End;
    VK_END :
      Begin
        VTop := LastTop;
        InvalView;
      End;
    VK_LEFT :
      If Not VWrap And Not VHex And (VCol > 0) Then
      Begin
        If Ctrl Then VCol := MaxI(0, VCol - 20) Else Dec(VCol);
        InvalView;
      End;
    VK_RIGHT :
      If Not VWrap And Not VHex Then
      Begin
        If Ctrl Then VCol := VCol + 20 Else Inc(VCol);
        InvalView;
      End;
    VK_ESC : ViewClose;
  Else
    Begin
      If (Ch_ = Ord(' ')) And Not Ctrl Then ViewScroll(ViewRows - 1)
      Else ViewKey := False;
    End;
  End;
  If Shift Then ;
End;

Procedure ViewFKey(K, M : LongInt);
Begin
  Case K Of
    1 : If Not VIsHelp Then
        Begin
          Msg('Visualiseur : fl'#138'ches, Pg pr'#130'c, Pg suiv, Origine, Fin, Ctrl+fl'#138'ches.' + #13 +
              'F2 coupure des lignes, F4 hexad'#130'cimal ou ASCII, F5 atteindre,' + #13 +
              'F7 chercher, Maj+F7 ou F8 suivant, Echap, F3 ou F10 quitter.');
        End;
    2 :
      If Not VHex Then
      Begin
        VWrap := Not VWrap;
        VCol := 0;
        VTop := LineStartOf(MinI(VTop, MaxI(0, VBuf.Len - 1)));
        If VBuf.Len = 0 Then VTop := 0;
        InvalView; InvalKeys;
      End;
    3, 10 : ViewClose;
    4 : ViewSetHex(Not VHex);
    5 : ViewGoto;
    7 : If M = kmShift Then ViewFindNext(True) Else ViewSearch;
    8 : ViewFindNext(True);
  End;
End;

{ --- aide (dans le visualiseur) --- }

Procedure HL(Var B : TBuf; S : String);
Begin
  BufAdd(B, S + #13#10);
End;

Procedure ShowHelp;
Begin
  BufFree(VBuf);
  HL(VBuf, '  ' + AppTitle + ' ' + NcVersion + ' pour OS/2-0');
  HL(VBuf, '  Gestionnaire de fichiers '#133' deux panneaux (d''apr'#138's NC.PAS du d'#130'p'#153't NORTONCOMMANDER-0)');
  HL(VBuf, '');
  HL(VBuf, '  TOUCHES DE FONCTION (barre du bas ; cliquer un bouton = appuyer la touche)');
  HL(VBuf, '    F1  Aide                F6  Renommer ou d'#130'placer');
  HL(VBuf, '    F2  Menu utilisateur    F7  Cr'#130'er un r'#130'pertoire');
  HL(VBuf, '    F3  Voir (ASCII/hexa)   F8  Supprimer');
  HL(VBuf, '    F4  '#144'diter              F9  Menu d'#130'roulant');
  HL(VBuf, '    F5  Copier              F10 Quitter');
  HL(VBuf, '');
  HL(VBuf, '    Maj+F4 nouveau fichier   Maj+F5 copier ici   Maj+F6 renommer ici   Maj+F9 enregistrer la config.');
  HL(VBuf, '    Alt+F1 / Alt+F2 lecteur du panneau gauche / droit   Alt+F7 recherche de fichiers');
  HL(VBuf, '    Alt+F8 historique   Alt+F9 agrandir la fen'#136'tre   Alt+F10 arbre NCD');
  HL(VBuf, '    Ctrl+F1 / Ctrl+F2 panneau gauche / droit   Ctrl+F3 nom   Ctrl+F4 extension');
  HL(VBuf, '    Ctrl+F5 heure   Ctrl+F6 taille   Ctrl+F7 non tri'#130);
  HL(VBuf, '');
  HL(VBuf, '  PANNEAUX');
  HL(VBuf, '    Tab               panneau suivant           Entr'#130'e    ouvrir, lancer, associer (NC.EXT)');
  HL(VBuf, '    Ins               s'#130'lectionner             Gris +    s'#130'lectionner un groupe');
  HL(VBuf, '    Gris -            d'#130's'#130'lectionner un groupe  Gris *    inverser la s'#130'lection');
  HL(VBuf, '    Ctrl+Pg pr'#130'c      r'#130'pertoire parent        Ctrl+\    r'#130'pertoire racine');
  HL(VBuf, '    Ctrl+L            panneau Info              Ctrl+Q    vue rapide');
  HL(VBuf, '    Ctrl+O            ecran de sortie           Ctrl+U    permuter les panneaux');
  HL(VBuf, '    Ctrl+R            relire                    Ctrl+B    barre des touches');
  HL(VBuf, '    Ctrl+S            recherche rapide          Ctrl+P    panneau inactif');
  HL(VBuf, '    Ctrl+F            Compare les r'#130'pertoires   Ctrl+A    attributs');
  HL(VBuf, '');
  HL(VBuf, '  LIGNE DE COMMANDE');
  HL(VBuf, '    Entr'#130'e            ex'#130'cuter (la sortie s''affiche ; Echap ou Ctrl+O : retour aux panneaux)');
  HL(VBuf, '    Maj+Entr'#130'e        ex'#130'cuter dans une fen'#136'tre OS/2');
  HL(VBuf, '    Ctrl+Entr'#130'e       copier le nom du fichier dans la ligne de commande');
  HL(VBuf, '    Ctrl+[ / Ctrl+]   copier le chemin du panneau gauche / droit');
  HL(VBuf, '    Ctrl+E / Ctrl+X   commande pr'#130'c'#130'dente / suivante      Echap : effacer la ligne');
  HL(VBuf, '    Commandes internes : CD, lecteur:, CLS, EXIT');
  HL(VBuf, '');
  HL(VBuf, '  VISUALISEUR (F3)');
  HL(VBuf, '    F2 coupure des lignes   F4 hexad'#130'cimal / ASCII   F5 atteindre (ligne, $hexa, nn%)');
  HL(VBuf, '    F7 chercher (texte ou octets en hexa)   Maj+F7 ou F8 suivant   F3, F10 ou Echap : quitter');
  HL(VBuf, '');
  HL(VBuf, '  '#144'DITEUR (F4)');
  HL(VBuf, '    F2 enregistrer   F5 atteindre la ligne   F7 chercher   Maj+F7 suivant   F8 ou Ctrl+Y supprimer la ligne');
  HL(VBuf, '    Ins insertion ou remplacement   Ctrl+Origine / Ctrl+Fin d'#130'but / fin   F10 ou Echap : quitter');
  HL(VBuf, '');
  HL(VBuf, '  MENU UTILISATEUR (NC.MNU) : une ligne "touche: titre", puis les commandes en retrait.');
  HL(VBuf, '  EXTENSIONS (NC.EXT) : une ligne par association, par exemple "txt: notepad !.!".');
  HL(VBuf, '  Dans les commandes : !.! nom du fichier, ! nom sans extension, !: lecteur, !\ r'#130'pertoire.');
  HL(VBuf, '');
  HL(VBuf, '  SOURIS : clic = curseur, double clic = Entr'#130'e, bouton 2 = s'#130'lectionner,');
  HL(VBuf, '  clic sur l''en-t'#136'te des colonnes = tri, clic sur la barre du bas = touche de fonction.');
  HL(VBuf, '');
  HL(VBuf, '  La configuration est enregistr'#130'e dans ' + IniName + '.');
  VName := 'Aide';
  VSize := VBuf.Len;
  VTrunc := False;
  VTop := 0; VCol := 0; VHiLen := 0;
  VHex := False; VWrap := False;
  VIsHelp := True;
  Mode := mdHelp;
  Redraw;
End;

{ ==================================================================== }
{ Editeur interne                                                       }
{ ==================================================================== }

Procedure EdAlloc;
Begin
  If EdL = Nil Then GetMem(EdL, MaxEdL * SizeOf(String));
End;

Function EdLoad(P : String) : Boolean;
Var H, R, K : LongInt; Bf : Array[0..8191] Of Byte; L : String; Tr : Boolean;
Begin
  EdLoad := False;
  EdAlloc;
  EdN := 0;
  Tr := False;
  If FExists(P) Then
  Begin
    If Not FOpenRead(P, H) Then
    Begin
      MsgErr('Impossible d''ouvrir ' + P);
      Exit;
    End;
    SetWait(True);
    L := '';
    Repeat
      R := FRead(H, @Bf, SizeOf(Bf));
      For K := 0 To R - 1 Do
      Begin
        If Bf[K] = 10 Then
        Begin
          If EdN < MaxEdL Then
          Begin
            EdL^[EdN] := L; Inc(EdN);
          End
          Else Tr := True;
          L := '';
        End
        Else If Bf[K] = 9 Then
        Begin
          Repeat
            L := L + ' ';
          Until (Length(L) Mod 8 = 0) Or (Length(L) >= 255);
        End
        Else If (Bf[K] <> 13) And (Bf[K] <> 26) Then
        Begin
          If Length(L) < 255 Then L := L + Chr(Bf[K]) Else Tr := True;
        End;
      End;
    Until R <= 0;
    If (L <> '') And (EdN < MaxEdL) Then
    Begin
      EdL^[EdN] := L; Inc(EdN);
    End;
    DosClose(H);
    SetWait(False);
  End;
  If EdN = 0 Then
  Begin
    EdL^[0] := ''; EdN := 1;
  End;
  If Tr Then Msg('Le fichier est trop grand pour l'''#130'diteur interne : il est tronqu'#130'.');
  EdLoad := True;
End;

Function EdSave : Boolean;
Var B : TBuf; K : LongInt; Ok : Boolean;
Begin
  BufInit(B);
  For K := 0 To EdN - 1 Do
  Begin
    BufAdd(B, EdL^[K]);
    If K < EdN - 1 Then BufAdd(B, #13#10)
    Else If EdL^[K] <> '' Then BufAdd(B, #13#10);
  End;
  Ok := WriteAll(EdName, B.P, B.Len);
  BufFree(B);
  If Ok Then
  Begin
    EdMod := False;
    StatusMsg := 'Enregistr'#130' : ' + EdName;
  End
  Else MsgErr('Impossible d''enregistrer ' + EdName);
  EdSave := Ok;
End;

Procedure EdOpen(P : String);
Begin
  If Not EdLoad(P) Then Exit;
  EdName := P;
  EdX := 0; EdY := 0; EdTop := 0; EdLeft := 0;
  EdMod := False; EdIns := True;
  Mode := mdEdit;
  Redraw;
End;

Procedure EdInval;
Begin
  InvalBand(0, 0, CW, KbY);
End;

Procedure EdFix;
Var R, C : LongInt;
Begin
  If EdY < 0 Then EdY := 0;
  If EdY >= EdN Then EdY := EdN - 1;
  If EdX < 0 Then EdX := 0;
  If EdX > 254 Then EdX := 254;
  R := EdRows; C := EdCols;
  If EdY < EdTop Then EdTop := EdY;
  If EdY >= EdTop + R Then EdTop := EdY - R + 1;
  If EdX < EdLeft Then EdLeft := MaxI(0, EdX - 8);
  If EdX >= EdLeft + C Then EdLeft := EdX - C + 8;
  EdInval;
End;

Procedure EdInsLine(At : LongInt; S : String);
Begin
  If EdN >= MaxEdL Then Exit;
  If At < EdN Then Move(EdL^[At], EdL^[At + 1], (EdN - At) * SizeOf(String));
  EdL^[At] := S;
  Inc(EdN);
End;

Procedure EdDelLine(At : LongInt);
Begin
  If EdN <= 1 Then
  Begin
    EdL^[0] := '';
    Exit;
  End;
  If At < EdN - 1 Then Move(EdL^[At + 1], EdL^[At], (EdN - At - 1) * SizeOf(String));
  Dec(EdN);
End;

Procedure EdPad;
Begin
  While Length(EdL^[EdY]) < EdX Do EdL^[EdY] := EdL^[EdY] + ' ';
End;

Procedure EdChar(C : Char);
Var L : String;
Begin
  EdPad;
  L := EdL^[EdY];
  If EdIns Or (EdX >= Length(L)) Then
  Begin
    If Length(L) >= 255 Then Exit;
    Insert(C, L, EdX + 1);
  End
  Else L[EdX + 1] := C;
  EdL^[EdY] := L;
  Inc(EdX);
  EdMod := True;
  EdFix;
End;

Procedure EdEnter;
Var L, Ind : String; K : LongInt;
Begin
  If EdN >= MaxEdL Then Exit;
  L := EdL^[EdY];
  { retrait automatique }
  Ind := '';
  K := 1;
  While (K <= Length(L)) And (L[K] = ' ') Do
  Begin
    Ind := Ind + ' '; Inc(K);
  End;
  If Length(Ind) > EdX Then Ind := Copy(Ind, 1, EdX);
  If EdX < Length(L) Then
  Begin
    EdL^[EdY] := Copy(L, 1, EdX);
    EdInsLine(EdY + 1, Ind + Copy(L, EdX + 1, 255));
  End
  Else EdInsLine(EdY + 1, Ind);
  Inc(EdY);
  EdX := Length(Ind);
  EdMod := True;
  EdFix;
End;

Procedure EdBack;
Var L : String; K : LongInt;
Begin
  If EdX > 0 Then
  Begin
    L := EdL^[EdY];
    If EdX <= Length(L) Then Delete(L, EdX, 1);
    EdL^[EdY] := L;
    Dec(EdX);
  End
  Else If EdY > 0 Then
  Begin
    K := Length(EdL^[EdY - 1]);
    If K + Length(EdL^[EdY]) > 255 Then Exit;
    EdL^[EdY - 1] := EdL^[EdY - 1] + EdL^[EdY];
    EdDelLine(EdY);
    Dec(EdY);
    EdX := K;
  End
  Else Exit;
  EdMod := True;
  EdFix;
End;

Procedure EdDel;
Var L : String;
Begin
  L := EdL^[EdY];
  If EdX < Length(L) Then
  Begin
    Delete(L, EdX + 1, 1);
    EdL^[EdY] := L;
  End
  Else If EdY < EdN - 1 Then
  Begin
    EdPad;
    If Length(EdL^[EdY]) + Length(EdL^[EdY + 1]) > 255 Then Exit;
    EdL^[EdY] := EdL^[EdY] + EdL^[EdY + 1];
    EdDelLine(EdY + 1);
  End
  Else Exit;
  EdMod := True;
  EdFix;
End;

Procedure EdWord(D : LongInt);
Var L : String;
Begin
  L := EdL^[EdY];
  If D > 0 Then
  Begin
    While (EdX < Length(L)) And (L[EdX + 1] <> ' ') Do Inc(EdX);
    While (EdX < Length(L)) And (L[EdX + 1] = ' ') Do Inc(EdX);
  End
  Else
  Begin
    If EdX > Length(L) Then EdX := Length(L);
    While (EdX > 0) And (L[EdX] = ' ') Do Dec(EdX);
    While (EdX > 0) And (L[EdX] <> ' ') Do Dec(EdX);
  End;
  EdFix;
End;

Procedure EdFind(Again : Boolean);
Var Y, X, P : LongInt; U : String;
Begin
  If Not Again Or (EdSearch = '') Then
  Begin
    DlgReset;
    DlgEdit('Chercher :', EdSearch);
    DlgCheck('Respecter la casse', VCase);
    If Not DlgRun('Recherche', 'Chercher') Then Exit;
    EdSearch := DfVal[0];
    VCase := DlgBool(0 + 1);
    If EdSearch = '' Then Exit;
    Again := False;
  End;
  If VCase Then U := EdSearch Else U := UpStr(EdSearch);
  X := EdX + 1;
  If Not Again Then X := EdX;
  For Y := EdY To EdN - 1 Do
  Begin
    If VCase Then P := Pos(U, Copy(EdL^[Y], X + 1, 255)) Else P := Pos(U, UpStr(Copy(EdL^[Y], X + 1, 255)));
    If P > 0 Then
    Begin
      EdY := Y; EdX := X + P - 1;
      EdFix;
      Exit;
    End;
    X := 0;
  End;
  Msg('Cha'#140'ne introuvable : ' + EdSearch);
End;

Procedure EdGotoLine;
Var V, E : LongInt;
Begin
  DlgReset;
  DlgEdit('Num'#130'ro de la ligne :', IStr(EdY + 1));
  If Not DlgRun('Atteindre', 'Atteindre') Then Exit;
  Val(Trim(DfVal[0]), V, E);
  If (E <> 0) Or (V < 1) Then Exit;
  EdY := MinI(V, EdN) - 1;
  EdX := 0;
  EdFix;
End;

Function EdClose : Boolean;
Var R : LongInt;
Begin
  EdClose := False;
  If EdMod Then
  Begin
    R := Ask3('Le fichier ' + EdName + ' a chang'#130'.' + #13 + 'Enregistrer les modifications ?');
    If R = MBID_CANCEL Then Exit;
    If R = MBID_YES Then
      If Not EdSave Then Exit;
  End;
  EdClose := True;
  Mode := mdPanels;
  ReReadAll;
  Redraw;
End;

Function EdKey(Vk, Ch_ : LongInt; Ctrl, Shift : Boolean) : Boolean;
Var K : LongInt;
Begin
  EdKey := True;
  Case Vk Of
    VK_UP : Begin Dec(EdY); EdFix; Exit; End;
    VK_DOWN : Begin Inc(EdY); EdFix; Exit; End;
    VK_LEFT :
      Begin
        If Ctrl Then EdWord(-1)
        Else If EdX > 0 Then
        Begin
          Dec(EdX); EdFix;
        End;
        Exit;
      End;
    VK_RIGHT :
      Begin
        If Ctrl Then EdWord(1)
        Else
        Begin
          Inc(EdX); EdFix;
        End;
        Exit;
      End;
    VK_HOME :
      Begin
        If Ctrl Then
        Begin
          EdY := 0; EdX := 0;
        End
        Else
        Begin
          { premier caractere non blanc, puis colonne 1 }
          K := 0;
          While (K < Length(EdL^[EdY])) And (EdL^[EdY][K + 1] = ' ') Do Inc(K);
          If EdX = K Then EdX := 0 Else EdX := K;
        End;
        EdFix;
        Exit;
      End;
    VK_END :
      Begin
        If Ctrl Then EdY := EdN - 1;
        EdX := Length(EdL^[EdY]);
        EdFix;
        Exit;
      End;
    VK_PAGEUP : Begin EdY := EdY - EdRows + 1; EdTop := MaxI(0, EdTop - EdRows + 1); EdFix; Exit; End;
    VK_PAGEDOWN :
      Begin
        EdY := EdY + EdRows - 1;
        EdTop := MinI(MaxI(0, EdN - EdRows), EdTop + EdRows - 1);
        EdFix;
        Exit;
      End;
    VK_INSERT : Begin EdIns := Not EdIns; EdInval; Exit; End;
    VK_DELETE : Begin EdDel; Exit; End;
    VK_BACKSPACE : Begin EdBack; Exit; End;
    VK_NEWLINE, VK_ENTER : Begin EdEnter; Exit; End;
    VK_TAB :
      Begin
        Repeat
          EdChar(' ');
        Until EdX Mod 8 = 0;
        Exit;
      End;
    VK_ESC : Begin If EdClose Then ; Exit; End;
  End;
  If Ctrl And ((Ch_ = 25) Or (Ch_ = Ord('y')) Or (Ch_ = Ord('Y'))) Then
  Begin
    EdDelLine(EdY);
    EdMod := True;
    EdFix;
    Exit;
  End;
  If Ctrl And ((Ch_ = 19) Or (Ch_ = Ord('s')) Or (Ch_ = Ord('S'))) Then
  Begin
    If EdSave Then ;
    EdInval;
    Exit;
  End;
  If Not Ctrl And (Ch_ >= 32) And (Ch_ < 256) Then
  Begin
    EdChar(Chr(Ch_));
    Exit;
  End;
  If Shift Then ;
  EdKey := False;
End;

Procedure EdFKey(K, M : LongInt);
Begin
  Case K Of
    1 : Msg('Editeur : F2 enregistrer, F5 atteindre la ligne, F7 chercher, Maj+F7 suivant,' + #13 +
            'F8 ou Ctrl+Y supprimer la ligne, Ins insertion/remplacement, Ctrl+fl'#138'ches mot par mot,' + #13 +
            'Ctrl+Origine / Ctrl+Fin d'#130'but et fin du fichier, F10 ou Echap quitter.');
    2 : Begin If EdSave Then ; EdInval; End;
    5 : EdGotoLine;
    7 : EdFind(M = kmShift);
    8 :
      Begin
        EdDelLine(EdY);
        EdMod := True;
        EdFix;
      End;
    10 : If EdClose Then ;
  End;
End;

{ F4 : editeur interne ou externe }
Procedure EditFile(P : String);
Var C : String;
Begin
  If OptEditor = 1 Then
  Begin
    C := Subst(OptEditCmd, P);
    If Pos('!', OptEditCmd) = 0 Then C := OptEditCmd + ' ' + QArg(P);
    RunCommand(C, True);
    Exit;
  End;
  EdOpen(P);
End;

Procedure ViewCur;
Var S : LongInt; P, C : String;
Begin
  S := Side;
  If Not IsFilePanel(S) Or (NEnt[S] = 0) Then Exit;
  If IsDirE(Ent[S]^[CurI[S]]) Then
  Begin
    ShowDirSize;
    Exit;
  End;
  P := JoinP(PPath[S], CurName(S));
  If (OptViewer = 1) And (Trim(OptViewCmd) <> '') Then
  Begin
    C := Subst(OptViewCmd, P);
    If Pos('!', OptViewCmd) = 0 Then C := OptViewCmd + ' ' + QArg(P);
    RunCommand(C, True);
    Exit;
  End;
  VHex := False;
  ViewFile(P);
End;

Procedure EditCur;
Var S : LongInt;
Begin
  S := Side;
  If Not IsFilePanel(S) Or (NEnt[S] = 0) Then Exit;
  If IsDirE(Ent[S]^[CurI[S]]) Then Exit;
  EditFile(JoinP(PPath[S], CurName(S)));
End;

Procedure EditNew;
Var P : String;
Begin
  If Not IsFilePanel(Side) Then Exit;
  DlgReset;
  DlgEdit('Nom du fichier '#133' '#130'diter :', '');
  If Not DlgRun('Nouveau fichier', #144'diter') Then Exit;
  P := FullPath(DfVal[0]);
  If P = '' Then Exit;
  EditFile(P);
End;

{ ==================================================================== }
{ Listes : historique, menu utilisateur, fichiers trouves, NCD          }
{ ==================================================================== }

Procedure ListOpen(K : LongInt; T : String);
Begin
  LsKind := K; LsTitle := T;
  LsCur := 0; LsTop := 0; LsQuick := '';
  Mode := mdList;
  InvalPanels;
  InvalCmd;
End;

Procedure ListClose;
Begin
  Mode := mdPanels;
  InvalPanels;
  InvalCmd;
End;

Procedure HistoryList;
Var K : LongInt;
Begin
  If NHist = 0 Then
  Begin
    Msg('L''historique des commandes est vide.');
    Exit;
  End;
  LsN := 0;
  For K := NHist - 1 DownTo 0 Do
    If LsN < 300 Then
    Begin
      LsItem[LsN] := Hist[K];
      Inc(LsN);
    End;
  ListOpen(lkHist, 'Historique des commandes');
End;

Function MenuFileName : String;
Var R : String;
Begin
  R := JoinP(PPath[Side], 'NC.MNU');
  If Not FExists(R) Then R := JoinPath(WorkDir, 'NC.MNU');
  MenuFileName := R;
End;

Procedure WriteDefMenu(P : String);
Var B : TBuf;
Begin
  BufInit(B);
  BufAdd(B, '; Menu utilisateur de North Commander (NC.MNU)'#13#10);
  BufAdd(B, '; "touche: titre", puis les commandes en retrait ; !.! fichier, ! sans extension, !: lecteur, !\ chemin'#13#10);
  BufAdd(B, 'D: Verifier le disque (CHKDSK)'#13#10'    CHKDSK !:'#13#10);
  BufAdd(B, 'M: Memoire du systeme (MEM)'#13#10'    MEM'#13#10);
  BufAdd(B, 'T: Arbre des repertoires (TREE)'#13#10'    TREE !:!\'#13#10);
  BufAdd(B, 'A: Attributs du fichier (ATTRIB)'#13#10'    ATTRIB !.!'#13#10);
  BufAdd(B, 'B: Ouvrir le fichier dans le Bloc-notes'#13#10'    C:\NOTEPAD.EXE !.!'#13#10);
  BufAdd(B, 'E: Explorateur OS2-Zero'#13#10'    C:\EXPLORER.EXE'#13#10);
  BufAdd(B, 'G: Gestionnaire des taches'#13#10'    C:\TASKMGR.EXE'#13#10);
  BufAdd(B, 'V: Version du systeme'#13#10'    VER'#13#10);
  Dummy := LongInt(WriteAll(P, B.P, B.Len));
  BufFree(B);
End;

Procedure UserMenu;
Var H, N, I, P : LongInt; Bf : Array[0..16383] Of Byte; S, Fn : String;
Begin
  Fn := MenuFileName;
  If Not FExists(Fn) Then
  Begin
    If Not AskYes('Le menu utilisateur (NC.MNU) n''existe pas.' + #13 + 'Cr'#130'er un menu d''exemple dans ' + WorkDir + ' ?') Then Exit;
    Fn := JoinPath(WorkDir, 'NC.MNU');
    WriteDefMenu(Fn);
  End;
  If Not FOpenRead(Fn, H) Then
  Begin
    MsgErr('Impossible de lire ' + Fn);
    Exit;
  End;
  N := FRead(H, @Bf, SizeOf(Bf));
  DosClose(H);
  LsN := 0;
  I := 0;
  While I < N Do
  Begin
    S := '';
    While (I < N) And (Bf[I] <> 10) Do
    Begin
      If (Bf[I] <> 13) And (Length(S) < 250) Then
      Begin
        If Bf[I] = 9 Then S := S + ' ' Else S := S + Chr(Bf[I]);
      End;
      Inc(I);
    End;
    Inc(I);
    If (Trim(S) = '') Or (Trim(S)[1] = ';') Then Continue;
    If S[1] <> ' ' Then
    Begin
      If LsN < 300 Then
      Begin
        P := Pos(':', S);
        If P > 0 Then LsItem[LsN] := Trim(Copy(S, 1, P - 1)) + '   ' + Trim(Copy(S, P + 1, 255))
        Else LsItem[LsN] := Trim(S);
        LsCmd[LsN] := '';
        Inc(LsN);
      End;
    End
    Else If LsN > 0 Then
      If Length(LsCmd[LsN - 1]) + Length(Trim(S)) < 250 Then LsCmd[LsN - 1] := LsCmd[LsN - 1] + Trim(S) + #13;
  End;
  If LsN = 0 Then
  Begin
    Msg('Le menu ' + Fn + ' est vide.');
    Exit;
  End;
  ListOpen(lkMenu, 'Menu utilisateur');
End;

{ commandes d'une entree du menu : une ligne directement, plusieurs dans NCMENU.CMD }
Procedure RunMenuItem(K : LongInt);
Var C, L, Fn, Nm : String; I, N : LongInt; B : TBuf;
Begin
  If (K < 0) Or (K >= LsN) Then Exit;
  C := LsCmd[K];
  ListClose;
  Nm := '';
  If IsFilePanel(Side) Then Nm := CurName(Side);
  N := 0;
  For I := 1 To Length(C) Do If C[I] = #13 Then Inc(N);
  If N = 0 Then Exit;
  If N = 1 Then
  Begin
    RunCommand(Subst(Copy(C, 1, Length(C) - 1), Nm), False);
    Exit;
  End;
  BufInit(B);
  BufAdd(B, '@ECHO OFF'#13#10);
  L := '';
  For I := 1 To Length(C) Do
    If C[I] = #13 Then
    Begin
      BufAdd(B, Subst(L, Nm) + #13#10);
      L := '';
    End
    Else L := L + C[I];
  Fn := JoinPath(WorkDir, 'NCMENU.CMD');
  Dummy := LongInt(WriteAll(Fn, B.P, B.Len));
  BufFree(B);
  RunCommand(Fn, False);
End;

Procedure EditMenuFile;
Var Fn : String;
Begin
  Fn := MenuFileName;
  If Not FExists(Fn) Then
  Begin
    Fn := JoinPath(WorkDir, 'NC.MNU');
    WriteDefMenu(Fn);
  End;
  If Mode = mdList Then ListClose;
  EdOpen(Fn);
End;

Procedure EditExtFile;
Var B : TBuf; K : LongInt;
Begin
  If Not FExists(ExtFileName) Then
  Begin
    ExtDefaults;
    BufInit(B);
    BufAdd(B, '; Extensions de North Commander (NC.EXT) : "ext: commande" ; !.! fichier'#13#10);
    For K := 0 To NExt - 1 Do BufAdd(B, LoStr(ExtL[K]) + ': ' + ExtC[K] + #13#10);
    Dummy := LongInt(WriteAll(ExtFileName, B.P, B.Len));
    BufFree(B);
  End;
  EdOpen(ExtFileName);
End;

{ --- recherche de fichiers (Alt+F7) --- }

Procedure FindFiles;
Var K, Scope, M : LongInt; Root : String;
Begin
  DlgReset;
  DlgEdit('Fichiers (masques s'#130'par'#130's par ;) :', FindMask);
  DlgEdit('Contenant le texte :', FindText);
  DlgCheck('Respecter la casse', FindCase);
  DlgCombo('Chercher dans :', 'Tout le disque|R'#130'pertoire courant et sous-r'#130'pertoires|R'#130'pertoire courant seulement|Tous les disques', 0);
  If Not DlgRun('Recherche de fichiers', 'Chercher') Then Exit;
  FindMask := Trim(DfVal[0]);
  If FindMask = '' Then FindMask := '*.*';
  FindText := DfVal[1];
  FindCase := DlgBool(2);
  Scope := DlgInt(3);
  NFound := 0;
  Stop_ := False;
  SetWait(True);
  Progress('Recherche de ' + FindMask + '...  (Echap : arr'#136'ter)');
  FindMaxD := 30;
  If Scope = 2 Then FindMaxD := 0;
  PoolTop := 0;
  If Scope = 3 Then
  Begin
    M := DriveMap;
    For K := 2 To 25 Do
      If (((M Shr K) And 1) <> 0) And Not Stop_ Then
      Begin
        Root := Chr(65 + K) + ':\';
        If DirExists(Root) Then
        Begin
          Progress('Recherche sur ' + Root + '...');
          PoolTop := 0;
          FindWalk(Root, 0);
          If UserStop Then ;
        End;
      End;
  End
  Else
  Begin
    If Scope = 0 Then Root := Copy(PPath[Side], 1, 3) Else Root := PPath[Side];
    FindWalk(Root, 0);
  End;
  SetWait(False);
  StatusMsg := '';
  InvalCmd;
  If NFound = 0 Then
  Begin
    Msg('Aucun fichier trouv'#130' (' + FindMask + ').');
    Exit;
  End;
  LsN := MinI(NFound, 300);
  For K := 0 To LsN - 1 Do LsItem[K] := FoundP^[K];
  If NFound > 300 Then LsTitle := ' (300 premiers)' Else LsTitle := '';
  ListOpen(lkFound, IStr(NFound) + ' fichier(s) trouv'#130'(s)' + LsTitle);
End;

Procedure GoFound(K : LongInt);
Var P, D, N : String;
Begin
  If (K < 0) Or (K >= LsN) Then Exit;
  P := LsItem[K];
  ListClose;
  If P[Length(P)] = '\' Then
  Begin
    P := Copy(P, 1, Length(P) - 1);
    D := ParentOf(P); N := LastPart(P);
  End
  Else
  Begin
    D := DirOf(P); N := NameOf(P);
    If (Length(D) > 3) And (D[Length(D)] = '\') Then D := Copy(D, 1, Length(D) - 1);
  End;
  If Not IsFilePanel(Side) Then PMode[Side] := pmFull;
  ChDirPanel(Side, D, N);
End;

{ --- arbre NCD (Alt+F10) --- }

Procedure NcdOpen(Rebuild : Boolean);
Var K : LongInt; P : String;
Begin
  P := PPath[Side];
  If Rebuild Or (NTree = 0) Or (TreeDrive <> UpCase(P[1])) Then
  Begin
    SetWait(True);
    Progress('Lecture de l''arbre de ' + UpCase(P[1]) + ':...');
    BuildTree(P[1]);
    SetWait(False);
    StatusMsg := '';
  End;
  LsN := NTree;
  ListOpen(lkNcd, 'Arbre des r'#130'pertoires ' + TreeDrive + ': (NCD)');
  For K := 0 To NTree - 1 Do If UpStr(TreeP^[K]) = UpStr(P) Then LsCur := K;
End;

Procedure NcdQuick(C : Char);
Var K, I : LongInt; Q : String;
Begin
  Q := UpStr(LsQuick + C);
  For K := 0 To LsN - 1 Do
  Begin
    I := (LsCur + K) Mod LsN;
    If Copy(UpStr(LastPart(TreeP^[I])), 1, Length(Q)) = Q Then
    Begin
      LsQuick := LsQuick + C;
      LsCur := I;
      InvalPanels;
      Exit;
    End;
  End;
  Dummy := WinAlarm(HWND_DESKTOP, 0);
End;

Procedure NcdMkDir;
Var P, Nm : String;
Begin
  If (LsCur < 0) Or (LsCur >= NTree) Then Exit;
  DlgReset;
  DlgEdit('Cr'#130'er dans ' + TreeP^[LsCur] + ' :', '');
  If Not DlgRun('Cr'#130'er un r'#130'pertoire', 'Cr'#130'er') Then Exit;
  Nm := Trim(DfVal[0]);
  If Nm = '' Then Exit;
  P := JoinP(TreeP^[LsCur], Nm);
  If Not MkDirs(P) Then
  Begin
    MsgErr('Impossible de cr'#130'er ' + P);
    Exit;
  End;
  NcdOpen(True);
  ReReadAll;
End;

Procedure ListEnter;
Var K : LongInt; C : String;
Begin
  K := LsCur;
  Case LsKind Of
    lkHist :
      Begin
        C := LsItem[K];
        ListClose;
        CmdLine := C; CmdPos := Length(C);
        ExecLine;
      End;
    lkMenu : RunMenuItem(K);
    lkFound : GoFound(K);
    lkNcd :
      Begin
        ListClose;
        If (K >= 0) And (K < NTree) Then
        Begin
          If Not IsFilePanel(Side) Then PMode[Side] := pmFull;
          ChDirPanel(Side, TreeP^[K], '');
        End;
      End;
  End;
End;

Function ListKey(Vk, Ch_ : LongInt; Ctrl, Shift : Boolean) : Boolean;
Var R, K : LongInt; C : Char; Key_ : String;
Begin
  ListKey := True;
  R := ListRowsN;
  Case Vk Of
    VK_UP : If LsCur > 0 Then Dec(LsCur);
    VK_DOWN : If LsCur < LsN - 1 Then Inc(LsCur);
    VK_PAGEUP : LsCur := MaxI(0, LsCur - R + 1);
    VK_PAGEDOWN : LsCur := MinI(LsN - 1, LsCur + R - 1);
    VK_HOME : LsCur := 0;
    VK_END : LsCur := LsN - 1;
    VK_NEWLINE, VK_ENTER :
      Begin
        ListEnter;
        Exit;
      End;
    VK_ESC :
      Begin
        ListClose;
        Exit;
      End;
    VK_BACKSPACE :
      If (LsKind = lkNcd) And (LsQuick <> '') Then LsQuick := Copy(LsQuick, 1, Length(LsQuick) - 1);
    VK_DELETE :
      If (LsKind = lkHist) And (LsN > 0) Then
      Begin
        { retirer de l'historique }
        For K := 0 To NHist - 1 Do
          If Hist[K] = LsItem[LsCur] Then
          Begin
            While K < NHist - 1 Do
            Begin
              Hist[K] := Hist[K + 1]; Inc(K);
            End;
            Dec(NHist);
            HistPos := NHist;
            Break;
          End;
        For K := LsCur To LsN - 2 Do LsItem[K] := LsItem[K + 1];
        Dec(LsN);
        If LsN = 0 Then
        Begin
          ListClose;
          Exit;
        End;
        If LsCur >= LsN Then LsCur := LsN - 1;
      End;
  Else
    Begin
      If (Ch_ > 32) And (Ch_ < 256) And Not Ctrl Then
      Begin
        C := Chr(Ch_);
        If LsKind = lkNcd Then
        Begin
          NcdQuick(C);
          Exit;
        End;
        If LsKind = lkMenu Then
          For K := 0 To LsN - 1 Do
          Begin
            Key_ := UpStr(Copy(LsItem[K], 1, Pos(' ', LsItem[K] + ' ') - 1));
            If Key_ = UpCase(C) Then
            Begin
              RunMenuItem(K);
              Exit;
            End;
          End;
      End;
      ListKey := False;
      Exit;
    End;
  End;
  If Shift Then ;
  InvalPanels;
End;

Procedure ListFKey(K, M : LongInt);
Begin
  Case LsKind Of
    lkMenu : If K = 4 Then EditMenuFile;
    lkFound :
      If (K = 3) And (LsCur < LsN) And (LsItem[LsCur][Length(LsItem[LsCur])] <> '\') Then
      Begin
        ListClose;
        VHex := False;
        ViewFile(LsItem[LsCur]);
      End;
    lkNcd :
      Begin
        If K = 2 Then NcdOpen(True);
        If K = 7 Then NcdMkDir;
      End;
  End;
  If K = 10 Then ListClose;
  If M = 0 Then ;
End;
{ ==================================================================== }
{ Menus                                                                 }
{ ==================================================================== }

Procedure PanelMenu(B : LongInt; S : LongInt);
Var H : LongInt; F : String;
Begin
  If S = 0 Then F := 'Ctrl+F1' Else F := 'Ctrl+F2';
  ItA(B + pcBrief, Chk(PMode[S] = pmBrief), '~Bref');
  ItA(B + pcFull, Chk(PMode[S] = pmFull), '~Complet');
  ItA(B + pcInfo, Chk(PMode[S] = pmInfo), '~Info' + #9 + 'Ctrl+L');
  ItA(B + pcTree, Chk(PMode[S] = pmTree), '~Arbre');
  ItA(B + pcQuick, Chk(PMode[S] = pmQuick), '~Vue rapide' + #9 + 'Ctrl+Q');
  ItA(B + pcOnOff, Chk(PMode[S] <> pmOff), 'A~ctiv'#130 + #9 + F);
  Sep;
  ItA(B + pcName, Chk(PSort[S] = srName), '~Nom' + #9 + 'Ctrl+F3');
  ItA(B + pcExt, Chk(PSort[S] = srExt), '~Extension' + #9 + 'Ctrl+F4');
  ItA(B + pcTime, Chk(PSort[S] = srTime), '~Heure' + #9 + 'Ctrl+F5');
  ItA(B + pcSize, Chk(PSort[S] = srSize), '~Taille' + #9 + 'Ctrl+F6');
  ItA(B + pcUnsorted, Chk(PSort[S] = srNone), 'N~on tri'#130 + #9 + 'Ctrl+F7');
  Sep;
  It(B + pcReread, '~Relire' + #9 + 'Ctrl+R');
  It(B + pcFilter, '~Filtre...');
  If S = 0 Then It(B + pcDrive, 'Changer de ~lecteur...' + #9 + 'Alt+F1')
  Else It(B + pcDrive, 'Changer de ~lecteur...' + #9 + 'Alt+F2');
  H := 0;
  If H = 0 Then ;
End;

Procedure BuildMenu;
Var H0, H1, H2, K : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 80, '~Gauche');
  H1 := MenuOpen;
  PanelMenu(cmLeft0, 0);
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 81, '~Fichiers');
  H1 := MenuOpen;
  It(cmHelp, '~Aide' + #9 + 'F1');
  It(cmUserMenu, '~Menu utilisateur' + #9 + 'F2');
  It(cmView, '~Voir' + #9 + 'F3');
  It(cmEdit, #144'~diter' + #9 + 'F4');
  It(cmCopy, '~Copier' + #9 + 'F5');
  It(cmRenMov, '~Renommer ou d'#130'placer' + #9 + 'F6');
  It(cmMkDir, 'C~r'#130'er un r'#130'pertoire' + #9 + 'F7');
  It(cmDelete, '~Supprimer' + #9 + 'F8');
  Sep;
  It(cmEditNew, '~Nouveau fichier...' + #9 + 'Maj+F4');
  It(cmCopyHere, 'Copier ~ici...' + #9 + 'Maj+F5');
  It(cmRenHere, 'Re~nommer ici...' + #9 + 'Maj+F6');
  It(cmAttrib, 'A~ttributs...' + #9 + 'Ctrl+A');
  It(cmDirSize, 'Tai~lle des r'#130'pertoires');
  Sep;
  It(cmSelGroup, 'S'#130'lectionner un ~groupe...' + #9 + 'Gris +');
  It(cmUnselGroup, '~D'#130's'#130'lectionner un groupe...' + #9 + 'Gris -');
  It(cmInvertSel, '~Inverser la s'#130'lection' + #9 + 'Gris *');
  It(cmRestoreSel, 'Restaurer la s'#130'~lection');
  Sep;
  It(cmQuit, '~Quitter' + #9 + 'F10');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 82, '~Disque');
  H1 := MenuOpen;
  It(cmDiskCopy, '~Copier une disquette...');
  It(cmFormat, '~Formater une disquette...');
  It(cmLabel, '~Nommer le disque...');
  It(cmDiskInfo, '~Informations sur le disque');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 83, '~Commandes');
  H1 := MenuOpen;
  It(cmNcd, '~Arbre NCD' + #9 + 'Alt+F10');
  It(cmFind, '~Recherche de fichiers...' + #9 + 'Alt+F7');
  It(cmHistory, '~Historique' + #9 + 'Alt+F8');
  It(cmMaximize, 'A~grandir la fen'#136'tre' + #9 + 'Alt+F9');
  Sep;
  It(cmSwap, '~Permuter les panneaux' + #9 + 'Ctrl+U');
  It(cmPanelsOnOff, 'Afficher ou ~masquer les panneaux' + #9 + 'Ctrl+O');
  It(cmCompare, '~Comparer les r'#130'pertoires' + #9 + 'Ctrl+F');
  Sep;
  It(cmRunWin, 'E~x'#130'cuter dans une fen'#136'tre OS/2' + #9 + 'Maj+Entr'#130'e');
  It(cmOutput, #144'cran de ~sortie' + #9 + 'Ctrl+O');
  Sep;
  It(cmEditMenu, #144'diter le fichier ~menu (NC.MNU)');
  It(cmEditExt, #144'diter le fichier des ~extensions (NC.EXT)');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 84, '~Options');
  H1 := MenuOpen;
  It(cmConfig, '~Configuration...');
  It(cmEditors, #144'~diteur et visualiseur...');
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 85, 'Co~uleurs');
  H2 := MenuOpen;
  For K := 0 To 2 Do ItA(cmStyle0 + K, Chk(OptStyle = K), '~' + StyleName(K));
  MenuClose(H2);
  Sep;
  ItA(cmKeyBar, Chk(OptKeyBar), '~Barre des touches' + #9 + 'Ctrl+B');
  ItA(cmMiniStatus, Chk(OptMiniStatus), '~Mini-statut');
  ItA(cmClock, Chk(OptClock), '~Horloge');
  ItA(cmHidden, Chk(OptHidden), 'Fichiers ca~ch'#130's et syst'#138'me');
  Sep;
  It(cmSaveCfg, '~Enregistrer la configuration' + #9 + 'Maj+F9');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 86, '~Droite');
  H1 := MenuOpen;
  PanelMenu(cmRight0, 1);
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 87, '~?');
  H1 := MenuOpen;
  It(cmHelp, '~Aide' + #9 + 'F1');
  It(cmKeys, '~Touches');
  Sep;
  It(cmAbout, '~A propos de North Commander...');
  MenuClose(H1);
  MenuClose(H0);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

Procedure SyncMenu;
Var S, B, K : LongInt;
Begin
  For S := 0 To 1 Do
  Begin
    If S = 0 Then B := cmLeft0 Else B := cmRight0;
    SetCheck(B + pcBrief, PMode[S] = pmBrief);
    SetCheck(B + pcFull, PMode[S] = pmFull);
    SetCheck(B + pcInfo, PMode[S] = pmInfo);
    SetCheck(B + pcTree, PMode[S] = pmTree);
    SetCheck(B + pcQuick, PMode[S] = pmQuick);
    SetCheck(B + pcOnOff, PMode[S] <> pmOff);
    SetCheck(B + pcName, PSort[S] = srName);
    SetCheck(B + pcExt, PSort[S] = srExt);
    SetCheck(B + pcTime, PSort[S] = srTime);
    SetCheck(B + pcSize, PSort[S] = srSize);
    SetCheck(B + pcUnsorted, PSort[S] = srNone);
  End;
  For K := 0 To 2 Do SetCheck(cmStyle0 + K, OptStyle = K);
  SetCheck(cmKeyBar, OptKeyBar); SetCheck(cmMiniStatus, OptMiniStatus);
  SetCheck(cmClock, OptClock); SetCheck(cmHidden, OptHidden);
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Procedure Relayout;
Begin
  Layout;
  EnsureVis(0); EnsureVis(1);
  Redraw;
End;

Procedure ConfigDlg;
Begin
  DlgReset;
  DlgCheck('Montrer les fichiers cach'#130's et syst'#138'me', OptHidden);
  DlgCheck('Confirmer les suppressions', OptConfDel);
  DlgCheck('Bo'#140'te de dialogue avant de copier ou d'#130'placer (F5, F6)', OptConfCopy);
  DlgCheck('Confirmer l'''#130'crasement des fichiers', OptConfOver);
  DlgCheck('Ins s'#130'lectionne puis descend', OptInsMoves);
  DlgCheck('R'#130'pertoires avant les fichiers (tri)', OptDirsFirst);
  DlgCheck('Barre des touches de fonction', OptKeyBar);
  DlgCheck('Mini-statut dans les panneaux', OptMiniStatus);
  DlgCheck('Horloge', OptClock);
  DlgCheck('Ex'#130'cuter les commandes dans une fen'#136'tre OS/2', OptExecWin);
  DlgCheck('Menu utilisateur au d'#130'marrage', OptAutoMenu);
  DlgCheck('Enregistrer la configuration en quittant', OptSaveOnExit);
  DlgCombo('Couleurs :', StyleName(0) + '|' + StyleName(1) + '|' + StyleName(2), OptStyle);
  If Not DlgRun('Configuration', 'OK') Then Exit;
  OptHidden := DlgBool(0); OptConfDel := DlgBool(1); OptConfCopy := DlgBool(2); OptConfOver := DlgBool(3);
  OptInsMoves := DlgBool(4); OptDirsFirst := DlgBool(5); OptKeyBar := DlgBool(6); OptMiniStatus := DlgBool(7);
  OptClock := DlgBool(8); OptExecWin := DlgBool(9); OptAutoMenu := DlgBool(10); OptSaveOnExit := DlgBool(11);
  OptStyle := DlgInt(12);
  If (OptStyle < 0) Or (OptStyle > 2) Then OptStyle := 0;
  SetStyle;
  ReReadAll;
  SyncMenu;
  Relayout;
End;

Procedure EditorsDlg;
Begin
  DlgReset;
  DlgCombo('Editeur (F4) :', 'Interne|Externe', OptEditor);
  DlgEdit('Commande de l'''#130'diteur externe :', OptEditCmd);
  DlgCombo('Visualiseur (F3) :', 'Interne|Externe', OptViewer);
  DlgEdit('Commande du visualiseur externe :', OptViewCmd);
  DlgLabel('Dans les commandes : !.! fichier, ! nom sans extension, !: lecteur, !\ r'#130'pertoire.');
  If Not DlgRun(#144'diteur et visualiseur', 'OK') Then Exit;
  OptEditor := DlgInt(0); OptEditCmd := Trim(DfVal[1]);
  OptViewer := DlgInt(2); OptViewCmd := Trim(DfVal[3]);
  If OptEditCmd = '' Then OptEditor := 0;
End;

Procedure DiskInfo;
Var C : Char; Tot, Fr : Double; T, L : String;
Begin
  C := UpCase(PPath[Side][1]);
  L := VolLabel(C);
  If L = '' Then L := '(sans nom)';
  T := 'Disque ' + C + ':' + #13 + 'Nom de volume : ' + L + #13;
  If DiskSpace(C, Tot, Fr) Then
  Begin
    T := T + 'Taille : ' + Thou(Tot) + ' octets' + #13 + 'Libre : ' + Thou(Fr) + ' octets' + #13;
    If Tot > 0 Then T := T + 'Occup'#130' : ' + IStr(Round((Tot - Fr) * 100 / Tot)) + ' %';
  End;
  Msg(T);
End;

Procedure LabelDlg;
Var C : Char;
Begin
  C := UpCase(PPath[Side][1]);
  DlgReset;
  DlgEdit('Nom du volume ' + C + ': (11 caract'#138'res) :', VolLabel(C));
  If Not DlgRun('Nommer le disque', 'OK') Then Exit;
  If Not SetVolLabel(C, Copy(Trim(DfVal[0]), 1, 11)) Then MsgErr('Impossible de changer le nom du volume ' + C + ':')
  Else
  Begin
    StatusMsg := 'Nom du volume ' + C + ': chang'#130;
    InvalPanels; InvalCmd;
  End;
End;

Procedure FloppyTool(Format_ : Boolean);
Var T, P : String;
Begin
  DlgReset;
  If Format_ Then
  Begin
    DlgEdit('Formater le lecteur :', 'A:');
    T := 'Formater une disquette';
  End
  Else
  Begin
    DlgEdit('Copier du lecteur :', 'A:');
    DlgEdit('vers le lecteur :', 'A:');
    T := 'Copier une disquette';
  End;
  If Not DlgRun(T, 'D'#130'marrer') Then Exit;
  If Format_ Then
  Begin
    P := FindExe('FORMAT');
    If P = '' Then P := 'FORMAT';
    If RunWindow(P + ' ' + Trim(DfVal[0]), 'FORMAT') Then ;
  End
  Else
  Begin
    P := FindExe('DISKCOPY');
    If P = '' Then P := 'DISKCOPY';
    If RunWindow(P + ' ' + Trim(DfVal[0]) + ' ' + Trim(DfVal[1]), 'DISKCOPY') Then ;
  End;
End;

Procedure About;
Begin
  Msg(AppTitle + ' ' + NcVersion + ' pour OS/2-0' + #13#13 +
      'Gestionnaire de fichiers '#133' deux panneaux pour le Presentation Manager, d''apr'#138's NC.PAS' + #13 +
      'du d'#130'p'#153't NORTONCOMMANDER-0 (Sylvain Maltais, gladir.com).' + #13#13 +
      'Panneaux bref, complet, info, arbre et vue rapide ; visualiseur ASCII et' + #13 +
      'hexad'#130'cimal ; '#130'diteur ; menu utilisateur ; recherche de fichiers ; NCD.');
End;

Procedure QuitApp;
Begin
  If Mode = mdEdit Then
    If Not EdClose Then Exit;
  If ExecOn Then
  Begin
    If Not AskYes('Une commande est en cours. L''arr'#136'ter et quitter ?') Then Exit;
    ExecStop;
  End;
  If OptConfDel Then
    If Not AskYes('Voulez-vous quitter North Commander ?') Then Exit;
  If OptSaveOnExit Then SaveIni;
  Dummy := WinPostMsg(Client, WM_QUIT, 0, 0);
End;

Procedure ToggleMax;
Var Fl : LongInt; Rc : Array[0..3] Of LongInt; Sw, Sh : LongInt;
Begin
  { Alt+F9 de NC (lignes EGA) : la fenetre occupe tout l'ecran ou revient }
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinQueryWindowRect(Frame, LongInt(@Rc));
  If (Rc[2] - Rc[0] >= Sw) And (Rc[3] - Rc[1] >= Sh - 2) Then Fl := SWP_RESTORE Else Fl := SWP_MAXIMIZE;
  Dummy := WinSetWindowPos(Frame, 0, 0, 0, 0, 0, Fl);
End;

Procedure PanelCmd(S, P : LongInt);
Begin
  Case P Of
    pcBrief : SetPanelMode(S, pmBrief);
    pcFull : SetPanelMode(S, pmFull);
    pcInfo : SetPanelMode(S, pmInfo);
    pcTree : SetPanelMode(S, pmTree);
    pcQuick : SetPanelMode(S, pmQuick);
    pcOnOff : SetPanelMode(S, pmOff);
    pcName : SetSort(S, srName);
    pcExt : SetSort(S, srExt);
    pcTime : SetSort(S, srTime);
    pcSize : SetSort(S, srSize);
    pcUnsorted : SetSort(S, srNone);
    pcReread :
      Begin
        If PMode[S] = pmTree Then
        Begin
          NTree := 0;
          TreeSync(S);
        End;
        ReReadAll;
      End;
    pcFilter : FilterDlg(S);
    pcDrive : DriveOpen(S);
  End;
  SyncMenu;
End;

Procedure DoCmd(C : LongInt);
Begin
  If (Mode = mdList) Or (Mode = mdDrive) Then
    If (C <> cmQuit) And (C <> cmHelp) Then
    Begin
      Mode := mdPanels;
      InvalPanels;
    End;
  If (Mode = mdView) Or (Mode = mdHelp) Then
    If (C <> cmQuit) And (C <> cmHelp) And (C <> cmAbout) Then ViewClose;
  If Mode = mdEdit Then
    If (C <> cmQuit) And (C <> cmHelp) And (C <> cmAbout) Then
      If Not EdClose Then Exit;
  If (C >= cmLeft0) And (C < cmLeft0 + 16) Then
  Begin
    PanelCmd(0, C - cmLeft0);
    Exit;
  End;
  If (C >= cmRight0) And (C < cmRight0 + 16) Then
  Begin
    PanelCmd(1, C - cmRight0);
    Exit;
  End;
  If (C >= cmStyle0) And (C < cmStyle0 + 3) Then
  Begin
    OptStyle := C - cmStyle0;
    SetStyle;
    SyncMenu;
    Redraw;
    Exit;
  End;
  Case C Of
    cmHelp, cmKeys : ShowHelp;
    cmUserMenu : UserMenu;
    cmView : ViewCur;
    cmEdit : EditCur;
    cmCopy : CopyMove(False, False);
    cmRenMov : CopyMove(True, False);
    cmMkDir : DoMkDir;
    cmDelete : DoDelete;
    cmAttrib : DoAttrib;
    cmSelGroup : SelGroup(True);
    cmUnselGroup : SelGroup(False);
    cmInvertSel : InvertSel;
    cmRestoreSel : RestoreSel;
    cmQuit : QuitApp;
    cmEditNew : EditNew;
    cmCopyHere : CopyMove(False, True);
    cmRenHere : CopyMove(True, True);
    cmDirSize : ShowDirSize;
    cmDiskCopy : FloppyTool(False);
    cmFormat : FloppyTool(True);
    cmLabel : LabelDlg;
    cmDiskInfo : DiskInfo;
    cmNcd : NcdOpen(False);
    cmFind : FindFiles;
    cmHistory : HistoryList;
    cmMaximize : ToggleMax;
    cmSwap : SwapPanels;
    cmPanelsOnOff, cmOutput :
      Begin
        If Mode = mdOutput Then Mode := mdPanels Else Mode := mdOutput;
        InvalPanels; InvalCmd;
      End;
    cmCompare : CompareDirs;
    cmRunWin :
      If Trim(CmdLine) <> '' Then
      Begin
        AddHist(CmdLine);
        RunCommand(CmdLine, True);
        CmdLine := ''; CmdPos := 0;
        InvalCmd;
      End
      Else If IsFilePanel(Side) And (NEnt[Side] > 0) And Not IsDirE(Ent[Side]^[CurI[Side]]) Then
        RunCommand(QArg(CurName(Side)), True);
    cmEditMenu : EditMenuFile;
    cmEditExt : EditExtFile;
    cmTogglePanel : ;
    cmConfig : ConfigDlg;
    cmEditors : EditorsDlg;
    cmKeyBar :
      Begin
        OptKeyBar := Not OptKeyBar;
        SyncMenu;
        Relayout;
      End;
    cmClock :
      Begin
        OptClock := Not OptClock;
        SyncMenu;
        InvalCmd;
      End;
    cmMiniStatus :
      Begin
        OptMiniStatus := Not OptMiniStatus;
        SyncMenu;
        Relayout;
      End;
    cmHidden :
      Begin
        OptHidden := Not OptHidden;
        SyncMenu;
        NTree := 0;
        ReReadAll;
      End;
    cmSaveCfg :
      Begin
        SaveIni;
        StatusMsg := 'Configuration enregistr'#130'e dans ' + IniName;
        InvalCmd;
      End;
    cmAbout : About;
  End;
  SyncMenu;
End;

{ ==================================================================== }
{ Touches de fonction (clavier ou barre du bas)                         }
{ ==================================================================== }

Procedure PanelsFKey(K, M : LongInt);
Begin
  Case M Of
    kmShift :
      Case K Of
        4 : DoCmd(cmEditNew);
        5 : DoCmd(cmCopyHere);
        6 : DoCmd(cmRenHere);
        9 : DoCmd(cmSaveCfg);
      End;
    kmAlt :
      Case K Of
        1 : DriveOpen(0);
        2 : DriveOpen(1);
        7 : DoCmd(cmFind);
        8 : DoCmd(cmHistory);
        9 : DoCmd(cmMaximize);
        10 : DoCmd(cmNcd);
      End;
    kmCtrl :
      Case K Of
        1 : PanelCmd(0, pcOnOff);
        2 : PanelCmd(1, pcOnOff);
        3 : SetSort(Side, srName);
        4 : SetSort(Side, srExt);
        5 : SetSort(Side, srTime);
        6 : SetSort(Side, srSize);
        7 : SetSort(Side, srNone);
      End;
  Else
    Case K Of
      1 : DoCmd(cmHelp);
      2 : DoCmd(cmUserMenu);
      3 : DoCmd(cmView);
      4 : DoCmd(cmEdit);
      5 : DoCmd(cmCopy);
      6 : DoCmd(cmRenMov);
      7 : DoCmd(cmMkDir);
      8 : DoCmd(cmDelete);
      9 : Dummy := WinPostMsg(Frame, WM_SYSCOMMAND, SC_APPMENU, 2);
      10 : DoCmd(cmQuit);
    End;
  End;
  SyncMenu;
End;

Procedure FKey(K, M : LongInt);
Begin
  Case Mode Of
    mdView, mdHelp : ViewFKey(K, M);
    mdEdit : EdFKey(K, M);
    mdList : If (K = 1) Then ShowHelp Else ListFKey(K, M);
    mdDrive :
      Begin
        Mode := mdPanels;
        InvalPanels;
        If K = 10 Then Exit;
        PanelsFKey(K, M);
      End;
  Else
    PanelsFKey(K, M);
  End;
End;

{ ==================================================================== }
{ Clavier                                                               }
{ ==================================================================== }

Procedure SetKeyMod(M : LongInt);
Begin
  If M = KeyMod Then Exit;
  KeyMod := M;
  InvalKeys;
End;

Function PollMod : LongInt;
Var M, St : LongInt;
Begin
  { etat reel des touches (le noyau) : Maj 1 et 2, Ctrl 4, Alt 8 }
  M := kmNone;
  St := KrnKbdCtl(0, 0);
  If (St And 8) <> 0 Then M := kmAlt
  Else If (St And 4) <> 0 Then M := kmCtrl
  Else If (St And 3) <> 0 Then M := kmShift;
  PollMod := M;
End;

Function DriveKey(Vk, Ch_ : LongInt) : Boolean;
Var K : LongInt; C : Char;
Begin
  DriveKey := True;
  Case Vk Of
    VK_LEFT, VK_UP : If DrvCur > 0 Then Dec(DrvCur);
    VK_RIGHT, VK_DOWN : If DrvCur < NDrv - 1 Then Inc(DrvCur);
    VK_HOME : DrvCur := 0;
    VK_END : DrvCur := NDrv - 1;
    VK_NEWLINE, VK_ENTER :
      Begin
        DriveChoose;
        Exit;
      End;
    VK_ESC :
      Begin
        Mode := mdPanels;
        InvalPanels;
        Exit;
      End;
  Else
    Begin
      C := UpCase(Chr(Ch_ And 255));
      For K := 0 To NDrv - 1 Do
        If DrvL[K] = C Then
        Begin
          DrvCur := K;
          DriveChoose;
          Exit;
        End;
      DriveKey := False;
      Exit;
    End;
  End;
  InvalPanels;
End;

Procedure TreeKey(Vk : LongInt);
Var R : LongInt; X1, Y1_, X2, Y2 : LongInt;
Begin
  PanRect(Side, X1, Y1_, X2, Y2);
  R := (Y2 - 6 - Y1_ - 25) Div ChH;
  Case Vk Of
    VK_UP : If TreeCur > 0 Then Dec(TreeCur);
    VK_DOWN : If TreeCur < NTree - 1 Then Inc(TreeCur);
    VK_PAGEUP : TreeCur := MaxI(0, TreeCur - R + 1);
    VK_PAGEDOWN : TreeCur := MinI(NTree - 1, TreeCur + R - 1);
    VK_HOME : TreeCur := 0;
    VK_END : TreeCur := NTree - 1;
    VK_LEFT :
      Begin
        { vers le repertoire parent dans l'arbre }
        R := TreeCur;
        While (R > 0) And (TreeD[R] >= TreeD[TreeCur]) Do Dec(R);
        TreeCur := R;
      End;
    VK_RIGHT : If (TreeCur < NTree - 1) And (TreeD[TreeCur + 1] > TreeD[TreeCur]) Then Inc(TreeCur);
  End;
  TreeFollow;
  InvalPanels;
End;

{ touches des panneaux (et de la ligne de commande) }
Function PanelKey(Fl_, Vk, Ch_, Sc : LongInt) : Boolean;
Var Ctrl, Shift, Alt, Virt : Boolean; S, K, R : LongInt;
Begin
  PanelKey := True;
  Ctrl := (Fl_ And KC_CTRL) <> 0;
  Shift := (Fl_ And KC_SHIFT) <> 0;
  Alt := (Fl_ And KC_ALT) <> 0;
  Virt := (Fl_ And KC_VIRTUALKEY) <> 0;
  S := Side;
  { pave numerique gris : selection, si la ligne de commande est vide }
  If (CmdLine = '') And Not Ctrl And Not Alt And ((Fl_ And KC_CHAR) <> 0) Then
  Begin
    If (Sc = $4E) And (Ch_ = Ord('+')) Then Begin DoCmd(cmSelGroup); Exit; End;
    If (Sc = $4A) And (Ch_ = Ord('-')) Then Begin DoCmd(cmUnselGroup); Exit; End;
    If (Sc = $37) And (Ch_ = Ord('*')) Then Begin DoCmd(cmInvertSel); Exit; End;
  End;
  If Virt Then
  Begin
    If (Vk <> VK_SHIFT) And (Vk <> VK_CTRL) And (Vk <> VK_ALT) And QuickOn Then
      If (Vk <> VK_BACKSPACE) Then QuickEnd;
    Case Vk Of
      VK_TAB, VK_BACKTAB :
        Begin
          If IsFilePanel(1 - S) Or (PMode[1 - S] = pmTree) Then Side := 1 - S;
          If Mode = mdOutput Then Mode := mdPanels;
          QuickEnd;
          SetTitle;
          InvalPanels; InvalCmd;
          Exit;
        End;
      VK_NEWLINE, VK_ENTER :
        Begin
          If Ctrl Then
          Begin
            If IsFilePanel(S) And (CurName(S) <> '..') Then CmdInsert(QArg(CurName(S)) + ' ');
          End
          Else If Shift Then DoCmd(cmRunWin)
          Else If Trim(CmdLine) <> '' Then ExecLine
          Else If Mode = mdPanels Then EnterItem;
          Exit;
        End;
      VK_ESC :
        Begin
          If ExecOn Then ExecStop
          Else If CmdLine <> '' Then
          Begin
            CmdLine := ''; CmdPos := 0;
            InvalCmd;
          End
          Else If Mode = mdOutput Then
          Begin
            Mode := mdPanels;
            InvalPanels;
          End;
          Exit;
        End;
      VK_BACKSPACE :
        Begin
          If QuickOn Then
          Begin
            Quick := Copy(Quick, 1, Length(Quick) - 1);
            StatusMsg := 'Recherche rapide : ' + Quick;
            If Quick = '' Then StatusMsg := '';
            InvalCmd;
          End
          Else If CmdPos > 0 Then
          Begin
            Delete(CmdLine, CmdPos, 1);
            Dec(CmdPos);
            InvalCmd;
          End;
          Exit;
        End;
    End;
    { la ligne de commande non vide garde les fleches gauche et droite }
    If (CmdLine <> '') And Not Ctrl Then
      Case Vk Of
        VK_LEFT : Begin If CmdPos > 0 Then Dec(CmdPos); InvalCmd; Exit; End;
        VK_RIGHT : Begin If CmdPos < Length(CmdLine) Then Inc(CmdPos); InvalCmd; Exit; End;
        VK_HOME : Begin CmdPos := 0; InvalCmd; Exit; End;
        VK_END : Begin CmdPos := Length(CmdLine); InvalCmd; Exit; End;
        VK_DELETE : Begin If CmdPos < Length(CmdLine) Then Delete(CmdLine, CmdPos + 1, 1); InvalCmd; Exit; End;
      End;
    If Mode = mdOutput Then
    Begin
      If (Vk = VK_UP) Or (Vk = VK_DOWN) Then
      Begin
        If Vk = VK_UP Then HistStep(-1) Else HistStep(1);
        Exit;
      End;
      PanelKey := False;
      Exit;
    End;
    If PMode[S] = pmTree Then
      Case Vk Of
        VK_UP, VK_DOWN, VK_PAGEUP, VK_PAGEDOWN, VK_HOME, VK_END, VK_LEFT, VK_RIGHT :
          Begin
            TreeKey(Vk);
            Exit;
          End;
      End;
    If IsFilePanel(S) Then
    Begin
      R := ListRows(S);
      Case Vk Of
        VK_UP : Begin MoveCur(S, -1); Exit; End;
        VK_DOWN : Begin MoveCur(S, 1); Exit; End;
        VK_PAGEUP :
          Begin
            If Ctrl Then GoParent(S) Else MoveCur(S, -(PageSize(S) - 1));
            Exit;
          End;
        VK_PAGEDOWN :
          Begin
            If Ctrl Then
            Begin
              If (NEnt[S] > 0) And IsDirE(Ent[S]^[CurI[S]]) Then EnterItem;
            End
            Else MoveCur(S, PageSize(S) - 1);
            Exit;
          End;
        VK_HOME : Begin SetCur(S, 0); Exit; End;
        VK_END : Begin SetCur(S, NEnt[S] - 1); Exit; End;
        VK_LEFT :
          Begin
            If PMode[S] = pmBrief Then MoveCur(S, -R) Else SetCur(S, 0);
            Exit;
          End;
        VK_RIGHT :
          Begin
            If PMode[S] = pmBrief Then MoveCur(S, R) Else SetCur(S, NEnt[S] - 1);
            Exit;
          End;
        VK_INSERT :
          Begin
            ToggleSel(S, CurI[S]);
            If OptInsMoves Then MoveCur(S, 1) Else UpdPanel(S);
            Exit;
          End;
      End;
    End;
  End;
  { Ctrl+lettre }
  If Ctrl And Not Alt And (Ch_ > 0) And (Ch_ < 128) Then
  Begin
    K := Ch_;
    If (K >= 1) And (K <= 26) Then K := K + 96;
    If (K >= 65) And (K <= 90) Then K := K + 32;
    Case K Of
      Ord('a') : Begin DoCmd(cmAttrib); Exit; End;
      Ord('b') : Begin DoCmd(cmKeyBar); Exit; End;
      Ord('e') : Begin HistStep(-1); Exit; End;
      Ord('x') : Begin HistStep(1); Exit; End;
      Ord('f') : Begin DoCmd(cmCompare); Exit; End;
      Ord('l') : Begin SetPanelMode(1 - Side, pmInfo); SyncMenu; Exit; End;
      Ord('q') : Begin SetPanelMode(1 - Side, pmQuick); SyncMenu; Exit; End;
      Ord('o') : Begin DoCmd(cmPanelsOnOff); Exit; End;
      Ord('u') : Begin DoCmd(cmSwap); Exit; End;
      Ord('r') :
        Begin
          If S = 0 Then PanelCmd(0, pcReread) Else PanelCmd(1, pcReread);
          Exit;
        End;
      Ord('p') : Begin PanelCmd(1 - Side, pcOnOff); Exit; End;
      Ord('s') :
        Begin
          Quick := ''; QuickOn := True;
          StatusMsg := 'Recherche rapide : tapez le d'#130'but du nom';
          InvalCmd;
          Exit;
        End;
      Ord('\'), 28 : Begin GoRoot(S); Exit; End;
      Ord('['), 27 : Begin CmdInsert(QArg(PPath[0]) + ' '); Exit; End;
      Ord(']'), 29 : Begin CmdInsert(QArg(PPath[1]) + ' '); Exit; End;
    End;
  End;
  { caracteres : recherche rapide ou ligne de commande }
  If ((Fl_ And KC_CHAR) <> 0) And Not Ctrl And Not Alt And (Ch_ >= 32) And (Ch_ < 256) Then
  Begin
    If QuickOn Then
    Begin
      If Ch_ = 32 Then QuickEnd Else QuickKey(Chr(Ch_));
      Exit;
    End;
    CmdInsert(Chr(Ch_));
    Exit;
  End;
  If Alt And ((Fl_ And KC_CHAR) <> 0) And (Ch_ > 32) And (Ch_ < 128) And Not Ctrl Then
  Begin
    { Alt+lettre : recherche rapide, comme Norton Commander ; les lettres
      des menus (Gauche, Fichiers, Disque, Commandes, Options, Droite)
      restent a la barre de menus d'OS/2 }
    If Pos(UpCase(Chr(Ch_)), 'GFDCOR') > 0 Then
    Begin
      PanelKey := False;
      Exit;
    End;
    QuickKey(Chr(Ch_));
    Exit;
  End;
  PanelKey := False;
End;

Function Key(Mp1, Mp2 : LongInt) : Boolean;
Var Fl_, Ch_, Vk, Sc, M : LongInt; Ctrl, Shift : Boolean;
Begin
  Key := True;
  Fl_ := Lo16(Mp1); Ch_ := Lo16(Mp2); Vk := Hi16(Mp2);
  Sc := (Mp1 Shr 24) And 255;
  If (Fl_ And KC_VIRTUALKEY) <> 0 Then
    If (Vk = VK_SHIFT) Or (Vk = VK_CTRL) Or (Vk = VK_ALT) Then
    Begin
      SetKeyMod(PollMod);
      Key := False;
      Exit;
    End;
  If (Fl_ And KC_KEYUP) <> 0 Then
  Begin
    Key := False;
    Exit;
  End;
  Ctrl := (Fl_ And KC_CTRL) <> 0;
  Shift := (Fl_ And KC_SHIFT) <> 0;
  If (Fl_ And KC_VIRTUALKEY) = 0 Then Vk := 0;
  { Maj+F4 et Maj+F5 arrivent comme F11 et F12 (codes 57h et 58h) }
  If Shift And (Vk = VK_F11) Then Vk := VK_F4;
  If Shift And (Vk = VK_F12) Then Vk := VK_F5;
  { touches de fonction }
  If (Vk >= VK_F1) And (Vk <= VK_F1 + 9) Then
  Begin
    M := kmNone;
    If (Fl_ And KC_ALT) <> 0 Then M := kmAlt
    Else If Ctrl Then M := kmCtrl
    Else If Shift Then M := kmShift;
    QuickEnd;
    FKey(Vk - VK_F1 + 1, M);
    Exit;
  End;
  Case Mode Of
    mdView, mdHelp : Key := ViewKey(Vk, Ch_, Ctrl, Shift);
    mdEdit : Key := EdKey(Vk, Ch_, Ctrl, Shift);
    mdList : Key := ListKey(Vk, Ch_, Ctrl, Shift);
    mdDrive : Key := DriveKey(Vk, Ch_);
  Else
    Key := PanelKey(Fl_, Vk, Ch_, Sc);
  End;
End;

{ ==================================================================== }
{ Souris                                                                }
{ ==================================================================== }

Function PanelAt(X : LongInt) : LongInt;
Begin
  If X < CW Div 2 Then PanelAt := 0 Else PanelAt := 1;
End;

{ element sous la souris ; -1 : aucun ; -2..-5 : en-tete des colonnes (tri) }
Function ItemAt(S, X, Y : LongInt) : LongInt;
Var X1, Y1_, X2, Y2, Rows, Cw_, C, R, I, Nw, Px : LongInt;
Begin
  ItemAt := -1;
  If Not IsFilePanel(S) Then Exit;
  ListRect(S, X1, Y1_, X2, Y2);
  If (X < X1) Or (X > X2) Then Exit;
  If (PMode[S] = pmFull) And (Y >= Y1_ - 18) And (Y < Y1_) Then
  Begin
    Nw := PanChars(S) - 26;
    If Nw < 6 Then Nw := 6;
    Px := X1 + 4 + Nw * ChW + 3;
    If X < Px Then ItemAt := -2
    Else If X < Px + 10 * ChW + 8 Then ItemAt := -3
    Else ItemAt := -4;
    Exit;
  End;
  If (Y < Y1_) Or (Y > Y2) Then Exit;
  Rows := ListRows(S);
  R := (Y - Y1_) Div ChH;
  If R >= Rows Then Exit;
  If PMode[S] = pmBrief Then
  Begin
    Cw_ := (X2 - X1 + 1) Div 3;
    C := MinI(2, (X - X1) Div Cw_);
    I := TopI[S] + C * Rows + R;
  End
  Else I := TopI[S] + R;
  If I < NEnt[S] Then ItemAt := I;
End;

Procedure MouseDown(X, Y : LongInt; Dbl : Boolean);
Var S, I, K, X1, Y1_, X2, Y2 : LongInt;
Begin
  { barre des touches }
  If OptKeyBar And (Y >= KbY) Then
  Begin
    K := X * 10 Div CW + 1;
    If (K >= 1) And (K <= 10) Then
    Begin
      KbDown := K;
      InvalKeys;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
    End;
    Exit;
  End;
  Case Mode Of
    mdView, mdHelp, mdEdit :
      Begin
        If (Mode = mdEdit) And (Y >= 26) Then
        Begin
          EdY := EdTop + (Y - 26) Div ChH;
          EdX := EdLeft + (X - 8) Div ChW;
          If EdX < 0 Then EdX := 0;
          EdFix;
        End;
        Exit;
      End;
    mdList :
      Begin
        ListBox(X1, Y1_, X2, Y2);
        If (X < X1) Or (X > X2) Or (Y < Y1_) Or (Y > Y2) Then
        Begin
          ListClose;
          Exit;
        End;
        I := LsTop + (Y - Y1_ - 28) Div ChH;
        If (Y >= Y1_ + 28) And (I >= 0) And (I < LsN) And (I < LsTop + ListRowsN) Then
        Begin
          LsCur := I;
          InvalPanels;
          If Dbl Then ListEnter;
        End;
        Exit;
      End;
    mdDrive :
      Begin
        For K := 0 To NDrv - 1 Do
        Begin
          DriveCell(K, X1, Y1_);
          If (X >= X1) And (X <= X1 + 31) And (Y >= Y1_) And (Y <= Y1_ + 23) Then
          Begin
            DrvCur := K;
            DriveChoose;
            Exit;
          End;
        End;
        Mode := mdPanels;
        InvalPanels;
        Exit;
      End;
    mdOutput :
      Begin
        If Y <= PanY2 Then
        Begin
          Mode := mdPanels;
          InvalPanels;
        End;
        Exit;
      End;
  End;
  If Y > PanY2 Then Exit;
  S := PanelAt(X);
  If PMode[S] = pmTree Then
  Begin
    PanRect(S, X1, Y1_, X2, Y2);
    I := TreeTop + (Y - Y1_ - 25) Div ChH;
    If (Y >= Y1_ + 25) And (I >= 0) And (I < NTree) Then
    Begin
      Side := S;
      TreeCur := I;
      TreeFollow;
      If Dbl Then EnterItem;
      SetTitle;
      InvalPanels;
    End;
    Exit;
  End;
  If Not IsFilePanel(S) Then Exit;
  QuickEnd;
  If S <> Side Then
  Begin
    Side := S;
    SetTitle;
    InvalPanels; InvalCmd;
  End;
  I := ItemAt(S, X, Y);
  If I = -2 Then SetSort(S, srName)
  Else If I = -3 Then SetSort(S, srSize)
  Else If I = -4 Then SetSort(S, srTime)
  Else If I >= 0 Then
  Begin
    CurI[S] := I;
    UpdPanel(S);
    If Dbl Then EnterItem;
  End;
  SyncMenu;
End;

Procedure MouseUp(X, Y : LongInt);
Var K : LongInt;
Begin
  If KbDown > 0 Then
  Begin
    K := KbDown;
    KbDown := 0;
    Dummy := WinSetCapture(HWND_DESKTOP, 0);
    InvalKeys;
    If (Y >= KbY) And (X * 10 Div CW + 1 = K) Then FKey(K, PollMod);
  End;
End;

Procedure RightClick(X, Y : LongInt);
Var S, I : LongInt;
Begin
  If (Mode <> mdPanels) Or (Y > PanY2) Then Exit;
  S := PanelAt(X);
  If Not IsFilePanel(S) Then Exit;
  Side := S;
  I := ItemAt(S, X, Y);
  If I >= 0 Then
  Begin
    { bouton 2 : selectionner, comme Norton Commander }
    ToggleSel(S, I);
    CurI[S] := I;
    UpdPanel(S);
  End;
  SetTitle;
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

Procedure Tick;
Var Dt : Array[0..15] Of Byte; Cl : String;
Begin
  SetKeyMod(PollMod);
  ExecPoll;
  If OptClock Then
  Begin
    Dummy := DosGetDateTime(LongInt(@Dt));
    Cl := Z2D(Dt[0]) + ':' + Z2D(Dt[1]) + ':' + Z2D(Dt[2]);
    If Cl <> LastClock Then
    Begin
      LastClock := Cl;
      If (Mode = mdPanels) Or (Mode = mdOutput) Or (Mode = mdList) Or (Mode = mdDrive) Then
        InvalBand(CW - 80, CmdY, CW, CmdY + CmdH);
    End;
  End;
End;

Function FrameProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Begin
  FrameProc := 0;
  If (Msg_ = WM_SYSCOMMAND) And (Lo16(Mp2) = CMDSRC_ACCELERATOR) Then
  Begin
    { F10, Alt+F9 et Alt+F10 sont des touches de Norton Commander }
    If Lo16(Mp1) = SC_APPMENU Then
    Begin
      FKey(10, kmNone);
      Exit;
    End;
    If Lo16(Mp1) = SC_MINIMIZE Then
    Begin
      FKey(9, kmAlt);
      Exit;
    End;
    If Lo16(Mp1) = SC_MAXIMIZE Then
    Begin
      FKey(10, kmAlt);
      Exit;
    End;
  End;
  FrameProc := WinSysClassProc(H, Msg_, Mp1, Mp2);
End;

Function ClientProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; X, Y : LongInt;
Begin
  ClientProc := 0;
  Case Msg_ Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
        Relayout;
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
    WM_BUTTON2DOWN :
      Begin
        RightClick(S16(Mp1), CH - 1 - S16(Mp1 Shr 16));
        ClientProc := 1;
      End;
    WM_CHAR :
      If Key(Mp1, Mp2) Then ClientProc := 1
      Else ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
    WM_COMMAND : DoCmd(Lo16(Mp1));
    WM_TIMER : Tick;
    WM_CLOSE : QuitApp;
  Else
    ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
  End;
End;

Function CanWriteDir(D : String) : Boolean;
Var H : LongInt; N : String;
Begin
  CanWriteDir := False;
  N := JoinPath(D, 'NC$TEST.TMP');
  If Not FOpenWrite(N, H) Then Exit;
  DosClose(H);
  Dummy := DosDelete(Z(N));
  CanWriteDir := True;
End;

Function CurDirStr : String;
Var D, M, L : LongInt; B : Array[0..259] Of Byte; R : String; K : LongInt;
Begin
  D := 0; M := 0;
  Dummy := DosQueryCurrentDisk(LongInt(@D), LongInt(@M));
  R := '';
  If (D >= 1) And (D <= 26) Then
  Begin
    L := 256;
    R := Chr(64 + D) + ':\';
    If DosQueryCurrentDir(0, LongInt(@B), LongInt(@L)) = 0 Then
    Begin
      K := 0;
      While (K < 255) And (B[K] <> 0) Do
      Begin
        R := R + Chr(B[K]); Inc(K);
      End;
    End;
  End;
  If (Length(R) > 3) And (R[Length(R)] = '\') Then R := Copy(R, 1, Length(R) - 1);
  CurDirStr := R;
End;

Procedure Main;
Var Fl0, Sw, Sh, Fw, Fh, K : LongInt; A, D : String;
Begin
  InitFs;
  OutL := Nil; EdL := Nil; NOut := 0;
  BufInit(VBuf); BufInit(QvBuf);
  Mode := mdPanels; Side := 0; KeyMod := kmNone; KbDown := 0;
  CmdLine := ''; CmdPos := 0; StatusMsg := ''; Quick := ''; QuickOn := False; LastClock := '';
  ExecOn := False; ShieldOk := False; QvName := '#';
  VHex := False; VWrap := False; VSearch := ''; VCase := False; VHexS := False; EdSearch := '';
  GroupMask := '*.*';
  NPrevSel[0] := 0; NPrevSel[1] := 0; PPrev[0] := pmFull; PPrev[1] := pmFull;
  For K := 0 To 25 Do DrvLast[K] := '';
  CtxMenu := 0; Drag := dNone; DgBtns := '';
  { repertoire de travail (NC.INI, NC.MNU, NC.EXT, sortie des commandes) }
  WorkDir := 'C:\';
  If Not CanWriteDir(WorkDir) Then
    If CanWriteDir('D:\') Then WorkDir := 'D:\';
  IniName := JoinPath(WorkDir, 'NC.INI');
  D := CurDirStr;
  If (D = '') Or Not DirExists(D) Then D := Copy(WorkDir, 1, 3);
  PPath[0] := D; PPath[1] := D;
  LoadIni;
  { parametres : repertoires des panneaux gauche et droit }
  For K := 1 To MinI(2, ParamCount) Do
  Begin
    A := ParamStr(K);
    If (A <> '') And (A[1] <> '/') And (A[1] <> '-') Then
    Begin
      If (Length(A) = 2) And (A[2] = ':') Then A := A + '\';
      If (Length(A) > 3) And (A[Length(A)] = '\') Then A := Copy(A, 1, Length(A) - 1);
      If DirExists(A) Then PPath[K - 1] := A;
    End;
  End;
  If Not DirExists(PPath[0]) Then PPath[0] := D;
  If Not DirExists(PPath[1]) Then PPath[1] := D;
  For K := 0 To 1 Do
  Begin
    If PMode[K] = pmTree Then PMode[K] := pmFull;
    If PMode[K] = pmOff Then PMode[K] := pmFull;
    ReadPanel(K, '');
    DrvLast[Ord(UpCase(PPath[K][1])) - 65] := PPath[K];
  End;
  GetMem(OutL, MaxOut * SizeOf(String));
  SetStyle;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('NCMAIN'), LongInt(@ClientProc), 0, 0);
  Fl0 := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl0), Z('NCMAIN'), Z2(AppTitle), 0, 0, 0, LongInt(@Client));
  Dummy := WinSubclassWindow(Frame, LongInt(@FrameProc));
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
  BuildMenu;
  SetTitle;
  Layout;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Layout;
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  Dummy := WinStartTimer(Hab, Client, 1, 150);
  If OptAutoMenu Then Dummy := WinPostMsg(Client, WM_COMMAND, cmUserMenu, 0);
  While WinGetMsg(Hab, LongInt(@GQmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@GQmsg));
  Dummy := WinDestroyWindow(Frame);
End;

BEGIN
  Main;
END.
