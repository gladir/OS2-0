{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: GITCLI - Client GitHub d'OS/2-0 (Presentation Manager),
  dans le genre de GitHub Desktop, porte du Client GitHub de Pasdows 95.
}

Program GitCli;

{$R-,S-,I-}

{ Compilation : OS2PC APPS\GITCLI.PAS GITCLI.EXE

  Bureau - Outils reseau - Client GitHub (GITCLI.EXE).
  Porte de APPS/GITCLI.PAS de Pasdows 95 (Win32, WPC -CW32) : fichier
  unique, sans unite ni fichier d'inclusion.

  Ce qui vient de Pasdows 95, sans changement de fond :
  - Git ecrit entierement en Pascal : SHA-1, zlib (inflate ; deflate
    LZ77 + Huffman fixe), Adler-32, CRC-32, objets libres, packs et index
    v2 (deltas OFS_DELTA et REF_DELTA, gros objets traites par morceaux
    dans des fichiers), index du dossier de travail (DIRC v2, cache
    taille/date), arbres, commits, references (libres et packed-refs),
    config, .gitignore, statut, validation, extraction, branches, fusion
    a trois voies ligne par ligne (marqueurs de conflit, MERGE_HEAD),
    diff (patience + plus longue sous-suite commune), historique ;
  - protocole Git « intelligent » : clonage, recuperation (fetch),
    tirage (pull = fetch + fusion), envoi (push, report-status) en
    HTTP, HTTPS et git:// (port 9418), authentification Basic ;
  - API de GitHub.com (jeton d'acces personnel) : compte, liste des
    depots pour le clonage, publication d'un depot ;
  - fenetre de GitHub Desktop : boutons Depot actuel, Branche actuelle
    et Recuperer/Pousser/Tirer origin, onglets Modifications (cases a
    cocher, resume et description du commit) et Historique (commits,
    fichiers modifies), vue des differences en couleurs, menus Fichier,
    Edition, Affichage, Depot, Branche et Aide, raccourcis clavier,
    boites de dialogue (cloner, nouveau depot, ajouter un depot local,
    options, publier, fusionner, authentification, parametres du depot).

  Ce qui change pour OS/2 (methode du Client FTP) :
  - les procedures de fenetre gardent les evenements de Pasdows
    (WM_PAINT, WM_LBUTTONDOWN, WM_COMMAND... numeros de Windows) : les
    procedures de PM (MainProc, LvProc, DiffProc, DlgProc) les produisent
    a partir des messages de PM (coordonnees retournees : Y vers le bas,
    touches virtuelles de PM traduites, WM_CONTROL des controles traduit
    en notifications BN_CLICKED, EN_CHANGE, LBN_SELCHANGE, LBN_DBLCLK) ;
  - dessin par GPI en couleurs RVB (GpiCreateLogColorTable, GpiBox,
    GpiCharStringAt) avec la police de PM 8 x 16 ; le texte ANSI de
    Pasdows est affiche en page de codes 850 ;
  - controles natifs de PM (WC_ENTRYFIELD, WC_MLE pour la description du
    commit, WC_BUTTON, WC_STATIC, WC_LISTBOX, WC_SCROLLBAR), barre de
    menus et menus contextuels faits de gabarits (WinCreateMenu,
    WinPopupMenu), boites de message (WinMessageBox), presse-papiers ;
  - le choix d'un dossier (SHBrowseForFolder) est une petite boite de PM
    (liste des lecteurs et dossiers) ;
  - reglages : GITCLI.INI (meme format que le fichier .INI de Pasdows)
    dans C:\RESEAU\, ou D:\RESEAU\ quand C: est en lecture seule ;
  - WININET est remplace par un client HTTP/1.1 ecrit ici sur les sockets
    de TCPIP32.DLL (Content-Length, Transfer-Encoding: chunked,
    redirections), https par TLS32.DLL (TLS 1.2 et 1.3 ; certificats non
    verifies), proxy HTTP (Options ou SET HTTP_PROXY=hote:port de
    CONFIG.SYS : requete absolue pour http, tunnel CONNECT pour https ;
    le reseau prive 10.*, 127.*, 192.168.* et localhost sans proxy) ;
    git:// directement sur TCPIP32 ;
  - fichiers : DosOpen, DosRead, DosWrite, DosSetFilePtr,
    DosQueryFileInfo, DosQueryPathInfo, DosFindFirst/DosFindNext,
    DosCreateDir, DosDeleteDir, DosDelete, DosMove (les noms de fichiers
    sont en page 850 ; les chemins de Git restent en UTF-8) ;
  - le reseau tourne dans un fil (DosCreateThread) ; un semaphore
    d'exclusion (DosCreateMutexSem) remplace la section critique : il
    protege les chaines temporaires du runtime d'OS2PC, partagees par les
    deux fils ; le fil reseau le libere pendant les appels bloquants
    (connect, send, recv, TLS) et la progression ; la fin de l'operation
    et la progression arrivent a la fenetre par WinPostMsg ;
  - heure : DosGetDateTime, DosQuerySysInfo (QSV_MS_COUNT) ; programmes
    lances par DosExecPgm (Explorateur, Invite de commandes, Bloc-notes,
    Navigateur Web pour « Voir sur GitHub »).

  API d'OS/2 utilisees : PMWIN (WinInitialize, WinCreateMsgQueue,
  WinRegisterClass, WinCreateStdWindow, WinCreateWindow, WinDefWindowProc,
  WinDefDlgProc, WinBeginPaint, WinEndPaint, WinInvalidateRect,
  WinSetWindowPos, WinMessageBox, WinCreateMenu, WinPopupMenu,
  WinSendMsg, WinPostMsg, WinStartTimer, WinOpenClipbrd...), PMGPI
  (GpiCreateLogColorTable, GpiSetColor, GpiMove, GpiBox,
  GpiCharStringAt), DOSCALLS (voir plus haut, DosCreateThread,
  DosCreateMutexSem, DosRequestMutexSem, DosReleaseMutexSem, DosScanEnv,
  DosExecPgm), TCPIP32 (sock_init, gethostbyname, inet_addr, socket,
  connect, send, recv, shutdown, soclose), TLS32 (TLSOPEN, TLSSEND,
  TLSRECV, TLSCLOSE, TLSERROR).

  Parametres :
    GITCLI                 fenetre du Client GitHub
    GITCLI chemin          ouvre (ou ajoute) le depot local chemin
    GITCLI /CLONE:url /DIR:chemin
                           clone url dans chemin au demarrage
    GITCLI /TEST [/URL:url]...
                           essais sans fenetre (SHA-1, zlib, objets,
                           packs, deltas, diff, fusion, et clonage, envoi
                           et tirage pour chaque /URL:), resultats sur
                           COM1 (lignes « GITCLI : ... »)
    GITCLI /INDEX:pack /DIR:chemin
                           essai sans fenetre : indexe le pack (fichier
                           .pack recu d'un serveur) dans un depot neuf,
                           temps et caches sur COM1 }

Const
  PS = '\';
  AllFiles = '*.*';

  { ---- evenements internes des fenetres (numeros de Pasdows 95 ; les
    procedures de PM les produisent, voir MainProc, LvProc, DiffProc et
    DlgProc) ---- }
  WM_CREATE = $0001; WM_DESTROY = $0002; WM_SIZE = $0005;
  WM_SETFOCUS = $0007; WM_KILLFOCUS = $0008; WM_PAINT = $000F;
  WM_CLOSE = $0010; WM_ERASEBKGND = $0014; WM_ACTIVATE = $0006;
  WM_KEYDOWN = $0100; WM_CHAR = $0102;
  WM_COMMAND = $0111; WM_TIMER = $0113;
  WM_HSCROLL = $0114; WM_VSCROLL = $0115;
  WM_MOUSEMOVE = $0200; WM_LBUTTONDOWN = $0201; WM_LBUTTONUP = $0202;
  WM_LBUTTONDBLCLK = $0203; WM_RBUTTONDOWN = $0204; WM_RBUTTONUP = $0205;
  WM_MOUSEWHEEL = $020A;
  { messages du fil reseau a la fenetre principale (WM_USER de PM) }
  WM_USER = $1000;
  WM_GITDONE = WM_USER + 10;           { operation reseau terminee }
  WM_GITPROG = WM_USER + 11;           { progression }
  WM_GITCMD = WM_USER + 12;            { commande differee (menus) }
  { notifications internes (WM_COMMAND : Id + Code Shl 16) }
  BN_CLICKED = 0; LBN_SELCHANGE = 1; LBN_DBLCLK = 2; EN_CHANGE = $0300;
  { styles internes des controles (Ctl les traduit pour PM) }
  WS_BORDER = $00800000; WS_VSCROLL = $00200000;
  WS_TABSTOP = $00010000; WS_GROUP = $00020000;
  ES_AUTOHSCROLL = $0080; ES_MULTILINE = $0004; ES_PASSWORD = $0020;
  BS_PUSHBUTTON = 0; BS_DEFPUSHBUTTON = 1; BS_AUTOCHECKBOX = 3;
  BS_GROUPBOX = 7; LBS_NOTIFY = 1;
  { defilement (codes de Pasdows, VsCode les produit) }
  SB_LINEUP = 0; SB_LINEDOWN = 1; SB_PAGEUP = 2; SB_PAGEDOWN = 3;
  SB_THUMBPOSITION = 4; SB_THUMBTRACK = 5; SB_TOP = 6; SB_BOTTOM = 7;
  { boites de message (valeurs internes ; MbFlags les traduit) }
  MB_OK = 0; MB_OKCANCEL = 1; MB_YESNOCANCEL = 3; MB_YESNO = 4;
  MB_ICONERROR = $10; MB_ICONQUESTION = $20; MB_ICONWARNING = $30;
  MB_ICONINFO = $40; IDOK = 1; IDCANCEL = 2; IDYES = 6; IDNO = 7;
  { touches internes }
  VK_BACK = $08; VK_TAB = $09; VK_RETURN = $0D; VK_SHIFT = $10;
  VK_CONTROL = $11; VK_ESCAPE = $1B; VK_SPACE = $20; VK_PRIOR = $21;
  VK_NEXT = $22; VK_END = $23; VK_HOME = $24; VK_LEFT = $25; VK_UP = $26;
  VK_RIGHT = $27; VK_DOWN = $28; VK_DELETE = $2E; VK_F5 = $74;
  { couleurs de Pasdows ($00BBGGRR), dessinees en RVB par GPI }
  ClrFace = $AAAAAA; ClrShadow = $555555; ClrHi = $FFFFFF; ClrDark = 0;
  ClrWin = $FFFFFF; ClrBlack = 0; ClrNavy = $AA0000; ClrGray = $808080;
  ClrGreen = $008000; ClrRed = $0000C0; ClrMaroon = $000080;
  ClrAddBg = $EDFFE6; ClrDelBg = $F0EEFF; ClrAddG = $D8FFCD;
  ClrDelG = $E0DCFF; ClrHunk = $FFF8F1; ClrHunkT = $A06030;
  ClrAddI = $289A2C; ClrModI = $0088C0; ClrDelI = $2020C8;
  ClrConfI = $0060E0; ClrLight = $E0E0E0;

  { ---- Presentation Manager ---- }
  PM_WM_ACTIVATE = $000D; PM_WM_SETFOCUS = $000F; PM_WM_SIZE = $0007;
  PM_WM_COMMAND = $0020;
  PM_WM_PAINT = $0023; PM_WM_TIMER = $0024; PM_WM_CLOSE = $0029;
  PM_WM_QUIT = $002A; PM_WM_CONTROL = $0030; PM_WM_VSCROLL = $0031;
  PM_WM_HSCROLL = $0032;
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
  PM_BM_QUERYCHECK = $0124; PM_BM_SETCHECK = $0125;
  PM_EM_SETSEL = $0142; PM_EM_SETTEXTLIMIT = $0143;
  PM_LM_INSERTITEM = $0161; PM_LM_SELECTITEM = $0164;
  PM_LM_QUERYSELECTION = $0165; PM_LM_DELETEALL = $016E;
  PM_MM_SETITEMATTR = $0192;
  PM_SBM_SETSCROLLBAR = $01A0; PM_SBM_SETPOS = $01A1; PM_SBM_QUERYPOS = $01A2;
  PM_SBM_SETTHUMBSIZE = $01A6;
  PM_BN_CLICKED = 1; PM_EN_CHANGE = 4; PM_LN_SELECT = 1; PM_LN_ENTER = 5;
  PM_MLN_CHANGE = 7;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10;
  FCF_MAXBUTTON = $20; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3; HWND_BOTTOM = 4; QW_PARENT = 5;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_HIDE = $10;
  SWP_ACTIVATE = $80; SWP_MAXIMIZE = $800;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  PM_MB_OK = 0; PM_MB_OKCANCEL = 1; PM_MB_YESNO = 4; PM_MB_YESNOCANCEL = 5;
  PM_MB_QUERY = $10; PM_MB_WARNING = $20; PM_MB_INFORMATION = $30;
  PM_MB_ERROR = $40; PM_MB_MOVEABLE = $4000;
  SPTR_ARROW = 1; SPTR_WAIT = 3;
  PP_BACKGROUNDCOLORINDEX = 4; CLR_PALEGRAY = 15;

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
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinUpdateWindow(H : LongInt) : LongInt; External 'PMWIN';
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
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysPointer(HD, Id, Load : LongInt) : LongInt; External 'PMWIN';
Function WinSetPointer(HD, Hptr : LongInt) : LongInt; External 'PMWIN';
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
Function GpiMove(Hps, PPt : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Ctl, PPt, Hr, Vr : LongInt) : LongInt; External 'PMGPI';
Function GpiCreateLogColorTable(Hps, Opt, Fmt, St, N, P : LongInt) : LongInt; External 'PMGPI';
{ ---- DOSCALLS ---- }
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ofs, Method, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFileInfo(H, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosDeleteDir(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosMove(POld, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFSAttach(PDev, Ordinal, Level, PBuf, PCb : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosQuerySysInfo(IStart, ILast, PBuf, CbBuf : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateMutexSem(PName, PH, Attr, State : LongInt) : LongInt; External 'DOSCALLS';
Function DosRequestMutexSem(H, Timeout : LongInt) : LongInt; External 'DOSCALLS';
Function DosReleaseMutexSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetInfoBlocks(PPtib, PPpib : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosExit(Action, Code : LongInt) : LongInt; External 'DOSCALLS';
{ ---- TCPIP32 ---- }
Function sock_init : LongInt; External 'TCPIP32' Name 'sock_init';
Function socket(Af, Typ, Pr : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function connect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function send(S, B, N, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function recv(S, B, N, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function soclose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function shutdown(S, How : LongInt) : LongInt; External 'TCPIP32' Name 'shutdown';
Function gethostbyname(N : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
Function inet_addr(N : LongInt) : LongInt; External 'TCPIP32' Name 'inet_addr';
{ ---- TLS32 ---- }
Function TlsOpen(S, PHost : LongInt) : LongInt; External 'TLS32' Name 'TLSOPEN';
Function TlsSend(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSSEND';
Function TlsRecv(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSRECV';
Function TlsClose(H : LongInt) : LongInt; External 'TLS32' Name 'TLSCLOSE';
Function TlsError(B, Cb : LongInt) : LongInt; External 'TLS32' Name 'TLSERROR';

Var
  Dummy0 : LongInt;
  TestMode : Boolean;                  { /TEST : essais sans fenetre }

{ ligne sur le port serie COM1 (journal des essais) }
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

{ millisecondes depuis le demarrage (QSV_MS_COUNT) }
Function MsTick : LongInt;
Var V : LongInt;
Begin
  V := 0;
  If DosQuerySysInfo(14, 14, LongInt(@V), 4) <> 0 Then V := 0;
  MsTick := V;
End;

{ le noyau ne preempte pas un programme de PM : un long calcul (inflate,
  delta, SHA-1 d'une image ISO de plusieurs dizaines de Mo) gelerait tout
  le systeme, pointeur de la souris compris. Breathe(W) compte le travail
  fait (W : octets traites, environ) et cede le processeur aux autres
  taches (DosSleep(0)) toutes les 30 ms au plus ; le verrou de
  l'application reste pris (la fenetre se redessine aux points surs, voir
  GitProgress). }
Var
  BrWork, BrTick : LongInt;

Procedure Breathe(W : LongInt);
Var T : LongInt;
Begin
  BrWork := BrWork + W;
  If BrWork < 32768 Then Exit;
  BrWork := 0;
  T := MsTick;
  If (T - BrTick >= 30) Or (T < BrTick) Then
  Begin
    Dummy0 := DosSleep(0);
    BrTick := MsTick;
  End;
End;

{ chaine ASCIIZ a l'adresse A }
Procedure PutZA(A : LongInt; Const S : String);
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do PByt(A + I - 1)^ := Ord(S[I]);
  PByt(A + Length(S))^ := 0;
End;

{ ==================================================================== }
{ Noyau Git : utilitaires, tampons d'octets                             }
{ ==================================================================== }

Type
  TByteArr = Array[0..$7FFFFFF] Of Byte;
  PBytes = ^TByteArr;
  TSha = Array[0..19] Of Byte;
  { tampon d'octets extensible }
  TBuf = Record
    P : PBytes;
    N, Cap : LongInt;
  End;

Type
  TLongArr4 = Array[0..$3FFFFFF] Of LongInt;

Var
  GitErr : String;                     { derniere erreur (texte) }
  ShaZero : TSha;
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

Function ShaHex(Const H : TSha) : String;
Var S : String; I : LongInt;
Begin
  S := '';
  For I := 0 To 19 Do S := S + HexB(H[I]);
  ShaHex := S;
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

{ 40 chiffres hexadecimaux -> empreinte ; faux si invalide }
Function ShaParse(Const S : String; Var H : TSha) : Boolean;
Var I, A, B : LongInt;
Begin
  ShaParse := False;
  If Length(S) < 40 Then Exit;
  For I := 0 To 19 Do
  Begin
    A := HexVal(S[I * 2 + 1]); B := HexVal(S[I * 2 + 2]);
    If (A < 0) Or (B < 0) Then Exit;
    H[I] := A * 16 + B;
  End;
  ShaParse := True;
End;

Function ShaEq(Const A, B : TSha) : Boolean;
Var I : LongInt;
Begin
  ShaEq := False;
  For I := 0 To 19 Do If A[I] <> B[I] Then Exit;
  ShaEq := True;
End;

Function ShaIsZero(Const A : TSha) : Boolean;
Begin
  ShaIsZero := ShaEq(A, ShaZero);
End;

{ comparaison (ordre des octets) : -1, 0, 1 }
Function ShaCmp(Const A, B : TSha) : LongInt;
Var I : LongInt;
Begin
  ShaCmp := 0;
  For I := 0 To 19 Do
    If A[I] <> B[I] Then
    Begin
      If A[I] < B[I] Then ShaCmp := -1 Else ShaCmp := 1;
      Exit;
    End;
End;

Procedure ShaFrom(Var B : TBuf; Ofs : LongInt; Var H : TSha);
Var I : LongInt;
Begin
  For I := 0 To 19 Do H[I] := B.P^[Ofs + I];
End;

{ ==================================================================== }
{ SHA-1, CRC-32, Adler-32                                               }
{ ==================================================================== }

Type
  TSha1 = Record
    H0, H1, H2, H3, H4 : LongInt;
    W : Array[0..79] Of LongInt;
    Blk : Array[0..63] Of Byte;
    BN : LongInt;
    Len : LongInt;                     { octets (moins de 512 Mo) }
  End;

Procedure Sha1Init(Var C : TSha1);
Begin
  C.H0 := $67452301; C.H1 := LongInt($EFCDAB89); C.H2 := LongInt($98BADCFE);
  C.H3 := $10325476; C.H4 := LongInt($C3D2E1F0);
  C.BN := 0; C.Len := 0;
End;

{ un bloc de 64 octets (P^[O..O+63]) ; rotations ecrites en ligne et
  une boucle par groupe de 20 tours (le SHA-1 de gros fichiers compte) }
Procedure Sha1Run(Var C : TSha1; P : PBytes; O : LongInt);
{ compression SHA-1 d'un bloc de 64 octets (P^[O..O+63]) : assembleur 386
  deroule (genere), 5 registres pour a..e, XCHG AL,AH / ROL EAX,16 pour
  lire les mots gros-boutistes ; C.W recoit le message etendu. Le code Pascal
  equivalent faisait la moitie du temps d'un clonage (images ISO de
  plusieurs dizaines de Mo). Parametres : C [ebp+16], P [ebp+12],
  O [ebp+8]. Constantes en decimal : l'assembleur d'OS2PC lit 6ED9EBA1h
  comme un nombre reel et ignore 08F1BBCDCh et 0CA62C1D6h. }
Begin
  Breathe(64);
  asm
    push esi
    push edi
    push ebx
    push ebp
    mov edi,[ebp+16]
    mov esi,[ebp+12]
    add esi,[ebp+8]
    mov eax,[esi+0]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+20],eax
    mov eax,[esi+4]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+24],eax
    mov eax,[esi+8]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+28],eax
    mov eax,[esi+12]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+32],eax
    mov eax,[esi+16]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+36],eax
    mov eax,[esi+20]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+40],eax
    mov eax,[esi+24]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+44],eax
    mov eax,[esi+28]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+48],eax
    mov eax,[esi+32]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+52],eax
    mov eax,[esi+36]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+56],eax
    mov eax,[esi+40]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+60],eax
    mov eax,[esi+44]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+64],eax
    mov eax,[esi+48]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+68],eax
    mov eax,[esi+52]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+72],eax
    mov eax,[esi+56]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+76],eax
    mov eax,[esi+60]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+80],eax
    mov eax,[edi+72]
    xor eax,[edi+52]
    xor eax,[edi+28]
    xor eax,[edi+20]
    rol eax,1
    mov [edi+84],eax
    mov eax,[edi+76]
    xor eax,[edi+56]
    xor eax,[edi+32]
    xor eax,[edi+24]
    rol eax,1
    mov [edi+88],eax
    mov eax,[edi+80]
    xor eax,[edi+60]
    xor eax,[edi+36]
    xor eax,[edi+28]
    rol eax,1
    mov [edi+92],eax
    mov eax,[edi+84]
    xor eax,[edi+64]
    xor eax,[edi+40]
    xor eax,[edi+32]
    rol eax,1
    mov [edi+96],eax
    mov eax,[edi+88]
    xor eax,[edi+68]
    xor eax,[edi+44]
    xor eax,[edi+36]
    rol eax,1
    mov [edi+100],eax
    mov eax,[edi+92]
    xor eax,[edi+72]
    xor eax,[edi+48]
    xor eax,[edi+40]
    rol eax,1
    mov [edi+104],eax
    mov eax,[edi+96]
    xor eax,[edi+76]
    xor eax,[edi+52]
    xor eax,[edi+44]
    rol eax,1
    mov [edi+108],eax
    mov eax,[edi+100]
    xor eax,[edi+80]
    xor eax,[edi+56]
    xor eax,[edi+48]
    rol eax,1
    mov [edi+112],eax
    mov eax,[edi+104]
    xor eax,[edi+84]
    xor eax,[edi+60]
    xor eax,[edi+52]
    rol eax,1
    mov [edi+116],eax
    mov eax,[edi+108]
    xor eax,[edi+88]
    xor eax,[edi+64]
    xor eax,[edi+56]
    rol eax,1
    mov [edi+120],eax
    mov eax,[edi+112]
    xor eax,[edi+92]
    xor eax,[edi+68]
    xor eax,[edi+60]
    rol eax,1
    mov [edi+124],eax
    mov eax,[edi+116]
    xor eax,[edi+96]
    xor eax,[edi+72]
    xor eax,[edi+64]
    rol eax,1
    mov [edi+128],eax
    mov eax,[edi+120]
    xor eax,[edi+100]
    xor eax,[edi+76]
    xor eax,[edi+68]
    rol eax,1
    mov [edi+132],eax
    mov eax,[edi+124]
    xor eax,[edi+104]
    xor eax,[edi+80]
    xor eax,[edi+72]
    rol eax,1
    mov [edi+136],eax
    mov eax,[edi+128]
    xor eax,[edi+108]
    xor eax,[edi+84]
    xor eax,[edi+76]
    rol eax,1
    mov [edi+140],eax
    mov eax,[edi+132]
    xor eax,[edi+112]
    xor eax,[edi+88]
    xor eax,[edi+80]
    rol eax,1
    mov [edi+144],eax
    mov eax,[edi+136]
    xor eax,[edi+116]
    xor eax,[edi+92]
    xor eax,[edi+84]
    rol eax,1
    mov [edi+148],eax
    mov eax,[edi+140]
    xor eax,[edi+120]
    xor eax,[edi+96]
    xor eax,[edi+88]
    rol eax,1
    mov [edi+152],eax
    mov eax,[edi+144]
    xor eax,[edi+124]
    xor eax,[edi+100]
    xor eax,[edi+92]
    rol eax,1
    mov [edi+156],eax
    mov eax,[edi+148]
    xor eax,[edi+128]
    xor eax,[edi+104]
    xor eax,[edi+96]
    rol eax,1
    mov [edi+160],eax
    mov eax,[edi+152]
    xor eax,[edi+132]
    xor eax,[edi+108]
    xor eax,[edi+100]
    rol eax,1
    mov [edi+164],eax
    mov eax,[edi+156]
    xor eax,[edi+136]
    xor eax,[edi+112]
    xor eax,[edi+104]
    rol eax,1
    mov [edi+168],eax
    mov eax,[edi+160]
    xor eax,[edi+140]
    xor eax,[edi+116]
    xor eax,[edi+108]
    rol eax,1
    mov [edi+172],eax
    mov eax,[edi+164]
    xor eax,[edi+144]
    xor eax,[edi+120]
    xor eax,[edi+112]
    rol eax,1
    mov [edi+176],eax
    mov eax,[edi+168]
    xor eax,[edi+148]
    xor eax,[edi+124]
    xor eax,[edi+116]
    rol eax,1
    mov [edi+180],eax
    mov eax,[edi+172]
    xor eax,[edi+152]
    xor eax,[edi+128]
    xor eax,[edi+120]
    rol eax,1
    mov [edi+184],eax
    mov eax,[edi+176]
    xor eax,[edi+156]
    xor eax,[edi+132]
    xor eax,[edi+124]
    rol eax,1
    mov [edi+188],eax
    mov eax,[edi+180]
    xor eax,[edi+160]
    xor eax,[edi+136]
    xor eax,[edi+128]
    rol eax,1
    mov [edi+192],eax
    mov eax,[edi+184]
    xor eax,[edi+164]
    xor eax,[edi+140]
    xor eax,[edi+132]
    rol eax,1
    mov [edi+196],eax
    mov eax,[edi+188]
    xor eax,[edi+168]
    xor eax,[edi+144]
    xor eax,[edi+136]
    rol eax,1
    mov [edi+200],eax
    mov eax,[edi+192]
    xor eax,[edi+172]
    xor eax,[edi+148]
    xor eax,[edi+140]
    rol eax,1
    mov [edi+204],eax
    mov eax,[edi+196]
    xor eax,[edi+176]
    xor eax,[edi+152]
    xor eax,[edi+144]
    rol eax,1
    mov [edi+208],eax
    mov eax,[edi+200]
    xor eax,[edi+180]
    xor eax,[edi+156]
    xor eax,[edi+148]
    rol eax,1
    mov [edi+212],eax
    mov eax,[edi+204]
    xor eax,[edi+184]
    xor eax,[edi+160]
    xor eax,[edi+152]
    rol eax,1
    mov [edi+216],eax
    mov eax,[edi+208]
    xor eax,[edi+188]
    xor eax,[edi+164]
    xor eax,[edi+156]
    rol eax,1
    mov [edi+220],eax
    mov eax,[edi+212]
    xor eax,[edi+192]
    xor eax,[edi+168]
    xor eax,[edi+160]
    rol eax,1
    mov [edi+224],eax
    mov eax,[edi+216]
    xor eax,[edi+196]
    xor eax,[edi+172]
    xor eax,[edi+164]
    rol eax,1
    mov [edi+228],eax
    mov eax,[edi+220]
    xor eax,[edi+200]
    xor eax,[edi+176]
    xor eax,[edi+168]
    rol eax,1
    mov [edi+232],eax
    mov eax,[edi+224]
    xor eax,[edi+204]
    xor eax,[edi+180]
    xor eax,[edi+172]
    rol eax,1
    mov [edi+236],eax
    mov eax,[edi+228]
    xor eax,[edi+208]
    xor eax,[edi+184]
    xor eax,[edi+176]
    rol eax,1
    mov [edi+240],eax
    mov eax,[edi+232]
    xor eax,[edi+212]
    xor eax,[edi+188]
    xor eax,[edi+180]
    rol eax,1
    mov [edi+244],eax
    mov eax,[edi+236]
    xor eax,[edi+216]
    xor eax,[edi+192]
    xor eax,[edi+184]
    rol eax,1
    mov [edi+248],eax
    mov eax,[edi+240]
    xor eax,[edi+220]
    xor eax,[edi+196]
    xor eax,[edi+188]
    rol eax,1
    mov [edi+252],eax
    mov eax,[edi+244]
    xor eax,[edi+224]
    xor eax,[edi+200]
    xor eax,[edi+192]
    rol eax,1
    mov [edi+256],eax
    mov eax,[edi+248]
    xor eax,[edi+228]
    xor eax,[edi+204]
    xor eax,[edi+196]
    rol eax,1
    mov [edi+260],eax
    mov eax,[edi+252]
    xor eax,[edi+232]
    xor eax,[edi+208]
    xor eax,[edi+200]
    rol eax,1
    mov [edi+264],eax
    mov eax,[edi+256]
    xor eax,[edi+236]
    xor eax,[edi+212]
    xor eax,[edi+204]
    rol eax,1
    mov [edi+268],eax
    mov eax,[edi+260]
    xor eax,[edi+240]
    xor eax,[edi+216]
    xor eax,[edi+208]
    rol eax,1
    mov [edi+272],eax
    mov eax,[edi+264]
    xor eax,[edi+244]
    xor eax,[edi+220]
    xor eax,[edi+212]
    rol eax,1
    mov [edi+276],eax
    mov eax,[edi+268]
    xor eax,[edi+248]
    xor eax,[edi+224]
    xor eax,[edi+216]
    rol eax,1
    mov [edi+280],eax
    mov eax,[edi+272]
    xor eax,[edi+252]
    xor eax,[edi+228]
    xor eax,[edi+220]
    rol eax,1
    mov [edi+284],eax
    mov eax,[edi+276]
    xor eax,[edi+256]
    xor eax,[edi+232]
    xor eax,[edi+224]
    rol eax,1
    mov [edi+288],eax
    mov eax,[edi+280]
    xor eax,[edi+260]
    xor eax,[edi+236]
    xor eax,[edi+228]
    rol eax,1
    mov [edi+292],eax
    mov eax,[edi+284]
    xor eax,[edi+264]
    xor eax,[edi+240]
    xor eax,[edi+232]
    rol eax,1
    mov [edi+296],eax
    mov eax,[edi+288]
    xor eax,[edi+268]
    xor eax,[edi+244]
    xor eax,[edi+236]
    rol eax,1
    mov [edi+300],eax
    mov eax,[edi+292]
    xor eax,[edi+272]
    xor eax,[edi+248]
    xor eax,[edi+240]
    rol eax,1
    mov [edi+304],eax
    mov eax,[edi+296]
    xor eax,[edi+276]
    xor eax,[edi+252]
    xor eax,[edi+244]
    rol eax,1
    mov [edi+308],eax
    mov eax,[edi+300]
    xor eax,[edi+280]
    xor eax,[edi+256]
    xor eax,[edi+248]
    rol eax,1
    mov [edi+312],eax
    mov eax,[edi+304]
    xor eax,[edi+284]
    xor eax,[edi+260]
    xor eax,[edi+252]
    rol eax,1
    mov [edi+316],eax
    mov eax,[edi+308]
    xor eax,[edi+288]
    xor eax,[edi+264]
    xor eax,[edi+256]
    rol eax,1
    mov [edi+320],eax
    mov eax,[edi+312]
    xor eax,[edi+292]
    xor eax,[edi+268]
    xor eax,[edi+260]
    rol eax,1
    mov [edi+324],eax
    mov eax,[edi+316]
    xor eax,[edi+296]
    xor eax,[edi+272]
    xor eax,[edi+264]
    rol eax,1
    mov [edi+328],eax
    mov eax,[edi+320]
    xor eax,[edi+300]
    xor eax,[edi+276]
    xor eax,[edi+268]
    rol eax,1
    mov [edi+332],eax
    mov eax,[edi+324]
    xor eax,[edi+304]
    xor eax,[edi+280]
    xor eax,[edi+272]
    rol eax,1
    mov [edi+336],eax
    mov eax,[edi+0]
    mov ebx,[edi+4]
    mov ecx,[edi+8]
    mov edx,[edi+12]
    mov esi,[edi+16]
    add esi,[edi+20]
    add esi,1518500249
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ecx
    xor ebp,edx
    and ebp,ebx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+24]
    add edx,1518500249
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,ebx
    xor ebp,ecx
    and ebp,eax
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+28]
    add ecx,1518500249
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,eax
    xor ebp,ebx
    and ebp,esi
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+32]
    add ebx,1518500249
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,esi
    xor ebp,eax
    and ebp,edx
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+36]
    add eax,1518500249
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,edx
    xor ebp,esi
    and ebp,ecx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+40]
    add esi,1518500249
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ecx
    xor ebp,edx
    and ebp,ebx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+44]
    add edx,1518500249
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,ebx
    xor ebp,ecx
    and ebp,eax
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+48]
    add ecx,1518500249
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,eax
    xor ebp,ebx
    and ebp,esi
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+52]
    add ebx,1518500249
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,esi
    xor ebp,eax
    and ebp,edx
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+56]
    add eax,1518500249
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,edx
    xor ebp,esi
    and ebp,ecx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+60]
    add esi,1518500249
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ecx
    xor ebp,edx
    and ebp,ebx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+64]
    add edx,1518500249
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,ebx
    xor ebp,ecx
    and ebp,eax
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+68]
    add ecx,1518500249
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,eax
    xor ebp,ebx
    and ebp,esi
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+72]
    add ebx,1518500249
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,esi
    xor ebp,eax
    and ebp,edx
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+76]
    add eax,1518500249
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,edx
    xor ebp,esi
    and ebp,ecx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+80]
    add esi,1518500249
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ecx
    xor ebp,edx
    and ebp,ebx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+84]
    add edx,1518500249
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,ebx
    xor ebp,ecx
    and ebp,eax
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+88]
    add ecx,1518500249
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,eax
    xor ebp,ebx
    and ebp,esi
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+92]
    add ebx,1518500249
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,esi
    xor ebp,eax
    and ebp,edx
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+96]
    add eax,1518500249
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,edx
    xor ebp,esi
    and ebp,ecx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+100]
    add esi,1859775393
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+104]
    add edx,1859775393
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+108]
    add ecx,1859775393
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+112]
    add ebx,1859775393
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+116]
    add eax,1859775393
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+120]
    add esi,1859775393
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+124]
    add edx,1859775393
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+128]
    add ecx,1859775393
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+132]
    add ebx,1859775393
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+136]
    add eax,1859775393
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+140]
    add esi,1859775393
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+144]
    add edx,1859775393
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+148]
    add ecx,1859775393
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+152]
    add ebx,1859775393
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+156]
    add eax,1859775393
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+160]
    add esi,1859775393
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+164]
    add edx,1859775393
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+168]
    add ecx,1859775393
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+172]
    add ebx,1859775393
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+176]
    add eax,1859775393
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+180]
    add esi,-1894007588
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    and ebp,edx
    add esi,ebp
    mov ebp,ebx
    and ebp,ecx
    add esi,ebp
    rol ebx,30
    add edx,[edi+184]
    add edx,-1894007588
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    and ebp,ecx
    add edx,ebp
    mov ebp,eax
    and ebp,ebx
    add edx,ebp
    rol eax,30
    add ecx,[edi+188]
    add ecx,-1894007588
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    and ebp,ebx
    add ecx,ebp
    mov ebp,esi
    and ebp,eax
    add ecx,ebp
    rol esi,30
    add ebx,[edi+192]
    add ebx,-1894007588
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    and ebp,eax
    add ebx,ebp
    mov ebp,edx
    and ebp,esi
    add ebx,ebp
    rol edx,30
    add eax,[edi+196]
    add eax,-1894007588
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    and ebp,esi
    add eax,ebp
    mov ebp,ecx
    and ebp,edx
    add eax,ebp
    rol ecx,30
    add esi,[edi+200]
    add esi,-1894007588
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    and ebp,edx
    add esi,ebp
    mov ebp,ebx
    and ebp,ecx
    add esi,ebp
    rol ebx,30
    add edx,[edi+204]
    add edx,-1894007588
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    and ebp,ecx
    add edx,ebp
    mov ebp,eax
    and ebp,ebx
    add edx,ebp
    rol eax,30
    add ecx,[edi+208]
    add ecx,-1894007588
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    and ebp,ebx
    add ecx,ebp
    mov ebp,esi
    and ebp,eax
    add ecx,ebp
    rol esi,30
    add ebx,[edi+212]
    add ebx,-1894007588
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    and ebp,eax
    add ebx,ebp
    mov ebp,edx
    and ebp,esi
    add ebx,ebp
    rol edx,30
    add eax,[edi+216]
    add eax,-1894007588
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    and ebp,esi
    add eax,ebp
    mov ebp,ecx
    and ebp,edx
    add eax,ebp
    rol ecx,30
    add esi,[edi+220]
    add esi,-1894007588
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    and ebp,edx
    add esi,ebp
    mov ebp,ebx
    and ebp,ecx
    add esi,ebp
    rol ebx,30
    add edx,[edi+224]
    add edx,-1894007588
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    and ebp,ecx
    add edx,ebp
    mov ebp,eax
    and ebp,ebx
    add edx,ebp
    rol eax,30
    add ecx,[edi+228]
    add ecx,-1894007588
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    and ebp,ebx
    add ecx,ebp
    mov ebp,esi
    and ebp,eax
    add ecx,ebp
    rol esi,30
    add ebx,[edi+232]
    add ebx,-1894007588
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    and ebp,eax
    add ebx,ebp
    mov ebp,edx
    and ebp,esi
    add ebx,ebp
    rol edx,30
    add eax,[edi+236]
    add eax,-1894007588
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    and ebp,esi
    add eax,ebp
    mov ebp,ecx
    and ebp,edx
    add eax,ebp
    rol ecx,30
    add esi,[edi+240]
    add esi,-1894007588
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    and ebp,edx
    add esi,ebp
    mov ebp,ebx
    and ebp,ecx
    add esi,ebp
    rol ebx,30
    add edx,[edi+244]
    add edx,-1894007588
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    and ebp,ecx
    add edx,ebp
    mov ebp,eax
    and ebp,ebx
    add edx,ebp
    rol eax,30
    add ecx,[edi+248]
    add ecx,-1894007588
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    and ebp,ebx
    add ecx,ebp
    mov ebp,esi
    and ebp,eax
    add ecx,ebp
    rol esi,30
    add ebx,[edi+252]
    add ebx,-1894007588
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    and ebp,eax
    add ebx,ebp
    mov ebp,edx
    and ebp,esi
    add ebx,ebp
    rol edx,30
    add eax,[edi+256]
    add eax,-1894007588
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    and ebp,esi
    add eax,ebp
    mov ebp,ecx
    and ebp,edx
    add eax,ebp
    rol ecx,30
    add esi,[edi+260]
    add esi,-899497514
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+264]
    add edx,-899497514
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+268]
    add ecx,-899497514
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+272]
    add ebx,-899497514
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+276]
    add eax,-899497514
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+280]
    add esi,-899497514
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+284]
    add edx,-899497514
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+288]
    add ecx,-899497514
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+292]
    add ebx,-899497514
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+296]
    add eax,-899497514
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+300]
    add esi,-899497514
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+304]
    add edx,-899497514
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+308]
    add ecx,-899497514
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+312]
    add ebx,-899497514
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+316]
    add eax,-899497514
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add esi,[edi+320]
    add esi,-899497514
    mov ebp,eax
    rol ebp,5
    add esi,ebp
    mov ebp,ebx
    xor ebp,ecx
    xor ebp,edx
    add esi,ebp
    rol ebx,30
    add edx,[edi+324]
    add edx,-899497514
    mov ebp,esi
    rol ebp,5
    add edx,ebp
    mov ebp,eax
    xor ebp,ebx
    xor ebp,ecx
    add edx,ebp
    rol eax,30
    add ecx,[edi+328]
    add ecx,-899497514
    mov ebp,edx
    rol ebp,5
    add ecx,ebp
    mov ebp,esi
    xor ebp,eax
    xor ebp,ebx
    add ecx,ebp
    rol esi,30
    add ebx,[edi+332]
    add ebx,-899497514
    mov ebp,ecx
    rol ebp,5
    add ebx,ebp
    mov ebp,edx
    xor ebp,esi
    xor ebp,eax
    add ebx,ebp
    rol edx,30
    add eax,[edi+336]
    add eax,-899497514
    mov ebp,ebx
    rol ebp,5
    add eax,ebp
    mov ebp,ecx
    xor ebp,edx
    xor ebp,esi
    add eax,ebp
    rol ecx,30
    add [edi+0],eax
    add [edi+4],ebx
    add [edi+8],ecx
    add [edi+12],edx
    add [edi+16],esi
    pop ebp
    pop ebx
    pop edi
    pop esi
  end;
End;

Procedure Sha1Block(Var C : TSha1);
Begin
  Sha1Run(C, PBytes(@C.Blk), 0);
End;

Procedure Sha1Byte(Var C : TSha1; V : LongInt);
Begin
  C.Blk[C.BN] := V;
  Inc(C.BN); Inc(C.Len);
  If C.BN = 64 Then
  Begin
    Sha1Block(C);
    C.BN := 0;
  End;
End;

Procedure Sha1Ptr(Var C : TSha1; P : PBytes; Ofs, N : LongInt);
Var I, E : LongInt;
Begin
  I := Ofs; E := Ofs + N;
  While I < E Do
  Begin
    If (C.BN = 0) And (E - I >= 64) Then
    Begin
      { blocs entiers : directement depuis la source }
      Sha1Run(C, P, I);
      I := I + 64;
    End
    Else
    Begin
      C.Blk[C.BN] := P^[I];
      Inc(C.BN); Inc(I);
      If C.BN = 64 Then
      Begin
        Sha1Block(C);
        C.BN := 0;
      End;
    End;
  End;
  C.Len := C.Len + N;
End;

Procedure Sha1Mem(Var C : TSha1; Var B : TBuf; Ofs, N : LongInt);
Begin
  Sha1Ptr(C, B.P, Ofs, N);
End;

Procedure Sha1Str(Var C : TSha1; Const S : String);
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do Sha1Byte(C, Ord(S[I]));
End;

Procedure Sha1Put(Var H : TSha; V, At : LongInt);
Begin
  H[At] := (V Shr 24) And 255; H[At + 1] := (V Shr 16) And 255;
  H[At + 2] := (V Shr 8) And 255; H[At + 3] := V And 255;
End;

Procedure Sha1Final(Var C : TSha1; Var H : TSha);
Var L, I : LongInt;
Begin
  L := C.Len;
  Sha1Byte(C, $80);
  While C.BN <> 56 Do Sha1Byte(C, 0);
  { longueur en bits sur 64 bits (moins de 512 Mo) }
  For I := 0 To 2 Do Sha1Byte(C, 0);
  Sha1Byte(C, (L Shr 29) And 7);
  Sha1Byte(C, (L Shr 21) And 255);
  Sha1Byte(C, (L Shr 13) And 255);
  Sha1Byte(C, (L Shr 5) And 255);
  Sha1Byte(C, (L Shl 3) And 255);
  Sha1Put(H, C.H0, 0); Sha1Put(H, C.H1, 4); Sha1Put(H, C.H2, 8);
  Sha1Put(H, C.H3, 12); Sha1Put(H, C.H4, 16);
End;

Var
  CrcTab : Array[0..255] Of LongInt;
  CrcReady : Boolean;

Procedure CrcInit;
Var I, J, C : LongInt;
Begin
  For I := 0 To 255 Do
  Begin
    C := I;
    For J := 0 To 7 Do
      If (C And 1) <> 0 Then C := LongInt($EDB88320) Xor (C Shr 1)
      Else C := C Shr 1;
    CrcTab[I] := C;
  End;
  CrcReady := True;
End;

Function Crc32(Var B : TBuf; Ofs, N : LongInt) : LongInt;
Var C, I : LongInt;
Begin
  If Not CrcReady Then CrcInit;
  C := LongInt($FFFFFFFF);
  For I := Ofs To Ofs + N - 1 Do
    C := CrcTab[(C Xor B.P^[I]) And 255] Xor (C Shr 8);
  Crc32 := Not C;
End;

{ Adler-32 en continu : V = valeur precedente (1 au debut) }
Function AdlerUpd(V : LongInt; P : PBytes; Ofs, N : LongInt) : LongInt;
Var A, S, I : LongInt;
Begin
  A := V And $FFFF; S := (V Shr 16) And $FFFF;
  For I := Ofs To Ofs + N - 1 Do
  Begin
    A := A + P^[I];
    If A >= 65521 Then A := A - 65521;
    S := S + A;
    If S >= 65521 Then S := S - 65521;
  End;
  AdlerUpd := (S Shl 16) Or A;
End;

Function Adler32(Var B : TBuf; Ofs, N : LongInt) : LongInt;
Begin
  Adler32 := AdlerUpd(1, B.P, Ofs, N);
End;

{ ==================================================================== }
{ zlib : inflate (blocs stockes, Huffman fixe et dynamique) et deflate  }
{ (blocs stockes)                                                       }
{ ==================================================================== }

Type
  THuff = Record
    Cnt : Array[0..15] Of LongInt;
    Sym : Array[0..287] Of LongInt;
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

Const
  ZChunk = 32768;

Type
  TZChunk = Array[0..ZChunk - 1] Of Byte;

Var
  ZIn : PBytes;                        { entree de l'inflate }
  ZPos, ZEnd, ZBit, ZBitN : LongInt;
  ZErr : Boolean;
  ZLitW, ZDst, ZFixL, ZFixD : THuff;
  ZFixOk : Boolean;
  { entree depuis un fichier : tampon ZInB, ZFBase = position (fichier) de
    ZInB[0] }
  ZFH, ZFBase, ZFSize : LongInt;
  ZInB : ^TZChunk;
  { sortie : memoire (ZMem, ZO) ou flux (fenetre de 32 Ko, puis fichier
    ZOutH et/ou empreinte ZSha) }
  ZMem : Boolean;
  ZO : ^TBuf;
  ZWin, ZOB : ^TZChunk;
  ZOBN, ZTotal, ZLimit, ZOutH, ZSkip : LongInt;
  ZShaOn, ZStop : Boolean;

Const
  LenBase : Array[0..28] Of LongInt = (3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17,
    19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258);
  LenExtra : Array[0..28] Of LongInt = (0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
    2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0);
  DistBase : Array[0..29] Of LongInt = (1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33,
    49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097,
    6145, 8193, 12289, 16385, 24577);
  DistExtra : Array[0..29] Of LongInt = (0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4,
    5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13);
  ClOrder : Array[0..18] Of LongInt = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11,
    4, 12, 3, 13, 2, 14, 1, 15);

{ entree depuis un fichier : lit le morceau suivant }
Function ZRefill : Boolean;
Var N : LongInt;
Begin
  ZRefill := False;
  If ZFH < 0 Then Exit;
  ZFBase := ZFBase + ZEnd;
  N := ZFSize - ZFBase;
  If N > ZChunk Then N := ZChunk;
  If N <= 0 Then Exit;
  N := FReadAt(ZFH, ZFBase, PBytes(ZInB), N);
  If N <= 0 Then Exit;
  ZIn := PBytes(ZInB); ZPos := 0; ZEnd := N;
  ZRefill := True;
End;

Function ZByteIn : LongInt;
Begin
  ZByteIn := -1;
  If ZPos >= ZEnd Then
    If Not ZRefill Then Exit;
  ZByteIn := ZIn^[ZPos];
  Inc(ZPos);
End;

{ sortie en flux : vide le tampon vers le fichier et l'empreinte }
Var
  ZSha : TSha1;

Procedure ZFlush;
Begin
  If ZOBN <= 0 Then Exit;
  If ZShaOn Then Sha1Ptr(ZSha, PBytes(ZOB), 0, ZOBN);
  If ZOutH >= 0 Then
    If Not FWrite(ZOutH, PBytes(ZOB), ZOBN) Then ZErr := True;
  ZOBN := 0;
End;

Procedure ZOut(V : LongInt);
Begin
  If ZMem Then
  Begin
    If ZO^.N >= ZO^.Cap Then BufNeed(ZO^, ZO^.N + 1);
    If ZO^.N >= ZO^.Cap Then
    Begin
      ZErr := True; Exit;
    End;
    ZO^.P^[ZO^.N] := V; Inc(ZO^.N);
  End
  Else
  Begin
    ZWin^[ZTotal And (ZChunk - 1)] := V;
    If ZSkip > 0 Then Dec(ZSkip)
    Else
    Begin
      ZOB^[ZOBN] := V; Inc(ZOBN);
      If ZOBN >= ZChunk Then ZFlush;
    End;
  End;
  Inc(ZTotal);
  If ZTotal >= ZLimit Then ZStop := True;
End;

Function ZBits(N : LongInt) : LongInt;
Var V : LongInt;
Begin
  While ZBitN < N Do
  Begin
    If ZPos >= ZEnd Then
      If Not ZRefill Then
      Begin
        ZErr := True;
        ZBits := 0;
        Exit;
      End;
    ZBit := ZBit Or (ZIn^[ZPos] Shl ZBitN);
    Inc(ZPos);
    ZBitN := ZBitN + 8;
  End;
  V := ZBit And ((1 Shl N) - 1);
  ZBit := ZBit Shr N;
  ZBitN := ZBitN - N;
  ZBits := V;
End;

Procedure HuffBuild(Var H : THuff; Var Lens : Array Of LongInt; N : LongInt);
Var Offs : Array[0..15] Of LongInt; I : LongInt;
Begin
  For I := 0 To 15 Do H.Cnt[I] := 0;
  For I := 0 To N - 1 Do Inc(H.Cnt[Lens[I]]);
  H.Cnt[0] := 0;
  Offs[1] := 0;
  For I := 1 To 14 Do Offs[I + 1] := Offs[I] + H.Cnt[I];
  For I := 0 To N - 1 Do
    If Lens[I] <> 0 Then
    Begin
      H.Sym[Offs[Lens[I]]] := I;
      Inc(Offs[Lens[I]]);
    End;
End;

Function HuffDecode(Var H : THuff) : LongInt;
Var Code, First, Index, Len, C : LongInt;
Begin
  Code := 0; First := 0; Index := 0;
  For Len := 1 To 15 Do
  Begin
    { un bit (ZBits(1) en ligne : c'est la boucle la plus parcourue) }
    If ZBitN = 0 Then
    Begin
      If ZPos >= ZEnd Then
        If Not ZRefill Then
        Begin
          ZErr := True; HuffDecode := -1; Exit;
        End;
      ZBit := ZIn^[ZPos];
      Inc(ZPos);
      ZBitN := 8;
    End;
    Code := Code Or (ZBit And 1);
    ZBit := ZBit Shr 1;
    Dec(ZBitN);
    C := H.Cnt[Len];
    If Code - C < First Then
    Begin
      HuffDecode := H.Sym[Index + (Code - First)];
      Exit;
    End;
    Index := Index + C;
    First := (First + C) Shl 1;
    Code := Code Shl 1;
  End;
  ZErr := True;
  HuffDecode := -1;
End;

Procedure ZFixed;
Var L : Array[0..287] Of LongInt; I : LongInt;
Begin
  For I := 0 To 143 Do L[I] := 8;
  For I := 144 To 255 Do L[I] := 9;
  For I := 256 To 279 Do L[I] := 7;
  For I := 280 To 287 Do L[I] := 8;
  HuffBuild(ZFixL, L, 288);
  For I := 0 To 29 Do L[I] := 5;
  HuffBuild(ZFixD, L, 30);
  ZFixOk := True;
End;

Function ZCodes(Var Lit, Dst : THuff) : Boolean;
Var S, Len, D, I, K : LongInt;
Begin
  ZCodes := False;
  Repeat
    S := HuffDecode(Lit);
    If S < 0 Then Exit;
    If S < 256 Then ZOut(S)
    Else If S > 256 Then
    Begin
      S := S - 257;
      If S > 28 Then Exit;
      Len := LenBase[S] + ZBits(LenExtra[S]);
      D := HuffDecode(Dst);
      If (D < 0) Or (D > 29) Then Exit;
      D := DistBase[D] + ZBits(DistExtra[D]);
      If ZErr Or (D > ZTotal) Or (D > ZChunk) Then Exit;
      If ZMem Then
      Begin
        BufNeed(ZO^, ZO^.N + Len);
        If ZO^.N + Len > ZO^.Cap Then Exit;
        K := ZO^.N - D;
        For I := 0 To Len - 1 Do ZO^.P^[ZO^.N + I] := ZO^.P^[K + I];
        ZO^.N := ZO^.N + Len;
        ZTotal := ZTotal + Len;
        If ZTotal >= ZLimit Then ZStop := True;
      End
      Else
        For I := 1 To Len Do ZOut(ZWin^[(ZTotal - D) And (ZChunk - 1)]);
    End;
    If ZStop Then
    Begin
      ZCodes := True; Exit;
    End;
  Until S = 256;
  ZCodes := Not ZErr;
End;

Function ZDynamic : Boolean;
Var L : Array[0..319] Of LongInt; NL, ND, NC, I, S, Prev, R : LongInt;
    CL : THuff;
Begin
  ZDynamic := False;
  NL := ZBits(5) + 257; ND := ZBits(5) + 1; NC := ZBits(4) + 4;
  For I := 0 To 18 Do L[I] := 0;
  For I := 0 To NC - 1 Do L[ClOrder[I]] := ZBits(3);
  HuffBuild(CL, L, 19);
  I := 0;
  While I < NL + ND Do
  Begin
    S := HuffDecode(CL);
    If S < 0 Then Exit;
    If S < 16 Then
    Begin
      L[I] := S; Inc(I);
    End
    Else
    Begin
      Prev := 0;
      If S = 16 Then
      Begin
        If I = 0 Then Exit;
        Prev := L[I - 1];
        R := 3 + ZBits(2);
      End
      Else If S = 17 Then R := 3 + ZBits(3)
      Else R := 11 + ZBits(7);
      If I + R > NL + ND Then Exit;
      While R > 0 Do
      Begin
        L[I] := Prev; Inc(I); Dec(R);
      End;
    End;
  End;
  If ZErr Then Exit;
  HuffBuild(ZLitW, L, NL);
  For I := 0 To ND - 1 Do L[I] := L[NL + I];
  HuffBuild(ZDst, L, ND);
  ZDynamic := True;
End;

{ source de l'inflate : memoire (Src, de Ofs a Ofs + Lim) ou fichier
  (poignee H, a partir de Pos) }
Procedure ZSrcMem(Var Src : TBuf; Ofs, Lim : LongInt);
Begin
  ZFH := -1;
  ZIn := Src.P; ZPos := Ofs; ZEnd := Ofs + Lim; ZFBase := 0;
End;

Procedure ZSrcFile(H, Pos : LongInt);
Begin
  If ZInB = Nil Then GetMem(ZInB, ZChunk);
  ZFH := H; ZFSize := FSize(H);
  ZFBase := Pos; ZEnd := 0; ZPos := 0;
  ZIn := PBytes(ZInB);
End;

{ destination : memoire (ajoute a O) ou flux (fichier OutH >= 0 et/ou
  empreinte ZSha si UseSha ; Skip octets ignores au debut) }
Procedure ZDstMem(Var O : TBuf);
Begin
  ZMem := True; ZO := @O;
End;

Procedure ZDstStream(OutH : LongInt; UseSha : Boolean; Skip : LongInt);
Begin
  If ZWin = Nil Then
  Begin
    GetMem(ZWin, ZChunk); GetMem(ZOB, ZChunk);
  End;
  ZMem := False; ZOutH := OutH; ZShaOn := UseSha; ZSkip := Skip;
  ZOBN := 0;
End;

{ decompresse le flux zlib ; s'arrete apres Limit octets produits ;
  Used : octets du flux consommes }
Function ZRun(Limit : LongInt; Var Used : LongInt) : Boolean;
Var Fin, Typ, Len, NLen, Start, I, C : LongInt; Ok : Boolean;
Begin
  ZRun := False;
  Used := 0;
  Start := ZFBase + ZPos;
  ZBit := 0; ZBitN := 0; ZErr := False; ZStop := False;
  ZTotal := 0; ZLimit := Limit;
  C := ZByteIn;
  If (C < 0) Or ((C And 15) <> 8) Then Exit;
  If ZByteIn < 0 Then Exit;
  If Not ZFixOk Then ZFixed;
  Repeat
    Fin := ZBits(1);
    Typ := ZBits(2);
    If ZErr Then Exit;
    Case Typ Of
      0 :
        Begin
          ZBit := 0; ZBitN := 0;
          Len := ZByteIn; C := ZByteIn;
          Len := Len Or (C Shl 8);
          NLen := ZByteIn; C := ZByteIn;
          If C < 0 Then Exit;
          NLen := NLen Or (C Shl 8);
          If ((Len Xor NLen) And $FFFF) <> $FFFF Then Exit;
          For I := 1 To Len Do
          Begin
            C := ZByteIn;
            If C < 0 Then Exit;
            ZOut(C);
            If ZStop Then Break;
          End;
        End;
      1 : If Not ZCodes(ZFixL, ZFixD) Then Exit;
      2 :
        Begin
          If Not ZDynamic Then Exit;
          Ok := ZCodes(ZLitW, ZDst);
          If Not Ok Then Exit;
        End;
    Else
      Exit;
    End;
    If ZStop Then
    Begin
      If Not ZMem Then ZFlush;
      ZRun := Not ZErr;
      Exit;
    End;
  Until Fin = 1;
  If Not ZMem Then ZFlush;
  If ZErr Then Exit;
  { octets entiers restants dans le tampon de bits : rendus }
  ZPos := ZPos - (ZBitN Div 8);
  Used := ZFBase + ZPos + 4 - Start;     { Adler-32 }
  ZRun := True;
End;

{ flux zlib (en-tete, blocs, Adler-32) de Src a partir de Ofs -> O
  (ajoute) ; Used : octets consommes ; faux si le flux est invalide }
Function ZInflate(Var Src : TBuf; Ofs, Lim : LongInt; Var O : TBuf;
  Var Used : LongInt) : Boolean;
Begin
  ZInflate := False;
  Used := 0;
  If Lim < 6 Then Exit;
  ZSrcMem(Src, Ofs, Lim);
  ZDstMem(O);
  ZInflate := ZRun($7FFFFFFF, Used);
  If Used > Lim Then Used := Lim;
End;

{ flux zlib de N octets de Src (blocs stockes) -> O (ajoute) }
{ compression : LZ77 (chaines de hachage) + codes de Huffman fixes }
Var
  ZoBuf, ZoCnt : LongInt;
  ZHead : ^TLongArr4;
  ZPrev : ^TLongArr4;

Procedure ZPut(Var O : TBuf; V, N : LongInt);
Begin
  ZoBuf := ZoBuf Or (V Shl ZoCnt);
  Inc(ZoCnt, N);
  While ZoCnt >= 8 Do
  Begin
    BufByte(O, ZoBuf And 255);
    ZoBuf := ZoBuf Shr 8;
    Dec(ZoCnt, 8);
  End;
End;

{ code de Huffman (bits de poids fort d'abord) }
Procedure ZPutRev(Var O : TBuf; Code, N : LongInt);
Var R, I : LongInt;
Begin
  R := 0;
  For I := 1 To N Do
  Begin
    R := (R Shl 1) Or (Code And 1);
    Code := Code Shr 1;
  End;
  ZPut(O, R, N);
End;

Procedure ZEmit(Var O : TBuf; V : LongInt);
Begin
  If V < 144 Then ZPutRev(O, $30 + V, 8)
  Else If V < 256 Then ZPutRev(O, $190 + V - 144, 9)
  Else If V < 280 Then ZPutRev(O, V - 256, 7)
  Else ZPutRev(O, $C0 + V - 280, 8);
End;

Procedure ZMatch(Var O : TBuf; L, D : LongInt);
Var K : LongInt;
Begin
  K := 28;
  While LenBase[K] > L Do Dec(K);
  ZEmit(O, 257 + K);
  If LenExtra[K] > 0 Then ZPut(O, L - LenBase[K], LenExtra[K]);
  K := 29;
  While DistBase[K] > D Do Dec(K);
  ZPutRev(O, K, 5);
  If DistExtra[K] > 0 Then ZPut(O, D - DistBase[K], DistExtra[K]);
End;

Procedure ZDeflate(Var Src : TBuf; Ofs, N : LongInt; Var O : TBuf);
Const HSize = 32768; Win = 32768; MaxChain = 48;
Var I, J, H, A, Best, BestD, L, C, Lim, E : LongInt; P : PBytes;
Begin
  BufByte(O, $78); BufByte(O, $9C);
  If ZHead = Nil Then
  Begin
    GetMem(ZHead, HSize * 4); GetMem(ZPrev, Win * 4);
  End;
  For I := 0 To HSize - 1 Do ZHead^[I] := -1;
  ZoBuf := 0; ZoCnt := 0;
  ZPut(O, 1, 1); ZPut(O, 1, 2);        { bloc final, Huffman fixe }
  P := Src.P;
  E := Ofs + N;
  I := Ofs;
  While I < E Do
  Begin
    Best := 0; BestD := 0;
    If I + 2 < E Then
    Begin
      H := ((P^[I] Shl 10) Xor (P^[I + 1] Shl 5) Xor P^[I + 2]) And
        (HSize - 1);
      J := ZHead^[H];
      C := 0;
      Lim := MinL(258, E - I);
      While (J >= 0) And (I - J <= Win - 1) And (C < MaxChain) Do
      Begin
        If (P^[J + Best] = P^[I + Best]) And (P^[J] = P^[I]) Then
        Begin
          L := 0;
          While (L < Lim) And (P^[J + L] = P^[I + L]) Do Inc(L);
          If L > Best Then
          Begin
            Best := L; BestD := I - J;
            If L >= Lim Then Break;
          End;
        End;
        J := ZPrev^[J And (Win - 1)];
        Inc(C);
      End;
      ZPrev^[I And (Win - 1)] := ZHead^[H];
      ZHead^[H] := I;
    End;
    If Best >= 3 Then
    Begin
      ZMatch(O, Best, BestD);
      { insere les positions couvertes dans les chaines }
      For J := I + 1 To I + Best - 1 Do
        If J + 2 < E Then
        Begin
          H := ((P^[J] Shl 10) Xor (P^[J + 1] Shl 5) Xor P^[J + 2]) And
            (HSize - 1);
          ZPrev^[J And (Win - 1)] := ZHead^[H];
          ZHead^[H] := J;
        End;
      Inc(I, Best);
    End
    Else
    Begin
      ZEmit(O, P^[I]);
      Inc(I);
    End;
  End;
  ZEmit(O, 256);
  If ZoCnt > 0 Then ZPut(O, 0, 8 - ZoCnt);
  A := Adler32(Src, Ofs, N);
  BufByte(O, (A Shr 24) And 255); BufByte(O, (A Shr 16) And 255);
  BufByte(O, (A Shr 8) And 255); BufByte(O, A And 255);
End;
{ ==================================================================== }
{ Fichiers                                                              }
{ ==================================================================== }

{ chemins ASCIIZ pour DOSCALLS (sous le verrou : un seul fil a la fois) }
Var
  FZ, FZ2 : Array[0..299] Of Byte;

Function FZa(Const P : String) : LongInt;
Begin
  PutZA(LongInt(@FZ), P);
  FZa := LongInt(@FZ);
End;

Function FZb(Const P : String) : LongInt;
Begin
  PutZA(LongInt(@FZ2), P);
  FZb := LongInt(@FZ2);
End;

{ attributs de P (FILESTATUS3 de DosQueryPathInfo) ; -1 s'il n'existe pas }
Function FAttr(Const P : String) : LongInt;
Var B : Array[0..31] Of Byte;
Begin
  If DosQueryPathInfo(FZa(P), 1, LongInt(@B), 24) <> 0 Then FAttr := -1
  Else FAttr := PLng(LongInt(@B) + 20)^ And $37;
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
  If R < 0 Then R := 0;
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

{ fichier (pas un dossier) existant }
Function FileExist(Const Path : String) : Boolean;
Var A : LongInt;
Begin
  A := FAttr(Path);
  FileExist := (A >= 0) And ((A And $10) = 0);
End;

Function DirExist(Const Path : String) : Boolean;
Var A : LongInt;
Begin
  A := FAttr(Path);
  DirExist := (A >= 0) And ((A And $10) <> 0);
End;

Procedure FileDel(Const Path : String);
Begin
  Dummy0 := DosDelete(FZa(Path));
End;

Function FileRen(Const A, B : String) : Boolean;
Begin
  FileDel(B);
  FileRen := DosMove(FZa(A), FZb(B)) = 0;
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
  Dummy0 := DosCreateDir(FZa(P), 0);
End;

{ chemin Git (a/b/c) -> chemin du systeme }
Function OsPath(Const S : String) : String;
Var T : String; I : LongInt;
Begin
  T := S;
  For I := 1 To Length(T) Do If T[I] = '/' Then T[I] := PS;
  OsPath := T;
End;

{ heure de modification d'un fichier (format DOS : date Shl 16 Or heure)
  et taille (DosQueryPathInfo, FILESTATUS3) }
Function FileStat(Const Path : String; Var Size, Tm : LongInt) : Boolean;
Var B : Array[0..31] Of Byte;
Begin
  FileStat := False;
  Size := 0; Tm := 0;
  If DosQueryPathInfo(FZa(Path), 1, LongInt(@B), 24) <> 0 Then Exit;
  If (B[20] And $10) <> 0 Then Exit;
  Size := PLng(LongInt(@B) + 12)^;
  Tm := ((B[8] Or (B[9] Shl 8)) Shl 16) Or (B[10] Or (B[11] Shl 8));
  FileStat := True;
End;

{ recherche de fichiers (DosFindFirst, FILEFINDBUF3) : FindFirstF puis
  FindNextF tant que vrai ; FindName, FindAttr, FindSize, FindTime ;
  FindCloseF }
Type
  TFind = Record
    H, N : LongInt;
    B : Array[0..299] Of Byte;
  End;

Function FindFirstF(Const Spec : String; Var F : TFind) : Boolean;
Begin
  F.H := -1; F.N := 1;
  FindFirstF := (DosFindFirst(FZa(Spec), LongInt(@F.H), $37, LongInt(@F.B),
    300, LongInt(@F.N), 1) = 0) And (F.N > 0);
End;

Function FindNextF(Var F : TFind) : Boolean;
Begin
  F.N := 1;
  FindNextF := (DosFindNext(F.H, LongInt(@F.B), 300, LongInt(@F.N)) = 0) And
    (F.N > 0);
End;

Procedure FindCloseF(Var F : TFind);
Begin
  If F.H <> -1 Then Dummy0 := DosFindClose(F.H);
  F.H := -1;
End;

Function FindName(Var F : TFind) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  For K := 0 To F.B[28] - 1 Do S := S + Chr(F.B[29 + K]);
  FindName := S;
End;

Function FindAttr(Var F : TFind) : LongInt;
Begin
  FindAttr := PLng(LongInt(@F.B[24]))^;
End;

Function FindSize(Var F : TFind) : LongInt;
Begin
  FindSize := PLng(LongInt(@F.B[16]))^;
End;

Function FindTime(Var F : TFind) : LongInt;
Begin
  FindTime := ((F.B[12] Or (F.B[13] Shl 8)) Shl 16) Or
    (F.B[14] Or (F.B[15] Shl 8));
End;

{ ANSI (1252) <-> page de codes 850 (ecran et noms de fichiers
  d'OS/2-0) }
Const
  AnsiOem : Array[128..255] Of Byte = (
    69, 63, 44, 102, 34, 46, 197, 206, 94, 63, 83, 60, 79, 63, 90, 63, 63,
    39, 39, 34, 34, 249, 45, 45, 126, 159, 115, 62, 111, 63, 122, 89, 255,
    173, 155, 156, 63, 157, 124, 21, 34, 169, 166, 174, 170, 45, 158, 196,
    248, 241, 253, 51, 39, 230, 20, 250, 44, 49, 167, 175, 172, 171, 63,
    168, 65, 65, 65, 65, 142, 143, 146, 128, 69, 144, 69, 69, 73, 73, 73,
    73, 68, 165, 79, 79, 79, 79, 153, 120, 79, 85, 85, 85, 154, 89, 63, 225,
    133, 160, 131, 97, 132, 134, 145, 135, 138, 130, 136, 137, 141, 161, 140,
    139, 63, 164, 149, 162, 147, 111, 148, 246, 111, 151, 163, 150, 129, 121,
    63, 152);

Function AnsiToOem(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If Ord(S[K]) >= 128 Then S[K] := Chr(AnsiOem[Ord(S[K])]);
  AnsiToOem := S;
End;

Function OemToAnsi(S : String) : String;
Var K, C : LongInt;
Begin
  For K := 1 To Length(S) Do
    If Ord(S[K]) >= 128 Then
      For C := 160 To 255 Do
        If AnsiOem[C] = Ord(S[K]) Then
        Begin
          S[K] := Chr(C);
          Break;
        End;
  OemToAnsi := S;
End;

{ ==================================================================== }
{ Objets Git : libres (objects/xx/...) et packs (objects/pack)          }
{ ==================================================================== }

Const
  OtCommit = 1; OtTree = 2; OtBlob = 3; OtTag = 4; OtOfsDelta = 6;
  OtRefDelta = 7;
  MaxPack = 100;
  IxK = MaxPack;                       { pack en cours d'indexation }
  BigObj = 2097152;                    { objet plus grand : fichier }

Type
  { pack : l'index (.idx) est en memoire, le .pack est lu dans le fichier
    (un pack peut faire des centaines de Mo) }
  TPack = Record
    Name : String;                     { chemin sans extension }
    Idx : TBuf;
    N, H, Size : LongInt;              { objets, poignee du .pack }
    Loaded : Boolean;
  End;

Var
  GitDir, WorkDir : String;            { .git et dossier de travail }
  Packs : Array[0..MaxPack] Of TPack;
  PackN : LongInt;
  PacksRead : Boolean;

Function TypeName(T : LongInt) : String;
Begin
  Case T Of
    OtCommit : TypeName := 'commit';
    OtTree : TypeName := 'tree';
    OtBlob : TypeName := 'blob';
    OtTag : TypeName := 'tag';
  Else
    TypeName := '?';
  End;
End;

Function TypeOfName(Const S : String) : LongInt;
Begin
  If S = 'commit' Then TypeOfName := OtCommit
  Else If S = 'tree' Then TypeOfName := OtTree
  Else If S = 'blob' Then TypeOfName := OtBlob
  Else If S = 'tag' Then TypeOfName := OtTag
  Else TypeOfName := 0;
End;

Function ObjPath(Const H : TSha) : String;
Var S : String;
Begin
  S := ShaHex(H);
  ObjPath := GitDir + PS + 'objects' + PS + Copy(S, 1, 2) + PS +
             Copy(S, 3, 38);
End;

{ empreinte d'un objet (en-tete "type taille\0" puis contenu) }
Procedure ObjHash(T : LongInt; Var D : TBuf; Ofs, N : LongInt; Var H : TSha);
Var C : TSha1;
Begin
  Sha1Init(C);
  Sha1Str(C, TypeName(T) + ' ' + IStr(N));
  Sha1Byte(C, 0);
  Sha1Mem(C, D, Ofs, N);
  Sha1Final(C, H);
End;

{ ------------------------------------------------------------------ }
{ Fichiers temporaires (gros objets) dans .git\pasgit                  }
{ ------------------------------------------------------------------ }

Function TmpPath(Const N : String) : String;
Begin
  MkDirs(GitDir + PS + 'pasgit');
  TmpPath := GitDir + PS + 'pasgit' + PS + N;
End;

{ copie un fichier par morceaux }
Function FileCopy(Const A, B : String) : Boolean;
Var HA, HB, N, Pos : LongInt; Ch : TBuf;
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
  BufNeed(Ch, ZChunk);
  Pos := 0;
  FileCopy := Ch.Cap >= ZChunk;
  If Ch.Cap >= ZChunk Then
    Repeat
      N := FReadAt(HA, Pos, Ch.P, ZChunk);
      If N <= 0 Then Break;
      If Not FWrite(HB, Ch.P, N) Then
      Begin
        FileCopy := False; Break;
      End;
      Pos := Pos + N;
    Until False;
  BufFree(Ch);
  FClose(HA); FClose(HB);
End;

{ empreinte d'un fichier lu par morceaux (en-tete d'objet de type T) }
Function HashFile(Const Path : String; T : LongInt; Var H : TSha)
  : Boolean;
Var F, Sz, Pos, N : LongInt; C : TSha1; Ch : TBuf;
Begin
  HashFile := False;
  F := FOpenR(Path);
  If F < 0 Then Exit;
  Sz := FSize(F);
  BufInit(Ch);
  BufNeed(Ch, ZChunk);
  If Ch.Cap >= ZChunk Then
  Begin
    Sha1Init(C);
    Sha1Str(C, TypeName(T) + ' ' + IStr(Sz));
    Sha1Byte(C, 0);
    Pos := 0;
    While Pos < Sz Do
    Begin
      N := FReadAt(F, Pos, Ch.P, MinL(ZChunk, Sz - Pos));
      If N <= 0 Then Break;
      Sha1Ptr(C, Ch.P, 0, N);
      Pos := Pos + N;
    End;
    Sha1Final(C, H);
    HashFile := Pos = Sz;
  End;
  BufFree(Ch);
  FClose(F);
End;

{ cache des gros objets resolus (fichiers) : bases des chaines de deltas
  de gros fichiers (images ISO...) }
Const
  BigN = 6;

{ derniere base de delta chargee en memoire, en morceaux de 1 Mo (un
  seul bloc de plusieurs dizaines de Mo n'est souvent pas disponible
  quand la memoire est fragmentee) }
Const
  CkSz = 1048576;
  CkMax = 32;

Var
  BaseCk : Array[0..CkMax - 1] Of PBytes;
  BaseCkN, BaseCkLen : LongInt;        { morceaux, taille de la base }
  DUseCk : Boolean;                    { DeltaApplyX : base = BaseCk }
  BaseCFn : String;                    { son fichier (cache des gros objets) }
  BigK, BigOfs, BigT, BigSz : Array[0..BigN - 1] Of LongInt;
  BigSha : Array[0..BigN - 1] Of TSha;     { empreinte de l'objet }
  BigUse : Array[0..BigN - 1] Of LongInt;  { dernier usage (LRU) }
  BigTick : LongInt;
  BigNext, BigMade, BaseLoads, BaseHits : LongInt;

Function BigFile(I : LongInt) : String;
Begin
  BigFile := TmpPath('big' + IStr(I) + '.tmp');
End;

Procedure BaseCDrop;
Var I : LongInt;
Begin
  For I := 0 To BaseCkN - 1 Do FreeMem(BaseCk[I], CkSz);
  BaseCkN := 0; BaseCkLen := -1;
  BaseCFn := '';
End;

{ lit tout le fichier H dans BaseCk ; faux si la memoire manque }
Function BaseCLoad(H : LongInt) : Boolean;
Var Sz, Pos, N, I : LongInt;
Begin
  BaseCLoad := False;
  BaseCDrop;
  Sz := FSize(H);
  If (Sz < 0) Or (Sz > CkMax * CkSz) Then Exit;
  While BaseCkN * CkSz < Sz Do
  Begin
    GetMem(BaseCk[BaseCkN], CkSz);
    If BaseCk[BaseCkN] = Nil Then
    Begin
      BaseCDrop; Exit;
    End;
    Inc(BaseCkN);
  End;
  Pos := 0;
  While Pos < Sz Do
  Begin
    I := Pos Div CkSz;
    N := FReadAt(H, Pos, BaseCk[I], MinL(CkSz, Sz - Pos));
    If N <= 0 Then Break;
    Pos := Pos + N;
  End;
  If Pos <> Sz Then
  Begin
    BaseCDrop; Exit;
  End;
  BaseCkLen := Sz;
  BaseCLoad := True;
End;

Procedure BigClear;
Var I : LongInt;
Begin
  BaseCDrop;
  For I := 0 To BigN - 1 Do
  Begin
    If BigOfs[I] <> 0 Then FileDel(BigFile(I));
    BigOfs[I] := 0;
  End;
End;

Function BigGet(K, Ofs : LongInt; Var T, Sz : LongInt; Var Fn : String)
  : Boolean;
Var I : LongInt;
Begin
  BigGet := False;
  For I := 0 To BigN - 1 Do
    If (BigOfs[I] = Ofs) And (BigK[I] = K) And (Ofs <> 0) Then
    Begin
      Inc(BigTick); BigUse[I] := BigTick;
      T := BigT[I]; Sz := BigSz[I]; Fn := BigFile(I);
      BigGet := True; Exit;
    End;
End;

{ emplacement pour un gros objet (sauf le fichier Avoid, en usage) }
Function BigNew(K, Ofs, T, Sz : LongInt; Const Avoid : String) : String;
Var I, J : LongInt;
Begin
  { le moins recemment utilise (libre d'abord), sauf Avoid }
  I := -1;
  For J := 0 To BigN - 1 Do
    If BigFile(J) <> Avoid Then
      If (I < 0) Or (BigOfs[J] = 0) And (BigOfs[I] <> 0) Or
         ((BigOfs[J] <> 0) = (BigOfs[I] <> 0)) And (BigUse[J] < BigUse[I])
      Then I := J;
  Inc(BigTick); BigUse[I] := BigTick;
  Inc(BigMade);
  If BaseCFn = BigFile(I) Then BaseCDrop;
  BigK[I] := K; BigOfs[I] := Ofs; BigT[I] := T; BigSz[I] := Sz;
  BigNew := BigFile(I);
End;

{ empreinte calculee pendant l'ecriture du gros objet Fn }
Function BigShaOf(Const Fn : String; Var H : TSha) : Boolean;
Var I : LongInt;
Begin
  BigShaOf := False;
  For I := 0 To BigN - 1 Do
    If (BigFile(I) = Fn) And (BigOfs[I] <> 0) Then
    Begin
      H := BigSha[I]; BigShaOf := True; Exit;
    End;
End;

Procedure BigSetSha(Const Fn : String);
Var I : LongInt;
Begin
  For I := 0 To BigN - 1 Do
    If BigFile(I) = Fn Then Sha1Final(ZSha, BigSha[I]);
End;

{ commence l'empreinte d'un objet (en-tete) dans ZSha }
Procedure ShaHead(T, Sz : LongInt);
Begin
  Sha1Init(ZSha);
  Sha1Str(ZSha, TypeName(T) + ' ' + IStr(Sz));
  Sha1Byte(ZSha, 0);
End;

Procedure BigDrop(Const Fn : String);
Var I : LongInt;
Begin
  For I := 0 To BigN - 1 Do
    If BigFile(I) = Fn Then BigOfs[I] := 0;
  If BaseCFn = Fn Then BaseCDrop;
  FileDel(Fn);
End;

{ cache des objets resolus en memoire (bases des chaines de deltas) :
  jusqu'a DcN objets d'au plus DcMax octets, DcBudget octets en tout ; le
  moins recemment utilise sort le premier (sa memoire est rendue). Les
  fichiers moyens (README.md, PMSHELL.PAS : 256 Ko a 2 Mo, chaines de
  deltas de 50 versions) seraient sinon reconstitues depuis la racine de
  leur chaine pour chaque version. }
Const
  DcN = 48;
  DcMax = 2097152;
  DcBudget = 8388608;

Var
  DcKey, DcOfs, DcT, DcUse : Array[0..DcN - 1] Of LongInt;
  DcBuf : Array[0..DcN - 1] Of TBuf;
  DcTick, DcBytes : LongInt;

Procedure DcDrop(I : LongInt);
Begin
  If DcOfs[I] >= 0 Then DcBytes := DcBytes - DcBuf[I].N;
  DcKey[I] := 0; DcOfs[I] := -1;
  BufFree(DcBuf[I]);
End;

Procedure DcClear;
Var I : LongInt;
Begin
  For I := 0 To DcN - 1 Do
  Begin
    DcKey[I] := 0; DcOfs[I] := -1;
    BufFree(DcBuf[I]);
  End;
  DcBytes := 0;
End;

Function DcGet(Key, Ofs : LongInt; Var T : LongInt; Var D : TBuf) : Boolean;
Var I : LongInt;
Begin
  DcGet := False;
  For I := 0 To DcN - 1 Do
    If (DcOfs[I] = Ofs) And (DcKey[I] = Key) Then
    Begin
      D.N := 0;
      BufAppend(D, DcBuf[I], 0, DcBuf[I].N);
      T := DcT[I];
      Inc(DcTick); DcUse[I] := DcTick;
      DcGet := D.N = DcBuf[I].N;
      Exit;
    End;
End;

Procedure DcPut(Key, Ofs, T : LongInt; Var D : TBuf);
Var I, J, K : LongInt; Oom : Boolean; E : String;
Begin
  If D.N > DcMax Then Exit;
  For I := 0 To DcN - 1 Do
    If (DcOfs[I] = Ofs) And (DcKey[I] = Key) Then Exit;
  { place : une entree libre, sinon la moins recemment utilisee ; puis
    les plus anciennes jusqu'a tenir dans le budget }
  I := -1;
  For J := 0 To DcN - 1 Do
    If DcOfs[J] < 0 Then
    Begin
      If I < 0 Then I := J;
    End;
  If I < 0 Then
  Begin
    I := 0;
    For J := 1 To DcN - 1 Do
      If DcUse[J] < DcUse[I] Then I := J;
    DcDrop(I);
  End;
  While DcBytes + D.N > DcBudget Do
  Begin
    J := -1;
    For K := 0 To DcN - 1 Do
      If (DcOfs[K] >= 0) And ((J < 0) Or (DcUse[K] < DcUse[J])) Then J := K;
    If J < 0 Then Break;
    DcDrop(J);
  End;
  DcBuf[I].N := 0;
  Oom := GitOom; E := GitErr;
  BufAppend(DcBuf[I], D, 0, D.N);
  If DcBuf[I].N <> D.N Then
  Begin
    { cache : pas de place, ce n'est pas une erreur }
    BufFree(DcBuf[I]);
    GitOom := Oom; GitErr := E;
    Exit;
  End;
  DcKey[I] := Key; DcOfs[I] := Ofs; DcT[I] := T;
  Inc(DcTick); DcUse[I] := DcTick;
  DcBytes := DcBytes + D.N;
End;

{ ------------------------------------------------------------------ }
{ Packs                                                                }
{ ------------------------------------------------------------------ }

Procedure PackFree(K : LongInt);
Begin
  BufFree(Packs[K].Idx);
  If Packs[K].Loaded And (Packs[K].H >= 0) Then FClose(Packs[K].H);
  Packs[K].H := -1;
  Packs[K].Loaded := False;
End;

{ liste des packs (objects/pack/*.idx), relue apres un fetch }
Procedure PacksScan;
Var SR : TFind; D : String; K : LongInt; Ok : Boolean;
Begin
  For K := 0 To PackN - 1 Do PackFree(K);
  PackN := 0;
  PacksRead := True;
  DcClear;
  BigClear;
  D := GitDir + PS + 'objects' + PS + 'pack' + PS;
  Ok := FindFirstF(D + '*.idx', SR);
  While Ok And (PackN < MaxPack) Do
  Begin
    Packs[PackN].Name := D + Copy(FindName(SR), 1, Length(FindName(SR)) - 4);
    BufInit(Packs[PackN].Idx);
    Packs[PackN].Loaded := False;
    Packs[PackN].H := -1;
    Inc(PackN);
    Ok := FindNextF(SR);
  End;
  FindCloseF(SR);
End;

Function BE32(Var B : TBuf; O : LongInt) : LongInt;
Begin
  BE32 := (B.P^[O] Shl 24) Or (B.P^[O + 1] Shl 16) Or (B.P^[O + 2] Shl 8) Or
          B.P^[O + 3];
End;

Procedure PutBE32(Var B : TBuf; V : LongInt);
Begin
  BufByte(B, (V Shr 24) And 255); BufByte(B, (V Shr 16) And 255);
  BufByte(B, (V Shr 8) And 255); BufByte(B, V And 255);
End;

Function PackLoad(K : LongInt) : Boolean;
Begin
  PackLoad := False;
  If Packs[K].Loaded Then Begin PackLoad := True; Exit; End;
  If Not FileLoad(Packs[K].Name + '.idx', Packs[K].Idx) Then Exit;
  If (Packs[K].Idx.N < 1072) Or (BE32(Packs[K].Idx, 0) <> LongInt($FF744F63))
     Or (BE32(Packs[K].Idx, 4) <> 2) Then
  Begin
    GitErr := 'index de pack non pris en charge : ' + Packs[K].Name;
    Exit;
  End;
  Packs[K].H := FOpenR(Packs[K].Name + '.pack');
  If Packs[K].H < 0 Then
  Begin
    GitErr := 'pack illisible : ' + Packs[K].Name; Exit;
  End;
  Packs[K].Size := FSize(Packs[K].H);
  Packs[K].N := BE32(Packs[K].Idx, 8 + 255 * 4);
  Packs[K].Loaded := True;
  PackLoad := True;
End;

{ position de l'objet H dans le pack K (-1 : absent) }
Function PackFind(K : LongInt; Const H : TSha) : LongInt;
Var Lo, Hi, M, C, J : LongInt; T : TSha;
Begin
  PackFind := -1;
  If Not PackLoad(K) Then Exit;
  If H[0] = 0 Then Lo := 0 Else Lo := BE32(Packs[K].Idx, 8 + (H[0] - 1) * 4);
  Hi := BE32(Packs[K].Idx, 8 + H[0] * 4) - 1;
  While Lo <= Hi Do
  Begin
    M := (Lo + Hi) Div 2;
    ShaFrom(Packs[K].Idx, 1032 + M * 20, T);
    C := ShaCmp(T, H);
    If C = 0 Then
    Begin
      J := 1032 + Packs[K].N * 24 + M * 4;
      PackFind := BE32(Packs[K].Idx, J);
      Exit;
    End;
    If C < 0 Then Lo := M + 1 Else Hi := M - 1;
  End;
End;

{ en-tete d'un objet de pack (dans un tampon) : type, taille, debut des
  donnees, distance de la base (OFS_DELTA), base (REF_DELTA) }
Procedure PackHdr(Var P : TBuf; Ofs : LongInt; Var T, Sz, DataAt,
  OfsBase : LongInt; Var RefBase : TSha);
Var C, Sh, V : LongInt;
Begin
  C := P.P^[Ofs]; Inc(Ofs);
  T := (C Shr 4) And 7;
  Sz := C And 15;
  Sh := 4;
  While (C And 128) <> 0 Do
  Begin
    C := P.P^[Ofs]; Inc(Ofs);
    Sz := Sz Or ((C And 127) Shl Sh);
    Sh := Sh + 7;
  End;
  OfsBase := -1;
  If T = OtOfsDelta Then
  Begin
    C := P.P^[Ofs]; Inc(Ofs);
    V := C And 127;
    While (C And 128) <> 0 Do
    Begin
      C := P.P^[Ofs]; Inc(Ofs);
      V := ((V + 1) Shl 7) Or (C And 127);
    End;
    OfsBase := V;
  End
  Else If T = OtRefDelta Then
  Begin
    ShaFrom(P, Ofs, RefBase);
    Ofs := Ofs + 20;
  End;
  DataAt := Ofs;
End;

{ en-tete d'un objet du pack K (lu dans le fichier) }
Function PackHdrK(K, Ofs : LongInt; Var T, Sz, DataAt, OfsBase : LongInt;
  Var RefBase : TSha) : Boolean;
Var B : TBuf; N : LongInt;
Begin
  PackHdrK := False;
  BufInit(B);
  BufNeed(B, 64);
  FillChar(B.P^[0], 64, 0);
  N := FReadAt(Packs[K].H, Ofs, B.P, MinL(48, Packs[K].Size - Ofs));
  If N > 0 Then
  Begin
    B.N := N;
    PackHdr(B, 0, T, Sz, DataAt, OfsBase, RefBase);
    DataAt := DataAt + Ofs;
    PackHdrK := (T >= 1) And (T <= 7) And (T <> 5);
  End;
  BufFree(B);
End;

{ tailles en tete d'un delta : base, resultat ; P : debut des
  instructions }
Function DeltaVint(Var Dl : TBuf; Var P : LongInt) : LongInt;
Var V, S, B : LongInt;
Begin
  V := 0; S := 0;
  Repeat
    If P >= Dl.N Then Break;
    B := Dl.P^[P]; Inc(P);
    V := V Or ((B And 127) Shl S);
    S := S + 7;
  Until (B And 128) = 0;
  DeltaVint := V;
End;

Procedure DeltaHdr(Var Dl : TBuf; Var BSz, RSz, P : LongInt);
Begin
  P := 0;
  BSz := DeltaVint(Dl, P);
  RSz := DeltaVint(Dl, P);
End;

{ ecrit des octets vers la sortie d'un delta : memoire (O) ou flux
  (tampon ZOB, puis fichier et/ou empreinte : voir ZDstStream) }
Var
  DOutMem : Boolean;
  DO_ : ^TBuf;

Procedure DEmit(P : PBytes; Ofs, N : LongInt);
Var K : LongInt;
Begin
  Breathe(N + 16);
  If DOutMem Then
  Begin
    BufNeed(DO_^, DO_^.N + N);
    If DO_^.N + N > DO_^.Cap Then
    Begin
      ZErr := True; Exit;
    End;
    Move(P^[Ofs], DO_^.P^[DO_^.N], N);
    DO_^.N := DO_^.N + N;
    Exit;
  End;
  While N > 0 Do
  Begin
    K := MinL(N, ZChunk - ZOBN);
    Move(P^[Ofs], ZOB^[ZOBN], K);
    ZOBN := ZOBN + K; Ofs := Ofs + K; N := N - K;
    If ZOBN >= ZChunk Then ZFlush;
  End;
End;

{ applique le delta Dl a la base (memoire Base, ou fichier BaseH >= 0) ;
  resultat : memoire O (OutH < 0 et pas d'empreinte) ou flux }
Function DeltaApplyX(Var Base : TBuf; BaseH : LongInt; Var Dl : TBuf;
  Var O : TBuf; OutH : LongInt; UseSha : Boolean) : Boolean;
Const DWin = 65536;
Var P, BSz, RSz, Sh, C, Ofs, Len, Done, N, BLen, WOfs : LongInt; Ch : TBuf;
Begin
  DeltaApplyX := False;
  WOfs := 0;
  DeltaHdr(Dl, BSz, RSz, P);
  If DUseCk Then BLen := BaseCkLen
  Else If BaseH >= 0 Then BLen := FSize(BaseH) Else BLen := Base.N;
  If BSz <> BLen Then Exit;
  DOutMem := (OutH < 0) And Not UseSha;
  If DOutMem Then
  Begin
    O.N := 0;
    DO_ := @O;
    BufNeed(O, RSz);
  End
  Else ZDstStream(OutH, UseSha, 0);
  ZErr := False;
  BufInit(Ch);
  Done := 0;
  While (P < Dl.N) And Not ZErr Do
  Begin
    C := Dl.P^[P]; Inc(P);
    If (C And 128) <> 0 Then
    Begin
      Ofs := 0; Len := 0;
      For Sh := 0 To 3 Do
        If (C And (1 Shl Sh)) <> 0 Then
        Begin
          Ofs := Ofs Or (Dl.P^[P] Shl (Sh * 8)); Inc(P);
        End;
      For Sh := 0 To 2 Do
        If (C And (16 Shl Sh)) <> 0 Then
        Begin
          Len := Len Or (Dl.P^[P] Shl (Sh * 8)); Inc(P);
        End;
      If Len = 0 Then Len := $10000;
      If (Ofs < 0) Or (Ofs + Len > BLen) Then
      Begin
        BufFree(Ch); Exit;
      End;
      If DUseCk Then
      Begin
        { base en morceaux : une copie peut chevaucher deux morceaux }
        While Len > 0 Do
        Begin
          N := MinL(Len, CkSz - Ofs Mod CkSz);
          DEmit(BaseCk[Ofs Div CkSz], Ofs Mod CkSz, N);
          Ofs := Ofs + N; Len := Len - N; Done := Done + N;
        End;
      End
      Else If BaseH < 0 Then DEmit(Base.P, Ofs, Len)
      Else
      Begin
        { base dans un fichier : fenetre de lecture de 512 Ko (les copies
          d'un delta sont nombreuses et souvent petites) }
        BufNeed(Ch, DWin);
        If Ch.Cap < DWin Then
        Begin
          BufFree(Ch); Exit;
        End;
        While Len > 0 Do
        Begin
          If (Ofs < WOfs) Or (Ofs >= WOfs + Ch.N) Then
          Begin
            WOfs := Ofs - 4096;
            If WOfs < 0 Then WOfs := 0;
            Ch.N := FReadAt(BaseH, WOfs, Ch.P, MinL(DWin, BLen - WOfs));
            If (Ch.N <= 0) Or (Ofs >= WOfs + Ch.N) Then
            Begin
              BufFree(Ch); Exit;
            End;
          End;
          N := MinL(Len, WOfs + Ch.N - Ofs);
          DEmit(Ch.P, Ofs - WOfs, N);
          Ofs := Ofs + N; Len := Len - N; Done := Done + N;
        End;
        Len := 0;
      End;
      Done := Done + Len;
    End
    Else If C > 0 Then
    Begin
      If P + C > Dl.N Then
      Begin
        BufFree(Ch); Exit;
      End;
      DEmit(Dl.P, P, C);
      P := P + C;
      Done := Done + C;
    End
    Else
    Begin
      BufFree(Ch); Exit;
    End;
  End;
  BufFree(Ch);
  If Not DOutMem Then ZFlush;
  DeltaApplyX := (Done = RSz) And Not ZErr;
End;

{ DeltaApplyX avec la base en morceaux (BaseCk) si Ck }
Function DeltaApplyCk(Ck : Boolean; Var Base : TBuf; BaseH : LongInt;
  Var Dl : TBuf; Var O : TBuf; OutH : LongInt; UseSha : Boolean) : Boolean;
Begin
  DUseCk := Ck;
  DeltaApplyCk := DeltaApplyX(Base, BaseH, Dl, O, OutH, UseSha);
  DUseCk := False;
End;

{ delta Git en memoire : base + instructions -> O }
Function DeltaApply(Var Base, Dl : TBuf; Var O : TBuf) : Boolean;
Begin
  DeltaApply := DeltaApplyX(Base, -1, Dl, O, -1, False);
End;

Var
  PackRefHookOn : Boolean;
  { resolution d'un pack : objet sans enfant dans l'arbre des deltas, seule
    son empreinte est calculee (pas de fichier pour un gros objet) }
  PgShaOnly, PgShaSet : Boolean;
  { resolution d'un pack : objet avec enfants, garde en memoire (cache) au
    niveau 0 aussi : ses deltas le suivent dans l'ordre de resolution }
  PgKeep : Boolean;
  PgSha : TSha;             { bases REF_DELTA du pack en cours }

Function IxRefHook(Const H : TSha; Var T, Sz : LongInt; Var D : TBuf;
  Var Fn : String) : Boolean; Forward;
Function ObjGet(Const H : TSha; Var T, Sz : LongInt; Var D : TBuf;
  Var Fn : String) : Boolean; Forward;

Const
  BaseMemMax = 33554432;               { base de delta en memoire : 32 Mo }

Function PackGet(K, Ofs : LongInt; Var T, Sz : LongInt; Var D : TBuf;
  Var Fn : String; Depth : LongInt) : Boolean; Forward;

{ objet du pack K a la position Ofs, deltas resolus : en memoire (D) s'il
  fait au plus BigObj octets, sinon dans le fichier Fn (cache) }
Function PackGet1(K, Ofs : LongInt; Var T, Sz : LongInt; Var D : TBuf;
  Var Fn : String; Depth : LongInt) : Boolean;
Var T0, Sz0, At, OB, U, BT, BSz, BH, OH, P0, RSz : LongInt; RB : TSha;
    Dl, Base : TBuf; Ok, UseCk : Boolean; BFn : String;
Begin
  PackGet1 := False;
  Fn := '';
  D.N := 0;
  If Depth > 60 Then Exit;
  If DcGet(K, Ofs, T, D) Then
  Begin
    Sz := D.N; PackGet1 := True; Exit;
  End;
  If BigGet(K, Ofs, T, Sz, Fn) Then
  Begin
    PackGet1 := True; Exit;
  End;
  If Not PackHdrK(K, Ofs, T0, Sz0, At, OB, RB) Then Exit;
  If (T0 >= OtCommit) And (T0 <= OtTag) Then
  Begin
    T := T0; Sz := Sz0;
    ZSrcFile(Packs[K].H, At);
    If Sz0 <= BigObj Then
    Begin
      BufNeed(D, Sz0 + 1);
      ZDstMem(D);
      Ok := ZRun($7FFFFFFF, U) And (D.N = Sz0) And Not ZErr;
      If Ok And ((Depth > 0) Or PgKeep) Then DcPut(K, Ofs, T, D);
    End
    Else
    Begin
      Fn := BigNew(K, Ofs, T, Sz, '');
      OH := FCreate(Fn);
      Ok := OH >= 0;
      If Ok Then
      Begin
        ShaHead(T, Sz);
        ZDstStream(OH, True, 0);
        Ok := ZRun($7FFFFFFF, U) And (ZTotal = Sz0);
        FClose(OH);
        If Ok Then BigSetSha(Fn);
      End;
      If Not Ok Then BigDrop(Fn);
    End;
    PackGet1 := Ok;
    Exit;
  End;
  { delta : la base d'abord (memoire ou fichier ; un seul niveau de la
    chaine garde ses tampons a la fois), puis les instructions }
  BufInit(Dl); BufInit(Base);
  BFn := '';
  If T0 = OtOfsDelta Then
    Ok := PackGet(K, Ofs - OB, BT, BSz, Base, BFn, Depth + 1)
  Else
  Begin
    Ok := False;
    If PackRefHookOn And (K = IxK) Then
      Ok := IxRefHook(RB, BT, BSz, Base, BFn);
    If Not Ok Then Ok := ObjGet(RB, BT, BSz, Base, BFn);
  End;
  If Ok Then
  Begin
    BufNeed(Dl, Sz0 + 1);
    ZSrcFile(Packs[K].H, At);
    ZDstMem(Dl);
    Ok := ZRun($7FFFFFFF, U) And (Dl.N = Sz0) And Not GitOom;
  End;
  If Ok Then
  Begin
    DeltaHdr(Dl, BSz, RSz, P0);
    T := BT; Sz := RSz;
    BH := -1;
    UseCk := False;
    { base dans un fichier : chargee en memoire si elle y tient (les
      copies d'un delta sautent partout dans la base) et gardee pour les
      deltas suivants qui ont la meme base ; sinon lue dans le fichier }
    If BFn <> '' Then
    Begin
      If (BaseCFn = BFn) And (BaseCkLen = BSz) Then
      Begin
        UseCk := True; Inc(BaseHits);
      End
      Else
      Begin
        BH := FOpenR(BFn);
        If (BH >= 0) And (BSz <= BaseMemMax) Then
        Begin
          Inc(BaseLoads);
          If BaseCLoad(BH) Then
          Begin
            FClose(BH); BH := -1;
            UseCk := True; BaseCFn := BFn;
          End;
        End;
      End;
    End;
    If (BFn <> '') And (BH < 0) And Not UseCk Then
    Begin
      Ok := False;
      GitErr := 'lecture impossible : ' + BFn;
    End
    Else If RSz <= BigObj Then
    Begin
      Ok := DeltaApplyCk(UseCk, Base, BH, Dl, D, -1, False);
      If Ok And ((Depth > 0) Or PgKeep) Then DcPut(K, Ofs, T, D);
    End
    Else If PgShaOnly And (Depth = 0) Then
    Begin
      ShaHead(T, RSz);
      Ok := DeltaApplyCk(UseCk, Base, BH, Dl, D, -1, True);
      If Ok Then Sha1Final(ZSha, PgSha);
      PgShaSet := Ok;
    End
    Else
    Begin
      Fn := BigNew(K, Ofs, T, RSz, BFn);
      OH := FCreate(Fn);
      Ok := OH >= 0;
      If Not Ok Then GitErr := 'cr'#233'ation impossible : ' + Fn;
      If Ok Then
      Begin
        ShaHead(T, RSz);
        Ok := DeltaApplyCk(UseCk, Base, BH, Dl, D, OH, True);
        FClose(OH);
        If Ok Then BigSetSha(Fn);
      End;
      If Not Ok Then
      Begin
        BigDrop(Fn); Fn := '';
      End;
    End;
    If BH >= 0 Then FClose(BH);
  End;
  BufFree(Dl); BufFree(Base);
  If Not Ok And (GitErr = '') Then GitErr := 'objet de pack illisible';
  PackGet1 := Ok;
End;

{ PackGet1 ; si la memoire a manque, les caches (base en memoire, petits
  objets) sont vides et l'objet est demande une seconde fois }
Function PackGet(K, Ofs : LongInt; Var T, Sz : LongInt; Var D : TBuf;
  Var Fn : String; Depth : LongInt) : Boolean;
Var Ok, Oom : Boolean;
Begin
  If Depth > 0 Then
  Begin
    PackGet := PackGet1(K, Ofs, T, Sz, D, Fn, Depth);
    Exit;
  End;
  Oom := GitOom;
  GitOom := False;
  Ok := PackGet1(K, Ofs, T, Sz, D, Fn, 0);
  If (Not Ok) And GitOom Then
  Begin
    BaseCDrop; DcClear;
    BufFree(D);
    GitOom := False; GitErr := '';
    Ok := PackGet1(K, Ofs, T, Sz, D, Fn, 0);
  End;
  { reussi : un manque de memoire en chemin (cache) n'est pas une erreur }
  If Ok Then GitOom := Oom
  Else If Oom Then GitOom := True;
  PackGet := Ok;
End;

{ type et taille d'un objet du pack, sans le reconstituer }
Function PackInfo(K, Ofs : LongInt; Var T, Sz : LongInt; Depth : LongInt)
  : Boolean; Forward;

Function ObjInfo(Const H : TSha; Var T, Sz : LongInt) : Boolean; Forward;

Function PackInfo(K, Ofs : LongInt; Var T, Sz : LongInt; Depth : LongInt)
  : Boolean;
Var T0, Sz0, At, OB, U, BSz, P0, BS : LongInt; RB : TSha; Dl : TBuf;
Begin
  PackInfo := False;
  If (Depth > 60) Or Not PackHdrK(K, Ofs, T0, Sz0, At, OB, RB) Then Exit;
  If T0 <= OtTag Then
  Begin
    T := T0; Sz := Sz0; PackInfo := True; Exit;
  End;
  BufInit(Dl);
  ZSrcFile(Packs[K].H, At);
  ZDstMem(Dl);
  If ZRun(32, U) Then
  Begin
    DeltaHdr(Dl, BSz, Sz, P0);
    If T0 = OtOfsDelta Then PackInfo := PackInfo(K, Ofs - OB, T, BS,
      Depth + 1)
    Else PackInfo := ObjInfo(RB, T, BS);
  End;
  BufFree(Dl);
End;

{ en-tete d'un objet libre : type, taille, longueur de l'en-tete }
Function LooseInfo(Const H : TSha; Var T, Sz, HL : LongInt) : Boolean;
Var F, U, I, K : LongInt; R : TBuf; S : String;
Begin
  LooseInfo := False;
  F := FOpenR(ObjPath(H));
  If F < 0 Then Exit;
  BufInit(R);
  ZSrcFile(F, 0);
  ZDstMem(R);
  If ZRun(64, U) Then
  Begin
    I := 0;
    While (I < R.N) And (R.P^[I] <> 0) Do Inc(I);
    S := BufStrAt(R, 0, I);
    K := Pos(' ', S);
    T := TypeOfName(Copy(S, 1, K - 1));
    Val(Copy(S, K + 1, 20), Sz, K);
    HL := I + 1;
    LooseInfo := (T > 0) And (I < R.N);
  End;
  BufFree(R);
  FClose(F);
End;

Function ObjInfo(Const H : TSha; Var T, Sz : LongInt) : Boolean;
Var K, I, HL : LongInt;
Begin
  ObjInfo := False;
  If LooseInfo(H, T, Sz, HL) Then
  Begin
    ObjInfo := True; Exit;
  End;
  If Not PacksRead Then PacksScan;
  For K := 0 To PackN - 1 Do
  Begin
    I := PackFind(K, H);
    If I >= 0 Then
    Begin
      ObjInfo := PackInfo(K, I, T, Sz, 0);
      Exit;
    End;
  End;
  GitErr := 'objet introuvable : ' + ShaHex(H);
End;

{ objet (libre ou dans un pack) : en memoire (D) ou dans le fichier Fn
  s'il est plus grand que BigObj }
Function ObjGet(Const H : TSha; Var T, Sz : LongInt; Var D : TBuf;
  Var Fn : String) : Boolean;
Var F, U, I, K, HL, OH : LongInt; R : TBuf; Ok : Boolean;
Begin
  ObjGet := False;
  Fn := '';
  D.N := 0;
  T := 0;
  If LooseInfo(H, T, Sz, HL) Then
  Begin
    F := FOpenR(ObjPath(H));
    If F < 0 Then Exit;
    ZSrcFile(F, 0);
    If Sz <= BigObj Then
    Begin
      BufInit(R);
      BufNeed(R, Sz + HL + 1);
      ZDstMem(R);
      Ok := ZRun($7FFFFFFF, U) And (R.N = Sz + HL);
      If Ok Then BufAppend(D, R, HL, Sz);
      BufFree(R);
    End
    Else
    Begin
      Fn := BigNew(-2, (H[0] Shl 16) Or (H[1] Shl 8) Or H[2] Or 1, T, Sz,
        '');
      OH := FCreate(Fn);
      Ok := OH >= 0;
      If Ok Then
      Begin
        ZDstStream(OH, False, HL);
        Ok := ZRun($7FFFFFFF, U) And (ZTotal = Sz + HL);
        FClose(OH);
      End;
      If Not Ok Then
      Begin
        BigDrop(Fn); Fn := '';
      End;
    End;
    FClose(F);
    ObjGet := Ok;
    Exit;
  End;
  If Not PacksRead Then PacksScan;
  For K := 0 To PackN - 1 Do
  Begin
    I := PackFind(K, H);
    If I >= 0 Then
    Begin
      ObjGet := PackGet(K, I, T, Sz, D, Fn, 0);
      Exit;
    End;
  End;
  GitErr := 'objet introuvable : ' + ShaHex(H);
End;

{ lit un objet en memoire (faux s'il est trop grand pour la memoire) }
Function ReadObject(Const H : TSha; Var T : LongInt; Var D : TBuf) : Boolean;
Var Sz : LongInt; Fn : String;
Begin
  ReadObject := False;
  If Not ObjGet(H, T, Sz, D, Fn) Then Exit;
  If Fn <> '' Then
  Begin
    GitErr := 'objet trop volumineux pour la m'#233'moire : ' + ShaHex(H);
    D.N := 0;
    Exit;
  End;
  ReadObject := True;
End;

{ ecrit le contenu d'un objet dans un fichier (toute taille) }
Function ObjToFile(Const H : TSha; Const Path : String; Var T : LongInt)
  : Boolean;
Var D : TBuf; Sz : LongInt; Fn : String;
Begin
  BufInit(D);
  ObjToFile := False;
  If ObjGet(H, T, Sz, D, Fn) Then
  Begin
    If Fn <> '' Then ObjToFile := FileCopy(Fn, Path)
    Else ObjToFile := FileSave(Path, D, 0, D.N);
  End;
  BufFree(D);
End;

Function HasObject(Const H : TSha) : Boolean;
Var K : LongInt;
Begin
  HasObject := True;
  If FileExist(ObjPath(H)) Then Exit;
  If Not PacksRead Then PacksScan;
  For K := 0 To PackN - 1 Do
    If PackFind(K, H) >= 0 Then Exit;
  HasObject := False;
End;

{ ecrit un objet libre (s'il n'existe pas) ; H : son empreinte }
Function WriteObject(T : LongInt; Var D : TBuf; Var H : TSha) : Boolean;
Var R, Z : TBuf; P : String;
Begin
  WriteObject := False;
  ObjHash(T, D, 0, D.N, H);
  If HasObject(H) Then Begin WriteObject := True; Exit; End;
  BufInit(R); BufInit(Z);
  BufStr(R, TypeName(T) + ' ' + IStr(D.N));
  BufByte(R, 0);
  BufAppend(R, D, 0, D.N);
  ZDeflate(R, 0, R.N, Z);
  P := ObjPath(H);
  MkDirs(ParentOf(P));
  If Not GitOom Then WriteObject := FileSave(P, Z, 0, Z.N);
  If Not FileExist(P) Then GitErr := ''#233'criture impossible : ' + P;
  BufFree(R); BufFree(Z);
End;

{ objet libre d'un gros fichier : lu par morceaux, blocs zlib stockes }
{ bloc stocke de N octets de B (a partir de 5) ; Fin : dernier bloc }
Function WofBlk(Var B : TBuf; N, Fin : LongInt; Var A : LongInt;
  O : LongInt) : Boolean;
Begin
  B.P^[0] := Fin;
  B.P^[1] := N And 255; B.P^[2] := (N Shr 8) And 255;
  B.P^[3] := (Not N) And 255; B.P^[4] := ((Not N) Shr 8) And 255;
  A := AdlerUpd(A, B.P, 5, N);
  WofBlk := FWrite(O, B.P, N + 5);
End;

Function WriteObjectFile(T : LongInt; Const Path : String; Var H : TSha)
  : Boolean;
Var F, O, Sz, Pos, N, A, Fin : LongInt; Ch, Hd : TBuf; P, Tmp : String;
    Ok : Boolean;
Begin
  WriteObjectFile := False;
  If Not HashFile(Path, T, H) Then Exit;
  If HasObject(H) Then
  Begin
    WriteObjectFile := True; Exit;
  End;
  F := FOpenR(Path);
  If F < 0 Then Exit;
  Sz := FSize(F);
  P := ObjPath(H);
  MkDirs(ParentOf(P));
  Tmp := P + '.tmp';
  O := FCreate(Tmp);
  If O < 0 Then
  Begin
    FClose(F); Exit;
  End;
  BufInit(Ch); BufInit(Hd);
  BufNeed(Ch, ZChunk + 8);
  Ok := Ch.Cap >= ZChunk + 8;
  A := 1;
  If Ok Then
  Begin
    { en-tete zlib, bloc de l'en-tete de l'objet, puis le fichier en
      blocs de 32 Ko au plus }
    BufByte(Hd, $78); BufByte(Hd, $01);
    Ok := FWrite(O, Hd.P, 2);
    Ch.N := 5;
    BufStr(Ch, TypeName(T) + ' ' + IStr(Sz));
    BufByte(Ch, 0);
    If Sz = 0 Then Fin := 1 Else Fin := 0;
    Ok := Ok And WofBlk(Ch, Ch.N - 5, Fin, A, O);
  End;
  Pos := 0;
  While Ok And (Pos < Sz) Do
  Begin
    N := MinL(ZChunk, Sz - Pos);
    If FReadAt(F, Pos, PBytes(@Ch.P^[5]), N) <> N Then
    Begin
      Ok := False; Break;
    End;
    Pos := Pos + N;
    If Pos >= Sz Then Fin := 1 Else Fin := 0;
    Ok := WofBlk(Ch, N, Fin, A, O);
  End;
  Hd.N := 0;
  PutBE32(Hd, A);
  Ok := Ok And FWrite(O, Hd.P, 4);
  FClose(O); FClose(F);
  BufFree(Ch); BufFree(Hd);
  If Ok Then Ok := FileRen(Tmp, P);
  If Not Ok Then
  Begin
    FileDel(Tmp);
    GitErr := ''#233'criture impossible : ' + P;
  End;
  WriteObjectFile := Ok;
End;

{ ------------------------------------------------------------------ }
{ Pack recu (clone, fetch), dans un fichier : verification, empreintes, }
{ fichier .idx                                                         }
{ ------------------------------------------------------------------ }

Type
  TLongArr = Array[0..$3FFFFFF] Of LongInt;
  TPEnt = Record
    Sha : TSha;
    Ofs, Len, Crc, Typ, Depth, BaseI : LongInt;
    Done : Boolean;
  End;
  TPEntArr = Array[0..$3FFFFF] Of TPEnt;
  PPEntArr = ^TPEntArr;

Var
  IxE : PPEntArr;                      { objets du pack en cours d'indexation }
  IxN : LongInt;
  IxSort : ^TLongArr;

{ base REF_DELTA cherchee parmi les objets deja calcules du pack }
Function IxRefHook(Const H : TSha; Var T, Sz : LongInt; Var D : TBuf;
  Var Fn : String) : Boolean;
Var I : LongInt;
Begin
  IxRefHook := False;
  For I := 0 To IxN - 1 Do
    If IxE^[I].Done And ShaEq(IxE^[I].Sha, H) Then
    Begin
      IxRefHook := PackGet(IxK, IxE^[I].Ofs, T, Sz, D, Fn, 1);
      Exit;
    End;
End;

Procedure IxSortRange(L, R : LongInt);
Var I, J, T : LongInt; P : TSha;
Begin
  I := L; J := R;
  P := IxE^[IxSort^[(L + R) Div 2]].Sha;
  Repeat
    While ShaCmp(IxE^[IxSort^[I]].Sha, P) < 0 Do Inc(I);
    While ShaCmp(IxE^[IxSort^[J]].Sha, P) > 0 Do Dec(J);
    If I <= J Then
    Begin
      T := IxSort^[I]; IxSort^[I] := IxSort^[J]; IxSort^[J] := T;
      Inc(I); Dec(J);
    End;
  Until I > J;
  If L < J Then IxSortRange(L, J);
  If I < R Then IxSortRange(I, R);
End;

{ CRC-32 d'une portion du fichier }
Function CrcFile(H, Ofs, N : LongInt; Var Ch : TBuf) : LongInt;
Var C, K, I, R : LongInt;
Begin
  If Not CrcReady Then CrcInit;
  C := LongInt($FFFFFFFF);
  While N > 0 Do
  Begin
    K := MinL(N, ZChunk);
    R := FReadAt(H, Ofs, Ch.P, K);
    If R <= 0 Then Break;
    For I := 0 To R - 1 Do
      C := CrcTab[(C Xor Ch.P^[I]) And 255] Xor (C Shr 8);
    Ofs := Ofs + R; N := N - R;
  End;
  CrcFile := Not C;
End;

{ objet du pack en cours d'indexation a la position Ofs (parmi les N
  premiers, ranges par position) }
Function IxAt(Ofs, N : LongInt) : LongInt;
Var Lo, Hi, M : LongInt;
Begin
  IxAt := -1;
  Lo := 0; Hi := N - 1;
  While Lo <= Hi Do
  Begin
    M := (Lo + Hi) Div 2;
    If IxE^[M].Ofs = Ofs Then
    Begin
      IxAt := M; Exit;
    End;
    If IxE^[M].Ofs < Ofs Then Lo := M + 1 Else Hi := M - 1;
  End;
End;

Procedure IxDone(Cnt : LongInt);
Begin
  If IxE <> Nil Then FreeMem(IxE, (Cnt + 1) * SizeOf(TPEnt));
  IxE := Nil; IxN := 0;
  If Packs[IxK].Loaded And (Packs[IxK].H >= 0) Then FClose(Packs[IxK].H);
  Packs[IxK].H := -1; Packs[IxK].Loaded := False;
  PackRefHookOn := False;
  DcClear;
  BigClear;
End;

{ verifie le pack recu dans le fichier Path, calcule l'empreinte de chaque
  objet et l'enregistre (objects/pack/pack-X.pack et .idx v2) }
Var
  IxTrace : Boolean;                   { /INDEX : trace sur COM1 }
  IxT0 : LongInt;

Function IndexPackFile(Const Path : String) : Boolean;
Var Cnt, I, Ofs, T, Sz, At, OB, U, Left, K, H0, Size, N, Dp : LongInt;
    DCnt, DNext, DStk : ^TLongArr;
    RB, H : TSha; D, Ch, X : TBuf; C : TSha1; Ok : Boolean;
    Nm, Fn, FirstErr : String;
    Tr : Array[0..19] Of Byte;
Begin
  IndexPackFile := False;
  H0 := FOpenR(Path);
  If H0 < 0 Then
  Begin
    GitErr := 'pack re'#231'u illisible'; Exit;
  End;
  Size := FSize(H0);
  BufInit(D); BufInit(Ch); BufInit(X);
  BufNeed(Ch, ZChunk);
  Ch.N := 0;
  If (Size >= 32) And (Ch.Cap >= ZChunk) Then Ch.N := FReadAt(H0, 0, Ch.P, 12);
  If (Ch.N <> 12) Or (BufStrAt(Ch, 0, 4) <> 'PACK') Then
  Begin
    GitErr := 'pack invalide';
    FClose(H0); BufFree(Ch); Exit;
  End;
  Ch.N := 12;
  Cnt := BE32(Ch, 8);
  { somme de controle du pack }
  Sha1Init(C);
  Ofs := 0;
  While Ofs < Size - 20 Do
  Begin
    N := FReadAt(H0, Ofs, Ch.P, MinL(ZChunk, Size - 20 - Ofs));
    If N <= 0 Then Break;
    Sha1Ptr(C, Ch.P, 0, N);
    Ofs := Ofs + N;
    If (Ofs And $FFFFF) < ZChunk Then
      GitProgress('V'#233'rification du pack', Ofs, 0);
  End;
  Sha1Final(C, H);
  N := FReadAt(H0, Size - 20, PBytes(@Tr), 20);
  Ok := N = 20;
  For I := 0 To 19 Do
    If H[I] <> Tr[I] Then Ok := False;
  If Not Ok Then
  Begin
    GitErr := 'somme de contr'#244'le du pack incorrecte';
    FClose(H0); BufFree(Ch); Exit;
  End;
  Packs[IxK].Name := Path; Packs[IxK].H := H0; Packs[IxK].Size := Size;
  Packs[IxK].Loaded := True;
  GetMem(IxE, (Cnt + 1) * SizeOf(TPEnt));
  If IxE = Nil Then
  Begin
    GitErr := 'm'#233'moire insuffisante';
    IxDone(Cnt); BufFree(Ch); Exit;
  End;
  IxN := Cnt;
  { positions, longueurs, objets entiers }
  Ofs := 12;
  For I := 0 To Cnt - 1 Do
  Begin
    IxE^[I].Done := False;
    Ok := PackHdrK(IxK, Ofs, T, Sz, At, OB, RB);
    If Ok Then
    Begin
      ZSrcFile(H0, At);
      If T <= OtTag Then
      Begin
        { empreinte en flux : en-tete puis contenu }
        Sha1Init(ZSha);
        Sha1Str(ZSha, TypeName(T) + ' ' + IStr(Sz));
        Sha1Byte(ZSha, 0);
        ZDstStream(-1, True, 0);
        Ok := ZRun($7FFFFFFF, U) And (ZTotal = Sz);
        If Ok Then
        Begin
          Sha1Final(ZSha, IxE^[I].Sha);
          IxE^[I].Typ := T;
          IxE^[I].Done := True;
        End;
      End
      Else
      Begin
        ZDstStream(-1, False, 0);
        Ok := ZRun($7FFFFFFF, U);
      End;
    End;
    If Not Ok Then
    Begin
      GitErr := 'objet compress'#233' invalide dans le pack (' + IStr(I) + ')';
      IxDone(Cnt); BufFree(Ch); Exit;
    End;
    { profondeur dans la chaine de deltas (bases OFS_DELTA : plus haut
      dans le pack) ; REF_DELTA : a la fin }
    IxE^[I].Depth := 0; IxE^[I].BaseI := -1;
    If T = OtRefDelta Then IxE^[I].Depth := 9999
    Else If T = OtOfsDelta Then
    Begin
      K := IxAt(Ofs - OB, I);
      IxE^[I].BaseI := K;
      If K >= 0 Then IxE^[I].Depth := MinL(IxE^[K].Depth + 1, 9998)
      Else IxE^[I].Depth := 9999;
    End;
    IxE^[I].Ofs := Ofs;
    IxE^[I].Len := At + U - Ofs;
    IxE^[I].Crc := CrcFile(H0, Ofs, IxE^[I].Len, Ch);
    Ofs := At + U;
    If (I And 31) = 0 Then GitProgress('Lecture des objets', I, Cnt);
  End;
  { deltas (les bases REF_DELTA peuvent venir plus loin : passes) }
  PackRefHookOn := True;
  Left := 0;
  For I := 0 To Cnt - 1 Do
    If Not IxE^[I].Done Then Inc(Left);
  { profondeur croissante : la base de chaque delta vient d'etre
    reconstituee (cache) }
  { ordre de resolution : parcours en profondeur de l'arbre des deltas,
    chaine par chaine (chaque delta juste apres sa base, que le cache des
    gros objets garde) ; les REF_DELTA et les orphelins a la fin }
  GetMem(IxSort, (Cnt + 1) * 4);
  GetMem(DCnt, (Cnt + 1) * 4);         { premier enfant }
  GetMem(DNext, (Cnt + 1) * 4);        { frere suivant }
  GetMem(DStk, (Cnt + 1) * 4);         { pile }
  If (IxSort = Nil) Or (DCnt = Nil) Or (DNext = Nil) Or (DStk = Nil) Then
  Begin
    GitErr := 'm'#233'moire insuffisante';
    IxDone(Cnt); BufFree(Ch); Exit;
  End;
  For I := 0 To Cnt - 1 Do
  Begin
    DCnt^[I] := -1; DNext^[I] := -1;
  End;
  For I := Cnt - 1 DownTo 0 Do
    If IxE^[I].BaseI >= 0 Then
    Begin
      DNext^[I] := DCnt^[IxE^[I].BaseI];
      DCnt^[IxE^[I].BaseI] := I;
    End;
  N := 0;
  For I := 0 To Cnt - 1 Do
    If IxE^[I].BaseI < 0 Then
    Begin
      Sz := 1; DStk^[0] := I;
      While Sz > 0 Do
      Begin
        Dec(Sz);
        K := DStk^[Sz];
        IxSort^[N] := K; Inc(N);
        K := DCnt^[K];
        While K >= 0 Do
        Begin
          DStk^[Sz] := K; Inc(Sz);
          K := DNext^[K];
        End;
      End;
    End;
  FreeMem(DNext, (Cnt + 1) * 4);
  FreeMem(DStk, (Cnt + 1) * 4);
  FirstErr := '';
  Repeat
    K := Left;
    For Dp := 0 To N - 1 Do
    Begin
      I := IxSort^[Dp];
      PgShaOnly := DCnt^[I] < 0;
      PgKeep := Not PgShaOnly;
      PgShaSet := False;
      If Not IxE^[I].Done Then
        If PackGet(IxK, IxE^[I].Ofs, T, Sz, D, Fn, 0) Then
        Begin
          If PgShaSet Then
          Begin
            IxE^[I].Sha := PgSha;
            Ok := True;
          End
          Else If Fn <> '' Then
          Begin
            Ok := BigShaOf(Fn, IxE^[I].Sha);
            If Not Ok Then Ok := HashFile(Fn, T, IxE^[I].Sha);
          End
          Else
          Begin
            ObjHash(T, D, 0, D.N, IxE^[I].Sha);
            Ok := True;
          End;
          If Ok Then
          Begin
            IxE^[I].Typ := T;
            IxE^[I].Done := True;
            Dec(Left);
            If ((Left Mod 16) = 0) Or (Sz > BigObj) Then
              GitProgress('R'#233'solution des deltas', Cnt - Left, Cnt);
            If IxTrace And ((Sz > BigObj) Or ((Left Mod 200) = 0)) Then
              Log('GITCLI : objet ' + IStr(Cnt - Left) + '/' + IStr(Cnt) +
                ' ' + IStr(Sz) + ' o, ' + IStr(MsTick - IxT0) + ' ms');
          End;
        End
        Else If FirstErr = '' Then FirstErr := GitErr;
    End;
  Until (Left = 0) Or (Left = K);
  PgShaOnly := False; PgKeep := False;
  FreeMem(DCnt, (Cnt + 1) * 4);
  FreeMem(IxSort, (Cnt + 1) * 4);
  PackRefHookOn := False;
  If Left > 0 Then
  Begin
    GitErr := IStr(Left) + ' objet(s) du pack sans base';
    If FirstErr <> '' Then GitErr := GitErr + ' (' + FirstErr + ')';
    IxDone(Cnt); BufFree(D); BufFree(Ch); Exit;
  End;
  { .idx version 2 }
  GetMem(IxSort, (Cnt + 1) * 4);
  For I := 0 To Cnt - 1 Do IxSort^[I] := I;
  If Cnt > 1 Then IxSortRange(0, Cnt - 1);
  X.N := 0;
  PutBE32(X, LongInt($FF744F63)); PutBE32(X, 2);
  K := 0;
  For I := 0 To 255 Do
  Begin
    While (K < Cnt) And (IxE^[IxSort^[K]].Sha[0] <= I) Do Inc(K);
    PutBE32(X, K);
  End;
  For I := 0 To Cnt - 1 Do BufMem(X, IxE^[IxSort^[I]].Sha, 20);
  For I := 0 To Cnt - 1 Do PutBE32(X, IxE^[IxSort^[I]].Crc);
  For I := 0 To Cnt - 1 Do PutBE32(X, IxE^[IxSort^[I]].Ofs);
  BufMem(X, Tr, 20);
  Sha1Init(C);
  Sha1Mem(C, X, 0, X.N);
  Sha1Final(C, RB);
  BufMem(X, RB, 20);
  FreeMem(IxSort, (Cnt + 1) * 4);
  IxDone(Cnt);
  Nm := GitDir + PS + 'objects' + PS + 'pack';
  MkDirs(Nm);
  Nm := Nm + PS + 'pack-' + ShaHex(H);
  Ok := Not GitOom;
  If Ok Then
  Begin
    FileDel(Nm + '.pack');
    Ok := FileRen(Path, Nm + '.pack');
    If Not Ok Then Ok := FileCopy(Path, Nm + '.pack');
    Ok := Ok And FileSave(Nm + '.idx', X, 0, X.N);
  End;
  If Not Ok Then GitErr := ''#233'criture du pack impossible';
  BufFree(D); BufFree(Ch); BufFree(X);
  PacksRead := False;
  IndexPackFile := Ok;
End;

{ pack en memoire (tests) : enregistre dans un fichier puis indexe }
Function IndexPack(Var P : TBuf) : Boolean;
Var Tmp : String;
Begin
  Tmp := TmpPath('recv.pack');
  IndexPack := FileSave(Tmp, P, 0, P.N) And IndexPackFile(Tmp);
  FileDel(Tmp);
End;

{ ------------------------------------------------------------------ }
{ Pack a envoyer (push) : objets non deltifies                         }
{ ------------------------------------------------------------------ }

Procedure PackBegin(Var P : TBuf; Cnt : LongInt);
Begin
  P.N := 0;
  BufStr(P, 'PACK');
  PutBE32(P, 2);
  PutBE32(P, Cnt);
End;

Procedure PackAdd(Var P : TBuf; T : LongInt; Var D : TBuf);
Var Sz, C : LongInt;
Begin
  Sz := D.N;
  C := (T Shl 4) Or (Sz And 15);
  Sz := Sz Shr 4;
  While Sz > 0 Do
  Begin
    BufByte(P, C Or 128);
    C := Sz And 127;
    Sz := Sz Shr 7;
  End;
  BufByte(P, C);
  ZDeflate(D, 0, D.N, P);
End;

{ ajoute un gros objet (fichier Fn) : blocs zlib stockes, lus par
  morceaux }
Function PackAddFile(Var P : TBuf; T : LongInt; Const Fn : String)
  : Boolean;
Var F, Sz, C, Pos, N, A, Fin : LongInt;
Begin
  PackAddFile := False;
  F := FOpenR(Fn);
  If F < 0 Then Exit;
  Sz := FSize(F);
  C := (T Shl 4) Or (Sz And 15);
  N := Sz Shr 4;
  While N > 0 Do
  Begin
    BufByte(P, C Or 128);
    C := N And 127;
    N := N Shr 7;
  End;
  BufByte(P, C);
  BufByte(P, $78); BufByte(P, $01);
  A := 1; Pos := 0;
  Repeat
    N := MinL(ZChunk, Sz - Pos);
    If Pos + N >= Sz Then Fin := 1 Else Fin := 0;
    BufByte(P, Fin);
    BufByte(P, N And 255); BufByte(P, (N Shr 8) And 255);
    BufByte(P, (Not N) And 255); BufByte(P, ((Not N) Shr 8) And 255);
    BufNeed(P, P.N + N);
    If P.N + N > P.Cap Then Break;
    If (N > 0) And (FReadAt(F, Pos, PBytes(@P.P^[P.N]), N) <> N) Then Break;
    A := AdlerUpd(A, P.P, P.N, N);
    P.N := P.N + N;
    Pos := Pos + N;
  Until Pos >= Sz;
  FClose(F);
  PutBE32(P, A);
  PackAddFile := (Pos >= Sz) And Not GitOom;
End;

Procedure PackEnd(Var P : TBuf);
Var C : TSha1; H : TSha;
Begin
  Sha1Init(C);
  Sha1Mem(C, P, 0, P.N);
  Sha1Final(C, H);
  BufMem(P, H, 20);
End;
{ ==================================================================== }
{ Listes de fichiers (arbres aplatis, index, dossier de travail)        }
{ ==================================================================== }

Type
  TFlatE = Record
    Path : String;
    Sha, Old : TSha;
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
  F.E^[F.N].Sha := ShaZero; F.E^[F.N].Old := ShaZero;
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
{ References (HEAD, refs/heads, refs/remotes, packed-refs) et config    }
{ ==================================================================== }

{ contenu du dossier Dir dans L (nom, Mode = 1 pour un dossier, taille,
  date) ; sans . et .. (ni .git si SkipGit) }
Procedure DirList(Const Dir : String; Var L : TFlat; SkipGit : Boolean);
Var SR : TFind; K, A : LongInt; Nm : String; Ok : Boolean;
Begin
  If (Dir <> '') And (Dir[Length(Dir)] = PS) Then
    Ok := FindFirstF(Dir + AllFiles, SR)
  Else Ok := FindFirstF(Dir + PS + AllFiles, SR);
  While Ok Do
  Begin
    Nm := FindName(SR);
    A := FindAttr(SR);
    If (Nm <> '.') And (Nm <> '..') And (Nm <> '') And
       (Not SkipGit Or (LowStr(Nm) <> '.git')) And ((A And 8) = 0) Then
    Begin
      K := FlatAdd(L, Nm);
      L.E^[K].Mode := Ord((A And $10) <> 0);
      L.E^[K].Size := FindSize(SR);
      L.E^[K].MTime := FindTime(SR);
    End;
    Ok := FindNextF(SR);
  End;
  FindCloseF(SR);
End;

Function GitPath(Const Rel : String) : String;
Begin
  GitPath := GitDir + PS + OsPath(Rel);
End;

Function FirstLine(Var B : TBuf) : String;
Var I : LongInt;
Begin
  I := 0;
  While (I < B.N) And (B.P^[I] <> 10) And (B.P^[I] <> 13) Do Inc(I);
  FirstLine := BufStrAt(B, 0, I);
End;

{ ligne K (0...) d'un tampon de texte ; faux apres la derniere }
Function BufLine(Var B : TBuf; Var Pos : LongInt; Var S : String) : Boolean;
Var I : LongInt;
Begin
  BufLine := False;
  If Pos >= B.N Then Exit;
  I := Pos;
  While (I < B.N) And (B.P^[I] <> 10) Do Inc(I);
  S := BufStrAt(B, Pos, I - Pos);
  If (S <> '') And (S[Length(S)] = #13) Then Delete(S, Length(S), 1);
  Pos := I + 1;
  BufLine := True;
End;

Function PackedRef(Const Name : String; Var H : TSha) : Boolean;
Var B : TBuf; P : LongInt; S : String;
Begin
  PackedRef := False;
  BufInit(B);
  If FileLoad(GitPath('packed-refs'), B) Then
  Begin
    P := 0;
    While BufLine(B, P, S) Do
      If (Length(S) > 41) And (S[1] <> '#') And (S[1] <> '^') And
         (Copy(S, 42, 255) = Name) Then
      Begin
        PackedRef := ShaParse(S, H);
        Break;
      End;
  End;
  BufFree(B);
End;

{ empreinte d'une reference (suit les references symboliques) }
Function RefRead(Name : String; Var H : TSha) : Boolean;
Var B : TBuf; S : String; K : LongInt;
Begin
  RefRead := False;
  BufInit(B);
  For K := 1 To 5 Do
  Begin
    If FileLoad(GitPath(Name), B) Then
    Begin
      S := TrimS(FirstLine(B));
      If Copy(S, 1, 5) = 'ref: ' Then
      Begin
        Name := TrimS(Copy(S, 6, 255));
        Continue;
      End;
      RefRead := ShaParse(S, H);
    End
    Else RefRead := PackedRef(Name, H);
    Break;
  End;
  BufFree(B);
End;

{ branche de HEAD ('' : HEAD detachee) }
Function HeadRef : String;
Var B : TBuf; S : String;
Begin
  HeadRef := '';
  BufInit(B);
  If FileLoad(GitPath('HEAD'), B) Then
  Begin
    S := TrimS(FirstLine(B));
    If Copy(S, 1, 5) = 'ref: ' Then HeadRef := TrimS(Copy(S, 6, 255));
  End;
  BufFree(B);
End;

Function HeadBranch : String;
Var S : String;
Begin
  S := HeadRef;
  If Copy(S, 1, 11) = 'refs/heads/' Then Delete(S, 1, 11);
  HeadBranch := S;
End;

Function RefWrite(Const Name : String; Const H : TSha) : Boolean;
Var P : String;
Begin
  P := GitPath(Name);
  MkDirs(ParentOf(P));
  RefWrite := FileSaveStr(P, ShaHex(H) + #10);
End;

Procedure SetHead(Const Ref : String);
Begin
  If FileSaveStr(GitPath('HEAD'), 'ref: ' + Ref + #10) Then ;
End;

{ supprime une reference (fichier et ligne de packed-refs) }
Procedure RefDelete(Const Name : String);
Var B, O : TBuf; P : LongInt; S : String; Skip : Boolean;
Begin
  FileDel(GitPath(Name));
  BufInit(B); BufInit(O);
  If FileLoad(GitPath('packed-refs'), B) Then
  Begin
    P := 0; Skip := False;
    While BufLine(B, P, S) Do
    Begin
      If (S <> '') And (S[1] = '^') And Skip Then Continue;
      Skip := (Length(S) > 41) And (Copy(S, 42, 255) = Name);
      If Not Skip Then
      Begin
        BufStr(O, S); BufByte(O, 10);
      End;
    End;
    If FileSave(GitPath('packed-refs'), O, 0, O.N) Then ;
  End;
  BufFree(B); BufFree(O);
End;

Const
  MaxRefs = 400;

Type
  TRefs = Record
    N : LongInt;
    Name : Array[0..MaxRefs - 1] Of String[120];
    Sha : Array[0..MaxRefs - 1] Of TSha;
  End;
  PRefs = ^TRefs;

Procedure RefsAdd(Var R : TRefs; Const Nm : String; Const H : TSha);
Var I : LongInt;
Begin
  For I := 0 To R.N - 1 Do
    If R.Name[I] = Nm Then
    Begin
      R.Sha[I] := H; Exit;
    End;
  If R.N >= MaxRefs Then Exit;
  R.Name[R.N] := Nm; R.Sha[R.N] := H;
  Inc(R.N);
End;

Procedure RefsScanDir(Var R : TRefs; Const Rel : String);
Var B : TBuf; H : TSha; L : TFlat; J : LongInt;
Begin
  FlatInit(L);
  DirList(GitPath(Rel), L, False);
  BufInit(B);
  For J := 0 To L.N - 1 Do
    If L.E^[J].Mode <> 0 Then RefsScanDir(R, Rel + '/' + L.E^[J].Path)
    Else If FileLoad(GitPath(Rel + '/' + L.E^[J].Path), B) Then
      If ShaParse(TrimS(FirstLine(B)), H) Then
        RefsAdd(R, Rel + '/' + L.E^[J].Path, H);
  BufFree(B);
  FlatFree(L);
End;

{ references sous Prefix (refs/heads, refs/remotes/origin, refs/tags) }
Procedure RefsList(Var R : TRefs; Const Prefix : String);
Var B : TBuf; P : LongInt; S : String; H : TSha; I, J : LongInt; T : String;
    TH : TSha;
Begin
  R.N := 0;
  BufInit(B);
  If FileLoad(GitPath('packed-refs'), B) Then
  Begin
    P := 0;
    While BufLine(B, P, S) Do
      If (Length(S) > 41) And (S[1] <> '#') And (S[1] <> '^') And
         (Copy(S, 42, Length(Prefix)) = Prefix) Then
        If ShaParse(S, H) Then RefsAdd(R, Copy(S, 42, 255), H);
  End;
  BufFree(B);
  T := Prefix;
  If (T <> '') And (T[Length(T)] = '/') Then Delete(T, Length(T), 1);
  If DirExist(GitPath(T)) Then RefsScanDir(R, T);
  { tri par nom }
  For I := 0 To R.N - 2 Do
    For J := I + 1 To R.N - 1 Do
      If R.Name[J] < R.Name[I] Then
      Begin
        T := R.Name[I]; R.Name[I] := R.Name[J]; R.Name[J] := T;
        TH := R.Sha[I]; R.Sha[I] := R.Sha[J]; R.Sha[J] := TH;
      End;
End;

{ config : [Sect "Sub"] Key = Value }
{ (OS2PC, comme WPC : le resultat d'une fonction String vit dans un anneau de tampons
  temporaires ; il est affecte une seule fois, a la fin) }
Function CfgGet(Const Sect, Sub, Key : String) : String;
Var B : TBuf; P, K : LongInt; S, Cur, W, R : String;
Begin
  R := '';
  BufInit(B);
  If FileLoad(GitPath('config'), B) Then
  Begin
    P := 0; Cur := '';
    W := LowStr(Sect);
    If Sub <> '' Then W := W + ' "' + Sub + '"';
    While BufLine(B, P, S) Do
    Begin
      S := TrimS(S);
      If (S <> '') And (S[1] = '[') Then
      Begin
        Cur := Copy(S, 2, Length(S) - 2);
        K := Pos(' ', Cur);
        If K = 0 Then Cur := LowStr(Cur)
        Else Cur := LowStr(Copy(Cur, 1, K - 1)) + Copy(Cur, K, 255);
      End
      Else If Cur = W Then
      Begin
        K := Pos('=', S);
        If (K > 0) And (LowStr(TrimS(Copy(S, 1, K - 1))) = LowStr(Key)) Then
          R := TrimS(Copy(S, K + 1, 255));
      End;
    End;
  End;
  BufFree(B);
  CfgGet := R;
End;

Procedure CfgSet(Const Sect, Sub, Key, Value : String);
Var B, O : TBuf; P, K : LongInt; S, Cur, W, T : String; Done, InS : Boolean;
Begin
  BufInit(B); BufInit(O);
  If FileLoad(GitPath('config'), B) Then ;
  P := 0; Cur := ''; Done := False; InS := False;
  W := LowStr(Sect);
  If Sub <> '' Then W := W + ' "' + Sub + '"';
  While BufLine(B, P, S) Do
  Begin
    T := TrimS(S);
    If (T <> '') And (T[1] = '[') Then
    Begin
      If InS And Not Done Then
      Begin
        BufStr(O, #9 + Key + ' = ' + Value + #10); Done := True;
      End;
      Cur := Copy(T, 2, Length(T) - 2);
      K := Pos(' ', Cur);
      If K = 0 Then Cur := LowStr(Cur)
      Else Cur := LowStr(Copy(Cur, 1, K - 1)) + Copy(Cur, K, 255);
      InS := Cur = W;
    End
    Else If InS And Not Done Then
    Begin
      K := Pos('=', T);
      If (K > 0) And (LowStr(TrimS(Copy(T, 1, K - 1))) = LowStr(Key)) Then
      Begin
        S := #9 + Key + ' = ' + Value; Done := True;
      End;
    End;
    BufStr(O, S + #10);
  End;
  If Not Done Then
  Begin
    If Not InS Then
      If Sub = '' Then BufStr(O, '[' + Sect + ']' + #10)
      Else BufStr(O, '[' + Sect + ' "' + Sub + '"]' + #10);
    BufStr(O, #9 + Key + ' = ' + Value + #10);
  End;
  If FileSave(GitPath('config'), O, 0, O.N) Then ;
  BufFree(B); BufFree(O);
End;

{ ==================================================================== }
{ Index (.git/index, version 2)                                         }
{ ==================================================================== }

Function IndexRead(Var F : TFlat) : Boolean;
Var B : TBuf; N, I, O, L, K, Ver : LongInt;
Begin
  IndexRead := False;
  F.N := 0;
  BufInit(B);
  If Not FileLoad(GitPath('index'), B) Then
  Begin
    BufFree(B);
    IndexRead := True;                 { pas d'index : vide }
    Exit;
  End;
  If (B.N < 32) Or (BufStrAt(B, 0, 4) <> 'DIRC') Then
  Begin
    GitErr := 'index invalide'; BufFree(B); Exit;
  End;
  Ver := BE32(B, 4);
  If (Ver < 2) Or (Ver > 3) Then
  Begin
    GitErr := 'index version ' + IStr(Ver) + ' non prise en charge';
    BufFree(B); Exit;
  End;
  N := BE32(B, 8);
  O := 12;
  For I := 0 To N - 1 Do
  Begin
    If O + 62 > B.N Then Break;
    L := (B.P^[O + 60] Shl 8) Or B.P^[O + 61];
    K := L And $FFF;
    If (Ver = 3) And ((L And $4000) <> 0) Then
    Begin
      K := FlatAdd(F, BufStrAt(B, O + 64, K));
      L := 64;
    End
    Else
    Begin
      K := FlatAdd(F, BufStrAt(B, O + 62, K));
      L := 62;
    End;
    F.E^[K].MTime := BE32(B, O + 8);
    F.E^[K].Mode := BE32(B, O + 24);
    F.E^[K].Size := BE32(B, O + 36);
    ShaFrom(B, O + 40, F.E^[K].Sha);
    { longueur : multiple de 8 avec au moins un octet nul }
    L := L + Length(F.E^[K].Path);
    O := O + ((L + 8) Div 8) * 8;
  End;
  BufFree(B);
  FlatSort(F);
  IndexRead := True;
End;

Function IndexWrite(Var F : TFlat) : Boolean;
Var B : TBuf; I, J, L : LongInt; C : TSha1; H : TSha;
Begin
  BufInit(B);
  BufStr(B, 'DIRC');
  PutBE32(B, 2);
  PutBE32(B, F.N);
  For I := 0 To F.N - 1 Do
  Begin
    PutBE32(B, F.E^[I].MTime); PutBE32(B, 0);     { ctime }
    PutBE32(B, F.E^[I].MTime); PutBE32(B, 0);     { mtime }
    PutBE32(B, 0); PutBE32(B, 0);                 { dev, ino }
    PutBE32(B, F.E^[I].Mode);
    PutBE32(B, 0); PutBE32(B, 0);                 { uid, gid }
    PutBE32(B, F.E^[I].Size);
    BufMem(B, F.E^[I].Sha, 20);
    L := MinL(Length(F.E^[I].Path), $FFF);
    BufByte(B, L Shr 8); BufByte(B, L And 255);
    BufStr(B, F.E^[I].Path);
    L := 62 + Length(F.E^[I].Path);
    For J := 1 To ((L + 8) Div 8) * 8 - L Do BufByte(B, 0);
  End;
  Sha1Init(C);
  Sha1Mem(C, B, 0, B.N);
  Sha1Final(C, H);
  BufMem(B, H, 20);
  IndexWrite := FileSave(GitPath('index'), B, 0, B.N);
  BufFree(B);
End;

{ ==================================================================== }
{ Arbres et commits                                                     }
{ ==================================================================== }

Function OctVal(Const S : String) : LongInt;
Var V, I : LongInt;
Begin
  V := 0;
  For I := 1 To Length(S) Do V := V * 8 + Ord(S[I]) - 48;
  OctVal := V;
End;

Function OctStr(V : LongInt) : String;
Var S : String;
Begin
  S := '';
  Repeat
    S := Chr(48 + (V And 7)) + S;
    V := V Shr 3;
  Until V = 0;
  OctStr := S;
End;

{ arbre H aplati (fichiers seulement, chemins Prefix + nom) -> F }
Function TreeFlat(Const H : TSha; Const Prefix : String; Var F : TFlat)
  : Boolean;
Var D : TBuf; T, P, Q, M, K : LongInt; Nm, Md : String; S : TSha;
Begin
  TreeFlat := False;
  BufInit(D);
  If Not ReadObject(H, T, D) Or (T <> OtTree) Then
  Begin
    BufFree(D); Exit;
  End;
  P := 0;
  While P < D.N Do
  Begin
    Q := P;
    While (Q < D.N) And (D.P^[Q] <> 32) Do Inc(Q);
    Md := BufStrAt(D, P, Q - P);
    P := Q + 1; Q := P;
    While (Q < D.N) And (D.P^[Q] <> 0) Do Inc(Q);
    Nm := BufStrAt(D, P, Q - P);
    ShaFrom(D, Q + 1, S);
    P := Q + 21;
    M := OctVal(Md);
    If M = $4000 Then
    Begin
      If Not TreeFlat(S, Prefix + Nm + '/', F) Then
      Begin
        BufFree(D); Exit;
      End;
    End
    Else
    Begin
      K := FlatAdd(F, Prefix + Nm);
      F.E^[K].Sha := S; F.E^[K].Mode := M;
    End;
  End;
  BufFree(D);
  TreeFlat := True;
End;

{ ecrit les arbres de la liste triee F (a partir de I, sous Prefix) }
Function TreeBuild(Var F : TFlat; Var I : LongInt; Const Prefix : String;
  Var H : TSha) : Boolean;
Var D : TBuf; R, Dir : String; K : LongInt; Sub : TSha;
Begin
  TreeBuild := False;
  BufInit(D);
  While (I < F.N) And (Copy(F.E^[I].Path, 1, Length(Prefix)) = Prefix) Do
  Begin
    R := Copy(F.E^[I].Path, Length(Prefix) + 1, 255);
    K := Pos('/', R);
    If K > 0 Then
    Begin
      Dir := Copy(R, 1, K - 1);
      If Not TreeBuild(F, I, Prefix + Dir + '/', Sub) Then
      Begin
        BufFree(D); Exit;
      End;
      BufStr(D, '40000 ' + Dir);
      BufByte(D, 0);
      BufMem(D, Sub, 20);
    End
    Else
    Begin
      BufStr(D, OctStr(F.E^[I].Mode) + ' ' + R);
      BufByte(D, 0);
      BufMem(D, F.E^[I].Sha, 20);
      Inc(I);
    End;
  End;
  TreeBuild := WriteObject(OtTree, D, H);
  BufFree(D);
End;

Function TreeFromFlat(Var F : TFlat; Var H : TSha) : Boolean;
Var I : LongInt;
Begin
  I := 0;
  TreeFromFlat := TreeBuild(F, I, '', H);
End;

Const
  MaxParents = 8;

Type
  TCommit = Record
    Tree : TSha;
    Parent : Array[0..MaxParents - 1] Of TSha;
    PN : LongInt;
    Author, Committer : String;        { Nom <courriel> }
    ATime, CTime : LongInt;            { secondes Unix }
    Summary : String;                  { premiere ligne du message }
  End;

Function ParseIdent(Const S : String; Var Who : String; Var Tm : LongInt)
  : Boolean;
Var K, E : LongInt; R : String;
Begin
  K := Pos('>', S);
  Who := Copy(S, 1, K);
  R := TrimS(Copy(S, K + 1, 255));
  K := Pos(' ', R);
  If K > 0 Then R := Copy(R, 1, K - 1);
  Val(R, Tm, E);
  ParseIdent := E = 0;
End;

{ commit H : en-tete et resume ; Msg (si non Nil) recoit le message }
Function CommitRead(Const H : TSha; Var C : TCommit; Msg : Pointer)
  : Boolean;
Var D : TBuf; T, P : LongInt; S : String; M : ^TBuf;
Begin
  CommitRead := False;
  C.PN := 0; C.Author := ''; C.Committer := ''; C.Summary := '';
  C.ATime := 0; C.CTime := 0;
  BufInit(D);
  If Not ReadObject(H, T, D) Or (T <> OtCommit) Then
  Begin
    BufFree(D); Exit;
  End;
  P := 0;
  While BufLine(D, P, S) Do
  Begin
    If S = '' Then Break;
    If Copy(S, 1, 5) = 'tree ' Then
    Begin
      If ShaParse(Copy(S, 6, 40), C.Tree) Then ;
    End
    Else If Copy(S, 1, 7) = 'parent ' Then
    Begin
      If C.PN < MaxParents Then
      Begin
        If ShaParse(Copy(S, 8, 40), C.Parent[C.PN]) Then Inc(C.PN);
      End;
    End
    Else If Copy(S, 1, 7) = 'author ' Then
    Begin
      If ParseIdent(Copy(S, 8, 255), C.Author, C.ATime) Then ;
    End
    Else If Copy(S, 1, 10) = 'committer ' Then
    Begin
      If ParseIdent(Copy(S, 11, 255), C.Committer, C.CTime) Then ;
    End;
  End;
  If Msg <> Nil Then
  Begin
    M := Msg;
    M^.N := 0;
    BufAppend(M^, D, P, D.N - P);
  End;
  While BufLine(D, P, S) Do
    If TrimS(S) <> '' Then
    Begin
      C.Summary := S; Break;
    End;
  BufFree(D);
  CommitRead := True;
End;

Function NowUnix : LongInt; Forward;

Var
  UserName, UserEmail : String;        { auteur des commits }

{ ecrit un commit ; Parents : 0, 1 ou 2 }
Function CommitWrite(Const Tree : TSha; Var Par : Array Of TSha;
  PN : LongInt; Var Msg : TBuf; Var H : TSha) : Boolean;
Var D : TBuf; I : LongInt; Id : String;
Begin
  BufInit(D);
  BufStr(D, 'tree ' + ShaHex(Tree) + #10);
  For I := 0 To PN - 1 Do BufStr(D, 'parent ' + ShaHex(Par[I]) + #10);
  Id := UserName + ' <' + UserEmail + '> ' + IStr(NowUnix) + ' +0000';
  BufStr(D, 'author ' + Id + #10);
  BufStr(D, 'committer ' + Id + #10#10);
  BufAppend(D, Msg, 0, Msg.N);
  If (Msg.N = 0) Or (Msg.P^[Msg.N - 1] <> 10) Then BufByte(D, 10);
  CommitWrite := WriteObject(OtCommit, D, H);
  BufFree(D);
End;

{ arbre aplati d'un commit (vide si H est nul) }
Function CommitFlat(Const H : TSha; Var F : TFlat) : Boolean;
Var C : TCommit;
Begin
  F.N := 0;
  CommitFlat := True;
  If ShaIsZero(H) Then Exit;
  CommitFlat := False;
  If Not CommitRead(H, C, Nil) Then Exit;
  If Not TreeFlat(C.Tree, '', F) Then Exit;
  FlatSort(F);
  CommitFlat := True;
End;

{ ==================================================================== }
{ Ensembles d'empreintes (table de hachage)                             }
{ ==================================================================== }

Type
  TShaSetArr = Array[0..$3FFFFF] Of TSha;
  TShaSet = Record
    H : ^TShaSetArr;
    Cap, N : LongInt;
  End;

Procedure SetInit(Var S : TShaSet; Cap : LongInt);
Var I : LongInt;
Begin
  S.Cap := 1024;
  While S.Cap < Cap * 2 Do S.Cap := S.Cap * 2;
  GetMem(S.H, S.Cap * 20);
  For I := 0 To S.Cap - 1 Do S.H^[I] := ShaZero;
  S.N := 0;
End;

Procedure SetFree(Var S : TShaSet);
Begin
  If S.H <> Nil Then FreeMem(S.H, S.Cap * 20);
  S.H := Nil; S.N := 0;
End;

Function SetSlot(Var S : TShaSet; Const K : TSha) : LongInt;
Var I : LongInt;
Begin
  I := ((K[0] Shl 16) Or (K[1] Shl 8) Or K[2]) And (S.Cap - 1);
  While Not ShaIsZero(S.H^[I]) And Not ShaEq(S.H^[I], K) Do
    I := (I + 1) And (S.Cap - 1);
  SetSlot := I;
End;

Function SetHas(Var S : TShaSet; Const K : TSha) : Boolean;
Begin
  SetHas := ShaEq(S.H^[SetSlot(S, K)], K);
End;

{ ajoute ; faux s'il y etait deja }
Function SetAdd(Var S : TShaSet; Const K : TSha) : Boolean;
Var I, J : LongInt; Old : ^TShaSetArr; OC : LongInt;
Begin
  SetAdd := False;
  I := SetSlot(S, K);
  If ShaEq(S.H^[I], K) Then Exit;
  S.H^[I] := K;
  Inc(S.N);
  SetAdd := True;
  If S.N * 2 > S.Cap Then
  Begin
    Old := S.H; OC := S.Cap;
    S.Cap := S.Cap * 2;
    GetMem(S.H, S.Cap * 20);
    For J := 0 To S.Cap - 1 Do S.H^[J] := ShaZero;
    For J := 0 To OC - 1 Do
      If Not ShaIsZero(Old^[J]) Then S.H^[SetSlot(S, Old^[J])] := Old^[J];
    FreeMem(Old, OC * 20);
  End;
End;

{ ancetres de H (commits) dans S }
Procedure Ancestors(Const H : TSha; Var S : TShaSet);
Var Q : ^TShaSetArr; QN, QCap, I : LongInt; C : TCommit; X : TSha;
    NQ : ^TShaSetArr;
Begin
  If ShaIsZero(H) Then Exit;
  QCap := 256;
  GetMem(Q, QCap * 20);
  QN := 1; Q^[0] := H;
  While QN > 0 Do
  Begin
    Dec(QN);
    X := Q^[QN];
    If Not SetAdd(S, X) Then Continue;
    If Not CommitRead(X, C, Nil) Then Continue;
    For I := 0 To C.PN - 1 Do
    Begin
      If QN >= QCap Then
      Begin
        GetMem(NQ, QCap * 40);
        Move(Q^[0], NQ^[0], QCap * 20);
        FreeMem(Q, QCap * 20);
        Q := NQ; QCap := QCap * 2;
      End;
      Q^[QN] := C.Parent[I]; Inc(QN);
    End;
  End;
  FreeMem(Q, QCap * 20);
End;

{ base de fusion de A et B (premier ancetre commun trouve en largeur
  depuis B) ; faux s'il n'y en a pas }
Function MergeBase(Const A, B : TSha; Var Base : TSha) : Boolean;
Var SA, Seen : TShaSet; Q : ^TShaSetArr; QH, QT, QCap, I : LongInt;
    C : TCommit; X : TSha; NQ : ^TShaSetArr;
Begin
  MergeBase := False;
  SetInit(SA, 1024); SetInit(Seen, 1024);
  Ancestors(A, SA);
  QCap := 4096;
  GetMem(Q, QCap * 20);
  QH := 0; QT := 1; Q^[0] := B;
  While QH < QT Do
  Begin
    X := Q^[QH]; Inc(QH);
    If SetHas(SA, X) Then
    Begin
      Base := X; MergeBase := True; Break;
    End;
    If Not SetAdd(Seen, X) Then Continue;
    If CommitRead(X, C, Nil) Then
      For I := 0 To C.PN - 1 Do
      Begin
        If QT >= QCap Then
        Begin
          GetMem(NQ, QCap * 40);
          Move(Q^[0], NQ^[0], QCap * 20);
          FreeMem(Q, QCap * 20);
          Q := NQ; QCap := QCap * 2;
        End;
        Q^[QT] := C.Parent[I]; Inc(QT);
      End;
  End;
  FreeMem(Q, QCap * 20);
  SetFree(SA); SetFree(Seen);
End;
Type
  PLongArr = ^TLongArr;

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

{ heure du systeme (DosGetDateTime), tenue pour UTC comme sous
  Pasdows (fuseau +0000 dans les commits) }
Function NowUnix : LongInt;
Var Dt : Array[0..11] Of Byte;
Begin
  FillChar(Dt, SizeOf(Dt), 0);
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
{ .gitignore                                                            }
{ ==================================================================== }

Const
  MaxIgn = 300;

Var
  IgnN : LongInt;
  IgnBase : Array[0..MaxIgn - 1] Of String[80];
  IgnPat : Array[0..MaxIgn - 1] Of String[80];
  IgnFl : Array[0..MaxIgn - 1] Of Byte;  { 1 negation 2 dossier 4 ancre }

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

Procedure IgnAdd(Const Base : String; S : String);
Var F : Byte;
Begin
  S := TrimS(S);
  If (S = '') Or (S[1] = '#') Or (IgnN >= MaxIgn) Then Exit;
  F := 0;
  If S[1] = '!' Then
  Begin
    F := 1; Delete(S, 1, 1);
  End;
  If (S <> '') And (S[Length(S)] = '/') Then
  Begin
    F := F Or 2; Delete(S, Length(S), 1);
  End;
  If Pos('/', S) > 0 Then F := F Or 4;
  If (S <> '') And (S[1] = '/') Then Delete(S, 1, 1);
  If S = '' Then Exit;
  IgnBase[IgnN] := Base; IgnPat[IgnN] := S; IgnFl[IgnN] := F;
  Inc(IgnN);
End;

Procedure IgnLoad(Const Path, Base : String);
Var B : TBuf; P : LongInt; S : String;
Begin
  BufInit(B);
  If FileLoad(Path, B) Then
  Begin
    P := 0;
    While BufLine(B, P, S) Do IgnAdd(Base, S);
  End;
  BufFree(B);
End;

Function Ignored(Const Path : String; IsDir : Boolean) : Boolean;
Var I : LongInt; R : String; Res : Boolean;
Begin
  Res := False;
  For I := 0 To IgnN - 1 Do
  Begin
    If Copy(Path, 1, Length(IgnBase[I])) <> IgnBase[I] Then Continue;
    If ((IgnFl[I] And 2) <> 0) And Not IsDir Then Continue;
    If ((IgnFl[I] And 1) <> 0) = Res Then
    Begin
      R := Copy(Path, Length(IgnBase[I]) + 1, 255);
      If (IgnFl[I] And 4) = 0 Then R := NameOf(R);
      If Glob(IgnPat[I], 1, R, 1) Then Res := Not Res;
    End;
  End;
  Ignored := Res;
End;

{ ==================================================================== }
{ Etat du depot                                                         }
{ ==================================================================== }

Const
  StNew = 1;
  StMod = 2;
  StDel = 3;
  StConf = 4;
  FlSel = $100;                        { fichier coche }

Var
  HeadSha : TSha;
  HeadF, IdxF, WorkF, Chg : TFlat;
  InMerge : Boolean;

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

Var
  FsAnsi : Boolean;                    { noms de fichiers en page 850 }

Function WorkPath(Const Rel : String) : String;
Begin
  If FsAnsi Then WorkPath := WorkDir + PS + OsPath(AnsiToOem(Utf8ToAnsi(Rel)))
  Else WorkPath := WorkDir + PS + OsPath(Rel);
End;

Function FsName(Const S : String) : String;
Begin
  If FsAnsi Then FsName := AnsiToUtf8(OemToAnsi(S)) Else FsName := S;
End;

{ vrai si un fichier suivi est sous le dossier Rel/ }
Function TrackedUnder(Const Rel : String) : Boolean;
Var K : LongInt;
Begin
  K := FlatLower(HeadF, Rel + '/');
  TrackedUnder := (K < HeadF.N) And
    (Copy(HeadF.E^[K].Path, 1, Length(Rel) + 1) = Rel + '/');
End;

{ le dossier est lu en entier (DirList) avant de descendre dans ses
  sous-dossiers }
Procedure ScanDir(Const Rel : String; Ign : Boolean);
Var P, D : String; K, J : LongInt; I : Boolean; L : TFlat;
Begin
  If Rel = '' Then D := WorkDir Else D := WorkPath(Rel);
  If Not Ign And (Rel <> '') Then IgnLoad(D + PS + '.gitignore', Rel + '/');
  FlatInit(L);
  DirList(D, L, Rel = '');
  For J := 0 To L.N - 1 Do
  Begin
    If Rel = '' Then P := FsName(L.E^[J].Path)
    Else P := Rel + '/' + FsName(L.E^[J].Path);
    If L.E^[J].Mode <> 0 Then
    Begin
      I := Ign Or Ignored(P, True);
      If Not I Or TrackedUnder(P) Then ScanDir(P, I);
    End
    Else
    Begin
      I := Ign Or Ignored(P, False);
      If Not I Or (FlatFind(HeadF, P) >= 0) Then
      Begin
        K := FlatAdd(WorkF, P);
        WorkF.E^[K].Size := L.E^[J].Size;
        WorkF.E^[K].MTime := L.E^[J].MTime;
      End;
    End;
  End;
  FlatFree(L);
End;

{ empreinte d'un fichier de travail (lu par morceaux) }
Function BlobOfFile(Const Rel : String; Var H : TSha) : Boolean;
Begin
  BlobOfFile := HashFile(WorkPath(Rel), OtBlob, H);
End;

Function HasConflictMark(Const Rel : String) : Boolean;
Var B : TBuf; P : LongInt; S : String;
Begin
  HasConflictMark := False;
  BufInit(B);
  If FileLoad(WorkPath(Rel), B) Then
  Begin
    P := 0;
    While BufLine(B, P, S) Do
      If Copy(S, 1, 8) = '<<<<<<< ' Then
      Begin
        HasConflictMark := True; Break;
      End;
  End;
  BufFree(B);
End;

{ index = arbre F, avec les informations de fichier quand le contenu du
  dossier de travail correspond }
Function IndexFrom(Var F : TFlat) : Boolean;
Var X : TFlat; I, K : LongInt;
Begin
  FlatInit(X);
  FlatCopy(X, F);
  For I := 0 To X.N - 1 Do
  Begin
    X.E^[I].Size := 0; X.E^[I].MTime := 0;
    K := FlatFind(WorkF, X.E^[I].Path);
    If (K >= 0) And ShaEq(WorkF.E^[K].Sha, X.E^[I].Sha) Then
    Begin
      X.E^[I].Size := WorkF.E^[K].Size;
      X.E^[I].MTime := WorkF.E^[K].MTime;
    End;
  End;
  IndexFrom := IndexWrite(X);
  FlatFree(X);
End;

Procedure ChgAdd(Const P : String; St : LongInt; Const Old, New : TSha;
  Mode : LongInt);
Var K : LongInt;
Begin
  K := FlatAdd(Chg, P);
  Chg.E^[K].Flag := St Or FlSel;
  Chg.E^[K].Old := Old; Chg.E^[K].Sha := New;
  Chg.E^[K].Mode := Mode;
End;

{ calcule HeadF, IdxF, WorkF et Chg (modifications par rapport a HEAD) }
Function RepoStatus : Boolean;
Var I, K, Hashed : LongInt; Same : Boolean; T : TSha;
Begin
  RepoStatus := False;
  PacksScan;
  If Not RefRead('HEAD', HeadSha) Then HeadSha := ShaZero;
  If Not CommitFlat(HeadSha, HeadF) Then
  Begin
    GitErr := 'commit HEAD illisible'; Exit;
  End;
  If Not IndexRead(IdxF) Then IdxF.N := 0;
  Same := IdxF.N = HeadF.N;
  If Same Then
    For I := 0 To HeadF.N - 1 Do
      If (IdxF.E^[I].Path <> HeadF.E^[I].Path) Or
         Not ShaEq(IdxF.E^[I].Sha, HeadF.E^[I].Sha) Then
      Begin
        Same := False; Break;
      End;
  IgnN := 0;
  IgnLoad(WorkDir + PS + '.gitignore', '');
  IgnLoad(GitPath('info/exclude'), '');
  WorkF.N := 0;
  ScanDir('', False);
  FlatSort(WorkF);
  InMerge := FileExist(GitPath('MERGE_HEAD'));
  Chg.N := 0;
  Hashed := 0;
  For I := 0 To WorkF.N - 1 Do
  Begin
    K := FlatFind(IdxF, WorkF.E^[I].Path);
    If (K >= 0) And (IdxF.E^[K].MTime <> 0) And
       (IdxF.E^[K].MTime = WorkF.E^[I].MTime) And
       (IdxF.E^[K].Size = WorkF.E^[I].Size) Then
      WorkF.E^[I].Sha := IdxF.E^[K].Sha
    Else
    Begin
      If (Hashed And 15) = 0 Then
        GitProgress('Analyse des fichiers', I, WorkF.N);
      If BlobOfFile(WorkF.E^[I].Path, T) Then WorkF.E^[I].Sha := T;
      Inc(Hashed);
    End;
    K := FlatFind(HeadF, WorkF.E^[I].Path);
    If K < 0 Then
      ChgAdd(WorkF.E^[I].Path, StNew, ShaZero, WorkF.E^[I].Sha, $81A4)
    Else If Not ShaEq(HeadF.E^[K].Sha, WorkF.E^[I].Sha) Then
    Begin
      If InMerge And HasConflictMark(WorkF.E^[I].Path) Then
        ChgAdd(WorkF.E^[I].Path, StConf, HeadF.E^[K].Sha,
          WorkF.E^[I].Sha, HeadF.E^[K].Mode)
      Else
        ChgAdd(WorkF.E^[I].Path, StMod, HeadF.E^[K].Sha,
          WorkF.E^[I].Sha, HeadF.E^[K].Mode);
    End;
  End;
  For I := 0 To HeadF.N - 1 Do
    If (HeadF.E^[I].Mode <> $E000) And
       (FlatFind(WorkF, HeadF.E^[I].Path) < 0) Then
      ChgAdd(HeadF.E^[I].Path, StDel, HeadF.E^[I].Sha, ShaZero,
        HeadF.E^[I].Mode);
  FlatSort(Chg);
  { met a jour le cache de l'index s'il ne contient rien d'indexe }
  If Same And (Hashed > 0) Then
  Begin
    If IndexFrom(HeadF) Then ;
  End;
  RepoStatus := True;
End;

{ blob du fichier de travail Rel (ecrit dans la base d'objets) }
Function StoreFile(Const Rel : String; Var H : TSha) : Boolean;
Var B : TBuf; Sz, Tm : LongInt;
Begin
  StoreFile := False;
  If Not FileStat(WorkPath(Rel), Sz, Tm) Then Exit;
  { gros fichier : objet ecrit par morceaux }
  If Sz > BigObj Then
  Begin
    StoreFile := WriteObjectFile(OtBlob, WorkPath(Rel), H); Exit;
  End;
  BufInit(B);
  StoreFile := FileLoad(WorkPath(Rel), B) And WriteObject(OtBlob, B, H);
  BufFree(B);
End;

Procedure ClearMerge;
Begin
  FileDel(GitPath('MERGE_HEAD'));
  FileDel(GitPath('MERGE_MSG'));
  FileDel(GitPath('MERGE_MODE'));
End;

{ met a jour la branche courante (ou HEAD detachee) }
Function HeadSet(Const H : TSha) : Boolean;
Var R : String;
Begin
  R := HeadRef;
  If R = '' Then R := 'HEAD';
  HeadSet := RefWrite(R, H);
  HeadSha := H;
End;

{ valide les modifications cochees de Chg (apres RepoStatus) }
Function DoCommit(Var Msg : TBuf; Var NewSha : TSha) : Boolean;
Var N : TFlat; I, K, St, PN : LongInt; Tree, H : TSha;
    Par : Array[0..1] Of TSha; B : TBuf; Any : Boolean;
Begin
  DoCommit := False;
  FlatInit(N);
  FlatCopy(N, HeadF);
  Any := False;
  For I := 0 To Chg.N - 1 Do
  Begin
    If (Chg.E^[I].Flag And FlSel) = 0 Then Continue;
    Any := True;
    St := Chg.E^[I].Flag And $FF;
    K := FlatFind(N, Chg.E^[I].Path);
    If St = StDel Then
    Begin
      If K >= 0 Then N.E^[K].Path := '';
    End
    Else
    Begin
      If Not StoreFile(Chg.E^[I].Path, H) Then
      Begin
        GitErr := 'lecture impossible : ' + Chg.E^[I].Path;
        FlatFree(N); Exit;
      End;
      If K < 0 Then
      Begin
        K := FlatAdd(N, Chg.E^[I].Path);
        N.E^[K].Mode := $81A4;
      End;
      N.E^[K].Sha := H;
    End;
  End;
  If Not Any And Not InMerge Then
  Begin
    GitErr := 'aucune modification coch'#233'e'; FlatFree(N); Exit;
  End;
  { retire les chemins effaces }
  K := 0;
  For I := 0 To N.N - 1 Do
    If N.E^[I].Path <> '' Then
    Begin
      N.E^[K] := N.E^[I]; Inc(K);
    End;
  N.N := K;
  FlatSort(N);
  If Not TreeFromFlat(N, Tree) Then
  Begin
    FlatFree(N); Exit;
  End;
  PN := 0;
  If Not ShaIsZero(HeadSha) Then
  Begin
    Par[0] := HeadSha; PN := 1;
  End;
  If InMerge Then
  Begin
    BufInit(B);
    If FileLoad(GitPath('MERGE_HEAD'), B) Then
      If ShaParse(FirstLine(B), Par[PN]) Then Inc(PN);
    BufFree(B);
  End;
  If Not CommitWrite(Tree, Par, PN, Msg, NewSha) Then
  Begin
    FlatFree(N); Exit;
  End;
  If Not HeadSet(NewSha) Then
  Begin
    GitErr := 'mise '#224' jour de la branche impossible'; FlatFree(N); Exit;
  End;
  ClearMerge;
  InMerge := False;
  { contenu de travail des fichiers valides = blob ecrit }
  For I := 0 To N.N - 1 Do
  Begin
    K := FlatFind(WorkF, N.E^[I].Path);
    If K >= 0 Then
    Begin
      St := FlatFind(Chg, N.E^[I].Path);
      If (St >= 0) And ((Chg.E^[St].Flag And FlSel) <> 0) Then
        WorkF.E^[K].Sha := N.E^[I].Sha;
    End;
  End;
  If IndexFrom(N) Then ;
  FlatFree(N);
  DoCommit := True;
End;

Procedure RmEmptyDirs(Rel : String);
Var K : LongInt;
Begin
  Repeat
    K := Length(Rel);
    While (K > 0) And (Rel[K] <> '/') Do Dec(K);
    If K = 0 Then Exit;
    Rel := Copy(Rel, 1, K - 1);
    If Not FRmDir(WorkPath(Rel)) Then Exit;
  Until False;
End;

Function WriteWorkFile(Const Rel : String; Const H : TSha; Mode : LongInt)
  : Boolean;
Var T : LongInt; P : String;
Begin
  WriteWorkFile := False;
  P := WorkPath(Rel);
  MkDirs(ParentOf(P));
  If Mode = $E000 Then
  Begin
    MkDirs(P); WriteWorkFile := True; Exit;
  End;
  If ObjToFile(H, P, T) And (T = OtBlob) Then WriteWorkFile := True
  Else If GitErr = '' Then GitErr := 'objet manquant ' + ShaHex(H);
End;

{ fait passer le dossier de travail de Cur a Tgt et reecrit l'index }
Function WorkUpdate(Var Cur, Tgt : TFlat) : Boolean;
Var I, K, Sz, Tm : LongInt;
Begin
  WorkUpdate := False;
  For I := 0 To Cur.N - 1 Do
    If FlatFind(Tgt, Cur.E^[I].Path) < 0 Then
    Begin
      FileDel(WorkPath(Cur.E^[I].Path));
      RmEmptyDirs(Cur.E^[I].Path);
    End;
  For I := 0 To Tgt.N - 1 Do
  Begin
    K := FlatFind(Cur, Tgt.E^[I].Path);
    If (K < 0) Or Not ShaEq(Cur.E^[K].Sha, Tgt.E^[I].Sha) Or
       Not FileExist(WorkPath(Tgt.E^[I].Path)) Then
    Begin
      If (I And 7) = 0 Then
        GitProgress('Extraction des fichiers', I, Tgt.N);
      If Not WriteWorkFile(Tgt.E^[I].Path, Tgt.E^[I].Sha, Tgt.E^[I].Mode)
      Then Exit;
    End;
  End;
  { index avec informations de fichier }
  WorkF.N := 0;
  For I := 0 To Tgt.N - 1 Do
  Begin
    K := FlatAdd(WorkF, Tgt.E^[I].Path);
    WorkF.E^[K].Sha := Tgt.E^[I].Sha;
    If FileStat(WorkPath(Tgt.E^[I].Path), Sz, Tm) Then
    Begin
      WorkF.E^[K].Size := Sz; WorkF.E^[K].MTime := Tm;
    End;
  End;
  WorkUpdate := IndexFrom(Tgt);
  BigClear;
End;

{ change de commit (branche deja choisie par l'appelant) ; exige un
  dossier de travail propre }
Function CheckoutTo(Const H : TSha) : Boolean;
Var T : TFlat; I : LongInt;
Begin
  CheckoutTo := False;
  For I := 0 To Chg.N - 1 Do
    If (Chg.E^[I].Flag And $FF) <> StNew Then
    Begin
      GitErr := 'des modifications ne sont pas valid'#233'es'; Exit;
    End;
  FlatInit(T);
  If Not CommitFlat(H, T) Then
  Begin
    GitErr := 'commit illisible'; FlatFree(T); Exit;
  End;
  For I := 0 To Chg.N - 1 Do
    If FlatFind(T, Chg.E^[I].Path) >= 0 Then
    Begin
      GitErr := 'le fichier non suivi ' + Chg.E^[I].Path +
        ' serait '#233'cras'#233;
      FlatFree(T); Exit;
    End;
  CheckoutTo := WorkUpdate(HeadF, T);
  FlatCopy(HeadF, T);
  HeadSha := H;
  FlatFree(T);
End;

Function SwitchBranch(Const Name : String) : Boolean;
Var H : TSha;
Begin
  SwitchBranch := False;
  If Not RefRead('refs/heads/' + Name, H) Then
  Begin
    GitErr := 'branche inconnue : ' + Name; Exit;
  End;
  If Not CheckoutTo(H) Then Exit;
  SetHead('refs/heads/' + Name);
  SwitchBranch := True;
End;

{ annule les modifications cochees (retour au contenu de HEAD) }
Function DiscardSel : Boolean;
Var I, St : LongInt;
Begin
  DiscardSel := True;
  For I := 0 To Chg.N - 1 Do
  Begin
    If (Chg.E^[I].Flag And FlSel) = 0 Then Continue;
    St := Chg.E^[I].Flag And $FF;
    If St = StNew Then
    Begin
      FileDel(WorkPath(Chg.E^[I].Path));
      RmEmptyDirs(Chg.E^[I].Path);
    End
    Else If Not WriteWorkFile(Chg.E^[I].Path, Chg.E^[I].Old,
      Chg.E^[I].Mode) Then DiscardSel := False;
  End;
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
      BufStr(R, '<<<<<<< HEAD' + #10);
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
Function BigBlob(Const H : TSha) : Boolean;
Var T, Sz : LongInt;
Begin
  BigBlob := False;
  If ShaIsZero(H) Then Exit;
  If ObjInfo(H, T, Sz) Then BigBlob := Sz > BigObj;
End;

Function BlobLoad(Const H : TSha; Var B : TBuf) : Boolean;
Var T : LongInt;
Begin
  B.N := 0;
  If ShaIsZero(H) Then
  Begin
    BlobLoad := True; Exit;
  End;
  BlobLoad := ReadObject(H, T, B) And (T = OtBlob);
End;

{ fusionne le commit Th dans HEAD ; 0 erreur, 1 deja a jour, 2 avance
  rapide, 3 commit de fusion, 4 conflits }
Function DoMerge(Const Th : TSha; Const Name : String) : LongInt;
Var Base, H : TSha; BF, TF, U, RF : TFlat; I, K, KB, KO, KT : LongInt;
    SB, SO, ST : TSha; MB, MOu, MT : LongInt; XB, XO, XT, R : TBuf;
    Par : Array[0..1] Of TSha; Msg : TBuf; Tree : TSha; Fail : Boolean;
Begin
  DoMerge := 0;
  MergeConf := 0;
  For I := 0 To Chg.N - 1 Do
    If (Chg.E^[I].Flag And $FF) <> StNew Then
    Begin
      GitErr := 'validez ou annulez d''abord vos modifications'; Exit;
    End;
  If ShaEq(Th, HeadSha) Then
  Begin
    DoMerge := 1; Exit;
  End;
  If ShaIsZero(HeadSha) Then Base := ShaZero
  Else If Not MergeBase(HeadSha, Th, Base) Then Base := ShaZero;
  If ShaEq(Base, Th) Then
  Begin
    DoMerge := 1; Exit;
  End;
  FlatInit(TF);
  If Not CommitFlat(Th, TF) Then
  Begin
    GitErr := 'commit illisible'; FlatFree(TF); Exit;
  End;
  If ShaEq(Base, HeadSha) Then
  Begin
    { avance rapide }
    If WorkUpdate(HeadF, TF) And HeadSet(Th) Then DoMerge := 2;
    FlatCopy(HeadF, TF);
    FlatFree(TF); Exit;
  End;
  FlatInit(BF); FlatInit(U); FlatInit(RF);
  If Not CommitFlat(Base, BF) Then BF.N := 0;
  { union des chemins }
  For I := 0 To HeadF.N - 1 Do K := FlatAdd(U, HeadF.E^[I].Path);
  For I := 0 To BF.N - 1 Do
    If FlatFind(HeadF, BF.E^[I].Path) < 0 Then K := FlatAdd(U, BF.E^[I].Path);
  FlatSort(U);
  For I := 0 To TF.N - 1 Do
    If (FlatFind(U, TF.E^[I].Path) < 0) Then K := FlatAdd(U, TF.E^[I].Path);
  FlatSort(U);
  BufInit(XB); BufInit(XO); BufInit(XT); BufInit(R);
  Fail := False;
  For I := 0 To U.N - 1 Do
  Begin
    KB := FlatFind(BF, U.E^[I].Path);
    KO := FlatFind(HeadF, U.E^[I].Path);
    KT := FlatFind(TF, U.E^[I].Path);
    SB := ShaZero; SO := ShaZero; ST := ShaZero;
    MB := $81A4; MOu := $81A4; MT := $81A4;
    If KB >= 0 Then Begin SB := BF.E^[KB].Sha; MB := BF.E^[KB].Mode; End;
    If KO >= 0 Then Begin SO := HeadF.E^[KO].Sha; MOu := HeadF.E^[KO].Mode;
      End;
    If KT >= 0 Then Begin ST := TF.E^[KT].Sha; MT := TF.E^[KT].Mode; End;
    If ShaEq(SO, ST) Or ShaEq(ST, SB) Then
    Begin
      { garde la version locale }
      If KO >= 0 Then
      Begin
        K := FlatAdd(RF, U.E^[I].Path);
        RF.E^[K].Sha := SO; RF.E^[K].Mode := MOu;
      End;
    End
    Else If ShaEq(SO, SB) Then
    Begin
      { prend la version de l'autre branche }
      If KT >= 0 Then
      Begin
        K := FlatAdd(RF, U.E^[I].Path);
        RF.E^[K].Sha := ST; RF.E^[K].Mode := MT;
        If Not WriteWorkFile(U.E^[I].Path, ST, MT) Then
        Begin
          Fail := True; Break;
        End;
      End
      Else
      Begin
        FileDel(WorkPath(U.E^[I].Path));
        RmEmptyDirs(U.E^[I].Path);
      End;
    End
    Else
    Begin
      { modifie des deux cotes }

      { gros fichiers : conflit sans fusion ligne par ligne (la version
        locale est gardee) }
      If BigBlob(SB) Or BigBlob(SO) Or BigBlob(ST) Then
      Begin
        Inc(MergeConf);
        If KO >= 0 Then
        Begin
          K := FlatAdd(RF, U.E^[I].Path);
          RF.E^[K].Sha := SO; RF.E^[K].Mode := MOu;
        End
        Else
        Begin
          K := FlatAdd(RF, U.E^[I].Path);
          RF.E^[K].Sha := ST; RF.E^[K].Mode := MT;
          If Not WriteWorkFile(U.E^[I].Path, ST, MT) Then
          Begin
            Fail := True; Break;
          End;
        End;
      End
      Else If BlobLoad(SB, XB) And BlobLoad(SO, XO) And BlobLoad(ST, XT) Then
      Begin
        If (KO < 0) Or (KT < 0) Then
        Begin
          { supprime d'un cote, modifie de l'autre : conflit }
          Inc(MergeConf);
          If KO < 0 Then BufCopy(R, XT) Else BufCopy(R, XO);
        End
        Else If IsBinary(XO) Or IsBinary(XT) Then
        Begin
          Inc(MergeConf);
          BufCopy(R, XO);
        End
        Else If Not Merge3(XB, XO, XT, R, Name) Then Inc(MergeConf);
        If Not WriteObject(OtBlob, R, H) Then
        Begin
          Fail := True; Break;
        End;
        K := FlatAdd(RF, U.E^[I].Path);
        RF.E^[K].Sha := H; RF.E^[K].Mode := MOu;
        If KO < 0 Then RF.E^[K].Mode := MT;
        If Not FileSave(WorkPath(U.E^[I].Path), R, 0, R.N) Then
        Begin
          MkDirs(ParentOf(WorkPath(U.E^[I].Path)));
          If FileSave(WorkPath(U.E^[I].Path), R, 0, R.N) Then ;
        End;
      End
      Else
      Begin
        Fail := True; Break;
      End;
    End;
  End;
  If Fail Then
  Begin
    GitErr := 'fusion interrompue : ' + U.E^[I].Path;
  End
  Else
  Begin
    BufInit(Msg);
    BufStr(Msg, 'Merge ' + Name + #10);
    FlatSort(RF);
    If MergeConf > 0 Then
    Begin
      If FileSaveStr(GitPath('MERGE_HEAD'), ShaHex(Th) + #10) Then ;
      If FileSave(GitPath('MERGE_MSG'), Msg, 0, Msg.N) Then ;
      If FileSaveStr(GitPath('MERGE_MODE'), '') Then ;
      InMerge := True;
      DoMerge := 4;
    End
    Else If TreeFromFlat(RF, Tree) Then
    Begin
      Par[0] := HeadSha; Par[1] := Th;
      If CommitWrite(Tree, Par, 2, Msg, H) And HeadSet(H) Then
      Begin
        WorkF.N := 0;
        For I := 0 To RF.N - 1 Do
        Begin
          K := FlatAdd(WorkF, RF.E^[I].Path);
          WorkF.E^[K].Sha := RF.E^[I].Sha;
          If FileStat(WorkPath(RF.E^[I].Path), MB, MT) Then
          Begin
            WorkF.E^[K].Size := MB; WorkF.E^[K].MTime := MT;
          End;
        End;
        If IndexFrom(RF) Then ;
        FlatCopy(HeadF, RF);
        DoMerge := 3;
      End;
    End;
    BufFree(Msg);
  End;
  BufFree(XB); BufFree(XO); BufFree(XT); BufFree(R);
  FlatFree(BF); FlatFree(TF); FlatFree(U); FlatFree(RF);
End;

{ ==================================================================== }
{ Historique                                                            }
{ ==================================================================== }

Type
  THist = Record
    Sha : TSha;
    Summary : String[120];
    Author : String[60];
    Time : LongInt;
  End;
  THistArr = Array[0..20000] Of THist;

Var
  Hist : ^THistArr;
  HistN, HistCap : LongInt;

Procedure HistLoad(Const Start : TSha; Max : LongInt);
Var Q : ^TShaSetArr; QT : ^TLongArr; QN, QCap, I, B : LongInt;
    Seen : TShaSet; C : TCommit; X : TSha; K : LongInt;
Begin
  If Hist <> Nil Then FreeMem(Hist, HistCap * SizeOf(THist));
  HistCap := Max;
  GetMem(Hist, HistCap * SizeOf(THist));
  HistN := 0;
  If ShaIsZero(Start) Then Exit;
  QCap := 1024;
  GetMem(Q, QCap * 20); GetMem(QT, QCap * 4);
  SetInit(Seen, 1024);
  QN := 1; Q^[0] := Start; QT^[0] := 0;
  If SetAdd(Seen, Start) Then ;
  While (QN > 0) And (HistN < Max) Do
  Begin
    { le plus recent d'abord }
    B := 0;
    For I := 1 To QN - 1 Do
      If QT^[I] > QT^[B] Then B := I;
    X := Q^[B];
    Dec(QN);
    Q^[B] := Q^[QN]; QT^[B] := QT^[QN];
    If Not CommitRead(X, C, Nil) Then Continue;
    Hist^[HistN].Sha := X;
    Hist^[HistN].Summary := Copy(C.Summary, 1, 120);
    K := Pos(' <', C.Author);
    If K > 0 Then Hist^[HistN].Author := Copy(C.Author, 1, MinL(K - 1, 60))
    Else Hist^[HistN].Author := Copy(C.Author, 1, 60);
    Hist^[HistN].Time := C.CTime;
    Inc(HistN);
    For I := 0 To C.PN - 1 Do
      If SetAdd(Seen, C.Parent[I]) And (QN < QCap) Then
      Begin
        Q^[QN] := C.Parent[I];
        QT^[QN] := C.CTime;            { approximation : date de l'enfant }
        Inc(QN);
      End;
  End;
  FreeMem(Q, QCap * 20); FreeMem(QT, QCap * 4);
  SetFree(Seen);
End;

{ fichiers modifies par le commit H (par rapport a son premier parent) }
Function CommitChanges(Const H : TSha; Var Out : TFlat) : Boolean;
Var C : TCommit; A, B : TFlat; I, K : LongInt;
Begin
  CommitChanges := False;
  Out.N := 0;
  If Not CommitRead(H, C, Nil) Then Exit;
  FlatInit(A); FlatInit(B);
  If C.PN > 0 Then
    If Not CommitFlat(C.Parent[0], A) Then A.N := 0;
  If Not TreeFlat(C.Tree, '', B) Then B.N := 0;
  FlatSort(B);
  For I := 0 To B.N - 1 Do
  Begin
    K := FlatFind(A, B.E^[I].Path);
    If K < 0 Then
    Begin
      K := FlatAdd(Out, B.E^[I].Path);
      Out.E^[K].Flag := StNew; Out.E^[K].Sha := B.E^[I].Sha;
    End
    Else If Not ShaEq(A.E^[K].Sha, B.E^[I].Sha) Then
    Begin
      K := FlatAdd(Out, B.E^[I].Path);
      Out.E^[K].Flag := StMod; Out.E^[K].Sha := B.E^[I].Sha;
      Out.E^[K].Old := A.E^[FlatFind(A, B.E^[I].Path)].Sha;
    End;
  End;
  For I := 0 To A.N - 1 Do
    If FlatFind(B, A.E^[I].Path) < 0 Then
    Begin
      K := FlatAdd(Out, A.E^[I].Path);
      Out.E^[K].Flag := StDel; Out.E^[K].Old := A.E^[I].Sha;
    End;
  FlatSort(Out);
  FlatFree(A); FlatFree(B);
  CommitChanges := True;
End;
{ ==================================================================== }
{ Transport (implante plus bas : TCPIP32, TLS32)                       }
{ ==================================================================== }

{ requete HTTP(S) ; Hdr : en-tetes supplementaires separes par #13#10 }
Function HttpReq(Const Method, Url, Hdr : String; Var Body, Resp : TBuf;
  Var Status : LongInt) : Boolean; Forward;
Function TcpOpen(Const Host : String; Port : LongInt) : LongInt; Forward;
Function TcpSend(H : LongInt; Var B : TBuf; Ofs, N : LongInt) : Boolean;
  Forward;
{ ajoute a B ce qui est recu ; 0 : connexion fermee, -1 : erreur }
Function TcpRecv(H : LongInt; Var B : TBuf) : LongInt; Forward;
Procedure TcpClose(H : LongInt); Forward;

{ ==================================================================== }
{ Base64, URL, pkt-line                                                 }
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

Var
  UrlScheme, UrlHost, UrlPath : String;
  UrlPort : LongInt;

{ decoupe http[s]://hote[:port]/chemin ou git://hote[:port]/chemin }
Function UrlSplit(U : String) : Boolean;
Var K, E : LongInt;
Begin
  UrlSplit := False;
  K := Pos('://', U);
  If K = 0 Then Exit;
  UrlScheme := LowStr(Copy(U, 1, K - 1));
  Delete(U, 1, K + 2);
  K := Pos('@', U);
  If (K > 0) And (K < Pos('/', U)) Then Delete(U, 1, K);
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
  Else If UrlScheme = 'git' Then UrlPort := 9418
  Else UrlPort := 80;
  K := Pos(':', UrlHost);
  If K > 0 Then
  Begin
    Val(Copy(UrlHost, K + 1, 10), UrlPort, E);
    UrlHost := Copy(UrlHost, 1, K - 1);
  End;
  UrlSplit := (UrlHost <> '') And ((UrlScheme = 'http') Or
    (UrlScheme = 'https') Or (UrlScheme = 'git'));
End;

Procedure PktStr(Var B : TBuf; Const S : String);
Var L : LongInt;
Begin
  L := Length(S) + 4;
  BufStr(B, HexB(L Shr 8) + HexB(L And 255));
  BufStr(B, S);
End;

{ ligne pkt « A NUL C » (OS2PC et WPC perdent #0 dans les concatenations) ;
  Nul2 : NUL final }
Procedure PktStr0(Var B : TBuf; Const A, C : String; Nul2 : Boolean);
Var L : LongInt;
Begin
  L := Length(A) + 1 + Length(C) + 4;
  If Nul2 Then Inc(L);
  BufStr(B, HexB(L Shr 8) + HexB(L And 255));
  BufStr(B, A);
  BufByte(B, 0);
  BufStr(B, C);
  If Nul2 Then BufByte(B, 0);
End;

Procedure PktFlush(Var B : TBuf);
Begin
  BufStr(B, '0000');
End;

{ ligne pkt a Pp : Ofs/Len du contenu (Len = -1 : vidage) ; faux si
  la ligne est incomplete }
Function PktNext(Var B : TBuf; Var Pp, Ofs, Len : LongInt) : Boolean;
Var I, V : LongInt;
Begin
  PktNext := False;
  If Pp + 4 > B.N Then Exit;
  V := 0;
  For I := 0 To 3 Do V := V * 16 + HexVal(Chr(B.P^[Pp + I]));
  If V < 4 Then
  Begin
    Ofs := Pp + 4; Len := -1; Inc(Pp, 4);
    PktNext := True; Exit;
  End;
  If Pp + V > B.N Then Exit;
  Ofs := Pp + 4; Len := V - 4;
  Inc(Pp, V);
  { retire le saut de ligne final }
  If (Len > 0) And (B.P^[Ofs + Len - 1] = 10) Then Dec(Len);
  PktNext := True;
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

{ ==================================================================== }
{ Session distante                                                      }
{ ==================================================================== }

Var
  RemUrl : String;                     { URL du depot distant }
  RemUser, RemPass : String;           { authentification HTTP }
  RemRefs : TRefs;                     { references annoncees }
  RemHead : String;                    { branche par defaut distante }
  RemSock : LongInt;
  RemCaps : String;                    { capacites utiles }
  AgentName : String;
  LocRefs : TRefs;

Function AuthHdr : String;
Begin
  If (RemUser = '') And (RemPass = '') Then AuthHdr := ''
  Else AuthHdr := 'Authorization: Basic ' + Base64(RemUser + ':' + RemPass)
    + #13#10;
End;

Function HttpErr(St : LongInt) : String;
Begin
  Case St Of
    401 : HttpErr := 'authentification requise ou refus'#233'e (401)';
    403 : HttpErr := 'acc'#232's refus'#233' (403)';
    404 : HttpErr := 'd'#233'p'#244't introuvable (404)';
    Else HttpErr := 'erreur HTTP ' + IStr(St);
  End;
End;

{ analyse l'annonce des references a partir de Pp }
Function ParseAdvert(Var B : TBuf; Pp : LongInt) : Boolean;
Var Ofs, Len, K, E : LongInt; H : TSha; Nm : String; First : Boolean;
Begin
  ParseAdvert := False;
  RemRefs.N := 0; RemHead := ''; RemCaps := '';
  First := True;
  While PktNext(B, Pp, Ofs, Len) Do
  Begin
    If Len < 0 Then
    Begin
      ParseAdvert := True; Exit;
    End;
    If (Len >= 4) And (BufStrAt(B, Ofs, 4) = 'ERR ') Then
    Begin
      GitErr := 'serveur : ' + BufStrAt(B, Ofs + 4, MinL(Len - 4, 200));
      Exit;
    End;
    If Len < 41 Then Continue;
    If Not ShaParse(BufStrAt(B, Ofs, 40), H) Then Continue;
    E := Ofs + Len;
    K := Ofs + 41;
    While (K < E) And (B.P^[K] <> 0) Do Inc(K);
    Nm := BufStrAt(B, Ofs + 41, MinL(K - Ofs - 41, 200));
    If First Then
    Begin
      First := False;
      If K < E Then
      Begin
        If BufFind(B, K, E - K, ' ofs-delta') >= 0 Then
          RemCaps := RemCaps + ' ofs-delta';
        If BufFind(B, K, E - K, 'report-status') >= 0 Then
          RemCaps := RemCaps + ' report-status';
        Len := BufFind(B, K, E - K, 'symref=HEAD:');
        If Len >= 0 Then
        Begin
          Len := Len + 12;
          Ofs := Len;
          While (Ofs < E) And (B.P^[Ofs] <> 32) Do Inc(Ofs);
          RemHead := BufStrAt(B, Len, Ofs - Len);
        End;
      End;
      If Nm = 'capabilities^{}' Then Continue;
    End;
    If (Copy(Nm, 1, 11) = 'refs/heads/') Or
       ((Copy(Nm, 1, 10) = 'refs/tags/') And (Pos('^{}', Nm) = 0)) Then
      RefsAdd(RemRefs, Nm, H)
    Else If (Nm = 'HEAD') And (RemHead = '') Then
      RefsAdd(RemRefs, Nm, H);
  End;
  GitErr := 'annonce des r'#233'f'#233'rences tronqu'#233'e';
End;

Procedure RemClose;
Begin
  If RemSock > 0 Then TcpClose(RemSock);
  RemSock := 0;
End;

{ lit sur la socket jusqu'a un paquet de vidage (annonce) }
Function SockAdvert(Var B : TBuf) : Boolean;
Var P, O, L, R : LongInt; Done : Boolean;
Begin
  SockAdvert := False;
  B.N := 0;
  Repeat
    P := 0; Done := False;
    While PktNext(B, P, O, L) Do
      If L < 0 Then
      Begin
        Done := True; Break;
      End;
    If Done Then Break;
    R := TcpRecv(RemSock, B);
    If R <= 0 Then
    Begin
      If B.N = 0 Then GitErr := 'le serveur a ferm'#233' la connexion'
      Else Done := True;
      If Not Done Then Exit;
      Break;
    End;
  Until False;
  SockAdvert := True;
End;

{ decouvre les references ; Service = git-upload-pack ou
  git-receive-pack ; garde la connexion git:// ouverte }
Function RemDiscover(Const Service : String) : Boolean;
Var B, E : TBuf; St, Pp, Ofs, Len : LongInt; U : String;
Begin
  RemDiscover := False;
  RemClose;
  If Not UrlSplit(RemUrl) Then
  Begin
    GitErr := 'URL non prise en charge : ' + RemUrl; Exit;
  End;
  BufInit(B); BufInit(E);
  If UrlScheme = 'git' Then
  Begin
    GitProgress('Connexion '#224' ' + UrlHost, 0, 0);
    RemSock := TcpOpen(UrlHost, UrlPort);
    If RemSock <= 0 Then
    Begin
      RemSock := 0;
      GitErr := 'connexion impossible '#224' ' + UrlHost; BufFree(B); Exit;
    End;
    E.N := 0;
    PktStr0(E, Service + ' ' + UrlPath, 'host=' + UrlHost, True);
    If Not TcpSend(RemSock, E, 0, E.N) Or Not SockAdvert(B) Then
    Begin
      If GitErr = '' Then GitErr := ''#233'chec de l''envoi';
      RemClose; BufFree(B); BufFree(E); Exit;
    End;
    RemDiscover := ParseAdvert(B, 0);
  End
  Else
  Begin
    U := RemUrl;
    If (U <> '') And (U[Length(U)] = '/') Then Delete(U, Length(U), 1);
    GitProgress('Connexion '#224' ' + UrlHost, 0, 0);
    If Not HttpReq('GET', U + '/info/refs?service=' + Service,
      AuthHdr, E, B, St) Then
    Begin
      If GitErr = '' Then GitErr := 'connexion impossible '#224' ' + UrlHost;
      BufFree(B); BufFree(E); Exit;
    End;
    If St <> 200 Then
    Begin
      GitErr := HttpErr(St); BufFree(B); BufFree(E); Exit;
    End;
    Pp := 0;
    If Not PktNext(B, Pp, Ofs, Len) Or (Len < 0) Or
       (BufFind(B, Ofs, Len, '# service=') <> Ofs) Then
    Begin
      GitErr := 'le serveur ne parle pas le protocole Git intelligent';
      BufFree(B); BufFree(E); Exit;
    End;
    { vidage apres la ligne de service }
    Len := -1;
    If Not PktNext(B, Pp, Ofs, Len) Then Pp := B.N;
    If Len >= 0 Then Pp := Ofs - 4;
    RemDiscover := ParseAdvert(B, Pp);
  End;
  BufFree(B); BufFree(E);
End;

{ reception du pack directement dans un fichier (RecvOn) : les lignes
  ACK/NAK du debut sont lues, puis tout est ecrit a partir de 'PACK' ; le
  tampon de reception reste petit, quelle que soit la taille du pack }
Var
  RecvOn, RecvStarted : Boolean;
  RecvH, RecvTot, RecvLast : LongInt;
  RecvErr : String;

Procedure RecvFeed(Var B : TBuf);
Var Pp, P2, Ofs, Len : LongInt;
Begin
  If Not RecvOn Then Exit;
  RecvTot := RecvTot + B.N;
  If RecvTot - RecvLast >= 65536 Then
  Begin
    GitProgress('R'#233'ception des objets', RecvTot, 0);
    RecvLast := RecvTot;
  End;
  If Not RecvStarted Then
  Begin
    Pp := 0;
    Repeat
      If (Pp + 4 <= B.N) And (BufStrAt(B, Pp, 4) = 'PACK') Then
      Begin
        RecvStarted := True;
        Break;
      End;
      P2 := Pp;
      If (Pp + 4 > B.N) Or Not PktNext(B, P2, Ofs, Len) Then Break;
      If (Len >= 4) And (BufStrAt(B, Ofs, 4) = 'ERR ') Then
        RecvErr := 'serveur : ' + BufStrAt(B, Ofs + 4, MinL(Len - 4, 200));
      Pp := P2;
    Until False;
    { garde la ligne incomplete pour la suite }
    If Pp > 0 Then
    Begin
      Move(B.P^[Pp], B.P^[0], B.N - Pp);
      B.N := B.N - Pp;
    End;
    If Not RecvStarted Then Exit;
  End;
  If B.N > 0 Then
    If Not FWrite(RecvH, B.P, B.N) Then
      RecvErr := ''#233'criture du pack impossible (disque plein ?)';
  B.N := 0;
End;

{ envoie la requete Req et recoit toute la reponse }
Function RemRpc(Const Service : String; Var Req, Resp : TBuf) : Boolean;
Var St, R, Last : LongInt; U : String; E : TBuf;
Begin
  RemRpc := False;
  Resp.N := 0;
  If UrlScheme = 'git' Then
  Begin
    If Not TcpSend(RemSock, Req, 0, Req.N) Then
    Begin
      GitErr := ''#233'chec de l''envoi'; RemClose; Exit;
    End;
    Last := 0;
    Repeat
      R := TcpRecv(RemSock, Resp);
      If RecvOn Then RecvFeed(Resp)
      Else If Resp.N - Last >= 65536 Then
      Begin
        GitProgress('R'#233'ception', Resp.N, 0);
        Last := Resp.N;
      End;
    Until (R <= 0) Or GitOom;
    RemClose;
    RemRpc := R = 0;
    If R < 0 Then GitErr := 'erreur de r'#233'ception';
  End
  Else
  Begin
    U := RemUrl;
    If (U <> '') And (U[Length(U)] = '/') Then Delete(U, Length(U), 1);
    If Not HttpReq('POST', U + '/' + Service, AuthHdr +
      'Content-Type: application/x-' + Service + '-request' + #13#10 +
      'Accept: application/x-' + Service + '-result' + #13#10,
      Req, Resp, St) Then
    Begin
      If GitErr = '' Then GitErr := 'connexion impossible';
      Exit;
    End;
    If St <> 200 Then
    Begin
      GitErr := HttpErr(St); Exit;
    End;
    RemRpc := True;
  End;
End;

{ ==================================================================== }
{ Recuperation (fetch / clone)                                          }
{ ==================================================================== }

{ ajoute les commits recents de H (au plus Max) a la liste des « have » }
Procedure AddHaves(Var Req : TBuf; Const H : TSha; Var Seen : TShaSet;
  Var Cnt : LongInt; Max : LongInt);
Var C : TCommit; X : TSha; Q : Array[0..63] Of TSha; QN, I : LongInt;
Begin
  QN := 1; Q[0] := H;
  While (QN > 0) And (Cnt < Max) Do
  Begin
    Dec(QN);
    X := Q[QN];
    If ShaIsZero(X) Or Not SetAdd(Seen, X) Then Continue;
    If Not HasObject(X) Then Continue;
    PktStr(Req, 'have ' + ShaHex(X) + #10);
    Inc(Cnt);
    If CommitRead(X, C, Nil) Then
      For I := C.PN - 1 DownTo 0 Do
        If QN < 64 Then
        Begin
          Q[QN] := C.Parent[I]; Inc(QN);
        End;
  End;
End;

{ recupere les branches distantes dans refs/remotes/<Remote>/ }
Function DoFetch(Const Remote : String) : Boolean;
Var Req, Resp : TBuf; I, Pp, Ofs, Len, Cnt, Wants : LongInt;
    Seen : TShaSet; Nm : String; First, Ok : Boolean;
Begin
  GitOom := False;
  DoFetch := False;
  If Not RemDiscover('git-upload-pack') Then Exit;
  BufInit(Req); BufInit(Resp);
  First := True; Wants := 0;
  SetInit(Seen, 256);
  For I := 0 To RemRefs.N - 1 Do
    If (RemRefs.Name[I] <> 'HEAD') And Not HasObject(RemRefs.Sha[I]) And
       SetAdd(Seen, RemRefs.Sha[I]) Then
    Begin
      If First Then
      Begin
        PktStr(Req, 'want ' + ShaHex(RemRefs.Sha[I]) + Copy(RemCaps,
          Pos(' ofs', RemCaps), 10) + ' agent=' + AgentName + #10);
        First := False;
      End
      Else PktStr(Req, 'want ' + ShaHex(RemRefs.Sha[I]) + #10);
      Inc(Wants);
    End;
  SetFree(Seen);
  If Wants > 0 Then
  Begin
    PktFlush(Req);
    { « have » : branches locales et distantes connues }
    SetInit(Seen, 1024);
    Cnt := 0;
    RefsList(LocRefs, 'refs/');
    For I := 0 To LocRefs.N - 1 Do
      AddHaves(Req, LocRefs.Sha[I], Seen, Cnt, 256);
    SetFree(Seen);
    PktStr(Req, 'done' + #10);
    GitProgress('N'#233'gociation', 0, 0);
    { le pack est recu dans un fichier, puis indexe depuis le disque }
    Nm := TmpPath('recv.pack');
    RecvH := FCreate(Nm);
    If RecvH < 0 Then
    Begin
      GitErr := 'cr'#233'ation de ' + Nm + ' impossible';
      BufFree(Req); BufFree(Resp); Exit;
    End;
    RecvOn := True; RecvStarted := False; RecvErr := '';
    RecvTot := 0; RecvLast := 0;
    Ok := RemRpc('git-upload-pack', Req, Resp);
    RecvOn := False;
    FClose(RecvH);
    If Ok And (RecvErr <> '') Then
    Begin
      GitErr := RecvErr; Ok := False;
    End;
    If Ok And Not RecvStarted Then
    Begin
      GitErr := 'pas de pack dans la r'#233'ponse du serveur'; Ok := False;
    End;
    If Ok And GitOom Then Ok := False;
    If Ok Then Ok := IndexPackFile(Nm);
    FileDel(Nm);
    If Not Ok Then
    Begin
      BufFree(Req); BufFree(Resp); Exit;
    End;
  End;
  { met a jour les references de suivi }
  For I := 0 To RemRefs.N - 1 Do
  Begin
    Nm := RemRefs.Name[I];
    If Copy(Nm, 1, 11) = 'refs/heads/' Then
    Begin
      If Not RefWrite('refs/remotes/' + Remote + '/' + Copy(Nm, 12, 255),
        RemRefs.Sha[I]) Then ;
    End
    Else If (Copy(Nm, 1, 10) = 'refs/tags/') And HasObject(RemRefs.Sha[I])
    Then
      If Not FileExist(GitPath(Nm)) Then
        If RefWrite(Nm, RemRefs.Sha[I]) Then ;
  End;
  { branches distantes supprimees }
  RefsList(LocRefs, 'refs/remotes/' + Remote + '/');
  For I := 0 To LocRefs.N - 1 Do
  Begin
    Nm := 'refs/heads/' + Copy(LocRefs.Name[I], Length(Remote) + 15, 255);
    If Nm = 'refs/heads/HEAD' Then Continue;
    First := False;
    For Cnt := 0 To RemRefs.N - 1 Do
      If RemRefs.Name[Cnt] = Nm Then First := True;
    If Not First Then RefDelete(LocRefs.Name[I]);
  End;
  If RemHead <> '' Then
    If FileSaveStr(GitPath('refs/remotes/' + Remote + '/HEAD'),
      'ref: refs/remotes/' + Remote + '/' + Copy(RemHead, 12, 255) + #10)
    Then ;
  BufFree(Req); BufFree(Resp);
  PacksScan;
  DoFetch := True;
End;

{ ==================================================================== }
{ Envoi (push)                                                          }
{ ==================================================================== }

Type
  TShaList = Record
    H : ^TShaSetArr;
    N, Cap : LongInt;
  End;

Procedure ListAdd(Var L : TShaList; Const H : TSha);
Var Q : ^TShaSetArr; C : LongInt;
Begin
  If L.N >= L.Cap Then
  Begin
    C := L.Cap * 2;
    If C < 256 Then C := 256;
    GetMem(Q, C * 20);
    If L.N > 0 Then Move(L.H^[0], Q^[0], L.N * 20);
    If L.H <> Nil Then FreeMem(L.H, L.Cap * 20);
    L.H := Q; L.Cap := C;
  End;
  L.H^[L.N] := H;
  Inc(L.N);
End;

Procedure ListFree(Var L : TShaList);
Begin
  If L.H <> Nil Then FreeMem(L.H, L.Cap * 20);
  L.H := Nil; L.N := 0; L.Cap := 0;
End;

{ objets de l'arbre H : dans Excl (Add = Faux) ou a envoyer (Add = Vrai)
  s'ils ne sont ni exclus ni deja ajoutes }
Procedure TreeObjs(Const H : TSha; Var Excl, Added : TShaSet;
  Var L : TShaList; Add : Boolean);
Var D : TBuf; T, P, Q : LongInt; S : TSha; Md : String;
Begin
  If Add Then
  Begin
    If SetHas(Excl, H) Or Not SetAdd(Added, H) Then Exit;
    ListAdd(L, H);
  End
  Else If Not SetAdd(Excl, H) Then Exit;
  BufInit(D);
  If ReadObject(H, T, D) And (T = OtTree) Then
  Begin
    P := 0;
    While P < D.N Do
    Begin
      Q := P;
      While (Q < D.N) And (D.P^[Q] <> 32) Do Inc(Q);
      Md := BufStrAt(D, P, Q - P);
      While (Q < D.N) And (D.P^[Q] <> 0) Do Inc(Q);
      ShaFrom(D, Q + 1, S);
      P := Q + 21;
      If Md = '160000' Then Continue;
      If Md = '40000' Then TreeObjs(S, Excl, Added, L, Add)
      Else If Add Then
      Begin
        If Not SetHas(Excl, S) And SetAdd(Added, S) Then ListAdd(L, S);
      End
      Else If SetAdd(Excl, S) Then ;
    End;
  End;
  BufFree(D);
End;

Var
  PushMsg : String;                    { compte rendu du serveur }

{ envoie la branche locale Branch vers Remote ; Force : sans verifier
  l'avance rapide }
Function DoPush(Const Remote, Branch : String; Force : Boolean) : Boolean;
Var Local, Old, X : TSha; Known, Excl, Added : TShaSet; L : TShaList;
    Q : TShaList; I, J, T, Pp, Ofs, Len, Sz : LongInt; C : TCommit;
    Req, Resp, D, Pk : TBuf; Ref, S, Fn : String; Ok : Boolean;
Begin
  DoPush := False;
  PushMsg := '';
  Ref := 'refs/heads/' + Branch;
  If Not RefRead(Ref, Local) Then
  Begin
    GitErr := 'la branche ' + Branch + ' n''a aucun commit'; Exit;
  End;
  If Not RemDiscover('git-receive-pack') Then Exit;
  Old := ShaZero;
  For I := 0 To RemRefs.N - 1 Do
    If RemRefs.Name[I] = Ref Then Old := RemRefs.Sha[I];
  If ShaEq(Old, Local) Then
  Begin
    RemClose;
    PushMsg := 'deja a jour';
    DoPush := True; Exit;
  End;
  SetInit(Known, 4096);
  For I := 0 To RemRefs.N - 1 Do
    If HasObject(RemRefs.Sha[I]) Then Ancestors(RemRefs.Sha[I], Known);
  If Not ShaIsZero(Old) And Not Force Then
  Begin
    If Not HasObject(Old) Or Not SetHas(Known, Old) Then
    Begin
      GitErr := 'le d'#233'p'#244't distant contient des commits absents : ' +
        'tirez (pull) d''abord';
      SetFree(Known); RemClose; Exit;
    End;
    SetInit(Excl, 1024);
    Ancestors(Local, Excl);
    Ok := SetHas(Excl, Old);
    SetFree(Excl);
    If Not Ok Then
    Begin
      GitErr := 'envoi refus'#233' : ce n''est pas une avance rapide, ' +
        'tirez (pull) d''abord';
      SetFree(Known); RemClose; Exit;
    End;
  End;
  { nouveaux commits et frontiere }
  SetInit(Excl, 4096); SetInit(Added, 4096);
  FillChar(L, SizeOf(L), 0); FillChar(Q, SizeOf(Q), 0);
  ListAdd(Q, Local);
  I := 0;
  While I < Q.N Do
  Begin
    X := Q.H^[I]; Inc(I);
    If SetHas(Known, X) Or Not SetAdd(Added, X) Then Continue;
    ListAdd(L, X);
    If CommitRead(X, C, Nil) Then
      For J := 0 To C.PN - 1 Do
        If SetHas(Known, C.Parent[J]) Then
        Begin
          If CommitRead(C.Parent[J], C, Nil) Then
            TreeObjs(C.Tree, Excl, Added, L, False);
          If CommitRead(X, C, Nil) Then ;
        End
        Else ListAdd(Q, C.Parent[J]);
  End;
  { arbres et fichiers des nouveaux commits }
  J := L.N;
  For I := 0 To J - 1 Do
    If CommitRead(L.H^[I], C, Nil) Then
      TreeObjs(C.Tree, Excl, Added, L, True);
  SetFree(Known); SetFree(Excl); SetFree(Added); ListFree(Q);
  { pack }
  BufInit(Req); BufInit(Resp); BufInit(D); BufInit(Pk);
  PackBegin(Pk, L.N);
  Ok := True;
  For I := 0 To L.N - 1 Do
  Begin
    If (I And 15) = 0 Then GitProgress('Compression des objets', I, L.N);
    If Not ObjGet(L.H^[I], T, Sz, D, Fn) Then
    Begin
      GitErr := 'objet manquant ' + ShaHex(L.H^[I]); Ok := False; Break;
    End;
    If Fn <> '' Then Ok := PackAddFile(Pk, T, Fn)
    Else PackAdd(Pk, T, D);
    If GitOom Then
    Begin
      GitErr := 'm'#233'moire insuffisante pour envoyer les objets';
      Ok := False;
    End;
    If Not Ok Then Break;
  End;
  ListFree(L);
  If Ok Then
  Begin
    PackEnd(Pk);
    PktStr0(Req, ShaHex(Old) + ' ' + ShaHex(Local) + ' ' + Ref,
      'report-status agent=' + AgentName + #10, False);
    PktFlush(Req);
    BufAppend(Req, Pk, 0, Pk.N);
    GitProgress('Envoi des objets', 0, 0);
    Ok := RemRpc('git-receive-pack', Req, Resp);
  End;
  If Ok Then
  Begin
    Ok := False;
    Pp := 0;
    While PktNext(Resp, Pp, Ofs, Len) Do
    Begin
      If Len < 0 Then Break;
      S := BufStrAt(Resp, Ofs, MinL(Len, 200));
      If S = 'unpack ok' Then Continue;
      If Copy(S, 1, 7) = 'unpack ' Then PushMsg := S
      Else If Copy(S, 1, 3) = 'ok ' Then Ok := True
      Else If Copy(S, 1, 3) = 'ng ' Then
        PushMsg := Copy(S, 4 + Length(Ref) + 1, 200)
      Else If Copy(S, 1, 4) = 'ERR ' Then PushMsg := Copy(S, 5, 200);
    End;
    If Not Ok Then
    Begin
      If PushMsg = '' Then PushMsg := 'reponse du serveur invalide';
      GitErr := 'refus du serveur : ' + PushMsg;
    End
    Else If RefWrite('refs/remotes/' + Remote + '/' + Branch, Local) Then ;
  End;
  BufFree(Req); BufFree(Resp); BufFree(D); BufFree(Pk);
  RemClose;
  DoPush := Ok;
End;

{ ==================================================================== }
{ Creation, clonage                                                     }
{ ==================================================================== }

Function SetRepo(Const Dir : String) : Boolean;
Begin
  WorkDir := Dir;
  If (WorkDir <> '') And (WorkDir[Length(WorkDir)] = PS) Then
    Delete(WorkDir, Length(WorkDir), 1);
  GitDir := WorkDir + PS + '.git';
  PacksRead := False;
  PackN := 0;
  SetRepo := DirExist(GitDir) And FileExist(GitPath('HEAD'));
End;

Function InitRepo(Const Dir, Branch : String) : Boolean;
Begin
  InitRepo := False;
  MkDirs(Dir);
  If SetRepo(Dir) Then
  Begin
    GitErr := 'ce dossier contient d'#233'j'#224' un d'#233'p'#244't Git'; Exit;
  End;
  MkDirs(GitPath('objects/pack'));
  MkDirs(GitPath('objects/info'));
  MkDirs(GitPath('refs/heads'));
  MkDirs(GitPath('refs/tags'));
  MkDirs(GitPath('info'));
  If Not FileSaveStr(GitPath('config'), '[core]' + #10 +
    #9'repositoryformatversion = 0' + #10 + #9'filemode = false' + #10 +
    #9'bare = false' + #10 + #9'logallrefupdates = true' + #10 +
    #9'symlinks = false' + #10 + #9'ignorecase = true' + #10) Then
  Begin
    GitErr := ''#233'criture impossible dans ' + Dir; Exit;
  End;
  If FileSaveStr(GitPath('description'), 'Unnamed repository' + #10) Then;
  SetHead('refs/heads/' + Branch);
  InitRepo := True;
End;

Procedure SetRemote(Const Name, Url : String);
Begin
  CfgSet('remote', Name, 'url', Url);
  CfgSet('remote', Name, 'fetch', '+refs/heads/*:refs/remotes/' + Name +
    '/*');
End;

Procedure SetUpstream(Const Branch, Remote : String);
Begin
  CfgSet('branch', Branch, 'remote', Remote);
  CfgSet('branch', Branch, 'merge', 'refs/heads/' + Branch);
End;

Function DoClone(Const Url, Dir : String) : Boolean;
Var B : String; H : TSha; I : LongInt; T : TFlat;
Begin
  DoClone := False;
  If Not InitRepo(Dir, 'main') Then Exit;
  SetRemote('origin', Url);
  RemUrl := Url;
  If Not DoFetch('origin') Then Exit;
  B := RemHead;
  If B = '' Then
    For I := 0 To RemRefs.N - 1 Do
      If (RemRefs.Name[I] = 'refs/heads/main') Or
         ((B = '') And (RemRefs.Name[I] = 'refs/heads/master')) Then
        B := RemRefs.Name[I];
  If B = '' Then
    For I := 0 To RemRefs.N - 1 Do
      If (B = '') And (Copy(RemRefs.Name[I], 1, 11) = 'refs/heads/') Then
        B := RemRefs.Name[I];
  If B = '' Then
  Begin
    { depot distant vide }
    DoClone := True; Exit;
  End;
  Delete(B, 1, 11);
  SetHead('refs/heads/' + B);
  If Not RefRead('refs/remotes/origin/' + B, H) Then
  Begin
    GitErr := 'branche distante introuvable'; Exit;
  End;
  If Not RefWrite('refs/heads/' + B, H) Then Exit;
  SetUpstream(B, 'origin');
  HeadSha := H;
  FlatInit(T);
  HeadF.N := 0; Chg.N := 0;
  If CommitFlat(H, T) Then DoClone := WorkUpdate(HeadF, T);
  FlatCopy(HeadF, T);
  FlatFree(T);
End;

{ ==================================================================== }
{ API GitHub (JSON)                                                     }
{ ==================================================================== }

Const
  JkStr = 1;
  JkLit = 2;
  JkSym = 3;

{ jeton JSON suivant : chaine (decodee), litteral ou symbole }
Function JsonNext(Var B : TBuf; Var P : LongInt; Var S : String) : LongInt;
Var C, K, V : LongInt;
Begin
  JsonNext := 0;
  S := '';
  While (P < B.N) And (B.P^[P] <= 32) Do Inc(P);
  If P >= B.N Then Exit;
  C := B.P^[P];
  If C = 34 Then
  Begin
    Inc(P);
    While (P < B.N) And (B.P^[P] <> 34) Do
    Begin
      C := B.P^[P];
      If (C = 92) And (P + 1 < B.N) Then
      Begin
        Inc(P);
        C := B.P^[P];
        Case Chr(C) Of
          'n' : C := 32;
          't' : C := 32;
          'r' : C := 32;
          'b', 'f' : C := 32;
          'u' :
          Begin
            V := 0;
            For K := 1 To 4 Do
              If P + K < B.N Then V := V * 16 + HexVal(Chr(B.P^[P + K]));
            Inc(P, 4);
            Case V Of
              $E9 : C := 130; $E8 : C := 138; $EA : C := 136;
              $E0 : C := 133; $E7 : C := 135; $F4 : C := 147;
              $EE : C := 140; $FB : C := 150; $F9 : C := 151;
              $C9 : C := 144;
              Else If V < 128 Then C := V Else C := Ord('?');
            End;
          End;
        End;
      End
      Else If C >= 128 Then
      Begin
        { UTF-8 : lettres accentuees courantes }
        If (C = $C3) And (P + 1 < B.N) Then
        Begin
          Inc(P);
          Case B.P^[P] Of
            $A9 : C := 130; $A8 : C := 138; $AA : C := 136; $A0 : C := 133;
            $A7 : C := 135; $B4 : C := 147; $AE : C := 140; $BB : C := 150;
            $B9 : C := 151; $89 : C := 144;
            Else C := Ord('?');
          End;
        End
        Else
        Begin
          While (P + 1 < B.N) And (B.P^[P + 1] >= 128) And
            (B.P^[P + 1] < 192) Do Inc(P);
          C := Ord('?');
        End;
      End;
      If Length(S) < 250 Then S := S + Chr(C);
      Inc(P);
    End;
    Inc(P);
    JsonNext := JkStr;
  End
  Else If Chr(C) In ['{', '}', '[', ']', ':', ','] Then
  Begin
    S := Chr(C); Inc(P);
    JsonNext := JkSym;
  End
  Else
  Begin
    While (P < B.N) And Not (Chr(B.P^[P]) In [',', '}', ']', ' ', #10, #13,
      #9]) Do
    Begin
      If Length(S) < 250 Then S := S + Chr(B.P^[P]);
      Inc(P);
    End;
    JsonNext := JkLit;
  End;
End;

{ premiere valeur de Key a la profondeur Depth (1 : objet racine) ;
  resultat affecte une seule fois (anneau de chaines d'OS2PC et de WPC) }
Function JsonGet(Var B : TBuf; Const Key : String; Depth : LongInt)
  : String;
Var P, K, D : LongInt; S, R : String; IsKey, Done : Boolean;
Begin
  R := '';
  P := 0; D := 0; Done := False;
  Repeat
    K := JsonNext(B, P, S);
    If K = 0 Then Done := True
    Else If K = JkSym Then
    Begin
      If (S = '{') Or (S = '[') Then Inc(D)
      Else If (S = '}') Or (S = ']') Then Dec(D);
    End
    Else
    Begin
      { une chaine suivie de ':' est une cle }
      While (P < B.N) And (B.P^[P] <= 32) Do Inc(P);
      IsKey := (K = JkStr) And (P < B.N) And (B.P^[P] = Ord(':'));
      If IsKey Then
      Begin
        Inc(P);
        If (D = Depth) And (S = Key) Then
        Begin
          K := JsonNext(B, P, S);
          If K <> JkSym Then R := S;
          Done := True;
        End;
      End;
    End;
  Until Done;
  JsonGet := R;
End;

Const
  MaxGh = 300;

Var
  GhLogin, GhToken : String;
  GhN : LongInt;
  GhName : Array[0..MaxGh - 1] Of String[100];
  GhUrl : Array[0..MaxGh - 1] Of String[160];
  GhPriv : Array[0..MaxGh - 1] Of Boolean;
  GhDesc : Array[0..MaxGh - 1] Of String[100];

Function GhApi(Const Method, Path : String; Var Body, Resp : TBuf;
  Var St : LongInt) : Boolean;
Var H : String;
Begin
  H := 'Accept: application/vnd.github+json' + #13#10;
  If GhToken <> '' Then H := H + 'Authorization: token ' + GhToken + #13#10;
  If Body.N > 0 Then H := H + 'Content-Type: application/json' + #13#10;
  GhApi := HttpReq(Method, 'https://api.github.com' + Path, H, Body, Resp,
    St);
End;

{ repertorie les depots de l'utilisateur (objets du tableau racine) }
Procedure GhParseRepos(Var B : TBuf);
Var P, K, D : LongInt; S, Key : String;
Begin
  P := 0; D := 0;
  Repeat
    K := JsonNext(B, P, S);
    If K = 0 Then Exit;
    If K = JkSym Then
    Begin
      If (S = '{') Or (S = '[') Then
      Begin
        Inc(D);
        If (D = 2) And (S = '{') And (GhN < MaxGh) Then
        Begin
          GhName[GhN] := ''; GhUrl[GhN] := ''; GhPriv[GhN] := False;
          GhDesc[GhN] := '';
        End;
      End
      Else If (S = '}') Or (S = ']') Then
      Begin
        If (D = 2) And (S = '}') And (GhN < MaxGh) And (GhName[GhN] <> '')
        Then Inc(GhN);
        Dec(D);
      End;
      Continue;
    End;
    While (P < B.N) And (B.P^[P] <= 32) Do Inc(P);
    If (K = JkStr) And (P < B.N) And (B.P^[P] = Ord(':')) Then
    Begin
      Inc(P);
      If (D <> 2) Or (GhN >= MaxGh) Then Continue;
      Key := S;
      K := JsonNext(B, P, S);
      If K = JkSym Then
      Begin
        If (S = '{') Or (S = '[') Then Inc(D);
        Continue;
      End;
      If Key = 'full_name' Then GhName[GhN] := Copy(S, 1, 100)
      Else If Key = 'clone_url' Then GhUrl[GhN] := Copy(S, 1, 160)
      Else If Key = 'private' Then GhPriv[GhN] := S = 'true'
      Else If (Key = 'description') And (K = JkStr) Then
        GhDesc[GhN] := Copy(S, 1, 100);
    End;
  Until False;
End;

{ ouvre une session GitHub : verifie le jeton et lit l'identifiant }
Function GhSignIn : Boolean;
Var B, R : TBuf; St : LongInt;
Begin
  GhSignIn := False;
  BufInit(B); BufInit(R);
  If GhApi('GET', '/user', B, R, St) Then
  Begin
    If St = 200 Then
    Begin
      GhLogin := JsonGet(R, 'login', 1);
      GhSignIn := GhLogin <> '';
    End
    Else GitErr := HttpErr(St);
  End
  Else If GitErr = '' Then GitErr := 'connexion impossible '#224' api.github.com';
  BufFree(B); BufFree(R);
End;

Function GhListRepos : Boolean;
Var B, R : TBuf; St, Pg : LongInt; Old : LongInt;
Begin
  GhListRepos := False;
  GhN := 0;
  BufInit(B); BufInit(R);
  For Pg := 1 To 3 Do
  Begin
    Old := GhN;
    If Not GhApi('GET', '/user/repos?per_page=100&sort=updated&page=' +
      IStr(Pg), B, R, St) Then Break;
    If St <> 200 Then
    Begin
      GitErr := HttpErr(St); Break;
    End;
    GhParseRepos(R);
    GhListRepos := True;
    If GhN - Old < 100 Then Break;
  End;
  BufFree(B); BufFree(R);
End;

Function JsonQuote(Const S : String) : String;
Var I : LongInt; R : String;
Begin
  R := '"';
  For I := 1 To Length(S) Do
    If (S[I] = '"') Or (S[I] = '\') Then R := R + '\' + S[I]
    Else If S[I] >= ' ' Then R := R + S[I];
  JsonQuote := R + '"';
End;

{ cree un depot GitHub ; Url recoit l'adresse de clonage }
Function GhCreate(Const Name, Desc : String; Priv : Boolean;
  Var Url : String) : Boolean;
Var B, R : TBuf; St : LongInt; S : String;
Begin
  GhCreate := False;
  BufInit(B); BufInit(R);
  If Priv Then S := 'true' Else S := 'false';
  BufStr(B, '{"name":' + JsonQuote(Name) + ',"description":' +
    JsonQuote(Desc) + ',"private":' + S + '}');
  If GhApi('POST', '/user/repos', B, R, St) Then
  Begin
    If St = 201 Then
    Begin
      Url := JsonGet(R, 'clone_url', 1);
      GhCreate := Url <> '';
    End
    Else
    Begin
      S := JsonGet(R, 'message', 1);
      If S <> '' Then GitErr := 'GitHub : ' + S Else GitErr := HttpErr(St);
    End;
  End;
  BufFree(B); BufFree(R);
End;
{ ==================================================================== }
{ Transport d'OS/2 : verrou (DOSCALLS), sockets (TCPIP32), HTTP/1.1     }
{ ecrit ici (remplace WININET), https (TLS32.DLL), proxy                }
{ ==================================================================== }

Var
  LockSem : LongInt;                   { semaphore d'exclusion }
  LockOn : Boolean;
  LockDepth : LongInt;
  NetReady : Boolean;
  ProxyStr : String;                   { hote:port des Options, ou '' }
  EnvProxy : String;                   { SET HTTP_PROXY= de CONFIG.SYS }
  NetZ : Array[0..1023] Of Byte;
  NetAbort : Boolean;
  HRaw : Array[0..16383] Of Byte;      { octets recus (une requete a la fois) }

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

Function MemL4(A : LongInt) : LongInt;
Begin
  MemL4 := PLng(A)^;
End;

{ variable d'environnement (DosScanEnv) }
Function GetEnvS(Const Name : String) : String;
Var P : LongInt; S : String; Nm : Array[0..63] Of Byte;
Begin
  S := '';
  P := 0;
  PutZA(LongInt(@Nm), Name);
  If DosScanEnv(LongInt(@Nm), LongInt(@P)) = 0 Then
    If P <> 0 Then
      While (PByt(P)^ <> 0) And (Length(S) < 250) Do
      Begin
        S := S + Chr(PByt(P)^);
        Inc(P);
      End;
  GetEnvS := S;
End;

{ connexion TCP (git://, http, proxy) ; -1 si impossible }
Function TcpOpen(Const Host : String; Port : LongInt) : LongInt;
Var A : Array[0..15] Of Byte; S, IP, H, I, R : LongInt;
Begin
  TcpOpen := -1;
  If Not NetReady Then
  Begin
    Dummy0 := sock_init;
    NetReady := True;
  End;
  PutZA(LongInt(@NetZ), Host);
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

Function TcpRecv(H : LongInt; Var B : TBuf) : LongInt;
Var R : LongInt;
Begin
  If NetAbort Then
  Begin
    GitErr := 'op'#233'ration annul'#233'e'; TcpRecv := -1; Exit;
  End;
  BufNeed(B, B.N + 65536);
  If B.N + 65536 > B.Cap Then
  Begin
    GitErr := 'm'#233'moire insuffisante'; TcpRecv := -1; Exit;
  End;
  BigUnlock;
  R := recv(H, LongInt(@B.P^[B.N]), 65536, 0);
  BigLock;
  If R > 0 Then Inc(B.N, R);
  TcpRecv := R;
End;

Procedure TcpClose(H : LongInt);
Begin
  Dummy0 := shutdown(H, 2);
  Dummy0 := soclose(H);
End;

{ ---- HTTP/1.1 ----
  Une requete par connexion (Connection: close) ; reponse lue jusqu'a
  Content-Length, la fin du codage « chunked » ou la fermeture. Les
  octets du corps vont dans Resp, ou au pack recu (RecvFeed) pendant
  un fetch. }

Var
  HSock : LongInt;                     { socket de la requete }
  HTls : Boolean;                      { TLS32 sur HSock }

{ envoi sur la connexion (TLS ou non) ; verrou libre pendant l'appel }
Function HSendRaw(A, N : LongInt) : Boolean;
Var R, K : LongInt;
Begin
  HSendRaw := False;
  K := 0;
  While K < N Do
  Begin
    BigUnlock;
    If HTls Then R := TlsSend(1, A + K, MinL(N - K, 16384))
    Else R := send(HSock, A + K, MinL(N - K, 16384), 0);
    BigLock;
    If R <= 0 Then Exit;
    K := K + R;
  End;
  HSendRaw := True;
End;

Function HSendStr(Const S : String) : Boolean;
Var B : Array[0..259] Of Byte; I : LongInt;
Begin
  For I := 1 To Length(S) Do B[I - 1] := Ord(S[I]);
  HSendStr := HSendRaw(LongInt(@B), Length(S));
End;

{ recoit dans HRaw ; 0 : fin, -1 : erreur }
Function HRecvRaw : LongInt;
Var R : LongInt;
Begin
  BigUnlock;
  If HTls Then R := TlsRecv(1, LongInt(@HRaw), SizeOf(HRaw))
  Else R := recv(HSock, LongInt(@HRaw), SizeOf(HRaw), 0);
  BigLock;
  HRecvRaw := R;
End;

Procedure HClose;
Begin
  If HSock > 0 Then
  Begin
    If HTls Then Dummy0 := TlsClose(1);
    Dummy0 := shutdown(HSock, 2);
    Dummy0 := soclose(HSock);
  End;
  HSock := 0; HTls := False;
End;

{ hote du reseau local (sans proxy) }
Function LocalHost(Const H : String) : Boolean;
Var S : String;
Begin
  S := LowStr(H);
  LocalHost := (S = 'localhost') Or (Copy(S, 1, 4) = '127.') Or
    (Copy(S, 1, 3) = '10.') Or (Copy(S, 1, 8) = '192.168.');
End;

{ proxy a utiliser : Options, sinon HTTP_PROXY ; « hote:port » }
Procedure ProxyOf(Var PHost : String; Var PPort : LongInt);
Var S : String; K, E : LongInt;
Begin
  PHost := ''; PPort := 0;
  S := TrimS(ProxyStr);
  If S = '' Then S := TrimS(EnvProxy);
  If S = '' Then Exit;
  K := Pos('://', S);
  If K > 0 Then Delete(S, 1, K + 2);
  K := Pos('@', S);
  If K > 0 Then Delete(S, 1, K);
  K := Pos('/', S);
  If K > 0 Then S := Copy(S, 1, K - 1);
  K := Pos(':', S);
  If K = 0 Then
  Begin
    PHost := S; PPort := 80;
  End
  Else
  Begin
    PHost := Copy(S, 1, K - 1);
    Val(Copy(S, K + 1, 8), PPort, E);
    If (E <> 0) Or (PPort <= 0) Then PHost := '';
  End;
End;

{ en-tete de reponse : lit jusqu'a la ligne vide ; Hd recoit les
  en-tetes, Rest (dans HRaw a partir de RestOfs) le debut du corps }
Function HReadHead(Var Hd : TBuf; Var RestOfs, RestN : LongInt) : Boolean;
Var N, I, Start : LongInt;
Begin
  HReadHead := False;
  Hd.N := 0;
  Repeat
    If NetAbort Then
    Begin
      GitErr := 'op'#233'ration annul'#233'e'; Exit;
    End;
    N := HRecvRaw;
    If N <= 0 Then
    Begin
      GitErr := 'le serveur ' + UrlHost + ' a ferm'#233' la connexion';
      Exit;
    End;
    Start := Hd.N;
    BufMem(Hd, HRaw[0], N);
    { fin de l'en-tete (CR LF CR LF) }
    I := MaxL(0, Start - 3);
    While I + 3 < Hd.N Do
    Begin
      If (Hd.P^[I] = 13) And (Hd.P^[I + 1] = 10) And (Hd.P^[I + 2] = 13) And
         (Hd.P^[I + 3] = 10) Then
      Begin
        RestOfs := I + 4 - Start;
        RestN := N - RestOfs;
        Hd.N := I + 2;
        HReadHead := True;
        Exit;
      End;
      Inc(I);
    End;
  Until Hd.N > 65536;
  GitErr := 'en-t'#234'te HTTP trop long';
End;

{ valeur de l'en-tete Name (minuscules) dans Hd ; '' s'il est absent }
Function HHeader(Var Hd : TBuf; Const Name : String) : String;
Var I, J, E : LongInt; L, V : String;
Begin
  HHeader := '';
  I := 0;
  While I < Hd.N Do
  Begin
    E := I;
    While (E < Hd.N) And (Hd.P^[E] <> 10) Do Inc(E);
    J := I;
    While (J < E) And (Hd.P^[J] <> Ord(':')) Do Inc(J);
    If J < E Then
    Begin
      L := LowStr(BufStrAt(Hd, I, J - I));
      If L = Name Then
      Begin
        V := TrimS(BufStrAt(Hd, J + 1, E - J - 1));
        HHeader := V;
        Exit;
      End;
    End;
    I := E + 1;
  End;
End;

{ ajoute N octets de HRaw (a partir de Ofs) au corps de la reponse }
Procedure HBody(Var Resp : TBuf; Ofs, N : LongInt);
Begin
  If N <= 0 Then Exit;
  BufMem(Resp, HRaw[Ofs], N);
  If RecvOn Then RecvFeed(Resp);
End;

Var
  HChState, HChLeft : LongInt;         { decodage « chunked » }
  HChLine : String;

{ decode N octets du flux « chunked » ; vrai a la fin du dernier bloc }
Function HChunked(Var Resp : TBuf; Ofs, N : LongInt) : Boolean;
Var E, K, V, C : LongInt;
Begin
  HChunked := False;
  E := Ofs + N;
  While Ofs < E Do
  Begin
    Case HChState Of
      0 :                              { ligne de taille }
      Begin
        C := HRaw[Ofs]; Inc(Ofs);
        If C = 10 Then
        Begin
          V := 0;
          For K := 1 To Length(HChLine) Do
            If HexVal(HChLine[K]) >= 0 Then V := V * 16 + HexVal(HChLine[K])
            Else Break;
          HChLine := '';
          If V = 0 Then
          Begin
            HChState := 3;
            HChunked := True;
            Exit;
          End;
          HChLeft := V; HChState := 1;
        End
        Else If (C <> 13) And (Length(HChLine) < 60) Then
          HChLine := HChLine + Chr(C);
      End;
      1 :                              { donnees du bloc }
      Begin
        K := MinL(HChLeft, E - Ofs);
        HBody(Resp, Ofs, K);
        Ofs := Ofs + K;
        HChLeft := HChLeft - K;
        If HChLeft = 0 Then HChState := 2;
      End;
      2 :                              { CR LF apres le bloc }
      Begin
        If HRaw[Ofs] = 10 Then HChState := 0;
        Inc(Ofs);
      End;
    Else
      Begin
        HChunked := True; Exit;
      End;
    End;
  End;
End;

{ requete HTTP(S) ; Hdr : en-tetes supplementaires separes par #13#10 ;
  Body : corps envoye (POST) ; Resp : corps recu ; Status : code HTTP }
Function HttpReq(Const Method, Url, Hdr : String; Var Body, Resp : TBuf;
  Var Status : LongInt) : Boolean;
Var PHost, Path, Req, Loc, CurUrl, Meth, S : String; PPort, Port, N, Ofs,
    Redir, K, Len, Last, Got : LongInt; Hd : TBuf; Ok, Chunk, Done,
    UseProxy : Boolean; Eb : Array[0..255] Of Byte; Hb : Array[0..299] Of
    Byte;
Begin
  HttpReq := False;
  Status := 0;
  Resp.N := 0;
  CurUrl := Url; Meth := Method;
  BufInit(Hd);
  Redir := 0;
  Repeat
    Status := 0;
    Resp.N := 0;
    If Not UrlSplit(CurUrl) Or (UrlScheme = 'git') Then
    Begin
      GitErr := 'URL non valable : ' + CurUrl; BufFree(Hd); Exit;
    End;
    ProxyOf(PHost, PPort);
    UseProxy := (PHost <> '') And Not LocalHost(UrlHost);
    { connexion (au proxy ou au serveur) }
    If UseProxy Then HSock := TcpOpen(PHost, PPort)
    Else HSock := TcpOpen(UrlHost, UrlPort);
    If HSock <= 0 Then
    Begin
      HSock := 0;
      If UseProxy Then GitErr := 'proxy ' + PHost + ':' + IStr(PPort) +
        ' injoignable'
      Else GitErr := 'connexion impossible '#224' ' + UrlHost + ':' +
        IStr(UrlPort);
      BufFree(Hd); Exit;
    End;
    HTls := False;
    Port := UrlPort;
    { https par un proxy : tunnel CONNECT }
    If UseProxy And (UrlScheme = 'https') Then
    Begin
      Ok := HSendStr('CONNECT ' + UrlHost + ':' + IStr(Port) +
        ' HTTP/1.1'#13#10'Host: ' + UrlHost + ':' + IStr(Port) + #13#10 +
        'User-Agent: ' + AgentName + #13#10#13#10);
      If Ok Then Ok := HReadHead(Hd, Ofs, N);
      If Ok Then
      Begin
        S := BufStrAt(Hd, 0, 40);
        K := Pos(' ', S);
        Val(Copy(S, K + 1, 3), Status, Len);
        If Status <> 200 Then
        Begin
          GitErr := 'le proxy refuse le tunnel vers ' + UrlHost + ' (' +
            IStr(Status) + ')';
          Ok := False;
        End;
        Status := 0;
      End;
      If Not Ok Then
      Begin
        HClose; BufFree(Hd); Exit;
      End;
    End;
    If UrlScheme = 'https' Then
    Begin
      GitProgress('Connexion s'#233'curis'#233'e '#224' ' + UrlHost, 0, 0);
      PutZA(LongInt(@Hb), UrlHost);
      BigUnlock;
      K := TlsOpen(HSock, LongInt(@Hb));
      BigLock;
      If K <> 1 Then
      Begin
        Eb[0] := 0;
        Dummy0 := TlsError(LongInt(@Eb), 250);
        S := '';
        K := 0;
        While (Eb[K] <> 0) And (K < 250) Do
        Begin
          S := S + Chr(Eb[K]); Inc(K);
        End;
        GitErr := 'connexion s'#233'curis'#233'e impossible '#224' ' + UrlHost +
          ' (TLS : ' + S + ')';
        HClose; BufFree(Hd); Exit;
      End;
      HTls := True;
    End;
    { requete }
    If UseProxy And (UrlScheme = 'http') Then Path := CurUrl
    Else Path := UrlPath;
    Req := Meth + ' ' + Path + ' HTTP/1.1'#13#10;
    If ((UrlScheme = 'https') And (Port = 443)) Or
       ((UrlScheme = 'http') And (Port = 80)) Then S := UrlHost
    Else S := UrlHost + ':' + IStr(Port);
    Ok := HSendStr(Req) And HSendStr('Host: ' + S + #13#10) And
      HSendStr('User-Agent: ' + AgentName + #13#10) And
      HSendStr('Accept-Encoding: identity'#13#10'Connection: close'#13#10);
    If Ok And ((Body.N > 0) Or (Meth = 'POST')) Then
      Ok := HSendStr('Content-Length: ' + IStr(Body.N) + #13#10);
    If Ok And (Pos('accept:', LowStr(Hdr)) = 0) Then
      Ok := HSendStr('Accept: */*'#13#10);
    { en-tetes supplementaires (Hdr peut depasser 255 : par morceaux) }
    K := 1;
    While Ok And (K <= Length(Hdr)) Do
    Begin
      Ok := HSendStr(Copy(Hdr, K, 200));
      K := K + 200;
    End;
    If Ok Then Ok := HSendStr(#13#10);
    If Ok And (Body.N > 0) Then
    Begin
      GitProgress('Envoi', 0, 0);
      Ok := HSendRaw(LongInt(@Body.P^[0]), Body.N);
    End;
    If Not Ok Then
    Begin
      GitErr := 'envoi impossible vers ' + UrlHost;
      HClose; BufFree(Hd); Exit;
    End;
    { reponse : ligne d'etat et en-tetes }
    If Not HReadHead(Hd, Ofs, N) Then
    Begin
      HClose; BufFree(Hd); Exit;
    End;
    S := BufStrAt(Hd, 0, 60);
    K := Pos(' ', S);
    Val(Copy(S, K + 1, 3), Status, Len);
    If Len <> 0 Then Status := 0;
    If Status = 0 Then
    Begin
      GitErr := 'r'#233'ponse HTTP non valable de ' + UrlHost;
      HClose; BufFree(Hd); Exit;
    End;
    { redirection }
    Loc := HHeader(Hd, 'location');
    If ((Status = 301) Or (Status = 302) Or (Status = 303) Or
        (Status = 307) Or (Status = 308)) And (Loc <> '') And (Redir < 5) Then
    Begin
      HClose;
      If Copy(Loc, 1, 1) = '/' Then
      Begin
        If ((UrlScheme = 'https') And (Port = 443)) Or
           ((UrlScheme = 'http') And (Port = 80)) Then
          Loc := UrlScheme + '://' + UrlHost + Loc
        Else Loc := UrlScheme + '://' + UrlHost + ':' + IStr(Port) + Loc;
      End;
      CurUrl := Loc;
      If (Status = 303) Or ((Status <= 302) And (Meth <> 'POST')) Then
        Meth := 'GET';
      Inc(Redir);
      Continue;
    End;
    Break;
  Until False;
  { corps }
  Chunk := Pos('chunked', LowStr(HHeader(Hd, 'transfer-encoding'))) > 0;
  S := HHeader(Hd, 'content-length');
  Len := -1;
  If (S <> '') And Not Chunk Then
  Begin
    Val(S, Len, K);
    If K <> 0 Then Len := -1;
  End;
  If Meth = 'HEAD' Then Len := 0;
  HChState := 0; HChLeft := 0; HChLine := '';
  Got := 0; Last := 0;
  Done := Len = 0;
  If (N > 0) And Not Done Then
  Begin
    If Chunk Then Done := HChunked(Resp, Ofs, N)
    Else
    Begin
      If (Len >= 0) And (N > Len) Then N := Len;
      HBody(Resp, Ofs, N);
      Got := N;
      Done := (Len >= 0) And (Got >= Len);
    End;
  End;
  While Not Done Do
  Begin
    If NetAbort Then
    Begin
      GitErr := 'op'#233'ration annul'#233'e'; Status := 0; Break;
    End;
    If GitOom Then
    Begin
      GitErr := 'm'#233'moire insuffisante'; Status := 0; Break;
    End;
    N := HRecvRaw;
    If N <= 0 Then
    Begin
      { fin de connexion : normale sans longueur annoncee }
      If (Len >= 0) Or Chunk Then
      Begin
        GitErr := 'r'#233'ponse de ' + UrlHost + ' tronqu'#233'e';
        Status := 0;
      End;
      Break;
    End;
    If Chunk Then Done := HChunked(Resp, 0, N)
    Else
    Begin
      If (Len >= 0) And (Got + N > Len) Then N := Len - Got;
      HBody(Resp, 0, N);
      Got := Got + N;
      Done := (Len >= 0) And (Got >= Len);
    End;
    If Not RecvOn And (Resp.N - Last >= 65536) Then
    Begin
      GitProgress('R'#233'ception', Resp.N, 0);
      Last := Resp.N;
    End;
  End;
  HClose;
  BufFree(Hd);
  HttpReq := Status > 0;
End;

{ ==================================================================== }
{ Fichiers d'OS/2 (poignees de DosOpen)                                 }
{ ==================================================================== }

Function FOpenR(Const P : String) : LongInt;
Var H, Act : LongInt;
Begin
  H := 0; Act := 0;
  { ouvrir s'il existe ; lecture seule, partage permis }
  If DosOpen(FZa(P), LongInt(@H), LongInt(@Act), 0, 0, $01, $40, 0) <> 0 Then
    H := -1;
  FOpenR := H;
End;

Function FCreate(Const P : String) : LongInt;
Var H, Act : LongInt;
Begin
  H := 0; Act := 0;
  { creer ou remplacer ; lecture et ecriture }
  If DosOpen(FZa(P), LongInt(@H), LongInt(@Act), 0, 0, $12, $42, 0) <> 0 Then
    H := -1;
  FCreate := H;
End;

Function FReadAt(H, Pos : LongInt; Q : PBytes; N : LongInt) : LongInt;
Var R, NP : LongInt;
Begin
  FReadAt := 0;
  NP := 0;
  Breathe(N + 1024);
  If DosSetFilePtr(H, Pos, 0, LongInt(@NP)) <> 0 Then Exit;
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

{ taille (FILESTATUS3 de DosQueryFileInfo) }
Function FSize(H : LongInt) : LongInt;
Var B : Array[0..31] Of Byte;
Begin
  FSize := 0;
  If DosQueryFileInfo(H, 1, LongInt(@B), 24) = 0 Then
    FSize := PLng(LongInt(@B) + 12)^;
End;

Procedure FClose(H : LongInt);
Begin
  If H >= 0 Then Dummy0 := DosClose(H);
End;

Function FRmDir(Const P : String) : Boolean;
Begin
  FRmDir := DosDeleteDir(FZa(P)) = 0;
End;
{ ==================================================================== }
{ Utilitaires de l'interface (Presentation Manager)                     }
{ ==================================================================== }

Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';
Function DosSetDefaultDisk(D : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetCurrentDir(P : LongInt) : LongInt; External 'DOSCALLS';

Const
  CW = 8;                              { police de PM : 8 x 16 }

Var
  Hab, Hmq, MainWnd, MainFrame, Dummy, OemOut : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  Qmsg : Array[0..7] Of LongInt;
  AppDir, AppExeDir, IniFile : String;
  ScrW, ScrH : LongInt;
  PaintH : LongInt;                    { hauteur de la fenetre peinte }
  CtlKind : Array[0..255] Of Byte;     { 1 bouton, 2 saisie, 3 liste, 4 MLE }

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
  PutZA(LongInt(@NameZ), S);
  Z := LongInt(@NameZ);
End;

Function Z2(Const S : String) : LongInt;
Begin
  PutZA(LongInt(@NameZ2), S);
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

{ texte ANSI tel qu'il s'affiche (page 850 de l'ecran d'OS/2-0) }
Function Disp(S : String) : String;
Begin
  If OemOut <> 0 Then S := AnsiToOem(S);
  Disp := S;
End;

Function UnDisp(S : String) : String;
Begin
  If OemOut <> 0 Then S := OemToAnsi(S);
  UnDisp := S;
End;

Procedure DetectOem;
Begin
  OemOut := 1;
End;

{ boite de message : drapeaux de Pasdows traduits pour WinMessageBox ;
  #13#10 ou | = nouvelle ligne }
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

Var
  MbText : Array[0..1023] Of Byte;
  MbCap : Array[0..127] Of Byte;
  DlgFrame : LongInt;                  { boite de dialogue ouverte (cadre) }

Function Ask(Const Text, Cap : String; Fl : LongInt) : LongInt;
Var D, K, N, C : LongInt; S : String; Own : LongInt;
Begin
  S := Disp(Text);
  N := 0;
  For K := 1 To Length(S) Do
  Begin
    C := Ord(S[K]);
    If C = 13 Then Continue;
    If C = Ord('|') Then C := 10;
    MbText[N] := C; Inc(N);
  End;
  MbText[N] := 0;
  PutZA(LongInt(@MbCap), Disp(Cap));
  If TestMode Then
  Begin
    Log('GITCLI : boite : ' + Cap + ' : ' + Text);
    Ask := IDOK;
    Exit;
  End;
  If DlgFrame <> 0 Then Own := DlgFrame Else Own := MainFrame;
  D := LockDepthRelease;
  Ask := WinMessageBox(HWND_DESKTOP, Own, LongInt(@MbText), LongInt(@MbCap), 0, MbFlags(Fl));
  LockDepthRestore(D);
End;

Procedure ErrBox(Const S : String);
Begin
  Dummy := Ask(S, 'Client GitHub', MB_OK Or MB_ICONERROR);
End;

{ ---- dessin par GPI ----
  Coordonnees de Pasdows (origine en haut a gauche, X2 et Y2 exclus) ;
  PaintH (hauteur de la fenetre peinte) les retourne pour PM. Couleurs
  RVB ($00BBGGRR de Pasdows -> RRGGBB de GPI, LCOLF_RGB). }

Function Rgb(C : LongInt) : LongInt;
Begin
  Rgb := ((C And $FF) Shl 16) Or (C And $FF00) Or ((C Shr 16) And $FF);
End;

Function WinHt(H : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[3] := 0; Rc[1] := 0;
  Dummy0 := WinQueryWindowRect(H, LongInt(@Rc));
  WinHt := Rc[3] - Rc[1];
End;

Function WinWd(H : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[2] := 0; Rc[0] := 0;
  Dummy0 := WinQueryWindowRect(H, LongInt(@Rc));
  WinWd := Rc[2] - Rc[0];
End;

Function PaintBegin(H : LongInt) : LongInt;
Var Hps : LongInt;
Begin
  PaintH := WinHt(H);
  Hps := WinBeginPaint(H, 0, 0);
  Dummy0 := GpiCreateLogColorTable(Hps, 0, 3, 0, 0, 0);
  PaintBegin := Hps;
End;

Procedure PaintEnd(Dc : LongInt);
Begin
  Dummy0 := WinEndPaint(Dc);
End;

Procedure Bar(Dc, X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  Dummy0 := GpiSetColor(Dc, Rgb(C));
  P[0] := X1; P[1] := PaintH - Y2;
  Dummy0 := GpiMove(Dc, LongInt(@P[0]));
  P[0] := X2 - 1; P[1] := PaintH - Y1 - 1;
  { DRO_OUTLINEFILL }
  Dummy0 := GpiBox(Dc, 3, LongInt(@P[0]), 0, 0);
End;

{ texte (police 8 x 16 de PM), fond transparent ; Y : haut de la ligne }
Procedure Txt(Dc, X, Y : LongInt; Const S : String; Fg : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZA(LongInt(@TxtBuf), Disp(S));
  Dummy0 := GpiSetColor(Dc, Rgb(Fg));
  P[0] := X; P[1] := PaintH - Y - 12;
  Dummy0 := GpiCharStringAt(Dc, LongInt(@P), Length(S), LongInt(@TxtBuf));
End;

Function Fit(S : String; W : LongInt) : String;
Var N : LongInt;
Begin
  N := W Div CW;
  If N < 1 Then
  Begin
    Fit := ''; Exit;
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

{ place H (coordonnees de Pasdows dans son parent) }
Procedure Place(H, X, Y, W, Hh : LongInt);
Var Ph : LongInt;
Begin
  If H = 0 Then Exit;
  Ph := WinHt(WinQueryWindow(H, QW_PARENT));
  Dummy0 := WinSetWindowPos(H, 0, X, Ph - Y - MaxL(Hh, 1), MaxL(W, 1), MaxL(Hh, 1),
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
  If H = 0 Then Exit;
  Ht := WinHt(H);
  Rc[0] := X1; Rc[1] := Ht - Y2; Rc[2] := X2; Rc[3] := Ht - Y1;
  Dummy0 := WinInvalidateRect(H, LongInt(@Rc), 0);
End;

Procedure WFocus(H : LongInt);
Begin
  If H <> 0 Then Dummy0 := WinSetFocus(HWND_DESKTOP, H);
End;

Function GetFocus : LongInt;
Begin
  GetFocus := WinQueryFocus(HWND_DESKTOP);
End;

{ point de la fenetre H (Y vers le bas) -> ecran (Y vers le bas) }
Procedure ToScreen(H : LongInt; Var X, Y : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  P[0] := X; P[1] := WinHt(H) - 1 - Y;
  Dummy0 := WinMapWindowPoints(H, HWND_DESKTOP, LongInt(@P), 1);
  X := P[0]; Y := ScrH - 1 - P[1];
End;

Var
  PtrWait : Boolean;

{ pointeur de la souris : sablier ou fleche }
Procedure SetPtr(Wait : Boolean);
Var P : LongInt;
Begin
  If TestMode Then Exit;
  PtrWait := Wait;
  If Wait Then P := WinQuerySysPointer(HWND_DESKTOP, SPTR_WAIT, 0)
  Else P := WinQuerySysPointer(HWND_DESKTOP, SPTR_ARROW, 0);
  If P <> 0 Then Dummy0 := WinSetPointer(HWND_DESKTOP, P);
End;

{ touche de Pasdows (VK_SHIFT, VK_CONTROL) enfoncee }
Function KeyDown(V : LongInt) : Boolean;
Begin
  If V = VK_SHIFT Then V := PM_VK_SHIFT
  Else If V = VK_CONTROL Then V := PM_VK_CTRL;
  KeyDown := (WinGetKeyState(HWND_DESKTOP, V) And $8000) <> 0;
End;

Function S16(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V >= $8000 Then V := V - $10000;
  S16 := V;
End;

{ barres de defilement de PM : position Pos de 0 a Max, Vis visibles }
Procedure SbSet(Sb, Pos, Max, Vis : LongInt);
Begin
  If Sb = 0 Then Exit;
  Dummy0 := WinSendMsg(Sb, PM_SBM_SETSCROLLBAR, Pos, Max Shl 16);
  Dummy0 := WinSendMsg(Sb, PM_SBM_SETTHUMBSIZE, MaxL(1, Vis) Or ((Max + Vis) Shl 16), 0);
  Dummy0 := WinEnableWindow(Sb, Ord(Max > 0));
End;

{ fond gris des controles statiques et des cases (PP_BACKGROUNDCOLOR,
  RVB : le meme gris que le fond peint des boites) }
Procedure GrayCtl(H : LongInt);
Var C : LongInt;
Begin
  C := ClrFace;
  Dummy0 := WinSetPresParam(H, 3, 4, LongInt(@C));
End;

{ controle enfant de P (classes et styles de Pasdows traduits pour PM ;
  X, Y : Y vers le bas dans P) }
Function Ctl(P : LongInt; Const Cls, T : String; Style, X, Y, W, H, Id : LongInt) : LongInt;
Var R, C, S, K, Ph : LongInt;
Begin
  K := 0;
  S := PM_WS_VISIBLE;
  If (Style And WS_TABSTOP) <> 0 Then S := S Or PM_WS_TABSTOP;
  If (Style And WS_GROUP) <> 0 Then S := S Or PM_WS_GROUP;
  If (Cls = 'EDIT') And ((Style And ES_MULTILINE) <> 0) Then
  Begin
    C := WC_MLE; K := 4;
  End
  Else If Cls = 'EDIT' Then
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
    Y := Y - 1; H := MaxL(H, 16);
  End
  Else
  Begin
    C := WC_BUTTON; K := 1;
    Case Style And 15 Of
      BS_DEFPUSHBUTTON : S := S Or PM_BS_PUSHBUTTON Or PM_BS_DEFAULT;
      BS_AUTOCHECKBOX : S := S Or PM_BS_AUTOCHECKBOX;
      BS_GROUPBOX :
      Begin
        C := WC_STATIC; K := 0;
        S := S Or PM_SS_GROUPBOX;
      End;
    Else
      S := S Or PM_BS_PUSHBUTTON;
    End;
    If (Style And 15) = BS_AUTOCHECKBOX Then H := MaxL(H, 18);
  End;
  Ph := WinHt(P);
  { HWND_BOTTOM : l'ordre de tabulation suit l'ordre de creation }
  R := WinCreateWindow(P, C, Z(Disp(T)), S, X, Ph - Y - H, W, H, P, HWND_BOTTOM, Id, 0, 0);
  If (R <> 0) And ((C = WC_STATIC) Or ((C = WC_BUTTON) And ((S And 7) <> 0))) Then GrayCtl(R);
  If (R <> 0) And (C = WC_ENTRYFIELD) Then Dummy0 := WinSendMsg(R, PM_EM_SETTEXTLIMIT, 255, 0);
  If (Id >= 0) And (Id <= 255) Then CtlKind[Id] := K;
  Ctl := R;
End;

Function CtlText(H : LongInt) : String;
Var N : LongInt;
Begin
  TxtBuf[0] := 0;
  If H = 0 Then
  Begin
    CtlText := ''; Exit;
  End;
  N := WinQueryWindowText(H, 256, LongInt(@TxtBuf));
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

{ listes de PM }
Procedure LbClear(H : LongInt);
Begin
  Dummy0 := WinSendMsg(H, PM_LM_DELETEALL, 0, 0);
End;

Procedure LbAdd(H : LongInt; Const S : String);
Begin
  Dummy0 := WinSendMsg(H, PM_LM_INSERTITEM, $FFFF, Z(Disp(S)));
End;

Function LbSel(H : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := WinSendMsg(H, PM_LM_QUERYSELECTION, $FFFF, 0);
  If (R < 0) Or (R >= $FFFF) Then R := -1;
  LbSel := R;
End;

Procedure LbSetSel(H, I : LongInt);
Begin
  Dummy0 := WinSendMsg(H, PM_LM_SELECTITEM, I, 1);
End;

{ ---- menus : modele (menus de PM crees par gabarit) ----
  Un menu est un numero (1, 2...) ; ses articles (texte, separateur,
  sous-menu) gardent leur etat (coche, grise). SetMenu cree la barre de
  menus de la fenetre principale ; MCheck et MEnable mettent aussi a jour
  ses articles (MM_SETITEMATTR) ; TrackPopupMenu cree le menu contextuel
  avec WinPopupMenu (les commandes arrivent par WM_COMMAND). }
Const
  MaxMn = 48; MaxMi = 700;

Var
  MnN, MiN, MnBase : LongInt;
  MnLive : Array[1..MaxMn] Of Boolean;
  MiMenu, MiKind, MiId, MiAttr, MiSub : Array[0..MaxMi - 1] Of LongInt;
  MiText : Array[0..MaxMi - 1] Of String[80];
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
Begin
  If (MiN >= MaxMi) Or (M < 1) Then Exit;
  MiMenu[MiN] := M; MiKind[MiN] := Kind; MiId[MiN] := Id; MiAttr[MiN] := 0;
  MiText[MiN] := Copy(Disp(S), 1, 80); MiSub[MiN] := Sub;
  Inc(MiN);
End;

{ ~ = lettre soulignee (comme PM) ; Id 0 : separateur }
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

{ menu contextuel M au point (X, Y) de la fenetre H (Y vers le bas) }
Procedure TrackPopupMenu(M, H, X, Y : LongInt);
Var I, J : LongInt;
Begin
  MnLen := 0;
  MBuild(M);
  ToScreen(H, X, Y);
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

{ WM_VSCROLL / WM_HSCROLL de PM (mp2 : position, commande) -> code de
  Pasdows (SB_*) + position Shl 16 }
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
    If (V >= PM_VK_F1) And (V <= PM_VK_F1 + 11) Then VkOf := $70 + V - PM_VK_F1 Else VkOf := 0;
  End;
End;

Procedure CopyToClip(Const S : String);
Begin
  PutZA(LongInt(@TxtBuf), Disp(S));
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy0 := WinEmptyClipbrd(Hab);
    Dummy0 := WinSetClipbrdData(Hab, LongInt(@TxtBuf), 1, $400);
    Dummy0 := WinCloseClipbrd(Hab);
  End;
End;

{ ---- programmes d'OS/2-0 ---- }

Function AppPath(Const N : String) : String;
Begin
  If FAttr('C:\' + N) <> -1 Then AppPath := 'C:\' + N
  Else If FAttr(AppExeDir + N) <> -1 Then AppPath := AppExeDir + N
  Else AppPath := '';
End;

{ lance un programme (DosExecPgm, EXEC_BACKGROUND) dans le dossier Dir ;
  Sess : dans sa propre session (Invite de commandes) }
Function RunPgm(Const P, Params, Dir : String; Sess : Boolean) : Boolean;
Var Res : Array[0..1] Of LongInt; Fail : Array[0..63] Of Byte; Rc, S : LongInt;
Begin
  If (Length(Dir) >= 2) And (Dir[2] = ':') Then
  Begin
    Dummy0 := DosSetDefaultDisk(Ord(UpCase(Dir[1])) - 64);
    Dummy0 := DosSetCurrentDir(Z(Dir));
  End;
  PutZA(LongInt(@TxtBuf), P);
  PutZA(LongInt(@TxtBuf) + Length(P) + 1, Params);
  TxtBuf[Length(P) + Length(Params) + 2] := 0;
  S := -1;
  If Sess Then
  Begin
    S := KSes(4, Z(NameOf(P)), 0);
    If S >= 0 Then
    Begin
      Dummy0 := KSes(16, S, 1);
      Dummy0 := KSes(12, S, 0);
    End;
  End;
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@Fail), 64, 4, LongInt(@TxtBuf), 0, LongInt(@Res), Z2(P));
  If S >= 0 Then
  Begin
    If Rc <> 0 Then
    Begin
      Dummy0 := KSes(12, -1, 0);
      Dummy0 := KSes(17, S, 0);
    End
    Else Dummy0 := KSes(3, S, 0);
  End;
  RunPgm := Rc = 0;
  If Rc <> 0 Then ErrBox('Impossible de lancer ' + P + ' (erreur ' + IStr(Rc) + ').');
End;

{ ---- reglages (GITCLI.INI, format des fichiers .INI de Pasdows) ---- }

Var
  IniB : TBuf;                         { contenu du fichier }
  IniRead : Boolean;

Procedure IniLoad;
Begin
  If IniRead Then Exit;
  IniRead := True;
  BufInit(IniB);
  If Not FileLoad(IniFile, IniB) Then IniB.N := 0;
End;

{ position de la ligne « Key=valeur » de la section Sect (ou -1) ; Ins :
  ou inserer une nouvelle cle (fin de la section, -1 sans section) }
Function IniFind(Const Sect, Key : String; Var LineEnd, Ins : LongInt) : LongInt;
Var P, Q, E : LongInt; S, Cur : String; In0 : Boolean;
Begin
  IniFind := -1; Ins := -1; LineEnd := 0;
  P := 0; In0 := False; Cur := '';
  While P < IniB.N Do
  Begin
    E := P;
    While (E < IniB.N) And (IniB.P^[E] <> 10) Do Inc(E);
    S := TrimS(BufStrAt(IniB, P, E - P));
    Q := E;
    If Q < IniB.N Then Inc(Q);
    If (S <> '') And (S[1] = '[') Then
    Begin
      In0 := UpStr(S) = UpStr('[' + Sect + ']');
      If In0 Then Ins := Q;
    End
    Else If In0 Then
    Begin
      If S <> '' Then Ins := Q;
      If (Pos('=', S) > 0) And (UpStr(TrimS(Copy(S, 1, Pos('=', S) - 1))) = UpStr(Key)) Then
      Begin
        IniFind := P; LineEnd := Q;
        Exit;
      End;
    End;
    P := Q;
  End;
End;

Function IniGet(Const Sect, Key, Def : String) : String;
Var P, E, I, K : LongInt; S : String;
Begin
  IniLoad;
  P := IniFind(Sect, Key, E, I);
  If P < 0 Then
  Begin
    IniGet := Def; Exit;
  End;
  S := TrimS(BufStrAt(IniB, P, E - P));
  K := Pos('=', S);
  IniGet := TrimS(Copy(S, K + 1, 255));
End;

Procedure IniSet(Const Sect, Key, V : String);
Var P, E, I : LongInt; N : TBuf;
Begin
  IniLoad;
  BufInit(N);
  P := IniFind(Sect, Key, E, I);
  If P >= 0 Then
  Begin
    BufAppend(N, IniB, 0, P);
    BufStr(N, Key + '=' + V + #13#10);
    BufAppend(N, IniB, E, IniB.N - E);
  End
  Else If I >= 0 Then
  Begin
    BufAppend(N, IniB, 0, I);
    If (I > 0) And (IniB.P^[I - 1] <> 10) Then BufStr(N, #13#10);
    BufStr(N, Key + '=' + V + #13#10);
    BufAppend(N, IniB, I, IniB.N - I);
  End
  Else
  Begin
    BufAppend(N, IniB, 0, IniB.N);
    If (IniB.N > 0) And (IniB.P^[IniB.N - 1] <> 10) Then BufStr(N, #13#10);
    If IniB.N > 0 Then BufStr(N, #13#10);
    BufStr(N, '[' + Sect + ']' + #13#10 + Key + '=' + V + #13#10);
  End;
  BufCopy(IniB, N);
  BufFree(N);
  If FileSave(IniFile, IniB, 0, IniB.N) Then ;
End;

{ ecriture possible sur le lecteur D (pas un CD-ROM) }
Function DrvWritable(D : Char) : Boolean;
Var B : Array[0..63] Of Byte; Cb, N : LongInt; Fs : String;
Begin
  DrvWritable := False;
  Cb := 64;
  PutZA(LongInt(@NameZ2), D + ':');
  If DosQueryFSAttach(LongInt(@NameZ2), 0, 1, LongInt(@B), LongInt(@Cb)) <> 0 Then Exit;
  N := B[2] Or (B[3] Shl 8);
  Fs := UpStr(GetZ(LongInt(@B) + 8 + N + 1));
  DrvWritable := (Fs <> 'CDFS') And (Fs <> 'ISO9660') And (Fs <> 'UDF');
End;

{ dossier des reglages : C:\RESEAU\, sinon D:\RESEAU\ quand C: est en
  lecture seule (demarrage du CD-ROM), comme le Client FTP et le Client
  SSH ; depots clones par defaut dans X:\Mes documents\GitHub }
Var
  DataDrive : Char;

Procedure FindAppDir;
Var S : String;
Begin
  S := GetEnvS('COMSPEC');
  AppExeDir := 'C:\';
  If S <> '' Then
  Begin
    While (S <> '') And (S[Length(S)] <> '\') Do Delete(S, Length(S), 1);
    If S <> '' Then AppExeDir := S;
  End;
  DataDrive := 'C';
  If Not DrvWritable('C') Then DataDrive := 'D';
  AppDir := DataDrive + ':\RESEAU\';
  If FAttr(DataDrive + ':\RESEAU') = -1 Then
    If DosCreateDir(Z(DataDrive + ':\RESEAU'), 0) <> 0 Then
    Begin
      DataDrive := 'D';
      AppDir := 'D:\RESEAU\';
      Dummy0 := DosCreateDir(Z('D:\RESEAU'), 0);
    End;
  IniFile := AppDir + 'GITCLI.INI';
End;

{ fil courant (DosGetInfoBlocks : TIB, TIB2) }
Function CurTid : LongInt;
Var T, P : LongInt;
Begin
  T := 0; P := 0;
  Dummy0 := DosGetInfoBlocks(LongInt(@T), LongInt(@P));
  If T = 0 Then CurTid := 0 Else CurTid := PLng(PLng(T + 12)^)^;
End;
{ ==================================================================== }
{ Etat de l'application, depots, operations en arriere-plan             }
{ ==================================================================== }

Const
  MaxRepo = 30;
  OpNone = 0; OpClone = 1; OpFetch = 2; OpPull = 3; OpPush = 4;
  OpGhList = 5; OpPublish = 6; OpSignIn = 7;
  VwChanges = 0; VwHistory = 1;

Var
  RepoN, RepoCur : LongInt;
  RepoPath : Array[0..MaxRepo - 1] Of String[200];
  CloneRoot, DefName, DefEmail : String;
  View : LongInt;
  ChgSel, HistSel, FileSel : LongInt;
  HFiles : TFlat;
  HCommit : TCommit;
  HMsg : TBuf;
  Ahead, Behind : LongInt;
  HasUpstream, HasRemote : Boolean;
  CurBranch : String;
  LastFetch : LongInt;
  Busy : Boolean;
  Op : LongInt;
  OpOk : Boolean;
  OpRes : LongInt;
  OpUrl, OpDir, OpBranch, OpName, OpDesc : String;
  OpPriv : Boolean;
  WorkTid, ProgTick : LongInt;
  ProgTxt : String;
  ProgDone, ProgTotal : LongInt;
  StatusTxt : String;
  CredHost, CredUser, CredPass : String;
  DiffTitle : String;
  DiffMode : LongInt;                  { 0 vide, 1 texte, 2 binaire,
                                         3 trop grand }

Procedure InvalidateStatus; Forward;
Procedure PaintNow; Forward;

Function SizeTxt(V : LongInt) : String;
Begin
  If V < 1024 Then SizeTxt := IStr(V) + ' o'
  Else If V < 1048576 Then SizeTxt := IStr(V Div 1024) + ' Ko'
  Else SizeTxt := IStr(V Div 1048576) + ',' + IStr((V Mod 1048576) * 10 Div
    1048576) + ' Mo';
End;

{ progression : le fil reseau previent la fenetre (WinPostMsg) et laisse
  le verrou un instant ; le fil de l'interface redessine la barre d'etat }
Procedure GitProgress(Const What : String; Done, Total : LongInt);
Var T : LongInt;
Begin
  ProgTxt := What; ProgDone := Done; ProgTotal := Total;
  If TestMode Or (MainWnd = 0) Then Exit;
  T := MsTick;
  If (WorkTid <> 0) And (CurTid = WorkTid) Then
  Begin
    If T - ProgTick > 150 Then
    Begin
      ProgTick := T;
      Dummy0 := WinPostMsg(MainWnd, WM_GITPROG, 0, 0);
    End;
    BigUnlock;
    Dummy0 := DosSleep(0);
    BigLock;
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
  Else If ProgDone > 0 Then S := S + ' : ' + SizeTxt(ProgDone);
  ProgLine := S + '...';
End;

{ ---- liste des depots ---- }

Procedure ReposSave;
Var I : LongInt;
Begin
  IniSet('Depots', 'Nombre', IStr(RepoN));
  For I := 0 To RepoN - 1 Do IniSet('Depots', 'D' + IStr(I), RepoPath[I]);
  IniSet('Depots', 'Courant', IStr(RepoCur));
End;

Procedure ReposLoad;
Var I, E : LongInt;
Begin
  Val(IniGet('Depots', 'Nombre', '0'), RepoN, E);
  If (E <> 0) Or (RepoN < 0) Then RepoN := 0;
  If RepoN > MaxRepo Then RepoN := MaxRepo;
  For I := 0 To RepoN - 1 Do RepoPath[I] := IniGet('Depots', 'D' + IStr(I), '');
  Val(IniGet('Depots', 'Courant', '-1'), RepoCur, E);
  If (E <> 0) Or (RepoCur >= RepoN) Then RepoCur := -1;
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

{ supprime un dossier et son contenu (clonage echoue) }
Procedure RmTree(Const D : String; Depth : LongInt);
Var L : TFlat; J : LongInt;
Begin
  If (Depth > 30) Or (Length(D) <= 3) Then Exit;
  FlatInit(L);
  DirList(D, L, False);
  For J := 0 To L.N - 1 Do
    If L.E^[J].Mode <> 0 Then RmTree(D + '\' + L.E^[J].Path, Depth + 1)
    Else FileDel(D + '\' + L.E^[J].Path);
  FlatFree(L);
  If FRmDir(D) Then ;
End;

{ ---- identifiants ---- }

Procedure SetCreds(Const Url : String);
Begin
  RemUser := ''; RemPass := '';
  If Not UrlSplit(Url) Then Exit;
  If (LowStr(UrlHost) = 'github.com') And (GhToken <> '') Then
  Begin
    If GhLogin <> '' Then RemUser := GhLogin Else RemUser := 'git';
    RemPass := GhToken;
  End
  Else If (CredHost <> '') And (LowStr(UrlHost) = CredHost) Then
  Begin
    RemUser := CredUser; RemPass := CredPass;
  End;
End;

Procedure LoadIdentity;
Var S : String;
Begin
  S := CfgGet('user', '', 'name');
  If S <> '' Then UserName := S Else UserName := AnsiToUtf8(DefName);
  S := CfgGet('user', '', 'email');
  If S <> '' Then UserEmail := S Else UserEmail := DefEmail;
  If UserName = '' Then UserName := 'Utilisateur OS/2-0';
  If UserEmail = '' Then UserEmail := 'utilisateur@os2-0.local';
End;

{ ---- avance et retard sur la branche distante ---- }

Procedure AncLim(Const H : TSha; Var S : TShaSet; Max : LongInt);
Var Q : TShaList; I, J : LongInt; C : TCommit; X : TSha;
Begin
  If ShaIsZero(H) Then Exit;
  FillChar(Q, SizeOf(Q), 0);
  ListAdd(Q, H);
  I := 0;
  While (I < Q.N) And (S.N < Max) Do
  Begin
    X := Q.H^[I]; Inc(I);
    If Not SetAdd(S, X) Then Continue;
    If CommitRead(X, C, Nil) Then
      For J := 0 To C.PN - 1 Do ListAdd(Q, C.Parent[J]);
  End;
  ListFree(Q);
End;

{ commits atteints depuis From qui ne sont pas dans Other ; la marche
  s'arrete aux commits de Other (historique commun) }
Function CountOnly(Const From : TSha; Var Other : TShaSet; Max : LongInt)
  : LongInt;
Var Q : TShaList; S : TShaSet; I, J, N : LongInt; C : TCommit; X : TSha;
Begin
  N := 0;
  FillChar(Q, SizeOf(Q), 0);
  SetInit(S, 256);
  ListAdd(Q, From);
  I := 0;
  While (I < Q.N) And (N < Max) Do
  Begin
    X := Q.H^[I]; Inc(I);
    If ShaIsZero(X) Or SetHas(Other, X) Or Not SetAdd(S, X) Then Continue;
    Inc(N);
    If CommitRead(X, C, Nil) Then
      For J := 0 To C.PN - 1 Do ListAdd(Q, C.Parent[J]);
  End;
  ListFree(Q);
  SetFree(S);
  CountOnly := N;
End;

{ avance et retard sur origin : ancetres de chaque cote (600 au plus),
  puis commits propres a chacun (Pasdows comparait les deux ensembles
  limites, ce qui comptait un retard de trop dans un long historique) }
Procedure CountAB;
Var U : TSha; A, B : TShaSet;
Begin
  Ahead := 0; Behind := 0;
  HasRemote := CfgGet('remote', 'origin', 'url') <> '';
  HasUpstream := (CurBranch <> '') And
    RefRead('refs/remotes/origin/' + CurBranch, U);
  If Not HasUpstream Or ShaIsZero(HeadSha) Then Exit;
  If ShaEq(U, HeadSha) Then Exit;
  SetInit(A, 1024); SetInit(B, 1024);
  AncLim(HeadSha, A, 600);
  AncLim(U, B, 600);
  Ahead := CountOnly(HeadSha, B, 600);
  Behind := CountOnly(U, A, 600);
  SetFree(A); SetFree(B);
End;

{ ---- operations reseau (fil de travail) ---- }

Function DoOp : Boolean;
Var H : TSha; Ok : Boolean; U : String;
Begin
  DoOp := False;
  GitErr := ''; OpRes := 0;
  GitOom := False;
  Case Op Of
    OpClone :
    Begin
      SetCreds(OpUrl);
      DoOp := DoClone(OpUrl, OpDir);
    End;
    OpFetch, OpPull :
    Begin
      If Not SetRepo(RepoPath[RepoCur]) Then
      Begin
        GitErr := 'd'#233'p'#244't introuvable'; Exit;
      End;
      RemUrl := CfgGet('remote', 'origin', 'url');
      If RemUrl = '' Then
      Begin
        GitErr := 'aucun d'#233'p'#244't distant (origin) n''est d'#233'fini';
        Exit;
      End;
      SetCreds(RemUrl);
      Ok := DoFetch('origin');
      If Ok Then LastFetch := MsTick;
      If Ok And (Op = OpPull) Then
      Begin
        Ok := False;
        If Not RepoStatus Then Exit;
        If RefRead('refs/remotes/origin/' + OpBranch, H) Then
        Begin
          OpRes := DoMerge(H, 'branch ''' + OpBranch + ''' of ' + RemUrl);
          Ok := OpRes > 0;
        End
        Else GitErr := 'la branche ' + OpBranch +
          ' n''existe pas sur le d'#233'p'#244't distant';
      End;
      DoOp := Ok;
    End;
    OpPush, OpPublish :
    Begin
      If Not SetRepo(RepoPath[RepoCur]) Then
      Begin
        GitErr := 'd'#233'p'#244't introuvable'; Exit;
      End;
      If Op = OpPublish Then
      Begin
        If Not GhCreate(OpName, OpDesc, OpPriv, U) Then Exit;
        SetRemote('origin', U);
      End;
      RemUrl := CfgGet('remote', 'origin', 'url');
      If RemUrl = '' Then
      Begin
        GitErr := 'aucun d'#233'p'#244't distant (origin) : publiez d''abord ' +
          'le d'#233'p'#244't';
        Exit;
      End;
      SetCreds(RemUrl);
      Ok := DoPush('origin', OpBranch, False);
      If Ok And (CfgGet('branch', OpBranch, 'remote') = '') Then
        SetUpstream(OpBranch, 'origin');
      DoOp := Ok;
    End;
    OpSignIn : DoOp := GhSignIn;
    OpGhList :
    Begin
      Ok := True;
      If GhLogin = '' Then Ok := GhSignIn;
      If Ok Then Ok := GhListRepos;
      DoOp := Ok;
    End;
  End;
End;

{ fil de travail (DosCreateThread) : l'operation, puis WM_GITDONE }
Function WorkProc(P : LongInt) : LongInt;
Begin
  BigLock;
  NetAbort := False;
  OpOk := DoOp;
  RemClose;
  WorkTid := 0;
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
  Tid := 0;
  { le fil attend le verrou (tenu ici) : WorkTid est connu avant qu'il ne
    commence }
  If DosCreateThread(LongInt(@Tid), LongInt(@WorkProc), 0, 0, 262144) = 0 Then
    WorkTid := Tid
  Else
  Begin
    { pas de fil : execution directe }
    WorkTid := 0;
    OpOk := DoOp;
    RemClose;
    Dummy0 := WinPostMsg(MainWnd, WM_GITDONE, 0, 0);
  End;
  InvalidateStatus;
End;
{ ==================================================================== }
{ Listes (modifications, historique, fichiers d'un commit) et diff      }
{ ==================================================================== }

Const
  LvChg = 0; LvHist = 1; LvFiles = 2;
  SbW = 16;
  DRowH = 16;
  DHeadH = 24;
  DGut = 96;                           { gouttiere des numeros de lignes }

Type
  TLv = Record
    H, Sb : LongInt;
    Top, RowH, W, Hh : LongInt;
  End;

Var
  Lv : Array[0..2] Of TLv;
  DiffWnd, DSbV, DSbH : LongInt;
  DTop, DLeft, DW, DH : LongInt;

Procedure SelectChange(I : LongInt); Forward;
Procedure FocusNext(From : LongInt; Back : Boolean); Forward;
Procedure SelectCommit(I : LongInt); Forward;
Procedure SelectFile(I : LongInt); Forward;
Procedure ChangesMenu(X, Y : LongInt); Forward;
Procedure CheckedChanged; Forward;

Function LvCount(K : LongInt) : LongInt;
Begin
  Case K Of
    LvChg : LvCount := Chg.N;
    LvHist : LvCount := HistN;
    Else LvCount := HFiles.N;
  End;
End;

Function LvCur(K : LongInt) : LongInt;
Begin
  Case K Of
    LvChg : LvCur := ChgSel;
    LvHist : LvCur := HistSel;
    Else LvCur := FileSel;
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
    StNew : C := ClrAddI;
    StDel : C := ClrDelI;
    StConf : C := ClrConfI;
    Else C := ClrModI;
  End;
  Bar(Dc, X, Y, X + 12, Y + 12, C);
  Bar(Dc, X + 1, Y + 1, X + 11, Y + 11, ClrWin);
  Case St Of
    StNew :
    Begin
      Bar(Dc, X + 3, Y + 5, X + 9, Y + 7, C);
      Bar(Dc, X + 5, Y + 3, X + 7, Y + 9, C);
    End;
    StDel : Bar(Dc, X + 3, Y + 5, X + 9, Y + 7, C);
    StConf :
    Begin
      Bar(Dc, X + 5, Y + 2, X + 7, Y + 7, C);
      Bar(Dc, X + 5, Y + 8, X + 7, Y + 10, C);
    End;
    Else Bar(Dc, X + 4, Y + 4, X + 8, Y + 8, C);
  End;
End;

{ case a cocher d'OS/2 (13 points) }
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
        X := 24;
        If D <> '' Then
        Begin
          D := Fit(D, MaxL(30, Lv[K].W - 48 - Length(S) * CW));
          Txt(Dc, X, Y + 2, D, Fg2);
          X := X + Length(D) * CW;
        End;
        Txt(Dc, X, Y + 2, Fit(S, Lv[K].W - X - 22), Fg);
        StIcon(Dc, Lv[K].W - 17, Y + 4, St);
      End;
      LvHist :
      Begin
        Txt(Dc, 6, Y + 2, Fit(Utf8ToAnsi(Hist^[I].Summary), Lv[K].W - 10),
          Fg);
        Txt(Dc, 6, Y + 18, Fit(Utf8ToAnsi(Hist^[I].Author) + ' - ' +
          UnixToStr(Hist^[I].Time), Lv[K].W - 10), Fg2);
        If Not Sel Then Bar(Dc, 0, Y + Lv[K].RowH - 1, Lv[K].W,
          Y + Lv[K].RowH, ClrLight);
      End;
      Else
      Begin
        St := HFiles.E^[I].Flag And $FF;
        D := Utf8ToAnsi(DirOf(HFiles.E^[I].Path));
        S := Utf8ToAnsi(FileOf(HFiles.E^[I].Path));
        X := 6;
        If D <> '' Then
        Begin
          D := Fit(D, MaxL(30, Lv[K].W - 30 - Length(S) * CW));
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
    Else If K = LvHist Then S := 'Aucun commit'
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
    Else SelectFile(I);
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

{ procedure de PM des listes : messages de PM traduits en evenements de
  LvProc0 (souris : Y vers le bas ; touches virtuelles de PM) }
Function LvProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, V, R : LongInt;
Begin
  R := 0;
  BigLock;
  Case Msg Of
    PM_WM_PAINT : Dummy0 := LvProc0(H, WM_PAINT, 0, 0);
    PM_WM_ERASEBACKGROUND : R := 0;
    PM_WM_SIZE : Dummy0 := LvProc0(H, WM_SIZE, 0, Mp2);
    PM_WM_VSCROLL : Dummy0 := LvProc0(H, WM_VSCROLL, VsCode(Mp2), 0);
    PM_WM_BUTTON1DOWN :
    Begin
      Dummy0 := LvProc0(H, WM_LBUTTONDOWN, 0, MousePt(H, Mp1)); R := 1;
    End;
    PM_WM_BUTTON1DBLCLK :
    Begin
      Dummy0 := LvProc0(H, WM_LBUTTONDBLCLK, 0, MousePt(H, Mp1)); R := 1;
    End;
    PM_WM_BUTTON2DOWN :
    Begin
      Dummy0 := LvProc0(H, WM_RBUTTONDOWN, 0, MousePt(H, Mp1)); R := 1;
    End;
    PM_WM_CHAR :
    Begin
      Fl := Mp1 And $FFFF; V := (Mp2 Shr 16) And $FFFF;
      If ((Fl And PM_KC_KEYUP) = 0) And ((Fl And PM_KC_VIRTUALKEY) <> 0) And
         (VkOf(V) In [VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_HOME, VK_END, VK_SPACE]) And
         ((Fl And PM_KC_CTRL) = 0) Then
      Begin
        Dummy0 := LvProc0(H, WM_KEYDOWN, VkOf(V), 0);
        R := 1;
      End
      Else If ((Fl And PM_KC_KEYUP) = 0) And ((Fl And PM_KC_VIRTUALKEY) <> 0) And
         ((V = PM_VK_TAB) Or (V = PM_VK_BACKTAB)) Then
      Begin
        FocusNext(H, V = PM_VK_BACKTAB);
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
  DCols := MaxL(1, (DW - DGut - 12) Div CW);
End;

Procedure DiffSync;
Var M : LongInt;
Begin
  M := 0;
  If DiffMode = 1 Then M := MaxL(0, DfN - DRows);
  If DTop > M Then DTop := M;
  If DTop < 0 Then DTop := 0;
  SbSet(DSbV, DTop, M, DRows);
  M := MaxL(0, 250 - DCols);
  If DiffMode <> 1 Then M := 0;
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
  Txt(Dc, MaxL(4, (DW - Length(S) * CW) Div 2), Y, S, C);
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
    Txt(Dc, 8, 4, Fit(Utf8ToAnsi(DiffTitle), DW + SbW - 16 - Length(S) * CW),
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
  Bar(Dc, DW, DH, DW + SbW, DH + SbW, ClrFace);
  Case DiffMode Of
    0 :
    Begin
      If (RepoCur >= 0) And (View = VwChanges) And (Chg.N = 0) Then
      Begin
        CenterTxt(Dc, DHeadH + 60, 'Aucune modification locale', ClrBlack);
        CenterTxt(Dc, DHeadH + 84, 'Il n''y a aucune modification non ' +
          'valid'#233'e dans ce d'#233'p'#244't.', ClrGray);
        If Ahead > 0 Then
          CenterTxt(Dc, DHeadH + 108, IStr(Ahead) + ' commit(s) local(aux) '
            + #224' pousser vers origin (Ctrl+P).', ClrNavy)
        Else If Behind > 0 Then
          CenterTxt(Dc, DHeadH + 108, IStr(Behind) + ' commit(s) '#224' ' +
            'tirer depuis origin (Ctrl+Maj+P).', ClrNavy)
        Else
          CenterTxt(Dc, DHeadH + 108, 'Pour le modifier : D'#233'p'#244't > ' +
            'Ouvrir dans l''Explorateur.', ClrGray);
      End;
    End;
    2 : CenterTxt(Dc, DHeadH + 60, 'Fichier binaire : diff'#233'rences non ' +
          'affich'#233'es.', ClrGray);
    3 : CenterTxt(Dc, DHeadH + 60, 'Fichier trop volumineux pour afficher ' +
          'les diff'#233'rences.', ClrGray);
    1 :
    Begin
      If DfN = 0 Then
        CenterTxt(Dc, DHeadH + 60, 'Aucune diff'#233'rence de contenu (fichier '
          + 'vide ou mode modifi'#233').', ClrGray);
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
        If A <> '' Then Txt(Dc, 40 - Length(A) * CW, Y, A, ClrGray);
        If B <> '' Then Txt(Dc, 80 - Length(B) * CW, Y, B, ClrGray);
        Case Df^[I].K Of
          DkAdd : Txt(Dc, DGut - 8, Y, '+', ClrGreen);
          DkDel : Txt(Dc, DGut - 8, Y, '-', ClrRed);
        End;
        S := ExpandTabs(Utf8ToAnsi(DiffText(I)));
        If Df^[I].K = DkHunk Then
          Txt(Dc, DGut + 2, Y, Copy(S, 1, DCols), Fg)
        Else Txt(Dc, DGut + 2, Y, Copy(S, DLeft + 1, DCols), Fg);
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
Var Fl, V, R : LongInt;
Begin
  R := 0;
  BigLock;
  Case Msg Of
    PM_WM_PAINT : Dummy0 := DiffProc0(H, WM_PAINT, 0, 0);
    PM_WM_ERASEBACKGROUND : R := 0;
    PM_WM_SIZE : Dummy0 := DiffProc0(H, WM_SIZE, 0, Mp2);
    PM_WM_VSCROLL : Dummy0 := DiffProc0(H, WM_VSCROLL, VsCode(Mp2), 0);
    PM_WM_HSCROLL : Dummy0 := DiffProc0(H, WM_HSCROLL, VsCode(Mp2), 0);
    PM_WM_BUTTON1DOWN :
    Begin
      Dummy0 := DiffProc0(H, WM_LBUTTONDOWN, 0, MousePt(H, Mp1)); R := 1;
    End;
    PM_WM_CHAR :
    Begin
      Fl := Mp1 And $FFFF; V := (Mp2 Shr 16) And $FFFF;
      If ((Fl And PM_KC_KEYUP) = 0) And ((Fl And PM_KC_VIRTUALKEY) <> 0) And
         (VkOf(V) In [VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_HOME, VK_END, VK_LEFT, VK_RIGHT]) Then
      Begin
        Dummy0 := DiffProc0(H, WM_KEYDOWN, VkOf(V), 0);
        R := 1;
      End
      Else If ((Fl And PM_KC_KEYUP) = 0) And ((Fl And PM_KC_VIRTUALKEY) <> 0) And
         ((V = PM_VK_TAB) Or (V = PM_VK_BACKTAB)) Then
      Begin
        FocusNext(H, V = PM_VK_BACKTAB);
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

{ charge les deux versions et calcule le diff }
Procedure DiffLoad(Const OldSha, NewSha : TSha; FromWork : Boolean;
  Const Path : String; St : LongInt);
Var T, SA, SB, Tm : LongInt;
Begin
  DiffTitle := Path;
  DfA.N := 0; DfB.N := 0;
  DiffMode := 1;
  { tailles d'abord : un gros fichier n'est pas charge en memoire }
  SA := 0; SB := 0;
  If Not ShaIsZero(OldSha) Then
    If Not ObjInfo(OldSha, T, SA) Then SA := 0;
  If St <> StDel Then
  Begin
    If FromWork Then
    Begin
      If Not FileStat(WorkPath(Path), SB, Tm) Then SB := 0;
    End
    Else If Not ObjInfo(NewSha, T, SB) Then SB := 0;
  End;
  If SA + SB > 3000000 Then
  Begin
    DiffMode := 3; DfN := 0; DfAdd := 0; DfDel := 0;
    DiffReset;
    Exit;
  End;
  If Not ShaIsZero(OldSha) Then
    If Not BlobLoad(OldSha, DfA) Then DfA.N := 0;
  If St <> StDel Then
  Begin
    If FromWork Then
    Begin
      If Not FileLoad(WorkPath(Path), DfB) Then DfB.N := 0;
    End
    Else If Not BlobLoad(NewSha, DfB) Then DfB.N := 0;
  End;
  If DfA.N + DfB.N > 3000000 Then
  Begin
    DiffMode := 3; DfN := 0;
  End
  Else
  Begin
    DiffBuild;
    If DfBin Then DiffMode := 2;
  End;
  DiffReset;
End;

Procedure DiffClear;
Begin
  DiffTitle := '';
  DiffMode := 0;
  DfN := 0;
  DiffReset;
End;
{ ==================================================================== }
{ Boites de dialogue (cadres de PM, controles natifs)                   }
{ ==================================================================== }

Const
  DgInput = 1; DgClone = 2; DgNew = 3; DgAdd = 4; DgOptions = 5;
  DgPublish = 6; DgMerge = 7; DgCred = 8; DgRepoSet = 9; DgBrowse = 10;
  IdInput = 120;
  IdList = 201; IdRefresh = 202; IdUrl = 203; IdPath = 204; IdBrowse = 205;
  IdName = 206; IdDesc = 207; IdReadme = 208; IdPriv = 209; IdToken = 210;
  IdSignIn = 211; IdSignOut = 212; IdUName = 213; IdUMail = 214;
  IdProxy = 215; IdRoot = 216; IdLogin = 217; IdUser = 218; IdPass = 219;
  IdInfo = 220; IdFbPath = 221; IdFbList = 222; IdFbNew = 223;
  MaxFb = 300;

Var
  DlgWnd, DlgKind, DlgRes : LongInt;
  DlgDone : Boolean;
  DlgText : String;
  InpEdit : LongInt;
  DC : Array[200..230] Of LongInt;
  PathEdited, DlgSync : Boolean;
  MergeRefs : Array[0..199] Of String[120];
  MergeN : LongInt;
  DlgOut : Array[0..7] Of String;
  DlgPrevFocus, DlgOwner : LongInt;
  FbDir : String;                      { dossier affiche (Parcourir) }
  FbNames : Array[0..MaxFb - 1] Of String[100];
  FbN : LongInt;

Procedure RefreshRepo(Keep : Boolean); Forward;

{ boucle modale : le proprietaire (fenetre principale ou boite qui a
  ouvert celle-ci) est desactive ; le verrou est libre pendant l'attente
  des messages }
Procedure ModalLoop;
Var D : LongInt;
Begin
  Dummy0 := WinEnableWindow(DlgOwner, 0);
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
  { le proprietaire est reactive avant la destruction de la boite (sinon
  PM active une autre fenetre du bureau et le clavier ne revient pas) }
  Dummy0 := WinEnableWindow(DlgOwner, 1);
  Dummy0 := WinSetActiveWindow(HWND_DESKTOP, DlgOwner);
  If (DlgPrevFocus <> 0) And (WinIsWindow(Hab, DlgPrevFocus) <> 0) Then WFocus(DlgPrevFocus)
  Else WFocus(MainWnd);
  If DlgFrame <> 0 Then Dummy0 := WinDestroyWindow(DlgFrame);
  DlgWnd := 0; DlgFrame := 0;
  Dummy0 := WinSetActiveWindow(HWND_DESKTOP, DlgOwner);
  If (DlgPrevFocus <> 0) And (WinIsWindow(Hab, DlgPrevFocus) <> 0) Then WFocus(DlgPrevFocus)
  Else WFocus(MainWnd);
End;

{ boite de dialogue : cadre de PM (titre, menu systeme, bordure de
  dialogue) centre, zone client de W x H ; DlgWnd est la zone client,
  parent des controles (cachee jusqu'a DlgShow) }
Function DlgCreate(Const Title : String; W, H : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Fw, Fh, Fl, I : LongInt;
Begin
  For I := 200 To 230 Do DC[I] := 0;
  DlgDone := False; DlgRes := IDCANCEL;
  DlgPrevFocus := WinQueryFocus(HWND_DESKTOP);
  If DlgFrame <> 0 Then DlgOwner := DlgFrame Else DlgOwner := MainFrame;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DlgWnd := 0;
  DlgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z2('GCDLG'),
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
  DC[Id] := Ctl(DlgWnd, 'EDIT', S, St, X, Y, W, 22, Id);
  DEdit := DC[Id];
End;

Procedure DButtons(W, H : LongInt; Const OkTxt : String);
Var Bw : LongInt;
Begin
  Bw := MaxL(90, Length(OkTxt) * CW + 24);
  Dummy := Ctl(DlgWnd, 'BUTTON', OkTxt, BS_DEFPUSHBUTTON Or WS_TABSTOP,
    W - Bw - 104, H - 36, Bw, 26, IDOK);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Annuler', WS_TABSTOP, W - 96, H - 36, 84,
    26, IDCANCEL);
End;

Function DText(Id : LongInt) : String;
Begin
  If DC[Id] = 0 Then DText := '' Else DText := TrimS(CtlText(DC[Id]));
End;

Function InputBox(Const Title, Prompt : String; Var S : String) : Boolean;
Var W : LongInt;
Begin
  InputBox := False;
  DlgKind := DgInput;
  W := MaxL(360, Length(Prompt) * CW + 24);
  If W > ScrW - 40 Then W := ScrW - 40;
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

{ ---- choix d'un dossier (remplace SHBrowseForFolder) ----
  Liste des lecteurs et des sous-dossiers du dossier affiche ; double
  clic ou Entree pour y entrer ; la boite s'ouvre par-dessus celle qui
  l'appelle (etat de cette derniere garde, puis rendu). }

Procedure FbFill;
Var L : TFlat; J : LongInt; D : Char;
Begin
  FbN := 0;
  LbClear(DC[IdFbList]);
  If FbDir <> '' Then
  Begin
    FbNames[FbN] := '..'; Inc(FbN);
    LbAdd(DC[IdFbList], '[..]');
    FlatInit(L);
    DirList(FbDir, L, False);
    FlatSort(L);
    For J := 0 To L.N - 1 Do
      If (L.E^[J].Mode <> 0) And (FbN < MaxFb - 26) Then
      Begin
        FbNames[FbN] := L.E^[J].Path; Inc(FbN);
        LbAdd(DC[IdFbList], '[' + OemToAnsi(L.E^[J].Path) + ']');
      End;
    FlatFree(L);
  End;
  For D := 'C' To 'Z' Do
    If FAttr(D + ':\') >= 0 Then
    Begin
      FbNames[FbN] := D + ':\'; Inc(FbN);
      LbAdd(DC[IdFbList], '[-' + D + '-]');
    End;
  DlgSync := True;
  SetText(DC[IdFbPath], OemToAnsi(FbDir));
  DlgSync := False;
End;

Procedure FbEnter(I : LongInt);
Var S : String;
Begin
  If (I < 0) Or (I >= FbN) Then Exit;
  S := FbNames[I];
  If S = '..' Then
  Begin
    If Length(FbDir) <= 3 Then FbDir := ''
    Else
    Begin
      FbDir := ParentOf(FbDir);
      If Length(FbDir) = 2 Then FbDir := FbDir + '\';
    End;
  End
  Else If (Length(S) = 3) And (S[2] = ':') Then FbDir := S
  Else If (FbDir <> '') And (FbDir[Length(FbDir)] = '\') Then FbDir := FbDir + S
  Else FbDir := FbDir + '\' + S;
  FbFill;
End;

Function BrowseFolder(Const Title : String; Var Dir : String) : Boolean;
Const W = 420; H = 330;
Var SvWnd, SvFrame, SvKind, SvRes, SvPrev, SvOwner, I : LongInt;
    SvDone, SvSync : Boolean; SvDC : Array[200..230] Of LongInt;
    SvText, P : String;
Begin
  BrowseFolder := False;
  SvWnd := DlgWnd; SvFrame := DlgFrame; SvKind := DlgKind; SvRes := DlgRes;
  SvDone := DlgDone; SvPrev := DlgPrevFocus; SvOwner := DlgOwner;
  SvSync := DlgSync; SvText := DlgText;
  For I := 200 To 230 Do SvDC[I] := DC[I];
  DlgKind := DgBrowse;
  P := AnsiToOem(Dir);
  While (Length(P) > 3) And Not DirExist(P) Do P := ParentOf(P);
  If (Length(P) = 2) And (P[2] = ':') Then P := P + '\';
  If Not DirExist(P) Then P := DataDrive + ':\';
  FbDir := P;
  If DlgCreate('Parcourir', W, H) <> 0 Then
  Begin
    Lbl(DlgWnd, Title, 12, 8, W - 24);
    DC[IdFbPath] := Ctl(DlgWnd, 'EDIT', '', WS_BORDER Or ES_AUTOHSCROLL Or
      WS_TABSTOP, 12, 28, W - 24, 22, IdFbPath);
    DC[IdFbList] := Ctl(DlgWnd, 'LISTBOX', '', WS_BORDER Or WS_VSCROLL Or
      LBS_NOTIFY Or WS_TABSTOP, 12, 58, W - 24, H - 110, IdFbList);
    Dummy := Ctl(DlgWnd, 'BUTTON', 'Nouveau dossier...', WS_TABSTOP, 12,
      H - 36, 150, 26, IdFbNew);
    DButtons(W, H, 'OK');
    FbFill;
    DlgShow;
    WFocus(DC[IdFbList]);
    ModalLoop;
    If (DlgRes = IDOK) And (DlgText <> '') Then
    Begin
      Dir := DlgText;
      BrowseFolder := True;
    End;
  End;
  DlgWnd := SvWnd; DlgFrame := SvFrame; DlgKind := SvKind; DlgRes := SvRes;
  DlgDone := SvDone; DlgPrevFocus := SvPrev; DlgOwner := SvOwner;
  DlgSync := SvSync; DlgText := SvText;
  For I := 200 To 230 Do DC[I] := SvDC[I];
  If DlgFrame <> 0 Then
  Begin
    Dummy0 := WinSetActiveWindow(HWND_DESKTOP, DlgFrame);
    If (DlgPrevFocus <> 0) And (WinIsWindow(Hab, DlgPrevFocus) <> 0) Then ;
  End;
End;

Function InputBox2(Const Title, Prompt : String; Var S : String) : Boolean;
Forward;

Procedure FbCommand(Id, Code : LongInt);
Var S : String;
Begin
  Case Id Of
    IdFbList :
      If Code = LBN_DBLCLK Then FbEnter(LbSel(DC[IdFbList]));
    IdFbNew :
      If FbDir <> '' Then
      Begin
        S := '';
        If InputBox2('Nouveau dossier', 'Nom du dossier '#224' cr'#233'er dans ' +
          OemToAnsi(FbDir) + ' :', S) And (S <> '') Then
        Begin
          If FbDir[Length(FbDir)] = '\' Then S := FbDir + AnsiToOem(S)
          Else S := FbDir + '\' + AnsiToOem(S);
          MkDirs(S);
          If DirExist(S) Then FbDir := S
          Else ErrBox('Cr'#233'ation du dossier impossible : ' + OemToAnsi(S));
          FbFill;
        End;
      End;
    IDOK :
    Begin
      S := AnsiToOem(DText(IdFbPath));
      If (S <> '') And (S <> FbDir) And DirExist(S) Then
      Begin
        { chemin tape puis Entree : on y entre }
        FbDir := S;
        FbFill;
        Exit;
      End;
      If S = '' Then S := FbDir;
      If (Length(S) > 3) And (S[Length(S)] = '\') Then Delete(S, Length(S), 1);
      DlgText := OemToAnsi(S);
      DlgRes := IDOK; DlgDone := True;
    End;
    IDCANCEL :
    Begin
      DlgRes := IDCANCEL; DlgDone := True;
    End;
  End;
End;

{ nom du depot d'apres une URL (.../nom.git) }
Function UrlRepoName(S : String) : String;
Var K : LongInt;
Begin
  While (S <> '') And (S[Length(S)] = '/') Do Delete(S, Length(S), 1);
  K := Length(S);
  While (K > 0) And (S[K] <> '/') And (S[K] <> ':') Do Dec(K);
  S := Copy(S, K + 1, 255);
  If LowStr(Copy(S, Length(S) - 3, 4)) = '.git' Then
    Delete(S, Length(S) - 3, 4);
  UrlRepoName := S;
End;

{ « utilisateur/depot » -> https://github.com/utilisateur/depot.git }
Function NormUrl(S : String) : String;
Begin
  S := TrimS(S);
  If (S <> '') And (Pos('://', S) = 0) And (Pos('/', S) > 0) And
     (Pos(' ', S) = 0) Then
  Begin
    If LowStr(Copy(S, 1, 11)) = 'github.com/' Then S := 'https://' + S
    Else S := 'https://github.com/' + S;
    If LowStr(Copy(S, Length(S) - 3, 4)) <> '.git' Then S := S + '.git';
  End;
  NormUrl := S;
End;

Function JoinDir(Const D, N : String) : String;
Begin
  If (D <> '') And (D[Length(D)] = '\') Then JoinDir := D + N
  Else JoinDir := D + '\' + N;
End;

Function DirEmpty(Const D : String) : Boolean;
Var L : TFlat;
Begin
  FlatInit(L);
  DirList(D, L, False);
  DirEmpty := L.N = 0;
  FlatFree(L);
End;

Procedure CloneFill;
Var I : LongInt;
Begin
  If DC[IdList] = 0 Then Exit;
  LbClear(DC[IdList]);
  For I := 0 To GhN - 1 Do
    If GhPriv[I] Then LbAdd(DC[IdList], Utf8ToAnsi(GhName[I]) + '  (priv'#233')')
    Else LbAdd(DC[IdList], Utf8ToAnsi(GhName[I]));
  If GhLogin <> '' Then
    SetText(DC[IdInfo], 'D'#233'p'#244'ts GitHub de ' + GhLogin + ' (' +
      IStr(GhN) + ') :')
  Else SetText(DC[IdInfo], 'D'#233'p'#244'ts GitHub : voir Fichier > Options.');
End;

Procedure CloneRefreshList;
Begin
  If GhToken = '' Then
  Begin
    ErrBox('Pour lister vos d'#233'p'#244'ts GitHub, entrez d''abord un jeton '
      + 'd''acc'#232's personnel dans Fichier > Options.');
    Exit;
  End;
  SetPtr(True);
  If GhLogin = '' Then
    If Not GhSignIn Then
    Begin
      SetPtr(False);
      ErrBox('Connexion '#224' GitHub impossible : ' + GitErr);
      Exit;
    End;
  If Not GhListRepos Then ErrBox('Liste des d'#233'p'#244'ts : ' + GitErr);
  CloneFill;
  SetPtr(False);
End;

Procedure ClonePathFromUrl;
Var N : String;
Begin
  If PathEdited Then Exit;
  N := UrlRepoName(NormUrl(DText(IdUrl)));
  DlgSync := True;
  If N <> '' Then SetText(DC[IdPath], JoinDir(CloneRoot, N))
  Else SetText(DC[IdPath], CloneRoot);
  DlgSync := False;
End;

Function CloneDialog : Boolean;
Const W = 540; H = 356;
Begin
  CloneDialog := False;
  DlgKind := DgClone;
  PathEdited := False; DlgSync := False;
  If DlgCreate('Cloner un d'#233'p'#244't', W, H) = 0 Then Exit;
  DC[IdInfo] := Ctl(DlgWnd, 'STATIC', '', 0, 12, 10, W - 190, 16, IdInfo);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Actualiser la liste', WS_TABSTOP,
    W - 172, 6, 160, 26, IdRefresh);
  DC[IdList] := Ctl(DlgWnd, 'LISTBOX', '', WS_BORDER Or WS_VSCROLL Or
    LBS_NOTIFY Or WS_TABSTOP, 12, 38, W - 24, 120, IdList);
  Lbl(DlgWnd, 'URL ou nom d''utilisateur/d'#233'p'#244't (http, https, ' +
    'git://) :', 12, 170, W - 24);
  Dummy := DEdit(IdUrl, 12, 190, W - 24, '', False);
  Lbl(DlgWnd, 'Chemin local :', 12, 224, W - 24);
  Dummy := DEdit(IdPath, 12, 244, W - 132, CloneRoot, False);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Parcourir...', WS_TABSTOP, W - 112, 242,
    100, 26, IdBrowse);
  Lbl(DlgWnd, 'Exemple : gladir/7iles ou https://serveur/projet.git',
    12, 278, W - 24);
  DButtons(W, H, 'Cloner');
  CloneFill;
  DlgShow;
  WFocus(DC[IdUrl]);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    OpUrl := DlgOut[0]; OpDir := DlgOut[1];
    CloneDialog := True;
  End;
End;

Procedure CloneCommand(Id, Code : LongInt);
Var I : LongInt; S, P : String;
Begin
  Case Id Of
    IdRefresh : CloneRefreshList;
    IdList :
      If (Code = LBN_SELCHANGE) Or (Code = LBN_DBLCLK) Then
      Begin
        I := LbSel(DC[IdList]);
        If (I >= 0) And (I < GhN) Then
        Begin
          PathEdited := False;
          SetText(DC[IdUrl], GhUrl[I]);
          ClonePathFromUrl;
        End;
      End;
    IdUrl : If (Code = EN_CHANGE) And Not DlgSync Then ClonePathFromUrl;
    IdPath : If (Code = EN_CHANGE) And Not DlgSync Then PathEdited := True;
    IdBrowse :
    Begin
      S := DText(IdPath);
      If S = '' Then S := CloneRoot;
      If BrowseFolder('Dossier o'#249' cloner le d'#233'p'#244't :', S) Then
      Begin
        P := UrlRepoName(NormUrl(DText(IdUrl)));
        If (P <> '') And (LowStr(NameOf(S)) <> LowStr(P)) Then S := JoinDir(S, P);
        DlgSync := True;
        SetText(DC[IdPath], S);
        DlgSync := False;
        PathEdited := True;
      End;
    End;
    IDOK :
    Begin
      S := NormUrl(DText(IdUrl));
      P := DText(IdPath);
      If Not UrlSplit(S) Then
      Begin
        ErrBox('Entrez une URL de d'#233'p'#244't valable (https://..., ' +
          'http://..., git://...) ou un nom utilisateur/d'#233'p'#244't.');
        Exit;
      End;
      If (P = '') Or (Pos(':', P) = 0) Then
      Begin
        ErrBox('Entrez un chemin local complet (par exemple ' + DataDrive +
          ':\Mes documents\GitHub\projet).');
        Exit;
      End;
      If DirExist(AnsiToOem(P)) And Not DirEmpty(AnsiToOem(P)) Then
      Begin
        ErrBox('Le dossier ' + P + ' existe d'#233'j'#224' et n''est pas ' +
          'vide.');
        Exit;
      End;
      DlgOut[0] := S; DlgOut[1] := AnsiToOem(P);
      DlgRes := IDOK; DlgDone := True;
    End;
    IDCANCEL :
    Begin
      DlgRes := IDCANCEL; DlgDone := True;
    End;
  End;
End;

{ ---- nouveau depot ---- }

Function NewRepoDialog : Boolean;
Const W = 470; H = 290;
Begin
  NewRepoDialog := False;
  DlgKind := DgNew;
  If DlgCreate('Cr'#233'er un nouveau d'#233'p'#244't', W, H) = 0 Then Exit;
  Lbl(DlgWnd, 'Nom :', 12, 10, 120);
  Dummy := DEdit(IdName, 12, 30, W - 24, '', False);
  Lbl(DlgWnd, 'Description :', 12, 62, 200);
  Dummy := DEdit(IdDesc, 12, 82, W - 24, '', False);
  Lbl(DlgWnd, 'Chemin local (le dossier du d'#233'p'#244't y sera cr'#233
    + #233') :', 12, 114, W - 24);
  Dummy := DEdit(IdPath, 12, 134, W - 132, CloneRoot, False);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Parcourir...', WS_TABSTOP, W - 112, 132,
    100, 26, IdBrowse);
  DC[IdReadme] := Ctl(DlgWnd, 'BUTTON', 'Initialiser ce d'#233'p'#244't ' +
    'avec un fichier README', BS_AUTOCHECKBOX Or WS_TABSTOP, 12, 170,
    W - 24, 20, IdReadme);
  SetCheck(DC[IdReadme], True);
  DC[IdPriv] := Ctl(DlgWnd, 'BUTTON', 'Ajouter un fichier .gitignore ' +
    '(*.EXE, *.OBJ, *.TMP, *.BAK)', BS_AUTOCHECKBOX Or WS_TABSTOP, 12, 196,
    W - 24, 20, IdPriv);
  DButtons(W, H, 'Cr'#233'er le d'#233'p'#244't');
  DlgShow;
  WFocus(DC[IdName]);
  ModalLoop;
  NewRepoDialog := DlgRes = IDOK;
End;

{ ---- ajouter un depot local ---- }

Function AddLocalDialog : Boolean;
Const W = 470; H = 126;
Begin
  AddLocalDialog := False;
  DlgKind := DgAdd;
  If DlgCreate('Ajouter un d'#233'p'#244't local', W, H) = 0 Then Exit;
  Lbl(DlgWnd, 'Chemin local du d'#233'p'#244't :', 12, 10, W - 24);
  Dummy := DEdit(IdPath, 12, 32, W - 132, CloneRoot, False);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Parcourir...', WS_TABSTOP, W - 112, 30,
    100, 26, IdBrowse);
  DButtons(W, H, 'Ajouter le d'#233'p'#244't');
  DlgShow;
  WFocus(DC[IdPath]);
  SelAllText(DC[IdPath]);
  ModalLoop;
  AddLocalDialog := DlgRes = IDOK;
End;

{ ---- options ---- }

Procedure OptShowLogin;
Begin
  If GhLogin <> '' Then SetText(DC[IdLogin], 'Connect'#233' '#224' GitHub : '
    + GhLogin)
  Else If GhToken <> '' Then SetText(DC[IdLogin], 'Jeton enregistr'#233' ' +
    '(non v'#233'rifi'#233')')
  Else SetText(DC[IdLogin], 'Non connect'#233' '#224' GitHub.com');
End;

Function OptionsDialog : Boolean;
Const W = 500; H = 404;
Begin
  OptionsDialog := False;
  DlgKind := DgOptions;
  If DlgCreate('Options', W, H) = 0 Then Exit;
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Compte GitHub.com', BS_GROUPBOX, 8, 6,
    W - 16, 126, 0);
  DC[IdLogin] := Ctl(DlgWnd, 'STATIC', '', 0, 20, 26, W - 40, 16, IdLogin);
  Lbl(DlgWnd, 'Jeton d''acc'#232's personnel (github.com > Settings > ' +
    'Developer settings) :', 20, 46, W - 40);
  Dummy := DEdit(IdToken, 20, 66, W - 40, GhToken, True);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Se connecter', WS_TABSTOP, 20, 96, 130,
    26, IdSignIn);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Se d'#233'connecter', WS_TABSTOP, 158, 96,
    150, 26, IdSignOut);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Identit'#233' Git (auteur des commits)',
    BS_GROUPBOX, 8, 140, W - 16, 86, 0);
  Lbl(DlgWnd, 'Nom :', 20, 164, 80);
  Dummy := DEdit(IdUName, 110, 160, W - 130, DefName, False);
  Lbl(DlgWnd, 'Courriel :', 20, 194, 80);
  Dummy := DEdit(IdUMail, 110, 190, W - 130, DefEmail, False);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Avanc'#233, BS_GROUPBOX, 8, 234, W - 16,
    122, 0);
  Lbl(DlgWnd, 'Proxy HTTP (h'#244'te:port ; vide : SET HTTP_PROXY ou direct) :', 20,
    254, W - 40);
  Dummy := DEdit(IdProxy, 20, 272, W - 40, ProxyStr, False);
  Lbl(DlgWnd, 'Dossier de clonage par d'#233'faut :', 20, 300, W - 40);
  Dummy := DEdit(IdRoot, 20, 320, W - 152, CloneRoot, False);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Parcourir...', WS_TABSTOP, W - 124, 318,
    104, 26, IdBrowse);
  DButtons(W, H, 'Enregistrer');
  OptShowLogin;
  DlgShow;
  WFocus(DC[IdToken]);
  ModalLoop;
  OptionsDialog := DlgRes = IDOK;
End;

Procedure OptionsCommand(Id, Code : LongInt);
Var S : String;
Begin
  Case Id Of
    IdSignIn :
    Begin
      GhToken := DText(IdToken);
      ProxyStr := DText(IdProxy);
      GhLogin := '';
      If GhToken = '' Then
      Begin
        ErrBox('Entrez votre jeton d''acc'#232's personnel GitHub.');
        Exit;
      End;
      SetPtr(True);
      If Not GhSignIn Then
      Begin
        SetPtr(False);
        ErrBox('Connexion '#224' GitHub impossible : ' + GitErr);
      End
      Else IniSet('Compte', 'Login', GhLogin);
      SetPtr(False);
      OptShowLogin;
    End;
    IdSignOut :
    Begin
      GhToken := ''; GhLogin := ''; GhN := 0;
      SetText(DC[IdToken], '');
      IniSet('Compte', 'Jeton', '');
      IniSet('Compte', 'Login', '');
      OptShowLogin;
    End;
    IdBrowse :
    Begin
      S := DText(IdRoot);
      If BrowseFolder('Dossier de clonage par d'#233'faut :', S) Then
        SetText(DC[IdRoot], S);
    End;
    IDOK :
    Begin
      If DText(IdToken) <> GhToken Then GhLogin := '';
      GhToken := DText(IdToken);
      DefName := DText(IdUName); DefEmail := DText(IdUMail);
      ProxyStr := DText(IdProxy);
      S := DText(IdRoot);
      If S <> '' Then CloneRoot := S;
      IniSet('Compte', 'Jeton', GhToken);
      IniSet('Compte', 'Login', GhLogin);
      IniSet('Identite', 'Nom', DefName);
      IniSet('Identite', 'Courriel', DefEmail);
      IniSet('Options', 'Proxy', ProxyStr);
      IniSet('Options', 'Dossier', CloneRoot);
      DlgRes := IDOK; DlgDone := True;
    End;
    IDCANCEL :
    Begin
      DlgRes := IDCANCEL; DlgDone := True;
    End;
  End;
End;

{ ---- publier sur GitHub ---- }

Function PublishDialog : Boolean;
Const W = 440; H = 206;
Begin
  PublishDialog := False;
  DlgKind := DgPublish;
  If DlgCreate('Publier le d'#233'p'#244't sur GitHub.com', W, H) = 0 Then
    Exit;
  Lbl(DlgWnd, 'Nom :', 12, 10, 100);
  Dummy := DEdit(IdName, 12, 30, W - 24, RepoTitle(RepoCur), False);
  Lbl(DlgWnd, 'Description :', 12, 62, 200);
  Dummy := DEdit(IdDesc, 12, 82, W - 24, '', False);
  DC[IdPriv] := Ctl(DlgWnd, 'BUTTON', 'Garder ce code priv'#233,
    BS_AUTOCHECKBOX Or WS_TABSTOP, 12, 114, W - 24, 20, IdPriv);
  SetCheck(DC[IdPriv], True);
  Lbl(DlgWnd, 'Compte : ' + GhLogin, 12, 142, W - 24);
  DButtons(W, H, 'Publier le d'#233'p'#244't');
  DlgShow;
  WFocus(DC[IdName]);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    OpName := DlgOut[0]; OpDesc := DlgOut[1];
    OpPriv := DlgOut[2] = '1';
    PublishDialog := True;
  End;
End;

{ ---- fusionner ---- }

Function MergeDialog(Var Ref : String) : Boolean;
Const W = 380; H = 310;
Var I : LongInt;
Begin
  MergeDialog := False;
  DlgKind := DgMerge;
  MergeN := 0;
  RefsList(LocRefs, 'refs/heads/');
  For I := 0 To LocRefs.N - 1 Do
    If (LocRefs.Name[I] <> 'refs/heads/' + CurBranch) And (MergeN < 200) Then
    Begin
      MergeRefs[MergeN] := LocRefs.Name[I]; Inc(MergeN);
    End;
  RefsList(LocRefs, 'refs/remotes/');
  For I := 0 To LocRefs.N - 1 Do
    If (Copy(LocRefs.Name[I], Length(LocRefs.Name[I]) - 4, 5) <> '/HEAD')
       And (MergeN < 200) Then
    Begin
      MergeRefs[MergeN] := LocRefs.Name[I]; Inc(MergeN);
    End;
  If MergeN = 0 Then
  Begin
    ErrBox('Il n''y a aucune autre branche '#224' fusionner.');
    Exit;
  End;
  If DlgCreate('Fusionner dans ' + Utf8ToAnsi(CurBranch), W, H) = 0 Then Exit;
  Lbl(DlgWnd, 'Choisissez la branche '#224' fusionner dans ' +
    Utf8ToAnsi(CurBranch) + ' :', 12, 10, W - 24);
  DC[IdList] := Ctl(DlgWnd, 'LISTBOX', '', WS_BORDER Or WS_VSCROLL Or
    LBS_NOTIFY Or WS_TABSTOP, 12, 32, W - 24, H - 82, IdList);
  For I := 0 To MergeN - 1 Do
    If Copy(MergeRefs[I], 1, 11) = 'refs/heads/' Then
      LbAdd(DC[IdList], Utf8ToAnsi(Copy(MergeRefs[I], 12, 120)))
    Else LbAdd(DC[IdList], Utf8ToAnsi(Copy(MergeRefs[I], 14, 120)));
  LbSetSel(DC[IdList], 0);
  DButtons(W, H, 'Fusionner');
  DlgShow;
  WFocus(DC[IdList]);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    Ref := DlgOut[0];
    MergeDialog := True;
  End;
End;

{ ---- identifiants HTTP ---- }

Function CredDialog(Const Host : String) : Boolean;
Const W = 400; H = 180;
Begin
  CredDialog := False;
  DlgKind := DgCred;
  If DlgCreate('Authentification', W, H) = 0 Then Exit;
  Lbl(DlgWnd, 'Le serveur ' + Host + ' demande une identification.', 12,
    10, W - 24);
  Lbl(DlgWnd, 'Utilisateur :', 12, 42, 110);
  Dummy := DEdit(IdUser, 130, 38, W - 142, CredUser, False);
  Lbl(DlgWnd, 'Mot de passe :', 12, 74, 110);
  Dummy := DEdit(IdPass, 130, 70, W - 142, '', True);
  Lbl(DlgWnd, '(GitHub : jeton d''acc'#232's personnel)', 130, 98,
    W - 142);
  DButtons(W, H, 'OK');
  DlgShow;
  WFocus(DC[IdUser]);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    CredHost := LowStr(Host);
    CredUser := DlgOut[0]; CredPass := DlgOut[1];
    CredDialog := True;
  End;
End;

{ ---- parametres du depot ---- }

Function RepoSetDialog : Boolean;
Const W = 500; H = 220;
Begin
  RepoSetDialog := False;
  DlgKind := DgRepoSet;
  If DlgCreate('Param'#232'tres du d'#233'p'#244't', W, H) = 0 Then Exit;
  Lbl(DlgWnd, 'D'#233'p'#244't distant principal (origin) :', 12, 10, W - 24);
  Dummy := DEdit(IdUrl, 12, 30, W - 24, CfgGet('remote', 'origin', 'url'),
    False);
  Dummy := Ctl(DlgWnd, 'BUTTON', 'Identit'#233' pour ce d'#233'p'#244't ' +
    '(vide : identit'#233' des Options)', BS_GROUPBOX, 8, 62, W - 16, 96, 0);
  Lbl(DlgWnd, 'Nom :', 20, 88, 80);
  Dummy := DEdit(IdUName, 110, 84, W - 130,
    Utf8ToAnsi(CfgGet('user', '', 'name')), False);
  Lbl(DlgWnd, 'Courriel :', 20, 120, 80);
  Dummy := DEdit(IdUMail, 110, 116, W - 130, CfgGet('user', '', 'email'),
    False);
  DButtons(W, H, 'Enregistrer');
  DlgShow;
  WFocus(DC[IdUrl]);
  ModalLoop;
  RepoSetDialog := DlgRes = IDOK;
End;

Procedure DlgCommand(Id, Code : LongInt);
Var S : String; I : LongInt;
Begin
  If DlgKind = DgClone Then
  Begin
    CloneCommand(Id, Code); Exit;
  End;
  If DlgKind = DgOptions Then
  Begin
    OptionsCommand(Id, Code); Exit;
  End;
  If DlgKind = DgBrowse Then
  Begin
    FbCommand(Id, Code); Exit;
  End;
  Case Id Of
    IdBrowse :
    Begin
      S := DText(IdPath);
      If BrowseFolder('Choisissez un dossier :', S) Then SetText(DC[IdPath], S);
    End;
    IdList :
      If (Code = LBN_DBLCLK) And (DlgKind = DgMerge) Then
        DlgCommand(IDOK, 0);
    IDOK :
    Begin
      Case DlgKind Of
        DgInput : DlgText := CtlText(InpEdit);
        DgNew :
        Begin
          If (DText(IdName) = '') Or (Pos('\', DText(IdName)) > 0) Or
             (Pos(':', DText(IdName)) > 0) Then
          Begin
            ErrBox('Entrez un nom de d'#233'p'#244't valable (sans \ ni :).');
            Exit;
          End;
          DlgOut[0] := DText(IdName); DlgOut[1] := DText(IdDesc);
          DlgOut[2] := DText(IdPath);
          DlgOut[3] := '0'; DlgOut[4] := '0';
          If Checked(DC[IdReadme]) Then DlgOut[3] := '1';
          If Checked(DC[IdPriv]) Then DlgOut[4] := '1';
        End;
        DgAdd : DlgOut[0] := DText(IdPath);
        DgPublish :
        Begin
          If DText(IdName) = '' Then
          Begin
            ErrBox('Entrez le nom du d'#233'p'#244't GitHub.'); Exit;
          End;
          DlgOut[0] := DText(IdName); DlgOut[1] := DText(IdDesc);
          If Checked(DC[IdPriv]) Then DlgOut[2] := '1' Else DlgOut[2] := '0';
        End;
        DgMerge :
        Begin
          I := LbSel(DC[IdList]);
          If (I < 0) Or (I >= MergeN) Then Exit;
          DlgOut[0] := MergeRefs[I];
        End;
        DgCred :
        Begin
          DlgOut[0] := DText(IdUser); DlgOut[1] := CtlText(DC[IdPass]);
        End;
        DgRepoSet :
        Begin
          S := NormUrl(DText(IdUrl));
          If S <> '' Then SetRemote('origin', S)
          Else If CfgGet('remote', 'origin', 'url') <> '' Then
            CfgSet('remote', 'origin', 'url', '');
          If (DText(IdUName) <> '') Or (CfgGet('user', '', 'name') <> '') Then
            CfgSet('user', '', 'name', AnsiToUtf8(DText(IdUName)));
          If (DText(IdUMail) <> '') Or (CfgGet('user', '', 'email') <> '')
          Then CfgSet('user', '', 'email', DText(IdUMail));
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

{ seconde saisie (Nouveau dossier, par-dessus Parcourir) : etat de la
  boite appelante garde comme dans BrowseFolder }
Function InputBox2(Const Title, Prompt : String; Var S : String) : Boolean;
Var SvWnd, SvFrame, SvKind, SvRes, SvPrev, SvOwner, I : LongInt;
    SvDone : Boolean; SvDC : Array[200..230] Of LongInt; SvText : String;
Begin
  SvWnd := DlgWnd; SvFrame := DlgFrame; SvKind := DlgKind; SvRes := DlgRes;
  SvDone := DlgDone; SvPrev := DlgPrevFocus; SvOwner := DlgOwner;
  SvText := DlgText;
  For I := 200 To 230 Do SvDC[I] := DC[I];
  InputBox2 := InputBox(Title, Prompt, S);
  DlgWnd := SvWnd; DlgFrame := SvFrame; DlgKind := SvKind; DlgRes := SvRes;
  DlgDone := SvDone; DlgPrevFocus := SvPrev; DlgOwner := SvOwner;
  DlgText := SvText;
  For I := 200 To 230 Do DC[I] := SvDC[I];
  If DlgFrame <> 0 Then Dummy0 := WinSetActiveWindow(HWND_DESKTOP, DlgFrame);
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
      BigLock;
      Dc := PaintBegin(H);
      Bar(Dc, 0, 0, 4000, PaintH, ClrFace);
      PaintEnd(Dc);
      BigUnlock;
    End;
    PM_WM_ERASEBACKGROUND : R := 0;
    PM_WM_COMMAND :
    Begin
      BigLock;
      If H = DlgWnd Then DlgCommand(Mp1 And $FFFF, BN_CLICKED);
      BigUnlock;
    End;
    PM_WM_CONTROL :
    Begin
      Id := Mp1 And $FFFF;
      If Id <= 255 Then K := CtlKind[Id] Else K := 0;
      Code := -1;
      Case K Of
        1 : If ((Mp1 Shr 16) And $FFFF) = PM_BN_CLICKED Then Code := BN_CLICKED;
        2 : If ((Mp1 Shr 16) And $FFFF) = PM_EN_CHANGE Then Code := EN_CHANGE;
        3 :
          If ((Mp1 Shr 16) And $FFFF) = PM_LN_SELECT Then Code := LBN_SELCHANGE
          Else If ((Mp1 Shr 16) And $FFFF) = PM_LN_ENTER Then Code := LBN_DBLCLK;
      End;
      If (Code >= 0) And (H = DlgWnd) Then
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
        BigLock;
        If DlgKind = DgBrowse Then FbCommand(IDCANCEL, 0)
        Else
        Begin
          DlgRes := IDCANCEL; DlgDone := True;
        End;
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
  TbH = 52; StH = 22; TabH = 26; ChkH = 24; ComH = 176; HdrH = 74;
  FilesH = 126;
  IdSum = 20; IdDescE = 21; IdCommit = 22;
  IdWClone = 23; IdWNew = 24; IdWAdd = 25;
  CmNewRepo = 101; CmAddRepo = 102; CmClone = 103; CmOptions = 104;
  CmExit = 105;
  CmCheckAll = 111; CmUncheckAll = 112; CmDiscardAll = 113;
  CmCopyPath = 114; CmIgnore = 115; CmDiscardOne = 116; CmOpenFile = 117;
  CmViewChg = 121; CmViewHist = 122; CmRepoList = 123; CmBranchList = 124;
  CmRefresh = 125;
  CmPush = 131; CmPull = 132; CmFetch = 133; CmExplorer = 134;
  CmDos = 135; CmRepoSet = 136; CmRemoveRepo = 137; CmPublish = 138;
  CmViewGh = 139;
  CmNewBranch = 141; CmRenBranch = 142; CmDelBranch = 143; CmMerge = 144;
  CmAbout = 151; CmGhHelp = 152;
  CmBrLocal = 1000; CmBrRemote = 1400; CmRepo = 2000;

Var
  MainMenu, MFile, MEdit, MView, MRepo, MBranch, MHelp : LongInt;
  ESum, EDesc, BCommit, BWClone, BWNew, BWAdd : LongInt;
  CW0, CH0, LX, CY0, CY1 : LongInt;
  TbDown : LongInt;
  Unchk : Array[0..199] Of String[120];
  UnchkN : LongInt;
  BrList : Array[0..299] Of String[120];
  BrN, BrRemN : LongInt;
  Refreshing : Boolean;
  LastRefresh : LongInt;
  FrN : LongInt;
  FrX1, FrY1, FrX2, FrY2 : Array[0..3] Of LongInt;  { cadres creux des vues }
  HoleN : LongInt;                     { controles de la fenetre (trous) }
  HoleX1, HoleY1, HoleX2, HoleY2 : Array[0..7] Of LongInt;

Procedure Layout; Forward;
Procedure MenuState; Forward;

{ place une vue dans un cadre creux (2 points) }
Procedure PlaceF(H, X, Y, W, Hh : LongInt);
Begin
  Place(H, X + 2, Y + 2, W - 4, Hh - 4);
  If FrN < 4 Then
  Begin
    FrX1[FrN] := X; FrY1[FrN] := Y; FrX2[FrN] := X + W; FrY2[FrN] := Y + Hh;
    Inc(FrN);
  End;
End;

{ place un controle de la fenetre principale (le fond est peint autour) }
Procedure PlaceC(H, X, Y, W, Hh : LongInt);
Begin
  Place(H, X, Y, W, Hh);
  If HoleN < 8 Then
  Begin
    HoleX1[HoleN] := X; HoleY1[HoleN] := Y; HoleX2[HoleN] := X + W;
    HoleY2[HoleN] := Y + Hh;
    Inc(HoleN);
  End;
End;

{ rectangle plein sans recouvrir les controles places par PlaceC }
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
  BarHoles(Dc, X1, MaxL(Y1, HoleY1[J]), MaxL(X1, HoleX1[J]), MinL(Y2, HoleY2[J]), C, J + 1);
  BarHoles(Dc, MinL(X2, HoleX2[J]), MaxL(Y1, HoleY1[J]), X2, MinL(Y2, HoleY2[J]), C, J + 1);
End;

Procedure InvalidateStatus;
Begin
  If MainWnd = 0 Then Exit;
  InvalRect(MainWnd, 0, CH0 - StH, CW0, CH0);
  InvalRect(MainWnd, 0, 0, CW0, TbH);
End;

Procedure PaintNow;
Begin
  If MainWnd = 0 Then Exit;
  InvalidateStatus;
  BigUnlock;
  Dummy0 := WinUpdateWindow(MainWnd);
  BigLock;
End;

Procedure SetStatus(Const S : String);
Begin
  StatusTxt := S;
  If TestMode Then Log('GITCLI : etat : ' + S);
  InvalidateStatus;
End;

Procedure Redraw;
Begin
  If MainWnd = 0 Then Exit;
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
  If CurBranch <> '' Then S := 'Valider dans ' + Utf8ToAnsi(CurBranch)
  Else S := 'Valider';
  If InMerge Then S := 'Valider la fusion';
  SetText(BCommit, Fit(S, LX - 30));
  Dummy0 := WinEnableWindow(BCommit, Ord(((CheckedCount > 0) Or InMerge) And
    (CtlText(ESum) <> '') And Not Busy));
End;

Procedure CheckedChanged;
Begin
  InvalRect(MainWnd, 0, CY0 + TabH, LX, CY0 + TabH + ChkH);
  UpdateCommitBtn;
End;

Procedure UpdateTitle;
Begin
  If MainWnd = 0 Then Exit;
  If RepoCur >= 0 Then SetText(MainWnd, RepoTitle(RepoCur) + ' - Client GitHub')
  Else SetText(MainWnd, 'Client GitHub');
End;

{ ---- selection ---- }

Procedure SelectChange(I : LongInt);
Begin
  ChgSel := I;
  If (I < 0) Or (I >= Chg.N) Then
  Begin
    DiffClear; Exit;
  End;
  DiffLoad(Chg.E^[I].Old, ShaZero, True, Chg.E^[I].Path,
    Chg.E^[I].Flag And $FF);
End;

Procedure SelectFile(I : LongInt);
Begin
  FileSel := I;
  If (I < 0) Or (I >= HFiles.N) Then
  Begin
    DiffClear; Exit;
  End;
  DiffLoad(HFiles.E^[I].Old, HFiles.E^[I].Sha, False, HFiles.E^[I].Path,
    HFiles.E^[I].Flag And $FF);
End;

Procedure SelectCommit(I : LongInt);
Begin
  HistSel := I;
  HFiles.N := 0; FileSel := -1;
  If (I >= 0) And (I < HistN) Then
  Begin
    If Not CommitRead(Hist^[I].Sha, HCommit, @HMsg) Then HMsg.N := 0;
    If CommitChanges(Hist^[I].Sha, HFiles) Then ;
  End;
  Lv[LvFiles].Top := 0;
  LvSync(LvFiles);
  LvRepaint(LvFiles);
  If HFiles.N > 0 Then SelectFile(0) Else DiffClear;
  InvalRect(MainWnd, LX, CY0, CW0, CY0 + HdrH);
End;

{ ---- actualisation du depot ---- }

Procedure RefreshRepo(Keep : Boolean);
Var I, K : LongInt; OldPath : String;
Begin
  If Refreshing Or Busy Then Exit;
  Refreshing := True;
  GitOom := False;
  LastRefresh := MsTick;
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
  Chg.N := 0; HistN := 0; HFiles.N := 0;
  CurBranch := ''; Ahead := 0; Behind := 0;
  HasRemote := False; HasUpstream := False; InMerge := False;
  ChgSel := -1; HistSel := -1; FileSel := -1;
  If RepoCur >= 0 Then
  Begin
    If Not SetRepo(RepoPath[RepoCur]) Then
    Begin
      ErrBox('Le d'#233'p'#244't ' + OemToAnsi(RepoPath[RepoCur]) +
        ' est introuvable (dossier .git absent). Il est retir'#233' de la liste.');
      RepoRemove(RepoCur);
      ReposSave;
    End
    Else
    Begin
      SetPtr(True);
      LoadIdentity;
      SetStatus('Analyse du d'#233'p'#244't...');
      If Not RepoStatus Then ErrBox('Lecture du d'#233'p'#244't : ' + GitErr);
      CurBranch := HeadBranch;
      CountAB;
      HistLoad(HeadSha, 400);
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
      SetPtr(False);
      If InMerge Then SetStatus('Fusion en cours : r'#233'solvez les ' +
        'conflits puis validez.')
      Else SetStatus(IStr(Chg.N) + ' fichier(s) modifi'#233'(s), ' +
        IStr(HistN) + ' commit(s) affich'#233'(s)');
    End;
  End
  Else SetStatus('Aucun d'#233'p'#244't ouvert');
  If View = VwChanges Then SelectChange(ChgSel)
  Else If HistN > 0 Then SelectCommit(0)
  Else DiffClear;
  For I := 0 To 2 Do LvSync(I);
  If ChgSel >= 0 Then LvVisible(LvChg);
  Layout;
  UpdateTitle;
  UpdateCommitBtn;
  MenuState;
  Redraw;
  Refreshing := False;
End;

Procedure OpenRepo(K : LongInt);
Begin
  RepoCur := K;
  ReposSave;
  View := VwChanges;
  RefreshRepo(False);
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
  If V = VwChanges Then WFocus(Lv[LvChg].H) Else WFocus(Lv[LvHist].H);
End;

{ Tab et Maj+Tab dans la fenetre principale : vue suivante (listes,
  resume, description, bouton Valider, differences) }
Procedure FocusNext(From : LongInt; Back : Boolean);
Var L : Array[0..5] Of LongInt; N, I, K : LongInt;
Begin
  N := 0;
  If RepoCur < 0 Then
  Begin
    L[0] := BWClone; L[1] := BWNew; L[2] := BWAdd; N := 3;
  End
  Else If View = VwChanges Then
  Begin
    L[0] := Lv[LvChg].H; L[1] := ESum; L[2] := EDesc; N := 3;
    L[N] := BCommit; Inc(N);
    L[N] := DiffWnd; Inc(N);
  End
  Else
  Begin
    L[0] := Lv[LvHist].H; L[1] := Lv[LvFiles].H; L[2] := DiffWnd; N := 3;
  End;
  K := -1;
  For I := 0 To N - 1 Do
    If L[I] = From Then K := I;
  If Back Then K := K - 1 Else K := K + 1;
  If K < 0 Then K := N - 1;
  If K >= N Then K := 0;
  { le bouton Valider desactive est saute }
  If (L[K] = BCommit) And Not (((CheckedCount > 0) Or InMerge) And
     (CtlText(ESum) <> '') And Not Busy) Then
  Begin
    If Back Then K := K - 1 Else K := K + 1;
    If K < 0 Then K := N - 1;
    If K >= N Then K := 0;
  End;
  WFocus(L[K]);
End;

{ ---- disposition ---- }

Procedure Layout;
Var Has, Chgv : Boolean; Y, Ri, Rw : LongInt;
Begin
  If ESum = 0 Then Exit;
  Has := RepoCur >= 0;
  Chgv := Has And (View = VwChanges);
  LX := MinL(360, MaxL(300, CW0 Div 3));
  CY0 := TbH; CY1 := CH0 - StH;
  Ri := LX + 3; Rw := CW0 - Ri;
  FrN := 0; HoleN := 0;
  Show(Lv[LvChg].H, Chgv);
  Show(ESum, Chgv); Show(EDesc, Chgv); Show(BCommit, Chgv);
  Show(Lv[LvHist].H, Has And Not Chgv);
  Show(Lv[LvFiles].H, Has And Not Chgv);
  Show(DiffWnd, Has);
  Show(BWClone, Not Has); Show(BWNew, Not Has); Show(BWAdd, Not Has);
  If Chgv Then
  Begin
    Y := CY1 - ComH;
    PlaceF(Lv[LvChg].H, 0, CY0 + TabH + ChkH, LX, Y - CY0 - TabH - ChkH);
    PlaceC(ESum, 8, Y + 10, LX - 16, 24);
    PlaceC(EDesc, 8, Y + 40, LX - 16, 88);
    PlaceC(BCommit, 8, Y + 136, LX - 16, 30);
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
    PlaceC(BWClone, CW0 Div 2 - 170, Y, 340, 32);
    PlaceC(BWNew, CW0 Div 2 - 170, Y + 42, 340, 32);
    PlaceC(BWAdd, CW0 Div 2 - 170, Y + 84, 340, 32);
  End;
End;

{ ---- dessin ---- }

Function TbX(I : LongInt) : LongInt;
Var W : LongInt;
Begin
  W := MaxL(200, MinL(260, (CW0 - 8) Div 3));
  Case I Of
    0 : TbX := 0;
    1 : TbX := W;
    2 : TbX := W * 2;
    Else TbX := MaxL(W * 3, CW0);
  End;
End;

Procedure IconRepo(Dc, X, Y : LongInt);
Begin
  Bar(Dc, X, Y, X + 14, Y + 18, ClrBlack);
  Bar(Dc, X + 1, Y + 1, X + 13, Y + 15, ClrWin);
  Bar(Dc, X + 3, Y + 1, X + 4, Y + 15, ClrBlack);
  Bar(Dc, X + 6, Y + 4, X + 11, Y + 5, ClrGray);
  Bar(Dc, X + 6, Y + 7, X + 11, Y + 8, ClrGray);
  Bar(Dc, X + 3, Y + 15, X + 7, Y + 20, ClrRed);
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

Procedure IconSync(Dc, X, Y, Kind : LongInt);
Var I : LongInt;
Begin
  { fleche vers le haut (pousser), le bas (tirer) ou les deux }
  If Kind <> 2 Then
  Begin
    Bar(Dc, X + 3, Y + 4, X + 5, Y + 18, ClrBlack);
    For I := 0 To 3 Do Bar(Dc, X + 3 - I, Y + 4 + I, X + 5 + I, Y + 5 + I,
      ClrBlack);
  End;
  If Kind <> 1 Then
  Begin
    Bar(Dc, X + 11, Y + 2, X + 13, Y + 16, ClrBlack);
    For I := 0 To 3 Do Bar(Dc, X + 11 - I, Y + 16 - I, X + 13 + I,
      Y + 17 - I, ClrBlack);
  End;
End;

{ petite fleche vers le bas (liste deroulante) }
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
  M := (MsTick - T) Div 60000;
  If M < 1 Then AgoTxt := 'il y a moins d''une minute'
  Else If M < 60 Then AgoTxt := 'il y a ' + IStr(M) + ' min'
  Else AgoTxt := 'il y a ' + IStr(M Div 60) + ' h';
End;

{ libelles du troisieme bouton : action de synchronisation }
Function SyncKind : LongInt;
Begin
  If Not HasRemote Then SyncKind := 1
  Else If Not HasUpstream Then SyncKind := 2
  Else If Behind > 0 Then SyncKind := 3
  Else If Ahead > 0 Then SyncKind := 4
  Else SyncKind := 5;
End;

Procedure PaintTb(Dc : LongInt);
Var I, X, X2, K : LongInt; A, B : String;
Begin
  Bar(Dc, 0, 0, CW0, TbH - 2, ClrFace);
  Bar(Dc, 0, TbH - 2, CW0, TbH - 1, ClrShadow);
  Bar(Dc, 0, TbH - 1, CW0, TbH, ClrHi);
  For I := 0 To 2 Do
  Begin
    If (I = 2) And (RepoCur < 0) Then Break;
    X := TbX(I); X2 := TbX(I + 1) - 2;
    If I = 2 Then X2 := MinL(CW0 - 4, X + 300);
    If TbDown = I Then Bevel(Dc, X + 2, 3, X2, TbH - 5, False)
    Else Bevel(Dc, X + 2, 3, X2, TbH - 5, True);
    Case I Of
      0 :
      Begin
        IconRepo(Dc, X + 12, 12);
        A := 'D'#233'p'#244't actuel';
        If RepoCur >= 0 Then B := RepoTitle(RepoCur) Else B := 'Aucun d'#233
          + 'p'#244't';
      End;
      1 :
      Begin
        IconBranch(Dc, X + 12, 13);
        A := 'Branche actuelle';
        If RepoCur < 0 Then B := '-'
        Else If CurBranch = '' Then B := '(HEAD d'#233'tach'#233'e)'
        Else B := Utf8ToAnsi(CurBranch);
      End;
      Else
      Begin
        K := SyncKind;
        If Busy Then
        Begin
          IconSync(Dc, X + 12, 14, 0);
          Case Op Of
            OpPush : A := 'Envoi vers origin';
            OpPull : A := 'Tirage depuis origin';
            OpPublish : A := 'Publication';
            OpClone : A := 'Clonage';
            Else A := 'R'#233'cup'#233'ration depuis origin';
          End;
          B := ProgTxt;
        End
        Else
          Case K Of
            1 :
            Begin
              IconSync(Dc, X + 12, 14, 1);
              A := 'Publier le d'#233'p'#244't';
              B := 'Le publier sur GitHub.com';
            End;
            2 :
            Begin
              IconSync(Dc, X + 12, 14, 1);
              A := 'Publier la branche';
              B := 'Cr'#233'er la branche sur origin';
            End;
            3 :
            Begin
              IconSync(Dc, X + 12, 14, 2);
              A := 'Tirer origin  ' + #25 + IStr(Behind);
              If Ahead > 0 Then A := A + ' ' + #24 + IStr(Ahead);
              B := 'R'#233'cup'#233'r'#233' ' + AgoTxt(LastFetch);
            End;
            4 :
            Begin
              IconSync(Dc, X + 12, 14, 1);
              A := 'Pousser origin  ' + #24 + IStr(Ahead);
              B := 'R'#233'cup'#233'r'#233' ' + AgoTxt(LastFetch);
            End;
            Else
            Begin
              IconSync(Dc, X + 12, 14, 0);
              A := 'R'#233'cup'#233'rer origin';
              B := 'R'#233'cup'#233'r'#233' ' + AgoTxt(LastFetch);
            End;
          End;
      End;
    End;
    Txt(Dc, X + 36, 8, Fit(A, X2 - X - 54), ClrShadow);
    Txt(Dc, X + 36, 26, Fit(B, X2 - X - 54), ClrBlack);
    If I < 2 Then IconDrop(Dc, X2 - 16, 23);
  End;
End;

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
    If I = View Then Bar(Dc, X + 1, Y + 1, X + W - 2, CY0 + TabH, ClrFace);
    Bar(Dc, X, Y, X + W - 1, Y + 1, ClrHi);
    Bar(Dc, X, Y, X + 1, CY0 + TabH, ClrHi);
    Bar(Dc, X + W - 2, Y + 1, X + W - 1, CY0 + TabH, ClrShadow);
    Bar(Dc, X + W - 1, Y + 2, X + W, CY0 + TabH, ClrDark);
    Txt(Dc, X + (W - Length(Fit(S, W - 8)) * CW) Div 2, Y + 3, Fit(S, W - 8), ClrBlack);
  End;
  Bar(Dc, 0, CY0 + TabH - 1, LX, CY0 + TabH, ClrHi);
  X := 4 + View * W;
  Bar(Dc, X + 1, CY0 + TabH - 1, X + W - 2, CY0 + TabH, ClrFace);
End;

Procedure PaintCommitHdr(Dc : LongInt);
Var S : String; I : LongInt;
Begin
  Bar(Dc, LX + 3, CY0, CW0, CY0 + HdrH, ClrFace);
  If (HistSel < 0) Or (HistSel >= HistN) Then Exit;
  Txt(Dc, LX + 12, CY0 + 6, Fit(Utf8ToAnsi(HCommit.Summary), CW0 - LX - 24),
    ClrBlack);
  { nom de l'auteur (sans le courriel, comme GitHub Desktop) }
  S := Utf8ToAnsi(HCommit.Author);
  I := Pos(' <', S);
  If I > 0 Then S := Copy(S, 1, I - 1);
  Txt(Dc, LX + 12, CY0 + 28, Fit(S + '   ' + UnixToStr(HCommit.ATime) +
    ' UTC', CW0 - LX - 24), ClrNavy);
  S := 'Commit ' + Copy(ShaHex(Hist^[HistSel].Sha), 1, 10);
  If HCommit.PN > 1 Then S := S + '   (fusion de ' + IStr(HCommit.PN) +
    ' parents)';
  S := S + '   ' + IStr(HFiles.N) + ' fichier(s) modifi'#233'(s)';
  Txt(Dc, LX + 12, CY0 + 50, Fit(S, CW0 - LX - 24), ClrShadow);
End;

Procedure PaintWelcome(Dc : LongInt);
Var Y : LongInt; S : String;
Begin
  BarHoles(Dc, 0, CY0, CW0, CY1, ClrFace, 0);
  Y := CY0 + 36;
  IconRepo(Dc, CW0 Div 2 - 7, Y);
  S := 'Bienvenue dans le Client GitHub !';
  Txt(Dc, MaxL(4, (CW0 - Length(S) * CW) Div 2), Y + 34, S, ClrBlack);
  S := 'Clonez un d'#233'p'#244't de GitHub.com, cr'#233'ez-en un nouveau ou ' +
    'ajoutez-en un';
  Txt(Dc, MaxL(4, (CW0 - Length(S) * CW) Div 2), Y + 66, S, ClrShadow);
  S := 'qui existe d'#233'j'#224' sur votre ordinateur.';
  Txt(Dc, MaxL(4, (CW0 - Length(S) * CW) Div 2), Y + 84, S, ClrShadow);
End;

Procedure MainPaint(H : LongInt);
Var Dc, N, Y, I : LongInt; S : String;
Begin
  Dc := PaintBegin(H);
  { cadres creux des vues (leur interieur est dessine par les vues) }
  If RepoCur >= 0 Then
    For I := 0 To FrN - 1 Do
      Bevel(Dc, FrX1[I], FrY1[I], FrX2[I], FrY2[I], False);
  PaintTb(Dc);
  If RepoCur < 0 Then PaintWelcome(Dc)
  Else
  Begin
    PaintTabs(Dc);
    Bar(Dc, LX, CY0, LX + 3, CY1, ClrFace);
    If View = VwChanges Then
    Begin
      Y := CY0 + TabH;
      Bar(Dc, 0, Y, LX, Y + ChkH, ClrFace);
      N := CheckedCount;
      CheckBox(Dc, 5, Y + 5, N > 0, (N > 0) And (N < Chg.N));
      S := IStr(Chg.N) + ' fichier(s) modifi'#233'(s)';
      If (N <> Chg.N) Then S := S + ', ' + IStr(N) + ' coch'#233'(s)';
      Txt(Dc, 24, Y + 4, Fit(S, LX - 30), ClrBlack);
      BarHoles(Dc, 0, CY1 - ComH, LX, CY1, ClrFace, 0);
      Bar(Dc, 0, CY1 - ComH, LX, CY1 - ComH + 1, ClrShadow);
      Bar(Dc, 0, CY1 - ComH + 1, LX, CY1 - ComH + 2, ClrHi);
    End
    Else
    Begin
      PaintCommitHdr(Dc);
      Bar(Dc, LX + 3, CY0 + HdrH + FilesH, CW0, CY0 + HdrH + FilesH + 3,
        ClrFace);
    End;
  End;
  { barre d'etat }
  Bar(Dc, 0, CH0 - StH, CW0, CH0, ClrFace);
  Thin(Dc, 2, CH0 - StH + 2, CW0 - 2, CH0 - 1, False);
  If Busy Then S := ProgLine Else S := StatusTxt;
  Txt(Dc, 6, CH0 - StH + 4, Fit(S, CW0 - 12), ClrBlack);
  PaintEnd(Dc);
End;

{ ---- menus ---- }

Procedure BuildMenus;
Begin
  MainMenu := CreateMenu;
  MFile := CreatePopupMenu;
  MItem(MFile, CmNewRepo, '~Nouveau d'#233'p'#244't...'#9'Ctrl+N');
  MItem(MFile, CmAddRepo, '~Ajouter un d'#233'p'#244't local...'#9'Ctrl+O');
  MItem(MFile, CmClone, '~Cloner un d'#233'p'#244't...'#9'Ctrl+Maj+O');
  MItem(MFile, 0, '');
  MItem(MFile, CmOptions, '~Options...'#9'Ctrl+,');
  MItem(MFile, 0, '');
  MItem(MFile, CmExit, '~Quitter'#9'F3');
  MSub(MainMenu, MFile, '~Fichier');
  MEdit := CreatePopupMenu;
  MItem(MEdit, CmCheckAll, '~Cocher tous les fichiers'#9'Ctrl+A');
  MItem(MEdit, CmUncheckAll, '~D'#233'cocher tous les fichiers');
  MItem(MEdit, 0, '');
  MItem(MEdit, CmCopyPath, 'Copier le ~chemin du fichier');
  MItem(MEdit, CmOpenFile, '~Ouvrir le fichier');
  MItem(MEdit, CmIgnore, 'Ajouter le fichier '#224' .~gitignore');
  MItem(MEdit, 0, '');
  MItem(MEdit, CmDiscardOne, '~Annuler les modifications du fichier...');
  MItem(MEdit, CmDiscardAll, 'Annuler ~toutes les modifications...'#9 +
    'Ctrl+Maj+Suppr');
  MSub(MainMenu, MEdit, '~Edition');
  MView := CreatePopupMenu;
  MItem(MView, CmViewChg, '~Modifications'#9'Ctrl+1');
  MItem(MView, CmViewHist, '~Historique'#9'Ctrl+2');
  MItem(MView, 0, '');
  MItem(MView, CmRepoList, 'Liste des ~d'#233'p'#244'ts'#9'Ctrl+T');
  MItem(MView, CmBranchList, 'Liste des ~branches'#9'Ctrl+B');
  MItem(MView, 0, '');
  MItem(MView, CmRefresh, '~Actualiser'#9'F5');
  MSub(MainMenu, MView, '~Affichage');
  MRepo := CreatePopupMenu;
  MItem(MRepo, CmPush, '~Pousser'#9'Ctrl+P');
  MItem(MRepo, CmPull, '~Tirer'#9'Ctrl+Maj+P');
  MItem(MRepo, CmFetch, '~R'#233'cup'#233'rer'#9'Ctrl+Maj+T');
  MItem(MRepo, CmPublish, 'P~ublier sur GitHub.com...');
  MItem(MRepo, 0, '');
  MItem(MRepo, CmViewGh, '~Voir sur GitHub'#9'Ctrl+Maj+G');
  MItem(MRepo, CmExplorer, 'Ouvrir dans l''~Explorateur'#9'Ctrl+Maj+F');
  MItem(MRepo, CmDos, 'Ouvrir dans l''~Invite de commandes');
  MItem(MRepo, 0, '');
  MItem(MRepo, CmRepoSet, 'P~aram'#232'tres du d'#233'p'#244't...');
  MItem(MRepo, CmRemoveRepo, 'Retirer de la ~liste');
  MSub(MainMenu, MRepo, '~D'#233'p'#244't');
  MBranch := CreatePopupMenu;
  MItem(MBranch, CmNewBranch, '~Nouvelle branche...'#9'Ctrl+Maj+N');
  MItem(MBranch, CmRenBranch, '~Renommer...');
  MItem(MBranch, CmDelBranch, '~Supprimer...');
  MItem(MBranch, 0, '');
  MItem(MBranch, CmMerge, '~Fusionner dans la branche actuelle...'#9 +
    'Ctrl+Maj+M');
  MSub(MainMenu, MBranch, '~Branche');
  MHelp := CreatePopupMenu;
  MItem(MHelp, CmGhHelp, '~Raccourcis clavier');
  MItem(MHelp, 0, '');
  MItem(MHelp, CmAbout, '~A propos du Client GitHub...');
  MSub(MainMenu, MHelp, '~Aide');
  SetMenu(MainMenu);
End;

Procedure MenuState;
Var Has, Free : Boolean; I : LongInt;
Begin
  If MainWnd = 0 Then Exit;
  Has := RepoCur >= 0;
  Free := Not Busy;
  For I := CmCheckAll To CmOpenFile Do MEnable(MEdit, I, Has And Free);
  MEnable(MView, CmViewChg, Has); MEnable(MView, CmViewHist, Has);
  MEnable(MView, CmBranchList, Has And Free);
  MEnable(MView, CmRefresh, Has And Free);
  For I := CmPush To CmViewGh Do MEnable(MRepo, I, Has And Free);
  For I := CmNewBranch To CmMerge Do MEnable(MBranch, I, Has And Free);
  MEnable(MFile, CmNewRepo, Free); MEnable(MFile, CmAddRepo, Free);
  MEnable(MFile, CmClone, Free);
  MCheck(MView, CmViewChg, Has And (View = VwChanges));
  MCheck(MView, CmViewHist, Has And (View = VwHistory));
End;

{ ---- commandes ---- }

Function ValidBranch(Const S : String) : Boolean;
Var I : LongInt;
Begin
  ValidBranch := False;
  If (S = '') Or (S[1] = '-') Or (S[1] = '/') Or (S[Length(S)] = '/') Or
     (Pos('..', S) > 0) Or (S = 'HEAD') Or
     (LowStr(Copy(S, Length(S) - 4, 5)) = '.lock') Then Exit;
  For I := 1 To Length(S) Do
    If (S[I] <= ' ') Or (S[I] In ['~', '^', ':', '?', '*', '[', '\']) Then
      Exit;
  ValidBranch := True;
End;

Function Clean : Boolean;
Var I : LongInt;
Begin
  Clean := True;
  For I := 0 To Chg.N - 1 Do
    If (Chg.E^[I].Flag And $FF) <> StNew Then Clean := False;
End;

{ texte de la description (MLE : lignes separees par LF) }
Function DescText(Var M : TBuf) : Boolean;
Var Big : Array[0..4095] Of Byte; N, I : LongInt; D : String;
Begin
  DescText := False;
  N := WinQueryWindowText(EDesc, 4000, LongInt(@Big));
  If N <= 0 Then Exit;
  While (N > 0) And ((Big[N - 1] = 10) Or (Big[N - 1] = 13) Or (Big[N - 1] = 32)) Do Dec(N);
  If N <= 0 Then Exit;
  BufStr(M, #10#10);
  D := '';
  For I := 0 To N - 1 Do
    If Big[I] <> 13 Then
    Begin
      D := D + Chr(Big[I]);
      If Length(D) >= 120 Then
      Begin
        BufStr(M, AnsiToUtf8(UnDisp(D))); D := '';
      End;
    End;
  BufStr(M, AnsiToUtf8(UnDisp(D)));
  DescText := True;
End;

Procedure DoCommitCmd;
Var M : TBuf; S : String; H : TSha;
Begin
  If Busy Or (RepoCur < 0) Then Exit;
  S := TrimS(CtlText(ESum));
  If S = '' Then
  Begin
    ErrBox('Entrez un r'#233'sum'#233' pour ce commit.'); Exit;
  End;
  If (CheckedCount = 0) And Not InMerge Then
  Begin
    ErrBox('Cochez au moins un fichier '#224' valider.'); Exit;
  End;
  BufInit(M);
  BufStr(M, AnsiToUtf8(S));
  If DescText(M) Then ;
  SetPtr(True);
  If DoCommit(M, H) Then
  Begin
    SetText(ESum, ''); SetText(EDesc, '');
    WFocus(Lv[LvChg].H);
    RefreshRepo(False);
    SetStatus('Commit ' + Copy(ShaHex(H), 1, 7) + ' cr'#233#233' dans ' +
      Utf8ToAnsi(CurBranch) + ' : ' + S);
  End
  Else ErrBox('Validation impossible : ' + GitErr);
  SetPtr(False);
  BufFree(M);
End;

Procedure CheckoutCmd(Const Name : String; FromRemote : Boolean);
Var H : TSha;
Begin
  If Not Clean Then
  Begin
    ErrBox('Vous avez des modifications non valid'#233'es. Validez-les ou ' +
      'annulez-les avant de changer de branche.');
    Exit;
  End;
  If FromRemote Then
  Begin
    { cree la branche locale qui suit origin/Name }
    If Not RefRead('refs/remotes/origin/' + Name, H) Then Exit;
    If Not RefWrite('refs/heads/' + Name, H) Then
    Begin
      ErrBox('Cr'#233'ation de la branche impossible.'); Exit;
    End;
    SetUpstream(Name, 'origin');
  End;
  SetPtr(True);
  If SwitchBranch(Name) Then SetStatus('Branche ' + Utf8ToAnsi(Name) +
    ' extraite')
  Else ErrBox('Changement de branche impossible : ' + GitErr);
  SetPtr(False);
  RefreshRepo(False);
End;

Procedure NewBranchCmd;
Var S : String;
Begin
  S := '';
  If Not InputBox('Cr'#233'er une branche', 'Nom de la nouvelle branche ' +
    '(cr'#233#233'e '#224' partir de ' + Utf8ToAnsi(CurBranch) + ') :', S) Then Exit;
  S := AnsiToUtf8(S);
  While Pos(' ', S) > 0 Do S[Pos(' ', S)] := '-';
  If Not ValidBranch(S) Then
  Begin
    ErrBox('Nom de branche non valable : ' + S); Exit;
  End;
  If FileExist(GitPath('refs/heads/' + S)) Then
  Begin
    ErrBox('La branche ' + S + ' existe d'#233'j'#224'.'); Exit;
  End;
  If Not ShaIsZero(HeadSha) Then
    If Not RefWrite('refs/heads/' + S, HeadSha) Then
    Begin
      ErrBox('Cr'#233'ation de la branche impossible.'); Exit;
    End;
  SetHead('refs/heads/' + S);
  RefreshRepo(True);
  SetStatus('Branche ' + Utf8ToAnsi(S) + ' cr'#233#233'e et extraite');
End;

Procedure RenameBranchCmd;
Var S, Old : String; H : TSha;
Begin
  If CurBranch = '' Then Exit;
  Old := CurBranch;
  S := Utf8ToAnsi(Old);
  If Not InputBox('Renommer la branche', 'Nouveau nom de la branche ' +
    Utf8ToAnsi(Old) + ' :', S) Then Exit;
  S := AnsiToUtf8(S);
  If (S = Old) Then Exit;
  If Not ValidBranch(S) Or FileExist(GitPath('refs/heads/' + S)) Then
  Begin
    ErrBox('Nom de branche non valable ou d'#233'j'#224' utilis'#233' : ' + S);
    Exit;
  End;
  If RefRead('refs/heads/' + Old, H) Then
  Begin
    If Not RefWrite('refs/heads/' + S, H) Then Exit;
    RefDelete('refs/heads/' + Old);
  End;
  SetHead('refs/heads/' + S);
  RefreshRepo(True);
End;

Procedure DeleteBranchCmd;
Var Ref, Nm : String;
Begin
  If Not MergeDialog(Ref) Then Exit;
  If Copy(Ref, 1, 11) <> 'refs/heads/' Then
  Begin
    ErrBox('Choisissez une branche locale '#224' supprimer.'); Exit;
  End;
  Nm := Copy(Ref, 12, 120);
  If Ask('Supprimer la branche locale ' + Utf8ToAnsi(Nm) + ' ?'#13#10 +
    'Les commits qui ne sont dans aucune autre branche seront perdus.',
    'Supprimer la branche', MB_YESNO Or MB_ICONWARNING) <> IDYES Then Exit;
  RefDelete(Ref);
  RefreshRepo(True);
  SetStatus('Branche ' + Utf8ToAnsi(Nm) + ' supprim'#233'e');
End;

Procedure ReportMerge(R : LongInt; Const What : String);
Var I : LongInt; S : String;
Begin
  Case R Of
    0 : ErrBox(What + ' impossible : ' + GitErr);
    1 : SetStatus('D'#233'j'#224' '#224' jour');
    2 : SetStatus(What + ' : avance rapide');
    3 : SetStatus(What + ' : commit de fusion cr'#233#233);
    4 :
    Begin
      RefreshRepo(False);
      S := '';
      For I := 0 To Chg.N - 1 Do
        If ((Chg.E^[I].Flag And $FF) = StConf) And (Length(S) < 180) Then
          S := S + #13#10'  ' + Utf8ToAnsi(Chg.E^[I].Path);
      ErrBox(What + ' : ' + IStr(MergeConf) + ' conflit(s). Corrigez les ' +
        'fichiers marqu'#233's (<<<<<<< ======= >>>>>>>) puis validez la ' +
        'fusion.' + S);
    End;
  End;
End;

Procedure MergeCmd;
Var Ref : String; H : TSha; R : LongInt;
Begin
  If Not MergeDialog(Ref) Then Exit;
  If Not RefRead(Ref, H) Then Exit;
  SetPtr(True);
  If Copy(Ref, 1, 11) = 'refs/heads/' Then
    R := DoMerge(H, 'branch ''' + Copy(Ref, 12, 120) + '''')
  Else R := DoMerge(H, 'remote-tracking branch ''' + Copy(Ref, 14, 120) +
    '''');
  SetPtr(False);
  RefreshRepo(False);
  ReportMerge(R, 'Fusion');
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
  If Ask(Q + #13#10'Cette op'#233'ration est irr'#233'versible.',
    'Annuler les modifications', MB_YESNO Or MB_ICONWARNING) <> IDYES Then
    Exit;
  For I := 0 To Chg.N - 1 Do
    If One And (I <> ChgSel) Then
      Chg.E^[I].Flag := Chg.E^[I].Flag And Not FlSel
    Else Chg.E^[I].Flag := Chg.E^[I].Flag Or FlSel;
  If Not DiscardSel Then ErrBox('Certaines modifications n''ont pas pu ' +
    #234'tre annul'#233'es : ' + GitErr);
  RefreshRepo(False);
End;

Procedure IgnoreCmd;
Var B : TBuf; P : String;
Begin
  If (ChgSel < 0) Or (ChgSel >= Chg.N) Then Exit;
  BufInit(B);
  If FileLoad(WorkDir + PS + '.gitignore', B) Then ;
  If (B.N > 0) And (B.P^[B.N - 1] <> 10) Then BufByte(B, 10);
  P := Chg.E^[ChgSel].Path;
  BufStr(B, '/' + P + #10);
  If Not FileSave(WorkDir + PS + '.gitignore', B, 0, B.N) Then
    ErrBox('Ecriture de .gitignore impossible.');
  BufFree(B);
  RefreshRepo(True);
End;

{ ouvre un fichier avec l'application d'OS/2-0 de son type }
Procedure OpenFile(Const P : String);
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
  Else If (X = 'DOC') Or (X = 'DOCX') Or (X = 'PDF') Then A := AppPath('WORDIUM.EXE')
  Else If X = 'EXE' Then A := P;
  If A = '' Then A := AppPath('NOTEPAD.EXE');
  If A = '' Then A := AppPath('PASDEV.EXE');
  If A = '' Then
  Begin
    ErrBox('Aucune application ne peut ouvrir ' + OemToAnsi(P)); Exit;
  End;
  If A = P Then Dummy0 := Ord(RunPgm(A, '', ParentOf(P), False))
  Else If Pos(' ', P) > 0 Then Dummy0 := Ord(RunPgm(A, '"' + P + '"', ParentOf(P), False))
  Else Dummy0 := Ord(RunPgm(A, P, ParentOf(P), False));
End;

Function GitHubPage : String;
Var U : String; K : LongInt;
Begin
  GitHubPage := '';
  U := CfgGet('remote', 'origin', 'url');
  K := Pos('github.com/', LowStr(U));
  If K = 0 Then
  Begin
    K := Pos('github.com:', LowStr(U));
    If K = 0 Then Exit;
  End;
  U := Copy(U, K + 11, 255);
  If LowStr(Copy(U, Length(U) - 3, 4)) = '.git' Then
    Delete(U, Length(U) - 3, 4);
  GitHubPage := 'https://github.com/' + U;
End;

Procedure SyncCmd(K : LongInt);
Begin
  If Busy Or (RepoCur < 0) Then Exit;
  If (K = OpPush) Or (K = OpPull) Then
    If CurBranch = '' Then
    Begin
      ErrBox('HEAD est d'#233'tach'#233'e : cr'#233'ez ou extrayez une ' +
        'branche.');
      Exit;
    End;
  If (K = OpPull) And Not Clean Then
  Begin
    ErrBox('Validez ou annulez vos modifications avant de tirer.'); Exit;
  End;
  If (K = OpPush) And ShaIsZero(HeadSha) Then
  Begin
    ErrBox('Aucun commit '#224' pousser : validez d''abord.'); Exit;
  End;
  If (K <> OpFetch) And (CfgGet('remote', 'origin', 'url') = '') Then
  Begin
    If GhToken <> '' Then
    Begin
      If Not PublishDialog Then Exit;
      OpBranch := CurBranch;
      StartOp(OpPublish);
      MenuState;
    End
    Else ErrBox('Ce d'#233'p'#244't n''a pas de d'#233'p'#244't distant. ' +
      'D'#233'finissez origin dans D'#233'p'#244't > Param'#232'tres, ou ' +
      'connectez-vous '#224' GitHub (Fichier > Options) pour le publier.');
    Exit;
  End;
  OpBranch := CurBranch;
  StartOp(K);
  MenuState;
End;

Procedure NewRepoCmd;
Var P, Nm : String; B : TBuf; H : TSha; K : LongInt;
Begin
  If Not NewRepoDialog Then Exit;
  Nm := DlgOut[0];
  While Pos(' ', Nm) > 0 Do Nm[Pos(' ', Nm)] := '-';
  P := AnsiToOem(JoinDir(DlgOut[2], Nm));
  If DirExist(P + '\.git') Then
  Begin
    ErrBox('Le dossier ' + OemToAnsi(P) + ' contient d'#233'j'#224' un d'#233'p'#244't.');
    Exit;
  End;
  If Not InitRepo(P, 'main') Then
  Begin
    ErrBox('Cr'#233'ation impossible : ' + GitErr); Exit;
  End;
  BufInit(B);
  If DlgOut[3] = '1' Then
  Begin
    BufStr(B, '# ' + AnsiToUtf8(Nm) + #10);
    If DlgOut[1] <> '' Then BufStr(B, #10 + AnsiToUtf8(DlgOut[1]) + #10);
    If FileSave(P + '\README.md', B, 0, B.N) Then ;
  End;
  If DlgOut[4] = '1' Then
    If FileSaveStr(P + '\.gitignore', '*.EXE'#10'*.OBJ'#10'*.TMP'#10 +
      '*.BAK'#10'*.~*'#10) Then ;
  K := RepoAdd(P);
  RepoCur := K;
  ReposSave;
  LoadIdentity;
  If RepoStatus And (Chg.N > 0) Then
  Begin
    B.N := 0;
    BufStr(B, 'Initial commit'#10);
    If Not DoCommit(B, H) Then ErrBox('Commit initial : ' + GitErr);
  End;
  BufFree(B);
  OpenRepo(K);
  SetStatus('D'#233'p'#244't ' + Nm + ' cr'#233#233' dans ' + OemToAnsi(P));
End;

Procedure AddRepoCmd;
Var P : String; K : LongInt;
Begin
  If Not AddLocalDialog Then Exit;
  P := AnsiToOem(DlgOut[0]);
  If (Length(P) > 3) And (P[Length(P)] = '\') Then Delete(P, Length(P), 1);
  If Not DirExist(P) Then
  Begin
    ErrBox('Le dossier ' + OemToAnsi(P) + ' n''existe pas.'); Exit;
  End;
  If Not SetRepo(P) Then
  Begin
    If Ask('Le dossier ' + OemToAnsi(P) + ' n''est pas un d'#233'p'#244't Git.'#13#10 +
      'Voulez-vous en cr'#233'er un dans ce dossier ?', 'Ajouter un d'#233'p'
      + #244't local', MB_YESNO Or MB_ICONQUESTION) <> IDYES Then Exit;
    If Not InitRepo(P, 'main') Then
    Begin
      ErrBox('Cr'#233'ation impossible : ' + GitErr); Exit;
    End;
  End;
  K := RepoAdd(P);
  OpenRepo(K);
End;

Procedure RepoListMenu(X, Y : LongInt);
Var M, I : LongInt;
Begin
  M := CreatePopupMenu;
  For I := 0 To RepoN - 1 Do
  Begin
    MItem(M, CmRepo + I, RepoTitle(I) + '   (' + OemToAnsi(RepoPath[I]) + ')');
    If I = RepoCur Then MCheck(M, CmRepo + I, True);
  End;
  If RepoN > 0 Then MItem(M, 0, '');
  MItem(M, CmClone, '~Cloner un d'#233'p'#244't...');
  MItem(M, CmNewRepo, '~Nouveau d'#233'p'#244't...');
  MItem(M, CmAddRepo, '~Ajouter un d'#233'p'#244't local...');
  TrackPopupMenu(M, MainWnd, X, Y);
End;

Procedure BranchListMenu(X, Y : LongInt);
Var M, I, K : LongInt; Nm : String; Dup : Boolean;
Begin
  If RepoCur < 0 Then Exit;
  M := CreatePopupMenu;
  BrN := 0;
  RefsList(LocRefs, 'refs/heads/');
  For I := 0 To LocRefs.N - 1 Do
    If BrN < 300 Then
    Begin
      BrList[BrN] := Copy(LocRefs.Name[I], 12, 120);
      If BrN < 200 Then
      Begin
        MItem(M, CmBrLocal + BrN, Utf8ToAnsi(BrList[BrN]));
        If BrList[BrN] = CurBranch Then MCheck(M, CmBrLocal + BrN, True);
      End;
      Inc(BrN);
    End;
  BrRemN := 0;
  RefsList(LocRefs, 'refs/remotes/origin/');
  For I := 0 To LocRefs.N - 1 Do
  Begin
    Nm := Copy(LocRefs.Name[I], 21, 120);
    If Nm = 'HEAD' Then Continue;
    Dup := False;
    For K := 0 To BrN - 1 Do
      If BrList[K] = Nm Then Dup := True;
    If Dup Or (BrN + BrRemN >= 300) Or (BrRemN >= 200) Then Continue;
    If BrRemN = 0 Then MItem(M, 0, '');
    BrList[BrN + BrRemN] := Nm;
    MItem(M, CmBrRemote + BrRemN, 'origin/' + Utf8ToAnsi(Nm));
    Inc(BrRemN);
  End;
  MItem(M, 0, '');
  MItem(M, CmNewBranch, '~Nouvelle branche...');
  MItem(M, CmMerge, '~Fusionner dans ' + Utf8ToAnsi(CurBranch) + '...');
  TrackPopupMenu(M, MainWnd, X, Y);
End;

Procedure ChangesMenu(X, Y : LongInt);
Var M : LongInt;
Begin
  M := CreatePopupMenu;
  MItem(M, CmDiscardOne, '~Annuler les modifications...');
  MItem(M, CmIgnore, 'Ajouter '#224' .~gitignore');
  MItem(M, 0, '');
  MItem(M, CmCopyPath, 'Copier le ~chemin');
  MItem(M, CmOpenFile, '~Ouvrir le fichier');
  TrackPopupMenu(M, Lv[LvChg].H, X, Y);
End;

Procedure AboutBox;
Begin
  Dummy := Ask('Client GitHub pour OS/2-0'#13#10'Version 1.0'#13#10 +
    #13#10'Auteur : Sylvain Maltais'#13#10'Licence : MIT'#13#10#13#10 +
    'Protocole Git (HTTP/HTTPS intelligent et git://), packs, deltas, ' +
    'fusion '#224' trois voies, API de GitHub.com.'#13#10 +
    'Porte du Client GitHub de Pasdows 95, compil'#233' avec OS/2 Pascal ' +
    'Compiler (OS2PC).',
    'A propos du Client GitHub', MB_OK Or MB_ICONINFO);
End;

Procedure KeysBox;
Begin
  Dummy := Ask('Ctrl+1 / Ctrl+2 : Modifications / Historique'#13#10 +
    'Ctrl+T / Ctrl+B : liste des d'#233'p'#244'ts / des branches'#13#10 +
    'Ctrl+N / Ctrl+O : nouveau d'#233'p'#244't / ajouter un d'#233'p'#244't'
    + #13#10'Ctrl+Maj+O : cloner un d'#233'p'#244't'#13#10 +
    'Ctrl+P / Ctrl+Maj+P : pousser / tirer'#13#10 +
    'Ctrl+Maj+T : r'#233'cup'#233'rer'#13#10 +
    'Ctrl+Maj+N : nouvelle branche'#13#10 +
    'Ctrl+Maj+M : fusionner dans la branche actuelle'#13#10 +
    'Ctrl+Entr'#233'e : valider'#13#10'F5 : actualiser'#13#10 +
    'Espace : cocher ou d'#233'cocher le fichier', 'Raccourcis clavier',
    MB_OK Or MB_ICONINFO);
End;

Procedure DoMenu(Cmd : LongInt);
Var I : LongInt; S : String;
Begin
  If Busy And (Cmd <> CmExit) And (Cmd <> CmAbout) And (Cmd <> CmGhHelp) And
     (Cmd <> CmViewChg) And (Cmd <> CmViewHist) Then
  Begin
    Dummy0 := WinAlarm(HWND_DESKTOP, 0); Exit;
  End;
  If (Cmd >= CmRepo) And (Cmd < CmRepo + MaxRepo) Then
  Begin
    OpenRepo(Cmd - CmRepo); Exit;
  End;
  If (Cmd >= CmBrLocal) And (Cmd < CmBrRemote + 300) And (RepoCur >= 0) Then
  Begin
    If (Cmd < CmBrRemote) Then
    Begin
      I := Cmd - CmBrLocal;
      If (I < BrN) And (BrList[I] <> CurBranch) Then
        CheckoutCmd(BrList[I], False);
    End
    Else
    Begin
      I := Cmd - CmBrRemote;
      If I < BrRemN Then CheckoutCmd(BrList[BrN + I], True);
    End;
    Exit;
  End;
  Case Cmd Of
    CmNewRepo : NewRepoCmd;
    CmAddRepo : AddRepoCmd;
    CmClone :
      If CloneDialog Then
      Begin
        StartOp(OpClone);
        MenuState;
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
      If (View = VwChanges) And (ChgSel >= 0) Then
        CopyToClip(OemToAnsi(WorkPath(Chg.E^[ChgSel].Path)))
      Else If (View = VwHistory) And (FileSel >= 0) Then
        CopyToClip(OemToAnsi(WorkPath(HFiles.E^[FileSel].Path)));
    CmOpenFile :
      If (View = VwChanges) And (ChgSel >= 0) Then
        OpenFile(WorkPath(Chg.E^[ChgSel].Path))
      Else If (View = VwHistory) And (FileSel >= 0) And
              FileExist(WorkPath(HFiles.E^[FileSel].Path)) Then
        OpenFile(WorkPath(HFiles.E^[FileSel].Path));
    CmIgnore : IgnoreCmd;
    CmViewChg : SetView(VwChanges);
    CmViewHist : SetView(VwHistory);
    CmRepoList : RepoListMenu(TbX(0) + 4, TbH - 4);
    CmBranchList : BranchListMenu(TbX(1) + 4, TbH - 4);
    CmRefresh : RefreshRepo(True);
    CmPush : SyncCmd(OpPush);
    CmPull : SyncCmd(OpPull);
    CmFetch : SyncCmd(OpFetch);
    CmPublish :
      If GhToken = '' Then ErrBox('Connectez-vous d''abord '#224' GitHub ' +
        '(Fichier > Options, jeton d''acc'#232's personnel).')
      Else If CfgGet('remote', 'origin', 'url') <> '' Then
        ErrBox('Ce d'#233'p'#244't a d'#233'j'#224' un d'#233'p'#244't distant ' +
          '(origin).')
      Else If PublishDialog Then
      Begin
        OpBranch := CurBranch;
        StartOp(OpPublish);
        MenuState;
      End;
    CmViewGh :
    Begin
      S := GitHubPage;
      If S = '' Then ErrBox('Le d'#233'p'#244't distant n''est pas sur ' +
        'GitHub.com.')
      Else If AppPath('BROWSER.EXE') <> '' Then
        Dummy0 := Ord(RunPgm(AppPath('BROWSER.EXE'), S, WorkDir, False))
      Else ErrBox('Navigateur Web introuvable. Adresse : ' + S);
    End;
    CmExplorer :
      If AppPath('EXPLORER.EXE') <> '' Then
        Dummy0 := Ord(RunPgm(AppPath('EXPLORER.EXE'), WorkDir, WorkDir, False));
    CmDos :
      If AppPath('CMD.EXE') <> '' Then
        Dummy0 := Ord(RunPgm(AppPath('CMD.EXE'), '', WorkDir, True));
    CmRepoSet : If RepoSetDialog Then RefreshRepo(True);
    CmRemoveRepo :
      If Ask('Retirer ' + RepoTitle(RepoCur) + ' de la liste ?'#13#10 +
        '(Les fichiers ne sont pas supprim'#233's.)', 'Retirer le d'#233'p'#244
        + 't', MB_YESNO Or MB_ICONQUESTION) = IDYES Then
      Begin
        RepoRemove(RepoCur);
        If RepoN > 0 Then RepoCur := 0;
        ReposSave;
        RefreshRepo(False);
      End;
    CmNewBranch : NewBranchCmd;
    CmRenBranch : RenameBranchCmd;
    CmDelBranch : DeleteBranchCmd;
    CmMerge : MergeCmd;
    CmAbout : AboutBox;
    CmGhHelp : KeysBox;
  End;
End;

{ fin d'une operation reseau }
Procedure OpDone;
Var K, R : LongInt; Retry : Boolean;
Begin
  Busy := False;
  WorkTid := 0;
  Retry := False;
  If Not OpOk And (Pos('(401)', GitErr) > 0) And (Op <> OpPublish) And
     (Op <> OpGhList) And (Op <> OpSignIn) Then
  Begin
    If (Op = OpClone) And UrlSplit(OpUrl) Then Retry := CredDialog(UrlHost)
    Else If (RepoCur >= 0) And UrlSplit(CfgGet('remote', 'origin', 'url'))
    Then Retry := CredDialog(UrlHost);
  End;
  If Retry Then
  Begin
    { recommence dans un dossier vide }
    If Op = OpClone Then RmTree(OpDir, 0);
    StartOp(Op);
    Exit;
  End;
  Case Op Of
    OpClone :
      If OpOk Then
      Begin
        LastFetch := MsTick;
        K := RepoAdd(OpDir);
        OpenRepo(K);
        SetStatus('Clonage termin'#233' : ' + OemToAnsi(OpDir));
      End
      Else
      Begin
        RmTree(OpDir, 0);
        ErrBox('Clonage impossible : ' + GitErr);
        RefreshRepo(True);
      End;
    OpFetch :
    Begin
      RefreshRepo(True);
      If OpOk Then SetStatus('R'#233'cup'#233'ration termin'#233'e')
      Else ErrBox('R'#233'cup'#233'ration impossible : ' + GitErr);
    End;
    OpPull :
    Begin
      R := OpRes;
      RefreshRepo(False);
      If OpOk Or (R = 0) Then ReportMerge(R, 'Tirage');
    End;
    OpPush, OpPublish :
    Begin
      RefreshRepo(True);
      If OpOk Then
      Begin
        If PushMsg = 'deja a jour' Then SetStatus('D'#233'j'#224' '#224' jour')
        Else SetStatus('Branche ' + Utf8ToAnsi(OpBranch) + ' pouss'#233'e vers origin');
      End
      Else If Op = OpPublish Then ErrBox('Publication impossible : ' + GitErr)
      Else ErrBox('Envoi impossible : ' + GitErr);
    End;
  End;
  MenuState;
  Redraw;
End;

Procedure TbClick(X, Y : LongInt);
Var I : LongInt;
Begin
  If Y >= TbH Then Exit;
  For I := 0 To 2 Do
    If (X >= TbX(I)) And (X < TbX(I + 1) - 2) Then
    Begin
      If (I = 2) And (RepoCur < 0) Then Exit;
      TbDown := I;
      InvalidateStatus;
      BigUnlock;
      Dummy0 := WinUpdateWindow(MainWnd);
      BigLock;
      Case I Of
        0 : If Not Busy Then RepoListMenu(TbX(0) + 4, TbH - 4);
        1 : If Not Busy Then BranchListMenu(TbX(1) + 4, TbH - 4);
        2 :
          If Busy Then
          Begin
            If Ask('Annuler l''op'#233'ration en cours ?', 'Client GitHub',
              MB_YESNO Or MB_ICONQUESTION) = IDYES Then NetAbort := True;
          End
          Else
            Case SyncKind Of
              1 : DoMenu(CmPublish);
              2, 4 : SyncCmd(OpPush);
              3 : SyncCmd(OpPull);
              Else SyncCmd(OpFetch);
            End;
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

{ raccourcis clavier (WM_CHAR de PM avant la distribution) : Key est une
  touche de Pasdows (VK_F5, VK_DELETE, VK_RETURN) ou une lettre }
Function Accel(Key : LongInt; C, Sh : Boolean) : Boolean;
Var Cmd, F : LongInt;
Begin
  Accel := False;
  Cmd := 0;
  If (Key = VK_F5) And Not C Then Cmd := CmRefresh
  Else If (Key = $72) And Not C Then Cmd := CmExit
  Else If C Then
    Case Key Of
      Ord('1') : Cmd := CmViewChg;
      Ord('2') : Cmd := CmViewHist;
      Ord('T') : If Sh Then Cmd := CmFetch Else Cmd := CmRepoList;
      Ord('B') : Cmd := CmBranchList;
      Ord('N') : If Sh Then Cmd := CmNewBranch Else Cmd := CmNewRepo;
      Ord('O') : If Sh Then Cmd := CmClone Else Cmd := CmAddRepo;
      Ord('P') : If Sh Then Cmd := CmPull Else Cmd := CmPush;
      Ord('M') : If Sh Then Cmd := CmMerge;
      Ord('G') : If Sh Then Cmd := CmViewGh;
      Ord('F') : If Sh Then Cmd := CmExplorer;
      Ord(',') : Cmd := CmOptions;
      VK_DELETE : If Sh Then Cmd := CmDiscardAll;
      VK_RETURN :
        If (View = VwChanges) And (RepoCur >= 0) Then
        Begin
          DoCommitCmd; Accel := True; Exit;
        End;
      Ord('A') :
      Begin
        F := GetFocus;
        If (F <> ESum) And (F <> EDesc) Then Cmd := CmCheckAll;
      End;
    End;
  If Cmd = 0 Then Exit;
  If (RepoCur < 0) And (Cmd <> CmNewRepo) And (Cmd <> CmAddRepo) And
     (Cmd <> CmClone) And (Cmd <> CmOptions) And (Cmd <> CmExit) Then Exit;
  DoMenu(Cmd);
  Accel := True;
End;

{ WM_CHAR de PM -> Accel ; vrai si la touche est un raccourci }
Function AccelPm(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, V, K : LongInt;
Begin
  AccelPm := False;
  Fl := Mp1 And $FFFF;
  If (Fl And PM_KC_KEYUP) <> 0 Then Exit;
  Ch := Mp2 And $FFFF; V := (Mp2 Shr 16) And $FFFF;
  K := 0;
  If ((Fl And PM_KC_VIRTUALKEY) <> 0) And (VkOf(V) <> 0) And
     (VkOf(V) <> VK_SPACE) Then K := VkOf(V)
  Else If (Fl And PM_KC_CTRL) <> 0 Then
  Begin
    Ch := Ch And 255;
    If (Ch >= 1) And (Ch <= 26) Then Ch := Ch + 64;
    K := Ord(UpCase(Chr(Ch)));
  End;
  If K = 0 Then Exit;
  If (K <> VK_F5) And (K <> $72) And ((Fl And PM_KC_CTRL) = 0) Then Exit;
  AccelPm := Accel(K, (Fl And PM_KC_CTRL) <> 0, (Fl And PM_KC_SHIFT) <> 0);
End;

Procedure MakeChildren(H : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 2 Do
  Begin
    Lv[K].H := WinCreateWindow(H, Z2('GCLIST'), 0, PM_WS_TABSTOP, 0, 0, 100,
      100, H, HWND_BOTTOM, 40 + K, 0, 0);
    Lv[K].Sb := WinCreateWindow(Lv[K].H, WC_SCROLLBAR, 0, PM_WS_VISIBLE Or
      PM_SBS_VERT, 0, 0, SbW, 100, Lv[K].H, HWND_BOTTOM, 50 + K, 0, 0);
  End;
  Lv[LvChg].RowH := 20; Lv[LvHist].RowH := 36; Lv[LvFiles].RowH := 18;
  DiffWnd := WinCreateWindow(H, Z2('GCDIFF'), 0, PM_WS_TABSTOP, 0, 0, 100,
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
  BWClone := Ctl(H, 'BUTTON', 'Cloner un d'#233'p'#244't depuis Internet...',
    WS_TABSTOP, 0, 0, 10, 10, IdWClone);
  BWNew := Ctl(H, 'BUTTON', 'Cr'#233'er un nouveau d'#233'p'#244't sur votre ' +
    'disque...', WS_TABSTOP, 0, 0, 10, 10, IdWNew);
  BWAdd := Ctl(H, 'BUTTON', 'Ajouter un d'#233'p'#244't existant...',
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
        IdWClone : DoMenu(CmClone);
        IdWNew : DoMenu(CmNewRepo);
        IdWAdd : DoMenu(CmAddRepo);
        Else If Id > 100 Then DoMenu(Id);
      End;
    End;
    WM_GITPROG : InvalidateStatus;
    WM_GITDONE : OpDone;
    WM_TIMER : If Busy Then InvalidateStatus;
    WM_ACTIVATE :
      If (WP <> 0) And (RepoCur >= 0) And Not Busy And (DlgFrame = 0) And
         (MsTick - LastRefresh > 5000) Then
        Dummy0 := WinPostMsg(H, WM_GITCMD, CmRefresh, 0);
    WM_CLOSE :
      If Busy Then
      Begin
        If Ask('Une op'#233'ration r'#233'seau est en cours. Quitter quand ' +
          'm'#234'me ?', 'Client GitHub', MB_YESNO Or MB_ICONWARNING) = IDYES
        Then
        Begin
          NetAbort := True;
          Dummy0 := WinPostMsg(H, PM_WM_QUIT, 0, 0);
        End;
      End
      Else Dummy0 := WinPostMsg(H, PM_WM_QUIT, 0, 0);
  End;
End;

{ procedure de PM de la fenetre principale : messages de PM traduits en
  messages de Pasdows (souris : Y vers le bas) ; Tab : controle suivant
  (WinDefDlgProc) ; les controles (WM_CONTROL) : EN_CHANGE du resume }
Var
  InMainKey : Boolean;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var R, Fl, V : LongInt;
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
        { Tab venu d'un controle (saisie, bouton) : controle suivant }
        InMainKey := True;
        BigLock;
        FocusNext(GetFocus, V = PM_VK_BACKTAB);
        BigUnlock;
        InMainKey := False;
        R := 1;
      End
      Else R := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
  Else
    BigLock;
    Case Msg Of
      PM_WM_SIZE : Dummy0 := MainProc0(H, WM_SIZE, 0, Mp2);
      PM_WM_PAINT : Dummy0 := MainProc0(H, WM_PAINT, 0, 0);
      PM_WM_COMMAND : Dummy0 := MainProc0(H, WM_COMMAND, Mp1 And $FFFF, 0);
      PM_WM_CONTROL :
      Begin
        If ((Mp1 And $FFFF) = IdSum) And (((Mp1 Shr 16) And $FFFF) = PM_EN_CHANGE) Then
          Dummy0 := MainProc0(H, WM_COMMAND, IdSum Or (EN_CHANGE Shl 16), 0);
        R := 0;
      End;
      PM_WM_TIMER : Dummy0 := MainProc0(H, WM_TIMER, Mp1, 0);
      PM_WM_ACTIVATE :
      Begin
        Dummy0 := MainProc0(H, WM_ACTIVATE, Mp1 And $FFFF, 0);
        R := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
      PM_WM_BUTTON1DOWN :
      Begin
        Dummy0 := MainProc0(H, WM_LBUTTONDOWN, 0, MousePt(H, Mp1));
        R := 1;
      End;
      WM_GITPROG, WM_GITDONE : Dummy0 := MainProc0(H, Msg, Mp1, Mp2);
      WM_GITCMD : If Not Busy And (DlgFrame = 0) Then DoMenu(Mp1);
      PM_WM_CLOSE : Dummy0 := MainProc0(H, WM_CLOSE, 0, 0);
    Else
      R := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
    BigUnlock;
  End;
  MainProc := R;
End;
Const
  { flux zlib (Huffman dynamique, Python zlib niveau 9) de TstZText x 20 }
  TstZlib : Array[0..1] Of String[200] = (
    '78DAEDCF4D12C1401445E1B955DC0D20E2DFD48041AAA8B2824EE7E1D169927423593D650F8CEEF4D4997C9960ED547CC046C336E628B03B0CD37E02B1B57E2BC4636F1A6BDC00D94FF7CEE96769BD29B58A82154C6E0B399ECE7AB9BAD2DFEE55DD84F8',
    '78BEDA0EC9281D4FA6B3F962D9CB68A081061A68A081061A68A081061A68A0E1CF86373CC8FB79');
  TstZLen = 3920;
  TstOfsPack : Array[0..20] Of String[200] = (
    '5041434B0000000200000006971D789C7D905B4F83401085DFF757EC7B63DC5D6E4BA2C6522E520A5A17ACEDDB5E58548A45A05AFBEB2D9AF864FC92999C9CCC4C2667E8CA1222A9895002991499B8C4AE56AE41392112111797D211DA900A9B18B4BC2B',
    '5F07885C4D903035910A296A5B02B91C13D3D63622D410AE6139846AE500BE1F9E761DCCE1C5703D5C41ECD88E810942084E4E0D01B96B9AE76128FF19A9DAAA7FAEE0D9881744710619BB812C8EB2695EDC07DF3E8005CEE2026D6FA623CB53F9E9A816',
    'D2C8768BD5439DBE1438CDEBD1ABBAC5B1D761CC42537CD2E5244C8EC459B775820BD67BDEA40190377BBCACE7AFC2EFC70D7F43B668FACBE6C8A3E0742D3E692F1F9D99911DF90C6F377E8CB33CB0BE9F08ABBDEB583E805E31B94D3FBC036B295B274D',
    '7BBEAAEC8D2F33A1A59BCED687B98A93C8527612E687B76931A83D7B7BFCD8AD10EDA2F3E66E2E1DFEE8F37E4BEB150330AC824BF0134790F97F8501DE09F8028A668525971A789C7D905B4F83401085DFF757EC3B31EE52AE891AA1D02D165610B0C2DB',
    '722D05DA5AA0A6FC7AA1263E19BF6492939399C9C9E9CF790E7986653155D5842196F292A0484C92182BB05A084CC44A8A65B4C8850CB0A1DF1DCF30800FFD73FF04B12CC93C2F4A08410E4D80F4D8B655DFE7FFAC94A7B2AB4A7837A39BC4A2D0F7D7D0',
    'B708D582F0CDBCF90086985A216AD6DA8C378DE1CCCA4E17F4686FDF6B671F6227A867AF3CDB6357AC2C7F252457C5E3569B9197A353BDC1A1DFE93AD702C8DA017BF5CB2131BAF9C288F90669BFC42323E6F4CD9AB41ECCCE724147B6C44D6C589806A6',
    '780B41B22156250F40BE09BF62B132F605DD5E389ABBD9A58D689C20A52D37878E9C76498182C1E5873DCAA36BBDCC8CD8FFE84E76414CD5EDB3CA7D25D8D1EEED88B8007E6ACA23F8A9C3A4C65F65800B06DFAD5B787FA102789C3334303033315148D4',
    '2BA92861383DE744C6C2A73E2CAF0EDDDC1D94E09378E1E8951700D5180F9CB5B402789C75585B6EA4400CFCF729B81A6CA20CDA8141C920A139FD76BBFC28F764A58410BAF1B35C76B33E9EF3B49DD3F7ED31CDF7E3364F8F6DFDF3FDD8A7E7EDB32D2D',
    'FDF26A17F9F8BC63EBB1DADA7E4E3FEBD7364F587ACEA7600182FADDB54EEBC324F4FD2AE96BDEDA4B9FC7CF7A6F7A5C9FFFEF7F212444891B82CBDFF938E6E93E6FCB0734C192BE51D74D1FB6414833BD99A316B80EB50DE69828BCD05CB197F0D84CC6',
    'E2E6625B20EC2D5579AC72403EA2A6C243F56E120586364BF03055792096E284C556E3EA3B2C5FDB29FD8FEAF1A548459AA9F29A3E0BFB337C858C08B8B9AAE260247B5DE2A3D6E96A8432429201C0EB10B59FA2CFE048D35AAC6ED6B91CB576413C39BF',
    'BEDE5DF3FB6B3554BE0C6BE4CD628FD42E19C1A62F74FFFD412A6B6954DBC2A13D85429BE35E5ED5CC8C4A7FA8429A0A4BB8051BCB1BF2BE049265F35AD2D7FCF5127A456EC2A5EDA1376C0F4755F0B629F690A30A1A745E03A20814EE6EBF7F79EDA1F2',
    '21135E583569E1F7AD1E6DB62BA920CC2F39001E12334E2E928F6AF06BC569C1439D279C5CDA3DDEDDC2823E2E4BB533A004619B2507FFC12BAC235D9953B3A73B16F440F86C06F5A5903AB29D11A30606EEC4524005C6B64D250229B616B02EB4CD4DF3',
    'E54C1D89039C77CB7EC5B9C5A1125FACE2C6551DBE0D2639E2A02D6927F6EF236A853012361243983D03BD8435EDA7071FDAC1ABBFED8492425DD1E8848062F558B803F6AA1110532936FA8D6DD4707B1A77BF66383C44CCA9F166A2E71819CB810E7D49',
    '3625F5156644BE0866B63953CF299EA235C0EA259B3DF71EDCD7200F60966CCF4E0DD973B29C245814AB6ADD6244A2BFBA4188772350A5572B0E04E92B68AB58ED123B0F3324701DA3C38FB90930270685B8F35E4CD5563331E8879262FE73F78979EAAD',
    '1DD16608F6765A3DEED0A33445131A6A703B4B899A91A0410A77DB860D68A95D79C94FF073E4106A973231C6D4E6C47EACC96697E62EB49825EE7E2D357242085530FBC8D12129C5A296A3A78D75373647810EF4987AAA7B4A84AB2EEC5B0B60EC625D32',
    'E468C86E69F44E839976446221EEADFF6992194F9FACDF67C7A09A8B87316A673D9F981085E112C41BE8493E8E89CC8197136EB65C21E2F730E4A4053614AEBC52CD6C0A36F161E1CDD3E8A84710EF7E964AC5FE5F12257C6A799B5F89945A69FB043A1C',
    '4E783E8EF310AADBA898B8A50C36805D62723B8BE7590B4D39B4B01FCC69351E8E523C2D10A9536BEC2C1445737D391C2511517239496C238D0452E8094327E115A1E8AC4CA3FF76F2E924A82206C757129C0FD7D562027EFB29F53A104C394F45A1942A',
    '7A65C1A0D1F0C093BC9B48CFC84B02E0F0735EE4C9E8413D4818944382F718897B2A3F9A2F3D93A1CAAB934E45BBB75303D0B3B6CF82E44F745D76D4B9C265617432098C4C2BF1FE27663C727B984EEAE07A69174F4C6B15476888162D07E51015A70E1A',
    'D8985E08B15171F9B1C00649EE6278B98C59CDC03DE770FF9011765A85EC67E5B2A0A83241452A70A5E9837A9B7FA86047BCFBC607041FEFE58A8198BBBB571C22C7E7A618F2EBD12ABE7D38497BDEAF9571C375251463EAC419D23CC14B0E4C591B34C0',
    'E72191F970E0DF604B3A4816D7D2F2F85E45E2C46B3539A6143E354209BE24BBB932B20EE51FC24EE389E104883B789C3BAA364B6DC30C4601670F473F775717051F4F3F57057F3FD7CDFB187339514543C2FD374772EF60E1F0F40B760D0A7175D92C20',
    '60CA0C008BE612C1A102789C3334303033315148D42BA92861A8E9BD6DD6A67FE5C5C299A7376EF6BAD361375BB91D00CE700E6491CD592AC7101EC5528CBAB58E174AF9598C5474');
  TstRefPack : Array[0..20] Of String[200] = (
    '5041434B0000000200000006971D789C7D905B4F83401085DFF757EC7B63DC5D6E4BA2C6522E520A5A17ACEDDB5E58548A45A05AFBEB2D9AF864FC92999C9CCC4C2667E8CA1222A9895002991499B8C4AE56AE41392112111797D211DA900A9B18B4BC2B',
    '5F07885C4D903035910A296A5B02B91C13D3D63622D410AE6139846AE500BE1F9E761DCCE1C5703D5C41ECD88E810942084E4E0D01B96B9AE76128FF19A9DAAA7FAEE0D9881744710619BB812C8EB2695EDC07DF3E8005CEE2026D6FA623CB53F9E9A816',
    'D2C8768BD5439DBE1438CDEBD1ABBAC5B1D761CC42537CD2E5244C8EC459B775820BD67BDEA40190377BBCACE7AFC2EFC70D7F43B668FACBE6C8A3E0742D3E692F1F9D99911DF90C6F377E8CB33CB0BE9F08ABBDEB583E805E31B94D3FBC036B295B274D',
    '7BBEAAEC8D2F33A1A59BCED687B98A93C8527612E687B76931A83D7B7BFCD8AD10EDA2F3E66E2E1DFEE8F37E4BEB150330AC824BF0134790F97F8501DE09F8028A668525971A789C7D905B4F83401085DFF757EC3B31EE52AE891AA1D02D165610B0C2DB',
    '722D05DA5AA0A6FC7AA1263E19BF6492939399C9C9E9CF790E7986653155D5842196F292A0484C92182BB05A084CC44A8A65B4C8850CB0A1DF1DCF30800FFD73FF04B12CC93C2F4A08410E4D80F4D8B655DFE7FFAC94A7B2AB4A7837A39BC4A2D0F7D7D0',
    'B708D582F0CDBCF90086985A216AD6DA8C378DE1CCCA4E17F4686FDF6B671F6227A867AF3CDB6357AC2C7F252457C5E3569B9197A353BDC1A1DFE93AD702C8DA017BF5CB2131BAF9C288F90669BFC42323E6F4CD9AB41ECCCE724147B6C44D6C589806A6',
    '780B41B22156250F40BE09BF62B132F605DD5E389ABBD9A58D689C20A52D37878E9C76498182C1E5873DCAA36BBDCC8CD8FFE84E76414CD5EDB3CA7D25D8D1EEED88B8007E6ACA23F8A9C3A4C65F65800B06DFAD5B787FA102789C3334303033315148D4',
    '2BA92861383DE744C6C2A73E2CAF0EDDDC1D94E09378E1E8951700D5180F9CB5B402789C75585B6EA4400CFCF729B81A6CA20CDA8141C920A139FD76BBFC28F764A58410BAF1B35C76B33E9EF3B49DD3F7ED31CDF7E3364F8F6DFDF3FDD8A7E7EDB32D2D',
    'FDF26A17F9F8BC63EBB1DADA7E4E3FEBD7364F587ACEA7600182FADDB54EEBC324F4FD2AE96BDEDA4B9FC7CF7A6F7A5C9FFFEF7F212444891B82CBDFF938E6E93E6FCB0734C192BE51D74D1FB6414833BD99A316B80EB50DE69828BCD05CB197F0D84CC6',
    'E2E6625B20EC2D5579AC72403EA2A6C243F56E120586364BF03055792096E284C556E3EA3B2C5FDB29FD8FEAF1A548459AA9F29A3E0BFB337C858C08B8B9AAE260247B5DE2A3D6E96A8432429201C0EB10B59FA2CFE048D35AAC6ED6B91CB576413C39BF',
    'BEDE5DF3FB6B3554BE0C6BE4CD628FD42E19C1A62F74FFFD412A6B6954DBC2A13D85429BE35E5ED5CC8C4A7FA8429A0A4BB8051BCB1BF2BE049265F35AD2D7FCF5127A456EC2A5EDA1376C0F4755F0B629F690A30A1A745E03A20814EE6EBF7F79EDA1F2',
    '21135E583569E1F7AD1E6DB62BA920CC2F39001E12334E2E928F6AF06BC569C1439D279C5CDA3DDEDDC2823E2E4BB533A004619B2507FFC12BAC235D9953B3A73B16F440F86C06F5A5903AB29D11A30606EEC4524005C6B64D250229B616B02EB4CD4DF3',
    'E54C1D89039C77CB7EC5B9C5A1125FACE2C6551DBE0D2639E2A02D6927F6EF236A853012361243983D03BD8435EDA7071FDAC1ABBFED8492425DD1E8848062F558B803F6AA1110532936FA8D6DD4707B1A77BF66383C44CCA9F166A2E71819CB810E7D49',
    '3625F5156644BE0866B63953CF299EA235C0EA259B3DF71EDCD7200F60966CCF4E0DD973B29C245814AB6ADD6244A2BFBA4188772350A5572B0E04E92B68AB58ED123B0F3324701DA3C38FB90930270685B8F35E4CD5563331E8879262FE73F78979EAAD',
    '1DD16608F6765A3DEED0A33445131A6A703B4B899A91A0410A77DB860D68A95D79C94FF073E4106A973231C6D4E6C47EACC96697E62EB49825EE7E2D357242085530FBC8D12129C5A296A3A78D75373647810EF4987AAA7B4A84AB2EEC5B0B60EC625D32',
    'E468C86E69F44E839976446221EEADFF6992194F9FACDF67C7A09A8B87316A673D9F981085E112C41BE8493E8E89CC8197136EB65C21E2F730E4A4053614AEBC52CD6C0A36F161E1CDD3E8A84710EF7E964AC5FE5F12257C6A799B5F89945A69FB043A1C',
    '4E783E8EF310AADBA898B8A50C36805D62723B8BE7590B4D39B4B01FCC69351E8E523C2D10A9536BEC2C1445737D391C2511517239496C238D0452E8094327E115A1E8AC4CA3FF76F2E924A82206C757129C0FD7D562027EFB29F53A104C394F45A1942A',
    '7A65C1A0D1F0C093BC9B48CFC84B02E0F0735EE4C9E8413D4818944382F718897B2A3F9A2F3D93A1CAAB934E45BBB75303D0B3B6CF82E44F745D76D4B9C265617432098C4C2BF1FE27663C727B984EEAE07A69174F4C6B15476888162D07E51015A70E1A',
    'D8985E08B15171F9B1C00649EE6278B98C59CDC03DE770FF9011765A85EC67E5B2A0A83241452A70A5E9837A9B7FA86047BCFBC607041FEFE58A8198BBBB571C22C7E7A618F2EBD12ABE7D38497BDEAF9571C375251463EAC419D23CC14B0E4C591B34C0',
    'E72191F970E0DF604B3A4816D7D2F2F85E45E2C46B3539A6143E354209BE24BBB932B20EE51FC24EE389F1047C8DDB36862FD4E8A199CBB1B34ADC883E9B2387789C3BAA364B6DC30C4601670F473F775717051F4F3F57057F3FD7CDFB187339514543C2',
    'FD374772EF60E1F0F40B760D0A7175D92C2060CA0C008BE612C1A102789C3334303033315148D42BA92861A8E9BD6DD6A67FE5C5C299A7376EF6BAD361375BB91D00CE700E645BC6F537FF753A60AC8C86B41AC70579AB0F556E');
{ ==================================================================== }
{ Essais (/TEST) : sans fenetre, resultats sur COM1                     }
{ ==================================================================== }

Var
  TOk, TN : LongInt;
  TUrls : Array[0..7] Of String[200];  { /URL: (lecture et ecriture) }
  TRo : Array[0..7] Of Boolean;        { /RO: lecture seulement }
  TUrlN : LongInt;

Procedure TRes(Ok : Boolean; Const S : String);
Begin
  Inc(TN);
  If Ok Then
  Begin
    Inc(TOk);
    Log('GITCLI : ' + S + ' : reussi');
  End
  Else Log('GITCLI : ' + S + ' : ECHEC (' + GitErr + ')');
  GitErr := '';
End;

{ chaines hexadecimales -> octets }
Procedure THex(Var B : TBuf; Const S : String);
Var I : LongInt;
Begin
  I := 1;
  While I < Length(S) Do
  Begin
    BufByte(B, HexVal(S[I]) * 16 + HexVal(S[I + 1]));
    Inc(I, 2);
  End;
End;

Function TSha1Str(Const S : String) : String;
Var C : TSha1; H : TSha;
Begin
  Sha1Init(C);
  Sha1Str(C, S);
  Sha1Final(C, H);
  TSha1Str := ShaHex(H);
End;

Function TBufEq(Var A, B : TBuf) : Boolean;
Var I : LongInt;
Begin
  TBufEq := False;
  If A.N <> B.N Then Exit;
  For I := 0 To A.N - 1 Do
    If A.P^[I] <> B.P^[I] Then Exit;
  TBufEq := True;
End;

{ supprime un dossier d'essai (et son contenu) }
Procedure TRmTree(Const D : String; Depth : LongInt);
Var L : TFlat; J : LongInt;
Begin
  If (Depth > 30) Or (Length(D) <= 3) Or Not DirExist(D) Then Exit;
  FlatInit(L);
  DirList(D, L, False);
  For J := 0 To L.N - 1 Do
    If L.E^[J].Mode <> 0 Then TRmTree(D + '\' + L.E^[J].Path, Depth + 1)
    Else FileDel(D + '\' + L.E^[J].Path);
  FlatFree(L);
  If FRmDir(D) Then ;
End;

Procedure TWrite(Const P, S : String);
Begin
  If FileSaveStr(P, S) Then ;
End;

Function TRead(Const P : String) : String;
Var B : TBuf; S : String;
Begin
  BufInit(B);
  S := '';
  If FileLoad(P, B) Then S := BufStrAt(B, 0, B.N);
  BufFree(B);
  TRead := S;
End;

{ statut et validation de tout ce qui a change }
Function TCommitAll(Const Msg : String; Var H : TSha) : Boolean;
Var M : TBuf;
Begin
  TCommitAll := False;
  If Not RepoStatus Then Exit;
  BufInit(M);
  BufStr(M, Msg + #10);
  TCommitAll := DoCommit(M, H);
  BufFree(M);
End;

{ pack embarque : indexe dans un depot neuf, objets relus }
Function TPackEmb(Const Dir : String; K : LongInt) : Boolean;
Var B, D : TBuf; I, T : LongInt; H, X : TSha; C : TCommit; F : TFlat;
    Ok : Boolean; Nm : String;
Begin
  TPackEmb := False;
  TRmTree(Dir, 0);
  If Not InitRepo(Dir, 'main') Then Exit;
  BufInit(B); BufInit(D);
  If K = 0 Then
    For I := 0 To 20 Do THex(B, TstOfsPack[I])
  Else
    For I := 0 To 20 Do THex(B, TstRefPack[I]);
  Nm := TmpPath('recv.pack');
  Ok := FileSave(Nm, B, 0, B.N);
  If Not Ok Then GitErr := 'ecriture de ' + Nm;
  Ok := Ok And IndexPackFile(Nm);
  FileDel(Nm);
  If Ok Then
  Begin
    PacksScan;
    { blob en delta (v2) et sa base (v1) }
    Ok := ShaParse('cb9cc868a1e54c04eac2d9bb52604c61d0c5d4e8', H) And
      ReadObject(H, T, D) And (T = OtBlob) And (D.N = 4890);
    If Ok Then
    Begin
      ObjHash(OtBlob, D, 0, D.N, X);
      Ok := ShaEq(X, H);
      If Not Ok Then GitErr := 'empreinte du blob en delta : ' + ShaHex(X);
    End;
    If Ok Then
      Ok := ShaParse('7c8ddb36862fd4e8a199cbb1b34adc883e9b2387', H) And
        ReadObject(H, T, D) And (T = OtBlob);
    If Ok Then
    Begin
      ObjHash(OtBlob, D, 0, D.N, X);
      Ok := ShaEq(X, H);
    End;
    { commit et arbre }
    FlatInit(F);
    If Ok Then
      Ok := ShaParse('5552c28d382ced063d60b3f9b40f7be2d28e74b3', H) And
        CommitRead(H, C, Nil) And (C.Summary = 'v2') And (C.PN = 1) And
        CommitFlat(H, F) And (F.N = 1) And (F.E^[0].Path = 'a.txt') And
        (ShaHex(F.E^[0].Sha) = 'cb9cc868a1e54c04eac2d9bb52604c61d0c5d4e8');
    If Not Ok And (GitErr = '') Then
    Begin
      GitErr := 'objets du pack incorrects : resume "' + C.Summary + '", ' +
        IStr(C.PN) + ' parent(s), ' + IStr(F.N) + ' fichier(s)';
      If F.N > 0 Then GitErr := GitErr + ' ' + F.E^[0].Path + ' ' + ShaHex(F.E^[0].Sha);
    End;
    FlatFree(F);
  End;
  BufFree(B); BufFree(D);
  TPackEmb := Ok;
End;

{ clonage, validation, envoi et tirage par l'URL U (No : numero) }
Procedure TNet(Const U : String; Ro : Boolean; No : LongInt);
Var D1, D2, S, S2 : String; Ok : Boolean; H, H1, R : TSha; T0, K : LongInt;
    Bd, Br : TBuf;
Begin
  D1 := 'D:\GT\C' + IStr(No) + 'A';
  D2 := 'D:\GT\C' + IStr(No) + 'B';
  TRmTree(D1, 0); TRmTree(D2, 0);
  GitErr := '';
  T0 := MsTick;
  RemUser := ''; RemPass := '';
  Ok := DoClone(U, D1);
  If Ok Then
  Begin
    Ok := SetRepo(D1) And RepoStatus And Not ShaIsZero(HeadSha) And
      (Chg.N = 0) And (HeadF.N > 0);
    If Not Ok And (GitErr = '') Then
      GitErr := 'depot clone incomplet (' + IStr(Chg.N) + ' modification(s), ' +
        IStr(HeadF.N) + ' fichier(s))';
  End;
  S := '';
  If Ok Then
  Begin
    S := ' (' + IStr(HeadF.N) + ' fichiers, HEAD ' + Copy(ShaHex(HeadSha), 1,
      10) + ', branche ' + HeadBranch + ', ' + IStr((MsTick - T0) Div 1000) +
      ' s)';
    { tous les fichiers extraits ont le contenu de leur blob }
    For K := 0 To HeadF.N - 1 Do
      If Ok And (HeadF.E^[K].Mode <> $E000) Then
        If Not BlobOfFile(HeadF.E^[K].Path, H) Or
           Not ShaEq(H, HeadF.E^[K].Sha) Then
        Begin
          Ok := False;
          GitErr := 'contenu incorrect : ' + HeadF.E^[K].Path;
        End;
  End;
  TRes(Ok, 'clonage ' + U + S);
  { API de GitHub (sans jeton) : description publique du depot }
  If Ok And UrlSplit(U) And (LowStr(UrlHost) = 'github.com') Then
  Begin
    S := UrlPath;
    If LowStr(Copy(S, Length(S) - 3, 4)) = '.git' Then Delete(S, Length(S) - 3, 4);
    BufInit(Bd); BufInit(Br); S2 := '';
    Ok := GhApi('GET', '/repos' + S, Bd, Br, K) And (K = 200);
    If Ok Then
    Begin
      S2 := JsonGet(Br, 'full_name', 1);
      Ok := (S2 <> '') And (LowStr('/' + S2) = LowStr(Copy(UrlPath, 1, Length(S2) + 1)));
      If Not Ok Then GitErr := 'full_name : ' + S2;
    End
    Else If GitErr = '' Then GitErr := 'statut ' + IStr(K);
    { un refus (401, 403) vient du compte ou du proxy, pas du client :
      renseignement seulement }
    If Ok Or ((K <> 401) And (K <> 403)) Then
      TRes(Ok, 'API de GitHub (api.github.com/repos' + S + ' : ' + S2 + ')')
    Else
    Begin
      Log('GITCLI : API de GitHub (api.github.com/repos' + S + ') : statut ' +
        IStr(K) + ' (acces refuse par le serveur ou le proxy ; non compte)');
      GitErr := '';
    End;
    Ok := True;
    BufFree(Bd); BufFree(Br);
  End;
  If Not Ok Or Ro Then Exit;
  { second clone, validation dans le premier, envoi, tirage dans le
    second }
  Ok := DoClone(U, D2);
  If Not Ok Then
  Begin
    TRes(False, 'second clonage ' + U); Exit;
  End;
  Ok := SetRepo(D1);
  S := 'OS2-0 ' + IStr(NowUnix) + ' ' + IStr(No);
  TWrite(D1 + '\OS2_' + IStr(No) + '.TXT', 'Envoye par le Client GitHub d''OS/2-0' +
    #10 + S + #10);
  Ok := Ok And TCommitAll('Essai du Client GitHub (' + S + ')', H1);
  If Ok Then Ok := DoPush('origin', HeadBranch, False);
  TRes(Ok, 'validation et envoi (push) ' + U);
  If Not Ok Then Exit;
  Ok := SetRepo(D2) And RepoStatus;
  RemUrl := CfgGet('remote', 'origin', 'url');
  Ok := Ok And DoFetch('origin');
  If Ok Then
  Begin
    Ok := RepoStatus And RefRead('refs/remotes/origin/' + HeadBranch, R) And
      ShaEq(R, H1);
    If Ok Then
    Begin
      K := DoMerge(R, 'branch ''' + HeadBranch + ''' of ' + U);
      Ok := (K = 2) And ShaEq(HeadSha, H1) And
        (Pos(S, TRead(D2 + '\OS2_' + IStr(No) + '.TXT')) > 0);
      If Not Ok And (GitErr = '') Then GitErr := 'fusion ' + IStr(K);
    End
    Else If GitErr = '' Then GitErr := 'origin/' + HeadBranch + ' pas a jour';
  End;
  TRes(Ok, 'recuperation et tirage (pull) ' + U);
End;

{ /INDEX:pack /DIR:chemin : indexation d'un pack recu (mesures) }
Procedure IndexTest(Const Pack, Dir : String);
Var Nm : String; Ok : Boolean;
Begin
  Log('GITCLI : indexation de ' + Pack);
  If Not InitRepo(Dir, 'main') Then
  Begin
    Log('GITCLI : depot ' + Dir + ' impossible'); Exit;
  End;
  Nm := TmpPath('recv.pack');
  If Not FileCopy(Pack, Nm) Then
  Begin
    Log('GITCLI : copie de ' + Pack + ' impossible'); Exit;
  End;
  IxTrace := True;
  IxT0 := MsTick;
  Ok := IndexPackFile(Nm);
  IxTrace := False;
  FileDel(Nm);
  If Ok Then Log('GITCLI : INDEX REUSSI en ' + IStr(MsTick - IxT0) + ' ms')
  Else Log('GITCLI : INDEX ECHEC (' + GitErr + ') apres ' +
    IStr(MsTick - IxT0) + ' ms');
  Log('GITCLI : gros objets ' + IStr(BigMade) + ', bases chargees ' +
    IStr(BaseLoads) + ', reprises ' + IStr(BaseHits));
End;

Procedure RunTests;
Var B, Z, O, O2 : TBuf; H, H2, H3, H4 : TSha; C : TSha1; I, U, T, K : LongInt;
    Ok : Boolean; S : String; Cm : TCommit; HFlatT : TFlat;
Begin
  TOk := 0; TN := 0;
  Log('GITCLI : essais du Client GitHub (' + AgentName + ')');
  MkDirs('D:\GT');
  BufInit(B); BufInit(Z); BufInit(O); BufInit(O2);
  { 1. SHA-1 }
  Sha1Init(C);
  For I := 1 To 1000000 Do Sha1Byte(C, Ord('a'));
  Sha1Final(C, H);
  B.N := 0; BufStr(B, 'hello' + #10);
  ObjHash(OtBlob, B, 0, B.N, H2);
  Ok := (TSha1Str('abc') = 'a9993e364706816aba3e25717850c26c9cd0d89d') And
    (TSha1Str('') = 'da39a3ee5e6b4b0d3255bfef95601890afd80709') And
    (ShaHex(H) = '34aa973cd4c4daa4f61eeb2bdbad27316534016f') And
    (ShaHex(H2) = 'ce013625030ba8dba906f756967f9e9ca394464a');
  If Not Ok Then GitErr := ShaHex(H) + ' ' + ShaHex(H2);
  TRes(Ok, 'SHA-1 (abc, vide, million de a, blob hello)');
  { 2. zlib : inflate d'un flux de Python, deflate puis inflate }
  B.N := 0;
  For I := 0 To 1 Do THex(B, TstZlib[I]);
  O.N := 0;
  Ok := ZInflate(B, 0, B.N, O, U) And (O.N = TstZLen) And (U = B.N);
  If Ok Then
  Begin
    Sha1Init(C); Sha1Mem(C, O, 0, O.N); Sha1Final(C, H);
    Ok := ShaHex(H) = '20a3de5d8f0399809040cc6fdfb43c3bb4f38f84';
  End;
  If Not Ok Then GitErr := 'inflate : ' + IStr(O.N) + ' octets';
  TRes(Ok, 'zlib inflate (Huffman dynamique, ' + IStr(B.N) + ' -> ' +
    IStr(O.N) + ' octets)');
  Z.N := 0;
  ZDeflate(O, 0, O.N, Z);
  O2.N := 0;
  Ok := ZInflate(Z, 0, Z.N, O2, U) And TBufEq(O, O2);
  { donnees peu compressibles }
  B.N := 0;
  K := 12345;
  For I := 0 To 99999 Do
  Begin
    K := K * 1103515245 + 12345;
    If (I Mod 7) = 0 Then BufByte(B, Ord('A')) Else BufByte(B, (K Shr 16) And 255);
  End;
  Z.N := 0; ZDeflate(B, 0, B.N, Z);
  O2.N := 0;
  Ok := Ok And ZInflate(Z, 0, Z.N, O2, U) And TBufEq(B, O2);
  If Not Ok Then GitErr := 'deflate/inflate : ' + IStr(O2.N) + ' octets';
  TRes(Ok, 'zlib deflate puis inflate (texte de ' + IStr(O.N) +
    ' octets ; donnees aleatoires : ' + IStr(B.N) + ' -> ' + IStr(Z.N) + ')');
  { 3. objets libres }
  TRmTree('D:\GT\OBJ', 0);
  Ok := InitRepo('D:\GT\OBJ', 'main');
  B.N := 0; BufStr(B, 'hello' + #10);
  Ok := Ok And WriteObject(OtBlob, B, H) And
    (ShaHex(H) = 'ce013625030ba8dba906f756967f9e9ca394464a') And
    FileExist('D:\GT\OBJ\.git\objects\ce\013625030ba8dba906f756967f9e9ca394464a');
  O.N := 0;
  Ok := Ok And ReadObject(H, T, O) And (T = OtBlob) And TBufEq(B, O);
  { gros objet (ecrit par morceaux) }
  B.N := 0;
  For I := 0 To 2299999 Do BufByte(B, (I * 7 + I Div 1000) And 255);
  Ok := Ok And FileSave('D:\GT\OBJ\GROS.BIN', B, 0, B.N) And
    WriteObjectFile(OtBlob, 'D:\GT\OBJ\GROS.BIN', H2);
  ObjHash(OtBlob, B, 0, B.N, H3);
  O.N := 0;
  Ok := Ok And ShaEq(H2, H3) And ObjToFile(H2, 'D:\GT\OBJ\GROS2.BIN', T) And
    (T = OtBlob) And FileLoad('D:\GT\OBJ\GROS2.BIN', O) And TBufEq(B, O);
  TRes(Ok, 'objets libres (ecriture, lecture, gros objet de 2,3 Mo)');
  { 4. packs embarques (deltas) }
  TRes(TPackEmb('D:\GT\PK1', 0), 'pack avec delta OFS_DELTA (git pack-objects)');
  TRes(TPackEmb('D:\GT\PK2', 1), 'pack avec delta REF_DELTA (git pack-objects)');
  { 5. pack ecrit ici puis indexe }
  TRmTree('D:\GT\PK3', 0);
  Ok := InitRepo('D:\GT\PK3', 'main');
  Z.N := 0;
  PackBegin(Z, 3);
  B.N := 0; BufStr(B, 'premier objet' + #10); PackAdd(Z, OtBlob, B);
  ObjHash(OtBlob, B, 0, B.N, H);
  B.N := 0; BufStr(B, 'second objet, un peu plus long que le premier' + #10);
  PackAdd(Z, OtBlob, B);
  ObjHash(OtBlob, B, 0, B.N, H2);
  O.N := 0;
  For I := 0 To 4999 Do BufStr(O, 'ligne ' + IStr(I) + #10);
  PackAdd(Z, OtBlob, O);
  ObjHash(OtBlob, O, 0, O.N, H3);
  PackEnd(Z);
  Ok := Ok And IndexPack(Z);
  PacksScan;
  O2.N := 0;
  Ok := Ok And (PackN = 1) And Not FileExist(ObjPath(H)) And
    ReadObject(H3, T, O2) And TBufEq(O, O2) And HasObject(H) And
    HasObject(H2);
  TRes(Ok, 'pack ecrit (3 objets, ' + IStr(Z.N) + ' octets) et index v2');
  { 6. depot : statut, validation, diff, historique, branches, fusion }
  TRmTree('D:\GT\WK', 0);
  UserName := 'Essai OS/2-0'; UserEmail := 'essai@os2-0.local';
  Ok := InitRepo('D:\GT\WK', 'main');
  MkDirs('D:\GT\WK\SRC');
  S := '';
  For I := 1 To 20 Do S := S + 'ligne ' + IStr(I) + #10;
  TWrite('D:\GT\WK\A.TXT', S);
  TWrite('D:\GT\WK\SRC\B.PAS', 'Program B;' + #10 + 'Begin' + #10 + 'End.' + #10);
  TWrite('D:\GT\WK\.gitignore', '*.BAK' + #10);
  TWrite('D:\GT\WK\X.BAK', 'ignore' + #10);
  Ok := Ok And RepoStatus And (Chg.N = 3);
  Ok := Ok And TCommitAll('Premier commit', H) And RepoStatus And (Chg.N = 0);
  TRes(Ok, 'statut (.gitignore) et premier commit ' + Copy(ShaHex(H), 1, 10));
  { modification, diff }
  S := '';
  For I := 1 To 20 Do
    If I = 5 Then S := S + 'ligne cinq modifiee' + #10
    Else If I <> 12 Then S := S + 'ligne ' + IStr(I) + #10;
  S := S + 'ligne 21' + #10;
  TWrite('D:\GT\WK\A.TXT', S);
  Ok := RepoStatus And (Chg.N = 1) And ((Chg.E^[0].Flag And $FF) = StMod);
  If Ok Then
  Begin
    DfA.N := 0; DfB.N := 0;
    Ok := BlobLoad(Chg.E^[0].Old, DfA) And FileLoad(WorkPath('A.TXT'), DfB);
    DiffBuild;
    Ok := Ok And (DfAdd = 2) And (DfDel = 2);
    If Not Ok Then GitErr := 'diff +' + IStr(DfAdd) + ' -' + IStr(DfDel);
  End;
  TRes(Ok, 'diff (+' + IStr(DfAdd) + ' -' + IStr(DfDel) + ', ' + IStr(DfN) +
    ' lignes affichees)');
  Ok := TCommitAll('Second commit', H2);
  HistLoad(HeadSha, 10);
  Ok := Ok And (HistN = 2) And (Hist^[0].Summary = 'Second commit') And
    (Hist^[1].Summary = 'Premier commit');
  FlatInit(HFlatT);
  Ok := Ok And CommitChanges(H2, HFlatT) And (HFlatT.N = 1);
  FlatFree(HFlatT);
  TRes(Ok, 'historique (2 commits) et fichiers modifies d''un commit');
  { branche dev : B.PAS modifie ; main : A.TXT modifie ; fusion }
  Ok := RefWrite('refs/heads/dev', HeadSha) And RepoStatus And
    SwitchBranch('dev') And (HeadBranch = 'dev');
  TWrite('D:\GT\WK\SRC\B.PAS', 'Program B;' + #10 + 'Begin' + #10 +
    '  WriteLn(''dev'');' + #10 + 'End.' + #10);
  Ok := Ok And TCommitAll('Sur dev', H3) And RepoStatus And SwitchBranch('main') And
    (Pos('dev', TRead('D:\GT\WK\SRC\B.PAS')) = 0);
  S := 'ligne 0' + #10 + TRead('D:\GT\WK\A.TXT');
  TWrite('D:\GT\WK\A.TXT', S);
  Ok := Ok And TCommitAll('Sur main', H4) And RepoStatus;
  K := 0;
  If Ok Then K := DoMerge(H3, 'branch ''dev''');
  Ok := Ok And (K = 3) And (Pos('dev', TRead('D:\GT\WK\SRC\B.PAS')) > 0) And
    (Pos('ligne 0', TRead('D:\GT\WK\A.TXT')) > 0) And CommitRead(HeadSha, Cm, Nil) And
    (Cm.PN = 2);
  TRes(Ok, 'branches et fusion a trois voies (resultat ' + IStr(K) + ')');
  { conflit }
  Ok := RepoStatus And SwitchBranch('dev');
  TWrite('D:\GT\WK\A.TXT', 'conflit dev' + #10 + TRead('D:\GT\WK\A.TXT'));
  Ok := Ok And TCommitAll('Conflit dev', H3) And RepoStatus And SwitchBranch('main');
  TWrite('D:\GT\WK\A.TXT', 'conflit main' + #10 + TRead('D:\GT\WK\A.TXT'));
  Ok := Ok And TCommitAll('Conflit main', H4) And RepoStatus;
  K := 0;
  If Ok Then K := DoMerge(H3, 'branch ''dev''');
  Ok := Ok And (K = 4) And (MergeConf = 1) And
    (Pos('<<<<<<< ', TRead('D:\GT\WK\A.TXT')) > 0) And RepoStatus And InMerge And
    (Chg.N = 1) And ((Chg.E^[0].Flag And $FF) = StConf);
  { resolution et commit de fusion }
  TWrite('D:\GT\WK\A.TXT', 'resolu' + #10);
  Ok := Ok And TCommitAll('Fusion resolue', H) And Not InMerge And
    CommitRead(H, Cm, Nil) And (Cm.PN = 2);
  TRes(Ok, 'conflit de fusion (marqueurs, MERGE_HEAD) et resolution');
  { 7. reseau }
  For I := 0 To TUrlN - 1 Do TNet(TUrls[I], TRo[I], I);
  BufFree(B); BufFree(Z); BufFree(O); BufFree(O2);
  Log('GITCLI : ' + IStr(TOk) + '/' + IStr(TN) + ' essais reussis');
End;
{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

Var
  Fw, Fh, Fl, KA, StartK : LongInt;
  Handled : Boolean;
  SA, ArgRepo, ArgClone, ArgDir, ArgIndex : String;

Begin
  AgentName := 'git/2.0 (OS/2-0; Client GitHub 1.0)';
  FsAnsi := True;
  EnvProxy := GetEnvS('HTTP_PROXY');
  DetectOem;
  TUrlN := 0;
  ArgRepo := ''; ArgClone := ''; ArgDir := ''; ArgIndex := '';
  For KA := 1 To ParamCount Do
  Begin
    SA := ParamStr(KA);
    If UpStr(SA) = '/TEST' Then TestMode := True
    Else If (UpStr(Copy(SA, 1, 5)) = '/URL:') And (TUrlN < 8) Then
    Begin
      TUrls[TUrlN] := Copy(SA, 6, 200); TRo[TUrlN] := False; Inc(TUrlN);
    End
    Else If (UpStr(Copy(SA, 1, 4)) = '/RO:') And (TUrlN < 8) Then
    Begin
      TUrls[TUrlN] := Copy(SA, 5, 200); TRo[TUrlN] := True; Inc(TUrlN);
    End
    Else If UpStr(Copy(SA, 1, 7)) = '/CLONE:' Then ArgClone := Copy(SA, 8, 200)
    Else If UpStr(Copy(SA, 1, 7)) = '/INDEX:' Then ArgIndex := Copy(SA, 8, 200)
    Else If UpStr(Copy(SA, 1, 5)) = '/DIR:' Then ArgDir := Copy(SA, 6, 200)
    Else If (Length(SA) >= 3) And (SA[2] = ':') And (SA[3] = '\') Then
      ArgRepo := SA;
  End;
  If (ArgIndex <> '') And (ArgDir <> '') Then
  Begin
    LockOn := False;
    TestMode := True;
    IndexTest(ArgIndex, ArgDir);
    Dummy0 := DosExit(1, 0);
  End;
  If TestMode Then
  Begin
    { essais sans fenetre : un seul fil, pas de verrou }
    LockOn := False;
    RunTests;
    Dummy0 := DosExit(1, 0);
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20); ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  FindAppDir;
  Dummy0 := DosCreateMutexSem(0, LongInt(@LockSem), 0, 0);
  LockOn := True;
  FlatInit(HFiles); BufInit(HMsg);
  BufInit(DfA); BufInit(DfB);
  TbDown := -1; ChgSel := -1; HistSel := -1; FileSel := -1;
  RegClass('GCMAIN', LongInt(@MainProc));
  RegClass('GCLIST', LongInt(@LvProc));
  RegClass('GCDIFF', LongInt(@DiffProc));
  RegClass('GCDLG', LongInt(@DlgProc));
  BigLock;
  GhToken := IniGet('Compte', 'Jeton', '');
  GhLogin := IniGet('Compte', 'Login', '');
  DefName := IniGet('Identite', 'Nom', '');
  DefEmail := IniGet('Identite', 'Courriel', '');
  ProxyStr := IniGet('Options', 'Proxy', '');
  CloneRoot := IniGet('Options', 'Dossier', DataDrive + ':\Mes documents\GitHub');
  ReposLoad;
  If ArgRepo <> '' Then
  Begin
    StartK := RepoAdd(ArgRepo);
    RepoCur := StartK;
    ReposSave;
  End;
  If (RepoCur < 0) And (RepoN > 0) Then RepoCur := 0;
  StatusTxt := 'Pr'#234't';
  BigUnlock;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or
    FCF_MAXBUTTON Or FCF_TASKLIST;
  MainWnd := 0;
  MainFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z2('GCMAIN'),
    Z('Client GitHub'), 0, 0, 0, LongInt(@MainWnd));
  BigLock;
  MakeChildren(MainWnd);
  BuildMenus;
  BigUnlock;
  Fw := MinL(ScrW, 900); Fh := MinL(ScrH - 32, 660);
  If ScrW <= 800 Then
    Dummy0 := WinSetWindowPos(MainFrame, HWND_TOP, 0, 0, ScrW, ScrH, SWP_SIZE Or
      SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE Or SWP_MAXIMIZE)
  Else
    Dummy0 := WinSetWindowPos(MainFrame, HWND_TOP, (ScrW - Fw) Div 2,
      MaxL(0, (ScrH - Fh) Div 2 + 16), Fw, Fh, SWP_SIZE Or SWP_MOVE Or
      SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy0 := WinSetActiveWindow(HWND_DESKTOP, MainFrame);
  BigLock;
  Layout;
  RefreshRepo(False);
  BigUnlock;
  Dummy0 := WinStartTimer(Hab, MainWnd, 1, 1000);
  { /CLONE:url /DIR:chemin : clonage au demarrage }
  If (ArgClone <> '') And (ArgDir <> '') Then
  Begin
    BigLock;
    OpUrl := NormUrl(ArgClone); OpDir := ArgDir;
    StartOp(OpClone);
    MenuState;
    BigUnlock;
  End;
  If RepoCur >= 0 Then WFocus(Lv[LvChg].H) Else WFocus(BWClone);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do
  Begin
    Handled := False;
    If (Qmsg[1] = PM_WM_CHAR) And (DlgFrame = 0) Then
    Begin
      BigLock;
      Handled := AccelPm(Qmsg[2], Qmsg[3]);
      BigUnlock;
    End;
    If Not Handled Then Dummy0 := WinDispatchMsg(Hab, LongInt(@Qmsg));
  End;
  NetAbort := True;
  Dummy0 := DosSleep(200);
  Dummy0 := WinDestroyWindow(MainFrame);
  Dummy0 := DosExit(1, 0);
End.
