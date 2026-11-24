{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: WEBDEV - Web Developer, editeur de pages Web (HTML, ASP,
                PSP, PHP, CSS, JavaScript) dans le genre de HomeSite, pour
                le Presentation Manager d'OS/2-0.
}

Program WebDev;

{$R-,S-,I-}

{ Compilation : OS2PC APPS\WEBDEV.PAS WEBDEV.EXE

  Web Developer (dossier Developer Kit du bureau) est l'editeur des pages
  Web d'OS/2-0, dans le genre de HomeSite :
    - a gauche, le panneau des ressources : l'arbre des dossiers (lecteurs
      et sous-dossiers, deplies a la demande) et, dessous, la liste des
      fichiers du dossier choisi (double clic ou Entree : ouvrir) ;
    - a droite, l'editeur : numeros de ligne, coloration syntaxique selon
      l'extension (.htm et .html : HTML avec ses <script> et <style> ;
      .asp : HTML et VBScript entre <% %> ; .psp : HTML et Pascal Server
      Pages ; .php : HTML et PHP entre <?php ?> ; .css ; .js), lignes de
      longueur quelconque, onglets des documents ouverts en bas ;
    - en haut, la barre d'outils et la barre de balises (onglets Commun,
      Polices, Tableaux, Formulaires, Listes, Script) : un bouton entoure
      la selection de la balise choisie ;
    - menus deroulants d'OS/2 : Fichier, Edition, Recherche, Affichage,
      Balises, Outils, ? ; barre d'etat (ligne, colonne, insertion ou
      refrappe, langage, encodage, fichier modifie).
  Edition : annuler et retablir (plusieurs niveaux), couper, copier,
  coller (presse-papiers de PM), rechercher, remplacer, aller a la ligne,
  retrait automatique, Tab et Maj+Tab sur la selection, selection a la
  souris et au clavier, molette. Encodage : un fichier UTF-8 est affiche
  en CP850 et reenregistre en UTF-8 ; s'il contient des caracteres hors de
  CP850, ses octets sont gardes tels quels.
  Outils : Parcourir (F12) ouvre la page dans le Navigateur Web d'OS/2-0,
  par http://localhost/ si elle est dans un site du Serveur Web en marche
  (les pages PSP et ASP sont alors executees), sinon par file:/// ;
  Executer la page (Ctrl+F9) l'execute (PSP, ASP, PHP) par WEBSRV /PSPOUT
  et montre le resultat dans un nouvel onglet.

  Parametres : fichiers a ouvrir. }

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
  BS_PUSHBUTTON = 0; BS_AUTOCHECKBOX = 2; BS_DEFAULT = $0400; ES_AUTOSCROLL = 4; ES_MARGIN = 8;
  EM_SETTEXTLIMIT = $0143; BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_CHECKED = $2000; MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_YESNOCANCEL = 5; MB_INFORMATION = $30; MB_WARNING = $20; MB_ERROR = $40;
  MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6; MBID_NO = 7; MBID_CANCEL = 2;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08; VK_ESC = $0F;
  VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14; VK_LEFT = $15; VK_UP = $16;
  VK_RIGHT = $17; VK_DOWN = $18; VK_INSERT = $1A; VK_DELETE = $1B; VK_ENTER = $1E;
  VK_F1 = $20; VK_F3 = $22; VK_F5 = $24; VK_F9 = $28; VK_F12 = $2B;
  SB_LINEUP = 1; SB_LINEDOWN = 2;
  { couleurs de PM }
  cBlue = 1; cRed = 2; cPink = 3; cGreen = 4; cCyan = 5; cYellow = 6; cGray = 8; cNavy = 9; cMaroon = 10;
  cDPink = 11; cDGreen = 12; cTeal = 13; cBrown = 14; cSilver = 15; cWhite = -2; cBlack = -1;
  { dimensions }
  TbH = 30; QbH = 46; SbH = 20; EdTabH = 20; DocTabH = 20; RowH = 16; ScrW = 16; TabStop = 4;
  { langages }
  lgText = 0; lgHtml = 1; lgAsp = 2; lgPsp = 3; lgPhp = 4; lgCss = 5; lgJs = 6;
  MaxDoc = 16; MaxUndo = 4000; MaxNode = 1200; MaxFile = 1500;

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
  If (X = 'HTM') Or (X = 'HTML') Or (X = 'SHTML') Or (X = 'XHTML') Or (X = 'XML') Or (X = 'SVG') Then LangOf := lgHtml
  Else If (X = 'ASP') Or (X = 'ASA') Or (X = 'INC') Then LangOf := lgAsp
  Else If X = 'PSP' Then LangOf := lgPsp
  Else If (X = 'PHP') Or (X = 'PHTML') Or (X = 'PHP3') Or (X = 'PHP4') Or (X = 'PHP5') Then LangOf := lgPhp
  Else If X = 'CSS' Then LangOf := lgCss
  Else If (X = 'JS') Or (X = 'JSON') Or (X = 'MJS') Then LangOf := lgJs
  Else LangOf := lgText;
End;

Function LangName(L : LongInt) : String;
Begin
  Case L Of
    lgHtml : LangName := 'HTML';
    lgAsp : LangName := 'ASP (VBScript)';
    lgPsp : LangName := 'PSP (Pascal)';
    lgPhp : LangName := 'PHP';
    lgCss : LangName := 'CSS';
    lgJs : LangName := 'JavaScript';
  Else
    LangName := 'Texte';
  End;
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
{ Coloration syntaxique                                                 }
{ ==================================================================== }

{ Etat d'une ligne (au debut) :
    bits 0-3   HTML : 0 texte, 1 balise, 2 valeur "...", 3 valeur '...',
               4 commentaire <!-- -->, 5 declaration <! >
    bits 4-7   bloc : 0 aucun, 1 serveur (retour au HTML), 2 script client
               (JavaScript), 3 style (CSS), 4 serveur dans un script,
               5 serveur dans un style
    bits 8-11  dans le bloc : 0 code, 1 chaine "...", 2 chaine '...',
               3 commentaire /* */, 4 commentaire (* *), 5 commentaire { },
               6 gabarit `...`
    bits 12-15 balise <script> (1) ou <style> (2) en cours
    bits 16-19 classe de la balise en cours (couleur)
    bits 20-21 CSS : 1 entre accolades, 2 dans une valeur }

Const
  kTxt = 0; kTag = 1; kTbl = 2; kA = 3; kImg = 4; kForm = 5; kScr = 6; kVal = 7; kEnt = 8; kCmt = 9;
  kDecl = 10; kKw = 1; kStr = 6; kCCmt = 3; kNum = 2; kVar = 4; kDelim = 8; kObj = 5; kSel = 1; kProp = 2;
  kSrvBg = $10;
  ColTab : Array[0..15] Of LongInt = (cBlack, cNavy, cTeal, cDGreen, cDPink, cBrown, cMaroon, cBlue, cRed, cGray,
                                      cTeal, cBlack, cBlack, cBlack, cBlack, cBlack);

  KwVb1 = ' and as byref byval call case class const dim do each else elseif empty end eqv erase error exit explicit false for function get if imp in is let loop me mod new next not nothing null on option or ';
  KwVb2 = ' preserve private property public randomize redim rem resume select set step sub then to true until wend while with xor response request server session application ';
  KwPas1 = ' and array as begin break case const continue div do downto else end except exit false file finally for function goto if in inherited is mod nil not object of or ';
  KwPas2 = ' procedure program raise record repeat set shl shr string then to true try type until uses var while with xor write writeln database databaseconnection recordset ';
  KwPhp1 = ' abstract and array as break case catch class clone const continue declare default do echo else elseif empty enddeclare endfor endforeach endif endswitch endwhile extends final ';
  KwPhp2 = ' finally fn for foreach function global goto if implements include include_once instanceof insteadof interface isset list match namespace new null or print private protected public ';
  KwPhp3 = ' require require_once return static switch throw trait true false try unset use var while xor yield self parent die exit ';
  KwJs1 = ' async await break case catch class const continue debugger default delete do else export extends false finally for function if import in instanceof let new null of return super ';
  KwJs2 = ' switch this throw true try typeof undefined var void while with yield document window console ';
  KwCss = ' important inherit initial none auto block inline flex grid absolute relative fixed bold normal solid ';

Var
  LAttr : PBytes;
  LAttrCap : LongInt;
  LxP : PBytes;
  LxN : LongInt;

Function StInit(Lang : LongInt) : LongInt;
Begin
  If Lang = lgJs Then StInit := 2 Shl 4
  Else If Lang = lgCss Then StInit := 3 Shl 4
  Else StInit := 0;
End;

Function LxC(I : LongInt) : LongInt;
Begin
  If (I < 0) Or (I >= LxN) Then LxC := 0 Else LxC := LxP^[I];
End;

Function LxLo(I : LongInt) : LongInt;
Var C : LongInt;
Begin
  C := LxC(I);
  If (C >= 65) And (C <= 90) Then C := C + 32;
  LxLo := C;
End;

{ le texte en I commence par S (S en minuscules) ? }
Function LxMat(I : LongInt; S : String) : Boolean;
Var K : LongInt;
Begin
  LxMat := False;
  If I + Length(S) > LxN Then Exit;
  For K := 1 To Length(S) Do If LxLo(I + K - 1) <> Ord(S[K]) Then Exit;
  LxMat := True;
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

{ mot-cle du langage de code (1 VBScript, 2 Pascal, 3 PHP, 4 JavaScript, 5 CSS) }
Function IsKw(Kind : LongInt; W : String) : Boolean;
Begin
  If Kind <> 4 Then W := LoStr(W);
  W := ' ' + W + ' ';
  Case Kind Of
    1 : IsKw := (Pos(W, KwVb1) > 0) Or (Pos(W, KwVb2) > 0);
    2 : IsKw := (Pos(W, KwPas1) > 0) Or (Pos(W, KwPas2) > 0);
    3 : IsKw := (Pos(W, KwPhp1) > 0) Or (Pos(W, KwPhp2) > 0) Or (Pos(W, KwPhp3) > 0);
    4 : IsKw := (Pos(W, KwJs1) > 0) Or (Pos(W, KwJs2) > 0);
    5 : IsKw := Pos(W, KwCss) > 0;
  Else
    IsKw := False;
  End;
End;

{ classe de couleur d'une balise d'apres son nom }
Function TagClass(W : String) : LongInt;
Begin
  W := ' ' + LoStr(W) + ' ';
  If Pos(W, ' table tr td th thead tbody tfoot caption col colgroup ') > 0 Then TagClass := kTbl
  Else If W = ' a ' Then TagClass := kA
  Else If Pos(W, ' img map area picture source video audio canvas svg object embed ') > 0 Then TagClass := kImg
  Else If Pos(W, ' form input select option textarea button label fieldset legend optgroup ') > 0 Then
    TagClass := kForm
  Else If Pos(W, ' script style noscript ') > 0 Then TagClass := kScr
  Else TagClass := kTag;
End;

{ ouverture d'un bloc serveur en I : longueur du delimiteur (0 : aucun) }
Function SrvOpen(Lang, I : LongInt) : LongInt;
Begin
  SrvOpen := 0;
  If LxC(I) <> 60 Then Exit;
  If (Lang = lgAsp) Or (Lang = lgPsp) Then
  Begin
    If LxC(I + 1) = 37 Then
    Begin
      If (LxC(I + 2) = 61) Or (LxC(I + 2) = 64) Then SrvOpen := 3 Else SrvOpen := 2;
    End;
  End
  Else If Lang = lgPhp Then
  Begin
    If LxMat(I, '<?php') Then SrvOpen := 5
    Else If LxMat(I, '<?=') Then SrvOpen := 3
    Else If (LxC(I + 1) = 63) And Not LxMat(I, '<?xml') Then SrvOpen := 2;
  End;
End;

Function SrvClose(Lang, I : LongInt) : Boolean;
Begin
  If Lang = lgPhp Then SrvClose := (LxC(I) = 63) And (LxC(I + 1) = 62)
  Else SrvClose := (LxC(I) = 37) And (LxC(I + 1) = 62);
End;

{ colore la ligne P[0..N-1] a partir de l'etat St ; rend l'etat de fin }
Function LexLine(Lang : LongInt; P : PBytes; N, St : LongInt) : LongInt;
Var H, B, S, Pd, Cl, Cb, I, J, C, Kind, Bg, A, K : LongInt; W : String;
    InSrv : Boolean;
Begin
  LxP := P; LxN := N;
  If (LAttr <> Nil) And (N > 0) Then FillChar(LAttr^[0], N, kTxt);
  If Lang = lgText Then
  Begin
    LexLine := 0;
    Exit;
  End;
  H := St And 15; B := (St Shr 4) And 15; S := (St Shr 8) And 15; Pd := (St Shr 12) And 15;
  Cl := (St Shr 16) And 15; Cb := (St Shr 20) And 3;
  If Cl = 0 Then Cl := kTag;
  I := 0;
  While I < N Do
  Begin
    C := P^[I];
    InSrv := (B = 1) Or (B = 4) Or (B = 5);
    { --- bloc serveur --- }
    If InSrv Then
    Begin
      If Lang = lgAsp Then Kind := 1 Else If Lang = lgPsp Then Kind := 2 Else Kind := 3;
      Bg := kSrvBg;
      { fin du bloc (sauf dans une chaine) }
      If ((S = 0) Or (S = 3) Or (S = 4) Or (S = 5) Or (Kind = 1)) And SrvClose(Lang, I) Then
      Begin
        LxSet(I, 2, kDelim Or Bg);
        I := I + 2;
        If B = 1 Then B := 0 Else If B = 4 Then B := 2 Else B := 3;
        S := 0;
        Continue;
      End;
      Case S Of
        1 :
          Begin
            LxSet(I, 1, kStr Or Bg);
            If (C = 92) And (Kind = 3) Then
            Begin
              LxSet(I + 1, 1, kStr Or Bg);
              Inc(I);
            End
            Else If C = 34 Then S := 0;
            Inc(I);
          End;
        2 :
          Begin
            LxSet(I, 1, kStr Or Bg);
            If (C = 92) And (Kind = 3) Then
            Begin
              LxSet(I + 1, 1, kStr Or Bg);
              Inc(I);
            End
            Else If C = 39 Then S := 0;
            Inc(I);
          End;
        3 :
          Begin
            LxSet(I, 1, kCCmt Or Bg);
            If (C = 42) And (LxC(I + 1) = 47) Then
            Begin
              LxSet(I + 1, 1, kCCmt Or Bg);
              Inc(I);
              S := 0;
            End;
            Inc(I);
          End;
        4 :
          Begin
            LxSet(I, 1, kCCmt Or Bg);
            If (C = 42) And (LxC(I + 1) = 41) Then
            Begin
              LxSet(I + 1, 1, kCCmt Or Bg);
              Inc(I);
              S := 0;
            End;
            Inc(I);
          End;
        5 :
          Begin
            LxSet(I, 1, kCCmt Or Bg);
            If C = 125 Then S := 0;
            Inc(I);
          End;
      Else
        Begin
          { code }
          If (C = 34) And (Kind <> 2) Then
          Begin
            S := 1; LxSet(I, 1, kStr Or Bg); Inc(I);
          End
          Else If (C = 39) And (Kind = 1) Then
          Begin
            { commentaire VBScript jusqu'a la fin de la ligne ou %> }
            J := I;
            While (J < N) And Not SrvClose(Lang, J) Do Inc(J);
            LxSet(I, J - I, kCCmt Or Bg);
            I := J;
          End
          Else If C = 39 Then
          Begin
            S := 2; LxSet(I, 1, kStr Or Bg); Inc(I);
          End
          Else If ((C = 47) And (LxC(I + 1) = 47)) Or ((C = 35) And (Kind = 3)) Then
          Begin
            J := I;
            While (J < N) And Not SrvClose(Lang, J) Do Inc(J);
            LxSet(I, J - I, kCCmt Or Bg);
            I := J;
          End
          Else If (C = 47) And (LxC(I + 1) = 42) And (Kind = 3) Then
          Begin
            S := 3; LxSet(I, 2, kCCmt Or Bg); I := I + 2;
          End
          Else If (C = 40) And (LxC(I + 1) = 42) And (Kind = 2) Then
          Begin
            S := 4; LxSet(I, 2, kCCmt Or Bg); I := I + 2;
          End
          Else If (C = 123) And (Kind = 2) Then
          Begin
            S := 5; LxSet(I, 1, kCCmt Or Bg); Inc(I);
          End
          Else If (C = 36) And (Kind = 3) And IsAl(LxC(I + 1)) Then
          Begin
            J := I + 1;
            While (J < N) And (IsAl(P^[J]) Or IsDg(P^[J])) Do Inc(J);
            LxSet(I, J - I, kVar Or Bg);
            I := J;
          End
          Else If IsDg(C) Or ((C = 35) And (Kind = 2) And IsDg(LxC(I + 1))) Or ((C = 36) And (Kind = 2)) Then
          Begin
            J := I + 1;
            While (J < N) And (IsDg(P^[J]) Or IsAl(P^[J]) Or (P^[J] = 46)) Do Inc(J);
            LxSet(I, J - I, kNum Or Bg);
            I := J;
          End
          Else If IsAl(C) Then
          Begin
            J := I;
            W := '';
            While (J < N) And (IsAl(P^[J]) Or IsDg(P^[J])) Do
            Begin
              If Length(W) < 40 Then W := W + Chr(P^[J]);
              Inc(J);
            End;
            If IsKw(Kind, W) Then A := kKw Else A := kTxt;
            LxSet(I, J - I, A Or Bg);
            I := J;
          End
          Else
          Begin
            LxSet(I, 1, kTxt Or Bg);
            Inc(I);
          End;
        End;
      End;
      Continue;
    End;
    { --- ouverture d'un bloc serveur (dans le HTML, un script ou un style) --- }
    J := SrvOpen(Lang, I);
    If (J > 0) And (S <> 3) Then
    Begin
      LxSet(I, J, kDelim Or kSrvBg);
      I := I + J;
      If B = 2 Then B := 4 Else If B = 3 Then B := 5 Else B := 1;
      S := 0;
      Continue;
    End;
    { --- script client (JavaScript) --- }
    If B = 2 Then
    Begin
      If (Lang <> lgJs) And LxMat(I, '</script') Then
      Begin
        B := 0; S := 0; H := 0;
        Continue;
      End;
      Case S Of
        1, 2, 6 :
          Begin
            LxSet(I, 1, kStr);
            If C = 92 Then
            Begin
              LxSet(I + 1, 1, kStr);
              Inc(I);
            End
            Else If ((S = 1) And (C = 34)) Or ((S = 2) And (C = 39)) Or ((S = 6) And (C = 96)) Then S := 0;
            Inc(I);
          End;
        3 :
          Begin
            LxSet(I, 1, kCCmt);
            If (C = 42) And (LxC(I + 1) = 47) Then
            Begin
              LxSet(I + 1, 1, kCCmt);
              Inc(I);
              S := 0;
            End;
            Inc(I);
          End;
      Else
        Begin
          If C = 34 Then S := 1 Else If C = 39 Then S := 2 Else If C = 96 Then S := 6;
          If S <> 0 Then
          Begin
            LxSet(I, 1, kStr); Inc(I);
          End
          Else If (C = 47) And (LxC(I + 1) = 47) Then
          Begin
            J := I;
            While (J < N) And Not LxMat(J, '</script') Do Inc(J);
            LxSet(I, J - I, kCCmt);
            I := J;
          End
          Else If (C = 47) And (LxC(I + 1) = 42) Then
          Begin
            S := 3; LxSet(I, 2, kCCmt); I := I + 2;
          End
          Else If IsDg(C) Then
          Begin
            J := I + 1;
            While (J < N) And (IsDg(P^[J]) Or IsAl(P^[J]) Or (P^[J] = 46)) Do Inc(J);
            LxSet(I, J - I, kNum);
            I := J;
          End
          Else If IsAl(C) Or (C = 36) Then
          Begin
            J := I;
            W := '';
            While (J < N) And (IsAl(P^[J]) Or IsDg(P^[J]) Or (P^[J] = 36)) Do
            Begin
              If Length(W) < 40 Then W := W + Chr(P^[J]);
              Inc(J);
            End;
            If IsKw(4, W) Then LxSet(I, J - I, kKw);
            I := J;
          End
          Else Inc(I);
        End;
      End;
      Continue;
    End;
    { --- feuille de style (CSS) --- }
    If B = 3 Then
    Begin
      If (Lang <> lgCss) And LxMat(I, '</style') Then
      Begin
        B := 0; S := 0; H := 0; Cb := 0;
        Continue;
      End;
      If S = 3 Then
      Begin
        LxSet(I, 1, kCmt);
        If (C = 42) And (LxC(I + 1) = 47) Then
        Begin
          LxSet(I + 1, 1, kCmt);
          Inc(I);
          S := 0;
        End;
        Inc(I);
      End
      Else If (C = 47) And (LxC(I + 1) = 42) Then
      Begin
        S := 3; LxSet(I, 2, kCmt); I := I + 2;
      End
      Else If (C = 34) Or (C = 39) Then
      Begin
        J := I + 1;
        While (J < N) And (P^[J] <> C) Do Inc(J);
        LxSet(I, J - I + 1, kVal);
        I := J + 1;
      End
      Else If C = 123 Then
      Begin
        Cb := 1; Inc(I);
      End
      Else If C = 125 Then
      Begin
        Cb := 0; Inc(I);
      End
      Else If (C = 58) And (Cb = 1) Then
      Begin
        Cb := 3; Inc(I);
      End
      Else If (C = 59) And (Cb = 3) Then
      Begin
        Cb := 1; Inc(I);
      End
      Else
      Begin
        If Cb = 0 Then
        Begin
          { selecteur : .classe et #id en rose fonce }
          If ((C = 46) Or (C = 35)) And IsAl(LxC(I + 1)) Then
          Begin
            J := I + 1;
            While (J < N) And (IsAl(P^[J]) Or IsDg(P^[J]) Or (P^[J] = 45)) Do Inc(J);
            LxSet(I, J - I, kVar);
            I := J;
          End
          Else
          Begin
            If C > 32 Then LxSet(I, 1, kSel);
            Inc(I);
          End;
        End
        Else If Cb = 1 Then
        Begin
          If C > 32 Then LxSet(I, 1, kProp);
          Inc(I);
        End
        Else
        Begin
          If C > 32 Then LxSet(I, 1, kVal);
          Inc(I);
        End;
      End;
      Continue;
    End;
    { --- HTML --- }
    Case H Of
      0 :
        Begin
          If LxMat(I, '<!--') Then
          Begin
            H := 4; LxSet(I, 4, kCmt); I := I + 4;
          End
          Else If (C = 60) And (LxC(I + 1) = 33) Then
          Begin
            H := 5; LxSet(I, 2, kDecl); I := I + 2;
          End
          Else If (C = 60) And (IsAl(LxC(I + 1)) Or ((LxC(I + 1) = 47) And IsAl(LxC(I + 2)))) Then
          Begin
            J := I + 1;
            If LxC(J) = 47 Then Inc(J);
            W := '';
            K := J;
            While (J < N) And (IsAl(P^[J]) Or IsDg(P^[J]) Or (P^[J] = 45) Or (P^[J] = 58)) Do
            Begin
              If Length(W) < 40 Then W := W + Chr(P^[J]);
              Inc(J);
            End;
            Cl := TagClass(W);
            Pd := 0;
            If LxC(I + 1) <> 47 Then
            Begin
              If LoStr(W) = 'script' Then Pd := 1 Else If LoStr(W) = 'style' Then Pd := 2;
            End;
            LxSet(I, J - I, Cl);
            H := 1;
            I := J;
          End
          Else If (C = 38) And (IsAl(LxC(I + 1)) Or (LxC(I + 1) = 35)) Then
          Begin
            J := I + 1;
            While (J < N) And (J - I < 12) And (IsAl(P^[J]) Or IsDg(P^[J]) Or (P^[J] = 35)) Do Inc(J);
            If LxC(J) = 59 Then
            Begin
              LxSet(I, J - I + 1, kEnt);
              I := J + 1;
            End
            Else Inc(I);
          End
          Else Inc(I);
        End;
      1 :
        Begin
          If C = 62 Then
          Begin
            LxSet(I, 1, Cl);
            Inc(I);
            H := 0;
            If Pd = 1 Then
            Begin
              B := 2; S := 0;
            End
            Else If Pd = 2 Then
            Begin
              B := 3; S := 0; Cb := 0;
            End;
            Pd := 0;
          End
          Else If C = 34 Then
          Begin
            H := 2; LxSet(I, 1, kVal); Inc(I);
          End
          Else If C = 39 Then
          Begin
            H := 3; LxSet(I, 1, kVal); Inc(I);
          End
          Else
          Begin
            LxSet(I, 1, Cl);
            Inc(I);
          End;
        End;
      2, 3 :
        Begin
          LxSet(I, 1, kVal);
          If ((H = 2) And (C = 34)) Or ((H = 3) And (C = 39)) Then H := 1;
          Inc(I);
        End;
      4 :
        Begin
          If LxMat(I, '-->') Then
          Begin
            LxSet(I, 3, kCmt); I := I + 3; H := 0;
          End
          Else
          Begin
            LxSet(I, 1, kCmt); Inc(I);
          End;
        End;
      5 :
        Begin
          LxSet(I, 1, kDecl);
          If C = 62 Then H := 0;
          Inc(I);
        End;
    Else
      Inc(I);
    End;
  End;
  { fin de ligne : les chaines d'une ligne et les commentaires de ligne s'arretent }
  If (B = 1) Or (B = 4) Or (B = 5) Then
  Begin
    If (Lang <> lgPhp) And ((S = 1) Or (S = 2)) Then S := 0;
  End
  Else If B = 2 Then
  Begin
    If (S = 1) Or (S = 2) Then S := 0;
  End;
  If Cl = kTag Then Cl := 0;
  LexLine := H Or (B Shl 4) Or (S Shl 8) Or (Pd Shl 12) Or (Cl Shl 16) Or (Cb Shl 20);
End;

{ etat au debut de la ligne Y (calcule les lignes manquantes) }
Function LineState(D, Y : LongInt) : LongInt;
Var K, St : LongInt; Sv : PBytes;
Begin
  If DStOk[D] < 1 Then
  Begin
    DSt[D]^[0] := StInit(DLang[D]);
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
Var N, C : LongInt; Q : PBytes;
Begin
  N := LLen(D, Y);
  If N + 16 > LAttrCap Then
  Begin
    If LAttrCap > 0 Then FreeMem(LAttr, LAttrCap);
    C := (N + 1024) And Not 1023;
    GetMem(LAttr, C);
    LAttrCap := C;
  End;
  Dummy := LexLine(DLang[D], LP(D, Y), N, LineState(D, Y));
  Q := LAttr;
  If Q = Nil Then Exit;
End;
{ ==================================================================== }
{ Panneau des ressources : arbre des dossiers et liste des fichiers     }
{ ==================================================================== }

Var
  FindBuf : Array[0..8191] Of Byte;
  { arbre (ordre d'affichage ; les enfants suivent leur parent) }
  NNode, NSel, NTop : LongInt;
  NName : Array[0..MaxNode - 1] Of String[79];
  NLev, NKids : Array[0..MaxNode - 1] Of LongInt;   { NKids : 0 inconnu, 1 oui, 2 non }
  NOpen : Array[0..MaxNode - 1] Of Boolean;
  { fichiers du dossier choisi }
  NFile, FSel, FTop : LongInt;
  FName : Array[0..MaxFile - 1] Of String[79];
  FSize, FDate, FTime : Array[0..MaxFile - 1] Of LongInt;
  CurDir : String;
  WebOnly : Boolean;

Function NodePath(I : LongInt) : String;
Var S : String; L, K : LongInt;
Begin
  If (I < 0) Or (I >= NNode) Then
  Begin
    NodePath := '';
    Exit;
  End;
  S := NName[I];
  L := NLev[I];
  K := I - 1;
  While (K >= 0) And (L > 0) Do
  Begin
    If NLev[K] = L - 1 Then
    Begin
      S := NName[K] + '\' + S;
      Dec(L);
    End;
    Dec(K);
  End;
  NodePath := S;
End;

{ chemin pour DosFindFirst (C: -> C:\) }
Function SpecDir(P : String) : String;
Begin
  If (Length(P) = 2) And (P[2] = ':') Then SpecDir := P + '\' Else SpecDir := P;
End;

Function JoinPath(D, N : String) : String;
Begin
  If (D <> '') And (D[Length(D)] = '\') Then JoinPath := D + N
  Else If D = '' Then JoinPath := N
  Else JoinPath := D + '\' + N;
End;

Function FindName(Off : LongInt) : String;
Var S : String; K, N : LongInt;
Begin
  N := FindBuf[Off + 28];
  If N > 255 Then N := 255;
  S[0] := Chr(N);
  For K := 1 To N Do S[K] := Chr(FindBuf[Off + 28 + K]);
  FindName := S;
End;

Function WebExt(N : String) : Boolean;
Var X : String;
Begin
  X := ' ' + ExtOf(N) + ' ';
  WebExt := Pos(X, ' HTM HTML SHTML XHTML ASP ASA INC PSP PHP PHTML CSS JS JSON XML SVG TXT CFG INI ') > 0;
End;

{ sous-dossiers de P (tries), inseres apres le noeud I }
Procedure ExpandNode(I : LongInt);
Var H, N, Rc, Off, A, K, J, Cnt, Lev : LongInt; S, P : String;
    Sub : Array[0..255] Of String[79];
Begin
  If (I < 0) Or (I >= NNode) Or NOpen[I] Then Exit;
  P := NodePath(I);
  Cnt := 0;
  H := -1; N := 64;
  Rc := DosFindFirst(Z(JoinPath(SpecDir(P), '*.*')), LongInt(@H), $37, LongInt(@FindBuf), SizeOf(FindBuf),
                     LongInt(@N), 1);
  While (Rc = 0) And (N > 0) Do
  Begin
    Off := 0;
    While N > 0 Do
    Begin
      A := RdL(LongInt(@FindBuf) + Off + 24);
      S := FindName(Off);
      If ((A And $10) <> 0) And (S <> '.') And (S <> '..') And (S <> '') And (Cnt < 256) Then
      Begin
        { tri par insertion (sans tenir compte de la casse) }
        J := Cnt;
        While (J > 0) And (UpStr(Sub[J - 1]) > UpStr(S)) Do
        Begin
          Sub[J] := Sub[J - 1];
          Dec(J);
        End;
        Sub[J] := S;
        Inc(Cnt);
      End;
      Dec(N);
      K := RdL(LongInt(@FindBuf) + Off);
      If K = 0 Then N := 0 Else Off := Off + K;
    End;
    N := 64;
    Rc := DosFindNext(H, LongInt(@FindBuf), SizeOf(FindBuf), LongInt(@N));
  End;
  If H <> -1 Then Dummy := DosFindClose(H);
  NOpen[I] := True;
  If Cnt = 0 Then
  Begin
    NKids[I] := 2;
    Exit;
  End;
  NKids[I] := 1;
  If NNode + Cnt > MaxNode Then Cnt := MaxNode - NNode;
  If Cnt <= 0 Then Exit;
  Lev := NLev[I] + 1;
  For K := NNode - 1 DownTo I + 1 Do
  Begin
    NName[K + Cnt] := NName[K]; NLev[K + Cnt] := NLev[K]; NKids[K + Cnt] := NKids[K]; NOpen[K + Cnt] := NOpen[K];
  End;
  For K := 0 To Cnt - 1 Do
  Begin
    NName[I + 1 + K] := Sub[K]; NLev[I + 1 + K] := Lev; NKids[I + 1 + K] := 0; NOpen[I + 1 + K] := False;
  End;
  NNode := NNode + Cnt;
  If NSel > I Then NSel := NSel + Cnt;
End;

Procedure CollapseNode(I : LongInt);
Var J, Cnt, K : LongInt;
Begin
  If (I < 0) Or (I >= NNode) Or Not NOpen[I] Then Exit;
  J := I + 1;
  While (J < NNode) And (NLev[J] > NLev[I]) Do Inc(J);
  Cnt := J - I - 1;
  For K := J To NNode - 1 Do
  Begin
    NName[K - Cnt] := NName[K]; NLev[K - Cnt] := NLev[K]; NKids[K - Cnt] := NKids[K]; NOpen[K - Cnt] := NOpen[K];
  End;
  NNode := NNode - Cnt;
  NOpen[I] := False;
  If (NSel > I) And (NSel < J) Then NSel := I
  Else If NSel >= J Then NSel := NSel - Cnt;
End;

{ liste des fichiers du dossier P }
Procedure ListFiles(P : String);
Var H, N, Rc, Off, A, K, J : LongInt; S : String;
Begin
  CurDir := P;
  NFile := 0; FSel := -1; FTop := 0;
  H := -1; N := 64;
  Rc := DosFindFirst(Z(JoinPath(SpecDir(P), '*.*')), LongInt(@H), $37, LongInt(@FindBuf), SizeOf(FindBuf),
                     LongInt(@N), 1);
  While (Rc = 0) And (N > 0) Do
  Begin
    Off := 0;
    While N > 0 Do
    Begin
      A := RdL(LongInt(@FindBuf) + Off + 24);
      S := FindName(Off);
      If ((A And $10) = 0) And (S <> '') And (NFile < MaxFile) And (Not WebOnly Or WebExt(S)) Then
      Begin
        J := NFile;
        While (J > 0) And (UpStr(FName[J - 1]) > UpStr(S)) Do
        Begin
          FName[J] := FName[J - 1]; FSize[J] := FSize[J - 1]; FDate[J] := FDate[J - 1]; FTime[J] := FTime[J - 1];
          Dec(J);
        End;
        FName[J] := S;
        FSize[J] := RdL(LongInt(@FindBuf) + Off + 16);
        FDate[J] := FindBuf[Off + 12] Or (FindBuf[Off + 13] Shl 8);
        FTime[J] := FindBuf[Off + 14] Or (FindBuf[Off + 15] Shl 8);
        Inc(NFile);
      End;
      Dec(N);
      K := RdL(LongInt(@FindBuf) + Off);
      If K = 0 Then N := 0 Else Off := Off + K;
    End;
    N := 64;
    Rc := DosFindNext(H, LongInt(@FindBuf), SizeOf(FindBuf), LongInt(@N));
  End;
  If H <> -1 Then Dummy := DosFindClose(H);
End;

{ arbre initial : les lecteurs }
Procedure TreeInit;
Var Cur_, Map, K : LongInt;
Begin
  NNode := 0; NSel := 0; NTop := 0;
  Cur_ := 0; Map := 0;
  Dummy := DosQueryCurrentDisk(LongInt(@Cur_), LongInt(@Map));
  If Map = 0 Then Map := 4;
  For K := 0 To 25 Do
    If ((Map And (1 Shl K)) <> 0) And (NNode < MaxNode) And (K <> 1) Then
    Begin
      NName[NNode] := Chr(65 + K) + ':';
      NLev[NNode] := 0; NKids[NNode] := 0; NOpen[NNode] := False;
      Inc(NNode);
    End;
End;

{ deplie l'arbre jusqu'au dossier P et le choisit }
Procedure TreeGoto(P : String);
Var I, J, St : LongInt; Part : String; Found : Boolean;
Begin
  P := UpStr(P);
  While (Length(P) > 3) And (P[Length(P)] = '\') Do Delete(P, Length(P), 1);
  If (Length(P) < 2) Or (P[2] <> ':') Then Exit;
  { lecteur }
  I := -1;
  For J := 0 To NNode - 1 Do If (NLev[J] = 0) And (UpStr(NName[J]) = Copy(P, 1, 2)) Then I := J;
  If I < 0 Then Exit;
  St := 4;
  While St <= Length(P) Do
  Begin
    J := St;
    While (J <= Length(P)) And (P[J] <> '\') Do Inc(J);
    Part := Copy(P, St, J - St);
    St := J + 1;
    If Part = '' Then Continue;
    ExpandNode(I);
    Found := False;
    J := I + 1;
    While (J < NNode) And (NLev[J] > NLev[I]) Do
    Begin
      If (NLev[J] = NLev[I] + 1) And (UpStr(NName[J]) = Part) Then
      Begin
        I := J;
        Found := True;
        Break;
      End;
      Inc(J);
    End;
    If Not Found Then Break;
  End;
  NSel := I;
  ListFiles(NodePath(I));
End;

{ date FAT -> texte }
Function DateStr(D, T : LongInt) : String;
Begin
  DateStr := Z2D(D And 31) + '/' + Z2D((D Shr 5) And 15) + '/' + IStr(1980 + (D Shr 9)) + ' ' + Z2D(T Shr 11) + ':' +
             Z2D((T Shr 5) And 63);
End;
{ ==================================================================== }
{ Fenetre : disposition et dessin                                       }
{ ==================================================================== }

Const
  MaxTb = 24; MaxQb = 120;
  { commandes }
  cmNew = 100; cmNewHtml = 101; cmNewAsp = 102; cmNewPsp = 103; cmNewPhp = 104; cmNewCss = 105; cmNewJs = 106;
  cmOpen = 110; cmSave = 111; cmSaveAs = 112; cmSaveAll = 113; cmClose = 114; cmCloseAll = 115; cmRevert = 116;
  cmQuit = 119;
  cmUndo = 120; cmRedo = 121; cmCut = 122; cmCopy = 123; cmPaste = 124; cmDelete = 125; cmSelAll = 126;
  cmIndent = 127; cmUnindent = 128; cmUpper = 129; cmLower = 130; cmComment = 131;
  cmFind = 140; cmFindNext = 141; cmReplace = 142; cmGoto = 143; cmMatchTag = 144;
  cmNums = 150; cmQBar = 151; cmPanel = 152; cmWebOnly = 153; cmRefresh = 154; cmSrvBg = 155;
  cmLangAuto = 160; cmLangText = 161; cmLangHtml = 162; cmLangAsp = 163; cmLangPsp = 164; cmLangPhp = 165;
  cmLangCss = 166; cmLangJs = 167;
  cmBrowse = 170; cmRun = 171; cmEncUtf8 = 172; cmEncRaw = 173; cmEndCrlf = 174; cmEndLf = 175;
  cmNewFolder = 176; cmOpenDir = 177;
  cmHelp = 180; cmAbout = 181; cmKeys = 182;
  cmTagFirst = 200;           { 200 + numero du bouton de la barre de balises }
  cmDocFirst = 400;           { 400 + numero d'onglet (menu Fenetre) }

Var
  Hab, Hmq, Frame, Client, MenuHw, Hps, CW, CH : LongInt;
  GQmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..8191] Of Byte;
  MenuLen : LongInt;
  { options }
  ShowNums, ShowQb, ShowPanel, InsMode, CaretOn, HasFocus, SrvBg : Boolean;
  { disposition (Y vers le bas) }
  PanW, TreeH, Y0, Y1, EdX0, TxX0, TxY0, GutW, VsX, HsY, DtY, Rows, Cols : LongInt;
  UX1, UY1, UX2, UY2 : LongInt;        { zone a repeindre }
  { barre d'outils }
  NTb : LongInt;
  TbCmd, TbX, TbIco : Array[0..MaxTb - 1] Of LongInt;
  TbTip : Array[0..MaxTb - 1] Of String[47];
  TbDown : LongInt;
  { barre de balises }
  QbTabN, QbCur, NQb : LongInt;
  QbTabS : Array[0..7] Of String[15];
  QbTabX : Array[0..8] Of LongInt;
  QbTab, QbX, QbW : Array[0..MaxQb - 1] Of LongInt;
  QbLab : Array[0..MaxQb - 1] Of String[15];
  QbOpen, QbClose : Array[0..MaxQb - 1] Of String;
  { onglets des documents }
  DtX : Array[0..MaxDoc] Of LongInt;
  StatusMsg : String;

Procedure PutZ(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do TxtBuf[K - 1] := Ord(S[K]);
  TxtBuf[Length(S)] := 0;
End;

Procedure FBar(X1, Y1, X2, Y2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  If (X2 < UX1) Or (X1 > UX2) Or (Y2 < UY1) Or (Y1 > UY2) Then Exit;
  Rc[0] := X1; Rc[1] := CH - 1 - Y2; Rc[2] := X2 + 1; Rc[3] := CH - Y1;
  Dummy := WinFillRect(Hps, LongInt(@Rc), C);
End;

Procedure HLine(X1, X2, Y, C : LongInt);
Begin
  FBar(X1, Y, X2, Y, C);
End;

Procedure VLine(X, Y1, Y2, C : LongInt);
Begin
  FBar(X, Y1, X, Y2, C);
End;

Procedure Box(X1, Y1, X2, Y2, C : LongInt);
Begin
  HLine(X1, X2, Y1, C); HLine(X1, X2, Y2, C);
  VLine(X1, Y1, Y2, C); VLine(X2, Y1, Y2, C);
End;

Procedure Edge(X1, Y1, X2, Y2, Lt, Dk : LongInt);
Begin
  HLine(X1, X2, Y1, Lt); VLine(X1, Y1, Y2, Lt);
  HLine(X1, X2, Y2, Dk); VLine(X2, Y1, Y2, Dk);
End;

Procedure Raised(X1, Y1, X2, Y2 : LongInt);
Begin
  FBar(X1, Y1, X2, Y2, cSilver);
  Edge(X1, Y1, X2, Y2, cWhite, cGray);
End;

Procedure Sunken(X1, Y1, X2, Y2, F : LongInt);
Begin
  FBar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, F);
  Edge(X1, Y1, X2, Y2, cGray, cWhite);
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

Procedure InvalBand(X1, Y1, X2, Y2 : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[0] := X1; Rc[1] := CH - Y2; Rc[2] := X2; Rc[3] := CH - Y1;
  Dummy := WinInvalidateRect(Client, LongInt(@Rc), 0);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ --- icones (grille de 16 x 16) --- }
Var
  IcX, IcY : LongInt;

Procedure IR(X1, Y1, X2, Y2, C : LongInt);
Begin
  FBar(IcX + X1, IcY + Y1, IcX + X2, IcY + Y2, C);
End;

Procedure IB(X1, Y1, X2, Y2, C : LongInt);
Begin
  IR(X1, Y1, X2, Y1, C); IR(X1, Y2, X2, Y2, C); IR(X1, Y1, X1, Y2, C); IR(X2, Y1, X2, Y2, C);
End;

Procedure IcoPage(X, Y, C : LongInt);
Begin
  IR(X + 2, Y + 1, X + 11, Y + 14, cWhite);
  IB(X + 2, Y + 1, X + 11, Y + 14, cBlack);
  IR(X + 9, Y + 1, X + 11, Y + 3, cSilver);
  IR(X + 9, Y + 1, X + 9, Y + 3, cBlack); IR(X + 9, Y + 3, X + 11, Y + 3, cBlack);
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

Procedure IcoDrive;
Begin
  IR(1, 5, 14, 11, cSilver);
  IB(1, 5, 14, 11, cBlack);
  IR(2, 10, 13, 10, cGray);
  IR(11, 7, 12, 8, cGreen);
End;

Procedure IcoFloppy(C : LongInt);
Begin
  IR(1, 1, 14, 14, C);
  IR(4, 1, 11, 5, cSilver);
  IR(9, 2, 10, 4, C);
  IR(3, 8, 12, 14, cWhite);
  IB(1, 1, 14, 14, cBlack);
End;

Procedure IcoTb(K : LongInt);
Var I : LongInt;
Begin
  Case K Of
    1 : IcoPage(0, 0, 0);
    2 :
      Begin
        IcoFolder(True);
      End;
    3 : IcoFloppy(cNavy);
    4 :
      Begin
        IcX := IcX - 2; IcY := IcY - 2;
        IcoFloppy(cTeal);
        IcX := IcX + 4; IcY := IcY + 4;
        IR(0, 0, 11, 11, cNavy);
        IR(3, 0, 8, 3, cSilver);
        IR(2, 6, 9, 11, cWhite);
        IB(0, 0, 11, 11, cBlack);
        IcX := IcX - 2; IcY := IcY - 2;
      End;
    5 :
      Begin
        { couper : ciseaux }
        For I := 0 To 6 Do
        Begin
          IR(3 + I, 1 + I, 3 + I, 1 + I, cBlack); IR(12 - I, 1 + I, 12 - I, 1 + I, cBlack);
        End;
        IB(2, 9, 6, 13, cBlack); IB(9, 9, 13, 13, cBlack);
      End;
    6 :
      Begin
        IcoPage(-1, -1, cGray);
        IcoPage(3, 2, cGray);
      End;
    7 :
      Begin
        IR(2, 2, 12, 14, cBrown); IB(2, 2, 12, 14, cBlack);
        IR(5, 1, 9, 3, cSilver); IB(5, 1, 9, 3, cBlack);
        IR(6, 6, 14, 15, cWhite); IB(6, 6, 14, 15, cBlack);
        IR(8, 9, 12, 9, cGray); IR(8, 11, 12, 11, cGray);
      End;
    8, 9 :
      Begin
        { annuler (fleche vers la gauche) ou retablir }
        For I := 0 To 4 Do
          If K = 8 Then IR(2 + I, 7 - I, 2 + I, 7 + I, cNavy) Else IR(13 - I, 7 - I, 13 - I, 7 + I, cNavy);
        If K = 8 Then
        Begin
          IR(6, 6, 12, 8, cNavy); IR(11, 8, 13, 12, cNavy);
        End
        Else
        Begin
          IR(3, 6, 9, 8, cNavy); IR(2, 8, 4, 12, cNavy);
        End;
      End;
    10, 11 :
      Begin
        { loupe }
        IR(3, 1, 8, 1, cBlack); IR(3, 8, 8, 8, cBlack); IR(1, 3, 1, 6, cBlack); IR(10, 3, 10, 6, cBlack);
        IR(2, 2, 2, 2, cBlack); IR(9, 2, 9, 2, cBlack); IR(2, 7, 2, 7, cBlack); IR(9, 7, 9, 7, cBlack);
        IR(2, 3, 9, 6, cCyan); IR(3, 2, 8, 7, cCyan);
        For I := 0 To 4 Do IR(9 + I, 9 + I, 10 + I, 10 + I, cBrown);
        If K = 11 Then
        Begin
          IR(10, 1, 15, 2, cRed); IR(13, 0, 13, 3, cRed);
        End;
      End;
    12 :
      Begin
        { globe }
        IR(5, 1, 10, 14, cBlue); IR(3, 2, 12, 13, cBlue); IR(2, 3, 13, 12, cBlue); IR(1, 5, 14, 10, cBlue);
        IR(4, 3, 7, 6, cGreen); IR(5, 7, 7, 10, cGreen); IR(9, 4, 12, 7, cGreen); IR(10, 9, 11, 12, cGreen);
      End;
    13 :
      Begin
        { executer (triangle vert) }
        For I := 0 To 6 Do IR(4 + I, 1 + I, 4 + I, 14 - I, cGreen);
        IR(4, 1, 4, 14, cDGreen);
      End;
    14 :
      Begin
        { aide }
        IR(4, 1, 11, 14, cBlue); IR(2, 3, 13, 12, cBlue);
        IR(6, 3, 9, 3, cWhite); IR(9, 4, 10, 6, cWhite); IR(7, 7, 9, 8, cWhite); IR(7, 9, 8, 9, cWhite);
        IR(7, 11, 8, 12, cWhite);
      End;
    15 :
      Begin
        { fermer }
        IcoPage(0, 0, 0);
        For I := 0 To 5 Do
        Begin
          IR(4 + I, 5 + I, 5 + I, 5 + I, cRed); IR(9 - I, 5 + I, 10 - I, 5 + I, cRed);
        End;
      End;
  End;
End;

{ icone d'un fichier d'apres son extension }
Procedure IcoFile(N : String);
Var L : LongInt;
Begin
  L := LangOf(N);
  Case L Of
    lgHtml : IcoPage(0, 0, cBlue);
    lgAsp : IcoPage(0, 0, cRed);
    lgPsp : IcoPage(0, 0, cDGreen);
    lgPhp : IcoPage(0, 0, cDPink);
    lgCss : IcoPage(0, 0, cTeal);
    lgJs : IcoPage(0, 0, cBrown);
  Else
    IcoPage(0, 0, cGray);
  End;
  If L <> lgText Then
  Begin
    { petit "e" bleu des pages Web }
    IR(1, 8, 6, 14, cWhite); IB(1, 8, 6, 14, cNavy);
    IR(2, 11, 5, 11, cNavy);
  End;
End;

{ ==================================================================== }
{ Disposition                                                           }
{ ==================================================================== }

Procedure Layout;
Var N, D : LongInt;
Begin
  Y0 := TbH;
  If ShowQb Then Y0 := Y0 + QbH;
  Y1 := CH - SbH - 1;
  If ShowPanel Then
  Begin
    If PanW > CW - 200 Then PanW := MaxI(120, CW - 200);
    If PanW < 120 Then PanW := 120;
    EdX0 := PanW + 4;
    If TreeH > Y1 - Y0 - 80 Then TreeH := MaxI(60, Y1 - Y0 - 80);
    If TreeH < 60 Then TreeH := 60;
  End
  Else EdX0 := 0;
  DtY := Y1 - DocTabH + 1;
  HsY := DtY - ScrW;
  VsX := CW - ScrW;
  D := 3; N := 1000;
  If Cur >= 0 Then
    While (DN[Cur] >= N) And (D < 9) Do
    Begin
      Inc(D);
      N := N * 10;
    End;
  If ShowNums Then GutW := D * 8 + 10 Else GutW := 4;
  TxX0 := EdX0 + 1 + GutW + 2;
  TxY0 := Y0 + 2;
  Rows := MaxI(1, (HsY - TxY0 - 1) Div RowH);
  Cols := MaxI(1, (VsX - TxX0 - 1) Div 8);
End;

Function MaxTop : LongInt;
Begin
  If Cur < 0 Then MaxTop := 0 Else MaxTop := MaxI(0, DN[Cur] - Rows + 1);
End;

{ le curseur reste visible }
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

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Procedure PaintToolbar;
Var I, X : LongInt;
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
      IcoTb(TbIco[I]);
    End;
  End;
End;

Procedure PaintQuickBar;
Var I, X, Y : LongInt;
Begin
  Y := TbH;
  FBar(0, Y, CW - 1, Y + QbH - 1, cSilver);
  HLine(0, CW - 1, Y + 19, cGray);
  { onglets }
  For I := 0 To QbTabN - 1 Do
  Begin
    X := QbTabX[I];
    If I = QbCur Then
    Begin
      FBar(X, Y + 1, QbTabX[I + 1] - 2, Y + 19, cSilver);
      HLine(X, QbTabX[I + 1] - 2, Y + 1, cWhite);
      VLine(X, Y + 1, Y + 19, cWhite);
      VLine(QbTabX[I + 1] - 2, Y + 1, Y + 19, cGray);
      OutTxt(X + 8, Y + 2, QbTabS[I], cBlack, cSilver);
    End
    Else
    Begin
      HLine(X + 1, QbTabX[I + 1] - 3, Y + 4, cWhite);
      VLine(X + 1, Y + 4, Y + 18, cWhite);
      VLine(QbTabX[I + 1] - 3, Y + 4, Y + 18, cGray);
      OutTxt(X + 8, Y + 3, QbTabS[I], cGray, cSilver);
    End;
  End;
  { boutons de l'onglet }
  For I := 0 To NQb - 1 Do
    If QbTab[I] = QbCur Then
    Begin
      X := QbX[I];
      Raised(X, Y + 22, X + QbW[I] - 1, Y + 43);
      OutTxt(X + 6, Y + 25, QbLab[I], cNavy, cSilver);
    End;
End;

Procedure PaintTree;
Var I, Y, X, R, Rows_, D : LongInt; S : String;
Begin
  Sunken(0, Y0, PanW - 1, Y0 + TreeH - 1, cWhite);
  Rows_ := MaxI(1, (TreeH - 6) Div RowH);
  If NTop > MaxI(0, NNode - Rows_) Then NTop := MaxI(0, NNode - Rows_);
  If NTop < 0 Then NTop := 0;
  For R := 0 To Rows_ - 1 Do
  Begin
    I := NTop + R;
    If I >= NNode Then Break;
    Y := Y0 + 3 + R * RowH;
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
    If NKids[I] <> 2 Then
    Begin
      FBar(X - 16, Y + 4, X - 8, Y + 12, cWhite);
      Box(X - 16, Y + 4, X - 8, Y + 12, cGray);
      HLine(X - 14, X - 10, Y + 8, cBlack);
      If Not NOpen[I] Then VLine(X - 12, Y + 6, Y + 10, cBlack);
    End;
    IcX := X; IcY := Y;
    If NLev[I] = 0 Then
    Begin
      If NName[I] = 'A:' Then IcoFloppy(cGray) Else IcoDrive;
    End
    Else IcoFolder(NOpen[I] Or (I = NSel));
    S := Fit(NName[I], PanW - X - 26);
    If I = NSel Then
    Begin
      FBar(X + 18, Y, X + 20 + Length(S) * 8, Y + 15, cNavy);
      OutTxt(X + 19, Y, S, cWhite, cNavy);
    End
    Else OutTxt(X + 19, Y, S, cBlack, cWhite);
  End;
End;

Function FileRows : LongInt;
Begin
  FileRows := MaxI(1, (Y1 - (Y0 + TreeH + 4 + 20) - 4) Div RowH);
End;

Procedure PaintFiles;
Var I, Y, R, Fy, Rows_, W : LongInt; S, Sz : String;
Begin
  Fy := Y0 + TreeH + 4;
  FBar(0, Y0 + TreeH, PanW - 1, Fy - 1, cSilver);
  Sunken(0, Fy, PanW - 1, Y1, cWhite);
  { en-tete des colonnes }
  Raised(1, Fy + 1, PanW - 2, Fy + 19);
  OutTxt(6, Fy + 2, Fit('Nom (' + IStr(NFile) + ')', PanW - 90), cBlack, cSilver);
  VLine(PanW - 76, Fy + 2, Fy + 18, cGray);
  OutTxt(PanW - 68, Fy + 2, 'Taille', cBlack, cSilver);
  Rows_ := FileRows;
  If FTop > MaxI(0, NFile - Rows_) Then FTop := MaxI(0, NFile - Rows_);
  If FTop < 0 Then FTop := 0;
  W := PanW - 100;
  For R := 0 To Rows_ - 1 Do
  Begin
    I := FTop + R;
    If I >= NFile Then Break;
    Y := Fy + 22 + R * RowH;
    IcX := 4; IcY := Y;
    IcoFile(FName[I]);
    S := Fit(FName[I], W);
    If FSize[I] < 1024 Then Sz := IStr(FSize[I]) + ' o'
    Else If FSize[I] < 1048576 Then Sz := IStr((FSize[I] + 1023) Div 1024) + ' Ko'
    Else Sz := IStr(FSize[I] Div 1048576) + ' Mo';
    If I = FSel Then
    Begin
      FBar(22, Y, 24 + Length(S) * 8, Y + 15, cNavy);
      OutTxt(23, Y, S, cWhite, cNavy);
    End
    Else OutTxt(23, Y, S, cBlack, cWhite);
    OutTxt(PanW - 8 - Length(Sz) * 8, Y, Sz, cGray, cWhite);
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

{ une ligne du texte }
Procedure PaintLine(R : LongInt);
Var D, Y, Yy, K, N, V, A, Nv, Fg, Bg, X, Y1s, X1s, Y2s, X2s, Ca, Sx : LongInt; Q : PBytes; S : String;
    InSel, Sel, Has : Boolean; Cs : String;
Begin
  D := Cur;
  Y := DTop[D] + R;
  Yy := TxY0 + R * RowH;
  If (Yy + RowH - 1 < UY1) Or (Yy > UY2) Then Exit;
  { numero de ligne }
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
            Fg := ColTab[Ca And 15];
            If ((Ca And kSrvBg) <> 0) And SrvBg Then Bg := cSilver Else Bg := cWhite;
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
      Fg := ColTab[Ca And 15];
      If ((Ca And kSrvBg) <> 0) And SrvBg Then Bg := cSilver Else Bg := cWhite;
    End;
    OutTxt(X, Yy, S, Fg, Bg);
    X := X + Length(S) * 8;
  End;
  { fin de ligne selectionnee }
  If Has And (Y >= Y1s) And (Y < Y2s) And (K >= N) Then
  Begin
    Sx := TxX0 + (VisCol(D, Y, N) - DLeft[D]) * 8;
    If Sx >= TxX0 Then FBar(Sx, Yy, Sx + 7, Yy + RowH - 1, cNavy);
  End;
  { curseur }
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

Procedure PaintEditor;
Var R, I, X, W : LongInt; S : String;
Begin
  { cadre }
  Box(EdX0, Y0, VsX - 1, HsY - 1, cGray);
  If Cur < 0 Then
  Begin
    FBar(EdX0 + 1, Y0 + 1, VsX - 1, HsY - 1, cGray);
    OutTxt(EdX0 + 20, Y0 + 20, 'Aucun document ouvert.', cWhite, cGray);
    OutTxt(EdX0 + 20, Y0 + 44, 'Fichier - Nouveau, ou double clic sur un fichier', cWhite, cGray);
    OutTxt(EdX0 + 20, Y0 + 60, 'de la liste de gauche.', cWhite, cGray);
    PaintVScroll(VsX, Y0, HsY - 1, 0, 0, 1);
    PaintHScroll(EdX0, VsX - 1, HsY, 0, 0, 1);
  End
  Else
  Begin
    FBar(EdX0 + 1, Y0 + 1, VsX - 1, TxY0 - 1, cWhite);
    If ShowNums Then FBar(EdX0 + 1, Y0 + 1, EdX0 + GutW, TxY0 - 1, cSilver);
    For R := 0 To Rows - 1 Do PaintLine(R);
    R := TxY0 + Rows * RowH;
    If ShowNums Then FBar(EdX0 + 1, R, EdX0 + GutW, HsY - 1, cSilver)
    Else FBar(EdX0 + 1, R, EdX0 + GutW, HsY - 1, cWhite);
    FBar(EdX0 + GutW + 1, R, VsX - 1, HsY - 1, cWhite);
    PaintVScroll(VsX, Y0, HsY - 1, DTop[Cur], MaxTop, Rows);
    PaintHScroll(EdX0, VsX - 1, HsY, DLeft[Cur], HMax, Cols);
  End;
  FBar(VsX, HsY, CW - 1, HsY + ScrW - 1, cSilver);
  { onglets des documents (en bas, comme HomeSite) }
  FBar(EdX0, DtY, CW - 1, Y1, cSilver);
  HLine(EdX0, CW - 1, DtY, cGray);
  X := EdX0 + 4;
  For I := 0 To NDoc - 1 Do
  Begin
    S := NameOf(DName[Order[I]]);
    If DMod[Order[I]] Then S := S + ' *';
    W := Length(S) * 8 + 16;
    DtX[I] := X;
    If Order[I] = Cur Then
    Begin
      FBar(X, DtY, X + W - 1, Y1 - 1, cWhite);
      VLine(X, DtY, Y1 - 1, cGray); VLine(X + W - 1, DtY, Y1 - 1, cBlack);
      HLine(X, X + W - 1, Y1 - 1, cBlack);
      OutTxt(X + 8, DtY + 2, S, cBlack, cWhite);
    End
    Else
    Begin
      VLine(X + W - 1, DtY + 3, Y1 - 3, cGray);
      OutTxt(X + 8, DtY + 2, S, cGray, cSilver);
    End;
    X := X + W;
  End;
  DtX[NDoc] := X;
End;

Procedure PaintStatus;
Var Y, X : LongInt; S : String;
Begin
  Y := CH - SbH;
  FBar(0, Y, CW - 1, CH - 1, cSilver);
  HLine(0, CW - 1, Y, cWhite);
  X := CW - 8;
  If Cur >= 0 Then
  Begin
    If DMod[Cur] Then S := 'Modifi'#130 Else S := '';
    X := X - 80;
    Sunken(X, Y + 2, X + 76, CH - 2, cSilver);
    OutTxt(X + 4, Y + 2, S, cBlack, cSilver);
    Case DUtf8[Cur] Of
      1 : S := 'UTF-8';
      2 : S := 'UTF-8 (octets)';
    Else
      S := 'CP850';
    End;
    If DCrlf[Cur] = 0 Then S := S + ' LF' Else S := S + ' CRLF';
    X := X - (Length(S) * 8 + 12);
    Sunken(X, Y + 2, X + Length(S) * 8 + 8, CH - 2, cSilver);
    OutTxt(X + 4, Y + 2, S, cBlack, cSilver);
    S := LangName(DLang[Cur]);
    X := X - (Length(S) * 8 + 12);
    Sunken(X, Y + 2, X + Length(S) * 8 + 8, CH - 2, cSilver);
    OutTxt(X + 4, Y + 2, S, cNavy, cSilver);
    If InsMode Then S := 'INS' Else S := 'RFP';
    X := X - 40;
    Sunken(X, Y + 2, X + 36, CH - 2, cSilver);
    OutTxt(X + 6, Y + 2, S, cBlack, cSilver);
    S := IStr(DCY[Cur] + 1) + ' : ' + IStr(VisCol(Cur, DCY[Cur], DCX[Cur]) + 1);
    X := X - (Length(S) * 8 + 12);
    Sunken(X, Y + 2, X + Length(S) * 8 + 8, CH - 2, cSilver);
    OutTxt(X + 4, Y + 2, S, cBlack, cSilver);
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
  If ShowQb And (UY1 < TbH + QbH) And (UY2 >= TbH) Then PaintQuickBar;
  If ShowPanel And (UX1 < EdX0) Then
  Begin
    PaintTree;
    PaintFiles;
    FBar(PanW, Y0, EdX0 - 1, Y1, cSilver);
  End;
  If UX2 >= EdX0 Then PaintEditor;
  If UY2 >= CH - SbH Then PaintStatus;
  Dummy := WinEndPaint(Hps);
End;

{ zone du curseur a repeindre }
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
  InvalBand(EdX0, Y0, CW, CH);
End;

Function TreeRows : LongInt;
Begin
  TreeRows := MaxI(1, (TreeH - 6) Div RowH);
End;

Procedure ShowNode;
Begin
  If NSel < NTop Then NTop := NSel;
  If NSel >= NTop + TreeRows Then NTop := NSel - TreeRows + 1;
End;

Procedure ShowFile;
Begin
  If FSel < 0 Then Exit;
  If FSel < FTop Then FTop := FSel;
  If FSel >= FTop + FileRows Then FTop := FSel - FileRows + 1;
End;
{ ==================================================================== }
{ Edition                                                               }
{ ==================================================================== }

Var
  Clip : TBuf;                 { copie interne (le presse-papiers de PM garde 16 Ko) }
  FindS, ReplS : String;
  FindCase : Boolean;
  Pane : LongInt;              { clavier : 0 editeur, 1 arbre, 2 fichiers }

Procedure Changed;
Begin
  ScrollToCaret;
  InvalEditor;
  InvalBand(0, CH - SbH, CW, CH);
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

{ commentaire selon le langage : <!-- --> en HTML, ' en VBScript... }
Procedure CommentSel;
Var D, Y1, X1, Y2, X2, St, B : LongInt; Op, Cl : String; Bf : TBuf;
Begin
  D := Cur;
  If D < 0 Then Exit;
  St := LineState(D, DCY[D]);
  B := (St Shr 4) And 15;
  If (DLang[D] = lgCss) Or (B = 3) Then
  Begin
    Op := '/* '; Cl := ' */';
  End
  Else If (DLang[D] = lgJs) Or (B = 2) Then
  Begin
    Op := '/* '; Cl := ' */';
  End
  Else If (B = 1) Or (B = 4) Or (B = 5) Then
  Begin
    If DLang[D] = lgPsp Then
    Begin
      Op := '{ '; Cl := ' }';
    End
    Else
    Begin
      Op := '/* '; Cl := ' */';
    End;
  End
  Else
  Begin
    Op := '<!-- '; Cl := ' -->';
  End;
  If DLang[D] = lgAsp Then
    If (B = 1) Or (B = 4) Or (B = 5) Then
    Begin
      Op := ''''; Cl := '';
    End;
  BufInit(Bf);
  BufAdd(Bf, Op);
  If HasSel(D) Then
  Begin
    SelRange(D, Y1, X1, Y2, X2);
    GetRange(D, Y1, X1, Y2, X2, Bf);
  End;
  BufAdd(Bf, Cl);
  InsertStr(Bf.P, Bf.Len);
  If (Cl <> '') And (DCX[D] >= Length(Cl)) Then DCX[D] := DCX[D] - Length(Cl);
  BufFree(Bf);
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
  dNone = 0; dText = 1; dSplitV = 2; dSplitH = 3; dVThumb = 4; dHThumb = 5; dToolbar = 6;

Var
  DgFrame, DgClient, DgN, DgW, DgH, DgChkH : LongInt;
  DgDone, DgOk, DgChk : Boolean;
  DgLab : Array[0..4] Of String[47];
  DgV : Array[0..4] Of String;
  DgEf : Array[0..4] Of LongInt;
  DgChkS : String[63];
  DNoName : Array[0..MaxDoc - 1] Of Boolean;
  DLangFix : Array[0..MaxDoc - 1] Of Boolean;
  NewCount : LongInt;
  Drag, DragOff, LastMx, LastMy : LongInt;
  MyDir : String;
  CtxMenu, CtxN : LongInt;
  HelpBuf : TBuf;
  TipOn : Boolean;
  TipSave : String;

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
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Web Developer'), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure MsgErr(S : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Web Developer'), 0, MB_OK Or MB_ERROR Or MB_MOVEABLE);
End;

Function Ask(S : String) : Boolean;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Web Developer'), 0, MB_YESNO Or MB_QUERY Or MB_MOVEABLE) =
         MBID_YES;
End;

Function Ask3(S : String) : LongInt;
Begin
  Ask3 := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Web Developer'), 0, MB_YESNOCANCEL Or MB_QUERY Or MB_MOVEABLE);
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
          Tr[0] := 12; Tr[1] := DgH - 34 - K * 30; Tr[2] := 166; Tr[3] := Tr[1] + 18;
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
          If (X >= 170) And (X < DgW - 14) And (Y >= DgH - 36 - K * 30) And (Y < DgH - 16 - K * 30) Then
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
  For K := 0 To 4 Do
  Begin
    DgLab[K] := ''; DgV[K] := '';
  End;
End;

Procedure DlgField(L, V : String);
Begin
  If DgN > 4 Then Exit;
  DgLab[DgN] := L; DgV[DgN] := V;
  Inc(DgN);
End;

{ boite modale (champs DgLab/DgV, case DgChkS) ; OkS : texte du bouton }
Function InputBox(Title, OkS : String) : Boolean;
Var Fl, K, Fw, Fh, Sw, Sh, C : LongInt; Rc : Array[0..3] Of LongInt; Q : Array[0..7] Of LongInt;
Begin
  InputBox := False;
  DgW := 520;
  DgH := 60 + DgN * 30;
  If DgChkS <> '' Then Inc(DgH, 28);
  Dummy := WinRegisterClass(Hab, Z('WEBDEVDLG'), LongInt(@DlgProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DgClient := 0;
  DgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('WEBDEVDLG'), Z2(Title), 0, 0, 0, LongInt(@DgClient));
  If DgFrame = 0 Then Exit;
  For K := 0 To DgN - 1 Do
  Begin
    DgEf[K] := WinCreateWindow(DgClient, WC_ENTRYFIELD, Z(DgV[K]), WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
                               170, DgH - 36 - K * 30, DgW - 184, 20, DgClient, HWND_TOP, 10 + K, 0, 0);
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
{ Barre d'outils et barre de balises                                    }
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
  TbAdd(cmNew, 1, 'Nouveau document HTML (Ctrl+N)');
  TbAdd(cmOpen, 2, 'Ouvrir (Ctrl+O)');
  TbAdd(cmSave, 3, 'Enregistrer (Ctrl+S)');
  TbAdd(cmSaveAll, 4, 'Enregistrer tout');
  TbAdd(cmClose, 15, 'Fermer le document (Ctrl+F4)');
  TbAdd(0, 0, '');
  TbAdd(cmCut, 5, 'Couper (Ctrl+X)');
  TbAdd(cmCopy, 6, 'Copier (Ctrl+C)');
  TbAdd(cmPaste, 7, 'Coller (Ctrl+V)');
  TbAdd(0, 0, '');
  TbAdd(cmUndo, 8, 'Annuler (Ctrl+Z)');
  TbAdd(cmRedo, 9, 'R'#130'tablir (Ctrl+Y)');
  TbAdd(0, 0, '');
  TbAdd(cmFind, 10, 'Rechercher (Ctrl+F)');
  TbAdd(cmReplace, 11, 'Remplacer (Ctrl+H)');
  TbAdd(0, 0, '');
  TbAdd(cmBrowse, 12, 'Parcourir dans le Navigateur Web (F12)');
  TbAdd(cmRun, 13, 'Ex'#130'cuter la page PSP, ASP ou PHP (Ctrl+F9)');
  TbAdd(0, 0, '');
  TbAdd(cmHelp, 14, 'Aide (F1)');
End;

Procedure QbTabAdd(S : String);
Begin
  QbTabS[QbTabN] := S;
  If QbTabN = 0 Then QbTabX[0] := 4;
  QbTabX[QbTabN + 1] := QbTabX[QbTabN] + Length(S) * 8 + 18;
  Inc(QbTabN);
End;

{ bouton : Op et Cl entourent la selection ; ~ : fin de ligne, ^ : curseur }
Procedure QbAdd(Lab, Op, Cl : String);
Var T, K : LongInt;
Begin
  If NQb >= MaxQb Then Exit;
  T := QbTabN - 1;
  QbTab[NQb] := T; QbLab[NQb] := Lab; QbOpen[NQb] := Op; QbClose[NQb] := Cl;
  QbW[NQb] := Length(Lab) * 8 + 12;
  QbX[NQb] := 4;
  For K := NQb - 1 DownTo 0 Do
    If QbTab[K] = T Then
    Begin
      QbX[NQb] := QbX[K] + QbW[K] + 3;
      Break;
    End;
  Inc(NQb);
End;

Procedure QuickBarInit;
Begin
  QbTabN := 0; NQb := 0; QbCur := 0;
  QbTabAdd('Commun');
  QbAdd('Page', '<!DOCTYPE html>~<html lang="fr">~<head>~<meta charset="utf-8">~<title>^</title>~</head>~<body>~~',
        '~</body>~</html>~');
  QbAdd('B', '<b>', '</b>');
  QbAdd('I', '<i>', '</i>');
  QbAdd('U', '<u>', '</u>');
  QbAdd('P', '<p>', '</p>');
  QbAdd('BR', '<br>', '');
  QbAdd('&nbsp;', '&nbsp;', '');
  QbAdd('H1', '<h1>', '</h1>');
  QbAdd('H2', '<h2>', '</h2>');
  QbAdd('H3', '<h3>', '</h3>');
  QbAdd('HR', '<hr>', '');
  QbAdd('Lien', '<a href="^">', '</a>');
  QbAdd('Image', '<img src="^" alt="">', '');
  QbAdd('Div', '<div>', '</div>');
  QbAdd('Span', '<span>', '</span>');
  QbAdd('<!-- -->', '<!-- ', ' -->');
  QbTabAdd('Polices');
  QbAdd('Police', '<font face="Helv" size="3" color="#000080">', '</font>');
  QbAdd('Gras', '<strong>', '</strong>');
  QbAdd('Italique', '<em>', '</em>');
  QbAdd('Petit', '<small>', '</small>');
  QbAdd('Grand', '<big>', '</big>');
  QbAdd('Exposant', '<sup>', '</sup>');
  QbAdd('Indice', '<sub>', '</sub>');
  QbAdd('Code', '<code>', '</code>');
  QbAdd('Pre', '<pre>', '</pre>');
  QbAdd('Centre', '<div style="text-align:center">', '</div>');
  QbAdd('Couleur', '<span style="color:#800000">', '</span>');
  QbTabAdd('Tableaux');
  QbAdd('Tableau 2x2', '<table border="1" cellpadding="4">~<tr><th>^</th><th></th></tr>~<tr><td></td><td></td></tr>~' +
        '<tr><td></td><td></td></tr>~</table>~', '');
  QbAdd('Table', '<table border="1">~', '~</table>');
  QbAdd('Ligne', '<tr>', '</tr>');
  QbAdd('Cellule', '<td>', '</td>');
  QbAdd('En-t'#136'te', '<th>', '</th>');
  QbAdd('L'#130'gende', '<caption>', '</caption>');
  QbTabAdd('Formulaires');
  QbAdd('Formulaire', '<form action="^" method="post">~', '~</form>');
  QbAdd('Texte', '<input type="text" name="^" value="">', '');
  QbAdd('Mot de passe', '<input type="password" name="^">', '');
  QbAdd('Case', '<input type="checkbox" name="^" value="1">', '');
  QbAdd('Radio', '<input type="radio" name="^" value="">', '');
  QbAdd('Liste', '<select name="^">~<option value="1">Un</option>~<option value="2">Deux</option>~</select>', '');
  QbAdd('Zone', '<textarea name="^" rows="4" cols="40">', '</textarea>');
  QbAdd('Bouton', '<input type="submit" value="Envoyer">', '');
  QbAdd('Cach'#130, '<input type="hidden" name="^" value="">', '');
  QbAdd(#144'tiquette', '<label for="^">', '</label>');
  QbTabAdd('Listes');
  QbAdd('Liste '#133' puces', '<ul>~<li>^</li>~<li></li>~</ul>', '');
  QbAdd('Liste num'#130'rot'#130'e', '<ol>~<li>^</li>~<li></li>~</ol>', '');
  QbAdd(#144'l'#130'ment', '<li>', '</li>');
  QbAdd('D'#130'finitions', '<dl>~<dt>^</dt>~<dd></dd>~</dl>', '');
  QbTabAdd('Script');
  QbAdd('<% %>', '<% ', ' %>');
  QbAdd('<%= %>', '<%= ', ' %>');
  QbAdd('<?php ?>', '<?php ', ' ?>');
  QbAdd('<?= ?>', '<?= ', ' ?>');
  QbAdd('Script', '<script type="text/javascript">~', '~</script>');
  QbAdd('Style', '<style type="text/css">~', '~</style>');
  QbAdd('Lien CSS', '<link rel="stylesheet" type="text/css" href="^">', '');
  QbAdd('Base PSP', '<%~Var~  Cnx : DatabaseConnection;~  Res : RecordSet;~BEGIN~  Cnx := Database.Connect(''Driver=' +
        'PostgreSQL;Server=^;Database=;User=;Password='');~  Res := Cnx.Query(''SELECT * FROM table'');~',
        '  While Not Res.Eof Do~  Begin~    WriteLn(''<p>'', Res[''id''], ''</p>'');~    Res.Next;~  End;~' +
        '  Res.Close;~  Cnx.Close;~END.~%>~');
  QbAdd('Base ASP', '<%~Dim Cnx, Res~Set Cnx = Server.CreateObject("ADODB.Connection")~Cnx.Open "Driver=MariaDB;' +
        'Server=^;Database=;User=;Password="~Set Res = Cnx.Execute("SELECT * FROM table")~',
        'Do While Not Res.EOF~  Response.Write "<p>" & Res("id") & "</p>"~  Res.MoveNext~Loop~Res.Close~Cnx.Close~%>~');
End;

{ texte d'un bouton (~ : CR LF) ; Car : position de ^ (-1 : aucune) }
Procedure Expand(S : String; Var B : TBuf; Var Car : LongInt);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If S[K] = '~' Then
    Begin
      BufAddC(B, 13); BufAddC(B, 10);
    End
    Else If S[K] = '^' Then
    Begin
      If Car < 0 Then Car := B.Len;
    End
    Else BufAddC(B, Ord(S[K]));
End;

{ position (ligne, colonne) apres Off octets du texte insere en (Y0_, X0_) }
Procedure OffsetPos(Var B : TBuf; Off, Y0_, X0_ : LongInt; Var Y, X : LongInt);
Var K, Ls : LongInt;
Begin
  Y := Y0_; X := X0_; Ls := -1;
  For K := 0 To Off - 1 Do
    If B.P^[K] = 10 Then
    Begin
      Inc(Y);
      Ls := K;
    End;
  If Ls >= 0 Then
  Begin
    X := Off - Ls - 1;
  End
  Else X := X0_ + Off;
End;

Procedure ApplyQb(I : LongInt);
Var D, Car, Y1, X1, Y2, X2, Ya, Xa : LongInt; B, Sel : TBuf; WithSel : Boolean;
Begin
  D := Cur;
  If D < 0 Then Exit;
  BufInit(B); BufInit(Sel);
  Car := -1;
  WithSel := HasSel(D);
  If WithSel Then
  Begin
    SelRange(D, Y1, X1, Y2, X2);
    GetRange(D, Y1, X1, Y2, X2, Sel);
    Ya := Y1; Xa := X1;
  End
  Else
  Begin
    Ya := DCY[D]; Xa := MinI(DCX[D], LLen(D, DCY[D]));
  End;
  Expand(QbOpen[I], B, Car);
  If Car < 0 Then Car := B.Len;
  If WithSel Then
  Begin
    BufAddB(B, Sel.P, Sel.Len);
    Car := B.Len;
  End;
  Expand(QbClose[I], B, Car);
  If WithSel Then Car := B.Len;
  InsertStr(B.P, B.Len);
  OffsetPos(B, Car, Ya, Xa, DCY[D], DCX[D]);
  ClampCaret;
  BufFree(B); BufFree(Sel);
  Changed;
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  Pane := 0;
End;

{ ==================================================================== }
{ Documents : nouveau, ouvrir, enregistrer, fermer                      }
{ ==================================================================== }

Procedure SetCur(D : LongInt);
Begin
  Cur := D;
  If Cur >= 0 Then
  Begin
    Pane := 0;
    If DNoName[D] Then StatusMsg := NameOf(DName[D]) + ' (pas encore enregistr'#130')'
    Else StatusMsg := DName[D];
  End;
  Redraw;
End;

Procedure TplLine(Var B : TBuf; S : String);
Begin
  BufAdd(B, S);
  BufAddC(B, 13); BufAddC(B, 10);
End;

{ place le curseur sur le ^ du gabarit et l'enleve }
Procedure TplCaret(D : LongInt);
Var Y, K, N : LongInt; Q : PBytes;
Begin
  For Y := 0 To DN[D] - 1 Do
  Begin
    N := LLen(D, Y);
    Q := LP(D, Y);
    For K := 0 To N - 1 Do
      If Q^[K] = 94 Then
      Begin
        Tmp.Len := 0;
        If K > 0 Then BufAddB(Tmp, Q, K);
        If N > K + 1 Then BufAddB(Tmp, @Q^[K + 1], N - K - 1);
        RawSet(D, Y, Tmp.P, Tmp.Len);
        DCY[D] := Y; DCX[D] := K;
        Exit;
      End;
  End;
End;

Procedure NewDoc(Lang : LongInt);
Var D : LongInt; B : TBuf; X : String;
Begin
  Case Lang Of
    lgAsp : X := '.asp';
    lgPsp : X := '.psp';
    lgPhp : X := '.php';
    lgCss : X := '.css';
    lgJs : X := '.js';
  Else
    X := '.html';
  End;
  Inc(NewCount);
  D := DocNew(JoinPath(CurDir, 'sanstitre' + IStr(NewCount) + X));
  If D < 0 Then
  Begin
    MsgErr('Pas plus de ' + IStr(MaxDoc) + ' documents ouverts.');
    Exit;
  End;
  DNoName[D] := True; DLangFix[D] := False;
  BufInit(B);
  Case Lang Of
    lgCss :
      Begin
        TplLine(B, '/* Feuille de style */');
        TplLine(B, 'body {');
        TplLine(B, '  font-family: Helv, Helvetica, Arial, sans-serif;');
        TplLine(B, '  color: #000000;');
        TplLine(B, '  background: #FFFFFF;');
        TplLine(B, '}');
        TplLine(B, '');
        TplLine(B, 'h1 { color: #000080; }');
        TplLine(B, '^');
      End;
    lgJs :
      Begin
        TplLine(B, '// Script JavaScript');
        TplLine(B, 'function bonjour(nom) {');
        TplLine(B, '  console.log("Bonjour, " + nom + " !");');
        TplLine(B, '}');
        TplLine(B, '^');
      End;
  Else
    Begin
      If Lang = lgAsp Then TplLine(B, '<%@ Language="VBScript" %>')
      Else If Lang = lgPsp Then TplLine(B, '<%@ Language="PascalScript" %>');
      TplLine(B, '<!DOCTYPE html>');
      TplLine(B, '<html lang="fr">');
      TplLine(B, '<head>');
      TplLine(B, '<meta charset="utf-8">');
      TplLine(B, '<title>Sans titre</title>');
      TplLine(B, '</head>');
      TplLine(B, '<body>');
      Case Lang Of
        lgAsp :
          Begin
            TplLine(B, '<%');
            TplLine(B, 'Dim nom');
            TplLine(B, 'nom = Request.QueryString("nom")');
            TplLine(B, 'If nom = "" Then nom = "visiteur"');
            TplLine(B, '%>');
            TplLine(B, '<h1>Bonjour <%= Server.HTMLEncode(nom) %> !</h1>');
            TplLine(B, '^');
          End;
        lgPsp :
          Begin
            TplLine(B, '<%');
            TplLine(B, 'var');
            TplLine(B, '  nom : String;');
            TplLine(B, 'begin');
            TplLine(B, '  nom := Request.QueryString(''nom'');');
            TplLine(B, '  if nom = '''' then nom := ''visiteur'';');
            TplLine(B, 'end.');
            TplLine(B, '%>');
            TplLine(B, '<h1>Bonjour <%= Server.HTMLEncode(nom) %> !</h1>');
            TplLine(B, '<p>Il est <%= TimeToStr %> le <%= DateToStr %>.</p>');
            TplLine(B, '^');
          End;
        lgPhp :
          Begin
            TplLine(B, '<?php');
            TplLine(B, '$nom = isset($_GET[''nom'']) ? $_GET[''nom''] : ''visiteur'';');
            TplLine(B, '?>');
            TplLine(B, '<h1>Bonjour <?= htmlspecialchars($nom) ?> !</h1>');
            TplLine(B, '^');
          End;
      Else
        TplLine(B, '^');
      End;
      TplLine(B, '</body>');
      BufAdd(B, '</html>');
    End;
  End;
  DocFromBytes(D, B.P, B.Len);
  BufFree(B);
  DUtf8[D] := 1; DCrlf[D] := 1;
  TplCaret(D);
  DMod[D] := False;
  SetCur(D);
  ScrollToCaret;
  StatusMsg := 'Nouveau document ' + LangName(Lang) + '.';
End;

Function FindDoc(Name : String) : LongInt;
Var K : LongInt;
Begin
  FindDoc := -1;
  For K := 0 To MaxDoc - 1 Do
    If DUsed[K] And Not DNoName[K] And (UpStr(DName[K]) = UpStr(Name)) Then FindDoc := K;
End;

Procedure OpenFile(Name : String);
Var D : LongInt;
Begin
  D := FindDoc(Name);
  If D >= 0 Then
  Begin
    SetCur(D);
    Exit;
  End;
  D := DocNew(Name);
  If D < 0 Then
  Begin
    MsgErr('Pas plus de ' + IStr(MaxDoc) + ' documents ouverts.');
    Exit;
  End;
  DNoName[D] := False; DLangFix[D] := False;
  If Not DocLoad(D, Name) Then
  Begin
    DocFree(D);
    MsgErr('Impossible d''ouvrir ' + Name + '.');
    Exit;
  End;
  SetCur(D);
  StatusMsg := Name + ' : ' + IStr(DN[D]) + ' lignes.';
  If DUtf8[D] = 2 Then StatusMsg := StatusMsg + ' UTF-8 hors CP850 : octets gard'#130's tels quels.';
End;

Procedure RefreshFiles;
Begin
  If CurDir <> '' Then ListFiles(CurDir);
  If ShowPanel Then InvalBand(0, Y0, PanW, Y1 + 1);
End;

Function SaveAs(D : LongInt) : Boolean;
Var N : String;
Begin
  SaveAs := False;
  DlgReset;
  If DNoName[D] Then DlgField('Nom du fichier :', JoinPath(CurDir, NameOf(DName[D])))
  Else DlgField('Nom du fichier :', DName[D]);
  If Not InputBox('Enregistrer sous', 'Enregistrer') Then Exit;
  N := Trim(DgV[0]);
  If N = '' Then Exit;
  If (Length(N) < 2) Or (N[2] <> ':') Then N := JoinPath(CurDir, N);
  If (UpStr(N) <> UpStr(DName[D])) Or DNoName[D] Then
    If FExists(N) Then
      If Not Ask(N + ' existe d'#130'j'#133'. Le remplacer ?') Then Exit;
  If Not DocSave(D, N) Then
  Begin
    MsgErr('Impossible d''enregistrer ' + N + '.');
    Exit;
  End;
  DName[D] := N; DNoName[D] := False; DMod[D] := False;
  If Not DLangFix[D] Then
  Begin
    DLang[D] := LangOf(N);
    DStOk[D] := 0;
  End;
  StatusMsg := N + ' enregistr'#130'.';
  If UpStr(DirOf(N)) = UpStr(CurDir) Then RefreshFiles;
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
  If UpStr(DirOf(DName[D])) = UpStr(CurDir) Then RefreshFiles;
  SaveDoc := True;
End;

{ True : on peut fermer (enregistre ou abandonne) }
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

Procedure CloseDoc(D : LongInt);
Var K : LongInt;
Begin
  If D < 0 Then Exit;
  If Not CanClose(D) Then Exit;
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

Procedure OpenDlg;
Var N : String;
Begin
  DlgReset;
  DlgField('Fichier :', JoinPath(CurDir, ''));
  If Not InputBox('Ouvrir', 'Ouvrir') Then Exit;
  N := Trim(DgV[0]);
  If N = '' Then Exit;
  If (Length(N) < 2) Or (N[2] <> ':') Then N := JoinPath(CurDir, N);
  If Not FExists(N) Then
  Begin
    If Ask(N + ' n''existe pas. Le cr'#130'er ?') Then
    Begin
      Inc(NewCount);
      Dummy := DocNew(N);
      If Dummy >= 0 Then
      Begin
        DNoName[Dummy] := False; DLangFix[Dummy] := False;
        RawIns(Dummy, 0, Nil, 0);
        DUtf8[Dummy] := 1;
        SetCur(Dummy);
        DMod[Dummy] := True;
      End;
    End;
    Exit;
  End;
  OpenFile(N);
  TreeGoto(DirOf(N));
  ShowNode;
  Redraw;
End;

{ ==================================================================== }
{ Parcourir et executer                                                 }
{ ==================================================================== }

Procedure Launch(Exe, Arg : String; Sync : Boolean);
Var Args : Array[0..599] Of Byte; Res : Array[0..1] Of LongInt; Fail : Array[0..259] Of Byte; P, K, Fl : LongInt;
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
  If Sync Then Fl := 0 Else Fl := 4;
  If DosExecPgm(LongInt(@Fail), 260, Fl, LongInt(@Args), 0, LongInt(@Res), Z(Exe)) <> 0 Then
    MsgErr('Impossible de lancer ' + Exe + '.');
End;

Function FindExe(Nm : String) : String;
Begin
  FindExe := '';
  If FExists('C:\' + Nm) Then FindExe := 'C:\' + Nm
  Else If (MyDir <> '') And FExists(JoinPath(MyDir, Nm)) Then FindExe := JoinPath(MyDir, Nm);
End;

{ le Serveur Web tourne-t-il ? }
Function WebAlive : Boolean;
Var P : LongInt;
Begin
  WebAlive := False;
  P := 0;
  If DosGetNamedSharedMem(LongInt(@P), Z('\SHAREMEM\WEBSRV'), $13) <> 0 Then Exit;
  If (RdL(P) <> $53424557) Or (RdL(P + 8) = 0) Then Exit;
  WebAlive := KTaskCtl(3, RdL(P + 4), 0, 0) = 1;
End;

{ adresse http://localhost/... d'un fichier d'un site du Serveur Web ('' : aucun) }
Function SiteUrl(Path : String) : String;
Var Base, Cfg, L, Root, Bind, Best, U : String; H, R, K, Port, BestLen, BestPort : LongInt; B : TBuf;
    C : Char; Started, Tls, BestTls : Boolean;

  Procedure EndSite;
  Begin
    If (Root <> '') And Started And (Port > 0) Then
    Begin
      While (Length(Root) > 3) And (Root[Length(Root)] = '\') Do Delete(Root, Length(Root), 1);
      If (Length(Root) > BestLen) And (UpStr(Copy(Path, 1, Length(Root) + 1)) = UpStr(Root) + '\') Then
      Begin
        BestLen := Length(Root); Best := Root; BestPort := Port; BestTls := Tls;
      End;
    End;
    Root := ''; Port := 0; Started := True; Tls := False;
  End;

Begin
  SiteUrl := '';
  Base := EnvStr('WEBSRV_ROOT');
  If Base = '' Then Base := 'C:\WWW';
  Cfg := 'D:\WWW\WEBSRV.CFG';
  If Not FExists(Cfg) Then Cfg := Base + '\WEBSRV.CFG';
  BestLen := -1; Best := ''; BestPort := 80; BestTls := False;
  Root := ''; Port := 0; Started := True; Tls := False;
  If Not FOpenRead(Cfg, H) Then
  Begin
    { configuration par defaut : C:\WWW\ROOT sur le port 80 }
    Root := Base + '\ROOT'; Port := 80;
    EndSite;
  End
  Else
  Begin
    BufInit(B);
    Repeat
      If Not BufGrow(B, 4096) Then Break;
      R := FRead(H, @B.P^[B.Len], 4096);
      If R > 0 Then B.Len := B.Len + R;
    Until R <= 0;
    DosClose(H);
    L := '';
    For K := 0 To B.Len Do
    Begin
      If K < B.Len Then C := Chr(B.P^[K]) Else C := #10;
      If (C = #13) Or (C = #10) Then
      Begin
        L := Trim(L);
        If UpStr(Copy(L, 1, 6)) = '[SITE:' Then EndSite
        Else If UpStr(Copy(L, 1, 7)) = 'RACINE=' Then Root := Trim(Copy(L, 8, 255))
        Else If UpStr(Copy(L, 1, 5)) = 'ETAT=' Then Started := UpStr(Trim(Copy(L, 6, 20))) = 'DEMARRE'
        Else If (UpStr(Copy(L, 1, 8)) = 'LIAISON=') And (Port = 0) Then
        Begin
          { Liaison=http,*,80,hote }
          Bind := Copy(L, 9, 255);
          Tls := LoStr(Copy(Bind, 1, 6)) = 'https,';
          Delete(Bind, 1, Pos(',', Bind));
          Delete(Bind, 1, Pos(',', Bind));
          If Pos(',', Bind) > 0 Then Bind := Copy(Bind, 1, Pos(',', Bind) - 1);
          Port := SVal(Trim(Bind));
        End;
        L := '';
      End
      Else If Length(L) < 250 Then L := L + C;
    End;
    EndSite;
    BufFree(B);
  End;
  If BestLen < 0 Then Exit;
  U := Copy(Path, BestLen + 2, 255);
  For K := 1 To Length(U) Do If U[K] = '\' Then U[K] := '/';
  If BestTls Then L := 'https://localhost' Else L := 'http://localhost';
  If (BestTls And (BestPort <> 443)) Or (Not BestTls And (BestPort <> 80)) Then L := L + ':' + IStr(BestPort);
  SiteUrl := L + '/' + U;
End;

{ le document doit etre enregistre (Parcourir, Executer) }
Function NeedSaved : Boolean;
Begin
  NeedSaved := False;
  If Cur < 0 Then Exit;
  If DNoName[Cur] Then
  Begin
    If Not SaveAs(Cur) Then Exit;
  End
  Else If DMod[Cur] Then
  Begin
    If Not SaveDoc(Cur) Then Exit;
  End;
  NeedSaved := True;
End;

Procedure BrowseDoc;
Var U, Exe, P : String; K : LongInt;
Begin
  If Not NeedSaved Then Exit;
  P := DName[Cur];
  U := '';
  If WebAlive Then U := SiteUrl(P);
  If U = '' Then
  Begin
    If (DLang[Cur] = lgPsp) Or (DLang[Cur] = lgAsp) Or (DLang[Cur] = lgPhp) Then
      StatusMsg := 'Page hors d''un site du Serveur Web en marche : le code serveur ne sera pas ex'#130'cut'#130'.';
    U := P;
    For K := 1 To Length(U) Do If U[K] = '\' Then U[K] := '/';
    U := 'file:///' + U;
  End
  Else StatusMsg := U;
  Exe := FindExe('BROWSER.EXE');
  If Exe = '' Then MsgErr('Navigateur Web introuvable (BROWSER.EXE).') Else Launch(Exe, U, False);
  InvalBand(0, CH - SbH, CW, CH);
End;

{ dossier ou l'on peut ecrire (resultat de l'execution) }
Function TempDir : String;
Var T : String; H : LongInt;
Begin
  T := EnvStr('TEMP');
  If T = '' Then T := EnvStr('TMP');
  If T <> '' Then
    If FOpenWrite(JoinPath(T, 'WEBDEV.TMP'), H) Then
    Begin
      DosClose(H);
      TempDir := T;
      Exit;
    End;
  If FOpenWrite('C:\WEBDEV.TMP', H) Then
  Begin
    DosClose(H);
    TempDir := 'C:\';
    Exit;
  End;
  TempDir := 'D:\';
End;

Procedure RunPage;
Var Exe, Out_, Nm, Arg : String; D, H : LongInt;
Begin
  If Cur < 0 Then Exit;
  If (DLang[Cur] <> lgPsp) And (DLang[Cur] <> lgAsp) And (DLang[Cur] <> lgPhp) Then
  Begin
    Msg('Ex'#130'cuter la page : pour les pages PSP (Pascal), ASP (VBScript) et PHP. Pour les autres pages, ' +
        'utilisez Parcourir (F12).');
    Exit;
  End;
  If Not NeedSaved Then Exit;
  Exe := FindExe('WEBSRV.EXE');
  If Exe = '' Then
  Begin
    MsgErr('Serveur Web introuvable (WEBSRV.EXE).');
    Exit;
  End;
  Nm := DName[Cur];
  Out_ := JoinPath(TempDir, 'WEBDEV.HTM');
  Dummy := DosDelete(Z(Out_));
  DlgReset;
  DlgField('Requ'#136'te (nom=valeur&...) :', '');
  If Not InputBox('Ex'#130'cuter ' + NameOf(Nm), 'Ex'#130'cuter') Then Exit;
  Arg := '/PSPOUT ' + Out_ + ' ' + Nm;
  If Trim(DgV[0]) <> '' Then Arg := Arg + ' ' + Trim(DgV[0]);
  StatusMsg := 'Ex'#130'cution de ' + NameOf(Nm) + '...';
  Redraw;
  Launch(Exe, Arg, True);
  If Not FOpenRead(Out_, H) Then
  Begin
    MsgErr('La page n''a rien produit (' + Out_ + ').');
    Exit;
  End;
  DosClose(H);
  D := DocNew(JoinPath(DirOf(Out_), 'R'#130'sultat - ' + NameOf(Nm) + '.htm'));
  If D < 0 Then Exit;
  DNoName[D] := True; DLangFix[D] := False;
  If Not DocLoad(D, Out_) Then RawIns(D, 0, Nil, 0);
  DLang[D] := lgHtml;
  DMod[D] := False;
  SetCur(D);
  StatusMsg := 'R'#130'sultat de ' + NameOf(Nm) + ' : ' + IStr(DN[D]) + ' lignes.';
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

{ gabarit de menu : les elements de chaque (sous-)menu sont comptes }
Var
  MStkN : Array[0..7] Of LongInt;
  MDep : LongInt;

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

Procedure BuildMenu;
Var H0, H1, H2 : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 90, '~Fichier');
  H1 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, cmNew, '~Nouveau');
  H2 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmNewHtml, 'Page ~HTML' + #9 + 'Ctrl+N');
  MnItem(MIS_TEXT, 0, cmNewAsp, 'Page ~ASP (VBScript)');
  MnItem(MIS_TEXT, 0, cmNewPsp, 'Page ~PSP (Pascal Server Pages)');
  MnItem(MIS_TEXT, 0, cmNewPhp, 'Page P~HP');
  MnItem(MIS_TEXT, 0, cmNewCss, 'Feuille de style ~CSS');
  MnItem(MIS_TEXT, 0, cmNewJs, 'Script ~JavaScript');
  MenuClose(H2, 6);
  MnItem(MIS_TEXT, 0, cmOpen, '~Ouvrir...' + #9 + 'Ctrl+O');
  MnItem(MIS_TEXT, 0, cmRevert, '~Recharger du disque');
  Sep;
  MnItem(MIS_TEXT, 0, cmSave, '~Enregistrer' + #9 + 'Ctrl+S');
  MnItem(MIS_TEXT, 0, cmSaveAs, 'Enregistrer ~sous...');
  MnItem(MIS_TEXT, 0, cmSaveAll, 'Enregistrer ~tout');
  Sep;
  MnItem(MIS_TEXT, 0, cmClose, '~Fermer' + #9 + 'Ctrl+F4');
  MnItem(MIS_TEXT, 0, cmCloseAll, 'Fermer to~ut');
  Sep;
  MnItem(MIS_TEXT, 0, cmQuit, '~Quitter' + #9 + 'Alt+F4');
  MenuClose(H1, 13);
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
  MnItem(MIS_TEXT, 0, cmIndent, '~Indenter' + #9 + 'Tab');
  MnItem(MIS_TEXT, 0, cmUnindent, '~D'#130'sindenter' + #9 + 'Maj+Tab');
  MnItem(MIS_TEXT, 0, cmUpper, 'M~ajuscules' + #9 + 'Ctrl+Maj+U');
  MnItem(MIS_TEXT, 0, cmLower, 'Mi~nuscules' + #9 + 'Ctrl+U');
  MnItem(MIS_TEXT, 0, cmComment, 'Mettre en co~mmentaire' + #9 + 'Ctrl+Maj+C');
  MenuClose(H1, 17);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 92, '~Recherche');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmFind, '~Rechercher...' + #9 + 'Ctrl+F');
  MnItem(MIS_TEXT, 0, cmFindNext, 'Rechercher le ~suivant' + #9 + 'F3');
  MnItem(MIS_TEXT, 0, cmReplace, 'R~emplacer...' + #9 + 'Ctrl+H');
  Sep;
  MnItem(MIS_TEXT, 0, cmGoto, '~Aller '#133' la ligne...' + #9 + 'Ctrl+G');
  MnItem(MIS_TEXT, 0, cmMatchTag, '~Balise ou parenth'#138'se associ'#130'e' + #9 + 'Ctrl+M');
  MenuClose(H1, 6);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 93, '~Affichage');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, Chk(ShowPanel), cmPanel, 'Panneau des ~ressources' + #9 + 'F9');
  MnItem(MIS_TEXT, Chk(ShowQb), cmQBar, '~Barre de balises');
  MnItem(MIS_TEXT, Chk(ShowNums), cmNums, '~Num'#130'ros de ligne');
  MnItem(MIS_TEXT, Chk(SrvBg), cmSrvBg, '~Fond des blocs serveur (<% %>, <?php ?>)');
  MnItem(MIS_TEXT, Chk(WebOnly), cmWebOnly, 'Fichiers ~Web seulement');
  Sep;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 94, '~Coloration');
  H2 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmLangAuto, 'D'#39'apr'#138's l'#39'~extension');
  Sep;
  MnItem(MIS_TEXT, 0, cmLangHtml, '~HTML');
  MnItem(MIS_TEXT, 0, cmLangAsp, '~ASP (VBScript)');
  MnItem(MIS_TEXT, 0, cmLangPsp, '~PSP (Pascal)');
  MnItem(MIS_TEXT, 0, cmLangPhp, 'P~HP');
  MnItem(MIS_TEXT, 0, cmLangCss, '~CSS');
  MnItem(MIS_TEXT, 0, cmLangJs, '~JavaScript');
  MnItem(MIS_TEXT, 0, cmLangText, '~Texte (aucune)');
  MenuClose(H2, 9);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 95, '~Encodage');
  H2 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmEncUtf8, '~UTF-8');
  MnItem(MIS_TEXT, 0, cmEncRaw, '~CP850 (octets)');
  Sep;
  MnItem(MIS_TEXT, 0, cmEndCrlf, 'Fins de ligne ~CR LF (OS/2)');
  MnItem(MIS_TEXT, 0, cmEndLf, 'Fins de ligne ~LF (Unix)');
  MenuClose(H2, 5);
  Sep;
  MnItem(MIS_TEXT, 0, cmRefresh, '~Actualiser les dossiers' + #9 + 'F5');
  MenuClose(H1, 9);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 96, '~Balises');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmTagFirst + 0, 'Page ~HTML compl'#138'te');
  MnItem(MIS_TEXT, 0, cmTagFirst + 1, '~Gras <b>');
  MnItem(MIS_TEXT, 0, cmTagFirst + 2, '~Italique <i>');
  MnItem(MIS_TEXT, 0, cmTagFirst + 4, '~Paragraphe <p>');
  MnItem(MIS_TEXT, 0, cmTagFirst + 5, 'Saut de ~ligne <br>');
  MnItem(MIS_TEXT, 0, cmTagFirst + 7, 'Titre ~1 <h1>');
  MnItem(MIS_TEXT, 0, cmTagFirst + 11, 'Lie~n <a href>');
  MnItem(MIS_TEXT, 0, cmTagFirst + 12, 'I~mage <img>');
  MnItem(MIS_TEXT, 0, cmTagFirst + 15, '~Commentaire <!-- -->');
  Sep;
  MnItem(MIS_TEXT, 0, cmComment, 'Commentaire selon le ~langage' + #9 + 'Ctrl+Maj+C');
  MenuClose(H1, 11);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 97, '~Outils');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmBrowse, '~Parcourir dans le Navigateur Web' + #9 + 'F12');
  MnItem(MIS_TEXT, 0, cmRun, '~Ex'#130'cuter la page (PSP, ASP, PHP)' + #9 + 'Ctrl+F9');
  Sep;
  MnItem(MIS_TEXT, 0, cmNewFolder, '~Nouveau dossier...');
  MnItem(MIS_TEXT, 0, cmOpenDir, '~Aller au dossier...');
  MenuClose(H1, 5);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 98, '~?');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmHelp, '~Aide' + #9 + 'F1');
  MnItem(MIS_TEXT, 0, cmKeys, '~Touches');
  Sep;
  MnItem(MIS_TEXT, 0, cmAbout, '~A propos de Web Developer...');
  MenuClose(H1, 4);
  MenuClose(H0, 7);
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

{ Kind : 0 editeur, 1 arbre, 2 fichiers, 3 onglets ; X, Y de PM }
Procedure Popup(Kind, X, Y : LongInt);
Var Fst : LongInt;
Begin
  MenuLen := 0; CtxN := 0;
  Dummy := MenuOpen;
  Case Kind Of
    1 :
      Begin
        Fst := cmRefresh;
        CtxIt(cmNewHtml, 'Nouvelle page ~HTML ici');
        CtxIt(cmNewFolder, 'Nouveau ~dossier...');
        CtxSep;
        CtxIt(cmRefresh, 'A~ctualiser' + #9 + 'F5');
      End;
    2 :
      Begin
        Fst := cmOpen;
        CtxIt(cmOpen + 1000, '~Ouvrir');
        CtxIt(cmBrowse + 1000, '~Parcourir');
        CtxSep;
        CtxIt(cmNewHtml, 'Nouvelle page ~HTML');
        CtxIt(cmRefresh, 'A~ctualiser' + #9 + 'F5');
      End;
    3 :
      Begin
        Fst := cmSave;
        CtxIt(cmSave, '~Enregistrer' + #9 + 'Ctrl+S');
        CtxIt(cmSaveAs, 'Enregistrer ~sous...');
        CtxSep;
        CtxIt(cmBrowse, '~Parcourir' + #9 + 'F12');
        CtxSep;
        CtxIt(cmClose, '~Fermer' + #9 + 'Ctrl+F4');
      End;
  Else
    Begin
      Fst := cmCopy;
      CtxIt(cmUndo, '~Annuler' + #9 + 'Ctrl+Z');
      CtxSep;
      CtxIt(cmCut, '~Couper' + #9 + 'Ctrl+X');
      CtxIt(cmCopy, 'C~opier' + #9 + 'Ctrl+C');
      CtxIt(cmPaste, 'Co~ller' + #9 + 'Ctrl+V');
      CtxSep;
      CtxIt(cmSelAll, 'S'#130'lectionner ~tout' + #9 + 'Ctrl+A');
      CtxSep;
      CtxIt(cmTagFirst + 1, '~Gras <b>');
      CtxIt(cmTagFirst + 2, '~Italique <i>');
      CtxIt(cmTagFirst + 11, 'Lie~n <a href>');
      CtxIt(cmComment, 'Co~mmentaire' + #9 + 'Ctrl+Maj+C');
      CtxSep;
      CtxIt(cmBrowse, '~Parcourir' + #9 + 'F12');
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

Procedure SelectNode(I : LongInt);
Begin
  If (I < 0) Or (I >= NNode) Then Exit;
  NSel := I;
  ShowNode;
  ListFiles(NodePath(I));
  StatusMsg := SpecDir(CurDir) + ' : ' + IStr(NFile) + ' fichiers.';
  Redraw;
End;

Procedure ToggleNode(I : LongInt);
Begin
  If (I < 0) Or (I >= NNode) Then Exit;
  If NOpen[I] Then CollapseNode(I) Else ExpandNode(I);
  Redraw;
End;

Procedure HelpBox(S : String);
Begin
  BufAdd(HelpBuf, S);
End;

Procedure ShowHelp(Keys : Boolean);
Begin
  BufInit(HelpBuf);
  If Not Keys Then
  Begin
    HelpBox('Web Developer : '#130'diteur de pages Web (HTML, ASP, PSP, PHP, CSS, JavaScript).' + #13#10#13#10);
    HelpBox('A gauche : l'#39'arbre des dossiers (clic : liste des fichiers ; + ou double clic : d'#130'plier) ');
    HelpBox('et la liste des fichiers du dossier (double clic : ouvrir). Les bords se d'#130'placent ');
    HelpBox(#133' la souris.' + #13#10#13#10);
    HelpBox('Barre de balises : un bouton entoure la s'#130'lection de la balise choisie.' + #13#10);
    HelpBox('Coloration d'#39'apr'#138's l'#39'extension (menu Affichage - Coloration pour la changer).' + #13#10);
    HelpBox('Parcourir (F12) : la page dans le Navigateur Web, par http://localhost/ si elle est ');
    HelpBox('dans un site du Serveur Web en marche (le code PSP ou ASP est alors ex'#130'cut'#130').' + #13#10);
    HelpBox('Ex'#130'cuter la page (Ctrl+F9) : r'#130'sultat d'#39'une page PSP, ASP ou PHP dans un nouvel onglet.');
  End
  Else
  Begin
    HelpBox('Ctrl+N nouveau, Ctrl+O ouvrir, Ctrl+S enregistrer, Ctrl+F4 fermer, Ctrl+Tab document suivant.' + #13#10);
    HelpBox('Ctrl+Z annuler, Ctrl+Y r'#130'tablir, Ctrl+X/C/V couper, copier, coller, Ctrl+A tout.' + #13#10);
    HelpBox('Ctrl+F rechercher, F3 suivant, Ctrl+H remplacer, Ctrl+G aller '#133' la ligne, ');
    HelpBox('Ctrl+M balise associ'#130'e.' + #13#10);
    HelpBox('Tab et Maj+Tab : indenter la s'#130'lection, Ctrl+U minuscules, Ctrl+Maj+U majuscules, ');
    HelpBox('Ctrl+Maj+C commentaire.' + #13#10);
    HelpBox('Ins : insertion ou refrappe ; Ctrl+fl'#138'ches : mot, d'#130'filement.' + #13#10);
    HelpBox('F9 panneau des ressources, F5 actualiser, F12 parcourir, Ctrl+F9 ex'#130'cuter.');
  End;
  BufAddC(HelpBuf, 0);
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, LongInt(HelpBuf.P), Z2('Web Developer - Aide'), 0,
                         MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
  BufFree(HelpBuf);
End;

Procedure SetLang(L : LongInt);
Begin
  If Cur < 0 Then Exit;
  If L < 0 Then
  Begin
    DLang[Cur] := LangOf(DName[Cur]);
    DLangFix[Cur] := False;
  End
  Else
  Begin
    DLang[Cur] := L;
    DLangFix[Cur] := True;
  End;
  DStOk[Cur] := 0;
  StatusMsg := 'Coloration : ' + LangName(DLang[Cur]) + '.';
  Redraw;
End;

Procedure DoCmd(C : LongInt);
Var K, N : LongInt; S : String;
Begin
  Case C Of
    cmNew, cmNewHtml : NewDoc(lgHtml);
    cmNewAsp : NewDoc(lgAsp);
    cmNewPsp : NewDoc(lgPsp);
    cmNewPhp : NewDoc(lgPhp);
    cmNewCss : NewDoc(lgCss);
    cmNewJs : NewDoc(lgJs);
    cmOpen : OpenDlg;
    cmRevert :
      If (Cur >= 0) And Not DNoName[Cur] Then
        If Not DMod[Cur] Or Ask('Abandonner les modifications de ' + NameOf(DName[Cur]) + ' ?') Then
        Begin
          S := DName[Cur];
          K := Cur;
          DMod[K] := False;
          CloseDoc(K);
          OpenFile(S);
        End;
    cmSave : Dummy := Ord(SaveDoc(Cur));
    cmSaveAs : If Cur >= 0 Then Dummy := Ord(SaveAs(Cur));
    cmSaveAll :
      For K := 0 To MaxDoc - 1 Do
        If DUsed[K] And DMod[K] Then Dummy := Ord(SaveDoc(K));
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
    cmCopy : CopySel;
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
            Msg(IStr(N) + ' remplacement(s) de "' + FindS + '".');
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
    cmMatchTag : MatchTag;
    cmPanel :
      Begin
        ShowPanel := Not ShowPanel;
        SetCheck(cmPanel, ShowPanel);
        If Not ShowPanel Then Pane := 0;
        Redraw;
      End;
    cmQBar :
      Begin
        ShowQb := Not ShowQb;
        SetCheck(cmQBar, ShowQb);
        Redraw;
      End;
    cmNums :
      Begin
        ShowNums := Not ShowNums;
        SetCheck(cmNums, ShowNums);
        Redraw;
      End;
    cmSrvBg :
      Begin
        SrvBg := Not SrvBg;
        SetCheck(cmSrvBg, SrvBg);
        InvalEditor;
      End;
    cmWebOnly :
      Begin
        WebOnly := Not WebOnly;
        SetCheck(cmWebOnly, WebOnly);
        RefreshFiles;
      End;
    cmRefresh :
      Begin
        If (NSel >= 0) And (NSel < NNode) And NOpen[NSel] Then
        Begin
          CollapseNode(NSel);
          ExpandNode(NSel);
        End;
        RefreshFiles;
        Redraw;
      End;
    cmLangAuto : SetLang(-1);
    cmLangText : SetLang(lgText);
    cmLangHtml : SetLang(lgHtml);
    cmLangAsp : SetLang(lgAsp);
    cmLangPsp : SetLang(lgPsp);
    cmLangPhp : SetLang(lgPhp);
    cmLangCss : SetLang(lgCss);
    cmLangJs : SetLang(lgJs);
    cmEncUtf8, cmEncRaw :
      If Cur >= 0 Then
      Begin
        If C = cmEncUtf8 Then DUtf8[Cur] := 1 Else DUtf8[Cur] := 0;
        DMod[Cur] := True;
        Redraw;
      End;
    cmEndCrlf, cmEndLf :
      If Cur >= 0 Then
      Begin
        If C = cmEndCrlf Then DCrlf[Cur] := 1 Else DCrlf[Cur] := 0;
        DMod[Cur] := True;
        Redraw;
      End;
    cmBrowse : BrowseDoc;
    cmRun : RunPage;
    cmNewFolder :
      Begin
        DlgReset;
        DlgField('Nom du dossier :', 'nouveau');
        If InputBox('Nouveau dossier dans ' + SpecDir(CurDir), 'Cr'#130'er') And (Trim(DgV[0]) <> '') Then
        Begin
          S := JoinPath(SpecDir(CurDir), Trim(DgV[0]));
          If DosCreateDir(Z(S), 0) <> 0 Then MsgErr('Impossible de cr'#130'er ' + S + '.')
          Else
          Begin
            If (NSel >= 0) And NOpen[NSel] Then CollapseNode(NSel);
            NKids[NSel] := 0;
            ExpandNode(NSel);
            Redraw;
          End;
        End;
      End;
    cmOpenDir :
      Begin
        DlgReset;
        DlgField('Dossier :', SpecDir(CurDir));
        If InputBox('Aller au dossier', 'Aller') And (Trim(DgV[0]) <> '') Then
        Begin
          TreeGoto(Trim(DgV[0]));
          ShowNode;
          Redraw;
        End;
      End;
    cmHelp : ShowHelp(False);
    cmKeys : ShowHelp(True);
    cmAbout : Msg('Web Developer pour OS/2-0, version 1.0' + #13#10 +
                  #130'diteur de pages Web dans le genre de HomeSite.' + #13#10 +
                  'HTML, ASP, PSP, PHP, CSS, JavaScript.');
    cmOpen + 1000, cmBrowse + 1000 :
      If (FSel >= 0) And (FSel < NFile) Then
      Begin
        OpenFile(JoinPath(SpecDir(CurDir), FName[FSel]));
        If C = cmBrowse + 1000 Then BrowseDoc;
      End;
  Else
    If (C >= cmTagFirst) And (C < cmTagFirst + NQb) Then ApplyQb(C - cmTagFirst);
  End;
  InvalBand(0, CH - SbH, CW, CH);
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
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

Procedure Click(X, Y : LongInt; Dbl, Shift : Boolean);
Var I, Fy, R, Nx, T, Th, Ty, Ny, Nx_ : LongInt;
Begin
  LastMx := X; LastMy := Y;
  { barre d'outils }
  If Y < TbH Then
  Begin
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
  { barre de balises }
  If ShowQb And (Y < TbH + QbH) Then
  Begin
    If Y < TbH + 20 Then
    Begin
      For I := 0 To QbTabN - 1 Do
        If (X >= QbTabX[I]) And (X < QbTabX[I + 1]) Then QbCur := I;
      InvalBand(0, TbH, CW, TbH + QbH);
    End
    Else
      For I := 0 To NQb - 1 Do
        If (QbTab[I] = QbCur) And (X >= QbX[I]) And (X < QbX[I] + QbW[I]) Then
        Begin
          ApplyQb(I);
          Break;
        End;
    Exit;
  End;
  If Y > Y1 Then Exit;
  { panneau des ressources }
  If ShowPanel And (X < PanW) Then
  Begin
    If Y < Y0 + TreeH Then
    Begin
      Pane := 1;
      R := (Y - Y0 - 3) Div RowH;
      I := NTop + R;
      If (R >= 0) And (I < NNode) Then
      Begin
        Nx := 18 + NLev[I] * 14;
        If (X >= Nx - 17) And (X <= Nx - 7) And (NKids[I] <> 2) Then ToggleNode(I)
        Else
        Begin
          SelectNode(I);
          If Dbl Then ToggleNode(I);
        End;
      End;
    End
    Else If Y < Y0 + TreeH + 4 Then
    Begin
      Drag := dSplitH;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
    End
    Else
    Begin
      Pane := 2;
      Fy := Y0 + TreeH + 4 + 22;
      If Y >= Fy Then
      Begin
        I := FTop + (Y - Fy) Div RowH;
        If I < NFile Then
        Begin
          FSel := I;
          InvalBand(0, Y0, PanW, Y1 + 1);
          If Dbl Then OpenFile(JoinPath(SpecDir(CurDir), FName[I]));
        End;
      End;
    End;
    Exit;
  End;
  If ShowPanel And (X < EdX0) Then
  Begin
    Drag := dSplitV;
    Dummy := WinSetCapture(HWND_DESKTOP, Client);
    Exit;
  End;
  { onglets des documents }
  If Y >= DtY Then
  Begin
    For I := 0 To NDoc - 1 Do
      If (X >= DtX[I]) And (X < DtX[I + 1]) Then SetCur(Order[I]);
    Exit;
  End;
  If Cur < 0 Then Exit;
  Pane := 0;
  { barre de defilement verticale }
  If (X >= VsX) And (Y < HsY) Then
  Begin
    If Y < Y0 + ScrW Then ScrollTo(DTop[Cur] - 1)
    Else If Y >= HsY - ScrW Then ScrollTo(DTop[Cur] + 1)
    Else
    Begin
      T := HsY - Y0 - 2 * ScrW;
      Th := MaxI(10, T * Rows Div (MaxTop + Rows));
      If Th > T Then Th := T;
      If MaxTop > 0 Then Ty := Y0 + ScrW + (T - Th) * DTop[Cur] Div MaxTop Else Ty := Y0 + ScrW;
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
  { barre de defilement horizontale }
  If (Y >= HsY) And (Y < DtY) Then
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
    { marge : toute la ligne }
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
  InvalBand(0, CH - SbH, CW, CH);
End;

Procedure MouseMove(X, Y : LongInt);
Var Ny, Nx, T, Th : LongInt;
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
          InvalBand(0, CH - SbH, CW, CH);
        End;
      End;
    dSplitV :
      Begin
        PanW := MaxI(120, MinI(X, CW - 200));
        Redraw;
      End;
    dSplitH :
      Begin
        TreeH := MaxI(60, MinI(Y - Y0, Y1 - Y0 - 80));
        InvalBand(0, Y0, PanW, Y1 + 1);
      End;
    dVThumb :
      If Cur >= 0 Then
      Begin
        T := HsY - Y0 - 2 * ScrW;
        Th := MaxI(10, T * Rows Div (MaxTop + Rows));
        If T - Th > 0 Then ScrollTo((Y - DragOff - Y0 - ScrW) * MaxTop Div (T - Th));
      End;
    dHThumb :
      If Cur >= 0 Then
      Begin
        T := VsX - EdX0 - 2 * ScrW;
        Th := MaxI(10, T * Cols Div (HMax + Cols));
        If T - Th > 0 Then ScrollLeft((X - DragOff - EdX0 - ScrW) * HMax Div (T - Th));
      End;
  End;
End;

Procedure MouseUp(X, Y : LongInt);
Var I : LongInt;
Begin
  If Drag = dToolbar Then
  Begin
    I := TbHit(X, Y);
    If (I >= 0) And (I = TbDown) Then
    Begin
      TbDown := -1;
      InvalBand(0, 0, CW, TbH);
      DoCmd(TbCmd[I]);
    End;
    TbDown := -1;
    InvalBand(0, 0, CW, TbH);
  End
  Else If (Drag = dText) And (Cur >= 0) Then
  Begin
    If Not HasSel(Cur) Then DSel[Cur] := False;
  End;
  If Drag <> dNone Then Dummy := WinSetCapture(HWND_DESKTOP, 0);
  Drag := dNone;
End;

Procedure RightClick(X, Y : LongInt);
Var I, R, Fy : LongInt;
Begin
  If Y < TbH + QbH * Ord(ShowQb) Then Exit;
  If ShowPanel And (X < PanW) Then
  Begin
    If Y < Y0 + TreeH Then
    Begin
      R := (Y - Y0 - 3) Div RowH;
      If (R >= 0) And (NTop + R < NNode) Then SelectNode(NTop + R);
      Pane := 1;
      Popup(1, X, CH - 1 - Y);
    End
    Else
    Begin
      Fy := Y0 + TreeH + 4 + 22;
      If Y >= Fy Then
      Begin
        I := FTop + (Y - Fy) Div RowH;
        If I < NFile Then FSel := I;
      End;
      Pane := 2;
      InvalBand(0, Y0, PanW, Y1 + 1);
      Popup(2, X, CH - 1 - Y);
    End;
    Exit;
  End;
  If X < EdX0 Then Exit;
  If Y >= DtY Then
  Begin
    For I := 0 To NDoc - 1 Do
      If (X >= DtX[I]) And (X < DtX[I + 1]) Then
      Begin
        SetCur(Order[I]);
        Popup(3, X, CH - 1 - Y);
      End;
    Exit;
  End;
  If Cur >= 0 Then Popup(0, X, CH - 1 - Y);
End;

{ panneau : clavier de l'arbre et de la liste }
Function PaneKey(Fl, Ch_, Vk : LongInt) : Boolean;
Var I : LongInt;
Begin
  PaneKey := True;
  If Pane = 1 Then
  Begin
    I := NSel;
    If (Fl And KC_VIRTUALKEY) <> 0 Then
      Case Vk Of
        VK_UP : If I > 0 Then SelectNode(I - 1);
        VK_DOWN : If I < NNode - 1 Then SelectNode(I + 1);
        VK_HOME : SelectNode(0);
        VK_END : SelectNode(NNode - 1);
        VK_RIGHT : If Not NOpen[I] Then ToggleNode(I) Else If I < NNode - 1 Then SelectNode(I + 1);
        VK_LEFT :
          If NOpen[I] Then ToggleNode(I)
          Else
          Begin
            While (I > 0) And (NLev[I - 1] >= NLev[NSel]) Do Dec(I);
            If I > 0 Then SelectNode(I - 1);
          End;
        VK_ENTER, VK_NEWLINE : ToggleNode(I);
        VK_TAB :
          Begin
            Pane := 2;
            If (FSel < 0) And (NFile > 0) Then FSel := 0;
            Redraw;
          End;
      Else
        PaneKey := False;
      End
    Else If ((Fl And KC_CHAR) <> 0) And ((Ch_ = Ord('+')) Or (Ch_ = Ord('-'))) Then ToggleNode(I)
    Else PaneKey := False;
    Exit;
  End;
  If Pane = 2 Then
  Begin
    If (Fl And KC_VIRTUALKEY) <> 0 Then
    Begin
      Case Vk Of
        VK_UP : If FSel > 0 Then Dec(FSel);
        VK_DOWN : If FSel < NFile - 1 Then Inc(FSel);
        VK_HOME : FSel := 0;
        VK_END : FSel := NFile - 1;
        VK_PAGEUP : FSel := MaxI(0, FSel - FileRows + 1);
        VK_PAGEDOWN : FSel := MinI(NFile - 1, FSel + FileRows - 1);
        VK_ENTER, VK_NEWLINE :
          If (FSel >= 0) And (FSel < NFile) Then OpenFile(JoinPath(SpecDir(CurDir), FName[FSel]));
        VK_TAB :
          Begin
            If Cur >= 0 Then Pane := 0 Else Pane := 1;
            Redraw;
          End;
      Else
        PaneKey := False;
      End;
      ShowFile;
      InvalBand(0, Y0, PanW, Y1 + 1);
    End
    Else PaneKey := False;
    Exit;
  End;
  PaneKey := False;
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
  { raccourcis }
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    Case Vk Of
      VK_F1 : Begin DoCmd(cmHelp); Exit; End;
      VK_F3 : Begin DoCmd(cmFindNext); Exit; End;
      VK_F5 : Begin DoCmd(cmRefresh); Exit; End;
      VK_F9 :
        Begin
          If Ctrl Then DoCmd(cmRun) Else DoCmd(cmPanel);
          Exit;
        End;
      VK_F12 : Begin DoCmd(cmBrowse); Exit; End;
      VK_F1 + 3 :
        If Ctrl Then
        Begin
          DoCmd(cmClose);
          Exit;
        End;
      VK_TAB :
        If Ctrl Then
        Begin
          { document suivant (Maj : precedent) }
          If NDoc > 1 Then
          Begin
            K := 0;
            While (K < NDoc) And (Order[K] <> Cur) Do Inc(K);
            If Shift Then K := (K + NDoc - 1) Mod NDoc Else K := (K + 1) Mod NDoc;
            SetCur(Order[K]);
          End;
          Exit;
        End;
      VK_ESC :
        If Pane <> 0 Then
        Begin
          Pane := 0;
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
      Ord('n') : Begin DoCmd(cmNewHtml); Exit; End;
      Ord('o') : Begin DoCmd(cmOpen); Exit; End;
      Ord('s') : Begin DoCmd(cmSave); Exit; End;
      Ord('z') : Begin DoCmd(cmUndo); Exit; End;
      Ord('y') : Begin DoCmd(cmRedo); Exit; End;
      Ord('x') : Begin DoCmd(cmCut); Exit; End;
      Ord('c') :
        Begin
          If Shift Then DoCmd(cmComment) Else DoCmd(cmCopy);
          Exit;
        End;
      Ord('v') : Begin DoCmd(cmPaste); Exit; End;
      Ord('a') : Begin DoCmd(cmSelAll); Exit; End;
      Ord('f') : Begin DoCmd(cmFind); Exit; End;
      Ord('h') : Begin DoCmd(cmReplace); Exit; End;
      Ord('g') : Begin DoCmd(cmGoto); Exit; End;
      Ord('m') : Begin DoCmd(cmMatchTag); Exit; End;
      Ord('w') : Begin DoCmd(cmClose); Exit; End;
      Ord('u') :
        Begin
          If Shift Then DoCmd(cmUpper) Else DoCmd(cmLower);
          Exit;
        End;
    End;
  End;
  If (Pane <> 0) And ShowPanel Then
  Begin
    If PaneKey(Fl, Ch_, Vk) Then Exit;
  End;
  If (Cur >= 0) And EditKey(Fl, Ch_, Vk) Then
  Begin
    Pane := 0;
    Exit;
  End;
  Key := False;
End;

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
        { bulle des boutons de la barre d'outils dans la barre d'etat }
        K := -1;
        If (Y < TbH) And (Drag = dNone) Then K := TbHit(X, Y);
        If (K >= 0) And (StatusMsg <> TbTip[K]) Then
        Begin
          If Not TipOn Then TipSave := StatusMsg;
          StatusMsg := TbTip[K];
          TipOn := True;
          InvalBand(0, CH - SbH, CW, CH);
        End
        Else If (K < 0) And TipOn Then
        Begin
          StatusMsg := TipSave;
          TipOn := False;
          InvalBand(0, CH - SbH, CW, CH);
        End;
        { pointeur : bords deplacables, texte }
        K := 0;
        If ShowPanel And (Y >= Y0) And (Y <= Y1) And (X >= PanW) And (X < EdX0) Then K := 8
        Else If ShowPanel And (X < PanW) And (Y >= Y0 + TreeH) And (Y < Y0 + TreeH + 4) Then K := 9
        Else If (Drag = dSplitV) Then K := 8
        Else If (Drag = dSplitH) Then K := 9
        Else If (Cur >= 0) And (X >= TxX0) And (X < VsX) And (Y >= Y0) And (Y < HsY) Then K := 2;
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
        { molette : sous le pointeur }
        K := 0;
        If Hi16(Mp2) = SB_LINEUP Then K := -3 Else If Hi16(Mp2) = SB_LINEDOWN Then K := 3;
        If ShowPanel And (LastMx < PanW) Then
        Begin
          If LastMy < Y0 + TreeH Then NTop := MaxI(0, NTop + K)
          Else FTop := MaxI(0, MinI(FTop + K, NFile - FileRows));
          InvalBand(0, Y0, PanW, Y1 + 1);
        End
        Else If Cur >= 0 Then ScrollTo(DTop[Cur] + K);
      End;
    WM_CHAR :
      If Key(Mp1, Mp2) Then ClientProc := 1
      Else ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
    WM_COMMAND : DoCmd(Lo16(Mp1));
    WM_TIMER :
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

Procedure Main;
Var Fl, Sw, Sh, Fw, Fh, K : LongInt; S : String;
Begin
  NDoc := 0; Cur := -1;
  For K := 0 To MaxDoc - 1 Do
  Begin
    DUsed[K] := False; DNoName[K] := False; DLangFix[K] := False;
  End;
  BufInit(Tmp); BufInit(Clip);
  LAttr := Nil; LAttrCap := 0;
  ShowNums := True; ShowQb := True; ShowPanel := True; InsMode := True; CaretOn := True; HasFocus := True;
  WebOnly := False; SrvBg := True;
  FindS := ''; ReplS := ''; FindCase := False;
  Pane := 0; Drag := dNone; NewCount := 0; CtxMenu := 0; TipOn := False;
  StatusMsg := 'Pr'#136't.';
  S := ParamStr(0);
  MyDir := DirOf(S);
  ToolbarInit;
  QuickBarInit;
  TreeInit;
  { dossier de depart : le site Web par defaut s'il existe }
  S := EnvStr('WEBSRV_ROOT');
  If S = '' Then S := 'C:\WWW';
  If FExists(S + '\ROOT') Then S := S + '\ROOT'
  Else If FExists('D:\WWW\ROOT') Then S := 'D:\WWW\ROOT'
  Else S := 'C:';
  TreeGoto(S);
  If CurDir = '' Then SelectNode(0);
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('WEBDEV'), LongInt(@ClientProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('WEBDEV'), Z2('Web Developer'), 0, 0, 0,
                              LongInt(@Client));
  BuildMenu;
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Fw := MinI(Sw, 640); Fh := MinI(Sh - 20, 460);
  If Sw >= 1000 Then
  Begin
    Fw := 980; Fh := MinI(Sh - 50, 680);
  End
  Else If Sw >= 800 Then
  Begin
    Fw := 796; Fh := MinI(Sh - 30, 560);
  End;
  PanW := Fw Div 4 + 20;
  TreeH := (Fh - 40 - TbH - QbH - SbH) Div 2;
  CW := Fw - 8; CH := Fh - 40;
  Layout;
  ShowNode;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) < 2) Or (S[2] <> ':') Then S := JoinPath(CurDir, S);
    OpenFile(S);
  End;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 500);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@GQmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@GQmsg));
  Dummy := WinDestroyWindow(Frame);
End;

BEGIN
  Main;
END.
