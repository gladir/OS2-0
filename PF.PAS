{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: PF - PascalFlow, flux d'automatisation dans l'esprit de
                Power Automate pour le Presentation Manager d'OS/2-0 ;
                les flux sont enregistres en Pascal (fichiers .pf).
}

Program PascalFlow;

{$R-,S-,I-}

(* Compilation : OS2PC PF.PAS PF.EXE

  PascalFlow (dossier Developer Kit du bureau) : un flux est une suite
  d'actions reliees par des fleches, a la maniere de Power Automate, avec
  l'apparence et les menus d'OS/2 :
    - au centre, le flux : un declencheur (Declencher manuellement un
      flux) puis des actions ; une Condition se partage en deux branches
      Vrai et Faux, Appliquer a chacun et Faire jusqu'a contiennent les
      actions repetees ; un bouton + sur chaque fleche insere une action a
      cet endroit, un menu contextuel (bouton 2 ou le bouton ... de la
      carte) copie, coupe, colle, duplique, deplace, desactive ou supprime
      une action ; une carte se depose sur un + par glisser-deposer ;
    - a gauche, la barre verticale des actions qu'on greffe au flux (clic :
      apres l'action choisie ; glisser : sur un +) ;
    - a droite, les proprietes de l'action courante (titre et parametres)
      et le resultat de sa derniere execution ;
    - Tester (F5, pas a pas visible) et Executer manuellement (Ctrl+F5) :
      un crochet vert marque chaque action reussie, un X rouge l'action
      qui a echoue ou qui a arrete le flux en faute, et ses conteneurs.
  Les valeurs des parametres acceptent des expressions @{...} (variables,
  operateurs + - * / & et fonctions : concat, length, toUpper, substring,
  replace, add, if, utcNow...).

  Le fichier d'un flux (.pf) est un programme Pascal : chaque action est
  une instruction (InitialiserVariable('Compteur', 'Entier', '0');), une
  Condition est un If ... Then ... Else, Appliquer a chacun un For ... In,
  Faire jusqu'a un Repeat ... Until ; le titre de chaque carte est dans le
  commentaire { @ ... } qui la precede.

  PascalFlow n'est pas un service : un flux ne s'execute qu'a la main, et
  tout s'arrete quand on ferme le programme.

  Parametres : un fichier .pf a ouvrir ; /RUN l'execute, /OUT fichier y
  ecrit le journal de l'execution puis ferme PascalFlow (essais
  automatiques ; les messages vont alors dans le journal et les questions
  prennent leur valeur par defaut). *)

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
  TbH = 30; SbH = 20; RowH = 16; ScrW = 16;

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

{ ==================================================================== }
{ Sortes d'actions                                                      }
{ ==================================================================== }

Const
  kTrigger = 1; kInitVar = 2; kSetVar = 3; kIncVar = 4; kDecVar = 5; kAppend = 6; kCompose = 7;
  kCond = 8; kForEach = 9; kUntil = 10; kWait = 11; kTerminate = 12;
  kReadFile = 13; kWriteFile = 14; kCopyFile = 15; kDelFile = 16; kMkDir = 17; kListFiles = 18;
  kMessage = 19; kAsk = 20; kLog = 21; kRun = 22; kDateTime = 23;
  NKinds = 23;
  NCats = 6;
  MaxN = 400;        { noeuds du flux (0 : la racine) }
  MaxPar = 4;
  { etat d'execution d'une action }
  stNone = 0; stOk = 1; stFail = 2; stSkip = 3; stRun = 4;

Function KName(K : LongInt) : String;
Begin
  Case K Of
    kTrigger : KName := 'D'#130'clencher manuellement un flux';
    kInitVar : KName := 'Initialiser une variable';
    kSetVar : KName := 'D'#130'finir une variable';
    kIncVar : KName := 'Incr'#130'menter une variable';
    kDecVar : KName := 'D'#130'cr'#130'menter une variable';
    kAppend : KName := 'Ajouter '#133' une variable';
    kCompose : KName := 'Composer';
    kCond : KName := 'Condition';
    kForEach : KName := 'Appliquer '#133' chacun';
    kUntil : KName := 'Faire jusqu'''#133;
    kWait : KName := 'Attendre';
    kTerminate : KName := 'Terminer';
    kReadFile : KName := 'Lire un fichier';
    kWriteFile : KName := #144'crire un fichier';
    kCopyFile : KName := 'Copier un fichier';
    kDelFile : KName := 'Supprimer un fichier';
    kMkDir : KName := 'Cr'#130'er un dossier';
    kListFiles : KName := 'Lister les fichiers';
    kMessage : KName := 'Afficher un message';
    kAsk : KName := 'Demander une valeur';
    kLog : KName := #144'crire dans le journal';
    kRun : KName := 'Lancer un programme';
    kDateTime : KName := 'Date et heure';
  Else
    KName := '';
  End;
End;

{ nom de l'instruction Pascal dans les fichiers .pf }
Function KProc(K : LongInt) : String;
Begin
  Case K Of
    kTrigger : KProc := 'DeclencherManuellement';
    kInitVar : KProc := 'InitialiserVariable';
    kSetVar : KProc := 'DefinirVariable';
    kIncVar : KProc := 'IncrementerVariable';
    kDecVar : KProc := 'DecrementerVariable';
    kAppend : KProc := 'AjouterAVariable';
    kCompose : KProc := 'Composer';
    kCond : KProc := 'Condition';
    kForEach : KProc := 'Liste';
    kUntil : KProc := 'Condition';
    kWait : KProc := 'Attendre';
    kTerminate : KProc := 'Terminer';
    kReadFile : KProc := 'LireFichier';
    kWriteFile : KProc := 'EcrireFichier';
    kCopyFile : KProc := 'CopierFichier';
    kDelFile : KProc := 'SupprimerFichier';
    kMkDir : KProc := 'CreerDossier';
    kListFiles : KProc := 'ListerFichiers';
    kMessage : KProc := 'AfficherMessage';
    kAsk : KProc := 'DemanderValeur';
    kLog : KProc := 'EcrireJournal';
    kRun : KProc := 'LancerProgramme';
    kDateTime : KProc := 'DateHeure';
  Else
    KProc := '';
  End;
End;

Function KCat(K : LongInt) : LongInt;
Begin
  Case K Of
    kTrigger : KCat := 0;
    kInitVar..kCompose : KCat := 1;
    kCond..kTerminate : KCat := 2;
    kReadFile..kListFiles : KCat := 3;
    kMessage..kLog : KCat := 4;
  Else
    KCat := 5;
  End;
End;

Function CatName(C : LongInt) : String;
Begin
  Case C Of
    0 : CatName := 'D'#130'clencheur';
    1 : CatName := 'Variables';
    2 : CatName := 'Contr'#147'le';
    3 : CatName := 'Fichiers';
    4 : CatName := 'Interaction';
  Else
    CatName := 'Syst'#138'me';
  End;
End;

{ couleur de la categorie (bordure et icone des cartes) }
Function CatColor(C : LongInt) : LongInt;
Begin
  Case C Of
    0 : CatColor := cTeal;
    1 : CatColor := cDPink;
    2 : CatColor := cGray;
    3 : CatColor := cDGreen;
    4 : CatColor := cBlue;
  Else
    CatColor := cBrown;
  End;
End;

Function KNPar(K : LongInt) : LongInt;
Begin
  Case K Of
    kTrigger, kInitVar, kWriteFile, kListFiles, kAsk, kRun, kCond : KNPar := 3;
    kUntil : KNPar := 4;
    kSetVar, kIncVar, kDecVar, kAppend, kCompose, kForEach, kTerminate, kReadFile, kCopyFile, kMessage,
    kDateTime : KNPar := 2;
  Else
    KNPar := 1;
  End;
End;

Const
  OpList = '=|<>|>|>=|<|<=|contient|ne contient pas|commence par|finit par|est vide|n''est pas vide';

{ libelle du parametre I (0..3) }
Function KPar(K, I : LongInt) : String;
Var S : String;
Begin
  S := '';
  Case K Of
    kTrigger : S := 'Entr'#130'e ' + IStr(I + 1) + ' (nom, facultatif)';
    kInitVar :
      Case I Of
        0 : S := 'Nom';
        1 : S := 'Type';
      Else
        S := 'Valeur';
      End;
    kSetVar, kIncVar, kDecVar, kAppend : If I = 0 Then S := 'Nom' Else S := 'Valeur';
    kCompose : If I = 0 Then S := 'Entr'#130'es' Else S := 'Variable de sortie';
    kCond, kUntil :
      Case I Of
        0 : S := 'Valeur 1';
        1 : S := 'Op'#130'rateur';
        2 : S := 'Valeur 2';
      Else
        S := 'Nombre maximal de tours';
      End;
    kForEach : If I = 0 Then S := 'Liste (valeurs s'#130'par'#130'es par ;)' Else S := 'Nom de l'''#130'l'#130'ment';
    kWait : S := 'Dur'#130'e (secondes)';
    kTerminate : If I = 0 Then S := 'Statut' Else S := 'Message';
    kReadFile : If I = 0 Then S := 'Chemin du fichier' Else S := 'Variable du contenu';
    kWriteFile :
      Case I Of
        0 : S := 'Chemin du fichier';
        1 : S := 'Contenu';
      Else
        S := 'Mode';
      End;
    kCopyFile : If I = 0 Then S := 'Source' Else S := 'Destination';
    kDelFile : S := 'Chemin du fichier';
    kMkDir : S := 'Chemin du dossier';
    kListFiles :
      Case I Of
        0 : S := 'Dossier';
        1 : S := 'Masque';
      Else
        S := 'Variable de la liste';
      End;
    kMessage : If I = 0 Then S := 'Titre' Else S := 'Texte';
    kAsk :
      Case I Of
        0 : S := 'Question';
        1 : S := 'Variable de la r'#130'ponse';
      Else
        S := 'Valeur par d'#130'faut';
      End;
    kLog : S := 'Texte';
    kRun :
      Case I Of
        0 : S := 'Programme';
        1 : S := 'Param'#138'tres';
      Else
        S := 'Attendre la fin';
      End;
    kDateTime : If I = 0 Then S := 'Variable' Else S := 'Format (AAAA MM JJ hh mm ss)';
  End;
  KPar := S;
End;

Function KDef(K, I : LongInt) : String;
Var S : String;
Begin
  S := '';
  Case K Of
    kInitVar :
      Case I Of
        0 : S := 'Variable1';
        1 : S := 'Cha'#140'ne';
      End;
    kIncVar, kDecVar : If I = 1 Then S := '1';
    kCompose : If I = 1 Then S := 'Sortie';
    kCond, kUntil :
      Case I Of
        1 : S := '=';
        3 : S := '60';
      End;
    kForEach : If I = 1 Then S := 'Element';
    kWait : S := '1';
    kTerminate : If I = 0 Then S := 'R'#130'ussi';
    kReadFile : If I = 1 Then S := 'Contenu';
    kWriteFile : If I = 2 Then S := 'Remplacer';
    kListFiles :
      Case I Of
        1 : S := '*.*';
        2 : S := 'Fichiers';
      End;
    kMessage : If I = 0 Then S := 'PascalFlow';
    kAsk : If I = 1 Then S := 'Reponse';
    kRun : If I = 2 Then S := 'Oui';
    kDateTime : If I = 0 Then S := 'Maintenant' Else S := 'AAAA-MM-JJ hh:mm:ss';
  End;
  KDef := S;
End;

{ valeurs possibles d'un parametre a choix ('' : texte libre) }
Function KEnum(K, I : LongInt) : String;
Begin
  KEnum := '';
  Case K Of
    kInitVar : If I = 1 Then KEnum := 'Cha'#140'ne|Entier|D'#130'cimal|Bool'#130'en|Liste';
    kCond, kUntil : If I = 1 Then KEnum := OpList;
    kTerminate : If I = 0 Then KEnum := 'R'#130'ussi|'#144'chec|Annul'#130;
    kWriteFile : If I = 2 Then KEnum := 'Remplacer|Ajouter';
    kRun : If I = 2 Then KEnum := 'Oui|Non';
  End;
End;

{ element I (0..) d'une liste a | }
Function EnumItem(L : String; I : LongInt) : String;
Var K, N : LongInt; S : String;
Begin
  S := ''; N := 0;
  For K := 1 To Length(L) Do
    If L[K] = '|' Then Inc(N)
    Else If N = I Then S := S + L[K];
  EnumItem := S;
End;

Function EnumCount(L : String) : LongInt;
Var K, N : LongInt;
Begin
  If L = '' Then
  Begin
    EnumCount := 0;
    Exit;
  End;
  N := 1;
  For K := 1 To Length(L) Do If L[K] = '|' Then Inc(N);
  EnumCount := N;
End;

Function IsContainer(K : LongInt) : Boolean;
Begin
  IsContainer := (K = kCond) Or (K = kForEach) Or (K = kUntil);
End;

{ ==================================================================== }
{ Noeuds du flux                                                        }
{ ==================================================================== }

Var
  NUsed, NOff : Array[0..MaxN - 1] Of Boolean;
  NKind, NNext, NParent, NBr, NSt : Array[0..MaxN - 1] Of LongInt;
  NFst : Array[0..MaxN * 2 - 1] Of LongInt;      { premier noeud de chaque branche }
  NTitle, NOut : Array[0..MaxN - 1] Of String;
  NP : Array[0..MaxN * MaxPar - 1] Of String;
  FlowName : String;
  Modified : Boolean;

Function NFirst(P, B : LongInt) : LongInt;
Begin
  NFirst := NFst[P * 2 + B];
End;

Function NBranches(N : LongInt) : LongInt;
Begin
  If N = 0 Then NBranches := 1
  Else If NKind[N] = kCond Then NBranches := 2
  Else If IsContainer(NKind[N]) Then NBranches := 1
  Else NBranches := 0;
End;

Function PGet(N, I : LongInt) : String;
Begin
  PGet := NP[N * MaxPar + I];
End;

Procedure PSet(N, I : LongInt; S : String);
Begin
  NP[N * MaxPar + I] := S;
End;

Procedure NReset;
Var K : LongInt;
Begin
  For K := 0 To MaxN - 1 Do
  Begin
    NUsed[K] := False; NNext[K] := -1;
  End;
  For K := 0 To MaxN * 2 - 1 Do NFst[K] := -1;
  NUsed[0] := True; NKind[0] := 0; NParent[0] := -1;
End;

Function NAlloc(K : LongInt) : LongInt;
Var N, I : LongInt;
Begin
  NAlloc := -1;
  N := 1;
  While (N < MaxN) And NUsed[N] Do Inc(N);
  If N >= MaxN Then Exit;
  NUsed[N] := True; NOff[N] := False;
  NKind[N] := K; NNext[N] := -1; NParent[N] := -1; NBr[N] := 0; NSt[N] := stNone; NOut[N] := '';
  NFst[N * 2] := -1; NFst[N * 2 + 1] := -1;
  NTitle[N] := KName(K);
  For I := 0 To MaxPar - 1 Do PSet(N, I, KDef(K, I));
  NAlloc := N;
End;

Function NCount : LongInt;
Var K, C : LongInt;
Begin
  C := 0;
  For K := 1 To MaxN - 1 Do If NUsed[K] Then Inc(C);
  NCount := C;
End;

Function NLast(P, B : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := NFst[P * 2 + B];
  If N >= 0 Then While NNext[N] >= 0 Do N := NNext[N];
  NLast := N;
End;

Function NPrev(N : LongInt) : LongInt;
Var M : LongInt;
Begin
  NPrev := -1;
  If N <= 0 Then Exit;
  M := NFst[NParent[N] * 2 + NBr[N]];
  While (M >= 0) And (NNext[M] <> N) Do M := NNext[M];
  NPrev := M;
End;

{ inserer N dans la branche B de P, apres After (-1 : au debut) }
Procedure NInsert(P, B, After, N : LongInt);
Begin
  NParent[N] := P; NBr[N] := B;
  If After < 0 Then
  Begin
    NNext[N] := NFst[P * 2 + B];
    NFst[P * 2 + B] := N;
  End
  Else
  Begin
    NNext[N] := NNext[After];
    NNext[After] := N;
  End;
End;

Procedure NUnlink(N : LongInt);
Var Pv : LongInt;
Begin
  If N <= 0 Then Exit;
  Pv := NPrev(N);
  If Pv < 0 Then NFst[NParent[N] * 2 + NBr[N]] := NNext[N] Else NNext[Pv] := NNext[N];
  NNext[N] := -1;
End;

Procedure NFreeTree(N : LongInt);
Var B, C, D : LongInt;
Begin
  If (N <= 0) Or Not NUsed[N] Then Exit;
  For B := 0 To 1 Do
  Begin
    C := NFst[N * 2 + B];
    While C >= 0 Do
    Begin
      D := NNext[C];
      NFreeTree(C);
      C := D;
    End;
    NFst[N * 2 + B] := -1;
  End;
  NUsed[N] := False;
End;

{ A est-il N ou un de ses ancetres ? }
Function IsAncestor(A, N : LongInt) : Boolean;
Begin
  IsAncestor := False;
  While N >= 0 Do
  Begin
    If N = A Then
    Begin
      IsAncestor := True;
      Exit;
    End;
    N := NParent[N];
  End;
End;

Procedure ClearRun;
Var K : LongInt;
Begin
  For K := 0 To MaxN - 1 Do
  Begin
    NSt[K] := stNone; NOut[K] := '';
  End;
End;

{ ==================================================================== }
{ Ecriture d'un flux en Pascal (.pf)                                    }
{ ==================================================================== }

Function IsIdent(S : String) : Boolean;
Var K : LongInt;
Begin
  IsIdent := False;
  If S = '' Then Exit;
  For K := 1 To Length(S) Do
    If Not (((S[K] >= 'A') And (S[K] <= 'Z')) Or ((S[K] >= 'a') And (S[K] <= 'z')) Or (S[K] = '_') Or
       ((K > 1) And (S[K] >= '0') And (S[K] <= '9'))) Then Exit;
  IsIdent := True;
End;

{ identificateur Pascal fait d'un nom quelconque }
Function ToIdent(S : String) : String;
Var K : LongInt; R : String;
Begin
  R := '';
  For K := 1 To Length(S) Do
    If ((S[K] >= 'A') And (S[K] <= 'Z')) Or ((S[K] >= 'a') And (S[K] <= 'z')) Or (S[K] = '_') Or
       ((S[K] >= '0') And (S[K] <= '9')) Then R := R + S[K]
    Else Case S[K] Of
      #130, #136, #137, #138 : R := R + 'e';
      #133, #131, #132, #160 : R := R + 'a';
      #135 : R := R + 'c';
      #140, #139, #161 : R := R + 'i';
      #147, #148, #162 : R := R + 'o';
      #150, #151, #129, #163 : R := R + 'u';
      #144 : R := R + 'E';
    End;
  If (R = '') Or ((R[1] >= '0') And (R[1] <= '9')) Then R := 'F' + R;
  ToIdent := R;
End;

{ chaine Pascal : 'texte' avec '' et #nn pour les caracteres de controle }
Procedure BufPStr(Var B : TBuf; S : String);
Var K : LongInt; InQ : Boolean;
Begin
  If S = '' Then
  Begin
    BufAdd(B, '''''');
    Exit;
  End;
  InQ := False;
  For K := 1 To Length(S) Do
    If S[K] < ' ' Then
    Begin
      If InQ Then BufAddC(B, 39);
      InQ := False;
      BufAdd(B, '#' + IStr(Ord(S[K])));
    End
    Else
    Begin
      If Not InQ Then BufAddC(B, 39);
      InQ := True;
      If S[K] = '''' Then BufAdd(B, '''''') Else BufAddC(B, Ord(S[K]));
    End;
  If InQ Then BufAddC(B, 39);
End;

Procedure BufInd(Var B : TBuf; Ind : LongInt);
Var K : LongInt;
Begin
  For K := 1 To Ind Do BufAdd(B, '  ');
End;

Procedure BufNl(Var B : TBuf);
Begin
  BufAddC(B, 13); BufAddC(B, 10);
End;

{ (p1, p2, ...) sans les parametres vides de la fin }
Procedure BufArgs(Var B : TBuf; N, First, Cnt : LongInt);
Var I, Last : LongInt;
Begin
  Last := -1;
  For I := First To First + Cnt - 1 Do If PGet(N, I) <> '' Then Last := I;
  If Last < 0 Then Exit;
  BufAdd(B, '(');
  For I := First To Last Do
  Begin
    If I > First Then BufAdd(B, ', ');
    BufPStr(B, PGet(N, I));
  End;
  BufAdd(B, ')');
End;

Procedure EmitList(Var B : TBuf; P, Br, Ind : LongInt); Forward;

Procedure EmitBlock(Var B : TBuf; P, Br, Ind : LongInt);
Begin
  BufInd(B, Ind); BufAdd(B, 'Begin'); BufNl(B);
  EmitList(B, P, Br, Ind + 1);
  BufInd(B, Ind); BufAdd(B, 'End');
End;

Procedure EmitNode(Var B : TBuf; N, Ind : LongInt);
Var T, Nm : String; K : LongInt;
Begin
  { titre de la carte }
  T := NTitle[N];
  For K := 1 To Length(T) Do If (T[K] = '}') Or (T[K] < ' ') Then T[K] := ')';
  BufInd(B, Ind);
  If NOff[N] Then BufAdd(B, '{ @- ' + T + ' }') Else BufAdd(B, '{ @ ' + T + ' }');
  BufNl(B);
  BufInd(B, Ind);
  Case NKind[N] Of
    kCond :
      Begin
        BufAdd(B, 'If Condition');
        BufAdd(B, '(');
        For K := 0 To 2 Do
        Begin
          If K > 0 Then BufAdd(B, ', ');
          BufPStr(B, PGet(N, K));
        End;
        BufAdd(B, ') Then'); BufNl(B);
        EmitBlock(B, N, 0, Ind); BufNl(B);
        BufInd(B, Ind); BufAdd(B, 'Else'); BufNl(B);
        EmitBlock(B, N, 1, Ind);
        BufAdd(B, ';');
      End;
    kForEach :
      Begin
        Nm := ToIdent(PGet(N, 1));
        BufAdd(B, 'For ' + Nm + ' In Liste(');
        BufPStr(B, PGet(N, 0));
        If Nm <> PGet(N, 1) Then
        Begin
          BufAdd(B, ', ');
          BufPStr(B, PGet(N, 1));
        End;
        BufAdd(B, ') Do'); BufNl(B);
        EmitBlock(B, N, 0, Ind);
        BufAdd(B, ';');
      End;
    kUntil :
      Begin
        BufAdd(B, 'Repeat'); BufNl(B);
        EmitList(B, N, 0, Ind + 1);
        BufInd(B, Ind); BufAdd(B, 'Until Condition(');
        For K := 0 To 2 Do
        Begin
          If K > 0 Then BufAdd(B, ', ');
          BufPStr(B, PGet(N, K));
        End;
        BufAdd(B, ')');
        If Trim(PGet(N, 3)) <> '' Then
        Begin
          BufAdd(B, ' Or Limite(');
          BufPStr(B, Trim(PGet(N, 3)));
          BufAdd(B, ')');
        End;
        BufAdd(B, ';');
      End;
  Else
    BufAdd(B, KProc(NKind[N]));
    BufArgs(B, N, 0, KNPar(NKind[N]));
    BufAdd(B, ';');
  End;
  BufNl(B);
End;

Procedure EmitList(Var B : TBuf; P, Br, Ind : LongInt);
Var N : LongInt;
Begin
  N := NFirst(P, Br);
  While N >= 0 Do
  Begin
    EmitNode(B, N, Ind);
    N := NNext[N];
  End;
End;

{ le flux entier : un programme Pascal }
Procedure EmitFlow(Var B : TBuf);
Begin
  BufAdd(B, '(* PascalFlow : flux d''OS/2-0 (fichier .pf). Chaque instruction de ce'); BufNl(B);
  BufAdd(B, '   programme Pascal est une action du flux ; le commentaire @ qui la'); BufNl(B);
  BufAdd(B, '   precede donne le titre de sa carte (@- : action desactivee). *)'); BufNl(B);
  BufAdd(B, 'Program ' + ToIdent(FlowName) + ';'); BufNl(B);
  BufNl(B);
  BufAdd(B, 'Begin'); BufNl(B);
  EmitList(B, 0, 0, 1);
  BufAdd(B, 'End.'); BufNl(B);
End;

{ ==================================================================== }
{ Lecture d'un fichier .pf                                              }
{ ==================================================================== }

Const
  tkEof = 0; tkId = 1; tkStr = 2; tkNum = 3; tkSym = 4;

Var
  SrcP : PBytes;
  SrcN, SrcI, SrcLine : LongInt;
  Tk, TkLine : LongInt;
  TkS, TkU : String;
  PendTitle : String;
  PendHas, PendOff : Boolean;
  StTitle : String;              { titre de l'instruction en cours }
  StHas, StOff : Boolean;
  PErr : String;

Function SrcC(I : LongInt) : LongInt;
Begin
  If (I < 0) Or (I >= SrcN) Then SrcC := 0 Else SrcC := SrcP^[I];
End;

Procedure PFail(S : String);
Begin
  If PErr = '' Then PErr := 'ligne ' + IStr(TkLine) + ' : ' + S;
  Tk := tkEof;
End;

Procedure NextTk;
Var C, K, V : LongInt; Cm : String; Done : Boolean;
Begin
  TkS := ''; TkU := '';
  Repeat
    Done := True;
    While (SrcI < SrcN) And (SrcP^[SrcI] <= 32) Do
    Begin
      If SrcP^[SrcI] = 10 Then Inc(SrcLine);
      Inc(SrcI);
    End;
    C := SrcC(SrcI);
    If C = 123 Then
    Begin
      { commentaire entre accolades : un titre de carte s'il commence par @ }
      Cm := '';
      Inc(SrcI);
      While (SrcI < SrcN) And (SrcP^[SrcI] <> 125) Do
      Begin
        If SrcP^[SrcI] = 10 Then Inc(SrcLine);
        If Length(Cm) < 250 Then Cm := Cm + Chr(SrcP^[SrcI]);
        Inc(SrcI);
      End;
      Inc(SrcI);
      Cm := Trim(Cm);
      If (Length(Cm) > 0) And (Cm[1] = '@') Then
      Begin
        Delete(Cm, 1, 1);
        PendOff := (Length(Cm) > 0) And (Cm[1] = '-');
        If PendOff Then Delete(Cm, 1, 1);
        PendTitle := Trim(Cm);
        PendHas := True;
      End;
      Done := False;
    End
    Else If (C = 40) And (SrcC(SrcI + 1) = 42) Then
    Begin
      SrcI := SrcI + 2;
      While (SrcI < SrcN) And Not ((SrcP^[SrcI] = 42) And (SrcC(SrcI + 1) = 41)) Do
      Begin
        If SrcP^[SrcI] = 10 Then Inc(SrcLine);
        Inc(SrcI);
      End;
      SrcI := SrcI + 2;
      Done := False;
    End
    Else If (C = 47) And (SrcC(SrcI + 1) = 47) Then
    Begin
      While (SrcI < SrcN) And (SrcP^[SrcI] <> 10) Do Inc(SrcI);
      Done := False;
    End;
  Until Done;
  TkLine := SrcLine;
  If SrcI >= SrcN Then
  Begin
    Tk := tkEof;
    Exit;
  End;
  C := SrcP^[SrcI];
  If ((C >= 65) And (C <= 90)) Or ((C >= 97) And (C <= 122)) Or (C = 95) Then
  Begin
    While (SrcI < SrcN) And (((SrcP^[SrcI] >= 65) And (SrcP^[SrcI] <= 90)) Or ((SrcP^[SrcI] >= 97) And
          (SrcP^[SrcI] <= 122)) Or (SrcP^[SrcI] = 95) Or ((SrcP^[SrcI] >= 48) And (SrcP^[SrcI] <= 57))) Do
    Begin
      If Length(TkS) < 250 Then TkS := TkS + Chr(SrcP^[SrcI]);
      Inc(SrcI);
    End;
    TkU := UpStr(TkS);
    Tk := tkId;
  End
  Else If (C = 39) Or (C = 35) Then
  Begin
    { 'texte', 'l''apostrophe', #13#10, colles les uns aux autres }
    While (SrcI < SrcN) And ((SrcP^[SrcI] = 39) Or (SrcP^[SrcI] = 35)) Do
    Begin
      If SrcP^[SrcI] = 39 Then
      Begin
        Inc(SrcI);
        Repeat
          If SrcI >= SrcN Then Break;
          If SrcP^[SrcI] = 39 Then
          Begin
            If SrcC(SrcI + 1) = 39 Then
            Begin
              If Length(TkS) < 255 Then TkS := TkS + '''';
              SrcI := SrcI + 2;
            End
            Else
            Begin
              Inc(SrcI);
              Break;
            End;
          End
          Else
          Begin
            If SrcP^[SrcI] = 10 Then Inc(SrcLine);
            If Length(TkS) < 255 Then TkS := TkS + Chr(SrcP^[SrcI]);
            Inc(SrcI);
          End;
        Until False;
      End
      Else
      Begin
        Inc(SrcI);
        V := 0;
        While (SrcI < SrcN) And (SrcP^[SrcI] >= 48) And (SrcP^[SrcI] <= 57) Do
        Begin
          V := V * 10 + SrcP^[SrcI] - 48;
          Inc(SrcI);
        End;
        If Length(TkS) < 255 Then TkS := TkS + Chr(V And 255);
      End;
    End;
    Tk := tkStr;
  End
  Else If (C >= 48) And (C <= 57) Then
  Begin
    While (SrcI < SrcN) And (((SrcP^[SrcI] >= 48) And (SrcP^[SrcI] <= 57)) Or (SrcP^[SrcI] = 46)) Do
    Begin
      TkS := TkS + Chr(SrcP^[SrcI]);
      Inc(SrcI);
    End;
    Tk := tkNum;
  End
  Else
  Begin
    TkS := Chr(C);
    Inc(SrcI);
    If ((C = 58) Or (C = 60) Or (C = 62)) And ((SrcC(SrcI) = 61) Or (SrcC(SrcI) = 62)) Then
    Begin
      TkS := TkS + Chr(SrcP^[SrcI]);
      Inc(SrcI);
    End;
    Tk := tkSym;
  End;
  K := 0;
End;

Function IsSym(S : String) : Boolean;
Begin
  IsSym := (Tk = tkSym) And (TkS = S);
End;

Function IsKw(S : String) : Boolean;
Begin
  IsKw := (Tk = tkId) And (TkU = S);
End;

Procedure Expect(S : String);
Begin
  If PErr <> '' Then Exit;
  If ((Tk = tkSym) And (TkS = S)) Or ((Tk = tkId) And (TkU = UpStr(S))) Then NextTk
  Else PFail(S + ' attendu');
End;

{ une valeur : 'texte' + 'texte' + nombre + identificateur }
Function ParseVal : String;
Var S : String;
Begin
  S := '';
  Repeat
    If (Tk = tkStr) Or (Tk = tkNum) Or (Tk = tkId) Then
    Begin
      S := S + TkS;
      NextTk;
    End
    Else If IsSym('-') Then
    Begin
      S := S + '-';
      NextTk;
      Continue;
    End
    Else
    Begin
      PFail('valeur attendue');
      Break;
    End;
    If IsSym('+') Then NextTk Else Break;
  Until PErr <> '';
  ParseVal := S;
End;

Var
  ArgN : LongInt;
  ArgV : Array[0..7] Of String;

{ (a, b, c) facultatif }
Procedure ParseArgs;
Begin
  ArgN := 0;
  If Not IsSym('(') Then Exit;
  NextTk;
  If IsSym(')') Then
  Begin
    NextTk;
    Exit;
  End;
  Repeat
    If ArgN < 8 Then ArgV[ArgN] := ParseVal Else Dummy := Length(ParseVal);
    Inc(ArgN);
    If IsSym(',') Then NextTk Else Break;
  Until PErr <> '';
  Expect(')');
End;

Function KindOfProc(U : String) : LongInt;
Var K : LongInt;
Begin
  KindOfProc := 0;
  For K := 1 To NKinds Do
    If (K <> kCond) And (K <> kForEach) And (K <> kUntil) And (UpStr(KProc(K)) = U) Then KindOfProc := K;
End;

{ nouveau noeud a la fin de la branche B de P, avec le titre en attente }
Function NewAt(P, B, K : LongInt) : LongInt;
Var N, I : LongInt;
Begin
  N := NAlloc(K);
  NewAt := N;
  If N < 0 Then
  Begin
    PFail('flux trop grand (' + IStr(MaxN - 1) + ' actions au plus)');
    Exit;
  End;
  If StHas Then
  Begin
    If StTitle <> '' Then NTitle[N] := StTitle;
    NOff[N] := StOff;
  End;
  StHas := False;
  For I := 0 To MaxPar - 1 Do PSet(N, I, '');
  NInsert(P, B, NLast(P, B), N);
End;

Procedure SetArgs(N, Cnt : LongInt);
Var I : LongInt;
Begin
  If N < 0 Then Exit;
  For I := 0 To Cnt - 1 Do
    If I < ArgN Then PSet(N, I, ArgV[I]);
End;

Procedure ParseStmts(P, B : LongInt); Forward;

Procedure ParseStmt(P, B : LongInt); Forward;

Procedure ParseBlock(P, B : LongInt);
Begin
  If IsKw('BEGIN') Then
  Begin
    NextTk;
    ParseStmts(P, B);
    Expect('End');
  End
  Else If Not IsSym(';') And Not IsKw('ELSE') And Not IsKw('END') Then ParseStmt(P, B);
End;

Procedure ParseStmt(P, B : LongInt);
Var N, K : LongInt; Nm : String;
Begin
  If PErr <> '' Then Exit;
  { le commentaire @ lu avant cette instruction est son titre }
  StHas := PendHas; StTitle := PendTitle; StOff := PendOff;
  PendHas := False;
  If IsKw('IF') Then
  Begin
    NextTk;
    Expect('Condition');
    ParseArgs;
    Expect('Then');
    If PErr <> '' Then Exit;
    N := NewAt(P, B, kCond);
    If N < 0 Then Exit;
    SetArgs(N, 3);
    If PGet(N, 1) = '' Then PSet(N, 1, '=');
    ParseBlock(N, 0);
    If IsKw('ELSE') Then
    Begin
      NextTk;
      ParseBlock(N, 1);
    End;
  End
  Else If IsKw('FOR') Then
  Begin
    NextTk;
    Nm := TkS;
    If Tk <> tkId Then PFail('identificateur attendu') Else NextTk;
    Expect('In');
    Expect('Liste');
    ParseArgs;
    Expect('Do');
    If PErr <> '' Then Exit;
    N := NewAt(P, B, kForEach);
    If N < 0 Then Exit;
    If ArgN > 0 Then PSet(N, 0, ArgV[0]);
    If ArgN > 1 Then PSet(N, 1, ArgV[1]) Else PSet(N, 1, Nm);
    ParseBlock(N, 0);
  End
  Else If IsKw('REPEAT') Then
  Begin
    NextTk;
    N := NewAt(P, B, kUntil);
    If N < 0 Then Exit;
    ParseStmts(N, 0);
    Expect('Until');
    Expect('Condition');
    ParseArgs;
    SetArgs(N, 3);
    If PGet(N, 1) = '' Then PSet(N, 1, '=');
    If IsKw('OR') Then
    Begin
      NextTk;
      Expect('Limite');
      ParseArgs;
      If ArgN > 0 Then PSet(N, 3, ArgV[0]);
    End;
  End
  Else If IsKw('BEGIN') Then
  Begin
    NextTk;
    ParseStmts(P, B);
    Expect('End');
  End
  Else If Tk = tkId Then
  Begin
    K := KindOfProc(TkU);
    If K = 0 Then
    Begin
      PFail('action inconnue : ' + TkS);
      Exit;
    End;
    NextTk;
    ParseArgs;
    If PErr <> '' Then Exit;
    N := NewAt(P, B, K);
    SetArgs(N, KNPar(K));
  End
  Else PFail('instruction attendue');
End;

Procedure ParseStmts(P, B : LongInt);
Begin
  While PErr = '' Do
  Begin
    While IsSym(';') Do NextTk;
    If (Tk = tkEof) Or IsKw('END') Or IsKw('UNTIL') Or IsKw('ELSE') Then Exit;
    ParseStmt(P, B);
    If (PErr = '') And Not IsSym(';') And Not IsKw('END') And Not IsKw('UNTIL') And Not IsKw('ELSE') And
       (Tk <> tkEof) Then PFail('; attendu');
  End;
End;

{ lit B dans la branche (P, Br) ; un programme complet ou une suite
  d'instructions (presse-papiers) ; rend '' ou le message d'erreur }
Function ParseInto(Var Src : TBuf; P, Br : LongInt) : String;
Begin
  SrcP := Src.P; SrcN := Src.Len; SrcI := 0; SrcLine := 1;
  PErr := ''; PendHas := False; PendTitle := ''; PendOff := False;
  NextTk;
  If IsKw('PROGRAM') Then
  Begin
    NextTk;
    If Tk = tkId Then
    Begin
      If P = 0 Then FlowName := TkS;
      NextTk;
    End;
    Expect(';');
    If IsKw('USES') Then
    Begin
      While (Tk <> tkEof) And Not IsSym(';') Do NextTk;
      Expect(';');
    End;
    Expect('Begin');
    ParseStmts(P, Br);
    Expect('End');
    If PErr = '' Then Expect('.');
  End
  Else If IsKw('BEGIN') And (P = 0) Then
  Begin
    NextTk;
    ParseStmts(P, Br);
    Expect('End');
  End
  Else
  Begin
    ParseStmts(P, Br);
    If (PErr = '') And (Tk <> tkEof) Then PFail('fin attendue');
  End;
  ParseInto := PErr;
End;

{ le flux commence toujours par son declencheur }
Procedure EnsureTrigger;
Var N : LongInt;
Begin
  N := NFirst(0, 0);
  If (N >= 0) And (NKind[N] = kTrigger) Then Exit;
  N := NAlloc(kTrigger);
  If N >= 0 Then NInsert(0, 0, -1, N);
End;

Procedure NewFlow;
Begin
  NReset;
  FlowName := 'NouveauFlux';
  EnsureTrigger;
  Modified := False;
End;
{ ==================================================================== }
{ Variables du flux                                                     }
{ ==================================================================== }

Const
  MaxVar = 64;
  vtStr = 0; vtInt = 1; vtDec = 2; vtBool = 3; vtList = 4;

Var
  NVar : LongInt;
  VName : Array[0..MaxVar - 1] Of String;
  VType : Array[0..MaxVar - 1] Of LongInt;
  VVal : Array[0..MaxVar - 1] Of TBuf;
  EvalErr : String;

Procedure VarsClear;
Var K : LongInt;
Begin
  For K := 0 To NVar - 1 Do BufFree(VVal[K]);
  NVar := 0;
End;

Function FindVar(Name : String) : LongInt;
Var K : LongInt;
Begin
  FindVar := -1;
  Name := UpStr(Trim(Name));
  For K := 0 To NVar - 1 Do
    If UpStr(VName[K]) = Name Then
    Begin
      FindVar := K;
      Exit;
    End;
End;

{ variable (creee au besoin) }
Function VarSlot(Name : String) : LongInt;
Var K : LongInt;
Begin
  K := FindVar(Name);
  If (K < 0) And (NVar < MaxVar) Then
  Begin
    K := NVar;
    Inc(NVar);
    VName[K] := Trim(Name); VType[K] := vtStr;
    BufInit(VVal[K]);
  End;
  VarSlot := K;
End;

Function VarS(K : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If (K >= 0) And (K < NVar) Then
  Begin
    N := MinI(VVal[K].Len, 255);
    S[0] := Chr(N);
    If N > 0 Then Move(VVal[K].P^[0], S[1], N);
  End;
  VarS := S;
End;

Procedure SetVarS(Name, V : String);
Var K : LongInt;
Begin
  K := VarSlot(Name);
  If K < 0 Then Exit;
  VVal[K].Len := 0;
  BufAdd(VVal[K], V);
End;

Procedure SetVarB(Name : String; Var B : TBuf);
Var K : LongInt;
Begin
  K := VarSlot(Name);
  If K < 0 Then Exit;
  VVal[K].Len := 0;
  BufAddB(VVal[K], B.P, B.Len);
End;

{ ==================================================================== }
{ Nombres                                                               }
{ ==================================================================== }

Function IsNum(S : String; Var R : Real) : Boolean;
Var E : LongInt; K : LongInt;
Begin
  IsNum := False;
  S := Trim(S);
  If S = '' Then Exit;
  For K := 1 To Length(S) Do If S[K] = ',' Then S[K] := '.';
  For K := 1 To Length(S) Do
    If Not (((S[K] >= '0') And (S[K] <= '9')) Or (S[K] = '.') Or (((S[K] = '-') Or (S[K] = '+')) And (K = 1))) Then
      Exit;
  Val(S, R, E);
  IsNum := E = 0;
End;

Function NumStr(R : Real) : String;
Var S : String; L : LongInt;
Begin
  If (R > -2000000000.0) And (R < 2000000000.0) And (R = Trunc(R)) Then
  Begin
    L := Trunc(R);
    NumStr := IStr(L);
    Exit;
  End;
  Str(R:0:6, S);
  While (Length(S) > 0) And (S[Length(S)] = '0') Do Delete(S, Length(S), 1);
  If (Length(S) > 0) And (S[Length(S)] = '.') Then Delete(S, Length(S), 1);
  NumStr := S;
End;

Function NumOf(S : String) : Real;
Var R : Real;
Begin
  If Not IsNum(S, R) Then
  Begin
    If EvalErr = '' Then EvalErr := 'nombre attendu : ' + S;
    R := 0;
  End;
  NumOf := R;
End;

Function Truth(S : String) : Boolean;
Begin
  S := LoStr(Trim(S));
  Truth := (S = 'true') Or (S = 'vrai') Or (S = '1') Or (S = 'oui');
End;

Function BoolStr(B : Boolean) : String;
Begin
  If B Then BoolStr := 'true' Else BoolStr := 'false';
End;

{ ==================================================================== }
{ Listes (valeurs separees par ; ou par des fins de ligne)              }
{ ==================================================================== }

Function ListCount(Var B : TBuf) : LongInt;
Var K, N : LongInt; InIt : Boolean;
Begin
  N := 0; InIt := False;
  For K := 0 To B.Len - 1 Do
    If (B.P^[K] = 59) Or (B.P^[K] = 13) Or (B.P^[K] = 10) Then InIt := False
    Else If Not InIt Then
    Begin
      InIt := True;
      Inc(N);
    End;
  ListCount := N;
End;

Function ListItem(Var B : TBuf; I : LongInt) : String;
Var K, N : LongInt; InIt : Boolean; S : String;
Begin
  N := -1; InIt := False; S := '';
  For K := 0 To B.Len - 1 Do
    If (B.P^[K] = 59) Or (B.P^[K] = 13) Or (B.P^[K] = 10) Then
    Begin
      If InIt And (N = I) Then Break;
      InIt := False;
    End
    Else
    Begin
      If Not InIt Then
      Begin
        InIt := True;
        Inc(N);
      End;
      If (N = I) And (Length(S) < 255) Then S := S + Chr(B.P^[K]);
    End;
  ListItem := Trim(S);
End;

Function StrListCount(S : String) : LongInt;
Var B : TBuf;
Begin
  BufInit(B);
  BufAdd(B, S);
  StrListCount := ListCount(B);
  BufFree(B);
End;

Function StrListItem(S : String; I : LongInt) : String;
Var B : TBuf;
Begin
  BufInit(B);
  BufAdd(B, S);
  StrListItem := ListItem(B, I);
  BufFree(B);
End;

{ ==================================================================== }
{ Date et heure                                                         }
{ ==================================================================== }

Function Pad(V, N : LongInt) : String;
Var S : String;
Begin
  S := IStr(V);
  While Length(S) < N Do S := '0' + S;
  Pad := S;
End;

{ AAAA MM JJ hh mm ss dans le format F }
Function FmtDate(F : String) : String;
Var D : Array[0..11] Of Byte; R : String; K : LongInt; Y : LongInt;
Begin
  For K := 0 To 11 Do D[K] := 0;
  Dummy := DosGetDateTime(LongInt(@D));
  Y := D[6] + D[7] * 256;
  If F = '' Then F := 'AAAA-MM-JJ hh:mm:ss';
  R := '';
  K := 1;
  While K <= Length(F) Do
  Begin
    If Copy(F, K, 4) = 'AAAA' Then
    Begin
      R := R + Pad(Y, 4); K := K + 4;
    End
    Else If Copy(F, K, 2) = 'MM' Then
    Begin
      R := R + Pad(D[5], 2); K := K + 2;
    End
    Else If Copy(F, K, 2) = 'JJ' Then
    Begin
      R := R + Pad(D[4], 2); K := K + 2;
    End
    Else If Copy(F, K, 2) = 'hh' Then
    Begin
      R := R + Pad(D[0], 2); K := K + 2;
    End
    Else If Copy(F, K, 2) = 'mm' Then
    Begin
      R := R + Pad(D[1], 2); K := K + 2;
    End
    Else If Copy(F, K, 2) = 'ss' Then
    Begin
      R := R + Pad(D[2], 2); K := K + 2;
    End
    Else
    Begin
      R := R + F[K]; Inc(K);
    End;
  End;
  FmtDate := R;
End;

{ ==================================================================== }
{ Expressions : arobase-accolade dans les valeurs                       }
{ ==================================================================== }

Var
  ExS : String;
  ExI : LongInt;

Function ExC : Char;
Begin
  If ExI <= Length(ExS) Then ExC := ExS[ExI] Else ExC := #0;
End;

Procedure ExSkip;
Begin
  While (ExI <= Length(ExS)) And (ExS[ExI] <= ' ') Do Inc(ExI);
End;

Function ExIsAl(C : Char) : Boolean;
Begin
  ExIsAl := ((C >= 'A') And (C <= 'Z')) Or ((C >= 'a') And (C <= 'z')) Or (C = '_') Or (C >= #128);
End;

{ mot-cle (and, or, not, mod) a la position courante ? }
Function ExWord(W : String) : Boolean;
Var L : LongInt;
Begin
  ExSkip;
  L := Length(W);
  ExWord := False;
  If LoStr(Copy(ExS, ExI, L)) <> W Then Exit;
  If ExIsAl(ExC) And (ExI + L <= Length(ExS)) And (ExIsAl(ExS[ExI + L]) Or ((ExS[ExI + L] >= '0') And
     (ExS[ExI + L] <= '9'))) Then Exit;
  ExI := ExI + L;
  ExWord := True;
End;

Function ExSym(W : String) : Boolean;
Begin
  ExSkip;
  ExSym := False;
  If Copy(ExS, ExI, Length(W)) <> W Then Exit;
  ExI := ExI + Length(W);
  ExSym := True;
End;

Function EOr : String; Forward;

Function ECompare(A, B : String) : LongInt;
Var Ra, Rb : Real;
Begin
  If IsNum(A, Ra) And IsNum(B, Rb) Then
  Begin
    If Ra < Rb Then ECompare := -1 Else If Ra > Rb Then ECompare := 1 Else ECompare := 0;
  End
  Else If A < B Then ECompare := -1
  Else If A > B Then ECompare := 1
  Else ECompare := 0;
End;

Type
  TArgs = Array[0..5] Of String;

Var
  RndSeed : LongInt;

Function Rnd(N : LongInt) : LongInt;
Begin
  RndSeed := RndSeed * 1103515245 + 12345;
  If N <= 0 Then Rnd := 0 Else Rnd := ((RndSeed Shr 8) And $7FFFFF) Mod N;
End;

Function ECall(F : String; N : LongInt; Var A : TArgs) : String;
Var R : String; K, I, J : LongInt; X : Real;
Begin
  R := '';
  F := LoStr(F);
  If (F = 'concat') Then
  Begin
    For K := 0 To N - 1 Do R := R + A[K];
  End
  Else If (F = 'length') Or (F = 'len') Then R := IStr(Length(A[0]))
  Else If (F = 'toupper') Or (F = 'majuscules') Then R := UpStr(A[0])
  Else If (F = 'tolower') Or (F = 'minuscules') Then R := LoStr(A[0])
  Else If F = 'trim' Then R := Trim(A[0])
  Else If F = 'substring' Then
  Begin
    I := Trunc(NumOf(A[1]));
    If N > 2 Then J := Trunc(NumOf(A[2])) Else J := 255;
    If I < 0 Then I := 0;
    R := Copy(A[0], I + 1, J);
  End
  Else If F = 'replace' Then
  Begin
    R := '';
    K := 1;
    If A[1] = '' Then R := A[0]
    Else
      While K <= Length(A[0]) Do
        If Copy(A[0], K, Length(A[1])) = A[1] Then
        Begin
          R := R + A[2];
          K := K + Length(A[1]);
        End
        Else
        Begin
          R := R + A[0][K];
          Inc(K);
        End;
  End
  Else If F = 'indexof' Then R := IStr(Pos(LoStr(A[1]), LoStr(A[0])) - 1)
  Else If F = 'contains' Then R := BoolStr(Pos(LoStr(A[1]), LoStr(A[0])) > 0)
  Else If F = 'startswith' Then R := BoolStr(LoStr(Copy(A[0], 1, Length(A[1]))) = LoStr(A[1]))
  Else If F = 'endswith' Then
    R := BoolStr((Length(A[0]) >= Length(A[1])) And (LoStr(Copy(A[0], Length(A[0]) - Length(A[1]) + 1, 255)) =
                  LoStr(A[1])))
  Else If F = 'add' Then R := NumStr(NumOf(A[0]) + NumOf(A[1]))
  Else If F = 'sub' Then R := NumStr(NumOf(A[0]) - NumOf(A[1]))
  Else If F = 'mul' Then R := NumStr(NumOf(A[0]) * NumOf(A[1]))
  Else If (F = 'div') Or (F = 'mod') Then
  Begin
    X := NumOf(A[1]);
    If X = 0 Then
    Begin
      If EvalErr = '' Then EvalErr := 'division par z'#130'ro';
    End
    Else If F = 'div' Then R := NumStr(NumOf(A[0]) / X)
    Else R := IStr(Trunc(NumOf(A[0])) Mod Trunc(X));
  End
  Else If F = 'min' Then
  Begin
    If NumOf(A[0]) < NumOf(A[1]) Then R := A[0] Else R := A[1];
  End
  Else If F = 'max' Then
  Begin
    If NumOf(A[0]) > NumOf(A[1]) Then R := A[0] Else R := A[1];
  End
  Else If F = 'int' Then R := IStr(Trunc(NumOf(A[0])))
  Else If (F = 'float') Or (F = 'string') Then R := A[0]
  Else If F = 'if' Then
  Begin
    If Truth(A[0]) Then R := A[1] Else R := A[2];
  End
  Else If F = 'equals' Then R := BoolStr(A[0] = A[1])
  Else If F = 'not' Then R := BoolStr(Not Truth(A[0]))
  Else If F = 'and' Then R := BoolStr(Truth(A[0]) And Truth(A[1]))
  Else If F = 'or' Then R := BoolStr(Truth(A[0]) Or Truth(A[1]))
  Else If F = 'empty' Then R := BoolStr(Trim(A[0]) = '')
  Else If (F = 'utcnow') Or (F = 'now') Then
  Begin
    If N > 0 Then R := FmtDate(A[0]) Else R := FmtDate('');
  End
  Else If F = 'count' Then R := IStr(StrListCount(A[0]))
  Else If F = 'item' Then R := StrListItem(A[0], Trunc(NumOf(A[1])))
  Else If F = 'first' Then R := StrListItem(A[0], 0)
  Else If F = 'last' Then R := StrListItem(A[0], StrListCount(A[0]) - 1)
  Else If F = 'rand' Then
  Begin
    I := Trunc(NumOf(A[0])); J := Trunc(NumOf(A[1]));
    If J > I Then R := IStr(I + Rnd(J - I)) Else R := IStr(I);
  End
  Else If (F = 'variables') Or (F = 'variable') Then R := VarS(FindVar(A[0]))
  Else If EvalErr = '' Then EvalErr := 'fonction inconnue : ' + F;
  ECall := R;
End;

Function EPrimary : String;
Var R, Nm : String; Q : Char; N : LongInt; A : TArgs; K : LongInt;
Begin
  R := '';
  ExSkip;
  Q := ExC;
  If (Q = '''') Or (Q = '"') Then
  Begin
    Inc(ExI);
    While ExI <= Length(ExS) Do
    Begin
      If ExS[ExI] = Q Then
      Begin
        If (ExI < Length(ExS)) And (ExS[ExI + 1] = Q) Then
        Begin
          R := R + Q;
          ExI := ExI + 2;
          Continue;
        End;
        Inc(ExI);
        Break;
      End;
      R := R + ExS[ExI];
      Inc(ExI);
    End;
  End
  Else If ((Q >= '0') And (Q <= '9')) Or (Q = '.') Then
  Begin
    While (ExI <= Length(ExS)) And (((ExS[ExI] >= '0') And (ExS[ExI] <= '9')) Or (ExS[ExI] = '.')) Do
    Begin
      R := R + ExS[ExI];
      Inc(ExI);
    End;
  End
  Else If Q = '(' Then
  Begin
    Inc(ExI);
    R := EOr;
    If Not ExSym(')') And (EvalErr = '') Then EvalErr := ') attendue';
  End
  Else If ExIsAl(Q) Then
  Begin
    Nm := '';
    While (ExI <= Length(ExS)) And (ExIsAl(ExS[ExI]) Or ((ExS[ExI] >= '0') And (ExS[ExI] <= '9'))) Do
    Begin
      Nm := Nm + ExS[ExI];
      Inc(ExI);
    End;
    ExSkip;
    If ExC = '(' Then
    Begin
      Inc(ExI);
      N := 0;
      For K := 0 To 5 Do A[K] := '';
      ExSkip;
      If ExC = ')' Then Inc(ExI)
      Else
      Begin
        Repeat
          If N < 6 Then A[N] := EOr Else Dummy := Length(EOr);
          Inc(N);
          If ExSym(',') Then Continue;
          If Not ExSym(')') And (EvalErr = '') Then EvalErr := ') attendue apr'#138's ' + Nm;
          Break;
        Until EvalErr <> '';
      End;
      R := ECall(Nm, N, A);
    End
    Else If (LoStr(Nm) = 'true') Or (LoStr(Nm) = 'false') Then R := LoStr(Nm)
    Else If FindVar(Nm) >= 0 Then R := VarS(FindVar(Nm))
    Else If EvalErr = '' Then EvalErr := 'variable inconnue : ' + Nm;
  End
  Else If EvalErr = '' Then
  Begin
    If Q = #0 Then EvalErr := 'expression incompl'#138'te' Else EvalErr := 'caract'#138're inattendu : ' + Q;
  End;
  EPrimary := R;
End;

Function EUnary : String;
Begin
  If ExSym('-') Then EUnary := NumStr(-NumOf(EUnary))
  Else If ExWord('not') Then EUnary := BoolStr(Not Truth(EUnary))
  Else EUnary := EPrimary;
End;

Function EMul : String;
Var A, B : String; X : Real;
Begin
  A := EUnary;
  While EvalErr = '' Do
  Begin
    If ExSym('*') Then A := NumStr(NumOf(A) * NumOf(EUnary))
    Else If ExSym('/') Then
    Begin
      B := EUnary;
      X := NumOf(B);
      If X = 0 Then EvalErr := 'division par z'#130'ro' Else A := NumStr(NumOf(A) / X);
    End
    Else If ExWord('mod') Then
    Begin
      B := EUnary;
      If Trunc(NumOf(B)) = 0 Then EvalErr := 'division par z'#130'ro'
      Else A := IStr(Trunc(NumOf(A)) Mod Trunc(NumOf(B)));
    End
    Else Break;
  End;
  EMul := A;
End;

Function EAdd : String;
Var A, B : String; Ra, Rb : Real;
Begin
  A := EMul;
  While EvalErr = '' Do
  Begin
    If ExSym('+') Then
    Begin
      B := EMul;
      If IsNum(A, Ra) And IsNum(B, Rb) Then A := NumStr(Ra + Rb) Else A := A + B;
    End
    Else If ExSym('-') Then A := NumStr(NumOf(A) - NumOf(EMul))
    Else If ExSym('&') Then A := A + EMul
    Else Break;
  End;
  EAdd := A;
End;

Function ECmp : String;
Var A, B : String;
Begin
  A := EAdd;
  If EvalErr <> '' Then
  Begin
    ECmp := A;
    Exit;
  End;
  If ExSym('<=') Then A := BoolStr(ECompare(A, EAdd) <= 0)
  Else If ExSym('>=') Then A := BoolStr(ECompare(A, EAdd) >= 0)
  Else If ExSym('<>') Then A := BoolStr(ECompare(A, EAdd) <> 0)
  Else If ExSym('<') Then A := BoolStr(ECompare(A, EAdd) < 0)
  Else If ExSym('>') Then A := BoolStr(ECompare(A, EAdd) > 0)
  Else If ExSym('=') Then
  Begin
    B := EAdd;
    A := BoolStr(ECompare(A, B) = 0);
  End;
  ECmp := A;
End;

Function EAnd : String;
Var A : String;
Begin
  A := ECmp;
  While (EvalErr = '') And ExWord('and') Do A := BoolStr(Truth(A) And Truth(ECmp));
  EAnd := A;
End;

Function EOr : String;
Var A : String;
Begin
  A := EAnd;
  While (EvalErr = '') And ExWord('or') Do A := BoolStr(Truth(A) Or Truth(EAnd));
  EOr := A;
End;

{ valeur d'une expression ; EvalErr si elle est fausse }
Function Eval(S : String) : String;
Var SvS : String; SvI : LongInt; R : String;
Begin
  SvS := ExS; SvI := ExI;
  ExS := S; ExI := 1;
  R := EOr;
  ExSkip;
  If (EvalErr = '') And (ExI <= Length(ExS)) Then EvalErr := 'reste inattendu : ' + Copy(ExS, ExI, 30);
  ExS := SvS; ExI := SvI;
  Eval := R;
End;

{ texte avec ses expressions (arobase-accolade) remplacees, dans B }
Procedure InterpB(S : String; Var B : TBuf);
Var K, J, D, V : LongInt; E : String; Q : Char;
Begin
  K := 1;
  While K <= Length(S) Do
  Begin
    If (S[K] = '@') And (K < Length(S)) And (S[K + 1] = '{') Then
    Begin
      { fin de l'expression : l'accolade fermante hors des chaines }
      J := K + 2; D := 1; Q := #0;
      While J <= Length(S) Do
      Begin
        If Q <> #0 Then
        Begin
          If S[J] = Q Then Q := #0;
        End
        Else If (S[J] = '''') Or (S[J] = '"') Then Q := S[J]
        Else If S[J] = '{' Then Inc(D)
        Else If S[J] = '}' Then
        Begin
          Dec(D);
          If D = 0 Then Break;
        End;
        Inc(J);
      End;
      E := Trim(Copy(S, K + 2, J - K - 2));
      V := -1;
      If IsIdent(E) Then V := FindVar(E);
      If V >= 0 Then BufAddB(B, VVal[V].P, VVal[V].Len)
      Else BufAdd(B, Eval(E));
      K := J + 1;
    End
    Else
    Begin
      BufAddC(B, Ord(S[K]));
      Inc(K);
    End;
  End;
End;

Function Interp(S : String) : String;
Var B : TBuf; R : String; N : LongInt;
Begin
  BufInit(B);
  InterpB(S, B);
  N := MinI(B.Len, 255);
  R[0] := Chr(N);
  If N > 0 Then Move(B.P^[0], R[1], N);
  BufFree(B);
  Interp := R;
End;

{ comparaison d'une Condition }
Function CondTrue(A, Op, B : String) : Boolean;
Var C : LongInt; La, Lb : String;
Begin
  La := LoStr(A); Lb := LoStr(B);
  C := ECompare(A, B);
  If Op = '=' Then CondTrue := C = 0
  Else If Op = '<>' Then CondTrue := C <> 0
  Else If Op = '>' Then CondTrue := C > 0
  Else If Op = '>=' Then CondTrue := C >= 0
  Else If Op = '<' Then CondTrue := C < 0
  Else If Op = '<=' Then CondTrue := C <= 0
  Else If Op = 'contient' Then CondTrue := Pos(Lb, La) > 0
  Else If Op = 'ne contient pas' Then CondTrue := Pos(Lb, La) = 0
  Else If Op = 'commence par' Then CondTrue := Copy(La, 1, Length(Lb)) = Lb
  Else If Op = 'finit par' Then CondTrue := (Length(La) >= Length(Lb)) And (Copy(La, Length(La) - Length(Lb) + 1, 255) = Lb)
  Else If Op = 'est vide' Then CondTrue := Trim(A) = ''
  Else If Op = 'n''est pas vide' Then CondTrue := Trim(A) <> ''
  Else
  Begin
    If EvalErr = '' Then EvalErr := 'op'#130'rateur inconnu : ' + Op;
    CondTrue := False;
  End;
End;
{ ==================================================================== }
{ Fichiers                                                              }
{ ==================================================================== }

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

{ ajouter a la fin d'un fichier (cree au besoin) }
Function AppendAll(Name : String; P : PBytes; N : LongInt) : Boolean;
Var H, A, Np : LongInt;
Begin
  AppendAll := False;
  H := 0; A := 0;
  If DosOpen(Z(Name), LongInt(@H), LongInt(@A), 0, 0, $11, $41, 0) <> 0 Then Exit;
  Np := 0;
  Dummy := DosSetFilePtr(H, 0, 2, LongInt(@Np));
  AppendAll := (N = 0) Or (FWrite(H, P, N) = N);
  DosClose(H);
End;

Var
  FindBf : Array[0..511] Of Byte;

{ noms des fichiers d'un motif, separes par ; }
Function ListNames(Spec : String; Var B : TBuf) : LongInt;
Var H, N, C, K, L, Attr : LongInt; S : String;
Begin
  ListNames := -1;
  B.Len := 0;
  H := -1; N := 1; C := 0;
  If DosFindFirst(Z(Spec), LongInt(@H), $27, LongInt(@FindBf), SizeOf(FindBf), LongInt(@N), 1) <> 0 Then
  Begin
    ListNames := 0;
    Exit;
  End;
  Repeat
    Attr := FindBf[24];
    L := FindBf[28];
    S := '';
    For K := 1 To L Do S := S + Chr(FindBf[28 + K]);
    If (S <> '.') And (S <> '..') And ((Attr And $10) = 0) Then
    Begin
      If C > 0 Then BufAddC(B, 59);
      BufAdd(B, S);
      Inc(C);
    End;
    N := 1;
  Until DosFindNext(H, LongInt(@FindBf), SizeOf(FindBf), LongInt(@N)) <> 0;
  Dummy := DosFindClose(H);
  ListNames := C;
End;

{ lancer un programme ; Wait : attendre sa fin ; rend le code de DosExecPgm }
Function RunPgm(Exe, Arg : String; Wait : Boolean; Var Code : LongInt) : LongInt;
Var Args : Array[0..1023] Of Byte; Res : Array[0..1] Of LongInt; Fail : Array[0..259] Of Byte; P, K, Fl : LongInt;
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
  Res[0] := 0; Res[1] := 0;
  If Wait Then Fl := 0 Else Fl := 1;
  RunPgm := DosExecPgm(LongInt(@Fail), 260, Fl, LongInt(@Args), 0, LongInt(@Res), Z(Exe));
  Code := Res[1];
End;

{ ==================================================================== }
{ Execution d'un flux                                                   }
{ ==================================================================== }

Const
  MaxFr = 40;
  rsIdle = 0; rsRun = 1; rsWait = 2;

Var
  RunState, RunNode, RunT0, RunSteps, RunWaitUntil, RunWaitNode : LongInt;
  RunTest, RunOk, AutoMode, RunBusy, StopAsked : Boolean;
  RunSummary : String;
  RunLog : TBuf;
  Sp : LongInt;
  FrNode, FrBr, FrCur, FrIter, FrPos : Array[0..MaxFr - 1] Of LongInt;
  FrItems : Array[0..MaxFr - 1] Of TBuf;

{ fournies par l'interface }
Function RunAsk(Q, Def : String; Var V : String) : Boolean; Forward;
Procedure RunShow(Title : String; Var Text : TBuf); Forward;
Procedure RunChanged; Forward;

Procedure LogLine(S : String);
Begin
  BufAdd(RunLog, FmtDate('hh:mm:ss') + '  ' + S);
  BufAddC(RunLog, 13); BufAddC(RunLog, 10);
End;

Function StName(St : LongInt) : String;
Begin
  Case St Of
    stOk : StName := 'r'#130'ussie';
    stFail : StName := #130'chec';
    stSkip : StName := 'ignor'#130'e (d'#130'sactiv'#130'e)';
    stRun : StName := 'en cours';
  Else
    StName := 'non ex'#130'cut'#130'e';
  End;
End;

Function Secs(T : LongInt) : String;
Var S : String;
Begin
  S := IStr(T Div 1000) + ',' + IStr((T Mod 1000) Div 100) + ' s';
  Secs := S;
End;

Procedure FinishRun(Ok : Boolean; S : String);
Var K : LongInt;
Begin
  RunState := rsIdle;
  RunOk := Ok;
  RunNode := -1;
  For K := 0 To MaxFr - 1 Do FrItems[K].Len := 0;
  If S = '' Then
  Begin
    If Ok Then S := 'Le flux a r'#130'ussi' Else S := 'Le flux a '#130'chou'#130;
  End;
  RunSummary := S + ' (' + IStr(RunSteps) + ' '#130'tape(s), ' + Secs(PTicks - RunT0) + ').';
  LogLine(RunSummary);
  RunChanged;
End;

{ echec de N : X rouge sur l'action et sur les actions qui la contiennent }
Procedure FailAt(N : LongInt; S : String);
Var F : LongInt;
Begin
  If N > 0 Then
  Begin
    NSt[N] := stFail;
    NOut[N] := S;
    LogLine('X ' + NTitle[N] + ' : ' + S);
  End;
  For F := Sp DownTo 1 Do
    If (FrNode[F] > 0) And (NSt[FrNode[F]] <> stFail) Then
    Begin
      NSt[FrNode[F]] := stFail;
      NOut[FrNode[F]] := 'Une action contenue a '#130'chou'#130'.';
    End;
  FinishRun(False, 'Le flux a '#130'chou'#130' : ' + NTitle[N]);
End;

Procedure OkAt(N : LongInt; S : String);
Begin
  NSt[N] := stOk;
  NOut[N] := S;
  If S <> '' Then LogLine('v ' + NTitle[N] + ' : ' + S) Else LogLine('v ' + NTitle[N]);
End;

Procedure PushFr(N, B, Cur : LongInt);
Begin
  If Sp >= MaxFr - 1 Then
  Begin
    FailAt(N, 'trop de niveaux imbriqu'#130's.');
    Exit;
  End;
  Inc(Sp);
  FrNode[Sp] := N; FrBr[Sp] := B; FrCur[Sp] := Cur; FrIter[Sp] := 0; FrPos[Sp] := 0;
  FrItems[Sp].Len := 0;
End;

Procedure StartRun(Test : Boolean);
Begin
  ClearRun;
  VarsClear;
  RunLog.Len := 0;
  RunTest := Test;
  RunSteps := 0; RunT0 := PTicks; RunOk := False; StopAsked := False;
  If Test Then LogLine('Test du flux ' + FlowName) Else LogLine('Ex'#130'cution du flux ' + FlowName);
  Sp := 0;
  FrNode[0] := 0; FrBr[0] := 0; FrCur[0] := NFirst(0, 0); FrIter[0] := 0;
  RunState := rsRun;
  RunNode := -1;
  RunSummary := 'Ex'#130'cution...';
  RunChanged;
End;

Procedure StopRun;
Begin
  If RunState = rsIdle Then Exit;
  If (RunNode > 0) Then FailAt(RunNode, 'Arr'#136't'#130' par l''utilisateur.')
  Else FinishRun(False, 'Ex'#130'cution arr'#136't'#130'e');
End;

{ valeur d'un parametre, ses expressions calculees }
Function PVal(N, I : LongInt) : String;
Begin
  PVal := Interp(PGet(N, I));
End;

Function VarExists(N : LongInt; Name : String) : LongInt;
Var K : LongInt;
Begin
  K := FindVar(Name);
  If K < 0 Then FailAt(N, 'variable inconnue : ' + Name + ' (Initialiser une variable d''abord).');
  VarExists := K;
End;

{ une action simple ; faux si elle echoue (FailAt deja appele) }
Function ExecAction(N : LongInt) : Boolean;
Var S, T, Nm, Op : String; B : TBuf; K, V, Rc, Code : LongInt; R : Real; Ok : Boolean;
Begin
  ExecAction := False;
  EvalErr := '';
  BufInit(B);
  Case NKind[N] Of
    kTrigger :
      Begin
        T := '';
        For K := 0 To 2 Do
        Begin
          Nm := Trim(PGet(N, K));
          If Nm = '' Then Continue;
          S := '';
          If Not AutoMode Then
            If Not RunAsk('Valeur de l''entr'#130'e ' + Nm + ' :', '', S) Then
            Begin
              FailAt(N, 'Ex'#130'cution annul'#130'e.');
              Exit;
            End;
          SetVarS(Nm, S);
          T := T + ', ' + Nm + ' = ' + S;
        End;
        OkAt(N, 'D'#130'clench'#130' manuellement '#133' ' + FmtDate('hh:mm:ss') + T);
      End;
    kInitVar :
      Begin
        Nm := Trim(PGet(N, 0));
        If Nm = '' Then
        Begin
          FailAt(N, 'nom de variable vide.');
          Exit;
        End;
        If FindVar(Nm) >= 0 Then
        Begin
          FailAt(N, 'la variable ' + Nm + ' existe d'#130'j'#133'.');
          Exit;
        End;
        T := LoStr(PGet(N, 1));
        InterpB(PGet(N, 2), B);
        If EvalErr = '' Then
        Begin
          K := VarSlot(Nm);
          If K < 0 Then
          Begin
            FailAt(N, 'trop de variables (' + IStr(MaxVar) + ' au plus).');
            BufFree(B);
            Exit;
          End;
          VType[K] := vtStr;
          VVal[K].Len := 0;
          BufAddB(VVal[K], B.P, B.Len);
          S := VarS(K);
          If T = 'entier' Then
          Begin
            VType[K] := vtInt;
            If Trim(S) = '' Then S := '0';
            If Not IsNum(S, R) Then EvalErr := 'entier attendu : ' + S Else SetVarS(Nm, IStr(Trunc(R)));
          End
          Else If T = 'd'#130'cimal' Then
          Begin
            VType[K] := vtDec;
            If Trim(S) = '' Then S := '0';
            If Not IsNum(S, R) Then EvalErr := 'nombre attendu : ' + S Else SetVarS(Nm, NumStr(R));
          End
          Else If T = 'bool'#130'en' Then
          Begin
            VType[K] := vtBool;
            SetVarS(Nm, BoolStr(Truth(S)));
          End
          Else If T = 'liste' Then VType[K] := vtList;
        End;
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          BufFree(B);
          Exit;
        End;
        OkAt(N, Nm + ' = ' + VarS(FindVar(Nm)));
      End;
    kSetVar, kAppend :
      Begin
        Nm := Trim(PGet(N, 0));
        K := VarExists(N, Nm);
        If K < 0 Then Exit;
        InterpB(PGet(N, 1), B);
        If EvalErr = '' Then
        Begin
          If NKind[N] = kSetVar Then VVal[K].Len := 0
          Else If (VType[K] = vtList) And (VVal[K].Len > 0) And (B.Len > 0) Then BufAddC(VVal[K], 59);
          BufAddB(VVal[K], B.P, B.Len);
          If VType[K] = vtInt Then
          Begin
            If Not IsNum(VarS(K), R) Then EvalErr := 'entier attendu : ' + VarS(K);
          End;
        End;
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          BufFree(B);
          Exit;
        End;
        OkAt(N, Nm + ' = ' + Copy(VarS(K), 1, 80));
      End;
    kIncVar, kDecVar :
      Begin
        Nm := Trim(PGet(N, 0));
        K := VarExists(N, Nm);
        If K < 0 Then Exit;
        S := PVal(N, 1);
        If Trim(S) = '' Then S := '1';
        If EvalErr = '' Then
        Begin
          If NKind[N] = kIncVar Then R := NumOf(VarS(K)) + NumOf(S) Else R := NumOf(VarS(K)) - NumOf(S);
        End;
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        SetVarS(Nm, NumStr(R));
        OkAt(N, Nm + ' = ' + VarS(K));
      End;
    kCompose :
      Begin
        InterpB(PGet(N, 0), B);
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          BufFree(B);
          Exit;
        End;
        Nm := Trim(PGet(N, 1));
        If Nm = '' Then Nm := 'Sortie';
        SetVarB(Nm, B);
        OkAt(N, Nm + ' = ' + Copy(VarS(FindVar(Nm)), 1, 80));
      End;
    kWait :
      Begin
        S := PVal(N, 0);
        If EvalErr = '' Then R := NumOf(S);
        If (EvalErr <> '') Or (R < 0) Or (R > 3600) Then
        Begin
          If EvalErr = '' Then EvalErr := 'dur'#130'e entre 0 et 3600 secondes.';
          FailAt(N, EvalErr);
          Exit;
        End;
        RunWaitUntil := PTicks + Trunc(R * 1000);
        RunWaitNode := N;
        NSt[N] := stRun;
        NOut[N] := 'Attente de ' + NumStr(R) + ' s...';
        RunState := rsWait;
      End;
    kTerminate :
      Begin
        S := PVal(N, 1);
        T := PGet(N, 0);
        If (T = 'R'#130'ussi') Or (T = '') Then
        Begin
          OkAt(N, 'Flux termin'#130' : r'#130'ussi. ' + S);
          FinishRun(True, 'Le flux s''est termin'#130' (r'#130'ussi)');
        End
        Else
        Begin
          If T = 'Annul'#130 Then T := 'annul'#130 Else T := #130'chec';
          NSt[N] := stFail;
          NOut[N] := 'Flux termin'#130' : ' + T + '. ' + S;
          LogLine('X ' + NTitle[N] + ' : ' + NOut[N]);
          For K := Sp DownTo 1 Do If FrNode[K] > 0 Then NSt[FrNode[K]] := stFail;
          FinishRun(False, 'Le flux s''est termin'#130' (' + T + ')');
        End;
        BufFree(B);
        Exit;
      End;
    kReadFile :
      Begin
        S := Trim(PVal(N, 0));
        Nm := Trim(PGet(N, 1));
        If Nm = '' Then Nm := 'Contenu';
        If (EvalErr = '') And Not ReadAll(S, B) Then EvalErr := 'fichier introuvable : ' + S;
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          BufFree(B);
          Exit;
        End;
        SetVarB(Nm, B);
        OkAt(N, IStr(B.Len) + ' octet(s) lu(s) dans ' + Nm);
      End;
    kWriteFile :
      Begin
        S := Trim(PVal(N, 0));
        InterpB(PGet(N, 1), B);
        If EvalErr = '' Then
        Begin
          If PGet(N, 2) = 'Ajouter' Then Ok := AppendAll(S, B.P, B.Len) Else Ok := WriteAll(S, B.P, B.Len);
          If Not Ok Then EvalErr := 'impossible d'''#130'crire ' + S;
        End;
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          BufFree(B);
          Exit;
        End;
        OkAt(N, IStr(B.Len) + ' octet(s) '#130'crit(s) dans ' + S);
      End;
    kCopyFile :
      Begin
        S := Trim(PVal(N, 0)); T := Trim(PVal(N, 1));
        If EvalErr = '' Then
        Begin
          Rc := DosCopy(Z(S), Z2(T), 1);
          If Rc <> 0 Then EvalErr := 'copie impossible (code ' + IStr(Rc) + ') : ' + S;
        End;
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        OkAt(N, S + ' copi'#130' vers ' + T);
      End;
    kDelFile :
      Begin
        S := Trim(PVal(N, 0));
        If EvalErr = '' Then
        Begin
          Rc := DosDelete(Z(S));
          If Rc <> 0 Then EvalErr := 'suppression impossible (code ' + IStr(Rc) + ') : ' + S;
        End;
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        OkAt(N, S + ' supprim'#130);
      End;
    kMkDir :
      Begin
        S := Trim(PVal(N, 0));
        If EvalErr = '' Then
        Begin
          Rc := DosCreateDir(Z(S), 0);
          If (Rc <> 0) And Not FExists(S) Then EvalErr := 'cr'#130'ation impossible (code ' + IStr(Rc) + ') : ' + S;
        End;
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        If Rc = 0 Then OkAt(N, S + ' cr'#130#130) Else OkAt(N, S + ' existe d'#130'j'#133);
      End;
    kListFiles :
      Begin
        S := Trim(PVal(N, 0)); T := Trim(PVal(N, 1));
        Nm := Trim(PGet(N, 2));
        If Nm = '' Then Nm := 'Fichiers';
        If T = '' Then T := '*.*';
        If (S <> '') And (S[Length(S)] <> '\') Then S := S + '\';
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        V := ListNames(S + T, B);
        K := VarSlot(Nm);
        If K >= 0 Then
        Begin
          VType[K] := vtList;
          SetVarB(Nm, B);
        End;
        OkAt(N, IStr(V) + ' fichier(s) dans ' + Nm);
      End;
    kMessage :
      Begin
        S := PVal(N, 0);
        InterpB(PGet(N, 1), B);
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          BufFree(B);
          Exit;
        End;
        If AutoMode Then
        Begin
          BufAddC(B, 0);
          LogLine('Message : ' + Interp(PGet(N, 1)));
        End
        Else RunShow(S, B);
        OkAt(N, 'Message affich'#130);
      End;
    kAsk :
      Begin
        S := PVal(N, 0); T := PVal(N, 2);
        Nm := Trim(PGet(N, 1));
        If Nm = '' Then Nm := 'Reponse';
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        If Not AutoMode Then
          If Not RunAsk(S, T, T) Then
          Begin
            FailAt(N, 'Annul'#130' par l''utilisateur.');
            Exit;
          End;
        SetVarS(Nm, T);
        OkAt(N, Nm + ' = ' + T);
      End;
    kLog :
      Begin
        S := PVal(N, 0);
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        LogLine('Journal : ' + S);
        NSt[N] := stOk; NOut[N] := S;
      End;
    kRun :
      Begin
        S := Trim(PVal(N, 0)); T := PVal(N, 1);
        If EvalErr = '' Then
        Begin
          If (Pos('\', S) = 0) And (Pos(':', S) = 0) And Not FExists(S) And FExists('C:\' + S) Then S := 'C:\' + S;
          If (ExtOf(S) = '') And FExists(S + '.EXE') Then S := S + '.EXE';
          Code := 0;
          Rc := RunPgm(S, T, PGet(N, 2) <> 'Non', Code);
          If Rc <> 0 Then EvalErr := 'programme introuvable ou invalide (code ' + IStr(Rc) + ') : ' + S;
        End;
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        If PGet(N, 2) <> 'Non' Then OkAt(N, NameOf(S) + ' termin'#130', code de retour ' + IStr(Code))
        Else OkAt(N, NameOf(S) + ' lanc'#130);
      End;
    kDateTime :
      Begin
        Nm := Trim(PGet(N, 0));
        If Nm = '' Then Nm := 'Maintenant';
        S := FmtDate(PVal(N, 1));
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        SetVarS(Nm, S);
        OkAt(N, Nm + ' = ' + S);
      End;
  End;
  BufFree(B);
  ExecAction := True;
End;

{ fin d'une liste d'actions : celle du flux, d'une branche ou d'un tour de boucle }
Procedure EndOfList;
Var N : LongInt; S : String; Lim : LongInt;
Begin
  N := FrNode[Sp];
  If N = 0 Then
  Begin
    Dec(Sp);
    FinishRun(True, '');
    Exit;
  End;
  Case NKind[N] Of
    kForEach :
      If FrPos[Sp] < ListCount(FrItems[Sp]) Then
      Begin
        S := ListItem(FrItems[Sp], FrPos[Sp]);
        SetVarS(Trim(PGet(N, 1)), S);
        Inc(FrPos[Sp]);
        FrCur[Sp] := NFirst(N, 0);
        Exit;
      End
      Else
      Begin
        Dec(Sp);
        OkAt(N, IStr(FrPos[Sp + 1]) + ' '#130'l'#130'ment(s) trait'#130'(s)');
      End;
    kUntil :
      Begin
        EvalErr := '';
        If CondTrue(PVal(N, 0), PGet(N, 1), PVal(N, 2)) Then
        Begin
          Dec(Sp);
          OkAt(N, 'Condition atteinte apr'#138's ' + IStr(FrIter[Sp + 1]) + ' tour(s)');
          Exit;
        End;
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        Lim := SVal(Trim(PGet(N, 3)));
        If Lim <= 0 Then Lim := 60;
        If FrIter[Sp] >= Lim Then
        Begin
          Dec(Sp);
          OkAt(N, 'Limite de ' + IStr(Lim) + ' tour(s) atteinte');
          Exit;
        End;
        Inc(FrIter[Sp]);
        FrCur[Sp] := NFirst(N, 0);
      End;
  Else
    Dec(Sp);
  End;
End;

{ une etape : une action, ou la fin d'une liste }
Procedure StepRun;
Var N : LongInt; B : Boolean; S : String;
Begin
  If RunState = rsWait Then
  Begin
    If StopAsked Then
    Begin
      StopRun;
      Exit;
    End;
    If PTicks < RunWaitUntil Then Exit;
    RunState := rsRun;
    OkAt(RunWaitNode, 'Attente termin'#130'e');
    Exit;
  End;
  If RunState <> rsRun Then Exit;
  If Sp < 0 Then
  Begin
    FinishRun(True, '');
    Exit;
  End;
  If FrCur[Sp] < 0 Then
  Begin
    EndOfList;
    Exit;
  End;
  N := FrCur[Sp];
  FrCur[Sp] := NNext[N];
  RunNode := N;
  If NOff[N] Then
  Begin
    NSt[N] := stSkip;
    NOut[N] := 'Action d'#130'sactiv'#130'e : ignor'#130'e.';
    Exit;
  End;
  Inc(RunSteps);
  EvalErr := '';
  Case NKind[N] Of
    kCond :
      Begin
        B := CondTrue(PVal(N, 0), PGet(N, 1), PVal(N, 2));
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        If B Then OkAt(N, 'Vrai : branche Vrai') Else OkAt(N, 'Faux : branche Faux');
        If B Then PushFr(N, 0, NFirst(N, 0)) Else PushFr(N, 1, NFirst(N, 1));
      End;
    kForEach :
      Begin
        S := Trim(PGet(N, 1));
        If S = '' Then
        Begin
          FailAt(N, 'nom de l'''#130'l'#130'ment vide.');
          Exit;
        End;
        PushFr(N, 0, -1);
        If RunState <> rsRun Then Exit;
        InterpB(PGet(N, 0), FrItems[Sp]);
        If EvalErr <> '' Then
        Begin
          FailAt(N, EvalErr);
          Exit;
        End;
        NSt[N] := stRun;
        If VarSlot(S) >= 0 Then Dummy := 0;
      End;
    kUntil :
      Begin
        PushFr(N, 0, NFirst(N, 0));
        If RunState = rsRun Then
        Begin
          FrIter[Sp] := 1;
          NSt[N] := stRun;
        End;
      End;
  Else
    NSt[N] := stRun;
    Dummy := Ord(ExecAction(N));
  End;
End;
{ ==================================================================== }
{ Fenetre : etat et primitives de dessin                                }
{ ==================================================================== }

Const
  PalW = 232; PropW = 300;
  CardW = 280; CardH = 46; GapH = 44; TopPlusH = 32; BoxPad = 14; HdrH = 16; SepW = 28; ConnH = 30; MergeH = 18;
  LoopH = 14;
  PalRowH = 22;
  MaxTb = 24;
  MaxIP = MaxN * 2 + 8;
  MaxPal = NKinds + NCats + 2;
  { commandes }
  cmNew = 100; cmOpen = 101; cmSave = 102; cmSaveAs = 103; cmQuit = 104;
  cmUndo = 110; cmRedo = 111; cmCut = 112; cmCopy = 113; cmPaste = 114; cmDelete = 115; cmDup = 116;
  cmUp = 117; cmDown = 118; cmToggleOff = 119; cmRename = 120; cmPasteHere = 121; cmSelAll = 122;
  cmShowPal = 130; cmShowProp = 131; cmCode = 132; cmFit = 133;
  cmTest = 140; cmRun = 141; cmStop = 142; cmClearRes = 143; cmLog = 144;
  cmCheck = 150; cmFlowProps = 151; cmVars = 152;
  cmHelp = 160; cmExpr = 161; cmAbout = 162;
  cmSample1 = 170; cmSample2 = 171; cmSample3 = 172;
  cmAddFirst = 200;     { + sorte : ajouter apres l'action choisie }
  cmInsFirst = 240;     { + sorte : inserer au + choisi }
  cmEnumFirst = 300;    { + valeur d'un parametre a choix }

Var
  Hab, Hmq, Frame, Client, MenuHw, Hps, CW, CH : LongInt;
  GQmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..8191] Of Byte;
  MenuLen : LongInt;
  UX1, UY1, UX2, UY2 : LongInt;
  IcX, IcY : LongInt;
  { zones }
  Y0, Y1, CX0, CX1, VsX, HsY : LongInt;
  ShowPal, ShowProp, CodeMode, HasFocus : Boolean;
  ScrX, ScrY, FlowW, FlowH, FlowCX : LongInt;
  { mise en page du flux (coordonnees du flux) }
  NX, NY, SW, SH : Array[0..MaxN - 1] Of LongInt;
  BX, BY, BW, BH, LW, LH : Array[0..MaxN * 2 - 1] Of LongInt;
  NIP : LongInt;
  IPX, IPY, IPP, IPB, IPA : Array[0..MaxIP - 1] Of LongInt;
  Sel, HovIP, HovNode, HovPal : LongInt;
  DragKind, DragNode, DropIP : LongInt;
  { barre d'outils }
  NTb, TbDown, TbHot : LongInt;
  TbCmd, TbX, TbW, TbIco : Array[0..MaxTb - 1] Of LongInt;
  TbTxt, TbTip : Array[0..MaxTb - 1] Of String;
  { palette }
  NPal, PalTop : LongInt;
  PalK : Array[0..MaxPal - 1] Of LongInt;     { > 0 : sorte ; <= 0 : -categorie (titre) }
  StatusMsg, CurFile : String;
  { vue du code Pascal }
  CodeB : TBuf;
  CodeLn : PLongs;
  CodeN, CodeCap, CodeTop : LongInt;

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

{ disque plein de rayon R }
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

{ trait epais de (X1, Y1) a (X2, Y2) par points de 2 x 2 }
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

{ crochet vert, X rouge, sablier bleu, rond gris : etat d'une action }
Procedure Badge(Cx, Cy, St : LongInt);
Begin
  Case St Of
    stOk :
      Begin
        Disc(Cx, Cy, 8, cDGreen);
        Thick(Cx - 5, Cy, Cx - 2, Cy + 3, cWhite);
        Thick(Cx - 2, Cy + 3, Cx + 4, Cy - 4, cWhite);
      End;
    stFail :
      Begin
        Disc(Cx, Cy, 8, cRed);
        Thick(Cx - 4, Cy - 4, Cx + 3, Cy + 3, cWhite);
        Thick(Cx + 3, Cy - 4, Cx - 4, Cy + 3, cWhite);
      End;
    stRun :
      Begin
        Disc(Cx, Cy, 8, cBlue);
        Disc(Cx, Cy, 5, cWhite);
        Disc(Cx, Cy, 2, cBlue);
      End;
    stSkip :
      Begin
        Disc(Cx, Cy, 8, cGray);
        FBar(Cx - 4, Cy - 1, Cx + 4, Cy + 1, cWhite);
      End;
  End;
End;

{ ==================================================================== }
{ Icones                                                                }
{ ==================================================================== }

{ icone d'une sorte d'action (carre de couleur et dessin blanc), 16 x 16 }
Procedure IcoKind(K : LongInt);
Var C : LongInt;
Begin
  C := CatColor(KCat(K));
  IR(0, 0, 15, 15, C);
  Case K Of
    kTrigger :
      Begin
        { main : clic }
        IR(6, 2, 8, 9, cWhite); IR(4, 8, 11, 13, cWhite); IR(9, 6, 11, 8, cWhite);
      End;
    kInitVar, kSetVar :
      Begin
        { variable : x entre accolades }
        IR(3, 4, 3, 11, cWhite); IR(4, 3, 4, 3, cWhite); IR(4, 12, 4, 12, cWhite);
        IR(12, 4, 12, 11, cWhite); IR(11, 3, 11, 3, cWhite); IR(11, 12, 11, 12, cWhite);
        IR(6, 5, 7, 6, cWhite); IR(8, 9, 9, 10, cWhite); IR(9, 5, 9, 6, cWhite); IR(6, 9, 6, 10, cWhite);
        IR(7, 7, 8, 8, cWhite);
      End;
    kIncVar :
      Begin
        IR(3, 7, 12, 8, cWhite); IR(7, 3, 8, 12, cWhite);
      End;
    kDecVar : IR(3, 7, 12, 8, cWhite);
    kAppend :
      Begin
        IR(2, 4, 9, 5, cWhite); IR(2, 7, 9, 8, cWhite); IR(2, 10, 6, 11, cWhite);
        IR(10, 10, 14, 11, cWhite); IR(11, 8, 13, 13, cWhite);
      End;
    kCompose :
      Begin
        IR(2, 3, 7, 12, cWhite); IR(9, 3, 14, 12, cWhite); IR(3, 5, 6, 5, C); IR(10, 5, 13, 5, C);
      End;
    kCond :
      Begin
        { losange }
        IR(7, 2, 8, 2, cWhite); IR(6, 3, 9, 3, cWhite); IR(5, 4, 10, 4, cWhite); IR(4, 5, 11, 5, cWhite);
        IR(3, 6, 12, 9, cWhite); IR(4, 10, 11, 10, cWhite); IR(5, 11, 10, 11, cWhite); IR(6, 12, 9, 12, cWhite);
        IR(7, 13, 8, 13, cWhite);
      End;
    kForEach, kUntil :
      Begin
        { fleche en boucle }
        IR(3, 4, 12, 5, cWhite); IR(11, 4, 12, 11, cWhite); IR(3, 10, 12, 11, cWhite); IR(3, 4, 4, 8, cWhite);
        IR(1, 7, 6, 7, cWhite); IR(2, 8, 5, 8, cWhite); IR(3, 9, 4, 9, cWhite);
        If K = kUntil Then IR(7, 7, 8, 8, cWhite);
      End;
    kWait :
      Begin
        { sablier }
        IR(3, 2, 12, 3, cWhite); IR(3, 12, 12, 13, cWhite);
        IR(4, 4, 11, 4, cWhite); IR(5, 5, 10, 5, cWhite); IR(6, 6, 9, 6, cWhite); IR(7, 7, 8, 8, cWhite);
        IR(6, 9, 9, 9, cWhite); IR(5, 10, 10, 10, cWhite); IR(4, 11, 11, 11, cWhite);
      End;
    kTerminate :
      Begin
        { arret : octogone }
        IR(5, 3, 10, 12, cWhite); IR(3, 5, 12, 10, cWhite); IR(4, 4, 11, 11, cWhite);
        IR(6, 7, 9, 8, C);
      End;
    kReadFile, kWriteFile, kCopyFile, kDelFile :
      Begin
        IR(3, 2, 10, 13, cWhite); IR(10, 4, 12, 13, cWhite); IR(9, 2, 9, 3, C);
        IR(5, 6, 10, 6, C); IR(5, 8, 10, 8, C); IR(5, 10, 9, 10, C);
        If K = kWriteFile Then
        Begin
          IR(8, 9, 13, 10, cYellow);
        End
        Else If K = kDelFile Then
        Begin
          IR(9, 9, 14, 14, cRed); IR(10, 11, 13, 12, cWhite);
        End
        Else If K = kCopyFile Then
        Begin
          IR(6, 8, 14, 15, cWhite); IB(6, 8, 14, 15, C);
        End;
      End;
    kMkDir, kListFiles :
      Begin
        IR(2, 4, 6, 5, cYellow); IR(2, 5, 13, 12, cYellow);
        If K = kListFiles Then
        Begin
          IR(4, 7, 11, 7, C); IR(4, 9, 11, 9, C);
        End
        Else
        Begin
          IR(7, 6, 8, 11, C); IR(5, 8, 10, 9, C);
        End;
      End;
    kMessage :
      Begin
        { bulle }
        IR(2, 3, 13, 10, cWhite); IR(4, 11, 6, 11, cWhite); IR(4, 12, 4, 12, cWhite);
        IR(4, 5, 11, 5, C); IR(4, 8, 9, 8, C);
      End;
    kAsk :
      Begin
        IR(2, 3, 13, 10, cWhite); IR(9, 11, 11, 11, cWhite); IR(11, 12, 11, 12, cWhite);
        IR(6, 4, 9, 4, C); IR(9, 5, 9, 6, C); IR(7, 7, 8, 7, C); IR(7, 9, 8, 9, C);
      End;
    kLog :
      Begin
        IR(3, 2, 12, 13, cWhite); IR(5, 5, 10, 5, C); IR(5, 7, 10, 7, C); IR(5, 9, 10, 9, C); IR(5, 11, 8, 11, C);
      End;
    kRun :
      Begin
        { fenetre et fleche }
        IR(2, 3, 13, 12, cWhite); IR(2, 3, 13, 5, cNavy); IR(5, 7, 6, 10, C); IR(7, 8, 8, 9, C);
      End;
    kDateTime :
      Begin
        Disc(IcX + 8, IcY + 8, 6, cWhite);
        IR(8, 4, 8, 8, C); IR(8, 8, 11, 8, C);
      End;
  End;
End;

{ icones de la barre d'outils }
Procedure IcoTb(K : LongInt);
Begin
  Case K Of
    1 :
      Begin
        IR(2, 1, 11, 14, cWhite); IB(2, 1, 11, 14, cBlack); IR(9, 1, 11, 3, cSilver);
        IR(9, 8, 14, 13, cYellow); IR(11, 6, 12, 15, cYellow);
      End;
    2 :
      Begin
        IR(1, 3, 6, 4, cBrown); IR(1, 4, 14, 13, cYellow); IB(1, 4, 14, 13, cBrown);
        IR(3, 7, 15, 13, cYellow); IB(3, 7, 15, 13, cBrown);
      End;
    3 :
      Begin
        IR(1, 1, 14, 14, cNavy); IR(4, 1, 11, 5, cSilver); IR(3, 8, 12, 14, cWhite); IB(1, 1, 14, 14, cBlack);
      End;
    4, 5 :
      Begin
        { annuler, retablir : fleche courbe }
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
      End;
    6 :
      Begin
        { couper }
        IR(4, 1, 5, 8, cGray); IR(10, 1, 11, 8, cGray); IR(6, 8, 9, 9, cGray);
        IR(2, 10, 6, 14, cBlack); IR(3, 11, 5, 13, cSilver); IR(9, 10, 13, 14, cBlack); IR(10, 11, 12, 13, cSilver);
      End;
    7 :
      Begin
        IR(1, 1, 8, 10, cWhite); IB(1, 1, 8, 10, cBlack);
        IR(6, 5, 14, 14, cWhite); IB(6, 5, 14, 14, cBlack); IR(8, 8, 12, 8, cGray); IR(8, 10, 12, 10, cGray);
      End;
    8 :
      Begin
        IR(2, 2, 12, 14, cBrown); IR(5, 1, 9, 3, cGray);
        IR(6, 6, 14, 15, cWhite); IB(6, 6, 14, 15, cBlack);
      End;
    9 :
      Begin
        { supprimer : X rouge }
        Thick(IcX + 3, IcY + 3, IcX + 12, IcY + 12, cRed); Thick(IcX + 12, IcY + 3, IcX + 3, IcY + 12, cRed);
      End;
    10, 11 :
      Begin
        { tester, executer : triangle vert }
        IR(3, 2, 4, 13, cDGreen); IR(5, 3, 6, 12, cDGreen); IR(7, 4, 8, 11, cDGreen); IR(9, 5, 10, 10, cDGreen);
        IR(11, 6, 12, 9, cDGreen); IR(13, 7, 13, 8, cDGreen);
        If K = 11 Then
        Begin
          IR(1, 2, 2, 13, cDGreen);
        End;
      End;
    12 : IR(3, 3, 12, 12, cRed);
    13 :
      Begin
        { code Pascal }
        IR(2, 1, 13, 14, cWhite); IB(2, 1, 13, 14, cBlack);
        IR(4, 4, 5, 11, cNavy); IR(5, 4, 8, 4, cNavy); IR(8, 5, 8, 7, cNavy); IR(5, 7, 8, 7, cNavy);
        IR(10, 6, 11, 6, cMaroon); IR(10, 9, 11, 9, cMaroon);
      End;
    14 :
      Begin
        Disc(IcX + 8, IcY + 8, 7, cBlue);
        IR(6, 4, 9, 4, cWhite); IR(9, 5, 10, 6, cWhite); IR(7, 7, 9, 7, cWhite); IR(7, 8, 8, 9, cWhite);
        IR(7, 11, 8, 12, cWhite);
      End;
    15 :
      Begin
        { verifier : coche }
        IR(1, 1, 14, 14, cWhite); IB(1, 1, 14, 14, cGray);
        Thick(IcX + 3, IcY + 7, IcX + 6, IcY + 10, cDGreen); Thick(IcX + 6, IcY + 10, IcX + 12, IcY + 4, cDGreen);
      End;
  End;
End;

{ ==================================================================== }
{ Mise en page du flux                                                  }
{ ==================================================================== }

Procedure SizeList(P, B : LongInt); Forward;

Procedure SizeNode(N : LongInt);
Var K, W0, W1, H : LongInt;
Begin
  Case NKind[N] Of
    kCond :
      Begin
        For K := 0 To 1 Do
        Begin
          SizeList(N, K);
          BW[N * 2 + K] := MaxI(CardW - 40, LW[N * 2 + K]) + 2 * BoxPad;
        End;
        W0 := BW[N * 2]; W1 := BW[N * 2 + 1];
        H := MaxI(LH[N * 2], LH[N * 2 + 1]) + HdrH + BoxPad;
        BH[N * 2] := H; BH[N * 2 + 1] := H;
        SW[N] := MaxI(CardW, W0 + SepW + W1);
        SH[N] := CardH + ConnH + H + MergeH;
      End;
    kForEach, kUntil :
      Begin
        SizeList(N, 0);
        BW[N * 2] := MaxI(CardW, LW[N * 2]) + 2 * BoxPad;
        BH[N * 2] := LH[N * 2] + HdrH + BoxPad;
        SW[N] := MaxI(CardW, BW[N * 2]);
        SH[N] := CardH + LoopH + BH[N * 2];
      End;
  Else
    SW[N] := CardW; SH[N] := CardH;
  End;
End;

Procedure SizeList(P, B : LongInt);
Var N, W, H : LongInt;
Begin
  W := CardW; H := 0;
  If P <> 0 Then H := TopPlusH;
  N := NFirst(P, B);
  While N >= 0 Do
  Begin
    SizeNode(N);
    W := MaxI(W, SW[N]);
    H := H + SH[N] + GapH;
    N := NNext[N];
  End;
  If (P <> 0) And (NFirst(P, B) >= 0) Then H := H - GapH Div 2;
  LW[P * 2 + B] := W; LH[P * 2 + B] := H;
End;

Procedure AddIP(X, Y, P, B, A : LongInt);
Begin
  If NIP >= MaxIP Then Exit;
  IPX[NIP] := X; IPY[NIP] := Y; IPP[NIP] := P; IPB[NIP] := B; IPA[NIP] := A;
  Inc(NIP);
End;

Procedure PlaceList(P, B, Cx, Y : LongInt); Forward;

Procedure PlaceNode(N, Cx, Y : LongInt);
Var Tot, X : LongInt;
Begin
  NX[N] := Cx - CardW Div 2; NY[N] := Y;
  Case NKind[N] Of
    kCond :
      Begin
        Tot := BW[N * 2] + SepW + BW[N * 2 + 1];
        X := Cx - Tot Div 2;
        BX[N * 2] := X; BY[N * 2] := Y + CardH + ConnH;
        BX[N * 2 + 1] := X + BW[N * 2] + SepW; BY[N * 2 + 1] := BY[N * 2];
        PlaceList(N, 0, BX[N * 2] + BW[N * 2] Div 2, BY[N * 2] + HdrH);
        PlaceList(N, 1, BX[N * 2 + 1] + BW[N * 2 + 1] Div 2, BY[N * 2] + HdrH);
      End;
    kForEach, kUntil :
      Begin
        BX[N * 2] := Cx - BW[N * 2] Div 2; BY[N * 2] := Y + CardH + LoopH;
        PlaceList(N, 0, Cx, BY[N * 2] + HdrH);
      End;
  End;
End;

Procedure PlaceList(P, B, Cx, Y : LongInt);
Var N : LongInt;
Begin
  If P <> 0 Then
  Begin
    AddIP(Cx, Y + TopPlusH Div 2, P, B, -1);
    Y := Y + TopPlusH;
  End;
  N := NFirst(P, B);
  While N >= 0 Do
  Begin
    PlaceNode(N, Cx, Y);
    Y := Y + SH[N];
    If (P = 0) Or (NNext[N] >= 0) Then AddIP(Cx, Y + GapH Div 2, P, B, N)
    Else AddIP(Cx, Y + GapH Div 4, P, B, N);
    Y := Y + GapH;
    N := NNext[N];
  End;
End;

Procedure Layout;
Begin
  Y0 := TbH; Y1 := CH - SbH - 1;
  If ShowPal Then CX0 := PalW + 4 Else CX0 := 0;
  If ShowProp Then CX1 := CW - PropW - 5 Else CX1 := CW - 1;
  VsX := CX1 - ScrW + 1; HsY := Y1 - ScrW + 1;
  SizeList(0, 0);
  FlowW := LW[0] + 60; FlowH := LH[0] + 40;
  FlowCX := MaxI(FlowW Div 2, (VsX - CX0) Div 2);
  NIP := 0;
  PlaceList(0, 0, FlowCX, 24);
  If ScrX > MaxI(0, FlowW - (VsX - CX0)) Then ScrX := MaxI(0, FlowW - (VsX - CX0));
  If ScrY > MaxI(0, FlowH - (HsY - Y0)) Then ScrY := MaxI(0, FlowH - (HsY - Y0));
  If ScrX < 0 Then ScrX := 0;
  If ScrY < 0 Then ScrY := 0;
End;

{ coordonnees du flux -> fenetre }
Function SX(X : LongInt) : LongInt;
Begin
  SX := CX0 + X - ScrX;
End;

Function SY(Y : LongInt) : LongInt;
Begin
  SY := Y0 + Y - ScrY;
End;

{ ==================================================================== }
{ Dessin du flux                                                        }
{ ==================================================================== }

Var
  ClX1, ClY1, ClX2, ClY2 : LongInt;    { zone du flux dans la fenetre }

{ rectangle plein, coupe a la zone du flux }
Procedure CBar(X1, Y1_, X2, Y2, C : LongInt);
Begin
  FBar(MaxI(X1, ClX1), MaxI(Y1_, ClY1), MinI(X2, ClX2), MinI(Y2, ClY2), C);
End;

Procedure CTxt(X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var N : LongInt;
Begin
  If (Y < ClY1) Or (Y + 15 > ClY2) Then Exit;
  If X < ClX1 Then
  Begin
    N := (ClX1 - X + 7) Div 8;
    Delete(S, 1, N);
    X := X + N * 8;
  End;
  If X + Length(S) * 8 > ClX2 Then S := Copy(S, 1, MaxI(0, (ClX2 - X) Div 8));
  OutTxt(X, Y, S, Fg, Bg);
End;

{ fleche verticale de Ya a Yb (pointe en bas si Head) }
Procedure Arrow(X, Ya, Yb : LongInt; Head : Boolean);
Var I : LongInt;
Begin
  CBar(X, Ya, X, Yb, cGray);
  If Head Then
    For I := 0 To 4 Do CBar(X - I, Yb - I, X + I, Yb - I, cGray);
End;

Procedure PlusBtn(X, Y : LongInt; Hot : Boolean);
Var Dy, H : LongInt;
Begin
  If (X < ClX1 + 9) Or (X > ClX2 - 9) Or (Y < ClY1 + 9) Or (Y > ClY2 - 9) Then Exit;
  If Hot Then
  Begin
    Disc(X, Y, 9, cNavy);
    FBar(X - 4, Y, X + 4, Y, cWhite); FBar(X, Y - 4, X, Y + 4, cWhite);
    FBar(X - 4, Y + 1, X + 4, Y + 1, cWhite); FBar(X + 1, Y - 4, X + 1, Y + 4, cWhite);
  End
  Else
  Begin
    Disc(X, Y, 9, cGray);
    Disc(X, Y, 8, cWhite);
    FBar(X - 4, Y, X + 4, Y, cNavy); FBar(X, Y - 4, X, Y + 4, cNavy);
  End;
  Dy := 0; H := 0;
End;

{ resume d'une action sur sa carte }
Function Summary(N : LongInt) : String;
Var S : String;
Begin
  S := '';
  Case NKind[N] Of
    kTrigger :
      Begin
        S := Trim(PGet(N, 0));
        If PGet(N, 1) <> '' Then S := S + ', ' + PGet(N, 1);
        If PGet(N, 2) <> '' Then S := S + ', ' + PGet(N, 2);
        If S = '' Then S := 'Bouton Tester ou Ex'#130'cuter' Else S := 'Entr'#130'es : ' + S;
      End;
    kInitVar : S := PGet(N, 0) + ' (' + PGet(N, 1) + ') = ' + PGet(N, 2);
    kSetVar, kCompose : S := PGet(N, 0) + ' = ' + PGet(N, 1);
    kIncVar, kDecVar :
      Begin
        If NKind[N] = kIncVar Then S := PGet(N, 0) + ' + ' Else S := PGet(N, 0) + ' - ';
        If Trim(PGet(N, 1)) = '' Then S := S + '1' Else S := S + PGet(N, 1);
      End;
    kAppend : S := PGet(N, 0) + ' += ' + PGet(N, 1);
    kCond : S := PGet(N, 0) + ' ' + PGet(N, 1) + ' ' + PGet(N, 2);
    kForEach : S := PGet(N, 1) + ' dans ' + PGet(N, 0);
    kUntil : S := 'jusqu'''#133' ' + PGet(N, 0) + ' ' + PGet(N, 1) + ' ' + PGet(N, 2);
    kWait : S := PGet(N, 0) + ' s';
    kTerminate : S := PGet(N, 0) + ' ' + PGet(N, 1);
    kReadFile : S := PGet(N, 0) + ' -> ' + PGet(N, 1);
    kWriteFile : S := PGet(N, 2) + ' ' + PGet(N, 0);
    kCopyFile : S := PGet(N, 0) + ' -> ' + PGet(N, 1);
    kListFiles : S := PGet(N, 0) + '\' + PGet(N, 1) + ' -> ' + PGet(N, 2);
    kMessage, kLog : S := PGet(N, 1 - Ord(NKind[N] = kLog));
    kAsk : S := PGet(N, 0) + ' -> ' + PGet(N, 1);
    kRun : S := PGet(N, 0) + ' ' + PGet(N, 1);
    kDateTime : S := PGet(N, 0) + ' = ' + PGet(N, 1);
  Else
    S := PGet(N, 0);
  End;
  If NOff[N] Then S := '(d'#130'sactiv'#130'e) ' + S;
  Summary := S;
End;

Procedure DrawCard(N : LongInt);
Var X, Y, C, Fg, Bc : LongInt;
Begin
  X := SX(NX[N]); Y := SY(NY[N]);
  If (X > ClX2) Or (X + CardW < ClX1) Or (Y > ClY2) Or (Y + CardH < ClY1) Then Exit;
  C := CatColor(KCat(NKind[N]));
  { ombre, fond, bordure }
  CBar(X + 3, Y + 3, X + CardW + 2, Y + CardH + 2, cGray);
  CBar(X, Y, X + CardW - 1, Y + CardH - 1, cWhite);
  Bc := cGray;
  If NSt[N] = stRun Then Bc := cBlue;
  If N = Sel Then Bc := cNavy;
  CBar(X, Y, X + CardW - 1, Y, Bc); CBar(X, Y + CardH - 1, X + CardW - 1, Y + CardH - 1, Bc);
  CBar(X, Y, X, Y + CardH - 1, Bc); CBar(X + CardW - 1, Y, X + CardW - 1, Y + CardH - 1, Bc);
  If (N = Sel) Or (NSt[N] = stRun) Then
  Begin
    CBar(X + 1, Y + 1, X + CardW - 2, Y + 1, Bc); CBar(X + 1, Y + CardH - 2, X + CardW - 2, Y + CardH - 2, Bc);
    CBar(X + CardW - 2, Y + 1, X + CardW - 2, Y + CardH - 2, Bc);
  End;
  { bande de couleur de la categorie }
  CBar(X + 1, Y + 1, X + 4, Y + CardH - 2, C);
  { icone }
  If (X + 12 >= ClX1) And (X + 28 <= ClX2) And (Y + 8 >= ClY1) And (Y + 24 <= ClY2) Then
  Begin
    IcX := X + 12; IcY := Y + 8;
    IcoKind(NKind[N]);
  End;
  If NOff[N] Then Fg := cGray Else Fg := cBlack;
  CTxt(X + 36, Y + 5, Fit(NTitle[N], CardW - 36 - 30), Fg, cWhite);
  CTxt(X + 36, Y + 24, Fit(Summary(N), CardW - 36 - 30), cGray, cWhite);
  { bouton ... (menu de l'action) }
  If (X + CardW - 22 >= ClX1) And (X + CardW - 6 <= ClX2) And (Y + 6 >= ClY1) And (Y + 10 <= ClY2) Then
  Begin
    FBar(X + CardW - 20, Y + 8, X + CardW - 19, Y + 9, cGray);
    FBar(X + CardW - 15, Y + 8, X + CardW - 14, Y + 9, cGray);
    FBar(X + CardW - 10, Y + 8, X + CardW - 9, Y + 9, cGray);
  End;
  { etat de la derniere execution }
  If (NSt[N] <> stNone) And (X + CardW - 23 >= ClX1) And (X + CardW - 5 <= ClX2) And (Y + 21 >= ClY1) And
     (Y + 39 <= ClY2) Then Badge(X + CardW - 14, Y + 30, NSt[N]);
End;

Procedure BoxFrame(X, Y, W, H : LongInt; Lbl : String; Fg, Bg : LongInt);
Var L : LongInt;
Begin
  CBar(X, Y, X + W - 1, Y, cGray); CBar(X, Y + H - 1, X + W - 1, Y + H - 1, cGray);
  CBar(X, Y, X, Y + H - 1, cGray); CBar(X + W - 1, Y, X + W - 1, Y + H - 1, cGray);
  CBar(X + 1, Y + 1, X + W - 2, Y + 1, cWhite); CBar(X + 1, Y + 1, X + 1, Y + H - 2, cWhite);
  L := Length(Lbl) * 8 + 16;
  CBar(X + W Div 2 - L Div 2, Y - 9, X + W Div 2 + L Div 2, Y + 9, Bg);
  CTxt(X + W Div 2 - L Div 2 + 8, Y - 8, Lbl, Fg, Bg);
End;

Procedure DrawList(P, B, Cx : LongInt); Forward;

Procedure DrawNode(N : LongInt);
Var Cx, Y, Ym, K, Bc, Yb : LongInt;
Begin
  Cx := SX(NX[N] + CardW Div 2);
  Y := SY(NY[N]);
  Case NKind[N] Of
    kCond :
      Begin
        Ym := Y + CardH + ConnH Div 2;
        Arrow(Cx, Y + CardH, Ym, False);
        CBar(SX(BX[N * 2] + BW[N * 2] Div 2), Ym, SX(BX[N * 2 + 1] + BW[N * 2 + 1] Div 2), Ym, cGray);
        Yb := SY(BY[N * 2]) + BH[N * 2];
        For K := 0 To 1 Do
        Begin
          Bc := SX(BX[N * 2 + K] + BW[N * 2 + K] Div 2);
          Arrow(Bc, Ym, SY(BY[N * 2 + K]) - 10, False);
          If K = 0 Then BoxFrame(SX(BX[N * 2]), SY(BY[N * 2]), BW[N * 2], BH[N * 2], 'Vrai', cWhite, cDGreen)
          Else BoxFrame(SX(BX[N * 2 + 1]), SY(BY[N * 2 + 1]), BW[N * 2 + 1], BH[N * 2 + 1], 'Faux', cWhite, cRed);
          DrawList(N, K, Bc);
          Arrow(Bc, Yb, Yb + MergeH Div 2, False);
        End;
        CBar(SX(BX[N * 2] + BW[N * 2] Div 2), Yb + MergeH Div 2, SX(BX[N * 2 + 1] + BW[N * 2 + 1] Div 2),
             Yb + MergeH Div 2, cGray);
        Arrow(Cx, Yb + MergeH Div 2, Y + SH[N], False);
      End;
    kForEach, kUntil :
      Begin
        Arrow(Cx, Y + CardH, SY(BY[N * 2]) - 10, False);
        If NKind[N] = kForEach Then BoxFrame(SX(BX[N * 2]), SY(BY[N * 2]), BW[N * 2], BH[N * 2], 'Pour chaque',
                                             cWhite, cNavy)
        Else BoxFrame(SX(BX[N * 2]), SY(BY[N * 2]), BW[N * 2], BH[N * 2], 'R'#130'p'#130'ter', cWhite, cNavy);
        DrawList(N, 0, Cx);
      End;
  End;
  DrawCard(N);
End;

Procedure DrawList(P, B, Cx : LongInt);
Var N, Y, Yn : LongInt;
Begin
  N := NFirst(P, B);
  If P <> 0 Then
  Begin
    Y := SY(BY[P * 2 + B]) + 9;
    If N >= 0 Then Arrow(Cx, Y, SY(NY[N]) - 1, True);
  End;
  While N >= 0 Do
  Begin
    DrawNode(N);
    Y := SY(NY[N]) + SH[N];
    If NNext[N] >= 0 Then
    Begin
      Yn := SY(NY[NNext[N]]);
      Arrow(Cx, Y, Yn - 1, True);
    End
    Else If P = 0 Then Arrow(Cx, Y, Y + GapH Div 2 - 9, False)
    Else Arrow(Cx, Y, Y + GapH Div 4 - 9, False);
    N := NNext[N];
  End;
End;

Procedure DrawScroll;
Var T, Th, Tp, Max_, Page : LongInt;
Begin
  { verticale }
  Raised(VsX, Y0, CX1, Y0 + ScrW - 1);
  Raised(VsX, HsY - ScrW, CX1, HsY - 1);
  FBar(VsX + 4, Y0 + 9, VsX + 11, Y0 + 9, cBlack); FBar(VsX + 5, Y0 + 8, VsX + 10, Y0 + 8, cBlack);
  FBar(VsX + 6, Y0 + 7, VsX + 9, Y0 + 7, cBlack); FBar(VsX + 7, Y0 + 6, VsX + 8, Y0 + 6, cBlack);
  FBar(VsX + 4, HsY - 10, VsX + 11, HsY - 10, cBlack); FBar(VsX + 5, HsY - 9, VsX + 10, HsY - 9, cBlack);
  FBar(VsX + 6, HsY - 8, VsX + 9, HsY - 8, cBlack); FBar(VsX + 7, HsY - 7, VsX + 8, HsY - 7, cBlack);
  T := HsY - Y0 - 2 * ScrW;
  FBar(VsX, Y0 + ScrW, CX1, HsY - ScrW - 1, cWhite);
  Page := HsY - Y0;
  Max_ := MaxI(0, FlowH - Page);
  If (Max_ > 0) And (T > 10) Then
  Begin
    Th := MaxI(12, T * Page Div FlowH);
    Tp := Y0 + ScrW + (T - Th) * ScrY Div Max_;
    Raised(VsX, Tp, CX1, Tp + Th - 1);
  End;
  { horizontale }
  Raised(CX0, HsY, CX0 + ScrW - 1, Y1);
  Raised(VsX - ScrW, HsY, VsX - 1, Y1);
  FBar(CX0 + 9, HsY + 4, CX0 + 9, HsY + 11, cBlack); FBar(CX0 + 8, HsY + 5, CX0 + 8, HsY + 10, cBlack);
  FBar(CX0 + 7, HsY + 6, CX0 + 7, HsY + 9, cBlack); FBar(CX0 + 6, HsY + 7, CX0 + 6, HsY + 8, cBlack);
  FBar(VsX - 10, HsY + 4, VsX - 10, HsY + 11, cBlack); FBar(VsX - 9, HsY + 5, VsX - 9, HsY + 10, cBlack);
  FBar(VsX - 8, HsY + 6, VsX - 8, HsY + 9, cBlack); FBar(VsX - 7, HsY + 7, VsX - 7, HsY + 8, cBlack);
  T := VsX - CX0 - 2 * ScrW;
  FBar(CX0 + ScrW, HsY, VsX - ScrW - 1, Y1, cWhite);
  Page := VsX - CX0;
  Max_ := MaxI(0, FlowW - Page);
  If (Max_ > 0) And (T > 10) Then
  Begin
    Th := MaxI(12, T * Page Div FlowW);
    Tp := CX0 + ScrW + (T - Th) * ScrX Div Max_;
    Raised(Tp, HsY, Tp + Th - 1, Y1);
  End;
  FBar(VsX, HsY, CX1, Y1, cSilver);
End;

{ ==================================================================== }
{ Vue du code Pascal (F12)                                              }
{ ==================================================================== }

Procedure CodeBuild;
Var K : LongInt;
Begin
  CodeB.Len := 0;
  EmitFlow(CodeB);
  CodeN := 0;
  If CodeLn = Nil Then
  Begin
    CodeCap := 4096;
    GetMem(CodeLn, CodeCap * 4);
  End;
  CodeLn^[0] := 0;
  CodeN := 1;
  For K := 0 To CodeB.Len - 1 Do
    If (CodeB.P^[K] = 10) And (CodeN < CodeCap - 1) Then
    Begin
      CodeLn^[CodeN] := K + 1;
      Inc(CodeN);
    End;
  If (CodeN > 1) And (CodeLn^[CodeN - 1] >= CodeB.Len) Then Dec(CodeN);
End;

Function CodeLine(I : LongInt) : String;
Var S : String; K, E : LongInt;
Begin
  S := '';
  If (I >= 0) And (I < CodeN) Then
  Begin
    K := CodeLn^[I];
    If I + 1 < CodeN Then E := CodeLn^[I + 1] Else E := CodeB.Len;
    While (K < E) And (Length(S) < 250) Do
    Begin
      If CodeB.P^[K] >= 32 Then S := S + Chr(CodeB.P^[K]);
      Inc(K);
    End;
  End;
  CodeLine := S;
End;

Function IsKwP(W : String) : Boolean;
Begin
  W := ' ' + UpStr(W) + ' ';
  IsKwP := Pos(W, ' PROGRAM BEGIN END IF THEN ELSE FOR IN DO REPEAT UNTIL OR AND NOT ') > 0;
End;

{ une ligne de Pascal coloree }
Procedure CodePaint(X, Y : LongInt; S : String);
Var K, J, C : LongInt; W : String;
Begin
  K := 1;
  While K <= Length(S) Do
  Begin
    J := K;
    If S[K] = '{' Then
    Begin
      While (J <= Length(S)) And (S[J] <> '}') Do Inc(J);
      C := cDGreen;
    End
    Else If (S[K] = '(') And (K < Length(S)) And (S[K + 1] = '*') Then
    Begin
      J := Length(S);
      C := cDGreen;
    End
    Else If (S[K] = '''') Or (S[K] = '#') Then
    Begin
      Repeat
        If S[J] = '''' Then
        Begin
          Inc(J);
          While (J <= Length(S)) And (S[J] <> '''') Do Inc(J);
          Inc(J);
        End
        Else
        Begin
          Inc(J);
          While (J <= Length(S)) And (S[J] >= '0') And (S[J] <= '9') Do Inc(J);
        End;
      Until (J > Length(S)) Or ((S[J] <> '''') And (S[J] <> '#'));
      Dec(J);
      C := cMaroon;
    End
    Else If ExIsAl(S[K]) Then
    Begin
      While (J < Length(S)) And (ExIsAl(S[J + 1]) Or ((S[J + 1] >= '0') And (S[J + 1] <= '9'))) Do Inc(J);
      W := Copy(S, K, J - K + 1);
      If IsKwP(W) Then C := cBlue Else C := cBlack;
    End
    Else C := cBlack;
    If J > Length(S) Then J := Length(S);
    W := Copy(S, K, J - K + 1);
    CTxt(X + (K - 1) * 8, Y, W, C, cWhite);
    K := J + 1;
  End;
End;

Procedure PaintCode;
Var R, Rows, Y : LongInt;
Begin
  FBar(CX0, Y0, VsX - 1, HsY - 1, cWhite);
  Rows := (HsY - Y0 - 8) Div 16;
  If CodeTop > MaxI(0, CodeN - Rows) Then CodeTop := MaxI(0, CodeN - Rows);
  For R := 0 To Rows - 1 Do
  Begin
    If CodeTop + R >= CodeN Then Break;
    Y := Y0 + 4 + R * 16;
    CTxt(CX0 + 4, Y, IStr(CodeTop + R + 1), cGray, cWhite);
    CodePaint(CX0 + 44, Y, CodeLine(CodeTop + R));
  End;
End;

{ ==================================================================== }
{ Barre d'outils, palette, proprietes, barre d'etat                     }
{ ==================================================================== }

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
    Dis := ((TbCmd[I] = cmStop) And (RunState = rsIdle)) Or (((TbCmd[I] = cmTest) Or (TbCmd[I] = cmRun)) And
           (RunState <> rsIdle));
    If TbDown = I Then
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
    If Dis Then IR(3, 3, 12, 12, cGray) Else IcoTb(TbIco[I]);
    If TbTxt[I] <> '' Then
    Begin
      If Dis Then OutTxt(IcX + 20, IcY - 1, TbTxt[I], cGray, cSilver)
      Else OutTxt(IcX + 20, IcY - 1, TbTxt[I], cBlack, cSilver);
    End;
  End;
End;

Procedure PaintPalette;
Var I, Y, K, Bg : LongInt;
Begin
  Raised(0, Y0, PalW - 1, Y0 + 21);
  OutTxt(8, Y0 + 3, 'Actions', cBlack, cSilver);
  FBar(0, Y0 + 22, PalW - 1, Y1, cWhite);
  VLine(PalW - 1, Y0 + 22, Y1, cGray);
  For I := PalTop To NPal - 1 Do
  Begin
    Y := Y0 + 24 + (I - PalTop) * PalRowH;
    If Y + PalRowH > Y1 Then Break;
    K := PalK[I];
    If K <= 0 Then
    Begin
      FBar(0, Y, PalW - 2, Y + PalRowH - 1, cSilver);
      OutTxt(8, Y + 3, CatName(-K), cNavy, cSilver);
      HLine(0, PalW - 2, Y + PalRowH - 1, cGray);
    End
    Else
    Begin
      If (I = HovPal) Or (DragKind = K) Then Bg := cSilver Else Bg := cWhite;
      FBar(0, Y, PalW - 2, Y + PalRowH - 1, Bg);
      IcX := 10; IcY := Y + 3;
      IcoKind(K);
      OutTxt(32, Y + 3, Fit(KName(K), PalW - 36), cBlack, Bg);
    End;
  End;
End;

Procedure PaintStatus;
Var X : LongInt; S : String;
Begin
  Raised(0, CH - SbH, CW - 1, CH - 1);
  S := IStr(NCount) + ' action(s)';
  X := CW - 8 - Length(S) * 8;
  Sunken(X - 6, CH - SbH + 2, CW - 4, CH - 3, cSilver);
  OutTxt(X, CH - SbH + 2, S, cBlack, cSilver);
  If (RunState <> rsIdle) Or (RunSummary <> '') Then
  Begin
    S := RunSummary;
    If Length(S) * 8 > X - 200 Then S := Fit(S, MaxI(0, X - 200));
    X := X - 14 - Length(S) * 8 - 24;
    Sunken(X - 6, CH - SbH + 2, X + Length(S) * 8 + 26, CH - 3, cSilver);
    If RunState <> rsIdle Then Badge(X + 6, CH - SbH Div 2, stRun)
    Else If RunOk Then Badge(X + 6, CH - SbH Div 2, stOk) Else Badge(X + 6, CH - SbH Div 2, stFail);
    OutTxt(X + 20, CH - SbH + 2, S, cBlack, cSilver);
  End
  Else X := X - 10;
  OutTxt(6, CH - SbH + 2, Fit(StatusMsg, X - 16), cBlack, cSilver);
End;
{ ==================================================================== }
{ Boites de dialogue                                                    }
{ ==================================================================== }

Const
  WM_SETFOCUS = $000F;
  MaxDlg = 6;
  dNone = 0; dToolbar = 1; dCardWait = 2; dCard = 3; dPalWait = 4; dPal = 5; dPan = 6; dVThumb = 7; dHThumb = 8;
  MaxUndo = 40;
  MaxProp = 5;

Var
  DgFrame, DgClient, DgN, DgW, DgH : LongInt;
  DgDone, DgOk : Boolean;
  DgLab, DgV : Array[0..MaxDlg - 1] Of String;
  DgEf : Array[0..MaxDlg - 1] Of LongInt;
  Drag, DragX0, DragY0, DragOff, DragSX, DragSY, LastMx, LastMy : LongInt;
  CtxMenu : LongInt;
  MStkN : Array[0..7] Of LongInt;
  MDep : LongInt;
  HelpBuf, ClipB : TBuf;
  UndoB, RedoB : Array[0..MaxUndo - 1] Of TBuf;
  UndoN, RedoN : LongInt;
  CurDir, OutFile : String;
  AutoRun : Boolean;
  { insertion en attente (menu d'un +) et parametre a choix en attente }
  PendP, PendB, PendA, PendEnum, MenuNode : LongInt;
  { proprietes }
  PropN : LongInt;
  PropEf, PropPar, PropY : Array[0..MaxProp - 1] Of LongInt;
  PropSnap : Boolean;
  PropFor : LongInt;           { action dont le volet montre les champs }
  NextStep : LongInt;

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
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('PascalFlow'), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure MsgErr(S : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('PascalFlow'), 0, MB_OK Or MB_ERROR Or MB_MOVEABLE);
End;

Function Ask3(S : String) : LongInt;
Begin
  Ask3 := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('PascalFlow'), 0, MB_YESNOCANCEL Or MB_QUERY Or MB_MOVEABLE);
End;

{ texte long (aide, journal) dans une boite de message }
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
  Dummy := WinRegisterClass(Hab, Z('PFDLG'), LongInt(@DlgProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DgClient := 0;
  DgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('PFDLG'), Z2(Title), 0, 0, 0, LongInt(@DgClient));
  If DgFrame = 0 Then Exit;
  For K := 0 To DgN - 1 Do
  Begin
    DgEf[K] := WinCreateWindow(DgClient, WC_ENTRYFIELD, Z(DgV[K]), WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or
                               ES_MARGIN, 14, DgH - 54 - K * 46, DgW - 28, 20, DgClient, HWND_TOP, 10 + K, 0, 0);
    Dummy := WinSendMsg(DgEf[K], EM_SETTEXTLIMIT, 250, 0);
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

{ fournies au moteur d'execution }
Function RunAsk(Q, Def : String; Var V : String) : Boolean;
Begin
  DlgReset;
  DlgField(Q, Def);
  RunAsk := InputBox('PascalFlow - Demander une valeur', 'OK');
  V := DgV[0];
End;

Procedure RunShow(Title : String; Var Text : TBuf);
Begin
  If Title = '' Then Title := 'PascalFlow';
  ShowBuf(Title, Text);
End;

Procedure RunChanged;
Begin
  Redraw;
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

{ sous-menus des actions par categorie ; Base : cmAddFirst ou cmInsFirst }
Procedure KindMenus(Base : LongInt);
Var C, K, H : LongInt;
Begin
  For C := 1 To NCats - 1 Do
  Begin
    MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 90 + C, '~' + CatName(C));
    H := MenuOpen;
    For K := 2 To NKinds Do If KCat(K) = C Then It(Base + K, KName(K));
    MenuClose(H);
  End;
End;

Procedure BuildMenu;
Var H0, H1, H2 : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 80, '~Fichier');
  H1 := MenuOpen;
  It(cmNew, '~Nouveau flux' + #9 + 'Ctrl+N');
  It(cmOpen, '~Ouvrir...' + #9 + 'Ctrl+O');
  It(cmSave, '~Enregistrer' + #9 + 'Ctrl+S');
  It(cmSaveAs, 'Enregistrer ~sous...');
  Sep;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 89, 'E~xemples');
  H2 := MenuOpen;
  It(cmSample1, '~Bonjour (entr'#130'e, condition, message)');
  It(cmSample2, '~Compter jusqu'''#133' 10 (boucle, variables)');
  It(cmSample3, '~Inventaire d''un dossier (fichiers, Appliquer '#133' chacun)');
  MenuClose(H2);
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
  It(cmDup, '~Dupliquer' + #9 + 'Ctrl+D');
  Sep;
  It(cmUp, '~Monter' + #9 + 'Ctrl+Haut');
  It(cmDown, 'D~escendre' + #9 + 'Ctrl+Bas');
  It(cmToggleOff, 'D'#130's~activer ou activer' + #9 + 'Ctrl+E');
  It(cmRename, 'Re~nommer' + #9 + 'F2');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 82, '~Affichage');
  H1 := MenuOpen;
  ItA(cmShowPal, Chk(ShowPal), 'Barre des ~actions' + #9 + 'F7');
  ItA(cmShowProp, Chk(ShowProp), 'Volet des ~propri'#130't'#130's' + #9 + 'F8');
  ItA(cmCode, Chk(CodeMode), '~Code Pascal du flux' + #9 + 'F12');
  Sep;
  It(cmFit, '~Haut du flux' + #9 + 'Origine');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 83, 'Fl~ux');
  H1 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 88, '~Ajouter une action');
  H2 := MenuOpen;
  KindMenus(cmAddFirst);
  MenuClose(H2);
  Sep;
  It(cmCheck, '~V'#130'rifier le flux');
  It(cmVars, 'V~ariables de la derni'#138're ex'#130'cution');
  It(cmFlowProps, '~Propri'#130't'#130's du flux...');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 84, 'E~x'#130'cuter');
  H1 := MenuOpen;
  It(cmTest, '~Tester (pas '#133' pas)' + #9 + 'F5');
  It(cmRun, '~Ex'#130'cuter manuellement' + #9 + 'Ctrl+F5');
  It(cmStop, '~Arr'#136'ter' + #9 + 'Echap');
  Sep;
  It(cmClearRes, 'Effacer les ~r'#130'sultats');
  It(cmLog, '~Journal de la derni'#138're ex'#130'cution');
  MenuClose(H1);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 85, '~?');
  H1 := MenuOpen;
  It(cmHelp, '~Aide' + #9 + 'F1');
  It(cmExpr, '~Expressions @{...}');
  Sep;
  It(cmAbout, '~A propos de PascalFlow...');
  MenuClose(H1);
  MenuClose(H0);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

Procedure ShowPopup(X, Y, Fst : LongInt);
Begin
  If CtxMenu <> 0 Then Dummy := WinDestroyWindow(CtxMenu);
  CtxMenu := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuT));
  If CtxMenu <> 0 Then Dummy := WinPopupMenu(Client, Client, CtxMenu, X, CH - 1 - Y, Fst, 0);
End;

{ ==================================================================== }
{ Barre d'outils et palette                                             }
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
  TbAdd(cmNew, 1, '', 'Nouveau flux (Ctrl+N)');
  TbAdd(cmOpen, 2, '', 'Ouvrir un flux .pf (Ctrl+O)');
  TbAdd(cmSave, 3, '', 'Enregistrer (Ctrl+S)');
  TbAdd(0, 0, '', '');
  TbAdd(cmUndo, 4, '', 'Annuler (Ctrl+Z)');
  TbAdd(cmRedo, 5, '', 'R'#130'tablir (Ctrl+Y)');
  TbAdd(0, 0, '', '');
  TbAdd(cmCut, 6, '', 'Couper l''action (Ctrl+X)');
  TbAdd(cmCopy, 7, '', 'Copier l''action (Ctrl+C)');
  TbAdd(cmPaste, 8, '', 'Coller apr'#138's l''action choisie (Ctrl+V)');
  TbAdd(cmDelete, 9, '', 'Supprimer l''action (Suppr)');
  TbAdd(0, 0, '', '');
  TbAdd(cmTest, 10, 'Tester', 'Tester le flux pas '#133' pas (F5)');
  TbAdd(cmRun, 11, 'Ex'#130'cuter', 'Ex'#130'cuter manuellement le flux (Ctrl+F5)');
  TbAdd(cmStop, 12, 'Arr'#136'ter', 'Arr'#136'ter l''ex'#130'cution (Echap)');
  TbAdd(0, 0, '', '');
  TbAdd(cmCheck, 15, '', 'V'#130'rifier le flux');
  TbAdd(cmCode, 13, 'Code Pascal', 'Voir le flux en Pascal, tel qu''il est enregistr'#130' (F12)');
  TbAdd(0, 0, '', '');
  TbAdd(cmHelp, 14, '', 'Aide (F1)');
End;

Procedure PaletteInit;
Var C, K : LongInt;
Begin
  NPal := 0; PalTop := 0; HovPal := -1;
  For C := 1 To NCats - 1 Do
  Begin
    PalK[NPal] := -C; Inc(NPal);
    For K := 2 To NKinds Do
      If KCat(K) = C Then
      Begin
        PalK[NPal] := K; Inc(NPal);
      End;
  End;
End;

{ ==================================================================== }
{ Volet des proprietes                                                  }
{ ==================================================================== }

Function PX0 : LongInt;
Begin
  PX0 := CW - PropW;
End;

Procedure PropKill;
Var K : LongInt;
Begin
  For K := 0 To MaxProp - 1 Do
  Begin
    If PropEf[K] <> 0 Then Dummy := WinDestroyWindow(PropEf[K]);
    PropEf[K] := 0;
  End;
  PropN := 0;
End;

{ valeur affichee de la ligne K du volet }
Function PropValue(K : LongInt) : String;
Begin
  If Sel <= 0 Then
  Begin
    If Sel = 0 Then PropValue := NTitle[0] Else PropValue := FlowName;
  End
  Else If PropPar[K] < 0 Then PropValue := NTitle[Sel]
  Else PropValue := PGet(Sel, PropPar[K]);
End;

Function PropIsEnum(K : LongInt) : Boolean;
Begin
  PropIsEnum := (Sel > 0) And (PropPar[K] >= 0) And (KEnum(NKind[Sel], PropPar[K]) <> '');
End;

{ champs de saisie de l'action choisie (Sel), ou du flux (Sel < 0) }
Procedure PropMake;
Var K, Y, St : LongInt;
Begin
  PropKill;
  PropSnap := False;
  If (Sel > 0) And Not NUsed[Sel] Then Sel := -1;
  If Sel = 0 Then Sel := -1;
  PropFor := Sel;
  If Not ShowProp Or CodeMode Then Exit;
  PropN := 1;
  PropPar[0] := -1;
  If Sel > 0 Then
    For K := 0 To KNPar(NKind[Sel]) - 1 Do
    Begin
      PropPar[PropN] := K;
      Inc(PropN);
    End;
  Y := Y0 + 36;
  For K := 0 To PropN - 1 Do
  Begin
    PropY[K] := Y;
    If Not PropIsEnum(K) Then
    Begin
      St := WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN;
      PropEf[K] := WinCreateWindow(Client, WC_ENTRYFIELD, Z(PropValue(K)), St, PX0 + 12, CH - (Y + 18) - 22,
                                   PropW - 26, 22, Client, HWND_TOP, 50 + K, 0, 0);
      Dummy := WinSendMsg(PropEf[K], EM_SETTEXTLIMIT, 250, 0);
    End;
    Y := Y + 48;
  End;
End;

{ reporter dans le flux ce qui a ete tape dans le volet }
Procedure Snapshot; Forward;

Procedure PropPoll;
Var K : LongInt; S : String; Ch : Boolean;
Begin
  Ch := False;
  { champs d'une autre action (la selection a change sans PropMake) }
  If (PropFor <> Sel) Or ((Sel > 0) And Not NUsed[Sel]) Then Exit;
  For K := 0 To PropN - 1 Do
  Begin
    If PropEf[K] = 0 Then Continue;
    S := WinText(PropEf[K]);
    If S = PropValue(K) Then Continue;
    If Not PropSnap Then
    Begin
      Snapshot;
      PropSnap := True;
    End;
    If Sel <= 0 Then FlowName := S
    Else If PropPar[K] < 0 Then NTitle[Sel] := S
    Else PSet(Sel, PropPar[K], S);
    Ch := True;
  End;
  If Ch Then
  Begin
    Modified := True;
    If CodeMode Then CodeBuild;
    InvalBand(CX0, Y0, CX1 + 1, Y1 + 1);
    InvalBand(0, CH - SbH, CW, CH);
  End;
End;

{ texte coupe en lignes de W caracteres au plus }
Procedure WrapOut(X, Y, W, MaxL : LongInt; S : String; Fg : LongInt);
Var L, K : LongInt;
Begin
  L := 0;
  While (S <> '') And (L < MaxL) Do
  Begin
    K := MinI(Length(S), W);
    If (K < Length(S)) Then
    Begin
      While (K > W Div 2) And (S[K] <> ' ') Do Dec(K);
      If S[K] <> ' ' Then K := MinI(Length(S), W);
    End;
    OutTxt(X, Y + L * 16, Trim(Copy(S, 1, K)), Fg, cSilver);
    Delete(S, 1, K);
    Inc(L);
  End;
End;

Procedure PaintProps;
Var X, K, Y, W : LongInt; S, L : String;
Begin
  X := PX0;
  FBar(X - 4, Y0, X - 1, Y1, cSilver);
  VLine(X - 4, Y0, Y1, cWhite); VLine(X - 1, Y0, Y1, cGray);
  FBar(X, Y0, CW - 1, Y1, cSilver);
  Raised(X, Y0, CW - 1, Y0 + 27);
  If Sel > 0 Then
  Begin
    IcX := X + 8; IcY := Y0 + 6;
    IcoKind(NKind[Sel]);
    OutTxt(X + 30, Y0 + 5, Fit(KName(NKind[Sel]), PropW - 36), cBlack, cSilver);
  End
  Else OutTxt(X + 8, Y0 + 5, 'Propri'#130't'#130's du flux', cBlack, cSilver);
  W := PropW - 26;
  For K := 0 To PropN - 1 Do
  Begin
    Y := PropY[K];
    If Sel <= 0 Then L := 'Nom du flux (programme Pascal)'
    Else If PropPar[K] < 0 Then L := 'Titre de la carte'
    Else L := KPar(NKind[Sel], PropPar[K]);
    OutTxt(X + 12, Y, Fit(L, W), cBlack, cSilver);
    If PropIsEnum(K) Then
    Begin
      Sunken(X + 12, Y + 18, X + 12 + W - 1, Y + 18 + 21, cWhite);
      OutTxt(X + 16, Y + 21, Fit(PropValue(K), W - 30), cBlack, cWhite);
      Raised(X + 12 + W - 20, Y + 19, X + 12 + W - 2, Y + 38);
      FBar(X + W - 2, Y + 26, X + W + 6, Y + 26, cBlack); FBar(X + W - 1, Y + 27, X + W + 5, Y + 27, cBlack);
      FBar(X + W, Y + 28, X + W + 4, Y + 28, cBlack); FBar(X + W + 1, Y + 29, X + W + 3, Y + 29, cBlack);
      FBar(X + W + 2, Y + 30, X + W + 2, Y + 30, cBlack);
    End;
  End;
  Y := Y0 + 36 + PropN * 48 + 6;
  HLine(X + 8, CW - 9, Y, cGray); HLine(X + 8, CW - 9, Y + 1, cWhite);
  Y := Y + 8;
  If Sel > 0 Then
  Begin
    OutTxt(X + 12, Y, 'Derni'#138're ex'#130'cution', cNavy, cSilver);
    Y := Y + 20;
    If NSt[Sel] <> stNone Then Badge(X + 20, Y + 8, NSt[Sel]);
    S := StName(NSt[Sel]);
    S := UpCase(S[1]) + Copy(S, 2, 255);
    OutTxt(X + 34, Y, S, cBlack, cSilver);
    Y := Y + 22;
    If NOut[Sel] <> '' Then WrapOut(X + 12, Y, W Div 8, MaxI(1, (Y1 - Y - 8) Div 16), NOut[Sel], cBlack);
  End
  Else
  Begin
    OutTxt(X + 12, Y, 'Flux', cNavy, cSilver);
    Y := Y + 20;
    If CurFile <> '' Then S := NameOf(CurFile) Else S := '(non enregistr'#130')';
    OutTxt(X + 12, Y, Fit('Fichier : ' + S, W), cBlack, cSilver);
    OutTxt(X + 12, Y + 16, IStr(NCount) + ' action(s)', cBlack, cSilver);
    If RunSummary <> '' Then WrapOut(X + 12, Y + 40, W Div 8, 4, RunSummary, cBlack);
    Y := Y + 112;
    If Y + 100 < Y1 Then
    Begin
      OutTxt(X + 12, Y, 'Astuces', cNavy, cSilver);
      WrapOut(X + 12, Y + 20, W Div 8, MaxI(1, (Y1 - Y - 28) Div 16),
              'Cliquez une action de la barre de gauche pour l''ajouter, ou glissez-la sur un +. ' +
              'Bouton 2 sur une carte : copier, coller, supprimer... Valeurs : @{Variable} ou ' +
              '@{expression}.', cBlack);
    End;
  End;
End;

{ ==================================================================== }
{ Peinture                                                              }
{ ==================================================================== }

Procedure Paint(H : LongInt);
Var Rc : Array[0..3] Of LongInt; I : LongInt;
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
  If ShowPal And (UX1 < CX0) Then
  Begin
    PaintPalette;
    FBar(PalW, Y0, CX0 - 1, Y1, cSilver);
    VLine(CX0 - 1, Y0, Y1, cGray);
  End;
  If (UX2 >= CX0) And (UX1 <= CX1) Then
  Begin
    ClX1 := CX0; ClY1 := Y0; ClX2 := VsX - 1; ClY2 := HsY - 1;
    If CodeMode Then PaintCode
    Else
    Begin
      FBar(CX0, Y0, VsX - 1, HsY - 1, cSilver);
      DrawList(0, 0, SX(FlowCX));
      For I := 0 To NIP - 1 Do
        PlusBtn(SX(IPX[I]), SY(IPY[I]), (I = HovIP) Or (I = DropIP));
    End;
    DrawScroll;
  End;
  If ShowProp And (UX2 >= CX1) Then PaintProps;
  If UY2 >= CH - SbH Then PaintStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure InvalCanvas;
Begin
  InvalBand(CX0, Y0, CX1 + 1, Y1 + 1);
End;

{ ==================================================================== }
{ Annuler, retablir                                                     }
{ ==================================================================== }

Procedure Snapshot;
Var K : LongInt;
Begin
  If UndoN >= MaxUndo Then
  Begin
    BufFree(UndoB[0]);
    For K := 0 To MaxUndo - 2 Do UndoB[K] := UndoB[K + 1];
    BufInit(UndoB[MaxUndo - 1]);
    Dec(UndoN);
  End;
  BufInit(UndoB[UndoN]);
  EmitFlow(UndoB[UndoN]);
  Inc(UndoN);
  For K := 0 To RedoN - 1 Do BufFree(RedoB[K]);
  RedoN := 0;
  Modified := True;
End;

Procedure UndoClear;
Var K : LongInt;
Begin
  For K := 0 To UndoN - 1 Do BufFree(UndoB[K]);
  For K := 0 To RedoN - 1 Do BufFree(RedoB[K]);
  UndoN := 0; RedoN := 0;
End;

{ remplacer le flux par celui de B }
Procedure LoadFrom(Var B : TBuf);
Var E : String;
Begin
  NReset;
  E := ParseInto(B, 0, 0);
  EnsureTrigger;
  Sel := -1;
  If E <> '' Then MsgErr('Fichier de flux incorrect, ' + E);
End;

Procedure UndoRedo(Redo : Boolean);
Var Cur : TBuf;
Begin
  If RunState <> rsIdle Then Exit;
  If Redo And (RedoN = 0) Then Exit;
  If Not Redo And (UndoN = 0) Then Exit;
  BufInit(Cur);
  EmitFlow(Cur);
  If Redo Then
  Begin
    If UndoN < MaxUndo Then
    Begin
      UndoB[UndoN] := Cur; Inc(UndoN);
    End
    Else BufFree(Cur);
    Dec(RedoN);
    LoadFrom(RedoB[RedoN]);
    BufFree(RedoB[RedoN]);
  End
  Else
  Begin
    If RedoN < MaxUndo Then
    Begin
      RedoB[RedoN] := Cur; Inc(RedoN);
    End
    Else BufFree(Cur);
    Dec(UndoN);
    LoadFrom(UndoB[UndoN]);
    BufFree(UndoB[UndoN]);
  End;
  Modified := True;
  ClearRun;
  If CodeMode Then CodeBuild;
  PropMake;
  Redraw;
End;

{ ==================================================================== }
{ Modifications du flux                                                 }
{ ==================================================================== }

Procedure SetTitle;
Var S : String;
Begin
  If CurFile <> '' Then S := NameOf(CurFile) Else S := 'Sans titre';
  If Modified Then S := S + ' *';
  Dummy := WinSetWindowText(Frame, Z('PascalFlow - ' + S));
End;

Procedure Changed;
Begin
  Modified := True;
  If CodeMode Then CodeBuild;
  Redraw;
End;

{ faire voir l'action choisie }
Procedure ShowSel;
Var W, H : LongInt;
Begin
  If Sel <= 0 Then Exit;
  Layout;
  W := VsX - CX0; H := HsY - Y0;
  If NY[Sel] - 20 < ScrY Then ScrY := MaxI(0, NY[Sel] - 20);
  If NY[Sel] + CardH + 30 > ScrY + H Then ScrY := NY[Sel] + CardH + 30 - H;
  If NX[Sel] - 20 < ScrX Then ScrX := MaxI(0, NX[Sel] - 20);
  If NX[Sel] + CardW + 20 > ScrX + W Then ScrX := NX[Sel] + CardW + 20 - W;
End;

{ centrer la vue sur l'action choisie (apres un ajout qui elargit le flux) }
Procedure CenterSel;
Begin
  If Sel <= 0 Then Exit;
  Layout;
  ScrX := MaxI(0, NX[Sel] + CardW Div 2 - (VsX - CX0) Div 2);
  Layout;
  ShowSel;
End;

Procedure Select(N : LongInt);
Begin
  PropPoll;
  If (N > 0) And Not NUsed[N] Then N := -1;
  Sel := N;
  If Sel = 0 Then Sel := -1;
  PropMake;
  ShowSel;
  Redraw;
End;

{ ajouter une action de la sorte K dans la branche B de P, apres A }
Procedure AddAt(K, P, B, A : LongInt);
Var N : LongInt;
Begin
  If RunState <> rsIdle Then Exit;
  PropPoll;
  If (P = 0) And (A < 0) Then A := NFirst(0, 0);     { jamais avant le declencheur }
  Snapshot;
  N := NAlloc(K);
  If N < 0 Then
  Begin
    MsgErr('Le flux est plein (' + IStr(MaxN - 1) + ' actions au plus).');
    Exit;
  End;
  NInsert(P, B, A, N);
  StatusMsg := KName(K) + ' ajout'#130'e.';
  Sel := N;
  Changed;
  PropMake;
  CenterSel;
  SetTitle;
End;

{ ajouter apres l'action choisie (ou a la fin du flux) }
Procedure AddKind(K : LongInt);
Begin
  If Sel > 0 Then AddAt(K, NParent[Sel], NBr[Sel], Sel)
  Else AddAt(K, 0, 0, NLast(0, 0));
End;

{ coller le texte Pascal de B dans la branche (P, Br) apres A }
Function PasteBuf(Var B : TBuf; P, Br, A : LongInt) : LongInt;
Var T, C, Nx, Last : LongInt; E : String;
Begin
  PasteBuf := -1;
  If (P = 0) And (A < 0) Then A := NFirst(0, 0);
  T := NAlloc(kForEach);
  If T < 0 Then Exit;
  E := ParseInto(B, T, 0);
  If E <> '' Then
  Begin
    NFreeTree(T);
    MsgErr('Le presse-papiers ne contient pas d''actions de PascalFlow (' + E + ').');
    Exit;
  End;
  Last := -1;
  C := NFirst(T, 0);
  While C >= 0 Do
  Begin
    Nx := NNext[C];
    If NKind[C] = kTrigger Then NFreeTree(C)
    Else
    Begin
      NInsert(P, Br, A, C);
      A := C; Last := C;
    End;
    C := Nx;
  End;
  NFst[T * 2] := -1;
  NUsed[T] := False;
  PasteBuf := Last;
End;

Procedure CopyNode(N : LongInt);
Var T : PBytes;
Begin
  If (N <= 0) Or (NKind[N] = kTrigger) Then Exit;
  PropPoll;
  ClipB.Len := 0;
  EmitNode(ClipB, N, 0);
  GetMem(T, ClipB.Len + 1);
  Move(ClipB.P^[0], T^[0], ClipB.Len);
  T^[ClipB.Len] := 0;
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    Dummy := WinSetClipbrdData(Hab, LongInt(T), 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
  FreeMem(T, ClipB.Len + 1);
  StatusMsg := 'Action copi'#130'e (texte Pascal dans le presse-papiers).';
End;

{ texte du presse-papiers de PM (ou celui de la derniere copie) }
Procedure ClipText(Var B : TBuf);
Var P, K : LongInt; Q : PBytes;
Begin
  B.Len := 0;
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    P := WinQueryClipbrdData(Hab, 1);
    If P <> 0 Then
    Begin
      Q := Pointer(P);
      K := 0;
      While (Q^[K] <> 0) And (K < 200000) Do Inc(K);
      BufAddB(B, Q, K);
    End;
    Dummy := WinCloseClipbrd(Hab);
  End;
  If B.Len = 0 Then BufAddB(B, ClipB.P, ClipB.Len);
End;

Procedure PasteAt(P, Br, A : LongInt);
Var B : TBuf; N : LongInt;
Begin
  If RunState <> rsIdle Then Exit;
  PropPoll;
  BufInit(B);
  ClipText(B);
  If B.Len = 0 Then
  Begin
    BufFree(B);
    StatusMsg := 'Le presse-papiers est vide.';
    Redraw;
    Exit;
  End;
  Snapshot;
  N := PasteBuf(B, P, Br, A);
  BufFree(B);
  If N > 0 Then
  Begin
    Sel := N;
    StatusMsg := 'Action(s) coll'#130'e(s).';
  End;
  Changed;
  PropMake;
  CenterSel;
  SetTitle;
End;

Procedure DeleteNode(N : LongInt);
Var Nx : LongInt;
Begin
  If (N <= 0) Or (NKind[N] = kTrigger) Or (RunState <> rsIdle) Then Exit;
  PropPoll;
  Snapshot;
  Nx := NNext[N];
  If Nx < 0 Then Nx := NPrev(N);
  If Nx < 0 Then Nx := NParent[N];
  NUnlink(N);
  NFreeTree(N);
  Sel := Nx;
  If Sel = 0 Then Sel := -1;
  StatusMsg := 'Action supprim'#130'e.';
  Changed;
  PropMake;
  SetTitle;
End;

Procedure DupNode(N : LongInt);
Var B : TBuf; M : LongInt;
Begin
  If (N <= 0) Or (NKind[N] = kTrigger) Or (RunState <> rsIdle) Then Exit;
  PropPoll;
  BufInit(B);
  EmitNode(B, N, 0);
  Snapshot;
  M := PasteBuf(B, NParent[N], NBr[N], N);
  BufFree(B);
  If M > 0 Then Sel := M;
  Changed;
  PropMake;
  ShowSel;
  SetTitle;
End;

Procedure MoveNode(N : LongInt; Down : Boolean);
Var Pv, Nx, P, B : LongInt;
Begin
  If (N <= 0) Or (NKind[N] = kTrigger) Or (RunState <> rsIdle) Then Exit;
  P := NParent[N]; B := NBr[N];
  If Down Then
  Begin
    Nx := NNext[N];
    If Nx < 0 Then Exit;
    PropPoll;
    Snapshot;
    NUnlink(N);
    NInsert(P, B, Nx, N);
  End
  Else
  Begin
    Pv := NPrev(N);
    If (Pv < 0) Or (NKind[Pv] = kTrigger) Then Exit;
    PropPoll;
    Snapshot;
    NUnlink(N);
    NInsert(P, B, NPrev(Pv), N);
  End;
  Changed;
  ShowSel;
  SetTitle;
End;

{ deplacer N au + numero I (glisser-deposer) }
Procedure MoveTo(N, I : LongInt);
Var P, B, A : LongInt;
Begin
  If (N <= 0) Or (I < 0) Or (NKind[N] = kTrigger) Then Exit;
  P := IPP[I]; B := IPB[I]; A := IPA[I];
  If IsAncestor(N, P) Or (A = N) Then Exit;
  If (NParent[N] = P) And (NBr[N] = B) And (NPrev(N) = A) Then Exit;
  If (P = 0) And (A < 0) Then Exit;
  PropPoll;
  Snapshot;
  NUnlink(N);
  NInsert(P, B, A, N);
  Sel := N;
  PropMake;
  StatusMsg := 'Action d'#130'plac'#130'e.';
  Changed;
  SetTitle;
End;

Procedure ToggleOff(N : LongInt);
Begin
  If (N <= 0) Or (NKind[N] = kTrigger) Or (RunState <> rsIdle) Then Exit;
  PropPoll;
  Snapshot;
  NOff[N] := Not NOff[N];
  If NOff[N] Then StatusMsg := 'Action d'#130'sactiv'#130'e : elle sera ignor'#130'e.'
  Else StatusMsg := 'Action activ'#130'e.';
  Changed;
  SetTitle;
End;

{ ==================================================================== }
{ Fichiers                                                              }
{ ==================================================================== }

Function SaveTo(Name : String) : Boolean;
Var B : TBuf; Ok : Boolean;
Begin
  PropPoll;
  BufInit(B);
  EmitFlow(B);
  Ok := WriteAll(Name, B.P, B.Len);
  If Not Ok Then MsgErr('Impossible d'''#130'crire ' + Name + '.')
  Else
  Begin
    CurFile := Name;
    Modified := False;
    StatusMsg := 'Flux enregistr'#130' dans ' + Name + ' (' + IStr(B.Len) + ' octets de Pascal).';
  End;
  BufFree(B);
  SetTitle;
  Redraw;
  SaveTo := Ok;
End;

Function SaveAsDlg : Boolean;
Var N : String;
Begin
  SaveAsDlg := False;
  DlgReset;
  If CurFile <> '' Then N := CurFile Else N := JoinPath(CurDir, ToIdent(FlowName) + '.pf');
  DlgField('Enregistrer le flux sous (fichier .pf) :', N);
  If Not InputBox('Enregistrer le flux sous', 'Enregistrer') Then Exit;
  N := Trim(DgV[0]);
  If N = '' Then Exit;
  If ExtOf(N) = '' Then N := N + '.pf';
  If (Length(N) < 2) Or (N[2] <> ':') Then N := JoinPath(CurDir, N);
  SaveAsDlg := SaveTo(N);
End;

Function SaveCur : Boolean;
Begin
  If CurFile = '' Then SaveCur := SaveAsDlg Else SaveCur := SaveTo(CurFile);
End;

{ enregistrer les modifications avant de les perdre ? }
Function CanDiscard : Boolean;
Var R : LongInt;
Begin
  CanDiscard := True;
  PropPoll;
  If Not Modified Then Exit;
  R := Ask3('Le flux ' + FlowName + ' a '#130't'#130' modifi'#130'. L''enregistrer ?');
  If R = MBID_CANCEL Then CanDiscard := False
  Else If R = MBID_YES Then CanDiscard := SaveCur;
End;

Procedure AfterLoad;
Begin
  UndoClear;
  ClearRun;
  RunSummary := '';
  Sel := -1; ScrX := 0; ScrY := 0; CodeTop := 0;
  Modified := False;
  { la colonne principale du flux au milieu de la vue }
  Layout;
  ScrX := MaxI(0, FlowCX - (VsX - CX0) Div 2);
  If CodeMode Then CodeBuild;
  PropMake;
  SetTitle;
  Redraw;
End;

Function OpenFile(N : String) : Boolean;
Var B : TBuf; E : String;
Begin
  OpenFile := False;
  BufInit(B);
  If Not ReadAll(N, B) Then
  Begin
    MsgErr('Fichier introuvable : ' + N);
    BufFree(B);
    Exit;
  End;
  NReset;
  FlowName := NameOf(N);
  If Pos('.', FlowName) > 0 Then FlowName := Copy(FlowName, 1, Pos('.', FlowName) - 1);
  E := ParseInto(B, 0, 0);
  BufFree(B);
  EnsureTrigger;
  CurFile := N;
  AfterLoad;
  If E <> '' Then MsgErr(NameOf(N) + ' : ' + E + '. Le flux a '#130't'#130' lu jusqu'''#133' cette erreur.')
  Else
  Begin
    StatusMsg := NameOf(N) + ' ouvert (' + IStr(NCount) + ' action(s)).';
    OpenFile := True;
  End;
End;

Procedure OpenDlg;
Var N : String;
Begin
  If Not CanDiscard Then Exit;
  DlgReset;
  DlgField('Ouvrir le flux (fichier .pf) :', JoinPath(CurDir, ''));
  If Not InputBox('Ouvrir un flux', 'Ouvrir') Then Exit;
  N := Trim(DgV[0]);
  If N = '' Then Exit;
  If (Length(N) < 2) Or (N[2] <> ':') Then N := JoinPath(CurDir, N);
  If (ExtOf(N) = '') And FExists(N + '.pf') Then N := N + '.pf';
  Dummy := Ord(OpenFile(N));
End;

{ ==================================================================== }
{ Exemples                                                              }
{ ==================================================================== }

Var
  SmB : TBuf;

Procedure L(S : String);
Begin
  BufAdd(SmB, S);
  BufAddC(SmB, 13); BufAddC(SmB, 10);
End;

Procedure Sample(I : LongInt);
Begin
  If Not CanDiscard Then Exit;
  BufInit(SmB);
  Case I Of
    1 :
      Begin
        L('Program Bonjour;');
        L('Begin');
        L('  { @ D'#130'clencher manuellement un flux }');
        L('  DeclencherManuellement(''Nom'');');
        L('  { @ Initialiser le message }');
        L('  InitialiserVariable(''Message'', ''Cha'#140'ne'', ''Bonjour @{Nom} !'');');
        L('  { @ Le nom est-il vide ? }');
        L('  If Condition(''@{Nom}'', ''est vide'', '''') Then');
        L('  Begin');
        L('    { @ Message pour tout le monde }');
        L('    DefinirVariable(''Message'', ''Bonjour tout le monde !'');');
        L('  End');
        L('  Else');
        L('  Begin');
        L('    { @ Nom en majuscules }');
        L('    Composer(''@{toUpper(Nom)}'', ''NomMaj'');');
        L('    { @ Noter le nom }');
        L('    EcrireJournal(''Nom saisi : @{NomMaj}'');');
        L('  End;');
        L('  { @ Afficher le message }');
        L('  AfficherMessage(''PascalFlow'', ''@{Message}'');');
        L('End.');
      End;
    2 :
      Begin
        L('Program Compter;');
        L('Begin');
        L('  { @ D'#130'clencher manuellement un flux }');
        L('  DeclencherManuellement;');
        L('  { @ Initialiser le compteur }');
        L('  InitialiserVariable(''Compteur'', ''Entier'', ''0'');');
        L('  { @ Initialiser le total }');
        L('  InitialiserVariable(''Total'', ''Entier'', ''0'');');
        L('  { @ Initialiser les nombres pairs }');
        L('  InitialiserVariable(''Pairs'', ''Liste'', '''');');
        L('  { @ Faire jusqu'''#133' 10 }');
        L('  Repeat');
        L('    { @ Compteur + 1 }');
        L('    IncrementerVariable(''Compteur'', ''1'');');
        L('    { @ Additionner }');
        L('    DefinirVariable(''Total'', ''@{Total + Compteur}'');');
        L('    { @ Nombre pair ? }');
        L('    If Condition(''@{Compteur mod 2}'', ''='', ''0'') Then');
        L('    Begin');
        L('      { @ Garder le nombre pair }');
        L('      AjouterAVariable(''Pairs'', ''@{Compteur}'');');
        L('    End');
        L('    Else');
        L('    Begin');
        L('    End;');
        L('  Until Condition(''@{Compteur}'', ''>='', ''10'') Or Limite(''60'');');
        L('  { @ '#144'crire le r'#130'sultat }');
        L('  EcrireFichier(''D:\COMPTER.TXT'', ''Total = @{Total}, pairs : @{Pairs}'');');
        L('  { @ Afficher le total }');
        L('  AfficherMessage(''Compter'', ''La somme de 1 '#133' 10 est @{Total}. Pairs : @{Pairs}.'');');
        L('End.');
      End;
    3 :
      Begin
        L('Program Inventaire;');
        L('Begin');
        L('  { @ D'#130'clencher manuellement un flux }');
        L('  DeclencherManuellement(''Dossier'');');
        L('  { @ Dossier par d'#130'faut }');
        L('  If Condition(''@{Dossier}'', ''est vide'', '''') Then');
        L('  Begin');
        L('    { @ Racine de C: }');
        L('    DefinirVariable(''Dossier'', ''C:\'');');
        L('  End');
        L('  Else');
        L('  Begin');
        L('  End;');
        L('  { @ Lister les programmes }');
        L('  ListerFichiers(''@{Dossier}'', ''*.EXE'', ''Programmes'');');
        L('  { @ Initialiser le rapport }');
        L('  InitialiserVariable(''Rapport'', ''Cha'#140'ne'', ''Programmes de @{Dossier} :''#13#10);');
        L('  { @ Initialiser le nombre }');
        L('  InitialiserVariable(''Nombre'', ''Entier'', ''0'');');
        L('  { @ Pour chaque programme }');
        L('  For Programme In Liste(''@{Programmes}'') Do');
        L('  Begin');
        L('    { @ Ajouter au rapport }');
        L('    AjouterAVariable(''Rapport'', ''  @{Programme}''#13#10);');
        L('    { @ Compter }');
        L('    IncrementerVariable(''Nombre'', ''1'');');
        L('  End;');
        L('  { @ Date du rapport }');
        L('  DateHeure(''Quand'', ''JJ/MM/AAAA hh:mm'');');
        L('  { @ '#144'crire le rapport }');
        L('  EcrireFichier(''D:\INVENT.TXT'', ''@{Rapport}(@{Nombre} programmes, @{Quand})'');');
        L('  { @ Afficher le r'#130'sum'#130' }');
        L('  AfficherMessage(''Inventaire'', ''@{Nombre} programmes dans @{Dossier} ; rapport : D:\INVENT.TXT'');');
        L('End.');
      End;
  End;
  LoadFrom(SmB);
  BufFree(SmB);
  CurFile := '';
  AfterLoad;
  Modified := True;
  SetTitle;
  StatusMsg := 'Exemple charg'#130' : Tester (F5) pour l''ex'#130'cuter pas '#133' pas.';
End;

{ ==================================================================== }
{ Verification, variables, journal, aide                                }
{ ==================================================================== }

Var
  ChkB : TBuf;
  ChkN, ChkFirst : LongInt;

Procedure ChkAdd(N : LongInt; S : String);
Begin
  If ChkN < 30 Then BufAdd(ChkB, '- ' + NTitle[N] + ' : ' + S + #13#10);
  Inc(ChkN);
  If ChkFirst < 0 Then ChkFirst := N;
End;

Function VarInited(S : String) : Boolean;
Var K : LongInt;
Begin
  VarInited := False;
  For K := 1 To MaxN - 1 Do
    If NUsed[K] And (NKind[K] = kInitVar) And (UpStr(Trim(PGet(K, 0))) = UpStr(S)) Then
    Begin
      VarInited := True;
      Exit;
    End;
End;

Procedure ChkList(P, B : LongInt);
Var N, K : LongInt; S : String;
Begin
  N := NFirst(P, B);
  While N >= 0 Do
  Begin
    If Not NOff[N] Then
    Begin
      Case NKind[N] Of
        kInitVar, kSetVar, kIncVar, kDecVar, kAppend :
          Begin
            S := Trim(PGet(N, 0));
            If S = '' Then ChkAdd(N, 'nom de variable vide.')
            Else If (NKind[N] <> kInitVar) And Not VarInited(S) Then
              ChkAdd(N, 'la variable ' + S + ' n''est initialis'#130'e nulle part.');
          End;
        kReadFile, kWriteFile, kDelFile, kMkDir, kCopyFile, kRun :
          If Trim(PGet(N, 0)) = '' Then ChkAdd(N, KPar(NKind[N], 0) + ' vide.');
        kForEach :
          If Trim(PGet(N, 1)) = '' Then ChkAdd(N, 'nom de l'''#130'l'#130'ment vide.');
        kWait :
          If Trim(PGet(N, 0)) = '' Then ChkAdd(N, 'dur'#130'e vide.');
      End;
      If NBranches(N) > 0 Then ChkList(N, 0);
      If NBranches(N) > 1 Then ChkList(N, 1);
    End;
    N := NNext[N];
  End;
End;

Procedure CheckFlow;
Begin
  PropPoll;
  BufInit(ChkB);
  ChkN := 0; ChkFirst := -1;
  ChkList(0, 0);
  If ChkN = 0 Then Msg('Aucun probl'#138'me trouv'#130' dans le flux ' + FlowName + ' (' + IStr(NCount) + ' actions).')
  Else
  Begin
    BufAdd(ChkB, IStr(ChkN) + ' probl'#138'me(s).');
    Select(ChkFirst);
    ShowBuf('PascalFlow - V'#130'rifier le flux', ChkB);
  End;
  BufFree(ChkB);
End;

Procedure ShowVars;
Var B : TBuf; K : LongInt;
Begin
  BufInit(B);
  If NVar = 0 Then BufAdd(B, 'Aucune variable : ex'#130'cutez d''abord le flux.')
  Else
    For K := 0 To NVar - 1 Do BufAdd(B, VName[K] + ' = ' + Copy(VarS(K), 1, 120) + #13#10);
  ShowBuf('PascalFlow - Variables', B);
  BufFree(B);
End;

Procedure ShowHelp(Which : LongInt);
Begin
  BufInit(HelpBuf);
  Case Which Of
    0 :
      Begin
        BufAdd(HelpBuf, 'PascalFlow : un flux est une suite d''actions reli'#130'es par des fl'#138'ches. Il commence par ');
        BufAdd(HelpBuf, 'son d'#130'clencheur (D'#130'clencher manuellement un flux).' + #13#10#13#10);
        BufAdd(HelpBuf, 'Ajouter : cliquez une action de la barre de gauche (elle se place apr'#138's l''action ');
        BufAdd(HelpBuf, 'choisie), glissez-la sur un +, ou cliquez un + des fl'#138'ches. Une Condition a deux ');
        BufAdd(HelpBuf, 'branches, Vrai et Faux ; Appliquer '#133' chacun et Faire jusqu'''#133' r'#130'p'#138'tent leurs ');
        BufAdd(HelpBuf, 'actions.' + #13#10#13#10);
        BufAdd(HelpBuf, 'Bouton 2 ou ... sur une carte : copier, couper, coller, dupliquer, supprimer, monter, ');
        BufAdd(HelpBuf, 'descendre, d'#130'sactiver. Une carte se glisse sur un + pour la d'#130'placer. '#133' droite, ');
        BufAdd(HelpBuf, 'les propri'#130't'#130's de l''action choisie.' + #13#10#13#10);
        BufAdd(HelpBuf, 'Tester (F5) ex'#130'cute le flux pas '#133' pas, Ex'#130'cuter (Ctrl+F5) d''un trait : un ');
        BufAdd(HelpBuf, 'crochet vert marque les actions r'#130'ussies, un X rouge celle qui a '#130'chou'#130' ou arr'#136't'#130' ');
        BufAdd(HelpBuf, 'le flux. Un flux ne s''ex'#130'cute qu'''#133' la main, tant que PascalFlow est ouvert.' + #13#10#13#10);
        BufAdd(HelpBuf, 'Le fichier .pf est un programme Pascal (F12 : Code Pascal).');
      End;
    1 :
      Begin
        BufAdd(HelpBuf, 'Dans une valeur, @{...} est remplac'#130' par sa valeur : @{Compteur} (une variable), ');
        BufAdd(HelpBuf, '@{Total + Compteur}, @{Nom & ''!''}, @{Compteur mod 2}, @{Prix * 2 >= 10 and Actif}.' + #13#10#13#10);
        BufAdd(HelpBuf, 'Op'#130'rateurs : + - * / mod, & (concat'#130'nation), = <> < > <= >=, and, or, not.' + #13#10#13#10);
        BufAdd(HelpBuf, 'Fonctions : concat, length, toUpper, toLower, trim, substring(s, d'#130'but, n), ');
        BufAdd(HelpBuf, 'replace(s, a, b), indexOf, contains, startsWith, endsWith, add, sub, mul, div, mod, ');
        BufAdd(HelpBuf, 'min, max, int, if(c, a, b), equals, not, and, or, empty, utcNow(''AAAA-MM-JJ''), ');
        BufAdd(HelpBuf, 'count(liste), item(liste, i), first, last, rand(a, b), variables(''nom'').' + #13#10#13#10);
        BufAdd(HelpBuf, 'Une liste est une suite de valeurs s'#130'par'#130'es par ; ou par des fins de ligne.');
      End;
  Else
    BufAdd(HelpBuf, 'PascalFlow pour OS/2-0, version 1.0' + #13#10#13#10);
    BufAdd(HelpBuf, 'Flux d''automatisation dans l''esprit de Power Automate, avec l''apparence d''OS/2. ');
    BufAdd(HelpBuf, 'Les flux sont enregistr'#130's en Pascal (fichiers .pf).');
  End;
  If Which = 0 Then ShowBuf('PascalFlow - Aide', HelpBuf)
  Else If Which = 1 Then ShowBuf('PascalFlow - Expressions', HelpBuf)
  Else ShowBuf('A propos de PascalFlow', HelpBuf);
  BufFree(HelpBuf);
End;

{ ==================================================================== }
{ Execution                                                             }
{ ==================================================================== }

Procedure DoRun(Test : Boolean);
Begin
  If RunState <> rsIdle Then Exit;
  PropPoll;
  If CodeMode Then
  Begin
    CodeMode := False;
    SetCheck(cmCode, False);
    PropMake;
  End;
  StartRun(Test);
  NextStep := PTicks;
  If Test Then StatusMsg := 'Test du flux pas '#133' pas...' Else StatusMsg := 'Ex'#130'cution du flux...';
  Redraw;
End;

{ etats des actions pour /OUT }
Procedure StatusList(Var B : TBuf; P, Br, Ind : LongInt);
Var N, K : LongInt; S, Id : String;
Begin
  N := NFirst(P, Br);
  Id := '';
  For K := 1 To Ind Do Id := Id + '  ';
  While N >= 0 Do
  Begin
    S := Id;
    Case NSt[N] Of
      stOk : S := S + '[v] ';
      stFail : S := S + '[X] ';
      stSkip : S := S + '[-] ';
    Else
      S := S + '[ ] ';
    End;
    BufAdd(B, S + NTitle[N]);
    If NOut[N] <> '' Then BufAdd(B, ' : ' + NOut[N]);
    BufAddC(B, 13); BufAddC(B, 10);
    If NBranches(N) > 0 Then StatusList(B, N, 0, Ind + 1);
    If NBranches(N) > 1 Then
    Begin
      BufAdd(B, Id + '    (Faux)' + #13#10);
      StatusList(B, N, 1, Ind + 1);
    End;
    N := NNext[N];
  End;
End;

Procedure WriteOut;
Var B : TBuf;
Begin
  BufInit(B);
  BufAddB(B, RunLog.P, RunLog.Len);
  BufAdd(B, '== Actions' + #13#10);
  StatusList(B, 0, 0, 0);
  Dummy := Ord(WriteAll(OutFile, B.P, B.Len));
  BufFree(B);
End;

{ minuterie de l'execution }
Procedure RunTick;
Var T0 : LongInt; Was : Boolean;
Begin
  If (RunState = rsIdle) Or RunBusy Then Exit;
  RunBusy := True;
  Was := RunState <> rsIdle;
  If RunTest Then
  Begin
    If (RunState = rsWait) Or (PTicks >= NextStep) Then
    Begin
      StepRun;
      NextStep := PTicks + 350;
      If (RunNode > 0) And NUsed[RunNode] Then
      Begin
        If Sel <> RunNode Then
        Begin
          PropPoll;
          Sel := RunNode;
          PropMake;
        End;
        ShowSel;
      End;
      Redraw;
    End;
  End
  Else
  Begin
    T0 := PTicks;
    While (RunState = rsRun) And (PTicks - T0 < 40) Do StepRun;
    If RunState = rsWait Then StepRun;
    Redraw;
  End;
  If Was And (RunState = rsIdle) Then
  Begin
    If RunOk Then StatusMsg := 'Termin'#130' : toutes les actions ex'#130'cut'#130'es ont un crochet vert.'
    Else StatusMsg := 'Le X rouge marque l''action qui a '#130'chou'#130' ; cliquez-la pour voir pourquoi.';
    PropMake;
    Redraw;
    If AutoRun And (OutFile <> '') Then
    Begin
      WriteOut;
      Dummy := WinPostMsg(Client, WM_QUIT, 0, 0);
    End;
  End;
  RunBusy := False;
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Procedure CtxNode(N, X, Y : LongInt); Forward;

Procedure DoCmd(C : LongInt);
Var S : String; T : LongInt;
Begin
  Case C Of
    cmNew :
      If CanDiscard And (RunState = rsIdle) Then
      Begin
        NewFlow;
        CurFile := '';
        AfterLoad;
        StatusMsg := 'Nouveau flux.';
      End;
    cmOpen : If RunState = rsIdle Then OpenDlg;
    cmSave : Dummy := Ord(SaveCur);
    cmSaveAs : Dummy := Ord(SaveAsDlg);
    cmQuit : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    cmUndo : UndoRedo(False);
    cmRedo : UndoRedo(True);
    cmCopy : CopyNode(Sel);
    cmCut :
      If (Sel > 0) And (NKind[Sel] <> kTrigger) Then
      Begin
        CopyNode(Sel);
        DeleteNode(Sel);
        StatusMsg := 'Action coup'#130'e.';
      End;
    cmPaste :
      If Sel > 0 Then PasteAt(NParent[Sel], NBr[Sel], Sel) Else PasteAt(0, 0, NLast(0, 0));
    cmPasteHere : PasteAt(PendP, PendB, PendA);
    cmDelete : DeleteNode(Sel);
    cmDup : DupNode(Sel);
    cmUp : MoveNode(Sel, False);
    cmDown : MoveNode(Sel, True);
    cmToggleOff : ToggleOff(Sel);
    cmRename :
      If (PropN > 0) And (PropEf[0] <> 0) Then Dummy := WinSetFocus(HWND_DESKTOP, PropEf[0]);
    cmShowPal :
      Begin
        ShowPal := Not ShowPal;
        SetCheck(cmShowPal, ShowPal);
        Redraw;
        PropMake;
      End;
    cmShowProp :
      Begin
        PropPoll;
        ShowProp := Not ShowProp;
        SetCheck(cmShowProp, ShowProp);
        PropMake;
        Redraw;
      End;
    cmCode :
      Begin
        PropPoll;
        CodeMode := Not CodeMode;
        SetCheck(cmCode, CodeMode);
        If CodeMode Then
        Begin
          CodeBuild;
          CodeTop := 0;
          StatusMsg := 'Code Pascal du flux, tel qu''il est enregistr'#130' dans le fichier .pf (F12 : retour au flux).';
        End;
        PropMake;
        Redraw;
      End;
    cmFit :
      Begin
        ScrX := 0; ScrY := 0; CodeTop := 0;
        Redraw;
      End;
    cmTest : DoRun(True);
    cmRun : DoRun(False);
    cmStop :
      If RunState <> rsIdle Then
      Begin
        StopAsked := True;
        If Not RunBusy Then StopRun;
        StatusMsg := 'Ex'#130'cution arr'#136't'#130'e.';
        PropMake;
        Redraw;
      End;
    cmClearRes :
      Begin
        ClearRun;
        RunSummary := '';
        Redraw;
      End;
    cmLog :
      Begin
        If RunLog.Len = 0 Then Msg('Le flux n''a pas encore '#130't'#130' ex'#130'cut'#130'.')
        Else ShowBuf('PascalFlow - Journal de la derni'#138're ex'#130'cution', RunLog);
      End;
    cmCheck : CheckFlow;
    cmVars : ShowVars;
    cmFlowProps :
      Begin
        PropPoll;
        DlgReset;
        DlgField('Nom du flux (nom du programme Pascal) :', FlowName);
        If InputBox('Propri'#130't'#130's du flux', 'OK') And (Trim(DgV[0]) <> '') And (Trim(DgV[0]) <> FlowName) Then
        Begin
          Snapshot;
          FlowName := Trim(DgV[0]);
          Changed;
          PropMake;
          SetTitle;
        End;
      End;
    cmHelp : ShowHelp(0);
    cmExpr : ShowHelp(1);
    cmAbout : ShowHelp(2);
    cmSample1, cmSample2, cmSample3 : Sample(C - cmSample1 + 1);
  Else
    If (C > cmAddFirst) And (C <= cmAddFirst + NKinds) Then
    Begin
      If MenuNode > 0 Then AddAt(C - cmAddFirst, NParent[MenuNode], NBr[MenuNode], MenuNode)
      Else AddKind(C - cmAddFirst);
      MenuNode := -1;
    End
    Else If (C > cmInsFirst) And (C <= cmInsFirst + NKinds) Then AddAt(C - cmInsFirst, PendP, PendB, PendA)
    Else If (C >= cmEnumFirst) And (C < cmEnumFirst + 20) And (Sel > 0) And (PendEnum >= 0) Then
    Begin
      S := EnumItem(KEnum(NKind[Sel], PendEnum), C - cmEnumFirst);
      If S <> PGet(Sel, PendEnum) Then
      Begin
        PropPoll;
        Snapshot;
        PSet(Sel, PendEnum, S);
        Changed;
        SetTitle;
      End;
    End;
  End;
  If (C <> cmTest) And (C <> cmRun) Then T := 0;
  SetTitle;
  InvalBand(0, CH - SbH, CW, CH);
  InvalBand(0, 0, CW, TbH);
End;

{ menu de l'action N (bouton 2 ou ...) }
Procedure CtxNode(N, X, Y : LongInt);
Var H : LongInt; Tr, Dis : LongInt;
Begin
  MenuLen := 0;
  MenuNode := N;
  H := MenuOpen;
  If NKind[N] = kTrigger Then Tr := MIA_DISABLED Else Tr := 0;
  If RunState <> rsIdle Then Dis := MIA_DISABLED Else Dis := 0;
  ItA(cmCopy, Tr, 'C~opier' + #9 + 'Ctrl+C');
  ItA(cmCut, Tr Or Dis, '~Couper' + #9 + 'Ctrl+X');
  ItA(cmPaste, Dis, 'Co~ller apr'#138's' + #9 + 'Ctrl+V');
  ItA(cmDup, Tr Or Dis, '~Dupliquer' + #9 + 'Ctrl+D');
  ItA(cmDelete, Tr Or Dis, '~Supprimer' + #9 + 'Suppr');
  Sep;
  ItA(cmUp, Tr Or Dis, '~Monter' + #9 + 'Ctrl+Haut');
  ItA(cmDown, Tr Or Dis, 'D~escendre' + #9 + 'Ctrl+Bas');
  If NOff[N] Then ItA(cmToggleOff, Tr Or Dis, '~Activer l''action') Else ItA(cmToggleOff, Tr Or Dis, 'D'#130's~activer l''action');
  It(cmRename, '~Renommer' + #9 + 'F2');
  Sep;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 87, 'Ajouter une action a~pr'#138's');
  H := MenuOpen;
  KindMenus(cmAddFirst);
  MenuClose(H);
  MenuClose(0);
  ShowPopup(X, Y, cmCopy);
End;

{ menu d'un + : inserer une action a cet endroit }
Procedure CtxPlus(I, X, Y : LongInt);
Var H : LongInt;
Begin
  If (RunState <> rsIdle) Or (I < 0) Then Exit;
  PendP := IPP[I]; PendB := IPB[I]; PendA := IPA[I];
  MenuLen := 0;
  H := MenuOpen;
  KindMenus(cmInsFirst);
  Sep;
  It(cmPasteHere, 'Co~ller ici' + #9 + 'Ctrl+V');
  MenuClose(H);
  ShowPopup(X, Y, cmInsFirst + kInitVar);
End;

Procedure CtxCanvas(X, Y : LongInt);
Var H : LongInt;
Begin
  MenuLen := 0;
  MenuNode := -1;
  H := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 86, '~Ajouter une action '#133' la fin');
  H := MenuOpen;
  KindMenus(cmAddFirst);
  MenuClose(H);
  It(cmPaste, 'Co~ller '#133' la fin' + #9 + 'Ctrl+V');
  Sep;
  It(cmTest, '~Tester' + #9 + 'F5');
  It(cmRun, '~Ex'#130'cuter manuellement' + #9 + 'Ctrl+F5');
  Sep;
  It(cmCode, '~Code Pascal' + #9 + 'F12');
  It(cmFit, '~Haut du flux');
  MenuClose(0);
  ShowPopup(X, Y, cmTest);
End;

Procedure CtxEnum(K, X, Y : LongInt);
Var H, I : LongInt; E : String;
Begin
  If (Sel <= 0) Or (PropPar[K] < 0) Then Exit;
  PendEnum := PropPar[K];
  E := KEnum(NKind[Sel], PendEnum);
  MenuLen := 0;
  H := MenuOpen;
  For I := 0 To EnumCount(E) - 1 Do
    ItA(cmEnumFirst + I, Chk(EnumItem(E, I) = PGet(Sel, PendEnum)), EnumItem(E, I));
  MenuClose(H);
  ShowPopup(X, Y, cmEnumFirst);
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
    If (TbCmd[I] <> 0) And (X >= TbX[I]) And (X < TbX[I] + TbW[I]) Then TbHit := I;
End;

Function InCanvas(X, Y : LongInt) : Boolean;
Begin
  InCanvas := (X >= CX0) And (X < VsX) And (Y >= Y0) And (Y < HsY);
End;

{ + sous la souris (Near : tolerance du glisser-deposer) }
Function IPHit(X, Y, Near : LongInt) : LongInt;
Var I, Fx, Fy, D, Best, BD : LongInt;
Begin
  IPHit := -1;
  If Not InCanvas(X, Y) Or CodeMode Then Exit;
  Fx := X - CX0 + ScrX; Fy := Y - Y0 + ScrY;
  Best := -1; BD := Near * Near + 1;
  For I := 0 To NIP - 1 Do
  Begin
    D := (Fx - IPX[I]) * (Fx - IPX[I]) + (Fy - IPY[I]) * (Fy - IPY[I]);
    If D < BD Then
    Begin
      BD := D; Best := I;
    End;
  End;
  IPHit := Best;
End;

Function CardHit(X, Y : LongInt) : LongInt;
Var N, Fx, Fy : LongInt;
Begin
  CardHit := -1;
  If Not InCanvas(X, Y) Or CodeMode Then Exit;
  Fx := X - CX0 + ScrX; Fy := Y - Y0 + ScrY;
  For N := 1 To MaxN - 1 Do
    If NUsed[N] And (NParent[N] >= 0) And (Fx >= NX[N]) And (Fx < NX[N] + CardW) And (Fy >= NY[N]) And
       (Fy < NY[N] + CardH) Then
    Begin
      CardHit := N;
      Exit;
    End;
End;

Function PalHit(X, Y : LongInt) : LongInt;
Var I : LongInt;
Begin
  PalHit := -1;
  If Not ShowPal Or (X >= PalW) Or (Y < Y0 + 24) Or (Y > Y1) Then Exit;
  I := PalTop + (Y - Y0 - 24) Div PalRowH;
  If (I < NPal) And (PalK[I] > 0) Then PalHit := I;
End;

Procedure ScrollBy(Dx, Dy : LongInt);
Begin
  If CodeMode Then
  Begin
    CodeTop := MaxI(0, CodeTop + Dy Div 16);
    If CodeTop > MaxI(0, CodeN - 4) Then CodeTop := MaxI(0, CodeN - 4);
  End
  Else
  Begin
    ScrX := ScrX + Dx; ScrY := ScrY + Dy;
    Layout;
  End;
  InvalCanvas;
End;

{ clic dans les barres de defilement du flux }
Function ScrollClick(X, Y : LongInt) : Boolean;
Var T, Th, Tp, Max_, Page : LongInt;
Begin
  ScrollClick := False;
  If (X >= VsX) And (X <= CX1) And (Y >= Y0) And (Y < HsY) Then
  Begin
    ScrollClick := True;
    Page := HsY - Y0;
    If Y < Y0 + ScrW Then ScrollBy(0, -32)
    Else If Y >= HsY - ScrW Then ScrollBy(0, 32)
    Else
    Begin
      T := HsY - Y0 - 2 * ScrW;
      Max_ := MaxI(0, FlowH - Page);
      If (Max_ = 0) Or CodeMode Then
      Begin
        If Y < (Y0 + HsY) Div 2 Then ScrollBy(0, -Page + 32) Else ScrollBy(0, Page - 32);
        Exit;
      End;
      Th := MaxI(12, T * Page Div FlowH);
      Tp := Y0 + ScrW + (T - Th) * ScrY Div Max_;
      If Y < Tp Then ScrollBy(0, -Page + 32)
      Else If Y >= Tp + Th Then ScrollBy(0, Page - 32)
      Else
      Begin
        Drag := dVThumb; DragOff := Y - Tp;
        Dummy := WinSetCapture(HWND_DESKTOP, Client);
      End;
    End;
  End
  Else If (Y >= HsY) And (Y <= Y1) And (X >= CX0) And (X < VsX) Then
  Begin
    ScrollClick := True;
    Page := VsX - CX0;
    If X < CX0 + ScrW Then ScrollBy(-32, 0)
    Else If X >= VsX - ScrW Then ScrollBy(32, 0)
    Else
    Begin
      T := VsX - CX0 - 2 * ScrW;
      Max_ := MaxI(0, FlowW - Page);
      If Max_ = 0 Then Exit;
      Th := MaxI(12, T * Page Div FlowW);
      Tp := CX0 + ScrW + (T - Th) * ScrX Div Max_;
      If X < Tp Then ScrollBy(-Page + 32, 0)
      Else If X >= Tp + Th Then ScrollBy(Page - 32, 0)
      Else
      Begin
        Drag := dHThumb; DragOff := X - Tp;
        Dummy := WinSetCapture(HWND_DESKTOP, Client);
      End;
    End;
  End;
End;

Procedure Click(X, Y : LongInt; Dbl : Boolean);
Var I, N, K, W : LongInt;
Begin
  LastMx := X; LastMy := Y;
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
  If Y > Y1 Then Exit;
  { palette }
  If ShowPal And (X < PalW) Then
  Begin
    I := PalHit(X, Y);
    If I >= 0 Then
    Begin
      Drag := dPalWait; DragKind := PalK[I]; DragX0 := X; DragY0 := Y;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
    End;
    Exit;
  End;
  { volet des proprietes : listes de choix }
  If ShowProp And (X >= PX0) Then
  Begin
    W := PropW - 26;
    For K := 0 To PropN - 1 Do
      If PropIsEnum(K) And (X >= PX0 + 12) And (X < PX0 + 12 + W) And (Y >= PropY[K] + 18) And (Y < PropY[K] + 40) Then
        CtxEnum(K, PX0 + 12, PropY[K] + 40);
    Exit;
  End;
  If ScrollClick(X, Y) Then Exit;
  If Not InCanvas(X, Y) Or CodeMode Then Exit;
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  I := IPHit(X, Y, 10);
  If I >= 0 Then
  Begin
    CtxPlus(I, X, Y);
    Exit;
  End;
  N := CardHit(X, Y);
  If N > 0 Then
  Begin
    If N <> Sel Then Select(N);
    { bouton ... de la carte }
    If (X - CX0 + ScrX >= NX[N] + CardW - 26) And (Y - Y0 + ScrY < NY[N] + 18) Then
    Begin
      CtxNode(N, X, Y);
      Exit;
    End;
    If Dbl Then
    Begin
      DoCmd(cmRename);
      Exit;
    End;
    If NKind[N] <> kTrigger Then
    Begin
      Drag := dCardWait; DragNode := N; DragX0 := X; DragY0 := Y;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
    End;
    Exit;
  End;
  { fond : deplacer la vue }
  If Sel <> -1 Then Select(-1);
  Drag := dPan; DragX0 := X; DragY0 := Y; DragSX := ScrX; DragSY := ScrY;
  Dummy := WinSetCapture(HWND_DESKTOP, Client);
End;

Procedure MouseMove(X, Y : LongInt);
Var I, T, Th, Max_, Page, Old : LongInt;
Begin
  Case Drag Of
    dPalWait, dCardWait :
      If Abs(X - DragX0) + Abs(Y - DragY0) > 6 Then
      Begin
        If Drag = dPalWait Then Drag := dPal Else Drag := dCard;
        StatusMsg := 'D'#130'posez l''action sur un + du flux.';
        InvalBand(0, CH - SbH, CW, CH);
      End;
    dPal, dCard :
      Begin
        Old := DropIP;
        DropIP := IPHit(X, Y, 40);
        If (Drag = dCard) And (DropIP >= 0) Then
          If IsAncestor(DragNode, IPP[DropIP]) Then DropIP := -1;
        If Y < Y0 + 10 Then ScrollBy(0, -16) Else If (Y > HsY - 10) And (Y < Y1) Then ScrollBy(0, 16);
        If Old <> DropIP Then InvalCanvas;
      End;
    dPan :
      Begin
        ScrX := DragSX - (X - DragX0); ScrY := DragSY - (Y - DragY0);
        Layout;
        InvalCanvas;
      End;
    dVThumb :
      Begin
        Page := HsY - Y0;
        T := HsY - Y0 - 2 * ScrW;
        Max_ := MaxI(0, FlowH - Page);
        Th := MaxI(12, T * Page Div MaxI(1, FlowH));
        If (T - Th > 0) And (Max_ > 0) Then
        Begin
          ScrY := (Y - DragOff - Y0 - ScrW) * Max_ Div (T - Th);
          Layout;
          InvalCanvas;
        End;
      End;
    dHThumb :
      Begin
        Page := VsX - CX0;
        T := VsX - CX0 - 2 * ScrW;
        Max_ := MaxI(0, FlowW - Page);
        Th := MaxI(12, T * Page Div MaxI(1, FlowW));
        If (T - Th > 0) And (Max_ > 0) Then
        Begin
          ScrX := (X - DragOff - CX0 - ScrW) * Max_ Div (T - Th);
          Layout;
          InvalCanvas;
        End;
      End;
  Else
    Begin
      { survol : + et palette en surbrillance }
      I := IPHit(X, Y, 10);
      If I <> HovIP Then
      Begin
        HovIP := I;
        InvalCanvas;
      End;
      I := PalHit(X, Y);
      If I <> HovPal Then
      Begin
        HovPal := I;
        InvalBand(0, Y0, PalW, Y1 + 1);
      End;
      I := -1;
      If Y < TbH Then I := TbHit(X, Y);
      If I <> TbHot Then
      Begin
        TbHot := I;
        If I >= 0 Then StatusMsg := TbTip[I];
        InvalBand(0, 0, CW, TbH);
        InvalBand(0, CH - SbH, CW, CH);
      End;
    End;
  End;
End;

Procedure MouseUp(X, Y : LongInt);
Var I : LongInt;
Begin
  Case Drag Of
    dToolbar :
      Begin
        I := TbHit(X, Y);
        TbDown := -1;
        InvalBand(0, 0, CW, TbH);
        Dummy := WinSetCapture(HWND_DESKTOP, 0);
        Drag := dNone;
        If (I >= 0) Then DoCmd(TbCmd[I]);
        Exit;
      End;
    dPalWait :
      Begin
        Dummy := WinSetCapture(HWND_DESKTOP, 0);
        Drag := dNone;
        I := DragKind;
        DragKind := 0;
        AddKind(I);
        Exit;
      End;
    dPal :
      Begin
        I := DropIP;
        If I >= 0 Then AddAt(DragKind, IPP[I], IPB[I], IPA[I]);
      End;
    dCard : MoveTo(DragNode, DropIP);
  End;
  If Drag <> dNone Then Dummy := WinSetCapture(HWND_DESKTOP, 0);
  If (Drag = dPal) Or (Drag = dCard) Then
  Begin
    StatusMsg := '';
    Redraw;
  End;
  Drag := dNone; DragKind := 0; DragNode := -1; DropIP := -1;
  InvalBand(0, Y0, PalW, Y1 + 1);
End;

Procedure RightClick(X, Y : LongInt);
Var N, I : LongInt;
Begin
  If Not InCanvas(X, Y) Or CodeMode Then Exit;
  I := IPHit(X, Y, 10);
  If I >= 0 Then
  Begin
    CtxPlus(I, X, Y);
    Exit;
  End;
  N := CardHit(X, Y);
  If N > 0 Then
  Begin
    If N <> Sel Then Select(N);
    CtxNode(N, X, Y);
  End
  Else CtxCanvas(X, Y);
End;

{ ==================================================================== }
{ Clavier                                                               }
{ ==================================================================== }

{ action suivante ou precedente dans l'ordre du flux }
Function NextInFlow(N : LongInt) : LongInt;
Var M : LongInt;
Begin
  NextInFlow := -1;
  If N <= 0 Then
  Begin
    NextInFlow := NFirst(0, 0);
    Exit;
  End;
  If (NBranches(N) > 0) And (NFirst(N, 0) >= 0) Then
  Begin
    NextInFlow := NFirst(N, 0);
    Exit;
  End;
  If (NBranches(N) > 1) And (NFirst(N, 1) >= 0) Then
  Begin
    NextInFlow := NFirst(N, 1);
    Exit;
  End;
  M := N;
  While M > 0 Do
  Begin
    If NNext[M] >= 0 Then
    Begin
      NextInFlow := NNext[M];
      Exit;
    End;
    If (NBr[M] = 0) And (NBranches(NParent[M]) > 1) And (NFirst(NParent[M], 1) >= 0) Then
    Begin
      NextInFlow := NFirst(NParent[M], 1);
      Exit;
    End;
    M := NParent[M];
  End;
End;

Function PrevInFlow(N : LongInt) : LongInt;
Var M, K : LongInt;
Begin
  PrevInFlow := -1;
  M := NFirst(0, 0);
  K := -1;
  While (M >= 0) And (M <> N) Do
  Begin
    K := M;
    M := NextInFlow(M);
  End;
  If M = N Then PrevInFlow := K;
End;

Function Key(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch_, Vk, K : LongInt; Ctrl : Boolean;
Begin
  Key := True;
  Fl := Lo16(Mp1); Ch_ := Lo16(Mp2); Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
    Key := False;
    Exit;
  End;
  Ctrl := (Fl And KC_CTRL) <> 0;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    Case Vk Of
      VK_F1 : Begin DoCmd(cmHelp); Exit; End;
      VK_F2 : Begin DoCmd(cmRename); Exit; End;
      VK_F5 :
        Begin
          If Ctrl Then DoCmd(cmRun) Else DoCmd(cmTest);
          Exit;
        End;
      VK_F1 + 6 : Begin DoCmd(cmShowPal); Exit; End;
      VK_F8 : Begin DoCmd(cmShowProp); Exit; End;
      VK_F12 : Begin DoCmd(cmCode); Exit; End;
      VK_ESC : Begin DoCmd(cmStop); Exit; End;
      VK_DELETE : Begin DoCmd(cmDelete); Exit; End;
      VK_HOME :
        Begin
          DoCmd(cmFit);
          Exit;
        End;
      VK_UP, VK_DOWN :
        Begin
          If CodeMode Then
          Begin
            If Vk = VK_UP Then ScrollBy(0, -16) Else ScrollBy(0, 16);
          End
          Else If Ctrl Then DoCmd(cmUp + Ord(Vk = VK_DOWN))
          Else
          Begin
            If Vk = VK_DOWN Then K := NextInFlow(Sel) Else K := PrevInFlow(Sel);
            If K > 0 Then Select(K);
          End;
          Exit;
        End;
      VK_PAGEUP : Begin ScrollBy(0, -(HsY - Y0 - 40)); Exit; End;
      VK_PAGEDOWN : Begin ScrollBy(0, HsY - Y0 - 40); Exit; End;
      VK_LEFT : Begin ScrollBy(-40, 0); Exit; End;
      VK_RIGHT : Begin ScrollBy(40, 0); Exit; End;
      VK_ENTER, VK_NEWLINE :
        Begin
          If (PropN > 1) And (PropEf[1] <> 0) Then Dummy := WinSetFocus(HWND_DESKTOP, PropEf[1])
          Else DoCmd(cmRename);
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
      Ord('z') : Begin DoCmd(cmUndo); Exit; End;
      Ord('y') : Begin DoCmd(cmRedo); Exit; End;
      Ord('x') : Begin DoCmd(cmCut); Exit; End;
      Ord('c') : Begin DoCmd(cmCopy); Exit; End;
      Ord('v') : Begin DoCmd(cmPaste); Exit; End;
      Ord('d') : Begin DoCmd(cmDup); Exit; End;
      Ord('e') : Begin DoCmd(cmToggleOff); Exit; End;
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
        PropPoll;
        Layout;
        PropMake;
        Redraw;
      End;
    WM_PAINT : Paint(H);
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
      Begin
        X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
        If Not (ShowProp And (X >= PX0)) Then
        Begin
          PropPoll;
          Dummy := WinSetFocus(HWND_DESKTOP, H);
        End;
        Click(X, Y, Msg_ = WM_BUTTON1DBLCLK);
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
        If Hi16(Mp2) = SB_LINEUP Then K := -48 Else If Hi16(Mp2) = SB_LINEDOWN Then K := 48;
        If ShowPal And (LastMx < PalW) Then
        Begin
          PalTop := MaxI(0, MinI(NPal - 4, PalTop + K Div 24));
          InvalBand(0, Y0, PalW, Y1 + 1);
        End
        Else ScrollBy(0, K);
      End;
    WM_CHAR :
      If Key(Mp1, Mp2) Then ClientProc := 1
      Else ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
    WM_COMMAND : DoCmd(Lo16(Mp1));
    WM_TIMER :
      If Lo16(Mp1) = 2 Then RunTick
      Else
      Begin
        PropPoll;
        If AutoRun And (RunState = rsIdle) And (RunSteps = 0) And (RunLog.Len = 0) Then DoRun(False);
      End;
    WM_SETFOCUS :
      HasFocus := Lo16(Mp2) <> 0;
    WM_CLOSE :
      Begin
        If RunState <> rsIdle Then
        Begin
          StopAsked := True;
          If Not RunBusy Then StopRun;
        End;
        If AutoRun Or CanDiscard Then Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
      End;
  Else
    ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

Procedure Main;
Var Fl, Sw, Sh, Fw, Fh, K : LongInt; A, U, Fn : String;
Begin
  NewFlow;
  NVar := 0; RndSeed := PTicks;
  BufInit(RunLog); BufInit(ClipB); BufInit(CodeB); CodeLn := Nil; CodeN := 0;
  UndoN := 0; RedoN := 0;
  RunState := rsIdle; RunBusy := False; AutoMode := False; AutoRun := False; RunSummary := ''; RunSteps := 0;
  Sel := -1; HovIP := -1; HovNode := -1; DragKind := 0; DragNode := -1; DropIP := -1; Drag := dNone;
  ShowPal := True; ShowProp := True; CodeMode := False; HasFocus := True;
  ScrX := 0; ScrY := 0; CtxMenu := 0; MenuNode := -1; PendEnum := -1;
  For K := 0 To MaxProp - 1 Do PropEf[K] := 0;
  PropN := 0;
  StatusMsg := 'Pr'#136't. Cliquez une action de la barre de gauche pour l''ajouter au flux.';
  CurFile := ''; OutFile := ''; Fn := '';
  { dossier des flux : C:\, ou D:\ quand C: est le CD-ROM (lecture seule) }
  CurDir := 'C:\';
  If WriteAll('C:\PFTEST.TMP', @CurDir[1], 1) And FExists('C:\PFTEST.TMP') Then
    Dummy := DosDelete(Z('C:\PFTEST.TMP'))
  Else If FExists('D:\') Then CurDir := 'D:\';
  K := 1;
  While K <= ParamCount Do
  Begin
    A := ParamStr(K);
    U := UpStr(A);
    If U = '/RUN' Then AutoRun := True
    Else If (U = '/OUT') And (K < ParamCount) Then
    Begin
      Inc(K);
      OutFile := ParamStr(K);
    End
    Else Fn := A;
    Inc(K);
  End;
  AutoMode := AutoRun And (OutFile <> '');
  ToolbarInit;
  PaletteInit;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('PASCALFLOW'), LongInt(@ClientProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('PASCALFLOW'), Z2('PascalFlow'), 0, 0, 0,
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
  If Fn <> '' Then
  Begin
    If (Length(Fn) < 2) Or (Fn[2] <> ':') Then Fn := JoinPath(CurDir, Fn);
    If (ExtOf(Fn) = '') And FExists(Fn + '.pf') Then Fn := Fn + '.pf';
    If Not OpenFile(Fn) Then AutoRun := False;
  End;
  SetTitle;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Layout;
  PropMake;
  Dummy := WinStartTimer(Hab, Client, 1, 300);
  Dummy := WinStartTimer(Hab, Client, 2, 20);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@GQmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@GQmsg));
  PropKill;
  Dummy := WinDestroyWindow(Frame);
End;

BEGIN
  Main;
END.
