{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: FTPCLI - Client FTP et SFTP d'OS/2-0 (Presentation
  Manager), dans le genre de FileZilla, porte du Client FTP de Pasdows 95.
}

Program FTPCLI;

{$R-,S-,I-}

{ Compilation : OS2PC APPS\FTPCLI.PAS FTPCLI.EXE

  Bureau - Outils reseau - Client FTP (FTPCLI.EXE).
  Porte de APPS/FTPCLI.PAS de Pasdows 95 (Win32, WPC -CW32) : les API de
  Windows sont remplacees par celles d'OS/2 (PMWIN, PMGPI, DOSCALLS,
  TCPIP32) ; fichier unique, sans unite.
  - Protocoles : FTP (mode passif EPSV/PASV, MLSD ou LIST Unix et
    MS-DOS, UTF-8) et SFTP version 3 sur SSH-2 (echange de cles
    curve25519-sha256, cles d'hote ssh-ed25519, rsa-sha2-512 et
    rsa-sha2-256 verifiees, chiffrement aes128-ctr, hmac-sha2-256, "kex
    strict" contre l'attaque Terrapin, mot de passe ou clavier
    interactif). Les cles d'hote acceptees sont gardees (empreinte
    SHA-256) comme les "known_hosts" (knownhosts.txt, commun avec le
    Client SSH).
  - Fenetre de FileZilla : barre d'outils, barre de connexion rapide
    (historique), journal des messages en couleurs, deux panneaux (site
    local, site distant) avec colonnes triables, selection multiple,
    glisser-deposer d'un panneau a l'autre, menus contextuels ; file
    d'attente des transferts (progression, transferts echoues et
    reussis), dossiers transferes avec leur contenu.
  - Gestionnaire de sites : fichier sitemanager.xml au format de
    FileZilla 3 (dossiers, mot de passe en base64, dossiers par defaut),
    importation et exportation ; historique de connexion rapide
    (recentservers.xml).
  - Fichiers de configuration dans C:\RESEAU\ (D:\RESEAU\ quand C: est
    en lecture seule : demarrage du CD-ROM).
  API d'OS/2 : fenetres et controles de Presentation Manager
  (WinCreateStdWindow, WinCreateWindow : WC_ENTRYFIELD, WC_BUTTON,
  WC_LISTBOX, WC_STATIC, WC_SCROLLBAR ; gabarits de menus, WinPopupMenu,
  WinMessageBox, WinStartTimer, presse-papiers), dessin par WinFillRect
  et GpiCharStringAt, fichiers DosOpen/DosRead/DosWrite/DosFindFirst/
  DosQueryPathInfo/DosCreateDir/DosDeleteDir/DosDelete/DosMove/
  DosQueryFSInfo/DosQueryFSAttach/DosQueryCurrentDisk, fil de travail
  DosCreateThread, semaphores DosCreateMutexSem et DosCreateEventSem,
  sockets de TCPIP32.DLL, DosExecPgm (ouvrir un fichier local).
  Le reseau tourne dans un fil de travail ; un verrou (semaphore
  d'exclusion) protege les chaines temporaires du runtime d'OS2PC,
  partagees par les deux fils : le fil reseau le libere pendant les
  appels bloquants (recv, send, connect). Les boites de message du fil
  reseau (cle d'hote, fichier existant) sont affichees par le fil de
  l'interface (message WM_NETASK). }

Const
  { evenements internes des fenetres (valeurs de Pasdows 95 : les
    procedures de fenetre de PM les produisent a partir des messages de
    PM, voir LogProc, LvProc, DlgProc et MainProc) }
  WM_CREATE = $0001; WM_DESTROY = $0002; WM_SIZE = $0005;
  WM_SETFOCUS = $0007; WM_KILLFOCUS = $0008; WM_PAINT = $000F;
  WM_CLOSE = $0010; WM_ERASEBKGND = $0014;
  WM_KEYDOWN = $0100; WM_CHAR = $0102;
  WM_COMMAND = $0111; WM_TIMER = $0113; WM_VSCROLL = $0115;
  WM_MOUSEMOVE = $0200; WM_LBUTTONDOWN = $0201; WM_LBUTTONUP = $0202;
  WM_LBUTTONDBLCLK = $0203; WM_RBUTTONDOWN = $0204; WM_RBUTTONUP = $0205;
  WM_MOUSEWHEEL = $020A;
  { messages du fil reseau a la fenetre principale (WM_USER de PM) }
  WM_USER = $1000;
  WM_NETLOG = WM_USER + 1;            { nouvelles lignes du journal }
  WM_NETSTATE = WM_USER + 2;          { etat de la connexion }
  WM_NETLIST = WM_USER + 3;           { liste distante arrivee }
  WM_NETQUEUE = WM_USER + 4;          { file d'attente modifiee }
  WM_NETLOCAL = WM_USER + 5;          { dossier local a relire }
  WM_NETASK = WM_USER + 6;            { boite de message du fil reseau }
  { notifications internes (WM_COMMAND : Id + Code Shl 16) }
  BN_CLICKED = 0; LBN_SELCHANGE = 1; LBN_DBLCLK = 2; EN_CHANGE = $0300;
  { styles internes des controles (Ctl les traduit pour PM) }
  WS_BORDER = $00800000; WS_VSCROLL = $00200000;
  WS_TABSTOP = $00010000; WS_GROUP = $00020000;
  ES_AUTOHSCROLL = $0080; ES_PASSWORD = $0020;
  BS_PUSHBUTTON = 0; BS_DEFPUSHBUTTON = 1; BS_AUTOCHECKBOX = 3;
  BS_AUTORADIOBUTTON = 9; BS_GROUPBOX = 7; LBS_NOTIFY = 1;
  { boites de message (valeurs internes ; Ask les traduit pour PM) }
  MB_OK = 0; MB_OKCANCEL = 1; MB_YESNOCANCEL = 3; MB_YESNO = 4;
  MB_ICONERROR = $10; MB_ICONQUESTION = $20; MB_ICONWARNING = $30;
  MB_ICONINFO = $40; IDOK = 1; IDCANCEL = 2; IDYES = 6; IDNO = 7;
  { touches internes (LvKey) }
  VK_BACK = $08; VK_TAB = $09; VK_RETURN = $0D; VK_SHIFT = $10;
  VK_CONTROL = $11; VK_ESCAPE = $1B; VK_SPACE = $20; VK_PRIOR = $21;
  VK_NEXT = $22; VK_END = $23; VK_HOME = $24; VK_LEFT = $25; VK_UP = $26;
  VK_RIGHT = $27; VK_DOWN = $28; VK_DELETE = $2E; VK_F2 = $71;
  VK_F5 = $74;
  { couleurs de Windows 95 ($00BBGGRR), traduites en index de PM }
  ClrFace = $C0C0C0; ClrShadow = $808080; ClrHi = $FFFFFF; ClrDark = 0;
  ClrSel = $800000; ClrWin = $FFFFFF; ClrBlack = 0;
  ClrNavy = $800000; ClrGreen = $008000; ClrRed = $0000C0;
  ClrGray = $808080; ClrYellow = $00FFFF; ClrOlive = $008080;
  ClrMaroon = $000080; ClrBlue = $FF0000; ClrTeal = $808000;

  { ---- Presentation Manager ---- }
  PM_WM_SETFOCUS = $000F; PM_WM_SIZE = $0007; PM_WM_COMMAND = $0020;
  PM_WM_PAINT = $0023; PM_WM_TIMER = $0024; PM_WM_CLOSE = $0029;
  PM_WM_QUIT = $002A; PM_WM_CONTROL = $0030; PM_WM_VSCROLL = $0031;
  PM_WM_ERASEBACKGROUND = $004F; PM_WM_MOUSEMOVE = $0070;
  PM_WM_BUTTON1DOWN = $0071; PM_WM_BUTTON1UP = $0072;
  PM_WM_BUTTON1DBLCLK = $0073; PM_WM_BUTTON2DOWN = $0074;
  PM_WM_CHAR = $007A; PM_WM_DESTROY = $0002;
  PM_KC_CHAR = 1; PM_KC_VIRTUALKEY = 2; PM_KC_SHIFT = 8; PM_KC_CTRL = $10;
  PM_KC_ALT = $20; PM_KC_KEYUP = $40;
  PM_VK_BACKSPACE = $05; PM_VK_TAB = $06; PM_VK_BACKTAB = $07;
  PM_VK_NEWLINE = $08; PM_VK_SHIFT = $09; PM_VK_CTRL = $0A; PM_VK_ESC = $0F;
  PM_VK_SPACE = $10; PM_VK_PAGEUP = $11; PM_VK_PAGEDOWN = $12;
  PM_VK_END = $13; PM_VK_HOME = $14; PM_VK_LEFT = $15; PM_VK_UP = $16;
  PM_VK_RIGHT = $17; PM_VK_DOWN = $18; PM_VK_DELETE = $1B;
  PM_VK_ENTER = $1E; PM_VK_F1 = $20;
  WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006;
  WC_LISTBOX = $FFFF0007; WC_SCROLLBAR = $FFFF0008;
  PM_WS_VISIBLE = $80000000; PM_WS_DISABLED = $40000000;
  PM_WS_GROUP = $00010000; PM_WS_TABSTOP = $00020000;
  PM_BS_PUSHBUTTON = 0; PM_BS_AUTOCHECKBOX = 2; PM_BS_AUTORADIOBUTTON = 4;
  PM_BS_DEFAULT = $0400; PM_SS_TEXT = 1; PM_SS_GROUPBOX = 2;
  PM_DT_VCENTER = $0400; PM_ES_AUTOSCROLL = 4; PM_ES_MARGIN = 8;
  PM_ES_UNREADABLE = $80; PM_SBS_VERT = 1;
  PM_BM_QUERYCHECK = $0124; PM_BM_SETCHECK = $0125;
  PM_EM_SETSEL = $0142; PM_EM_SETTEXTLIMIT = $0143;
  PM_LM_INSERTITEM = $0161; PM_LM_SELECTITEM = $0164;
  PM_LM_QUERYSELECTION = $0165; PM_LM_DELETEALL = $016E;
  PM_MM_SETITEMATTR = $0192;
  PM_SBM_SETSCROLLBAR = $01A0; PM_SBM_SETPOS = $01A1; PM_SBM_QUERYPOS = $01A2;
  PM_SBM_SETTHUMBSIZE = $01A6;
  PM_BN_CLICKED = 1; PM_EN_CHANGE = 4; PM_LN_SELECT = 1; PM_LN_ENTER = 5;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10;
  FCF_MAXBUTTON = $20; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  FID_MENU = $8005;
  HWND_DESKTOP = 1; HWND_TOP = 3; HWND_BOTTOM = 4; QW_PARENT = 5;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_HIDE = $10;
  SWP_ACTIVATE = $80; SWP_MAXIMIZE = $800;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  PM_MB_OK = 0; PM_MB_OKCANCEL = 1; PM_MB_YESNO = 4; PM_MB_YESNOCANCEL = 5;
  PM_MB_QUERY = $10; PM_MB_WARNING = $20; PM_MB_INFORMATION = $30;
  PM_MB_ERROR = $40; PM_MB_MOVEABLE = $4000;
  SPTR_ARROW = 1; SPTR_WAIT = 3; SPTR_MOVE = 5;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_GREEN = 4;
  CLR_CYAN = 5; CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9;
  CLR_DARKRED = 10; CLR_DARKGREEN = 12; CLR_DARKCYAN = 13; CLR_BROWN = 14;
  CLR_PALEGRAY = 15;
  PP_BACKGROUNDCOLORINDEX = 4;

Type
  PByt = ^Byte;
  PLng = ^LongInt;
  TlPtr = LongInt;
  TBytes = Array[0..$7FFFFFF] Of Byte;
  PBytes = ^TBytes;

{ ---- PMWIN ---- }
Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinDefDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinShowWindow(H, Show : LongInt) : LongInt; External 'PMWIN';
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
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysPointer(HD, Id, Load : LongInt) : LongInt; External 'PMWIN';
Function WinSetPointer(HD, Hptr : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Ms : LongInt) : LongInt; External 'PMWIN';
Function WinMapWindowPoints(HFrom, HTo, P, N : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindow(H, Cmd : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindow(Hab, H : LongInt) : LongInt; External 'PMWIN';
Function WinGetKeyState(HD, Vk : LongInt) : LongInt; External 'PMWIN';
Function WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetClipbrdData(Hab, D, Fmt, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
{ ---- PMGPI ---- }
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiCharStringAt(Hps, PPt, N, P : LongInt) : LongInt; External 'PMGPI';
{ ---- DOSCALLS ---- }
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosDeleteDir(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosMove(POld, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFSAttach(PDev, Ordinal, Level, PBuf, PCb : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosQuerySysInfo(IStart, ILast, PBuf, CbBuf : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateMutexSem(PName, PH, Attr, State : LongInt) : LongInt; External 'DOSCALLS';
Function DosRequestMutexSem(H, Timeout : LongInt) : LongInt; External 'DOSCALLS';
Function DosReleaseMutexSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateEventSem(PName, PH, Attr, State : LongInt) : LongInt; External 'DOSCALLS';
Function DosPostEventSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosWaitEventSem(H, Timeout : LongInt) : LongInt; External 'DOSCALLS';
Function DosResetEventSem(H, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosExit(Action, Code : LongInt) : LongInt; External 'DOSCALLS';

Function TlGet(A : TlPtr) : LongInt;
Begin
  TlGet := PByt(A)^;
End;

Procedure TlPut(A : TlPtr; V : LongInt);
Begin
  PByt(A)^ := V And 255;
End;

{ bloc de N octets, mis a zero (DosAllocMem, PAG_COMMIT, lecture et
  ecriture) }
Function TlNew(N : LongInt) : TlPtr;
Var P : LongInt;
Begin
  P := 0;
  If DosAllocMem(LongInt(@P), N, $13) <> 0 Then P := 0;
  If P <> 0 Then FillChar(PBytes(P)^[0], N, 0);
  TlNew := P;
End;

Var
  Dummy0 : LongInt;

{ ==================================================================== }
{ Cryptographie (reprise de MSTSC) : SHA-256, AES-128, X25519         }
{ (mots de 32 bits en LongInt ; Shr est un decalage logique)          }
{ ==================================================================== }

Type
  TlSha = Record
    H : Array[0..7] Of LongInt;
    B : Array[0..63] Of Byte;
    N : LongInt;                     { octets en attente dans B }
    Len : LongInt;                   { longueur totale (octets) }
  End;
  TlFe = Array[0..31] Of LongInt;    { element de GF(2^255-19), 8 bits }
  TlAes = Record
    RK : Array[0..43] Of LongInt;    { cles de tour (AES-128) }
  End;

Const
  TlShaKC : Array[0..63] Of LongWord = (
    $428A2F98, $71374491, $B5C0FBCF, $E9B5DBA5, $3956C25B, $59F111F1,
    $923F82A4, $AB1C5ED5, $D807AA98, $12835B01, $243185BE, $550C7DC3,
    $72BE5D74, $80DEB1FE, $9BDC06A7, $C19BF174, $E49B69C1, $EFBE4786,
    $0FC19DC6, $240CA1CC, $2DE92C6F, $4A7484AA, $5CB0A9DC, $76F988DA,
    $983E5152, $A831C66D, $B00327C8, $BF597FC7, $C6E00BF3, $D5A79147,
    $06CA6351, $14292967, $27B70A85, $2E1B2138, $4D2C6DFC, $53380D13,
    $650A7354, $766A0ABB, $81C2C92E, $92722C85, $A2BFE8A1, $A81A664B,
    $C24B8B70, $C76C51A3, $D192E819, $D6990624, $F40E3585, $106AA070,
    $19A4C116, $1E376C08, $2748774C, $34B0BCB5, $391C0CB3, $4ED8AA4A,
    $5B9CCA4F, $682E6FF3, $748F82EE, $78A5636F, $84C87814, $8CC70208,
    $90BEFFFA, $A4506CEB, $BEF9A3F7, $C67178F2);
  TlSBox : Array[0..255] Of Byte = (
    $63, $7C, $77, $7B, $F2, $6B, $6F, $C5, $30, $01, $67, $2B,
    $FE, $D7, $AB, $76, $CA, $82, $C9, $7D, $FA, $59, $47, $F0,
    $AD, $D4, $A2, $AF, $9C, $A4, $72, $C0, $B7, $FD, $93, $26,
    $36, $3F, $F7, $CC, $34, $A5, $E5, $F1, $71, $D8, $31, $15,
    $04, $C7, $23, $C3, $18, $96, $05, $9A, $07, $12, $80, $E2,
    $EB, $27, $B2, $75, $09, $83, $2C, $1A, $1B, $6E, $5A, $A0,
    $52, $3B, $D6, $B3, $29, $E3, $2F, $84, $53, $D1, $00, $ED,
    $20, $FC, $B1, $5B, $6A, $CB, $BE, $39, $4A, $4C, $58, $CF,
    $D0, $EF, $AA, $FB, $43, $4D, $33, $85, $45, $F9, $02, $7F,
    $50, $3C, $9F, $A8, $51, $A3, $40, $8F, $92, $9D, $38, $F5,
    $BC, $B6, $DA, $21, $10, $FF, $F3, $D2, $CD, $0C, $13, $EC,
    $5F, $97, $44, $17, $C4, $A7, $7E, $3D, $64, $5D, $19, $73,
    $60, $81, $4F, $DC, $22, $2A, $90, $88, $46, $EE, $B8, $14,
    $DE, $5E, $0B, $DB, $E0, $32, $3A, $0A, $49, $06, $24, $5C,
    $C2, $D3, $AC, $62, $91, $95, $E4, $79, $E7, $C8, $37, $6D,
    $8D, $D5, $4E, $A9, $6C, $56, $F4, $EA, $65, $7A, $AE, $08,
    $BA, $78, $25, $2E, $1C, $A6, $B4, $C6, $E8, $DD, $74, $1F,
    $4B, $BD, $8B, $8A, $70, $3E, $B5, $66, $48, $03, $F6, $0E,
    $61, $35, $57, $B9, $86, $C1, $1D, $9E, $E1, $F8, $98, $11,
    $69, $D9, $8E, $94, $9B, $1E, $87, $E9, $CE, $55, $28, $DF,
    $8C, $A1, $89, $0D, $BF, $E6, $42, $68, $41, $99, $2D, $0F,
    $B0, $54, $BB, $16);

Var
  TlK : Array[0..63] Of LongInt;
  TlTe : Array[0..255] Of LongInt;   { table T0 de l'AES }
  TlReady : Boolean;

Function TlRor(X, N : LongInt) : LongInt;
Begin
  TlRor := (X Shr N) Or (X Shl (32 - N));
End;

Function TlXt(B : LongInt) : LongInt;
Begin
  B := B Shl 1;
  If (B And $100) <> 0 Then B := B Xor $11B;
  TlXt := B And 255;
End;

Procedure TlInit;
Var I, S, S2, S3 : LongInt; W : LongInt;
Begin
  If TlReady Then Exit;
  For I := 0 To 63 Do Begin W := TlShaKC[I]; TlK[I] := W; End;
  For I := 0 To 255 Do
  Begin
    S := TlSBox[I]; S2 := TlXt(S); S3 := S2 Xor S;
    TlTe[I] := (S2 Shl 24) Or (S Shl 16) Or (S Shl 8) Or S3;
  End;
  TlReady := True;
End;

{ ---- SHA-256 ---- }

Procedure TlShaBlock(Var C : TlSha);
Var W : Array[0..63] Of LongInt; I, A, B, D, E, F, G, H, T1, T2,
    Cc, S0, S1 : LongInt;
Begin
  For I := 0 To 15 Do
    W[I] := (C.B[I * 4] Shl 24) Or (C.B[I * 4 + 1] Shl 16) Or
            (C.B[I * 4 + 2] Shl 8) Or C.B[I * 4 + 3];
  For I := 16 To 63 Do
  Begin
    S0 := TlRor(W[I - 15], 7) Xor TlRor(W[I - 15], 18) Xor
          (W[I - 15] Shr 3);
    S1 := TlRor(W[I - 2], 17) Xor TlRor(W[I - 2], 19) Xor
          (W[I - 2] Shr 10);
    W[I] := W[I - 16] + S0 + W[I - 7] + S1;
  End;
  A := C.H[0]; B := C.H[1]; Cc := C.H[2]; D := C.H[3];
  E := C.H[4]; F := C.H[5]; G := C.H[6]; H := C.H[7];
  For I := 0 To 63 Do
  Begin
    S1 := TlRor(E, 6) Xor TlRor(E, 11) Xor TlRor(E, 25);
    T1 := H + S1 + ((E And F) Xor ((Not E) And G)) + TlK[I] + W[I];
    S0 := TlRor(A, 2) Xor TlRor(A, 13) Xor TlRor(A, 22);
    T2 := S0 + ((A And B) Xor (A And Cc) Xor (B And Cc));
    H := G; G := F; F := E; E := D + T1;
    D := Cc; Cc := B; B := A; A := T1 + T2;
  End;
  C.H[0] := C.H[0] + A; C.H[1] := C.H[1] + B; C.H[2] := C.H[2] + Cc;
  C.H[3] := C.H[3] + D; C.H[4] := C.H[4] + E; C.H[5] := C.H[5] + F;
  C.H[6] := C.H[6] + G; C.H[7] := C.H[7] + H;
End;

Procedure TlShaInit(Var C : TlSha);
Begin
  TlInit;
  C.H[0] := $6A09E667; C.H[1] := LongInt($BB67AE85);
  C.H[2] := $3C6EF372; C.H[3] := LongInt($A54FF53A);
  C.H[4] := $510E527F; C.H[5] := LongInt($9B05688C);
  C.H[6] := $1F83D9AB; C.H[7] := $5BE0CD19;
  C.N := 0; C.Len := 0;
End;

{ ajoute N octets a partir de l'adresse A }
Procedure TlShaAdd(Var C : TlSha; A : TlPtr; N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do
  Begin
    C.B[C.N] := TlGet(A + I);
    Inc(C.N);
    If C.N = 64 Then Begin TlShaBlock(C); C.N := 0; End;
  End;
  C.Len := C.Len + N;
End;

Procedure TlShaByte(Var C : TlSha; V : LongInt);
Var B : Array[0..0] Of Byte;
Begin
  B[0] := V And 255;
  TlShaAdd(C, TlPtr(@B[0]), 1);
End;

{ empreinte de 32 octets a l'adresse Out (C est detruit) }
Procedure TlShaDone(Var C : TlSha; Out0 : TlPtr);
Var I, L : LongInt;
Begin
  L := C.Len;
  TlShaByte(C, $80);
  While C.N <> 56 Do TlShaByte(C, 0);
  TlShaByte(C, 0); TlShaByte(C, 0); TlShaByte(C, 0);
  TlShaByte(C, (L Shr 29) And 7);
  TlShaByte(C, (L Shr 21) And 255); TlShaByte(C, (L Shr 13) And 255);
  TlShaByte(C, (L Shr 5) And 255); TlShaByte(C, (L Shl 3) And 255);
  For I := 0 To 7 Do
  Begin
    TlPut(Out0 + I * 4, C.H[I] Shr 24);
    TlPut(Out0 + I * 4 + 1, C.H[I] Shr 16);
    TlPut(Out0 + I * 4 + 2, C.H[I] Shr 8);
    TlPut(Out0 + I * 4 + 3, C.H[I]);
  End;
End;

{ ---- AES-128 (chiffrement seulement : GCM n'utilise que lui) ---- }

Type
  TlBlk = Array[0..15] Of Byte;
  TlKey32 = Array[0..31] Of Byte;

Var
  TlTe1, TlTe2, TlTe3 : Array[0..255] Of LongInt;

Procedure TlAesTables;
Var I : LongInt;
Begin
  TlInit;
  For I := 0 To 255 Do
  Begin
    TlTe1[I] := TlRor(TlTe[I], 8);
    TlTe2[I] := TlRor(TlTe[I], 16);
    TlTe3[I] := TlRor(TlTe[I], 24);
  End;
End;

Function TlSubW(W : LongInt) : LongInt;
Begin
  TlSubW := (TlSBox[(W Shr 24) And 255] Shl 24) Or
            (TlSBox[(W Shr 16) And 255] Shl 16) Or
            (TlSBox[(W Shr 8) And 255] Shl 8) Or TlSBox[W And 255];
End;

Function TlGetW(Var B : TlBlk; I : LongInt) : LongInt;
Begin
  TlGetW := (B[I] Shl 24) Or (B[I + 1] Shl 16) Or (B[I + 2] Shl 8) Or
            B[I + 3];
End;

Procedure TlPutW(Var B : TlBlk; I, W : LongInt);
Begin
  B[I] := (W Shr 24) And 255; B[I + 1] := (W Shr 16) And 255;
  B[I + 2] := (W Shr 8) And 255; B[I + 3] := W And 255;
End;

Procedure TlAesEnc(Var A : TlAes; Var Inp, Outp : TlBlk);
Var S0, S1, S2, S3, T0, T1, T2, T3, R, K : LongInt;
Begin
  S0 := TlGetW(Inp, 0) Xor A.RK[0]; S1 := TlGetW(Inp, 4) Xor A.RK[1];
  S2 := TlGetW(Inp, 8) Xor A.RK[2]; S3 := TlGetW(Inp, 12) Xor A.RK[3];
  K := 4;
  For R := 1 To 9 Do
  Begin
    T0 := TlTe[S0 Shr 24] Xor TlTe1[(S1 Shr 16) And 255] Xor
          TlTe2[(S2 Shr 8) And 255] Xor TlTe3[S3 And 255] Xor A.RK[K];
    T1 := TlTe[S1 Shr 24] Xor TlTe1[(S2 Shr 16) And 255] Xor
          TlTe2[(S3 Shr 8) And 255] Xor TlTe3[S0 And 255] Xor
          A.RK[K + 1];
    T2 := TlTe[S2 Shr 24] Xor TlTe1[(S3 Shr 16) And 255] Xor
          TlTe2[(S0 Shr 8) And 255] Xor TlTe3[S1 And 255] Xor
          A.RK[K + 2];
    T3 := TlTe[S3 Shr 24] Xor TlTe1[(S0 Shr 16) And 255] Xor
          TlTe2[(S1 Shr 8) And 255] Xor TlTe3[S2 And 255] Xor
          A.RK[K + 3];
    S0 := T0; S1 := T1; S2 := T2; S3 := T3;
    K := K + 4;
  End;
  T0 := (TlSBox[S0 Shr 24] Shl 24) Or (TlSBox[(S1 Shr 16) And 255] Shl 16)
        Or (TlSBox[(S2 Shr 8) And 255] Shl 8) Or TlSBox[S3 And 255];
  T1 := (TlSBox[S1 Shr 24] Shl 24) Or (TlSBox[(S2 Shr 16) And 255] Shl 16)
        Or (TlSBox[(S3 Shr 8) And 255] Shl 8) Or TlSBox[S0 And 255];
  T2 := (TlSBox[S2 Shr 24] Shl 24) Or (TlSBox[(S3 Shr 16) And 255] Shl 16)
        Or (TlSBox[(S0 Shr 8) And 255] Shl 8) Or TlSBox[S1 And 255];
  T3 := (TlSBox[S3 Shr 24] Shl 24) Or (TlSBox[(S0 Shr 16) And 255] Shl 16)
        Or (TlSBox[(S1 Shr 8) And 255] Shl 8) Or TlSBox[S2 And 255];
  TlPutW(Outp, 0, T0 Xor A.RK[40]); TlPutW(Outp, 4, T1 Xor A.RK[41]);
  TlPutW(Outp, 8, T2 Xor A.RK[42]); TlPutW(Outp, 12, T3 Xor A.RK[43]);
End;

{ cle de 16 octets }
Procedure TlAesKey(Var A : TlAes; Var Key : TlBlk);
Const Rc : Array[0..9] Of LongInt = ($01, $02, $04, $08, $10, $20,
  $40, $80, $1B, $36);
Var I, T : LongInt;
Begin
  TlAesTables;
  For I := 0 To 3 Do A.RK[I] := TlGetW(Key, I * 4);
  For I := 4 To 43 Do
  Begin
    T := A.RK[I - 1];
    If (I And 3) = 0 Then
      T := TlSubW(TlRor(T, 24)) Xor (Rc[I Div 4 - 1] Shl 24);
    A.RK[I] := A.RK[I - 4] Xor T;
  End;
End;

{ ---- X25519 (RFC 7748) : 32 chiffres de 8 bits signes ---- }

Procedure TlFeCarry(Var A : TlFe);
Var I, C, V, P : LongInt;
Begin
  For P := 1 To 2 Do
    For I := 0 To 31 Do
    Begin
      V := A[I];
      If V >= 0 Then C := V Shr 8 Else C := -((255 - V) Shr 8);
      A[I] := V - C * 256;
      If I < 31 Then A[I + 1] := A[I + 1] + C
      Else A[0] := A[0] + 38 * C;
    End;
End;

Procedure TlFeAdd(Var R : TlFe; Var A, B : TlFe);
Var I : LongInt;
Begin
  For I := 0 To 31 Do R[I] := A[I] + B[I];
  TlFeCarry(R);
End;

Procedure TlFeSub(Var R : TlFe; Var A, B : TlFe);
Var I : LongInt;
Begin
  For I := 0 To 31 Do R[I] := A[I] - B[I];
  TlFeCarry(R);
End;

Procedure TlFeMul(Var R : TlFe; Var A, B : TlFe);
Var T : Array[0..63] Of LongInt; I, J, X : LongInt;
Begin
  For I := 0 To 63 Do T[I] := 0;
  For I := 0 To 31 Do
  Begin
    X := A[I];
    If X <> 0 Then
      For J := 0 To 31 Do T[I + J] := T[I + J] + X * B[J];
  End;
  For I := 0 To 31 Do R[I] := T[I] + 38 * T[I + 32];
  TlFeCarry(R);
End;

Procedure TlFeMulK(Var R : TlFe; Var A : TlFe; K : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 31 Do R[I] := A[I] * K;
  TlFeCarry(R);
End;

Procedure TlFeSwap(Var A, B : TlFe; S : LongInt);
Var I, T, M : LongInt;
Begin
  M := -S;
  For I := 0 To 31 Do
  Begin
    T := M And (A[I] Xor B[I]);
    A[I] := A[I] Xor T; B[I] := B[I] Xor T;
  End;
End;

Procedure TlFeInv(Var R : TlFe; Var A : TlFe);
Var C, T : TlFe; I : LongInt;
Begin
  C := A;
  For I := 253 DownTo 0 Do
  Begin
    TlFeMul(T, C, C); C := T;
    If (I <> 2) And (I <> 4) Then Begin TlFeMul(T, C, A); C := T; End;
  End;
  R := C;
End;

{ valeur canonique (0..p-1) en 32 octets }
Procedure TlFePack(Var A : TlFe; Var O : TlKey32);
Var T : TlFe; I, K, B, V : LongInt;
Begin
  TlFeCarry(A); TlFeCarry(A);
  For K := 1 To 2 Do
  Begin
    B := 0;
    For I := 0 To 31 Do
    Begin
      If I = 0 Then V := A[0] - $ED
      Else If I = 31 Then V := A[31] - $7F
      Else V := A[I] - $FF;
      V := V - B;
      If V < 0 Then Begin V := V + 256; B := 1; End Else B := 0;
      T[I] := V;
    End;
    If B = 0 Then A := T;
  End;
  For I := 0 To 31 Do O[I] := A[I] And 255;
End;

{ Out := X25519(K, U) ; tableaux de 32 octets }
Procedure TlX25519(Var Out0, K, U : TlKey32);
Var X1, X2, Z2, X3, Z3, A, AA, B, BB, E, C, D, DA, CB, T : TlFe;
    E0 : Array[0..31] Of Byte; I, Bit, Sw : LongInt;
Begin
  For I := 0 To 31 Do E0[I] := K[I];
  E0[0] := E0[0] And 248; E0[31] := (E0[31] And 127) Or 64;
  For I := 0 To 31 Do
  Begin
    X1[I] := U[I]; X2[I] := 0; Z2[I] := 0; Z3[I] := 0;
  End;
  X1[31] := X1[31] And 127;
  X2[0] := 1; Z3[0] := 1; X3 := X1;
  Sw := 0;
  For I := 254 DownTo 0 Do
  Begin
    Bit := (E0[I Shr 3] Shr (I And 7)) And 1;
    Sw := Sw Xor Bit;
    TlFeSwap(X2, X3, Sw); TlFeSwap(Z2, Z3, Sw);
    Sw := Bit;
    TlFeAdd(A, X2, Z2); TlFeMul(AA, A, A);
    TlFeSub(B, X2, Z2); TlFeMul(BB, B, B);
    TlFeSub(E, AA, BB);
    TlFeAdd(C, X3, Z3); TlFeSub(D, X3, Z3);
    TlFeMul(DA, D, A); TlFeMul(CB, C, B);
    TlFeAdd(T, DA, CB); TlFeMul(X3, T, T);
    TlFeSub(T, DA, CB); TlFeMul(D, T, T); TlFeMul(Z3, X1, D);
    TlFeMul(X2, AA, BB);
    TlFeMulK(T, E, 121665); TlFeAdd(T, AA, T); TlFeMul(Z2, E, T);
  End;
  TlFeSwap(X2, X3, Sw); TlFeSwap(Z2, Z3, Sw);
  TlFeInv(T, Z2); TlFeMul(A, X2, T);
  TlFePack(A, Out0);
End;

{ ==================================================================== }
{ Cryptographie de SSH : HMAC-SHA256, AES-128-CTR, SHA-512, Ed25519,   }
{ RSA (PKCS #1 v1.5, SHA-256 ou SHA-512)                               }
{ ==================================================================== }

{ ---- HMAC-SHA256 (cle de 64 octets au plus) : HMAC(K, M1 || M2) ---- }

Procedure TlHmac(Key : TlPtr; KLen : LongInt; Msg : TlPtr;
  MLen : LongInt; Msg2 : TlPtr; M2Len : LongInt; Out0 : TlPtr);
Var C : TlSha; Pad : Array[0..63] Of Byte; In0 : Array[0..31] Of Byte;
    I : LongInt;
Begin
  For I := 0 To 63 Do
    If I < KLen Then Pad[I] := TlGet(Key + I) Xor $36
    Else Pad[I] := $36;
  TlShaInit(C);
  TlShaAdd(C, TlPtr(@Pad[0]), 64);
  If MLen > 0 Then TlShaAdd(C, Msg, MLen);
  If M2Len > 0 Then TlShaAdd(C, Msg2, M2Len);
  TlShaDone(C, TlPtr(@In0[0]));
  For I := 0 To 63 Do Pad[I] := Pad[I] Xor ($36 Xor $5C);
  TlShaInit(C);
  TlShaAdd(C, TlPtr(@Pad[0]), 64);
  TlShaAdd(C, TlPtr(@In0[0]), 32);
  TlShaDone(C, Out0);
End;

{ ---- AES-128-CTR : N octets (multiple de 16) a l'adresse D, sur place ;
  le compteur de 128 bits (gros-boutiste) avance d'un bloc a la fois ---- }

Procedure AesCtr(Var A : TlAes; Var Ctr : TlBlk; D : TlPtr; N : LongInt);
Var Ks : TlBlk; I, K, C : LongInt;
Begin
  K := 0;
  While K < N Do
  Begin
    TlAesEnc(A, Ctr, Ks);
    For I := 0 To 15 Do
      If K + I < N Then TlPut(D + K + I, TlGet(D + K + I) Xor Ks[I]);
    I := 15;
    Repeat
      C := (Ctr[I] + 1) And 255; Ctr[I] := C; Dec(I);
    Until (C <> 0) Or (I < 0);
    K := K + 16;
  End;
End;

{ ---- SHA-512 : mots de 64 bits en deux LongInt (haut, bas) ---- }

Type
  TS5 = Record
    H : Array[0..15] Of LongInt;     { H[2i] haut, H[2i+1] bas }
    B : Array[0..127] Of Byte;
    N : LongInt;
    Len : LongInt;
  End;
  T64 = Array[0..63] Of Byte;

Const
  S5K : Array[0..159] Of LongWord = (
    $428A2F98, $D728AE22, $71374491, $23EF65CD, $B5C0FBCF, $EC4D3B2F,
    $E9B5DBA5, $8189DBBC, $3956C25B, $F348B538, $59F111F1, $B605D019,
    $923F82A4, $AF194F9B, $AB1C5ED5, $DA6D8118, $D807AA98, $A3030242,
    $12835B01, $45706FBE, $243185BE, $4EE4B28C, $550C7DC3, $D5FFB4E2,
    $72BE5D74, $F27B896F, $80DEB1FE, $3B1696B1, $9BDC06A7, $25C71235,
    $C19BF174, $CF692694, $E49B69C1, $9EF14AD2, $EFBE4786, $384F25E3,
    $0FC19DC6, $8B8CD5B5, $240CA1CC, $77AC9C65, $2DE92C6F, $592B0275,
    $4A7484AA, $6EA6E483, $5CB0A9DC, $BD41FBD4, $76F988DA, $831153B5,
    $983E5152, $EE66DFAB, $A831C66D, $2DB43210, $B00327C8, $98FB213F,
    $BF597FC7, $BEEF0EE4, $C6E00BF3, $3DA88FC2, $D5A79147, $930AA725,
    $06CA6351, $E003826F, $14292967, $0A0E6E70, $27B70A85, $46D22FFC,
    $2E1B2138, $5C26C926, $4D2C6DFC, $5AC42AED, $53380D13, $9D95B3DF,
    $650A7354, $8BAF63DE, $766A0ABB, $3C77B2A8, $81C2C92E, $47EDAEE6,
    $92722C85, $1482353B, $A2BFE8A1, $4CF10364, $A81A664B, $BC423001,
    $C24B8B70, $D0F89791, $C76C51A3, $0654BE30, $D192E819, $D6EF5218,
    $D6990624, $5565A910, $F40E3585, $5771202A, $106AA070, $32BBD1B8,
    $19A4C116, $B8D2D0C8, $1E376C08, $5141AB53, $2748774C, $DF8EEB99,
    $34B0BCB5, $E19B48A8, $391C0CB3, $C5C95A63, $4ED8AA4A, $E3418ACB,
    $5B9CCA4F, $7763E373, $682E6FF3, $D6B2B8A3, $748F82EE, $5DEFB2FC,
    $78A5636F, $43172F60, $84C87814, $A1F0AB72, $8CC70208, $1A6439EC,
    $90BEFFFA, $23631E28, $A4506CEB, $DE82BDE9, $BEF9A3F7, $B2C67915,
    $C67178F2, $E372532B, $CA273ECE, $EA26619C, $D186B8C7, $21C0C207,
    $EADA7DD6, $CDE0EB1E, $F57D4F7F, $EE6ED178, $06F067AA, $72176FBA,
    $0A637DC5, $A2C898A6, $113F9804, $BEF90DAE, $1B710B35, $131C471B,
    $28DB77F5, $23047D84, $32CAAB7B, $40C72493, $3C9EBE0A, $15C9BEBC,
    $431D67C4, $9C100D4C, $4CC5D4BE, $CB3E42B6, $597F299C, $FC657E2A,
    $5FCB6FAB, $3AD6FAEC, $6C44198C, $4A475817);

Var
  S5KL : Array[0..159] Of LongInt;
  S5Ready : Boolean;

{ (H:L) := (H:L) + (BH:BL) ; additions de 16 bits pour la retenue }
Procedure A64(Var H, L : LongInt; BH, BL : LongInt);
Var X, Y : LongInt;
Begin
  X := (L And $FFFF) + (BL And $FFFF);
  Y := ((L Shr 16) And $FFFF) + ((BL Shr 16) And $FFFF) + (X Shr 16);
  L := (Y Shl 16) Or (X And $FFFF);
  H := H + BH + ((Y Shr 16) And 1);
End;

{ rotation a droite de N bits (0 < N < 64, N <> 32) }
Procedure R64(H, L, N : LongInt; Var RH, RL : LongInt);
Var T : LongInt;
Begin
  If N > 32 Then
  Begin
    T := H; H := L; L := T; N := N - 32;
  End;
  RH := (H Shr N) Or (L Shl (32 - N));
  RL := (L Shr N) Or (H Shl (32 - N));
End;

Procedure S5Block(Var C : TS5);
Var WH, WL : Array[0..79] Of LongInt;
    VH, VL : Array[0..7] Of LongInt;
    I, J, AH, AL, BH, BL, XH, XL, T1H, T1L, T2H, T2L : LongInt;
Begin
  For I := 0 To 15 Do
  Begin
    J := I * 8;
    WH[I] := (C.B[J] Shl 24) Or (C.B[J + 1] Shl 16) Or (C.B[J + 2] Shl 8) Or
             C.B[J + 3];
    WL[I] := (C.B[J + 4] Shl 24) Or (C.B[J + 5] Shl 16) Or
             (C.B[J + 6] Shl 8) Or C.B[J + 7];
  End;
  For I := 16 To 79 Do
  Begin
    { s0 = ror1 ^ ror8 ^ shr7 ; s1 = ror19 ^ ror61 ^ shr6 }
    R64(WH[I - 15], WL[I - 15], 1, AH, AL);
    R64(WH[I - 15], WL[I - 15], 8, BH, BL);
    XH := AH Xor BH Xor (WH[I - 15] Shr 7);
    XL := AL Xor BL Xor ((WL[I - 15] Shr 7) Or (WH[I - 15] Shl 25));
    R64(WH[I - 2], WL[I - 2], 19, AH, AL);
    R64(WH[I - 2], WL[I - 2], 61, BH, BL);
    T1H := AH Xor BH Xor (WH[I - 2] Shr 6);
    T1L := AL Xor BL Xor ((WL[I - 2] Shr 6) Or (WH[I - 2] Shl 26));
    A64(T1H, T1L, XH, XL);
    A64(T1H, T1L, WH[I - 7], WL[I - 7]);
    A64(T1H, T1L, WH[I - 16], WL[I - 16]);
    WH[I] := T1H; WL[I] := T1L;
  End;
  For I := 0 To 7 Do
  Begin
    VH[I] := C.H[I * 2]; VL[I] := C.H[I * 2 + 1];
  End;
  For I := 0 To 79 Do
  Begin
    { T1 = h + S1(e) + Ch(e,f,g) + K + W }
    R64(VH[4], VL[4], 14, AH, AL);
    R64(VH[4], VL[4], 18, BH, BL);
    XH := AH Xor BH; XL := AL Xor BL;
    R64(VH[4], VL[4], 41, AH, AL);
    XH := XH Xor AH; XL := XL Xor AL;
    T1H := VH[7]; T1L := VL[7];
    A64(T1H, T1L, XH, XL);
    A64(T1H, T1L, (VH[4] And VH[5]) Xor ((Not VH[4]) And VH[6]),
        (VL[4] And VL[5]) Xor ((Not VL[4]) And VL[6]));
    A64(T1H, T1L, S5KL[I * 2], S5KL[I * 2 + 1]);
    A64(T1H, T1L, WH[I], WL[I]);
    { T2 = S0(a) + Maj(a,b,c) }
    R64(VH[0], VL[0], 28, AH, AL);
    R64(VH[0], VL[0], 34, BH, BL);
    T2H := AH Xor BH; T2L := AL Xor BL;
    R64(VH[0], VL[0], 39, AH, AL);
    T2H := T2H Xor AH; T2L := T2L Xor AL;
    A64(T2H, T2L, (VH[0] And VH[1]) Xor (VH[0] And VH[2]) Xor
        (VH[1] And VH[2]), (VL[0] And VL[1]) Xor (VL[0] And VL[2]) Xor
        (VL[1] And VL[2]));
    For J := 7 DownTo 1 Do
    Begin
      VH[J] := VH[J - 1]; VL[J] := VL[J - 1];
    End;
    A64(VH[4], VL[4], T1H, T1L);
    VH[0] := T1H; VL[0] := T1L;
    A64(VH[0], VL[0], T2H, T2L);
  End;
  For I := 0 To 7 Do
    A64(C.H[I * 2], C.H[I * 2 + 1], VH[I], VL[I]);
End;

Procedure S5Init(Var C : TS5);
Var I : LongInt; W : LongWord;
Begin
  If Not S5Ready Then
  Begin
    For I := 0 To 159 Do
    Begin
      W := S5K[I]; S5KL[I] := LongInt(W);
    End;
    S5Ready := True;
  End;
  C.H[0] := $6A09E667; C.H[1] := LongInt($F3BCC908);
  C.H[2] := LongInt($BB67AE85); C.H[3] := LongInt($84CAA73B);
  C.H[4] := $3C6EF372; C.H[5] := LongInt($FE94F82B);
  C.H[6] := LongInt($A54FF53A); C.H[7] := $5F1D36F1;
  C.H[8] := $510E527F; C.H[9] := LongInt($ADE682D1);
  C.H[10] := LongInt($9B05688C); C.H[11] := $2B3E6C1F;
  C.H[12] := $1F83D9AB; C.H[13] := LongInt($FB41BD6B);
  C.H[14] := $5BE0CD19; C.H[15] := $137E2179;
  C.N := 0; C.Len := 0;
End;

Procedure S5Add(Var C : TS5; A : TlPtr; N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do
  Begin
    C.B[C.N] := TlGet(A + I);
    Inc(C.N);
    If C.N = 128 Then Begin S5Block(C); C.N := 0; End;
  End;
  C.Len := C.Len + N;
End;

Procedure S5Byte(Var C : TS5; V : LongInt);
Var B : Array[0..0] Of Byte;
Begin
  B[0] := V And 255;
  S5Add(C, TlPtr(@B[0]), 1);
End;

{ empreinte de 64 octets (C est detruit) }
Procedure S5Done(Var C : TS5; Out0 : TlPtr);
Var I, L : LongInt;
Begin
  L := C.Len;
  S5Byte(C, $80);
  While C.N <> 120 Do S5Byte(C, 0);
  S5Byte(C, 0); S5Byte(C, 0); S5Byte(C, 0);
  S5Byte(C, (L Shr 29) And 7);
  S5Byte(C, (L Shr 21) And 255); S5Byte(C, (L Shr 13) And 255);
  S5Byte(C, (L Shr 5) And 255); S5Byte(C, (L Shl 3) And 255);
  For I := 0 To 15 Do
  Begin
    TlPut(Out0 + I * 4, C.H[I] Shr 24);
    TlPut(Out0 + I * 4 + 1, C.H[I] Shr 16);
    TlPut(Out0 + I * 4 + 2, C.H[I] Shr 8);
    TlPut(Out0 + I * 4 + 3, C.H[I]);
  End;
End;

{ ---- Ed25519 (RFC 8032) : verification d'une signature ---- }
{ Points en coordonnees etendues (X:Y:Z:T), x = X/Z, y = Y/Z, xy = T/Z ;
  corps GF(2^255-19) de X25519 (TlFe). }

Type
  TEdPt = Record
    X, Y, Z, T : TlFe;
  End;

Var
  EdD, EdD2, EdSqrtM1 : TlFe;          { d, 2d et racine de -1 }
  EdB : TEdPt;                         { point de base }
  EdReady : Boolean;

Procedure FeFromBytes(Var R : TlFe; Var B : TlKey32);
Var I : LongInt;
Begin
  For I := 0 To 31 Do R[I] := B[I];
  R[31] := R[31] And 127;
End;

Procedure FeSet(Var R : TlFe; V : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 31 Do R[I] := 0;
  R[0] := V;
  TlFeCarry(R);
End;

{ R := A ^ E, E entier de 256 bits (petit-boutiste) }
Procedure FePow(Var R, A : TlFe; Var E : TlKey32);
Var C, T : TlFe; I : LongInt; Started : Boolean;
Begin
  FeSet(C, 1);
  Started := False;
  For I := 255 DownTo 0 Do
  Begin
    If Started Then Begin TlFeMul(T, C, C); C := T; End;
    If ((E[I Shr 3] Shr (I And 7)) And 1) <> 0 Then
    Begin
      TlFeMul(T, C, A); C := T; Started := True;
    End;
  End;
  R := C;
End;

Function FeEqual(Var A, B : TlFe) : Boolean;
Var PA, PB : TlKey32; X, Y : TlFe; I : LongInt;
Begin
  X := A; Y := B;
  TlFePack(X, PA); TlFePack(Y, PB);
  FeEqual := True;
  For I := 0 To 31 Do
    If PA[I] <> PB[I] Then FeEqual := False;
End;

Function FeOdd(Var A : TlFe) : LongInt;
Var P : TlKey32; X : TlFe;
Begin
  X := A;
  TlFePack(X, P);
  FeOdd := P[0] And 1;
End;

Procedure FeNeg(Var R, A : TlFe);
Var Z : TlFe;
Begin
  FeSet(Z, 0);
  TlFeSub(R, Z, A);
End;

{ R := P + Q (formule unifiee, a = -1 : vaut aussi pour P + P) }
Procedure EdAdd(Var R : TEdPt; Var P, Q : TEdPt);
Var A, B, C, D, E, F, G, H, T1, T2 : TlFe;
Begin
  TlFeSub(T1, P.Y, P.X); TlFeSub(T2, Q.Y, Q.X); TlFeMul(A, T1, T2);
  TlFeAdd(T1, P.Y, P.X); TlFeAdd(T2, Q.Y, Q.X); TlFeMul(B, T1, T2);
  TlFeMul(T1, P.T, Q.T); TlFeMul(C, T1, EdD2);
  TlFeMul(T1, P.Z, Q.Z); TlFeAdd(D, T1, T1);
  TlFeSub(E, B, A); TlFeSub(F, D, C); TlFeAdd(G, D, C); TlFeAdd(H, B, A);
  TlFeMul(R.X, E, F); TlFeMul(R.Y, G, H);
  TlFeMul(R.T, E, H); TlFeMul(R.Z, F, G);
End;

{ R := [S] P (S : 32 octets petit-boutistes) }
Procedure EdMul(Var R : TEdPt; Var P : TEdPt; Var S : TlKey32);
Var Q, T : TEdPt; I : LongInt;
Begin
  FeSet(Q.X, 0); FeSet(Q.Y, 1); FeSet(Q.Z, 1); FeSet(Q.T, 0);
  For I := 255 DownTo 0 Do
  Begin
    EdAdd(T, Q, Q); Q := T;
    If ((S[I Shr 3] Shr (I And 7)) And 1) <> 0 Then
    Begin
      EdAdd(T, Q, P); Q := T;
    End;
  End;
  R := Q;
End;

Procedure EdEncode(Var P : TEdPt; Var O : TlKey32);
Var Zi, X, Y : TlFe; PX : TlKey32;
Begin
  TlFeInv(Zi, P.Z);
  TlFeMul(X, P.X, Zi); TlFeMul(Y, P.Y, Zi);
  TlFePack(X, PX);
  TlFePack(Y, O);
  O[31] := O[31] Xor ((PX[0] And 1) Shl 7);
End;

{ point a partir de son codage ; False s'il n'est pas sur la courbe }
Function EdDecode(Var P : TEdPt; Var B : TlKey32) : Boolean;
Var Y, Y2, U, V, V3, X, T, T2, One : TlFe; Sign, I : LongInt;
    E : TlKey32;
Begin
  EdDecode := False;
  Sign := (B[31] Shr 7) And 1;
  FeFromBytes(Y, B);
  FeSet(One, 1);
  TlFeMul(Y2, Y, Y);
  TlFeSub(U, Y2, One);                          { u = y^2 - 1 }
  TlFeMul(T, Y2, EdD);
  TlFeAdd(V, T, One);                           { v = d y^2 + 1 }
  TlFeMul(V3, V, V); TlFeMul(V3, V3, V);        { v^3 }
  TlFeMul(T, V3, V3); TlFeMul(T, T, V);         { v^7 }
  TlFeMul(T, T, U);                             { u v^7 }
  E[0] := $FD; For I := 1 To 30 Do E[I] := $FF; E[31] := $0F;
  FePow(T2, T, E);                              { (u v^7)^((p-5)/8) }
  TlFeMul(X, U, V3); TlFeMul(X, X, T2);         { x = u v^3 (..)^.. }
  TlFeMul(T, X, X); TlFeMul(T, T, V);           { v x^2 }
  If Not FeEqual(T, U) Then
  Begin
    FeNeg(T2, U);
    If Not FeEqual(T, T2) Then Exit;
    TlFeMul(T, X, EdSqrtM1); X := T;
  End;
  If (FeOdd(X) = 0) And (Sign = 1) Then
  Begin
    FeSet(T, 0);
    If FeEqual(X, T) Then Exit;
  End;
  If FeOdd(X) <> Sign Then Begin FeNeg(T, X); X := T; End;
  P.X := X; P.Y := Y; FeSet(P.Z, 1); TlFeMul(P.T, X, Y);
  EdDecode := True;
End;

Procedure EdInit;
Var A, B, T : TlFe; E : TlKey32; I : LongInt;
Begin
  If EdReady Then Exit;
  { d = -121665 / 121666 ; on garde 2d }
  FeSet(A, 0); FeSet(B, 121665); TlFeSub(A, A, B);
  FeSet(B, 121666); TlFeInv(T, B); TlFeMul(EdD, A, T);
  TlFeAdd(EdD2, EdD, EdD);
  { sqrt(-1) = 2^((p-1)/4) }
  E[0] := $FB; For I := 1 To 30 Do E[I] := $FF; E[31] := $1F;
  FeSet(A, 2); FePow(EdSqrtM1, A, E);
  { B : y = 4/5, x pair }
  E[0] := $58; For I := 1 To 31 Do E[I] := $66;
  EdReady := True;
  EdDecode(EdB, E);
End;

{ S (32 octets) < L ? }
Const
  EdL : Array[0..31] Of Byte = ($ED, $D3, $F5, $5C, $1A, $63, $12, $58,
    $D6, $9C, $F7, $A2, $DE, $F9, $DE, $14, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, $10);

{ R := H mod L (H : 64 octets petit-boutistes) }
Procedure EdModL(Var H : T64; Var R : TlKey32);
Var A : Array[0..32] Of LongInt; I, J, Bit, C, V : LongInt; Ge : Boolean;
Begin
  For I := 0 To 32 Do A[I] := 0;
  For I := 511 DownTo 0 Do
  Begin
    Bit := (H[I Shr 3] Shr (I And 7)) And 1;
    C := Bit;
    For J := 0 To 32 Do
    Begin
      V := A[J] * 2 + C;
      A[J] := V And 255; C := V Shr 8;
    End;
    { A >= L ? }
    Ge := A[32] <> 0;
    If Not Ge Then
    Begin
      Ge := True;
      For J := 31 DownTo 0 Do
        If A[J] <> EdL[J] Then
        Begin
          Ge := A[J] > EdL[J];
          Break;
        End;
    End;
    If Ge Then
    Begin
      C := 0;
      For J := 0 To 32 Do
      Begin
        If J < 32 Then V := A[J] - EdL[J] - C Else V := A[J] - C;
        If V < 0 Then Begin V := V + 256; C := 1; End Else C := 0;
        A[J] := V;
      End;
    End;
  End;
  For I := 0 To 31 Do R[I] := A[I];
End;

{ signature Sig (64 octets) du message Msg (N octets) par la cle Pub
  (32 octets) }
Function Ed25519Verify(Pub, Msg : TlPtr; N : LongInt; Sig : TlPtr)
  : Boolean;
Var A, P1, P2, R : TEdPt; PK, S, K, RB, Enc : TlKey32; H : T64;
    C : TS5; I : LongInt; Lt : Boolean;
Begin
  Ed25519Verify := False;
  EdInit;
  For I := 0 To 31 Do
  Begin
    PK[I] := TlGet(Pub + I); RB[I] := TlGet(Sig + I);
    S[I] := TlGet(Sig + 32 + I);
  End;
  { S < L }
  Lt := False;
  For I := 31 DownTo 0 Do
    If S[I] <> EdL[I] Then
    Begin
      Lt := S[I] < EdL[I];
      Break;
    End;
  If Not Lt Then Exit;
  If Not EdDecode(A, PK) Then Exit;
  S5Init(C);
  S5Add(C, Sig, 32); S5Add(C, Pub, 32);
  If N > 0 Then S5Add(C, Msg, N);
  S5Done(C, TlPtr(@H[0]));
  EdModL(H, K);
  { [S]B - [k]A doit valoir R }
  EdMul(P1, EdB, S);
  FeNeg(R.X, A.X); R.Y := A.Y; R.Z := A.Z; FeNeg(R.T, A.T);
  EdMul(P2, R, K);
  EdAdd(R, P1, P2);
  EdEncode(R, Enc);
  For I := 0 To 31 Do
    If Enc[I] <> RB[I] Then Exit;
  Ed25519Verify := True;
End;

{ ---- RSA : verification PKCS #1 v1.5 (exposant public quelconque) ---- }
{ Entiers en octets petit-boutistes (LongInt), multiplication de
  Montgomery en base 256. Modules jusqu'a 8192 bits. }

Const
  RsaMax = 1024;

Type
  TBig = Array[0..RsaMax + 1] Of LongInt;

Var
  RsN, RsT, RsR2, RsA, RsX, RsOne : TBig;
  RsK, RsNi : LongInt;

{ R := A * B / 256^k mod N (A, B < N) }
Procedure RsMul(Var R : TBig; Var A, B : TBig);
Var I, J, T, C, M, Ai : LongInt;
Begin
  For I := 0 To RsK + 1 Do RsT[I] := 0;
  For I := 0 To RsK - 1 Do
  Begin
    C := 0; Ai := A[I];
    For J := 0 To RsK - 1 Do
    Begin
      T := RsT[J] + Ai * B[J] + C;
      RsT[J] := T And 255; C := T Shr 8;
    End;
    T := RsT[RsK] + C;
    RsT[RsK] := T And 255; RsT[RsK + 1] := T Shr 8;
    M := (RsT[0] * RsNi) And 255;
    T := RsT[0] + M * RsN[0]; C := T Shr 8;
    For J := 1 To RsK - 1 Do
    Begin
      T := RsT[J] + M * RsN[J] + C;
      RsT[J - 1] := T And 255; C := T Shr 8;
    End;
    T := RsT[RsK] + C;
    RsT[RsK - 1] := T And 255; C := T Shr 8;
    RsT[RsK] := RsT[RsK + 1] + C;
  End;
  { RsT[0..k] < 2N : soustraire N si besoin }
  J := RsT[RsK];
  If J = 0 Then
  Begin
    J := 1;
    For I := RsK - 1 DownTo 0 Do
      If RsT[I] <> RsN[I] Then
      Begin
        If RsT[I] > RsN[I] Then J := 1 Else J := 0;
        Break;
      End;
  End;
  If J <> 0 Then
  Begin
    C := 0;
    For I := 0 To RsK - 1 Do
    Begin
      T := RsT[I] - RsN[I] - C;
      If T < 0 Then Begin T := T + 256; C := 1; End Else C := 0;
      RsT[I] := T;
    End;
  End;
  For I := 0 To RsK - 1 Do R[I] := RsT[I];
End;

{ Sig^E mod N ; NB, EB, SB : gros-boutistes (longueurs en octets) ;
  resultat gros-boutiste de k octets en Out0 }
Function RsaPow(NB : TlPtr; NL : LongInt; EB : TlPtr; EL : LongInt;
  SB : TlPtr; SL : LongInt; Out0 : TlPtr) : Boolean;
Var I, J, C, V, Bit, X : LongInt; Ge, Started : Boolean;
Begin
  RsaPow := False;
  While (NL > 0) And (TlGet(NB) = 0) Do Begin Inc(NB); Dec(NL); End;
  If (NL < 32) Or (NL > RsaMax) Or ((TlGet(NB + NL - 1) And 1) = 0) Then
    Exit;
  RsK := NL;
  For I := 0 To RsK + 1 Do
  Begin
    RsN[I] := 0; RsA[I] := 0; RsOne[I] := 0;
  End;
  For I := 0 To NL - 1 Do RsN[I] := TlGet(NB + NL - 1 - I);
  While (SL > 0) And (TlGet(SB) = 0) Do Begin Inc(SB); Dec(SL); End;
  If SL > NL Then Exit;
  For I := 0 To SL - 1 Do RsA[I] := TlGet(SB + SL - 1 - I);
  { signature < N }
  Ge := True;
  For I := RsK - 1 DownTo 0 Do
    If RsA[I] <> RsN[I] Then
    Begin
      Ge := RsA[I] > RsN[I];
      Break;
    End;
  If Ge Then Exit;
  { -1/N mod 256 }
  X := 1;
  For I := 1 To 4 Do X := (X * (2 - RsN[0] * X)) And 255;
  RsNi := (256 - X) And 255;
  { R2 = 256^(2k) mod N : doublements successifs de 1 }
  For I := 0 To RsK + 1 Do RsR2[I] := 0;
  RsR2[0] := 1;
  For I := 1 To RsK * 16 Do
  Begin
    C := 0;
    For J := 0 To RsK Do
    Begin
      V := RsR2[J] * 2 + C;
      RsR2[J] := V And 255; C := V Shr 8;
    End;
    Ge := RsR2[RsK] <> 0;
    If Not Ge Then
    Begin
      Ge := True;
      For J := RsK - 1 DownTo 0 Do
        If RsR2[J] <> RsN[J] Then
        Begin
          Ge := RsR2[J] > RsN[J];
          Break;
        End;
    End;
    If Ge Then
    Begin
      C := 0;
      For J := 0 To RsK Do
      Begin
        V := RsR2[J] - RsN[J] - C;
        If V < 0 Then Begin V := V + 256; C := 1; End Else C := 0;
        RsR2[J] := V;
      End;
    End;
  End;
  RsMul(RsA, RsA, RsR2);                       { forme de Montgomery }
  RsX := RsA;
  Started := False;
  For I := 0 To EL - 1 Do
  Begin
    V := TlGet(EB + I);
    For Bit := 7 DownTo 0 Do
    Begin
      If Started Then RsMul(RsX, RsX, RsX);
      If ((V Shr Bit) And 1) <> 0 Then
      Begin
        If Started Then RsMul(RsX, RsX, RsA)
        Else Started := True;
      End;
    End;
  End;
  If Not Started Then Exit;
  RsOne[0] := 1;
  RsMul(RsX, RsX, RsOne);
  For I := 0 To RsK - 1 Do TlPut(Out0 + I, RsX[RsK - 1 - I]);
  RsaPow := True;
End;

{ signature PKCS #1 v1.5 de l'empreinte Hash (32 octets : SHA-256, 64 :
  SHA-512) }
Function RsaVerify(NB : TlPtr; NL : LongInt; EB : TlPtr; EL : LongInt;
  SB : TlPtr; SL : LongInt; Hash : TlPtr; HL : LongInt) : Boolean;
Const
  Di256 : Array[0..18] Of Byte = ($30, $31, $30, $0D, $06, $09, $60, $86,
    $48, $01, $65, $03, $04, $02, $01, $05, $00, $04, $20);
  Di512 : Array[0..18] Of Byte = ($30, $51, $30, $0D, $06, $09, $60, $86,
    $48, $01, $65, $03, $04, $02, $03, $05, $00, $04, $40);
Var Em : Array[0..RsaMax - 1] Of Byte; I, K, P : LongInt;
Begin
  RsaVerify := False;
  If Not RsaPow(NB, NL, EB, EL, SB, SL, TlPtr(@Em[0])) Then Exit;
  K := RsK;
  If (Em[0] <> 0) Or (Em[1] <> 1) Then Exit;
  P := K - HL - 19;                          { debut de DigestInfo }
  If P < 11 Then Exit;
  For I := 2 To P - 2 Do
    If Em[I] <> $FF Then Exit;
  If Em[P - 1] <> 0 Then Exit;
  For I := 0 To 18 Do
    If HL = 64 Then
    Begin
      If Em[P + I] <> Di512[I] Then Exit;
    End
    Else If Em[P + I] <> Di256[I] Then Exit;
  For I := 0 To HL - 1 Do
    If Em[P + 19 + I] <> TlGet(Hash + I) Then Exit;
  RsaVerify := True;
End;

{ ---- aleas : SHA-256 d'un compteur et d'evenements du systeme ---- }

Var
  TlPool : TlSha;
  TlPoolN : LongInt;

Procedure TlEntropy; Forward;

Procedure TlSeed(V : LongInt);
Begin
  If TlPoolN = 0 Then TlShaInit(TlPool);
  Inc(TlPoolN);
  TlShaByte(TlPool, V); TlShaByte(TlPool, V Shr 8);
  TlShaByte(TlPool, V Shr 16); TlShaByte(TlPool, V Shr 24);
End;

Procedure TlRandom(A : TlPtr; N : LongInt);
Var C : TlSha; H : TlKey32; I, K : LongInt;
Begin
  TlEntropy;
  K := 0;
  While K < N Do
  Begin
    TlSeed(K);
    C := TlPool;
    TlShaDone(C, TlPtr(@H[0]));
    I := 0;
    While (I < 32) And (K < N) Do
    Begin
      TlPut(A + K, H[I]); Inc(I); Inc(K);
    End;
  End;
End;
{ ==================================================================== }
{ Protocoles : FTP (RFC 959, 2428, 3659) et SFTP version 3 sur SSH-2    }
{ (RFC 4251 a 4254 : curve25519-sha256, ssh-ed25519 / rsa-sha2-256 et   }
{ rsa-sha2-512, aes128-ctr, hmac-sha2-256, mot de passe ou clavier      }
{ interactif). Une seule session a la fois (Ss*). Les fonctions         }
{ attendues de l'appelant : NetOpen, NetSend, NetRecv, NetClose,        }
{ LogMsg, LfOpen, LfCreate, LfRead, LfWrite, LfClose, LfSize, HostAsk,  }
{ XferStep (progression, annulation).                                   }
{ ==================================================================== }

Const
  PrFtp = 0; PrSftp = 1;
  LgStatus = 0; LgCmd = 1; LgReply = 2; LgError = 3; LgList = 4;
  MaxEnt = 2000;                      { elements d'une liste }
  SshMax = 36000;                     { paquet SSH (charge 32 Ko + entete) }
  SfMax = 70000;                      { flux SFTP recu (2 paquets) }

Type
  TEntry = Record
    Name : String;
    Size : Double;
    Dir, Link : Boolean;
    Time : String[20];                { AAAA-MM-JJ HH:MM }
    Perm : String[11];
    Owner : String[40];
  End;
  TEntArr = Array[0..MaxEnt - 1] Of TEntry;
  PEntArr = ^TEntArr;

Var
  SsProto, SsSock, SsPort : LongInt;
  SsHost, SsUser, SsPass, SsCwd, SsErr, SsSys : String;
  SsOpen, SsLost : Boolean;           { SsLost : connexion de controle coupee }
  { FTP }
  FtUtf8, FtMlsd, FtEpsvBad : Boolean;
  FtLine : String;                     { derniere ligne de reponse }
  FtCode : LongInt;
  FtRb : Array[0..4095] Of Byte;       { tampon de la connexion de controle }
  FtRPos, FtREnd : LongInt;
  { SSH }
  ShOut, ShIn : TlPtr;                 { paquets (SshMax + 64) }
  ShInLen : LongInt;                   { charge recue }
  ShEnc, ShStrict : Boolean;
  ShSeqC, ShSeqS : LongInt;
  ShAesC, ShAesS : TlAes;
  ShCtrC, ShCtrS : TlBlk;
  ShMacC, ShMacS : TlKey32;
  ShSid : TlKey32;
  ShVc, ShVs : String;
  ShChan, ShRWin, ShRMax, ShLWin : LongInt;
  { SFTP }
  SfBuf : TlPtr;                       { octets du canal pas encore lus }
  SfLen, SfId : LongInt;
  SfPk : TlPtr;                        { paquet SFTP recu (charge) }
  SfPkLen, SfStatus : LongInt;
  SfMsg : String;
  { file : progression }
  XfDone : Double;
  XfCancel : Boolean;
  FtLBuf, XBuf, KxIc, KxIs : TlPtr;    { tampons alloues une fois }

Procedure LogMsg(Kind : LongInt; S : String); Forward;
Function NetOpen(Host : String; Port : LongInt; Var Err : String) : LongInt;
  Forward;
Function NetSend(S : LongInt; A : TlPtr; N : LongInt) : LongInt; Forward;
Function NetRecv(S : LongInt; A : TlPtr; N : LongInt) : LongInt; Forward;
Procedure NetClose(S : LongInt); Forward;
Function LfOpen(Name : String) : LongInt; Forward;
Function LfCreate(Name : String; Append : Boolean) : LongInt; Forward;
Function LfRead(H : LongInt; A : TlPtr; N : LongInt) : LongInt; Forward;
Function LfWrite(H : LongInt; A : TlPtr; N : LongInt) : Boolean; Forward;
Procedure LfClose(H : LongInt); Forward;
Function HostAsk(Fp, Alg : String; Changed : Boolean) : LongInt;
  Forward;
Procedure XferStep; Forward;
Procedure NowYM(Var Y, M : LongInt); Forward;
Function KnownHost(Key : String) : String; Forward;
Procedure SaveHost(Key, Val : String); Forward;

{ ---- outils ---- }

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function DStr(V : Double) : String;
Var S : String;
Begin
  Str(V : 0 : 0, S);
  DStr := S;
End;

Function SVal(S : String) : LongInt;
Var V, C : LongInt;
Begin
  Val(S, V, C);
  If C <> 0 Then V := 0;
  SVal := V;
End;

Function DVal(S : String) : Double;
Var V : Double; C : LongInt;
Begin
  Val(S, V, C);
  If C <> 0 Then V := 0;
  DVal := V;
End;

Function UpS(S : String) : String;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do S[I] := UpCase(S[I]);
  UpS := S;
End;

Function TrimS(S : String) : String;
Begin
  While (S <> '') And (S[1] <= ' ') Do Delete(S, 1, 1);
  While (S <> '') And (S[Length(S)] <= ' ') Do S := Copy(S, 1, Length(S) - 1);
  TrimS := S;
End;

Function Pad2(V : LongInt) : String;
Begin
  If V < 10 Then Pad2 := '0' + IStr(V) Else Pad2 := IStr(V);
End;

{ UTF-8 <-> ANSI (Windows-1252 limite a Latin-1) }
Function U8ToA(S : String) : String;
Var R : String; I, C : LongInt;
Begin
  R := ''; I := 1;
  While I <= Length(S) Do
  Begin
    C := Ord(S[I]);
    If (C >= $C2) And (C <= $C3) And (I < Length(S)) Then
    Begin
      R := R + Chr(((C And 3) Shl 6) Or (Ord(S[I + 1]) And 63));
      I := I + 2;
    End
    Else If C >= $C0 Then
    Begin
      R := R + '?';
      Inc(I);
      While (I <= Length(S)) And ((Ord(S[I]) And $C0) = $80) Do Inc(I);
    End
    Else
    Begin
      R := R + S[I]; Inc(I);
    End;
  End;
  U8ToA := R;
End;

Function AToU8(S : String) : String;
Var R : String; I, C : LongInt;
Begin
  R := '';
  For I := 1 To Length(S) Do
  Begin
    C := Ord(S[I]);
    If C < 128 Then R := R + S[I]
    Else R := R + Chr($C0 Or (C Shr 6)) + Chr($80 Or (C And 63));
  End;
  AToU8 := R;
End;

Const
  B64C : String[64] =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

Function B64Enc(A : TlPtr; N : LongInt; Pad : Boolean) : String;
Var R : String; I, V, K : LongInt;
Begin
  R := ''; I := 0;
  While I < N Do
  Begin
    V := TlGet(A + I) Shl 16; K := 1;
    If I + 1 < N Then Begin V := V Or (TlGet(A + I + 1) Shl 8); Inc(K); End;
    If I + 2 < N Then Begin V := V Or TlGet(A + I + 2); Inc(K); End;
    R := R + B64C[((V Shr 18) And 63) + 1] + B64C[((V Shr 12) And 63) + 1];
    If K > 1 Then R := R + B64C[((V Shr 6) And 63) + 1]
    Else If Pad Then R := R + '=';
    If K > 2 Then R := R + B64C[(V And 63) + 1]
    Else If Pad Then R := R + '=';
    I := I + 3;
  End;
  B64Enc := R;
End;

{ decode S dans A ; nombre d'octets }
Function B64Dec(S : String; A : TlPtr) : LongInt;
Var I, V, N, K, C : LongInt;
Begin
  V := 0; N := 0; K := 0;
  For I := 1 To Length(S) Do
  Begin
    C := Pos(S[I], B64C) - 1;
    If C >= 0 Then
    Begin
      V := (V Shl 6) Or C; Inc(K);
      If K = 4 Then
      Begin
        TlPut(A + N, V Shr 16); TlPut(A + N + 1, V Shr 8);
        TlPut(A + N + 2, V); N := N + 3; K := 0; V := 0;
      End;
    End;
  End;
  If K = 2 Then Begin TlPut(A + N, V Shr 4); N := N + 1; End;
  If K = 3 Then
  Begin
    TlPut(A + N, V Shr 10); TlPut(A + N + 1, V Shr 2); N := N + 2;
  End;
  B64Dec := N;
End;

Function StrB64Enc(S : String) : String;
Begin
  If S = '' Then StrB64Enc := ''
  Else StrB64Enc := B64Enc(TlPtr(@S[1]), Length(S), True);
End;

Function StrB64Dec(S : String) : String;
Var B : Array[0..255] Of Byte; N, I : LongInt; R : String;
Begin
  If Length(S) > 340 Then S := Copy(S, 1, 340);
  N := B64Dec(S, TlPtr(@B[0]));
  R := '';
  For I := 0 To N - 1 Do R := R + Chr(B[I]);
  StrB64Dec := R;
End;

{ chemins distants }
Function RJoin(D, N : String) : String;
Begin
  If (D <> '') And (D[Length(D)] = '/') Then RJoin := D + N
  Else RJoin := D + '/' + N;
End;

Function RParent(D : String) : String;
Var I : LongInt;
Begin
  If (D = '/') Or (D = '') Then
  Begin
    RParent := '/';
    Exit;
  End;
  If D[Length(D)] = '/' Then D := Copy(D, 1, Length(D) - 1);
  I := Length(D);
  While (I > 0) And (D[I] <> '/') Do Dec(I);
  If I <= 1 Then RParent := '/' Else RParent := Copy(D, 1, I - 1);
End;

Function MonthNum(S : String) : LongInt;
Var I : LongInt;
Const Ms : String[36] = 'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC';
Begin
  S := UpS(Copy(S, 1, 3));
  MonthNum := 0;
  For I := 0 To 11 Do
    If Copy(Ms, I * 3 + 1, 3) = S Then MonthNum := I + 1;
End;

Function PermStr(P : LongInt) : String;
Var S : String; I : LongInt;
Const Rwx : String[3] = 'rwx';
Begin
  Case (P Shr 12) And 15 Of
    4 : S := 'd';
    10 : S := 'l';
  Else
    S := '-';
  End;
  For I := 8 DownTo 0 Do
    If ((P Shr I) And 1) <> 0 Then S := S + Rwx[3 - (I Mod 3)]
    Else S := S + '-';
  PermStr := S;
End;

{ date Unix (secondes depuis 1970, UTC) -> AAAA-MM-JJ HH:MM }
Function UnixTime(T : Double) : String;
Var D, S, Y, M, Dm, Dy : LongInt;
Const Mo : Array[1..12] Of LongInt = (31, 28, 31, 30, 31, 30, 31, 31, 30,
  31, 30, 31);
Begin
  D := Trunc(T / 86400);
  S := Trunc(T - D * 86400.0);
  Y := 1970;
  Repeat
    If ((Y Mod 4 = 0) And (Y Mod 100 <> 0)) Or (Y Mod 400 = 0) Then Dy := 366
    Else Dy := 365;
    If D >= Dy Then Begin D := D - Dy; Inc(Y); End;
  Until D < Dy;
  M := 1;
  Repeat
    Dm := Mo[M];
    If (M = 2) And (Dy = 366) Then Dm := 29;
    If D >= Dm Then Begin D := D - Dm; Inc(M); End;
  Until (D < Dm) Or (M > 12);
  UnixTime := IStr(Y) + '-' + Pad2(M) + '-' + Pad2(D + 1) + ' ' +
              Pad2(S Div 3600) + ':' + Pad2((S Div 60) Mod 60);
End;

Function GetBE(A : TlPtr) : LongInt;
Begin
  GetBE := (TlGet(A) Shl 24) Or (TlGet(A + 1) Shl 16) Or
           (TlGet(A + 2) Shl 8) Or TlGet(A + 3);
End;

Procedure PutBE(A : TlPtr; V : LongInt);
Begin
  TlPut(A, V Shr 24); TlPut(A + 1, V Shr 16); TlPut(A + 2, V Shr 8);
  TlPut(A + 3, V);
End;

Procedure CopyB(Src, Dst : TlPtr; N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do TlPut(Dst + I, TlGet(Src + I));
End;

Function NetSendAll(S : LongInt; A : TlPtr; N : LongInt) : Boolean;
Var R : LongInt;
Begin
  NetSendAll := False;
  While N > 0 Do
  Begin
    R := NetSend(S, A, N);
    If R <= 0 Then Exit;
    A := A + R; N := N - R;
  End;
  NetSendAll := True;
End;

{ envoi complet ; False si la connexion est coupee }
Function SendAll(A : TlPtr; N : LongInt) : Boolean;
Var R : LongInt;
Begin
  SendAll := False;
  While N > 0 Do
  Begin
    R := NetSend(SsSock, A, N);
    If R <= 0 Then
    Begin
      SsLost := True;
      Exit;
    End;
    A := A + R; N := N - R;
  End;
  SendAll := True;
End;

Function RecvAll(A : TlPtr; N : LongInt) : Boolean;
Var R : LongInt;
Begin
  RecvAll := False;
  While N > 0 Do
  Begin
    R := NetRecv(SsSock, A, N);
    If R <= 0 Then
    Begin
      SsLost := True;
      Exit;
    End;
    A := A + R; N := N - R;
  End;
  RecvAll := True;
End;

{ ==================================================================== }
{ FTP                                                                  }
{ ==================================================================== }

{ ligne de la connexion de controle (sans CR LF) }
Function FtGetLine(Var S : String) : Boolean;
Var C, R : LongInt;
Begin
  FtGetLine := False;
  S := '';
  Repeat
    If FtRPos >= FtREnd Then
    Begin
      R := NetRecv(SsSock, TlPtr(@FtRb[0]), SizeOf(FtRb));
      If R <= 0 Then
      Begin
        SsLost := True;
        Exit;
      End;
      FtRPos := 0; FtREnd := R;
    End;
    C := FtRb[FtRPos]; Inc(FtRPos);
    If (C <> 10) And (C <> 13) And (Length(S) < 255) Then S := S + Chr(C);
  Until C = 10;
  FtGetLine := True;
End;

{ reponse complete (multi-lignes "123-" ... "123 ") ; code (0 : coupee) }
Function FtReply : LongInt;
Var S, Cd : String;
Begin
  FtReply := 0; FtCode := 0;
  If Not FtGetLine(S) Then
  Begin
    SsErr := 'La connexion a '#233't'#233' ferm'#233'e par le serveur.';
    Exit;
  End;
  If FtUtf8 Then S := U8ToA(S);
  LogMsg(LgReply, S);
  If (Length(S) >= 4) And (S[4] = '-') Then
  Begin
    Cd := Copy(S, 1, 3) + ' ';
    Repeat
      If Not FtGetLine(S) Then Exit;
      If FtUtf8 Then S := U8ToA(S);
      LogMsg(LgReply, S);
    Until Copy(S, 1, 4) = Cd;
  End;
  FtLine := S;
  FtCode := SVal(Copy(S, 1, 3));
  FtReply := FtCode;
End;

Function FtSend(S : String) : Boolean;
Var T : String;
Begin
  If Copy(S, 1, 5) = 'PASS ' Then LogMsg(LgCmd, 'PASS ****')
  Else LogMsg(LgCmd, S);
  If FtUtf8 Then T := AToU8(S) Else T := S;
  T := T + #13#10;
  FtSend := SendAll(TlPtr(@T[1]), Length(T));
End;

Function FtCmd(S : String) : LongInt;
Begin
  FtCmd := 0;
  If Not FtSend(S) Then
  Begin
    SsErr := 'Impossible d''envoyer la commande.';
    Exit;
  End;
  FtCmd := FtReply;
End;

{ connexion de donnees passive (EPSV, sinon PASV) ; socket ou -1 }
Function FtData : LongInt;
Var R, P, I, A1, A2, A3, A4, P1, P2 : LongInt; S, Ip, E : String;
Begin
  FtData := -1;
  P := 0; Ip := SsHost;
  If Not FtEpsvBad Then
  Begin
    R := FtCmd('EPSV');
    If R = 229 Then
    Begin
      I := Pos('(|||', FtLine);
      If I > 0 Then
      Begin
        S := Copy(FtLine, I + 4, 10);
        I := Pos('|', S);
        If I > 0 Then P := SVal(Copy(S, 1, I - 1));
      End;
    End
    Else If R = 0 Then Exit
    Else FtEpsvBad := True;
  End;
  If P = 0 Then
  Begin
    R := FtCmd('PASV');
    If R <> 227 Then
    Begin
      SsErr := 'Le serveur refuse le mode passif : ' + FtLine;
      Exit;
    End;
    S := FtLine;
    I := Pos('(', S);
    If I > 0 Then S := Copy(S, I + 1, 255)
    Else
    Begin
      I := 5;
      While (I <= Length(S)) And Not (S[I] In ['0'..'9']) Do Inc(I);
      S := Copy(S, I, 255);
    End;
    A1 := SVal(Copy(S, 1, Pos(',', S) - 1)); Delete(S, 1, Pos(',', S));
    A2 := SVal(Copy(S, 1, Pos(',', S) - 1)); Delete(S, 1, Pos(',', S));
    A3 := SVal(Copy(S, 1, Pos(',', S) - 1)); Delete(S, 1, Pos(',', S));
    A4 := SVal(Copy(S, 1, Pos(',', S) - 1)); Delete(S, 1, Pos(',', S));
    P1 := SVal(Copy(S, 1, Pos(',', S) - 1)); Delete(S, 1, Pos(',', S));
    I := 1;
    While (I <= Length(S)) And (S[I] In ['0'..'9']) Do Inc(I);
    P2 := SVal(Copy(S, 1, I - 1));
    P := P1 * 256 + P2;
    { adresse privee ou locale derriere un NAT : celle du serveur (comme
      FileZilla) }
    If (A1 = 10) Or (A1 = 127) Or (A1 = 0) Or ((A1 = 192) And (A2 = 168)) Or
       ((A1 = 172) And (A2 >= 16) And (A2 < 32)) Then Ip := SsHost
    Else Ip := IStr(A1) + '.' + IStr(A2) + '.' + IStr(A3) + '.' + IStr(A4);
  End;
  LogMsg(LgStatus, 'Connexion de donn'#233'es vers ' + Ip + ':' + IStr(P) +
         '...');
  R := NetOpen(Ip, P, E);
  If R < 0 Then
  Begin
    SsErr := E;
    Exit;
  End;
  FtData := R;
End;

{ lit tout le flux de donnees dans B (au plus Max octets) ; longueur }
Function FtReadData(D : LongInt; B : TlPtr; Max : LongInt) : LongInt;
Var N, R : LongInt;
Begin
  N := 0;
  Repeat
    If N >= Max Then Break;
    R := NetRecv(D, B + N, Max - N);
    If R > 0 Then N := N + R;
  Until R <= 0;
  FtReadData := N;
End;

{ analyse d'une ligne de LIST (Unix ou MS-DOS) ou MLSD }
Function FtParse(S : String; Var E : TEntry; Mlsd : Boolean) : Boolean;
Var F : Array[0..9] Of String; N, I, P, Yr, Mo : LongInt; T, Fact, V, Ys : String;
Begin
  FtParse := False;
  E.Name := ''; E.Size := 0; E.Dir := False; E.Link := False; E.Time := '';
  E.Perm := ''; E.Owner := '';
  If Mlsd Then
  Begin
    P := Pos('; ', S);
    If P = 0 Then Exit;
    E.Name := Copy(S, P + 2, 255);
    T := Copy(S, 1, P);
    While T <> '' Do
    Begin
      I := Pos(';', T);
      If I = 0 Then I := Length(T) + 1;
      Fact := Copy(T, 1, I - 1); Delete(T, 1, I);
      I := Pos('=', Fact);
      If I = 0 Then Continue;
      V := Copy(Fact, I + 1, 255); Fact := UpS(Copy(Fact, 1, I - 1));
      If Fact = 'TYPE' Then
      Begin
        V := UpS(V);
        If (V = 'CDIR') Or (V = 'PDIR') Then Exit;
        E.Dir := V = 'DIR';
      End
      Else If Fact = 'SIZE' Then E.Size := DVal(V)
      Else If Fact = 'MODIFY' Then
        E.Time := Copy(V, 1, 4) + '-' + Copy(V, 5, 2) + '-' + Copy(V, 7, 2) +
                  ' ' + Copy(V, 9, 2) + ':' + Copy(V, 11, 2)
      Else If Fact = 'UNIX.MODE' Then E.Perm := V
      Else If (Fact = 'UNIX.OWNER') Or (Fact = 'UNIX.OWNERNAME') Then
        E.Owner := V;
    End;
    FtParse := (E.Name <> '.') And (E.Name <> '..');
    Exit;
  End;
  { decoupage en champs (les 8 premiers), le reste est le nom }
  N := 0; T := S;
  While (N < 8) And (T <> '') Do
  Begin
    While (T <> '') And (T[1] = ' ') Do Delete(T, 1, 1);
    I := Pos(' ', T);
    If I = 0 Then I := Length(T) + 1;
    F[N] := Copy(T, 1, I - 1); Delete(T, 1, I);
    Inc(N);
  End;
  If N = 0 Then Exit;
  If (Length(F[0]) = 8) And (F[0][3] = '-') And (N >= 4) Then
  Begin
    { MS-DOS : 11-21-26  10:35PM  <DIR>  nom }
    E.Dir := F[2] = '<DIR>';
    If Not E.Dir Then E.Size := DVal(F[2]);
    Ys := Copy(F[0], 7, 2);
    If Length(Ys) = 2 Then
      If SVal(Ys) < 70 Then Ys := '20' + Ys Else Ys := '19' + Ys;
    T := F[1];
    I := SVal(Copy(T, 1, 2));
    If (Pos('PM', UpS(T)) > 0) And (I < 12) Then I := I + 12;
    If (Pos('AM', UpS(T)) > 0) And (I = 12) Then I := 0;
    E.Time := Ys + '-' + Copy(F[0], 1, 2) + '-' + Copy(F[0], 4, 2) + ' ' +
              Pad2(I) + ':' + Copy(T, 4, 2);
    { le nom suit le 3e champ (espaces compris) }
    T := S;
    For I := 1 To 3 Do
    Begin
      While (T <> '') And (T[1] = ' ') Do Delete(T, 1, 1);
      While (T <> '') And (T[1] <> ' ') Do Delete(T, 1, 1);
    End;
    While (T <> '') And (T[1] = ' ') Do Delete(T, 1, 1);
    E.Name := T;
    FtParse := E.Name <> '';
    Exit;
  End;
  { Unix : drwxr-xr-x 3 user group 4096 Nov 21 22:35 nom }
  If (N < 8) Or (Length(F[0]) < 10) Or Not (F[0][1] In ['-', 'd', 'l']) Then
    Exit;
  E.Perm := F[0];
  E.Dir := F[0][1] = 'd';
  E.Link := F[0][1] = 'l';
  E.Owner := F[2] + ' ' + F[3];
  E.Size := DVal(F[4]);
  I := MonthNum(F[5]);
  If Pos(':', F[7]) > 0 Then Ys := '' Else Ys := F[7];
  If Ys = '' Then
  Begin
    { annee absente (moins de 6 mois) : annee courante, ou la precedente
      si le mois est posterieur au mois courant }
    NowYM(Yr, Mo);
    If I > Mo Then Dec(Yr);
    E.Time := IStr(Yr) + '-' + Pad2(I) + '-' + Pad2(SVal(F[6])) + ' ' + F[7];
  End
  Else E.Time := Ys + '-' + Pad2(I) + '-' + Pad2(SVal(F[6]));
  E.Name := T;
  If E.Link And (Pos(' -> ', E.Name) > 0) Then
    E.Name := Copy(E.Name, 1, Pos(' -> ', E.Name) - 1);
  FtParse := (E.Name <> '') And (E.Name <> '.') And (E.Name <> '..');
End;

Function FtPwd : Boolean;
Var I, J : LongInt;
Begin
  FtPwd := False;
  If FtCmd('PWD') <> 257 Then Exit;
  I := Pos('"', FtLine);
  J := I + 1;
  While (J <= Length(FtLine)) And (FtLine[J] <> '"') Do Inc(J);
  If I > 0 Then SsCwd := Copy(FtLine, I + 1, J - I - 1);
  FtPwd := True;
End;

Function FtConnect : Boolean;
Var R : LongInt; S : String;
Begin
  FtConnect := False;
  FtRPos := 0; FtREnd := 0; FtUtf8 := False; FtMlsd := False;
  FtEpsvBad := False;
  If FtReply <> 220 Then
  Begin
    If SsErr = '' Then SsErr := 'R'#233'ponse inattendue du serveur : ' +
                                FtLine;
    Exit;
  End;
  If SsUser = '' Then
  Begin
    SsUser := 'anonymous'; SsPass := 'anonymous@';
  End;
  R := FtCmd('USER ' + SsUser);
  If R = 331 Then R := FtCmd('PASS ' + SsPass);
  If R <> 230 Then
  Begin
    If R = 530 Then
      SsErr := 'Identifiant ou mot de passe incorrect (' + FtLine + ').'
    Else If SsErr = '' Then SsErr := 'Connexion refus'#233'e : ' + FtLine;
    Exit;
  End;
  LogMsg(LgStatus, 'Connect'#233);
  { possibilites du serveur }
  If FtSend('FEAT') Then
  Begin
    If Not FtGetLine(S) Then Exit;
    LogMsg(LgReply, S);
    If Copy(S, 1, 4) = '211-' Then
      Repeat
        If Not FtGetLine(S) Then Exit;
        LogMsg(LgReply, S);
        If UpS(TrimS(S)) = 'UTF8' Then FtUtf8 := True;
        If Copy(UpS(TrimS(S)), 1, 4) = 'MLST' Then FtMlsd := True;
      Until Copy(S, 1, 4) = '211 ';
  End;
  If FtUtf8 Then
  Begin
    FtUtf8 := False;
    If FtCmd('OPTS UTF8 ON') = 200 Then FtUtf8 := True;
  End;
  If FtCmd('SYST') = 215 Then SsSys := Copy(FtLine, 5, 255);
  If FtCmd('TYPE I') = 0 Then Exit;
  If Not FtPwd Then SsCwd := '/';
  FtConnect := True;
End;

{ liste du dossier courant }
Function FtList(L : PEntArr; Var N : LongInt) : Boolean;
Var D, R, Len, I, St : LongInt; B : TlPtr; S : String; E : TEntry;
Begin
  FtList := False;
  N := 0;
  D := FtData;
  If D < 0 Then Exit;
  If FtMlsd Then R := FtCmd('MLSD') Else R := FtCmd('LIST');
  If (R <> 150) And (R <> 125) Then
  Begin
    NetClose(D);
    If R = 0 Then Exit;
    If FtMlsd And ((R = 500) Or (R = 502)) Then
    Begin
      FtMlsd := False;
      FtList := FtList(L, N);
      Exit;
    End;
    SsErr := 'Impossible de lister le dossier : ' + FtLine;
    Exit;
  End;
  If FtLBuf = 0 Then FtLBuf := TlNew(1048576);
  B := FtLBuf;
  Len := FtReadData(D, B, 1048576);
  NetClose(D);
  R := FtReply;
  If (R <> 226) And (R <> 250) Then
  Begin
    If SsErr = '' Then SsErr := FtLine;
    Exit;
  End;
  St := 0;
  For I := 0 To Len Do
    If (I = Len) Or (TlGet(B + I) = 10) Then
    Begin
      S := '';
      While (St < I) And (Length(S) < 255) Do
      Begin
        If TlGet(B + St) <> 13 Then S := S + Chr(TlGet(B + St));
        Inc(St);
      End;
      St := I + 1;
      If FtUtf8 Then S := U8ToA(S);
      If (S <> '') And (N < MaxEnt) And FtParse(S, E, FtMlsd) Then
      Begin
        L^[N] := E; Inc(N);
      End;
    End;
  LogMsg(LgStatus, 'Contenu du dossier "' + SsCwd + '" affich'#233' (' +
         IStr(N) + ' '#233'l'#233'ments).');
  FtList := True;
End;

{ transfert d'un fichier ; Down : telechargement }
Function FtXfer(Rem, Loc : String; Down : Boolean;
  Resume : Double) : Boolean;
Var D, R, H, N : LongInt; B : TlPtr; Ok : Boolean;
Begin
  FtXfer := False;
  If Down Then H := LfCreate(Loc, False) Else H := LfOpen(Loc);
  If H < 0 Then
  Begin
    SsErr := 'Impossible d''ouvrir le fichier local ' + Loc;
    Exit;
  End;
  D := FtData;
  If D < 0 Then
  Begin
    LfClose(H);
    Exit;
  End;
  If Down Then R := FtCmd('RETR ' + Rem) Else R := FtCmd('STOR ' + Rem);
  If (R <> 150) And (R <> 125) Then
  Begin
    NetClose(D); LfClose(H);
    If SsErr = '' Then SsErr := FtLine;
    Exit;
  End;
  If XBuf = 0 Then XBuf := TlNew(32768);
  B := XBuf;
  Ok := True;
  XfDone := 0;
  Repeat
    If Down Then
    Begin
      N := NetRecv(D, B, 32768);
      If N > 0 Then
        If Not LfWrite(H, B, N) Then
        Begin
          SsErr := 'Erreur d'''#233'criture du fichier local.';
          Ok := False; N := 0;
        End;
    End
    Else
    Begin
      N := LfRead(H, B, 32768);
      If N > 0 Then
        If Not NetSendAll(D, B, N) Then
        Begin
          SsErr := 'Envoi interrompu.';
          Ok := False; N := 0;
        End;
    End;
    If N > 0 Then
    Begin
      XfDone := XfDone + N;
      XferStep;
      If XfCancel Then
      Begin
        Ok := False; N := 0;
        SsErr := 'Transfert annul'#233' par l''utilisateur.';
      End;
    End;
  Until N <= 0;
  NetClose(D);
  LfClose(H);
  R := FtReply;
  If (R <> 226) And (R <> 250) And Ok Then
  Begin
    If SsErr = '' Then SsErr := FtLine;
    Ok := False;
  End;
  FtXfer := Ok;
End;

{ ==================================================================== }
{ SSH-2                                                                }
{ ==================================================================== }

Var
  ShPos : LongInt;                     { lecture dans la charge recue }
  ShOutLen : LongInt;                  { charge en construction }

Procedure PkStart(T : LongInt);
Begin
  ShOutLen := 0;
  TlPut(ShOut + 5, T); ShOutLen := 1;
End;

Procedure PkByte(V : LongInt);
Begin
  TlPut(ShOut + 5 + ShOutLen, V); Inc(ShOutLen);
End;

Procedure PkU32(V : LongInt);
Begin
  PutBE(ShOut + 5 + ShOutLen, V); ShOutLen := ShOutLen + 4;
End;

Procedure PkBytes(A : TlPtr; N : LongInt);
Begin
  CopyB(A, ShOut + 5 + ShOutLen, N); ShOutLen := ShOutLen + N;
End;

Procedure PkStr(S : String);
Begin
  PkU32(Length(S));
  If S <> '' Then PkBytes(TlPtr(@S[1]), Length(S));
End;

Procedure PkBin(A : TlPtr; N : LongInt);
Begin
  PkU32(N); PkBytes(A, N);
End;

{ chiffrement, MAC et envoi du paquet construit }
Function PkSend : Boolean;
Var Pad, Len, I : LongInt; Sq : Array[0..3] Of Byte;
    Mac : TlKey32;
Begin
  Pad := 16 - ((5 + ShOutLen) Mod 16);
  If Pad < 4 Then Pad := Pad + 16;
  Len := 1 + ShOutLen + Pad;
  PutBE(ShOut, Len);
  TlPut(ShOut + 4, Pad);
  TlRandom(ShOut + 5 + ShOutLen, Pad);
  Len := Len + 4;
  If ShEnc Then
  Begin
    PutBE(TlPtr(@Sq[0]), ShSeqC);
    TlHmac(TlPtr(@ShMacC[0]), 32, TlPtr(@Sq[0]), 4, ShOut, Len,
           TlPtr(@Mac[0]));
    AesCtr(ShAesC, ShCtrC, ShOut, Len);
    For I := 0 To 31 Do TlPut(ShOut + Len + I, Mac[I]);
    Len := Len + 32;
  End;
  ShSeqC := ShSeqC + 1;
  PkSend := SendAll(ShOut, Len);
End;

{ reception d'un paquet : type (0 : erreur) ; charge dans ShIn + 5 }
Function PkRecvRaw : LongInt;
Var Len, Pad, I : LongInt; Sq : Array[0..3] Of Byte; Mac : TlKey32;
Begin
  PkRecvRaw := 0;
  If ShEnc Then
  Begin
    If Not RecvAll(ShIn, 16) Then Exit;
    AesCtr(ShAesS, ShCtrS, ShIn, 16);
  End
  Else If Not RecvAll(ShIn, 4) Then Exit;
  Len := GetBE(ShIn);
  If (Len < 5) Or (Len > SshMax) Then
  Begin
    SsErr := 'Paquet SSH invalide (longueur ' + IStr(Len) + ').';
    Exit;
  End;
  If ShEnc Then
  Begin
    If ((Len + 4) Mod 16) <> 0 Then
    Begin
      SsErr := 'Paquet SSH mal align'#233'.';
      Exit;
    End;
    If Not RecvAll(ShIn + 16, Len + 4 - 16) Then Exit;
    AesCtr(ShAesS, ShCtrS, ShIn + 16, Len + 4 - 16);
    If Not RecvAll(ShIn + Len + 4, 32) Then Exit;
    PutBE(TlPtr(@Sq[0]), ShSeqS);
    TlHmac(TlPtr(@ShMacS[0]), 32, TlPtr(@Sq[0]), 4, ShIn, Len + 4,
           TlPtr(@Mac[0]));
    For I := 0 To 31 Do
      If Mac[I] <> TlGet(ShIn + Len + 4 + I) Then
      Begin
        SsErr := 'Code d''authentification (MAC) incorrect.';
        Exit;
      End;
  End
  Else If Not RecvAll(ShIn + 4, Len) Then Exit;
  ShSeqS := ShSeqS + 1;
  Pad := TlGet(ShIn + 4);
  ShInLen := Len - 1 - Pad;
  If ShInLen < 1 Then Exit;
  ShPos := 1;
  PkRecvRaw := TlGet(ShIn + 5);
End;

Function RdU32 : LongInt;
Begin
  RdU32 := GetBE(ShIn + 5 + ShPos); ShPos := ShPos + 4;
End;

Function RdByte : LongInt;
Begin
  RdByte := TlGet(ShIn + 5 + ShPos); Inc(ShPos);
End;

{ chaine (255 caracteres au plus ; la suite est sautee) }
Function RdStr : String;
Var N, I : LongInt; S : String;
Begin
  N := RdU32;
  If (N < 0) Or (ShPos + N > ShInLen) Then N := ShInLen - ShPos;
  If N < 0 Then N := 0;
  S := '';
  For I := 0 To N - 1 Do
    If I < 255 Then S := S + Chr(TlGet(ShIn + 5 + ShPos + I));
  ShPos := ShPos + N;
  RdStr := S;
End;

{ chaine binaire : adresse et longueur dans la charge }
Procedure RdBin(Var A : TlPtr; Var N : LongInt);
Begin
  N := RdU32;
  If (N < 0) Or (ShPos + N > ShInLen) Then N := 0;
  A := ShIn + 5 + ShPos;
  ShPos := ShPos + N;
End;

{ paquet suivant, messages de service traites ; type }
Function PkRecv : LongInt;
Var T, R : LongInt; S : String;
Begin
  Repeat
    T := PkRecvRaw;
    If T = 0 Then
    Begin
      If SsErr = '' Then
        SsErr := 'La connexion a '#233't'#233' ferm'#233'e par le serveur.';
      PkRecv := 0;
      Exit;
    End;
    Case T Of
      1 :                                       { DISCONNECT }
      Begin
        R := RdU32; S := RdStr;
        SsErr := 'Le serveur a ferm'#233' la connexion : ' + S;
        PkRecv := 0;
        Exit;
      End;
      2, 4, 7 : T := -1;                        { IGNORE, DEBUG, EXT_INFO }
      3 : T := -1;                              { UNIMPLEMENTED }
      53 :                                      { USERAUTH_BANNER }
      Begin
        S := RdStr;
        LogMsg(LgReply, TrimS(U8ToA(S)));
        T := -1;
      End;
      80 :                                      { GLOBAL_REQUEST }
      Begin
        S := RdStr;
        If RdByte <> 0 Then
        Begin
          PkStart(82);
          If Not PkSend Then Begin PkRecv := 0; Exit; End;
        End;
        T := -1;
      End;
    End;
  Until T <> -1;
  PkRecv := T;
End;

{ ---- echange de cles ---- }

Function NameIn(Nm, List : String) : Boolean;
Begin
  NameIn := Pos(',' + Nm + ',', ',' + List + ',') > 0;
End;

{ Nm figure-t-il dans la liste brute (A, N) ? (les listes du serveur
  depassent souvent 255 caracteres) }
Function NameInRaw(Nm : String; A : TlPtr; N : LongInt) : Boolean;
Var I, J, St : LongInt; Ok : Boolean;
Begin
  NameInRaw := False;
  St := 0;
  For I := 0 To N Do
    If (I = N) Or (TlGet(A + I) = Ord(',')) Then
    Begin
      If I - St = Length(Nm) Then
      Begin
        Ok := True;
        For J := 1 To Length(Nm) Do
          If TlGet(A + St + J - 1) <> Ord(Nm[J]) Then Ok := False;
        If Ok Then
        Begin
          NameInRaw := True;
          Exit;
        End;
      End;
      St := I + 1;
    End;
End;

Function ChooseRaw(Mine : String; A : TlPtr; N : LongInt) : String;
Var T, Nm : String; I : LongInt;
Begin
  ChooseRaw := '';
  T := Mine;
  While T <> '' Do
  Begin
    I := Pos(',', T);
    If I = 0 Then I := Length(T) + 1;
    Nm := Copy(T, 1, I - 1); Delete(T, 1, I);
    If NameInRaw(Nm, A, N) Then
    Begin
      ChooseRaw := Nm;
      Exit;
    End;
  End;
End;

{ premier algorithme du client propose par le serveur }
Function Choose(Mine, Theirs : String) : String;
Var T, A : String; I : LongInt;
Begin
  Choose := '';
  T := Mine;
  While T <> '' Do
  Begin
    I := Pos(',', T);
    If I = 0 Then I := Length(T) + 1;
    A := Copy(T, 1, I - 1); Delete(T, 1, I);
    If NameIn(A, Theirs) Then
    Begin
      Choose := A;
      Exit;
    End;
  End;
End;

{ mpint d'un entier gros-boutiste (sans signe) a ajouter au hachage }
Procedure HashMpint(Var C : TlSha; A : TlPtr; N : LongInt);
Var L : Array[0..3] Of Byte; Z : Byte;
Begin
  While (N > 0) And (TlGet(A) = 0) Do Begin Inc(A); Dec(N); End;
  If (N > 0) And (TlGet(A) >= $80) Then
  Begin
    PutBE(TlPtr(@L[0]), N + 1); TlShaAdd(C, TlPtr(@L[0]), 4);
    Z := 0; TlShaAdd(C, TlPtr(@Z), 1);
  End
  Else
  Begin
    PutBE(TlPtr(@L[0]), N); TlShaAdd(C, TlPtr(@L[0]), 4);
  End;
  If N > 0 Then TlShaAdd(C, A, N);
End;

Procedure HashStr(Var C : TlSha; A : TlPtr; N : LongInt);
Var L : Array[0..3] Of Byte;
Begin
  PutBE(TlPtr(@L[0]), N);
  TlShaAdd(C, TlPtr(@L[0]), 4);
  If N > 0 Then TlShaAdd(C, A, N);
End;

{ cle derivee : SHA256(K || H || X || session_id) }
Procedure KeyDerive(Var Kc : TlSha; Var H : TlKey32; X : Char;
  Var Out0 : TlKey32);
Var C : TlSha; B : Byte;
Begin
  C := Kc;
  TlShaAdd(C, TlPtr(@H[0]), 32);
  B := Ord(X); TlShaAdd(C, TlPtr(@B), 1);
  TlShaAdd(C, TlPtr(@ShSid[0]), 32);
  TlShaDone(C, TlPtr(@Out0[0]));
End;

Function ShKex : Boolean;
Const
  MyKex = 'curve25519-sha256,curve25519-sha256@libssh.org';
  MyHk = 'ssh-ed25519,rsa-sha2-512,rsa-sha2-256';
  MyEnc = 'aes128-ctr';
  MyMac = 'hmac-sha2-256';
Var Ic, Is : TlPtr; IcN, IsN, T, I, N, KsN, QsN, SigN, SbN, EN, NN : LongInt;
    Ks, Qs, Sig, Sb, A, Eb, Nb : TlPtr;
    Lists : Array[0..9] Of String; S, Alg, SAlg, Fp, Key, Old : String;
    Priv, Pub, Base, Shared, H, H2, K : TlKey32;
    H5 : T64; C, Kc : TlSha; C5 : TS5; Ok : Boolean; Kb : TlBlk;
    La : Array[0..9] Of TlPtr; Ln : Array[0..9] Of LongInt;
Begin
  ShKex := False;
  { notre KEXINIT }
  PkStart(20);
  TlRandom(ShOut + 5 + ShOutLen, 16); ShOutLen := ShOutLen + 16;
  PkStr(MyKex + ',kex-strict-c-v00@openssh.com');
  PkStr(MyHk);
  PkStr(MyEnc); PkStr(MyEnc); PkStr(MyMac); PkStr(MyMac);
  PkStr('none'); PkStr('none'); PkStr(''); PkStr('');
  PkByte(0); PkU32(0);
  IcN := ShOutLen;
  If KxIc = 0 Then Begin KxIc := TlNew(4096); KxIs := TlNew(SshMax); End;
  If IcN > 4096 Then Exit;
  Ic := KxIc;
  CopyB(ShOut + 5, Ic, IcN);
  If Not PkSend Then Exit;
  T := PkRecv;
  If T <> 20 Then
  Begin
    If SsErr = '' Then SsErr := 'KEXINIT attendu (re'#231'u ' + IStr(T) + ').';
    Exit;
  End;
  IsN := ShInLen;
  Is := KxIs;
  CopyB(ShIn + 5, Is, IsN);
  ShPos := 17;
  For I := 0 To 9 Do
  Begin
    RdBin(La[I], Ln[I]);
    Lists[I] := '';
    For N := 0 To Ln[I] - 1 Do
      If N < 200 Then Lists[I] := Lists[I] + Chr(TlGet(La[I] + N));
    If Ln[I] > 200 Then Lists[I] := Lists[I] + '...';
  End;
  ShStrict := NameInRaw('kex-strict-s-v00@openssh.com', La[0], Ln[0]);
  If ChooseRaw(MyKex, La[0], Ln[0]) = '' Then
  Begin
    SsErr := 'Aucun '#233'change de cl'#233's commun (le serveur propose : ' +
             Lists[0] + ').';
    Exit;
  End;
  Alg := ChooseRaw(MyHk, La[1], Ln[1]);
  If Alg = '' Then
  Begin
    SsErr := 'Aucun type de cl'#233' d''h'#244'te commun (serveur : ' +
             Lists[1] + ').';
    Exit;
  End;
  If (ChooseRaw(MyEnc, La[2], Ln[2]) = '') Or
     (ChooseRaw(MyEnc, La[3], Ln[3]) = '') Or
     (ChooseRaw(MyMac, La[4], Ln[4]) = '') Or
     (ChooseRaw(MyMac, La[5], Ln[5]) = '') Then
  Begin
    SsErr := 'Le serveur n''accepte pas aes128-ctr et hmac-sha2-256.';
    Exit;
  End;
  LogMsg(LgStatus, 'Algorithmes : curve25519-sha256, ' + Alg +
         ', aes128-ctr, hmac-sha2-256');
  { ECDH }
  TlRandom(TlPtr(@Priv[0]), 32);
  For I := 0 To 31 Do Base[I] := 0;
  Base[0] := 9;
  TlX25519(Pub, Priv, Base);
  PkStart(30);
  PkBin(TlPtr(@Pub[0]), 32);
  If Not PkSend Then Exit;
  T := PkRecv;
  If T <> 31 Then
  Begin
    If SsErr = '' Then SsErr := 'R'#233'ponse ECDH attendue.';
    Exit;
  End;
  RdBin(Ks, KsN); RdBin(Qs, QsN); RdBin(Sig, SigN);
  If QsN <> 32 Then
  Begin
    SsErr := 'Cl'#233' publique du serveur invalide.';
    Exit;
  End;
  For I := 0 To 31 Do K[I] := TlGet(Qs + I);
  TlX25519(Shared, Priv, K);
  { hachage de l'echange }
  TlShaInit(C);
  HashStr(C, TlPtr(@ShVc[1]), Length(ShVc));
  HashStr(C, TlPtr(@ShVs[1]), Length(ShVs));
  HashStr(C, Ic, IcN); HashStr(C, Is, IsN);
  HashStr(C, Ks, KsN);
  HashStr(C, TlPtr(@Pub[0]), 32); HashStr(C, Qs, 32);
  TlShaInit(Kc);
  HashMpint(Kc, TlPtr(@Shared[0]), 32);
  HashMpint(C, TlPtr(@Shared[0]), 32);
  TlShaDone(C, TlPtr(@H[0]));
  ShSid := H;
  { cle d'hote : empreinte, signature }
  TlShaInit(C);
  TlShaAdd(C, Ks, KsN);
  TlShaDone(C, TlPtr(@H2[0]));
  Fp := 'SHA256:' + B64Enc(TlPtr(@H2[0]), 32, False);
  LogMsg(LgStatus, 'Cl'#233' d''h'#244'te ' + Alg + ' : ' + Fp);
  { la signature : string alg, string sig }
  ShPos := 0;
  A := Sig;
  N := GetBE(A);
  SAlg := '';
  For I := 0 To N - 1 Do
    If I < 64 Then SAlg := SAlg + Chr(TlGet(A + 4 + I));
  SbN := GetBE(A + 4 + N); Sb := A + 8 + N;
  { cle : string type, puis ed25519 : string pub ; rsa : mpint e, n }
  N := GetBE(Ks);
  S := '';
  For I := 0 To N - 1 Do
    If I < 64 Then S := S + Chr(TlGet(Ks + 4 + I));
  Ok := False;
  If (S = 'ssh-ed25519') And (SAlg = 'ssh-ed25519') And (SbN = 64) Then
    Ok := Ed25519Verify(Ks + 8 + N, TlPtr(@H[0]), 32, Sb)
  Else If (S = 'ssh-rsa') And ((SAlg = 'rsa-sha2-256') Or
          (SAlg = 'rsa-sha2-512')) Then
  Begin
    EN := GetBE(Ks + 4 + N); Eb := Ks + 8 + N;
    NN := GetBE(Eb + EN); Nb := Eb + EN + 4;
    If SAlg = 'rsa-sha2-256' Then
    Begin
      TlShaInit(C); TlShaAdd(C, TlPtr(@H[0]), 32);
      TlShaDone(C, TlPtr(@H5[0]));
      Ok := RsaVerify(Nb, NN, Eb, EN, Sb, SbN, TlPtr(@H5[0]), 32);
    End
    Else
    Begin
      S5Init(C5); S5Add(C5, TlPtr(@H[0]), 32);
      S5Done(C5, TlPtr(@H5[0]));
      Ok := RsaVerify(Nb, NN, Eb, EN, Sb, SbN, TlPtr(@H5[0]), 64);
    End;
  End;
  If Not Ok Then
  Begin
    SsErr := 'La signature de la cl'#233' d''h'#244'te est invalide.';
    Exit;
  End;
  { cle connue ? }
  Key := SsHost + ':' + IStr(SsPort);
  Old := KnownHost(Key);
  If Old <> Fp Then
  Begin
    I := HostAsk(Fp, Alg, Old <> '');
    If I = 0 Then
    Begin
      SsErr := 'Cl'#233' d''h'#244'te refus'#233'e.';
      Exit;
    End;
    If I = 2 Then SaveHost(Key, Fp);
  End;
  { NEWKEYS }
  PkStart(21);
  If Not PkSend Then Exit;
  T := PkRecv;
  If T <> 21 Then
  Begin
    If SsErr = '' Then SsErr := 'NEWKEYS attendu.';
    Exit;
  End;
  KeyDerive(Kc, H, 'A', K); For I := 0 To 15 Do ShCtrC[I] := K[I];
  KeyDerive(Kc, H, 'B', K); For I := 0 To 15 Do ShCtrS[I] := K[I];
  KeyDerive(Kc, H, 'C', K);
  For I := 0 To 15 Do Kb[I] := K[I];
  TlAesKey(ShAesC, Kb);
  KeyDerive(Kc, H, 'D', K);
  For I := 0 To 15 Do Kb[I] := K[I];
  TlAesKey(ShAesS, Kb);
  KeyDerive(Kc, H, 'E', ShMacC);
  KeyDerive(Kc, H, 'F', ShMacS);
  ShEnc := True;
  If ShStrict Then
  Begin
    ShSeqC := 0; ShSeqS := 0;
  End;
  ShKex := True;
End;

{ ---- authentification ---- }

Function ShAuth : Boolean;
Var T, N, I : LongInt; S, Methods : String; Tried : Boolean;
Begin
  ShAuth := False;
  PkStart(5); PkStr('ssh-userauth');
  If Not PkSend Then Exit;
  T := PkRecv;
  If T <> 6 Then
  Begin
    If SsErr = '' Then SsErr := 'Service d''authentification refus'#233'.';
    Exit;
  End;
  PkStart(50); PkStr(AToU8(SsUser)); PkStr('ssh-connection');
  PkStr('password'); PkByte(0); PkStr(AToU8(SsPass));
  If Not PkSend Then Exit;
  T := PkRecv;
  If T = 52 Then
  Begin
    ShAuth := True;
    Exit;
  End;
  If T <> 51 Then
  Begin
    If SsErr = '' Then SsErr := 'R'#233'ponse d''authentification inattendue.';
    Exit;
  End;
  Methods := RdStr;
  If Not NameIn('keyboard-interactive', Methods) Then
  Begin
    If NameIn('password', Methods) Then
      SsErr := 'Identifiant ou mot de passe incorrect.'
    Else
      SsErr := 'Le serveur n''accepte pas le mot de passe (m'#233'thodes : ' +
               Methods + ').';
    Exit;
  End;
  { clavier interactif : le mot de passe repond a chaque question }
  PkStart(50); PkStr(AToU8(SsUser)); PkStr('ssh-connection');
  PkStr('keyboard-interactive'); PkStr(''); PkStr('');
  If Not PkSend Then Exit;
  Tried := False;
  Repeat
    T := PkRecv;
    If T = 60 Then
    Begin
      S := RdStr; S := RdStr; S := RdStr;
      N := RdU32;
      If (N > 0) And Tried Then
      Begin
        SsErr := 'Identifiant ou mot de passe incorrect.';
        Exit;
      End;
      PkStart(61); PkU32(N);
      For I := 1 To N Do PkStr(AToU8(SsPass));
      If N > 0 Then Tried := True;
      If Not PkSend Then Exit;
    End;
  Until T <> 60;
  If T = 52 Then ShAuth := True
  Else If SsErr = '' Then SsErr := 'Identifiant ou mot de passe incorrect.';
End;

{ ---- canal "session" et sous-systeme sftp ---- }

Function ShChannel : Boolean;
Var T : LongInt; S : String;
Begin
  ShChannel := False;
  ShLWin := 2097152;
  PkStart(90); PkStr('session'); PkU32(0); PkU32(ShLWin); PkU32(32768);
  If Not PkSend Then Exit;
  T := PkRecv;
  If T <> 91 Then
  Begin
    If SsErr = '' Then SsErr := 'Ouverture du canal refus'#233'e.';
    Exit;
  End;
  T := RdU32; ShChan := RdU32; ShRWin := RdU32; ShRMax := RdU32;
  If ShRMax > 32768 Then ShRMax := 32768;
  PkStart(98); PkU32(ShChan); PkStr('subsystem'); PkByte(1); PkStr('sftp');
  If Not PkSend Then Exit;
  Repeat
    T := PkRecv;
    If T = 93 Then
    Begin
      T := RdU32; ShRWin := ShRWin + RdU32;
      T := 93;
    End;
  Until T <> 93;
  If T <> 99 Then
  Begin
    If SsErr = '' Then
      SsErr := 'Le serveur n''offre pas le sous-syst'#232'me SFTP.';
    Exit;
  End;
  ShChannel := True;
End;

{ donnees du canal recues dans SfBuf ; False si erreur }
Function ShPump : Boolean;
Var T, A, N, R : LongInt; P : TlPtr; S : String;
Begin
  ShPump := False;
  T := PkRecv;
  Case T Of
    0 : Exit;
    93 : Begin R := RdU32; ShRWin := ShRWin + RdU32; End;
    94, 95 :
    Begin
      R := RdU32;
      If T = 95 Then R := RdU32;
      RdBin(P, N);
      If T = 94 Then
      Begin
        If SfLen + N > SfMax Then
        Begin
          SsErr := 'Flux SFTP trop grand.';
          Exit;
        End;
        CopyB(P, SfBuf + SfLen, N);
        SfLen := SfLen + N;
      End;
      ShLWin := ShLWin - N;
      If ShLWin < 1048576 Then
      Begin
        PkStart(93); PkU32(ShChan); PkU32(2097152 - ShLWin);
        ShLWin := 2097152;
        If Not PkSend Then Exit;
      End;
    End;
    96, 97 :
    Begin
      SsErr := 'Le serveur a ferm'#233' le canal SFTP.';
      Exit;
    End;
    98 :
    Begin
      R := RdU32; S := RdStr;
      If RdByte <> 0 Then
      Begin
        PkStart(100); PkU32(ShChan);
        If Not PkSend Then Exit;
      End;
    End;
  End;
  ShPump := True;
End;

{ envoi de N octets sur le canal (fenetre et taille de paquet) }
Function ShWrite(A : TlPtr; N : LongInt) : Boolean;
Var K : LongInt;
Begin
  ShWrite := False;
  While N > 0 Do
  Begin
    While ShRWin <= 0 Do
      If Not ShPump Then Exit;
    K := N;
    If K > ShRMax Then K := ShRMax;
    If K > ShRWin Then K := ShRWin;
    PkStart(94); PkU32(ShChan); PkBin(A, K);
    If Not PkSend Then Exit;
    ShRWin := ShRWin - K;
    A := A + K; N := N - K;
  End;
  ShWrite := True;
End;

{ ==================================================================== }
{ SFTP version 3                                                       }
{ ==================================================================== }

Type
  THnd = Record                         { handle SFTP (octets bruts) }
    N : LongInt;
    B : Array[0..255] Of Byte;
  End;

Var
  SqB : TlPtr;                          { requete en construction }
  SqLen : LongInt;
  SpPos : LongInt;                      { lecture dans SfPk }

Procedure SqStart(T : LongInt; WithId : Boolean);
Begin
  SqLen := 4;
  TlPut(SqB + 4, T); SqLen := 5;
  If WithId Then
  Begin
    Inc(SfId);
    PutBE(SqB + SqLen, SfId); SqLen := SqLen + 4;
  End;
End;

Procedure SqU32(V : LongInt);
Begin
  PutBE(SqB + SqLen, V); SqLen := SqLen + 4;
End;

Procedure SqU64(V : Double);
Var H, L : LongInt;
Begin
  H := Trunc(V / 4294967296.0);
  V := V - H * 4294967296.0;
  If V >= 2147483648.0 Then L := Trunc(V - 4294967296.0) Else L := Trunc(V);
  SqU32(H); SqU32(L);
End;

Procedure SqBin(A : TlPtr; N : LongInt);
Begin
  SqU32(N); CopyB(A, SqB + SqLen, N); SqLen := SqLen + N;
End;

Procedure SqStr(S : String);
Begin
  SqU32(Length(S));
  If S <> '' Then CopyB(TlPtr(@S[1]), SqB + SqLen, Length(S));
  SqLen := SqLen + Length(S);
End;

Procedure SqHnd(Var H : THnd);
Begin
  SqBin(TlPtr(@H.B[0]), H.N);
End;

Function SqSend : Boolean;
Begin
  PutBE(SqB, SqLen - 4);
  SqSend := ShWrite(SqB, SqLen);
End;

{ paquet SFTP suivant dans SfPk (type ; 0 : erreur) }
Function SfRecv : LongInt;
Var N : LongInt;
Begin
  SfRecv := 0;
  While SfLen < 4 Do
    If Not ShPump Then Exit;
  N := GetBE(SfBuf);
  If (N < 1) Or (N > SfMax - 8) Then
  Begin
    SsErr := 'Paquet SFTP invalide.';
    Exit;
  End;
  While SfLen < N + 4 Do
    If Not ShPump Then Exit;
  CopyB(SfBuf + 4, SfPk, N);
  SfPkLen := N;
  CopyB(SfBuf + 4 + N, SfBuf, SfLen - 4 - N);
  SfLen := SfLen - 4 - N;
  SpPos := 1;
  SfRecv := TlGet(SfPk);
End;

Function SpU32 : LongInt;
Begin
  SpU32 := GetBE(SfPk + SpPos); SpPos := SpPos + 4;
End;

Function SpStr : String;
Var N, I : LongInt; S : String;
Begin
  N := SpU32;
  If (N < 0) Or (SpPos + N > SfPkLen) Then N := SfPkLen - SpPos;
  If N < 0 Then N := 0;
  S := '';
  For I := 0 To N - 1 Do
    If I < 255 Then S := S + Chr(TlGet(SfPk + SpPos + I));
  SpPos := SpPos + N;
  SpStr := S;
End;

Function SpU64 : Double;
Var H, L : LongInt; V : Double;
Begin
  H := SpU32; L := SpU32;
  V := L;
  If L < 0 Then V := V + 4294967296.0;
  SpU64 := H * 4294967296.0 + V;
End;

Procedure SpHnd(Var H : THnd);
Var N, I : LongInt;
Begin
  N := SpU32;
  If (N < 0) Or (N > 256) Then N := 0;
  H.N := N;
  For I := 0 To N - 1 Do H.B[I] := TlGet(SfPk + SpPos + I);
  SpPos := SpPos + N;
End;

{ attributs : remplit E (taille, droits, date) }
Procedure SpAttrs(Var E : TEntry);
Var F, N, I : LongInt; S : String;
Begin
  F := SpU32;
  If (F And 1) <> 0 Then E.Size := SpU64;
  If (F And 2) <> 0 Then Begin I := SpU32; I := SpU32; End;
  If (F And 4) <> 0 Then
  Begin
    I := SpU32;
    E.Perm := PermStr(I);
    E.Dir := ((I Shr 12) And 15) = 4;
    E.Link := ((I Shr 12) And 15) = 10;
  End;
  If (F And 8) <> 0 Then
  Begin
    I := SpU32; I := SpU32;
    If I < 0 Then E.Time := UnixTime(I + 4294967296.0)
    Else E.Time := UnixTime(I);
  End;
  If (F And LongInt($80000000)) <> 0 Then
  Begin
    N := SpU32;
    For I := 1 To N Do Begin S := SpStr; S := SpStr; End;
  End;
End;

Function SfStatusText(C : LongInt) : String;
Begin
  Case C Of
    1 : SfStatusText := 'Fin de fichier';
    2 : SfStatusText := 'Fichier ou dossier introuvable';
    3 : SfStatusText := 'Permission refus'#233'e';
    4 : SfStatusText := #201'chec';
    5 : SfStatusText := 'Message incorrect';
    6 : SfStatusText := 'Pas de connexion';
    7 : SfStatusText := 'Connexion perdue';
    8 : SfStatusText := 'Op'#233'ration non prise en charge';
  Else
    SfStatusText := 'Erreur ' + IStr(C);
  End;
End;

{ reponse STATUS attendue : True si OK }
Function SfOk(What : String) : Boolean;
Var T, I : LongInt;
Begin
  SfOk := False;
  T := SfRecv;
  If T = 0 Then Exit;
  If T <> 101 Then
  Begin
    SsErr := What + ' : r'#233'ponse inattendue.';
    Exit;
  End;
  I := SpU32; SfStatus := SpU32; SfMsg := SpStr;
  If SfStatus <> 0 Then
  Begin
    SsErr := What + ' : ' + SfStatusText(SfStatus);
    If SfMsg <> '' Then SsErr := SsErr + ' (' + U8ToA(SfMsg) + ')';
    Exit;
  End;
  SfOk := True;
End;

{ HANDLE attendu }
Function SfHandle(What : String; Var H : THnd) : Boolean;
Var T, I : LongInt;
Begin
  SfHandle := False;
  T := SfRecv;
  If T = 102 Then
  Begin
    I := SpU32; SpHnd(H);
    SfHandle := True;
  End
  Else If T = 101 Then
  Begin
    I := SpU32; SfStatus := SpU32; SfMsg := SpStr;
    SsErr := What + ' : ' + SfStatusText(SfStatus);
  End
  Else If T <> 0 Then SsErr := What + ' : r'#233'ponse inattendue.';
End;

Function SfRealPath(P : String; Var R : String) : Boolean;
Var T, I : LongInt;
Begin
  SfRealPath := False;
  SqStart(16, True); SqStr(AToU8(P));
  If Not SqSend Then Exit;
  T := SfRecv;
  If T = 104 Then
  Begin
    I := SpU32; I := SpU32;
    R := U8ToA(SpStr);
    SfRealPath := True;
  End
  Else If T = 101 Then
  Begin
    I := SpU32; SfStatus := SpU32;
    SsErr := 'Dossier "' + P + '" : ' + SfStatusText(SfStatus);
  End;
End;

Function ShConnect : Boolean;
Var Line : String; C, I, T : LongInt; S : String;
Begin
  ShConnect := False;
  ShEnc := False; ShSeqC := 0; ShSeqS := 0; SfLen := 0; SfId := 0;
  If ShOut = 0 Then
  Begin
    ShOut := TlNew(SshMax + 128); ShIn := TlNew(SshMax + 128);
    SfBuf := TlNew(SfMax + 16); SfPk := TlNew(SfMax + 16);
    SqB := TlNew(SshMax + 64);
  End;
  ShVc := 'SSH-2.0-PasdowsFTP_1.0';
  S := ShVc + #13#10;
  If Not SendAll(TlPtr(@S[1]), Length(S)) Then Exit;
  { version du serveur (les lignes precedentes sont ignorees) }
  Repeat
    Line := '';
    Repeat
      If Not RecvAll(TlPtr(@C), 1) Then
      Begin
        SsErr := 'Pas de r'#233'ponse SSH du serveur.';
        Exit;
      End;
      C := C And 255;
      If (C <> 13) And (C <> 10) And (Length(Line) < 255) Then
        Line := Line + Chr(C);
    Until C = 10;
  Until Copy(Line, 1, 4) = 'SSH-';
  ShVs := Line;
  LogMsg(LgReply, Line);
  If (Copy(Line, 1, 8) <> 'SSH-2.0-') And (Copy(Line, 1, 9) <> 'SSH-1.99-')
  Then
  Begin
    SsErr := 'Version de SSH non prise en charge : ' + Line;
    Exit;
  End;
  If Not ShKex Then Exit;
  LogMsg(LgStatus, 'Authentification de ' + SsUser + '...');
  If Not ShAuth Then Exit;
  LogMsg(LgStatus, 'Authentifi'#233' ; ouverture de la session SFTP...');
  If Not ShChannel Then Exit;
  SqStart(1, False); SqU32(3);
  If Not SqSend Then Exit;
  T := SfRecv;
  If T <> 2 Then
  Begin
    If SsErr = '' Then SsErr := 'R'#233'ponse SFTP inattendue.';
    Exit;
  End;
  LogMsg(LgStatus, 'SFTP version ' + IStr(SpU32));
  If Not SfRealPath('.', SsCwd) Then Exit;
  ShConnect := True;
End;

Function SfList(L : PEntArr; Var N : LongInt) : Boolean;
Var H : THnd; Nm, Ln : String; T, I, K, Cnt, P : LongInt; E : TEntry;
Begin
  SfList := False;
  N := 0;
  SqStart(11, True); SqStr(AToU8(SsCwd));
  If Not SqSend Then Exit;
  If Not SfHandle('Dossier ' + SsCwd, H) Then Exit;
  Repeat
    SqStart(12, True); SqHnd(H);
    If Not SqSend Then Exit;
    T := SfRecv;
    If T = 104 Then
    Begin
      I := SpU32; Cnt := SpU32;
      For K := 1 To Cnt Do
      Begin
        Nm := U8ToA(SpStr); Ln := SpStr;
        E.Name := Nm; E.Size := 0; E.Dir := False; E.Link := False;
        E.Time := ''; E.Perm := ''; E.Owner := '';
        SpAttrs(E);
        { proprietaire et groupe : 3e et 4e champs de longname }
        For I := 1 To 2 Do
        Begin
          While (Ln <> '') And (Ln[1] <> ' ') Do Delete(Ln, 1, 1);
          While (Ln <> '') And (Ln[1] = ' ') Do Delete(Ln, 1, 1);
        End;
        P := Pos(' ', Ln);
        If P > 0 Then
        Begin
          E.Owner := Copy(Ln, 1, P - 1);
          Delete(Ln, 1, P);
          While (Ln <> '') And (Ln[1] = ' ') Do Delete(Ln, 1, 1);
          P := Pos(' ', Ln);
          If P > 0 Then E.Owner := E.Owner + ' ' + Copy(Ln, 1, P - 1);
        End;
        If (Nm <> '.') And (Nm <> '..') And (N < MaxEnt) Then
        Begin
          L^[N] := E; Inc(N);
        End;
      End;
    End
    Else If T = 101 Then
    Begin
      I := SpU32; SfStatus := SpU32;
      If SfStatus <> 1 Then
      Begin
        SsErr := 'Lecture du dossier : ' + SfStatusText(SfStatus);
        Exit;
      End;
    End
    Else Exit;
  Until T <> 104;
  SqStart(4, True); SqHnd(H);
  If Not SqSend Then Exit;
  If Not SfOk('Fermeture') Then Exit;
  LogMsg(LgStatus, 'Contenu du dossier "' + SsCwd + '" affich'#233' (' +
         IStr(N) + ' '#233'l'#233'ments).');
  SfList := True;
End;

{ transfert SFTP : lectures ou ecritures de 32 Ko, 8 en vol }
Function SfXfer(Rem, Loc : String; Down : Boolean) : Boolean;
Const
  Chunk = 32768; Depth = 8;
Var H : THnd; F, T, I, N, Pend, Got : LongInt; Off, Sent : Double;
    B : TlPtr; Eof, Ok : Boolean; P : TlPtr;
Begin
  SfXfer := False;
  If Down Then F := LfCreate(Loc, False) Else F := LfOpen(Loc);
  If F < 0 Then
  Begin
    SsErr := 'Impossible d''ouvrir le fichier local ' + Loc;
    Exit;
  End;
  SqStart(3, True); SqStr(AToU8(Rem));
  If Down Then SqU32(1) Else SqU32(2 Or 8 Or $10);
  SqU32(0);
  If Not SqSend Then Begin LfClose(F); Exit; End;
  If Not SfHandle(Rem, H) Then Begin LfClose(F); Exit; End;
  If XBuf = 0 Then XBuf := TlNew(32768);
  B := XBuf;
  Off := 0; Sent := 0; Pend := 0; Eof := False; Ok := True;
  XfDone := 0;
  Repeat
    { requetes en vol }
    While Ok And Not Eof And (Pend < Depth) Do
    Begin
      If Down Then
      Begin
        SqStart(5, True); SqHnd(H); SqU64(Sent); SqU32(Chunk);
        Sent := Sent + Chunk;
      End
      Else
      Begin
        N := LfRead(F, B, Chunk);
        If N <= 0 Then
        Begin
          Eof := True;
          Break;
        End;
        SqStart(6, True); SqHnd(H); SqU64(Sent); SqBin(B, N);
        Sent := Sent + N;
      End;
      If Not SqSend Then
      Begin
        LfClose(F);
        Exit;
      End;
      Inc(Pend);
    End;
    If Pend = 0 Then Break;
    T := SfRecv;
    Dec(Pend);
    If T = 0 Then
    Begin
      LfClose(F);
      Exit;
    End;
    If Down And (T = 103) Then
    Begin
      I := SpU32; N := SpU32;
      P := SfPk + SpPos;
      If Ok Then
        If Not LfWrite(F, P, N) Then
        Begin
          SsErr := 'Erreur d'''#233'criture du fichier local.';
          Ok := False;
        End;
      Off := Off + N;
      XfDone := XfDone + N;
      If N < Chunk Then
      Begin
        { lecture courte : la suite est relue a partir d'ici }
        Eof := True;
        If Pend = 0 Then
        Begin
          Sent := Off;
          Eof := False;
        End;
      End;
    End
    Else If T = 101 Then
    Begin
      I := SpU32; SfStatus := SpU32; SfMsg := SpStr;
      If SfStatus = 1 Then Eof := True
      Else If SfStatus <> 0 Then
      Begin
        If Ok Then SsErr := Rem + ' : ' + SfStatusText(SfStatus);
        Ok := False;
      End
      Else If Not Down Then
      Begin
        Got := Chunk;
        If XfDone + Got > Sent Then XfDone := Sent Else XfDone := XfDone + Got;
      End;
    End
    Else
    Begin
      SsErr := 'R'#233'ponse SFTP inattendue (' + IStr(T) + ').';
      Ok := False;
    End;
    XferStep;
    If XfCancel And Ok Then
    Begin
      Ok := False;
      SsErr := 'Transfert annul'#233' par l''utilisateur.';
    End;
  Until (Pend = 0) And (Eof Or Not Ok);
  LfClose(F);
  SqStart(4, True); SqHnd(H);
  If Not SqSend Then Exit;
  If Not SfOk('Fermeture') Then Exit;
  SfXfer := Ok;
End;

{ ==================================================================== }
{ Operations de la session (FTP ou SFTP)                                }
{ ==================================================================== }

Procedure SsClose;
Begin
  If SsSock >= 0 Then
  Begin
    If SsOpen Then
      If SsLost Then
      Else If SsProto = PrFtp Then
      Begin
        If FtSend('QUIT') Then FtReply;
      End
      Else
      Begin
        PkStart(1); PkU32(11); PkStr('Fermeture'); PkStr('');
        If PkSend Then;
      End;
    NetClose(SsSock);
  End;
  SsSock := -1;
  SsOpen := False;
End;

Function SsConnect : Boolean;
Var E : String;
Begin
  SsConnect := False;
  SsErr := ''; SsSys := ''; SsLost := False;
  LogMsg(LgStatus, 'R'#233'solution de l''adresse de ' + SsHost + '...');
  SsSock := NetOpen(SsHost, SsPort, E);
  If SsSock < 0 Then
  Begin
    SsErr := E;
    Exit;
  End;
  LogMsg(LgStatus, 'Connexion '#233'tablie avec ' + SsHost + ':' +
         IStr(SsPort) + ', attente du message d''accueil...');
  If SsProto = PrFtp Then SsOpen := FtConnect Else SsOpen := ShConnect;
  If Not SsOpen Then
  Begin
    NetClose(SsSock); SsSock := -1;
    Exit;
  End;
  SsConnect := True;
End;

{ change de dossier (chemin absolu ou relatif) }
Function SsCd(P : String) : Boolean;
Var R : String; H : THnd; T : LongInt;
Begin
  SsCd := False;
  SsErr := '';
  If SsProto = PrFtp Then
  Begin
    If FtCmd('CWD ' + P) <> 250 Then
    Begin
      If SsErr = '' Then SsErr := 'Impossible d''ouvrir "' + P + '" : ' +
                                  FtLine;
      Exit;
    End;
    If Not FtPwd Then SsCwd := P;
  End
  Else
  Begin
    If (P <> '') And (P[1] <> '/') Then P := RJoin(SsCwd, P);
    If Not SfRealPath(P, R) Then Exit;
    { verifier que c'est un dossier lisible }
    SqStart(11, True); SqStr(AToU8(R));
    If Not SqSend Then Exit;
    If Not SfHandle('Dossier ' + R, H) Then Exit;
    SqStart(4, True); SqHnd(H);
    If Not SqSend Then Exit;
    If Not SfOk('Fermeture') Then Exit;
    SsCwd := R;
  End;
  SsCd := True;
End;

Function SsList(L : PEntArr; Var N : LongInt) : Boolean;
Begin
  SsErr := '';
  LogMsg(LgStatus, 'Lecture du contenu du dossier "' + SsCwd + '"...');
  If SsProto = PrFtp Then SsList := FtList(L, N)
  Else SsList := SfList(L, N);
End;

{ liste d'un autre dossier (le dossier courant est garde) }
Function SsListPath(P : String; L : PEntArr; Var N : LongInt) : Boolean;
Var Save : String;
Begin
  SsListPath := False;
  N := 0;
  Save := SsCwd;
  If SsProto = PrSftp Then
  Begin
    SsCwd := P;
    SsListPath := SsList(L, N);
    SsCwd := Save;
    Exit;
  End;
  If Not SsCd(P) Then Exit;
  SsListPath := SsList(L, N);
  If SsCd(Save) Then;
End;

{ commande FTP quelconque (Serveur, Entrer une commande) }
Function SsRaw(C : String) : Boolean;
Begin
  SsRaw := False;
  SsErr := '';
  If SsProto <> PrFtp Then
  Begin
    SsErr := 'Les commandes personnalis'#233'es ne sont possibles qu''en FTP.';
    Exit;
  End;
  SsRaw := FtCmd(C) <> 0;
End;

{ Op : 1 creer un dossier, 2 supprimer un dossier, 3 supprimer un fichier }
Function SsOp(Op : LongInt; P : String) : Boolean;
Var R : LongInt;
Begin
  SsOp := False;
  SsErr := '';
  If SsProto = PrFtp Then
  Begin
    Case Op Of
      1 : R := FtCmd('MKD ' + P);
      2 : R := FtCmd('RMD ' + P);
    Else
      R := FtCmd('DELE ' + P);
    End;
    If (R < 200) Or (R > 299) Then
    Begin
      If SsErr = '' Then SsErr := FtLine;
      Exit;
    End;
  End
  Else
  Begin
    Case Op Of
      1 : Begin SqStart(14, True); SqStr(AToU8(P)); SqU32(0); End;
      2 : Begin SqStart(15, True); SqStr(AToU8(P)); End;
    Else
      Begin SqStart(13, True); SqStr(AToU8(P)); End;
    End;
    If Not SqSend Then Exit;
    If Not SfOk(P) Then Exit;
  End;
  SsOp := True;
End;

Function SsRename(A, B : String) : Boolean;
Var R : LongInt;
Begin
  SsRename := False;
  SsErr := '';
  If SsProto = PrFtp Then
  Begin
    R := FtCmd('RNFR ' + A);
    If R = 350 Then R := FtCmd('RNTO ' + B);
    If (R < 200) Or (R > 299) Then
    Begin
      If SsErr = '' Then SsErr := FtLine;
      Exit;
    End;
  End
  Else
  Begin
    SqStart(18, True); SqStr(AToU8(A)); SqStr(AToU8(B));
    If Not SqSend Then Exit;
    If Not SfOk(A) Then Exit;
  End;
  SsRename := True;
End;

{ changement des droits (SFTP : SETSTAT ; FTP : SITE CHMOD) }
Function SsChmod(P : String; Mode : LongInt) : Boolean;
Var R : LongInt; S : String;
Begin
  SsChmod := False;
  SsErr := '';
  If SsProto = PrFtp Then
  Begin
    S := IStr((Mode Shr 6) And 7) + IStr((Mode Shr 3) And 7) +
         IStr(Mode And 7);
    R := FtCmd('SITE CHMOD ' + S + ' ' + P);
    If (R < 200) Or (R > 299) Then
    Begin
      If SsErr = '' Then SsErr := FtLine;
      Exit;
    End;
  End
  Else
  Begin
    SqStart(9, True); SqStr(AToU8(P)); SqU32(4); SqU32(Mode);
    If Not SqSend Then Exit;
    If Not SfOk(P) Then Exit;
  End;
  SsChmod := True;
End;

Function SsGet(Rem, Loc : String) : Boolean;
Begin
  SsErr := '';
  XfCancel := False;
  If SsProto = PrFtp Then SsGet := FtXfer(Rem, Loc, True, 0)
  Else SsGet := SfXfer(Rem, Loc, True);
End;

Function SsPut(Loc, Rem : String) : Boolean;
Begin
  SsErr := '';
  XfCancel := False;
  If SsProto = PrFtp Then SsPut := FtXfer(Rem, Loc, False, 0)
  Else SsPut := SfXfer(Rem, Loc, False);
End;
{ ==================================================================== }
{ ==================================================================== }
{ Reseau (TCPIP32) et fichiers locaux (DOSCALLS) pour les protocoles    }
{ Les appels bloquants liberent le verrou de l'interface (BigUnlock).   }
{ ==================================================================== }

Function sock_init : LongInt; External 'TCPIP32' Name 'sock_init';
Function socket(Af, Typ, Pr : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function connect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function send(S, B, N, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function recv(S, B, N, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function soclose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function shutdown(S, How : LongInt) : LongInt; External 'TCPIP32' Name 'shutdown';
Function gethostbyname(N : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
Function inet_addr(N : LongInt) : LongInt; External 'TCPIP32' Name 'inet_addr';

Var
  NetReady : Boolean;
  NetZ : Array[0..299] Of Byte;

Procedure BigUnlock; Forward;
Procedure BigLock; Forward;

Function GetLE(A : LongInt) : LongInt;
Begin
  GetLE := TlGet(A) Or (TlGet(A + 1) Shl 8) Or (TlGet(A + 2) Shl 16) Or
           (TlGet(A + 3) Shl 24);
End;

Procedure PutZ(A : LongInt; S : String);
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do TlPut(A + I - 1, Ord(S[I]));
  TlPut(A + Length(S), 0);
End;

{ millisecondes depuis le demarrage (QSV_MS_COUNT) }
Function MsCount : LongInt;
Var V : LongInt;
Begin
  V := 0;
  If DosQuerySysInfo(14, 14, LongInt(@V), 4) <> 0 Then V := 0;
  MsCount := V;
End;

{ annee et mois courants (DosGetDateTime) }
Procedure NowYM(Var Y, M : LongInt);
Var Dt : Array[0..11] Of Byte;
Begin
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy0 := DosGetDateTime(LongInt(@Dt));
  Y := Dt[6] Or (Dt[7] Shl 8); M := Dt[5];
End;

{ alea : compteur de millisecondes, date et heure, compteur de cycles
  (RDTSC) et adresse de la pile }
Procedure TlEntropy;
Var Dt : Array[0..11] Of Byte; Lo, Hi : LongInt;
Begin
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy0 := DosGetDateTime(LongInt(@Dt));
  Lo := 0; Hi := 0;
  asm
    db $0F, $31
    mov Lo,eax
    mov Hi,edx
  end;
  TlSeed(MsCount); TlSeed(Lo); TlSeed(Hi);
  TlSeed(GetLE(LongInt(@Dt)) Xor GetLE(LongInt(@Dt) + 4));
  TlSeed(LongInt(@Dt));
End;

Function NetOpen(Host : String; Port : LongInt; Var Err : String) : LongInt;
Var A : Array[0..15] Of Byte; S, IP, H, I, R : LongInt;
Begin
  NetOpen := -1;
  If Not NetReady Then
  Begin
    Dummy0 := sock_init;
    NetReady := True;
  End;
  PutZ(LongInt(@NetZ[0]), Host);
  IP := inet_addr(LongInt(@NetZ[0]));
  If (IP = -1) Or (IP = 0) Then
  Begin
    BigUnlock;
    H := gethostbyname(LongInt(@NetZ[0]));
    BigLock;
    If H = 0 Then
    Begin
      Err := 'Ordinateur introuvable : ' + Host;
      Exit;
    End;
    { hostent d'OS/2 : h_addr_list en +16 }
    IP := GetLE(GetLE(GetLE(H + 16)));
  End;
  S := socket(2, 1, 6);
  If S = -1 Then
  Begin
    Err := 'Impossible de cr'#233'er un socket.';
    Exit;
  End;
  For I := 0 To 15 Do A[I] := 0;
  A[0] := 16; A[1] := 2; A[2] := (Port Shr 8) And 255; A[3] := Port And 255;
  A[4] := IP And 255; A[5] := (IP Shr 8) And 255;
  A[6] := (IP Shr 16) And 255; A[7] := (IP Shr 24) And 255;
  BigUnlock;
  R := connect(S, LongInt(@A[0]), 16);
  BigLock;
  If R <> 0 Then
  Begin
    Err := 'Connexion refus'#233'e ou impossible : ' + Host + ':' + IStr(Port);
    Dummy0 := soclose(S);
    Exit;
  End;
  NetOpen := S;
End;

Function NetSend(S : LongInt; A : TlPtr; N : LongInt) : LongInt;
Begin
  BigUnlock;
  NetSend := send(S, A, N, 0);
  BigLock;
End;

Function NetRecv(S : LongInt; A : TlPtr; N : LongInt) : LongInt;
Begin
  BigUnlock;
  NetRecv := recv(S, A, N, 0);
  BigLock;
End;

Procedure NetClose(S : LongInt);
Begin
  Dummy0 := shutdown(S, 2);
  Dummy0 := soclose(S);
End;

{ fichiers locaux : DosOpen (lecture, partage permis) }
Function LfOpen(Name : String) : LongInt;
Var H, Act : LongInt;
Begin
  PutZ(LongInt(@NetZ[0]), Name);
  H := 0; Act := 0;
  If DosOpen(LongInt(@NetZ[0]), LongInt(@H), LongInt(@Act), 0, 0, $01, $40, 0) <> 0 Then H := -1;
  LfOpen := H;
End;

{ cree ou remplace (ecriture seule) }
Function LfCreate(Name : String; Append : Boolean) : LongInt;
Var H, Act : LongInt;
Begin
  PutZ(LongInt(@NetZ[0]), Name);
  H := 0; Act := 0;
  If DosOpen(LongInt(@NetZ[0]), LongInt(@H), LongInt(@Act), 0, 0, $12, $21, 0) <> 0 Then H := -1;
  LfCreate := H;
End;

Function LfRead(H : LongInt; A : TlPtr; N : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If DosRead(H, A, N, LongInt(@R)) <> 0 Then R := -1;
  LfRead := R;
End;

Function LfWrite(H : LongInt; A : TlPtr; N : LongInt) : Boolean;
Var R : LongInt;
Begin
  R := 0;
  LfWrite := (DosWrite(H, A, N, LongInt(@R)) = 0) And (R = N);
End;

Procedure LfClose(H : LongInt);
Begin
  Dummy0 := DosClose(H);
End;
{ ==================================================================== }
{ Utilitaires de l'interface (Presentation Manager)                     }
{ ==================================================================== }

Const
  CW = 8;                               { police de PM : 8 x 16 }
  RH = 16;                              { hauteur d'une ligne de liste }
  HH = 18;                              { en-tete des colonnes }

Var
  Hab, Hmq, MainWnd, MainFrame, Dummy, OemOut : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  Qmsg : Array[0..7] Of LongInt;
  LockSem : LongInt;                    { semaphore d'exclusion }
  LockOn : Boolean;
  AppDir, AppExeDir : String;
  ScrW, ScrH : LongInt;
  DcH : LongInt;                        { hauteur de la fenetre peinte }
  CtlKind : Array[0..255] Of Byte;      { 1 bouton, 2 saisie, 3 liste }

Var
  LockDepth : LongInt;                  { profondeur (fil qui le tient) }

Procedure BigLock;
Begin
  If Not LockOn Then Exit;
  Dummy0 := DosRequestMutexSem(LockSem, -1);
  Inc(LockDepth);
End;

Procedure BigUnlock;
Begin
  If Not LockOn Then Exit;
  Dec(LockDepth);
  Dummy0 := DosReleaseMutexSem(LockSem);
End;

{ libere entierement le verrou (attente d'une boite modale) }
Function LockDepthRelease : LongInt;
Var D, I : LongInt;
Begin
  D := LockDepth;
  For I := 1 To D Do BigUnlock;
  LockDepthRelease := D;
End;

Procedure LockDepthRestore(D : LongInt);
Var I : LongInt;
Begin
  For I := 1 To D Do BigLock;
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

Function GetZ(A : LongInt) : String;
Var S : String; P : PByt;
Begin
  S := '';
  P := PByt(A);
  While (P^ <> 0) And (Length(S) < 255) Do
  Begin
    S := S + Chr(P^);
    P := PByt(LongInt(P) + 1);
  End;
  GetZ := S;
End;

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
End;

Function S16(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V >= $8000 Then V := V - $10000;
  S16 := V;
End;

Function LoS(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'A') And (S[K] <= 'Z') Then S[K] := Chr(Ord(S[K]) + 32);
  LoS := S;
End;

{ ANSI (1252) -> page de codes 850 de l'ecran d'OS/2-0 (les lettres
  accentuees du francais ont les memes codes en 437 et en 850) }
Const
  AnsiOem : Array[128..255] Of Byte = (
    69, 63, 44, 102, 34, 46, 197, 206, 94, 63, 83, 60, 79, 63, 90, 63, 63,
    39, 39, 34, 34, 249, 45, 45, 126, 159, 115, 62, 111, 63, 122, 89, 255,
    173, 155, 156, 63, 157, 124, 21, 34, 169, 166, 174, 170, 45, 158, 196,
    248, 241, 253, 51, 39, 230, 20, 250, 44, 49, 167, 175, 172, 171, 63, 168,
    65, 65, 65, 65, 142, 143, 146, 128, 69, 144, 69, 69, 73, 73, 73, 73, 68,
    165, 79, 79, 79, 79, 153, 120, 79, 85, 85, 85, 154, 89, 63, 225, 133,
    160, 131, 97, 132, 134, 145, 135, 138, 130, 136, 137, 141, 161, 140, 139,
    63, 164, 149, 162, 147, 111, 148, 246, 111, 151, 163, 150, 129, 121, 63,
    152);

{ texte ANSI tel qu'il s'affiche (page 850) }
Function Disp(S : String) : String;
Var K : LongInt;
Begin
  If OemOut <> 0 Then
    For K := 1 To Length(S) Do
      If Ord(S[K]) >= 128 Then S[K] := Chr(AnsiOem[Ord(S[K])]);
  Disp := S;
End;

Function UnDisp(S : String) : String;
Var K, C : LongInt;
Begin
  If OemOut <> 0 Then
    For K := 1 To Length(S) Do
      If Ord(S[K]) >= 128 Then
        For C := 160 To 255 Do
          If AnsiOem[C] = Ord(S[K]) Then
          Begin
            S[K] := Chr(C);
            Break;
          End;
  UnDisp := S;
End;

{ l'ecran d'OS/2-0 est en page de codes 850 }
Procedure DetectOem;
Begin
  OemOut := 1;
End;

{ boite de message : drapeaux et resultats de Pasdows traduits pour
  WinMessageBox ; | = nouvelle ligne }
Function MbFlags(Fl : LongInt) : LongInt;
Var R : LongInt;
Begin
  Case Fl And 15 Of
    MB_OKCANCEL : R := PM_MB_OKCANCEL;
    MB_YESNOCANCEL : R := PM_MB_YESNOCANCEL;
    MB_YESNO : R := PM_MB_YESNO;
  Else
    R := PM_MB_OK;
  End;
  Case Fl And $F0 Of
    MB_ICONERROR : R := R Or PM_MB_ERROR;
    MB_ICONQUESTION : R := R Or PM_MB_QUERY;
    MB_ICONWARNING : R := R Or PM_MB_WARNING;
    MB_ICONINFO : R := R Or PM_MB_INFORMATION;
  End;
  MbFlags := R Or PM_MB_MOVEABLE;
End;

Function MsgBox(Own : LongInt; Text, Cap : String; Fl : LongInt) : LongInt;
Var A, B : Array[0..511] Of Byte; K : LongInt;
Begin
  Text := Disp(Text);
  For K := 1 To Length(Text) Do If Text[K] = '|' Then Text[K] := Chr(10);
  PutZ(LongInt(@A[0]), Text); PutZ(LongInt(@B[0]), Disp(Cap));
  MsgBox := WinMessageBox(HWND_DESKTOP, Own, LongInt(@A[0]), LongInt(@B[0]), 0, MbFlags(Fl));
End;

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Var D : LongInt;
Begin
  D := LockDepthRelease;
  Ask := MsgBox(MainFrame, Text, Cap, Fl);
  LockDepthRestore(D);
End;

{ couleur de Windows ($00BBGGRR) -> couleur de PM (palette de 16) }
Function PmClr(C : LongInt) : LongInt;
Const
  Pal : Array[0..15] Of LongInt = (0, $800000, $008000, $808000, $000080, $800080, $008080, $C0C0C0,
    $808080, $FF0000, $00FF00, $FFFF00, $0000FF, $FF00FF, $00FFFF, $FFFFFF);
  Idx : Array[0..15] Of LongInt = (CLR_BLACK, CLR_DARKBLUE, CLR_DARKGREEN, CLR_DARKCYAN, CLR_DARKRED, 11,
    CLR_BROWN, CLR_PALEGRAY, CLR_DARKGRAY, CLR_BLUE, CLR_GREEN, CLR_CYAN, CLR_RED, 3, CLR_YELLOW, CLR_WHITE);
Var I, B, D, Best, R1, G1, B1, R2, G2, B2 : LongInt;
Begin
  If C = $0000C0 Then
  Begin
    PmClr := CLR_RED;
    Exit;
  End;
  R1 := C And 255; G1 := (C Shr 8) And 255; B1 := (C Shr 16) And 255;
  Best := MaxLongInt; B := 0;
  For I := 0 To 15 Do
  Begin
    R2 := Pal[I] And 255; G2 := (Pal[I] Shr 8) And 255; B2 := (Pal[I] Shr 16) And 255;
    D := (R1 - R2) * (R1 - R2) + (G1 - G2) * (G1 - G2) + (B1 - B2) * (B1 - B2);
    If D < Best Then
    Begin
      Best := D; B := I;
    End;
  End;
  PmClr := Idx[B];
End;

{ dessin : coordonnees de Pasdows (Y vers le bas) dans la fenetre peinte
  de hauteur DcH ; Dc = espace de presentation de PM }
Procedure Bar(Dc, X1, Y1, X2, Y2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  Rc[0] := X1; Rc[1] := DcH - Y2; Rc[2] := X2; Rc[3] := DcH - Y1;
  Dummy0 := WinFillRect(Dc, LongInt(@Rc), PmClr(C));
End;

{ texte (police 8 x 16 de PM), fond transparent ; Y : haut de la cellule }
Procedure Txt(Dc, X, Y : LongInt; S : String; Fg : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), Disp(S));
  Dummy0 := GpiSetColor(Dc, PmClr(Fg));
  P[0] := X; P[1] := DcH - Y - 12;
  Dummy0 := GpiCharStringAt(Dc, LongInt(@P), Length(S), LongInt(@TxtBuf));
End;

{ debut et fin du dessin d'une fenetre }
Function PaintBegin(H : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  Dummy0 := WinQueryWindowRect(H, LongInt(@Rc));
  DcH := Rc[3] - Rc[1];
  PaintBegin := WinBeginPaint(H, 0, 0);
End;

Procedure PaintEnd(Dc : LongInt);
Begin
  Dummy0 := WinEndPaint(Dc);
End;

{ S coupe pour tenir dans W points (... a la fin) }
Function Fit(S : String; W : LongInt) : String;
Var N : LongInt;
Begin
  N := W Div CW;
  If N < 1 Then
  Begin
    Fit := '';
    Exit;
  End;
  If Length(S) > N Then
  Begin
    If N > 3 Then S := Copy(S, 1, N - 3) + '...' Else S := Copy(S, 1, N);
  End;
  Fit := S;
End;

{ cadre en relief (X2, Y2 exclus) : Up bouton, sinon creux }
Procedure Bevel(Dc, X1, Y1, X2, Y2 : LongInt; Up : Boolean);
Var L, D : LongInt;
Begin
  If Up Then Begin L := ClrHi; D := ClrDark; End Else Begin L := ClrShadow; D := ClrHi; End;
  Bar(Dc, X1, Y1, X2, Y1 + 1, L); Bar(Dc, X1, Y1, X1 + 1, Y2, L);
  Bar(Dc, X1, Y2 - 1, X2, Y2, D); Bar(Dc, X2 - 1, Y1, X2, Y2, D);
  If Up Then
  Begin
    Bar(Dc, X1 + 1, Y2 - 2, X2 - 1, Y2 - 1, ClrShadow);
    Bar(Dc, X2 - 2, Y1 + 1, X2 - 1, Y2 - 1, ClrShadow);
  End
  Else
  Begin
    Bar(Dc, X1 + 1, Y1 + 1, X2 - 1, Y1 + 2, ClrDark);
    Bar(Dc, X1 + 1, Y1 + 1, X1 + 2, Y2 - 1, ClrDark);
  End;
End;

{ relief mince (barre d'etat, en-tetes) }
Procedure Thin(Dc, X1, Y1, X2, Y2 : LongInt; Up : Boolean);
Var L, D : LongInt;
Begin
  If Up Then Begin L := ClrHi; D := ClrShadow; End Else Begin L := ClrShadow; D := ClrHi; End;
  Bar(Dc, X1, Y1, X2, Y1 + 1, L); Bar(Dc, X1, Y1, X1 + 1, Y2, L);
  Bar(Dc, X1, Y2 - 1, X2, Y2, D); Bar(Dc, X2 - 1, Y1, X2, Y2, D);
End;

Procedure RegClass(Name : String; Proc : LongInt);
Begin
  Dummy0 := WinRegisterClass(Hab, Z2(Name), Proc, 0, 0);
End;

{ fenetres : hauteur, placement (coordonnees de Pasdows dans le parent),
  affichage, invalidation }
Function WinHt(H : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[3] := 0; Rc[1] := 0;
  Dummy0 := WinQueryWindowRect(H, LongInt(@Rc));
  WinHt := Rc[3] - Rc[1];
End;

Procedure WPlace(H, X, Y, W, Hh : LongInt);
Var Ph : LongInt;
Begin
  If H = 0 Then Exit;
  Ph := WinHt(WinQueryWindow(H, QW_PARENT));
  Dummy0 := WinSetWindowPos(H, 0, X, Ph - Y - Hh, MaxI(W, 1), MaxI(Hh, 1), SWP_MOVE Or SWP_SIZE);
  Dummy0 := WinInvalidateRect(H, 0, 1);
End;

Procedure WShow(H : LongInt; On : Boolean);
Begin
  If H <> 0 Then Dummy0 := WinShowWindow(H, Ord(On));
End;

Procedure Inval(H : LongInt);
Begin
  If H <> 0 Then Dummy0 := WinInvalidateRect(H, 0, 0);
End;

{ rectangle de Pasdows (Y vers le bas) a redessiner }
Procedure InvalRect(H, X1, Y1, X2, Y2 : LongInt);
Var Rc : Array[0..3] Of LongInt; Ht : LongInt;
Begin
  Ht := WinHt(H);
  Rc[0] := X1; Rc[1] := Ht - Y2; Rc[2] := X2; Rc[3] := Ht - Y1;
  Dummy0 := WinInvalidateRect(H, LongInt(@Rc), 0);
End;

Procedure WFocus(H : LongInt);
Begin
  If H <> 0 Then Dummy0 := WinSetFocus(HWND_DESKTOP, H);
End;

{ point de la fenetre H (Y vers le bas) -> ecran (Y vers le bas) }
Procedure ToScreen(H : LongInt; Var X, Y : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  P[0] := X; P[1] := WinHt(H) - 1 - Y;
  Dummy0 := WinMapWindowPoints(H, HWND_DESKTOP, LongInt(@P), 1);
  X := P[0]; Y := ScrH - 1 - P[1];
End;

{ pointeur de la souris : SPTR_ARROW, SPTR_WAIT, SPTR_MOVE }
Procedure SetPtr(Id : LongInt);
Var P : LongInt;
Begin
  P := WinQuerySysPointer(HWND_DESKTOP, Id, 0);
  If P <> 0 Then Dummy0 := WinSetPointer(HWND_DESKTOP, P);
End;

{ touche de Pasdows (VK_SHIFT, VK_CONTROL) enfoncee }
Function KeyDown(V : LongInt) : Boolean;
Begin
  If V = VK_SHIFT Then V := PM_VK_SHIFT
  Else If V = VK_CONTROL Then V := PM_VK_CTRL;
  KeyDown := (WinGetKeyState(HWND_DESKTOP, V) And $8000) <> 0;
End;

{ barres de defilement de PM : position Pos de 0 a Max, Vis visibles }
Procedure SbSet(Sb, Pos, Max, Vis : LongInt);
Begin
  If Sb = 0 Then Exit;
  Dummy0 := WinSendMsg(Sb, PM_SBM_SETSCROLLBAR, Pos, Max Shl 16);
  Dummy0 := WinSendMsg(Sb, PM_SBM_SETTHUMBSIZE, MaxI(1, Vis) Or ((Max + Vis) Shl 16), 0);
End;

Function SbPos(Sb : LongInt) : LongInt;
Begin
  SbPos := WinSendMsg(Sb, PM_SBM_QUERYPOS, 0, 0);
End;

{ fond gris des controles statiques et des cases (boites, barres) }
Procedure GrayCtl(H : LongInt);
Var C : LongInt;
Begin
  C := CLR_PALEGRAY;
  Dummy0 := WinSetPresParam(H, PP_BACKGROUNDCOLORINDEX, 4, LongInt(@C));
End;

{ controle enfant de P (classes et styles de Pasdows traduits pour PM ;
  X, Y : Y vers le bas dans P) }
Function Ctl(P : LongInt; Cls, T : String; Style, X, Y, W, H, Id : LongInt) : LongInt;
Var R, C, S, K, Ph : LongInt;
Begin
  K := 0;
  S := PM_WS_VISIBLE;
  If (Style And WS_TABSTOP) <> 0 Then S := S Or PM_WS_TABSTOP;
  If (Style And WS_GROUP) <> 0 Then S := S Or PM_WS_GROUP;
  If Cls = 'EDIT' Then
  Begin
    C := WC_ENTRYFIELD; K := 2;
    S := S Or PM_ES_AUTOSCROLL Or PM_ES_MARGIN;
    If (Style And ES_PASSWORD) <> 0 Then S := S Or PM_ES_UNREADABLE;
    { la marge de PM est dans le rectangle : un point de chaque cote }
    X := X + 2; W := W - 4; Y := Y + 1; H := H - 2;
  End
  Else If Cls = 'LISTBOX' Then
  Begin
    C := WC_LISTBOX; K := 3;
  End
  Else If Cls = 'STATIC' Then
  Begin
    C := WC_STATIC;
    S := S Or PM_SS_TEXT Or PM_DT_VCENTER;
    Y := Y - 1; H := MaxI(H, 16);
  End
  Else
  Begin
    C := WC_BUTTON; K := 1;
    Case Style And 15 Of
      BS_DEFPUSHBUTTON : S := S Or PM_BS_PUSHBUTTON Or PM_BS_DEFAULT;
      BS_AUTOCHECKBOX : S := S Or PM_BS_AUTOCHECKBOX;
      BS_AUTORADIOBUTTON : S := S Or PM_BS_AUTORADIOBUTTON;
      BS_GROUPBOX :
      Begin
        C := WC_STATIC; K := 0;
        S := S Or PM_SS_GROUPBOX;
      End;
    Else
      S := S Or PM_BS_PUSHBUTTON;
    End;
    If ((Style And 15) = BS_AUTOCHECKBOX) Or ((Style And 15) = BS_AUTORADIOBUTTON) Then H := MaxI(H, 18);
  End;
  Ph := WinHt(P);
  { HWND_BOTTOM : l'ordre de tabulation suit l'ordre de creation }
  R := WinCreateWindow(P, C, Z(Disp(T)), S, X, Ph - Y - H, W, H, P, HWND_BOTTOM, Id, 0, 0);
  If (R <> 0) And ((C = WC_STATIC) Or ((C = WC_BUTTON) And (K = 1) And ((S And 7) <> 0))) Then GrayCtl(R);
  If (R <> 0) And (C = WC_ENTRYFIELD) Then Dummy0 := WinSendMsg(R, PM_EM_SETTEXTLIMIT, 255, 0);
  If (Id >= 0) And (Id <= 255) Then CtlKind[Id] := K;
  Ctl := R;
End;

Function CtlText(H : LongInt) : String;
Var N : LongInt;
Begin
  TxtBuf[0] := 0;
  N := WinQueryWindowText(H, 255, LongInt(@TxtBuf));
  If (N >= 0) And (N < 1023) Then TxtBuf[N] := 0;
  CtlText := UnDisp(GetZ(LongInt(@TxtBuf)));
End;

{ titre de la fenetre principale (cadre) ou texte d'un controle }
Procedure SetText(H : LongInt; S : String);
Begin
  If H = MainWnd Then H := MainFrame;
  Dummy0 := WinSetWindowText(H, Z(Disp(S)));
End;

Function Checked(H : LongInt) : Boolean;
Begin
  Checked := WinSendMsg(H, PM_BM_QUERYCHECK, 0, 0) <> 0;
End;

Procedure SetCheck(H : LongInt; On : Boolean);
Begin
  Dummy0 := WinSendMsg(H, PM_BM_SETCHECK, Ord(On), 0);
End;

{ tout le texte d'un champ de saisie choisi }
Procedure SelAllText(H : LongInt);
Begin
  Dummy0 := WinSendMsg(H, PM_EM_SETSEL, 255 Shl 16, 0);
End;

{ ---- menus : modele (menus de PM crees par gabarit) ----
  Un menu est un numero (1, 2...) ; ses articles (texte, separateur,
  sous-menu) gardent leur etat (coche, grise). SetMenu cree la barre de
  menus de la fenetre principale ; MCheck et MEnable mettent aussi a jour
  ses articles (MM_SETITEMATTR) ; TrackPopupMenu cree le menu contextuel
  avec WinPopupMenu. }
Const
  MaxMn = 48; MaxMi = 400;

Var
  MnN, MiN, MnBase : LongInt;
  MnLive : Array[1..MaxMn] Of Boolean;
  MiMenu, MiKind, MiId, MiAttr, MiSub : Array[0..MaxMi - 1] Of LongInt;
  MiText : Array[0..MaxMi - 1] Of String[80];
  MnT : Array[0..8191] Of Byte;
  MnLen, MenuHw, PopHw : LongInt;

Function CreatePopupMenu : LongInt;
Begin
  If MnN < MaxMn Then Inc(MnN);
  MnLive[MnN] := False;
  CreatePopupMenu := MnN;
End;

Function CreateMenu : LongInt;
Begin
  CreateMenu := CreatePopupMenu;
End;

Procedure MAdd(M, Kind, Id : LongInt; S : String; Sub : LongInt);
Begin
  If (MiN >= MaxMi) Or (M < 1) Then Exit;
  MiMenu[MiN] := M; MiKind[MiN] := Kind; MiId[MiN] := Id; MiAttr[MiN] := 0;
  MiText[MiN] := Copy(Disp(S), 1, 80); MiSub[MiN] := Sub;
  Inc(MiN);
End;

{ menus : ~ = lettre soulignee (comme PM) ; Id 0 : separateur }
Procedure MItem(M, Id : LongInt; S : String);
Begin
  If Id = 0 Then MAdd(M, 1, 0, '', 0) Else MAdd(M, 0, Id, S, 0);
End;

Procedure MSub(Bar0, P : LongInt; S : String);
Begin
  MAdd(Bar0, 2, 0, S, P);
End;

Procedure MAttr(M, Id, Mask : LongInt; On : Boolean);
Var I : LongInt;
Begin
  For I := 0 To MiN - 1 Do
    If (MiMenu[I] = M) And (MiId[I] = Id) And (MiKind[I] = 0) Then
      If On Then MiAttr[I] := MiAttr[I] Or Mask Else MiAttr[I] := MiAttr[I] And Not Mask;
  If (M >= 1) And (M <= MaxMn) Then
    If MnLive[M] And (MenuHw <> 0) Then
    Begin
      If On Then Dummy0 := WinSendMsg(MenuHw, PM_MM_SETITEMATTR, Id Or $10000, Mask Or (Mask Shl 16))
      Else Dummy0 := WinSendMsg(MenuHw, PM_MM_SETITEMATTR, Id Or $10000, Mask);
    End;
End;

Procedure MCheck(M, Id : LongInt; On : Boolean);
Begin
  MAttr(M, Id, MIA_CHECKED, On);
End;

Procedure MEnable(M, Id : LongInt; On : Boolean);
Begin
  MAttr(M, Id, MIA_DISABLED, Not On);
End;

Procedure MB(V : LongInt);
Begin
  If MnLen < 8191 Then
  Begin
    MnT[MnLen] := V And 255;
    Inc(MnLen);
  End;
End;

Procedure MW(V : LongInt);
Begin
  MB(V And 255); MB((V Shr 8) And 255);
End;

{ gabarit du menu M (recursif pour les sous-menus) }
Procedure MBuild(M : LongInt);
Var H, I, N, K, St : LongInt;
Begin
  H := MnLen;
  MW(0); MW(0); MW(0);
  N := 0;
  For I := 0 To MiN - 1 Do
    If MiMenu[I] = M Then
    Begin
      Case MiKind[I] Of
        1 : St := MIS_SEPARATOR;
        2 : St := MIS_TEXT Or MIS_SUBMENU;
      Else
        St := MIS_TEXT;
      End;
      MW(St); MW(MiAttr[I]);
      If MiKind[I] = 2 Then MW(9000 + I) Else MW(MiId[I]);
      If MiKind[I] <> 1 Then
      Begin
        For K := 1 To Length(MiText[I]) Do MB(Ord(MiText[I][K]));
        MB(0);
      End;
      If MiKind[I] = 2 Then MBuild(MiSub[I]);
      Inc(N);
    End;
  MnT[H] := (MnLen - H) And 255; MnT[H + 1] := ((MnLen - H) Shr 8) And 255;
  MnT[H + 4] := N And 255; MnT[H + 5] := (N Shr 8) And 255;
End;

Procedure MLive(M : LongInt);
Var I : LongInt;
Begin
  If (M < 1) Or (M > MaxMn) Then Exit;
  MnLive[M] := True;
  For I := 0 To MiN - 1 Do
    If (MiMenu[I] = M) And (MiKind[I] = 2) Then MLive(MiSub[I]);
End;

{ barre de menus de la fenetre principale }
Procedure SetMenu(M : LongInt);
Begin
  MnLen := 0;
  MBuild(M);
  MenuHw := WinCreateMenu(MainFrame, LongInt(@MnT));
  MLive(M);
  MnBase := MnN;
End;

{ menu contextuel M au point (X, Y) de l'ecran (Y vers le bas) ; les
  commandes arrivent a la fenetre principale (WM_COMMAND) }
Procedure TrackPopupMenu(M, X, Y : LongInt);
Var I, J : LongInt;
Begin
  MnLen := 0;
  MBuild(M);
  If PopHw <> 0 Then Dummy0 := WinDestroyWindow(PopHw);
  PopHw := WinCreateMenu(HWND_DESKTOP, LongInt(@MnT));
  If PopHw <> 0 Then Dummy0 := WinPopupMenu(HWND_DESKTOP, MainWnd, PopHw, X, ScrH - 1 - Y, 0, 0);
  { les menus contextuels ne servent qu'une fois }
  J := 0;
  For I := 0 To MiN - 1 Do
    If MiMenu[I] <= MnBase Then
    Begin
      MiMenu[J] := MiMenu[I]; MiKind[J] := MiKind[I]; MiId[J] := MiId[I];
      MiAttr[J] := MiAttr[I]; MiSub[J] := MiSub[I]; MiText[J] := MiText[I];
      Inc(J);
    End;
  MiN := J;
  If MnBase > 0 Then MnN := MnBase;
End;

Procedure MsgLoop;
Begin
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do
    Dummy0 := WinDispatchMsg(Hab, LongInt(@Qmsg));
End;

{ 1 234 567 }
Function Group(S : String) : String;
Var R : String; I : LongInt;
Begin
  R := '';
  For I := 1 To Length(S) Do
  Begin
    R := R + S[I];
    If ((Length(S) - I) Mod 3 = 0) And (I < Length(S)) Then R := R + ' ';
  End;
  Group := R;
End;

{ taille lisible : 512 o, 12,4 Ko, 3,2 Mo }
Function SizeTxt(V : Double) : String;
Var U : String; K : LongInt;
Begin
  If V < 1024 Then
  Begin
    SizeTxt := DStr(V) + ' o';
    Exit;
  End;
  If V < 1048576 Then Begin V := V / 1024; U := ' Ko'; End
  Else If V < 1073741824.0 Then Begin V := V / 1048576; U := ' Mo'; End
  Else Begin V := V / 1073741824.0; U := ' Go'; End;
  K := Trunc(V * 10 + 0.5);
  SizeTxt := IStr(K Div 10) + ',' + IStr(K Mod 10) + U;
End;

{ chemins locaux }
Function LJoin(D, N : String) : String;
Begin
  If (D <> '') And (D[Length(D)] = '\') Then LJoin := D + N
  Else LJoin := D + '\' + N;
End;

Function LParent(D : String) : String;
Var I : LongInt;
Begin
  If (Length(D) <= 3) Then
  Begin
    LParent := '';                       { la liste des lecteurs }
    Exit;
  End;
  If D[Length(D)] = '\' Then D := Copy(D, 1, Length(D) - 1);
  I := Length(D);
  While (I > 0) And (D[I] <> '\') Do Dec(I);
  If I <= 3 Then LParent := Copy(D, 1, 3) Else LParent := Copy(D, 1, I - 1);
End;

Function BaseOf(S : String) : String;
Var I : LongInt;
Begin
  I := Length(S);
  While (I > 0) And (S[I] <> '\') And (S[I] <> '/') Do Dec(I);
  BaseOf := Copy(S, I + 1, 255);
End;

{ ---- fichiers locaux (DOSCALLS) ---- }

{ attributs de P (FILESTATUS3) ; -1 s'il n'existe pas }
Function FAttr(P : String) : LongInt;
Var B : Array[0..31] Of Byte;
Begin
  If DosQueryPathInfo(Z(P), 1, LongInt(@B), 24) <> 0 Then FAttr := -1
  Else FAttr := PLng(LongInt(@B) + 20)^ And $37;
End;

{ recherche de fichiers (FILEFINDBUF3) : FfFirst puis FfNext tant que
  vrai ; FfName, FfAttr, FfSize, FfDate, FfTime ; FfClose }
Type
  TNames = Array[0..255] Of String;
  PNames = ^TNames;
  TFf = Record
    H, N : LongInt;
    B : Array[0..299] Of Byte;
  End;

Function FfFirst(Spec : String; Var F : TFf) : Boolean;
Begin
  F.H := -1; F.N := 1;
  FfFirst := (DosFindFirst(Z(Spec), LongInt(@F.H), $37, LongInt(@F.B), 300, LongInt(@F.N), 1) = 0) And (F.N > 0);
End;

Function FfNext(Var F : TFf) : Boolean;
Begin
  F.N := 1;
  FfNext := (DosFindNext(F.H, LongInt(@F.B), 300, LongInt(@F.N)) = 0) And (F.N > 0);
End;

Procedure FfClose(Var F : TFf);
Begin
  If F.H <> -1 Then Dummy0 := DosFindClose(F.H);
  F.H := -1;
End;

Function FfName(Var F : TFf) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  For K := 0 To F.B[28] - 1 Do S := S + Chr(F.B[29 + K]);
  FfName := S;
End;

Function FfAttr(Var F : TFf) : LongInt;
Begin
  FfAttr := PLng(LongInt(@F.B[24]))^;
End;

Function FfSize(Var F : TFf) : Double;
Var Lo : LongInt; V : Double;
Begin
  Lo := PLng(LongInt(@F.B[16]))^;
  V := Lo;
  If Lo < 0 Then V := V + 4294967296.0;
  FfSize := V;
End;

{ date de modification : AAAA-MM-JJ HH:MM }
Function FfTime(Var F : TFf) : String;
Var D, T : LongInt;
Begin
  D := F.B[12] Or (F.B[13] Shl 8); T := F.B[14] Or (F.B[15] Shl 8);
  If D = 0 Then FfTime := ''
  Else FfTime := IStr(1980 + (D Shr 9)) + '-' + Pad2((D Shr 5) And 15) + '-' + Pad2(D And 31) + ' ' +
                 Pad2(T Shr 11) + ':' + Pad2((T Shr 5) And 63);
End;

Function MkDir(P : String) : Boolean;
Begin
  MkDir := DosCreateDir(Z(P), 0) = 0;
End;

{ ecriture possible sur le lecteur de P (pas un CD-ROM) }
Function DrvWritable(D : Char) : Boolean;
Var B : Array[0..63] Of Byte; Cb, N : LongInt; Fs : String;
Begin
  DrvWritable := False;
  Cb := 64;
  PutZ(LongInt(@NameZ2), D + ':');
  If DosQueryFSAttach(LongInt(@NameZ2), 0, 1, LongInt(@B), LongInt(@Cb)) <> 0 Then Exit;
  N := B[2] Or (B[3] Shl 8);
  Fs := UpS(GetZ(LongInt(@B) + 8 + N + 1));
  DrvWritable := (Fs <> 'CDFS') And (Fs <> 'ISO9660') And (Fs <> 'UDF');
End;

{ dossier des fichiers de configuration (sitemanager.xml,
  recentservers.xml, knownhosts.txt) : C:\RESEAU\, sinon D:\RESEAU\
  quand C: est en lecture seule (demarrage du CD-ROM) ; meme regle que
  le Client SSH }
Procedure FindAppDir;
Var P : LongInt;
Begin
  { dossier des applications d'OS/2-0 : celui de COMSPEC }
  AppExeDir := 'C:\';
  P := 0;
  If DosScanEnv(Z2('COMSPEC'), LongInt(@P)) = 0 Then
    If P <> 0 Then
    Begin
      AppExeDir := GetZ(P);
      While (AppExeDir <> '') And (AppExeDir[Length(AppExeDir)] <> '\') Do Delete(AppExeDir, Length(AppExeDir), 1);
      If AppExeDir = '' Then AppExeDir := 'C:\';
    End;
  AppDir := 'C:\RESEAU\';
  If DrvWritable('C') Then
  Begin
    If FAttr('C:\RESEAU') = -1 Then
      If Not MkDir('C:\RESEAU') Then AppDir := 'D:\RESEAU\';
  End
  Else AppDir := 'D:\RESEAU\';
  If AppDir = 'D:\RESEAU\' Then
    If FAttr('D:\RESEAU') = -1 Then
      If Not MkDir('D:\RESEAU') Then AppDir := 'D:\';
End;

{ WM_VSCROLL de PM (mp2 : position, commande) -> code de Pasdows
  (0 ligne haut, 1 ligne bas, 2 page haut, 3 page bas, 4 position,
  5 suivi) + position Shl 16 }
Function VsCode(Mp2 : LongInt) : LongInt;
Var C, P : LongInt;
Begin
  P := Mp2 And $FFFF;
  Case (Mp2 Shr 16) And $FFFF Of
    1 : C := 0;
    2 : C := 1;
    3 : C := 2;
    4 : C := 3;
    5 : C := 5;
    6 : C := 4;
  Else
    C := 99;
  End;
  VsCode := C Or (P Shl 16);
End;

{ point de la souris de PM (Y vers le haut) -> Pasdows (Y vers le bas) }
Function MousePt(H, Mp1 : LongInt) : LongInt;
Var X, Y : LongInt;
Begin
  X := S16(Mp1); Y := WinHt(H) - 1 - S16(Mp1 Shr 16);
  MousePt := (X And $FFFF) Or ((Y And $FFFF) Shl 16);
End;

{ touche virtuelle de PM -> touche de Pasdows (0 : aucune) }
Function VkOf(V : LongInt) : LongInt;
Begin
  Case V Of
    PM_VK_BACKSPACE : VkOf := VK_BACK;
    PM_VK_TAB, PM_VK_BACKTAB : VkOf := VK_TAB;
    PM_VK_NEWLINE, PM_VK_ENTER : VkOf := VK_RETURN;
    PM_VK_ESC : VkOf := VK_ESCAPE;
    PM_VK_SPACE : VkOf := VK_SPACE;
    PM_VK_PAGEUP : VkOf := VK_PRIOR;
    PM_VK_PAGEDOWN : VkOf := VK_NEXT;
    PM_VK_END : VkOf := VK_END;
    PM_VK_HOME : VkOf := VK_HOME;
    PM_VK_LEFT : VkOf := VK_LEFT;
    PM_VK_UP : VkOf := VK_UP;
    PM_VK_RIGHT : VkOf := VK_RIGHT;
    PM_VK_DOWN : VkOf := VK_DOWN;
    PM_VK_DELETE : VkOf := VK_DELETE;
  Else
    If (V >= PM_VK_F1) And (V <= PM_VK_F1 + 11) Then VkOf := $70 + V - PM_VK_F1 Else VkOf := 0;
  End;
End;
{ Gestionnaire de sites : sitemanager.xml (format de FileZilla 3),      }
{ historique recentservers.xml, cles d'hote connues (knownhosts.txt)    }
{ ==================================================================== }

Const
  MaxSite = 100;
  MaxRecent = 10;
  LgAnon = 0; LgNormal = 1; LgAsk = 2;

Type
  TSite = Record
    Name, Folder, Host, User, Pass, RemDir, LocDir, Comment : String;
    Port, Proto, Logon : LongInt;
  End;
  TSiteArr = Array[0..MaxSite - 1] Of TSite;
  PSiteArr = ^TSiteArr;

Var
  Sites : PSiteArr;
  SiteN : LongInt;
  Recent : Array[0..MaxRecent - 1] Of TSite;
  RecentN : LongInt;
  XBufA : TlPtr;                       { fichier lu ou ecrit (256 Ko) }
  XLen : LongInt;
  XOut : TlPtr;
  XOutN : LongInt;

Procedure SiteClear(Var S : TSite);
Begin
  S.Name := ''; S.Folder := ''; S.Host := ''; S.User := ''; S.Pass := '';
  S.RemDir := ''; S.LocDir := ''; S.Comment := '';
  S.Port := 21; S.Proto := PrFtp; S.Logon := LgNormal;
End;

{ fichier entier dans XBufA (False s'il n'existe pas) }
Function LoadAll(Name : String) : Boolean;
Var H, N : LongInt;
Begin
  LoadAll := False;
  If XBufA = 0 Then XBufA := TlNew(262144);
  XLen := 0;
  H := LfOpen(Name);
  If H = -1 Then Exit;
  Repeat
    N := LfRead(H, XBufA + XLen, 262143 - XLen);
    If N > 0 Then XLen := XLen + N;
  Until (N <= 0) Or (XLen >= 262143);
  LfClose(H);
  LoadAll := True;
End;

Function SaveAll(Name : String) : Boolean;
Var H : LongInt;
Begin
  SaveAll := False;
  H := LfCreate(Name, False);
  If H = -1 Then Exit;
  SaveAll := LfWrite(H, XOut, XOutN);
  LfClose(H);
End;

{ ---- lecture XML ---- }

Function XmlDecode(S : String) : String;
Var R, E : String; I, J, V : LongInt;
Begin
  R := ''; I := 1;
  While I <= Length(S) Do
  Begin
    If S[I] = '&' Then
    Begin
      J := I;
      While (J <= Length(S)) And (S[J] <> ';') Do Inc(J);
      E := Copy(S, I + 1, J - I - 1);
      If E = 'amp' Then R := R + '&'
      Else If E = 'lt' Then R := R + '<'
      Else If E = 'gt' Then R := R + '>'
      Else If E = 'quot' Then R := R + '"'
      Else If E = 'apos' Then R := R + ''''
      Else If (E <> '') And (E[1] = '#') Then
      Begin
        If (Length(E) > 1) And (E[2] = 'x') Then V := SVal('$' + Copy(E, 3, 8))
        Else V := SVal(Copy(E, 2, 8));
        If (V > 0) And (V < 256) Then R := R + Chr(V) Else R := R + '?';
      End;
      I := J + 1;
    End
    Else
    Begin
      R := R + S[I]; Inc(I);
    End;
  End;
  XmlDecode := U8ToA(R);
End;

{ chemin distant de FileZilla : "1 0 4 home 7 pasdows" -> /home/pasdows }
Function FzPathDec(S : String) : String;
Var P, N : LongInt; R : String;

  Function NextInt : LongInt;
  Var V : LongInt;
  Begin
    While (P <= Length(S)) And (S[P] = ' ') Do Inc(P);
    V := 0;
    While (P <= Length(S)) And (S[P] In ['0'..'9']) Do
    Begin
      V := V * 10 + Ord(S[P]) - 48; Inc(P);
    End;
    NextInt := V;
  End;

Begin
  S := TrimS(S);
  If S = '' Then
  Begin
    FzPathDec := '';
    Exit;
  End;
  If S[1] = '/' Then
  Begin
    FzPathDec := S;
    Exit;
  End;
  P := 1;
  N := NextInt;                          { type de serveur }
  N := NextInt;                          { longueur du prefixe }
  If N > 0 Then P := P + 1 + N;
  R := '';
  While P <= Length(S) Do
  Begin
    N := NextInt;
    If N <= 0 Then Break;
    Inc(P);                               { espace }
    R := R + '/' + Copy(S, P, N);
    P := P + N;
  End;
  If R = '' Then R := '/';
  FzPathDec := R;
End;

Function FzPathEnc(S : String) : String;
Var R, Seg : String; I : LongInt;
Begin
  If S = '' Then
  Begin
    FzPathEnc := '';
    Exit;
  End;
  R := '1 0';
  Seg := '';
  For I := 1 To Length(S) + 1 Do
    If (I > Length(S)) Or (S[I] = '/') Then
    Begin
      If Seg <> '' Then R := R + ' ' + IStr(Length(Seg)) + ' ' + Seg;
      Seg := '';
    End
    Else Seg := Seg + S[I];
  FzPathEnc := R;
End;

{ elements <Server> du fichier lu (Dest : 0 sites, 1 historique) }
Procedure ParseServers(Dest : LongInt);
Var I, J, FDepth, K : LongInt; Tag, Txt, Nm, Attr : String;
    FName : Array[0..7] Of String; InServer, WantFolder : Boolean;
    S : TSite; C : LongInt;
Begin
  I := 0; FDepth := 0; InServer := False; WantFolder := False; Txt := '';
  SiteClear(S);
  While I < XLen Do
  Begin
    C := TlGet(XBufA + I);
    If C <> Ord('<') Then
    Begin
      If Length(Txt) < 255 Then Txt := Txt + Chr(C);
      Inc(I);
      Continue;
    End;
    { balise }
    J := I + 1; Tag := '';
    While (J < XLen) And (TlGet(XBufA + J) <> Ord('>')) Do
    Begin
      If Length(Tag) < 255 Then Tag := Tag + Chr(TlGet(XBufA + J));
      Inc(J);
    End;
    I := J + 1;
    If WantFolder And (FDepth > 0) And (TrimS(Txt) <> '') Then
    Begin
      FName[FDepth] := TrimS(XmlDecode(Txt));
      WantFolder := False;
    End;
    If (Tag = '') Or (Tag[1] = '?') Or (Tag[1] = '!') Then
    Begin
      Txt := '';
      Continue;
    End;
    K := 1;
    While (K <= Length(Tag)) And Not (Tag[K] In [' ', '/', #9]) Do Inc(K);
    If Tag[1] = '/' Then
    Begin
      Nm := Copy(Tag, 2, 64);
      If Nm = 'Folder' Then
      Begin
        If FDepth > 0 Then Dec(FDepth);
      End
      Else If Nm = 'Server' Then
      Begin
        InServer := False;
        If S.Name = '' Then S.Name := S.Host;
        If Dest = 0 Then
        Begin
          If SiteN < MaxSite Then
          Begin
            Sites^[SiteN] := S; Inc(SiteN);
          End;
        End
        Else If RecentN < MaxRecent Then
        Begin
          Recent[RecentN] := S; Inc(RecentN);
        End;
      End
      Else If InServer Then
      Begin
        Txt := XmlDecode(Txt);
        If Nm = 'Host' Then S.Host := TrimS(Txt)
        Else If Nm = 'Port' Then S.Port := SVal(TrimS(Txt))
        Else If Nm = 'Protocol' Then
        Begin
          If SVal(TrimS(Txt)) = 1 Then S.Proto := PrSftp Else S.Proto := PrFtp;
        End
        Else If Nm = 'Logontype' Then
        Begin
          Case SVal(TrimS(Txt)) Of
            0 : S.Logon := LgAnon;
            2, 3 : S.Logon := LgAsk;
          Else
            S.Logon := LgNormal;
          End;
        End
        Else If Nm = 'User' Then S.User := Txt
        Else If Nm = 'Pass' Then
        Begin
          If Pos('base64', Attr) > 0 Then S.Pass := StrB64Dec(TrimS(Txt))
          Else S.Pass := Txt;
        End
        Else If Nm = 'Name' Then S.Name := TrimS(Txt)
        Else If Nm = 'RemoteDir' Then S.RemDir := FzPathDec(Txt)
        Else If Nm = 'LocalDir' Then S.LocDir := TrimS(Txt)
        Else If Nm = 'Comments' Then S.Comment := Txt;
      End;
    End
    Else
    Begin
      Nm := Copy(Tag, 1, K - 1);
      Attr := Copy(Tag, K, 255);
      If Nm = 'Folder' Then
      Begin
        If FDepth < 7 Then Inc(FDepth);
        FName[FDepth] := '';
        WantFolder := True;
      End
      Else If Nm = 'Server' Then
      Begin
        InServer := True;
        SiteClear(S);
        S.Folder := '';
        For K := 1 To FDepth Do
        Begin
          If S.Folder <> '' Then S.Folder := S.Folder + '/';
          S.Folder := S.Folder + FName[K];
        End;
      End;
    End;
    Txt := '';
  End;
End;

Procedure LoadSites;
Begin
  SiteN := 0;
  If LoadAll(AppDir + 'sitemanager.xml') Then ParseServers(0);
End;

Procedure LoadRecent;
Begin
  RecentN := 0;
  If LoadAll(AppDir + 'recentservers.xml') Then ParseServers(1);
End;

{ importe un autre sitemanager.xml (ajoute ses sites) ; nombre ajoute }
Function ImportSites(F : String) : LongInt;
Var N : LongInt;
Begin
  N := SiteN;
  If LoadAll(F) Then ParseServers(0);
  ImportSites := SiteN - N;
End;

{ ---- ecriture XML ---- }

Procedure XW(S : String);
Var I : LongInt;
Begin
  If XOut = 0 Then XOut := TlNew(262144);
  For I := 1 To Length(S) Do
    If XOutN < 262143 Then
    Begin
      TlPut(XOut + XOutN, Ord(S[I])); Inc(XOutN);
    End;
End;

Function XmlEnc(S : String) : String;
Var R : String; I : LongInt;
Begin
  S := AToU8(S);
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
  XmlEnc := R;
End;

Procedure XEl(Ind : String; Nm, V : String);
Begin
  If V = '' Then XW(Ind + '<' + Nm + ' />'#13#10)
  Else XW(Ind + '<' + Nm + '>' + XmlEnc(V) + '</' + Nm + '>'#13#10);
End;

Procedure XServer(Var S : TSite; Ind : String);
Var L : LongInt;
Begin
  XW(Ind + '<Server>'#13#10);
  XEl(Ind + #9, 'Host', S.Host);
  XEl(Ind + #9, 'Port', IStr(S.Port));
  If S.Proto = PrSftp Then XEl(Ind + #9, 'Protocol', '1')
  Else XEl(Ind + #9, 'Protocol', '0');
  XEl(Ind + #9, 'Type', '0');
  XEl(Ind + #9, 'User', S.User);
  If (S.Pass <> '') And (S.Logon = LgNormal) Then
    XW(Ind + #9'<Pass encoding="base64">' + StrB64Enc(AToU8(S.Pass)) +
       '</Pass>'#13#10);
  Case S.Logon Of
    LgAnon : L := 0;
    LgAsk : L := 2;
  Else
    L := 1;
  End;
  XEl(Ind + #9, 'Logontype', IStr(L));
  XEl(Ind + #9, 'PasvMode', 'MODE_DEFAULT');
  XEl(Ind + #9, 'EncodingType', 'Auto');
  XEl(Ind + #9, 'BypassProxy', '0');
  XEl(Ind + #9, 'Name', S.Name);
  XEl(Ind + #9, 'RemoteDir', FzPathEnc(S.RemDir));
  XEl(Ind + #9, 'LocalDir', S.LocDir);
  XEl(Ind + #9, 'Comments', S.Comment);
  XEl(Ind + #9, 'SyncBrowsing', '0');
  XEl(Ind + #9, 'DirectoryComparison', '0');
  XW(Ind + '</Server>'#13#10);
End;

Procedure XHead;
Begin
  XOutN := 0;
  XW('<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>'#13#10);
  XW('<FileZilla3 version="3.66.0" platform="windows">'#13#10);
End;

{ sites sans dossier, puis chaque dossier (un niveau) }
Function SaveSitesTo(F : String) : Boolean;
Var I, J : LongInt; Done : Array[0..MaxSite - 1] Of Boolean;
Begin
  XHead;
  XW(#9'<Servers>'#13#10);
  For I := 0 To SiteN - 1 Do
  Begin
    Done[I] := Sites^[I].Folder = '';
    If Done[I] Then XServer(Sites^[I], #9#9);
  End;
  For I := 0 To SiteN - 1 Do
    If Not Done[I] Then
    Begin
      XW(#9#9'<Folder expanded="1">' + XmlEnc(Sites^[I].Folder) + #13#10);
      For J := I To SiteN - 1 Do
        If Not Done[J] And (Sites^[J].Folder = Sites^[I].Folder) Then
        Begin
          XServer(Sites^[J], #9#9#9);
          Done[J] := True;
        End;
      XW(#9#9'</Folder>'#13#10);
    End;
  XW(#9'</Servers>'#13#10'</FileZilla3>'#13#10);
  SaveSitesTo := SaveAll(F);
End;

Function SaveSites : Boolean;
Begin
  SaveSites := SaveSitesTo(AppDir + 'sitemanager.xml');
End;

Procedure SaveRecent;
Var I : LongInt;
Begin
  XHead;
  XW(#9'<RecentServers>'#13#10);
  For I := 0 To RecentN - 1 Do XServer(Recent[I], #9#9);
  XW(#9'</RecentServers>'#13#10'</FileZilla3>'#13#10);
  If SaveAll(AppDir + 'recentservers.xml') Then;
End;

{ ajoute une connexion rapide en tete de l'historique }
Procedure AddRecent(Var S : TSite);
Var I, K : LongInt;
Begin
  K := RecentN;
  For I := 0 To RecentN - 1 Do
    If (UpS(Recent[I].Host) = UpS(S.Host)) And (Recent[I].Port = S.Port) And
       (Recent[I].User = S.User) And (Recent[I].Proto = S.Proto) Then K := I;
  If K = RecentN Then
  Begin
    If RecentN < MaxRecent Then Inc(RecentN);
    K := RecentN - 1;
  End;
  For I := K DownTo 1 Do Recent[I] := Recent[I - 1];
  Recent[0] := S;
  Recent[0].Name := S.Host;
  SaveRecent;
End;

{ ---- cles d'hote : lignes "hote:port SHA256:..." ---- }

Function KnownHost(Key : String) : String;
Var I, St, K, N : LongInt; L, R : String; Same : Boolean;
Begin
  R := '';
  N := Length(Key);
  If LoadAll(AppDir + 'knownhosts.txt') Then
  Begin
    St := 0;
    For I := 0 To XLen Do
      If (I = XLen) Or (TlGet(XBufA + I) = 10) Then
      Begin
        L := '';
        While (St < I) And (Length(L) < 255) Do
        Begin
          If TlGet(XBufA + St) >= 32 Then L := L + Chr(TlGet(XBufA + St));
          Inc(St);
        End;
        St := I + 1;
        Same := Length(L) > N + 1;
        If Same Then
          For K := 1 To N Do
            If L[K] <> Key[K] Then Same := False;
        If Same And (L[N + 1] = ' ') Then R := Copy(L, N + 2, 255);
      End;
  End;
  KnownHost := R;
End;

Procedure SaveHost(Key, Val : String);
Var I, St : LongInt; L : String;
Begin
  XOutN := 0;
  XW('');
  If LoadAll(AppDir + 'knownhosts.txt') Then
  Begin
    St := 0;
    For I := 0 To XLen Do
      If (I = XLen) Or (TlGet(XBufA + I) = 10) Then
      Begin
        L := '';
        While (St < I) And (Length(L) < 255) Do
        Begin
          If TlGet(XBufA + St) >= 32 Then L := L + Chr(TlGet(XBufA + St));
          Inc(St);
        End;
        St := I + 1;
        If (L <> '') And (Copy(L, 1, Length(Key) + 1) <> Key + ' ') Then
          XW(L + #13#10);
      End;
  End;
  XW(Key + ' ' + Val + #13#10);
  If SaveAll(AppDir + 'knownhosts.txt') Then;
End;
{ ==================================================================== }
{ Listes (site local, site distant, file d'attente) et journal          }
{ ==================================================================== }

Const
  LvLocal = 0; LvRemote = 1; LvQueue = 2;
  MaxQ = 1000;
  QkDown = 0; QkUp = 1; QkMkdir = 2; QkDownDir = 3;
  QsWait = 0; QsRun = 1; QsOk = 2; QsFail = 3;
  LogMax = 300;
  LRH = 14;                             { ligne du journal }
  SbW = 16;                             { barre de defilement }

Type
  TLv = Record
    H, Sb : LongInt;
    Top, Cur, Anchor : LongInt;
    SortCol : LongInt;
    SortDesc : Boolean;
    W, Ht : LongInt;
    Focus : Boolean;
  End;
  TQItem = Record
    Kind, State : LongInt;
    Loc, Rem : String;
    Size, Done : Double;
    Err : String;
  End;
  TQArr = Array[0..MaxQ - 1] Of TQItem;
  PQArr = ^TQArr;
  TIdx = Array[0..MaxEnt - 1] Of LongInt;
  TSel = Array[0..MaxEnt - 1] Of Boolean;
  TLogLine = Record
    Kind : LongInt;
    S : String[200];
  End;
  TLogArr = Array[0..LogMax - 1] Of TLogLine;
  PLogArr = ^TLogArr;

Var
  Lv : Array[0..2] Of TLv;
  LocL, RemL, TmpL : PEntArr;
  LocN, RemN : LongInt;
  LocIdx, RemIdx, QIdx : TIdx;
  LocSel, RemSel, QSel : TSel;
  LocPath : String;
  RemPath : String;                     { dossier distant affiche }
  RemOk : Boolean;                      { liste distante valide }
  Queue : PQArr;
  QN, QTab, QShown : LongInt;
  ShowHidden : Boolean;
  LogW, LogSb, LogHt, LogWd : LongInt;
  LogL : PLogArr;
  LogN, LogTop : LongInt;
  LogPosted : Boolean;
  DragFrom : LongInt;                   { -1 : pas de glisser }
  DragOn : Boolean;
  DragX, DragY : LongInt;
  ColN : LongInt;                       { colonnes de la liste peinte }
  ColT : Array[0..5] Of String[40];
  ColW, ColF, ColA : Array[0..5] Of LongInt;

Procedure ListCommand(K, Cmd : LongInt); Forward;
Procedure ListOpen(K : LongInt); Forward;
Procedure ListDrop(K, Target : LongInt); Forward;
Procedure ListMenu(K, X, Y : LongInt); Forward;
Procedure ListChanged(K : LongInt); Forward;

{ ==================================================================== }
{ Journal des messages                                                  }
{ ==================================================================== }

{ appele par les protocoles (tache reseau, verrou tenu) et l'interface }
Procedure LogMsg(Kind : LongInt; S : String);
Var I : LongInt;
Begin
  If LogL = Nil Then Exit;
  If LogN >= LogMax Then
  Begin
    For I := 0 To LogMax - 2 Do LogL^[I] := LogL^[I + 1];
    LogN := LogMax - 1;
  End;
  LogL^[LogN].Kind := Kind;
  LogL^[LogN].S := Copy(S, 1, 200);
  Inc(LogN);
  If Not LogPosted Then
  Begin
    LogPosted := True;
    Dummy := WinPostMsg(MainWnd, WM_NETLOG, 0, 0);
  End;
End;

Function LogRows : LongInt;
Begin
  LogRows := MaxI(1, (LogHt - 4) Div LRH);
End;

Procedure LogSync(Follow : Boolean);
Var M : LongInt;
Begin
  M := MaxI(0, LogN - LogRows);
  If Follow Or (LogTop > M) Then LogTop := M;
  SbSet(LogSb, LogTop, M, LogRows);
End;

Procedure LogPaint(H : LongInt);
Var Dc, I, Y, C : LongInt; P : String;
Begin
  Dc := PaintBegin(H);
  Bar(Dc, 0, 0, LogWd - SbW, LogHt, ClrWin);
  Bevel(Dc, 0, 0, LogWd - SbW, LogHt, False);
  Y := 2;
  For I := LogTop To LogN - 1 Do
  Begin
    If Y + LRH > LogHt Then Break;
    Case LogL^[I].Kind Of
      LgStatus : Begin C := ClrBlack; P := 'Statut :'; End;
      LgCmd : Begin C := ClrNavy; P := 'Commande :'; End;
      LgReply : Begin C := ClrGreen; P := 'R'#233'ponse :'; End;
      LgError : Begin C := ClrRed; P := 'Erreur :'; End;
    Else
      Begin C := ClrGray; P := 'Liste :'; End;
    End;
    Txt(Dc, 4, Y, P, C);
    Txt(Dc, 4 + 12 * CW, Y, Fit(LogL^[I].S, LogWd - SbW - 8 - 12 * CW), C);
    Y := Y + LRH;
  End;
  PaintEnd(Dc);
End;

Function LogProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var Code, M : LongInt;
Begin
  LogProc0 := 0;
  Case Msg Of
    WM_PAINT : LogPaint(H);
    WM_ERASEBKGND : LogProc0 := 1;
    WM_SIZE :
    Begin
      LogWd := LP And $FFFF; LogHt := (LP Shr 16) And $FFFF;
      If LogSb <> 0 Then
        WPlace(LogSb, LogWd - SbW, 0, SbW, LogHt);
      LogSync(False);
    End;
    WM_VSCROLL :
    Begin
      Code := WP And $FFFF;
      M := MaxI(0, LogN - LogRows);
      Case Code Of
        0 : Dec(LogTop);
        1 : Inc(LogTop);
        2 : LogTop := LogTop - LogRows;
        3 : LogTop := LogTop + LogRows;
        4, 5 : LogTop := S16(WP Shr 16);
        8 : LogTop := SbPos(LogSb);
      End;
      If LogTop > M Then LogTop := M;
      If LogTop < 0 Then LogTop := 0;
      SbSet(LogSb, LogTop, M, LogRows);
      Inval(H);
    End;
    WM_MOUSEWHEEL :
    Begin
      If S16(WP Shr 16) > 0 Then LogTop := LogTop - 3 Else LogTop := LogTop + 3;
      M := MaxI(0, LogN - LogRows);
      If LogTop > M Then LogTop := M;
      If LogTop < 0 Then LogTop := 0;
      SbSet(LogSb, LogTop, M, LogRows);
      Inval(H);
    End;
  Else
    LogProc0 := 0;
  End;
End;

{ procedure de fenetre de PM du journal : messages de PM traduits en
  evenements de LogProc0 }
Function LogProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  BigLock;
  LogProc := 0;
  Case Msg Of
    PM_WM_PAINT : Dummy0 := LogProc0(H, WM_PAINT, 0, 0);
    PM_WM_SIZE : Dummy0 := LogProc0(H, WM_SIZE, 0, Mp2);
    PM_WM_VSCROLL : Dummy0 := LogProc0(H, WM_VSCROLL, VsCode(Mp2), 0);
    PM_WM_ERASEBACKGROUND : LogProc := 1;
  Else
    LogProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
  BigUnlock;
End;

{ ==================================================================== }
{ Listes de fichiers                                                    }
{ ==================================================================== }

Type
  PEntry = ^TEntry;

Function LvCount(K : LongInt) : LongInt;
Begin
  Case K Of
    LvLocal : LvCount := LocN;
    LvRemote : If RemOk Then LvCount := RemN Else LvCount := 0;
  Else
    LvCount := QShown;
  End;
End;

Function LvE(K, R : LongInt) : PEntry;
Begin
  If K = LvLocal Then LvE := @LocL^[LocIdx[R]]
  Else LvE := @RemL^[RemIdx[R]];
End;

Function LvSel(K, R : LongInt) : Boolean;
Begin
  Case K Of
    LvLocal : LvSel := LocSel[R];
    LvRemote : LvSel := RemSel[R];
  Else
    LvSel := QSel[R];
  End;
End;

Procedure LvSetSel(K, R : LongInt; On : Boolean);
Begin
  Case K Of
    LvLocal : LocSel[R] := On;
    LvRemote : RemSel[R] := On;
  Else
    QSel[R] := On;
  End;
End;

Procedure LvClearSel(K : LongInt);
Var I : LongInt;
Begin
  For I := 0 To MaxEnt - 1 Do LvSetSel(K, I, False);
End;

Function LvRows(K : LongInt) : LongInt;
Begin
  LvRows := MaxI(1, (Lv[K].Ht - HH) Div RH);
End;

{ file d'attente : elements de l'onglet choisi }
Procedure QFilter;
Var I : LongInt; Ok : Boolean;
Begin
  QShown := 0;
  For I := 0 To QN - 1 Do
  Begin
    Case QTab Of
      0 : Ok := (Queue^[I].State = QsWait) Or (Queue^[I].State = QsRun);
      1 : Ok := Queue^[I].State = QsFail;
    Else
      Ok := Queue^[I].State = QsOk;
    End;
    If Ok And (QShown < MaxEnt) Then
    Begin
      QIdx[QShown] := I; Inc(QShown);
    End;
  End;
End;

Function ExtOf(N : String) : String;
Var I : LongInt;
Begin
  I := Length(N);
  While (I > 0) And (N[I] <> '.') Do Dec(I);
  If I > 1 Then ExtOf := UpS(Copy(N, I + 1, 8)) Else ExtOf := '';
End;

Function FileType(Var E : TEntry) : String;
Var X : String;
Begin
  If E.Name = '..' Then FileType := ''
  Else If E.Dir Then
  Begin
    If (Length(E.Name) = 2) And (E.Name[2] = ':') Then FileType := E.Perm
    Else FileType := 'Dossier';
  End
  Else If E.Link Then FileType := 'Lien'
  Else
  Begin
    X := ExtOf(E.Name);
    If (X = 'EXE') Or (X = 'COM') Then FileType := 'Application'
    Else If X = 'TXT' Then FileType := 'Document texte'
    Else If (X = 'HTM') Or (X = 'HTML') Then FileType := 'Document HTML'
    Else If X = 'BMP' Then FileType := 'Image bitmap'
    Else If (X = 'JPG') Or (X = 'PNG') Or (X = 'GIF') Then FileType := 'Image ' + X
    Else If (X = 'MP3') Or (X = 'WAV') Then FileType := 'Son ' + X
    Else If (X = 'ZIP') Or (X = 'GZ') Or (X = 'TGZ') Then FileType := 'Archive ' + X
    Else If X = '' Then FileType := 'Fichier'
    Else FileType := 'Fichier ' + X;
  End;
End;

Procedure ColAdd(T : String; Wd, F, A : LongInt);
Begin
  ColT[ColN] := T; ColW[ColN] := Wd; ColF[ColN] := F; ColA[ColN] := A;
  Inc(ColN);
End;

{ colonnes de la liste K pour une largeur W (F : champ) ; largeurs pour
  la police de 8 points de PM }
Procedure LvCols(K, W : LongInt);
Var Rest, I : LongInt;
Begin
  ColN := 0;
  W := W - SbW;
  If K = LvQueue Then
  Begin
    ColAdd('Fichier local', 0, 10, 0);
    ColAdd('Direction', 96, 11, 0);
    ColAdd('Fichier distant', 0, 12, 0);
    ColAdd('Taille', 96, 13, 1);
    ColAdd('Statut', 150, 14, 0);
    Rest := W - 96 - 96 - 150;
    ColW[0] := Rest Div 2; ColW[2] := Rest - ColW[0];
    Exit;
  End;
  ColAdd('Nom de fichier', 0, 0, 0);
  ColAdd('Taille', 96, 1, 1);
  If W >= 560 Then ColAdd('Type de fichier', 128, 2, 0);
  If W >= 340 Then ColAdd('Derni'#232're modification', 136, 3, 0);
  If (K = LvRemote) And (W >= 640) Then ColAdd('Droits', 96, 4, 0);
  If (K = LvRemote) And (W >= 800) Then ColAdd('Propri'#233'taire', 144, 5, 0);
  If (K = LvLocal) And (W >= 800) Then ColW[2] := 186;
  Rest := W;
  For I := 1 To ColN - 1 Do Rest := Rest - ColW[I];
  ColW[0] := MaxI(60, Rest);
End;

Function SizeCell(V : Double; Dir : Boolean) : String;
Begin
  If Dir Then SizeCell := '' Else SizeCell := Group(DStr(V));
End;

Function CellText(K, R, F : LongInt) : String;
Var E : PEntry; Q : LongInt;
Begin
  CellText := '';
  If K = LvQueue Then
  Begin
    Q := QIdx[R];
    Case F Of
      10 : CellText := Queue^[Q].Loc;
      11 : Case Queue^[Q].Kind Of
             QkDown, QkDownDir : CellText := '<-- r'#233'ception';
             QkUp : CellText := '--> envoi';
           Else
             CellText := 'dossier';
           End;
      12 : CellText := Queue^[Q].Rem;
      13 : If Queue^[Q].Kind In [QkDown, QkUp] Then CellText := Group(DStr(Queue^[Q].Size));
      14 : Case Queue^[Q].State Of
             QsWait : CellText := 'En attente';
             QsRun : CellText := 'En cours';
             QsOk : CellText := 'Termin'#233;
           Else
             CellText := Queue^[Q].Err;
           End;
    End;
    Exit;
  End;
  E := LvE(K, R);
  Case F Of
    0 : CellText := E^.Name;
    1 : If E^.Name <> '..' Then CellText := SizeCell(E^.Size, E^.Dir);
    2 : CellText := FileType(E^);
    3 : CellText := E^.Time;
    4 : CellText := E^.Perm;
    5 : CellText := E^.Owner;
  End;
End;

{ ---- icones (rectangles) ---- }

Procedure IconFolder(Dc, X, Y : LongInt; Open : Boolean);
Begin
  Bar(Dc, X + 1, Y + 1, X + 7, Y + 3, ClrOlive);
  Bar(Dc, X, Y + 3, X + 15, Y + 13, ClrOlive);
  Bar(Dc, X + 1, Y + 4, X + 14, Y + 12, ClrYellow);
  If Open Then Bar(Dc, X + 1, Y + 4, X + 14, Y + 5, ClrHi);
End;

Procedure IconFile(Dc, X, Y : LongInt; Ex : String);
Var C : LongInt;
Begin
  Bar(Dc, X + 2, Y, X + 12, Y + 13, ClrBlack);
  Bar(Dc, X + 3, Y + 1, X + 11, Y + 12, ClrHi);
  Bar(Dc, X + 8, Y + 1, X + 11, Y + 4, ClrFace);
  If (Ex = 'EXE') Or (Ex = 'COM') Then
  Begin
    Bar(Dc, X + 3, Y + 4, X + 11, Y + 6, ClrNavy);
    Exit;
  End;
  If (Ex = 'JPG') Or (Ex = 'PNG') Or (Ex = 'GIF') Or (Ex = 'BMP') Then C := ClrTeal
  Else If (Ex = 'MP3') Or (Ex = 'WAV') Then C := ClrMaroon
  Else C := ClrGray;
  Bar(Dc, X + 4, Y + 5, X + 10, Y + 6, C);
  Bar(Dc, X + 4, Y + 7, X + 10, Y + 8, C);
  Bar(Dc, X + 4, Y + 9, X + 9, Y + 10, C);
End;

Procedure IconDrive(Dc, X, Y : LongInt);
Begin
  Bar(Dc, X, Y + 4, X + 15, Y + 11, ClrBlack);
  Bar(Dc, X + 1, Y + 5, X + 14, Y + 10, ClrFace);
  Bar(Dc, X + 11, Y + 8, X + 13, Y + 9, ClrGreen);
End;

Procedure IconUp(Dc, X, Y : LongInt);
Begin
  IconFolder(Dc, X, Y, False);
  Bar(Dc, X + 7, Y + 5, X + 9, Y + 11, ClrBlack);
  Bar(Dc, X + 5, Y + 7, X + 11, Y + 8, ClrBlack);
  Bar(Dc, X + 6, Y + 6, X + 10, Y + 7, ClrBlack);
End;

Procedure IconFor(Dc, X, Y : LongInt; Var E : TEntry);
Begin
  If E.Name = '..' Then IconUp(Dc, X, Y)
  Else If E.Dir And (Length(E.Name) = 2) And (E.Name[2] = ':') Then
    IconDrive(Dc, X, Y)
  Else If E.Dir Then IconFolder(Dc, X, Y, False)
  Else IconFile(Dc, X, Y, ExtOf(E.Name));
End;

{ ---- tri ---- }

Function EntLess(K, A, B : LongInt) : Boolean;
Var EA, EB : PEntry; C : LongInt; SA, SB : String;
Begin
  If K = LvLocal Then Begin EA := @LocL^[A]; EB := @LocL^[B]; End
  Else Begin EA := @RemL^[A]; EB := @RemL^[B]; End;
  If EA^.Name = '..' Then Begin EntLess := True; Exit; End;
  If EB^.Name = '..' Then Begin EntLess := False; Exit; End;
  If EA^.Dir <> EB^.Dir Then
  Begin
    EntLess := EA^.Dir;
    Exit;
  End;
  C := 0;
  Case Lv[K].SortCol Of
    1 : If EA^.Size < EB^.Size Then C := -1 Else If EA^.Size > EB^.Size Then C := 1;
    2 : Begin
          SA := UpS(FileType(EA^)); SB := UpS(FileType(EB^));
          If SA < SB Then C := -1 Else If SA > SB Then C := 1;
        End;
    3 : If EA^.Time < EB^.Time Then C := -1 Else If EA^.Time > EB^.Time Then C := 1;
    4 : If EA^.Perm < EB^.Perm Then C := -1 Else If EA^.Perm > EB^.Perm Then C := 1;
    5 : If EA^.Owner < EB^.Owner Then C := -1 Else If EA^.Owner > EB^.Owner Then C := 1;
  End;
  If C = 0 Then
  Begin
    SA := UpS(EA^.Name); SB := UpS(EB^.Name);
    If SA < SB Then C := -1 Else If SA > SB Then C := 1;
  End;
  If Lv[K].SortDesc Then C := -C;
  EntLess := C < 0;
End;

{ tri de Shell des indices }
Procedure SortList(K : LongInt);
Var N, Gap, I, J, T : LongInt;
Begin
  If K = LvLocal Then N := LocN Else N := RemN;
  For I := 0 To N - 1 Do
    If K = LvLocal Then LocIdx[I] := I Else RemIdx[I] := I;
  Gap := N Div 2;
  While Gap > 0 Do
  Begin
    For I := Gap To N - 1 Do
    Begin
      If K = LvLocal Then T := LocIdx[I] Else T := RemIdx[I];
      J := I;
      While J >= Gap Do
      Begin
        If K = LvLocal Then
        Begin
          If Not EntLess(K, T, LocIdx[J - Gap]) Then Break;
          LocIdx[J] := LocIdx[J - Gap];
        End
        Else
        Begin
          If Not EntLess(K, T, RemIdx[J - Gap]) Then Break;
          RemIdx[J] := RemIdx[J - Gap];
        End;
        J := J - Gap;
      End;
      If K = LvLocal Then LocIdx[J] := T Else RemIdx[J] := T;
    End;
    Gap := Gap Div 2;
  End;
End;

{ ---- defilement ---- }

Procedure LvSync(K : LongInt);
Var M : LongInt;
Begin
  M := MaxI(0, LvCount(K) - LvRows(K));
  If Lv[K].Top > M Then Lv[K].Top := M;
  If Lv[K].Top < 0 Then Lv[K].Top := 0;
  SbSet(Lv[K].Sb, Lv[K].Top, M, LvRows(K));
End;

Procedure LvVisible(K : LongInt);
Begin
  If Lv[K].Cur < Lv[K].Top Then Lv[K].Top := Lv[K].Cur;
  If Lv[K].Cur >= Lv[K].Top + LvRows(K) Then
    Lv[K].Top := Lv[K].Cur - LvRows(K) + 1;
  LvSync(K);
End;

Procedure LvRepaint(K : LongInt);
Begin
  If Lv[K].H <> 0 Then Inval(Lv[K].H);
End;

{ liste rechargee : tri, selection effacee, debut }
Procedure LvReset(K : LongInt);
Begin
  If K <> LvQueue Then SortList(K) Else QFilter;
  LvClearSel(K);
  Lv[K].Top := 0; Lv[K].Cur := 0; Lv[K].Anchor := 0;
  LvSync(K);
  LvRepaint(K);
End;

{ ---- dessin ---- }

Procedure LvPaint(K, H : LongInt);
Var Dc, W, Ht, X, Y, I, C, R, N, Fg, Bg,
    Q, P : LongInt; S : String; Sel : Boolean;
Begin
  Dc := PaintBegin(H);
  W := Lv[K].W - SbW; Ht := Lv[K].Ht;
  LvCols(K, Lv[K].W);
  { en-tetes }
  X := 0;
  For C := 0 To ColN - 1 Do
  Begin
    Bar(Dc, X, 0, X + ColW[C], HH, ClrFace);
    Thin(Dc, X, 0, X + ColW[C], HH, True);
    S := Fit(ColT[C], ColW[C] - 14);
    Txt(Dc, X + 4, 2, S, ClrBlack);
    If (K <> LvQueue) And (Lv[K].SortCol = ColF[C]) Then
    Begin
      { fleche du tri }
      P := X + ColW[C] - 11;
      If Lv[K].SortDesc Then
      Begin
        Bar(Dc, P, 6, P + 7, 7, ClrShadow); Bar(Dc, P + 1, 7, P + 6, 8, ClrShadow);
        Bar(Dc, P + 2, 8, P + 5, 9, ClrShadow); Bar(Dc, P + 3, 9, P + 4, 10, ClrShadow);
      End
      Else
      Begin
        Bar(Dc, P + 3, 6, P + 4, 7, ClrShadow); Bar(Dc, P + 2, 7, P + 5, 8, ClrShadow);
        Bar(Dc, P + 1, 8, P + 6, 9, ClrShadow); Bar(Dc, P, 9, P + 7, 10, ClrShadow);
      End;
    End;
    X := X + ColW[C];
  End;
  Bar(Dc, X, 0, W, HH, ClrFace);
  N := LvCount(K);
  Y := HH;
  R := Lv[K].Top;
  While (Y < Ht) And (R < N) Do
  Begin
    Sel := LvSel(K, R);
    If Sel And Lv[K].Focus Then Begin Bg := ClrSel; Fg := ClrHi; End
    Else If Sel Then Begin Bg := ClrFace; Fg := ClrBlack; End
    Else Begin Bg := ClrWin; Fg := ClrBlack; End;
    Bar(Dc, 0, Y, W, Y + RH, Bg);
    X := 0;
    For C := 0 To ColN - 1 Do
    Begin
      S := CellText(K, R, ColF[C]);
      If (ColF[C] = 0) Then
      Begin
        IconFor(Dc, X + 2, Y + 1, LvE(K, R)^);
        Txt(Dc, X + 20, Y + 1, Fit(S, ColW[C] - 22), Fg);
      End
      Else If (ColF[C] = 14) And (Queue^[QIdx[R]].State = QsRun) Then
      Begin
        { barre de progression }
        Q := QIdx[R];
        Bar(Dc, X + 2, Y + 2, X + ColW[C] - 4, Y + RH - 2, ClrWin);
        Thin(Dc, X + 2, Y + 2, X + ColW[C] - 4, Y + RH - 2, False);
        If Queue^[Q].Size > 0 Then
          P := Trunc((ColW[C] - 8) * MinI(100, Trunc(Queue^[Q].Done * 100 / Queue^[Q].Size)) / 100)
        Else P := 0;
        Bar(Dc, X + 3, Y + 3, X + 3 + P, Y + RH - 3, ClrNavy);
        If Queue^[Q].Size > 0 Then
          S := IStr(MinI(100, Trunc(Queue^[Q].Done * 100 / Queue^[Q].Size))) + ' %'
        Else S := SizeTxt(Queue^[Q].Done);
        Txt(Dc, X + (ColW[C] - Length(S) * CW) Div 2, Y + 1, S, ClrBlack);
      End
      Else If ColA[C] = 1 Then
      Begin
        S := Fit(S, ColW[C] - 8);
        Txt(Dc, X + ColW[C] - 4 - Length(S) * CW, Y + 1, S, Fg);
      End
      Else
      Begin
        If (ColF[C] = 14) And (Queue^[QIdx[R]].State = QsFail) And Not Sel Then
          Txt(Dc, X + 4, Y + 1, Fit(S, ColW[C] - 8), ClrRed)
        Else Txt(Dc, X + 4, Y + 1, Fit(S, ColW[C] - 8), Fg);
      End;
      X := X + ColW[C];
    End;
    If (R = Lv[K].Cur) And Lv[K].Focus Then
    Begin
      { rectangle de l'element courant }
      Bar(Dc, 0, Y, W, Y + 1, ClrGray); Bar(Dc, 0, Y + RH - 1, W, Y + RH, ClrGray);
      Bar(Dc, 0, Y, 1, Y + RH, ClrGray); Bar(Dc, W - 1, Y, W, Y + RH, ClrGray);
    End;
    Y := Y + RH;
    Inc(R);
  End;
  Bar(Dc, 0, Y, W, Ht, ClrWin);
  If (K = LvRemote) And Not RemOk Then
    Txt(Dc, 12, HH + 12, 'Non connect'#233' '#224' un serveur', ClrGray)
  Else If (N = 0) And (K = LvQueue) Then
    Txt(Dc, 12, HH + 8, 'La file d''attente est vide.', ClrGray)
  Else If (N = 0) Then
    Txt(Dc, 12, HH + 12, 'Le dossier est vide.', ClrGray);
  PaintEnd(Dc);
End;

{ ---- souris et clavier ---- }

Function LvOf(H : LongInt) : LongInt;
Var K : LongInt;
Begin
  LvOf := -1;
  For K := 0 To 2 Do
    If Lv[K].H = H Then LvOf := K;
End;


Procedure LvSelectOnly(K, R : LongInt);
Begin
  LvClearSel(K);
  If (R >= 0) And (R < LvCount(K)) Then LvSetSel(K, R, True);
  Lv[K].Cur := R; Lv[K].Anchor := R;
End;

Procedure LvClick(K, R : LongInt; Ctrl, Shift : Boolean);
Var I : LongInt;
Begin
  If Ctrl Then
  Begin
    LvSetSel(K, R, Not LvSel(K, R));
    Lv[K].Cur := R; Lv[K].Anchor := R;
  End
  Else If Shift Then
  Begin
    LvClearSel(K);
    For I := MinI(R, Lv[K].Anchor) To MaxI(R, Lv[K].Anchor) Do LvSetSel(K, I, True);
    Lv[K].Cur := R;
  End
  Else LvSelectOnly(K, R);
  ListChanged(K);
End;

{ point (X, Y) de la liste K dans l'ecran }
Procedure LvToScreen(K : LongInt; Var X, Y : LongInt);
Begin
  ToScreen(Lv[K].H, X, Y);
End;

{ liste sous le point (ecran) ; -1 }
Function LvAt(X, Y : LongInt) : LongInt;
Var K, A, B : LongInt;
Begin
  LvAt := -1;
  For K := 0 To 2 Do
  Begin
    A := 0; B := 0;
    LvToScreen(K, A, B);
    If (X >= A) And (X < A + Lv[K].W) And (Y >= B) And (Y < B + Lv[K].Ht) Then
      LvAt := K;
  End;
End;

Procedure LvKey(K, VK : LongInt);
Var N, C, I : LongInt; Sh, Ct : Boolean;
Begin
  N := LvCount(K);
  Sh := KeyDown(VK_SHIFT); Ct := KeyDown(VK_CONTROL);
  C := Lv[K].Cur;
  Case VK Of
    VK_UP : Dec(C);
    VK_DOWN : Inc(C);
    VK_PRIOR : C := C - LvRows(K);
    VK_NEXT : C := C + LvRows(K);
    VK_HOME : C := 0;
    VK_END : C := N - 1;
    VK_RETURN :
    Begin
      ListOpen(K);
      Exit;
    End;
    VK_BACK : Begin ListCommand(K, 1); Exit; End;
    VK_DELETE : Begin ListCommand(K, 2); Exit; End;
    VK_F2 : Begin ListCommand(K, 3); Exit; End;
    VK_F5 : Begin ListCommand(K, 4); Exit; End;
    VK_TAB :
    Begin
      If K = LvLocal Then WFocus(Lv[LvRemote].H)
      Else WFocus(Lv[LvLocal].H);
      Exit;
    End;
    $41 :
      If Ct Then
      Begin
        For I := 0 To N - 1 Do
          If (K = LvQueue) Or (LvE(K, I)^.Name <> '..') Then LvSetSel(K, I, True);
        LvRepaint(K);
        ListChanged(K);
        Exit;
      End
      Else Exit;
  Else
    Exit;
  End;
  If N = 0 Then Exit;
  If C < 0 Then C := 0;
  If C >= N Then C := N - 1;
  If Sh Then
  Begin
    LvClearSel(K);
    For I := MinI(C, Lv[K].Anchor) To MaxI(C, Lv[K].Anchor) Do LvSetSel(K, I, True);
    Lv[K].Cur := C;
  End
  Else LvSelectOnly(K, C);
  LvVisible(K);
  LvRepaint(K);
  ListChanged(K);
End;

Function LvProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var K, X, Y, R, C, Code, M, I, T : LongInt;
Begin
  LvProc0 := 0;
  K := LvOf(H);
  If K < 0 Then
  Begin
    LvProc0 := 0;
    Exit;
  End;
  X := S16(LP); Y := S16(LP Shr 16);
  Case Msg Of
    WM_PAINT : LvPaint(K, H);
    WM_ERASEBKGND : LvProc0 := 1;
    WM_SIZE :
    Begin
      Lv[K].W := LP And $FFFF; Lv[K].Ht := (LP Shr 16) And $FFFF;
      If Lv[K].Sb <> 0 Then
        WPlace(Lv[K].Sb, Lv[K].W - SbW, 0, SbW, Lv[K].Ht);
      LvSync(K);
    End;
    WM_SETFOCUS :
    Begin
      Lv[K].Focus := True; LvRepaint(K);
    End;
    WM_KILLFOCUS :
    Begin
      Lv[K].Focus := False; LvRepaint(K);
    End;
    WM_VSCROLL :
    Begin
      Code := WP And $FFFF;
      Case Code Of
        0 : Dec(Lv[K].Top);
        1 : Inc(Lv[K].Top);
        2 : Lv[K].Top := Lv[K].Top - LvRows(K);
        3 : Lv[K].Top := Lv[K].Top + LvRows(K);
        4, 5 : Lv[K].Top := S16(WP Shr 16);
        8 : Lv[K].Top := SbPos(Lv[K].Sb);
      End;
      LvSync(K);
      LvRepaint(K);
    End;
    WM_MOUSEWHEEL :
    Begin
      If S16(WP Shr 16) > 0 Then Lv[K].Top := Lv[K].Top - 3
      Else Lv[K].Top := Lv[K].Top + 3;
      LvSync(K);
      LvRepaint(K);
    End;
    WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_LBUTTONDBLCLK :
    Begin
      WFocus(H);
      If (Y < HH) And (Msg = WM_LBUTTONDOWN) Then
      Begin
        { en-tete : tri }
        If K = LvQueue Then Exit;
        LvCols(K, Lv[K].W);
        T := 0;
        For C := 0 To ColN - 1 Do
        Begin
          If (X >= T) And (X < T + ColW[C]) Then
          Begin
            If Lv[K].SortCol = ColF[C] Then Lv[K].SortDesc := Not Lv[K].SortDesc
            Else
            Begin
              Lv[K].SortCol := ColF[C]; Lv[K].SortDesc := False;
            End;
          End;
          T := T + ColW[C];
        End;
        LvReset(K);
        ListChanged(K);
        Exit;
      End;
      R := Lv[K].Top + (Y - HH) Div RH;
      If (Y < HH) Or (R >= LvCount(K)) Then R := -1;
      If Msg = WM_LBUTTONDBLCLK Then
      Begin
        If R >= 0 Then
        Begin
          LvSelectOnly(K, R);
          LvRepaint(K);
          ListOpen(K);
        End;
        Exit;
      End;
      If R < 0 Then
      Begin
        LvClearSel(K);
        LvRepaint(K);
        ListChanged(K);
        If Msg = WM_RBUTTONDOWN Then
        Begin
          LvToScreen(K, X, Y);
          ListMenu(K, X, Y);
        End;
        Exit;
      End;
      If Msg = WM_RBUTTONDOWN Then
      Begin
        If Not LvSel(K, R) Then LvSelectOnly(K, R) Else Lv[K].Cur := R;
        LvRepaint(K);
        ListChanged(K);
        LvToScreen(K, X, Y);
        ListMenu(K, X, Y);
        Exit;
      End;
      If KeyDown(VK_CONTROL) Or KeyDown(VK_SHIFT) Or Not LvSel(K, R) Then
        LvClick(K, R, KeyDown(VK_CONTROL), KeyDown(VK_SHIFT))
      Else Lv[K].Cur := R;
      LvRepaint(K);
      If K <> LvQueue Then
      Begin
        DragFrom := K; DragOn := False; DragX := X; DragY := Y;
        Dummy := WinSetCapture(HWND_DESKTOP, H);
      End;
    End;
    WM_MOUSEMOVE :
      If DragFrom = K Then
        If (Abs(X - DragX) > 4) Or (Abs(Y - DragY) > 4) Then
        Begin
          If Not DragOn Then
          Begin
            DragOn := True;
            SetPtr(SPTR_MOVE);
          End;
        End;
    WM_LBUTTONUP :
      If DragFrom = K Then
      Begin
        Dummy := WinSetCapture(HWND_DESKTOP, 0);
        DragFrom := -1;
        If DragOn Then
        Begin
          DragOn := False;
          LvToScreen(K, X, Y);
          M := LvAt(X, Y);
          If (M >= 0) And (M <> K) Then ListDrop(K, M);
        End
        Else
        Begin
          { clic simple sur un element deja choisi : lui seul }
          R := Lv[K].Top + (Y - HH) Div RH;
          If (R >= 0) And (R < LvCount(K)) And Not KeyDown(VK_CONTROL) And
             Not KeyDown(VK_SHIFT) Then
          Begin
            LvSelectOnly(K, R);
            LvRepaint(K);
            ListChanged(K);
          End;
        End;
      End;
    WM_KEYDOWN : LvKey(K, WP);
  Else
    LvProc0 := 0;
  End;
End;

{ procedure de fenetre de PM des listes : messages de PM traduits en
  evenements de LvProc0 (souris : Y vers le bas ; clavier : touches de
  Pasdows) }
Function LvProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, V, Ch : LongInt;
Begin
  BigLock;
  LvProc := 0;
  Case Msg Of
    PM_WM_PAINT : Dummy0 := LvProc0(H, WM_PAINT, 0, 0);
    PM_WM_ERASEBACKGROUND : LvProc := 1;
    PM_WM_SIZE : Dummy0 := LvProc0(H, WM_SIZE, 0, Mp2);
    PM_WM_SETFOCUS :
      If (Mp2 And $FFFF) <> 0 Then Dummy0 := LvProc0(H, WM_SETFOCUS, 0, 0)
      Else Dummy0 := LvProc0(H, WM_KILLFOCUS, 0, 0);
    PM_WM_VSCROLL : Dummy0 := LvProc0(H, WM_VSCROLL, VsCode(Mp2), 0);
    PM_WM_BUTTON1DOWN :
    Begin
      Dummy0 := LvProc0(H, WM_LBUTTONDOWN, 0, MousePt(H, Mp1));
      LvProc := 1;
    End;
    PM_WM_BUTTON1DBLCLK :
    Begin
      Dummy0 := LvProc0(H, WM_LBUTTONDBLCLK, 0, MousePt(H, Mp1));
      LvProc := 1;
    End;
    PM_WM_BUTTON2DOWN :
    Begin
      Dummy0 := LvProc0(H, WM_RBUTTONDOWN, 0, MousePt(H, Mp1));
      LvProc := 1;
    End;
    PM_WM_BUTTON1UP :
    Begin
      Dummy0 := LvProc0(H, WM_LBUTTONUP, 0, MousePt(H, Mp1));
      LvProc := 1;
    End;
    PM_WM_MOUSEMOVE :
    Begin
      Dummy0 := LvProc0(H, WM_MOUSEMOVE, 0, MousePt(H, Mp1));
      If DragOn Then
      Begin
        SetPtr(SPTR_MOVE);
        LvProc := 1;
      End
      Else LvProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
    PM_WM_CHAR :
    Begin
      Fl := Mp1 And $FFFF; Ch := Mp2 And $FFFF; V := (Mp2 Shr 16) And $FFFF;
      If (Fl And PM_KC_KEYUP) <> 0 Then LvProc := WinDefWindowProc(H, Msg, Mp1, Mp2)
      Else If ((Fl And PM_KC_VIRTUALKEY) <> 0) And (VkOf(V) <> 0) Then
      Begin
        Dummy0 := LvProc0(H, WM_KEYDOWN, VkOf(V), 0);
        LvProc := 1;
      End
      Else If ((Fl And PM_KC_CTRL) <> 0) And ((Ch = 1) Or (UpCase(Chr(Ch And 255)) = 'A')) Then
      Begin
        Dummy0 := LvProc0(H, WM_KEYDOWN, $41, 0);
        LvProc := 1;
      End
      Else LvProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
  Else
    LvProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
  BigUnlock;
End;

{ ==================================================================== }
{ Site local : lecteurs et dossiers                                     }
{ ==================================================================== }

{ type d'un lecteur : 2 disquette, 3 disque local, 4 reseau, 5 CD-ROM }
Function DriveType(I : LongInt) : LongInt;
Var B : Array[0..299] Of Byte; Cb, N : LongInt; Fs : String;
Begin
  DriveType := 3;
  If I < 2 Then
  Begin
    DriveType := 2;
    Exit;
  End;
  Cb := 300;
  PutZ(LongInt(@NameZ2), Chr(65 + I) + ':');
  If DosQueryFSAttach(LongInt(@NameZ2), 0, 1, LongInt(@B), LongInt(@Cb)) <> 0 Then Exit;
  If (B[0] = 4) And (B[1] = 0) Then
  Begin
    DriveType := 4;
    Exit;
  End;
  N := B[2] Or (B[3] Shl 8);
  Fs := UpS(GetZ(LongInt(@B) + 8 + N + 1));
  If (Fs = 'CDFS') Or (Fs = 'ISO9660') Or (Fs = 'UDF') Then DriveType := 5;
End;

{ nom du volume (DosQueryFSInfo, niveau 2) }
Function VolLabel(I : LongInt) : String;
Var B : Array[0..63] Of Byte; S : String; K : LongInt;
Begin
  VolLabel := '';
  FillChar(B, SizeOf(B), 0);
  If DosQueryFSInfo(I + 1, 2, LongInt(@B), 64) <> 0 Then Exit;
  S := '';
  For K := 1 To MinI(B[4], 32) Do S := S + Chr(B[4 + K]);
  While (S <> '') And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
  VolLabel := UnDisp(S);
End;

Procedure LocalRead;
Var F : TFf; M, I, A, Cur : LongInt; Nm : String;
    E : TEntry;
Begin
  LocN := 0;
  If LocPath = '' Then
  Begin
    Cur := 0; M := 0;
    Dummy0 := DosQueryCurrentDisk(LongInt(@Cur), LongInt(@M));
    For I := 0 To 25 Do
      If ((M Shr I) And 1) <> 0 Then
      Begin
        E.Name := Chr(65 + I) + ':'; E.Dir := True; E.Link := False;
        E.Size := 0; E.Time := '';
        Case DriveType(I) Of
          2 : E.Perm := 'Disquette';
          4 : E.Perm := 'Lecteur r'#233'seau';
          5 : E.Perm := 'CD-ROM';
        Else
          E.Perm := 'Disque local';
        End;
        E.Owner := '';
        If I >= 2 Then E.Owner := VolLabel(I);
        If LocN < MaxEnt Then Begin LocL^[LocN] := E; Inc(LocN); End;
      End;
    Exit;
  End;
  E.Name := '..'; E.Dir := True; E.Link := False; E.Size := 0; E.Time := '';
  E.Perm := ''; E.Owner := '';
  LocL^[0] := E; LocN := 1;
  If Not FfFirst(LJoin(LocPath, '*'), F) Then
  Begin
    FfClose(F);
    Exit;
  End;
  Repeat
    Nm := UnDisp(FfName(F));
    A := FfAttr(F);
    If (Nm <> '.') And (Nm <> '..') And (Nm <> '') And
       (ShowHidden Or ((A And 2) = 0)) Then
    Begin
      E.Name := Nm;
      E.Dir := (A And $10) <> 0;
      E.Size := FfSize(F);
      E.Time := FfTime(F);
      E.Perm := ''; E.Owner := '';
      If (A And 1) <> 0 Then E.Perm := 'lecture seule';
      If LocN < MaxEnt Then Begin LocL^[LocN] := E; Inc(LocN); End;
    End;
  Until Not FfNext(F);
  FfClose(F);
End;
{ ==================================================================== }
{ Tache reseau : commandes, connexion, transferts                       }
{ ==================================================================== }

Const
  OpConnect = 1; OpList = 2; OpCd = 3; OpMkdir = 4; OpDelete = 5;
  OpRename = 6; OpDisconnect = 7; OpRaw = 8; OpChmod = 9;
  OvAsk = 0; OvOver = 1; OvSkip = 2; OvNewer = 3;

Type
  TCmd = Record
    Op, N : LongInt;
    A, B : String;
  End;

Var
  Cmds : Array[0..31] Of TCmd;
  CmdN : LongInt;
  WorkEv, WorkTh : LongInt;
  CurSite : TSite;                       { site de la connexion }
  HaveSite, Connected, Busy, AppQuit : Boolean;
  QRun : Boolean;                        { traitement de la file }
  QCur : LongInt;                        { element en cours (-1) }
  QStart, QLastPost, QBytes0 : LongInt;
  QSpeed : Double;
  OverMode : LongInt;
  DelNames : PEntArr;                    { a supprimer (copie) }
  DelN : LongInt;
  NsBuf : TlPtr;                         { pile de noms (suppression) }
  NsLen : LongInt;
  WkZ : Array[0..2047] Of Byte;          { textes de la tache reseau }
  WkZ2 : Array[0..127] Of Byte;
  AskEv, AskFl, AskRes : LongInt;        { boite du fil reseau }
  WkZN : LongInt;
  PendLocal : String;                    { dossier local du site }
  QUpDone : Boolean;                     { envois dans le dossier affiche }

Procedure PostState;
Begin
  Dummy := WinPostMsg(MainWnd, WM_NETSTATE, 0, 0);
End;

Procedure PostQueue;
Begin
  Dummy := WinPostMsg(MainWnd, WM_NETQUEUE, 0, 0);
End;

{ ajoute une commande (interface, verrou tenu) }
Procedure AddCmd(Op : LongInt; A, B : String; N : LongInt);
Begin
  If CmdN >= 32 Then Exit;
  Cmds[CmdN].Op := Op; Cmds[CmdN].A := A; Cmds[CmdN].B := B;
  Cmds[CmdN].N := N;
  Inc(CmdN);
  Dummy := DosPostEventSem(WorkEv);
End;

{ texte long pour une boite de message de la tache reseau }
Procedure WkStart;
Begin
  WkZN := 0; WkZ[0] := 0;
End;

Procedure WkAdd(S : String);
Var I : LongInt;
Begin
  S := Disp(S);
  For I := 1 To Length(S) Do
    If WkZN < 2040 Then
    Begin
      If S[I] = '|' Then WkZ[WkZN] := 10 Else WkZ[WkZN] := Ord(S[I]);
      Inc(WkZN);
    End;
  WkZ[WkZN] := 0;
End;

{ la boite est affichee par le fil de l'interface (WM_NETASK) : le fil
  reseau attend sa reponse (semaphore AskEv), verrou libere }
Function WkBox(Cap : String; Fl : LongInt) : LongInt;
Var D, N : LongInt;
Begin
  PutZ(LongInt(@WkZ2[0]), Disp(Cap));
  AskFl := MbFlags(Fl); AskRes := IDCANCEL;
  N := 0;
  Dummy0 := DosResetEventSem(AskEv, LongInt(@N));
  Dummy0 := WinPostMsg(MainWnd, WM_NETASK, 0, 0);
  D := LockDepthRelease;
  Dummy0 := DosWaitEventSem(AskEv, -1);
  LockDepthRestore(D);
  WkBox := AskRes;
End;

{ cle d'hote inconnue ou changee : 0 refuser, 1 cette fois, 2 toujours }
Function HostAsk(Fp, Alg : String; Changed : Boolean) : LongInt;
Var R : LongInt;
Begin
  WkStart;
  If Changed Then
  Begin
    WkAdd('ATTENTION : la cl'#233' d''h'#244'te du serveur a chang'#233' !||');
    WkAdd('Elle ne correspond plus a celle qui a ete memorisee. Il peut s''agir ');
    WkAdd('d''une attaque (un autre ordinateur se fait passer pour le serveur) ');
    WkAdd('ou d''une reinstallation du serveur.||');
  End
  Else
  Begin
    WkAdd('La cl'#233' d''h'#244'te du serveur est inconnue. Vous n''avez aucune ');
    WkAdd('garantie que le serveur est bien l''ordinateur que vous pensez.||');
  End;
  WkAdd('Serveur : ' + SsHost + ':' + IStr(SsPort) + '|');
  WkAdd('Type de cl'#233' : ' + Alg + '|');
  WkAdd('Empreinte : ' + Fp + '||');
  WkAdd('Faire confiance '#224' cet h'#244'te et poursuivre la connexion ?||');
  WkAdd('Oui : toujours faire confiance '#224' cet h'#244'te|');
  WkAdd('Non : faire confiance pour cette fois seulement|');
  WkAdd('Annuler : ne pas se connecter');
  R := WkBox('Cl'#233' d''h'#244'te', MB_YESNOCANCEL Or MB_ICONWARNING);
  If R = IDYES Then HostAsk := 2
  Else If R = IDNO Then HostAsk := 1
  Else HostAsk := 0;
End;

{ progression : appele par les protocoles apres chaque bloc }
Procedure XferStep;
Var T, D : LongInt;
Begin
  If (QCur >= 0) And (QCur < QN) Then Queue^[QCur].Done := XfDone;
  T := MsCount;
  If T - QLastPost > 250 Then
  Begin
    QLastPost := T;
    If T > QStart Then QSpeed := XfDone * 1000.0 / (T - QStart);
    Dummy := WinPostMsg(MainWnd, WM_NETQUEUE, 1, 0);
    { la section critique n'est pas equitable : sur un reseau rapide le
      thread de travail la reprendrait aussitot ; laisser l'interface
      traiter ses messages (progression, Annuler) }
    D := LockDepthRelease;
    Dummy0 := DosSleep(20);
    LockDepthRestore(D);
  End;
End;

Procedure LostCheck;
Begin
  If SsLost And Connected Then
  Begin
    LogMsg(LgError, 'Connexion perdue avec le serveur.');
    SsClose;
    Connected := False;
    PostState;
  End;
End;

{ ---- liste distante ---- }

Procedure ShowRemote(N : LongInt);
Var I : LongInt; E : TEntry;
Begin
  RemN := 0;
  If (SsCwd <> '/') And (SsCwd <> '') Then
  Begin
    E.Name := '..'; E.Dir := True; E.Link := False; E.Size := 0; E.Time := '';
    E.Perm := ''; E.Owner := '';
    RemL^[0] := E; RemN := 1;
  End;
  For I := 0 To N - 1 Do
    If (RemN < MaxEnt) And (ShowHidden Or (TmpL^[I].Name[1] <> '.')) Then
    Begin
      RemL^[RemN] := TmpL^[I]; Inc(RemN);
    End;
  RemPath := SsCwd;
  RemOk := True;
  Dummy := WinPostMsg(MainWnd, WM_NETLIST, 0, 0);
End;

Function DoList : Boolean;
Var N : LongInt;
Begin
  DoList := False;
  If Not SsList(TmpL, N) Then
  Begin
    LogMsg(LgError, SsErr);
    LostCheck;
    Exit;
  End;
  ShowRemote(N);
  DoList := True;
End;

{ ---- connexion ---- }

Function DoConnect : Boolean;
Begin
  DoConnect := False;
  If Connected Then
  Begin
    SsClose;
    Connected := False;
  End;
  RemOk := False; RemN := 0;
  Dummy := WinPostMsg(MainWnd, WM_NETLIST, 0, 0);
  SsProto := CurSite.Proto; SsHost := CurSite.Host; SsPort := CurSite.Port;
  If CurSite.Logon = LgAnon Then
  Begin
    SsUser := 'anonymous'; SsPass := 'anonymous@';
  End
  Else
  Begin
    SsUser := CurSite.User; SsPass := CurSite.Pass;
  End;
  Connected := False;
  PostState;
  If Not SsConnect Then
  Begin
    LogMsg(LgError, SsErr);
    LogMsg(LgError, 'Impossible d'''#233'tablir une connexion au serveur');
    PostState;
    Exit;
  End;
  Connected := True;
  PostState;
  If CurSite.RemDir <> '' Then
    If Not SsCd(CurSite.RemDir) Then LogMsg(LgError, SsErr);
  If CurSite.LocDir <> '' Then
  Begin
    PendLocal := CurSite.LocDir;
    Dummy := WinPostMsg(MainWnd, WM_NETLOCAL, 1, 0);
  End;
  DoConnect := DoList;
End;

{ reconnexion apres une coupure (file d'attente, commandes) }
Function Ensure : Boolean;
Begin
  Ensure := Connected;
  If Connected Or Not HaveSite Then Exit;
  LogMsg(LgStatus, 'Reconnexion au serveur...');
  Ensure := DoConnect;
End;

{ ---- suppression recursive ---- }

Procedure NsPush(S : String; Dir : Boolean);
Var I : LongInt;
Begin
  If NsBuf = 0 Then NsBuf := TlNew(262144);
  If NsLen + Length(S) + 2 > 262144 Then Exit;
  TlPut(NsBuf + NsLen, Length(S)); TlPut(NsBuf + NsLen + 1, Ord(Dir));
  For I := 1 To Length(S) Do TlPut(NsBuf + NsLen + 1 + I, Ord(S[I]));
  NsLen := NsLen + Length(S) + 2;
End;

Function RDelete(P : String; IsDir : Boolean; Depth : LongInt) : Boolean;
Var St, N, I, Pos0, L : LongInt; Nm : String; D : Boolean;
Begin
  RDelete := False;
  If Not IsDir Then
  Begin
    If SsOp(3, P) Then RDelete := True Else LogMsg(LgError, SsErr);
    Exit;
  End;
  If Depth > 16 Then Exit;
  If Not SsListPath(P, TmpL, N) Then
  Begin
    LogMsg(LgError, SsErr);
    Exit;
  End;
  St := NsLen;
  For I := 0 To N - 1 Do NsPush(TmpL^[I].Name, TmpL^[I].Dir And Not TmpL^[I].Link);
  Pos0 := St;
  While Pos0 < NsLen Do
  Begin
    L := TlGet(NsBuf + Pos0); D := TlGet(NsBuf + Pos0 + 1) <> 0;
    Nm := '';
    For I := 1 To L Do Nm := Nm + Chr(TlGet(NsBuf + Pos0 + 1 + I));
    Pos0 := Pos0 + L + 2;
    If Not RDelete(RJoin(P, Nm), D, Depth + 1) Then
    Begin
      NsLen := St;
      Exit;
    End;
  End;
  NsLen := St;
  If SsOp(2, P) Then RDelete := True Else LogMsg(LgError, SsErr);
End;

{ ---- file d'attente ---- }

Function QNext : LongInt;
Var I : LongInt;
Begin
  QNext := -1;
  For I := 0 To QN - 1 Do
    If Queue^[I].State = QsWait Then
    Begin
      QNext := I;
      Exit;
    End;
End;

{ insere un element apres At (dossiers telecharges) }
Procedure QInsert(At, Kind : LongInt; Loc, Rem : String; Size : Double);
Var I : LongInt;
Begin
  If QN >= MaxQ Then Exit;
  For I := QN - 1 DownTo At + 1 Do Queue^[I + 1] := Queue^[I];
  Inc(QN);
  Queue^[At + 1].Kind := Kind; Queue^[At + 1].State := QsWait;
  Queue^[At + 1].Loc := Loc; Queue^[At + 1].Rem := Rem;
  Queue^[At + 1].Size := Size; Queue^[At + 1].Done := 0;
  Queue^[At + 1].Err := '';
End;

{ le fichier cible existe : True s'il faut le transferer }
Function OverOk(Name : String; Down : Boolean) : Boolean;
Var R : LongInt;
Begin
  OverOk := True;
  If OverMode = OvOver Then Exit;
  If OverMode = OvSkip Then
  Begin
    OverOk := False;
    Exit;
  End;
  WkStart;
  WkAdd('Le fichier cible existe d'#233'j'#224' :|' + Name + '||');
  WkAdd('Voulez-vous le remplacer ?||');
  WkAdd('Oui : remplacer le fichier|Non : ignorer ce fichier|');
  WkAdd('Annuler : arr'#234'ter la file d''attente||');
  WkAdd('(Transfert, Fichier existant : pour toujours remplacer ou ignorer)');
  R := WkBox('Le fichier cible existe d'#233'j'#224, MB_YESNOCANCEL Or MB_ICONQUESTION);
  If R = IDNO Then OverOk := False
  Else If R <> IDYES Then
  Begin
    OverOk := False;
    QRun := False;
  End;
End;

Function RemoteExists(Rem : String) : Boolean;
Var I : LongInt; P : String;
Begin
  RemoteExists := False;
  P := RParent(Rem);
  If Not RemOk Or (P <> RemPath) Then Exit;
  For I := 0 To RemN - 1 Do
    If RemL^[I].Name = BaseOf(Rem) Then RemoteExists := True;
End;

Procedure DoQueueItem(I : LongInt);
Var Ok, Skip : Boolean; N, K : LongInt; E : TEntry;
Begin
  If Not Ensure Then
  Begin
    Queue^[I].State := QsFail;
    Queue^[I].Err := 'Pas de connexion au serveur';
    QRun := False;
    PostQueue;
    Exit;
  End;
  QCur := I;
  Queue^[I].State := QsRun; Queue^[I].Done := 0;
  QStart := MsCount; QLastPost := 0; QSpeed := 0;
  PostQueue;
  Ok := False; Skip := False;
  Case Queue^[I].Kind Of
    QkDown :
    Begin
      If FAttr(Queue^[I].Loc) <> -1 Then
        Skip := Not OverOk(Queue^[I].Loc, True);
      If Not Skip Then
      Begin
        LogMsg(LgStatus, 'T'#233'l'#233'chargement de ' + Queue^[I].Rem + '...');
        Ok := SsGet(Queue^[I].Rem, Queue^[I].Loc);
        If Not Ok And SsLost Then
        Begin
          LostCheck;
          If Ensure Then Ok := SsGet(Queue^[I].Rem, Queue^[I].Loc);
        End;
      End;
    End;
    QkUp :
    Begin
      If RemoteExists(Queue^[I].Rem) Then
        Skip := Not OverOk(Queue^[I].Rem, False);
      If Not Skip Then
      Begin
        LogMsg(LgStatus, 'Envoi de ' + Queue^[I].Loc + '...');
        Ok := SsPut(Queue^[I].Loc, Queue^[I].Rem);
        If Not Ok And SsLost Then
        Begin
          LostCheck;
          If Ensure Then Ok := SsPut(Queue^[I].Loc, Queue^[I].Rem);
        End;
        If Ok And (RParent(Queue^[I].Rem) = RemPath) Then QUpDone := True;
      End;
    End;
    QkMkdir :
    Begin
      { le dossier peut deja exister }
      If Not SsOp(1, Queue^[I].Rem) Then
        LogMsg(LgStatus, 'Dossier ' + Queue^[I].Rem + ' : ' + SsErr);
      Ok := Not SsLost;
      If RParent(Queue^[I].Rem) = RemPath Then QUpDone := True;
    End;
    QkDownDir :
    Begin
      Ok := SsListPath(Queue^[I].Rem, TmpL, N);
      If Ok Then
      Begin
        Dummy := Ord(MkDir(Queue^[I].Loc));
        For K := N - 1 DownTo 0 Do
        Begin
          E := TmpL^[K];
          If E.Dir And Not E.Link Then
            QInsert(I, QkDownDir, LJoin(Queue^[I].Loc, E.Name), RJoin(Queue^[I].Rem, E.Name), 0)
          Else
            QInsert(I, QkDown, LJoin(Queue^[I].Loc, E.Name), RJoin(Queue^[I].Rem, E.Name), E.Size);
        End;
      End;
    End;
  End;
  If Skip Then
  Begin
    Queue^[I].State := QsOk;
    Queue^[I].Err := 'Ignor'#233;
  End
  Else If Ok Then
  Begin
    Queue^[I].State := QsOk;
    Queue^[I].Done := Queue^[I].Size;
    If Queue^[I].Kind In [QkDown, QkUp] Then
      LogMsg(LgStatus, 'Transfert r'#233'ussi : ' + Group(DStr(XfDone)) + ' octets en ' +
             IStr((MsCount - QStart) Div 1000) + ' s');
  End
  Else
  Begin
    Queue^[I].State := QsFail;
    Queue^[I].Err := SsErr;
    LogMsg(LgError, SsErr);
    LostCheck;
  End;
  QCur := -1;
  If Queue^[I].Kind In [QkDown, QkDownDir] Then
    Dummy := WinPostMsg(MainWnd, WM_NETLOCAL, 0, 0);
  PostQueue;
End;

{ ---- commandes ---- }

Procedure DoCmd(Var C : TCmd);
Var I, N : LongInt; Ok : Boolean;
Begin
  Case C.Op Of
    OpConnect : If DoConnect Then;
    OpDisconnect :
    Begin
      If Connected Then
      Begin
        SsClose;
        LogMsg(LgStatus, 'D'#233'connect'#233' du serveur');
      End;
      Connected := False; RemOk := False; RemN := 0; HaveSite := False;
      QRun := False;
      Dummy := WinPostMsg(MainWnd, WM_NETLIST, 0, 0);
      PostState;
    End;
    OpList :
      If Ensure Then
        If Not DoList Then
          If Ensure Then If DoList Then;
    OpCd :
      If Ensure Then
      Begin
        If SsCd(C.A) Then
        Begin
          If DoList Then;
        End
        Else
        Begin
          LogMsg(LgError, SsErr);
          LostCheck;
        End;
      End;
    OpMkdir :
      If Ensure Then
      Begin
        If SsOp(1, C.A) Then LogMsg(LgStatus, 'Dossier cr'#233#233' : ' + C.A)
        Else LogMsg(LgError, SsErr);
        If DoList Then;
      End;
    OpRename :
      If Ensure Then
      Begin
        If SsRename(C.A, C.B) Then
          LogMsg(LgStatus, C.A + ' renomm'#233' en ' + C.B)
        Else LogMsg(LgError, SsErr);
        If DoList Then;
      End;
    OpChmod :
      If Ensure Then
      Begin
        If SsChmod(C.A, C.N) Then
          LogMsg(LgStatus, 'Droits de ' + C.A + ' : ' + PermStr(C.N))
        Else LogMsg(LgError, SsErr);
        If DoList Then;
      End;
    OpDelete :
      If Ensure Then
      Begin
        N := DelN;
        For I := 0 To N - 1 Do
        Begin
          Ok := RDelete(RJoin(RemPath, DelNames^[I].Name), DelNames^[I].Dir And Not DelNames^[I].Link, 0);
          If Ok Then LogMsg(LgStatus, 'Supprim'#233' : ' + DelNames^[I].Name);
          If SsLost Then Break;
        End;
        LostCheck;
        If Connected Then If DoList Then;
      End;
    OpRaw :
      If Ensure Then
      Begin
        If Not SsRaw(C.A) Then LogMsg(LgError, SsErr);
        LostCheck;
      End;
  End;
End;

Function WorkThread(P : LongInt) : LongInt;
Var C : TCmd; I, Nx : LongInt;
Begin
  BigLock;
  While Not AppQuit Do
  Begin
    If CmdN > 0 Then
    Begin
      C := Cmds[0];
      For I := 1 To CmdN - 1 Do Cmds[I - 1] := Cmds[I];
      Dec(CmdN);
      Busy := True;
      PostState;
      DoCmd(C);
      Busy := False;
      PostState;
    End
    Else
    Begin
      Nx := -1;
      If QRun Then Nx := QNext;
      If Nx >= 0 Then
      Begin
        Busy := True;
        PostState;
        DoQueueItem(Nx);
        Busy := False;
        If QNext < 0 Then
        Begin
          QRun := False;
          LogMsg(LgStatus, 'Tous les transferts sont termin'#233's.');
          If QUpDone And Connected Then
          Begin
            QUpDone := False;
            If DoList Then;
          End;
        End;
        PostState;
      End
      Else
      Begin
        BigUnlock;
        Dummy0 := DosWaitEventSem(WorkEv, 1000);
        Dummy0 := DosResetEventSem(WorkEv, LongInt(@Nx));
        BigLock;
      End;
    End;
  End;
  If Connected Then SsClose;
  BigUnlock;
  WorkThread := 0;
End;
{ ==================================================================== }
{ Boites de dialogue                                                    }
{ ==================================================================== }

Const
  DkInput = 1; DkSites = 2; DkChmod = 3;
  IdName = 101; IdProtoF = 102; IdProtoS = 103; IdHost = 104; IdPort = 105;
  IdAnon = 106; IdNormal = 107; IdAskPw = 108; IdUser = 109; IdPass = 110;
  IdFolder = 111; IdLocDir = 112; IdRemDir = 113; IdComment = 114;
  IdList = 115; IdNew = 116; IdDel = 117; IdDup = 118; IdConn = 119;
  IdInput = 120; IdNum = 121; IdChk = 130;

Var
  DlgWnd, DlgFrame, DlgKind, DlgRes, DlgDef : LongInt;
  DlgDone : Boolean;
  DlgText, DlgPrompt : String;
  SmCur : LongInt;                     { site affiche }
  SmCtl : Array[100..130] Of LongInt;
  ChMode : LongInt;
  ChBox : Array[0..8] Of LongInt;
  ChSync : Boolean;
  InpEdit : LongInt;
  SmFilling : Boolean;
  DlgPrevFocus : LongInt;


{ boucle modale : la fenetre principale est desactivee ; le verrou est
  libere pendant l'attente des messages }
Procedure ModalLoop;
Var D : LongInt;
Begin
  Dummy0 := WinEnableWindow(MainFrame, 0);
  While Not DlgDone Do
  Begin
    D := LockDepthRelease;
    If WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) = 0 Then
    Begin
      LockDepthRestore(D);
      Break;
    End;
    LockDepthRestore(D);
    Dummy0 := WinDispatchMsg(Hab, LongInt(@Qmsg));
  End;
  Dummy0 := WinEnableWindow(MainFrame, 1);
  If DlgFrame <> 0 Then Dummy0 := WinDestroyWindow(DlgFrame);
  DlgWnd := 0; DlgFrame := 0;
  Dummy0 := WinSetActiveWindow(HWND_DESKTOP, MainFrame);
  { le focus revient au controle qui l'avait avant la boite }
  If (DlgPrevFocus <> 0) And (WinIsWindow(Hab, DlgPrevFocus) <> 0) Then WFocus(DlgPrevFocus) Else WFocus(MainWnd);
End;

{ boite de dialogue : cadre de PM (titre, menu systeme, bordure de
  dialogue) centre, zone client de W x H ; DlgWnd est la zone client,
  parent des controles (cache jusqu'a DlgShow) }
Function DlgCreate(Title : String; W, H : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Fw, Fh, Fl : LongInt;
Begin
  DlgDone := False; DlgRes := IDCANCEL; DlgDef := IDOK;
  DlgPrevFocus := WinQueryFocus(HWND_DESKTOP);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DlgWnd := 0;
  DlgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z2('PFDLG'), Z(Disp(Title)), 0, 0, 0,
                                 LongInt(@DlgWnd));
  If DlgFrame = 0 Then
  Begin
    DlgCreate := 0;
    Exit;
  End;
  Rc[0] := 0; Rc[1] := 0; Rc[2] := W; Rc[3] := H;
  Dummy0 := WinCalcFrameRect(DlgFrame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Dummy0 := WinSetWindowPos(DlgFrame, HWND_TOP, MaxI(0, (ScrW - Fw) Div 2), MaxI(0, (ScrH - Fh) Div 2), Fw, Fh,
                            SWP_SIZE Or SWP_MOVE);
  DlgCreate := DlgWnd;
End;

{ affiche la boite (cadre active au premier plan) }
Procedure DlgShow;
Begin
  Dummy0 := WinSetWindowPos(DlgFrame, HWND_TOP, 0, 0, 0, 0, SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy0 := WinSetActiveWindow(HWND_DESKTOP, DlgFrame);
  WFocus(DlgWnd);
End;

Procedure Lbl(P : LongInt; S : String; X, Y, W : LongInt);
Begin
  Dummy := Ctl(P, 'STATIC', S, 0, X, Y, W, 16, 0);
End;

{ ---- saisie d'un texte ---- }

Function InputBox(Title, Prompt : String; Var S : String; Pw : Boolean) : Boolean;
Var E, W : LongInt;
Begin
  InputBox := False;
  DlgKind := DkInput;
  W := MaxI(320, Length(Prompt) * CW + 24);
  If W > ScrW - 20 Then W := ScrW - 20;
  If DlgCreate(Title, W, 104) = 0 Then Exit;
  Lbl(DlgWnd, Prompt, 12, 10, W - 24);
  If Pw Then
    E := Ctl(DlgWnd, 'EDIT', S, WS_BORDER Or ES_AUTOHSCROLL Or ES_PASSWORD Or WS_TABSTOP, 12, 32, W - 24, 20, IdInput)
  Else E := Ctl(DlgWnd, 'EDIT', S, WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 12, 32, W - 24, 20, IdInput);
  InpEdit := E;
  Dummy := Ctl(DlgWnd, 'BUTTON', 'OK', BS_DEFPUSHBUTTON Or WS_TABSTOP, W - 184, 66, 84, 26, IDOK);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Annuler', WS_TABSTOP, W - 94, 66, 84, 26, IDCANCEL);
  DlgShow;
  WFocus(E);
  SelAllText(E);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    S := DlgText;
    InputBox := True;
  End;
End;

{ ---- gestionnaire de sites ---- }

Function SmName(I : LongInt) : String;
Begin
  If Sites^[I].Folder <> '' Then SmName := Sites^[I].Folder + ' / ' + Sites^[I].Name
  Else SmName := Sites^[I].Name;
End;

Procedure SmFill;
Var I : LongInt;
Begin
  SmFilling := True;
  Dummy := WinSendMsg(SmCtl[IdList], PM_LM_DELETEALL, 0, 0);
  For I := 0 To SiteN - 1 Do
    Dummy := WinSendMsg(SmCtl[IdList], PM_LM_INSERTITEM, -1, Z(Disp(SmName(I))));
  If (SmCur >= 0) And (SmCur < SiteN) Then
    Dummy := WinSendMsg(SmCtl[IdList], PM_LM_SELECTITEM, SmCur, 1);
  SmFilling := False;
End;

Procedure SmEnable;
Var I : LongInt; On : Boolean;
Begin
  On := (SmCur >= 0) And (SmCur < SiteN);
  For I := IdName To IdComment Do
    If SmCtl[I] <> 0 Then Dummy := WinEnableWindow(SmCtl[I], Ord(On));
  Dummy := WinEnableWindow(SmCtl[IdDel], Ord(On));
  Dummy := WinEnableWindow(SmCtl[IdDup], Ord(On));
  Dummy := WinEnableWindow(SmCtl[IdConn], Ord(On));
  If On Then
  Begin
    Dummy := WinEnableWindow(SmCtl[IdUser], Ord(Not Checked(SmCtl[IdAnon])));
    Dummy := WinEnableWindow(SmCtl[IdPass], Ord(Checked(SmCtl[IdNormal])));
  End;
End;

Procedure SmLoad;
Var S : TSite;
Begin
  If (SmCur < 0) Or (SmCur >= SiteN) Then
  Begin
    SiteClear(S); S.Port := 0;
  End
  Else S := Sites^[SmCur];
  SetText(SmCtl[IdName], S.Name);
  SetCheck(SmCtl[IdProtoF], S.Proto = PrFtp);
  SetCheck(SmCtl[IdProtoS], S.Proto = PrSftp);
  SetText(SmCtl[IdHost], S.Host);
  If S.Port > 0 Then SetText(SmCtl[IdPort], IStr(S.Port)) Else SetText(SmCtl[IdPort], '');
  SetCheck(SmCtl[IdAnon], S.Logon = LgAnon);
  SetCheck(SmCtl[IdNormal], S.Logon = LgNormal);
  SetCheck(SmCtl[IdAskPw], S.Logon = LgAsk);
  SetText(SmCtl[IdUser], S.User);
  SetText(SmCtl[IdPass], S.Pass);
  SetText(SmCtl[IdFolder], S.Folder);
  SetText(SmCtl[IdLocDir], S.LocDir);
  SetText(SmCtl[IdRemDir], S.RemDir);
  SetText(SmCtl[IdComment], S.Comment);
  SmEnable;
End;

Procedure SmSave;
Var S : TSite;
Begin
  If (SmCur < 0) Or (SmCur >= SiteN) Then Exit;
  S := Sites^[SmCur];
  S.Name := TrimS(CtlText(SmCtl[IdName]));
  If S.Name = '' Then S.Name := 'Nouveau site';
  If Checked(SmCtl[IdProtoS]) Then S.Proto := PrSftp Else S.Proto := PrFtp;
  S.Host := TrimS(CtlText(SmCtl[IdHost]));
  S.Port := SVal(TrimS(CtlText(SmCtl[IdPort])));
  If S.Port <= 0 Then
    If S.Proto = PrSftp Then S.Port := 22 Else S.Port := 21;
  If Checked(SmCtl[IdAnon]) Then S.Logon := LgAnon
  Else If Checked(SmCtl[IdAskPw]) Then S.Logon := LgAsk
  Else S.Logon := LgNormal;
  S.User := CtlText(SmCtl[IdUser]);
  S.Pass := CtlText(SmCtl[IdPass]);
  If S.Logon <> LgNormal Then S.Pass := '';
  S.Folder := TrimS(CtlText(SmCtl[IdFolder]));
  S.LocDir := TrimS(CtlText(SmCtl[IdLocDir]));
  S.RemDir := TrimS(CtlText(SmCtl[IdRemDir]));
  S.Comment := CtlText(SmCtl[IdComment]);
  Sites^[SmCur] := S;
End;

Procedure SmSelect(I : LongInt);
Begin
  SmSave;
  SmCur := I;
  SmFill;
  SmLoad;
End;

Procedure SmCommand(Id, Code : LongInt);
Var I : LongInt; Nm : String;
Begin
  Case Id Of
    IdList :
      If Code = LBN_SELCHANGE Then
      Begin
        I := WinSendMsg(SmCtl[IdList], PM_LM_QUERYSELECTION, -1, 0);
        If (I >= 0) And (I < SiteN) And (I <> SmCur) And Not SmFilling Then SmSelect(I);
      End
      Else If Code = LBN_DBLCLK Then SmCommand(IdConn, 0);
    IdNew :
      If SiteN < MaxSite Then
      Begin
        SmSave;
        SiteClear(Sites^[SiteN]);
        Sites^[SiteN].Name := 'Nouveau site';
        If (SmCur >= 0) And (SmCur < SiteN) Then
          Sites^[SiteN].Folder := Sites^[SmCur].Folder;
        Inc(SiteN);
        SmCur := SiteN - 1;
        SmFill; SmLoad;
        WFocus(SmCtl[IdName]);
        SelAllText(SmCtl[IdName]);
      End;
    IdDup :
      If (SmCur >= 0) And (SiteN < MaxSite) Then
      Begin
        SmSave;
        Sites^[SiteN] := Sites^[SmCur];
        Sites^[SiteN].Name := 'Copie de ' + Sites^[SmCur].Name;
        Inc(SiteN);
        SmCur := SiteN - 1;
        SmFill; SmLoad;
      End;
    IdDel :
      If (SmCur >= 0) And (SmCur < SiteN) Then
      Begin
        Nm := Sites^[SmCur].Name;
        If MsgBox(DlgFrame, 'Voulez-vous vraiment supprimer le site "' + Nm + '" ?', 'Gestionnaire de sites',
                  MB_YESNO Or MB_ICONQUESTION) = IDYES Then
        Begin
          For I := SmCur To SiteN - 2 Do Sites^[I] := Sites^[I + 1];
          Dec(SiteN);
          If SmCur >= SiteN Then SmCur := SiteN - 1;
          SmFill; SmLoad;
        End;
      End;
    IdProtoF, IdProtoS :
    Begin
      { port par defaut du protocole }
      Nm := TrimS(CtlText(SmCtl[IdPort]));
      If (Id = IdProtoS) And ((Nm = '21') Or (Nm = '')) Then SetText(SmCtl[IdPort], '22');
      If (Id = IdProtoF) And ((Nm = '22') Or (Nm = '')) Then SetText(SmCtl[IdPort], '21');
    End;
    IdAnon, IdNormal, IdAskPw : SmEnable;
    IdConn, IDOK :
    Begin
      SmSave;
      If Not SaveSites Then
        Dummy := MsgBox(DlgFrame, 'Impossible d''enregistrer ' + AppDir + 'sitemanager.xml',
                        'Gestionnaire de sites', MB_OK Or MB_ICONERROR);
      DlgRes := Id;
      DlgDone := True;
    End;
    IDCANCEL :
    Begin
      LoadSites;
      DlgRes := IDCANCEL;
      DlgDone := True;
    End;
  End;
End;

{ gestionnaire de sites ; True s'il faut se connecter a Sites^[SmCur] }
Function SiteManager(Sel : LongInt) : Boolean;
Var P : LongInt;
Begin
  SiteManager := False;
  DlgKind := DkSites;
  For P := 100 To 130 Do SmCtl[P] := 0;
  If DlgCreate('Gestionnaire de sites', 630, 446) = 0 Then Exit;
  DlgDef := IdConn;
  P := DlgWnd;
  Lbl(P, 'S'#233'lectionnez une entr'#233'e :', 8, 8, 184);
  SmCtl[IdList] := Ctl(P, 'LISTBOX', '', WS_BORDER Or WS_VSCROLL Or LBS_NOTIFY Or WS_TABSTOP, 8, 26, 184, 278, IdList);
  SmCtl[IdNew] := Ctl(P, 'BUTTON', 'Nouveau site', WS_TABSTOP, 8, 310, 90, 26, IdNew);
  SmCtl[IdDup] := Ctl(P, 'BUTTON', 'Dupliquer', WS_TABSTOP, 102, 310, 90, 26, IdDup);
  SmCtl[IdDel] := Ctl(P, 'BUTTON', 'Supprimer', WS_TABSTOP, 8, 340, 90, 26, IdDel);
  Dummy := Ctl(P, 'BUTTON', 'G'#233'n'#233'ral', BS_GROUPBOX, 198, 4, 426, 278, 0);
  Lbl(P, 'Nom :', 208, 28, 140);
  SmCtl[IdName] := Ctl(P, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 350, 26, 264, 20, IdName);
  Lbl(P, 'Protocole :', 208, 54, 140);
  SmCtl[IdProtoF] := Ctl(P, 'BUTTON', 'FTP - Protocole de transfert de fichiers', BS_AUTORADIOBUTTON Or WS_GROUP Or WS_TABSTOP,
                         224, 72, 390, 18, IdProtoF);
  SmCtl[IdProtoS] := Ctl(P, 'BUTTON', 'SFTP - SSH File Transfer Protocol', BS_AUTORADIOBUTTON, 224, 92, 390, 18, IdProtoS);
  Lbl(P, 'H'#244'te :', 208, 120, 140);
  SmCtl[IdHost] := Ctl(P, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 350, 118, 166, 20, IdHost);
  Lbl(P, 'Port :', 522, 120, 46);
  SmCtl[IdPort] := Ctl(P, 'EDIT', '', WS_BORDER Or WS_TABSTOP, 568, 118, 46, 20, IdPort);
  Lbl(P, 'Authentification :', 208, 146, 140);
  SmCtl[IdAnon] := Ctl(P, 'BUTTON', 'Anonyme', BS_AUTORADIOBUTTON Or WS_GROUP Or WS_TABSTOP, 350, 144, 96, 18, IdAnon);
  SmCtl[IdNormal] := Ctl(P, 'BUTTON', 'Normale', BS_AUTORADIOBUTTON, 452, 144, 96, 18, IdNormal);
  SmCtl[IdAskPw] := Ctl(P, 'BUTTON', 'Demander le mot de passe', BS_AUTORADIOBUTTON, 350, 164, 264, 18, IdAskPw);
  Lbl(P, 'Utilisateur :', 208, 192, 140);
  SmCtl[IdUser] := Ctl(P, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 350, 190, 264, 20, IdUser);
  Lbl(P, 'Mot de passe :', 208, 218, 140);
  SmCtl[IdPass] := Ctl(P, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or ES_PASSWORD Or WS_TABSTOP, 350, 216, 264, 20, IdPass);
  Lbl(P, 'Dossier :', 208, 244, 140);
  SmCtl[IdFolder] := Ctl(P, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 350, 242, 264, 20, IdFolder);
  Dummy := Ctl(P, 'BUTTON', 'Avanc'#233, BS_GROUPBOX, 198, 286, 426, 84, 0);
  Lbl(P, 'Dossier local par d'#233'faut :', 208, 310, 220);
  SmCtl[IdLocDir] := Ctl(P, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 430, 308, 184, 20, IdLocDir);
  Lbl(P, 'Dossier distant par d'#233'faut :', 208, 338, 222);
  SmCtl[IdRemDir] := Ctl(P, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 430, 336, 184, 20, IdRemDir);
  Lbl(P, 'Commentaires :', 198, 384, 120);
  SmCtl[IdComment] := Ctl(P, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 320, 382, 304, 20, IdComment);
  SmCtl[IdConn] := Ctl(P, 'BUTTON', 'Connexion', BS_DEFPUSHBUTTON Or WS_TABSTOP, 352, 412, 90, 26, IdConn);
  Dummy := Ctl(P, 'BUTTON', 'OK', WS_TABSTOP, 448, 412, 84, 26, IDOK);
  Dummy := Ctl(P, 'BUTTON', 'Annuler', WS_TABSTOP, 538, 412, 86, 26, IDCANCEL);
  SmCur := Sel;
  If (SmCur < 0) And (SiteN > 0) Then SmCur := 0;
  If SmCur >= SiteN Then SmCur := SiteN - 1;
  SmFill; SmLoad;
  DlgShow;
  WFocus(SmCtl[IdList]);
  ModalLoop;
  SiteManager := DlgRes = IdConn;
End;

{ ---- droits d'acces (chmod) ---- }

Procedure ChFromBoxes;
Var I, M : LongInt;
Begin
  M := 0;
  For I := 0 To 8 Do
    If Checked(ChBox[I]) Then M := M Or (1 Shl (8 - I));
  ChMode := M;
  ChSync := True;
  SetText(SmCtl[IdNum], IStr((M Shr 6) And 7) + IStr((M Shr 3) And 7) + IStr(M And 7));
  ChSync := False;
End;

Procedure ChToBoxes;
Var I : LongInt;
Begin
  For I := 0 To 8 Do SetCheck(ChBox[I], ((ChMode Shr (8 - I)) And 1) <> 0);
End;

Function OctVal(S : String) : LongInt;
Var I, V : LongInt;
Begin
  V := 0;
  For I := 1 To Length(S) Do
    If S[I] In ['0'..'7'] Then V := V * 8 + Ord(S[I]) - 48
    Else Begin OctVal := -1; Exit; End;
  OctVal := V;
End;

Function ChmodBox(Name : String; Var Mode : LongInt) : Boolean;
Var G, I, J : LongInt; T : String;
Begin
  ChmodBox := False;
  DlgKind := DkChmod;
  ChMode := Mode And $1FF;
  If DlgCreate('Modifier les droits d''acc'#232's', 384, 276) = 0 Then Exit;
  Lbl(DlgWnd, Fit('Droits de "' + Name + '" :', 360), 12, 8, 360);
  For G := 0 To 2 Do
  Begin
    Case G Of
      0 : T := 'Droits du propri'#233'taire';
      1 : T := 'Droits du groupe';
    Else
      T := 'Droits publics';
    End;
    Dummy := Ctl(DlgWnd, 'BUTTON', T, BS_GROUPBOX, 12, 28 + G * 58, 360, 52, 0);
    For J := 0 To 2 Do
    Begin
      Case J Of
        0 : T := 'Lecture';
        1 : T := #201'criture';
      Else
        T := 'Ex'#233'cution';
      End;
      ChBox[G * 3 + J] := Ctl(DlgWnd, 'BUTTON', T, BS_AUTOCHECKBOX Or WS_TABSTOP, 24 + J * 116, 52 + G * 58, 110, 18,
                              IdChk + G * 3 + J);
    End;
  End;
  Lbl(DlgWnd, 'Valeur num'#233'rique :', 12, 210, 150);
  SmCtl[IdNum] := Ctl(DlgWnd, 'EDIT', '', WS_BORDER Or WS_TABSTOP, 166, 208, 60, 20, IdNum);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'OK', BS_DEFPUSHBUTTON Or WS_TABSTOP, 196, 242, 84, 26, IDOK);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Annuler', WS_TABSTOP, 288, 242, 84, 26, IDCANCEL);
  ChToBoxes;
  ChFromBoxes;
  DlgShow;
  WFocus(ChBox[0]);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    Mode := ChMode;
    ChmodBox := True;
  End;
End;

Function DlgProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var Id, Code, V : LongInt;
Begin
  DlgProc0 := 0;
  Case Msg Of
    WM_COMMAND :
    Begin
      Id := WP And $FFFF; Code := (WP Shr 16) And $FFFF;
      If DlgKind = DkSites Then SmCommand(Id, Code)
      Else If DlgKind = DkChmod Then
      Begin
        If (Id >= IdChk) And (Id < IdChk + 9) Then ChFromBoxes
        Else If (Id = IdNum) And (Code = EN_CHANGE) And Not ChSync Then
        Begin
          V := OctVal(TrimS(CtlText(SmCtl[IdNum])));
          If (V >= 0) And (V <= $1FF) Then
          Begin
            ChMode := V;
            ChToBoxes;
          End;
        End
        Else If (Id = IDOK) Or (Id = IDCANCEL) Then
        Begin
          DlgRes := Id; DlgDone := True;
        End;
      End
      Else If (Id = IDOK) Or (Id = IDCANCEL) Then
      Begin
        If Id = IDOK Then DlgText := CtlText(InpEdit);
        DlgRes := Id; DlgDone := True;
      End;
    End;
    WM_CLOSE :
    Begin
      If DlgKind = DkSites Then LoadSites;
      DlgRes := IDCANCEL; DlgDone := True;
    End;
  Else
    DlgProc0 := 0;
  End;
End;

Var
  InDlgKey : Boolean;

{ procedure de PM des boites : fond gris ; WM_COMMAND (boutons) et
  WM_CONTROL (cases, saisies, listes) traduits en WM_COMMAND de Pasdows
  (identifiant + code de notification Shl 16) ; le clavier (tabulation,
  fleches, Entree, Echap, mnemoniques) passe par WinDefDlgProc }
Function DlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Dc, Id, Code, K, R : LongInt;
Begin
  R := 0;
  Case Msg Of
    PM_WM_PAINT :
    Begin
      Dc := PaintBegin(H);
      Bar(Dc, 0, 0, 4000, DcH, ClrFace);
      PaintEnd(Dc);
    End;
    PM_WM_ERASEBACKGROUND : R := 0;
    PM_WM_COMMAND :
    Begin
      BigLock;
      R := DlgProc0(H, WM_COMMAND, Mp1 And $FFFF, 0);
      BigUnlock;
    End;
    PM_WM_CONTROL :
    Begin
      Id := Mp1 And $FFFF; Code := (Mp1 Shr 16) And $FFFF;
      If Id <= 255 Then K := CtlKind[Id] Else K := 0;
      Code := -1;
      Case K Of
        1 : If ((Mp1 Shr 16) And $FFFF) = PM_BN_CLICKED Then Code := BN_CLICKED;
        2 : If ((Mp1 Shr 16) And $FFFF) = PM_EN_CHANGE Then Code := EN_CHANGE;
        3 :
          If ((Mp1 Shr 16) And $FFFF) = PM_LN_SELECT Then Code := LBN_SELCHANGE
          Else If ((Mp1 Shr 16) And $FFFF) = PM_LN_ENTER Then Code := LBN_DBLCLK;
      End;
      If Code >= 0 Then
      Begin
        BigLock;
        R := DlgProc0(H, WM_COMMAND, Id Or (Code Shl 16), 0);
        BigUnlock;
      End;
    End;
    PM_WM_CHAR :
      If InDlgKey Then R := WinDefWindowProc(H, Msg, Mp1, Mp2)
      Else
      Begin
        InDlgKey := True;
        R := WinDefDlgProc(H, Msg, Mp1, Mp2);
        InDlgKey := False;
      End;
    PM_WM_CLOSE :
    Begin
      BigLock;
      R := DlgProc0(H, WM_CLOSE, 0, 0);
      BigUnlock;
    End;
  Else
    R := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
  DlgProc := R;
End;

{ ==================================================================== }
{ Fenetre principale                                                    }
{ ==================================================================== }

Const
  IdQuick = 10; IdHist = 11; IdQHost = 12; IdQUser = 13; IdQPass = 14;
  IdQPort = 15; IdLocPath = 16; IdRemPath = 17;
  CmSiteMgr = 201; CmCopySite = 202; CmImport = 203; CmExport = 204;
  CmExit = 205;
  CmClearLog = 211; CmClearHist = 212; CmSelAll = 213;
  CmRefresh = 221; CmShowLog = 222; CmShowQueue = 223; CmHidden = 224;
  CmProcess = 231; CmStop = 232; CmClearQ = 233; CmClearDone = 234;
  CmRetry = 235; CmOvAsk = 236; CmOvOver = 237; CmOvSkip = 238;
  CmCancel = 241; CmReconnect = 242; CmDisconnect = 243; CmRaw = 244;
  CmCdR = 245; CmMkdirRem = 246;
  CmHelp = 251; CmAbout = 252;
  CmUpload = 301; CmAddQL = 302; CmOpenL = 303; CmMkdirL = 304;
  CmRefreshL = 305; CmDeleteL = 306; CmRenameL = 307; CmEnterL = 308;
  CmDownload = 311; CmAddQR = 312; CmMkdirR = 313; CmRefreshR = 314;
  CmDeleteR = 315; CmRenameR = 316; CmCopyUrl = 317; CmChmod = 318;
  CmEnterR = 319;
  CmQRemove = 321;
  CmRecent = 400;
  TbH = 30; QcH = 28; StH = 22; TabH = 22;
  TbN = 7;

Var
  MainMenu, MView, MTrans, MOver, MSrv : LongInt;
  EHost, EUser, EPass, EPort, BConn, BHist, ELoc, ERem : LongInt;
  ShowLog, ShowQueue : Boolean;
  CW0, CH0 : LongInt;                     { zone client }
  LogY, LogH, PaneY, PaneB, Mid, QY : LongInt;
  QcX : Array[0..4] Of LongInt;            { abscisses des libelles }
  QcL : Array[0..3] Of String[20];         { libelles (courts si etroit) }
  TbHot, TbDown : LongInt;
  StatusTxt : String;

Function QCount(St : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To QN - 1 Do
    If (Queue^[I].State = St) Or ((St = QsWait) And (Queue^[I].State = QsRun)) Then Inc(N);
  QCount := N;
End;

Function TbTip(I : LongInt) : String;
Begin
  Case I Of
    0 : TbTip := 'Ouvre le Gestionnaire de sites';
    1 : TbTip := 'Actualise les listes des fichiers et des dossiers';
    2 : TbTip := 'Traite la file d''attente';
    3 : TbTip := 'Annule l''op'#233'ration en cours';
    4 : TbTip := 'D'#233'connecte du serveur affich'#233;
    5 : TbTip := 'Se reconnecte au dernier serveur utilis'#233;
  Else
    TbTip := 'Affiche ou masque la file d''attente';
  End;
End;

Function TbX(I : LongInt) : LongInt;
Begin
  { separateurs apres les boutons 0 et 3 }
  If I = 0 Then TbX := 6
  Else If I <= 3 Then TbX := 6 + 8 + I * 26
  Else TbX := 6 + 16 + I * 26;
End;

Function TbEnabled(I : LongInt) : Boolean;
Begin
  Case I Of
    1 : TbEnabled := True;
    2 : TbEnabled := (QCount(QsWait) > 0) And Not QRun;
    3 : TbEnabled := Busy Or QRun;
    4 : TbEnabled := Connected;
    5 : TbEnabled := HaveSite And Not Connected And Not Busy;
  Else
    TbEnabled := True;
  End;
End;

{ pictogrammes de la barre d'outils }
Procedure TbIcon(Dc, I, X, Y : LongInt; En : Boolean);
Var C1, C2, C3 : LongInt;
Begin
  If En Then Begin C1 := ClrBlack; C2 := ClrGreen; C3 := ClrRed; End
  Else Begin C1 := ClrShadow; C2 := ClrShadow; C3 := ClrShadow; End;
  Case I Of
    0 :
    Begin
      { deux serveurs }
      Bar(Dc, X + 1, Y + 1, X + 10, Y + 7, C1); Bar(Dc, X + 2, Y + 2, X + 9, Y + 6, ClrFace);
      Bar(Dc, X + 3, Y + 3, X + 5, Y + 5, C2);
      Bar(Dc, X + 5, Y + 8, X + 15, Y + 15, C1); Bar(Dc, X + 6, Y + 9, X + 14, Y + 14, ClrFace);
      Bar(Dc, X + 7, Y + 10, X + 9, Y + 12, C2);
      Bar(Dc, X + 2, Y + 8, X + 3, Y + 13, C1); Bar(Dc, X + 2, Y + 12, X + 5, Y + 13, C1);
    End;
    1 :
    Begin
      { fleches tournantes }
      Bar(Dc, X + 3, Y + 3, X + 12, Y + 5, C2); Bar(Dc, X + 3, Y + 3, X + 5, Y + 9, C2);
      Bar(Dc, X + 10, Y + 1, X + 11, Y + 7, C2); Bar(Dc, X + 11, Y + 2, X + 12, Y + 6, C2);
      Bar(Dc, X + 12, Y + 3, X + 13, Y + 5, C2);
      Bar(Dc, X + 4, Y + 11, X + 13, Y + 13, ClrNavy); Bar(Dc, X + 11, Y + 7, X + 13, Y + 13, ClrNavy);
      Bar(Dc, X + 5, Y + 9, X + 6, Y + 15, ClrNavy); Bar(Dc, X + 4, Y + 10, X + 5, Y + 14, ClrNavy);
      Bar(Dc, X + 3, Y + 11, X + 4, Y + 13, ClrNavy);
      If Not En Then
      Begin
        Bar(Dc, X + 4, Y + 11, X + 13, Y + 13, ClrShadow); Bar(Dc, X + 11, Y + 7, X + 13, Y + 13, ClrShadow);
      End;
    End;
    2 :
    Begin
      { file + lecture }
      Bar(Dc, X + 1, Y + 2, X + 8, Y + 4, C1); Bar(Dc, X + 1, Y + 7, X + 8, Y + 9, C1);
      Bar(Dc, X + 1, Y + 12, X + 8, Y + 14, C1);
      Bar(Dc, X + 10, Y + 3, X + 11, Y + 14, C2); Bar(Dc, X + 11, Y + 4, X + 12, Y + 13, C2);
      Bar(Dc, X + 12, Y + 5, X + 13, Y + 12, C2); Bar(Dc, X + 13, Y + 6, X + 14, Y + 11, C2);
      Bar(Dc, X + 14, Y + 7, X + 15, Y + 10, C2);
    End;
    3 :
    Begin
      { croix rouge }
      For C1 := 0 To 9 Do
      Begin
        Bar(Dc, X + 3 + C1, Y + 3 + C1, X + 5 + C1, Y + 5 + C1, C3);
        Bar(Dc, X + 12 - C1, Y + 3 + C1, X + 14 - C1, Y + 5 + C1, C3);
      End;
    End;
    4, 5 :
    Begin
      { prises : debranchees (4) ou branchees (5) }
      Bar(Dc, X, Y + 6, X + 5, Y + 10, C1);
      Bar(Dc, X + 5, Y + 5, X + 8, Y + 11, ClrShadow);
      Bar(Dc, X + 11, Y + 5, X + 14, Y + 11, ClrShadow);
      Bar(Dc, X + 14, Y + 6, X + 16, Y + 10, C1);
      If I = 5 Then Bar(Dc, X + 8, Y + 7, X + 11, Y + 9, C2)
      Else
      Begin
        Bar(Dc, X + 9, Y + 2, X + 10, Y + 5, C3); Bar(Dc, X + 9, Y + 11, X + 10, Y + 14, C3);
      End;
    End;
  Else
    Begin
      { file d'attente }
      Bar(Dc, X + 1, Y + 2, X + 15, Y + 14, C1); Bar(Dc, X + 2, Y + 3, X + 14, Y + 13, ClrWin);
      Bar(Dc, X + 3, Y + 5, X + 13, Y + 6, ClrNavy); Bar(Dc, X + 3, Y + 8, X + 13, Y + 9, ClrNavy);
      Bar(Dc, X + 3, Y + 11, X + 9, Y + 12, ClrNavy);
    End;
  End;
End;

Function PaneText(K : LongInt) : String;
Var I, NF, ND, SF, SD : LongInt; T, ST : Double; S : String; E : PEntry;
Begin
  NF := 0; ND := 0; SF := 0; SD := 0; T := 0; ST := 0;
  For I := 0 To LvCount(K) - 1 Do
  Begin
    E := LvE(K, I);
    If E^.Name = '..' Then Continue;
    If E^.Dir Then Inc(ND) Else Begin Inc(NF); T := T + E^.Size; End;
    If LvSel(K, I) Then
      If E^.Dir Then Inc(SD) Else Begin Inc(SF); ST := ST + E^.Size; End;
  End;
  If (K = LvRemote) And Not RemOk Then
  Begin
    PaneText := 'Non connect'#233'.';
    Exit;
  End;
  If (K = LvLocal) And (LocPath = '') Then
  Begin
    PaneText := IStr(ND) + ' lecteur(s)';
    Exit;
  End;
  If SF + SD > 0 Then
  Begin
    S := '';
    If SF > 0 Then S := IStr(SF) + ' fichier(s)';
    If SD > 0 Then
    Begin
      If S <> '' Then S := S + ' et ';
      S := S + IStr(SD) + ' dossier(s)';
    End;
    S := S + ' s'#233'lectionn'#233'(s).';
    If SF > 0 Then S := S + ' Taille totale : ' + Group(DStr(ST)) + ' octets';
  End
  Else If NF + ND = 0 Then S := 'Dossier vide.'
  Else
  Begin
    S := IStr(NF) + ' fichier(s) et ' + IStr(ND) + ' dossier(s).';
    If NF > 0 Then S := S + ' Taille totale : ' + Group(DStr(T)) + ' octets';
  End;
  PaneText := S;
End;

Function QSummary : String;
Var I, N : LongInt; T : Double;
Begin
  N := 0; T := 0;
  For I := 0 To QN - 1 Do
    If (Queue^[I].State = QsWait) Or (Queue^[I].State = QsRun) Then
    Begin
      Inc(N);
      T := T + Queue^[I].Size - Queue^[I].Done;
    End;
  If N = 0 Then QSummary := 'File d''attente : vide'
  Else QSummary := 'File d''attente : ' + IStr(N) + ' fichier(s), ' + SizeTxt(T);
End;

{ controles de la fenetre principale : PM ne retire pas les fenetres
  enfants du dessin de la fenetre mere (pas de WS_CLIPCHILDREN) ; le fond
  est donc peint autour de leurs rectangles (Y vers le bas) }
Var
  HoleX1, HoleY1, HoleX2, HoleY2 : Array[0..7] Of LongInt;

Procedure MPlace(I, H, X, Y, W, Hh : LongInt);
Begin
  HoleX1[I] := X; HoleY1[I] := Y; HoleX2[I] := X + W; HoleY2[I] := Y + Hh;
  WPlace(H, X, Y, W, Hh);
End;

Procedure BarHoles(Dc, X1, Y1, X2, Y2, C, From : LongInt);
Var I, J : LongInt;
Begin
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  J := -1;
  For I := 7 DownTo From Do
    If (HoleX1[I] < X2) And (HoleX2[I] > X1) And (HoleY1[I] < Y2) And (HoleY2[I] > Y1) Then J := I;
  If J < 0 Then
  Begin
    Bar(Dc, X1, Y1, X2, Y2, C);
    Exit;
  End;
  { au-dessus, au-dessous, a gauche, a droite du controle J }
  BarHoles(Dc, X1, Y1, X2, MaxI(Y1, HoleY1[J]), C, J + 1);
  BarHoles(Dc, X1, MinI(Y2, HoleY2[J]), X2, Y2, C, J + 1);
  BarHoles(Dc, X1, MaxI(Y1, HoleY1[J]), MaxI(X1, HoleX1[J]), MinI(Y2, HoleY2[J]), C, J + 1);
  BarHoles(Dc, MinI(X2, HoleX2[J]), MaxI(Y1, HoleY1[J]), X2, MinI(Y2, HoleY2[J]), C, J + 1);
End;

Procedure MainPaint(H : LongInt);
Var Dc, I, X, Y, W, En, Tw : LongInt; S : String;
Begin
  Dc := PaintBegin(H);
  W := CW0;
  { barre d'outils }
  Bar(Dc, 0, 0, W, TbH, ClrFace);
  Bar(Dc, 0, 0, W, 1, ClrHi);
  For I := 0 To TbN - 1 Do
  Begin
    X := TbX(I); En := Ord(TbEnabled(I));
    If (I = TbDown) And (En <> 0) Then Bevel(Dc, X, 3, X + 24, 27, False)
    Else If ((I = TbHot) And (En <> 0)) Or ((I = 6) And ShowQueue) Then Thin(Dc, X, 3, X + 24, 27, True);
    TbIcon(Dc, I, X + 4 + Ord(I = TbDown), 7 + Ord(I = TbDown), En <> 0);
  End;
  Bar(Dc, TbX(1) - 5, 4, TbX(1) - 4, 26, ClrShadow); Bar(Dc, TbX(1) - 4, 4, TbX(1) - 3, 26, ClrHi);
  Bar(Dc, TbX(4) - 5, 4, TbX(4) - 4, 26, ClrShadow); Bar(Dc, TbX(4) - 4, 4, TbX(4) - 3, 26, ClrHi);
  Bar(Dc, 0, TbH - 2, W, TbH - 1, ClrShadow); Bar(Dc, 0, TbH - 1, W, TbH, ClrHi);
  { connexion rapide }
  BarHoles(Dc, 0, TbH, W, TbH + QcH, ClrFace, 0);
  Txt(Dc, QcX[0], TbH + 6, QcL[0], ClrBlack);
  Txt(Dc, QcX[1], TbH + 6, QcL[1], ClrBlack);
  Txt(Dc, QcX[2], TbH + 6, QcL[2], ClrBlack);
  Txt(Dc, QcX[3], TbH + 6, QcL[3], ClrBlack);
  Bar(Dc, 0, TbH + QcH - 2, W, TbH + QcH - 1, ClrShadow); Bar(Dc, 0, TbH + QcH - 1, W, TbH + QcH, ClrHi);
  { fond des panneaux, autour des fenetres enfants (pas de WS_CLIPCHILDREN) }
  Bar(Dc, 0, TbH + QcH, W, LogY, ClrFace);
  If LogH > 0 Then
  Begin
    Bar(Dc, 0, LogY, 2, LogY + LogH, ClrFace); Bar(Dc, W - 2, LogY, W, LogY + LogH, ClrFace);
  End;
  BarHoles(Dc, 0, LogY + LogH, W, PaneY + 24, ClrFace, 0);
  Bar(Dc, 0, PaneY + 24, 2, PaneB - 20, ClrFace);
  Bar(Dc, Mid - 2, PaneY + 24, Mid + 2, PaneB - 20, ClrFace);
  Bar(Dc, W - 2, PaneY + 24, W, PaneB - 20, ClrFace);
  If ShowQueue Then
  Begin
    Bar(Dc, 0, PaneB - 20, W, QY + TabH, ClrFace);
    Bar(Dc, 0, QY + TabH, 2, CH0 - StH, ClrFace); Bar(Dc, W - 2, QY + TabH, W, CH0 - StH, ClrFace);
    Bar(Dc, 0, CH0 - StH - 2, W, CH0 - StH, ClrFace);
  End
  Else Bar(Dc, 0, PaneB - 20, W, CH0 - StH, ClrFace);
  Txt(Dc, 6, PaneY + 3, 'Site local :', ClrBlack);
  Txt(Dc, Mid + 6, PaneY + 3, 'Site distant :', ClrBlack);
  { etats des panneaux }
  Thin(Dc, 2, PaneB - 18, Mid - 2, PaneB, False);
  Txt(Dc, 6, PaneB - 17, Fit(PaneText(LvLocal), Mid - 12), ClrBlack);
  Thin(Dc, Mid + 2, PaneB - 18, W - 2, PaneB, False);
  Txt(Dc, Mid + 6, PaneB - 17, Fit(PaneText(LvRemote), W - Mid - 12), ClrBlack);
  { onglets de la file d'attente }
  If ShowQueue Then
  Begin
    X := 4;
    For I := 0 To 2 Do
    Begin
      Case I Of
        0 : S := 'Fichiers en attente (' + IStr(QCount(QsWait)) + ')';
        1 : S := 'Transferts '#233'chou'#233's (' + IStr(QCount(QsFail)) + ')';
      Else
        S := 'Transferts r'#233'ussis (' + IStr(QCount(QsOk)) + ')';
      End;
      Tw := Length(S) * CW + 16;
      If I = QTab Then
      Begin
        Bar(Dc, X, QY, X + Tw, QY + TabH, ClrFace);
        Bar(Dc, X, QY, X + Tw, QY + 1, ClrHi); Bar(Dc, X, QY, X + 1, QY + TabH, ClrHi);
        Bar(Dc, X + Tw - 1, QY, X + Tw, QY + TabH, ClrDark);
        Txt(Dc, X + 8, QY + 2, S, ClrBlack);
      End
      Else
      Begin
        Bar(Dc, X, QY + 2, X + Tw, QY + 3, ClrHi); Bar(Dc, X, QY + 2, X + 1, QY + TabH, ClrHi);
        Bar(Dc, X + Tw - 1, QY + 2, X + Tw, QY + TabH, ClrShadow);
        Bar(Dc, X, QY + TabH - 1, X + Tw, QY + TabH, ClrHi);
        Txt(Dc, X + 8, QY + 3, S, ClrBlack);
      End;
      X := X + Tw + 1;
    End;
    Bar(Dc, X, QY + TabH - 1, W, QY + TabH, ClrHi);
  End;
  { barre d'etat }
  Y := CH0 - StH;
  Bar(Dc, 0, Y, W, CH0, ClrFace);
  Thin(Dc, 2, Y + 2, W - 230, CH0 - 2, False);
  Thin(Dc, W - 226, Y + 2, W - 22, CH0 - 2, False);
  Txt(Dc, 6, Y + 3, Fit(StatusTxt, W - 240), ClrBlack);
  Txt(Dc, W - 222, Y + 3, Fit(QSummary, 196), ClrBlack);
  If Connected Then Bar(Dc, W - 16, Y + 6, W - 8, CH0 - 6, ClrGreen)
  Else If Busy Then Bar(Dc, W - 16, Y + 6, W - 8, CH0 - 6, ClrYellow)
  Else Bar(Dc, W - 16, Y + 6, W - 8, CH0 - 6, ClrShadow);
  Thin(Dc, W - 18, Y + 4, W - 6, CH0 - 4, False);
  PaintEnd(Dc);
End;

Procedure Layout;
Var W, H, Rest, Wh, Wu, X, LH : LongInt;
Begin
  W := CW0; H := CH0;
  { connexion rapide }
  { libelles de la police de PM (8 points par caractere) ; plus courts
    quand la fenetre est etroite (640 x 480) }
  If W >= 760 Then
  Begin
    QcL[0] := 'H'#244'te :'; QcL[1] := 'Identifiant :'; QcL[2] := 'Mot de passe :'; QcL[3] := 'Port :';
  End
  Else
  Begin
    QcL[0] := 'H'#244'te:'; QcL[1] := 'Utilisateur:'; QcL[2] := 'Mot de passe:'; QcL[3] := 'Port:';
  End;
  Rest := W - 6 - 8 * 3 - 54 - 82 - 20 - 4;
  For X := 0 To 3 Do Rest := Rest - Length(QcL[X]) * CW - 6;
  Rest := MaxI(150, Rest);
  Wh := Rest * 44 Div 100; Wu := (Rest - Wh) Div 2;
  X := 6;
  QcX[0] := X; X := X + Length(QcL[0]) * CW + 6;
  MPlace(0, EHost, X, TbH + 4, Wh, 20); X := X + Wh + 8;
  QcX[1] := X; X := X + Length(QcL[1]) * CW + 6;
  MPlace(1, EUser, X, TbH + 4, Wu, 20); X := X + Wu + 8;
  QcX[2] := X; X := X + Length(QcL[2]) * CW + 6;
  MPlace(2, EPass, X, TbH + 4, Wu, 20); X := X + Wu + 8;
  QcX[3] := X; X := X + Length(QcL[3]) * CW + 6;
  MPlace(3, EPort, X, TbH + 4, 48, 20); X := X + 54;
  MPlace(4, BConn, X, TbH + 2, 82, 24); X := X + 82;
  MPlace(5, BHist, X, TbH + 2, 20, 24);
  { journal }
  LogY := TbH + QcH + 2;
  If ShowLog Then LH := MaxI(68, H * 16 Div 100) Else LH := 0;
  LogH := LH;
  If ShowLog Then
  Begin
    WPlace(LogW, 2, LogY, W - 4, LH);
    WShow(LogW, True);
  End
  Else WShow(LogW, False);
  PaneY := LogY + LH + 2;
  { file d'attente }
  If ShowQueue Then
  Begin
    QY := H - StH - MaxI(84, H * 20 Div 100);
    WPlace(Lv[LvQueue].H, 2, QY + TabH, W - 4, H - StH - QY - TabH - 2);
    WShow(Lv[LvQueue].H, True);
  End
  Else
  Begin
    QY := H - StH;
    WShow(Lv[LvQueue].H, False);
  End;
  PaneB := QY - 4;
  Mid := W Div 2;
  MPlace(6, ELoc, 104, PaneY + 1, Mid - 108, 20);
  MPlace(7, ERem, Mid + 120, PaneY + 1, W - Mid - 124, 20);
  WPlace(Lv[LvLocal].H, 2, PaneY + 24, Mid - 4, PaneB - 20 - PaneY - 24);
  WPlace(Lv[LvRemote].H, Mid + 2, PaneY + 24, W - Mid - 4, PaneB - 20 - PaneY - 24);
  Inval(MainWnd);
End;

Procedure SetStatus(S : String);
Begin
  StatusTxt := S;
  Inval(MainWnd);
End;

Procedure UpdateTitle;
Var S : String;
Begin
  If Connected Then
  Begin
    S := CurSite.Host;
    If CurSite.Name <> CurSite.Host Then S := CurSite.Name;
    S := S + ' - Client FTP';
  End
  Else S := 'Client FTP';
  SetText(MainWnd, S);
End;

{ ---- site local ---- }

Procedure LocalGo(P : String);
Var A : LongInt;
Begin
  P := TrimS(P);
  If (Length(P) = 2) And (P[2] = ':') Then P := P + '\';
  If (P <> '') And (Length(P) > 3) And (P[Length(P)] = '\') Then P := Copy(P, 1, Length(P) - 1);
  If P <> '' Then
  Begin
    A := FAttr(P);
    If (A = -1) Or ((A And $10) = 0) Then
    Begin
      If Ask('Le dossier "' + P + '" est introuvable.', 'Site local', MB_OK Or MB_ICONERROR) = 0 Then;
      SetText(ELoc, LocPath);
      Exit;
    End;
  End;
  LocPath := P;
  LocalRead;
  LvReset(LvLocal);
  If LocPath = '' Then SetText(ELoc, 'Poste de travail') Else SetText(ELoc, LocPath);
  ListChanged(LvLocal);
End;

Procedure LocalRefresh;
Var C, T : LongInt;
Begin
  C := Lv[LvLocal].Cur; T := Lv[LvLocal].Top;
  LocalRead;
  SortList(LvLocal);
  LvClearSel(LvLocal);
  Lv[LvLocal].Top := T; Lv[LvLocal].Cur := MinI(C, MaxI(0, LocN - 1));
  LvSync(LvLocal);
  LvRepaint(LvLocal);
  ListChanged(LvLocal);
End;

{ ---- file d'attente ---- }

Procedure QAdd(Kind : LongInt; Loc, Rem : String; Size : Double);
Begin
  If QN >= MaxQ Then Exit;
  Queue^[QN].Kind := Kind; Queue^[QN].State := QsWait;
  Queue^[QN].Loc := Loc; Queue^[QN].Rem := Rem;
  Queue^[QN].Size := Size; Queue^[QN].Done := 0; Queue^[QN].Err := '';
  Inc(QN);
End;

Procedure QueueUpDir(L, R : String; Depth : LongInt);
Var F : TFf; A : LongInt; Nm : String; More : Boolean;
Begin
  If Depth > 16 Then Exit;
  QAdd(QkMkdir, L, R, 0);
  More := FfFirst(LJoin(L, '*'), F);
  While More Do
  Begin
    Nm := FfName(F);
    A := FfAttr(F);
    If (Nm <> '.') And (Nm <> '..') And (Nm <> '') Then
    Begin
      If (A And $10) <> 0 Then QueueUpDir(LJoin(L, Nm), RJoin(R, Nm), Depth + 1)
      Else QAdd(QkUp, LJoin(L, Nm), RJoin(R, Nm), FfSize(F));
    End;
    More := FfNext(F);
  End;
  FfClose(F);
End;

Procedure QueueChanged;
Var C : LongInt;
Begin
  C := Lv[LvQueue].Top;
  QFilter;
  LvClearSel(LvQueue);
  Lv[LvQueue].Top := C;
  LvSync(LvQueue);
  LvRepaint(LvQueue);
  Inval(MainWnd);
End;

Procedure StartQueue;
Begin
  If Not HaveSite Then
  Begin
    Ask('Connectez-vous d''abord '#224' un serveur.', 'File d''attente', MB_OK Or MB_ICONINFO);
    Exit;
  End;
  QRun := True;
  Dummy := DosPostEventSem(WorkEv);
  QueueChanged;
End;

{ envoi (Up) ou telechargement des elements choisis }
Procedure Enqueue(Up, Start : Boolean);
Var I, N : LongInt; E : PEntry;
Begin
  If Not RemOk Then
  Begin
    Ask('Connectez-vous d''abord '#224' un serveur.', 'Transfert', MB_OK Or MB_ICONINFO);
    Exit;
  End;
  N := 0;
  If Up Then
  Begin
    If LocPath = '' Then Exit;
    For I := 0 To LocN - 1 Do
      If LocSel[I] Then
      Begin
        E := LvE(LvLocal, I);
        If E^.Name = '..' Then Continue;
        If E^.Dir Then QueueUpDir(LJoin(LocPath, E^.Name), RJoin(RemPath, E^.Name), 0)
        Else QAdd(QkUp, LJoin(LocPath, E^.Name), RJoin(RemPath, E^.Name), E^.Size);
        Inc(N);
      End;
  End
  Else
  Begin
    If LocPath = '' Then
    Begin
      Ask('Choisissez d''abord un dossier local.', 'Transfert', MB_OK Or MB_ICONINFO);
      Exit;
    End;
    For I := 0 To RemN - 1 Do
      If RemSel[I] Then
      Begin
        E := LvE(LvRemote, I);
        If E^.Name = '..' Then Continue;
        If E^.Dir And Not E^.Link Then
          QAdd(QkDownDir, LJoin(LocPath, E^.Name), RJoin(RemPath, E^.Name), 0)
        Else QAdd(QkDown, LJoin(LocPath, E^.Name), RJoin(RemPath, E^.Name), E^.Size);
        Inc(N);
      End;
  End;
  If N = 0 Then Exit;
  QTab := 0;
  If Start Then StartQueue Else QueueChanged;
End;

{ ---- connexion ---- }

Procedure ConnectSite(Var S : TSite);
Var P : String;
Begin
  If S.Host = '' Then
  Begin
    Ask('Indiquez l''h'#244'te (nom ou adresse du serveur).', 'Connexion', MB_OK Or MB_ICONINFO);
    Exit;
  End;
  CurSite := S;
  If CurSite.Logon = LgAsk Then
  Begin
    P := '';
    If Not InputBox('Mot de passe', 'Mot de passe de ' + CurSite.User + ' sur ' + CurSite.Host + ' :', P, True) Then Exit;
    CurSite.Pass := P;
  End;
  HaveSite := True;
  QRun := False;
  If Busy Then XfCancel := True;
  AddCmd(OpConnect, '', '', 0);
  SetStatus('Connexion '#224' ' + CurSite.Host + '...');
End;

Procedure QuickConnect;
Var S : TSite; H : String; I : LongInt;
Begin
  SiteClear(S);
  H := TrimS(CtlText(EHost));
  S.User := TrimS(CtlText(EUser)); S.Pass := CtlText(EPass);
  S.Port := SVal(TrimS(CtlText(EPort)));
  If LoS(Copy(H, 1, 7)) = 'sftp://' Then
  Begin
    S.Proto := PrSftp; Delete(H, 1, 7);
  End
  Else If LoS(Copy(H, 1, 6)) = 'ftp://' Then Delete(H, 1, 6)
  Else If S.Port = 22 Then S.Proto := PrSftp;
  I := Pos('/', H);
  If I > 0 Then
  Begin
    S.RemDir := Copy(H, I, 255); H := Copy(H, 1, I - 1);
  End;
  I := Pos('@', H);
  If I > 0 Then
  Begin
    S.User := Copy(H, 1, I - 1); H := Copy(H, I + 1, 255);
  End;
  I := Pos(':', H);
  If I > 0 Then
  Begin
    S.Port := SVal(Copy(H, I + 1, 6)); H := Copy(H, 1, I - 1);
  End;
  If S.Port <= 0 Then
    If S.Proto = PrSftp Then S.Port := 22 Else S.Port := 21;
  S.Host := H; S.Name := H;
  If S.User = '' Then S.Logon := LgAnon;
  If H = '' Then
  Begin
    Ask('Indiquez l''h'#244'te (nom ou adresse du serveur).', 'Connexion rapide', MB_OK Or MB_ICONINFO);
    WFocus(EHost);
    Exit;
  End;
  If S.Proto = PrSftp Then SetText(EPort, IStr(S.Port));
  AddRecent(S);
  ConnectSite(S);
End;

Procedure ShowRecent;
Var M, I, X, Y : LongInt; S : String;
Begin
  M := CreatePopupMenu;
  If RecentN = 0 Then MItem(M, CmRecent + 99, '(historique vide)')
  Else
    For I := 0 To RecentN - 1 Do
    Begin
      If Recent[I].Proto = PrSftp Then S := 'sftp://' Else S := '';
      If Recent[I].User <> '' Then S := S + Recent[I].User + '@';
      S := S + Recent[I].Host + ':' + IStr(Recent[I].Port);
      MItem(M, CmRecent + I, S);
    End;
  MItem(M, 0, '');
  MItem(M, CmClearHist, 'Effacer l''historique');
  X := 0; Y := 23;
  ToScreen(BHist, X, Y);
  TrackPopupMenu(M, X, Y);
End;

{ ---- commandes des listes ---- }

Function SelCount(K : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To LvCount(K) - 1 Do
    If LvSel(K, I) Then
      If (K = LvQueue) Or (LvE(K, I)^.Name <> '..') Then Inc(N);
  SelCount := N;
End;

Function FirstSel(K : LongInt) : LongInt;
Var I : LongInt;
Begin
  FirstSel := -1;
  For I := LvCount(K) - 1 DownTo 0 Do
    If LvSel(K, I) Then
      If (K = LvQueue) Or (LvE(K, I)^.Name <> '..') Then FirstSel := I;
End;

Function LDelete(P : String; IsDir : Boolean; Depth : LongInt) : Boolean;
Var F : TFf; A, N, I : LongInt; Nm : String; Ok, More : Boolean; Names : PNames; Dirs : Array[0..255] Of Boolean;
Begin
  LDelete := False;
  If Not IsDir Then
  Begin
    LDelete := DosDelete(Z(P)) = 0;
    Exit;
  End;
  If Depth > 16 Then Exit;
  Ok := True;
  { liste d'abord le dossier, puis supprime (la recherche reste valide) }
  New(Names);
  N := 0;
  More := FfFirst(LJoin(P, '*'), F);
  While More And (N < 256) Do
  Begin
    Nm := FfName(F);
    A := FfAttr(F);
    If (Nm <> '.') And (Nm <> '..') And (Nm <> '') Then
    Begin
      Names^[N] := Nm; Dirs[N] := (A And $10) <> 0;
      Inc(N);
    End;
    More := FfNext(F);
  End;
  FfClose(F);
  For I := 0 To N - 1 Do
    If Not LDelete(LJoin(P, Names^[I]), Dirs[I], Depth + 1) Then Ok := False;
  Dispose(Names);
  LDelete := Ok And (DosDeleteDir(Z(P)) = 0);
End;

{ presse-papiers de PM : CF_TEXT, CFI_POINTER (PM copie le texte) }
Procedure CopyToClip(S : String);
Begin
  PutZ(LongInt(@TxtBuf), Disp(S));
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    Dummy := WinSetClipbrdData(Hab, LongInt(@TxtBuf), 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
End;

{ ouvre un fichier local avec l'application d'OS/2-0 de son type
  (comme l'Explorateur) ; un .EXE est lance directement }
Function AppPath(N : String) : String;
Begin
  If FAttr('C:\' + N) <> -1 Then AppPath := 'C:\' + N
  Else If FAttr(AppExeDir + N) <> -1 Then AppPath := AppExeDir + N
  Else AppPath := '';
End;

Procedure RunPm(P, Params : String);
Var Res : Array[0..1] Of LongInt; Fail : Array[0..63] Of Byte; Rc : LongInt;
Begin
  PutZ(LongInt(@TxtBuf), P);
  PutZ(LongInt(@TxtBuf) + Length(P) + 1, Params);
  TxtBuf[Length(P) + Length(Params) + 2] := 0;
  PutZ(LongInt(@NameZ2), P);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@Fail), 64, 4, LongInt(@TxtBuf), 0, LongInt(@Res), LongInt(@NameZ2));
  If Rc <> 0 Then Ask('Impossible de lancer ' + P + ' (' + IStr(Rc) + ').', 'Ouvrir', MB_OK Or MB_ICONERROR);
End;

Procedure OpenLocal(P : String);
Var X, A : String; I : LongInt;
Begin
  X := '';
  I := Length(P);
  While (I > 0) And (P[I] <> '.') And (P[I] <> '\') Do Dec(I);
  If (I > 0) And (P[I] = '.') Then X := UpS(Copy(P, I + 1, 10));
  If X = 'EXE' Then
  Begin
    RunPm(P, '');
    Exit;
  End;
  A := '';
  If (X = 'DOC') Or (X = 'DOCX') Or (X = 'WPD') Or (X = 'GAT') Or (X = 'PDF') Then A := AppPath('WORDIUM.EXE')
  Else If (X = 'XLC') Or (X = 'XLS') Or (X = 'XLSX') Then A := AppPath('EXCELSIO.EXE')
  Else If (X = 'HTM') Or (X = 'HTML') Then A := AppPath('BROWSER.EXE')
  Else If X = 'WAV' Then A := AppPath('DIGAUDIO.EXE')
  Else If (X = 'MP3') Or (X = 'M3U') Or (X = 'PLS') Then A := AppPath('MP3PLAY.EXE')
  Else If (X = 'SON') Or (X = 'MID') Then A := AppPath('NOTATOR.EXE')
  Else If (X = 'BMP') Or (X = 'PCX') Or (X = 'GIF') Or (X = 'PNG') Or (X = 'JPG') Or (X = 'ICO') Or
          (X = 'TIF') Or (X = 'PPM') Then A := AppPath('PAINT.EXE')
  Else If (X = 'TXT') Or (X = 'PAS') Or (X = 'INI') Or (X = 'SYS') Or (X = 'LOG') Or (X = 'CFG') Or
          (X = 'XML') Or (X = 'CMD') Or (X = 'BAT') Or (X = 'ME') Or (X = '') Then
  Begin
    A := AppPath('NOTEPAD.EXE');
    If A = '' Then A := AppPath('PASDEV.EXE');
  End;
  If Pos(' ', P) > 0 Then P := '"' + P + '"';
  If A <> '' Then RunPm(A, P)
  Else Ask('Aucune application n''est associ'#233'e '#224' ce fichier :|' + P, 'Ouvrir', MB_OK Or MB_ICONINFO);
End;

Function PermMode(P : String) : LongInt;
Var M, I : LongInt;
Begin
  M := 0;
  If Length(P) >= 10 Then
    For I := 0 To 8 Do
      If P[I + 2] <> '-' Then M := M Or (1 Shl (8 - I));
  If Length(P) < 10 Then M := $1A4;
  PermMode := M;
End;

Procedure DoMenu(Cmd : LongInt);
Var I, N, Mode : LongInt; S, Old : String; E : PEntry; Ok : Boolean;
Begin
  Case Cmd Of
    CmSiteMgr :
      If SiteManager(-1) Then ConnectSite(Sites^[SmCur]);
    CmCopySite :
      If Not HaveSite Then Ask('Aucune connexion en cours.', 'Gestionnaire de sites', MB_OK Or MB_ICONINFO)
      Else If SiteN < MaxSite Then
      Begin
        Sites^[SiteN] := CurSite;
        If Sites^[SiteN].Name = '' Then Sites^[SiteN].Name := CurSite.Host;
        Inc(SiteN);
        If SiteManager(SiteN - 1) Then ConnectSite(Sites^[SmCur]);
      End;
    CmImport :
    Begin
      S := 'C:\sitemanager.xml';
      If InputBox('Importer des sites', 'Fichier XML (sitemanager.xml de FileZilla) :', S, False) Then
      Begin
        N := ImportSites(TrimS(S));
        If SaveSites Then;
        Ask(IStr(N) + ' site(s) import'#233'(s) de ' + S + '.', 'Importer des sites', MB_OK Or MB_ICONINFO);
      End;
    End;
    CmExport :
    Begin
      S := 'C:\sites.xml';
      If InputBox('Exporter les sites', 'Enregistrer les ' + IStr(SiteN) + ' site(s) dans le fichier XML :', S, False) Then
        If SaveSitesTo(TrimS(S)) Then
          Ask('Sites export'#233's dans ' + S + '.', 'Exporter les sites', MB_OK Or MB_ICONINFO)
        Else Ask('Impossible d''enregistrer ' + S + '.', 'Exporter les sites', MB_OK Or MB_ICONERROR);
    End;
    CmExit : Dummy := WinPostMsg(MainWnd, WM_CLOSE, 0, 0);
    CmClearLog :
    Begin
      LogN := 0; LogTop := 0; LogSync(True);
      Inval(LogW);
    End;
    CmClearHist :
    Begin
      RecentN := 0; SaveRecent;
    End;
    CmSelAll :
    Begin
      If Lv[LvRemote].Focus Then N := LvRemote Else N := LvLocal;
      For I := 0 To LvCount(N) - 1 Do
        If LvE(N, I)^.Name <> '..' Then LvSetSel(N, I, True);
      LvRepaint(N); ListChanged(N);
    End;
    CmRefresh :
    Begin
      LocalRefresh;
      If Connected Then AddCmd(OpList, '', '', 0);
    End;
    CmShowLog :
    Begin
      ShowLog := Not ShowLog; MCheck(MView, CmShowLog, ShowLog); Layout;
    End;
    CmShowQueue :
    Begin
      ShowQueue := Not ShowQueue; MCheck(MView, CmShowQueue, ShowQueue); Layout;
    End;
    CmHidden :
    Begin
      ShowHidden := Not ShowHidden; MCheck(MView, CmHidden, ShowHidden);
      LocalRefresh;
      If Connected Then AddCmd(OpList, '', '', 0);
    End;
    CmProcess : StartQueue;
    CmStop, CmCancel :
    Begin
      QRun := False;
      If Busy Then
      Begin
        XfCancel := True;
        LogMsg(LgError, 'Interrompu par l''utilisateur');
      End;
      For I := 0 To CmdN - 1 Do Cmds[I].Op := 0;
      CmdN := 0;
      QueueChanged;
    End;
    CmClearQ :
    Begin
      N := 0;
      For I := 0 To QN - 1 Do
        If Queue^[I].State = QsRun Then Begin Queue^[N] := Queue^[I]; Inc(N); End;
      QN := N;
      If QCur >= 0 Then QCur := 0;
      QueueChanged;
    End;
    CmClearDone :
    Begin
      N := 0;
      For I := 0 To QN - 1 Do
        If Queue^[I].State <> QsOk Then
        Begin
          If I = QCur Then QCur := N;
          Queue^[N] := Queue^[I]; Inc(N);
        End;
      QN := N;
      QueueChanged;
    End;
    CmRetry :
    Begin
      For I := 0 To QN - 1 Do
        If Queue^[I].State = QsFail Then
        Begin
          Queue^[I].State := QsWait; Queue^[I].Err := ''; Queue^[I].Done := 0;
        End;
      QTab := 0;
      StartQueue;
    End;
    CmOvAsk, CmOvOver, CmOvSkip :
    Begin
      OverMode := Cmd - CmOvAsk;
      MCheck(MOver, CmOvAsk, OverMode = OvAsk);
      MCheck(MOver, CmOvOver, OverMode = OvOver);
      MCheck(MOver, CmOvSkip, OverMode = OvSkip);
    End;
    CmReconnect :
      If HaveSite Then
      Begin
        AddCmd(OpConnect, '', '', 0);
        SetStatus('Reconnexion '#224' ' + CurSite.Host + '...');
      End;
    CmDisconnect :
    Begin
      QRun := False;
      If Busy Then XfCancel := True;
      AddCmd(OpDisconnect, '', '', 0);
    End;
    CmRaw :
      If Not Connected Then Ask('Aucune connexion en cours.', 'Commande', MB_OK Or MB_ICONINFO)
      Else
      Begin
        S := '';
        If InputBox('Entrer une commande personnalis'#233'e', 'Commande FTP (par exemple SITE HELP) :', S, False) Then
          If TrimS(S) <> '' Then AddCmd(OpRaw, TrimS(S), '', 0);
      End;
    CmCdR :
      If Connected Then
      Begin
        S := RemPath;
        If InputBox('Changer de dossier', 'Dossier distant :', S, False) Then AddCmd(OpCd, TrimS(S), '', 0);
      End;
    CmMkdirRem, CmMkdirR :
      If Connected Then
      Begin
        S := 'nouveau dossier';
        If InputBox('Cr'#233'er un dossier', 'Nom du dossier '#224' cr'#233'er dans ' + RemPath + ' :', S, False) Then
          If TrimS(S) <> '' Then
            If Pos('/', S) = 1 Then AddCmd(OpMkdir, TrimS(S), '', 0)
            Else AddCmd(OpMkdir, RJoin(RemPath, TrimS(S)), '', 0);
      End;
    CmHelp :
      Ask('Connectez-vous avec la barre de connexion rapide (h'#244'te, identifiant, mot de passe, port : 21 pour FTP, 22 '+
          'pour SFTP, ou sftp://serveur) ou avec le Gestionnaire de sites. Double-cliquez sur un fichier pour le '+
          'transf'#233'rer, ou faites-le glisser d''un panneau a l''autre. Les menus contextuels (clic droit) '+
          'offrent les autres operations.', 'Aide', MB_OK Or MB_ICONINFO);
    CmAbout :
      Ask('Client FTP pour OS/2-0 - version 1.0|FTP et SFTP (SSH-2) - '#169' 2026 Sylvain Maltais|'+
          'Port'#233' de Pasdows 95 ; compil'#233' par OS2PC (OS/2 Pascal Compiler).', 'A propos de Client FTP',
          MB_OK Or MB_ICONINFO);
    CmUpload : Enqueue(True, True);
    CmAddQL : Enqueue(True, False);
    CmDownload : Enqueue(False, True);
    CmAddQR : Enqueue(False, False);
    CmOpenL :
    Begin
      I := FirstSel(LvLocal);
      If (I >= 0) And (LocPath <> '') Then
      Begin
        E := LvE(LvLocal, I);
        If Not E^.Dir Then OpenLocal(LJoin(LocPath, E^.Name));
      End;
    End;
    CmEnterL : ListOpen(LvLocal);
    CmEnterR : ListOpen(LvRemote);
    CmMkdirL :
      If LocPath <> '' Then
      Begin
        S := 'Nouveau dossier';
        If InputBox('Cr'#233'er un dossier', 'Nom du dossier '#224' cr'#233'er dans ' + LocPath + ' :', S, False) Then
          If TrimS(S) <> '' Then
          Begin
            If Not MkDir(LJoin(LocPath, TrimS(S))) Then
              Ask('Impossible de cr'#233'er le dossier.', 'Site local', MB_OK Or MB_ICONERROR);
            LocalRefresh;
          End;
      End;
    CmRefreshL : LocalRefresh;
    CmRefreshR : If Connected Then AddCmd(OpList, '', '', 0);
    CmDeleteL :
    Begin
      N := SelCount(LvLocal);
      If (N = 0) Or (LocPath = '') Then Exit;
      If N = 1 Then S := 'Voulez-vous vraiment supprimer "' + LvE(LvLocal, FirstSel(LvLocal))^.Name + '" ?'
      Else S := 'Voulez-vous vraiment supprimer ces ' + IStr(N) + ' '#233'l'#233'ments ?';
      If Ask(S, 'Confirmer la suppression', MB_YESNO Or MB_ICONQUESTION) <> IDYES Then Exit;
      Ok := True;
      For I := 0 To LocN - 1 Do
        If LocSel[I] Then
        Begin
          E := LvE(LvLocal, I);
          If E^.Name <> '..' Then
            If Not LDelete(LJoin(LocPath, E^.Name), E^.Dir, 0) Then Ok := False;
        End;
      If Not Ok Then Ask('Certains '#233'l'#233'ments n''ont pas pu '#234'tre supprim'#233's.', 'Site local', MB_OK Or MB_ICONWARNING);
      LocalRefresh;
    End;
    CmRenameL :
    Begin
      I := FirstSel(LvLocal);
      If (I < 0) Or (LocPath = '') Then Exit;
      Old := LvE(LvLocal, I)^.Name; S := Old;
      If InputBox('Renommer', 'Nouveau nom de "' + Old + '" :', S, False) Then
        If (TrimS(S) <> '') And (S <> Old) Then
        Begin
          PutZ(LongInt(@NameZ2), LJoin(LocPath, TrimS(S)));
          If DosMove(Z(LJoin(LocPath, Old)), LongInt(@NameZ2)) <> 0 Then
            Ask('Impossible de renommer "' + Old + '".', 'Site local', MB_OK Or MB_ICONERROR);
          LocalRefresh;
        End;
    End;
    CmDeleteR :
    Begin
      N := SelCount(LvRemote);
      If (N = 0) Or Not Connected Then Exit;
      If Busy Then
      Begin
        Ask('Une op'#233'ration est en cours ; attendez qu''elle se termine.', 'Site distant', MB_OK Or MB_ICONINFO);
        Exit;
      End;
      If N = 1 Then S := 'Voulez-vous vraiment supprimer "' + LvE(LvRemote, FirstSel(LvRemote))^.Name + '" du serveur ?'
      Else S := 'Voulez-vous vraiment supprimer ces ' + IStr(N) + ' '#233'l'#233'ments du serveur ?';
      If Ask(S, 'Confirmer la suppression', MB_YESNO Or MB_ICONQUESTION) <> IDYES Then Exit;
      DelN := 0;
      For I := 0 To RemN - 1 Do
        If RemSel[I] And (LvE(LvRemote, I)^.Name <> '..') Then
        Begin
          DelNames^[DelN] := LvE(LvRemote, I)^; Inc(DelN);
        End;
      AddCmd(OpDelete, '', '', DelN);
    End;
    CmRenameR :
    Begin
      I := FirstSel(LvRemote);
      If (I < 0) Or Not Connected Then Exit;
      Old := LvE(LvRemote, I)^.Name; S := Old;
      If InputBox('Renommer', 'Nouveau nom de "' + Old + '" :', S, False) Then
        If (TrimS(S) <> '') And (S <> Old) Then
          AddCmd(OpRename, RJoin(RemPath, Old), RJoin(RemPath, TrimS(S)), 0);
    End;
    CmCopyUrl :
    Begin
      I := FirstSel(LvRemote);
      If (I < 0) Or Not HaveSite Then Exit;
      If CurSite.Proto = PrSftp Then S := 'sftp://' Else S := 'ftp://';
      If (CurSite.User <> '') And (CurSite.Logon <> LgAnon) Then S := S + CurSite.User + '@';
      S := S + CurSite.Host;
      If ((CurSite.Proto = PrSftp) And (CurSite.Port <> 22)) Or ((CurSite.Proto = PrFtp) And (CurSite.Port <> 21)) Then
        S := S + ':' + IStr(CurSite.Port);
      S := S + RJoin(RemPath, LvE(LvRemote, I)^.Name);
      CopyToClip(S);
      SetStatus('Copi'#233' : ' + S);
    End;
    CmChmod :
    Begin
      I := FirstSel(LvRemote);
      If (I < 0) Or Not Connected Then Exit;
      E := LvE(LvRemote, I);
      Mode := PermMode(E^.Perm);
      If SelCount(LvRemote) > 1 Then S := IStr(SelCount(LvRemote)) + ' '#233'l'#233'ments' Else S := E^.Name;
      If ChmodBox(S, Mode) Then
        For I := 0 To RemN - 1 Do
          If RemSel[I] And (LvE(LvRemote, I)^.Name <> '..') Then
            AddCmd(OpChmod, RJoin(RemPath, LvE(LvRemote, I)^.Name), '', Mode);
    End;
    CmQRemove :
    Begin
      For I := 0 To QShown - 1 Do
        If QSel[I] And (Queue^[QIdx[I]].State <> QsRun) Then Queue^[QIdx[I]].State := -1;
      N := 0;
      For I := 0 To QN - 1 Do
        If Queue^[I].State <> -1 Then
        Begin
          If I = QCur Then QCur := N;
          Queue^[N] := Queue^[I]; Inc(N);
        End;
      QN := N;
      QueueChanged;
    End;
  Else
    If (Cmd >= CmRecent) And (Cmd < CmRecent + RecentN) Then
    Begin
      I := Cmd - CmRecent;
      SetText(EHost, Recent[I].Host); SetText(EUser, Recent[I].User);
      SetText(EPass, Recent[I].Pass); SetText(EPort, IStr(Recent[I].Port));
      If Recent[I].Proto = PrSftp Then SetText(EHost, 'sftp://' + Recent[I].Host);
      ConnectSite(Recent[I]);
    End;
  End;
End;

Procedure ListCommand(K, Cmd : LongInt);
Begin
  Case Cmd Of
    1 : If K = LvLocal Then LocalGo(LParent(LocPath))
        Else If (K = LvRemote) And Connected Then AddCmd(OpCd, RParent(RemPath), '', 0);
    2 : If K = LvLocal Then DoMenu(CmDeleteL)
        Else If K = LvRemote Then DoMenu(CmDeleteR)
        Else DoMenu(CmQRemove);
    3 : If K = LvLocal Then DoMenu(CmRenameL) Else If K = LvRemote Then DoMenu(CmRenameR);
    4 : DoMenu(CmRefresh);
  End;
End;

Procedure ListOpen(K : LongInt);
Var E : PEntry; I : LongInt;
Begin
  If K = LvQueue Then Exit;
  I := Lv[K].Cur;
  If (I < 0) Or (I >= LvCount(K)) Then Exit;
  E := LvE(K, I);
  If K = LvLocal Then
  Begin
    If E^.Name = '..' Then LocalGo(LParent(LocPath))
    Else If E^.Dir Then
    Begin
      If LocPath = '' Then LocalGo(E^.Name + '\') Else LocalGo(LJoin(LocPath, E^.Name));
    End
    Else If RemOk Then Enqueue(True, True);
  End
  Else
  Begin
    If Not Connected Then Exit;
    If E^.Name = '..' Then AddCmd(OpCd, RParent(RemPath), '', 0)
    Else If E^.Dir Or E^.Link Then AddCmd(OpCd, RJoin(RemPath, E^.Name), '', 0)
    Else Enqueue(False, True);
  End;
End;

Procedure ListDrop(K, Target : LongInt);
Begin
  If (K = LvLocal) And (Target = LvRemote) Then Enqueue(True, True)
  Else If (K = LvRemote) And (Target = LvLocal) Then Enqueue(False, True)
  Else If (K = LvLocal) And (Target = LvQueue) Then Enqueue(True, False)
  Else If (K = LvRemote) And (Target = LvQueue) Then Enqueue(False, False);
End;

Procedure ListMenu(K, X, Y : LongInt);
Var M, N : LongInt; E : PEntry; One : Boolean;
Begin
  M := CreatePopupMenu;
  N := SelCount(K);
  One := False;
  If N = 1 Then
  Begin
    E := LvE(K, FirstSel(K));
    One := E^.Dir;
  End;
  If K = LvLocal Then
  Begin
    MItem(M, CmUpload, '~Envoyer');
    MItem(M, CmAddQL, '~Ajouter '#224' la file d''attente');
    MItem(M, 0, '');
    If One Then MItem(M, CmEnterL, 'Ou~vrir le dossier') Else MItem(M, CmOpenL, '~Ouvrir');
    MItem(M, 0, '');
    MItem(M, CmMkdirL, '~Cr'#233'er un dossier...');
    MItem(M, CmRefreshL, 'Ac~tualiser');
    MItem(M, 0, '');
    MItem(M, CmDeleteL, '~Supprimer');
    MItem(M, CmRenameL, '~Renommer');
    If (N = 0) Or (LocPath = '') Or Not RemOk Then
    Begin
      MEnable(M, CmUpload, False); MEnable(M, CmAddQL, False);
    End;
    If (N = 0) Or (LocPath = '') Then
    Begin
      MEnable(M, CmOpenL, False); MEnable(M, CmDeleteL, False); MEnable(M, CmRenameL, False);
    End;
    If N > 1 Then MEnable(M, CmRenameL, False);
    If LocPath = '' Then MEnable(M, CmMkdirL, False);
  End
  Else If K = LvRemote Then
  Begin
    MItem(M, CmDownload, '~T'#233'l'#233'charger');
    MItem(M, CmAddQR, '~Ajouter '#224' la file d''attente');
    If One Then MItem(M, CmEnterR, 'Ou~vrir le dossier');
    MItem(M, 0, '');
    MItem(M, CmMkdirR, '~Cr'#233'er un dossier...');
    MItem(M, CmRefreshR, 'Ac~tualiser');
    MItem(M, 0, '');
    MItem(M, CmDeleteR, '~Supprimer');
    MItem(M, CmRenameR, '~Renommer');
    MItem(M, CmCopyUrl, 'Copier l''~URL dans le presse-papiers');
    MItem(M, CmChmod, '~Droits d''acc'#232's...');
    If (N = 0) Or Not Connected Then
    Begin
      MEnable(M, CmDownload, False); MEnable(M, CmAddQR, False); MEnable(M, CmDeleteR, False);
      MEnable(M, CmRenameR, False); MEnable(M, CmCopyUrl, False); MEnable(M, CmChmod, False);
    End;
    If N > 1 Then MEnable(M, CmRenameR, False);
    If Not Connected Then
    Begin
      MEnable(M, CmMkdirR, False); MEnable(M, CmRefreshR, False);
    End;
  End
  Else
  Begin
    MItem(M, CmProcess, '~Traiter la file d''attente');
    MItem(M, CmStop, '~Arr'#234'ter');
    MItem(M, 0, '');
    MItem(M, CmQRemove, '~Supprimer les '#233'l'#233'ments choisis');
    MItem(M, CmRetry, '~Recommencer les transferts '#233'chou'#233's');
    MItem(M, CmClearDone, 'Effacer les transferts r'#233'~ussis');
    MItem(M, CmClearQ, '~Vider la file d''attente');
    If N = 0 Then MEnable(M, CmQRemove, False);
    If QRun Then MEnable(M, CmProcess, False) Else MEnable(M, CmStop, False);
  End;
  TrackPopupMenu(M, X, Y);
End;

Procedure ListChanged(K : LongInt);
Begin
  InvalRect(MainWnd, 0, PaneB - 18, CW0, PaneB);
End;

{ ---- menus ---- }

Procedure BuildMenus;
Var M, Sub : LongInt;
Begin
  MainMenu := CreateMenu;
  M := CreatePopupMenu;
  MItem(M, CmSiteMgr, '~Gestionnaire de sites...');
  MItem(M, CmCopySite, '~Copier la connexion actuelle dans le Gestionnaire de sites...');
  MItem(M, 0, '');
  MItem(M, CmImport, '~Importer des sites (XML)...');
  MItem(M, CmExport, '~Exporter les sites (XML)...');
  MItem(M, 0, '');
  MItem(M, CmExit, '~Quitter');
  MSub(MainMenu, M, '~Fichier');
  M := CreatePopupMenu;
  MItem(M, CmSelAll, '~S'#233'lectionner tout');
  MItem(M, 0, '');
  MItem(M, CmClearLog, 'Effacer le ~journal des messages');
  MItem(M, CmClearHist, 'Effacer l''~historique de connexion rapide');
  MSub(MainMenu, M, #201'~dition');
  MView := CreatePopupMenu;
  MItem(MView, CmRefresh, '~Actualiser'#9'F5');
  MItem(MView, 0, '');
  MItem(MView, CmShowLog, '~Journal des messages');
  MItem(MView, CmShowQueue, '~File d''attente');
  MItem(MView, CmHidden, 'Fichiers ~masqu'#233's');
  MCheck(MView, CmShowLog, ShowLog);
  MCheck(MView, CmShowQueue, ShowQueue);
  MCheck(MView, CmHidden, ShowHidden);
  MSub(MainMenu, MView, '~Affichage');
  MTrans := CreatePopupMenu;
  MItem(MTrans, CmProcess, '~Traiter la file d''attente');
  MItem(MTrans, CmStop, '~Arr'#234'ter');
  MItem(MTrans, 0, '');
  MItem(MTrans, CmRetry, '~Recommencer les transferts '#233'chou'#233's');
  MItem(MTrans, CmClearDone, 'Effacer les transferts r'#233'~ussis');
  MItem(MTrans, CmClearQ, '~Vider la file d''attente');
  MItem(MTrans, 0, '');
  Sub := CreatePopupMenu;
  MItem(Sub, CmOvAsk, '~Demander');
  MItem(Sub, CmOvOver, '~Toujours remplacer');
  MItem(Sub, CmOvSkip, 'Toujours ~ignorer');
  MCheck(Sub, CmOvAsk, True);
  MSub(MTrans, Sub, 'Si le fichier ~existe');
  MOver := Sub;
  MSub(MainMenu, MTrans, '~Transfert');
  MSrv := CreatePopupMenu;
  MItem(MSrv, CmCancel, '~Annuler l''op'#233'ration en cours');
  MItem(MSrv, 0, '');
  MItem(MSrv, CmReconnect, '~Reconnecter');
  MItem(MSrv, CmDisconnect, '~D'#233'connecter');
  MItem(MSrv, 0, '');
  MItem(MSrv, CmCdR, '~Changer de dossier...');
  MItem(MSrv, CmMkdirRem, 'Cr'#233'er un d~ossier...');
  MItem(MSrv, CmRaw, '~Entrer une commande personnalis'#233'e...');
  MSub(MainMenu, MSrv, '~Serveur');
  M := CreatePopupMenu;
  MItem(M, CmHelp, '~Aide');
  MItem(M, 0, '');
  MItem(M, CmAbout, '~A propos de Client FTP...');
  MSub(MainMenu, M, '~?');
  SetMenu(MainMenu);
End;

{ ---- procedure de la fenetre ---- }

Function TbAt(X, Y : LongInt) : LongInt;
Var I : LongInt;
Begin
  TbAt := -1;
  If (Y < 3) Or (Y >= 27) Then Exit;
  For I := 0 To TbN - 1 Do
    If (X >= TbX(I)) And (X < TbX(I) + 24) Then TbAt := I;
End;

Procedure TbClick(I : LongInt);
Begin
  If Not TbEnabled(I) Then Exit;
  Case I Of
    0 : DoMenu(CmSiteMgr);
    1 : DoMenu(CmRefresh);
    2 : DoMenu(CmProcess);
    3 : DoMenu(CmCancel);
    4 : DoMenu(CmDisconnect);
    5 : DoMenu(CmReconnect);
  Else
    DoMenu(CmShowQueue);
  End;
End;

Procedure MakeChildren(H : LongInt);
Var K : LongInt;
Begin
  EHost := Ctl(H, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 0, 0, 10, 10, IdQHost);
  EUser := Ctl(H, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 0, 0, 10, 10, IdQUser);
  EPass := Ctl(H, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or ES_PASSWORD Or WS_TABSTOP, 0, 0, 10, 10, IdQPass);
  EPort := Ctl(H, 'EDIT', '', WS_BORDER Or WS_TABSTOP, 0, 0, 10, 10, IdQPort);
  BConn := Ctl(H, 'BUTTON', 'Connexion', BS_DEFPUSHBUTTON Or WS_TABSTOP, 0, 0, 10, 10, IdQuick);
  BHist := Ctl(H, 'BUTTON', #25, WS_TABSTOP, 0, 0, 10, 10, IdHist);
  ELoc := Ctl(H, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 0, 0, 10, 10, IdLocPath);
  ERem := Ctl(H, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 0, 0, 10, 10, IdRemPath);
  LogW := WinCreateWindow(H, Z2('PFLOG'), 0, PM_WS_VISIBLE, 0, 0, 100, 60, H, HWND_BOTTOM, 30, 0, 0);
  LogSb := WinCreateWindow(LogW, WC_SCROLLBAR, 0, PM_WS_VISIBLE Or PM_SBS_VERT, 0, 0, SbW, 60, LogW, HWND_BOTTOM, 31, 0, 0);
  For K := 0 To 2 Do
  Begin
    Lv[K].H := WinCreateWindow(H, Z2('PFLIST'), 0, PM_WS_VISIBLE Or PM_WS_TABSTOP, 0, 0, 100, 100, H, HWND_BOTTOM, 40 + K,
                               0, 0);
    Lv[K].Sb := WinCreateWindow(Lv[K].H, WC_SCROLLBAR, 0, PM_WS_VISIBLE Or PM_SBS_VERT, 0, 0, SbW, 100, Lv[K].H,
                                HWND_BOTTOM, 50 + K, 0, 0);
  End;
End;

Function MainProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var Id, Code, X, Y, I : LongInt; F : LongInt;
Begin
  MainProc0 := 0;
  Case Msg Of
    WM_SIZE :
    Begin
      CW0 := LP And $FFFF; CH0 := (LP Shr 16) And $FFFF;
      If EHost <> 0 Then Layout;
    End;
    WM_PAINT : MainPaint(H);
    WM_COMMAND :
    Begin
      Id := WP And $FFFF; Code := (WP Shr 16) And $FFFF;
      If Id = IdQuick Then
      Begin
        { Entree : selon le controle qui a le focus }
        F := WinQueryFocus(HWND_DESKTOP);
        If F = ELoc Then LocalGo(CtlText(ELoc))
        Else If F = ERem Then
        Begin
          If Connected Then AddCmd(OpCd, TrimS(CtlText(ERem)), '', 0);
        End
        Else If F = Lv[LvLocal].H Then ListOpen(LvLocal)
        Else If F = Lv[LvRemote].H Then ListOpen(LvRemote)
        Else QuickConnect;
      End
      Else If Id = IdHist Then ShowRecent
      Else If Id >= 100 Then DoMenu(Id);
    End;
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK :
    Begin
      X := S16(LP); Y := S16(LP Shr 16);
      I := TbAt(X, Y);
      If I >= 0 Then
      Begin
        TbDown := I;
        Dummy := WinSetCapture(HWND_DESKTOP, H);
        Inval(H);
      End
      Else If ShowQueue And (Y >= QY) And (Y < QY + TabH) Then
      Begin
        X := X - 4;
        For I := 0 To 2 Do
        Begin
          Case I Of
            0 : Code := Length('Fichiers en attente (' + IStr(QCount(QsWait)) + ')');
            1 : Code := Length('Transferts echoues (' + IStr(QCount(QsFail)) + ')');
          Else
            Code := Length('Transferts reussis (' + IStr(QCount(QsOk)) + ')');
          End;
          Code := Code * CW + 17;
          If (X >= 0) And (X < Code) Then
          Begin
            QTab := I;
            QueueChanged;
            Lv[LvQueue].Top := 0;
            LvSync(LvQueue);
          End;
          X := X - Code;
        End;
      End;
    End;
    WM_LBUTTONUP :
      If TbDown >= 0 Then
      Begin
        Dummy := WinSetCapture(HWND_DESKTOP, 0);
        I := TbAt(S16(LP), S16(LP Shr 16));
        Code := TbDown;
        TbDown := -1;
        Inval(H);
        If I = Code Then TbClick(I);
      End;
    WM_MOUSEMOVE :
    Begin
      I := TbAt(S16(LP), S16(LP Shr 16));
      If I <> TbHot Then
      Begin
        TbHot := I;
        If I >= 0 Then StatusTxt := TbTip(I)
        Else If Busy Then StatusTxt := 'Op'#233'ration en cours...'
        Else StatusTxt := 'Pr'#234't';
        Inval(H);
      End;
    End;
    WM_TIMER :
      If QRun Or Busy Then
      Begin
        LvRepaint(LvQueue);
        If (QCur >= 0) And (QCur < QN) Then
        Begin
          StatusTxt := BaseOf(Queue^[QCur].Rem) + ' : ' + SizeTxt(Queue^[QCur].Done);
          If QSpeed > 0 Then StatusTxt := StatusTxt + ' - ' + SizeTxt(QSpeed) + '/s';
        End;
        Inval(H);
      End;
    WM_NETLOG :
    Begin
      LogPosted := False;
      LogSync(True);
      Inval(LogW);
    End;
    WM_NETSTATE :
    Begin
      UpdateTitle;
      If Busy Then StatusTxt := 'Op'#233'ration en cours...'
      Else If Connected Then StatusTxt := 'Connect'#233' '#224' ' + CurSite.Host
      Else StatusTxt := 'Pr'#234't';
      MEnable(MSrv, CmDisconnect, Connected);
      MEnable(MSrv, CmReconnect, HaveSite And Not Connected);
      Inval(H);
    End;
    WM_NETLIST :
    Begin
      LvReset(LvRemote);
      If RemOk Then SetText(ERem, RemPath) Else SetText(ERem, '');
      ListChanged(LvRemote);
    End;
    WM_NETQUEUE :
      If WP = 1 Then
      Begin
        { progression seulement : ne pas toucher a la selection }
        LvRepaint(LvQueue);
        If (QCur >= 0) And (QCur < QN) Then
        Begin
          StatusTxt := BaseOf(Queue^[QCur].Rem) + ' : ' + SizeTxt(Queue^[QCur].Done);
          If QSpeed > 0 Then StatusTxt := StatusTxt + ' - ' + SizeTxt(QSpeed) + '/s';
        End;
        Inval(H);
      End
      Else QueueChanged;
    WM_NETLOCAL :
      If WP = 1 Then LocalGo(PendLocal) Else LocalRefresh;
    WM_CLOSE :
    Begin
      If QRun And (QCount(QsWait) > 0) Then
        If Ask('Des transferts sont en cours. Voulez-vous vraiment quitter ?', 'Client FTP',
               MB_YESNO Or MB_ICONQUESTION) <> IDYES Then Exit;
      Dummy := WinPostMsg(H, PM_WM_QUIT, 0, 0);
    End;
  Else
    MainProc0 := 0;
  End;
End;

Var
  InMainKey : Boolean;

{ procedure de PM de la fenetre principale : messages de PM traduits en
  messages de Pasdows (souris : Y vers le bas) ; Entree = bouton
  Connexion (selon le controle qui a le focus), Tab = controle suivant
  (WinDefDlgProc), F5 = Actualiser ; WM_NETASK : boite de message
  demandee par le fil reseau (verrou libre pendant la boite) }
Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var R, Fl, V : LongInt;
Begin
  R := 0;
  Case Msg Of
    PM_WM_ERASEBACKGROUND : R := 0;
    WM_NETASK :
    Begin
      AskRes := WinMessageBox(HWND_DESKTOP, MainFrame, LongInt(@WkZ[0]), LongInt(@WkZ2[0]), 0, AskFl);
      Dummy0 := DosPostEventSem(AskEv);
    End;
    PM_WM_CHAR :
    Begin
      Fl := Mp1 And $FFFF; V := (Mp2 Shr 16) And $FFFF;
      If ((Fl And PM_KC_KEYUP) <> 0) Or ((Fl And PM_KC_VIRTUALKEY) = 0) Then R := WinDefWindowProc(H, Msg, Mp1, Mp2)
      Else If (V = PM_VK_NEWLINE) Or (V = PM_VK_ENTER) Then
      Begin
        BigLock;
        Dummy0 := MainProc0(H, WM_COMMAND, IdQuick, 0);
        BigUnlock;
        R := 1;
      End
      Else If V = PM_VK_F1 + 4 Then
      Begin
        BigLock;
        DoMenu(CmRefresh);
        BigUnlock;
        R := 1;
      End
      Else If ((V = PM_VK_TAB) Or (V = PM_VK_BACKTAB)) And Not InMainKey Then
      Begin
        InMainKey := True;
        R := WinDefDlgProc(H, Msg, Mp1, Mp2);
        InMainKey := False;
      End
      Else R := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
  Else
    BigLock;
    Case Msg Of
      PM_WM_SIZE : Dummy0 := MainProc0(H, WM_SIZE, 0, Mp2);
      PM_WM_PAINT : Dummy0 := MainProc0(H, WM_PAINT, 0, 0);
      PM_WM_COMMAND : Dummy0 := MainProc0(H, WM_COMMAND, Mp1 And $FFFF, 0);
      PM_WM_CONTROL : R := 0;
      PM_WM_TIMER : Dummy0 := MainProc0(H, WM_TIMER, Mp1, 0);
      PM_WM_BUTTON1DOWN :
      Begin
        Dummy0 := MainProc0(H, WM_LBUTTONDOWN, 0, MousePt(H, Mp1));
        R := 1;
      End;
      PM_WM_BUTTON1DBLCLK :
      Begin
        Dummy0 := MainProc0(H, WM_LBUTTONDBLCLK, 0, MousePt(H, Mp1));
        R := 1;
      End;
      PM_WM_BUTTON1UP :
      Begin
        Dummy0 := MainProc0(H, WM_LBUTTONUP, 0, MousePt(H, Mp1));
        R := 1;
      End;
      PM_WM_MOUSEMOVE :
      Begin
        Dummy0 := MainProc0(H, WM_MOUSEMOVE, 0, MousePt(H, Mp1));
        R := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
      WM_NETLOG, WM_NETSTATE, WM_NETLIST, WM_NETQUEUE, WM_NETLOCAL : Dummy0 := MainProc0(H, Msg, Mp1, Mp2);
      PM_WM_CLOSE :
      Begin
        Dummy0 := MainProc0(H, WM_CLOSE, 0, 0);
      End;
    Else
      R := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
    BigUnlock;
  End;
  MainProc := R;
End;

{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

Var
  Tid, Fw, Fh, Fl : LongInt;

Begin
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20); ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  DetectOem;
  FindAppDir;
  Dummy0 := DosCreateMutexSem(0, LongInt(@LockSem), 0, 0);
  LockOn := True;
  LocL := PEntArr(TlNew(SizeOf(TEntArr)));
  RemL := PEntArr(TlNew(SizeOf(TEntArr)));
  TmpL := PEntArr(TlNew(SizeOf(TEntArr)));
  DelNames := PEntArr(TlNew(SizeOf(TEntArr)));
  Queue := PQArr(TlNew(SizeOf(TQArr)));
  LogL := PLogArr(TlNew(SizeOf(TLogArr)));
  Sites := PSiteArr(TlNew(SizeOf(TSiteArr)));
  SsSock := -1; QCur := -1; DragFrom := -1; TbHot := -1; TbDown := -1;
  ShowLog := True; ShowQueue := True; ShowHidden := True;
  Lv[LvLocal].SortCol := 0; Lv[LvRemote].SortCol := 0;
  RegClass('PFMAIN', LongInt(@MainProc));
  RegClass('PFLIST', LongInt(@LvProc));
  RegClass('PFLOG', LongInt(@LogProc));
  RegClass('PFDLG', LongInt(@DlgProc));
  BigLock;
  LoadSites;
  LoadRecent;
  StatusTxt := 'Pr'#234't';
  BigUnlock;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  MainWnd := 0;
  MainFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z2('PFMAIN'), Z('Client FTP'), 0, 0, 0,
                                  LongInt(@MainWnd));
  BigLock;
  MakeChildren(MainWnd);
  BuildMenus;
  LocPath := 'C:\';
  LocalGo(LocPath);
  If RecentN > 0 Then
  Begin
    If Recent[0].Proto = PrSftp Then SetText(EHost, 'sftp://' + Recent[0].Host) Else SetText(EHost, Recent[0].Host);
    SetText(EUser, Recent[0].User);
    SetText(EPort, IStr(Recent[0].Port));
  End;
  LogMsg(LgStatus, 'Client FTP pr'#234't. Sites : ' + AppDir + 'sitemanager.xml (' + IStr(SiteN) + ' site(s)).');
  BigUnlock;
  Fw := MinI(ScrW, 960); Fh := MinI(ScrH - 32, 700);
  If ScrW <= 800 Then
    Dummy0 := WinSetWindowPos(MainFrame, HWND_TOP, 0, 0, ScrW, ScrH, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                              SWP_ACTIVATE Or SWP_MAXIMIZE)
  Else
    Dummy0 := WinSetWindowPos(MainFrame, HWND_TOP, (ScrW - Fw) Div 2, MaxI(0, (ScrH - Fh) Div 2 + 16), Fw, Fh,
                              SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy0 := WinSetActiveWindow(HWND_DESKTOP, MainFrame);
  BigLock;
  Layout;
  QFilter;
  BigUnlock;
  Dummy0 := WinStartTimer(Hab, MainWnd, 1, 500);
  Dummy0 := DosCreateEventSem(0, LongInt(@WorkEv), 0, 0);
  Dummy0 := DosCreateEventSem(0, LongInt(@AskEv), 0, 0);
  If DosCreateThread(LongInt(@Tid), LongInt(@WorkThread), 0, 0, 262144) <> 0 Then
    LogMsg(LgError, 'Impossible de cr'#233'er le fil r'#233'seau.');
  WFocus(EHost);
  MsgLoop;
  AppQuit := True;
  Dummy0 := DosPostEventSem(WorkEv);
  Dummy0 := DosSleep(300);
  Dummy0 := WinDestroyWindow(MainFrame);
  Dummy0 := DosExit(1, 0);
End.
