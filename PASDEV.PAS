{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: PASDEV - Pascal Developer, environnement de developpement
                integre (EDI) Pascal pour le Presentation Manager d'OS/2-0.
}

Program PASDEV;

{$R-,S-,I-}

{ Compilation : OS2PC PASDEV.PAS   (produit PASDEV.EXE)

  Pascal Developer est l'environnement de developpement du dossier
  Developer Kit du bureau : un editeur de sources Pascal a fenetres
  multiples (MDI) avec coloration syntaxique, dans l'esprit de Borland
  Pascal mais avec l'apparence d'OS/2. Le compilateur est OS2PC.EXE (OS/2
  Pascal Compiler), lance avec sa sortie standard redirigee vers un
  fichier : ses messages s'affichent dans la fenetre Messages (double
  clic ou Entree : la ligne en cause).

  Menus : Fichier (Nouveau, Ouvrir, Enregistrer, Enregistrer sous,
  Enregistrer tout, Fermer, Quitter), Edition (Couper, Copier, Coller,
  Effacer, Tout selectionner), Recherche (Rechercher, Occurrence suivante,
  Aller a la ligne, Ouvrir le fichier au curseur), Executer (Executer,
  Parametres), Compiler (Compiler, Information, Destination : OS/2
  Presentation Manager par defaut, ou OS/2 Console), Fenetre (Mosaique,
  Cascade, Suivante, Messages, Fermer tout, liste des fenetres), Aide
  (Touches, A propos). Barre d'etat : ligne et colonne du curseur,
  Insertion ou Refrappe, fichier modifie, destination de la compilation.
  Menu contextuel de l'editeur (bouton 2 de la souris ou Maj+F10) :
  Couper, Copier, Coller, Effacer, Tout selectionner, Ouvrir le fichier
  au curseur, Aller a la ligne, Compiler, Executer, Information.

  Les fenetres d'edition sont dessinees dans la zone de travail de la
  fenetre principale : barre de titre (deplacement, double clic :
  agrandir), case de fermeture, case d'agrandissement, barres de
  defilement et coin de redimensionnement.

  Touches (Borland et CUA) : F2 enregistrer, F3 ouvrir, Alt+F3 fermer,
  F6 fenetre suivante, F9 compiler, Ctrl+F9 executer, Alt+X
  quitter, Ins insertion/refrappe, Maj+fleches selection, Ctrl+Ins ou
  Ctrl+C copier, Maj+Suppr ou Ctrl+X couper, Maj+Ins ou Ctrl+V coller,
  Ctrl+Suppr effacer, Ctrl+A tout selectionner, Ctrl+Y supprimer la
  ligne, Ctrl+F rechercher, Ctrl+L occurrence suivante, Ctrl+G aller a
  la ligne, Ctrl+Entree ouvrir le fichier au curseur, Ctrl+fleches mot
  par mot, Ctrl+Origine/Fin debut/fin du fichier.

  Parametres : fichiers sources a ouvrir. }

Uses Dos;

Const
  WM_CREATE = $0001; WM_SIZE = $0007; WM_SETFOCUS = $000F;
  WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024;
  WM_CLOSE = $0029; WM_QUIT = $002A; WM_CONTROL = $0030;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
  WM_BUTTON2DOWN = $0074; WM_BUTTON2UP = $0075; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20;
  FCF_DLGBORDER = $200; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000;
  WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006; WC_LISTBOX = $FFFF0007;
  BS_PUSHBUTTON = 0; BS_DEFAULT = $0400; ES_AUTOSCROLL = 4; ES_MARGIN = 8;
  EM_SETTEXTLIMIT = $0143; EM_SETSEL = $0142;
  LM_DELETEALL = $016E; LM_INSERTITEM = $0161; LM_QUERYSELECTION = $0165; LM_SELECTITEM = $0164;
  LN_SELECT = 1; LN_ENTER = 5;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_CHECKED = $2000; MIA_DISABLED = $4000; MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_YESNOCANCEL = 3; MB_INFORMATION = $30; MB_WARNING = $20; MB_ERROR = $40;
  MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6; MBID_NO = 7; MBID_CANCEL = 2;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08; VK_ESC = $0F;
  VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14; VK_LEFT = $15; VK_UP = $16;
  VK_RIGHT = $17; VK_DOWN = $18; VK_INSERT = $1A; VK_DELETE = $1B; VK_ENTER = $1E;
  VK_F1 = $20;
  SPTR_ARROW = 1; SPTR_TEXT = 2; SPTR_WAIT = 3; SPTR_SIZENWSE = 5; SPTR_MOVE = 10;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4;
  CLR_CYAN = 5; CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKPINK = 11; CLR_DARKGREEN = 12; CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  { couleurs du systeme (barres de titre, comme les cadres de PM) }
  SYSCLR_INACTIVETITLE = -22; SYSCLR_ACTIVETITLE = -23;
  SYSCLR_ACTIVETITLETEXT = -28; SYSCLR_INACTIVETITLETEXT = -29;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  DT_CENTER = $100; DT_VCENTER = $400; DT_MNEMONIC = $2000;

  { --- commandes --- }
  CM_NEW = 101; CM_OPEN = 102; CM_SAVE = 103; CM_SAVEAS = 104; CM_SAVEALL = 105;
  CM_CLOSE = 106; CM_EXIT = 107;
  CM_CUT = 201; CM_COPY = 202; CM_PASTE = 203; CM_CLEAR = 204; CM_SELALL = 205;
  CM_FIND = 301; CM_FINDNEXT = 302; CM_GOTO = 303; CM_OPENCUR = 304;
  CM_RUN = 401; CM_PARAMS = 402;
  CM_COMPILE = 501; CM_INFO = 502; CM_TGTPM = 503; CM_TGTCON = 504;
  CM_TILE = 601; CM_CASCADE = 602; CM_NEXT = 603; CM_MESSAGES = 604; CM_CLOSEALL = 605;
  CM_WIN0 = 650;                       { 650..665 : fenetres (menu Fenetre) }
  CM_KEYS = 701; CM_ABOUT = 702;
  ID_DOK = 1; ID_DCANCEL = 2; ID_DEF = 20; ID_DLIST = 21;
  { dialogues }
  DM_SAVEAS = 1; DM_FIND = 2; DM_GOTO = 3; DM_PARAMS = 4; DM_OPEN = 5;

  { --- limites et dimensions --- }
  MAXWIN = 16;                         { fenetres (sources et Messages) }
  MAXLEN = 250;                        { longueur d'une ligne de source }
  SLOT = 256;                          { octets par ligne dans le bloc d'un document }
  MAXMSG = 300;                        { lignes de la fenetre Messages }
  CHW = 8; CHH = 16;                   { cellule de la police du systeme }
  BRD = 3;                             { bordure des fenetres d'edition }
  TTLH = 20;                           { barre de titre }
  SBW = 16;                            { barres de defilement }
  STATH = 22;                          { barre d'etat }
  TABSZ = 2;                           { tabulation : espaces }
  WK_EDIT = 1; WK_MSG = 2;
  { glisser de la souris }
  DG_NONE = 0; DG_MOVE = 1; DG_SIZE = 2; DG_VTHUMB = 3; DG_HTHUMB = 4; DG_SEL = 5;
  { etats du lexeur de coloration (debut de ligne) }
  ST_NORMAL = 0; ST_BRACE = 1; ST_PAREN = 2;
  { mots reserves et directives de Turbo Pascal (coloration) }
  { (deux chaines : une constante chaine a au plus 255 caracteres) }
  KEYWORDS = ' AND ARRAY ASM BEGIN CASE CONST CONSTRUCTOR DESTRUCTOR DIV DO DOWNTO ELSE END ' +
             'EXPORTS FILE FOR FUNCTION GOTO IF IMPLEMENTATION IN INHERITED INLINE INTERFACE ';
  KEYWORDS2 = ' LABEL LIBRARY MOD NIL NOT OBJECT OF OR PACKED PROCEDURE PROGRAM RECORD REPEAT SET ' +
              'SHL SHR STRING THEN TO TYPE UNIT UNTIL USES VAR WHILE WITH XOR ';
  DIRECTIVES = ' ABSOLUTE ASSEMBLER EXTERNAL FAR FORWARD INTERRUPT NEAR PRIVATE PUBLIC ' +
               'VIRTUAL NAME INDEX ';

Type
  PStr = ^String;
  PLong = ^LongInt;
  PByte = ^Byte;
  TWin = Record
    Used : Boolean;
    Kind : LongInt;                    { WK_EDIT ou WK_MSG }
    X, Y, W, H : LongInt;              { position dans la zone de travail (haut gauche) }
    NX, NY, NW, NH : LongInt;          { position avant agrandissement }
    Max : Boolean;
    FileName : String;                 { '' : sans nom }
    Untitled : LongInt;                { numero de NONAMEnn.PAS }
    Modified : Boolean;
    NLines, Cap : LongInt;             { lignes, capacite du bloc }
    Mem : LongInt;                     { bloc : lignes (SLOT octets), index, pile libre, etats }
    IdxOfs, FreeOfs, StOfs : LongInt;
    FreeCnt : LongInt;
    StValid : LongInt;                 { etats de coloration valides pour les lignes 0..StValid-1 }
    CX, CY : LongInt;                  { curseur : colonne et ligne (0 = premiere) }
    TopL, LeftC : LongInt;             { defilement }
    SelOn : Boolean;
    SAX, SAY : LongInt;                { ancre de la selection }
    Num : LongInt;                     { numero affiche dans le titre }
    ShownMod : Boolean;                { etat Modifie dessine dans le titre }
  End;

Var
  Hab, Hmq, Frame, Client, MenuHw, CtxMenu, Dummy : LongInt;
  CW, CH : LongInt;                    { zone client }
  Wins : Array[0..MAXWIN - 1] Of TWin;
  ZOrd : Array[0..MAXWIN - 1] Of LongInt;  { ordre d'empilement : ZOrd[NZ-1] = active }
  NZ : LongInt;
  MsgWin : LongInt;                    { fenetre Messages (-1) }
  MsgText : Array[0..MAXMSG - 1] Of String;
  MsgLine : Array[0..MAXMSG - 1] Of LongInt;
  MsgCount, MsgSel, MsgTop : LongInt;
  InsMode : Boolean;
  Target : LongInt;                    { 0 : OS/2 PM, 1 : OS/2 Console }
  RunParams : String;
  FindText : String;
  UntitledSeq, WinSeq : LongInt;
  StatusMsg : String;
  { glisser de la souris }
  Drag, DragWin, DragDX, DragDY : LongInt;
  { derniere compilation (Information) }
  LastSrc, LastExe : String;
  LastOk, LastDone : Boolean;
  LastLines, LastCode, LastData, LastImports, LastSize, LastErrs, LastWarns, LastTime : LongInt;
  LastTarget : LongInt;
  { repertoires }
  ExeDir, WorkDir, CompilerPath : String;
  { dialogue courant (non modal) }
  DlgFr, DlgCl, DlgEf, DlgLb, DlgMode : LongInt;
  DlgPrompt, DlgDir : String;
  { boites Information et A propos }
  InfoFr, AboutFr : LongInt;
  NameZ, NameZ2, TxtBuf, ArgBuf, FailBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..4095] Of Byte;
  MenuLen : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  ClipBuf : Array[0..16383] Of Byte;
  PicBmi : Array[0..15 + 64] Of Byte;  { BITMAPINFO2 (16 octets) + 16 couleurs }
  PicBits : Array[0..72 * 176 - 1] Of Byte;
  PicReady : Boolean;

{ --- PMWIN.DLL, PMGPI.DLL, PMVIOP.DLL, DOSCALLS.DLL --- }
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
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt; External 'PMWIN';
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryActiveWindow(HD : LongInt) : LongInt; External 'PMWIN';
Function WinSetPointer(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysPointer(HD, Id, Ld : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinUpdateWindow(H : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function WinInitShield(Hab, Hmq : LongInt) : LongInt; External 'PMVIOP' Name 'WININITSHIELD';
Function WinCreateConsole(Own, PTitle, Fl, PH : LongInt) : LongInt; External 'PMVIOP' Name 'WINCREATECONSOLE';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeMem(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetDefaultDisk(Disk : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetCurrentDir(PName : LongInt) : LongInt; External 'DOSCALLS';
Function SetStdHandle(N, H : LongInt) : LongInt; External 'DOSCALLS';
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function DosWaitChild(Action, Option, PRes, PPid, Pid : LongInt) : LongInt; External 'DOSCALLS';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Procedure WrB(A, V : LongInt);
Var Q : PByte;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Function RdB(A : LongInt) : LongInt;
Var Q : PByte;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrL(A, V : LongInt);
Var Q : PLong;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Function RdL(A : LongInt) : LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; C : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    C := RdB(A);
    While (C <> 0) And (Length(S) < 255) Do
    Begin
      S := S + Chr(C);
      Inc(A);
      C := RdB(A);
    End;
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
  S := IStr(V);
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
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

Function Spaces(N : LongInt) : String;
Var S : String;
Begin
  S := '';
  While (N > 0) And (Length(S) < 255) Do
  Begin
    S := S + ' ';
    Dec(N);
  End;
  Spaces := S;
End;

Function TrimR(S : String) : String;
Begin
  While (Length(S) > 0) And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
  TrimR := S;
End;

Function Trim(S : String) : String;
Begin
  While (Length(S) > 0) And (S[1] = ' ') Do Delete(S, 1, 1);
  Trim := TrimR(S);
End;

Function IsIdCh(C : Char) : Boolean;
Begin
  IsIdCh := ((C >= 'A') And (C <= 'Z')) Or ((C >= 'a') And (C <= 'z')) Or
            ((C >= '0') And (C <= '9')) Or (C = '_');
End;

{ copie memoire avec recouvrement }
Procedure MemMove(Src, Dst, N : LongInt);
Var Ps, Pd : PByte;
Begin
  If N <= 0 Then Exit;
  Ps := Pointer(Src); Pd := Pointer(Dst);
  Move(Ps^, Pd^, N);
End;

Function FileExists(N : String) : Boolean;
Var F : File; R : LongInt;
Begin
  FileExists := False;
  If N = '' Then Exit;
  Assign(F, N);
  {$I-} Reset(F, 1); {$I+}
  R := IOResult;
  If R = 0 Then
  Begin
    Close(F);
    FileExists := True;
  End;
End;

Function FileSizeOf(N : String) : LongInt;
Var F : File; R : LongInt;
Begin
  FileSizeOf := -1;
  Assign(F, N);
  {$I-} Reset(F, 1); {$I+}
  R := IOResult;
  If R = 0 Then
  Begin
    FileSizeOf := FileSize(F);
    Close(F);
  End;
End;

{ repertoire d'un chemin (avec \ final), nom sans repertoire, extension }
Function DirOf(S : String) : String;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '\') And (S[K] <> ':') Do Dec(K);
  DirOf := Copy(S, 1, K);
End;

Function NameOf(S : String) : String;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '\') And (S[K] <> ':') Do Dec(K);
  NameOf := Copy(S, K + 1, 255);
End;

Function ChangeExt(S, E : String) : String;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '.') And (S[K] <> '\') And (S[K] <> ':') Do Dec(K);
  If (K > 0) And (S[K] = '.') Then S := Copy(S, 1, K - 1);
  ChangeExt := S + E;
End;

Function HasExt(S : String) : Boolean;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '.') And (S[K] <> '\') And (S[K] <> ':') Do Dec(K);
  HasExt := (K > 0) And (S[K] = '.');
End;

{ chemin complet (lecteur et repertoire courants) }
Function FullPath(S : String) : String;
Begin
  If S = '' Then FullPath := ''
  Else FullPath := UpStr(FExpand(S));
End;

Procedure ShowMsg(Text, Cap : String; Fl : LongInt);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

Function AskYesNo(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  AskYesNo := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

{ caracteres du CP850 pour les accents des messages }
Function Acc(S : String) : String;
Var K : LongInt; R : String;
Begin
  R := '';
  K := 1;
  While K <= Length(S) Do
  Begin
    If (S[K] = '^') And (K < Length(S)) Then
    Begin
      Inc(K);
      Case S[K] Of
        'e' : R := R + Chr(130);       { e aigu }
        'E' : R := R + Chr(144);       { E aigu }
        'g' : R := R + Chr(138);       { e grave }
        'a' : R := R + Chr(133);       { a grave }
        'c' : R := R + Chr(135);       { c cedille }
        'o' : R := R + Chr(147);       { o circonflexe }
        'i' : R := R + Chr(140);       { i circonflexe }
        'u' : R := R + Chr(150);       { u circonflexe }
        'x' : R := R + Chr(136);       { e circonflexe }
      Else R := R + S[K];
      End;
    End
    Else R := R + S[K];
    Inc(K);
  End;
  Acc := R;
End;

{ ==================================================================== }
{ Documents : lignes dans un bloc DosAllocMem                           }
{ ==================================================================== }
{ Bloc d'un document de capacite C : C lignes de SLOT octets (chaines
  Pascal), puis l'index (C LongInt : ligne -> numero de case), la pile
  des cases libres (C LongInt) et l'etat de coloration au debut de
  chaque ligne (C octets). Inserer ou supprimer une ligne deplace
  seulement l'index. }

Function BlockSize(C : LongInt) : LongInt;
Begin
  BlockSize := C * SLOT + C * 4 + C * 4 + C;
End;

Function AllocBlock(C : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := 0;
  If DosAllocMem(LongInt(@P), BlockSize(C), $13) <> 0 Then P := 0;
  AllocBlock := P;
End;

Procedure SetLayout(W : LongInt);
Begin
  Wins[W].IdxOfs := Wins[W].Cap * SLOT;
  Wins[W].FreeOfs := Wins[W].IdxOfs + Wins[W].Cap * 4;
  Wins[W].StOfs := Wins[W].FreeOfs + Wins[W].Cap * 4;
End;

Function SlotOf(W, I : LongInt) : LongInt;
Begin
  SlotOf := RdL(Wins[W].Mem + Wins[W].IdxOfs + I * 4);
End;

Function LineAddr(W, I : LongInt) : LongInt;
Begin
  LineAddr := Wins[W].Mem + SlotOf(W, I) * SLOT;
End;

Function GetLine(W, I : LongInt) : String;
Var P : PStr;
Begin
  If (W < 0) Or (I < 0) Or (I >= Wins[W].NLines) Then GetLine := ''
  Else
  Begin
    P := Pointer(LineAddr(W, I));
    GetLine := P^;
  End;
End;

Function LineLen(W, I : LongInt) : LongInt;
Begin
  If (I < 0) Or (I >= Wins[W].NLines) Then LineLen := 0
  Else LineLen := RdB(LineAddr(W, I));
End;

Procedure Touch(W, I : LongInt);
Begin
  If I < Wins[W].StValid Then Wins[W].StValid := MaxI(0, I);
  Wins[W].Modified := True;
End;

Procedure SetLine(W, I : LongInt; S : String);
Var P : PStr;
Begin
  If (I < 0) Or (I >= Wins[W].NLines) Then Exit;
  If Length(S) > MAXLEN Then S := Copy(S, 1, MAXLEN);
  P := Pointer(LineAddr(W, I));
  P^ := S;
  Touch(W, I + 1);
End;

{ nouveau document vide de capacite C (une ligne vide) }
Function DocInit(W, C : LongInt) : Boolean;
Var K : LongInt;
Begin
  DocInit := False;
  If C < 256 Then C := 256;
  Wins[W].Mem := AllocBlock(C);
  If Wins[W].Mem = 0 Then Exit;
  Wins[W].Cap := C;
  SetLayout(W);
  { cases libres : C-1 ... 0 (la case 0 sort en premier) }
  For K := 0 To C - 1 Do WrL(Wins[W].Mem + Wins[W].FreeOfs + K * 4, C - 1 - K);
  Wins[W].FreeCnt := C;
  Wins[W].NLines := 0;
  Wins[W].StValid := 0;
  DocInit := True;
End;

Procedure DocFree(W : LongInt);
Begin
  If Wins[W].Mem <> 0 Then Dummy := DosFreeMem(Wins[W].Mem);
  Wins[W].Mem := 0;
  Wins[W].Cap := 0;
  Wins[W].NLines := 0;
End;

{ doubler la capacite }
Function DocGrow(W : LongInt) : Boolean;
Var NC, NM, K, OldCap, OldMem, OldIdx, OldSt : LongInt;
Begin
  DocGrow := False;
  OldCap := Wins[W].Cap;
  NC := OldCap * 2;
  NM := AllocBlock(NC);
  If NM = 0 Then Exit;
  OldMem := Wins[W].Mem;
  OldIdx := OldMem + Wins[W].IdxOfs;
  OldSt := OldMem + Wins[W].StOfs;
  MemMove(OldMem, NM, OldCap * SLOT);
  Wins[W].Mem := NM;
  Wins[W].Cap := NC;
  SetLayout(W);
  MemMove(OldIdx, NM + Wins[W].IdxOfs, OldCap * 4);
  MemMove(OldSt, NM + Wins[W].StOfs, OldCap);
  { nouvelles cases libres OldCap..NC-1, au-dessous des anciennes libres }
  MemMove(OldMem + OldCap * SLOT + OldCap * 4, NM + Wins[W].FreeOfs + (NC - OldCap) * 4, Wins[W].FreeCnt * 4);
  For K := 0 To NC - OldCap - 1 Do WrL(NM + Wins[W].FreeOfs + K * 4, NC - 1 - K);
  Wins[W].FreeCnt := Wins[W].FreeCnt + NC - OldCap;
  Dummy := DosFreeMem(OldMem);
  DocGrow := True;
End;

{ inserer la ligne S avant la ligne I (I = NLines : a la fin) }
Function DocIns(W, I : LongInt; S : String) : Boolean;
Var Sl, A : LongInt;
Begin
  DocIns := False;
  If Wins[W].FreeCnt = 0 Then
    If Not DocGrow(W) Then
    Begin
      ShowMsg(Acc('M^emoire insuffisante : le fichier est trop grand.'), 'Pascal Developer', MB_OK Or MB_ERROR);
      Exit;
    End;
  Dec(Wins[W].FreeCnt);
  Sl := RdL(Wins[W].Mem + Wins[W].FreeOfs + Wins[W].FreeCnt * 4);
  A := Wins[W].Mem + Wins[W].IdxOfs;
  MemMove(A + I * 4, A + (I + 1) * 4, (Wins[W].NLines - I) * 4);
  WrL(A + I * 4, Sl);
  Inc(Wins[W].NLines);
  WrB(Wins[W].Mem + Sl * SLOT, 0);
  SetLine(W, I, S);
  Touch(W, I);
  DocIns := True;
End;

Procedure DocDel(W, I : LongInt);
Var A : LongInt;
Begin
  If (I < 0) Or (I >= Wins[W].NLines) Then Exit;
  A := Wins[W].Mem + Wins[W].IdxOfs;
  WrL(Wins[W].Mem + Wins[W].FreeOfs + Wins[W].FreeCnt * 4, SlotOf(W, I));
  Inc(Wins[W].FreeCnt);
  MemMove(A + (I + 1) * 4, A + I * 4, (Wins[W].NLines - I - 1) * 4);
  Dec(Wins[W].NLines);
  Touch(W, I);
End;

{ ==================================================================== }
{ Coloration syntaxique : etat (commentaire ouvert) au debut des lignes }
{ ==================================================================== }

{ etat a la fin de la ligne S commencee dans l'etat St }
Function ScanState(S : String; St : LongInt) : LongInt;
Var K, N : LongInt; C : Char;
Begin
  K := 1;
  N := Length(S);
  While K <= N Do
  Begin
    C := S[K];
    If St = ST_BRACE Then
    Begin
      If C = '}' Then St := ST_NORMAL;
      Inc(K);
    End
    Else If St = ST_PAREN Then
    Begin
      If (C = '*') And (K < N) And (S[K + 1] = ')') Then
      Begin
        St := ST_NORMAL;
        Inc(K);
      End;
      Inc(K);
    End
    Else
    Begin
      If C = '{' Then St := ST_BRACE
      Else If (C = '(') And (K < N) And (S[K + 1] = '*') Then
      Begin
        St := ST_PAREN;
        Inc(K);
      End
      Else If (C = '/') And (K < N) And (S[K + 1] = '/') Then K := N
      Else If C = '''' Then
      Begin
        Inc(K);
        While (K <= N) And (S[K] <> '''') Do Inc(K);
      End;
      Inc(K);
    End;
  End;
  ScanState := St;
End;

Function StateAt(W, I : LongInt) : LongInt;
Var K, St : LongInt;
Begin
  If I <= 0 Then
  Begin
    StateAt := ST_NORMAL;
    Exit;
  End;
  If I > Wins[W].NLines Then I := Wins[W].NLines;
  If Wins[W].StValid < 1 Then
  Begin
    WrB(Wins[W].Mem + Wins[W].StOfs, ST_NORMAL);
    Wins[W].StValid := 1;
  End;
  K := Wins[W].StValid - 1;
  St := RdB(Wins[W].Mem + Wins[W].StOfs + K);
  While K < I Do
  Begin
    St := ScanState(GetLine(W, K), St);
    Inc(K);
    If K < Wins[W].Cap Then WrB(Wins[W].Mem + Wins[W].StOfs + K, St);
    Wins[W].StValid := K + 1;
  End;
  StateAt := RdB(Wins[W].Mem + Wins[W].StOfs + I);
End;

{ ==================================================================== }
{ Fichiers                                                              }
{ ==================================================================== }

Function ExpandTabs(S : String) : String;
Var R : String; K : LongInt;
Begin
  If Pos(#9, S) = 0 Then
  Begin
    ExpandTabs := S;
    Exit;
  End;
  R := '';
  For K := 1 To Length(S) Do
    If S[K] = #9 Then
    Begin
      Repeat
        R := R + ' ';
      Until (Length(R) Mod 8 = 0) Or (Length(R) >= MAXLEN);
    End
    Else If Length(R) < 255 Then R := R + S[K];
  ExpandTabs := R;
End;

{ charger le fichier N dans le document W (deja initialise) ; Faux si
  le fichier ne peut etre lu }
Function LoadFile(W : LongInt; N : String) : Boolean;
Var F : Text; S : String; R : LongInt;
Begin
  LoadFile := False;
  Assign(F, N);
  {$I-} Reset(F); {$I+}
  R := IOResult;
  If R <> 0 Then Exit;
  While Not EOF(F) Do
  Begin
    ReadLn(F, S);
    S := ExpandTabs(S);
    If Not DocIns(W, Wins[W].NLines, S) Then Break;
  End;
  Close(F);
  If Wins[W].NLines = 0 Then
    If DocIns(W, 0, '') Then ;
  Wins[W].Modified := False;
  LoadFile := True;
End;

Function SaveFile(W : LongInt; N : String) : Boolean;
Var F : Text; K, R, Last : LongInt;
Begin
  SaveFile := False;
  Assign(F, N);
  {$I-} Rewrite(F); {$I+}
  R := IOResult;
  If R <> 0 Then
  Begin
    ShowMsg(Acc('Impossible de cr^eer le fichier ') + N + Acc(' (erreur ') + IStr(R) + ').',
            'Pascal Developer', MB_OK Or MB_ERROR);
    Exit;
  End;
  { sans les lignes vides de la fin }
  Last := Wins[W].NLines - 1;
  While (Last > 0) And (TrimR(GetLine(W, Last)) = '') Do Dec(Last);
  For K := 0 To Last Do WriteLn(F, TrimR(GetLine(W, K)));
  Close(F);
  R := IOResult;
  If R <> 0 Then
  Begin
    ShowMsg(Acc('Erreur d''^ecriture du fichier ') + N + '.', 'Pascal Developer', MB_OK Or MB_ERROR);
    Exit;
  End;
  Wins[W].Modified := False;
  SaveFile := True;
End;

{ ==================================================================== }
{ Dessin (coordonnees depuis le coin haut gauche de la zone client)     }
{ ==================================================================== }

Function WorkH : LongInt;
Begin
  WorkH := MaxI(0, CH - STATH);
End;

{ rectangle plein (X1, Y1) - (X2, Y2) exclus }
Procedure FillR(Hps, X1, Y1, X2, Y2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  Rc[0] := X1; Rc[1] := CH - Y2; Rc[2] := X2; Rc[3] := CH - Y1;
  Dummy := WinFillRect(Hps, LongInt(@Rc), C);
End;

Procedure DrawLn(Hps, X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := CH - 1 - Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := CH - 1 - Y2;
  Dummy := GpiLine(Hps, LongInt(@P));
End;

{ relief : clair en haut a gauche, sombre en bas a droite (Up) ou l'inverse }
Procedure Bevel(Hps, X1, Y1, X2, Y2 : LongInt; Up : Boolean);
Var A, B : LongInt;
Begin
  If Up Then Begin A := CLR_WHITE; B := CLR_DARKGRAY; End
  Else Begin A := CLR_DARKGRAY; B := CLR_WHITE; End;
  DrawLn(Hps, X1, Y1, X2 - 1, Y1, A);
  DrawLn(Hps, X1, Y1, X1, Y2 - 1, A);
  DrawLn(Hps, X1, Y2 - 1, X2 - 1, Y2 - 1, B);
  DrawLn(Hps, X2 - 1, Y1, X2 - 1, Y2 - 1, B);
End;

{ texte : cellule haut gauche (X, Y), coupe a XMax }
Procedure TextAt(Hps, X, Y, XMax : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (S = '') Or (X >= XMax) Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := CH - Y - CHH; Rc[2] := MinI(XMax, X + Length(S) * CHW); Rc[3] := CH - Y;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ texte centre dans (X1, Y1) - (X2, Y2) }
Procedure TextCenter(Hps, X1, Y1, X2, Y2 : LongInt; S : String; Fg, Bg : LongInt);
Var X, Y : LongInt;
Begin
  If Length(S) * CHW > X2 - X1 Then S := Copy(S, 1, MaxI(0, (X2 - X1) Div CHW));
  X := X1 + ((X2 - X1) - Length(S) * CHW) Div 2;
  Y := Y1 + ((Y2 - Y1) - CHH) Div 2;
  TextAt(Hps, X, Y, X2, S, Fg, Bg);
End;

{ petits triangles des boutons de defilement : Dir 0 haut, 1 bas, 2 gauche, 3 droite }
Procedure Arrow(Hps, X1, Y1, X2, Y2, Dir : LongInt);
Var Cx, Cy, K : LongInt;
Begin
  Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
  For K := 0 To 3 Do
    Case Dir Of
      0 : DrawLn(Hps, Cx - K, Cy - 2 + K, Cx + K, Cy - 2 + K, CLR_BLACK);
      1 : DrawLn(Hps, Cx - K, Cy + 1 - K, Cx + K, Cy + 1 - K, CLR_BLACK);
      2 : DrawLn(Hps, Cx - 2 + K, Cy - K, Cx - 2 + K, Cy + K, CLR_BLACK);
      3 : DrawLn(Hps, Cx + 1 - K, Cy - K, Cx + 1 - K, Cy + K, CLR_BLACK);
    End;
End;

{ ==================================================================== }
{ Fenetres : geometrie                                                  }
{ ==================================================================== }

Function TopWin : LongInt;
Begin
  If NZ > 0 Then TopWin := ZOrd[NZ - 1] Else TopWin := -1;
End;

{ fenetre d'edition active (-1 : aucune, ou la fenetre Messages est devant) }
Function ActEdit : LongInt;
Var W : LongInt;
Begin
  W := TopWin;
  If (W >= 0) And (Wins[W].Kind = WK_EDIT) Then ActEdit := W Else ActEdit := -1;
End;

Procedure Geo(W : LongInt; Var X, Y, Wd, Ht : LongInt);
Begin
  If Wins[W].Max Then
  Begin
    X := 0; Y := 0; Wd := CW; Ht := WorkH;
  End
  Else
  Begin
    X := Wins[W].X; Y := Wins[W].Y; Wd := Wins[W].W; Ht := Wins[W].H;
  End;
End;

{ zone du texte (X1, Y1) - (X2, Y2) exclus }
Procedure TextArea(W : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Var X, Y, Wd, Ht : LongInt;
Begin
  Geo(W, X, Y, Wd, Ht);
  X1 := X + BRD; Y1 := Y + BRD + TTLH;
  X2 := X + Wd - BRD - SBW; Y2 := Y + Ht - BRD - SBW;
End;

Function Rows(W : LongInt) : LongInt;
Var X1, Y1, X2, Y2 : LongInt;
Begin
  TextArea(W, X1, Y1, X2, Y2);
  Rows := MaxI(1, (Y2 - Y1) Div CHH);
End;

Function Cols(W : LongInt) : LongInt;
Var X1, Y1, X2, Y2 : LongInt;
Begin
  TextArea(W, X1, Y1, X2, Y2);
  Cols := MaxI(1, (X2 - X1 - 4) Div CHW);
End;

Function ContentLines(W : LongInt) : LongInt;
Begin
  If Wins[W].Kind = WK_MSG Then ContentLines := MsgCount Else ContentLines := Wins[W].NLines;
End;

Function WinTitle(W : LongInt) : String;
Var T : String;
Begin
  If Wins[W].Kind = WK_MSG Then T := 'Messages'
  Else If Wins[W].FileName = '' Then T := 'NONAME' + IStr(Wins[W].Untitled) + '.PAS'
  Else T := Wins[W].FileName;
  If (Wins[W].Kind = WK_EDIT) And Wins[W].Modified Then T := T + ' *';
  WinTitle := T;
End;

{ ==================================================================== }
{ Selection                                                             }
{ ==================================================================== }

{ debut (L1, C1) et fin (L2, C2) exclue de la selection, dans l'ordre }
Procedure SelRange(W : LongInt; Var L1, C1, L2, C2 : LongInt);
Begin
  If (Wins[W].SAY < Wins[W].CY) Or ((Wins[W].SAY = Wins[W].CY) And (Wins[W].SAX <= Wins[W].CX)) Then
  Begin
    L1 := Wins[W].SAY; C1 := Wins[W].SAX; L2 := Wins[W].CY; C2 := Wins[W].CX;
  End
  Else
  Begin
    L1 := Wins[W].CY; C1 := Wins[W].CX; L2 := Wins[W].SAY; C2 := Wins[W].SAX;
  End;
End;

Function HasSel(W : LongInt) : Boolean;
Begin
  HasSel := (W >= 0) And Wins[W].SelOn And
            ((Wins[W].SAX <> Wins[W].CX) Or (Wins[W].SAY <> Wins[W].CY));
End;

{ le caractere (L, C) est-il selectionne ? }
Function InSel(W, L, C : LongInt) : Boolean;
Var L1, C1, L2, C2 : LongInt;
Begin
  InSel := False;
  If Not HasSel(W) Then Exit;
  SelRange(W, L1, C1, L2, C2);
  If (L < L1) Or (L > L2) Then Exit;
  If (L = L1) And (C < C1) Then Exit;
  If (L = L2) And (C >= C2) Then Exit;
  InSel := True;
End;

{ ==================================================================== }
{ Dessin des fenetres                                                   }
{ ==================================================================== }

{ couleurs des caracteres de la ligne S (etat St au debut) dans Col }
Var Col : Array[0..256] Of Byte;     { couleurs des caracteres (ColorLine) }

Procedure ColorLine(S : String; St : LongInt);
Var K, N, J, C0 : LongInt; Wd : String; Dir : Boolean;
Begin
  N := Length(S);
  K := 1;
  Dir := False;
  While K <= N Do
  Begin
    If St = ST_BRACE Then
    Begin
      If Dir Then Col[K] := CLR_DARKCYAN Else Col[K] := CLR_DARKGREEN;
      If S[K] = '}' Then
      Begin
        St := ST_NORMAL;
        Dir := False;
      End;
      Inc(K);
    End
    Else If St = ST_PAREN Then
    Begin
      Col[K] := CLR_DARKGREEN;
      If (S[K] = '*') And (K < N) And (S[K + 1] = ')') Then
      Begin
        Col[K + 1] := CLR_DARKGREEN;
        St := ST_NORMAL;
        Inc(K);
      End;
      Inc(K);
    End
    Else If S[K] = '{' Then
    Begin
      St := ST_BRACE;
      Dir := (K < N) And (S[K + 1] = '$');
      If Dir Then Col[K] := CLR_DARKCYAN Else Col[K] := CLR_DARKGREEN;
      Inc(K);
    End
    Else If (S[K] = '(') And (K < N) And (S[K + 1] = '*') Then
    Begin
      St := ST_PAREN;
      Col[K] := CLR_DARKGREEN; Col[K + 1] := CLR_DARKGREEN;
      K := K + 2;
    End
    Else If (S[K] = '/') And (K < N) And (S[K + 1] = '/') Then
    Begin
      While K <= N Do
      Begin
        Col[K] := CLR_DARKGREEN;
        Inc(K);
      End;
    End
    Else If S[K] = '''' Then
    Begin
      Col[K] := CLR_DARKRED;
      Inc(K);
      While (K <= N) And (S[K] <> '''') Do
      Begin
        Col[K] := CLR_DARKRED;
        Inc(K);
      End;
      If K <= N Then
      Begin
        Col[K] := CLR_DARKRED;
        Inc(K);
      End;
    End
    Else If (S[K] = '#') And (K < N) And (((S[K + 1] >= '0') And (S[K + 1] <= '9')) Or (S[K + 1] = '$')) Then
    Begin
      Col[K] := CLR_DARKRED;
      Inc(K);
      If (K <= N) And (S[K] = '$') Then
      Begin
        Col[K] := CLR_DARKRED;
        Inc(K);
      End;
      While (K <= N) And IsIdCh(S[K]) Do
      Begin
        Col[K] := CLR_DARKRED;
        Inc(K);
      End;
    End
    Else If ((S[K] >= '0') And (S[K] <= '9')) Or
            ((S[K] = '$') And (K < N) And (Pos(UpCase(S[K + 1]), '0123456789ABCDEF') > 0)) Then
    Begin
      Col[K] := CLR_DARKPINK;
      Inc(K);
      While (K <= N) And (IsIdCh(S[K]) Or (S[K] = '.')) Do
      Begin
        If (S[K] = '.') And (K < N) And (S[K + 1] = '.') Then Break;
        Col[K] := CLR_DARKPINK;
        Inc(K);
      End;
    End
    Else If IsIdCh(S[K]) Then
    Begin
      J := K;
      While (J <= N) And IsIdCh(S[J]) Do Inc(J);
      Wd := ' ' + UpStr(Copy(S, K, J - K)) + ' ';
      If (Pos(Wd, KEYWORDS) > 0) Or (Pos(Wd, KEYWORDS2) > 0) Then C0 := CLR_DARKBLUE
      Else If Pos(Wd, DIRECTIVES) > 0 Then C0 := CLR_BLUE
      Else C0 := CLR_BLACK;
      While K < J Do
      Begin
        Col[K] := C0;
        Inc(K);
      End;
    End
    Else
    Begin
      Col[K] := CLR_BLACK;
      Inc(K);
    End;
  End;
End;

{ une ligne de texte de la fenetre d'edition W }
Procedure PaintLine(Hps, W, I, X1, Y, X2 : LongInt; Active : Boolean);
Var S, Run : String; K, C0, Fg, Bg, Fg0, Bg0, X, NC, Lc : LongInt;
  Sel : Boolean;
Begin
  FillR(Hps, X1, Y, X2, Y + CHH, CLR_WHITE);
  If I >= Wins[W].NLines Then Exit;
  S := GetLine(W, I);
  ColorLine(S, StateAt(W, I));
  NC := (X2 - X1 - 4) Div CHW;
  Lc := Wins[W].LeftC;
  X := X1 + 4;
  Run := '';
  Fg0 := 0; Bg0 := 0;
  For K := Lc + 1 To MinI(Length(S) + 1, Lc + NC) Do
  Begin
    Sel := InSel(W, I, K - 1);
    If K > Length(S) Then
    Begin
      { fin de ligne selectionnee : une case }
      If Not Sel Then Break;
      C0 := 32; Fg := CLR_WHITE; Bg := CLR_DARKBLUE;
    End
    Else
    Begin
      C0 := Ord(S[K]);
      If Sel Then Begin Fg := CLR_WHITE; Bg := CLR_DARKBLUE; End
      Else Begin Fg := Col[K]; Bg := CLR_WHITE; End;
    End;
    If (Run <> '') And ((Fg <> Fg0) Or (Bg <> Bg0)) Then
    Begin
      TextAt(Hps, X, Y, X2, Run, Fg0, Bg0);
      X := X + Length(Run) * CHW;
      Run := '';
    End;
    Run := Run + Chr(C0);
    Fg0 := Fg; Bg0 := Bg;
  End;
  If Run <> '' Then TextAt(Hps, X, Y, X2, Run, Fg0, Bg0);
  { curseur }
  If Active And (I = Wins[W].CY) And (Wins[W].CX >= Lc) And (Wins[W].CX < Lc + NC) Then
  Begin
    X := X1 + 4 + (Wins[W].CX - Lc) * CHW;
    If InsMode Then FillR(Hps, X, Y, X + 2, Y + CHH, CLR_BLACK)
    Else
    Begin
      If Wins[W].CX < Length(S) Then C0 := Ord(S[Wins[W].CX + 1]) Else C0 := 32;
      TextAt(Hps, X, Y, X2, Chr(C0), CLR_WHITE, CLR_BLACK);
    End;
  End;
End;

Procedure PaintText(Hps, W : LongInt; Active : Boolean);
Var X1, Y1, X2, Y2, R, K, I, Fg, Bg : LongInt; S : String;
Begin
  TextArea(W, X1, Y1, X2, Y2);
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  R := (Y2 - Y1 + CHH - 1) Div CHH;
  If Wins[W].Kind = WK_MSG Then
  Begin
    For K := 0 To R - 1 Do
    Begin
      I := Wins[W].TopL + K;
      If (I < MsgCount) And (I = MsgSel) And Active Then Begin Fg := CLR_WHITE; Bg := CLR_DARKBLUE; End
      Else If (I < MsgCount) And (MsgLine[I] = -2) Then Begin Fg := CLR_DARKRED; Bg := CLR_WHITE; End
      Else Begin Fg := CLR_BLACK; Bg := CLR_WHITE; End;
      FillR(Hps, X1, Y1 + K * CHH, X2, MinI(Y2, Y1 + (K + 1) * CHH), Bg);
      If I < MsgCount Then
      Begin
        S := Copy(MsgText[I], Wins[W].LeftC + 1, 255);
        TextAt(Hps, X1 + 4, Y1 + K * CHH, X2, S, Fg, Bg);
      End;
    End;
    Exit;
  End;
  For K := 0 To R - 1 Do
  Begin
    If Y1 + (K + 1) * CHH > Y2 Then
    Begin
      FillR(Hps, X1, Y1 + K * CHH, X2, Y2, CLR_WHITE);
      Break;
    End;
    PaintLine(Hps, W, Wins[W].TopL + K, X1, Y1 + K * CHH, X2, Active);
  End;
End;

{ position (0..Len) et taille du curseur d'une barre de defilement }
Procedure ThumbOf(Len, Total, Vis, Pos : LongInt; Var TPos, TSize : LongInt);
Begin
  If Total <= Vis Then
  Begin
    TPos := 0; TSize := Len;
    Exit;
  End;
  TSize := MaxI(12, (Len * Vis) Div Total);
  If TSize > Len Then TSize := Len;
  TPos := ((Len - TSize) * Pos) Div MaxI(1, Total - Vis);
  If TPos > Len - TSize Then TPos := Len - TSize;
  If TPos < 0 Then TPos := 0;
End;

Procedure PaintButton(Hps, X1, Y1, X2, Y2 : LongInt);
Begin
  FillR(Hps, X1, Y1, X2, Y2, CLR_PALEGRAY);
  Bevel(Hps, X1, Y1, X2, Y2, True);
End;

Procedure PaintScrollBars(Hps, W : LongInt);
Var X1, Y1, X2, Y2, L, TP, TS, MaxC : LongInt;
Begin
  TextArea(W, X1, Y1, X2, Y2);
  { verticale }
  FillR(Hps, X2, Y1, X2 + SBW, Y2, CLR_PALEGRAY);
  DrawLn(Hps, X2, Y1, X2, Y2 - 1, CLR_DARKGRAY);
  PaintButton(Hps, X2, Y1, X2 + SBW, Y1 + SBW); Arrow(Hps, X2, Y1, X2 + SBW, Y1 + SBW, 0);
  PaintButton(Hps, X2, Y2 - SBW, X2 + SBW, Y2); Arrow(Hps, X2, Y2 - SBW, X2 + SBW, Y2, 1);
  L := Y2 - Y1 - 2 * SBW;
  If L > 4 Then
  Begin
    ThumbOf(L, ContentLines(W), Rows(W), Wins[W].TopL, TP, TS);
    PaintButton(Hps, X2, Y1 + SBW + TP, X2 + SBW, Y1 + SBW + TP + TS);
  End;
  { horizontale }
  FillR(Hps, X1, Y2, X2, Y2 + SBW, CLR_PALEGRAY);
  DrawLn(Hps, X1, Y2, X2 - 1, Y2, CLR_DARKGRAY);
  PaintButton(Hps, X1, Y2, X1 + SBW, Y2 + SBW); Arrow(Hps, X1, Y2, X1 + SBW, Y2 + SBW, 2);
  PaintButton(Hps, X2 - SBW, Y2, X2, Y2 + SBW); Arrow(Hps, X2 - SBW, Y2, X2, Y2 + SBW, 3);
  L := X2 - X1 - 2 * SBW;
  MaxC := MAXLEN + 1;
  If L > 4 Then
  Begin
    ThumbOf(L, MaxC, Cols(W), Wins[W].LeftC, TP, TS);
    PaintButton(Hps, X1 + SBW + TP, Y2, X1 + SBW + TP + TS, Y2 + SBW);
  End;
  { coin de redimensionnement }
  FillR(Hps, X2, Y2, X2 + SBW, Y2 + SBW, CLR_PALEGRAY);
  DrawLn(Hps, X2 + 4, Y2 + SBW - 2, X2 + SBW - 2, Y2 + 4, CLR_DARKGRAY);
  DrawLn(Hps, X2 + 8, Y2 + SBW - 2, X2 + SBW - 2, Y2 + 8, CLR_DARKGRAY);
  DrawLn(Hps, X2 + 12, Y2 + SBW - 2, X2 + SBW - 2, Y2 + 12, CLR_DARKGRAY);
End;

Procedure PaintFrame(Hps, W : LongInt; Active : Boolean);
Var X, Y, Wd, Ht, Tb, Tf, B, K : LongInt; T : String;
Begin
  Geo(W, X, Y, Wd, Ht);
  { bordure en relief }
  FillR(Hps, X, Y, X + Wd, Y + BRD, CLR_PALEGRAY);
  FillR(Hps, X, Y + Ht - BRD, X + Wd, Y + Ht, CLR_PALEGRAY);
  FillR(Hps, X, Y, X + BRD, Y + Ht, CLR_PALEGRAY);
  FillR(Hps, X + Wd - BRD, Y, X + Wd, Y + Ht, CLR_PALEGRAY);
  Bevel(Hps, X, Y, X + Wd, Y + Ht, True);
  DrawLn(Hps, X + BRD - 1, Y + BRD - 1, X + Wd - BRD, Y + BRD - 1, CLR_DARKGRAY);
  { barre de titre aux couleurs du systeme }
  If Active Then Begin Tb := SYSCLR_ACTIVETITLE; Tf := SYSCLR_ACTIVETITLETEXT; End
  Else Begin Tb := SYSCLR_INACTIVETITLE; Tf := SYSCLR_INACTIVETITLETEXT; End;
  FillR(Hps, X + BRD, Y + BRD, X + Wd - BRD, Y + BRD + TTLH, Tb);
  B := TTLH - 4;
  { case de fermeture (menu systeme) a gauche }
  PaintButton(Hps, X + BRD + 2, Y + BRD + 2, X + BRD + 2 + B, Y + BRD + 2 + B);
  FillR(Hps, X + BRD + 5, Y + BRD + 1 + B Div 2, X + BRD + B - 1, Y + BRD + 3 + B Div 2, CLR_BLACK);
  { case d'agrandissement a droite }
  PaintButton(Hps, X + Wd - BRD - 2 - B, Y + BRD + 2, X + Wd - BRD - 2, Y + BRD + 2 + B);
  If Wins[W].Max Then
  Begin
    { restaurer : deux petites fenetres }
    K := X + Wd - BRD - 2 - B;
    DrawLn(Hps, K + 6, Y + BRD + 5, K + B - 4, Y + BRD + 5, CLR_BLACK);
    DrawLn(Hps, K + B - 4, Y + BRD + 5, K + B - 4, Y + BRD + B - 7, CLR_BLACK);
    FillR(Hps, K + 4, Y + BRD + 8, K + B - 6, Y + BRD + 10, CLR_BLACK);
    DrawLn(Hps, K + 4, Y + BRD + 8, K + 4, Y + BRD + B - 2, CLR_BLACK);
    DrawLn(Hps, K + B - 7, Y + BRD + 8, K + B - 7, Y + BRD + B - 2, CLR_BLACK);
    DrawLn(Hps, K + 4, Y + BRD + B - 2, K + B - 7, Y + BRD + B - 2, CLR_BLACK);
  End
  Else
  Begin
    K := X + Wd - BRD - 2 - B;
    FillR(Hps, K + 4, Y + BRD + 6, K + B - 4, Y + BRD + 8, CLR_BLACK);
    DrawLn(Hps, K + 4, Y + BRD + 6, K + 4, Y + BRD + B - 2, CLR_BLACK);
    DrawLn(Hps, K + B - 5, Y + BRD + 6, K + B - 5, Y + BRD + B - 2, CLR_BLACK);
    DrawLn(Hps, K + 4, Y + BRD + B - 2, K + B - 5, Y + BRD + B - 2, CLR_BLACK);
  End;
  { titre : numero et nom }
  Wins[W].ShownMod := Wins[W].Modified;
  T := IStr(Wins[W].Num) + ' - ' + WinTitle(W);
  TextCenter(Hps, X + BRD + B + 6, Y + BRD, X + Wd - BRD - B - 6, Y + BRD + TTLH, T, Tf, Tb);
End;

Procedure PaintWin(Hps, W : LongInt; Active : Boolean);
Begin
  PaintFrame(Hps, W, Active);
  PaintText(Hps, W, Active);
  PaintScrollBars(Hps, W);
End;

Function TargetName(T : LongInt) : String;
Begin
  If T = 0 Then TargetName := 'OS/2 PM' Else TargetName := 'OS/2 Console';
End;

Procedure PaintStatus(Hps : LongInt);
Var Y, W, X, R : LongInt; S : String;
Begin
  Y := WorkH;
  FillR(Hps, 0, Y, CW, CH, CLR_PALEGRAY);
  DrawLn(Hps, 0, Y, CW - 1, Y, CLR_WHITE);
  W := ActEdit;
  R := CW - 4;
  { champs de droite : destination, modifie, insertion, position }
  S := TargetName(Target);
  X := R - Length(S) * CHW - 8;
  Bevel(Hps, X, Y + 3, R, CH - 2, False);
  TextAt(Hps, X + 4, Y + 4, R, S, CLR_BLACK, CLR_PALEGRAY);
  R := X - 4;
  If InsMode Then S := 'Insertion' Else S := 'Refrappe';
  X := R - 9 * CHW - 8;
  Bevel(Hps, X, Y + 3, R, CH - 2, False);
  TextAt(Hps, X + 4, Y + 4, R, S, CLR_BLACK, CLR_PALEGRAY);
  R := X - 4;
  If (W >= 0) And Wins[W].Modified Then S := Acc('Modifi^e') Else S := '';
  X := R - 7 * CHW - 8;
  Bevel(Hps, X, Y + 3, R, CH - 2, False);
  TextAt(Hps, X + 4, Y + 4, R, S, CLR_DARKRED, CLR_PALEGRAY);
  R := X - 4;
  If W >= 0 Then S := 'Ligne ' + IStr(Wins[W].CY + 1) + '  Col ' + IStr(Wins[W].CX + 1) Else S := '';
  X := R - 17 * CHW - 8;
  Bevel(Hps, X, Y + 3, R, CH - 2, False);
  TextAt(Hps, X + 4, Y + 4, R, S, CLR_BLACK, CLR_PALEGRAY);
  { message ou rappel des touches }
  If StatusMsg <> '' Then S := StatusMsg
  Else S := Acc('F2 Enreg.  F3 Ouvrir  F9 Compiler  Ctrl+F9 Ex^ecuter');
  Bevel(Hps, 4, Y + 3, X - 4, CH - 2, False);
  TextAt(Hps, 8, Y + 4, X - 6, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintAll(H : LongInt);
Var Hps, K, W, X1, Y1, X2, Y2 : LongInt; Rc : Array[0..3] Of LongInt; Only : Boolean;
Begin
  Rc[0] := 0; Rc[1] := 0; Rc[2] := 0; Rc[3] := 0;
  Hps := WinBeginPaint(H, 0, LongInt(@Rc));
  { seulement la zone de texte de la fenetre active a mettre a jour ? }
  W := TopWin;
  Only := False;
  If W >= 0 Then
  Begin
    TextArea(W, X1, Y1, X2, Y2);
    Only := (Rc[2] > Rc[0]) And (Rc[0] >= X1) And (Rc[2] <= X2) And (CH - Rc[3] >= Y1) And (CH - Rc[1] <= Y2);
  End;
  If Only Then PaintText(Hps, W, True)
  Else
  Begin
    FillR(Hps, 0, 0, CW, WorkH, CLR_DARKGRAY);
    For K := 0 To NZ - 1 Do PaintWin(Hps, ZOrd[K], K = NZ - 1);
    If NZ = 0 Then
      TextCenter(Hps, 0, 0, CW, WorkH, Acc('Fichier, Nouveau (Ctrl+N) ou Ouvrir (F3) : un source Pascal'),
                 CLR_PALEGRAY, CLR_DARKGRAY);
    PaintStatus(Hps);
  End;
  Dummy := WinEndPaint(Hps);
End;

{ ==================================================================== }
{ Invalidation                                                          }
{ ==================================================================== }

Procedure InvRect(X1, Y1, X2, Y2 : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[0] := X1; Rc[1] := CH - Y2; Rc[2] := X2; Rc[3] := CH - Y1;
  Dummy := WinInvalidateRect(Client, LongInt(@Rc), 0);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ texte de la fenetre active seulement (frappe) ; barre d'etat a part }
Procedure RedrawText(W : LongInt);
Var X1, Y1, X2, Y2 : LongInt;
Begin
  If (W <> TopWin) Or (Wins[W].ShownMod <> Wins[W].Modified) Then
  Begin
    Redraw;
    Exit;
  End;
  TextArea(W, X1, Y1, X2, Y2);
  InvRect(X1, Y1, X2, Y2);
  InvRect(0, WorkH, CW, CH);
End;

{ ==================================================================== }
{ Fenetres : creation, activation, disposition                          }
{ ==================================================================== }

Procedure ZRemove(W : LongInt);
Var K, J : LongInt;
Begin
  J := 0;
  For K := 0 To NZ - 1 Do
    If ZOrd[K] <> W Then
    Begin
      ZOrd[J] := ZOrd[K];
      Inc(J);
    End;
  NZ := J;
End;

Procedure Activate(W : LongInt);
Begin
  If (W < 0) Or Not Wins[W].Used Then Exit;
  ZRemove(W);
  ZOrd[NZ] := W;
  Inc(NZ);
  Redraw;
End;

Function FreeWin : LongInt;
Var K : LongInt;
Begin
  FreeWin := -1;
  For K := 0 To MAXWIN - 1 Do
    If Not Wins[K].Used Then
    Begin
      FreeWin := K;
      Exit;
    End;
End;

{ position par defaut d'une nouvelle fenetre (en cascade) }
Procedure PlaceNew(W : LongInt);
Var N : LongInt;
Begin
  N := NZ Mod 8;
  Wins[W].X := 8 + N * 22;
  Wins[W].Y := 6 + N * 22;
  Wins[W].W := MaxI(220, CW - 60 - N * 22);
  Wins[W].H := MaxI(140, WorkH - 50 - N * 22);
  If Wins[W].X + Wins[W].W > CW Then Wins[W].W := MaxI(120, CW - Wins[W].X);
  If Wins[W].Y + Wins[W].H > WorkH Then Wins[W].H := MaxI(100, WorkH - Wins[W].Y);
  Wins[W].Max := False;
End;

Function NewWin(Kind : LongInt) : LongInt;
Var W : LongInt;
Begin
  NewWin := -1;
  W := FreeWin;
  If W < 0 Then
  Begin
    ShowMsg(Acc('Trop de fen^etres ouvertes : fermez-en une.'), 'Pascal Developer', MB_OK Or MB_WARNING);
    Exit;
  End;
  FillChar(Wins[W], SizeOf(TWin), 0);
  Wins[W].Used := True;
  Wins[W].Kind := Kind;
  Wins[W].FileName := '';
  Inc(WinSeq);
  Wins[W].Num := WinSeq;
  PlaceNew(W);
  NewWin := W;
End;

{ document vide sans nom }
Function NewDoc : LongInt;
Var W : LongInt;
Begin
  NewDoc := -1;
  W := NewWin(WK_EDIT);
  If W < 0 Then Exit;
  If Not DocInit(W, 512) Then
  Begin
    Wins[W].Used := False;
    ShowMsg(Acc('M^emoire insuffisante.'), 'Pascal Developer', MB_OK Or MB_ERROR);
    Exit;
  End;
  If DocIns(W, 0, '') Then ;
  Wins[W].Modified := False;
  Inc(UntitledSeq);
  Wins[W].Untitled := UntitledSeq;
  Activate(W);
  NewDoc := W;
End;

Function FindDoc(N : String) : LongInt;
Var K : LongInt;
Begin
  FindDoc := -1;
  N := FullPath(N);
  For K := 0 To MAXWIN - 1 Do
    If Wins[K].Used And (Wins[K].Kind = WK_EDIT) And (Wins[K].FileName = N) Then
    Begin
      FindDoc := K;
      Exit;
    End;
End;

{ ouvrir N (deja ouvert : l'activer) ; Quiet : sans message d'erreur }
Function OpenDoc(N : String; Quiet : Boolean) : LongInt;
Var W, C, Sz : LongInt;
Begin
  OpenDoc := -1;
  N := Trim(N);
  If N = '' Then Exit;
  If Not HasExt(N) And Not FileExists(N) Then N := N + '.PAS';
  N := FullPath(N);
  W := FindDoc(N);
  If W >= 0 Then
  Begin
    Activate(W);
    OpenDoc := W;
    Exit;
  End;
  If Not FileExists(N) Then
  Begin
    If Not Quiet Then ShowMsg(Acc('Fichier introuvable : ') + N, 'Pascal Developer', MB_OK Or MB_ERROR);
    Exit;
  End;
  W := NewWin(WK_EDIT);
  If W < 0 Then Exit;
  { capacite : environ une ligne par 20 octets du fichier }
  Sz := FileSizeOf(N);
  C := MaxI(512, Sz Div 20 + 256);
  If Not DocInit(W, C) Then
  Begin
    Wins[W].Used := False;
    ShowMsg(Acc('M^emoire insuffisante pour ') + N, 'Pascal Developer', MB_OK Or MB_ERROR);
    Exit;
  End;
  If Not LoadFile(W, N) Then
  Begin
    DocFree(W);
    Wins[W].Used := False;
    ShowMsg(Acc('Lecture impossible : ') + N, 'Pascal Developer', MB_OK Or MB_ERROR);
    Exit;
  End;
  Wins[W].FileName := N;
  Activate(W);
  StatusMsg := NameOf(N) + ' : ' + NStr(Wins[W].NLines) + ' lignes';
  OpenDoc := W;
End;

Procedure CloseWinNow(W : LongInt);
Begin
  If W = MsgWin Then MsgWin := -1;
  If Wins[W].Kind = WK_EDIT Then DocFree(W);
  Wins[W].Used := False;
  ZRemove(W);
  Redraw;
End;

Function SaveDoc(W : LongInt) : Boolean; Forward;
Procedure OpenInput(Mode : LongInt; Title, Prompt, Def : String); Forward;

{ fermer W en demandant d'enregistrer ; Faux : annule }
Function CloseWin(W : LongInt) : Boolean;
Var R : LongInt;
Begin
  CloseWin := False;
  If (W < 0) Or Not Wins[W].Used Then Exit;
  If (Wins[W].Kind = WK_EDIT) And Wins[W].Modified Then
  Begin
    Activate(W);
    R := AskYesNo(WinTitle(W) + Acc(' a ^et^e modifi^e. Enregistrer les modifications ?'),
                  'Pascal Developer', MB_YESNOCANCEL Or MB_QUERY);
    If R = MBID_CANCEL Then Exit;
    If R = MBID_YES Then
      If Not SaveDoc(W) Then Exit;
  End;
  CloseWinNow(W);
  CloseWin := True;
End;

Function CloseAll : Boolean;
Var K : LongInt;
Begin
  CloseAll := False;
  For K := 0 To MAXWIN - 1 Do
    If Wins[K].Used Then
      If Not CloseWin(K) Then Exit;
  CloseAll := True;
End;

Procedure Tile;
Var K, N, C, R, I, Wd, Ht, W, AreaH : LongInt;
Begin
  If NZ = 0 Then Exit;
  { Messages en bas sur toute la largeur, les sources en grille au-dessus }
  AreaH := WorkH;
  If (MsgWin >= 0) And Wins[MsgWin].Used Then
  Begin
    Wins[MsgWin].Max := False;
    Wins[MsgWin].H := MaxI(80, WorkH Div 3);
    Wins[MsgWin].X := 0; Wins[MsgWin].W := CW;
    Wins[MsgWin].Y := WorkH - Wins[MsgWin].H;
    AreaH := Wins[MsgWin].Y;
  End;
  N := 0;
  For K := 0 To NZ - 1 Do
    If Wins[ZOrd[K]].Kind = WK_EDIT Then Inc(N);
  If N = 0 Then
  Begin
    Redraw;
    Exit;
  End;
  C := 1;
  While C * C < N Do Inc(C);
  R := (N + C - 1) Div C;
  Wd := CW Div C; Ht := AreaH Div R;
  I := 0;
  For K := 0 To NZ - 1 Do
  Begin
    W := ZOrd[K];
    If Wins[W].Kind = WK_EDIT Then
    Begin
      Wins[W].Max := False;
      Wins[W].X := (I Mod C) * Wd; Wins[W].Y := (I Div C) * Ht;
      Wins[W].W := Wd; Wins[W].H := Ht;
      { derniere rangee incomplete : les fenetres s'elargissent }
      If (I Div C = R - 1) And (N Mod C <> 0) Then
      Begin
        Wins[W].W := CW Div (N Mod C);
        Wins[W].X := (I Mod C) * Wins[W].W;
      End;
      Inc(I);
    End;
  End;
  Redraw;
End;

Procedure Cascade;
Var K, W : LongInt;
Begin
  For K := 0 To NZ - 1 Do
  Begin
    W := ZOrd[K];
    Wins[W].Max := False;
    Wins[W].X := K * 22; Wins[W].Y := K * 22;
    Wins[W].W := MaxI(200, CW - (NZ - 1) * 22);
    Wins[W].H := MaxI(120, WorkH - (NZ - 1) * 22);
  End;
  Redraw;
End;

Procedure NextWin;
Var T : LongInt;
Begin
  If NZ < 2 Then Exit;
  { la fenetre active passe dessous }
  T := ZOrd[NZ - 1];
  MemMove(LongInt(@ZOrd[0]), LongInt(@ZOrd[1]), (NZ - 1) * 4);
  ZOrd[0] := T;
  Redraw;
End;

Procedure ToggleMax(W : LongInt);
Begin
  Wins[W].Max := Not Wins[W].Max;
  Redraw;
End;

{ ==================================================================== }
{ Curseur et defilement                                                 }
{ ==================================================================== }

{ rendre le curseur visible }
Procedure ShowCursor(W : LongInt);
Var R, C : LongInt;
Begin
  R := Rows(W); C := Cols(W);
  If Wins[W].CY < Wins[W].TopL Then Wins[W].TopL := Wins[W].CY;
  If Wins[W].CY >= Wins[W].TopL + R Then Wins[W].TopL := Wins[W].CY - R + 1;
  If Wins[W].CX < Wins[W].LeftC Then Wins[W].LeftC := Wins[W].CX;
  If Wins[W].CX >= Wins[W].LeftC + C Then Wins[W].LeftC := Wins[W].CX - C + 1;
  If Wins[W].TopL < 0 Then Wins[W].TopL := 0;
  If Wins[W].LeftC < 0 Then Wins[W].LeftC := 0;
End;

Procedure ClampCursor(W : LongInt);
Begin
  If Wins[W].CY >= Wins[W].NLines Then Wins[W].CY := Wins[W].NLines - 1;
  If Wins[W].CY < 0 Then Wins[W].CY := 0;
  If Wins[W].CX < 0 Then Wins[W].CX := 0;
  If Wins[W].CX > MAXLEN Then Wins[W].CX := MAXLEN;
End;

{ deplacement : Ext etend la selection (Maj) }
Procedure CurTo(W, X, Y : LongInt; Ext : Boolean);
Begin
  If Ext Then
  Begin
    If Not Wins[W].SelOn Then
    Begin
      Wins[W].SelOn := True;
      Wins[W].SAX := Wins[W].CX; Wins[W].SAY := Wins[W].CY;
    End;
  End
  Else Wins[W].SelOn := False;
  Wins[W].CX := X; Wins[W].CY := Y;
  ClampCursor(W);
  ShowCursor(W);
End;

Procedure ScrollBy(W, DL, DC : LongInt);
Var MaxT : LongInt;
Begin
  MaxT := MaxI(0, ContentLines(W) - 1);
  Wins[W].TopL := Wins[W].TopL + DL;
  If Wins[W].TopL > MaxT Then Wins[W].TopL := MaxT;
  If Wins[W].TopL < 0 Then Wins[W].TopL := 0;
  Wins[W].LeftC := Wins[W].LeftC + DC;
  If Wins[W].LeftC > MAXLEN Then Wins[W].LeftC := MAXLEN;
  If Wins[W].LeftC < 0 Then Wins[W].LeftC := 0;
End;

{ ==================================================================== }
{ Edition                                                               }
{ ==================================================================== }

{ ligne completee d'espaces jusqu'a la colonne X }
Function PadTo(S : String; X : LongInt) : String;
Begin
  While Length(S) < X Do S := S + ' ';
  PadTo := S;
End;

{ supprimer la selection ; Vrai si quelque chose a ete supprime }
Function DeleteSel(W : LongInt) : Boolean;
Var L1, C1, L2, C2, K : LongInt; S, T : String;
Begin
  DeleteSel := False;
  If Not HasSel(W) Then
  Begin
    Wins[W].SelOn := False;
    Exit;
  End;
  SelRange(W, L1, C1, L2, C2);
  S := PadTo(GetLine(W, L1), C1);
  T := GetLine(W, L2);
  S := Copy(S, 1, C1) + Copy(T, C2 + 1, 255);
  For K := L2 DownTo L1 + 1 Do DocDel(W, K);
  SetLine(W, L1, S);
  Wins[W].CX := C1; Wins[W].CY := L1;
  Wins[W].SelOn := False;
  ShowCursor(W);
  DeleteSel := True;
End;

Procedure TypeChar(W : LongInt; C : Char);
Var S : String;
Begin
  If DeleteSel(W) Then ;
  If Wins[W].CX >= MAXLEN Then Exit;
  S := PadTo(GetLine(W, Wins[W].CY), Wins[W].CX);
  If InsMode Or (Wins[W].CX >= Length(S)) Then
  Begin
    If Length(TrimR(S)) >= MAXLEN Then Exit;
    Insert(C, S, Wins[W].CX + 1);
  End
  Else S[Wins[W].CX + 1] := C;
  SetLine(W, Wins[W].CY, S);
  Inc(Wins[W].CX);
  ShowCursor(W);
End;

{ Entree : couper la ligne, retrait de la ligne courante }
Procedure NewLine(W : LongInt);
Var S, Ind : String; K : LongInt;
Begin
  If DeleteSel(W) Then ;
  S := GetLine(W, Wins[W].CY);
  K := 0;
  While (K < Length(S)) And (S[K + 1] = ' ') Do Inc(K);
  If K > Wins[W].CX Then K := Wins[W].CX;
  Ind := Spaces(K);
  If Not DocIns(W, Wins[W].CY + 1, Ind + Trim(Copy(S, Wins[W].CX + 1, 255))) Then Exit;
  SetLine(W, Wins[W].CY, TrimR(Copy(S, 1, Wins[W].CX)));
  Inc(Wins[W].CY);
  Wins[W].CX := K;
  ShowCursor(W);
End;

Procedure BackSpace(W : LongInt);
Var S, P : String;
Begin
  If DeleteSel(W) Then Exit;
  If Wins[W].CX > 0 Then
  Begin
    S := GetLine(W, Wins[W].CY);
    If Wins[W].CX <= Length(S) Then Delete(S, Wins[W].CX, 1);
    SetLine(W, Wins[W].CY, S);
    Dec(Wins[W].CX);
  End
  Else If Wins[W].CY > 0 Then
  Begin
    P := GetLine(W, Wins[W].CY - 1);
    S := GetLine(W, Wins[W].CY);
    If Length(P) + Length(S) > MAXLEN Then Exit;
    SetLine(W, Wins[W].CY - 1, P + S);
    DocDel(W, Wins[W].CY);
    Dec(Wins[W].CY);
    Wins[W].CX := Length(P);
  End;
  ShowCursor(W);
End;

Procedure DeleteChar(W : LongInt);
Var S, N : String;
Begin
  If DeleteSel(W) Then Exit;
  S := GetLine(W, Wins[W].CY);
  If Wins[W].CX < Length(S) Then
  Begin
    Delete(S, Wins[W].CX + 1, 1);
    SetLine(W, Wins[W].CY, S);
  End
  Else If Wins[W].CY < Wins[W].NLines - 1 Then
  Begin
    N := GetLine(W, Wins[W].CY + 1);
    S := PadTo(S, Wins[W].CX);
    If Length(S) + Length(N) > MAXLEN Then Exit;
    SetLine(W, Wins[W].CY, S + N);
    DocDel(W, Wins[W].CY + 1);
  End;
End;

Procedure DeleteLine(W : LongInt);
Begin
  Wins[W].SelOn := False;
  If Wins[W].NLines <= 1 Then SetLine(W, 0, '')
  Else DocDel(W, Wins[W].CY);
  ClampCursor(W);
  Wins[W].CX := 0;
  ShowCursor(W);
End;

Procedure TabKey(W : LongInt);
Var N : LongInt;
Begin
  N := TABSZ - (Wins[W].CX Mod TABSZ);
  While N > 0 Do
  Begin
    TypeChar(W, ' ');
    Dec(N);
  End;
End;

{ mot sous le curseur ; Path : caracteres d'un nom de fichier admis }
Function OkCh(C : Char; Path : Boolean) : Boolean;
Begin
  OkCh := IsIdCh(C) Or (Path And ((C = '.') Or (C = '\') Or (C = ':') Or (C = '-')));
End;

Function WordAt(W : LongInt; Path : Boolean) : String;
Var S : String; A, B : LongInt;
Begin
  S := GetLine(W, Wins[W].CY);
  A := Wins[W].CX + 1;
  If (A > Length(S)) Or Not OkCh(S[A], Path) Then
    If (A > 1) And (A - 1 <= Length(S)) And OkCh(S[A - 1], Path) Then Dec(A);
  If (A > Length(S)) Or Not OkCh(S[A], Path) Then
  Begin
    WordAt := '';
    Exit;
  End;
  B := A;
  While (A > 1) And OkCh(S[A - 1], Path) Do Dec(A);
  While (B < Length(S)) And OkCh(S[B + 1], Path) Do Inc(B);
  WordAt := Copy(S, A, B - A + 1);
End;

{ selectionner le mot sous le curseur (double clic) }
Procedure SelectWord(W : LongInt);
Var S : String; A, B : LongInt;
Begin
  S := GetLine(W, Wins[W].CY);
  A := Wins[W].CX + 1;
  If (A > Length(S)) Or Not IsIdCh(S[A]) Then Exit;
  B := A;
  While (A > 1) And IsIdCh(S[A - 1]) Do Dec(A);
  While (B < Length(S)) And IsIdCh(S[B + 1]) Do Inc(B);
  Wins[W].SelOn := True;
  Wins[W].SAX := A - 1; Wins[W].SAY := Wins[W].CY;
  Wins[W].CX := B;
End;

Procedure SelectAll(W : LongInt);
Begin
  Wins[W].SelOn := True;
  Wins[W].SAX := 0; Wins[W].SAY := 0;
  Wins[W].CY := Wins[W].NLines - 1;
  Wins[W].CX := LineLen(W, Wins[W].CY);
  ShowCursor(W);
End;

{ mot suivant / precedent }
Procedure WordRight(W : LongInt; Ext : Boolean);
Var S : String; X, Y : LongInt;
Begin
  X := Wins[W].CX; Y := Wins[W].CY;
  S := GetLine(W, Y);
  If X >= Length(S) Then
  Begin
    If Y < Wins[W].NLines - 1 Then
    Begin
      Inc(Y);
      S := GetLine(W, Y);
      X := 0;
      While (X < Length(S)) And (S[X + 1] = ' ') Do Inc(X);
    End;
  End
  Else
  Begin
    While (X < Length(S)) And IsIdCh(S[X + 1]) Do Inc(X);
    While (X < Length(S)) And Not IsIdCh(S[X + 1]) Do Inc(X);
  End;
  CurTo(W, X, Y, Ext);
End;

Procedure WordLeft(W : LongInt; Ext : Boolean);
Var S : String; X, Y : LongInt;
Begin
  X := Wins[W].CX; Y := Wins[W].CY;
  S := GetLine(W, Y);
  If X > Length(S) Then X := Length(S);
  If X = 0 Then
  Begin
    If Y > 0 Then
    Begin
      Dec(Y);
      X := LineLen(W, Y);
    End;
  End
  Else
  Begin
    While (X > 0) And Not IsIdCh(S[X]) Do Dec(X);
    While (X > 0) And IsIdCh(S[X]) Do Dec(X);
  End;
  CurTo(W, X, Y, Ext);
End;

{ ==================================================================== }
{ Presse-papiers (CF_TEXT, lignes separees par CR LF)                   }
{ ==================================================================== }

Var ClipN : LongInt;

Procedure ClipPut(C : LongInt);
Begin
  If ClipN < SizeOf(ClipBuf) - 1 Then
  Begin
    ClipBuf[ClipN] := C;
    Inc(ClipN);
  End;
End;

Function SelText(W : LongInt) : Boolean;
Var L1, C1, L2, C2, K, J : LongInt; S : String;
Begin
  SelText := False;
  ClipN := 0;
  If Not HasSel(W) Then Exit;
  SelRange(W, L1, C1, L2, C2);
  For K := L1 To L2 Do
  Begin
    S := GetLine(W, K);
    If K = L2 Then S := Copy(PadTo(S, C2), 1, C2);
    If K = L1 Then S := Copy(S, C1 + 1, 255);
    For J := 1 To Length(S) Do ClipPut(Ord(S[J]));
    If K < L2 Then
    Begin
      ClipPut(13); ClipPut(10);
    End;
  End;
  ClipBuf[ClipN] := 0;
  SelText := True;
End;

Procedure CopySel(W : LongInt);
Begin
  If Not SelText(W) Then Exit;
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    Dummy := WinSetClipbrdData(Hab, LongInt(@ClipBuf), 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
End;

Procedure CutSel(W : LongInt);
Begin
  CopySel(W);
  If DeleteSel(W) Then ;
End;

{ inserer le texte T (CR LF, LF) au curseur }
Procedure InsertText(W, A : LongInt);
Var S, Tail, Cur : String; C : LongInt;
Begin
  If DeleteSel(W) Then ;
  S := PadTo(GetLine(W, Wins[W].CY), Wins[W].CX);
  Tail := Copy(S, Wins[W].CX + 1, 255);
  Cur := Copy(S, 1, Wins[W].CX);
  C := RdB(A);
  While C <> 0 Do
  Begin
    If C = 10 Then
    Begin
      SetLine(W, Wins[W].CY, Cur);
      If Not DocIns(W, Wins[W].CY + 1, '') Then Exit;
      Inc(Wins[W].CY);
      Cur := '';
    End
    Else If C = 9 Then
    Begin
      Repeat
        Cur := Cur + ' ';
      Until Length(Cur) Mod 8 = 0;
    End
    Else If (C <> 13) And (Length(Cur) < MAXLEN) Then Cur := Cur + Chr(C);
    Inc(A);
    C := RdB(A);
  End;
  Wins[W].CX := Length(Cur);
  SetLine(W, Wins[W].CY, Cur + Tail);
  ShowCursor(W);
End;

Procedure Paste(W : LongInt);
Var A : LongInt;
Begin
  If WinOpenClipbrd(Hab) = 0 Then Exit;
  A := WinQueryClipbrdData(Hab, 1);
  If A <> 0 Then InsertText(W, A);
  Dummy := WinCloseClipbrd(Hab);
End;

{ ==================================================================== }
{ Recherche                                                             }
{ ==================================================================== }

{ occurrence suivante de FindText (sans distinction des majuscules) }
Procedure FindAgain(W : LongInt);
Var K, Y, X, P : LongInt; S, F : String;
Begin
  If (W < 0) Or (FindText = '') Then Exit;
  F := UpStr(FindText);
  Y := Wins[W].CY;
  X := Wins[W].CX;
  For K := 0 To Wins[W].NLines Do
  Begin
    S := UpStr(GetLine(W, Y));
    If K = 0 Then S := Spaces(MinI(X, Length(S))) + Copy(S, X + 1, 255);
    P := Pos(F, S);
    If P > 0 Then
    Begin
      Wins[W].SelOn := True;
      Wins[W].SAY := Y; Wins[W].SAX := P - 1;
      Wins[W].CY := Y; Wins[W].CX := P - 1 + Length(F);
      ShowCursor(W);
      StatusMsg := '';
      Redraw;
      Exit;
    End;
    Inc(Y);
    X := 0;
    If Y >= Wins[W].NLines Then Y := 0;
  End;
  StatusMsg := Acc('Cha^ine introuvable : ') + FindText;
  Redraw;
End;

Procedure GotoLine(W, N : LongInt);
Begin
  If W < 0 Then Exit;
  If N < 1 Then N := 1;
  If N > Wins[W].NLines Then N := Wins[W].NLines;
  Wins[W].SelOn := False;
  Wins[W].CY := N - 1;
  Wins[W].CX := 0;
  { la ligne au premier tiers de la fenetre }
  Wins[W].TopL := MaxI(0, N - 1 - Rows(W) Div 3);
  ShowCursor(W);
  Redraw;
End;

{ ==================================================================== }
{ Fenetre Messages                                                      }
{ ==================================================================== }

Procedure MsgClear;
Begin
  MsgCount := 0;
  MsgSel := -1;
End;

{ Ln : ligne du source (>= 1), -1 : sans ligne, -2 : erreur sans ligne }
Procedure MsgAdd(S : String; L : LongInt);
Begin
  If MsgCount >= MAXMSG Then Exit;
  MsgText[MsgCount] := S;
  MsgLine[MsgCount] := L;
  Inc(MsgCount);
End;

Procedure ShowMessages;
Var W : LongInt;
Begin
  If MsgWin < 0 Then
  Begin
    W := NewWin(WK_MSG);
    If W < 0 Then Exit;
    MsgWin := W;
    Wins[W].X := 0; Wins[W].W := CW;
    Wins[W].H := MaxI(100, WorkH Div 3);
    Wins[W].Y := MaxI(0, WorkH - Wins[W].H);
  End;
  Wins[MsgWin].TopL := 0;
  Activate(MsgWin);
End;

{ aller a la ligne du message I dans le source compile }
Procedure MsgGo(I : LongInt);
Var W : LongInt;
Begin
  If (I < 0) Or (I >= MsgCount) Or (MsgLine[I] < 1) Then Exit;
  W := FindDoc(LastSrc);
  If W < 0 Then W := OpenDoc(LastSrc, False);
  If W < 0 Then Exit;
  Activate(W);
  GotoLine(W, MsgLine[I]);
  StatusMsg := MsgText[I];
End;

{ ==================================================================== }
{ Compilation et execution                                              }
{ ==================================================================== }

{ fenetre d'edition la plus haute (meme si Messages est devant) }
Function SrcWin : LongInt;
Var K : LongInt;
Begin
  SrcWin := -1;
  For K := NZ - 1 DownTo 0 Do
    If Wins[ZOrd[K]].Kind = WK_EDIT Then
    Begin
      SrcWin := ZOrd[K];
      Exit;
    End;
End;

Function SaveDoc(W : LongInt) : Boolean;
Begin
  SaveDoc := False;
  If Wins[W].FileName = '' Then
  Begin
    OpenInput(DM_SAVEAS, 'Enregistrer sous', 'Nom du fichier :', WorkDir + 'NONAME' + IStr(Wins[W].Untitled) + '.PAS');
    Exit;
  End;
  If SaveFile(W, Wins[W].FileName) Then
  Begin
    SaveDoc := True;
    StatusMsg := Acc('Enregistr^e : ') + Wins[W].FileName;
  End;
  Redraw;
End;

{ valeur entiere qui suit Key dans S (ex. 'code=') }
Function NumAfter(S, Key : String) : LongInt;
Var P, V, E : LongInt; T : String;
Begin
  NumAfter := -1;
  P := Pos(Key, S);
  If P = 0 Then Exit;
  T := '';
  P := P + Length(Key);
  While (P <= Length(S)) And (S[P] = ' ') Do Inc(P);
  While (P <= Length(S)) And (S[P] >= '0') And (S[P] <= '9') Do
  Begin
    T := T + S[P];
    Inc(P);
  End;
  If T = '' Then Exit;
  Val(T, V, E);
  If E = 0 Then NumAfter := V;
End;

{ message d'OS2PC -> texte de la fenetre Messages et ligne }
Procedure AddCompilerLine(S : String);
Var L, P : LongInt; Err : Boolean; T : String;
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
    If Err Then
    Begin
      Inc(LastErrs);
      T := 'Erreur : ' + T;
      If L < 1 Then L := -2;
    End
    Else
    Begin
      Inc(LastWarns);
      T := 'Avertissement : ' + T;
    End;
    If L >= 1 Then T := NameOf(LastSrc) + '(' + IStr(L) + ') ' + T;
    MsgAdd(T, L);
  End
  Else If Pos('PE genere', S) > 0 Then
  Begin
    LastSize := NumAfter(S, '(');
    LastCode := NumAfter(S, 'code=');
    LastData := NumAfter(S, 'data=');
    LastImports := NumAfter(S, 'imports=');
  End
  Else If Pos('Lignes analysees', S) > 0 Then LastLines := NumAfter(S, ':')
  Else If (Pos('OS2PC', S) = 1) And (Pos('OS2PC v', S) <> 1) Then
  Begin
    Inc(LastErrs);
    MsgAdd(Trim(S), -2);
  End
  Else If Pos('Runtime error', S) > 0 Then
  Begin
    Inc(LastErrs);
    MsgAdd(Acc('Erreur interne du compilateur : ') + Trim(S), -2);
  End;
End;

{ prepare ArgBuf : "programme#0arguments#0#0" }
Procedure SetArgs(Prog, Args : String);
Var K : LongInt;
Begin
  PutZ(LongInt(@ArgBuf), Prog);
  K := Length(Prog) + 1;
  PutZ(LongInt(@ArgBuf) + K, Args);
  WrB(LongInt(@ArgBuf) + K + Length(Args) + 1, 0);
End;

Procedure SetWait(On : Boolean);
Begin
  If On Then Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, SPTR_WAIT, 0))
  Else Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, SPTR_ARROW, 0));
End;

Var PendCmd : LongInt;                 { commande a reprendre apres Enregistrer sous }

{ compilation en cours (OS2PC.EXE lance en asynchrone : l'EDI et le
  bureau restent vivants ; un minuteur attend la fin du compilateur) }
Var
  CompBusy, PendRun : Boolean;
  CompPid, CompT0 : LongInt;
  CompEF : Text;
  CompErrN : String;

Procedure CompileDone(R, Code : LongInt); Forward;

Function Compile : Boolean;
Var W, R, K, T0 : LongInt; Src, Exe, ErrN, Args, S : String; Res : Array[0..1] Of LongInt;
  PL : PLong;
Begin
  Compile := False;
  If CompBusy Then
  Begin
    StatusMsg := Acc('Compilation d^ej^a en cours...');
    InvRect(0, WorkH, CW, CH);
    Exit;
  End;
  W := SrcWin;
  If W < 0 Then
  Begin
    ShowMsg(Acc('Aucun source ^a compiler : ouvrez un fichier Pascal.'), 'Compiler', MB_OK Or MB_INFORMATION);
    Exit;
  End;
  If Wins[W].FileName = '' Then
  Begin
    PendCmd := CM_COMPILE;
    Activate(W);
    If SaveDoc(W) Then ;
    Exit;
  End;
  If Wins[W].Modified Then
    If Not SaveFile(W, Wins[W].FileName) Then Exit;
  If Not FileExists(CompilerPath) Then
  Begin
    ShowMsg(Acc('Le compilateur OS2PC.EXE est introuvable (') + CompilerPath + ').', 'Compiler', MB_OK Or MB_ERROR);
    Exit;
  End;
  Src := Wins[W].FileName;
  Exe := ChangeExt(Src, '.EXE');
  ErrN := DirOf(Exe) + 'PASDEV.ERR';
  { repertoire du source en lecture seule (CD-ROM) : sorties dans le repertoire de travail }
  Assign(CompEF, ErrN);
  {$I-} Rewrite(CompEF); {$I+}
  R := IOResult;
  If R <> 0 Then
  Begin
    Exe := WorkDir + NameOf(Exe);
    ErrN := WorkDir + 'PASDEV.ERR';
    Assign(CompEF, ErrN);
    {$I-} Rewrite(CompEF); {$I+}
    R := IOResult;
    If R <> 0 Then
    Begin
      ShowMsg(Acc('Impossible de cr^eer ') + ErrN + '.', 'Compiler', MB_OK Or MB_ERROR);
      Exit;
    End;
  End;
  LastSrc := Src; LastExe := Exe; LastTarget := Target;
  LastLines := 0; LastCode := 0; LastData := 0; LastImports := 0; LastSize := 0;
  LastErrs := 0; LastWarns := 0; LastOk := False; LastDone := True;
  StatusMsg := 'Compilation de ' + NameOf(Src) + ' (' + TargetName(Target) + ')...';
  Redraw;
  Dummy := WinUpdateWindow(Client);
  SetWait(True);
  If Target = 0 Then Args := '-v -w -DOS2PM ' Else Args := '-v -w -DOS2CONSOLE ';
  Args := Args + Src + ' ' + Exe;
  SetArgs(CompilerPath, Args);
  { sortie standard du compilateur -> fichier (heritee par l'enfant) }
  PL := @CompEF;
  Dummy := SetStdHandle(-11, PL^);
  Res[0] := 0; Res[1] := 0;
  CompT0 := KTicks;
  CompErrN := ErrN;
  { EXEC_ASYNCRESULT : le resultat est lu par DosWaitChild (minuteur) }
  R := DosExecPgm(LongInt(@FailBuf), 64, 2, LongInt(@ArgBuf), 0, LongInt(@Res), Z(CompilerPath));
  Dummy := SetStdHandle(-11, 0);
  If R <> 0 Then
  Begin
    CompileDone(R, 0);
    Exit;
  End;
  CompPid := Res[0];
  CompBusy := True;
  Dummy := WinStartTimer(Hab, Client, 7, 100);
End;

{ fin du compilateur (minuteur 7) : rend vrai quand il est termine }
Function CompilePoll : Boolean;
Var Res : Array[0..1] Of LongInt; Pid, R : LongInt;
Begin
  CompilePoll := False;
  If Not CompBusy Then Exit;
  Res[0] := 0; Res[1] := 0; Pid := 0;
  { DCWA_PROCESS, DCWW_NOWAIT }
  R := DosWaitChild(0, 1, LongInt(@Res), LongInt(@Pid), CompPid);
  If R = 129 Then Exit;                  { ERROR_CHILD_NOT_COMPLETE }
  CompBusy := False;
  Dummy := WinStopTimer(Hab, Client, 7);
  If R <> 0 Then Res[1] := 0;
  CompileDone(0, Res[1]);
  CompilePoll := True;
End;

Procedure CompileDone(R, Code : LongInt);
Var K : LongInt; S, ErrN, Exe, Src : String; EF : Text;
Begin
  LastTime := KTicks - CompT0;
  Close(CompEF);
  SetWait(False);
  ErrN := CompErrN; Exe := LastExe; Src := LastSrc;
  MsgClear;
  MsgAdd('Compilation de ' + Src + ' -> ' + Exe + ' (' + TargetName(LastTarget) + ')', -1);
  If R <> 0 Then
  Begin
    MsgAdd(Acc('Impossible de lancer le compilateur (erreur ') + IStr(R) + ').', -2);
    Inc(LastErrs);
  End
  Else
  Begin
    Assign(EF, ErrN);
    {$I-} Reset(EF); {$I+}
    If IOResult = 0 Then
    Begin
      While Not EOF(EF) Do
      Begin
        ReadLn(EF, S);
        AddCompilerLine(S);
      End;
      Close(EF);
    End;
    If (Code <> 0) And (LastErrs = 0) Then
    Begin
      MsgAdd(Acc('Le compilateur s''est termin^e avec le code ') + IStr(Code) + '.', -2);
      Inc(LastErrs);
    End;
  End;
  { le fichier .ERR n'est plus utile }
  Assign(EF, ErrN);
  {$I-} Erase(EF); {$I+}
  K := IOResult;
  LastOk := (LastErrs = 0) And FileExists(Exe);
  If LastOk And (LastSize <= 0) Then LastSize := FileSizeOf(Exe);
  If LastOk Then
  Begin
    MsgAdd(Acc('Compilation r^eussie : ') + NStr(LastLines) + Acc(' lignes, ') + NameOf(Exe) + ' (' +
           NStr(LastSize) + ' octets), ' + IStr(LastWarns) + ' avertissement(s).', -1);
    StatusMsg := Acc('Compilation r^eussie : ') + NameOf(Exe) + ' (' + NStr(LastSize) + ' octets)';
  End
  Else
  Begin
    MsgAdd(Acc('Compilation ^echou^ee : ') + IStr(LastErrs) + ' erreur(s).', -2);
    StatusMsg := Acc('Compilation ^echou^ee : voir la fen^etre Messages');
    PendRun := False;
  End;
  If (Not LastOk) Or (LastWarns > 0) Then
  Begin
    ShowMessages;
    { premiere erreur avec une ligne : y aller }
    For K := 0 To MsgCount - 1 Do
      If (MsgLine[K] >= 1) And (Pos('Erreur', MsgText[K]) > 0) Then
      Begin
        MsgSel := K;
        MsgGo(K);
        Break;
      End;
  End;
  Redraw;
End;

Var ShieldOk : Boolean;

{ le source ouvre-t-il des fenetres de PM ? (sinon, meme compile pour
  OS/2 PM, ses WriteLn n'auraient nulle part ou s'afficher) }
Function UsesPm(W : LongInt) : Boolean;
Var I : LongInt; S : String;
Begin
  UsesPm := False;
  For I := 0 To Wins[W].NLines - 1 Do
  Begin
    S := UpStr(GetLine(W, I));
    If (Pos('WININITIALIZE', S) > 0) Or (Pos('WINCREATESTDWINDOW', S) > 0) Or
       (Pos('WINCREATEWINDOW', S) > 0) Or (Pos('WINMESSAGEBOX', S) > 0) Then
    Begin
      UsesPm := True;
      Exit;
    End;
  End;
End;

Procedure RunProgram;
Var W, Rc, S, Hc : LongInt; Res : Array[0..1] Of LongInt; Exe, Cmd, Note : String;
Begin
  W := SrcWin;
  If W < 0 Then Exit;
  { compiler d'abord si le source a change depuis la derniere compilation }
  If (Not LastOk) Or (LastSrc <> Wins[W].FileName) Or Wins[W].Modified Or (LastTarget <> Target) Or
     Not FileExists(LastExe) Then
  Begin
    { compilation d'abord (asynchrone) : l'execution suit a sa fin }
    PendRun := True;
    If Not Compile Then Exit;
  End;
  If CompBusy Then Exit;
  Exe := LastExe;
  { repeindre l'EDI maintenant : sinon le dessin en attente (compilation)
    passerait par-dessus la fenetre du programme }
  Dummy := WinUpdateWindow(Client);
  SetArgs(Exe, RunParams);
  Res[0] := 0; Res[1] := 0;
  Note := '';
  If (Target = 0) And Not UsesPm(W) Then
    Note := Acc(' - sans fen^etre PM : ex^ecut^e en console');
  If (Target = 0) And (Note = '') Then
  Begin
    { Presentation Manager : le programme ouvre ses propres fenetres }
    Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), Z(Exe));
    If Rc <> 0 Then ShowMsg(Acc('Impossible de lancer ') + Exe + ' (erreur ' + IStr(Rc) + ').', Acc('Ex^ecuter'), MB_OK Or MB_ERROR)
    Else StatusMsg := Acc('Ex^ecution de ') + NameOf(Exe);
  End
  Else
  Begin
    { console : nouvelle session dans une fenetre OS/2 ; l'interpreteur de
      commandes lance le programme puis PAUSE (la fenetre reste ouverte) }
    Cmd := GetEnv('COMSPEC');
    If (Cmd = '') Or Not FileExists(Cmd) Then Cmd := ExeDir + 'CMD.EXE';
    If Not FileExists(Cmd) Then Cmd := 'C:\CMD.EXE';
    If RunParams = '' Then SetArgs(Cmd, '/C ' + Exe + ' /C PAUSE')
    Else SetArgs(Cmd, '/C "' + Exe + ' ' + RunParams + '" /C PAUSE');
    S := KSes(4, Z(NameOf(Exe)), 0);
    If S < 0 Then
    Begin
      ShowMsg('Trop de sessions : fermez un programme.', Acc('Ex^ecuter'), MB_OK Or MB_WARNING);
      Exit;
    End;
    Dummy := KSes(12, S, 0);
    Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), Z(Cmd));
    If Rc <> 0 Then
    Begin
      Dummy := KSes(12, -1, 0);
      Dummy := KSes(17, S, 0);
      ShowMsg(Acc('Impossible de lancer ') + Exe + ' (erreur ' + IStr(Rc) + ').', Acc('Ex^ecuter'), MB_OK Or MB_ERROR);
      Exit;
    End;
    If Not ShieldOk Then
    Begin
      Dummy := WinInitShield(Hab, Hmq);
      ShieldOk := True;
    End;
    Hc := 0;
    If WinCreateConsole(HWND_DESKTOP, Z(NameOf(Exe)), 1 Or 2 Or (S Shl 8), LongInt(@Hc)) <> 0 Then
      Dummy := KSes(3, S, 0);
    StatusMsg := Acc('Ex^ecution de ') + NameOf(Exe) + ' (OS/2 Console)' + Note;
  End;
  { la barre d'etat seulement : la fenetre du programme est devant l'EDI }
  InvRect(0, WorkH, CW, CH);
End;

{ ==================================================================== }
{ Image de la boite A propos : Blaise Pascal ecrivant OS/2              }
{ (144 x 176 pels, 16 couleurs du VGA, une ligne hexadecimale par rangee) }
{ ==================================================================== }
Const
  PIC_W = 144; PIC_H = 176;
  { 0 noir, 1 bleu, 2 vert, 3 cyan, 4 rouge, 5 magenta, 6 brun, 7 gris clair, 8 gris fonce,
    9 bleu clair, A vert clair, B cyan clair, C rouge clair, D rose, E jaune, F blanc }
  PicRows : Array[0..PIC_H - 1] Of String[PIC_W] = (
    '010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '044441111122222866685555010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '144440111022222066605555101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '0C6C6889882A2A284E465D6D110101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '1CECE8E7E8EAEAE8EEE8E7E7601010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '044441111122222846685555010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '144440111022222066605555101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '044441111122222866685555010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '144440111022222066605555101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '044441111122222866685555010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '144440111022222066605555101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '044441111122222866685555010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '144440111022222066605555101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '044441111122222866685555010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '144440111022222066605555501010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '664646686666666666666868666666010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '666666666666666666666666666666801010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '666666666666666666666666666666010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '808080808080808080808080808080101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '010101010101010101010101010101010101010101080806060608010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '101010101010101010101010101010101010101080606060606060606080101010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '010101010101010101010101010101010101080606060606060606060606010101010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '101010101010101010101010101010101010606060606060606060606060608010101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '010101010101010101010101010101010106060606060606060606060606060601010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '101010101010101010101010101010108060606060606060606060606060606060101010101010101010101010101010101010101010101010101010101010101010101010101010',
    '010101010101010101010101010101080606060606060606060606060606060606010101010101010101010101010101010101010101010101010101010101010101010101010101',
    '101010101010101010101010101010806060606060606060606060606060606060601010101010101010101010101010101010101010101010101010101010101010101010101010',
    '0101010101010101010101010101080606060606060606060606060606060606060601010101010101010101010101010101010101010101010101010107EE010101010101010101',
    '101010101010101010101010101080606060606060606060606060606060606060606010101010101010101010101010101010101010101010101010107EEEE01010101010101010',
    '01010101010101010101010101010606060606060606060606060606060606060606060101010101010101010101010101010101010101010101010108EEEEE80101010101010101',
    '10101010101010101010101010106060606060606060606060606060606060606060606010101010101010101010101010101010101010101010101013EEEEE81010101010101010',
    '0101010101010101010101010106060606060606060606060606060606060606060606080101010101010101010101010101010101010101010101010EEEEEEE0101010101010101',
    '1010101010101010101010101060606060606066767676767676767676606060606060601010101010101010101010101010101010101010101010101EEEFEEE6010101010101010',
    '010101010101010101010101080606060606066E6F6F6F6F6F6F6F6F6F660606060606060101010101010101010101010101010101010101010101010EEFFFEE8101010101010101',
    '1010101010101010101010101060606060606076F6F6F6F6F6F6F6F6F6C06060606060606010101010101010101010101010101010101010101010101EEFFFEE8010101010101010',
    '010101010101010101010101060606060606067F6F6F6F6F6F6F6F6F6F680606060606060801010101010101010101010101010101010101010101010EEFFFEE8101010101010101',
    '10101010101010101010101080606060606060F6F6F6F6F6F6F6F6F6F6F760606060606060101010101010101010101010101010101010101010101018EFFFFE1010101010101010',
    '010101010101010101010101060666666606086F6F6F6F6F6F6F6F6C676F66060666666606010101010101010101010101010101010101010101010107EFFFEE0101010101010101',
    '10101010101010101010101066666060666066F6F6F6F6F6F6F6F6C6767770666660606660101010101010101010101010101010101010101010101018EEFFE31010101010101010',
    '0101010101010101010101016606060606060C6F6F6F6F6F6F6F6F676767766606060606060101010101010101010101010101010101010101010101018EFFE10101010101010101',
    '10101010101010101010101660606060606066F6F6F6F6F6F6F6F7767676766060606060606010101010101010101010101010101010101010101010108788801010101010101010',
    '0101010101010101010101680606060606676E6F6E7F6C6F6F6C67676767670606060606060601010101010101010101010101010101010101010101017F87F80101010101010101',
    '10101010101010101010108060606060607676F676868676F6F68686867676606060606060148010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '01010101010101010101060106060666666F6F6F6C676F6F6F6F7C68676767066666660606016101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '101010101010101010108610606666606076F6F6E6E7F6F6F6F6C776767676646060666060808410101010101010101010101010101010101010101010FFFFF11010101010101010',
    '01010101010101010101010806660606067F6F6F6E787E6F6F6E7877676767660606060606010101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '1010101010101010101010106660606060F6F6F6F7F08CF6F6F7F086767676806060606060601010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '01010101010101010101010866060606066F6F6F6F787F6F666F7867676767660606060606010101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '1010101010101010101010106060606060F6F6F6F6F7F6F6F6F67676767676806060606066601010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '01010101010101010101010606060606666F6F6F6F6F6F6F6C6F6767676767666666060606680101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '1010101010101010101010866060666660C6F6F6F6F6F6F6F4767676767676806066606060601010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '01010101010101010101010606066606066F6F6F6F6F6F6F676F6767676767660606060606080101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '101010101010101010101010606660606076F6F6F6F6F6F6F7667676767676806060606060601010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '01010101010101010101010606660606066E6F6F6F6F6F6F6F6C6767676767060606060606080101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '101010101010101010101080606060606086F6F6F6F6F6F676C67676767676606060606660601010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '01010101010101010101010606060606066F6F6F6F6F6F6F676E6767676767666606060666060101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '101010101010101010101080666060666666F6F6F6F6F7F7C7C7C676767676606660606066601010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '0101010101010101010101060606066606077F6F6F6F686808086867676768060606060606060101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '101010101010101010101060606066606066F6F6F6F68676C676C886767670606060606060601010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '0101010101010101010101060606660606066F6F6F6F6E7E7E7F7C67676766060606060606060101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '10101010101010101010106060606060606086F6F6F6F67676767776767680606060666060608010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '010101010101010101010106060606060606676F6F6F6F4646464C77676766660606066606060101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '10101010101010101010106060666060666666F6F6F6F6F6E7F6F6F6768060666060606660606010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '010101010101010101010806060606066606066E6F6F6F6F6C6F6F6F670606060606060606060101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '1010101010101010101010606060606660606066E6F6F6F6C076F6F6F06060606060606060606010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '01010101010101010101060606060666060606066E6F6F6F677F6F6F660606060606060606060101010101010101010101010101010101010101010101FFFFF80101010101010101',
    '101010101010101010101060606060606060606066F6F6F6F6F6F6F6606060606066606060606010101010101010101010101010101010101010101010FFFFF11010101010101010',
    '0101010101010101010106060606060606060666666F6F6F6F6F6C676666660606066606060601010101010101010101010101010101010101010166666666666668010101010101',
    '1010101010101010101010606060666060666660607676F6F6F776768060666060606660606060101010101010101010101010101010101010101066666666666660101010101010',
    '010101010101010101010606060606060666060101676767676767670101060606060606060608010101010101010101010101010101010101010166666666666668010101010101',
    '101010101010101010108060606060606660601010767676767676768010806060606060606060101010101010101010101010101010101010101080808080808080101010101010',
    '010101010101010101010606060606066606080101676767676767670101060606060606060608010101010101010101010101010101010101010101010101010101010101010101',
    '101010101010101010108060606060606060601010767676767676768010806066606060606060101010101010101010101010101010101010101010101010101010101010101010',
    '0101010101010101010106060606060606087FFFFFFFFFFFFFFFFFFFFFFFFF7606660606060606010101010101010101010101010101010101010101010101010101010101010101',
    '101010101010101010106060606060666087FFFFFFFFFFFFFFFFFFFFFFFFFFF660666060606060101010101010101010101010101010101010101010101010101010101010101010',
    '01010101010101010101060606060606067FFFFFFFFFFFFFFFFFFFFFFFFFFFFF06060606060606010101010101010101010101010101010101010101010101010101010101010101',
    '1010101010101010101060606060606068FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF70606060606060101010101010101010101010101010101010101010101010101010101010101010',
    '0101010101010101010106060606060607FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF6060606060606010101010101010101010101010101010101010101010101010101010101010101',
    '1010101010101010101060606060606087FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7606060606060801010101010101010101010101010101010101010101010101010101010101010',
    '010101010101010101080606060606087FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF660606060606010101010101010101010101010101010101010101010101010101010101010101',
    '10101010101010101010606060606067FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF06060606060801010101010101010101010101010101010101010101010101010101010101010',
    '0101010101010101010806060606067FFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFF80606060606010101010101010101010101010101010101010101010101010101010101010101',
    '1010101010101010101060606060667FFFFFFFFFFFFFFFFF87FFFFFFFFFFFFFFFFFF8000006060601010101010101010101010101010101010101010101010101010101010101010',
    '0101010101010101010606060606087FFFFFFFFFFFFFFFF8088FFFFFFFFFFFFFFFFF7600000606010101010101010101010101010101010101010101010101010109110101010101',
    '101010101010101010006060606087FFFFFFFFFFFFFFFFF08707FFFFFFFFFFFFFFFFF660000000601010101010101010101010101010101010101010101010101087101010101010',
    '01010101010101010006060606067FFFFFFFFFFFFFFFFF0008007FFFFFFFFFFFFFFFFF00000000010101010101010101010101010101010101010101010101010877010101010101',
    '1010101010101000000060606067FFFFFFFFFFFFFFFFF70087008FFFFFFFFFFFFFFFFF700000000000101010101010101010101010101010101010101010101017F8101010101010',
    '0101010101010000000606060667FFFFFFFFFFFFFFFF7000080008FFFFFFFFFFFFFFFFF8000000000001010101010101010101010101010101010101010101016FF1010101010101',
    '101010101010000000006060607FFFFFFFFFFFFFFFFF8000870000FFFFFFFFFFFFFFFFF7000000000000001010101010101010101010101010101010101010117F70101010101010',
    '0101010101000000000606060668777FFFFFFFFFFFF800000800000FFFFFFFFFFF7F7868000000000000000101010101010101010101010101010101010101087F81010101010101',
    '1010101010000000006060606060606060888777FF70000000000007FFF787888060606060000000000000001010101010101010101010101010101010101087FF80101010101010',
    '0101010100000000000606060606060600000000000000000000000000000000060606060000000000000000010101010101010101010101010101010101017FFF01010101010101',
    '10101010100000000060606060606060600000000000000000000000000000000060606060000000000000001010101010101010101010101010101010101877F781101010101010',
    '0101010100000000000406060606060600000000000008080808000000000000060606060600000000000000010101010101010101010101010101010101077FF901010101010101',
    '101010100000000000000000606060606000000000008080808000000000000000606060600000000000000000101010101010101010101010101010101097FFF010101010101010',
    '01010101000000000000000000060606000000000000080808080000000000000006060600000000000000000001010101010101010101010101010101087FFF7101010101010101',
    '1010101000000000000000000000006000000000000080808080000000000000006000000000000000000000001010101010101010101010101010101017FFFF9010101010101010',
    '0101010000000000000000000000000000000000000008080808000000000000000000000000000000000000000101010101010101010101010101010187FFFF0101010101010101',
    '101010100000000000000000000000000000000000008080808000000000000000000000000000000000000000001010101010101010101010101010107FFFF81010101010101010',
    '010101000000000000000000000000000000000000000808080800000000000000000000000000000000000000000101010101010101010101010101087F7F710101010101010101',
    '10101000000000000000000000000000000000000000808080808000000000000000000000000000000000000000001010101010101010101010101087F7FF801010101010101010',
    '0101010000000000000000000000000000000000000008080808000000000000000000000000000000000000000001010101010101010101010101017FFFF9010101010101010101',
    '1010100000000000000000000000000000000000000080808080800000000000000000000000000000000000000000101010101010101010101010187FFFF0101010101010101010',
    '0101000000000000000000000000000000000000000008080808000000000000000000000000000000000000000000010101010101010101010101077FFF11010101010101010101',
    '101010000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000101010101010101010101087FFF710101010101010101010',
    '01010000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000101010101010101010101087FFFF801010101010101010101',
    '101000000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000101010101010101010101777F77110101010101010101010',
    '01000000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000001010101010101010101877FF70101010101010101010101',
    '1010000000000000000000000000000000000000000080808080800000000000000000000000000000000000000000000010101010101010101177FFF11010101010101010101010',
    '010000000000000000000000000000000000000000080808080800000000000000000000000000000000000000000000000101010101010101087FFF710101010101010101010101',
    '10000000000000000000000000000000000000000000808080808000000000000000000000000000000000000000000000101010101010101087FFF7101181818180101010101010',
    '01000000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000000010101010101010177FFF8081818000118110101010101',
    '1000000000000000000000000000000000000000000080808080800000000000000000000000000000000000000000000000101010101010187FFF70818100000081811010101010',
    '0000000000000000000000000000000000000000000808080808000000000000000000000000000000000000000000000000010101010101177F7778181800000118180101010101',
    '100000000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000000000101010101077F7F110118181818181801010101010',
    '00000000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000000000101010101087FFF7101010818181811000101010101',
    '00000000000000000000000000000000000000000000808080808000000000000000000000000000000000000000000000000010101010177FF71010100010101000001010101010',
    '00000000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000000000007710101177FF80101000000000000000101010101',
    '000000000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000000008FFF1101087FF901010100000000000001010101010',
    '00000000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000000087FFFFF01017FF7010101000000000000000101010101',
    '000000000000000000000000000000000000000000008080808080000000000000000000000000000000000000000000008FFFFFFF801777F7811010100000000000001010101010',
    '0000000000000000000000000000000000000000000808080808080000000000000000000000000000000000000000008FFFFF7E6F78877F11010101000000000000000101010101',
    '000000000000000000000000000000000000000000008080808080000000000000000000000000000000000000100087FFFFF6F6F6F777F710101010100000000000001010101010',
    '00000000000000000000000000000000000000000008080808080800000000000000000000000000000000000000007FFFFF6F6F6F677FF101010101000000000000000101010101',
    '00000000000000000000000000000000000000000000808080808000000000000000000000000000000000000010008FFFF6F6F6F6F7FFE810101010000000000000000010101010',
    '0000000000000000000000000000000000000000000808080808080000000000000000000000000000000000006E6007FFCF6F6F6F77F76C4E4E4E0001010101010101006E4E4E4E',
    '00000000000000000000000000000000000000000080808080808000000000000000000000000000000000000084E600FFF6F6F6F67FF67674E4E4000000000000000000C4E4E4E4',
    '0000000000000000000000000000000000000000000808080808080000000000000000000000000000000000006E4E607F6F6F6F677F67676E4E4E6800000000000000084E4E4E4E',
    '0000000000000000000000000000000000000000008080808080800000000000000000000000000000000000006666608FF6F6F67776767676666666600000000000606666666666',
    '0000000000000000000000000000000000000000000808080808080000000000000000000000000000000000000666666C7F6F6E8867676766666666666666460666666666666666',
    '0000000000000000000000000000000000000000008080808080800000000000000000000000000000000000000666666668E6E607F676767666666666666666E4E4666666666666',
    '000000000000000000000000000000000000000000080808080808000000000000000000000000000000000000066666666667606768666C6E4E4ECECE7E7FEFEFEF666666666666',
    '00000000000000000000000000000000000000000080808080808000000000000000000000000000000000000066666666E4E660ECE7E7FEFEFEFEFEFEFEFEFEFEFEE66666666666',
    '00000000000000000000000000000000000000000008080808080800000000000000000000060606666E4E4ECE7E7EEFEFEFEE0EEFEFEFEFEFEFEFEFEFEFEFEFEFEFC60606060606',
    '00000000000000000000000000000000000000000080808080808000000060606666E4E6ECE7E7EEFEFEFEFEFEFEFEFEFEFEF07EFEFEFEFEFEFEFEFEFEFEFEFEFEFEE66666666666',
    '000000000000000000000000000000000000000000080808080808066ECE7E7EEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF88EFEFEFEFEFEFEFEFEFEFEFEFEFEFEFE66666666666',
    '00000000000000000000000000000000000000000080808080808000EEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF707FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF46666666666',
    '00000000000000000000000000000000000000000008080808080806EFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF7FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE6666666666',
    '00000000000000000000000000000000000000000080808080808086FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF76666666666',
    '0000000000000000000000000000000000000000000808080808080EEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF6606060606',
    '0000000000000000000000000000000000000000008080808080806CFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE666666666',
    '0000000000000000000000000000000000000000000808080808080EEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFC666666666',
    '00000000000000000000000000000000000000000080808080808067FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE666666666',
    '0000000000000000000000000000000000000000000808080808086FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF79EE791119EFEFEFEFEFEFEFEFEFEFEFEFEFEFE666666666',
    '000000000000000000000000000000000000000000808080808080EEFEFEFEFEFEFEFEFEFEFEFEFEFEF7911117FEFEFE18F11778119EFEFEFEFEFEFEFEFEFEFEFEFEFEF466666666',
    '0000000000000000000000000000000000000000080808080808064FEFEFEFEFEFEF7911197FEFEFE711877719EFEFE71FE17FEF1117EFEFEFEFEFEFEFEFEFEFEFEFEFEE46060606',
    '000000000000000000000000000000000000000000808080808080EEFEFEFEFEFEF8117771117EFEF117FEFE97FEFEF89EF1EEFE9117FEFEFEFEFEFEFEFEFEFEFEFEFEF766666666',
    '0000000000000000000000000000000000000000080808080808067FEFEFEFEFEF111FEFEF111FEF7117EFEF87EFEF717FEFEFEF811FEFEFEFEFEFEFEFEFEFEFEFEFEFEF66666666',
    '000000000000000000000000000000000000000000808080808086FEFEFEFEFEF8117EFEFE9118FE7111FEFEFEFEFE91FEFEFEFE119EFEFEFEFEFEFEFEFEFEFEFEFEFEFEE6666666',
    '000000000000000000000000000000000000000008080808080806EFEFEFEFEF7119EFEFEF7118EF711117EFEFEFEF17EFEFEFE9117FEFEFEFEFEFEFEFEFEFEFEFEFEFEF86666666',
    '000000000000000000000000000000000000000000808080808084FEFEFEFEFE9118FEFEFE7111FEF8111117FEFEF71EFEFEFE7117FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE6666666',
    '00000000000000000000000000000000000000000808080808080EEFEFEFEFEF1117EFEFEF7111EFEF8111118FEFE18FEFEFEF117FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFE6060606',
    '00000000000000000000000000000000000000000080808080806CFEFEFEFEF71117FEFEFE7111FEFEF7911117FE71EEFEFEF117FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF4666666',
    '00000000000000000000000000000000000000000808080808086EEFEFEFEFE7111FEFEFEF7118EFEFEFE71118EF89EFEFEF817FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE666666',
    '00000000000000000000000000000000000000000080808080806EFEFEFEFEF7111EFEFEFE9118FE7EFEFEF111F717FEFEF89EFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF7666666',
    '00000000000000000000000000000000000000000808080808086FEFEFEFEFEF111FEFEFEF1117EF17EFEFE919E91FEFEF117789897FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE666666',
    '0000000000000000000000000000000000000000008080808080EEFEFEFEFEFE9117FEFEF7119EFE17FEFEF117F18EFEF8111111119EFEFEFEFEFEFEFEFEFEFEFEFEFEFEFE666666',
    '0000000000000000000000000000000000000000080808080806CFEFEFEFEFEF7119EFEFE111EFEE197FE7818F71EFEFE9198989777FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF660606',
    '0000000000000000000000000000000000000000008080808080EEFEFEFEFEFEF7119EF71197FEF791111197FE97FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE66666',
    '00000000000000000000000000000000000000000808080808067FEFEFEFEFEFEF79111187EFEFEFEF777FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF766666',
    '0000000000000000000000000000000000000000008080808086FEFEFEFEFEFEFEFEF7FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEF66666',
    '000000000000000000000000000000000000000008080808080EEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE6666',
    '0000000000000000000000000000000000000000008080808064FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE7EC6666',
    '000000000000000000000000000000000000000008080808080EEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE7E7ECE6E4E666666666606',
    '0000000000000000000000000000000000000000008080808067FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE7E7ECE6E4E666666666666666666666666666',
    '000000000000000000000000000000000000000008080808086FEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEE7E7ECE6E4E666666666666666666666666666666666666666666',
    '000000000000000000000000000000000000000080808080806EFEFEFEFEFEFEFEFEFEFEFEFEE7E7ECECE4E666606060666666666666666666666666666666666666666666666666',
    '000000000000000000000000000000000000000008080808084FEFEFEFEFEE7E7ECECE4E666606060000000000000006666666666666666666666666666666666666666666666666',
    '000000000000000000000000000000000000000080808080806CECE4E666606060000000000000000000000000000000606060606060646060606060606060666666666666666666',
    '000000000000000000000000000000000000000008080808080606080000000000000000000000000000000000000000666666666666666666666666666666060606060606060606',
    '000000000000000000000000000000000000000080808080808080800000000000000000000000000000000000000000666666666666666666666666666666666666666666666666',
    '000000000000000000000000000000000000000008080808080808080000000000000000000000000000000000000000666666666666666666666666666666666666666666666666',
    '000000000000000000000000000000000000000080808080808080800000000000000000000000000000000000000000666666666666666666666666666666666666666666666666'
  );

Function HexVal(C : Char) : LongInt;
Begin
  If (C >= '0') And (C <= '9') Then HexVal := Ord(C) - 48
  Else HexVal := Ord(UpCase(C)) - 55;
End;

{ bitmap 4 bits (BITMAPINFO2 de 16 octets + 16 couleurs RVB2), rangees de bas en haut }
Procedure BuildPic;
Const Pal : Array[0..15] Of LongInt = ($000000, $0000AA, $00AA00, $00AAAA, $AA0000, $AA00AA, $AA5500, $AAAAAA,
                                       $555555, $5555FF, $55FF55, $55FFFF, $FF5555, $FF55FF, $FFFF55, $FFFFFF);
Var Y, X, A, B : LongInt; S : String;
Begin
  If PicReady Then Exit;
  WrL(LongInt(@PicBmi), 16);
  WrL(LongInt(@PicBmi) + 4, PIC_W);
  WrL(LongInt(@PicBmi) + 8, PIC_H);
  WrW(LongInt(@PicBmi) + 12, 1);
  WrW(LongInt(@PicBmi) + 14, 4);
  For X := 0 To 15 Do
  Begin
    A := LongInt(@PicBmi) + 16 + X * 4;
    WrB(A, Pal[X] And 255);              { bleu }
    WrB(A + 1, (Pal[X] Shr 8) And 255);  { vert }
    WrB(A + 2, (Pal[X] Shr 16) And 255); { rouge }
    WrB(A + 3, 0);
  End;
  For Y := 0 To PIC_H - 1 Do
  Begin
    S := PicRows[Y];
    A := (PIC_H - 1 - Y) * (PIC_W Div 2);
    For X := 0 To PIC_W Div 2 - 1 Do
    Begin
      B := HexVal(S[X * 2 + 1]) * 16 + HexVal(S[X * 2 + 2]);
      PicBits[A + X] := B;
    End;
  End;
  PicReady := True;
End;

{ dessiner l'image, coin haut gauche (X, Y) de la fenetre de hauteur Hh }
Procedure DrawPic(Hps, X, Y, Hh : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  BuildPic;
  P[0] := X; P[1] := Hh - Y - PIC_H; P[2] := X + PIC_W; P[3] := Hh - Y;
  P[4] := 0; P[5] := 0; P[6] := PIC_W; P[7] := PIC_H;
  Dummy := GpiDrawBits(Hps, LongInt(@PicBits), LongInt(@PicBmi), 4, LongInt(@P), $CC, 0);
End;

{ ==================================================================== }
{ Boites Information et A propos                                        }
{ ==================================================================== }

{ texte dans une fenetre de dialogue de hauteur Hh (coin haut gauche) }
Procedure DlgText(Hps, Hh, X, Y : LongInt; S : String; Fg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := Hh - Y - CHH; Rc[2] := X + Length(S) * CHW; Rc[3] := Hh - Y;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, CLR_PALEGRAY, 0);
End;

Procedure InfoLine(Hps, Hh, Y : LongInt; L, V : String);
Begin
  DlgText(Hps, Hh, 16, Y, L, CLR_BLACK);
  DlgText(Hps, Hh, 220, Y, V, CLR_DARKBLUE);
End;

Function InfoProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, Hh, Y, W : LongInt; Rc : Array[0..3] Of LongInt; S : String;
Begin
  InfoProc := 0;
  Case Msg Of
    WM_CREATE :
      Dummy := WinCreateWindow(H, WC_BUTTON, Z('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                               196, 8, 84, 26, H, HWND_TOP, ID_DOK, 0, 0);
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
        Hh := Rc[3];
        Y := 12;
        W := SrcWin;
        If Not LastDone Then
        Begin
          DlgText(Hps, Hh, 16, Y, Acc('Aucun programme n''a encore ^et^e compil^e.'), CLR_BLACK);
          Y := Y + 24;
          If W >= 0 Then
          Begin
            InfoLine(Hps, Hh, Y, 'Source :', NameOf(WinTitle(W))); Y := Y + 20;
            InfoLine(Hps, Hh, Y, 'Lignes :', NStr(Wins[W].NLines)); Y := Y + 20;
          End;
          InfoLine(Hps, Hh, Y, 'Destination :', TargetName(Target)); Y := Y + 28;
          DlgText(Hps, Hh, 16, Y, Acc('Compilez (F9) pour conna^itre la taille du code'), CLR_DARKGRAY);
          DlgText(Hps, Hh, 16, Y + 18, Acc('et des donn^ees du programme.'), CLR_DARKGRAY);
        End
        Else
        Begin
          If LastOk Then S := Acc('r^eussie') Else S := Acc('^echou^ee');
          InfoLine(Hps, Hh, Y, 'Compilation :', S); Y := Y + 20;
          InfoLine(Hps, Hh, Y, 'Source :', NameOf(LastSrc)); Y := Y + 20;
          InfoLine(Hps, Hh, Y, 'Programme :', NameOf(LastExe)); Y := Y + 20;
          If LastTarget = 0 Then S := 'OS/2 Presentation Manager' Else S := 'OS/2 Console';
          InfoLine(Hps, Hh, Y, 'Destination :', S); Y := Y + 20;
          InfoLine(Hps, Hh, Y, Acc('Lignes compil^ees :'), NStr(LastLines)); Y := Y + 26;
          InfoLine(Hps, Hh, Y, 'Taille du code :', NStr(LastCode) + ' octets'); Y := Y + 20;
          InfoLine(Hps, Hh, Y, Acc('Taille des donn^ees :'), NStr(LastData) + ' octets'); Y := Y + 20;
          InfoLine(Hps, Hh, Y, 'Taille de la pile :', '262 144 octets'); Y := Y + 20;
          InfoLine(Hps, Hh, Y, 'Importations (API) :', NStr(LastImports)); Y := Y + 20;
          InfoLine(Hps, Hh, Y, Acc('Taille du fichier .EXE :'), NStr(LastSize) + ' octets'); Y := Y + 26;
          InfoLine(Hps, Hh, Y, Acc('Dur^ee :'), IStr(LastTime Div 1000) + ',' + IStr((LastTime Mod 1000) Div 100) + ' s');
          Y := Y + 20;
          InfoLine(Hps, Hh, Y, 'Avertissements :', IStr(LastWarns) + '   Erreurs : ' + IStr(LastErrs));
        End;
        Dummy := WinEndPaint(Hps);
      End;
    WM_COMMAND :
      If InfoFr <> 0 Then
      Begin
        Dummy := WinDestroyWindow(InfoFr);
        InfoFr := 0;
      End;
    WM_CHAR :
      If ((Lo16(Mp1) And KC_KEYUP) = 0) And ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And
         ((Hi16(Mp2) = VK_ESC) Or (Hi16(Mp2) = VK_ENTER) Or (Hi16(Mp2) = VK_NEWLINE)) Then
        InfoProc := WinSendMsg(H, WM_COMMAND, ID_DOK, 0)
      Else InfoProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_CLOSE :
      If InfoFr <> 0 Then
      Begin
        Dummy := WinDestroyWindow(InfoFr);
        InfoFr := 0;
      End;
  Else
    InfoProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Function AboutProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, Hh, X : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  AboutProc := 0;
  Case Msg Of
    WM_CREATE :
      Dummy := WinCreateWindow(H, WC_BUTTON, Z('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                               326, 12, 90, 26, H, HWND_TOP, ID_DOK, 0, 0);
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
        Hh := Rc[3];
        { cadre en creux autour de l'image }
        Rc[0] := 10; Rc[1] := Hh - 14 - PIC_H - 2; Rc[2] := 14 + PIC_W + 2; Rc[3] := Hh - 10;
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_DARKGRAY);
        DrawPic(Hps, 12, 12, Hh);
        X := 180;
        DlgText(Hps, Hh, X, 16, 'Pascal Developer', CLR_DARKBLUE);
        DlgText(Hps, Hh, X, 36, 'Version 1.0', CLR_BLACK);
        DlgText(Hps, Hh, X, 64, Acc('Environnement de d^eveloppement'), CLR_BLACK);
        DlgText(Hps, Hh, X, 82, 'Pascal pour OS/2-0', CLR_BLACK);
        DlgText(Hps, Hh, X, 100, '(compilateur OS2PC)', CLR_DARKGRAY);
        DlgText(Hps, Hh, X, 130, 'Auteur : Sylvain Maltais', CLR_BLACK);
        DlgText(Hps, Hh, X, 148, 'Date : 2026', CLR_BLACK);
        DlgText(Hps, Hh, X, 166, 'Licence : MIT', CLR_BLACK);
        Dummy := WinEndPaint(Hps);
      End;
    WM_COMMAND, WM_CLOSE :
      If AboutFr <> 0 Then
      Begin
        Dummy := WinDestroyWindow(AboutFr);
        AboutFr := 0;
      End;
    WM_CHAR :
      If ((Lo16(Mp1) And KC_KEYUP) = 0) And ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And
         ((Hi16(Mp2) = VK_ESC) Or (Hi16(Mp2) = VK_ENTER) Or (Hi16(Mp2) = VK_NEWLINE)) Then
        AboutProc := WinSendMsg(H, WM_COMMAND, ID_DOK, 0)
      Else AboutProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  Else
    AboutProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ fenetre de dialogue centree (cadre) : Cls, titre, taille du cadre }
Function OpenBox(Cls, Title : String; Wd, Ht : LongInt; Var Cl : LongInt) : LongInt;
Var Fl, Fr, Sw, Sh : LongInt;
Begin
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  Cl := 0;
  Fr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z(Cls), Z2(Title), 0, 0, 0, LongInt(@Cl));
  If Fr <> 0 Then
  Begin
    Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
    Dummy := WinSetWindowPos(Fr, HWND_TOP, MaxI(0, (Sw - Wd) Div 2), MaxI(0, (Sh - Ht) Div 2), Wd, Ht,
                             SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
    Dummy := WinSetActiveWindow(HWND_DESKTOP, Fr);
  End;
  OpenBox := Fr;
End;

Procedure ShowInfo;
Var Cl : LongInt;
Begin
  If InfoFr <> 0 Then Dummy := WinDestroyWindow(InfoFr);
  InfoFr := OpenBox('PDINFO', 'Information', 480, 360, Cl);
  If Cl <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, WinWindowFromID(Cl, ID_DOK));
End;

Procedure ShowAbout;
Var Cl : LongInt;
Begin
  If AboutFr <> 0 Then Dummy := WinDestroyWindow(AboutFr);
  AboutFr := OpenBox('PDABOUT', Acc('A propos de Pascal Developer'), 440, 250, Cl);
  If Cl <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, WinWindowFromID(Cl, ID_DOK));
End;

{ ==================================================================== }
{ Dialogues : saisie, ouverture, liste des fenetres                     }
{ ==================================================================== }

Var
  DlgWin : LongInt;                    { fenetre concernee (Enregistrer sous) }
  DlgItems : Array[0..511] Of String;  { elements de la liste }
  DlgNItems : LongInt;

Procedure CloseDlg;
Begin
  If DlgFr <> 0 Then Dummy := WinDestroyWindow(DlgFr);
  DlgFr := 0; DlgCl := 0; DlgEf := 0; DlgLb := 0;
End;

Procedure OpenInput(Mode : LongInt; Title, Prompt, Def : String);
Var Cl : LongInt;
Begin
  CloseDlg;
  DlgMode := Mode; DlgPrompt := Prompt;
  If Mode = DM_SAVEAS Then DlgWin := SrcWin;
  DlgFr := OpenBox('PDINPUT', Title, 460, 130, Cl);
  If DlgFr = 0 Then Exit;
  Dummy := WinSetWindowText(DlgEf, Z(Def));
  Dummy := WinSendMsg(DlgEf, EM_SETSEL, Length(Def) Shl 16, 0);
  Dummy := WinSetFocus(HWND_DESKTOP, DlgEf);
End;

Procedure ListAdd(S : String);
Begin
  If DlgNItems > 511 Then Exit;
  DlgItems[DlgNItems] := S;
  Inc(DlgNItems);
  Dummy := WinSendMsg(DlgLb, LM_INSERTITEM, -1, Z(S));
End;

{ repertoires puis sources (*.PAS, *.INC) de DlgDir }
Procedure FillOpenList;
Var SR : SearchRec; N, E : String; K : LongInt;
Begin
  Dummy := WinSendMsg(DlgLb, LM_DELETEALL, 0, 0);
  DlgNItems := 0;
  If Length(DlgDir) > 3 Then ListAdd('[..]');
  FindFirst(DlgDir + '*.*', Directory, SR);
  While DosError = 0 Do
  Begin
    If ((SR.Attr And Directory) <> 0) And (SR.Name <> '.') And (SR.Name <> '..') Then ListAdd('[' + SR.Name + ']');
    FindNext(SR);
  End;
  FindFirst(DlgDir + '*.*', AnyFile, SR);
  While DosError = 0 Do
  Begin
    If (SR.Attr And Directory) = 0 Then
    Begin
      N := UpStr(SR.Name);
      K := Length(N);
      While (K > 0) And (N[K] <> '.') Do Dec(K);
      If K > 0 Then E := Copy(N, K, 4) Else E := '';
      If (E = '.PAS') Or (E = '.INC') Or (E = '.PP') Or (E = '.DPR') Then ListAdd(SR.Name);
    End;
    FindNext(SR);
  End;
  Dummy := WinInvalidateRect(DlgCl, 0, 0);
End;

Procedure OpenFileDlg;
Var Cl : LongInt;
Begin
  CloseDlg;
  DlgMode := DM_OPEN;
  If DlgDir = '' Then DlgDir := WorkDir;
  DlgFr := OpenBox('PDOPEN', 'Ouvrir un fichier', 470, 360, Cl);
  If DlgFr = 0 Then Exit;
  FillOpenList;
  Dummy := WinSetWindowText(DlgEf, Z('*.PAS'));
  Dummy := WinSetFocus(HWND_DESKTOP, DlgEf);
End;

Procedure WinListDlg;
Var Cl, K, W : LongInt;
Begin
  CloseDlg;
  DlgMode := 0;
  DlgFr := OpenBox('PDWINLIST', Acc('Fen^etres'), 470, 300, Cl);
  If DlgFr = 0 Then Exit;
  DlgNItems := 0;
  For K := NZ - 1 DownTo 0 Do
  Begin
    W := ZOrd[K];
    ListAdd(IStr(Wins[W].Num) + ' - ' + WinTitle(W));
    DlgItems[DlgNItems - 1] := IStr(W);
  End;
  Dummy := WinSendMsg(DlgLb, LM_SELECTITEM, 0, 1);
  Dummy := WinSetFocus(HWND_DESKTOP, DlgLb);
End;

Procedure Command(Id : LongInt); Forward;

{ chemin d'un repertoire choisi dans la liste ou tape }
Function IsDir(P : String) : Boolean;
Var SR : SearchRec;
Begin
  IsDir := False;
  If P = '' Then Exit;
  If (P[Length(P)] = '\') Or (P[Length(P)] = ':') Then
  Begin
    IsDir := True;
    Exit;
  End;
  FindFirst(P, Directory, SR);
  IsDir := (DosError = 0) And ((SR.Attr And Directory) <> 0);
End;

Procedure OpenChoice(S : String);
Var P : String;
Begin
  S := Trim(S);
  If S = '' Then Exit;
  If S = '[..]' Then
  Begin
    P := Copy(DlgDir, 1, Length(DlgDir) - 1);
    DlgDir := DirOf(P);
    FillOpenList;
    Exit;
  End;
  If (S[1] = '[') And (S[Length(S)] = ']') Then
  Begin
    DlgDir := DlgDir + Copy(S, 2, Length(S) - 2) + '\';
    FillOpenList;
    Exit;
  End;
  If (Length(S) < 2) Or ((S[2] <> ':') And (S[1] <> '\')) Then P := DlgDir + S Else P := S;
  If (Pos('*', P) > 0) Or (Pos('?', P) > 0) Then
  Begin
    DlgDir := DirOf(FullPath(P));
    FillOpenList;
    Exit;
  End;
  If IsDir(P) Then
  Begin
    P := FullPath(P);
    If P[Length(P)] <> '\' Then P := P + '\';
    DlgDir := P;
    FillOpenList;
    Exit;
  End;
  CloseDlg;
  If OpenDoc(P, False) >= 0 Then ;
End;

Procedure DlgDone;
Var S : String; I, V, E, W : LongInt;
Begin
  Dummy := WinQueryWindowText(DlgEf, 255, LongInt(@TxtBuf));
  S := Trim(GetZ(LongInt(@TxtBuf)));
  Case DlgMode Of
    DM_SAVEAS :
      Begin
        W := DlgWin;
        If (W < 0) Or Not Wins[W].Used Or (S = '') Then
        Begin
          CloseDlg;
          Exit;
        End;
        If Not HasExt(S) Then S := S + '.PAS';
        S := FullPath(S);
        If FileExists(S) And (S <> Wins[W].FileName) Then
          If AskYesNo(Acc('Le fichier ') + S + Acc(' existe d^ej^a. Le remplacer ?'), 'Enregistrer sous',
                      MB_YESNO Or MB_QUERY) <> MBID_YES Then Exit;
        CloseDlg;
        If SaveFile(W, S) Then
        Begin
          Wins[W].FileName := S;
          StatusMsg := Acc('Enregistr^e : ') + S;
          Redraw;
          If PendCmd <> 0 Then
          Begin
            I := PendCmd;
            PendCmd := 0;
            Command(I);
          End;
        End;
      End;
    DM_FIND :
      Begin
        CloseDlg;
        FindText := S;
        FindAgain(SrcWin);
      End;
    DM_GOTO :
      Begin
        CloseDlg;
        Val(S, V, E);
        If E = 0 Then GotoLine(SrcWin, V);
      End;
    DM_PARAMS :
      Begin
        CloseDlg;
        RunParams := S;
      End;
    DM_OPEN :
      Begin
        I := WinSendMsg(DlgLb, LM_QUERYSELECTION, -1, 0);
        If (S = '') And (I >= 0) And (I < DlgNItems) Then S := DlgItems[I];
        OpenChoice(S);
      End;
  Else
    Begin
      { liste des fenetres }
      I := WinSendMsg(DlgLb, LM_QUERYSELECTION, -1, 0);
      CloseDlg;
      If (I >= 0) And (I < DlgNItems) Then
      Begin
        Val(DlgItems[I], W, E);
        If (E = 0) And (W >= 0) And (W < MAXWIN) And Wins[W].Used Then Activate(W);
      End;
    End;
  End;
End;

Function DlgCharKey(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk : LongInt;
Begin
  Fl := Lo16(Mp1); Vk := Hi16(Mp2);
  DlgCharKey := 1;
  If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then DlgDone
  Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then CloseDlg
  Else DlgCharKey := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

Function InputProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  InputProc := 0;
  Case Msg Of
    WM_CREATE :
      Begin
        DlgCl := H;
        DlgEf := WinCreateWindow(H, WC_ENTRYFIELD, 0, WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
                                 8, 44, 432, 18, H, HWND_TOP, ID_DEF, 0, 0);
        Dummy := WinSendMsg(DlgEf, EM_SETTEXTLIMIT, 250, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                                 264, 8, 84, 24, H, HWND_TOP, ID_DOK, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                 356, 8, 84, 24, H, HWND_TOP, ID_DCANCEL, 0, 0);
      End;
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
        DlgText(Hps, Rc[3], 8, 10, DlgPrompt, CLR_BLACK);
        Dummy := WinEndPaint(Hps);
      End;
    WM_COMMAND :
      If Lo16(Mp1) = ID_DOK Then DlgDone Else If Lo16(Mp1) = ID_DCANCEL Then CloseDlg;
    WM_CHAR : InputProc := DlgCharKey(H, Msg, Mp1, Mp2);
    WM_CLOSE : CloseDlg;
  Else
    InputProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Function OpenProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, I : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  OpenProc := 0;
  Case Msg Of
    WM_CREATE :
      Begin
        DlgCl := H;
        DlgEf := WinCreateWindow(H, WC_ENTRYFIELD, 0, WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
                                 8, 266, 444, 18, H, HWND_TOP, ID_DEF, 0, 0);
        Dummy := WinSendMsg(DlgEf, EM_SETTEXTLIMIT, 250, 0);
        DlgLb := WinCreateWindow(H, WC_LISTBOX, 0, WS_VISIBLE Or WS_TABSTOP, 8, 40, 444, 196, H, HWND_TOP, ID_DLIST, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Ouvrir'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                                 276, 8, 84, 24, H, HWND_TOP, ID_DOK, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                 368, 8, 84, 24, H, HWND_TOP, ID_DCANCEL, 0, 0);
      End;
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
        DlgText(Hps, Rc[3], 8, Rc[3] - 284 - 20, 'Nom du fichier :', CLR_BLACK);
        DlgText(Hps, Rc[3], 8, Rc[3] - 236 - 20, Acc('R^epertoire : ') + DlgDir, CLR_DARKBLUE);
        Dummy := WinEndPaint(Hps);
      End;
    WM_CONTROL :
      If Lo16(Mp1) = ID_DLIST Then
      Begin
        I := WinSendMsg(DlgLb, LM_QUERYSELECTION, -1, 0);
        If (I >= 0) And (I < DlgNItems) Then
        Begin
          If Hi16(Mp1) = LN_ENTER Then
          Begin
            Dummy := WinSetWindowText(DlgEf, Z(''));
            OpenChoice(DlgItems[I]);
          End
          Else If Hi16(Mp1) = LN_SELECT Then
            If DlgItems[I][1] <> '[' Then Dummy := WinSetWindowText(DlgEf, Z(DlgItems[I]));
        End;
      End;
    WM_COMMAND :
      If Lo16(Mp1) = ID_DOK Then DlgDone Else If Lo16(Mp1) = ID_DCANCEL Then CloseDlg;
    WM_CHAR : OpenProc := DlgCharKey(H, Msg, Mp1, Mp2);
    WM_CLOSE : CloseDlg;
  Else
    OpenProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Function WinListProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  WinListProc := 0;
  Case Msg Of
    WM_CREATE :
      Begin
        DlgCl := H;
        DlgEf := 0;
        DlgLb := WinCreateWindow(H, WC_LISTBOX, 0, WS_VISIBLE Or WS_TABSTOP, 8, 40, 444, 210, H, HWND_TOP, ID_DLIST, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Activer'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                                 276, 8, 84, 24, H, HWND_TOP, ID_DOK, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                 368, 8, 84, 24, H, HWND_TOP, ID_DCANCEL, 0, 0);
      End;
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
        Dummy := WinEndPaint(Hps);
      End;
    WM_CONTROL :
      If (Lo16(Mp1) = ID_DLIST) And (Hi16(Mp1) = LN_ENTER) Then DlgDone;
    WM_COMMAND :
      If Lo16(Mp1) = ID_DOK Then DlgDone Else If Lo16(Mp1) = ID_DCANCEL Then CloseDlg;
    WM_CHAR : WinListProc := DlgCharKey(H, Msg, Mp1, Mp2);
    WM_CLOSE : CloseDlg;
  Else
    WinListProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
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
  MenuOpen := MenuLen;
  MW(0); MW(0); MW(0);
End;

Procedure MenuClose(H, Count : LongInt);
Begin
  WrW(LongInt(@MenuT) + H, MenuLen - H);
  WrW(LongInt(@MenuT) + H + 4, Count);
End;

Procedure MItem(Style, Attr, Id : LongInt; S : String);
Var K : LongInt;
Begin
  MW(Style); MW(Attr); MW(Id);
  If (Style And MIS_SEPARATOR) = 0 Then
  Begin
    For K := 1 To Length(S) Do MB(Ord(S[K]));
    MB(0);
  End;
End;

Procedure MSep;
Begin
  MItem(MIS_SEPARATOR, 0, 0, '');
End;

Procedure BuildMenu;
Var H0, H1 : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Fichier');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouveau' + Chr(9) + 'Ctrl+N');
  MItem(MIS_TEXT, 0, CM_OPEN, '~Ouvrir...' + Chr(9) + 'F3');
  MItem(MIS_TEXT, 0, CM_SAVE, '~Enregistrer' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_SAVEAS, 'Enregistrer ~sous...');
  MItem(MIS_TEXT, 0, CM_SAVEALL, 'Enregistrer ~tout');
  MSep;
  MItem(MIS_TEXT, 0, CM_CLOSE, '~Fermer' + Chr(9) + 'Alt+F3');
  MSep;
  MItem(MIS_TEXT, 0, CM_EXIT, '~Quitter' + Chr(9) + 'Alt+X');
  MenuClose(H1, 9);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Edition');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_CUT, '~Couper' + Chr(9) + 'Maj+Suppr');
  MItem(MIS_TEXT, 0, CM_COPY, 'C~opier' + Chr(9) + 'Ctrl+Ins');
  MItem(MIS_TEXT, 0, CM_PASTE, 'Co~ller' + Chr(9) + 'Maj+Ins');
  MItem(MIS_TEXT, 0, CM_CLEAR, '~Effacer' + Chr(9) + 'Ctrl+Suppr');
  MSep;
  MItem(MIS_TEXT, 0, CM_SELALL, Acc('~Tout s^electionner') + Chr(9) + 'Ctrl+A');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, '~Recherche');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_FIND, '~Rechercher...' + Chr(9) + 'Ctrl+F');
  MItem(MIS_TEXT, 0, CM_FINDNEXT, '~Occurrence suivante' + Chr(9) + 'Ctrl+L');
  MItem(MIS_TEXT, 0, CM_GOTO, Acc('~Aller ^a la ligne...') + Chr(9) + 'Ctrl+G');
  MSep;
  MItem(MIS_TEXT, 0, CM_OPENCUR, 'Ouvrir le ~fichier au curseur' + Chr(9) + 'Ctrl+Entr' + Chr(130) + 'e');
  MenuClose(H1, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 400, Acc('Ex^ecu~ter'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RUN, Acc('~Ex^ecuter') + Chr(9) + 'Ctrl+F9');
  MItem(MIS_TEXT, 0, CM_PARAMS, Acc('~Param^etres...'));
  MenuClose(H1, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 500, '~Compiler');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_COMPILE, '~Compiler' + Chr(9) + 'F9');
  MItem(MIS_TEXT, 0, CM_INFO, '~Information...');
  MSep;
  MItem(MIS_TEXT, MIA_CHECKED, CM_TGTPM, 'Destination OS/2 ~Presentation Manager');
  MItem(MIS_TEXT, 0, CM_TGTCON, 'Destination OS/2 Co~nsole');
  MenuClose(H1, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 600, Acc('Fe~n^etre'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_TILE, Acc('~Mosa^ique'));
  MItem(MIS_TEXT, 0, CM_CASCADE, '~Cascade');
  MItem(MIS_TEXT, 0, CM_NEXT, '~Suivante' + Chr(9) + 'F6');
  MItem(MIS_TEXT, 0, CM_MESSAGES, 'M~essages');
  MItem(MIS_TEXT, 0, CM_WIN0, '~Liste...' + Chr(9) + 'Alt+0');
  MSep;
  MItem(MIS_TEXT, 0, CM_CLOSEALL, '~Fermer tout');
  MenuClose(H1, 7);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 700, 'A~ide');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_KEYS, '~Touches' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Pascal Developer...');
  MenuClose(H1, 2);
  MenuClose(H0, 7);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

Procedure SetTarget(T : LongInt);
Var M : LongInt;
Begin
  Target := T;
  M := WinWindowFromID(Frame, $8005);
  If T = 0 Then
  Begin
    Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_TGTPM Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16));
    Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_TGTCON Or $10000, MIA_CHECKED);
  End
  Else
  Begin
    Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_TGTCON Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16));
    Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_TGTPM Or $10000, MIA_CHECKED);
  End;
  StatusMsg := 'Destination : ' + TargetName(T);
  Redraw;
End;

{ menu contextuel de l'editeur, au point (X, Y) de PM }
Procedure ShowContext(X, Y : LongInt);
Var H0, W, A, N : LongInt; F : String;
Begin
  W := ActEdit;
  If W < 0 Then Exit;
  If HasSel(W) Then A := 0 Else A := MIA_DISABLED;
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT, A, CM_CUT, '~Couper' + Chr(9) + 'Maj+Suppr');
  MItem(MIS_TEXT, A, CM_COPY, 'C~opier' + Chr(9) + 'Ctrl+Ins');
  MItem(MIS_TEXT, 0, CM_PASTE, 'Co~ller' + Chr(9) + 'Maj+Ins');
  MItem(MIS_TEXT, A, CM_CLEAR, '~Effacer' + Chr(9) + 'Ctrl+Suppr');
  MSep;
  MItem(MIS_TEXT, 0, CM_SELALL, Acc('~Tout s^electionner') + Chr(9) + 'Ctrl+A');
  MSep;
  F := WordAt(W, True);
  If F <> '' Then MItem(MIS_TEXT, 0, CM_OPENCUR, 'Ouvrir le ~fichier ' + F)
  Else MItem(MIS_TEXT, MIA_DISABLED, CM_OPENCUR, 'Ouvrir le ~fichier au curseur');
  MItem(MIS_TEXT, 0, CM_GOTO, Acc('~Aller ^a la ligne...'));
  MSep;
  MItem(MIS_TEXT, 0, CM_COMPILE, 'Co~mpiler' + Chr(9) + 'F9');
  MItem(MIS_TEXT, 0, CM_RUN, Acc('Ex^ecute~r') + Chr(9) + 'Ctrl+F9');
  MItem(MIS_TEXT, 0, CM_INFO, '~Information...');
  N := 13;
  MenuClose(H0, N);
  If CtxMenu <> 0 Then Dummy := WinDestroyWindow(CtxMenu);
  CtxMenu := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuT));
  If CtxMenu <> 0 Then Dummy := WinPopupMenu(Client, Client, CtxMenu, X, Y, 0, 0);
End;

{ Maj+F10 : menu contextuel au curseur du texte }
Procedure ContextAtCursor;
Var W, X1, Y1, X2, Y2, X, Y : LongInt;
Begin
  W := ActEdit;
  If W < 0 Then Exit;
  TextArea(W, X1, Y1, X2, Y2);
  X := MinI(X2 - 1, MaxI(X1, X1 + 4 + (Wins[W].CX - Wins[W].LeftC) * CHW));
  Y := MinI(Y2 - 1, MaxI(Y1, Y1 + (Wins[W].CY - Wins[W].TopL + 1) * CHH));
  ShowContext(X, CH - 1 - Y);
End;

{ ouvrir le fichier dont le nom est sous le curseur (directive $I X.INC, Uses X) }
Procedure OpenAtCursor;
Var W, R : LongInt; N, D : String;
Begin
  W := ActEdit;
  If W < 0 Then Exit;
  N := WordAt(W, True);
  If N = '' Then
  Begin
    StatusMsg := Acc('Aucun nom de fichier sous le curseur');
    Redraw;
    Exit;
  End;
  If Wins[W].FileName <> '' Then D := DirOf(Wins[W].FileName) Else D := WorkDir;
  R := -1;
  If FileExists(D + N) Then R := OpenDoc(D + N, True)
  Else If FileExists(D + N + '.PAS') Then R := OpenDoc(D + N + '.PAS', True)
  Else If FileExists(D + N + '.INC') Then R := OpenDoc(D + N + '.INC', True)
  Else If FileExists(N) Then R := OpenDoc(N, True)
  Else If FileExists(N + '.PAS') Then R := OpenDoc(N + '.PAS', True);
  If R < 0 Then ShowMsg(Acc('Fichier introuvable : ') + N, 'Ouvrir le fichier au curseur', MB_OK Or MB_WARNING);
End;

Procedure ShowKeys;
Begin
  ShowMsg(Acc('F2 enregistrer, F3 ouvrir, Alt+F3 fermer, F6 fen^etre suivante, Alt+0 liste des fen^etres, ') +
          Acc('F9 compiler, Ctrl+F9 ex^ecuter, Alt+X quitter. Ins : insertion ou refrappe. ') +
          Acc('Maj+fl^eches : s^election ; Ctrl+Ins/Ctrl+C copier, Maj+Suppr/Ctrl+X couper, ') +
          Acc('Maj+Ins/Ctrl+V coller, Ctrl+Suppr effacer, Ctrl+A tout s^electionner, Ctrl+Y supprimer la ligne. ') +
          Acc('Ctrl+F rechercher, Ctrl+L suivant, Ctrl+G aller ^a la ligne, Ctrl+Entr^ee ouvrir le fichier ') +
          Acc('au curseur. Bouton 2 de la souris ou Maj+F10 : menu contextuel.'), 'Touches', MB_OK Or MB_INFORMATION);
End;

Procedure Quit;
Begin
  If CloseAll Then Dummy := WinPostMsg(Client, WM_QUIT, 0, 0);
End;

Procedure Command(Id : LongInt);
Var W, K : LongInt;
Begin
  W := ActEdit;
  Case Id Of
    CM_NEW : If NewDoc >= 0 Then ;
    CM_OPEN : OpenFileDlg;
    CM_SAVE : If SrcWin >= 0 Then If SaveDoc(SrcWin) Then ;
    CM_SAVEAS :
      If SrcWin >= 0 Then
      Begin
        If Wins[SrcWin].FileName <> '' Then OpenInput(DM_SAVEAS, 'Enregistrer sous', 'Nom du fichier :', Wins[SrcWin].FileName)
        Else OpenInput(DM_SAVEAS, 'Enregistrer sous', 'Nom du fichier :', WorkDir + 'NONAME' + IStr(Wins[SrcWin].Untitled) + '.PAS');
      End;
    CM_SAVEALL :
      For K := 0 To MAXWIN - 1 Do
        If Wins[K].Used And (Wins[K].Kind = WK_EDIT) And Wins[K].Modified And (Wins[K].FileName <> '') Then
          If SaveFile(K, Wins[K].FileName) Then Redraw;
    CM_CLOSE : If TopWin >= 0 Then If CloseWin(TopWin) Then ;
    CM_EXIT : Quit;
    CM_CUT : If W >= 0 Then Begin CutSel(W); Redraw; End;
    CM_COPY : If W >= 0 Then CopySel(W);
    CM_PASTE : If W >= 0 Then Begin Paste(W); Redraw; End;
    CM_CLEAR : If W >= 0 Then Begin If DeleteSel(W) Then ; Redraw; End;
    CM_SELALL : If W >= 0 Then Begin SelectAll(W); Redraw; End;
    CM_FIND : If SrcWin >= 0 Then OpenInput(DM_FIND, 'Rechercher', Acc('Texte ^a rechercher :'), FindText);
    CM_FINDNEXT : If FindText = '' Then Command(CM_FIND) Else FindAgain(SrcWin);
    CM_GOTO :
      If SrcWin >= 0 Then
        OpenInput(DM_GOTO, Acc('Aller ^a la ligne'), Acc('Num^ero de ligne (1 ^a ') + IStr(Wins[SrcWin].NLines) + ') :',
                  IStr(Wins[SrcWin].CY + 1));
    CM_OPENCUR : OpenAtCursor;
    CM_RUN : RunProgram;
    CM_PARAMS : OpenInput(DM_PARAMS, Acc('Param^etres'), Acc('Param^etres du programme :'), RunParams);
    CM_COMPILE :
      Begin
        PendRun := False;
        If Compile Then ;
      End;
    CM_INFO : ShowInfo;
    CM_TGTPM : SetTarget(0);
    CM_TGTCON : SetTarget(1);
    CM_TILE : Tile;
    CM_CASCADE : Cascade;
    CM_NEXT : NextWin;
    CM_MESSAGES : ShowMessages;
    CM_WIN0 : WinListDlg;
    CM_CLOSEALL : If CloseAll Then ;
    CM_KEYS : ShowKeys;
    CM_ABOUT : ShowAbout;
  End;
  { apres un menu, le clavier revient a l'editeur (sauf dialogue ouvert) }
  If (DlgFr = 0) And (InfoFr = 0) And (AboutFr = 0) And (WinQueryActiveWindow(HWND_DESKTOP) = Frame) Then
    Dummy := WinSetFocus(HWND_DESKTOP, Client);
End;

{ ==================================================================== }
{ Souris                                                                }
{ ==================================================================== }

{ fenetre sous le point (X, Y), de la plus haute a la plus basse }
Function HitWin(X, Y : LongInt) : LongInt;
Var K, W, Wx, Wy, Wd, Ht : LongInt;
Begin
  HitWin := -1;
  For K := NZ - 1 DownTo 0 Do
  Begin
    W := ZOrd[K];
    Geo(W, Wx, Wy, Wd, Ht);
    If (X >= Wx) And (X < Wx + Wd) And (Y >= Wy) And (Y < Wy + Ht) Then
    Begin
      HitWin := W;
      Exit;
    End;
  End;
End;

{ position du texte (colonne, ligne) sous le point (X, Y) }
Procedure TextPos(W, X, Y : LongInt; Var C, L : LongInt);
Var X1, Y1, X2, Y2 : LongInt;
Begin
  TextArea(W, X1, Y1, X2, Y2);
  C := Wins[W].LeftC + (X - X1 - 4 + CHW Div 2) Div CHW;
  If X - X1 - 4 < 0 Then C := Wins[W].LeftC;
  If Y < Y1 Then L := Wins[W].TopL - 1
  Else L := Wins[W].TopL + (Y - Y1) Div CHH;
  If C < 0 Then C := 0;
  If C > MAXLEN Then C := MAXLEN;
  If L < 0 Then L := 0;
  If L >= ContentLines(W) Then L := ContentLines(W) - 1;
  If L < 0 Then L := 0;
End;

Procedure ThumbDrag(W, Pos : LongInt; Vert : Boolean);
Var X1, Y1, X2, Y2, L, TP, TS, Total, Vis, NewP : LongInt;
Begin
  TextArea(W, X1, Y1, X2, Y2);
  If Vert Then
  Begin
    L := Y2 - Y1 - 2 * SBW; Total := ContentLines(W); Vis := Rows(W);
    ThumbOf(L, Total, Vis, Wins[W].TopL, TP, TS);
    NewP := Pos - Y1 - SBW - DragDY;
  End
  Else
  Begin
    L := X2 - X1 - 2 * SBW; Total := MAXLEN + 1; Vis := Cols(W);
    ThumbOf(L, Total, Vis, Wins[W].LeftC, TP, TS);
    NewP := Pos - X1 - SBW - DragDX;
  End;
  If L - TS <= 0 Then Exit;
  NewP := (NewP * (Total - Vis) + (L - TS) Div 2) Div (L - TS);
  If NewP > Total - Vis Then NewP := Total - Vis;
  If NewP < 0 Then NewP := 0;
  If Vert Then Wins[W].TopL := NewP Else Wins[W].LeftC := NewP;
  Redraw;
End;

Procedure ButtonDown(X, Y, Kc : LongInt; Dbl : Boolean);
Var W, Wx, Wy, Wd, Ht, B, X1, Y1, X2, Y2, L, TP, TS, C, Ln0 : LongInt;
Begin
  W := HitWin(X, Y);
  If W < 0 Then Exit;
  If W <> TopWin Then Activate(W);
  Geo(W, Wx, Wy, Wd, Ht);
  TextArea(W, X1, Y1, X2, Y2);
  B := TTLH - 4;
  { barre de titre }
  If (Y >= Wy + BRD) And (Y < Wy + BRD + TTLH) Then
  Begin
    If (X >= Wx + BRD + 2) And (X < Wx + BRD + 2 + B) Then
    Begin
      If CloseWin(W) Then ;
      Exit;
    End;
    If (X >= Wx + Wd - BRD - 2 - B) And (X < Wx + Wd - BRD - 2) Then
    Begin
      ToggleMax(W);
      Exit;
    End;
    If Dbl Then
    Begin
      ToggleMax(W);
      Exit;
    End;
    If Not Wins[W].Max Then
    Begin
      Drag := DG_MOVE; DragWin := W; DragDX := X - Wx; DragDY := Y - Wy;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
    End;
    Exit;
  End;
  { coin ou bords droit et bas : taille }
  If ((X >= X2) And (Y >= Y2)) Or (X >= Wx + Wd - BRD) Or (Y >= Wy + Ht - BRD) Then
  Begin
    If Not Wins[W].Max And ((X >= X2) Or (X >= Wx + Wd - BRD)) And ((Y >= Y2) Or (Y >= Wy + Ht - BRD)) Then
    Begin
      Drag := DG_SIZE; DragWin := W; DragDX := Wx + Wd - X; DragDY := Wy + Ht - Y;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
      Exit;
    End;
  End;
  { barre de defilement verticale }
  If (X >= X2) And (X < X2 + SBW) And (Y >= Y1) And (Y < Y2) Then
  Begin
    If Y < Y1 + SBW Then ScrollBy(W, -1, 0)
    Else If Y >= Y2 - SBW Then ScrollBy(W, 1, 0)
    Else
    Begin
      L := Y2 - Y1 - 2 * SBW;
      ThumbOf(L, ContentLines(W), Rows(W), Wins[W].TopL, TP, TS);
      If Y < Y1 + SBW + TP Then ScrollBy(W, -Rows(W), 0)
      Else If Y >= Y1 + SBW + TP + TS Then ScrollBy(W, Rows(W), 0)
      Else
      Begin
        Drag := DG_VTHUMB; DragWin := W; DragDY := Y - (Y1 + SBW + TP);
        Dummy := WinSetCapture(HWND_DESKTOP, Client);
      End;
    End;
    Redraw;
    Exit;
  End;
  { barre horizontale }
  If (Y >= Y2) And (Y < Y2 + SBW) And (X >= X1) And (X < X2) Then
  Begin
    If X < X1 + SBW Then ScrollBy(W, 0, -1)
    Else If X >= X2 - SBW Then ScrollBy(W, 0, 1)
    Else
    Begin
      L := X2 - X1 - 2 * SBW;
      ThumbOf(L, MAXLEN + 1, Cols(W), Wins[W].LeftC, TP, TS);
      If X < X1 + SBW + TP Then ScrollBy(W, 0, -Cols(W))
      Else If X >= X1 + SBW + TP + TS Then ScrollBy(W, 0, Cols(W))
      Else
      Begin
        Drag := DG_HTHUMB; DragWin := W; DragDX := X - (X1 + SBW + TP);
        Dummy := WinSetCapture(HWND_DESKTOP, Client);
      End;
    End;
    Redraw;
    Exit;
  End;
  { texte }
  If (X >= X1) And (X < X2) And (Y >= Y1) And (Y < Y2) Then
  Begin
    TextPos(W, X, Y, C, Ln0);
    If Wins[W].Kind = WK_MSG Then
    Begin
      If Ln0 < MsgCount Then MsgSel := Ln0;
      If Dbl Then MsgGo(MsgSel) Else Redraw;
      Exit;
    End;
    If Dbl Then
    Begin
      Wins[W].CX := C; Wins[W].CY := Ln0;
      SelectWord(W);
      Redraw;
      Exit;
    End;
    CurTo(W, C, Ln0, (Kc And KC_SHIFT) <> 0);
    If Not Wins[W].SelOn Then
    Begin
      Wins[W].SelOn := True;
      Wins[W].SAX := C; Wins[W].SAY := Ln0;
    End;
    Drag := DG_SEL; DragWin := W;
    Dummy := WinSetCapture(HWND_DESKTOP, Client);
    Redraw;
  End;
End;

Procedure MouseMove(X, Y : LongInt);
Var W, NX, NY, C, L, X1, Y1, X2, Y2, P : LongInt;
Begin
  W := DragWin;
  If (Drag = DG_NONE) Or (W < 0) Or Not Wins[W].Used Then
  Begin
    { forme du pointeur }
    W := HitWin(X, Y);
    P := SPTR_ARROW;
    If W >= 0 Then
    Begin
      TextArea(W, X1, Y1, X2, Y2);
      If (X >= X1) And (X < X2) And (Y >= Y1) And (Y < Y2) And (Wins[W].Kind = WK_EDIT) Then P := SPTR_TEXT
      Else If (X >= X2) And (Y >= Y2) And Not Wins[W].Max Then P := SPTR_SIZENWSE;
    End;
    Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, P, 0));
    Exit;
  End;
  Case Drag Of
    DG_MOVE :
      Begin
        NX := X - DragDX; NY := Y - DragDY;
        If NY < 0 Then NY := 0;
        If NY > WorkH - TTLH Then NY := WorkH - TTLH;
        If NX > CW - 40 Then NX := CW - 40;
        If NX < 40 - Wins[W].W Then NX := 40 - Wins[W].W;
        If (NX <> Wins[W].X) Or (NY <> Wins[W].Y) Then
        Begin
          Wins[W].X := NX; Wins[W].Y := NY;
          Redraw;
        End;
      End;
    DG_SIZE :
      Begin
        NX := MaxI(160, X + DragDX - Wins[W].X);
        NY := MaxI(TTLH + 2 * BRD + 3 * SBW + CHH, Y + DragDY - Wins[W].Y);
        If (NX <> Wins[W].W) Or (NY <> Wins[W].H) Then
        Begin
          Wins[W].W := NX; Wins[W].H := NY;
          Redraw;
        End;
      End;
    DG_VTHUMB : ThumbDrag(W, Y, True);
    DG_HTHUMB : ThumbDrag(W, X, False);
    DG_SEL :
      Begin
        TextArea(W, X1, Y1, X2, Y2);
        If Y >= Y2 Then ScrollBy(W, 1, 0);
        If (Y < Y1) And (Wins[W].TopL > 0) Then ScrollBy(W, -1, 0);
        TextPos(W, X, MinI(Y, Y2 - 1), C, L);
        If (C <> Wins[W].CX) Or (L <> Wins[W].CY) Then
        Begin
          Wins[W].CX := C; Wins[W].CY := L;
          ShowCursor(W);
          RedrawText(W);
        End;
      End;
  End;
End;

Procedure ButtonUp;
Begin
  If Drag <> DG_NONE Then Dummy := WinSetCapture(HWND_DESKTOP, 0);
  If (Drag = DG_SEL) And (DragWin >= 0) Then
    If Not HasSel(DragWin) Then Wins[DragWin].SelOn := False;
  Drag := DG_NONE;
  DragWin := -1;
End;

{ bouton 2 : menu contextuel (le curseur va au point s'il est hors de la selection) }
Procedure Button2(X, Y, PmX, PmY : LongInt);
Var W, C, L, X1, Y1, X2, Y2 : LongInt;
Begin
  W := HitWin(X, Y);
  If W < 0 Then Exit;
  If W <> TopWin Then Activate(W);
  If Wins[W].Kind <> WK_EDIT Then Exit;
  TextArea(W, X1, Y1, X2, Y2);
  If (X >= X1) And (X < X2) And (Y >= Y1) And (Y < Y2) Then
  Begin
    TextPos(W, X, Y, C, L);
    If Not InSel(W, L, C) Then CurTo(W, C, L, False);
    Redraw;
  End;
  ShowContext(PmX, PmY);
End;

{ ==================================================================== }
{ Clavier                                                               }
{ ==================================================================== }

Function KeyEdit(W, Fl, Vk, KCh : LongInt) : Boolean;
Var Sh, Ct : Boolean; L : LongInt; S : String;
Begin
  KeyEdit := True;
  Sh := (Fl And KC_SHIFT) <> 0;
  Ct := (Fl And KC_CTRL) <> 0;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
    Case Vk Of
      VK_LEFT :
        Begin
          If Ct Then WordLeft(W, Sh)
          Else If Wins[W].CX > 0 Then CurTo(W, Wins[W].CX - 1, Wins[W].CY, Sh)
          Else If Wins[W].CY > 0 Then CurTo(W, LineLen(W, Wins[W].CY - 1), Wins[W].CY - 1, Sh)
          Else CurTo(W, 0, 0, Sh);
          RedrawText(W);
          Exit;
        End;
      VK_RIGHT :
        Begin
          If Ct Then WordRight(W, Sh) Else CurTo(W, Wins[W].CX + 1, Wins[W].CY, Sh);
          RedrawText(W);
          Exit;
        End;
      VK_UP :
        Begin
          If Ct Then
          Begin
            ScrollBy(W, -1, 0);
            If Wins[W].CY >= Wins[W].TopL + Rows(W) Then Wins[W].CY := Wins[W].TopL + Rows(W) - 1;
          End
          Else CurTo(W, Wins[W].CX, Wins[W].CY - 1, Sh);
          RedrawText(W);
          Exit;
        End;
      VK_DOWN :
        Begin
          If Ct Then
          Begin
            ScrollBy(W, 1, 0);
            If Wins[W].CY < Wins[W].TopL Then Wins[W].CY := Wins[W].TopL;
          End
          Else CurTo(W, Wins[W].CX, Wins[W].CY + 1, Sh);
          RedrawText(W);
          Exit;
        End;
      VK_HOME :
        Begin
          If Ct Then CurTo(W, 0, 0, Sh)
          Else
          Begin
            { premier caractere non blanc, puis colonne 1 }
            L := 0;
            S := GetLine(W, Wins[W].CY);
            While (L < Length(S)) And (S[L + 1] = ' ') Do Inc(L);
            If Wins[W].CX = L Then L := 0;
            CurTo(W, L, Wins[W].CY, Sh);
          End;
          RedrawText(W);
          Exit;
        End;
      VK_END :
        Begin
          If Ct Then CurTo(W, LineLen(W, Wins[W].NLines - 1), Wins[W].NLines - 1, Sh)
          Else CurTo(W, LineLen(W, Wins[W].CY), Wins[W].CY, Sh);
          RedrawText(W);
          Exit;
        End;
      VK_PAGEUP :
        Begin
          If Ct Then CurTo(W, 0, 0, Sh)
          Else
          Begin
            ScrollBy(W, -Rows(W) + 1, 0);
            CurTo(W, Wins[W].CX, Wins[W].CY - Rows(W) + 1, Sh);
          End;
          RedrawText(W);
          Exit;
        End;
      VK_PAGEDOWN :
        Begin
          If Ct Then CurTo(W, LineLen(W, Wins[W].NLines - 1), Wins[W].NLines - 1, Sh)
          Else
          Begin
            ScrollBy(W, Rows(W) - 1, 0);
            CurTo(W, Wins[W].CX, Wins[W].CY + Rows(W) - 1, Sh);
          End;
          RedrawText(W);
          Exit;
        End;
      VK_INSERT :
        Begin
          If Sh Then Paste(W)
          Else If Ct Then CopySel(W)
          Else InsMode := Not InsMode;
          Redraw;
          Exit;
        End;
      VK_DELETE :
        Begin
          If Sh Then CutSel(W)
          Else If Ct Then Begin If DeleteSel(W) Then ; End
          Else DeleteChar(W);
          RedrawText(W);
          Exit;
        End;
      VK_BACKSPACE :
        Begin
          BackSpace(W);
          RedrawText(W);
          Exit;
        End;
      VK_ENTER, VK_NEWLINE :
        Begin
          If Ct Then OpenAtCursor
          Else
          Begin
            NewLine(W);
            RedrawText(W);
          End;
          Exit;
        End;
      VK_TAB :
        Begin
          TabKey(W);
          RedrawText(W);
          Exit;
        End;
    End;
  { caracteres }
  If ((Fl And KC_CHAR) <> 0) And (KCh >= 32) And (KCh < 256) And ((Fl And (KC_CTRL Or KC_ALT)) = 0) Then
  Begin
    TypeChar(W, Chr(KCh));
    RedrawText(W);
    Exit;
  End;
  KeyEdit := False;
End;

Function KeyMsgWin(Fl, Vk : LongInt) : Boolean;
Begin
  KeyMsgWin := True;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
    Case Vk Of
      VK_UP : If MsgSel > 0 Then Dec(MsgSel);
      VK_DOWN : If MsgSel < MsgCount - 1 Then Inc(MsgSel);
      VK_ENTER, VK_NEWLINE : MsgGo(MsgSel);
    Else
      Begin
        KeyMsgWin := False;
        Exit;
      End;
    End
  Else
  Begin
    KeyMsgWin := False;
    Exit;
  End;
  If (MsgWin >= 0) And (MsgSel >= 0) Then
  Begin
    If MsgSel < Wins[MsgWin].TopL Then Wins[MsgWin].TopL := MsgSel;
    If MsgSel >= Wins[MsgWin].TopL + Rows(MsgWin) Then Wins[MsgWin].TopL := MsgSel - Rows(MsgWin) + 1;
  End;
  Redraw;
End;

{ touches de l'EDI ; Faux : a traiter par l'editeur ou PM }
Function KeyGlobal(Fl, Vk, KCh : LongInt) : Boolean;
Var C : LongInt; Ct, Al, Sh : Boolean;
Begin
  KeyGlobal := True;
  Ct := (Fl And KC_CTRL) <> 0;
  Al := (Fl And KC_ALT) <> 0;
  Sh := (Fl And KC_SHIFT) <> 0;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_KEYS); Exit; End;
    If (Vk = VK_F1 + 1) And Not Al Then Begin Command(CM_SAVE); Exit; End;
    If (Vk = VK_F1 + 2) And Al Then Begin Command(CM_CLOSE); Exit; End;
    If Vk = VK_F1 + 2 Then Begin Command(CM_OPEN); Exit; End;
    If Vk = VK_F1 + 5 Then Begin Command(CM_NEXT); Exit; End;
    If (Vk = VK_F1 + 8) And Ct Then Begin Command(CM_RUN); Exit; End;
    If Vk = VK_F1 + 8 Then Begin Command(CM_COMPILE); Exit; End;
    If (Vk = VK_F1 + 9) And Sh Then Begin ContextAtCursor; Exit; End;
  End;
  If ((Fl And KC_CHAR) <> 0) Or ((Fl And KC_VIRTUALKEY) = 0) Then
  Begin
    C := KCh;
    If (C >= 1) And (C <= 26) Then C := C + 64;
    C := C And $DF;
    If Al And Not Ct Then
    Begin
      If C = Ord('X') Then Begin Command(CM_EXIT); Exit; End;
      If KCh = Ord('0') Then Begin Command(CM_WIN0); Exit; End;
    End;
    If Ct And Not Al Then
    Begin
      Case Chr(C) Of
        'N' : Begin Command(CM_NEW); Exit; End;
        'O' : Begin Command(CM_OPEN); Exit; End;
        'S' : Begin Command(CM_SAVE); Exit; End;
        'F' : Begin Command(CM_FIND); Exit; End;
        'L' : Begin Command(CM_FINDNEXT); Exit; End;
        'G' : Begin Command(CM_GOTO); Exit; End;
        'A' : Begin Command(CM_SELALL); Exit; End;
        'C' : Begin Command(CM_COPY); Exit; End;
        'X' : Begin Command(CM_CUT); Exit; End;
        'V' : Begin Command(CM_PASTE); Exit; End;
        'Y' :
          If ActEdit >= 0 Then
          Begin
            DeleteLine(ActEdit);
            Redraw;
            Exit;
          End;
      End;
    End;
  End;
  KeyGlobal := False;
End;

{ ==================================================================== }
{ Fenetre principale                                                    }
{ ==================================================================== }

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Fl, Vk, KCh, W, X, Y : LongInt;
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
      If (Mp1 And $FFFF) = 7 Then
      Begin
        { fin du compilateur ; Ctrl+F9 : execution ensuite }
        If CompilePoll And PendRun Then
        Begin
          PendRun := False;
          If LastOk Then RunProgram;
        End;
      End
      Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_BUTTON1DOWN :
      Begin
        ButtonDown(S16(Mp1), CH - 1 - S16(Mp1 Shr 16), Hi16(Mp2), False);
        MainProc := 1;
      End;
    WM_BUTTON1DBLCLK :
      Begin
        ButtonDown(S16(Mp1), CH - 1 - S16(Mp1 Shr 16), Hi16(Mp2), True);
        MainProc := 1;
      End;
    WM_BUTTON1UP :
      Begin
        ButtonUp;
        MainProc := 1;
      End;
    WM_BUTTON2DOWN :
      Begin
        Button2(S16(Mp1), CH - 1 - S16(Mp1 Shr 16), S16(Mp1), S16(Mp1 Shr 16));
        MainProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        MouseMove(S16(Mp1), CH - 1 - S16(Mp1 Shr 16));
        MainProc := 1;
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2); KCh := Lo16(Mp2);
        If (Fl And KC_KEYUP) <> 0 Then
        Begin
          MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
          Exit;
        End;
        If KeyGlobal(Fl, Vk, KCh) Then
        Begin
          MainProc := 1;
          Exit;
        End;
        W := TopWin;
        If (W >= 0) And (Wins[W].Kind = WK_MSG) Then
        Begin
          If KeyMsgWin(Fl, Vk) Then
          Begin
            MainProc := 1;
            Exit;
          End;
        End
        Else If W >= 0 Then
          If KeyEdit(W, Fl, Vk, KCh) Then
          Begin
            If StatusMsg <> '' Then
            Begin
              StatusMsg := '';
              InvRect(0, WorkH, CW, CH);
            End;
            MainProc := 1;
            Exit;
          End;
        MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE : Quit;
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
  X := 0; Y := 0;
End;

{ le repertoire D (avec \ final) accepte-t-il un nouveau fichier ? }
Function CanWrite(D : String) : Boolean;
Var F : Text; R : LongInt;
Begin
  Assign(F, D + 'PASDEV.$$$');
  {$I-} Rewrite(F); {$I+}
  R := IOResult;
  CanWrite := R = 0;
  If R = 0 Then
  Begin
    Close(F);
    {$I-} Erase(F); {$I+}
    R := IOResult;
  End;
End;

Var
  Fl, Sw, Sh, K : LongInt;
  S : String;

BEGIN
  FileMode := 0;
  InsMode := True;
  Target := 0;
  MsgWin := -1;
  NZ := 0;
  Drag := DG_NONE; DragWin := -1;
  PendCmd := 0;
  { repertoires : celui du programme (OS2PC.EXE a cote), repertoire de travail }
  ExeDir := DirOf(FullPath(ParamStr(0)));
  CompilerPath := ExeDir + 'OS2PC.EXE';
  If Not FileExists(CompilerPath) Then CompilerPath := 'C:\OS2PC.EXE';
  If Not FileExists(CompilerPath) Then CompilerPath := ExeDir + 'OS2PC.EXE';
  GetDir(0, WorkDir);
  If (WorkDir <> '') And (WorkDir[Length(WorkDir)] <> '\') Then WorkDir := WorkDir + '\';
  WorkDir := UpStr(WorkDir);
  { CD-ROM (lecture seule) : le disque virtuel D: pour les nouveaux fichiers }
  If Not CanWrite(WorkDir) Then
    If CanWrite('D:\') Then WorkDir := 'D:\';
  DlgDir := WorkDir;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  Dummy := WinRegisterClass(Hab, Z('PASDEV'), LongInt(@MainProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('PDINPUT'), LongInt(@InputProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('PDOPEN'), LongInt(@OpenProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('PDWINLIST'), LongInt(@WinListProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('PDINFO'), LongInt(@InfoProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('PDABOUT'), LongInt(@AboutProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('PASDEV'), Z2('Pascal Developer'), 0, 0, 0,
                              LongInt(@Client));
  BuildMenu;
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, 0, 0, Sw, Sh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinQueryWindowRect(Client, LongInt(@Qmsg));
  CW := Qmsg[2]; CH := Qmsg[3];
  { fichiers de la ligne de commande, sinon un document vide }
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If OpenDoc(S, False) >= 0 Then ;
  End;
  If NZ = 0 Then If NewDoc >= 0 Then ;
  If Not FileExists(CompilerPath) Then
    StatusMsg := Acc('Attention : OS2PC.EXE introuvable (compilation impossible)');
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
