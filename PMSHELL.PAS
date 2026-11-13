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

  PMSHELL est le bureau d'OS/2-0. Le noyau le lance a la place de
  CMD.EXE quand CONFIG.SYS contient PROTSHELL=C:\PMSHELL.EXE (et le
  relance s'il se termine). Il affiche le bureau en mode graphique
  (640 x 480 x 16 couleurs, PMWIN.DLL) et s'utilise a la souris et au
  clavier :

  Bureau : objets Systeme OS/2, Lecteurs, Invite de commandes OS/2,
  Liste des fenetres et Arret. Les icones du bureau se deplacent a la
  souris (position gardee dans OS2.INI, application PMSHELL).
  Dossiers : Systeme OS/2 (invite de commandes, lecteurs, liste des
  fenetres, informations sur le systeme, aide, arret), Lecteurs (une
  icone par unite : C: CD-ROM, D: disque virtuel HPFS...), et les
  repertoires (sous-repertoires, programmes .EXE, fichiers de commandes
  .CMD/.BAT, fichiers de donnees). Un dossier deja ouvert est active au
  lieu d'etre ouvert une seconde fois.

  Souris : clic (bouton 1) : selection ; double clic : ouvrir ; bouton 2 :
  menu contextuel de l'objet ou du fond ; glisser une icone du bureau la
  deplace.
  Clavier : fleches, Debut, Fin : selection ; Entree : ouvrir ;
  Maj+F10 : menu contextuel ; Ctrl+Echap : liste des fenetres ; F5 :
  actualiser ; Retour arriere : dossier parent ; Suppr : supprimer le
  fichier choisi (apres confirmation) ; F1 : aide ; lettre : objet
  suivant qui commence par cette lettre ; Alt+F4 : fermer la fenetre
  (sur le bureau : arret du systeme) ; Echap : fermer la visionneuse ou
  la liste des fenetres.

  Programmes : un objet programme (.EXE), un fichier de commandes (par
  COMSPEC /C) ou l'invite de commandes (COMSPEC) est lance par
  DosExecPgm, dans le repertoire de son dossier. Le noyau d'OS/2-0
  execute un programme a la fois : pendant ce temps le bureau est cache
  et l'ecran est prete au programme (WINSUSPENDSCREEN de PMWIN : mode
  texte 80 x 25 ; un programme de PM reprend le mode graphique) ; a la
  fin du programme le bureau revient (WINRESUMESCREEN). Apres un
  programme en mode texte autre que l'invite de commandes, PMSHELL
  attend une touche pour laisser lire ce qu'il a affiche.
  Fichiers de donnees : visionneuse (texte du fichier dans une liste).
  STARTUP.CMD (C:\ ou D:\) est execute au demarrage, avant le bureau.

  Arret : apres confirmation, les fichiers sont ecrits (DosShutdown) et
  l'ecran indique que l'ordinateur peut etre eteint ; Ctrl+Alt+Suppr
  redemarre alors l'ordinateur. }

Const
  { messages }
  WM_CREATE = $0001; WM_DESTROY = $0002; WM_SIZE = $0007; WM_ACTIVATE = $000D;
  WM_SETFOCUS = $000F; WM_COMMAND = $0020; WM_SYSCOMMAND = $0021; WM_PAINT = $0023; WM_CLOSE = $0029; WM_CONTROL = $0030;
  WM_VSCROLL = $0031; WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072;
  WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074; WM_BUTTON2CLICK = $0416; WM_CHAR = $007A;
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
  MaxView = 24; MaxItem = 600; CW = 112; CH = 80;
  VK_DESK = 0; VK_SYS = 1; VK_DRIVES = 2; VK_DIR = 3; VK_VIEWER = 4; VK_LIST = 5;
  IC_FOLDER = 0; IC_SYSTEM = 1; IC_DRIVES = 2; IC_PROGRAM = 3; IC_CMD = 4; IC_BATCH = 5; IC_FILE = 6;
  IC_CDROM = 7; IC_DISK = 8; IC_SHUTDOWN = 9; IC_WINLIST = 10; IC_INFO = 11; IC_HELP = 12;
  OB_SYS = 1; OB_DRIVES = 2; OB_CMD = 3; OB_SHUTDOWN = 4; OB_WINLIST = 5; OB_INFO = 6; OB_HELP = 7;
  OB_DIR = 8; OB_EXE = 9; OB_BATCH = 10; OB_DATA = 11;
  { commandes des menus }
  CM_OPEN = 100; CM_REFRESH = 101; CM_ARRANGE = 102; CM_WINLIST = 103; CM_INFO = 104; CM_SHUTDOWN = 105;
  CM_HELP = 106; CM_PROPS = 107; CM_DELETE = 108; CM_CLOSE = 109; CM_PARENT = 110; CM_CMDHERE = 111;

Var
  Hab, Hmq, Desk, MenuH, Creating, ScrW, ScrH, Dummy, I : LongInt;
  { vues }
  VUse, VKind, VFrame, VClient, VSel, VTop, VMax, VList, VHidden, VStamp : Array[0..MaxView - 1] Of LongInt;
  Stamp : LongInt;
  VPath, VTitle : Array[0..MaxView - 1] Of String[127];
  { objets }
  IUse, IView, IIcon, IObj, IX, ITop, ISize : Array[0..MaxItem - 1] Of LongInt;
  IName : Array[0..MaxItem - 1] Of String[47];
  IPath : Array[0..MaxItem - 1] Of String[127];
  { glisser }
  DragItem, DragX0, DragY0, DragIX, DragITop, Dragging, MenuView, MenuItem : LongInt;
  { tampons }
  NameZ, NameZ2, ArgBuf, FailBuf : Array[0..511] Of Byte;
  MenuTpl : Array[0..2047] Of Byte;
  MenuLen, MenuCnt : LongInt;
  FindBuf : Array[0..4095] Of Byte;
  FileBuf : Array[0..4095] Of Byte;
  SortN : Array[0..299] Of String[47];
  SortA : Array[0..299] Of LongInt;
  Qmsg : Array[0..7] Of LongInt;
  I2 : LongInt;
  WlSess : Array[0..31] Of LongInt;   { liste des fenetres : sessions }
  WlViews, WlNS : LongInt;

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
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindow(H, Cmd : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowULong(H, Ix : LongInt) : LongInt; External 'PMWIN';
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

{ ==================================================================== }
{ Objets et vues                                                        }
{ ==================================================================== }

Function NewItem(V, Icon, Obj : LongInt; Name, Path : String) : LongInt;
Var K, F : LongInt;
Begin
  F := -1;
  For K := MaxItem - 1 DownTo 0 Do
    If IUse[K] = 0 Then F := K;
  If F >= 0 Then
  Begin
    IUse[F] := 1; IView[F] := V; IIcon[F] := Icon; IObj[F] := Obj; IName[F] := Name; IPath[F] := Path;
    IX[F] := 0; ITop[F] := 0; ISize[F] := 0;
  End;
  NewItem := F;
End;

Procedure ClearItems(V : LongInt);
Var K : LongInt;
Begin
  For K := 0 To MaxItem - 1 Do
    If (IUse[K] <> 0) And (IView[K] = V) Then IUse[K] := 0;
  VSel[V] := -1;
End;

Function ViewOf(Hwnd : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 0 To MaxView - 1 Do
    If (VUse[K] <> 0) And ((VClient[K] = Hwnd) Or (VFrame[K] = Hwnd)) Then R := K;
  ViewOf := R;
End;

Function ClientH(V : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[3] := 0;
  Dummy := WinQueryWindowRect(VClient[V], LongInt(@Rc));
  ClientH := Rc[3];
End;

Function ClientW(V : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[2] := 0;
  Dummy := WinQueryWindowRect(VClient[V], LongInt(@Rc));
  ClientW := Rc[2];
End;

{ rectangle (coordonnees du client) de la cellule de l'objet K }
Procedure CellRect(K : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Var V : LongInt;
Begin
  V := IView[K];
  X1 := IX[K]; X2 := IX[K] + CW;
  Y2 := ClientH(V) - (ITop[K] - VTop[V]);
  Y1 := Y2 - CH;
End;

Procedure InvalItem(K : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (K < 0) Or (IUse[K] = 0) Then Exit;
  CellRect(K, Rc[0], Rc[1], Rc[2], Rc[3]);
  Dummy := WinInvalidateRect(VClient[IView[K]], LongInt(@Rc), 1);
End;

Procedure SelectItem(V, K : LongInt);
Begin
  If VSel[V] = K Then Exit;
  InvalItem(VSel[V]);
  VSel[V] := K;
  InvalItem(K);
End;

Function HitItem(V, X, Y : LongInt) : LongInt;
Var K, R, X1, Y1, X2, Y2 : LongInt;
Begin
  R := -1;
  For K := 0 To MaxItem - 1 Do
    If (IUse[K] <> 0) And (IView[K] = V) Then
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
  Dummy := PrfQueryProfileString(-1, Z('PMSHELL'), Z2('POS ' + IName[K]), 0, LongInt(@B), 60);
  S := GetZ(LongInt(@B));
  P := Pos(',', S);
  If P > 1 Then
  Begin
    Val(Copy(S, 1, P - 1), X, C);
    If C = 0 Then Val(Copy(S, P + 1, 20), Y, C);
    If (C = 0) And (X >= 0) And (X < ScrW - 16) And (Y >= 0) And (Y < ScrH - 16) Then
    Begin
      IX[K] := X; ITop[K] := Y;
    End;
  End;
End;

Procedure SavePos(K : LongInt);
Var B : Array[0..63] Of Byte;
Begin
  PutZ(LongInt(@B), IStr(IX[K]) + ',' + IStr(ITop[K]));
  Dummy := PrfWriteProfileString(-1, Z('PMSHELL'), Z2('POS ' + IName[K]), LongInt(@B));
End;

{ disposition : colonnes (bureau) ou lignes (dossier) }
Procedure Layout(V : LongInt);
Var K, N, Cols, Rows, W, H : LongInt;
Begin
  W := ClientW(V); H := ClientH(V);
  N := 0; Rows := 0;
  If VKind[V] = VK_DESK Then
  Begin
    Rows := MaxI(1, (H - 8) Div CH);
    For K := 0 To MaxItem - 1 Do
      If (IUse[K] <> 0) And (IView[K] = V) Then
      Begin
        IX[K] := 8 + (N Div Rows) * CW;
        ITop[K] := 8 + (N Mod Rows) * CH;
        LoadPos(K);
        Inc(N);
      End;
  End
  Else
  Begin
    Cols := MaxI(1, (W - 8) Div CW);
    For K := 0 To MaxItem - 1 Do
      If (IUse[K] <> 0) And (IView[K] = V) Then
      Begin
        IX[K] := 8 + (N Mod Cols) * CW;
        ITop[K] := 8 + (N Div Cols) * CH;
        Inc(N);
      End;
    VMax[V] := 8 + ((N + Cols - 1) Div Cols) * CH;
  End;
End;

Procedure UpdScroll(V : LongInt);
Var Sb, H, M : LongInt;
Begin
  If VKind[V] = VK_DESK Then Exit;
  Sb := WinWindowFromID(VFrame[V], FID_VERTSCROLL);
  If Sb = 0 Then Exit;
  H := ClientH(V);
  M := MaxI(0, VMax[V] - H);
  If VTop[V] > M Then VTop[V] := M;
  If VTop[V] < 0 Then VTop[V] := 0;
  Dummy := WinSendMsg(Sb, SBM_SETSCROLLBAR, VTop[V], Mk2(0, M));
  Dummy := WinSendMsg(Sb, SBM_SETTHUMBSIZE, Mk2(H, MaxI(H, VMax[V])), 0);
End;

{ faire voir l'objet K (defilement) }
Procedure ShowItem(K : LongInt);
Var V, H : LongInt;
Begin
  V := IView[K];
  If VKind[V] = VK_DESK Then Exit;
  H := ClientH(V);
  If ITop[K] < VTop[V] Then VTop[V] := MaxI(0, ITop[K] - 8)
  Else If ITop[K] + CH > VTop[V] + H Then VTop[V] := ITop[K] + CH + 8 - H
  Else Exit;
  UpdScroll(V);
  Dummy := WinInvalidateRect(VClient[V], 0, 1);
End;

{ contenu d'un dossier }
Procedure AddSorted(V : LongInt; Dir : String);
Var H, N, A, Cnt, Rc, K, J, T, Icon, Obj, Off : LongInt; S, E, Ts : String;
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
      If (S <> '.') And (S <> '..') And (Cnt < 300) Then
      Begin
        { repertoires d'abord (cle "0nom"), puis fichiers ("1nom") }
        If (A And $10) <> 0 Then SortN[Cnt] := '0' + S Else SortN[Cnt] := '1' + S;
        SortA[Cnt] := RdL(LongInt(@FindBuf) + Off + 16);
        If (A And $10) <> 0 Then SortA[Cnt] := -1;
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
    Ts := SortN[K]; T := SortA[K]; J := K - 1;
    While (J >= 0) And (UpStr(SortN[J]) > UpStr(Ts)) Do
    Begin
      SortN[J + 1] := SortN[J]; SortA[J + 1] := SortA[J];
      Dec(J);
    End;
    SortN[J + 1] := Ts; SortA[J + 1] := T;
  End;
  For K := 0 To Cnt - 1 Do
  Begin
    S := Copy(SortN[K], 2, 255);
    E := ExtOf(S);
    If SortN[K][1] = '0' Then
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
    If Obj = OB_DIR Then J := NewItem(V, Icon, Obj, S, Dir + S + '\')
    Else J := NewItem(V, Icon, Obj, S, Dir + S);
    If J >= 0 Then ISize[J] := SortA[K];
  End;
End;

Procedure Populate(V : LongInt);
Var D, L, K : LongInt;
Begin
  ClearItems(V);
  Case VKind[V] Of
    VK_DESK :
      Begin
        Dummy := NewItem(V, IC_SYSTEM, OB_SYS, 'Systeme OS/2', '');
        Dummy := NewItem(V, IC_DRIVES, OB_DRIVES, 'Lecteurs', '');
        Dummy := NewItem(V, IC_CMD, OB_CMD, 'Invite de commandes OS/2', '');
        Dummy := NewItem(V, IC_WINLIST, OB_WINLIST, 'Liste des fenetres', '');
        Dummy := NewItem(V, IC_SHUTDOWN, OB_SHUTDOWN, 'Arret', '');
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
    VK_DIR : AddSorted(V, VPath[V]);
  End;
  Layout(V);
  If VKind[V] <> VK_DESK Then UpdScroll(V);
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
  V := IView[K];
  CellRect(K, X1, Y1, X2, Y2);
  Sel := VSel[V] = K;
  DrawIcon(Hps, IIcon[K], X1 + (CW - 32) Div 2, Y2 - 36);
  SplitLabel(IName[K], L1, L2);
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
  Hps := WinBeginPaint(VClient[V], 0, LongInt(@Rc));
  If Hps = 0 Then Exit;
  If VKind[V] = VK_DESK Then
  Begin
    Bg := DeskRgb; Fg := CLR_WHITE;
  End
  Else
  Begin
    Bg := CLR_WHITE; Fg := CLR_BLACK;
  End;
  Dummy := WinFillRect(Hps, LongInt(@Rc), Bg);
  If VKind[V] = VK_DESK Then
    GText(Hps, ScrW - 26 * 8, 4, 'OS/2-0  Workplace Shell', CLR_PALEGRAY, Bg);
  For K := 0 To MaxItem - 1 Do
    If (IUse[K] <> 0) And (IView[K] = V) Then
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
  If MenuH <> 0 Then Dummy := WinPopupMenu(VClient[V], VClient[V], MenuH, X, Y, First, 0);
End;

Procedure ContextMenu(V, K, X, Y : LongInt);
Begin
  MenuView := V; MenuItem := K;
  MenuStart;
  If K >= 0 Then
  Begin
    MenuAdd(CM_OPEN, '~Ouvrir');
    MenuAdd(CM_PROPS, '~Proprietes');
    If (IObj[K] = OB_EXE) Or (IObj[K] = OB_BATCH) Or (IObj[K] = OB_DATA) Then
    Begin
      MenuAdd(0, '');
      MenuAdd(CM_DELETE, '~Supprimer...');
    End;
  End
  Else If VKind[V] = VK_DESK Then
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
    If VKind[V] = VK_DIR Then
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
  For K := MaxView - 1 DownTo 0 Do
    If VUse[K] = 0 Then F := K;
  If F >= 0 Then
  Begin
    VUse[F] := 1; VKind[F] := Kind; VPath[F] := Path; VTitle[F] := Title; VSel[F] := -1; VTop[F] := 0;
    VMax[F] := 0; VFrame[F] := 0; VClient[F] := 0; VList[F] := 0; VHidden[F] := 0;
  End;
  NewView := F;
End;

{ la fenetre utilisee le plus recemment reprend la main }
Procedure ActivateLast;
Var K, B : LongInt;
Begin
  B := -1;
  For K := 0 To MaxView - 1 Do
    If (VUse[K] <> 0) And (VFrame[K] <> 0) Then
      If (WinQueryWindowULong(VFrame[K], QWL_STYLE) And WS_MINIMIZED) = 0 Then
        If (B < 0) Or (VStamp[K] > VStamp[B]) Then B := K;
  If B >= 0 Then Dummy := WinSetActiveWindow(HWND_DESKTOP, VFrame[B])
  Else If Desk <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Desk);
End;

Procedure CloseView(V : LongInt);
Begin
  If (V < 0) Or (VUse[V] = 0) Or (VKind[V] = VK_DESK) Then Exit;
  ClearItems(V);
  VUse[V] := 0;
  If VFrame[V] <> 0 Then Dummy := WinDestroyWindow(VFrame[V]);
  VFrame[V] := 0; VClient[V] := 0;
  ActivateLast;
End;

Function OpenFrame(V : LongInt; Cls : String; Fl, X, Y, W, H : LongInt) : Boolean;
Var Fr, Cl, Flags : LongInt;
Begin
  Flags := Fl;
  Creating := V;
  Cl := 0;
  Fr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flags), Z(Cls), Z2(VTitle[V]), 0, 0, 0, LongInt(@Cl));
  Creating := -1;
  If (Fr = 0) Or (Cl = 0) Then
  Begin
    VUse[V] := 0;
    OpenFrame := False;
    Exit;
  End;
  VFrame[V] := Fr; VClient[V] := Cl;
  Inc(Stamp);
  VStamp[V] := Stamp;
  Dummy := WinSetWindowPos(Fr, HWND_TOP, X, Y, W, H, SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Fr);
  OpenFrame := True;
End;

Function FindView(Kind : LongInt; Path : String) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 0 To MaxView - 1 Do
    If (VUse[K] <> 0) And (VKind[K] = Kind) And (UpStr(VPath[K]) = UpStr(Path)) Then R := K;
  FindView := R;
End;

Procedure ActivateView(V : LongInt);
Begin
  Inc(Stamp);
  VStamp[V] := Stamp;
  If VFrame[V] = 0 Then
  Begin
    Dummy := WinSetFocus(HWND_DESKTOP, VClient[V]);
    Exit;
  End;
  If (WinQueryWindowULong(VFrame[V], QWL_STYLE) And WS_MINIMIZED) <> 0 Then
    Dummy := WinSetWindowPos(VFrame[V], HWND_TOP, 0, 0, 0, 0, SWP_RESTORE Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, VFrame[V]);
End;

Function NViews : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To MaxView - 1 Do
    If (VUse[K] <> 0) And (VKind[K] <> VK_DESK) Then Inc(N);
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
    For N := MaxItem - 1 DownTo 0 Do
      If (IUse[N] <> 0) And (IView[N] = V) Then VSel[V] := N;
    Dummy := WinInvalidateRect(VClient[V], 0, 1);
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
    Dummy := WinSendMsg(VList[V], LM_INSERTITEM, -1, LongInt(@B));
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
          Dummy := WinSendMsg(VList[V], LM_INSERTITEM, -1, LongInt(@B));
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
    Dummy := WinSendMsg(VList[V], LM_INSERTITEM, -1, LongInt(@B));
  End;
  Dummy := DosClose(H);
  Dummy := WinSendMsg(VList[V], LM_SELECTITEM, 0, 1);
  Dummy := WinSetFocus(HWND_DESKTOP, VList[V]);
End;

{ liste des fenetres (Ctrl+Echap) }
Procedure FillWinList(V : LongInt);
Var K : LongInt; B : Array[0..259] Of Byte; Info : Array[0..15] Of LongInt;
Begin
  Dummy := WinSendMsg(VList[V], LM_DELETEALL, 0, 0);
  PutZ(LongInt(@B), 'Bureau');
  Dummy := WinSendMsg(VList[V], LM_INSERTITEM, -1, LongInt(@B));
  For K := 0 To MaxView - 1 Do
    If (VUse[K] <> 0) And (VKind[K] <> VK_DESK) And (VKind[K] <> VK_LIST) Then
    Begin
      PutZ(LongInt(@B), VTitle[K]);
      Dummy := WinSendMsg(VList[V], LM_INSERTITEM, -1, LongInt(@B));
    End;
  { sessions en mode texte (programmes lances, plein ecran) }
  WlViews := WinSendMsg(VList[V], LM_QUERYITEMCOUNT, 0, 0);
  WlNS := 0;
  For K := 0 To 15 Do
    If (WlNS < 32) And (KSes(7, K, LongInt(@Info)) = 1) Then
      If (Info[3] > 0) And (Info[2] = 0) And (K <> KSes(10, 0, 0)) Then
      Begin
        PutZ(LongInt(@B), GetZ(LongInt(@Info) + 16) + ' (plein ecran)');
        Dummy := WinSendMsg(VList[V], LM_INSERTITEM, -1, LongInt(@B));
        WlSess[WlNS] := K;
        Inc(WlNS);
      End;
  Dummy := WinSendMsg(VList[V], LM_SELECTITEM, 0, 1);
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
  Dummy := WinSetFocus(HWND_DESKTOP, VList[V]);
End;

Procedure WinListChoose(V : LongInt);
Var Sel, K, N, T : LongInt;
Begin
  Sel := WinSendMsg(VList[V], LM_QUERYSELECTION, -1, 0);
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
    For K := 0 To MaxView - 1 Do
      If (VUse[K] <> 0) And (VKind[K] <> VK_DESK) And (VKind[K] <> VK_LIST) Then
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
  For K := 0 To MaxView - 1 Do
    If VUse[K] <> 0 Then
    Begin
      If VFrame[K] <> 0 Then
      Begin
        VHidden[K] := WinIsWindowVisible(VFrame[K]);
        If VHidden[K] <> 0 Then Dummy := WinShowWindow(VFrame[K], 0);
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
  For K := 0 To MaxView - 1 Do
    If (VUse[K] <> 0) And (VFrame[K] <> 0) And (VHidden[K] <> 0) Then Dummy := WinShowWindow(VFrame[K], 1);
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
  For K := 0 To MaxView - 1 Do
    If (VUse[K] <> 0) And (VKind[K] <> VK_DESK) Then CloseView(K);
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
  T := IName[K];
  Case IObj[K] Of
    OB_DIR : T := T + ' : dossier ' + IPath[K] + '.';
    OB_EXE : T := T + ' : programme ' + IPath[K] + ' (' + IStr(ISize[K]) + ' octets).';
    OB_BATCH : T := T + ' : fichier de commandes ' + IPath[K] + ' (' + IStr(ISize[K]) + ' octets).';
    OB_DATA : T := T + ' : fichier de donnees ' + IPath[K] + ' (' + IStr(ISize[K]) + ' octets).';
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

Procedure OpenItem(K : LongInt);
Var V : LongInt; P : String;
Begin
  If (K < 0) Or (IUse[K] = 0) Then Exit;
  V := IView[K];
  Case IObj[K] Of
    OB_SYS : OpenFolder(VK_SYS, '', 'Systeme OS/2');
    OB_DRIVES : OpenFolder(VK_DRIVES, '', 'Lecteurs');
    OB_CMD :
      Begin
        If VKind[V] = VK_DIR Then P := VPath[V] Else P := '';
        RunProgram(Comspec, '', P, False);
      End;
    OB_SHUTDOWN : Shutdown;
    OB_WINLIST : OpenWinList;
    OB_INFO : SysInfo;
    OB_HELP : Help;
    OB_DIR : OpenFolder(VK_DIR, IPath[K], IPath[K]);
    OB_EXE : RunProgram(IPath[K], '', DirOf(IPath[K]), True);
    OB_BATCH : RunProgram(Comspec, '/C ' + IPath[K], DirOf(IPath[K]), True);
    OB_DATA : OpenViewer(IPath[K]);
  End;
End;

Procedure DeleteItem(K : LongInt);
Var V : LongInt;
Begin
  If (K < 0) Or ((IObj[K] <> OB_EXE) And (IObj[K] <> OB_BATCH) And (IObj[K] <> OB_DATA)) Then Exit;
  If WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, Z('Supprimer le fichier ' + IPath[K] + ' ?'), Z2('Supprimer'), 0,
                   MB_YESNO Or MB_WARNING Or MB_MOVEABLE) <> MBID_YES Then Exit;
  V := IView[K];
  If DosDelete(Z(IPath[K])) <> 0 Then
    ShowMsg('Le fichier ' + IPath[K] + ' ne peut pas etre supprime (unite en lecture seule ?).', 'Supprimer',
        MB_OK Or MB_ERROR)
  Else
  Begin
    Populate(V);
    Dummy := WinInvalidateRect(VClient[V], 0, 1);
  End;
End;

Procedure ParentFolder(V : LongInt);
Var P : String; K : LongInt;
Begin
  If VKind[V] <> VK_DIR Then Exit;
  P := VPath[V];
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
  If VKind[V] = VK_DESK Then Layout(V) Else Populate(V);
  Dummy := WinInvalidateRect(VClient[V], 0, 1);
End;

Procedure Arrange(V : LongInt);
Var K : LongInt; B : Array[0..3] Of Byte;
Begin
  B[0] := 0;
  For K := 0 To MaxItem - 1 Do
    If (IUse[K] <> 0) And (IView[K] = V) Then
      Dummy := PrfWriteProfileString(-1, Z('PMSHELL'), Z2('POS ' + IName[K]), 0);
  Refresh(V);
End;

Procedure Command(V, Cmd : LongInt);
Var K : LongInt;
Begin
  K := MenuItem;
  If (K >= 0) And ((IUse[K] = 0) Or (IView[K] <> V)) Then K := -1;
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
    CM_CMDHERE : RunProgram(Comspec, '', VPath[V], False);
  End;
End;

{ objet suivant dans une direction (dx, dy : -1, 0, 1) }
Procedure MoveSel(V, Dx, Dy : LongInt);
Var K, B, Best, Cx, Cy, X, Y, D : LongInt;
Begin
  If (VSel[V] < 0) Or (IUse[VSel[V]] = 0) Then
  Begin
    B := -1;
    For K := MaxItem - 1 DownTo 0 Do
      If (IUse[K] <> 0) And (IView[K] = V) Then B := K;
    If B >= 0 Then SelectItem(V, B);
    Exit;
  End;
  Cx := IX[VSel[V]]; Cy := ITop[VSel[V]];
  B := -1; Best := $7FFFFFFF;
  For K := 0 To MaxItem - 1 Do
    If (IUse[K] <> 0) And (IView[K] = V) And (K <> VSel[V]) Then
    Begin
      X := IX[K] - Cx; Y := ITop[K] - Cy;
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
  For K := 0 To MaxItem - 1 Do
    If (IUse[K] <> 0) And (IView[K] = V) Then
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
  Start := VSel[V];
  B := -1;
  For J := 1 To MaxItem Do
  Begin
    K := (Start + J + MaxItem) Mod MaxItem;
    If (B < 0) And (IUse[K] <> 0) And (IView[K] = V) And (Length(IName[K]) > 0) Then
      If UpCase(IName[K][1]) = UpCase(Chr(Ch)) Then B := K;
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
      If (VSel[V] >= 0) And (IUse[VSel[V]] <> 0) Then
      Begin
        CellRect(VSel[V], X1, Y1, X2, Y2);
        ContextMenu(V, VSel[V], X1 + 40, Y1 + 20);
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
      VK_ENTER, VK_NEWLINE : OpenItem(VSel[V]);
      VK_F1 : Help;
      VK_F5 : Refresh(V);
      VK_DELETE : DeleteItem(VSel[V]);
      VK_BACKSPACE : ParentFolder(V);
      VK_PAGEUP :
        If VKind[V] <> VK_DESK Then
        Begin
          VTop[V] := VTop[V] - ClientH(V);
          UpdScroll(V);
          Dummy := WinInvalidateRect(VClient[V], 0, 1);
        End;
      VK_PAGEDOWN :
        If VKind[V] <> VK_DESK Then
        Begin
          VTop[V] := VTop[V] + ClientH(V);
          UpdScroll(V);
          Dummy := WinInvalidateRect(VClient[V], 0, 1);
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

Function ViewProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var V, K, X, Y, Dx, Dy, Sc : LongInt;
Begin
  ViewProc := 0;
  V := ViewOf(H);
  If (V < 0) And (Msg = WM_CREATE) And (Creating >= 0) Then
  Begin
    VClient[Creating] := H;
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
        VStamp[V] := Stamp;
      End;
    WM_PAINT : PaintView(V);
    WM_SIZE :
      If VKind[V] <> VK_DESK Then
      Begin
        Layout(V);
        UpdScroll(V);
        Dummy := WinInvalidateRect(H, 0, 1);
      End;
    WM_ACTIVATE :
      { le bureau reste sous les autres fenetres }
      If (VKind[V] = VK_DESK) And (Lo16(Mp1) <> 0) Then
        Dummy := WinSetWindowPos(H, HWND_BOTTOM, 0, 0, 0, 0, SWP_ZORDER);
    WM_BUTTON1DOWN :
      Begin
        If VKind[V] = VK_DESK Then Dummy := WinSetFocus(HWND_DESKTOP, H)
        Else ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        K := HitItem(V, X, Y);
        SelectItem(V, K);
        If (K >= 0) And (VKind[V] = VK_DESK) Then
        Begin
          DragItem := K; DragX0 := X; DragY0 := Y; DragIX := IX[K]; DragITop := ITop[K]; Dragging := 0;
          Dummy := WinSetCapture(HWND_DESKTOP, H);
        End;
        ViewProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        If (DragItem >= 0) And (IView[DragItem] = V) Then
        Begin
          X := S16(Mp1); Y := S16(Mp1 Shr 16);
          Dx := X - DragX0; Dy := Y - DragY0;
          If (Dragging = 0) And (AbsI(Dx) + AbsI(Dy) > 4) Then Dragging := 1;
          If Dragging <> 0 Then
          Begin
            InvalItem(DragItem);
            IX[DragItem] := MaxI(0, MinI(ScrW - CW, DragIX + Dx));
            ITop[DragItem] := MaxI(0, MinI(ScrH - CH, DragITop - Dy));
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
          If Dragging <> 0 Then SavePos(DragItem);
          DragItem := -1; Dragging := 0;
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
        If VKind[V] = VK_DESK Then Dummy := WinSetFocus(HWND_DESKTOP, H)
        Else Dummy := WinDefWindowProc(H, Msg, Mp1, Mp2);
        ViewProc := 1;
      End;
    WM_BUTTON2CLICK :
      Begin
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        K := HitItem(V, X, Y);
        If K >= 0 Then SelectItem(V, K);
        ContextMenu(V, K, X, Y);
        ViewProc := 1;
      End;
    WM_COMMAND : Command(V, Lo16(Mp1));
    WM_CHAR :
      If ViewKey(V, Mp1, Mp2) Then ViewProc := 1
      Else ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_VSCROLL :
      Begin
        Sc := Hi16(Mp2);
        Case Sc Of
          SB_LINEUP : VTop[V] := VTop[V] - 16;
          SB_LINEDOWN : VTop[V] := VTop[V] + 16;
          SB_PAGEUP : VTop[V] := VTop[V] - ClientH(V);
          SB_PAGEDOWN : VTop[V] := VTop[V] + ClientH(V);
          SB_SLIDERTRACK, SB_SLIDERPOSITION : VTop[V] := S16(Mp2);
        End;
        UpdScroll(V);
        Dummy := WinInvalidateRect(H, 0, 1);
      End;
    WM_SYSCOMMAND :
      If (VKind[V] = VK_DESK) And (Lo16(Mp1) = SC_CLOSE) Then Shutdown
      Else ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_CLOSE :
      If VKind[V] = VK_DESK Then Shutdown Else CloseView(V);
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
    VClient[V] := H;
    VList[V] := WinCreateWindow(H, WC_LISTBOX, 0, WS_VISIBLE, 0, 0, 100, 100, H, HWND_TOP, 1, 0, 0);
    Exit;
  End;
  If V < 0 Then
  Begin
    ListProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    Exit;
  End;
  Case Msg Of
    WM_SIZE :
      If VList[V] <> 0 Then
        Dummy := WinSetWindowPos(VList[V], 0, 0, 0, Lo16(Mp2), Hi16(Mp2), SWP_SIZE Or SWP_MOVE);
    WM_CONTROL :
      If (Hi16(Mp1) = LN_ENTER) And (VKind[V] = VK_LIST) Then WinListChoose(V);
    WM_CHAR :
      Begin
        Fs := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fs And KC_KEYUP) = 0) And ((Fs And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then CloseView(V)
        Else If ((Fs And KC_KEYUP) = 0) And ((Fs And KC_VIRTUALKEY) <> 0) And
                ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) And (VKind[V] = VK_LIST) Then WinListChoose(V)
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
  For I := 0 To MaxView - 1 Do VUse[I] := 0;
  For I := 0 To MaxItem - 1 Do IUse[I] := 0;
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
  VClient[I] := Desk; VFrame[I] := 0;
  Populate(I);
  VSel[I] := -1;
  For I2 := 0 To MaxItem - 1 Do
    If (IUse[I2] <> 0) And (IView[I2] = I) And (VSel[I] < 0) Then VSel[I] := I2;
  Dummy := WinSetFocus(HWND_DESKTOP, Desk);
  Dummy := WinInvalidateRect(HWND_DESKTOP, 0, 1);
  { boucle des messages (WM_QUIT est ignore : le bureau ne se termine pas) }
  Repeat
    If WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Then Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Until False;
END.
