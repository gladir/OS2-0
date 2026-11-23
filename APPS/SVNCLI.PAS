{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: SVNCLI - Client SVN d'OS/2-0 (Presentation Manager), client
  Subversion dans le genre du Client GitHub (et de GitHub Desktop), porte
  du Client SVN de Pasdows 95.
}

Program SVNCLI;

{$R-,S-,I-}

{ Compilation : OS2PC APPS\SVNCLI.PAS SVNCLI.EXE

  Bureau - Outils reseau - Client SVN (SVNCLI.EXE).
  Porte de APPS/SVNCLI.PAS de Pasdows 95 (Win32, WPC -CW32) : les API de
  Windows sont remplacees par celles d'OS/2 (PMWIN, PMGPI, PMMERGE,
  DOSCALLS, TCPIP32, TLS32) ; fichier unique, sans unite ni fichier
  d'inclusion.

  Repris de Pasdows 95 sans changement (Pascal pur) :
  - Subversion ecrit entierement en Pascal : MD5 et HMAC-MD5, copie de
    travail dans .pasvn (entrees, copies de base rangees par MD5), statut
    (cache taille/date), extraction, mise a jour (les dossiers dont la
    revision du dernier changement n'a pas bouge ne sont pas relus),
    fusion a trois voies ligne par ligne avec conflits comme svn (.mine,
    .rN), validation (ajouts, suppressions, dossiers, svn:ignore),
    annulation, branches (trunk, branches, tags : creation par copie sur
    le serveur et changement de branche), journal avec chemins modifies,
    differences (patience + plus longue sous-suite commune) ;
  - svn:// (svnserve, protocole ra_svn version 2 en S-expressions,
    authentification ANONYMOUS et CRAM-MD5, pilotage de l'editeur de
    commit, fenetres svndiff0 de 64 Ko) et http(s):// (Apache et
    mod_dav_svn : WebDAV et protocole HTTP v2 de Subversion, OPTIONS,
    PROPFIND, GET, REPORT log-report, POST create-txn-with-props, PUT en
    svndiff, MKCOL, DELETE, COPY, PROPPATCH, MERGE, authentification
    Basic) ;
  - la fenetre du Client GitHub : boutons Copie de travail actuelle,
    Branche actuelle et Mettre a jour, onglets Modifications (cases a
    cocher, resume et description de la validation, differences en
    couleurs) et Historique (revisions, chemins modifies, differences lues
    sur le serveur), menus Fichier, Edition, Affichage, Copie de travail,
    Branche et Aide, raccourcis clavier.

  Ce qui change pour OS/2 :
  - HTTP : WININET n'existe pas ; un client HTTP/1.1 est ecrit ici sur
    les sockets de TCPIP32.DLL (connexion gardee ouverte, corps
    Content-Length ou chunked, reponses 100 Continue passees), https://
    par TLS32.DLL (TLSOPEN, TLSSEND, TLSRECV, TLSCLOSE, TLSERROR), proxy
    pris dans les Options ou dans SET HTTP_PROXY=hote:port (URL complete
    en http://, tunnel CONNECT en https://) sauf pour le reseau local
    (localhost, 127.*, 10.*, 192.168.*, noms sans point) ;
  - svn:// : Winsock -> TCPIP32 (sock_init, gethostbyname, socket,
    connect, send, recv, shutdown, soclose) ;
  - fichiers : unite Dos et CreateFileA -> DosOpen, DosRead, DosWrite,
    DosSetFilePtr, DosQueryFileInfo, DosQueryPathInfo (taille et date du
    cache du statut), DosFindFirst/DosFindNext/DosFindClose, DosCreateDir,
    DosDeleteDir, DosDelete, DosMove, DosGetDateTime ; les noms de
    fichiers sont en page de codes 850 sur le disque (UTF-8 sur le
    serveur, ANSI dans le programme) ;
  - reglages : SVNCLI.INI (GetPrivateProfileString) -> OS2.INI par
    PrfQueryProfileString et PrfWriteProfileString (applications
    PM_SvnClient et PM_SvnClient_Identifiants) ;
  - fenetres : RegisterClassA/CreateWindowExA -> WinRegisterClass,
    WinCreateStdWindow (cadre a bordure de taille, liste des taches),
    WinCreateWindow ; controles de PM (WC_ENTRYFIELD, WC_MLE pour la
    description, WC_BUTTON, WC_STATIC, WC_LISTBOX, WC_SCROLLBAR) ; barre
    de menus et menus contextuels faits de gabarits (WinCreateMenu,
    WinPopupMenu, MM_SETITEMATTR, WM_INITMENU) ; boites de dialogue
    (WinCreateStdWindow avec FCF_DLGBORDER, WinDefDlgProc pour la
    tabulation) ; WinMessageBox ; presse-papiers (WinSetClipbrdData) ;
    minuterie (WinStartTimer) ; pointeur d'attente (WinQuerySysPointer) ;
  - dessin : GDI (FillRect, TextOutA, police MS Sans Serif 6 x 13) -> GPI
    en couleurs RVB (GpiCreateLogColorTable, GpiSetColor, GpiMove, GpiBox,
    GpiCharStringAt) avec la police de PM 8 x 16, ramenee a 6 x 16
    (GpiSetCharBox) pour les petits textes ; coordonnees de PM (origine en
    bas a gauche) : la couche de dessin retourne les ordonnees ; le fond
    de la fenetre principale est peint autour des fenetres enfants (pas de
    WS_CLIPCHILDREN) ;
  - SHBrowseForFolderA n'existe pas sous OS/2 : boite Choisir un dossier
    faite d'une liste de PM (lecteurs et sous-dossiers) ;
  - Ouvrir le fichier, Explorateur, invite de commandes : ShellExecuteA ->
    DosExecPgm (Bloc-notes, Navigateur Web, Paint... d'OS/2-0 selon
    l'extension, EXPLORER.EXE, CMD.EXE dans sa propre session) ;
  - les messages de Windows sont produits a partir de ceux de PM par les
    procedures de fenetre (MainProc, LvProc, DiffProc, DlgProc) :
    WM_PAINT, WM_SIZE, WM_BUTTON1DOWN (Y retourne), WM_CHAR (touches
    virtuelles de PM -> VK_), WM_VSCROLL et WM_HSCROLL (SB_), WM_CONTROL
    (EN_CHANGE, LN_SELECT, LN_ENTER) ; les raccourcis (Ctrl+Maj+P...) sont
    reconnus dans la boucle des messages avant WinDispatchMsg ;
  - le reseau tourne dans un fil de travail (DosCreateThread) ; un verrou
    (semaphore d'exclusion DosCreateMutexSem, DosRequestMutexSem,
    DosReleaseMutexSem) protege les chaines temporaires du runtime
    d'OS2PC partagees par les deux fils : le fil reseau le libere pendant
    les appels bloquants (connect, send, recv, poignee de main TLS) et
    pendant la progression ; il ne parle a l'interface que par WinPostMsg
    (WM_GITPROG, WM_GITDONE) ; l'identifiant du fil vient de
    DosGetInfoBlocks.

  Parametres :
    SVNCLI dossier            ouvre cette copie de travail (ajoutee a la
                              liste) ;
    SVNCLI URL dossier        l'extrait (comme svn checkout) dans la
                              fenetre ;
    SVNCLI /CHECKOUT URL dossier : extraction sans fenetre (procedures de
                              commandes, STARTUP.CMD), resultat sur COM1 ;
    /USER:nom /PASS:mot       identifiants pour le serveur de l'URL ;
    SVNCLI /TEST [URL...]     essais sans fenetre, resultats sur COM1
                              (lignes SVNCLI : ...) : MD5, HMAC-MD5,
                              svndiff0, differences, fusion, protocole
                              ra_svn, XML de WebDAV, en-tetes HTTP et URL,
                              svn:ignore, dates ; puis, pour chaque URL
                              (dossier trunk vide d'un depot de test) :
                              extraction, validations (ajouts, dossier,
                              svn:ignore, modification, suppression),
                              fusion, conflit et resolution, annulation,
                              journal, fichier d'une revision, branche.
  Proxy : Options, ou SET HTTP_PROXY=hote:port dans CONFIG.SYS. }

Const
  PS = '\';
  AllFiles = '*';

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
  WM_COMMAND = $0111; WM_TIMER = $0113; WM_HSCROLL = $0114; WM_VSCROLL = $0115;
  WM_MOUSEMOVE = $0200; WM_LBUTTONDOWN = $0201; WM_LBUTTONUP = $0202;
  WM_LBUTTONDBLCLK = $0203; WM_RBUTTONDOWN = $0204; WM_RBUTTONUP = $0205;
  WM_MOUSEWHEEL = $020A;
  { messages du fil reseau a la fenetre principale (WM_USER de PM) }
  WM_USER = $1000;
  WM_GITDONE = WM_USER + 10;          { operation reseau terminee }
  WM_GITPROG = WM_USER + 11;          { progression }
  { notifications internes (WM_COMMAND : Id + Code Shl 16) }
  BN_CLICKED = 0; LBN_SELCHANGE = 1; LBN_DBLCLK = 2; EN_CHANGE = $0300;
  { styles internes des controles (Ctl les traduit pour PM) }
  WS_BORDER = $00800000; WS_VSCROLL = $00200000;
  WS_TABSTOP = $00010000; WS_GROUP = $00020000;
  ES_AUTOHSCROLL = $0080; ES_PASSWORD = $0020; ES_MULTILINE = $0004;
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
  SB_LINEUP = 0; SB_LINEDOWN = 1; SB_PAGEUP = 2; SB_PAGEDOWN = 3;
  SB_THUMBPOSITION = 4; SB_THUMBTRACK = 5; SB_TOP = 6; SB_BOTTOM = 7;
  { couleurs de Windows 95 ($00BBGGRR), traduites en index de PM }
  ClrFace = $C0C0C0; ClrShadow = $808080; ClrHi = $FFFFFF; ClrDark = 0;
  ClrSel = $800000; ClrWin = $FFFFFF; ClrBlack = 0;
  ClrNavy = $800000; ClrGreen = $008000; ClrRed = $0000C0;
  ClrGray = $808080; ClrYellow = $00FFFF; ClrOlive = $008080;
  ClrMaroon = $000080; ClrBlue = $FF0000; ClrTeal = $808000;
  ClrAddBg = $EDFFE6; ClrDelBg = $F0EEFF; ClrAddG = $D8FFCD;
  ClrDelG = $E0DCFF; ClrHunk = $FFF8F1; ClrHunkT = $A06030;
  ClrAddI = $289A2C; ClrModI = $0088C0; ClrDelI = $2020C8;
  ClrConfI = $0060E0; ClrLight = $E0E0E0; ClrFolder = $40C0E0;

  { ---- Presentation Manager ---- }
  PM_WM_SETFOCUS = $000F; PM_WM_SIZE = $0007; PM_WM_COMMAND = $0020;
  PM_WM_PAINT = $0023; PM_WM_TIMER = $0024; PM_WM_CLOSE = $0029;
  PM_WM_QUIT = $002A; PM_WM_CONTROL = $0030; PM_WM_VSCROLL = $0031;
  PM_WM_HSCROLL = $0032; PM_WM_ACTIVATE = $000D; PM_WM_BUTTON2UP = $0075;
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
  WC_LISTBOX = $FFFF0007; WC_SCROLLBAR = $FFFF0008; WC_MLE = $FFFF000A;
  PM_WS_VISIBLE = $80000000; PM_WS_DISABLED = $40000000;
  PM_WS_GROUP = $00010000; PM_WS_TABSTOP = $00020000;
  PM_BS_PUSHBUTTON = 0; PM_BS_AUTOCHECKBOX = 2; PM_BS_AUTORADIOBUTTON = 4;
  PM_BS_DEFAULT = $0400; PM_SS_TEXT = 1; PM_SS_GROUPBOX = 2;
  PM_DT_VCENTER = $0400; PM_ES_AUTOSCROLL = 4; PM_ES_MARGIN = 8;
  PM_ES_UNREADABLE = $80; PM_SBS_VERT = 1; PM_SBS_HORZ = 0;
  PM_MLS_BORDER = 2; PM_MLS_VSCROLL = 4; PM_MLS_WORDWRAP = 1;
  PM_BM_QUERYCHECK = $0124; PM_BM_SETCHECK = $0125;
  PM_EM_SETSEL = $0142; PM_EM_SETTEXTLIMIT = $0143;
  PM_LM_INSERTITEM = $0161; PM_LM_SELECTITEM = $0164;
  PM_LM_QUERYSELECTION = $0165; PM_LM_DELETEALL = $016E;
  PM_MLM_SETTEXTLIMIT = $01B0;
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

  PM_WM_INITMENU = $0033;

Type
  PByt = ^Byte;
  PLng = ^LongInt;

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
Function WinUpdateWindow(H : LongInt) : LongInt; External 'PMWIN';
{ ---- PMGPI (couleurs RVB, police) ---- }
Function GpiCreateLogColorTable(Hps, Opt, Fmt, St, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiSetCharBox(Hps, P : LongInt) : LongInt; External 'PMGPI';
{ ---- PMMERGE (OS2.INI) ---- }
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE';
{ ---- DOSCALLS (suite) ---- }
Function DosSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFileInfo(H, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetInfoBlocks(PPTib, PPPib : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetDefaultDisk(D : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetCurrentDir(P : LongInt) : LongInt; External 'DOSCALLS';
{ sessions d'OS/2-0 (comme le Client SSH) : l'Invite de commandes a son
  propre ecran }
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';

Var
  Dummy0 : LongInt;

{ le noyau ne preempte pas un programme de PM : un long calcul du fil de
  travail (MD5, svndiff, lecture ou ecriture d'un gros fichier) gelerait
  tout le systeme, pointeur de la souris compris. Breathe(W) compte le
  travail fait (W : octets traites, environ) et cede le processeur aux
  autres taches (DosSleep(0)) toutes les 30 ms au plus. }
Var
  BrWork, BrTick : LongInt;

Procedure Breathe(W : LongInt);
Var T : LongInt;
Begin
  BrWork := BrWork + W;
  If BrWork < 32768 Then Exit;
  BrWork := 0;
  T := 0;
  If DosQuerySysInfo(14, 14, LongInt(@T), 4) <> 0 Then T := 0;
  If (T - BrTick >= 30) Or (T < BrTick) Then
  Begin
    Dummy0 := DosSleep(0);
    BrTick := T;
  End;
End;

{ ==================================================================== }
{ Noyau : utilitaires, tampons d'octets                                }
{ ==================================================================== }

Type
  TByteArr = Array[0..$7FFFFFF] Of Byte;
  PBytes = ^TByteArr;
  { tampon d'octets extensible }
  TBuf = Record
    P : PBytes;
    N, Cap : LongInt;
  End;

Type
  TLongArr4 = Array[0..$3FFFFFF] Of LongInt;

Var
  GitErr : String;                     { derniere erreur (texte) }
  GitOom : Boolean;                    { une allocation a echoue }

{ progression d'une operation longue (definie par le programme) }
Procedure GitProgress(Const What : String; Done, Total : LongInt); Forward;

Procedure BufInit(Var B : TBuf);
Begin
  B.P := Nil; B.N := 0; B.Cap := 0;
End;

Procedure BufFree(Var B : TBuf);
Begin
  If B.P <> Nil Then FreeMem(B.P, B.Cap);
  B.P := Nil; B.N := 0; B.Cap := 0;
End;

{ capacite d'au moins N octets (contenu garde) }
Procedure BufNeed(Var B : TBuf; N : LongInt);
Var Q : PBytes; C : LongInt;
Begin
  If N <= B.Cap Then Exit;
  C := B.Cap * 2;
  If C < 256 Then C := 256;
  While C < N Do C := C * 2;
  { gros tampons (images de plusieurs Mo) : au plus juste, +25 % au moins,
    pour ne pas demander le double de la memoire necessaire }
  If C > 4194304 Then
  Begin
    C := B.Cap + B.Cap Div 4;
    If C < N Then C := N;
    C := (C + 65535) And Not 65535;
  End;
  GetMem(Q, C);
  If Q = Nil Then
  Begin
    { memoire epuisee : le tampon garde sa taille, les ecritures qui ne
      tiennent pas sont ignorees (GitOom) }
    GitOom := True;
    GitErr := 'm'#233'moire insuffisante';
    Exit;
  End;
  If B.N > 0 Then Move(B.P^[0], Q^[0], B.N);
  If B.P <> Nil Then FreeMem(B.P, B.Cap);
  B.P := Q; B.Cap := C;
End;

Procedure BufByte(Var B : TBuf; V : LongInt);
Begin
  If B.N >= B.Cap Then BufNeed(B, B.N + 1);
  If B.N >= B.Cap Then Exit;
  B.P^[B.N] := V And 255;
  Inc(B.N);
End;

Procedure BufStr(Var B : TBuf; Const S : String);
Var I : LongInt;
Begin
  BufNeed(B, B.N + Length(S));
  If B.N + Length(S) > B.Cap Then Exit;
  For I := 1 To Length(S) Do
  Begin
    B.P^[B.N] := Ord(S[I]);
    Inc(B.N);
  End;
End;

Procedure BufMem(Var B : TBuf; Const Src; N : LongInt);
Begin
  If N <= 0 Then Exit;
  BufNeed(B, B.N + N);
  If B.N + N > B.Cap Then Exit;
  Move(Src, B.P^[B.N], N);
  B.N := B.N + N;
End;

Procedure BufAppend(Var B : TBuf; Var S : TBuf; Ofs, N : LongInt);
Begin
  If N <= 0 Then Exit;
  BufNeed(B, B.N + N);
  If B.N + N > B.Cap Then Exit;
  Move(S.P^[Ofs], B.P^[B.N], N);
  B.N := B.N + N;
End;

Procedure BufCopy(Var D : TBuf; Var S : TBuf);
Begin
  D.N := 0;
  BufAppend(D, S, 0, S.N);
End;

{ chaine depuis le tampon (au plus 250 caracteres) }
Function BufStrAt(Var B : TBuf; Ofs, N : LongInt) : String;
Var S : String; I : LongInt;
Begin
  S := '';
  If N > 250 Then N := 250;
  For I := 0 To N - 1 Do
    If Ofs + I < B.N Then S := S + Chr(B.P^[Ofs + I]);
  BufStrAt := S;
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function MinL(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinL := A Else MinL := B;
End;

Function MaxL(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxL := A Else MaxL := B;
End;

Function UpStr(S : String) : String;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do S[I] := UpCase(S[I]);
  UpStr := S;
End;

Function LowStr(S : String) : String;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do
    If (S[I] >= 'A') And (S[I] <= 'Z') Then S[I] := Chr(Ord(S[I]) + 32);
  LowStr := S;
End;

Function TrimS(S : String) : String;
Begin
  While (S <> '') And ((S[1] = ' ') Or (S[1] = #9)) Do Delete(S, 1, 1);
  While (S <> '') And ((S[Length(S)] = ' ') Or (S[Length(S)] = #9) Or
        (S[Length(S)] = #13) Or (S[Length(S)] = #10)) Do
    Delete(S, Length(S), 1);
  TrimS := S;
End;

Const
  HexD : String[16] = '0123456789abcdef';

Function HexB(V : LongInt) : String;
Begin
  HexB := HexD[((V Shr 4) And 15) + 1] + HexD[(V And 15) + 1];
End;

Function Hex8(V : LongInt) : String;
Var S : String; I : LongInt;
Begin
  S := '';
  For I := 0 To 7 Do
  Begin
    S := HexD[(V And 15) + 1] + S;
    V := V Shr 4;
  End;
  Hex8 := S;
End;

Function HexVal(C : Char) : LongInt;
Begin
  Case C Of
    '0'..'9' : HexVal := Ord(C) - 48;
    'a'..'f' : HexVal := Ord(C) - 87;
    'A'..'F' : HexVal := Ord(C) - 55;
  Else
    HexVal := -1;
  End;
End;

{ ANSI (1252) -> page de codes 850 d'OS/2-0 (ecran et noms de fichiers ;
  les lettres accentuees du francais ont les memes codes en 437 et en
  850) }
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

Var
  OemOut : LongInt;

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

{ fichiers (implantes par la plate-forme) : poignee >= 0, -1 si erreur }
Function FOpenR(Const P : String) : LongInt; Forward;
Function FCreate(Const P : String) : LongInt; Forward;
Function FReadAt(H, Pos : LongInt; Q : PBytes; N : LongInt) : LongInt;
  Forward;
Function FWrite(H : LongInt; Q : PBytes; N : LongInt) : Boolean; Forward;
Function FSize(H : LongInt) : LongInt; Forward;
Procedure FClose(H : LongInt); Forward;
{ supprime un dossier vide (sans erreur fatale) }
Function FRmDir(Const P : String) : Boolean; Forward;

Type
  TLongArr = Array[0..$3FFFFFF] Of LongInt;
  PLongArr = ^TLongArr;

{ ==================================================================== }
{ Fichiers                                                              }
{ ==================================================================== }

Type
  TFs3 = Array[0..31] Of Byte;         { FILESTATUS3 }
  TSRec = Record                       { recherche (FILEFINDBUF3) }
    H, Cnt, Attr : LongInt;
    B : Array[0..299] Of Byte;
    Name : String;
  End;

Function Le16(Var B; Ofs : LongInt) : LongInt;
Var P : PBytes;
Begin
  P := PBytes(@B);
  Le16 := P^[Ofs] Or (P^[Ofs + 1] Shl 8);
End;

Function Le32(Var B; Ofs : LongInt) : LongInt;
Var P : PBytes;
Begin
  P := PBytes(@B);
  Le32 := P^[Ofs] Or (P^[Ofs + 1] Shl 8) Or (P^[Ofs + 2] Shl 16) Or
    (P^[Ofs + 3] Shl 24);
End;

Procedure FsTake(Var R : TSRec);
Var K : LongInt;
Begin
  R.Name := '';
  For K := 0 To R.B[28] - 1 Do R.Name := R.Name + Chr(R.B[29 + K]);
  R.Name := UnDisp(R.Name);
  R.Attr := Le32(R.B, 24);
End;

Var
  FZ : Array[0..299] Of Byte;          { chemins ASCIIZ (DOSCALLS) }

{ chemin ANSI -> ASCIIZ en page 850 (noms de fichiers d'OS/2-0) }
Procedure PathZ(Const P : String);
Var I : LongInt; T : String;
Begin
  T := Disp(P);
  For I := 1 To Length(T) Do FZ[I - 1] := Ord(T[I]);
  FZ[Length(T)] := 0;
End;

Function FileLoad(Const Path : String; Var B : TBuf) : Boolean;
Var H, N, R : LongInt;
Begin
  FileLoad := False;
  B.N := 0;
  H := FOpenR(Path);
  If H < 0 Then Exit;
  N := FSize(H);
  BufNeed(B, N + 1);
  R := 0;
  If (N > 0) And (B.Cap > N) Then R := FReadAt(H, 0, B.P, N);
  FClose(H);
  B.N := R;
  FileLoad := R = N;
End;

Function FileSave(Const Path : String; Var B : TBuf; Ofs, N : LongInt)
  : Boolean;
Var H : LongInt; Ok : Boolean;
Begin
  FileSave := False;
  H := FCreate(Path);
  If H < 0 Then Exit;
  Ok := True;
  If N > 0 Then Ok := FWrite(H, PBytes(@B.P^[Ofs]), N);
  FClose(H);
  FileSave := Ok;
End;

Function FileSaveStr(Const Path, S : String) : Boolean;
Var B : TBuf;
Begin
  BufInit(B);
  BufStr(B, S);
  FileSaveStr := FileSave(Path, B, 0, B.N);
  BufFree(B);
End;

{ attributs (FILESTATUS3) ; -1 si absent }
Function FAttrOf(Const Path : String; Var Fs : TFs3) : LongInt;
Begin
  PathZ(Path);
  FillChar(Fs, 32, 0);
  If DosQueryPathInfo(LongInt(@FZ), 1, LongInt(@Fs), 24) <> 0 Then
    FAttrOf := -1
  Else FAttrOf := Le32(Fs, 20) And $37;
End;

Function FileExist(Const Path : String) : Boolean;
Var Fs : TFs3; A : LongInt;
Begin
  A := FAttrOf(Path, Fs);
  FileExist := (A >= 0) And ((A And $10) = 0);
End;

Function DirExist(Const Path : String) : Boolean;
Var Fs : TFs3; A : LongInt;
Begin
  A := FAttrOf(Path, Fs);
  DirExist := (A >= 0) And ((A And $10) <> 0);
End;

Procedure FileDel(Const Path : String);
Begin
  PathZ(Path);
  Dummy0 := DosDelete(LongInt(@FZ));
End;

Function FileRen(Const A, B : String) : Boolean;
Var Z2b : Array[0..299] Of Byte; I : LongInt; T : String;
Begin
  FileDel(B);
  T := Disp(B);
  For I := 1 To Length(T) Do Z2b[I - 1] := Ord(T[I]);
  Z2b[Length(T)] := 0;
  PathZ(A);
  FileRen := DosMove(LongInt(@FZ), LongInt(@Z2b)) = 0;
End;

Function ParentOf(Const P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> PS) Do Dec(K);
  ParentOf := Copy(P, 1, K - 1);
End;

Function NameOf(Const P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> PS) And (P[K] <> '/') Do Dec(K);
  NameOf := Copy(P, K + 1, 255);
End;

{ cree le dossier et ses parents }
Procedure MkDirs(Const P : String);
Begin
  If (P = '') Or DirExist(P) Then Exit;
  If (Length(P) <= 3) And (Pos(':', P) > 0) Then Exit;
  MkDirs(ParentOf(P));
  PathZ(P);
  Dummy0 := DosCreateDir(LongInt(@FZ), 0);
End;

{ chemin Subversion (a/b/c) -> chemin du systeme }
Function OsPath(Const S : String) : String;
Var T : String; I : LongInt;
Begin
  T := S;
  For I := 1 To Length(T) Do If T[I] = '/' Then T[I] := PS;
  OsPath := T;
End;

{ heure de modification d'un fichier (date et heure DOS : date Shl 16
  Or heure, comme GetFTime) et taille }
Function FileStat(Const Path : String; Var Size, Tm : LongInt) : Boolean;
Var Fs : TFs3; A : LongInt;
Begin
  FileStat := False;
  Size := 0; Tm := 0;
  A := FAttrOf(Path, Fs);
  If (A < 0) Or ((A And $10) <> 0) Then Exit;
  Size := Le32(Fs, 12);
  Tm := (Le16(Fs, 8) Shl 16) Or Le16(Fs, 10);
  FileStat := True;
End;

{ ---- recherche de fichiers (DosFindFirst, FILEFINDBUF3) ---- }

Function FsFirst(Const Spec : String; Var R : TSRec) : Boolean;
Var Ok : Boolean;
Begin
  PathZ(Spec);
  R.H := -1; R.Cnt := 1;
  Ok := (DosFindFirst(LongInt(@FZ), LongInt(@R.H), $37, LongInt(@R.B), 300,
    LongInt(@R.Cnt), 1) = 0) And (R.Cnt > 0);
  If Ok Then FsTake(R);
  FsFirst := Ok;
End;

Function FsNext(Var R : TSRec) : Boolean;
Var Ok : Boolean;
Begin
  R.Cnt := 1;
  Ok := (DosFindNext(R.H, LongInt(@R.B), 300, LongInt(@R.Cnt)) = 0) And
    (R.Cnt > 0);
  If Ok Then FsTake(R);
  FsNext := Ok;
End;

Procedure FsClose(Var R : TSRec);
Begin
  If R.H <> -1 Then Dummy0 := DosFindClose(R.H);
  R.H := -1;
End;

{ ==================================================================== }
{ Listes de fichiers (arbres aplatis, index, dossier de travail)        }
{ ==================================================================== }

Type
  TFlatE = Record
    Path : String;
    Mode, Size, MTime, Flag : LongInt;
  End;
  TFlatArr = Array[0..$FFFFF] Of TFlatE;
  PFlatArr = ^TFlatArr;
  TFlat = Record
    E : PFlatArr;
    N, Cap : LongInt;
  End;

Procedure FlatInit(Var F : TFlat);
Begin
  F.E := Nil; F.N := 0; F.Cap := 0;
End;

Procedure FlatFree(Var F : TFlat);
Begin
  If F.E <> Nil Then FreeMem(F.E, F.Cap * SizeOf(TFlatE));
  FlatInit(F);
End;

Function FlatAdd(Var F : TFlat; Const P : String) : LongInt;
Var Q : PFlatArr; C : LongInt;
Begin
  If F.N >= F.Cap Then
  Begin
    C := F.Cap * 2;
    If C < 64 Then C := 64;
    GetMem(Q, C * SizeOf(TFlatE));
    If F.N > 0 Then Move(F.E^[0], Q^[0], F.N * SizeOf(TFlatE));
    If F.E <> Nil Then FreeMem(F.E, F.Cap * SizeOf(TFlatE));
    F.E := Q; F.Cap := C;
  End;
  F.E^[F.N].Path := P;
  F.E^[F.N].Mode := $81A4;             { 100644 }
  F.E^[F.N].Size := 0; F.E^[F.N].MTime := 0; F.E^[F.N].Flag := 0;
  FlatAdd := F.N;
  Inc(F.N);
End;

Procedure FlatSortR(Var F : TFlat; L, R : LongInt);
Var I, J : LongInt; P : String; T : TFlatE;
Begin
  I := L; J := R;
  P := F.E^[(L + R) Div 2].Path;
  Repeat
    While F.E^[I].Path < P Do Inc(I);
    While F.E^[J].Path > P Do Dec(J);
    If I <= J Then
    Begin
      T := F.E^[I]; F.E^[I] := F.E^[J]; F.E^[J] := T;
      Inc(I); Dec(J);
    End;
  Until I > J;
  If L < J Then FlatSortR(F, L, J);
  If I < R Then FlatSortR(F, I, R);
End;

Procedure FlatSort(Var F : TFlat);
Begin
  If F.N > 1 Then FlatSortR(F, 0, F.N - 1);
End;

{ position du chemin P (liste triee), -1 si absent }
Function FlatLower(Var F : TFlat; Const P : String) : LongInt;
Var Lo, Hi, M : LongInt;
Begin
  Lo := 0; Hi := F.N;
  While Lo < Hi Do
  Begin
    M := (Lo + Hi) Div 2;
    If F.E^[M].Path < P Then Lo := M + 1 Else Hi := M;
  End;
  FlatLower := Lo;
End;

Function FlatFind(Var F : TFlat; Const P : String) : LongInt;
Var Lo, Hi, M : LongInt;
Begin
  FlatFind := -1;
  Lo := 0; Hi := F.N - 1;
  While Lo <= Hi Do
  Begin
    M := (Lo + Hi) Div 2;
    If F.E^[M].Path = P Then
    Begin
      FlatFind := M; Exit;
    End;
    If F.E^[M].Path < P Then Lo := M + 1 Else Hi := M - 1;
  End;
End;

Procedure FlatCopy(Var D, S : TFlat);
Var I, K : LongInt;
Begin
  D.N := 0;
  For I := 0 To S.N - 1 Do
  Begin
    K := FlatAdd(D, S.E^[I].Path);
    D.E^[K] := S.E^[I];
  End;
End;

{ ==================================================================== }
{ Dates                                                                 }
{ ==================================================================== }

Function CivilToUnix(Y, Mo, D, H, Mi, S : LongInt) : LongInt;
Var Era, Yoe, Doy, Doe : LongInt;
Begin
  If Mo <= 2 Then Dec(Y);
  If Y >= 0 Then Era := Y Div 400 Else Era := (Y - 399) Div 400;
  Yoe := Y - Era * 400;
  If Mo > 2 Then Doy := (153 * (Mo - 3) + 2) Div 5 + D - 1
  Else Doy := (153 * (Mo + 9) + 2) Div 5 + D - 1;
  Doe := Yoe * 365 + Yoe Div 4 - Yoe Div 100 + Doy;
  CivilToUnix := (Era * 146097 + Doe - 719468) * 86400 + H * 3600 +
    Mi * 60 + S;
End;

Function NowUnix : LongInt;
Var Dt : Array[0..11] Of Byte;
Begin
  FillChar(Dt, 12, 0);
  Dummy0 := DosGetDateTime(LongInt(@Dt));
  NowUnix := CivilToUnix(Dt[6] Or (Dt[7] Shl 8), Dt[5], Dt[4], Dt[0], Dt[1],
    Dt[2]);
End;

Function Pad2(V : LongInt) : String;
Begin
  If V < 10 Then Pad2 := '0' + IStr(V) Else Pad2 := IStr(V);
End;

{ AAAA-MM-JJ HH:MM }
Function UnixToStr(T : LongInt) : String;
Var Z, Era, Doe, Yoe, Y, Doy, Mp, D, M, Sec : LongInt;
Begin
  Sec := T Mod 86400;
  Z := T Div 86400;
  If Sec < 0 Then
  Begin
    Inc(Sec, 86400); Dec(Z);
  End;
  Z := Z + 719468;
  If Z >= 0 Then Era := Z Div 146097 Else Era := (Z - 146096) Div 146097;
  Doe := Z - Era * 146097;
  Yoe := (Doe - Doe Div 1460 + Doe Div 36524 - Doe Div 146096) Div 365;
  Y := Yoe + Era * 400;
  Doy := Doe - (365 * Yoe + Yoe Div 4 - Yoe Div 100);
  Mp := (5 * Doy + 2) Div 153;
  D := Doy - (153 * Mp + 2) Div 5 + 1;
  If Mp < 10 Then M := Mp + 3 Else M := Mp - 9;
  If M <= 2 Then Inc(Y);
  UnixToStr := IStr(Y) + '-' + Pad2(M) + '-' + Pad2(D) + ' ' +
    Pad2(Sec Div 3600) + ':' + Pad2((Sec Div 60) Mod 60);
End;


{ ==================================================================== }
{ Motifs (svn:ignore, exclusions globales)                              }
{ ==================================================================== }

Function Glob(Const P : String; PI : LongInt; Const S : String;
  SI : LongInt) : Boolean;
Var K : LongInt; Ok, Neg : Boolean;
Begin
  Glob := False;
  While PI <= Length(P) Do
  Begin
    If P[PI] = '*' Then
    Begin
      If (PI < Length(P)) And (P[PI + 1] = '*') Then
      Begin
        Inc(PI, 2);
        If (PI <= Length(P)) And (P[PI] = '/') Then Inc(PI);
        For K := SI To Length(S) + 1 Do
          If (K = SI) Or (S[K - 1] = '/') Or (PI > Length(P)) Then
            If Glob(P, PI, S, K) Then
            Begin
              Glob := True; Exit;
            End;
        Exit;
      End;
      Inc(PI);
      For K := SI To Length(S) + 1 Do
      Begin
        If Glob(P, PI, S, K) Then
        Begin
          Glob := True; Exit;
        End;
        If (K <= Length(S)) And (S[K] = '/') Then Exit;
      End;
      Exit;
    End;
    If SI > Length(S) Then Exit;
    If P[PI] = '?' Then
    Begin
      If S[SI] = '/' Then Exit;
    End
    Else If P[PI] = '[' Then
    Begin
      Inc(PI);
      Neg := (PI <= Length(P)) And ((P[PI] = '!') Or (P[PI] = '^'));
      If Neg Then Inc(PI);
      Ok := False;
      While (PI <= Length(P)) And (P[PI] <> ']') Do
      Begin
        If (PI + 2 <= Length(P)) And (P[PI + 1] = '-') And
           (P[PI + 2] <> ']') Then
        Begin
          If (S[SI] >= P[PI]) And (S[SI] <= P[PI + 2]) Then Ok := True;
          Inc(PI, 3);
        End
        Else
        Begin
          If S[SI] = P[PI] Then Ok := True;
          Inc(PI);
        End;
      End;
      If Ok = Neg Then Exit;
    End
    Else
    Begin
      If P[PI] = '\' Then Inc(PI);
      If (PI > Length(P)) Or (P[PI] <> S[SI]) Then Exit;
    End;
    Inc(PI); Inc(SI);
  End;
  Glob := SI > Length(S);
End;


{ UTF-8 (Git) <-> ANSI (fenetres) }
Function Utf8ToAnsi(Const S : String) : String;
Var I, C, V : LongInt; R : String;
Begin
  R := '';
  I := 1;
  While I <= Length(S) Do
  Begin
    C := Ord(S[I]);
    If C < 128 Then R := R + Chr(C)
    Else If (C >= $C0) And (C < $E0) And (I < Length(S)) Then
    Begin
      V := ((C And 31) Shl 6) Or (Ord(S[I + 1]) And 63);
      Inc(I);
      If V < 256 Then R := R + Chr(V) Else R := R + '?';
    End
    Else If (C >= $E0) And (C < $F0) And (I + 1 < Length(S)) Then
    Begin
      V := ((C And 15) Shl 12) Or ((Ord(S[I + 1]) And 63) Shl 6) Or
        (Ord(S[I + 2]) And 63);
      Inc(I, 2);
      Case V Of
        $2018, $2019 : R := R + '''';
        $201C, $201D : R := R + '"';
        $2013, $2014 : R := R + '-';
        $2026 : R := R + '...';
        $20AC : R := R + #128;
        Else R := R + '?';
      End;
    End
    Else If C >= $F0 Then
    Begin
      Inc(I, 3); R := R + '?';
    End
    Else R := R + Chr(C);              { octet isole : Latin-1 }
    Inc(I);
  End;
  Utf8ToAnsi := R;
End;

Function AnsiToUtf8(Const S : String) : String;
Var I, C : LongInt; R : String;
Begin
  R := '';
  For I := 1 To Length(S) Do
  Begin
    C := Ord(S[I]);
    If C < 128 Then R := R + S[I]
    Else If C = 128 Then R := R + #226#130#172
    Else R := R + Chr($C0 Or (C Shr 6)) + Chr($80 Or (C And 63));
  End;
  AnsiToUtf8 := R;
End;

{ ==================================================================== }
{ Comparaison de lignes                                                 }
{ ==================================================================== }

Type
  TLines = Record
    N : LongInt;
    St : ^TLongArr;                    { N + 1 debuts de ligne }
    Hs : ^TLongArr;
  End;

Procedure LinesFree(Var L : TLines);
Begin
  If L.St <> Nil Then FreeMem(L.St, (L.N + 1) * 4);
  If L.Hs <> Nil Then FreeMem(L.Hs, (L.N + 1) * 4);
  L.St := Nil; L.Hs := Nil; L.N := 0;
End;

Procedure LinesOf(Var B : TBuf; Var L : TLines);
Var I, K, H : LongInt;
Begin
  L.N := 0;
  For I := 0 To B.N - 1 Do
    If B.P^[I] = 10 Then Inc(L.N);
  If (B.N > 0) And (B.P^[B.N - 1] <> 10) Then Inc(L.N);
  GetMem(L.St, (L.N + 1) * 4);
  GetMem(L.Hs, (L.N + 1) * 4);
  K := 0; H := 5381;
  L.St^[0] := 0;
  For I := 0 To B.N - 1 Do
  Begin
    If B.P^[I] = 10 Then
    Begin
      L.Hs^[K] := H; Inc(K);
      L.St^[K] := I + 1;
      H := 5381;
    End
    Else If B.P^[I] <> 13 Then H := (H * 33) Xor B.P^[I];
  End;
  If K < L.N Then
  Begin
    L.Hs^[K] := H; L.St^[L.N] := B.N;
  End;
End;

Function LineEq(Var A : TBuf; Var LA : TLines; I : LongInt; Var B : TBuf;
  Var LB : TLines; J : LongInt) : Boolean;
Var N, M, K : LongInt;
Begin
  LineEq := False;
  If LA.Hs^[I] <> LB.Hs^[J] Then Exit;
  N := LA.St^[I + 1] - LA.St^[I];
  M := LB.St^[J + 1] - LB.St^[J];
  { ignore la difference CR/LF de fin de ligne }
  If (N > 1) And (A.P^[LA.St^[I] + N - 2] = 13) Then Dec(N);
  If (M > 1) And (B.P^[LB.St^[J] + M - 2] = 13) Then Dec(M);
  If N <> M Then Exit;
  For K := 0 To N - 2 Do
    If A.P^[LA.St^[I] + K] <> B.P^[LB.St^[J] + K] Then Exit;
  LineEq := True;
End;

Function LineText(Var B : TBuf; Var L : TLines; I : LongInt) : String;
Var N : LongInt;
Begin
  N := L.St^[I + 1] - L.St^[I];
  While (N > 0) And ((B.P^[L.St^[I] + N - 1] = 10) Or
    (B.P^[L.St^[I] + N - 1] = 13)) Do Dec(N);
  LineText := BufStrAt(B, L.St^[I], MinL(N, 250));
End;

Function IsBinary(Var B : TBuf) : Boolean;
Var I : LongInt;
Begin
  IsBinary := False;
  For I := 0 To MinL(B.N, 8000) - 1 Do
    If B.P^[I] = 0 Then
    Begin
      IsBinary := True; Exit;
    End;
End;

Const
  MaxCells = 2000000;

{ correspondance par plus longue sous-suite commune sur [A0,A1) x [B0,B1) }
Procedure MatchDP(Var A : TBuf; Var LA : TLines; Var B : TBuf;
  Var LB : TLines; A0, A1, B0, B1 : LongInt; M : PLongArr);
Type TW = Array[0..$3FFFFFF] Of Word;
Var T : ^TW; N, W, I, J, X, Y : LongInt;
Begin
  N := A1 - A0; W := B1 - B0;
  If (N = 0) Or (W = 0) Then Exit;
  GetMem(T, (N + 1) * (W + 1) * 2);
  { T[i, j] = LCS des suffixes A[A0 + i..], B[B0 + j..] }
  For I := N DownTo 0 Do
    For J := W DownTo 0 Do
      If (I = N) Or (J = W) Then T^[I * (W + 1) + J] := 0
      Else If LineEq(A, LA, A0 + I, B, LB, B0 + J) Then
        T^[I * (W + 1) + J] := T^[(I + 1) * (W + 1) + J + 1] + 1
      Else
      Begin
        X := T^[(I + 1) * (W + 1) + J];
        Y := T^[I * (W + 1) + J + 1];
        If X >= Y Then T^[I * (W + 1) + J] := X
        Else T^[I * (W + 1) + J] := Y;
      End;
  I := 0; J := 0;
  While (I < N) And (J < W) Do
    If LineEq(A, LA, A0 + I, B, LB, B0 + J) Then
    Begin
      M^[A0 + I] := B0 + J; Inc(I); Inc(J);
    End
    Else If T^[(I + 1) * (W + 1) + J] >= T^[I * (W + 1) + J + 1] Then Inc(I)
    Else Inc(J);
  FreeMem(T, (N + 1) * (W + 1) * 2);
End;

{ lignes uniques dans les deux plages, reliees par plus longue suite
  croissante (algorithme de patience), puis comparaison des intervalles }
Procedure MatchRange(Var A : TBuf; Var LA : TLines; Var B : TBuf;
  Var LB : TLines; A0, A1, B0, B1 : LongInt; M : PLongArr; Depth : LongInt);
Var PA, PB, Tl, Pv : ^TLongArr; I, J, K, Cnt, Na, Lo, Hi, Md, Len,
    CA, CB : LongInt;
Begin
  { prefixe et suffixe communs }
  While (A0 < A1) And (B0 < B1) And LineEq(A, LA, A0, B, LB, B0) Do
  Begin
    M^[A0] := B0; Inc(A0); Inc(B0);
  End;
  While (A0 < A1) And (B0 < B1) And LineEq(A, LA, A1 - 1, B, LB, B1 - 1) Do
  Begin
    Dec(A1); Dec(B1); M^[A1] := B1;
  End;
  If (A0 = A1) Or (B0 = B1) Then Exit;
  If (A1 - A0) * (B1 - B0) <= MaxCells Then
  Begin
    MatchDP(A, LA, B, LB, A0, A1, B0, B1, M); Exit;
  End;
  If Depth > 8 Then Exit;
  { couples de lignes uniques (recherche quadratique bornee) }
  Na := A1 - A0;
  GetMem(PA, Na * 4); GetMem(PB, Na * 4);
  Cnt := 0;
  For I := A0 To A1 - 1 Do
  Begin
    CA := 0; CB := 0; K := -1;
    For J := A0 To A1 - 1 Do
      If (LA.Hs^[J] = LA.Hs^[I]) Then Inc(CA);
    If CA <> 1 Then Continue;
    For J := B0 To B1 - 1 Do
      If (LB.Hs^[J] = LA.Hs^[I]) Then
      Begin
        Inc(CB); K := J;
      End;
    If (CB = 1) And LineEq(A, LA, I, B, LB, K) Then
    Begin
      PA^[Cnt] := I; PB^[Cnt] := K; Inc(Cnt);
    End;
  End;
  If Cnt = 0 Then
  Begin
    FreeMem(PA, Na * 4); FreeMem(PB, Na * 4); Exit;
  End;
  { plus longue suite croissante sur PB }
  GetMem(Tl, Cnt * 4); GetMem(Pv, Cnt * 4);
  Len := 0;
  For I := 0 To Cnt - 1 Do
  Begin
    Lo := 0; Hi := Len;
    While Lo < Hi Do
    Begin
      Md := (Lo + Hi) Div 2;
      If PB^[Tl^[Md]] < PB^[I] Then Lo := Md + 1 Else Hi := Md;
    End;
    If Lo > 0 Then Pv^[I] := Tl^[Lo - 1] Else Pv^[I] := -1;
    Tl^[Lo] := I;
    If Lo = Len Then Inc(Len);
  End;
  { remonte la suite dans Tl (ordre croissant) }
  K := Tl^[Len - 1];
  For I := Len - 1 DownTo 0 Do
  Begin
    Tl^[I] := K; K := Pv^[K];
  End;
  CA := A0; CB := B0;
  For I := 0 To Len - 1 Do
  Begin
    J := Tl^[I];
    MatchRange(A, LA, B, LB, CA, PA^[J], CB, PB^[J], M, Depth + 1);
    M^[PA^[J]] := PB^[J];
    CA := PA^[J] + 1; CB := PB^[J] + 1;
  End;
  MatchRange(A, LA, B, LB, CA, A1, CB, B1, M, Depth + 1);
  FreeMem(Tl, Cnt * 4); FreeMem(Pv, Cnt * 4);
  FreeMem(PA, Na * 4); FreeMem(PB, Na * 4);
End;

{ M^[i] = ligne de B correspondant a la ligne i de A, ou -1 }
Procedure LineMatch(Var A : TBuf; Var LA : TLines; Var B : TBuf;
  Var LB : TLines; Var M : PLongArr);
Var I : LongInt;
Begin
  GetMem(M, (LA.N + 1) * 4);
  For I := 0 To LA.N Do M^[I] := -1;
  MatchRange(A, LA, B, LB, 0, LA.N, 0, LB.N, M, 0);
End;

{ Diff affichable : lignes de contexte, ajouts, suppressions, en-tetes }
Const
  DkCtx = 0;
  DkAdd = 1;
  DkDel = 2;
  DkHunk = 3;

Type
  TDiffL = Record
    K : Byte;
    LA, LB : LongInt;                  { numeros de ligne (0...) }
    CA, CB : LongInt;                  { en-tete : nombres de lignes }
  End;
  TDiffArr = Array[0..$FFFFF] Of TDiffL;

Var
  DfA, DfB : TBuf;                     { ancien et nouveau contenu }
  DfLA, DfLB : TLines;
  Df : ^TDiffArr;
  DfN, DfCap : LongInt;
  DfBin : Boolean;
  DfAdd, DfDel : LongInt;

Procedure DfPush(K : Byte; LA, LB : LongInt);
Var Q : ^TDiffArr; C : LongInt;
Begin
  If DfN >= DfCap Then
  Begin
    C := DfCap * 2;
    If C < 256 Then C := 256;
    GetMem(Q, C * SizeOf(TDiffL));
    If DfN > 0 Then Move(Df^[0], Q^[0], DfN * SizeOf(TDiffL));
    If Df <> Nil Then FreeMem(Df, DfCap * SizeOf(TDiffL));
    Df := Q; DfCap := C;
  End;
  Df^[DfN].K := K; Df^[DfN].LA := LA; Df^[DfN].LB := LB;
  Df^[DfN].CA := 0; Df^[DfN].CB := 0;
  Inc(DfN);
End;

{ calcule le diff de DfA vers DfB (a remplir par l'appelant) }
Procedure DiffBuild;
Type TOp = Array[0..$FFFFFF] Of Byte;
Var M, MB : PLongArr; Ops : ^TOp; OI, OJ : ^TLongArr; N, I, J, K, S,
    E, H, Last : LongInt;
Begin
  DfN := 0; DfAdd := 0; DfDel := 0;
  LinesFree(DfLA); LinesFree(DfLB);
  DfBin := IsBinary(DfA) Or IsBinary(DfB);
  If DfBin Then Exit;
  LinesOf(DfA, DfLA); LinesOf(DfB, DfLB);
  LineMatch(DfA, DfLA, DfB, DfLB, M);
  GetMem(MB, (DfLB.N + 1) * 4);
  For J := 0 To DfLB.N Do MB^[J] := -1;
  For I := 0 To DfLA.N - 1 Do
    If M^[I] >= 0 Then MB^[M^[I]] := I;
  { suite d'operations }
  N := DfLA.N + DfLB.N;
  GetMem(Ops, N + 1); GetMem(OI, (N + 1) * 4); GetMem(OJ, (N + 1) * 4);
  I := 0; J := 0; K := 0;
  While (I < DfLA.N) Or (J < DfLB.N) Do
  Begin
    If (I < DfLA.N) And (J < DfLB.N) And (M^[I] = J) Then
    Begin
      Ops^[K] := DkCtx; OI^[K] := I; OJ^[K] := J; Inc(I); Inc(J);
    End
    Else If (I < DfLA.N) And (M^[I] < 0) Then
    Begin
      Ops^[K] := DkDel; OI^[K] := I; OJ^[K] := J; Inc(I); Inc(DfDel);
    End
    Else
    Begin
      Ops^[K] := DkAdd; OI^[K] := I; OJ^[K] := J; Inc(J); Inc(DfAdd);
    End;
    Inc(K);
  End;
  N := K;
  { blocs avec 3 lignes de contexte }
  I := 0; Last := 0;
  While I < N Do
  Begin
    If Ops^[I] = DkCtx Then
    Begin
      Inc(I); Continue;
    End;
    S := MaxL(I - 3, Last);
    E := I;
    { etend tant que deux changements sont separes de <= 6 lignes }
    Repeat
      While (E < N) And (Ops^[E] <> DkCtx) Do Inc(E);
      J := E;
      While (J < N) And (Ops^[J] = DkCtx) And (J - E < 7) Do Inc(J);
      If (J < N) And (Ops^[J] <> DkCtx) Then E := J Else Break;
    Until False;
    E := MinL(E + 3, N);
    H := DfN;
    DfPush(DkHunk, OI^[S], OJ^[S]);
    For J := S To E - 1 Do
    Begin
      DfPush(Ops^[J], OI^[J], OJ^[J]);
      If Ops^[J] <> DkAdd Then Inc(Df^[H].CA);
      If Ops^[J] <> DkDel Then Inc(Df^[H].CB);
    End;
    I := E; Last := E;
  End;
  FreeMem(Ops, DfLA.N + DfLB.N + 1);
  FreeMem(OI, (DfLA.N + DfLB.N + 1) * 4);
  FreeMem(OJ, (DfLA.N + DfLB.N + 1) * 4);
  FreeMem(M, (DfLA.N + 1) * 4);
  FreeMem(MB, (DfLB.N + 1) * 4);
End;

Function DiffText(I : LongInt) : String;
Var S : String;
Begin
  Case Df^[I].K Of
    DkHunk :
    Begin
      If Df^[I].CA = 0 Then S := '@@ -' + IStr(Df^[I].LA)
      Else S := '@@ -' + IStr(Df^[I].LA + 1);
      If Df^[I].CA <> 1 Then S := S + ',' + IStr(Df^[I].CA);
      If Df^[I].CB = 0 Then S := S + ' +' + IStr(Df^[I].LB)
      Else S := S + ' +' + IStr(Df^[I].LB + 1);
      If Df^[I].CB <> 1 Then S := S + ',' + IStr(Df^[I].CB);
      DiffText := S + ' @@';
    End;
    DkDel : DiffText := LineText(DfA, DfLA, Df^[I].LA);
    Else DiffText := LineText(DfB, DfLB, Df^[I].LB);
  End;
End;

{ ==================================================================== }
{ Fusion                                                                }
{ ==================================================================== }

Procedure PutLines(Var O, B : TBuf; Var L : TLines; I0, I1 : LongInt);
Var K : LongInt;
Begin
  If I1 <= I0 Then Exit;
  K := L.St^[I1] - L.St^[I0];
  BufAppend(O, B, L.St^[I0], K);
  If (L.St^[I1] = B.N) And (B.N > 0) And (B.P^[B.N - 1] <> 10) Then
    BufByte(O, 10);
End;

Function RangeEq(Var A : TBuf; Var LA : TLines; A0, A1 : LongInt;
  Var B : TBuf; Var LB : TLines; B0, B1 : LongInt) : Boolean;
Var I : LongInt;
Begin
  RangeEq := False;
  If A1 - A0 <> B1 - B0 Then Exit;
  For I := 0 To A1 - A0 - 1 Do
    If Not LineEq(A, LA, A0 + I, B, LB, B0 + I) Then Exit;
  RangeEq := True;
End;

{ fusion a trois voies ligne par ligne ; faux s'il y a des conflits (R
  recoit alors le texte avec marqueurs) }
Function Merge3(Var Bs, Ou, Th, R : TBuf; Const NameT : String) : Boolean;
Var LB, LO, LT : TLines; MO, MT : PLongArr; I, O, T, J, OE, TE : LongInt;
    Clean : Boolean;
Begin
  R.N := 0;
  LinesOf(Bs, LB); LinesOf(Ou, LO); LinesOf(Th, LT);
  LineMatch(Bs, LB, Ou, LO, MO);
  LineMatch(Bs, LB, Th, LT, MT);
  Clean := True;
  I := 0; O := 0; T := 0;
  While (I < LB.N) Or (O < LO.N) Or (T < LT.N) Do
  Begin
    If (I < LB.N) And (MO^[I] = O) And (MT^[I] = T) Then
    Begin
      PutLines(R, Bs, LB, I, I + 1);
      Inc(I); Inc(O); Inc(T); Continue;
    End;
    { prochain point de synchronisation : ligne de base commune aux
      trois versions }
    J := I;
    While (J < LB.N) And ((MO^[J] < 0) Or (MT^[J] < 0)) Do Inc(J);
    If J < LB.N Then
    Begin
      OE := MO^[J]; TE := MT^[J];
    End
    Else
    Begin
      OE := LO.N; TE := LT.N;
    End;
    If RangeEq(Bs, LB, I, J, Ou, LO, O, OE) Then
      PutLines(R, Th, LT, T, TE)
    Else If RangeEq(Bs, LB, I, J, Th, LT, T, TE) Or
      RangeEq(Ou, LO, O, OE, Th, LT, T, TE) Then
      PutLines(R, Ou, LO, O, OE)
    Else
    Begin
      Clean := False;
      BufStr(R, '<<<<<<< .mine' + #10);
      PutLines(R, Ou, LO, O, OE);
      BufStr(R, '=======' + #10);
      PutLines(R, Th, LT, T, TE);
      BufStr(R, '>>>>>>> ' + NameT + #10);
    End;
    I := J; O := OE; T := TE;
  End;
  FreeMem(MO, (LB.N + 1) * 4); FreeMem(MT, (LB.N + 1) * 4);
  LinesFree(LB); LinesFree(LO); LinesFree(LT);
  Merge3 := Clean;
End;

Var
  MergeConf : LongInt;                 { nombre de conflits }

{ objet trop grand pour etre fusionne ou compare en memoire }

{ ==================================================================== }
{ MD5 et HMAC-MD5 (sommes de controle de Subversion, CRAM-MD5)          }
{ ==================================================================== }

Type
  TMd5 = Record
    A, B, C, D : LongInt;
    Blk : Array[0..63] Of Byte;
    BN, Len : LongInt;
  End;
  TMd5D = Array[0..15] Of Byte;

Const
  Md5KC : Array[0..63] Of LongWord = (
    $D76AA478, $E8C7B756, $242070DB, $C1BDCEEE, $F57C0FAF, $4787C62A,
    $A8304613, $FD469501, $698098D8, $8B44F7AF, $FFFF5BB1, $895CD7BE,
    $6B901122, $FD987193, $A679438E, $49B40821, $F61E2562, $C040B340,
    $265E5A51, $E9B6C7AA, $D62F105D, $02441453, $D8A1E681, $E7D3FBC8,
    $21E1CDE6, $C33707D6, $F4D50D87, $455A14ED, $A9E3E905, $FCEFA3F8,
    $676F02D9, $8D2A4C8A, $FFFA3942, $8771F681, $6D9D6122, $FDE5380C,
    $A4BEEA44, $4BDECFA9, $F6BB4B60, $BEBFBC70, $289B7EC6, $EAA127FA,
    $D4EF3085, $04881D05, $D9D4D039, $E6DB99E5, $1FA27CF8, $C4AC5665,
    $F4292244, $432AFF97, $AB9423A7, $FC93A039, $655B59C3, $8F0CCC92,
    $FFEFF47D, $85845DD1, $6FA87E4F, $FE2CE6E0, $A3014314, $4E0811A1,
    $F7537E82, $BD3AF235, $2AD7D2BB, $EB86D391);
  Md5S : Array[0..63] Of Byte = (
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21);

Var
  Md5K : Array[0..63] Of LongInt;
  Md5Ready : Boolean;

Procedure Md5Init(Var C : TMd5);
Var I : LongInt; W : LongInt;
Begin
  If Not Md5Ready Then
  Begin
    For I := 0 To 63 Do
    Begin
      W := Md5KC[I]; Md5K[I] := W;
    End;
    Md5Ready := True;
  End;
  C.A := $67452301; C.B := LongInt($EFCDAB89);
  C.C := LongInt($98BADCFE); C.D := $10325476;
  C.BN := 0; C.Len := 0;
End;

{ un bloc de 64 octets P^[O..O+63] }
Procedure Md5Run(Var C : TMd5; P : PBytes; O : LongInt);
Var X : Array[0..15] Of LongInt; I, A, B, Cc, D, F, G, T, S : LongInt;
Begin
  Breathe(64);
  For I := 0 To 15 Do
    X[I] := P^[O + I * 4] Or (P^[O + I * 4 + 1] Shl 8) Or
      (P^[O + I * 4 + 2] Shl 16) Or (P^[O + I * 4 + 3] Shl 24);
  A := C.A; B := C.B; Cc := C.C; D := C.D;
  For I := 0 To 63 Do
  Begin
    If I < 16 Then
    Begin
      F := (B And Cc) Or ((Not B) And D); G := I;
    End
    Else If I < 32 Then
    Begin
      F := (D And B) Or ((Not D) And Cc); G := (5 * I + 1) And 15;
    End
    Else If I < 48 Then
    Begin
      F := B Xor Cc Xor D; G := (3 * I + 5) And 15;
    End
    Else
    Begin
      F := Cc Xor (B Or (Not D)); G := (7 * I) And 15;
    End;
    T := D; D := Cc; Cc := B;
    F := F + A + Md5K[I] + X[G];
    S := Md5S[I];
    B := B + ((F Shl S) Or (F Shr (32 - S)));
    A := T;
  End;
  C.A := C.A + A; C.B := C.B + B; C.C := C.C + Cc; C.D := C.D + D;
End;

Procedure Md5Ptr(Var C : TMd5; P : PBytes; Ofs, N : LongInt);
Var I, E : LongInt;
Begin
  I := Ofs; E := Ofs + N;
  While I < E Do
  Begin
    If (C.BN = 0) And (E - I >= 64) Then
    Begin
      Md5Run(C, P, I);
      I := I + 64;
    End
    Else
    Begin
      C.Blk[C.BN] := P^[I];
      Inc(C.BN); Inc(I);
      If C.BN = 64 Then
      Begin
        Md5Run(C, PBytes(@C.Blk), 0);
        C.BN := 0;
      End;
    End;
  End;
  C.Len := C.Len + N;
End;

Procedure Md5Str(Var C : TMd5; Const S : String);
Var I : LongInt; B : Array[0..255] Of Byte;
Begin
  For I := 1 To Length(S) Do B[I - 1] := Ord(S[I]);
  Md5Ptr(C, PBytes(@B), 0, Length(S));
End;

Procedure Md5Final(Var C : TMd5; Var D : TMd5D);
Var Pad : Array[0..71] Of Byte; N, I, L : LongInt;
Begin
  L := C.Len;
  For I := 0 To 71 Do Pad[I] := 0;
  Pad[0] := $80;
  If C.BN < 56 Then N := 56 - C.BN Else N := 120 - C.BN;
  { longueur en bits (moins de 256 Mo) }
  Pad[N] := (L Shl 3) And 255; Pad[N + 1] := (L Shr 5) And 255;
  Pad[N + 2] := (L Shr 13) And 255; Pad[N + 3] := (L Shr 21) And 255;
  Pad[N + 4] := (L Shr 29) And 7;
  Md5Ptr(C, PBytes(@Pad), 0, N + 8);
  For I := 0 To 3 Do
  Begin
    D[I] := (C.A Shr (I * 8)) And 255;
    D[I + 4] := (C.B Shr (I * 8)) And 255;
    D[I + 8] := (C.C Shr (I * 8)) And 255;
    D[I + 12] := (C.D Shr (I * 8)) And 255;
  End;
End;

Function Md5HexD(Const D : TMd5D) : String;
Var I : LongInt; S : String;
Begin
  S := '';
  For I := 0 To 15 Do S := S + HexB(D[I]);
  Md5HexD := S;
End;

{ empreinte d'une portion de tampon }
Function Md5Of(Var B : TBuf; Ofs, N : LongInt) : String;
Var C : TMd5; D : TMd5D;
Begin
  Md5Init(C);
  If N > 0 Then Md5Ptr(C, B.P, Ofs, N);
  Md5Final(C, D);
  Md5Of := Md5HexD(D);
End;

{ HMAC-MD5 (RFC 2104) : authentification CRAM-MD5 de svnserve }
Function HmacMd5(Key : String; Const Msg : String) : String;
Var C : TMd5; D : TMd5D; KB : Array[0..63] Of Byte; I : LongInt;
    P : Array[0..63] Of Byte;
Begin
  If Length(Key) > 64 Then
  Begin
    Md5Init(C); Md5Str(C, Key); Md5Final(C, D);
    Key := '';
    For I := 0 To 15 Do Key := Key + Chr(D[I]);
  End;
  For I := 0 To 63 Do KB[I] := 0;
  For I := 1 To Length(Key) Do KB[I - 1] := Ord(Key[I]);
  Md5Init(C);
  For I := 0 To 63 Do P[I] := KB[I] Xor $36;
  Md5Ptr(C, PBytes(@P), 0, 64);
  Md5Str(C, Msg);
  Md5Final(C, D);
  Md5Init(C);
  For I := 0 To 63 Do P[I] := KB[I] Xor $5C;
  Md5Ptr(C, PBytes(@P), 0, 64);
  Md5Ptr(C, PBytes(@D), 0, 16);
  Md5Final(C, D);
  HmacMd5 := Md5HexD(D);
End;

{ MD5 d'un fichier (lu par morceaux) ; '' si illisible }
Function Md5File(Const Path : String; Var Size : LongInt) : String;
Var H, N, Pos : LongInt; C : TMd5; D : TMd5D; B : TBuf;
Begin
  Md5File := '';
  Size := 0;
  H := FOpenR(Path);
  If H < 0 Then Exit;
  BufInit(B);
  BufNeed(B, 65536);
  If B.Cap < 65536 Then
  Begin
    FClose(H); Exit;
  End;
  Md5Init(C);
  Pos := 0;
  Repeat
    N := FReadAt(H, Pos, B.P, 65536);
    If N <= 0 Then Break;
    Md5Ptr(C, B.P, 0, N);
    Pos := Pos + N;
  Until False;
  FClose(H);
  BufFree(B);
  Md5Final(C, D);
  Size := Pos;
  Md5File := Md5HexD(D);
End;

Function BufFind(Var B : TBuf; Ofs, N : LongInt; Const S : String)
  : LongInt;
Var I, J : LongInt; Ok : Boolean;
Begin
  BufFind := -1;
  For I := Ofs To Ofs + N - Length(S) Do
  Begin
    Ok := True;
    For J := 1 To Length(S) Do
      If B.P^[I + J - 1] <> Ord(S[J]) Then
      Begin
        Ok := False; Break;
      End;
    If Ok Then
    Begin
      BufFind := I; Exit;
    End;
  End;
End;

Function StrToIntDef(Const S : String; D : LongInt) : LongInt;
Var V, E : LongInt;
Begin
  Val(TrimS(S), V, E);
  If (E <> 0) Or (TrimS(S) = '') Then StrToIntDef := D
  Else StrToIntDef := V;
End;

{ ==================================================================== }
{ Base64, URL, XML                                                      }
{ ==================================================================== }

Const
  B64 : String[64] =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

Function Base64(Const S : String) : String;
Var I, V, N : LongInt; R : String;
Begin
  R := '';
  I := 1;
  While I <= Length(S) Do
  Begin
    N := MinL(3, Length(S) - I + 1);
    V := Ord(S[I]) Shl 16;
    If N > 1 Then V := V Or (Ord(S[I + 1]) Shl 8);
    If N > 2 Then V := V Or Ord(S[I + 2]);
    R := R + B64[(V Shr 18) + 1] + B64[((V Shr 12) And 63) + 1];
    If N > 1 Then R := R + B64[((V Shr 6) And 63) + 1] Else R := R + '=';
    If N > 2 Then R := R + B64[(V And 63) + 1] Else R := R + '=';
    Inc(I, 3);
  End;
  Base64 := R;
End;

{ decode du Base64 (texte de B[Ofs..Ofs+N-1]) a la fin de O }
Procedure UnBase64(Var B : TBuf; Ofs, N : LongInt; Var O : TBuf);
Var I, V, K, C : LongInt;
Begin
  V := 0; K := 0;
  For I := Ofs To Ofs + N - 1 Do
  Begin
    C := B.P^[I];
    If (C >= 65) And (C <= 90) Then C := C - 65
    Else If (C >= 97) And (C <= 122) Then C := C - 71
    Else If (C >= 48) And (C <= 57) Then C := C + 4
    Else If C = 43 Then C := 62
    Else If C = 47 Then C := 63
    Else Continue;
    V := (V Shl 6) Or C; Inc(K);
    If K = 4 Then
    Begin
      BufByte(O, (V Shr 16) And 255); BufByte(O, (V Shr 8) And 255);
      BufByte(O, V And 255);
      V := 0; K := 0;
    End;
  End;
  If K = 2 Then BufByte(O, (V Shr 4) And 255)
  Else If K = 3 Then
  Begin
    BufByte(O, (V Shr 10) And 255); BufByte(O, (V Shr 2) And 255);
  End;
End;

Var
  UrlScheme, UrlHost, UrlPath : String;
  UrlPort : LongInt;

{ decoupe svn://, http:// et https://hote[:port]/chemin }
Function UrlSplit(U : String) : Boolean;
Var K, E : LongInt;
Begin
  UrlSplit := False;
  K := Pos('://', U);
  If K = 0 Then Exit;
  UrlScheme := LowStr(Copy(U, 1, K - 1));
  Delete(U, 1, K + 2);
  K := Pos('@', U);
  If (K > 0) And ((Pos('/', U) = 0) Or (K < Pos('/', U))) Then
    Delete(U, 1, K);
  K := Pos('/', U);
  If K = 0 Then
  Begin
    UrlHost := U; UrlPath := '/';
  End
  Else
  Begin
    UrlHost := Copy(U, 1, K - 1); UrlPath := Copy(U, K, 255);
  End;
  If UrlScheme = 'https' Then UrlPort := 443
  Else If UrlScheme = 'svn' Then UrlPort := 3690
  Else UrlPort := 80;
  K := Pos(':', UrlHost);
  If K > 0 Then
  Begin
    Val(Copy(UrlHost, K + 1, 10), UrlPort, E);
    UrlHost := Copy(UrlHost, 1, K - 1);
  End;
  UrlSplit := (UrlHost <> '') And ((UrlScheme = 'http') Or
    (UrlScheme = 'https') Or (UrlScheme = 'svn'));
End;

{ chemin d'URL encode (%xx) : octets non surs, UTF-8 compris }
Function UrlEnc(Const S : String) : String;
Var I, C : LongInt; R : String;
Begin
  R := '';
  For I := 1 To Length(S) Do
  Begin
    C := Ord(S[I]);
    If (C <= 32) Or (C >= 127) Or (S[I] In ['%', '#', '?', '"', '<', '>',
       '[', ']', '{', '}', '^', '`', '|', '\', '''', ';']) Then
      R := R + '%' + HexB(C)
    Else R := R + S[I];
  End;
  UrlEnc := R;
End;

Function UrlDec(Const S : String) : String;
Var I : LongInt; R : String;
Begin
  R := '';
  I := 1;
  While I <= Length(S) Do
  Begin
    If (S[I] = '%') And (I + 2 <= Length(S)) Then
    Begin
      R := R + Chr(HexVal(S[I + 1]) * 16 + HexVal(S[I + 2]));
      Inc(I, 3);
    End
    Else
    Begin
      R := R + S[I]; Inc(I);
    End;
  End;
  UrlDec := R;
End;

{ texte XML : caracteres speciaux echappes }
Function XmlEsc(Const S : String) : String;
Var I : LongInt; R : String;
Begin
  R := '';
  For I := 1 To Length(S) Do
    Case S[I] Of
      '&' : R := R + '&amp;';
      '<' : R := R + '&lt;';
      '>' : R := R + '&gt;';
      '"' : R := R + '&quot;';
      Else R := R + S[I];
    End;
  XmlEsc := R;
End;

Procedure BufXmlEsc(Var O, B : TBuf; Ofs, N : LongInt);
Var I : LongInt;
Begin
  For I := Ofs To Ofs + N - 1 Do
    Case B.P^[I] Of
      38 : BufStr(O, '&amp;');
      60 : BufStr(O, '&lt;');
      62 : BufStr(O, '&gt;');
      13 : BufStr(O, '&#13;');
      Else BufByte(O, B.P^[I]);
    End;
End;

{ ---- analyse XML simple (reponses WebDAV) ---- }

Const
  XkOpen = 1; XkClose = 2; XkEmpty = 3; XkText = 4; XkEnd = 0;

Var
  XName : String;                      { nom local (sans prefixe) }
  XAttr : String;                      { attributs bruts }
  XText : TBuf;                        { texte (entites decodees) }

{ element suivant a partir de Pp }
Function XmlNext(Var B : TBuf; Var Pp : LongInt) : LongInt;
Var I, K, C, V : LongInt; S : String;
Begin
  XmlNext := XkEnd;
  XName := ''; XAttr := '';
  XText.N := 0;
  If Pp >= B.N Then Exit;
  If B.P^[Pp] <> 60 Then
  Begin
    { texte jusqu'au prochain < }
    While (Pp < B.N) And (B.P^[Pp] <> 60) Do
    Begin
      C := B.P^[Pp];
      If C = 38 Then
      Begin
        K := Pp + 1;
        While (K < B.N) And (K - Pp < 12) And (B.P^[K] <> 59) Do Inc(K);
        S := BufStrAt(B, Pp + 1, K - Pp - 1);
        If S = 'amp' Then BufByte(XText, 38)
        Else If S = 'lt' Then BufByte(XText, 60)
        Else If S = 'gt' Then BufByte(XText, 62)
        Else If S = 'quot' Then BufByte(XText, 34)
        Else If S = 'apos' Then BufByte(XText, 39)
        Else If (S <> '') And (S[1] = '#') Then
        Begin
          V := 0;
          If (Length(S) > 1) And (S[2] = 'x') Then
            For I := 3 To Length(S) Do V := V * 16 + HexVal(S[I])
          Else For I := 2 To Length(S) Do V := V * 10 + Ord(S[I]) - 48;
          If V < 128 Then BufByte(XText, V)
          Else If V < 2048 Then
          Begin
            BufByte(XText, $C0 Or (V Shr 6));
            BufByte(XText, $80 Or (V And 63));
          End
          Else
          Begin
            BufByte(XText, $E0 Or (V Shr 12));
            BufByte(XText, $80 Or ((V Shr 6) And 63));
            BufByte(XText, $80 Or (V And 63));
          End;
        End;
        Pp := K + 1;
      End
      Else
      Begin
        BufByte(XText, C); Inc(Pp);
      End;
    End;
    XmlNext := XkText;
    Exit;
  End;
  { balise }
  Inc(Pp);
  If (Pp < B.N) And ((B.P^[Pp] = 63) Or (B.P^[Pp] = 33)) Then
  Begin
    { <?xml ...?> ou <!-- --> : passer }
    While (Pp < B.N) And (B.P^[Pp] <> 62) Do Inc(Pp);
    Inc(Pp);
    XmlNext := XmlNext(B, Pp);
    Exit;
  End;
  K := XkOpen;
  If (Pp < B.N) And (B.P^[Pp] = 47) Then
  Begin
    K := XkClose; Inc(Pp);
  End;
  S := '';
  While (Pp < B.N) And Not (B.P^[Pp] In [32, 9, 10, 13, 47, 62]) Do
  Begin
    If Length(S) < 80 Then S := S + Chr(B.P^[Pp]);
    Inc(Pp);
  End;
  I := Pos(':', S);
  If I > 0 Then Delete(S, 1, I);
  XName := S;
  While (Pp < B.N) And (B.P^[Pp] <> 62) Do
  Begin
    If (B.P^[Pp] = 47) And (Pp + 1 < B.N) And (B.P^[Pp + 1] = 62) Then
      K := XkEmpty
    Else If Length(XAttr) < 250 Then XAttr := XAttr + Chr(B.P^[Pp]);
    Inc(Pp);
  End;
  Inc(Pp);
  XmlNext := K;
End;

{ valeur d'un attribut (nom local) dans XAttr }
Function XmlAttr(Const N : String) : String;
Var K, E : LongInt; S : String;
Begin
  XmlAttr := '';
  S := ' ' + XAttr;
  K := Pos(':' + N + '="', S);
  If K = 0 Then K := Pos(' ' + N + '="', S);
  If K = 0 Then Exit;
  Delete(S, 1, K + Length(N) + 2);
  E := Pos('"', S);
  If E > 0 Then XmlAttr := Copy(S, 1, E - 1);
End;

{ texte du premier element Name (nom local) a partir de 0 }
Function XmlFirst(Var B : TBuf; Const Name : String) : String;
Var Pp, K : LongInt; S : String;
Begin
  XmlFirst := '';
  Pp := 0;
  Repeat
    K := XmlNext(B, Pp);
    If K = XkEnd Then Exit;
    If (K = XkOpen) And (XName = Name) Then
    Begin
      K := XmlNext(B, Pp);
      If K = XkText Then
      Begin
        S := BufStrAt(XText, 0, MinL(XText.N, 255));
        XmlFirst := S;
      End;
      Exit;
    End;
  Until False;
End;

{ ==================================================================== }
{ Transport (implante par la plate-forme)                               }
{ ==================================================================== }

{ requete HTTP(S) ; Hdr : en-tetes supplementaires separes par #13#10 ;
  en-tetes de la reponse dans HttpHdrs ; si HttpSinkH >= 0, le corps
  d'une reponse 200 est ecrit dans ce fichier (et son MD5 calcule) }
Function HttpReq(Const Method, Url, Hdr : String; Var Body, Resp : TBuf;
  Var Status : LongInt) : Boolean; Forward;
Function TcpOpen(Const Host : String; Port : LongInt) : LongInt; Forward;
Function TcpSend(H : LongInt; Var B : TBuf; Ofs, N : LongInt) : Boolean;
  Forward;
{ ajoute a B ce qui est recu ; 0 : connexion fermee, -1 : erreur }
Function TcpRecv(H : LongInt; Var B : TBuf) : LongInt; Forward;
Procedure TcpClose(H : LongInt); Forward;

Var
  HttpHdrs : TBuf;                     { en-tetes de la derniere reponse }
  HttpSinkH : LongInt;                 { corps vers un fichier (-1 : non) }
  HttpSinkMd5 : TMd5;
  HttpSinkN : LongInt;
  AgentName : String;

{ valeur d'un en-tete de la derniere reponse HTTP }
Function HttpHeader(Const Name : String) : String;
Var I, K, E : LongInt; L, N : String;
Begin
  HttpHeader := '';
  N := LowStr(Name) + ':';
  I := 0;
  While I < HttpHdrs.N Do
  Begin
    K := I;
    While (K < HttpHdrs.N) And (HttpHdrs.P^[K] <> 10) Do Inc(K);
    E := K;
    If (E > I) And (HttpHdrs.P^[E - 1] = 13) Then Dec(E);
    L := BufStrAt(HttpHdrs, I, MinL(E - I, 255));
    If LowStr(Copy(L, 1, Length(N))) = N Then
    Begin
      HttpHeader := TrimS(Copy(L, Length(N) + 1, 255));
      Exit;
    End;
    I := K + 1;
  End;
End;

{ ==================================================================== }
{ Acces au depot (RA) : svn:// et http(s):// (WebDAV, HTTP v2)          }
{ ==================================================================== }

Const
  RaSvn = 1; RaDav = 2;
  { actions du journal }
  LaAdd = 1; LaMod = 2; LaDel = 3; LaRep = 4;

Type
  TDirE = Record
    Name : String;                     { UTF-8 }
    Kind : Char;                       { 'f' fichier, 'd' dossier }
    Size, Rev, Time : LongInt;         { Rev : derniere modification }
    Author : String[60];
  End;
  TDirArr = Array[0..$FFFFF] Of TDirE;
  TDirList = Record
    E : ^TDirArr;
    N, Cap : LongInt;
    Rev : LongInt;                     { derniere modification du dossier }
    Ign : String;                      { svn:ignore (lignes separees #10) }
  End;
  TLogE = Record
    Rev, Time : LongInt;
    Author : String[60];
    MsgOfs, MsgLen : LongInt;          { dans LogMsg }
    P0, PN : LongInt;                  { chemins modifies dans LogP }
  End;
  TLogArr = Array[0..$FFFF] Of TLogE;

Var
  RaKind : LongInt;
  RaUrl, RaRoot, RaUuid : String;      { URL ouverte, racine du depot }
  RaRel : String;                      { chemin de RaUrl dans le depot }
  RemUser, RemPass : String;           { identifiants }
  RaAuthUser : String;                 { utilisateur authentifie }
  { svn:// }
  SvSock : LongInt;
  SvIn, SvOut : TBuf;
  SvP : LongInt;
  { http }
  DavHost, DavRootP, DavMe, DavRvr, DavTxr, DavTxn : String;
  DavProps : Boolean;                  { create-txn-with-props }
  { journal }
  Hist : ^TLogArr;
  HistN, HistCap : LongInt;
  LogMsg : TBuf;
  LogP, LogCp : TFlat;                 { chemins modifies, copies }

Procedure DirInit(Var L : TDirList);
Begin
  L.E := Nil; L.N := 0; L.Cap := 0; L.Rev := -1; L.Ign := '';
End;

Procedure DirFree(Var L : TDirList);
Begin
  If L.E <> Nil Then FreeMem(L.E, L.Cap * SizeOf(TDirE));
  DirInit(L);
End;

Function DirAdd(Var L : TDirList; Const Name : String) : LongInt;
Var Q : ^TDirArr; C : LongInt;
Begin
  If L.N >= L.Cap Then
  Begin
    C := L.Cap * 2;
    If C < 32 Then C := 32;
    GetMem(Q, C * SizeOf(TDirE));
    If L.N > 0 Then Move(L.E^[0], Q^[0], L.N * SizeOf(TDirE));
    If L.E <> Nil Then FreeMem(L.E, L.Cap * SizeOf(TDirE));
    L.E := Q; L.Cap := C;
  End;
  L.E^[L.N].Name := Name; L.E^[L.N].Kind := 'f';
  L.E^[L.N].Size := 0; L.E^[L.N].Rev := 0; L.E^[L.N].Time := 0;
  L.E^[L.N].Author := '';
  DirAdd := L.N;
  Inc(L.N);
End;

{ 2026-11-23T01:26:21.331077Z -> secondes depuis 1970 (UTC) }
Function SvnDate(Const S : String) : LongInt;
Var V : Array[0..5] Of LongInt; I, K : LongInt;
Begin
  SvnDate := 0;
  If Length(S) < 19 Then Exit;
  K := 0;
  For I := 0 To 5 Do V[I] := 0;
  For I := 1 To 19 Do
    If (S[I] >= '0') And (S[I] <= '9') Then V[K] := V[K] * 10 + Ord(S[I])
      - 48
    Else Inc(K);
  SvnDate := CivilToUnix(V[0], V[1], V[2], V[3], V[4], V[5]);
End;

Function JoinP(Const A, B : String) : String;
Begin
  If A = '' Then JoinP := B
  Else If B = '' Then JoinP := A
  Else JoinP := A + '/' + B;
End;

{ ---- journal ---- }

Procedure HistClear;
Begin
  HistN := 0; LogMsg.N := 0; LogP.N := 0; LogCp.N := 0;
End;

Function HistAdd : LongInt;
Var Q : ^TLogArr; C : LongInt;
Begin
  If HistN >= HistCap Then
  Begin
    C := HistCap * 2;
    If C < 64 Then C := 64;
    GetMem(Q, C * SizeOf(TLogE));
    If HistN > 0 Then Move(Hist^[0], Q^[0], HistN * SizeOf(TLogE));
    If Hist <> Nil Then FreeMem(Hist, HistCap * SizeOf(TLogE));
    Hist := Q; HistCap := C;
  End;
  Hist^[HistN].Rev := 0; Hist^[HistN].Time := 0; Hist^[HistN].Author := '';
  Hist^[HistN].MsgOfs := LogMsg.N; Hist^[HistN].MsgLen := 0;
  Hist^[HistN].P0 := LogP.N; Hist^[HistN].PN := 0;
  HistAdd := HistN;
  Inc(HistN);
End;

Procedure LogPathAdd(H : LongInt; Const P : String; Act : LongInt;
  Const CpPath : String; CpRev : LongInt; Const Kind : String);
Var K : LongInt;
Begin
  K := FlatAdd(LogP, P);
  LogP.E^[K].Flag := Act;
  If Kind = 'dir' Then LogP.E^[K].Mode := 1
  Else If Kind = 'file' Then LogP.E^[K].Mode := 0
  Else LogP.E^[K].Mode := -1;
  K := FlatAdd(LogCp, CpPath);
  LogCp.E^[K].Size := CpRev;
  Inc(Hist^[H].PN);
End;

Function HistSummary(I : LongInt) : String;
Var K, N : LongInt;
Begin
  N := Hist^[I].MsgLen;
  K := 0;
  While (K < N) And (LogMsg.P^[Hist^[I].MsgOfs + K] <> 10) And
    (LogMsg.P^[Hist^[I].MsgOfs + K] <> 13) Do Inc(K);
  HistSummary := BufStrAt(LogMsg, Hist^[I].MsgOfs, MinL(K, 255));
End;

{ ==================================================================== }
{ svn:// (protocole ra_svn, version 2)                                  }
{ ==================================================================== }

Const
  NkList = 1; NkWord = 2; NkNum = 3; NkStr = 4;

Var
  { arbre de l'element lu : noeuds }
  NKind, NVal, NLen, NFirst, NNext : PLongArr;
  NCnt, NCap : LongInt;
  NPool : TBuf;                        { textes des mots et chaines }

{ agrandit un tableau de noeuds de NCap a C elements }
Function NGrow(A : PLongArr; C : LongInt) : PLongArr;
Var Q : PLongArr;
Begin
  GetMem(Q, C * 4);
  If NCnt > 0 Then Move(A^[0], Q^[0], NCnt * 4);
  If A <> Nil Then FreeMem(A, NCap * 4);
  NGrow := Q;
End;

Function NNew(K : LongInt) : LongInt;
Var C : LongInt;
Begin
  If NCnt >= NCap Then
  Begin
    C := NCap * 2;
    If C < 256 Then C := 256;
    NKind := NGrow(NKind, C); NVal := NGrow(NVal, C); NLen := NGrow(NLen, C);
    NFirst := NGrow(NFirst, C); NNext := NGrow(NNext, C);
    NCap := C;
  End;
  NKind^[NCnt] := K; NVal^[NCnt] := 0; NLen^[NCnt] := 0;
  NFirst^[NCnt] := -1; NNext^[NCnt] := -1;
  NNew := NCnt;
  Inc(NCnt);
End;

{ au moins N octets disponibles a SvP }
Function SvNeed(N : LongInt) : Boolean;
Var R : LongInt;
Begin
  SvNeed := True;
  While SvIn.N - SvP < N Do
  Begin
    If SvP > 65536 Then
    Begin
      Move(SvIn.P^[SvP], SvIn.P^[0], SvIn.N - SvP);
      SvIn.N := SvIn.N - SvP; SvP := 0;
    End;
    R := TcpRecv(SvSock, SvIn);
    If R <= 0 Then
    Begin
      If GitErr = '' Then GitErr := 'connexion ferm'#233'e par le serveur';
      SvNeed := False; Exit;
    End;
  End;
End;

{ lit un element complet (liste, mot, nombre ou chaine) ; noeud ou -1 }
Function SvItem(Depth : LongInt) : LongInt;
Var C, N, K, Last, Ch : LongInt; IsNum : Boolean;
Begin
  SvItem := -1;
  If Depth > 40 Then
  Begin
    GitErr := 'r'#233'ponse du serveur trop imbriqu'#233'e'; Exit;
  End;
  { blancs }
  Repeat
    If Not SvNeed(1) Then Exit;
    C := SvIn.P^[SvP];
    If (C = 32) Or (C = 10) Or (C = 13) Or (C = 9) Then Inc(SvP)
    Else Break;
  Until False;
  If C = 40 Then
  Begin
    Inc(SvP);
    N := NNew(NkList);
    Last := -1;
    Repeat
      Repeat
        If Not SvNeed(1) Then Exit;
        C := SvIn.P^[SvP];
        If (C = 32) Or (C = 10) Or (C = 13) Or (C = 9) Then Inc(SvP)
        Else Break;
      Until False;
      If C = 41 Then
      Begin
        Inc(SvP); Break;
      End;
      Ch := SvItem(Depth + 1);
      If Ch < 0 Then Exit;
      If Last < 0 Then NFirst^[N] := Ch Else NNext^[Last] := Ch;
      Last := Ch;
    Until False;
    SvItem := N;
    Exit;
  End;
  If (C >= 48) And (C <= 57) Then
  Begin
    { nombre ou chaine (longueur:octets) }
    K := 0; IsNum := True;
    Repeat
      If Not SvNeed(1) Then Exit;
      C := SvIn.P^[SvP];
      If (C >= 48) And (C <= 57) Then
      Begin
        If K < 100000000 Then K := K * 10 + C - 48 Else K := $7FFFFFFF;
        Inc(SvP);
      End
      Else Break;
    Until False;
    If C = 58 Then
    Begin
      Inc(SvP);
      If Not SvNeed(K) Then Exit;
      N := NNew(NkStr);
      NVal^[N] := NPool.N; NLen^[N] := K;
      BufAppend(NPool, SvIn, SvP, K);
      SvP := SvP + K;
      If NPool.N <> NVal^[N] + K Then
      Begin
        GitErr := 'm'#233'moire insuffisante'; Exit;
      End;
    End
    Else
    Begin
      N := NNew(NkNum); NVal^[N] := K;
    End;
    SvItem := N;
    Exit;
  End;
  { mot }
  N := NNew(NkWord);
  NVal^[N] := NPool.N;
  Repeat
    If Not SvNeed(1) Then Exit;
    C := SvIn.P^[SvP];
    If (C = 32) Or (C = 10) Or (C = 41) Or (C = 40) Then Break;
    BufByte(NPool, C); Inc(SvP);
  Until False;
  NLen^[N] := NPool.N - NVal^[N];
  SvItem := N;
End;

{ lit un element de premier niveau (arbre remis a zero) }
Function SvRead : LongInt;
Begin
  NCnt := 0; NPool.N := 0;
  SvRead := SvItem(0);
End;

Function NChild(N, I : LongInt) : LongInt;
Var K : LongInt;
Begin
  NChild := -1;
  If (N < 0) Or (NKind^[N] <> NkList) Then Exit;
  K := NFirst^[N];
  While (K >= 0) And (I > 0) Do
  Begin
    K := NNext^[K]; Dec(I);
  End;
  NChild := K;
End;

Function NCount(N : LongInt) : LongInt;
Var K, C : LongInt;
Begin
  C := 0;
  If (N >= 0) And (NKind^[N] = NkList) Then
  Begin
    K := NFirst^[N];
    While K >= 0 Do
    Begin
      Inc(C); K := NNext^[K];
    End;
  End;
  NCount := C;
End;

Function NStr(N : LongInt) : String;
Begin
  If (N < 0) Or ((NKind^[N] <> NkStr) And (NKind^[N] <> NkWord)) Then
    NStr := ''
  Else NStr := BufStrAt(NPool, NVal^[N], MinL(NLen^[N], 255));
End;

Function NNum(N : LongInt) : LongInt;
Begin
  If (N < 0) Or (NKind^[N] <> NkNum) Then NNum := -1
  Else NNum := NVal^[N];
End;

{ premier element d'une liste optionnelle ( x ) }
Function NOpt(N : LongInt) : LongInt;
Begin
  NOpt := NChild(N, 0);
End;

{ ---- ecriture ---- }

Procedure SvW(Const S : String);
Begin
  BufStr(SvOut, S);
End;

Procedure SvS(Const S : String);
Begin
  BufStr(SvOut, IStr(Length(S)) + ':');
  BufStr(SvOut, S);
  BufByte(SvOut, 32);
End;

Procedure SvSB(Var B : TBuf; Ofs, N : LongInt);
Begin
  BufStr(SvOut, IStr(N) + ':');
  BufAppend(SvOut, B, Ofs, N);
  BufByte(SvOut, 32);
End;

Function SvFlush : Boolean;
Begin
  SvFlush := TcpSend(SvSock, SvOut, 0, SvOut.N);
  SvOut.N := 0;
End;

{ message d'une reponse ( failure ( ( code message fichier ligne ) ) ) }
Function SvFailMsg(N : LongInt) : String;
Var E, K : LongInt; S : String;
Begin
  S := '';
  E := NChild(N, 1);
  K := NFirst^[E];
  While K >= 0 Do
  Begin
    If NStr(NChild(K, 1)) <> '' Then
    Begin
      S := Utf8ToAnsi(NStr(NChild(K, 1)));
      If Pos('authoriz', S) > 0 Then S := S + ' (401)';
    End;
    K := NNext^[K];
    If S <> '' Then Break;
  End;
  If S = '' Then S := 'erreur du serveur';
  SvFailMsg := S;
End;

{ ( success ( ... ) ) : liste des parametres, sinon -1 (GitErr) }
Function SvResp(N : LongInt) : LongInt;
Begin
  SvResp := -1;
  If N < 0 Then Exit;
  If NStr(NChild(N, 0)) = 'success' Then SvResp := NChild(N, 1)
  Else If NStr(NChild(N, 0)) = 'failure' Then GitErr := SvFailMsg(N)
  Else GitErr := 'r'#233'ponse inattendue du serveur';
End;

{ demande d'authentification ( ( mecanismes ) royaume ) }
Function SvAuth(P : LongInt) : Boolean;
Var M, K, N : LongInt; Anon, Cram : Boolean; Ch, Realm : String;
Begin
  SvAuth := False;
  M := NChild(P, 0);
  If NCount(M) = 0 Then
  Begin
    SvAuth := True; Exit;
  End;
  Realm := NStr(NChild(P, 1));
  Anon := False; Cram := False;
  K := NFirst^[M];
  While K >= 0 Do
  Begin
    If NStr(K) = 'ANONYMOUS' Then Anon := True;
    If NStr(K) = 'CRAM-MD5' Then Cram := True;
    K := NNext^[K];
  End;
  If Cram And (RemUser <> '') Then
  Begin
    SvW('( CRAM-MD5 ( ) ) ');
    If Not SvFlush Then Exit;
    N := SvRead;
    If (N < 0) Or (NStr(NChild(N, 0)) <> 'step') Then
    Begin
      If N >= 0 Then GitErr := 'authentification refus'#233'e (401)';
      Exit;
    End;
    Ch := NStr(NChild(NChild(N, 1), 0));
    SvS(RemUser + ' ' + HmacMd5(RemPass, Ch));
    If Not SvFlush Then Exit;
    N := SvRead;
    If NStr(NChild(N, 0)) <> 'success' Then
    Begin
      GitErr := 'utilisateur ou mot de passe incorrect (401)'; Exit;
    End;
    RaAuthUser := RemUser;
    SvAuth := True;
    Exit;
  End;
  If Anon Then
  Begin
    SvW('( ANONYMOUS ( 0: ) ) ');
    If Not SvFlush Then Exit;
    N := SvRead;
    If NStr(NChild(N, 0)) <> 'success' Then
    Begin
      GitErr := 'acc'#232's anonyme refus'#233' (401)'; Exit;
    End;
    SvAuth := True;
    Exit;
  End;
  GitErr := 'le serveur demande une identification (401)';
  If Realm = '' Then ;
End;

{ commande : SvBegin, parametres (SvS, SvW), puis SvCall : envoi,
  authentification eventuelle, reponse (liste des parametres) }
Procedure SvBegin(Const Cmd : String);
Begin
  SvOut.N := 0;
  SvW('( ' + Cmd + ' ( ');
End;

Function SvCall : LongInt;
Var N, P : LongInt;
Begin
  SvCall := -1;
  SvW(') ) ');
  If Not SvFlush Then
  Begin
    GitErr := 'envoi impossible au serveur'; Exit;
  End;
  N := SvRead;
  P := SvResp(N);
  If P < 0 Then Exit;
  If Not SvAuth(P) Then Exit;
  SvCall := SvResp(SvRead);
End;

Function SvOpen(Const Url : String) : Boolean;
Var N, P, K : LongInt; Ok : Boolean;
Begin
  SvOpen := False;
  If Not UrlSplit(Url) Then Exit;
  SvIn.N := 0; SvP := 0; SvOut.N := 0;
  SvSock := TcpOpen(UrlHost, UrlPort);
  If SvSock < 0 Then
  Begin
    If GitErr = '' Then GitErr := 'connexion impossible '#224' ' + UrlHost +
      ':' + IStr(UrlPort);
    Exit;
  End;
  { accueil : ( success ( min max ( mecanismes ) ( capacites ) ) ) }
  P := SvResp(SvRead);
  If P < 0 Then
  Begin
    If GitErr = '' Then GitErr := 'ce serveur ne parle pas svn://';
    Exit;
  End;
  Ok := False;
  K := NFirst^[NChild(P, 3)];
  While K >= 0 Do
  Begin
    If NStr(K) = 'edit-pipeline' Then Ok := True;
    K := NNext^[K];
  End;
  If Not Ok Then
  Begin
    GitErr := 'serveur svnserve trop ancien'; Exit;
  End;
  SvW('( 2 ( edit-pipeline depth log-revprops ) ');
  SvS(Url); SvS(AgentName);
  SvW('( ) ) ');
  If Not SvFlush Then Exit;
  N := SvRead;
  P := SvResp(N);
  If P < 0 Then Exit;
  If Not SvAuth(P) Then Exit;
  { informations du depot : ( uuid racine ( capacites ) ) }
  P := SvResp(SvRead);
  If P < 0 Then Exit;
  RaUuid := NStr(NChild(P, 0));
  RaRoot := NStr(NChild(P, 1));
  SvOpen := True;
End;

Procedure SvClose;
Begin
  If SvSock >= 0 Then TcpClose(SvSock);
  SvSock := -1;
End;

{ liste de proprietes ( ( nom valeur ) ... ) : svn:ignore et revision }
Procedure SvProps(P : LongInt; Var L : TDirList);
Var K : LongInt; Nm : String;
Begin
  K := NFirst^[P];
  While K >= 0 Do
  Begin
    Nm := NStr(NChild(K, 0));
    If Nm = 'svn:ignore' Then L.Ign := NStr(NChild(K, 1))
    Else If Nm = 'svn:entry:committed-rev' Then
      L.Rev := StrToIntDef(NStr(NChild(K, 1)), -1);
    K := NNext^[K];
  End;
End;

{ ==================================================================== }
{ http(s):// : WebDAV et protocole HTTP v2 de Subversion                }
{ ==================================================================== }

Function AuthHdr : String;
Begin
  If (RemUser = '') And (RemPass = '') Then AuthHdr := ''
  Else AuthHdr := 'Authorization: Basic ' + Base64(RemUser + ':' + RemPass)
    + #13#10;
End;

{ message d'erreur d'une reponse HTTP de mod_dav_svn }
Function DavErr(St : LongInt; Var R : TBuf) : String;
Var S : String;
Begin
  S := Utf8ToAnsi(TrimS(XmlFirst(R, 'human-readable')));
  Case St Of
    401 : DavErr := 'authentification requise ou refus'#233'e (401)';
    403 : DavErr := 'acc'#232's refus'#233' (403)';
    404 : If S <> '' Then DavErr := S Else DavErr := 'introuvable (404)';
  Else
    If S <> '' Then DavErr := S
    Else DavErr := 'erreur HTTP ' + IStr(St);
  End;
End;

Var
  DavBody, DavResp : TBuf;

{ requete ; Ok : codes acceptes (ex. '200 207') }
Function Dav(Const Meth, Path, Hdr, Ok : String; Var St : LongInt) : Boolean;
Begin
  Dav := False;
  If Not HttpReq(Meth, DavHost + UrlEnc(Path), Hdr + AuthHdr, DavBody,
    DavResp, St) Then
  Begin
    If GitErr = '' Then GitErr := 'connexion impossible';
    Exit;
  End;
  If Pos(IStr(St), Ok) = 0 Then
  Begin
    GitErr := DavErr(St, DavResp);
    Exit;
  End;
  Dav := True;
End;

Function DavOpen(Const Url : String) : Boolean;
Var St, K : LongInt; P : String;
Begin
  DavOpen := False;
  If Not UrlSplit(Url) Then Exit;
  DavHost := UrlScheme + '://' + UrlHost;
  If ((UrlScheme = 'http') And (UrlPort <> 80)) Or
     ((UrlScheme = 'https') And (UrlPort <> 443)) Then
    DavHost := DavHost + ':' + IStr(UrlPort);
  P := UrlDec(UrlPath);
  While (Length(P) > 1) And (P[Length(P)] = '/') Do Delete(P, Length(P), 1);
  DavBody.N := 0;
  BufStr(DavBody, '<?xml version="1.0" encoding="utf-8"?><D:options ' +
    'xmlns:D="DAV:"><D:activity-collection-set/></D:options>');
  If Not Dav('OPTIONS', P, 'Content-Type: text/xml'#13#10, '200', St) Then
  Begin
    If St = 404 Then GitErr := 'URL introuvable sur le serveur (404)';
    Exit;
  End;
  DavRootP := UrlDec(HttpHeader('SVN-Repository-Root'));
  DavMe := HttpHeader('SVN-Me-Resource');
  If (DavRootP = '') Or (DavMe = '') Then
  Begin
    If DavRootP = '' Then GitErr := 'ce serveur n''h'#233'berge pas de ' +
      'd'#233'p'#244't Subversion'
    Else GitErr := 'serveur Subversion trop ancien (protocole HTTP v1)';
    Exit;
  End;
  DavRvr := UrlDec(HttpHeader('SVN-Rev-Root-Stub'));
  DavTxr := UrlDec(HttpHeader('SVN-Txn-Root-Stub'));
  DavTxn := UrlDec(HttpHeader('SVN-Txn-Stub'));
  DavMe := UrlDec(DavMe);
  RaUuid := HttpHeader('SVN-Repository-UUID');
  DavProps := Pos('create-txn-with-props', LowStr(HttpHeader(
    'SVN-Supported-Posts'))) > 0;
  { plusieurs en-tetes SVN-Supported-Posts : chercher dans tout le bloc }
  K := 0;
  While K + 21 < HttpHdrs.N Do
  Begin
    If BufStrAt(HttpHdrs, K, 21) = 'create-txn-with-props' Then
      DavProps := True;
    Inc(K);
  End;
  RaRoot := DavHost + UrlEnc(DavRootP);
  DavOpen := True;
End;

{ ==================================================================== }
{ API commune                                                           }
{ ==================================================================== }

Procedure RaClose;
Begin
  If RaKind = RaSvn Then SvClose;
  RaKind := 0;
End;

{ ouvre l'URL : racine du depot (RaRoot) et chemin relatif (RaRel) }
Function RaOpen(Url : String) : Boolean;
Var Ok : Boolean; R, U : String;
Begin
  RaOpen := False;
  RaClose;
  GitErr := '';
  RaAuthUser := '';
  While (Length(Url) > 8) And (Url[Length(Url)] = '/') Do
    Delete(Url, Length(Url), 1);
  If Not UrlSplit(Url) Then
  Begin
    GitErr := 'URL non valable (svn://, http:// ou https://) : ' + Url;
    Exit;
  End;
  RaUrl := Url;
  If UrlScheme = 'svn' Then
  Begin
    RaKind := RaSvn;
    Ok := SvOpen(Url);
    { la session est replacee a la racine : chemins depuis la racine }
    If Ok And (RaRoot <> Url) Then
    Begin
      SvBegin('reparent');
      SvS(RaRoot);
      Ok := SvCall >= 0;
    End;
  End
  Else
  Begin
    RaKind := RaDav;
    Ok := DavOpen(Url);
  End;
  If Not Ok Then
  Begin
    RaClose; Exit;
  End;
  { chemin relatif (decode) }
  R := UrlDec(RaRoot); U := UrlDec(Url);
  If LowStr(Copy(U, 1, Length(R))) = LowStr(R) Then
  Begin
    RaRel := Copy(U, Length(R) + 1, 255);
    While (RaRel <> '') And (RaRel[1] = '/') Do Delete(RaRel, 1, 1);
  End
  Else RaRel := '';
  RaOpen := True;
End;

Function RaLatest(Var Rev : LongInt) : Boolean;
Var P, St : LongInt;
Begin
  RaLatest := False;
  If RaKind = RaSvn Then
  Begin
    SvBegin('get-latest-rev');
    P := SvCall;
    If P < 0 Then Exit;
    Rev := NNum(NChild(P, 0));
  End
  Else
  Begin
    DavBody.N := 0;
    BufStr(DavBody, '<?xml version="1.0" encoding="utf-8"?><D:options ' +
      'xmlns:D="DAV:"><D:activity-collection-set/></D:options>');
    If Not Dav('OPTIONS', DavRootP, 'Content-Type: text/xml'#13#10, '200',
      St) Then Exit;
    Rev := StrToIntDef(HttpHeader('SVN-Youngest-Rev'), -1);
  End;
  RaLatest := Rev >= 0;
End;

Function RvrPath(Const P : String; Rev : LongInt) : String;
Begin
  If P = '' Then RvrPath := DavRvr + '/' + IStr(Rev)
  Else RvrPath := DavRvr + '/' + IStr(Rev) + '/' + P;
End;

{ nature d'un chemin : 'n' absent, 'f' fichier, 'd' dossier }
Function RaCheckPath(Const Path : String; Rev : LongInt; Var K : Char)
  : Boolean;
Var P, St : LongInt; S : String;
Begin
  RaCheckPath := False;
  K := 'n';
  If RaKind = RaSvn Then
  Begin
    SvBegin('check-path');
    SvS(Path);
    SvW('( ' + IStr(Rev) + ' ) ');
    P := SvCall;
    If P < 0 Then Exit;
    S := NStr(NChild(P, 0));
    If S = 'file' Then K := 'f' Else If S = 'dir' Then K := 'd';
  End
  Else
  Begin
    DavBody.N := 0;
    BufStr(DavBody, '<?xml version="1.0" encoding="utf-8"?><propfind ' +
      'xmlns="DAV:"><prop><resourcetype/></prop></propfind>');
    If Not Dav('PROPFIND', RvrPath(Path, Rev), 'Depth: 0'#13#10 +
      'Content-Type: text/xml'#13#10, '207 404', St) Then Exit;
    If St = 207 Then
    Begin
      If BufFind(DavResp, 0, DavResp.N, 'collection') >= 0 Then K := 'd'
      Else K := 'f';
    End;
  End;
  RaCheckPath := True;
End;

{ contenu d'un dossier (et sa revision, son svn:ignore) }
Function RaGetDir(Const Path : String; Rev : LongInt; Var L : TDirList)
  : Boolean;
Var P, K, I, St, Pp, Kd, Depth : LongInt; S, Href, Base : String;
    E : TDirE; InProp, First : Boolean; Ign : TBuf;
Begin
  RaGetDir := False;
  L.N := 0; L.Rev := -1; L.Ign := '';
  If RaKind = RaSvn Then
  Begin
    SvBegin('get-dir');
    SvS(Path);
    SvW('( ' + IStr(Rev) + ' ) true true ( kind size has-props created-rev '
      + 'time last-author ) ');
    P := SvCall;
    If P < 0 Then Exit;
    SvProps(NChild(P, 1), L);
    K := NFirst^[NChild(P, 2)];
    While K >= 0 Do
    Begin
      I := DirAdd(L, NStr(NChild(K, 0)));
      If NStr(NChild(K, 1)) = 'dir' Then L.E^[I].Kind := 'd';
      L.E^[I].Size := NNum(NChild(K, 2));
      L.E^[I].Rev := NNum(NChild(K, 4));
      L.E^[I].Time := SvnDate(NStr(NOpt(NChild(K, 5))));
      L.E^[I].Author := Utf8ToAnsi(NStr(NOpt(NChild(K, 6))));
      K := NNext^[K];
    End;
    RaGetDir := True;
    Exit;
  End;
  DavBody.N := 0;
  BufStr(DavBody, '<?xml version="1.0" encoding="utf-8"?><propfind ' +
    'xmlns="DAV:"><prop><resourcetype/><getcontentlength/><version-name/>' +
    '<creationdate/><creator-displayname/><ignore xmlns="http://' +
    'subversion.tigris.org/xmlns/svn/"/></prop></propfind>');
  If Not Dav('PROPFIND', RvrPath(Path, Rev), 'Depth: 1'#13#10 +
    'Content-Type: text/xml'#13#10, '207', St) Then Exit;
  BufInit(Ign);
  Base := '';
  First := True;
  Pp := 0; InProp := False;
  E.Name := ''; E.Kind := 'f'; E.Size := 0; E.Rev := 0; E.Time := 0;
  E.Author := '';
  Href := '';
  Repeat
    Kd := XmlNext(DavResp, Pp);
    If Kd = XkEnd Then Break;
    If (Kd = XkOpen) Or (Kd = XkEmpty) Then
    Begin
      S := XName;
      If S = 'response' Then
      Begin
        E.Name := ''; E.Kind := 'f'; E.Size := 0; E.Rev := 0; E.Time := 0;
        E.Author := ''; Href := ''; Ign.N := 0;
      End
      Else If (S = 'collection') Then E.Kind := 'd'
      Else If (Kd = XkOpen) And ((S = 'href') Or (S = 'getcontentlength') Or
        (S = 'version-name') Or (S = 'creationdate') Or
        (S = 'creator-displayname') Or (S = 'ignore')) Then
      Begin
        Kd := XmlNext(DavResp, Pp);
        If Kd = XkText Then
        Begin
          If S = 'ignore' Then BufAppend(Ign, XText, 0, XText.N)
          Else
          Begin
            Href := BufStrAt(XText, 0, MinL(XText.N, 255));
            If S = 'getcontentlength' Then E.Size := StrToIntDef(Href, 0)
            Else If S = 'version-name' Then E.Rev := StrToIntDef(Href, 0)
            Else If S = 'creationdate' Then E.Time := SvnDate(Href)
            Else If S = 'creator-displayname' Then
              E.Author := Utf8ToAnsi(Href)
            Else If S = 'href' Then E.Name := UrlDec(Href);
          End;
        End;
      End;
    End
    Else If (Kd = XkClose) And (XName = 'response') Then
    Begin
      S := E.Name;
      While (Length(S) > 1) And (S[Length(S)] = '/') Do
        Delete(S, Length(S), 1);
      If First Then
      Begin
        { le dossier lui-meme }
        First := False;
        Base := S;
        L.Rev := E.Rev;
        L.Ign := BufStrAt(Ign, 0, MinL(Ign.N, 255));
      End
      Else If Copy(S, 1, Length(Base) + 1) = Base + '/' Then
      Begin
        I := DirAdd(L, Copy(S, Length(Base) + 2, 255));
        L.E^[I].Kind := E.Kind; L.E^[I].Size := E.Size;
        L.E^[I].Rev := E.Rev; L.E^[I].Time := E.Time;
        L.E^[I].Author := E.Author;
      End;
    End;
  Until False;
  BufFree(Ign);
  Depth := 0;
  If Depth = 0 Then ;
  RaGetDir := True;
End;

{ contenu d'un fichier : dans le fichier OutPath (OutPath <> '') ou dans
  B ; Md5 : empreinte calculee }
Function RaGetFile(Const Path : String; Rev : LongInt; Const OutPath : String;
  Var B : TBuf; Var Md5 : String) : Boolean;
Var P, N, St, H, K : LongInt; C : TMd5; D : TMd5D; S, Sum : String;
    Ok : Boolean;
Begin
  RaGetFile := False;
  B.N := 0; Md5 := '';
  H := -1;
  If OutPath <> '' Then
  Begin
    H := FCreate(OutPath);
    If H < 0 Then
    Begin
      GitErr := 'cr'#233'ation impossible : ' + OutPath; Exit;
    End;
  End;
  Md5Init(C);
  Ok := False;
  If RaKind = RaSvn Then
  Begin
    SvBegin('get-file');
    SvS(Path);
    SvW('( ' + IStr(Rev) + ' ) false true ');
    P := SvCall;
    If P >= 0 Then
    Begin
      Sum := NStr(NOpt(NChild(P, 0)));
      { contenu : chaines jusqu'a la chaine vide }
      Ok := True;
      Repeat
        N := SvRead;
        If (N < 0) Or (NKind^[N] <> NkStr) Then
        Begin
          Ok := False; Break;
        End;
        If NLen^[N] = 0 Then Break;
        Md5Ptr(C, NPool.P, NVal^[N], NLen^[N]);
        If H >= 0 Then
        Begin
          If Not FWrite(H, PBytes(@NPool.P^[NVal^[N]]), NLen^[N]) Then
          Begin
            GitErr := #233'criture impossible (disque plein ?)';
            Ok := False; Break;
          End;
        End
        Else BufAppend(B, NPool, NVal^[N], NLen^[N]);
        If GitOom Then
        Begin
          Ok := False; Break;
        End;
      Until False;
      If Ok Then Ok := SvResp(SvRead) >= 0;
    End;
    Md5Final(C, D);
    Md5 := Md5HexD(D);
    If Ok And (Sum <> '') And (Sum <> Md5) Then
    Begin
      GitErr := 'somme de contr'#244'le incorrecte : ' + Path; Ok := False;
    End;
  End
  Else
  Begin
    DavBody.N := 0;
    HttpSinkH := H;
    Md5Init(HttpSinkMd5);
    HttpSinkN := 0;
    K := 0;
    Ok := Dav('GET', RvrPath(Path, Rev), '', '200', St);
    HttpSinkH := -1;
    If Ok Then
    Begin
      If H >= 0 Then Md5Final(HttpSinkMd5, D)
      Else
      Begin
        BufAppend(B, DavResp, 0, DavResp.N);
        Md5Ptr(C, DavResp.P, 0, DavResp.N);
        Md5Final(C, D);
      End;
      Md5 := Md5HexD(D);
    End;
    If K = 0 Then ;
  End;
  If H >= 0 Then FClose(H);
  If Not Ok And (H >= 0) Then FileDel(OutPath);
  RaGetFile := Ok;
End;

{ journal de Path (depuis la racine) de StartRev a EndRev (decroissant) }
Function RaLog(Const Path : String; StartRev, EndRev, Limit : LongInt;
  WithPaths : Boolean) : Boolean;
Var N, P, K, H, St, Pp, Kd, Act, CpRev : LongInt; S, T, Cp, Kind : String;
    InItem : Boolean;
Begin
  RaLog := False;
  HistClear;
  If RaKind = RaSvn Then
  Begin
    If WithPaths Then T := 'true' Else T := 'false';
    SvOut.N := 0;
    SvW('( log ( ( ');
    SvS(Path);
    SvW(') ( ' + IStr(StartRev) + ' ) ( ' + IStr(EndRev) +
      ' ) ' + T + ' false ' + IStr(Limit) + ' false revprops ( 10:svn:' +
      'author 8:svn:date 7:svn:log ) ) ) ');
    If Not SvFlush Then Exit;
    P := SvResp(SvRead);
    If P < 0 Then Exit;
    If Not SvAuth(P) Then Exit;
    Repeat
      N := SvRead;
      If N < 0 Then Exit;
      If (NKind^[N] = NkWord) And (NStr(N) = 'done') Then Break;
      If NKind^[N] <> NkList Then Exit;
      H := HistAdd;
      Hist^[H].Rev := NNum(NChild(N, 1));
      Hist^[H].Author := Utf8ToAnsi(NStr(NOpt(NChild(N, 2))));
      Hist^[H].Time := SvnDate(NStr(NOpt(NChild(N, 3))));
      K := NOpt(NChild(N, 4));
      If K >= 0 Then BufAppend(LogMsg, NPool, NVal^[K], NLen^[K]);
      Hist^[H].MsgLen := LogMsg.N - Hist^[H].MsgOfs;
      K := NFirst^[NChild(N, 0)];
      While K >= 0 Do
      Begin
        S := NStr(NChild(K, 1));
        If S = 'A' Then Act := LaAdd Else If S = 'D' Then Act := LaDel
        Else If S = 'R' Then Act := LaRep Else Act := LaMod;
        Cp := NStr(NChild(NChild(K, 2), 0));
        CpRev := NNum(NChild(NChild(K, 2), 1));
        Kind := NStr(NChild(NChild(K, 3), 0));
        LogPathAdd(H, NStr(NChild(K, 0)), Act, Cp, CpRev, Kind);
        K := NNext^[K];
      End;
    Until False;
    RaLog := SvResp(SvRead) >= 0;
    Exit;
  End;
  DavBody.N := 0;
  BufStr(DavBody, '<?xml version="1.0" encoding="utf-8"?><S:log-report ' +
    'xmlns:S="svn:"><S:start-revision>' + IStr(StartRev) +
    '</S:start-revision><S:end-revision>' + IStr(EndRev) +
    '</S:end-revision><S:limit>' + IStr(Limit) + '</S:limit>');
  If WithPaths Then BufStr(DavBody, '<S:discover-changed-paths/>');
  BufStr(DavBody, '<S:revprop>svn:author</S:revprop><S:revprop>svn:date' +
    '</S:revprop><S:revprop>svn:log</S:revprop><S:path></S:path>' +
    '</S:log-report>');
  If Not Dav('REPORT', RvrPath(Path, StartRev), 'Content-Type: text/xml' +
    #13#10, '200', St) Then Exit;
  Pp := 0; H := -1; InItem := False;
  Repeat
    Kd := XmlNext(DavResp, Pp);
    If Kd = XkEnd Then Break;
    If Kd = XkOpen Then
    Begin
      S := XName;
      If S = 'log-item' Then
      Begin
        H := HistAdd; InItem := True;
      End
      Else If InItem And ((S = 'added-path') Or (S = 'modified-path') Or
        (S = 'deleted-path') Or (S = 'replaced-path')) Then
      Begin
        Cp := UrlDec(XmlAttr('copyfrom-path'));
        CpRev := StrToIntDef(XmlAttr('copyfrom-rev'), -1);
        Kind := XmlAttr('node-kind');
        If S = 'added-path' Then Act := LaAdd
        Else If S = 'deleted-path' Then Act := LaDel
        Else If S = 'replaced-path' Then Act := LaRep Else Act := LaMod;
        If XmlNext(DavResp, Pp) = XkText Then
          LogPathAdd(H, BufStrAt(XText, 0, MinL(XText.N, 255)), Act, Cp,
            CpRev, Kind);
      End
      Else If InItem And ((S = 'version-name') Or (S = 'creator-displayname')
        Or (S = 'date') Or (S = 'comment')) Then
      Begin
        If XmlNext(DavResp, Pp) = XkText Then
        Begin
          T := BufStrAt(XText, 0, MinL(XText.N, 255));
          If S = 'version-name' Then Hist^[H].Rev := StrToIntDef(T, 0)
          Else If S = 'creator-displayname' Then
            Hist^[H].Author := Utf8ToAnsi(T)
          Else If S = 'date' Then Hist^[H].Time := SvnDate(T)
          Else
          Begin
            BufAppend(LogMsg, XText, 0, XText.N);
            Hist^[H].MsgLen := LogMsg.N - Hist^[H].MsgOfs;
          End;
        End;
      End;
    End
    Else If (Kd = XkClose) And (XName = 'log-item') Then InItem := False;
  Until False;
  RaLog := True;
End;

{ ==================================================================== }
{ Validation (commit)                                                   }
{ ==================================================================== }

Const
  CoAddDir = 1; CoAddFile = 2; CoModFile = 3; CoDelete = 4; CoPropDir = 5;
  CoCopyDir = 6;

Type
  TCOp = Record
    K : LongInt;                       { CoAddDir... }
    Path : String;                     { depuis la racine du depot }
    Rev : LongInt;                     { revision de base }
    Src : String;                      { fichier local ; propriete ; copie }
    Vl : String;                      { valeur de la propriete }
    Md5 : String;                      { calcule a l'envoi }
  End;
  TCOpArr = Array[0..$FFFF] Of TCOp;

Var
  COps : ^TCOpArr;
  COpN, COpCap : LongInt;
  CNewRev, CDate : LongInt;
  CAuthor : String;

Function COpAdd(K : LongInt; Const P : String; Rev : LongInt;
  Const Src, Vl : String) : LongInt;
Var Q : ^TCOpArr; C : LongInt;
Begin
  If COpN >= COpCap Then
  Begin
    C := COpCap * 2;
    If C < 64 Then C := 64;
    GetMem(Q, C * SizeOf(TCOp));
    If COpN > 0 Then Move(COps^[0], Q^[0], COpN * SizeOf(TCOp));
    If COps <> Nil Then FreeMem(COps, COpCap * SizeOf(TCOp));
    COps := Q; COpCap := C;
  End;
  COps^[COpN].K := K; COps^[COpN].Path := P; COps^[COpN].Rev := Rev;
  COps^[COpN].Src := Src; COps^[COpN].Vl := Vl; COps^[COpN].Md5 := '';
  COpAdd := COpN;
  Inc(COpN);
End;

{ cle de tri : '/' avant tout autre caractere (parcours en profondeur :
  un dossier et son contenu se suivent) }
Function PKey(Const P : String) : String;
Var I : LongInt; S : String;
Begin
  S := P;
  For I := 1 To Length(S) Do If S[I] = '/' Then S[I] := #1;
  PKey := S;
End;

Procedure COpSort;
Var I, J : LongInt; T : TCOp; K : String;
Begin
  { tri par insertion (quelques centaines d'operations au plus) }
  For I := 1 To COpN - 1 Do
  Begin
    T := COps^[I];
    K := PKey(T.Path);
    J := I - 1;
    While (J >= 0) And (PKey(COps^[J].Path) > K) Do
    Begin
      COps^[J + 1] := COps^[J]; Dec(J);
    End;
    COps^[J + 1] := T;
  End;
End;

{ entier variable de svndiff (7 bits par octet, poids fort d'abord) }
Procedure SdInt(Var B : TBuf; V : LongInt);
Var T : Array[0..5] Of Byte; N, I : LongInt;
Begin
  N := 0;
  Repeat
    T[N] := V And 127; V := V Shr 7; Inc(N);
  Until V = 0;
  For I := N - 1 DownTo 0 Do
    If I > 0 Then BufByte(B, T[I] Or 128) Else BufByte(B, T[I]);
End;

Const
  SdWin = 65536;

{ fenetre svndiff0 (texte entier, sans source) des octets D[0..N-1] }
Procedure SdWindow(Var O, D : TBuf; N : LongInt);
Var I : TBuf;
Begin
  BufInit(I);
  If N < 64 Then BufByte(I, $80 Or N)
  Else
  Begin
    BufByte(I, $80); SdInt(I, N);
  End;
  SdInt(O, 0); SdInt(O, 0); SdInt(O, N); SdInt(O, I.N); SdInt(O, N);
  BufAppend(O, I, 0, I.N);
  BufAppend(O, D, 0, N);
  BufFree(I);
End;

{ svndiff0 complet d'un fichier dans O ; MD5 du contenu }
Function SdFile(Const Path : String; Var O : TBuf; Var Md5 : String)
  : Boolean;
Var H, Pos, N : LongInt; Ch : TBuf; C : TMd5; D : TMd5D;
Begin
  SdFile := False;
  O.N := 0;
  BufStr(O, 'SVN'); BufByte(O, 0);
  H := FOpenR(Path);
  If H < 0 Then
  Begin
    GitErr := 'lecture impossible : ' + Path; Exit;
  End;
  BufInit(Ch);
  BufNeed(Ch, SdWin);
  Md5Init(C);
  Pos := 0;
  Repeat
    N := FReadAt(H, Pos, Ch.P, SdWin);
    If N <= 0 Then Break;
    Md5Ptr(C, Ch.P, 0, N);
    SdWindow(O, Ch, N);
    Pos := Pos + N;
  Until GitOom;
  FClose(H);
  BufFree(Ch);
  Md5Final(C, D);
  Md5 := Md5HexD(D);
  SdFile := Not GitOom;
End;

Function SvTok(I : LongInt) : String;
Begin
  SvTok := 't' + IStr(I);
End;

{ envoi d'un fichier (svn://) : fenetres de 64 Ko, sans tout charger }
Function SvSendFile(Const Tok, Path : String; Var Md5 : String) : Boolean;
Var H, Pos, N : LongInt; Ch, W : TBuf; C : TMd5; D : TMd5D;
Begin
  SvSendFile := False;
  H := FOpenR(Path);
  If H < 0 Then
  Begin
    GitErr := 'lecture impossible : ' + Path; Exit;
  End;
  BufInit(Ch); BufInit(W);
  BufNeed(Ch, SdWin);
  W.N := 0;
  BufStr(W, 'SVN'); BufByte(W, 0);
  SvW('( textdelta-chunk ( ');
  SvS(Tok);
  SvSB(W, 0, W.N);
  SvW(') ) ');
  Md5Init(C);
  Pos := 0;
  Repeat
    N := FReadAt(H, Pos, Ch.P, SdWin);
    If N <= 0 Then Break;
    Md5Ptr(C, Ch.P, 0, N);
    W.N := 0;
    SdWindow(W, Ch, N);
    SvW('( textdelta-chunk ( ');
    SvS(Tok);
    SvSB(W, 0, W.N);
    SvW(') ) ');
    Pos := Pos + N;
    If SvOut.N > 262144 Then
      If Not SvFlush Then Break;
  Until GitOom;
  FClose(H);
  BufFree(Ch); BufFree(W);
  Md5Final(C, D);
  Md5 := Md5HexD(D);
  SvSendFile := Not GitOom;
End;

{ commit par svn:// : pilotage de l'editeur du serveur ; pile des
  dossiers ouverts (chemins et jetons) }
Var
  CStack, CSTok : Array[0..63] Of String[200];
  CSN, CTk : LongInt;

Function DirOfP(Const X : String) : String;
Var J : LongInt;
Begin
  J := Length(X);
  While (J > 0) And (X[J] <> '/') Do Dec(J);
  DirOfP := Copy(X, 1, J - 1);
End;

Function UnderD(Const X, D : String) : Boolean;
Begin
  UnderD := (D = '') Or (Copy(X, 1, Length(D) + 1) = D + '/') Or (X = D);
End;

Procedure CloseTo(Const D : String);
Begin
  While (CSN > 1) And Not UnderD(D, CStack[CSN - 1]) Do
  Begin
    Dec(CSN);
    SvW('( close-dir ( ');
    SvS(CSTok[CSN]);
    SvW(') ) ');
  End;
End;

{ ouvre les dossiers jusqu'a D (deja existants dans le depot) }
Procedure OpenTo(Const D : String);
Var Rest, Cur, C : String; J : LongInt;
Begin
  CloseTo(D);
  Cur := CStack[CSN - 1];
  If Cur = D Then Exit;
  If Cur = '' Then Rest := D Else Rest := Copy(D, Length(Cur) + 2, 255);
  While Rest <> '' Do
  Begin
    J := Pos('/', Rest);
    If J = 0 Then J := Length(Rest) + 1;
    C := Copy(Rest, 1, J - 1);
    Delete(Rest, 1, J);
    Cur := JoinP(Cur, C);
    Inc(CTk);
    SvW('( open-dir ( ');
    SvS(Cur); SvS(CSTok[CSN - 1]); SvS(SvTok(CTk));
    SvW('( ) ) ) ');
    CStack[CSN] := Cur; CSTok[CSN] := SvTok(CTk); Inc(CSN);
  End;
End;

Function SvCommit(Var Msg : TBuf) : Boolean;
Var I, P, N : LongInt; Parent, Md5 : String;
Begin
  SvCommit := False;
  SvOut.N := 0;
  SvW('( commit ( ');
  SvSB(Msg, 0, Msg.N);
  SvW('( ) false ( ( 7:svn:log ');
  SvSB(Msg, 0, Msg.N);
  SvW(') ) ) ) ');
  If Not SvFlush Then Exit;
  P := SvResp(SvRead);
  If P < 0 Then Exit;
  If Not SvAuth(P) Then Exit;
  If SvResp(SvRead) < 0 Then Exit;
  { editeur : racine, puis les operations triees par chemin }
  CTk := 0;
  SvW('( open-root ( ( ) 2:t0 ) ) ');
  CStack[0] := ''; CSTok[0] := 't0'; CSN := 1;
  For I := 0 To COpN - 1 Do
  Begin
    GitProgress('Envoi des modifications', I, COpN);
    With COps^[I] Do
    Begin
      Parent := DirOfP(Path);
      Case K Of
        CoAddDir, CoCopyDir :
        Begin
          OpenTo(Parent);
          Inc(CTk);
          SvW('( add-dir ( ');
          SvS(Path); SvS(CSTok[CSN - 1]); SvS(SvTok(CTk));
          If K = CoCopyDir Then
          Begin
            SvW('( ');
            SvS(RaRoot + '/' + UrlEnc(Src));
            SvW(IStr(Rev) + ' ) ) ) ');
          End
          Else SvW('( ) ) ) ');
          CStack[CSN] := Path; CSTok[CSN] := SvTok(CTk); Inc(CSN);
        End;
        CoDelete :
        Begin
          OpenTo(Parent);
          SvW('( delete-entry ( ');
          SvS(Path);
          SvW('( ' + IStr(Rev) + ' ) ');
          SvS(CSTok[CSN - 1]);
          SvW(') ) ');
        End;
        CoPropDir :
        Begin
          OpenTo(Path);
          SvW('( change-dir-prop ( ');
          SvS(CSTok[CSN - 1]); SvS(Src);
          If Vl <> '' Then
          Begin
            SvW('( '); SvS(Vl); SvW(') ) ) ');
          End
          Else SvW('( ) ) ) ');
        End;
        CoAddFile, CoModFile :
        Begin
          OpenTo(Parent);
          Inc(CTk);
          If K = CoAddFile Then SvW('( add-file ( ') Else SvW('( open-file ( ');
          SvS(Path); SvS(CSTok[CSN - 1]); SvS(SvTok(CTk));
          If K = CoAddFile Then SvW('( ) ) ) ')
          Else SvW('( ' + IStr(Rev) + ' ) ) ) ');
          SvW('( apply-textdelta ( ');
          SvS(SvTok(CTk));
          SvW('( ) ) ) ');
          If Not SvSendFile(SvTok(CTk), Src, Md5) Then Exit;
          COps^[I].Md5 := Md5;
          SvW('( textdelta-end ( ');
          SvS(SvTok(CTk));
          SvW(') ) ( close-file ( ');
          SvS(SvTok(CTk));
          SvW('( '); SvS(Md5); SvW(') ) ) ');
        End;
      End;
    End;
    If SvOut.N > 65536 Then
      If Not SvFlush Then Exit;
  End;
  CloseTo('');
  SvW('( close-dir ( 2:t0 ) ) ( close-edit ( ) ) ');
  If Not SvFlush Then Exit;
  { reponse de l'editeur, puis informations du commit }
  N := SvRead;
  If SvResp(N) < 0 Then Exit;
  P := SvResp(SvRead);
  If P < 0 Then Exit;
  If Not SvAuth(P) Then Exit;
  N := SvRead;
  If (N < 0) Or (NKind^[N] <> NkList) Then Exit;
  If NStr(NChild(N, 0)) = 'failure' Then
  Begin
    GitErr := SvFailMsg(N); Exit;
  End;
  CNewRev := NNum(NChild(N, 0));
  CDate := SvnDate(NStr(NOpt(NChild(N, 1))));
  CAuthor := NStr(NOpt(NChild(N, 2)));
  SvCommit := CNewRev > 0;
End;

{ commit par http : transaction, PUT/MKCOL/DELETE/PROPPATCH, MERGE }
Function DavCommit(Var Msg : TBuf) : Boolean;
Var St, I : LongInt; Txn, Md5, H : String; Ok : Boolean; Sk : TBuf;
Begin
  DavCommit := False;
  { transaction avec le message }
  DavBody.N := 0;
  If DavProps Then
  Begin
    BufStr(DavBody, '(create-txn-with-props (7 svn:log ' + IStr(Msg.N) + ' ');
    BufAppend(DavBody, Msg, 0, Msg.N);
    BufStr(DavBody, '))');
  End
  Else BufStr(DavBody, '( create-txn )');
  If Not Dav('POST', DavMe, 'Content-Type: application/vnd.svn-skel'#13#10,
    '201', St) Then Exit;
  Txn := HttpHeader('SVN-Txn-Name');
  If Txn = '' Then
  Begin
    GitErr := 'transaction refus'#233'e par le serveur'; Exit;
  End;
  Ok := True;
  If Not DavProps Then
  Begin
    DavBody.N := 0;
    BufStr(DavBody, '<?xml version="1.0" encoding="utf-8"?><D:propertyupdate'
      + ' xmlns:D="DAV:" xmlns:S="http://subversion.tigris.org/xmlns/svn/">' +
      '<D:set><D:prop><S:log>');
    BufXmlEsc(DavBody, Msg, 0, Msg.N);
    BufStr(DavBody, '</S:log></D:prop></D:set></D:propertyupdate>');
    Ok := Dav('PROPPATCH', DavTxn + '/' + Txn, 'Content-Type: text/xml' +
      #13#10, '207', St);
  End;
  BufInit(Sk);
  I := 0;
  While Ok And (I < COpN) Do
  Begin
    GitProgress('Envoi des modifications', I, COpN);
    With COps^[I] Do
    Begin
      H := DavTxr + '/' + Txn + '/' + Path;
      Case K Of
        CoAddDir :
        Begin
          DavBody.N := 0;
          Ok := Dav('MKCOL', H, '', '201', St);
        End;
        CoCopyDir :
        Begin
          DavBody.N := 0;
          Ok := Dav('COPY', RvrPath(Src, Rev), 'Destination: ' + DavHost +
            UrlEnc(H) + #13#10'Depth: infinity'#13#10'Overwrite: F'#13#10,
            '201 204', St);
        End;
        CoDelete :
        Begin
          DavBody.N := 0;
          Ok := Dav('DELETE', H, 'X-SVN-Version-Name: ' + IStr(Rev) + #13#10,
            '204', St);
        End;
        CoPropDir :
        Begin
          DavBody.N := 0;
          BufStr(DavBody, '<?xml version="1.0" encoding="utf-8"?><D:' +
            'propertyupdate xmlns:D="DAV:" xmlns:S="http://subversion.' +
            'tigris.org/xmlns/svn/">');
          If Vl <> '' Then
            BufStr(DavBody, '<D:set><D:prop><S:ignore>' + XmlEsc(Vl) +
              '</S:ignore></D:prop></D:set>')
          Else BufStr(DavBody, '<D:remove><D:prop><S:ignore/></D:prop>' +
            '</D:remove>');
          BufStr(DavBody, '</D:propertyupdate>');
          Ok := Dav('PROPPATCH', H, 'Content-Type: text/xml'#13#10, '207',
            St);
        End;
        CoAddFile, CoModFile :
        Begin
          Ok := SdFile(Src, DavBody, Md5);
          If Ok Then
          Begin
            COps^[I].Md5 := Md5;
            If K = CoModFile Then
              Ok := Dav('PUT', H, 'Content-Type: application/vnd.svn-svndiff'
                + #13#10'X-SVN-Version-Name: ' + IStr(Rev) + #13#10 +
                'X-SVN-Result-Fulltext-MD5: ' + Md5 + #13#10, '201 204', St)
            Else
              Ok := Dav('PUT', H, 'Content-Type: application/vnd.svn-svndiff'
                + #13#10'X-SVN-Result-Fulltext-MD5: ' + Md5 + #13#10,
                '201 204', St);
          End;
        End;
      End;
    End;
    Inc(I);
  End;
  BufFree(Sk);
  If Ok Then
  Begin
    DavBody.N := 0;
    BufStr(DavBody, '<?xml version="1.0" encoding="utf-8"?><D:merge ' +
      'xmlns:D="DAV:"><D:source><D:href>');
    BufStr(DavBody, XmlEsc(UrlEnc(DavTxn + '/' + Txn)));
    BufStr(DavBody, '</D:href></D:source><D:no-auto-merge/><D:no-checkout/>' +
      '<D:prop><D:checked-in/><D:version-name/><D:resourcetype/>');
    BufStr(DavBody, '<D:creationdate/><D:creator-displayname/></D:prop>' +
      '</D:merge>');
    Ok := Dav('MERGE', DavRootP, 'Content-Type: text/xml'#13#10, '200', St);
    If Ok Then
    Begin
      CNewRev := StrToIntDef(XmlFirst(DavResp, 'version-name'), -1);
      CDate := SvnDate(XmlFirst(DavResp, 'creationdate'));
      CAuthor := Utf8ToAnsi(XmlFirst(DavResp, 'creator-displayname'));
      Ok := CNewRev > 0;
      If Not Ok Then GitErr := 'r'#233'ponse MERGE inattendue';
    End;
  End;
  If Not Ok Then
  Begin
    { abandon de la transaction }
    H := GitErr;
    DavBody.N := 0;
    If Dav('DELETE', DavTxn + '/' + Txn, '', '204 404', St) Then ;
    GitErr := H;
  End;
  DavCommit := Ok;
End;

{ commit des operations COps (chemins depuis la racine) }
Function RaCommit(Var Msg : TBuf) : Boolean;
Begin
  COpSort;
  CNewRev := -1; CDate := 0; CAuthor := '';
  If RaKind = RaSvn Then
  Begin
    RaCommit := SvCommit(Msg);
    { apres une erreur au milieu de l'edition, la session est inutilisable }
    If CNewRev <= 0 Then RaClose;
  End
  Else RaCommit := DavCommit(Msg);
End;

{ ==================================================================== }
{ Copie de travail : .pasvn\entries, .pasvn\pristine\<md5>             }
{ ==================================================================== }

Const
  { etats des modifications (liste Chg) }
  StMod = 1; StNew = 2; StDel = 3; StConf = 4; StUnv = 5; StMiss = 6;
  StProp = 7;
  FlSel = $100;                        { element coche }
  MetaName = '.pasvn';
  DiffMax = 3000000;                   { fusion et diff en memoire }

Type
  TEnt = Record
    Path : String;                     { UTF-8, relatif a la copie }
    Md5 : String[32];                  { contenu de base ('' : aucun) }
    Kind, State : Char;                { f/d ; n a r c }
    Rev, Size, MTime : LongInt;        { Rev : derniere modification }
  End;
  TEntArr = Array[0..$FFFFF] Of TEnt;

Var
  WcDir, WcUrl, WcRoot, WcUuid : String;
  WcRev : LongInt;
  Ent : ^TEntArr;
  EntN, EntCap : LongInt;
  EntDirty : Boolean;
  IgnB, IgnBV, IgnP, IgnPV : TFlat;    { svn:ignore : base et a valider }
  Chg : TFlat;                         { modifications (Flag : etat) }
  FsAnsi : Boolean;                    { noms de fichiers ANSI (Windows) }
  UpdFiles, UpdConf, UpdDel, UpdAdd : LongInt;
  UpdTarget : LongInt;
  UpdSwitch : Boolean;
  UpdNote : String;

Function WorkPath(Const Rel : String) : String;
Var T : String; I : LongInt;
Begin
  If FsAnsi Then T := Utf8ToAnsi(Rel) Else T := Rel;
  For I := 1 To Length(T) Do If T[I] = '/' Then T[I] := PS;
  If T = '' Then WorkPath := WcDir Else WorkPath := WcDir + PS + T;
End;

Function MetaPath(Const N : String) : String;
Begin
  MetaPath := WcDir + PS + MetaName + PS + N;
End;

Function PristinePath(Const Md5 : String) : String;
Begin
  PristinePath := MetaPath('pristine' + PS + Md5);
End;

Function ParentP(Const P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> '/') Do Dec(K);
  If K = 0 Then ParentP := '' Else ParentP := Copy(P, 1, K - 1);
End;

Function BaseP(Const P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> '/') Do Dec(K);
  BaseP := Copy(P, K + 1, 255);
End;

{ P est-il dans le dossier D (ou D lui-meme) ? }
Function UnderP(Const P, D : String) : Boolean;
Begin
  UnderP := (D = '') Or (P = D) Or (Copy(P, 1, Length(D) + 1) = D + '/');
End;

{ ---- entrees ---- }

Function EntLower(Const P : String) : LongInt;
Var Lo, Hi, M : LongInt;
Begin
  Lo := 0; Hi := EntN;
  While Lo < Hi Do
  Begin
    M := (Lo + Hi) Div 2;
    If Ent^[M].Path < P Then Lo := M + 1 Else Hi := M;
  End;
  EntLower := Lo;
End;

Function EntFind(Const P : String) : LongInt;
Var K : LongInt;
Begin
  K := EntLower(P);
  If (K < EntN) And (Ent^[K].Path = P) Then EntFind := K Else EntFind := -1;
End;

Function EntAdd(Const P : String; Kind : Char) : LongInt;
Var Q : ^TEntArr; C, K : LongInt;
Begin
  K := EntFind(P);
  If K < 0 Then
  Begin
    If EntN >= EntCap Then
    Begin
      C := EntCap * 2;
      If C < 128 Then C := 128;
      GetMem(Q, C * SizeOf(TEnt));
      If Q = Nil Then
      Begin
        GitOom := True; GitErr := 'm'#233'moire insuffisante';
        EntAdd := -1; Exit;
      End;
      If EntN > 0 Then Move(Ent^[0], Q^[0], EntN * SizeOf(TEnt));
      If Ent <> Nil Then FreeMem(Ent, EntCap * SizeOf(TEnt));
      Ent := Q; EntCap := C;
    End;
    K := EntLower(P);
    If K < EntN Then Move(Ent^[K], Ent^[K + 1], (EntN - K) * SizeOf(TEnt));
    Inc(EntN);
    Ent^[K].Path := P;
  End;
  Ent^[K].Kind := Kind; Ent^[K].State := 'n'; Ent^[K].Md5 := '';
  Ent^[K].Rev := -1; Ent^[K].Size := -1; Ent^[K].MTime := 0;
  EntDirty := True;
  EntAdd := K;
End;

Procedure EntDel(K : LongInt);
Begin
  If (K < 0) Or (K >= EntN) Then Exit;
  If K < EntN - 1 Then Move(Ent^[K + 1], Ent^[K], (EntN - K - 1) *
    SizeOf(TEnt));
  Dec(EntN);
  EntDirty := True;
End;

{ retire P et tout ce qui est dessous }
Procedure EntDelTree(Const P : String);
Var K : LongInt;
Begin
  K := EntFind(P);
  If K >= 0 Then EntDel(K);
  K := EntLower(P + '/');
  While (K < EntN) And (Copy(Ent^[K].Path, 1, Length(P) + 1) = P + '/') Do
    EntDel(K);
End;

{ svn:ignore d'un dossier (base ou a valider) }
Function IgnGet(Var L, V : TFlat; Const D : String) : String;
Var K : LongInt;
Begin
  K := FlatFind(L, D);
  If K >= 0 Then IgnGet := V.E^[K].Path Else IgnGet := '';
End;

Function IgnHas(Var L : TFlat; Const D : String) : Boolean;
Begin
  IgnHas := FlatFind(L, D) >= 0;
End;

Procedure IgnSet(Var L, V : TFlat; Const D, S : String);
Var K, I : LongInt;
Begin
  K := FlatFind(L, D);
  If K < 0 Then
  Begin
    K := FlatAdd(L, D);
    I := FlatAdd(V, S);
    { garder les deux listes alignees (tri par chemin) }
    While (K > 0) And (L.E^[K - 1].Path > D) Do
    Begin
      L.E^[K] := L.E^[K - 1]; V.E^[K] := V.E^[K - 1]; Dec(K);
    End;
    L.E^[K].Path := D;
  End;
  V.E^[K].Path := S;
  If I = 0 Then ;
  EntDirty := True;
End;

Procedure IgnDel(Var L, V : TFlat; Const D : String);
Var K, I : LongInt;
Begin
  K := FlatFind(L, D);
  If K < 0 Then Exit;
  For I := K To L.N - 2 Do
  Begin
    L.E^[I] := L.E^[I + 1]; V.E^[I] := V.E^[I + 1];
  End;
  Dec(L.N); Dec(V.N);
  EntDirty := True;
End;

Function EscNl(Const S : String) : String;
Var I : LongInt; R : String;
Begin
  R := '';
  For I := 1 To Length(S) Do
    If S[I] = #10 Then R := R + '\n'
    Else If S[I] = '\' Then R := R + '\\'
    Else If S[I] <> #13 Then R := R + S[I];
  EscNl := R;
End;

Function UnEscNl(Const S : String) : String;
Var I : LongInt; R : String;
Begin
  R := '';
  I := 1;
  While I <= Length(S) Do
  Begin
    If (S[I] = '\') And (I < Length(S)) Then
    Begin
      If S[I + 1] = 'n' Then R := R + #10 Else R := R + S[I + 1];
      Inc(I, 2);
    End
    Else
    Begin
      R := R + S[I]; Inc(I);
    End;
  End;
  UnEscNl := R;
End;

Function WcSave : Boolean;
Var B : TBuf; I : LongInt; T : String;
Begin
  BufInit(B);
  BufStr(B, 'pasvn 1'#10'url ' + WcUrl + #10'root ' + WcRoot + #10'uuid ' +
    WcUuid + #10'rev ' + IStr(WcRev) + #10);
  For I := 0 To EntN - 1 Do
    With Ent^[I] Do
    Begin
      If Md5 = '' Then T := '-' Else T := Md5;
      BufStr(B, 'e'#9 + Kind + #9 + State + #9 + IStr(Rev) + #9 + IStr(Size)
        + #9 + IStr(MTime) + #9 + T + #9);
      BufStr(B, Path);
      BufByte(B, 10);
    End;
  For I := 0 To IgnB.N - 1 Do
  Begin
    BufStr(B, 'i'#9 + IgnB.E^[I].Path + #9);
    BufStr(B, EscNl(IgnBV.E^[I].Path));
    BufByte(B, 10);
  End;
  For I := 0 To IgnP.N - 1 Do
  Begin
    BufStr(B, 'I'#9 + IgnP.E^[I].Path + #9);
    BufStr(B, EscNl(IgnPV.E^[I].Path));
    BufByte(B, 10);
  End;
  WcSave := False;
  If Not GitOom Then
    If FileSave(MetaPath('entries.new'), B, 0, B.N) Then
      WcSave := FileRen(MetaPath('entries.new'), MetaPath('entries'));
  BufFree(B);
  EntDirty := False;
End;

{ champ N (0...) d'une ligne separee par des tabulations }
Function Fld(Const L : String; N : LongInt) : String;
Var I, K : LongInt;
Begin
  K := 0; I := 1;
  While (K < N) And (I <= Length(L)) Do
  Begin
    If L[I] = #9 Then Inc(K);
    Inc(I);
  End;
  Fld := '';
  If K < N Then Exit;
  K := I;
  While (K <= Length(L)) And (L[K] <> #9) Do Inc(K);
  Fld := Copy(L, I, K - I);
End;

Function WcLoad(Const Dir : String) : Boolean;
Var B : TBuf; I, J, K : LongInt; L : String;
Begin
  WcLoad := False;
  WcDir := Dir;
  While (Length(WcDir) > 3) And (WcDir[Length(WcDir)] = PS) Do
    Delete(WcDir, Length(WcDir), 1);
  EntN := 0; IgnB.N := 0; IgnBV.N := 0; IgnP.N := 0; IgnPV.N := 0;
  WcUrl := ''; WcRoot := ''; WcUuid := ''; WcRev := 0;
  BufInit(B);
  If Not FileLoad(MetaPath('entries'), B) Then
  Begin
    BufFree(B);
    If DirExist(WcDir + PS + '.svn') Then
      GitErr := 'ce dossier est une copie de travail du client svn ' +
        'officiel (.svn) : extrayez-la avec le Client SVN'
    Else GitErr := 'ce dossier n''est pas une copie de travail Subversion';
    Exit;
  End;
  I := 0;
  While I < B.N Do
  Begin
    J := I;
    While (J < B.N) And (B.P^[J] <> 10) Do Inc(J);
    L := BufStrAt(B, I, MinL(J - I, 255));
    I := J + 1;
    If L = '' Then Continue;
    If Copy(L, 1, 4) = 'url ' Then WcUrl := Copy(L, 5, 255)
    Else If Copy(L, 1, 5) = 'root ' Then WcRoot := Copy(L, 6, 255)
    Else If Copy(L, 1, 5) = 'uuid ' Then WcUuid := Copy(L, 6, 255)
    Else If Copy(L, 1, 4) = 'rev ' Then WcRev := StrToIntDef(Copy(L, 5, 20),
      0)
    Else If Copy(L, 1, 2) = 'e'#9 Then
    Begin
      K := EntAdd(Fld(L, 7), Fld(L, 1)[1]);
      If K < 0 Then Break;
      Ent^[K].State := Fld(L, 2)[1];
      Ent^[K].Rev := StrToIntDef(Fld(L, 3), -1);
      Ent^[K].Size := StrToIntDef(Fld(L, 4), -1);
      Ent^[K].MTime := StrToIntDef(Fld(L, 5), 0);
      Ent^[K].Md5 := Fld(L, 6);
      If Ent^[K].Md5 = '-' Then Ent^[K].Md5 := '';
    End
    Else If Copy(L, 1, 2) = 'i'#9 Then
      IgnSet(IgnB, IgnBV, Fld(L, 1), UnEscNl(Fld(L, 2)))
    Else If Copy(L, 1, 2) = 'I'#9 Then
      IgnSet(IgnP, IgnPV, Fld(L, 1), UnEscNl(Fld(L, 2)));
  End;
  BufFree(B);
  EntDirty := False;
  WcLoad := (WcUrl <> '') And (EntFind('') >= 0);
  If WcUrl = '' Then GitErr := 'copie de travail endommag'#233'e (.pasvn)';
End;

{ ---- fichiers ---- }

{ copie de fichier par morceaux }
Function FileCopy(Const A, B : String) : Boolean;
Var HA, HB, N, Pos : LongInt; Ch : TBuf; Ok : Boolean;
Begin
  FileCopy := False;
  HA := FOpenR(A);
  If HA < 0 Then Exit;
  HB := FCreate(B);
  If HB < 0 Then
  Begin
    FClose(HA); Exit;
  End;
  BufInit(Ch);
  BufNeed(Ch, 65536);
  Ok := Ch.Cap >= 65536;
  Pos := 0;
  While Ok Do
  Begin
    N := FReadAt(HA, Pos, Ch.P, 65536);
    If N <= 0 Then Break;
    Ok := FWrite(HB, Ch.P, N);
    Pos := Pos + N;
  End;
  FClose(HA); FClose(HB);
  BufFree(Ch);
  FileCopy := Ok;
End;

{ met a jour taille et date en cache d'une entree }
Procedure EntStat(K : LongInt);
Var Sz, Tm : LongInt;
Begin
  If FileStat(WorkPath(Ent^[K].Path), Sz, Tm) Then
  Begin
    Ent^[K].Size := Sz; Ent^[K].MTime := Tm;
  End
  Else
  Begin
    Ent^[K].Size := -1; Ent^[K].MTime := 0;
  End;
  EntDirty := True;
End;

{ fichier de travail identique a sa base ? }
Function WorkSame(K : LongInt) : Boolean;
Var Sz, Tm : LongInt; M : String;
Begin
  WorkSame := False;
  If Not FileStat(WorkPath(Ent^[K].Path), Sz, Tm) Then Exit;
  If (Sz = Ent^[K].Size) And (Tm = Ent^[K].MTime) Then
  Begin
    WorkSame := True; Exit;
  End;
  M := Md5File(WorkPath(Ent^[K].Path), Sz);
  If (M <> '') And (M = Ent^[K].Md5) Then
  Begin
    WorkSame := True;
    Ent^[K].Size := Sz; Ent^[K].MTime := Tm;
    EntDirty := True;
  End;
End;

{ ---- exclusions ---- }

Const
  GlobIgn : Array[0..13] Of String[12] = ('*.o', '*.lo', '*.la', '*.al',
    '.libs', '*.so', '*.a', '*.pyc', '*.pyo', '__pycache__', '*.rej', '*~',
    '#*#', '.DS_Store');

Function IgnoredIn(Const Dir, Name : String) : Boolean;
Var S, L : String; I, K : LongInt;
Begin
  IgnoredIn := True;
  For I := 0 To 13 Do
    If Glob(GlobIgn[I], 1, Name, 1) Then Exit;
  If IgnHas(IgnP, Dir) Then S := IgnGet(IgnP, IgnPV, Dir)
  Else S := IgnGet(IgnB, IgnBV, Dir);
  While S <> '' Do
  Begin
    K := Pos(#10, S);
    If K = 0 Then K := Length(S) + 1;
    L := TrimS(Copy(S, 1, K - 1));
    Delete(S, 1, K);
    If (L <> '') And Glob(L, 1, Name, 1) Then Exit;
  End;
  IgnoredIn := False;
End;

{ ==================================================================== }
{ Statut                                                                }
{ ==================================================================== }

Procedure ChgAdd(Const P : String; St : LongInt);
Var K : LongInt;
Begin
  K := FlatAdd(Chg, P);
  Chg.E^[K].Flag := St Or FlSel;
End;

{ fichiers produits par un conflit (nom.mine, nom.rN) d'une entree en
  conflit : non listes }
Function ConflictArtifact(Const P : String) : Boolean;
Var K : LongInt; B : String;
Begin
  ConflictArtifact := False;
  If Copy(P, Length(P) - 4, 5) = '.mine' Then B := Copy(P, 1, Length(P) - 5)
  Else
  Begin
    K := Length(P);
    While (K > 0) And (P[K] >= '0') And (P[K] <= '9') Do Dec(K);
    If (K < 3) Or (K = Length(P)) Or (Copy(P, K - 1, 2) <> '.r') Then Exit;
    B := Copy(P, 1, K - 2);
  End;
  K := EntFind(B);
  ConflictArtifact := (K >= 0) And (Ent^[K].State = 'c');
End;

{ dossiers et fichiers non suivis sous Rel (dossier existant) }
Procedure ScanUnv(Const Rel : String; Unv : Boolean; Depth : LongInt);
Var SR : TSRec; L : TFlat; K, J : LongInt; P, D : String; Ok : Boolean;
Begin
  If Depth > 40 Then Exit;
  FlatInit(L);
  D := WorkPath(Rel);
  Ok := FsFirst(D + PS + AllFiles, SR);
  While Ok Do
  Begin
    If (SR.Name <> '.') And (SR.Name <> '..') And
       ((SR.Attr And 8) = 0) Then
    Begin
      K := FlatAdd(L, SR.Name);
      L.E^[K].Mode := Ord((SR.Attr And $10) <> 0);
    End;
    Ok := FsNext(SR);
  End;
  FsClose(SR);
  For J := 0 To L.N - 1 Do
  Begin
    If FsAnsi Then P := JoinP(Rel, AnsiToUtf8(L.E^[J].Path))
    Else P := JoinP(Rel, L.E^[J].Path);
    If (Rel = '') And (L.E^[J].Path = MetaName) Then Continue;
    K := EntFind(P);
    If L.E^[J].Mode <> 0 Then
    Begin
      If (K >= 0) And (Ent^[K].Kind = 'd') Then ScanUnv(P, False, Depth + 1)
      Else If (K < 0) And Not IgnoredIn(Rel, BaseP(P)) Then
        ScanUnv(P, True, Depth + 1);
    End
    Else If (K < 0) And Not IgnoredIn(Rel, BaseP(P)) And
      Not ConflictArtifact(P) Then ChgAdd(P, StUnv);
  End;
  FlatFree(L);
  If Unv Then ;
End;

{ liste des modifications dans Chg }
Function WcStatus : Boolean;
Var I : LongInt;
Begin
  WcStatus := True;
  Chg.N := 0;
  I := 0;
  While I < EntN Do
  Begin
    With Ent^[I] Do
      If Kind = 'f' Then
        Case State Of
          'a' :
            If FileExist(WorkPath(Path)) Then ChgAdd(Path, StNew)
            Else
            Begin
              { ajoute puis supprime : oublie }
              EntDel(I); Continue;
            End;
          'r' : ChgAdd(Path, StDel);
          'c' : ChgAdd(Path, StConf);
          Else
            If Not FileExist(WorkPath(Path)) Then ChgAdd(Path, StMiss)
            Else If Not WorkSame(I) Then ChgAdd(Path, StMod);
        End;
    Inc(I);
  End;
  For I := 0 To IgnP.N - 1 Do
    If EntFind(IgnP.E^[I].Path) >= 0 Then ChgAdd(IgnP.E^[I].Path, StProp);
  ScanUnv('', False, 0);
  FlatSort(Chg);
  If EntDirty Then WcSave;
End;

{ ==================================================================== }
{ Extraction et mise a jour                                             }
{ ==================================================================== }

Function RPath(Const P : String) : String;
Begin
  RPath := JoinP(RaRel, P);
End;

{ telecharge le fichier dans la reserve des bases ; Md5 en retour }
Function FetchPristine(Const P : String; Rev : LongInt; Var Md5 : String)
  : Boolean;
Var T : String; B : TBuf;
Begin
  FetchPristine := False;
  MkDirs(MetaPath('pristine'));
  T := MetaPath('tmp.dl');
  BufInit(B);
  If Not RaGetFile(RPath(P), Rev, T, B, Md5) Then
  Begin
    BufFree(B); Exit;
  End;
  BufFree(B);
  If FileExist(PristinePath(Md5)) Then FileDel(T)
  Else If Not FileRen(T, PristinePath(Md5)) Then
  Begin
    GitErr := 'enregistrement impossible : ' + PristinePath(Md5); Exit;
  End;
  FetchPristine := True;
End;

Function LoadSmall(Const Path : String; Var B : TBuf) : Boolean;
Var Sz, Tm : LongInt;
Begin
  LoadSmall := False;
  B.N := 0;
  If Not FileStat(Path, Sz, Tm) Or (Sz > DiffMax) Then Exit;
  LoadSmall := FileLoad(Path, B);
End;

{ fusionne les modifications locales de l'entree K avec la nouvelle base
  NewMd5 (revision R) ; vrai si sans conflit }
Function MergeFile(K : LongInt; Const NewMd5 : String; R : LongInt)
  : Boolean;
Var Bs, Mi, Th, O : TBuf; W : String; Ok : Boolean;
Begin
  MergeFile := False;
  BufInit(Bs); BufInit(Mi); BufInit(Th); BufInit(O);
  W := WorkPath(Ent^[K].Path);
  Ok := LoadSmall(PristinePath(Ent^[K].Md5), Bs) And LoadSmall(W, Mi) And
    LoadSmall(PristinePath(NewMd5), Th);
  If Ok Then Ok := Not IsBinary(Bs) And Not IsBinary(Mi) And
    Not IsBinary(Th);
  If Ok Then
  Begin
    If Merge3(Bs, Mi, Th, O, '.r' + IStr(R)) Then
    Begin
      If FileSave(W, O, 0, O.N) Then MergeFile := True;
    End
    Else
    Begin
      { conflit : marqueurs, et les trois versions a cote (comme svn) }
      If FileCopy(W, W + '.mine') Then ;
      If FileCopy(PristinePath(Ent^[K].Md5), W + '.r' + IStr(Ent^[K].Rev))
      Then ;
      If FileCopy(PristinePath(NewMd5), W + '.r' + IStr(R)) Then ;
      If FileSave(W, O, 0, O.N) Then ;
    End;
  End
  Else
  Begin
    { binaire ou trop grand : la version locale est gardee }
    If FileCopy(W, W + '.mine') Then ;
    If FileCopy(PristinePath(NewMd5), W + '.r' + IStr(R)) Then ;
  End;
  BufFree(Bs); BufFree(Mi); BufFree(Th); BufFree(O);
End;

{ un fichier du depot (nom, revision) dans la copie }
Function UpdFile(Const P : String; Var E : TDirE) : Boolean;
Var K : LongInt; Md5, W : String; Local : Boolean;
Begin
  UpdFile := False;
  K := EntFind(P);
  If (K >= 0) And (Ent^[K].Kind = 'f') And (Ent^[K].State <> 'a') And
     (Ent^[K].Rev = E.Rev) And (Ent^[K].Md5 <> '') And Not UpdSwitch Then
  Begin
    UpdFile := True; Exit;
  End;
  If (K >= 0) And (Ent^[K].Kind = 'd') Then
  Begin
    { dossier remplace par un fichier }
    EntDelTree(P);
    K := -1;
  End;
  GitProgress('Mise '#224' jour des fichiers', UpdFiles, 0);
  If Not FetchPristine(P, UpdTarget, Md5) Then Exit;
  W := WorkPath(P);
  If (K >= 0) And (Ent^[K].Md5 = Md5) And (Ent^[K].State <> 'a') Then
  Begin
    { meme contenu (changement de branche, proprietes) }
    Ent^[K].Rev := E.Rev; EntDirty := True;
    UpdFile := True; Exit;
  End;
  Inc(UpdFiles);
  Local := FileExist(W);
  If K < 0 Then
  Begin
    If Local And (Md5File(W, E.Size) <> Md5) Then
    Begin
      { fichier non suivi au meme nom : garde en .mine, conflit }
      If FileRen(W, W + '.mine') Then ;
      K := EntAdd(P, 'f');
      If K < 0 Then Exit;
      Ent^[K].State := 'c';
      Inc(UpdConf);
    End
    Else
    Begin
      K := EntAdd(P, 'f');
      If K < 0 Then Exit;
      Inc(UpdAdd);
    End;
    If Not FileCopy(PristinePath(Md5), W) Then
    Begin
      GitErr := #233'criture impossible : ' + W; Exit;
    End;
  End
  Else If Ent^[K].State = 'a' Then
  Begin
    { ajoute localement et dans le depot : conflit si different }
    If Local And (Md5File(W, E.Size) <> Md5) Then
    Begin
      If FileCopy(W, W + '.mine') Then ;
      Ent^[K].State := 'c';
      Inc(UpdConf);
    End
    Else Ent^[K].State := 'n';
    If Ent^[K].State = 'n' Then
      If Not FileCopy(PristinePath(Md5), W) Then Exit;
  End
  Else If Not Local Or WorkSame(K) Then
  Begin
    If Ent^[K].State <> 'r' Then
      If Not FileCopy(PristinePath(Md5), W) Then
      Begin
        GitErr := #233'criture impossible : ' + W; Exit;
      End;
  End
  Else
  Begin
    { modifie localement : fusion a trois voies }
    If Not MergeFile(K, Md5, E.Rev) Then
    Begin
      Ent^[K].State := 'c';
      Inc(UpdConf);
    End;
  End;
  Ent^[K].Md5 := Md5;
  Ent^[K].Rev := E.Rev;
  If Ent^[K].State = 'n' Then
    If WorkSame(K) Then EntStat(K) Else Ent^[K].MTime := 0;
  EntDirty := True;
  UpdFile := True;
End;

{ suppression locale d'un element supprime du depot }
Procedure UpdRemove(Const P : String; Depth : LongInt);
Var K, I : LongInt; W : String;
Begin
  K := EntFind(P);
  If K < 0 Then Exit;
  If Ent^[K].Kind = 'd' Then
  Begin
    I := EntLower(P + '/');
    While (I < EntN) And (Copy(Ent^[I].Path, 1, Length(P) + 1) = P + '/') Do
    Begin
      If (ParentP(Ent^[I].Path) = P) And (Depth < 40) Then
      Begin
        UpdRemove(Ent^[I].Path, Depth + 1);
        I := EntLower(P + '/');
      End
      Else Inc(I);
    End;
    K := EntFind(P);
    If K >= 0 Then EntDel(K);
    If FRmDir(WorkPath(P)) Then ;
    Exit;
  End;
  W := WorkPath(P);
  If Ent^[K].State = 'a' Then Exit;
  If FileExist(W) And Not WorkSame(K) Then
    { modifie localement : garde comme fichier non suivi }
    UpdNote := 'modifi'#233' localement et supprim'#233' du d'#233'p'#244't : ' +
      P
  Else FileDel(W);
  EntDel(K);
  Inc(UpdDel);
End;

{ met a jour le dossier P (et son contenu) ; Force : tout comparer }
Function UpdDir(Const P : String; Force : Boolean; Depth : LongInt)
  : Boolean;
Var L : TDirList; D, I, K : LongInt; C, Q : String; Seen : TFlat;
Begin
  UpdDir := False;
  If Depth > 60 Then Exit;
  DirInit(L);
  If Not RaGetDir(RPath(P), UpdTarget, L) Then Exit;
  D := EntFind(P);
  If D < 0 Then
  Begin
    D := EntAdd(P, 'd');
    If D < 0 Then Exit;
  End;
  If (Not Force) And (Ent^[D].Rev = L.Rev) And (L.Rev > 0) And
     (Ent^[D].State = 'n') Then
  Begin
    DirFree(L);
    UpdDir := True; Exit;
  End;
  MkDirs(WorkPath(P));
  FlatInit(Seen);
  For I := 0 To L.N - 1 Do
  Begin
    C := JoinP(P, L.E^[I].Name);
    K := FlatAdd(Seen, C);
    If L.E^[I].Kind = 'f' Then
    Begin
      If Not UpdFile(C, L.E^[I]) Then
      Begin
        DirFree(L); FlatFree(Seen); Exit;
      End;
    End
    Else
    Begin
      K := EntFind(C);
      If (K >= 0) And (Ent^[K].Kind = 'f') Then UpdRemove(C, Depth);
      K := EntFind(C);
      If K < 0 Then
      Begin
        K := EntAdd(C, 'd');
        If K < 0 Then Exit;
      End
      Else If Ent^[K].State = 'a' Then Ent^[K].State := 'n';
      If Not UpdDir(C, Force Or (Ent^[K].Rev < 0), Depth + 1) Then
      Begin
        DirFree(L); FlatFree(Seen); Exit;
      End;
    End;
    If GitOom Then Exit;
  End;
  { elements supprimes du depot : enfants directs absents de la liste }
  FlatSort(Seen);
  I := EntLower(JoinP(P, ''));
  If P <> '' Then I := EntLower(P + '/');
  While I < EntN Do
  Begin
    Q := Ent^[I].Path;
    If (P <> '') And (Copy(Q, 1, Length(P) + 1) <> P + '/') Then Break;
    If (Q <> P) And (ParentP(Q) = P) And (FlatFind(Seen, Q) < 0) And
       (Ent^[I].State <> 'a') Then
    Begin
      UpdRemove(Q, Depth);
      I := EntLower(Q);
    End
    Else Inc(I);
  End;
  FlatFree(Seen);
  D := EntFind(P);
  Ent^[D].Rev := L.Rev;
  Ent^[D].State := 'n';
  If L.Ign <> '' Then IgnSet(IgnB, IgnBV, P, L.Ign)
  Else IgnDel(IgnB, IgnBV, P);
  EntDirty := True;
  DirFree(L);
  UpdDir := True;
End;

{ mise a jour vers Rev (-1 : la plus recente) ; NewUrl <> '' : changer
  de branche (switch) }
Function WcUpdate(Rev : LongInt; Const NewUrl : String) : Boolean;
Var Head : LongInt; U : String; K : Char; Ok : Boolean;
Begin
  WcUpdate := False;
  UpdFiles := 0; UpdConf := 0; UpdDel := 0; UpdAdd := 0; UpdNote := '';
  UpdSwitch := NewUrl <> '';
  If UpdSwitch Then U := NewUrl Else U := WcUrl;
  If Not RaOpen(U) Then Exit;
  If (WcUuid <> '') And (RaUuid <> '') And (RaUuid <> WcUuid) Then
  Begin
    GitErr := 'cette URL est celle d''un autre d'#233'p'#244't'; Exit;
  End;
  If Not RaLatest(Head) Then Exit;
  If (Rev < 0) Or (Rev > Head) Then UpdTarget := Head Else UpdTarget := Rev;
  If Not RaCheckPath(RaRel, UpdTarget, K) Then Exit;
  If K <> 'd' Then
  Begin
    If K = 'n' Then GitErr := 'le chemin ' + Utf8ToAnsi(RaRel) + ' n''existe '
      + 'pas dans la r'#233'vision ' + IStr(UpdTarget)
    Else GitErr := 'l''URL d'#233'signe un fichier, pas un dossier';
    Exit;
  End;
  Ok := UpdDir('', UpdSwitch Or (UpdTarget < WcRev), 0);
  If Ok Then
  Begin
    WcRev := UpdTarget;
    WcUrl := U;
    WcRoot := RaRoot;
    If WcUuid = '' Then WcUuid := RaUuid;
  End;
  If Not WcSave And Ok Then
  Begin
    GitErr := 'enregistrement de .pasvn\entries impossible'; Ok := False;
  End;
  WcUpdate := Ok;
End;

{ extraction (checkout) de Url dans le dossier vide Dir }
Function WcCheckout(Const Url, Dir : String) : Boolean;
Begin
  WcCheckout := False;
  WcDir := Dir;
  While (Length(WcDir) > 3) And (WcDir[Length(WcDir)] = PS) Do
    Delete(WcDir, Length(WcDir), 1);
  MkDirs(MetaPath('pristine'));
  If Not DirExist(MetaPath('pristine')) Then
  Begin
    GitErr := 'cr'#233'ation du dossier impossible : ' + WcDir; Exit;
  End;
  EntN := 0; IgnB.N := 0; IgnBV.N := 0; IgnP.N := 0; IgnPV.N := 0;
  WcUrl := Url; WcRoot := ''; WcUuid := ''; WcRev := 0;
  If EntAdd('', 'd') < 0 Then Exit;
  WcCheckout := WcUpdate(-1, '');
End;

{ ==================================================================== }
{ Validation                                                            }
{ ==================================================================== }

Function HasConflictMark(Const Path : String) : Boolean;
Var B : TBuf; I : LongInt;
Begin
  HasConflictMark := False;
  BufInit(B);
  If LoadSmall(Path, B) Then
    For I := 0 To B.N - 8 Do
      If ((I = 0) Or (B.P^[I - 1] = 10)) And
         (BufStrAt(B, I, 7) = '<<<<<<<') Then
      Begin
        HasConflictMark := True; Break;
      End;
  BufFree(B);
End;

{ fichiers .mine et .rN d'un conflit }
Procedure ConflictClean(K : LongInt);
Var SR : TSRec; W, D, N, Nm : String; L : TFlat; I : LongInt; Ok : Boolean;
Begin
  W := WorkPath(Ent^[K].Path);
  FileDel(W + '.mine');
  FlatInit(L);
  D := ParentOf(W); N := NameOf(W);
  Ok := FsFirst(W + '.r*', SR);
  While Ok Do
  Begin
    Nm := SR.Name;
    If (LowStr(Copy(Nm, 1, Length(N) + 2)) = LowStr(N + '.r')) And
       (StrToIntDef(Copy(Nm, Length(N) + 3, 20), -1) >= 0) Then
      I := FlatAdd(L, D + PS + Nm);
    Ok := FsNext(SR);
  End;
  FsClose(SR);
  For I := 0 To L.N - 1 Do FileDel(L.E^[I].Path);
  FlatFree(L);
End;

{ marque l'entree comme resolue }
Procedure Resolve(K : LongInt);
Begin
  ConflictClean(K);
  Ent^[K].State := 'n';
  Ent^[K].MTime := 0;
  EntDirty := True;
End;

{ ajoute au commit le dossier P et ses parents non encore dans le depot }
Procedure NeedDir(Const P : String);
Var K, I : LongInt;
Begin
  If P = '' Then Exit;
  K := EntFind(P);
  If (K >= 0) And (Ent^[K].State <> 'a') Then Exit;
  For I := 0 To COpN - 1 Do
    If (COps^[I].K = CoAddDir) And (COps^[I].Path = RPath(P)) Then Exit;
  NeedDir(ParentP(P));
  I := COpAdd(CoAddDir, RPath(P), -1, '', P);
End;

{ valide les elements coches de Chg ; Msg en UTF-8 }
Function WcCommit(Var Msg : TBuf) : Boolean;
Var I, K, J, St, R : LongInt; P, D, Md5 : String; Gone : TFlat;
Begin
  WcCommit := False;
  COpN := 0;
  If Not RaOpen(WcUrl) Then Exit;
  FlatInit(Gone);
  For I := 0 To Chg.N - 1 Do
  Begin
    If (Chg.E^[I].Flag And FlSel) = 0 Then Continue;
    St := Chg.E^[I].Flag And $FF;
    P := Chg.E^[I].Path;
    K := EntFind(P);
    Case St Of
      StMod, StConf :
      Begin
        If (St = StConf) And HasConflictMark(WorkPath(P)) Then
        Begin
          GitErr := 'le fichier ' + Utf8ToAnsi(P) + ' contient encore des ' +
            'marqueurs de conflit (<<<<<<<) : corrigez-le d''abord';
          FlatFree(Gone); Exit;
        End;
        J := COpAdd(CoModFile, RPath(P), Ent^[K].Rev, WorkPath(P), P);
        { un fichier en conflit sans marqueurs : resolu (non ajoute) }
        If (St = StConf) And (Ent^[K].Md5 = '') Then
          COps^[J].K := CoAddFile;
      End;
      StNew, StUnv :
      Begin
        NeedDir(ParentP(P));
        J := COpAdd(CoAddFile, RPath(P), -1, WorkPath(P), P);
      End;
      StDel, StMiss :
      Begin
        { dossier disparu : supprime en entier }
        D := ParentP(P);
        While (D <> '') And Not DirExist(WorkPath(ParentP(D))) Do
          D := ParentP(D);
        If (D <> '') And Not DirExist(WorkPath(D)) Then
        Begin
          If FlatFind(Gone, D) < 0 Then
          Begin
            J := FlatAdd(Gone, D);
            FlatSort(Gone);
            R := WcRev;
            If (EntFind(D) >= 0) And (Ent^[EntFind(D)].Rev > 0) Then
              R := Ent^[EntFind(D)].Rev;
            J := COpAdd(CoDelete, RPath(D), R, '', D);
          End;
        End
        Else J := COpAdd(CoDelete, RPath(P), Ent^[K].Rev, '', P);
      End;
      StProp :
      Begin
        R := WcRev;
        If (K >= 0) And (Ent^[K].Rev > 0) Then R := Ent^[K].Rev;
        J := COpAdd(CoPropDir, RPath(P), R, 'svn:ignore',
          IgnGet(IgnP, IgnPV, P));
        COps^[J].Md5 := P;
      End;
    End;
  End;
  FlatFree(Gone);
  If COpN = 0 Then
  Begin
    GitErr := 'aucune modification '#224' valider'; Exit;
  End;
  If Not RaCommit(Msg) Then Exit;
  { mise a jour des entrees }
  For I := 0 To COpN - 1 Do
    With COps^[I] Do
    Begin
      { chemin local : Vl (operations de fichiers), Md5 (proprietes) }
      Case K Of
        CoAddDir :
        Begin
          J := EntAdd(Vl, 'd');
          If J >= 0 Then Ent^[J].Rev := -1;
        End;
        CoDelete :
        Begin
          J := EntFind(Vl);
          If J >= 0 Then
          Begin
            If Ent^[J].Kind = 'd' Then EntDelTree(Vl)
            Else EntDel(J);
          End;
          IgnDel(IgnP, IgnPV, Vl);
        End;
        CoPropDir :
        Begin
          P := COps^[I].Md5;
          If COps^[I].Vl <> '' Then IgnSet(IgnB, IgnBV, P, COps^[I].Vl)
          Else IgnDel(IgnB, IgnBV, P);
          IgnDel(IgnP, IgnPV, P);
        End;
        CoAddFile, CoModFile :
        Begin
          J := EntFind(Vl);
          If J < 0 Then J := EntAdd(Vl, 'f');
          If J >= 0 Then
          Begin
            If Ent^[J].State = 'c' Then ConflictClean(J);
            Md5 := COps^[I].Md5;
            MkDirs(MetaPath('pristine'));
            If Not FileExist(PristinePath(Md5)) Then
              If FileCopy(Src, PristinePath(Md5)) Then ;
            Ent^[J].Md5 := Md5;
            Ent^[J].Rev := CNewRev;
            Ent^[J].State := 'n';
            EntStat(J);
          End;
        End;
      End;
    End;
  { dossiers parents : revision inconnue (la prochaine mise a jour les
    relit) }
  For I := 0 To COpN - 1 Do
  Begin
    If COps^[I].K = CoPropDir Then P := COps^[I].Md5
    Else P := ParentP(COps^[I].Vl);
    Repeat
      J := EntFind(P);
      If J >= 0 Then Ent^[J].Rev := -1;
      If P = '' Then Break;
      P := ParentP(P);
    Until False;
  End;
  { si aucune autre revision n'a touche la copie depuis WcRev, toute la
    copie est a la nouvelle revision (comme apres svn update) }
  If (CNewRev > WcRev) And RaLog(RaRel, CNewRev, WcRev + 1, 2, False) Then
    If (HistN = 1) And (Hist^[0].Rev = CNewRev) Then WcRev := CNewRev;
  HistClear;
  EntDirty := True;
  WcSave;
  WcCommit := True;
End;

{ ==================================================================== }
{ Annulation, ajout a svn:ignore, nettoyage                             }
{ ==================================================================== }

{ annule les elements coches de Chg }
Function WcRevert : Boolean;
Var I, K, St : LongInt; P, W : String; Ok : Boolean;
Begin
  Ok := True;
  For I := 0 To Chg.N - 1 Do
  Begin
    If (Chg.E^[I].Flag And FlSel) = 0 Then Continue;
    St := Chg.E^[I].Flag And $FF;
    P := Chg.E^[I].Path;
    W := WorkPath(P);
    K := EntFind(P);
    Case St Of
      StMod, StDel, StMiss, StConf :
        If (K >= 0) And (Ent^[K].Md5 <> '') Then
        Begin
          If St = StConf Then ConflictClean(K);
          MkDirs(ParentOf(W));
          If FileCopy(PristinePath(Ent^[K].Md5), W) Then
          Begin
            Ent^[K].State := 'n';
            EntStat(K);
          End
          Else Ok := False;
        End
        Else If K >= 0 Then
        Begin
          ConflictClean(K);
          FileDel(W); EntDel(K);
        End;
      StNew, StUnv :
      Begin
        If K >= 0 Then EntDel(K);
        FileDel(W);
        If FileExist(W) Then Ok := False;
      End;
      StProp : IgnDel(IgnP, IgnPV, P);
    End;
  End;
  If Not Ok Then GitErr := 'certains fichiers n''ont pas pu '#234'tre ' +
    'r'#233'tablis';
  WcSave;
  WcRevert := Ok;
End;

{ ajoute le nom de P au svn:ignore (a valider) de son dossier }
Procedure WcIgnore(Const P : String);
Var D, S : String;
Begin
  D := ParentP(P);
  If IgnHas(IgnP, D) Then S := IgnGet(IgnP, IgnPV, D)
  Else S := IgnGet(IgnB, IgnBV, D);
  If (S <> '') And (S[Length(S)] <> #10) Then S := S + #10;
  S := S + BaseP(P) + #10;
  IgnSet(IgnP, IgnPV, D, S);
  WcSave;
End;

{ supprime les bases qui ne servent plus }
Procedure WcCleanup;
Var SR : TSRec; L : TFlat; I, K : LongInt; Used : TFlat; Ok : Boolean;
Begin
  FlatInit(L); FlatInit(Used);
  For I := 0 To EntN - 1 Do
    If Ent^[I].Md5 <> '' Then K := FlatAdd(Used, Ent^[I].Md5);
  FlatSort(Used);
  Ok := FsFirst(MetaPath('pristine') + PS + AllFiles, SR);
  While Ok Do
  Begin
    If (Length(SR.Name) = 32) And (FlatFind(Used, LowStr(SR.Name)) < 0) Then
      K := FlatAdd(L, SR.Name);
    Ok := FsNext(SR);
  End;
  FsClose(SR);
  For I := 0 To L.N - 1 Do FileDel(PristinePath(L.E^[I].Path));
  FlatFree(L); FlatFree(Used);
  FileDel(MetaPath('tmp.dl'));
End;

{ ==================================================================== }
{ Branches (trunk, branches/x, tags/x)                                  }
{ ==================================================================== }

Var
  BrBase, BrCur : String;              { projet, branche actuelle }

{ decoupe RaRel/WcRel : base du projet et branche }
Procedure BranchSplit(Const Rel : String);
Var K : LongInt; S : String;
Begin
  BrBase := ''; BrCur := '';
  S := '/' + Rel + '/';
  K := Pos('/trunk/', S);
  If K > 0 Then
  Begin
    BrBase := Copy(S, 2, K - 2); BrCur := 'trunk'; Exit;
  End;
  K := Pos('/branches/', S);
  If K = 0 Then K := Pos('/tags/', S);
  If K > 0 Then
  Begin
    BrBase := Copy(S, 2, K - 2);
    S := Copy(S, K + 1, 255);
    { branches/nom }
    K := Pos('/', S);
    BrCur := Copy(S, 1, K);
    Delete(S, 1, K);
    K := Pos('/', S);
    BrCur := BrCur + Copy(S, 1, K - 1);
    Exit;
  End;
  BrCur := Rel;
End;

{ chemin relatif de l'URL de la copie dans le depot }
Function WcRel : String;
Var R, U : String;
Begin
  R := UrlDec(WcRoot); U := UrlDec(WcUrl);
  If (R <> '') And (Copy(U, 1, Length(R)) = R) Then
  Begin
    U := Copy(U, Length(R) + 1, 255);
    While (U <> '') And (U[1] = '/') Do Delete(U, 1, 1);
    WcRel := U;
  End
  Else WcRel := '';
End;

{ cree la branche Name (copie de la copie de travail) }
Function WcBranch(Const Name : String; Var Msg : TBuf) : Boolean;
Var K : Char; Head : LongInt; B : String;
Begin
  WcBranch := False;
  If Not RaOpen(WcUrl) Then Exit;
  BranchSplit(RaRel);
  If Not RaLatest(Head) Then Exit;
  COpN := 0;
  B := JoinP(BrBase, 'branches');
  If Not RaCheckPath(B, Head, K) Then Exit;
  If K = 'n' Then COpAdd(CoAddDir, B, -1, '', '')
  Else If K <> 'd' Then
  Begin
    GitErr := B + ' n''est pas un dossier'; Exit;
  End;
  If Not RaCheckPath(B + '/' + Name, Head, K) Then Exit;
  If K <> 'n' Then
  Begin
    GitErr := 'la branche ' + Utf8ToAnsi(Name) + ' existe d'#233'j'#224;
    Exit;
  End;
  COpAdd(CoCopyDir, B + '/' + Name, WcRev, RaRel, '');
  WcBranch := RaCommit(Msg);
End;
{ ==================================================================== }
{ Transport d'OS/2 : sockets de TCPIP32.DLL (svn://, http://) et        }
{ TLS32.DLL (https://) ; les appels bloquants liberent le verrou        }
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
Function TlsOpen(S, PHost : LongInt) : LongInt; External 'TLS32' Name 'TLSOPEN';
Function TlsSend(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSSEND';
Function TlsRecv(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSRECV';
Function TlsClose(H : LongInt) : LongInt; External 'TLS32' Name 'TLSCLOSE';
Function TlsError(B, Cb : LongInt) : LongInt; External 'TLS32' Name 'TLSERROR';

Var
  LockSem : LongInt;                   { semaphore d'exclusion }
  LockOn : Boolean;
  LockDepth : LongInt;
  NetReady : Boolean;
  ProxyStr : String;                   { hote:port ou '' }
  NetZ : Array[0..299] Of Byte;
  NetAbort : Boolean;
  { connexion HTTP gardee ouverte (keep-alive) }
  HSock : LongInt;                     { -1 : aucune }
  HTls : Boolean;
  HKey : String;                       { schema://hote:port de HSock }
  HRb : TBuf;                          { octets recus non lus }
  HRp : LongInt;

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

Procedure PutZ(A : LongInt; Const S : String);
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do PByt(A + I - 1)^ := Ord(S[I]);
  PByt(A + Length(S))^ := 0;
End;

Function MemL4(A : LongInt) : LongInt;
Begin
  MemL4 := PLng(A)^;
End;

{ millisecondes depuis le demarrage (QSV_MS_COUNT) }
Function MsCount : LongInt;
Var V : LongInt;
Begin
  V := 0;
  If DosQuerySysInfo(14, 14, LongInt(@V), 4) <> 0 Then V := 0;
  MsCount := V;
End;

Function TcpOpen(Const Host : String; Port : LongInt) : LongInt;
Var A : Array[0..15] Of Byte; S, IP, H, I, R : LongInt;
Begin
  TcpOpen := -1;
  If Not NetReady Then
  Begin
    If sock_init <> 0 Then
    Begin
      GitErr := 'r'#233'seau indisponible (carte r'#233'seau, DHCP : voir ' +
        'IFCONFIG)';
      Exit;
    End;
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
      GitErr := 'ordinateur introuvable : ' + Host; Exit;
    End;
    { hostent d'OS/2 : h_addr_list en +16 }
    IP := MemL4(MemL4(MemL4(H + 16)));
  End;
  S := socket(2, 1, 6);
  If S = -1 Then
  Begin
    GitErr := 'impossible de cr'#233'er un socket'; Exit;
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
    GitErr := 'connexion refus'#233'e : ' + Host + ':' + IStr(Port);
    Dummy0 := soclose(S); Exit;
  End;
  TcpOpen := S;
End;

Function TcpSend(H : LongInt; Var B : TBuf; Ofs, N : LongInt) : Boolean;
Var R : LongInt;
Begin
  TcpSend := False;
  While N > 0 Do
  Begin
    BigUnlock;
    R := send(H, LongInt(@B.P^[Ofs]), MinL(N, 16384), 0);
    BigLock;
    If R <= 0 Then Exit;
    Inc(Ofs, R); Dec(N, R);
  End;
  TcpSend := True;
End;

{ ajoute a B ce qui est recu ; 0 : connexion fermee, -1 : erreur }
Function TcpRecv(H : LongInt; Var B : TBuf) : LongInt;
Var R : LongInt;
Begin
  If NetAbort Then
  Begin
    GitErr := 'op'#233'ration annul'#233'e'; TcpRecv := -1; Exit;
  End;
  BufNeed(B, B.N + 32768);
  If B.N + 32768 > B.Cap Then
  Begin
    GitErr := 'm'#233'moire insuffisante'; TcpRecv := -1; Exit;
  End;
  BigUnlock;
  R := recv(H, LongInt(@B.P^[B.N]), 32768, 0);
  BigLock;
  If R > 0 Then Inc(B.N, R);
  TcpRecv := R;
End;

Procedure TcpClose(H : LongInt);
Begin
  Dummy0 := shutdown(H, 2);
  Dummy0 := soclose(H);
End;

{ ---- HTTP/1.1 sur TCPIP32 et TLS32 (connexion gardee ouverte, proxy
  HTTP_PROXY : URL complete en http://, tunnel CONNECT en https://) ---- }

Procedure HClose;
Begin
  If HSock >= 0 Then
  Begin
    If HTls Then Dummy0 := TlsClose(1);
    TcpClose(HSock);
  End;
  HSock := -1; HTls := False; HKey := '';
  HRb.N := 0; HRp := 0;
End;

Function HSendRaw(A, N : LongInt) : Boolean;
Var R : LongInt;
Begin
  HSendRaw := False;
  While N > 0 Do
  Begin
    BigUnlock;
    If HTls Then R := TlsSend(1, A, MinL(N, 16384))
    Else R := send(HSock, A, MinL(N, 16384), 0);
    BigLock;
    If R <= 0 Then Exit;
    A := A + R; N := N - R;
  End;
  HSendRaw := True;
End;

Function HSendStr(Const S : String) : Boolean;
Var B : Array[0..255] Of Byte; I : LongInt;
Begin
  For I := 1 To Length(S) Do B[I - 1] := Ord(S[I]);
  HSendStr := HSendRaw(LongInt(@B), Length(S));
End;

{ au moins un octet de plus dans HRb (a partir de HRp) ; faux a la fin }
Function HFill : Boolean;
Var R : LongInt;
Begin
  HFill := False;
  If NetAbort Then
  Begin
    GitErr := 'op'#233'ration annul'#233'e'; Exit;
  End;
  If HRp >= HRb.N Then
  Begin
    HRb.N := 0; HRp := 0;
  End;
  BufNeed(HRb, HRb.N + 16384);
  If HRb.N + 16384 > HRb.Cap Then Exit;
  BigUnlock;
  If HTls Then R := TlsRecv(1, LongInt(@HRb.P^[HRb.N]), 16384)
  Else R := recv(HSock, LongInt(@HRb.P^[HRb.N]), 16384, 0);
  BigLock;
  If R <= 0 Then Exit;
  HRb.N := HRb.N + R;
  HFill := True;
End;

{ ligne terminee par LF (sans CR ni LF) ; faux a la fermeture }
Function HLine(Var S : String) : Boolean;
Var C : LongInt;
Begin
  HLine := False;
  S := '';
  Repeat
    If HRp >= HRb.N Then If Not HFill Then Exit;
    C := HRb.P^[HRp]; Inc(HRp);
    If C = 10 Then
    Begin
      HLine := True; Exit;
    End;
    If (C <> 13) And (Length(S) < 255) Then S := S + Chr(C);
  Until False;
End;

{ hote du reseau local : sans proxy (comme la liste de contournement de
  Pasdows : localhost, 127.*, 10.*, 192.168.*, noms sans point) }
Function NoProxy(Const H : String) : Boolean;
Begin
  NoProxy := (LowStr(H) = 'localhost') Or (Copy(H, 1, 4) = '127.') Or
    (Copy(H, 1, 3) = '10.') Or (Copy(H, 1, 8) = '192.168.') Or
    (Pos('.', H) = 0);
End;

{ connexion a l'hote de l'URL decoupee (UrlScheme, UrlHost, UrlPort) }
Function HConnect(Px : Boolean; Const PxHost : String; PxPort : LongInt)
  : Boolean;
Var L : String; St, K : LongInt; B : Array[0..259] Of Byte;
Begin
  HConnect := False;
  HClose;
  If Px Then HSock := TcpOpen(PxHost, PxPort)
  Else HSock := TcpOpen(UrlHost, UrlPort);
  If HSock < 0 Then
  Begin
    HSock := -1; Exit;
  End;
  HRb.N := 0; HRp := 0;
  If UrlScheme = 'https' Then
  Begin
    If Px Then
    Begin
      If Not HSendStr('CONNECT ' + UrlHost + ':' + IStr(UrlPort) +
        ' HTTP/1.1'#13#10'Host: ' + UrlHost + ':' + IStr(UrlPort) +
        #13#10#13#10) Then
      Begin
        GitErr := 'le proxy ne r'#233'pond pas'; HClose; Exit;
      End;
      St := 0;
      Repeat
        If Not HLine(L) Then
        Begin
          GitErr := 'le proxy a ferm'#233' la connexion'; HClose; Exit;
        End;
        If (St = 0) And (L <> '') Then
        Begin
          K := Pos(' ', L);
          If K > 0 Then St := StrToIntDef(Copy(L, K + 1, 3), 0);
        End;
      Until L = '';
      If (St < 200) Or (St > 299) Then
      Begin
        GitErr := 'le proxy refuse le tunnel vers ' + UrlHost + ' (code ' +
          IStr(St) + ')';
        HClose; Exit;
      End;
    End;
    PutZ(LongInt(@B), UrlHost);
    BigUnlock;
    K := TlsOpen(HSock, LongInt(@B));
    BigLock;
    If K <> 1 Then
    Begin
      Dummy0 := TlsError(LongInt(@B), 250);
      L := '';
      K := 0;
      While (K < 200) And (B[K] <> 0) Do
      Begin
        L := L + Chr(B[K]); Inc(K);
      End;
      GitErr := 'connexion s'#233'curis'#233'e impossible avec ' + UrlHost +
        ' : ' + L;
      TcpClose(HSock); HSock := -1; Exit;
    End;
    HTls := True;
  End;
  HKey := UrlScheme + '://' + LowStr(UrlHost) + ':' + IStr(UrlPort);
  HConnect := True;
End;

{ corps recu : vers Resp, ou vers le fichier HttpSinkH (reponse 200) }
Function HSink(Status, A, N : LongInt; Var Resp : TBuf) : Boolean;
Begin
  HSink := True;
  If N <= 0 Then Exit;
  If (HttpSinkH >= 0) And (Status = 200) Then
  Begin
    Md5Ptr(HttpSinkMd5, PBytes(A), 0, N);
    If Not FWrite(HttpSinkH, PBytes(A), N) Then
    Begin
      GitErr := #233'criture impossible (disque plein ?)'; HSink := False;
      Exit;
    End;
    HttpSinkN := HttpSinkN + N;
  End
  Else
  Begin
    BufMem(Resp, PBytes(A)^, N);
    If GitOom Then
    Begin
      GitErr := 'm'#233'moire insuffisante'; HSink := False;
    End;
  End;
End;

Function HttpReq(Const Method, Url, Hdr : String; Var Body, Resp : TBuf;
  Var Status : LongInt) : Boolean;
Var Try0, K, N, ClenV, Chunk, Last, PxPort : LongInt; Px, Reused, Chunked,
    CloseC, Ok, NoBody : Boolean; L, HN, HV, Req, Key, PxHost : String;
Begin
  HttpReq := False;
  Status := 0;
  Resp.N := 0;
  If Not UrlSplit(Url) Then
  Begin
    GitErr := 'URL non valable : ' + Url; Exit;
  End;
  { proxy (Options ou HTTP_PROXY) : hote:port }
  Px := False; PxHost := ''; PxPort := 0;
  If (ProxyStr <> '') And Not NoProxy(UrlHost) Then
  Begin
    L := ProxyStr;
    K := Pos('://', L);
    If K > 0 Then Delete(L, 1, K + 2);
    While (L <> '') And (L[Length(L)] = '/') Do Delete(L, Length(L), 1);
    K := Pos(':', L);
    If K > 0 Then
    Begin
      PxHost := Copy(L, 1, K - 1);
      PxPort := StrToIntDef(Copy(L, K + 1, 6), 0);
    End
    Else
    Begin
      PxHost := L; PxPort := 8080;
    End;
    Px := (PxHost <> '') And (PxPort > 0);
  End;
  Key := UrlScheme + '://' + LowStr(UrlHost) + ':' + IStr(UrlPort);
  For Try0 := 1 To 2 Do
  Begin
    Reused := (HSock >= 0) And (HKey = Key);
    If Not Reused Then
      If Not HConnect(Px, PxHost, PxPort) Then Exit;
    { chaque morceau tient dans une chaine de 255 caracteres }
    Ok := HSendStr(Method + ' ');
    If Ok Then
      If Px And (UrlScheme = 'http') Then Ok := HSendStr(Url)
      Else Ok := HSendStr(UrlPath);
    Req := 'Host: ' + UrlHost;
    If ((UrlScheme = 'https') And (UrlPort <> 443)) Or
       ((UrlScheme = 'http') And (UrlPort <> 80)) Then
      Req := Req + ':' + IStr(UrlPort);
    If Ok Then Ok := HSendStr(' HTTP/1.1'#13#10 + Req + #13#10);
    If Ok Then Ok := HSendStr('User-Agent: ' + AgentName + #13#10 +
      'Accept-Encoding: identity'#13#10'Connection: keep-alive'#13#10 +
      'Content-Length: ' + IStr(Body.N) + #13#10);
    If Ok And (Hdr <> '') Then Ok := HSendStr(Hdr);
    If Ok Then Ok := HSendStr(#13#10);
    If Ok And (Body.N > 0) Then Ok := HSendRaw(LongInt(@Body.P^[0]), Body.N);
    { ligne d'etat (les reponses 100 Continue sont passees) }
    Repeat
      If Ok Then Ok := HLine(L);
      If Ok And (L = '') Then Continue;
      If Ok Then
      Begin
        K := Pos(' ', L);
        If K > 0 Then Status := StrToIntDef(Copy(L, K + 1, 3), 0);
        If (Status >= 100) And (Status < 200) Then
          Repeat
            Ok := HLine(L);
          Until Not Ok Or (L = '')
        Else Break;
      End;
    Until Not Ok;
    If Not Ok Then
    Begin
      HClose;
      If NetAbort Then Exit;
      { connexion gardee mais fermee par le serveur : une seconde fois }
      If Reused And (Try0 = 1) Then Continue;
      If GitErr = '' Then GitErr := 'le serveur ' + UrlHost +
        ' a ferm'#233' la connexion';
      Exit;
    End;
    { en-tetes }
    HttpHdrs.N := 0;
    ClenV := -1; Chunked := False; CloseC := False;
    Repeat
      If Not HLine(L) Then
      Begin
        HClose;
        GitErr := 'r'#233'ponse incompl'#232'te de ' + UrlHost; Exit;
      End;
      BufStr(HttpHdrs, L); BufStr(HttpHdrs, #13#10);
      K := Pos(':', L);
      If K > 0 Then
      Begin
        HN := LowStr(TrimS(Copy(L, 1, K - 1)));
        HV := TrimS(Copy(L, K + 1, 255));
        If HN = 'content-length' Then ClenV := StrToIntDef(HV, -1)
        Else If (HN = 'transfer-encoding') And (Pos('chunked', LowStr(HV)) >
          0) Then Chunked := True
        Else If (HN = 'connection') And (Pos('close', LowStr(HV)) > 0) Then
          CloseC := True;
      End;
    Until L = '';
    NoBody := (Method = 'HEAD') Or (Status = 204) Or (Status = 304);
    { corps }
    Last := 0;
    Ok := True;
    If NoBody Then K := 0
    Else If Chunked Then
    Begin
      Repeat
        If Not HLine(L) Then
        Begin
          Ok := False; Break;
        End;
        Chunk := 0;
        For K := 1 To Length(L) Do
          If HexVal(L[K]) >= 0 Then Chunk := Chunk * 16 + HexVal(L[K])
          Else Break;
        If Chunk = 0 Then
        Begin
          Repeat
          Until Not HLine(L) Or (L = '');
          Break;
        End;
        While Ok And (Chunk > 0) Do
        Begin
          If HRp >= HRb.N Then If Not HFill Then
          Begin
            Ok := False; Break;
          End;
          N := MinL(Chunk, HRb.N - HRp);
          Ok := HSink(Status, LongInt(@HRb.P^[HRp]), N, Resp);
          HRp := HRp + N; Chunk := Chunk - N;
        End;
        If Not Ok Then Break;
        If Not HLine(L) Then
        Begin
          Ok := False; Break;
        End;
        K := Resp.N + HttpSinkN;
        If K - Last >= 65536 Then
        Begin
          GitProgress('R'#233'ception', K, 0); Last := K;
        End;
      Until False;
    End
    Else
    Begin
      K := 0;
      While (ClenV < 0) Or (K < ClenV) Do
      Begin
        If HRp >= HRb.N Then If Not HFill Then
        Begin
          If ClenV >= 0 Then Ok := False;
          CloseC := True;
          Break;
        End;
        N := HRb.N - HRp;
        If ClenV >= 0 Then N := MinL(N, ClenV - K);
        Ok := HSink(Status, LongInt(@HRb.P^[HRp]), N, Resp);
        If Not Ok Then Break;
        HRp := HRp + N; K := K + N;
        If K - Last >= 65536 Then
        Begin
          GitProgress('R'#233'ception', K, 0); Last := K;
        End;
      End;
    End;
    If CloseC Or Not Ok Then HClose;
    If Not Ok Then
    Begin
      If GitErr = '' Then GitErr := 'transfert incomplet depuis ' + UrlHost;
      Status := 0;
      Exit;
    End;
    HttpReq := Status > 0;
    Exit;
  End;
End;

{ ==================================================================== }
{ Fichiers d'OS/2 (DosOpen, DosRead, DosWrite, DosSetFilePtr)           }
{ ==================================================================== }

Function FOpenR(Const P : String) : LongInt;
Var H, Act : LongInt;
Begin
  PathZ(P);
  H := 0; Act := 0;
  If DosOpen(LongInt(@FZ), LongInt(@H), LongInt(@Act), 0, 0, $01, $40, 0) <> 0
  Then H := -1;
  FOpenR := H;
End;

Function FCreate(Const P : String) : LongInt;
Var H, Act : LongInt;
Begin
  PathZ(P);
  H := 0; Act := 0;
  If DosOpen(LongInt(@FZ), LongInt(@H), LongInt(@Act), 0, 0, $12, $22, 0) <> 0
  Then H := -1;
  FCreate := H;
End;

Function FReadAt(H, Pos : LongInt; Q : PBytes; N : LongInt) : LongInt;
Var R, Act : LongInt;
Begin
  FReadAt := 0;
  Act := 0;
  Breathe(N + 1024);
  If DosSetFilePtr(H, Pos, 0, LongInt(@Act)) <> 0 Then Exit;
  R := 0;
  If DosRead(H, LongInt(Q), N, LongInt(@R)) <> 0 Then Exit;
  FReadAt := R;
End;

Function FWrite(H : LongInt; Q : PBytes; N : LongInt) : Boolean;
Var W : LongInt;
Begin
  W := 0;
  If N <= 0 Then
  Begin
    FWrite := True; Exit;
  End;
  Breathe(N + 1024);
  FWrite := (DosWrite(H, LongInt(Q), N, LongInt(@W)) = 0) And (W = N);
End;

Function FSize(H : LongInt) : LongInt;
Var Fs : TFs3;
Begin
  FillChar(Fs, 32, 0);
  If DosQueryFileInfo(H, 1, LongInt(@Fs), 24) <> 0 Then FSize := 0
  Else FSize := Le32(Fs, 12);
End;

Procedure FClose(H : LongInt);
Begin
  If H >= 0 Then Dummy0 := DosClose(H);
End;

Function FRmDir(Const P : String) : Boolean;
Begin
  PathZ(P);
  FRmDir := DosDeleteDir(LongInt(@FZ)) = 0;
End;
{ ==================================================================== }
{ Utilitaires de l'interface (Presentation Manager)                     }
{ ==================================================================== }

Const
  CW = 8;                              { police de PM : 8 x 16 }
  SCW = 6;                             { petite police : 6 x 16 }
  IniApp = 'PM_SvnClient';             { OS2.INI : reglages }
  IniAuth = 'PM_SvnClient_Identifiants';

Var
  Hab, Hmq, MainWnd, MainFrame, Dummy : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  Qmsg : Array[0..7] Of LongInt;
  AppExeDir : String;
  ScrW, ScrH : LongInt;
  DcH, CurFont : LongInt;              { fenetre peinte : hauteur, police }
  CtlKind : Array[0..255] Of Byte;     { 1 bouton, 2 saisie, 3 liste }
  TestMode : Boolean;

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

Function Z(Const S : String) : LongInt;
Begin
  PutZ(LongInt(@NameZ), S);
  Z := LongInt(@NameZ);
End;

Function Z2(Const S : String) : LongInt;
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

Function S16(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V >= $8000 Then V := V - $10000;
  S16 := V;
End;

{ boite de message : drapeaux et resultats de Pasdows traduits pour
  WinMessageBox ; #13#10 = nouvelle ligne }
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

Function Ask(Const Text, Cap : String; Fl : LongInt) : LongInt;
Var A, B : Array[0..511] Of Byte; K, N, D : LongInt; S : String;
Begin
  S := Disp(Text);
  N := 0;
  For K := 1 To Length(S) Do
    If S[K] <> #13 Then
    Begin
      A[N] := Ord(S[K]); Inc(N);
    End;
  A[N] := 0;
  PutZ(LongInt(@B[0]), Disp(Cap));
  D := LockDepthRelease;
  Ask := WinMessageBox(HWND_DESKTOP, MainFrame, LongInt(@A[0]),
    LongInt(@B[0]), 0, MbFlags(Fl));
  LockDepthRestore(D);
End;

Procedure ErrBox(Const S : String);
Begin
  Dummy := Ask(S, 'Client SVN', MB_OK Or MB_ICONERROR);
End;

{ couleur de Windows ($00BBGGRR) -> RVB de PM ($00RRGGBB) }
Function Rgb(C : LongInt) : LongInt;
Begin
  { le gris des boutons de Windows 95 est celui de PM (CLR_PALEGRAY) }
  If C = ClrFace Then Rgb := $AAAAAA
  Else Rgb := ((C And $FF) Shl 16) Or (C And $FF00) Or ((C Shr 16) And $FF);
End;

{ debut et fin du dessin d'une fenetre (couleurs RVB, police 8 x 16) }
Function PaintBegin(H : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Hps : LongInt;
Begin
  Rc[1] := 0; Rc[3] := 0;
  Dummy0 := WinQueryWindowRect(H, LongInt(@Rc));
  DcH := Rc[3] - Rc[1];
  Hps := WinBeginPaint(H, 0, 0);
  Dummy0 := GpiCreateLogColorTable(Hps, 0, 3, 0, 0, 0);
  CurFont := 0;
  PaintBegin := Hps;
End;

Procedure PaintEnd(Dc : LongInt);
Begin
  Dummy0 := WinEndPaint(Dc);
End;

{ police : 1 petite (6 x 16), 2 celle de l'ecran (8 x 16) }
Procedure SelFont(Dc, F : LongInt);
Var B : Array[0..1] Of LongInt;
Begin
  If F = CurFont Then Exit;
  CurFont := F;
  If F = 1 Then B[0] := 6 * 65536 Else B[0] := 8 * 65536;
  B[1] := 16 * 65536;
  Dummy0 := GpiSetCharBox(Dc, LongInt(@B[0]));
End;

{ dessin : coordonnees de Pasdows (Y vers le bas) dans la fenetre peinte
  de hauteur DcH }
Procedure Bar(Dc, X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  Dummy0 := GpiSetColor(Dc, Rgb(C));
  P[0] := X1; P[1] := DcH - Y2;
  Dummy0 := GpiMove(Dc, LongInt(@P[0]));
  P[0] := X2 - 1; P[1] := DcH - Y1 - 1;
  Dummy0 := GpiBox(Dc, 3, LongInt(@P[0]), 0, 0);
End;

{ texte, fond transparent ; Y : haut de la cellule de 16 points }
Procedure TxtF(Dc, X, Y : LongInt; Const S : String; Fg, F : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If S = '' Then Exit;
  SelFont(Dc, F);
  PutZ(LongInt(@TxtBuf), Disp(S));
  Dummy0 := GpiSetColor(Dc, Rgb(Fg));
  P[0] := X; P[1] := DcH - Y - 12;
  Dummy0 := GpiCharStringAt(Dc, LongInt(@P), Length(S), LongInt(@TxtBuf));
End;

Procedure Txt(Dc, X, Y : LongInt; Const S : String; Fg : LongInt);
Begin
  TxtF(Dc, X, Y, S, Fg, 2);
End;

{ S coupe pour tenir dans W points (... a la fin), caracteres de Cw }
Function FitW(S : String; W, Cw0 : LongInt) : String;
Var N : LongInt;
Begin
  N := W Div Cw0;
  If N < 1 Then
  Begin
    FitW := ''; Exit;
  End;
  If Length(S) > N Then
  Begin
    If N > 3 Then S := Copy(S, 1, N - 3) + '...' Else S := Copy(S, 1, N);
  End;
  FitW := S;
End;

Function Fit(S : String; W : LongInt) : String;
Begin
  Fit := FitW(S, W, CW);
End;

{ cadre en relief (X2, Y2 exclus) : Up bouton, sinon creux }
Procedure Bevel(Dc, X1, Y1, X2, Y2 : LongInt; Up : Boolean);
Var L, D : LongInt;
Begin
  If Up Then
  Begin
    L := ClrHi; D := ClrDark;
  End
  Else
  Begin
    L := ClrShadow; D := ClrHi;
  End;
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
  If Up Then
  Begin
    L := ClrHi; D := ClrShadow;
  End
  Else
  Begin
    L := ClrShadow; D := ClrHi;
  End;
  Bar(Dc, X1, Y1, X2, Y1 + 1, L); Bar(Dc, X1, Y1, X1 + 1, Y2, L);
  Bar(Dc, X1, Y2 - 1, X2, Y2, D); Bar(Dc, X2 - 1, Y1, X2, Y2, D);
End;

Procedure RegClass(Const Name : String; Proc : LongInt);
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

Procedure Place(H, X, Y, W, Hh : LongInt);
Var Ph : LongInt;
Begin
  If H = 0 Then Exit;
  Ph := WinHt(WinQueryWindow(H, QW_PARENT));
  Dummy0 := WinSetWindowPos(H, 0, X, Ph - Y - Hh, MaxL(W, 1), MaxL(Hh, 1),
    SWP_MOVE Or SWP_SIZE);
  Dummy0 := WinInvalidateRect(H, 0, 1);
End;

Procedure Show(H : LongInt; On : Boolean);
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

{ pointeur de la souris : SPTR_ARROW, SPTR_WAIT }
Procedure SetPtr(Id : LongInt);
Var P : LongInt;
Begin
  If TestMode Then Exit;
  P := WinQuerySysPointer(HWND_DESKTOP, Id, 0);
  If P <> 0 Then Dummy0 := WinSetPointer(HWND_DESKTOP, P);
End;

{ barres de defilement de PM : position Pos de 0 a Max, Vis visibles }
Procedure SbSet(Sb, Pos, Max, Vis : LongInt);
Begin
  If Sb = 0 Then Exit;
  Dummy0 := WinSendMsg(Sb, PM_SBM_SETSCROLLBAR, Pos, Max Shl 16);
  Dummy0 := WinSendMsg(Sb, PM_SBM_SETTHUMBSIZE, MaxL(1, Vis) Or
    ((Max + Vis) Shl 16), 0);
  Dummy0 := WinEnableWindow(Sb, Ord(Max > 0));
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
Function Ctl(P : LongInt; Const Cls, T : String; Style, X, Y, W, H,
  Id : LongInt) : LongInt;
Var R, C, S, K, Ph : LongInt;
Begin
  K := 0;
  S := PM_WS_VISIBLE;
  If (Style And WS_TABSTOP) <> 0 Then S := S Or PM_WS_TABSTOP;
  If (Style And WS_GROUP) <> 0 Then S := S Or PM_WS_GROUP;
  If Cls = 'EDIT' Then
  Begin
    If (Style And ES_MULTILINE) <> 0 Then
    Begin
      C := WC_MLE; K := 2;
      S := S Or PM_MLS_BORDER Or PM_MLS_VSCROLL Or PM_MLS_WORDWRAP;
    End
    Else
    Begin
      C := WC_ENTRYFIELD; K := 2;
      S := S Or PM_ES_AUTOSCROLL Or PM_ES_MARGIN;
      If (Style And ES_PASSWORD) <> 0 Then S := S Or PM_ES_UNREADABLE;
      { la marge de PM est dans le rectangle : un point de chaque cote }
      X := X + 2; W := W - 4; Y := Y + 1; H := H - 2;
    End;
  End
  Else If Cls = 'LISTBOX' Then
  Begin
    C := WC_LISTBOX; K := 3;
  End
  Else If Cls = 'STATIC' Then
  Begin
    C := WC_STATIC;
    S := S Or PM_SS_TEXT Or PM_DT_VCENTER;
    Y := Y - 1; H := MaxL(H, 16);
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
    If ((Style And 15) = BS_AUTOCHECKBOX) Or
       ((Style And 15) = BS_AUTORADIOBUTTON) Then H := MaxL(H, 18);
  End;
  Ph := WinHt(P);
  { HWND_BOTTOM : l'ordre de tabulation suit l'ordre de creation }
  R := WinCreateWindow(P, C, Z(Disp(T)), S, X, Ph - Y - H, W, H, P,
    HWND_BOTTOM, Id, 0, 0);
  If (R <> 0) And ((C = WC_STATIC) Or ((C = WC_BUTTON) And (K = 1) And
     ((S And 7) <> 0))) Then GrayCtl(R);
  If (R <> 0) And (C = WC_ENTRYFIELD) Then
    Dummy0 := WinSendMsg(R, PM_EM_SETTEXTLIMIT, 255, 0);
  If (R <> 0) And (C = WC_MLE) Then
    Dummy0 := WinSendMsg(R, PM_MLM_SETTEXTLIMIT, 255, 0);
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
Procedure SetText(H : LongInt; Const S : String);
Begin
  If H = 0 Then Exit;
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
  avec WinPopupMenu (les commandes arrivent en WM_COMMAND). }
Const
  MaxMn = 48; MaxMi = 500;

Var
  MnN, MiN, MnBase : LongInt;
  MnLive : Array[1..MaxMn] Of Boolean;
  MiMenu, MiKind, MiId, MiAttr, MiSub : Array[0..MaxMi - 1] Of LongInt;
  MiText : Array[0..MaxMi - 1] Of String[90];
  MnT : Array[0..16383] Of Byte;
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

Procedure MAdd(M, Kind, Id : LongInt; Const S : String; Sub : LongInt);
Var T : String;
Begin
  If (MiN >= MaxMi) Or (M < 1) Then Exit;
  MiMenu[MiN] := M; MiKind[MiN] := Kind; MiId[MiN] := Id; MiAttr[MiN] := 0;
  { tabulation : colonne des raccourcis de PM }
  T := Copy(Disp(S), 1, 90);
  MiText[MiN] := T; MiSub[MiN] := Sub;
  Inc(MiN);
End;

{ menus : ~ = lettre soulignee (comme PM) ; Id 0 : separateur }
Procedure MItem(M, Id : LongInt; Const S : String);
Begin
  If Id = 0 Then MAdd(M, 1, 0, '', 0) Else MAdd(M, 0, Id, S, 0);
End;

Procedure MSub(Bar0, P : LongInt; Const S : String);
Begin
  MAdd(Bar0, 2, 0, S, P);
End;

Procedure MAttr(M, Id, Mask : LongInt; On : Boolean);
Var I : LongInt;
Begin
  For I := 0 To MiN - 1 Do
    If (MiMenu[I] = M) And (MiId[I] = Id) And (MiKind[I] = 0) Then
      If On Then MiAttr[I] := MiAttr[I] Or Mask
      Else MiAttr[I] := MiAttr[I] And Not Mask;
  If (M >= 1) And (M <= MaxMn) Then
    If MnLive[M] And (MenuHw <> 0) Then
    Begin
      If On Then Dummy0 := WinSendMsg(MenuHw, PM_MM_SETITEMATTR, Id Or
        $10000, Mask Or (Mask Shl 16))
      Else Dummy0 := WinSendMsg(MenuHw, PM_MM_SETITEMATTR, Id Or $10000,
        Mask);
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
  If MnLen < 16383 Then
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

{ menu contextuel M au point (X, Y) de l'ecran (Y vers le bas) }
Procedure TrackPopupMenu(M, X, Y : LongInt);
Var I, J : LongInt;
Begin
  MnLen := 0;
  MBuild(M);
  If PopHw <> 0 Then Dummy0 := WinDestroyWindow(PopHw);
  PopHw := WinCreateMenu(HWND_DESKTOP, LongInt(@MnT));
  If PopHw <> 0 Then Dummy0 := WinPopupMenu(HWND_DESKTOP, MainWnd, PopHw, X,
    ScrH - 1 - Y, 0, 0);
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

Procedure CopyToClip(Const S : String);
Begin
  PutZ(LongInt(@TxtBuf), Disp(S));
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy0 := WinEmptyClipbrd(Hab);
    Dummy0 := WinSetClipbrdData(Hab, LongInt(@TxtBuf), 1, $400);
    Dummy0 := WinCloseClipbrd(Hab);
  End;
End;

{ ---- reglages (OS2.INI, comme le Bureau a distance) ---- }

Function IniGet(Const Sect, Key, Def : String) : String;
Var B : Array[0..299] Of Byte; A : String;
Begin
  If Sect = 'Identifiants' Then A := IniAuth Else A := IniApp;
  B[0] := 0;
  If PrfQueryProfileString(-1, Z(A), Z2(Sect + '.' + Key), 0, LongInt(@B),
    290) <= 0 Then B[0] := 0;
  If B[0] = 0 Then IniGet := Def Else IniGet := GetZ(LongInt(@B));
End;

Procedure IniSet(Const Sect, Key, V : String);
Var B : Array[0..299] Of Byte; A : String;
Begin
  If Sect = 'Identifiants' Then A := IniAuth Else A := IniApp;
  PutZ(LongInt(@B), V);
  If V = '' Then
    Dummy0 := PrfWriteProfileString(-1, Z(A), Z2(Sect + '.' + Key), 0)
  Else Dummy0 := PrfWriteProfileString(-1, Z(A), Z2(Sect + '.' + Key),
    LongInt(@B));
End;

{ ecriture possible sur le lecteur D (pas un CD-ROM) }
Function DrvWritable(D : Char) : Boolean;
Var B : Array[0..63] Of Byte; Cb, N : LongInt; Fs : String;
Begin
  DrvWritable := False;
  Cb := 64;
  PutZ(LongInt(@NameZ2), D + ':');
  If DosQueryFSAttach(LongInt(@NameZ2), 0, 1, LongInt(@B), LongInt(@Cb)) <> 0
  Then Exit;
  N := B[2] Or (B[3] Shl 8);
  Fs := UpStr(GetZ(LongInt(@B) + 8 + N + 1));
  DrvWritable := (Fs <> 'CDFS') And (Fs <> 'ISO9660') And (Fs <> 'UDF');
End;

{ dossier des programmes (celui de COMSPEC) et dossier des copies de
  travail par defaut : C:\Subversion, D:\Subversion quand C: est en
  lecture seule (demarrage du CD-ROM) }
Var
  DefRoot : String;

Procedure FindAppDir;
Var P : LongInt;
Begin
  AppExeDir := 'C:\';
  P := 0;
  If DosScanEnv(Z2('COMSPEC'), LongInt(@P)) = 0 Then
    If P <> 0 Then
    Begin
      AppExeDir := GetZ(P);
      While (AppExeDir <> '') And (AppExeDir[Length(AppExeDir)] <> '\') Do
        Delete(AppExeDir, Length(AppExeDir), 1);
      If AppExeDir = '' Then AppExeDir := 'C:\';
    End;
  If DrvWritable('C') Then DefRoot := 'C:\Subversion'
  Else DefRoot := 'D:\Subversion';
End;

{ proxy du systeme : SET HTTP_PROXY=hote:port }
Function EnvProxy : String;
Var P : LongInt;
Begin
  EnvProxy := '';
  P := 0;
  If DosScanEnv(Z2('HTTP_PROXY'), LongInt(@P)) = 0 Then
    If P <> 0 Then EnvProxy := TrimS(GetZ(P));
End;

{ WM_VSCROLL / WM_HSCROLL de PM (mp2 : position, commande) -> code de
  Pasdows (SB_LINEUP...) + position Shl 16 }
Function VsCode(Mp2 : LongInt) : LongInt;
Var C, P : LongInt;
Begin
  P := Mp2 And $FFFF;
  Case (Mp2 Shr 16) And $FFFF Of
    1 : C := SB_LINEUP;
    2 : C := SB_LINEDOWN;
    3 : C := SB_PAGEUP;
    4 : C := SB_PAGEDOWN;
    5 : C := SB_THUMBTRACK;
    6 : C := SB_THUMBPOSITION;
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
    If (V >= PM_VK_F1) And (V <= PM_VK_F1 + 11) Then VkOf := $70 + V - PM_VK_F1
    Else VkOf := 0;
  End;
End;

{ ---- programmes d'OS/2-0 (Explorateur, Invite de commandes, Bloc-notes)
  ---- }

Function AppPath(Const N : String) : String;
Begin
  If FileExist('C:\' + N) Then AppPath := 'C:\' + N
  Else If FileExist(AppExeDir + N) Then AppPath := AppExeDir + N
  Else AppPath := '';
End;

Function RunPm(Const P, Params : String) : Boolean;
Var Res : Array[0..1] Of LongInt; Fail : Array[0..63] Of Byte; Rc : LongInt;
    Pd, Ad : String;
Begin
  Pd := Disp(P); Ad := Disp(Params);
  PutZ(LongInt(@TxtBuf), Pd);
  PutZ(LongInt(@TxtBuf) + Length(Pd) + 1, Ad);
  TxtBuf[Length(Pd) + Length(Ad) + 2] := 0;
  PutZ(LongInt(@NameZ2), Pd);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@Fail), 64, 4, LongInt(@TxtBuf), 0, LongInt(@Res),
    LongInt(@NameZ2));
  RunPm := Rc = 0;
End;

{ ouvre un fichier local avec l'application d'OS/2-0 de son type }
Procedure OpenLocal(P : String);
Var X, A : String; I : LongInt;
Begin
  X := '';
  I := Length(P);
  While (I > 0) And (P[I] <> '.') And (P[I] <> '\') Do Dec(I);
  If (I > 0) And (P[I] = '.') Then X := UpStr(Copy(P, I + 1, 10));
  A := '';
  If (X = 'HTM') Or (X = 'HTML') Then A := AppPath('BROWSER.EXE')
  Else If (X = 'BMP') Or (X = 'PCX') Or (X = 'GIF') Or (X = 'PNG') Or
          (X = 'JPG') Or (X = 'ICO') Then A := AppPath('PAINT.EXE')
  Else If (X = 'DOC') Or (X = 'DOCX') Or (X = 'PDF') Then
    A := AppPath('WORDIUM.EXE')
  Else If (X = 'XLS') Or (X = 'XLSX') Or (X = 'XLC') Then
    A := AppPath('EXCELSIO.EXE')
  Else
  Begin
    A := AppPath('NOTEPAD.EXE');
    If A = '' Then A := AppPath('PASDEV.EXE');
  End;
  If Pos(' ', P) > 0 Then P := '"' + P + '"';
  If (A = '') Or Not RunPm(A, P) Then
    ErrBox('Aucune application ne peut ouvrir ce fichier :'#13#10 + P);
End;

Function JoinDirS(Const D, N : String) : String;
Begin
  If (D <> '') And (D[Length(D)] = '\') Then JoinDirS := D + N
  Else JoinDirS := D + '\' + N;
End;
{ ==================================================================== }
{ Etat de l'application, copies de travail, operations en arriere-plan  }
{ ==================================================================== }

Const
  MaxRepo = 30;
  OpNone = 0; OpCheckout = 1; OpUpdate = 2; OpCommit = 3; OpLog = 4;
  OpSwitch = 5; OpBranch = 6;
  VwChanges = 0; VwHistory = 1;
  HistMax = 200;

Var
  RepoN, RepoCur : LongInt;
  RepoPath : Array[0..MaxRepo - 1] Of String[200];
  CheckRoot : String;
  View : LongInt;
  ChgSel, HistSel, FileSel : LongInt;
  HFiles : TFlat;                      { chemins modifies d'une revision }
  HHead : LongInt;                     { derniere revision du depot }
  Incoming : LongInt;                  { revisions plus recentes }
  LogOk : Boolean;
  LastCheck : LongInt;
  Busy : Boolean;
  Op : LongInt;
  OpOk : Boolean;
  OpUrl, OpDir, OpName : String;
  OpMsg : TBuf;
  WorkTid, ProgTick : LongInt;
  ProgTxt : String;
  ProgDone, ProgTotal : LongInt;
  StatusTxt : String;
  CredHost, CredUser, CredPass : String;
  DiffTitle : String;
  DiffMode : LongInt;                  { 0 vide, 1 texte, 2 binaire,
                                         3 trop grand, 5 dossier,
                                         6 erreur }

Procedure InvalidateStatus; Forward;
Procedure PaintNow; Forward;

Function SizeTxt(V : LongInt) : String;
Begin
  If V < 1024 Then SizeTxt := IStr(V) + ' o'
  Else If V < 1048576 Then SizeTxt := IStr(V Div 1024) + ' Ko'
  Else SizeTxt := IStr(V Div 1048576) + ',' + IStr((V Mod 1048576) * 10 Div
    1048576) + ' Mo';
End;

{ identifiant du fil courant (TIB2 : tib2_ultid) }
Function CurTid : LongInt;
Var PTib, PPib : LongInt;
Begin
  PTib := 0; PPib := 0;
  Dummy0 := DosGetInfoBlocks(LongInt(@PTib), LongInt(@PPib));
  CurTid := 0;
  If PTib <> 0 Then If MemL4(PTib + 12) <> 0 Then
    CurTid := MemL4(MemL4(PTib + 12));
End;

Procedure GitProgress(Const What : String; Done, Total : LongInt);
Var T, D : LongInt;
Begin
  ProgTxt := What; ProgDone := Done; ProgTotal := Total;
  If TestMode Then Exit;
  T := MsCount;
  If (WorkTid <> 0) And (CurTid = WorkTid) Then
  Begin
    If T - ProgTick > 150 Then
    Begin
      ProgTick := T;
      Dummy0 := WinPostMsg(MainWnd, WM_GITPROG, 0, 0);
      { le semaphore n'est pas equitable : laisser l'interface peindre }
      D := LockDepthRelease;
      Dummy0 := DosSleep(10);
      LockDepthRestore(D);
    End;
  End
  Else If T - ProgTick > 250 Then
  Begin
    ProgTick := T;
    PaintNow;
  End;
End;

Function ProgLine : String;
Var S : String;
Begin
  S := ProgTxt;
  If ProgTotal > 0 Then
    S := S + ' : ' + IStr((ProgDone * 100) Div MaxL(ProgTotal, 1)) + ' % (' +
      IStr(ProgDone) + '/' + IStr(ProgTotal) + ')'
  Else If (ProgDone > 0) And (Pos('ception', ProgTxt) > 0) Then
    S := S + ' : ' + SizeTxt(ProgDone)
  Else If ProgDone > 0 Then S := S + ' : ' + IStr(ProgDone);
  ProgLine := S + '...';
End;

{ ---- liste des copies de travail ---- }

Procedure ReposSave;
Var I : LongInt;
Begin
  IniSet('Copies', 'Nombre', IStr(RepoN));
  For I := 0 To RepoN - 1 Do IniSet('Copies', 'C' + IStr(I), RepoPath[I]);
  IniSet('Copies', 'Courante', IStr(RepoCur));
End;

Procedure ReposLoad;
Var I : LongInt;
Begin
  RepoN := StrToIntDef(IniGet('Copies', 'Nombre', '0'), 0);
  If RepoN < 0 Then RepoN := 0;
  If RepoN > MaxRepo Then RepoN := MaxRepo;
  For I := 0 To RepoN - 1 Do RepoPath[I] := IniGet('Copies', 'C' + IStr(I),
    '');
  RepoCur := StrToIntDef(IniGet('Copies', 'Courante', '-1'), -1);
  If RepoCur >= RepoN Then RepoCur := -1;
End;

Function RepoIndex(Const P : String) : LongInt;
Var I : LongInt;
Begin
  RepoIndex := -1;
  For I := 0 To RepoN - 1 Do
    If UpStr(RepoPath[I]) = UpStr(P) Then RepoIndex := I;
End;

Function RepoAdd(P : String) : LongInt;
Var K, I : LongInt;
Begin
  If (Length(P) > 3) And (P[Length(P)] = '\') Then Delete(P, Length(P), 1);
  K := RepoIndex(P);
  If K < 0 Then
  Begin
    If RepoN >= MaxRepo Then
    Begin
      For I := 0 To MaxRepo - 2 Do RepoPath[I] := RepoPath[I + 1];
      Dec(RepoN);
    End;
    RepoPath[RepoN] := P;
    K := RepoN;
    Inc(RepoN);
  End;
  RepoAdd := K;
End;

Procedure RepoRemove(K : LongInt);
Var I : LongInt;
Begin
  If (K < 0) Or (K >= RepoN) Then Exit;
  For I := K To RepoN - 2 Do RepoPath[I] := RepoPath[I + 1];
  Dec(RepoN);
  If RepoCur = K Then RepoCur := -1
  Else If RepoCur > K Then Dec(RepoCur);
End;

Function RepoTitle(K : LongInt) : String;
Begin
  If (K < 0) Or (K >= RepoN) Then RepoTitle := ''
  Else RepoTitle := NameOf(RepoPath[K]);
End;

{ supprime un dossier et son contenu (extraction echouee) }
Procedure RmTree(Const D : String; Depth : LongInt);
Var SR : TSRec; L : TFlat; K, J : LongInt; Ok : Boolean;
Begin
  If (Depth > 30) Or (Length(D) <= 3) Then Exit;
  FlatInit(L);
  Ok := FsFirst(D + '\*', SR);
  While Ok Do
  Begin
    If (SR.Name <> '.') And (SR.Name <> '..') Then
    Begin
      K := FlatAdd(L, SR.Name);
      L.E^[K].Mode := Ord((SR.Attr And $10) <> 0);
    End;
    Ok := FsNext(SR);
  End;
  FsClose(SR);
  For J := 0 To L.N - 1 Do
    If L.E^[J].Mode <> 0 Then RmTree(D + '\' + L.E^[J].Path, Depth + 1)
    Else FileDel(D + '\' + L.E^[J].Path);
  FlatFree(L);
  If FRmDir(D) Then ;
End;

{ ---- identifiants (par serveur) ---- }

Procedure SetCreds(Const Url : String);
Var H : String;
Begin
  RemUser := ''; RemPass := '';
  If Not UrlSplit(Url) Then Exit;
  H := LowStr(UrlHost) + ':' + IStr(UrlPort);
  If (CredHost <> '') And (H = CredHost) Then
  Begin
    RemUser := CredUser; RemPass := CredPass;
  End
  Else If Not TestMode Then
  Begin
    RemUser := IniGet('Identifiants', H + '.Utilisateur', '');
    RemPass := IniGet('Identifiants', H + '.MotDePasse', '');
  End;
End;

Function HostKey(Const Url : String) : String;
Begin
  If UrlSplit(Url) Then HostKey := LowStr(UrlHost) + ':' + IStr(UrlPort)
  Else HostKey := '';
End;

{ ---- operations reseau (fil de travail) ---- }

Function DoOp : Boolean;
Var Ok : Boolean;
Begin
  DoOp := False;
  GitErr := '';
  GitOom := False;
  Case Op Of
    OpCheckout :
    Begin
      SetCreds(OpUrl);
      DoOp := WcCheckout(OpUrl, OpDir);
    End;
    OpUpdate, OpSwitch :
    Begin
      SetCreds(WcUrl);
      If Op = OpSwitch Then Ok := WcUpdate(-1, OpUrl)
      Else Ok := WcUpdate(-1, '');
      If Ok Then WcCleanup;
      DoOp := Ok;
    End;
    OpCommit :
    Begin
      SetCreds(WcUrl);
      DoOp := WcCommit(OpMsg);
    End;
    OpBranch :
    Begin
      SetCreds(WcUrl);
      Ok := WcBranch(OpName, OpMsg);
      If Ok Then
      Begin
        { puis la copie passe sur la nouvelle branche }
        OpUrl := RaRoot + '/' + UrlEnc(JoinP(BrBase, 'branches/' + OpName));
        Ok := WcUpdate(-1, OpUrl);
      End;
      DoOp := Ok;
    End;
    OpLog :
    Begin
      SetCreds(WcUrl);
      Ok := RaOpen(WcUrl) And RaLatest(HHead);
      If Ok Then
      Begin
        Ok := RaLog(RaRel, HHead, 0, HistMax, True);
        { nouvelles revisions qui touchent la copie }
        Incoming := 0;
        While (Incoming < HistN) And (Hist^[Incoming].Rev > WcRev) Do
          Inc(Incoming);
      End;
      DoOp := Ok;
    End;
  End;
End;

{ fil de travail (DosCreateThread) : une operation, puis WM_GITDONE }
Function WorkProc(P : LongInt) : LongInt;
Begin
  BigLock;
  WorkTid := CurTid;
  NetAbort := False;
  OpOk := DoOp;
  RaClose;
  HClose;
  BigUnlock;
  Dummy0 := WinPostMsg(MainWnd, WM_GITDONE, 0, 0);
  WorkProc := 0;
End;

Procedure StartOp(K : LongInt);
Var Tid : LongInt;
Begin
  If Busy Then Exit;
  Op := K;
  Busy := True;
  ProgTxt := 'Connexion'; ProgDone := 0; ProgTotal := 0;
  WorkTid := -1;
  Tid := 0;
  If DosCreateThread(LongInt(@Tid), LongInt(@WorkProc), 0, 0, 262144) <> 0 Then
  Begin
    { pas de fil : execution directe }
    WorkTid := 0;
    OpOk := DoOp;
    RaClose;
    HClose;
    Dummy0 := WinPostMsg(MainWnd, WM_GITDONE, 0, 0);
  End;
  InvalidateStatus;
End;
{ ==================================================================== }
{ Listes (modifications, historique, fichiers d'une revision) et diff   }
{ ==================================================================== }

Const
  LvChg = 0; LvHist = 1; LvFiles = 2;
  SbW = 16;
  DRowH = 16;
  DHeadH = 24;
  DGut = 92;                           { colonnes des numeros de ligne }

Type
  TLv = Record
    H, Sb : LongInt;
    Top, RowH, W, Hh : LongInt;
  End;

Var
  DiffErr : String;
  Lv : Array[0..2] Of TLv;
  DiffWnd, DSbV, DSbH : LongInt;
  DTop, DLeft, DW, DH : LongInt;

Procedure SelectChange(I : LongInt); Forward;
Procedure SelectCommit(I : LongInt); Forward;
Procedure SelectFile(I : LongInt); Forward;
Procedure ChangesMenu(X, Y : LongInt); Forward;
Procedure CheckedChanged; Forward;
Function HPath(Const P : String) : String; Forward;

Function LvCount(K : LongInt) : LongInt;
Begin
  Case K Of
    LvChg : LvCount := Chg.N;
    LvHist : LvCount := HistN;
  Else
    LvCount := HFiles.N;
  End;
End;

Function LvCur(K : LongInt) : LongInt;
Begin
  Case K Of
    LvChg : LvCur := ChgSel;
    LvHist : LvCur := HistSel;
  Else
    LvCur := FileSel;
  End;
End;

Function LvRows(K : LongInt) : LongInt;
Begin
  LvRows := MaxL(1, Lv[K].Hh Div Lv[K].RowH);
End;

Procedure LvSync(K : LongInt);
Var M : LongInt;
Begin
  M := MaxL(0, LvCount(K) - LvRows(K));
  If Lv[K].Top > M Then Lv[K].Top := M;
  If Lv[K].Top < 0 Then Lv[K].Top := 0;
  SbSet(Lv[K].Sb, Lv[K].Top, M, LvRows(K));
End;

Procedure LvRepaint(K : LongInt);
Begin
  Inval(Lv[K].H);
End;

Procedure LvVisible(K : LongInt);
Var C : LongInt;
Begin
  C := LvCur(K);
  If C < 0 Then Exit;
  If C < Lv[K].Top Then Lv[K].Top := C;
  If C >= Lv[K].Top + LvRows(K) Then Lv[K].Top := C - LvRows(K) + 1;
  LvSync(K);
End;

{ icone d'etat d'un fichier (carre de 12 points) }
Procedure StIcon(Dc, X, Y, St : LongInt);
Var C : LongInt;
Begin
  Case St Of
    StNew, StUnv : C := ClrAddI;
    StDel, StMiss : C := ClrDelI;
    StConf : C := ClrConfI;
  Else
    C := ClrModI;
  End;
  Bar(Dc, X, Y, X + 12, Y + 12, C);
  Bar(Dc, X + 1, Y + 1, X + 11, Y + 11, ClrWin);
  Case St Of
    StNew, StUnv :
    Begin
      Bar(Dc, X + 3, Y + 5, X + 9, Y + 7, C);
      Bar(Dc, X + 5, Y + 3, X + 7, Y + 9, C);
    End;
    StDel, StMiss : Bar(Dc, X + 3, Y + 5, X + 9, Y + 7, C);
    StProp :
    Begin
      { P : proprietes }
      Bar(Dc, X + 4, Y + 3, X + 6, Y + 10, C);
      Bar(Dc, X + 4, Y + 3, X + 9, Y + 5, C);
      Bar(Dc, X + 7, Y + 3, X + 9, Y + 7, C);
      Bar(Dc, X + 4, Y + 6, X + 9, Y + 7, C);
    End;
    StConf :
    Begin
      Bar(Dc, X + 5, Y + 2, X + 7, Y + 7, C);
      Bar(Dc, X + 5, Y + 8, X + 7, Y + 10, C);
    End;
  Else
    Bar(Dc, X + 4, Y + 4, X + 8, Y + 8, C);
  End;
End;

{ case a cocher dans le style de PM (13 points) }
Procedure CheckBox(Dc, X, Y : LongInt; On, Gray : Boolean);
Var I, C : LongInt;
Begin
  Bevel(Dc, X, Y, X + 13, Y + 13, False);
  If Gray Then Bar(Dc, X + 2, Y + 2, X + 11, Y + 11, ClrFace)
  Else Bar(Dc, X + 2, Y + 2, X + 11, Y + 11, ClrWin);
  If Not On Then Exit;
  C := ClrBlack;
  If Gray Then C := ClrGray;
  For I := 0 To 2 Do Bar(Dc, X + 3 + I, Y + 5 + I, X + 4 + I, Y + 8 + I, C);
  For I := 0 To 3 Do Bar(Dc, X + 6 + I, Y + 6 - I, X + 7 + I, Y + 9 - I, C);
End;

Function DirOf(Const P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> '/') Do Dec(K);
  DirOf := Copy(P, 1, K);
End;

Function FileOf(Const P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> '/') Do Dec(K);
  FileOf := Copy(P, K + 1, 255);
End;

Procedure LvPaint(K, H : LongInt);
Var Dc, R, Y, N, I, Fg, Fg2, Bg, X, St : LongInt; S, D : String;
    Sel : Boolean;
Begin
  Dc := PaintBegin(H);
  N := LvCount(K);
  For R := 0 To LvRows(K) Do
  Begin
    I := Lv[K].Top + R;
    Y := R * Lv[K].RowH;
    Sel := (I < N) And (I = LvCur(K));
    If Sel Then
    Begin
      Bg := ClrNavy; Fg := ClrWin; Fg2 := ClrLight;
    End
    Else
    Begin
      Bg := ClrWin; Fg := ClrBlack; Fg2 := ClrGray;
    End;
    Bar(Dc, 0, Y, Lv[K].W, Y + Lv[K].RowH, Bg);
    If I >= N Then Continue;
    Case K Of
      LvChg :
      Begin
        St := Chg.E^[I].Flag And $FF;
        CheckBox(Dc, 4, Y + 3, (Chg.E^[I].Flag And FlSel) <> 0, False);
        D := Utf8ToAnsi(DirOf(Chg.E^[I].Path));
        S := Utf8ToAnsi(FileOf(Chg.E^[I].Path));
        If St = StProp Then
        Begin
          D := '';
          If Chg.E^[I].Path = '' Then S := '(racine) : svn:ignore'
          Else S := Utf8ToAnsi(Chg.E^[I].Path) + '/ : svn:ignore';
        End;
        X := 24;
        If D <> '' Then
        Begin
          D := Fit(D, MaxL(40, Lv[K].W - 48 - Length(S) * CW));
          Txt(Dc, X, Y + 2, D, Fg2);
          X := X + Length(D) * CW;
        End;
        Txt(Dc, X, Y + 2, Fit(S, Lv[K].W - X - 22), Fg);
        StIcon(Dc, Lv[K].W - 17, Y + 4, St);
      End;
      LvHist :
      Begin
        S := 'r' + IStr(Hist^[I].Rev) + '  ';
        If (Hist^[I].Rev > WcRev) And Not Sel Then
          Txt(Dc, 6, Y + 2, S, ClrRed)
        Else Txt(Dc, 6, Y + 2, S, Fg);
        Txt(Dc, 6 + Length(S) * CW, Y + 2, Fit(Utf8ToAnsi(HistSummary(I)),
          Lv[K].W - 12 - Length(S) * CW), Fg);
        TxtF(Dc, 6, Y + 19, FitW(Hist^[I].Author + ' - ' +
          UnixToStr(Hist^[I].Time), Lv[K].W - 12, SCW), Fg2, 1);
        If Not Sel Then Bar(Dc, 0, Y + Lv[K].RowH - 1, Lv[K].W,
          Y + Lv[K].RowH, ClrLight);
      End;
    Else
      Begin
        Case HFiles.E^[I].Flag And $FF Of
          LaAdd : St := StNew;
          LaDel : St := StDel;
        Else
          St := StMod;
        End;
        D := Utf8ToAnsi(DirOf(HPath(HFiles.E^[I].Path)));
        S := Utf8ToAnsi(FileOf(HPath(HFiles.E^[I].Path)));
        If HFiles.E^[I].Mode = 1 Then S := S + '/';
        X := 6;
        If D <> '' Then
        Begin
          D := Fit(D, MaxL(40, Lv[K].W - 30 - Length(S) * CW));
          Txt(Dc, X, Y + 1, D, Fg2);
          X := X + Length(D) * CW;
        End;
        Txt(Dc, X, Y + 1, Fit(S, Lv[K].W - X - 22), Fg);
        StIcon(Dc, Lv[K].W - 17, Y + 3, St);
      End;
    End;
  End;
  If N = 0 Then
  Begin
    If K = LvChg Then S := 'Aucune modification'
    Else If (K = LvHist) And Busy And (Op = OpLog) Then
      S := 'Lecture du journal...'
    Else If K = LvHist Then S := 'Aucune r'#233'vision'
    Else S := '';
    Txt(Dc, MaxL(4, (Lv[K].W - Length(S) * CW) Div 2), 20, S, ClrGray);
  End;
  PaintEnd(Dc);
End;

Procedure LvSelect(K, I : LongInt);
Begin
  If (I < 0) Or (I >= LvCount(K)) Then Exit;
  Case K Of
    LvChg : SelectChange(I);
    LvHist : SelectCommit(I);
  Else
    SelectFile(I);
  End;
  LvVisible(K);
  LvRepaint(K);
End;

Procedure LvKey(K, VK : LongInt);
Var C, N : LongInt;
Begin
  C := LvCur(K); N := LvCount(K);
  If N = 0 Then Exit;
  Case VK Of
    VK_UP : LvSelect(K, MaxL(0, C - 1));
    VK_DOWN : LvSelect(K, MinL(N - 1, C + 1));
    VK_PRIOR : LvSelect(K, MaxL(0, C - LvRows(K) + 1));
    VK_NEXT : LvSelect(K, MinL(N - 1, C + LvRows(K) - 1));
    VK_HOME : LvSelect(K, 0);
    VK_END : LvSelect(K, N - 1);
    VK_SPACE :
      If (K = LvChg) And (C >= 0) Then
      Begin
        Chg.E^[C].Flag := Chg.E^[C].Flag Xor FlSel;
        LvRepaint(K);
        CheckedChanged;
      End;
  End;
End;

Function LvOf(H : LongInt) : LongInt;
Var K : LongInt;
Begin
  LvOf := -1;
  For K := 0 To 2 Do
    If Lv[K].H = H Then LvOf := K;
End;

Procedure LvScroll(K, Code, Pos : LongInt);
Begin
  Case Code Of
    SB_LINEUP : Dec(Lv[K].Top);
    SB_LINEDOWN : Inc(Lv[K].Top);
    SB_PAGEUP : Dec(Lv[K].Top, LvRows(K) - 1);
    SB_PAGEDOWN : Inc(Lv[K].Top, LvRows(K) - 1);
    SB_THUMBTRACK, SB_THUMBPOSITION : Lv[K].Top := Pos;
    SB_TOP : Lv[K].Top := 0;
    SB_BOTTOM : Lv[K].Top := LvCount(K);
  End;
  LvSync(K);
  LvRepaint(K);
End;

Function LvProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var K, X, Y, I : LongInt;
Begin
  LvProc0 := 0;
  K := LvOf(H);
  If K < 0 Then Exit;
  Case Msg Of
    WM_PAINT : LvPaint(K, H);
    WM_SIZE :
    Begin
      Lv[K].W := (LP And $FFFF) - SbW; Lv[K].Hh := (LP Shr 16) And $FFFF;
      Place(Lv[K].Sb, Lv[K].W, 0, SbW, Lv[K].Hh);
      LvSync(K);
    End;
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK, WM_RBUTTONDOWN :
    Begin
      WFocus(H);
      If Busy Then Exit;
      X := S16(LP); Y := S16(LP Shr 16);
      I := Lv[K].Top + Y Div Lv[K].RowH;
      If (I >= 0) And (I < LvCount(K)) Then
      Begin
        If (K = LvChg) And (X < 22) And (Msg <> WM_RBUTTONDOWN) Then
        Begin
          Chg.E^[I].Flag := Chg.E^[I].Flag Xor FlSel;
          LvRepaint(K);
          CheckedChanged;
        End;
        If I <> LvCur(K) Then LvSelect(K, I);
        If (K = LvChg) And (Msg = WM_RBUTTONDOWN) Then ChangesMenu(X, Y);
      End;
    End;
    WM_KEYDOWN : If Not Busy Then LvKey(K, WP);
    WM_VSCROLL : LvScroll(K, WP And $FFFF, (WP Shr 16) And $FFFF);
  End;
End;

{ procedure de PM des listes : messages de PM traduits en messages de
  Pasdows (souris : Y vers le bas ; touches de PM -> VK_ ; barre de
  defilement -> SB_) }
Function LvProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var R, Fl, V : LongInt;
Begin
  R := 0;
  BigLock;
  Case Msg Of
    PM_WM_PAINT : Dummy0 := LvProc0(H, WM_PAINT, 0, 0);
    PM_WM_ERASEBACKGROUND : R := 0;
    PM_WM_SIZE : Dummy0 := LvProc0(H, WM_SIZE, 0, Mp2);
    PM_WM_BUTTON1DOWN :
    Begin
      Dummy0 := LvProc0(H, WM_LBUTTONDOWN, 0, MousePt(H, Mp1));
      R := 1;
    End;
    PM_WM_BUTTON1DBLCLK :
    Begin
      Dummy0 := LvProc0(H, WM_LBUTTONDBLCLK, 0, MousePt(H, Mp1));
      R := 1;
    End;
    PM_WM_BUTTON2DOWN :
    Begin
      Dummy0 := LvProc0(H, WM_RBUTTONDOWN, 0, MousePt(H, Mp1));
      R := 1;
    End;
    PM_WM_VSCROLL : Dummy0 := LvProc0(H, WM_VSCROLL, VsCode(Mp2), 0);
    PM_WM_CHAR :
    Begin
      Fl := Mp1 And $FFFF; V := (Mp2 Shr 16) And $FFFF;
      If ((Fl And PM_KC_KEYUP) = 0) And ((Fl And PM_KC_VIRTUALKEY) <> 0) And
         (VkOf(V) <> 0) And (VkOf(V) <> VK_TAB) And
         ((Fl And (PM_KC_CTRL Or PM_KC_ALT)) = 0) Then
      Begin
        Dummy0 := LvProc0(H, WM_KEYDOWN, VkOf(V), 0);
        R := 1;
      End
      Else R := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
  Else
    R := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
  BigUnlock;
  LvProc := R;
End;

{ ---- vue des differences ---- }

Function ExpandTabs(Const S : String) : String;
Var I, K : LongInt; R : String;
Begin
  R := '';
  For I := 1 To Length(S) Do
    If S[I] = #9 Then
    Begin
      K := 4 - (Length(R) Mod 4);
      While (K > 0) And (Length(R) < 250) Do
      Begin
        R := R + ' '; Dec(K);
      End;
    End
    Else If Length(R) < 250 Then R := R + S[I];
  ExpandTabs := R;
End;

Function DRows : LongInt;
Begin
  DRows := MaxL(1, (DH - DHeadH) Div DRowH);
End;

Function DCols : LongInt;
Begin
  DCols := MaxL(1, (DW - DGut - 14) Div CW);
End;

Procedure DiffSync;
Var M : LongInt;
Begin
  M := 0;
  If DiffMode = 1 Then M := MaxL(0, DfN - DRows);
  If DTop > M Then DTop := M;
  If DTop < 0 Then DTop := 0;
  SbSet(DSbV, DTop, M, DRows);
  M := 0;
  If DiffMode = 1 Then M := MaxL(0, 250 - DCols);
  If DLeft > M Then DLeft := M;
  If DLeft < 0 Then DLeft := 0;
  SbSet(DSbH, DLeft, M, DCols);
End;

Procedure DiffRepaint;
Begin
  Inval(DiffWnd);
End;

Procedure DiffReset;
Begin
  DTop := 0; DLeft := 0;
  DiffSync;
  DiffRepaint;
End;

Procedure CenterTxt(Dc, Y : LongInt; Const S : String; C : LongInt);
Begin
  Txt(Dc, MaxL(4, (DW - Length(S) * CW) Div 2), Y, Fit(S, DW - 8), C);
End;

Procedure DiffPaint(H : LongInt);
Var Dc, R, I, Y, Bg, Gb, Fg, X : LongInt; S, A, B : String;
Begin
  Dc := PaintBegin(H);
  { en-tete : chemin du fichier }
  Bar(Dc, 0, 0, DW + SbW, DHeadH, ClrFace);
  Thin(Dc, 0, 0, DW + SbW, DHeadH, True);
  If DiffTitle <> '' Then
  Begin
    S := '';
    If DiffMode = 1 Then
      S := '  +' + IStr(DfAdd) + ' -' + IStr(DfDel);
    Txt(Dc, 8, 4, Fit(Utf8ToAnsi(DiffTitle), DW - 16 - Length(S) * CW),
      ClrBlack);
    If S <> '' Then
    Begin
      X := DW + SbW - 8 - Length(S) * CW;
      Txt(Dc, X, 4, '  +' + IStr(DfAdd), ClrGreen);
      Txt(Dc, X + (Length(IStr(DfAdd)) + 4) * CW, 4, '-' + IStr(DfDel),
        ClrRed);
    End;
  End;
  Bar(Dc, 0, DHeadH, DW, DH, ClrWin);
  { coin entre les deux barres de defilement }
  Bar(Dc, DW, DH, DW + SbW, DH + SbW, ClrFace);
  Case DiffMode Of
    0 :
    Begin
      If (RepoCur >= 0) And (View = VwChanges) And (Chg.N = 0) Then
      Begin
        CenterTxt(Dc, DHeadH + 60, 'Aucune modification locale', ClrBlack);
        CenterTxt(Dc, DHeadH + 84, 'Rien '#224' valider dans cette copie.',
          ClrGray);
        If Incoming > 0 Then
        Begin
          CenterTxt(Dc, DHeadH + 108, IStr(Incoming) + ' r'#233'vision(s) ' +
            'plus r'#233'cente(s) sur le serveur :', ClrNavy);
          CenterTxt(Dc, DHeadH + 126, 'mettez '#224' jour (Ctrl+Maj+P).',
            ClrNavy);
        End
        Else
        Begin
          CenterTxt(Dc, DHeadH + 108, 'Modifiez-la avec l''Explorateur',
            ClrGray);
          CenterTxt(Dc, DHeadH + 126, '(Ctrl+Maj+F) ou vos programmes.',
            ClrGray);
        End;
      End;
    End;
    5 : CenterTxt(Dc, DHeadH + 60, 'Dossier', ClrGray);
    6 : CenterTxt(Dc, DHeadH + 60, DiffErr, ClrRed);
    2 : CenterTxt(Dc, DHeadH + 60, 'Fichier binaire : diff'#233'rences non ' +
          'affich'#233'es.', ClrGray);
    3 : CenterTxt(Dc, DHeadH + 60, 'Fichier trop volumineux pour afficher ' +
          'les diff'#233'rences.', ClrGray);
    1 :
    Begin
      If DfN = 0 Then
        CenterTxt(Dc, DHeadH + 60, 'Aucune diff'#233'rence de contenu (fichier '
          + 'vide ou propri'#233't'#233's).', ClrGray);
      For R := 0 To DRows Do
      Begin
        I := DTop + R;
        If I >= DfN Then Break;
        Y := DHeadH + R * DRowH;
        If Y + DRowH > DH Then Break;
        A := ''; B := '';
        Case Df^[I].K Of
          DkAdd :
          Begin
            Bg := ClrAddBg; Gb := ClrAddG; Fg := ClrBlack;
            B := IStr(Df^[I].LB + 1);
          End;
          DkDel :
          Begin
            Bg := ClrDelBg; Gb := ClrDelG; Fg := ClrBlack;
            A := IStr(Df^[I].LA + 1);
          End;
          DkHunk :
          Begin
            Bg := ClrHunk; Gb := ClrHunk; Fg := ClrHunkT;
          End;
        Else
          Begin
            Bg := ClrWin; Gb := ClrWin; Fg := ClrBlack;
            A := IStr(Df^[I].LA + 1); B := IStr(Df^[I].LB + 1);
          End;
        End;
        Bar(Dc, 0, Y, DGut - 12, Y + DRowH, Gb);
        Bar(Dc, DGut - 12, Y, DW, Y + DRowH, Bg);
        Bar(Dc, DGut - 12, Y, DGut - 11, Y + DRowH, ClrLight);
        If A <> '' Then TxtF(Dc, 36 - Length(A) * SCW, Y, A, ClrGray, 1);
        If B <> '' Then TxtF(Dc, 74 - Length(B) * SCW, Y, B, ClrGray, 1);
        Case Df^[I].K Of
          DkAdd : Txt(Dc, DGut - 8, Y, '+', ClrGreen);
          DkDel : Txt(Dc, DGut - 8, Y, '-', ClrRed);
        End;
        S := ExpandTabs(Utf8ToAnsi(DiffText(I)));
        If Df^[I].K = DkHunk Then
          Txt(Dc, DGut, Y, Copy(S, 1, DCols), Fg)
        Else Txt(Dc, DGut, Y, Copy(S, DLeft + 1, DCols), Fg);
      End;
    End;
  End;
  PaintEnd(Dc);
End;

Procedure DiffScroll(Vert : Boolean; Code, Pos : LongInt);
Var V, Pg : LongInt;
Begin
  If Vert Then
  Begin
    V := DTop; Pg := DRows - 1;
  End
  Else
  Begin
    V := DLeft; Pg := DCols - 4;
  End;
  Case Code Of
    SB_LINEUP : Dec(V);
    SB_LINEDOWN : Inc(V);
    SB_PAGEUP : Dec(V, Pg);
    SB_PAGEDOWN : Inc(V, Pg);
    SB_THUMBTRACK, SB_THUMBPOSITION : V := Pos;
    SB_TOP : V := 0;
    SB_BOTTOM : V := 1000000;
  End;
  If Vert Then DTop := V Else DLeft := V;
  DiffSync;
  DiffRepaint;
End;

Function DiffProc0(H, Msg, WP, LP : LongInt) : LongInt;
Begin
  DiffProc0 := 0;
  Case Msg Of
    WM_PAINT : DiffPaint(H);
    WM_SIZE :
    Begin
      DW := (LP And $FFFF) - SbW; DH := ((LP Shr 16) And $FFFF) - SbW;
      Place(DSbV, DW, DHeadH, SbW, DH - DHeadH);
      Place(DSbH, 0, DH, DW, SbW);
      DiffSync;
    End;
    WM_LBUTTONDOWN : WFocus(H);
    WM_VSCROLL : DiffScroll(True, WP And $FFFF, (WP Shr 16) And $FFFF);
    WM_HSCROLL : DiffScroll(False, WP And $FFFF, (WP Shr 16) And $FFFF);
    WM_KEYDOWN :
      Case WP Of
        VK_UP : DiffScroll(True, SB_LINEUP, 0);
        VK_DOWN : DiffScroll(True, SB_LINEDOWN, 0);
        VK_PRIOR : DiffScroll(True, SB_PAGEUP, 0);
        VK_NEXT : DiffScroll(True, SB_PAGEDOWN, 0);
        VK_HOME : DiffScroll(True, SB_TOP, 0);
        VK_END : DiffScroll(True, SB_BOTTOM, 0);
        VK_LEFT : DiffScroll(False, SB_LINEUP, 0);
        VK_RIGHT : DiffScroll(False, SB_LINEDOWN, 0);
      End;
  End;
End;

Function DiffProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var R, Fl, V : LongInt;
Begin
  R := 0;
  BigLock;
  Case Msg Of
    PM_WM_PAINT : Dummy0 := DiffProc0(H, WM_PAINT, 0, 0);
    PM_WM_ERASEBACKGROUND : R := 0;
    PM_WM_SIZE : Dummy0 := DiffProc0(H, WM_SIZE, 0, Mp2);
    PM_WM_BUTTON1DOWN :
    Begin
      Dummy0 := DiffProc0(H, WM_LBUTTONDOWN, 0, MousePt(H, Mp1));
      R := 1;
    End;
    PM_WM_VSCROLL : Dummy0 := DiffProc0(H, WM_VSCROLL, VsCode(Mp2), 0);
    PM_WM_HSCROLL : Dummy0 := DiffProc0(H, WM_HSCROLL, VsCode(Mp2), 0);
    PM_WM_CHAR :
    Begin
      Fl := Mp1 And $FFFF; V := (Mp2 Shr 16) And $FFFF;
      If ((Fl And PM_KC_KEYUP) = 0) And ((Fl And PM_KC_VIRTUALKEY) <> 0) And
         (VkOf(V) <> 0) And (VkOf(V) <> VK_TAB) And
         ((Fl And (PM_KC_CTRL Or PM_KC_ALT)) = 0) Then
      Begin
        Dummy0 := DiffProc0(H, WM_KEYDOWN, VkOf(V), 0);
        R := 1;
      End
      Else R := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
  Else
    R := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
  BigUnlock;
  DiffProc := R;
End;

{ calcule et affiche le diff de DfA vers DfB }
Procedure DiffShow;
Begin
  If DfA.N + DfB.N > DiffMax Then
  Begin
    DiffMode := 3; DfN := 0; DfAdd := 0; DfDel := 0;
  End
  Else
  Begin
    DiffMode := 1;
    DiffBuild;
    If DfBin Then DiffMode := 2;
  End;
  DiffReset;
End;

{ texte de svn:ignore (lignes) dans B }
Procedure IgnText(Const S : String; Var B : TBuf);
Begin
  B.N := 0;
  BufStr(B, S);
  If (B.N > 0) And (B.P^[B.N - 1] <> 10) Then BufByte(B, 10);
End;

{ modification locale : base (copie) contre fichier de travail }
Procedure DiffLoadWork(I : LongInt);
Var K, St, Sz, Tm, Sw : LongInt; P : String;
Begin
  P := Chg.E^[I].Path;
  St := Chg.E^[I].Flag And $FF;
  DiffTitle := P;
  DfA.N := 0; DfB.N := 0;
  If St = StProp Then
  Begin
    If P = '' Then DiffTitle := '(racine) : svn:ignore'
    Else DiffTitle := P + '/ : svn:ignore';
    IgnText(IgnGet(IgnB, IgnBV, P), DfA);
    IgnText(IgnGet(IgnP, IgnPV, P), DfB);
    DiffShow;
    Exit;
  End;
  K := EntFind(P);
  Sz := 0;
  If (K >= 0) And (Ent^[K].Md5 <> '') Then
    If FileStat(PristinePath(Ent^[K].Md5), Sz, Tm) Then ;
  If (St <> StDel) And (St <> StMiss) Then
    If FileStat(WorkPath(P), Sw, Tm) Then Sz := Sz + Sw;
  If Sz > DiffMax Then
  Begin
    DiffMode := 3; DfN := 0; DfAdd := 0; DfDel := 0;
    DiffReset; Exit;
  End;
  If (K >= 0) And (Ent^[K].Md5 <> '') And (St <> StNew) And (St <> StUnv)
  Then
    If Not FileLoad(PristinePath(Ent^[K].Md5), DfA) Then DfA.N := 0;
  If (St <> StDel) And (St <> StMiss) Then
    If Not FileLoad(WorkPath(P), DfB) Then DfB.N := 0;
  DiffShow;
End;

{ fichier Path (depuis la racine du depot) a la revision R, dans B ;
  faux s'il est trop grand ou illisible }
Function FetchAt(Const Path : String; R : LongInt; Var B : TBuf) : Boolean;
Var T, M : String; Sz, Tm : LongInt;
Begin
  FetchAt := False;
  B.N := 0;
  T := MetaPath('tmp.diff');
  If Not RaGetFile(Path, R, T, B, M) Then Exit;
  If FileStat(T, Sz, Tm) And (Sz <= DiffMax) Then
    FetchAt := FileLoad(T, B)
  Else
  Begin
    GitErr := 'trop grand'; DiffMode := 3;
  End;
  FileDel(T);
End;

{ fichier modifie par une revision : version precedente et nouvelle,
  lues sur le serveur }
Procedure DiffLoadRev(I : LongInt);
Var R, Act, Cr, K : LongInt; P, Cp : String; Ok : Boolean;
Begin
  DfA.N := 0; DfB.N := 0;
  P := HFiles.E^[I].Path;
  DiffTitle := P;
  If HFiles.E^[I].Mode = 1 Then
  Begin
    DiffMode := 5; DfN := 0; DiffReset; Exit;
  End;
  R := Hist^[HistSel].Rev;
  Act := HFiles.E^[I].Flag And $FF;
  K := HFiles.E^[I].Size;              { indice dans LogCp }
  Cp := ''; Cr := -1;
  If (K >= 0) And (K < LogCp.N) Then
  Begin
    Cp := LogCp.E^[K].Path; Cr := LogCp.E^[K].Size;
  End;
  SetPtr(SPTR_WAIT);
  SetCreds(WcUrl);
  DiffMode := 1;
  Ok := RaOpen(WcUrl);
  If Ok And (Act <> LaDel) Then Ok := FetchAt(Copy(P, 2, 255), R, DfB);
  If Ok And (Cp <> '') And (Cr > 0) Then
    Ok := FetchAt(Copy(Cp, 2, 255), Cr, DfA)
  Else If Ok And (Act <> LaAdd) And (R > 1) Then
    Ok := FetchAt(Copy(P, 2, 255), R - 1, DfA);
  RaClose;
  SetPtr(SPTR_ARROW);
  If Not Ok Then
  Begin
    If DiffMode <> 3 Then
    Begin
      DiffMode := 6; DiffErr := 'Lecture impossible : ' + GitErr;
    End;
    DfN := 0; DfAdd := 0; DfDel := 0;
    DiffReset; Exit;
  End;
  DiffShow;
End;

Procedure DiffClear;
Begin
  DiffTitle := '';
  DiffMode := 0;
  DfN := 0;
  DiffReset;
End;
{ ==================================================================== }
{ Boites de dialogue                                                    }
{ ==================================================================== }

Const
  DgInput = 1; DgCheckout = 2; DgAdd = 4; DgOptions = 5; DgCred = 8;
  DgBrowse = 9;
  IdInput = 120;
  IdList = 201; IdUrl = 203; IdPath = 204; IdBrowse = 205;
  IdProxy = 215; IdRoot = 216; IdUser = 218; IdPass = 219; IdInfo = 220;
  IdSave = 221; IdForget = 222; IdDirs = 223; IdCur = 224;
  MaxUrls = 12;

Var
  DlgWnd, DlgFrame, DlgKind, DlgRes : LongInt;
  DlgDone : Boolean;
  DlgText : String;
  InpEdit : LongInt;
  DCt : Array[200..230] Of LongInt;
  PathEdited, DlgSync : Boolean;
  DlgOut : Array[0..7] Of String;
  UrlN : LongInt;
  Urls : Array[0..MaxUrls - 1] Of String;
  DlgPrevFocus : LongInt;
  { boite de dialogue imbriquee (choix d'un dossier) : etat sauve }
  SvDlgWnd, SvDlgFrame, SvDlgKind : LongInt;

Procedure RefreshRepo(Keep : Boolean); Forward;

{ boucle modale : la fenetre principale (et la boite qui ouvre une autre
  boite) est desactivee ; le verrou est libere pendant l'attente des
  messages }
Procedure ModalLoop;
Var D, Own : LongInt;
Begin
  Own := MainFrame;
  If SvDlgFrame <> 0 Then Own := SvDlgFrame;
  Dummy0 := WinEnableWindow(Own, 0);
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
  Dummy0 := WinEnableWindow(Own, 1);
  If DlgFrame <> 0 Then Dummy0 := WinDestroyWindow(DlgFrame);
  DlgWnd := 0; DlgFrame := 0;
  Dummy0 := WinSetWindowPos(Own, HWND_TOP, 0, 0, 0, 0, SWP_ZORDER Or
    SWP_ACTIVATE);
  Dummy0 := WinSetActiveWindow(HWND_DESKTOP, Own);
  { le focus revient au controle qui l'avait avant la boite }
  If (DlgPrevFocus <> 0) And (WinIsWindow(Hab, DlgPrevFocus) <> 0) Then
    WFocus(DlgPrevFocus)
  Else WFocus(MainWnd);
End;

{ boite de dialogue : cadre de PM (titre, menu systeme, bordure de
  dialogue) centre, zone client de W x H ; DlgWnd est la zone client,
  parent des controles }
Function DlgCreate(Const Title : String; W, H : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Fw, Fh, Fl, I : LongInt;
Begin
  If SvDlgFrame = 0 Then
    For I := 200 To 230 Do DCt[I] := 0;
  DlgDone := False; DlgRes := IDCANCEL;
  DlgPrevFocus := WinQueryFocus(HWND_DESKTOP);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DlgWnd := 0;
  DlgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z2('SVDLG'),
    Z(Disp(Title)), 0, 0, 0, LongInt(@DlgWnd));
  If DlgFrame = 0 Then
  Begin
    DlgCreate := 0; Exit;
  End;
  Rc[0] := 0; Rc[1] := 0; Rc[2] := W; Rc[3] := H;
  Dummy0 := WinCalcFrameRect(DlgFrame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Dummy0 := WinSetWindowPos(DlgFrame, HWND_TOP, MaxL(0, (ScrW - Fw) Div 2),
    MaxL(0, (ScrH - Fh) Div 2), Fw, Fh, SWP_SIZE Or SWP_MOVE);
  DlgCreate := DlgWnd;
End;

{ affiche la boite (cadre active au premier plan) }
Procedure DlgShow;
Begin
  Dummy0 := WinSetWindowPos(DlgFrame, HWND_TOP, 0, 0, 0, 0, SWP_SHOW Or
    SWP_ZORDER Or SWP_ACTIVATE);
  Dummy0 := WinSetActiveWindow(HWND_DESKTOP, DlgFrame);
  WFocus(DlgWnd);
End;

Procedure Lbl(P : LongInt; Const S : String; X, Y, W : LongInt);
Begin
  Dummy := Ctl(P, 'STATIC', S, 0, X, Y, W, 16, 0);
End;

Function DEdit(Id, X, Y, W : LongInt; Const S : String; Pw : Boolean)
  : LongInt;
Var St : LongInt;
Begin
  St := WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP;
  If Pw Then St := St Or ES_PASSWORD;
  DCt[Id] := Ctl(DlgWnd, 'EDIT', S, St, X, Y, W, 22, Id);
  DEdit := DCt[Id];
End;

Procedure DButtons(W, H : LongInt; Const OkTxt : String);
Var Bw : LongInt;
Begin
  Bw := MaxL(88, Length(OkTxt) * CW + 24);
  Dummy := Ctl(DlgWnd, 'BUTTON', OkTxt, BS_DEFPUSHBUTTON Or WS_TABSTOP,
    W - Bw - 100, H - 38, Bw, 28, IDOK);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Annuler', WS_TABSTOP, W - 92, H - 38, 80,
    28, IDCANCEL);
End;

Function DText(Id : LongInt) : String;
Begin
  If DCt[Id] = 0 Then DText := '' Else DText := TrimS(CtlText(DCt[Id]));
End;

Function LbAdd(H : LongInt; Const S : String) : LongInt;
Begin
  LbAdd := WinSendMsg(H, PM_LM_INSERTITEM, -1, Z(Disp(S)));
End;

Function LbSel(H : LongInt) : LongInt;
Begin
  LbSel := WinSendMsg(H, PM_LM_QUERYSELECTION, -1, 0);
End;

Function InputBox(Const Title, Prompt : String; Var S : String) : Boolean;
Var W : LongInt;
Begin
  InputBox := False;
  DlgKind := DgInput;
  W := MaxL(340, Length(Prompt) * CW + 24);
  If W > ScrW - 20 Then W := ScrW - 20;
  If DlgCreate(Title, W, 110) = 0 Then Exit;
  Lbl(DlgWnd, Prompt, 12, 10, W - 24);
  InpEdit := Ctl(DlgWnd, 'EDIT', S, WS_BORDER Or ES_AUTOHSCROLL Or
    WS_TABSTOP, 12, 32, W - 24, 22, IdInput);
  DButtons(W, 110, 'OK');
  DlgShow;
  WFocus(InpEdit);
  SelAllText(InpEdit);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    S := TrimS(DlgText);
    InputBox := True;
  End;
End;

{ ---- choix d'un dossier (OS/2 n'a pas de boite de choix de dossier :
  liste des lecteurs et des sous-dossiers, comme le Client SSH) ---- }

Var
  BrDir : String;                      { dossier affiche ('' : lecteurs) }
  BrNames : Array[0..199] Of String[80];
  BrNN : LongInt;

Procedure BrowseFill;
Var SR : TSRec; Ok : Boolean; D : LongInt; C : Char; L : TFlat; I : LongInt;
Begin
  Dummy0 := WinSendMsg(DCt[IdDirs], PM_LM_DELETEALL, 0, 0);
  BrNN := 0;
  If BrDir = '' Then
  Begin
    For C := 'C' To 'Z' Do
      If DirExist(C + ':\') And (BrNN < 200) Then
      Begin
        BrNames[BrNN] := C + ':'; Inc(BrNN);
      End;
  End
  Else
  Begin
    BrNames[0] := '..'; BrNN := 1;
    FlatInit(L);
    Ok := FsFirst(JoinDirS(BrDir, '*'), SR);
    While Ok Do
    Begin
      If ((SR.Attr And $10) <> 0) And (SR.Name <> '.') And (SR.Name <> '..')
      Then D := FlatAdd(L, SR.Name);
      Ok := FsNext(SR);
    End;
    FsClose(SR);
    FlatSort(L);
    For I := 0 To L.N - 1 Do
      If BrNN < 200 Then
      Begin
        BrNames[BrNN] := '[' + Copy(L.E^[I].Path, 1, 76) + ']'; Inc(BrNN);
      End;
    FlatFree(L);
  End;
  For I := 0 To BrNN - 1 Do Dummy0 := LbAdd(DCt[IdDirs], BrNames[I]);
  If BrDir = '' Then SetText(DCt[IdCur], 'Lecteurs')
  Else SetText(DCt[IdCur], BrDir);
End;

Procedure BrowseEnter(I : LongInt);
Var S : String; K : LongInt;
Begin
  If (I < 0) Or (I >= BrNN) Then Exit;
  S := BrNames[I];
  If S = '..' Then
  Begin
    If Length(BrDir) <= 3 Then BrDir := ''
    Else
    Begin
      K := Length(BrDir);
      While (K > 0) And (BrDir[K] <> '\') Do Dec(K);
      BrDir := Copy(BrDir, 1, K - 1);
      If Length(BrDir) = 2 Then BrDir := BrDir + '\';
    End;
  End
  Else If (Length(S) = 2) And (S[2] = ':') Then BrDir := S + '\'
  Else BrDir := JoinDirS(BrDir, Copy(S, 2, Length(S) - 2));
  BrowseFill;
End;

Procedure BrowseCommand(Id, Code : LongInt);
Begin
  Case Id Of
    IdDirs : If Code = LBN_DBLCLK Then BrowseEnter(LbSel(DCt[IdDirs]));
    IDOK :
    Begin
      If BrDir = '' Then Exit;
      DlgText := BrDir;
      DlgRes := IDOK; DlgDone := True;
    End;
    IDCANCEL :
    Begin
      DlgRes := IDCANCEL; DlgDone := True;
    End;
  End;
End;

Function BrowseFolder(Const Title : String; Var Dir : String) : Boolean;
Const W = 380; H = 330;
Var D, K : LongInt; Ok : Boolean; SvOut : Array[0..1] Of LongInt;
Begin
  BrowseFolder := False;
  { la boite qui appelle reste ouverte : son etat est sauve }
  SvDlgWnd := DlgWnd; SvDlgFrame := DlgFrame; SvDlgKind := DlgKind;
  SvOut[0] := DCt[IdDirs]; SvOut[1] := DCt[IdCur];
  D := DlgPrevFocus;
  BrDir := Dir;
  While (BrDir <> '') And Not DirExist(BrDir) Do
  Begin
    K := Length(BrDir);
    While (K > 0) And (BrDir[K] <> '\') Do Dec(K);
    If K <= 2 Then BrDir := '' Else BrDir := Copy(BrDir, 1, K - 1);
  End;
  If Length(BrDir) = 2 Then BrDir := BrDir + '\';
  DlgKind := DgBrowse;
  Ok := DlgCreate(Title, W, H) <> 0;
  If Ok Then
  Begin
    DCt[IdCur] := Ctl(DlgWnd, 'STATIC', '', 0, 12, 10, W - 24, 16, IdCur);
    Lbl(DlgWnd, 'Double-cliquez sur un dossier pour l''ouvrir.', 12, 30,
      W - 24);
    DCt[IdDirs] := Ctl(DlgWnd, 'LISTBOX', '', WS_BORDER Or WS_VSCROLL Or
      LBS_NOTIFY Or WS_TABSTOP, 12, 52, W - 24, H - 102, IdDirs);
    DButtons(W, H, 'Choisir');
    BrowseFill;
    DlgShow;
    WFocus(DCt[IdDirs]);
    ModalLoop;
    If DlgRes = IDOK Then
    Begin
      Dir := DlgText;
      If (Length(Dir) > 3) And (Dir[Length(Dir)] = '\') Then
        Delete(Dir, Length(Dir), 1);
      BrowseFolder := True;
    End;
  End;
  DlgWnd := SvDlgWnd; DlgFrame := SvDlgFrame; DlgKind := SvDlgKind;
  DCt[IdDirs] := SvOut[0]; DCt[IdCur] := SvOut[1];
  SvDlgWnd := 0; SvDlgFrame := 0;
  DlgDone := False; DlgRes := IDCANCEL;
  DlgPrevFocus := D;
  If DlgFrame <> 0 Then
  Begin
    Dummy0 := WinSetActiveWindow(HWND_DESKTOP, DlgFrame);
    WFocus(DCt[IdPath]);
  End;
End;

{ ---- adresses deja utilisees ---- }

Procedure UrlsLoad;
Var I : LongInt; S : String;
Begin
  UrlN := 0;
  For I := 0 To MaxUrls - 1 Do
  Begin
    S := IniGet('Adresses', 'U' + IStr(I), '');
    If S <> '' Then
    Begin
      Urls[UrlN] := S; Inc(UrlN);
    End;
  End;
End;

Procedure UrlsRemember(Const U : String);
Var I, K : LongInt;
Begin
  UrlsLoad;
  K := -1;
  For I := 0 To UrlN - 1 Do
    If Urls[I] = U Then K := I;
  If K < 0 Then
  Begin
    If UrlN < MaxUrls Then Inc(UrlN);
    K := UrlN - 1;
  End;
  For I := K DownTo 1 Do Urls[I] := Urls[I - 1];
  Urls[0] := U;
  For I := 0 To UrlN - 1 Do IniSet('Adresses', 'U' + IStr(I), Urls[I]);
End;

{ nom du dossier d'apres une URL (.../projet/trunk -> projet) }
Function UrlDirName(S : String) : String;
Var K : LongInt; T : String;
Begin
  While (S <> '') And (S[Length(S)] = '/') Do Delete(S, Length(S), 1);
  K := Length(S);
  While (K > 0) And (S[K] <> '/') Do Dec(K);
  T := Copy(S, K + 1, 255);
  If (LowStr(T) = 'trunk') And (K > 1) Then
  Begin
    Delete(S, K, 255);
    K := Length(S);
    While (K > 0) And (S[K] <> '/') Do Dec(K);
    T := Copy(S, K + 1, 255);
  End;
  If Pos(':', T) > 0 Then T := '';
  UrlDirName := Utf8ToAnsi(UrlDec(T));
End;

Function DirEmpty(Const D : String) : Boolean;
Var SR : TSRec; N : LongInt; Ok : Boolean;
Begin
  N := 0;
  Ok := FsFirst(JoinDirS(D, '*'), SR);
  While Ok Do
  Begin
    If (SR.Name <> '.') And (SR.Name <> '..') Then Inc(N);
    Ok := FsNext(SR);
  End;
  FsClose(SR);
  DirEmpty := N = 0;
End;

Procedure CheckPathFromUrl;
Var N : String;
Begin
  If PathEdited Then Exit;
  N := UrlDirName(DText(IdUrl));
  DlgSync := True;
  If N <> '' Then SetText(DCt[IdPath], JoinDirS(CheckRoot, N))
  Else SetText(DCt[IdPath], CheckRoot);
  DlgSync := False;
End;

{ ---- extraire (checkout) ---- }

Function CheckoutDialog : Boolean;
Const W = 500; H = 346;
Var I : LongInt;
Begin
  CheckoutDialog := False;
  DlgKind := DgCheckout;
  PathEdited := False; DlgSync := False;
  If DlgCreate('Extraire une copie de travail', W, H) = 0 Then Exit;
  Lbl(DlgWnd, 'Adresses utilis'#233'es r'#233'cemment :', 12, 10, W - 24);
  DCt[IdList] := Ctl(DlgWnd, 'LISTBOX', '', WS_BORDER Or WS_VSCROLL Or
    LBS_NOTIFY Or WS_TABSTOP, 12, 30, W - 24, 104, IdList);
  UrlsLoad;
  For I := 0 To UrlN - 1 Do Dummy0 := LbAdd(DCt[IdList], Urls[I]);
  Lbl(DlgWnd, 'URL du d'#233'p'#244't (svn://, http:// ou https://) :', 12,
    146, W - 24);
  Dummy := DEdit(IdUrl, 12, 166, W - 24, '', False);
  Lbl(DlgWnd, 'Dossier de la copie de travail :', 12, 200, W - 24);
  Dummy := DEdit(IdPath, 12, 220, W - 136, CheckRoot, False);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Parcourir...', WS_TABSTOP, W - 116, 218,
    104, 26, IdBrowse);
  Lbl(DlgWnd, 'Exemple : svn://serveur/projet/trunk', 12, 256, W - 24);
  DButtons(W, H, 'Extraire');
  DlgShow;
  WFocus(DCt[IdUrl]);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    OpUrl := DlgOut[0]; OpDir := DlgOut[1];
    CheckoutDialog := True;
  End;
End;

Procedure CheckoutCommand(Id, Code : LongInt);
Var I : LongInt; S, P : String;
Begin
  Case Id Of
    IdList :
      If (Code = LBN_SELCHANGE) Or (Code = LBN_DBLCLK) Then
      Begin
        I := LbSel(DCt[IdList]);
        If (I >= 0) And (I < UrlN) Then
        Begin
          PathEdited := False;
          SetText(DCt[IdUrl], Urls[I]);
          CheckPathFromUrl;
        End;
      End;
    IdUrl : If Code = EN_CHANGE Then CheckPathFromUrl;
    IdPath : If (Code = EN_CHANGE) And Not DlgSync Then PathEdited := True;
    IdBrowse :
    Begin
      S := CheckRoot;
      If BrowseFolder('Dossier de la copie de travail', S) Then
      Begin
        P := UrlDirName(DText(IdUrl));
        If P <> '' Then S := JoinDirS(S, P);
        DlgSync := True;
        SetText(DCt[IdPath], S);
        DlgSync := False;
        PathEdited := True;
      End;
    End;
    IDOK :
    Begin
      S := DText(IdUrl);
      P := DText(IdPath);
      If Not UrlSplit(S) Then
      Begin
        ErrBox('Entrez une URL de d'#233'p'#244't Subversion valable ' +
          '(svn://..., http://... ou https://...).');
        Exit;
      End;
      If (P = '') Or (Pos(':', P) = 0) Then
      Begin
        ErrBox('Entrez un chemin local complet (par exemple ' + DefRoot +
          '\projet).');
        Exit;
      End;
      If DirExist(P) And Not DirEmpty(P) Then
      Begin
        ErrBox('Le dossier ' + P + ' existe d'#233'j'#224' et n''est pas ' +
          'vide.');
        Exit;
      End;
      DlgOut[0] := S; DlgOut[1] := P;
      DlgRes := IDOK; DlgDone := True;
    End;
    IDCANCEL :
    Begin
      DlgRes := IDCANCEL; DlgDone := True;
    End;
  End;
End;

{ ---- ajouter une copie de travail existante ---- }

Function AddLocalDialog : Boolean;
Const W = 460; H = 124;
Begin
  AddLocalDialog := False;
  DlgKind := DgAdd;
  If DlgCreate('Ajouter une copie de travail', W, H) = 0 Then Exit;
  Lbl(DlgWnd, 'Dossier de la copie de travail :', 12, 12, W - 24);
  Dummy := DEdit(IdPath, 12, 32, W - 136, CheckRoot, False);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Parcourir...', WS_TABSTOP, W - 116, 30,
    104, 26, IdBrowse);
  DButtons(W, H, 'Ajouter');
  DlgShow;
  WFocus(DCt[IdPath]);
  SelAllText(DCt[IdPath]);
  ModalLoop;
  AddLocalDialog := DlgRes = IDOK;
End;

{ ---- options ---- }

Function OptionsDialog : Boolean;
Const W = 500; H = 258;
Begin
  OptionsDialog := False;
  DlgKind := DgOptions;
  If DlgCreate('Options', W, H) = 0 Then Exit;
  Dummy := Ctl(DlgWnd, 'BUTTON', 'R'#233'seau', BS_GROUPBOX, 8, 6, W - 16,
    70, 0);
  Lbl(DlgWnd, 'Proxy HTTP (h'#244'te:port, vide = connexion directe) :', 20,
    24, W - 40);
  Dummy := DEdit(IdProxy, 20, 44, W - 40, ProxyStr, False);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Dossiers', BS_GROUPBOX, 8, 84, W - 16, 72,
    0);
  Lbl(DlgWnd, 'Dossier des copies de travail par d'#233'faut :', 20, 102,
    W - 40);
  Dummy := DEdit(IdRoot, 20, 122, W - 144, CheckRoot, False);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Parcourir...', WS_TABSTOP, W - 120, 120,
    100, 26, IdBrowse);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Oublier les mots de passe enregistr'#233
    + 's', WS_TABSTOP, 8, 168, 320, 28, IdForget);
  DButtons(W, H, 'Enregistrer');
  DlgShow;
  WFocus(DCt[IdProxy]);
  ModalLoop;
  OptionsDialog := DlgRes = IDOK;
End;

Procedure OptionsCommand(Id, Code : LongInt);
Var S : String;
Begin
  Case Id Of
    IdBrowse :
    Begin
      S := DText(IdRoot);
      If BrowseFolder('Dossier des copies de travail', S) Then
        SetText(DCt[IdRoot], S);
    End;
    IdForget :
    Begin
      { efface toute l'application des identifiants dans OS2.INI }
      Dummy0 := PrfWriteProfileString(-1, Z(IniAuth), 0, 0);
      CredHost := ''; CredUser := ''; CredPass := '';
      Dummy := Ask('Les identifiants enregistr'#233's ont '#233't'#233' ' +
        'effac'#233's.', 'Options', MB_OK Or MB_ICONINFO);
    End;
    IDOK :
    Begin
      ProxyStr := DText(IdProxy);
      S := DText(IdRoot);
      If S <> '' Then CheckRoot := S;
      IniSet('Options', 'Proxy', ProxyStr);
      If ProxyStr = '' Then IniSet('Options', 'SansProxy', '1')
      Else IniSet('Options', 'SansProxy', '');
      IniSet('Options', 'Dossier', CheckRoot);
      DlgRes := IDOK; DlgDone := True;
    End;
    IDCANCEL :
    Begin
      DlgRes := IDCANCEL; DlgDone := True;
    End;
  End;
  If Code = 0 Then ;
End;

{ ---- identifiants ---- }

Function CredDialog(Const Url : String) : Boolean;
Const W = 420; H = 196;
Var Host : String;
Begin
  CredDialog := False;
  DlgKind := DgCred;
  Host := HostKey(Url);
  If DlgCreate('Authentification', W, H) = 0 Then Exit;
  Lbl(DlgWnd, 'Le serveur ' + Host + ' demande une identification.', 12,
    10, W - 24);
  Lbl(DlgWnd, 'Utilisateur :', 12, 44, 120);
  Dummy := DEdit(IdUser, 140, 40, W - 152, RemUser, False);
  Lbl(DlgWnd, 'Mot de passe :', 12, 76, 120);
  Dummy := DEdit(IdPass, 140, 72, W - 152, '', True);
  DCt[IdSave] := Ctl(DlgWnd, 'BUTTON', 'Enregistrer ces identifiants',
    BS_AUTOCHECKBOX Or WS_TABSTOP, 140, 106, W - 152, 20, IdSave);
  DButtons(W, H, 'OK');
  DlgShow;
  If RemUser <> '' Then WFocus(DCt[IdPass]) Else WFocus(DCt[IdUser]);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    CredHost := Host;
    CredUser := DlgOut[0]; CredPass := DlgOut[1];
    If DlgOut[2] = '1' Then
    Begin
      IniSet('Identifiants', Host + '.Utilisateur', CredUser);
      IniSet('Identifiants', Host + '.MotDePasse', CredPass);
    End;
    CredDialog := True;
  End;
End;

Procedure DlgCommand(Id, Code : LongInt);
Var S : String;
Begin
  If DlgKind = DgCheckout Then
  Begin
    CheckoutCommand(Id, Code); Exit;
  End;
  If DlgKind = DgOptions Then
  Begin
    OptionsCommand(Id, Code); Exit;
  End;
  If DlgKind = DgBrowse Then
  Begin
    BrowseCommand(Id, Code); Exit;
  End;
  Case Id Of
    IdBrowse :
    Begin
      S := DText(IdPath);
      If BrowseFolder('Choisissez un dossier', S) Then
        SetText(DCt[IdPath], S);
    End;
    IDOK :
    Begin
      Case DlgKind Of
        DgInput : DlgText := CtlText(InpEdit);
        DgAdd : DlgOut[0] := DText(IdPath);
        DgCred :
        Begin
          DlgOut[0] := DText(IdUser); DlgOut[1] := CtlText(DCt[IdPass]);
          If Checked(DCt[IdSave]) Then DlgOut[2] := '1' Else DlgOut[2] := '0';
        End;
      End;
      DlgRes := IDOK; DlgDone := True;
    End;
    IDCANCEL :
    Begin
      DlgRes := IDCANCEL; DlgDone := True;
    End;
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
      If H = DlgWnd Then
      Begin
        BigLock;
        DlgCommand(Mp1 And $FFFF, 0);
        BigUnlock;
      End;
    PM_WM_CONTROL :
      If H = DlgWnd Then
      Begin
        Id := Mp1 And $FFFF;
        If Id <= 255 Then K := CtlKind[Id] Else K := 0;
        Code := -1;
        Case K Of
          1 : If ((Mp1 Shr 16) And $FFFF) = PM_BN_CLICKED Then
                Code := BN_CLICKED;
          2 : If ((Mp1 Shr 16) And $FFFF) = PM_EN_CHANGE Then Code := EN_CHANGE;
          3 :
            If ((Mp1 Shr 16) And $FFFF) = PM_LN_SELECT Then
              Code := LBN_SELCHANGE
            Else If ((Mp1 Shr 16) And $FFFF) = PM_LN_ENTER Then
              Code := LBN_DBLCLK;
        End;
        If (Code >= 0) And (Code <> BN_CLICKED) Then
        Begin
          BigLock;
          DlgCommand(Id, Code);
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
      If H = DlgWnd Then
      Begin
        DlgRes := IDCANCEL; DlgDone := True;
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
  TbH = 52; StH = 22; TabH = 26; ChkH = 24; ComH = 176; HdrH = 72;
  FilesH = 130;
  IdSum = 20; IdDescE = 21; IdCommit = 22;
  IdWCheck = 23; IdWAdd = 25;
  CmAddRepo = 102; CmCheckout = 103; CmOptions = 104; CmExit = 105;
  CmCheckAll = 111; CmUncheckAll = 112; CmDiscardAll = 113;
  CmCopyPath = 114; CmIgnore = 115; CmDiscardOne = 116; CmOpenFile = 117;
  CmResolve = 118;
  CmViewChg = 121; CmViewHist = 122; CmRepoList = 123; CmBranchList = 124;
  CmRefresh = 125;
  CmUpdate = 132; CmCheckUpd = 133; CmExplorer = 134; CmDos = 135;
  CmInfo = 136; CmRemoveRepo = 137; CmCleanup = 138; CmCopyUrl = 139;
  CmNewBranch = 141; CmSwitchUrl = 142;
  CmAbout = 151; CmKeys = 152;
  CmBr = 1000; CmRepo = 2000;
  MaxHole = 12;

Var
  MainMenu, MFile, MEdit, MView, MRepo, MBranch, MHelp : LongInt;
  ESum, EDesc, BCommit, BWCheck, BWAdd : LongInt;
  CW0, CH0, LX, CY0, CY1 : LongInt;
  TbDown : LongInt;
  Unchk : Array[0..199] Of String[120];
  UnchkN : LongInt;
  BrList : Array[0..199] Of String[120];
  BrN : LongInt;
  Refreshing : Boolean;
  LastRefresh : LongInt;
  CurBranch, WcRelP : String;
  { cadres creux des vues (4 nombres par cadre) et trous des fenetres
    enfants (le fond de la fenetre principale est peint autour) }
  FrN : LongInt;
  FrA : Array[0..15] Of LongInt;
  HoleN : LongInt;
  HoleX1, HoleY1, HoleX2, HoleY2 : Array[0..MaxHole - 1] Of LongInt;

Procedure Layout; Forward;

Procedure HoleAdd(X, Y, W, Hh : LongInt);
Begin
  If HoleN >= MaxHole Then Exit;
  HoleX1[HoleN] := X; HoleY1[HoleN] := Y;
  HoleX2[HoleN] := X + W; HoleY2[HoleN] := Y + Hh;
  Inc(HoleN);
End;

{ fenetre enfant placee (et son trou) }
Procedure PlaceH(H, X, Y, W, Hh : LongInt);
Begin
  Place(H, X, Y, W, Hh);
  HoleAdd(X, Y, W, Hh);
End;

{ place une vue dans un cadre creux (2 points) }
Procedure PlaceF(H, X, Y, W, Hh : LongInt);
Begin
  PlaceH(H, X + 2, Y + 2, W - 4, Hh - 4);
  If FrN < 4 Then
  Begin
    FrA[FrN * 4] := X; FrA[FrN * 4 + 1] := Y; FrA[FrN * 4 + 2] := X + W;
    FrA[FrN * 4 + 3] := Y + Hh;
    Inc(FrN);
  End;
End;

{ rectangle plein, sauf sur les fenetres enfants (pas de WS_CLIPCHILDREN
  dans OS/2-0) }
Procedure BarHoles(Dc, X1, Y1, X2, Y2, C, From : LongInt);
Var I, J : LongInt;
Begin
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  J := -1;
  For I := HoleN - 1 DownTo From Do
    If (HoleX1[I] < X2) And (HoleX2[I] > X1) And (HoleY1[I] < Y2) And
       (HoleY2[I] > Y1) Then J := I;
  If J < 0 Then
  Begin
    Bar(Dc, X1, Y1, X2, Y2, C);
    Exit;
  End;
  BarHoles(Dc, X1, Y1, X2, MaxL(Y1, HoleY1[J]), C, J + 1);
  BarHoles(Dc, X1, MinL(Y2, HoleY2[J]), X2, Y2, C, J + 1);
  BarHoles(Dc, X1, MaxL(Y1, HoleY1[J]), MaxL(X1, HoleX1[J]),
    MinL(Y2, HoleY2[J]), C, J + 1);
  BarHoles(Dc, MinL(X2, HoleX2[J]), MaxL(Y1, HoleY1[J]), X2,
    MinL(Y2, HoleY2[J]), C, J + 1);
End;

Procedure InvalidateStatus;
Begin
  If MainWnd = 0 Then Exit;
  InvalRect(MainWnd, 0, CH0 - StH, CW0, CH0);
  InvalRect(MainWnd, 0, 0, CW0, TbH);
End;

Procedure PaintNow;
Begin
  InvalidateStatus;
  If MainWnd <> 0 Then Dummy0 := WinUpdateWindow(MainWnd);
End;

Procedure SetStatus(Const S : String);
Begin
  StatusTxt := S;
  InvalidateStatus;
End;

Procedure Redraw;
Begin
  Inval(MainWnd);
  LvRepaint(LvChg); LvRepaint(LvHist); LvRepaint(LvFiles);
  DiffRepaint;
End;

Function CheckedCount : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To Chg.N - 1 Do
    If (Chg.E^[I].Flag And FlSel) <> 0 Then Inc(N);
  CheckedCount := N;
End;

Procedure UpdateCommitBtn;
Var S : String;
Begin
  If BCommit = 0 Then Exit;
  If CurBranch <> '' Then S := 'Valider dans ' + CurBranch
  Else S := 'Valider';
  SetText(BCommit, Fit(S, LX - 34));
  Dummy0 := WinEnableWindow(BCommit, Ord((CheckedCount > 0) And
    (TrimS(CtlText(ESum)) <> '') And Not Busy));
End;

Procedure CheckedChanged;
Begin
  InvalRect(MainWnd, 0, CY0 + TabH, LX, CY0 + TabH + ChkH);
  UpdateCommitBtn;
End;

Procedure UpdateTitle;
Begin
  If RepoCur >= 0 Then SetText(MainWnd, 'Client SVN - ' + RepoTitle(RepoCur))
  Else SetText(MainWnd, 'Client SVN');
End;

{ chemin d'un fichier du journal, relatif a la copie si possible }
Function HPath(Const P : String) : String;
Begin
  If P = '/' + WcRelP Then HPath := '(racine de la copie)'
  Else If (WcRelP <> '') And (Copy(P, 1, Length(WcRelP) + 2) = '/' + WcRelP +
     '/') Then HPath := Copy(P, Length(WcRelP) + 3, 255)
  Else If WcRelP = '' Then HPath := Copy(P, 2, 255)
  Else HPath := P;
End;

{ ---- selection ---- }

Procedure SelectChange(I : LongInt);
Begin
  ChgSel := I;
  If (I < 0) Or (I >= Chg.N) Then
  Begin
    DiffClear; Exit;
  End;
  DiffLoadWork(I);
End;

Procedure SelectFile(I : LongInt);
Begin
  FileSel := I;
  If (I < 0) Or (I >= HFiles.N) Or Busy Then
  Begin
    DiffClear; Exit;
  End;
  DiffLoadRev(I);
End;

Procedure SelectCommit(I : LongInt);
Var J, K : LongInt;
Begin
  HistSel := I;
  HFiles.N := 0; FileSel := -1;
  If (I >= 0) And (I < HistN) Then
    For J := Hist^[I].P0 To Hist^[I].P0 + Hist^[I].PN - 1 Do
      If J < LogP.N Then
      Begin
        K := FlatAdd(HFiles, LogP.E^[J].Path);
        HFiles.E^[K].Flag := LogP.E^[J].Flag;
        HFiles.E^[K].Mode := LogP.E^[J].Mode;
        HFiles.E^[K].Size := J;
      End;
  Lv[LvFiles].Top := 0;
  LvSync(LvFiles);
  LvRepaint(LvFiles);
  If HFiles.N > 0 Then SelectFile(0) Else DiffClear;
  InvalRect(MainWnd, LX, CY0, CW0, CY0 + HdrH);
End;

{ ---- actualisation de la copie de travail ---- }

Procedure RefreshRepo(Keep : Boolean);
Var I, K, N : LongInt; OldPath : String;
Begin
  If Refreshing Or Busy Then Exit;
  Refreshing := True;
  GitOom := False;
  LastRefresh := MsCount;
  OldPath := '';
  If Keep And (ChgSel >= 0) And (ChgSel < Chg.N) Then
    OldPath := Chg.E^[ChgSel].Path;
  UnchkN := 0;
  If Keep Then
    For I := 0 To Chg.N - 1 Do
      If ((Chg.E^[I].Flag And FlSel) = 0) And (UnchkN < 200) Then
      Begin
        Unchk[UnchkN] := Chg.E^[I].Path; Inc(UnchkN);
      End;
  Chg.N := 0; HFiles.N := 0;
  CurBranch := ''; WcRelP := '';
  ChgSel := -1; FileSel := -1;
  If Not Keep Then HistSel := -1;
  If RepoCur >= 0 Then
  Begin
    If Not WcLoad(RepoPath[RepoCur]) Then
    Begin
      ErrBox(RepoPath[RepoCur] + ' : ' + GitErr + '. Elle est retir'#233'e ' +
        'de la liste.');
      RepoRemove(RepoCur);
      ReposSave;
      HistClear; LogOk := False;
    End
    Else
    Begin
      SetPtr(SPTR_WAIT);
      SetStatus('Analyse de la copie de travail...');
      If Not WcStatus Then ErrBox('Lecture de la copie : ' + GitErr);
      WcRelP := WcRel;
      BranchSplit(WcRelP);
      CurBranch := Utf8ToAnsi(BrCur);
      If CurBranch = '' Then CurBranch := '(racine)';
      For I := 0 To Chg.N - 1 Do
        For K := 0 To UnchkN - 1 Do
          If Chg.E^[I].Path = Unchk[K] Then
            Chg.E^[I].Flag := Chg.E^[I].Flag And Not FlSel;
      If Chg.N > 0 Then
      Begin
        ChgSel := 0;
        If OldPath <> '' Then
        Begin
          K := FlatFind(Chg, OldPath);
          If K >= 0 Then ChgSel := K;
        End;
      End;
      SetPtr(SPTR_ARROW);
      N := 0;
      For I := 0 To Chg.N - 1 Do
        If (Chg.E^[I].Flag And $FF) = StConf Then Inc(N);
      If N > 0 Then SetStatus(IStr(N) + ' conflit(s) : corrigez les ' +
        'fichiers puis validez-les (ou Edition > Marquer comme r'#233'solu).')
      Else SetStatus(IStr(Chg.N) + ' fichier(s) modifi'#233'(s), r'#233'vision '
        + IStr(WcRev) + ', ' + Utf8ToAnsi(UrlDec(WcUrl)));
    End;
  End
  Else SetStatus('Aucune copie de travail ouverte');
  If View = VwChanges Then SelectChange(ChgSel)
  Else If (HistSel >= 0) And (HistSel < HistN) Then SelectCommit(HistSel)
  Else If HistN > 0 Then SelectCommit(0)
  Else DiffClear;
  For I := 0 To 2 Do LvSync(I);
  If ChgSel >= 0 Then LvVisible(LvChg);
  Layout;
  UpdateTitle;
  UpdateCommitBtn;
  Redraw;
  Refreshing := False;
End;

Procedure OpenRepo(K : LongInt);
Begin
  RepoCur := K;
  ReposSave;
  View := VwChanges;
  HistClear; LogOk := False; Incoming := 0; HHead := 0;
  RefreshRepo(False);
  { journal et revisions plus recentes (comme une recuperation) }
  If RepoCur >= 0 Then StartOp(OpLog);
End;

Procedure SetView(V : LongInt);
Begin
  If RepoCur < 0 Then Exit;
  View := V;
  If V = VwChanges Then SelectChange(ChgSel)
  Else If (HistSel < 0) And (HistN > 0) Then SelectCommit(0)
  Else SelectCommit(HistSel);
  Layout;
  Redraw;
End;

{ ---- disposition ---- }

Procedure Layout;
Var Has, Chgv : Boolean; Y, Ri, Rw : LongInt;
Begin
  If ESum = 0 Then Exit;
  Has := RepoCur >= 0;
  Chgv := Has And (View = VwChanges);
  LX := MinL(340, MaxL(232, CW0 Div 3));
  CY0 := TbH; CY1 := CH0 - StH;
  Ri := LX + 3; Rw := CW0 - Ri;
  FrN := 0; HoleN := 0;
  Show(Lv[LvChg].H, Chgv);
  Show(ESum, Chgv); Show(EDesc, Chgv); Show(BCommit, Chgv);
  Show(Lv[LvHist].H, Has And Not Chgv);
  Show(Lv[LvFiles].H, Has And Not Chgv);
  Show(DiffWnd, Has);
  Show(BWCheck, Not Has); Show(BWAdd, Not Has);
  If Chgv Then
  Begin
    Y := CY1 - ComH;
    PlaceF(Lv[LvChg].H, 0, CY0 + TabH + ChkH, LX, Y - CY0 - TabH - ChkH);
    PlaceH(ESum, 8, Y + 10, LX - 16, 24);
    PlaceH(EDesc, 8, Y + 40, LX - 16, 88);
    PlaceH(BCommit, 8, Y + 136, LX - 16, 30);
    PlaceF(DiffWnd, Ri, CY0, Rw, CY1 - CY0);
  End
  Else If Has Then
  Begin
    PlaceF(Lv[LvHist].H, 0, CY0 + TabH, LX, CY1 - CY0 - TabH);
    PlaceF(Lv[LvFiles].H, Ri, CY0 + HdrH, Rw, FilesH);
    PlaceF(DiffWnd, Ri, CY0 + HdrH + FilesH + 3, Rw,
      CY1 - CY0 - HdrH - FilesH - 3);
  End
  Else
  Begin
    Y := CY0 + 170;
    PlaceH(BWCheck, CW0 Div 2 - 200, Y, 400, 32);
    PlaceH(BWAdd, CW0 Div 2 - 200, Y + 42, 400, 32);
  End;
End;

{ ---- dessin ---- }

Function TbW : LongInt;
Begin
  TbW := MaxL(170, MinL(250, (CW0 - 4) Div 3));
End;

Function TbX(I : LongInt) : LongInt;
Begin
  If I < 3 Then TbX := I * TbW Else TbX := MaxL(3 * TbW, CW0);
End;

{ copie de travail : dossier avec une pastille verte (sous controle) }
Procedure IconRepo(Dc, X, Y : LongInt);
Begin
  Bar(Dc, X, Y + 3, X + 7, Y + 5, ClrBlack);
  Bar(Dc, X, Y + 5, X + 18, Y + 17, ClrBlack);
  Bar(Dc, X + 1, Y + 6, X + 17, Y + 16, ClrFolder);
  Bar(Dc, X + 1, Y + 4, X + 6, Y + 6, ClrFolder);
  Bar(Dc, X + 10, Y + 11, X + 18, Y + 19, ClrBlack);
  Bar(Dc, X + 11, Y + 12, X + 17, Y + 18, ClrGreen);
  Bar(Dc, X + 12, Y + 14, X + 13, Y + 16, ClrWin);
  Bar(Dc, X + 13, Y + 15, X + 16, Y + 16, ClrWin);
End;

Procedure IconBranch(Dc, X, Y : LongInt);
Begin
  Bar(Dc, X + 2, Y, X + 4, Y + 20, ClrBlack);
  Bar(Dc, X, Y, X + 6, Y + 4, ClrNavy);
  Bar(Dc, X, Y + 16, X + 6, Y + 20, ClrNavy);
  Bar(Dc, X + 10, Y + 2, X + 12, Y + 9, ClrBlack);
  Bar(Dc, X + 8, Y, X + 14, Y + 4, ClrNavy);
  Bar(Dc, X + 4, Y + 9, X + 12, Y + 11, ClrBlack);
End;

{ fleche vers le bas (mise a jour) ou les deux (verification) }
Procedure IconSync(Dc, X, Y, Kind : LongInt);
Var I : LongInt;
Begin
  If Kind = 0 Then
  Begin
    Bar(Dc, X + 3, Y + 4, X + 5, Y + 18, ClrBlack);
    For I := 0 To 3 Do Bar(Dc, X + 3 - I, Y + 4 + I, X + 5 + I, Y + 5 + I,
      ClrBlack);
  End;
  Bar(Dc, X + 11, Y + 2, X + 13, Y + 16, ClrBlack);
  For I := 0 To 3 Do Bar(Dc, X + 11 - I, Y + 16 - I, X + 13 + I,
    Y + 17 - I, ClrBlack);
End;

{ petite fleche de liste deroulante }
Procedure IconDrop(Dc, X, Y : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 3 Do Bar(Dc, X + I, Y + I, X + 7 - I, Y + I + 1, ClrBlack);
End;

Function AgoTxt(T : LongInt) : String;
Var M : LongInt;
Begin
  If T = 0 Then
  Begin
    AgoTxt := 'jamais'; Exit;
  End;
  M := (MsCount - T) Div 60000;
  If M < 1 Then AgoTxt := 'il y a moins d''une minute'
  Else If M < 60 Then AgoTxt := 'il y a ' + IStr(M) + ' min'
  Else AgoTxt := 'il y a ' + IStr(M Div 60) + ' h';
End;

Procedure PaintTb(Dc : LongInt);
Var I, X, X2 : LongInt; A, B : String;
Begin
  Bar(Dc, 0, 0, CW0, TbH - 2, ClrFace);
  Bar(Dc, 0, TbH - 2, CW0, TbH - 1, ClrShadow);
  Bar(Dc, 0, TbH - 1, CW0, TbH, ClrHi);
  For I := 0 To 2 Do
  Begin
    If (I = 2) And (RepoCur < 0) And Not Busy Then Break;
    X := TbX(I); X2 := TbX(I + 1) - 2;
    If I = 2 Then X2 := MinL(CW0 - 3, X + 280);
    If TbDown = I Then Bevel(Dc, X + 2, 3, X2, TbH - 5, False)
    Else Bevel(Dc, X + 2, 3, X2, TbH - 5, True);
    Case I Of
      0 :
      Begin
        IconRepo(Dc, X + 10, 13);
        A := 'Copie de travail actuelle';
        If RepoCur >= 0 Then B := RepoTitle(RepoCur) Else B := 'Aucune';
      End;
      1 :
      Begin
        IconBranch(Dc, X + 12, 13);
        A := 'Branche actuelle';
        If RepoCur < 0 Then B := '-' Else B := CurBranch;
      End;
    Else
      Begin
        If Busy Then
        Begin
          IconSync(Dc, X + 12, 14, 0);
          Case Op Of
            OpCheckout : A := 'Extraction';
            OpCommit : A := 'Validation';
            OpLog : A := 'Lecture du journal';
            OpSwitch : A := 'Changement de branche';
            OpBranch : A := 'Cr'#233'ation de la branche';
          Else
            A := 'Mise '#224' jour';
          End;
          B := ProgTxt;
        End
        Else If Incoming > 0 Then
        Begin
          IconSync(Dc, X + 12, 14, 0);
          A := 'Mettre '#224' jour  (' + IStr(Incoming) + ' nouvelle(s))';
          B := 'R'#233'vision ' + IStr(WcRev) + ' -> ' + IStr(HHead);
        End
        Else
        Begin
          IconSync(Dc, X + 12, 14, 1);
          A := 'Mettre '#224' jour';
          If LogOk Then B := 'R'#233'vision ' + IStr(WcRev) + ', v'#233'rifi'#233
            + 'e ' + AgoTxt(LastCheck)
          Else B := 'R'#233'vision ' + IStr(WcRev);
        End;
      End;
    End;
    TxtF(Dc, X + 36, 8, FitW(A, X2 - X - 54, SCW), ClrShadow, 1);
    Txt(Dc, X + 36, 26, Fit(B, X2 - X - 54), ClrBlack);
    If I < 2 Then IconDrop(Dc, X2 - 16, 24);
  End;
End;

{ onglets dans le style des carnets de PM }
Procedure PaintTabs(Dc : LongInt);
Var I, X, W, Y : LongInt; S : String;
Begin
  Bar(Dc, 0, CY0, LX, CY0 + TabH, ClrFace);
  W := (LX - 8) Div 2;
  For I := 0 To 1 Do
  Begin
    X := 4 + I * W;
    If I = 0 Then S := 'Modifications (' + IStr(Chg.N) + ')'
    Else S := 'Historique';
    If I = View Then Y := CY0 + 3 Else Y := CY0 + 6;
    Bar(Dc, X, Y, X + W - 1, Y + 1, ClrHi);
    Bar(Dc, X, Y, X + 1, CY0 + TabH, ClrHi);
    Bar(Dc, X + W - 2, Y + 1, X + W - 1, CY0 + TabH, ClrShadow);
    Bar(Dc, X + W - 1, Y + 2, X + W, CY0 + TabH, ClrDark);
    { petite police quand le titre ne tient pas dans l'onglet }
    If Length(S) * CW <= W - 6 Then
      Txt(Dc, X + (W - Length(S) * CW) Div 2, Y + 4, S, ClrBlack)
    Else
    Begin
      S := FitW(S, W - 6, SCW);
      TxtF(Dc, X + (W - Length(S) * SCW) Div 2, Y + 4, S, ClrBlack, 1);
    End;
  End;
  Bar(Dc, 0, CY0 + TabH - 1, LX, CY0 + TabH, ClrHi);
  X := 4 + View * W;
  Bar(Dc, X + 1, CY0 + TabH - 1, X + W - 2, CY0 + TabH, ClrFace);
End;

Procedure PaintCommitHdr(Dc : LongInt);
Var S : String;
Begin
  If (HistSel < 0) Or (HistSel >= HistN) Then Exit;
  Txt(Dc, LX + 12, CY0 + 6, Fit(Utf8ToAnsi(HistSummary(HistSel)),
    CW0 - LX - 24), ClrBlack);
  Txt(Dc, LX + 12, CY0 + 26, Fit(Hist^[HistSel].Author + '   ' +
    UnixToStr(Hist^[HistSel].Time) + ' UTC', CW0 - LX - 24), ClrNavy);
  S := 'R'#233'vision ' + IStr(Hist^[HistSel].Rev) + '   ' + IStr(HFiles.N) +
    ' chemin(s) modifi'#233'(s)';
  If Hist^[HistSel].Rev > WcRev Then S := S + '   (pas encore dans la copie)';
  Txt(Dc, LX + 12, CY0 + 46, Fit(S, CW0 - LX - 24), ClrShadow);
End;

Procedure PaintWelcome(Dc : LongInt);
Var Y : LongInt; S : String;
Begin
  Y := CY0 + 40;
  IconRepo(Dc, CW0 Div 2 - 9, Y);
  S := 'Bienvenue dans le Client SVN';
  Txt(Dc, MaxL(4, (CW0 - Length(S) * CW) Div 2), Y + 34, S, ClrBlack);
  S := 'Extrayez une copie de travail d''un d'#233'p'#244't Subversion';
  Txt(Dc, MaxL(4, (CW0 - Length(S) * CW) Div 2), Y + 66, S, ClrShadow);
  S := '(svn://, http://, https://) ou ajoutez une copie existante.';
  Txt(Dc, MaxL(4, (CW0 - Length(S) * CW) Div 2), Y + 84, S, ClrShadow);
End;

Procedure MainPaint(H : LongInt);
Var Dc, N, Y, I : LongInt; S : String;
Begin
  Dc := PaintBegin(H);
  { fond, autour des fenetres enfants }
  BarHoles(Dc, 0, TbH, CW0, CH0 - StH, ClrFace, 0);
  If RepoCur >= 0 Then
    For I := 0 To FrN - 1 Do
      Bevel(Dc, FrA[I * 4], FrA[I * 4 + 1], FrA[I * 4 + 2], FrA[I * 4 + 3],
        False);
  PaintTb(Dc);
  If RepoCur < 0 Then PaintWelcome(Dc)
  Else
  Begin
    PaintTabs(Dc);
    If View = VwChanges Then
    Begin
      Y := CY0 + TabH;
      N := CheckedCount;
      CheckBox(Dc, 5, Y + 5, N > 0, (N > 0) And (N < Chg.N));
      S := IStr(Chg.N) + ' fichier(s) modifi'#233'(s)';
      If (N <> Chg.N) Then S := S + ', ' + IStr(N) + ' coch'#233'(s)';
      Txt(Dc, 24, Y + 4, Fit(S, LX - 30), ClrBlack);
      Bar(Dc, 0, CY1 - ComH, LX, CY1 - ComH + 1, ClrShadow);
      Bar(Dc, 0, CY1 - ComH + 1, LX, CY1 - ComH + 2, ClrHi);
    End
    Else PaintCommitHdr(Dc);
  End;
  { barre d'etat }
  Bar(Dc, 0, CH0 - StH, CW0, CH0, ClrFace);
  Thin(Dc, 2, CH0 - StH + 2, CW0 - 2, CH0 - 1, False);
  If Busy Then S := ProgLine Else S := StatusTxt;
  Txt(Dc, 6, CH0 - StH + 3, Fit(S, CW0 - 12), ClrBlack);
  PaintEnd(Dc);
End;

{ ---- menus ---- }

Procedure BuildMenus;
Begin
  MainMenu := CreateMenu;
  MFile := CreatePopupMenu;
  MItem(MFile, CmCheckout, '~Extraire une copie de travail...'#9 +
    'Ctrl+Maj+O');
  MItem(MFile, CmAddRepo, '~Ajouter une copie de travail...'#9'Ctrl+O');
  MItem(MFile, 0, '');
  MItem(MFile, CmOptions, '~Options...');
  MItem(MFile, 0, '');
  MItem(MFile, CmExit, '~Quitter'#9'F3');
  MSub(MainMenu, MFile, '~Fichier');
  MEdit := CreatePopupMenu;
  MItem(MEdit, CmCheckAll, '~Cocher tous les fichiers'#9'Ctrl+A');
  MItem(MEdit, CmUncheckAll, '~D'#233'cocher tous les fichiers');
  MItem(MEdit, 0, '');
  MItem(MEdit, CmCopyPath, 'Copier le ~chemin du fichier');
  MItem(MEdit, CmOpenFile, '~Ouvrir le fichier');
  MItem(MEdit, CmIgnore, 'Ajouter '#224' svn:i~gnore');
  MItem(MEdit, CmResolve, 'Marquer comme ~r'#233'solu'#9'Ctrl+R');
  MItem(MEdit, 0, '');
  MItem(MEdit, CmDiscardOne, '~Annuler les modifications du fichier...');
  MItem(MEdit, CmDiscardAll, 'Annuler ~toutes les modifications...'#9 +
    'Ctrl+Maj+Suppr');
  MSub(MainMenu, MEdit, #201'~dition');
  MView := CreatePopupMenu;
  MItem(MView, CmViewChg, '~Modifications'#9'Ctrl+1');
  MItem(MView, CmViewHist, '~Historique'#9'Ctrl+2');
  MItem(MView, 0, '');
  MItem(MView, CmRepoList, 'Liste des ~copies de travail'#9'Ctrl+T');
  MItem(MView, CmBranchList, 'Liste des ~branches'#9'Ctrl+B');
  MItem(MView, 0, '');
  MItem(MView, CmRefresh, '~Actualiser'#9'F5');
  MSub(MainMenu, MView, '~Affichage');
  MRepo := CreatePopupMenu;
  MItem(MRepo, CmUpdate, '~Mettre '#224' jour'#9'Ctrl+Maj+P');
  MItem(MRepo, CmCheckUpd, '~Rechercher les nouvelles r'#233'visions'#9 +
    'Ctrl+Maj+T');
  MItem(MRepo, 0, '');
  MItem(MRepo, CmExplorer, 'Ouvrir dans l''~Explorateur'#9'Ctrl+Maj+F');
  MItem(MRepo, CmDos, 'Ouvrir dans l''~invite de commandes');
  MItem(MRepo, CmCopyUrl, 'Copier l''~URL du d'#233'p'#244't');
  MItem(MRepo, 0, '');
  MItem(MRepo, CmInfo, '~Informations...');
  MItem(MRepo, CmCleanup, '~Nettoyer');
  MItem(MRepo, CmRemoveRepo, 'Retirer de la ~liste');
  MSub(MainMenu, MRepo, '~Copie de travail');
  MBranch := CreatePopupMenu;
  MItem(MBranch, CmNewBranch, '~Nouvelle branche...'#9'Ctrl+Maj+N');
  MItem(MBranch, CmBranchList, '~Changer de branche...'#9'Ctrl+B');
  MItem(MBranch, CmSwitchUrl, 'Changer d''~URL (switch)...');
  MSub(MainMenu, MBranch, '~Branche');
  MHelp := CreatePopupMenu;
  MItem(MHelp, CmKeys, '~Raccourcis clavier');
  MItem(MHelp, 0, '');
  MItem(MHelp, CmAbout, '~A propos du Client SVN...');
  MSub(MainMenu, MHelp, '~Aide');
  SetMenu(MainMenu);
End;

Procedure MenuState;
Var Has, Free : Boolean; I : LongInt;
Begin
  Has := RepoCur >= 0;
  Free := Not Busy;
  For I := CmCheckAll To CmResolve Do MEnable(MEdit, I, Has And Free);
  MEnable(MView, CmViewChg, Has); MEnable(MView, CmViewHist, Has);
  MEnable(MView, CmBranchList, Has And Free);
  MEnable(MView, CmRefresh, Has And Free);
  For I := CmUpdate To CmCopyUrl Do MEnable(MRepo, I, Has And Free);
  For I := CmNewBranch To CmSwitchUrl Do MEnable(MBranch, I, Has And Free);
  MEnable(MBranch, CmBranchList, Has And Free);
  MEnable(MFile, CmAddRepo, Free);
  MEnable(MFile, CmCheckout, Free);
End;
{ ---- commandes ---- }

{ aucune modification suivie (les fichiers non suivis sont permis) }
Function Clean : Boolean;
Var I : LongInt;
Begin
  Clean := True;
  For I := 0 To Chg.N - 1 Do
    If (Chg.E^[I].Flag And $FF) <> StUnv Then Clean := False;
End;

Procedure DoCommitCmd;
Var S, D : String; I : LongInt;
Begin
  If Busy Or (RepoCur < 0) Then Exit;
  S := TrimS(CtlText(ESum));
  If S = '' Then
  Begin
    ErrBox('Entrez un r'#233'sum'#233' pour cette validation.'); Exit;
  End;
  If CheckedCount = 0 Then
  Begin
    ErrBox('Cochez au moins un fichier '#224' valider.'); Exit;
  End;
  For I := 0 To Chg.N - 1 Do
    If ((Chg.E^[I].Flag And FlSel) <> 0) And
       ((Chg.E^[I].Flag And $FF) = StConf) And
       HasConflictMark(WorkPath(Chg.E^[I].Path)) Then
    Begin
      ErrBox('Le fichier ' + Utf8ToAnsi(Chg.E^[I].Path) + ' contient encore ' +
        'des marqueurs de conflit (<<<<<<< ======= >>>>>>>). Corrigez-le ' +
        'avant de valider.');
      Exit;
    End;
  OpMsg.N := 0;
  BufStr(OpMsg, AnsiToUtf8(S));
  D := CtlText(EDesc);
  If TrimS(D) <> '' Then
  Begin
    BufStr(OpMsg, #10#10);
    For I := 1 To Length(D) Do
      If D[I] <> #13 Then BufStr(OpMsg, AnsiToUtf8(D[I]));
  End;
  StartOp(OpCommit);
End;

Procedure DiscardCmd(One : Boolean);
Var I : LongInt; Q : String;
Begin
  If Chg.N = 0 Then Exit;
  If One Then
  Begin
    If (ChgSel < 0) Or (ChgSel >= Chg.N) Then Exit;
    Q := 'Annuler les modifications de ' + Utf8ToAnsi(Chg.E^[ChgSel].Path) +
      ' ?';
  End
  Else Q := 'Annuler toutes les modifications (' + IStr(Chg.N) +
    ' fichier(s)) ?';
  If Ask(Q + #13#10'Les fichiers non suivis sont supprim'#233's. Cette ' +
    'op'#233'ration est irr'#233'versible.', 'Annuler les modifications',
    MB_YESNO Or MB_ICONWARNING) <> IDYES Then Exit;
  For I := 0 To Chg.N - 1 Do
    If One And (I <> ChgSel) Then
      Chg.E^[I].Flag := Chg.E^[I].Flag And Not FlSel
    Else Chg.E^[I].Flag := Chg.E^[I].Flag Or FlSel;
  If Not WcRevert Then ErrBox('Annulation incompl'#232'te : ' + GitErr);
  RefreshRepo(False);
End;

Procedure IgnoreCmd;
Var St : LongInt;
Begin
  If (ChgSel < 0) Or (ChgSel >= Chg.N) Then Exit;
  St := Chg.E^[ChgSel].Flag And $FF;
  If St <> StUnv Then
  Begin
    ErrBox('Seul un fichier non suivi (nouveau, pas encore valid'#233') ' +
      'peut '#234'tre ajout'#233' '#224' svn:ignore.');
    Exit;
  End;
  WcIgnore(Chg.E^[ChgSel].Path);
  RefreshRepo(True);
  SetStatus('svn:ignore modifi'#233' : validez la propri'#233't'#233' du ' +
    'dossier pour l''enregistrer sur le serveur.');
End;

Procedure ResolveCmd;
Var K : LongInt;
Begin
  If (ChgSel < 0) Or (ChgSel >= Chg.N) Then Exit;
  If (Chg.E^[ChgSel].Flag And $FF) <> StConf Then
  Begin
    ErrBox('Ce fichier n''est pas en conflit.'); Exit;
  End;
  K := EntFind(Chg.E^[ChgSel].Path);
  If K < 0 Then Exit;
  If HasConflictMark(WorkPath(Chg.E^[ChgSel].Path)) Then
    If Ask('Le fichier contient encore des marqueurs de conflit. Le ' +
      'marquer comme r'#233'solu quand m'#234'me ?', 'Marquer comme r'#233 +
      'solu', MB_YESNO Or MB_ICONWARNING) <> IDYES Then Exit;
  Resolve(K);
  WcSave;
  RefreshRepo(True);
End;

{ Invite de commandes d'OS/2-0 dans le dossier de la copie (sa propre
  session, comme le Client SSH) }
Procedure DosPrompt;
Var S, Rc, D : LongInt; P : String; Res : Array[0..1] Of LongInt;
    Fail : Array[0..63] Of Byte; Arg : Array[0..299] Of Byte;
Begin
  P := AppPath('CMD.EXE');
  If P = '' Then
  Begin
    ErrBox('CMD.EXE est introuvable.'); Exit;
  End;
  { dossier courant herite par l'Invite de commandes }
  PathZ(WcDir);
  D := Ord(UpCase(WcDir[1])) - 64;
  If (D >= 1) And (D <= 26) Then Dummy0 := DosSetDefaultDisk(D);
  Dummy0 := DosSetCurrentDir(LongInt(@FZ));
  PutZ(LongInt(@Arg), P);
  Arg[Length(P) + 1] := 0; Arg[Length(P) + 2] := 0;
  S := KSes(4, Z('CMD.EXE'), 0);
  If S >= 0 Then
  Begin
    Dummy0 := KSes(16, S, 1);
    Dummy0 := KSes(12, S, 0);
  End;
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@Fail), 64, 4, LongInt(@Arg), 0, LongInt(@Res),
    Z2(P));
  If S >= 0 Then
  Begin
    If Rc <> 0 Then
    Begin
      Dummy0 := KSes(12, -1, 0);
      Dummy0 := KSes(17, S, 0);
    End
    Else Dummy0 := KSes(3, S, 0);
  End;
  If Rc <> 0 Then ErrBox('Impossible de lancer l''Invite de commandes (' +
    IStr(Rc) + ').');
End;

Procedure UpdateCmd;
Begin
  If Busy Or (RepoCur < 0) Then Exit;
  StartOp(OpUpdate);
End;

{ changement de branche : URL complete }
Procedure SwitchTo(Const Url : String);
Begin
  If Busy Or (RepoCur < 0) Then Exit;
  If Not Clean Then
  Begin
    ErrBox('Vous avez des modifications non valid'#233'es. Validez-les ou ' +
      'annulez-les avant de changer de branche.');
    Exit;
  End;
  OpUrl := Url;
  StartOp(OpSwitch);
End;

Procedure SwitchUrlCmd;
Var S : String;
Begin
  S := Utf8ToAnsi(UrlDec(WcUrl));
  If Not InputBox('Changer d''URL (switch)', 'Nouvelle URL dans le m'#234 +
    'me d'#233'p'#244't :', S) Then Exit;
  S := UrlEnc(AnsiToUtf8(S));
  If Not UrlSplit(S) Then
  Begin
    ErrBox('URL non valable.'); Exit;
  End;
  SwitchTo(S);
End;

Function ValidBranch(Const S : String) : Boolean;
Var I : LongInt;
Begin
  ValidBranch := False;
  If (S = '') Or (S = '.') Or (S = '..') Then Exit;
  For I := 1 To Length(S) Do
    If (S[I] < ' ') Or (S[I] In ['/', '\', ':', '*', '?', '"', '<', '>',
       '|']) Then Exit;
  ValidBranch := True;
End;

Procedure NewBranchCmd;
Var S : String;
Begin
  If Busy Or (RepoCur < 0) Then Exit;
  If Not Clean Then
  Begin
    ErrBox('Validez ou annulez d''abord vos modifications : la branche ' +
      'est une copie de la r'#233'vision ' + IStr(WcRev) + ' du serveur.');
    Exit;
  End;
  S := '';
  If Not InputBox('Cr'#233'er une branche', 'Nom de la nouvelle branche ' +
    '(copie de ' + CurBranch + ', r'#233'vision ' + IStr(WcRev) + ') :', S)
  Then Exit;
  While Pos(' ', S) > 0 Do S[Pos(' ', S)] := '-';
  If Not ValidBranch(S) Then
  Begin
    ErrBox('Nom de branche non valable : ' + S); Exit;
  End;
  OpName := AnsiToUtf8(S);
  OpMsg.N := 0;
  BufStr(OpMsg, AnsiToUtf8('Cr'#233'ation de la branche ' + S));
  StartOp(OpBranch);
End;

Procedure InfoCmd;
Var S : String;
Begin
  S := 'Dossier : ' + WcDir + #13#10 +
    'URL : ' + Utf8ToAnsi(UrlDec(WcUrl)) + #13#10 +
    'Racine du d'#233'p'#244't : ' + Utf8ToAnsi(UrlDec(WcRoot)) + #13#10 +
    'UUID : ' + WcUuid + #13#10 +
    'R'#233'vision de la copie : ' + IStr(WcRev) + #13#10;
  If LogOk Then S := S + 'Derni'#232're r'#233'vision du d'#233'p'#244't : ' +
    IStr(HHead) + #13#10;
  S := S + #201'l'#233'ments suivis : ' + IStr(EntN);
  Dummy := Ask(S, 'Informations', MB_OK Or MB_ICONINFO);
End;

Procedure RepoListMenu(X, Y : LongInt);
Var M, I : LongInt;
Begin
  M := CreatePopupMenu;
  For I := 0 To RepoN - 1 Do
  Begin
    MItem(M, CmRepo + I, RepoTitle(I) + '   (' + RepoPath[I] + ')');
    If I = RepoCur Then MCheck(M, CmRepo + I, True);
  End;
  If RepoN > 0 Then MItem(M, 0, '');
  MItem(M, CmCheckout, '~Extraire une copie de travail...');
  MItem(M, CmAddRepo, '~Ajouter une copie de travail...');
  ToScreen(MainWnd, X, Y);
  TrackPopupMenu(M, X, Y);
End;

{ branches du serveur : trunk, branches/*, tags/* }
Procedure BranchListMenu(X, Y : LongInt);
Var M, I, J, Head : LongInt; L : TDirList; Ok : Boolean; D : String;
Begin
  If (RepoCur < 0) Or Busy Then Exit;
  BrN := 0;
  SetPtr(SPTR_WAIT);
  SetCreds(WcUrl);
  Ok := RaOpen(WcUrl) And RaLatest(Head);
  If Ok Then
  Begin
    BranchSplit(RaRel);
    DirInit(L);
    For J := 0 To 2 Do
    Begin
      Case J Of
        0 : D := '';
        1 : D := 'branches';
      Else
        D := 'tags';
      End;
      If J = 0 Then
      Begin
        If RaGetDir(BrBase, Head, L) Then
          For I := 0 To L.N - 1 Do
            If (L.E^[I].Kind = 'd') And (L.E^[I].Name = 'trunk') Then
            Begin
              BrList[BrN] := 'trunk'; Inc(BrN);
            End;
      End
      Else If RaGetDir(JoinP(BrBase, D), Head, L) Then
        For I := 0 To L.N - 1 Do
          If (L.E^[I].Kind = 'd') And (BrN < 200) Then
          Begin
            BrList[BrN] := D + '/' + L.E^[I].Name; Inc(BrN);
          End;
    End;
    DirFree(L);
  End;
  RaClose;
  HClose;
  SetPtr(SPTR_ARROW);
  M := CreatePopupMenu;
  If Not Ok Then MItem(M, CmRefresh, '(liste indisponible : ' +
    Copy(GitErr, 1, 60) + ')');
  For I := 0 To BrN - 1 Do
  Begin
    If (I > 0) And (Copy(BrList[I], 1, 5) <> Copy(BrList[I - 1], 1, 5)) Then
      MItem(M, 0, '');
    MItem(M, CmBr + I, Utf8ToAnsi(BrList[I]));
    If BrList[I] = BrCur Then MCheck(M, CmBr + I, True);
  End;
  MItem(M, 0, '');
  MItem(M, CmNewBranch, '~Nouvelle branche...');
  MItem(M, CmSwitchUrl, 'Changer d''~URL...');
  ToScreen(MainWnd, X, Y);
  TrackPopupMenu(M, X, Y);
End;

Procedure ChangesMenu(X, Y : LongInt);
Var M : LongInt;
Begin
  M := CreatePopupMenu;
  MItem(M, CmDiscardOne, '~Annuler les modifications...');
  MItem(M, CmIgnore, 'Ajouter '#224' svn:i~gnore');
  MItem(M, CmResolve, 'Marquer comme ~r'#233'solu');
  MItem(M, 0, '');
  MItem(M, CmCopyPath, 'Copier le ~chemin');
  MItem(M, CmOpenFile, '~Ouvrir le fichier');
  ToScreen(Lv[LvChg].H, X, Y);
  TrackPopupMenu(M, X, Y);
End;

Procedure AboutBox;
Begin
  Dummy := Ask('Client SVN pour OS/2-0'#13#10'Version 1.0'#13#10#13#10 +
    'Auteur : Sylvain Maltais'#13#10'Licence : MIT'#13#10#13#10 +
    'Subversion : svn:// (svnserve, CRAM-MD5) et http(s):// (WebDAV, ' +
    'protocole HTTP v2, TLS32), mise '#224' jour avec fusion '#224' trois ' +
    'voies, branches.'#13#10 +
    'Port'#233' du Client SVN de Pasdows 95, compil'#233' par OS/2 Pascal ' +
    'Compiler (OS2PC).', 'A propos du Client SVN', MB_OK Or MB_ICONINFO);
End;

Procedure KeysBox;
Begin
  Dummy := Ask('Ctrl+1 / Ctrl+2 : Modifications / Historique'#13#10 +
    'Ctrl+T / Ctrl+B : Copies de travail / Branches'#13#10 +
    'Ctrl+Maj+O : Extraire une copie de travail'#13#10 +
    'Ctrl+O : Ajouter une copie de travail'#13#10 +
    'Ctrl+Maj+P : Mettre '#224' jour'#13#10 +
    'Ctrl+Maj+T : Rechercher les nouvelles r'#233'visions'#13#10 +
    'Ctrl+Maj+N : Nouvelle branche'#13#10 +
    'Ctrl+R : Marquer comme r'#233'solu'#13#10 +
    'Ctrl+Entr'#233'e : Valider'#13#10'F5 : Actualiser'#13#10 +
    'Espace : Cocher ou d'#233'cocher le fichier', 'Raccourcis clavier',
    MB_OK Or MB_ICONINFO);
End;

Procedure DoMenu(Cmd : LongInt);
Var I, K : LongInt; P : String;
Begin
  If Busy And (Cmd <> CmExit) And (Cmd <> CmAbout) And (Cmd <> CmKeys) And
     (Cmd <> CmViewChg) And (Cmd <> CmViewHist) Then
  Begin
    Dummy0 := WinAlarm(HWND_DESKTOP, 0); Exit;
  End;
  If (Cmd >= CmRepo) And (Cmd < CmRepo + MaxRepo) Then
  Begin
    OpenRepo(Cmd - CmRepo); Exit;
  End;
  If (Cmd >= CmBr) And (Cmd < CmBr + 200) And (RepoCur >= 0) Then
  Begin
    I := Cmd - CmBr;
    If (I < BrN) And (BrList[I] <> BrCur) Then
      SwitchTo(WcRoot + '/' + UrlEnc(JoinP(BrBase, BrList[I])));
    Exit;
  End;
  Case Cmd Of
    CmCheckout : If CheckoutDialog Then StartOp(OpCheckout);
    CmAddRepo :
      If AddLocalDialog Then
      Begin
        P := DlgOut[0];
        If (Length(P) > 3) And (P[Length(P)] = '\') Then
          Delete(P, Length(P), 1);
        If Not WcLoad(P) Then
        Begin
          ErrBox(P + ' : ' + GitErr + '.');
          { la copie ouverte est relue (WcLoad a vide son etat) }
          RefreshRepo(True);
        End
        Else
        Begin
          K := RepoAdd(P);
          OpenRepo(K);
        End;
      End;
    CmOptions : If OptionsDialog Then RefreshRepo(True);
    CmExit : Dummy0 := WinPostMsg(MainWnd, PM_WM_CLOSE, 0, 0);
    CmCheckAll, CmUncheckAll :
    Begin
      For I := 0 To Chg.N - 1 Do
        If Cmd = CmCheckAll Then Chg.E^[I].Flag := Chg.E^[I].Flag Or FlSel
        Else Chg.E^[I].Flag := Chg.E^[I].Flag And Not FlSel;
      LvRepaint(LvChg);
      CheckedChanged;
    End;
    CmDiscardAll : DiscardCmd(False);
    CmDiscardOne : DiscardCmd(True);
    CmCopyPath :
      If (View = VwChanges) And (ChgSel >= 0) And (ChgSel < Chg.N) Then
        CopyToClip(WorkPath(Chg.E^[ChgSel].Path))
      Else If (View = VwHistory) And (FileSel >= 0) And (FileSel < HFiles.N)
      Then CopyToClip(Utf8ToAnsi(HFiles.E^[FileSel].Path));
    CmOpenFile :
      If (View = VwChanges) And (ChgSel >= 0) And (ChgSel < Chg.N) Then
        OpenLocal(WorkPath(Chg.E^[ChgSel].Path));
    CmIgnore : IgnoreCmd;
    CmResolve : ResolveCmd;
    CmViewChg : SetView(VwChanges);
    CmViewHist : SetView(VwHistory);
    CmRepoList : RepoListMenu(TbX(0) + 4, TbH - 4);
    CmBranchList : BranchListMenu(TbX(1) + 4, TbH - 4);
    CmRefresh : RefreshRepo(True);
    CmUpdate : UpdateCmd;
    CmCheckUpd : If RepoCur >= 0 Then StartOp(OpLog);
    CmExplorer :
    Begin
      P := AppPath('EXPLORER.EXE');
      If (P = '') Or Not RunPm(P, WcDir) Then
        ErrBox('Impossible de lancer l''Explorateur.');
    End;
    CmDos : DosPrompt;
    CmCopyUrl : CopyToClip(Utf8ToAnsi(UrlDec(WcUrl)));
    CmInfo : InfoCmd;
    CmCleanup :
    Begin
      WcCleanup;
      RefreshRepo(True);
      SetStatus('Copie de travail nettoy'#233'e (bases inutiles supprim'#233
        + 'es)');
    End;
    CmRemoveRepo :
      If Ask('Retirer ' + RepoTitle(RepoCur) + ' de la liste ?'#13#10 +
        '(Les fichiers ne sont pas supprim'#233's.)', 'Retirer la copie de ' +
        'travail', MB_YESNO Or MB_ICONQUESTION) = IDYES Then
      Begin
        RepoRemove(RepoCur);
        If RepoN > 0 Then RepoCur := 0;
        ReposSave;
        HistClear; LogOk := False; Incoming := 0;
        If RepoCur >= 0 Then OpenRepo(RepoCur) Else RefreshRepo(False);
      End;
    CmNewBranch : NewBranchCmd;
    CmSwitchUrl : SwitchUrlCmd;
    CmAbout : AboutBox;
    CmKeys : KeysBox;
  End;
End;

{ fin d'une operation reseau }
Procedure OpDone;
Var K, I : LongInt; Retry : Boolean; U, S : String;
Begin
  Busy := False;
  WorkTid := 0;
  Retry := False;
  If Op = OpCheckout Then U := OpUrl Else U := WcUrl;
  If Not OpOk And (Pos('(401)', GitErr) > 0) Then
  Begin
    SetCreds(U);
    Retry := CredDialog(U);
  End;
  If Retry Then
  Begin
    { recommence (dans un dossier vide pour une extraction) }
    If Op = OpCheckout Then RmTree(OpDir, 0);
    StartOp(Op);
    Exit;
  End;
  Case Op Of
    OpCheckout :
      If OpOk Then
      Begin
        UrlsRemember(OpUrl);
        K := RepoAdd(OpDir);
        OpenRepo(K);
        SetStatus('Extraction termin'#233'e : r'#233'vision ' + IStr(WcRev) +
          ', ' + IStr(EntN) + ' '#233'l'#233'ment(s) dans ' + OpDir);
      End
      Else
      Begin
        RmTree(OpDir, 0);
        ErrBox('Extraction impossible : ' + GitErr);
        RefreshRepo(True);
      End;
    OpUpdate, OpSwitch, OpBranch :
    Begin
      HistClear; LogOk := False; Incoming := 0;
      RefreshRepo(False);
      If OpOk Then
      Begin
        S := 'R'#233'vision ' + IStr(WcRev) + ' : ' + IStr(UpdFiles) +
          ' fichier(s) re'#231'u(s), ' + IStr(UpdDel) + ' supprim'#233'(s)';
        If Op = OpBranch Then S := 'Branche cr'#233#233'e et extraite. ' + S
        Else If Op = OpSwitch Then S := 'Branche ' + CurBranch + '. ' + S;
        SetStatus(S);
        If UpdConf > 0 Then
        Begin
          S := '';
          For I := 0 To Chg.N - 1 Do
            If ((Chg.E^[I].Flag And $FF) = StConf) And (Length(S) < 180) Then
              S := S + #13#10'  ' + Utf8ToAnsi(Chg.E^[I].Path);
          ErrBox('Mise '#224' jour : ' + IStr(UpdConf) + ' conflit(s). ' +
            'Corrigez les fichiers marqu'#233's (<<<<<<< ======= >>>>>>>) ' +
            'puis validez-les. Vos versions sont dans les fichiers .mine.' + S);
        End
        Else If UpdNote <> '' Then ErrBox(Utf8ToAnsi(UpdNote));
      End
      Else If Op = OpBranch Then ErrBox('Cr'#233'ation de la branche ' +
        'impossible : ' + GitErr)
      Else ErrBox('Mise '#224' jour impossible : ' + GitErr);
      If RepoCur >= 0 Then StartOp(OpLog);
    End;
    OpCommit :
      If OpOk Then
      Begin
        SetText(ESum, ''); SetText(EDesc, '');
        WFocus(Lv[LvChg].H);
        RefreshRepo(False);
        SetStatus('R'#233'vision ' + IStr(CNewRev) + ' valid'#233'e dans ' +
          CurBranch);
        StartOp(OpLog);
      End
      Else
      Begin
        If (Pos('out of date', GitErr) > 0) Or (Pos('ut-of-date', GitErr) >
          0) Or (Pos('Conflict', GitErr) > 0) Then
          ErrBox('Validation impossible : des fichiers ont chang'#233' sur ' +
            'le serveur depuis votre derni'#232're mise '#224' jour. Mettez '#224
            + ' jour (Ctrl+Maj+P) puis validez de nouveau.'#13#10'(' + GitErr +
            ')')
        Else ErrBox('Validation impossible : ' + GitErr);
        RefreshRepo(True);
      End;
    OpLog :
    Begin
      LogOk := OpOk;
      LastCheck := MsCount;
      If Not OpOk Then
      Begin
        HistClear;
        SetStatus('Journal indisponible : ' + GitErr);
      End;
      HistSel := -1;
      LvSync(LvHist);
      If (View = VwHistory) And (HistN > 0) Then SelectCommit(0);
    End;
  End;
  UpdateCommitBtn;
  Redraw;
End;

Procedure TbClick(X, Y : LongInt);
Var I : LongInt;
Begin
  If Y >= TbH Then Exit;
  For I := 0 To 2 Do
    If (X >= TbX(I)) And (X < TbX(I) + TbW - 2) Then
    Begin
      If (I = 2) And (RepoCur < 0) And Not Busy Then Exit;
      TbDown := I;
      PaintNow;
      Case I Of
        0 : If Not Busy Then RepoListMenu(TbX(0) + 4, TbH - 4);
        1 : If Not Busy Then BranchListMenu(TbX(1) + 4, TbH - 4);
        2 :
          If Busy Then
          Begin
            If Ask('Annuler l''op'#233'ration en cours ?', 'Client SVN',
              MB_YESNO Or MB_ICONQUESTION) = IDYES Then NetAbort := True;
          End
          Else UpdateCmd;
      End;
      TbDown := -1;
      InvalidateStatus;
      Exit;
    End;
End;

Procedure TabClick(X, Y : LongInt);
Var N : LongInt;
Begin
  If (RepoCur < 0) Or (X >= LX) Then Exit;
  If (Y >= CY0) And (Y < CY0 + TabH) Then
  Begin
    If X < LX Div 2 Then SetView(VwChanges) Else SetView(VwHistory);
  End
  Else If (View = VwChanges) And (Y >= CY0 + TabH) And
     (Y < CY0 + TabH + ChkH) And (X < 24) And Not Busy Then
  Begin
    N := CheckedCount;
    If N = Chg.N Then DoMenu(CmUncheckAll) Else DoMenu(CmCheckAll);
  End;
End;

{ raccourcis clavier (avant la distribution du message) : VK de Pasdows,
  Ctrl et Maj enfoncees }
Function Accel(VK : LongInt; C, Sh : Boolean) : Boolean;
Var Cmd, F : LongInt;
Begin
  Accel := False;
  Cmd := 0;
  If VK = VK_F5 Then Cmd := CmRefresh
  Else If C Then
    Case VK Of
      Ord('1') : Cmd := CmViewChg;
      Ord('2') : Cmd := CmViewHist;
      Ord('T') : If Sh Then Cmd := CmCheckUpd Else Cmd := CmRepoList;
      Ord('B') : Cmd := CmBranchList;
      Ord('N') : If Sh Then Cmd := CmNewBranch;
      Ord('O') : If Sh Then Cmd := CmCheckout Else Cmd := CmAddRepo;
      Ord('P') : If Sh Then Cmd := CmUpdate;
      Ord('R') : Cmd := CmResolve;
      Ord('F') : If Sh Then Cmd := CmExplorer;
      $BC : Cmd := CmOptions;
      VK_DELETE : If Sh Then Cmd := CmDiscardAll;
      VK_RETURN : If View = VwChanges Then
                  Begin
                    DoCommitCmd; Accel := True; Exit;
                  End;
      Ord('A') :
      Begin
        F := WinQueryFocus(HWND_DESKTOP);
        If (F <> ESum) And (F <> EDesc) Then Cmd := CmCheckAll;
      End;
    End;
  If Cmd = 0 Then Exit;
  If (RepoCur < 0) And (Cmd <> CmAddRepo) And (Cmd <> CmCheckout) And
     (Cmd <> CmOptions) Then Exit;
  MenuState;
  DoMenu(Cmd);
  Accel := True;
End;

{ touche de PM (WM_CHAR) -> raccourci ; vrai s'il a ete traite }
Const
  { lettres et chiffres d'apres le code de balayage (Ctrl+lettre) }
  ScanKeys : String[58] = '  1234567890    QWERTYUIOP    ASDFGHJKL     ZXCVBNM,      ';

Function AccelMsg(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, V, Sc, Vk : LongInt;
Begin
  AccelMsg := False;
  Fl := Mp1 And $FFFF; Ch := Mp2 And $FFFF; V := (Mp2 Shr 16) And $FFFF;
  Sc := (Mp1 Shr 24) And 255;
  If (Fl And PM_KC_KEYUP) <> 0 Then Exit;
  Vk := 0;
  If (Fl And PM_KC_VIRTUALKEY) <> 0 Then Vk := VkOf(V);
  If (Vk = 0) Or (Vk = VK_SPACE) Then
  Begin
    Vk := 0;
    If (Fl And PM_KC_CTRL) = 0 Then Exit;
    If (Ch >= 1) And (Ch <= 26) Then Vk := Ch + 64
    Else If (Ch >= Ord('a')) And (Ch <= Ord('z')) Then Vk := Ch - 32
    Else If ((Ch >= Ord('A')) And (Ch <= Ord('Z'))) Or
            ((Ch >= Ord('0')) And (Ch <= Ord('9'))) Then Vk := Ch
    Else If Ch = Ord(',') Then Vk := $BC
    Else If (Sc > 0) And (Sc < Length(ScanKeys)) And
       (ScanKeys[Sc + 1] <> ' ') Then
    Begin
      Vk := Ord(ScanKeys[Sc + 1]);
      If Vk = Ord(',') Then Vk := $BC;
    End;
  End;
  If Vk = 0 Then Exit;
  AccelMsg := Accel(Vk, (Fl And PM_KC_CTRL) <> 0, (Fl And PM_KC_SHIFT) <> 0);
End;

Procedure MakeChildren(H : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 2 Do
  Begin
    Lv[K].H := WinCreateWindow(H, Z2('SVLIST'), 0, PM_WS_TABSTOP, 0, 0, 100,
      100, H, HWND_BOTTOM, 40 + K, 0, 0);
    Lv[K].Sb := WinCreateWindow(Lv[K].H, WC_SCROLLBAR, 0, PM_WS_VISIBLE Or
      PM_SBS_VERT, 0, 0, SbW, 100, Lv[K].H, HWND_BOTTOM, 50 + K, 0, 0);
  End;
  Lv[LvChg].RowH := 20; Lv[LvHist].RowH := 38; Lv[LvFiles].RowH := 18;
  DiffWnd := WinCreateWindow(H, Z2('SVDIFF'), 0, PM_WS_TABSTOP, 0, 0, 100,
    100, H, HWND_BOTTOM, 60, 0, 0);
  DSbV := WinCreateWindow(DiffWnd, WC_SCROLLBAR, 0, PM_WS_VISIBLE Or
    PM_SBS_VERT, 0, 0, SbW, 100, DiffWnd, HWND_BOTTOM, 61, 0, 0);
  DSbH := WinCreateWindow(DiffWnd, WC_SCROLLBAR, 0, PM_WS_VISIBLE Or
    PM_SBS_HORZ, 0, 0, 100, SbW, DiffWnd, HWND_BOTTOM, 62, 0, 0);
  ESum := Ctl(H, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or WS_TABSTOP, 0,
    0, 10, 10, IdSum);
  EDesc := Ctl(H, 'EDIT', '', WS_BORDER Or ES_MULTILINE Or WS_TABSTOP, 0, 0,
    10, 10, IdDescE);
  BCommit := Ctl(H, 'BUTTON', 'Valider', BS_DEFPUSHBUTTON Or WS_TABSTOP, 0,
    0, 10, 10, IdCommit);
  BWCheck := Ctl(H, 'BUTTON', 'Extraire une copie de travail depuis un ' +
    'serveur...', WS_TABSTOP, 0, 0, 10, 10, IdWCheck);
  BWAdd := Ctl(H, 'BUTTON', 'Ajouter une copie de travail existante...',
    WS_TABSTOP, 0, 0, 10, 10, IdWAdd);
End;

Function MainProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var Id, Code : LongInt;
Begin
  MainProc0 := 0;
  Case Msg Of
    WM_SIZE :
    Begin
      CW0 := LP And $FFFF; CH0 := (LP Shr 16) And $FFFF;
      Layout;
      Inval(H);
    End;
    WM_PAINT : MainPaint(H);
    WM_LBUTTONDOWN :
    Begin
      If S16(LP Shr 16) < TbH Then TbClick(S16(LP), S16(LP Shr 16))
      Else TabClick(S16(LP), S16(LP Shr 16));
    End;
    WM_COMMAND :
    Begin
      Id := WP And $FFFF; Code := (WP Shr 16) And $FFFF;
      Case Id Of
        IdSum : If Code = EN_CHANGE Then UpdateCommitBtn;
        IdCommit : DoCommitCmd;
        IdWCheck : DoMenu(CmCheckout);
        IdWAdd : DoMenu(CmAddRepo);
      Else
        If Id > 100 Then DoMenu(Id);
      End;
    End;
    WM_GITPROG : InvalidateStatus;
    WM_GITDONE : OpDone;
    WM_TIMER : If Busy Then InvalidateStatus;
    WM_CLOSE :
      If Busy Then
      Begin
        If Ask('Une op'#233'ration r'#233'seau est en cours. Quitter quand ' +
          'm'#234'me ?', 'Client SVN', MB_YESNO Or MB_ICONWARNING) = IDYES
        Then
        Begin
          NetAbort := True;
          Dummy0 := WinPostMsg(H, PM_WM_QUIT, 0, 0);
        End;
      End
      Else Dummy0 := WinPostMsg(H, PM_WM_QUIT, 0, 0);
  End;
End;

Var
  InMainKey : Boolean;

{ procedure de PM de la fenetre principale : messages de PM traduits en
  messages de Pasdows (souris : Y vers le bas) ; Tab = controle suivant
  (WinDefDlgProc) ; WM_INITMENU : etat des menus ; WM_ACTIVATE : la copie
  est relue quand la fenetre redevient active }
Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var R, Fl, V, Id, Code, K : LongInt;
Begin
  R := 0;
  Case Msg Of
    PM_WM_ERASEBACKGROUND : R := 0;
    PM_WM_CHAR :
    Begin
      Fl := Mp1 And $FFFF; V := (Mp2 Shr 16) And $FFFF;
      If ((Fl And PM_KC_KEYUP) = 0) And ((Fl And PM_KC_VIRTUALKEY) <> 0) And
         ((V = PM_VK_TAB) Or (V = PM_VK_BACKTAB)) And Not InMainKey Then
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
      PM_WM_INITMENU :
      Begin
        MenuState;
        R := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
      PM_WM_CONTROL :
      Begin
        Id := Mp1 And $FFFF; Code := (Mp1 Shr 16) And $FFFF;
        If Id <= 255 Then K := CtlKind[Id] Else K := 0;
        If (K = 2) And (Code = PM_EN_CHANGE) Then
          Dummy0 := MainProc0(H, WM_COMMAND, Id Or (EN_CHANGE Shl 16), 0);
      End;
      PM_WM_TIMER : Dummy0 := MainProc0(H, WM_TIMER, Mp1, 0);
      PM_WM_BUTTON1DOWN :
      Begin
        Dummy0 := MainProc0(H, WM_LBUTTONDOWN, 0, MousePt(H, Mp1));
        R := 1;
      End;
      PM_WM_ACTIVATE :
      Begin
        { retour dans la fenetre : la copie a pu changer (Bloc-notes) }
        If ((Mp1 And $FFFF) <> 0) And (RepoCur >= 0) And Not Busy And
           (DlgFrame = 0) And (MsCount - LastRefresh > 5000) Then
          Dummy0 := WinPostMsg(H, PM_WM_COMMAND, CmRefresh, 0);
        R := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
      WM_GITPROG, WM_GITDONE : Dummy0 := MainProc0(H, Msg, Mp1, Mp2);
      PM_WM_CLOSE : Dummy0 := MainProc0(H, WM_CLOSE, 0, 0);
    Else
      R := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
    BigUnlock;
  End;
  MainProc := R;
End;
{ ==================================================================== }
{ Essais (/TEST) : resultats sur le port serie COM1                     }
{ ==================================================================== }

Var
  TOk, TN : LongInt;
  TUser, TPass, TxtS : String;

Procedure Log(S : String);
Var I, C : LongInt;
Begin
  S := S + Chr(13) + Chr(10);
  For I := 1 To Length(S) Do
  Begin
    C := Ord(S[I]);
    asm
      mov dx,3FDh
      mov ecx,100000
    @w:
      in al,dx
      test al,20h
      jnz @ok
      dec ecx
      jnz @w
    @ok:
      mov dx,3F8h
      mov eax,C
      out dx,al
    end;
  End;
End;

Procedure Check(Const Name : String; Ok : Boolean; Const Info : String);
Var S : String;
Begin
  Inc(TN);
  If Ok Then
  Begin
    Inc(TOk); S := 'ok';
  End
  Else S := 'ECHEC';
  If Info <> '' Then Log('SVNCLI : ' + Name + ' : ' + S + ' (' + Info + ')')
  Else Log('SVNCLI : ' + Name + ' : ' + S);
End;

Function TStr(Const S : String; Var B : TBuf) : Boolean;
Begin
  B.N := 0;
  BufStr(B, S);
  TStr := True;
End;

{ texte d'un tampon (lignes separees par |) }
Function BufTxt(Var B : TBuf) : String;
Var S : String; I : LongInt;
Begin
  S := '';
  For I := 0 To MinL(B.N, 200) - 1 Do
    If B.P^[I] = 10 Then S := S + '|' Else S := S + Chr(B.P^[I]);
  BufTxt := S;
End;

{ ---- decodeur svndiff0 (pour verifier l'encodeur) ---- }

Function SdRd(Var B : TBuf; Var P : LongInt) : LongInt;
Var V, C : LongInt;
Begin
  V := 0;
  Repeat
    If P >= B.N Then
    Begin
      SdRd := -1; Exit;
    End;
    C := B.P^[P]; Inc(P);
    V := (V Shl 7) Or (C And 127);
  Until (C And 128) = 0;
  SdRd := V;
End;

Function SdDecode(Var B, O : TBuf) : Boolean;
Var P, SOfs, SLen, TLen, ILen, NLen, IP, IE, DP, T0, C, Op0, L, Ofs, K
    : LongInt;
Begin
  SdDecode := False;
  O.N := 0;
  If (B.N < 4) Or (BufStrAt(B, 0, 3) <> 'SVN') Or (B.P^[3] <> 0) Then Exit;
  P := 4;
  While P < B.N Do
  Begin
    SOfs := SdRd(B, P); SLen := SdRd(B, P); TLen := SdRd(B, P);
    ILen := SdRd(B, P); NLen := SdRd(B, P);
    If (SOfs < 0) Or (NLen < 0) Or (SLen <> 0) Then Exit;
    IP := P; IE := P + ILen; DP := IE; T0 := O.N;
    While IP < IE Do
    Begin
      C := B.P^[IP]; Inc(IP);
      Op0 := (C Shr 6) And 3; L := C And 63;
      If L = 0 Then L := SdRd(B, IP);
      If Op0 = 0 Then Exit;            { pas de source }
      If Op0 = 1 Then
      Begin
        Ofs := SdRd(B, IP);
        For K := 0 To L - 1 Do BufByte(O, O.P^[T0 + Ofs + K]);
      End
      Else
      Begin
        BufAppend(O, B, DP, L); DP := DP + L;
      End;
    End;
    If O.N - T0 <> TLen Then Exit;
    P := IE + NLen;
  End;
  SdDecode := True;
End;

Procedure TestOffline;
Var A, B, O, R : TBuf; S : String; I, N, Pp, K : LongInt; C : TMd5;
    D : TMd5D; M1, M2 : String; Ok : Boolean;
Begin
  BufInit(A); BufInit(B); BufInit(O); BufInit(R);
  { MD5 (RFC 1321) et HMAC-MD5 (RFC 2104) : CRAM-MD5 de svnserve }
  A.N := 0;
  M1 := Md5Of(A, 0, 0);
  Dummy0 := Ord(TStr('abc', A));
  M2 := Md5Of(A, 0, A.N);
  Check('MD5', (M1 = 'd41d8cd98f00b204e9800998ecf8427e') And
    (M2 = '900150983cd24fb0d6963f7d28e17f72'), M2);
  S := HmacMd5('Jefe', 'what do ya want for nothing?');
  Check('HMAC-MD5', S = '750c783e6ab0b503eaa86e310a5db738', S);
  { svndiff0 : fenetre de 3 octets, puis gros fichier en fenetres de
    64 Ko decode et compare }
  Dummy0 := Ord(TStr('abc', A));
  O.N := 0;
  SdWindow(O, A, 3);
  S := '';
  For I := 0 To O.N - 1 Do S := S + HexB(O.P^[I]);
  Check('svndiff fenetre', S = '000003010383616263', S);
  MkDirs('D:\SVNTEST');
  A.N := 0;
  K := 12345;
  For I := 0 To 150000 - 1 Do
  Begin
    K := K * 1103515245 + 12345;
    If (I Mod 7) = 0 Then BufByte(A, 10) Else BufByte(A, 97 + ((K Shr 16) And 15));
  End;
  Ok := FileSave('D:\SVNTEST\SD.BIN', A, 0, A.N);
  Ok := Ok And SdFile('D:\SVNTEST\SD.BIN', B, M1);
  Ok := Ok And SdDecode(B, R);
  Check('svndiff fichier', Ok And (R.N = A.N) And (Md5Of(R, 0, R.N) = M1) And
    (M1 = Md5Of(A, 0, A.N)), IStr(B.N) + ' octets, ' + IStr(R.N));
  FileDel('D:\SVNTEST\SD.BIN');
  { differences (patience + plus longue sous-suite commune) }
  Dummy0 := Ord(TStr('un'#10'deux'#10'trois'#10'quatre'#10, DfA));
  Dummy0 := Ord(TStr('un'#10'DEUX'#10'trois'#10'quatre'#10'cinq'#10, DfB));
  DiffBuild;
  S := '';
  If DfN > 0 Then S := DiffText(0);
  Check('diff', (DfAdd = 2) And (DfDel = 1) And (S = '@@ -1,4 +1,5 @@') And
    (DfN = 7), S + ' +' + IStr(DfAdd) + ' -' + IStr(DfDel));
  { fusion a trois voies : sans conflit puis avec conflit }
  Dummy0 := Ord(TStr('1'#10'2'#10'3'#10'4'#10'5'#10, A));
  Dummy0 := Ord(TStr('1'#10'2 mine'#10'3'#10'4'#10'5'#10, B));
  Dummy0 := Ord(TStr('1'#10'2'#10'3'#10'4'#10'5 theirs'#10'6'#10, O));
  Ok := Merge3(A, B, O, R, '.r9');
  S := BufTxt(R);
  Check('fusion', Ok And (S = '1|2 mine|3|4|5 theirs|6|'), S);
  Dummy0 := Ord(TStr('1'#10'3 a'#10'3'#10'4'#10'5'#10, B));
  Dummy0 := Ord(TStr('1'#10'3 b'#10'3'#10'4'#10'5'#10, O));
  Ok := Merge3(A, B, O, R, '.r9');
  S := BufTxt(R);
  Check('fusion conflit', Not Ok And
    (S = '1|<<<<<<< .mine|3 a|=======|3 b|>>>>>>> .r9|3|4|5|'), S);
  { protocole ra_svn : S-expressions }
  SvIn.N := 0; SvP := 0;
  BufStr(SvIn, '( success ( 2 2 ( ANONYMOUS CRAM-MD5 ) ( edit-pipeline ' +
    'svndiff1 ) 5:a b)c ) ) ');
  N := SvRead;
  K := SvResp(N);
  Ok := (K >= 0) And (NNum(NChild(K, 0)) = 2) And
    (NStr(NChild(NChild(K, 2), 1)) = 'CRAM-MD5') And
    (NStr(NChild(NChild(K, 3), 0)) = 'edit-pipeline') And
    (NStr(NChild(K, 4)) = 'a b)c') And (NCount(K) = 5);
  Check('ra_svn', Ok, NStr(NChild(K, 4)));
  SvIn.N := 0; SvP := 0;
  BufStr(SvIn, '( failure ( ( 160013 19:Path not found here 6:file.c 42 ) ) ) ');
  K := SvResp(SvRead);
  Check('ra_svn erreur', (K < 0) And (GitErr = 'Path not found here'), GitErr);
  GitErr := '';
  { WebDAV : XML, en-tetes HTTP, URL }
  A.N := 0;
  BufStr(A, '<?xml version="1.0"?><D:multistatus xmlns:D="DAV:"><D:response>' +
    '<D:href>/svn/proj/!svn/rvr/6/trunk/a%20b.txt</D:href><D:propstat>');
  BufStr(A, '<D:prop><lp1:version-name>6</lp1:version-name><D:getcontentlength>' +
    '42</D:getcontentlength><lp1:creator-displayname>jos&#233;');
  BufStr(A, '</lp1:creator-displayname></D:prop></D:propstat></D:response>' +
    '<S:added-path node-kind="file" copyfrom-path="/x">/y</S:added-path>');
  S := UrlDec(XmlFirst(A, 'href'));
  Ok := (S = '/svn/proj/!svn/rvr/6/trunk/a b.txt') And
    (XmlFirst(A, 'version-name') = '6') And
    (Utf8ToAnsi(XmlFirst(A, 'creator-displayname')) = 'jos'#233);
  Pp := 0;
  Repeat
    K := XmlNext(A, Pp);
  Until (K = XkEnd) Or ((K = XkOpen) And (XName = 'added-path'));
  Ok := Ok And (XmlAttr('node-kind') = 'file') And
    (XmlAttr('copyfrom-path') = '/x');
  Check('XML WebDAV', Ok, S);
  HttpHdrs.N := 0;
  BufStr(HttpHdrs, 'DAV: 1,2'#13#10'SVN-Youngest-Rev: 17'#13#10 +
    'SVN-Repository-Root: /svn/proj'#13#10#13#10);
  Ok := (HttpHeader('svn-youngest-rev') = '17') And
    (HttpHeader('SVN-Repository-Root') = '/svn/proj');
  Ok := Ok And UrlSplit('https://user@10.0.2.2:8443/svn/a%20b') And
    (UrlScheme = 'https') And (UrlHost = '10.0.2.2') And (UrlPort = 8443) And
    (UrlPath = '/svn/a%20b');
  Ok := Ok And UrlSplit('svn://serveur/proj') And (UrlPort = 3690);
  Ok := Ok And (UrlEnc('a b/'#233) = 'a%20b/%e9') And
    (Base64('Aladdin:open sesame') = 'QWxhZGRpbjpvcGVuIHNlc2FtZQ==');
  Check('HTTP et URL', Ok, UrlEnc('a b/'#233));
  { motifs svn:ignore, dates }
  Ok := Glob('*.tmp', 1, 'essai.tmp', 1) And Not Glob('*.tmp', 1,
    'essai.txt', 1) And Glob('[a-c]?.o', 1, 'bx.o', 1) And
    Not Glob('[!a-c]*', 1, 'b', 1);
  S := UnixToStr(SvnDate('2026-11-23T01:26:21.331077Z'));
  Check('svn:ignore et dates', Ok And (S = '2026-11-23 01:26'), S);
  BufFree(A); BufFree(B); BufFree(O); BufFree(R);
End;

{ ---- essais avec un serveur (une URL de projet vide : .../trunk) ---- }

Function TPutFile(Const Path, S : String) : Boolean;
Begin
  TPutFile := FileSaveStr(Path, S);
End;

Function TFileTxt(Const Path : String) : String;
Var B : TBuf; S : String;
Begin
  BufInit(B);
  S := '?';
  If FileLoad(Path, B) Then S := BufTxt(B);
  BufFree(B);
  TFileTxt := S;
End;

{ coche tout et valide }
Function TCommit(Const Msg : String) : Boolean;
Var I : LongInt; M : TBuf; Ok : Boolean;
Begin
  Ok := WcStatus;
  For I := 0 To Chg.N - 1 Do Chg.E^[I].Flag := Chg.E^[I].Flag Or FlSel;
  BufInit(M);
  BufStr(M, Msg);
  Ok := Ok And WcCommit(M);
  BufFree(M);
  RaClose; HClose;
  TCommit := Ok;
End;

Procedure TestServer(Const Url : String; Nb : LongInt);
Var D1, D2, P, S, T : String; Ok : Boolean; R1, I, K : LongInt; B : TBuf;
Begin
  P := 'D:\SVNTEST\W' + IStr(Nb);
  D1 := P + 'A'; D2 := P + 'B';
  RmTree(D1, 0); RmTree(D2, 0);
  RemUser := TUser; RemPass := TPass;
  T := Copy(Url, 1, Pos(':', Url) - 1) + ' ';
  { extraction de la racine du projet (vide) puis premiers fichiers }
  GitErr := '';
  Ok := WcCheckout(Url, D1);
  RaClose; HClose;
  Check(T + 'extraction', Ok, GitErr + ' r' + IStr(WcRev));
  If Not Ok Then Exit;
  R1 := WcRev;
  Ok := TPutFile(D1 + '\LISEZMOI.txt', 'Bonjour'#10'Deuxieme ligne'#10 +
    'Troisieme'#10'Quatrieme'#10);
  MkDirs(D1 + '\doc');
  Ok := Ok And TPutFile(D1 + '\doc\manuel.txt', 'Manuel'#10);
  Ok := Ok And TPutFile(D1 + '\essai.tmp', 'temporaire'#10);
  WcIgnore('essai.tmp');
  Ok := Ok And WcStatus;
  S := IStr(Chg.N);
  Ok := Ok And (Chg.N = 3);            { 2 fichiers + svn:ignore }
  Ok := Ok And TCommit('Premiers fichiers');
  Check(T + 'validation (ajouts, dossier, svn:ignore)', Ok And
    (CNewRev = R1 + 1), GitErr + ' ' + S + ' -> r' + IStr(CNewRev));
  { seconde copie, modifications des deux cotes, fusion }
  Ok := WcCheckout(Url, D2);
  RaClose; HClose;
  Ok := Ok And (TFileTxt(D2 + '\doc\manuel.txt') = 'Manuel|') And
    Not FileExist(D2 + '\essai.tmp');
  Check(T + 'seconde extraction', Ok, GitErr + ' ' + IStr(EntN) +
    ' entrees');
  Ok := TPutFile(D2 + '\LISEZMOI.txt', 'Bonjour'#10'Deuxieme ligne'#10 +
    'Troisieme'#10'Quatrieme (depuis B)'#10);
  Ok := Ok And TCommit('Modif dans B');
  Check(T + 'validation (modification)', Ok, GitErr + ' r' + IStr(CNewRev));
  Ok := WcLoad(D1);
  Ok := Ok And TPutFile(D1 + '\LISEZMOI.txt', 'Bonjour'#10 +
    'Deuxieme ligne modifiee'#10'Troisieme'#10'Quatrieme'#10);
  Ok := Ok And WcUpdate(-1, '');
  RaClose; HClose;
  S := TFileTxt(D1 + '\LISEZMOI.txt');
  Check(T + 'mise a jour avec fusion', Ok And (UpdConf = 0) And
    (S = 'Bonjour|Deuxieme ligne modifiee|Troisieme|Quatrieme (depuis B)|'),
    GitErr + ' ' + S);
  Ok := TCommit('Fusion');
  Check(T + 'validation apres fusion', Ok, GitErr + ' r' + IStr(CNewRev));
  { conflit : la meme ligne modifiee des deux cotes }
  Ok := WcLoad(D2);
  Ok := Ok And TPutFile(D2 + '\doc\manuel.txt', 'Manuel B'#10);
  Ok := Ok And TCommit('Manuel B');
  Ok := Ok And WcLoad(D1);
  Ok := Ok And TPutFile(D1 + '\doc\manuel.txt', 'Manuel A'#10);
  Ok := Ok And WcUpdate(-1, '');
  RaClose; HClose;
  Ok := Ok And (UpdConf = 1) And HasConflictMark(D1 + '\doc\manuel.txt') And
    FileExist(D1 + '\doc\manuel.txt.mine');
  K := EntFind('doc/manuel.txt');
  If K >= 0 Then
  Begin
    Resolve(K);
    Ok := Ok And Not FileExist(D1 + '\doc\manuel.txt.mine');
  End;
  Ok := Ok And TPutFile(D1 + '\doc\manuel.txt', 'Manuel A et B'#10);
  Ok := Ok And TCommit('Conflit resolu');
  Check(T + 'conflit (.mine, .rN) et resolution', Ok, GitErr);
  { annulation }
  Ok := TPutFile(D1 + '\LISEZMOI.txt', 'efface'#10);
  FileDel(D1 + '\doc\manuel.txt');
  Ok := Ok And WcStatus And (Chg.N = 2);
  For I := 0 To Chg.N - 1 Do Chg.E^[I].Flag := Chg.E^[I].Flag Or FlSel;
  Ok := Ok And WcRevert And WcStatus And (Chg.N = 0) And
    (TFileTxt(D1 + '\doc\manuel.txt') = 'Manuel A et B|');
  Check(T + 'annulation', Ok, GitErr + ' ' + IStr(Chg.N));
  { suppression d'un fichier }
  FileDel(D1 + '\doc\manuel.txt');
  Ok := TCommit('Suppression');
  Check(T + 'validation (suppression)', Ok, GitErr);
  { journal et differences lues sur le serveur }
  Ok := RaOpen(WcUrl) And RaLatest(HHead) And
    RaLog(RaRel, HHead, 0, HistMax, True);
  K := 0;
  If Ok And (HistN > 0) Then K := Hist^[0].PN;
  S := '';
  If HistN > 1 Then S := HistSummary(1);
  Ok := Ok And (HistN >= 6) And (Hist^[0].Rev = HHead) And (S = 'Conflit resolu');
  BufInit(B);
  Ok := Ok And RaGetFile(RPath('LISEZMOI.txt'), R1 + 2, '', B, P) And
    (BufTxt(B) = 'Bonjour|Deuxieme ligne|Troisieme|Quatrieme (depuis B)|');
  BufFree(B);
  RaClose; HClose;
  Check(T + 'historique et fichier d''une revision', Ok, GitErr + ' ' +
    IStr(HistN) + ' revisions, ' + S);
  { branche : creation par copie sur le serveur, changement, retour }
  BufInit(B);
  BufStr(B, 'Creation de la branche essai');
  Ok := WcBranch('essai', B);
  BufFree(B);
  S := RaRoot + '/' + UrlEnc(JoinP(BrBase, 'branches/essai'));
  RaClose; HClose;
  Ok := Ok And WcUpdate(-1, S);
  RaClose; HClose;
  BranchSplit(WcRel);
  T := T + 'branche ';
  Ok := Ok And (BrCur = 'branches/essai') And
    (TFileTxt(D1 + '\LISEZMOI.txt') <> '?');
  S := RaRoot + '/' + UrlEnc(JoinP(BrBase, 'trunk'));
  Ok := Ok And WcUpdate(-1, S);
  RaClose; HClose;
  BranchSplit(WcRel);
  Check(T + '(creation, changement, retour)', Ok And (BrCur = 'trunk'),
    GitErr + ' ' + BrCur);
  Log('SVNCLI : copie ' + D1 + ' : ' + IStr(EntN) + ' elements, revision ' +
    IStr(WcRev) + ', ' + WcUrl);
End;

Procedure RunTests;
Var I, N : LongInt; S : String;
Begin
  Log('SVNCLI : essais du Client SVN');
  TOk := 0; TN := 0;
  TestOffline;
  N := 0;
  For I := 1 To ParamCount Do
  Begin
    S := ParamStr(I);
    If UpStr(Copy(S, 1, 6)) = '/USER:' Then TUser := Copy(S, 7, 255)
    Else If UpStr(Copy(S, 1, 6)) = '/PASS:' Then TPass := Copy(S, 7, 255);
  End;
  For I := 1 To ParamCount Do
  Begin
    S := ParamStr(I);
    If Pos('://', S) > 0 Then
    Begin
      Inc(N);
      TestServer(S, N);
    End;
  End;
  Log('SVNCLI : ' + IStr(TOk) + '/' + IStr(TN) + ' essais reussis');
End;

{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

{ SVNCLI /CHECKOUT url dossier [/USER:nom] [/PASS:mot] : extraction sans
  fenetre (procedures de commandes, STARTUP.CMD) }
Procedure ConsoleCheckout;
Var I : LongInt; S, U, D : String;
Begin
  U := ''; D := '';
  For I := 1 To ParamCount Do
  Begin
    S := ParamStr(I);
    If UpStr(Copy(S, 1, 6)) = '/USER:' Then TUser := Copy(S, 7, 255)
    Else If UpStr(Copy(S, 1, 6)) = '/PASS:' Then TPass := Copy(S, 7, 255)
    Else If Pos('://', S) > 0 Then U := S
    Else If (S <> '') And (S[1] <> '/') Then D := S;
  End;
  RemUser := TUser; RemPass := TPass;
  If (U <> '') And (D <> '') And WcCheckout(U, D) Then
  Begin
    Log('SVNCLI : extraction de ' + U + ' dans ' + D + ' : revision ' +
      IStr(WcRev) + ', ' + IStr(EntN) + ' elements');
    { la copie et l'adresse sont retenues pour la fenetre }
    UrlsRemember(U);
    ReposLoad;
    RepoCur := RepoAdd(D);
    ReposSave;
  End
  Else Log('SVNCLI : extraction impossible : ' + GitErr);
  RaClose; HClose;
End;

Var
  Tid, Fw, Fh, Fl, I : LongInt;
  Handled, CoMode : Boolean;
  ArgUrl, ArgDir : String;

Begin
  TestMode := False; CoMode := False;
  ArgUrl := ''; ArgDir := '';
  For I := 1 To ParamCount Do
  Begin
    TxtS := ParamStr(I);
    If UpStr(TxtS) = '/TEST' Then TestMode := True
    Else If UpStr(TxtS) = '/CHECKOUT' Then CoMode := True
    Else If UpStr(Copy(TxtS, 1, 6)) = '/USER:' Then TUser := Copy(TxtS, 7, 255)
    Else If UpStr(Copy(TxtS, 1, 6)) = '/PASS:' Then TPass := Copy(TxtS, 7, 255)
    Else If Pos('://', TxtS) > 0 Then ArgUrl := TxtS
    Else If (TxtS <> '') And (TxtS[1] <> '/') Then ArgDir := TxtS;
  End;
  If CoMode Then TestMode := True;
  OemOut := 1;
  FsAnsi := True;
  AgentName := 'SVN/1.14.0 (OS/2-0; Client SVN 1.0)';
  FlatInit(HFiles); BufInit(OpMsg); BufInit(HttpHdrs); BufInit(XText);
  BufInit(DfA); BufInit(DfB); BufInit(HRb);
  HttpSinkH := -1; SvSock := -1; HSock := -1;
  TbDown := -1; ChgSel := -1; HistSel := -1; FileSel := -1;
  FindAppDir;
  If TestMode Then
  Begin
    ProxyStr := EnvProxy;
    If CoMode Then ConsoleCheckout Else RunTests;
    Dummy0 := DosExit(1, 0);
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20);
  ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy0 := DosCreateMutexSem(0, LongInt(@LockSem), 0, 0);
  LockOn := True;
  RegClass('SVMAIN', LongInt(@MainProc));
  RegClass('SVLIST', LongInt(@LvProc));
  RegClass('SVDIFF', LongInt(@DiffProc));
  RegClass('SVDLG', LongInt(@DlgProc));
  BigLock;
  ProxyStr := IniGet('Options', 'Proxy', '');
  If (ProxyStr = '') And (IniGet('Options', 'SansProxy', '') = '') Then
    ProxyStr := EnvProxy;
  CheckRoot := IniGet('Options', 'Dossier', DefRoot);
  ReposLoad;
  If (RepoCur < 0) And (RepoN > 0) Then RepoCur := 0;
  { SVNCLI dossier : ouvre cette copie de travail ; SVNCLI url dossier :
    l'extrait (comme svn checkout) ; /USER: et /PASS: pour ce serveur }
  While (Length(ArgDir) > 3) And (ArgDir[Length(ArgDir)] = '') Do
    Delete(ArgDir, Length(ArgDir), 1);
  If (ArgUrl = '') And (ArgDir <> '') Then
    If DirExist(JoinDirS(ArgDir, MetaName)) Then
    Begin
      RepoCur := RepoAdd(ArgDir);
      ReposSave;
      If WcLoad(ArgDir) Then ArgUrl := WcUrl;
      ArgDir := '';
    End;
  If (TUser <> '') And (ArgUrl <> '') Then
  Begin
    CredHost := HostKey(ArgUrl); CredUser := TUser; CredPass := TPass;
  End;
  StatusTxt := 'Pr'#234't';
  BigUnlock;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or
    FCF_MAXBUTTON Or FCF_TASKLIST;
  MainWnd := 0;
  MainFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z2('SVMAIN'),
    Z('Client SVN'), 0, 0, 0, LongInt(@MainWnd));
  BigLock;
  MakeChildren(MainWnd);
  BuildMenus;
  BigUnlock;
  Fw := MinL(ScrW, 900); Fh := MinL(ScrH - 32, 640);
  If ScrW <= 800 Then
    Dummy0 := WinSetWindowPos(MainFrame, HWND_TOP, 0, 0, ScrW, ScrH, SWP_SIZE
      Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE Or SWP_MAXIMIZE)
  Else
    Dummy0 := WinSetWindowPos(MainFrame, HWND_TOP, (ScrW - Fw) Div 2,
      MaxL(0, (ScrH - Fh) Div 2 + 16), Fw, Fh, SWP_SIZE Or SWP_MOVE Or
      SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy0 := WinSetActiveWindow(HWND_DESKTOP, MainFrame);
  BigLock;
  Layout;
  If RepoCur >= 0 Then OpenRepo(RepoCur) Else RefreshRepo(False);
  If (ArgUrl <> '') And (ArgDir <> '') And Not Busy Then
  Begin
    OpUrl := ArgUrl; OpDir := ArgDir;
    StartOp(OpCheckout);
  End;
  { clavier : liste des modifications, ou bouton Extraire }
  If RepoCur >= 0 Then WFocus(Lv[LvChg].H) Else WFocus(BWCheck);
  BigUnlock;
  Dummy0 := WinStartTimer(Hab, MainWnd, 1, 1000);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do
  Begin
    Handled := False;
    If (Qmsg[1] = PM_WM_CHAR) And (DlgFrame = 0) Then
    Begin
      BigLock;
      Handled := AccelMsg(Qmsg[2], Qmsg[3]);
      BigUnlock;
    End;
    If Not Handled Then Dummy0 := WinDispatchMsg(Hab, LongInt(@Qmsg));
  End;
  NetAbort := True;
  Dummy0 := DosSleep(200);
  Dummy0 := WinDestroyWindow(MainFrame);
  Dummy0 := DosExit(1, 0);
End.
