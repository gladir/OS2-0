{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 PMWIN.DLL de OS/2-0 (gestionnaire de
                fenetres de Presentation Manager, ecran graphique
                640 x 480 x 16 couleurs ou ecran texte).
}

Library PMWIN;

{$IMAGEBASE $00B00000}
{$R-,S-,I-}

{ Compilation : OS2PC PMWIN.PAS   (produit PMWIN.DLL)

  PMWIN.DLL est le gestionnaire de fenetres de Presentation Manager :
  classes et fenetres (arbre des parents et des proprietaires, ordre de
  superposition, mots reserves, texte), files de messages (envoi,
  postage, WM_PAINT, minuteries, entrees du clavier et de la souris),
  focus et activation, dessin, controles standard (cadre, barre de
  titre, bouton, statique, champ de saisie, liste, barre de defilement,
  menu), dialogues et boites de message, accelerateurs, crochets,
  presse-papiers, atomes, tas, valeurs et couleurs du systeme, pages de
  codes, ressources et erreurs.

  Ecran : la premiere file de messages (WinCreateMsgQueue) passe l'ecran
  en mode graphique 640 x 480 x 16 couleurs (VioSetMode, mode 12h du VGA ;
  origine en bas a gauche, y vers le haut). Les fenetres y sont dessinees
  en pels : cadres et boutons en relief, barre de titre, menu systeme,
  boutons de reduction et d'agrandissement, barre d'actions et menus
  deroulants (mnemoniques soulignes, coches, sous-menus), cases a cocher,
  boutons radio, champs de saisie et listes en creux, barres de
  defilement (fleches, curseur a glisser), bitmaps OS/2 (1, 4, 8 et 24
  bits), texte de la police 8 x 16 du VGA ; le pointeur de la souris
  (fleche) et le curseur (rectangle inverse) sont superposes. Le dernier
  WinTerminate rend l'ecran au mode texte (CMD le fait aussi a la fin
  d'un programme). Avec PMMODE=TEXTE dans l'environnement, PM reste dans
  l'ecran texte de 80 x 25 cellules, vu en coordonnees de 640 x 400 pels
  (une cellule = 8 x 16 pels, dessinee si son centre est dans la zone de
  dessin). Les couleurs (CLR_*, SYSCLR_*, RVB 00RRGGBBh) deviennent les
  16 couleurs du VGA (8 pour le fond en mode texte). Le clavier
  (KBDCALLS.DLL) et la souris (MOUCALLS.DLL, positions en pels en mode
  graphique) sont lus par WinGetMsg et WinPeekMsg.

  Procedures de fenetre, de dialogue et de crochet : une adresse dans le
  programme (00400000h-007FFFFFh) est une fonction d'un programme OS2PC
  (convention Pascal : parametres empiles de gauche a droite, pile
  nettoyee par la fonction) ; ailleurs (point d'entree exporte d'une DLL,
  convention _System). Les procedures des classes du systeme sont le
  point d'entree interne WINSYSCLASSPROC (ordinal 1000) ; WINQUERYPSINFO
  (ordinal 1001, interne) decrit un HPS pour PMGPI.DLL, WINQUERYSCREENTEXT
  (1002, interne) rend le texte ecrit a l'ecran (programmes d'essai) et
  WINHIDEOVERLAYS (1003, interne) retire le pointeur et le curseur avant
  un dessin direct de PMGPI.DLL. Pour le bureau (PMSHELL.EXE) :
  WINSUSPENDSCREEN (1004) prete l'ecran a un programme lance (mode texte ;
  un programme de PM lance pendant ce temps reprend le mode graphique a
  sa premiere file de messages et le rend a sa fin), WINRESUMESCREEN
  (1005) rend l'ecran a PM et WINQUERYSCREENTAKEN (1006) dit si un
  programme de PM a pris l'ecran entre les deux.

  Handles : HAB 00010001h..., HMQ 00510001h..., HWND 8000xxyyh (HWND_DESKTOP
  1 et HWND_OBJECT 2 acceptes), HPS 5053xxxxh, HDC 4443xxxxh, HPOINTER
  5054xxxxh (pointeurs du systeme : 5054000nh, n = SPTR_*), HBITMAP
  424Dxxxxh, HACCEL 4143xxxxh, HHEAP 4845xxxxh, HATOMTBL 4154xxxxh
  (systeme 41540001h), HENUM 454Exxxxh ; atomes C000h-FFFFh (entiers :
  1-BFFFh, "#n" ou FFFF0000h + n).

  Les fonctions de l'interface 16 bits d'OS/2 (ordinaux bas) et 32 bits
  (ordinaux 700 et plus) ont le meme effet (OS/2-0 n'a pas de code 16
  bits) ; un nom present deux fois est exporte en majuscules a l'ordinal
  bas.

  Limites : les fonctions Gpi* sont dans PMGPI.DLL (les regions HRGN de
  PMWIN se limitent a 0 : toute la fenetre ; en mode texte, une bitmap
  est dessinee en trame), une seule police (8 x 16), pointeurs du systeme
  dessines en fleche, WinScrollWindow deplace les pels par octets entiers
  (le reste est a redessiner), WinCatch et WinThrow ne peuvent derouler la pile (WinThrow rend FALSE),
  les messages envoyes a une fenetre d'un autre processus ne sont remis
  que si sa procedure est dans une DLL (les processus s'executent l'un
  apres l'autre).

  Organisation :
    Partie 1 - Constantes, variables, utilitaires
    Partie 2 - Fenetres et classes
    Partie 3 - Ecran, espaces de presentation, mise a jour, dessin
    Partie 4 - Files de messages, entrees, focus, minuteries, crochets
    Partie 5 - Procedures des classes, dialogues, boites de message
    Partie 6 - Presse-papiers, atomes, tas, ressources, systeme
    Partie 7 - Points d'entree 16 bits, exportations, initialisation }

{ ==================================================================== }
{ Partie 1 - Constantes, variables, utilitaires                         }
{ ==================================================================== }

Const
  { messages }
  WM_NULL = $0000; WM_CREATE = $0001; WM_DESTROY = $0002; WM_ENABLE = $0004;
  WM_SHOW = $0005; WM_MOVE = $0006; WM_SIZE = $0007; WM_ADJUSTWINDOWPOS = $0008;
  WM_SETWINDOWPARAMS = $000A; WM_QUERYWINDOWPARAMS = $000B; WM_HITTEST = $000C;
  WM_ACTIVATE = $000D; WM_SETFOCUS = $000F; WM_SETSELECTION = $0010;
  WM_COMMAND = $0020; WM_SYSCOMMAND = $0021; WM_HELP = $0022; WM_PAINT = $0023;
  WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A; WM_SYSCOLORCHANGE = $002B;
  WM_SYSVALUECHANGED = $002D; WM_PRESPARAMCHANGED = $002F; WM_CONTROL = $0030;
  WM_VSCROLL = $0031; WM_HSCROLL = $0032; WM_INITMENU = $0033; WM_MENUSELECT = $0034;
  WM_MENUEND = $0035; WM_QUERYDLGCODE = $003A; WM_INITDLG = $003B;
  WM_SUBSTITUTESTRING = $003C; WM_MATCHMNEMONIC = $003D; WM_SAVEAPPLICATION = $003E;
  WM_FLASHWINDOW = $0040; WM_FORMATFRAME = $0041; WM_UPDATEFRAME = $0042;
  WM_FOCUSCHANGE = $0043; WM_MINMAXFRAME = $0046; WM_ERASEBACKGROUND = $004F;
  WM_QUERYFRAMECTLCOUNT = $0059; WM_CALCFRAMERECT = $0053; WM_WINDOWPOSCHANGED = $0055;
  WM_DESTROYCLIPBOARD = $0062; WM_DRAWCLIPBOARD = $0067;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072;
  WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074; WM_BUTTON2UP = $0075;
  WM_BUTTON2DBLCLK = $0076; WM_BUTTON3DOWN = $0077; WM_BUTTON3UP = $0078;
  WM_BUTTON3DBLCLK = $0079; WM_CHAR = $007A;
  WM_DDE_INITIATE = $00A0; WM_DDE_INITIATEACK = $00A9;
  WM_BUTTON1CLICK = $0413; WM_BUTTON2CLICK = $0416; WM_BUTTON3CLICK = $0419;
  WM_CONTEXTMENU = $0424; WM_USER = $1000;

  { controles }
  BM_CLICK = $0120; BM_QUERYCHECKINDEX = $0121; BM_QUERYHILITE = $0122;
  BM_SETHILITE = $0123; BM_QUERYCHECK = $0124; BM_SETCHECK = $0125; BM_SETDEFAULT = $0126;
  EM_QUERYCHANGED = $0140; EM_QUERYSEL = $0141; EM_SETSEL = $0142; EM_SETTEXTLIMIT = $0143;
  EM_CUT = $0144; EM_COPY = $0145; EM_CLEAR = $0146; EM_PASTE = $0147;
  EM_QUERYFIRSTCHAR = $0148; EM_SETFIRSTCHAR = $0149; EM_QUERYREADONLY = $014A;
  EM_SETREADONLY = $014B; EM_SETINSERTMODE = $014C;
  LM_QUERYITEMCOUNT = $0160; LM_INSERTITEM = $0161; LM_SETTOPINDEX = $0162;
  LM_DELETEITEM = $0163; LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165;
  LM_SETITEMTEXT = $0166; LM_QUERYITEMTEXTLENGTH = $0167; LM_QUERYITEMTEXT = $0168;
  LM_SETITEMHANDLE = $0169; LM_QUERYITEMHANDLE = $016A; LM_SEARCHSTRING = $016B;
  LM_QUERYTOPINDEX = $016D; LM_DELETEALL = $016E;
  MM_INSERTITEM = $0180; MM_DELETEITEM = $0181; MM_QUERYITEM = $0182; MM_SETITEM = $0183;
  MM_QUERYITEMCOUNT = $0184; MM_STARTMENUMODE = $0185; MM_ENDMENUMODE = $0186;
  MM_REMOVEITEM = $0188; MM_SELECTITEM = $0189; MM_QUERYSELITEMID = $018A;
  MM_QUERYITEMTEXT = $018B; MM_QUERYITEMTEXTLENGTH = $018C; MM_SETITEMHANDLE = $018D;
  MM_SETITEMTEXT = $018E; MM_ITEMPOSITIONFROMID = $018F; MM_ITEMIDFROMPOSITION = $0190;
  MM_QUERYITEMATTR = $0191; MM_SETITEMATTR = $0192; MM_ISITEMVALID = $0193;
  SBM_SETSCROLLBAR = $01A0; SBM_SETPOS = $01A1; SBM_QUERYPOS = $01A2; SBM_QUERYRANGE = $01A3;
  SBM_SETTHUMBSIZE = $01A6;
  TBM_SETHILITE = $01E3; TBM_QUERYHILITE = $01E4;

  { styles }
  WS_VISIBLE = $80000000; WS_DISABLED = $40000000; WS_CLIPCHILDREN = $20000000;
  WS_MINIMIZED = $01000000; WS_MAXIMIZED = $00800000; WS_GROUP = $00010000;
  WS_TABSTOP = $00020000;
  FS_ICON = 1; FS_ACCELTABLE = 2; FS_SHELLPOSITION = 4; FS_TASKLIST = 8;
  FS_SYSMODAL = $40; FS_DLGBORDER = $80; FS_BORDER = $100; FS_SIZEBORDER = $800;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MENU = 4; FCF_SIZEBORDER = 8;
  FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20; FCF_VERTSCROLL = $40; FCF_HORZSCROLL = $80;
  FCF_DLGBORDER = $100; FCF_BORDER = $200; FCF_SHELLPOSITION = $400; FCF_TASKLIST = $800;
  FCF_ACCELTABLE = $8000; FCF_SYSMODAL = $10000;
  FID_SYSMENU = $8002; FID_TITLEBAR = $8003; FID_MINMAX = $8004; FID_MENU = $8005;
  FID_VERTSCROLL = $8006; FID_HORZSCROLL = $8007; FID_CLIENT = $8008;
  BS_PUSHBUTTON = 0; BS_CHECKBOX = 1; BS_AUTOCHECKBOX = 2; BS_RADIOBUTTON = 3;
  BS_AUTORADIOBUTTON = 4; BS_3STATE = 5; BS_AUTO3STATE = 6; BS_USERBUTTON = 7;
  BS_DEFAULT = $0400;
  SS_TEXT = 1; SS_GROUPBOX = 2; SS_FGNDRECT = 5; SS_BKGNDRECT = 7; SS_FGNDFRAME = 8;
  ES_CENTER = 1; ES_RIGHT = 2; ES_READONLY = $20; ES_UNREADABLE = $80;
  SBS_VERT = 1;
  MS_ACTIONBAR = 1;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIS_SYSCOMMAND = $40; MIS_HELP = $80;
  MIA_CHECKED = $2000; MIA_DISABLED = $4000; MIA_HILITED = $8000;

  { positions }
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_HIDE = $10;
  SWP_NOREDRAW = $20; SWP_NOADJUST = $40; SWP_ACTIVATE = $80; SWP_DEACTIVATE = $100;
  SWP_MINIMIZE = $400; SWP_MAXIMIZE = $800; SWP_RESTORE = $1000;
  HWND_DESKTOP = 1; HWND_OBJECT = 2; HWND_TOP = 3; HWND_BOTTOM = 4;
  QW_NEXT = 0; QW_PREV = 1; QW_TOP = 2; QW_BOTTOM = 3; QW_OWNER = 4; QW_PARENT = 5;
  QW_NEXTTOP = 6; QW_PREVTOP = 7; QW_FRAMEOWNER = 8;
  QWS_ID = -1; QWL_STYLE = -2; QWP_PFNWP = -3; QWL_HMQ = -4; QWL_RESERVED = -5;

  { commandes du systeme }
  SC_SIZE = $8000; SC_MOVE = $8001; SC_MINIMIZE = $8002; SC_MAXIMIZE = $8003;
  SC_CLOSE = $8004; SC_APPMENU = $8006; SC_SYSMENU = $8007; SC_RESTORE = $8008;
  CMDSRC_PUSHBUTTON = 1; CMDSRC_MENU = 2; CMDSRC_ACCELERATOR = 3; CMDSRC_OTHER = 0;
  BN_CLICKED = 1; EN_SETFOCUS = 1; EN_KILLFOCUS = 2; EN_CHANGE = 4;
  LN_SELECT = 1; LN_ENTER = 5; SB_LINEUP = 1; SB_LINEDOWN = 2; SB_PAGEUP = 3; SB_PAGEDOWN = 4;
  SB_SLIDERPOSITION = 6; SB_ENDSCROLL = 7;
  DID_OK = 1; DID_CANCEL = 2;
  MBID_OK = 1; MBID_CANCEL = 2; MBID_ABORT = 3; MBID_RETRY = 4; MBID_IGNORE = 5;
  MBID_YES = 6; MBID_NO = 7; MBID_HELP = 8; MBID_ENTER = 9; MBID_ERROR = $FFFF;

  { clavier }
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SCANCODE = 4; KC_SHIFT = 8; KC_CTRL = $10;
  KC_ALT = $20; KC_KEYUP = $40;
  VK_BUTTON1 = 1; VK_BUTTON2 = 2; VK_BUTTON3 = 3; VK_BREAK = 4; VK_BACKSPACE = 5;
  VK_TAB = 6; VK_BACKTAB = 7; VK_NEWLINE = 8; VK_SHIFT = 9; VK_CTRL = $0A; VK_ALT = $0B;
  VK_PAUSE = $0D; VK_CAPSLOCK = $0E; VK_ESC = $0F; VK_SPACE = $10; VK_PAGEUP = $11;
  VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14; VK_LEFT = $15; VK_UP = $16;
  VK_RIGHT = $17; VK_DOWN = $18; VK_PRINTSCRN = $19; VK_INSERT = $1A; VK_DELETE = $1B;
  VK_SCRLLOCK = $1C; VK_NUMLOCK = $1D; VK_ENTER = $1E; VK_SYSRQ = $1F; VK_F1 = $20;
  AF_CHAR = 1; AF_VIRTUALKEY = 2; AF_SCANCODE = 4; AF_SHIFT = 8; AF_CONTROL = $10;
  AF_ALT = $20; AF_LONEKEY = $40; AF_SYSCOMMAND = $100; AF_HELP = $200;

  { erreurs (PMERR_*, gravite SEVERITY_ERROR) }
  PMERR_INVALID_HWND = $1001; PMERR_INVALID_HMQ = $1002;
  PMERR_PARAMETER_OUT_OF_RANGE = $1003; PMERR_WINDOW_LOCK_UNDERFLOW = $1004;
  PMERR_WINDOW_LOCK_OVERFLOW = $1005; PMERR_RESOURCE_NOT_FOUND = $100A;
  PMERR_INVALID_STRING_PARM = $100B; PMERR_INVALID_HHEAP = $100C;
  PMERR_INVALID_HEAP_POINTER = $100D; PMERR_HEAP_OUT_OF_MEMORY = $1011;
  PMERR_INVALID_HATOMTBL = $1013; PMERR_INVALID_ATOM = $1014;
  PMERR_INVALID_ATOM_NAME = $1015; PMERR_ATOM_NAME_NOT_FOUND = $1017;
  PMERR_INVALID_FLAG = $1019; PMERR_INVALID_HACCEL = $101A; PMERR_INVALID_HPTR = $101B;
  PMERR_INVALID_HENUM = $101C; PMERR_INVALID_SRC_CODEPAGE = $101D;
  PMERR_INVALID_DST_CODEPAGE = $101E; PMERR_NO_MSG_QUEUE = $1036; PMERR_QUEUE_FULL = $1038;
  PMERR_LIBRARY_LOAD_FAILED = $1039; PMERR_PROCEDURE_LOAD_FAILED = $103A;
  PMERR_INVALID_HAB = $104A; PMERR_NO_HANDLE_ALLOC = $1050;
  PMERR_MSG_QUEUE_ALREADY_EXISTS = $1052; PMERR_INVALID_HPS = $207F;
  PMERR_INVALID_PARAMETERS = $1208;
  SEVERITY_ERROR = 4;

  { limites }
  MaxWin = 1024;
  MaxCls = 128;
  MaxQ = 64;
  MaxHab = 64;
  MaxPS = 128;
  MaxItem = 1024;
  ItemSlot = 64;
  MaxTimer = 128;
  MaxHook = 32;
  MaxAtom = 512;
  AtomSlot = 64;
  MaxAtomTbl = 8;
  MaxAccel = 16;
  MaxPtr = 32;
  MaxBmp = 32;
  MaxHeap = 16;
  MaxPP = 128;
  MaxClip = 16;
  MaxEnum = 16;
  MaxLib = 16;
  KeyPendMax = 16;
  ArenaSize = 262144;

  { classes du systeme (WC_* = FFFF00nnh) }
  CK_FRAME = 1; CK_COMBOBOX = 2; CK_BUTTON = 3; CK_MENU = 4; CK_STATIC = 5;
  CK_ENTRYFIELD = 6; CK_LISTBOX = 7; CK_SCROLLBAR = 8; CK_TITLEBAR = 9; CK_MLE = 10;
  CK_GENERIC = 11; CK_DESKTOP = 98; CK_OBJECT = 99;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  { --- fenetres --- }
  WGen, WUse, WPid, WHmq, WCls, WProc, WStyle, WId, WPar, WOwner : Array[0..MaxWin - 1] Of LongInt;
  WX, WY, WCX, WCY, WZ, WData, WCbData, WLock, WFlags : Array[0..MaxWin - 1] Of LongInt;
  WUpd, WUx1, WUy1, WUx2, WUy2, WNoUpd, WThunk, WDC, WDestroyReg : Array[0..MaxWin - 1] Of LongInt;
  WS0, WS1, WS2, WS3, WS4, WS5 : Array[0..MaxWin - 1] Of LongInt;      { etat des controles }
  WRX, WRY, WRCX, WRCY : Array[0..MaxWin - 1] Of LongInt;            { position a restaurer }
  WInt0, WInt1 : Array[0..MaxWin - 1] Of LongInt;                    { interet des messages }
  WText : Array[0..MaxWin * 256 - 1] Of Byte;                        { longueur, texte }
  ZCounter : LongInt;
  { --- classes --- }
  CUse, CProc, CStyle, CCb, CPid, CKind, CThunk, CMsgMode, CInt0, CInt1 : Array[0..MaxCls - 1] Of LongInt;
  CName : Array[0..MaxCls * 64 - 1] Of Byte;
  SysProc : LongInt;                     { WINSYSCLASSPROC (_System) }
  DefProcAddr, DefDlgAddr : LongInt;
  { --- ancres et files --- }
  HabPid, HabErr, HabQ, HabMou : Array[0..MaxHab - 1] Of LongInt;
  QPid, QHab, QSize, QBuf, QHead, QCount, QCp, QStat, QLockIn, QAccel, QProc : Array[0..MaxQ - 1] Of LongInt;
  QPosX, QPosY, QTime, QQuit, QMou, QLastDown, QDownWin, QDownTime : Array[0..MaxQ - 1] Of LongInt;
  KpN : Array[0..MaxQ - 1] Of LongInt;                              { touches en attente }
  KpT, KpFs, KpCh, KpVk, KpSc : Array[0..MaxQ * 16 - 1] Of LongInt;
  { --- etat global --- }
  FocusWin, ActiveWin, CaptureWin, SysModalWin, LockUpdWin, VisLock : LongInt;
  PhysInput, ShuttingDown, NoShutdown, SemCount, FsrCount, InSend : LongInt;
  PtrCur, PtrLevel, CursorWin, CurX, CurY, CurCX, CurCY, CurFs, CurShown : LongInt;
  MouseX, MouseY, MouseBtn, LastMsgTime, TrackShown : LongInt;
  { --- espaces de presentation --- }
  PsUse, PsWin, PsX1, PsY1, PsX2, PsY2, PsOrgX, PsOrgY, PsKind : Array[0..MaxPS - 1] Of LongInt;
  { --- elements (listes, menus) --- }
  ItWin, ItPos, ItId, ItStyle, ItAttr, ItSub, ItHandle : Array[0..MaxItem - 1] Of LongInt;
  ItText : Array[0..MaxItem * ItemSlot - 1] Of Byte;
  { --- minuteries, crochets --- }
  TmUse, TmWin, TmId, TmQ, TmIntv, TmNext : Array[0..MaxTimer - 1] Of LongInt;
  HkUse, HkType, HkProc, HkQ, HkMod : Array[0..MaxHook - 1] Of LongInt;
  { --- atomes --- }
  AtUse, AtTbl : Array[0..MaxAtom - 1] Of LongInt;
  AtName : Array[0..MaxAtom * AtomSlot - 1] Of Byte;
  AtbUse, AtbOwner : Array[0..MaxAtomTbl - 1] Of LongInt;
  { --- accelerateurs, pointeurs, bitmaps, tas --- }
  AcUse, AcData, AcPid : Array[0..MaxAccel - 1] Of LongInt;
  PtUse, PtHotX, PtHotY, PtBmp, PtPid, PtAni : Array[0..MaxPtr - 1] Of LongInt;
  BmUse, BmCX, BmCY, BmData : Array[0..MaxBmp - 1] Of LongInt;
  HpUse, HpBase, HpSize : Array[0..MaxHeap - 1] Of LongInt;
  { --- parametres de presentation --- }
  PpWin, PpId, PpLen : Array[0..MaxPP - 1] Of LongInt;
  PpData : Array[0..MaxPP * 64 - 1] Of Byte;
  { --- presse-papiers --- }
  ClFmt, ClData, ClInfo : Array[0..MaxClip - 1] Of LongInt;
  ClOpen, ClOwner, ClViewer, ClSysViewer : LongInt;
  { --- enumerations, bibliotheques --- }
  EnUse, EnList, EnCount, EnPos : Array[0..MaxEnum - 1] Of LongInt;
  { --- valeurs et couleurs du systeme --- }
  SysVal : Array[0..127] Of LongInt;
  SysClr : Array[0..63] Of LongInt;      { SYSCLR_x : SysClr[-x] (RVB) }
  KeyState : Array[0..255] Of Byte;
  ScanState : Array[0..255] Of Byte;
  KbdLayout : Array[0..15] Of Byte;
  AabReg : Array[0..31] Of LongInt;
  DeskBkgnd : Array[0..299] Of Byte;
  SysFont : Array[0..63] Of Byte;
  VisCb : Array[0..7] Of LongInt;
  { --- memoire --- }
  Arena : Array[0..ArenaSize - 1] Of Byte;
  { --- tampons --- }
  NameZ, NameZ2 : Array[0..259] Of Byte;
  GMsg : Array[0..7] Of LongInt;         { QMSG de travail }
  Dummy, MyMod : LongInt;

Var
  GMode : LongInt;                        { 1 : ecran graphique }
  Susp, SuspPid, SuspTook : LongInt;      { ecran prete a un programme (WINSUSPENDSCREEN) }
  SesAddr, PmEpoch : LongInt;              { sessions du noyau (KrnSesCtl 15) }
  ScrCols, ScrRows, ScrCX, ScrCY : LongInt;
  GCx1, GCy1, GCx2, GCy2 : LongInt;       { decoupage (pels de l'ecran, x2 et y2 exclus) }
  GFont : Array[0..4095] Of Byte;         { police 8 x 16 }
  GMask : LongInt;                        { masque de bits courant du VGA }
  GPtrOn, GPtrX, GPtrY : LongInt;         { pointeur dessine (x, ligne du haut) }
  GPtrSave : Array[0..255] Of Byte;       { pels sous le pointeur }
  GCarWant, GCarOn : LongInt;             { curseur demande, curseur dessine }
  GCarX1, GCarY1, GCarX2, GCarY2 : LongInt;
  GCdX1, GCdY1, GCdX2, GCdY2 : LongInt;   { rectangle dessine }
  GShadow : Array[0..2399] Of Byte;       { caracteres de l'ecran (80 x 30) }
  BrdX, BrdY, TitleH, MenuH, VsbW, HsbH, MRowH, MPad : LongInt;
  GPl : Array[0..11] Of LongInt;
  HwBit : LongInt;
  POrd : Array[0..MaxWin - 1] Of LongInt;
  PCnt : LongInt;
  VkXlate, ChXlate : LongInt;
  HelpMod : LongInt;
  HelpFn : Array[1..6] Of LongInt;
  DebugEnabled : LongInt;
  InitDone : LongInt;

{ --- services des autres DLL --- }
Function DcSleep(Ms : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSleep';
Function DcBeep(Freq, Dur : LongInt) : LongInt; External 'DOSCALLS' Name 'DosBeep';
Function DcGetResource(H, T, Id, PP : LongInt) : LongInt; External 'DOSCALLS' Name 'DosGetResource';
Function DcQueryResourceSize(H, T, Id, PSize : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryResourceSize';
Function DcLoadModule(PObj, Cb, PName, PH : LongInt) : LongInt; External 'DOSCALLS' Name 'DosLoadModule';
Function DcFreeModule(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosFreeModule';
Function DcQueryProcAddr(H, Ord, PName, PP : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryProcAddr';
Function DcQueryModuleHandle(PName, PH : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryModuleHandle';
Function DcWaitEventSem(H, T : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWaitEventSem';
Function DcRequestMutexSem(H, T : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRequestMutexSem';
Function DcWaitMuxWaitSem(H, T, PU : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWaitMuxWaitSem';
Function DcSemWait(H, T : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSemWait';
Function DcMuxSemWait(PI, PL, T : LongInt) : LongInt; External 'DOSCALLS' Name 'DosMuxSemWait';
Function DcWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWrite';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';
Function KTask(Op, P1, P2, P3 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnTaskCtl';
Function KGetTickCount : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function KbdCharIn(PInfo, Wait, H : LongInt) : LongInt; External 'KBDCALLS' Name 'KbdCharIn';
Function MouOpen(PDrv, PH : LongInt) : LongInt; External 'MOUCALLS' Name 'MouOpen';
Function MouClose(H : LongInt) : LongInt; External 'MOUCALLS' Name 'MouClose';
Function MouReadEventQue(PEv, PWait, H : LongInt) : LongInt; External 'MOUCALLS' Name 'MouReadEventQue';
Function MouGetPtrPos(PPos, H : LongInt) : LongInt; External 'MOUCALLS' Name 'MouGetPtrPos';
Function MouSetPtrPos(PPos, H : LongInt) : LongInt; External 'MOUCALLS' Name 'MouSetPtrPos';
Function MouDrawPtr(H : LongInt) : LongInt; External 'MOUCALLS' Name 'MouDrawPtr';
Function MouRemovePtr(PRect, H : LongInt) : LongInt; External 'MOUCALLS' Name 'MouRemovePtr';
Function VioSetCurPos(Row, Col, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioSetCurPos';
Function VioSetCurType(PInfo, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioSetCurType';
Function VioSetMode(PMode, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioSetMode';
Function VioGetMode(PMode, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetMode';
Function VioGetFont(PInfo, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetFont';
Function DcScanEnv(PName, PP : LongInt) : LongInt; External 'DOSCALLS' Name 'DosScanEnv';

{ --- acces a la memoire --- }
Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V;
End;

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
End;

{ mot signe }
Function RdSW(A : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := RdW(A);
  If V >= $8000 Then V := V - $10000;
  RdSW := V;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FFFF;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FF;
End;

Procedure MemMove(Src, Dst, N : LongInt);
Var K : LongInt;
Begin
  If (Dst < Src) Then
  Begin
    For K := 0 To N - 1 Do WrB(Dst + K, RdB(Src + K));
  End
  Else
    For K := N - 1 DownTo 0 Do WrB(Dst + K, RdB(Src + K));
End;

Procedure MemZero(A, N : LongInt);
Var K : LongInt;
Begin
  For K := 0 To N - 1 Do WrB(A + K, 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (RdB(A + N) <> 0) And (N < 255) Do
    Begin
      S := S + Chr(RdB(A + N));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

{ N caracteres (N < 0 : jusqu'au zero) }
Function GetN(A, N : LongInt) : String;
Var S : String; K : LongInt;
Begin
  If N < 0 Then
  Begin
    GetN := GetZ(A);
    Exit;
  End;
  S := '';
  If A <> 0 Then
    For K := 0 To N - 1 Do
      If Length(S) < 255 Then S := S + Chr(RdB(A + K));
  GetN := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  If A = 0 Then Exit;
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

{ Copier S dans un tampon de Cb octets ; rend la longueur copiee }
Function PutZN(A, Cb : LongInt; S : String) : LongInt;
Begin
  PutZN := 0;
  If (A = 0) Or (Cb <= 0) Then Exit;
  If Length(S) > Cb - 1 Then S := Copy(S, 1, Cb - 1);
  PutZ(A, S);
  PutZN := Length(S);
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

Function IntStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IntStr := S;
End;

Function StrToIntDef(S : String; Var V : LongInt) : Boolean;
Var K, Sg, R : LongInt; Ok : Boolean;
Begin
  R := 0; Sg := 1; K := 1;
  While (K <= Length(S)) And (Ord(S[K]) = 32) Do Inc(K);
  If (K <= Length(S)) And ((Ord(S[K]) = 45) Or (Ord(S[K]) = 43)) Then
  Begin
    If Ord(S[K]) = 45 Then Sg := -1;
    Inc(K);
  End;
  Ok := K <= Length(S);
  While (K <= Length(S)) And Ok Do
  Begin
    If (Ord(S[K]) >= 48) And (Ord(S[K]) <= 57) Then R := R * 10 + Ord(S[K]) - 48
    Else If Ord(S[K]) <> 32 Then Ok := False;
    Inc(K);
  End;
  V := R * Sg;
  StrToIntDef := Ok;
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

Function Alive(Pid : LongInt) : Boolean;
Begin
  Alive := (Pid = 0) Or (Pid = MyPid) Or (KrnMonIo(0, 4, Pid) <> 0);
End;

Function Lo16(V : LongInt) : LongInt;
Begin
  Lo16 := V And $FFFF;
End;

Function Hi16(V : LongInt) : LongInt;
Begin
  Hi16 := (V Shr 16) And $FFFF;
End;

{ mot signe d'un double mot }
Function SLo(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V >= $8000 Then V := V - $10000;
  SLo := V;
End;

Function SHi(V : LongInt) : LongInt;
Begin
  V := (V Shr 16) And $FFFF;
  If V >= $8000 Then V := V - $10000;
  SHi := V;
End;

Function Mk2(A, B : LongInt) : LongInt;
Begin
  Mk2 := (A And $FFFF) Or ((B And $FFFF) Shl 16);
End;

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
End;

{ --- appel des procedures (programme OS2PC : Pascal ; sinon _System) --- }
Function CallSys4(F, A1, A2, A3, A4 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A4
    push eax
    mov eax,A3
    push eax
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,16
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallSys4 := R;
End;

Function CallPas4(F, A1, A2, A3, A4 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A1
    push eax
    mov eax,A2
    push eax
    mov eax,A3
    push eax
    mov eax,A4
    push eax
    mov eax,F
    call eax
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPas4 := R;
End;

Function CallSys3(F, A1, A2, A3 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A3
    push eax
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,12
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallSys3 := R;
End;

Function CallPas3(F, A1, A2, A3 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A1
    push eax
    mov eax,A2
    push eax
    mov eax,A3
    push eax
    mov eax,F
    call eax
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPas3 := R;
End;

Function CallSys5(F, A1, A2, A3, A4, A5 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A5
    push eax
    mov eax,A4
    push eax
    mov eax,A3
    push eax
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,20
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallSys5 := R;
End;

Function CallPas5(F, A1, A2, A3, A4, A5 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A1
    push eax
    mov eax,A2
    push eax
    mov eax,A3
    push eax
    mov eax,A4
    push eax
    mov eax,A5
    push eax
    mov eax,F
    call eax
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPas5 := R;
End;

Function IsPasProc(F : LongInt) : Boolean;
Begin
  IsPasProc := (F >= $00400000) And (F < $00800000);
End;

Function Call4(F, A1, A2, A3, A4 : LongInt) : LongInt;
Begin
  If F = 0 Then Call4 := 0
  Else If IsPasProc(F) Then Call4 := CallPas4(F, A1, A2, A3, A4)
  Else Call4 := CallSys4(F, A1, A2, A3, A4);
End;

Function Call3(F, A1, A2, A3 : LongInt) : LongInt;
Begin
  If F = 0 Then Call3 := 0
  Else If IsPasProc(F) Then Call3 := CallPas3(F, A1, A2, A3)
  Else Call3 := CallSys3(F, A1, A2, A3);
End;

Function Call5(F, A1, A2, A3, A4, A5 : LongInt) : LongInt;
Begin
  If F = 0 Then Call5 := 0
  Else If IsPasProc(F) Then Call5 := CallPas5(F, A1, A2, A3, A4, A5)
  Else Call5 := CallSys5(F, A1, A2, A3, A4, A5);
End;

{ --- memoire de la DLL : blocs (+0 taille | 1 si utilise, +4 processus) --- }
Function HeapAllocIn(Base, Size, N : LongInt) : LongInt;
Var P, BS, Need, R, K : LongInt;
Begin
  R := 0;
  Need := ((N + 7) And Not 7) + 8;
  P := 0;
  While (R = 0) And (P < Size) Do
  Begin
    BS := RdL(Base + P) And Not 1;
    If BS <= 0 Then P := Size
    Else
    Begin
      If (RdL(Base + P) And 1) = 0 Then
      Begin
        While (P + BS < Size) And ((RdL(Base + P + BS) And 1) = 0) And (RdL(Base + P + BS) > 0) Do
        Begin
          BS := BS + RdL(Base + P + BS);
          WrL(Base + P, BS);
        End;
        If BS >= Need Then
        Begin
          If BS - Need >= 16 Then
          Begin
            WrL(Base + P + Need, BS - Need);
            BS := Need;
          End;
          WrL(Base + P, BS Or 1);
          WrL(Base + P + 4, MyPid);
          R := Base + P + 8;
          For K := 0 To BS - 9 Do WrB(R + K, 0);
        End;
      End;
      P := P + BS;
    End;
  End;
  HeapAllocIn := R;
End;

Function HeapSizeOf(A : LongInt) : LongInt;
Begin
  HeapSizeOf := (RdL(A - 8) And Not 1) - 8;
End;

Procedure HeapFreeIn(A : LongInt);
Begin
  If A <> 0 Then WrL(A - 8, RdL(A - 8) And Not 1);
End;

Procedure HeapInitIn(Base, Size : LongInt);
Begin
  WrL(Base, Size And Not 7);
  WrL(Base + 4, 0);
End;

{ plus grand bloc libre }
Function HeapAvailIn(Base, Size : LongInt) : LongInt;
Var P, BS, M, Run : LongInt;
Begin
  M := 0; P := 0; Run := 0;
  While P < Size Do
  Begin
    BS := RdL(Base + P) And Not 1;
    If BS <= 0 Then P := Size
    Else
    Begin
      If (RdL(Base + P) And 1) = 0 Then Run := Run + BS Else Run := 0;
      If Run - 8 > M Then M := Run - 8;
      P := P + BS;
    End;
  End;
  HeapAvailIn := M;
End;

Function MemAlloc(N : LongInt) : LongInt;
Begin
  MemAlloc := HeapAllocIn(LongInt(@Arena), ArenaSize, N);
End;

Procedure MemFree(A : LongInt);
Begin
  HeapFreeIn(A);
End;

{ --- ancres (HAB) et erreurs --- }
Function HabIdx(Hab : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := Hab - $00010001;
  If (I >= 0) And (I < MaxHab) Then
  Begin
    If HabPid[I] = 0 Then I := -1;
  End
  Else I := -1;
  HabIdx := I;
End;

{ ancre du processus courant (-1 : aucune) }
Function CurHab : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := MaxHab - 1 DownTo 0 Do
    If HabPid[I] = MyPid Then R := I;
  CurHab := R;
End;

Procedure SetErr(Code : LongInt);
Var I : LongInt;
Begin
  I := CurHab;
  If I >= 0 Then
  Begin
    If Code = 0 Then HabErr[I] := 0 Else HabErr[I] := (SEVERITY_ERROR Shl 16) Or Code;
  End;
End;

{ --- couleurs --- }
Const
  VgaRgb : Array[0..15] Of LongInt = ($000000, $0000AA, $00AA00, $00AAAA, $AA0000, $AA00AA, $AA5500, $AAAAAA,
                                      $555555, $5555FF, $55FF55, $55FFFF, $FF5555, $FF55FF, $FFFF55, $FFFFFF);
  ClrVga : Array[0..15] Of LongInt = (7, 9, 12, 13, 10, 11, 14, 0, 8, 1, 4, 5, 2, 3, 6, 7);

{ Couleur PM -> couleur VGA (fond : 0 a 7) }
Function VgaColor(Clr : LongInt; Bg : Boolean) : LongInt;
Var R, I, Best, D, Dr, Dg, Db, BestD, Rgb, Lim : LongInt;
Begin
  Rgb := -1;
  R := 7;
  If Clr = -1 Then R := 0
  Else If Clr = -2 Then R := 15
  Else If Clr = -3 Then
  Begin
    If Bg Then Rgb := SysClr[20] Else Rgb := SysClr[17];
  End
  Else If (Clr <= -10) And (Clr >= -63) Then Rgb := SysClr[-Clr]
  Else If (Clr >= 0) And (Clr <= 15) Then R := ClrVga[Clr]
  Else If Clr > 15 Then Rgb := Clr And $FFFFFF;
  If Bg And (GMode = 0) Then Lim := 7 Else Lim := 15;
  If Rgb >= 0 Then
  Begin
    Best := 0; BestD := $7FFFFFFF;
    For I := 0 To Lim Do
    Begin
      Dr := ((Rgb Shr 16) And 255) - ((VgaRgb[I] Shr 16) And 255);
      Dg := ((Rgb Shr 8) And 255) - ((VgaRgb[I] Shr 8) And 255);
      Db := (Rgb And 255) - (VgaRgb[I] And 255);
      D := Dr * Dr + Dg * Dg + Db * Db;
      If D < BestD Then
      Begin
        BestD := D; Best := I;
      End;
    End;
    R := Best;
  End;
  If Bg And (R > 7) And (GMode = 0) Then R := R - 8;
  VgaColor := R;
End;

Function Attr(Fg, Bg : LongInt) : LongInt;
Begin
  Attr := VgaColor(Fg, False) Or (VgaColor(Bg, True) Shl 4);
End;

{ --- ressources --- }
Function GetRes(Hmod, Typ, Id : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := 0;
  If DcGetResource(Hmod, Typ, Id, LongInt(@P)) <> 0 Then P := 0;
  GetRes := P;
End;


{ ==================================================================== }
{ Partie 1b - Ecran graphique de PM (VGA 640 x 480 x 16 couleurs)      }
{ ==================================================================== }
{ Sauf si l'environnement contient PMMODE=TEXTE, la premiere file de
  messages passe l'ecran dans le mode 12h du VGA (VioSetMode) : 640 x 480
  pels de 16 couleurs, origine en bas a gauche. Les attributs (couleur du
  texte, couleur du fond) deviennent des couleurs de pels et le texte est
  dessine avec la police 8 x 16 du VGA ; les cadres, barres de titre,
  menus et controles sont dessines en relief. Le pointeur de la souris et
  le curseur sont superposes : ils sont retires avant un dessin qui les
  touche et remis quand le programme lit ses messages. }


Const
  { pointeur (fleche) : contour noir, interieur blanc ; bit 15 = pel de
    gauche }
  PtrB : Array[0..15] Of LongInt = ($8000, $C000, $A000, $9000, $8800, $8400, $8200, $8100,
                                    $8080, $83C0, $9200, $A900, $C900, $8480, $0480, $0300);
  PtrW : Array[0..15] Of LongInt = ($0000, $0000, $4000, $6000, $7000, $7800, $7C00, $7E00,
                                    $7F00, $7C00, $6C00, $4600, $0600, $0300, $0300, $0000);

{ --- ports du VGA --- }
{ l'ecran est-il a la session de l'appelant ? (session de PM au premier
  plan, ou bascule en cours) }
Function GMine : Boolean;
Type PLong = ^LongInt;
Var Q : PLong; F, C, S : LongInt;
Begin
  If SesAddr = 0 Then SesAddr := KSes(15, 0, 0);
  If SesAddr = 0 Then
  Begin
    GMine := True;
    Exit;
  End;
  Q := Pointer(SesAddr); F := Q^;
  Q := Pointer(SesAddr + 4); C := Q^;
  Q := Pointer(SesAddr + 12); S := Q^;
  GMine := (F = C) Or (S <> 0);
End;

Function SesEpoch : LongInt;
Type PLong = ^LongInt;
Var Q : PLong;
Begin
  If SesAddr = 0 Then SesAddr := KSes(15, 0, 0);
  If SesAddr = 0 Then SesEpoch := 0
  Else
  Begin
    Q := Pointer(SesAddr + 8);
    SesEpoch := Q^;
  End;
End;

Procedure GOut(P, V : LongInt);
Begin
  If Not GMine Then Exit;
  asm
    mov edx,P
    mov eax,V
    out dx,al
  end;
End;

Function GIn(P : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  asm
    mov edx,P
    xor eax,eax
    in al,dx
    mov R,eax
  end;
  GIn := R;
End;

{ ecriture dans les 4 plans : mode d'ecriture 2 (couleur dans l'octet
  ecrit), operation Op (0 remplacement, 3 ou exclusif) }
Procedure GBegin(Op : LongInt);
Begin
  GOut($3CE, 5); GOut($3CF, 2);
  GOut($3CE, 3); GOut($3CF, Op Shl 3);
  GOut($3C4, 2); GOut($3C5, $0F);
  GOut($3CE, 8); GOut($3CF, $FF);
  GMask := $FF;
End;

Procedure GEnd;
Begin
  GOut($3CE, 8); GOut($3CF, $FF);
  GOut($3CE, 3); GOut($3CF, 0);
  GOut($3CE, 5); GOut($3CF, 0);
  GMask := $FF;
End;

Procedure GSetMask(M : LongInt);
Begin
  If M <> GMask Then
  Begin
    GOut($3CE, 8); GOut($3CF, M);
    GMask := M;
  End;
End;

{ pels X1 a X2 - 1 de la ligne Row (0 en haut) dont le bit du motif est
  mis (bit 7 : x multiple de 8) }
Procedure GRow(Row, X1, X2, C, Pat : LongInt);
Var A, B, B1, B2, M : LongInt;
Begin
  If (X1 >= X2) Or (Row < 0) Or (Row >= ScrCY) Then Exit;
  A := $A0000 + Row * 80;
  B1 := X1 Shr 3; B2 := (X2 - 1) Shr 3;
  B := B1;
  While B <= B2 Do
  Begin
    M := Pat And $FF;
    If B = B1 Then M := M And ($FF Shr (X1 And 7));
    If B = B2 Then M := M And (($FF00 Shr (((X2 - 1) And 7) + 1)) And $FF);
    If M <> 0 Then
    Begin
      GSetMask(M);
      Dummy := RdB(A + B);
      WrB(A + B, C);
    End;
    Inc(B);
  End;
End;

{ 8 pels (bit 7 a gauche) a partir de x sur la ligne Row }
Procedure GMask8(Row, X, Bits, C : LongInt);
Var A, Sh, M0, M1 : LongInt;
Begin
  Bits := Bits And $FF;
  If (Bits = 0) Or (Row < 0) Or (Row >= ScrCY) Then Exit;
  If X < 0 Then
  Begin
    If X <= -8 Then Exit;
    Bits := (Bits Shl (-X)) And $FF;
    X := 0;
    If Bits = 0 Then Exit;
  End;
  A := $A0000 + Row * 80 + (X Shr 3);
  Sh := X And 7;
  M0 := Bits Shr Sh;
  If Sh <> 0 Then M1 := (Bits Shl (8 - Sh)) And $FF Else M1 := 0;
  If M0 <> 0 Then
  Begin
    GSetMask(M0);
    Dummy := RdB(A);
    WrB(A, C);
  End;
  If (M1 <> 0) And ((X Shr 3) < 79) Then
  Begin
    GSetMask(M1);
    Dummy := RdB(A + 1);
    WrB(A + 1, C);
  End;
End;

{ couleur d'un pel (x, ligne du haut) }
Function GGetRaw(X, Row : LongInt) : LongInt;
Var A, M, P, V : LongInt;
Begin
  V := 0;
  If (X >= 0) And (X < ScrCX) And (Row >= 0) And (Row < ScrCY) Then
  Begin
    A := $A0000 + Row * 80 + (X Shr 3);
    M := $80 Shr (X And 7);
    For P := 0 To 3 Do
    Begin
      GOut($3CE, 4); GOut($3CF, P);
      If (RdB(A) And M) <> 0 Then V := V Or (1 Shl P);
    End;
    GOut($3CE, 4); GOut($3CF, 0);
  End;
  GGetRaw := V;
End;

{ --- pointeur de la souris --- }
Procedure GPtrHide;
Var R, X, Row, C, Px : LongInt;
Begin
  If GPtrOn = 0 Then Exit;
  GPtrOn := 0;
  GBegin(0);
  For R := 0 To 15 Do
  Begin
    Row := GPtrY + R;
    For X := 0 To 15 Do
    Begin
      Px := GPtrX + X;
      If (Px < ScrCX) And (((PtrB[R] Or PtrW[R]) And ($8000 Shr X)) <> 0) Then
      Begin
        C := GPtrSave[R * 16 + X];
        GMask8(Row, Px And Not 7, $80 Shr (Px And 7), C);
      End;
    End;
  End;
  GEnd;
End;

Procedure GPtrDraw(X0, Row0 : LongInt);
Var R, X, Row, Px, B, P, Bt, A, N, V : LongInt;
Begin
  GPtrX := X0; GPtrY := Row0;
  { pels sous le pointeur : 3 octets par plan et par ligne }
  For R := 0 To 15 Do
  Begin
    Row := Row0 + R;
    If (Row >= 0) And (Row < ScrCY) Then
    Begin
      A := $A0000 + Row * 80 + (X0 Shr 3);
      For P := 0 To 3 Do
      Begin
        GOut($3CE, 4); GOut($3CF, P);
        For Bt := 0 To 2 Do
          If (X0 Shr 3) + Bt < 80 Then GPl[P * 3 + Bt] := RdB(A + Bt) Else GPl[P * 3 + Bt] := 0;
      End;
      For X := 0 To 15 Do
      Begin
        B := (X0 And 7) + X;
        V := 0;
        For P := 0 To 3 Do
          If (GPl[P * 3 + (B Shr 3)] And ($80 Shr (B And 7))) <> 0 Then V := V Or (1 Shl P);
        GPtrSave[R * 16 + X] := V;
      End;
    End;
  End;
  GOut($3CE, 4); GOut($3CF, 0);
  GBegin(0);
  For R := 0 To 15 Do
  Begin
    Row := Row0 + R;
    If (Row >= 0) And (Row < ScrCY) Then
      For X := 0 To 15 Do
      Begin
        Px := X0 + X;
        N := $8000 Shr X;
        If Px < ScrCX Then
        Begin
          If (PtrB[R] And N) <> 0 Then GMask8(Row, Px And Not 7, $80 Shr (Px And 7), 0)
          Else If (PtrW[R] And N) <> 0 Then GMask8(Row, Px And Not 7, $80 Shr (Px And 7), 15);
        End;
      End;
  End;
  GEnd;
  GPtrOn := 1;
End;

{ --- curseur (rectangle inverse) --- }
Procedure GXorRaw(X1, Y1, X2, Y2 : LongInt);
Var Y : LongInt;
Begin
  X1 := MaxI(X1, 0); Y1 := MaxI(Y1, 0); X2 := MinI(X2, ScrCX); Y2 := MinI(Y2, ScrCY);
  If (X1 >= X2) Or (Y1 >= Y2) Then Exit;
  GBegin(3);
  Y := Y1;
  While Y < Y2 Do
  Begin
    GRow(ScrCY - 1 - Y, X1, X2, 15, $FF);
    Inc(Y);
  End;
  GEnd;
End;

Function GHits(X1, Y1, X2, Y2, A1, B1, A2, B2 : LongInt) : Boolean;
Begin
  GHits := (X1 < A2) And (A1 < X2) And (Y1 < B2) And (B1 < Y2);
End;

Procedure GCarHide;
Begin
  If GCarOn = 0 Then Exit;
  If (GPtrOn <> 0) And GHits(GCdX1, GCdY1, GCdX2, GCdY2, GPtrX, ScrCY - GPtrY - 16, GPtrX + 16, ScrCY - GPtrY) Then GPtrHide;
  GXorRaw(GCdX1, GCdY1, GCdX2, GCdY2);
  GCarOn := 0;
End;

{ retirer ce qui est superpose au rectangle (pels de l'ecran) }
Procedure GHide(X1, Y1, X2, Y2 : LongInt);
Begin
  If (GPtrOn <> 0) And GHits(X1, Y1, X2, Y2, GPtrX, ScrCY - GPtrY - 16, GPtrX + 16, ScrCY - GPtrY) Then GPtrHide;
  If (GCarOn <> 0) And GHits(X1, Y1, X2, Y2, GCdX1, GCdY1, GCdX2, GCdY2) Then GCarHide;
End;

Procedure GHideAll;
Begin
  GPtrHide;
  GCarHide;
End;

{ --- texte de l'ecran (programmes d'essai) --- }
Procedure GShadowClear(X1, Y1, X2, Y2 : LongInt);
Var C, R, Top : LongInt;
Begin
  For R := 0 To ScrRows - 1 Do
  Begin
    Top := ScrCY - R * 16;
    If (Top - 16 >= Y1) And (Top <= Y2) Then
      For C := 0 To ScrCols - 1 Do
        If (C * 8 >= X1) And (C * 8 + 8 <= X2) Then GShadow[R * 80 + C] := 32;
  End;
End;

Procedure GShadowSet(X, Y, Ch : LongInt);
Var C, R : LongInt;
Begin
  If (X < 0) Or (Y < 0) Or (Y + 16 > ScrCY) Then Exit;
  C := (X + 4) Div 8;
  R := (ScrCY - Y - 16 + 8) Div 16;
  If (C >= 0) And (C < ScrCols) And (R >= 0) And (R < ScrRows) Then GShadow[R * 80 + C] := Ch And 255;
End;

{ --- dessin (pels de l'ecran, y vers le haut, decoupage GCx1...) --- }
Procedure GClipAll;
Begin
  GCx1 := 0; GCy1 := 0; GCx2 := ScrCX; GCy2 := ScrCY;
End;

Procedure GClip(X1, Y1, X2, Y2 : LongInt);
Begin
  GCx1 := MaxI(X1, 0); GCy1 := MaxI(Y1, 0); GCx2 := MinI(X2, ScrCX); GCy2 := MinI(Y2, ScrCY);
End;

{ rectangle de couleur C ; Pat : motif (FFh plein, AAh damier) ; Op : 0
  remplacement, 3 ou exclusif }
Procedure GFillPat(X1, Y1, X2, Y2, C, Pat, Op : LongInt);
Var Y, P : LongInt;
Begin
  X1 := MaxI(X1, GCx1); Y1 := MaxI(Y1, GCy1); X2 := MinI(X2, GCx2); Y2 := MinI(Y2, GCy2);
  If (X1 >= X2) Or (Y1 >= Y2) Then Exit;
  GHide(X1, Y1, X2, Y2);
  GBegin(Op);
  Y := Y1;
  While Y < Y2 Do
  Begin
    P := Pat;
    If (Pat = $AA) And ((Y And 1) <> 0) Then P := $55;
    GRow(ScrCY - 1 - Y, X1, X2, C And 15, P);
    Inc(Y);
  End;
  GEnd;
  If (Pat = $FF) And (Op = 0) Then GShadowClear(X1, Y1, X2, Y2);
End;

Procedure GFill(X1, Y1, X2, Y2, C : LongInt);
Begin
  GFillPat(X1, Y1, X2, Y2, C, $FF, 0);
End;

Procedure GHLine(X1, X2, Y, C : LongInt);
Begin
  GFill(X1, Y, X2, Y + 1, C);
End;

Procedure GVLine(X, Y1, Y2, C : LongInt);
Begin
  GFill(X, Y1, X + 1, Y2, C);
End;

Procedure GPix(X, Y, C : LongInt);
Begin
  GFill(X, Y, X + 1, Y + 1, C);
End;

{ contour d'un pel }
Procedure GFrame(X1, Y1, X2, Y2, C : LongInt);
Begin
  If (X1 >= X2) Or (Y1 >= Y2) Then Exit;
  GHLine(X1, X2, Y2 - 1, C); GHLine(X1, X2, Y1, C);
  GVLine(X1, Y1, Y2, C); GVLine(X2 - 1, Y1, Y2, C);
End;

{ relief de W pels : Lt en haut et a gauche, Dk en bas et a droite }
Procedure GBevel(X1, Y1, X2, Y2, Lt, Dk, W : LongInt);
Var I : LongInt;
Begin
  I := 0;
  While (I < W) And (X1 + I < X2 - I) And (Y1 + I < Y2 - I) Do
  Begin
    GHLine(X1 + I, X2 - I, Y2 - 1 - I, Lt);
    GVLine(X1 + I, Y1 + I, Y2 - I, Lt);
    GHLine(X1 + I, X2 - I, Y1 + I, Dk);
    GVLine(X2 - 1 - I, Y1 + I, Y2 - I, Dk);
    Inc(I);
  End;
End;

{ segment (Bresenham) }
Procedure GLine(X1, Y1, X2, Y2, C : LongInt);
Var Dx, Dy, Sx, Sy, E, E2, N : LongInt;
Begin
  Dx := X2 - X1; If Dx < 0 Then Dx := -Dx;
  Dy := Y2 - Y1; If Dy < 0 Then Dy := -Dy;
  If X1 < X2 Then Sx := 1 Else Sx := -1;
  If Y1 < Y2 Then Sy := 1 Else Sy := -1;
  E := Dx - Dy;
  N := 0;
  While N < 2048 Do
  Begin
    GPix(X1, Y1, C);
    If (X1 = X2) And (Y1 = Y2) Then N := 2048
    Else
    Begin
      E2 := 2 * E;
      If E2 > -Dy Then
      Begin
        E := E - Dy; X1 := X1 + Sx;
      End;
      If E2 < Dx Then
      Begin
        E := E + Dx; Y1 := Y1 + Sy;
      End;
    End;
    Inc(N);
  End;
End;

{ fleche pleine dans le rectangle : 0 haut, 1 bas, 2 gauche, 3 droite }
Procedure GArrow(X1, Y1, X2, Y2, Dir, C : LongInt);
Var Cx, Cy, S, I, T : LongInt;
Begin
  Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
  S := MaxI(2, (MinI(X2 - X1, Y2 - Y1) + 1) Div 3);
  T := S Div 2;
  I := 0;
  While I < S Do
  Begin
    Case Dir Of
      0 : GFill(Cx - I, Cy + T - I, Cx + I + 1, Cy + T - I + 1, C);
      1 : GFill(Cx - I, Cy - T + I, Cx + I + 1, Cy - T + I + 1, C);
      2 : GFill(Cx - T + I, Cy - I, Cx - T + I + 1, Cy + I + 1, C);
      3 : GFill(Cx + T - I, Cy - I, Cx + T - I + 1, Cy + I + 1, C);
    End;
    Inc(I);
  End;
End;

{ disque plein de rayon R }
Procedure GDisc(Cx, Cy, R, C : LongInt);
Var Y, W : LongInt;
Begin
  Y := -R;
  While Y <= R Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) + Y * Y <= R * R + R Do Inc(W);
    GFill(Cx - W, Cy + Y, Cx + W + 1, Cy + Y + 1, C);
    Inc(Y);
  End;
End;

{ caractere 8 x 16 : coin bas gauche (x, y) ; Opaque : fond Bg }
Procedure GGlyph(X, Y, Ch, Fg, Bg : LongInt; Opaque : Boolean);
Var R, Bits, Cm, I, Yy, Row : LongInt;
Begin
  If (X + 8 <= GCx1) Or (X >= GCx2) Or (Y + 16 <= GCy1) Or (Y >= GCy2) Then Exit;
  GHide(X, Y, X + 8, Y + 16);
  Cm := 0;
  For I := 0 To 7 Do
    If (X + I >= GCx1) And (X + I < GCx2) Then Cm := Cm Or ($80 Shr I);
  GBegin(0);
  For R := 0 To 15 Do
  Begin
    Yy := Y + 15 - R;
    If (Yy >= GCy1) And (Yy < GCy2) Then
    Begin
      Row := ScrCY - 1 - Yy;
      Bits := GFont[(Ch And 255) * 16 + R];
      GMask8(Row, X, Bits And Cm, Fg And 15);
      If Opaque Then GMask8(Row, X, (Not Bits) And Cm, Bg And 15);
    End;
  End;
  GEnd;
  If (Cm = $FF) And (Y >= GCy1) And (Y + 16 <= GCy2) Then GShadowSet(X, Y, Ch);
End;

{ texte (au plus N caracteres) ; le caractere suivant un ~ est souligne
  si Mn }
Procedure GText(X, Y : LongInt; S : String; N, Fg, Bg : LongInt; Opaque, Mn : Boolean);
Var J, Ch : LongInt; Hi : Boolean;
Begin
  Hi := False;
  J := 1;
  While (J <= Length(S)) And (N > 0) Do
  Begin
    Ch := Ord(S[J]);
    If Mn And (Ch = 126) And Not Hi Then Hi := True
    Else
    Begin
      GGlyph(X, Y, Ch, Fg, Bg, Opaque);
      If Hi Then GHLine(X, X + 7, Y + 1, Fg);
      Hi := False;
      X := X + 8;
      Dec(N);
    End;
    Inc(J);
  End;
End;

{ largeur visible d'un texte (sans les ~) }
Function GTextW(S : String; Mn : Boolean) : LongInt;
Var J, N : LongInt;
Begin
  N := 0;
  For J := 1 To Length(S) Do
    If Not (Mn And (Ord(S[J]) = 126)) Then Inc(N);
  GTextW := N * 8;
End;

{ metriques du mode (pels) }
Procedure GMetrics;
Begin
  ScrCols := 80;
  If GMode <> 0 Then
  Begin
    ScrCX := 640; ScrCY := 480; ScrRows := 30;
    BrdX := 4; BrdY := 4; TitleH := 20; MenuH := 20; VsbW := 16; HsbH := 16; MRowH := 20; MPad := 3;
  End
  Else
  Begin
    ScrCX := 640; ScrCY := 400; ScrRows := 25;
    BrdX := 8; BrdY := 16; TitleH := 16; MenuH := 16; VsbW := 8; HsbH := 16; MRowH := 16; MPad := 16;
  End;
  GClipAll;
End;

{ deplacer le contenu du rectangle de (Dx, Dy) pels (Dx multiple de 8) :
  octets entiers copies par les registres de verrouillage du VGA }
Procedure GScroll(X1, Y1, X2, Y2, Dx, Dy : LongInt);
Var B1, B2, Db, Y, Ys, B, Bs, Ad, As, Stp, Ye : LongInt;
Begin
  B1 := (X1 + 7) Shr 3; B2 := X2 Shr 3;
  If B1 >= B2 Then Exit;
  Db := Dx Div 8;
  GHideAll;
  GOut($3CE, 5); GOut($3CF, 1);
  GOut($3C4, 2); GOut($3C5, $0F);
  If Dy > 0 Then
  Begin
    Y := Y2 - 1; Ye := Y1 - 1; Stp := -1;
  End
  Else
  Begin
    Y := Y1; Ye := Y2; Stp := 1;
  End;
  While Y <> Ye Do
  Begin
    Ys := Y - Dy;
    If (Ys >= Y1) And (Ys < Y2) Then
    Begin
      Ad := $A0000 + (ScrCY - 1 - Y) * 80;
      As := $A0000 + (ScrCY - 1 - Ys) * 80;
      If Db > 0 Then
      Begin
        B := B2 - 1;
        While B >= B1 Do
        Begin
          Bs := B - Db;
          If (Bs >= B1) And (Bs < B2) Then
          Begin
            Dummy := RdB(As + Bs);
            WrB(Ad + B, 0);
          End;
          Dec(B);
        End;
      End
      Else
      Begin
        B := B1;
        While B < B2 Do
        Begin
          Bs := B - Db;
          If (Bs >= B1) And (Bs < B2) Then
          Begin
            Dummy := RdB(As + Bs);
            WrB(Ad + B, 0);
          End;
          Inc(B);
        End;
      End;
    End;
    Y := Y + Stp;
  End;
  GOut($3CE, 5); GOut($3CF, 0);
End;

{ couleur du VGA la plus proche d'une couleur RVB }
Function GNear(Rgb : LongInt) : LongInt;
Var I, B, D, Bd, Dr, Dg, Db : LongInt;
Begin
  B := 0; Bd := $7FFFFFFF;
  For I := 0 To 15 Do
  Begin
    Dr := ((Rgb Shr 16) And 255) - ((VgaRgb[I] Shr 16) And 255);
    Dg := ((Rgb Shr 8) And 255) - ((VgaRgb[I] Shr 8) And 255);
    Db := (Rgb And 255) - (VgaRgb[I] And 255);
    D := Dr * Dr + Dg * Dg + Db * Db;
    If D < Bd Then
    Begin
      Bd := D; B := I;
    End;
  End;
  GNear := B;
End;

{ bitmap OS/2 (BITMAPFILEHEADER, ou tableau 'BA') dans le rectangle de
  l'ecran (etiree) ; une bitmap monochrome prend les couleurs Fg (1) et
  Bg (0) }
Procedure GBitmap(P, X1, Y1, X2, Y2, Fg, Bg : LongInt; Inv : Boolean);
Var Hd, Cx, Cy, Bpp, Pal, PalSz, Bits, Stride, X, Y, Sx, Sy, V, C, A, Run, RunC, J, N : LongInt;
    Map : Array[0..255] Of Byte;
Begin
  If P = 0 Then Exit;
  If RdW(P) = $4142 Then P := P + 14;
  If RdW(P) <> $4D42 Then Exit;
  Hd := P + 14;
  If RdL(Hd) = 12 Then
  Begin
    Cx := RdW(Hd + 4); Cy := RdW(Hd + 6); Bpp := RdW(Hd + 10); PalSz := 3;
  End
  Else
  Begin
    Cx := RdL(Hd + 4); Cy := RdL(Hd + 8); Bpp := RdW(Hd + 14); PalSz := 4;
  End;
  If (Cx <= 0) Or (Cy <= 0) Or (X1 >= X2) Or (Y1 >= Y2) Then Exit;
  If (Bpp <> 1) And (Bpp <> 4) And (Bpp <> 8) And (Bpp <> 24) Then Exit;
  Pal := Hd + RdL(Hd);
  Bits := P + RdL(P + 10);
  Stride := ((Cx * Bpp + 31) Div 32) * 4;
  If Bpp <= 8 Then
  Begin
    N := 1 Shl Bpp;
    For J := 0 To N - 1 Do
      Map[J] := GNear(RdB(Pal + J * PalSz) Or (RdB(Pal + J * PalSz + 1) Shl 8) Or (RdB(Pal + J * PalSz + 2) Shl 16));
    If Bpp = 1 Then
    Begin
      Map[0] := Bg And 15; Map[1] := Fg And 15;
    End;
  End;
  Y := Y1;
  While Y < Y2 Do
  Begin
    Sy := ((Y - Y1) * Cy) Div (Y2 - Y1);
    A := Bits + Sy * Stride;
    Run := X1; RunC := -1;
    X := X1;
    While X < X2 Do
    Begin
      Sx := ((X - X1) * Cx) Div (X2 - X1);
      Case Bpp Of
        1 : C := Map[(RdB(A + Sx Shr 3) Shr (7 - (Sx And 7))) And 1];
        4 : Begin
              V := RdB(A + Sx Shr 1);
              If (Sx And 1) = 0 Then V := V Shr 4 Else V := V And 15;
              C := Map[V];
            End;
        8 : C := Map[RdB(A + Sx)];
      Else
        C := GNear(RdB(A + Sx * 3) Or (RdB(A + Sx * 3 + 1) Shl 8) Or (RdB(A + Sx * 3 + 2) Shl 16));
      End;
      If Inv Then C := 15 - C;
      If C <> RunC Then
      Begin
        If RunC >= 0 Then GFill(Run, Y, X, Y + 1, RunC);
        Run := X; RunC := C;
      End;
      Inc(X);
    End;
    If RunC >= 0 Then GFill(Run, Y, X2, Y + 1, RunC);
    Inc(Y);
  End;
End;

{ bitmap du systeme (SBMP_*) : bouton en relief avec un symbole }
Procedure GSysBitmap(N, X1, Y1, X2, Y2 : LongInt);
Var Cx, Cy : LongInt;
Begin
  GFill(X1, Y1, X2, Y2, 7);
  GBevel(X1, Y1, X2, Y2, 15, 8, 1);
  Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
  Case N Of
    2 : GArrow(X1, Y1, X2, Y2, 0, 0);
    3 : GArrow(X1, Y1, X2, Y2, 1, 0);
    4 : GArrow(X1, Y1, X2, Y2, 3, 0);
    5 : GArrow(X1, Y1, X2, Y2, 2, 0);
    6 : Begin
          GLine(Cx - 4, Cy, Cx - 1, Cy - 3, 0); GLine(Cx - 1, Cy - 3, Cx + 4, Cy + 3, 0);
        End;
    9, 26 : GArrow(X1, Y1, X2, Y2, 1, 0);
    10, 27 : GArrow(X1, Y1, X2, Y2, 0, 0);
    11, 28 : Begin
               GArrow(X1, Cy, X2, Y2, 0, 0); GArrow(X1, Y1, X2, Cy, 1, 0);
             End;
    1, 12, 25 : GFill(Cx - 4, Cy - 1, Cx + 4, Cy + 1, 0);
  Else
    GFrame(Cx - 3, Cy - 3, Cx + 3, Cy + 3, 0);
  End;
End;

{ image du pointeur : coin bas gauche (x, y) }
Procedure GPtrImage(X, Y : LongInt);
Var R, C : LongInt;
Begin
  For R := 0 To 15 Do
    For C := 0 To 15 Do
      If (PtrB[R] And ($8000 Shr C)) <> 0 Then GPix(X + C, Y + 15 - R, 0)
      Else If (PtrW[R] And ($8000 Shr C)) <> 0 Then GPix(X + C, Y + 15 - R, 15);
End;


{ ==================================================================== }
{ Partie 2 - Fenetres et classes                                       }
{ ==================================================================== }


Procedure InvalScreen(X1, Y1, X2, Y2 : LongInt); Forward;
Procedure InvalWin(I : LongInt); Forward;
Function SendM(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; Forward;
Function PostM(Hwnd, Msg, Mp1, Mp2 : LongInt) : Boolean; Forward;
Procedure FocusTo(I : LongInt); Forward;
Function CurQ : LongInt; Forward;
Procedure FreeItemsOf(I : LongInt); Forward;
Procedure CallHooks3(Typ, A1, A2, A3 : LongInt); Forward;
Procedure EnsureInit; Forward;
Procedure ScreenStart; Forward;

Function HwOf(I : LongInt) : LongInt;
Begin
  If I < 0 Then HwOf := 0 Else HwOf := HwBit Or ((WGen[I] And $1FFFFF) Shl 10) Or I;
End;

{ Rang d'une fenetre ; -1 si le handle est invalide }
Function WIdx(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  If H = HWND_DESKTOP Then R := 0
  Else If H = HWND_OBJECT Then R := 1
  Else If (H And HwBit) <> 0 Then
  Begin
    I := H And $3FF;
    If (WUse[I] <> 0) And (HwOf(I) = H) Then R := I;
  End;
  WIdx := R;
End;

{ Rang d'une fenetre (erreur PMERR_INVALID_HWND si invalide) }
Function WChk(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WIdx(H);
  If I < 0 Then SetErr(PMERR_INVALID_HWND);
  WChk := I;
End;

Function WTextGet(I : LongInt) : String;
Var S : String; K, N : LongInt;
Begin
  S := '';
  N := WText[I * 256];
  For K := 1 To N Do S := S + Chr(WText[I * 256 + K]);
  WTextGet := S;
End;

Procedure WTextSet(I : LongInt; S : String);
Var K : LongInt;
Begin
  WText[I * 256] := Length(S);
  For K := 1 To Length(S) Do WText[I * 256 + K] := Ord(S[K]);
End;

{ --- position absolue, visibilite --- }
Function AbsX(I : LongInt) : LongInt;
Var X, N : LongInt;
Begin
  X := 0; N := 0;
  While (I > 1) And (N < 64) Do
  Begin
    X := X + WX[I];
    I := WPar[I];
    Inc(N);
  End;
  AbsX := X;
End;

Function AbsY(I : LongInt) : LongInt;
Var Y, N : LongInt;
Begin
  Y := 0; N := 0;
  While (I > 1) And (N < 64) Do
  Begin
    Y := Y + WY[I];
    I := WPar[I];
    Inc(N);
  End;
  AbsY := Y;
End;

{ La fenetre et ses parents sont-ils visibles (et sur le bureau) ? }
Function Shown(I : LongInt) : Boolean;
Var Ok : Boolean; N : LongInt;
Begin
  Ok := True; N := 0;
  While Ok And (I <> 0) And (N < 64) Do
  Begin
    If (I = 1) Or ((WStyle[I] And WS_VISIBLE) = 0) Then Ok := False;
    I := WPar[I];
    Inc(N);
  End;
  Shown := Ok;
End;

{ Rectangle visible (ecran) : la fenetre limitee par ses parents ;
  faux s'il est vide }
Function VisRect(I : LongInt; Var X1, Y1, X2, Y2 : LongInt) : Boolean;
Var J, N, AX, AY : LongInt;
Begin
  X1 := AbsX(I); Y1 := AbsY(I);
  X2 := X1 + WCX[I]; Y2 := Y1 + WCY[I];
  J := WPar[I]; N := 0;
  While (J > 0) And (N < 64) Do
  Begin
    AX := AbsX(J); AY := AbsY(J);
    X1 := MaxI(X1, AX); Y1 := MaxI(Y1, AY);
    X2 := MinI(X2, AX + WCX[J]); Y2 := MinI(Y2, AY + WCY[J]);
    J := WPar[J];
    Inc(N);
  End;
  X1 := MaxI(X1, 0); Y1 := MaxI(Y1, 0);
  X2 := MinI(X2, ScrCX); Y2 := MinI(Y2, ScrCY);
  VisRect := (X1 < X2) And (Y1 < Y2) And Shown(I);
End;

{ --- ordre de superposition (Z plus grand : au-dessus) --- }
Function ChildTop(P : LongInt) : LongInt;
Var I, R, Z : LongInt;
Begin
  R := -1; Z := -2147483647;
  For I := 2 To MaxWin - 1 Do
    If (WUse[I] <> 0) And (WPar[I] = P) And (WZ[I] > Z) Then
    Begin
      R := I; Z := WZ[I];
    End;
  ChildTop := R;
End;

Function ChildBottom(P : LongInt) : LongInt;
Var I, R, Z : LongInt;
Begin
  R := -1; Z := 2147483647;
  For I := 2 To MaxWin - 1 Do
    If (WUse[I] <> 0) And (WPar[I] = P) And (WZ[I] < Z) Then
    Begin
      R := I; Z := WZ[I];
    End;
  ChildBottom := R;
End;

{ Frere suivant (au-dessous) ou precedent (au-dessus) }
Function SibNext(W : LongInt; Below : Boolean) : LongInt;
Var I, R, Z : LongInt;
Begin
  R := -1;
  If Below Then Z := -2147483647 Else Z := 2147483647;
  For I := 2 To MaxWin - 1 Do
    If (WUse[I] <> 0) And (I <> W) And (WPar[I] = WPar[W]) Then
    Begin
      If Below And (WZ[I] < WZ[W]) And (WZ[I] > Z) Then
      Begin
        R := I; Z := WZ[I];
      End;
      If (Not Below) And (WZ[I] > WZ[W]) And (WZ[I] < Z) Then
      Begin
        R := I; Z := WZ[I];
      End;
    End;
  SibNext := R;
End;

Procedure ZTop(I : LongInt);
Begin
  Inc(ZCounter);
  WZ[I] := ZCounter;
End;

Procedure ZBottom(I : LongInt);
Var J, M : LongInt;
Begin
  M := 0;
  For J := 2 To MaxWin - 1 Do
    If (WUse[J] <> 0) And (WPar[J] = WPar[I]) And (J <> I) And (WZ[J] < M) Then M := WZ[J];
  WZ[I] := M - 1;
End;

{ Placer I juste sous la fenetre B }
Procedure ZBehind(I, B : LongInt);
Var J : LongInt;
Begin
  For J := 2 To MaxWin - 1 Do
    If (WUse[J] <> 0) And (WPar[J] = WPar[I]) And (J <> I) And (WZ[J] < WZ[B]) Then Dec(WZ[J]);
  WZ[I] := WZ[B] - 1;
End;

Function IsChildOf(I, P : LongInt) : Boolean;
Var N : LongInt; R : Boolean;
Begin
  R := False; N := 0;
  While (I > 1) And Not R And (N < 64) Do
  Begin
    I := WPar[I];
    If I = P Then R := True;
    Inc(N);
  End;
  IsChildOf := R;
End;

{ Cadre de premier niveau contenant la fenetre }
Function TopFrame(I : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  While (I > 1) And (WPar[I] > 1) And (N < 64) Do
  Begin
    I := WPar[I];
    Inc(N);
  End;
  TopFrame := I;
End;

{ --- classes --- }
Function ClsGet(I : LongInt) : String;
Var S : String; K, N : LongInt;
Begin
  S := '';
  N := CName[I * 64];
  For K := 1 To N Do S := S + Chr(CName[I * 64 + K]);
  ClsGet := S;
End;

Procedure ClsSet(I : LongInt; S : String);
Var K : LongInt;
Begin
  S := Copy(S, 1, 63);
  CName[I * 64] := Length(S);
  For K := 1 To Length(S) Do CName[I * 64 + K] := Ord(S[K]);
End;

{ Nom d'une classe (WC_* = FFFF00nnh -> #nn) }
Function ClsNameOf(P : LongInt) : String;
Begin
  If (P And $FFFF0000) = $FFFF0000 Then ClsNameOf := '#' + IntStr(P And $FFFF)
  Else ClsNameOf := GetZ(P);
End;

Function ClsFind(N : String) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := MaxCls - 1 DownTo 0 Do
    If (CUse[I] <> 0) And (CPid[I] = 0) And (ClsGet(I) = N) Then R := I;
  For I := MaxCls - 1 DownTo 0 Do
    If (CUse[I] <> 0) And (CPid[I] = MyPid) And (ClsGet(I) = N) Then R := I;
  ClsFind := R;
End;

Function ClsAdd(N : String; Proc, Style, Cb, Pid, Kind : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxCls - 1 DownTo 0 Do
    If (CUse[I] <> 0) And (CPid[I] = Pid) And (ClsGet(I) = N) Then F := I;
  If F < 0 Then
    For I := MaxCls - 1 DownTo 0 Do
      If (CUse[I] = 0) Or ((CPid[I] <> 0) And Not Alive(CPid[I])) Then F := I;
  If F >= 0 Then
  Begin
    CUse[F] := 1;
    ClsSet(F, N);
    CProc[F] := Proc; CStyle[F] := Style; CCb[F] := Cb; CPid[F] := Pid;
    CKind[F] := Kind; CThunk[F] := 0; CMsgMode[F] := 0; CInt0[F] := 0; CInt1[F] := 0;
  End;
  ClsAdd := F;
End;

{ WinRegisterClass(hab, pszClassName, pfnWndProc, flStyle, cbWindowData) : BOOL }
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt;
Var N : String; Pid : LongInt;
Begin
  WinRegisterClass := 0;
  N := ClsNameOf(PName);
  If (N = '') Or (Cb < 0) Or (Cb > 4096) Then
  Begin
    SetErr(PMERR_INVALID_PARAMETERS);
    Exit;
  End;
  If (N[1] = '#') And (ClsFind(N) >= 0) And (CPid[ClsFind(N)] = 0) And (Proc = 0) Then
  Begin
    SetErr(PMERR_INVALID_PARAMETERS);
    Exit;
  End;
  If (Style And $10) <> 0 Then Pid := 0 Else Pid := MyPid;     { CS_PUBLIC }
  If Proc = 0 Then Proc := DefProcAddr;
  If ClsAdd(N, Proc, Style, Cb, Pid, 0) >= 0 Then WinRegisterClass := 1
  Else SetErr(PMERR_NO_HANDLE_ALLOC);
End;

{ WinQueryClassInfo(hab, pszClassName, pClassInfo) : CLASSINFO
  (flClassStyle, pfnWindowProc, cbWindowData) ; BOOL }
Function WinQueryClassInfo(Hab, PName, PInfo : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ClsFind(ClsNameOf(PName));
  If (I < 0) Or (PInfo = 0) Then
  Begin
    SetErr(PMERR_INVALID_PARAMETERS);
    WinQueryClassInfo := 0;
    Exit;
  End;
  WrL(PInfo, CStyle[I]);
  WrL(PInfo + 4, CProc[I]);
  WrL(PInfo + 8, CCb[I]);
  WinQueryClassInfo := 1;
End;

{ WinQueryClassName(hwnd, cchMax, pch) : longueur }
Function WinQueryClassName(H, Cch, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 0 Then WinQueryClassName := 0
  Else WinQueryClassName := PutZN(P, Cch, ClsGet(WCls[I]));
End;

Function KindOf(I : LongInt) : LongInt;
Begin
  If (I < 0) Or (WCls[I] < 0) Then KindOf := 0 Else KindOf := CKind[WCls[I]];
End;

{ --- fenetres --- }
Function NewWin : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxWin - 1 DownTo 2 Do
    If WUse[I] = 0 Then F := I;
  NewWin := F;
End;

Procedure PPRemoveAll(I : LongInt); Forward;
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; Forward;

{ WinCreateWindow(hwndParent, pszClass, pszName, flStyle, x, y, cx, cy,
  hwndOwner, hwndInsertBehind, id, pCtlData, pPresParams) : HWND }
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt;
Var I, P, C, B, Cs, K, Off, Q, R : LongInt;
Begin
  WinCreateWindow := 0;
  P := WChk(HPar);
  If P < 0 Then Exit;
  C := ClsFind(ClsNameOf(PCls));
  If C < 0 Then
  Begin
    SetErr(PMERR_INVALID_PARAMETERS);
    Exit;
  End;
  I := NewWin;
  If I < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    Exit;
  End;
  Inc(WGen[I]);
  If WGen[I] > $7FFFFF Then WGen[I] := 1;
  WUse[I] := 1;
  WPid[I] := MyPid;
  WHmq[I] := CurQ;
  WCls[I] := C;
  WProc[I] := CProc[C];
  WThunk[I] := CThunk[C];
  WStyle[I] := Style;
  WId[I] := Id And $FFFF;
  WPar[I] := P;
  WOwner[I] := 0;
  If WIdx(HOwn) >= 0 Then WOwner[I] := HwOf(WIdx(HOwn));
  WX[I] := X; WY[I] := Y; WCX[I] := MaxI(Cx, 0); WCY[I] := MaxI(Cy, 0);
  WLock[I] := 0; WFlags[I] := 0; WUpd[I] := 0; WNoUpd[I] := 0; WDC[I] := 0; WDestroyReg[I] := 0;
  WS0[I] := 0; WS1[I] := 0; WS2[I] := 0; WS3[I] := 0; WS4[I] := 0; WS5[I] := 0;
  WInt0[I] := CInt0[C]; WInt1[I] := CInt1[C];
  WRX[I] := X; WRY[I] := Y; WRCX[I] := Cx; WRCY[I] := Cy;
  WTextSet(I, '');
  If PName <> 0 Then WTextSet(I, GetZ(PName));
  WCbData[I] := CCb[C];
  WData[I] := 0;
  If CCb[C] > 0 Then WData[I] := MemAlloc(CCb[C]);
  { ordre }
  B := WIdx(HBehind);
  If (HBehind = HWND_BOTTOM) Then ZBottom(I)
  Else If (B > 1) And (WPar[B] = P) Then ZBehind(I, B)
  Else ZTop(I);
  { parametres de presentation : PRESPARAMS (cb, {id, cb, ab}) }
  If PPres <> 0 Then
  Begin
    Off := 4;
    While Off < RdL(PPres) + 4 Do
    Begin
      Dummy := WinSetPresParam(HwOf(I), RdL(PPres + Off), RdL(PPres + Off + 4), PPres + Off + 8);
      Off := Off + 8 + RdL(PPres + Off + 4);
    End;
  End;
  { WM_CREATE (pCtlData, CREATESTRUCT) }
  Cs := MemAlloc(52);
  WrL(Cs, PPres); WrL(Cs + 4, PCtl); WrL(Cs + 8, Id); WrL(Cs + 12, HBehind); WrL(Cs + 16, HOwn);
  WrL(Cs + 20, Cy); WrL(Cs + 24, Cx); WrL(Cs + 28, Y); WrL(Cs + 32, X); WrL(Cs + 36, Style);
  WrL(Cs + 40, PName); WrL(Cs + 44, PCls); WrL(Cs + 48, HPar);
  R := SendM(HwOf(I), WM_CREATE, PCtl, Cs);
  MemFree(Cs);
  If (R <> 0) Or (WUse[I] = 0) Then
  Begin
    If WUse[I] <> 0 Then
    Begin
      If WData[I] <> 0 Then MemFree(WData[I]);
      WUse[I] := 0;
    End;
    Exit;
  End;
  If (Cx <> 0) Or (Cy <> 0) Then Dummy := SendM(HwOf(I), WM_SIZE, 0, Mk2(Cx, Cy));
  If (WStyle[I] And WS_VISIBLE) <> 0 Then InvalWin(I);
  WinCreateWindow := HwOf(I);
End;

Procedure StopTimersOf(I : LongInt); Forward;
Procedure ReleasePSOf(I : LongInt); Forward;

Procedure DestroyIdx(I : LongInt);
Var J, H, X1, Y1, X2, Y2 : LongInt; WasShown : Boolean;
Begin
  If (I < 2) Or (WUse[I] = 0) Then Exit;
  H := HwOf(I);
  WasShown := VisRect(I, X1, Y1, X2, Y2);
  CallHooks3(16, 0, H, 0);           { HK_DESTROYWINDOW }
  Dummy := SendM(H, WM_DESTROY, 0, 0);
  { enfants }
  For J := 2 To MaxWin - 1 Do
    If (WUse[J] <> 0) And (WPar[J] = I) Then DestroyIdx(J);
  If WUse[I] = 0 Then Exit;
  { fenetres possedees de premier niveau (dialogues, menus) }
  For J := 2 To MaxWin - 1 Do
    If (WUse[J] <> 0) And (WOwner[J] = H) And (WPar[J] <= 1) And ((KindOf(J) = CK_MENU) Or ((WFlags[J] And 4) <> 0)) Then
      DestroyIdx(J);
  If (FocusWin = I) Or ((FocusWin > 1) And IsChildOf(FocusWin, I)) Then
  Begin
    FocusWin := 0;
    If WPar[I] > 1 Then FocusWin := WPar[I];
  End;
  If ActiveWin = I Then ActiveWin := 0;
  If CaptureWin = I Then CaptureWin := 0;
  If SysModalWin = I Then SysModalWin := 0;
  If CursorWin = I Then CursorWin := 0;
  If ClOwner = H Then ClOwner := 0;
  If ClViewer = H Then ClViewer := 0;
  StopTimersOf(I);
  ReleasePSOf(I);
  FreeItemsOf(I);
  PPRemoveAll(I);
  If WData[I] <> 0 Then MemFree(WData[I]);
  WData[I] := 0;
  WUse[I] := 0;
  Inc(WGen[I]);
  If WasShown Then InvalScreen(X1, Y1, X2, Y2);
End;

{ WinDestroyWindow(hwnd) : BOOL }
Function WinDestroyWindow(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 2 Then
  Begin
    WinDestroyWindow := 0;
    Exit;
  End;
  If WLock[I] > 0 Then
  Begin
    SetErr(PMERR_INVALID_PARAMETERS);
    WinDestroyWindow := 0;
    Exit;
  End;
  DestroyIdx(I);
  If (ActiveWin = 0) Or (WUse[ActiveWin] = 0) Then
  Begin
    ActiveWin := 0;
    I := ChildTop(0);
    While (I > 1) And Not Shown(I) Do I := SibNext(I, True);
    If I > 1 Then ActiveWin := I;
  End;
  WinDestroyWindow := 1;
End;

{ --- position --- }
Procedure SwpGet(I, P : LongInt);
Var Fl, B : LongInt;
Begin
  Fl := 0;
  If (WStyle[I] And WS_VISIBLE) <> 0 Then Fl := SWP_SHOW Else Fl := SWP_HIDE;
  If (WStyle[I] And WS_MINIMIZED) <> 0 Then Fl := Fl Or SWP_MINIMIZE;
  If (WStyle[I] And WS_MAXIMIZED) <> 0 Then Fl := Fl Or SWP_MAXIMIZE;
  WrL(P, Fl);
  WrL(P + 4, WCY[I]); WrL(P + 8, WCX[I]); WrL(P + 12, WY[I]); WrL(P + 16, WX[I]);
  B := SibNext(I, False);
  If B > 1 Then WrL(P + 20, HwOf(B)) Else WrL(P + 20, HWND_TOP);
  WrL(P + 24, HwOf(I)); WrL(P + 28, 0); WrL(P + 32, 0);
End;

Function WinQueryWindowPos(H, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If (I < 0) Or (P = 0) Then WinQueryWindowPos := 0
  Else
  Begin
    SwpGet(I, P);
    WinQueryWindowPos := 1;
  End;
End;

Function WinGetMaxPosition(H, P : LongInt) : LongInt; Forward;
Function WinGetMinPosition(H, P, PPtl : LongInt) : LongInt; Forward;
Function WinSetActiveWindow(HDesk, H : LongInt) : LongInt; Forward;
Procedure VisNotify(I : LongInt); Forward;

{ WinSetWindowPos(hwnd, hwndInsertBehind, x, y, cx, cy, fl) : BOOL }
Function WinSetWindowPos(H, HBehind, X, Y, Cx, Cy, Fl : LongInt) : LongInt;
Var I, B, OX1, OY1, OX2, OY2, OCx, OCy, Swp, K : LongInt; Was, Changed : Boolean;
Begin
  WinSetWindowPos := 0;
  I := WChk(H);
  If I < 2 Then Exit;
  Was := VisRect(I, OX1, OY1, OX2, OY2);
  OCx := WCX[I]; OCy := WCY[I];
  Changed := False;
  { WM_ADJUSTWINDOWPOS : la fenetre peut corriger le SWP }
  If (Fl And SWP_NOADJUST) = 0 Then
  Begin
    Swp := MemAlloc(36);
    WrL(Swp, Fl); WrL(Swp + 4, Cy); WrL(Swp + 8, Cx); WrL(Swp + 12, Y); WrL(Swp + 16, X);
    WrL(Swp + 20, HBehind); WrL(Swp + 24, H);
    Dummy := SendM(H, WM_ADJUSTWINDOWPOS, Swp, 0);
    Fl := RdL(Swp); Cy := RdL(Swp + 4); Cx := RdL(Swp + 8); Y := RdL(Swp + 12); X := RdL(Swp + 16);
    MemFree(Swp);
  End;
  If (Fl And SWP_RESTORE) <> 0 Then
  Begin
    If (WStyle[I] And (WS_MINIMIZED Or WS_MAXIMIZED)) <> 0 Then
    Begin
      X := WRX[I]; Y := WRY[I]; Cx := WRCX[I]; Cy := WRCY[I];
      Fl := Fl Or SWP_MOVE Or SWP_SIZE Or SWP_SHOW;
    End;
    WStyle[I] := WStyle[I] And Not (WS_MINIMIZED Or WS_MAXIMIZED);
  End;
  If (Fl And (SWP_MAXIMIZE Or SWP_MINIMIZE)) <> 0 Then
  Begin
    If (WStyle[I] And (WS_MINIMIZED Or WS_MAXIMIZED)) = 0 Then
    Begin
      WRX[I] := WX[I]; WRY[I] := WY[I]; WRCX[I] := WCX[I]; WRCY[I] := WCY[I];
    End;
    Swp := MemAlloc(36);
    If (Fl And SWP_MAXIMIZE) <> 0 Then
    Begin
      Dummy := WinGetMaxPosition(H, Swp);
      WStyle[I] := (WStyle[I] Or WS_MAXIMIZED) And Not WS_MINIMIZED;
    End
    Else
    Begin
      Dummy := WinGetMinPosition(H, Swp, 0);
      WStyle[I] := (WStyle[I] Or WS_MINIMIZED) And Not WS_MAXIMIZED;
    End;
    X := RdL(Swp + 16); Y := RdL(Swp + 12); Cx := RdL(Swp + 8); Cy := RdL(Swp + 4);
    Fl := Fl Or SWP_MOVE Or SWP_SIZE;
    MemFree(Swp);
    Dummy := SendM(H, WM_MINMAXFRAME, H, Fl);
  End;
  If (Fl And SWP_MOVE) <> 0 Then
    If (X <> WX[I]) Or (Y <> WY[I]) Then
    Begin
      WX[I] := X; WY[I] := Y;
      Changed := True;
      Dummy := SendM(H, WM_MOVE, 0, 0);
    End;
  If (Fl And SWP_SIZE) <> 0 Then
    If (Cx <> WCX[I]) Or (Cy <> WCY[I]) Then
    Begin
      WCX[I] := MaxI(Cx, 0); WCY[I] := MaxI(Cy, 0);
      Changed := True;
      Dummy := SendM(H, WM_SIZE, Mk2(OCx, OCy), Mk2(WCX[I], WCY[I]));
    End;
  If (Fl And SWP_ZORDER) <> 0 Then
  Begin
    B := WIdx(HBehind);
    If HBehind = HWND_TOP Then ZTop(I)
    Else If HBehind = HWND_BOTTOM Then ZBottom(I)
    Else If (B > 1) And (WPar[B] = WPar[I]) And (B <> I) Then ZBehind(I, B);
    Changed := True;
  End;
  If ((Fl And SWP_SHOW) <> 0) And ((WStyle[I] And WS_VISIBLE) = 0) Then
  Begin
    WStyle[I] := WStyle[I] Or WS_VISIBLE;
    Changed := True;
    Dummy := SendM(H, WM_SHOW, 1, 0);
  End;
  If ((Fl And SWP_HIDE) <> 0) And ((WStyle[I] And WS_VISIBLE) <> 0) Then
  Begin
    WStyle[I] := WStyle[I] And Not WS_VISIBLE;
    Changed := True;
    Dummy := SendM(H, WM_SHOW, 0, 0);
    If (FocusWin = I) Or ((FocusWin > 1) And IsChildOf(FocusWin, I)) Then FocusTo(0);
  End;
  If Changed And ((Fl And SWP_NOREDRAW) = 0) Then
  Begin
    If Was Then InvalScreen(OX1, OY1, OX2, OY2);
    InvalWin(I);
  End;
  If Changed Then
  Begin
    Swp := MemAlloc(36);
    SwpGet(I, Swp);
    Dummy := SendM(H, WM_WINDOWPOSCHANGED, Swp, 0);
    MemFree(Swp);
    VisNotify(I);
  End;
  If (Fl And SWP_ACTIVATE) <> 0 Then Dummy := WinSetActiveWindow(HWND_DESKTOP, H);
  If ((Fl And SWP_DEACTIVATE) <> 0) And (ActiveWin = I) Then
  Begin
    K := SibNext(I, True);
    If K > 1 Then Dummy := WinSetActiveWindow(HWND_DESKTOP, HwOf(K));
  End;
  WinSetWindowPos := 1;
End;

{ WinSetMultWindowPos(hab, pswp, cswp) : BOOL }
Function WinSetMultWindowPos(Hab, P, N : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := 1;
  K := 0;
  While K < N Do
  Begin
    If WinSetWindowPos(RdL(P + K * 36 + 24), RdL(P + K * 36 + 20), RdL(P + K * 36 + 16), RdL(P + K * 36 + 12),
                       RdL(P + K * 36 + 8), RdL(P + K * 36 + 4), RdL(P + K * 36)) = 0 Then R := 0;
    Inc(K);
  End;
  WinSetMultWindowPos := R;
End;

{ WinSaveWindowPos(hsvwp, pswp, cswp) : copie la position des fenetres
  dans le tableau SWP ; BOOL }
Function WinSaveWindowPos(Hsv, P, N : LongInt) : LongInt;
Var K, I, R : LongInt;
Begin
  R := 1;
  For K := 0 To N - 1 Do
  Begin
    I := WIdx(RdL(P + K * 36 + 24));
    If I < 0 Then R := 0 Else SwpGet(I, P + K * 36);
  End;
  WinSaveWindowPos := R;
End;

Function WinShowWindow(H, Show : LongInt) : LongInt;
Begin
  If Show <> 0 Then WinShowWindow := WinSetWindowPos(H, 0, 0, 0, 0, 0, SWP_SHOW)
  Else WinShowWindow := WinSetWindowPos(H, 0, 0, 0, 0, 0, SWP_HIDE);
End;

Function WinIsWindowVisible(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If (I >= 0) And ((I = 0) Or Shown(I)) Then WinIsWindowVisible := 1 Else WinIsWindowVisible := 0;
End;

{ WinEnableWindowUpdate(hwnd, fEnable) : visibilite sans dessin }
Function WinEnableWindowUpdate(H, En : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  WinEnableWindowUpdate := 0;
  If I < 2 Then Exit;
  If En <> 0 Then
  Begin
    WStyle[I] := WStyle[I] Or WS_VISIBLE;
    WNoUpd[I] := 0;
    InvalWin(I);
  End
  Else
  Begin
    WStyle[I] := WStyle[I] And Not WS_VISIBLE;
    WNoUpd[I] := 1;
  End;
  WinEnableWindowUpdate := 1;
End;

Function WinEnableWindow(H, En : LongInt) : LongInt;
Var I, Old : LongInt;
Begin
  I := WChk(H);
  WinEnableWindow := 0;
  If I < 2 Then Exit;
  Old := WStyle[I];
  If En <> 0 Then WStyle[I] := WStyle[I] And Not WS_DISABLED Else WStyle[I] := WStyle[I] Or WS_DISABLED;
  If Old <> WStyle[I] Then
  Begin
    Dummy := SendM(H, WM_ENABLE, En, 0);
    InvalWin(I);
    If (En = 0) And (FocusWin = I) Then FocusTo(0);
  End;
  WinEnableWindow := 1;
End;

Function WinIsWindowEnabled(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If (I >= 0) And ((WStyle[I] And WS_DISABLED) = 0) Then WinIsWindowEnabled := 1 Else WinIsWindowEnabled := 0;
End;

Function WinIsWindow(Hab, H : LongInt) : LongInt;
Begin
  If WIdx(H) >= 0 Then WinIsWindow := 1 Else WinIsWindow := 0;
End;

Function WinIsChild(H, HPar : LongInt) : LongInt;
Var I, P : LongInt;
Begin
  I := WIdx(H); P := WIdx(HPar);
  If (I >= 0) And (P >= 0) And ((I = P) Or IsChildOf(I, P)) Then WinIsChild := 1 Else WinIsChild := 0;
End;

{ --- texte --- }
{ WinSetWindowText(hwnd, psz) : WM_SETWINDOWPARAMS (WPM_TEXT) ; BOOL }
Function WinSetWindowText(H, P : LongInt) : LongInt;
Var I, Wp : LongInt;
Begin
  I := WChk(H);
  WinSetWindowText := 0;
  If I < 0 Then Exit;
  Wp := MemAlloc(28);
  WrL(Wp, 1); WrL(Wp + 4, Length(GetZ(P))); WrL(Wp + 8, P);
  WinSetWindowText := SendM(H, WM_SETWINDOWPARAMS, Wp, 0);
  MemFree(Wp);
End;

{ WinQueryWindowText(hwnd, cchBufferMax, pchBuffer) : longueur }
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt;
Var I, Wp : LongInt;
Begin
  I := WChk(H);
  WinQueryWindowText := 0;
  If (I < 0) Or (P = 0) Or (Cch <= 0) Then Exit;
  WrB(P, 0);
  Wp := MemAlloc(28);
  WrL(Wp, 1 Or 8); WrL(Wp + 4, Cch); WrL(Wp + 8, P);
  Dummy := SendM(H, WM_QUERYWINDOWPARAMS, Wp, 0);
  MemFree(Wp);
  WinQueryWindowText := Length(GetZ(P));
End;

Function WinQueryWindowTextLength(H : LongInt) : LongInt;
Var I, Wp : LongInt;
Begin
  I := WChk(H);
  WinQueryWindowTextLength := 0;
  If I < 0 Then Exit;
  Wp := MemAlloc(28);
  WrL(Wp, 8);
  Dummy := SendM(H, WM_QUERYWINDOWPARAMS, Wp, 0);
  WinQueryWindowTextLength := RdL(Wp + 4);
  MemFree(Wp);
End;

{ --- identificateurs, liens --- }
Function WinWindowFromID(HPar, Id : LongInt) : LongInt;
Var P, I, R : LongInt;
Begin
  R := 0;
  P := WChk(HPar);
  If P >= 0 Then
    For I := MaxWin - 1 DownTo 2 Do
      If (WUse[I] <> 0) And (WPar[I] = P) And (WId[I] = (Id And $FFFF)) Then R := HwOf(I);
  WinWindowFromID := R;
End;

{ WinMultWindowFromIDs(hwndParent, prghwnd, idFirst, idLast) : nombre trouve }
Function WinMultWindowFromIDs(HPar, P, IdF, IdL : LongInt) : LongInt;
Var K, N, H : LongInt;
Begin
  N := 0;
  For K := IdF To IdL Do
  Begin
    H := WinWindowFromID(HPar, K);
    WrL(P + (K - IdF) * 4, H);
    If H <> 0 Then Inc(N);
  End;
  WinMultWindowFromIDs := N;
End;

{ WinSetParent(hwnd, hwndNewParent, fRedraw) : BOOL }
Function WinSetParent(H, HPar, Redraw : LongInt) : LongInt;
Var I, P, X1, Y1, X2, Y2 : LongInt; Was : Boolean;
Begin
  WinSetParent := 0;
  I := WChk(H); P := WChk(HPar);
  If (I < 2) Or (P < 0) Or (P = I) Or IsChildOf(P, I) Then Exit;
  Was := VisRect(I, X1, Y1, X2, Y2);
  WPar[I] := P;
  ZTop(I);
  If Redraw <> 0 Then
  Begin
    If Was Then InvalScreen(X1, Y1, X2, Y2);
    InvalWin(I);
  End;
  WinSetParent := 1;
End;

Function WinSetOwner(H, HOwn : LongInt) : LongInt;
Var I, O : LongInt;
Begin
  WinSetOwner := 0;
  I := WChk(H);
  If I < 2 Then Exit;
  O := WIdx(HOwn);
  If O >= 0 Then WOwner[I] := HwOf(O) Else WOwner[I] := 0;
  WinSetOwner := 1;
End;

{ WinQueryWindow(hwnd, cmd) : QW_* }
Function WinQueryWindow(H, Cmd : LongInt) : LongInt;
Var I, R, J : LongInt;
Begin
  R := 0;
  I := WChk(H);
  If I >= 0 Then
    Case Cmd Of
      QW_NEXT : If I > 1 Then R := HwOf(SibNext(I, True));
      QW_PREV : If I > 1 Then R := HwOf(SibNext(I, False));
      QW_TOP : R := HwOf(ChildTop(I));
      QW_BOTTOM : R := HwOf(ChildBottom(I));
      QW_OWNER : R := WOwner[I];
      QW_PARENT : If I > 1 Then R := HwOf(WPar[I]);
      QW_NEXTTOP, QW_PREVTOP :
        Begin
          J := TopFrame(I);
          If J > 1 Then
          Begin
            J := SibNext(J, Cmd = QW_NEXTTOP);
            If J < 2 Then
            Begin
              If Cmd = QW_NEXTTOP Then J := ChildTop(WPar[TopFrame(I)]) Else J := ChildBottom(WPar[TopFrame(I)]);
            End;
            R := HwOf(J);
          End;
        End;
      QW_FRAMEOWNER :
        Begin
          J := WIdx(WOwner[I]);
          While (J > 1) And (KindOf(J) <> CK_FRAME) Do J := WIdx(WOwner[J]);
          If J > 1 Then R := HwOf(J);
        End;
    Else
      SetErr(PMERR_PARAMETER_OUT_OF_RANGE);
    End;
  WinQueryWindow := R;
End;

Function WinQueryWindowRect(H, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If (I < 0) Or (P = 0) Then WinQueryWindowRect := 0
  Else
  Begin
    WrL(P, 0); WrL(P + 4, 0); WrL(P + 8, WCX[I]); WrL(P + 12, WCY[I]);
    WinQueryWindowRect := 1;
  End;
End;

Function WinQueryWindowProcess(H, PPid, PTid : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 0 Then WinQueryWindowProcess := 0
  Else
  Begin
    WrL(PPid, WPid[I]);
    WrL(PTid, 1);
    WinQueryWindowProcess := 1;
  End;
End;

{ --- mots reserves --- }
Function WordAddr(I, Index, Size : LongInt) : LongInt;
Begin
  If (Index < 0) Or (Index + Size > WCbData[I]) Or (WData[I] = 0) Then WordAddr := 0
  Else WordAddr := WData[I] + Index;
End;

Function WinQueryWindowULong(H, Index : LongInt) : LongInt;
Var I, A : LongInt;
Begin
  WinQueryWindowULong := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  If Index = QWL_STYLE Then WinQueryWindowULong := WStyle[I]
  Else If Index = QWP_PFNWP Then WinQueryWindowULong := WProc[I]
  Else If Index = QWL_HMQ Then WinQueryWindowULong := $00510001 + WHmq[I]
  Else If Index = QWL_RESERVED Then WinQueryWindowULong := 0
  Else
  Begin
    A := WordAddr(I, Index, 4);
    If A = 0 Then SetErr(PMERR_PARAMETER_OUT_OF_RANGE) Else WinQueryWindowULong := RdL(A);
  End;
End;

Function WinSetWindowULong(H, Index, V : LongInt) : LongInt;
Var I, A : LongInt;
Begin
  WinSetWindowULong := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  If Index = QWL_STYLE Then
  Begin
    WStyle[I] := V;
    InvalWin(I);
  End
  Else If Index = QWP_PFNWP Then WProc[I] := V
  Else
  Begin
    A := WordAddr(I, Index, 4);
    If A = 0 Then
    Begin
      SetErr(PMERR_PARAMETER_OUT_OF_RANGE);
      Exit;
    End;
    WrL(A, V);
  End;
  WinSetWindowULong := 1;
End;

Function WinQueryWindowUShort(H, Index : LongInt) : LongInt;
Var I, A : LongInt;
Begin
  WinQueryWindowUShort := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  If Index = QWS_ID Then WinQueryWindowUShort := WId[I]
  Else
  Begin
    A := WordAddr(I, Index, 2);
    If A = 0 Then SetErr(PMERR_PARAMETER_OUT_OF_RANGE) Else WinQueryWindowUShort := RdW(A);
  End;
End;

Function WinSetWindowUShort(H, Index, V : LongInt) : LongInt;
Var I, A : LongInt;
Begin
  WinSetWindowUShort := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  If Index = QWS_ID Then WId[I] := V And $FFFF
  Else
  Begin
    A := WordAddr(I, Index, 2);
    If A = 0 Then
    Begin
      SetErr(PMERR_PARAMETER_OUT_OF_RANGE);
      Exit;
    End;
    WrW(A, V);
  End;
  WinSetWindowUShort := 1;
End;

Function WinQueryWindowPtr(H, Index : LongInt) : LongInt;
Begin
  WinQueryWindowPtr := WinQueryWindowULong(H, Index);
End;

Function WinSetWindowPtr(H, Index, V : LongInt) : LongInt;
Begin
  WinSetWindowPtr := WinSetWindowULong(H, Index, V);
End;

{ WinSetWindowBits(hwnd, index, flData, flMask) : BOOL }
Function WinSetWindowBits(H, Index, Data, Mask : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := WinQueryWindowULong(H, Index);
  WinSetWindowBits := WinSetWindowULong(H, Index, (V And Not Mask) Or (Data And Mask));
End;

{ --- enumeration --- }
Function WinBeginEnumWindows(H : LongInt) : LongInt;
Var P, I, F, L, N, J : LongInt;
Begin
  WinBeginEnumWindows := 0;
  P := WChk(H);
  If P < 0 Then Exit;
  F := -1;
  For I := MaxEnum - 1 DownTo 0 Do
    If EnUse[I] = 0 Then F := I;
  If F < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    Exit;
  End;
  L := MemAlloc(MaxWin * 4);
  N := 0;
  J := ChildTop(P);
  While J > 1 Do
  Begin
    WrL(L + N * 4, HwOf(J));
    Inc(N);
    J := SibNext(J, True);
  End;
  EnUse[F] := MyPid; EnList[F] := L; EnCount[F] := N; EnPos[F] := 0;
  WinBeginEnumWindows := $454E0001 + F;
End;

Function WinGetNextWindow(He : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  I := He - $454E0001;
  If (I >= 0) And (I < MaxEnum) And (EnUse[I] <> 0) Then
  Begin
    While (R = 0) And (EnPos[I] < EnCount[I]) Do
    Begin
      If WIdx(RdL(EnList[I] + EnPos[I] * 4)) >= 0 Then R := RdL(EnList[I] + EnPos[I] * 4);
      Inc(EnPos[I]);
    End;
  End
  Else SetErr(PMERR_INVALID_HENUM);
  WinGetNextWindow := R;
End;

Function WinEndEnumWindows(He : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := He - $454E0001;
  If (I >= 0) And (I < MaxEnum) And (EnUse[I] <> 0) Then
  Begin
    MemFree(EnList[I]);
    EnUse[I] := 0;
    WinEndEnumWindows := 1;
  End
  Else
  Begin
    SetErr(PMERR_INVALID_HENUM);
    WinEndEnumWindows := 0;
  End;
End;

{ --- points --- }
{ Fenetre visible la plus profonde sous un point ecran, descendante de P }
Function WinAtAbs(P, X, Y : LongInt; Children : Boolean) : LongInt;
Var J, R, AX, AY : LongInt;
Begin
  R := -1;
  J := ChildTop(P);
  While (R < 0) And (J > 1) Do
  Begin
    If (WStyle[J] And WS_VISIBLE) <> 0 Then
    Begin
      AX := AbsX(J); AY := AbsY(J);
      If (X >= AX) And (X < AX + WCX[J]) And (Y >= AY) And (Y < AY + WCY[J]) Then
      Begin
        R := J;
        If Children Then
        Begin
          J := WinAtAbs(R, X, Y, True);
          If J >= 0 Then R := J;
        End;
      End;
    End;
    If R < 0 Then J := SibNext(J, True);
  End;
  WinAtAbs := R;
End;

{ WinWindowFromPoint(hwndParent, pptl, fChildren) }
Function WinWindowFromPoint(HPar, PPtl, Children : LongInt) : LongInt;
Var P, X, Y, R : LongInt;
Begin
  WinWindowFromPoint := 0;
  P := WChk(HPar);
  If (P < 0) Or (PPtl = 0) Then Exit;
  X := RdL(PPtl) + AbsX(P); Y := RdL(PPtl + 4) + AbsY(P);
  If (X < AbsX(P)) Or (Y < AbsY(P)) Or (X >= AbsX(P) + WCX[P]) Or (Y >= AbsY(P) + WCY[P]) Then Exit;
  R := WinAtAbs(P, X, Y, Children <> 0);
  If R < 0 Then R := P;
  WinWindowFromPoint := HwOf(R);
End;

{ WinMapWindowPoints(hwndFrom, hwndTo, prgptl, cwpt) : BOOL }
Function WinMapWindowPoints(HFrom, HTo, P, N : LongInt) : LongInt;
Var A, B, K, Dx, Dy : LongInt;
Begin
  WinMapWindowPoints := 0;
  A := WChk(HFrom); B := WChk(HTo);
  If (A < 0) Or (B < 0) Then Exit;
  Dx := AbsX(A) - AbsX(B); Dy := AbsY(A) - AbsY(B);
  For K := 0 To N - 1 Do
  Begin
    WrL(P + K * 8, RdL(P + K * 8) + Dx);
    WrL(P + K * 8 + 4, RdL(P + K * 8 + 4) + Dy);
  End;
  WinMapWindowPoints := 1;
End;

{ WinSubclassWindow(hwnd, pfnwp) : ancienne procedure }
Function WinSubclassWindow(H, Proc : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If (I < 2) Or (Proc = 0) Then WinSubclassWindow := 0
  Else
  Begin
    WinSubclassWindow := WProc[I];
    WProc[I] := Proc;
  End;
End;

{ WinLockWindow(hwnd, fLock) : BOOL ; WinQueryWindowLockCount }
Function WinLockWindow(H, Lock : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinLockWindow := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  If Lock <> 0 Then
  Begin
    If WLock[I] >= 255 Then
    Begin
      SetErr(PMERR_WINDOW_LOCK_OVERFLOW);
      Exit;
    End;
    Inc(WLock[I]);
  End
  Else
  Begin
    If WLock[I] <= 0 Then
    Begin
      SetErr(PMERR_WINDOW_LOCK_UNDERFLOW);
      Exit;
    End;
    Dec(WLock[I]);
  End;
  WinLockWindow := 1;
End;

Function WinQueryWindowLockCount(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 0 Then WinQueryWindowLockCount := 0 Else WinQueryWindowLockCount := WLock[I];
End;

{ WinRegisterWindowDestroy(hwnd, fRegister) : la fenetre recoit
  WM_DESTROY avant la destruction de ses proprietaires ; BOOL }
Function WinRegisterWindowDestroy(H, Reg : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 0 Then WinRegisterWindowDestroy := 0
  Else
  Begin
    WDestroyReg[I] := Reg;
    WinRegisterWindowDestroy := 1;
  End;
End;

Function WinQueryDesktopWindow(Hab, Hdc : LongInt) : LongInt;
Begin
  WinQueryDesktopWindow := HwOf(0);
End;

Function WinQueryObjectWindow(HDesk : LongInt) : LongInt;
Begin
  WinQueryObjectWindow := HwOf(1);
End;

{ WinQueryWindowModel(hwnd) : PM_MODEL_2X (1) }
Function WinQueryWindowModel(H : LongInt) : LongInt;
Begin
  If WIdx(H) < 0 Then WinQueryWindowModel := 0 Else WinQueryWindowModel := 1;
End;

{ WinQueryWindowSGId(hwnd) : groupe d'ecran (session) }
Function WinQueryWindowSGId(H : LongInt) : LongInt;
Begin
  If WIdx(H) < 0 Then WinQueryWindowSGId := 0 Else WinQueryWindowSGId := 1;
End;

{ WinQueryPwnd(hwnd) : structure interne (mots reserves) }
Function WinQueryPwnd(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WIdx(H);
  If I < 0 Then WinQueryPwnd := 0 Else WinQueryPwnd := WData[I];
End;

{ WinIsWindowOverlapped(hwnd) : un frere au-dessus le recouvre-t-il ? }
Function WinIsWindowOverlapped(H : LongInt) : LongInt;
Var I, J, R, X1, Y1, X2, Y2, A1, B1 : LongInt;
Begin
  R := 0;
  I := WIdx(H);
  If I > 1 Then
  Begin
    X1 := AbsX(I); Y1 := AbsY(I); X2 := X1 + WCX[I]; Y2 := Y1 + WCY[I];
    J := SibNext(I, False);
    While J > 1 Do
    Begin
      A1 := AbsX(J); B1 := AbsY(J);
      If ((WStyle[J] And WS_VISIBLE) <> 0) And (A1 < X2) And (A1 + WCX[J] > X1) And (B1 < Y2) And (B1 + WCY[J] > Y1) Then R := 1;
      J := SibNext(J, False);
    End;
  End;
  WinIsWindowOverlapped := R;
End;

{ WinIsWindowShowing(hwnd) : une partie est-elle visible ? }
Function WinIsWindowShowing(H : LongInt) : LongInt;
Var I, X1, Y1, X2, Y2 : LongInt;
Begin
  I := WIdx(H);
  If (I >= 0) And ((I = 0) Or VisRect(I, X1, Y1, X2, Y2)) And (LockUpdWin <> I) Then WinIsWindowShowing := 1
  Else WinIsWindowShowing := 0;
End;

{ WinQueryAnchorBlock(hwnd) : ancre du processus de la fenetre }
Function WinQueryAnchorBlock(H : LongInt) : LongInt;
Var I, K, R : LongInt;
Begin
  R := 0;
  I := WIdx(H);
  If I >= 0 Then
    For K := MaxHab - 1 DownTo 0 Do
      If (HabPid[K] <> 0) And ((HabPid[K] = WPid[I]) Or (WPid[I] = 0)) Then R := $00010001 + K;
  WinQueryAnchorBlock := R;
End;


{ ==================================================================== }
{ Partie 3 - Ecran, espaces de presentation, mise a jour, dessin       }
{ ==================================================================== }

{ --- cellules de l'ecran texte --- }
Procedure PutCell(C, R, Ch, A : LongInt);
Begin
  If GMode <> 0 Then
  Begin
    If (C >= 0) And (C < ScrCols) And (R >= 0) And (R < ScrRows) Then
    Begin
      GClipAll;
      GGlyph(C * 8, ScrCY - 16 - R * 16, Ch, A And 15, (A Shr 4) And 15, True);
    End;
    Exit;
  End;
  If (C >= 0) And (C < ScrCols) And (R >= 0) And (R < ScrRows) Then
  Begin
    WrB($B8000 + (R * ScrCols + C) * 2, Ch);
    WrB($B8000 + (R * ScrCols + C) * 2 + 1, A);
  End;
End;

Function GetAttr(C, R : LongInt) : LongInt;
Begin
  If GMode <> 0 Then GetAttr := (GGetRaw(C * 8 + 4, R * 16 + 8) Shl 4) Or 15
  Else GetAttr := RdB($B8000 + (R * ScrCols + C) * 2 + 1);
End;

Procedure SetAttr(C, R, A : LongInt);
Begin
  If GMode <> 0 Then
  Begin
    GClipAll;
    GFill(C * 8, ScrCY - 16 - R * 16, C * 8 + 8, ScrCY - R * 16, (A Shr 4) And 15);
  End
  Else WrB($B8000 + (R * ScrCols + C) * 2 + 1, A);
End;

{ cellule d'un point ecran : colonne, ligne }
Function ColOf(X : LongInt) : LongInt;
Begin
  If X < 0 Then ColOf := -1 Else ColOf := X Div 8;
End;

Function RowOf(Y : LongInt) : LongInt;
Begin
  If Y < 0 Then RowOf := ScrRows Else RowOf := ScrRows - 1 - (Y Div 16);
End;

{ --- ordre de dessin : bureau, puis fenetres de bas en haut et en
  profondeur --- }

Procedure POrdAdd(P : LongInt);
Var J, N : LongInt;
Begin
  If PCnt >= MaxWin Then Exit;
  POrd[PCnt] := P;
  Inc(PCnt);
  J := ChildBottom(P);
  N := 0;
  While (J > 1) And (N < MaxWin) Do
  Begin
    If (WStyle[J] And WS_VISIBLE) <> 0 Then POrdAdd(J);
    J := SibNext(J, False);
    Inc(N);
  End;
End;

Procedure BuildPOrd;
Begin
  PCnt := 0;
  POrdAdd(0);
End;

{ Ajouter un rectangle ecran a la zone a mettre a jour de I }
Procedure AddUpd(I, X1, Y1, X2, Y2 : LongInt);
Var A1, B1, A2, B2 : LongInt;
Begin
  If I = 0 Then
  Begin
    A1 := 0; B1 := 0; A2 := ScrCX; B2 := ScrCY;
  End
  Else If Not VisRect(I, A1, B1, A2, B2) Then Exit;
  A1 := MaxI(A1, X1); B1 := MaxI(B1, Y1); A2 := MinI(A2, X2); B2 := MinI(B2, Y2);
  If (A1 >= A2) Or (B1 >= B2) Then Exit;
  If WUpd[I] = 0 Then
  Begin
    WUx1[I] := A1; WUy1[I] := B1; WUx2[I] := A2; WUy2[I] := B2;
    WUpd[I] := 1;
  End
  Else
  Begin
    WUx1[I] := MinI(WUx1[I], A1); WUy1[I] := MinI(WUy1[I], B1);
    WUx2[I] := MaxI(WUx2[I], A2); WUy2[I] := MaxI(WUy2[I], B2);
  End;
End;

Procedure InvalScreen(X1, Y1, X2, Y2 : LongInt);
Var K : LongInt;
Begin
  If VisLock > 0 Then Exit;
  BuildPOrd;
  For K := 0 To PCnt - 1 Do AddUpd(POrd[K], X1, Y1, X2, Y2);
End;

{ Invalider la fenetre I (rectangle ecran) et ce qui est dessine apres }
Procedure InvalFrom(I, X1, Y1, X2, Y2 : LongInt);
Var K : LongInt; Found : Boolean;
Begin
  BuildPOrd;
  Found := False;
  For K := 0 To PCnt - 1 Do
  Begin
    If POrd[K] = I Then Found := True;
    If Found Then AddUpd(POrd[K], X1, Y1, X2, Y2);
  End;
End;

{ La fenetre I va etre dessinee dans le rectangle ecran donne : le
  dessin n'est pas decoupe par les fenetres placees au-dessus ; celles
  des autres processus (qui ne sont pas redessinees dans l'ordre de ce
  processus) sont donc a redessiner apres elle }
Procedure InvalAboveOthers(I, X1, Y1, X2, Y2 : LongInt);
Var K, J : LongInt; Found : Boolean;
Begin
  If (X1 >= X2) Or (Y1 >= Y2) Then Exit;
  BuildPOrd;
  Found := False;
  For K := 0 To PCnt - 1 Do
  Begin
    J := POrd[K];
    If Found And (J > 1) And (WPid[J] <> MyPid) Then AddUpd(J, X1, Y1, X2, Y2);
    If J = I Then Found := True;
  End;
End;

Procedure InvalWin(I : LongInt);
Var X1, Y1, X2, Y2 : LongInt;
Begin
  If I = 0 Then InvalScreen(0, 0, ScrCX, ScrCY)
  Else If VisRect(I, X1, Y1, X2, Y2) Then InvalFrom(I, X1, Y1, X2, Y2);
End;

{ --- espaces de presentation --- }
Function PsIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $50530001;
  If (I >= 0) And (I < MaxPS) Then
  Begin
    If PsUse[I] = 0 Then I := -1;
  End
  Else I := -1;
  If I < 0 Then SetErr(PMERR_INVALID_HPS);
  PsIdx := I;
End;

{ Nouvel espace de presentation de la fenetre I (Kind : 1 cache, 2 ecran,
  3 dessin, 4 effacement) }
Function NewPS(I, Kind : LongInt) : LongInt;
Var K, F, X1, Y1, X2, Y2 : LongInt;
Begin
  F := -1;
  For K := MaxPS - 1 DownTo 0 Do
    If (PsUse[K] = 0) Or Not Alive(PsUse[K]) Then F := K;
  If F < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    NewPS := -1;
    Exit;
  End;
  PsUse[F] := MyPid;
  PsWin[F] := I;
  PsKind[F] := Kind;
  If (I = 0) Or (Kind = 2) Then
  Begin
    X1 := 0; Y1 := 0; X2 := ScrCX; Y2 := ScrCY;
    PsOrgX[F] := 0; PsOrgY[F] := 0;
  End
  Else
  Begin
    If Not VisRect(I, X1, Y1, X2, Y2) Then
    Begin
      X2 := X1; Y2 := Y1;
    End;
    PsOrgX[F] := AbsX(I); PsOrgY[F] := AbsY(I);
  End;
  PsX1[F] := X1; PsY1[F] := Y1; PsX2[F] := X2; PsY2[F] := Y2;
  NewPS := F;
End;

Procedure ReleasePSOf(I : LongInt);
Var K : LongInt;
Begin
  For K := 0 To MaxPS - 1 Do
    If (PsUse[K] <> 0) And (PsWin[K] = I) Then PsUse[K] := 0;
End;

{ La cellule peut-elle etre dessinee par l'espace K ? }
Function CanDraw(K, C, R : LongInt) : Boolean;
Var X, Y : LongInt;
Begin
  X := C * 8 + 4;
  Y := (ScrRows - 1 - R) * 16 + 8;
  CanDraw := (C >= 0) And (C < ScrCols) And (R >= 0) And (R < ScrRows) And
             (X >= PsX1[K]) And (X < PsX2[K]) And (Y >= PsY1[K]) And (Y < PsY2[K]) And
             Not ((LockUpdWin > 1) And ((PsWin[K] = LockUpdWin) Or IsChildOf(PsWin[K], LockUpdWin))) And
             Not ((PsWin[K] > 1) And (WNoUpd[PsWin[K]] <> 0));
End;

{ ecran graphique : decoupage du dessin de l'espace K ; faux si rien ne
  peut etre dessine }
Function GPsClip(K : LongInt) : Boolean;
Begin
  GClip(PsX1[K], PsY1[K], PsX2[K], PsY2[K]);
  GPsClip := (GCx1 < GCx2) And (GCy1 < GCy2) And
             Not ((LockUpdWin > 1) And ((PsWin[K] = LockUpdWin) Or IsChildOf(PsWin[K], LockUpdWin))) And
             Not ((PsWin[K] > 1) And (WNoUpd[PsWin[K]] <> 0));
End;

{ Remplir un rectangle (coordonnees de l'espace) }
Procedure FillPS(K, X1, Y1, X2, Y2, Ch, A : LongInt);
Var C, R, C1, C2, R1, R2, Fg, Bg, Xx, Yy : LongInt;
Begin
  X1 := X1 + PsOrgX[K]; X2 := X2 + PsOrgX[K]; Y1 := Y1 + PsOrgY[K]; Y2 := Y2 + PsOrgY[K];
  If (X1 >= X2) Or (Y1 >= Y2) Then Exit;
  If GMode <> 0 Then
  Begin
    If Not GPsClip(K) Then Exit;
    Fg := A And 15; Bg := (A Shr 4) And 15;
    If Ch = $DB Then GFill(X1, Y1, X2, Y2, Fg)
    Else
    Begin
      GFill(X1, Y1, X2, Y2, Bg);
      If (Ch = $B0) Or (Ch = $B1) Or (Ch = $B2) Then GFillPat(X1, Y1, X2, Y2, Fg, $AA, 0)
      Else If (Ch = $C4) Or (Ch = $CD) Then GHLine(X1, X2, (Y1 + Y2) Div 2, Fg)
      Else If (Ch = $B3) Or (Ch = $BA) Then GVLine((X1 + X2) Div 2, Y1, Y2, Fg)
      Else If (Ch > 32) And (Ch < 255) Then
      Begin
        Yy := Y2 - 16;
        While Yy >= Y1 Do
        Begin
          Xx := X1;
          While Xx + 8 <= X2 Do
          Begin
            GGlyph(Xx, Yy, Ch, Fg, Bg, True);
            Xx := Xx + 8;
          End;
          Yy := Yy - 16;
        End;
      End;
    End;
    Exit;
  End;
  C1 := ColOf(X1); C2 := ColOf(X2 - 1);
  R1 := RowOf(Y2 - 1); R2 := RowOf(Y1);
  For R := R1 To R2 Do
    For C := C1 To C2 Do
      If CanDraw(K, C, R) Then
      Begin
        If Ch >= 0 Then PutCell(C, R, Ch, A) Else SetAttr(C, R, A);
      End;
End;

{ Ecrire un caractere au point (x, y) de l'espace }
Procedure CharPS(K, X, Y, Ch, A : LongInt);
Var C, R : LongInt;
Begin
  If GMode <> 0 Then
  Begin
    If GPsClip(K) Then GGlyph(X + PsOrgX[K], Y + PsOrgY[K], Ch, A And 15, (A Shr 4) And 15, True);
    Exit;
  End;
  C := ColOf(X + PsOrgX[K]);
  R := RowOf(Y + PsOrgY[K]);
  If CanDraw(K, C, R) Then PutCell(C, R, Ch, A);
End;

{ ecran graphique : soulignement du caractere mnemonique en (x, y) }
Procedure UnderPS(K, X, Y, A : LongInt);
Begin
  If GMode <> 0 Then
    If GPsClip(K) Then GHLine(X + PsOrgX[K], X + PsOrgX[K] + 7, Y + PsOrgY[K] + 1, A And 15);
End;

Function WinGetPS(H : LongInt) : LongInt;
Var I, K : LongInt;
Begin
  WinGetPS := 0;
  If H = 0 Then I := 0 Else I := WChk(H);
  If I < 0 Then Exit;
  K := NewPS(I, 1);
  If K >= 0 Then WinGetPS := $50530001 + K;
End;

Function WinGetScreenPS(HDesk : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := NewPS(0, 2);
  If K < 0 Then WinGetScreenPS := 0 Else WinGetScreenPS := $50530001 + K;
End;

{ WinGetClipPS(hwnd, hwndClip, fl) }
Function WinGetClipPS(H, HClip, Fl : LongInt) : LongInt;
Begin
  WinGetClipPS := WinGetPS(H);
End;

Function WinReleasePS(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsIdx(Hps);
  If K < 0 Then WinReleasePS := 0
  Else
  Begin
    PsUse[K] := 0;
    WinReleasePS := 1;
  End;
End;

Function WinGetErasePS(H : LongInt) : LongInt;
Begin
  WinGetErasePS := WinGetPS(H);
End;

Function WinReleaseErasePS(Hps : LongInt) : LongInt;
Begin
  WinReleaseErasePS := WinReleasePS(Hps);
End;

{ WinBeginPaint(hwnd, hps, prclPaint) : espace limite a la zone a mettre
  a jour (validee) }
Function WinBeginPaint(H, Hps, PRcl : LongInt) : LongInt;
Var I, K, X1, Y1, X2, Y2 : LongInt;
Begin
  WinBeginPaint := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  If Hps <> 0 Then
  Begin
    K := PsIdx(Hps);
    If K < 0 Then Exit;
  End
  Else
  Begin
    K := NewPS(I, 3);
    If K < 0 Then Exit;
  End;
  If WUpd[I] <> 0 Then
  Begin
    X1 := WUx1[I]; Y1 := WUy1[I]; X2 := WUx2[I]; Y2 := WUy2[I];
  End
  Else If Not VisRect(I, X1, Y1, X2, Y2) Then
  Begin
    X2 := X1; Y2 := Y1;
  End;
  WUpd[I] := 0;
  InvalAboveOthers(I, X1, Y1, X2, Y2);
  PsX1[K] := X1; PsY1[K] := Y1; PsX2[K] := X2; PsY2[K] := Y2;
  If PRcl <> 0 Then
  Begin
    WrL(PRcl, X1 - PsOrgX[K]); WrL(PRcl + 4, Y1 - PsOrgY[K]);
    WrL(PRcl + 8, X2 - PsOrgX[K]); WrL(PRcl + 12, Y2 - PsOrgY[K]);
  End;
  WinBeginPaint := $50530001 + K;
End;

Function WinEndPaint(Hps : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsIdx(Hps);
  If K < 0 Then WinEndPaint := 0
  Else
  Begin
    If PsKind[K] = 3 Then PsUse[K] := 0;
    WinEndPaint := 1;
  End;
End;

{ --- zones a mettre a jour --- }
Function WinInvalidateRect(H, PRcl, Incl : LongInt) : LongInt;
Var I, X1, Y1, X2, Y2, A, B : LongInt;
Begin
  WinInvalidateRect := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  If (I = 0) And (PRcl = 0) Then
  Begin
    InvalScreen(0, 0, ScrCX, ScrCY);
    WinInvalidateRect := 1;
    Exit;
  End;
  If Not VisRect(I, X1, Y1, X2, Y2) And (I <> 0) Then
  Begin
    WinInvalidateRect := 1;
    Exit;
  End;
  If PRcl <> 0 Then
  Begin
    A := AbsX(I); B := AbsY(I);
    X1 := MaxI(X1, RdL(PRcl) + A); Y1 := MaxI(Y1, RdL(PRcl + 4) + B);
    X2 := MinI(X2, RdL(PRcl + 8) + A); Y2 := MinI(Y2, RdL(PRcl + 12) + B);
  End;
  If (X1 < X2) And (Y1 < Y2) Then InvalFrom(I, X1, Y1, X2, Y2);
  WinInvalidateRect := 1;
End;

Function WinInvalidateRegion(H, Hrgn, Incl : LongInt) : LongInt;
Begin
  WinInvalidateRegion := WinInvalidateRect(H, 0, Incl);
End;

Procedure ValidateIdx(I, X1, Y1, X2, Y2 : LongInt; Whole : Boolean);
Begin
  If WUpd[I] = 0 Then Exit;
  If Whole Or ((X1 <= WUx1[I]) And (Y1 <= WUy1[I]) And (X2 >= WUx2[I]) And (Y2 >= WUy2[I])) Then
  Begin
    WUpd[I] := 0;
    Exit;
  End;
  { retrait d'une bande entiere }
  If (X1 <= WUx1[I]) And (X2 >= WUx2[I]) Then
  Begin
    If (Y1 <= WUy1[I]) And (Y2 > WUy1[I]) Then WUy1[I] := Y2
    Else If (Y2 >= WUy2[I]) And (Y1 < WUy2[I]) Then WUy2[I] := Y1;
  End
  Else If (Y1 <= WUy1[I]) And (Y2 >= WUy2[I]) Then
  Begin
    If (X1 <= WUx1[I]) And (X2 > WUx1[I]) Then WUx1[I] := X2
    Else If (X2 >= WUx2[I]) And (X1 < WUx2[I]) Then WUx2[I] := X1;
  End;
  If (WUx1[I] >= WUx2[I]) Or (WUy1[I] >= WUy2[I]) Then WUpd[I] := 0;
End;

{ WinValidateRect(hwnd, prcl, fIncludeChildren) : BOOL }
Function WinValidateRect(H, PRcl, Incl : LongInt) : LongInt;
Var I, J, X1, Y1, X2, Y2, A, B : LongInt;
Begin
  WinValidateRect := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  A := AbsX(I); B := AbsY(I);
  If PRcl <> 0 Then
  Begin
    X1 := RdL(PRcl) + A; Y1 := RdL(PRcl + 4) + B; X2 := RdL(PRcl + 8) + A; Y2 := RdL(PRcl + 12) + B;
  End
  Else
  Begin
    X1 := -32768; Y1 := -32768; X2 := 32767; Y2 := 32767;
  End;
  ValidateIdx(I, X1, Y1, X2, Y2, PRcl = 0);
  If Incl <> 0 Then
    For J := 2 To MaxWin - 1 Do
      If (WUse[J] <> 0) And IsChildOf(J, I) Then ValidateIdx(J, X1, Y1, X2, Y2, PRcl = 0);
  WinValidateRect := 1;
End;

Function WinValidateRegion(H, Hrgn, Incl : LongInt) : LongInt;
Begin
  WinValidateRegion := WinValidateRect(H, 0, Incl);
End;

{ WinQueryUpdateRect(hwnd, prcl) : BOOL (zone non vide) }
Function WinQueryUpdateRect(H, PRcl : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinQueryUpdateRect := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  If WUpd[I] = 0 Then
  Begin
    If PRcl <> 0 Then
    Begin
      WrL(PRcl, 0); WrL(PRcl + 4, 0); WrL(PRcl + 8, 0); WrL(PRcl + 12, 0);
    End;
    Exit;
  End;
  If PRcl <> 0 Then
  Begin
    WrL(PRcl, WUx1[I] - AbsX(I)); WrL(PRcl + 4, WUy1[I] - AbsY(I));
    WrL(PRcl + 8, WUx2[I] - AbsX(I)); WrL(PRcl + 12, WUy2[I] - AbsY(I));
  End;
  WinQueryUpdateRect := 1;
End;

{ WinQueryUpdateRegion(hwnd, hrgn) : RGN_NULL 1, RGN_RECT 2, RGN_ERROR 0 }
Function WinQueryUpdateRegion(H, Hrgn : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 0 Then WinQueryUpdateRegion := 0
  Else If WUpd[I] <> 0 Then WinQueryUpdateRegion := 2
  Else WinQueryUpdateRegion := 1;
End;

{ WinExcludeUpdateRegion(hps, hwnd) : complexite de la zone d'ecretage }
Function WinExcludeUpdateRegion(Hps, H : LongInt) : LongInt;
Var K, I : LongInt;
Begin
  WinExcludeUpdateRegion := 0;
  K := PsIdx(Hps); I := WChk(H);
  If (K < 0) Or (I < 0) Then Exit;
  If (WUpd[I] <> 0) And (WUx1[I] <= PsX1[K]) And (WUy1[I] <= PsY1[K]) And (WUx2[I] >= PsX2[K]) And (WUy2[I] >= PsY2[K]) Then
  Begin
    PsX2[K] := PsX1[K];
    WinExcludeUpdateRegion := 1;
  End
  Else WinExcludeUpdateRegion := 2;
End;

Function WinLockWindowUpdate(HDesk, HLock : LongInt) : LongInt;
Var I, Old : LongInt;
Begin
  Old := LockUpdWin;
  If HLock = 0 Then LockUpdWin := 0
  Else
  Begin
    I := WChk(HLock);
    If I < 0 Then
    Begin
      WinLockWindowUpdate := 0;
      Exit;
    End;
    LockUpdWin := I;
  End;
  If (Old > 1) And (Old <> LockUpdWin) And (WUse[Old] <> 0) Then InvalWin(Old);
  WinLockWindowUpdate := 1;
End;

Function WinLockVisRegions(HDesk, Lock : LongInt) : LongInt;
Begin
  If Lock <> 0 Then Inc(VisLock)
  Else If VisLock > 0 Then Dec(VisLock);
  If VisLock = 0 Then InvalScreen(0, 0, ScrCX, ScrCY);
  WinLockVisRegions := 1;
End;

{ Dessiner le bureau (zone a mettre a jour) }
Procedure PaintDesktop;
Var K : LongInt;
Begin
  If WUpd[0] = 0 Then Exit;
  K := NewPS(0, 2);
  If K >= 0 Then
  Begin
    PsX1[K] := WUx1[0]; PsY1[K] := WUy1[0]; PsX2[K] := WUx2[0]; PsY2[K] := WUy2[0];
    FillPS(K, WUx1[0], WUy1[0], WUx2[0], WUy2[0], 32, Attr(-2, -24));
    PsUse[K] := 0;
  End;
  WUpd[0] := 0;
  InvalAboveOthers(0, WUx1[0], WUy1[0], WUx2[0], WUy2[0]);
End;

{ Premiere fenetre a dessiner de la file Q (-1 : aucune) }
Function PaintWinOf(Q, Root : LongInt) : LongInt;
Var K, R, I : LongInt;
Begin
  R := -1;
  BuildPOrd;
  For K := 0 To PCnt - 1 Do
  Begin
    I := POrd[K];
    If (R < 0) And (I > 1) And (WUpd[I] <> 0) And (WHmq[I] = Q) And (WPid[I] = MyPid) And
       ((Root < 0) Or (I = Root) Or IsChildOf(I, Root)) Then R := I;
  End;
  PaintWinOf := R;
End;

{ WinUpdateWindow(hwnd) : dessiner maintenant la fenetre et ses enfants }
Function WinUpdateWindow(H : LongInt) : LongInt;
Var I, J, N : LongInt;
Begin
  WinUpdateWindow := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  PaintDesktop;
  N := 0;
  J := PaintWinOf(CurQ, I);
  While (J >= 0) And (N < 256) Do
  Begin
    Dummy := SendM(HwOf(J), WM_PAINT, 0, 0);
    If WUse[J] <> 0 Then WUpd[J] := 0;
    J := PaintWinOf(CurQ, I);
    Inc(N);
  End;
  WinUpdateWindow := 1;
End;

{ WinScrollWindow(hwnd, dx, dy, prclScroll, prclClip, hrgnUpdate,
  prclUpdate, fs) : RGN_RECT ; SW_SCROLLCHILDREN 1, SW_INVALIDATERGN 2 }
Function WinScrollWindow(H, Dx, Dy, PScroll, PClip, Hrgn, PUpd, Fs : LongInt) : LongInt;
Var I, X1, Y1, X2, Y2, A, B, C1, C2, R1, R2, DC, DR, C, R, SC, SR, J, U1, V1, U2, V2 : LongInt;
Begin
  WinScrollWindow := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  If Not VisRect(I, X1, Y1, X2, Y2) Then
  Begin
    WinScrollWindow := 1;
    Exit;
  End;
  A := AbsX(I); B := AbsY(I);
  If PScroll <> 0 Then
  Begin
    X1 := MaxI(X1, RdL(PScroll) + A); Y1 := MaxI(Y1, RdL(PScroll + 4) + B);
    X2 := MinI(X2, RdL(PScroll + 8) + A); Y2 := MinI(Y2, RdL(PScroll + 12) + B);
  End;
  If PClip <> 0 Then
  Begin
    X1 := MaxI(X1, RdL(PClip) + A); Y1 := MaxI(Y1, RdL(PClip + 4) + B);
    X2 := MinI(X2, RdL(PClip + 8) + A); Y2 := MinI(Y2, RdL(PClip + 12) + B);
  End;
  If GMode <> 0 Then
  Begin
    { pels deplaces par octets entiers (bords et deplacements non
      alignes : a redessiner) }
    If (X1 < X2) And (Y1 < Y2) Then
    Begin
      If (Dx Mod 8) = 0 Then
      Begin
        GScroll(X1, Y1, X2, Y2, Dx, Dy);
        If (X1 And 7) <> 0 Then InvalFrom(I, X1, Y1, MinI(X2, (X1 + 7) And Not 7), Y2);
        If (X2 And 7) <> 0 Then InvalFrom(I, MaxI(X1, X2 And Not 7), Y1, X2, Y2);
      End
      Else InvalFrom(I, X1, Y1, X2, Y2);
    End;
  End
  Else
  Begin
  DC := Dx Div 8; DR := -(Dy Div 16);
  C1 := ColOf(X1); C2 := ColOf(X2 - 1); R1 := RowOf(Y2 - 1); R2 := RowOf(Y1);
  { deplacer les cellules dans le bon ordre }
  If (DR > 0) Or ((DR = 0) And (DC > 0)) Then
  Begin
    For R := R2 DownTo R1 Do
      For C := C2 DownTo C1 Do
      Begin
        SC := C - DC; SR := R - DR;
        If (SC >= C1) And (SC <= C2) And (SR >= R1) And (SR <= R2) Then
          PutCell(C, R, RdB($B8000 + (SR * ScrCols + SC) * 2), GetAttr(SC, SR));
      End;
  End
  Else
    For R := R1 To R2 Do
      For C := C1 To C2 Do
      Begin
        SC := C - DC; SR := R - DR;
        If (SC >= C1) And (SC <= C2) And (SR >= R1) And (SR <= R2) Then
          PutCell(C, R, RdB($B8000 + (SR * ScrCols + SC) * 2), GetAttr(SC, SR));
      End;
  End;
  { zone decouverte }
  U1 := X1; V1 := Y1; U2 := X2; V2 := Y2;
  If Dx > 0 Then U2 := MinI(X2, X1 + Dx) Else If Dx < 0 Then U1 := MaxI(X1, X2 + Dx);
  If Dy > 0 Then V2 := MinI(Y2, Y1 + Dy) Else If Dy < 0 Then V1 := MaxI(Y1, Y2 + Dy);
  If Dx = 0 Then
  Begin
    U1 := X1; U2 := X2;
  End;
  If Dy = 0 Then
  Begin
    V1 := Y1; V2 := Y2;
  End;
  If PUpd <> 0 Then
  Begin
    WrL(PUpd, U1 - A); WrL(PUpd + 4, V1 - B); WrL(PUpd + 8, U2 - A); WrL(PUpd + 12, V2 - B);
  End;
  If (Fs And 2) <> 0 Then
    If (U1 < U2) And (V1 < V2) And ((Dx <> 0) Or (Dy <> 0)) Then InvalFrom(I, U1, V1, U2, V2);
  If (Fs And 1) <> 0 Then
    For J := 2 To MaxWin - 1 Do
      If (WUse[J] <> 0) And (WPar[J] = I) Then
      Begin
        WX[J] := WX[J] + Dx;
        WY[J] := WY[J] + Dy;
      End;
  WinScrollWindow := 2;
End;

{ --- rectangles (RECTL : xLeft, yBottom, xRight, yTop) --- }
Function WinSetRectEmpty(Hab, P : LongInt) : LongInt;
Begin
  WrL(P, 0); WrL(P + 4, 0); WrL(P + 8, 0); WrL(P + 12, 0);
  WinSetRectEmpty := 1;
End;

Function WinSetRect(Hab, P, X1, Y1, X2, Y2 : LongInt) : LongInt;
Begin
  WrL(P, X1); WrL(P + 4, Y1); WrL(P + 8, X2); WrL(P + 12, Y2);
  WinSetRect := 1;
End;

Function WinCopyRect(Hab, PD, PS : LongInt) : LongInt;
Begin
  WrL(PD, RdL(PS)); WrL(PD + 4, RdL(PS + 4)); WrL(PD + 8, RdL(PS + 8)); WrL(PD + 12, RdL(PS + 12));
  WinCopyRect := 1;
End;

Function RectEmpty(P : LongInt) : Boolean;
Begin
  RectEmpty := (RdL(P) >= RdL(P + 8)) Or (RdL(P + 4) >= RdL(P + 12));
End;

Function WinIsRectEmpty(Hab, P : LongInt) : LongInt;
Begin
  If RectEmpty(P) Then WinIsRectEmpty := 1 Else WinIsRectEmpty := 0;
End;

Function WinEqualRect(Hab, P1, P2 : LongInt) : LongInt;
Begin
  If (RdL(P1) = RdL(P2)) And (RdL(P1 + 4) = RdL(P2 + 4)) And (RdL(P1 + 8) = RdL(P2 + 8)) And
     (RdL(P1 + 12) = RdL(P2 + 12)) Then WinEqualRect := 1 Else WinEqualRect := 0;
End;

Function WinPtInRect(Hab, P, PPt : LongInt) : LongInt;
Begin
  If (RdL(PPt) >= RdL(P)) And (RdL(PPt) < RdL(P + 8)) And (RdL(PPt + 4) >= RdL(P + 4)) And
     (RdL(PPt + 4) < RdL(P + 12)) Then WinPtInRect := 1 Else WinPtInRect := 0;
End;

Function WinOffsetRect(Hab, P, Dx, Dy : LongInt) : LongInt;
Begin
  WrL(P, RdL(P) + Dx); WrL(P + 8, RdL(P + 8) + Dx);
  WrL(P + 4, RdL(P + 4) + Dy); WrL(P + 12, RdL(P + 12) + Dy);
  WinOffsetRect := 1;
End;

Function WinInflateRect(Hab, P, Cx, Cy : LongInt) : LongInt;
Begin
  WrL(P, RdL(P) - Cx); WrL(P + 8, RdL(P + 8) + Cx);
  WrL(P + 4, RdL(P + 4) - Cy); WrL(P + 12, RdL(P + 12) + Cy);
  WinInflateRect := 1;
End;

{ WinIntersectRect(hab, prclDst, prclSrc1, prclSrc2) : BOOL (non vide) }
Function WinIntersectRect(Hab, PD, P1, P2 : LongInt) : LongInt;
Var X1, Y1, X2, Y2 : LongInt;
Begin
  X1 := MaxI(RdL(P1), RdL(P2)); Y1 := MaxI(RdL(P1 + 4), RdL(P2 + 4));
  X2 := MinI(RdL(P1 + 8), RdL(P2 + 8)); Y2 := MinI(RdL(P1 + 12), RdL(P2 + 12));
  If (X1 >= X2) Or (Y1 >= Y2) Then
  Begin
    Dummy := WinSetRectEmpty(Hab, PD);
    WinIntersectRect := 0;
  End
  Else
  Begin
    Dummy := WinSetRect(Hab, PD, X1, Y1, X2, Y2);
    WinIntersectRect := 1;
  End;
End;

Function WinUnionRect(Hab, PD, P1, P2 : LongInt) : LongInt;
Var X1, Y1, X2, Y2 : LongInt;
Begin
  If RectEmpty(P1) Then WinUnionRect := WinCopyRect(Hab, PD, P2)
  Else If RectEmpty(P2) Then WinUnionRect := WinCopyRect(Hab, PD, P1)
  Else
  Begin
    X1 := MinI(RdL(P1), RdL(P2)); Y1 := MinI(RdL(P1 + 4), RdL(P2 + 4));
    X2 := MaxI(RdL(P1 + 8), RdL(P2 + 8)); Y2 := MaxI(RdL(P1 + 12), RdL(P2 + 12));
    WinUnionRect := WinSetRect(Hab, PD, X1, Y1, X2, Y2);
  End;
End;

{ WinSubtractRect(hab, prclDst, prclSrc1, prclSrc2) : Src1 moins Src2
  (si le reste est un rectangle) ; BOOL (non vide) }
Function WinSubtractRect(Hab, PD, P1, P2 : LongInt) : LongInt;
Var X1, Y1, X2, Y2, A1, B1, A2, B2 : LongInt;
Begin
  X1 := RdL(P1); Y1 := RdL(P1 + 4); X2 := RdL(P1 + 8); Y2 := RdL(P1 + 12);
  A1 := RdL(P2); B1 := RdL(P2 + 4); A2 := RdL(P2 + 8); B2 := RdL(P2 + 12);
  If (A1 <= X1) And (A2 >= X2) Then
  Begin
    If (B1 <= Y1) And (B2 > Y1) Then Y1 := MinI(B2, Y2)
    Else If (B2 >= Y2) And (B1 < Y2) Then Y2 := MaxI(B1, Y1);
  End
  Else If (B1 <= Y1) And (B2 >= Y2) Then
  Begin
    If (A1 <= X1) And (A2 > X1) Then X1 := MinI(A2, X2)
    Else If (A2 >= X2) And (A1 < X2) Then X2 := MaxI(A1, X1);
  End;
  Dummy := WinSetRect(Hab, PD, X1, Y1, X2, Y2);
  If (X1 < X2) And (Y1 < Y2) Then WinSubtractRect := 1 Else WinSubtractRect := 0;
End;

{ WinMakeRect(hab, pwrc) : WRECT (4 mots signes) -> RECTL, sur place }
Function WinMakeRect(Hab, P : LongInt) : LongInt;
Var A, B, C, D : LongInt;
Begin
  A := RdSW(P); B := RdSW(P + 2); C := RdSW(P + 4); D := RdSW(P + 6);
  WrL(P, A); WrL(P + 4, B); WrL(P + 8, C); WrL(P + 12, D);
  WinMakeRect := 1;
End;

{ WinMakePoints(hab, pwpt, cwpt) : WPOINT -> POINTL, sur place }
Function WinMakePoints(Hab, P, N : LongInt) : LongInt;
Var K, X, Y : LongInt;
Begin
  For K := N - 1 DownTo 0 Do
  Begin
    X := RdSW(P + K * 4); Y := RdSW(P + K * 4 + 2);
    WrL(P + K * 8, X); WrL(P + K * 8 + 4, Y);
  End;
  WinMakePoints := 1;
End;

{ --- dessin --- }
Function WinFillRect(Hps, P, Clr : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsIdx(Hps);
  If (K < 0) Or (P = 0) Then WinFillRect := 0
  Else
  Begin
    FillPS(K, RdL(P), RdL(P + 4), RdL(P + 8), RdL(P + 12), 32, Attr(-17, Clr));
    WinFillRect := 1;
  End;
End;

Function WinInvertRect(Hps, P : LongInt) : LongInt;
Var K, C, R, C1, C2, R1, R2, A : LongInt;
Begin
  WinInvertRect := 0;
  K := PsIdx(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  If GMode <> 0 Then
  Begin
    If GPsClip(K) Then
      GFillPat(RdL(P) + PsOrgX[K], RdL(P + 4) + PsOrgY[K], RdL(P + 8) + PsOrgX[K], RdL(P + 12) + PsOrgY[K], 15, $FF, 3);
    WinInvertRect := 1;
    Exit;
  End;
  C1 := ColOf(RdL(P) + PsOrgX[K]); C2 := ColOf(RdL(P + 8) - 1 + PsOrgX[K]);
  R1 := RowOf(RdL(P + 12) - 1 + PsOrgY[K]); R2 := RowOf(RdL(P + 4) + PsOrgY[K]);
  For R := R1 To R2 Do
    For C := C1 To C2 Do
      If CanDraw(K, C, R) Then
      Begin
        A := GetAttr(C, R);
        SetAttr(C, R, ((A Shr 4) And 7) Or ((A And 7) Shl 4) Or (A And $88));
      End;
  WinInvertRect := 1;
End;

{ Cadre de caracteres (simple ou double) dans l'espace K }
Procedure BoxPS(K, X1, Y1, X2, Y2, A : LongInt; Dbl : Boolean);
Var C, R, C1, C2, R1, R2, H, V, TL, TR, BL, BR : LongInt;
Begin
  If Dbl Then
  Begin
    H := $CD; V := $BA; TL := $C9; TR := $BB; BL := $C8; BR := $BC;
  End
  Else
  Begin
    H := $C4; V := $B3; TL := $DA; TR := $BF; BL := $C0; BR := $D9;
  End;
  X1 := X1 + PsOrgX[K]; X2 := X2 + PsOrgX[K]; Y1 := Y1 + PsOrgY[K]; Y2 := Y2 + PsOrgY[K];
  If (X1 >= X2) Or (Y1 >= Y2) Then Exit;
  If GMode <> 0 Then
  Begin
    If GPsClip(K) Then
    Begin
      GFrame(X1, Y1, X2, Y2, A And 15);
      If Dbl Then GFrame(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, A And 15);
    End;
    Exit;
  End;
  C1 := ColOf(X1); C2 := ColOf(X2 - 1); R1 := RowOf(Y2 - 1); R2 := RowOf(Y1);
  For C := C1 To C2 Do
  Begin
    If CanDraw(K, C, R1) Then PutCell(C, R1, H, A);
    If CanDraw(K, C, R2) Then PutCell(C, R2, H, A);
  End;
  For R := R1 To R2 Do
  Begin
    If CanDraw(K, C1, R) Then PutCell(C1, R, V, A);
    If CanDraw(K, C2, R) Then PutCell(C2, R, V, A);
  End;
  If CanDraw(K, C1, R1) Then PutCell(C1, R1, TL, A);
  If CanDraw(K, C2, R1) Then PutCell(C2, R1, TR, A);
  If CanDraw(K, C1, R2) Then PutCell(C1, R2, BL, A);
  If CanDraw(K, C2, R2) Then PutCell(C2, R2, BR, A);
End;

{ WinDrawBorder(hps, prcl, cx, cy, clrFore, clrBack, flCmd) : BOOL ;
  DB_PATINVERT 1, DB_DESTINVERT 2, DB_INTERIOR 8, DB_DLGBORDER 200h }
Function WinDrawBorder(Hps, P, Cx, Cy, Fg, Bg, Fl : LongInt) : LongInt;
Var K, X1, Y1, X2, Y2, F, Op : LongInt;
Begin
  WinDrawBorder := 0;
  K := PsIdx(Hps);
  If (K < 0) Or (P = 0) Then Exit;
  X1 := RdL(P); Y1 := RdL(P + 4); X2 := RdL(P + 8); Y2 := RdL(P + 12);
  If GMode <> 0 Then
  Begin
    If GPsClip(K) Then
    Begin
      X1 := X1 + PsOrgX[K]; X2 := X2 + PsOrgX[K]; Y1 := Y1 + PsOrgY[K]; Y2 := Y2 + PsOrgY[K];
      Cx := MaxI(Cx, 0); Cy := MaxI(Cy, 0);
      If (Fl And 8) <> 0 Then GFill(X1 + Cx, Y1 + Cy, X2 - Cx, Y2 - Cy, VgaColor(Bg, True));
      F := VgaColor(Fg, False);
      If (Fl And 3) <> 0 Then
      Begin
        Op := 3; F := 15;
      End
      Else Op := 0;
      If Cy > 0 Then
      Begin
        GFillPat(X1, Y2 - Cy, X2, Y2, F, $FF, Op); GFillPat(X1, Y1, X2, Y1 + Cy, F, $FF, Op);
      End;
      If Cx > 0 Then
      Begin
        GFillPat(X1, Y1 + Cy, X1 + Cx, Y2 - Cy, F, $FF, Op); GFillPat(X2 - Cx, Y1 + Cy, X2, Y2 - Cy, F, $FF, Op);
      End;
    End;
    WinDrawBorder := 1;
    Exit;
  End;
  If (Fl And 8) <> 0 Then FillPS(K, X1, Y1, X2, Y2, 32, Attr(Fg, Bg));
  If (Cx > 0) Or (Cy > 0) Then BoxPS(K, X1, Y1, X2, Y2, Attr(Fg, Bg), (Fl And $200) <> 0);
  WinDrawBorder := 1;
End;

{ WinDrawText(hps, cchText, lpchText, prcl, clrFore, clrBack, flCmd) :
  caracteres dessines. DT_LEFT 0, DT_QUERYEXTENT 2, DT_CENTER 100h,
  DT_RIGHT 200h, DT_TOP 0, DT_VCENTER 400h, DT_BOTTOM 800h, DT_HALFTONE
  1000h, DT_MNEMONIC 2000h, DT_WORDBREAK 4000h, DT_ERASERECT 8000h }
Function WinDrawText(Hps, Cch, P, PRcl, Fg, Bg, Fl : LongInt) : LongInt;
Var K, X1, Y1, X2, Y2, W, N, X, Y, J, A, AM, Ch, Drawn : LongInt; S, T : String; Mn : Boolean;
Begin
  WinDrawText := 0;
  K := PsIdx(Hps);
  If (K < 0) Or (PRcl = 0) Then Exit;
  S := GetN(P, Cch);
  X1 := RdL(PRcl); Y1 := RdL(PRcl + 4); X2 := RdL(PRcl + 8); Y2 := RdL(PRcl + 12);
  { texte affiche (sans les ~ des mnemoniques) }
  T := '';
  For J := 1 To Length(S) Do
    If Not (((Fl And $2000) <> 0) And (Ord(S[J]) = 126)) Then T := T + S[J];
  N := Length(T);
  If (Fl And $4000) <> 0 Then
    If N * 8 > X2 - X1 Then
    Begin
      N := (X2 - X1) Div 8;
      J := N;
      While (J > 0) And (Ord(T[J + 1]) <> 32) Do Dec(J);
      If J > 0 Then N := J;
    End;
  W := N * 8;
  If (Fl And $100) <> 0 Then X := X1 + ((X2 - X1) - W) Div 2
  Else If (Fl And $200) <> 0 Then X := X2 - W
  Else X := X1;
  If (Fl And $400) <> 0 Then Y := Y1 + ((Y2 - Y1) - 16) Div 2
  Else If (Fl And $800) <> 0 Then Y := Y1
  Else Y := Y2 - 16;
  If (Fl And 2) <> 0 Then
  Begin
    WrL(PRcl, X); WrL(PRcl + 4, Y); WrL(PRcl + 8, X + W); WrL(PRcl + 12, Y + 16);
    WinDrawText := N;
    Exit;
  End;
  If (Fl And $1000) <> 0 Then Fg := 8;
  A := Attr(Fg, Bg);
  AM := (A And $F0) Or 15;
  If (Fl And $8000) <> 0 Then FillPS(K, X1, Y1, X2, Y2, 32, A);
  Drawn := 0;
  Mn := False;
  J := 1;
  While (J <= Length(S)) And (Drawn < N) Do
  Begin
    Ch := Ord(S[J]);
    If ((Fl And $2000) <> 0) And (Ch = 126) Then Mn := True
    Else
    Begin
      If (X >= X1) And (X + 8 <= X2) Then
      Begin
        If Mn And (GMode <> 0) Then
        Begin
          CharPS(K, X, Y, Ch, A); UnderPS(K, X, Y, A);
        End
        Else If Mn Then CharPS(K, X, Y, Ch, AM) Else CharPS(K, X, Y, Ch, A);
      End;
      X := X + 8;
      Inc(Drawn);
      Mn := False;
    End;
    Inc(J);
  End;
  WinDrawText := J - 1;
End;

{ --- bitmaps (dessinees en trame) --- }
Function BmIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := -1;
  If (H >= $424D0001) And (H < $424D0001 + MaxBmp) Then
  Begin
    I := H - $424D0001;
    If BmUse[I] = 0 Then I := -1;
  End;
  BmIdx := I;
End;

Function NewBmp(Cx, Cy, Data : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxBmp - 1 DownTo 0 Do
    If BmUse[I] = 0 Then F := I;
  If F < 0 Then NewBmp := 0
  Else
  Begin
    BmUse[F] := 1; BmCX[F] := Cx; BmCY[F] := Cy; BmData[F] := Data;
    NewBmp := $424D0001 + F;
  End;
End;

{ GpiLoadBitmap(hps, hmod, idBitmap, width, height) : HBITMAP }
Function GpiLoadBitmap(Hps, Hmod, Id, Cx, Cy : LongInt) : LongInt;
Var P, W, H : LongInt;
Begin
  P := GetRes(Hmod, 2, Id);
  If P = 0 Then
  Begin
    SetErr(PMERR_RESOURCE_NOT_FOUND);
    GpiLoadBitmap := 0;
    Exit;
  End;
  W := 16; H := 16;
  If (RdW(P) = $4D42) Then
  Begin
    If RdL(P + 14) = 12 Then
    Begin
      W := RdW(P + 18); H := RdW(P + 20);
    End
    Else
    Begin
      W := RdL(P + 18); H := RdL(P + 22);
    End;
  End;
  If Cx > 0 Then W := Cx;
  If Cy > 0 Then H := Cy;
  GpiLoadBitmap := NewBmp(W, H, P);
End;

{ WinGetSysBitmap(hwndDesktop, ibm) : HBITMAP du systeme (16 x 16) }
Function WinGetSysBitmap(HDesk, Ibm : LongInt) : LongInt;
Begin
  If (Ibm <= 0) Or (Ibm > 64) Then WinGetSysBitmap := 0 Else WinGetSysBitmap := NewBmp(16, 16, -Ibm);
End;

{ WinDrawBitmap(hpsDst, hbm, pwrcSrc, pptlDst, clrFore, clrBack, fl) :
  BOOL ; DBM_INVERT 1, DBM_HALFTONE 2, DBM_STRETCH 4 (pptlDst : RECTL) }
Function WinDrawBitmap(Hps, Hbm, PSrc, PDst, Fg, Bg, Fl : LongInt) : LongInt;
Var K, B, X1, Y1, X2, Y2, Ch, A : LongInt;
Begin
  WinDrawBitmap := 0;
  K := PsIdx(Hps); B := BmIdx(Hbm);
  If (K < 0) Or (B < 0) Or (PDst = 0) Then Exit;
  X1 := RdL(PDst); Y1 := RdL(PDst + 4);
  If (Fl And 4) <> 0 Then
  Begin
    X2 := RdL(PDst + 8); Y2 := RdL(PDst + 12);
  End
  Else
  Begin
    X2 := X1 + BmCX[B]; Y2 := Y1 + BmCY[B];
    If PSrc <> 0 Then
    Begin
      X2 := X1 + RdL(PSrc + 8) - RdL(PSrc); Y2 := Y1 + RdL(PSrc + 12) - RdL(PSrc + 4);
    End;
  End;
  If GMode <> 0 Then
  Begin
    If GPsClip(K) Then
    Begin
      X1 := X1 + PsOrgX[K]; X2 := X2 + PsOrgX[K]; Y1 := Y1 + PsOrgY[K]; Y2 := Y2 + PsOrgY[K];
      If BmData[B] < 0 Then GSysBitmap(-BmData[B], X1, Y1, X2, Y2)
      Else GBitmap(BmData[B], X1, Y1, X2, Y2, VgaColor(Fg, False), VgaColor(Bg, True), (Fl And 1) <> 0);
      If (Fl And 2) <> 0 Then GFillPat(X1, Y1, X2, Y2, 7, $AA, 0);
    End;
    WinDrawBitmap := 1;
    Exit;
  End;
  If (Fl And 2) <> 0 Then Ch := $B0 Else Ch := $B1;
  If (Fl And 1) <> 0 Then A := Attr(Bg, Fg) Else A := Attr(Fg, Bg);
  FillPS(K, X1, Y1, X2, Y2, Ch, A);
  WinDrawBitmap := 1;
End;

{ --- pointeurs --- }
Function PtrValid(H : LongInt) : Boolean;
Var I : LongInt;
Begin
  If (H > $50540000) And (H <= $50540016) Then PtrValid := True
  Else
  Begin
    I := H - $50540101;
    PtrValid := (I >= 0) And (I < MaxPtr) And (PtUse[I] <> 0);
  End;
End;

Function NewPtr(HotX, HotY, Bmp, Ani : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxPtr - 1 DownTo 0 Do
    If (PtUse[I] = 0) Or Not Alive(PtPid[I]) Then F := I;
  If F < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    NewPtr := 0;
  End
  Else
  Begin
    PtUse[F] := 1; PtHotX[F] := HotX; PtHotY[F] := HotY; PtBmp[F] := Bmp; PtPid[F] := MyPid; PtAni[F] := Ani;
    NewPtr := $50540101 + F;
  End;
End;

{ caractere d'un pointeur (dessin) }
Function PtrGlyph(H : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := H - $50540000;
  If N = 2 Then PtrGlyph := 73
  Else If N = 3 Then PtrGlyph := $B0
  Else If (N >= 4) And (N <= 9) Then PtrGlyph := $1D
  Else If (N >= 10) And (N <= 14) Then PtrGlyph := $FE
  Else PtrGlyph := $18;
End;

Function WinQuerySysPointer(HDesk, Iptr, Load : LongInt) : LongInt;
Begin
  If (Iptr < 1) Or (Iptr > 22) Then
  Begin
    SetErr(PMERR_PARAMETER_OUT_OF_RANGE);
    WinQuerySysPointer := 0;
  End
  Else If Load <> 0 Then WinQuerySysPointer := NewPtr(0, 0, 0, 0)
  Else WinQuerySysPointer := $50540000 + Iptr;
End;

Function CurMou : LongInt; Forward;

Function WinSetPointer(HDesk, Hptr : LongInt) : LongInt;
Begin
  If (Hptr <> 0) And Not PtrValid(Hptr) Then
  Begin
    SetErr(PMERR_INVALID_HPTR);
    WinSetPointer := 0;
  End
  Else
  Begin
    PtrCur := Hptr;
    WinSetPointer := 1;
  End;
End;

Function WinQueryPointer(HDesk : LongInt) : LongInt;
Begin
  WinQueryPointer := PtrCur;
End;

Function WinShowPointer(HDesk, Show : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := CurMou;
  If GMode <> 0 Then
  Begin
    If Show <> 0 Then Inc(PtrLevel) Else Dec(PtrLevel);
    If PtrLevel < 0 Then GPtrHide;
    SysVal[44] := PtrLevel;
    WinShowPointer := 1;
    Exit;
  End;
  If Show <> 0 Then
  Begin
    Inc(PtrLevel);
    If (PtrLevel >= 0) And (H <> 0) Then Dummy := MouDrawPtr(H);
  End
  Else
  Begin
    Dec(PtrLevel);
    If (PtrLevel = -1) And (H <> 0) Then
    Begin
      WrW(LongInt(@NameZ), 0); WrW(LongInt(@NameZ) + 2, 0); WrW(LongInt(@NameZ) + 4, ScrRows - 1);
      WrW(LongInt(@NameZ) + 6, ScrCols - 1);
      Dummy := MouRemovePtr(LongInt(@NameZ), H);
    End;
  End;
  SysVal[44] := PtrLevel;
  WinShowPointer := 1;
End;

Function WinSetPointerPos(HDesk, X, Y : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := CurMou;
  MouseX := MaxI(0, MinI(X, ScrCX - 1)); MouseY := MaxI(0, MinI(Y, ScrCY - 1));
  If GMode <> 0 Then
  Begin
    WrW(LongInt(@NameZ), ScrCY - 1 - MouseY);
    WrW(LongInt(@NameZ) + 2, MouseX);
  End
  Else
  Begin
    WrW(LongInt(@NameZ), MaxI(0, MinI(ScrRows - 1, RowOf(Y))));
    WrW(LongInt(@NameZ) + 2, MaxI(0, MinI(ScrCols - 1, ColOf(X))));
  End;
  If H <> 0 Then Dummy := MouSetPtrPos(LongInt(@NameZ), H);
  WinSetPointerPos := 1;
End;

Function WinQueryPointerPos(HDesk, P : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := CurMou;
  If H <> 0 Then
    If MouGetPtrPos(LongInt(@NameZ), H) = 0 Then
    Begin
      If GMode <> 0 Then
      Begin
        MouseX := MaxI(0, MinI(RdW(LongInt(@NameZ) + 2), ScrCX - 1));
        MouseY := MaxI(0, MinI(ScrCY - 1 - RdW(LongInt(@NameZ)), ScrCY - 1));
      End
      Else
      Begin
        MouseX := RdW(LongInt(@NameZ) + 2) * 8 + 4;
        MouseY := (ScrRows - 1 - RdW(LongInt(@NameZ))) * 16 + 8;
      End;
    End;
  WrL(P, MouseX); WrL(P + 4, MouseY);
  WinQueryPointerPos := 1;
End;

{ WinLoadPointer(hwndDesktop, hmod, idres) : RT_POINTER }
Function WinLoadPointer(HDesk, Hmod, Id : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := GetRes(Hmod, 1, Id);
  If P = 0 Then
  Begin
    SetErr(PMERR_RESOURCE_NOT_FOUND);
    WinLoadPointer := 0;
  End
  Else WinLoadPointer := NewPtr(0, 0, NewBmp(16, 16, P), 0);
End;

{ WinCreatePointer(hwndDesktop, hbmPointer, fPointer, xHotspot, yHotspot) }
Function WinCreatePointer(HDesk, Hbm, FPtr, HotX, HotY : LongInt) : LongInt;
Begin
  If (Hbm <> 0) And (BmIdx(Hbm) < 0) Then
  Begin
    SetErr(PMERR_INVALID_PARAMETERS);
    WinCreatePointer := 0;
  End
  Else WinCreatePointer := NewPtr(HotX, HotY, Hbm, 0);
End;

{ WinCreatePointerIndirect(hwndDesktop, pptri) : POINTERINFO (fPointer,
  xHotspot, yHotspot, hbmPointer, hbmColor, hbmMiniPointer, hbmMiniColor) }
Function WinCreatePointerIndirect(HDesk, P : LongInt) : LongInt;
Begin
  If P = 0 Then WinCreatePointerIndirect := 0
  Else WinCreatePointerIndirect := NewPtr(RdL(P + 4), RdL(P + 8), RdL(P + 12), 0);
End;

Function WinDestroyPointer(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $50540101;
  If (I < 0) Or (I >= MaxPtr) Or (PtUse[I] = 0) Then
  Begin
    SetErr(PMERR_INVALID_HPTR);
    WinDestroyPointer := 0;
  End
  Else
  Begin
    PtUse[I] := 0;
    If PtrCur = H Then PtrCur := $50540001;
    WinDestroyPointer := 1;
  End;
End;

Function WinQueryPointerInfo(H, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinQueryPointerInfo := 0;
  If (P = 0) Or Not PtrValid(H) Then
  Begin
    SetErr(PMERR_INVALID_HPTR);
    Exit;
  End;
  MemZero(P, 28);
  WrL(P, 1);
  I := H - $50540101;
  If (I >= 0) And (I < MaxPtr) Then
  Begin
    WrL(P + 4, PtHotX[I]); WrL(P + 8, PtHotY[I]); WrL(P + 12, PtBmp[I]);
  End;
  WinQueryPointerInfo := 1;
End;

Function OldWinQueryPointerInfo(H, P : LongInt) : LongInt;
Begin
  OldWinQueryPointerInfo := WinQueryPointerInfo(H, P);
End;

{ WinBuildPtrHandle(pData) : pointeur d'apres des donnees en memoire }
Function WinBuildPtrHandle(P : LongInt) : LongInt;
Begin
  If P = 0 Then WinBuildPtrHandle := 0 Else WinBuildPtrHandle := NewPtr(0, 0, NewBmp(16, 16, P), 0);
End;

Function WinSetPointerOwner(H, Pid, FDestroy : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $50540101;
  If (I < 0) Or (I >= MaxPtr) Or (PtUse[I] = 0) Then WinSetPointerOwner := 0
  Else
  Begin
    PtPid[I] := Pid;
    If FDestroy = 0 Then PtPid[I] := 0;
    WinSetPointerOwner := 1;
  End;
End;

Function WinLockPointerUpdate(HDesk, Hptr, Interval : LongInt) : LongInt;
Begin
  WinLockPointerUpdate := WinSetPointer(HDesk, Hptr);
End;

{ pointeurs animes : WinLoadAniPointer(hmod, idres, pReserved) }
Function WinLoadAniPointer(Hmod, Id, PRes : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := GetRes(Hmod, 1, Id);
  If P = 0 Then
  Begin
    SetErr(PMERR_RESOURCE_NOT_FOUND);
    WinLoadAniPointer := 0;
  End
  Else WinLoadAniPointer := NewPtr(0, 0, NewBmp(16, 16, P), 1);
End;

Function WinDestroyAniPointer(H : LongInt) : LongInt;
Begin
  WinDestroyAniPointer := WinDestroyPointer(H);
End;

Function WinSetAniPointer(H, FAnimate : LongInt) : LongInt;
Begin
  WinSetAniPointer := WinSetPointer(HWND_DESKTOP, H);
End;

{ WinDrawPointer(hps, x, y, hptr, fs) : DP_HALFTONED 1, DP_INVERTED 2 }
Function WinDrawPointer(Hps, X, Y, H, Fs : LongInt) : LongInt;
Var K, A : LongInt;
Begin
  K := PsIdx(Hps);
  If (K < 0) Or Not PtrValid(H) Then
  Begin
    WinDrawPointer := 0;
    Exit;
  End;
  If GMode <> 0 Then
  Begin
    If GPsClip(K) Then GPtrImage(X + PsOrgX[K], Y + PsOrgY[K]);
    WinDrawPointer := 1;
    Exit;
  End;
  If (Fs And 2) <> 0 Then A := $70 Else If (Fs And 1) <> 0 Then A := $08 Else A := $0F;
  CharPS(K, X, Y, PtrGlyph(H), A Or (GetAttr(MaxI(0, ColOf(X + PsOrgX[K])), MaxI(0, MinI(24, RowOf(Y + PsOrgY[K])))) And $70));
  WinDrawPointer := 1;
End;

Function WinStretchPointer(Hps, X, Y, Cx, Cy, H, Fs : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PsIdx(Hps);
  If (K < 0) Or Not PtrValid(H) Then WinStretchPointer := 0
  Else
  Begin
    If GMode <> 0 Then
    Begin
      If GPsClip(K) Then GPtrImage(X + PsOrgX[K], Y + PsOrgY[K]);
    End
    Else FillPS(K, X, Y, X + MaxI(Cx, 8), Y + MaxI(Cy, 16), PtrGlyph(H), $0F);
    WinStretchPointer := 1;
  End;
End;

{ --- curseur (curseur materiel de l'ecran texte) --- }
Procedure ShowHwCursor;
Var Vis : Boolean; C, R, X1, Y1, X2, Y2, A, B : LongInt;
Begin
  Vis := (CursorWin > 1) And (WUse[CursorWin] <> 0) And (CurShown > 0) And Shown(CursorWin);
  If GMode <> 0 Then
  Begin
    { curseur dessine (rectangle inverse) : CURSOR_FRAME 2 : contour }
    X1 := 0; Y1 := 0; X2 := 0; Y2 := 0;
    If Vis Then
    Begin
      A := AbsX(CursorWin) + CurX; B := AbsY(CursorWin) + CurY;
      X1 := A; Y1 := B; X2 := A + CurCX; Y2 := B + CurCY;
      If CurCX <= 0 Then X2 := A + 2;
      If CurCY <= 0 Then Y2 := B + 16;
      If VisRect(CursorWin, A, B, C, R) Then
      Begin
        X1 := MaxI(X1, A); Y1 := MaxI(Y1, B); X2 := MinI(X2, C); Y2 := MinI(Y2, R);
      End
      Else X2 := X1;
      If (X1 >= X2) Or (Y1 >= Y2) Then Vis := False;
    End;
    If (GCarOn <> 0) And ((Not Vis) Or (X1 <> GCdX1) Or (Y1 <> GCdY1) Or (X2 <> GCdX2) Or (Y2 <> GCdY2)) Then GCarHide;
    If Vis Then GCarWant := 1 Else GCarWant := 0;
    GCarX1 := X1; GCarY1 := Y1; GCarX2 := X2; GCarY2 := Y2;
    Exit;
  End;
  If Vis Then
  Begin
    C := ColOf(AbsX(CursorWin) + CurX);
    R := RowOf(AbsY(CursorWin) + CurY);
    Dummy := VioSetCurPos(MaxI(0, MinI(24, R)), MaxI(0, MinI(79, C)), 0);
  End;
  WrW(LongInt(@NameZ2), 13); WrW(LongInt(@NameZ2) + 2, 15); WrW(LongInt(@NameZ2) + 4, 1);
  If (CurFs And 3) = 0 Then WrW(LongInt(@NameZ2), 0);
  If Vis Then WrW(LongInt(@NameZ2) + 6, 0) Else WrW(LongInt(@NameZ2) + 6, $FFFF);
  Dummy := VioSetCurType(LongInt(@NameZ2), 0);
End;

{ WinCreateCursor(hwnd, x, y, cx, cy, fs, prclClip) : BOOL ;
  CURSOR_SOLID 0, CURSOR_HALFTONE 1, CURSOR_FRAME 2, CURSOR_FLASH 4,
  CURSOR_SETPOS 8000h }
Function WinCreateCursor(H, X, Y, Cx, Cy, Fs, PClip : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinCreateCursor := 0;
  I := WChk(H);
  If I < 2 Then Exit;
  If ((Fs And $8000) <> 0) And (CursorWin = I) Then
  Begin
    CurX := X; CurY := Y;
  End
  Else
  Begin
    CursorWin := I;
    CurX := X; CurY := Y; CurCX := Cx; CurCY := Cy; CurFs := Fs And $7FFF;
    CurShown := 0;
  End;
  ShowHwCursor;
  WinCreateCursor := 1;
End;

Function WinMoveCursor(H, X, Y : LongInt) : LongInt;
Begin
  WinMoveCursor := WinCreateCursor(H, X, Y, 0, 0, $8000, 0);
End;

Function WinShowCursor(H, Show : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WIdx(H);
  If (I < 0) Or (I <> CursorWin) Then WinShowCursor := 0
  Else
  Begin
    If Show <> 0 Then Inc(CurShown) Else Dec(CurShown);
    ShowHwCursor;
    WinShowCursor := 1;
  End;
End;

Function WinDestroyCursor(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WIdx(H);
  If (I < 0) Or (I <> CursorWin) Then WinDestroyCursor := 0
  Else
  Begin
    CursorWin := 0;
    ShowHwCursor;
    WinDestroyCursor := 1;
  End;
End;

{ WinQueryCursorInfo(hwndDesktop, pcsri) : CURSORINFO (hwnd, x, y, cx,
  cy, fs, rclClip) }
Function WinQueryCursorInfo(HDesk, P : LongInt) : LongInt;
Begin
  If (P = 0) Or (CursorWin < 2) Then WinQueryCursorInfo := 0
  Else
  Begin
    MemZero(P, 40);
    WrL(P, HwOf(CursorWin)); WrL(P + 4, CurX); WrL(P + 8, CurY); WrL(P + 12, CurCX); WrL(P + 16, CurCY);
    WrL(P + 20, CurFs); WrL(P + 32, WCX[CursorWin]); WrL(P + 36, WCY[CursorWin]);
    WinQueryCursorInfo := 1;
  End;
End;

{ --- contextes de peripherique --- }
Function WinOpenWindowDC(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 0 Then WinOpenWindowDC := 0
  Else
  Begin
    WDC[I] := 1;
    WinOpenWindowDC := $44430000 + I;
  End;
End;

Function WinQueryWindowDC(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WIdx(H);
  If (I < 0) Or (WDC[I] = 0) Then WinQueryWindowDC := 0 Else WinQueryWindowDC := $44430000 + I;
End;

Function WinWindowFromDC(Hdc : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := Hdc - $44430000;
  If (I >= 0) And (I < MaxWin) And (WUse[I] <> 0) And (WDC[I] <> 0) Then WinWindowFromDC := HwOf(I)
  Else WinWindowFromDC := 0;
End;

Function WinSetWindowDC(H, Hdc : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 0 Then WinSetWindowDC := 0
  Else
  Begin
    If Hdc <> 0 Then WDC[I] := 1 Else WDC[I] := 0;
    WinSetWindowDC := 1;
  End;
End;

{ --- avertissements de region visible --- }
{ VisRegionCallback(pfnCallback, fRegister) : la fonction (hwnd) est
  appelee quand une fenetre change de position ou de visibilite ; BOOL }
Function VisRegionCallback(Pfn, Reg : LongInt) : LongInt;
Var K, F : LongInt;
Begin
  F := -1;
  For K := 7 DownTo 0 Do
    If VisCb[K] = Pfn Then F := K;
  If Reg = 0 Then
  Begin
    If F >= 0 Then VisCb[F] := 0;
    VisRegionCallback := 1;
    Exit;
  End;
  If F < 0 Then
    For K := 7 DownTo 0 Do
      If VisCb[K] = 0 Then F := K;
  If (F < 0) Or (Pfn = 0) Then VisRegionCallback := 0
  Else
  Begin
    VisCb[F] := Pfn;
    VisRegionCallback := 1;
  End;
End;

Procedure VisNotify(I : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 7 Do
    If VisCb[K] <> 0 Then Dummy := Call3(VisCb[K], HwOf(I), 0, 0);
End;

{ WinVisRegionNotify(hwnd, fs) : avertir les fonctions inscrites ; BOOL }
Function WinVisRegionNotify(H, Fs : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WIdx(H);
  If I < 0 Then WinVisRegionNotify := 0
  Else
  Begin
    VisNotify(I);
    WinVisRegionNotify := 1;
  End;
End;


{ ==================================================================== }
{ Partie 4 - Files de messages, entrees, focus, minuteries, crochets   }
{ ==================================================================== }

Function CurQ : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := MaxQ - 1 DownTo 0 Do
    If QPid[I] = MyPid Then R := I;
  CurQ := R;
End;

{ Rang d'une file (HMQ_CURRENT = 1 : file du processus) }
Function QIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  If H = 1 Then I := CurQ
  Else
  Begin
    I := H - $00510001;
    If (I < 0) Or (I >= MaxQ) Then I := -1
    Else If QPid[I] = 0 Then I := -1;
  End;
  QIdx := I;
End;

{ souris de la file courante (ouverte a la demande) }
Function CurMou : LongInt;
Var Q, H : LongInt;
Begin
  Q := CurQ;
  H := 0;
  If Q >= 0 Then
  Begin
    If QMou[Q] = 0 Then
      If MouOpen(0, LongInt(@H)) = 0 Then QMou[Q] := H;
    H := QMou[Q];
  End
  Else If MouOpen(0, LongInt(@H)) <> 0 Then H := 0;
  CurMou := H;
End;

{ Fenetres des processus termines }
Procedure CleanupDead;
Var I : LongInt;
Begin
  For I := 2 To MaxWin - 1 Do
    If (WUse[I] <> 0) And (WPid[I] <> 0) And Not Alive(WPid[I]) And (WPar[I] <= 1) Then DestroyIdx(I);
  For I := 0 To MaxQ - 1 Do
    If (QPid[I] <> 0) And Not Alive(QPid[I]) Then QPid[I] := 0;
  For I := 0 To MaxHab - 1 Do
    If (HabPid[I] <> 0) And Not Alive(HabPid[I]) Then HabPid[I] := 0;
End;

{ WinCreateMsgQueue(hab, cmsg) : HMQ }
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt;
Var I, F : LongInt; First : Boolean;
Begin
  WinCreateMsgQueue := 0;
  EnsureInit;
  CleanupDead;
  If CurQ >= 0 Then
  Begin
    SetErr(PMERR_MSG_QUEUE_ALREADY_EXISTS);
    Exit;
  End;
  If N <= 0 Then N := 10;
  If N > 256 Then N := 256;
  F := -1;
  For I := MaxQ - 1 DownTo 0 Do
    If QPid[I] = 0 Then F := I;
  If F < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    Exit;
  End;
  QBuf[F] := MemAlloc(N * 32);
  If QBuf[F] = 0 Then
  Begin
    SetErr(PMERR_HEAP_OUT_OF_MEMORY);
    Exit;
  End;
  KpN[F] := 0;
  QPid[F] := MyPid; QHab[F] := Hab; QSize[F] := N; QHead[F] := 0; QCount[F] := 0;
  QCp[F] := 850; QStat[F] := 0; QLockIn[F] := 0; QAccel[F] := 0; QProc[F] := 0;
  QQuit[F] := 0; QMou[F] := 0; QLastDown[F] := 0; QDownWin[F] := -1; QDownTime[F] := 0;
  QPosX[F] := 0; QPosY[F] := 0; QTime[F] := 0;
  First := True;
  For I := 0 To MaxQ - 1 Do
    If (I <> F) And (QPid[I] <> 0) Then First := False;
  { premiere file, ou premiere file d'un programme lance par l'interpreteur
    pendant que l'ecran lui est prete }
  If (Susp <> 0) And (MyPid <> SuspPid) Then SuspTook := 1;
  { le programme rejoint la session de Presentation Manager (premier plan) }
  Dummy := KSes(5, 0, 0);
  { un programme de PM n'est pas preempte (ses procedures de fenetre sont
    appelees depuis PMWIN) : il cede la main en attendant ses messages }
  Dummy := KTask(4, 1, 0, 0);
  If First Or ((Susp <> 0) And (MyPid <> SuspPid)) Then ScreenStart;
  PmEpoch := SesEpoch;
  WinCreateMsgQueue := $00510001 + F;
End;

{ WinDestroyMsgQueue(hmq) : les fenetres de la file sont detruites ; BOOL }
Function WinDestroyMsgQueue(H : LongInt) : LongInt;
Var Q, I : LongInt;
Begin
  Q := QIdx(H);
  If Q < 0 Then
  Begin
    SetErr(PMERR_INVALID_HMQ);
    WinDestroyMsgQueue := 0;
    Exit;
  End;
  For I := 2 To MaxWin - 1 Do
    If (WUse[I] <> 0) And (WHmq[I] = Q) And (WPid[I] = QPid[Q]) And (WPar[I] <= 1) Then DestroyIdx(I);
  For I := 0 To MaxTimer - 1 Do
    If TmQ[I] = Q Then TmUse[I] := 0;
  If QMou[Q] <> 0 Then Dummy := MouClose(QMou[Q]);
  MemFree(QBuf[Q]);
  QPid[Q] := 0;
  WinDestroyMsgQueue := 1;
End;

{ Poster dans une file }
Function QPut(Q, H, Msg, Mp1, Mp2 : LongInt) : Boolean;
Var A : LongInt;
Begin
  QPut := False;
  If (Q < 0) Or (Q >= MaxQ) Then Exit;
  If QPid[Q] = 0 Then Exit;
  If QCount[Q] >= QSize[Q] Then
  Begin
    SetErr(PMERR_QUEUE_FULL);
    Exit;
  End;
  A := QBuf[Q] + ((QHead[Q] + QCount[Q]) Mod QSize[Q]) * 32;
  WrL(A, H); WrL(A + 4, Msg); WrL(A + 8, Mp1); WrL(A + 12, Mp2);
  WrL(A + 16, KGetTickCount); WrL(A + 20, MouseX); WrL(A + 24, MouseY); WrL(A + 28, 0);
  Inc(QCount[Q]);
  If (Msg = WM_CHAR) Then QStat[Q] := QStat[Q] Or 1
  Else If (Msg >= WM_MOUSEMOVE) And (Msg <= WM_BUTTON3DBLCLK) Then
  Begin
    If Msg = WM_MOUSEMOVE Then QStat[Q] := QStat[Q] Or 4 Else QStat[Q] := QStat[Q] Or 2;
  End
  Else QStat[Q] := QStat[Q] Or $20;
  QPut := True;
End;

Function PostM(Hwnd, Msg, Mp1, Mp2 : LongInt) : Boolean;
Var I : LongInt;
Begin
  I := WIdx(Hwnd);
  If I < 0 Then PostM := False
  Else PostM := QPut(WHmq[I], HwOf(I), Msg, Mp1, Mp2);
End;

{ Le message correspond-il au filtre ? }
Function Matches(H, Msg, HF, First, Last : LongInt) : Boolean;
Var Ok : Boolean; I, F : LongInt;
Begin
  Ok := True;
  If HF <> 0 Then
  Begin
    I := WIdx(H); F := WIdx(HF);
    Ok := (I >= 0) And (F >= 0) And ((I = F) Or IsChildOf(I, F));
  End;
  If Ok And ((First <> 0) Or (Last <> 0)) Then
  Begin
    If First <= Last Then Ok := (Msg >= First) And (Msg <= Last)
    Else Ok := (Msg >= First) Or (Msg <= Last);
  End;
  Matches := Ok;
End;

{ Prendre un message de la file (Remove : le retirer) ; P : QMSG }
Function QTake(Q, HF, First, Last : LongInt; Remove : Boolean; P : LongInt) : Boolean;
Var K, A, B, J : LongInt; Found : Boolean;
Begin
  Found := False;
  K := 0;
  While (Not Found) And (K < QCount[Q]) Do
  Begin
    A := QBuf[Q] + ((QHead[Q] + K) Mod QSize[Q]) * 32;
    If Matches(RdL(A), RdL(A + 4), HF, First, Last) Then
    Begin
      Found := True;
      MemMove(A, P, 32);
      If Remove Then
      Begin
        For J := K To QCount[Q] - 2 Do
        Begin
          A := QBuf[Q] + ((QHead[Q] + J) Mod QSize[Q]) * 32;
          B := QBuf[Q] + ((QHead[Q] + J + 1) Mod QSize[Q]) * 32;
          MemMove(B, A, 32);
        End;
        Dec(QCount[Q]);
      End;
    End
    Else Inc(K);
  End;
  QTake := Found;
End;

{ --- crochets --- }
Function HookCount(Typ, Q : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To MaxHook - 1 Do
    If (HkUse[K] <> 0) And (HkType[K] = Typ) And ((HkQ[K] = -1) Or (HkQ[K] = Q)) Then Inc(N);
  HookCount := N;
End;

Procedure CallHooks3(Typ, A1, A2, A3 : LongInt);
Var K : LongInt;
Begin
  For K := MaxHook - 1 DownTo 0 Do
    If (HkUse[K] <> 0) And (HkType[K] = Typ) And ((HkQ[K] = -1) Or (HkQ[K] = CurQ)) And
       ((HkUse[K] = MyPid) Or Not IsPasProc(HkProc[K])) Then
    Begin
      If A1 = 0 Then A1 := $00010001 + MaxI(CurHab, 0);
      Dummy := Call3(HkProc[K], A1, A2, A3);
    End;
End;

{ un crochet BOOL a-t-il rendu TRUE ? }
Function HookBool3(Typ, A1, A2, A3 : LongInt) : Boolean;
Var K : LongInt; R : Boolean;
Begin
  R := False;
  For K := MaxHook - 1 DownTo 0 Do
    If (Not R) And (HkUse[K] <> 0) And (HkType[K] = Typ) And ((HkQ[K] = -1) Or (HkQ[K] = CurQ)) And
       ((HkUse[K] = MyPid) Or Not IsPasProc(HkProc[K])) Then
      If Call3(HkProc[K], A1, A2, A3) <> 0 Then R := True;
  HookBool3 := R;
End;

{ WinSetHook(hab, hmq, iHook, pfnHook, hmod) : hmq 0 crochet du systeme,
  HMQ_CURRENT 1 file courante ; BOOL }
Function WinSetHook(Hab, Hmq, Typ, Pfn, Hmod : LongInt) : LongInt;
Var K, F, Q : LongInt;
Begin
  WinSetHook := 0;
  If (Pfn = 0) Or (Typ < 0) Or (Typ > 31) Then
  Begin
    SetErr(PMERR_INVALID_PARAMETERS);
    Exit;
  End;
  If Hmq = 0 Then Q := -1 Else Q := QIdx(Hmq);
  If (Hmq <> 0) And (Q < 0) Then
  Begin
    SetErr(PMERR_INVALID_HMQ);
    Exit;
  End;
  F := -1;
  For K := MaxHook - 1 DownTo 0 Do
    If (HkUse[K] = 0) Or Not Alive(HkUse[K]) Then F := K;
  If F < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    Exit;
  End;
  HkUse[F] := MyPid; HkType[F] := Typ; HkProc[F] := Pfn; HkQ[F] := Q; HkMod[F] := Hmod;
  WinSetHook := 1;
End;

Function WinReleaseHook(Hab, Hmq, Typ, Pfn, Hmod : LongInt) : LongInt;
Var K, Q, R : LongInt;
Begin
  R := 0;
  If Hmq = 0 Then Q := -1 Else Q := QIdx(Hmq);
  For K := 0 To MaxHook - 1 Do
    If (R = 0) And (HkUse[K] <> 0) And (HkType[K] = Typ) And (HkProc[K] = Pfn) And (HkQ[K] = Q) Then
    Begin
      HkUse[K] := 0;
      R := 1;
    End;
  WinReleaseHook := R;
End;

{ FarCallHook(pfnHook, a1, a2, a3) : appeler une procedure de crochet }
Function FarCallHook(Pfn, A1, A2, A3 : LongInt) : LongInt;
Begin
  FarCallHook := Call3(Pfn, A1, A2, A3);
End;

{ WinCallMsgFilter(hab, pqmsg, msgf) : crochets HK_MSGFILTER ; BOOL }
Function WinCallMsgFilter(Hab, P, Msgf : LongInt) : LongInt;
Begin
  If HookBool3(2, Hab, P, Msgf) Then WinCallMsgFilter := 1 Else WinCallMsgFilter := 0;
End;

{ WinCallHelpHook(hab, usMode, idTopic, idSubTopic, prcPosition) : BOOL }
Function WinCallHelpHook(Hab, Mode, Topic, Sub, PRc : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := 0;
  For K := MaxHook - 1 DownTo 0 Do
    If (R = 0) And (HkUse[K] <> 0) And (HkType[K] = 5) Then
      If Call5(HkProc[K], Hab, Mode, Topic, Sub, PRc) <> 0 Then R := 1;
  WinCallHelpHook := R;
End;

{ --- envoi --- }
Function SysProcI(H, Msg, Mp1, Mp2 : LongInt) : LongInt; Forward;
Function DefWP(H, Msg, Mp1, Mp2 : LongInt) : LongInt; Forward;
Function DefDlgI(H, Msg, Mp1, Mp2 : LongInt) : LongInt; Forward;

{ procedure de la fenetre (celles de PMWIN sont appelees directement) }
Function CallProcOf(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := WProc[I];
  If (P = 0) Or (IsPasProc(P) And (WPid[I] <> MyPid)) Then CallProcOf := 0
  Else If P = SysProc Then CallProcOf := SysProcI(HwOf(I), Msg, Mp1, Mp2)
  Else If P = DefProcAddr Then CallProcOf := DefWP(HwOf(I), Msg, Mp1, Mp2)
  Else If P = DefDlgAddr Then CallProcOf := DefDlgI(HwOf(I), Msg, Mp1, Mp2)
  Else CallProcOf := Call4(P, HwOf(I), Msg, Mp1, Mp2);
End;

Function SendM(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I, Smh : LongInt;
Begin
  I := WIdx(Hwnd);
  If I < 0 Then
  Begin
    SendM := 0;
    Exit;
  End;
  If HookCount(0, CurQ) > 0 Then
  Begin
    Smh := MemAlloc(16);
    WrL(Smh, Mp2); WrL(Smh + 4, Mp1); WrL(Smh + 8, Msg); WrL(Smh + 12, HwOf(I));
    CallHooks3(0, 0, Smh, 0);
    MemFree(Smh);
  End;
  Inc(InSend);
  SendM := CallProcOf(I, Msg, Mp1, Mp2);
  Dec(InSend);
End;

Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  If WIdx(H) < 0 Then SetErr(PMERR_INVALID_HWND);
  WinSendMsg := SendM(H, Msg, Mp1, Mp2);
End;

{ WinPostMsg(hwnd, msg, mp1, mp2) : hwnd 0 : file courante ; BOOL }
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  WinPostMsg := 0;
  If H = 0 Then
  Begin
    If QPut(CurQ, 0, Msg, Mp1, Mp2) Then WinPostMsg := 1;
  End
  Else If WIdx(H) < 0 Then SetErr(PMERR_INVALID_HWND)
  Else If PostM(H, Msg, Mp1, Mp2) Then WinPostMsg := 1;
End;

Function WinPostQueueMsg(Hmq, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := QIdx(Hmq);
  If Q < 0 Then
  Begin
    SetErr(PMERR_INVALID_HMQ);
    WinPostQueueMsg := 0;
  End
  Else If QPut(Q, 0, Msg, Mp1, Mp2) Then WinPostQueueMsg := 1
  Else WinPostQueueMsg := 0;
End;

{ WinSendQueueMsg(hmq, msg, mp1, mp2) : procedure de la file (WinSetQueueProc) }
Function WinSendQueueMsg(Hmq, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := QIdx(Hmq);
  If (Q < 0) Or (QProc[Q] = 0) Then WinSendQueueMsg := 0
  Else WinSendQueueMsg := Call4(QProc[Q], Hmq, Msg, Mp1, Mp2);
End;

Function WinSetQueueProc(Hmq, Pfn : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := QIdx(Hmq);
  If Q < 0 Then WinSetQueueProc := 0
  Else
  Begin
    WinSetQueueProc := QProc[Q];
    QProc[Q] := Pfn;
  End;
End;

{ WinDefQueueProc(hmq, msg, mp1, mp2) }
Function WinDefQueueProc(Hmq, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  WinDefQueueProc := 0;
End;

{ WinBroadcastMsg(hwndParent, msg, mp1, mp2, rgf) : BMSG_POST 0,
  BMSG_SEND 1, BMSG_POSTQUEUE 2, BMSG_DESCENDANTS 4, BMSG_FRAMEONLY 8 }
Function WinBroadcastMsg(HPar, Msg, Mp1, Mp2, Rgf : LongInt) : LongInt;
Var P, I, Q : LongInt;
Begin
  WinBroadcastMsg := 0;
  If (Rgf And 2) <> 0 Then
  Begin
    For Q := 0 To MaxQ - 1 Do
      If QPid[Q] <> 0 Then Dummy := LongInt(QPut(Q, 0, Msg, Mp1, Mp2));
    WinBroadcastMsg := 1;
    Exit;
  End;
  P := WChk(HPar);
  If P < 0 Then Exit;
  For I := 2 To MaxWin - 1 Do
    If (WUse[I] <> 0) And ((WPar[I] = P) Or (((Rgf And 4) <> 0) And IsChildOf(I, P))) And
       (((Rgf And 8) = 0) Or (KindOf(I) = CK_FRAME)) Then
    Begin
      If (Rgf And 1) <> 0 Then Dummy := SendM(HwOf(I), Msg, Mp1, Mp2)
      Else Dummy := LongInt(PostM(HwOf(I), Msg, Mp1, Mp2));
    End;
  WinBroadcastMsg := 1;
End;

Function WinInSendMsg(Hab : LongInt) : LongInt;
Begin
  WinInSendMsg := 0;
End;

{ --- focus et activation --- }
Procedure Activate(F : LongInt);
Var Old : LongInt;
Begin
  If (F < 2) Or (WUse[F] = 0) Then Exit;
  Old := ActiveWin;
  If Old = F Then Exit;
  ActiveWin := F;
  If (Old > 1) And (WUse[Old] <> 0) Then
  Begin
    Dummy := SendM(HwOf(Old), WM_ACTIVATE, 0, HwOf(F));
    InvalWin(Old);
  End;
  ZTop(F);
  Dummy := SendM(HwOf(F), WM_ACTIVATE, 1, HwOf(Old));
  InvalWin(F);
End;

Procedure FocusTo(I : LongInt);
Var Old, F : LongInt;
Begin
  If (I > 1) And (WUse[I] = 0) Then I := 0;
  Old := FocusWin;
  If Old = I Then Exit;
  If I > 1 Then
  Begin
    F := TopFrame(I);
    If (F > 1) And (F <> ActiveWin) Then Activate(F);
    If (KindOf(F) = CK_FRAME) And (WData[F] <> 0) Then WrL(WData[F] + $18, HwOf(I));
  End;
  FocusWin := I;
  If (Old > 1) And (WUse[Old] <> 0) Then Dummy := SendM(HwOf(Old), WM_SETFOCUS, HwOf(I), 0);
  If I > 1 Then Dummy := SendM(HwOf(I), WM_SETFOCUS, HwOf(Old), 1);
End;

Function WinSetFocus(HDesk, H : LongInt) : LongInt;
Var I : LongInt;
Begin
  If H = 0 Then
  Begin
    FocusTo(0);
    WinSetFocus := 1;
    Exit;
  End;
  I := WChk(H);
  If I < 0 Then WinSetFocus := 0
  Else
  Begin
    If I = 0 Then I := 0;
    FocusTo(I);
    WinSetFocus := 1;
  End;
End;

{ WinFocusChange(hwndDesktop, hwndNewFocus, fl) : FC_NOSETFOCUS 1,
  FC_NOLOSEFOCUS 2, FC_NOSETACTIVE 10h ... ; BOOL }
Function WinFocusChange(HDesk, H, Fl : LongInt) : LongInt;
Var I, Old : LongInt;
Begin
  I := 0;
  If H <> 0 Then I := WChk(H);
  If I < 0 Then
  Begin
    WinFocusChange := 0;
    Exit;
  End;
  Old := FocusWin;
  If ((Fl And $10) = 0) And (I > 1) Then Activate(TopFrame(I));
  FocusWin := I;
  If ((Fl And 2) = 0) And (Old > 1) And (WUse[Old] <> 0) Then Dummy := SendM(HwOf(Old), WM_SETFOCUS, HwOf(I), 0);
  If ((Fl And 1) = 0) And (I > 1) Then Dummy := SendM(HwOf(I), WM_SETFOCUS, HwOf(Old), 1);
  Dummy := SendM(HwOf(I), WM_FOCUSCHANGE, HwOf(Old), Fl);
  WinFocusChange := 1;
End;

Function WinQueryFocus(HDesk : LongInt) : LongInt;
Begin
  If (FocusWin > 1) And (WUse[FocusWin] <> 0) Then WinQueryFocus := HwOf(FocusWin) Else WinQueryFocus := 0;
End;

{ WinSetActiveWindow(hwndDesktop, hwnd) : cadre actif, focus a sa
  fenetre memorisee (ou au client) ; BOOL }
Function WinSetActiveWindow(HDesk, H : LongInt) : LongInt;
Var I, F, S, C : LongInt;
Begin
  WinSetActiveWindow := 0;
  I := WChk(H);
  If I < 2 Then Exit;
  F := TopFrame(I);
  Activate(F);
  S := -1;
  If (KindOf(F) = CK_FRAME) And (WData[F] <> 0) Then S := WIdx(RdL(WData[F] + $18));
  If (S < 2) Or Not ((S = F) Or IsChildOf(S, F)) Then
  Begin
    C := WIdx(WinWindowFromID(HwOf(F), FID_CLIENT));
    If C > 1 Then S := C Else S := F;
  End;
  FocusTo(S);
  WinSetActiveWindow := 1;
End;

Function WinQueryActiveWindow(HPar : LongInt) : LongInt;
Begin
  If (ActiveWin > 1) And (WUse[ActiveWin] <> 0) Then WinQueryActiveWindow := HwOf(ActiveWin)
  Else WinQueryActiveWindow := 0;
End;

Function WinSetSysModalWindow(HDesk, H : LongInt) : LongInt;
Var I : LongInt;
Begin
  If H = 0 Then
  Begin
    SysModalWin := 0;
    WinSetSysModalWindow := 1;
    Exit;
  End;
  I := WChk(H);
  If I < 2 Then WinSetSysModalWindow := 0
  Else
  Begin
    SysModalWin := I;
    Activate(TopFrame(I));
    WinSetSysModalWindow := 1;
  End;
End;

Function WinQuerySysModalWindow(HDesk : LongInt) : LongInt;
Begin
  If (SysModalWin > 1) And (WUse[SysModalWin] <> 0) Then WinQuerySysModalWindow := HwOf(SysModalWin)
  Else WinQuerySysModalWindow := 0;
End;

Function WinIsThreadActive(Hab : LongInt) : LongInt;
Begin
  If (ActiveWin > 1) And (WUse[ActiveWin] <> 0) And (WPid[ActiveWin] = MyPid) Then WinIsThreadActive := 1
  Else WinIsThreadActive := 0;
End;

Function WinSetCapture(HDesk, H : LongInt) : LongInt;
Var I : LongInt;
Begin
  If H = 0 Then
  Begin
    CaptureWin := 0;
    WinSetCapture := 1;
    Exit;
  End;
  I := WChk(H);
  If I < 2 Then WinSetCapture := 0
  Else
  Begin
    CaptureWin := I;
    WinSetCapture := 1;
  End;
End;

Function WinQueryCapture(HDesk : LongInt) : LongInt;
Begin
  If (CaptureWin > 1) And (WUse[CaptureWin] <> 0) Then WinQueryCapture := HwOf(CaptureWin) Else WinQueryCapture := 0;
End;

{ --- minuteries --- }
Procedure StopTimersOf(I : LongInt);
Var K : LongInt;
Begin
  For K := 0 To MaxTimer - 1 Do
    If (TmUse[K] <> 0) And (TmWin[K] = I) Then TmUse[K] := 0;
End;

{ WinStartTimer(hab, hwnd, idTimer, dtTimeout) : identificateur (0 :
  erreur) ; hwnd 0 : nouvel identificateur, WM_TIMER poste a la file }
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt;
Var I, K, F, N : LongInt; Used : Boolean;
Begin
  WinStartTimer := 0;
  If H = 0 Then I := -1 Else I := WChk(H);
  If (H <> 0) And (I < 0) Then Exit;
  F := -1;
  For K := MaxTimer - 1 DownTo 0 Do
    If (TmUse[K] <> 0) And (I >= 0) And (TmWin[K] = I) And (TmId[K] = Id) Then F := K;
  If F < 0 Then
    For K := MaxTimer - 1 DownTo 0 Do
      If (TmUse[K] = 0) Or Not Alive(TmUse[K]) Then F := K;
  If F < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    Exit;
  End;
  If I < 0 Then
  Begin
    { identificateur libre pour la file }
    N := 1;
    Repeat
      Used := False;
      For K := 0 To MaxTimer - 1 Do
        If (TmUse[K] <> 0) And (TmWin[K] < 0) And (TmId[K] = N) Then Used := True;
      If Used Then Inc(N);
    Until Not Used;
    Id := N;
  End;
  If Dt < 1 Then Dt := 1;
  TmUse[F] := MyPid; TmWin[F] := I; TmId[F] := Id; TmIntv[F] := Dt;
  If I >= 0 Then TmQ[F] := WHmq[I] Else TmQ[F] := CurQ;
  TmNext[F] := KGetTickCount + Dt;
  WinStartTimer := Id;
End;

Function WinStopTimer(Hab, H, Id : LongInt) : LongInt;
Var I, K, R : LongInt;
Begin
  R := 0;
  If H = 0 Then I := -1 Else I := WIdx(H);
  For K := 0 To MaxTimer - 1 Do
    If (TmUse[K] <> 0) And (TmWin[K] = I) And (TmId[K] = Id) And ((I >= 0) Or (TmQ[K] = CurQ)) Then
    Begin
      TmUse[K] := 0;
      R := 1;
    End;
  WinStopTimer := R;
End;

Function StartTimer(Hab, H, Id, Dt : LongInt) : LongInt;
Begin
  StartTimer := WinStartTimer(Hab, H, Id, Dt);
End;

{ DestroyTimers(hab) : arreter les minuteries du processus }
Function DestroyTimers(Hab : LongInt) : LongInt;
Var K : LongInt;
Begin
  For K := 0 To MaxTimer - 1 Do
    If TmUse[K] = MyPid Then TmUse[K] := 0;
  DestroyTimers := 1;
End;

Function WinGetCurrentTime(Hab : LongInt) : LongInt;
Begin
  WinGetCurrentTime := KGetTickCount;
End;

{ --- accelerateurs (ACCELTABLE : cAccel, codepage, {fs, key, cmd}) --- }
Function AcIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $41430001;
  If (I < 0) Or (I >= MaxAccel) Then I := -1
  Else If AcUse[I] = 0 Then I := -1;
  AcIdx := I;
End;

Function NewAccel(P : LongInt) : LongInt;
Var I, F, N : LongInt;
Begin
  NewAccel := 0;
  If P = 0 Then Exit;
  N := RdW(P);
  F := -1;
  For I := MaxAccel - 1 DownTo 0 Do
    If (AcUse[I] = 0) Or Not Alive(AcPid[I]) Then F := I;
  If F < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    Exit;
  End;
  If AcUse[F] <> 0 Then MemFree(AcData[F]);
  AcData[F] := MemAlloc(4 + N * 6);
  MemMove(P, AcData[F], 4 + N * 6);
  AcUse[F] := 1; AcPid[F] := MyPid;
  NewAccel := $41430001 + F;
End;

Function WinCreateAccelTable(Hab, P : LongInt) : LongInt;
Begin
  WinCreateAccelTable := NewAccel(P);
End;

Function WinLoadAccelTable(Hab, Hmod, Id : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := GetRes(Hmod, 8, Id);
  If P = 0 Then
  Begin
    SetErr(PMERR_RESOURCE_NOT_FOUND);
    WinLoadAccelTable := 0;
  End
  Else WinLoadAccelTable := NewAccel(P);
End;

Function WinDestroyAccelTable(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := AcIdx(H);
  If I < 0 Then
  Begin
    SetErr(PMERR_INVALID_HACCEL);
    WinDestroyAccelTable := 0;
  End
  Else
  Begin
    MemFree(AcData[I]);
    AcUse[I] := 0;
    WinDestroyAccelTable := 1;
  End;
End;

{ WinCopyAccelTable(haccel, pAccelTable, cbCopyMax) : octets (p nul :
  taille) }
Function WinCopyAccelTable(H, P, Cb : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  I := AcIdx(H);
  If I < 0 Then
  Begin
    SetErr(PMERR_INVALID_HACCEL);
    WinCopyAccelTable := 0;
    Exit;
  End;
  N := 4 + RdW(AcData[I]) * 6;
  If P = 0 Then WinCopyAccelTable := N
  Else
  Begin
    N := MinI(N, Cb);
    MemMove(AcData[I], P, N);
    WinCopyAccelTable := N;
  End;
End;

{ WinSetAccelTable(hab, haccel, hwndFrame) : hwndFrame 0 : file }
Function WinSetAccelTable(Hab, H, HFrame : LongInt) : LongInt;
Var I, Q : LongInt;
Begin
  WinSetAccelTable := 0;
  If (H <> 0) And (AcIdx(H) < 0) Then
  Begin
    SetErr(PMERR_INVALID_HACCEL);
    Exit;
  End;
  If HFrame = 0 Then
  Begin
    Q := CurQ;
    If Q < 0 Then Exit;
    QAccel[Q] := H;
  End
  Else
  Begin
    I := WChk(HFrame);
    If I < 2 Then Exit;
    WS5[I] := H;
  End;
  WinSetAccelTable := 1;
End;

Function WinQueryAccelTable(Hab, HFrame : LongInt) : LongInt;
Var I, Q : LongInt;
Begin
  WinQueryAccelTable := 0;
  If HFrame = 0 Then
  Begin
    Q := CurQ;
    If Q >= 0 Then WinQueryAccelTable := QAccel[Q];
  End
  Else
  Begin
    I := WIdx(HFrame);
    If I > 1 Then WinQueryAccelTable := WS5[I];
  End;
End;

{ WinQueryAccelTableValue(haccel, iAccel, pAccel), WinSetAccelTableValue :
  un ACCEL (fs, key, cmd) de la table ; BOOL }
Function WinQueryAccelTableValue(H, Ix, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := AcIdx(H);
  If (I < 0) Or (Ix < 0) Or (Ix >= RdW(AcData[I])) Or (P = 0) Then WinQueryAccelTableValue := 0
  Else
  Begin
    MemMove(AcData[I] + 4 + Ix * 6, P, 6);
    WinQueryAccelTableValue := 1;
  End;
End;

Function WinSetAccelTableValue(H, Ix, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := AcIdx(H);
  If (I < 0) Or (Ix < 0) Or (Ix >= RdW(AcData[I])) Or (P = 0) Then WinSetAccelTableValue := 0
  Else
  Begin
    MemMove(P, AcData[I] + 4 + Ix * 6, 6);
    WinSetAccelTableValue := 1;
  End;
End;

{ Le message WM_CHAR (QMSG en P) correspond-il a la table (adresse T) ?
  rend la commande transformee }
Function AccelMatch(T, P, H : LongInt) : Boolean;
Var K, N, Fs, Key, Cmd, Mf, Ch, Vk, Sc, Want, Have : LongInt; Ok, R : Boolean;
Begin
  R := False;
  Mf := RdW(P + 8);
  If (RdL(P + 4) <> WM_CHAR) Or ((Mf And KC_KEYUP) <> 0) Then
  Begin
    AccelMatch := False;
    Exit;
  End;
  Ch := RdW(P + 12); Vk := RdW(P + 14); Sc := RdB(P + 11);
  Have := Mf And (KC_SHIFT Or KC_CTRL Or KC_ALT);
  N := RdW(T);
  For K := 0 To N - 1 Do
    If Not R Then
    Begin
      Fs := RdW(T + 4 + K * 6); Key := RdW(T + 6 + K * 6); Cmd := RdW(T + 8 + K * 6);
      Want := 0;
      If (Fs And AF_SHIFT) <> 0 Then Want := Want Or KC_SHIFT;
      If (Fs And AF_CONTROL) <> 0 Then Want := Want Or KC_CTRL;
      If (Fs And AF_ALT) <> 0 Then Want := Want Or KC_ALT;
      Ok := False;
      If (Fs And AF_VIRTUALKEY) <> 0 Then Ok := ((Mf And KC_VIRTUALKEY) <> 0) And (Vk = Key)
      Else If (Fs And AF_SCANCODE) <> 0 Then Ok := Sc = Key
      Else If (Mf And KC_CHAR) <> 0 Then
      Begin
        Ok := Ch = Key;
        If (Not Ok) And ((Want And (KC_CTRL Or KC_ALT)) <> 0) Then Ok := UpCase(Chr(Ch And 255)) = UpCase(Chr(Key And 255));
        If ((Fs And AF_SHIFT) = 0) And ((Want And (KC_CTRL Or KC_ALT)) = 0) Then Have := Have And Not KC_SHIFT;
      End;
      If Ok And (Want = (Have And (KC_SHIFT Or KC_CTRL Or KC_ALT))) Then
      Begin
        R := True;
        WrL(P, H);
        If (Fs And AF_SYSCOMMAND) <> 0 Then WrL(P + 4, WM_SYSCOMMAND)
        Else If (Fs And AF_HELP) <> 0 Then WrL(P + 4, WM_HELP)
        Else WrL(P + 4, WM_COMMAND);
        WrL(P + 8, Cmd);
        WrL(P + 12, Mk2(CMDSRC_ACCELERATOR, 1));
      End;
    End;
  AccelMatch := R;
End;

{ WinTranslateAccel(hab, hwnd, haccel, pqmsg) : BOOL }
Function WinTranslateAccel(Hab, H, HAcc, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := AcIdx(HAcc);
  If (I < 0) Or (P = 0) Then WinTranslateAccel := 0
  Else If AccelMatch(AcData[I], P, H) Then WinTranslateAccel := 1
  Else WinTranslateAccel := 0;
End;

{ --- clavier --- }
Function ScanVk(Sc, Ch : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := 0;
  Case Sc Of
    $01 : V := VK_ESC;
    $0E : V := VK_BACKSPACE;
    $0F : V := VK_TAB;
    $1C : V := VK_NEWLINE;
    $39 : V := VK_SPACE;
    $3A : V := VK_CAPSLOCK;
    $45 : V := VK_NUMLOCK;
    $46 : V := VK_SCRLLOCK;
    $47 : V := VK_HOME;
    $48 : V := VK_UP;
    $49 : V := VK_PAGEUP;
    $4B : V := VK_LEFT;
    $4D : V := VK_RIGHT;
    $4F : V := VK_END;
    $50 : V := VK_DOWN;
    $51 : V := VK_PAGEDOWN;
    $52 : V := VK_INSERT;
    $53 : V := VK_DELETE;
    $57, $85 : V := VK_F1 + 10;
    $58, $86 : V := VK_F1 + 11;
  End;
  If (Sc >= $3B) And (Sc <= $44) Then V := VK_F1 + Sc - $3B;
  If (Sc >= $54) And (Sc <= $5D) Then V := VK_F1 + Sc - $54;
  If (Sc >= $5E) And (Sc <= $67) Then V := VK_F1 + Sc - $5E;
  If (Sc >= $68) And (Sc <= $71) Then V := VK_F1 + Sc - $68;
  If (Sc = $87) Or (Sc = $89) Or (Sc = $8B) Then V := VK_F1 + 10;
  If (Sc = $88) Or (Sc = $8A) Or (Sc = $8C) Then V := VK_F1 + 11;
  If (Sc = $73) Then V := VK_LEFT;
  If (Sc = $74) Then V := VK_RIGHT;
  If (Sc = $77) Then V := VK_HOME;
  If (Sc = $75) Then V := VK_END;
  If (Sc = $84) Then V := VK_PAGEUP;
  If (Sc = $76) Then V := VK_PAGEDOWN;
  If (Ch = $E0) And (Sc = $1C) Then V := VK_ENTER;
  ScanVk := V;
End;

{ lettre d'une touche (Alt+lettre : caractere nul) }
Function ScanChar(Sc : LongInt) : LongInt;
Var S : String; R : LongInt;
Begin
  R := 0;
  S := 'qwertyuiop';
  If (Sc >= $10) And (Sc <= $19) Then R := Ord(S[Sc - $10 + 1]);
  S := 'asdfghjkl';
  If (Sc >= $1E) And (Sc <= $26) Then R := Ord(S[Sc - $1E + 1]);
  S := 'zxcvbnm';
  If (Sc >= $2C) And (Sc <= $32) Then R := Ord(S[Sc - $2C + 1]);
  S := '1234567890';
  If (Sc >= $02) And (Sc <= $0B) Then R := Ord(S[Sc - $02 + 1]);
  If (Sc >= $78) And (Sc <= $81) Then R := Ord(S[Sc - $78 + 1]);
  ScanChar := R;
End;

{ Accelerateurs du systeme : Alt+F4 fermer, F10 menu, Alt+F5 restaurer,
  Alt+F9 reduire, Alt+F10 agrandir }
Function SysAccel(P, F : LongInt) : Boolean;
Var Mf, Vk, Cmd : LongInt;
Begin
  SysAccel := False;
  Mf := RdW(P + 8); Vk := RdW(P + 14);
  If (Mf And KC_VIRTUALKEY) = 0 Then Exit;
  Cmd := 0;
  If (Mf And KC_ALT) <> 0 Then
  Begin
    If Vk = VK_F1 + 3 Then Cmd := SC_CLOSE
    Else If Vk = VK_F1 + 4 Then Cmd := SC_RESTORE
    Else If Vk = VK_F1 + 8 Then Cmd := SC_MINIMIZE
    Else If Vk = VK_F1 + 9 Then Cmd := SC_MAXIMIZE;
  End
  Else If (Vk = VK_F1 + 9) And ((Mf And (KC_SHIFT Or KC_CTRL)) = 0) Then Cmd := SC_APPMENU;
  If (Cmd <> 0) And (F > 1) Then
  Begin
    WrL(P, HwOf(F));
    WrL(P + 4, WM_SYSCOMMAND);
    WrL(P + 8, Cmd);
    WrL(P + 12, Mk2(CMDSRC_ACCELERATOR, 1));
    SysAccel := True;
  End;
End;

{ Remettre la touche a la fenetre T (file Q du processus qui l'a lue,
  qui est aussi celui de T) }
Procedure KeyDeliver(Q, T, Fs, Ch, Vk, Sc : LongInt);
Var F : LongInt;
Begin
  If T >= 0 Then
  Begin
    WrL(LongInt(@GMsg), HwOf(T)); WrL(LongInt(@GMsg) + 4, WM_CHAR);
    WrL(LongInt(@GMsg) + 8, Fs Or (1 Shl 16) Or ((Sc And 255) Shl 24));
    WrL(LongInt(@GMsg) + 12, Mk2(Ch, Vk));
    WrL(LongInt(@GMsg) + 16, KGetTickCount); WrL(LongInt(@GMsg) + 20, MouseX); WrL(LongInt(@GMsg) + 24, MouseY);
    If Not HookBool3(1, QHab[Q], LongInt(@GMsg), 1) Then
    Begin
      CallHooks3(3, QHab[Q], LongInt(@GMsg), 0);    { HK_JOURNALRECORD }
      F := TopFrame(T);
      If (F > 1) And (WS5[F] <> 0) And (AcIdx(WS5[F]) >= 0) Then Dummy := LongInt(AccelMatch(AcData[AcIdx(WS5[F])], LongInt(@GMsg), HwOf(F)));
      If (RdL(LongInt(@GMsg) + 4) = WM_CHAR) And (QAccel[Q] <> 0) And (AcIdx(QAccel[Q]) >= 0) And (F > 1) Then
        Dummy := LongInt(AccelMatch(AcData[AcIdx(QAccel[Q])], LongInt(@GMsg), HwOf(F)));
      If RdL(LongInt(@GMsg) + 4) = WM_CHAR Then Dummy := LongInt(SysAccel(LongInt(@GMsg), F));
      Dummy := LongInt(QPut(Q, RdL(LongInt(@GMsg)), RdL(LongInt(@GMsg) + 4), RdL(LongInt(@GMsg) + 8),
                            RdL(LongInt(@GMsg) + 12)));
    End;
  End;
End;

{ touche pour la file Q d'un autre processus de PM }
Procedure KeyPend(Q, T, Fs, Ch, Vk, Sc : LongInt);
Var K : LongInt;
Begin
  If KpN[Q] >= KeyPendMax Then Exit;
  K := Q * KeyPendMax + KpN[Q];
  KpT[K] := T; KpFs[K] := Fs; KpCh[K] := Ch; KpVk[K] := Vk; KpSc[K] := Sc;
  Inc(KpN[Q]);
End;

Procedure KeyInput(Q : LongInt);
Var Ki : Array[0..15] Of Byte; Ch, Sc, St, Fs, Vk, T, N, K : LongInt;
Begin
  { touches lues par un autre processus pour une fenetre de celui-ci }
  K := 0;
  While (KpN[Q] > 0) And (K < KeyPendMax) Do
  Begin
    T := KpT[Q * KeyPendMax];
    Fs := KpFs[Q * KeyPendMax]; Ch := KpCh[Q * KeyPendMax]; Vk := KpVk[Q * KeyPendMax]; Sc := KpSc[Q * KeyPendMax];
    For N := 1 To KpN[Q] - 1 Do
    Begin
      KpT[Q * KeyPendMax + N - 1] := KpT[Q * KeyPendMax + N]; KpFs[Q * KeyPendMax + N - 1] := KpFs[Q * KeyPendMax + N];
      KpCh[Q * KeyPendMax + N - 1] := KpCh[Q * KeyPendMax + N]; KpVk[Q * KeyPendMax + N - 1] := KpVk[Q * KeyPendMax + N];
      KpSc[Q * KeyPendMax + N - 1] := KpSc[Q * KeyPendMax + N];
    End;
    Dec(KpN[Q]);
    If (T > 1) And (WUse[T] <> 0) And (WHmq[T] = Q) Then KeyDeliver(Q, T, Fs, Ch, Vk, Sc);
    Inc(K);
  End;
  N := 0;
  While N < 8 Do
  Begin
    Inc(N);
    MemZero(LongInt(@Ki), 16);
    If KbdCharIn(LongInt(@Ki), 1, 0) <> 0 Then Exit;
    If (Ki[2] And $40) = 0 Then Exit;
    Ch := Ki[0]; Sc := Ki[1]; St := RdW(LongInt(@Ki) + 4);
    Fs := KC_SCANCODE;
    Vk := ScanVk(Sc, Ch);
    If (Ch <> 0) And (Ch <> $E0) Then Fs := Fs Or KC_CHAR Else Ch := 0;
    If Vk <> 0 Then
    Begin
      Fs := Fs Or KC_VIRTUALKEY;
      If (Vk = VK_TAB) And ((St And 3) <> 0) Then Vk := VK_BACKTAB;
    End;
    If (St And 3) <> 0 Then Fs := Fs Or KC_SHIFT;
    If (St And 4) <> 0 Then Fs := Fs Or KC_CTRL;
    If (St And 8) <> 0 Then Fs := Fs Or KC_ALT;
    If (Ch = 0) And ((Fs And (KC_ALT Or KC_CTRL)) <> 0) And (ScanChar(Sc) <> 0) Then
    Begin
      Ch := ScanChar(Sc);
      Fs := Fs Or KC_CHAR;
    End;
    If ((St And 4) <> 0) And (ScanChar(Sc) <> 0) Then
    Begin
      Ch := ScanChar(Sc);
      Fs := Fs Or KC_CHAR;
    End;
    { etat des touches }
    If Vk <> 0 Then KeyState[Vk] := KeyState[Vk] Xor 1;
    ScanState[Sc And 255] := ScanState[Sc And 255] Xor 1;
    If (St And 3) <> 0 Then KeyState[VK_SHIFT] := $80 Else KeyState[VK_SHIFT] := 0;
    If (St And 4) <> 0 Then KeyState[VK_CTRL] := $80 Else KeyState[VK_CTRL] := 0;
    If (St And 8) <> 0 Then KeyState[VK_ALT] := $80 Else KeyState[VK_ALT] := 0;
    { destinataire : fenetre du focus, sinon cadre actif }
    T := -1;
    If (FocusWin > 1) And (WUse[FocusWin] <> 0) And (WHmq[FocusWin] >= 0) Then T := FocusWin
    Else If (ActiveWin > 1) And (WUse[ActiveWin] <> 0) And (WHmq[ActiveWin] >= 0) Then T := ActiveWin;
    { fenetre d'un autre processus de PM : la touche lui est remise par
      son propre processus (crochets, accelerateurs, procedures) }
    If (T > 1) And (WHmq[T] <> Q) And (QPid[WHmq[T]] <> 0) Then
    Begin
      KeyPend(WHmq[T], T, Fs, Ch, Vk, Sc);
      Continue;
    End;
    If (T > 1) And (WHmq[T] <> Q) Then T := -1;
    KeyDeliver(Q, T, Fs, Ch, Vk, Sc);
  End;
End;

{ la fenetre ou un de ses parents est-il desactive ? }
Function Disabled(T : LongInt) : Boolean;
Var N : LongInt; R : Boolean;
Begin
  R := False; N := 0;
  While (T > 1) And Not R And (N < 64) Do
  Begin
    If (WStyle[T] And WS_DISABLED) <> 0 Then R := True;
    T := WPar[T];
    Inc(N);
  End;
  Disabled := R;
End;

Procedure MouseMsg(Q, T, Msg, Kc : LongInt);
Begin
  { la fenetre peut appartenir a un autre processus de PM : message pose
    dans sa propre file }
  If (T > 1) And (WUse[T] <> 0) And (WHmq[T] >= 0) And Not Disabled(T) Then
  Begin
    If QPid[WHmq[T]] = 0 Then Exit;
    If (Msg = WM_MOUSEMOVE) And ((WInt0[T] And 1) <> 0) Then Exit;
    Dummy := LongInt(QPut(WHmq[T], HwOf(T), Msg, Mk2(MouseX - AbsX(T), MouseY - AbsY(T)), Mk2(0, Kc)));
  End;
End;

Procedure MouseInput(Q : LongInt);
Var Ev : Array[0..11] Of Byte; Wait, H, Fs, Btn, T, N, Kc, K, Bit, Dn, Up, Dbl, TQ : LongInt;
Begin
  If QMou[Q] = 0 Then
  Begin
    H := 0;
    If MouOpen(0, LongInt(@H)) = 0 Then QMou[Q] := H;
  End;
  H := QMou[Q];
  If H = 0 Then Exit;
  N := 0;
  While N < 16 Do
  Begin
    Inc(N);
    Wait := 0;
    MemZero(LongInt(@Ev), 12);
    If MouReadEventQue(LongInt(@Ev), LongInt(@Wait), H) <> 0 Then Exit;
    If (RdW(LongInt(@Ev)) = 0) And (RdL(LongInt(@Ev) + 2) = 0) Then Exit;
    Fs := RdW(LongInt(@Ev));
    If GMode <> 0 Then
    Begin
      MouseX := MaxI(0, MinI(RdW(LongInt(@Ev) + 8), ScrCX - 1));
      MouseY := MaxI(0, MinI(ScrCY - 1 - RdW(LongInt(@Ev) + 6), ScrCY - 1));
    End
    Else
    Begin
      MouseX := RdW(LongInt(@Ev) + 8) * 8 + 4;
      MouseY := (ScrRows - 1 - RdW(LongInt(@Ev) + 6)) * 16 + 8;
    End;
    Btn := 0;
    If (Fs And $06) <> 0 Then Btn := Btn Or 1;
    If (Fs And $18) <> 0 Then Btn := Btn Or 2;
    If (Fs And $60) <> 0 Then Btn := Btn Or 4;
    If CaptureWin > 1 Then T := CaptureWin Else T := WinAtAbs(0, MouseX, MouseY, True);
    If (SysModalWin > 1) And (T > 1) And (T <> SysModalWin) And Not IsChildOf(T, SysModalWin) Then T := -1;
    { file de la fenetre visee (double clic) }
    TQ := Q;
    If (T > 1) And (WUse[T] <> 0) And (WHmq[T] >= 0) Then TQ := WHmq[T];
    Kc := 0;
    If KeyState[VK_SHIFT] <> 0 Then Kc := Kc Or KC_SHIFT;
    If KeyState[VK_CTRL] <> 0 Then Kc := Kc Or KC_CTRL;
    If KeyState[VK_ALT] <> 0 Then Kc := Kc Or KC_ALT;
    MouseMsg(Q, T, WM_MOUSEMOVE, Kc);
    For K := 0 To 2 Do
    Begin
      Bit := 1 Shl K;
      If K = 0 Then
      Begin
        Dn := WM_BUTTON1DOWN; Up := WM_BUTTON1UP; Dbl := WM_BUTTON1DBLCLK;
      End
      Else If K = 1 Then
      Begin
        Dn := WM_BUTTON2DOWN; Up := WM_BUTTON2UP; Dbl := WM_BUTTON2DBLCLK;
      End
      Else
      Begin
        Dn := WM_BUTTON3DOWN; Up := WM_BUTTON3UP; Dbl := WM_BUTTON3DBLCLK;
      End;
      If ((Btn And Bit) <> 0) And ((MouseBtn And Bit) = 0) Then
      Begin
        If (QDownWin[TQ] = T) And (QLastDown[TQ] = Bit) And (KGetTickCount - QDownTime[TQ] < SysVal[1]) Then
          MouseMsg(Q, T, Dbl, Kc)
        Else MouseMsg(Q, T, Dn, Kc);
        QDownWin[TQ] := T; QLastDown[TQ] := Bit; QDownTime[TQ] := KGetTickCount;
      End;
      If ((Btn And Bit) = 0) And ((MouseBtn And Bit) <> 0) Then
      Begin
        MouseMsg(Q, T, Up, Kc);
        If (T = QDownWin[TQ]) And (T > 1) Then
        Begin
          If K = 0 Then MouseMsg(Q, T, WM_BUTTON1CLICK, Kc)
          Else If K = 1 Then MouseMsg(Q, T, WM_BUTTON2CLICK, Kc)
          Else MouseMsg(Q, T, WM_BUTTON3CLICK, Kc);
        End;
      End;
    End;
    MouseBtn := Btn;
  End;
End;

{ lecture differee : HK_JOURNALPLAYBACK fournit les entrees }
Function PlaybackInput(Q : LongInt) : Boolean;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 0 To MaxHook - 1 Do
    If (R < 0) And (HkUse[K] <> 0) And (HkType[K] = 4) Then R := K;
  PlaybackInput := R >= 0;
  If R < 0 Then Exit;
  MemZero(LongInt(@GMsg), 32);
  Dummy := Call3(HkProc[R], QHab[Q], 0, LongInt(@GMsg));
  If RdL(LongInt(@GMsg) + 4) <> 0 Then
    Dummy := LongInt(QPut(Q, RdL(LongInt(@GMsg)), RdL(LongInt(@GMsg) + 4), RdL(LongInt(@GMsg) + 8), RdL(LongInt(@GMsg) + 12)));
  Dummy := Call3(HkProc[R], QHab[Q], 1, 0);
End;

{ ecran graphique : remettre le curseur et le pointeur }
Procedure GShow(Q : LongInt);
Begin
  If GMode = 0 Then Exit;
  If (GCarWant <> 0) And (GCarOn = 0) And (GCarX1 < GCarX2) And (GCarY1 < GCarY2) Then
  Begin
    GCdX1 := GCarX1; GCdY1 := GCarY1; GCdX2 := GCarX2; GCdY2 := GCarY2;
    If (GPtrOn <> 0) And GHits(GCdX1, GCdY1, GCdX2, GCdY2, GPtrX, ScrCY - GPtrY - 16, GPtrX + 16, ScrCY - GPtrY) Then GPtrHide;
    GXorRaw(GCdX1, GCdY1, GCdX2, GCdY2);
    GCarOn := 1;
  End;
  If (GPtrOn <> 0) And ((GPtrX <> MouseX) Or (GPtrY <> ScrCY - 1 - MouseY)) Then GPtrHide;
  If (GPtrOn = 0) And (PtrLevel >= 0) And (Q >= 0) Then
    If QMou[Q] <> 0 Then GPtrDraw(MouseX, ScrCY - 1 - MouseY);
End;

Procedure PollInput(Q : LongInt);
Begin
  If (QLockIn[Q] <> 0) Or (PhysInput = 0) Then Exit;
  If PlaybackInput(Q) Then Exit;
  KeyInput(Q);
  MouseInput(Q);
End;

{ Message suivant : postes et entrees, WM_PAINT, WM_TIMER ; Wait :
  attendre ; rend faux s'il n'y en a pas }
Function NextMsg(Q, P, HF, First, Last : LongInt; Remove, Wait : Boolean) : Boolean;
Var Got : Boolean; W, K, T : LongInt;
Begin
  Got := False;
  Repeat
    { la session de PM revient au premier plan : ecran graphique redessine }
    If SesEpoch <> PmEpoch Then
    Begin
      PmEpoch := SesEpoch;
      If GMine Then ScreenStart;
    End;
    PollInput(Q);
    GShow(Q);
    Got := QTake(Q, HF, First, Last, Remove, P);
    If Not Got Then
    Begin
      PaintDesktop;
      W := PaintWinOf(Q, -1);
      If (W >= 0) And Matches(HwOf(W), WM_PAINT, HF, First, Last) Then
      Begin
        WrL(P, HwOf(W)); WrL(P + 4, WM_PAINT); WrL(P + 8, 0); WrL(P + 12, 0);
        WrL(P + 16, KGetTickCount); WrL(P + 20, MouseX); WrL(P + 24, MouseY); WrL(P + 28, 0);
        Got := True;
      End;
    End;
    If Not Got Then
    Begin
      T := KGetTickCount;
      For K := 0 To MaxTimer - 1 Do
        If (Not Got) And (TmUse[K] <> 0) And (TmQ[K] = Q) And (T - TmNext[K] >= 0) Then
        Begin
          If (TmWin[K] < 0) Or (WUse[TmWin[K]] <> 0) Then
          Begin
            If TmWin[K] < 0 Then WrL(P, 0) Else WrL(P, HwOf(TmWin[K]));
            WrL(P + 4, WM_TIMER); WrL(P + 8, TmId[K]); WrL(P + 12, 0);
            WrL(P + 16, T); WrL(P + 20, MouseX); WrL(P + 24, MouseY); WrL(P + 28, 0);
            If Matches(RdL(P), WM_TIMER, HF, First, Last) Then
            Begin
              Got := True;
              If Remove Then TmNext[K] := T + TmIntv[K];
            End;
          End
          Else TmUse[K] := 0;
        End;
    End;
    If (Not Got) And Wait Then Dummy := DcSleep(10);
  Until Got Or Not Wait;
  If Got Then
  Begin
    QPosX[Q] := RdL(P + 20); QPosY[Q] := RdL(P + 24); QTime[Q] := RdL(P + 16);
    LastMsgTime := QTime[Q];
  End;
  NextMsg := Got;
End;

{ WinGetMsg(hab, pqmsg, hwndFilter, msgFilterFirst, msgFilterLast) :
  FALSE pour WM_QUIT }
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt;
Var Q : LongInt;
Begin
  WinGetMsg := 0;
  Q := CurQ;
  If (Q < 0) Or (P = 0) Then
  Begin
    SetErr(PMERR_NO_MSG_QUEUE);
    Exit;
  End;
  Dummy := LongInt(NextMsg(Q, P, HF, First, Last, True, True));
  If RdL(P + 4) <> WM_QUIT Then WinGetMsg := 1;
End;

{ WinPeekMsg(hab, pqmsg, hwndFilter, first, last, fl) : PM_REMOVE 1 }
Function WinPeekMsg(Hab, P, HF, First, Last, Fl : LongInt) : LongInt;
Var Q : LongInt;
Begin
  WinPeekMsg := 0;
  Q := CurQ;
  If (Q < 0) Or (P = 0) Then
  Begin
    SetErr(PMERR_NO_MSG_QUEUE);
    Exit;
  End;
  If NextMsg(Q, P, HF, First, Last, (Fl And 1) <> 0, False) Then WinPeekMsg := 1;
End;

{ WinWaitMsg(hab, first, last) : attendre un message ; BOOL }
Function WinWaitMsg(Hab, First, Last : LongInt) : LongInt;
Var Q : LongInt;
Begin
  WinWaitMsg := 0;
  Q := CurQ;
  If Q < 0 Then Exit;
  Dummy := LongInt(NextMsg(Q, LongInt(@GMsg), 0, First, Last, False, True));
  WinWaitMsg := 1;
End;

{ WinDispatchMsg(hab, pqmsg) : procedure de la fenetre }
Function WinDispatchMsg(Hab, P : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  WinDispatchMsg := 0;
  If P = 0 Then Exit;
  I := WIdx(RdL(P));
  If I < 0 Then Exit;
  R := CallProcOf(I, RdL(P + 4), RdL(P + 8), RdL(P + 12));
  { WM_PAINT non traite : la zone est validee }
  If (RdL(P + 4) = WM_PAINT) And (WUse[I] <> 0) Then WUpd[I] := 0;
  WinDispatchMsg := R;
End;

Function WinQueryMsgPos(Hab, P : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := CurQ;
  If (Q < 0) Or (P = 0) Then WinQueryMsgPos := 0
  Else
  Begin
    WrL(P, QPosX[Q]); WrL(P + 4, QPosY[Q]);
    WinQueryMsgPos := 1;
  End;
End;

Function WinQueryMsgTime(Hab : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := CurQ;
  If Q < 0 Then WinQueryMsgTime := 0 Else WinQueryMsgTime := QTime[Q];
End;

{ WinQueryQueueStatus(hwndDesktop) : mot bas etat courant (QS_*), mot
  haut ajouts depuis l'appel precedent }
Function WinQueryQueueStatus(HDesk : LongInt) : LongInt;
Var Q, Cur, K, T : LongInt;
Begin
  Q := CurQ;
  If Q < 0 Then
  Begin
    WinQueryQueueStatus := 0;
    Exit;
  End;
  PollInput(Q);
  Cur := 0;
  If QCount[Q] > 0 Then Cur := Cur Or $20;
  If PaintWinOf(Q, -1) >= 0 Then Cur := Cur Or $10;
  T := KGetTickCount;
  For K := 0 To MaxTimer - 1 Do
    If (TmUse[K] <> 0) And (TmQ[K] = Q) And (T - TmNext[K] >= 0) Then Cur := Cur Or 8;
  WinQueryQueueStatus := Mk2(QStat[Q] Or Cur, QStat[Q]);
  QStat[Q] := 0;
End;

{ WinQueryQueueInfo(hmq, pmqi, cbCopy) : MQINFO (cb, pid, tid, cmsgs,
  pReserved) ; BOOL }
Function WinQueryQueueInfo(Hmq, P, Cb : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := QIdx(Hmq);
  If (Q < 0) Or (P = 0) Then WinQueryQueueInfo := 0
  Else
  Begin
    MemZero(LongInt(@NameZ), 20);
    WrL(LongInt(@NameZ), 20); WrL(LongInt(@NameZ) + 4, QPid[Q]); WrL(LongInt(@NameZ) + 8, 1);
    WrL(LongInt(@NameZ) + 12, QSize[Q]);
    MemMove(LongInt(@NameZ), P, MinI(Cb, 20));
    WinQueryQueueInfo := 1;
  End;
End;

Function WinQueueFromId(Hab, Pid, Tid : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  For I := MaxQ - 1 DownTo 0 Do
    If (QPid[I] <> 0) And (QPid[I] = Pid) Then R := $00510001 + I;
  WinQueueFromId := R;
End;

Function WinThreadAssocQueue(Hab, Hmq : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := QIdx(Hmq);
  If (Hmq <> 0) And (Q < 0) Then WinThreadAssocQueue := 0 Else WinThreadAssocQueue := 1;
End;

{ les messages envoyes sont remis aussitot : aucun n'attend }
Function WinQuerySendMsg(Hab, HmqSender, HmqReceiver, P : LongInt) : LongInt;
Begin
  WinQuerySendMsg := 0;
End;

Function WinReplyMsg(Hab, HmqSender, HmqReceiver, Mres : LongInt) : LongInt;
Begin
  WinReplyMsg := 0;
End;

Function WinWakeThread(Hmq : LongInt) : LongInt;
Begin
  If QIdx(Hmq) < 0 Then WinWakeThread := 0 Else WinWakeThread := 1;
End;

{ WinLockInput(hmq, fLock) : plus de lecture du clavier et de la souris }
Function WinLockInput(Hmq, Lock : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := QIdx(Hmq);
  If Q < 0 Then WinLockInput := 0
  Else
  Begin
    QLockIn[Q] := Lock;
    WinLockInput := 1;
  End;
End;

Function WinLockStartInput(Hab, Lock : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := CurQ;
  If Q < 0 Then WinLockStartInput := 0
  Else
  Begin
    QLockIn[Q] := Lock;
    WinLockStartInput := 1;
  End;
End;

{ WinSetMsgInterest(hwnd, msg_class, control) : SMI_NOINTEREST 1,
  SMI_INTEREST 2, SMI_RESET 4 ; message WM_MOUSEMOVE, WM_CHAR, ou -1
  (tous) ; BOOL }
Function InterestBits(MsgCls : LongInt) : LongInt;
Begin
  If MsgCls = WM_MOUSEMOVE Then InterestBits := 1
  Else If MsgCls = WM_CHAR Then InterestBits := 2
  Else If (MsgCls >= WM_BUTTON1DOWN) And (MsgCls <= WM_BUTTON3DBLCLK) Then InterestBits := 4
  Else InterestBits := 7;
End;

Function WinSetMsgInterest(H, MsgCls, Ctl : LongInt) : LongInt;
Var I, B : LongInt;
Begin
  I := WChk(H);
  If I < 0 Then
  Begin
    WinSetMsgInterest := 0;
    Exit;
  End;
  B := InterestBits(MsgCls);
  If (Ctl And 1) <> 0 Then WInt0[I] := WInt0[I] Or B;
  If (Ctl And 2) <> 0 Then WInt0[I] := WInt0[I] And Not B;
  If (Ctl And 4) <> 0 Then WInt0[I] := CInt0[WCls[I]];
  WinSetMsgInterest := 1;
End;

Function WinSetClassMsgInterest(Hab, PCls, MsgCls, Ctl : LongInt) : LongInt;
Var C, B : LongInt;
Begin
  C := ClsFind(ClsNameOf(PCls));
  If C < 0 Then
  Begin
    WinSetClassMsgInterest := 0;
    Exit;
  End;
  B := InterestBits(MsgCls);
  If (Ctl And 1) <> 0 Then CInt0[C] := CInt0[C] Or B;
  If (Ctl And 2) <> 0 Then CInt0[C] := CInt0[C] And Not B;
  If (Ctl And 4) <> 0 Then CInt0[C] := 0;
  WinSetClassMsgInterest := 1;
End;

{ --- etat du clavier --- }
Function WinGetKeyState(HDesk, Vk : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If (Vk >= 0) And (Vk < 256) Then
  Begin
    If (KeyState[Vk] And $80) <> 0 Then R := R Or $8000;
    If (KeyState[Vk] And 1) <> 0 Then R := R Or 1;
  End;
  WinGetKeyState := R;
End;

Function WinGetPhysKeyState(HDesk, Sc : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If (Sc >= 0) And (Sc < 256) Then
  Begin
    If (ScanState[Sc] And $80) <> 0 Then R := R Or $8000;
    If (ScanState[Sc] And 1) <> 0 Then R := R Or 1;
  End;
  WinGetPhysKeyState := R;
End;

{ WinSetKeyboardStateTable(hwndDesktop, pKeyStateTable, fSet) : 256
  octets (80h enfoncee, 01h basculee) ; BOOL }
Function WinSetKeyboardStateTable(HDesk, P, FSet : LongInt) : LongInt;
Begin
  If P = 0 Then WinSetKeyboardStateTable := 0
  Else
  Begin
    If FSet <> 0 Then MemMove(P, LongInt(@KeyState), 256) Else MemMove(LongInt(@KeyState), P, 256);
    WinSetKeyboardStateTable := 1;
  End;
End;

Function WinGetScanState(HDesk, Sc : LongInt) : LongInt;
Begin
  WinGetScanState := WinGetPhysKeyState(HDesk, Sc);
End;

Function WinSetScanStateTable(HDesk, P, FSet : LongInt) : LongInt;
Begin
  If P = 0 Then WinSetScanStateTable := 0
  Else
  Begin
    If FSet <> 0 Then MemMove(P, LongInt(@ScanState), 256) Else MemMove(LongInt(@ScanState), P, 256);
    WinSetScanStateTable := 1;
  End;
End;

Function WinEnablePhysInput(HDesk, En : LongInt) : LongInt;
Begin
  PhysInput := En;
  WinEnablePhysInput := 1;
End;

Function WinIsPhysInputEnabled(HDesk : LongInt) : LongInt;
Begin
  If PhysInput <> 0 Then WinIsPhysInputEnabled := 1 Else WinIsPhysInputEnabled := 0;
End;

{ WinCheckInput(hab) : une entree attend-elle ? }
Function WinCheckInput(Hab : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := CurQ;
  WinCheckInput := 0;
  If Q < 0 Then Exit;
  PollInput(Q);
  If (QStat[Q] And 7) <> 0 Then WinCheckInput := 1;
End;

{ KbdPacket(ch, scan, fsState) : poster une frappe (WM_CHAR) a la
  fenetre du focus }
Function KbdPacket(Ch, Sc, St : LongInt) : LongInt;
Var Fs, Vk, T : LongInt;
Begin
  KbdPacket := 0;
  T := FocusWin;
  If (T < 2) Or (WUse[T] = 0) Then T := ActiveWin;
  If (T < 2) Or (WUse[T] = 0) Then Exit;
  Fs := KC_SCANCODE;
  If (Ch And 255) <> 0 Then Fs := Fs Or KC_CHAR;
  Vk := ScanVk(Sc And 255, Ch And 255);
  If Vk <> 0 Then Fs := Fs Or KC_VIRTUALKEY;
  If (St And 3) <> 0 Then Fs := Fs Or KC_SHIFT;
  If (St And 4) <> 0 Then Fs := Fs Or KC_CTRL;
  If (St And 8) <> 0 Then Fs := Fs Or KC_ALT;
  If PostM(HwOf(T), WM_CHAR, Fs Or (1 Shl 16) Or ((Sc And 255) Shl 24), Mk2(Ch And 255, Vk)) Then KbdPacket := 1;
End;

{ WinJiggleMouse : un WM_MOUSEMOVE a la fenetre sous le pointeur }
Function WinJiggleMouse : LongInt;
Var T : LongInt;
Begin
  T := WinAtAbs(0, MouseX, MouseY, True);
  If T > 1 Then MouseMsg(WHmq[T], T, WM_MOUSEMOVE, 0);
  WinJiggleMouse := 1;
End;

{ WinCancelMode(hwndDesktop) : fin de la capture et des modes (menus,
  suivi) ; BOOL }
Function WinCancelMode(HDesk : LongInt) : LongInt;
Begin
  CaptureWin := 0;
  TrackShown := 0;
  WinCancelMode := 1;
End;


{ ==================================================================== }
{ Partie 5 - Procedures des classes, dialogues, boites de message      }
{ ==================================================================== }

Function PPColor(I, Id, Def : LongInt) : LongInt; Forward;
Function ClipGetText : String; Forward;
Procedure ClipPutText(S : String); Forward;
Function WinDismissDlg(H, R : LongInt) : LongInt; Forward;
Function WinEnumDlgItem(HDlg, H, Code : LongInt) : LongInt; Forward;
Function WinTrackRect(H, Hps, P : LongInt) : LongInt; Forward;

{ --- textes --- }
Function NoTilde(S : String) : String;
Var T : String; K : LongInt;
Begin
  T := '';
  For K := 1 To Length(S) Do
    If Ord(S[K]) <> 126 Then T := T + S[K];
  NoTilde := T;
End;

Function VisLen(S : String) : LongInt;
Begin
  VisLen := Length(NoTilde(S));
End;

{ caractere mnemonique (majuscule) ; 0 s'il n'y en a pas }
Function MnemOf(S : String) : LongInt;
Var K, R : LongInt;
Begin
  R := 0;
  For K := 1 To Length(S) - 1 Do
    If (R = 0) And (Ord(S[K]) = 126) Then R := Ord(UpCase(S[K + 1]));
  MnemOf := R;
End;

Function UpCh(C : LongInt) : LongInt;
Begin
  UpCh := Ord(UpCase(Chr(C And 255)));
End;

{ premiere ligne de S (au plus W cellules ; coupee a un espace ou a un
  saut de ligne) ; S devient le reste }
Function CutLine(Var S : String; W : LongInt) : String;
Var J, N, Sp, E, Nx : LongInt; Done : Boolean;
Begin
  If W < 1 Then W := 1;
  J := 1; N := 0; Sp := 0; E := Length(S); Nx := Length(S) + 1; Done := False;
  While (J <= Length(S)) And Not Done Do
  Begin
    If (Ord(S[J]) = 10) Or (Ord(S[J]) = 13) Then
    Begin
      E := J - 1; Nx := J + 1;
      If (Ord(S[J]) = 13) And (J < Length(S)) Then
        If Ord(S[J + 1]) = 10 Then Nx := J + 2;
      Done := True;
    End
    Else
    Begin
      If Ord(S[J]) = 32 Then Sp := J;
      If Ord(S[J]) <> 126 Then Inc(N);
      If N > W Then
      Begin
        If Sp > 1 Then
        Begin
          E := Sp - 1; Nx := Sp + 1;
        End
        Else
        Begin
          E := J - 1; Nx := J;
        End;
        Done := True;
      End;
    End;
    Inc(J);
  End;
  CutLine := Copy(S, 1, E);
  If Nx > Length(S) Then S := '' Else S := Copy(S, Nx, 255);
End;

{ --- dessin des controles --- }
Function BeginP(I : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := WinBeginPaint(HwOf(I), 0, 0);
  If H = 0 Then BeginP := -1 Else BeginP := H - $50530001;
End;

Procedure EndP(K : LongInt);
Begin
  If K >= 0 Then Dummy := WinEndPaint($50530001 + K);
End;

{ attribut du mnemonique }
Function MnA(A : LongInt) : LongInt;
Begin
  If (A And 15) = 15 Then MnA := (A And $F0) Or 14 Else MnA := (A And $F0) Or 15;
End;

{ ecrire S en (x, y) de l'espace K (au plus N cellules) }
Procedure TextPS(K, X, Y, N : LongInt; S : String; A, AM : LongInt; Mn : Boolean);
Var J, Ch : LongInt; Hi : Boolean;
Begin
  Hi := False;
  J := 1;
  While (J <= Length(S)) And (N > 0) Do
  Begin
    Ch := Ord(S[J]);
    If Mn And (Ch = 126) And Not Hi Then Hi := True
    Else
    Begin
      If Hi And (GMode <> 0) Then
      Begin
        CharPS(K, X, Y, Ch, A); UnderPS(K, X, Y, A);
      End
      Else If Hi Then CharPS(K, X, Y, Ch, AM) Else CharPS(K, X, Y, Ch, A);
      Hi := False;
      X := X + 8;
      Dec(N);
    End;
    Inc(J);
  End;
End;

{ Texte dans un rectangle (0, 0, W, H) : DT_CENTER 100h, DT_RIGHT 200h,
  DT_VCENTER 400h, DT_BOTTOM 800h, DT_MNEMONIC 2000h, DT_WORDBREAK 4000h }
Procedure TextBox(K : LongInt; S : String; W, H, Fl, A : LongInt);
Var T, L : String; N, Wc, Y, X, Yt : LongInt;
Begin
  Wc := MaxI(W Div 8, 1);
  T := S; N := 0;
  While (T <> '') And (N < 25) Do
  Begin
    L := CutLine(T, Wc);
    Inc(N);
  End;
  If (Fl And $4000) = 0 Then N := MinI(N, 1);
  If N = 0 Then Exit;
  If (Fl And $400) <> 0 Then Yt := (H + N * 16) Div 2 - 16
  Else If (Fl And $800) <> 0 Then Yt := N * 16 - 16
  Else Yt := H - 16;
  T := S; Y := Yt;
  While (T <> '') And (N > 0) Do
  Begin
    L := CutLine(T, Wc);
    If (Fl And $100) <> 0 Then X := ((Wc - VisLen(L)) Div 2) * 8
    Else If (Fl And $200) <> 0 Then X := (Wc - VisLen(L)) * 8
    Else X := 0;
    TextPS(K, MaxI(X, 0), Y, Wc, L, A, MnA(A), (Fl And $2000) <> 0);
    Y := Y - 16;
    Dec(N);
  End;
End;

{ fond des controles : dialogue (enfant d'un cadre) ou fenetre }
Function CtlBg(I : LongInt) : LongInt;
Begin
  If (WPar[I] > 1) And (KindOf(WPar[I]) = CK_FRAME) Then CtlBg := -34 Else CtlBg := -20;
End;

{ --- ecran graphique : dessin des controles (coordonnees de l'espace K) --- }
Function GCol(Clr : LongInt) : LongInt;
Begin
  GCol := VgaColor(Clr, False);
End;

Procedure GFillPS(K, X1, Y1, X2, Y2, C : LongInt);
Begin
  If GPsClip(K) Then GFill(X1 + PsOrgX[K], Y1 + PsOrgY[K], X2 + PsOrgX[K], Y2 + PsOrgY[K], C);
End;

{ relief de W pels (Lt en haut et a gauche) }
Procedure GBevelPS(K, X1, Y1, X2, Y2, Lt, Dk, W : LongInt);
Begin
  If GPsClip(K) Then GBevel(X1 + PsOrgX[K], Y1 + PsOrgY[K], X2 + PsOrgX[K], Y2 + PsOrgY[K], Lt, Dk, W);
End;

Procedure GFramePS(K, X1, Y1, X2, Y2, C : LongInt);
Begin
  If GPsClip(K) Then GFrame(X1 + PsOrgX[K], Y1 + PsOrgY[K], X2 + PsOrgX[K], Y2 + PsOrgY[K], C);
End;

{ contour en pointilles (focus) }
Procedure GDotPS(K, X1, Y1, X2, Y2, C : LongInt);
Begin
  If GPsClip(K) Then
  Begin
    X1 := X1 + PsOrgX[K]; X2 := X2 + PsOrgX[K]; Y1 := Y1 + PsOrgY[K]; Y2 := Y2 + PsOrgY[K];
    GFillPat(X1, Y2 - 1, X2, Y2, C, $AA, 0); GFillPat(X1, Y1, X2, Y1 + 1, C, $AA, 0);
    GFillPat(X1, Y1, X1 + 1, Y2, C, $AA, 0); GFillPat(X2 - 1, Y1, X2, Y2, C, $AA, 0);
  End;
End;

Procedure GArrowPS(K, X1, Y1, X2, Y2, Dir, C : LongInt);
Begin
  If GPsClip(K) Then GArrow(X1 + PsOrgX[K], Y1 + PsOrgY[K], X2 + PsOrgX[K], Y2 + PsOrgY[K], Dir, C);
End;

Procedure GLinePS(K, X1, Y1, X2, Y2, C : LongInt);
Begin
  If GPsClip(K) Then GLine(X1 + PsOrgX[K], Y1 + PsOrgY[K], X2 + PsOrgX[K], Y2 + PsOrgY[K], C);
End;

Procedure GDiscPS(K, X, Y, R, C : LongInt);
Begin
  If GPsClip(K) Then GDisc(X + PsOrgX[K], Y + PsOrgY[K], R, C);
End;

{ texte transparent (Opaque faux) ou sur le fond Bg ; ~ souligne si Mn }
Procedure GTextPS(K, X, Y : LongInt; S : String; N, Fg, Bg : LongInt; Opaque, Mn : Boolean);
Begin
  If GPsClip(K) Then GText(X + PsOrgX[K], Y + PsOrgY[K], S, N, Fg, Bg, Opaque, Mn);
End;

{ bouton en relief (enfonce : Dn) }
Procedure GButtonPS(K, X1, Y1, X2, Y2, Bg : LongInt; Dn : Boolean);
Begin
  GFillPS(K, X1, Y1, X2, Y2, Bg);
  If Dn Then
  Begin
    GBevelPS(K, X1, Y1, X2, Y2, 0, 15, 1); GBevelPS(K, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, 8, Bg, 1);
  End
  Else
  Begin
    GBevelPS(K, X1, Y1, X2, Y2, 15, 0, 1); GBevelPS(K, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, Bg, 8, 1);
  End;
End;

{ champ en creux }
Procedure GSunkenPS(K, X1, Y1, X2, Y2 : LongInt);
Begin
  GBevelPS(K, X1, Y1, X2, Y2, 8, 15, 1); GBevelPS(K, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, 0, 7, 1);
End;

Function OwnerH(I : LongInt) : LongInt;
Begin
  If WIdx(WOwner[I]) > 1 Then OwnerH := WOwner[I]
  Else If WPar[I] > 1 Then OwnerH := HwOf(WPar[I])
  Else OwnerH := 0;
End;

Procedure Notify(I, Code : LongInt);
Begin
  Dummy := SendM(OwnerH(I), WM_CONTROL, Mk2(WId[I], Code), HwOf(I));
End;

Function ChildId(I, Id : LongInt) : LongInt;
Var J, R : LongInt;
Begin
  R := -1;
  For J := MaxWin - 1 DownTo 2 Do
    If (WUse[J] <> 0) And (WPar[J] = I) And (WId[J] = Id) Then R := J;
  ChildId := R;
End;

{ --- articles (listes et menus) : ItWin = rang + 1 --- }
Function ItCnt(I : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To MaxItem - 1 Do
    If ItWin[K] = I + 1 Then Inc(N);
  ItCnt := N;
End;

Function ItAt(I, Ps : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  If Ps >= 0 Then
    For K := 0 To MaxItem - 1 Do
      If (ItWin[K] = I + 1) And (ItPos[K] = Ps) Then R := K;
  ItAt := R;
End;

Function ItTextGet(K : LongInt) : String;
Var S : String; J, N : LongInt;
Begin
  S := '';
  N := ItText[K * ItemSlot];
  For J := 1 To N Do S := S + Chr(ItText[K * ItemSlot + J]);
  ItTextGet := S;
End;

Procedure ItTextSet(K : LongInt; S : String);
Var J : LongInt;
Begin
  S := Copy(S, 1, ItemSlot - 1);
  ItText[K * ItemSlot] := Length(S);
  For J := 1 To Length(S) Do ItText[K * ItemSlot + J] := Ord(S[J]);
End;

Function ItIns(I, Ps : LongInt; S : String) : LongInt;
Var K, F, N : LongInt;
Begin
  F := -1;
  For K := MaxItem - 1 DownTo 0 Do
    If ItWin[K] = 0 Then F := K;
  If F < 0 Then
  Begin
    SetErr(PMERR_HEAP_OUT_OF_MEMORY);
    ItIns := -1;
    Exit;
  End;
  N := ItCnt(I);
  If (Ps < 0) Or (Ps > N) Then Ps := N;
  For K := 0 To MaxItem - 1 Do
    If (ItWin[K] = I + 1) And (ItPos[K] >= Ps) Then Inc(ItPos[K]);
  ItWin[F] := I + 1; ItPos[F] := Ps; ItId[F] := 0; ItStyle[F] := 0; ItAttr[F] := 0;
  ItSub[F] := 0; ItHandle[F] := 0;
  ItTextSet(F, S);
  ItIns := F;
End;

Procedure ItDel(K : LongInt);
Var J, I, P : LongInt;
Begin
  I := ItWin[K]; P := ItPos[K];
  ItWin[K] := 0;
  For J := 0 To MaxItem - 1 Do
    If (ItWin[J] = I) And (ItPos[J] > P) Then Dec(ItPos[J]);
End;

Procedure FreeItemsOf(I : LongInt);
Var K : LongInt;
Begin
  For K := 0 To MaxItem - 1 Do
    If ItWin[K] = I + 1 Then ItWin[K] := 0;
End;

{ ==================================================================== }
{ WinDefWindowProc                                                      }
{ ==================================================================== }
Function DefWP(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I, K, T, Fs : LongInt; Tx : String;
Begin
  DefWP := 0;
  I := WIdx(H);
  If I < 0 Then Exit;
  Case Msg Of
    WM_CLOSE :
      Dummy := LongInt(PostM(H, WM_QUIT, 0, 0));
    WM_PAINT :
      Begin
        K := WinBeginPaint(H, 0, 0);
        If K <> 0 Then Dummy := WinEndPaint(K);
      End;
    WM_SETWINDOWPARAMS :
      If Mp1 <> 0 Then
      Begin
        If (RdL(Mp1) And 1) <> 0 Then WTextSet(I, GetN(RdL(Mp1 + 8), MinI(RdL(Mp1 + 4), 255)));
        DefWP := 1;
      End;
    WM_QUERYWINDOWPARAMS :
      If Mp1 <> 0 Then
      Begin
        Fs := RdL(Mp1);
        Tx := WTextGet(I);
        If (Fs And 1) <> 0 Then Dummy := PutZN(RdL(Mp1 + 8), RdL(Mp1 + 4), Tx);
        If (Fs And 8) <> 0 Then WrL(Mp1 + 4, Length(Tx));
        If (Fs And 2) <> 0 Then WrL(Mp1 + 12, 0);
        If (Fs And $10) <> 0 Then WrL(Mp1 + 20, 0);
        DefWP := 1;
      End;
    WM_CHAR :
      If (WIdx(WOwner[I]) > 1) And (WIdx(WOwner[I]) <> I) Then DefWP := SendM(WOwner[I], Msg, Mp1, Mp2);
    WM_BUTTON1DOWN, WM_BUTTON2DOWN, WM_BUTTON3DOWN :
      Begin
        T := TopFrame(I);
        If (T > 1) And (T <> ActiveWin) And (KindOf(T) <> CK_MENU) Then Dummy := WinSetActiveWindow(HWND_DESKTOP, HwOf(T));
      End;
    $0038 :                                   { WM_CONTROLPOINTER }
      DefWP := Mp2;
    WM_ENABLE, WM_PRESPARAMCHANGED, WM_SYSCOLORCHANGE :
      InvalWin(I);
  End;
End;

Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  WinDefWindowProc := DefWP(H, Msg, Mp1, Mp2);
End;

{ procedure de la classe d'une fenetre (pour les dialogues) }
Function ClassProcCall(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := 0;
  If WCls[I] >= 0 Then P := CProc[WCls[I]];
  If P = SysProc Then ClassProcCall := SysProcI(HwOf(I), Msg, Mp1, Mp2)
  Else If (P = 0) Or (P = DefProcAddr) Or (P = DefDlgAddr) Then ClassProcCall := DefWP(HwOf(I), Msg, Mp1, Mp2)
  Else ClassProcCall := Call4(P, HwOf(I), Msg, Mp1, Mp2);
End;

{ ==================================================================== }
{ Cadre                                                                 }
{ ==================================================================== }
Function HasBorder(I : LongInt) : Boolean;
Begin
  HasBorder := ((WStyle[I] And (FS_BORDER Or FS_DLGBORDER Or FS_SIZEBORDER)) <> 0) Or
               ((WS0[I] And (FCF_BORDER Or FCF_DLGBORDER Or FCF_SIZEBORDER)) <> 0);
End;

{ ecran graphique : largeur de la bordure (FS_SIZEBORDER 4, FS_DLGBORDER 3,
  FS_BORDER 1) }
Function GBorderW(I : LongInt) : LongInt;
Begin
  If ((WStyle[I] And FS_SIZEBORDER) <> 0) Or ((WS0[I] And FCF_SIZEBORDER) <> 0) Then GBorderW := 4
  Else If ((WStyle[I] And FS_DLGBORDER) <> 0) Or ((WS0[I] And FCF_DLGBORDER) <> 0) Then GBorderW := 3
  Else If HasBorder(I) Then GBorderW := 1
  Else GBorderW := 0;
End;

{ marges du cadre (pels) : gauche, bas, droite, haut }
Procedure FrameInsets(I : LongInt; Var L, B, R, T : LongInt);
Var Bd : Boolean;
Begin
  If GMode <> 0 Then
  Begin
    L := GBorderW(I); R := L; B := L; T := L;
    If (ChildId(I, FID_TITLEBAR) >= 0) Or (ChildId(I, FID_SYSMENU) >= 0) Or (ChildId(I, FID_MINMAX) >= 0) Then T := T + TitleH;
    If ChildId(I, FID_MENU) >= 0 Then T := T + MenuH;
    If ChildId(I, FID_VERTSCROLL) >= 0 Then R := R + VsbW;
    If ChildId(I, FID_HORZSCROLL) >= 0 Then B := B + HsbH;
    Exit;
  End;
  Bd := HasBorder(I);
  If Bd Then
  Begin
    L := 8; R := 8; B := 16; T := 16;
  End
  Else
  Begin
    L := 0; R := 0; B := 0; T := 0;
    If (ChildId(I, FID_TITLEBAR) >= 0) Or (ChildId(I, FID_SYSMENU) >= 0) Or (ChildId(I, FID_MINMAX) >= 0) Then T := 16;
  End;
  If ChildId(I, FID_MENU) >= 0 Then T := T + 16;
  If ChildId(I, FID_VERTSCROLL) >= 0 Then R := R + 8;
  If ChildId(I, FID_HORZSCROLL) >= 0 Then B := B + 16;
End;

Function MenuWidthPels(I : LongInt) : LongInt; Forward;

{ placer un controle (P <> 0 : remplir le SWP numero N) }
Procedure Place(J, X, Y, Cx, Cy, P, Max : LongInt; Var N : LongInt);
Var A : LongInt;
Begin
  Cx := MaxI(Cx, 0); Cy := MaxI(Cy, 0);
  If P <> 0 Then
  Begin
    If N < Max Then
    Begin
      A := P + N * 36;
      WrL(A, SWP_MOVE Or SWP_SIZE); WrL(A + 4, Cy); WrL(A + 8, Cx); WrL(A + 12, Y); WrL(A + 16, X);
      WrL(A + 20, 0); WrL(A + 24, HwOf(J)); WrL(A + 28, 0); WrL(A + 32, 0);
    End;
  End
  Else Dummy := WinSetWindowPos(HwOf(J), 0, X, Y, Cx, Cy, SWP_MOVE Or SWP_SIZE Or SWP_NOADJUST);
  Inc(N);
End;

{ disposer les controles du cadre ; rend leur nombre }
Function FormatFrameI(I, P, Max : LongInt) : LongInt;
Var L, B, R, T, Cx, Cy, J, N, Sw, Mw, Bw, Bh, Hs, Vs, Th : LongInt;
Begin
  FrameInsets(I, L, B, R, T);
  If GMode <> 0 Then
  Begin
    Bw := GBorderW(I);
    Cx := WCX[I]; Cy := WCY[I];
    N := 0; Sw := 0; Mw := 0; Th := 0;
    If (ChildId(I, FID_TITLEBAR) >= 0) Or (ChildId(I, FID_SYSMENU) >= 0) Or (ChildId(I, FID_MINMAX) >= 0) Then Th := TitleH;
    J := ChildId(I, FID_SYSMENU);
    If J >= 0 Then
    Begin
      Sw := TitleH;
      Place(J, Bw, Cy - Bw - TitleH, TitleH, TitleH, P, Max, N);
    End;
    J := ChildId(I, FID_MINMAX);
    If J >= 0 Then
    Begin
      Mw := MenuWidthPels(J);
      Place(J, Cx - Bw - Mw, Cy - Bw - TitleH, Mw, TitleH, P, Max, N);
    End;
    J := ChildId(I, FID_TITLEBAR);
    If J >= 0 Then Place(J, Bw + Sw, Cy - Bw - TitleH, Cx - 2 * Bw - Sw - Mw, TitleH, P, Max, N);
    J := ChildId(I, FID_MENU);
    If J >= 0 Then Place(J, Bw, Cy - Bw - Th - MenuH, Cx - 2 * Bw, MenuH, P, Max, N);
    Hs := 0; Vs := 0;
    If ChildId(I, FID_HORZSCROLL) >= 0 Then Hs := HsbH;
    If ChildId(I, FID_VERTSCROLL) >= 0 Then Vs := VsbW;
    J := ChildId(I, FID_VERTSCROLL);
    If J >= 0 Then Place(J, Cx - Bw - Vs, Bw + Hs, Vs, Cy - T - Bw - Hs, P, Max, N);
    J := ChildId(I, FID_HORZSCROLL);
    If J >= 0 Then Place(J, Bw, Bw, Cx - 2 * Bw - Vs, Hs, P, Max, N);
    J := ChildId(I, FID_CLIENT);
    If J >= 0 Then Place(J, L, B, Cx - L - R, Cy - B - T, P, Max, N);
    FormatFrameI := N;
    Exit;
  End;
  If HasBorder(I) Then
  Begin
    Bw := 8; Bh := 16;
  End
  Else
  Begin
    Bw := 0; Bh := 0;
  End;
  Cx := WCX[I]; Cy := WCY[I];
  N := 0; Sw := 0; Mw := 0;
  J := ChildId(I, FID_SYSMENU);
  If J >= 0 Then
  Begin
    Sw := 24;
    Place(J, Bw, Cy - 16, 24, 16, P, Max, N);
  End;
  J := ChildId(I, FID_MINMAX);
  If J >= 0 Then
  Begin
    Mw := MenuWidthPels(J);
    Place(J, Cx - Bw - Mw, Cy - 16, Mw, 16, P, Max, N);
  End;
  J := ChildId(I, FID_TITLEBAR);
  If J >= 0 Then Place(J, Bw + Sw, Cy - 16, Cx - 2 * Bw - Sw - Mw, 16, P, Max, N);
  J := ChildId(I, FID_MENU);
  If J >= 0 Then Place(J, Bw, Cy - T, Cx - 2 * Bw, 16, P, Max, N);
  Hs := 0; Vs := 0;
  If ChildId(I, FID_HORZSCROLL) >= 0 Then Hs := 16;
  If ChildId(I, FID_VERTSCROLL) >= 0 Then Vs := 8;
  J := ChildId(I, FID_VERTSCROLL);
  If J >= 0 Then Place(J, Cx - Bw - 8, Bh + Hs, 8, Cy - T - Bh - Hs, P, Max, N);
  J := ChildId(I, FID_HORZSCROLL);
  If J >= 0 Then Place(J, Bw, Bh, Cx - 2 * Bw - Vs, 16, P, Max, N);
  J := ChildId(I, FID_CLIENT);
  If J >= 0 Then Place(J, L, B, Cx - L - R, Cy - B - T, P, Max, N);
  FormatFrameI := N;
End;

Function NewMenuWin(HPar, HOwn, Style, Id : LongInt) : LongInt; Forward;
Procedure MAdd(M, Style, Id, Sub : LongInt; S : String); Forward;
Function WinCreateMenu(HPar, P : LongInt) : LongInt; Forward;
Procedure MenuStart(R : LongInt); Forward;
Procedure MenuOpenSub(I, Ps : LongInt); Forward;
Function MenuMnem(I, Ch : LongInt) : LongInt; Forward;
Procedure MenuSelect(I, Ps, Mouse : LongInt); Forward;
Function MenuFirstSel(I : LongInt) : LongInt; Forward;

{ Creer les controles du cadre (FCF_*) }
Procedure CreateFrameCtls(I, Fl, Hmod, IdRes : LongInt);
Var H, M, S, P : LongInt; Buf : Array[0..259] Of Byte;
Begin
  H := HwOf(I);
  WS0[I] := WS0[I] Or Fl;
  If ((Fl And FCF_TITLEBAR) <> 0) And (ChildId(I, FID_TITLEBAR) < 0) Then
  Begin
    PutZ(LongInt(@Buf), WTextGet(I));
    Dummy := WinCreateWindow(H, $FFFF0009, LongInt(@Buf), WS_VISIBLE, 0, 0, 0, 0, H, HWND_TOP, FID_TITLEBAR, 0, 0);
  End;
  If ((Fl And FCF_SYSMENU) <> 0) And (ChildId(I, FID_SYSMENU) < 0) Then
  Begin
    M := NewMenuWin(H, H, MS_ACTIONBAR Or WS_VISIBLE, FID_SYSMENU);
    If M > 1 Then
    Begin
      S := NewMenuWin(HWND_DESKTOP, HwOf(M), 0, 0);
      If S > 1 Then
      Begin
        MAdd(S, MIS_TEXT Or MIS_SYSCOMMAND, SC_RESTORE, 0, '~Restaurer');
        MAdd(S, MIS_TEXT Or MIS_SYSCOMMAND, SC_MOVE, 0, '~Deplacer');
        MAdd(S, MIS_TEXT Or MIS_SYSCOMMAND, SC_SIZE, 0, '~Taille');
        MAdd(S, MIS_TEXT Or MIS_SYSCOMMAND, SC_MINIMIZE, 0, 'R~eduire');
        MAdd(S, MIS_TEXT Or MIS_SYSCOMMAND, SC_MAXIMIZE, 0, '~Agrandir');
        MAdd(S, MIS_SEPARATOR, 0, 0, '');
        MAdd(S, MIS_TEXT Or MIS_SYSCOMMAND, SC_CLOSE, 0, '~Fermer');
        MAdd(M, MIS_TEXT Or MIS_SUBMENU Or MIS_SYSCOMMAND, SC_SYSMENU, HwOf(S), '[' + Chr(254) + ']');
      End;
    End;
  End;
  If ((Fl And (FCF_MINBUTTON Or FCF_MAXBUTTON)) <> 0) And (ChildId(I, FID_MINMAX) < 0) Then
  Begin
    M := NewMenuWin(H, H, MS_ACTIONBAR Or WS_VISIBLE, FID_MINMAX);
    If M > 1 Then
    Begin
      If (Fl And FCF_MINBUTTON) <> 0 Then MAdd(M, MIS_TEXT Or MIS_SYSCOMMAND, SC_MINIMIZE, 0, '[' + Chr(25) + ']');
      If (Fl And FCF_MAXBUTTON) <> 0 Then MAdd(M, MIS_TEXT Or MIS_SYSCOMMAND, SC_MAXIMIZE, 0, '[' + Chr(24) + ']');
    End;
  End;
  If ((Fl And FCF_VERTSCROLL) <> 0) And (ChildId(I, FID_VERTSCROLL) < 0) Then
    Dummy := WinCreateWindow(H, $FFFF0008, 0, SBS_VERT Or WS_VISIBLE, 0, 0, 0, 0, H, HWND_TOP, FID_VERTSCROLL, 0, 0);
  If ((Fl And FCF_HORZSCROLL) <> 0) And (ChildId(I, FID_HORZSCROLL) < 0) Then
    Dummy := WinCreateWindow(H, $FFFF0008, 0, WS_VISIBLE, 0, 0, 0, 0, H, HWND_TOP, FID_HORZSCROLL, 0, 0);
  If ((Fl And FCF_MENU) <> 0) And (ChildId(I, FID_MENU) < 0) Then
  Begin
    P := GetRes(Hmod, 3, IdRes);
    If P <> 0 Then Dummy := WinCreateMenu(H, P);
  End;
  If (Fl And FCF_ACCELTABLE) <> 0 Then
  Begin
    P := GetRes(Hmod, 8, IdRes);
    If P <> 0 Then WS5[I] := WinCreateAccelTable(0, P);
  End;
  If (Fl And FCF_SYSMODAL) <> 0 Then SysModalWin := I;
  Dummy := FormatFrameI(I, 0, 0);
End;

{ WinCreateFrameControls(hwndFrame, pfcdata, pszTitle) : BOOL }
Function WinCreateFrameControls(H, P, PTitle : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinCreateFrameControls := 0;
  I := WChk(H);
  If (I < 2) Or (P = 0) Then Exit;
  If PTitle <> 0 Then WTextSet(I, GetZ(PTitle));
  CreateFrameCtls(I, RdL(P + 2), RdW(P + 6), RdW(P + 8));
  WinCreateFrameControls := 1;
End;

{ WinFormatFrame(hwndFrame, prclFrame, pswp, cswpMax, prclClient) :
  nombre de SWP }
Function WinFormatFrame(H, PFr, PSwp, Max, PCl : LongInt) : LongInt;
Var I, L, B, R, T : LongInt;
Begin
  WinFormatFrame := 0;
  I := WChk(H);
  If (I < 2) Or (PSwp = 0) Then Exit;
  WinFormatFrame := FormatFrameI(I, PSwp, Max);
  If PCl <> 0 Then
  Begin
    FrameInsets(I, L, B, R, T);
    WrL(PCl, L); WrL(PCl + 4, B); WrL(PCl + 8, WCX[I] - R); WrL(PCl + 12, WCY[I] - T);
  End;
End;

{ WinCalcFrameRect(hwndFrame, prcl, fClient) : fClient TRUE : prcl est le
  cadre et devient le client ; BOOL }
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt;
Var I, L, B, R, T : LongInt;
Begin
  WinCalcFrameRect := 0;
  I := WChk(H);
  If (I < 2) Or (P = 0) Then Exit;
  FrameInsets(I, L, B, R, T);
  If FClient <> 0 Then
  Begin
    WrL(P, RdL(P) + L); WrL(P + 4, RdL(P + 4) + B); WrL(P + 8, RdL(P + 8) - R); WrL(P + 12, RdL(P + 12) - T);
  End
  Else
  Begin
    WrL(P, RdL(P) - L); WrL(P + 4, RdL(P + 4) - B); WrL(P + 8, RdL(P + 8) + R); WrL(P + 12, RdL(P + 12) + T);
  End;
  WinCalcFrameRect := 1;
End;

{ WinGetMinPosition(hwnd, pswp, pptl) : position reduite (ligne du bas) }
Function WinGetMinPosition(H, P, PPtl : LongInt) : LongInt;
Var I, J, N, X, Y : LongInt;
Begin
  WinGetMinPosition := 0;
  I := WChk(H);
  If (I < 2) Or (P = 0) Then Exit;
  N := 0;
  For J := 2 To MaxWin - 1 Do
    If (J <> I) And (WUse[J] <> 0) And (WPar[J] = WPar[I]) And ((WStyle[J] And WS_MINIMIZED) <> 0) Then Inc(N);
  X := (N Mod 4) * 160; Y := (N Div 4) * (TitleH + 2 * GBorderW(I));
  If PPtl <> 0 Then
  Begin
    X := RdL(PPtl); Y := RdL(PPtl + 4);
  End;
  WrL(P, SWP_MINIMIZE Or SWP_MOVE Or SWP_SIZE); WrL(P + 4, TitleH + 2 * GBorderW(I)); WrL(P + 8, 160); WrL(P + 12, Y); WrL(P + 16, X);
  WrL(P + 20, 0); WrL(P + 24, H);
  WinGetMinPosition := 1;
End;

{ WinGetMaxPosition(hwnd, pswp) : tout le parent }
Function WinGetMaxPosition(H, P : LongInt) : LongInt;
Var I, Pa : LongInt;
Begin
  WinGetMaxPosition := 0;
  I := WChk(H);
  If (I < 2) Or (P = 0) Then Exit;
  Pa := WPar[I];
  WrL(P, SWP_MAXIMIZE Or SWP_MOVE Or SWP_SIZE); WrL(P + 4, WCY[Pa]); WrL(P + 8, WCX[Pa]);
  WrL(P + 12, 0); WrL(P + 16, 0); WrL(P + 20, 0); WrL(P + 24, H);
  WinGetMaxPosition := 1;
End;

Procedure FramePaint(I : LongInt);
Var K, A, Bg, Bw, Bc : LongInt; Act : Boolean;
Begin
  K := BeginP(I);
  If K < 0 Then Exit;
  Act := (ActiveWin = I);
  If (WFlags[I] And 4) <> 0 Then Bg := -34 Else Bg := -20;
  If Act Then A := Attr(-15, Bg) Else A := Attr(-14, Bg);
  If GMode <> 0 Then
  Begin
    Bw := GBorderW(I);
    GFillPS(K, Bw, Bw, WCX[I] - Bw, WCY[I] - Bw, GCol(Bg));
    If Bw = 1 Then GFramePS(K, 0, 0, WCX[I], WCY[I], 0)
    Else If Bw > 1 Then
    Begin
      If Act Then Bc := GCol(-15) Else Bc := GCol(-14);
      GFillPS(K, 0, 0, WCX[I], Bw, Bc); GFillPS(K, 0, WCY[I] - Bw, WCX[I], WCY[I], Bc);
      GFillPS(K, 0, Bw, Bw, WCY[I] - Bw, Bc); GFillPS(K, WCX[I] - Bw, Bw, WCX[I], WCY[I] - Bw, Bc);
      GBevelPS(K, 0, 0, WCX[I], WCY[I], 15, 0, 1);
      GBevelPS(K, Bw - 1, Bw - 1, WCX[I] - Bw + 1, WCY[I] - Bw + 1, 8, 15, 1);
    End;
    EndP(K);
    Exit;
  End;
  FillPS(K, 0, 0, WCX[I], WCY[I], 32, Attr(-17, Bg));
  If HasBorder(I) And ((WStyle[I] And WS_MINIMIZED) = 0) Then BoxPS(K, 0, 0, WCX[I], WCY[I], A, Act);
  EndP(K);
End;

Function FrameProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var H, C, J, Ti, R, N : LongInt; Tr : Array[0..19] Of LongInt;
Begin
  FrameProc := 0;
  H := HwOf(I);
  Case Msg Of
    WM_CREATE :
      If Mp1 <> 0 Then CreateFrameCtls(I, RdL(Mp1 + 2), RdW(Mp1 + 6), RdW(Mp1 + 8));
    WM_PAINT :
      FramePaint(I);
    WM_SIZE, WM_UPDATEFRAME :
      Begin
        Dummy := FormatFrameI(I, 0, 0);
        If Msg = WM_UPDATEFRAME Then
        Begin
          InvalWin(I);
          FrameProc := 1;
        End;
      End;
    WM_FORMATFRAME :
      FrameProc := WinFormatFrame(H, 0, Mp1, 64, Mp2);
    WM_QUERYFRAMECTLCOUNT :
      Begin
        N := 0;
        For J := 2 To MaxWin - 1 Do
          If (WUse[J] <> 0) And (WPar[J] = I) And (WId[J] >= $8001) And (WId[J] <= $8007) Then Inc(N);
        FrameProc := N;
      End;
    WM_CALCFRAMERECT :
      FrameProc := WinCalcFrameRect(H, Mp1, Mp2);
    WM_ACTIVATE :
      Begin
        Ti := ChildId(I, FID_TITLEBAR);
        If Ti > 1 Then Dummy := SendM(HwOf(Ti), TBM_SETHILITE, Lo16(Mp1), 0);
        InvalWin(I);
      End;
    WM_SETWINDOWPARAMS :
      Begin
        FrameProc := DefWP(H, Msg, Mp1, Mp2);
        Ti := ChildId(I, FID_TITLEBAR);
        If Ti > 1 Then
        Begin
          WTextSet(Ti, WTextGet(I));
          InvalWin(Ti);
        End;
      End;
    WM_CLOSE :
      Begin
        C := ChildId(I, FID_CLIENT);
        If C > 1 Then FrameProc := SendM(HwOf(C), WM_CLOSE, Mp1, Mp2)
        Else Dummy := LongInt(PostM(H, WM_QUIT, 0, 0));
      End;
    WM_COMMAND, WM_HELP, WM_CONTROL, WM_VSCROLL, WM_HSCROLL, WM_INITMENU, WM_MENUSELECT, WM_MENUEND :
      Begin
        C := ChildId(I, FID_CLIENT);
        If C > 1 Then FrameProc := SendM(HwOf(C), Msg, Mp1, Mp2);
      End;
    WM_SYSCOMMAND :
      Case Lo16(Mp1) Of
        SC_CLOSE : Dummy := LongInt(PostM(H, WM_CLOSE, 0, 0));
        SC_MINIMIZE : Dummy := WinSetWindowPos(H, 0, 0, 0, 0, 0, SWP_MINIMIZE);
        SC_MAXIMIZE : Dummy := WinSetWindowPos(H, 0, 0, 0, 0, 0, SWP_MAXIMIZE);
        SC_RESTORE : Dummy := WinSetWindowPos(H, 0, 0, 0, 0, 0, SWP_RESTORE);
        SC_MOVE, SC_SIZE :
          Begin
            For J := 0 To 19 Do Tr[J] := 0;
            Tr[0] := 8; Tr[1] := 16; Tr[2] := 8; Tr[3] := 16; Tr[4] := 8; Tr[5] := 16;
            If GMode <> 0 Then
            Begin
              Tr[0] := 4; Tr[1] := 4; Tr[2] := 1; Tr[3] := 1; Tr[4] := 8; Tr[5] := 8;
            End;
            Tr[6] := WX[I]; Tr[7] := WY[I]; Tr[8] := WX[I] + WCX[I]; Tr[9] := WY[I] + WCY[I];
            Tr[10] := 0; Tr[11] := 0; Tr[12] := WCX[WPar[I]]; Tr[13] := WCY[WPar[I]];
            Tr[14] := 80; Tr[15] := 48; Tr[16] := ScrCX; Tr[17] := ScrCY;
            If Lo16(Mp1) = SC_MOVE Then Tr[18] := $0F Or $80 Else Tr[18] := 4 Or 8 Or $80;
            If WinTrackRect(HwOf(WPar[I]), 0, LongInt(@Tr)) <> 0 Then
              Dummy := WinSetWindowPos(H, 0, Tr[6], Tr[7], Tr[8] - Tr[6], Tr[9] - Tr[7], SWP_MOVE Or SWP_SIZE);
          End;
        SC_APPMENU :
          Begin
            J := ChildId(I, FID_MENU);
            If J < 2 Then J := ChildId(I, FID_SYSMENU);
            If J > 1 Then MenuStart(J);
          End;
        SC_SYSMENU :
          Begin
            J := ChildId(I, FID_SYSMENU);
            If J > 1 Then
            Begin
              MenuStart(J);
              MenuOpenSub(J, 0);
            End;
          End;
      End;
    WM_CHAR :
      Begin
        R := 0;
        If ((Lo16(Mp1) And (KC_ALT Or KC_CHAR)) = (KC_ALT Or KC_CHAR)) And ((Lo16(Mp1) And KC_KEYUP) = 0) Then
        Begin
          J := ChildId(I, FID_MENU);
          If J > 1 Then
          Begin
            N := MenuMnem(J, Lo16(Mp2));
            If N >= 0 Then
            Begin
              MenuStart(J);
              MenuSelect(J, N, 0);
              R := 1;
            End;
          End;
        End;
        If R = 0 Then R := DefWP(H, Msg, Mp1, Mp2);
        FrameProc := R;
      End;
  Else
    FrameProc := DefWP(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Barre de titre                                                        }
{ ==================================================================== }
Function TitleProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var K, A, F, X, N, Dx, Dy : LongInt; S : String;
Begin
  TitleProc := 0;
  F := WPar[I];
  Case Msg Of
    WM_PAINT :
      Begin
        K := BeginP(I);
        If K >= 0 Then
        Begin
          If WS0[I] <> 0 Then A := Attr(-28, -23) Else A := Attr(-29, -22);
          If GMode <> 0 Then
          Begin
            GFillPS(K, 0, 0, WCX[I], WCY[I], (A Shr 4) And 15);
            GBevelPS(K, 0, 0, WCX[I], WCY[I], 15, 8, 1);
            S := WTextGet(I);
            N := MaxI((WCX[I] - 8) Div 8, 0);
            If Length(S) > N Then S := Copy(S, 1, N);
            X := MaxI((WCX[I] - Length(S) * 8) Div 2, 4);
            GTextPS(K, X, (WCY[I] - 16) Div 2, S, N, A And 15, 0, False, False);
            EndP(K);
            Exit;
          End;
          FillPS(K, 0, 0, WCX[I], WCY[I], 32, A);
          S := WTextGet(I);
          N := WCX[I] Div 8;
          If Length(S) > N Then S := Copy(S, 1, N);
          X := ((N - Length(S)) Div 2) * 8;
          TextPS(K, X, WCY[I] - 16, N, S, A, A, False);
          EndP(K);
        End;
      End;
    TBM_SETHILITE :
      Begin
        If WS0[I] <> Mp1 Then
        Begin
          WS0[I] := Mp1;
          InvalWin(I);
        End;
        TitleProc := 1;
      End;
    TBM_QUERYHILITE :
      TitleProc := WS0[I];
    WM_BUTTON1DOWN :
      Begin
        If F > 1 Then Dummy := WinSetActiveWindow(HWND_DESKTOP, HwOf(TopFrame(F)));
        WS1[I] := 1; WS2[I] := MouseX; WS3[I] := MouseY;
        CaptureWin := I;
        TitleProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        If (WS1[I] <> 0) And (CaptureWin = I) And (F > 1) Then
        Begin
          Dx := MouseX - WS2[I]; Dy := MouseY - WS3[I];
          If ((Dx <> 0) Or (Dy <> 0)) And ((WStyle[F] And WS_MAXIMIZED) = 0) Then
          Begin
            Dummy := WinSetWindowPos(HwOf(F), 0, WX[F] + Dx, WY[F] + Dy, 0, 0, SWP_MOVE);
            WS2[I] := MouseX; WS3[I] := MouseY;
          End;
        End;
        TitleProc := 1;
      End;
    WM_BUTTON1UP :
      Begin
        WS1[I] := 0;
        If CaptureWin = I Then CaptureWin := 0;
        TitleProc := 1;
      End;
    WM_BUTTON1DBLCLK :
      Begin
        If F > 1 Then
        Begin
          If (WStyle[F] And WS_MAXIMIZED) <> 0 Then Dummy := SendM(HwOf(F), WM_SYSCOMMAND, SC_RESTORE, Mk2(CMDSRC_OTHER, 1))
          Else Dummy := SendM(HwOf(F), WM_SYSCOMMAND, SC_MAXIMIZE, Mk2(CMDSRC_OTHER, 1));
        End;
        TitleProc := 1;
      End;
    WM_SETWINDOWPARAMS :
      Begin
        TitleProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
        InvalWin(I);
      End;
  Else
    TitleProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Statique                                                              }
{ ==================================================================== }
Function StaticProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var K, A, Fg, Bg, Typ : LongInt; S : String;
Begin
  StaticProc := 0;
  Case Msg Of
    WM_PAINT :
      Begin
        K := BeginP(I);
        If K >= 0 Then
        Begin
          Typ := WStyle[I] And $3F;
          Fg := PPColor(I, 1, -26); Bg := PPColor(I, 3, CtlBg(I));
          If (WStyle[I] And WS_DISABLED) <> 0 Then Fg := 8;
          A := Attr(Fg, Bg);
          S := WTextGet(I);
          Case Typ Of
            SS_GROUPBOX :
              If GMode <> 0 Then
              Begin
                GFramePS(K, 0, 0, WCX[I] - 1, WCY[I] - 8, 8);
                GFramePS(K, 1, 1, WCX[I], WCY[I] - 7, 15);
                If S <> '' Then GTextPS(K, 12, WCY[I] - 16, ' ' + S + ' ', MaxI(WCX[I] Div 8 - 3, 0), A And 15, (A Shr 4) And 15, True, True);
              End
              Else
              Begin
                BoxPS(K, 0, 0, WCX[I], WCY[I], A, False);
                If S <> '' Then TextPS(K, 16, WCY[I] - 16, MaxI(WCX[I] Div 8 - 4, 0), ' ' + S + ' ', A, MnA(A), True);
              End;
            SS_FGNDRECT : FillPS(K, 0, 0, WCX[I], WCY[I], 32, Attr(Fg, Fg));
            6 : FillPS(K, 0, 0, WCX[I], WCY[I], 177, A);
            SS_BKGNDRECT : FillPS(K, 0, 0, WCX[I], WCY[I], 32, A);
            SS_FGNDFRAME, 9, 10 : BoxPS(K, 0, 0, WCX[I], WCY[I], A, False);
            3, 4, 11 :
              Begin
                FillPS(K, 0, 0, WCX[I], WCY[I], 32, A);
                If GMode <> 0 Then GButtonPS(K, 0, 0, MinI(WCX[I], 32), MinI(WCY[I], 32), 7, False)
                Else TextPS(K, 0, WCY[I] - 16, 3, '[*]', A, A, False);
              End;
          Else
            Begin
              FillPS(K, 0, 0, WCX[I], WCY[I], 32, A);
              TextBox(K, S, WCX[I], WCY[I], WStyle[I] And $FF00, A);
            End;
          End;
          EndP(K);
        End;
      End;
    WM_SETWINDOWPARAMS :
      Begin
        StaticProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
        InvalWin(I);
      End;
    WM_MATCHMNEMONIC :
      If (MnemOf(WTextGet(I)) <> 0) And (MnemOf(WTextGet(I)) = UpCh(Mp1)) Then StaticProc := 1;
    WM_QUERYDLGCODE :
      StaticProc := $100;
  Else
    StaticProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Bouton                                                                }
{ ==================================================================== }
{ elements d'un dialogue dans l'ordre de creation (sans les controles du
  cadre) }
Function ItemFirst(P : LongInt) : LongInt;
Var J : LongInt;
Begin
  J := ChildTop(P);
  While (J > 1) And (WId[J] >= $8001) And (WId[J] <= $800F) Do J := SibNext(J, True);
  ItemFirst := J;
End;

Function ItemNext(J : LongInt) : LongInt;
Begin
  J := SibNext(J, True);
  While (J > 1) And (WId[J] >= $8001) And (WId[J] <= $800F) Do J := SibNext(J, True);
  ItemNext := J;
End;

Function GroupFirst(I : LongInt) : LongInt;
Var J, R, N : LongInt;
Begin
  R := ItemFirst(WPar[I]);
  J := R; N := 0;
  While (J > 1) And (J <> I) And (N < MaxWin) Do
  Begin
    J := ItemNext(J);
    If (J > 1) And ((WStyle[J] And WS_GROUP) <> 0) Then R := J;
    Inc(N);
  End;
  GroupFirst := R;
End;

Function GroupNext(J : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := ItemNext(J);
  If K > 1 Then
    If (WStyle[K] And WS_GROUP) <> 0 Then K := -1;
  If K <= 1 Then K := -1;
  GroupNext := K;
End;

Procedure BtnClick(I : LongInt);
Var T, J, N, Own : LongInt;
Begin
  If (WStyle[I] And WS_DISABLED) <> 0 Then Exit;
  T := WStyle[I] And $0F;
  If T = BS_AUTOCHECKBOX Then
  Begin
    If WS0[I] = 0 Then WS0[I] := 1 Else WS0[I] := 0;
  End
  Else If T = BS_AUTO3STATE Then WS0[I] := (WS0[I] + 1) Mod 3
  Else If T = BS_AUTORADIOBUTTON Then
  Begin
    J := GroupFirst(I); N := 0;
    While (J > 1) And (N < MaxWin) Do
    Begin
      If (J <> I) And (KindOf(J) = CK_BUTTON) And ((WStyle[J] And $0F) = BS_AUTORADIOBUTTON) And (WS0[J] <> 0) Then
      Begin
        WS0[J] := 0;
        InvalWin(J);
      End;
      J := GroupNext(J);
      Inc(N);
    End;
    WS0[I] := 1;
  End;
  InvalWin(I);
  Own := OwnerH(I);
  If (WStyle[I] And $100) <> 0 Then Dummy := SendM(Own, WM_HELP, WId[I], Mk2(CMDSRC_PUSHBUTTON, 0))
  Else If (WStyle[I] And $200) <> 0 Then Dummy := LongInt(PostM(Own, WM_SYSCOMMAND, WId[I], Mk2(CMDSRC_PUSHBUTTON, 0)))
  Else If T = BS_PUSHBUTTON Then Dummy := LongInt(PostM(Own, WM_COMMAND, WId[I], Mk2(CMDSRC_PUSHBUTTON, 0)))
  Else Notify(I, BN_CLICKED);
End;

{ ecran graphique : bouton poussoir, case a cocher, bouton radio }
Procedure GButtonPaint(I, K : LongInt);
Var T, Fg, Bg, Tw, X, Y, Cy, X2, Y2, Ins : LongInt; S : String; Foc, Dn, Dis : Boolean;
Begin
  T := WStyle[I] And $0F;
  Foc := FocusWin = I; Dn := WS1[I] <> 0; Dis := (WStyle[I] And WS_DISABLED) <> 0;
  S := WTextGet(I); Tw := GTextW(S, True);
  X2 := WCX[I]; Y2 := WCY[I];
  If (T = BS_PUSHBUTTON) Or (T = BS_USERBUTTON) Then
  Begin
    Bg := GCol(PPColor(I, 3, -40)); Fg := GCol(PPColor(I, 1, -17));
    If Dis Then Fg := 8;
    Ins := 0;
    If (WStyle[I] And BS_DEFAULT) <> 0 Then
    Begin
      GFramePS(K, 0, 0, X2, Y2, 0);
      Ins := 1;
    End;
    GButtonPS(K, Ins, Ins, X2 - Ins, Y2 - Ins, Bg, Dn);
    X := (X2 - Tw) Div 2; Y := (Y2 - 16) Div 2;
    If Dn Then
    Begin
      Inc(X); Dec(Y);
    End;
    GTextPS(K, X, Y, S, 255, Fg, Bg, False, True);
    If Foc Then GDotPS(K, MaxI(X - 3, 3), MaxI(Y - 1, 3), MinI(X + Tw + 3, X2 - 3), MinI(Y + 17, Y2 - 3), 0);
  End
  Else
  Begin
    Bg := GCol(PPColor(I, 3, CtlBg(I))); Fg := GCol(PPColor(I, 1, -26));
    If Dis Then Fg := 8;
    GFillPS(K, 0, 0, X2, Y2, Bg);
    Cy := Y2 Div 2;
    If (T = BS_RADIOBUTTON) Or (T = BS_AUTORADIOBUTTON) Then
    Begin
      GDiscPS(K, 7, Cy, 6, 8); GDiscPS(K, 7, Cy, 5, 15);
      If WS0[I] <> 0 Then GDiscPS(K, 7, Cy, 2, 0);
    End
    Else
    Begin
      GFillPS(K, 1, Cy - 6, 14, Cy + 7, 15);
      GSunkenPS(K, 1, Cy - 6, 14, Cy + 7);
      If WS0[I] = 2 Then GFillPS(K, 4, Cy - 3, 11, Cy + 4, 8)
      Else If WS0[I] <> 0 Then
      Begin
        GLinePS(K, 4, Cy, 6, Cy - 3, 0); GLinePS(K, 6, Cy - 3, 11, Cy + 3, 0);
        GLinePS(K, 4, Cy + 1, 6, Cy - 2, 0); GLinePS(K, 6, Cy - 2, 11, Cy + 4, 0);
      End;
    End;
    X := 20; Y := Cy - 8;
    GTextPS(K, X, Y, S, MaxI((X2 - X) Div 8, 0), Fg, Bg, False, True);
    If Foc Then GDotPS(K, X - 2, MaxI(Y - 1, 0), MinI(X + Tw + 2, X2), MinI(Y + 17, Y2), 0);
  End;
End;

Function ButtonProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var K, A, AT, T, Bg, Fg, Y, N, X, J, C : LongInt; S, M : String; Foc : Boolean;
Begin
  ButtonProc := 0;
  T := WStyle[I] And $0F;
  Case Msg Of
    WM_PAINT :
      Begin
        K := BeginP(I);
        If (K >= 0) And (GMode <> 0) Then
        Begin
          GButtonPaint(I, K);
          EndP(K);
        End
        Else If K >= 0 Then
        Begin
          Foc := FocusWin = I;
          S := WTextGet(I);
          Y := (WCY[I] + 16) Div 2 - 16;
          N := WCX[I] Div 8;
          If (T = BS_PUSHBUTTON) Or (T = BS_USERBUTTON) Then
          Begin
            Bg := PPColor(I, 3, -40); Fg := PPColor(I, 1, -17);
            If Foc Or (WS1[I] <> 0) Then Fg := -2;
            If (WStyle[I] And WS_DISABLED) <> 0 Then Fg := 8;
            A := Attr(Fg, Bg);
            FillPS(K, 0, 0, WCX[I], WCY[I], 32, A);
            If (WStyle[I] And BS_DEFAULT) <> 0 Then
            Begin
              CharPS(K, 0, Y, 16, A); CharPS(K, (N - 1) * 8, Y, 17, A);
            End
            Else
            Begin
              CharPS(K, 0, Y, 91, A); CharPS(K, (N - 1) * 8, Y, 93, A);
            End;
            X := MaxI(((N - VisLen(S)) Div 2) * 8, 8);
            TextPS(K, X, Y, MaxI(N - 2, 0), S, A, MnA(A), True);
          End
          Else
          Begin
            Bg := PPColor(I, 3, CtlBg(I)); Fg := PPColor(I, 1, -26);
            If (WStyle[I] And WS_DISABLED) <> 0 Then Fg := 8;
            A := Attr(Fg, Bg);
            FillPS(K, 0, 0, WCX[I], WCY[I], 32, A);
            If (T = BS_RADIOBUTTON) Or (T = BS_AUTORADIOBUTTON) Then
            Begin
              If WS0[I] <> 0 Then M := '(*)' Else M := '( )';
            End
            Else If WS0[I] = 2 Then M := '[?]'
            Else If WS0[I] <> 0 Then M := '[X]'
            Else M := '[ ]';
            TextPS(K, 0, Y, 3, M, A, A, False);
            If Foc Then AT := Attr(-33, -32) Else AT := A;
            TextPS(K, 32, Y, MaxI(N - 4, 0), S, AT, MnA(AT), True);
          End;
          EndP(K);
        End;
      End;
    BM_CLICK :
      BtnClick(I);
    BM_QUERYCHECK :
      ButtonProc := WS0[I];
    BM_SETCHECK :
      Begin
        ButtonProc := WS0[I];
        If WS0[I] <> (Mp1 And 3) Then
        Begin
          WS0[I] := Mp1 And 3;
          InvalWin(I);
        End;
      End;
    BM_QUERYHILITE :
      ButtonProc := WS1[I];
    BM_SETHILITE :
      Begin
        ButtonProc := WS1[I];
        WS1[I] := Mp1;
        InvalWin(I);
      End;
    BM_SETDEFAULT :
      Begin
        If Mp1 <> 0 Then WStyle[I] := WStyle[I] Or BS_DEFAULT Else WStyle[I] := WStyle[I] And Not BS_DEFAULT;
        InvalWin(I);
        ButtonProc := 1;
      End;
    BM_QUERYCHECKINDEX :
      Begin
        ButtonProc := -1;
        J := GroupFirst(I); N := 0; C := 0;
        While (J > 1) And (N < MaxWin) Do
        Begin
          If KindOf(J) = CK_BUTTON Then
          Begin
            If WS0[J] <> 0 Then
            Begin
              ButtonProc := C;
              J := -1;
            End
            Else Inc(C);
          End;
          If J > 1 Then J := GroupNext(J);
          Inc(N);
        End;
      End;
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
      Begin
        If (WStyle[I] And WS_DISABLED) = 0 Then
        Begin
          If FocusWin <> I Then FocusTo(I);
          WS1[I] := 1;
          CaptureWin := I;
          InvalWin(I);
        End;
        ButtonProc := 1;
      End;
    WM_BUTTON1UP :
      Begin
        If WS1[I] <> 0 Then
        Begin
          WS1[I] := 0;
          If CaptureWin = I Then CaptureWin := 0;
          InvalWin(I);
          If (SLo(Mp1) >= 0) And (SLo(Mp1) < WCX[I]) And (SHi(Mp1) >= 0) And (SHi(Mp1) < WCY[I]) Then BtnClick(I);
        End;
        ButtonProc := 1;
      End;
    WM_CHAR :
      Begin
        If ((Lo16(Mp1) And KC_KEYUP) = 0) And
           ((((Lo16(Mp1) And KC_CHAR) <> 0) And (Lo16(Mp2) = 32)) Or
            ((T = BS_PUSHBUTTON) And ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And
             ((Hi16(Mp2) = VK_NEWLINE) Or (Hi16(Mp2) = VK_ENTER)))) Then
        Begin
          BtnClick(I);
          ButtonProc := 1;
        End
        Else ButtonProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
      End;
    WM_SETFOCUS, WM_ENABLE :
      InvalWin(I);
    WM_SETWINDOWPARAMS :
      Begin
        ButtonProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
        InvalWin(I);
      End;
    WM_MATCHMNEMONIC :
      If (MnemOf(WTextGet(I)) <> 0) And (MnemOf(WTextGet(I)) = UpCh(Mp1)) Then ButtonProc := 1;
    WM_QUERYDLGCODE :
      Begin
        If T = BS_PUSHBUTTON Then
        Begin
          If (WStyle[I] And BS_DEFAULT) <> 0 Then ButtonProc := $80 Or $10 Or $20 Else ButtonProc := $80 Or $10;
        End
        Else If (T = BS_RADIOBUTTON) Or (T = BS_AUTORADIOBUTTON) Then ButtonProc := $80 Or 4
        Else If T = BS_USERBUTTON Then ButtonProc := $80
        Else ButtonProc := $80 Or 2;
      End;
  Else
    ButtonProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Champ de saisie (et texte multiligne)                                 }
{ WS0 curseur (fin de selection), WS1 limite, WS2 premier caractere   }
{ visible, WS3 modifie, WS4 debut de selection                         }
{ ==================================================================== }
{ marge du texte d'un champ (ecran graphique : bordure en creux) }
Function EfM(I : LongInt) : LongInt;
Begin
  If GMode <> 0 Then EfM := 3 Else EfM := 0;
End;

{ colonnes et lignes visibles }
Function EfCols(I : LongInt) : LongInt;
Begin
  EfCols := MaxI((WCX[I] - 2 * EfM(I)) Div 8, 1);
End;

Function EfRows(I : LongInt) : LongInt;
Begin
  EfRows := MaxI((WCY[I] - 2 * EfM(I)) Div 16, 1);
End;

Function EfY(I : LongInt) : LongInt;
Begin
  If KindOf(I) = CK_MLE Then EfY := WCY[I] - 16 - EfM(I) Else EfY := (WCY[I] - 16) Div 2;
End;

{ position (colonne, ligne) du caractere P dans un texte multiligne de
  largeur W }
Procedure MlePos(S : String; W, P : LongInt; Var C, R : LongInt);
Var J : LongInt;
Begin
  C := 0; R := 0;
  For J := 1 To MinI(P, Length(S)) Do
  Begin
    If Ord(S[J]) = 10 Then
    Begin
      C := 0; Inc(R);
    End
    Else
    Begin
      Inc(C);
      If C >= W Then
      Begin
        C := 0; Inc(R);
      End;
    End;
  End;
End;

Procedure EfCursor(I : LongInt);
Var C, R : LongInt;
Begin
  If FocusWin <> I Then Exit;
  If KindOf(I) = CK_MLE Then
  Begin
    MlePos(WTextGet(I), EfCols(I), WS0[I], C, R);
    R := R - WS2[I];
    If GMode <> 0 Then Dummy := WinCreateCursor(HwOf(I), EfM(I) + C * 8, EfY(I) - 16 * R, 2, 16, $8000, 0)
    Else Dummy := WinCreateCursor(HwOf(I), C * 8, WCY[I] - 16 * (R + 1), 8, 16, $8000, 0);
  End
  Else If GMode <> 0 Then Dummy := WinCreateCursor(HwOf(I), EfM(I) + (WS0[I] - WS2[I]) * 8, EfY(I), 2, 16, $8000, 0)
  Else Dummy := WinCreateCursor(HwOf(I), (WS0[I] - WS2[I]) * 8, EfY(I), 8, 16, $8000, 0);
End;

{ faire voir le curseur }
Procedure EfScroll(I : LongInt);
Var N, C, R : LongInt;
Begin
  If KindOf(I) = CK_MLE Then
  Begin
    MlePos(WTextGet(I), EfCols(I), WS0[I], C, R);
    N := EfRows(I);
    If R < WS2[I] Then WS2[I] := R;
    If R >= WS2[I] + N Then WS2[I] := R - N + 1;
  End
  Else
  Begin
    N := EfCols(I);
    If WS0[I] < WS2[I] Then WS2[I] := WS0[I];
    If WS0[I] - WS2[I] >= N Then WS2[I] := WS0[I] - N + 1;
  End;
End;

Procedure EfChanged(I : LongInt; S : String);
Begin
  WTextSet(I, S);
  WS3[I] := 1;
  EfScroll(I);
  InvalWin(I);
  EfCursor(I);
  Notify(I, EN_CHANGE);
End;

{ supprimer la selection ; vrai s'il y en avait une }
Function EfDelSel(I : LongInt; Var S : String) : Boolean;
Var A, B : LongInt;
Begin
  A := MinI(WS4[I], WS0[I]); B := MaxI(WS4[I], WS0[I]);
  B := MinI(B, Length(S)); A := MinI(A, B);
  EfDelSel := A < B;
  If A < B Then
  Begin
    Delete(S, A + 1, B - A);
    WS0[I] := A; WS4[I] := A;
  End;
End;

Function EfSelText(I : LongInt) : String;
Var A, B : LongInt; S : String;
Begin
  S := WTextGet(I);
  A := MinI(WS4[I], WS0[I]); B := MinI(MaxI(WS4[I], WS0[I]), Length(S));
  If A < B Then EfSelText := Copy(S, A + 1, B - A) Else EfSelText := '';
End;

Procedure EfInsert(I : LongInt; T : String);
Var S : String;
Begin
  S := WTextGet(I);
  Dummy := LongInt(EfDelSel(I, S));
  If Length(S) + Length(T) > WS1[I] Then T := Copy(T, 1, MaxI(WS1[I] - Length(S), 0));
  If T = '' Then
  Begin
    EfChanged(I, S);
    Exit;
  End;
  Insert(T, S, WS0[I] + 1);
  WS0[I] := WS0[I] + Length(T);
  WS4[I] := WS0[I];
  EfChanged(I, S);
End;

Procedure EfPaint(I : LongInt);
Var K, A, ASel, N, J, X, Y, C, R, Rows, W, Ch : LongInt; S : String; Foc, Mle : Boolean;
Begin
  K := BeginP(I);
  If K < 0 Then Exit;
  Mle := KindOf(I) = CK_MLE;
  A := Attr(PPColor(I, 1, -17), PPColor(I, 3, -47));
  If (WStyle[I] And WS_DISABLED) <> 0 Then A := (A And $F0) Or 8;
  ASel := Attr(-33, -32);
  FillPS(K, 0, 0, WCX[I], WCY[I], 32, A);
  If GMode <> 0 Then GSunkenPS(K, 0, 0, WCX[I], WCY[I]);
  S := WTextGet(I);
  Foc := FocusWin = I;
  W := EfCols(I);
  If Mle Then
  Begin
    Rows := EfRows(I);
    C := 0; R := 0;
    For J := 1 To Length(S) Do
    Begin
      Ch := Ord(S[J]);
      If Ch = 10 Then
      Begin
        C := 0; Inc(R);
      End
      Else
      Begin
        If (R >= WS2[I]) And (R < WS2[I] + Rows) Then
        Begin
          If Foc And (J - 1 >= MinI(WS4[I], WS0[I])) And (J - 1 < MaxI(WS4[I], WS0[I])) Then
            CharPS(K, EfM(I) + C * 8, WCY[I] - EfM(I) - 16 * (R - WS2[I] + 1), Ch, ASel)
          Else CharPS(K, EfM(I) + C * 8, WCY[I] - EfM(I) - 16 * (R - WS2[I] + 1), Ch, A);
        End;
        Inc(C);
        If C >= W Then
        Begin
          C := 0; Inc(R);
        End;
      End;
    End;
  End
  Else
  Begin
    Y := EfY(I);
    N := W;
    For J := 0 To N - 1 Do
      If WS2[I] + J < Length(S) Then
      Begin
        Ch := Ord(S[WS2[I] + J + 1]);
        If (WStyle[I] And ES_UNREADABLE) <> 0 Then Ch := 42;
        X := EfM(I) + J * 8;
        If Foc And (WS2[I] + J >= MinI(WS4[I], WS0[I])) And (WS2[I] + J < MaxI(WS4[I], WS0[I])) Then
          CharPS(K, X, Y, Ch, ASel)
        Else CharPS(K, X, Y, Ch, A);
      End;
  End;
  EndP(K);
End;

Function EntryProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Ch, Vk, A, B : LongInt; S : String; Ro, Mle : Boolean;
Begin
  EntryProc := 0;
  Mle := KindOf(I) = CK_MLE;
  Ro := (WStyle[I] And ES_READONLY) <> 0;
  Case Msg Of
    WM_CREATE :
      Begin
        If Mle Then WS1[I] := 255 Else WS1[I] := 32;
        If (Mp1 <> 0) And Not Mle Then
        Begin
          WS1[I] := MaxI(1, MinI(RdW(Mp1 + 2), 255));
          WS4[I] := RdW(Mp1 + 4); WS0[I] := RdW(Mp1 + 6);
        End;
        S := WTextGet(I);
        WS0[I] := MinI(WS0[I], Length(S)); WS4[I] := MinI(WS4[I], Length(S));
      End;
    WM_PAINT :
      EfPaint(I);
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := Hi16(Mp2);
        If (Fl And KC_KEYUP) <> 0 Then
        Begin
          EntryProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
          Exit;
        End;
        S := WTextGet(I);
        EntryProc := 1;
        If ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk <> VK_SPACE) Or ((Fl And KC_CHAR) = 0)) And
           Not (Mle And ((Vk = VK_NEWLINE) Or (Vk = VK_ENTER))) Then
        Begin
          If Vk = VK_LEFT Then
          Begin
            If WS0[I] > 0 Then Dec(WS0[I]);
            WS4[I] := WS0[I];
          End
          Else If Vk = VK_RIGHT Then
          Begin
            If WS0[I] < Length(S) Then Inc(WS0[I]);
            WS4[I] := WS0[I];
          End
          Else If Vk = VK_HOME Then
          Begin
            WS0[I] := 0; WS4[I] := 0;
          End
          Else If Vk = VK_END Then
          Begin
            WS0[I] := Length(S); WS4[I] := WS0[I];
          End
          Else If (Vk = VK_BACKSPACE) And Not Ro Then
          Begin
            If Not EfDelSel(I, S) Then
              If WS0[I] > 0 Then
              Begin
                Delete(S, WS0[I], 1);
                Dec(WS0[I]);
                WS4[I] := WS0[I];
              End;
            EfChanged(I, S);
          End
          Else If (Vk = VK_DELETE) And Not Ro Then
          Begin
            If Not EfDelSel(I, S) Then
              If WS0[I] < Length(S) Then Delete(S, WS0[I] + 1, 1);
            EfChanged(I, S);
          End
          Else If Vk = VK_INSERT Then
          Begin
            If SysVal[59] <> 0 Then SysVal[59] := 0 Else SysVal[59] := 1;
          End
          Else
          Begin
            EntryProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
            Exit;
          End;
          EfScroll(I);
          InvalWin(I);
          EfCursor(I);
        End
        Else If (((Fl And KC_CHAR) <> 0) And (Ch >= 32) And ((Fl And (KC_CTRL Or KC_ALT)) = 0)) Or
                (Mle And ((Vk = VK_NEWLINE) Or (Vk = VK_ENTER))) Then
        Begin
          If Ro Then Exit;
          If Mle And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_NEWLINE) Or (Vk = VK_ENTER)) Then Ch := 10;
          If (SysVal[59] = 0) And (WS0[I] = WS4[I]) And (WS0[I] < Length(S)) Then
          Begin
            S[WS0[I] + 1] := Chr(Ch);
            Inc(WS0[I]);
            WS4[I] := WS0[I];
            EfChanged(I, S);
          End
          Else EfInsert(I, Chr(Ch));
        End
        Else EntryProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
      End;
    EM_QUERYCHANGED :
      Begin
        EntryProc := WS3[I];
        WS3[I] := 0;
      End;
    EM_QUERYSEL :
      EntryProc := Mk2(MinI(WS4[I], WS0[I]), MaxI(WS4[I], WS0[I]));
    EM_SETSEL :
      Begin
        S := WTextGet(I);
        A := Lo16(Mp1); B := Hi16(Mp1);
        WS4[I] := MinI(A, Length(S)); WS0[I] := MinI(B, Length(S));
        EfScroll(I);
        InvalWin(I);
        EfCursor(I);
        EntryProc := 1;
      End;
    EM_SETTEXTLIMIT :
      Begin
        WS1[I] := MaxI(1, MinI(Lo16(Mp1), 255));
        EntryProc := 1;
      End;
    EM_CUT, EM_COPY, EM_CLEAR :
      Begin
        If (Msg <> EM_CLEAR) And (EfSelText(I) <> '') Then ClipPutText(EfSelText(I));
        If (Msg <> EM_COPY) And Not Ro Then
        Begin
          S := WTextGet(I);
          If EfDelSel(I, S) Then EfChanged(I, S);
        End;
        EntryProc := 1;
      End;
    EM_PASTE :
      Begin
        If Not Ro Then EfInsert(I, ClipGetText);
        EntryProc := 1;
      End;
    EM_QUERYFIRSTCHAR :
      EntryProc := WS2[I];
    EM_SETFIRSTCHAR :
      Begin
        WS2[I] := MaxI(Mp1, 0);
        InvalWin(I);
        EfCursor(I);
        EntryProc := 1;
      End;
    EM_QUERYREADONLY :
      If Ro Then EntryProc := 1;
    EM_SETREADONLY :
      Begin
        If Ro Then EntryProc := 1;
        If Mp1 <> 0 Then WStyle[I] := WStyle[I] Or ES_READONLY Else WStyle[I] := WStyle[I] And Not ES_READONLY;
      End;
    EM_SETINSERTMODE :
      Begin
        EntryProc := SysVal[59];
        SysVal[59] := Mp1;
      End;
    WM_SETWINDOWPARAMS :
      Begin
        EntryProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
        If (Mp1 <> 0) And ((RdL(Mp1) And 1) <> 0) Then
        Begin
          WS0[I] := 0; WS4[I] := 0; WS2[I] := 0;
          EfChanged(I, WTextGet(I));
        End;
      End;
    WM_SETFOCUS :
      Begin
        If Mp2 <> 0 Then
        Begin
          Dummy := WinCreateCursor(HwOf(I), 0, EfY(I), 8, 16, 0, 0);
          EfCursor(I);
          Dummy := WinShowCursor(HwOf(I), 1);
          Notify(I, EN_SETFOCUS);
        End
        Else
        Begin
          Dummy := WinDestroyCursor(HwOf(I));
          Notify(I, EN_KILLFOCUS);
        End;
        InvalWin(I);
      End;
    WM_BUTTON1DOWN :
      Begin
        If (WStyle[I] And WS_DISABLED) = 0 Then
        Begin
          If FocusWin <> I Then FocusTo(I);
          S := WTextGet(I);
          If Not Mle Then WS0[I] := MinI(WS2[I] + MaxI(SLo(Mp1) - EfM(I), 0) Div 8, Length(S));
          WS4[I] := WS0[I];
          InvalWin(I);
          EfCursor(I);
        End;
        EntryProc := 1;
      End;
    WM_ENABLE :
      InvalWin(I);
    WM_QUERYDLGCODE :
      If Mle Then EntryProc := $400 Else EntryProc := 1;
  Else
    EntryProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Liste (et liste deroulante)                                           }
{ liste : WS0 premier visible, WS1 article courant ;                   }
{ liste deroulante : WS5 article courant                               }
{ ==================================================================== }
{ marge et lignes visibles d'une liste (ecran graphique : bordure en creux) }
Function LM(I : LongInt) : LongInt;
Begin
  If GMode <> 0 Then LM := 2 Else LM := 0;
End;

Function LRows(I : LongInt) : LongInt;
Begin
  LRows := MaxI((WCY[I] - 2 * LM(I)) Div 16, 1);
End;

Function LCur(I : LongInt) : LongInt;
Begin
  If KindOf(I) = CK_COMBOBOX Then LCur := WS5[I] Else LCur := WS1[I];
End;

Procedure SetLCur(I, V : LongInt);
Var N : LongInt;
Begin
  If KindOf(I) = CK_COMBOBOX Then WS5[I] := V
  Else
  Begin
    WS1[I] := V;
    N := LRows(I);
    If V >= 0 Then
    Begin
      If V < WS0[I] Then WS0[I] := V;
      If V >= WS0[I] + N Then WS0[I] := V - N + 1;
    End;
  End;
End;

Function LSel(K : LongInt) : Boolean;
Begin
  LSel := (ItAttr[K] And 1) <> 0;
End;

{ selectionner l'article Ix (Sel) ; liste simple : un seul choisi }
Procedure LSelect(I, Ix : LongInt; Sel : Boolean);
Var K : LongInt;
Begin
  If ((WStyle[I] And (1 Or $10)) = 0) Or (Ix < 0) Then
    For K := 0 To MaxItem - 1 Do
      If ItWin[K] = I + 1 Then ItAttr[K] := ItAttr[K] And Not 1;
  K := ItAt(I, Ix);
  If K >= 0 Then
  Begin
    If Sel Then ItAttr[K] := ItAttr[K] Or 1 Else ItAttr[K] := ItAttr[K] And Not 1;
    SetLCur(I, Ix);
  End;
  If KindOf(I) = CK_COMBOBOX Then
  Begin
    If (K >= 0) And Sel Then
    Begin
      WTextSet(I, ItTextGet(K));
      WS0[I] := 0; WS4[I] := 0; WS2[I] := 0;
    End;
    InvalWin(I);
    Notify(I, 3);                     { CBN_LBSELECT }
  End
  Else
  Begin
    InvalWin(I);
    Notify(I, LN_SELECT);
  End;
End;

Function StrCmpCI(A, B : String) : LongInt;
Begin
  A := UpStr(A); B := UpStr(B);
  If A < B Then StrCmpCI := -1 Else If A > B Then StrCmpCI := 1 Else StrCmpCI := 0;
End;

Procedure ListPaint(I : LongInt);
Var K, A, ASel, R, Rows, Ix, It, Y, N : LongInt; Foc : Boolean;
Begin
  K := BeginP(I);
  If K < 0 Then Exit;
  A := Attr(PPColor(I, 1, -17), PPColor(I, 3, -20));
  ASel := Attr(-33, -32);
  FillPS(K, 0, 0, WCX[I], WCY[I], 32, A);
  If GMode <> 0 Then GSunkenPS(K, 0, 0, WCX[I], WCY[I]);
  Foc := FocusWin = I;
  Rows := LRows(I);
  N := (WCX[I] - 2 * LM(I)) Div 8;
  For R := 0 To Rows - 1 Do
  Begin
    Ix := WS0[I] + R;
    It := ItAt(I, Ix);
    If It >= 0 Then
    Begin
      Y := WCY[I] - LM(I) - 16 * (R + 1);
      If LSel(It) Then
      Begin
        FillPS(K, LM(I), Y, WCX[I] - LM(I), Y + 16, 32, ASel);
        TextPS(K, LM(I) + 8, Y, N - 1, ItTextGet(It), ASel, ASel, False);
      End
      Else TextPS(K, LM(I) + 8, Y, N - 1, ItTextGet(It), A, A, False);
      If Foc And (Ix = WS1[I]) Then
      Begin
        If GMode <> 0 Then GDotPS(K, LM(I), Y, WCX[I] - LM(I), Y + 16, (A And 15))
        Else CharPS(K, 0, Y, 16, A);
      End;
    End;
  End;
  EndP(K);
End;

Function ListProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var K, N, Ix, J, Cmd, St, R, Vk, Rows : LongInt; S, T : String; Ok : Boolean;
Begin
  ListProc := 0;
  N := ItCnt(I);
  Case Msg Of
    WM_CREATE :
      Begin
        WS1[I] := -1; WS5[I] := -1;
      End;
    WM_PAINT :
      ListPaint(I);
    LM_QUERYITEMCOUNT :
      ListProc := N;
    LM_INSERTITEM :
      Begin
        Ix := SLo(Mp1);
        S := GetZ(Mp2);
        If (Ix = -2) Or (Ix = -3) Then
        Begin
          J := 0;
          Ok := False;
          While (J < N) And Not Ok Do
          Begin
            T := ItTextGet(ItAt(I, J));
            If ((Ix = -2) And (StrCmpCI(S, T) < 0)) Or ((Ix = -3) And (StrCmpCI(S, T) > 0)) Then Ok := True
            Else Inc(J);
          End;
          Ix := J;
        End
        Else If (Ix < 0) Or (Ix > N) Then Ix := N;
        K := ItIns(I, Ix, S);
        If K < 0 Then ListProc := -2
        Else
        Begin
          If (LCur(I) >= Ix) Then SetLCur(I, LCur(I) + 1);
          InvalWin(I);
          ListProc := Ix;
        End;
      End;
    LM_DELETEITEM :
      Begin
        K := ItAt(I, SLo(Mp1));
        If K >= 0 Then
        Begin
          ItDel(K);
          If LCur(I) >= ItCnt(I) Then SetLCur(I, ItCnt(I) - 1);
          If WS0[I] > 0 Then
            If WS0[I] >= ItCnt(I) Then WS0[I] := MaxI(ItCnt(I) - 1, 0);
          InvalWin(I);
        End;
        ListProc := ItCnt(I);
      End;
    LM_DELETEALL :
      Begin
        FreeItemsOf(I);
        WS0[I] := 0;
        SetLCur(I, -1);
        InvalWin(I);
        ListProc := 1;
      End;
    LM_SETTOPINDEX :
      Begin
        If KindOf(I) <> CK_COMBOBOX Then WS0[I] := MaxI(0, MinI(SLo(Mp1), N - 1));
        InvalWin(I);
        ListProc := 1;
      End;
    LM_QUERYTOPINDEX :
      If N = 0 Then ListProc := -1 Else ListProc := WS0[I];
    LM_SELECTITEM :
      Begin
        LSelect(I, SLo(Mp1), Mp2 <> 0);
        ListProc := 1;
      End;
    LM_QUERYSELECTION :
      Begin
        R := -1;
        Ix := SLo(Mp1) + 1;
        If SLo(Mp1) < 0 Then Ix := 0;
        J := Ix;
        While (R < 0) And (J < N) Do
        Begin
          K := ItAt(I, J);
          If (K >= 0) And LSel(K) Then R := J;
          Inc(J);
        End;
        ListProc := R;
      End;
    LM_SETITEMTEXT :
      Begin
        K := ItAt(I, SLo(Mp1));
        If K >= 0 Then
        Begin
          ItTextSet(K, GetZ(Mp2));
          InvalWin(I);
          ListProc := 1;
        End;
      End;
    LM_QUERYITEMTEXTLENGTH :
      Begin
        K := ItAt(I, SLo(Mp1));
        If K >= 0 Then ListProc := Length(ItTextGet(K)) Else ListProc := -3;
      End;
    LM_QUERYITEMTEXT :
      Begin
        K := ItAt(I, SLo(Mp1));
        If K >= 0 Then ListProc := PutZN(Mp2, Hi16(Mp1), ItTextGet(K));
      End;
    LM_SETITEMHANDLE :
      Begin
        K := ItAt(I, SLo(Mp1));
        If K >= 0 Then
        Begin
          ItHandle[K] := Mp2;
          ListProc := 1;
        End;
      End;
    LM_QUERYITEMHANDLE :
      Begin
        K := ItAt(I, SLo(Mp1));
        If K >= 0 Then ListProc := ItHandle[K];
      End;
    LM_SEARCHSTRING :
      Begin
        Cmd := Lo16(Mp1); St := SHi(Mp1);
        S := GetZ(Mp2);
        If (Cmd And 4) = 0 Then S := UpStr(S);
        R := -1;
        If St < 0 Then St := -1;
        For J := 1 To N Do
          If R < 0 Then
          Begin
            Ix := (St + J) Mod N;
            T := ItTextGet(ItAt(I, Ix));
            If (Cmd And 4) = 0 Then T := UpStr(T);
            If (Cmd And 1) <> 0 Then Ok := Pos(S, T) > 0
            Else If (Cmd And 2) <> 0 Then Ok := Copy(T, 1, Length(S)) = S
            Else Ok := T = S;
            If Ok Then R := Ix;
          End;
        ListProc := R;
      End;
    WM_CHAR :
      Begin
        If ((Lo16(Mp1) And KC_KEYUP) <> 0) Or (KindOf(I) = CK_COMBOBOX) Then
        Begin
          ListProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
          Exit;
        End;
        Vk := 0;
        If (Lo16(Mp1) And KC_VIRTUALKEY) <> 0 Then Vk := Hi16(Mp2);
        Ix := WS1[I];
        Rows := LRows(I);
        ListProc := 1;
        If Vk = VK_UP Then Ix := Ix - 1
        Else If Vk = VK_DOWN Then Ix := Ix + 1
        Else If Vk = VK_HOME Then Ix := 0
        Else If Vk = VK_END Then Ix := N - 1
        Else If Vk = VK_PAGEUP Then Ix := Ix - Rows
        Else If Vk = VK_PAGEDOWN Then Ix := Ix + Rows
        Else If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
        Begin
          Notify(I, LN_ENTER);
          Exit;
        End
        Else If (Lo16(Mp2) = 32) And ((Lo16(Mp1) And KC_CHAR) <> 0) Then
        Begin
          K := ItAt(I, WS1[I]);
          If K >= 0 Then LSelect(I, WS1[I], Not LSel(K));
          Exit;
        End
        Else
        Begin
          ListProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
          Exit;
        End;
        If N > 0 Then
        Begin
          Ix := MaxI(0, MinI(Ix, N - 1));
          If (WStyle[I] And (1 Or $10)) = 0 Then LSelect(I, Ix, True)
          Else
          Begin
            SetLCur(I, Ix);
            InvalWin(I);
          End;
        End;
      End;
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
      Begin
        If FocusWin <> I Then FocusTo(I);
        Ix := WS0[I] + MaxI(WCY[I] - LM(I) - 1 - SHi(Mp1), 0) Div 16;
        K := ItAt(I, Ix);
        If K >= 0 Then
        Begin
          If Msg = WM_BUTTON1DBLCLK Then Notify(I, LN_ENTER)
          Else If (WStyle[I] And (1 Or $10)) <> 0 Then LSelect(I, Ix, Not LSel(K))
          Else LSelect(I, Ix, True);
        End;
        ListProc := 1;
      End;
    WM_SETFOCUS, WM_ENABLE :
      InvalWin(I);
    WM_QUERYDLGCODE :
      ListProc := 0;
  Else
    ListProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
  End;
End;

{ liste deroulante : champ de saisie et articles d'une liste }
Function ComboProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var K, Ix, N, Vk : LongInt;
Begin
  If (Msg >= LM_QUERYITEMCOUNT) And (Msg <= LM_DELETEALL) Then ComboProc := ListProc(I, Msg, Mp1, Mp2)
  Else If Msg = WM_CREATE Then
  Begin
    WS5[I] := -1;
    ComboProc := EntryProc(I, Msg, 0, Mp2);
  End
  Else If Msg = WM_PAINT Then
  Begin
    EfPaint(I);
    K := WinGetPS(HwOf(I));
    If K <> 0 Then
    Begin
      If GMode <> 0 Then
      Begin
        GButtonPS(K - $50530001, WCX[I] - 18, 2, WCX[I] - 2, WCY[I] - 2, 7, False);
        GArrowPS(K - $50530001, WCX[I] - 18, 2, WCX[I] - 2, WCY[I] - 2, 1, 0);
      End
      Else CharPS(K - $50530001, WCX[I] - 8, EfY(I), 25, Attr(-17, -40));
      Dummy := WinReleasePS(K);
    End;
    ComboProc := 0;
  End
  Else If (Msg = WM_CHAR) And ((Lo16(Mp1) And (KC_VIRTUALKEY Or KC_KEYUP)) = KC_VIRTUALKEY) And
          ((Hi16(Mp2) = VK_UP) Or (Hi16(Mp2) = VK_DOWN)) Then
  Begin
    N := ItCnt(I);
    Vk := Hi16(Mp2);
    Ix := WS5[I];
    If Vk = VK_UP Then Dec(Ix) Else Inc(Ix);
    If N > 0 Then
    Begin
      Ix := MaxI(0, MinI(Ix, N - 1));
      LSelect(I, Ix, True);
    End;
    ComboProc := 1;
  End
  Else ComboProc := EntryProc(I, Msg, Mp1, Mp2);
End;

{ ==================================================================== }
{ Barre de defilement : WS0 position, WS1 debut, WS2 fin, WS3 visible,  }
{ WS4 total                                                             }
{ ==================================================================== }
Function SbLen(I : LongInt) : LongInt;
Begin
  If (WStyle[I] And SBS_VERT) <> 0 Then SbLen := WCY[I] Div 16 Else SbLen := WCX[I] Div 8;
End;

Function SbThumb(I : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := SbLen(I);
  If (WS2[I] > WS1[I]) And (N > 3) Then SbThumb := 1 + ((WS0[I] - WS1[I]) * (N - 3)) Div (WS2[I] - WS1[I])
  Else SbThumb := 1;
End;

Procedure SbCell(K, I, C, Ch, A : LongInt);
Begin
  If (WStyle[I] And SBS_VERT) <> 0 Then CharPS(K, 0, WCY[I] - 16 * (C + 1), Ch, A)
  Else CharPS(K, C * 8, 0, Ch, A);
End;

{ ecran graphique : longueur L, fleches A, position Tp et taille Ts du
  curseur (pels le long de la barre, depuis le haut ou la gauche) }
Procedure SbGeom(I : LongInt; Var L, A, Tp, Ts : LongInt);
Var Tr, Rg : LongInt;
Begin
  If (WStyle[I] And SBS_VERT) <> 0 Then
  Begin
    L := WCY[I]; A := WCX[I];
  End
  Else
  Begin
    L := WCX[I]; A := WCY[I];
  End;
  A := MaxI(MinI(A, L Div 2), 0);
  Tr := MaxI(L - 2 * A, 0);
  If (WS3[I] > 0) And (WS4[I] > 0) Then Ts := MaxI(8, (Tr * WS3[I]) Div WS4[I]) Else Ts := MaxI(8, A);
  Ts := MinI(Ts, Tr);
  Rg := WS2[I] - WS1[I];
  If Rg > 0 Then Tp := A + ((Tr - Ts) * (WS0[I] - WS1[I])) Div Rg Else Tp := A;
End;

Procedure GSbPaint(I, K : LongInt);
Var L, A, Tp, Ts, X2, Y2, Dc : LongInt; Dis : Boolean;
Begin
  SbGeom(I, L, A, Tp, Ts);
  Dis := (WStyle[I] And WS_DISABLED) <> 0;
  X2 := WCX[I]; Y2 := WCY[I];
  GFillPS(K, 0, 0, X2, Y2, 7);
  If GPsClip(K) Then GFillPat(PsOrgX[K], PsOrgY[K], PsOrgX[K] + X2, PsOrgY[K] + Y2, 15, $AA, 0);
  If Dis Then Dc := 8 Else Dc := 0;
  If (WStyle[I] And SBS_VERT) <> 0 Then
  Begin
    GButtonPS(K, 0, Y2 - A, X2, Y2, 7, False); GArrowPS(K, 0, Y2 - A, X2, Y2, 0, Dc);
    GButtonPS(K, 0, 0, X2, A, 7, False); GArrowPS(K, 0, 0, X2, A, 1, Dc);
    If (Not Dis) And (Ts > 0) Then GButtonPS(K, 0, Y2 - Tp - Ts, X2, Y2 - Tp, 7, False);
  End
  Else
  Begin
    GButtonPS(K, 0, 0, A, Y2, 7, False); GArrowPS(K, 0, 0, A, Y2, 2, Dc);
    GButtonPS(K, X2 - A, 0, X2, Y2, 7, False); GArrowPS(K, X2 - A, 0, X2, Y2, 3, Dc);
    If (Not Dis) And (Ts > 0) Then GButtonPS(K, Tp, 0, Tp + Ts, Y2, 7, False);
  End;
End;

Procedure SbPaint(I : LongInt);
Var K, A, N, C, T : LongInt; V : Boolean;
Begin
  K := BeginP(I);
  If K < 0 Then Exit;
  If GMode <> 0 Then
  Begin
    GSbPaint(I, K);
    EndP(K);
    Exit;
  End;
  A := Attr(-17, -25);
  V := (WStyle[I] And SBS_VERT) <> 0;
  FillPS(K, 0, 0, WCX[I], WCY[I], 176, A);
  N := SbLen(I);
  T := SbThumb(I);
  If N >= 2 Then
  Begin
    If V Then
    Begin
      SbCell(K, I, 0, 30, A); SbCell(K, I, N - 1, 31, A);
    End
    Else
    Begin
      SbCell(K, I, 0, 17, A); SbCell(K, I, N - 1, 16, A);
    End;
    For C := 1 To N - 2 Do
      If (C = T) And ((WStyle[I] And WS_DISABLED) = 0) Then SbCell(K, I, C, 219, A);
  End;
  EndP(K);
End;

Procedure SbSend(I, Cmd : LongInt);
Var M : LongInt;
Begin
  If (WStyle[I] And SBS_VERT) <> 0 Then M := WM_VSCROLL Else M := WM_HSCROLL;
  Dummy := SendM(OwnerH(I), M, WId[I], Mk2(WS0[I], Cmd));
End;

Function ScrollProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var C, T, N, Vk, L, A, Tp, Ts : LongInt;
Begin
  ScrollProc := 0;
  Case Msg Of
    WM_PAINT :
      SbPaint(I);
    SBM_SETSCROLLBAR :
      Begin
        WS1[I] := SLo(Mp2); WS2[I] := SHi(Mp2);
        If WS2[I] < WS1[I] Then WS2[I] := WS1[I];
        WS0[I] := MaxI(WS1[I], MinI(SLo(Mp1), WS2[I]));
        InvalWin(I);
        ScrollProc := 1;
      End;
    SBM_SETPOS :
      Begin
        WS0[I] := MaxI(WS1[I], MinI(SLo(Mp1), WS2[I]));
        InvalWin(I);
        ScrollProc := 1;
      End;
    SBM_QUERYPOS :
      ScrollProc := WS0[I];
    SBM_QUERYRANGE :
      ScrollProc := Mk2(WS1[I], WS2[I]);
    SBM_SETTHUMBSIZE :
      Begin
        WS3[I] := Lo16(Mp1); WS4[I] := Hi16(Mp1);
        ScrollProc := 1;
      End;
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
      Begin
        If ((WStyle[I] And WS_DISABLED) = 0) And (GMode <> 0) Then
        Begin
          SbGeom(I, L, A, Tp, Ts);
          If (WStyle[I] And SBS_VERT) <> 0 Then C := WCY[I] - 1 - SHi(Mp1) Else C := SLo(Mp1);
          If C < A Then SbSend(I, SB_LINEUP)
          Else If C >= L - A Then SbSend(I, SB_LINEDOWN)
          Else If C < Tp Then SbSend(I, SB_PAGEUP)
          Else If C >= Tp + Ts Then SbSend(I, SB_PAGEDOWN)
          Else
          Begin
            { glisser le curseur }
            WS5[I] := C - Tp + 1;
            CaptureWin := I;
            ScrollProc := 1;
            Exit;
          End;
          SbSend(I, SB_ENDSCROLL);
        End
        Else If (WStyle[I] And WS_DISABLED) = 0 Then
        Begin
          N := SbLen(I);
          If (WStyle[I] And SBS_VERT) <> 0 Then C := (WCY[I] - 1 - SHi(Mp1)) Div 16 Else C := SLo(Mp1) Div 8;
          T := SbThumb(I);
          If C <= 0 Then SbSend(I, SB_LINEUP)
          Else If C >= N - 1 Then SbSend(I, SB_LINEDOWN)
          Else If C < T Then SbSend(I, SB_PAGEUP)
          Else If C > T Then SbSend(I, SB_PAGEDOWN);
          SbSend(I, SB_ENDSCROLL);
        End;
        ScrollProc := 1;
      End;
    WM_CHAR :
      Begin
        Vk := 0;
        If (Lo16(Mp1) And (KC_VIRTUALKEY Or KC_KEYUP)) = KC_VIRTUALKEY Then Vk := Hi16(Mp2);
        If (Vk = VK_UP) Or (Vk = VK_LEFT) Then SbSend(I, SB_LINEUP)
        Else If (Vk = VK_DOWN) Or (Vk = VK_RIGHT) Then SbSend(I, SB_LINEDOWN)
        Else If Vk = VK_PAGEUP Then SbSend(I, SB_PAGEUP)
        Else If Vk = VK_PAGEDOWN Then SbSend(I, SB_PAGEDOWN)
        Else
        Begin
          ScrollProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
          Exit;
        End;
        SbSend(I, SB_ENDSCROLL);
        ScrollProc := 1;
      End;
    WM_MOUSEMOVE :
      If (WS5[I] > 0) And (CaptureWin = I) Then
      Begin
        SbGeom(I, L, A, Tp, Ts);
        If (WStyle[I] And SBS_VERT) <> 0 Then C := WCY[I] - 1 - SHi(Mp1) Else C := SLo(Mp1);
        C := C - (WS5[I] - 1);
        If L - 2 * A - Ts > 0 Then N := WS1[I] + ((C - A) * (WS2[I] - WS1[I])) Div (L - 2 * A - Ts)
        Else N := WS1[I];
        N := MaxI(WS1[I], MinI(N, WS2[I]));
        If N <> WS0[I] Then
        Begin
          WS0[I] := N;
          InvalWin(I);
          SbSend(I, 5);
        End;
        ScrollProc := 1;
      End
      Else ScrollProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
    WM_BUTTON1UP :
      If WS5[I] > 0 Then
      Begin
        WS5[I] := 0;
        If CaptureWin = I Then CaptureWin := 0;
        SbSend(I, SB_SLIDERPOSITION);
        SbSend(I, SB_ENDSCROLL);
        ScrollProc := 1;
      End
      Else ScrollProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
    WM_ENABLE :
      InvalWin(I);
    WM_QUERYDLGCODE :
      ScrollProc := $40;
  Else
    ScrollProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Menu : WS0 article choisi, WS1 mode menu (racine), WS2 sous-menu      }
{ ouvert, WS3 menu qui l'a ouvert, WS4 focus a rendre                   }
{ ==================================================================== }
Function IsBar(I : LongInt) : Boolean;
Begin
  IsBar := (WStyle[I] And MS_ACTIONBAR) <> 0;
End;

{ largeur (pels) d'un article d'une barre }
Function MItemW(I, K : LongInt) : LongInt;
Begin
  If (ItStyle[K] And MIS_SEPARATOR) <> 0 Then MItemW := 8
  Else If (WId[I] = FID_SYSMENU) Or (WId[I] = FID_MINMAX) Then
  Begin
    If GMode <> 0 Then MItemW := TitleH Else MItemW := VisLen(ItTextGet(K)) * 8;
  End
  Else MItemW := (VisLen(ItTextGet(K)) + 2) * 8;
End;

{ position (pels) d'un article d'une barre }
Function MItemX(I, Ps : LongInt) : LongInt;
Var J, X, K : LongInt;
Begin
  X := 0;
  For J := 0 To Ps - 1 Do
  Begin
    K := ItAt(I, J);
    If K >= 0 Then X := X + MItemW(I, K);
  End;
  MItemX := X;
End;

Function MenuWidthPels(I : LongInt) : LongInt;
Var J, N, W, K : LongInt;
Begin
  N := ItCnt(I);
  If IsBar(I) Then MenuWidthPels := MItemX(I, N)
  Else
  Begin
    W := 4;
    For J := 0 To N - 1 Do
    Begin
      K := ItAt(I, J);
      If K >= 0 Then W := MaxI(W, VisLen(ItTextGet(K)) + 6);
    End;
    MenuWidthPels := MinI(W, 78) * 8;
  End;
End;

Function MenuHeightPels(I : LongInt) : LongInt;
Begin
  If IsBar(I) Then MenuHeightPels := MenuH Else MenuHeightPels := ItCnt(I) * MRowH + 2 * MPad;
End;

Function NewMenuWin(HPar, HOwn, Style, Id : LongInt) : LongInt;
Begin
  NewMenuWin := WIdx(WinCreateWindow(HPar, $FFFF0004, 0, Style, 0, 0, 0, 0, HOwn, HWND_TOP, Id, 0, 0));
End;

Procedure MAdd(M, Style, Id, Sub : LongInt; S : String);
Var K, J : LongInt;
Begin
  K := ItIns(M, -1, S);
  If K >= 0 Then
  Begin
    ItStyle[K] := Style; ItId[K] := Id; ItSub[K] := Sub;
    J := WIdx(Sub);
    If J > 1 Then
    Begin
      WOwner[J] := HwOf(M);
      WS3[J] := M;
    End;
  End;
End;

Function MenuOwner(R : LongInt) : LongInt;
Begin
  MenuOwner := OwnerH(R);
End;

Function MenuRoot(I : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  While (WS3[I] > 1) And (N < 16) Do
  Begin
    If (WUse[WS3[I]] = 0) Or (KindOf(WS3[I]) <> CK_MENU) Then N := 16
    Else
    Begin
      I := WS3[I];
      Inc(N);
    End;
  End;
  MenuRoot := I;
End;

{ position suivante choisissable (Dir +1 / -1) }
Function MenuNextSel(I, Ps, Dir : LongInt) : LongInt;
Var N, J, P, K, R : LongInt;
Begin
  N := ItCnt(I);
  R := -1;
  If N > 0 Then
  Begin
    P := Ps;
    For J := 1 To N Do
      If R < 0 Then
      Begin
        P := P + Dir;
        If P >= N Then P := 0;
        If P < 0 Then P := N - 1;
        K := ItAt(I, P);
        If (K >= 0) And ((ItStyle[K] And MIS_SEPARATOR) = 0) Then R := P;
      End;
  End;
  MenuNextSel := R;
End;

Function MenuFirstSel(I : LongInt) : LongInt;
Begin
  MenuFirstSel := MenuNextSel(I, -1, 1);
End;

Function MenuMnem(I, Ch : LongInt) : LongInt;
Var J, K, R : LongInt;
Begin
  R := -1;
  Ch := UpCh(Ch);
  For J := ItCnt(I) - 1 DownTo 0 Do
  Begin
    K := ItAt(I, J);
    If (K >= 0) And (MnemOf(ItTextGet(K)) = Ch) And (Ch <> 0) Then R := J;
  End;
  MenuMnem := R;
End;

{ fermer les sous-menus ouverts depuis I }
Procedure MenuCloseSub(I : LongInt);
Var S, N : LongInt;
Begin
  N := 0;
  S := WS2[I];
  If (S > 1) And (WUse[S] <> 0) Then
  Begin
    MenuCloseSub(S);
    Dummy := WinSetWindowPos(HwOf(S), 0, 0, 0, 0, 0, SWP_HIDE Or SWP_NOADJUST);
  End;
  WS2[I] := 0;
End;

Procedure MenuOpenSub(I, Ps : LongInt);
Var K, S, X, Y, Cx, Cy : LongInt;
Begin
  K := ItAt(I, Ps);
  If (K < 0) Or ((ItStyle[K] And MIS_SUBMENU) = 0) Then Exit;
  S := WIdx(ItSub[K]);
  If (S < 2) Or (S = I) Then Exit;
  If WS2[I] = S Then Exit;
  MenuCloseSub(I);
  Cx := MenuWidthPels(S); Cy := MenuHeightPels(S);
  If IsBar(I) Then
  Begin
    X := AbsX(I) + MItemX(I, Ps);
    Y := AbsY(I) - Cy;
  End
  Else
  Begin
    If GMode <> 0 Then X := AbsX(I) + WCX[I] - 4 Else X := AbsX(I) + WCX[I] - 16;
    Y := AbsY(I) + WCY[I] - MRowH * Ps - Cy;
  End;
  X := MaxI(0, MinI(X, ScrCX - Cx)); Y := MaxI(0, MinI(Y, ScrCY - Cy));
  WPar[S] := 0;
  WOwner[S] := HwOf(I);
  WS3[S] := I; WS2[S] := 0; WS1[S] := 0;
  WS0[S] := MenuFirstSel(S);
  WS2[I] := S;
  Dummy := SendM(MenuOwner(MenuRoot(I)), WM_INITMENU, ItId[K], HwOf(S));
  Dummy := WinSetWindowPos(HwOf(S), HWND_TOP, X, Y, Cx, Cy, SWP_MOVE Or SWP_SIZE Or SWP_SHOW Or SWP_ZORDER Or SWP_NOADJUST);
End;

Procedure MenuStart(R : LongInt);
Begin
  If WS1[R] <> 0 Then Exit;
  WS1[R] := 1;
  WS4[R] := FocusWin;
  FocusWin := R;
  CaptureWin := R;
  If WS0[R] < 0 Then WS0[R] := MenuFirstSel(R);
  Dummy := SendM(MenuOwner(R), WM_INITMENU, WId[R], HwOf(R));
  InvalWin(R);
End;

Procedure MenuEnd(R : LongInt);
Begin
  R := MenuRoot(R);
  MenuCloseSub(R);
  If WS1[R] = 0 Then Exit;
  WS1[R] := 0;
  If CaptureWin = R Then CaptureWin := 0;
  If FocusWin = R Then
  Begin
    FocusWin := WS4[R];
    If (FocusWin > 1) And (WUse[FocusWin] = 0) Then FocusWin := 0;
  End;
  If IsBar(R) Then WS0[R] := -1
  Else Dummy := WinSetWindowPos(HwOf(R), 0, 0, 0, 0, 0, SWP_HIDE Or SWP_NOADJUST);
  InvalWin(R);
  Dummy := SendM(MenuOwner(R), WM_MENUEND, WId[R], HwOf(R));
End;

Procedure MenuSelect(I, Ps, Mouse : LongInt);
Var K, R, O, Id, St, M : LongInt;
Begin
  K := ItAt(I, Ps);
  If K < 0 Then Exit;
  If (ItStyle[K] And MIS_SEPARATOR) <> 0 Then Exit;
  WS0[I] := Ps;
  InvalWin(I);
  If (ItAttr[K] And MIA_DISABLED) <> 0 Then Exit;
  If (ItStyle[K] And MIS_SUBMENU) <> 0 Then
  Begin
    MenuOpenSub(I, Ps);
    Exit;
  End;
  R := MenuRoot(I);
  O := MenuOwner(R);
  Id := ItId[K]; St := ItStyle[K];
  Dummy := SendM(O, WM_MENUSELECT, Mk2(Id, 1), HwOf(I));
  MenuEnd(R);
  If (St And MIS_SYSCOMMAND) <> 0 Then M := WM_SYSCOMMAND
  Else If (St And MIS_HELP) <> 0 Then M := WM_HELP
  Else M := WM_COMMAND;
  Dummy := LongInt(PostM(O, M, Id, Mk2(CMDSRC_MENU, Mouse)));
End;

{ article sous (x, y) relatif a la fenetre }
Function MenuHit(I, X, Y : LongInt) : LongInt;
Var J, N, K, C, Cx, R : LongInt;
Begin
  R := -1;
  N := ItCnt(I);
  If IsBar(I) Then
  Begin
    C := X; Cx := 0;
    For J := 0 To N - 1 Do
    Begin
      K := ItAt(I, J);
      If (K >= 0) And (R < 0) Then
      Begin
        If (C >= Cx) And (C < Cx + MItemW(I, K)) Then R := J;
        Cx := Cx + MItemW(I, K);
      End;
    End;
  End
  Else
  Begin
    If GMode <> 0 Then C := MPad Else C := 8;
    J := WCY[I] - MPad - 1 - Y;
    If J >= 0 Then J := J Div MRowH Else J := -1;
    If (J >= 0) And (J < N) And (X >= C) And (X < WCX[I] - C) Then R := J;
  End;
  If R >= 0 Then
  Begin
    K := ItAt(I, R);
    If (ItStyle[K] And MIS_SEPARATOR) <> 0 Then R := -1;
  End;
  MenuHit := R;
End;

{ ecran graphique : barre d'actions, menu deroulant, menu systeme et
  boutons de reduction et d'agrandissement }
Procedure GMenuPaint(I, K : LongInt);
Var J, N, X, W, It, Y, Fg, Bg, Hf, Hb, Df, C, Cx, Cy, Tb, F : LongInt; S, S2 : String; Act, Sel : Boolean;
Begin
  Fg := GCol(-18); Bg := GCol(-21); Hf := GCol(-45); Hb := GCol(-44); Df := GCol(-46);
  N := ItCnt(I);
  Act := (WS1[MenuRoot(I)] <> 0) Or Not IsBar(I);
  If (WId[I] = FID_SYSMENU) Or (WId[I] = FID_MINMAX) Then
  Begin
    F := WPar[I];
    X := 0;
    For J := 0 To N - 1 Do
    Begin
      It := ItAt(I, J);
      If It >= 0 Then
      Begin
        W := MItemW(I, It);
        Sel := Act And (WS0[I] = J);
        GButtonPS(K, X, 0, X + W, WCY[I], 7, Sel);
        Cx := X + W Div 2; Cy := WCY[I] Div 2;
        If Sel Then
        Begin
          Inc(Cx); Dec(Cy);
        End;
        Case ItId[It] Of
          SC_SYSMENU :
            Begin
              GFillPS(K, Cx - 5, Cy - 1, Cx + 6, Cy + 2, 15); GFramePS(K, Cx - 6, Cy - 2, Cx + 7, Cy + 3, 0);
            End;
          SC_MINIMIZE :
            GFramePS(K, Cx - 2, Cy - 2, Cx + 3, Cy + 3, 0);
          SC_MAXIMIZE, SC_RESTORE :
            If (F > 1) And ((WStyle[F] And WS_MAXIMIZED) <> 0) Then
            Begin
              GFramePS(K, Cx - 5, Cy - 5, Cx + 3, Cy + 3, 0); GFramePS(K, Cx - 2, Cy - 2, Cx + 6, Cy + 6, 0);
            End
            Else
            Begin
              GFramePS(K, Cx - 6, Cy - 6, Cx + 7, Cy + 7, 0); GFramePS(K, Cx - 6, Cy + 4, Cx + 7, Cy + 7, 0);
            End;
        Else
          GTextPS(K, X + (W - GTextW(ItTextGet(It), True)) Div 2, (WCY[I] - 16) Div 2, ItTextGet(It), 3, 0, 7, False, True);
        End;
        X := X + W;
      End;
    End;
    Exit;
  End;
  If IsBar(I) Then
  Begin
    GFillPS(K, 0, 0, WCX[I], WCY[I], Bg);
    GFillPS(K, 0, 0, WCX[I], 1, 8);
    X := 0;
    For J := 0 To N - 1 Do
    Begin
      It := ItAt(I, J);
      If It >= 0 Then
      Begin
        W := MItemW(I, It);
        If (ItStyle[It] And MIS_SEPARATOR) <> 0 Then GFillPS(K, X + 3, 3, X + 4, WCY[I] - 3, 8)
        Else
        Begin
          C := Fg;
          If (ItAttr[It] And MIA_DISABLED) <> 0 Then C := Df;
          If Act And (WS0[I] = J) Then
          Begin
            GFillPS(K, X, 1, X + W, WCY[I], Hb);
            C := Hf;
          End;
          GTextPS(K, X + 8, (WCY[I] - 16) Div 2, ItTextGet(It), W Div 8, C, Bg, False, True);
        End;
        X := X + W;
      End;
    End;
    Exit;
  End;
  { menu deroulant }
  GFillPS(K, 0, 0, WCX[I], WCY[I], Bg);
  GFramePS(K, 0, 0, WCX[I], WCY[I], 0);
  GBevelPS(K, 1, 1, WCX[I] - 1, WCY[I] - 1, 15, 8, 1);
  For J := 0 To N - 1 Do
  Begin
    It := ItAt(I, J);
    Y := WCY[I] - MPad - MRowH * (J + 1);
    If It >= 0 Then
    Begin
      If (ItStyle[It] And MIS_SEPARATOR) <> 0 Then
      Begin
        GFillPS(K, MPad + 3, Y + MRowH Div 2, WCX[I] - MPad - 3, Y + MRowH Div 2 + 1, 8);
        GFillPS(K, MPad + 3, Y + MRowH Div 2 - 1, WCX[I] - MPad - 3, Y + MRowH Div 2, 15);
      End
      Else
      Begin
        C := Fg; Tb := Bg;
        If (ItAttr[It] And MIA_DISABLED) <> 0 Then C := Df;
        If WS0[I] = J Then
        Begin
          GFillPS(K, MPad, Y, WCX[I] - MPad, Y + MRowH, Hb);
          C := Hf; Tb := Hb;
        End;
        If (ItAttr[It] And MIA_CHECKED) <> 0 Then
        Begin
          Cy := Y + MRowH Div 2;
          GLinePS(K, 5, Cy, 8, Cy - 3, C); GLinePS(K, 8, Cy - 3, 13, Cy + 3, C);
          GLinePS(K, 5, Cy + 1, 8, Cy - 2, C); GLinePS(K, 8, Cy - 2, 13, Cy + 4, C);
        End;
        S := ItTextGet(It); S2 := '';
        For X := Length(S) DownTo 1 Do
          If (S2 = '') And (Ord(S[X]) = 9) Then
          Begin
            S2 := Copy(S, X + 1, 255); S := Copy(S, 1, X - 1);
          End;
        GTextPS(K, 16, Y + (MRowH - 16) Div 2, S, MaxI((WCX[I] - 32) Div 8, 0), C, Tb, False, True);
        If S2 <> '' Then
          GTextPS(K, WCX[I] - 16 - GTextW(S2, True), Y + (MRowH - 16) Div 2, S2, 32, C, Tb, False, True);
        If (ItStyle[It] And MIS_SUBMENU) <> 0 Then GArrowPS(K, WCX[I] - 14, Y + 2, WCX[I] - 4, Y + MRowH - 2, 3, C);
      End;
    End;
  End;
End;

Procedure MenuPaint(I : LongInt);
Var K, A, AH, AD, J, N, X, Y, W, It, AA, Cw : LongInt; S : String; Act : Boolean;
Begin
  K := BeginP(I);
  If K < 0 Then Exit;
  If GMode <> 0 Then
  Begin
    GMenuPaint(I, K);
    EndP(K);
    Exit;
  End;
  A := Attr(-18, -21); AH := Attr(-45, -44); AD := (A And $F0) Or 8;
  FillPS(K, 0, 0, WCX[I], WCY[I], 32, A);
  N := ItCnt(I);
  Act := (WS1[MenuRoot(I)] <> 0) Or Not IsBar(I);
  If IsBar(I) Then
  Begin
    X := 0;
    For J := 0 To N - 1 Do
    Begin
      It := ItAt(I, J);
      If It >= 0 Then
      Begin
        W := MItemW(I, It);
        If Act And (WS0[I] = J) Then AA := AH
        Else If (ItAttr[It] And MIA_DISABLED) <> 0 Then AA := AD
        Else AA := A;
        If (ItStyle[It] And MIS_SEPARATOR) <> 0 Then CharPS(K, X, 0, 179, A)
        Else
        Begin
          FillPS(K, X, 0, X + W, 16, 32, AA);
          If (WId[I] = FID_SYSMENU) Or (WId[I] = FID_MINMAX) Then TextPS(K, X, 0, W Div 8, ItTextGet(It), AA, MnA(AA), True)
          Else TextPS(K, X + 8, 0, W Div 8 - 2, ItTextGet(It), AA, MnA(AA), True);
        End;
        X := X + W;
      End;
    End;
  End
  Else
  Begin
    BoxPS(K, 0, 0, WCX[I], WCY[I], A, False);
    Cw := WCX[I] Div 8;
    For J := 0 To N - 1 Do
    Begin
      It := ItAt(I, J);
      Y := WCY[I] - 16 * (J + 2);
      If It >= 0 Then
      Begin
        If (ItStyle[It] And MIS_SEPARATOR) <> 0 Then
        Begin
          FillPS(K, 8, Y, WCX[I] - 8, Y + 16, 196, A);
          CharPS(K, 0, Y, 195, A); CharPS(K, WCX[I] - 8, Y, 180, A);
        End
        Else
        Begin
          If WS0[I] = J Then AA := AH
          Else If (ItAttr[It] And MIA_DISABLED) <> 0 Then AA := AD
          Else AA := A;
          FillPS(K, 8, Y, WCX[I] - 8, Y + 16, 32, AA);
          If (ItAttr[It] And MIA_CHECKED) <> 0 Then CharPS(K, 8, Y, 251, AA);
          S := ItTextGet(It);
          TextPS(K, 16, Y, Cw - 4, S, AA, MnA(AA), True);
          If (ItStyle[It] And MIS_SUBMENU) <> 0 Then CharPS(K, WCX[I] - 16, Y, 16, AA);
        End;
      End;
    End;
  End;
  EndP(K);
End;

{ article de l'identificateur Id (Sub : chercher dans les sous-menus) ;
  M : menu qui le contient }
Function MFind(I, Id : LongInt; Sub : Boolean; Var M : LongInt) : LongInt;
Var K, R, S, M2, R2, D : LongInt;
Begin
  R := -1; M := I;
  For K := MaxItem - 1 DownTo 0 Do
    If (ItWin[K] = I + 1) And (ItId[K] = Id) Then R := K;
  If (R < 0) And Sub Then
    For K := 0 To MaxItem - 1 Do
      If (R < 0) And (ItWin[K] = I + 1) And ((ItStyle[K] And MIS_SUBMENU) <> 0) Then
      Begin
        S := WIdx(ItSub[K]);
        If (S > 1) And (S <> I) Then
        Begin
          R2 := MFind(S, Id, True, M2);
          If R2 >= 0 Then
          Begin
            R := R2; M := M2;
          End;
        End;
      End;
  D := 0;
  MFind := R;
End;

Procedure MenuKey(R, Mp1, Mp2 : LongInt);
Var Cur, Fl, Vk, Ch, P, N, Was, K : LongInt;
Begin
  Cur := R; N := 0;
  While (WS2[Cur] > 1) And (WUse[WS2[Cur]] <> 0) And (N < 16) Do
  Begin
    Cur := WS2[Cur];
    Inc(N);
  End;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := 0;
  If (Fl And KC_VIRTUALKEY) <> 0 Then Vk := Hi16(Mp2);
  If Vk = VK_ESC Then
  Begin
    If Cur <> R Then
    Begin
      P := WS3[Cur];
      MenuCloseSub(P);
      InvalWin(P);
    End
    Else MenuEnd(R);
  End
  Else If (Vk = VK_LEFT) Or (Vk = VK_RIGHT) Then
  Begin
    If IsBar(R) And ((Cur = R) Or (WS3[Cur] = R) Or (Vk = VK_LEFT) And (WS3[Cur] = R)) Then
    Begin
      If (Vk = VK_RIGHT) And (Cur <> R) And (WS0[Cur] >= 0) Then
      Begin
        K := ItAt(Cur, WS0[Cur]);
        If (K >= 0) And ((ItStyle[K] And MIS_SUBMENU) <> 0) Then
        Begin
          MenuOpenSub(Cur, WS0[Cur]);
          Exit;
        End;
      End;
      Was := WS2[R];
      MenuCloseSub(R);
      If Vk = VK_LEFT Then WS0[R] := MenuNextSel(R, WS0[R], -1) Else WS0[R] := MenuNextSel(R, WS0[R], 1);
      InvalWin(R);
      If Was > 1 Then MenuOpenSub(R, WS0[R]);
    End
    Else If Vk = VK_RIGHT Then MenuOpenSub(Cur, WS0[Cur])
    Else If Cur <> R Then
    Begin
      P := WS3[Cur];
      MenuCloseSub(P);
      InvalWin(P);
    End;
  End
  Else If (Vk = VK_UP) Or (Vk = VK_DOWN) Then
  Begin
    If (Cur = R) And IsBar(R) Then
    Begin
      If Vk = VK_DOWN Then MenuOpenSub(R, WS0[R]);
    End
    Else
    Begin
      If Vk = VK_UP Then WS0[Cur] := MenuNextSel(Cur, WS0[Cur], -1) Else WS0[Cur] := MenuNextSel(Cur, WS0[Cur], 1);
      InvalWin(Cur);
    End;
  End
  Else If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then MenuSelect(Cur, WS0[Cur], 0)
  Else If (Vk = VK_F1 + 9) Or (Vk = VK_ALT) Then MenuEnd(R)
  Else If (Fl And KC_CHAR) <> 0 Then
  Begin
    P := MenuMnem(Cur, Ch);
    If P >= 0 Then MenuSelect(Cur, P, 0);
  End;
End;

Procedure MenuMouse(I, Mp1 : LongInt);
Var R, Sx, Sy, T, P : LongInt;
Begin
  R := MenuRoot(I);
  Sx := AbsX(I) + SLo(Mp1); Sy := AbsY(I) + SHi(Mp1);
  T := WinAtAbs(0, Sx, Sy, True);
  If (T > 1) And (KindOf(T) = CK_MENU) And (MenuRoot(T) = R) Then
  Begin
    P := MenuHit(T, Sx - AbsX(T), Sy - AbsY(T));
    If P >= 0 Then
    Begin
      If WS1[R] = 0 Then MenuStart(R);
      If (T = R) And (WS0[R] = P) And (WS2[R] > 1) Then MenuEnd(R)
      Else
      Begin
        MenuCloseSub(T);
        MenuSelect(T, P, 1);
      End;
    End;
  End
  Else If WS1[R] <> 0 Then MenuEnd(R);
End;

Function MenuProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var K, M, N, Ps, S, J : LongInt;
Begin
  MenuProc := 0;
  Case Msg Of
    WM_CREATE :
      Begin
        WS0[I] := -1; WS2[I] := 0; WS3[I] := 0;
      End;
    WM_PAINT :
      MenuPaint(I);
    WM_CHAR :
      Begin
        If (Lo16(Mp1) And KC_KEYUP) = 0 Then
        Begin
          If WS1[MenuRoot(I)] = 0 Then MenuStart(MenuRoot(I));
          MenuKey(MenuRoot(I), Mp1, Mp2);
        End;
        MenuProc := 1;
      End;
    WM_BUTTON1DOWN, WM_BUTTON2DOWN :
      Begin
        MenuMouse(I, Mp1);
        MenuProc := 1;
      End;
    WM_BUTTON1UP, WM_BUTTON2UP, WM_MOUSEMOVE, WM_BUTTON1CLICK, WM_BUTTON1DBLCLK :
      MenuProc := 1;
    MM_INSERTITEM :
      Begin
        MenuProc := -3;
        If Mp1 = 0 Then Exit;
        Ps := SLo(RdW(Mp1));
        K := ItIns(I, Ps, GetZ(Mp2));
        If K < 0 Then
        Begin
          MenuProc := -2;
          Exit;
        End;
        ItStyle[K] := RdW(Mp1 + 2); ItAttr[K] := RdW(Mp1 + 4); ItId[K] := RdW(Mp1 + 6);
        ItSub[K] := RdL(Mp1 + 8); ItHandle[K] := RdL(Mp1 + 12);
        S := WIdx(ItSub[K]);
        If S > 1 Then
        Begin
          WOwner[S] := HwOf(I);
          WS3[S] := I;
        End;
        InvalWin(I);
        If IsBar(I) And (WPar[I] > 1) Then Dummy := FormatFrameI(WPar[I], 0, 0);
        MenuProc := ItPos[K];
      End;
    MM_DELETEITEM, MM_REMOVEITEM :
      Begin
        K := MFind(I, Lo16(Mp1), Hi16(Mp1) <> 0, M);
        If K >= 0 Then
        Begin
          S := WIdx(ItSub[K]);
          ItDel(K);
          If (Msg = MM_DELETEITEM) And (S > 1) Then DestroyIdx(S);
          InvalWin(M);
          If IsBar(M) And (WPar[M] > 1) Then Dummy := FormatFrameI(WPar[M], 0, 0);
        End;
        MenuProc := ItCnt(I);
      End;
    MM_QUERYITEM :
      Begin
        K := MFind(I, Lo16(Mp1), Hi16(Mp1) <> 0, M);
        If (K >= 0) And (Mp2 <> 0) Then
        Begin
          WrW(Mp2, ItPos[K]); WrW(Mp2 + 2, ItStyle[K]); WrW(Mp2 + 4, ItAttr[K]); WrW(Mp2 + 6, ItId[K]);
          WrL(Mp2 + 8, ItSub[K]); WrL(Mp2 + 12, ItHandle[K]);
          MenuProc := 1;
        End;
      End;
    MM_SETITEM :
      If Mp2 <> 0 Then
      Begin
        K := MFind(I, RdW(Mp2 + 6), Hi16(Mp1) <> 0, M);
        If K >= 0 Then
        Begin
          ItStyle[K] := RdW(Mp2 + 2); ItAttr[K] := RdW(Mp2 + 4); ItSub[K] := RdL(Mp2 + 8);
          ItHandle[K] := RdL(Mp2 + 12);
          S := WIdx(ItSub[K]);
          If S > 1 Then
          Begin
            WOwner[S] := HwOf(M);
            WS3[S] := M;
          End;
          InvalWin(M);
          MenuProc := 1;
        End;
      End;
    MM_QUERYITEMCOUNT :
      MenuProc := ItCnt(I);
    MM_STARTMENUMODE :
      Begin
        MenuStart(I);
        If Lo16(Mp1) <> 0 Then MenuOpenSub(I, WS0[I]);
        MenuProc := 1;
      End;
    MM_ENDMENUMODE :
      Begin
        MenuEnd(I);
        MenuProc := 1;
      End;
    MM_SELECTITEM :
      Begin
        If SLo(Mp1) = -1 Then
        Begin
          WS0[I] := -1;
          InvalWin(I);
          MenuProc := 1;
        End
        Else
        Begin
          K := MFind(I, Lo16(Mp1), Hi16(Mp1) <> 0, M);
          If K >= 0 Then
          Begin
            WS0[M] := ItPos[K];
            InvalWin(M);
            MenuProc := 1;
          End;
        End;
      End;
    MM_QUERYSELITEMID :
      Begin
        MenuProc := -1;
        M := I;
        If Hi16(Mp1) <> 0 Then
        Begin
          N := 0;
          While (WS2[M] > 1) And (N < 16) Do
          Begin
            M := WS2[M];
            Inc(N);
          End;
        End;
        K := ItAt(M, WS0[M]);
        If K >= 0 Then MenuProc := ItId[K];
      End;
    MM_QUERYITEMTEXT :
      Begin
        K := MFind(I, Lo16(Mp1), True, M);
        If K >= 0 Then MenuProc := PutZN(Mp2, Hi16(Mp1), ItTextGet(K));
      End;
    MM_QUERYITEMTEXTLENGTH :
      Begin
        K := MFind(I, Lo16(Mp1), True, M);
        If K >= 0 Then MenuProc := Length(ItTextGet(K));
      End;
    MM_SETITEMHANDLE :
      Begin
        K := MFind(I, Lo16(Mp1), True, M);
        If K >= 0 Then
        Begin
          ItHandle[K] := Mp2;
          MenuProc := 1;
        End;
      End;
    MM_SETITEMTEXT :
      Begin
        K := MFind(I, Lo16(Mp1), True, M);
        If K >= 0 Then
        Begin
          ItTextSet(K, GetZ(Mp2));
          InvalWin(M);
          If IsBar(M) And (WPar[M] > 1) Then Dummy := FormatFrameI(WPar[M], 0, 0);
          MenuProc := 1;
        End;
      End;
    MM_ITEMPOSITIONFROMID :
      Begin
        K := MFind(I, Lo16(Mp1), Hi16(Mp1) <> 0, M);
        If K >= 0 Then MenuProc := ItPos[K] Else MenuProc := -1;
      End;
    MM_ITEMIDFROMPOSITION :
      Begin
        K := ItAt(I, SLo(Mp1));
        If K >= 0 Then MenuProc := ItId[K] Else MenuProc := -3;
      End;
    MM_QUERYITEMATTR :
      Begin
        K := MFind(I, Lo16(Mp1), Hi16(Mp1) <> 0, M);
        If K >= 0 Then MenuProc := ItAttr[K] And Lo16(Mp2);
      End;
    MM_SETITEMATTR :
      Begin
        K := MFind(I, Lo16(Mp1), Hi16(Mp1) <> 0, M);
        If K >= 0 Then
        Begin
          ItAttr[K] := (ItAttr[K] And Not Lo16(Mp2)) Or (Hi16(Mp2) And Lo16(Mp2));
          InvalWin(M);
          MenuProc := 1;
        End;
      End;
    MM_ISITEMVALID :
      Begin
        K := MFind(I, Lo16(Mp1), Hi16(Mp1) <> 0, M);
        If (K >= 0) And ((ItAttr[K] And MIA_DISABLED) = 0) Then MenuProc := 1;
      End;
    WM_QUERYDLGCODE :
      MenuProc := $200;
  Else
    MenuProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
  End;
  J := 0;
End;

{ Lire un modele de menu : cb, version 0 (cMti) ou 1 (codepage,
  decalage des articles, cMti) ; article : afStyle, afAttribute, id,
  texte (sauf MIS_SEPARATOR/MIS_BITMAP/MIS_OWNERDRAW), puis le modele du
  sous-menu (MIS_SUBMENU). Rend la taille du modele. }
Function ParseMenu(I, P : LongInt) : LongInt;
Var Cb, N, Off, K, St, At, Id, S, J, Sz : LongInt; T : String;
Begin
  Cb := RdW(P);
  If RdW(P + 2) = 0 Then
  Begin
    N := RdW(P + 4); Off := 6;
  End
  Else
  Begin
    N := RdW(P + 8); Off := RdW(P + 6);
    If Off < 10 Then Off := 10;
  End;
  J := 0;
  While J < N Do
  Begin
    Inc(J);
    St := RdW(P + Off); At := RdW(P + Off + 2); Id := RdW(P + Off + 4);
    Off := Off + 6;
    T := '';
    If (St And (MIS_SEPARATOR Or 2 Or 8)) = 0 Then
    Begin
      T := GetZ(P + Off);
      Off := Off + Length(T) + 1;
    End;
    S := 0;
    If (St And MIS_SUBMENU) <> 0 Then
    Begin
      S := NewMenuWin(HWND_DESKTOP, HwOf(I), 0, Id);
      If S > 1 Then Sz := ParseMenu(S, P + Off) Else Sz := RdW(P + Off);
      If Sz <= 0 Then Sz := 2;
      Off := Off + Sz;
    End;
    K := ItIns(I, -1, T);
    If K >= 0 Then
    Begin
      ItStyle[K] := St; ItAttr[K] := At; ItId[K] := Id;
      If S > 1 Then
      Begin
        ItSub[K] := HwOf(S);
        WS3[S] := I;
      End;
    End;
  End;
  If Cb < Off Then Cb := Off;
  ParseMenu := Cb;
End;

{ WinCreateMenu(hwndParent, lpmt) : barre d'actions si le parent est un
  cadre, menu surgissant sinon }
Function WinCreateMenu(HPar, P : LongInt) : LongInt;
Var Pa, I, Old : LongInt;
Begin
  WinCreateMenu := 0;
  If P = 0 Then
  Begin
    SetErr(PMERR_INVALID_PARAMETERS);
    Exit;
  End;
  Pa := WChk(HPar);
  If Pa < 0 Then Exit;
  If (Pa > 1) And (KindOf(Pa) = CK_FRAME) Then
  Begin
    Old := ChildId(Pa, FID_MENU);
    If Old > 1 Then DestroyIdx(Old);
    I := NewMenuWin(HwOf(Pa), HwOf(Pa), MS_ACTIONBAR Or WS_VISIBLE, FID_MENU);
  End
  Else If Pa > 1 Then I := NewMenuWin(HWND_DESKTOP, HwOf(Pa), 0, 0)
  Else I := NewMenuWin(HWND_DESKTOP, 0, 0, 0);
  If I < 2 Then Exit;
  Dummy := ParseMenu(I, P);
  If (Pa > 1) And (KindOf(Pa) = CK_FRAME) Then
  Begin
    WS0[Pa] := WS0[Pa] Or FCF_MENU;
    Dummy := FormatFrameI(Pa, 0, 0);
    InvalWin(Pa);
  End;
  WinCreateMenu := HwOf(I);
End;

Function WinLoadMenu(HFrame, Hmod, Id : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := GetRes(Hmod, 3, Id);
  If P = 0 Then
  Begin
    SetErr(PMERR_RESOURCE_NOT_FOUND);
    WinLoadMenu := 0;
  End
  Else WinLoadMenu := WinCreateMenu(HFrame, P);
End;

{ WinPopupMenu(hwndParent, hwndOwner, hwndMenu, x, y, idItem, fs) : BOOL ;
  PU_POSITIONONITEM 1 }
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt;
Var M, P, Cx, Cy, K, Mm : LongInt;
Begin
  WinPopupMenu := 0;
  M := WChk(HMenu);
  If (M < 2) Or (KindOf(M) <> CK_MENU) Then Exit;
  P := WIdx(HPar);
  If P > 1 Then
  Begin
    X := X + AbsX(P); Y := Y + AbsY(P);
  End;
  MenuEnd(M);
  WOwner[M] := HOwn;
  WPar[M] := 0;
  WS3[M] := 0;
  WStyle[M] := WStyle[M] And Not MS_ACTIONBAR;
  Cx := MenuWidthPels(M); Cy := MenuHeightPels(M);
  K := MFind(M, Id, False, Mm);
  If K >= 0 Then WS0[M] := ItPos[K] Else WS0[M] := MenuFirstSel(M);
  If ((Fs And 1) <> 0) And (K >= 0) Then Y := Y - Cy + 16 * (ItPos[K] + 2)
  Else Y := Y - Cy;
  X := MaxI(0, MinI(X, ScrCX - Cx)); Y := MaxI(0, MinI(Y, ScrCY - Cy));
  Dummy := WinSetWindowPos(HwOf(M), HWND_TOP, X, Y, Cx, Cy, SWP_MOVE Or SWP_SIZE Or SWP_SHOW Or SWP_ZORDER Or SWP_NOADJUST);
  MenuStart(M);
  WinPopupMenu := 1;
End;

{ fonctions de service des menus }
Function WinMenuIndexFromID(HMenu, Id : LongInt) : LongInt;
Var M, K, Mm : LongInt;
Begin
  M := WIdx(HMenu);
  WinMenuIndexFromID := -1;
  If M < 2 Then Exit;
  K := MFind(M, Id, False, Mm);
  If K >= 0 Then WinMenuIndexFromID := ItPos[K];
End;

Function WinSetMenuData(HMenu, Id, Data : LongInt) : LongInt;
Var M, K, Mm : LongInt;
Begin
  WinSetMenuData := 0;
  M := WIdx(HMenu);
  If M < 2 Then Exit;
  K := MFind(M, Id, True, Mm);
  If K >= 0 Then
  Begin
    ItHandle[K] := Data;
    WinSetMenuData := 1;
  End;
End;

Function WinQueryMenuData(HMenu, Id : LongInt) : LongInt;
Var M, K, Mm : LongInt;
Begin
  WinQueryMenuData := 0;
  M := WIdx(HMenu);
  If M < 2 Then Exit;
  K := MFind(M, Id, True, Mm);
  If K >= 0 Then WinQueryMenuData := ItHandle[K];
End;

Function WinForceMenuRedraw(HMenu : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := WIdx(HMenu);
  If M < 2 Then WinForceMenuRedraw := 0
  Else
  Begin
    InvalWin(M);
    WinForceMenuRedraw := 1;
  End;
End;

{ ==================================================================== }
{ Classes generiques (#16 a #40) et procedure des classes du systeme    }
{ ==================================================================== }
Function GenericProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var K, A : LongInt;
Begin
  If Msg = WM_PAINT Then
  Begin
    K := BeginP(I);
    If K >= 0 Then
    Begin
      A := Attr(PPColor(I, 1, -17), PPColor(I, 3, CtlBg(I)));
      FillPS(K, 0, 0, WCX[I], WCY[I], 32, A);
      TextBox(K, WTextGet(I), WCX[I], WCY[I], $400, A);
      EndP(K);
    End;
    GenericProc := 0;
  End
  Else If Msg = WM_SETWINDOWPARAMS Then
  Begin
    GenericProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
    InvalWin(I);
  End
  Else GenericProc := DefWP(HwOf(I), Msg, Mp1, Mp2);
End;

Function SysProcI(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WIdx(H);
  If I < 0 Then
  Begin
    SysProcI := 0;
    Exit;
  End;
  Case KindOf(I) Of
    CK_FRAME : SysProcI := FrameProc(I, Msg, Mp1, Mp2);
    CK_TITLEBAR : SysProcI := TitleProc(I, Msg, Mp1, Mp2);
    CK_STATIC : SysProcI := StaticProc(I, Msg, Mp1, Mp2);
    CK_BUTTON : SysProcI := ButtonProc(I, Msg, Mp1, Mp2);
    CK_ENTRYFIELD, CK_MLE : SysProcI := EntryProc(I, Msg, Mp1, Mp2);
    CK_LISTBOX : SysProcI := ListProc(I, Msg, Mp1, Mp2);
    CK_COMBOBOX : SysProcI := ComboProc(I, Msg, Mp1, Mp2);
    CK_SCROLLBAR : SysProcI := ScrollProc(I, Msg, Mp1, Mp2);
    CK_MENU : SysProcI := MenuProc(I, Msg, Mp1, Mp2);
    CK_GENERIC : SysProcI := GenericProc(I, Msg, Mp1, Mp2);
  Else
    SysProcI := DefWP(H, Msg, Mp1, Mp2);
  End;
End;

{ point d'entree WINSYSCLASSPROC (ordinal 1000) }
Function WinSysClassProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  WinSysClassProc := SysProcI(H, Msg, Mp1, Mp2);
End;

{ ==================================================================== }
{ Dialogues                                                             }
{ ==================================================================== }
{ Creer l'element numero Idx du modele T (DLGTEMPLATE : cbTemplate, type,
  codepage, offadlgti, fsTemplateStatus, iItemFocus, coffPresParams ;
  DLGTITEM de 30 octets : fsItemStatus, cChildren, cchClassName,
  offClassName, cchText, offText, flStyle, x, y, cx, cy, id,
  offPresParams, offCtlData) et ses enfants ; unites de dialogue : 2 pels }
Function DlgCreate(T : LongInt; Var Idx : LongInt; HPar, HOwn : LongInt; Top : Boolean) : LongInt;
Var A, NCh, Cls, Txt, St, Id, PP, Ctl, H, K, HD : LongInt;
    CBuf, TBuf : Array[0..259] Of Byte;
Begin
  A := T + RdW(T + 6) + Idx * 30;
  Inc(Idx);
  NCh := RdW(A + 2);
  If RdW(A + 4) = 0 Then Cls := $FFFF0000 Or RdW(A + 6)
  Else
  Begin
    PutZ(LongInt(@CBuf), GetN(T + RdW(A + 6), RdW(A + 4)));
    Cls := LongInt(@CBuf);
  End;
  Txt := 0;
  If (RdW(A + 10) <> $FFFF) And (RdW(A + 10) <> 0) Then
  Begin
    PutZ(LongInt(@TBuf), GetN(T + RdW(A + 10), RdW(A + 8)));
    Txt := LongInt(@TBuf);
  End;
  St := RdL(A + 12);
  If Top Then St := St And Not WS_VISIBLE;
  Id := RdW(A + 24);
  PP := 0; Ctl := 0;
  If (RdW(A + 26) <> $FFFF) And (RdW(A + 26) <> 0) Then PP := T + RdW(A + 26);
  If (RdW(A + 28) <> $FFFF) And (RdW(A + 28) <> 0) Then Ctl := T + RdW(A + 28);
  H := WinCreateWindow(HPar, Cls, Txt, St, RdSW(A + 16) * 2, RdSW(A + 18) * 2, RdSW(A + 20) * 2, RdSW(A + 22) * 2,
                       HOwn, HWND_BOTTOM, Id, Ctl, PP);
  If Top Then HD := H Else HD := HOwn;
  { boucle While : la borne d'un For d'OS2PC n'est pas reentrante }
  K := 1;
  While K <= NCh Do
  Begin
    Dummy := DlgCreate(T, Idx, H, HD, False);
    Inc(K);
  End;
  DlgCreate := H;
End;

{ WinCreateDlg(hwndParent, hwndOwner, pfnDlgProc, pdlgt, pCreateParams) }
Function WinCreateDlg(HPar, HOwn, Proc, T, PCreate : LongInt) : LongInt;
Var Idx, H, I, F, R, Foc : LongInt;
Begin
  WinCreateDlg := 0;
  If T = 0 Then
  Begin
    SetErr(PMERR_INVALID_PARAMETERS);
    Exit;
  End;
  Idx := 0;
  H := DlgCreate(T, Idx, HPar, HOwn, True);
  I := WIdx(H);
  If I < 2 Then Exit;
  WFlags[I] := WFlags[I] Or 4;
  WS2[I] := 0; WS3[I] := 0;
  If Proc = 0 Then Proc := DefDlgAddr;
  WProc[I] := Proc;
  F := WIdx(WinEnumDlgItem(H, 0, 0));
  Foc := 0;
  If (RdW(T + 10) <> $FFFF) And (RdW(T + 10) > 0) And (RdW(T + 10) < Idx) Then
    Foc := WinWindowFromID(H, RdW(T + RdW(T + 6) + RdW(T + 10) * 30 + 24));
  If (Foc = 0) And (F > 1) Then Foc := HwOf(F);
  R := CallProcOf(I, WM_INITDLG, Foc, PCreate);
  If WUse[I] = 0 Then Exit;
  If (R = 0) And (WIdx(Foc) > 1) And (WData[I] <> 0) Then WrL(WData[I] + $18, Foc);
  If (RdL(T + RdW(T + 6) + 12) And WS_VISIBLE) <> 0 Then
    Dummy := WinSetWindowPos(H, HWND_TOP, 0, 0, 0, 0, SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  WinCreateDlg := H;
End;

Function WinLoadDlg(HPar, HOwn, Proc, Hmod, Id, PCreate : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := GetRes(Hmod, 4, Id);
  If P = 0 Then
  Begin
    SetErr(PMERR_RESOURCE_NOT_FOUND);
    WinLoadDlg := 0;
  End
  Else WinLoadDlg := WinCreateDlg(HPar, HOwn, Proc, P, PCreate);
End;

{ WinProcessDlg(hwndDlg) : boucle modale ; rend le resultat de
  WinDismissDlg (DID_ERROR FFFFh) }
Function WinProcessDlg(H : LongInt) : LongInt;
Var I, O, R : LongInt; Dis : Boolean; M : Array[0..7] Of LongInt;
Begin
  WinProcessDlg := $FFFF;
  I := WChk(H);
  If I < 2 Then Exit;
  WS3[I] := 0;
  Dummy := WinSetWindowPos(H, HWND_TOP, 0, 0, 0, 0, SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  O := WIdx(WOwner[I]);
  Dis := False;
  If (O > 1) And ((WStyle[O] And WS_DISABLED) = 0) Then
  Begin
    Dummy := WinEnableWindow(HwOf(O), 0);
    Dis := True;
  End;
  WFlags[I] := WFlags[I] Or 8;
  R := 1;
  While (R <> 0) And (WUse[I] <> 0) And (HwOf(I) = H) And (WS3[I] = 0) Do
  Begin
    R := WinGetMsg(0, LongInt(@M), 0, 0, 0);
    If R <> 0 Then Dummy := WinDispatchMsg(0, LongInt(@M))
    Else Dummy := LongInt(PostM(H, WM_QUIT, 0, 0));
  End;
  If Dis And (WUse[O] <> 0) Then Dummy := WinEnableWindow(HwOf(O), 1);
  If (WUse[I] <> 0) And (HwOf(I) = H) Then
  Begin
    WFlags[I] := WFlags[I] And Not 8;
    If WS3[I] <> 0 Then WinProcessDlg := WS2[I] Else WinProcessDlg := DID_CANCEL;
  End
  Else WinProcessDlg := DID_CANCEL;
  If (O > 1) And (WUse[O] <> 0) Then Dummy := WinSetActiveWindow(HWND_DESKTOP, HwOf(TopFrame(O)));
End;

{ WinDlgBox(hwndParent, hwndOwner, pfnDlgProc, hmod, idDlg, pCreateParams) }
Function WinDlgBox(HPar, HOwn, Proc, Hmod, Id, PCreate : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := WinLoadDlg(HPar, HOwn, Proc, Hmod, Id, PCreate);
  If H = 0 Then WinDlgBox := $FFFF
  Else
  Begin
    WinDlgBox := WinProcessDlg(H);
    Dummy := WinDestroyWindow(H);
  End;
End;

Function WinDismissDlg(H, R : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 2 Then
  Begin
    WinDismissDlg := 0;
    Exit;
  End;
  WS2[I] := R And $FFFF;
  WS3[I] := 1;
  Dummy := WinSetWindowPos(H, 0, 0, 0, 0, 0, SWP_HIDE);
  WinDismissDlg := 1;
End;

{ WinGetDlgMsg(hwndDlg, pqmsg) : FALSE quand le dialogue est termine }
Function WinGetDlgMsg(H, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinGetDlgMsg := 0;
  I := WIdx(H);
  If (I < 2) Or (P = 0) Then Exit;
  If WS3[I] <> 0 Then Exit;
  If WinGetMsg(0, P, 0, 0, 0) = 0 Then
  Begin
    Dummy := LongInt(PostM(H, WM_QUIT, 0, 0));
    Exit;
  End;
  WinGetDlgMsg := 1;
End;

Function WinSendDlgItemMsg(HDlg, Id, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := WinWindowFromID(HDlg, Id);
  If H = 0 Then WinSendDlgItemMsg := 0 Else WinSendDlgItemMsg := SendM(H, Msg, Mp1, Mp2);
End;

Function WinSetDlgItemText(HDlg, Id, P : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := WinWindowFromID(HDlg, Id);
  If H = 0 Then WinSetDlgItemText := 0 Else WinSetDlgItemText := WinSetWindowText(H, P);
End;

Function WinQueryDlgItemText(HDlg, Id, Cch, P : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := WinWindowFromID(HDlg, Id);
  If H = 0 Then
  Begin
    If (P <> 0) And (Cch > 0) Then WrB(P, 0);
    WinQueryDlgItemText := 0;
  End
  Else WinQueryDlgItemText := WinQueryWindowText(H, Cch, P);
End;

Function WinQueryDlgItemTextLength(HDlg, Id : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := WinWindowFromID(HDlg, Id);
  If H = 0 Then WinQueryDlgItemTextLength := 0 Else WinQueryDlgItemTextLength := WinQueryWindowTextLength(H);
End;

{ WinSetDlgItemShort(hwndDlg, idItem, usValue, fSigned) }
Function WinSetDlgItemShort(HDlg, Id, V, FSigned : LongInt) : LongInt;
Var Buf : Array[0..15] Of Byte;
Begin
  If FSigned <> 0 Then V := SLo(V) Else V := Lo16(V);
  PutZ(LongInt(@Buf), IntStr(V));
  WinSetDlgItemShort := WinSetDlgItemText(HDlg, Id, LongInt(@Buf));
End;

{ WinQueryDlgItemShort(hwndDlg, idItem, pResult, fSigned) : BOOL }
Function WinQueryDlgItemShort(HDlg, Id, P, FSigned : LongInt) : LongInt;
Var Buf : Array[0..63] Of Byte; V : LongInt;
Begin
  WinQueryDlgItemShort := 0;
  If P = 0 Then Exit;
  Dummy := WinQueryDlgItemText(HDlg, Id, 64, LongInt(@Buf));
  If Not StrToIntDef(GetZ(LongInt(@Buf)), V) Then Exit;
  If FSigned <> 0 Then
  Begin
    If (V < -32768) Or (V > 32767) Then Exit;
  End
  Else If (V < 0) Or (V > 65535) Then Exit;
  WrW(P, V);
  WinQueryDlgItemShort := 1;
End;

{ WinEnumDlgItem(hwndDlg, hwnd, code) : EDI_FIRSTTABITEM 0,
  EDI_LASTTABITEM 1, EDI_NEXTTABITEM 2, EDI_PREVTABITEM 3,
  EDI_FIRSTGROUPITEM 4, EDI_LASTGROUPITEM 5, EDI_NEXTGROUPITEM 6,
  EDI_PREVGROUPITEM 7 }
Function WinEnumDlgItem(HDlg, H, Code : LongInt) : LongInt;
Var D, I, J, N, P, K, Gs, Ge, R, C : LongInt; L : Array[0..127] Of LongInt;
Begin
  WinEnumDlgItem := 0;
  D := WChk(HDlg);
  If D < 0 Then Exit;
  N := 0;
  J := ItemFirst(D);
  While (J > 1) And (N < 128) Do
  Begin
    L[N] := J;
    Inc(N);
    J := ItemNext(J);
  End;
  If N = 0 Then Exit;
  I := WIdx(H);
  While (I > 1) And (WPar[I] <> D) Do I := WPar[I];
  P := -1;
  For K := 0 To N - 1 Do
    If L[K] = I Then P := K;
  R := -1;
  If Code <= 3 Then
  Begin
    { elements avec WS_TABSTOP, visibles et actives }
    If (Code = 0) Or ((Code = 2) And (P < 0)) Then
    Begin
      For K := N - 1 DownTo 0 Do
        If ((WStyle[L[K]] And (WS_TABSTOP Or WS_VISIBLE Or WS_DISABLED)) = (WS_TABSTOP Or WS_VISIBLE)) Then R := K;
    End
    Else If (Code = 1) Or ((Code = 3) And (P < 0)) Then
    Begin
      For K := 0 To N - 1 Do
        If ((WStyle[L[K]] And (WS_TABSTOP Or WS_VISIBLE Or WS_DISABLED)) = (WS_TABSTOP Or WS_VISIBLE)) Then R := K;
    End
    Else
    Begin
      For C := 1 To N Do
        If R < 0 Then
        Begin
          If Code = 2 Then K := (P + C) Mod N Else K := (P - C + N * 2) Mod N;
          If ((WStyle[L[K]] And (WS_TABSTOP Or WS_VISIBLE Or WS_DISABLED)) = (WS_TABSTOP Or WS_VISIBLE)) Then R := K;
        End;
    End;
  End
  Else
  Begin
    If P < 0 Then P := 0;
    Gs := P;
    While (Gs > 0) And ((WStyle[L[Gs]] And WS_GROUP) = 0) Do Dec(Gs);
    Ge := P + 1;
    While (Ge < N) And ((WStyle[L[Ge]] And WS_GROUP) = 0) Do Inc(Ge);
    Dec(Ge);
    If Code = 4 Then R := Gs
    Else If Code = 5 Then R := Ge
    Else
      For C := 1 To Ge - Gs + 1 Do
        If R < 0 Then
        Begin
          If Code = 6 Then K := Gs + (P - Gs + C) Mod (Ge - Gs + 1)
          Else K := Gs + (P - Gs - C + (Ge - Gs + 1) * 2) Mod (Ge - Gs + 1);
          If ((WStyle[L[K]] And (WS_VISIBLE Or WS_DISABLED)) = WS_VISIBLE) Then R := K;
        End;
  End;
  If R >= 0 Then WinEnumDlgItem := HwOf(L[R]);
End;

{ WinMapDlgPoints(hwndDlg, prgwptl, cwpt, fCalcWindowCoords) : BOOL }
Function WinMapDlgPoints(HDlg, P, N, FWin : LongInt) : LongInt;
Var K : LongInt;
Begin
  WinMapDlgPoints := 0;
  If P = 0 Then Exit;
  For K := 0 To N * 2 - 1 Do
    If FWin <> 0 Then WrL(P + K * 4, RdL(P + K * 4) * 2) Else WrL(P + K * 4, RdL(P + K * 4) Div 2);
  WinMapDlgPoints := 1;
End;

{ WinSubstituteStrings(hwnd, pszSrc, cchDstMax, pszDst) : %0 a %9
  remplaces par WM_SUBSTITUTESTRING ; rend la longueur }
Function WinSubstituteStrings(H, PSrc, Cch, PDst : LongInt) : LongInt;
Var S, R : String; J, P : LongInt;
Begin
  S := GetZ(PSrc);
  R := '';
  J := 1;
  While J <= Length(S) Do
  Begin
    If (Ord(S[J]) = 37) And (J < Length(S)) Then
    Begin
      If (Ord(S[J + 1]) >= 48) And (Ord(S[J + 1]) <= 57) Then
      Begin
        P := SendM(H, WM_SUBSTITUTESTRING, Ord(S[J + 1]) - 48, 0);
        If P <> 0 Then R := R + GetZ(P);
        J := J + 2;
      End
      Else If Ord(S[J + 1]) = 37 Then
      Begin
        R := R + '%';
        J := J + 2;
      End
      Else
      Begin
        R := R + S[J];
        Inc(J);
      End;
    End
    Else
    Begin
      R := R + S[J];
      Inc(J);
    End;
  End;
  WinSubstituteStrings := PutZN(PDst, Cch, R);
End;

Procedure DlgFocus(D, J : LongInt);
Begin
  If J > 1 Then FocusTo(J);
End;

{ clavier d'un dialogue : tabulation, fleches, Entree, Echap, mnemoniques }
Function DlgKey(D, Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk, F, J, B, N, T : LongInt; R : Boolean;
Begin
  DlgKey := False;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := 0;
  If (Fl And KC_KEYUP) <> 0 Then Exit;
  If (Fl And KC_VIRTUALKEY) <> 0 Then Vk := Hi16(Mp2);
  F := FocusWin;
  If (F > 1) And Not IsChildOf(F, D) Then F := 0;
  R := True;
  If (Vk = VK_TAB) And ((Fl And KC_SHIFT) = 0) Then DlgFocus(D, WIdx(WinEnumDlgItem(HwOf(D), HwOf(F), 2)))
  Else If (Vk = VK_BACKTAB) Or ((Vk = VK_TAB) And ((Fl And KC_SHIFT) <> 0)) Then
    DlgFocus(D, WIdx(WinEnumDlgItem(HwOf(D), HwOf(F), 3)))
  Else If ((Vk = VK_UP) Or (Vk = VK_LEFT) Or (Vk = VK_DOWN) Or (Vk = VK_RIGHT)) And (F > 1) Then
  Begin
    If (Vk = VK_UP) Or (Vk = VK_LEFT) Then J := WIdx(WinEnumDlgItem(HwOf(D), HwOf(F), 7))
    Else J := WIdx(WinEnumDlgItem(HwOf(D), HwOf(F), 6));
    If (J > 1) And (J <> F) Then
    Begin
      DlgFocus(D, J);
      If (KindOf(J) = CK_BUTTON) And ((WStyle[J] And $0F) = BS_AUTORADIOBUTTON) Then BtnClick(J);
    End;
  End
  Else If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
  Begin
    B := -1;
    If (F > 1) And (KindOf(F) = CK_BUTTON) And ((WStyle[F] And $0F) = BS_PUSHBUTTON) Then B := F
    Else
    Begin
      J := ItemFirst(D); N := 0;
      While (J > 1) And (N < MaxWin) Do
      Begin
        If (B < 0) And (KindOf(J) = CK_BUTTON) And ((WStyle[J] And BS_DEFAULT) <> 0) And
           ((WStyle[J] And (WS_VISIBLE Or WS_DISABLED)) = WS_VISIBLE) Then B := J;
        J := ItemNext(J);
        Inc(N);
      End;
    End;
    If B > 1 Then BtnClick(B)
    Else Dummy := LongInt(PostM(HwOf(D), WM_COMMAND, DID_OK, Mk2(CMDSRC_OTHER, 0)));
  End
  Else If Vk = VK_ESC Then Dummy := LongInt(PostM(HwOf(D), WM_COMMAND, DID_CANCEL, Mk2(CMDSRC_OTHER, 0)))
  Else If ((Fl And KC_CHAR) <> 0) And (Ch > 32) And
          (((Fl And KC_ALT) <> 0) Or (F < 2) Or Not ((KindOf(F) = CK_ENTRYFIELD) Or (KindOf(F) = CK_MLE) Or (KindOf(F) = CK_COMBOBOX))) Then
  Begin
    R := False;
    J := ItemFirst(D); N := 0;
    While (J > 1) And (N < MaxWin) And Not R Do
    Begin
      If ((WStyle[J] And (WS_VISIBLE Or WS_DISABLED)) = WS_VISIBLE) And (SendM(HwOf(J), WM_MATCHMNEMONIC, Ch, 0) <> 0) Then
      Begin
        R := True;
        If KindOf(J) = CK_BUTTON Then
        Begin
          DlgFocus(D, J);
          BtnClick(J);
        End
        Else If KindOf(J) = CK_STATIC Then
        Begin
          T := WIdx(WinEnumDlgItem(HwOf(D), HwOf(J), 2));
          DlgFocus(D, T);
        End
        Else DlgFocus(D, J);
      End;
      J := ItemNext(J);
      Inc(N);
    End;
  End
  Else R := False;
  DlgKey := R;
End;

Function DefDlgI(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I : LongInt;
Begin
  DefDlgI := 0;
  I := WIdx(H);
  If I < 2 Then Exit;
  Case Msg Of
    WM_INITDLG : DefDlgI := 0;
    WM_COMMAND : Dummy := WinDismissDlg(H, Lo16(Mp1));
    WM_CLOSE : Dummy := LongInt(PostM(H, WM_COMMAND, DID_CANCEL, Mk2(CMDSRC_OTHER, 0)));
    WM_CHAR :
      If DlgKey(I, Mp1, Mp2) Then DefDlgI := 1 Else DefDlgI := ClassProcCall(I, Msg, Mp1, Mp2);
  Else
    DefDlgI := ClassProcCall(I, Msg, Mp1, Mp2);
  End;
End;

Function WinDefDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  WinDefDlgProc := DefDlgI(H, Msg, Mp1, Mp2);
End;

Function WinLangsupWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  WinLangsupWindowProc := DefWP(H, Msg, Mp1, Mp2);
End;

Function WinLangsupDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  WinLangsupDlgProc := DefDlgI(H, Msg, Mp1, Mp2);
End;

{ ==================================================================== }
{ Boites de message, fenetre standard, divers                           }
{ ==================================================================== }
{ WinAlarm(hwndDesktop, rgfType) : WA_WARNING 0, WA_NOTE 1, WA_ERROR 2 }
Function WinAlarm(HDesk, Typ : LongInt) : LongInt;
Begin
  WinAlarm := 0;
  If (Typ < 0) Or (Typ > 2) Then Exit;
  If SysVal[6] <> 0 Then Dummy := DcBeep(SysVal[13 + Typ], SysVal[16 + Typ]);
  WinAlarm := 1;
End;

{ WinMessageBox(hwndParent, hwndOwner, pszText, pszCaption, idWindow,
  flStyle) : MBID_* (MBID_ERROR FFFFh) }
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt;
Var Txt, Cap, T, L, Ic : String; W, Lines, NB, K, X, Y, Cx, Cy, H, D, Def, R, BW, Iw, Bx, B, St, Row : LongInt;
    Lab : Array[0..3] Of String[15]; Ids : Array[0..3] Of LongInt;
    Buf : Array[0..259] Of Byte; Fcd : Array[0..11] Of Byte;
Begin
  WinMessageBox := MBID_ERROR;
  Txt := GetZ(PText); Cap := GetZ(PCap);
  If PCap = 0 Then Cap := 'Erreur';
  NB := 0;
  Case Fl And $0F Of
    0 : Begin Lab[0] := '~OK'; Ids[0] := MBID_OK; NB := 1; End;
    1 : Begin Lab[0] := '~OK'; Ids[0] := MBID_OK; Lab[1] := 'Annuler'; Ids[1] := MBID_CANCEL; NB := 2; End;
    2 : Begin Lab[0] := '~Reessayer'; Ids[0] := MBID_RETRY; Lab[1] := 'Annuler'; Ids[1] := MBID_CANCEL; NB := 2; End;
    3 : Begin Lab[0] := '~Abandonner'; Ids[0] := MBID_ABORT; Lab[1] := '~Reessayer'; Ids[1] := MBID_RETRY;
              Lab[2] := '~Ignorer'; Ids[2] := MBID_IGNORE; NB := 3; End;
    4 : Begin Lab[0] := '~Oui'; Ids[0] := MBID_YES; Lab[1] := '~Non'; Ids[1] := MBID_NO; NB := 2; End;
    5 : Begin Lab[0] := '~Oui'; Ids[0] := MBID_YES; Lab[1] := '~Non'; Ids[1] := MBID_NO;
              Lab[2] := 'Annuler'; Ids[2] := MBID_CANCEL; NB := 3; End;
    6 : Begin Lab[0] := 'Annuler'; Ids[0] := MBID_CANCEL; NB := 1; End;
    7 : Begin Lab[0] := '~Entree'; Ids[0] := MBID_ENTER; NB := 1; End;
    8 : Begin Lab[0] := '~Entree'; Ids[0] := MBID_ENTER; Lab[1] := 'Annuler'; Ids[1] := MBID_CANCEL; NB := 2; End;
  Else
    Exit;
  End;
  If (Fl And $2000) <> 0 Then
  Begin
    Lab[NB] := 'Aide'; Ids[NB] := MBID_HELP; Inc(NB);
  End;
  Def := 0;
  If (Fl And $100) <> 0 Then Def := 1;
  If (Fl And $200) <> 0 Then Def := 2;
  If Def >= NB Then Def := 0;
  { icone }
  Case Fl And $F0 Of
    $10 : Ic := '?';
    $20 : Ic := '!';
    $30 : Ic := 'i';
    $40 : Ic := 'X';
  Else
    Ic := '';
  End;
  If Ic <> '' Then Iw := 4 Else Iw := 0;
  If (Fl And $F0) = $40 Then Dummy := WinAlarm(HWND_DESKTOP, 2)
  Else If (Fl And $F0) = $20 Then Dummy := WinAlarm(HWND_DESKTOP, 0)
  Else If (Fl And $F0) <> 0 Then Dummy := WinAlarm(HWND_DESKTOP, 1);
  { largeur }
  BW := 0;
  For K := 0 To NB - 1 Do BW := BW + VisLen(Lab[K]) + 4;
  BW := BW + (NB - 1) * 2;
  W := MaxI(BW, Length(Cap) + 8);
  T := Txt; Lines := 0; X := 0;
  While (T <> '') And (Lines < 15) Do
  Begin
    L := CutLine(T, 60);
    X := MaxI(X, Length(L));
    Inc(Lines);
  End;
  If Lines = 0 Then Lines := 1;
  W := MinI(MaxI(W, X + Iw), 72);
  Cx := (W + 4) * 8; Cy := (Lines + 5) * 16;
  If GMode <> 0 Then Cy := Cy + 16;
  X := ((ScrCX - Cx) Div 16) * 8; Y := ((ScrCY - Cy) Div 32) * 16;
  { cadre }
  MemZero(LongInt(@Fcd), 12);
  WrW(LongInt(@Fcd), 10);
  If (Fl And $4000) <> 0 Then WrL(LongInt(@Fcd) + 2, FCF_TITLEBAR Or FCF_DLGBORDER Or FCF_SYSMENU)
  Else WrL(LongInt(@Fcd) + 2, FCF_TITLEBAR Or FCF_DLGBORDER);
  PutZ(LongInt(@Buf), Cap);
  If HPar = 0 Then HPar := HWND_DESKTOP;
  H := WinCreateWindow(HWND_DESKTOP, $FFFF0001, LongInt(@Buf), FS_DLGBORDER, X, Y, Cx, Cy, HOwn, HWND_TOP, Id,
                       LongInt(@Fcd), 0);
  D := WIdx(H);
  If D < 2 Then Exit;
  WFlags[D] := WFlags[D] Or 4;
  WProc[D] := DefDlgAddr;
  { texte }
  If Ic <> '' Then
  Begin
    PutZ(LongInt(@Buf), Ic);
    Dummy := WinCreateWindow(H, $FFFF0005, LongInt(@Buf), SS_TEXT Or WS_VISIBLE Or $100, 16, Cy - 48, 16, 16, H,
                             HWND_BOTTOM, $FFFF, 0, 0);
  End;
  T := Txt; Row := 2;
  While (T <> '') And (Row < Lines + 2) Do
  Begin
    L := CutLine(T, 60);
    PutZ(LongInt(@Buf), L);
    If Lines = 1 Then St := SS_TEXT Or WS_VISIBLE Or $100 Else St := SS_TEXT Or WS_VISIBLE;
    Dummy := WinCreateWindow(H, $FFFF0005, LongInt(@Buf), St, 16 + Iw * 8, Cy - 16 * (Row + 1), (W - Iw) * 8, 16, H,
                             HWND_BOTTOM, $FFFF, 0, 0);
    Inc(Row);
  End;
  { boutons }
  Bx := ((Cx - BW * 8) Div 16) * 8;
  For K := 0 To NB - 1 Do
  Begin
    PutZ(LongInt(@Buf), Lab[K]);
    St := BS_PUSHBUTTON Or WS_VISIBLE Or WS_TABSTOP;
    If K = 0 Then St := St Or WS_GROUP;
    If K = Def Then St := St Or BS_DEFAULT;
    If Ids[K] = MBID_HELP Then St := St Or $100;
    If GMode <> 0 Then
      B := WinCreateWindow(H, $FFFF0003, LongInt(@Buf), St, Bx, 10, (VisLen(Lab[K]) + 4) * 8, 26, H, HWND_BOTTOM,
                           Ids[K], 0, 0)
    Else
      B := WinCreateWindow(H, $FFFF0003, LongInt(@Buf), St, Bx, 16, (VisLen(Lab[K]) + 4) * 8, 16, H, HWND_BOTTOM,
                           Ids[K], 0, 0);
    If (K = Def) And (WData[D] <> 0) Then WrL(WData[D] + $18, B);
    Bx := Bx + (VisLen(Lab[K]) + 6) * 8;
  End;
  If (Fl And $1000) <> 0 Then SysModalWin := D;
  R := WinProcessDlg(H);
  If SysModalWin = D Then SysModalWin := 0;
  Dummy := WinDestroyWindow(H);
  If (R = DID_CANCEL) And ((Fl And $0F) <> 1) And ((Fl And $0F) <> 2) And ((Fl And $0F) <> 5) And
     ((Fl And $0F) <> 6) And ((Fl And $0F) <> 8) Then R := Ids[Def];
  WinMessageBox := R;
End;

{ WinCreateStdWindow(hwndParent, flStyle, pflCreateFlags, pszClientClass,
  pszTitle, flClientStyle, hmod, idResources, phwndClient) }
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, IdRes, PClient : LongInt) : LongInt;
Var Fl, H, I, C, N, J : LongInt; Vis : Boolean;
Begin
  WinCreateStdWindow := 0;
  Fl := 0;
  If PFl <> 0 Then Fl := RdL(PFl);
  If (Fl And FCF_DLGBORDER) <> 0 Then Style := Style Or FS_DLGBORDER;
  If (Fl And FCF_BORDER) <> 0 Then Style := Style Or FS_BORDER;
  If (Fl And FCF_SIZEBORDER) <> 0 Then Style := Style Or FS_SIZEBORDER;
  If (Fl And FCF_TASKLIST) <> 0 Then Style := Style Or FS_TASKLIST;
  If (Fl And FCF_SYSMODAL) <> 0 Then Style := Style Or FS_SYSMODAL;
  If (Fl And FCF_SHELLPOSITION) <> 0 Then Style := Style Or FS_SHELLPOSITION;
  Vis := (Style And WS_VISIBLE) <> 0;
  Style := Style And Not WS_VISIBLE;
  H := WinCreateWindow(HPar, $FFFF0001, PTitle, Style, 0, 0, 0, 0, 0, HWND_TOP, IdRes, 0, 0);
  I := WIdx(H);
  If I < 2 Then Exit;
  CreateFrameCtls(I, Fl, Hmod, IdRes);
  C := 0;
  If PCls <> 0 Then
    If ClsNameOf(PCls) <> '' Then
    Begin
      C := WinCreateWindow(H, PCls, 0, CStyle Or WS_VISIBLE, 0, 0, 0, 0, H, HWND_BOTTOM, FID_CLIENT, 0, 0);
      If C = 0 Then
      Begin
        DestroyIdx(I);
        Exit;
      End;
    End;
  If (Fl And FCF_SHELLPOSITION) <> 0 Then
  Begin
    N := 0;
    For J := 2 To MaxWin - 1 Do
      If (J <> I) And (WUse[J] <> 0) And (WPar[J] = WPar[I]) And (KindOf(J) = CK_FRAME) Then Inc(N);
    N := N Mod 6;
    Dummy := WinSetWindowPos(H, 0, (4 + 2 * N) * 8, ScrCY - 32 - 16 * N - 288, 480, 288, SWP_MOVE Or SWP_SIZE);
  End
  Else Dummy := FormatFrameI(I, 0, 0);
  If PClient <> 0 Then WrL(PClient, C);
  If Vis Then Dummy := WinSetWindowPos(H, HWND_TOP, 0, 0, 0, 0, SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  WinCreateStdWindow := H;
End;

{ WinFlashWindow(hwnd, fFlash) : BOOL }
Function WinFlashWindow(H, FFlash : LongInt) : LongInt;
Begin
  If WChk(H) < 0 Then WinFlashWindow := 0
  Else
  Begin
    If FFlash <> 0 Then Dummy := WinAlarm(HWND_DESKTOP, 1);
    WinFlashWindow := 1;
  End;
End;

{ inverser le contour d'un rectangle de l'ecran }
Procedure TrackDraw(X1, Y1, X2, Y2 : LongInt);
Var C, R, C1, C2, R1, R2 : LongInt;
Begin
  If GMode <> 0 Then
  Begin
    GHideAll;
    GXorRaw(X1, Y1, X2, Y1 + 2); GXorRaw(X1, Y2 - 2, X2, Y2);
    GXorRaw(X1, Y1 + 2, X1 + 2, Y2 - 2); GXorRaw(X2 - 2, Y1 + 2, X2, Y2 - 2);
    Exit;
  End;
  C1 := MaxI(ColOf(X1), 0); C2 := MinI(ColOf(X2 - 1), ScrCols - 1);
  R1 := MaxI(RowOf(Y2 - 1), 0); R2 := MinI(RowOf(Y1), ScrRows - 1);
  If (C1 > C2) Or (R1 > R2) Then Exit;
  For C := C1 To C2 Do
  Begin
    R := GetAttr(C, R1);
    SetAttr(C, R1, ((R Shr 4) And 7) Or ((R And 7) Shl 4) Or (R And $88));
    If R2 <> R1 Then
    Begin
      R := GetAttr(C, R2);
      SetAttr(C, R2, ((R Shr 4) And 7) Or ((R And 7) Shl 4) Or (R And $88));
    End;
  End;
  For R := R1 + 1 To R2 - 1 Do
  Begin
    C := GetAttr(C1, R);
    SetAttr(C1, R, ((C Shr 4) And 7) Or ((C And 7) Shl 4) Or (C And $88));
    If C2 <> C1 Then
    Begin
      C := GetAttr(C2, R);
      SetAttr(C2, R, ((C Shr 4) And 7) Or ((C And 7) Shl 4) Or (C And $88));
    End;
  End;
End;

{ WinTrackRect(hwnd, hps, ptinfo) : suivi au clavier (fleches, Entree,
  Echap) ; TRACKINFO : cxBorder, cyBorder, cxGrid, cyGrid, cxKeyboard,
  cyKeyboard, rclTrack, rclBoundary, ptlMinTrackSize, ptlMaxTrackSize,
  fs (TF_LEFT 1, TF_TOP 2, TF_RIGHT 4, TF_BOTTOM 8, TF_ALLINBOUNDARY 80h) }
Function WinTrackRect(H, Hps, P : LongInt) : LongInt;
Var I, OX, OY, X1, Y1, X2, Y2, Dx, Dy, Fs, Sx, Sy, Sc, Ch, Vk, W, Hh, R : LongInt; Ki : Array[0..15] Of Byte;
    Done : Boolean;
Begin
  WinTrackRect := 0;
  If P = 0 Then Exit;
  I := WIdx(H);
  OX := 0; OY := 0;
  If I > 1 Then
  Begin
    OX := AbsX(I); OY := AbsY(I);
  End;
  Sx := RdL(P + 16); Sy := RdL(P + 20);
  If Sx <= 0 Then Sx := 8;
  If Sy <= 0 Then Sy := 16;
  Fs := RdL(P + 72);
  If (Fs And $0F) = 0 Then Fs := Fs Or $0F;
  X1 := RdL(P + 24); Y1 := RdL(P + 28); X2 := RdL(P + 32); Y2 := RdL(P + 36);
  Done := False; R := 0;
  While Not Done Do
  Begin
    TrackDraw(X1 + OX, Y1 + OY, X2 + OX, Y2 + OY);
    MemZero(LongInt(@Ki), 16);
    If KbdCharIn(LongInt(@Ki), 0, 0) <> 0 Then
    Begin
      TrackDraw(X1 + OX, Y1 + OY, X2 + OX, Y2 + OY);
      Exit;
    End;
    TrackDraw(X1 + OX, Y1 + OY, X2 + OX, Y2 + OY);
    Ch := Ki[0]; Sc := Ki[1];
    Vk := ScanVk(Sc, Ch);
    Dx := 0; Dy := 0;
    If Ch = 13 Then
    Begin
      Done := True; R := 1;
    End
    Else If Ch = 27 Then Done := True
    Else If Vk = VK_LEFT Then Dx := -Sx
    Else If Vk = VK_RIGHT Then Dx := Sx
    Else If Vk = VK_UP Then Dy := Sy
    Else If Vk = VK_DOWN Then Dy := -Sy;
    If (Dx <> 0) Or (Dy <> 0) Then
    Begin
      If (Fs And 1) <> 0 Then X1 := X1 + Dx;
      If (Fs And 4) <> 0 Then X2 := X2 + Dx;
      If (Fs And 8) <> 0 Then Y1 := Y1 + Dy;
      If (Fs And 2) <> 0 Then Y2 := Y2 + Dy;
      W := X2 - X1; Hh := Y2 - Y1;
      If (RdL(P + 56) > 0) And (W < RdL(P + 56)) Then
      Begin
        If (Fs And 1) <> 0 Then X1 := X2 - RdL(P + 56) Else X2 := X1 + RdL(P + 56);
      End;
      If (RdL(P + 60) > 0) And (Hh < RdL(P + 60)) Then
      Begin
        If (Fs And 8) <> 0 Then Y1 := Y2 - RdL(P + 60) Else Y2 := Y1 + RdL(P + 60);
      End;
      If (Fs And $80) <> 0 Then
      Begin
        If X1 < RdL(P + 40) Then
        Begin
          X2 := X2 + RdL(P + 40) - X1; X1 := RdL(P + 40);
        End;
        If Y1 < RdL(P + 44) Then
        Begin
          Y2 := Y2 + RdL(P + 44) - Y1; Y1 := RdL(P + 44);
        End;
        If X2 > RdL(P + 48) Then
        Begin
          X1 := X1 - (X2 - RdL(P + 48)); X2 := RdL(P + 48);
        End;
        If Y2 > RdL(P + 52) Then
        Begin
          Y1 := Y1 - (Y2 - RdL(P + 52)); Y2 := RdL(P + 52);
        End;
      End;
    End;
  End;
  If R <> 0 Then
  Begin
    WrL(P + 24, X1); WrL(P + 28, Y1); WrL(P + 32, X2); WrL(P + 36, Y2);
  End;
  WinTrackRect := R;
End;

Function WinShowTrackRect(H, FShow : LongInt) : LongInt;
Begin
  TrackShown := FShow;
  WinShowTrackRect := 1;
End;

{ WinExplodeWindow(hwnd, pswp) : position finale (sans animation) }
Function WinExplodeWindow(H, PSwp : LongInt) : LongInt;
Begin
  If PSwp = 0 Then WinExplodeWindow := 0
  Else WinExplodeWindow := WinSetWindowPos(H, RdL(PSwp + 20), RdL(PSwp + 16), RdL(PSwp + 12), RdL(PSwp + 8),
                                           RdL(PSwp + 4), RdL(PSwp));
End;

Const
  { majuscules (80h-FFh) et conversions 437 <-> 850 }
  Up437 : Array[0..127] Of LongInt = (
    $80, $9A, $90, $83, $8E, $85, $8F, $80, $88, $89, $8A, $8B, $8C, $8D, $8E, $8F,
    $90, $92, $92, $93, $99, $95, $96, $97, $98, $99, $9A, $9B, $9C, $9D, $9E, $9F,
    $A0, $A1, $A2, $A3, $A5, $A5, $A6, $A7, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF,
    $B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $BB, $BC, $BD, $BE, $BF,
    $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF,
    $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF,
    $E0, $E1, $E2, $E3, $E4, $E4, $E6, $E7, $E8, $E9, $EA, $EB, $EC, $E8, $EE, $EF,
    $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF);
  Up850 : Array[0..127] Of LongInt = (
    $80, $9A, $90, $B6, $8E, $B7, $8F, $80, $D2, $D3, $D4, $D8, $D7, $DE, $8E, $8F,
    $90, $92, $92, $E2, $99, $E3, $EA, $EB, $98, $99, $9A, $9D, $9C, $9D, $9E, $9F,
    $B5, $D6, $E0, $E9, $A5, $A5, $A6, $A7, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF,
    $B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $BB, $BC, $BD, $BE, $BF,
    $C0, $C1, $C2, $C3, $C4, $C5, $C7, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF,
    $D1, $D1, $D2, $D3, $D4, $49, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF,
    $E0, $E1, $E2, $E3, $E5, $E5, $E6, $E8, $E8, $E9, $EA, $EB, $ED, $ED, $EE, $EF,
    $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF);
  T437to850 : Array[0..127] Of LongInt = (
    $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8A, $8B, $8C, $8D, $8E, $8F,
    $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $BD, $9C, $BE, $3F, $9F,
    $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $3F, $AA, $AB, $AC, $AD, $AE, $AF,
    $B0, $B1, $B2, $B3, $B4, $3F, $3F, $3F, $3F, $B9, $BA, $BB, $BC, $3F, $3F, $BF,
    $C0, $C1, $C2, $C3, $C4, $C5, $3F, $3F, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $3F,
    $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $D9, $DA, $DB, $DC, $3F, $3F, $DF,
    $3F, $E1, $3F, $3F, $3F, $3F, $E6, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F,
    $3F, $F1, $3F, $3F, $3F, $3F, $F6, $3F, $F8, $3F, $FA, $3F, $3F, $FD, $FE, $FF);
  T850to437 : Array[0..127] Of LongInt = (
    $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8A, $8B, $8C, $8D, $8E, $8F,
    $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $3F, $9C, $3F, $3F, $9F,
    $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $3F, $AA, $AB, $AC, $AD, $AE, $AF,
    $B0, $B1, $B2, $B3, $B4, $3F, $3F, $3F, $3F, $B9, $BA, $BB, $BC, $9B, $9D, $BF,
    $C0, $C1, $C2, $C3, $C4, $C5, $3F, $3F, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $3F,
    $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $D9, $DA, $DB, $DC, $3F, $3F, $DF,
    $3F, $E1, $3F, $3F, $3F, $3F, $E6, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F,
    $3F, $F1, $3F, $3F, $3F, $3F, $F6, $3F, $F8, $3F, $FA, $3F, $3F, $FD, $FE, $FF);
  { couleurs du systeme par defaut (SYSCLR_x : rang -x) }
  ClrDef : Array[10..50] Of LongInt = (
    $00AAAA, $000000, $FFFFFF, $AAAAAA, $555555, $FFFFFF, $FFFFFF, $000000, $000000, $000000,
    $FFFFFF, $AAAAAA, $AAAAAA, $0000AA, $00AAAA, $00AAAA, $000000, $000000, $FFFFFF, $000000,
    $0000AA, $AAAAAA, $0000AA, $FFFFFF, $AAAAAA, $FFFFFF, $555555, $0000AA, $000000, $555555,
    $00AA00, $FFFFFF, $FFFFFF, $FFFFFF, $000000, $FFFFFF, $555555, $00AAAA, $555555, $FFFFFF,
    $555555);
  { valeurs du systeme par defaut }
  SvDef : Array[0..59] Of LongInt = (
    0, 500, 8, 16, 8, 16, 1, 0, 0, 500,
    200, 50, 0, 1000, 2000, 500, 50, 50, 50, 0,
    640, 400, 8, 16, 16, 8, 8, 16, 8, 16,
    16, 16, 8, 24, 16, 16, 640, 384, 32, 32,
    8, 16, 0, 3, 0, 0, 0, 32, 1, 8,
    16, 0, 0, 0, 0, 0, 1, 0, 0, 1);


{ ==================================================================== }
{ Partie 6 - Presse-papiers, atomes, tas, ressources, systeme          }
{ ==================================================================== }

{ --- presse-papiers (CF_TEXT 1 : le texte est copie par PMWIN) --- }
Function ClIdx(Fmt : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := MaxClip - 1 DownTo 0 Do
    If (ClFmt[K] = Fmt) And (Fmt <> 0) Then R := K;
  ClIdx := R;
End;

Procedure ClFree(K : LongInt);
Begin
  If (ClFmt[K] = 1) And (ClData[K] <> 0) Then MemFree(ClData[K]);
  ClFmt[K] := 0; ClData[K] := 0; ClInfo[K] := 0;
End;

Function ClOpenOk : Boolean;
Begin
  ClOpenOk := (ClOpen = MyPid);
End;

Function WinOpenClipbrd(Hab : LongInt) : LongInt;
Begin
  If (ClOpen <> 0) And (ClOpen <> MyPid) And Alive(ClOpen) Then WinOpenClipbrd := 0
  Else
  Begin
    ClOpen := MyPid;
    WinOpenClipbrd := 1;
  End;
End;

Function WinCloseClipbrd(Hab : LongInt) : LongInt;
Begin
  If Not ClOpenOk Then WinCloseClipbrd := 0
  Else
  Begin
    ClOpen := 0;
    If WIdx(ClViewer) > 1 Then Dummy := SendM(ClViewer, WM_DRAWCLIPBOARD, 0, 0);
    WinCloseClipbrd := 1;
  End;
End;

Function WinEmptyClipbrd(Hab : LongInt) : LongInt;
Var K : LongInt;
Begin
  If Not ClOpenOk Then WinEmptyClipbrd := 0
  Else
  Begin
    If WIdx(ClOwner) > 1 Then Dummy := SendM(ClOwner, WM_DESTROYCLIPBOARD, 0, 0);
    For K := 0 To MaxClip - 1 Do ClFree(K);
    ClOwner := 0;
    WinEmptyClipbrd := 1;
  End;
End;

Function WinSetClipbrdOwner(Hab, H : LongInt) : LongInt;
Begin
  If (H <> 0) And (WIdx(H) < 2) Then
  Begin
    SetErr(PMERR_INVALID_HWND);
    WinSetClipbrdOwner := 0;
  End
  Else
  Begin
    ClOwner := H;
    WinSetClipbrdOwner := 1;
  End;
End;

Function WinQueryClipbrdOwner(Hab : LongInt) : LongInt;
Begin
  If WIdx(ClOwner) > 1 Then WinQueryClipbrdOwner := ClOwner Else WinQueryClipbrdOwner := 0;
End;

{ WinSetClipbrdData(hab, ulData, fmt, rgfFmtInfo) : BOOL ; CFI_POINTER
  400h, CFI_HANDLE 200h, CFI_OWNERFREE 1, CFI_OWNERDISPLAY 2 }
Function WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt;
Var K, N, P : LongInt;
Begin
  WinSetClipbrdData := 0;
  If (Fmt = 0) Or Not ClOpenOk Then Exit;
  K := ClIdx(Fmt);
  If K < 0 Then
  Begin
    For N := MaxClip - 1 DownTo 0 Do
      If ClFmt[N] = 0 Then K := N;
  End
  Else ClFree(K);
  If K < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    Exit;
  End;
  ClFmt[K] := Fmt; ClInfo[K] := Info; ClData[K] := Data;
  If (Fmt = 1) And (Data <> 0) Then
  Begin
    N := 0;
    While (RdB(Data + N) <> 0) And (N < 16383) Do Inc(N);
    P := MemAlloc(N + 1);
    If P = 0 Then
    Begin
      ClFmt[K] := 0;
      SetErr(PMERR_HEAP_OUT_OF_MEMORY);
      Exit;
    End;
    MemMove(Data, P, N);
    WrB(P + N, 0);
    ClData[K] := P;
  End;
  WinSetClipbrdData := 1;
End;

Function WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := ClIdx(Fmt);
  If K < 0 Then WinQueryClipbrdData := 0 Else WinQueryClipbrdData := ClData[K];
End;

{ WinEnumClipbrdFmts(hab, fmt) : format suivant (0 : premier ; 0 a la fin) }
Function WinEnumClipbrdFmts(Hab, Fmt : LongInt) : LongInt;
Var K, R, S : LongInt;
Begin
  R := 0; S := 0;
  If Fmt <> 0 Then S := ClIdx(Fmt) + 1;
  If S < 0 Then S := MaxClip;
  For K := MaxClip - 1 DownTo S Do
    If ClFmt[K] <> 0 Then R := ClFmt[K];
  WinEnumClipbrdFmts := R;
End;

Function WinQueryClipbrdFmtInfo(Hab, Fmt, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := ClIdx(Fmt);
  If K < 0 Then WinQueryClipbrdFmtInfo := 0
  Else
  Begin
    If P <> 0 Then WrL(P, ClInfo[K]);
    WinQueryClipbrdFmtInfo := 1;
  End;
End;

Function WinSetClipbrdViewer(Hab, H : LongInt) : LongInt;
Begin
  If (H <> 0) And (WIdx(H) < 2) Then WinSetClipbrdViewer := 0
  Else
  Begin
    ClViewer := H;
    WinSetClipbrdViewer := 1;
  End;
End;

Function WinQueryClipbrdViewer(Hab : LongInt) : LongInt;
Begin
  If WIdx(ClViewer) > 1 Then WinQueryClipbrdViewer := ClViewer Else WinQueryClipbrdViewer := 0;
End;

{ visionneuse du systeme (WinSetSysClipbrdViewer) }
Function WinSetSysClipbrdViewer(Hab, H : LongInt) : LongInt;
Begin
  ClSysViewer := H;
  WinSetSysClipbrdViewer := 1;
End;

Function ClipGetText : String;
Var K : LongInt;
Begin
  K := ClIdx(1);
  If (K < 0) Or (ClData[K] = 0) Then ClipGetText := '' Else ClipGetText := GetZ(ClData[K]);
End;

Procedure ClipPutText(S : String);
Var Old : LongInt; Buf : Array[0..259] Of Byte;
Begin
  Old := ClOpen;
  ClOpen := MyPid;
  PutZ(LongInt(@Buf), S);
  Dummy := WinSetClipbrdData(0, LongInt(@Buf), 1, $400);
  ClOpen := Old;
End;

{ --- atomes (tables : 41540001h systeme ; atomes C000h + rang) --- }
Function AtbIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $41540001;
  If (I < 0) Or (I >= MaxAtomTbl) Then I := -1
  Else If AtbUse[I] = 0 Then I := -1;
  If I < 0 Then SetErr(PMERR_INVALID_HATOMTBL);
  AtbIdx := I;
End;

Function AtNameGet(K : LongInt) : String;
Var S : String; J, N : LongInt;
Begin
  S := '';
  N := AtName[K * AtomSlot];
  For J := 1 To N Do S := S + Chr(AtName[K * AtomSlot + J]);
  AtNameGet := S;
End;

{ atome entier : "#nnn" ou FFFFxxxxh ; rend 0 sinon }
Function IntAtom(P : LongInt; Var S : String) : LongInt;
Var V : LongInt;
Begin
  IntAtom := 0;
  S := '';
  If P = 0 Then Exit;
  If (P And $FFFF0000) = $FFFF0000 Then
  Begin
    IntAtom := P And $FFFF;
    Exit;
  End;
  S := GetZ(P);
  If (Length(S) > 1) And (Ord(S[1]) = 35) Then
    If StrToIntDef(Copy(S, 2, 255), V) Then
      If (V > 0) And (V < $C000) Then IntAtom := V;
End;

Function AtFind(T : LongInt; S : String) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  S := UpStr(S);
  For K := MaxAtom - 1 DownTo 0 Do
    If (AtUse[K] <> 0) And (AtTbl[K] = T) And (UpStr(AtNameGet(K)) = S) Then R := K;
  AtFind := R;
End;

Function WinCreateAtomTable(CbInit, CBuckets : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxAtomTbl - 1 DownTo 1 Do
    If AtbUse[I] = 0 Then F := I;
  If F < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    WinCreateAtomTable := 0;
  End
  Else
  Begin
    AtbUse[F] := 1; AtbOwner[F] := MyPid;
    WinCreateAtomTable := $41540001 + F;
  End;
End;

{ rend NULLHANDLE si la table est detruite }
Function WinDestroyAtomTable(H : LongInt) : LongInt;
Var T, K : LongInt;
Begin
  T := AtbIdx(H);
  If T <= 0 Then
  Begin
    WinDestroyAtomTable := H;
    Exit;
  End;
  For K := 0 To MaxAtom - 1 Do
    If AtTbl[K] = T Then AtUse[K] := 0;
  AtbUse[T] := 0;
  WinDestroyAtomTable := 0;
End;

Function WinAddAtom(H, P : LongInt) : LongInt;
Var T, K, F, V : LongInt; S : String;
Begin
  WinAddAtom := 0;
  T := AtbIdx(H);
  If T < 0 Then Exit;
  V := IntAtom(P, S);
  If V <> 0 Then
  Begin
    WinAddAtom := V;
    Exit;
  End;
  If (S = '') Or (Length(S) >= AtomSlot) Then
  Begin
    SetErr(PMERR_INVALID_ATOM_NAME);
    Exit;
  End;
  K := AtFind(T, S);
  If K >= 0 Then
  Begin
    Inc(AtUse[K]);
    WinAddAtom := $C000 + K;
    Exit;
  End;
  F := -1;
  For K := MaxAtom - 1 DownTo 0 Do
    If AtUse[K] = 0 Then F := K;
  If F < 0 Then
  Begin
    SetErr(PMERR_HEAP_OUT_OF_MEMORY);
    Exit;
  End;
  AtUse[F] := 1; AtTbl[F] := T;
  AtName[F * AtomSlot] := Length(S);
  For K := 1 To Length(S) Do AtName[F * AtomSlot + K] := Ord(S[K]);
  WinAddAtom := $C000 + F;
End;

Function WinFindAtom(H, P : LongInt) : LongInt;
Var T, K, V : LongInt; S : String;
Begin
  WinFindAtom := 0;
  T := AtbIdx(H);
  If T < 0 Then Exit;
  V := IntAtom(P, S);
  If V <> 0 Then
  Begin
    WinFindAtom := V;
    Exit;
  End;
  K := AtFind(T, S);
  If K >= 0 Then WinFindAtom := $C000 + K Else SetErr(PMERR_ATOM_NAME_NOT_FOUND);
End;

{ rang d'un atome de chaine de la table T (-1) }
Function AtOf(T, A : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := A - $C000;
  If (K < 0) Or (K >= MaxAtom) Then K := -1
  Else If (AtUse[K] = 0) Or (AtTbl[K] <> T) Then K := -1;
  AtOf := K;
End;

{ rend 0 si l'atome est supprime (ou son compte diminue) }
Function WinDeleteAtom(H, A : LongInt) : LongInt;
Var T, K : LongInt;
Begin
  WinDeleteAtom := A;
  T := AtbIdx(H);
  If T < 0 Then Exit;
  If (A > 0) And (A < $C000) Then
  Begin
    WinDeleteAtom := 0;
    Exit;
  End;
  K := AtOf(T, A);
  If K < 0 Then
  Begin
    SetErr(PMERR_INVALID_ATOM);
    Exit;
  End;
  Dec(AtUse[K]);
  WinDeleteAtom := 0;
End;

Function WinQueryAtomUsage(H, A : LongInt) : LongInt;
Var T, K : LongInt;
Begin
  WinQueryAtomUsage := 0;
  T := AtbIdx(H);
  If T < 0 Then Exit;
  If (A > 0) And (A < $C000) Then WinQueryAtomUsage := 65535
  Else
  Begin
    K := AtOf(T, A);
    If K >= 0 Then WinQueryAtomUsage := AtUse[K];
  End;
End;

Function AtomText(T, A : LongInt; Var Ok : Boolean) : String;
Var K : LongInt;
Begin
  Ok := True;
  If (A > 0) And (A < $C000) Then AtomText := '#' + IntStr(A)
  Else
  Begin
    K := AtOf(T, A);
    If K < 0 Then
    Begin
      Ok := False;
      AtomText := '';
    End
    Else AtomText := AtNameGet(K);
  End;
End;

Function WinQueryAtomLength(H, A : LongInt) : LongInt;
Var T : LongInt; Ok : Boolean; S : String;
Begin
  WinQueryAtomLength := 0;
  T := AtbIdx(H);
  If T < 0 Then Exit;
  S := AtomText(T, A, Ok);
  If Ok Then WinQueryAtomLength := Length(S);
End;

{ WinQueryAtomName(hAtomTbl, atom, pchBuffer, cchBufferMax) }
Function WinQueryAtomName(H, A, P, Cch : LongInt) : LongInt;
Var T : LongInt; Ok : Boolean; S : String;
Begin
  WinQueryAtomName := 0;
  T := AtbIdx(H);
  If T < 0 Then Exit;
  S := AtomText(T, A, Ok);
  If Ok Then WinQueryAtomName := PutZN(P, Cch, S);
End;

Function WinQuerySystemAtomTable : LongInt;
Begin
  WinQuerySystemAtomTable := $41540001;
End;

Function WinSetAtomTableOwner(H, Pid : LongInt) : LongInt;
Var T : LongInt;
Begin
  T := AtbIdx(H);
  If T < 0 Then WinSetAtomTableOwner := 0
  Else
  Begin
    AtbOwner[T] := Pid;
    WinSetAtomTableOwner := 1;
  End;
End;

{ --- tas (blocs de la memoire de PMWIN) --- }
Function HpIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $48450001;
  If (I < 0) Or (I >= MaxHeap) Then I := -1
  Else If HpUse[I] = 0 Then I := -1;
  If I < 0 Then SetErr(PMERR_INVALID_HHEAP);
  HpIdx := I;
End;

{ WinCreateHeap(selHeapBase, cbHeap, cbGrow, chMinDed, chMaxDed,
  fOptions) : HHEAP }
Function WinCreateHeap(Sel, Cb, Grow, MinD, MaxD, Opt : LongInt) : LongInt;
Var I, F, B : LongInt;
Begin
  WinCreateHeap := 0;
  If Cb <= 0 Then Cb := 4096;
  If Cb > 65536 Then Cb := 65536;
  Cb := (Cb + 7) And Not 7;
  F := -1;
  For I := MaxHeap - 1 DownTo 0 Do
    If (HpUse[I] = 0) Or Not Alive(HpUse[I]) Then F := I;
  If F < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    Exit;
  End;
  If HpUse[F] <> 0 Then MemFree(HpBase[F]);
  B := MemAlloc(Cb);
  If B = 0 Then
  Begin
    SetErr(PMERR_HEAP_OUT_OF_MEMORY);
    Exit;
  End;
  HeapInitIn(B, Cb);
  HpUse[F] := MyPid; HpBase[F] := B; HpSize[F] := Cb;
  WinCreateHeap := $48450001 + F;
End;

Function WinDestroyHeap(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := HpIdx(H);
  If I < 0 Then WinDestroyHeap := H
  Else
  Begin
    MemFree(HpBase[I]);
    HpUse[I] := 0;
    WinDestroyHeap := 0;
  End;
End;

Function WinAvailMem(H, FCompact, CbMin : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := HpIdx(H);
  If I < 0 Then WinAvailMem := 0 Else WinAvailMem := HeapAvailIn(HpBase[I], HpSize[I]);
End;

Function WinAllocMem(H, Cb : LongInt) : LongInt;
Var I, P : LongInt;
Begin
  WinAllocMem := 0;
  I := HpIdx(H);
  If I < 0 Then Exit;
  P := HeapAllocIn(HpBase[I], HpSize[I], MaxI(Cb, 1));
  If P = 0 Then SetErr(PMERR_HEAP_OUT_OF_MEMORY);
  WinAllocMem := P;
End;

Function InHeap(I, P : LongInt) : Boolean;
Begin
  InHeap := (P >= HpBase[I] + 8) And (P < HpBase[I] + HpSize[I]);
End;

{ WinFreeMem(hHeap, npMem, cbMem) : NULL si libere }
Function WinFreeMem(H, P, Cb : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinFreeMem := P;
  I := HpIdx(H);
  If I < 0 Then Exit;
  If Not InHeap(I, P) Then
  Begin
    SetErr(PMERR_INVALID_HEAP_POINTER);
    Exit;
  End;
  HeapFreeIn(P);
  WinFreeMem := 0;
End;

{ WinReallocMem(hHeap, npMem, cbOld, cbNew) }
Function WinReallocMem(H, P, CbOld, CbNew : LongInt) : LongInt;
Var I, Q : LongInt;
Begin
  WinReallocMem := 0;
  I := HpIdx(H);
  If I < 0 Then Exit;
  If P = 0 Then
  Begin
    WinReallocMem := WinAllocMem(H, CbNew);
    Exit;
  End;
  If Not InHeap(I, P) Then
  Begin
    SetErr(PMERR_INVALID_HEAP_POINTER);
    Exit;
  End;
  If HeapSizeOf(P) >= CbNew Then
  Begin
    WinReallocMem := P;
    Exit;
  End;
  Q := HeapAllocIn(HpBase[I], HpSize[I], MaxI(CbNew, 1));
  If Q = 0 Then
  Begin
    SetErr(PMERR_HEAP_OUT_OF_MEMORY);
    Exit;
  End;
  MemMove(P, Q, MinI(HeapSizeOf(P), CbNew));
  HeapFreeIn(P);
  WinReallocMem := Q;
End;

Function WinLockHeap(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := HpIdx(H);
  If I < 0 Then WinLockHeap := 0 Else WinLockHeap := HpBase[I];
End;

{ tas "lointains" : memes tas }
Function WinCreateFarHeap(Hab, Cb : LongInt) : LongInt;
Begin
  WinCreateFarHeap := WinCreateHeap(0, Cb, 0, 0, 0, 0);
End;

Function WinDestoryFarHeap(H : LongInt) : LongInt;
Begin
  If WinDestroyHeap(H) = 0 Then WinDestoryFarHeap := 1 Else WinDestoryFarHeap := 0;
End;

Function WinAllocFarMem(H, Cb : LongInt) : LongInt;
Begin
  WinAllocFarMem := WinAllocMem(H, Cb);
End;

Function WinFreeFarMem(H, P, Cb : LongInt) : LongInt;
Begin
  If WinFreeMem(H, P, Cb) = 0 Then WinFreeFarMem := 1 Else WinFreeFarMem := 0;
End;

Function WinReallocFarMem(H, P, CbOld, CbNew : LongInt) : LongInt;
Begin
  WinReallocFarMem := WinReallocMem(H, P, CbOld, CbNew);
End;

{ --- chaines des ressources : RT_STRING 5 / RT_MESSAGE 10, paquets de
  16 chaines (ressource id Div 16 + 1) : USHORT codepage, puis pour
  chaque chaine un octet de longueur (zero final compris) et le texte --- }
Function ResString(Hmod, Typ, Id : LongInt; Var S : String) : Boolean;
Var P, Off, K, L : LongInt;
Begin
  ResString := False;
  S := '';
  P := GetRes(Hmod, Typ, (Id Div 16) + 1);
  If P = 0 Then Exit;
  Off := 2;
  For K := 0 To Id Mod 16 Do
  Begin
    L := RdB(P + Off);
    If K = Id Mod 16 Then
    Begin
      If L = 0 Then Exit;
      S := GetN(P + Off + 1, L - 1);
      ResString := True;
    End;
    Off := Off + 1 + L;
  End;
End;

{ WinLoadString(hab, hmod, id, cchMax, pchBuffer) : longueur }
Function WinLoadString(Hab, Hmod, Id, Cch, P : LongInt) : LongInt;
Var S : String;
Begin
  If ResString(Hmod, 5, Id, S) Then WinLoadString := PutZN(P, Cch, S)
  Else
  Begin
    SetErr(PMERR_RESOURCE_NOT_FOUND);
    If (P <> 0) And (Cch > 0) Then WrB(P, 0);
    WinLoadString := 0;
  End;
End;

Function WinLoadMessage(Hab, Hmod, Id, Cch, P : LongInt) : LongInt;
Var S : String;
Begin
  If ResString(Hmod, 10, Id, S) Then WinLoadMessage := PutZN(P, Cch, S)
  Else
  Begin
    SetErr(PMERR_RESOURCE_NOT_FOUND);
    If (P <> 0) And (Cch > 0) Then WrB(P, 0);
    WinLoadMessage := 0;
  End;
End;

{ WinLoadStringTable(hab, hmod, idBundle, cb, pb) : copie le paquet ;
  rend sa taille }
Function WinLoadStringTable(Hab, Hmod, Id, Cb, P : LongInt) : LongInt;
Var R, Sz : LongInt;
Begin
  WinLoadStringTable := 0;
  R := GetRes(Hmod, 5, Id);
  If R = 0 Then
  Begin
    SetErr(PMERR_RESOURCE_NOT_FOUND);
    Exit;
  End;
  Sz := 0;
  If DcQueryResourceSize(Hmod, 5, Id, LongInt(@Sz)) <> 0 Then Sz := 0;
  If (P <> 0) And (Cb > 0) Then MemMove(R, P, MinI(Sz, Cb));
  WinLoadStringTable := Sz;
End;

{ --- valeurs et couleurs du systeme --- }
Function WinQuerySysValue(HDesk, I : LongInt) : LongInt;
Begin
  If (I < 0) Or (I > 127) Then
  Begin
    SetErr(PMERR_PARAMETER_OUT_OF_RANGE);
    WinQuerySysValue := 0;
  End
  Else WinQuerySysValue := SysVal[I];
End;

Function WinSetSysValue(HDesk, I, V : LongInt) : LongInt;
Begin
  WinSetSysValue := 0;
  If (I < 0) Or (I > 127) Or (I = 20) Or (I = 21) Or (I = 108) Then
  Begin
    SetErr(PMERR_PARAMETER_OUT_OF_RANGE);
    Exit;
  End;
  SysVal[I] := V;
  Dummy := WinBroadcastMsg(HWND_DESKTOP, WM_SYSVALUECHANGED, I, I, 1 Or 8);
  WinSetSysValue := 1;
End;

{ couleur RVB d'une couleur PM }
Function ClrRgb(C : LongInt) : LongInt;
Begin
  If C = -1 Then ClrRgb := 0
  Else If C = -2 Then ClrRgb := $FFFFFF
  Else If (C <= -10) And (C >= -63) Then ClrRgb := SysClr[-C]
  Else If (C >= 0) And (C <= 15) Then ClrRgb := VgaRgb[ClrVga[C]]
  Else ClrRgb := C And $FFFFFF;
End;

Function WinQuerySysColor(HDesk, Clr, Rsvd : LongInt) : LongInt;
Begin
  If (Clr > -10) Or (Clr < -63) Then
  Begin
    SetErr(PMERR_PARAMETER_OUT_OF_RANGE);
    WinQuerySysColor := -255;
  End
  Else WinQuerySysColor := SysClr[-Clr];
End;

Procedure SysClrDefaults;
Var K : LongInt;
Begin
  For K := 10 To 50 Do SysClr[K] := ClrDef[K];
End;

{ WinSetSysColors(hwndDesktop, flOptions, flFormat, clrFirst, cclr, pclr) :
  LCOL_RESET 1 ; LCOLF_INDRGB 1 (paires index, RVB), LCOLF_CONSECRGB 2 }
Function WinSetSysColors(HDesk, Opt, Fmt, First, N, P : LongInt) : LongInt;
Var K, C : LongInt;
Begin
  WinSetSysColors := 0;
  If (Opt And 1) <> 0 Then SysClrDefaults;
  If (N > 0) And (P <> 0) Then
  Begin
    If Fmt = 1 Then
    Begin
      For K := 0 To (N Div 2) - 1 Do
      Begin
        C := RdL(P + K * 8);
        If (C <= -10) And (C >= -63) Then SysClr[-C] := RdL(P + K * 8 + 4) And $FFFFFF;
      End;
    End
    Else If Fmt = 2 Then
    Begin
      For K := 0 To N - 1 Do
      Begin
        C := First + K;
        If (C <= -10) And (C >= -63) Then SysClr[-C] := RdL(P + K * 4) And $FFFFFF;
      End;
    End
    Else
    Begin
      SetErr(PMERR_INVALID_PARAMETERS);
      Exit;
    End;
  End;
  InvalScreen(0, 0, ScrCX, ScrCY);
  Dummy := WinBroadcastMsg(HWND_DESKTOP, WM_SYSCOLORCHANGE, 0, 0, 1 Or 4);
  WinSetSysColors := 1;
End;

{ --- pages de codes --- }
Function CpOk(Cp : LongInt) : Boolean;
Begin
  CpOk := (Cp = 0) Or (Cp = 437) Or (Cp = 850) Or (Cp = 852) Or (Cp = 857) Or (Cp = 860) Or (Cp = 861) Or
          (Cp = 863) Or (Cp = 865) Or (Cp = 866) Or (Cp = 869) Or (Cp = 1004);
End;

Function CurCp : LongInt;
Var Q : LongInt;
Begin
  Q := CurQ;
  If Q < 0 Then CurCp := 850 Else CurCp := QCp[Q];
End;

Function WinQueryCp(Hmq : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := QIdx(Hmq);
  If Q < 0 Then WinQueryCp := 0 Else WinQueryCp := QCp[Q];
End;

Function WinSetCp(Hmq, Cp : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := QIdx(Hmq);
  If (Q < 0) Or (Cp = 0) Or Not CpOk(Cp) Then WinSetCp := 0
  Else
  Begin
    QCp[Q] := Cp;
    WinSetCp := 1;
  End;
End;

Function WinQueryProcessCP(Hmq : LongInt) : LongInt;
Begin
  WinQueryProcessCP := CurCp;
End;

Function WinQueryCpList(Hab, N, P : LongInt) : LongInt;
Begin
  If (P <> 0) And (N >= 1) Then WrL(P, 437);
  If (P <> 0) And (N >= 2) Then WrL(P + 4, 850);
  WinQueryCpList := 2;
End;

Function UpperCh(Cp, C : LongInt) : LongInt;
Begin
  C := C And 255;
  If (C >= 97) And (C <= 122) Then UpperCh := C - 32
  Else If C >= 128 Then
  Begin
    If Cp = 437 Then UpperCh := Up437[C - 128]
    Else If (Cp = 850) Or (Cp = 0) Then UpperCh := Up850[C - 128]
    Else UpperCh := C;
  End
  Else UpperCh := C;
End;

Function XlateCh(CpS, CpD, C : LongInt) : LongInt;
Begin
  C := C And 255;
  If CpS = 0 Then CpS := CurCp;
  If CpD = 0 Then CpD := CurCp;
  If (C < 128) Or (CpS = CpD) Then XlateCh := C
  Else If (CpS = 437) And (CpD = 850) Then XlateCh := T437to850[C - 128]
  Else If (CpS = 850) And (CpD = 437) Then XlateCh := T850to437[C - 128]
  Else XlateCh := C;
End;

{ WinCpTranslateString(hab, cpSrc, pszSrc, cpDst, cchDestMax, pchDest) : BOOL }
Function WinCpTranslateString(Hab, CpS, PSrc, CpD, Cch, PDst : LongInt) : LongInt;
Var K, C : LongInt;
Begin
  WinCpTranslateString := 0;
  If Not CpOk(CpS) Then
  Begin
    SetErr(PMERR_INVALID_SRC_CODEPAGE);
    Exit;
  End;
  If Not CpOk(CpD) Then
  Begin
    SetErr(PMERR_INVALID_DST_CODEPAGE);
    Exit;
  End;
  If (PSrc = 0) Or (PDst = 0) Or (Cch <= 0) Then Exit;
  K := 0;
  C := RdB(PSrc);
  While (C <> 0) And (K < Cch - 1) Do
  Begin
    WrB(PDst + K, XlateCh(CpS, CpD, C));
    Inc(K);
    C := RdB(PSrc + K);
  End;
  WrB(PDst + K, 0);
  WinCpTranslateString := 1;
End;

Function WinCpTranslateChar(Hab, CpS, C, CpD : LongInt) : LongInt;
Begin
  WinCpTranslateChar := XlateCh(CpS, CpD, C);
End;

{ WinUpper(hab, idcp, idcc, psz) : longueur }
Function WinUpper(Hab, Cp, Cc, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := 0;
  If P <> 0 Then
  Begin
    If Cp = 0 Then Cp := CurCp;
    While RdB(P + K) <> 0 Do
    Begin
      WrB(P + K, UpperCh(Cp, RdB(P + K)));
      Inc(K);
    End;
  End;
  WinUpper := K;
End;

Function WinUpperChar(Hab, Cp, Cc, C : LongInt) : LongInt;
Begin
  If Cp = 0 Then Cp := CurCp;
  WinUpperChar := UpperCh(Cp, C);
End;

{ WinCompareStrings(hab, idcp, idcc, psz1, psz2, reserved) : WCS_EQ 1,
  WCS_LT 2, WCS_GT 3 (sans tenir compte de la casse) }
Function WinCompareStrings(Hab, Cp, Cc, P1, P2, Rsvd : LongInt) : LongInt;
Var K, A, B, R : LongInt;
Begin
  WinCompareStrings := 0;
  If (P1 = 0) Or (P2 = 0) Then Exit;
  If Cp = 0 Then Cp := CurCp;
  K := 0; R := 1;
  Repeat
    A := UpperCh(Cp, RdB(P1 + K)); B := UpperCh(Cp, RdB(P2 + K));
    If A < B Then R := 2 Else If A > B Then R := 3;
    Inc(K);
  Until (R <> 1) Or (A = 0) Or (B = 0);
  WinCompareStrings := R;
End;

Function WinNextChar(Hab, Cp, Cc, P : LongInt) : LongInt;
Begin
  If (P <> 0) And (RdB(P) <> 0) Then WinNextChar := P + 1 Else WinNextChar := P;
End;

Function WinPrevChar(Hab, Cp, Cc, PStart, P : LongInt) : LongInt;
Begin
  If P > PStart Then WinPrevChar := P - 1 Else WinPrevChar := PStart;
End;

{ --- tables de traduction du clavier et disposition --- }

Function WinLoadVkeyGlyphXlatetbl(Hab, Hmod, Id : LongInt) : LongInt;
Begin
  WinLoadVkeyGlyphXlatetbl := GetRes(Hmod, 12, Id);
End;

Function WinLoadCharXlatetbl(Hab, Hmod, Id : LongInt) : LongInt;
Begin
  WinLoadCharXlatetbl := GetRes(Hmod, 14, Id);
End;

Function WinSetVkeyGlyphXlatetbl(Hab, P : LongInt) : LongInt;
Begin
  VkXlate := P;
  WinSetVkeyGlyphXlatetbl := 1;
End;

Function WinSetCharXlatetbl(Hab, P : LongInt) : LongInt;
Begin
  ChXlate := P;
  WinSetCharXlatetbl := 1;
End;

Function WinQueryVkeyGlyphXlatetbl(Hab : LongInt) : LongInt;
Begin
  WinQueryVkeyGlyphXlatetbl := VkXlate;
End;

Function WinQueryCharXlatetbl(Hab : LongInt) : LongInt;
Begin
  WinQueryCharXlatetbl := ChXlate;
End;

{ WinVkeyGlyphCharXlate(hab, vkey, fs) : caractere d'une touche virtuelle }
Function WinVkeyGlyphCharXlate(Hab, Vk, Fs : LongInt) : LongInt;
Begin
  If Vk = VK_SPACE Then WinVkeyGlyphCharXlate := 32
  Else If Vk = VK_TAB Then WinVkeyGlyphCharXlate := 9
  Else If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then WinVkeyGlyphCharXlate := 13
  Else If Vk = VK_ESC Then WinVkeyGlyphCharXlate := 27
  Else If Vk = VK_BACKSPACE Then WinVkeyGlyphCharXlate := 8
  Else WinVkeyGlyphCharXlate := 0;
End;

{ WinVkeyToScanId(hab, vkey) : code de balayage }
Function WinVkeyToScanId(Hab, Vk : LongInt) : LongInt;
Var S, R : LongInt;
Begin
  R := 0;
  For S := 255 DownTo 1 Do
    If ScanVk(S, 0) = Vk Then R := S;
  WinVkeyToScanId := R;
End;

Function WinTranslateChar(Hab, Ch : LongInt) : LongInt;
Begin
  WinTranslateChar := Ch;
End;

Function WinQueryKbdLayout(HDesk, P, Cb : LongInt) : LongInt;
Begin
  If P = 0 Then WinQueryKbdLayout := 0
  Else WinQueryKbdLayout := PutZN(P, Cb, GetZ(LongInt(@KbdLayout)));
End;

Function WinSetKbdLayout(HDesk, P : LongInt) : LongInt;
Begin
  If P = 0 Then WinSetKbdLayout := 0
  Else
  Begin
    Dummy := PutZN(LongInt(@KbdLayout), 16, GetZ(P));
    WinSetKbdLayout := 1;
  End;
End;

Function WinSetKbdLayout2(HDesk, P, Fl : LongInt) : LongInt;
Begin
  WinSetKbdLayout2 := WinSetKbdLayout(HDesk, P);
End;

Function WinLoadTranslationTable(Hab, Hmod, Id : LongInt) : LongInt;
Begin
  WinLoadTranslationTable := GetRes(Hmod, 13, Id);
End;

{ WinEnumVKeyScanIDs(hab, vkey, prgScan, cMax) : nombre de codes }
Function WinEnumVKeyScanIDs(Hab, Vk, P, N : LongInt) : LongInt;
Var S, C : LongInt;
Begin
  C := 0;
  For S := 1 To 255 Do
    If ScanVk(S, 0) = Vk Then
    Begin
      If (P <> 0) And (C < N) Then WrB(P + C, S);
      Inc(C);
    End;
  WinEnumVKeyScanIDs := C;
End;

{ --- erreurs --- }
Function ErrHab(Hab : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := HabIdx(Hab);
  If I < 0 Then I := CurHab;
  ErrHab := I;
End;

Function WinGetLastError(Hab : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ErrHab(Hab);
  If I < 0 Then WinGetLastError := 0
  Else
  Begin
    WinGetLastError := HabErr[I];
    HabErr[I] := 0;
  End;
End;

{ WinGetErrorInfo(hab) : ERRINFO (cbFixedErrInfo, idError, cDetailLevel,
  offaoffszMsg, offBinaryData), un message et 4 octets de donnees }
Function WinGetErrorInfo(Hab : LongInt) : LongInt;
Var I, P, E : LongInt; S : String;
Begin
  WinGetErrorInfo := 0;
  I := ErrHab(Hab);
  If I < 0 Then Exit;
  E := HabErr[I];
  If E = 0 Then Exit;
  S := 'PMWIN : erreur ' + IntStr(E And $FFFF);
  P := MemAlloc(28 + Length(S) + 1 + 4);
  If P = 0 Then Exit;
  WrL(P, 20); WrL(P + 4, E); WrL(P + 8, 1); WrL(P + 12, 20); WrL(P + 16, 28 + Length(S) + 1);
  WrL(P + 20, 24);
  PutZ(P + 24, S);
  WrL(P + 28 + Length(S) + 1 - 4, 0);
  WrL(P + 28 + Length(S) + 1, E);
  WinGetErrorInfo := P;
End;

Function WinFreeErrorInfo(P : LongInt) : LongInt;
Begin
  If (P < LongInt(@Arena)) Or (P >= LongInt(@Arena) + ArenaSize) Then WinFreeErrorInfo := 0
  Else
  Begin
    MemFree(P);
    WinFreeErrorInfo := 1;
  End;
End;

{ WinSetErrorInfo(errorid, fsOptions) : fixe l'erreur du processus }
Function WinSetErrorInfo(E, Fs : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := CurHab;
  If I >= 0 Then HabErr[I] := E;
  WinSetErrorInfo := E;
End;

Function XWinSetErrorInfo(E, Fs : LongInt) : LongInt;
Begin
  XWinSetErrorInfo := WinSetErrorInfo(E, Fs);
End;

Function WinSetLastError(Hab, E : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ErrHab(Hab);
  If I < 0 Then WinSetLastError := 0
  Else
  Begin
    HabErr[I] := E;
    WinSetLastError := 1;
  End;
End;

{ --- presentation (parametres : PpWin = rang + 1) --- }
Function PPFind(I, Id : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := MaxPP - 1 DownTo 0 Do
    If (PpWin[K] = I + 1) And (PpId[K] = Id) Then R := K;
  PPFind := R;
End;

Procedure PPRemoveAll(I : LongInt);
Var K : LongInt;
Begin
  For K := 0 To MaxPP - 1 Do
    If PpWin[K] = I + 1 Then PpWin[K] := 0;
End;

Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt;
Var I, K, F : LongInt;
Begin
  WinSetPresParam := 0;
  I := WChk(H);
  If (I < 0) Or (Cb < 0) Or ((Cb > 0) And (P = 0)) Then Exit;
  K := PPFind(I, Id);
  If K < 0 Then
  Begin
    For F := MaxPP - 1 DownTo 0 Do
      If PpWin[F] = 0 Then K := F;
  End;
  If K < 0 Then
  Begin
    SetErr(PMERR_NO_HANDLE_ALLOC);
    Exit;
  End;
  Cb := MinI(Cb, 64);
  PpWin[K] := I + 1; PpId[K] := Id; PpLen[K] := Cb;
  MemMove(P, LongInt(@PpData) + K * 64, Cb);
  Dummy := SendM(H, WM_PRESPARAMCHANGED, Id, 0);
  InvalWin(I);
  WinSetPresParam := 1;
End;

Function WinRemovePresParam(H, Id : LongInt) : LongInt;
Var I, K : LongInt;
Begin
  WinRemovePresParam := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  K := PPFind(I, Id);
  If K < 0 Then Exit;
  PpWin[K] := 0;
  Dummy := SendM(H, WM_PRESPARAMCHANGED, Id, 0);
  InvalWin(I);
  WinRemovePresParam := 1;
End;

{ chercher Id dans la fenetre et (Inh) ses parents ; rend le rang }
Function PPSearch(I, Id : LongInt; Inh : Boolean) : LongInt;
Var K, N : LongInt;
Begin
  K := -1; N := 0;
  While (K < 0) And (I >= 0) And (N < 64) Do
  Begin
    K := PPFind(I, Id);
    If (K < 0) And Inh And (I > 1) Then I := WPar[I] Else I := -1;
    Inc(N);
  End;
  PPSearch := K;
End;

{ WinQueryPresParam(hwnd, id1, id2, pulId, cbBuf, pbBuf, fs) : octets ;
  QPF_NOINHERIT 1, QPF_ID1COLORINDEX 2, QPF_ID2COLORINDEX 4,
  QPF_PURERGBCOLOR 8 }
Function WinQueryPresParam(H, Id1, Id2, PId, Cb, P, Fs : LongInt) : LongInt;
Var I, K, Id, V : LongInt; Inh, Idx : Boolean;
Begin
  WinQueryPresParam := 0;
  I := WChk(H);
  If I < 0 Then Exit;
  Inh := (Fs And 1) = 0;
  Idx := False;
  K := -1; Id := 0;
  If Id1 <> 0 Then
  Begin
    K := PPSearch(I, Id1, Inh);
    Id := Id1;
    Idx := (Fs And 2) <> 0;
  End;
  If (K < 0) And (Id2 <> 0) Then
  Begin
    K := PPSearch(I, Id2, Inh);
    Id := Id2;
    Idx := (Fs And 4) <> 0;
  End;
  If K < 0 Then Exit;
  If PId <> 0 Then WrL(PId, Id);
  If Idx And (PpLen[K] >= 4) And (Cb >= 4) And (P <> 0) Then
  Begin
    V := RdL(LongInt(@PpData) + K * 64);
    WrL(P, ClrRgb(V));
    WinQueryPresParam := 4;
  End
  Else
  Begin
    If P <> 0 Then MemMove(LongInt(@PpData) + K * 64, P, MinI(Cb, PpLen[K]));
    WinQueryPresParam := MinI(Cb, PpLen[K]);
  End;
End;

{ couleur d'un parametre (Id RVB ; Id + 1 : index) ; Def sinon }
Function PPColor(I, Id, Def : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := PPSearch(I, Id, True);
  If (K >= 0) And (PpLen[K] >= 4) Then PPColor := (RdL(LongInt(@PpData) + K * 64) And $FFFFFF) Or $01000000
  Else
  Begin
    K := PPSearch(I, Id + 1, True);
    If (K >= 0) And (PpLen[K] >= 4) Then PPColor := RdL(LongInt(@PpData) + K * 64)
    Else PPColor := Def;
  End;
End;

{ parametres d'un arbre de cadre : suite de (id de fenetre, id, cb,
  octets) ; id de fenetre FFFFFFFFh : le cadre }
Function FtpSize(F : LongInt) : LongInt;
Var K, N, W : LongInt;
Begin
  N := 0;
  For K := 0 To MaxPP - 1 Do
    If PpWin[K] > 0 Then
    Begin
      W := PpWin[K] - 1;
      If (W = F) Or IsChildOf(W, F) Then N := N + 12 + PpLen[K];
    End;
  FtpSize := N;
End;

Function WinGetFrameTreePPSize(H : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := WChk(H);
  If F < 0 Then WinGetFrameTreePPSize := 0 Else WinGetFrameTreePPSize := FtpSize(F);
End;

Function WinGetFrameTreePPs(H, Cb, P : LongInt) : LongInt;
Var F, K, N, W : LongInt;
Begin
  WinGetFrameTreePPs := 0;
  F := WChk(H);
  If (F < 0) Or (P = 0) Then Exit;
  N := 0;
  For K := 0 To MaxPP - 1 Do
    If PpWin[K] > 0 Then
    Begin
      W := PpWin[K] - 1;
      If ((W = F) Or IsChildOf(W, F)) And (N + 12 + PpLen[K] <= Cb) Then
      Begin
        If W = F Then WrL(P + N, -1) Else WrL(P + N, WId[W]);
        WrL(P + N + 4, PpId[K]); WrL(P + N + 8, PpLen[K]);
        MemMove(LongInt(@PpData) + K * 64, P + N + 12, PpLen[K]);
        N := N + 12 + PpLen[K];
      End;
    End;
  WinGetFrameTreePPs := N;
End;

{ WinSetFrameTreePPs(hwnd, cb, p) : BOOL }
Function WinSetFrameTreePPs(H, Cb, P : LongInt) : LongInt;
Var F, N, W, J : LongInt;
Begin
  WinSetFrameTreePPs := 0;
  F := WChk(H);
  If (F < 0) Or (P = 0) Then Exit;
  N := 0;
  While N + 12 <= Cb Do
  Begin
    If RdL(P + N) = -1 Then W := F
    Else
    Begin
      W := -1;
      For J := MaxWin - 1 DownTo 2 Do
        If (WUse[J] <> 0) And (WId[J] = RdL(P + N)) And IsChildOf(J, F) Then W := J;
    End;
    If W >= 0 Then Dummy := WinSetPresParam(HwOf(W), RdL(P + N + 4), RdL(P + N + 8), P + N + 12);
    N := N + 12 + RdL(P + N + 8);
  End;
  WinSetFrameTreePPs := 1;
End;

{ --- bureau --- }
{ WinSetDesktopBkgnd(hwndDesktop, pdskNew) : DESKTOP (cbSize, hbm, x, y,
  fl, lTileCount, szFile[260]) ; rend la bitmap }
Function WinSetDesktopBkgnd(HDesk, P : LongInt) : LongInt;
Begin
  WinSetDesktopBkgnd := 0;
  If P = 0 Then Exit;
  MemMove(P, LongInt(@DeskBkgnd), MinI(MaxI(RdL(P), 24), 284));
  InvalScreen(0, 0, ScrCX, ScrCY);
  If RdL(P + 4) <> 0 Then WinSetDesktopBkgnd := RdL(P + 4) Else WinSetDesktopBkgnd := 1;
End;

Function WinQueryDesktopBkgnd(HDesk, P : LongInt) : LongInt;
Begin
  If P = 0 Then WinQueryDesktopBkgnd := 0
  Else
  Begin
    MemMove(LongInt(@DeskBkgnd), P, 284);
    WrL(P, 284);
    WinQueryDesktopBkgnd := 1;
  End;
End;

{ WinRealizePalette(hwnd, hps, pcclr) : couleurs changees (aucune) }
Function WinRealizePalette(H, Hps, P : LongInt) : LongInt;
Begin
  If P <> 0 Then WrL(P, 0);
  WinRealizePalette := 0;
End;

Function WinSetSysFont(HDesk, P : LongInt) : LongInt;
Begin
  If P = 0 Then WinSetSysFont := 0
  Else
  Begin
    Dummy := PutZN(LongInt(@SysFont), 64, GetZ(P));
    WinSetSysFont := 1;
  End;
End;

{ --- divers de l'interface --- }
Function WinRegisterUserMsg(Hab, Msg, T1, D1, T2, D2, Tr : LongInt) : LongInt;
Begin
  WinRegisterUserMsg := 1;
End;

Function WinRegisterUserDatatype(Hab, T, N, P : LongInt) : LongInt;
Begin
  WinRegisterUserDatatype := 1;
End;

{ WinSetMsgMode(hab, pszClassName, control) : BOOL }
Function WinSetMsgMode(Hab, PCls, Ctl : LongInt) : LongInt;
Var C : LongInt;
Begin
  WinSetMsgMode := 1;
  If PCls <> 0 Then
  Begin
    C := ClsFind(ClsNameOf(PCls));
    If C >= 0 Then CMsgMode[C] := Ctl;
  End;
End;

Function WinSetSynchroMode(Hab, Mode : LongInt) : LongInt;
Begin
  WinSetSynchroMode := 1;
End;

Function WinSetClassThunkProc(PCls, Pfn : LongInt) : LongInt;
Var C : LongInt;
Begin
  C := ClsFind(ClsNameOf(PCls));
  If C < 0 Then WinSetClassThunkProc := 0
  Else
  Begin
    CThunk[C] := Pfn;
    WinSetClassThunkProc := 1;
  End;
End;

Function WinQueryClassThunkProc(PCls : LongInt) : LongInt;
Var C : LongInt;
Begin
  C := ClsFind(ClsNameOf(PCls));
  If C < 0 Then WinQueryClassThunkProc := 0 Else WinQueryClassThunkProc := CThunk[C];
End;

Function WinSetWindowThunkProc(H, Pfn : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 0 Then WinSetWindowThunkProc := 0
  Else
  Begin
    WThunk[I] := Pfn;
    WinSetWindowThunkProc := 1;
  End;
End;

Function WinQueryWindowThunkProc(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WChk(H);
  If I < 0 Then WinQueryWindowThunkProc := 0 Else WinQueryWindowThunkProc := WThunk[I];
End;

{ --- semaphores (attente sans traitement des messages envoyes : les
  messages sont remis aussitot) --- }
Function WinMsgSemWait(H, T : LongInt) : LongInt;
Begin
  WinMsgSemWait := DcSemWait(H, T);
End;

Function WinMsgMuxSemWait(PI, PL, T : LongInt) : LongInt;
Begin
  WinMsgMuxSemWait := DcMuxSemWait(PI, PL, T);
End;

Function WinWaitEventSem(H, T : LongInt) : LongInt;
Begin
  WinWaitEventSem := DcWaitEventSem(H, T);
End;

Function WinRequestMutexSem(H, T : LongInt) : LongInt;
Begin
  WinRequestMutexSem := DcRequestMutexSem(H, T);
End;

Function WinWaitMuxWaitSem(H, T, PU : LongInt) : LongInt;
Begin
  WinWaitMuxWaitSem := DcWaitMuxWaitSem(H, T, PU);
End;

{ semaphore interne de PM }
Function WinSemEnter : LongInt;
Begin
  Inc(SemCount);
  WinSemEnter := 1;
End;

Function WinSemLeave : LongInt;
Begin
  If SemCount > 0 Then Dec(SemCount);
  WinSemLeave := 1;
End;

Function WinSemQuery : LongInt;
Begin
  WinSemQuery := SemCount;
End;

Function FsrSemEnter : LongInt;
Begin
  Inc(FsrCount);
  FsrSemEnter := 0;
End;

Function FsrSemLeave : LongInt;
Begin
  If FsrCount > 0 Then Dec(FsrCount);
  FsrSemLeave := 0;
End;

Function FsrSemExit : LongInt;
Begin
  FsrCount := 0;
  FsrSemExit := 0;
End;

Function FsrSemCheck : LongInt;
Begin
  FsrSemCheck := FsrCount;
End;

{ --- arret du systeme --- }
{ WinSystemShutdown(hab, hmq) : WM_QUIT aux files qui ne l'ont pas
  refuse (WinCancelShutdown) }
Function WinSystemShutdown(Hab, Hmq : LongInt) : LongInt;
Var Q : LongInt;
Begin
  ShuttingDown := 1;
  For Q := 0 To MaxQ - 1 Do
    If (QPid[Q] <> 0) And (QQuit[Q] = 0) Then Dummy := LongInt(QPut(Q, 0, WM_QUIT, 0, 0));
  WinSystemShutdown := 1;
End;

{ WinCancelShutdown(hmq, fCancelAlways) : BOOL }
Function WinCancelShutdown(Hmq, FAlways : LongInt) : LongInt;
Var Q, K, J : LongInt;
Begin
  Q := QIdx(Hmq);
  If Q < 0 Then
  Begin
    WinCancelShutdown := 0;
    Exit;
  End;
  If FAlways <> 0 Then QQuit[Q] := 1 Else QQuit[Q] := 0;
  { retirer le WM_QUIT d'arret deja poste }
  If ShuttingDown <> 0 Then
  Begin
    K := 0;
    While K < QCount[Q] Do
    Begin
      If RdL(QBuf[Q] + ((QHead[Q] + K) Mod QSize[Q]) * 32 + 4) = WM_QUIT Then
      Begin
        For J := K To QCount[Q] - 2 Do
          MemMove(QBuf[Q] + ((QHead[Q] + J + 1) Mod QSize[Q]) * 32, QBuf[Q] + ((QHead[Q] + J) Mod QSize[Q]) * 32, 32);
        Dec(QCount[Q]);
      End
      Else Inc(K);
    End;
  End;
  WinCancelShutdown := 1;
End;

Function WinIsShuttingDown : LongInt;
Begin
  WinIsShuttingDown := ShuttingDown;
End;

Function WinTerminateShutdown : LongInt;
Begin
  ShuttingDown := 0;
  WinTerminateShutdown := 1;
End;

{ --- bibliotheques --- }
Function WinLoadLibrary(Hab, P : LongInt) : LongInt;
Var H : LongInt; Err : Array[0..63] Of Byte;
Begin
  H := 0;
  If (P = 0) Or (DcLoadModule(LongInt(@Err), 64, P, LongInt(@H)) <> 0) Then
  Begin
    SetErr(PMERR_LIBRARY_LOAD_FAILED);
    WinLoadLibrary := 0;
  End
  Else WinLoadLibrary := H;
End;

Function WinDeleteLibrary(Hab, H : LongInt) : LongInt;
Begin
  If DcFreeModule(H) = 0 Then WinDeleteLibrary := 1 Else WinDeleteLibrary := 0;
End;

Function WinLoadProcedure(Hab, H, P : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := 0;
  If DcQueryProcAddr(H, 0, P, LongInt(@A)) <> 0 Then
  Begin
    SetErr(PMERR_PROCEDURE_LOAD_FAILED);
    A := 0;
  End;
  WinLoadProcedure := A;
End;

Function WinDeleteProcedure(Hab, Pfn : LongInt) : LongInt;
Begin
  WinDeleteProcedure := 1;
End;

{ --- aide : HELPMGR.DLL (ordinaux 1 a 6) --- }

Function HelpCall(N, A1, A2, A3 : LongInt) : LongInt;
Var Err : Array[0..63] Of Byte; F : LongInt;
Begin
  HelpCall := 0;
  If HelpMod = 0 Then
  Begin
    PutZ(LongInt(@NameZ2), 'HELPMGR');
    If DcLoadModule(LongInt(@Err), 64, LongInt(@NameZ2), LongInt(@HelpMod)) <> 0 Then HelpMod := 0;
  End;
  If HelpMod = 0 Then Exit;
  If HelpFn[N] = 0 Then
  Begin
    F := 0;
    If DcQueryProcAddr(HelpMod, N, 0, LongInt(@F)) = 0 Then HelpFn[N] := F;
  End;
  If HelpFn[N] <> 0 Then HelpCall := CallSys3(HelpFn[N], A1, A2, A3);
End;

Function WinCreateHelpInstance(Hab, P : LongInt) : LongInt;
Begin
  WinCreateHelpInstance := HelpCall(1, Hab, P, 0);
End;

Function WinDestroyHelpInstance(H : LongInt) : LongInt;
Begin
  WinDestroyHelpInstance := HelpCall(2, H, 0, 0);
End;

Function WinQueryHelpInstance(H : LongInt) : LongInt;
Begin
  WinQueryHelpInstance := HelpCall(3, H, 0, 0);
End;

Function WinAssociateHelpInstance(HHelp, HApp : LongInt) : LongInt;
Begin
  WinAssociateHelpInstance := HelpCall(4, HHelp, HApp, 0);
End;

Function WinLoadHelpTable(HHelp, Id, Hmod : LongInt) : LongInt;
Begin
  WinLoadHelpTable := HelpCall(5, HHelp, Id, Hmod);
End;

Function WinCreateHelpTable(HHelp, P : LongInt) : LongInt;
Begin
  WinCreateHelpTable := HelpCall(6, HHelp, P, 0);
End;

Function DummyHelpEntry : LongInt;
Begin
  DummyHelpEntry := 0;
End;

{ --- DDE : DDEINIT (cb, pszAppName, pszTopic, offConvContext) --- }
Function WinDdeInitiate(HClient, PApp, PTopic, PCtx : LongInt) : LongInt;
Var J, D : LongInt;
Begin
  WinDdeInitiate := 0;
  If WIdx(HClient) < 2 Then Exit;
  D := MemAlloc(16 + 260 + 260);
  If D = 0 Then Exit;
  WrL(D, 16); WrL(D + 4, D + 16); WrL(D + 8, D + 16 + 260); WrL(D + 12, 0);
  PutZ(D + 16, Copy(GetZ(PApp), 1, 255)); PutZ(D + 16 + 260, Copy(GetZ(PTopic), 1, 255));
  For J := 2 To MaxWin - 1 Do
    If (WUse[J] <> 0) And (WPar[J] = 0) And (HwOf(J) <> HClient) And (KindOf(J) <> CK_MENU) Then
      Dummy := SendM(HwOf(J), WM_DDE_INITIATE, HClient, D);
  MemFree(D);
  WinDdeInitiate := 1;
End;

Function WinDdeRespond(HClient, HServer, PApp, PTopic, PCtx : LongInt) : LongInt;
Var D : LongInt;
Begin
  WinDdeRespond := 0;
  D := MemAlloc(16 + 260 + 260);
  If D = 0 Then Exit;
  WrL(D, 16); WrL(D + 4, D + 16); WrL(D + 8, D + 16 + 260); WrL(D + 12, 0);
  PutZ(D + 16, Copy(GetZ(PApp), 1, 255)); PutZ(D + 16 + 260, Copy(GetZ(PTopic), 1, 255));
  WinDdeRespond := SendM(HClient, WM_DDE_INITIATEACK, HServer, D);
  MemFree(D);
End;

{ WinDdePostMsg(hwndTo, hwndFrom, wm, pddest, flOptions) : DDEPM_RETRY 1 }
Function WinDdePostMsg(HTo, HFrom, Msg, P, Fl : LongInt) : LongInt;
Var N : LongInt; Ok : Boolean;
Begin
  N := 0;
  Repeat
    Ok := PostM(HTo, Msg, HFrom, P);
    If Not Ok And ((Fl And 1) <> 0) Then Dummy := DcSleep(10);
    Inc(N);
  Until Ok Or ((Fl And 1) = 0) Or (N > 100);
  If Ok Then WinDdePostMsg := 1 Else WinDdePostMsg := 0;
End;

{ --- fonctions internes ou de diagnostic --- }
Function AabAllocReg : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 31 DownTo 1 Do
    If AabReg[K] = 0 Then R := K;
  If R > 0 Then AabReg[R] := 1;
  AabAllocReg := R;
End;

Function AabGetReg(N : LongInt) : LongInt;
Begin
  If (N >= 0) And (N <= 31) Then AabGetReg := AabReg[N] Else AabGetReg := 0;
End;

Function AabSetReg(N, V : LongInt) : LongInt;
Begin
  If (N >= 0) And (N <= 31) Then
  Begin
    AabReg[N] := V;
    AabSetReg := 1;
  End
  Else AabSetReg := 0;
End;

Function AAB32GETREG(N : LongInt) : LongInt;
Begin
  AAB32GETREG := AabGetReg(N);
End;

Function AAB32SETREG(N, V : LongInt) : LongInt;
Begin
  AAB32SETREG := AabSetReg(N, V);
End;

Function ValidateSelector(Sel : LongInt) : LongInt;
Begin
  If Sel <> 0 Then ValidateSelector := 1 Else ValidateSelector := 0;
End;

{ LoadModuleHandle(pszName) : handle d'un module charge }
Function LoadModuleHandle(P : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := 0;
  If (P = 0) Or (DcQueryModuleHandle(P, LongInt(@H)) <> 0) Then H := 0;
  LoadModuleHandle := H;
End;

{ adresse de la memoire de l'ecran texte }
Function GetScreenSelector : LongInt;
Begin
  GetScreenSelector := $B8000;
End;

Function IdentifyCodeSelector(Sel : LongInt) : LongInt;
Begin
  IdentifyCodeSelector := 0;
End;

Function GetPMDDCodeSelector : LongInt;
Begin
  GetPMDDCodeSelector := 0;
End;


Function DebugInputEnable(F : LongInt) : LongInt;
Begin
  DebugEnabled := F;
  DebugInputEnable := 1;
End;

{ DebugInput : caractere du clavier (0 si aucun) }
Function DebugInput : LongInt;
Var Ki : Array[0..15] Of Byte;
Begin
  MemZero(LongInt(@Ki), 16);
  If (KbdCharIn(LongInt(@Ki), 1, 0) = 0) And ((Ki[2] And $40) <> 0) Then DebugInput := Ki[0]
  Else DebugInput := 0;
End;

{ DebugOutput(psz) : sur la sortie standard }
Function DebugOutput(P : LongInt) : LongInt;
Var N, W : LongInt;
Begin
  N := 0;
  If P <> 0 Then
    While RdB(P + N) <> 0 Do Inc(N);
  W := 0;
  If N > 0 Then Dummy := DcWrite(1, P, N, LongInt(@W));
  DebugOutput := W;
End;

Function DebugCurPos(Row, Col : LongInt) : LongInt;
Begin
  DebugCurPos := VioSetCurPos(Row, Col, 0);
End;

Function DebugCls : LongInt;
Var C, R : LongInt;
Begin
  If GMode <> 0 Then
  Begin
    GClipAll;
    GFill(0, 0, ScrCX, ScrCY, 0);
    DebugCls := 0;
    Exit;
  End;
  For R := 0 To ScrRows - 1 Do
    For C := 0 To ScrCols - 1 Do PutCell(C, R, 32, 7);
  Dummy := VioSetCurPos(0, 0, 0);
  DebugCls := 0;
End;

Function DebugRedirect(F : LongInt) : LongInt;
Begin
  DebugRedirect := 1;
End;

Function WinDebugBreak : LongInt;
Begin
  WinDebugBreak := 0;
End;

Function DEBUG32INPUT : LongInt;
Begin
  DEBUG32INPUT := DebugInput;
End;

Function DEBUG32OUTPUT(P : LongInt) : LongInt;
Begin
  DEBUG32OUTPUT := DebugOutput(P);
End;

Function DEBUG32CURPOS(Row, Col : LongInt) : LongInt;
Begin
  DEBUG32CURPOS := DebugCurPos(Row, Col);
End;

Function DEBUG32CLS : LongInt;
Begin
  DEBUG32CLS := DebugCls;
End;

Function WIN32DEBUGBREAK : LongInt;
Begin
  WIN32DEBUGBREAK := 0;
End;

{ sessions "seamless" (Win-OS/2) : non disponibles }
Function WinSeamlessBox(H, P : LongInt) : LongInt;
Begin
  WinSeamlessBox := 0;
End;

Function WinTrackSeamless(H, P : LongInt) : LongInt;
Begin
  WinTrackSeamless := 0;
End;

Function WinRegisterSeamlessProc(Pfn : LongInt) : LongInt;
Begin
  WinRegisterSeamlessProc := 0;
End;

{ AbnormalProcessExit(pid) : liberer les fenetres et les files du processus }
Function AbnormalProcessExit(Pid : LongInt) : LongInt;
Var I : LongInt;
Begin
  For I := 2 To MaxWin - 1 Do
    If (WUse[I] <> 0) And (WPid[I] = Pid) And (WPar[I] <= 1) Then DestroyIdx(I);
  For I := 0 To MaxQ - 1 Do
    If QPid[I] = Pid Then
    Begin
      MemFree(QBuf[I]);
      QPid[I] := 0;
    End;
  For I := 0 To MaxHab - 1 Do
    If HabPid[I] = Pid Then HabPid[I] := 0;
  For I := 0 To MaxTimer - 1 Do
    If TmUse[I] = Pid Then TmUse[I] := 0;
  For I := 0 To MaxHook - 1 Do
    If HkUse[I] = Pid Then HkUse[I] := 0;
  AbnormalProcessExit := 1;
End;

Function WinProfControl(Fl, P : LongInt) : LongInt;
Begin
  WinProfControl := 0;
End;

Function InputGetDeviceInfo(N, P : LongInt) : LongInt;
Begin
  If P <> 0 Then
  Begin
    WrL(P, 2);                { clavier et souris }
    WrL(P + 4, 3);            { boutons de la souris }
  End;
  InputGetDeviceInfo := 1;
End;

Function WinPortHoleUtil(H, P : LongInt) : LongInt;
Begin
  WinPortHoleUtil := 0;
End;

Function WinGetMinWindowViewer(HDesk : LongInt) : LongInt;
Begin
  WinGetMinWindowViewer := 0;
End;

{ WinQueryState(hab) : bit 0 file de messages, bit 1 mode menu, bit 2
  capture, bit 3 fenetre modale du systeme }
Function WinQueryState(Hab : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If CurQ >= 0 Then R := R Or 1;
  If (CaptureWin > 1) And (KindOf(CaptureWin) = CK_MENU) Then R := R Or 2;
  If CaptureWin > 1 Then R := R Or 4;
  If SysModalWin > 1 Then R := R Or 8;
  WinQueryState := R;
End;

Function WinSyncStartPgm(P : LongInt) : LongInt;
Begin
  WinSyncStartPgm := 0;
End;

Function WinScreenSwitch(H, Fl : LongInt) : LongInt;
Begin
  WinScreenSwitch := 1;
End;

Function WinResetSystem(HDesk : LongInt) : LongInt;
Begin
  WinResetSystem := 1;
End;

Function WinQueryHungProcess(Hab : LongInt) : LongInt;
Begin
  WinQueryHungProcess := 0;
End;

{ --- ancres --- }
Function WinInitialize(Fl : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  EnsureInit;
  CleanupDead;
  I := CurHab;
  If I >= 0 Then
  Begin
    WinInitialize := $00010001 + I;
    Exit;
  End;
  F := -1;
  For I := MaxHab - 1 DownTo 0 Do
    If HabPid[I] = 0 Then F := I;
  If F < 0 Then
  Begin
    WinInitialize := 0;
    Exit;
  End;
  HabPid[F] := MyPid; HabErr[F] := 0; HabQ[F] := -1; HabMou[F] := 0;
  WinInitialize := $00010001 + F;
End;

{ WinTerminate(hab) : fenetres, file, minuteries, crochets du processus }
Function WinTerminate(Hab : LongInt) : LongInt;
Var I, Pid, Q, C, R : LongInt; Others : Boolean;
Begin
  I := HabIdx(Hab);
  If (I < 0) Or (HabPid[I] <> MyPid) Then
  Begin
    WinTerminate := 0;
    Exit;
  End;
  Pid := MyPid;
  Q := CurQ;
  If Q >= 0 Then Dummy := WinDestroyMsgQueue($00510001 + Q);
  For C := 2 To MaxWin - 1 Do
    If (WUse[C] <> 0) And (WPid[C] = Pid) And (WPar[C] <= 1) Then DestroyIdx(C);
  For C := 0 To MaxTimer - 1 Do
    If TmUse[C] = Pid Then TmUse[C] := 0;
  For C := 0 To MaxHook - 1 Do
    If HkUse[C] = Pid Then HkUse[C] := 0;
  For C := 0 To MaxCls - 1 Do
    If CPid[C] = Pid Then CUse[C] := 0;
  If ClOpen = Pid Then ClOpen := 0;
  HabPid[I] := 0;
  { dernier programme de PM : ecran rendu au mode texte }
  Others := False;
  For C := 0 To MaxQ - 1 Do
    If (QPid[C] <> 0) And Alive(QPid[C]) And Not ((Susp <> 0) And (QPid[C] = SuspPid)) Then Others := True;
  If Not Others Then
  Begin
    If GMode <> 0 Then GLeave
    Else
      For R := 0 To ScrRows - 1 Do
        For C := 0 To ScrCols - 1 Do PutCell(C, R, 32, 7);
    CursorWin := 0; CurShown := 0; CurFs := 0;
    WrW(LongInt(@NameZ2), 14); WrW(LongInt(@NameZ2) + 2, 15); WrW(LongInt(@NameZ2) + 4, 1); WrW(LongInt(@NameZ2) + 6, 0);
    Dummy := VioSetCurType(LongInt(@NameZ2), 0);
    Dummy := VioSetCurPos(0, 0, 0);
    FocusWin := 0; ActiveWin := 0; CaptureWin := 0; SysModalWin := 0;
  End;
  WinTerminate := 1;
End;

Function WinInitializeSystem : LongInt;
Begin
  WinInitializeSystem := 1;
End;

Function WinTerminateSystem : LongInt;
Begin
  WinTerminateSystem := 1;
End;

{ WinQueryVersion(hab) : 20.40 }
Function WinQueryVersion(Hab : LongInt) : LongInt;
Begin
  WinQueryVersion := $2814;
End;

{ WinCatch(pcatchbuf) : 0 ; WinThrow(pcatchbuf, value) ne peut derouler
  la pile : FALSE }
Function WinCatch(P : LongInt) : LongInt;
Begin
  If P <> 0 Then WrL(P, $43415443);
  WinCatch := 0;
End;

Function WinThrow(P, V : LongInt) : LongInt;
Begin
  WinThrow := 0;
End;


{ WINQUERYPSINFO (ordinal 1001, interne : PMGPI.DLL) : (hps ou hwnd, p)
  -> p[0] HWND, p[1], p[2] origine, p[3] a p[6] rectangle visible (pels
  de l'ecran 640 x 400) ; BOOL }
Function WinQueryPSInfo(H, P : LongInt) : LongInt;
Var K, I, X1, Y1, X2, Y2 : LongInt;
Begin
  WinQueryPSInfo := 0;
  If P = 0 Then Exit;
  I := -1;
  If (H And $FFFF0000) = $50530000 Then
  Begin
    K := H - $50530001;
    If (K < 0) Or (K >= MaxPS) Then Exit;
    If PsUse[K] = 0 Then Exit;
    I := PsWin[K];
    WrL(P, HwOf(I)); WrL(P + 4, PsOrgX[K]); WrL(P + 8, PsOrgY[K]);
    WrL(P + 12, PsX1[K]); WrL(P + 16, PsY1[K]); WrL(P + 20, PsX2[K]); WrL(P + 24, PsY2[K]);
  End
  Else
  Begin
    I := WIdx(H);
    If I < 0 Then Exit;
    If Not VisRect(I, X1, Y1, X2, Y2) Then
    Begin
      X2 := X1; Y2 := Y1;
    End;
    WrL(P, HwOf(I)); WrL(P + 4, AbsX(I)); WrL(P + 8, AbsY(I));
    WrL(P + 12, X1); WrL(P + 16, Y1); WrL(P + 20, X2); WrL(P + 24, Y2);
  End;
  WinQueryPSInfo := 1;
End;

{ ==================================================================== }
{ Initialisation                                                        }
{ ==================================================================== }

Procedure SysValDefaults;
Var K : LongInt;
Begin
  For K := 0 To 59 Do SysVal[K] := SvDef[K];
  SysVal[64] := 0; SysVal[65] := 0; SysVal[66] := 1; SysVal[70] := 200;
  SysVal[108] := 108;
End;

{ --- ecran graphique de PM --- }
{ valeurs et couleurs du systeme du mode }
Procedure GSysVals;
Var K : LongInt;
Begin
  For K := 4 To 5 Do SysVal[K] := SvDef[K];
  For K := 20 To 41 Do SysVal[K] := SvDef[K];
  For K := 10 To 50 Do SysClr[K] := ClrDef[K];
  If GMode <> 0 Then
  Begin
    SysVal[4] := 4; SysVal[5] := 4; SysVal[20] := 640; SysVal[21] := 480; SysVal[22] := 16; SysVal[23] := 16;
    SysVal[24] := 16; SysVal[25] := 16; SysVal[26] := 1; SysVal[27] := 1; SysVal[28] := 3; SysVal[29] := 3;
    SysVal[30] := 20; SysVal[31] := 16; SysVal[32] := 16; SysVal[33] := 20; SysVal[34] := 20; SysVal[35] := 20;
    SysVal[36] := 640; SysVal[37] := 460; SysVal[40] := 16; SysVal[41] := 16;
    { cadres gris, boutons gris, champs blancs, selection bleue }
    SysClr[14] := $AAAAAA; SysClr[15] := $AAAAAA; SysClr[25] := $AAAAAA; SysClr[39] := $555555;
    SysClr[40] := $AAAAAA; SysClr[41] := $FFFFFF; SysClr[44] := $0000AA; SysClr[45] := $FFFFFF;
    SysClr[47] := $FFFFFF; SysClr[42] := $FFFFFF;
  End;
  WCX[0] := ScrCX; WCY[0] := ScrCY;
End;

{ PMMODE=TEXTE dans l'environnement : PM reste en mode texte }
Function GWanted : Boolean;
Var P : LongInt; S : String;
Begin
  P := 0; S := '';
  PutZ(LongInt(@NameZ2), 'PMMODE');
  If DcScanEnv(LongInt(@NameZ2), LongInt(@P)) = 0 Then
    If P <> 0 Then S := UpStr(GetZ(P));
  GWanted := Not ((S <> '') And (S[1] = 'T'));
End;

{ passer l'ecran en 640 x 480 x 16 couleurs (VioSetMode) }
Procedure GEnter;
Var K, P, H : LongInt;
Begin
  { police 8 x 16 du VGA (lue en mode texte : VioGetFont n'est pas
    disponible en mode graphique) }
  If GMode = 0 Then
  Begin
    MemZero(LongInt(@NameZ2), 16);
    WrW(LongInt(@NameZ2), 14); WrW(LongInt(@NameZ2) + 2, 1);
    If VioGetFont(LongInt(@NameZ2), 0) = 0 Then
    Begin
      P := RdL(LongInt(@NameZ2) + 8); H := RdW(LongInt(@NameZ2) + 6);
      For K := 0 To 4095 Do
        If (P <> 0) And ((K Mod 16) < H) Then GFont[K] := RdB(P + (K Div 16) * H + K Mod 16) Else GFont[K] := 0;
    End;
  End;
  MemZero(LongInt(@NameZ2), 40);
  WrW(LongInt(@NameZ2), 12); NameZ2[2] := 3; NameZ2[3] := 4;
  WrW(LongInt(@NameZ2) + 4, 80); WrW(LongInt(@NameZ2) + 6, 30);
  WrW(LongInt(@NameZ2) + 8, 640); WrW(LongInt(@NameZ2) + 10, 480);
  If VioSetMode(LongInt(@NameZ2), 0) <> 0 Then Exit;
  GMode := 1;
  GPtrOn := 0; GCarOn := 0; GCarWant := 0;
  For K := 0 To 2399 Do GShadow[K] := 32;
  GMetrics;
  GSysVals;
End;

{ revenir au mode texte 80 x 25 }
Procedure GLeave;
Begin
  If GMode = 0 Then Exit;
  GPtrOn := 0; GCarOn := 0; GCarWant := 0;
  MemZero(LongInt(@NameZ2), 40);
  WrW(LongInt(@NameZ2), 8); NameZ2[2] := 1; NameZ2[3] := 4;
  WrW(LongInt(@NameZ2) + 4, 80); WrW(LongInt(@NameZ2) + 6, 25);
  Dummy := VioSetMode(LongInt(@NameZ2), 0);
  GMode := 0;
  GMetrics;
  GSysVals;
End;

{ WINQUERYSCREENTEXT (ordinal 1002, interne : programmes d'essai) :
  (ligne, colonne, nombre, tampon) -> caracteres ecrits a l'ecran (mode
  texte : cellules ; mode graphique : caracteres dessines aux positions
  des cellules de 8 x 16 pels) ; rend 1 si l'ecran est graphique }
Function WinQueryScreenText(Row, Col, N, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  For K := 0 To N - 1 Do
    If (Row >= 0) And (Row < ScrRows) And (Col + K >= 0) And (Col + K < ScrCols) Then
    Begin
      If GMode <> 0 Then WrB(P + K, GShadow[Row * 80 + Col + K])
      Else WrB(P + K, RdB($B8000 + (Row * ScrCols + Col + K) * 2));
    End
    Else WrB(P + K, 32);
  WinQueryScreenText := GMode;
End;

{ WINHIDEOVERLAYS (ordinal 1003, interne : PMGPI.DLL) : retirer le
  pointeur et le curseur avant un dessin direct a l'ecran }
Function WinHideOverlays : LongInt;
Begin
  If GMode <> 0 Then GHideAll;
  WinHideOverlays := GMode;
End;

Procedure RegSys(N : String; Kind, Cb : LongInt);
Begin
  Dummy := ClsAdd(N, SysProc, 0, Cb, 0, Kind);
End;

Procedure EnsureInit;
Var A : LongInt;
Begin
  If InitDone <> 0 Then Exit;
  If MyMod = 0 Then
  Begin
    PutZ(LongInt(@NameZ2), 'PMWIN');
    If DcQueryModuleHandle(LongInt(@NameZ2), LongInt(@MyMod)) <> 0 Then MyMod := 0;
  End;
  If MyMod = 0 Then Exit;
  A := 0;
  If DcQueryProcAddr(MyMod, 1000, 0, LongInt(@A)) = 0 Then SysProc := A;
  PutZ(LongInt(@NameZ2), 'WinDefWindowProc');
  A := 0;
  If DcQueryProcAddr(MyMod, 0, LongInt(@NameZ2), LongInt(@A)) = 0 Then DefProcAddr := A;
  PutZ(LongInt(@NameZ2), 'WinDefDlgProc');
  A := 0;
  If DcQueryProcAddr(MyMod, 0, LongInt(@NameZ2), LongInt(@A)) = 0 Then DefDlgAddr := A;
  If (SysProc = 0) Or (DefProcAddr = 0) Or (DefDlgAddr = 0) Then Exit;
  RegSys('#1', CK_FRAME, 32);
  RegSys('#2', CK_COMBOBOX, 8);
  RegSys('#3', CK_BUTTON, 8);
  RegSys('#4', CK_MENU, 8);
  RegSys('#5', CK_STATIC, 8);
  RegSys('#6', CK_ENTRYFIELD, 8);
  RegSys('#7', CK_LISTBOX, 8);
  RegSys('#8', CK_SCROLLBAR, 8);
  RegSys('#9', CK_TITLEBAR, 8);
  RegSys('#10', CK_MLE, 8);
  RegSys('#16', CK_GENERIC, 8);
  RegSys('#17', CK_GENERIC, 8);
  RegSys('#18', CK_GENERIC, 8);
  RegSys('#19', CK_GENERIC, 8);
  RegSys('#32', CK_GENERIC, 8);
  RegSys('#37', CK_GENERIC, 8);
  RegSys('#38', CK_GENERIC, 8);
  RegSys('#39', CK_GENERIC, 8);
  RegSys('#40', CK_GENERIC, 8);
  { bureau et fenetre objet }
  WCls[0] := ClsAdd('#32766', DefProcAddr, 0, 0, 0, CK_DESKTOP);
  WCls[1] := ClsAdd('#32767', DefProcAddr, 0, 0, 0, CK_OBJECT);
  WProc[0] := DefProcAddr; WProc[1] := DefProcAddr;
  InitDone := 1;
End;

{ Premiere file de messages : ecran de PM }
Procedure ScreenStart;
Begin
  If GWanted Then GEnter Else GLeave;
  CursorWin := 0;
  ShowHwCursor;
  InvalScreen(0, 0, ScrCX, ScrCY);
End;

{ WINSUSPENDSCREEN (ordinal 1004, interne : PMSHELL.EXE) : l'ecran est
  prete a un programme lance (DosExecPgm) : mode texte 80 x 25 ; un
  programme de PM lance pendant ce temps reprend l'ecran graphique a sa
  premiere file de messages et le rend au mode texte a sa fin ; BOOL }
Function WinSuspendScreen : LongInt;
Var R, C : LongInt;
Begin
  Susp := 1; SuspPid := MyPid; SuspTook := 0;
  If GMode <> 0 Then GLeave
  Else
    For R := 0 To ScrRows - 1 Do
      For C := 0 To ScrCols - 1 Do PutCell(C, R, 32, 7);
  CaptureWin := 0;
  WrW(LongInt(@NameZ2), 14); WrW(LongInt(@NameZ2) + 2, 14); WrW(LongInt(@NameZ2) + 4, 15); WrW(LongInt(@NameZ2) + 6, 0);
  Dummy := VioSetCurType(LongInt(@NameZ2), 0);
  Dummy := VioSetCurPos(0, 0, 0);
  WinSuspendScreen := 1;
End;

{ WINRESUMESCREEN (ordinal 1005, interne : PMSHELL.EXE) : l'ecran revient
  a PM (mode graphique, tout est redessine) ; les evenements de la souris
  recus pendant le programme sont oublies ; BOOL }
Function WinResumeScreen : LongInt;
Var Q, N, Wait : LongInt; Ev : Array[0..11] Of Byte;
Begin
  Susp := 0; SuspPid := 0;
  CleanupDead;
  ScreenStart;
  Q := CurQ;
  If (Q >= 0) And (QMou[Q] <> 0) Then
  Begin
    N := 0;
    Repeat
      Wait := 0;
      MemZero(LongInt(@Ev), 12);
      If MouReadEventQue(LongInt(@Ev), LongInt(@Wait), QMou[Q]) <> 0 Then N := 999;
      If (RdW(LongInt(@Ev)) = 0) And (RdL(LongInt(@Ev) + 2) = 0) Then N := 999;
      Inc(N);
    Until N >= 64;
  End;
  MouseBtn := 0;
  CaptureWin := 0;
  WinResumeScreen := 1;
End;

{ WINQUERYSCREENTAKEN (ordinal 1006, interne : PMSHELL.EXE) : 1 si un
  programme de PM a pris l'ecran depuis WINSUSPENDSCREEN }
Function WinQueryScreenTaken : LongInt;
Begin
  WinQueryScreenTaken := SuspTook;
End;

{ ==================================================================== }
{ Partie 7 - Points d'entree 16 bits, exportations, initialisation    }
{ ==================================================================== }

{ ordinaux bas (interface 16 bits) : memes fonctions }
Function W16_WinQueryDesktopWindow(Hab, Hdc : LongInt) : LongInt;
Begin
  W16_WinQueryDesktopWindow := WinQueryDesktopWindow(Hab, Hdc);
End;

Function W16_WinQueryObjectWindow(HDesk : LongInt) : LongInt;
Begin
  W16_WinQueryObjectWindow := WinQueryObjectWindow(HDesk);
End;

Function W16_WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt;
Begin
  W16_WinRegisterClass := WinRegisterClass(Hab, PName, Proc, Style, Cb);
End;

Function W16_WinQueryClassName(H, Cch, P : LongInt) : LongInt;
Begin
  W16_WinQueryClassName := WinQueryClassName(H, Cch, P);
End;

Function W16_WinQueryClassInfo(Hab, PName, PInfo : LongInt) : LongInt;
Begin
  W16_WinQueryClassInfo := WinQueryClassInfo(Hab, PName, PInfo);
End;

Function W16_WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt;
Begin
  W16_WinCreateWindow := WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres);
End;

Function W16_WinDestroyWindow(H : LongInt) : LongInt;
Begin
  W16_WinDestroyWindow := WinDestroyWindow(H);
End;

Function W16_WinSetWindowPos(H, HBehind, X, Y, Cx, Cy, Fl : LongInt) : LongInt;
Begin
  W16_WinSetWindowPos := WinSetWindowPos(H, HBehind, X, Y, Cx, Cy, Fl);
End;

Function W16_WinSetMultWindowPos(Hab, P, N : LongInt) : LongInt;
Begin
  W16_WinSetMultWindowPos := WinSetMultWindowPos(Hab, P, N);
End;

Function W16_WinQueryWindowPos(H, P : LongInt) : LongInt;
Begin
  W16_WinQueryWindowPos := WinQueryWindowPos(H, P);
End;

Function W16_WinEnableWindow(H, En : LongInt) : LongInt;
Begin
  W16_WinEnableWindow := WinEnableWindow(H, En);
End;

Function W16_WinIsWindowEnabled(H : LongInt) : LongInt;
Begin
  W16_WinIsWindowEnabled := WinIsWindowEnabled(H);
End;

Function W16_WinShowWindow(H, Show : LongInt) : LongInt;
Begin
  W16_WinShowWindow := WinShowWindow(H, Show);
End;

Function W16_WinEnableWindowUpdate(H, En : LongInt) : LongInt;
Begin
  W16_WinEnableWindowUpdate := WinEnableWindowUpdate(H, En);
End;

Function W16_WinIsWindowVisible(H : LongInt) : LongInt;
Begin
  W16_WinIsWindowVisible := WinIsWindowVisible(H);
End;

Function W16_WinSetWindowText(H, P : LongInt) : LongInt;
Begin
  W16_WinSetWindowText := WinSetWindowText(H, P);
End;

Function W16_WinQueryWindowText(H, Cch, P : LongInt) : LongInt;
Begin
  W16_WinQueryWindowText := WinQueryWindowText(H, Cch, P);
End;

Function W16_WinQueryWindowTextLength(H : LongInt) : LongInt;
Begin
  W16_WinQueryWindowTextLength := WinQueryWindowTextLength(H);
End;

Function W16_WinWindowFromID(HPar, Id : LongInt) : LongInt;
Begin
  W16_WinWindowFromID := WinWindowFromID(HPar, Id);
End;

Function W16_WinMultWindowFromIDs(HPar, P, IdF, IdL : LongInt) : LongInt;
Begin
  W16_WinMultWindowFromIDs := WinMultWindowFromIDs(HPar, P, IdF, IdL);
End;

Function W16_WinIsWindow(Hab, H : LongInt) : LongInt;
Begin
  W16_WinIsWindow := WinIsWindow(Hab, H);
End;

Function W16_WinIsChild(H, HPar : LongInt) : LongInt;
Begin
  W16_WinIsChild := WinIsChild(H, HPar);
End;

Function W16_WinSetParent(H, HPar, Redraw : LongInt) : LongInt;
Begin
  W16_WinSetParent := WinSetParent(H, HPar, Redraw);
End;

Function W16_WinSetOwner(H, HOwn : LongInt) : LongInt;
Begin
  W16_WinSetOwner := WinSetOwner(H, HOwn);
End;

Function W16_WinQueryWindow(H, Cmd : LongInt) : LongInt;
Begin
  W16_WinQueryWindow := WinQueryWindow(H, Cmd);
End;

Function W16_WinQueryWindowRect(H, P : LongInt) : LongInt;
Begin
  W16_WinQueryWindowRect := WinQueryWindowRect(H, P);
End;

Function W16_WinQueryWindowProcess(H, PPid, PTid : LongInt) : LongInt;
Begin
  W16_WinQueryWindowProcess := WinQueryWindowProcess(H, PPid, PTid);
End;

Function W16_WinSetWindowUShort(H, Index, V : LongInt) : LongInt;
Begin
  W16_WinSetWindowUShort := WinSetWindowUShort(H, Index, V);
End;

Function W16_WinQueryWindowUShort(H, Index : LongInt) : LongInt;
Begin
  W16_WinQueryWindowUShort := WinQueryWindowUShort(H, Index);
End;

Function W16_WinSetWindowULong(H, Index, V : LongInt) : LongInt;
Begin
  W16_WinSetWindowULong := WinSetWindowULong(H, Index, V);
End;

Function W16_WinQueryWindowULong(H, Index : LongInt) : LongInt;
Begin
  W16_WinQueryWindowULong := WinQueryWindowULong(H, Index);
End;

Function W16_WinBeginEnumWindows(H : LongInt) : LongInt;
Begin
  W16_WinBeginEnumWindows := WinBeginEnumWindows(H);
End;

Function W16_WinGetNextWindow(He : LongInt) : LongInt;
Begin
  W16_WinGetNextWindow := WinGetNextWindow(He);
End;

Function W16_WinEndEnumWindows(He : LongInt) : LongInt;
Begin
  W16_WinEndEnumWindows := WinEndEnumWindows(He);
End;

Function W16_WinWindowFromPoint(HPar, PPtl, Children : LongInt) : LongInt;
Begin
  W16_WinWindowFromPoint := WinWindowFromPoint(HPar, PPtl, Children);
End;

Function W16_WinMapWindowPoints(HFrom, HTo, P, N : LongInt) : LongInt;
Begin
  W16_WinMapWindowPoints := WinMapWindowPoints(HFrom, HTo, P, N);
End;

Function W16_WinSubclassWindow(H, Proc : LongInt) : LongInt;
Begin
  W16_WinSubclassWindow := WinSubclassWindow(H, Proc);
End;

Function W16_WinOpenWindowDC(H : LongInt) : LongInt;
Begin
  W16_WinOpenWindowDC := WinOpenWindowDC(H);
End;

Function W16_WinGetScreenPS(HDesk : LongInt) : LongInt;
Begin
  W16_WinGetScreenPS := WinGetScreenPS(HDesk);
End;

Function W16_WinGetPS(H : LongInt) : LongInt;
Begin
  W16_WinGetPS := WinGetPS(H);
End;

Function W16_WinReleasePS(Hps : LongInt) : LongInt;
Begin
  W16_WinReleasePS := WinReleasePS(Hps);
End;

Function W16_WinBeginPaint(H, Hps, PRcl : LongInt) : LongInt;
Begin
  W16_WinBeginPaint := WinBeginPaint(H, Hps, PRcl);
End;

Function W16_WinEndPaint(Hps : LongInt) : LongInt;
Begin
  W16_WinEndPaint := WinEndPaint(Hps);
End;

Function W16_WinInvalidateRect(H, PRcl, Incl : LongInt) : LongInt;
Begin
  W16_WinInvalidateRect := WinInvalidateRect(H, PRcl, Incl);
End;

Function W16_WinInvalidateRegion(H, Hrgn, Incl : LongInt) : LongInt;
Begin
  W16_WinInvalidateRegion := WinInvalidateRegion(H, Hrgn, Incl);
End;

Function W16_WinValidateRect(H, PRcl, Incl : LongInt) : LongInt;
Begin
  W16_WinValidateRect := WinValidateRect(H, PRcl, Incl);
End;

Function W16_WinValidateRegion(H, Hrgn, Incl : LongInt) : LongInt;
Begin
  W16_WinValidateRegion := WinValidateRegion(H, Hrgn, Incl);
End;

Function W16_WinQueryUpdateRect(H, PRcl : LongInt) : LongInt;
Begin
  W16_WinQueryUpdateRect := WinQueryUpdateRect(H, PRcl);
End;

Function W16_WinQueryUpdateRegion(H, Hrgn : LongInt) : LongInt;
Begin
  W16_WinQueryUpdateRegion := WinQueryUpdateRegion(H, Hrgn);
End;

Function W16_WinUpdateWindow(H : LongInt) : LongInt;
Begin
  W16_WinUpdateWindow := WinUpdateWindow(H);
End;

Function W16_WinExcludeUpdateRegion(Hps, H : LongInt) : LongInt;
Begin
  W16_WinExcludeUpdateRegion := WinExcludeUpdateRegion(Hps, H);
End;

Function W16_WinLockWindowUpdate(HDesk, HLock : LongInt) : LongInt;
Begin
  W16_WinLockWindowUpdate := WinLockWindowUpdate(HDesk, HLock);
End;

Function W16_WinLockVisRegions(HDesk, Lock : LongInt) : LongInt;
Begin
  W16_WinLockVisRegions := WinLockVisRegions(HDesk, Lock);
End;

Function W16_WinWindowFromDC(Hdc : LongInt) : LongInt;
Begin
  W16_WinWindowFromDC := WinWindowFromDC(Hdc);
End;

Function W16_WinCreateMsgQueue(Hab, N : LongInt) : LongInt;
Begin
  W16_WinCreateMsgQueue := WinCreateMsgQueue(Hab, N);
End;

Function W16_WinDestroyMsgQueue(H : LongInt) : LongInt;
Begin
  W16_WinDestroyMsgQueue := WinDestroyMsgQueue(H);
End;

Function W16_WinQueryQueueStatus(HDesk : LongInt) : LongInt;
Begin
  W16_WinQueryQueueStatus := WinQueryQueueStatus(HDesk);
End;

Function W16_WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  W16_WinSendMsg := WinSendMsg(H, Msg, Mp1, Mp2);
End;

Function W16_WinBroadcastMsg(HPar, Msg, Mp1, Mp2, Rgf : LongInt) : LongInt;
Begin
  W16_WinBroadcastMsg := WinBroadcastMsg(HPar, Msg, Mp1, Mp2, Rgf);
End;

Function W16_WinInSendMsg(Hab : LongInt) : LongInt;
Begin
  W16_WinInSendMsg := WinInSendMsg(Hab);
End;

Function W16_WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt;
Begin
  W16_WinGetMsg := WinGetMsg(Hab, P, HF, First, Last);
End;

Function W16_WinPeekMsg(Hab, P, HF, First, Last, Fl : LongInt) : LongInt;
Begin
  W16_WinPeekMsg := WinPeekMsg(Hab, P, HF, First, Last, Fl);
End;

Function W16_WinWaitMsg(Hab, First, Last : LongInt) : LongInt;
Begin
  W16_WinWaitMsg := WinWaitMsg(Hab, First, Last);
End;

Function W16_WinDispatchMsg(Hab, P : LongInt) : LongInt;
Begin
  W16_WinDispatchMsg := WinDispatchMsg(Hab, P);
End;

Function W16_WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  W16_WinPostMsg := WinPostMsg(H, Msg, Mp1, Mp2);
End;

Function W16_WinPostQueueMsg(Hmq, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  W16_WinPostQueueMsg := WinPostQueueMsg(Hmq, Msg, Mp1, Mp2);
End;

Function W16_WinQueryMsgPos(Hab, P : LongInt) : LongInt;
Begin
  W16_WinQueryMsgPos := WinQueryMsgPos(Hab, P);
End;

Function W16_WinQueryMsgTime(Hab : LongInt) : LongInt;
Begin
  W16_WinQueryMsgTime := WinQueryMsgTime(Hab);
End;

Function W16_WinCallMsgFilter(Hab, P, Msgf : LongInt) : LongInt;
Begin
  W16_WinCallMsgFilter := WinCallMsgFilter(Hab, P, Msgf);
End;

Function W16_WinSetMsgInterest(H, MsgCls, Ctl : LongInt) : LongInt;
Begin
  W16_WinSetMsgInterest := WinSetMsgInterest(H, MsgCls, Ctl);
End;

Function W16_WinSetCapture(HDesk, H : LongInt) : LongInt;
Begin
  W16_WinSetCapture := WinSetCapture(HDesk, H);
End;

Function W16_WinQueryCapture(HDesk : LongInt) : LongInt;
Begin
  W16_WinQueryCapture := WinQueryCapture(HDesk);
End;

Function W16_WinSetFocus(HDesk, H : LongInt) : LongInt;
Begin
  W16_WinSetFocus := WinSetFocus(HDesk, H);
End;

Function W16_WinQueryFocus(HDesk : LongInt) : LongInt;
Begin
  W16_WinQueryFocus := WinQueryFocus(HDesk);
End;

Function W16_WinSetActiveWindow(HDesk, H : LongInt) : LongInt;
Begin
  W16_WinSetActiveWindow := WinSetActiveWindow(HDesk, H);
End;

Function W16_WinQueryActiveWindow(HPar : LongInt) : LongInt;
Begin
  W16_WinQueryActiveWindow := WinQueryActiveWindow(HPar);
End;

Function W16_WinSetSysModalWindow(HDesk, H : LongInt) : LongInt;
Begin
  W16_WinSetSysModalWindow := WinSetSysModalWindow(HDesk, H);
End;

Function W16_WinQuerySysModalWindow(HDesk : LongInt) : LongInt;
Begin
  W16_WinQuerySysModalWindow := WinQuerySysModalWindow(HDesk);
End;

Function W16_WinIsThreadActive(Hab : LongInt) : LongInt;
Begin
  W16_WinIsThreadActive := WinIsThreadActive(Hab);
End;

Function W16_WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt;
Begin
  W16_WinStartTimer := WinStartTimer(Hab, H, Id, Dt);
End;

Function W16_WinStopTimer(Hab, H, Id : LongInt) : LongInt;
Begin
  W16_WinStopTimer := WinStopTimer(Hab, H, Id);
End;

Function W16_WinGetCurrentTime(Hab : LongInt) : LongInt;
Begin
  W16_WinGetCurrentTime := WinGetCurrentTime(Hab);
End;

Function W16_WinLoadPointer(HDesk, Hmod, Id : LongInt) : LongInt;
Begin
  W16_WinLoadPointer := WinLoadPointer(HDesk, Hmod, Id);
End;

Function W16_WinCreatePointer(HDesk, Hbm, FPtr, HotX, HotY : LongInt) : LongInt;
Begin
  W16_WinCreatePointer := WinCreatePointer(HDesk, Hbm, FPtr, HotX, HotY);
End;

Function W16_WinDestroyPointer(H : LongInt) : LongInt;
Begin
  W16_WinDestroyPointer := WinDestroyPointer(H);
End;

Function W16_WinQuerySysPointer(HDesk, Iptr, Load : LongInt) : LongInt;
Begin
  W16_WinQuerySysPointer := WinQuerySysPointer(HDesk, Iptr, Load);
End;

Function W16_WinSetPointer(HDesk, Hptr : LongInt) : LongInt;
Begin
  W16_WinSetPointer := WinSetPointer(HDesk, Hptr);
End;

Function W16_WinQueryPointer(HDesk : LongInt) : LongInt;
Begin
  W16_WinQueryPointer := WinQueryPointer(HDesk);
End;

Function W16_WinShowPointer(HDesk, Show : LongInt) : LongInt;
Begin
  W16_WinShowPointer := WinShowPointer(HDesk, Show);
End;

Function W16_WinSetPointerPos(HDesk, X, Y : LongInt) : LongInt;
Begin
  W16_WinSetPointerPos := WinSetPointerPos(HDesk, X, Y);
End;

Function W16_WinQueryPointerPos(HDesk, P : LongInt) : LongInt;
Begin
  W16_WinQueryPointerPos := WinQueryPointerPos(HDesk, P);
End;

Function W16_WinGetSysBitmap(HDesk, Ibm : LongInt) : LongInt;
Begin
  W16_WinGetSysBitmap := WinGetSysBitmap(HDesk, Ibm);
End;

Function W16_WinCreateCursor(H, X, Y, Cx, Cy, Fs, PClip : LongInt) : LongInt;
Begin
  W16_WinCreateCursor := WinCreateCursor(H, X, Y, Cx, Cy, Fs, PClip);
End;

Function W16_WinDestroyCursor(H : LongInt) : LongInt;
Begin
  W16_WinDestroyCursor := WinDestroyCursor(H);
End;

Function W16_WinShowCursor(H, Show : LongInt) : LongInt;
Begin
  W16_WinShowCursor := WinShowCursor(H, Show);
End;

Function W16_WinQueryCursorInfo(HDesk, P : LongInt) : LongInt;
Begin
  W16_WinQueryCursorInfo := WinQueryCursorInfo(HDesk, P);
End;

Function W16_WinLoadAccelTable(Hab, Hmod, Id : LongInt) : LongInt;
Begin
  W16_WinLoadAccelTable := WinLoadAccelTable(Hab, Hmod, Id);
End;

Function W16_WinCreateAccelTable(Hab, P : LongInt) : LongInt;
Begin
  W16_WinCreateAccelTable := WinCreateAccelTable(Hab, P);
End;

Function W16_WinDestroyAccelTable(H : LongInt) : LongInt;
Begin
  W16_WinDestroyAccelTable := WinDestroyAccelTable(H);
End;

Function W16_WinTranslateAccel(Hab, H, HAcc, P : LongInt) : LongInt;
Begin
  W16_WinTranslateAccel := WinTranslateAccel(Hab, H, HAcc, P);
End;

Function W16_WinSetAccelTable(Hab, H, HFrame : LongInt) : LongInt;
Begin
  W16_WinSetAccelTable := WinSetAccelTable(Hab, H, HFrame);
End;

Function W16_WinQueryAccelTable(Hab, HFrame : LongInt) : LongInt;
Begin
  W16_WinQueryAccelTable := WinQueryAccelTable(Hab, HFrame);
End;

Function W16_WinCopyAccelTable(H, P, Cb : LongInt) : LongInt;
Begin
  W16_WinCopyAccelTable := WinCopyAccelTable(H, P, Cb);
End;

Function W16_WinSetHook(Hab, Hmq, Typ, Pfn, Hmod : LongInt) : LongInt;
Begin
  W16_WinSetHook := WinSetHook(Hab, Hmq, Typ, Pfn, Hmod);
End;

Function W16_WinReleaseHook(Hab, Hmq, Typ, Pfn, Hmod : LongInt) : LongInt;
Begin
  W16_WinReleaseHook := WinReleaseHook(Hab, Hmq, Typ, Pfn, Hmod);
End;

Function W16_WinOpenClipbrd(Hab : LongInt) : LongInt;
Begin
  W16_WinOpenClipbrd := WinOpenClipbrd(Hab);
End;

Function W16_WinCloseClipbrd(Hab : LongInt) : LongInt;
Begin
  W16_WinCloseClipbrd := WinCloseClipbrd(Hab);
End;

Function W16_WinEmptyClipbrd(Hab : LongInt) : LongInt;
Begin
  W16_WinEmptyClipbrd := WinEmptyClipbrd(Hab);
End;

Function W16_WinSetClipbrdOwner(Hab, H : LongInt) : LongInt;
Begin
  W16_WinSetClipbrdOwner := WinSetClipbrdOwner(Hab, H);
End;

Function W16_WinQueryClipbrdOwner(Hab : LongInt) : LongInt;
Begin
  W16_WinQueryClipbrdOwner := WinQueryClipbrdOwner(Hab);
End;

Function W16_WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt;
Begin
  W16_WinSetClipbrdData := WinSetClipbrdData(Hab, Data, Fmt, Info);
End;

Function W16_WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt;
Begin
  W16_WinQueryClipbrdData := WinQueryClipbrdData(Hab, Fmt);
End;

Function W16_WinEnumClipbrdFmts(Hab, Fmt : LongInt) : LongInt;
Begin
  W16_WinEnumClipbrdFmts := WinEnumClipbrdFmts(Hab, Fmt);
End;

Function W16_WinQueryClipbrdFmtInfo(Hab, Fmt, P : LongInt) : LongInt;
Begin
  W16_WinQueryClipbrdFmtInfo := WinQueryClipbrdFmtInfo(Hab, Fmt, P);
End;

Function W16_WinSetClipbrdViewer(Hab, H : LongInt) : LongInt;
Begin
  W16_WinSetClipbrdViewer := WinSetClipbrdViewer(Hab, H);
End;

Function W16_WinQueryClipbrdViewer(Hab : LongInt) : LongInt;
Begin
  W16_WinQueryClipbrdViewer := WinQueryClipbrdViewer(Hab);
End;

Function W16_WinLoadDlg(HPar, HOwn, Proc, Hmod, Id, PCreate : LongInt) : LongInt;
Begin
  W16_WinLoadDlg := WinLoadDlg(HPar, HOwn, Proc, Hmod, Id, PCreate);
End;

Function W16_WinCreateDlg(HPar, HOwn, Proc, T, PCreate : LongInt) : LongInt;
Begin
  W16_WinCreateDlg := WinCreateDlg(HPar, HOwn, Proc, T, PCreate);
End;

Function W16_WinProcessDlg(H : LongInt) : LongInt;
Begin
  W16_WinProcessDlg := WinProcessDlg(H);
End;

Function W16_WinDlgBox(HPar, HOwn, Proc, Hmod, Id, PCreate : LongInt) : LongInt;
Begin
  W16_WinDlgBox := WinDlgBox(HPar, HOwn, Proc, Hmod, Id, PCreate);
End;

Function W16_WinDismissDlg(H, R : LongInt) : LongInt;
Begin
  W16_WinDismissDlg := WinDismissDlg(H, R);
End;

Function W16_WinSendDlgItemMsg(HDlg, Id, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  W16_WinSendDlgItemMsg := WinSendDlgItemMsg(HDlg, Id, Msg, Mp1, Mp2);
End;

Function W16_WinSetDlgItemShort(HDlg, Id, V, FSigned : LongInt) : LongInt;
Begin
  W16_WinSetDlgItemShort := WinSetDlgItemShort(HDlg, Id, V, FSigned);
End;

Function W16_WinQueryDlgItemShort(HDlg, Id, P, FSigned : LongInt) : LongInt;
Begin
  W16_WinQueryDlgItemShort := WinQueryDlgItemShort(HDlg, Id, P, FSigned);
End;

Function W16_WinSubstituteStrings(H, PSrc, Cch, PDst : LongInt) : LongInt;
Begin
  W16_WinSubstituteStrings := WinSubstituteStrings(H, PSrc, Cch, PDst);
End;

Function W16_WinEnumDlgItem(HDlg, H, Code : LongInt) : LongInt;
Begin
  W16_WinEnumDlgItem := WinEnumDlgItem(HDlg, H, Code);
End;

Function W16_WinSetDlgItemText(HDlg, Id, P : LongInt) : LongInt;
Begin
  W16_WinSetDlgItemText := WinSetDlgItemText(HDlg, Id, P);
End;

Function W16_WinQueryDlgItemText(HDlg, Id, Cch, P : LongInt) : LongInt;
Begin
  W16_WinQueryDlgItemText := WinQueryDlgItemText(HDlg, Id, Cch, P);
End;

Function W16_WinLoadMenu(HFrame, Hmod, Id : LongInt) : LongInt;
Begin
  W16_WinLoadMenu := WinLoadMenu(HFrame, Hmod, Id);
End;

Function W16_WinCreateMenu(HPar, P : LongInt) : LongInt;
Begin
  W16_WinCreateMenu := WinCreateMenu(HPar, P);
End;

Function W16_WinAlarm(HDesk, Typ : LongInt) : LongInt;
Begin
  W16_WinAlarm := WinAlarm(HDesk, Typ);
End;

Function W16_WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt;
Begin
  W16_WinMessageBox := WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl);
End;

Function W16_WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, IdRes, PClient : LongInt) : LongInt;
Begin
  W16_WinCreateStdWindow := WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, IdRes, PClient);
End;

Function W16_WinCreateFrameControls(H, P, PTitle : LongInt) : LongInt;
Begin
  W16_WinCreateFrameControls := WinCreateFrameControls(H, P, PTitle);
End;

Function W16_WinCalcFrameRect(H, P, FClient : LongInt) : LongInt;
Begin
  W16_WinCalcFrameRect := WinCalcFrameRect(H, P, FClient);
End;

Function W16_WinFlashWindow(H, FFlash : LongInt) : LongInt;
Begin
  W16_WinFlashWindow := WinFlashWindow(H, FFlash);
End;

Function W16_WinGetMinPosition(H, P, PPtl : LongInt) : LongInt;
Begin
  W16_WinGetMinPosition := WinGetMinPosition(H, P, PPtl);
End;

Function W16_WinGetMaxPosition(H, P : LongInt) : LongInt;
Begin
  W16_WinGetMaxPosition := WinGetMaxPosition(H, P);
End;

Function W16_WinQuerySysValue(HDesk, I : LongInt) : LongInt;
Begin
  W16_WinQuerySysValue := WinQuerySysValue(HDesk, I);
End;

Function W16_WinSetSysValue(HDesk, I, V : LongInt) : LongInt;
Begin
  W16_WinSetSysValue := WinSetSysValue(HDesk, I, V);
End;

Function W16_WinSetSysColors(HDesk, Opt, Fmt, First, N, P : LongInt) : LongInt;
Begin
  W16_WinSetSysColors := WinSetSysColors(HDesk, Opt, Fmt, First, N, P);
End;

Function W16_WinQuerySysColor(HDesk, Clr, Rsvd : LongInt) : LongInt;
Begin
  W16_WinQuerySysColor := WinQuerySysColor(HDesk, Clr, Rsvd);
End;

Function W16_WinScrollWindow(H, Dx, Dy, PScroll, PClip, Hrgn, PUpd, Fs : LongInt) : LongInt;
Begin
  W16_WinScrollWindow := WinScrollWindow(H, Dx, Dy, PScroll, PClip, Hrgn, PUpd, Fs);
End;

Function W16_WinTrackRect(H, Hps, P : LongInt) : LongInt;
Begin
  W16_WinTrackRect := WinTrackRect(H, Hps, P);
End;

Function W16_WinShowTrackRect(H, FShow : LongInt) : LongInt;
Begin
  W16_WinShowTrackRect := WinShowTrackRect(H, FShow);
End;

Function W16_WinLoadString(Hab, Hmod, Id, Cch, P : LongInt) : LongInt;
Begin
  W16_WinLoadString := WinLoadString(Hab, Hmod, Id, Cch, P);
End;

Function W16_WinLoadMessage(Hab, Hmod, Id, Cch, P : LongInt) : LongInt;
Begin
  W16_WinLoadMessage := WinLoadMessage(Hab, Hmod, Id, Cch, P);
End;

Function W16_WinSetRectEmpty(Hab, P : LongInt) : LongInt;
Begin
  W16_WinSetRectEmpty := WinSetRectEmpty(Hab, P);
End;

Function W16_WinSetRect(Hab, P, X1, Y1, X2, Y2 : LongInt) : LongInt;
Begin
  W16_WinSetRect := WinSetRect(Hab, P, X1, Y1, X2, Y2);
End;

Function W16_WinCopyRect(Hab, PD, PS : LongInt) : LongInt;
Begin
  W16_WinCopyRect := WinCopyRect(Hab, PD, PS);
End;

Function W16_WinIsRectEmpty(Hab, P : LongInt) : LongInt;
Begin
  W16_WinIsRectEmpty := WinIsRectEmpty(Hab, P);
End;

Function W16_WinEqualRect(Hab, P1, P2 : LongInt) : LongInt;
Begin
  W16_WinEqualRect := WinEqualRect(Hab, P1, P2);
End;

Function W16_WinPtInRect(Hab, P, PPt : LongInt) : LongInt;
Begin
  W16_WinPtInRect := WinPtInRect(Hab, P, PPt);
End;

Function W16_WinOffsetRect(Hab, P, Dx, Dy : LongInt) : LongInt;
Begin
  W16_WinOffsetRect := WinOffsetRect(Hab, P, Dx, Dy);
End;

Function W16_WinInflateRect(Hab, P, Cx, Cy : LongInt) : LongInt;
Begin
  W16_WinInflateRect := WinInflateRect(Hab, P, Cx, Cy);
End;

Function W16_WinIntersectRect(Hab, PD, P1, P2 : LongInt) : LongInt;
Begin
  W16_WinIntersectRect := WinIntersectRect(Hab, PD, P1, P2);
End;

Function W16_WinUnionRect(Hab, PD, P1, P2 : LongInt) : LongInt;
Begin
  W16_WinUnionRect := WinUnionRect(Hab, PD, P1, P2);
End;

Function W16_WinSubtractRect(Hab, PD, P1, P2 : LongInt) : LongInt;
Begin
  W16_WinSubtractRect := WinSubtractRect(Hab, PD, P1, P2);
End;

Function W16_WinMakeRect(Hab, P : LongInt) : LongInt;
Begin
  W16_WinMakeRect := WinMakeRect(Hab, P);
End;

Function W16_WinMakePoints(Hab, P, N : LongInt) : LongInt;
Begin
  W16_WinMakePoints := WinMakePoints(Hab, P, N);
End;

Function W16_WinInvertRect(Hps, P : LongInt) : LongInt;
Begin
  W16_WinInvertRect := WinInvertRect(Hps, P);
End;

Function W16_WinFillRect(Hps, P, Clr : LongInt) : LongInt;
Begin
  W16_WinFillRect := WinFillRect(Hps, P, Clr);
End;

Function W16_WinDrawPointer(Hps, X, Y, H, Fs : LongInt) : LongInt;
Begin
  W16_WinDrawPointer := WinDrawPointer(Hps, X, Y, H, Fs);
End;

Function W16_WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  W16_WinDefWindowProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

Function W16_WinDefDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  W16_WinDefDlgProc := WinDefDlgProc(H, Msg, Mp1, Mp2);
End;

Function W16_WinQueryProcessCP(Hmq : LongInt) : LongInt;
Begin
  W16_WinQueryProcessCP := WinQueryProcessCP(Hmq);
End;

Function W16_WinGetKeyState(HDesk, Vk : LongInt) : LongInt;
Begin
  W16_WinGetKeyState := WinGetKeyState(HDesk, Vk);
End;

Function W16_WinGetPhysKeyState(HDesk, Sc : LongInt) : LongInt;
Begin
  W16_WinGetPhysKeyState := WinGetPhysKeyState(HDesk, Sc);
End;

Function W16_WinSetKeyboardStateTable(HDesk, P, FSet : LongInt) : LongInt;
Begin
  W16_WinSetKeyboardStateTable := WinSetKeyboardStateTable(HDesk, P, FSet);
End;

Function W16_WinEnablePhysInput(HDesk, En : LongInt) : LongInt;
Begin
  W16_WinEnablePhysInput := WinEnablePhysInput(HDesk, En);
End;

Function W16_WinSetCp(Hmq, Cp : LongInt) : LongInt;
Begin
  W16_WinSetCp := WinSetCp(Hmq, Cp);
End;

Function W16_WinQueryCp(Hmq : LongInt) : LongInt;
Begin
  W16_WinQueryCp := WinQueryCp(Hmq);
End;

Function W16_WinQueryCpList(Hab, N, P : LongInt) : LongInt;
Begin
  W16_WinQueryCpList := WinQueryCpList(Hab, N, P);
End;

Function W16_WinCpTranslateString(Hab, CpS, PSrc, CpD, Cch, PDst : LongInt) : LongInt;
Begin
  W16_WinCpTranslateString := WinCpTranslateString(Hab, CpS, PSrc, CpD, Cch, PDst);
End;

Function W16_WinCpTranslateChar(Hab, CpS, C, CpD : LongInt) : LongInt;
Begin
  W16_WinCpTranslateChar := WinCpTranslateChar(Hab, CpS, C, CpD);
End;

Function W16_WinCompareStrings(Hab, Cp, Cc, P1, P2, Rsvd : LongInt) : LongInt;
Begin
  W16_WinCompareStrings := WinCompareStrings(Hab, Cp, Cc, P1, P2, Rsvd);
End;

Function W16_WinUpper(Hab, Cp, Cc, P : LongInt) : LongInt;
Begin
  W16_WinUpper := WinUpper(Hab, Cp, Cc, P);
End;

Function W16_WinUpperChar(Hab, Cp, Cc, C : LongInt) : LongInt;
Begin
  W16_WinUpperChar := WinUpperChar(Hab, Cp, Cc, C);
End;

Function W16_WinNextChar(Hab, Cp, Cc, P : LongInt) : LongInt;
Begin
  W16_WinNextChar := WinNextChar(Hab, Cp, Cc, P);
End;

Function W16_WinPrevChar(Hab, Cp, Cc, PStart, P : LongInt) : LongInt;
Begin
  W16_WinPrevChar := WinPrevChar(Hab, Cp, Cc, PStart, P);
End;

Function W16_WinCreateAtomTable(CbInit, CBuckets : LongInt) : LongInt;
Begin
  W16_WinCreateAtomTable := WinCreateAtomTable(CbInit, CBuckets);
End;

Function W16_WinDestroyAtomTable(H : LongInt) : LongInt;
Begin
  W16_WinDestroyAtomTable := WinDestroyAtomTable(H);
End;

Function W16_WinAddAtom(H, P : LongInt) : LongInt;
Begin
  W16_WinAddAtom := WinAddAtom(H, P);
End;

Function W16_WinFindAtom(H, P : LongInt) : LongInt;
Begin
  W16_WinFindAtom := WinFindAtom(H, P);
End;

Function W16_WinDeleteAtom(H, A : LongInt) : LongInt;
Begin
  W16_WinDeleteAtom := WinDeleteAtom(H, A);
End;

Function W16_WinQueryAtomUsage(H, A : LongInt) : LongInt;
Begin
  W16_WinQueryAtomUsage := WinQueryAtomUsage(H, A);
End;

Function W16_WinQueryAtomLength(H, A : LongInt) : LongInt;
Begin
  W16_WinQueryAtomLength := WinQueryAtomLength(H, A);
End;

Function W16_WinQueryAtomName(H, A, P, Cch : LongInt) : LongInt;
Begin
  W16_WinQueryAtomName := WinQueryAtomName(H, A, P, Cch);
End;

Function W16_WinQuerySystemAtomTable : LongInt;
Begin
  W16_WinQuerySystemAtomTable := WinQuerySystemAtomTable;
End;

Function W16_WinGetLastError(Hab : LongInt) : LongInt;
Begin
  W16_WinGetLastError := WinGetLastError(Hab);
End;

Function W16_WinGetErrorInfo(Hab : LongInt) : LongInt;
Begin
  W16_WinGetErrorInfo := WinGetErrorInfo(Hab);
End;

Function W16_WinFreeErrorInfo(P : LongInt) : LongInt;
Begin
  W16_WinFreeErrorInfo := WinFreeErrorInfo(P);
End;

Function W16_WinInitialize(Fl : LongInt) : LongInt;
Begin
  W16_WinInitialize := WinInitialize(Fl);
End;

Function W16_WinTerminate(Hab : LongInt) : LongInt;
Begin
  W16_WinTerminate := WinTerminate(Hab);
End;

Function W16_WinQueryVersion(Hab : LongInt) : LongInt;
Begin
  W16_WinQueryVersion := WinQueryVersion(Hab);
End;

Function W16_WinIsPhysInputEnabled(HDesk : LongInt) : LongInt;
Begin
  W16_WinIsPhysInputEnabled := WinIsPhysInputEnabled(HDesk);
End;

Function W16_WinQueryWindowDC(H : LongInt) : LongInt;
Begin
  W16_WinQueryWindowDC := WinQueryWindowDC(H);
End;

Function W16_WinDrawBorder(Hps, P, Cx, Cy, Fg, Bg, Fl : LongInt) : LongInt;
Begin
  W16_WinDrawBorder := WinDrawBorder(Hps, P, Cx, Cy, Fg, Bg, Fl);
End;

Function W16_WinDrawText(Hps, Cch, P, PRcl, Fg, Bg, Fl : LongInt) : LongInt;
Begin
  W16_WinDrawText := WinDrawText(Hps, Cch, P, PRcl, Fg, Bg, Fl);
End;

Function W16_WinDrawBitmap(Hps, Hbm, PSrc, PDst, Fg, Bg, Fl : LongInt) : LongInt;
Begin
  W16_WinDrawBitmap := WinDrawBitmap(Hps, Hbm, PSrc, PDst, Fg, Bg, Fl);
End;

Function W16_WinQueryWindowPtr(H, Index : LongInt) : LongInt;
Begin
  W16_WinQueryWindowPtr := WinQueryWindowPtr(H, Index);
End;

Function W16_WinSetWindowPtr(H, Index, V : LongInt) : LongInt;
Begin
  W16_WinSetWindowPtr := WinSetWindowPtr(H, Index, V);
End;

Function W16_WinMsgSemWait(H, T : LongInt) : LongInt;
Begin
  W16_WinMsgSemWait := WinMsgSemWait(H, T);
End;

Function W16_WinMsgMuxSemWait(PI, PL, T : LongInt) : LongInt;
Begin
  W16_WinMsgMuxSemWait := WinMsgMuxSemWait(PI, PL, T);
End;

Function W16_WinSystemShutdown(Hab, Hmq : LongInt) : LongInt;
Begin
  W16_WinSystemShutdown := WinSystemShutdown(Hab, Hmq);
End;

Function W16_WinCancelShutdown(Hmq, FAlways : LongInt) : LongInt;
Begin
  W16_WinCancelShutdown := WinCancelShutdown(Hmq, FAlways);
End;

Function W16_WinSetWindowBits(H, Index, Data, Mask : LongInt) : LongInt;
Begin
  W16_WinSetWindowBits := WinSetWindowBits(H, Index, Data, Mask);
End;

Function W16_WinGetClipPS(H, HClip, Fl : LongInt) : LongInt;
Begin
  W16_WinGetClipPS := WinGetClipPS(H, HClip, Fl);
End;

Function W16_WinSaveWindowPos(Hsv, P, N : LongInt) : LongInt;
Begin
  W16_WinSaveWindowPos := WinSaveWindowPos(Hsv, P, N);
End;

Function W16_WinFocusChange(HDesk, H, Fl : LongInt) : LongInt;
Begin
  W16_WinFocusChange := WinFocusChange(HDesk, H, Fl);
End;

Function W16_WinQueryQueueInfo(Hmq, P, Cb : LongInt) : LongInt;
Begin
  W16_WinQueryQueueInfo := WinQueryQueueInfo(Hmq, P, Cb);
End;

Function W16_WinSetClassMsgInterest(Hab, PCls, MsgCls, Ctl : LongInt) : LongInt;
Begin
  W16_WinSetClassMsgInterest := WinSetClassMsgInterest(Hab, PCls, MsgCls, Ctl);
End;

Function W16_WinQueryDlgItemTextLength(HDlg, Id : LongInt) : LongInt;
Begin
  W16_WinQueryDlgItemTextLength := WinQueryDlgItemTextLength(HDlg, Id);
End;

Function W16_WinDdeInitiate(HClient, PApp, PTopic, PCtx : LongInt) : LongInt;
Begin
  W16_WinDdeInitiate := WinDdeInitiate(HClient, PApp, PTopic, PCtx);
End;

Function W16_WinDdeRespond(HClient, HServer, PApp, PTopic, PCtx : LongInt) : LongInt;
Begin
  W16_WinDdeRespond := WinDdeRespond(HClient, HServer, PApp, PTopic, PCtx);
End;

Function W16_WinDdePostMsg(HTo, HFrom, Msg, P, Fl : LongInt) : LongInt;
Begin
  W16_WinDdePostMsg := WinDdePostMsg(HTo, HFrom, Msg, P, Fl);
End;

Function W16_WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt;
Begin
  W16_WinSetPresParam := WinSetPresParam(H, Id, Cb, P);
End;

Function W16_WinQueryPresParam(H, Id1, Id2, PId, Cb, P, Fs : LongInt) : LongInt;
Begin
  W16_WinQueryPresParam := WinQueryPresParam(H, Id1, Id2, PId, Cb, P, Fs);
End;

Function W16_WinRemovePresParam(H, Id : LongInt) : LongInt;
Begin
  W16_WinRemovePresParam := WinRemovePresParam(H, Id);
End;

Function W16_WinThreadAssocQueue(Hab, Hmq : LongInt) : LongInt;
Begin
  W16_WinThreadAssocQueue := WinThreadAssocQueue(Hab, Hmq);
End;

Function W16_WinQueueFromId(Hab, Pid, Tid : LongInt) : LongInt;
Begin
  W16_WinQueueFromId := WinQueueFromId(Hab, Pid, Tid);
End;

Function W16_WinQuerySendMsg(Hab, HmqSender, HmqReceiver, P : LongInt) : LongInt;
Begin
  W16_WinQuerySendMsg := WinQuerySendMsg(Hab, HmqSender, HmqReceiver, P);
End;

Function W16_WinReplyMsg(Hab, HmqSender, HmqReceiver, Mres : LongInt) : LongInt;
Begin
  W16_WinReplyMsg := WinReplyMsg(Hab, HmqSender, HmqReceiver, Mres);
End;

Function W16_WinWakeThread(Hmq : LongInt) : LongInt;
Begin
  W16_WinWakeThread := WinWakeThread(Hmq);
End;

Function W16_WinLockInput(Hmq, Lock : LongInt) : LongInt;
Begin
  W16_WinLockInput := WinLockInput(Hmq, Lock);
End;

Function W16_WinBuildPtrHandle(P : LongInt) : LongInt;
Begin
  W16_WinBuildPtrHandle := WinBuildPtrHandle(P);
End;

Function W16_WinQueryWindowModel(H : LongInt) : LongInt;
Begin
  W16_WinQueryWindowModel := WinQueryWindowModel(H);
End;

Function W16_WinSetDesktopBkgnd(HDesk, P : LongInt) : LongInt;
Begin
  W16_WinSetDesktopBkgnd := WinSetDesktopBkgnd(HDesk, P);
End;

Function W16_WinQueryDesktopBkgnd(HDesk, P : LongInt) : LongInt;
Begin
  W16_WinQueryDesktopBkgnd := WinQueryDesktopBkgnd(HDesk, P);
End;

Function W16_WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt;
Begin
  W16_WinPopupMenu := WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs);
End;

Function W16_WinRealizePalette(H, Hps, P : LongInt) : LongInt;
Begin
  W16_WinRealizePalette := WinRealizePalette(H, Hps, P);
End;

Function W16_WinSemEnter : LongInt;
Begin
  W16_WinSemEnter := WinSemEnter;
End;

Function W16_WinSemLeave : LongInt;
Begin
  W16_WinSemLeave := WinSemLeave;
End;

Function W16_WinSemQuery : LongInt;
Begin
  W16_WinSemQuery := WinSemQuery;
End;

Function W16_WinDeleteLibrary(Hab, H : LongInt) : LongInt;
Begin
  W16_WinDeleteLibrary := WinDeleteLibrary(Hab, H);
End;

Function W16_WinLoadProcedure(Hab, H, P : LongInt) : LongInt;
Begin
  W16_WinLoadProcedure := WinLoadProcedure(Hab, H, P);
End;

Function W16_WinDeleteProcedure(Hab, Pfn : LongInt) : LongInt;
Begin
  W16_WinDeleteProcedure := WinDeleteProcedure(Hab, Pfn);
End;

Function W16_WinSetMsgMode(Hab, PCls, Ctl : LongInt) : LongInt;
Begin
  W16_WinSetMsgMode := WinSetMsgMode(Hab, PCls, Ctl);
End;

Function W16_WinSetSynchroMode(Hab, Mode : LongInt) : LongInt;
Begin
  W16_WinSetSynchroMode := WinSetSynchroMode(Hab, Mode);
End;

Function W16_WinGetDlgMsg(H, P : LongInt) : LongInt;
Begin
  W16_WinGetDlgMsg := WinGetDlgMsg(H, P);
End;

Function W16_WinRegisterUserMsg(Hab, Msg, T1, D1, T2, D2, Tr : LongInt) : LongInt;
Begin
  W16_WinRegisterUserMsg := WinRegisterUserMsg(Hab, Msg, T1, D1, T2, D2, Tr);
End;

Function W16_WinQueryAnchorBlock(H : LongInt) : LongInt;
Begin
  W16_WinQueryAnchorBlock := WinQueryAnchorBlock(H);
End;

Function W16_WinRegisterUserDatatype(Hab, T, N, P : LongInt) : LongInt;
Begin
  W16_WinRegisterUserDatatype := WinRegisterUserDatatype(Hab, T, N, P);
End;

Function W16_WinIsWindowShowing(H : LongInt) : LongInt;
Begin
  W16_WinIsWindowShowing := WinIsWindowShowing(H);
End;

Function W16_WinLoadLibrary(Hab, P : LongInt) : LongInt;
Begin
  W16_WinLoadLibrary := WinLoadLibrary(Hab, P);
End;

Function W16_WinCreatePointerIndirect(HDesk, P : LongInt) : LongInt;
Begin
  W16_WinCreatePointerIndirect := WinCreatePointerIndirect(HDesk, P);
End;

Function W16_WinQueryPointerInfo(H, P : LongInt) : LongInt;
Begin
  W16_WinQueryPointerInfo := WinQueryPointerInfo(H, P);
End;

Function W16_WinGetErasePS(H : LongInt) : LongInt;
Begin
  W16_WinGetErasePS := WinGetErasePS(H);
End;

Function W16_WinReleaseErasePS(Hps : LongInt) : LongInt;
Begin
  W16_WinReleaseErasePS := WinReleaseErasePS(Hps);
End;

Function W16_WinExplodeWindow(H, PSwp : LongInt) : LongInt;
Begin
  W16_WinExplodeWindow := WinExplodeWindow(H, PSwp);
End;

Function W16_WinSetAccelTableValue(H, Ix, P : LongInt) : LongInt;
Begin
  W16_WinSetAccelTableValue := WinSetAccelTableValue(H, Ix, P);
End;

Function W16_WinQueryAccelTableValue(H, Ix, P : LongInt) : LongInt;
Begin
  W16_WinQueryAccelTableValue := WinQueryAccelTableValue(H, Ix, P);
End;

Function W16_WinStretchPointer(Hps, X, Y, Cx, Cy, H, Fs : LongInt) : LongInt;
Begin
  W16_WinStretchPointer := WinStretchPointer(Hps, X, Y, Cx, Cy, H, Fs);
End;

Function W16_WinSetPointerOwner(H, Pid, FDestroy : LongInt) : LongInt;
Begin
  W16_WinSetPointerOwner := WinSetPointerOwner(H, Pid, FDestroy);
End;

Function W16_WinGetFrameTreePPSize(H : LongInt) : LongInt;
Begin
  W16_WinGetFrameTreePPSize := WinGetFrameTreePPSize(H);
End;

Function W16_WinGetFrameTreePPs(H, Cb, P : LongInt) : LongInt;
Begin
  W16_WinGetFrameTreePPs := WinGetFrameTreePPs(H, Cb, P);
End;

Function W16_WinSetFrameTreePPs(H, Cb, P : LongInt) : LongInt;
Begin
  W16_WinSetFrameTreePPs := WinSetFrameTreePPs(H, Cb, P);
End;

Function W16_WinSetClassThunkProc(PCls, Pfn : LongInt) : LongInt;
Begin
  W16_WinSetClassThunkProc := WinSetClassThunkProc(PCls, Pfn);
End;

Function W16_WinQueryClassThunkProc(PCls : LongInt) : LongInt;
Begin
  W16_WinQueryClassThunkProc := WinQueryClassThunkProc(PCls);
End;

Function W16_WinSetWindowThunkProc(H, Pfn : LongInt) : LongInt;
Begin
  W16_WinSetWindowThunkProc := WinSetWindowThunkProc(H, Pfn);
End;

Function W16_WinQueryWindowThunkProc(H : LongInt) : LongInt;
Begin
  W16_WinQueryWindowThunkProc := WinQueryWindowThunkProc(H);
End;

Function W16_WinSetSysClipbrdViewer(Hab, H : LongInt) : LongInt;
Begin
  W16_WinSetSysClipbrdViewer := WinSetSysClipbrdViewer(Hab, H);
End;

exports
  W16_WinQueryDesktopWindow Index 1 Name 'WINQUERYDESKTOPWINDOW',
  W16_WinQueryObjectWindow Index 2 Name 'WINQUERYOBJECTWINDOW',
  W16_WinRegisterClass Index 3 Name 'WINREGISTERCLASS',
  W16_WinQueryClassName Index 4 Name 'WINQUERYCLASSNAME',
  W16_WinQueryClassInfo Index 5 Name 'WINQUERYCLASSINFO',
  W16_WinCreateWindow Index 6 Name 'WINCREATEWINDOW',
  W16_WinDestroyWindow Index 7 Name 'WINDESTROYWINDOW',
  W16_WinSetWindowPos Index 8 Name 'WINSETWINDOWPOS',
  W16_WinSetMultWindowPos Index 9 Name 'WINSETMULTWINDOWPOS',
  W16_WinQueryWindowPos Index 10 Name 'WINQUERYWINDOWPOS',
  W16_WinEnableWindow Index 11 Name 'WINENABLEWINDOW',
  W16_WinIsWindowEnabled Index 12 Name 'WINISWINDOWENABLED',
  W16_WinShowWindow Index 13 Name 'WINSHOWWINDOW',
  W16_WinEnableWindowUpdate Index 14 Name 'WINENABLEWINDOWUPDATE',
  W16_WinIsWindowVisible Index 15 Name 'WINISWINDOWVISIBLE',
  W16_WinSetWindowText Index 16 Name 'WINSETWINDOWTEXT',
  W16_WinQueryWindowText Index 17 Name 'WINQUERYWINDOWTEXT',
  W16_WinQueryWindowTextLength Index 18 Name 'WINQUERYWINDOWTEXTLENGTH',
  W16_WinWindowFromID Index 19 Name 'WINWINDOWFROMID',
  W16_WinMultWindowFromIDs Index 20 Name 'WINMULTWINDOWFROMIDS',
  W16_WinIsWindow Index 21 Name 'WINISWINDOW',
  W16_WinIsChild Index 22 Name 'WINISCHILD',
  W16_WinSetParent Index 23 Name 'WINSETPARENT',
  W16_WinSetOwner Index 24 Name 'WINSETOWNER',
  W16_WinQueryWindow Index 25 Name 'WINQUERYWINDOW',
  W16_WinQueryWindowRect Index 26 Name 'WINQUERYWINDOWRECT',
  W16_WinQueryWindowProcess Index 27 Name 'WINQUERYWINDOWPROCESS',
  W16_WinSetWindowUShort Index 28 Name 'WINSETWINDOWUSHORT',
  W16_WinQueryWindowUShort Index 29 Name 'WINQUERYWINDOWUSHORT',
  W16_WinSetWindowULong Index 30 Name 'WINSETWINDOWULONG',
  W16_WinQueryWindowULong Index 31 Name 'WINQUERYWINDOWULONG',
  W16_WinBeginEnumWindows Index 32 Name 'WINBEGINENUMWINDOWS',
  W16_WinGetNextWindow Index 33 Name 'WINGETNEXTWINDOW',
  W16_WinEndEnumWindows Index 34 Name 'WINENDENUMWINDOWS',
  W16_WinWindowFromPoint Index 35 Name 'WINWINDOWFROMPOINT',
  W16_WinMapWindowPoints Index 36 Name 'WINMAPWINDOWPOINTS',
  W16_WinSubclassWindow Index 37 Name 'WINSUBCLASSWINDOW',
  WinLockWindow Index 38 Name 'WinLockWindow',
  WinQueryWindowLockCount Index 39 Name 'WinQueryWindowLockCount',
  WinRegisterWindowDestroy Index 40 Name 'WinRegisterWindowDestroy',
  W16_WinOpenWindowDC Index 41 Name 'WINOPENWINDOWDC',
  W16_WinGetScreenPS Index 42 Name 'WINGETSCREENPS',
  W16_WinGetPS Index 43 Name 'WINGETPS',
  W16_WinReleasePS Index 44 Name 'WINRELEASEPS',
  W16_WinBeginPaint Index 45 Name 'WINBEGINPAINT',
  W16_WinEndPaint Index 46 Name 'WINENDPAINT',
  W16_WinInvalidateRect Index 47 Name 'WININVALIDATERECT',
  W16_WinInvalidateRegion Index 48 Name 'WININVALIDATEREGION',
  W16_WinValidateRect Index 49 Name 'WINVALIDATERECT',
  W16_WinValidateRegion Index 50 Name 'WINVALIDATEREGION',
  W16_WinQueryUpdateRect Index 51 Name 'WINQUERYUPDATERECT',
  W16_WinQueryUpdateRegion Index 52 Name 'WINQUERYUPDATEREGION',
  W16_WinUpdateWindow Index 53 Name 'WINUPDATEWINDOW',
  W16_WinExcludeUpdateRegion Index 54 Name 'WINEXCLUDEUPDATEREGION',
  W16_WinLockWindowUpdate Index 55 Name 'WINLOCKWINDOWUPDATE',
  W16_WinLockVisRegions Index 56 Name 'WINLOCKVISREGIONS',
  W16_WinWindowFromDC Index 57 Name 'WINWINDOWFROMDC',
  W16_WinCreateMsgQueue Index 58 Name 'WINCREATEMSGQUEUE',
  W16_WinDestroyMsgQueue Index 59 Name 'WINDESTROYMSGQUEUE',
  W16_WinQueryQueueStatus Index 60 Name 'WINQUERYQUEUESTATUS',
  W16_WinSendMsg Index 61 Name 'WINSENDMSG',
  W16_WinBroadcastMsg Index 63 Name 'WINBROADCASTMSG',
  W16_WinInSendMsg Index 64 Name 'WININSENDMSG',
  W16_WinGetMsg Index 65 Name 'WINGETMSG',
  W16_WinPeekMsg Index 66 Name 'WINPEEKMSG',
  W16_WinWaitMsg Index 67 Name 'WINWAITMSG',
  W16_WinDispatchMsg Index 68 Name 'WINDISPATCHMSG',
  W16_WinPostMsg Index 69 Name 'WINPOSTMSG',
  W16_WinPostQueueMsg Index 70 Name 'WINPOSTQUEUEMSG',
  W16_WinQueryMsgPos Index 71 Name 'WINQUERYMSGPOS',
  W16_WinQueryMsgTime Index 72 Name 'WINQUERYMSGTIME',
  W16_WinCallMsgFilter Index 73 Name 'WINCALLMSGFILTER',
  W16_WinSetMsgInterest Index 74 Name 'WINSETMSGINTEREST',
  W16_WinSetCapture Index 75 Name 'WINSETCAPTURE',
  W16_WinQueryCapture Index 76 Name 'WINQUERYCAPTURE',
  W16_WinSetFocus Index 77 Name 'WINSETFOCUS',
  W16_WinQueryFocus Index 78 Name 'WINQUERYFOCUS',
  W16_WinSetActiveWindow Index 79 Name 'WINSETACTIVEWINDOW',
  W16_WinQueryActiveWindow Index 80 Name 'WINQUERYACTIVEWINDOW',
  W16_WinSetSysModalWindow Index 81 Name 'WINSETSYSMODALWINDOW',
  W16_WinQuerySysModalWindow Index 82 Name 'WINQUERYSYSMODALWINDOW',
  W16_WinIsThreadActive Index 83 Name 'WINISTHREADACTIVE',
  W16_WinStartTimer Index 84 Name 'WINSTARTTIMER',
  W16_WinStopTimer Index 85 Name 'WINSTOPTIMER',
  W16_WinGetCurrentTime Index 86 Name 'WINGETCURRENTTIME',
  W16_WinLoadPointer Index 87 Name 'WINLOADPOINTER',
  W16_WinCreatePointer Index 88 Name 'WINCREATEPOINTER',
  W16_WinDestroyPointer Index 89 Name 'WINDESTROYPOINTER',
  OldWinQueryPointerInfo Index 90 Name 'OldWinQueryPointerInfo',
  W16_WinQuerySysPointer Index 91 Name 'WINQUERYSYSPOINTER',
  W16_WinSetPointer Index 92 Name 'WINSETPOINTER',
  W16_WinQueryPointer Index 93 Name 'WINQUERYPOINTER',
  W16_WinShowPointer Index 94 Name 'WINSHOWPOINTER',
  W16_WinSetPointerPos Index 95 Name 'WINSETPOINTERPOS',
  W16_WinQueryPointerPos Index 96 Name 'WINQUERYPOINTERPOS',
  W16_WinGetSysBitmap Index 97 Name 'WINGETSYSBITMAP',
  W16_WinCreateCursor Index 98 Name 'WINCREATECURSOR',
  W16_WinDestroyCursor Index 99 Name 'WINDESTROYCURSOR',
  W16_WinShowCursor Index 100 Name 'WINSHOWCURSOR',
  W16_WinQueryCursorInfo Index 101 Name 'WINQUERYCURSORINFO',
  W16_WinLoadAccelTable Index 102 Name 'WINLOADACCELTABLE',
  W16_WinCreateAccelTable Index 103 Name 'WINCREATEACCELTABLE',
  W16_WinDestroyAccelTable Index 104 Name 'WINDESTROYACCELTABLE',
  W16_WinTranslateAccel Index 105 Name 'WINTRANSLATEACCEL',
  W16_WinSetAccelTable Index 106 Name 'WINSETACCELTABLE',
  W16_WinQueryAccelTable Index 107 Name 'WINQUERYACCELTABLE',
  W16_WinCopyAccelTable Index 108 Name 'WINCOPYACCELTABLE',
  W16_WinSetHook Index 109 Name 'WINSETHOOK',
  W16_WinReleaseHook Index 110 Name 'WINRELEASEHOOK',
  W16_WinOpenClipbrd Index 111 Name 'WINOPENCLIPBRD',
  W16_WinCloseClipbrd Index 112 Name 'WINCLOSECLIPBRD',
  W16_WinEmptyClipbrd Index 113 Name 'WINEMPTYCLIPBRD',
  W16_WinSetClipbrdOwner Index 114 Name 'WINSETCLIPBRDOWNER',
  W16_WinQueryClipbrdOwner Index 115 Name 'WINQUERYCLIPBRDOWNER',
  W16_WinSetClipbrdData Index 116 Name 'WINSETCLIPBRDDATA',
  W16_WinQueryClipbrdData Index 117 Name 'WINQUERYCLIPBRDDATA',
  W16_WinEnumClipbrdFmts Index 118 Name 'WINENUMCLIPBRDFMTS',
  W16_WinQueryClipbrdFmtInfo Index 119 Name 'WINQUERYCLIPBRDFMTINFO',
  W16_WinSetClipbrdViewer Index 120 Name 'WINSETCLIPBRDVIEWER',
  W16_WinQueryClipbrdViewer Index 121 Name 'WINQUERYCLIPBRDVIEWER',
  W16_WinLoadDlg Index 122 Name 'WINLOADDLG',
  W16_WinCreateDlg Index 123 Name 'WINCREATEDLG',
  W16_WinProcessDlg Index 124 Name 'WINPROCESSDLG',
  W16_WinDlgBox Index 125 Name 'WINDLGBOX',
  W16_WinDismissDlg Index 126 Name 'WINDISMISSDLG',
  W16_WinSendDlgItemMsg Index 127 Name 'WINSENDDLGITEMMSG',
  W16_WinSetDlgItemShort Index 128 Name 'WINSETDLGITEMSHORT',
  W16_WinQueryDlgItemShort Index 129 Name 'WINQUERYDLGITEMSHORT',
  W16_WinSubstituteStrings Index 132 Name 'WINSUBSTITUTESTRINGS',
  W16_WinEnumDlgItem Index 133 Name 'WINENUMDLGITEM',
  W16_WinSetDlgItemText Index 134 Name 'WINSETDLGITEMTEXT',
  W16_WinQueryDlgItemText Index 135 Name 'WINQUERYDLGITEMTEXT',
  W16_WinLoadMenu Index 136 Name 'WINLOADMENU',
  W16_WinCreateMenu Index 137 Name 'WINCREATEMENU',
  W16_WinAlarm Index 138 Name 'WINALARM',
  W16_WinMessageBox Index 139 Name 'WINMESSAGEBOX',
  W16_WinCreateStdWindow Index 140 Name 'WINCREATESTDWINDOW',
  W16_WinCreateFrameControls Index 141 Name 'WINCREATEFRAMECONTROLS',
  WinFormatFrame Index 142 Name 'WinFormatFrame',
  W16_WinCalcFrameRect Index 143 Name 'WINCALCFRAMERECT',
  W16_WinFlashWindow Index 144 Name 'WINFLASHWINDOW',
  W16_WinGetMinPosition Index 146 Name 'WINGETMINPOSITION',
  W16_WinGetMaxPosition Index 147 Name 'WINGETMAXPOSITION',
  W16_WinQuerySysValue Index 149 Name 'WINQUERYSYSVALUE',
  W16_WinSetSysValue Index 150 Name 'WINSETSYSVALUE',
  W16_WinSetSysColors Index 151 Name 'WINSETSYSCOLORS',
  W16_WinQuerySysColor Index 152 Name 'WINQUERYSYSCOLOR',
  W16_WinScrollWindow Index 153 Name 'WINSCROLLWINDOW',
  W16_WinTrackRect Index 154 Name 'WINTRACKRECT',
  W16_WinShowTrackRect Index 155 Name 'WINSHOWTRACKRECT',
  GpiLoadBitmap Index 156 Name 'GpiLoadBitmap',
  W16_WinLoadString Index 157 Name 'WINLOADSTRING',
  W16_WinLoadMessage Index 158 Name 'WINLOADMESSAGE',
  W16_WinSetRectEmpty Index 159 Name 'WINSETRECTEMPTY',
  W16_WinSetRect Index 160 Name 'WINSETRECT',
  W16_WinCopyRect Index 161 Name 'WINCOPYRECT',
  W16_WinIsRectEmpty Index 162 Name 'WINISRECTEMPTY',
  W16_WinEqualRect Index 163 Name 'WINEQUALRECT',
  W16_WinPtInRect Index 164 Name 'WINPTINRECT',
  W16_WinOffsetRect Index 165 Name 'WINOFFSETRECT',
  W16_WinInflateRect Index 166 Name 'WININFLATERECT',
  W16_WinIntersectRect Index 167 Name 'WININTERSECTRECT',
  W16_WinUnionRect Index 168 Name 'WINUNIONRECT',
  W16_WinSubtractRect Index 169 Name 'WINSUBTRACTRECT',
  W16_WinMakeRect Index 170 Name 'WINMAKERECT',
  W16_WinMakePoints Index 171 Name 'WINMAKEPOINTS',
  W16_WinInvertRect Index 172 Name 'WININVERTRECT',
  W16_WinFillRect Index 173 Name 'WINFILLRECT',
  KbdPacket Index 174 Name 'KbdPacket',
  W16_WinDrawPointer Index 177 Name 'WINDRAWPOINTER',
  W16_WinDefWindowProc Index 178 Name 'WINDEFWINDOWPROC',
  W16_WinDefDlgProc Index 179 Name 'WINDEFDLGPROC',
  WinSyncStartPgm Index 197 Name 'WinSyncStartPgm',
  WinScreenSwitch Index 198 Name 'WinScreenSwitch',
  WinResetSystem Index 199 Name 'WinResetSystem',
  WinQueryHungProcess Index 200 Name 'WinQueryHungProcess',
  WinLoadStringTable Index 201 Name 'WinLoadStringTable',
  WinLoadVkeyGlyphXlatetbl Index 202 Name 'WinLoadVkeyGlyphXlatetbl',
  WinLoadCharXlatetbl Index 203 Name 'WinLoadCharXlatetbl',
  WinSetVkeyGlyphXlatetbl Index 204 Name 'WinSetVkeyGlyphXlatetbl',
  WinSetCharXlatetbl Index 205 Name 'WinSetCharXlatetbl',
  WinQueryVkeyGlyphXlatetbl Index 206 Name 'WinQueryVkeyGlyphXlatetbl',
  WinQueryCharXlatetbl Index 207 Name 'WinQueryCharXlatetbl',
  WinVkeyGlyphCharXlate Index 208 Name 'WinVkeyGlyphCharXlate',
  WinVkeyToScanId Index 209 Name 'WinVkeyToScanId',
  W16_WinQueryProcessCP Index 210 Name 'WINQUERYPROCESSCP',
  W16_WinGetKeyState Index 211 Name 'WINGETKEYSTATE',
  W16_WinGetPhysKeyState Index 212 Name 'WINGETPHYSKEYSTATE',
  W16_WinSetKeyboardStateTable Index 213 Name 'WINSETKEYBOARDSTATETABLE',
  W16_WinEnablePhysInput Index 214 Name 'WINENABLEPHYSINPUT',
  W16_WinSetCp Index 215 Name 'WINSETCP',
  W16_WinQueryCp Index 216 Name 'WINQUERYCP',
  W16_WinQueryCpList Index 217 Name 'WINQUERYCPLIST',
  W16_WinCpTranslateString Index 218 Name 'WINCPTRANSLATESTRING',
  W16_WinCpTranslateChar Index 219 Name 'WINCPTRANSLATECHAR',
  W16_WinCompareStrings Index 220 Name 'WINCOMPARESTRINGS',
  W16_WinUpper Index 221 Name 'WINUPPER',
  W16_WinUpperChar Index 222 Name 'WINUPPERCHAR',
  W16_WinNextChar Index 223 Name 'WINNEXTCHAR',
  W16_WinPrevChar Index 224 Name 'WINPREVCHAR',
  WinCreateHeap Index 225 Name 'WinCreateHeap',
  WinDestroyHeap Index 226 Name 'WinDestroyHeap',
  WinAvailMem Index 227 Name 'WinAvailMem',
  WinAllocMem Index 228 Name 'WinAllocMem',
  WinReallocMem Index 229 Name 'WinReallocMem',
  WinFreeMem Index 230 Name 'WinFreeMem',
  WinLockHeap Index 231 Name 'WinLockHeap',
  W16_WinCreateAtomTable Index 233 Name 'WINCREATEATOMTABLE',
  W16_WinDestroyAtomTable Index 234 Name 'WINDESTROYATOMTABLE',
  W16_WinAddAtom Index 235 Name 'WINADDATOM',
  W16_WinFindAtom Index 236 Name 'WINFINDATOM',
  W16_WinDeleteAtom Index 237 Name 'WINDELETEATOM',
  W16_WinQueryAtomUsage Index 238 Name 'WINQUERYATOMUSAGE',
  W16_WinQueryAtomLength Index 239 Name 'WINQUERYATOMLENGTH',
  W16_WinQueryAtomName Index 240 Name 'WINQUERYATOMNAME',
  W16_WinQuerySystemAtomTable Index 241 Name 'WINQUERYSYSTEMATOMTABLE',
  WinSetLastError Index 242 Name 'WinSetLastError',
  W16_WinGetLastError Index 243 Name 'WINGETLASTERROR',
  W16_WinGetErrorInfo Index 244 Name 'WINGETERRORINFO',
  W16_WinFreeErrorInfo Index 245 Name 'WINFREEERRORINFO',
  W16_WinInitialize Index 246 Name 'WININITIALIZE',
  W16_WinTerminate Index 247 Name 'WINTERMINATE',
  WinCatch Index 248 Name 'WinCatch',
  WinThrow Index 249 Name 'WinThrow',
  W16_WinQueryVersion Index 250 Name 'WINQUERYVERSION',
  FsrSemEnter Index 251 Name 'FsrSemEnter',
  FsrSemLeave Index 252 Name 'FsrSemLeave',
  FsrSemExit Index 253 Name 'FsrSemExit',
  FsrSemCheck Index 254 Name 'FsrSemCheck',
  AabAllocReg Index 255 Name 'AabAllocReg',
  AabGetReg Index 256 Name 'AabGetReg',
  AabSetReg Index 257 Name 'AabSetReg',
  ValidateSelector Index 258 Name 'ValidateSelector',
  LoadModuleHandle Index 259 Name 'LoadModuleHandle',
  GetScreenSelector Index 260 Name 'GetScreenSelector',
  IdentifyCodeSelector Index 261 Name 'IdentifyCodeSelector',
  WinQueryWindowSGId Index 262 Name 'WinQueryWindowSGId',
  XWinSetErrorInfo Index 263 Name '_WinSetErrorInfo',
  W16_WinIsPhysInputEnabled Index 264 Name 'WINISPHYSINPUTENABLED',
  W16_WinQueryWindowDC Index 265 Name 'WINQUERYWINDOWDC',
  W16_WinDrawBorder Index 266 Name 'WINDRAWBORDER',
  W16_WinDrawText Index 267 Name 'WINDRAWTEXT',
  W16_WinDrawBitmap Index 268 Name 'WINDRAWBITMAP',
  W16_WinQueryWindowPtr Index 269 Name 'WINQUERYWINDOWPTR',
  W16_WinSetWindowPtr Index 270 Name 'WINSETWINDOWPTR',
  WinInitializeSystem Index 271 Name 'WinInitializeSystem',
  WinTerminateSystem Index 272 Name 'WinTerminateSystem',
  WinLockStartInput Index 273 Name 'WinLockStartInput',
  W16_WinMsgSemWait Index 274 Name 'WINMSGSEMWAIT',
  W16_WinMsgMuxSemWait Index 275 Name 'WINMSGMUXSEMWAIT',
  W16_WinSystemShutdown Index 276 Name 'WINSYSTEMSHUTDOWN',
  W16_WinCancelShutdown Index 277 Name 'WINCANCELSHUTDOWN',
  W16_WinSetWindowBits Index 278 Name 'WINSETWINDOWBITS',
  W16_WinGetClipPS Index 279 Name 'WINGETCLIPPS',
  WinSendQueueMsg Index 281 Name 'WinSendQueueMsg',
  WinSetQueueProc Index 282 Name 'WinSetQueueProc',
  WinDefQueueProc Index 283 Name 'WinDefQueueProc',
  W16_WinSaveWindowPos Index 285 Name 'WINSAVEWINDOWPOS',
  W16_WinFocusChange Index 286 Name 'WINFOCUSCHANGE',
  W16_WinQueryQueueInfo Index 287 Name 'WINQUERYQUEUEINFO',
  WinCallHelpHook Index 288 Name 'WinCallHelpHook',
  WinSetAtomTableOwner Index 289 Name 'WinSetAtomTableOwner',
  WinIsShuttingDown Index 290 Name 'WinIsShuttingDown',
  WinTerminateShutdown Index 291 Name 'WinTerminateShutdown',
  W16_WinSetClassMsgInterest Index 292 Name 'WINSETCLASSMSGINTEREST',
  VisRegionCallback Index 293 Name 'VisRegionCallback',
  W16_WinQueryDlgItemTextLength Index 294 Name 'WINQUERYDLGITEMTEXTLENGTH',
  WinQueryKbdLayout Index 295 Name 'WinQueryKbdLayout',
  WinSetKbdLayout Index 296 Name 'WinSetKbdLayout',
  W16_WinDdeInitiate Index 297 Name 'WINDDEINITIATE',
  W16_WinDdeRespond Index 298 Name 'WINDDERESPOND',
  W16_WinDdePostMsg Index 299 Name 'WINDDEPOSTMSG',
  WinCancelMode Index 300 Name 'WinCancelMode',
  W16_WinSetPresParam Index 301 Name 'WINSETPRESPARAM',
  W16_WinQueryPresParam Index 302 Name 'WINQUERYPRESPARAM',
  W16_WinRemovePresParam Index 303 Name 'WINREMOVEPRESPARAM',
  W16_WinThreadAssocQueue Index 304 Name 'WINTHREADASSOCQUEUE',
  W16_WinQueueFromId Index 305 Name 'WINQUEUEFROMID',
  W16_WinQuerySendMsg Index 306 Name 'WINQUERYSENDMSG',
  W16_WinReplyMsg Index 307 Name 'WINREPLYMSG',
  W16_WinWakeThread Index 308 Name 'WINWAKETHREAD',
  W16_WinLockInput Index 309 Name 'WINLOCKINPUT',
  W16_WinBuildPtrHandle Index 310 Name 'WINBUILDPTRHANDLE',
  WinCreateHelpInstance Index 311 Name 'WinCreateHelpInstance',
  WinDestroyHelpInstance Index 312 Name 'WinDestroyHelpInstance',
  WinAssociateHelpInstance Index 313 Name 'WinAssociateHelpInstance',
  WinCreateHelpTable Index 314 Name 'WinCreateHelpTable',
  WinLoadHelpTable Index 315 Name 'WinLoadHelpTable',
  WinQueryHelpInstance Index 316 Name 'WinQueryHelpInstance',
  W16_WinQueryWindowModel Index 317 Name 'WINQUERYWINDOWMODEL',
  W16_WinSetDesktopBkgnd Index 318 Name 'WINSETDESKTOPBKGND',
  W16_WinQueryDesktopBkgnd Index 319 Name 'WINQUERYDESKTOPBKGND',
  W16_WinPopupMenu Index 320 Name 'WINPOPUPMENU',
  W16_WinRealizePalette Index 321 Name 'WINREALIZEPALETTE',
  DummyHelpEntry Index 322 Name 'DummyHelpEntry',
  GetPMDDCodeSelector Index 325 Name 'GetPMDDCodeSelector',
  W16_WinSemEnter Index 326 Name 'WINSEMENTER',
  W16_WinSemLeave Index 327 Name 'WINSEMLEAVE',
  WinQueryPwnd Index 328 Name 'WinQueryPwnd',
  WinQueryState Index 329 Name 'WinQueryState',
  WinLoadAniPointer Index 330 Name 'WinLoadAniPointer',
  WinDestroyAniPointer Index 331 Name 'WinDestroyAniPointer',
  WinSetAniPointer Index 332 Name 'WinSetAniPointer',
  WinEnumVKeyScanIDs Index 333 Name 'WinEnumVKeyScanIDs',
  W16_WinSemQuery Index 334 Name 'WINSEMQUERY',
  WinLoadTranslationTable Index 400 Name 'WinLoadTranslationTable',
  WinSetKbdLayout2 Index 401 Name 'WinSetKbdLayout2',
  WinSeamlessBox Index 495 Name 'WinSeamlessBox',
  WinIsWindowOverlapped Index 496 Name 'WinIsWindowOverlapped',
  WinJiggleMouse Index 497 Name 'WinJiggleMouse',
  WinTrackSeamless Index 498 Name 'WinTrackSeamless',
  WinRegisterSeamlessProc Index 499 Name 'WinRegisterSeamlessProc',
  AbnormalProcessExit Index 500 Name 'AbnormalProcessExit',
  WinProfControl Index 508 Name 'WinProfControl',
  DebugInputEnable Index 509 Name 'DebugInputEnable',
  DebugInput Index 510 Name 'DebugInput',
  DebugOutput Index 511 Name 'DebugOutput',
  DebugCurPos Index 512 Name 'DebugCurPos',
  DebugCls Index 513 Name 'DebugCls',
  WinDebugBreak Index 514 Name 'WinDebugBreak',
  DebugRedirect Index 515 Name 'DebugRedirect',
  InputGetDeviceInfo Index 590 Name 'InputGetDeviceInfo',
  StartTimer Index 600 Name 'StartTimer',
  DestroyTimers Index 601 Name 'DestroyTimers',
  W16_WinDeleteLibrary Index 602 Name 'WINDELETELIBRARY',
  W16_WinLoadProcedure Index 603 Name 'WINLOADPROCEDURE',
  W16_WinDeleteProcedure Index 604 Name 'WINDELETEPROCEDURE',
  W16_WinSetMsgMode Index 605 Name 'WINSETMSGMODE',
  W16_WinSetSynchroMode Index 606 Name 'WINSETSYNCHROMODE',
  W16_WinGetDlgMsg Index 607 Name 'WINGETDLGMSG',
  W16_WinRegisterUserMsg Index 608 Name 'WINREGISTERUSERMSG',
  W16_WinQueryAnchorBlock Index 609 Name 'WINQUERYANCHORBLOCK',
  WinLangsupWindowProc Index 610 Name 'WinLangsupWindowProc',
  WinLangsupDlgProc Index 611 Name 'WinLangsupDlgProc',
  W16_WinRegisterUserDatatype Index 612 Name 'WINREGISTERUSERDATATYPE',
  FarCallHook Index 613 Name 'FarCallHook',
  W16_WinIsWindowShowing Index 614 Name 'WINISWINDOWSHOWING',
  W16_WinLoadLibrary Index 615 Name 'WINLOADLIBRARY',
  W16_WinCreatePointerIndirect Index 616 Name 'WINCREATEPOINTERINDIRECT',
  W16_WinQueryPointerInfo Index 617 Name 'WINQUERYPOINTERINFO',
  WinSetMenuData Index 618 Name 'WinSetMenuData',
  WinQueryMenuData Index 619 Name 'WinQueryMenuData',
  WinMenuIndexFromID Index 620 Name 'WinMenuIndexFromID',
  WinForceMenuRedraw Index 621 Name 'WinForceMenuRedraw',
  WinGetScanState Index 622 Name 'WinGetScanState',
  WinSetScanStateTable Index 623 Name 'WinSetScanStateTable',
  W16_WinGetErasePS Index 624 Name 'WINGETERASEPS',
  W16_WinReleaseErasePS Index 625 Name 'WINRELEASEERASEPS',
  WinSetWindowDC Index 626 Name 'WinSetWindowDC',
  WinTranslateChar Index 627 Name 'WinTranslateChar',
  WinPortHoleUtil Index 628 Name 'WinPortHoleUtil',
  W16_WinExplodeWindow Index 629 Name 'WINEXPLODEWINDOW',
  W16_WinSetAccelTableValue Index 630 Name 'WINSETACCELTABLEVALUE',
  W16_WinQueryAccelTableValue Index 631 Name 'WINQUERYACCELTABLEVALUE',
  W16_WinStretchPointer Index 632 Name 'WINSTRETCHPOINTER',
  W16_WinSetPointerOwner Index 633 Name 'WINSETPOINTEROWNER',
  W16_WinGetFrameTreePPSize Index 634 Name 'WINGETFRAMETREEPPSIZE',
  W16_WinGetFrameTreePPs Index 635 Name 'WINGETFRAMETREEPPS',
  W16_WinSetFrameTreePPs Index 636 Name 'WINSETFRAMETREEPPS',
  WinGetMinWindowViewer Index 637 Name 'WinGetMinWindowViewer',
  WinLockPointerUpdate Index 639 Name 'WinLockPointerUpdate',
  WinCheckInput Index 640 Name 'WinCheckInput',
  WinAddAtom Index 700 Name 'WinAddAtom',
  WinAlarm Index 701 Name 'WinAlarm',
  WinBeginEnumWindows Index 702 Name 'WinBeginEnumWindows',
  WinBeginPaint Index 703 Name 'WinBeginPaint',
  WinCalcFrameRect Index 704 Name 'WinCalcFrameRect',
  WinCancelShutdown Index 705 Name 'WinCancelShutdown',
  WinCloseClipbrd Index 707 Name 'WinCloseClipbrd',
  WinCompareStrings Index 708 Name 'WinCompareStrings',
  WinCopyAccelTable Index 709 Name 'WinCopyAccelTable',
  WinCopyRect Index 710 Name 'WinCopyRect',
  WinCpTranslateChar Index 711 Name 'WinCpTranslateChar',
  WinCpTranslateString Index 712 Name 'WinCpTranslateString',
  WinCreateAccelTable Index 713 Name 'WinCreateAccelTable',
  WinCreateAtomTable Index 714 Name 'WinCreateAtomTable',
  WinCreateCursor Index 715 Name 'WinCreateCursor',
  WinCreateMsgQueue Index 716 Name 'WinCreateMsgQueue',
  WinCreatePointer Index 717 Name 'WinCreatePointer',
  WinDdeInitiate Index 718 Name 'WinDdeInitiate',
  WinDdePostMsg Index 719 Name 'WinDdePostMsg',
  WinDdeRespond Index 720 Name 'WinDdeRespond',
  WinDeleteAtom Index 721 Name 'WinDeleteAtom',
  WinDeleteLibrary Index 722 Name 'WinDeleteLibrary',
  WinDestroyAccelTable Index 723 Name 'WinDestroyAccelTable',
  WinDestroyAtomTable Index 724 Name 'WinDestroyAtomTable',
  WinDestroyCursor Index 725 Name 'WinDestroyCursor',
  WinDestroyMsgQueue Index 726 Name 'WinDestroyMsgQueue',
  WinDestroyPointer Index 727 Name 'WinDestroyPointer',
  WinDestroyWindow Index 728 Name 'WinDestroyWindow',
  WinDismissDlg Index 729 Name 'WinDismissDlg',
  WinDrawBitmap Index 730 Name 'WinDrawBitmap',
  WinDrawBorder Index 731 Name 'WinDrawBorder',
  WinDrawPointer Index 732 Name 'WinDrawPointer',
  WinEmptyClipbrd Index 733 Name 'WinEmptyClipbrd',
  WinEnablePhysInput Index 734 Name 'WinEnablePhysInput',
  WinEnableWindow Index 735 Name 'WinEnableWindow',
  WinEnableWindowUpdate Index 736 Name 'WinEnableWindowUpdate',
  WinEndEnumWindows Index 737 Name 'WinEndEnumWindows',
  WinEndPaint Index 738 Name 'WinEndPaint',
  WinEnumClipbrdFmts Index 739 Name 'WinEnumClipbrdFmts',
  WinEnumDlgItem Index 740 Name 'WinEnumDlgItem',
  WinEqualRect Index 741 Name 'WinEqualRect',
  WinExcludeUpdateRegion Index 742 Name 'WinExcludeUpdateRegion',
  WinFillRect Index 743 Name 'WinFillRect',
  WinFindAtom Index 744 Name 'WinFindAtom',
  WinFlashWindow Index 745 Name 'WinFlashWindow',
  WinFocusChange Index 746 Name 'WinFocusChange',
  WinFreeErrorInfo Index 748 Name 'WinFreeErrorInfo',
  WinGetClipPS Index 749 Name 'WinGetClipPS',
  WinGetCurrentTime Index 750 Name 'WinGetCurrentTime',
  WinGetErrorInfo Index 751 Name 'WinGetErrorInfo',
  WinGetKeyState Index 752 Name 'WinGetKeyState',
  WinGetLastError Index 753 Name 'WinGetLastError',
  WinGetMaxPosition Index 754 Name 'WinGetMaxPosition',
  WinGetMinPosition Index 755 Name 'WinGetMinPosition',
  WinGetNextWindow Index 756 Name 'WinGetNextWindow',
  WinGetPS Index 757 Name 'WinGetPS',
  WinGetPhysKeyState Index 758 Name 'WinGetPhysKeyState',
  WinGetScreenPS Index 759 Name 'WinGetScreenPS',
  WinGetSysBitmap Index 760 Name 'WinGetSysBitmap',
  WinInSendMsg Index 761 Name 'WinInSendMsg',
  WinInflateRect Index 762 Name 'WinInflateRect',
  WinInitialize Index 763 Name 'WinInitialize',
  WinIntersectRect Index 764 Name 'WinIntersectRect',
  WinInvalidateRect Index 765 Name 'WinInvalidateRect',
  WinInvalidateRegion Index 766 Name 'WinInvalidateRegion',
  WinInvertRect Index 767 Name 'WinInvertRect',
  WinIsChild Index 768 Name 'WinIsChild',
  WinIsPhysInputEnabled Index 769 Name 'WinIsPhysInputEnabled',
  WinIsRectEmpty Index 770 Name 'WinIsRectEmpty',
  WinIsThreadActive Index 771 Name 'WinIsThreadActive',
  WinIsWindow Index 772 Name 'WinIsWindow',
  WinIsWindowEnabled Index 773 Name 'WinIsWindowEnabled',
  WinIsWindowShowing Index 774 Name 'WinIsWindowShowing',
  WinIsWindowVisible Index 775 Name 'WinIsWindowVisible',
  WinLoadAccelTable Index 776 Name 'WinLoadAccelTable',
  WinLoadLibrary Index 777 Name 'WinLoadLibrary',
  WinLoadMenu Index 778 Name 'WinLoadMenu',
  WinLoadMessage Index 779 Name 'WinLoadMessage',
  WinLoadPointer Index 780 Name 'WinLoadPointer',
  WinLoadString Index 781 Name 'WinLoadString',
  WinLockVisRegions Index 782 Name 'WinLockVisRegions',
  WinLockWindowUpdate Index 784 Name 'WinLockWindowUpdate',
  WinMakePoints Index 785 Name 'WinMakePoints',
  WinMakeRect Index 786 Name 'WinMakeRect',
  WinMapDlgPoints Index 787 Name 'WinMapDlgPoints',
  WinMapWindowPoints Index 788 Name 'WinMapWindowPoints',
  WinMessageBox Index 789 Name 'WinMessageBox',
  WinMsgSemWait Index 790 Name 'WinMsgSemWait',
  WinNextChar Index 791 Name 'WinNextChar',
  WinOffsetRect Index 792 Name 'WinOffsetRect',
  WinOpenClipbrd Index 793 Name 'WinOpenClipbrd',
  WinOpenWindowDC Index 794 Name 'WinOpenWindowDC',
  WinPrevChar Index 795 Name 'WinPrevChar',
  WinProcessDlg Index 796 Name 'WinProcessDlg',
  WinPtInRect Index 797 Name 'WinPtInRect',
  WinQueryAccelTable Index 798 Name 'WinQueryAccelTable',
  WinQueryActiveWindow Index 799 Name 'WinQueryActiveWindow',
  WinQueryAnchorBlock Index 800 Name 'WinQueryAnchorBlock',
  WinQueryAtomLength Index 801 Name 'WinQueryAtomLength',
  WinQueryAtomName Index 802 Name 'WinQueryAtomName',
  WinQueryAtomUsage Index 803 Name 'WinQueryAtomUsage',
  WinQueryCapture Index 804 Name 'WinQueryCapture',
  WinQueryClassName Index 805 Name 'WinQueryClassName',
  WinQueryClipbrdData Index 806 Name 'WinQueryClipbrdData',
  WinQueryClipbrdFmtInfo Index 807 Name 'WinQueryClipbrdFmtInfo',
  WinQueryClipbrdOwner Index 808 Name 'WinQueryClipbrdOwner',
  WinQueryClipbrdViewer Index 809 Name 'WinQueryClipbrdViewer',
  WinQueryCp Index 810 Name 'WinQueryCp',
  WinQueryCpList Index 811 Name 'WinQueryCpList',
  WinQueryCursorInfo Index 812 Name 'WinQueryCursorInfo',
  WinQueryDesktopWindow Index 813 Name 'WinQueryDesktopWindow',
  WinQueryDlgItemShort Index 814 Name 'WinQueryDlgItemShort',
  WinQueryDlgItemText Index 815 Name 'WinQueryDlgItemText',
  WinQueryDlgItemTextLength Index 816 Name 'WinQueryDlgItemTextLength',
  WinQueryFocus Index 817 Name 'WinQueryFocus',
  WinQueryMsgPos Index 818 Name 'WinQueryMsgPos',
  WinQueryMsgTime Index 819 Name 'WinQueryMsgTime',
  WinQueryObjectWindow Index 820 Name 'WinQueryObjectWindow',
  WinQueryPointer Index 821 Name 'WinQueryPointer',
  WinQueryPointerInfo Index 822 Name 'WinQueryPointerInfo',
  WinQueryPointerPos Index 823 Name 'WinQueryPointerPos',
  WinQueryQueueInfo Index 824 Name 'WinQueryQueueInfo',
  WinQueryQueueStatus Index 825 Name 'WinQueryQueueStatus',
  WinQuerySysColor Index 826 Name 'WinQuerySysColor',
  WinQuerySysModalWindow Index 827 Name 'WinQuerySysModalWindow',
  WinQuerySysPointer Index 828 Name 'WinQuerySysPointer',
  WinQuerySysValue Index 829 Name 'WinQuerySysValue',
  WinQuerySystemAtomTable Index 830 Name 'WinQuerySystemAtomTable',
  WinQueryUpdateRect Index 831 Name 'WinQueryUpdateRect',
  WinQueryUpdateRegion Index 832 Name 'WinQueryUpdateRegion',
  WinQueryVersion Index 833 Name 'WinQueryVersion',
  WinQueryWindow Index 834 Name 'WinQueryWindow',
  WinQueryWindowDC Index 835 Name 'WinQueryWindowDC',
  WinQueryWindowPos Index 837 Name 'WinQueryWindowPos',
  WinQueryWindowProcess Index 838 Name 'WinQueryWindowProcess',
  WinQueryWindowPtr Index 839 Name 'WinQueryWindowPtr',
  WinQueryWindowRect Index 840 Name 'WinQueryWindowRect',
  WinQueryWindowText Index 841 Name 'WinQueryWindowText',
  WinQueryWindowTextLength Index 842 Name 'WinQueryWindowTextLength',
  WinQueryWindowULong Index 843 Name 'WinQueryWindowULong',
  WinQueryWindowUShort Index 844 Name 'WinQueryWindowUShort',
  WinRegisterUserDatatype Index 845 Name 'WinRegisterUserDatatype',
  WinRegisterUserMsg Index 846 Name 'WinRegisterUserMsg',
  WinReleasePS Index 848 Name 'WinReleasePS',
  WinScrollWindow Index 849 Name 'WinScrollWindow',
  WinSetAccelTable Index 850 Name 'WinSetAccelTable',
  WinSetActiveWindow Index 851 Name 'WinSetActiveWindow',
  WinSetCapture Index 852 Name 'WinSetCapture',
  WinSetClassMsgInterest Index 853 Name 'WinSetClassMsgInterest',
  WinSetClipbrdData Index 854 Name 'WinSetClipbrdData',
  WinSetClipbrdOwner Index 855 Name 'WinSetClipbrdOwner',
  WinSetClipbrdViewer Index 856 Name 'WinSetClipbrdViewer',
  WinSetCp Index 857 Name 'WinSetCp',
  WinSetDlgItemShort Index 858 Name 'WinSetDlgItemShort',
  WinSetDlgItemText Index 859 Name 'WinSetDlgItemText',
  WinSetFocus Index 860 Name 'WinSetFocus',
  WinSetMsgInterest Index 861 Name 'WinSetMsgInterest',
  WinSetMsgMode Index 862 Name 'WinSetMsgMode',
  WinSetMultWindowPos Index 863 Name 'WinSetMultWindowPos',
  WinSetOwner Index 864 Name 'WinSetOwner',
  WinSetParent Index 865 Name 'WinSetParent',
  WinSetPointer Index 866 Name 'WinSetPointer',
  WinSetPointerPos Index 867 Name 'WinSetPointerPos',
  WinSetRect Index 868 Name 'WinSetRect',
  WinSetRectEmpty Index 869 Name 'WinSetRectEmpty',
  WinSetSynchroMode Index 870 Name 'WinSetSynchroMode',
  WinSetSysColors Index 871 Name 'WinSetSysColors',
  WinSetSysModalWindow Index 872 Name 'WinSetSysModalWindow',
  WinSetSysValue Index 873 Name 'WinSetSysValue',
  WinSetWindowBits Index 874 Name 'WinSetWindowBits',
  WinSetWindowPos Index 875 Name 'WinSetWindowPos',
  WinSetWindowPtr Index 876 Name 'WinSetWindowPtr',
  WinSetWindowText Index 877 Name 'WinSetWindowText',
  WinSetWindowULong Index 878 Name 'WinSetWindowULong',
  WinSetWindowUShort Index 879 Name 'WinSetWindowUShort',
  WinShowCursor Index 880 Name 'WinShowCursor',
  WinShowPointer Index 881 Name 'WinShowPointer',
  WinShowTrackRect Index 882 Name 'WinShowTrackRect',
  WinShowWindow Index 883 Name 'WinShowWindow',
  WinStartTimer Index 884 Name 'WinStartTimer',
  WinStopTimer Index 885 Name 'WinStopTimer',
  WinSubstituteStrings Index 886 Name 'WinSubstituteStrings',
  WinSubtractRect Index 887 Name 'WinSubtractRect',
  WinTerminate Index 888 Name 'WinTerminate',
  WinTrackRect Index 890 Name 'WinTrackRect',
  WinUnionRect Index 891 Name 'WinUnionRect',
  WinUpdateWindow Index 892 Name 'WinUpdateWindow',
  WinUpper Index 893 Name 'WinUpper',
  WinUpperChar Index 894 Name 'WinUpperChar',
  WinValidateRect Index 895 Name 'WinValidateRect',
  WinValidateRegion Index 896 Name 'WinValidateRegion',
  WinWaitMsg Index 897 Name 'WinWaitMsg',
  WinWindowFromDC Index 898 Name 'WinWindowFromDC',
  WinWindowFromID Index 899 Name 'WinWindowFromID',
  WinWindowFromPoint Index 900 Name 'WinWindowFromPoint',
  WinBroadcastMsg Index 901 Name 'WinBroadcastMsg',
  WinPostQueueMsg Index 902 Name 'WinPostQueueMsg',
  WinSendDlgItemMsg Index 903 Name 'WinSendDlgItemMsg',
  WinTranslateAccel Index 904 Name 'WinTranslateAccel',
  WinCallMsgFilter Index 905 Name 'WinCallMsgFilter',
  WinCreateFrameControls Index 906 Name 'WinCreateFrameControls',
  WinCreateMenu Index 907 Name 'WinCreateMenu',
  WinCreateStdWindow Index 908 Name 'WinCreateStdWindow',
  WinCreateWindow Index 909 Name 'WinCreateWindow',
  WinDefDlgProc Index 910 Name 'WinDefDlgProc',
  WinDefWindowProc Index 911 Name 'WinDefWindowProc',
  WinDispatchMsg Index 912 Name 'WinDispatchMsg',
  WinDrawText Index 913 Name 'WinDrawText',
  WinGetDlgMsg Index 914 Name 'WinGetDlgMsg',
  WinGetMsg Index 915 Name 'WinGetMsg',
  WinMsgMuxSemWait Index 916 Name 'WinMsgMuxSemWait',
  WinMultWindowFromIDs Index 917 Name 'WinMultWindowFromIDs',
  WinPeekMsg Index 918 Name 'WinPeekMsg',
  WinPostMsg Index 919 Name 'WinPostMsg',
  WinSendMsg Index 920 Name 'WinSendMsg',
  WinSetKeyboardStateTable Index 921 Name 'WinSetKeyboardStateTable',
  WinCreateDlg Index 922 Name 'WinCreateDlg',
  WinDlgBox Index 923 Name 'WinDlgBox',
  WinLoadDlg Index 924 Name 'WinLoadDlg',
  WinQueryClassInfo Index 925 Name 'WinQueryClassInfo',
  WinRegisterClass Index 926 Name 'WinRegisterClass',
  WinReleaseHook Index 927 Name 'WinReleaseHook',
  WinSetHook Index 928 Name 'WinSetHook',
  WinSubclassWindow Index 929 Name 'WinSubclassWindow',
  W16_WinSetClassThunkProc Index 930 Name 'WINSETCLASSTHUNKPROC',
  W16_WinQueryClassThunkProc Index 931 Name 'WINQUERYCLASSTHUNKPROC',
  W16_WinSetWindowThunkProc Index 932 Name 'WINSETWINDOWTHUNKPROC',
  W16_WinQueryWindowThunkProc Index 933 Name 'WINQUERYWINDOWTHUNKPROC',
  WinQueryWindowModel Index 934 Name 'WinQueryWindowModel',
  WinSetDesktopBkgnd Index 935 Name 'WinSetDesktopBkgnd',
  WinQueryDesktopBkgnd Index 936 Name 'WinQueryDesktopBkgnd',
  WinPopupMenu Index 937 Name 'WinPopupMenu',
  WinSetPresParam Index 938 Name 'WinSetPresParam',
  WinQueryPresParam Index 939 Name 'WinQueryPresParam',
  WinRemovePresParam Index 940 Name 'WinRemovePresParam',
  WinRealizePalette Index 941 Name 'WinRealizePalette',
  WinCreatePointerIndirect Index 942 Name 'WinCreatePointerIndirect',
  WinSaveWindowPos Index 943 Name 'WinSaveWindowPos',
  WinCreateFarHeap Index 947 Name 'WinCreateFarHeap',
  WinDestoryFarHeap Index 948 Name 'WinDestoryFarHeap',
  WinAllocFarMem Index 949 Name 'WinAllocFarMem',
  WinFreeFarMem Index 950 Name 'WinFreeFarMem',
  WinReallocFarMem Index 951 Name 'WinReallocFarMem',
  WinGetErasePS Index 952 Name 'WinGetErasePS',
  WinReleaseErasePS Index 953 Name 'WinReleaseErasePS',
  DEBUG32INPUT Index 954 Name 'DEBUG32INPUT',
  DEBUG32OUTPUT Index 955 Name 'DEBUG32OUTPUT',
  DEBUG32CURPOS Index 956 Name 'DEBUG32CURPOS',
  DEBUG32CLS Index 957 Name 'DEBUG32CLS',
  WIN32DEBUGBREAK Index 958 Name 'WIN32DEBUGBREAK',
  WinSetClassThunkProc Index 959 Name 'WinSetClassThunkProc',
  WinQueryClassThunkProc Index 960 Name 'WinQueryClassThunkProc',
  WinSetWindowThunkProc Index 961 Name 'WinSetWindowThunkProc',
  WinQueryWindowThunkProc Index 962 Name 'WinQueryWindowThunkProc',
  WinSystemShutdown Index 963 Name 'WinSystemShutdown',
  WinBuildPtrHandle Index 964 Name 'WinBuildPtrHandle',
  WinExplodeWindow Index 965 Name 'WinExplodeWindow',
  WinSetAccelTableValue Index 966 Name 'WinSetAccelTableValue',
  WinQueryAccelTableValue Index 967 Name 'WinQueryAccelTableValue',
  WinStretchPointer Index 968 Name 'WinStretchPointer',
  AAB32GETREG Index 969 Name 'AAB32GETREG',
  AAB32SETREG Index 970 Name 'AAB32SETREG',
  WinSetPointerOwner Index 971 Name 'WinSetPointerOwner',
  WinGetFrameTreePPSize Index 972 Name 'WinGetFrameTreePPSize',
  WinGetFrameTreePPs Index 973 Name 'WinGetFrameTreePPs',
  WinSetFrameTreePPs Index 974 Name 'WinSetFrameTreePPs',
  WinQueryProcessCP Index 975 Name 'WinQueryProcessCP',
  WinVisRegionNotify Index 976 Name 'WinVisRegionNotify',
  WinSetErrorInfo Index 977 Name 'WinSetErrorInfo',
  WinWaitEventSem Index 978 Name 'WinWaitEventSem',
  WinRequestMutexSem Index 979 Name 'WinRequestMutexSem',
  WinWaitMuxWaitSem Index 980 Name 'WinWaitMuxWaitSem',
  W16_WinSetSysClipbrdViewer Index 981 Name 'WINSETSYSCLIPBRDVIEWER',
  WinSetSysClipbrdViewer Index 982 Name 'WinSetSysClipbrdViewer',
  WinSemQuery Index 983 Name 'WinSemQuery',
  WinSemEnter Index 984 Name 'WinSemEnter',
  WinSemLeave Index 985 Name 'WinSemLeave',
  WinLoadProcedure Index 986 Name 'WinLoadProcedure',
  WinDeleteProcedure Index 987 Name 'WinDeleteProcedure',
  WinMoveCursor Index 988 Name 'WinMoveCursor',
  WinQuerySendMsg Index 990 Name 'WinQuerySendMsg',
  WinReplyMsg Index 991 Name 'WinReplyMsg',
  WinWakeThread Index 992 Name 'WinWakeThread',
  WinQueueFromId Index 993 Name 'WinQueueFromId',
  WinThreadAssocQueue Index 994 Name 'WinThreadAssocQueue',
  WinLockInput Index 995 Name 'WinLockInput',
  WinSetSysFont Index 996 Name 'WinSetSysFont',
  WinSysClassProc Index 1000 Name 'WINSYSCLASSPROC',
  WinQueryPSInfo Index 1001 Name 'WINQUERYPSINFO',
  WinQueryScreenText Index 1002 Name 'WINQUERYSCREENTEXT',
  WinHideOverlays Index 1003 Name 'WINHIDEOVERLAYS',
  WinSuspendScreen Index 1004 Name 'WINSUSPENDSCREEN',
  WinResumeScreen Index 1005 Name 'WINRESUMESCREEN',
  WinQueryScreenTaken Index 1006 Name 'WINQUERYSCREENTAKEN';

Var
  InitI : LongInt;

BEGIN
  HwBit := $80000000;
  GMode := 0;
  GMetrics;
  HeapInitIn(LongInt(@Arena), ArenaSize);
  For InitI := 0 To MaxWin - 1 Do
  Begin
    WUse[InitI] := 0; WGen[InitI] := 0; WCls[InitI] := -1;
  End;
  { bureau (rang 0) et fenetre objet (rang 1) }
  WUse[0] := 1; WGen[0] := 1; WStyle[0] := WS_VISIBLE; WCX[0] := ScrCX; WCY[0] := ScrCY;
  WUse[1] := 1; WGen[1] := 1;
  WHmq[0] := -1; WHmq[1] := -1;
  For InitI := 0 To MaxItem - 1 Do ItWin[InitI] := 0;
  For InitI := 0 To MaxPP - 1 Do PpWin[InitI] := 0;
  PhysInput := 1;
  SysValDefaults;
  SysClrDefaults;
  AtbUse[0] := 1;
  MyMod := 0;
  InitDone := 0;
  EnsureInit;
END.
