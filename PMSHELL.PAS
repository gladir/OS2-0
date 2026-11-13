{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: PMSHELL.EXE de OS/2-0 : l'interpreteur de Presentation
                Manager (Workplace Shell), lance au demarrage du systeme
                (PROTSHELL=C:\PMSHELL.EXE dans CONFIG.SYS).
}

Program PMSHELL;

{$R-,S-,I-}

{ Compilation : OS2PC PMSHELL.PAS   (produit PMSHELL.EXE)

  PMSHELL est le bureau d'OS/2-0 (Workplace Shell). Le noyau le lance a
  la place de CMD.EXE quand CONFIG.SYS contient PROTSHELL=C:\PMSHELL.EXE
  (et le relance s'il se termine). Il affiche le bureau en mode graphique
  (640 x 480 x 16 couleurs, PMWIN.DLL), s'utilise a la souris et au
  clavier, et lance le LaunchPad (C:\LAUNCHPD.EXE, sauf si OS2.INI
  contient PMSHELL, LAUNCHPAD = 0).

  Bureau : objets Systeme OS/2, Lecteurs, Invite de commandes OS/2,
  Liste des fenetres, Modeles, Broyeur et Arret, puis le contenu du
  repertoire du bureau (C:\DESKTOP, ou D:\DESKTOP quand C: est le CD-ROM : les
  objets crees ou deposes sur le bureau) et les
  raccourcis du bureau. Les icones du bureau se deplacent a la souris
  (position gardee dans OS2.INI, application PMSHELL).
  Dossiers : Systeme OS/2, Lecteurs (une icone par unite), Modeles, et les
  repertoires (sous-repertoires, programmes .EXE, fichiers de commandes
  .CMD/.BAT, fichiers de donnees). Un dossier deja ouvert est active au
  lieu d'etre ouvert une seconde fois. Il n'y a pas de limite au nombre
  de fenetres ni au nombre d'objets d'un dossier (tables qui grandissent).

  Glisser-deposer (bouton 2, ou bouton 1 dans un dossier) : un objet
  depose sur un dossier ou sur la fenetre d'un dossier y est deplace
  (copie si Ctrl est enfonce ; copie aussi d'une unite a une autre) ;
  depose sur le Broyeur il est supprime (apres confirmation) ; depose sur
  un programme, celui-ci est lance avec le fichier en parametre ; depose
  sur le LaunchPad il y est ajoute. Raccourcis (shadows) : menu
  contextuel, Creer un raccourci (sur le bureau), ou deposer avec Ctrl+Maj ;
  un raccourci (etiquette en bleu) ouvre son objet, le supprimer ne
  supprime que le raccourci (OS2.INI, PMSHELL_RACCOURCIS). Modeles :
  dossier, fichier texte, fichier de commandes ; ouvrir un modele (ou le
  deposer sur un dossier) cree un nouvel objet.

  Souris : clic (bouton 1) : selection ; double clic : ouvrir ; bouton 2 :
  menu contextuel de l'objet ou du fond.
  Clavier : fleches, Debut, Fin : selection ; Entree : ouvrir ;
  Maj+F10 : menu contextuel ; Ctrl+Echap : liste des fenetres ; F5 :
  actualiser ; Retour arriere : dossier parent ; Suppr : supprimer
  l'objet choisi (apres confirmation) ; F1 : aide ; lettre : objet
  suivant qui commence par cette lettre ; Alt+F4 : fermer la fenetre
  (sur le bureau : arret du systeme) ; Echap : fermer la visionneuse ou
  la liste des fenetres.

  Programmes : un objet programme (.EXE), un fichier de commandes (par
  COMSPEC /C) ou l'invite de commandes (COMSPEC) est lance par
  DosExecPgm dans une nouvelle session plein ecran, dans le repertoire de
  son dossier ; le bureau continue de s'executer (OS/2-0 est multitache).
  Ctrl+Echap revient au bureau, Alt+Echap passe a la session suivante, et
  la liste des fenetres montre les sessions. Un programme de PM rejoint
  la session de Presentation Manager. Apres un programme en mode texte
  autre que l'invite de commandes, le noyau attend une touche avant de
  fermer la session.
  Fichiers de donnees : visionneuse (texte du fichier dans une liste).
  STARTUP.CMD (C:\ ou D:\) est execute au demarrage, avant le bureau.

  Demandes des autres programmes (LaunchPad) : le programme ecrit la
  demande dans OS2.INI (PMSHELL, REQn) et envoie WM_USER + 1 (mp1 = n) a
  la fenetre du bureau (PMSHELL, HWND) : OPEN chemin, DRIVES, SYS, TEMPL,
  CMD, RUN programme, BATCH fichier, VIEW fichier, WINLIST, HELP, INFO,
  SHUTDOWN.

  Arret : apres confirmation, les fichiers sont ecrits (DosShutdown) et
  l'ecran indique que l'ordinateur peut etre eteint ; Ctrl+Alt+Suppr
  redemarre alors l'ordinateur. }

Const
  { messages }
  WM_CREATE = $0001; WM_DESTROY = $0002; WM_SIZE = $0007; WM_ACTIVATE = $000D;
  WM_SETFOCUS = $000F; WM_COMMAND = $0020; WM_SYSCOMMAND = $0021; WM_PAINT = $0023; WM_CLOSE = $0029; WM_CONTROL = $0030;
  WM_VSCROLL = $0031; WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072;
  WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074; WM_BUTTON2UP = $0075; WM_BUTTON2CLICK = $0416;
  WM_CHAR = $007A; WM_REQUEST = $1001;
  SC_CLOSE = $8004;
  { styles et fenetres }
  WS_VISIBLE = $80000000; WS_MINIMIZED = $01000000;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20;
  FCF_VERTSCROLL = $40;
  FID_VERTSCROLL = $8006; FID_CLIENT = $8008;
  HWND_DESKTOP = 1; HWND_TOP = 3; HWND_BOTTOM = 4;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80; SWP_RESTORE = $1000;
  QW_PARENT = 5; QWL_STYLE = -2;
  WC_LISTBOX = $FFFF0007;
  LM_QUERYITEMCOUNT = $0160; LM_INSERTITEM = $0161; LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165; LM_DELETEALL = $016E;
  LN_ENTER = 5;
  SBM_SETSCROLLBAR = $01A0; SBM_SETTHUMBSIZE = $01A6;
  SB_LINEUP = 1; SB_LINEDOWN = 2; SB_PAGEUP = 3; SB_PAGEDOWN = 4; SB_SLIDERTRACK = 5; SB_SLIDERPOSITION = 6;
  MBID_OK = 1; MBID_YES = 6;
  MB_OK = 0; MB_OKCANCEL = 1; MB_YESNO = 4; MB_QUERY = $10; MB_WARNING = $20; MB_INFORMATION = $30;
  MB_ERROR = $40; MB_MOVEABLE = $4000;
  { clavier }
  KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40; KC_CHAR = 1;
  VK_BACKSPACE = 5; VK_NEWLINE = 8; VK_ESC = $0F; VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13;
  VK_HOME = $14; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_DELETE = $1B;
  VK_ENTER = $1E; VK_F1 = $20; VK_F5 = $24; VK_F10 = $29;
  { couleurs }
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  DeskRgb = $008080;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  { vues et objets }
  CW = 112; CH = 80;
  VK_DESK = 0; VK_SYS = 1; VK_DRIVES = 2; VK_DIR = 3; VK_VIEWER = 4; VK_LIST = 5;
  IC_FOLDER = 0; IC_SYSTEM = 1; IC_DRIVES = 2; IC_PROGRAM = 3; IC_CMD = 4; IC_BATCH = 5; IC_FILE = 6;
  IC_CDROM = 7; IC_DISK = 8; IC_SHUTDOWN = 9; IC_WINLIST = 10; IC_INFO = 11; IC_HELP = 12;
  IC_TEMPL = 13; IC_SHRED = 14;
  OB_SYS = 1; OB_DRIVES = 2; OB_CMD = 3; OB_SHUTDOWN = 4; OB_WINLIST = 5; OB_INFO = 6; OB_HELP = 7;
  OB_DIR = 8; OB_EXE = 9; OB_BATCH = 10; OB_DATA = 11; OB_TEMPLATES = 12; OB_SHRED = 13;
  OB_TPLDIR = 14; OB_TPLDATA = 15; OB_TPLCMD = 16;
  VK_TEMPL = 6;
  ShadowApp = 'PMSHELL_RACCOURCIS';
  { commandes des menus }
  CM_OPEN = 100; CM_REFRESH = 101; CM_ARRANGE = 102; CM_WINLIST = 103; CM_INFO = 104; CM_SHUTDOWN = 105;
  CM_HELP = 106; CM_PROPS = 107; CM_DELETE = 108; CM_CLOSE = 109; CM_PARENT = 110; CM_CMDHERE = 111;
  CM_SHADOW = 112; CM_CREATE = 113;

Type
  { objet d'une vue (icone) }
  TItem = Record
    Use, View, Icon, Obj, X, Top, Size, Shadow : LongInt;
    Name : String[47];
    Path : String[127];
  End;
  PItem = ^TItem;
  { vue : bureau, dossier, visionneuse, liste des fenetres }
  TView = Record
    Use, Kind, Frame, Client, Sel, Top, Max, List, Hidden, Stamp : LongInt;
    Path, Title : String[127];
  End;
  PView = ^TView;
  { entree d'un repertoire avant le tri : cle "0nom" (repertoire) ou
    "1nom" (fichier), taille }
  TEnt = Record
    Size : LongInt;
    Key : String[48];
  End;
  PEnt = ^TEnt;

Var
  Hab, Hmq, Desk, MenuH, Creating, ScrW, ScrH, Dummy, I : LongInt;
  { vues }
  ViewBuf, ViewCap, Stamp : LongInt;   { vues : table qui grandit }
  { objets }
  ItemBuf, ItemCap : LongInt;          { objets : table qui grandit }
  { glisser }
  DragItem, DragX0, DragY0, DragIX, DragITop, Dragging, MenuView, MenuItem : LongInt;
  { tampons }
  NameZ, NameZ2, ArgBuf, FailBuf : Array[0..511] Of Byte;
  MenuTpl : Array[0..2047] Of Byte;
  MenuLen, MenuCnt : LongInt;
  FindBuf : Array[0..4095] Of Byte;
  FileBuf : Array[0..4095] Of Byte;
  EntBuf, EntCap : LongInt;            { entrees d'un repertoire (tri) }
  { glisser-deposer entre les vues }
  DSrc, DBtn, DActive, DX0, DY0, NoMenu : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  I2 : LongInt;
  WlSess : Array[0..31] Of LongInt;   { liste des fenetres : sessions }
  WlViews, WlNS : LongInt;
  DeskDir : String[40];               { repertoire du bureau (C:\DESKTOP ou D:\DESKTOP) }

{ --- DOSCALLS.DLL --- }
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt; External 'DOSCALLS';
Function DosQuerySysInfo(IStart, ILast, PBuf, CbBuf : LongInt) : LongInt; External 'DOSCALLS';
Function DosShutdown(Reserved : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetCurrentDir(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetDefaultDisk(Disk : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosCopy(PSrc, PDst, Opt : LongInt) : LongInt; External 'DOSCALLS';
Function DosMove(POld, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosDeleteDir(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';

{ --- PMWIN.DLL --- }
Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinShowWindow(H, Show : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindowVisible(H : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryActiveWindow(HDesk : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindow(H, Cmd : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowULong(H, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinMapWindowPoints(HFrom, HTo, P, N : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromPoint(HPar, P, Ch : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowULong(H, Ix, V : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetSysColors(HD, O, F, C1, N, P : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, T : LongInt) : LongInt; External 'PMWIN';
Function WinSuspendScreen : LongInt; External 'PMWIN' Name 'WINSUSPENDSCREEN';
Function WinResumeScreen : LongInt; External 'PMWIN' Name 'WINRESUMESCREEN';
Function WinQueryScreenTaken : LongInt; External 'PMWIN' Name 'WINQUERYSCREENTAKEN';

{ --- PMGPI.DLL --- }
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';

{ --- PMMERGE.DLL (profil de l'utilisateur) --- }
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryProfileSize(H, A, K, P : LongInt) : LongInt; External 'PMMERGE';

{ --- VIOCALLS.DLL, KBDCALLS.DLL (ecran d'arret) --- }
Function VioWrtCharStrAtt(PStr, Cb, Row, Col, PAttr, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioScrollUp(Top, Left, Bot, Right, N, PCell, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSetCurPos(Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function KbdCharIn(PInfo, Wait, Hkbd : LongInt) : LongInt; External 'KBDCALLS';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Function RdL(A : LongInt) : LongInt;
Type PLong = ^LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Procedure WrL(A, V : LongInt);
Type PLong = ^LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Function RdB(A : LongInt) : LongInt;
Type PByte = ^Byte;
Var Q : PByte;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrB(A, V : LongInt);
Type PByte = ^Byte;
Var Q : PByte;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := ''; K := 0;
  If A <> 0 Then
    While (K < 255) And (RdB(A + K) <> 0) Do
    Begin
      S := S + Chr(RdB(A + K));
      Inc(K);
    End;
  GetZ := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
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

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'a') And (S[K] <= 'z') Then S[K] := Chr(Ord(S[K]) - 32);
  UpStr := S;
End;

Function Mk2(A, B : LongInt) : LongInt;
Begin
  Mk2 := (A And $FFFF) Or (B Shl 16);
End;

Function Lo16(V : LongInt) : LongInt;
Begin
  Lo16 := V And $FFFF;
End;

Function Hi16(V : LongInt) : LongInt;
Begin
  Hi16 := (V Shr 16) And $FFFF;
End;

{ valeur signee de 16 bits }
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

Function AbsI(A : LongInt) : LongInt;
Begin
  If A < 0 Then AbsI := -A Else AbsI := A;
End;

Function GetEnvS(N : String) : String;
Var P : LongInt;
Begin
  P := 0;
  If DosScanEnv(Z(N), LongInt(@P)) = 0 Then GetEnvS := GetZ(P) Else GetEnvS := '';
End;

Function FileExists(S : String) : Boolean;
Var Info : Array[0..63] Of Byte;
Begin
  FileExists := DosQueryPathInfo(Z(S), 1, LongInt(@Info), 64) = 0;
End;

Function ExtOf(S : String) : String;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '.') And (S[K] <> '\') Do Dec(K);
  If (K > 0) And (S[K] = '.') Then ExtOf := UpStr(Copy(S, K + 1, 255)) Else ExtOf := '';
End;

Function Comspec : String;
Var S : String;
Begin
  S := GetEnvS('COMSPEC');
  If (S = '') Or (Pos('PMSHELL', UpStr(S)) > 0) Then S := 'C:\CMD.EXE';
  Comspec := S;
End;

Procedure ShowMsg(Text, Cap : String; Style : LongInt);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, Z(Text), Z2(Cap), 0, Style Or MB_MOVEABLE);
End;

Function PrfStr(App, Key : String) : String;
Var B : Array[0..299] Of Byte;
Begin
  B[0] := 0;
  Dummy := PrfQueryProfileString(-1, Z(App), Z2(Key), 0, LongInt(@B), 290);
  PrfStr := GetZ(LongInt(@B));
End;

Procedure PrfSet(App, Key, Value : String);
Var B : Array[0..299] Of Byte;
Begin
  PutZ(LongInt(@B), Value);
  If Value = '' Then Dummy := PrfWriteProfileString(-1, Z(App), Z2(Key), 0)
  Else Dummy := PrfWriteProfileString(-1, Z(App), Z2(Key), LongInt(@B));
End;

Function PrfInt(App, Key : String) : LongInt;
Var V, C : LongInt;
Begin
  Val(PrfStr(App, Key), V, C);
  If C <> 0 Then V := 0;
  PrfInt := V;
End;

{ ==================================================================== }
{ Objets et vues : tables d'enregistrements qui doublent quand elles     }
{ sont pleines (pas de limite fixe)                                     }
{ ==================================================================== }

Function It(K : LongInt) : PItem;
Begin
  It := Pointer(ItemBuf + K * SizeOf(TItem));
End;

Function Vw(V : LongInt) : PView;
Begin
  Vw := Pointer(ViewBuf + V * SizeOf(TView));
End;

{ agrandir une table : nouveau bloc (mis a zero), copie, ancien rendu }
Procedure Grow(Var Buf, Cap : LongInt; Sz : LongInt);
Var P : Pointer; N, K : LongInt;
Begin
  If Cap <= 0 Then N := 64 Else N := Cap * 2;
  GetMem(P, N * Sz);
  For K := 0 To N * Sz - 1 Do WrB(LongInt(P) + K, 0);
  If Buf <> 0 Then
  Begin
    For K := 0 To Cap * Sz - 1 Do WrB(LongInt(P) + K, RdB(Buf + K));
    FreeMem(Pointer(Buf), Cap * Sz);
  End;
  Buf := LongInt(P);
  Cap := N;
End;

Function NewItem(V, Icon, Obj : LongInt; Name, Path : String) : LongInt;
Var K, F : LongInt;
Begin
  F := -1;
  For K := ItemCap - 1 DownTo 0 Do
    If It(K)^.Use = 0 Then F := K;
  If F < 0 Then
  Begin
    F := ItemCap;
    Grow(ItemBuf, ItemCap, SizeOf(TItem));
  End;
  If F >= 0 Then
  Begin
    It(F)^.Use := 1; It(F)^.View := V; It(F)^.Icon := Icon; It(F)^.Obj := Obj; It(F)^.Name := Name; It(F)^.Path := Path;
    It(F)^.X := 0; It(F)^.Top := 0; It(F)^.Size := 0; It(F)^.Shadow := 0;
  End;
  NewItem := F;
End;

Procedure ClearItems(V : LongInt);
Var K : LongInt;
Begin
  For K := 0 To ItemCap - 1 Do
    If (It(K)^.Use <> 0) And (It(K)^.View = V) Then It(K)^.Use := 0;
  Vw(V)^.Sel := -1;
End;

Function ViewOf(Hwnd : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 0 To ViewCap - 1 Do
    If (Vw(K)^.Use <> 0) And ((Vw(K)^.Client = Hwnd) Or (Vw(K)^.Frame = Hwnd)) Then R := K;
  ViewOf := R;
End;

Function ClientH(V : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[3] := 0;
  Dummy := WinQueryWindowRect(Vw(V)^.Client, LongInt(@Rc));
  ClientH := Rc[3];
End;

Function ClientW(V : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[2] := 0;
  Dummy := WinQueryWindowRect(Vw(V)^.Client, LongInt(@Rc));
  ClientW := Rc[2];
End;

{ rectangle (coordonnees du client) de la cellule de l'objet K }
Procedure CellRect(K : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Var V : LongInt;
Begin
  V := It(K)^.View;
  X1 := It(K)^.X; X2 := It(K)^.X + CW;
  Y2 := ClientH(V) - (It(K)^.Top - Vw(V)^.Top);
  Y1 := Y2 - CH;
End;

Procedure InvalItem(K : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (K < 0) Or (It(K)^.Use = 0) Then Exit;
  CellRect(K, Rc[0], Rc[1], Rc[2], Rc[3]);
  Dummy := WinInvalidateRect(Vw(It(K)^.View)^.Client, LongInt(@Rc), 1);
End;

Procedure SelectItem(V, K : LongInt);
Begin
  If Vw(V)^.Sel = K Then Exit;
  InvalItem(Vw(V)^.Sel);
  Vw(V)^.Sel := K;
  InvalItem(K);
End;

Function HitItem(V, X, Y : LongInt) : LongInt;
Var K, R, X1, Y1, X2, Y2 : LongInt;
Begin
  R := -1;
  For K := 0 To ItemCap - 1 Do
    If (It(K)^.Use <> 0) And (It(K)^.View = V) Then
    Begin
      CellRect(K, X1, Y1, X2, Y2);
      If (X >= X1 + 8) And (X < X2 - 8) And (Y >= Y1 + 4) And (Y < Y2 - 2) Then R := K;
    End;
  HitItem := R;
End;

{ position d'une icone du bureau (OS2.INI, application PMSHELL) }
Procedure LoadPos(K : LongInt);
Var B : Array[0..63] Of Byte; S : String; P, X, Y, C : LongInt;
Begin
  B[0] := 0;
  Dummy := PrfQueryProfileString(-1, Z('PMSHELL'), Z2('POS ' + It(K)^.Name), 0, LongInt(@B), 60);
  S := GetZ(LongInt(@B));
  P := Pos(',', S);
  If P > 1 Then
  Begin
    Val(Copy(S, 1, P - 1), X, C);
    If C = 0 Then Val(Copy(S, P + 1, 20), Y, C);
    If (C = 0) And (X >= 0) And (X < ScrW - 16) And (Y >= 0) And (Y < ScrH - 16) Then
    Begin
      It(K)^.X := X; It(K)^.Top := Y;
    End;
  End;
End;

Procedure SavePos(K : LongInt);
Var B : Array[0..63] Of Byte;
Begin
  PutZ(LongInt(@B), IStr(It(K)^.X) + ',' + IStr(It(K)^.Top));
  Dummy := PrfWriteProfileString(-1, Z('PMSHELL'), Z2('POS ' + It(K)^.Name), LongInt(@B));
End;

{ disposition : colonnes (bureau) ou lignes (dossier) }
Procedure Layout(V : LongInt);
Var K, N, Cols, Rows, W, H : LongInt;
Begin
  W := ClientW(V); H := ClientH(V);
  N := 0; Rows := 0;
  If Vw(V)^.Kind = VK_DESK Then
  Begin
    Rows := MaxI(1, (H - 8) Div CH);
    For K := 0 To ItemCap - 1 Do
      If (It(K)^.Use <> 0) And (It(K)^.View = V) Then
      Begin
        It(K)^.X := 8 + (N Div Rows) * CW;
        It(K)^.Top := 8 + (N Mod Rows) * CH;
        LoadPos(K);
        Inc(N);
      End;
  End
  Else
  Begin
    Cols := MaxI(1, (W - 8) Div CW);
    For K := 0 To ItemCap - 1 Do
      If (It(K)^.Use <> 0) And (It(K)^.View = V) Then
      Begin
        It(K)^.X := 8 + (N Mod Cols) * CW;
        It(K)^.Top := 8 + (N Div Cols) * CH;
        Inc(N);
      End;
    Vw(V)^.Max := 8 + ((N + Cols - 1) Div Cols) * CH;
  End;
End;

Procedure UpdScroll(V : LongInt);
Var Sb, H, M : LongInt;
Begin
  If Vw(V)^.Kind = VK_DESK Then Exit;
  Sb := WinWindowFromID(Vw(V)^.Frame, FID_VERTSCROLL);
  If Sb = 0 Then Exit;
  H := ClientH(V);
  M := MaxI(0, Vw(V)^.Max - H);
  If Vw(V)^.Top > M Then Vw(V)^.Top := M;
  If Vw(V)^.Top < 0 Then Vw(V)^.Top := 0;
  Dummy := WinSendMsg(Sb, SBM_SETSCROLLBAR, Vw(V)^.Top, Mk2(0, M));
  Dummy := WinSendMsg(Sb, SBM_SETTHUMBSIZE, Mk2(H, MaxI(H, Vw(V)^.Max)), 0);
End;

{ faire voir l'objet K (defilement) }
Procedure ShowItem(K : LongInt);
Var V, H : LongInt;
Begin
  V := It(K)^.View;
  If Vw(V)^.Kind = VK_DESK Then Exit;
  H := ClientH(V);
  If It(K)^.Top < Vw(V)^.Top Then Vw(V)^.Top := MaxI(0, It(K)^.Top - 8)
  Else If It(K)^.Top + CH > Vw(V)^.Top + H Then Vw(V)^.Top := It(K)^.Top + CH + 8 - H
  Else Exit;
  UpdScroll(V);
  Dummy := WinInvalidateRect(Vw(V)^.Client, 0, 1);
End;

{ contenu d'un dossier }
Function Ent(K : LongInt) : PEnt;
Begin
  Ent := Pointer(EntBuf + K * SizeOf(TEnt));
End;

{ type de l'objet d'apres le nom du fichier }
Procedure FileKind(S : String; IsDir : Boolean; Var Icon, Obj : LongInt);
Var E : String;
Begin
  E := ExtOf(S);
  If IsDir Then
  Begin
    Icon := IC_FOLDER; Obj := OB_DIR;
  End
  Else If (E = 'EXE') Or (E = 'COM') Then
  Begin
    Icon := IC_PROGRAM; Obj := OB_EXE;
  End
  Else If (E = 'CMD') Or (E = 'BAT') Then
  Begin
    Icon := IC_BATCH; Obj := OB_BATCH;
  End
  Else
  Begin
    Icon := IC_FILE; Obj := OB_DATA;
  End;
End;

Procedure AddSorted(V : LongInt; Dir : String);
Var H, N, A, Cnt, Rc, K, J, T, Icon, Obj, Off : LongInt; S, Ts : String;
Begin
  Cnt := 0;
  H := -1; N := 1;
  Rc := DosFindFirst(Z(Dir + '*.*'), LongInt(@H), $37, LongInt(@FindBuf), 4096, LongInt(@N), 1);
  While (Rc = 0) And (N > 0) Do
  Begin
    Off := 0;
    While N > 0 Do
    Begin
      A := RdL(LongInt(@FindBuf) + Off + 24);
      S := '';
      For K := 0 To RdB(LongInt(@FindBuf) + Off + 28) - 1 Do S := S + Chr(RdB(LongInt(@FindBuf) + Off + 29 + K));
      If (S <> '.') And (S <> '..') Then
      Begin
        If Cnt >= EntCap Then Grow(EntBuf, EntCap, SizeOf(TEnt));
        { repertoires d'abord (cle "0nom"), puis fichiers ("1nom") }
        If (A And $10) <> 0 Then Ent(Cnt)^.Key := '0' + S Else Ent(Cnt)^.Key := '1' + S;
        Ent(Cnt)^.Size := RdL(LongInt(@FindBuf) + Off + 16);
        If (A And $10) <> 0 Then Ent(Cnt)^.Size := -1;
        Inc(Cnt);
      End;
      Dec(N);
      If RdL(LongInt(@FindBuf) + Off) = 0 Then N := 0
      Else Off := Off + RdL(LongInt(@FindBuf) + Off);
    End;
    N := 1;
    Rc := DosFindNext(H, LongInt(@FindBuf), 4096, LongInt(@N));
  End;
  If H <> -1 Then Dummy := DosFindClose(H);
  { tri par insertion }
  For K := 1 To Cnt - 1 Do
  Begin
    Ts := Ent(K)^.Key; T := Ent(K)^.Size; J := K - 1;
    While (J >= 0) And (UpStr(Ent(J)^.Key) > UpStr(Ts)) Do
    Begin
      Ent(J + 1)^.Key := Ent(J)^.Key; Ent(J + 1)^.Size := Ent(J)^.Size;
      Dec(J);
    End;
    Ent(J + 1)^.Key := Ts; Ent(J + 1)^.Size := T;
  End;
  For K := 0 To Cnt - 1 Do
  Begin
    S := Copy(Ent(K)^.Key, 2, 255);
    FileKind(S, Ent(K)^.Key[1] = '0', Icon, Obj);
    If Obj = OB_DIR Then J := NewItem(V, Icon, Obj, S, Dir + S + '\')
    Else J := NewItem(V, Icon, Obj, S, Dir + S);
    If J >= 0 Then It(J)^.Size := Ent(K)^.Size;
  End;
End;

{ --- Raccourcis (shadows) : OS2.INI, application PMSHELL_RACCOURCIS ;
  cle = conteneur (BUREAU ou chemin du dossier) + '|' + nom, valeur =
  cible (chemin d'un fichier ou d'un dossier, ou *n : objet du systeme
  n) --- }

{ icone et objet d'un objet du systeme }
Procedure SysObjKind(Obj : LongInt; Var Icon : LongInt);
Begin
  Case Obj Of
    OB_SYS : Icon := IC_SYSTEM;
    OB_DRIVES : Icon := IC_DRIVES;
    OB_CMD : Icon := IC_CMD;
    OB_SHUTDOWN : Icon := IC_SHUTDOWN;
    OB_WINLIST : Icon := IC_WINLIST;
    OB_INFO : Icon := IC_INFO;
    OB_HELP : Icon := IC_HELP;
    OB_TEMPLATES : Icon := IC_TEMPL;
    OB_SHRED : Icon := IC_SHRED;
  Else
    Icon := IC_FILE;
  End;
End;

Procedure AddShadows(V : LongInt; Cont : String);
Var Sz, P, K, J, Icon, Obj, C : LongInt; Buf : Pointer; S, Tg, Nm : String; B : Array[0..259] Of Byte;
Begin
  Sz := 0;
  If PrfQueryProfileSize(-1, Z(ShadowApp), 0, LongInt(@Sz)) = 0 Then Exit;
  If Sz <= 0 Then Exit;
  GetMem(Buf, Sz + 2);
  P := LongInt(Buf);
  WrB(P, 0);
  Dummy := PrfQueryProfileString(-1, Z(ShadowApp), 0, 0, P, Sz + 1);
  K := 0;
  While (K < Sz) And (RdB(P + K) <> 0) Do
  Begin
    S := GetZ(P + K);
    K := K + Length(S) + 1;
    J := Pos('|', S);
    If (J > 1) And (UpStr(Copy(S, 1, J - 1)) = UpStr(Cont)) Then
    Begin
      Nm := Copy(S, J + 1, 255);
      B[0] := 0;
      Dummy := PrfQueryProfileString(-1, Z(ShadowApp), Z2(S), 0, LongInt(@B), 256);
      Tg := GetZ(LongInt(@B));
      If (Length(Tg) > 1) And (Tg[1] = '*') Then
      Begin
        Val(Copy(Tg, 2, 10), Obj, C);
        SysObjKind(Obj, Icon);
        Tg := '';
      End
      Else FileKind(Tg, (Length(Tg) > 0) And (Tg[Length(Tg)] = '\'), Icon, Obj);
      { racine d'une unite : icone de l'unite }
      If (Length(Tg) = 3) And (Tg[2] = ':') Then
      Begin
        If Pos('CD-ROM', UpStr(Nm)) > 0 Then Icon := IC_CDROM Else Icon := IC_DISK;
      End;
      J := NewItem(V, Icon, Obj, Nm, Tg);
      If J >= 0 Then It(J)^.Shadow := 1;
    End;
  End;
  FreeMem(Buf, Sz + 2);
End;

{ conteneur des raccourcis d'une vue ou d'un repertoire }
Function ContOf(Dir : String) : String;
Begin
  If UpStr(Dir) = DeskDir Then ContOf := 'BUREAU' Else ContOf := UpStr(Dir);
End;

Function ShadowExists(Cont, Nm : String) : Boolean;
Var B : Array[0..63] Of Byte;
Begin
  B[0] := 0;
  Dummy := PrfQueryProfileString(-1, Z(ShadowApp), Z2(Cont + '|' + Nm), 0, LongInt(@B), 60);
  ShadowExists := B[0] <> 0;
End;

Procedure MakeShadow(Cont, Nm, Target : String);
Var N : LongInt; S : String; B : Array[0..259] Of Byte;
Begin
  S := Nm; N := 2;
  While ShadowExists(Cont, S) Do
  Begin
    S := Nm + ' ' + IStr(N);
    Inc(N);
  End;
  PutZ(LongInt(@B), Target);
  Dummy := PrfWriteProfileString(-1, Z(ShadowApp), Z2(Cont + '|' + S), LongInt(@B));
End;

Procedure DelShadow(Cont, Nm : String);
Begin
  Dummy := PrfWriteProfileString(-1, Z(ShadowApp), Z2(Cont + '|' + Nm), 0);
End;

{ cible d'un objet pour un raccourci }
Function TargetOf(K : LongInt) : String;
Begin
  If It(K)^.Path <> '' Then TargetOf := It(K)^.Path Else TargetOf := '*' + IStr(It(K)^.Obj);
End;

{ --- Modeles : un nouvel objet dans le repertoire Dir --- }
Function UniqueName(Dir, Base, Ext : String) : String;
Var N : LongInt; S : String;
Begin
  S := Base + Ext; N := 2;
  While FileExists(Dir + S) Do
  Begin
    S := Base + IStr(N) + Ext;
    Inc(N);
  End;
  UniqueName := S;
End;

Function CreateFromTemplate(Obj : LongInt; Dir : String) : Boolean;
Var S, Txt : String; H, A, W : LongInt;
Begin
  CreateFromTemplate := False;
  Dummy := DosCreateDir(Z(Copy(Dir, 1, Length(Dir) - 1)), 0);
  Case Obj Of
    OB_TPLDIR :
      Begin
        S := UniqueName(Dir, 'Dossier', '');
        CreateFromTemplate := DosCreateDir(Z(Dir + S), 0) = 0;
      End;
    OB_TPLDATA, OB_TPLCMD :
      Begin
        If Obj = OB_TPLDATA Then
        Begin
          S := UniqueName(Dir, 'Donnees', '.TXT'); Txt := '';
        End
        Else
        Begin
          S := UniqueName(Dir, 'Commandes', '.CMD');
          Txt := '@ECHO OFF' + #13#10 + 'REM Fichier de commandes cree par le bureau' + #13#10;
        End;
        H := 0; A := 0;
        If DosOpen(Z(Dir + S), LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0) = 0 Then
        Begin
          W := 0;
          If Txt <> '' Then Dummy := DosWrite(H, Z2(Txt), Length(Txt), LongInt(@W));
          Dummy := DosClose(H);
          CreateFromTemplate := True;
        End;
      End;
  End;
End;

Procedure Populate(V : LongInt);
Var D, L, K : LongInt;
Begin
  ClearItems(V);
  Case Vw(V)^.Kind Of
    VK_DESK :
      Begin
        Dummy := NewItem(V, IC_SYSTEM, OB_SYS, 'Systeme OS/2', '');
        Dummy := NewItem(V, IC_DRIVES, OB_DRIVES, 'Lecteurs', '');
        Dummy := NewItem(V, IC_CMD, OB_CMD, 'Invite de commandes OS/2', '');
        Dummy := NewItem(V, IC_WINLIST, OB_WINLIST, 'Liste des fenetres', '');
        Dummy := NewItem(V, IC_TEMPL, OB_TEMPLATES, 'Modeles', '');
        Dummy := NewItem(V, IC_SHRED, OB_SHRED, 'Broyeur', '');
        Dummy := NewItem(V, IC_SHUTDOWN, OB_SHUTDOWN, 'Arret', '');
        { fichiers et dossiers du repertoire du bureau, puis raccourcis }
        AddSorted(V, DeskDir);
        AddShadows(V, 'BUREAU');
      End;
    VK_TEMPL :
      Begin
        Dummy := NewItem(V, IC_FOLDER, OB_TPLDIR, 'Dossier', '');
        Dummy := NewItem(V, IC_FILE, OB_TPLDATA, 'Fichier de donnees', '');
        Dummy := NewItem(V, IC_BATCH, OB_TPLCMD, 'Fichier de commandes', '');
      End;
    VK_SYS :
      Begin
        Dummy := NewItem(V, IC_CMD, OB_CMD, 'Invite de commandes OS/2', '');
        Dummy := NewItem(V, IC_DRIVES, OB_DRIVES, 'Lecteurs', '');
        Dummy := NewItem(V, IC_WINLIST, OB_WINLIST, 'Liste des fenetres', '');
        Dummy := NewItem(V, IC_INFO, OB_INFO, 'Informations systeme', '');
        Dummy := NewItem(V, IC_HELP, OB_HELP, 'Aide du bureau', '');
        Dummy := NewItem(V, IC_SHUTDOWN, OB_SHUTDOWN, 'Arret', '');
      End;
    VK_DRIVES :
      Begin
        D := 0; L := 0;
        Dummy := DosQueryCurrentDisk(LongInt(@D), LongInt(@L));
        For K := 2 To 25 Do
          If (L And (1 Shl K)) <> 0 Then
          Begin
            If K = 2 Then Dummy := NewItem(V, IC_CDROM, OB_DIR, 'Lecteur ' + Chr(65 + K) + ' (CD-ROM)',
                                           Chr(65 + K) + ':\')
            Else Dummy := NewItem(V, IC_DISK, OB_DIR, 'Lecteur ' + Chr(65 + K), Chr(65 + K) + ':\');
          End;
      End;
    VK_DIR :
      Begin
        AddSorted(V, Vw(V)^.Path);
        AddShadows(V, UpStr(Vw(V)^.Path));
      End;
  End;
  Layout(V);
  If Vw(V)^.Kind <> VK_DESK Then UpdScroll(V);
End;

{ ==================================================================== }
{ Dessin des icones (GPI sur l'espace de presentation de la fenetre)    }
{ ==================================================================== }

Procedure GBox(Hps, X1, Y1, X2, Y2, C, Fl : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiBox(Hps, Fl, LongInt(@P), 0, 0);
End;

Procedure FBox(Hps, X1, Y1, X2, Y2, Fill, Edge : LongInt);
Begin
  GBox(Hps, X1, Y1, X2, Y2, Fill, DRO_FILL);
  If Edge <> Fill Then GBox(Hps, X1, Y1, X2, Y2, Edge, DRO_OUTLINE);
End;

Procedure GLn(Hps, X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiLine(Hps, LongInt(@P));
End;

Procedure GText(Hps, X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt; B : Array[0..63] Of Byte;
Begin
  PutZ(LongInt(@B), S);
  Rc[0] := X; Rc[1] := Y; Rc[2] := X + Length(S) * 8; Rc[3] := Y + 16;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@B), LongInt(@Rc), Fg, Bg, 0);
End;

Procedure IconFolder(Hps, X, Y, Fill : LongInt);
Begin
  FBox(Hps, X + 2, Y + 22, X + 13, Y + 26, Fill, CLR_BROWN);
  FBox(Hps, X + 1, Y + 4, X + 30, Y + 23, Fill, CLR_BROWN);
  GLn(Hps, X + 2, Y + 21, X + 29, Y + 21, CLR_WHITE);
End;

Procedure IconWindow(Hps, X, Y : LongInt);
Begin
  FBox(Hps, X + 2, Y + 4, X + 29, Y + 28, CLR_PALEGRAY, CLR_BLACK);
  FBox(Hps, X + 3, Y + 23, X + 28, Y + 27, CLR_DARKBLUE, CLR_DARKBLUE);
  FBox(Hps, X + 4, Y + 6, X + 27, Y + 21, CLR_WHITE, CLR_DARKGRAY);
End;

Procedure IconPage(Hps, X, Y : LongInt);
Var K : LongInt;
Begin
  FBox(Hps, X + 6, Y + 2, X + 25, Y + 29, CLR_WHITE, CLR_BLACK);
  FBox(Hps, X + 19, Y + 23, X + 25, Y + 29, CLR_PALEGRAY, CLR_BLACK);
  K := 0;
  While K < 5 Do
  Begin
    GLn(Hps, X + 9, Y + 19 - K * 3, X + 22, Y + 19 - K * 3, CLR_DARKGRAY);
    Inc(K);
  End;
End;

Procedure DrawIcon(Hps, Icon, X, Y : LongInt);
Begin
  Case Icon Of
    IC_FOLDER : IconFolder(Hps, X, Y, CLR_YELLOW);
    IC_SYSTEM :
      Begin
        IconFolder(Hps, X, Y, CLR_YELLOW);
        FBox(Hps, X + 9, Y + 8, X + 22, Y + 18, CLR_DARKBLUE, CLR_BLACK);
        GText(Hps, X + 12, Y + 5, '2', CLR_WHITE, CLR_DARKBLUE);
      End;
    IC_DRIVES :
      Begin
        IconFolder(Hps, X, Y, CLR_YELLOW);
        FBox(Hps, X + 7, Y + 8, X + 24, Y + 15, CLR_PALEGRAY, CLR_BLACK);
        GBox(Hps, X + 20, Y + 10, X + 22, Y + 11, CLR_GREEN, DRO_FILL);
      End;
    IC_PROGRAM : IconWindow(Hps, X, Y);
    IC_CMD :
      Begin
        FBox(Hps, X + 1, Y + 4, X + 30, Y + 28, CLR_BLACK, CLR_PALEGRAY);
        GText(Hps, X + 4, Y + 10, 'C:>', CLR_WHITE, CLR_BLACK);
      End;
    IC_BATCH :
      Begin
        IconPage(Hps, X, Y);
        FBox(Hps, X + 1, Y + 1, X + 17, Y + 12, CLR_BLACK, CLR_BLACK);
        GText(Hps, X + 2, Y - 2, 'C>', CLR_WHITE, CLR_BLACK);
      End;
    IC_FILE : IconPage(Hps, X, Y);
    IC_CDROM, IC_DISK :
      Begin
        FBox(Hps, X + 1, Y + 9, X + 30, Y + 22, CLR_PALEGRAY, CLR_BLACK);
        GLn(Hps, X + 5, Y + 16, X + 21, Y + 16, CLR_BLACK);
        If Icon = IC_CDROM Then GBox(Hps, X + 24, Y + 12, X + 27, Y + 13, CLR_GREEN, DRO_FILL)
        Else GBox(Hps, X + 24, Y + 12, X + 27, Y + 13, CLR_RED, DRO_FILL);
      End;
    IC_SHUTDOWN :
      Begin
        FBox(Hps, X + 6, Y + 4, X + 25, Y + 27, CLR_RED, CLR_DARKRED);
        GBox(Hps, X + 14, Y + 13, X + 17, Y + 24, CLR_WHITE, DRO_FILL);
        GBox(Hps, X + 10, Y + 8, X + 21, Y + 10, CLR_WHITE, DRO_FILL);
      End;
    IC_WINLIST :
      Begin
        FBox(Hps, X + 1, Y + 12, X + 20, Y + 29, CLR_PALEGRAY, CLR_BLACK);
        FBox(Hps, X + 2, Y + 26, X + 19, Y + 28, CLR_DARKBLUE, CLR_DARKBLUE);
        FBox(Hps, X + 11, Y + 2, X + 30, Y + 19, CLR_PALEGRAY, CLR_BLACK);
        FBox(Hps, X + 12, Y + 16, X + 29, Y + 18, CLR_DARKBLUE, CLR_DARKBLUE);
        FBox(Hps, X + 13, Y + 4, X + 28, Y + 14, CLR_WHITE, CLR_WHITE);
      End;
    IC_TEMPL :
      Begin
        IconFolder(Hps, X, Y, CLR_YELLOW);
        FBox(Hps, X + 8, Y + 6, X + 23, Y + 19, CLR_WHITE, CLR_DARKGRAY);
        GLn(Hps, X + 10, Y + 15, X + 21, Y + 15, CLR_DARKGRAY);
        GLn(Hps, X + 10, Y + 11, X + 21, Y + 11, CLR_DARKGRAY);
      End;
    IC_SHRED :
      Begin
        FBox(Hps, X + 6, Y + 18, X + 25, Y + 28, CLR_PALEGRAY, CLR_BLACK);
        GBox(Hps, X + 9, Y + 25, X + 22, Y + 26, CLR_BLACK, DRO_FILL);
        GLn(Hps, X + 9, Y + 4, X + 9, Y + 17, CLR_DARKGRAY);
        GLn(Hps, X + 13, Y + 2, X + 13, Y + 17, CLR_DARKGRAY);
        GLn(Hps, X + 17, Y + 5, X + 17, Y + 17, CLR_DARKGRAY);
        GLn(Hps, X + 21, Y + 3, X + 21, Y + 17, CLR_DARKGRAY);
      End;
    IC_INFO, IC_HELP :
      Begin
        FBox(Hps, X + 4, Y + 4, X + 27, Y + 27, CLR_BLUE, CLR_DARKBLUE);
        If Icon = IC_INFO Then GText(Hps, X + 12, Y + 8, 'i', CLR_WHITE, CLR_BLUE)
        Else GText(Hps, X + 12, Y + 8, '?', CLR_WHITE, CLR_BLUE);
      End;
  End;
End;

{ etiquette : deux lignes de 14 caracteres au plus }
Procedure SplitLabel(S : String; Var L1, L2 : String);
Var K : LongInt;
Begin
  L2 := '';
  If Length(S) <= 14 Then
  Begin
    L1 := S;
    Exit;
  End;
  K := 15;
  While (K > 1) And (S[K] <> ' ') Do Dec(K);
  If K <= 1 Then
  Begin
    L1 := Copy(S, 1, 14); L2 := Copy(S, 15, 255);
  End
  Else
  Begin
    L1 := Copy(S, 1, K - 1); L2 := Copy(S, K + 1, 255);
  End;
  If Length(L2) > 14 Then L2 := Copy(L2, 1, 12) + '..';
End;

Procedure DrawItem(Hps, K, Fg, Bg : LongInt);
Var X1, Y1, X2, Y2, V : LongInt; L1, L2 : String; Sel : Boolean;
Begin
  V := It(K)^.View;
  CellRect(K, X1, Y1, X2, Y2);
  Sel := Vw(V)^.Sel = K;
  DrawIcon(Hps, It(K)^.Icon, X1 + (CW - 32) Div 2, Y2 - 36);
  SplitLabel(It(K)^.Name, L1, L2);
  { raccourci : titre en couleur (bleu, jaune sur le bureau) }
  If It(K)^.Shadow <> 0 Then
  Begin
    If Vw(V)^.Kind = VK_DESK Then Fg := CLR_YELLOW Else Fg := CLR_BLUE;
  End;
  If Sel Then
  Begin
    Fg := CLR_WHITE; Bg := CLR_DARKBLUE;
  End;
  GText(Hps, X1 + (CW - Length(L1) * 8) Div 2, Y2 - 56, L1, Fg, Bg);
  If L2 <> '' Then GText(Hps, X1 + (CW - Length(L2) * 8) Div 2, Y2 - 72, L2, Fg, Bg);
End;

Procedure PaintView(V : LongInt);
Var Hps, K, X1, Y1, X2, Y2, Fg, Bg : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  Hps := WinBeginPaint(Vw(V)^.Client, 0, LongInt(@Rc));
  If Hps = 0 Then Exit;
  If Vw(V)^.Kind = VK_DESK Then
  Begin
    Bg := DeskRgb; Fg := CLR_WHITE;
  End
  Else
  Begin
    Bg := CLR_WHITE; Fg := CLR_BLACK;
  End;
  Dummy := WinFillRect(Hps, LongInt(@Rc), Bg);
  If Vw(V)^.Kind = VK_DESK Then
    GText(Hps, ScrW - 26 * 8, 4, 'OS/2-0  Workplace Shell', CLR_PALEGRAY, Bg);
  For K := 0 To ItemCap - 1 Do
    If (It(K)^.Use <> 0) And (It(K)^.View = V) Then
    Begin
      CellRect(K, X1, Y1, X2, Y2);
      If (X2 > Rc[0]) And (X1 < Rc[2]) And (Y2 > Rc[1]) And (Y1 < Rc[3]) Then DrawItem(Hps, K, Fg, Bg);
    End;
  Dummy := WinEndPaint(Hps);
End;

{ ==================================================================== }
{ Menus contextuels                                                     }
{ ==================================================================== }

Procedure MenuStart;
Begin
  MenuLen := 6; MenuCnt := 0;
End;

Procedure MenuAdd(Id : LongInt; S : String);
Begin
  If Id = 0 Then WrW(LongInt(@MenuTpl) + MenuLen, 4) Else WrW(LongInt(@MenuTpl) + MenuLen, 1);
  WrW(LongInt(@MenuTpl) + MenuLen + 2, 0);
  WrW(LongInt(@MenuTpl) + MenuLen + 4, Id);
  MenuLen := MenuLen + 6;
  If Id <> 0 Then
  Begin
    PutZ(LongInt(@MenuTpl) + MenuLen, S);
    MenuLen := MenuLen + Length(S) + 1;
  End;
  Inc(MenuCnt);
End;

Procedure MenuShow(V, X, Y, First : LongInt);
Begin
  WrW(LongInt(@MenuTpl), MenuLen); WrW(LongInt(@MenuTpl) + 2, 0); WrW(LongInt(@MenuTpl) + 4, MenuCnt);
  If MenuH <> 0 Then Dummy := WinDestroyWindow(MenuH);
  MenuH := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuTpl));
  If MenuH <> 0 Then Dummy := WinPopupMenu(Vw(V)^.Client, Vw(V)^.Client, MenuH, X, Y, First, 0);
End;

Procedure ContextMenu(V, K, X, Y : LongInt);
Begin
  MenuView := V; MenuItem := K;
  MenuStart;
  If K >= 0 Then
  Begin
    MenuAdd(CM_OPEN, '~Ouvrir');
    If (It(K)^.Obj >= OB_TPLDIR) And (It(K)^.Obj <= OB_TPLCMD) Then MenuAdd(CM_CREATE, '~Creer un autre')
    Else MenuAdd(CM_SHADOW, '~Creer un raccourci');
    MenuAdd(CM_PROPS, '~Proprietes');
    If Deletable(K) Then
    Begin
      MenuAdd(0, '');
      MenuAdd(CM_DELETE, '~Supprimer...');
    End;
  End
  Else If Vw(V)^.Kind = VK_DESK Then
  Begin
    MenuAdd(CM_REFRESH, '~Actualiser');
    MenuAdd(CM_ARRANGE, '~Reorganiser');
    MenuAdd(0, '');
    MenuAdd(CM_WINLIST, '~Liste des fenetres');
    MenuAdd(CM_INFO, '~Informations systeme');
    MenuAdd(CM_HELP, 'Ai~de');
    MenuAdd(0, '');
    MenuAdd(CM_SHUTDOWN, 'A~rret...');
  End
  Else
  Begin
    MenuAdd(CM_REFRESH, '~Actualiser');
    If Vw(V)^.Kind = VK_DIR Then
    Begin
      MenuAdd(CM_PARENT, '~Dossier parent');
      MenuAdd(CM_CMDHERE, '~Invite de commandes ici');
    End;
    MenuAdd(0, '');
    MenuAdd(CM_CLOSE, '~Fermer');
  End;
  If K >= 0 Then MenuShow(V, X, Y, CM_OPEN) Else MenuShow(V, X, Y, CM_REFRESH);
End;

{ ==================================================================== }
{ Fenetres                                                              }
{ ==================================================================== }

Function NewView(Kind : LongInt; Path, Title : String) : LongInt;
Var K, F : LongInt;
Begin
  F := -1;
  For K := ViewCap - 1 DownTo 0 Do
    If Vw(K)^.Use = 0 Then F := K;
  If F < 0 Then
  Begin
    F := ViewCap;
    Grow(ViewBuf, ViewCap, SizeOf(TView));
  End;
  If F >= 0 Then
  Begin
    Vw(F)^.Use := 1; Vw(F)^.Kind := Kind; Vw(F)^.Path := Path; Vw(F)^.Title := Title; Vw(F)^.Sel := -1; Vw(F)^.Top := 0;
    Vw(F)^.Max := 0; Vw(F)^.Frame := 0; Vw(F)^.Client := 0; Vw(F)^.List := 0; Vw(F)^.Hidden := 0;
  End;
  NewView := F;
End;

{ la fenetre utilisee le plus recemment reprend la main }
Procedure ActivateLast;
Var K, B : LongInt;
Begin
  B := -1;
  For K := 0 To ViewCap - 1 Do
    If (Vw(K)^.Use <> 0) And (Vw(K)^.Frame <> 0) Then
      If (WinQueryWindowULong(Vw(K)^.Frame, QWL_STYLE) And WS_MINIMIZED) = 0 Then
        If (B < 0) Or (Vw(K)^.Stamp > Vw(B)^.Stamp) Then B := K;
  If B >= 0 Then Dummy := WinSetActiveWindow(HWND_DESKTOP, Vw(B)^.Frame)
  Else If Desk <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Desk);
End;

Procedure CloseView(V : LongInt);
Begin
  If (V < 0) Or (Vw(V)^.Use = 0) Or (Vw(V)^.Kind = VK_DESK) Then Exit;
  ClearItems(V);
  Vw(V)^.Use := 0;
  If Vw(V)^.Frame <> 0 Then Dummy := WinDestroyWindow(Vw(V)^.Frame);
  Vw(V)^.Frame := 0; Vw(V)^.Client := 0;
  ActivateLast;
End;

Function OpenFrame(V : LongInt; Cls : String; Fl, X, Y, W, H : LongInt) : Boolean;
Var Fr, Cl, Flags : LongInt;
Begin
  Flags := Fl;
  Creating := V;
  Cl := 0;
  Fr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flags), Z(Cls), Z2(Vw(V)^.Title), 0, 0, 0, LongInt(@Cl));
  Creating := -1;
  If (Fr = 0) Or (Cl = 0) Then
  Begin
    Vw(V)^.Use := 0;
    OpenFrame := False;
    Exit;
  End;
  Vw(V)^.Frame := Fr; Vw(V)^.Client := Cl;
  Inc(Stamp);
  Vw(V)^.Stamp := Stamp;
  Dummy := WinSetWindowPos(Fr, HWND_TOP, X, Y, W, H, SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Fr);
  OpenFrame := True;
End;

Function FindView(Kind : LongInt; Path : String) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 0 To ViewCap - 1 Do
    If (Vw(K)^.Use <> 0) And (Vw(K)^.Kind = Kind) And (UpStr(Vw(K)^.Path) = UpStr(Path)) Then R := K;
  FindView := R;
End;

Procedure ActivateView(V : LongInt);
Begin
  Inc(Stamp);
  Vw(V)^.Stamp := Stamp;
  If Vw(V)^.Frame = 0 Then
  Begin
    Dummy := WinSetFocus(HWND_DESKTOP, Vw(V)^.Client);
    Exit;
  End;
  If (WinQueryWindowULong(Vw(V)^.Frame, QWL_STYLE) And WS_MINIMIZED) <> 0 Then
    Dummy := WinSetWindowPos(Vw(V)^.Frame, HWND_TOP, 0, 0, 0, 0, SWP_RESTORE Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Vw(V)^.Frame);
End;

Function NViews : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To ViewCap - 1 Do
    If (Vw(K)^.Use <> 0) And (Vw(K)^.Kind <> VK_DESK) Then Inc(N);
  NViews := N;
End;

Procedure OpenFolder(Kind : LongInt; Path, Title : String);
Var V, N : LongInt;
Begin
  V := FindView(Kind, Path);
  If V >= 0 Then
  Begin
    ActivateView(V);
    Exit;
  End;
  V := NewView(Kind, Path, Title);
  If V < 0 Then
  Begin
    ShowMsg('Trop de fenetres ouvertes. Fermez-en une.', 'Bureau', MB_OK Or MB_WARNING);
    Exit;
  End;
  N := NViews Mod 6;
  If OpenFrame(V, 'WPFolder', FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_SIZEBORDER Or
               FCF_VERTSCROLL, 130 + N * 24, ScrH - 330 - N * 24, 420, 300) Then
  Begin
    Populate(V);
    { premier objet choisi (clavier) }
    For N := ItemCap - 1 DownTo 0 Do
      If (It(N)^.Use <> 0) And (It(N)^.View = V) Then Vw(V)^.Sel := N;
    Dummy := WinInvalidateRect(Vw(V)^.Client, 0, 1);
  End;
End;

{ visionneuse : lignes du fichier dans une liste }
Procedure OpenViewer(Path : String);
Var V, H, A, N, K, C, NLines : LongInt; LineS : String; B : Array[0..259] Of Byte;
Begin
  V := FindView(VK_VIEWER, Path);
  If V >= 0 Then
  Begin
    ActivateView(V);
    Exit;
  End;
  V := NewView(VK_VIEWER, Path, Path);
  If V < 0 Then Exit;
  If Not OpenFrame(V, 'WPView', FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_SIZEBORDER,
                   60, 60, 520, 360) Then Exit;
  H := 0; A := 0;
  If DosOpen(Z(Path), LongInt(@H), LongInt(@A), 0, 0, 1, $40, 0) <> 0 Then
  Begin
    PutZ(LongInt(@B), '(fichier illisible)');
    Dummy := WinSendMsg(Vw(V)^.List, LM_INSERTITEM, -1, LongInt(@B));
    Exit;
  End;
  LineS := ''; NLines := 0;
  Repeat
    N := 0;
    If DosRead(H, LongInt(@FileBuf), 4096, LongInt(@N)) <> 0 Then N := 0;
    For K := 0 To N - 1 Do
    Begin
      C := FileBuf[K];
      If C = 10 Then
      Begin
        If NLines < 2000 Then
        Begin
          PutZ(LongInt(@B), LineS);
          Dummy := WinSendMsg(Vw(V)^.List, LM_INSERTITEM, -1, LongInt(@B));
        End;
        Inc(NLines);
        LineS := '';
      End
      Else If C = 9 Then
      Begin
        Repeat
          If Length(LineS) < 250 Then LineS := LineS + ' ';
        Until (Length(LineS) Mod 8 = 0) Or (Length(LineS) >= 250);
      End
      Else If (C >= 32) And (Length(LineS) < 250) Then LineS := LineS + Chr(C);
    End;
  Until N <= 0;
  If (LineS <> '') And (NLines < 2000) Then
  Begin
    PutZ(LongInt(@B), LineS);
    Dummy := WinSendMsg(Vw(V)^.List, LM_INSERTITEM, -1, LongInt(@B));
  End;
  Dummy := DosClose(H);
  Dummy := WinSendMsg(Vw(V)^.List, LM_SELECTITEM, 0, 1);
  Dummy := WinSetFocus(HWND_DESKTOP, Vw(V)^.List);
End;

{ liste des fenetres (Ctrl+Echap) }
Procedure FillWinList(V : LongInt);
Var K : LongInt; B : Array[0..259] Of Byte; Info : Array[0..15] Of LongInt;
Begin
  Dummy := WinSendMsg(Vw(V)^.List, LM_DELETEALL, 0, 0);
  PutZ(LongInt(@B), 'Bureau');
  Dummy := WinSendMsg(Vw(V)^.List, LM_INSERTITEM, -1, LongInt(@B));
  For K := 0 To ViewCap - 1 Do
    If (Vw(K)^.Use <> 0) And (Vw(K)^.Kind <> VK_DESK) And (Vw(K)^.Kind <> VK_LIST) Then
    Begin
      PutZ(LongInt(@B), Vw(K)^.Title);
      Dummy := WinSendMsg(Vw(V)^.List, LM_INSERTITEM, -1, LongInt(@B));
    End;
  { sessions en mode texte (programmes lances, plein ecran) }
  WlViews := WinSendMsg(Vw(V)^.List, LM_QUERYITEMCOUNT, 0, 0);
  WlNS := 0;
  For K := 0 To 15 Do
    If (WlNS < 32) And (KSes(7, K, LongInt(@Info)) = 1) Then
      If (Info[3] > 0) And (Info[2] = 0) And (K <> KSes(10, 0, 0)) Then
      Begin
        PutZ(LongInt(@B), GetZ(LongInt(@Info) + 16) + ' (plein ecran)');
        Dummy := WinSendMsg(Vw(V)^.List, LM_INSERTITEM, -1, LongInt(@B));
        WlSess[WlNS] := K;
        Inc(WlNS);
      End;
  Dummy := WinSendMsg(Vw(V)^.List, LM_SELECTITEM, 0, 1);
End;

Procedure OpenWinList;
Var V : LongInt;
Begin
  V := FindView(VK_LIST, '');
  If V < 0 Then
  Begin
    V := NewView(VK_LIST, '', 'Liste des fenetres');
    If V < 0 Then Exit;
    If Not OpenFrame(V, 'WPList', FCF_TITLEBAR Or FCF_SYSMENU, (ScrW - 320) Div 2, (ScrH - 240) Div 2, 320, 240) Then
      Exit;
  End
  Else ActivateView(V);
  FillWinList(V);
  Dummy := WinSetFocus(HWND_DESKTOP, Vw(V)^.List);
End;

Procedure WinListChoose(V : LongInt);
Var Sel, K, N, T : LongInt;
Begin
  Sel := WinSendMsg(Vw(V)^.List, LM_QUERYSELECTION, -1, 0);
  T := -1;
  If (Sel >= WlViews) And (Sel - WlViews < WlNS) Then
  Begin
    { session plein ecran : au premier plan }
    CloseView(V);
    Dummy := KSes(3, WlSess[Sel - WlViews], 0);
    Exit;
  End;
  If Sel = 0 Then T := 0
  Else If Sel > 0 Then
  Begin
    N := 0;
    For K := 0 To ViewCap - 1 Do
      If (Vw(K)^.Use <> 0) And (Vw(K)^.Kind <> VK_DESK) And (Vw(K)^.Kind <> VK_LIST) Then
      Begin
        Inc(N);
        If N = Sel Then T := K;
      End;
  End;
  CloseView(V);
  If T = 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Desk)
  Else If T > 0 Then ActivateView(T);
End;

{ ==================================================================== }
{ Programmes                                                            }
{ ==================================================================== }

{ cacher les fenetres du bureau pendant un programme }
Procedure HideAll;
Var K : LongInt;
Begin
  If MenuH <> 0 Then Dummy := WinDestroyWindow(MenuH);
  MenuH := 0;
  For K := 0 To ViewCap - 1 Do
    If Vw(K)^.Use <> 0 Then
    Begin
      If Vw(K)^.Frame <> 0 Then
      Begin
        Vw(K)^.Hidden := WinIsWindowVisible(Vw(K)^.Frame);
        If Vw(K)^.Hidden <> 0 Then Dummy := WinShowWindow(Vw(K)^.Frame, 0);
      End;
    End;
  If Desk <> 0 Then Dummy := WinShowWindow(Desk, 0);
End;

Procedure SetDeskColor;
Var C : LongInt;
Begin
  C := DeskRgb;
  Dummy := WinSetSysColors(HWND_DESKTOP, 0, 2, -24, 1, LongInt(@C));
End;

Procedure ShowAll(Act : LongInt);
Var K : LongInt;
Begin
  SetDeskColor;
  If Desk <> 0 Then Dummy := WinShowWindow(Desk, 1);
  For K := 0 To ViewCap - 1 Do
    If (Vw(K)^.Use <> 0) And (Vw(K)^.Frame <> 0) And (Vw(K)^.Hidden <> 0) Then Dummy := WinShowWindow(Vw(K)^.Frame, 1);
  If (Act <> 0) And (ViewOf(Act) >= 0) Then Dummy := WinSetActiveWindow(HWND_DESKTOP, Act)
  Else If Desk <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Desk);
  Dummy := WinInvalidateRect(HWND_DESKTOP, 0, 1);
End;

{ attendre une touche (programme en mode texte) }
Procedure WaitKey(Code : LongInt);
Var Ki : Array[0..15] Of Byte; S : String; At : Byte;
Begin
  S := ' Programme termine (code ' + IStr(Code) + '). Appuyez sur une touche pour revenir au bureau. ';
  At := $70;
  Dummy := VioWrtCharStrAtt(Z(S), Length(S), 24, 0, LongInt(@At), 0);
  Dummy := KbdCharIn(LongInt(@Ki), 0, 0);
End;

{ lancer un programme (DosExecPgm synchrone) dans le repertoire Dir }
Function BaseName(S : String) : String;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '\') And (S[K] <> ':') Do Dec(K);
  BaseName := Copy(S, K + 1, 255);
End;

Procedure RunProgram(Prog, Params, Dir : String; Pause : Boolean);
Var Res : Array[0..1] Of LongInt; Rc, Act, K, S : LongInt; D, T : String;
Begin
  Act := WinQueryActiveWindow(HWND_DESKTOP);
  If Dir <> '' Then
  Begin
    If (Length(Dir) >= 2) And (Dir[2] = ':') Then Dummy := DosSetDefaultDisk(Ord(UpCase(Dir[1])) - 64);
    D := Dir;
    If (Length(D) > 3) And (D[Length(D)] = '\') Then D := Copy(D, 1, Length(D) - 1);
    Dummy := DosSetCurrentDir(Z(D));
  End;
  { arguments : programme, nul, parametres, nul, nul }
  PutZ(LongInt(@ArgBuf), Prog);
  K := Length(Prog) + 1;
  PutZ(LongInt(@ArgBuf) + K, Params);
  WrB(LongInt(@ArgBuf) + K + Length(Params) + 1, 0);
  { nouvelle session plein ecran (un programme de PM la quitte pour la
    session de Presentation Manager) ; le bureau continue de s'executer }
  If (Params = '') And (Prog = Comspec) Then T := 'Invite de commandes OS/2'
  Else T := UpStr(BaseName(Prog));
  S := KSes(4, Z(T), 0);
  If S < 0 Then
  Begin
    ShowMsg('Trop de sessions : fermez un programme.', 'Bureau', MB_OK Or MB_WARNING);
    Exit;
  End;
  If Pause Then Dummy := KSes(16, S, 1);
  Dummy := KSes(12, S, 0);
  PutZ(LongInt(@NameZ2), Prog);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), LongInt(@NameZ2));
  If Rc <> 0 Then
  Begin
    Dummy := KSes(12, -1, 0);
    Dummy := KSes(17, S, 0);
    ShowMsg('SYS1041: Impossible de lancer ' + Prog + ' (erreur ' + IStr(Rc) + ').', 'Bureau', MB_OK Or MB_ERROR);
  End
  Else Dummy := KSes(3, S, 0);
End;

{ ==================================================================== }
{ Actions                                                               }
{ ==================================================================== }

Procedure SysInfo;
Var Q : Array[0..31] Of LongInt; T : String;
Begin
  Q[0] := 0;
  Dummy := DosQuerySysInfo(1, 26, LongInt(@Q), 104);
  T := 'OS/2-0, clone d''OS/2 (version ' + IStr(Q[10]) + '.' + IStr(Q[11]) + '). Memoire : ' +
       IStr(Q[16] Div 1024) + ' Ko. Depuis le demarrage : ' + IStr(Q[13] Div 1000) + ' s. Bureau : PMSHELL.EXE.';
  ShowMsg(T, 'Informations systeme', MB_OK Or MB_INFORMATION);
End;

Procedure Help;
Begin
  ShowMsg('Souris : clic pour choisir, double clic pour ouvrir, bouton 2 pour le menu. Clavier : fleches, Entree, ' +
      'Maj+F10 (menu), Ctrl+Echap (fenetres), F5, Suppr, Retour arriere, Alt+F4.', 'Aide du bureau',
      MB_OK Or MB_INFORMATION);
End;

Procedure Shutdown;
Var Ki : Array[0..15] Of Byte; S : String; At : Byte; K : LongInt;
Begin
  If WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, Z('L''arret du systeme ferme toutes les fenetres. Voulez-vous ' +
                   'arreter le systeme ?'), Z2('Arret'), 0, MB_OKCANCEL Or MB_QUERY Or MB_MOVEABLE) <> MBID_OK Then Exit;
  For K := 0 To ViewCap - 1 Do
    If (Vw(K)^.Use <> 0) And (Vw(K)^.Kind <> VK_DESK) Then CloseView(K);
  Dummy := DosShutdown(0);
  HideAll;
  Dummy := WinSuspendScreen;
  At := $1F;
  Ki[0] := 32; Ki[1] := $1F;
  Dummy := VioScrollUp(0, 0, 24, 79, 25, LongInt(@Ki), 0);
  S := 'L''arret est termine.';
  Dummy := VioWrtCharStrAtt(Z(S), Length(S), 10, (80 - Length(S)) Div 2, LongInt(@At), 0);
  S := 'Vous pouvez maintenant mettre l''ordinateur hors tension,';
  Dummy := VioWrtCharStrAtt(Z(S), Length(S), 12, (80 - Length(S)) Div 2, LongInt(@At), 0);
  S := 'ou appuyer sur Ctrl+Alt+Suppr pour redemarrer.';
  Dummy := VioWrtCharStrAtt(Z(S), Length(S), 13, (80 - Length(S)) Div 2, LongInt(@At), 0);
  Dummy := VioSetCurPos(24, 79, 0);
  { Ctrl+Alt+Suppr est traite par le noyau (redemarrage) }
  Repeat
    If KbdCharIn(LongInt(@Ki), 0, 0) <> 0 Then Dummy := DosSleep(100);
  Until False;
End;

Procedure Props(K : LongInt);
Var T : String;
Begin
  T := It(K)^.Name;
  Case It(K)^.Obj Of
    OB_DIR : T := T + ' : dossier ' + It(K)^.Path + '.';
    OB_EXE : T := T + ' : programme ' + It(K)^.Path + ' (' + IStr(It(K)^.Size) + ' octets).';
    OB_BATCH : T := T + ' : fichier de commandes ' + It(K)^.Path + ' (' + IStr(It(K)^.Size) + ' octets).';
    OB_DATA : T := T + ' : fichier de donnees ' + It(K)^.Path + ' (' + IStr(It(K)^.Size) + ' octets).';
    OB_CMD : T := T + ' : ' + Comspec + ' (plein ecran).';
  Else
    T := T + ' : objet du systeme.';
  End;
  ShowMsg(T, 'Proprietes', MB_OK Or MB_INFORMATION);
End;

Function DirOf(S : String) : String;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '\') Do Dec(K);
  DirOf := Copy(S, 1, K);
End;

{ actualiser les vues qui montrent le repertoire Dir (et le bureau pour
  C:\DESKTOP et les raccourcis) }
Procedure RefreshDir(Dir : String);
Var V : LongInt;
Begin
  Dir := UpStr(Dir);
  For V := 0 To ViewCap - 1 Do
    If Vw(V)^.Use <> 0 Then
      If ((Vw(V)^.Kind = VK_DIR) And (UpStr(Vw(V)^.Path) = Dir)) Or
         ((Vw(V)^.Kind = VK_DESK) And ((Dir = DeskDir) Or (Dir = ''))) Then
      Begin
        Populate(V);
        Dummy := WinInvalidateRect(Vw(V)^.Client, 0, 1);
      End;
End;

{ deposer l'objet S dans la vue TV (sur l'objet TK, ou -1) ; Kc : touches
  (Ctrl : copier, Ctrl+Maj : raccourci, sinon deplacer) }
Procedure DoDrop(S, TV, TK, Kc : LongInt);
Var Dest, Src, Nm, SrcDir : String; R : LongInt; Copy2 : Boolean;
Begin
  If (S < 0) Or (TV < 0) Or (TK = S) Then Exit;
  Dest := '';
  If TK >= 0 Then
  Begin
    If It(TK)^.Obj = OB_SHRED Then
    Begin
      SrcDir := DirOf(It(S)^.Path);
      If DoDelete(S, True) Then
      Begin
        RefreshDir(SrcDir);
        RefreshDir('');
        If It(S)^.Use <> 0 Then Refresh(It(S)^.View);
      End;
      Exit;
    End;
    If It(TK)^.Obj = OB_DIR Then Dest := It(TK)^.Path;
  End;
  If Dest = '' Then
  Begin
    If Vw(TV)^.Kind = VK_DESK Then Dest := DeskDir
    Else If Vw(TV)^.Kind = VK_DIR Then Dest := Vw(TV)^.Path
    Else
    Begin
      ShowMsg('Impossible de deposer un objet ici.', 'Bureau', MB_OK Or MB_WARNING);
      Exit;
    End;
  End;
  If Dest[Length(Dest)] <> '\' Then Dest := Dest + '\';
  { modele : un nouvel objet }
  If (It(S)^.Obj >= OB_TPLDIR) And (It(S)^.Obj <= OB_TPLCMD) Then
  Begin
    If CreateFromTemplate(It(S)^.Obj, Dest) Then RefreshDir(Dest)
    Else ShowMsg('Impossible de creer l''objet dans ' + Dest + '.', 'Modeles', MB_OK Or MB_ERROR);
    Exit;
  End;
  { objet du systeme, raccourci, ou Ctrl+Maj : raccourci }
  If (It(S)^.Path = '') Or (It(S)^.Shadow <> 0) Or ((Kc And (KC_CTRL Or KC_SHIFT)) = (KC_CTRL Or KC_SHIFT)) Then
  Begin
    MakeShadow(ContOf(Dest), It(S)^.Name, TargetOf(S));
    { un raccourci deplace (sans Ctrl) quitte son ancien dossier }
    If (It(S)^.Shadow <> 0) And ((Kc And KC_CTRL) = 0) Then
    Begin
      If Vw(It(S)^.View)^.Kind = VK_DESK Then DelShadow('BUREAU', It(S)^.Name)
      Else DelShadow(UpStr(Vw(It(S)^.View)^.Path), It(S)^.Name);
      Refresh(It(S)^.View);
    End;
    RefreshDir(Dest);
    Exit;
  End;
  { fichier ou dossier : deplacer (meme unite) ou copier (Ctrl, autre unite) }
  Src := It(S)^.Path;
  If Src[Length(Src)] = '\' Then Src := Copy(Src, 1, Length(Src) - 1);
  If Length(Src) <= 2 Then
  Begin
    ShowMsg('Une unite ne peut etre ni deplacee ni copiee ; Ctrl+Maj cree un raccourci.', 'Bureau',
            MB_OK Or MB_WARNING);
    Exit;
  End;
  Nm := Src;
  While Pos('\', Nm) > 0 Do Delete(Nm, 1, Pos('\', Nm));
  SrcDir := DirOf(Src);
  If UpStr(SrcDir) = UpStr(Dest) Then Exit;
  If (Length(UpStr(Dest)) > Length(UpStr(Src))) And (Copy(UpStr(Dest), 1, Length(Src) + 1) = UpStr(Src) + '\') Then
  Begin
    ShowMsg('Un dossier ne peut pas etre depose dans lui-meme.', 'Bureau', MB_OK Or MB_WARNING);
    Exit;
  End;
  Copy2 := ((Kc And KC_CTRL) <> 0) Or (UpCase(Src[1]) <> UpCase(Dest[1]));
  If Copy2 Then R := DosCopy(Z(Src), Z2(Dest + Nm), 0)
  Else R := DosMove(Z(Src), Z2(Dest + Nm));
  If R <> 0 Then
  Begin
    If Copy2 Then ShowMsg('Copie impossible de ' + Src + ' vers ' + Dest + ' (erreur ' + IStr(R) + ').', 'Bureau',
                          MB_OK Or MB_ERROR)
    Else ShowMsg('Deplacement impossible de ' + Src + ' vers ' + Dest + ' (erreur ' + IStr(R) + ').', 'Bureau',
                 MB_OK Or MB_ERROR);
    Exit;
  End;
  RefreshDir(Dest);
  If Not Copy2 Then RefreshDir(SrcDir);
End;

{ fin d'un glisser : vue et objet sous le point (ecran) X, Y }
Procedure DropAt(X, Y, Kc : LongInt);
Var Pt : Array[0..1] Of LongInt; Hw, TV, TK, N, Lp : LongInt;
Begin
  Pt[0] := X; Pt[1] := Y;
  Hw := WinWindowFromPoint(HWND_DESKTOP, LongInt(@Pt), 1);
  { depot sur le LaunchPad : il ajoute l'objet }
  Lp := PrfInt('LAUNCHPAD', 'HWND');
  If (Lp <> 0) And (Hw = Lp) And (DSrc >= 0) Then
  Begin
    PrfSet('LAUNCHPAD', 'DEPOT', TargetOf(DSrc));
    PrfSet('LAUNCHPAD', 'DEPOTNOM', It(DSrc)^.Name);
    Dummy := WinPostMsg(Lp, WM_REQUEST, X, Y);
    Exit;
  End;
  TV := -1; N := 0;
  While (Hw > 1) And (TV < 0) And (N < 16) Do
  Begin
    TV := ViewOf(Hw);
    If TV < 0 Then Hw := WinQueryWindow(Hw, QW_PARENT);
    Inc(N);
  End;
  { fond de l'ecran : la fenetre du bureau }
  If (TV < 0) And (Hw <= 1) And (Desk <> 0) Then TV := ViewOf(Desk);
  If TV < 0 Then Exit;
  Pt[0] := X; Pt[1] := Y;
  Dummy := WinMapWindowPoints(HWND_DESKTOP, Vw(TV)^.Client, LongInt(@Pt), 1);
  TK := HitItem(TV, Pt[0], Pt[1]);
  DoDrop(DSrc, TV, TK, Kc);
End;

Procedure OpenItem(K : LongInt);
Var V : LongInt; P : String;
Begin
  If (K < 0) Or (It(K)^.Use = 0) Then Exit;
  V := It(K)^.View;
  Case It(K)^.Obj Of
    OB_SYS : OpenFolder(VK_SYS, '', 'Systeme OS/2');
    OB_DRIVES : OpenFolder(VK_DRIVES, '', 'Lecteurs');
    OB_CMD :
      Begin
        If Vw(V)^.Kind = VK_DIR Then P := Vw(V)^.Path Else P := '';
        RunProgram(Comspec, '', P, False);
      End;
    OB_SHUTDOWN : Shutdown;
    OB_WINLIST : OpenWinList;
    OB_INFO : SysInfo;
    OB_HELP : Help;
    OB_DIR : OpenFolder(VK_DIR, It(K)^.Path, It(K)^.Path);
    OB_EXE : RunProgram(It(K)^.Path, '', DirOf(It(K)^.Path), True);
    OB_BATCH : RunProgram(Comspec, '/C ' + It(K)^.Path, DirOf(It(K)^.Path), True);
    OB_DATA : OpenViewer(It(K)^.Path);
    OB_TEMPLATES : OpenFolder(VK_TEMPL, '', 'Modeles');
    OB_SHRED : ShowMsg('Glissez un objet sur le broyeur (bouton 2 de la souris) pour le supprimer.', 'Broyeur',
                       MB_OK Or MB_INFORMATION);
    OB_TPLDIR, OB_TPLDATA, OB_TPLCMD :
      If CreateFromTemplate(It(K)^.Obj, DeskDir) Then RefreshDir(DeskDir);
  End;
End;

{ un repertoire et son contenu }
Function RemoveTree(Dir : String) : LongInt;
Var H, N, Rc, A, K : LongInt; S : String; Fb : Array[0..299] Of Byte;
Begin
  If Dir[Length(Dir)] <> '\' Then Dir := Dir + '\';
  H := -1; N := 1;
  Rc := DosFindFirst(Z(Dir + '*.*'), LongInt(@H), $37, LongInt(@Fb), 300, LongInt(@N), 1);
  While (Rc = 0) And (N > 0) Do
  Begin
    A := RdL(LongInt(@Fb) + 24);
    S := '';
    For K := 0 To Fb[28] - 1 Do S := S + Chr(Fb[29 + K]);
    If (S <> '.') And (S <> '..') Then
    Begin
      If (A And $10) <> 0 Then Dummy := RemoveTree(Dir + S)
      Else Dummy := DosDelete(Z(Dir + S));
    End;
    N := 1;
    Rc := DosFindNext(H, LongInt(@Fb), 300, LongInt(@N));
  End;
  If H <> -1 Then Dummy := DosFindClose(H);
  RemoveTree := DosDeleteDir(Z(Copy(Dir, 1, Length(Dir) - 1)));
End;

{ l'objet K peut-il etre supprime ? (raccourci, fichier, dossier sauf la
  racine d'une unite) }
Function Deletable(K : LongInt) : Boolean;
Begin
  Deletable := (It(K)^.Shadow <> 0) Or (It(K)^.Obj = OB_EXE) Or (It(K)^.Obj = OB_BATCH) Or
               (It(K)^.Obj = OB_DATA) Or ((It(K)^.Obj = OB_DIR) And (Length(It(K)^.Path) > 3));
End;

{ supprimer l'objet K (Ask : confirmation) ; rend TRUE si fait }
Function DoDelete(K : LongInt; Ask : Boolean) : Boolean;
Var V, R : LongInt; T, Nm : String;
Begin
  DoDelete := False;
  If (K < 0) Or Not Deletable(K) Then Exit;
  V := It(K)^.View;
  If It(K)^.Shadow <> 0 Then T := 'le raccourci ' + It(K)^.Name
  Else If It(K)^.Obj = OB_DIR Then T := 'le dossier ' + It(K)^.Path + ' et son contenu'
  Else T := 'le fichier ' + It(K)^.Path;
  If Ask Then
    If WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, Z('Supprimer ' + T + ' ?'), Z2('Supprimer'), 0,
                     MB_YESNO Or MB_WARNING Or MB_MOVEABLE) <> MBID_YES Then Exit;
  If It(K)^.Shadow <> 0 Then
  Begin
    If Vw(V)^.Kind = VK_DESK Then DelShadow('BUREAU', It(K)^.Name) Else DelShadow(UpStr(Vw(V)^.Path), It(K)^.Name);
    R := 0;
  End
  Else If It(K)^.Obj = OB_DIR Then R := RemoveTree(It(K)^.Path)
  Else R := DosDelete(Z(It(K)^.Path));
  If R <> 0 Then
    ShowMsg('Impossible de supprimer ' + T + ' (unite en lecture seule ?).', 'Supprimer', MB_OK Or MB_ERROR)
  Else DoDelete := True;
End;

Procedure DeleteItem(K : LongInt);
Var V : LongInt; P : String;
Begin
  If K < 0 Then Exit;
  V := It(K)^.View;
  P := DirOf(It(K)^.Path);
  If DoDelete(K, True) Then
  Begin
    Populate(V);
    Dummy := WinInvalidateRect(Vw(V)^.Client, 0, 1);
    If P <> '' Then RefreshDir(P);
  End;
End;

Procedure ParentFolder(V : LongInt);
Var P : String; K : LongInt;
Begin
  If Vw(V)^.Kind <> VK_DIR Then Exit;
  P := Vw(V)^.Path;
  If Length(P) <= 3 Then
  Begin
    OpenFolder(VK_DRIVES, '', 'Lecteurs');
    Exit;
  End;
  K := Length(P) - 1;
  While (K > 0) And (P[K] <> '\') Do Dec(K);
  P := Copy(P, 1, K);
  OpenFolder(VK_DIR, P, P);
End;

Procedure Refresh(V : LongInt);
Begin
  If Vw(V)^.Kind = VK_DESK Then Layout(V) Else Populate(V);
  Dummy := WinInvalidateRect(Vw(V)^.Client, 0, 1);
End;

Procedure Arrange(V : LongInt);
Var K : LongInt; B : Array[0..3] Of Byte;
Begin
  B[0] := 0;
  For K := 0 To ItemCap - 1 Do
    If (It(K)^.Use <> 0) And (It(K)^.View = V) Then
      Dummy := PrfWriteProfileString(-1, Z('PMSHELL'), Z2('POS ' + It(K)^.Name), 0);
  Refresh(V);
End;

Procedure Command(V, Cmd : LongInt);
Var K : LongInt;
Begin
  K := MenuItem;
  If (K >= 0) And ((It(K)^.Use = 0) Or (It(K)^.View <> V)) Then K := -1;
  Case Cmd Of
    CM_OPEN : OpenItem(K);
    CM_PROPS : If K >= 0 Then Props(K);
    CM_DELETE : DeleteItem(K);
    CM_REFRESH : Refresh(V);
    CM_ARRANGE : Arrange(V);
    CM_WINLIST : OpenWinList;
    CM_INFO : SysInfo;
    CM_HELP : Help;
    CM_SHUTDOWN : Shutdown;
    CM_CLOSE : CloseView(V);
    CM_PARENT : ParentFolder(V);
    CM_CMDHERE : RunProgram(Comspec, '', Vw(V)^.Path, False);
    CM_SHADOW :
      If K >= 0 Then
      Begin
        MakeShadow('BUREAU', It(K)^.Name, TargetOf(K));
        RefreshDir(DeskDir);
      End;
    CM_CREATE :
      If K >= 0 Then
      Begin
        If CreateFromTemplate(It(K)^.Obj, DeskDir) Then RefreshDir(DeskDir);
      End;
  End;
End;

{ objet suivant dans une direction (dx, dy : -1, 0, 1) }
Procedure MoveSel(V, Dx, Dy : LongInt);
Var K, B, Best, Cx, Cy, X, Y, D : LongInt;
Begin
  If (Vw(V)^.Sel < 0) Or (It(Vw(V)^.Sel)^.Use = 0) Then
  Begin
    B := -1;
    For K := ItemCap - 1 DownTo 0 Do
      If (It(K)^.Use <> 0) And (It(K)^.View = V) Then B := K;
    If B >= 0 Then SelectItem(V, B);
    Exit;
  End;
  Cx := It(Vw(V)^.Sel)^.X; Cy := It(Vw(V)^.Sel)^.Top;
  B := -1; Best := $7FFFFFFF;
  For K := 0 To ItemCap - 1 Do
    If (It(K)^.Use <> 0) And (It(K)^.View = V) And (K <> Vw(V)^.Sel) Then
    Begin
      X := It(K)^.X - Cx; Y := It(K)^.Top - Cy;
      If ((Dx > 0) And (X > 8)) Or ((Dx < 0) And (X < -8)) Or ((Dy > 0) And (Y > 8)) Or ((Dy < 0) And (Y < -8)) Then
      Begin
        If Dx <> 0 Then D := AbsI(X) + 3 * AbsI(Y) Else D := AbsI(Y) + 3 * AbsI(X);
        If D < Best Then
        Begin
          Best := D; B := K;
        End;
      End;
    End;
  If B >= 0 Then
  Begin
    SelectItem(V, B);
    ShowItem(B);
  End;
End;

Procedure SelEdge(V : LongInt; Last : Boolean);
Var K, B : LongInt;
Begin
  B := -1;
  For K := 0 To ItemCap - 1 Do
    If (It(K)^.Use <> 0) And (It(K)^.View = V) Then
      If Last Or (B < 0) Then B := K;
  If B >= 0 Then
  Begin
    SelectItem(V, B);
    ShowItem(B);
  End;
End;

Procedure SelLetter(V, Ch : LongInt);
Var K, Start, B, J : LongInt;
Begin
  Start := Vw(V)^.Sel;
  B := -1;
  For J := 1 To ItemCap Do
  Begin
    K := (Start + J + ItemCap) Mod ItemCap;
    If (B < 0) And (It(K)^.Use <> 0) And (It(K)^.View = V) And (Length(It(K)^.Name) > 0) Then
      If UpCase(It(K)^.Name[1]) = UpCase(Chr(Ch)) Then B := K;
  End;
  If B >= 0 Then
  Begin
    SelectItem(V, B);
    ShowItem(B);
  End;
End;

{ ==================================================================== }
{ Procedures des fenetres (convention Pascal)                           }
{ ==================================================================== }

Function ViewKey(V, Mp1, Mp2 : LongInt) : Boolean;
Var Fs, Vk, Ch, X1, Y1, X2, Y2 : LongInt; Done : Boolean;
Begin
  ViewKey := True;
  Done := True;
  Fs := Lo16(Mp1); Vk := Hi16(Mp2); Ch := Lo16(Mp2);
  If (Fs And KC_KEYUP) <> 0 Then Exit;
  If (Fs And KC_VIRTUALKEY) <> 0 Then
  Begin
    If (Vk = VK_ESC) And ((Fs And KC_CTRL) <> 0) Then
    Begin
      OpenWinList;
      Exit;
    End;
    If (Vk = VK_F10) And ((Fs And KC_SHIFT) <> 0) Then
    Begin
      If (Vw(V)^.Sel >= 0) And (It(Vw(V)^.Sel)^.Use <> 0) Then
      Begin
        CellRect(Vw(V)^.Sel, X1, Y1, X2, Y2);
        ContextMenu(V, Vw(V)^.Sel, X1 + 40, Y1 + 20);
      End
      Else ContextMenu(V, -1, 40, ClientH(V) - 40);
      Exit;
    End;
    Case Vk Of
      VK_LEFT : MoveSel(V, -1, 0);
      VK_RIGHT : MoveSel(V, 1, 0);
      VK_UP : MoveSel(V, 0, -1);
      VK_DOWN : MoveSel(V, 0, 1);
      VK_HOME : SelEdge(V, False);
      VK_END : SelEdge(V, True);
      VK_ENTER, VK_NEWLINE : OpenItem(Vw(V)^.Sel);
      VK_F1 : Help;
      VK_F5 : Refresh(V);
      VK_DELETE : DeleteItem(Vw(V)^.Sel);
      VK_BACKSPACE : ParentFolder(V);
      VK_PAGEUP :
        If Vw(V)^.Kind <> VK_DESK Then
        Begin
          Vw(V)^.Top := Vw(V)^.Top - ClientH(V);
          UpdScroll(V);
          Dummy := WinInvalidateRect(Vw(V)^.Client, 0, 1);
        End;
      VK_PAGEDOWN :
        If Vw(V)^.Kind <> VK_DESK Then
        Begin
          Vw(V)^.Top := Vw(V)^.Top + ClientH(V);
          UpdScroll(V);
          Dummy := WinInvalidateRect(Vw(V)^.Client, 0, 1);
        End;
    Else
      Done := False;
    End;
    If Done Then Exit;
  End;
  If ((Fs And KC_CHAR) <> 0) And (Ch > 32) And (Ch < 127) And ((Fs And (KC_CTRL Or KC_ALT)) = 0) Then
  Begin
    SelLetter(V, Ch);
    Exit;
  End;
  ViewKey := False;
End;

{ demande d'un autre programme (LaunchPad) : OS2.INI, PMSHELL, REQn }
Procedure DoRequest(N : LongInt);
Var S, Verb, Arg : String; P : LongInt;
Begin
  S := PrfStr('PMSHELL', 'REQ' + IStr(N));
  PrfSet('PMSHELL', 'REQ' + IStr(N), '');
  If S = '' Then Exit;
  P := Pos(' ', S);
  If P > 0 Then
  Begin
    Verb := UpStr(Copy(S, 1, P - 1)); Arg := Copy(S, P + 1, 255);
  End
  Else
  Begin
    Verb := UpStr(S); Arg := '';
  End;
  If Verb = 'OPEN' Then
  Begin
    If (Arg <> '') And (Arg[Length(Arg)] <> '\') Then Arg := Arg + '\';
    OpenFolder(VK_DIR, Arg, Arg);
  End
  Else If Verb = 'DRIVES' Then OpenFolder(VK_DRIVES, '', 'Lecteurs')
  Else If Verb = 'SYS' Then OpenFolder(VK_SYS, '', 'Systeme OS/2')
  Else If Verb = 'TEMPL' Then OpenFolder(VK_TEMPL, '', 'Modeles')
  Else If Verb = 'CMD' Then RunProgram(Comspec, '', Arg, False)
  Else If Verb = 'RUN' Then RunProgram(Arg, '', DirOf(Arg), True)
  Else If Verb = 'BATCH' Then RunProgram(Comspec, '/C ' + Arg, DirOf(Arg), True)
  Else If Verb = 'VIEW' Then OpenViewer(Arg)
  Else If Verb = 'WINLIST' Then OpenWinList
  Else If Verb = 'HELP' Then Help
  Else If Verb = 'INFO' Then SysInfo
  Else If Verb = 'SHUTDOWN' Then Shutdown;
End;

Function ViewProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var V, K, X, Y, Dx, Dy, Sc, Hw : LongInt; Pt : Array[0..1] Of LongInt;
Begin
  ViewProc := 0;
  V := ViewOf(H);
  If (V < 0) And (Msg = WM_CREATE) And (Creating >= 0) Then
  Begin
    Vw(Creating)^.Client := H;
    V := Creating;
  End;
  If V < 0 Then
  Begin
    ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    Exit;
  End;
  Case Msg Of
    WM_SETFOCUS :
      If Lo16(Mp2) <> 0 Then
      Begin
        Inc(Stamp);
        Vw(V)^.Stamp := Stamp;
      End;
    WM_PAINT : PaintView(V);
    WM_SIZE :
      If Vw(V)^.Kind <> VK_DESK Then
      Begin
        Layout(V);
        UpdScroll(V);
        Dummy := WinInvalidateRect(H, 0, 1);
      End;
    WM_ACTIVATE :
      { le bureau reste sous les autres fenetres }
      If (Vw(V)^.Kind = VK_DESK) And (Lo16(Mp1) <> 0) Then
        Dummy := WinSetWindowPos(H, HWND_BOTTOM, 0, 0, 0, 0, SWP_ZORDER);
    WM_BUTTON1DOWN :
      Begin
        If Vw(V)^.Kind = VK_DESK Then Dummy := WinSetFocus(HWND_DESKTOP, H)
        Else ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        K := HitItem(V, X, Y);
        SelectItem(V, K);
        If (K >= 0) And (Vw(V)^.Kind = VK_DESK) Then
        Begin
          DragItem := K; DragX0 := X; DragY0 := Y; DragIX := It(K)^.X; DragITop := It(K)^.Top; Dragging := 0;
          Dummy := WinSetCapture(HWND_DESKTOP, H);
        End
        Else If K >= 0 Then
        Begin
          { dossier : glisser avec le bouton 1 }
          DSrc := K; DActive := 1;
          Pt[0] := X; Pt[1] := Y;
          Dummy := WinMapWindowPoints(H, HWND_DESKTOP, LongInt(@Pt), 1);
          DX0 := Pt[0]; DY0 := Pt[1];
          Dummy := WinSetCapture(HWND_DESKTOP, H);
        End;
        ViewProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        If (DragItem >= 0) And (It(DragItem)^.View = V) Then
        Begin
          X := S16(Mp1); Y := S16(Mp1 Shr 16);
          Dx := X - DragX0; Dy := Y - DragY0;
          If (Dragging = 0) And (AbsI(Dx) + AbsI(Dy) > 4) Then Dragging := 1;
          If Dragging <> 0 Then
          Begin
            InvalItem(DragItem);
            It(DragItem)^.X := MaxI(0, MinI(ScrW - CW, DragIX + Dx));
            It(DragItem)^.Top := MaxI(0, MinI(ScrH - CH, DragITop - Dy));
            InvalItem(DragItem);
          End;
        End;
        ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_BUTTON1UP :
      Begin
        If DragItem >= 0 Then
        Begin
          Dummy := WinSetCapture(HWND_DESKTOP, 0);
          K := DragItem;
          DragItem := -1;
          If Dragging <> 0 Then
          Begin
            { lache hors du bureau (sur un dossier) : glisser-deposer }
            Pt[0] := S16(Mp1); Pt[1] := S16(Mp1 Shr 16);
            Dummy := WinMapWindowPoints(H, HWND_DESKTOP, LongInt(@Pt), 1);
            Hw := WinWindowFromPoint(HWND_DESKTOP, LongInt(@Pt), 1);
            If (Hw <> 0) And (Hw <> H) And (ViewOf(Hw) <> V) Then
            Begin
              It(K)^.X := DragIX; It(K)^.Top := DragITop;
              Dummy := WinInvalidateRect(H, 0, 1);
              DSrc := K;
              DropAt(Pt[0], Pt[1], Hi16(Mp2));
            End
            Else SavePos(K);
          End;
          Dragging := 0;
        End
        Else If DActive <> 0 Then
        Begin
          Dummy := WinSetCapture(HWND_DESKTOP, 0);
          DActive := 0;
          Pt[0] := S16(Mp1); Pt[1] := S16(Mp1 Shr 16);
          Dummy := WinMapWindowPoints(H, HWND_DESKTOP, LongInt(@Pt), 1);
          If (AbsI(Pt[0] - DX0) + AbsI(Pt[1] - DY0) > 4) And (DSrc >= 0) Then DropAt(Pt[0], Pt[1], Hi16(Mp2));
          DSrc := -1;
        End;
        ViewProc := 1;
      End;
    WM_BUTTON1DBLCLK :
      Begin
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        DragItem := -1; Dragging := 0;
        Dummy := WinSetCapture(HWND_DESKTOP, 0);
        K := HitItem(V, X, Y);
        SelectItem(V, K);
        If K >= 0 Then OpenItem(K);
        ViewProc := 1;
      End;
    WM_BUTTON2DOWN :
      Begin
        If Vw(V)^.Kind = VK_DESK Then Dummy := WinSetFocus(HWND_DESKTOP, H)
        Else Dummy := WinDefWindowProc(H, Msg, Mp1, Mp2);
        { glisser avec le bouton 2 (comme le Workplace Shell) }
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        K := HitItem(V, X, Y);
        NoMenu := 0;
        If K >= 0 Then
        Begin
          DSrc := K; DActive := 2;
          Pt[0] := X; Pt[1] := Y;
          Dummy := WinMapWindowPoints(H, HWND_DESKTOP, LongInt(@Pt), 1);
          DX0 := Pt[0]; DY0 := Pt[1];
          Dummy := WinSetCapture(HWND_DESKTOP, H);
        End;
        ViewProc := 1;
      End;
    WM_BUTTON2UP :
      Begin
        If DActive = 2 Then
        Begin
          Dummy := WinSetCapture(HWND_DESKTOP, 0);
          DActive := 0;
          Pt[0] := S16(Mp1); Pt[1] := S16(Mp1 Shr 16);
          Dummy := WinMapWindowPoints(H, HWND_DESKTOP, LongInt(@Pt), 1);
          If (AbsI(Pt[0] - DX0) + AbsI(Pt[1] - DY0) > 4) And (DSrc >= 0) Then
          Begin
            NoMenu := 1;
            DropAt(Pt[0], Pt[1], Hi16(Mp2));
          End;
          DSrc := -1;
        End;
        ViewProc := 1;
      End;
    WM_BUTTON2CLICK :
      Begin
        If NoMenu = 0 Then
        Begin
          X := S16(Mp1); Y := S16(Mp1 Shr 16);
          K := HitItem(V, X, Y);
          If K >= 0 Then SelectItem(V, K);
          ContextMenu(V, K, X, Y);
        End;
        NoMenu := 0;
        ViewProc := 1;
      End;
    WM_COMMAND : Command(V, Lo16(Mp1));
    WM_REQUEST : If Vw(V)^.Kind = VK_DESK Then DoRequest(Mp1);
    WM_CHAR :
      If ViewKey(V, Mp1, Mp2) Then ViewProc := 1
      Else ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_VSCROLL :
      Begin
        Sc := Hi16(Mp2);
        Case Sc Of
          SB_LINEUP : Vw(V)^.Top := Vw(V)^.Top - 16;
          SB_LINEDOWN : Vw(V)^.Top := Vw(V)^.Top + 16;
          SB_PAGEUP : Vw(V)^.Top := Vw(V)^.Top - ClientH(V);
          SB_PAGEDOWN : Vw(V)^.Top := Vw(V)^.Top + ClientH(V);
          SB_SLIDERTRACK, SB_SLIDERPOSITION : Vw(V)^.Top := S16(Mp2);
        End;
        UpdScroll(V);
        Dummy := WinInvalidateRect(H, 0, 1);
      End;
    WM_SYSCOMMAND :
      If (Vw(V)^.Kind = VK_DESK) And (Lo16(Mp1) = SC_CLOSE) Then Shutdown
      Else ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_CLOSE :
      If Vw(V)^.Kind = VK_DESK Then Shutdown Else CloseView(V);
  Else
    ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ visionneuse et liste des fenetres : une liste dans le client }
Function ListProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var V, Fs, Vk : LongInt;
Begin
  ListProc := 0;
  V := ViewOf(H);
  If (V < 0) And (Msg = WM_CREATE) And (Creating >= 0) Then
  Begin
    V := Creating;
    Vw(V)^.Client := H;
    Vw(V)^.List := WinCreateWindow(H, WC_LISTBOX, 0, WS_VISIBLE, 0, 0, 100, 100, H, HWND_TOP, 1, 0, 0);
    Exit;
  End;
  If V < 0 Then
  Begin
    ListProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    Exit;
  End;
  Case Msg Of
    WM_SIZE :
      If Vw(V)^.List <> 0 Then
        Dummy := WinSetWindowPos(Vw(V)^.List, 0, 0, 0, Lo16(Mp2), Hi16(Mp2), SWP_SIZE Or SWP_MOVE);
    WM_CONTROL :
      If (Hi16(Mp1) = LN_ENTER) And (Vw(V)^.Kind = VK_LIST) Then WinListChoose(V);
    WM_CHAR :
      Begin
        Fs := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fs And KC_KEYUP) = 0) And ((Fs And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then CloseView(V)
        Else If ((Fs And KC_KEYUP) = 0) And ((Fs And KC_VIRTUALKEY) <> 0) And
                ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) And (Vw(V)^.Kind = VK_LIST) Then WinListChoose(V)
        Else ListProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE : CloseView(V);
    WM_PAINT : ListProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  Else
    ListProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

{ LaunchPad : programme de PM lance en arriere-plan dans la session de
  Presentation Manager (il s'execute en meme temps que le bureau) }
Procedure StartLaunchPad;
Var Res : Array[0..1] Of LongInt; P : String;
Begin
  If PrfStr('PMSHELL', 'LAUNCHPAD') = '0' Then Exit;
  P := 'C:\LAUNCHPD.EXE';
  If Not FileExists(P) Then Exit;
  PutZ(LongInt(@ArgBuf), P);
  WrB(LongInt(@ArgBuf) + Length(P) + 1, 0);
  WrB(LongInt(@ArgBuf) + Length(P) + 2, 0);
  PutZ(LongInt(@NameZ2), P);
  Res[0] := 0; Res[1] := 0;
  Dummy := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), LongInt(@NameZ2));
End;

Procedure StartupCmd;
Var S : String;
Begin
  S := '';
  If FileExists('C:\STARTUP.CMD') Then S := 'C:\STARTUP.CMD'
  Else If FileExists('D:\STARTUP.CMD') Then S := 'D:\STARTUP.CMD';
  If S <> '' Then RunProgram(Comspec, '/C ' + S, DirOf(S), False);
End;

BEGIN
  Creating := -1; MenuH := 0; Desk := 0; DragItem := -1; Dragging := 0; MenuItem := -1; MenuView := 0;
  ItemBuf := 0; ItemCap := 0; ViewBuf := 0; ViewCap := 0; EntBuf := 0; EntCap := 0;
  DSrc := -1; DActive := 0; NoMenu := 0;
  { bureau : C:\DESKTOP, ou D:\DESKTOP si C: est en lecture seule (CD-ROM) }
  Dummy := DosCreateDir(Z('C:\DESKTOP'), 0);
  If FileExists('C:\DESKTOP') Then DeskDir := 'C:\DESKTOP\'
  Else
  Begin
    Dummy := DosCreateDir(Z('D:\DESKTOP'), 0);
    DeskDir := 'D:\DESKTOP\';
  End;
  Grow(ItemBuf, ItemCap, SizeOf(TItem));
  Grow(ViewBuf, ViewCap, SizeOf(TView));
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  If Hmq = 0 Then
  Begin
    WriteLn('PMSHELL : Presentation Manager (PMWIN.DLL) ne peut pas demarrer.');
    Halt(1);
  End;
  SetDeskColor;
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20); ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  If ScrW <= 0 Then ScrW := 640;
  If ScrH <= 0 Then ScrH := 480;
  Dummy := WinRegisterClass(Hab, Z('WPDesktop'), LongInt(@ViewProc), 0, 8);
  Dummy := WinRegisterClass(Hab, Z('WPFolder'), LongInt(@ViewProc), 0, 8);
  Dummy := WinRegisterClass(Hab, Z('WPView'), LongInt(@ListProc), 0, 8);
  Dummy := WinRegisterClass(Hab, Z('WPList'), LongInt(@ListProc), 0, 8);
  StartupCmd;
  { bureau : fenetre de tout l'ecran, sous les autres }
  I := NewView(VK_DESK, '', 'Bureau');
  Creating := I;
  Desk := WinCreateWindow(HWND_DESKTOP, Z('WPDesktop'), Z2('Bureau'), WS_VISIBLE, 0, 0, ScrW, ScrH, 0, HWND_BOTTOM, 1, 0, 0);
  Creating := -1;
  Vw(I)^.Client := Desk; Vw(I)^.Frame := 0;
  Populate(I);
  Vw(I)^.Sel := -1;
  For I2 := 0 To ItemCap - 1 Do
    If (It(I2)^.Use <> 0) And (It(I2)^.View = I) And (Vw(I)^.Sel < 0) Then Vw(I)^.Sel := I2;
  Dummy := WinSetFocus(HWND_DESKTOP, Desk);
  Dummy := WinInvalidateRect(HWND_DESKTOP, 0, 1);
  PrfSet('PMSHELL', 'HWND', IStr(Desk));
  StartLaunchPad;
  { boucle des messages (WM_QUIT est ignore : le bureau ne se termine pas) }
  Repeat
    If WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Then Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Until False;
END.
