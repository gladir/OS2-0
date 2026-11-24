{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: SQLDEV - SQL Developer, outil des bases de donnees
                (PostgreSQL, MariaDB et MySQL, SQL Server en fichiers .MDF,
                tables en fichiers dBASE, CSV, Clarion, Btrieve, MyISAM)
                pour le Presentation Manager d'OS/2-0.
}

Program SqlDev;

{$R-,S-,I-}

{ Compilation : OS2PC APPS\SQLDEV.PAS SQLDEV.EXE

  SQL Developer (dossier Developer Kit du bureau) : un outil des bases de
  donnees dans l'esprit de SQL Server Management Studio, avec l'apparence
  et les menus d'OS/2 :
    - a gauche, l'Explorateur d'objets : un arbre des connexions, deplie a
      la demande (serveur, bases de donnees, schemas, tables, vues,
      colonnes, index, procedures, fonctions, sequences, declencheurs,
      utilisateurs) ;
    - a droite, en haut, l'editeur SQL a coloration syntaxique (mots-cles,
      types, fonctions, chaines, nombres, commentaires), plusieurs requetes
      ouvertes dans des onglets ;
    - a droite, en bas, les resultats : une grille par jeu de resultats
      (numeros de ligne, colonnes redimensionnables, NULL), et l'onglet
      Messages (lignes touchees, erreurs du serveur, durees) ;
    - menus deroulants d'OS/2 : Fichier, Edition, Affichage, Requete,
      Outils, Fenetre, ? ; barre d'outils ; barre d'etat (connexion,
      base de donnees, lignes, duree).
  Sources de donnees :
    - PostgreSQL : protocole v3 (SCRAM-SHA-256, md5, en clair) ;
    - MariaDB et MySQL : protocole 4.1 (mysql_native_password,
      caching_sha2_password) ;
    - SQL Server : fichiers .MDF lus et ecrits par SQLCMD.EXE, le clone de
      SQL Server en ligne de commande d'OS/2-0 (programme separe), comme
      l'Explorateur SQL Server de DEVENV ;
    - tables en fichiers : dBASE III (.DBF, memos .DBT), CSV, Clarion
      (.DAT), Btrieve (.DAT, format d'origine), MyISAM de MySQL (.MYD,
      lecture seule) ; SELECT (DISTINCT, TOP, WHERE, GROUP BY, HAVING,
      ORDER BY, LIMIT/OFFSET, agregats, CASE, LIKE, IN, fonctions),
      UPDATE, INSERT et DELETE y sont executes par le moteur SQL local de
      SQL Developer, et les cellules se modifient dans la grille (DBF, CSV,
      Clarion, Btrieve).
  Les echanges avec les serveurs sont non bloquants : la minuterie de la
  fenetre les fait avancer, l'interface reste vivante pendant une longue
  requete (bouton Arreter).

  Parametres : fichiers .SQL a ouvrir, une table (.DBF, .CSV, .DAT, .MYD)
  ou une base .MDF ; /DIR dossier (dossier de tables), /PG et /MY
  hote:port:utilisateur:mot de passe:base ; /RUN execute la requete
  ouverte, et /OUT fichier y ecrit les resultats et les messages puis
  ferme SQL Developer (essais automatiques).

  Les connexions sont memorisees dans SQLDEV.INI (C:\, ou D:\ quand C:
  est le CD-ROM) ; le mot de passe seulement si on le demande.

  Origine : le prototype DEVENV (Explorateur SQL Server de DEVENV.PAS) et
  SQLCMD.PAS du depot DEV-COOLS ; les clients PostgreSQL et MariaDB sont
  ceux du Serveur Web d'OS/2-0 (APPS\WEBSRV.PAS), l'editeur celui de Web
  Developer (APPS\WEBDEV.PAS). Tout est dans ce fichier : aucune unite ni
  dependance externe ; SQLCMD.EXE (SQLCMD.PAS, a la racine) reste un
  programme separe. }

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
  TbH = 30; SbH = 20; DocTabH = 20; RowH = 16; ScrW = 16; TabStop = 4; GridRowH = 18; ResTabH = 20;
  { langages de l'editeur }
  lgText = 0; lgSql = 1;
  MaxDoc = 16; MaxNode = 3000;

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
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFileInfo(H, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ofs, Meth, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosCopy(PSrc, PDst, Opt : LongInt) : LongInt; External 'DOSCALLS';
Function Sock_Init : LongInt; External 'TCPIP32' Name 'sock_init';
Function SockSocket(D, T, P : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function SockSend(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function SockRecv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function SockClose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function SockIoctl(S, C, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'ioctl';
Function SockErrno : LongInt; External 'TCPIP32' Name 'sock_errno';

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

{ langage d'apres l'extension }
Function LangOf(N : String) : LongInt;
Var X : String;
Begin
  X := ExtOf(N);
  If (X = 'SQL') Or (X = 'DDL') Or (X = 'PRC') Or (X = 'TAB') Or (X = 'VW') Or (X = '') Then LangOf := lgSql
  Else LangOf := lgText;
End;

Function LangName(L : LongInt) : String;
Begin
  If L = lgSql Then LangName := 'SQL' Else LangName := 'Texte';
End;

Function PTicks : LongInt;
Begin
  PTicks := KTicks;
End;

Procedure PSleep(Ms : LongInt);
Begin
  Dummy := DosSleep(Ms);
End;

{ "a.b.c.d" -> adresse ; 0 : invalide }
Function ParseIp(S : String) : LongInt;
Var K, V, N, R : LongInt;
Begin
  ParseIp := 0;
  R := 0; N := 0; V := -1;
  S := Trim(S) + '.';
  For K := 1 To Length(S) Do
    If (S[K] >= '0') And (S[K] <= '9') Then
    Begin
      If V < 0 Then V := 0;
      V := V * 10 + Ord(S[K]) - 48;
      If V > 255 Then Exit;
    End
    Else If S[K] = '.' Then
    Begin
      If V < 0 Then Exit;
      R := (R Shl 8) Or V;
      Inc(N); V := -1;
    End
    Else Exit;
  If N = 4 Then ParseIp := R;
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
{ Reseau et bases de donnees externes : PostgreSQL, MariaDB (MySQL)     }
{ Code repris du client du Serveur Web d'OS/2-0 (APPS\WEBSRV.PAS) :      }
{ SHA-256 et HMAC, MD5, SHA-1, PBKDF2, protocole v3 de PostgreSQL         }
{ (SCRAM-SHA-256, md5, en clair), protocole 4.1 de MariaDB et MySQL       }
{ (mysql_native_password, caching_sha2_password). Les sockets sont non  }
{ bloquants : SQL Developer fait avancer les echanges par sa minuterie, }
{ la fenetre reste vivante pendant une longue requete.                 }
{ ==================================================================== }

Const
  ShK : Array[0..63] Of LongInt = (
    $428A2F98, $71374491, $B5C0FBCF, $E9B5DBA5, $3956C25B, $59F111F1, $923F82A4, $AB1C5ED5,
    $D807AA98, $12835B01, $243185BE, $550C7DC3, $72BE5D74, $80DEB1FE, $9BDC06A7, $C19BF174,
    $E49B69C1, $EFBE4786, $0FC19DC6, $240CA1CC, $2DE92C6F, $4A7484AA, $5CB0A9DC, $76F988DA,
    $983E5152, $A831C66D, $B00327C8, $BF597FC7, $C6E00BF3, $D5A79147, $06CA6351, $14292967,
    $27B70A85, $2E1B2138, $4D2C6DFC, $53380D13, $650A7354, $766A0ABB, $81C2C92E, $92722C85,
    $A2BFE8A1, $A81A664B, $C24B8B70, $C76C51A3, $D192E819, $D6990624, $F40E3585, $106AA070,
    $19A4C116, $1E376C08, $2748774C, $34B0BCB5, $391C0CB3, $4ED8AA4A, $5B9CCA4F, $682E6FF3,
    $748F82EE, $78A5636F, $84C87814, $8CC70208, $90BEFFFA, $A4506CEB, $BEF9A3F7, $C67178F2);
  ShIv : Array[0..7] Of LongInt = ($6A09E667, $BB67AE85, $3C6EF372, $A54FF53A, $510E527F, $9B05688C,
    $1F83D9AB, $5BE0CD19);

Type
  TSha = Record
    H : Array[0..7] Of LongInt;
    B : Array[0..63] Of Byte;
    N, T : LongInt;
  End;
  TB32 = Array[0..31] Of Byte;
  TBlk = Array[0..15] Of Byte;

{ decalage logique a droite (1 <= N <= 31) }
Function Sr(X, N : LongInt) : LongInt;
Begin
  Sr := (X Shr N) And ($7FFFFFFF Shr (N - 1));
End;

Function Ror(X, N : LongInt) : LongInt;
Begin
  Ror := Sr(X, N) Or (X Shl (32 - N));
End;

Procedure ShaInit(Var C : TSha);
Var I : LongInt;
Begin
  For I := 0 To 7 Do C.H[I] := ShIv[I];
  C.N := 0; C.T := 0;
End;

Procedure ShaBlock(Var C : TSha);
Var W : Array[0..63] Of LongInt;
    A, B, Cc, D, E, F, G, H, T1, T2, I, X : LongInt;
Begin
  For I := 0 To 15 Do
    W[I] := (C.B[I * 4] Shl 24) Or (C.B[I * 4 + 1] Shl 16) Or (C.B[I * 4 + 2] Shl 8) Or C.B[I * 4 + 3];
  For I := 16 To 63 Do
  Begin
    X := W[I - 15];
    T1 := Ror(X, 7) Xor Ror(X, 18) Xor Sr(X, 3);
    X := W[I - 2];
    T2 := Ror(X, 17) Xor Ror(X, 19) Xor Sr(X, 10);
    W[I] := W[I - 16] + T1 + W[I - 7] + T2;
  End;
  A := C.H[0]; B := C.H[1]; Cc := C.H[2]; D := C.H[3];
  E := C.H[4]; F := C.H[5]; G := C.H[6]; H := C.H[7];
  For I := 0 To 63 Do
  Begin
    T1 := H + (Ror(E, 6) Xor Ror(E, 11) Xor Ror(E, 25)) + ((E And F) Xor ((Not E) And G)) + ShK[I] + W[I];
    T2 := (Ror(A, 2) Xor Ror(A, 13) Xor Ror(A, 22)) + ((A And B) Xor (A And Cc) Xor (B And Cc));
    H := G; G := F; F := E; E := D + T1;
    D := Cc; Cc := B; B := A; A := T1 + T2;
  End;
  C.H[0] := C.H[0] + A; C.H[1] := C.H[1] + B; C.H[2] := C.H[2] + Cc; C.H[3] := C.H[3] + D;
  C.H[4] := C.H[4] + E; C.H[5] := C.H[5] + F; C.H[6] := C.H[6] + G; C.H[7] := C.H[7] + H;
End;

Procedure ShaUpd(Var C : TSha; P : PBytes; N : LongInt);
Var K : LongInt;
Begin
  For K := 0 To N - 1 Do
  Begin
    C.B[C.N] := P^[K];
    Inc(C.N);
    If C.N = 64 Then
    Begin
      ShaBlock(C);
      C.N := 0;
    End;
  End;
  C.T := C.T + N;
End;

Procedure ShaStr(Var C : TSha; S : String);
Begin
  If Length(S) > 0 Then ShaUpd(C, @S[1], Length(S));
End;

Procedure ShaFinal(Var C0 : TSha; Var Out_ : TB32);
Var C : TSha; L, I, V : LongInt; Pd : Array[0..71] Of Byte;
Begin
  C := C0;
  L := C.T;
  I := 0;
  Pd[0] := $80;
  I := 1;
  While ((C.N + I) Mod 64) <> 56 Do
  Begin
    Pd[I] := 0;
    Inc(I);
  End;
  Pd[I] := 0; Pd[I + 1] := 0; Pd[I + 2] := 0; Pd[I + 3] := Sr(L, 29);
  V := L Shl 3;
  Pd[I + 4] := Sr(V, 24); Pd[I + 5] := Sr(V, 16) And 255; Pd[I + 6] := Sr(V, 8) And 255; Pd[I + 7] := V And 255;
  ShaUpd(C, @Pd, I + 8);
  For I := 0 To 7 Do
  Begin
    V := C.H[I];
    Out_[I * 4] := Sr(V, 24); Out_[I * 4 + 1] := Sr(V, 16) And 255;
    Out_[I * 4 + 2] := Sr(V, 8) And 255; Out_[I * 4 + 3] := V And 255;
  End;
End;

Procedure Sha256(P : PBytes; N : LongInt; Var Out_ : TB32);
Var C : TSha;
Begin
  ShaInit(C);
  ShaUpd(C, P, N);
  ShaFinal(C, Out_);
End;

Procedure Hmac(K : PBytes; KN : LongInt; M : PBytes; MN : LongInt; Var Out_ : TB32);
Var Kb : Array[0..63] Of Byte; I : LongInt; C : TSha; Inner : TB32;
Begin
  For I := 0 To 63 Do Kb[I] := 0;
  If KN > 64 Then
  Begin
    Sha256(K, KN, Inner);
    For I := 0 To 31 Do Kb[I] := Inner[I];
  End
  Else
    For I := 0 To KN - 1 Do Kb[I] := K^[I];
  For I := 0 To 63 Do Kb[I] := Kb[I] Xor $36;
  ShaInit(C);
  ShaUpd(C, @Kb, 64);
  ShaUpd(C, M, MN);
  ShaFinal(C, Inner);
  For I := 0 To 63 Do Kb[I] := Kb[I] Xor $36 Xor $5C;
  ShaInit(C);
  ShaUpd(C, @Kb, 64);
  ShaUpd(C, @Inner, 32);
  ShaFinal(C, Out_);
End;


Const
  B64 : String[64] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

Procedure B64Enc(P : PBytes; N : LongInt; Var B : TBuf; LineLen : LongInt);
Var K, V, Col : LongInt;
Begin
  K := 0; Col := 0;
  While K < N Do
  Begin
    V := P^[K] Shl 16;
    If K + 1 < N Then V := V Or (P^[K + 1] Shl 8);
    If K + 2 < N Then V := V Or P^[K + 2];
    BufAddC(B, Ord(B64[((V Shr 18) And 63) + 1]));
    BufAddC(B, Ord(B64[((V Shr 12) And 63) + 1]));
    If K + 1 < N Then BufAddC(B, Ord(B64[((V Shr 6) And 63) + 1])) Else BufAddC(B, Ord('='));
    If K + 2 < N Then BufAddC(B, Ord(B64[(V And 63) + 1])) Else BufAddC(B, Ord('='));
    K := K + 3;
    Col := Col + 4;
    If (LineLen > 0) And (Col >= LineLen) And (K < N) Then
    Begin
      BufAddC(B, 10);
      Col := 0;
    End;
  End;
End;

Function B64Dec(Src : PBytes; N : LongInt; Dst : PBytes; Max : LongInt) : LongInt;
Var K, V, Bits, O, C, D : LongInt;
Begin
  V := 0; Bits := 0; O := 0;
  For K := 0 To N - 1 Do
  Begin
    C := Src^[K];
    If (C >= 65) And (C <= 90) Then D := C - 65
    Else If (C >= 97) And (C <= 122) Then D := C - 71
    Else If (C >= 48) And (C <= 57) Then D := C + 4
    Else If C = 43 Then D := 62
    Else If C = 47 Then D := 63
    Else D := -1;
    If D >= 0 Then
    Begin
      V := (V Shl 6) Or D;
      Bits := Bits + 6;
      If Bits >= 8 Then
      Begin
        Bits := Bits - 8;
        If O < Max Then Dst^[O] := (V Shr Bits) And 255;
        Inc(O);
      End;
    End;
  End;
  B64Dec := O;
End;

Function B64Str(S : String) : String;
Var B : TBuf; R : String; K : LongInt;
Begin
  BufInit(B);
  B64Enc(@S[1], Length(S), B, 0);
  R := '';
  For K := 0 To B.Len - 1 Do If Length(R) < 255 Then R := R + Chr(B.P^[K]);
  BufFree(B);
  B64Str := R;
End;

Function B64DecStr(S : String) : String;
Var R : String; N : LongInt;
Begin
  N := B64Dec(@S[1], Length(S), @R[1], 255);
  If N > 255 Then N := 255;
  R[0] := Chr(N);
  B64DecStr := R;
End;

{ --- lecture d'un fichier entier --- }
Var
  RndPool : Array[0..63] Of LongInt;
  RndCtr : LongInt;

Function PRdtsc : LongInt;
Var V : LongInt;
Begin
  {$IFDEF OS2PC}
  asm
    db 0Fh, 31h
    mov V,eax
  end;
  {$ELSE}
  V := PTicks * 7919;
  {$ENDIF}
  PRdtsc := V;
End;

{ aleatoire : SHA-256 d'un reservoir brasse avec le compteur de cycles }
Procedure RandFill(P : PBytes; N : LongInt);
Var C : TSha; T : TB32; K, I, V : LongInt;
Begin
  K := 0;
  While K < N Do
  Begin
    ShaInit(C);
    ShaUpd(C, @RndPool, SizeOf(RndPool));
    Inc(RndCtr);
    V := PRdtsc; ShaUpd(C, @V, 4);
    V := PTicks; ShaUpd(C, @V, 4);
    ShaUpd(C, @RndCtr, 4);
    ShaFinal(C, T);
    For I := 0 To 7 Do RndPool[(RndCtr + I) And 63] := RndPool[(RndCtr + I) And 63] Xor
      ((T[I * 4] Shl 24) Or (T[I * 4 + 1] Shl 16) Or (T[I * 4 + 2] Shl 8) Or T[I * 4 + 3]);
    T[0] := T[0] Xor $5A;
    Sha256(@T, 32, T);
    For I := 0 To 31 Do
      If K + I < N Then P^[K + I] := T[I];
    K := K + 32;
  End;
End;

{ > 0 : octets ; 0 : fin de la connexion ; -1 : rien pour l'instant ;
  -2 : erreur }
Function PRecv(S : LongInt; P : PBytes; N : LongInt) : LongInt;
Var R : LongInt;
Begin
  {$IFDEF OS2PC}
  R := SockRecv(S, LongInt(P), N, 0);
  If R < 0 Then
  Begin
    If SockErrno = 10035 Then R := -1 Else R := -2;
  End;
  {$ELSE}
  R := fpRecv(S, P, N, 0);
  If R < 0 Then
  Begin
    If (SocketError = ESysEAGAIN) Or (SocketError = ESysEINTR) Then R := -1 Else R := -2;
  End;
  {$ENDIF}
  PRecv := R;
End;

{ >= 0 : octets partis ; -2 : erreur }
Function PSend(S : LongInt; P : PBytes; N : LongInt) : LongInt;
Var R : LongInt;
Begin
  {$IFDEF OS2PC}
  R := SockSend(S, LongInt(P), N, 0);
  If R < 0 Then
  Begin
    If SockErrno = 10035 Then R := 0 Else R := -2;
  End;
  {$ELSE}
  R := fpSend(S, P, N, MSG_NOSIGNAL);
  If R < 0 Then
  Begin
    If (SocketError = ESysEAGAIN) Or (SocketError = ESysEINTR) Then R := 0 Else R := -2;
  End;
  {$ENDIF}
  PSend := R;
End;

Procedure PSockClose(S : LongInt);
Begin
  {$IFDEF OS2PC}
  Dummy := SockClose(S);
  {$ELSE}
  fpShutdown(S, 1);
  fpClose(S);
  {$ENDIF}
End;


Const
  MaxDbConn = 16;
  MaxRs = 32;
  MaxRsCol = 128;
  dbPg = 1; dbMy = 2;
  { etats d'une connexion }
  dsClosed = 0; dsHandshake = 1; dsReady = 2; dsBusy = 3;

Type
  TDbConn = Record
    Used : Boolean;
    Kind, Sock, St, LastUse, Deadline : LongInt;
    Owned : Boolean;            { prise par la requete en cours }
    Key : String;               { chaine de connexion }
    Host : String[79];
    DbPort : LongInt;
    User, Pass, Db : String[63];
    Rx : TBuf;
    Err : String;
    { SCRAM-SHA-256 }
    CNonce : String[63];
    CFirst, SFirst : String;
    Salted : TB32;
    { MySQL }
    Seq, Phase, NCol, ColDone : LongInt;
    Scramble : Array[0..19] Of Byte;
    { requete en cours }
    QRs : LongInt;
    QErr : String;
    QHaveT : Boolean;
    Affected : LongInt;
    InsId : LongInt;           { MariaDB : identifiant de la derniere insertion }
  End;

  TRs = Record
    Used : Boolean;
    NCol, NRow, Cur : LongInt;
    ColNO : Array[0..MaxRsCol - 1] Of LongInt;   { noms des colonnes : position dans Names }
    Names : TBuf;
    ColTy : Array[0..MaxRsCol - 1] Of Byte;    { 0 chaine, 1 entier, 2 reel, 3 booleen }
    Data : TBuf;                { octets des valeurs }
    Idx : TBuf;                 { (debut, longueur ; -1 : NULL) par cellule }
    Affected : LongInt;
  End;

Var
  DbC : Array[0..MaxDbConn - 1] Of TDbConn;
  Rss : Array[0..MaxRs - 1] Of TRs;
  DbPend : LongInt;             { connexion dont la page attend la reponse }
  DbWaitSock : LongInt;         { son socket (select du service) ; -1 : aucun }
  VmWait : Boolean;             { l'appel de membre attend : a reprendre }

{ --- hachages : MD5 et SHA-1 --- }

Function Rol(X, N : LongInt) : LongInt;
Begin
  Rol := (X Shl N) Or Sr(X, 32 - N);
End;

Procedure Md5(P : PBytes; N : LongInt; Var Out_ : TBlk);
Const
  S : Array[0..63] Of Byte = (7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21);
  { T[i] = partie entiere de abs(sin(i + 1)) * 2^32 (en LongInt) }
  T : Array[0..63] Of LongInt = (
    -680876936, -389564586, 606105819, -1044525330, -176418897, 1200080426, -1473231341, -45705983,
    1770035416, -1958414417, -42063, -1990404162, 1804603682, -40341101, -1502002290, 1236535329,
    -165796510, -1069501632, 643717713, -373897302, -701558691, 38016083, -660478335, -405537848,
    568446438, -1019803690, -187363961, 1163531501, -1444681467, -51403784, 1735328473, -1926607734,
    -378558, -2022574463, 1839030562, -35309556, -1530992060, 1272893353, -155497632, -1094730640,
    681279174, -358537222, -722521979, 76029189, -640364487, -421815835, 530742520, -995338651,
    -198630844, 1126891415, -1416354905, -57434055, 1700485571, -1894986606, -1051523, -2054922799,
    1873313359, -30611744, -1560198380, 1309151649, -145523070, -1120210379, 718787259, -343485551);
Var
  M : Array[0..15] Of LongInt; Blk : Array[0..63] Of Byte;
  A0, B0, C0, D0, A, B, C, D, F, G, K, I, Tot, Tmp : LongInt;
Begin
  A0 := $67452301; B0 := LongInt($EFCDAB89); C0 := LongInt($98BADCFE); D0 := $10325476;
  Tot := ((N + 8) Div 64 + 1) * 64;
  K := 0;
  While K < Tot Do
  Begin
    For I := 0 To 63 Do
    Begin
      If K + I < N Then Blk[I] := P^[K + I]
      Else If K + I = N Then Blk[I] := $80
      Else Blk[I] := 0;
    End;
    If K + 64 = Tot Then
    Begin
      Blk[56] := (N Shl 3) And 255; Blk[57] := (N Shr 5) And 255; Blk[58] := (N Shr 13) And 255;
      Blk[59] := (N Shr 21) And 255; Blk[60] := Sr(N, 29);
    End;
    For I := 0 To 15 Do
      M[I] := Blk[I * 4] Or (Blk[I * 4 + 1] Shl 8) Or (Blk[I * 4 + 2] Shl 16) Or (Blk[I * 4 + 3] Shl 24);
    A := A0; B := B0; C := C0; D := D0;
    For I := 0 To 63 Do
    Begin
      If I < 16 Then
      Begin
        F := (B And C) Or ((Not B) And D); G := I;
      End
      Else If I < 32 Then
      Begin
        F := (D And B) Or ((Not D) And C); G := (5 * I + 1) And 15;
      End
      Else If I < 48 Then
      Begin
        F := B Xor C Xor D; G := (3 * I + 5) And 15;
      End
      Else
      Begin
        F := C Xor (B Or (Not D)); G := (7 * I) And 15;
      End;
      Tmp := D; D := C; C := B;
      B := B + Rol(A + F + T[I] + M[G], S[I]);
      A := Tmp;
    End;
    A0 := A0 + A; B0 := B0 + B; C0 := C0 + C; D0 := D0 + D;
    K := K + 64;
  End;
  For I := 0 To 3 Do
  Begin
    Out_[I] := (A0 Shr (I * 8)) And 255; Out_[4 + I] := (B0 Shr (I * 8)) And 255;
    Out_[8 + I] := (C0 Shr (I * 8)) And 255; Out_[12 + I] := (D0 Shr (I * 8)) And 255;
  End;
End;

Type
  TB20 = Array[0..19] Of Byte;

Procedure Sha1(P : PBytes; N : LongInt; Var Out_ : TB20);
Var
  H : Array[0..4] Of LongInt; W : Array[0..79] Of LongInt; Blk : Array[0..63] Of Byte;
  A, B, C, D, E, F, K, I, Tot, Tmp, Kc : LongInt;
Begin
  H[0] := $67452301; H[1] := LongInt($EFCDAB89); H[2] := LongInt($98BADCFE); H[3] := $10325476;
  H[4] := LongInt($C3D2E1F0);
  Tot := ((N + 8) Div 64 + 1) * 64;
  K := 0;
  While K < Tot Do
  Begin
    For I := 0 To 63 Do
    Begin
      If K + I < N Then Blk[I] := P^[K + I]
      Else If K + I = N Then Blk[I] := $80
      Else Blk[I] := 0;
    End;
    If K + 64 = Tot Then
    Begin
      Blk[59] := Sr(N, 29); Blk[60] := (N Shr 21) And 255; Blk[61] := (N Shr 13) And 255;
      Blk[62] := (N Shr 5) And 255; Blk[63] := (N Shl 3) And 255;
    End;
    For I := 0 To 15 Do
      W[I] := (Blk[I * 4] Shl 24) Or (Blk[I * 4 + 1] Shl 16) Or (Blk[I * 4 + 2] Shl 8) Or Blk[I * 4 + 3];
    For I := 16 To 79 Do W[I] := Rol(W[I - 3] Xor W[I - 8] Xor W[I - 14] Xor W[I - 16], 1);
    A := H[0]; B := H[1]; C := H[2]; D := H[3]; E := H[4];
    For I := 0 To 79 Do
    Begin
      If I < 20 Then
      Begin
        F := (B And C) Or ((Not B) And D); Kc := $5A827999;
      End
      Else If I < 40 Then
      Begin
        F := B Xor C Xor D; Kc := $6ED9EBA1;
      End
      Else If I < 60 Then
      Begin
        F := (B And C) Or (B And D) Or (C And D); Kc := LongInt($8F1BBCDC);
      End
      Else
      Begin
        F := B Xor C Xor D; Kc := LongInt($CA62C1D6);
      End;
      Tmp := Rol(A, 5) + F + E + Kc + W[I];
      E := D; D := C; C := Rol(B, 30); B := A; A := Tmp;
    End;
    H[0] := H[0] + A; H[1] := H[1] + B; H[2] := H[2] + C; H[3] := H[3] + D; H[4] := H[4] + E;
    K := K + 64;
  End;
  For I := 0 To 4 Do
  Begin
    Out_[I * 4] := Sr(H[I], 24); Out_[I * 4 + 1] := Sr(H[I], 16) And 255;
    Out_[I * 4 + 2] := Sr(H[I], 8) And 255; Out_[I * 4 + 3] := H[I] And 255;
  End;
End;

Function HexBytes(P : PBytes; N : LongInt) : String;
Const Hx : String[16] = '0123456789abcdef';
Var S : String; K : LongInt;
Begin
  S := '';
  For K := 0 To N - 1 Do S := S + Hx[(P^[K] Shr 4) + 1] + Hx[(P^[K] And 15) + 1];
  HexBytes := S;
End;

{ PBKDF2-HMAC-SHA256, un bloc (32 octets) }
Procedure Pbkdf2(Pw : String; Salt : String; Iter : LongInt; Var Out_ : TB32);
Var U, T : TB32; Msg : String; I, K, L : LongInt;
Begin
  { sel suivi du numero de bloc (00 00 00 01), octet par octet : un
    litteral #0 coupe la chaine sous OS2PC }
  Msg := Salt;
  L := Length(Msg);
  If L > 250 Then L := 250;
  Msg[L + 1] := Chr(0); Msg[L + 2] := Chr(0); Msg[L + 3] := Chr(0); Msg[L + 4] := Chr(1);
  Msg[0] := Chr(L + 4);
  If Length(Pw) = 0 Then
  Begin
    Pw[1] := Chr(0); Pw[0] := Chr(1);    { (cle vide : une cle d'un octet nul est equivalente) }
  End;
  Hmac(@Pw[1], Length(Pw), @Msg[1], Length(Msg), U);
  T := U;
  For I := 2 To Iter Do
  Begin
    Hmac(@Pw[1], Length(Pw), @U, 32, U);
    For K := 0 To 31 Do T[K] := T[K] Xor U[K];
  End;
  Out_ := T;
End;

Procedure HmacStr(Var Key : TB32; S : String; Var R : TB32);
Begin
  Hmac(@Key, 32, @S[1], Length(S), R);
End;

Function B64Bytes(P : PBytes; N : LongInt) : String;
Var B : TBuf; S : String;
Begin
  BufInit(B);
  B64Enc(P, N, B, 0);
  S := '';
  If B.Len > 0 Then
  Begin
    If B.Len > 255 Then B.Len := 255;
    Move(B.P^[0], S[1], B.Len);
    S[0] := Chr(B.Len);
  End;
  While (Length(S) > 0) And (S[Length(S)] < ' ') Do Delete(S, Length(S), 1);
  BufFree(B);
  B64Bytes := S;
End;

{ --- reseau : connexion cliente (bloquante), puis non bloquante --- }

{$IFDEF OS2PC}
Function SockConnect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function SockGetHost(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
{$ENDIF}

Function PResolve(Host : String) : LongInt;
{$IFDEF OS2PC}
Var H, L, A : LongInt; P : PBytes;
Begin
  A := ParseIp(Host);
  PResolve := A;
  If A <> 0 Then Exit;
  H := SockGetHost(Z(Host));
  If H = 0 Then Exit;
  P := Pointer(H);
  L := P^[16] Or (P^[17] Shl 8) Or (P^[18] Shl 16) Or (P^[19] Shl 24);   { h_addr_list (hostent de TCPIP32) }
  If L = 0 Then Exit;
  P := Pointer(L);
  A := P^[0] Or (P^[1] Shl 8) Or (P^[2] Shl 16) Or (P^[3] Shl 24);
  If A = 0 Then Exit;
  P := Pointer(A);
  PResolve := (P^[0] Shl 24) Or (P^[1] Shl 16) Or (P^[2] Shl 8) Or P^[3];
End;
{$ELSE}
Begin
  If LoStr(Host) = 'localhost' Then PResolve := $7F000001 Else PResolve := ParseIp(Host);
End;
{$ENDIF}

{ socket connecte (non bloquant ensuite) ; -1 : echec }
Function PConnect(Ip, DbPort : LongInt) : LongInt;
Var S, One : LongInt;
{$IFDEF OS2PC}
    A : Array[0..15] Of Byte; K : LongInt;
{$ELSE}
    A : TInetSockAddr;
{$ENDIF}
Begin
  PConnect := -1;
  {$IFDEF OS2PC}
  S := SockSocket(2, 1, 0);
  If S < 0 Then Exit;
  For K := 0 To 15 Do A[K] := 0;
  A[0] := 16; A[1] := 2; A[2] := (DbPort Shr 8) And 255; A[3] := DbPort And 255;
  A[4] := Sr(Ip, 24); A[5] := Sr(Ip, 16) And 255; A[6] := Sr(Ip, 8) And 255; A[7] := Ip And 255;
  If SockConnect(S, LongInt(@A), 16) <> 0 Then
  Begin
    Dummy := SockClose(S);
    Exit;
  End;
  One := 1;
  Dummy := SockIoctl(S, $8004667E, LongInt(@One), 4);
  {$ELSE}
  S := fpSocket(AF_INET, SOCK_STREAM, 0);
  If S < 0 Then Exit;
  FillChar(A, SizeOf(A), 0);
  A.sin_family := AF_INET; A.sin_port := htons(DbPort); A.sin_addr.s_addr := htonl(LongWord(Ip));
  If fpConnect(S, @A, SizeOf(A)) <> 0 Then
  Begin
    fpClose(S);
    Exit;
  End;
  fpFcntl(S, F_SETFL, fpFcntl(S, F_GETFL) Or O_NONBLOCK);
  One := 1;
  fpSetSockOpt(S, 6, 1, @One, 4);
  {$ENDIF}
  PConnect := S;
End;

{ envoyer tout (petits messages : quelques essais) }
Function DbSend(K : LongInt; P : PBytes; N : LongInt) : Boolean;
Var R, Done, T : LongInt;
Begin
  DbSend := False;
  Done := 0; T := PTicks;
  While Done < N Do
  Begin
    R := PSend(DbC[K].Sock, @P^[Done], N - Done);
    If R < 0 Then
    Begin
      DbC[K].Err := 'connexion interrompue';
      Exit;
    End;
    Done := Done + R;
    If R = 0 Then
    Begin
      If PTicks - T > 10000 Then
      Begin
        DbC[K].Err := 'envoi impossible (delai)';
        Exit;
      End;
      PSleep(1);
    End;
  End;
  DbSend := True;
End;

{ lire ce qui est arrive ; faux : connexion fermee ou erreur }
Function DbFill(K : LongInt) : Boolean;
Var R : LongInt;
Begin
  DbFill := True;
  Repeat
    If Not BufGrow(DbC[K].Rx, 16384) Then
    Begin
      DbC[K].Err := 'memoire insuffisante';
      DbFill := False;
      Exit;
    End;
    R := PRecv(DbC[K].Sock, @DbC[K].Rx.P^[DbC[K].Rx.Len], 16384);
    If R > 0 Then DbC[K].Rx.Len := DbC[K].Rx.Len + R
    Else If R = 0 Then
    Begin
      DbC[K].Err := 'connexion fermee par le serveur';
      DbFill := False;
    End
    Else If R = -2 Then
    Begin
      DbC[K].Err := 'connexion interrompue';
      DbFill := False;
    End;
  Until R <= 0;
End;

{ retirer N octets du debut du tampon de reception }
Procedure DbEat(K, N : LongInt);
Begin
  With DbC[K] Do
  Begin
    If N >= Rx.Len Then Rx.Len := 0
    Else
    Begin
      Move(Rx.P^[N], Rx.P^[0], Rx.Len - N);
      Rx.Len := Rx.Len - N;
    End;
  End;
End;

Procedure DbClose(K : LongInt);
Var Q : Array[0..7] Of Byte;
Begin
  With DbC[K] Do
  Begin
    If Not Used Then Exit;
    If (Sock >= 0) And (St = dsReady) Then
    Begin
      If Kind = dbPg Then
      Begin
        Q[0] := Ord('X'); Q[1] := 0; Q[2] := 0; Q[3] := 0; Q[4] := 4;
        Dummy := PSend(Sock, @Q, 5);
      End
      Else
      Begin
        Q[0] := 1; Q[1] := 0; Q[2] := 0; Q[3] := 0; Q[4] := 1;
        Dummy := PSend(Sock, @Q, 5);
      End;
    End;
    If Sock >= 0 Then PSockClose(Sock);
    Sock := -1; St := dsClosed; Used := False; Owned := False;
    BufFree(Rx);
  End;
End;

{ --- jeux d'enregistrements --- }

Function RsNew : LongInt;
Var K : LongInt;
Begin
  RsNew := -1;
  For K := 0 To MaxRs - 1 Do
    If Not Rss[K].Used Then
    Begin
      Rss[K].Used := True;
      Rss[K].NCol := 0; Rss[K].NRow := 0; Rss[K].Cur := 0; Rss[K].Affected := 0;
      BufInit(Rss[K].Data); BufInit(Rss[K].Idx); BufInit(Rss[K].Names);
      RsNew := K;
      Exit;
    End;
End;


{ noms des colonnes (rangees dans un tampon : une chaine courte d'OS2PC
  occupe 256 octets quelle que soit sa longueur declaree) }
Procedure RsSetCol(Rs, C : LongInt; S : String);
Begin
  If (C < 0) Or (C >= MaxRsCol) Then Exit;
  Rss[Rs].ColNO[C] := Rss[Rs].Names.Len;
  BufAddC(Rss[Rs].Names, Length(S));
  BufAdd(Rss[Rs].Names, S);
End;

Function RsColName(Rs, C : LongInt) : String;
Var S : String; O, N : LongInt;
Begin
  RsColName := '';
  If (C < 0) Or (C >= Rss[Rs].NCol) Or (Rss[Rs].Names.Len = 0) Then Exit;
  O := Rss[Rs].ColNO[C];
  N := Rss[Rs].Names.P^[O];
  S[0] := Chr(N);
  If N > 0 Then Move(Rss[Rs].Names.P^[O + 1], S[1], N);
  RsColName := S;
End;

Procedure RsFree(K : LongInt);
Begin
  If (K < 0) Or (K >= MaxRs) Or Not Rss[K].Used Then Exit;
  BufFree(Rss[K].Data); BufFree(Rss[K].Idx); BufFree(Rss[K].Names);
  Rss[K].Used := False;
End;

Procedure RsAddInt(K, V : LongInt);
Var B : Array[0..3] Of Byte;
Begin
  B[0] := V And 255; B[1] := Sr(V, 8) And 255; B[2] := Sr(V, 16) And 255; B[3] := Sr(V, 24);
  BufAddB(Rss[K].Idx, @B, 4);
End;

{ une valeur (P, N octets ; N < 0 : NULL) de la ligne en cours de lecture }
Procedure RsAddVal(K : LongInt; P : PBytes; N : LongInt);
Begin
  RsAddInt(K, Rss[K].Data.Len);
  RsAddInt(K, N);
  If N > 0 Then BufAddB(Rss[K].Data, P, N);
End;

Function RsIdx(K, Pos : LongInt) : LongInt;
Var Q : PBytes;
Begin
  Q := Rss[K].Idx.P;
  RsIdx := Q^[Pos] Or (Q^[Pos + 1] Shl 8) Or (Q^[Pos + 2] Shl 16) Or (Q^[Pos + 3] Shl 24);
End;

{ colonne d'apres un nom (sans egard a la casse) ou un numero (0..) }

Procedure PgPut32(Var B : TBuf; V : LongInt);
Begin
  BufAddC(B, Sr(V, 24)); BufAddC(B, Sr(V, 16) And 255); BufAddC(B, Sr(V, 8) And 255); BufAddC(B, V And 255);
End;

{ envoyer un message : type (0 : demarrage, sans type), corps }
Function PgMsg(K : LongInt; Typ : Char; Var Body : TBuf) : Boolean;
Var B : TBuf;
Begin
  BufInit(B);
  If Typ <> #0 Then BufAddC(B, Ord(Typ));
  PgPut32(B, Body.Len + 4);
  BufAddB(B, Body.P, Body.Len);
  PgMsg := DbSend(K, B.P, B.Len);
  BufFree(B);
End;

Procedure BufAddZ(Var B : TBuf; S : String);
Begin
  BufAdd(B, S);
  BufAddC(B, 0);
End;

Function PgStart(K : LongInt) : Boolean;
Var B : TBuf;
Begin
  BufInit(B);
  PgPut32(B, 196608);
  BufAddZ(B, 'user'); BufAddZ(B, DbC[K].User);
  BufAddZ(B, 'database'); BufAddZ(B, DbC[K].Db);
  BufAddZ(B, 'client_encoding'); BufAddZ(B, 'UTF8');
  BufAddZ(B, 'application_name'); BufAddZ(B, 'OS2-0 SQL Developer');
  BufAddC(B, 0);
  PgStart := PgMsg(K, #0, B);
  BufFree(B);
End;

Function PgGet32(P : PBytes) : LongInt;
Begin
  PgGet32 := (P^[0] Shl 24) Or (P^[1] Shl 16) Or (P^[2] Shl 8) Or P^[3];
End;

Function PgGet16(P : PBytes) : LongInt;
Begin
  PgGet16 := (P^[0] Shl 8) Or P^[1];
End;

{ texte d'un message d'erreur ('E' : champs code + texte) }
Function PgErrText(P : PBytes; N : LongInt) : String;
Var I : LongInt; F : Char; S, M, C : String;
Begin
  I := 0; M := ''; C := '';
  While (I < N) And (P^[I] <> 0) Do
  Begin
    F := Chr(P^[I]); Inc(I);
    S := '';
    While (I < N) And (P^[I] <> 0) Do
    Begin
      If Length(S) < 200 Then S := S + Chr(P^[I]);
      Inc(I);
    End;
    Inc(I);
    If F = 'M' Then M := S Else If F = 'C' Then C := S;
  End;
  If C <> '' Then M := M + ' (' + C + ')';
  PgErrText := M;
End;

{ SCRAM-SHA-256 : premier message du client }
Procedure PgScramFirst(K : LongInt);
Var R : Array[0..17] Of Byte; B : TBuf; S : String;
Begin
  RandFill(@R, 18);
  DbC[K].CNonce := B64Bytes(@R, 18);
  DbC[K].CFirst := 'n=,r=' + DbC[K].CNonce;
  S := 'n,,' + DbC[K].CFirst;
  BufInit(B);
  BufAddZ(B, 'SCRAM-SHA-256');
  PgPut32(B, Length(S));
  BufAdd(B, S);
  Dummy := Ord(PgMsg(K, 'p', B));
  BufFree(B);
End;

Function ScramAttr(S : String; A : Char) : String;
Var P : LongInt;
Begin
  ScramAttr := '';
  S := ',' + S;
  P := Pos(',' + A + '=', S);
  If P = 0 Then Exit;
  S := Copy(S, P + 3, 255);
  P := Pos(',', S);
  If P > 0 Then S := Copy(S, 1, P - 1);
  ScramAttr := S;
End;

Function PgScramFinal(K : LongInt; SFirst : String) : Boolean;
Var Nonce, Salt, Fin, Auth : String; It, I : LongInt; CKey, SKey, Sig, Proof : TB32; B : TBuf;
Begin
  PgScramFinal := False;
  Nonce := ScramAttr(SFirst, 'r'); Salt := B64DecStr(ScramAttr(SFirst, 's'));
  It := SVal(ScramAttr(SFirst, 'i'));
  If (Copy(Nonce, 1, Length(DbC[K].CNonce)) <> DbC[K].CNonce) Or (It < 1) Or (Salt = '') Then
  Begin
    DbC[K].Err := 'SCRAM : r'#130'ponse du serveur incorrecte';
    Exit;
  End;
  DbC[K].SFirst := SFirst;
  Pbkdf2(DbC[K].Pass, Salt, It, DbC[K].Salted);
  HmacStr(DbC[K].Salted, 'Client Key', CKey);
  Sha256(@CKey, 32, SKey);
  Fin := 'c=biws,r=' + Nonce;
  Auth := DbC[K].CFirst + ',' + SFirst + ',' + Fin;
  HmacStr(SKey, Auth, Sig);
  For I := 0 To 31 Do Proof[I] := CKey[I] Xor Sig[I];
  DbC[K].CFirst := Auth;    { (garde pour verifier la signature du serveur) }
  Fin := Fin + ',p=' + B64Bytes(@Proof, 32);
  BufInit(B);
  BufAdd(B, Fin);
  PgScramFinal := PgMsg(K, 'p', B);
  BufFree(B);
End;

Function PgScramCheck(K : LongInt; SFinal : String) : Boolean;
Var SKey, Sig : TB32;
Begin
  HmacStr(DbC[K].Salted, 'Server Key', SKey);
  HmacStr(SKey, DbC[K].CFirst, Sig);
  PgScramCheck := ScramAttr(SFinal, 'v') = B64Bytes(@Sig, 32);
End;

{ avancer : 1 fini (ReadyForQuery), 0 a suivre, -1 erreur (Err) }
Function PgStep(K : LongInt) : LongInt;
Var Typ : Char; L, Code, N, I, J, C, Ty, O : LongInt; P : PBytes; S : String; B : TBuf; Dg : TBlk;
    Rs : LongInt;
Begin
  PgStep := 0;
  If Not DbFill(K) Then
  Begin
    PgStep := -1;
    Exit;
  End;
  With DbC[K] Do
    While Rx.Len >= 5 Do
    Begin
      Typ := Chr(Rx.P^[0]);
      L := PgGet32(@Rx.P^[1]);
      If (L < 4) Or (L > 64 * 1024 * 1024) Then
      Begin
        Err := 'r'#130'ponse incorrecte du serveur PostgreSQL';
        PgStep := -1;
        Exit;
      End;
      If Rx.Len < L + 1 Then Exit;
      P := @Rx.P^[5]; N := L - 4;
      Case Typ Of
        'R' :
          Begin
            Code := PgGet32(P);
            Case Code Of
              0 : ;
              3 :
                Begin
                  BufInit(B); BufAddZ(B, Pass);
                  Dummy := Ord(PgMsg(K, 'p', B)); BufFree(B);
                End;
              5 :
                Begin
                  S := Pass + User;
                  Md5(@S[1], Length(S), Dg);
                  S := HexBytes(@Dg, 16);
                  For I := 0 To 3 Do S[33 + I] := Chr(P^[4 + I]);    { sel (octets quelconques) }
                  S[0] := Chr(36);
                  Md5(@S[1], Length(S), Dg);
                  BufInit(B); BufAddZ(B, 'md5' + HexBytes(@Dg, 16));
                  Dummy := Ord(PgMsg(K, 'p', B)); BufFree(B);
                End;
              10 :
                Begin
                  S := '';
                  For I := 4 To N - 1 Do If P^[I] = 0 Then S := S + ',' Else S := S + Chr(P^[I]);
                  If Pos('SCRAM-SHA-256,', S + ',') = 0 Then
                  Begin
                    Err := 'm'#130'canisme d''authentification non pris en charge : ' + S;
                    PgStep := -1;
                    Exit;
                  End;
                  PgScramFirst(K);
                End;
              11 :
                Begin
                  S := '';
                  For I := 4 To N - 1 Do If Length(S) < 255 Then S := S + Chr(P^[I]);
                  If Not PgScramFinal(K, S) Then
                  Begin
                    PgStep := -1;
                    Exit;
                  End;
                End;
              12 :
                Begin
                  S := '';
                  For I := 4 To N - 1 Do If Length(S) < 255 Then S := S + Chr(P^[I]);
                  If Not PgScramCheck(K, S) Then
                  Begin
                    Err := 'SCRAM : signature du serveur incorrecte';
                    PgStep := -1;
                    Exit;
                  End;
                End;
            Else
              Begin
                Err := 'authentification PostgreSQL non prise en charge (code ' + IStr(Code) + ')';
                PgStep := -1;
                Exit;
              End;
            End;
          End;
        'E' :
          Begin
            QErr := PgErrText(P, N);
            If St = dsHandshake Then
            Begin
              Err := QErr;
              PgStep := -1;
              Exit;
            End;
          End;
        'T' :
          If (QRs >= 0) And Not QHaveT Then
          Begin
            Rs := QRs;
            QHaveT := True;
            C := PgGet16(P); O := 2;
            If C > MaxRsCol Then C := MaxRsCol;
            Rss[Rs].NCol := C;
            For J := 0 To C - 1 Do
            Begin
              S := '';
              While (O < N) And (P^[O] <> 0) Do
              Begin
                If Length(S) < 63 Then S := S + Chr(P^[O]);
                Inc(O);
              End;
              Inc(O);
              Ty := PgGet32(@P^[O + 6]);
              O := O + 18;
              RsSetCol(Rs, J, S);
              Case Ty Of
                20, 21, 23, 26 : Rss[Rs].ColTy[J] := 1;
                700, 701 : Rss[Rs].ColTy[J] := 2;
                16 : Rss[Rs].ColTy[J] := 3;
              Else
                Rss[Rs].ColTy[J] := 0;
              End;
            End;
          End;
        'D' :
          If (QRs >= 0) And QHaveT And (QErr = '') Then
          Begin
            Rs := QRs;
            C := PgGet16(P); O := 2;
            For J := 0 To Rss[Rs].NCol - 1 Do
            Begin
              If J < C Then
              Begin
                I := PgGet32(@P^[O]); O := O + 4;
                If I < 0 Then RsAddVal(Rs, Nil, -1)
                Else
                Begin
                  RsAddVal(Rs, @P^[O], I);
                  O := O + I;
                End;
              End
              Else RsAddVal(Rs, Nil, -1);
            End;
            Inc(Rss[Rs].NRow);
          End;
        'C' :
          Begin
            { "INSERT 0 3", "UPDATE 2", "SELECT 5" : le dernier nombre }
            S := '';
            For I := 0 To N - 2 Do If Length(S) < 60 Then S := S + Chr(P^[I]);
            I := Length(S);
            While (I > 0) And (S[I] <> ' ') Do Dec(I);
            Affected := SVal(Copy(S, I + 1, 20));
          End;
        'Z' :
          Begin
            DbEat(K, L + 1);
            If St = dsHandshake Then
            Begin
              St := dsReady;
              PgStep := 1;
            End
            Else If QErr <> '' Then
            Begin
              Err := QErr;
              St := dsReady;
              PgStep := -1;
            End
            Else
            Begin
              St := dsReady;
              PgStep := 1;
            End;
            Exit;
          End;
      End;
      DbEat(K, L + 1);
    End;
End;

Function PgQuery(K : LongInt; Var Sql : TBuf) : Boolean;
Var B : TBuf;
Begin
  BufInit(B);
  BufAddB(B, Sql.P, Sql.Len);
  BufAddC(B, 0);
  PgQuery := PgMsg(K, 'Q', B);
  BufFree(B);
End;

{ ==================================================================== }
{ MariaDB et MySQL                                                      }
{ ==================================================================== }

Function MySend(K : LongInt; Var Body : TBuf) : Boolean;
Var B : TBuf;
Begin
  BufInit(B);
  BufAddC(B, Body.Len And 255); BufAddC(B, Sr(Body.Len, 8) And 255); BufAddC(B, Sr(Body.Len, 16) And 255);
  BufAddC(B, DbC[K].Seq And 255);
  Inc(DbC[K].Seq);
  BufAddB(B, Body.P, Body.Len);
  MySend := DbSend(K, B.P, B.Len);
  BufFree(B);
End;

{ entier code en longueur variable a P^[O] ; O avance }
Function LenEnc(P : PBytes; Var O : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := P^[O];
  Inc(O);
  If V = $FC Then
  Begin
    V := P^[O] Or (P^[O + 1] Shl 8); O := O + 2;
  End
  Else If V = $FD Then
  Begin
    V := P^[O] Or (P^[O + 1] Shl 8) Or (P^[O + 2] Shl 16); O := O + 3;
  End
  Else If V = $FE Then
  Begin
    V := P^[O] Or (P^[O + 1] Shl 8) Or (P^[O + 2] Shl 16) Or (P^[O + 3] Shl 24); O := O + 8;
  End
  Else If V = $FB Then V := -1;
  LenEnc := V;
End;

{ reponse a l'authentification mysql_native_password : 20 octets }
Procedure MyNative(K : LongInt; Var Out_ : TB20);
Var H1, H2, H3 : TB20; S : Array[0..39] Of Byte; I : LongInt; Pw : String;
Begin
  Pw := DbC[K].Pass;
  Sha1(@Pw[1], Length(Pw), H1);
  Sha1(@H1, 20, H2);
  For I := 0 To 19 Do
  Begin
    S[I] := DbC[K].Scramble[I]; S[20 + I] := H2[I];
  End;
  Sha1(@S, 40, H3);
  For I := 0 To 19 Do Out_[I] := H1[I] Xor H3[I];
End;

{ caching_sha2_password (chemin rapide) : XOR(SHA256(mdp), SHA256(SHA256(SHA256(mdp)), brouillage)) }
Procedure MyCachingSha2(K : LongInt; Var Out_ : TB32);
Var H1, H2, H3 : TB32; S : Array[0..51] Of Byte; I : LongInt; Pw : String;
Begin
  Pw := DbC[K].Pass;
  Sha256(@Pw[1], Length(Pw), H1);
  Sha256(@H1, 32, H2);
  For I := 0 To 31 Do S[I] := H2[I];
  For I := 0 To 19 Do S[32 + I] := DbC[K].Scramble[I];
  Sha256(@S, 52, H3);
  For I := 0 To 31 Do Out_[I] := H1[I] Xor H3[I];
End;

Procedure MyAuthData(K : LongInt; Plugin : String; Var B : TBuf);
Var H : TB20; H2 : TB32;
Begin
  If DbC[K].Pass = '' Then Exit;
  If Plugin = 'caching_sha2_password' Then
  Begin
    MyCachingSha2(K, H2);
    BufAddB(B, @H2, 32);
  End
  Else If Plugin = 'mysql_clear_password' Then
  Begin
    BufAdd(B, DbC[K].Pass);
    BufAddC(B, 0);
  End
  Else
  Begin
    MyNative(K, H);
    BufAddB(B, @H, 20);
  End;
End;

Function MyErrText(P : PBytes; N : LongInt) : String;
Var S : String; I, Code : LongInt;
Begin
  Code := P^[1] Or (P^[2] Shl 8);
  S := '';
  I := 3;
  If (I < N) And (P^[I] = Ord('#')) Then I := I + 6;
  While (I < N) And (Length(S) < 200) Do
  Begin
    S := S + Chr(P^[I]);
    Inc(I);
  End;
  MyErrText := S + ' (' + IStr(Code) + ')';
End;

{ salut du serveur -> reponse d'authentification }
Function MyGreeting(K : LongInt; P : PBytes; N : LongInt) : Boolean;
Var O, I, Caps, AuthLen : LongInt; Plugin : String; B : TBuf; Ver : String;
Begin
  MyGreeting := False;
  If P^[0] = $FF Then
  Begin
    DbC[K].Err := MyErrText(P, N);
    Exit;
  End;
  If P^[0] <> 10 Then
  Begin
    DbC[K].Err := 'protocole MySQL non pris en charge (version ' + IStr(P^[0]) + ')';
    Exit;
  End;
  O := 1; Ver := '';
  While (O < N) And (P^[O] <> 0) Do
  Begin
    Ver := Ver + Chr(P^[O]);
    Inc(O);
  End;
  O := O + 1 + 4;
  For I := 0 To 7 Do DbC[K].Scramble[I] := P^[O + I];
  O := O + 9;
  Caps := P^[O] Or (P^[O + 1] Shl 8);
  O := O + 2 + 1 + 2;
  Caps := Caps Or (P^[O] Shl 16) Or (P^[O + 1] Shl 24);
  O := O + 2;
  AuthLen := P^[O];
  O := O + 1 + 10;
  For I := 0 To 11 Do If O + I < N Then DbC[K].Scramble[8 + I] := P^[O + I];
  O := O + 13;
  If AuthLen > 21 Then O := O + AuthLen - 21;
  Plugin := '';
  While (O < N) And (P^[O] <> 0) Do
  Begin
    Plugin := Plugin + Chr(P^[O]);
    Inc(O);
  End;
  If Plugin = '' Then Plugin := 'mysql_native_password';
  { reponse : CLIENT_LONG_PASSWORD, FOUND_ROWS, CONNECT_WITH_DB, PROTOCOL_41, TRANSACTIONS,
    SECURE_CONNECTION, PLUGIN_AUTH }
  BufInit(B);
  Caps := 1 Or 2 Or 8 Or $200 Or $2000 Or $8000 Or $80000;   { + FOUND_ROWS : lignes trouvees }
  BufAddC(B, Caps And 255); BufAddC(B, Sr(Caps, 8) And 255); BufAddC(B, Sr(Caps, 16) And 255); BufAddC(B, 0);
  BufAddC(B, 0); BufAddC(B, 0); BufAddC(B, 0); BufAddC(B, 1);       { paquet de 16 Mo au plus }
  BufAddC(B, 45);                                                    { utf8mb4 }
  For I := 1 To 23 Do BufAddC(B, 0);
  BufAddZ(B, DbC[K].User);
  I := B.Len;
  BufAddC(B, 0);
  MyAuthData(K, Plugin, B);
  B.P^[I] := B.Len - I - 1;
  BufAddZ(B, DbC[K].Db);
  BufAddZ(B, Plugin);
  MyGreeting := MySend(K, B);
  BufFree(B);
End;

{ avancer : 1 fini, 0 a suivre, -1 erreur }
Function MyStep(K : LongInt) : LongInt;
Var L, O, I, J, N, V, Rs, Ty : LongInt; P : PBytes; S, Plugin : String; B : TBuf;
Begin
  MyStep := 0;
  If Not DbFill(K) Then
  Begin
    MyStep := -1;
    Exit;
  End;
  With DbC[K] Do
    While Rx.Len >= 4 Do
    Begin
      L := Rx.P^[0] Or (Rx.P^[1] Shl 8) Or (Rx.P^[2] Shl 16);
      If Rx.Len < L + 4 Then Exit;
      Seq := Rx.P^[3] + 1;
      P := @Rx.P^[4];
      Case Phase Of
        1 :   { salut }
          Begin
            If Not MyGreeting(K, P, L) Then
            Begin
              MyStep := -1;
              Exit;
            End;
            Phase := 2;
          End;
        2 :   { resultat de l'authentification }
          If P^[0] = 0 Then
          Begin
            DbEat(K, L + 4);
            St := dsReady;
            MyStep := 1;
            Exit;
          End
          Else If P^[0] = $FF Then
          Begin
            Err := MyErrText(P, L);
            MyStep := -1;
            Exit;
          End
          Else If P^[0] = $FE Then
          Begin
            { changement de methode : nom, nouveau brouillage }
            O := 1; Plugin := '';
            While (O < L) And (P^[O] <> 0) Do
            Begin
              Plugin := Plugin + Chr(P^[O]);
              Inc(O);
            End;
            Inc(O);
            For I := 0 To 19 Do If O + I < L Then Scramble[I] := P^[O + I];
            BufInit(B);
            MyAuthData(K, Plugin, B);
            Dummy := Ord(MySend(K, B));
            BufFree(B);
          End
          Else If P^[0] = 1 Then
          Begin
            { caching_sha2_password : 3 = chemin rapide reussi, 4 = authentification complete }
            If (L >= 2) And (P^[1] = 4) Then
            Begin
              Err := 'caching_sha2_password : authentification compl'#138'te impossible sans TLS ' +
                     '(cr'#130'ez l''utilisateur avec mysql_native_password)';
              MyStep := -1;
              Exit;
            End;
          End;
        10 :  { premiere reponse a une requete }
          If P^[0] = 0 Then
          Begin
            O := 1;
            Affected := LenEnc(P, O);
            InsId := LenEnc(P, O);
            DbEat(K, L + 4);
            St := dsReady;
            MyStep := 1;
            Exit;
          End
          Else If P^[0] = $FF Then
          Begin
            Err := MyErrText(P, L);
            DbEat(K, L + 4);
            St := dsReady;
            MyStep := -1;
            Exit;
          End
          Else
          Begin
            O := 0;
            NCol := LenEnc(P, O);
            ColDone := 0;
            If QRs >= 0 Then
            Begin
              If NCol > MaxRsCol Then Rss[QRs].NCol := MaxRsCol Else Rss[QRs].NCol := NCol;
            End;
            If NCol <= 0 Then Phase := 13 Else Phase := 11;
          End;
        11 :  { definitions des colonnes }
          Begin
            If (P^[0] = $FE) And (L < 9) Then Phase := 13
            Else
            Begin
              O := 0;
              For J := 1 To 4 Do
              Begin
                N := LenEnc(P, O);
                If N > 0 Then O := O + N;
              End;
              N := LenEnc(P, O);
              S := '';
              For I := 0 To N - 1 Do If Length(S) < 63 Then S := S + Chr(P^[O + I]);
              If N > 0 Then O := O + N;
              N := LenEnc(P, O);
              If N > 0 Then O := O + N;
              O := O + 1 + 2 + 4;
              Ty := P^[O];
              If (QRs >= 0) And (ColDone < Rss[QRs].NCol) Then
              Begin
                RsSetCol(QRs, ColDone, S);
                Case Ty Of
                  1, 2, 3, 8, 9, 13 : Rss[QRs].ColTy[ColDone] := 1;
                  4, 5 : Rss[QRs].ColTy[ColDone] := 2;
                Else
                  Rss[QRs].ColTy[ColDone] := 0;
                End;
              End;
              Inc(ColDone);
              If ColDone >= NCol Then Phase := 12;
            End;
          End;
        12 :  { EOF apres les colonnes (ou deja une ligne) }
          If (P^[0] = $FE) And (L < 9) Then Phase := 13
          Else
          Begin
            Phase := 13;
            Continue;      { la ligne est traitee au tour suivant }
          End;
        13 :  { lignes, puis EOF }
          If (P^[0] = $FE) And (L < 9) Then
          Begin
            DbEat(K, L + 4);
            St := dsReady;
            If QRs >= 0 Then Rss[QRs].Affected := Rss[QRs].NRow;
            Affected := 0;
            MyStep := 1;
            Exit;
          End
          Else If P^[0] = $FF Then
          Begin
            Err := MyErrText(P, L);
            DbEat(K, L + 4);
            St := dsReady;
            MyStep := -1;
            Exit;
          End
          Else If QRs >= 0 Then
          Begin
            Rs := QRs;
            O := 0;
            For J := 0 To NCol - 1 Do
            Begin
              If O >= L Then V := -1
              Else If P^[O] = $FB Then
              Begin
                V := -1; Inc(O);
              End
              Else V := LenEnc(P, O);
              If J < Rss[Rs].NCol Then
              Begin
                If V < 0 Then RsAddVal(Rs, Nil, -1) Else RsAddVal(Rs, @P^[O], V);
              End;
              If V > 0 Then O := O + V;
            End;
            Inc(Rss[Rs].NRow);
          End;
      End;
      DbEat(K, L + 4);
    End;
End;

Function MyQuery(K : LongInt; Var Sql : TBuf) : Boolean;
Var B : TBuf;
Begin
  DbC[K].Seq := 0;
  DbC[K].Phase := 10;
  BufInit(B);
  BufAddC(B, 3);
  BufAddB(B, Sql.P, Sql.Len);
  MyQuery := MySend(K, B);
  BufFree(B);
End;

{ ==================================================================== }
{ Operations (avec attente) pour la machine des pages                  }
{ ==================================================================== }

Function DbStep(K : LongInt) : LongInt;
Begin
  If DbC[K].Kind = dbPg Then DbStep := PgStep(K) Else DbStep := MyStep(K);
End;

Function DbName(K : LongInt) : String;
Begin
  If DbC[K].Kind = dbPg Then DbName := 'PostgreSQL' Else DbName := 'MariaDB';
End;


Procedure DbInit;
Var K : LongInt;
Begin
  For K := 0 To MaxDbConn - 1 Do
  Begin
    DbC[K].Used := False; DbC[K].Sock := -1;
  End;
  For K := 0 To MaxRs - 1 Do Rss[K].Used := False;
  DbPend := -1; DbWaitSock := -1; VmWait := False;
End;
{ ==================================================================== }
{ Tables en fichiers : dBASE III (.DBF et memos .DBT), CSV, Clarion,     }
{ Btrieve (format d'origine), MyISAM (.MYD + .MYI, lecture seule)        }
{ Lecteurs repris de l'editeur de grille de DEVENV (DEV-COOLS), recrits  }
{ sur DosOpen, DosSetFilePtr, DosRead et DosWrite. Une table ouverte     }
{ garde son fichier ; la grille lit les enregistrements a la demande,    }
{ les modifications d'une cellule sont reecrites a leur place (DBF,      }
{ Clarion, Btrieve) ou par un fichier temporaire (CSV).                  }
{ ==================================================================== }

Const
  ftNone = 0; ftDbf = 1; ftCsv = 2; ftClarion = 3; ftBtrieve = 4; ftMyd = 5;
  MaxFCol = 128;
  MaxFTab = 12;

Type
  TFCol = Record
    NameO : LongInt;            { nom : position dans le tampon Names de la table }
    TypeCode : Char;
    Ofs, Len, Decimals : LongInt;
  End;
  TFTab = Record
    Used : Boolean;
    Name : String;
    Fmt : LongInt;
    H : LongInt;
    Writable : Boolean;
    RecordCount, RecordLen, DataStart, NCol : LongInt;
    Cols : Array[0..MaxFCol - 1] Of TFCol;
    Rec : PBytes;               { enregistrement courant }
    CurRec, CurLen : LongInt;
    RowOfs, RowLen : PLongs;    { CSV et Btrieve : position et longueur des lignes }
    RowCap : LongInt;
    CsvHdr : Boolean;           { CSV : la premiere ligne donne les noms }
    Names : TBuf;
    Err : String;
  End;

Var
  FT : Array[0..MaxFTab - 1] Of TFTab;
  CsvHeaders : Boolean;          { option : premiere ligne d'un CSV = en-tetes }

{ noms des colonnes (dans un tampon : une chaine courte d'OS2PC occupe
  256 octets quelle que soit sa longueur declaree) }
Procedure FtSetColName(T, C : LongInt; S : String);
Begin
  FT[T].Cols[C].NameO := FT[T].Names.Len;
  BufAddC(FT[T].Names, Length(S));
  BufAdd(FT[T].Names, S);
End;

Function FtColName(T, C : LongInt) : String;
Var S : String; O, N : LongInt;
Begin
  FtColName := '';
  If FT[T].Names.Len = 0 Then Exit;
  O := FT[T].Cols[C].NameO;
  N := FT[T].Names.P^[O];
  S[0] := Chr(N);
  If N > 0 Then Move(FT[T].Names.P^[O + 1], S[1], N);
  FtColName := S;
End;

Function HexByte(B : LongInt) : String;
Const Hx : String[16] = '0123456789ABCDEF';
Begin
  HexByte := Hx[((B Shr 4) And 15) + 1] + Hx[(B And 15) + 1];
End;

{ --- fichiers --- }

Function FOpenRW(Name : String; Var H : LongInt) : Boolean;
Var A : LongInt;
Begin
  H := 0; A := 0;
  FOpenRW := DosOpen(Z(Name), LongInt(@H), LongInt(@A), 0, 0, 1, $42, 0) = 0;
End;

Function FSizeOf(H : LongInt) : LongInt;
Var P, Old : LongInt;
Begin
  Old := 0; P := 0;
  Dummy := DosSetFilePtr(H, 0, 1, LongInt(@Old));
  If DosSetFilePtr(H, 0, 2, LongInt(@P)) <> 0 Then P := 0;
  Dummy := DosSetFilePtr(H, Old, 0, LongInt(@Old));
  FSizeOf := P;
End;

{ lire N octets a la position Ofs ; rend le nombre lu }
Function FReadAt(H, Ofs : LongInt; P : PBytes; N : LongInt) : LongInt;
Var Np : LongInt;
Begin
  FReadAt := 0;
  Np := 0;
  If DosSetFilePtr(H, Ofs, 0, LongInt(@Np)) <> 0 Then Exit;
  FReadAt := MaxI(0, FRead(H, P, N));
End;

Function FWriteAt(H, Ofs : LongInt; P : PBytes; N : LongInt) : Boolean;
Var Np : LongInt;
Begin
  Np := 0;
  FWriteAt := False;
  If DosSetFilePtr(H, Ofs, 0, LongInt(@Np)) <> 0 Then Exit;
  FWriteAt := FWrite(H, P, N) = N;
End;

Function LE16(P : PBytes; O : LongInt) : LongInt;
Begin
  LE16 := P^[O] Or (P^[O + 1] Shl 8);
End;

Function LE32(P : PBytes; O : LongInt) : LongInt;
Begin
  LE32 := P^[O] Or (P^[O + 1] Shl 8) Or (P^[O + 2] Shl 16) Or (P^[O + 3] Shl 24);
End;

{ meme nom, autre extension }
Function SiblingExt(Path, Ext : String) : String;
Var K : LongInt;
Begin
  K := Length(Path);
  While (K > 0) And (Path[K] <> '.') And (Path[K] <> '\') Do Dec(K);
  If (K > 0) And (Path[K] = '.') Then SiblingExt := Copy(Path, 1, K) + Ext
  Else SiblingExt := Path + '.' + Ext;
End;

Function FmtOfExt(Ext : String) : LongInt;
Begin
  FmtOfExt := ftNone;
  If Ext = 'DBF' Then FmtOfExt := ftDbf
  Else If (Ext = 'CSV') Or (Ext = 'TXT') Then FmtOfExt := ftCsv
  Else If Ext = 'DAT' Then FmtOfExt := ftClarion
  Else If (Length(Ext) = 3) And ((Ext[1] = 'K') Or (Ext[1] = 'I')) And (Ext[2] In ['0'..'9']) And
          (Ext[3] In ['0'..'9']) Then FmtOfExt := ftClarion
  Else If Ext = 'MYD' Then FmtOfExt := ftMyd;
End;

Function FmtName(F : LongInt) : String;
Begin
  Case F Of
    ftDbf : FmtName := 'dBASE III';
    ftCsv : FmtName := 'CSV';
    ftClarion : FmtName := 'Clarion';
    ftBtrieve : FmtName := 'Btrieve';
    ftMyd : FmtName := 'MyISAM';
  Else
    FmtName := '?';
  End;
End;

Function FmtEditable(F : LongInt) : Boolean;
Begin
  FmtEditable := (F = ftDbf) Or (F = ftClarion) Or (F = ftBtrieve) Or (F = ftCsv);
End;

Procedure RowGrow(T : LongInt);
Var A, B : PLongs; NC : LongInt;
Begin
  With FT[T] Do
  Begin
    If RecordCount < RowCap Then Exit;
    NC := RowCap * 2;
    If NC < 256 Then NC := 256;
    GetMem(A, NC * 4); GetMem(B, NC * 4);
    If RecordCount > 0 Then
    Begin
      Move(RowOfs^[0], A^[0], RecordCount * 4);
      Move(RowLen^[0], B^[0], RecordCount * 4);
    End;
    If RowCap > 0 Then
    Begin
      FreeMem(RowOfs, RowCap * 4); FreeMem(RowLen, RowCap * 4);
    End;
    RowOfs := A; RowLen := B; RowCap := NC;
  End;
End;

{ --- enregistrement --- }

Procedure FtRead(T, R : LongInt);
Var Ofs, Len : LongInt;
Begin
  With FT[T] Do
  Begin
    If (R < 0) Or (R >= RecordCount) Or (CurRec = R) Or (Rec = Nil) Then Exit;
    If RowOfs <> Nil Then
    Begin
      Ofs := RowOfs^[R]; Len := RowLen^[R];
    End
    Else
    Begin
      Ofs := DataStart + R * RecordLen; Len := RecordLen;
    End;
    If Len > RecordLen Then Len := RecordLen;
    If Len > 0 Then
      If FReadAt(H, Ofs, Rec, Len) <> Len Then Exit;
    CurRec := R; CurLen := Len;
  End;
End;

{ champ Col d'une ligne CSV deja lue }
Function CsvField(T, Col : LongInt) : String;
Var I, Fi : LongInt; InQ : Boolean; Res : String; Ch : Char;
Begin
  CsvField := '';
  Fi := 0; InQ := False; Res := '';
  I := 0;
  With FT[T] Do
    While I < CurLen Do
    Begin
      Ch := Chr(Rec^[I]);
      If InQ Then
      Begin
        If Ch = '"' Then
        Begin
          If (I + 1 < CurLen) And (Rec^[I + 1] = 34) Then
          Begin
            If (Fi = Col) And (Length(Res) < 250) Then Res := Res + '"';
            Inc(I);
          End
          Else InQ := False;
        End
        Else If (Fi = Col) And (Length(Res) < 250) Then Res := Res + Ch;
      End
      Else
      Begin
        If Ch = '"' Then InQ := True
        Else If Ch = ',' Then
        Begin
          If Fi = Col Then
          Begin
            CsvField := Res;
            Exit;
          End;
          Inc(Fi);
          Res := '';
        End
        Else If (Fi = Col) And (Length(Res) < 250) Then Res := Res + Ch;
      End;
      Inc(I);
    End;
  If Fi = Col Then CsvField := Res;
End;

Function CsvCount(T : LongInt) : LongInt;
Var I, N : LongInt; InQ : Boolean;
Begin
  N := 1; InQ := False; I := 0;
  With FT[T] Do
    While I < CurLen Do
    Begin
      If InQ Then
      Begin
        If Rec^[I] = 34 Then
        Begin
          If (I + 1 < CurLen) And (Rec^[I + 1] = 34) Then Inc(I) Else InQ := False;
        End;
      End
      Else If Rec^[I] = 34 Then InQ := True
      Else If Rec^[I] = 44 Then Inc(N);
      Inc(I);
    End;
  CsvCount := N;
End;

{ texte d'un memo dBASE III (.DBT : blocs de 512 octets, fin par $1A) }
Function DbtMemo(T, Block : LongInt) : String;
Var H, N, K : LongInt; B : Array[0..511] Of Byte; S : String; Done : Boolean;
Begin
  DbtMemo := '';
  If Block <= 0 Then Exit;
  If Not FOpenRead(SiblingExt(FT[T].Name, 'DBT'), H) Then
  Begin
    DbtMemo := '[memo : .DBT introuvable]';
    Exit;
  End;
  S := ''; Done := False;
  While Not Done And (Length(S) < 250) Do
  Begin
    N := FReadAt(H, Block * 512, @B, 512);
    If N <= 0 Then Break;
    For K := 0 To N - 1 Do
    Begin
      If B[K] = $1A Then
      Begin
        Done := True;
        Break;
      End;
      If Length(S) >= 250 Then Break;
      If B[K] = 13 Then S := S + ' '
      Else If B[K] >= 32 Then S := S + Chr(B[K]);
    End;
    Inc(Block);
  End;
  DosClose(H);
  DbtMemo := S;
End;

Function ClarionText(T, Col : LongInt) : String;
Var Ofs, J, Len, V : LongInt; Raw, Fs, Digits, IP, FP : String; Sg : Single; Db : Double; B : LongInt;
    Neg : Boolean;
Begin
  ClarionText := '';
  With FT[T] Do
  Begin
    Ofs := Cols[Col].Ofs; Len := Cols[Col].Len;
    Case Ord(Cols[Col].TypeCode) Of
      1 : ClarionText := IStr(LE32(Rec, Ofs));
      6 :
        Begin
          V := LE16(Rec, Ofs);
          If V >= 32768 Then V := V - 65536;
          ClarionText := IStr(V);
        End;
      5 : ClarionText := IStr(Rec^[Ofs]);
      3, 4 :
        Begin
          Raw := '';
          For J := 0 To Len - 1 Do If Length(Raw) < 255 Then Raw := Raw + Chr(Rec^[Ofs + J]);
          ClarionText := Trim(Raw);
        End;
      2 :
        If Len = 4 Then
        Begin
          Move(Rec^[Ofs], Sg, 4);
          Db := Sg;
          Str(Db : 0 : 6, Fs);
          ClarionText := Fs;
        End
        Else If Len = 8 Then
        Begin
          Move(Rec^[Ofs], Db, 8);
          Str(Db : 0 : 6, Fs);
          ClarionText := Fs;
        End
        Else ClarionText := '[reel de ' + IStr(Len) + ' octets]';
      7 :
        Begin
          Raw := '';
          For J := 0 To Len - 1 Do If Length(Raw) < 250 Then Raw := Raw + HexByte(Rec^[Ofs + J]) + ' ';
          ClarionText := Trim(Raw);
        End;
      8 :
        Begin
          Digits := ''; Neg := False;
          For J := 0 To Len - 1 Do
          Begin
            B := Rec^[Ofs + J];
            Digits := Digits + Chr(48 + (B Shr 4));
            If J < Len - 1 Then Digits := Digits + Chr(48 + (B And 15))
            Else If (B And 15) = $0D Then Neg := True;
          End;
          If Digits = '' Then Digits := '0';
          If Cols[Col].Decimals > 0 Then
          Begin
            While Length(Digits) <= Cols[Col].Decimals Do Digits := '0' + Digits;
            IP := Copy(Digits, 1, Length(Digits) - Cols[Col].Decimals);
            FP := Copy(Digits, Length(Digits) - Cols[Col].Decimals + 1, Cols[Col].Decimals);
          End
          Else
          Begin
            IP := Digits; FP := '';
          End;
          While (Length(IP) > 1) And (IP[1] = '0') Do Delete(IP, 1, 1);
          If FP <> '' Then IP := IP + '.' + FP;
          If Neg And (IP <> '0') Then IP := '-' + IP;
          ClarionText := IP;
        End;
    Else
      ClarionText := '[type ' + IStr(Ord(Cols[Col].TypeCode)) + ']';
    End;
  End;
End;

{ texte d'une cellule ; Null : valeur absente }
Function FtCell(T, R, Col : LongInt; Var Null : Boolean) : String;
Var Raw : String; I : LongInt; Ch : Char;
Begin
  FtCell := ''; Null := False;
  With FT[T] Do
  Begin
    If (Col < 0) Or (Col >= NCol) Then Exit;
    FtRead(T, R);
    If CurRec <> R Then Exit;
    Case Fmt Of
      ftDbf :
        Begin
          Raw := '';
          For I := 0 To Cols[Col].Len - 1 Do If Length(Raw) < 255 Then Raw := Raw + Chr(Rec^[Cols[Col].Ofs + I]);
          Case Cols[Col].TypeCode Of
            'M' :
              Begin
                Raw := Trim(Raw);
                If Raw = '' Then Null := True Else FtCell := DbtMemo(T, SVal(Raw));
              End;
            'D' :
              If Length(Trim(Raw)) = 8 Then FtCell := Copy(Raw, 1, 4) + '-' + Copy(Raw, 5, 2) + '-' + Copy(Raw, 7, 2)
              Else
              Begin
                FtCell := Trim(Raw);
                If Trim(Raw) = '' Then Null := True;
              End;
            'L' :
              Begin
                Ch := ' ';
                If Length(Raw) > 0 Then Ch := Raw[1];
                Case Ch Of
                  'T', 't', 'Y', 'y' : FtCell := '1';
                  'F', 'f', 'N', 'n' : FtCell := '0';
                Else
                  Null := True;
                End;
              End;
            'N', 'F' :
              Begin
                FtCell := Trim(Raw);
                If Trim(Raw) = '' Then Null := True;
              End;
          Else
            FtCell := Trim(Raw);
          End;
        End;
      ftCsv : FtCell := CsvField(T, Col);
      ftClarion : FtCell := ClarionText(T, Col);
      ftBtrieve, ftMyd :
        Begin
          Raw := '';
          For I := 0 To Cols[Col].Len - 1 Do
            If Length(Raw) < 250 Then Raw := Raw + HexByte(Rec^[Cols[Col].Ofs + I]) + ' ';
          FtCell := Trim(Raw);
        End;
    End;
  End;
End;

{ --- ouverture par format --- }

Function OpenDbf(T : LongInt) : Boolean;
Var Hdr, Fb : Array[0..31] Of Byte; Ver, HdrLen, RecLen, Cnt, Avail, Fs, Fp, Sum, I, NL : LongInt; Nm : String;
Begin
  OpenDbf := False;
  With FT[T] Do
  Begin
    If FReadAt(H, 0, @Hdr, 32) <> 32 Then
    Begin
      Err := 'DBF : en-t'#136'te illisible.';
      Exit;
    End;
    Ver := Hdr[0];
    If (Ver <> $03) And (Ver <> $83) And (Ver <> $30) And (Ver <> $F5) And (Ver <> $8B) Then
    Begin
      Err := 'DBF : version $' + HexByte(Ver) + ' non prise en charge (dBASE III : $03 ou $83).';
      Exit;
    End;
    Cnt := LE32(@Hdr, 4);
    HdrLen := LE16(@Hdr, 8); RecLen := LE16(@Hdr, 10);
    If (HdrLen < 33) Or (RecLen < 1) Then
    Begin
      Err := 'DBF : en-t'#136'te incoh'#130'rent.';
      Exit;
    End;
    Fs := FSizeOf(H);
    NCol := 0; Sum := 1; Fp := 32;
    While Fp + 1 <= HdrLen Do
    Begin
      If FReadAt(H, Fp, @Fb, 32) < 1 Then Break;
      If Fb[0] = $0D Then Break;
      If NCol >= MaxFCol Then
      Begin
        Err := 'DBF : trop de champs (limite ' + IStr(MaxFCol) + ').';
        Exit;
      End;
      NL := 0;
      While (NL < 11) And (Fb[NL] <> 0) Do Inc(NL);
      Nm := '';
      For I := 0 To NL - 1 Do Nm := Nm + Chr(Fb[I]);
      FtSetColName(T, NCol, Nm);
      Cols[NCol].TypeCode := Chr(Fb[$0B]);
      Cols[NCol].Ofs := Sum;
      Cols[NCol].Len := Fb[$10];
      Cols[NCol].Decimals := Fb[$11];
      Sum := Sum + Fb[$10];
      Inc(NCol);
      Fp := Fp + 32;
    End;
    If NCol = 0 Then
    Begin
      Err := 'DBF : aucun champ.';
      Exit;
    End;
    RecordLen := RecLen; DataStart := HdrLen;
    Avail := (Fs - HdrLen) Div RecLen;
    If Avail < 0 Then Avail := 0;
    If Cnt > Avail Then Cnt := Avail;
    If Cnt < 0 Then Cnt := 0;
    RecordCount := Cnt;
  End;
  OpenDbf := True;
End;

Function OpenCsv(T : LongInt) : Boolean;
Var Buf : Array[0..8191] Of Byte; Got, I, Pos, RecStart, MaxLen, Fs, Row0 : LongInt; Ch : LongInt;
    InQ, AfterQ, SkipLF, Again : Boolean;

  Procedure Emit;
  Begin
    With FT[T] Do
    Begin
      RowGrow(T);
      RowOfs^[RecordCount] := RecStart;
      RowLen^[RecordCount] := Pos - RecStart;
      If Pos - RecStart > MaxLen Then MaxLen := Pos - RecStart;
      Inc(RecordCount);
    End;
    RecStart := Pos + 1;
  End;

Begin
  OpenCsv := False;
  With FT[T] Do
  Begin
    Fs := FSizeOf(H);
    If Fs <= 0 Then
    Begin
      Err := 'CSV : fichier vide.';
      Exit;
    End;
    RecordCount := 0; MaxLen := 0; Row0 := 1;
    InQ := False; AfterQ := False; SkipLF := False;
    Pos := 0; RecStart := 0;
    Got := FReadAt(H, 0, @Buf, 0);
    Repeat
      Got := FRead(H, @Buf, 8192);
      If Got <= 0 Then Break;
      For I := 0 To Got - 1 Do
      Begin
        Ch := Buf[I];
        Repeat
          Again := False;
          If AfterQ Then
          Begin
            AfterQ := False;
            If Ch = 34 Then InQ := True
            Else
            Begin
              InQ := False;
              Again := True;
            End;
          End
          Else If InQ Then
          Begin
            If Ch = 34 Then AfterQ := True;
          End
          Else
          Begin
            If Ch = 34 Then
            Begin
              InQ := True; SkipLF := False;
            End
            Else If Ch = 10 Then
            Begin
              If SkipLF Then
              Begin
                SkipLF := False;
                RecStart := Pos + 1;
              End
              Else Emit;
            End
            Else If Ch = 13 Then
            Begin
              Emit;
              SkipLF := True;
            End
            Else
            Begin
              SkipLF := False;
              If (Ch = 44) And (RecordCount = 0) Then Inc(Row0);
            End;
          End;
        Until Not Again;
        Inc(Pos);
      End;
    Until Got < 8192;
    If RecStart < Pos Then Emit;
    If RecordCount = 0 Then
    Begin
      Err := 'CSV : aucune ligne.';
      Exit;
    End;
    If Row0 > MaxFCol Then
    Begin
      Err := 'CSV : trop de colonnes (limite ' + IStr(MaxFCol) + ').';
      Exit;
    End;
    NCol := Row0;
    For I := 0 To NCol - 1 Do
    Begin
      FtSetColName(T, I, 'Champ' + IStr(I + 1));
      Cols[I].TypeCode := 'C'; Cols[I].Ofs := 0; Cols[I].Len := 0; Cols[I].Decimals := 0;
    End;
    If MaxLen < 1 Then MaxLen := 1;
    RecordLen := MaxLen; DataStart := 0;
  End;
  OpenCsv := True;
End;

Function OpenBtrieve(T : LongInt) : Boolean;
Var Hdr : Array[0..271] Of Byte; Pg : PBytes; Fs, NPages, PNum, POfs, SOfs, Cap, Si, K, NC, CL : LongInt;
    Sig, Seq, PagSize, RecLenW, PhyLenW, UsrFlags, Usage : LongInt; AllZero : Boolean;
Begin
  OpenBtrieve := False;
  With FT[T] Do
  Begin
    Fs := FSizeOf(H);
    If (Fs < 272) Or (FReadAt(H, 0, @Hdr, 272) <> 272) Then
    Begin
      Err := '.DAT : ni Clarion ni Btrieve (fichier trop court).';
      Exit;
    End;
    Sig := LE16(@Hdr, 0); Seq := LE16(@Hdr, 2); PagSize := LE16(@Hdr, 8);
    If (Seq <> 0) Or (Sig <> 0) Then
    Begin
      If Sig = $4346 Then Err := '.DAT Btrieve : format 6.x ("FC") non pris en charge.'
      Else Err := '.DAT : format non reconnu (ni Clarion ni Btrieve).';
      Exit;
    End;
    If (PagSize = 0) Or (PagSize Mod 512 <> 0) Or (PagSize > 4096) Or (Fs Mod PagSize <> 0) Then
    Begin
      Err := '.DAT Btrieve : taille de page incoh'#130'rente.';
      Exit;
    End;
    RecLenW := LE16(@Hdr, $16); PhyLenW := LE16(@Hdr, $18);
    UsrFlags := LE16(@Hdr, $106);
    If (RecLenW = 0) Or (PhyLenW = 0) Or (RecLenW > PhyLenW) Or (PhyLenW > PagSize - 6) Then
    Begin
      Err := '.DAT Btrieve : longueurs d''enregistrement incoh'#130'rentes.';
      Exit;
    End;
    If ((UsrFlags And $0809) <> 0) Or (Hdr[$38] <> 0) Then
    Begin
      Err := '.DAT Btrieve : enregistrements variables ou compress'#130's, non pris en charge.';
      Exit;
    End;
    Cap := (PagSize - 6) Div PhyLenW;
    RecordCount := 0;
    NPages := Fs Div PagSize;
    GetMem(Pg, 4096);
    For PNum := 1 To NPages - 1 Do
    Begin
      POfs := PNum * PagSize;
      If FReadAt(H, POfs, Pg, PagSize) <> PagSize Then Break;
      Usage := LE16(Pg, 4);
      If (Usage And $8000) = 0 Then Continue;
      For Si := 0 To Cap - 1 Do
      Begin
        SOfs := 6 + Si * PhyLenW;
        AllZero := True;
        For K := 4 To PhyLenW - 1 Do
          If Pg^[SOfs + K] <> 0 Then
          Begin
            AllZero := False;
            Break;
          End;
        If AllZero Then Continue;
        RowGrow(T);
        RowOfs^[RecordCount] := POfs + SOfs;
        RowLen^[RecordCount] := RecLenW;
        Inc(RecordCount);
      End;
    End;
    FreeMem(Pg, 4096);
    NC := (RecLenW + 15) Div 16;
    If NC > MaxFCol Then NC := MaxFCol;
    NCol := NC;
    For Si := 0 To NC - 1 Do
    Begin
      CL := 16;
      If (Si + 1) * 16 > RecLenW Then CL := RecLenW - Si * 16;
      FtSetColName(T, Si, 'Champ' + IStr(Si + 1));
      Cols[Si].TypeCode := 'X'; Cols[Si].Ofs := Si * 16; Cols[Si].Len := CL; Cols[Si].Decimals := 0;
    End;
    RecordLen := RecLenW; DataStart := 0;
    Fmt := ftBtrieve;
  End;
  OpenBtrieve := True;
End;

Function OpenClarion(T : LongInt) : Boolean;
Var Hdr : Array[0..84] Of Byte; Fb : Array[0..26] Of Byte; Fs, DOfs, NRec, Avail, Fp, NF, RL, Sf, I, J : LongInt;
    Nm : String;
Begin
  OpenClarion := False;
  With FT[T] Do
  Begin
    Fs := FSizeOf(H);
    If (Fs < 85) Or (FReadAt(H, 0, @Hdr, 85) <> 85) Then
    Begin
      Err := '.DAT : fichier trop court.';
      Exit;
    End;
    NF := LE16(@Hdr, $0D); RL := LE16(@Hdr, $13); DOfs := LE32(@Hdr, $15); NRec := LE32(@Hdr, $05);
    Sf := LE16(@Hdr, $02);
    If Not ((NF > 0) And (NF <= MaxFCol) And (RL >= 5) And (85 + NF * 27 <= DOfs) And (DOfs <= Fs)) Then
    Begin
      OpenClarion := OpenBtrieve(T);
      Exit;
    End;
    If (Sf And $0014) <> 0 Then
    Begin
      Err := '.DAT Clarion : fichier chiffr'#130' ou compress'#130', non pris en charge.';
      Exit;
    End;
    NCol := 0; Fp := 85;
    For I := 0 To NF - 1 Do
    Begin
      If FReadAt(H, Fp, @Fb, 27) <> 27 Then
      Begin
        Err := '.DAT Clarion : descripteur de champ illisible.';
        Exit;
      End;
      Nm := '';
      For J := 0 To 15 Do Nm := Nm + Chr(Fb[1 + J]);
      FtSetColName(T, NCol, Trim(Nm));
      Cols[NCol].TypeCode := Chr(Fb[0]);
      Cols[NCol].Ofs := 5 + LE16(@Fb, $11);
      Cols[NCol].Len := LE16(@Fb, $13);
      Cols[NCol].Decimals := Fb[$16];
      Inc(NCol);
      Fp := Fp + 27;
    End;
    RecordLen := RL; DataStart := DOfs;
    Avail := (Fs - DOfs) Div RL;
    If Avail < 0 Then Avail := 0;
    If NRec > Avail Then NRec := Avail;
    If NRec < 0 Then NRec := 0;
    RecordCount := NRec;
  End;
  OpenClarion := True;
End;

Function OpenMyd(T : LongInt) : Boolean;
Var Mh, MySize, BasePos, Pos, Fs, Options, NKeys, NUniq, NF, KS, PackRL, StRecs, Sum, I : LongInt;
    Hdr : Array[0..123] Of Byte; Base : Array[0..99] Of Byte; Cb : Array[0..6] Of Byte; Sk : Array[0..1] Of Byte;

  Function Fail(S : String) : Boolean;
  Begin
    FT[T].Err := S;
    DosClose(Mh);
    Fail := False;
  End;

Begin
  OpenMyd := False;
  With FT[T] Do
  Begin
    If Not FOpenRead(SiblingExt(Name, 'MYI'), Mh) Then
    Begin
      Err := '.MYD : fichier .MYI associ'#130' introuvable.';
      Exit;
    End;
    MySize := FSizeOf(Mh);
    If (MySize < 124) Or (FReadAt(Mh, 0, @Hdr, 124) <> 124) Then
    Begin
      OpenMyd := Fail('.MYI : en-t'#136'te illisible.');
      Exit;
    End;
    Options := LE16(@Hdr, 4);
    BasePos := LE16(@Hdr, $0C);
    NKeys := Hdr[$12]; NUniq := Hdr[$13];
    StRecs := LE32(@Hdr, 28);
    If (Options And 4) <> 0 Then
    Begin
      OpenMyd := Fail('.MYD : table compress'#130'e (myisampack), non prise en charge.');
      Exit;
    End;
    If (Options And 1) <> 0 Then
    Begin
      OpenMyd := Fail('.MYD : table DYNAMIC, non prise en charge (FIXED seulement).');
      Exit;
    End;
    If (BasePos < 124) Or (BasePos + 100 > MySize) Or (FReadAt(Mh, BasePos, @Base, 100) <> 100) Then
    Begin
      OpenMyd := Fail('.MYI : MI_BASE_INFO illisible.');
      Exit;
    End;
    PackRL := LE32(@Base, $30); NF := LE32(@Base, $40);
    If (NF <= 0) Or (NF > MaxFCol) Or (PackRL <= 1) Then
    Begin
      OpenMyd := Fail('.MYI : MI_BASE_INFO incoh'#130'rent.');
      Exit;
    End;
    Pos := BasePos + 100;
    For I := 1 To NKeys Do
    Begin
      If FReadAt(Mh, Pos, @Sk, 1) <> 1 Then
      Begin
        OpenMyd := Fail('.MYI : MI_KEYDEF illisible.');
        Exit;
      End;
      Pos := Pos + 12 + Sk[0] * 18;
    End;
    For I := 1 To NUniq Do
    Begin
      If FReadAt(Mh, Pos, @Sk, 2) <> 2 Then
      Begin
        OpenMyd := Fail('.MYI : MI_UNIQUEDEF illisible.');
        Exit;
      End;
      KS := LE16(@Sk, 0);
      Pos := Pos + 4 + KS * 18;
    End;
    NCol := 0; Sum := 0;
    For I := 0 To NF - 1 Do
    Begin
      If FReadAt(Mh, Pos, @Cb, 7) <> 7 Then
      Begin
        OpenMyd := Fail('.MYI : MI_COLUMNDEF illisible.');
        Exit;
      End;
      If Cb[4] <> 0 Then
      Begin
        OpenMyd := Fail('.MYD : colonnes NULL, disposition non v'#130'rifi'#130'e.');
        Exit;
      End;
      FtSetColName(T, NCol, 'Champ' + IStr(I + 1));
      Cols[NCol].TypeCode := 'X';
      Cols[NCol].Ofs := 1 + Sum;
      Cols[NCol].Len := LE16(@Cb, 2);
      Cols[NCol].Decimals := 0;
      Sum := Sum + Cols[NCol].Len;
      Inc(NCol);
      Pos := Pos + 7;
    End;
    DosClose(Mh);
    If Sum <> PackRL - 1 Then
    Begin
      Err := '.MYD : enregistrement plus complexe qu''une concat'#130'nation (NULL, VARCHAR).';
      Exit;
    End;
    RecordLen := PackRL; DataStart := 0;
    Fs := FSizeOf(H);
    RecordCount := Fs Div RecordLen;
    If StRecs < RecordCount Then RecordCount := StRecs;
    If RecordCount < 0 Then RecordCount := 0;
  End;
  OpenMyd := True;
End;

Procedure FtClose(T : LongInt);
Begin
  If (T < 0) Or (T >= MaxFTab) Then Exit;
  With FT[T] Do
  Begin
    If Not Used Then Exit;
    If H <> 0 Then DosClose(H);
    H := 0;
    If Rec <> Nil Then FreeMem(Rec, RecordLen + 16);
    Rec := Nil;
    If RowCap > 0 Then
    Begin
      FreeMem(RowOfs, RowCap * 4); FreeMem(RowLen, RowCap * 4);
    End;
    RowCap := 0; RowOfs := Nil; RowLen := Nil;
    BufFree(Names);
    Used := False;
  End;
End;

{ ouvrir une table ; rend son numero (-1 : erreur dans FtErr) }
Var
  FtErr : String;

Function FtOpen(Fn : String) : LongInt;
Var T, K, J : LongInt; Ok : Boolean; Null : Boolean; S : String;
Begin
  FtOpen := -1;
  FtErr := '';
  { deja ouverte ? }
  For K := 0 To MaxFTab - 1 Do
    If FT[K].Used And (UpStr(FT[K].Name) = UpStr(Fn)) Then
    Begin
      FtOpen := K;
      Exit;
    End;
  T := -1;
  For K := MaxFTab - 1 DownTo 0 Do If Not FT[K].Used Then T := K;
  If T < 0 Then
  Begin
    FtErr := 'Trop de tables ouvertes (' + IStr(MaxFTab) + ').';
    Exit;
  End;
  FillChar(FT[T], SizeOf(TFTab), 0);
  With FT[T] Do
  Begin
    Name := Fn; Fmt := FmtOfExt(ExtOf(Fn));
    If Fmt = ftNone Then
    Begin
      FtErr := 'Type de fichier non reconnu : ' + NameOf(Fn) + ' (DBF, CSV, DAT, MYD).';
      Exit;
    End;
    CurRec := -1;
    Writable := False;
    If FmtEditable(Fmt) Then Writable := FOpenRW(Fn, H);
    If Not Writable Then
      If Not FOpenRead(Fn, H) Then
      Begin
        FtErr := 'Impossible d''ouvrir ' + Fn + '.';
        Exit;
      End;
    Used := True;
    Case Fmt Of
      ftDbf : Ok := OpenDbf(T);
      ftCsv : Ok := OpenCsv(T);
      ftClarion : Ok := OpenClarion(T);
      ftMyd : Ok := OpenMyd(T);
    Else
      Ok := False;
    End;
    If Not Ok Then
    Begin
      FtErr := Err;
      FtClose(T);
      Exit;
    End;
    GetMem(Rec, RecordLen + 16);
    CurRec := -1;
    { CSV : noms des colonnes d'apres la premiere ligne }
    CsvHdr := False;
    If (Fmt = ftCsv) And CsvHeaders And (RecordCount > 1) Then
    Begin
      FtRead(T, 0);
      If CsvCount(T) = NCol Then
      Begin
        CsvHdr := True;
        For J := 0 To NCol - 1 Do
        Begin
          S := Trim(FtCell(T, 0, J, Null));
          If S <> '' Then FtSetColName(T, J, Copy(S, 1, 63));
        End;
      End;
    End;
  End;
  FtOpen := T;
End;

{ premiere ligne de donnees (CSV avec en-tetes : 1) }
Function FtFirst(T : LongInt) : LongInt;
Begin
  If FT[T].CsvHdr Then FtFirst := 1 Else FtFirst := 0;
End;

Function FtRows(T : LongInt) : LongInt;
Begin
  FtRows := FT[T].RecordCount - FtFirst(T);
End;

{ type de la colonne en clair }
Function FtTypeName(T, C : LongInt) : String;
Var S : String;
Begin
  With FT[T] Do
  Begin
    S := '';
    Case Fmt Of
      ftDbf :
        Case Cols[C].TypeCode Of
          'C' : S := 'CHAR(' + IStr(Cols[C].Len) + ')';
          'N', 'F' :
            If Cols[C].Decimals > 0 Then S := 'NUMERIC(' + IStr(Cols[C].Len) + ',' + IStr(Cols[C].Decimals) + ')'
            Else S := 'NUMERIC(' + IStr(Cols[C].Len) + ')';
          'D' : S := 'DATE';
          'L' : S := 'LOGICAL';
          'M' : S := 'MEMO';
        Else
          S := Cols[C].TypeCode;
        End;
      ftCsv : S := 'TEXT';
      ftClarion :
        Case Ord(Cols[C].TypeCode) Of
          1 : S := 'LONG';
          2 : S := 'REAL';
          3, 4 : S := 'STRING(' + IStr(Cols[C].Len) + ')';
          5 : S := 'BYTE';
          6 : S := 'SHORT';
          7 : S := 'GROUP(' + IStr(Cols[C].Len) + ')';
          8 : S := 'DECIMAL(' + IStr(Cols[C].Len * 2 - 1) + ',' + IStr(Cols[C].Decimals) + ')';
        Else
          S := '?';
        End;
    Else
      S := 'BINARY(' + IStr(Cols[C].Len) + ')';
    End;
  End;
  FtTypeName := S;
End;

{ ==================================================================== }
{ Modification d'une cellule                                            }
{ ==================================================================== }

Function PackHex(T, Col : LongInt; Text : String; Var E : String) : Boolean;
Var Ofs, Len, I, Code : LongInt; Cl : String; B : LongInt;
Begin
  PackHex := False;
  Ofs := FT[T].Cols[Col].Ofs; Len := FT[T].Cols[Col].Len;
  Cl := '';
  For I := 1 To Length(Text) Do If Text[I] <> ' ' Then Cl := Cl + Text[I];
  If Length(Cl) <> Len * 2 Then
  Begin
    E := IStr(Len) + ' octets hexad'#130'cimaux attendus (' + IStr(Len * 2) + ' chiffres).';
    Exit;
  End;
  For I := 0 To Len - 1 Do
  Begin
    Val('$' + Copy(Cl, I * 2 + 1, 2), B, Code);
    If Code <> 0 Then
    Begin
      E := 'chiffre hexad'#130'cimal invalide.';
      Exit;
    End;
    FT[T].Rec^[Ofs + I] := B;
  End;
  PackHex := True;
End;

Function PackDbf(T, Col : LongInt; Text : String; Var E : String) : Boolean;
Var Ofs, Len, Dc, I, Code : LongInt; S : String; D : Double; Ch : Char;
Begin
  PackDbf := False;
  With FT[T] Do
  Begin
    Ofs := Cols[Col].Ofs; Len := Cols[Col].Len; Dc := Cols[Col].Decimals;
    Case Cols[Col].TypeCode Of
      'M' :
        Begin
          E := 'un m'#130'mo ne se modifie pas dans la grille.';
          Exit;
        End;
      'C' :
        Begin
          If Length(Text) > Len Then
          Begin
            E := 'texte trop long (' + IStr(Len) + ' caract'#138'res au plus).';
            Exit;
          End;
          S := Text;
          While Length(S) < Len Do S := S + ' ';
          For I := 0 To Len - 1 Do Rec^[Ofs + I] := Ord(S[I + 1]);
        End;
      'L' :
        Begin
          S := UpStr(Trim(Text));
          Ch := '?';
          If (S = 'VRAI') Or (S = 'T') Or (S = 'Y') Or (S = '1') Or (S = 'TRUE') Then Ch := 'T'
          Else If (S = 'FAUX') Or (S = 'F') Or (S = 'N') Or (S = '0') Or (S = 'FALSE') Then Ch := 'F'
          Else If (S = '') Or (S = 'NULL') Then Ch := ' ';
          If Ch = '?' Then
          Begin
            E := 'valeur logique attendue (1 ou 0).';
            Exit;
          End;
          Rec^[Ofs] := Ord(Ch);
          For I := 1 To Len - 1 Do Rec^[Ofs + I] := 32;
        End;
      'D' :
        Begin
          S := Trim(Text);
          If (S = '') Or (UpStr(S) = 'NULL') Then
            For I := 0 To Len - 1 Do Rec^[Ofs + I] := 32
          Else
          Begin
            { AAAA-MM-JJ ou JJ/MM/AAAA }
            If (Length(S) = 10) And (S[5] = '-') And (S[8] = '-') Then S := Copy(S, 1, 4) + Copy(S, 6, 2) + Copy(S, 9, 2)
            Else If (Length(S) = 10) And (S[3] = '/') And (S[6] = '/') Then S := Copy(S, 7, 4) + Copy(S, 4, 2) + Copy(S, 1, 2)
            Else
            Begin
              E := 'date attendue (AAAA-MM-JJ).';
              Exit;
            End;
            For I := 1 To 8 Do
              If Not (S[I] In ['0'..'9']) Then
              Begin
                E := 'date invalide.';
                Exit;
              End;
            If Len <> 8 Then
            Begin
              E := 'champ date de largeur inattendue.';
              Exit;
            End;
            For I := 0 To 7 Do Rec^[Ofs + I] := Ord(S[I + 1]);
          End;
        End;
      'N', 'F' :
        Begin
          S := Trim(Text);
          If (S = '') Or (UpStr(S) = 'NULL') Then
          Begin
            For I := 0 To Len - 1 Do Rec^[Ofs + I] := 32;
          End
          Else
          Begin
            Val(S, D, Code);
            If Code <> 0 Then
            Begin
              E := 'nombre invalide.';
              Exit;
            End;
            If Dc > 0 Then Str(D : 0 : Dc, S) Else Str(D : 0 : 0, S);
            If Length(S) > Len Then
            Begin
              E := 'nombre trop grand pour ' + IStr(Len) + ' caract'#138'res.';
              Exit;
            End;
            While Length(S) < Len Do S := ' ' + S;
            For I := 0 To Len - 1 Do Rec^[Ofs + I] := Ord(S[I + 1]);
          End;
        End;
    Else
      Begin
        E := 'type de champ non modifiable.';
        Exit;
      End;
    End;
  End;
  PackDbf := True;
End;

Function PackClarion(T, Col : LongInt; Text : String; Var E : String) : Boolean;
Var Ofs, Len, Dc, I, J, Code, Hn, Ln : LongInt; S, IP, FP, Dg : String; L : LongInt; D : Double; Sg : Single;
    Neg, Bad : Boolean;
Begin
  PackClarion := False;
  With FT[T] Do
  Begin
    Ofs := Cols[Col].Ofs; Len := Cols[Col].Len; Dc := Cols[Col].Decimals;
    S := Trim(Text);
    Case Ord(Cols[Col].TypeCode) Of
      1, 5, 6 :
        Begin
          Val(S, L, Code);
          If (Code <> 0) Or ((Ord(Cols[Col].TypeCode) = 5) And ((L < 0) Or (L > 255))) Or
             ((Ord(Cols[Col].TypeCode) = 6) And ((L < -32768) Or (L > 32767))) Then
          Begin
            E := 'entier invalide.';
            Exit;
          End;
          Rec^[Ofs] := L And 255;
          If Ord(Cols[Col].TypeCode) <> 5 Then Rec^[Ofs + 1] := (L Shr 8) And 255;
          If Ord(Cols[Col].TypeCode) = 1 Then
          Begin
            Rec^[Ofs + 2] := (L Shr 16) And 255; Rec^[Ofs + 3] := (L Shr 24) And 255;
          End;
        End;
      3, 4 :
        Begin
          If Length(Text) > Len Then
          Begin
            E := 'texte trop long (' + IStr(Len) + ' caract'#138'res au plus).';
            Exit;
          End;
          S := Text;
          While Length(S) < Len Do S := S + ' ';
          For I := 0 To Len - 1 Do Rec^[Ofs + I] := Ord(S[I + 1]);
        End;
      2 :
        Begin
          Val(S, D, Code);
          If (Code <> 0) Or ((Len <> 4) And (Len <> 8)) Then
          Begin
            E := 'nombre r'#130'el invalide.';
            Exit;
          End;
          If Len = 4 Then
          Begin
            Sg := D;
            Move(Sg, Rec^[Ofs], 4);
          End
          Else Move(D, Rec^[Ofs], 8);
        End;
      7 :
        Begin
          PackClarion := PackHex(T, Col, Text, E);
          Exit;
        End;
      8 :
        Begin
          Neg := (Length(S) > 0) And (S[1] = '-');
          If Neg Then Delete(S, 1, 1);
          I := Pos('.', S);
          If I > 0 Then
          Begin
            IP := Copy(S, 1, I - 1); FP := Copy(S, I + 1, 255);
          End
          Else
          Begin
            IP := S; FP := '';
          End;
          If IP = '' Then IP := '0';
          While Length(FP) < Dc Do FP := FP + '0';
          FP := Copy(FP, 1, Dc);
          Dg := IP + FP;
          Bad := Dg = '';
          For I := 1 To Length(Dg) Do If Not (Dg[I] In ['0'..'9']) Then Bad := True;
          If Bad Or (Length(Dg) > Len * 2 - 1) Then
          Begin
            E := 'nombre d'#130'cimal invalide ou trop grand.';
            Exit;
          End;
          While Length(Dg) < Len * 2 - 1 Do Dg := '0' + Dg;
          For J := 0 To Len - 1 Do
          Begin
            Hn := Ord(Dg[2 * J + 1]) - 48;
            If J < Len - 1 Then Ln := Ord(Dg[2 * J + 2]) - 48
            Else If Neg Then Ln := $0D
            Else Ln := $0C;
            Rec^[Ofs + J] := (Hn Shl 4) Or Ln;
          End;
        End;
    Else
      Begin
        E := 'type de champ non modifiable.';
        Exit;
      End;
    End;
  End;
  PackClarion := True;
End;

Function CsvNeedQ(S : String) : Boolean;
Var I : LongInt;
Begin
  CsvNeedQ := False;
  For I := 1 To Length(S) Do
    If (S[I] = ',') Or (S[I] = '"') Or (S[I] = #13) Or (S[I] = #10) Then CsvNeedQ := True;
End;

Procedure CsvPut(Var B : TBuf; S : String);
Var I : LongInt;
Begin
  If CsvNeedQ(S) Then
  Begin
    BufAddC(B, 34);
    For I := 1 To Length(S) Do
    Begin
      If S[I] = '"' Then BufAddC(B, 34);
      BufAddC(B, Ord(S[I]));
    End;
    BufAddC(B, 34);
  End
  Else BufAdd(B, S);
End;

{ CSV : la ligne R est reconstruite, le fichier recopie (lu en entier) }
Function CsvCommit(T, R, Col : LongInt; Text : String; Var E : String) : Boolean;
Var Fl : Array[0..MaxFCol - 1] Of String; I, Fs, OldOfs, OldLen, Delta, H2 : LongInt; Nl, All : TBuf; Null : Boolean;
Begin
  CsvCommit := False;
  With FT[T] Do
  Begin
    CurRec := -1;
    FtRead(T, R);
    If CurRec <> R Then
    Begin
      E := 'ligne illisible.';
      Exit;
    End;
    If CsvCount(T) <> NCol Then
    Begin
      E := 'ligne irr'#130'guli'#138're (nombre de champs) : non modifiable.';
      Exit;
    End;
    For I := 0 To NCol - 1 Do
      If I = Col Then Fl[I] := Text
      Else
      Begin
        Fl[I] := FtCell(T, R, I, Null);
        If Length(Fl[I]) >= 250 Then
        Begin
          E := 'un autre champ de la ligne d'#130'passe 250 caract'#138'res : non modifiable.';
          Exit;
        End;
      End;
    BufInit(Nl);
    For I := 0 To NCol - 1 Do
    Begin
      If I > 0 Then BufAddC(Nl, 44);
      CsvPut(Nl, Fl[I]);
    End;
    OldOfs := RowOfs^[R]; OldLen := RowLen^[R];
    Fs := FSizeOf(H);
    BufInit(All);
    If Not BufGrow(All, Fs + Nl.Len + 16) Then
    Begin
      BufFree(Nl);
      E := 'm'#130'moire insuffisante.';
      Exit;
    End;
    All.Len := FReadAt(H, 0, All.P, Fs);
    DosClose(H);
    H := 0;
    If Not FOpenWrite(Name, H2) Then
    Begin
      Dummy := Ord(FOpenRW(Name, H));
      BufFree(Nl); BufFree(All);
      E := 'impossible de r'#130#130'crire ' + Name + '.';
      Exit;
    End;
    Dummy := FWrite(H2, All.P, OldOfs);
    Dummy := FWrite(H2, Nl.P, Nl.Len);
    If All.Len > OldOfs + OldLen Then Dummy := FWrite(H2, @All.P^[OldOfs + OldLen], All.Len - OldOfs - OldLen);
    DosClose(H2);
    Dummy := Ord(FOpenRW(Name, H));
    Delta := Nl.Len - OldLen;
    RowLen^[R] := Nl.Len;
    For I := R + 1 To RecordCount - 1 Do RowOfs^[I] := RowOfs^[I] + Delta;
    If Nl.Len > RecordLen Then
    Begin
      FreeMem(Rec, RecordLen + 16);
      RecordLen := Nl.Len;
      GetMem(Rec, RecordLen + 16);
    End;
    BufFree(Nl); BufFree(All);
    CurRec := -1;
  End;
  CsvCommit := True;
End;

{ ecrire Text dans la cellule (ligne R du fichier) ; faux : E explique }
Function FtSetCell(T, R, Col : LongInt; Text : String; Var E : String) : Boolean;
Var Ok : Boolean; Ofs : LongInt;
Begin
  FtSetCell := False;
  E := '';
  With FT[T] Do
  Begin
    If Not Writable Then
    Begin
      If Fmt = ftMyd Then E := 'les tables MyISAM sont en lecture seule.'
      Else E := 'fichier en lecture seule.';
      Exit;
    End;
    If (Col < 0) Or (Col >= NCol) Or (R < 0) Or (R >= RecordCount) Then Exit;
    If Fmt = ftCsv Then
    Begin
      FtSetCell := CsvCommit(T, R, Col, Text, E);
      Exit;
    End;
    CurRec := -1;
    FtRead(T, R);
    If CurRec <> R Then
    Begin
      E := 'enregistrement illisible.';
      Exit;
    End;
    Case Fmt Of
      ftDbf : Ok := PackDbf(T, Col, Text, E);
      ftClarion : Ok := PackClarion(T, Col, Text, E);
      ftBtrieve : Ok := PackHex(T, Col, Text, E);
    Else
      Ok := False;
    End;
    If Not Ok Then
    Begin
      CurRec := -1;
      Exit;
    End;
    If RowOfs <> Nil Then Ofs := RowOfs^[R] Else Ofs := DataStart + R * RecordLen;
    If Not FWriteAt(H, Ofs, Rec, RecordLen) Then
    Begin
      E := 'erreur d'#39#130'criture.';
      CurRec := -1;
      Exit;
    End;
  End;
  FtSetCell := True;
End;

{ DBF : l'enregistrement est-il marque supprime ? }
Function FtDeleted(T, R : LongInt) : Boolean;
Begin
  FtDeleted := False;
  If FT[T].Fmt <> ftDbf Then Exit;
  FtRead(T, R);
  If FT[T].CurRec = R Then FtDeleted := FT[T].Rec^[0] = 42;
End;

{ DBF : marquer supprime (Del) ou retablir }
Function FtMarkDeleted(T, R : LongInt; Del : Boolean) : Boolean;
Begin
  FtMarkDeleted := False;
  With FT[T] Do
  Begin
    If (Fmt <> ftDbf) Or Not Writable Then Exit;
    CurRec := -1;
    FtRead(T, R);
    If CurRec <> R Then Exit;
    If Del Then Rec^[0] := 42 Else Rec^[0] := 32;
    FtMarkDeleted := FWriteAt(H, DataStart + R * RecordLen, Rec, RecordLen);
  End;
End;

{ DBF : ajouter un enregistrement vide a la fin ; rend son numero }
Function FtAppend(T : LongInt) : LongInt;
Var Hd : Array[0..7] Of Byte; N, I : LongInt; Eof_ : Array[0..0] Of Byte;
Begin
  FtAppend := -1;
  With FT[T] Do
  Begin
    If (Fmt <> ftDbf) Or Not Writable Then Exit;
    For I := 0 To RecordLen - 1 Do Rec^[I] := 32;
    N := RecordCount;
    If Not FWriteAt(H, DataStart + N * RecordLen, Rec, RecordLen) Then Exit;
    Eof_[0] := $1A;
    Dummy := Ord(FWriteAt(H, DataStart + (N + 1) * RecordLen, @Eof_, 1));
    Inc(RecordCount);
    If FReadAt(H, 0, @Hd, 8) = 8 Then
    Begin
      Hd[4] := RecordCount And 255; Hd[5] := (RecordCount Shr 8) And 255;
      Hd[6] := (RecordCount Shr 16) And 255; Hd[7] := (RecordCount Shr 24) And 255;
      Dummy := Ord(FWriteAt(H, 0, @Hd, 8));
    End;
    CurRec := -1;
    FtAppend := N;
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
{ Coloration syntaxique du SQL                                          }
{ ==================================================================== }

{ Etat d'une ligne (au debut) : 0 code, 1 commentaire /* */, 2 chaine
  '...', 3 identificateur "...", 4 chaine $$...$$ de PostgreSQL }

Const
  kTxt = 0; kKw = 1; kType = 2; kFunc = 3; kStr = 4; kCmt = 5; kNum = 6; kOp = 7; kVar = 8; kQId = 9;
  ColTab : Array[0..15] Of LongInt = (cBlack, cBlue, cTeal, cDPink, cRed, cDGreen, cBrown, cGray, cTeal, cBlack,
                                      cBlack, cBlack, cBlack, cBlack, cBlack, cBlack);
  Kw1 = ' add all alter and any as asc authorization backup begin between break browse bulk by cascade case check checkpoint close clustered coalesce collate column commit compute constraint contains continue convert create cross current cursor ';
  Kw2 = ' database dbcc deallocate declare default delete deny desc disk distinct distributed drop dump else end errlvl escape except exec execute exists exit external fetch file fillfactor for foreign freetext from full function goto grant group ';
  Kw3 = ' having holdlock identity if in index inner insert intersect into is join key kill left like lineno load merge national nocheck nonclustered not null nullif of off offsets on open option or order outer over percent pivot plan precision ';
  Kw4 = ' primary print proc procedure public raiserror read readtext reconfigure references replication restore restrict return revert revoke right rollback rowcount rowguidcol rule save schema select session_user set setuser shutdown some ';
  Kw5 = ' statistics system_user table tablesample textsize then to top tran transaction trigger truncate try_convert tsequal union unique unpivot update updatetext use user values varying view waitfor when where while with writetext limit offset ';
  Kw6 = ' returning ilike show databases tables columns describe explain analyze vacuum sequence if replace engine auto_increment unsigned zerofill cascade restrict temporary temp go using natural recursive window partition range rows preceding ';
  Kw7 = ' following unbounded true false lateral do language returns ';
  Ty1 = ' int integer smallint tinyint bigint bit decimal numeric money smallmoney float real double char varchar nchar nvarchar text ntext date time datetime datetime2 smalldatetime datetimeoffset timestamp timestamptz interval binary varbinary ';
  Ty2 = ' image uniqueidentifier xml json jsonb boolean bool serial bigserial blob longtext mediumtext enum bytea uuid ';
  Fn1 = ' count sum avg min max abs round floor ceiling ceil upper lower len length trim ltrim rtrim substring substr left right replace charindex concat isnull ifnull getdate now cast datepart dateadd datediff year month day newid row_number rank ';
  Fn2 = ' dense_rank lag lead first_value last_value nvl to_char to_date date_trunc extract string_agg group_concat ';

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

{ classe d'un mot : mot-cle, type, fonction }
Function WordClass(W : String) : LongInt;
Begin
  W := ' ' + LoStr(W) + ' ';
  If (Pos(W, Kw1) > 0) Or (Pos(W, Kw2) > 0) Or (Pos(W, Kw3) > 0) Or (Pos(W, Kw4) > 0) Or (Pos(W, Kw5) > 0) Or (Pos(W, Kw6) > 0) Or (Pos(W, Kw7) > 0) Then WordClass := kKw
  Else If (Pos(W, Ty1) > 0) Or (Pos(W, Ty2) > 0) Then WordClass := kType
  Else If (Pos(W, Fn1) > 0) Or (Pos(W, Fn2) > 0) Then WordClass := kFunc
  Else WordClass := kTxt;
End;

{ colore une ligne (LAttr si non nul) ; rend l'etat de la ligne suivante }
Function LexLine(Lang : LongInt; P : PBytes; N, St : LongInt) : LongInt;
Var I, J, C, A : LongInt; W : String;
Begin
  LxP := P; LxN := N;
  If Lang <> lgSql Then
  Begin
    LxSet(0, N, kTxt);
    LexLine := 0;
    Exit;
  End;
  I := 0;
  While I < N Do
  Begin
    C := LxC(I);
    Case St Of
      1 :
        Begin
          J := I;
          While (J < N) And Not ((LxC(J) = 42) And (LxC(J + 1) = 47)) Do Inc(J);
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
      2, 3 :
        Begin
          If St = 2 Then A := 39 Else A := 34;
          J := I;
          While J < N Do
          Begin
            If LxC(J) = A Then
            Begin
              If LxC(J + 1) = A Then Inc(J, 2)
              Else Break;
            End
            Else Inc(J);
          End;
          If St = 2 Then C := kStr Else C := kQId;
          If J < N Then
          Begin
            LxSet(I, J + 1 - I, C);
            I := J + 1;
            St := 0;
          End
          Else
          Begin
            LxSet(I, N - I, C);
            I := N;
          End;
          Continue;
        End;
      4 :
        Begin
          J := I;
          While (J < N) And Not ((LxC(J) = 36) And (LxC(J + 1) = 36)) Do Inc(J);
          If J < N Then
          Begin
            LxSet(I, J + 2 - I, kStr);
            I := J + 2;
            St := 0;
          End
          Else
          Begin
            LxSet(I, N - I, kStr);
            I := N;
          End;
          Continue;
        End;
    End;
    { code }
    If (C = 45) And (LxC(I + 1) = 45) Then
    Begin
      LxSet(I, N - I, kCmt);
      I := N;
    End
    Else If (C = 35) And (I = 0) Then
    Begin
      { commentaire # de MySQL en debut de ligne }
      LxSet(I, N - I, kCmt);
      I := N;
    End
    Else If (C = 47) And (LxC(I + 1) = 42) Then
    Begin
      LxSet(I, 2, kCmt);
      I := I + 2;
      St := 1;
    End
    Else If (C = 39) Or (((C = 78) Or (C = 110) Or (C = 69) Or (C = 101)) And (LxC(I + 1) = 39) And
            Not IsAl(LxC(I - 1))) Then
    Begin
      If C <> 39 Then
      Begin
        LxSet(I, 1, kStr);
        Inc(I);
      End;
      LxSet(I, 1, kStr);
      Inc(I);
      St := 2;
    End
    Else If C = 34 Then
    Begin
      LxSet(I, 1, kQId);
      Inc(I);
      St := 3;
    End
    Else If (C = 36) And (LxC(I + 1) = 36) Then
    Begin
      LxSet(I, 2, kStr);
      I := I + 2;
      St := 4;
    End
    Else If (C = 91) Or (C = 96) Then
    Begin
      { [identificateur] de SQL Server, `identificateur` de MySQL }
      If C = 91 Then A := 93 Else A := 96;
      J := I + 1;
      While (J < N) And (LxC(J) <> A) Do Inc(J);
      LxSet(I, J + 1 - I, kQId);
      I := J + 1;
    End
    Else If (C = 64) Or ((C = 58) And IsAl(LxC(I + 1))) Then
    Begin
      { @variable, :parametre }
      J := I + 1;
      While (J < N) And (IsAl(LxC(J)) Or IsDg(LxC(J)) Or (LxC(J) = 64)) Do Inc(J);
      LxSet(I, J - I, kVar);
      I := J;
    End
    Else If IsDg(C) Or ((C = 46) And IsDg(LxC(I + 1))) Then
    Begin
      J := I;
      If (C = 48) And ((LxC(I + 1) = 120) Or (LxC(I + 1) = 88)) Then
      Begin
        J := I + 2;
        While (J < N) And (IsDg(LxC(J)) Or ((LxC(J) Or 32) >= 97) And ((LxC(J) Or 32) <= 102)) Do Inc(J);
      End
      Else
        While (J < N) And (IsDg(LxC(J)) Or (LxC(J) = 46) Or (((LxC(J) Or 32) = 101) And IsDg(LxC(J + 1)))) Do Inc(J);
      LxSet(I, J - I, kNum);
      I := J;
    End
    Else If IsAl(C) Then
    Begin
      J := I;
      W := '';
      While (J < N) And (IsAl(LxC(J)) Or IsDg(LxC(J)) Or (LxC(J) = 36)) Do
      Begin
        If Length(W) < 40 Then W := W + Chr(LxC(J));
        Inc(J);
      End;
      { nom.colonne : pas de mot-cle apres un point }
      If LxC(I - 1) = 46 Then A := kTxt Else A := WordClass(W);
      { une fonction n'en est une que suivie d'une parenthese }
      If (A = kFunc) And (LxC(J) <> 40) Then
      Begin
        If (LoStr(W) = 'left') Or (LoStr(W) = 'right') Or (LoStr(W) = 'replace') Then A := kKw Else A := kTxt;
      End;
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
{ Serveurs, connexions, jeux de resultats et taches                     }
{ ==================================================================== }

Const
  skPg = 1; skMy = 2; skMdf = 3; skDir = 4;
  MaxSrv = 16;
  MaxRes = 8;                   { jeux de resultats d'une requete }
  MaxJob = 64;
  jbQuery = 1; jbTree = 2;
  SepCh = 31;                   { separateur des colonnes demande a SQLCMD (-s 0x1F) }

Type
  TFields = Array[0..MaxRsCol - 1] Of String;

Var
  SUsed, SSavePw : Array[0..MaxSrv - 1] Of Boolean;
  SKind, SPortN : Array[0..MaxSrv - 1] Of LongInt;
  SName, SHost, SUser, SPass, SDb, SPath : Array[0..MaxSrv - 1] Of String;
  { connexion DbC[K] : serveur et base }
  CSrv : Array[0..MaxDbConn - 1] Of LongInt;
  CDb : Array[0..MaxDbConn - 1] Of String[63];
  { taches (file d'attente, une a la fois) }
  NJob : LongInt;
  JKind, JSrv, JDoc, JNode, JTree, JConn, JPhase, JT0, JStmt, JFirst : Array[0..MaxJob - 1] Of LongInt;
  JDb : Array[0..MaxJob - 1] Of String[63];
  JSql : Array[0..MaxJob - 1] Of TBuf;
  SqlCmdExe, TmpDir, MyDir : String;

{ ==================================================================== }
{ Jeux de resultats                                                     }
{ ==================================================================== }

Function RsCell(Rs, R, C : LongInt; Var Null : Boolean) : String;
Var Pos, Ofs, N : LongInt; S : String;
Begin
  RsCell := ''; Null := True;
  If (Rs < 0) Or (Rs >= MaxRs) Then Exit;
  If Not Rss[Rs].Used Then Exit;
  If (R < 0) Or (R >= Rss[Rs].NRow) Or (C < 0) Or (C >= Rss[Rs].NCol) Then Exit;
  Pos := (R * Rss[Rs].NCol + C) * 8;
  Ofs := RsIdx(Rs, Pos); N := RsIdx(Rs, Pos + 4);
  If N < 0 Then Exit;
  Null := False;
  If N > 255 Then N := 255;
  S[0] := Chr(N);
  If N > 0 Then Move(Rss[Rs].Data.P^[Ofs], S[1], N);
  RsCell := S;
End;

Procedure RsAddStr(Rs : LongInt; S : String; Null : Boolean);
Begin
  If Null Then RsAddVal(Rs, Nil, -1)
  Else If S = '' Then RsAddVal(Rs, Nil, 0)
  Else RsAddVal(Rs, @S[1], Length(S));
End;

{ remplacer une cellule (la valeur est ajoutee a la fin des donnees) }
Procedure RsSetCell(Rs, R, C : LongInt; S : String; Null : Boolean);
Var Pos, V, N : LongInt; Q : PBytes;
Begin
  Pos := (R * Rss[Rs].NCol + C) * 8;
  V := Rss[Rs].Data.Len;
  If Null Then N := -1 Else N := Length(S);
  If N > 0 Then BufAddB(Rss[Rs].Data, @S[1], N);
  Q := Rss[Rs].Idx.P;
  Q^[Pos] := V And 255; Q^[Pos + 1] := (V Shr 8) And 255; Q^[Pos + 2] := (V Shr 16) And 255;
  Q^[Pos + 3] := (V Shr 24) And 255;
  Q^[Pos + 4] := N And 255; Q^[Pos + 5] := (N Shr 8) And 255; Q^[Pos + 6] := (N Shr 16) And 255;
  Q^[Pos + 7] := (N Shr 24) And 255;
End;

{ un jeu vide aux colonnes donnees (noms separes par |) }
Function RsMake(Cols : String) : LongInt;
Var Rs, P : LongInt;
Begin
  Rs := RsNew;
  RsMake := Rs;
  If Rs < 0 Then Exit;
  Cols := Cols + '|';
  While (Cols <> '') And (Rss[Rs].NCol < MaxRsCol) Do
  Begin
    P := Pos('|', Cols);
    RsSetCol(Rs, Rss[Rs].NCol, Copy(Cols, 1, P - 1));
    Rss[Rs].ColTy[Rss[Rs].NCol] := 0;
    Inc(Rss[Rs].NCol);
    Delete(Cols, 1, P);
  End;
End;

{ ==================================================================== }
{ Serveurs                                                              }
{ ==================================================================== }

Function SrvKindName(K : LongInt) : String;
Begin
  Case K Of
    skPg : SrvKindName := 'PostgreSQL';
    skMy : SrvKindName := 'MariaDB/MySQL';
    skMdf : SrvKindName := 'SQL Server';
    skDir : SrvKindName := 'Fichiers';
  Else
    SrvKindName := '?';
  End;
End;

{ nom affiche d'un serveur }
Function SrvLabel(S : LongInt) : String;
Begin
  If (S < 0) Or (S >= MaxSrv) Then
  Begin
    SrvLabel := '(non connect'#130')';
    Exit;
  End;
  If SName[S] <> '' Then SrvLabel := SName[S]
  Else
    Case SKind[S] Of
      skPg, skMy : SrvLabel := SHost[S] + ':' + IStr(SPortN[S]) + ' (' + SrvKindName(SKind[S]) + ' - ' + SUser[S] + ')';
      skMdf : SrvLabel := '(localdb) ' + NameOf(SPath[S]);
      skDir : SrvLabel := 'Fichiers - ' + SPath[S];
    Else
      SrvLabel := '?';
    End;
End;

Function SrvNew(Kind : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  S := -1;
  For K := MaxSrv - 1 DownTo 0 Do
    If Not SUsed[K] Then S := K;
  SrvNew := S;
  If S < 0 Then Exit;
  SUsed[S] := True; SSavePw[S] := False;
  SKind[S] := Kind; SPortN[S] := 0;
  SName[S] := ''; SHost[S] := ''; SUser[S] := ''; SPass[S] := ''; SDb[S] := ''; SPath[S] := '';
End;

{ base de donnees par defaut d'un serveur }
Function SrvDefDb(S : LongInt) : String;
Begin
  SrvDefDb := SDb[S];
  If SDb[S] = '' Then
    Case SKind[S] Of
      skPg : SrvDefDb := 'postgres';
      skMdf : SrvDefDb := NameOf(SPath[S]);
    End;
  If SKind[S] = skMdf Then
  Begin
    SrvDefDb := NameOf(SPath[S]);
    If Pos('.', NameOf(SPath[S])) > 0 Then SrvDefDb := Copy(NameOf(SPath[S]), 1, Pos('.', NameOf(SPath[S])) - 1);
  End;
End;

{ ==================================================================== }
{ Connexions aux serveurs (PostgreSQL, MariaDB)                         }
{ ==================================================================== }

{ connexion prete du serveur S sur la base Db ; -1 : aucune }
Function ConnFind(S : LongInt; Db : String) : LongInt;
Var K : LongInt;
Begin
  ConnFind := -1;
  For K := 0 To MaxDbConn - 1 Do
    If DbC[K].Used And (CSrv[K] = S) And (UpStr(CDb[K]) = UpStr(Db)) Then
    Begin
      ConnFind := K;
      Exit;
    End;
End;

{ fermer les connexions d'un serveur }
Procedure ConnCloseSrv(S : LongInt);
Var K : LongInt;
Begin
  For K := 0 To MaxDbConn - 1 Do
    If DbC[K].Used And (CSrv[K] = S) Then
    Begin
      DbClose(K);
      CSrv[K] := -1;
    End;
End;

{ ouvrir (debut de la poignee de main) ; -1 : erreur dans Err }
Function ConnOpen(S : LongInt; Db : String; Var Err : String) : LongInt;
Var K, T, Ip, Old : LongInt;
Begin
  ConnOpen := -1;
  K := -1;
  For T := 0 To MaxDbConn - 1 Do If (K < 0) And Not DbC[T].Used Then K := T;
  If K < 0 Then
  Begin
    { la plus ancienne connexion prete est fermee }
    Old := MaxLongInt;
    For T := 0 To MaxDbConn - 1 Do
      If (DbC[T].St = dsReady) And (DbC[T].LastUse < Old) Then
      Begin
        Old := DbC[T].LastUse;
        K := T;
      End;
    If K < 0 Then
    Begin
      Err := 'trop de connexions ouvertes (' + IStr(MaxDbConn) + ').';
      Exit;
    End;
    DbClose(K);
  End;
  FillChar(DbC[K], SizeOf(TDbConn), 0);
  With DbC[K] Do
  Begin
    Sock := -1; QRs := -1;
    If SKind[S] = skPg Then Kind := dbPg Else Kind := dbMy;
    Host := SHost[S]; DbPort := SPortN[S];
    User := SUser[S]; Pass := SPass[S]; Db := Db;
    BufInit(Rx);
  End;
  DbC[K].Db := Db;
  CSrv[K] := S; CDb[K] := Db;
  Ip := PResolve(SHost[S]);
  If Ip = 0 Then
  Begin
    Err := 'h'#147'te inconnu : ' + SHost[S];
    Exit;
  End;
  DbC[K].Sock := PConnect(Ip, SPortN[S]);
  If DbC[K].Sock < 0 Then
  Begin
    Err := 'connexion refus'#130'e par ' + SHost[S] + ':' + IStr(SPortN[S]) + ' (le serveur ' + SrvKindName(SKind[S]) +
           ' est-il d'#130'marr'#130' et accepte-t-il les connexions TCP ?)';
    Exit;
  End;
  DbC[K].Used := True; DbC[K].Owned := True;
  DbC[K].St := dsHandshake;
  DbC[K].Deadline := PTicks + 20000;
  If DbC[K].Kind = dbPg Then
  Begin
    If Not PgStart(K) Then
    Begin
      Err := DbC[K].Err;
      DbClose(K);
      Exit;
    End;
  End
  Else DbC[K].Phase := 1;
  ConnOpen := K;
End;

{ lancer une requete sur la connexion prete K ; faux : erreur }
Function ConnQuery(K : LongInt; Var Sql : TBuf; Var Err : String) : Boolean;
Var Rs, T : LongInt;
Begin
  ConnQuery := False;
  Rs := RsNew;
  If Rs < 0 Then
  Begin
    Err := 'trop de jeux de r'#130'sultats ouverts (fermez des onglets de requ'#136'te).';
    Exit;
  End;
  With DbC[K] Do
  Begin
    QRs := Rs; QErr := ''; QHaveT := False; Affected := 0; InsId := 0; Err := '';
    St := dsBusy;
    Deadline := PTicks + 300000;
  End;
  If DbC[K].Kind = dbPg Then T := Ord(PgQuery(K, Sql)) Else T := Ord(MyQuery(K, Sql));
  If T = 0 Then
  Begin
    Err := DbC[K].Err;
    RsFree(Rs);
    DbC[K].QRs := -1;
    DbClose(K);
    Exit;
  End;
  ConnQuery := True;
End;

{ ==================================================================== }
{ SQL Server : fichiers .MDF par SQLCMD.EXE (programme separe)           }
{ ==================================================================== }

Function JoinPath(D, N : String) : String;
Begin
  If (D <> '') And (D[Length(D)] <> '\') Then JoinPath := D + '\' + N Else JoinPath := D + N;
End;

Function FindExe(Nm : String) : String;
Begin
  FindExe := '';
  If FExists('C:\' + Nm) Then FindExe := 'C:\' + Nm
  Else If (MyDir <> '') And FExists(JoinPath(MyDir, Nm)) Then FindExe := JoinPath(MyDir, Nm);
End;

{ dossier ou l'on peut ecrire }
Function FindTemp : String;
Var T : String; H : LongInt;
Begin
  T := EnvStr('TEMP');
  If T = '' Then T := EnvStr('TMP');
  If T <> '' Then
    If FOpenWrite(JoinPath(T, 'SQLDEV.TMP'), H) Then
    Begin
      DosClose(H);
      FindTemp := T;
      Exit;
    End;
  If FOpenWrite('C:\SQLDEV.TMP', H) Then
  Begin
    DosClose(H);
    FindTemp := 'C:\';
    Exit;
  End;
  FindTemp := 'D:\';
End;

{ executer un programme et attendre ; faux : impossible de le lancer }
Function RunWait(Exe, Arg : String) : Boolean;
Var Args : Array[0..1023] Of Byte; Res : Array[0..1] Of LongInt; Fail : Array[0..259] Of Byte; P, K : LongInt;
Begin
  P := 0;
  For K := 1 To Length(Exe) Do
  Begin
    Args[P] := Ord(Exe[K]); Inc(P);
  End;
  Args[P] := 0; Inc(P);
  For K := 1 To Length(Arg) Do
  Begin
    Args[P] := Ord(Arg[K]); Inc(P);
  End;
  Args[P] := 0; Args[P + 1] := 0;
  RunWait := DosExecPgm(LongInt(@Fail), 260, 0, LongInt(@Args), 0, LongInt(@Res), Z(Exe)) = 0;
End;

{ lire un fichier texte entier }
Function ReadAll(Name : String; Var B : TBuf) : Boolean;
Var H, R : LongInt;
Begin
  ReadAll := False;
  B.Len := 0;
  If Not FOpenRead(Name, H) Then Exit;
  Repeat
    If Not BufGrow(B, 65536) Then Break;
    R := FRead(H, @B.P^[B.Len], 65536);
    If R > 0 Then B.Len := B.Len + R;
  Until R <= 0;
  DosClose(H);
  ReadAll := True;
End;

Function WriteAll(Name : String; P : PBytes; N : LongInt) : Boolean;
Var H : LongInt;
Begin
  WriteAll := False;
  If Not FOpenWrite(Name, H) Then Exit;
  WriteAll := (N = 0) Or (FWrite(H, P, N) = N);
  DosClose(H);
End;

{ ligne L (0..) d'un tampon de texte ; rend faux apres la derniere }
Var
  LnPos : LongInt;

Function NextLine(Var B : TBuf; Var S : String) : Boolean;
Var K : LongInt;
Begin
  NextLine := False;
  S := '';
  If LnPos >= B.Len Then Exit;
  K := LnPos;
  While (K < B.Len) And (B.P^[K] <> 10) Do
  Begin
    If (B.P^[K] <> 13) And (Length(S) < 255) Then S := S + Chr(B.P^[K]);
    Inc(K);
  End;
  LnPos := K + 1;
  NextLine := True;
End;

{ decoupe sur le separateur SepCh }
Function SplitSep(S : String; Var F : TFields; Max : LongInt) : LongInt;
Var N, K : LongInt;
Begin
  N := 0;
  If Max <= 0 Then
  Begin
    SplitSep := 0;
    Exit;
  End;
  F[0] := '';
  For K := 1 To Length(S) Do
    If Ord(S[K]) = SepCh Then
    Begin
      Inc(N);
      If N >= Max Then Break;
      F[N] := '';
    End
    Else F[N] := F[N] + S[K];
  SplitSep := N + 1;
End;

{ decoupe sur deux espaces ou plus (sorties de sp_tables, sp_columns) }
Function SplitWide(S : String; Var F : TFields; Max : LongInt) : LongInt;
Var N, K : LongInt; Cur : String;
Begin
  N := 0; Cur := '';
  S := Trim(S) + '  ';
  K := 1;
  While K <= Length(S) Do
  Begin
    If (S[K] = ' ') And (K < Length(S)) And (S[K + 1] = ' ') Then
    Begin
      If (Cur <> '') And (N < Max) Then
      Begin
        F[N] := Cur;
        Inc(N);
      End;
      Cur := '';
      While (K <= Length(S)) And (S[K] = ' ') Do Inc(K);
      Continue;
    End;
    Cur := Cur + S[K];
    Inc(K);
  End;
  SplitWide := N;
End;

Var
  MdfMsg : TBuf;                { messages de SQLCMD (texte) }

{ executer une instruction sur un .MDF ; rend le jeu de resultats (-1 :
  aucun) ; Err : erreur ; Rows : lignes touchees }
Function MdfRun(Mdf : String; Var Sql : TBuf; Var Err : String; Var Rows : LongInt) : LongInt;
Var Inp, Out_, L, Prev : String; B : TBuf; Rs, N, K : LongInt; F : TFields;
    InRows, Null : Boolean;
Begin
  MdfRun := -1; Err := ''; Rows := -1;
  MdfMsg.Len := 0;
  If SqlCmdExe = '' Then SqlCmdExe := FindExe('SQLCMD.EXE');
  If SqlCmdExe = '' Then
  Begin
    Err := 'SQLCMD.EXE introuvable (le clone de SQL Server d''OS/2-0).';
    Exit;
  End;
  Inp := JoinPath(TmpDir, 'SQLDEVQ.SQL');
  Out_ := JoinPath(TmpDir, 'SQLDEVR.TXT');
  If Not WriteAll(Inp, Sql.P, Sql.Len) Then
  Begin
    Err := 'impossible d'#39#130'crire ' + Inp + '.';
    Exit;
  End;
  Dummy := DosDelete(Z(Out_));
  If Not RunWait(SqlCmdExe, '-S ' + Mdf + ' -s 0x1F -W -i ' + Inp + ' -o ' + Out_) Then
  Begin
    Err := 'impossible de lancer ' + SqlCmdExe + '.';
    Exit;
  End;
  BufInit(B);
  If Not ReadAll(Out_, B) Then
  Begin
    BufFree(B);
    Err := 'SQLCMD n''a rien produit.';
    Exit;
  End;
  Rs := -1; InRows := False; Prev := '';
  LnPos := 0;
  While NextLine(B, L) Do
  Begin
    If InRows Then
    Begin
      If L = '' Then InRows := False
      Else
      Begin
        N := SplitSep(L, F, Rss[Rs].NCol);
        For K := 0 To Rss[Rs].NCol - 1 Do
          If K < N Then
          Begin
            Null := F[K] = 'NULL';
            RsAddStr(Rs, F[K], Null);
          End
          Else RsAddStr(Rs, '', True);
        Inc(Rss[Rs].NRow);
      End;
      Continue;
    End;
    { en-tete : la ligne suivante est faite de tirets et de separateurs }
    { (une seule colonne : la ligne n'a que des tirets) }
    K := 1;
    While (K <= Length(L)) And ((L[K] = '-') Or (L[K] = Chr(SepCh))) Do Inc(K);
    If (Rs < 0) And (Length(L) > 0) And (K > Length(L)) And (Prev <> '') And (Copy(Prev, 1, 1) <> '(') Then
    Begin
      Rs := RsNew;
      If Rs >= 0 Then
      Begin
        N := SplitSep(Prev, F, MaxRsCol);
        Rss[Rs].NCol := N;
        For K := 0 To N - 1 Do
        Begin
          RsSetCol(Rs, K, Trim(F[K]));
          Rss[Rs].ColTy[K] := 0;
        End;
        { la ligne d'en-tete n'est pas un message }
        If MdfMsg.Len >= Length(Prev) + 2 Then MdfMsg.Len := MdfMsg.Len - Length(Prev) - 2;
        InRows := True;
      End;
      Prev := '';
      Continue;
    End;
    If (Copy(L, 1, 1) = '(') And (Pos('affect', L) > 0) Then
    Begin
      Rows := SVal(Copy(L, 2, Pos(' ', L) - 2));
      Prev := L;
      Continue;
    End;
    If (Copy(L, 1, 10) = '-- Erreur ') Or (Copy(L, 1, 9) = '-- Erreur') Or (Pos('SQLCMD:', L) = 1) Then
    Begin
      If Err = '' Then Err := Trim(L);
      If Copy(Err, 1, 3) = '-- ' Then Delete(Err, 1, 3);
      If Copy(Err, 1, 9) = 'Erreur : ' Then Delete(Err, 1, 9);
    End
    Else If L <> '' Then
    Begin
      BufAdd(MdfMsg, L);
      BufAddC(MdfMsg, 13); BufAddC(MdfMsg, 10);
    End;
    Prev := L;
  End;
  BufFree(B);
  If (Rs >= 0) And (Rows < 0) Then Rows := Rss[Rs].NRow;
  MdfRun := Rs;
End;

{ creer un .MDF vide }
Function MdfCreate(Mdf : String; Var Err : String) : Boolean;
Begin
  MdfCreate := False;
  If SqlCmdExe = '' Then SqlCmdExe := FindExe('SQLCMD.EXE');
  If SqlCmdExe = '' Then
  Begin
    Err := 'SQLCMD.EXE introuvable.';
    Exit;
  End;
  If Not RunWait(SqlCmdExe, '--createmdf=' + Mdf) Then
  Begin
    Err := 'impossible de lancer SQLCMD.EXE.';
    Exit;
  End;
  If Not FExists(Mdf) Then
  Begin
    Err := 'SQLCMD n''a pas cr'#130#130' ' + Mdf + '.';
    Exit;
  End;
  MdfCreate := True;
End;


{ ==================================================================== }
{ Utilitaires : dossiers, UTF-8                                         }
{ ==================================================================== }

Type
  TSearchName = Record
    H, Attr, Size : LongInt;
    Name : String;
  End;

Var
  FindBf : Array[0..511] Of Byte;

Procedure FindTake(Var F : TSearchName);
Var N, K : LongInt;
Begin
  F.Attr := FindBf[24] Or (FindBf[25] Shl 8);
  F.Size := FindBf[16] Or (FindBf[17] Shl 8) Or (FindBf[18] Shl 16) Or (FindBf[19] Shl 24);
  N := FindBf[28];
  F.Name[0] := Chr(N);
  For K := 1 To N Do F.Name[K] := Chr(FindBf[28 + K]);
End;

{ premier fichier (pas les dossiers) d'un motif }
Function FindFirstName(Spec : String; Var F : TSearchName) : Boolean;
Var N : LongInt;
Begin
  F.H := -1; N := 1;
  FindFirstName := False;
  If DosFindFirst(Z(Spec), LongInt(@F.H), $27, LongInt(@FindBf), SizeOf(FindBf), LongInt(@N), 1) <> 0 Then
  Begin
    F.H := -1;
    Exit;
  End;
  FindTake(F);
  FindFirstName := True;
End;

Function FindNextName(Var F : TSearchName) : Boolean;
Var N : LongInt;
Begin
  N := 1;
  FindNextName := False;
  If F.H = -1 Then Exit;
  If DosFindNext(F.H, LongInt(@FindBf), SizeOf(FindBf), LongInt(@N)) <> 0 Then
  Begin
    Dummy := DosFindClose(F.H);
    F.H := -1;
    Exit;
  End;
  FindTake(F);
  FindNextName := True;
End;

{ UTF-8 (serveurs) -> CP850 (ecran) ; caractere absent de CP850 : ? }
Function Utf8To850(S : String) : String;
Var R : String; K, C, U : LongInt;
Begin
  R := '';
  K := 1;
  While K <= Length(S) Do
  Begin
    C := Ord(S[K]);
    If C < $80 Then
    Begin
      R := R + S[K];
      Inc(K);
    End
    Else If (C >= $C2) And (C <= $DF) And (K < Length(S)) Then
    Begin
      U := ((C And $1F) Shl 6) Or (Ord(S[K + 1]) And $3F);
      U := Uni850(U);
      If U < 0 Then R := R + '?' Else R := R + Chr(U);
      K := K + 2;
    End
    Else If (C >= $E0) And (C <= $EF) And (K + 1 < Length(S)) Then
    Begin
      U := ((C And $0F) Shl 12) Or ((Ord(S[K + 1]) And $3F) Shl 6) Or (Ord(S[K + 2]) And $3F);
      U := Uni850(U);
      If U < 0 Then R := R + '?' Else R := R + Chr(U);
      K := K + 3;
    End
    Else If C >= $F0 Then
    Begin
      R := R + '?';
      K := K + 4;
    End
    Else
    Begin
      { octet isole (pas de l'UTF-8) : garde tel quel }
      R := R + S[K];
      Inc(K);
    End;
  End;
  Utf8To850 := R;
End;

{ CP850 -> UTF-8 (texte envoye aux serveurs) }
Procedure C850ToUtf8(Var Src : TBuf; Var Dst : TBuf);
Var K, C, U : LongInt;
Begin
  Dst.Len := 0;
  For K := 0 To Src.Len - 1 Do
  Begin
    C := Src.P^[K];
    If C < 128 Then BufAddC(Dst, C)
    Else
    Begin
      U := U850[C];
      If U < $800 Then
      Begin
        BufAddC(Dst, $C0 Or (U Shr 6)); BufAddC(Dst, $80 Or (U And $3F));
      End
      Else
      Begin
        BufAddC(Dst, $E0 Or (U Shr 12)); BufAddC(Dst, $80 Or ((U Shr 6) And $3F)); BufAddC(Dst, $80 Or (U And $3F));
      End;
    End;
  End;
End;

{ ==================================================================== }
{ Decoupage d'un script en instructions                                 }
{ ==================================================================== }

Const
  MaxStmt = 200;
Var
  StN : LongInt;
  StA, StB, StLine : Array[0..MaxStmt - 1] Of LongInt;   { debut, fin (octets), ligne }

{ instructions du texte B : separees par ; (hors chaines et commentaires)
  ou par une ligne GO ; Line0 : numero de la premiere ligne }
Procedure SplitStmts(Var B : TBuf; Line0 : LongInt);
Var K, St, Q, Line, LnStart, J : LongInt; C : LongInt; W : String; Blank : Boolean;

  Procedure Add(E : LongInt);
  Var A, Z_, Q_ : LongInt;
  Begin
    A := St; Z_ := E;
    While (A < Z_) And (B.P^[A] <= 32) Do Inc(A);
    While (Z_ > A) And (B.P^[Z_ - 1] <= 32) Do Dec(Z_);
    If (Z_ > A) And (StN < MaxStmt) Then
    Begin
      StA[StN] := A; StB[StN] := Z_;
      StLine[StN] := Line0;
      For Q_ := 0 To A - 1 Do If B.P^[Q_] = 10 Then Inc(StLine[StN]);
      Inc(StN);
    End;
  End;

Begin
  StN := 0;
  St := 0; Q := 0; K := 0; Line := 0; LnStart := 0;
  While K < B.Len Do
  Begin
    C := B.P^[K];
    If Q = 1 Then
    Begin
      If (C = 42) And (K + 1 < B.Len) And (B.P^[K + 1] = 47) Then
      Begin
        Q := 0;
        Inc(K);
      End;
    End
    Else If Q = 2 Then
    Begin
      If C = 10 Then Q := 0;
    End
    Else If Q = 39 Then
    Begin
      If C = 39 Then Q := 0;
    End
    Else If Q = 34 Then
    Begin
      If C = 34 Then Q := 0;
    End
    Else If Q = 36 Then
    Begin
      If (C = 36) And (K + 1 < B.Len) And (B.P^[K + 1] = 36) Then
      Begin
        Q := 0;
        Inc(K);
      End;
    End
    Else
    Begin
      If (C = 47) And (K + 1 < B.Len) And (B.P^[K + 1] = 42) Then
      Begin
        Q := 1;
        Inc(K);
      End
      Else If (C = 45) And (K + 1 < B.Len) And (B.P^[K + 1] = 45) Then Q := 2
      Else If (C = 39) Or (C = 34) Then Q := C
      Else If (C = 36) And (K + 1 < B.Len) And (B.P^[K + 1] = 36) Then
      Begin
        Q := 36;
        Inc(K);
      End
      Else If C = 59 Then
      Begin
        Add(K);
        St := K + 1;
      End;
    End;
    If C = 10 Then
    Begin
      { ligne GO ? }
      W := '';
      Blank := True;
      For J := LnStart To K - 1 Do
        If B.P^[J] > 32 Then
        Begin
          If Length(W) < 10 Then W := W + UpCase(Chr(B.P^[J]));
        End;
      If (W = 'GO') And (Q <> 1) Then
      Begin
        Add(LnStart);
        St := K + 1;
      End;
      Inc(Line);
      LnStart := K + 1;
    End;
    Inc(K);
  End;
  W := '';
  For J := LnStart To B.Len - 1 Do If (B.P^[J] > 32) And (Length(W) < 10) Then W := W + UpCase(Chr(B.P^[J]));
  If W = 'GO' Then Add(LnStart) Else Add(B.Len);
End;
{ ==================================================================== }
{ Moteur SQL local : requetes sur les tables en fichiers                }
{   SELECT [DISTINCT] [TOP n] liste FROM table [alias] [WHERE ...]      }
{     [GROUP BY ...] [HAVING ...] [ORDER BY ... [ASC|DESC]]             }
{     [LIMIT n [OFFSET m]]                                              }
{   UPDATE table SET col = expr, ... [WHERE ...]                        }
{   DELETE FROM table [WHERE ...]          (dBASE : marque supprime)    }
{   INSERT INTO table [(cols)] VALUES (...) (dBASE et CSV)              }
{ Expressions : + - * / % ||, comparaisons, AND OR NOT, LIKE, IN,       }
{ BETWEEN, IS [NOT] NULL, CASE WHEN ; fonctions COUNT SUM AVG MIN MAX,  }
{ UPPER LOWER LEN TRIM SUBSTRING LEFT RIGHT REPLACE CONCAT COALESCE ABS }
{ ROUND FLOOR CEILING YEAR MONTH DAY CAST.                              }
{ ==================================================================== }

Const
  MaxTk = 1200;
  MaxNd = 600;
  tkEnd = 0; tkId = 1; tkNum = 2; tkStr = 3; tkOp = 4;
  ndCol = 1; ndConst = 2; ndBin = 3; ndNot = 4; ndNeg = 5; ndFunc = 6; ndIsNull = 7; ndIn = 8; ndBetween = 9;
  ndAgg = 10; ndStar = 11; ndCase = 12; ndWhen = 13;
  MaxItem = 64;
  MaxAggS = 48;

Var
  TkN, TkI : LongInt;
  TkK : Array[0..MaxTk - 1] Of Byte;
  TkO, TkLn : Array[0..MaxTk - 1] Of LongInt;
  TkTxt : TBuf;
  NdN : LongInt;
  NdK, NdA, NdB, NdC, NdNext, NdCI : Array[0..MaxNd - 1] Of LongInt;
  NdS : Array[0..MaxNd - 1] Of String[63];
  NdV : Array[0..MaxNd - 1] Of String;
  NdNull : Array[0..MaxNd - 1] Of Boolean;
  LocErr : String;
  LocT, LocR : LongInt;               { table et ligne en cours d'evaluation }
  LocDir : String;
  { agregats du groupe en cours : par noeud ndAgg }
  AgCnt : Array[0..MaxNd - 1] Of LongInt;
  AgSum : Array[0..MaxNd - 1] Of Double;
  AgHas : Array[0..MaxNd - 1] Of Boolean;
  AgSlot : Array[0..MaxNd - 1] Of LongInt;
  AgMin, AgMax : Array[0..MaxAggS - 1] Of String;
  NAgg : LongInt;
  InAgg : Boolean;                     { evaluation finale d'un groupe }
  { resultat modifiable : correspondance avec le fichier }
  LocEditT : LongInt;
  LocColMap : Array[0..MaxRsCol - 1] Of LongInt;
  LocRowMap : PLongs;
  LocRowCap : LongInt;
  LocAffected : LongInt;

{ --- lexique --- }

Function TkS(I : LongInt) : String;
Var S : String; N : LongInt;
Begin
  N := TkLn[I];
  If N > 255 Then N := 255;
  S[0] := Chr(N);
  If N > 0 Then Move(TkTxt.P^[TkO[I]], S[1], N);
  TkS := S;
End;

Procedure LexSql(Var B : TBuf; A, E : LongInt);
Var K, J, Q : LongInt; C : LongInt; S : String;

  Procedure Add(Kd : LongInt; T : String);
  Begin
    If TkN < MaxTk - 1 Then
    Begin
      TkK[TkN] := Kd;
      TkO[TkN] := TkTxt.Len; TkLn[TkN] := Length(T);
      BufAdd(TkTxt, T);
      Inc(TkN);
    End;
  End;

Begin
  TkN := 0;
  TkTxt.Len := 0;
  K := A;
  While K < E Do
  Begin
    C := B.P^[K];
    If C <= 32 Then Inc(K)
    Else If (C = 45) And (K + 1 < E) And (B.P^[K + 1] = 45) Then
    Begin
      While (K < E) And (B.P^[K] <> 10) Do Inc(K);
    End
    Else If (C = 47) And (K + 1 < E) And (B.P^[K + 1] = 42) Then
    Begin
      K := K + 2;
      While (K + 1 < E) And Not ((B.P^[K] = 42) And (B.P^[K + 1] = 47)) Do Inc(K);
      K := K + 2;
    End
    Else If (C = 39) Or (((C = 78) Or (C = 110)) And (K + 1 < E) And (B.P^[K + 1] = 39)) Then
    Begin
      If C <> 39 Then Inc(K);
      S := '';
      Inc(K);
      While K < E Do
      Begin
        If B.P^[K] = 39 Then
        Begin
          If (K + 1 < E) And (B.P^[K + 1] = 39) Then
          Begin
            If Length(S) < 255 Then S := S + '''';
            K := K + 2;
            Continue;
          End;
          Break;
        End;
        If Length(S) < 255 Then S := S + Chr(B.P^[K]);
        Inc(K);
      End;
      Inc(K);
      Add(tkStr, S);
    End
    Else If (C = 34) Or (C = 91) Or (C = 96) Then
    Begin
      If C = 91 Then Q := 93 Else Q := C;
      S := '';
      Inc(K);
      While (K < E) And (B.P^[K] <> Q) Do
      Begin
        If Length(S) < 255 Then S := S + Chr(B.P^[K]);
        Inc(K);
      End;
      Inc(K);
      Add(tkId, S);
    End
    Else If (C >= 48) And (C <= 57) Or ((C = 46) And (K + 1 < E) And (B.P^[K + 1] >= 48) And (B.P^[K + 1] <= 57)) Then
    Begin
      S := '';
      While (K < E) And (((B.P^[K] >= 48) And (B.P^[K] <= 57)) Or (B.P^[K] = 46)) Do
      Begin
        S := S + Chr(B.P^[K]);
        Inc(K);
      End;
      If (K < E) And ((B.P^[K] Or 32) = 101) Then
      Begin
        S := S + 'E';
        Inc(K);
        If (K < E) And ((B.P^[K] = 45) Or (B.P^[K] = 43)) Then
        Begin
          S := S + Chr(B.P^[K]);
          Inc(K);
        End;
        While (K < E) And (B.P^[K] >= 48) And (B.P^[K] <= 57) Do
        Begin
          S := S + Chr(B.P^[K]);
          Inc(K);
        End;
      End;
      Add(tkNum, S);
    End
    Else If ((C Or 32) >= 97) And ((C Or 32) <= 122) Or (C = 95) Or (C = 64) Or (C = 35) Or (C >= 128) Then
    Begin
      S := '';
      While (K < E) And ((((B.P^[K] Or 32) >= 97) And ((B.P^[K] Or 32) <= 122)) Or (B.P^[K] = 95) Or
            ((B.P^[K] >= 48) And (B.P^[K] <= 57)) Or (B.P^[K] = 64) Or (B.P^[K] = 35) Or (B.P^[K] = 36) Or
            (B.P^[K] >= 128)) Do
      Begin
        If Length(S) < 255 Then S := S + Chr(B.P^[K]);
        Inc(K);
      End;
      Add(tkId, S);
    End
    Else
    Begin
      S := Chr(C);
      If K + 1 < E Then
      Begin
        J := B.P^[K + 1];
        If ((C = 60) And ((J = 61) Or (J = 62))) Or ((C = 62) And (J = 61)) Or ((C = 33) And (J = 61)) Or
           ((C = 124) And (J = 124)) Then S := S + Chr(J);
      End;
      K := K + Length(S);
      Add(tkOp, S);
    End;
  End;
  TkK[TkN] := tkEnd; TkO[TkN] := 0; TkLn[TkN] := 0;
  TkI := 0;
End;

Function TkU : String;
Begin
  If TkK[TkI] = tkId Then TkU := UpStr(TkS(TkI)) Else TkU := TkS(TkI);
End;

Function IsTk(S : String) : Boolean;
Begin
  IsTk := ((TkK[TkI] = tkId) Or (TkK[TkI] = tkOp)) And (UpStr(TkS(TkI)) = S);
End;

Function Accept(S : String) : Boolean;
Begin
  Accept := False;
  If IsTk(S) Then
  Begin
    Inc(TkI);
    Accept := True;
  End;
End;

Procedure Expect(S : String);
Begin
  If Not Accept(S) Then
    If LocErr = '' Then LocErr := S + ' attendu pr'#138's de "' + TkS(TkI) + '".';
End;

Function NewNd(K : LongInt) : LongInt;
Begin
  If NdN >= MaxNd Then
  Begin
    LocErr := 'requ'#136'te trop longue.';
    NewNd := 0;
    Exit;
  End;
  NdK[NdN] := K; NdA[NdN] := -1; NdB[NdN] := -1; NdC[NdN] := -1; NdNext[NdN] := -1; NdCI[NdN] := -1;
  NdS[NdN] := ''; NdV[NdN] := ''; NdNull[NdN] := False;
  NewNd := NdN;
  Inc(NdN);
End;

{ --- analyse des expressions --- }

Function PExpr : LongInt; Forward;

Function IsAggName(S : String) : Boolean;
Begin
  IsAggName := (S = 'COUNT') Or (S = 'SUM') Or (S = 'AVG') Or (S = 'MIN') Or (S = 'MAX');
End;

Function PPrimary : LongInt;
Var N, A, Last, W : LongInt; S : String;
Begin
  PPrimary := -1;
  If LocErr <> '' Then Exit;
  Case TkK[TkI] Of
    tkNum, tkStr :
      Begin
        N := NewNd(ndConst);
        NdV[N] := TkS(TkI);
        If TkK[TkI] = tkNum Then NdS[N] := 'N';
        Inc(TkI);
        PPrimary := N;
      End;
    tkOp :
      If Accept('(') Then
      Begin
        PPrimary := PExpr;
        Expect(')');
      End
      Else If Accept('*') Then PPrimary := NewNd(ndStar)
      Else LocErr := 'expression attendue pr'#138's de "' + TkS(TkI) + '".';
    tkId :
      Begin
        S := TkU;
        If S = 'NULL' Then
        Begin
          N := NewNd(ndConst);
          NdNull[N] := True;
          Inc(TkI);
          PPrimary := N;
          Exit;
        End;
        If (S = 'TRUE') Or (S = 'FALSE') Then
        Begin
          N := NewNd(ndConst);
          If S = 'TRUE' Then NdV[N] := '1' Else NdV[N] := '0';
          NdS[N] := 'N';
          Inc(TkI);
          PPrimary := N;
          Exit;
        End;
        If S = 'CASE' Then
        Begin
          Inc(TkI);
          N := NewNd(ndCase);
          If Not IsTk('WHEN') Then NdA[N] := PExpr;
          Last := -1;
          While Accept('WHEN') Do
          Begin
            W := NewNd(ndWhen);
            NdA[W] := PExpr;
            Expect('THEN');
            NdB[W] := PExpr;
            If Last < 0 Then NdB[N] := W Else NdNext[Last] := W;
            Last := W;
          End;
          If Accept('ELSE') Then NdC[N] := PExpr;
          Expect('END');
          PPrimary := N;
          Exit;
        End;
        Inc(TkI);
        If IsTk('(') Then
        Begin
          Inc(TkI);
          If IsAggName(S) Then
          Begin
            N := NewNd(ndAgg);
            NdS[N] := S;
            If NAgg >= MaxAggS Then LocErr := 'trop de fonctions d''agr'#130'gat.';
            AgSlot[N] := NAgg;
            If NAgg < MaxAggS - 1 Then Inc(NAgg);
            If Accept('DISTINCT') Then NdV[N] := 'D';
            If Accept('*') Then NdA[N] := -1 Else NdA[N] := PExpr;
            Expect(')');
            PPrimary := N;
            Exit;
          End;
          N := NewNd(ndFunc);
          NdS[N] := S;
          Last := -1;
          If Not IsTk(')') Then
            Repeat
              A := PExpr;
              If (S = 'CAST') Or (S = 'CONVERT') Then
                If Accept('AS') Or Accept(',') Then
                Begin
                  While (TkK[TkI] <> tkEnd) And Not IsTk(')') Do Inc(TkI);
                End;
              If Last < 0 Then NdA[N] := A Else NdNext[Last] := A;
              Last := A;
            Until Not Accept(',') Or (LocErr <> '');
          Expect(')');
          PPrimary := N;
          Exit;
        End;
        { colonne, table.colonne }
        While IsTk('.') And (TkK[TkI + 1] = tkId) Do
        Begin
          Inc(TkI);
          S := TkS(TkI);
          Inc(TkI);
        End;
        If IsTk('.') And (TkS(TkI + 1) = '*') Then
        Begin
          TkI := TkI + 2;
          PPrimary := NewNd(ndStar);
          Exit;
        End;
        N := NewNd(ndCol);
        NdS[N] := Copy(TkS(TkI - 1), 1, 63);
        If UpStr(NdS[N]) <> S Then NdS[N] := Copy(S, 1, 63);
        PPrimary := N;
      End;
  Else
    LocErr := 'expression attendue.';
  End;
End;

Function PUnary : LongInt;
Var N : LongInt;
Begin
  If Accept('-') Then
  Begin
    N := NewNd(ndNeg);
    NdA[N] := PUnary;
    PUnary := N;
  End
  Else If Accept('+') Then PUnary := PUnary
  Else PUnary := PPrimary;
End;

Function PMul : LongInt;
Var A, N : LongInt; Op : String;
Begin
  A := PUnary;
  While (IsTk('*') Or IsTk('/') Or IsTk('%')) And (LocErr = '') Do
  Begin
    Op := TkS(TkI);
    Inc(TkI);
    N := NewNd(ndBin);
    NdS[N] := Op; NdA[N] := A; NdB[N] := PUnary;
    A := N;
  End;
  PMul := A;
End;

Function PAdd : LongInt;
Var A, N : LongInt; Op : String;
Begin
  A := PMul;
  While (IsTk('+') Or IsTk('-') Or IsTk('||')) And (LocErr = '') Do
  Begin
    Op := TkS(TkI);
    Inc(TkI);
    N := NewNd(ndBin);
    NdS[N] := Op; NdA[N] := A; NdB[N] := PMul;
    A := N;
  End;
  PAdd := A;
End;

Function PCmp : LongInt;
Var A, N, Last, X : LongInt; Op : String; Neg : Boolean;
Begin
  A := PAdd;
  PCmp := A;
  If LocErr <> '' Then Exit;
  If IsTk('=') Or IsTk('<>') Or IsTk('!=') Or IsTk('<') Or IsTk('>') Or IsTk('<=') Or IsTk('>=') Then
  Begin
    Op := TkS(TkI);
    If Op = '!=' Then Op := '<>';
    Inc(TkI);
    N := NewNd(ndBin);
    NdS[N] := Op; NdA[N] := A; NdB[N] := PAdd;
    PCmp := N;
    Exit;
  End;
  If Accept('IS') Then
  Begin
    N := NewNd(ndIsNull);
    NdA[N] := A;
    If Accept('NOT') Then NdS[N] := 'NOT';
    Expect('NULL');
    PCmp := N;
    Exit;
  End;
  Neg := Accept('NOT');
  If Accept('LIKE') Or Accept('ILIKE') Then
  Begin
    N := NewNd(ndBin);
    NdS[N] := 'LIKE'; NdA[N] := A; NdB[N] := PAdd;
  End
  Else If Accept('IN') Then
  Begin
    N := NewNd(ndIn);
    NdA[N] := A;
    Expect('(');
    Last := -1;
    Repeat
      X := PExpr;
      If Last < 0 Then NdB[N] := X Else NdNext[Last] := X;
      Last := X;
    Until Not Accept(',') Or (LocErr <> '');
    Expect(')');
  End
  Else If Accept('BETWEEN') Then
  Begin
    N := NewNd(ndBetween);
    NdA[N] := A; NdB[N] := PAdd;
    Expect('AND');
    NdC[N] := PAdd;
  End
  Else
  Begin
    If Neg Then LocErr := 'LIKE, IN ou BETWEEN attendu apr'#138's NOT.';
    Exit;
  End;
  If Neg Then
  Begin
    X := NewNd(ndNot);
    NdA[X] := N;
    N := X;
  End;
  PCmp := N;
End;

Function PNotE : LongInt;
Var N : LongInt;
Begin
  If Accept('NOT') Then
  Begin
    N := NewNd(ndNot);
    NdA[N] := PNotE;
    PNotE := N;
  End
  Else PNotE := PCmp;
End;

Function PAndE : LongInt;
Var A, N : LongInt;
Begin
  A := PNotE;
  While Accept('AND') And (LocErr = '') Do
  Begin
    N := NewNd(ndBin);
    NdS[N] := 'AND'; NdA[N] := A; NdB[N] := PNotE;
    A := N;
  End;
  PAndE := A;
End;

Function PExpr : LongInt;
Var A, N : LongInt;
Begin
  A := PAndE;
  While Accept('OR') And (LocErr = '') Do
  Begin
    N := NewNd(ndBin);
    NdS[N] := 'OR'; NdA[N] := A; NdB[N] := PAndE;
    A := N;
  End;
  PExpr := A;
End;

{ --- valeurs --- }

Function IsNumStr(S : String; Var V : Double) : Boolean;
Var E : LongInt;
Begin
  IsNumStr := False;
  S := Trim(S);
  If S = '' Then Exit;
  Val(S, V, E);
  IsNumStr := E = 0;
End;

Function NumStr(V : Double) : String;
Var S : String; L : LongInt;
Begin
  If (V = Int(V)) And (Abs(V) < 1E15) Then Str(V : 0 : 0, S)
  Else
  Begin
    Str(V : 0 : 6, S);
    While (Length(S) > 0) And (S[Length(S)] = '0') Do Delete(S, Length(S), 1);
    If (Length(S) > 0) And (S[Length(S)] = '.') Then Delete(S, Length(S), 1);
  End;
  L := 0;
  NumStr := S;
End;

{ comparaison : nombres entre eux, sinon textes sans egard a la casse }
Function CmpVal(A : String; ANull : Boolean; B : String; BNull : Boolean) : LongInt;
Var X, Y : Double;
Begin
  If ANull Or BNull Then
  Begin
    If ANull And BNull Then CmpVal := 0 Else If ANull Then CmpVal := -1 Else CmpVal := 1;
    Exit;
  End;
  If IsNumStr(A, X) And IsNumStr(B, Y) Then
  Begin
    If X < Y Then CmpVal := -1 Else If X > Y Then CmpVal := 1 Else CmpVal := 0;
    Exit;
  End;
  A := UpStr(A); B := UpStr(B);
  If A < B Then CmpVal := -1 Else If A > B Then CmpVal := 1 Else CmpVal := 0;
End;

{ LIKE : % et _ }
Function LikeM(S, P : String) : Boolean;
Var I, J, Si, Pi : LongInt;
Begin
  S := UpStr(S); P := UpStr(P);
  I := 1; J := 1; Si := -1; Pi := -1;
  While I <= Length(S) Do
  Begin
    If (J <= Length(P)) And ((P[J] = '_') Or (P[J] = S[I])) Then
    Begin
      Inc(I); Inc(J);
    End
    Else If (J <= Length(P)) And (P[J] = '%') Then
    Begin
      Pi := J; Si := I;
      Inc(J);
    End
    Else If Pi > 0 Then
    Begin
      J := Pi + 1;
      Inc(Si);
      I := Si;
    End
    Else
    Begin
      LikeM := False;
      Exit;
    End;
  End;
  While (J <= Length(P)) And (P[J] = '%') Do Inc(J);
  LikeM := J > Length(P);
End;

Function Truth(S : String; Null : Boolean) : Boolean;
Var V : Double;
Begin
  If Null Then Truth := False
  Else If IsNumStr(S, V) Then Truth := V <> 0
  Else Truth := (S <> '') And (UpStr(S) <> 'FALSE');
End;

{ colonne d'un noeud ndCol dans la table LocT }
Function ColOf(N : LongInt) : LongInt;
Var K : LongInt; S : String;
Begin
  If NdCI[N] >= 0 Then
  Begin
    ColOf := NdCI[N];
    Exit;
  End;
  ColOf := -1;
  If LocT < 0 Then Exit;
  S := UpStr(NdS[N]);
  For K := 0 To FT[LocT].NCol - 1 Do
    If UpStr(FtColName(LocT, K)) = S Then
    Begin
      NdCI[N] := K;
      ColOf := K;
      Exit;
    End;
End;

Function TodayStr : String; Forward;

Procedure Eval(N : LongInt; Var V : String; Var Null : Boolean);
Var A, B : String; An, Bn : Boolean; X, Y : Double; C, K, M : LongInt; Fn : String; Ok : Boolean;
    Args : Array[0..3] Of String; ArgN : Array[0..3] Of Boolean;
Begin
  V := ''; Null := False;
  If (N < 0) Or (LocErr <> '') Then
  Begin
    Null := True;
    Exit;
  End;
  Case NdK[N] Of
    ndConst :
      Begin
        V := NdV[N]; Null := NdNull[N];
      End;
    ndCol :
      Begin
        C := ColOf(N);
        If C < 0 Then
        Begin
          LocErr := 'colonne inconnue : ' + NdS[N];
          Null := True;
          Exit;
        End;
        V := FtCell(LocT, LocR, C, Null);
      End;
    ndAgg :
      Begin
        If Not InAgg Then
        Begin
          Null := True;
          Exit;
        End;
        Fn := NdS[N];
        If Fn = 'COUNT' Then V := IStr(AgCnt[N])
        Else If Not AgHas[N] Then Null := True
        Else If Fn = 'SUM' Then V := NumStr(AgSum[N])
        Else If Fn = 'AVG' Then V := NumStr(AgSum[N] / AgCnt[N])
        Else If Fn = 'MIN' Then V := AgMin[AgSlot[N]]
        Else V := AgMax[AgSlot[N]];
      End;
    ndNeg :
      Begin
        Eval(NdA[N], A, An);
        If An Then Null := True
        Else If IsNumStr(A, X) Then V := NumStr(-X)
        Else Null := True;
      End;
    ndNot :
      Begin
        Eval(NdA[N], A, An);
        If An Then Null := True Else If Truth(A, False) Then V := '0' Else V := '1';
      End;
    ndIsNull :
      Begin
        Eval(NdA[N], A, An);
        If NdS[N] = 'NOT' Then An := Not An;
        If An Then V := '1' Else V := '0';
      End;
    ndIn :
      Begin
        Eval(NdA[N], A, An);
        If An Then
        Begin
          Null := True;
          Exit;
        End;
        V := '0';
        K := NdB[N];
        While K >= 0 Do
        Begin
          Eval(K, B, Bn);
          If CmpVal(A, An, B, Bn) = 0 Then V := '1';
          K := NdNext[K];
        End;
      End;
    ndBetween :
      Begin
        Eval(NdA[N], A, An);
        Eval(NdB[N], B, Bn);
        If An Or Bn Then
        Begin
          Null := True;
          Exit;
        End;
        If CmpVal(A, False, B, False) < 0 Then V := '0'
        Else
        Begin
          Eval(NdC[N], B, Bn);
          If Bn Then Null := True Else If CmpVal(A, False, B, False) > 0 Then V := '0' Else V := '1';
        End;
      End;
    ndCase :
      Begin
        If NdA[N] >= 0 Then Eval(NdA[N], A, An);
        K := NdB[N];
        While K >= 0 Do
        Begin
          Eval(NdA[K], B, Bn);
          If NdA[N] >= 0 Then Ok := CmpVal(A, An, B, Bn) = 0 Else Ok := Truth(B, Bn);
          If Ok Then
          Begin
            Eval(NdB[K], V, Null);
            Exit;
          End;
          K := NdNext[K];
        End;
        If NdC[N] >= 0 Then Eval(NdC[N], V, Null) Else Null := True;
      End;
    ndBin :
      Begin
        Fn := NdS[N];
        Eval(NdA[N], A, An);
        If Fn = 'AND' Then
        Begin
          If Not An And Not Truth(A, False) Then
          Begin
            V := '0';
            Exit;
          End;
          Eval(NdB[N], B, Bn);
          If Not Bn And Not Truth(B, False) Then V := '0'
          Else If An Or Bn Then Null := True
          Else V := '1';
          Exit;
        End;
        If Fn = 'OR' Then
        Begin
          If Not An And Truth(A, False) Then
          Begin
            V := '1';
            Exit;
          End;
          Eval(NdB[N], B, Bn);
          If Not Bn And Truth(B, False) Then V := '1'
          Else If An Or Bn Then Null := True
          Else V := '0';
          Exit;
        End;
        Eval(NdB[N], B, Bn);
        If An Or Bn Then
        Begin
          Null := True;
          Exit;
        End;
        If Fn = '||' Then V := A + B
        Else If Fn = 'LIKE' Then
        Begin
          If LikeM(A, B) Then V := '1' Else V := '0';
        End
        Else If (Fn = '=') Or (Fn = '<>') Or (Fn = '<') Or (Fn = '>') Or (Fn = '<=') Or (Fn = '>=') Then
        Begin
          C := CmpVal(A, False, B, False);
          If Fn = '=' Then Ok := C = 0
          Else If Fn = '<>' Then Ok := C <> 0
          Else If Fn = '<' Then Ok := C < 0
          Else If Fn = '>' Then Ok := C > 0
          Else If Fn = '<=' Then Ok := C <= 0
          Else Ok := C >= 0;
          If Ok Then V := '1' Else V := '0';
        End
        Else If IsNumStr(A, X) And IsNumStr(B, Y) Then
        Begin
          If Fn = '+' Then V := NumStr(X + Y)
          Else If Fn = '-' Then V := NumStr(X - Y)
          Else If Fn = '*' Then V := NumStr(X * Y)
          Else If Y = 0 Then
          Begin
            LocErr := 'division par z'#130'ro.';
            Null := True;
          End
          Else If Fn = '/' Then V := NumStr(X / Y)
          Else V := NumStr(X - Int(X / Y) * Y);
        End
        Else If Fn = '+' Then V := A + B
        Else Null := True;
      End;
    ndFunc :
      Begin
        Fn := NdS[N];
        K := NdA[N]; M := 0;
        While (K >= 0) And (M < 4) Do
        Begin
          Eval(K, Args[M], ArgN[M]);
          Inc(M);
          K := NdNext[K];
        End;
        If (Fn = 'COALESCE') Or (Fn = 'ISNULL') Or (Fn = 'IFNULL') Or (Fn = 'NVL') Then
        Begin
          Null := True;
          For K := 0 To M - 1 Do
            If Null And Not ArgN[K] Then
            Begin
              V := Args[K]; Null := False;
            End;
          Exit;
        End;
        If (Fn = 'CONCAT') Then
        Begin
          For K := 0 To M - 1 Do If Not ArgN[K] Then V := V + Args[K];
          Exit;
        End;
        If (Fn = 'GETDATE') Or (Fn = 'NOW') Or (Fn = 'CURRENT_DATE') Then
        Begin
          V := TodayStr;
          Exit;
        End;
        If (M > 0) And ArgN[0] Then
        Begin
          Null := True;
          Exit;
        End;
        If M = 0 Then
        Begin
          LocErr := 'fonction ' + Fn + ' : argument attendu.';
          Exit;
        End;
        A := Args[0];
        If (Fn = 'UPPER') Or (Fn = 'UCASE') Then V := UpStr(A)
        Else If (Fn = 'LOWER') Or (Fn = 'LCASE') Then V := LoStr(A)
        Else If (Fn = 'LEN') Or (Fn = 'LENGTH') Or (Fn = 'CHAR_LENGTH') Then V := IStr(Length(A))
        Else If Fn = 'TRIM' Then V := Trim(A)
        Else If Fn = 'LTRIM' Then
        Begin
          While (A <> '') And (A[1] = ' ') Do Delete(A, 1, 1);
          V := A;
        End
        Else If Fn = 'RTRIM' Then
        Begin
          While (A <> '') And (A[Length(A)] = ' ') Do Delete(A, Length(A), 1);
          V := A;
        End
        Else If (Fn = 'SUBSTRING') Or (Fn = 'SUBSTR') Or (Fn = 'MID') Then
        Begin
          If M >= 3 Then V := Copy(A, SVal(Args[1]), SVal(Args[2])) Else If M = 2 Then V := Copy(A, SVal(Args[1]), 255)
          Else V := A;
        End
        Else If Fn = 'LEFT' Then V := Copy(A, 1, SVal(Args[1]))
        Else If Fn = 'RIGHT' Then
        Begin
          C := SVal(Args[1]);
          If C >= Length(A) Then V := A Else V := Copy(A, Length(A) - C + 1, C);
        End
        Else If Fn = 'REPLACE' Then
        Begin
          V := '';
          If (M < 3) Or (Args[1] = '') Then V := A
          Else
          Begin
            K := Pos(Args[1], A);
            While K > 0 Do
            Begin
              V := V + Copy(A, 1, K - 1) + Args[2];
              Delete(A, 1, K - 1 + Length(Args[1]));
              K := Pos(Args[1], A);
            End;
            V := V + A;
          End;
        End
        Else If (Fn = 'ABS') Or (Fn = 'ROUND') Or (Fn = 'FLOOR') Or (Fn = 'CEILING') Or (Fn = 'CEIL') Then
        Begin
          If Not IsNumStr(A, X) Then
          Begin
            Null := True;
            Exit;
          End;
          If Fn = 'ABS' Then V := NumStr(Abs(X))
          Else If Fn = 'FLOOR' Then
          Begin
            Y := Int(X);
            If Y > X Then Y := Y - 1;
            V := NumStr(Y);
          End
          Else If Fn = 'ROUND' Then
          Begin
            C := 0;
            If M >= 2 Then C := SVal(Args[1]);
            Y := 1;
            For K := 1 To C Do Y := Y * 10;
            If X >= 0 Then V := NumStr(Int(X * Y + 0.5) / Y) Else V := NumStr(-Int(-X * Y + 0.5) / Y);
          End
          Else
          Begin
            Y := Int(X);
            If Y < X Then Y := Y + 1;
            V := NumStr(Y);
          End;
        End
        Else If (Fn = 'YEAR') Or (Fn = 'MONTH') Or (Fn = 'DAY') Then
        Begin
          { AAAA-MM-JJ }
          If Fn = 'YEAR' Then V := IStr(SVal(Copy(A, 1, 4)))
          Else If Fn = 'MONTH' Then V := IStr(SVal(Copy(A, 6, 2)))
          Else V := IStr(SVal(Copy(A, 9, 2)));
        End
        Else If (Fn = 'CAST') Or (Fn = 'CONVERT') Or (Fn = 'STR') Then V := A
        Else LocErr := 'fonction inconnue du moteur local : ' + Fn + '.';
      End;
    ndStar : V := '*';
  End;
End;

{ accumuler les agregats de l'arbre N pour la ligne en cours }
Procedure AggAcc(N : LongInt);
Var V : String; Null : Boolean; X : Double; K : LongInt;
Begin
  If N < 0 Then Exit;
  If NdK[N] = ndAgg Then
  Begin
    If NdA[N] < 0 Then
    Begin
      Inc(AgCnt[N]);
      Exit;
    End;
    Eval(NdA[N], V, Null);
    If Null Then Exit;
    Inc(AgCnt[N]);
    If IsNumStr(V, X) Then AgSum[N] := AgSum[N] + X;
    If Not AgHas[N] Then
    Begin
      AgMin[AgSlot[N]] := V; AgMax[AgSlot[N]] := V; AgHas[N] := True;
    End
    Else
    Begin
      If CmpVal(V, False, AgMin[AgSlot[N]], False) < 0 Then AgMin[AgSlot[N]] := V;
      If CmpVal(V, False, AgMax[AgSlot[N]], False) > 0 Then AgMax[AgSlot[N]] := V;
    End;
    Exit;
  End;
  AggAcc(NdA[N]); AggAcc(NdB[N]); AggAcc(NdC[N]);
  If (NdK[N] = ndFunc) Or (NdK[N] = ndIn) Or (NdK[N] = ndCase) Then
  Begin
    If NdK[N] = ndCase Then K := NdB[N] Else K := NdA[N];
    If NdK[N] = ndIn Then K := NdB[N];
    While K >= 0 Do
    Begin
      If NdK[N] <> ndCase Then AggAcc(K)
      Else
      Begin
        AggAcc(NdA[K]); AggAcc(NdB[K]);
      End;
      K := NdNext[K];
    End;
  End;
End;

Procedure AggReset;
Var K : LongInt;
Begin
  For K := 0 To NdN - 1 Do
    If NdK[K] = ndAgg Then
    Begin
      AgCnt[K] := 0; AgSum[K] := 0; AgHas[K] := False;
    End;
End;

Function HasAgg(N : LongInt) : Boolean;
Var K : LongInt;
Begin
  HasAgg := False;
  If N < 0 Then Exit;
  If NdK[N] = ndAgg Then
  Begin
    HasAgg := True;
    Exit;
  End;
  If HasAgg(NdA[N]) Or HasAgg(NdB[N]) Or HasAgg(NdC[N]) Then
  Begin
    HasAgg := True;
    Exit;
  End;
  If (NdK[N] = ndFunc) Or (NdK[N] = ndCase) Or (NdK[N] = ndIn) Then
  Begin
    If NdK[N] = ndFunc Then K := NdA[N] Else K := NdB[N];
    While K >= 0 Do
    Begin
      If HasAgg(K) Then
      Begin
        HasAgg := True;
        Exit;
      End;
      K := NdNext[K];
    End;
  End;
End;

{ texte d'une expression (nom de colonne par defaut) }
Function NdText(N : LongInt) : String;
Begin
  NdText := '(Aucun nom de colonne)';
  If N < 0 Then Exit;
  Case NdK[N] Of
    ndCol : NdText := NdS[N];
    ndAgg : NdText := '(Aucun nom de colonne)';
  End;
End;

{ ==================================================================== }
{ Tables : resolution d'un nom                                          }
{ ==================================================================== }

{ fichier d'une table : nom.ext, chemin, ou nom (extension cherchee) }
Function TablePath(Nm : String) : String;
Var P : String; K : LongInt;
Const Ex : Array[0..4] Of String[3] = ('DBF', 'CSV', 'DAT', 'MYD', 'TXT');
Begin
  TablePath := '';
  If Nm = '' Then Exit;
  If (Length(Nm) > 1) And (Nm[2] = ':') Then P := Nm Else P := JoinPath(LocDir, Nm);
  If ExtOf(Nm) <> '' Then
  Begin
    If FExists(P) Then TablePath := P;
    Exit;
  End;
  For K := 0 To 4 Do
    If FExists(P + '.' + Ex[K]) Then
    Begin
      TablePath := P + '.' + Ex[K];
      Exit;
    End;
End;

{ nom de table au jeton courant (nom, nom.ext, 'chemin') ; ouvre la table }
Function ParseTable : LongInt;
Var Nm, P : String; T : LongInt;
Begin
  ParseTable := -1;
  If (TkK[TkI] <> tkId) And (TkK[TkI] <> tkStr) Then
  Begin
    LocErr := 'nom de table attendu.';
    Exit;
  End;
  Nm := TkS(TkI);
  Inc(TkI);
  { schema.table : le schema est ignore ; table.ext : extension }
  While IsTk('.') And ((TkK[TkI + 1] = tkId) Or (TkK[TkI + 1] = tkNum)) Do
  Begin
    If FmtOfExt(UpStr(TkS(TkI + 1))) <> ftNone Then Nm := Nm + '.' + TkS(TkI + 1)
    Else If (UpStr(Nm) = 'DBO') Or (UpStr(Nm) = 'PUBLIC') Then Nm := TkS(TkI + 1)
    Else Nm := TkS(TkI + 1);
    TkI := TkI + 2;
  End;
  P := TablePath(Nm);
  If P = '' Then
  Begin
    LocErr := 'table introuvable : ' + Nm + ' (dans ' + LocDir + ').';
    Exit;
  End;
  T := FtOpen(P);
  If T < 0 Then
  Begin
    LocErr := FtErr;
    Exit;
  End;
  { alias }
  If Accept('AS') Then Inc(TkI)
  Else If (TkK[TkI] = tkId) And Not IsTk('WHERE') And Not IsTk('ORDER') And Not IsTk('GROUP') And
          Not IsTk('LIMIT') And Not IsTk('SET') And Not IsTk('HAVING') And Not IsTk('VALUES') Then Inc(TkI);
  ParseTable := T;
End;

Function TodayStr : String;
Var Dt : Array[0..11] Of Byte;
Begin
  FillChar(Dt, 12, 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  TodayStr := IStr(Dt[6] Or (Dt[7] Shl 8)) + '-' + Z2D(Dt[5]) + '-' + Z2D(Dt[4]) + ' ' + Z2D(Dt[0]) + ':' +
              Z2D(Dt[1]) + ':' + Z2D(Dt[2]);
End;

{ ==================================================================== }
{ Execution                                                             }
{ ==================================================================== }

Var
  ItN : LongInt;
  ItE : Array[0..MaxItem - 1] Of LongInt;      { expression }
  ItName : Array[0..MaxItem - 1] Of String[63];
  ObN : LongInt;
  ObE, ObOut : Array[0..15] Of LongInt;        { expression, ou colonne du resultat }
  ObDesc : Array[0..15] Of Boolean;
  GbN : LongInt;
  GbE : Array[0..15] Of LongInt;

{ tri par fusion d'une permutation (cles en chaines dans KB, KOfs) }
Var
  SortKeys : TBuf;
  SortOfs : PLongs;
  SortNK : LongInt;
  SortDesc : Boolean;

Function KeyStr(R, I : LongInt; Var Null : Boolean) : String;
Var P, N : LongInt; S : String;
Begin
  P := SortOfs^[R * SortNK + I];
  N := SortKeys.P^[P];
  Null := N = 255;
  If Null Then N := 0;
  S[0] := Chr(N);
  If N > 0 Then Move(SortKeys.P^[P + 1], S[1], N);
  KeyStr := S;
End;

Procedure KeyAdd(S : String; Null : Boolean; Var Slot : LongInt);
Begin
  If Length(S) > 254 Then S := Copy(S, 1, 254);
  Slot := SortKeys.Len;
  If Null Then BufAddC(SortKeys, 255)
  Else
  Begin
    BufAddC(SortKeys, Length(S));
    BufAdd(SortKeys, S);
  End;
End;

Function KeyCmp(A, B : LongInt) : LongInt;
Var I, C : LongInt; Sa, Sb : String; Na, Nb : Boolean;
Begin
  KeyCmp := 0;
  For I := 0 To SortNK - 1 Do
  Begin
    Sa := KeyStr(A, I, Na); Sb := KeyStr(B, I, Nb);
    C := CmpVal(Sa, Na, Sb, Nb);
    If SortDesc And (I < ObN) And ObDesc[I] Then C := -C;
    If C <> 0 Then
    Begin
      KeyCmp := C;
      Exit;
    End;
  End;
End;

Procedure MSort(P, Tmp : PLongs; N : LongInt);
Var W, L, M, R, I, J, K : LongInt;
Begin
  W := 1;
  While W < N Do
  Begin
    L := 0;
    While L < N Do
    Begin
      M := MinI(L + W, N); R := MinI(L + 2 * W, N);
      I := L; J := M; K := L;
      While (I < M) And (J < R) Do
        If KeyCmp(P^[I], P^[J]) <= 0 Then
        Begin
          Tmp^[K] := P^[I]; Inc(I); Inc(K);
        End
        Else
        Begin
          Tmp^[K] := P^[J]; Inc(J); Inc(K);
        End;
      While I < M Do
      Begin
        Tmp^[K] := P^[I]; Inc(I); Inc(K);
      End;
      While J < R Do
      Begin
        Tmp^[K] := P^[J]; Inc(J); Inc(K);
      End;
      L := R;
    End;
    For I := 0 To N - 1 Do P^[I] := Tmp^[I];
    W := W * 2;
  End;
End;

Procedure RowMapAdd(R, V : LongInt);
Var Q : PLongs; NC : LongInt;
Begin
  If R >= LocRowCap Then
  Begin
    NC := LocRowCap * 2;
    If NC < 1024 Then NC := 1024;
    GetMem(Q, NC * 4);
    If LocRowCap > 0 Then
    Begin
      Move(LocRowMap^[0], Q^[0], LocRowCap * 4);
      FreeMem(LocRowMap, LocRowCap * 4);
    End;
    LocRowMap := Q; LocRowCap := NC;
  End;
  LocRowMap^[R] := V;
End;

{ SELECT ; rend le jeu de resultats }
Function LocSelect : LongInt;
Var T, Rs, R, I, J, K, N, N2, Top, Off, Lim, WhereE, HavingE, Rows, Out_, NK, Slot, Grp, OutRs : LongInt;
    Distinct, Agg, Simple, Null, Same : Boolean; V : String;
    Perm, Tmp, Src : PLongs; NSrc, First, AllocN : LongInt;
Begin
  LocSelect := -1;
  T := -1; Top := -1; Off := 0; Lim := -1; WhereE := -1; HavingE := -1;
  ItN := 0; ObN := 0; GbN := 0;
  Expect('SELECT');
  Distinct := Accept('DISTINCT');
  If Accept('ALL') Then ;
  If Accept('TOP') Then
  Begin
    If Accept('(') Then
    Begin
      Top := SVal(TkS(TkI)); Inc(TkI);
      Expect(')');
    End
    Else
    Begin
      Top := SVal(TkS(TkI)); Inc(TkI);
    End;
  End;
  { liste }
  Repeat
    If ItN >= MaxItem Then
    Begin
      LocErr := 'trop de colonnes demand'#130'es.';
      Exit;
    End;
    ItE[ItN] := PExpr;
    ItName[ItN] := '';
    If Accept('AS') Then
    Begin
      ItName[ItN] := Copy(TkS(TkI), 1, 63);
      Inc(TkI);
    End
    Else If ((TkK[TkI] = tkId) Or (TkK[TkI] = tkStr)) And Not IsTk('FROM') And Not IsTk(',') Then
    Begin
      ItName[ItN] := Copy(TkS(TkI), 1, 63);
      Inc(TkI);
    End;
    Inc(ItN);
  Until Not Accept(',') Or (LocErr <> '');
  If LocErr <> '' Then Exit;
  If Accept('FROM') Then
  Begin
    T := ParseTable;
    If LocErr <> '' Then Exit;
  End;
  LocT := T;
  If Accept('WHERE') Then WhereE := PExpr;
  If Accept('GROUP') Then
  Begin
    Expect('BY');
    Repeat
      If GbN < 16 Then
      Begin
        GbE[GbN] := PExpr;
        Inc(GbN);
      End;
    Until Not Accept(',') Or (LocErr <> '');
  End;
  If Accept('HAVING') Then HavingE := PExpr;
  If Accept('ORDER') Then
  Begin
    Expect('BY');
    Repeat
      If ObN < 16 Then
      Begin
        ObOut[ObN] := -1;
        If (TkK[TkI] = tkNum) And ((TkK[TkI + 1] = tkEnd) Or (TkS(TkI + 1) = ',') Or (UpStr(TkS(TkI + 1)) = 'ASC') Or
           (UpStr(TkS(TkI + 1)) = 'DESC') Or (UpStr(TkS(TkI + 1)) = 'LIMIT') Or (UpStr(TkS(TkI + 1)) = 'OFFSET')) Then
        Begin
          ObOut[ObN] := SVal(TkS(TkI)) - 1;
          ObE[ObN] := -1;
          Inc(TkI);
        End
        Else ObE[ObN] := PExpr;
        ObDesc[ObN] := False;
        If Accept('DESC') Then ObDesc[ObN] := True Else If Accept('ASC') Then ;
        Inc(ObN);
      End;
    Until Not Accept(',') Or (LocErr <> '');
  End;
  If Accept('LIMIT') Then
  Begin
    Lim := SVal(TkS(TkI)); Inc(TkI);
    If Accept(',') Then
    Begin
      Off := Lim;
      Lim := SVal(TkS(TkI)); Inc(TkI);
    End;
  End;
  If Accept('OFFSET') Then
  Begin
    Off := SVal(TkS(TkI)); Inc(TkI);
    If Accept('ROWS') Or Accept('ROW') Then ;
  End;
  If Accept('FETCH') Then
  Begin
    If Accept('FIRST') Or Accept('NEXT') Then ;
    Lim := SVal(TkS(TkI)); Inc(TkI);
    While (TkK[TkI] <> tkEnd) Do Inc(TkI);
  End;
  If LocErr <> '' Then Exit;
  If (TkK[TkI] <> tkEnd) And Not IsTk(';') Then
  Begin
    LocErr := 'texte inattendu : "' + TkS(TkI) + '".';
    Exit;
  End;
  If Top >= 0 Then Lim := Top;
  { colonnes du resultat : * devient toutes les colonnes de la table }
  Agg := GbN > 0;
  For I := 0 To ItN - 1 Do If HasAgg(ItE[I]) Then Agg := True;
  If HavingE >= 0 Then Agg := True;
  Simple := (T >= 0) And Not Agg And Not Distinct;
  Rs := RsNew;
  If Rs < 0 Then
  Begin
    LocErr := 'trop de jeux de r'#130'sultats.';
    Exit;
  End;
  Out_ := 0;
  For I := 0 To ItN - 1 Do
    If NdK[ItE[I]] = ndStar Then
    Begin
      If T < 0 Then
      Begin
        LocErr := 'SELECT * sans FROM.';
        RsFree(Rs);
        Exit;
      End;
      For K := 0 To FT[T].NCol - 1 Do
        If Out_ < MaxRsCol Then
        Begin
          RsSetCol(Rs, Out_, FtColName(T, K));
          LocColMap[Out_] := K;
          Inc(Out_);
        End;
    End
    Else If Out_ < MaxRsCol Then
    Begin
      If ItName[I] <> '' Then RsSetCol(Rs, Out_, ItName[I]) Else RsSetCol(Rs, Out_, NdText(ItE[I]));
      LocColMap[Out_] := -1;
      If NdK[ItE[I]] = ndCol Then
      Begin
        LocColMap[Out_] := ColOf(ItE[I]);
        If (LocColMap[Out_] >= 0) And (ItName[I] = '') Then RsSetCol(Rs, Out_, FtColName(T, LocColMap[Out_]));
      End
      Else Simple := False;
      Inc(Out_);
    End;
  Rss[Rs].NCol := Out_;
  For I := 0 To Out_ - 1 Do Rss[Rs].ColTy[I] := 0;
  { ORDER BY : alias ou nom d'une colonne du resultat }
  For I := 0 To ObN - 1 Do
    If (ObOut[I] < 0) And (ObE[I] >= 0) And (NdK[ObE[I]] = ndCol) Then
      For K := Out_ - 1 DownTo 0 Do
        If UpStr(RsColName(Rs, K)) = UpStr(NdS[ObE[I]]) Then ObOut[I] := K;
  { lignes sources retenues }
  NSrc := 0;
  If T >= 0 Then
  Begin
    N := FT[T].RecordCount;
    First := FtFirst(T);
  End
  Else
  Begin
    N := 1; First := 0;
  End;
  GetMem(Src, MaxI(1, N) * 4);
  For R := First To N - 1 Do
  Begin
    LocR := R;
    If T >= 0 Then
      If FtDeleted(T, R) Then Continue;
    If WhereE >= 0 Then
    Begin
      Eval(WhereE, V, Null);
      If LocErr <> '' Then Break;
      If Not Truth(V, Null) Then Continue;
    End;
    Src^[NSrc] := R;
    Inc(NSrc);
  End;
  If LocErr <> '' Then
  Begin
    FreeMem(Src, MaxI(1, N) * 4);
    RsFree(Rs);
    Exit;
  End;
  { regroupement : tri des lignes par cle de groupe }
  BufInit(SortKeys);
  If Agg Then
  Begin
    SortNK := GbN;
    GetMem(SortOfs, MaxI(1, NSrc * MaxI(1, GbN)) * 4);
    For I := 0 To NSrc - 1 Do
    Begin
      LocR := Src^[I];
      For J := 0 To GbN - 1 Do
      Begin
        Eval(GbE[J], V, Null);
        KeyAdd(V, Null, Slot);
        SortOfs^[I * GbN + J] := Slot;
      End;
    End;
    GetMem(Perm, MaxI(1, NSrc) * 4); GetMem(Tmp, MaxI(1, NSrc) * 4);
    For I := 0 To NSrc - 1 Do Perm^[I] := I;
    SortDesc := False;
    If GbN > 0 Then MSort(Perm, Tmp, NSrc);
    { un groupe par cle (sans GROUP BY : un seul groupe) }
    I := 0;
    Rows := 0;
    While (I < NSrc) Or ((NSrc = 0) And (GbN = 0) And (Rows = 0)) Do
    Begin
      AggReset;
      Grp := I;
      J := I;
      If NSrc > 0 Then
        Repeat
          LocR := Src^[Perm^[J]];
          InAgg := False;
          For K := 0 To ItN - 1 Do AggAcc(ItE[K]);
          If HavingE >= 0 Then AggAcc(HavingE);
          For K := 0 To ObN - 1 Do If ObE[K] >= 0 Then AggAcc(ObE[K]);
          Inc(J);
          Same := False;
          If (J < NSrc) And (GbN > 0) Then Same := KeyCmp(Perm^[J], Perm^[Grp]) = 0
          Else If (J < NSrc) And (GbN = 0) Then Same := True;
        Until Not Same;
      { ligne du groupe : la premiere ligne source pour les colonnes simples }
      If NSrc > 0 Then LocR := Src^[Perm^[Grp]];
      InAgg := True;
      If HavingE >= 0 Then
      Begin
        Eval(HavingE, V, Null);
        If Not Truth(V, Null) Then
        Begin
          InAgg := False;
          I := J;
          If NSrc = 0 Then Rows := 1;
          Continue;
        End;
      End;
      For K := 0 To ItN - 1 Do
      Begin
        Eval(ItE[K], V, Null);
        RsAddStr(Rs, V, Null);
      End;
      Inc(Rss[Rs].NRow);
      InAgg := False;
      Inc(Rows);
      I := J;
      If NSrc = 0 Then Break;
    End;
    FreeMem(Perm, MaxI(1, NSrc) * 4); FreeMem(Tmp, MaxI(1, NSrc) * 4);
    FreeMem(SortOfs, MaxI(1, NSrc * MaxI(1, GbN)) * 4);
  End
  Else
  Begin
    { lignes simples }
    For I := 0 To NSrc - 1 Do
    Begin
      LocR := Src^[I];
      If T >= 0 Then FtRead(T, LocR);
      For K := 0 To ItN - 1 Do
        If NdK[ItE[K]] = ndStar Then
        Begin
          For J := 0 To FT[T].NCol - 1 Do
          Begin
            V := FtCell(T, LocR, J, Null);
            RsAddStr(Rs, V, Null);
          End;
        End
        Else
        Begin
          Eval(ItE[K], V, Null);
          RsAddStr(Rs, V, Null);
        End;
      If Simple Then RowMapAdd(Rss[Rs].NRow, LocR);
      Inc(Rss[Rs].NRow);
      If LocErr <> '' Then Break;
    End;
  End;
  BufFree(SortKeys);
  If LocErr <> '' Then
  Begin
    FreeMem(Src, MaxI(1, N) * 4);
    RsFree(Rs);
    Exit;
  End;
  { DISTINCT, ORDER BY, LIMIT : nouvelle permutation des lignes du resultat }
  Rows := Rss[Rs].NRow;
  If (ObN > 0) Or Distinct Or (Lim >= 0) Or (Off > 0) Then
  Begin
    BufInit(SortKeys);
    If Distinct Then NK := Rss[Rs].NCol Else NK := ObN;
    SortNK := NK;
    AllocN := MaxI(1, Rows * MaxI(1, MaxI(NK, ObN)));
    GetMem(SortOfs, AllocN * 4);
    For R := 0 To Rows - 1 Do
      For K := 0 To NK - 1 Do
      Begin
        If Distinct Then V := RsCell(Rs, R, K, Null)
        Else If ObOut[K] >= 0 Then V := RsCell(Rs, R, ObOut[K], Null)
        Else
        Begin
          If Simple Then LocR := LocRowMap^[R] Else If (Not Agg) And (R < NSrc) Then LocR := Src^[R];
          Eval(ObE[K], V, Null);
        End;
        KeyAdd(V, Null, Slot);
        SortOfs^[R * NK + K] := Slot;
      End;
    N2 := MaxI(1, Rows);
    GetMem(Perm, N2 * 4); GetMem(Tmp, N2 * 4);
    For R := 0 To Rows - 1 Do Perm^[R] := R;
    If Distinct Then
    Begin
      { tri complet, doublons retires, puis ordre d'origine ou ORDER BY }
      SortDesc := False;
      MSort(Perm, Tmp, Rows);
      J := 0;
      For R := 0 To Rows - 1 Do
        If (R = 0) Or (KeyCmp(Perm^[R], Perm^[R - 1]) <> 0) Then
        Begin
          Tmp^[J] := Perm^[R];
          Inc(J);
        End;
      For R := 0 To J - 1 Do Perm^[R] := Tmp^[R];
      Rows := J;
      If ObN > 0 Then
      Begin
        { cles de tri = colonnes ORDER BY (sur le resultat) }
        SortKeys.Len := 0;
        SortNK := ObN;
        For R := 0 To Rss[Rs].NRow - 1 Do
          For K := 0 To ObN - 1 Do
          Begin
            If ObOut[K] >= 0 Then V := RsCell(Rs, R, ObOut[K], Null) Else
            Begin
              V := ''; Null := True;
            End;
            KeyAdd(V, Null, Slot);
            SortOfs^[R * NK + K] := Slot;
          End;
        SortNK := ObN;
        { les cles sont rangees avec le pas NK : on les recopie au pas ObN }
        For R := 0 To Rss[Rs].NRow - 1 Do
          For K := 0 To ObN - 1 Do SortOfs^[R * ObN + K] := SortOfs^[R * NK + K];
        SortDesc := True;
        MSort(Perm, Tmp, Rows);
      End
      Else
      Begin
        { garder l'ordre d'origine }
        For R := 0 To Rows - 1 Do Tmp^[R] := Perm^[R];
        For R := 1 To Rows - 1 Do
        Begin
          J := Tmp^[R]; K := R - 1;
          While (K >= 0) And (Tmp^[K] > J) Do
          Begin
            Tmp^[K + 1] := Tmp^[K];
            Dec(K);
          End;
          Tmp^[K + 1] := J;
        End;
        For R := 0 To Rows - 1 Do Perm^[R] := Tmp^[R];
      End;
    End
    Else If ObN > 0 Then
    Begin
      SortDesc := True;
      MSort(Perm, Tmp, Rows);
    End;
    { nouveau jeu dans l'ordre de Perm, avec OFFSET et LIMIT }
    OutRs := RsNew;
    If OutRs < 0 Then
    Begin
      LocErr := 'trop de jeux de r'#130'sultats.';
    End
    Else
    Begin
      Rss[OutRs].NCol := Rss[Rs].NCol;
      For K := 0 To Rss[Rs].NCol - 1 Do
      Begin
        RsSetCol(OutRs, K, RsColName(Rs, K)); Rss[OutRs].ColTy[K] := Rss[Rs].ColTy[K];
      End;
      J := 0;
      For R := Off To Rows - 1 Do
      Begin
        If (Lim >= 0) And (J >= Lim) Then Break;
        For K := 0 To Rss[Rs].NCol - 1 Do
        Begin
          V := RsCell(Rs, Perm^[R], K, Null);
          { valeurs longues : copie complete }
          I := RsIdx(Rs, (Perm^[R] * Rss[Rs].NCol + K) * 8 + 4);
          If I > 255 Then RsAddVal(OutRs, @Rss[Rs].Data.P^[RsIdx(Rs, (Perm^[R] * Rss[Rs].NCol + K) * 8)], I)
          Else RsAddStr(OutRs, V, Null);
        End;
        If Simple Then Tmp^[J] := LocRowMap^[Perm^[R]];
        Inc(Rss[OutRs].NRow);
        Inc(J);
      End;
      If Simple Then
        For R := 0 To J - 1 Do LocRowMap^[R] := Tmp^[R];
      RsFree(Rs);
      Rs := OutRs;
    End;
    FreeMem(Perm, N2 * 4);
    FreeMem(Tmp, N2 * 4);
    FreeMem(SortOfs, AllocN * 4);
    BufFree(SortKeys);
  End;
  FreeMem(Src, MaxI(1, N) * 4);
  If Simple Then LocEditT := T Else LocEditT := -1;
  Rss[Rs].Affected := Rss[Rs].NRow;
  LocSelect := Rs;
End;

{ UPDATE table SET col = expr, ... [WHERE ...] }
Procedure LocUpdate;
Var T, N, R, K, WhereE, Cnt : LongInt; SetC, SetE : Array[0..63] Of LongInt; V, E : String; Null : Boolean;
    Nm : String;
Begin
  Expect('UPDATE');
  T := ParseTable;
  If LocErr <> '' Then Exit;
  LocT := T;
  Expect('SET');
  N := 0;
  Repeat
    Nm := TkS(TkI);
    Inc(TkI);
    While IsTk('.') Do
    Begin
      Inc(TkI);
      Nm := TkS(TkI);
      Inc(TkI);
    End;
    SetC[N] := -1;
    For K := 0 To FT[T].NCol - 1 Do If UpStr(FtColName(T, K)) = UpStr(Nm) Then SetC[N] := K;
    If SetC[N] < 0 Then
    Begin
      LocErr := 'colonne inconnue : ' + Nm;
      Exit;
    End;
    Expect('=');
    SetE[N] := PExpr;
    If N < 63 Then Inc(N);
  Until Not Accept(',') Or (LocErr <> '');
  WhereE := -1;
  If Accept('WHERE') Then WhereE := PExpr;
  If LocErr <> '' Then Exit;
  If Not FT[T].Writable Then
  Begin
    LocErr := NameOf(FT[T].Name) + ' : table en lecture seule.';
    Exit;
  End;
  Cnt := 0;
  For R := FtFirst(T) To FT[T].RecordCount - 1 Do
  Begin
    LocR := R;
    If FtDeleted(T, R) Then Continue;
    If WhereE >= 0 Then
    Begin
      Eval(WhereE, V, Null);
      If LocErr <> '' Then Exit;
      If Not Truth(V, Null) Then Continue;
    End;
    For K := 0 To N - 1 Do
    Begin
      Eval(SetE[K], V, Null);
      If LocErr <> '' Then Exit;
      If Null Then V := '';
      If Not FtSetCell(T, R, SetC[K], V, E) Then
      Begin
        LocErr := 'ligne ' + IStr(R + 1) + ', ' + FtColName(T, SetC[K]) + ' : ' + E;
        LocAffected := Cnt;
        Exit;
      End;
    End;
    Inc(Cnt);
  End;
  LocAffected := Cnt;
End;

{ DELETE FROM table [WHERE ...] (dBASE : enregistrements marques) }
Procedure LocDelete;
Var T, R, WhereE, Cnt : LongInt; V : String; Null : Boolean;
Begin
  Expect('DELETE');
  If Accept('FROM') Then ;
  T := ParseTable;
  If LocErr <> '' Then Exit;
  LocT := T;
  WhereE := -1;
  If Accept('WHERE') Then WhereE := PExpr;
  If LocErr <> '' Then Exit;
  If (FT[T].Fmt <> ftDbf) Or Not FT[T].Writable Then
  Begin
    LocErr := 'DELETE : tables dBASE (.DBF) modifiables seulement.';
    Exit;
  End;
  Cnt := 0;
  For R := 0 To FT[T].RecordCount - 1 Do
  Begin
    LocR := R;
    If FtDeleted(T, R) Then Continue;
    If WhereE >= 0 Then
    Begin
      Eval(WhereE, V, Null);
      If LocErr <> '' Then Exit;
      If Not Truth(V, Null) Then Continue;
    End;
    If FtMarkDeleted(T, R, True) Then Inc(Cnt);
  End;
  LocAffected := Cnt;
End;

{ INSERT INTO table [(cols)] VALUES (...), (...) }
Procedure LocInsert;
Var T, N, K, R, Cnt, H, Np : LongInt; Cols : Array[0..MaxFCol - 1] Of LongInt; V, E, Nm, Fn : String; Null : Boolean;
    Ex : LongInt; Line : TBuf;
Begin
  Expect('INSERT');
  Expect('INTO');
  T := ParseTable;
  If LocErr <> '' Then Exit;
  LocT := T;
  N := 0;
  If Accept('(') Then
  Begin
    Repeat
      Nm := TkS(TkI);
      Inc(TkI);
      Cols[N] := -1;
      For K := 0 To FT[T].NCol - 1 Do If UpStr(FtColName(T, K)) = UpStr(Nm) Then Cols[N] := K;
      If Cols[N] < 0 Then
      Begin
        LocErr := 'colonne inconnue : ' + Nm;
        Exit;
      End;
      If N < MaxFCol - 1 Then Inc(N);
    Until Not Accept(',') Or (LocErr <> '');
    Expect(')');
  End
  Else
  Begin
    N := FT[T].NCol;
    For K := 0 To N - 1 Do Cols[K] := K;
  End;
  Expect('VALUES');
  If LocErr <> '' Then Exit;
  If Not FT[T].Writable Or ((FT[T].Fmt <> ftDbf) And (FT[T].Fmt <> ftCsv)) Then
  Begin
    LocErr := 'INSERT : tables dBASE (.DBF) et CSV modifiables seulement.';
    Exit;
  End;
  Cnt := 0;
  Repeat
    Expect('(');
    If LocErr <> '' Then Exit;
    If FT[T].Fmt = ftDbf Then
    Begin
      R := FtAppend(T);
      If R < 0 Then
      Begin
        LocErr := 'ajout impossible.';
        Exit;
      End;
      For K := 0 To N - 1 Do
      Begin
        Ex := PExpr;
        Eval(Ex, V, Null);
        If LocErr <> '' Then Exit;
        If Null Then V := '';
        If Not FtSetCell(T, R, Cols[K], V, E) Then
        Begin
          LocErr := FtColName(T, Cols[K]) + ' : ' + E;
          Exit;
        End;
        If K < N - 1 Then Expect(',');
      End;
    End
    Else
    Begin
      { CSV : une ligne ajoutee a la fin du fichier }
      BufInit(Line);
      For K := 0 To N - 1 Do
      Begin
        Ex := PExpr;
        Eval(Ex, V, Null);
        If LocErr <> '' Then Exit;
        If K > 0 Then BufAddC(Line, 44);
        If Not Null Then CsvPut(Line, V);
        If K < N - 1 Then Expect(',');
      End;
      For K := N To FT[T].NCol - 1 Do BufAddC(Line, 44);
      BufAddC(Line, 13); BufAddC(Line, 10);
      Fn := FT[T].Name;
      H := FT[T].H;
      Np := 0;
      Dummy := DosSetFilePtr(H, 0, 2, LongInt(@Np));
      { la derniere ligne a-t-elle sa fin de ligne ? }
      If Np > 0 Then
      Begin
        If FReadAt(H, Np - 1, @Ex, 1) = 1 Then
          If (Ex And 255) <> 10 Then
          Begin
            Ex := $0A0D;
            Dummy := Ord(FWriteAt(H, Np, @Ex, 2));
            Np := Np + 2;
          End;
      End;
      Dummy := Ord(FWriteAt(H, Np, Line.P, Line.Len));
      BufFree(Line);
      FtClose(T);
      T := FtOpen(Fn);
      If T < 0 Then
      Begin
        LocErr := FtErr;
        Exit;
      End;
      LocT := T;
    End;
    Expect(')');
    Inc(Cnt);
  Until Not Accept(',') Or (LocErr <> '');
  LocAffected := Cnt;
End;

{ executer une instruction sur les tables du dossier Dir ; rend un jeu de
  resultats (-1 : aucun) ; LocErr ; LocAffected }
Function LocRun(Dir : String; Var B : TBuf; A, E : LongInt) : LongInt;
Var Rs : LongInt; W : String;
Begin
  LocRun := -1;
  LocErr := ''; LocAffected := -1; LocEditT := -1;
  LocDir := Dir;
  LocT := -1;
  NdN := 0; NAgg := 0;
  InAgg := False;
  LexSql(B, A, E);
  If TkN = 0 Then Exit;
  W := TkU;
  If W = 'SELECT' Then
  Begin
    Rs := LocSelect;
    LocRun := Rs;
    If Rs >= 0 Then LocAffected := Rss[Rs].NRow;
  End
  Else If W = 'UPDATE' Then LocUpdate
  Else If W = 'DELETE' Then LocDelete
  Else If W = 'INSERT' Then LocInsert
  Else LocErr := 'instruction non prise en charge par le moteur des fichiers : ' + TkS(0) +
                 ' (SELECT, INSERT, UPDATE, DELETE).';
End;
{ ==================================================================== }
{ Explorateur d'objets : arbre des connexions, charge a la demande       }
{ ==================================================================== }

Const
  nkSrv = 1; nkDbs = 2; nkDb = 3; nkSchs = 4; nkSch = 5; nkTbls = 6; nkTbl = 7; nkViews = 8; nkView = 9;
  nkCols = 10; nkCol = 11; nkIdxs = 12; nkIdx = 13; nkProcs = 14; nkProc = 15; nkFuncs = 16; nkFunc = 17;
  nkSeqs = 18; nkSeq = 19; nkTrigs = 20; nkTrig = 21; nkSec = 22; nkUsers = 23; nkUser = 24; nkMsg = 25;
  nkLoad = 26;

Var
  NNode, NTop, NSel, NIdNext : LongInt;
  NKind, NLev, NSrvI, NId, NNm, NDbN, NSchN, NObjN : Array[0..MaxNode - 1] Of LongInt;
  NOpen, NLeaf : Array[0..MaxNode - 1] Of Boolean;
  NText : TBuf;                 { textes des noeuds (chaines courtes : 1 octet de longueur) }

{ --- textes des noeuds --- }

Function NPut(S : String) : LongInt;
Begin
  NPut := NText.Len;
  BufAddC(NText, Length(S));
  BufAdd(NText, S);
End;

Function NGet(O : LongInt) : String;
Var S : String; N : LongInt;
Begin
  NGet := '';
  If (O < 0) Or (O >= NText.Len) Then Exit;
  N := NText.P^[O];
  S[0] := Chr(N);
  If N > 0 Then Move(NText.P^[O + 1], S[1], N);
  NGet := S;
End;

Function NNameStr(I : LongInt) : String;
Begin
  NNameStr := NGet(NNm[I]);
End;

Function NDbStr(I : LongInt) : String;
Begin
  NDbStr := NGet(NDbN[I]);
End;

Function NSchStr(I : LongInt) : String;
Begin
  NSchStr := NGet(NSchN[I]);
End;

Function NObjStr(I : LongInt) : String;
Begin
  NObjStr := NGet(NObjN[I]);
End;

{ tampon des textes recompacte quand il a beaucoup grossi }
Procedure NCompact;
Var B : TBuf; K : LongInt;

  Function Mv(O : LongInt) : LongInt;
  Var N : LongInt;
  Begin
    If (O < 0) Or (O >= NText.Len) Then
    Begin
      Mv := -1;
      Exit;
    End;
    N := NText.P^[O];
    Mv := B.Len;
    BufAddB(B, @NText.P^[O], N + 1);
  End;

Begin
  If NText.Len < 400000 Then Exit;
  BufInit(B);
  For K := 0 To NNode - 1 Do
  Begin
    NNm[K] := Mv(NNm[K]); NDbN[K] := Mv(NDbN[K]); NSchN[K] := Mv(NSchN[K]); NObjN[K] := Mv(NObjN[K]);
  End;
  BufFree(NText);
  NText := B;
End;

{ --- structure de l'arbre --- }

{ inserer un noeud en position P }
Function NIns(P, Kind, Lev, S : LongInt; Nm, Db, Sch, Ob : String) : LongInt;
Var K : LongInt;
Begin
  NIns := -1;
  If NNode >= MaxNode Then Exit;
  For K := NNode - 1 DownTo P Do
  Begin
    NKind[K + 1] := NKind[K]; NLev[K + 1] := NLev[K]; NSrvI[K + 1] := NSrvI[K]; NId[K + 1] := NId[K];
    NNm[K + 1] := NNm[K]; NDbN[K + 1] := NDbN[K]; NSchN[K + 1] := NSchN[K]; NObjN[K + 1] := NObjN[K];
    NOpen[K + 1] := NOpen[K]; NLeaf[K + 1] := NLeaf[K];
  End;
  Inc(NNode);
  NKind[P] := Kind; NLev[P] := Lev; NSrvI[P] := S; NId[P] := NIdNext; Inc(NIdNext);
  NNm[P] := NPut(Nm); NDbN[P] := NPut(Db); NSchN[P] := NPut(Sch); NObjN[P] := NPut(Ob);
  NOpen[P] := False;
  NLeaf[P] := (Kind = nkCol) Or (Kind = nkIdx) Or (Kind = nkProc) Or (Kind = nkFunc) Or (Kind = nkSeq) Or
              (Kind = nkTrig) Or (Kind = nkUser) Or (Kind = nkMsg) Or (Kind = nkLoad);
  If NSel >= P Then Inc(NSel);
  NIns := P;
End;

Procedure NDel(P : LongInt);
Var K : LongInt;
Begin
  If (P < 0) Or (P >= NNode) Then Exit;
  For K := P To NNode - 2 Do
  Begin
    NKind[K] := NKind[K + 1]; NLev[K] := NLev[K + 1]; NSrvI[K] := NSrvI[K + 1]; NId[K] := NId[K + 1];
    NNm[K] := NNm[K + 1]; NDbN[K] := NDbN[K + 1]; NSchN[K] := NSchN[K + 1]; NObjN[K] := NObjN[K + 1];
    NOpen[K] := NOpen[K + 1]; NLeaf[K] := NLeaf[K + 1];
  End;
  Dec(NNode);
  If NSel > P Then Dec(NSel)
  Else If NSel = P Then NSel := MinI(P, NNode - 1);
End;

{ fin des descendants du noeud I (indice du premier noeud apres eux) }
Function NEnd(I : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := I + 1;
  While (K < NNode) And (NLev[K] > NLev[I]) Do Inc(K);
  NEnd := K;
End;

Function NFind(Id : LongInt) : LongInt;
Var K : LongInt;
Begin
  NFind := -1;
  For K := 0 To NNode - 1 Do
    If NId[K] = Id Then
    Begin
      NFind := K;
      Exit;
    End;
End;

{ retirer les enfants du noeud I }
Procedure NClear(I : LongInt);
Var E : LongInt;
Begin
  E := NEnd(I);
  While E > I + 1 Do
  Begin
    NDel(I + 1);
    Dec(E);
  End;
End;

{ ajouter un enfant a la fin des enfants de I ; rend sa position }
Function NAdd(I, Kind : LongInt; Nm, Db, Sch, Ob : String) : LongInt;
Begin
  NAdd := NIns(NEnd(I), Kind, NLev[I] + 1, NSrvI[I], Nm, Db, Sch, Ob);
End;

{ --- libelles --- }

Function KindFolder(K : LongInt) : Boolean;
Begin
  KindFolder := (K = nkDbs) Or (K = nkSchs) Or (K = nkTbls) Or (K = nkViews) Or (K = nkCols) Or (K = nkIdxs) Or
                (K = nkProcs) Or (K = nkFuncs) Or (K = nkSeqs) Or (K = nkTrigs) Or (K = nkSec) Or (K = nkUsers);
End;

Function SqlLit(S : String) : String;
Var K : LongInt; R : String;
Begin
  R := '''';
  For K := 1 To Length(S) Do
  Begin
    If S[K] = '''' Then R := R + '''';
    R := R + S[K];
  End;
  SqlLit := R + '''';
End;

{ nom d'objet cite pour le serveur S }
Function QName(S : LongInt; Sch, Ob : String) : String;
Begin
  Case SKind[S] Of
    skMy :
      If Sch <> '' Then QName := '`' + Sch + '`.`' + Ob + '`' Else QName := '`' + Ob + '`';
    skPg :
      If (Sch <> '') And (Sch <> 'public') Then QName := '"' + Sch + '"."' + Ob + '"'
      Else If (LoStr(Ob) = Ob) And (Pos(' ', Ob) = 0) Then QName := Ob
      Else QName := '"' + Ob + '"';
    skMdf : QName := '[' + Ob + ']';
  Else
    QName := Ob;
  End;
End;

{ nom de type SQL Server d'apres xtype (sp_columns de SQLCMD) }
Function XTypeName(X : LongInt) : String;
Begin
  Case X Of
    34 : XTypeName := 'image';
    35 : XTypeName := 'text';
    36 : XTypeName := 'uniqueidentifier';
    40 : XTypeName := 'date';
    41 : XTypeName := 'time';
    42 : XTypeName := 'datetime2';
    43 : XTypeName := 'datetimeoffset';
    48 : XTypeName := 'tinyint';
    52 : XTypeName := 'smallint';
    56 : XTypeName := 'int';
    58 : XTypeName := 'smalldatetime';
    59 : XTypeName := 'real';
    60 : XTypeName := 'money';
    61 : XTypeName := 'datetime';
    62 : XTypeName := 'float';
    99 : XTypeName := 'ntext';
    104 : XTypeName := 'bit';
    106 : XTypeName := 'decimal';
    108 : XTypeName := 'numeric';
    122 : XTypeName := 'smallmoney';
    127 : XTypeName := 'bigint';
    165 : XTypeName := 'varbinary';
    167 : XTypeName := 'varchar';
    173 : XTypeName := 'binary';
    175 : XTypeName := 'char';
    231 : XTypeName := 'nvarchar';
    239 : XTypeName := 'nchar';
    241 : XTypeName := 'xml';
  Else
    XTypeName := 'type ' + IStr(X);
  End;
End;

{ --- catalogues : requete de chargement des enfants d'un noeud ('' : aucune) --- }

Function CatSql(I : LongInt) : String;
Var S : LongInt; Db, Sch, Ob : String;
Begin
  CatSql := '';
  S := NSrvI[I];
  Db := NDbStr(I); Sch := NSchStr(I); Ob := NObjStr(I);
  Case SKind[S] Of
    skPg :
      Case NKind[I] Of
        nkDbs : CatSql := 'SELECT datname FROM pg_database WHERE NOT datistemplate ORDER BY 1';
        nkSchs : CatSql := 'SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT LIKE ''pg_%'' ' +
                           'AND schema_name <> ''information_schema'' ORDER BY 1';
        nkTbls : CatSql := 'SELECT table_name FROM information_schema.tables WHERE table_schema = ' + SqlLit(Sch) +
                           ' AND table_type = ''BASE TABLE'' ORDER BY 1';
        nkViews : CatSql := 'SELECT table_name FROM information_schema.views WHERE table_schema = ' + SqlLit(Sch) +
                            ' ORDER BY 1';
        nkFuncs : CatSql := 'SELECT DISTINCT routine_name FROM information_schema.routines WHERE routine_schema = ' +
                            SqlLit(Sch) + ' ORDER BY 1';
        nkSeqs : CatSql := 'SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = ' +
                           SqlLit(Sch) + ' ORDER BY 1';
        nkCols : CatSql := 'SELECT column_name, data_type, character_maximum_length, is_nullable FROM ' +
                           'information_schema.columns WHERE table_schema = ' + SqlLit(Sch) + ' AND table_name = ' +
                           SqlLit(Ob) + ' ORDER BY ordinal_position';
        nkIdxs : CatSql := 'SELECT indexname FROM pg_indexes WHERE schemaname = ' + SqlLit(Sch) + ' AND tablename = ' +
                           SqlLit(Ob) + ' ORDER BY 1';
        nkTrigs : CatSql := 'SELECT DISTINCT trigger_name FROM information_schema.triggers WHERE event_object_schema = ' +
                            SqlLit(Sch) + ' AND event_object_table = ' + SqlLit(Ob) + ' ORDER BY 1';
        nkUsers : CatSql := 'SELECT rolname FROM pg_roles WHERE rolname NOT LIKE ''pg_%'' ORDER BY 1';
      End;
    skMy :
      Case NKind[I] Of
        nkDbs : CatSql := 'SHOW DATABASES';
        nkTbls : CatSql := 'SELECT table_name FROM information_schema.tables WHERE table_schema = ' + SqlLit(Db) +
                           ' AND table_type = ''BASE TABLE'' ORDER BY 1';
        nkViews : CatSql := 'SELECT table_name FROM information_schema.tables WHERE table_schema = ' + SqlLit(Db) +
                            ' AND table_type = ''VIEW'' ORDER BY 1';
        nkProcs : CatSql := 'SELECT routine_name FROM information_schema.routines WHERE routine_schema = ' + SqlLit(Db) +
                            ' AND routine_type = ''PROCEDURE'' ORDER BY 1';
        nkFuncs : CatSql := 'SELECT routine_name FROM information_schema.routines WHERE routine_schema = ' + SqlLit(Db) +
                            ' AND routine_type = ''FUNCTION'' ORDER BY 1';
        nkTrigs : CatSql := 'SELECT trigger_name FROM information_schema.triggers WHERE trigger_schema = ' + SqlLit(Db) +
                            ' ORDER BY 1';
        nkCols : CatSql := 'SELECT column_name, column_type, column_key, is_nullable FROM information_schema.columns ' +
                           'WHERE table_schema = ' + SqlLit(Db) + ' AND table_name = ' + SqlLit(Ob) +
                           ' ORDER BY ordinal_position';
        nkIdxs : CatSql := 'SELECT DISTINCT index_name FROM information_schema.statistics WHERE table_schema = ' +
                           SqlLit(Db) + ' AND table_name = ' + SqlLit(Ob) + ' ORDER BY 1';
        nkUsers : CatSql := 'SELECT CONCAT(user, ''@'', host) FROM mysql.user ORDER BY 1';
      End;
    skMdf :
      Case NKind[I] Of
        nkTbls, nkViews : CatSql := 'EXEC sp_tables';
        nkCols : CatSql := 'EXEC sp_columns ' + Ob;
      End;
  End;
End;

{ libelle d'une colonne (comme SSMS : "Nom (varchar(40), NULL)") }
Function ColLabel(Nm, Ty, Len, Key, Nullable : String) : String;
Var S : String;
Begin
  S := Ty;
  If (Len <> '') And (Pos('(', Ty) = 0) Then S := S + '(' + Len + ')';
  If Key = 'PRI' Then S := 'PK, ' + S;
  If (UpStr(Nullable) = 'NO') Or (Nullable = '0') Then S := S + ', non NULL' Else S := S + ', NULL';
  ColLabel := Nm + ' (' + S + ')';
End;

{ enfants fixes d'un noeud (dossiers) ; faux : enfants a charger }
Function NStatic(I : LongInt) : Boolean;
Var S, K, T : LongInt; Db, Sch, Ob, P : String; F : TSearchName;
Begin
  NStatic := True;
  S := NSrvI[I];
  Db := NDbStr(I); Sch := NSchStr(I); Ob := NObjStr(I);
  Case NKind[I] Of
    nkSrv :
      Case SKind[S] Of
        skPg :
          Begin
            Dummy := NAdd(I, nkDbs, 'Bases de donn'#130'es', '', '', '');
            K := NAdd(I, nkSec, 'S'#130'curit'#130, '', '', '');
          End;
        skMy :
          Begin
            Dummy := NAdd(I, nkDbs, 'Bases de donn'#130'es', '', '', '');
            K := NAdd(I, nkSec, 'S'#130'curit'#130, '', '', '');
          End;
        skMdf :
          Begin
            K := NAdd(I, nkDbs, 'Bases de donn'#130'es', '', '', '');
            NOpen[K] := True;
            K := NAdd(K, nkDb, SrvDefDb(S), SrvDefDb(S), '', '');
          End;
        skDir :
          Begin
            K := NAdd(I, nkTbls, 'Tables', SPath[S], '', '');
            NStatic := NStatic(K) And True;
            NOpen[K] := True;
          End;
      End;
    nkSec :
      If SKind[S] = skPg Then Dummy := NAdd(I, nkUsers, 'R'#147'les', SrvDefDb(S), '', '')
      Else Dummy := NAdd(I, nkUsers, 'Utilisateurs', '', '', '');
    nkDb :
      Case SKind[S] Of
        skPg : Dummy := NAdd(I, nkSchs, 'Sch'#130'mas', Db, '', '');
        skMy :
          Begin
            Dummy := NAdd(I, nkTbls, 'Tables', Db, '', '');
            Dummy := NAdd(I, nkViews, 'Vues', Db, '', '');
            Dummy := NAdd(I, nkProcs, 'Proc'#130'dures stock'#130'es', Db, '', '');
            Dummy := NAdd(I, nkFuncs, 'Fonctions', Db, '', '');
            Dummy := NAdd(I, nkTrigs, 'D'#130'clencheurs', Db, '', '');
          End;
        skMdf :
          Begin
            Dummy := NAdd(I, nkTbls, 'Tables', Db, '', '');
            Dummy := NAdd(I, nkViews, 'Vues', Db, '', '');
          End;
      End;
    nkSch :
      Begin
        Dummy := NAdd(I, nkTbls, 'Tables', Db, Sch, '');
        Dummy := NAdd(I, nkViews, 'Vues', Db, Sch, '');
        Dummy := NAdd(I, nkFuncs, 'Fonctions', Db, Sch, '');
        Dummy := NAdd(I, nkSeqs, 'S'#130'quences', Db, Sch, '');
      End;
    nkTbl :
      Begin
        Dummy := NAdd(I, nkCols, 'Colonnes', Db, Sch, Ob);
        If (SKind[S] = skPg) Or (SKind[S] = skMy) Then
        Begin
          Dummy := NAdd(I, nkIdxs, 'Index', Db, Sch, Ob);
          If SKind[S] = skPg Then Dummy := NAdd(I, nkTrigs, 'D'#130'clencheurs', Db, Sch, Ob);
        End;
      End;
    nkView : Dummy := NAdd(I, nkCols, 'Colonnes', Db, Sch, Ob);
    nkTbls :
      If SKind[S] = skDir Then
      Begin
        { fichiers de tables du dossier }
        P := SPath[S];
        T := 0;
        If FindFirstName(JoinPath(P, '*.*'), F) Then
          Repeat
            If FmtOfExt(ExtOf(F.Name)) <> ftNone Then
              If (ExtOf(F.Name) <> 'TXT') Or (Pos('.', F.Name) > 0) Then
              Begin
                Dummy := NAdd(I, nkTbl, F.Name, P, '', F.Name);
                Inc(T);
              End;
          Until Not FindNextName(F);
        If T = 0 Then Dummy := NAdd(I, nkMsg, '(aucune table : .DBF, .CSV, .DAT, .MYD)', '', '', '');
      End
      Else NStatic := False;
    nkCols :
      If SKind[S] = skDir Then
      Begin
        T := FtOpen(JoinPath(SPath[S], Ob));
        If T < 0 Then Dummy := NAdd(I, nkMsg, FtErr, '', '', '')
        Else
          For K := 0 To FT[T].NCol - 1 Do
            Dummy := NAdd(I, nkCol, FtColName(T, K) + ' (' + FtTypeName(T, K) + ')', Db, '', FtColName(T, K));
      End
      Else NStatic := False;
  Else
    NStatic := False;
  End;
End;

{ remplir le noeud (Id) avec le jeu de resultats d'une requete de catalogue }
Procedure NFill(Id, Rs : LongInt; Err : String);
Var I, R, K, S, Kind, N : LongInt; V, V2, V3, V4 : String; Null : Boolean; F : TFields;
Begin
  I := NFind(Id);
  If (I < 0) Or Not NOpen[I] Then Exit;
  NClear(I);
  If Err <> '' Then
  Begin
    Dummy := NAdd(I, nkMsg, 'Erreur : ' + Err, '', '', '');
    Exit;
  End;
  S := NSrvI[I];
  Case NKind[I] Of
    nkDbs : Kind := nkDb;
    nkSchs : Kind := nkSch;
    nkTbls : Kind := nkTbl;
    nkViews : Kind := nkView;
    nkCols : Kind := nkCol;
    nkIdxs : Kind := nkIdx;
    nkProcs : Kind := nkProc;
    nkFuncs : Kind := nkFunc;
    nkSeqs : Kind := nkSeq;
    nkTrigs : Kind := nkTrig;
    nkUsers : Kind := nkUser;
  Else
    Kind := nkMsg;
  End;
  N := 0;
  If (SKind[S] = skMdf) And ((Rs < 0) Or (Rss[Rs].NCol = 0)) Then
  Begin
    { sp_tables et sp_columns de SQLCMD : texte en colonnes larges }
    LnPos := 0;
    R := 0;
    While NextLine(MdfMsg, V) Do
    Begin
      Inc(R);
      If (R <= 2) Or (Trim(V) = '') Or (V[1] = '(') Then Continue;
      K := SplitWide(V, F, 8);
      If K = 0 Then Continue;
      If (Kind = nkTbl) Or (Kind = nkView) Then
      Begin
        If K >= 2 Then V2 := UpStr(F[1]) Else V2 := 'U';
        If ((Kind = nkTbl) And (V2 = 'U')) Or ((Kind = nkView) And (V2 = 'V')) Then
        Begin
          Dummy := NAdd(I, Kind, F[0], NDbStr(I), '', F[0]);
          Inc(N);
        End;
      End
      Else If (Kind = nkCol) And (K >= 2) Then
      Begin
        V3 := '';
        If K >= 4 Then V3 := F[3];
        Dummy := NAdd(I, nkCol, ColLabel(F[1], XTypeName(SVal(F[2])), '', '', V3), NDbStr(I), '', F[1]);
        Inc(N);
      End;
    End;
  End
  Else If Rs >= 0 Then
    For R := 0 To Rss[Rs].NRow - 1 Do
    Begin
      V := Utf8To850(RsCell(Rs, R, 0, Null));
      If Kind = nkCol Then
      Begin
        V2 := RsCell(Rs, R, 1, Null);
        V3 := RsCell(Rs, R, 2, Null);
        V4 := RsCell(Rs, R, 3, Null);
        If SKind[S] = skMy Then V := ColLabel(V, V2, '', V3, V4) Else V := ColLabel(V, V2, V3, '', V4);
        Dummy := NAdd(I, nkCol, V, NDbStr(I), NSchStr(I), Utf8To850(RsCell(Rs, R, 0, Null)));
      End
      Else If Kind = nkDb Then Dummy := NAdd(I, nkDb, V, V, '', '')
      Else If Kind = nkSch Then Dummy := NAdd(I, nkSch, V, NDbStr(I), V, '')
      Else Dummy := NAdd(I, Kind, V, NDbStr(I), NSchStr(I), V);
      Inc(N);
    End;
  If N = 0 Then Dummy := NAdd(I, nkMsg, '(aucun)', '', '', '');
End;

{ ajouter un serveur a la racine ; rend la position du noeud }
Function NAddSrv(S : LongInt) : LongInt;
Begin
  NAddSrv := NIns(NNode, nkSrv, 0, S, SrvLabel(S), SrvDefDb(S), '', '');
End;

Function NFindSrv(S : LongInt) : LongInt;
Var K : LongInt;
Begin
  NFindSrv := -1;
  For K := 0 To NNode - 1 Do
    If (NKind[K] = nkSrv) And (NSrvI[K] = S) Then
    Begin
      NFindSrv := K;
      Exit;
    End;
End;

{ base de donnees du noeud (pour une nouvelle requete) }
Function NodeDb(I : LongInt) : String;
Var S : String;
Begin
  NodeDb := '';
  If I < 0 Then Exit;
  S := NDbStr(I);
  If (NKind[I] = nkSrv) Or (S = '') Then S := SrvDefDb(NSrvI[I]);
  NodeDb := S;
End;
{ ==================================================================== }
{ Fenetre : disposition et dessin                                       }
{ ==================================================================== }

Const
  MaxTb = 24;
  RnW = 44;                     { largeur des numeros de ligne de la grille }
  ExpHdrH = 20;                 { titre de l'Explorateur d'objets }
  { commandes }
  cmNewQuery = 100; cmNewQueryCur = 101; cmOpen = 110; cmOpenTable = 111; cmOpenMdf = 112; cmNewMdf = 113;
  cmSave = 114; cmSaveAs = 115; cmSaveRes = 116; cmClose = 117; cmCloseAll = 118; cmQuit = 119;
  cmUndo = 120; cmRedo = 121; cmCut = 122; cmCopy = 123; cmPaste = 124; cmDelete = 125; cmSelAll = 126;
  cmIndent = 127; cmUnindent = 128; cmUpper = 129; cmLower = 130; cmComment = 131;
  cmFind = 140; cmFindNext = 141; cmReplace = 142; cmGoto = 143;
  cmShowExp = 150; cmShowRes = 151; cmNums = 152; cmRefresh = 153; cmCsvHdr = 154;
  cmExec = 160; cmExecSel = 161; cmStop = 162; cmChangeDb = 163; cmChangeConn = 164; cmResGrid = 165;
  cmResMsg = 166; cmCopyHdr = 167;
  cmConnPg = 170; cmConnMy = 171; cmConnMdf = 172; cmConnDir = 173; cmDisconn = 174; cmConnProps = 175;
  cmConnDel = 176; cmConnMenu = 177;
  cmTop1000 = 180; cmEditRows = 181; cmScrCreate = 182; cmScrSelect = 183; cmScrInsert = 184; cmScrUpdate = 185;
  cmScrDelete = 186; cmNewTable = 187; cmCopyName = 188; cmCollapseAll = 189;
  cmHelp = 190; cmAbout = 191; cmKeys = 192;
  cmDocFirst = 400;
  cmDbFirst = 500;              { 500 + base de donnees (menu Base) }
  { panneaux (clavier) }
  pnEdit = 0; pnTree = 1; pnGrid = 2;

Var
  Hab, Hmq, Frame, Client, MenuHw, Hps, CW, CH : LongInt;
  GQmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..8191] Of Byte;
  MenuLen : LongInt;
  { options }
  ShowNums, ShowExp, ShowRes, InsMode, CaretOn, HasFocus, CopyHdr : Boolean;
  { disposition (Y vers le bas) }
  PanW, Y0, Y1, EdX0, TxX0, TxY0, GutW, VsX, HsY, DtY, Rows, Cols : LongInt;
  EdTop, EdBot, SplitY, RtY, GY0, GY1, GX1, GRows : LongInt;
  UX1, UY1, UX2, UY2 : LongInt;
  { barre d'outils }
  NTb, TbDown : LongInt;
  TbCmd, TbX, TbIco : Array[0..MaxTb - 1] Of LongInt;
  TbTip : Array[0..MaxTb - 1] Of String;
  DbLblX, DbLblW : LongInt;     { zone "Base : ..." de la barre d'outils }
  { onglets }
  DtX : Array[0..MaxDoc] Of LongInt;
  RtX : Array[0..MaxRes + 1] Of LongInt;
  StatusMsg : String;
  Pane : LongInt;
  { requetes : connexion, resultats }
  DSrv, DRun, DT0, DRsN, DTab, DGTop, DGLeft, DGSelR, DGSelC, DEdH, DErrN, DRowsT, DMsgTop, DStmts : Array[0..MaxDoc - 1] Of LongInt;
  DDb : Array[0..MaxDoc - 1] Of String;
  DMsg : Array[0..MaxDoc - 1] Of TBuf;
  DNoName : Array[0..MaxDoc - 1] Of Boolean;
  DRs, DRsT, DRsMapN : Array[0..MaxDoc * MaxRes - 1] Of LongInt;
  DRsMap, DRsCM, DColW : Array[0..MaxDoc * MaxRes - 1] Of PLongs;

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

{ texte coupe a la largeur W (en pixels) }
Procedure OutClip(X, Y, W : LongInt; S : String; Fg, Bg : LongInt);
Var N : LongInt;
Begin
  N := W Div 8;
  If N <= 0 Then Exit;
  If Length(S) > N Then S := Copy(S, 1, N);
  OutTxt(X, Y, S, Fg, Bg);
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

{ --- icones (16 x 16) --- }
Var
  IcX, IcY : LongInt;

Procedure IR(X1, Y1_, X2, Y2, C : LongInt);
Begin
  FBar(IcX + X1, IcY + Y1_, IcX + X2, IcY + Y2, C);
End;

Procedure IB(X1, Y1_, X2, Y2, C : LongInt);
Begin
  IR(X1, Y1_, X2, Y1_, C); IR(X1, Y2, X2, Y2, C); IR(X1, Y1_, X1, Y2, C); IR(X2, Y1_, X2, Y2, C);
End;

Procedure IcoPage(X, Y, C : LongInt);
Begin
  IR(X + 2, Y + 1, X + 11, Y + 14, cWhite);
  IB(X + 2, Y + 1, X + 11, Y + 14, cBlack);
  IR(X + 9, Y + 1, X + 11, Y + 3, cSilver);
  If C <> 0 Then
  Begin
    IR(X + 4, Y + 6, X + 9, Y + 6, C); IR(X + 4, Y + 8, X + 9, Y + 8, C); IR(X + 4, Y + 10, X + 8, Y + 10, C);
  End;
End;

Procedure IcoFolder(Open : Boolean);
Begin
  IR(1, 3, 6, 4, cBrown);
  IR(1, 4, 14, 13, cYellow);
  IB(1, 4, 14, 13, cBrown);
  If Open Then
  Begin
    IR(3, 7, 15, 13, cYellow); IB(3, 7, 15, 13, cBrown);
  End;
End;

{ cylindre d'une base de donnees }
Procedure IcoDb(C : LongInt);
Begin
  IR(3, 3, 12, 13, C);
  IR(4, 2, 11, 2, C); IR(4, 14, 11, 14, C);
  IR(4, 4, 11, 4, cWhite);
  IR(3, 5, 12, 5, cBlack);
  IB(3, 2, 12, 14, cBlack);
End;

Procedure IcoServer(C : LongInt);
Begin
  IR(2, 1, 13, 14, cSilver);
  IB(2, 1, 13, 14, cBlack);
  IR(4, 3, 11, 4, cGray); IR(4, 6, 11, 7, cGray);
  IR(10, 11, 11, 12, C);
End;

Procedure IcoTable(C : LongInt);
Begin
  IR(1, 3, 14, 13, cWhite);
  IR(1, 3, 14, 5, C);
  IB(1, 3, 14, 13, cBlack);
  IR(1, 8, 14, 8, cGray); IR(1, 11, 14, 11, cGray); IR(6, 6, 6, 13, cGray);
End;

Procedure IcoCol(Key : Boolean);
Begin
  IR(3, 3, 12, 12, cWhite);
  IB(3, 3, 12, 12, cBlack);
  IR(5, 5, 10, 6, cBlue);
  If Key Then
  Begin
    IR(8, 8, 14, 9, cYellow); IR(12, 10, 13, 11, cYellow); IR(6, 7, 8, 10, cYellow);
    IB(6, 7, 8, 10, cBrown);
  End;
End;

Procedure IcoTb(K : LongInt);
Var I : LongInt;
Begin
  Case K Of
    1 :
      Begin
        { nouvelle requete : page et "SQL" }
        IcoPage(0, 0, 0);
        IR(4, 6, 9, 6, cBlue); IR(4, 8, 9, 8, cBlue); IR(4, 10, 7, 10, cBlue);
        IR(10, 9, 15, 15, cYellow); IB(10, 9, 15, 15, cBrown);
      End;
    2 : IcoFolder(True);
    3 :
      Begin
        IR(1, 1, 14, 14, cNavy);
        IR(4, 1, 11, 5, cSilver);
        IR(3, 8, 12, 14, cWhite);
        IB(1, 1, 14, 14, cBlack);
      End;
    4 :
      Begin
        { se connecter : prise }
        IR(1, 6, 6, 9, cGray); IR(6, 4, 9, 11, cGreen); IB(6, 4, 9, 11, cBlack);
        IR(10, 5, 14, 5, cBlack); IR(10, 10, 14, 10, cBlack);
      End;
    5 :
      Begin
        { deconnecter : prise ouverte }
        IR(1, 6, 5, 9, cGray); IR(5, 4, 7, 11, cRed); IB(5, 4, 7, 11, cBlack);
        IR(10, 4, 12, 11, cSilver); IB(10, 4, 12, 11, cBlack);
      End;
    6 :
      Begin
        { executer : triangle vert }
        For I := 0 To 6 Do IR(4 + I, 1 + I, 4 + I, 14 - I, cGreen);
        IR(4, 1, 4, 14, cDGreen);
      End;
    7 :
      Begin
        { arreter : carre rouge }
        IR(3, 3, 12, 12, cRed); IB(3, 3, 12, 12, cMaroon);
      End;
    8 :
      Begin
        { actualiser : fleche circulaire }
        IR(4, 2, 11, 3, cBlue); IR(2, 4, 3, 11, cBlue); IR(4, 12, 11, 13, cBlue); IR(12, 4, 13, 8, cBlue);
        IR(10, 7, 15, 8, cBlue); IR(11, 9, 14, 9, cBlue); IR(12, 10, 13, 10, cBlue);
      End;
    9 :
      Begin
        IR(4, 1, 11, 14, cBlue); IR(2, 3, 13, 12, cBlue);
        IR(6, 3, 9, 3, cWhite); IR(9, 4, 10, 6, cWhite); IR(7, 7, 9, 8, cWhite); IR(7, 9, 8, 9, cWhite);
        IR(7, 11, 8, 12, cWhite);
      End;
    10 :
      Begin
        { couper }
        For I := 0 To 6 Do
        Begin
          IR(3 + I, 1 + I, 3 + I, 1 + I, cBlack); IR(12 - I, 1 + I, 12 - I, 1 + I, cBlack);
        End;
        IB(2, 9, 6, 13, cBlack); IB(9, 9, 13, 13, cBlack);
      End;
    11 :
      Begin
        IcoPage(-1, -1, cGray);
        IcoPage(3, 2, cGray);
      End;
    12 :
      Begin
        IR(2, 2, 12, 14, cBrown); IB(2, 2, 12, 14, cBlack);
        IR(5, 1, 9, 3, cSilver); IB(5, 1, 9, 3, cBlack);
        IR(6, 6, 14, 15, cWhite); IB(6, 6, 14, 15, cBlack);
      End;
    13 :
      Begin
        { table : ouvrir une table en fichier }
        IcoTable(cTeal);
      End;
  End;
End;

{ icone d'un noeud de l'arbre }
Procedure IcoNode(I : LongInt);
Var K : LongInt;
Begin
  K := NKind[I];
  Case K Of
    nkSrv :
      Case SKind[NSrvI[I]] Of
        skPg : IcoServer(cBlue);
        skMy : IcoServer(cTeal);
        skMdf : IcoServer(cRed);
      Else
        IcoFolder(NOpen[I]);
      End;
    nkDb : IcoDb(cYellow);
    nkSch : IcoFolder(False);
    nkTbl : IcoTable(cNavy);
    nkView : IcoTable(cDGreen);
    nkCol : IcoCol(Pos('PK,', NNameStr(I)) > 0);
    nkIdx :
      Begin
        IR(2, 7, 10, 8, cBrown); IR(10, 5, 14, 10, cYellow); IB(10, 5, 14, 10, cBrown);
        IR(4, 9, 5, 11, cBrown); IR(7, 9, 8, 10, cBrown);
      End;
    nkProc, nkFunc, nkTrig :
      Begin
        IcoPage(0, 0, 0);
        If K = nkProc Then IR(5, 6, 9, 10, cGreen) Else If K = nkFunc Then IR(5, 6, 9, 10, cDPink)
        Else IR(5, 6, 9, 10, cRed);
      End;
    nkSeq :
      Begin
        IR(2, 4, 13, 11, cWhite); IB(2, 4, 13, 11, cBlack);
        IR(4, 6, 5, 9, cNavy); IR(7, 6, 8, 9, cNavy); IR(10, 6, 11, 9, cNavy);
      End;
    nkUser :
      Begin
        IR(6, 2, 9, 6, cBrown); IR(4, 8, 11, 14, cBlue); IB(6, 2, 9, 6, cBlack);
      End;
    nkMsg, nkLoad :
      Begin
        IR(5, 5, 10, 10, cGray);
      End;
  Else
    IcoFolder(NOpen[I]);
  End;
End;

{ ==================================================================== }
{ Disposition                                                           }
{ ==================================================================== }

Procedure Layout;
Var N, D, H : LongInt;
Begin
  Y0 := TbH;
  Y1 := CH - SbH - 1;
  If ShowExp Then
  Begin
    If PanW > CW - 240 Then PanW := MaxI(140, CW - 240);
    If PanW < 140 Then PanW := 140;
    EdX0 := PanW + 4;
  End
  Else EdX0 := 0;
  DtY := Y0;
  EdTop := DtY + DocTabH;
  VsX := CW - ScrW;
  If (Cur >= 0) And ShowRes Then
  Begin
    H := DEdH[Cur];
    If H < 60 Then H := 60;
    If H > Y1 - EdTop - 80 Then H := MaxI(60, Y1 - EdTop - 80);
    DEdH[Cur] := H;
    EdBot := EdTop + H - 1;
  End
  Else EdBot := Y1;
  HsY := EdBot - ScrW + 1;
  SplitY := EdBot + 1;
  RtY := SplitY + 4;
  GY0 := RtY + ResTabH;
  GY1 := Y1 - ScrW;
  GX1 := VsX - 1;
  GRows := MaxI(1, (GY1 - GY0 - GridRowH) Div GridRowH);
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

Function TreeRows : LongInt;
Begin
  TreeRows := MaxI(1, (Y1 - (Y0 + ExpHdrH) - 4) Div RowH);
End;

Procedure ShowNode;
Begin
  If NSel < NTop Then NTop := NSel;
  If NSel >= NTop + TreeRows Then NTop := NSel - TreeRows + 1;
  If NTop < 0 Then NTop := 0;
End;

{ resultat affiche du document : indice dans DRs (-1 : messages) }
Function CurRes(D : LongInt) : LongInt;
Begin
  CurRes := -1;
  If (D < 0) Or (DTab[D] >= DRsN[D]) Then Exit;
  CurRes := D * MaxRes + DTab[D];
End;

{ largeurs des colonnes d'un resultat (calculees une fois) }
Procedure ColWidths(X : LongInt);
Var Rs, C, R, W, L : LongInt; Null : Boolean; S : String;
Begin
  If DColW[X] <> Nil Then Exit;
  Rs := DRs[X];
  GetMem(DColW[X], MaxRsCol * 4);
  For C := 0 To Rss[Rs].NCol - 1 Do
  Begin
    W := Length(RsColName(Rs, C));
    For R := 0 To MinI(Rss[Rs].NRow, 200) - 1 Do
    Begin
      S := RsCell(Rs, R, C, Null);
      If Null Then L := 4 Else L := Length(S);
      If L > W Then W := L;
    End;
    W := W * 8 + 12;
    If W < 48 Then W := 48;
    If W > 360 Then W := 360;
    DColW[X]^[C] := W;
  End;
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Procedure PaintToolbar;
Var I, X : LongInt; S : String;
Begin
  Raised(0, 0, CW - 1, TbH - 1);
  For I := 0 To NTb - 1 Do
  Begin
    X := TbX[I];
    If TbCmd[I] = 0 Then
    Begin
      VLine(X + 2, 4, TbH - 5, cGray); VLine(X + 3, 4, TbH - 5, cWhite);
    End
    Else
    Begin
      If TbDown = I Then
      Begin
        FBar(X, 3, X + 23, 26, cSilver);
        Edge(X, 3, X + 23, 26, cGray, cWhite);
        IcX := X + 5; IcY := 8;
      End
      Else
      Begin
        IcX := X + 4; IcY := 7;
      End;
      If (TbCmd[I] = cmStop) And Not ((Cur >= 0) And (DRun[Cur] <> 0)) Then
      Begin
        IR(3, 3, 12, 12, cGray);
      End
      Else IcoTb(TbIco[I]);
    End;
  End;
  { base de donnees de la requete }
  X := TbX[NTb - 1] + 36;
  DbLblX := X;
  S := '';
  If Cur >= 0 Then
  Begin
    If DSrv[Cur] >= 0 Then S := DDb[Cur] Else S := '(aucune connexion)';
  End;
  OutTxt(X, 7, 'Base :', cBlack, cSilver);
  X := X + 56;
  DbLblW := MaxI(160, MinI(260, CW - X - 8));
  Sunken(X, 4, X + DbLblW, 25, cWhite);
  OutTxt(X + 4, 7, Fit(S, DbLblW - 24), cBlack, cWhite);
  Raised(X + DbLblW - 16, 5, X + DbLblW - 1, 24);
  For I := 0 To 3 Do HLine(X + DbLblW - 12 + I, X + DbLblW - 5 - I, 12 + I, cBlack);
End;

Procedure PaintTree;
Var I, Y, X, R, Rws, D, Fg, Bg : LongInt; S : String;
Begin
  { titre }
  FBar(0, Y0, PanW - 1, Y0 + ExpHdrH - 1, cSilver);
  If Pane = pnTree Then FBar(1, Y0 + 1, PanW - 2, Y0 + ExpHdrH - 2, cNavy);
  If Pane = pnTree Then OutTxt(6, Y0 + 2, Fit('Explorateur d''objets', PanW - 10), cWhite, cNavy)
  Else OutTxt(6, Y0 + 2, Fit('Explorateur d''objets', PanW - 10), cBlack, cSilver);
  Sunken(0, Y0 + ExpHdrH, PanW - 1, Y1, cWhite);
  Rws := TreeRows;
  If NTop > MaxI(0, NNode - Rws) Then NTop := MaxI(0, NNode - Rws);
  If NTop < 0 Then NTop := 0;
  If NNode = 0 Then
  Begin
    OutTxt(8, Y0 + ExpHdrH + 6, Fit('Aucune connexion.', PanW - 12), cGray, cWhite);
    OutTxt(8, Y0 + ExpHdrH + 26, Fit('Outils - Se connecter,', PanW - 12), cGray, cWhite);
    OutTxt(8, Y0 + ExpHdrH + 42, Fit('ou Fichier - Ouvrir une table.', PanW - 12), cGray, cWhite);
  End;
  For R := 0 To Rws - 1 Do
  Begin
    I := NTop + R;
    If I >= NNode Then Break;
    Y := Y0 + ExpHdrH + 3 + R * RowH;
    X := 18 + NLev[I] * 14;
    If NLev[I] > 0 Then
    Begin
      D := 0;
      While D < 8 Do
      Begin
        FBar(X - 12 + D, Y + 8, X - 12 + D, Y + 8, cGray);
        Inc(D, 2);
      End;
    End;
    If Not NLeaf[I] Then
    Begin
      FBar(X - 16, Y + 4, X - 8, Y + 12, cWhite);
      Box(X - 16, Y + 4, X - 8, Y + 12, cGray);
      HLine(X - 14, X - 10, Y + 8, cBlack);
      If Not NOpen[I] Then VLine(X - 12, Y + 6, Y + 10, cBlack);
    End;
    IcX := X; IcY := Y;
    IcoNode(I);
    S := Fit(NNameStr(I), PanW - X - 26);
    Fg := cBlack; Bg := cWhite;
    If (NKind[I] = nkMsg) Or (NKind[I] = nkLoad) Then Fg := cGray;
    If (NKind[I] = nkMsg) And (Copy(NNameStr(I), 1, 6) = 'Erreur') Then Fg := cRed;
    If I = NSel Then
    Begin
      If Pane = pnTree Then
      Begin
        Fg := cWhite; Bg := cNavy;
      End
      Else Bg := cSilver;
      FBar(X + 18, Y, X + 20 + Length(S) * 8, Y + 15, Bg);
    End;
    OutTxt(X + 19, Y, S, Fg, Bg);
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
    InSel, Sel, Has : Boolean; Cs : String;
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
  S := ''; Ca := -1; Sel := False;
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
        If (Length(S) > 0) And ((A <> Ca) Or (InSel <> Sel) Or (Length(S) >= 200)) Then
        Begin
          If Sel Then
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
        Ca := A; Sel := InSel;
        If Q^[K] = 9 Then S := S + ' ' Else If Q^[K] < 32 Then S := S + '?' Else S := S + Chr(Q^[K]);
      End;
      Inc(V);
    End;
    Inc(K);
  End;
  If Length(S) > 0 Then
  Begin
    If Sel Then
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
  If (Y = DCY[D]) And CaretOn And HasFocus And (Pane = pnEdit) Then
  Begin
    Sx := TxX0 + (VisCol(D, Y, DCX[D]) - DLeft[D]) * 8;
    If (Sx >= TxX0) And (Sx < VsX - 1) Then
    Begin
      If InsMode Then FBar(Sx, Yy, Sx + 1, Yy + RowH - 1, cBlack)
      Else FBar(Sx, Yy + RowH - 3, Sx + 7, Yy + RowH - 1, cBlack);
    End;
  End;
End;

{ onglets des requetes (en haut, comme SSMS) }
Procedure PaintDocTabs;
Var I, X, W : LongInt; S : String;
Begin
  FBar(EdX0, DtY, CW - 1, DtY + DocTabH - 1, cSilver);
  HLine(EdX0, CW - 1, DtY + DocTabH - 1, cGray);
  X := EdX0 + 2;
  For I := 0 To NDoc - 1 Do
  Begin
    S := NameOf(DName[Order[I]]);
    If DMod[Order[I]] Then S := S + ' *';
    If (DSrv[Order[I]] >= 0) And (DDb[Order[I]] <> '') Then S := S + ' - ' + DDb[Order[I]];
    S := Fit(S, 260);
    W := Length(S) * 8 + 16;
    DtX[I] := X;
    If Order[I] = Cur Then
    Begin
      FBar(X, DtY + 1, X + W - 1, DtY + DocTabH - 1, cWhite);
      HLine(X, X + W - 1, DtY + 1, cWhite);
      VLine(X, DtY + 1, DtY + DocTabH - 1, cWhite); VLine(X + W - 1, DtY + 1, DtY + DocTabH - 1, cBlack);
      OutTxt(X + 8, DtY + 2, S, cBlack, cWhite);
    End
    Else
    Begin
      VLine(X + W - 1, DtY + 4, DtY + DocTabH - 3, cGray);
      OutTxt(X + 8, DtY + 3, S, cGray, cSilver);
    End;
    X := X + W;
  End;
  DtX[NDoc] := X;
End;

Procedure PaintEditor;
Var R : LongInt;
Begin
  Box(EdX0, EdTop, VsX - 1, HsY - 1, cGray);
  If Cur < 0 Then
  Begin
    FBar(EdX0 + 1, EdTop + 1, VsX - 1, HsY - 1, cGray);
    OutTxt(EdX0 + 20, EdTop + 20, 'Aucune requ'#136'te ouverte.', cWhite, cGray);
    OutTxt(EdX0 + 20, EdTop + 44, 'Fichier - Nouvelle requ'#136'te (Ctrl+N), ou double clic sur une table', cWhite, cGray);
    OutTxt(EdX0 + 20, EdTop + 60, 'de l''Explorateur d''objets.', cWhite, cGray);
    PaintVScroll(VsX, EdTop, HsY - 1, 0, 0, 1);
    PaintHScroll(EdX0, VsX - 1, HsY, 0, 0, 1);
    FBar(VsX, HsY, CW - 1, HsY + ScrW - 1, cSilver);
    Exit;
  End;
  FBar(EdX0 + 1, EdTop + 1, VsX - 1, TxY0 - 1, cWhite);
  If ShowNums Then FBar(EdX0 + 1, EdTop + 1, EdX0 + GutW, TxY0 - 1, cSilver);
  For R := 0 To Rows - 1 Do PaintLine(R);
  R := TxY0 + Rows * RowH;
  If ShowNums Then FBar(EdX0 + 1, R, EdX0 + GutW, HsY - 1, cSilver) Else FBar(EdX0 + 1, R, EdX0 + GutW, HsY - 1, cWhite);
  FBar(EdX0 + GutW + 1, R, VsX - 1, HsY - 1, cWhite);
  PaintVScroll(VsX, EdTop, HsY - 1, DTop[Cur], MaxTop, Rows);
  PaintHScroll(EdX0, VsX - 1, HsY, DLeft[Cur], HMax, Cols);
  FBar(VsX, HsY, CW - 1, HsY + ScrW - 1, cSilver);
End;

{ onglets des resultats : Resultats (1 par jeu) et Messages }
Procedure PaintResTabs;
Var I, X, W, N : LongInt; S : String;
Begin
  FBar(EdX0, SplitY, CW - 1, RtY - 1, cSilver);
  FBar(EdX0, RtY, CW - 1, RtY + ResTabH - 1, cSilver);
  HLine(EdX0, CW - 1, RtY + ResTabH - 1, cGray);
  N := DRsN[Cur];
  X := EdX0 + 2;
  For I := 0 To N Do
  Begin
    If I = N Then S := 'Messages'
    Else If N = 1 Then S := 'R'#130'sultats'
    Else S := 'R'#130'sultats ' + IStr(I + 1);
    W := Length(S) * 8 + 16;
    RtX[I] := X;
    If ((I = N) And (DTab[Cur] >= N)) Or (I = DTab[Cur]) Then
    Begin
      FBar(X, RtY + 1, X + W - 1, RtY + ResTabH - 1, cWhite);
      VLine(X, RtY + 1, RtY + ResTabH - 1, cWhite); VLine(X + W - 1, RtY + 1, RtY + ResTabH - 1, cBlack);
      HLine(X, X + W - 1, RtY + 1, cWhite);
      If (I = N) And (DErrN[Cur] > 0) Then OutTxt(X + 8, RtY + 2, S, cRed, cWhite)
      Else OutTxt(X + 8, RtY + 2, S, cBlack, cWhite);
    End
    Else
    Begin
      VLine(X + W - 1, RtY + 4, RtY + ResTabH - 3, cGray);
      If (I = N) And (DErrN[Cur] > 0) Then OutTxt(X + 8, RtY + 3, S, cRed, cSilver)
      Else OutTxt(X + 8, RtY + 3, S, cGray, cSilver);
    End;
    X := X + W;
  End;
  RtX[N + 1] := X;
  If DRun[Cur] <> 0 Then OutTxt(MaxI(X + 16, CW - 220), RtY + 3, 'Ex'#130'cution en cours...', cMaroon, cSilver);
End;

{ nombre de colonnes visibles a partir de GLeft }
Function GridColX(X, C : LongInt) : LongInt;
Var K, P : LongInt;
Begin
  P := EdX0 + 1 + RnW;
  For K := DGLeft[Cur] To C - 1 Do P := P + DColW[X]^[K];
  GridColX := P;
End;

Procedure PaintGrid;
Var X, Rs, R, C, Y, Cx, W, Fg, Bg, NR, NC, Ed : LongInt; S : String; Null : Boolean;
Begin
  X := CurRes(Cur);
  Rs := DRs[X];
  ColWidths(X);
  NR := Rss[Rs].NRow; NC := Rss[Rs].NCol;
  If DGTop[Cur] > MaxI(0, NR - GRows) Then DGTop[Cur] := MaxI(0, NR - GRows);
  If DGTop[Cur] < 0 Then DGTop[Cur] := 0;
  If DGLeft[Cur] >= NC Then DGLeft[Cur] := MaxI(0, NC - 1);
  If DGLeft[Cur] < 0 Then DGLeft[Cur] := 0;
  FBar(EdX0, GY0, GX1, GY1 - 1, cWhite);
  { en-tetes }
  Raised(EdX0, GY0, EdX0 + RnW, GY0 + GridRowH - 1);
  Cx := EdX0 + 1 + RnW;
  For C := DGLeft[Cur] To NC - 1 Do
  Begin
    If Cx > GX1 Then Break;
    W := DColW[X]^[C];
    Raised(Cx, GY0, MinI(GX1, Cx + W - 1), GY0 + GridRowH - 1);
    OutClip(Cx + 5, GY0 + 1, MinI(W, GX1 - Cx) - 8, RsColName(Rs, C), cBlack, cSilver);
    Cx := Cx + W;
  End;
  { lignes }
  Ed := DRsT[X];
  For R := 0 To GRows - 1 Do
  Begin
    If DGTop[Cur] + R >= NR Then Break;
    Y := GY0 + GridRowH + R * GridRowH;
    FBar(EdX0, Y, EdX0 + RnW, Y + GridRowH - 1, cSilver);
    HLine(EdX0, EdX0 + RnW, Y + GridRowH - 1, cGray);
    S := IStr(DGTop[Cur] + R + 1);
    If DGTop[Cur] + R = DGSelR[Cur] Then OutTxt(EdX0 + RnW - 4 - Length(S) * 8, Y + 1, S, cNavy, cSilver)
    Else OutTxt(EdX0 + RnW - 4 - Length(S) * 8, Y + 1, S, cBlack, cSilver);
    Cx := EdX0 + 1 + RnW;
    For C := DGLeft[Cur] To NC - 1 Do
    Begin
      If Cx > GX1 Then Break;
      W := DColW[X]^[C];
      S := RsCell(Rs, DGTop[Cur] + R, C, Null);
      Fg := cBlack; Bg := cWhite;
      If Null Then
      Begin
        S := 'NULL'; Fg := cGray;
      End
      Else If Ed < 0 Then S := Utf8To850(S);
      If (DGTop[Cur] + R = DGSelR[Cur]) And (C = DGSelC[Cur]) Then
      Begin
        If Pane = pnGrid Then
        Begin
          Fg := cWhite; Bg := cNavy;
        End
        Else Bg := cSilver;
        FBar(Cx, Y, MinI(GX1, Cx + W - 2), Y + GridRowH - 2, Bg);
      End;
      OutClip(Cx + 4, Y + 1, MinI(W, GX1 - Cx) - 6, S, Fg, Bg);
      VLine(Cx + W - 1, Y, Y + GridRowH - 1, cSilver);
      HLine(Cx, MinI(GX1, Cx + W - 1), Y + GridRowH - 1, cSilver);
      Cx := Cx + W;
    End;
  End;
  PaintVScroll(VsX, GY0, GY1 - 1, DGTop[Cur], MaxI(0, NR - GRows), GRows);
  PaintHScroll(EdX0, VsX - 1, GY1, DGLeft[Cur], MaxI(0, NC - 1), 1);
  FBar(VsX, GY1, CW - 1, Y1, cSilver);
End;

{ lignes des messages : 1er octet = couleur ('E' erreur, 'I' info, 'R' resultat) }
Function MsgLines(D : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To DMsg[D].Len - 1 Do If DMsg[D].P^[K] = 10 Then Inc(N);
  MsgLines := N;
End;

Procedure PaintMsgs;
Var K, St, L, Y, Fg, N : LongInt; S : String;
Begin
  FBar(EdX0, GY0, GX1, GY1 - 1, cWhite);
  N := MsgLines(Cur);
  If DMsgTop[Cur] > MaxI(0, N - GRows) Then DMsgTop[Cur] := MaxI(0, N - GRows);
  If DMsgTop[Cur] < 0 Then DMsgTop[Cur] := 0;
  L := 0; St := 0; Y := GY0 + 4;
  For K := 0 To DMsg[Cur].Len - 1 Do
    If DMsg[Cur].P^[K] = 10 Then
    Begin
      If (L >= DMsgTop[Cur]) And (Y + 16 <= GY1) And (K > St) Then
      Begin
        S := '';
        Move(DMsg[Cur].P^[St + 1], S[1], MinI(255, K - St - 1));
        S[0] := Chr(MinI(255, K - St - 1));
        Case Chr(DMsg[Cur].P^[St]) Of
          'E' : Fg := cRed;
          'R' : Fg := cBlack;
          'T' : Fg := cGray;
        Else
          Fg := cNavy;
        End;
        OutClip(EdX0 + 6, Y, GX1 - EdX0 - 10, S, Fg, cWhite);
        Y := Y + 16;
      End;
      Inc(L);
      St := K + 1;
    End;
  PaintVScroll(VsX, GY0, GY1 - 1, DMsgTop[Cur], MaxI(0, N - GRows), GRows);
  FBar(EdX0, GY1, CW - 1, Y1, cSilver);
End;

Procedure PaintResults;
Begin
  If (Cur < 0) Or Not ShowRes Then Exit;
  PaintResTabs;
  If CurRes(Cur) >= 0 Then PaintGrid Else PaintMsgs;
End;

Procedure PaintStatus;
Var Y, X, D : LongInt; S : String;
Begin
  Y := CH - SbH;
  FBar(0, Y, CW - 1, CH - 1, cSilver);
  HLine(0, CW - 1, Y, cWhite);
  X := CW - 8;
  D := Cur;
  If D >= 0 Then
  Begin
    S := IStr(DRowsT[D]) + ' lignes';
    X := X - (Length(S) * 8 + 12);
    Sunken(X, Y + 2, X + Length(S) * 8 + 8, CH - 2, cSilver);
    OutTxt(X + 4, Y + 2, S, cBlack, cSilver);
    S := IStr(DCY[D] + 1) + ' : ' + IStr(VisCol(D, DCY[D], DCX[D]) + 1);
    X := X - (Length(S) * 8 + 12);
    Sunken(X, Y + 2, X + Length(S) * 8 + 8, CH - 2, cSilver);
    OutTxt(X + 4, Y + 2, S, cBlack, cSilver);
    If DSrv[D] >= 0 Then S := Fit(SrvLabel(DSrv[D]), 300) Else S := '(non connect'#130')';
    X := X - (Length(S) * 8 + 12);
    Sunken(X, Y + 2, X + Length(S) * 8 + 8, CH - 2, cSilver);
    OutTxt(X + 4, Y + 2, S, cNavy, cSilver);
  End;
  OutTxt(6, Y + 2, Fit(StatusMsg, X - 14), cBlack, cSilver);
End;

Procedure Paint(H : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CW; Rc[3] := CH;
  Hps := WinBeginPaint(H, 0, LongInt(@Rc));
  UX1 := Rc[0]; UX2 := Rc[2] - 1; UY1 := CH - Rc[3]; UY2 := CH - 1 - Rc[1];
  If (UX2 < UX1) Or (UY2 < UY1) Then
  Begin
    UX1 := 0; UY1 := 0; UX2 := CW - 1; UY2 := CH - 1;
  End;
  Layout;
  If UY1 < TbH Then PaintToolbar;
  If ShowExp And (UX1 < EdX0) Then
  Begin
    PaintTree;
    FBar(PanW, Y0, EdX0 - 1, Y1, cSilver);
  End;
  If UX2 >= EdX0 Then
  Begin
    PaintDocTabs;
    PaintEditor;
    If (Cur >= 0) And ShowRes Then PaintResults;
  End;
  If UY2 >= CH - SbH Then PaintStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure InvalCaret;
Var R : LongInt;
Begin
  If Cur < 0 Then Exit;
  R := DCY[Cur] - DTop[Cur];
  If (R < 0) Or (R >= Rows) Then Exit;
  InvalBand(EdX0, TxY0 + R * RowH, VsX, TxY0 + (R + 1) * RowH);
End;

Procedure InvalEditor;
Begin
  InvalBand(EdX0, EdTop, CW, EdBot + 1);
End;

Procedure InvalResults;
Begin
  InvalBand(EdX0, SplitY, CW, Y1 + 1);
End;

Procedure InvalTree;
Begin
  InvalBand(0, Y0, PanW, Y1 + 1);
End;

Procedure InvalStatus;
Begin
  InvalBand(0, CH - SbH, CW, CH);
End;
{ ==================================================================== }
{ Edition                                                               }
{ ==================================================================== }

Var
  Clip : TBuf;                 { copie interne (le presse-papiers de PM garde 16 Ko) }
  FindS, ReplS : String;
  FindCase : Boolean;

Procedure Changed;
Begin
  ScrollToCaret;
  InvalEditor;
  InvalBand(EdX0, DtY, CW, DtY + DocTabH);
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

{ commentaire SQL : -- au debut des lignes choisies (ou retrait s'ils y sont tous) }
Procedure CommentSel;
Var D, A, B, Y, K : LongInt; All : Boolean; T : Array[0..2] Of Byte;
Begin
  D := Cur;
  If D < 0 Then Exit;
  SelLines(A, B);
  All := True;
  For Y := A To B Do
  Begin
    K := IndentOf(D, Y);
    If LLen(D, Y) > K Then
      If Not ((LChar(D, Y, K) = 45) And (LChar(D, Y, K + 1) = 45)) Then All := False;
  End;
  BeginEdit(D, 2);
  T[0] := 45; T[1] := 45; T[2] := 32;
  For Y := A To B Do
  Begin
    K := IndentOf(D, Y);
    If All Then
    Begin
      If LLen(D, Y) > K + 1 Then
      Begin
        If LChar(D, Y, K + 2) = 32 Then DelChars(D, Y, K, 3) Else DelChars(D, Y, K, 2);
      End;
    End
    Else If LLen(D, Y) > 0 Then InsChars(D, Y, K, @T, 3);
  End;
  ClampCaret;
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
  If (Cur < 0) Or Not HasSel(Cur) Then Exit;
  CopySel;
  BeginEdit(Cur, 2);
  Dummy := Ord(DelSel(Cur));
  Changed;
End;

Procedure PasteClip;
Var A, N, K : LongInt; Same : Boolean;
Begin
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

{ --- balise correspondante (Ctrl+M) : saute a < ou > associe --- }
Procedure MatchTag;
Var D, Y, X, C, Dir, Lev, Want, Cnt : LongInt;
Begin
  D := Cur;
  If D < 0 Then Exit;
  Y := DCY[D]; X := DCX[D];
  C := LChar(D, Y, X);
  If (C <> 60) And (C <> 62) And (C <> 40) And (C <> 41) And (C <> 123) And (C <> 125) And (C <> 91) And (C <> 93) Then
  Begin
    If X > 0 Then Dec(X);
    C := LChar(D, Y, X);
  End;
  Case C Of
    60 : Want := 62; 62 : Want := 60; 40 : Want := 41; 41 : Want := 40;
    123 : Want := 125; 125 : Want := 123; 91 : Want := 93; 93 : Want := 91;
  Else
    Exit;
  End;
  If (C = 60) Or (C = 40) Or (C = 123) Or (C = 91) Then Dir := 1 Else Dir := -1;
  Lev := 0; Cnt := 0;
  While Cnt < 2000000 Do
  Begin
    If LChar(D, Y, X) = C Then Inc(Lev)
    Else If LChar(D, Y, X) = Want Then
    Begin
      Dec(Lev);
      If Lev = 0 Then
      Begin
        DSel[D] := False;
        DCY[D] := Y; DCX[D] := X;
        Changed;
        Exit;
      End;
    End;
    X := X + Dir;
    If X < 0 Then
    Begin
      Dec(Y);
      If Y < 0 Then Exit;
      X := LLen(D, Y) - 1;
    End
    Else If X >= LLen(D, Y) Then
    Begin
      Inc(Y);
      If Y >= DN[D] Then Exit;
      X := 0;
      While (LLen(D, Y) = 0) And (Y < DN[D] - 1) Do Inc(Y);
    End;
    Inc(Cnt);
  End;
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
{ Boites de dialogue                                                    }
{ ==================================================================== }

Const
  WM_SETFOCUS = $000F;
  WM_USER = $1000;
  dNone = 0; dText = 1; dSplitV = 2; dSplitH = 3; dVThumb = 4; dHThumb = 5; dToolbar = 6; dGVThumb = 7;
  dColRs = 8; dGrid = 9;
  MaxDlg = 6;

Var
  DgFrame, DgClient, DgN, DgW, DgH, DgChkH : LongInt;
  DgDone, DgOk, DgChk : Boolean;
  DgLab, DgV : Array[0..MaxDlg - 1] Of String;
  DgPw : Array[0..MaxDlg - 1] Of Boolean;
  DgEf : Array[0..MaxDlg - 1] Of LongInt;
  DgChkS : String;
  NewCount : LongInt;
  Drag, DragOff, DragCol, LastMx, LastMy : LongInt;
  CtxMenu, CtxN, CtxNode : LongInt;
  HelpBuf : TBuf;
  TipOn : Boolean;
  TipSave, CurDir, IniName : String;
  EdWin, EdD, EdX, EdR, EdC : LongInt;     { edition d'une cellule de la grille }
  JobTimer : Boolean;

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
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('SQL Developer'), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure MsgErr(S : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('SQL Developer'), 0, MB_OK Or MB_ERROR Or MB_MOVEABLE);
End;

Function Ask(S : String) : Boolean;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('SQL Developer'), 0, MB_YESNO Or MB_QUERY Or MB_MOVEABLE) =
         MBID_YES;
End;

Function Ask3(S : String) : LongInt;
Begin
  Ask3 := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('SQL Developer'), 0, MB_YESNOCANCEL Or MB_QUERY Or MB_MOVEABLE);
End;

Function DlgProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Var P, Fl, Vk, K, X, Y : LongInt; Rc, Tr : Array[0..3] Of LongInt;
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
          Tr[0] := 12; Tr[1] := DgH - 34 - K * 30; Tr[2] := 196; Tr[3] := Tr[1] + 18;
          Dummy := WinDrawText(P, -1, LongInt(@TxtBuf), LongInt(@Tr), cBlack, cSilver, 0);
        End;
        Dummy := WinEndPaint(P);
      End;
    WM_COMMAND :
      Begin
        If Lo16(Mp1) = 1 Then
        Begin
          For K := 0 To DgN - 1 Do DgV[K] := WinText(DgEf[K]);
          If DgChkH <> 0 Then DgChk := WinSendMsg(DgChkH, BM_QUERYCHECK, 0, 0) = 1;
          DgOk := True;
        End;
        DgDone := True;
      End;
    WM_BUTTON1DOWN :
      Begin
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        For K := 0 To DgN - 1 Do
          If (X >= 200) And (X < DgW - 14) And (Y >= DgH - 36 - K * 30) And (Y < DgH - 16 - K * 30) Then
            Dummy := WinSetFocus(HWND_DESKTOP, DgEf[K]);
        DlgProc := 1;
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_TAB) Or (Vk = VK_BACKTAB) Or
           (Vk = VK_DOWN) Or (Vk = VK_UP)) Then
        Begin
          P := WinQueryFocus(HWND_DESKTOP);
          X := -1;
          For K := 0 To DgN - 1 Do If DgEf[K] = P Then X := K;
          If (DgChkH <> 0) And (DgChkH = P) Then X := DgN;
          If (Vk = VK_BACKTAB) Or (Vk = VK_UP) Or ((Fl And KC_SHIFT) <> 0) Then Dec(X) Else Inc(X);
          If X < 0 Then X := DgN;
          If (X > DgN) Or ((X = DgN) And (DgChkH = 0)) Then X := 0;
          If X = DgN Then Dummy := WinSetFocus(HWND_DESKTOP, DgChkH)
          Else If DgN > 0 Then Dummy := WinSetFocus(HWND_DESKTOP, DgEf[X]);
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
  DgN := 0; DgChkS := ''; DgChk := False;
  For K := 0 To MaxDlg - 1 Do
  Begin
    DgLab[K] := ''; DgV[K] := ''; DgPw[K] := False;
  End;
End;

Procedure DlgField(L, V : String);
Begin
  If DgN >= MaxDlg Then Exit;
  DgLab[DgN] := L; DgV[DgN] := V; DgPw[DgN] := False;
  Inc(DgN);
End;

Procedure DlgPass(L, V : String);
Begin
  DlgField(L, V);
  DgPw[DgN - 1] := True;
End;

Function InputBox(Title, OkS : String) : Boolean;
Var Fl, K, Fw, Fh, Sw, Sh, C, St : LongInt; Rc : Array[0..3] Of LongInt; Q : Array[0..7] Of LongInt;
Begin
  InputBox := False;
  DgW := 560;
  DgH := 60 + DgN * 30;
  If DgChkS <> '' Then Inc(DgH, 28);
  Dummy := WinRegisterClass(Hab, Z('SQLDEVDLG'), LongInt(@DlgProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DgClient := 0;
  DgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('SQLDEVDLG'), Z2(Title), 0, 0, 0, LongInt(@DgClient));
  If DgFrame = 0 Then Exit;
  For K := 0 To DgN - 1 Do
  Begin
    St := WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN;
    If DgPw[K] Then St := St Or ES_UNREADABLE;
    DgEf[K] := WinCreateWindow(DgClient, WC_ENTRYFIELD, Z(DgV[K]), St, 200, DgH - 36 - K * 30, DgW - 214, 20, DgClient,
                               HWND_TOP, 10 + K, 0, 0);
    Dummy := WinSendMsg(DgEf[K], EM_SETTEXTLIMIT, 250, 0);
  End;
  DgChkH := 0;
  If DgChkS <> '' Then
  Begin
    DgChkH := WinCreateWindow(DgClient, WC_BUTTON, Z(DgChkS), WS_VISIBLE Or WS_TABSTOP Or BS_AUTOCHECKBOX, 12,
                              DgH - 36 - DgN * 30, DgW - 30, 20, DgClient, HWND_TOP, 9, 0, 0);
    C := cSilver;
    Dummy := WinSetPresParam(DgChkH, 4, 4, LongInt(@C));
    If DgChk Then Dummy := WinSendMsg(DgChkH, BM_SETCHECK, 1, 0);
  End;
  Dummy := WinCreateWindow(DgClient, WC_BUTTON, Z(OkS), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                           DgW - 250, 10, 140, 26, DgClient, HWND_TOP, 1, 0, 0);
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
{ Barre d'outils                                                        }
{ ==================================================================== }

Procedure TbAdd(Cmd, Ico : LongInt; Tip : String);
Begin
  If NTb >= MaxTb Then Exit;
  TbCmd[NTb] := Cmd; TbIco[NTb] := Ico; TbTip[NTb] := Tip;
  If NTb = 0 Then TbX[NTb] := 4
  Else If TbCmd[NTb - 1] = 0 Then TbX[NTb] := TbX[NTb - 1] + 8
  Else TbX[NTb] := TbX[NTb - 1] + 25;
  Inc(NTb);
End;

Procedure ToolbarInit;
Begin
  NTb := 0; TbDown := -1;
  TbAdd(cmNewQuery, 1, 'Nouvelle requ'#136'te (Ctrl+N)');
  TbAdd(cmOpen, 2, 'Ouvrir un fichier SQL (Ctrl+O)');
  TbAdd(cmSave, 3, 'Enregistrer (Ctrl+S)');
  TbAdd(0, 0, '');
  TbAdd(cmConnMenu, 4, 'Se connecter (PostgreSQL, MariaDB, SQL Server, fichiers)');
  TbAdd(cmDisconn, 5, 'D'#130'connecter le serveur choisi');
  TbAdd(cmOpenTable, 13, 'Ouvrir une table en fichier (DBF, CSV, Clarion, Btrieve, MyISAM)');
  TbAdd(0, 0, '');
  TbAdd(cmCut, 10, 'Couper (Ctrl+X)');
  TbAdd(cmCopy, 11, 'Copier (Ctrl+C)');
  TbAdd(cmPaste, 12, 'Coller (Ctrl+V)');
  TbAdd(0, 0, '');
  TbAdd(cmExec, 6, 'Ex'#130'cuter (F5)');
  TbAdd(cmStop, 7, 'Arr'#136'ter l''ex'#130'cution (Echap)');
  TbAdd(cmRefresh, 8, 'Actualiser l''Explorateur d''objets');
  TbAdd(0, 0, '');
  TbAdd(cmHelp, 9, 'Aide (F1)');
End;

{ ==================================================================== }
{ Requetes : documents                                                  }
{ ==================================================================== }

Procedure SetCur(D : LongInt);
Begin
  Cur := D;
  If Cur >= 0 Then
  Begin
    Pane := pnEdit;
    If DNoName[D] Then StatusMsg := NameOf(DName[D]) Else StatusMsg := DName[D];
  End;
  Redraw;
End;

{ ligne de message : K = 'E' erreur, 'I' information, 'R' resultat, 'T' temps }
Procedure MsgAdd(D : LongInt; K : Char; S : String);
Begin
  BufAddC(DMsg[D], Ord(K));
  BufAdd(DMsg[D], S);
  BufAddC(DMsg[D], 10);
End;

{ liberer les resultats d'une requete }
Procedure ResClear(D : LongInt);
Var K, X : LongInt;
Begin
  For K := 0 To MaxRes - 1 Do
  Begin
    X := D * MaxRes + K;
    If K < DRsN[D] Then RsFree(DRs[X]);
    If DRsMap[X] <> Nil Then FreeMem(DRsMap[X], MaxI(1, DRsMapN[X]) * 4);
    If DRsCM[X] <> Nil Then FreeMem(DRsCM[X], MaxRsCol * 4);
    If DColW[X] <> Nil Then FreeMem(DColW[X], MaxRsCol * 4);
    DRsMap[X] := Nil; DRsCM[X] := Nil; DColW[X] := Nil; DRs[X] := -1; DRsT[X] := -1; DRsMapN[X] := 0;
  End;
  DRsN[D] := 0; DTab[D] := 0; DGTop[D] := 0; DGLeft[D] := 0; DGSelR[D] := 0; DGSelC[D] := 0;
  DErrN[D] := 0; DRowsT[D] := 0; DMsgTop[D] := 0;
  DMsg[D].Len := 0;
End;

{ ajouter un jeu de resultats ; Edit : table en fichier modifiable }
Procedure ResAdd(D, Rs, EditT : LongInt);
Var X, K : LongInt;
Begin
  If DRsN[D] >= MaxRes Then
  Begin
    MsgAdd(D, 'I', '(jeu de r'#130'sultats non affich'#130' : ' + IStr(MaxRes) + ' au plus par ex'#130'cution)');
    RsFree(Rs);
    Exit;
  End;
  X := D * MaxRes + DRsN[D];
  DRs[X] := Rs; DRsT[X] := -1;
  If (EditT >= 0) And (LocRowCap > 0) Then
  Begin
    DRsT[X] := EditT;
    DRsMapN[X] := MaxI(1, Rss[Rs].NRow);
    GetMem(DRsMap[X], DRsMapN[X] * 4);
    For K := 0 To Rss[Rs].NRow - 1 Do DRsMap[X]^[K] := LocRowMap^[K];
    GetMem(DRsCM[X], MaxRsCol * 4);
    For K := 0 To MaxRsCol - 1 Do DRsCM[X]^[K] := LocColMap[K];
  End;
  If DRsN[D] = 0 Then DTab[D] := 0;
  Inc(DRsN[D]);
End;

Function FindDoc(Name : String) : LongInt;
Var K : LongInt;
Begin
  FindDoc := -1;
  For K := 0 To MaxDoc - 1 Do
    If DUsed[K] And Not DNoName[K] And (UpStr(DName[K]) = UpStr(Name)) Then FindDoc := K;
End;

{ nouvelle requete sur le serveur S, base Db }
Function NewQuery(S : LongInt; Db : String) : LongInt;
Var D : LongInt;
Begin
  NewQuery := -1;
  Inc(NewCount);
  D := DocNew(JoinPath(CurDir, 'SQLQuery' + IStr(NewCount) + '.sql'));
  If D < 0 Then
  Begin
    MsgErr('Pas plus de ' + IStr(MaxDoc) + ' requ'#136'tes ouvertes.');
    Exit;
  End;
  DNoName[D] := True;
  RawIns(D, 0, Nil, 0);
  DMod[D] := False;
  DSrv[D] := S; DDb[D] := Db;
  If (S >= 0) And (Db = '') Then DDb[D] := SrvDefDb(S);
  DRun[D] := 0; DRsN[D] := 0; DEdH[D] := (Y1 - Y0) Div 2;
  BufInit(DMsg[D]);
  ResClear(D);
  SetCur(D);
  NewQuery := D;
End;

{ remplacer le texte de la requete D }
Procedure DocSetText(D : LongInt; S : String);
Var B : TBuf; K : LongInt;
Begin
  BufInit(B);
  For K := 1 To Length(S) Do
    If S[K] = '~' Then
    Begin
      BufAddC(B, 13); BufAddC(B, 10);
    End
    Else BufAddC(B, Ord(S[K]));
  DCY[D] := 0; DCX[D] := 0;
  While DN[D] > 1 Do RawDel(D, DN[D] - 1);
  RawSet(D, 0, Nil, 0);
  InsText(D, B.P, B.Len);
  BufFree(B);
  DCY[D] := 0; DCX[D] := 0; DTop[D] := 0;
  DMod[D] := False;
End;

Procedure OpenFile(Name : String);
Var D, S : LongInt;
Begin
  D := FindDoc(Name);
  If D >= 0 Then
  Begin
    SetCur(D);
    Exit;
  End;
  S := -1;
  If (Cur >= 0) Then S := DSrv[Cur];
  D := NewQuery(S, '');
  If D < 0 Then Exit;
  If (Cur >= 0) And (S >= 0) Then DDb[D] := DDb[Cur];
  RawDel(D, 0);
  DName[D] := Name;
  If Not DocLoad(D, Name) Then
  Begin
    RawIns(D, 0, Nil, 0);
    MsgErr('Impossible d''ouvrir ' + Name + '.');
  End;
  DNoName[D] := False;
  DLang[D] := lgSql;
  CurDir := DirOf(Name);
  SetCur(D);
  StatusMsg := Name + ' : ' + IStr(DN[D]) + ' lignes.';
End;

Function SaveAs(D : LongInt) : Boolean;
Var N : String;
Begin
  SaveAs := False;
  DlgReset;
  DlgField('Nom du fichier :', DName[D]);
  If Not InputBox('Enregistrer sous', 'Enregistrer') Then Exit;
  N := Trim(DgV[0]);
  If N = '' Then Exit;
  If (Length(N) < 2) Or (N[2] <> ':') Then N := JoinPath(CurDir, N);
  If ExtOf(N) = '' Then N := N + '.sql';
  If (UpStr(N) <> UpStr(DName[D])) Or DNoName[D] Then
    If FExists(N) Then
      If Not Ask(N + ' existe d'#130'j'#133'. Le remplacer ?') Then Exit;
  If Not DocSave(D, N) Then
  Begin
    MsgErr('Impossible d''enregistrer ' + N + '.');
    Exit;
  End;
  DName[D] := N; DNoName[D] := False; DMod[D] := False;
  StatusMsg := N + ' enregistr'#130'.';
  SaveAs := True;
End;

Function SaveDoc(D : LongInt) : Boolean;
Begin
  SaveDoc := False;
  If D < 0 Then Exit;
  If DNoName[D] Then
  Begin
    SaveDoc := SaveAs(D);
    Exit;
  End;
  If Not DocSave(D, DName[D]) Then
  Begin
    MsgErr('Impossible d''enregistrer ' + DName[D] + '.');
    Exit;
  End;
  DMod[D] := False;
  StatusMsg := DName[D] + ' enregistr'#130'.';
  SaveDoc := True;
End;

Function CanClose(D : LongInt) : Boolean;
Var R : LongInt;
Begin
  CanClose := True;
  If Not DMod[D] Then Exit;
  SetCur(D);
  R := Ask3('Enregistrer les modifications de ' + NameOf(DName[D]) + ' ?');
  If R = MBID_YES Then CanClose := SaveDoc(D)
  Else If R = MBID_CANCEL Then CanClose := False;
End;

Procedure JobDropDoc(D : LongInt); Forward;
Procedure CellEditEnd(Commit : Boolean); Forward;

Procedure CloseDoc(D : LongInt);
Var K : LongInt;
Begin
  If D < 0 Then Exit;
  If Not CanClose(D) Then Exit;
  If EdWin <> 0 Then CellEditEnd(False);
  JobDropDoc(D);
  ResClear(D);
  BufFree(DMsg[D]);
  K := 0;
  While (K < NDoc) And (Order[K] <> D) Do Inc(K);
  DocFree(D);
  If NDoc = 0 Then Cur := -1
  Else
  Begin
    If K >= NDoc Then K := NDoc - 1;
    Cur := Order[K];
  End;
  Redraw;
End;

{ ==================================================================== }
{ Taches : requetes et catalogues, une a la fois, par la minuterie     }
{ ==================================================================== }

Procedure JobDone(Rs : LongInt; Err : String; Rows : LongInt); Forward;

Function JobAdd(Kind, S : LongInt; Db : String; Sql : String; Doc, Node : LongInt) : LongInt;
Var J : LongInt;
Begin
  JobAdd := -1;
  If NJob >= MaxJob Then Exit;
  J := NJob;
  JKind[J] := Kind; JSrv[J] := S; JDb[J] := Db; JDoc[J] := Doc; JNode[J] := Node; JConn[J] := -1;
  JPhase[J] := 0; JT0[J] := 0; JStmt[J] := 0; JFirst[J] := 0;
  BufInit(JSql[J]);
  BufAdd(JSql[J], Sql);
  Inc(NJob);
  JobAdd := J;
  If Not JobTimer Then
  Begin
    Dummy := WinStartTimer(Hab, Client, 2, 20);
    JobTimer := True;
  End;
End;

Procedure JobPop;
Var K : LongInt;
Begin
  If NJob = 0 Then Exit;
  BufFree(JSql[0]);
  For K := 0 To NJob - 2 Do
  Begin
    JKind[K] := JKind[K + 1]; JSrv[K] := JSrv[K + 1]; JDb[K] := JDb[K + 1]; JDoc[K] := JDoc[K + 1];
    JNode[K] := JNode[K + 1]; JConn[K] := JConn[K + 1]; JPhase[K] := JPhase[K + 1]; JT0[K] := JT0[K + 1];
    JStmt[K] := JStmt[K + 1]; JFirst[K] := JFirst[K + 1]; JSql[K] := JSql[K + 1];
  End;
  Dec(NJob);
  BufInit(JSql[NJob]);
End;

{ retirer les taches d'une requete (fermee ou arretee) }
Procedure JobDropDoc(D : LongInt);
Var K : LongInt;
Begin
  K := 0;
  While K < NJob Do
    If (JKind[K] = jbQuery) And (JDoc[K] = D) Then
    Begin
      If (K = 0) And (JConn[0] >= 0) And (JPhase[0] >= 1) Then
      Begin
        { tache en cours : la connexion est fermee (seul moyen d'arreter) }
        If DbC[JConn[0]].QRs >= 0 Then RsFree(DbC[JConn[0]].QRs);
        DbC[JConn[0]].QRs := -1;
        DbClose(JConn[0]);
      End;
      If K = 0 Then JobPop
      Else
      Begin
        BufFree(JSql[K]);
        Move(JKind[K + 1], JKind[K], (NJob - K - 1) * 4);
        Move(JSrv[K + 1], JSrv[K], (NJob - K - 1) * 4);
        Move(JDoc[K + 1], JDoc[K], (NJob - K - 1) * 4);
        Move(JNode[K + 1], JNode[K], (NJob - K - 1) * 4);
        Move(JConn[K + 1], JConn[K], (NJob - K - 1) * 4);
        Move(JPhase[K + 1], JPhase[K], (NJob - K - 1) * 4);
        Move(JT0[K + 1], JT0[K], (NJob - K - 1) * 4);
        Move(JStmt[K + 1], JStmt[K], (NJob - K - 1) * 4);
        Move(JFirst[K + 1], JFirst[K], (NJob - K - 1) * 4);
        Move(JSql[K + 1], JSql[K], (NJob - K - 1) * SizeOf(TBuf));
        Move(JDb[K + 1], JDb[K], (NJob - K - 1) * SizeOf(JDb[0]));
        Dec(NJob);
        BufInit(JSql[NJob]);
      End;
    End
    Else Inc(K);
  If D >= 0 Then DRun[D] := 0;
End;

{ faire avancer la tache en tete ; appelee par la minuterie }
Procedure JobPump;
Var S, K, R, Rs, Rows, T0 : LongInt; Err : String; U : TBuf;
Begin
  If NJob = 0 Then Exit;
  S := JSrv[0];
  If (S < 0) Or Not SUsed[S] Then
  Begin
    JobDone(-1, 'connexion supprim'#130'e.', 0);
    Exit;
  End;
  If JT0[0] = 0 Then JT0[0] := PTicks;
  Case SKind[S] Of
    skDir :
      Begin
        Rs := LocRun(SPath[S], JSql[0], 0, JSql[0].Len);
        JDb[0] := '';
        JobDone(Rs, LocErr, LocAffected);
      End;
    skMdf :
      Begin
        Rs := MdfRun(SPath[S], JSql[0], Err, Rows);
        JobDone(Rs, Err, Rows);
      End;
    skPg, skMy :
      Begin
        Case JPhase[0] Of
          0 :
            Begin
              K := ConnFind(S, JDb[0]);
              If (K >= 0) And (DbC[K].St <> dsReady) And (DbC[K].St <> dsHandshake) Then
              Begin
                DbClose(K);
                K := -1;
              End;
              If K < 0 Then
              Begin
                Err := '';
                K := ConnOpen(S, JDb[0], Err);
                If K < 0 Then
                Begin
                  JobDone(-1, Err, 0);
                  Exit;
                End;
              End;
              JConn[0] := K;
              JPhase[0] := 1;
            End;
          1 :
            Begin
              K := JConn[0];
              If DbC[K].St = dsHandshake Then
              Begin
                R := DbStep(K);
                If (R = 0) And (PTicks - DbC[K].Deadline > 0) Then
                Begin
                  DbC[K].Err := 'pas de r'#130'ponse du serveur (d'#130'lai d'#130'pass'#130').';
                  R := -1;
                End;
                If R < 0 Then
                Begin
                  Err := 'connexion impossible : ' + DbC[K].Err;
                  DbClose(K);
                  JobDone(-1, Err, 0);
                  Exit;
                End;
                If R = 0 Then Exit;
              End;
              If DbC[K].St <> dsReady Then Exit;
              BufInit(U);
              C850ToUtf8(JSql[0], U);
              If Not ConnQuery(K, U, Err) Then
              Begin
                BufFree(U);
                JobDone(-1, Err, 0);
                Exit;
              End;
              BufFree(U);
              JPhase[0] := 2;
            End;
          2 :
            Begin
              K := JConn[0];
              R := DbStep(K);
              If (R = 0) And (PTicks - DbC[K].Deadline > 0) Then
              Begin
                DbC[K].Err := 'pas de r'#130'ponse du serveur (d'#130'lai d'#130'pass'#130').';
                R := -1;
              End;
              If R = 0 Then Exit;
              Rs := DbC[K].QRs;
              DbC[K].QRs := -1;
              DbC[K].LastUse := PTicks;
              If R < 0 Then
              Begin
                Err := DbC[K].Err;
                If Rs >= 0 Then RsFree(Rs);
                If DbC[K].St <> dsReady Then DbClose(K);
                JobDone(-1, Err, 0);
              End
              Else
              Begin
                Rows := DbC[K].Affected;
                If (Rs >= 0) And (Rss[Rs].NCol = 0) Then
                Begin
                  RsFree(Rs);
                  Rs := -1;
                End
                Else If Rs >= 0 Then Rows := Rss[Rs].NRow;
                JobDone(Rs, '', Rows);
              End;
            End;
        End;
      End;
  End;
End;

{ ==================================================================== }
{ Execution d'une requete                                               }
{ ==================================================================== }

Procedure DocStatus(D : LongInt);
Var T : LongInt; S : String;
Begin
  T := (PTicks - DT0[D]) Div 1000;
  S := Z2D(T Div 3600) + ':' + Z2D((T Div 60) Mod 60) + ':' + Z2D(T Mod 60);
  If DErrN[D] > 0 Then StatusMsg := 'Requ'#136'te termin'#130'e avec des erreurs. (' + S + ')'
  Else StatusMsg := 'Requ'#136'te ex'#130'cut'#130'e avec succ'#138's. (' + S + ')';
End;

{ fin de la tache en tete }
Procedure JobDone(Rs : LongInt; Err : String; Rows : LongInt);
Var D, Id, Kind, J, Ln : LongInt; S : String; Txt : TBuf;
Begin
  If NJob = 0 Then Exit;
  Kind := JKind[0]; D := JDoc[0]; Id := JNode[0];
  If Kind = jbTree Then
  Begin
    NFill(Id, Rs, Err);
    If Rs >= 0 Then RsFree(Rs);
    JobPop;
    InvalTree;
  End
  Else If Kind = jbQuery Then
  Begin
    If (D >= 0) And DUsed[D] Then
    Begin
      Ln := JStmt[0];
      If Err <> '' Then
      Begin
        Inc(DErrN[D]);
        MsgAdd(D, 'E', 'Msg, ligne ' + IStr(Ln + 1) + ' : ' + Utf8To850(Err));
        { erreur : les instructions suivantes ne sont pas executees }
        J := 1;
        While J < NJob Do
          If (JKind[J] = jbQuery) And (JDoc[J] = D) Then
          Begin
            JDoc[J] := -2;
            Inc(J);
          End
          Else Inc(J);
        DTab[D] := DRsN[D];
      End
      Else
      Begin
        If (SKind[JSrv[0]] = skMdf) And (MdfMsg.Len > 0) And (Rs < 0) Then
        Begin
          { sortie texte de SQLCMD (sp_help, PRINT...) }
          LnPos := 0;
          While NextLine(MdfMsg, S) Do MsgAdd(D, 'R', S);
        End;
        If Rs >= 0 Then
        Begin
          ResAdd(D, Rs, LocEditT * Ord(SKind[JSrv[0]] = skDir) - Ord(SKind[JSrv[0]] <> skDir));
          If Rows >= 0 Then MsgAdd(D, 'I', '(' + IStr(Rows) + ' ligne(s) affect'#130'e(s))');
          If Rows > 0 Then DRowsT[D] := DRowsT[D] + Rows;
        End
        Else If Rows >= 0 Then
        Begin
          MsgAdd(D, 'I', '(' + IStr(Rows) + ' ligne(s) affect'#130'e(s))');
          DRowsT[D] := DRowsT[D] + Rows;
        End
        Else MsgAdd(D, 'I', 'Commande(s) r'#130'ussie(s).');
      End;
      Dec(DStmts[D]);
      If DStmts[D] <= 0 Then
      Begin
        DRun[D] := 0;
        MsgAdd(D, 'T', 'Ach'#130'vement : ' + TodayStr);
        If DRsN[D] = 0 Then DTab[D] := DRsN[D];
        If D = Cur Then DocStatus(D);
      End;
      If D = Cur Then Redraw;
    End
    Else If Rs >= 0 Then RsFree(Rs);
    JobPop;
    { taches annulees par une erreur }
    While (NJob > 0) And (JDoc[0] = -2) Do JobPop;
    If (D >= 0) And DUsed[D] Then
    Begin
      J := 0;
      For Ln := 0 To NJob - 1 Do If (JKind[Ln] = jbQuery) And (JDoc[Ln] = D) Then Inc(J);
      If J = 0 Then
      Begin
        If DRun[D] <> 0 Then
        Begin
          DRun[D] := 0;
          MsgAdd(D, 'T', 'Ach'#130'vement : ' + TodayStr);
        End;
        DStmts[D] := 0;
        If D = Cur Then
        Begin
          DocStatus(D);
          Redraw;
        End;
      End;
    End;
  End
  Else
  Begin
    If Rs >= 0 Then RsFree(Rs);
    JobPop;
  End;
End;

{ executer la requete D (Sel : la selection seulement) }
Procedure ExecDoc(D : LongInt; Sel : Boolean);
Var B, One : TBuf; Y1s, X1s, Y2s, X2s, K, Line0 : LongInt;
Begin
  If D < 0 Then Exit;
  If DRun[D] <> 0 Then
  Begin
    StatusMsg := 'Une ex'#130'cution est d'#130'j'#133' en cours (Echap pour l''arr'#136'ter).';
    InvalStatus;
    Exit;
  End;
  If DSrv[D] < 0 Then
  Begin
    MsgErr('Cette requ'#136'te n''est li'#130'e '#133' aucune connexion.' + #13#10 +
           'Choisissez un serveur ou une base dans l''Explorateur d''objets, puis Requ'#136'te - Changer de connexion,' +
           ' ou ouvrez la requ'#136'te depuis un serveur (bouton 2 - Nouvelle requ'#136'te).');
    Exit;
  End;
  If EdWin <> 0 Then CellEditEnd(False);
  BufInit(B);
  Line0 := 0;
  If (Sel Or True) And HasSel(D) Then
  Begin
    SelRange(D, Y1s, X1s, Y2s, X2s);
    GetRange(D, Y1s, X1s, Y2s, X2s, B);
    Line0 := Y1s;
  End
  Else GetRange(D, 0, 0, DN[D] - 1, LLen(D, DN[D] - 1), B);
  SplitStmts(B, Line0);
  ResClear(D);
  If StN = 0 Then
  Begin
    BufFree(B);
    StatusMsg := 'Rien '#133' ex'#130'cuter.';
    InvalStatus;
    Exit;
  End;
  DT0[D] := PTicks;
  DRun[D] := 1;
  DStmts[D] := StN;
  BufInit(One);
  For K := 0 To StN - 1 Do
  Begin
    One.Len := 0;
    BufAddB(One, @B.P^[StA[K]], StB[K] - StA[K]);
    If JobAdd(jbQuery, DSrv[D], DDb[D], '', D, -1) >= 0 Then
    Begin
      BufAddB(JSql[NJob - 1], One.P, One.Len);
      JStmt[NJob - 1] := StLine[K];
    End;
  End;
  BufFree(One); BufFree(B);
  StatusMsg := 'Ex'#130'cution de la requ'#136'te...';
  Redraw;
End;

Procedure StopDoc(D : LongInt);
Begin
  If (D < 0) Or (DRun[D] = 0) Then Exit;
  JobDropDoc(D);
  DRun[D] := 0;
  Inc(DErrN[D]);
  MsgAdd(D, 'E', 'Requ'#136'te annul'#130'e par l''utilisateur.');
  DTab[D] := DRsN[D];
  StatusMsg := 'Requ'#136'te annul'#130'e.';
  Redraw;
End;

{ ==================================================================== }
{ Connexions                                                            }
{ ==================================================================== }

Procedure SaveIni;
Var B : TBuf; S, K : LongInt; T : String;
Begin
  BufInit(B);
  BufAdd(B, '; SQL Developer d''OS/2-0 : connexions m'#130'moris'#130'es' + #13#10);
  BufAdd(B, '[Options]' + #13#10);
  If CsvHeaders Then BufAdd(B, 'EntetesCSV=oui' + #13#10) Else BufAdd(B, 'EntetesCSV=non' + #13#10);
  For K := 0 To NNode - 1 Do
    If NKind[K] = nkSrv Then
    Begin
      S := NSrvI[K];
      Case SKind[S] Of
        skPg : T := 'pg';
        skMy : T := 'my';
        skMdf : T := 'mdf';
      Else
        T := 'dir';
      End;
      BufAdd(B, '[Connexion]' + #13#10 + 'Type=' + T + #13#10);
      If SName[S] <> '' Then BufAdd(B, 'Nom=' + SName[S] + #13#10);
      If SHost[S] <> '' Then BufAdd(B, 'Hote=' + SHost[S] + #13#10);
      If SPortN[S] > 0 Then BufAdd(B, 'Port=' + IStr(SPortN[S]) + #13#10);
      If SUser[S] <> '' Then BufAdd(B, 'Utilisateur=' + SUser[S] + #13#10);
      If SSavePw[S] Then BufAdd(B, 'MotDePasse=' + B64Str(SPass[S]) + #13#10);
      If SDb[S] <> '' Then BufAdd(B, 'Base=' + SDb[S] + #13#10);
      If SPath[S] <> '' Then BufAdd(B, 'Chemin=' + SPath[S] + #13#10);
    End;
  Dummy := Ord(WriteAll(IniName, B.P, B.Len));
  BufFree(B);
End;

Procedure LoadIni;
Var B : TBuf; L, Key, V : String; S, P : LongInt;
Begin
  BufInit(B);
  If Not ReadAll(IniName, B) Then
  Begin
    BufFree(B);
    Exit;
  End;
  S := -1;
  LnPos := 0;
  While NextLine(B, L) Do
  Begin
    L := Trim(L);
    If (L = '') Or (L[1] = ';') Then Continue;
    If UpStr(L) = '[CONNEXION]' Then
    Begin
      If S >= 0 Then Dummy := NAddSrv(S);
      S := SrvNew(skDir);
      Continue;
    End;
    P := Pos('=', L);
    If P = 0 Then Continue;
    Key := UpStr(Trim(Copy(L, 1, P - 1))); V := Trim(Copy(L, P + 1, 255));
    If Key = 'ENTETESCSV' Then CsvHeaders := UpStr(V) <> 'NON';
    If S < 0 Then Continue;
    If Key = 'TYPE' Then
    Begin
      If V = 'pg' Then SKind[S] := skPg Else If V = 'my' Then SKind[S] := skMy
      Else If V = 'mdf' Then SKind[S] := skMdf Else SKind[S] := skDir;
    End
    Else If Key = 'NOM' Then SName[S] := V
    Else If Key = 'HOTE' Then SHost[S] := V
    Else If Key = 'PORT' Then SPortN[S] := SVal(V)
    Else If Key = 'UTILISATEUR' Then SUser[S] := V
    Else If Key = 'MOTDEPASSE' Then
    Begin
      SPass[S] := B64DecStr(V);
      SSavePw[S] := True;
    End
    Else If Key = 'BASE' Then SDb[S] := V
    Else If Key = 'CHEMIN' Then SPath[S] := V;
  End;
  If S >= 0 Then Dummy := NAddSrv(S);
  BufFree(B);
End;

{ dialogue de connexion a un serveur (S : -1 nouveau) ; rend le serveur }
Function ConnDialog(Kind, S : LongInt) : LongInt;
Var Title : String; New_ : Boolean; P : LongInt;
Begin
  ConnDialog := -1;
  New_ := S < 0;
  DlgReset;
  Case Kind Of
    skPg, skMy :
      Begin
        If Kind = skPg Then Title := 'Se connecter '#133' PostgreSQL' Else Title := 'Se connecter '#133' MariaDB ou MySQL';
        If New_ Then
        Begin
          DlgField('Serveur (h'#147'te) :', '10.0.2.2');
          If Kind = skPg Then DlgField('Port :', '5432') Else DlgField('Port :', '3306');
          If Kind = skPg Then DlgField('Utilisateur :', 'postgres') Else DlgField('Utilisateur :', 'root');
          DlgPass('Mot de passe :', '');
          If Kind = skPg Then DlgField('Base de donn'#130'es :', 'postgres') Else DlgField('Base de donn'#130'es :', '');
        End
        Else
        Begin
          DlgField('Serveur (h'#147'te) :', SHost[S]);
          DlgField('Port :', IStr(SPortN[S]));
          DlgField('Utilisateur :', SUser[S]);
          DlgPass('Mot de passe :', SPass[S]);
          DlgField('Base de donn'#130'es :', SDb[S]);
        End;
        DlgField('Nom affich'#130' (facultatif) :', '');
        If Not New_ Then DgV[5] := SName[S];
        DgChkS := 'M'#130'moriser le mot de passe (SQLDEV.INI)';
        If Not New_ Then DgChk := SSavePw[S];
        If Not InputBox(Title, 'Se connecter') Then Exit;
        If Trim(DgV[0]) = '' Then Exit;
        If New_ Then S := SrvNew(Kind);
        If S < 0 Then
        Begin
          MsgErr('Trop de connexions (' + IStr(MaxSrv) + ').');
          Exit;
        End;
        ConnCloseSrv(S);
        SHost[S] := Trim(DgV[0]); SPortN[S] := SVal(Trim(DgV[1]));
        If SPortN[S] <= 0 Then If Kind = skPg Then SPortN[S] := 5432 Else SPortN[S] := 3306;
        SUser[S] := Trim(DgV[2]); SPass[S] := DgV[3]; SDb[S] := Trim(DgV[4]); SName[S] := Trim(DgV[5]);
        SSavePw[S] := DgChk;
      End;
    skMdf :
      Begin
        Title := 'Ouvrir une base SQL Server (.MDF)';
        If New_ Then DlgField('Fichier .MDF :', JoinPath(CurDir, 'master.mdf')) Else DlgField('Fichier .MDF :', SPath[S]);
        DgChkS := 'Cr'#130'er la base si le fichier n''existe pas (SQLCMD --createmdf)';
        DgChk := True;
        If Not InputBox(Title, 'Ouvrir') Then Exit;
        If Trim(DgV[0]) = '' Then Exit;
        DgV[0] := Trim(DgV[0]);
        If (Length(DgV[0]) < 2) Or (DgV[0][2] <> ':') Then DgV[0] := JoinPath(CurDir, DgV[0]);
        If ExtOf(DgV[0]) = '' Then DgV[0] := DgV[0] + '.mdf';
        If Not FExists(DgV[0]) Then
        Begin
          If Not DgChk Then
          Begin
            MsgErr(DgV[0] + ' introuvable.');
            Exit;
          End;
          If Not MdfCreate(DgV[0], Title) Then
          Begin
            MsgErr('Impossible de cr'#130'er ' + DgV[0] + ' : ' + Title);
            Exit;
          End;
        End;
        If New_ Then S := SrvNew(skMdf);
        If S < 0 Then Exit;
        SPath[S] := DgV[0];
      End;
    skDir :
      Begin
        Title := 'Ouvrir un dossier de tables (dBASE, CSV, Clarion, Btrieve, MyISAM)';
        If New_ Then DlgField('Dossier :', CurDir) Else DlgField('Dossier :', SPath[S]);
        If Not InputBox(Title, 'Ouvrir') Then Exit;
        If Trim(DgV[0]) = '' Then Exit;
        If New_ Then S := SrvNew(skDir);
        If S < 0 Then Exit;
        SPath[S] := Trim(DgV[0]);
        While (Length(SPath[S]) > 3) And (SPath[S][Length(SPath[S])] = '\') Do Delete(SPath[S], Length(SPath[S]), 1);
      End;
  End;
  P := NFindSrv(S);
  If P < 0 Then P := NAddSrv(S)
  Else
  Begin
    NClear(P);
    NOpen[P] := False;
    Dummy := NIns(P, nkSrv, 0, S, SrvLabel(S), SrvDefDb(S), '', '');
    NDel(P + 1);
  End;
  NSel := P;
  SaveIni;
  ConnDialog := S;
End;

{ ==================================================================== }
{ Explorateur d'objets : actions                                        }
{ ==================================================================== }

Procedure ExpandNode(I : LongInt);
Var Sql : String; L : LongInt;
Begin
  If (I < 0) Or (I >= NNode) Or NLeaf[I] Or NOpen[I] Then Exit;
  NOpen[I] := True;
  If NEnd(I) > I + 1 Then Exit;       { deja charge }
  If NStatic(I) Then Exit;
  Sql := CatSql(I);
  If Sql = '' Then
  Begin
    Dummy := NAdd(I, nkMsg, '(aucun)', '', '', '');
    Exit;
  End;
  L := NAdd(I, nkLoad, '(chargement...)', '', '', '');
  If JobAdd(jbTree, NSrvI[I], NodeDb(I), Sql, -1, NId[I]) < 0 Then NFill(NId[I], -1, 'trop de t'#131'ches en attente.');
End;

{ replier : les enfants sont retires (relus au prochain depliage, comme Actualiser) }
Procedure CollapseNode(I : LongInt);
Var K, E : LongInt;
Begin
  If (I < 0) Or (I >= NNode) Then Exit;
  E := NEnd(I);
  If (NSel > I) And (NSel < E) Then NSel := I;
  For K := NJob - 1 DownTo 1 Do
    If JKind[K] = jbTree Then
      If (NFind(JNode[K]) >= I) And (NFind(JNode[K]) < E) Then JNode[K] := -1;
  NClear(I);
  NOpen[I] := False;
  NCompact;
End;

{ actualiser : enfants relus }
Procedure RefreshNode(I : LongInt);
Var Was : Boolean; K : LongInt;
Begin
  If (I < 0) Or (I >= NNode) Then Exit;
  Was := NOpen[I];
  { une tache en attente pour ce noeud est retiree }
  For K := NJob - 1 DownTo 1 Do
    If (JKind[K] = jbTree) And (JNode[K] = NId[I]) Then JNode[K] := -1;
  NClear(I);
  NOpen[I] := False;
  If (NSel > I) And (NSel >= NNode) Then NSel := I;
  If Was Or (NKind[I] = nkSrv) Then ExpandNode(I);
  NCompact;
End;

Procedure ToggleNode(I : LongInt);
Begin
  If (I < 0) Or (I >= NNode) Then Exit;
  If NOpen[I] Then CollapseNode(I) Else ExpandNode(I);
  ShowNode;
  InvalTree;
End;

Procedure SelectNode(I : LongInt);
Begin
  If (I < 0) Or (I >= NNode) Then Exit;
  NSel := I;
  ShowNode;
  InvalTree;
End;

{ serveur et base du noeud choisi, ou de la requete active }
Function SelSrv : LongInt;
Begin
  SelSrv := -1;
  If (NSel >= 0) And (NSel < NNode) Then SelSrv := NSrvI[NSel]
  Else If Cur >= 0 Then SelSrv := DSrv[Cur];
End;

{ nom complet d'une table pour une requete }
Function TableRef(I : LongInt) : String;
Var S : LongInt;
Begin
  S := NSrvI[I];
  If SKind[S] = skDir Then TableRef := NObjStr(I)
  Else If SKind[S] = skMy Then TableRef := QName(S, NDbStr(I), NObjStr(I))
  Else TableRef := QName(S, NSchStr(I), NObjStr(I));
End;

{ SELECT des 1000 premieres lignes d'une table ou vue }
Procedure SelectTop(I : LongInt);
Var D, S : LongInt; Q, Q2 : String;
Begin
  If (I < 0) Or ((NKind[I] <> nkTbl) And (NKind[I] <> nkView)) Then Exit;
  S := NSrvI[I];
  Case SKind[S] Of
    skMdf, skDir : Q := 'SELECT TOP 1000 * FROM ' + TableRef(I);
  Else
    Q := 'SELECT * FROM ' + TableRef(I) + ' LIMIT 1000';
  End;
  D := NewQuery(S, NodeDb(I));
  If D < 0 Then Exit;
  Q2 := NObjStr(I);
  If Pos('.', Q2) > 0 Then Q2 := Copy(Q2, 1, Pos('.', Q2) - 1);
  DName[D] := JoinPath(CurDir, Q2 + '.sql');
  DocSetText(D, Q);
  ExecDoc(D, False);
End;

{ colonnes connues d'une table (noeud Colonnes deja charge) }
Function NodeCols(I : LongInt) : String;
Var K, E, C : LongInt; S : String;
Begin
  NodeCols := '';
  S := '';
  E := NEnd(I);
  For K := I + 1 To E - 1 Do
    If NKind[K] = nkCols Then
    Begin
      For C := K + 1 To NEnd(K) - 1 Do
        If NKind[C] = nkCol Then
        Begin
          If S <> '' Then S := S + ', ';
          If Length(S) < 200 Then S := S + NObjStr(C);
        End;
    End;
  NodeCols := S;
End;

{ scripts d'une table (Generer le script) }
Procedure Script(I, Kind : LongInt);
Var D, S, K, Tb : LongInt; T, C, Q, Fn, Q2 : String;
Begin
  If (I < 0) Or ((NKind[I] <> nkTbl) And (NKind[I] <> nkView)) Then
  Begin
    Msg('Choisissez une table dans l''Explorateur d''objets.');
    Exit;
  End;
  S := NSrvI[I];
  T := TableRef(I);
  C := NodeCols(I);
  If C = '' Then C := '*';
  D := NewQuery(S, NodeDb(I));
  If D < 0 Then Exit;
  Case Kind Of
    cmScrSelect : Q := 'SELECT ' + C + '~FROM ' + T + ';~';
    cmScrInsert :
      Begin
        If C = '*' Then Q := 'INSERT INTO ' + T + '~VALUES (...);~'
        Else Q := 'INSERT INTO ' + T + '~(' + C + ')~VALUES (...);~';
      End;
    cmScrUpdate :
      Begin
        If C = '*' Then Q := 'UPDATE ' + T + '~SET colonne = valeur~WHERE ...;~'
        Else Q := 'UPDATE ' + T + '~SET ' + Copy(C, 1, Pos(',', C + ',') - 1) + ' = valeur~WHERE ...;~';
      End;
    cmScrDelete : Q := 'DELETE FROM ' + T + '~WHERE ...;~';
    cmScrCreate :
      Begin
        Case SKind[S] Of
          skMy :
            Begin
              { la definition exacte vient du serveur }
              Q := 'SHOW CREATE TABLE ' + T + ';~';
            End;
          skDir :
            Begin
              Tb := FtOpen(JoinPath(SPath[S], NObjStr(I)));
              Q := '-- ' + NObjStr(I) + ' : table ';
              If Tb >= 0 Then
              Begin
                Q := Q + FmtName(FT[Tb].Fmt) + ', ' + IStr(FtRows(Tb)) + ' lignes~CREATE TABLE ' + T + ' (~';
                For K := 0 To FT[Tb].NCol - 1 Do
                Begin
                  Fn := FtColName(Tb, K) + ' ' + FtTypeName(Tb, K);
                  If Length(Q) + Length(Fn) > 240 Then Break;
                  If K > 0 Then Q := Q + ',~';
                  Q := Q + '  ' + Fn;
                End;
                Q := Q + '~);~';
              End;
            End;
          skPg :
            Q := 'SELECT column_name, data_type, character_maximum_length, is_nullable, column_default~' +
                 'FROM information_schema.columns~WHERE table_schema = ' + SqlLit(NSchStr(I)) + ' AND table_name = ' +
                 SqlLit(NObjStr(I)) + '~ORDER BY ordinal_position;~';
          skMdf : Q := 'EXEC sp_columns ' + NObjStr(I) + ';~';
        End;
      End;
  End;
  Q2 := NObjStr(I);
  If Pos('.', Q2) > 0 Then Q2 := Copy(Q2, 1, Pos('.', Q2) - 1);
  DName[D] := JoinPath(CurDir, Q2 + '.sql');
  DocSetText(D, Q);
  DMod[D] := True;
  If (Kind = cmScrCreate) And (SKind[S] <> skDir) Then ExecDoc(D, False);
  Redraw;
End;

{ ==================================================================== }
{ Grille : edition d'une cellule (tables en fichiers)                   }
{ ==================================================================== }

Function CellRect(X, R, C : LongInt; Var Cx, Cy, W : LongInt) : Boolean;
Begin
  CellRect := False;
  If (R < DGTop[Cur]) Or (R >= DGTop[Cur] + GRows) Or (C < DGLeft[Cur]) Then Exit;
  Cx := GridColX(X, C);
  If Cx > GX1 Then Exit;
  W := MinI(DColW[X]^[C], GX1 - Cx);
  Cy := GY0 + GridRowH + (R - DGTop[Cur]) * GridRowH;
  CellRect := True;
End;

Procedure CellEditBegin;
Var X, Rs, Cx, Cy, W : LongInt; S : String; Null : Boolean;
Begin
  If Cur < 0 Then Exit;
  X := CurRes(Cur);
  If X < 0 Then Exit;
  Rs := DRs[X];
  If (DRsT[X] < 0) Or (DRsCM[X] = Nil) Then
  Begin
    StatusMsg := 'R'#130'sultat en lecture seule (seules les tables en fichiers se modifient dans la grille ; ' +
                 'utilisez UPDATE).';
    InvalStatus;
    Exit;
  End;
  If (DGSelR[Cur] >= Rss[Rs].NRow) Or (DRsCM[X]^[DGSelC[Cur]] < 0) Then Exit;
  If Not FT[DRsT[X]].Writable Then
  Begin
    StatusMsg := NameOf(FT[DRsT[X]].Name) + ' : table en lecture seule.';
    InvalStatus;
    Exit;
  End;
  If Not CellRect(X, DGSelR[Cur], DGSelC[Cur], Cx, Cy, W) Then Exit;
  S := RsCell(Rs, DGSelR[Cur], DGSelC[Cur], Null);
  EdWin := WinCreateWindow(Client, WC_ENTRYFIELD, Z(S), WS_VISIBLE Or ES_AUTOSCROLL, Cx + 2,
                           CH - Cy - GridRowH + 1, MaxI(80, W - 3), GridRowH - 2, Client, HWND_TOP, 77, 0, 0);
  Dummy := WinSendMsg(EdWin, EM_SETTEXTLIMIT, 250, 0);
  EdD := Cur; EdX := X; EdR := DGSelR[Cur]; EdC := DGSelC[Cur];
  Dummy := WinSetFocus(HWND_DESKTOP, EdWin);
  StatusMsg := 'Modification de la cellule : Entr'#130'e pour enregistrer dans ' + NameOf(FT[DRsT[X]].Name) +
               ', Echap pour annuler.';
  InvalStatus;
End;

Procedure CellEditEnd(Commit : Boolean);
Var S, E : String; T, Fr, Fc : LongInt;
Begin
  If EdWin = 0 Then Exit;
  S := WinText(EdWin);
  Dummy := WinDestroyWindow(EdWin);
  EdWin := 0;
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  If Commit And DUsed[EdD] And (DRsT[EdX] >= 0) Then
  Begin
    T := DRsT[EdX];
    Fr := DRsMap[EdX]^[EdR]; Fc := DRsCM[EdX]^[EdC];
    If FtSetCell(T, Fr, Fc, S, E) Then
    Begin
      RsSetCell(DRs[EdX], EdR, EdC, FtCell(T, Fr, Fc, Commit), Commit);
      StatusMsg := NameOf(FT[T].Name) + ' : ligne ' + IStr(Fr + 1) + ', ' + FtColName(T, Fc) + ' enregistr'#130'.';
      MsgAdd(EdD, 'I', StatusMsg);
    End
    Else
    Begin
      StatusMsg := 'Cellule non modifi'#130'e : ' + E;
      MsgErr(StatusMsg);
    End;
  End;
  Redraw;
End;

{ copier la cellule choisie, ou tout le resultat (Tout) }
Procedure GridCopy(Tout : Boolean);
Var X, Rs, R, C, N : LongInt; B : TBuf; S : String; Null : Boolean; T : PBytes;
Begin
  If Cur < 0 Then Exit;
  X := CurRes(Cur);
  If X < 0 Then Exit;
  Rs := DRs[X];
  BufInit(B);
  If Tout Then
  Begin
    If CopyHdr Then
    Begin
      For C := 0 To Rss[Rs].NCol - 1 Do
      Begin
        If C > 0 Then BufAddC(B, 9);
        BufAdd(B, RsColName(Rs, C));
      End;
      BufAddC(B, 13); BufAddC(B, 10);
    End;
    For R := 0 To Rss[Rs].NRow - 1 Do
    Begin
      For C := 0 To Rss[Rs].NCol - 1 Do
      Begin
        If C > 0 Then BufAddC(B, 9);
        S := RsCell(Rs, R, C, Null);
        If Null Then S := 'NULL' Else If DRsT[X] < 0 Then S := Utf8To850(S);
        BufAdd(B, S);
      End;
      BufAddC(B, 13); BufAddC(B, 10);
      If B.Len > 15000 Then Break;
    End;
  End
  Else
  Begin
    S := RsCell(Rs, DGSelR[Cur], DGSelC[Cur], Null);
    If Null Then S := 'NULL' Else If DRsT[X] < 0 Then S := Utf8To850(S);
    BufAdd(B, S);
  End;
  N := MinI(B.Len, 16383);
  GetMem(T, N + 1);
  If N > 0 Then Move(B.P^[0], T^[0], N);
  T^[N] := 0;
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    Dummy := WinSetClipbrdData(Hab, LongInt(T), 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
  FreeMem(T, N + 1);
  BufFree(B);
  If Tout Then StatusMsg := 'R'#130'sultat copi'#130' (texte s'#130'par'#130' par des tabulations).'
  Else StatusMsg := 'Cellule copi'#130'e.';
  InvalStatus;
End;

{ enregistrer le resultat affiche en CSV }
Procedure SaveResCsv;
Var X, Rs, R, C : LongInt; B : TBuf; S, N : String; Null : Boolean;
Begin
  If Cur < 0 Then Exit;
  X := CurRes(Cur);
  If X < 0 Then
  Begin
    Msg('Aucun r'#130'sultat affich'#130'.');
    Exit;
  End;
  Rs := DRs[X];
  DlgReset;
  DlgField('Fichier CSV :', JoinPath(CurDir, 'resultats.csv'));
  If Not InputBox('Enregistrer les r'#130'sultats sous', 'Enregistrer') Then Exit;
  N := Trim(DgV[0]);
  If N = '' Then Exit;
  If (Length(N) < 2) Or (N[2] <> ':') Then N := JoinPath(CurDir, N);
  BufInit(B);
  For C := 0 To Rss[Rs].NCol - 1 Do
  Begin
    If C > 0 Then BufAddC(B, 44);
    CsvPut(B, RsColName(Rs, C));
  End;
  BufAddC(B, 13); BufAddC(B, 10);
  For R := 0 To Rss[Rs].NRow - 1 Do
  Begin
    For C := 0 To Rss[Rs].NCol - 1 Do
    Begin
      If C > 0 Then BufAddC(B, 44);
      S := RsCell(Rs, R, C, Null);
      If Not Null Then
      Begin
        If DRsT[X] < 0 Then S := Utf8To850(S);
        CsvPut(B, S);
      End;
    End;
    BufAddC(B, 13); BufAddC(B, 10);
  End;
  If WriteAll(N, B.P, B.Len) Then StatusMsg := N + ' : ' + IStr(Rss[Rs].NRow) + ' lignes enregistr'#130'es.'
  Else MsgErr('Impossible d'#39#130'crire ' + N + '.');
  BufFree(B);
  InvalStatus;
End;
{ ==================================================================== }
{ Menus                                                                 }
{ ==================================================================== }

Var
  MStkN : Array[0..7] Of LongInt;
  MDep : LongInt;
  DbListN : LongInt;
  DbList : TBuf;                { bases proposees par la liste de la barre d'outils }
  OutFile : String;             { /OUT : resultats ecrits puis fin du programme }
  AutoRun : Boolean;

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

Procedure MenuClose(H, Count : LongInt);
Begin
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

Procedure ConnSubMenu;
Var H2 : LongInt;
Begin
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 89, '~Se connecter');
  H2 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmConnPg, '~PostgreSQL...');
  MnItem(MIS_TEXT, 0, cmConnMy, '~MariaDB ou MySQL...');
  MnItem(MIS_TEXT, 0, cmConnMdf, 'Base ~SQL Server (.MDF)...');
  MnItem(MIS_TEXT, 0, cmConnDir, '~Dossier de tables (dBASE, CSV, Clarion, Btrieve, MyISAM)...');
  MenuClose(H2, 4);
End;

Procedure ScriptSubMenu;
Var H2 : LongInt;
Begin
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 88, '~G'#130'n'#130'rer le script de la table');
  H2 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmScrCreate, 'CREATE TABLE');
  MnItem(MIS_TEXT, 0, cmScrSelect, 'SELECT');
  MnItem(MIS_TEXT, 0, cmScrInsert, 'INSERT');
  MnItem(MIS_TEXT, 0, cmScrUpdate, 'UPDATE');
  MnItem(MIS_TEXT, 0, cmScrDelete, 'DELETE');
  MenuClose(H2, 5);
End;

Procedure BuildMenu;
Var H0, H1 : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 90, '~Fichier');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmNewQuery, '~Nouvelle requ'#136'te' + #9 + 'Ctrl+N');
  MnItem(MIS_TEXT, 0, cmOpen, '~Ouvrir un fichier SQL...' + #9 + 'Ctrl+O');
  MnItem(MIS_TEXT, 0, cmOpenTable, 'Ouvrir une ~table (DBF, CSV, Clarion, Btrieve, MyISAM)...');
  MnItem(MIS_TEXT, 0, cmOpenMdf, 'Ouvrir une base SQL Server (.~MDF)...');
  Sep;
  MnItem(MIS_TEXT, 0, cmSave, '~Enregistrer' + #9 + 'Ctrl+S');
  MnItem(MIS_TEXT, 0, cmSaveAs, 'Enregistrer ~sous...');
  MnItem(MIS_TEXT, 0, cmSaveRes, 'Enregistrer les ~r'#130'sultats sous (CSV)...');
  Sep;
  MnItem(MIS_TEXT, 0, cmClose, '~Fermer' + #9 + 'Ctrl+F4');
  MnItem(MIS_TEXT, 0, cmCloseAll, 'Fermer to~ut');
  Sep;
  MnItem(MIS_TEXT, 0, cmQuit, '~Quitter' + #9 + 'Alt+F4');
  MenuClose(H1, 0);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 91, '~Edition');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmUndo, '~Annuler' + #9 + 'Ctrl+Z');
  MnItem(MIS_TEXT, 0, cmRedo, '~R'#130'tablir' + #9 + 'Ctrl+Y');
  Sep;
  MnItem(MIS_TEXT, 0, cmCut, '~Couper' + #9 + 'Ctrl+X');
  MnItem(MIS_TEXT, 0, cmCopy, 'C~opier' + #9 + 'Ctrl+C');
  MnItem(MIS_TEXT, 0, cmPaste, 'Co~ller' + #9 + 'Ctrl+V');
  MnItem(MIS_TEXT, 0, cmDelete, '~Supprimer' + #9 + 'Suppr');
  Sep;
  MnItem(MIS_TEXT, 0, cmSelAll, 'S'#130'lectionner ~tout' + #9 + 'Ctrl+A');
  Sep;
  MnItem(MIS_TEXT, 0, cmFind, '~Rechercher...' + #9 + 'Ctrl+F');
  MnItem(MIS_TEXT, 0, cmFindNext, 'Rechercher le s~uivant' + #9 + 'F3');
  MnItem(MIS_TEXT, 0, cmReplace, 'R~emplacer...' + #9 + 'Ctrl+H');
  MnItem(MIS_TEXT, 0, cmGoto, 'Aller '#133' la ~ligne...' + #9 + 'Ctrl+G');
  Sep;
  MnItem(MIS_TEXT, 0, cmComment, 'Mettre en co~mmentaire (--)' + #9 + 'Ctrl+Maj+C');
  MnItem(MIS_TEXT, 0, cmUpper, 'M~ajuscules' + #9 + 'Ctrl+Maj+U');
  MnItem(MIS_TEXT, 0, cmLower, 'Mi~nuscules' + #9 + 'Ctrl+U');
  MnItem(MIS_TEXT, 0, cmIndent, '~Indenter' + #9 + 'Tab');
  MnItem(MIS_TEXT, 0, cmUnindent, '~D'#130'sindenter' + #9 + 'Maj+Tab');
  MenuClose(H1, 0);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 92, '~Affichage');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, Chk(ShowExp), cmShowExp, '~Explorateur d''objets' + #9 + 'F8');
  MnItem(MIS_TEXT, Chk(ShowRes), cmShowRes, 'Volet des ~r'#130'sultats' + #9 + 'Ctrl+R');
  MnItem(MIS_TEXT, Chk(ShowNums), cmNums, '~Num'#130'ros de ligne');
  Sep;
  MnItem(MIS_TEXT, 0, cmRefresh, '~Actualiser l''Explorateur d''objets');
  MnItem(MIS_TEXT, 0, cmCollapseAll, 'R'#130'~duire tout l''arbre');
  MenuClose(H1, 0);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 93, '~Requ'#136'te');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmExec, '~Ex'#130'cuter' + #9 + 'F5');
  MnItem(MIS_TEXT, 0, cmStop, '~Arr'#136'ter l''ex'#130'cution' + #9 + 'Echap');
  Sep;
  MnItem(MIS_TEXT, 0, cmChangeConn, '~Changer de connexion (noeud choisi de l''Explorateur)');
  MnItem(MIS_TEXT, 0, cmChangeDb, '~Base de donn'#130'es...');
  Sep;
  MnItem(MIS_TEXT, 0, cmResGrid, 'Afficher les ~r'#130'sultats');
  MnItem(MIS_TEXT, 0, cmResMsg, 'Afficher les ~messages');
  MnItem(MIS_TEXT, Chk(CopyHdr), cmCopyHdr, 'Copier les r'#130'sultats avec les ~en-t'#136'tes');
  MenuClose(H1, 0);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 94, '~Outils');
  H1 := MenuOpen;
  ConnSubMenu;
  MnItem(MIS_TEXT, 0, cmDisconn, '~D'#130'connecter');
  MnItem(MIS_TEXT, 0, cmConnProps, '~Propri'#130't'#130's de la connexion...');
  MnItem(MIS_TEXT, 0, cmConnDel, 'Supprimer la c~onnexion');
  Sep;
  MnItem(MIS_TEXT, 0, cmTop1000, 'S'#130'lectionner les ~1000 premi'#138'res lignes');
  ScriptSubMenu;
  MnItem(MIS_TEXT, 0, cmNewTable, 'Nouvelle ~table...');
  Sep;
  MnItem(MIS_TEXT, Chk(CsvHeaders), cmCsvHdr, 'Fichiers CSV : premi'#138're ligne = ~noms des colonnes');
  MenuClose(H1, 0);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 95, 'Fe~n'#136'tre');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmDocFirst + 1, 'Requ'#136'te ~suivante' + #9 + 'Ctrl+Tab');
  MnItem(MIS_TEXT, 0, cmDocFirst + 2, 'Requ'#136'te ~pr'#130'c'#130'dente' + #9 + 'Ctrl+Maj+Tab');
  Sep;
  MnItem(MIS_TEXT, 0, cmCloseAll, '~Fermer toutes les requ'#136'tes');
  MenuClose(H1, 0);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 96, '~?');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmHelp, '~Aide' + #9 + 'F1');
  MnItem(MIS_TEXT, 0, cmKeys, '~Touches');
  Sep;
  MnItem(MIS_TEXT, 0, cmAbout, '~A propos de SQL Developer...');
  MenuClose(H1, 0);
  MenuClose(H0, 0);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

Procedure CtxIt(Id : LongInt; S : String);
Begin
  MnItem(MIS_TEXT, 0, Id, S);
  Inc(CtxN);
End;

Procedure CtxSep;
Begin
  MnItem(MIS_SEPARATOR, 0, 0, '');
  Inc(CtxN);
End;

{ bases connues du serveur S (noeuds deja charges) }
Procedure DbListFill(S : LongInt);
Var K : LongInt;
Begin
  DbList.Len := 0; DbListN := 0;
  For K := 0 To NNode - 1 Do
    If (NKind[K] = nkDb) And (NSrvI[K] = S) And (DbListN < 60) Then
    Begin
      BufAddC(DbList, Length(NDbStr(K)));
      BufAdd(DbList, NDbStr(K));
      Inc(DbListN);
    End;
End;

Function DbListItem(I : LongInt) : String;
Var K, P, N : LongInt; S : String;
Begin
  DbListItem := '';
  P := 0;
  For K := 0 To I - 1 Do P := P + DbList.P^[P] + 1;
  N := DbList.P^[P];
  S[0] := Chr(N);
  Move(DbList.P^[P + 1], S[1], N);
  DbListItem := S;
End;

{ Kind : 0 editeur, 1 arbre, 2 grille, 3 onglets, 4 bases, 5 connexion ; X, Y de PM }
Procedure Popup(Kind, X, Y : LongInt);
Var Fst, K, I : LongInt;
Begin
  MenuLen := 0; CtxN := 0;
  Dummy := MenuOpen;
  Fst := 0;
  Case Kind Of
    1 :
      Begin
        I := NSel;
        If (I < 0) Or (I >= NNode) Then
        Begin
          ConnSubMenu;
          Inc(CtxN);
        End
        Else
          Case NKind[I] Of
            nkSrv :
              Begin
                Fst := cmNewQuery;
                CtxIt(cmNewQuery, '~Nouvelle requ'#136'te');
                CtxIt(cmRefresh, '~Actualiser');
                CtxSep;
                CtxIt(cmDisconn, '~D'#130'connecter');
                CtxIt(cmConnProps, '~Propri'#130't'#130's de la connexion...');
                CtxIt(cmConnDel, '~Supprimer la connexion');
              End;
            nkDb, nkSch :
              Begin
                Fst := cmNewQuery;
                CtxIt(cmNewQuery, '~Nouvelle requ'#136'te');
                CtxIt(cmRefresh, '~Actualiser');
              End;
            nkTbl, nkView :
              Begin
                Fst := cmTop1000;
                CtxIt(cmTop1000, 'S'#130'lectionner les ~1000 premi'#138'res lignes');
                If SKind[NSrvI[I]] = skDir Then CtxIt(cmEditRows, '~Modifier les lignes (grille)');
                CtxSep;
                ScriptSubMenu;
                Inc(CtxN);
                CtxSep;
                CtxIt(cmNewQuery, '~Nouvelle requ'#136'te');
                CtxIt(cmRefresh, '~Actualiser');
                CtxIt(cmCopyName, '~Copier le nom');
              End;
            nkTbls :
              Begin
                Fst := cmRefresh;
                If SKind[NSrvI[I]] <> skDir Then CtxIt(cmNewTable, '~Nouvelle table...');
                CtxIt(cmNewQuery, 'Nouvelle ~requ'#136'te');
                CtxIt(cmRefresh, '~Actualiser');
              End;
            nkCol, nkIdx, nkProc, nkFunc, nkSeq, nkTrig, nkUser :
              Begin
                Fst := cmCopyName;
                CtxIt(cmCopyName, '~Copier le nom');
              End;
          Else
            Begin
              Fst := cmRefresh;
              CtxIt(cmRefresh, '~Actualiser');
            End;
          End;
      End;
    2 :
      Begin
        Fst := cmCopy;
        CtxIt(cmCopy, '~Copier la cellule' + #9 + 'Ctrl+C');
        CtxIt(cmCopy + 1000, 'Copier ~tout le r'#130'sultat');
        CtxIt(cmSaveRes, '~Enregistrer les r'#130'sultats sous (CSV)...');
        If (CurRes(Cur) >= 0) And (DRsT[CurRes(Cur)] >= 0) Then
        Begin
          CtxSep;
          CtxIt(cmEditRows + 1000, '~Modifier la cellule' + #9 + 'F2');
        End;
      End;
    3 :
      Begin
        Fst := cmSave;
        CtxIt(cmSave, '~Enregistrer' + #9 + 'Ctrl+S');
        CtxIt(cmSaveAs, 'Enregistrer ~sous...');
        CtxSep;
        CtxIt(cmClose, '~Fermer' + #9 + 'Ctrl+F4');
      End;
    4 :
      Begin
        If (Cur >= 0) And (DSrv[Cur] >= 0) Then DbListFill(DSrv[Cur]) Else DbListN := 0;
        For K := 0 To DbListN - 1 Do CtxIt(cmDbFirst + K, DbListItem(K));
        If DbListN > 0 Then CtxSep;
        CtxIt(cmChangeDb, '~Autre base...');
        Fst := cmChangeDb;
      End;
    5 :
      Begin
        Fst := cmConnPg;
        CtxIt(cmConnPg, '~PostgreSQL...');
        CtxIt(cmConnMy, '~MariaDB ou MySQL...');
        CtxIt(cmConnMdf, 'Base ~SQL Server (.MDF)...');
        CtxIt(cmConnDir, '~Dossier de tables (dBASE, CSV...)...');
      End;
  Else
    Begin
      Fst := cmExec;
      CtxIt(cmExec, '~Ex'#130'cuter' + #9 + 'F5');
      CtxSep;
      CtxIt(cmCut, '~Couper' + #9 + 'Ctrl+X');
      CtxIt(cmCopy, 'C~opier' + #9 + 'Ctrl+C');
      CtxIt(cmPaste, 'Co~ller' + #9 + 'Ctrl+V');
      CtxSep;
      CtxIt(cmSelAll, 'S'#130'lectionner ~tout' + #9 + 'Ctrl+A');
      CtxIt(cmComment, 'Mettre en co~mmentaire' + #9 + 'Ctrl+Maj+C');
      CtxSep;
      CtxIt(cmChangeConn, 'Changer de co~nnexion');
    End;
  End;
  MenuClose(0, CtxN);
  If CtxMenu <> 0 Then Dummy := WinDestroyWindow(CtxMenu);
  CtxMenu := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuT));
  If CtxMenu <> 0 Then Dummy := WinPopupMenu(Client, Client, CtxMenu, X, Y, Fst, 0);
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Procedure HelpBox(S : String);
Begin
  BufAdd(HelpBuf, S);
End;

Procedure ShowHelp(Keys : Boolean);
Begin
  BufInit(HelpBuf);
  If Not Keys Then
  Begin
    HelpBox('SQL Developer : requ'#136'tes SQL et Explorateur d''objets.' + #13#10#13#10);
    HelpBox('Se connecter (Outils, ou le bouton de la prise) : PostgreSQL, MariaDB ou MySQL (h'#147'te, port, ');
    HelpBox('utilisateur, mot de passe), une base SQL Server en fichier .MDF (par SQLCMD.EXE), ou un dossier de ');
    HelpBox('tables (dBASE .DBF, CSV, Clarion et Btrieve .DAT, MyISAM .MYD). Les connexions sont m'#130'moris'#130'es ');
    HelpBox('dans SQLDEV.INI.' + #13#10#13#10);
    HelpBox('Explorateur d''objets : d'#130'pliez un serveur, ses bases, sch'#130'mas, tables et colonnes. Double ');
    HelpBox('clic sur une table : ses 1000 premi'#138'res lignes. Bouton 2 : nouvelle requ'#136'te, scripts, actualiser.');
    HelpBox(#13#10#13#10 + 'Requ'#136'te : F5 ex'#130'cute le texte (ou la s'#130'lection) ; chaque instruction (s'#130'par'#130'e ');
    HelpBox('par ; ou GO) donne un onglet R'#130'sultats ; Messages : lignes touch'#130'es et erreurs. Une table en ');
    HelpBox('fichier ouverte par SELECT * (ou ses colonnes) se modifie dans la grille (F2 ou double clic).');
  End
  Else
  Begin
    HelpBox('F5 ou Ctrl+E ex'#130'cuter, Echap arr'#136'ter, Ctrl+N nouvelle requ'#136'te, Ctrl+O ouvrir, Ctrl+S enregistrer, ');
    HelpBox('Ctrl+F4 fermer, Ctrl+Tab requ'#136'te suivante.' + #13#10);
    HelpBox('Ctrl+Z annuler, Ctrl+Y r'#130'tablir, Ctrl+X/C/V, Ctrl+A tout, Ctrl+F rechercher, F3 suivant, ');
    HelpBox('Ctrl+H remplacer, Ctrl+G aller '#133' la ligne, Ctrl+Maj+C commentaire --, Ctrl+U minuscules.' + #13#10);
    HelpBox('F8 Explorateur d''objets, Ctrl+R volet des r'#130'sultats, Tab passe de l'''#130'diteur '#133' la grille et '#133' ');
    HelpBox('l''arbre.' + #13#10);
    HelpBox('Arbre : fl'#138'ches, + et - d'#130'plier, Entr'#130'e ouvrir, F5 actualiser. Grille : fl'#138'ches, Pg pr'#130'c/suiv, ');
    HelpBox('F2 modifier, Ctrl+C copier.');
  End;
  BufAddC(HelpBuf, 0);
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, LongInt(HelpBuf.P), Z2('SQL Developer - Aide'), 0,
                         MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
  BufFree(HelpBuf);
End;

Procedure CopyText(S : String);
Var T : PBytes; N : LongInt;
Begin
  N := Length(S);
  GetMem(T, N + 1);
  If N > 0 Then Move(S[1], T^[0], N);
  T^[N] := 0;
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    Dummy := WinSetClipbrdData(Hab, LongInt(T), 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
  FreeMem(T, N + 1);
End;

{ ouvrir une table en fichier : connexion "dossier" + SELECT * }
Procedure OpenTableFile(N : String);
Var S, K, D, P : LongInt; Dir : String;
Begin
  If (Length(N) < 2) Or (N[2] <> ':') Then N := JoinPath(CurDir, N);
  If FmtOfExt(ExtOf(N)) = ftNone Then
  Begin
    MsgErr('Type de table non reconnu : ' + N + ' (DBF, CSV, DAT, MYD).');
    Exit;
  End;
  If FtOpen(N) < 0 Then
  Begin
    MsgErr(FtErr);
    Exit;
  End;
  Dir := DirOf(N);
  If (Length(Dir) = 2) And (Dir[2] = ':') Then Dir := Dir + '\';
  S := -1;
  For K := 0 To MaxSrv - 1 Do
    If SUsed[K] And (SKind[K] = skDir) And (UpStr(SPath[K]) = UpStr(Dir)) Then S := K;
  If S < 0 Then
  Begin
    S := SrvNew(skDir);
    If S < 0 Then Exit;
    SPath[S] := Dir;
    P := NAddSrv(S);
    SaveIni;
  End;
  P := NFindSrv(S);
  If (P >= 0) And Not NOpen[P] Then ExpandNode(P);
  D := NewQuery(S, '');
  If D < 0 Then Exit;
  DName[D] := JoinPath(CurDir, NameOf(N) + '.sql');
  DocSetText(D, 'SELECT * FROM ' + NameOf(N));
  ExecDoc(D, False);
End;

Procedure DoCmd(C : LongInt);
Var K, N, S, I : LongInt; T : String;
Begin
  Case C Of
    cmNewQuery :
      Begin
        S := SelSrv;
        If (NSel >= 0) And (NSel < NNode) Then T := NodeDb(NSel)
        Else If Cur >= 0 Then T := DDb[Cur] Else T := '';
        Dummy := NewQuery(S, T);
      End;
    cmOpen :
      Begin
        DlgReset;
        DlgField('Fichier SQL :', JoinPath(CurDir, ''));
        If InputBox('Ouvrir un fichier SQL', 'Ouvrir') And (Trim(DgV[0]) <> '') Then
        Begin
          T := Trim(DgV[0]);
          If (Length(T) < 2) Or (T[2] <> ':') Then T := JoinPath(CurDir, T);
          If FmtOfExt(ExtOf(T)) <> ftNone Then OpenTableFile(T) Else OpenFile(T);
        End;
      End;
    cmOpenTable :
      Begin
        DlgReset;
        DlgField('Table (.DBF, .CSV, .DAT, .MYD) :', JoinPath(CurDir, ''));
        If InputBox('Ouvrir une table', 'Ouvrir') And (Trim(DgV[0]) <> '') Then OpenTableFile(Trim(DgV[0]));
      End;
    cmOpenMdf, cmConnMdf : Dummy := ConnDialog(skMdf, -1);
    cmConnPg : Dummy := ConnDialog(skPg, -1);
    cmConnMy : Dummy := ConnDialog(skMy, -1);
    cmConnDir : Dummy := ConnDialog(skDir, -1);
    cmConnMenu : Popup(5, TbX[4], CH - TbH);
    cmConnProps :
      Begin
        S := SelSrv;
        If S >= 0 Then Dummy := ConnDialog(SKind[S], S);
      End;
    cmDisconn :
      Begin
        S := SelSrv;
        If S >= 0 Then
        Begin
          ConnCloseSrv(S);
          I := NFindSrv(S);
          If I >= 0 Then
          Begin
            NClear(I);
            NOpen[I] := False;
            NSel := I;
          End;
          StatusMsg := SrvLabel(S) + ' : d'#130'connect'#130'.';
        End;
      End;
    cmConnDel :
      Begin
        S := SelSrv;
        If (S >= 0) And Ask('Supprimer la connexion ' + SrvLabel(S) + ' de l''Explorateur d''objets ?') Then
        Begin
          ConnCloseSrv(S);
          I := NFindSrv(S);
          If I >= 0 Then
          Begin
            NClear(I);
            NDel(I);
          End;
          For K := 0 To MaxDoc - 1 Do If DUsed[K] And (DSrv[K] = S) Then DSrv[K] := -1;
          SUsed[S] := False;
          SaveIni;
        End;
      End;
    cmSave : Dummy := Ord(SaveDoc(Cur));
    cmSaveAs : If Cur >= 0 Then Dummy := Ord(SaveAs(Cur));
    cmSaveRes : SaveResCsv;
    cmClose : CloseDoc(Cur);
    cmCloseAll :
      While Cur >= 0 Do
      Begin
        N := NDoc;
        CloseDoc(Cur);
        If NDoc = N Then Break;
      End;
    cmQuit : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    cmUndo : If Cur >= 0 Then
             Begin
               UndoRedo(Cur, False);
               Changed;
             End;
    cmRedo : If Cur >= 0 Then
             Begin
               UndoRedo(Cur, True);
               Changed;
             End;
    cmCut : CutSel;
    cmCopy : If Pane = pnGrid Then GridCopy(False) Else CopySel;
    cmCopy + 1000 : GridCopy(True);
    cmPaste : PasteClip;
    cmDelete : DeleteKey;
    cmSelAll : SelectAll;
    cmIndent : IndentLines(1);
    cmUnindent : IndentLines(-1);
    cmUpper : CaseSel(True);
    cmLower : CaseSel(False);
    cmComment : CommentSel;
    cmFind, cmReplace :
      If Cur >= 0 Then
      Begin
        DlgReset;
        If HasSel(Cur) And (DAY[Cur] = DCY[Cur]) Then
          FindS := Copy(LStr(Cur, DCY[Cur]), MinI(DAX[Cur], DCX[Cur]) + 1, Abs(DCX[Cur] - DAX[Cur]));
        DlgField('Rechercher :', FindS);
        If C = cmReplace Then DlgField('Remplacer par :', ReplS);
        DgChkS := 'Respecter les majuscules et minuscules';
        DgChk := FindCase;
        If C = cmReplace Then
        Begin
          If InputBox('Remplacer', 'Remplacer tout') Then
          Begin
            FindS := DgV[0]; ReplS := DgV[1]; FindCase := DgChk;
            N := ReplaceAll;
            StatusMsg := IStr(N) + ' remplacement(s).';
          End;
        End
        Else If InputBox('Rechercher', 'Rechercher') Then
        Begin
          FindS := DgV[0]; FindCase := DgChk;
          If HasSel(Cur) Then
          Begin
            DCX[Cur] := MinI(DCX[Cur], DAX[Cur]);
            DCY[Cur] := MinI(DCY[Cur], DAY[Cur]);
          End;
          FindNext;
        End;
        Changed;
      End;
    cmFindNext : FindNext;
    cmGoto :
      If Cur >= 0 Then
      Begin
        DlgReset;
        DlgField('Ligne (1 - ' + IStr(DN[Cur]) + ') :', IStr(DCY[Cur] + 1));
        If InputBox('Aller '#133' la ligne', 'Aller') Then
        Begin
          N := SVal(Trim(DgV[0]));
          If N > 0 Then
          Begin
            DSel[Cur] := False;
            DCY[Cur] := MinI(N, DN[Cur]) - 1; DCX[Cur] := 0;
            DTop[Cur] := MaxI(0, DCY[Cur] - Rows Div 2);
            Changed;
          End;
        End;
      End;
    cmShowExp :
      Begin
        ShowExp := Not ShowExp;
        SetCheck(cmShowExp, ShowExp);
        If Not ShowExp And (Pane = pnTree) Then Pane := pnEdit;
        Redraw;
      End;
    cmShowRes :
      Begin
        ShowRes := Not ShowRes;
        SetCheck(cmShowRes, ShowRes);
        If Not ShowRes And (Pane = pnGrid) Then Pane := pnEdit;
        Redraw;
      End;
    cmNums :
      Begin
        ShowNums := Not ShowNums;
        SetCheck(cmNums, ShowNums);
        Redraw;
      End;
    cmCsvHdr :
      Begin
        CsvHeaders := Not CsvHeaders;
        SetCheck(cmCsvHdr, CsvHeaders);
        For K := 0 To MaxFTab - 1 Do If FT[K].Used And (FT[K].Fmt = ftCsv) Then FtClose(K);
        SaveIni;
      End;
    cmCopyHdr :
      Begin
        CopyHdr := Not CopyHdr;
        SetCheck(cmCopyHdr, CopyHdr);
      End;
    cmRefresh :
      Begin
        If (NSel >= 0) And (NSel < NNode) Then RefreshNode(NSel);
        For K := 0 To MaxFTab - 1 Do If FT[K].Used Then FtClose(K);
        InvalTree;
      End;
    cmCollapseAll :
      Begin
        For K := 0 To NNode - 1 Do If NLev[K] = 0 Then NOpen[K] := False;
        NSel := -1;
        K := 0;
        While K < NNode Do
          If NLev[K] = 0 Then
          Begin
            NSel := K;
            Inc(K);
          End
          Else Inc(K);
        NSel := MinI(0, NNode - 1);
        NTop := 0;
        InvalTree;
      End;
    cmExec, cmExecSel : ExecDoc(Cur, C = cmExecSel);
    cmStop : StopDoc(Cur);
    cmChangeConn :
      If Cur >= 0 Then
      Begin
        If (NSel < 0) Or (NSel >= NNode) Then Msg('Choisissez d''abord un serveur ou une base dans l''Explorateur d''objets.')
        Else
        Begin
          DSrv[Cur] := NSrvI[NSel];
          DDb[Cur] := NodeDb(NSel);
          StatusMsg := 'Connexion : ' + SrvLabel(DSrv[Cur]) + ', base ' + DDb[Cur] + '.';
          Redraw;
        End;
      End;
    cmChangeDb :
      If (Cur >= 0) And (DSrv[Cur] >= 0) Then
      Begin
        DlgReset;
        DlgField('Base de donn'#130'es :', DDb[Cur]);
        If InputBox('Base de donn'#130'es de la requ'#136'te', 'Choisir') And (Trim(DgV[0]) <> '') Then
        Begin
          DDb[Cur] := Trim(DgV[0]);
          Redraw;
        End;
      End;
    cmResGrid :
      If Cur >= 0 Then
      Begin
        DTab[Cur] := 0;
        Redraw;
      End;
    cmResMsg :
      If Cur >= 0 Then
      Begin
        DTab[Cur] := DRsN[Cur];
        Redraw;
      End;
    cmTop1000, cmEditRows : SelectTop(NSel);
    cmEditRows + 1000 : CellEditBegin;
    cmScrCreate, cmScrSelect, cmScrInsert, cmScrUpdate, cmScrDelete : Script(NSel, C);
    cmNewTable :
      Begin
        S := SelSrv;
        If S >= 0 Then
        Begin
          If SKind[S] = skDir Then
          Begin
            Msg('Les tables en fichiers se cr'#130'ent avec leur programme d''origine (dBASE...) ; SQL Developer ' +
                'les lit, les interroge et les modifie.');
            Exit;
          End;
          If (NSel >= 0) And (NSel < NNode) Then T := NodeDb(NSel) Else T := '';
          I := NewQuery(S, T);
          If I >= 0 Then
          Begin
            If SKind[S] = skMy Then
              DocSetText(I, 'CREATE TABLE NouvelleTable (~  Id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,~' +
                            '  Nom VARCHAR(50) NOT NULL,~  Cree DATETIME NULL~);~')
            Else If SKind[S] = skPg Then
              DocSetText(I, 'CREATE TABLE NouvelleTable (~  Id SERIAL PRIMARY KEY,~  Nom VARCHAR(50) NOT NULL,~' +
                            '  Cree TIMESTAMP NULL~);~')
            Else
              DocSetText(I, 'CREATE TABLE NouvelleTable (~  Id INT NOT NULL,~  Nom VARCHAR(50) NULL~);~');
            DMod[I] := True;
          End;
        End;
      End;
    cmCopyName :
      If (NSel >= 0) And (NSel < NNode) Then
      Begin
        If NObjStr(NSel) <> '' Then CopyText(NObjStr(NSel)) Else CopyText(NNameStr(NSel));
        StatusMsg := 'Nom copi'#130'.';
      End;
    cmDocFirst + 1, cmDocFirst + 2 :
      If NDoc > 1 Then
      Begin
        K := 0;
        While (K < NDoc) And (Order[K] <> Cur) Do Inc(K);
        If C = cmDocFirst + 2 Then K := (K + NDoc - 1) Mod NDoc Else K := (K + 1) Mod NDoc;
        SetCur(Order[K]);
      End;
    cmHelp : ShowHelp(False);
    cmKeys : ShowHelp(True);
    cmAbout : Msg('SQL Developer pour OS/2-0, version 1.0' + #13#10 +
                  'PostgreSQL, MariaDB et MySQL, SQL Server (.MDF par SQLCMD),' + #13#10 +
                  'tables dBASE, CSV, Clarion, Btrieve et MyISAM.');
  Else
    If (C >= cmDbFirst) And (C < cmDbFirst + DbListN) And (Cur >= 0) Then
    Begin
      DDb[Cur] := DbListItem(C - cmDbFirst);
      Redraw;
    End;
  End;
  InvalStatus;
End;

{ ==================================================================== }
{ Souris                                                                }
{ ==================================================================== }

Function TbHit(X, Y : LongInt) : LongInt;
Var I : LongInt;
Begin
  TbHit := -1;
  If (Y < 3) Or (Y > 26) Then Exit;
  For I := 0 To NTb - 1 Do
    If (TbCmd[I] <> 0) And (X >= TbX[I]) And (X < TbX[I] + 24) Then TbHit := I;
End;

Procedure ScrollTo(Top : LongInt);
Begin
  If Cur < 0 Then Exit;
  If Top > MaxTop Then Top := MaxTop;
  If Top < 0 Then Top := 0;
  If Top <> DTop[Cur] Then
  Begin
    DTop[Cur] := Top;
    InvalEditor;
  End;
End;

Procedure ScrollLeft(L : LongInt);
Begin
  If Cur < 0 Then Exit;
  If L < 0 Then L := 0;
  If L <> DLeft[Cur] Then
  Begin
    DLeft[Cur] := L;
    InvalEditor;
  End;
End;

{ grille : nombre de lignes et de colonnes du resultat affiche }
Function GNRow : LongInt;
Begin
  If CurRes(Cur) < 0 Then GNRow := 0 Else GNRow := Rss[DRs[CurRes(Cur)]].NRow;
End;

Function GNCol : LongInt;
Begin
  If CurRes(Cur) < 0 Then GNCol := 0 Else GNCol := Rss[DRs[CurRes(Cur)]].NCol;
End;

Procedure GridShowSel;
Var X, Cx, W : LongInt;
Begin
  If Cur < 0 Then Exit;
  If DGSelR[Cur] < DGTop[Cur] Then DGTop[Cur] := DGSelR[Cur];
  If DGSelR[Cur] >= DGTop[Cur] + GRows Then DGTop[Cur] := DGSelR[Cur] - GRows + 1;
  If DGSelC[Cur] < DGLeft[Cur] Then DGLeft[Cur] := DGSelC[Cur];
  X := CurRes(Cur);
  If X >= 0 Then
  Begin
    ColWidths(X);
    Cx := GridColX(X, DGSelC[Cur]);
    W := DColW[X]^[DGSelC[Cur]];
    While (Cx + W > GX1) And (DGLeft[Cur] < DGSelC[Cur]) Do
    Begin
      Inc(DGLeft[Cur]);
      Cx := GridColX(X, DGSelC[Cur]);
    End;
  End;
  InvalResults;
End;

{ clic dans la zone des resultats }
Procedure ResClick(X, Y : LongInt; Dbl : Boolean);
Var I, N, Rx, Cx, C, T, Th, Ty, Max_ : LongInt;
Begin
  If (Y >= RtY) And (Y < RtY + ResTabH) Then
  Begin
    N := DRsN[Cur];
    For I := 0 To N Do
      If (X >= RtX[I]) And (X < RtX[I + 1]) Then
      Begin
        If I = N Then DTab[Cur] := N Else DTab[Cur] := I;
        DGTop[Cur] := 0; DGLeft[Cur] := 0; DGSelR[Cur] := 0; DGSelC[Cur] := 0;
      End;
    InvalResults;
    Exit;
  End;
  If Y < GY0 Then Exit;
  Pane := pnGrid;
  Rx := CurRes(Cur);
  { barre verticale }
  If X >= VsX Then
  Begin
    If Rx >= 0 Then Max_ := MaxI(0, GNRow - GRows) Else Max_ := MaxI(0, MsgLines(Cur) - GRows);
    If Y < GY0 + ScrW Then
    Begin
      If Rx >= 0 Then Dec(DGTop[Cur]) Else Dec(DMsgTop[Cur]);
    End
    Else If Y >= GY1 - ScrW Then
    Begin
      If Rx >= 0 Then Inc(DGTop[Cur]) Else Inc(DMsgTop[Cur]);
    End
    Else
    Begin
      T := GY1 - GY0 - 2 * ScrW;
      Th := MaxI(10, T * GRows Div (Max_ + GRows));
      If Max_ > 0 Then
      Begin
        If Rx >= 0 Then Ty := GY0 + ScrW + (T - Th) * DGTop[Cur] Div Max_ Else Ty := GY0 + ScrW + (T - Th) * DMsgTop[Cur] Div Max_;
        If (Y >= Ty) And (Y < Ty + Th) Then
        Begin
          Drag := dGVThumb; DragOff := Y - Ty;
          Dummy := WinSetCapture(HWND_DESKTOP, Client);
        End
        Else If Y < Ty Then
        Begin
          If Rx >= 0 Then DGTop[Cur] := DGTop[Cur] - GRows Else DMsgTop[Cur] := DMsgTop[Cur] - GRows;
        End
        Else If Rx >= 0 Then DGTop[Cur] := DGTop[Cur] + GRows Else DMsgTop[Cur] := DMsgTop[Cur] + GRows;
      End;
    End;
    If DGTop[Cur] < 0 Then DGTop[Cur] := 0;
    If DMsgTop[Cur] < 0 Then DMsgTop[Cur] := 0;
    InvalResults;
    Exit;
  End;
  If Rx < 0 Then Exit;
  { barre horizontale : une colonne a la fois }
  If Y >= GY1 Then
  Begin
    If X < EdX0 + (VsX - EdX0) Div 2 Then Dec(DGLeft[Cur]) Else Inc(DGLeft[Cur]);
    If DGLeft[Cur] < 0 Then DGLeft[Cur] := 0;
    If DGLeft[Cur] > MaxI(0, GNCol - 1) Then DGLeft[Cur] := MaxI(0, GNCol - 1);
    InvalResults;
    Exit;
  End;
  ColWidths(Rx);
  { en-tete : bord d'une colonne = largeur }
  If Y < GY0 + GridRowH Then
  Begin
    For C := DGLeft[Cur] To GNCol - 1 Do
    Begin
      Cx := GridColX(Rx, C) + DColW[Rx]^[C];
      If Abs(X - Cx) <= 3 Then
      Begin
        Drag := dColRs; DragCol := C; DragOff := X - DColW[Rx]^[C];
        Dummy := WinSetCapture(HWND_DESKTOP, Client);
        Exit;
      End;
    End;
    Exit;
  End;
  { cellule }
  I := DGTop[Cur] + (Y - GY0 - GridRowH) Div GridRowH;
  If I >= GNRow Then Exit;
  C := -1;
  For N := DGLeft[Cur] To GNCol - 1 Do
  Begin
    Cx := GridColX(Rx, N);
    If (X >= Cx) And (X < Cx + DColW[Rx]^[N]) Then C := N;
  End;
  If X < EdX0 + 1 + RnW Then C := DGSelC[Cur];
  If C < 0 Then Exit;
  DGSelR[Cur] := I; DGSelC[Cur] := C;
  InvalResults;
  If Dbl Then CellEditBegin;
End;

Procedure Click(X, Y : LongInt; Dbl, Shift : Boolean);
Var I, R, Nx, T, Th, Ty, Ny, Nx_ : LongInt;
Begin
  LastMx := X; LastMy := Y;
  If EdWin <> 0 Then CellEditEnd(True);
  If Y < TbH Then
  Begin
    If (X >= DbLblX) And (X < DbLblX + 56 + DbLblW) Then
    Begin
      Popup(4, DbLblX + 56, CH - TbH);
      Exit;
    End;
    I := TbHit(X, Y);
    If I >= 0 Then
    Begin
      TbDown := I;
      Drag := dToolbar;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
      InvalBand(0, 0, CW, TbH);
    End;
    Exit;
  End;
  If Y > Y1 Then Exit;
  { Explorateur d'objets }
  If ShowExp And (X < PanW) Then
  Begin
    Pane := pnTree;
    If Y >= Y0 + ExpHdrH Then
    Begin
      R := (Y - Y0 - ExpHdrH - 3) Div RowH;
      I := NTop + R;
      If (R >= 0) And (I < NNode) Then
      Begin
        Nx := 18 + NLev[I] * 14;
        If (X >= Nx - 17) And (X <= Nx - 7) And Not NLeaf[I] Then ToggleNode(I)
        Else
        Begin
          SelectNode(I);
          If Dbl Then
          Begin
            If (NKind[I] = nkTbl) Or (NKind[I] = nkView) Then SelectTop(I) Else ToggleNode(I);
          End;
        End;
      End;
    End;
    InvalTree;
    Exit;
  End;
  If ShowExp And (X < EdX0) Then
  Begin
    Drag := dSplitV;
    Dummy := WinSetCapture(HWND_DESKTOP, Client);
    Exit;
  End;
  { onglets des requetes }
  If (Y >= DtY) And (Y < DtY + DocTabH) Then
  Begin
    For I := 0 To NDoc - 1 Do
      If (X >= DtX[I]) And (X < DtX[I + 1]) Then SetCur(Order[I]);
    Exit;
  End;
  If Cur < 0 Then Exit;
  { volet des resultats }
  If ShowRes And (Y > EdBot) Then
  Begin
    If Y < RtY Then
    Begin
      Drag := dSplitH;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
      Exit;
    End;
    ResClick(X, Y, Dbl);
    InvalTree;
    Exit;
  End;
  Pane := pnEdit;
  InvalTree;
  { barre verticale de l'editeur }
  If (X >= VsX) And (Y < HsY) Then
  Begin
    If Y < EdTop + ScrW Then ScrollTo(DTop[Cur] - 1)
    Else If Y >= HsY - ScrW Then ScrollTo(DTop[Cur] + 1)
    Else
    Begin
      T := HsY - EdTop - 2 * ScrW;
      Th := MaxI(10, T * Rows Div (MaxTop + Rows));
      If Th > T Then Th := T;
      If MaxTop > 0 Then Ty := EdTop + ScrW + (T - Th) * DTop[Cur] Div MaxTop Else Ty := EdTop + ScrW;
      If Y < Ty Then ScrollTo(DTop[Cur] - Rows + 1)
      Else If Y >= Ty + Th Then ScrollTo(DTop[Cur] + Rows - 1)
      Else
      Begin
        Drag := dVThumb; DragOff := Y - Ty;
        Dummy := WinSetCapture(HWND_DESKTOP, Client);
      End;
    End;
    Exit;
  End;
  If Y >= HsY Then
  Begin
    If X >= VsX Then Exit;
    If X < EdX0 + ScrW Then ScrollLeft(DLeft[Cur] - 4)
    Else If X >= VsX - ScrW Then ScrollLeft(DLeft[Cur] + 4)
    Else
    Begin
      T := VsX - EdX0 - 2 * ScrW;
      Th := MaxI(10, T * Cols Div (HMax + Cols));
      If Th > T Then Th := T;
      Nx_ := EdX0 + ScrW + (T - Th) * DLeft[Cur] Div MaxI(1, HMax);
      If X < Nx_ Then ScrollLeft(DLeft[Cur] - Cols + 4)
      Else If X >= Nx_ + Th Then ScrollLeft(DLeft[Cur] + Cols - 4)
      Else
      Begin
        Drag := dHThumb; DragOff := X - Nx_;
        Dummy := WinSetCapture(HWND_DESKTOP, Client);
      End;
    End;
    Exit;
  End;
  { texte }
  HitText(X, Y, Ny, Nx);
  If ShowNums And (X <= EdX0 + GutW) Then
  Begin
    If Not Shift Then
    Begin
      DSel[Cur] := True; DAY[Cur] := Ny; DAX[Cur] := 0;
    End;
    If Ny < DN[Cur] - 1 Then
    Begin
      DCY[Cur] := Ny + 1; DCX[Cur] := 0;
    End
    Else
    Begin
      DCY[Cur] := Ny; DCX[Cur] := LLen(Cur, Ny);
    End;
  End
  Else
  Begin
    If Shift Then
    Begin
      If Not DSel[Cur] Then
      Begin
        DSel[Cur] := True; DAY[Cur] := DCY[Cur]; DAX[Cur] := DCX[Cur];
      End;
    End
    Else
    Begin
      DSel[Cur] := True; DAY[Cur] := Ny; DAX[Cur] := Nx;
    End;
    DCY[Cur] := Ny; DCX[Cur] := Nx;
    If Dbl Then SelectWord;
  End;
  DWant[Cur] := -1;
  DLastKind[Cur] := 0;
  CaretOn := True;
  Drag := dText;
  Dummy := WinSetCapture(HWND_DESKTOP, Client);
  InvalEditor;
  InvalStatus;
End;

Procedure MouseMove(X, Y : LongInt);
Var Ny, Nx, T, Th, Max_, Rx : LongInt;
Begin
  LastMx := X; LastMy := Y;
  Case Drag Of
    dText :
      If Cur >= 0 Then
      Begin
        If Y < TxY0 Then ScrollTo(DTop[Cur] - 1)
        Else If Y >= TxY0 + Rows * RowH Then ScrollTo(DTop[Cur] + 1);
        If X < TxX0 Then ScrollLeft(DLeft[Cur] - 1)
        Else If X >= VsX Then ScrollLeft(DLeft[Cur] + 1);
        HitText(X, Y, Ny, Nx);
        If (Ny <> DCY[Cur]) Or (Nx <> DCX[Cur]) Then
        Begin
          DCY[Cur] := Ny; DCX[Cur] := Nx;
          InvalEditor;
          InvalStatus;
        End;
      End;
    dSplitV :
      Begin
        PanW := MaxI(140, MinI(X, CW - 240));
        Redraw;
      End;
    dSplitH :
      If Cur >= 0 Then
      Begin
        DEdH[Cur] := MaxI(60, MinI(Y - EdTop, Y1 - EdTop - 80));
        InvalBand(EdX0, EdTop, CW, Y1 + 1);
      End;
    dVThumb :
      If Cur >= 0 Then
      Begin
        T := HsY - EdTop - 2 * ScrW;
        Th := MaxI(10, T * Rows Div (MaxTop + Rows));
        If T - Th > 0 Then ScrollTo((Y - DragOff - EdTop - ScrW) * MaxTop Div (T - Th));
      End;
    dHThumb :
      If Cur >= 0 Then
      Begin
        T := VsX - EdX0 - 2 * ScrW;
        Th := MaxI(10, T * Cols Div (HMax + Cols));
        If T - Th > 0 Then ScrollLeft((X - DragOff - EdX0 - ScrW) * HMax Div (T - Th));
      End;
    dGVThumb :
      If Cur >= 0 Then
      Begin
        Rx := CurRes(Cur);
        If Rx >= 0 Then Max_ := MaxI(0, GNRow - GRows) Else Max_ := MaxI(0, MsgLines(Cur) - GRows);
        T := GY1 - GY0 - 2 * ScrW;
        Th := MaxI(10, T * GRows Div (Max_ + GRows));
        If T - Th > 0 Then
        Begin
          If Rx >= 0 Then DGTop[Cur] := MaxI(0, MinI(Max_, (Y - DragOff - GY0 - ScrW) * Max_ Div (T - Th)))
          Else DMsgTop[Cur] := MaxI(0, MinI(Max_, (Y - DragOff - GY0 - ScrW) * Max_ Div (T - Th)));
          InvalResults;
        End;
      End;
    dColRs :
      If (Cur >= 0) And (CurRes(Cur) >= 0) Then
      Begin
        DColW[CurRes(Cur)]^[DragCol] := MaxI(24, MinI(800, X - DragOff));
        InvalResults;
      End;
  End;
End;

Procedure MouseUp(X, Y : LongInt);
Var I : LongInt;
Begin
  If Drag = dToolbar Then
  Begin
    I := TbHit(X, Y);
    TbDown := -1;
    InvalBand(0, 0, CW, TbH);
    If (I >= 0) Then
    Begin
      Dummy := WinSetCapture(HWND_DESKTOP, 0);
      Drag := dNone;
      If TbCmd[I] = cmConnMenu Then Popup(5, TbX[I], CH - TbH) Else DoCmd(TbCmd[I]);
      Exit;
    End;
  End
  Else If (Drag = dText) And (Cur >= 0) Then
  Begin
    If Not HasSel(Cur) Then DSel[Cur] := False;
  End;
  If Drag <> dNone Then Dummy := WinSetCapture(HWND_DESKTOP, 0);
  Drag := dNone;
End;

Procedure RightClick(X, Y : LongInt);
Var I, R : LongInt;
Begin
  If Y < TbH Then Exit;
  If EdWin <> 0 Then CellEditEnd(True);
  If ShowExp And (X < PanW) Then
  Begin
    Pane := pnTree;
    R := (Y - Y0 - ExpHdrH - 3) Div RowH;
    If (Y >= Y0 + ExpHdrH) And (R >= 0) And (NTop + R < NNode) Then SelectNode(NTop + R) Else NSel := -1;
    InvalTree;
    Popup(1, X, CH - 1 - Y);
    Exit;
  End;
  If X < EdX0 Then Exit;
  If (Y >= DtY) And (Y < DtY + DocTabH) Then
  Begin
    For I := 0 To NDoc - 1 Do
      If (X >= DtX[I]) And (X < DtX[I + 1]) Then
      Begin
        SetCur(Order[I]);
        Popup(3, X, CH - 1 - Y);
      End;
    Exit;
  End;
  If Cur < 0 Then Exit;
  If ShowRes And (Y >= GY0) Then
  Begin
    If CurRes(Cur) >= 0 Then
    Begin
      ResClick(X, Y, False);
      Popup(2, X, CH - 1 - Y);
    End;
    Exit;
  End;
  If Y <= EdBot Then
  Begin
    Pane := pnEdit;
    Popup(0, X, CH - 1 - Y);
  End;
End;

{ ==================================================================== }
{ Clavier                                                               }
{ ==================================================================== }

Function TreeKey(Fl, Ch_, Vk : LongInt) : Boolean;
Var I : LongInt;
Begin
  TreeKey := True;
  I := NSel;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
    Case Vk Of
      VK_UP : If I > 0 Then SelectNode(I - 1);
      VK_DOWN : If I < NNode - 1 Then SelectNode(I + 1);
      VK_HOME : SelectNode(0);
      VK_END : SelectNode(NNode - 1);
      VK_PAGEUP : SelectNode(MaxI(0, I - TreeRows + 1));
      VK_PAGEDOWN : SelectNode(MinI(NNode - 1, I + TreeRows - 1));
      VK_RIGHT : If (I >= 0) And Not NOpen[I] Then ToggleNode(I) Else If I < NNode - 1 Then SelectNode(I + 1);
      VK_LEFT :
        If I >= 0 Then
        Begin
          If NOpen[I] Then ToggleNode(I)
          Else
          Begin
            While (I > 0) And (NLev[I - 1] >= NLev[NSel]) Do Dec(I);
            If I > 0 Then SelectNode(I - 1);
          End;
        End;
      VK_ENTER, VK_NEWLINE :
        If I >= 0 Then
        Begin
          If (NKind[I] = nkTbl) Or (NKind[I] = nkView) Then SelectTop(I) Else ToggleNode(I);
        End;
      VK_F5 : DoCmd(cmRefresh);
    Else
      TreeKey := False;
    End
  Else If ((Fl And KC_CHAR) <> 0) And ((Ch_ = Ord('+')) Or (Ch_ = Ord('-'))) And (I >= 0) Then ToggleNode(I)
  Else TreeKey := False;
End;

Function GridKey(Fl, Ch_, Vk : LongInt) : Boolean;
Var NR, NC : LongInt; Ctrl : Boolean;
Begin
  GridKey := True;
  NR := GNRow; NC := GNCol;
  Ctrl := (Fl And KC_CTRL) <> 0;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    Case Vk Of
      VK_UP : If DGSelR[Cur] > 0 Then Dec(DGSelR[Cur]);
      VK_DOWN : If DGSelR[Cur] < NR - 1 Then Inc(DGSelR[Cur]);
      VK_LEFT : If DGSelC[Cur] > 0 Then Dec(DGSelC[Cur]);
      VK_RIGHT : If DGSelC[Cur] < NC - 1 Then Inc(DGSelC[Cur]);
      VK_PAGEUP : DGSelR[Cur] := MaxI(0, DGSelR[Cur] - GRows + 1);
      VK_PAGEDOWN : DGSelR[Cur] := MaxI(0, MinI(NR - 1, DGSelR[Cur] + GRows - 1));
      VK_HOME :
        Begin
          DGSelC[Cur] := 0;
          If Ctrl Then DGSelR[Cur] := 0;
        End;
      VK_END :
        Begin
          DGSelC[Cur] := MaxI(0, NC - 1);
          If Ctrl Then DGSelR[Cur] := MaxI(0, NR - 1);
        End;
      VK_ENTER, VK_NEWLINE, VK_F2 : CellEditBegin;
    Else
      Begin
        GridKey := False;
        Exit;
      End;
    End;
    GridShowSel;
    Exit;
  End;
  GridKey := False;
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
  CaretOn := True;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    Case Vk Of
      VK_F1 : Begin DoCmd(cmHelp); Exit; End;
      VK_F3 : Begin DoCmd(cmFindNext); Exit; End;
      VK_F5 :
        Begin
          If Pane = pnTree Then DoCmd(cmRefresh) Else DoCmd(cmExec);
          Exit;
        End;
      VK_F8 : Begin DoCmd(cmShowExp); Exit; End;
      VK_F1 + 3 :
        If Ctrl Then
        Begin
          DoCmd(cmClose);
          Exit;
        End;
      VK_ESC :
        Begin
          If (Cur >= 0) And (DRun[Cur] <> 0) Then DoCmd(cmStop)
          Else If Pane <> pnEdit Then
          Begin
            Pane := pnEdit;
            Redraw;
          End;
          Exit;
        End;
      VK_TAB :
        If Ctrl Then
        Begin
          If Shift Then DoCmd(cmDocFirst + 2) Else DoCmd(cmDocFirst + 1);
          Exit;
        End
        Else If (Pane <> pnEdit) Or Shift And False Then
        Begin
          { Tab : editeur -> grille -> arbre -> editeur (hors editeur) }
          If Pane = pnGrid Then
          Begin
            If ShowExp Then Pane := pnTree Else Pane := pnEdit;
          End
          Else Pane := pnEdit;
          Redraw;
          Exit;
        End;
    End;
  End;
  If Ctrl And ((Fl And KC_CHAR) <> 0) Or (Ctrl And (Ch_ > 0) And (Ch_ < 128)) Then
  Begin
    K := Ch_;
    If (K >= 1) And (K <= 26) Then K := K + 96;
    If (K >= 65) And (K <= 90) Then K := K + 32;
    Case K Of
      Ord('n') : Begin DoCmd(cmNewQuery); Exit; End;
      Ord('o') : Begin DoCmd(cmOpen); Exit; End;
      Ord('s') : Begin DoCmd(cmSave); Exit; End;
      Ord('e') : Begin DoCmd(cmExec); Exit; End;
      Ord('r') : Begin DoCmd(cmShowRes); Exit; End;
      Ord('z') : Begin DoCmd(cmUndo); Exit; End;
      Ord('y') : Begin DoCmd(cmRedo); Exit; End;
      Ord('x') : Begin DoCmd(cmCut); Exit; End;
      Ord('c') :
        Begin
          If Shift And (Pane = pnEdit) Then DoCmd(cmComment) Else DoCmd(cmCopy);
          Exit;
        End;
      Ord('v') : Begin DoCmd(cmPaste); Exit; End;
      Ord('a') : Begin DoCmd(cmSelAll); Exit; End;
      Ord('f') : Begin DoCmd(cmFind); Exit; End;
      Ord('h') : Begin DoCmd(cmReplace); Exit; End;
      Ord('g') : Begin DoCmd(cmGoto); Exit; End;
      Ord('w') : Begin DoCmd(cmClose); Exit; End;
      Ord('u') :
        Begin
          If Shift Then DoCmd(cmUpper) Else DoCmd(cmLower);
          Exit;
        End;
    End;
  End;
  If (Pane = pnTree) And ShowExp Then
  Begin
    If TreeKey(Fl, Ch_, Vk) Then Exit;
  End;
  If (Pane = pnGrid) And (Cur >= 0) Then
  Begin
    If GridKey(Fl, Ch_, Vk) Then Exit;
    Key := False;
    Exit;
  End;
  If (Cur >= 0) And EditKey(Fl, Ch_, Vk) Then
  Begin
    Pane := pnEdit;
    Exit;
  End;
  Key := False;
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

{ /OUT : ecrire les resultats de la requete active et quitter }
Procedure WriteOut;
Var B : TBuf; K, R, C, Rs : LongInt; S : String; Null : Boolean;
Begin
  BufInit(B);
  If Cur >= 0 Then
  Begin
    For K := 0 To DRsN[Cur] - 1 Do
    Begin
      Rs := DRs[Cur * MaxRes + K];
      BufAdd(B, '== R'#130'sultats ' + IStr(K + 1) + #13#10);
      For C := 0 To Rss[Rs].NCol - 1 Do
      Begin
        If C > 0 Then BufAddC(B, Ord('|'));
        BufAdd(B, RsColName(Rs, C));
      End;
      BufAdd(B, #13#10);
      For R := 0 To Rss[Rs].NRow - 1 Do
      Begin
        For C := 0 To Rss[Rs].NCol - 1 Do
        Begin
          If C > 0 Then BufAddC(B, Ord('|'));
          S := RsCell(Rs, R, C, Null);
          If Null Then S := 'NULL';
          BufAdd(B, S);
        End;
        BufAdd(B, #13#10);
      End;
    End;
    BufAdd(B, '== Messages' + #13#10);
    { chaque ligne de message commence par sa sorte (E erreur, I information, T temps) }
    R := 1;
    For K := 0 To DMsg[Cur].Len - 1 Do
      If DMsg[Cur].P^[K] = 10 Then
      Begin
        BufAdd(B, #13#10);
        R := 1;
      End
      Else If R = 1 Then R := 0
      Else BufAddC(B, DMsg[Cur].P^[K]);
  End;
  Dummy := Ord(WriteAll(OutFile, B.P, B.Len));
  BufFree(B);
End;

Function ClientProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; X, Y, K, Fl : LongInt;
Begin
  ClientProc := 0;
  Case Msg_ Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
        If EdWin <> 0 Then CellEditEnd(False);
        Layout;
        Redraw;
      End;
    WM_PAINT : Paint(H);
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
      Begin
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        Click(S16(Mp1), CH - 1 - S16(Mp1 Shr 16), Msg_ = WM_BUTTON1DBLCLK, (Hi16(Mp2) And KC_SHIFT) <> 0);
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
        If Drag <> dNone Then MouseMove(X, Y);
        LastMx := X; LastMy := Y;
        K := -1;
        If (Y < TbH) And (Drag = dNone) Then K := TbHit(X, Y);
        If (K >= 0) And (StatusMsg <> TbTip[K]) Then
        Begin
          If Not TipOn Then TipSave := StatusMsg;
          StatusMsg := TbTip[K];
          TipOn := True;
          InvalStatus;
        End
        Else If (K < 0) And TipOn Then
        Begin
          StatusMsg := TipSave;
          TipOn := False;
          InvalStatus;
        End;
        K := 0;
        If ShowExp And (Y >= Y0) And (Y <= Y1) And (X >= PanW) And (X < EdX0) Then K := 8
        Else If (Drag = dSplitV) Or (Drag = dColRs) Then K := 8
        Else If (Drag = dSplitH) Or ((Cur >= 0) And ShowRes And (X >= EdX0) And (Y > EdBot) And (Y < RtY)) Then K := 9
        Else If (Cur >= 0) And (X >= TxX0) And (X < VsX) And (Y >= EdTop) And (Y < HsY) Then K := 2;
        If K <> 0 Then
        Begin
          Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, K, 0));
          ClientProc := 1;
        End
        Else ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
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
        If ShowExp And (LastMx < PanW) Then
        Begin
          NTop := MaxI(0, NTop + K);
          InvalTree;
        End
        Else If (Cur >= 0) And ShowRes And (LastMy > EdBot) Then
        Begin
          If CurRes(Cur) >= 0 Then DGTop[Cur] := MaxI(0, MinI(GNRow - GRows, DGTop[Cur] + K))
          Else DMsgTop[Cur] := MaxI(0, DMsgTop[Cur] + K);
          If DGTop[Cur] < 0 Then DGTop[Cur] := 0;
          InvalResults;
        End
        Else If Cur >= 0 Then ScrollTo(DTop[Cur] + K);
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1);
        If (EdWin <> 0) And ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) Then
        Begin
          If (Hi16(Mp2) = VK_ENTER) Or (Hi16(Mp2) = VK_NEWLINE) Then
          Begin
            CellEditEnd(True);
            ClientProc := 1;
            Exit;
          End;
          If Hi16(Mp2) = VK_ESC Then
          Begin
            CellEditEnd(False);
            ClientProc := 1;
            Exit;
          End;
        End;
        If Key(Mp1, Mp2) Then ClientProc := 1
        Else ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
      End;
    WM_COMMAND : DoCmd(Lo16(Mp1));
    WM_TIMER :
      If Lo16(Mp1) = 2 Then
      Begin
        For K := 1 To 20 Do
        Begin
          If NJob = 0 Then Break;
          JobPump;
        End;
        If AutoRun And (NJob = 0) And (OutFile <> '') And (Cur >= 0) And (DRun[Cur] = 0) Then
        Begin
          WriteOut;
          OutFile := '';
          Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
        End;
      End
      Else
      Begin
        If Drag = dText Then MouseMove(LastMx, LastMy);
        CaretOn := Not CaretOn;
        InvalCaret;
      End;
    WM_SETFOCUS :
      Begin
        HasFocus := Lo16(Mp2) <> 0;
        InvalCaret;
      End;
    WM_CLOSE :
      Begin
        For K := 0 To MaxDoc - 1 Do
          If DUsed[K] And DMod[K] Then
            If Not CanClose(K) Then Exit;
        Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
      End;
  Else
    ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

{ /PG hote:port:utilisateur:mot de passe:base (et /MY) }
Function ArgSrv(Kind : LongInt; A : String) : LongInt;
Var S, P, K : LongInt; F : Array[0..4] Of String;
Begin
  ArgSrv := -1;
  S := SrvNew(Kind);
  If S < 0 Then Exit;
  For K := 0 To 4 Do F[K] := '';
  K := 0;
  For P := 1 To Length(A) Do
    If (A[P] = ':') And (K < 4) Then Inc(K) Else F[K] := F[K] + A[P];
  SHost[S] := F[0]; SPortN[S] := SVal(F[1]); SUser[S] := F[2]; SPass[S] := F[3]; SDb[S] := F[4];
  If SPortN[S] <= 0 Then If Kind = skPg Then SPortN[S] := 5432 Else SPortN[S] := 3306;
  P := NAddSrv(S);
  ArgSrv := S;
End;

Procedure Main;
Var Fl, Sw, Sh, Fw, Fh, K, S, LastS, D : LongInt; A, U : String; Run : Boolean;
Begin
  NDoc := 0; Cur := -1;
  For K := 0 To MaxDoc - 1 Do
  Begin
    DUsed[K] := False; DNoName[K] := False; DSrv[K] := -1; BufInit(DMsg[K]); DRsN[K] := 0;
  End;
  For K := 0 To MaxDoc * MaxRes - 1 Do
  Begin
    DRs[K] := -1; DRsT[K] := -1; DRsMap[K] := Nil; DRsCM[K] := Nil; DColW[K] := Nil; DRsMapN[K] := 0;
  End;
  For K := 0 To MaxSrv - 1 Do SUsed[K] := False;
  For K := 0 To MaxDbConn - 1 Do CSrv[K] := -1;
  DbInit;
  BufInit(Tmp); BufInit(Clip); BufInit(NText); BufInit(MdfMsg); BufInit(DbList); BufInit(TkTxt);
  LAttr := Nil; LAttrCap := 0;
  NNode := 0; NTop := 0; NSel := -1; NIdNext := 1;
  NJob := 0; JobTimer := False; EdWin := 0;
  ShowNums := True; ShowExp := True; ShowRes := True; InsMode := True; CaretOn := True; HasFocus := True;
  CopyHdr := False; CsvHeaders := True;
  FindS := ''; ReplS := ''; FindCase := False;
  Pane := pnEdit; Drag := dNone; NewCount := 0; CtxMenu := 0; TipOn := False;
  StatusMsg := 'Pr'#136't.';
  OutFile := ''; AutoRun := False;
  A := ParamStr(0);
  MyDir := DirOf(A);
  TmpDir := FindTemp;
  SqlCmdExe := FindExe('SQLCMD.EXE');
  CurDir := 'C:\';
  If FExists('D:\') And Not FOpenWrite('C:\SQLDEV.TMP', K) Then CurDir := 'D:\'
  Else DosClose(K);
  Dummy := DosDelete(Z('C:\SQLDEV.TMP'));
  { connexions memorisees : C:\SQLDEV.INI, ou D:\ si C: est en lecture seule (CD-ROM) }
  IniName := 'C:\SQLDEV.INI';
  If Not FExists(IniName) And FExists('D:\SQLDEV.INI') Then IniName := 'D:\SQLDEV.INI';
  If Not FExists(IniName) Then
    If FOpenWrite(IniName, K) Then
    Begin
      DosClose(K);
      Dummy := DosDelete(Z(IniName));
    End
    Else IniName := 'D:\SQLDEV.INI';
  ToolbarInit;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('SQLDEV'), LongInt(@ClientProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('SQLDEV'), Z2('SQL Developer'), 0, 0, 0,
                              LongInt(@Client));
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
  PanW := Fw Div 4 + 30;
  CW := Fw - 8; CH := Fh - 40;
  Y0 := TbH; Y1 := CH - SbH - 1;
  LoadIni;
  BuildMenu;
  { parametres : fichiers .SQL, tables, .MDF ; /DIR /PG /MY /RUN /OUT }
  LastS := -1; Run := False;
  K := 1;
  While K <= ParamCount Do
  Begin
    A := ParamStr(K);
    U := UpStr(A);
    If (U = '/DIR') And (K < ParamCount) Then
    Begin
      Inc(K);
      S := SrvNew(skDir);
      If S >= 0 Then
      Begin
        SPath[S] := ParamStr(K);
        D := NAddSrv(S);
        LastS := S;
      End;
    End
    Else If (U = '/PG') And (K < ParamCount) Then
    Begin
      Inc(K);
      LastS := ArgSrv(skPg, ParamStr(K));
    End
    Else If (U = '/MY') And (K < ParamCount) Then
    Begin
      Inc(K);
      LastS := ArgSrv(skMy, ParamStr(K));
    End
    Else If U = '/RUN' Then Run := True
    Else If (U = '/OUT') And (K < ParamCount) Then
    Begin
      Inc(K);
      OutFile := ParamStr(K);
    End
    Else If ExtOf(A) = 'MDF' Then
    Begin
      S := SrvNew(skMdf);
      If S >= 0 Then
      Begin
        SPath[S] := A;
        D := NAddSrv(S);
        LastS := S;
      End;
    End
    Else If FmtOfExt(ExtOf(A)) <> ftNone Then OpenTableFile(A)
    Else
    Begin
      OpenFile(A);
      If (Cur >= 0) And (LastS >= 0) Then
      Begin
        DSrv[Cur] := LastS;
        DDb[Cur] := SrvDefDb(LastS);
      End;
    End;
    Inc(K);
  End;
  { serveurs donnes en parametre : deplies dans l'arbre }
  If LastS >= 0 Then
  Begin
    D := NFindSrv(LastS);
    If D >= 0 Then
    Begin
      NSel := D;
      ExpandNode(D);
    End;
  End;
  If (Cur < 0) Then Dummy := NewQuery(LastS, '');
  If (Cur >= 0) And (DSrv[Cur] < 0) And (LastS >= 0) Then
  Begin
    DSrv[Cur] := LastS;
    DDb[Cur] := SrvDefDb(LastS);
  End;
  Layout;
  ShowNode;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 500);
  If Not JobTimer Then
  Begin
    Dummy := WinStartTimer(Hab, Client, 2, 20);
    JobTimer := True;
  End;
  If Run And (Cur >= 0) Then
  Begin
    AutoRun := OutFile <> '';
    ExecDoc(Cur, False);
  End;
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@GQmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@GQmsg));
  Dummy := WinDestroyWindow(Frame);
End;

BEGIN
  Main;
END.
