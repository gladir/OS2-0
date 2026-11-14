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
  Liste des fenetres, Modeles, Broyeur, Arret et Fenetre OS/2, puis le contenu du
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
  Fenetre OS/2 : COMSPEC dans une nouvelle session montree dans une
  fenetre du bureau par PMVIOP.DLL (bouclier VIO : l'ecran de la session
  y est redessine, le clavier y est envoye ; bouton 2 : Marquer, Copier,
  Tout copier, Coller, Plein ecran, Fermer).
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

  Parametres du systeme (Systeme OS/2, Configuration du systeme :
  Systeme, Souris, Couleurs du bureau ; menu du bureau : Parametres du
  systeme...) : carnet a onglets "Systeme - Parametres" : Ecran
  (resolution : modes VGA et VESA de la carte, appliquee tout de suite
  par WINSETSCREENMODE de PMWIN, puis gardee si elle est confirmee :
  OS2.INI, PM_Display, RESOLUTION = LxHxB ; Capacites : BIOS VESA),
  Confirmations (suppression d'un dossier, d'un fichier, arret), Titre
  (objet de meme nom : numero ou avertissement), Fenetre (objet deja
  ouvert : fenetre existante ou nouvelle), Entree (delai du double clic,
  boutons inverses), Logo (au demarrage), General (couleur du bureau).
  Les reglages sont dans OS2.INI (application PMSHELL).
  Carnet "Souris - Parametres" (objet Souris) : Minutage (curseurs du
  double clic, avec zone d'essai, et de la vitesse de deplacement :
  MouSetScaleFact, MouSetThreshold), Configuration (droitier, gaucher),
  Affectations (liste des fenetres : bouton 3 ou double clic du bouton 1
  sur le bureau ; menus : bouton 2 ou Maj + bouton 1 ; glisser : bouton
  2 ou bouton 1), Pointeurs (taille, couleurs : WINSETPOINTERSTYLE de
  PMWIN), Comete (pointeur comete), General (titre). Un seul carnet de
  parametres est ouvert a la fois.

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
  WM_SYSVALUECHANGED = $002D;
  KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40; KC_CHAR = 1;
  VK_BACKSPACE = 5; VK_NEWLINE = 8; VK_ESC = $0F; VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13;
  VK_HOME = $14; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_DELETE = $1B;
  VK_ENTER = $1E; VK_F1 = $20; VK_F5 = $24; VK_F10 = $29;
  { couleurs }
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  { vues et objets }
  CW = 112; CH = 80;
  VK_DESK = 0; VK_SYS = 1; VK_DRIVES = 2; VK_DIR = 3; VK_VIEWER = 4; VK_LIST = 5;
  IC_FOLDER = 0; IC_SYSTEM = 1; IC_DRIVES = 2; IC_PROGRAM = 3; IC_CMD = 4; IC_BATCH = 5; IC_FILE = 6;
  IC_CDROM = 7; IC_DISK = 8; IC_SHUTDOWN = 9; IC_WINLIST = 10; IC_INFO = 11; IC_HELP = 12;
  IC_TEMPL = 13; IC_SHRED = 14; IC_SETUP = 15; IC_SCREEN = 16; IC_MOUSE = 17; IC_PALETTE = 18;
  OB_SYS = 1; OB_DRIVES = 2; OB_CMD = 3; OB_SHUTDOWN = 4; OB_WINLIST = 5; OB_INFO = 6; OB_HELP = 7;
  OB_DIR = 8; OB_EXE = 9; OB_BATCH = 10; OB_DATA = 11; OB_TEMPLATES = 12; OB_SHRED = 13;
  OB_TPLDIR = 14; OB_TPLDATA = 15; OB_TPLCMD = 16; OB_SETUP = 17; OB_SYSSET = 18; OB_MOUSE = 19; OB_COLORS = 20;
  OB_CMDWIN = 21; OB_LANG = 22; IC_LANG = 19; OB_COUNTRY = 23; IC_GLOBE = 20;
  OB_GAMES = 24; OB_GAME = 25; IC_CARDS = 21; IC_CHESS = 22; IC_TILES = 23;
  OB_MMFOLDER = 26; OB_SOUND = 27; IC_AUDIO = 24; IC_WAVE = 25; IC_HARDWARE = 26;
  OB_DOSFS = 28; OB_DOSWIN = 29;
  WC_COMBOBOX = $FFFF0002; CBS_DROPDOWNLIST = 4;
  VK_TEMPL = 6; VK_SETUP = 7; VK_NOTE = 8; VK_GAMES = 9; VK_MM = 10;
  { controles du carnet des parametres }
  WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005;
  BS_PUSHBUTTON = 0; BS_AUTOCHECKBOX = 2; BS_AUTORADIOBUTTON = 4; SS_TEXT = 1; SS_GROUPBOX = 2;
  WS_GROUP = $00010000; WS_TABSTOP = $00020000;
  BM_QUERYCHECK = $0124; BM_SETCHECK = $0125; BN_CLICKED = 1; LN_SELECT = 1;
  SV_SWAPBUTTON = 0; SV_DBLCLKTIME = 1;
  NbTabs = 8;              { carnet Systeme ; carnet Souris : 6 onglets }
  WC_ENTRYFIELD = $FFFF0006; ES_AUTOSCROLL = 4; ES_MARGIN = 8; WM_BUTTON3CLICK = $0419;
  ShadowApp = 'PMSHELL_RACCOURCIS';
  { commandes des menus }
  CM_OPEN = 100; CM_REFRESH = 101; CM_ARRANGE = 102; CM_WINLIST = 103; CM_INFO = 104; CM_SHUTDOWN = 105;
  CM_HELP = 106; CM_PROPS = 107; CM_DELETE = 108; CM_CLOSE = 109; CM_PARENT = 110; CM_CMDHERE = 111;
  CM_SHADOW = 112; CM_CREATE = 113; CM_SETTINGS = 114;

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
  ShieldOk : LongInt;
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
  { parametres du systeme (OS2.INI, application PMSHELL) }
  DeskColor : LongInt;                     { couleur du fond du bureau (RVB) }
  CfgConf : Array[0..2] Of LongInt;        { confirmer : dossier, objet, arret }
  CfgTitle, CfgWin, CfgLogo, CfgDbl, CfgSwap, CfgClr : LongInt;
  { souris : vitesse (0 a 8), correspondances, pointeur, comete }
  CfgSpeed, CfgMapList, CfgMapMenu, CfgMapDrag, CfgPtrBig, CfgPtrInv, CfgComet, CfgCometLen : LongInt;
  MouseTitle : String[40];
  MouH : LongInt;                          { handle de MOUCALLS (echelle, seuils) }
  { carnet : genre (0 Systeme, 1 Souris), curseurs dessines, cadres }
  NbKind, SlN, SlDrag, GbN, TestOn, UndoDbl, UndoSpeed : LongInt;
  SlX, SlY, SlW, SlCnt, SlVal, SlId : Array[0..3] Of LongInt;
  GbX, GbY, GbW, GbH : Array[0..3] Of LongInt;
  GbS : Array[0..3] Of String[32];
  { carnet des parametres }
  NbClient, NbTab, NbN, NbModeN, LogoH : LongInt;
  NbCtl : Array[0..31] Of LongInt;
  NbLblN : LongInt;
  NbLblX, NbLblY : Array[0..15] Of LongInt;
  NbLblS : Array[0..15] Of String[60];
  NbMW, NbMH, NbMB : Array[0..127] Of LongInt;
  DeskDir : String[40];               { repertoire du bureau (C:\DESKTOP ou D:\DESKTOP) }
  CfgIn, CfgOut : Array[0..8191] Of Byte;  { CONFIG.SYS (onglet Langue) }
  { carnet Pays : valeurs (PM_National) et copie a l'ouverture (Annuler) }
  NatN, UndoN : Array[0..6] Of LongInt;
  NatS, UndoS : Array[0..7] Of String[8];
  CountryTitle : String[40];
  NbBusy : LongInt;

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
Function DosQueryCtryInfo(Cb, Pcc, Pci, PcbActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
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
Function KSetEnv(PName, PValue : LongInt) : LongInt; External 'DOSCALLS' Name 'SetEnvironmentVariableA';

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
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
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
Function WinSetScreenMode(W, H, Bits : LongInt) : LongInt; External 'PMWIN' Name 'WINSETSCREENMODE';
Function WinQueryScreenMode(P : LongInt) : LongInt; External 'PMWIN' Name 'WINQUERYSCREENMODE';
Function WinSetSysValue(HD, Ix, V : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinInitShield(Hab, Hmq : LongInt) : LongInt; External 'PMVIOP' Name 'WININITSHIELD';
Function WinCreateConsole(Own, PTitle, Fl, PH : LongInt) : LongInt; External 'PMVIOP' Name 'WINCREATECONSOLE';
Function VioQueryModes(I, P : LongInt) : LongInt; External 'VIOCALLS' Name 'VIOQUERYMODES';
Function VioQueryVbe(P : LongInt) : LongInt; External 'VIOCALLS' Name 'VIOQUERYVBE';
Function WinSetPointerStyle(Size, Inv, Comet : LongInt) : LongInt; External 'PMWIN' Name 'WINSETPOINTERSTYLE';
Function MouOpen(PDrv, PHmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetScaleFact(PScale, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetThreshold(PThr, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouGetNumButtons(PCount, Hmou : LongInt) : LongInt; External 'MOUCALLS';

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
  Else If E = 'WAV' Then
  Begin
    { son numerique : ouvert par Audio numerique }
    Icon := IC_WAVE; Obj := OB_SOUND;
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
    OB_CMDWIN : Icon := IC_CMD;
    OB_DOSFS : Icon := IC_CMD;
    OB_DOSWIN : Icon := IC_CMD;
    OB_SHUTDOWN : Icon := IC_SHUTDOWN;
    OB_WINLIST : Icon := IC_WINLIST;
    OB_INFO : Icon := IC_INFO;
    OB_HELP : Icon := IC_HELP;
    OB_TEMPLATES : Icon := IC_TEMPL;
    OB_SHRED : Icon := IC_SHRED;
    OB_SETUP : Icon := IC_SETUP;
    OB_SYSSET : Icon := IC_SCREEN;
    OB_MOUSE : Icon := IC_MOUSE;
    OB_COUNTRY : Icon := IC_GLOBE;
    OB_COLORS : Icon := IC_PALETTE;
    OB_LANG : Icon := IC_LANG;
    OB_GAMES, OB_MMFOLDER : Icon := IC_FOLDER;
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
  { parametres du systeme (Titre) : avertir au lieu de numeroter }
  If (CfgTitle <> 0) And FileExists(Dir + S) Then
  Begin
    ShowMsg('Un objet nomme ' + S + ' existe deja dans ' + Dir + '.', 'Titre', MB_OK Or MB_WARNING);
    UniqueName := '';
    Exit;
  End;
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
        If S = '' Then Exit;
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
        If S = '' Then Exit;
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
        Dummy := NewItem(V, IC_CMD, OB_CMDWIN, 'Fenetre OS/2', '');
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
        Dummy := NewItem(V, IC_SETUP, OB_SETUP, 'Configuration du systeme', '');
        Dummy := NewItem(V, IC_INFO, OB_INFO, 'Informations systeme', '');
        Dummy := NewItem(V, IC_HELP, OB_HELP, 'Aide du bureau', '');
        Dummy := NewItem(V, IC_SHUTDOWN, OB_SHUTDOWN, 'Arret', '');
        Dummy := NewItem(V, IC_CMD, OB_CMDWIN, 'Fenetre OS/2', '');
        Dummy := NewItem(V, IC_FOLDER, OB_GAMES, 'Jeux', '');
        Dummy := NewItem(V, IC_FOLDER, OB_MMFOLDER, 'Multimedia', '');
        Dummy := NewItem(V, IC_CMD, OB_DOSWIN, 'Fenetre DOS', '');
        Dummy := NewItem(V, IC_CMD, OB_DOSFS, 'DOS plein ecran', '');
      End;
    VK_MM :
      Begin
        { multimedia (composant de l'installation) : Audio numerique et les
          sons du systeme }
        If FileExists('C:\DIGAUDIO.EXE') Then
          Dummy := NewItem(V, IC_AUDIO, OB_GAME, 'Audio numerique', 'C:\DIGAUDIO.EXE');
        If FileExists('C:\DEMARRE.WAV') Then Dummy := NewItem(V, IC_WAVE, OB_SOUND, 'DEMARRE.WAV', 'C:\DEMARRE.WAV');
        If FileExists('C:\CLOCHE.WAV') Then Dummy := NewItem(V, IC_WAVE, OB_SOUND, 'CLOCHE.WAV', 'C:\CLOCHE.WAV');
      End;
    VK_GAMES :
      Begin
        { jeux installes (composant Jeux du programme d'installation) }
        If FileExists('C:\MAHJONGG.EXE') Then
          Dummy := NewItem(V, IC_TILES, OB_GAME, 'Mahjongg Solitaire', 'C:\MAHJONGG.EXE');
        If FileExists('C:\ECHECS.EXE') Then Dummy := NewItem(V, IC_CHESS, OB_GAME, 'Echecs', 'C:\ECHECS.EXE');
        If FileExists('C:\KLONDIKE.EXE') Then
          Dummy := NewItem(V, IC_CARDS, OB_GAME, 'Solitaire - Klondike', 'C:\KLONDIKE.EXE');
      End;
    VK_SETUP :
      Begin
        Dummy := NewItem(V, IC_SCREEN, OB_SYSSET, 'Systeme', '');
        Dummy := NewItem(V, IC_MOUSE, OB_MOUSE, MouseTitle, '');
        Dummy := NewItem(V, IC_PALETTE, OB_COLORS, 'Couleurs du bureau', '');
        Dummy := NewItem(V, IC_LANG, OB_LANG, 'Langue', '');
        { (Pays reste le dernier objet du dossier) }
        If FileExists('C:\DEVMGR.EXE') Then
          Dummy := NewItem(V, IC_HARDWARE, OB_GAME, 'Gestionnaire de peripheriques', 'C:\DEVMGR.EXE');
        Dummy := NewItem(V, IC_GLOBE, OB_COUNTRY, CountryTitle, '');
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
    IC_SETUP :
      Begin
        IconFolder(Hps, X, Y, CLR_YELLOW);
        FBox(Hps, X + 9, Y + 7, X + 22, Y + 18, CLR_PALEGRAY, CLR_DARKGRAY);
        GBox(Hps, X + 13, Y + 10, X + 18, Y + 15, CLR_DARKGRAY, DRO_FILL);
      End;
    IC_SCREEN :
      Begin
        FBox(Hps, X + 2, Y + 8, X + 29, Y + 29, CLR_PALEGRAY, CLR_BLACK);
        FBox(Hps, X + 5, Y + 11, X + 26, Y + 26, CLR_DARKBLUE, CLR_DARKGRAY);
        FBox(Hps, X + 11, Y + 2, X + 20, Y + 7, CLR_PALEGRAY, CLR_BLACK);
      End;
    IC_MOUSE :
      Begin
        FBox(Hps, X + 9, Y + 2, X + 22, Y + 22, CLR_WHITE, CLR_BLACK);
        GLn(Hps, X + 15, Y + 16, X + 15, Y + 22, CLR_BLACK);
        GLn(Hps, X + 9, Y + 16, X + 22, Y + 16, CLR_BLACK);
        GLn(Hps, X + 15, Y + 22, X + 15, Y + 29, CLR_DARKGRAY);
      End;
    IC_PALETTE :
      Begin
        FBox(Hps, X + 2, Y + 6, X + 29, Y + 26, CLR_PALEGRAY, CLR_BLACK);
        GBox(Hps, X + 5, Y + 17, X + 10, Y + 22, CLR_RED, DRO_FILL);
        GBox(Hps, X + 13, Y + 17, X + 18, Y + 22, CLR_GREEN, DRO_FILL);
        GBox(Hps, X + 21, Y + 17, X + 26, Y + 22, CLR_BLUE, DRO_FILL);
        GBox(Hps, X + 5, Y + 9, X + 10, Y + 14, CLR_YELLOW, DRO_FILL);
        GBox(Hps, X + 13, Y + 9, X + 18, Y + 14, CLR_CYAN, DRO_FILL);
        GBox(Hps, X + 21, Y + 9, X + 26, Y + 14, CLR_DARKRED, DRO_FILL);
      End;
    IC_GLOBE :
      Begin
        GBox(Hps, X + 4, Y + 4, X + 27, Y + 27, CLR_BLUE, DRO_FILL);
        GBox(Hps, X + 4, Y + 4, X + 27, Y + 27, CLR_DARKBLUE, DRO_OUTLINE);
        FBox(Hps, X + 8, Y + 14, X + 14, Y + 23, CLR_GREEN, CLR_GREEN);
        FBox(Hps, X + 17, Y + 8, X + 23, Y + 15, CLR_GREEN, CLR_GREEN);
        GLn(Hps, X + 4, Y + 16, X + 27, Y + 16, CLR_CYAN);
      End;
    IC_CARDS :
      Begin
        { deux cartes : un as de pique sur un dos bleu }
        FBox(Hps, X + 3, Y + 8, X + 19, Y + 29, CLR_DARKBLUE, CLR_BLACK);
        FBox(Hps, X + 12, Y + 2, X + 28, Y + 23, CLR_WHITE, CLR_BLACK);
        GText(Hps, X + 16, Y + 5, Chr(6), CLR_BLACK, CLR_WHITE);
        GText(Hps, X + 13, Y + 9, 'A', CLR_RED, CLR_WHITE);
      End;
    IC_CHESS :
      Begin
        { un damier et un cavalier }
        FBox(Hps, X + 2, Y + 2, X + 29, Y + 29, CLR_PALEGRAY, CLR_BLACK);
        GBox(Hps, X + 2, Y + 16, X + 15, Y + 29, CLR_DARKCYAN, DRO_FILL);
        GBox(Hps, X + 16, Y + 2, X + 29, Y + 15, CLR_DARKCYAN, DRO_FILL);
        FBox(Hps, X + 9, Y + 5, X + 22, Y + 8, CLR_BLACK, CLR_BLACK);
        FBox(Hps, X + 12, Y + 8, X + 20, Y + 19, CLR_BLACK, CLR_BLACK);
        FBox(Hps, X + 8, Y + 17, X + 19, Y + 24, CLR_BLACK, CLR_BLACK);
        FBox(Hps, X + 15, Y + 24, X + 19, Y + 27, CLR_BLACK, CLR_BLACK);
      End;
    IC_TILES :
      Begin
        { tuiles empilees }
        FBox(Hps, X + 2, Y + 2, X + 17, Y + 21, CLR_DARKGRAY, CLR_BLACK);
        FBox(Hps, X + 5, Y + 5, X + 20, Y + 24, CLR_WHITE, CLR_BLACK);
        FBox(Hps, X + 11, Y + 8, X + 26, Y + 27, CLR_DARKGRAY, CLR_BLACK);
        FBox(Hps, X + 14, Y + 11, X + 29, Y + 30, CLR_WHITE, CLR_BLACK);
        GBox(Hps, X + 19, Y + 16, X + 24, Y + 25, CLR_RED, DRO_OUTLINE);
        GLn(Hps, X + 21, Y + 13, X + 21, Y + 28, CLR_RED);
        GBox(Hps, X + 9, Y + 12, X + 12, Y + 15, CLR_DARKGREEN, DRO_FILL);
      End;
    IC_HARDWARE :
      Begin
        { carte d'extension : circuit et connecteur }
        FBox(Hps, X + 2, Y + 8, X + 29, Y + 25, CLR_DARKGREEN, CLR_BLACK);
        FBox(Hps, X + 8, Y + 12, X + 18, Y + 21, CLR_BLACK, CLR_BLACK);
        GBox(Hps, X + 21, Y + 18, X + 26, Y + 21, CLR_YELLOW, DRO_FILL);
        GBox(Hps, X + 21, Y + 12, X + 26, Y + 15, CLR_YELLOW, DRO_FILL);
        GBox(Hps, X + 5, Y + 4, X + 27, Y + 7, CLR_YELLOW, DRO_FILL);
      End;
    IC_AUDIO :
      Begin
        { haut-parleur et ondes sonores }
        FBox(Hps, X + 3, Y + 11, X + 9, Y + 21, CLR_DARKGRAY, CLR_BLACK);
        GLn(Hps, X + 9, Y + 11, X + 16, Y + 4, CLR_BLACK);
        GLn(Hps, X + 9, Y + 21, X + 16, Y + 28, CLR_BLACK);
        GLn(Hps, X + 16, Y + 4, X + 16, Y + 28, CLR_BLACK);
        GLn(Hps, X + 20, Y + 12, X + 20, Y + 20, CLR_BLUE);
        GLn(Hps, X + 24, Y + 9, X + 24, Y + 23, CLR_BLUE);
        GLn(Hps, X + 28, Y + 6, X + 28, Y + 26, CLR_BLUE);
      End;
    IC_WAVE :
      Begin
        { fichier son : page et forme d'onde }
        FBox(Hps, X + 5, Y + 2, X + 26, Y + 29, CLR_WHITE, CLR_BLACK);
        GBox(Hps, X + 8, Y + 8, X + 23, Y + 23, CLR_BLUE, DRO_FILL);
        GLn(Hps, X + 9, Y + 15, X + 22, Y + 15, CLR_WHITE);
        GLn(Hps, X + 11, Y + 11, X + 11, Y + 19, CLR_WHITE);
        GLn(Hps, X + 14, Y + 9, X + 14, Y + 21, CLR_WHITE);
        GLn(Hps, X + 17, Y + 12, X + 17, Y + 18, CLR_WHITE);
        GLn(Hps, X + 20, Y + 14, X + 20, Y + 16, CLR_WHITE);
      End;
    IC_LANG :
      Begin
        FBox(Hps, X + 3, Y + 12, X + 17, Y + 29, CLR_WHITE, CLR_DARKBLUE);
        GText(Hps, X + 6, Y + 13, 'A', CLR_DARKBLUE, CLR_WHITE);
        FBox(Hps, X + 14, Y + 2, X + 28, Y + 19, CLR_YELLOW, CLR_DARKRED);
        GText(Hps, X + 17, Y + 3, 'z', CLR_DARKRED, CLR_YELLOW);
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
    Bg := DeskColor; Fg := CLR_WHITE;
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
    MenuAdd(CM_SETTINGS, '~Parametres du systeme...');
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
  { parametres du systeme (Fenetre) : fenetre existante ou nouvelle }
  If CfgWin = 0 Then V := FindView(Kind, Path) Else V := -1;
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
  C := DeskColor;
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

{ fenetre OS/2 : l'interpreteur de commandes dans une nouvelle session
  montree dans une fenetre de PM par PMVIOP.DLL (bouclier VIO) ; si la
  console ne peut etre creee, la session passe en plein ecran }
Procedure RunWindowOf(Prog, Title, Dir : String);
Var Res : Array[0..1] Of LongInt; Rc, K, S, Hc : LongInt; D : String;
Begin
  If Dir <> '' Then
  Begin
    If (Length(Dir) >= 2) And (Dir[2] = ':') Then Dummy := DosSetDefaultDisk(Ord(UpCase(Dir[1])) - 64);
    D := Dir;
    If (Length(D) > 3) And (D[Length(D)] = '\') Then D := Copy(D, 1, Length(D) - 1);
    Dummy := DosSetCurrentDir(Z(D));
  End;
  PutZ(LongInt(@ArgBuf), Prog);
  K := Length(Prog) + 1;
  WrB(LongInt(@ArgBuf) + K, 0); WrB(LongInt(@ArgBuf) + K + 1, 0);
  S := KSes(4, Z(Title), 0);
  If S < 0 Then
  Begin
    ShowMsg('Trop de sessions : fermez un programme.', 'Bureau', MB_OK Or MB_WARNING);
    Exit;
  End;
  Dummy := KSes(12, S, 0);
  PutZ(LongInt(@NameZ2), Prog);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), LongInt(@NameZ2));
  If Rc <> 0 Then
  Begin
    Dummy := KSes(12, -1, 0);
    Dummy := KSes(17, S, 0);
    ShowMsg('SYS1041: Impossible de lancer ' + Prog + ' (erreur ' + IStr(Rc) + ').', 'Bureau', MB_OK Or MB_ERROR);
    Exit;
  End;
  If ShieldOk = 0 Then
  Begin
    Dummy := WinInitShield(Hab, Hmq);
    ShieldOk := 1;
  End;
  Hc := 0;
  If WinCreateConsole(HWND_DESKTOP, Z(Title), 1 Or 2 Or (S Shl 8), LongInt(@Hc)) <> 0 Then
    Dummy := KSes(3, S, 0);
End;

Procedure RunWindow(Dir : String);
Begin
  RunWindowOf(Comspec, 'Fenetre OS/2', Dir);
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
  If CfgConf[2] <> 0 Then
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
    OB_CMDWIN : T := T + ' : ' + Comspec + ' dans une fenetre de PM (PMVIOP.DLL).';
    OB_DOSFS : T := T + ' : session DOS plein ecran (machine virtuelle 8086, COMMAND.COM integre).';
    OB_DOSWIN : T := T + ' : session DOS dans une fenetre de PM (machine virtuelle 8086 ; plein ecran pour les modes graphiques).';
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
  { un objet du meme nom existe deja : numero ajoute (ou avertissement) }
  If FileExists(Dest + Nm) Then
  Begin
    R := Length(Nm);
    While (R > 0) And (Nm[R] <> '.') Do Dec(R);
    If R > 1 Then Nm := UniqueName(Dest, Copy(Nm, 1, R - 1), Copy(Nm, R, 255))
    Else Nm := UniqueName(Dest, Nm, '');
    If Nm = '' Then Exit;
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

Procedure OpenNotebook(Tab : LongInt); Forward;
Procedure OpenNb(Kind, Tab : LongInt); Forward;
Procedure RunPm(P, Params : String); Forward;

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
    OB_CMDWIN :
      Begin
        If Vw(V)^.Kind = VK_DIR Then P := Vw(V)^.Path Else P := '';
        RunWindow(P);
      End;
    OB_DOSFS :
      Begin
        { session DOS plein ecran : l'interpreteur de commandes integre
          de la machine virtuelle DOS (COMMAND.COM) }
        If Vw(V)^.Kind = VK_DIR Then P := Vw(V)^.Path Else P := '';
        RunProgram('C:\COMMAND.COM', '', P, False);
      End;
    OB_DOSWIN :
      Begin
        { session DOS dans une fenetre de PM (PMVIOP.DLL) : COMMAND.COM de
          la machine virtuelle ; un mode graphique passe en plein ecran }
        If Vw(V)^.Kind = VK_DIR Then P := Vw(V)^.Path Else P := '';
        RunWindowOf('C:\COMMAND.COM', 'Fenetre DOS', P);
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
    OB_SETUP : OpenFolder(VK_SETUP, '', 'Configuration du systeme');
    OB_SYSSET : OpenNotebook(0);
    OB_MOUSE : OpenNb(1, 0);
    OB_COLORS : OpenNotebook(6);
    OB_LANG : OpenNotebook(7);
    OB_COUNTRY : OpenNb(2, 0);
    OB_GAMES : OpenFolder(VK_GAMES, '', 'Jeux');
    OB_GAME : RunPm(It(K)^.Path, '');
    OB_MMFOLDER : OpenFolder(VK_MM, '', 'Multimedia');
    OB_SOUND :
      If FileExists('C:\DIGAUDIO.EXE') Then RunPm('C:\DIGAUDIO.EXE', It(K)^.Path) Else OpenViewer(It(K)^.Path);
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
  { parametres du systeme : confirmations }
  If (It(K)^.Obj = OB_DIR) And (It(K)^.Shadow = 0) Then Ask := Ask And (CfgConf[0] <> 0)
  Else Ask := Ask And (CfgConf[1] <> 0);
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
    CM_SETTINGS : OpenNotebook(0);
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
  Else If Verb = 'SHUTDOWN' Then Shutdown
  Else If Verb = 'SETTINGS' Then OpenNotebook(0);
End;

{ ==================================================================== }
{ Parametres du systeme : carnet "Systeme - Parametres"                 }
{ ==================================================================== }
{ Onglets : Ecran (resolution : modes VGA et VESA de VIOCALLS),
  Confirmations, Titre, Fenetre, Entree (souris), Logo, General
  (couleur du bureau). Les valeurs sont gardees dans OS2.INI
  (application PMSHELL ; resolution : PM_Display, RESOLUTION). }

Const
  NbTabName : Array[0..NbTabs - 1] Of String[16] = ('Ecran', 'Confirmations', 'Titre', 'Fenetre', 'Entree', 'Logo',
                                                     'General', 'Langue');
  { langue des programmes : SET LANGUAGE= de CONFIG.SYS (convention de
    MSDOS-0, Pasdows95...) ; aussi reconnus : ES, DE, SQ, PRT, SWE, DNK,
    JPN }
  NLang = 10;
  LangCodes : Array[0..NLang - 1] Of String[3] = ('FR', 'EN', 'GR', 'SP', 'IT', 'ALB', 'PT', 'SE', 'DK', 'JP');
  LangNames : Array[0..NLang - 1] Of String[24] = ('Francais (FR)', 'English (EN)', 'Deutsch (GR)', 'Espanol (SP)',
                                                   'Italiano (IT)', 'Shqip (ALB)', 'Portugues (PT)', 'Svenska (SE)',
                                                   'Dansk (DK)', 'Nihongo, romaji (JP)');
  ClrName : Array[0..15] Of String[16] = ('Cyan fonce', 'Bleu fonce', 'Vert fonce', 'Rouge fonce', 'Magenta fonce',
                                          'Brun', 'Gris clair', 'Gris fonce', 'Bleu', 'Vert', 'Cyan', 'Rouge', 'Magenta',
                                          'Jaune', 'Blanc', 'Noir');
  ClrRgbTab : Array[0..15] Of LongInt = ($008080, $000080, $008000, $800000, $800080, $808000, $C0C0C0, $808080,
                                         $0000FF, $00FF00, $00FFFF, $FF0000, $FF00FF, $FFFF00, $FFFFFF, $000000);
  DblTab : Array[0..4] Of LongInt = (200, 300, 500, 700, 1000);
  { carnet Souris : double clic (lent -> rapide), echelle de MOUCALLS
    (mickeys par 8 pels : petit = rapide) }
  DblSlide : Array[0..8] Of LongInt = (1000, 850, 700, 600, 500, 420, 350, 280, 200);
  SpeedCs : Array[0..8] Of LongInt = (16, 12, 10, 8, 6, 5, 4, 3, 2);
  CtyTabName : Array[0..4] Of String[16] = ('Pays', 'Heure', 'Date', 'Nombres', 'General');
  { pays proposes (code de pays d'OS/2) }
  NCty = 20;
  CtyCodes : Array[0..NCty - 1] Of LongInt = (1, 2, 3, 31, 32, 33, 34, 39, 41, 44, 45, 46, 47, 49, 55, 61, 81, 351,
                                              355, 358);
  CtyNames : Array[0..NCty - 1] Of String[20] = ('Etats-Unis', 'Canada', 'Amerique latine', 'Pays-Bas', 'Belgique',
                                                 'France', 'Espagne', 'Italie', 'Suisse', 'Royaume-Uni', 'Danemark',
                                                 'Suede', 'Norvege', 'Allemagne', 'Bresil', 'Australie', 'Japon',
                                                 'Portugal', 'Albanie', 'Finlande');
  MouTabName : Array[0..5] Of String[16] = ('Minutage', 'Configuration', 'Affectations', 'Pointeurs', 'Comete',
                                            'General');
  { fleche du pointeur (apercu) }
  PvB : Array[0..15] Of LongInt = ($8000, $C000, $A000, $9000, $8800, $8400, $8200, $8100,
                                   $8080, $83C0, $9200, $A900, $C900, $8480, $0480, $0300);
  PvW : Array[0..15] Of LongInt = ($0000, $0000, $4000, $6000, $7000, $7800, $7C00, $7E00,
                                   $7F00, $7C00, $6C00, $4600, $0600, $0300, $0300, $0000);

Function PrfNum(Key : String; Df : LongInt) : LongInt;
Var V, C : LongInt; S : String;
Begin
  S := PrfStr('PMSHELL', Key);
  Val(S, V, C);
  If (S = '') Or (C <> 0) Then V := Df;
  PrfNum := V;
End;

{ souris : echelle et acceleration de MOUCALLS (vitesse de deplacement) }
Procedure ApplyMouse;
Var Sc : Array[0..3] Of Byte; Th : Array[0..9] Of Byte; Cs : LongInt;
Begin
  If MouH = 0 Then Dummy := MouOpen(0, LongInt(@MouH));
  If MouH = 0 Then Exit;
  If (CfgSpeed < 0) Or (CfgSpeed > 8) Then CfgSpeed := 3;
  Cs := SpeedCs[CfgSpeed];
  WrW(LongInt(@Sc), Cs * 2); WrW(LongInt(@Sc) + 2, Cs);
  Dummy := MouSetScaleFact(LongInt(@Sc), MouH);
  WrW(LongInt(@Th), 10); WrW(LongInt(@Th) + 2, 4); WrW(LongInt(@Th) + 4, 1); WrW(LongInt(@Th) + 6, 12);
  If CfgSpeed >= 6 Then WrW(LongInt(@Th) + 8, 2) Else WrW(LongInt(@Th) + 8, 1);
  Dummy := MouSetThreshold(LongInt(@Th), MouH);
End;

{ pointeur : taille, couleurs, comete (PMWIN, WINSETPOINTERSTYLE) }
Procedure ApplyPointer;
Var L : LongInt;
Begin
  If CfgComet <> 0 Then L := MaxI(1, MinI(6, CfgCometLen)) Else L := 0;
  Dummy := WinSetPointerStyle(1 + CfgPtrBig, CfgPtrInv, L);
End;

Procedure ApplySettings;
Begin
  If (CfgClr < 0) Or (CfgClr > 15) Then CfgClr := 0;
  DeskColor := ClrRgbTab[CfgClr];
  Dummy := WinSetSysValue(HWND_DESKTOP, SV_DBLCLKTIME, CfgDbl);
  Dummy := WinSetSysValue(HWND_DESKTOP, SV_SWAPBUTTON, CfgSwap);
  ApplyMouse;
  ApplyPointer;
End;

Procedure LoadSettings;
Begin
  CfgConf[0] := PrfNum('CONF_DOSSIER', 1); CfgConf[1] := PrfNum('CONF_OBJET', 1); CfgConf[2] := PrfNum('CONF_ARRET', 1);
  CfgTitle := PrfNum('TITRE', 0); CfgWin := PrfNum('FENETRE', 0); CfgLogo := PrfNum('LOGO', 0);
  CfgDbl := PrfNum('DOUBLECLIC', 500); CfgSwap := PrfNum('GAUCHER', 0); CfgClr := PrfNum('COULEUR', 0);
  CfgSpeed := PrfNum('VITESSE', 3); CfgMapList := PrfNum('MAP_LISTE', 0); CfgMapMenu := PrfNum('MAP_MENU', 0);
  CfgMapDrag := PrfNum('MAP_GLISSER', 0); CfgPtrBig := PrfNum('PTR_GRAND', 0); CfgPtrInv := PrfNum('PTR_INVERSE', 0);
  CfgComet := PrfNum('COMETE', 0); CfgCometLen := PrfNum('COMETE_LONG', 4);
  MouseTitle := PrfStr('PMSHELL', 'TITRE_SOURIS');
  If MouseTitle = '' Then MouseTitle := 'Souris';
  ApplySettings;
End;

Procedure SaveSettings;
Begin
  PrfSet('PMSHELL', 'CONF_DOSSIER', IStr(CfgConf[0])); PrfSet('PMSHELL', 'CONF_OBJET', IStr(CfgConf[1]));
  PrfSet('PMSHELL', 'CONF_ARRET', IStr(CfgConf[2])); PrfSet('PMSHELL', 'TITRE', IStr(CfgTitle));
  PrfSet('PMSHELL', 'FENETRE', IStr(CfgWin)); PrfSet('PMSHELL', 'LOGO', IStr(CfgLogo));
  PrfSet('PMSHELL', 'DOUBLECLIC', IStr(CfgDbl)); PrfSet('PMSHELL', 'GAUCHER', IStr(CfgSwap));
  PrfSet('PMSHELL', 'COULEUR', IStr(CfgClr));
  PrfSet('PMSHELL', 'VITESSE', IStr(CfgSpeed)); PrfSet('PMSHELL', 'MAP_LISTE', IStr(CfgMapList));
  PrfSet('PMSHELL', 'MAP_MENU', IStr(CfgMapMenu)); PrfSet('PMSHELL', 'MAP_GLISSER', IStr(CfgMapDrag));
  PrfSet('PMSHELL', 'PTR_GRAND', IStr(CfgPtrBig)); PrfSet('PMSHELL', 'PTR_INVERSE', IStr(CfgPtrInv));
  PrfSet('PMSHELL', 'COMETE', IStr(CfgComet)); PrfSet('PMSHELL', 'COMETE_LONG', IStr(CfgCometLen));
  PrfSet('PMSHELL', 'TITRE_SOURIS', MouseTitle);
End;

{ nombre de couleurs d'un mode (texte du carnet) }
Function ColorsOf(B : LongInt) : String;
Begin
  Case B Of
    1 : ColorsOf := '2';
    4 : ColorsOf := '16';
    8 : ColorsOf := '256';
    15 : ColorsOf := '32 768';
    16 : ColorsOf := '65 536';
    24 : ColorsOf := '16 777 216';
  Else
    ColorsOf := '16 777 216 (32 bits)';
  End;
End;

{ modes de l'ecran (VIOQUERYMODES), tries par largeur, hauteur, couleurs }
Procedure LoadModes;
Var N, I, J, T : LongInt; M : Array[0..3] Of LongInt;
Begin
  NbModeN := 0;
  N := VioQueryModes(0, 0);
  For I := 0 To N - 1 Do
    If (NbModeN < 128) And (VioQueryModes(I, LongInt(@M)) <> 0) Then
    Begin
      NbMW[NbModeN] := M[0]; NbMH[NbModeN] := M[1]; NbMB[NbModeN] := M[2];
      Inc(NbModeN);
    End;
  If NbModeN = 0 Then
  Begin
    NbMW[0] := 640; NbMH[0] := 480; NbMB[0] := 4; NbModeN := 1;
  End;
  For I := 1 To NbModeN - 1 Do
  Begin
    J := I;
    While (J > 0) And ((NbMW[J - 1] > NbMW[J]) Or ((NbMW[J - 1] = NbMW[J]) And
          ((NbMH[J - 1] > NbMH[J]) Or ((NbMH[J - 1] = NbMH[J]) And (NbMB[J - 1] > NbMB[J]))))) Do
    Begin
      T := NbMW[J]; NbMW[J] := NbMW[J - 1]; NbMW[J - 1] := T;
      T := NbMH[J]; NbMH[J] := NbMH[J - 1]; NbMH[J - 1] := T;
      T := NbMB[J]; NbMB[J] := NbMB[J - 1]; NbMB[J - 1] := T;
      Dec(J);
    End;
  End;
End;

{ l'ecran a change de taille : bureau redimensionne, icones replacees }
Procedure ScreenResized;
Var M : Array[0..3] Of LongInt; V : LongInt;
Begin
  M[0] := 0;
  Dummy := WinQueryScreenMode(LongInt(@M));
  If M[0] <= 0 Then Exit;
  ScrW := M[0]; ScrH := M[1];
  If Desk <> 0 Then
  Begin
    Dummy := WinSetWindowPos(Desk, HWND_BOTTOM, 0, 0, ScrW, ScrH, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER);
    V := ViewOf(Desk);
    If V >= 0 Then Layout(V);
  End;
  Dummy := WinInvalidateRect(HWND_DESKTOP, 0, 1);
End;

{ choisir la resolution W x H x B ; elle est gardee (OS2.INI) si
  l'utilisateur la confirme, sinon l'ancienne est rendue }
Procedure ApplyResolution(W, H, B : LongInt);
Var M : Array[0..3] Of LongInt;
Begin
  M[0] := 640; M[1] := 480; M[2] := 4;
  Dummy := WinQueryScreenMode(LongInt(@M));
  If (M[0] = W) And (M[1] = H) And (M[2] = B) Then Exit;
  If WinSetScreenMode(W, H, B) = 0 Then
  Begin
    ShowMsg('La carte video ne peut pas afficher ' + IStr(W) + ' x ' + IStr(H) + ' x ' + ColorsOf(B) + ' couleurs.',
            'Ecran', MB_OK Or MB_ERROR);
    ScreenResized;
    Exit;
  End;
  ScreenResized;
  If WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, Z('Nouvelle resolution : ' + IStr(W) + ' x ' + IStr(H) + ' x ' +
                   ColorsOf(B) + ' couleurs. La conserver ?'), Z2('Ecran'), 0,
                   MB_YESNO Or MB_QUERY Or MB_MOVEABLE) = MBID_YES Then
    PrfSet('PM_Display', 'RESOLUTION', IStr(W) + 'x' + IStr(H) + 'x' + IStr(B))
  Else
  Begin
    Dummy := WinSetScreenMode(M[0], M[1], M[2]);
    ScreenResized;
  End;
End;

{ --- controles d'une page (coordonnees depuis le haut de la page) --- }
Function NbAdd(Cls, Style, X, YTop, W, Hh, Id : LongInt; Text : String) : LongInt;
Var R : Array[0..3] Of LongInt; Hw : LongInt;
Begin
  Dummy := WinQueryWindowRect(NbClient, LongInt(@R));
  { HWND_BOTTOM : les controles restent dans l'ordre de creation (groupes
    de boutons radio, comme dans un dialogue) }
  Hw := WinCreateWindow(NbClient, Cls, Z(Text), WS_VISIBLE Or Style, 40 + X, R[3] - 18 - YTop - Hh, W, Hh, NbClient,
                        HWND_BOTTOM, Id, 0, 0);
  If NbN < 32 Then
  Begin
    NbCtl[NbN] := Hw;
    Inc(NbN);
  End;
  NbAdd := Hw;
End;

{ texte de la page (dessine par NbPaint, sur le fond de la page) }
Procedure NbText(X, YTop, W : LongInt; Text : String);
Begin
  If NbLblN < 16 Then
  Begin
    NbLblX[NbLblN] := X; NbLblY[NbLblN] := YTop; NbLblS[NbLblN] := Text;
    Inc(NbLblN);
  End;
End;

Function NbCheck(X, YTop, W, Id : LongInt; Text : String; On : Boolean; Style : LongInt) : LongInt;
Var Hw : LongInt;
Begin
  W := MinI(W, Length(Text) * 8 + 28);
  Hw := NbAdd(WC_BUTTON, Style Or WS_TABSTOP, X, YTop, W, 20, Id, Text);
  If On Then Dummy := WinSendMsg(Hw, BM_SETCHECK, 1, 0);
  NbCheck := Hw;
End;

Function NbButton(X, YTop, W, Id : LongInt; Text : String) : LongInt;
Begin
  NbButton := NbAdd(WC_BUTTON, BS_PUSHBUTTON Or WS_TABSTOP, X, YTop, W, 22, Id, Text);
End;

Function NbList(X, YTop, W, Hh, Id : LongInt) : LongInt;
Begin
  NbList := NbAdd(WC_LISTBOX, WS_TABSTOP, X, YTop, W, Hh, Id, '');
End;

Procedure NbItem(Lb : LongInt; S : String);
Var B : Array[0..127] Of Byte;
Begin
  PutZ(LongInt(@B), S);
  Dummy := WinSendMsg(Lb, LM_INSERTITEM, -1, LongInt(@B));
End;

{ langue courante (variable LANGUAGE de l'environnement) }
Function CurLang : LongInt;
Var S : String; K, R : LongInt;
Begin
  S := UpStr(GetEnvS('LANGUAGE'));
  If S = 'ES' Then S := 'SP';
  If S = 'DE' Then S := 'GR';
  If S = 'SQ' Then S := 'ALB';
  If S = 'PRT' Then S := 'PT';
  If S = 'SWE' Then S := 'SE';
  If S = 'DNK' Then S := 'DK';
  If S = 'JPN' Then S := 'JP';
  R := 0;
  For K := 0 To NLang - 1 Do
    If S = LangCodes[K] Then R := K;
  CurLang := R;
End;

{ nouvelle langue : environnement du systeme (programmes lances ensuite)
  et ligne SET LANGUAGE= de C:\CONFIG.SYS (ajoutee au besoin) ; le
  fichier est traite octet par octet (tampons CfgIn et CfgOut) }
{ ligne S (et CR LF) ajoutee a CfgOut en Out }
Procedure CfgLine(Var Out : LongInt; S : String);
Var J : LongInt;
Begin
  PutZ(LongInt(@NameZ), S);
  J := 0;
  While (NameZ[J] <> 0) And (Out < 8180) Do
  Begin
    CfgOut[Out] := NameZ[J];
    Inc(Out); Inc(J);
  End;
  CfgOut[Out] := 13; CfgOut[Out + 1] := 10; Out := Out + 2;
End;

{ remplacer dans C:\CONFIG.SYS la ligne qui commence par Key (sans tenir
  compte de la casse) par Ln, ou l'ajouter a la fin }
Procedure SetCfgLine(Key, Ln : String);
Var H, A, Got, K, J, Out, St : LongInt; Found, Match : Boolean;
Begin
  H := 0; A := 0; Got := 0;
  If DosOpen(Z('C:\CONFIG.SYS'), LongInt(@H), LongInt(@A), 0, 0, 1, $40, 0) = 0 Then
  Begin
    Dummy := DosRead(H, LongInt(@CfgIn), 8000, LongInt(@Got));
    Dummy := DosClose(H);
  End;
  If (Got < 0) Or (Got > 8000) Then Got := 0;
  Key := UpStr(Key);
  Out := 0; Found := False; K := 0;
  While K < Got Do
  Begin
    St := K;
    Match := True;
    For J := 1 To Length(Key) Do
      If (St + J - 1 >= Got) Or (UpCase(Chr(CfgIn[St + J - 1])) <> Key[J]) Then Match := False;
    While (K < Got) And (CfgIn[K] <> 10) Do Inc(K);
    If K < Got Then Inc(K);
    If Match And Not Found Then
    Begin
      Found := True;
      CfgLine(Out, Ln);
    End
    Else
      For J := St To K - 1 Do
        If Out < 8180 Then
        Begin
          CfgOut[Out] := CfgIn[J];
          Inc(Out);
        End;
  End;
  If Not Found Then
  Begin
    If (Out > 0) And (CfgOut[Out - 1] <> 10) Then
    Begin
      CfgOut[Out] := 13; CfgOut[Out + 1] := 10; Out := Out + 2;
    End;
    CfgLine(Out, Ln);
  End;
  H := 0;
  If DosOpen(Z('C:\CONFIG.SYS'), LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0) = 0 Then
  Begin
    Dummy := DosWrite(H, LongInt(@CfgOut), Out, LongInt(@Got));
    Dummy := DosClose(H);
  End;
End;

Procedure SetLanguage(N : LongInt);
Begin
  PutZ(LongInt(@NameZ2), LangCodes[N]);
  Dummy := KSetEnv(Z('LANGUAGE'), LongInt(@NameZ2));
  SetCfgLine('SET LANGUAGE=', 'SET LANGUAGE=' + LangCodes[N]);
End;

{ ==================================================================== }
{ Carnet "Pays - Parametres" (objet Pays de Configuration du systeme)   }
{ ==================================================================== }
{ Onglets : Pays (pays, mesures, separateur de liste), Heure (12 ou 24
  heures, AM et PM, separateur), Date (ordre, separateur), Nombres
  (separateurs des milliers et des decimales, decimales, zero initial,
  symbole monetaire et sa position), General (titre). Valeurs gardees
  dans OS2.INI, application PM_National (cles d'OS/2 : iCountry,
  iMeasurement, sList, iTime, s1159, s2359, sTime, iDate, sDate,
  sThousand, sDecimal, iDigits, iLzero, sCurrency, iCurrency) ; le pays
  est aussi la ligne COUNTRY= de CONFIG.SYS et la variable COUNTRY de
  l'environnement (DosQueryCtryInfo de DOSCALLS.DLL et NLS.DLL). }

Function NatKeyN(K : LongInt) : String;
Begin
  Case K Of
    0 : NatKeyN := 'iCountry';
    1 : NatKeyN := 'iMeasurement';
    2 : NatKeyN := 'iTime';
    3 : NatKeyN := 'iDate';
    4 : NatKeyN := 'iDigits';
    5 : NatKeyN := 'iLzero';
  Else
    NatKeyN := 'iCurrency';
  End;
End;

Function NatKeyS(K : LongInt) : String;
Begin
  Case K Of
    0 : NatKeyS := 'sList';
    1 : NatKeyS := 's1159';
    2 : NatKeyS := 's2359';
    3 : NatKeyS := 'sTime';
    4 : NatKeyS := 'sDate';
    5 : NatKeyS := 'sThousand';
    6 : NatKeyS := 'sDecimal';
  Else
    NatKeyS := 'sCurrency';
  End;
End;

Function CtyIndex(Code : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 0 To NCty - 1 Do
    If CtyCodes[K] = Code Then R := K;
  CtyIndex := R;
End;

{ valeurs d'un pays : COUNTRYINFO de DosQueryCtryInfo }
Procedure CountryDefaults(Code : LongInt);
Var Cc : Array[0..1] Of LongInt; Ci : Array[0..15] Of LongInt; N : LongInt;
Begin
  Cc[0] := Code; Cc[1] := 0;
  FillChar(Ci, SizeOf(Ci), 0);
  N := 0;
  If DosQueryCtryInfo(44, LongInt(@Cc), LongInt(@Ci), LongInt(@N)) <> 0 Then
  Begin
    Ci[2] := 1; PutZ(LongInt(@Ci) + 12, '$'); PutZ(LongInt(@Ci) + 17, ','); PutZ(LongInt(@Ci) + 19, '.');
    PutZ(LongInt(@Ci) + 21, '/'); PutZ(LongInt(@Ci) + 23, ':'); PutZ(LongInt(@Ci) + 32, ';');
    WrB(LongInt(@Ci) + 25, 0); WrB(LongInt(@Ci) + 26, 2); WrB(LongInt(@Ci) + 27, 1);
  End;
  NatN[0] := Code;
  If (Code = 1) Or (Code = 44) Then NatN[1] := 1 Else NatN[1] := 0;
  NatN[2] := RdB(LongInt(@Ci) + 27) And 1;
  NatN[3] := MinI(2, Ci[2]);
  NatN[4] := RdB(LongInt(@Ci) + 26);
  NatN[5] := 1;
  NatN[6] := RdB(LongInt(@Ci) + 25) And 3;
  NatS[0] := GetZ(LongInt(@Ci) + 32);
  If NatS[0] = '' Then NatS[0] := ';';
  NatS[1] := 'AM'; NatS[2] := 'PM';
  NatS[3] := GetZ(LongInt(@Ci) + 23);
  NatS[4] := GetZ(LongInt(@Ci) + 21);
  NatS[5] := GetZ(LongInt(@Ci) + 17);
  NatS[6] := GetZ(LongInt(@Ci) + 19);
  NatS[7] := GetZ(LongInt(@Ci) + 12);
End;

Procedure CountrySave;
Var K : LongInt;
Begin
  For K := 0 To 6 Do PrfSet('PM_National', NatKeyN(K), IStr(NatN[K]));
  For K := 0 To 7 Do
    If NatS[K] = '' Then PrfSet('PM_National', NatKeyS(K), ' ') Else PrfSet('PM_National', NatKeyS(K), NatS[K]);
  PrfSet('PMSHELL', 'TITRE_PAYS', CountryTitle);
End;

{ lecture d'OS2.INI (PM_National) ; sinon les valeurs du pays courant }
Procedure CountryLoad;
Var K, V, E : LongInt; S : String;
Begin
  CountryTitle := PrfStr('PMSHELL', 'TITRE_PAYS');
  If CountryTitle = '' Then CountryTitle := 'Pays';
  V := 0;
  S := GetEnvS('COUNTRY');
  If S <> '' Then Val(S, V, E);
  If CtyIndex(V) < 0 Then V := 2;
  CountryDefaults(V);
  S := PrfStr('PM_National', 'iCountry');
  If S = '' Then Exit;
  For K := 0 To 6 Do
  Begin
    S := PrfStr('PM_National', NatKeyN(K));
    Val(S, V, E);
    If (S <> '') And (E = 0) Then NatN[K] := V;
  End;
  For K := 0 To 7 Do
  Begin
    S := PrfStr('PM_National', NatKeyS(K));
    If S = ' ' Then NatS[K] := '' Else If S <> '' Then NatS[K] := S;
  End;
End;

Function Pad2(V : LongInt) : String;
Begin
  If V < 10 Then Pad2 := '0' + IStr(V) Else Pad2 := IStr(V);
End;

{ heure et date au format choisi }
Function NatTime(H, M, S : LongInt) : String;
Var T : String; H12 : LongInt;
Begin
  If NatN[2] = 1 Then T := Pad2(H) + NatS[3] + Pad2(M) + NatS[3] + Pad2(S)
  Else
  Begin
    H12 := H Mod 12;
    If H12 = 0 Then H12 := 12;
    T := IStr(H12) + NatS[3] + Pad2(M) + NatS[3] + Pad2(S);
    If H < 12 Then T := T + ' ' + NatS[1] Else T := T + ' ' + NatS[2];
  End;
  NatTime := T;
End;

Function NatDate(D, M, Y : LongInt) : String;
Begin
  Case NatN[3] Of
    0 : NatDate := Pad2(M) + NatS[4] + Pad2(D) + NatS[4] + IStr(Y);
    2 : NatDate := IStr(Y) + NatS[4] + Pad2(M) + NatS[4] + Pad2(D);
  Else
    NatDate := Pad2(D) + NatS[4] + Pad2(M) + NatS[4] + IStr(Y);
  End;
End;

{ nombre entier avec le separateur des milliers }
Function NatInt(V : LongInt) : String;
Var S, R : String; N : LongInt;
Begin
  S := IStr(V);
  R := ''; N := 0;
  While Length(S) > 0 Do
  Begin
    If (N > 0) And (N Mod 3 = 0) And (S[Length(S)] <> '-') Then R := NatS[5] + R;
    R := S[Length(S)] + R;
    Delete(S, Length(S), 1);
    Inc(N);
  End;
  NatInt := R;
End;

{ montant (centiemes) avec decimales et symbole monetaire }
Function NatMoney(Cents : LongInt; WithCur : Boolean) : String;
Var S, F : String; K : LongInt;
Begin
  S := NatInt(Cents Div 100);
  If (S = '0') And (NatN[5] = 0) And (NatN[4] > 0) Then S := '';
  If NatN[4] > 0 Then
  Begin
    F := Pad2(Cents Mod 100);
    For K := 3 To NatN[4] Do F := F + '0';
    S := S + NatS[6] + Copy(F, 1, NatN[4]);
  End;
  If WithCur Then
    Case NatN[6] Of
      0 : S := NatS[7] + S;
      1 : S := S + NatS[7];
      2 : S := NatS[7] + ' ' + S;
    Else
      S := S + ' ' + NatS[7];
    End;
  NatMoney := S;
End;

Procedure CountryApply(Code : LongInt);
Begin
  CountryDefaults(Code);
  CountrySave;
  SetCfgLine('COUNTRY=', 'COUNTRY=' + Copy(IStr(1000 + Code), 2, 3) + ',C:\COUNTRY.SYS');
  PutZ(LongInt(@NameZ2), IStr(Code));
  Dummy := KSetEnv(Z('COUNTRY'), LongInt(@NameZ2));
End;

Procedure NbCombo(X, YTop, W, Id : LongInt);
Begin
  Dummy := NbAdd(WC_COMBOBOX, WS_TABSTOP Or CBS_DROPDOWNLIST, X, YTop, W, 22, Id, '');
End;

Procedure NbComboItem(Id : LongInt; S : String);
Begin
  NbItem(WinWindowFromID(NbClient, Id), S);
End;

Procedure NbComboSel(Id, V : LongInt);
Begin
  Dummy := WinSendMsg(WinWindowFromID(NbClient, Id), LM_SELECTITEM, V, 1);
End;

Function NbEntryText(Id : LongInt) : String;
Var B : Array[0..63] Of Byte;
Begin
  B[0] := 0;
  Dummy := WinQueryWindowText(WinWindowFromID(NbClient, Id), 40, LongInt(@B));
  NbEntryText := GetZ(LongInt(@B));
End;

Function NbEntry(X, YTop, W, Id : LongInt; S : String) : LongInt;
Begin
  NbEntry := NbAdd(WC_ENTRYFIELD, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN, X, YTop, W, 20, Id, S);
End;

Procedure CountryBuild;
Var K : LongInt;
Begin
  NbBusy := 1;
  Case NbTab Of
    0 :
      Begin
        NbText(0, 40, 200, 'Pays');
        NbCombo(0, 60, 240, 500);
        For K := 0 To NCty - 1 Do NbComboItem(500, CtyNames[K] + ' (' + IStr(CtyCodes[K]) + ')');
        NbComboSel(500, MaxI(0, CtyIndex(NatN[0])));
        NbText(0, 100, 200, 'Mesures');
        NbCombo(0, 120, 240, 501);
        NbComboItem(501, 'Metrique'); NbComboItem(501, 'Anglo-saxonnes');
        NbComboSel(501, NatN[1]);
        NbText(0, 166, 200, 'Separateur de liste :');
        Dummy := NbEntry(184, 164, 40, 502, NatS[0]);
      End;
    1 :
      Begin
        NbText(0, 0, 330, 'Format de l''heure :');
        Dummy := NbCheck(10, 22, 160, 510, '12 heures', NatN[2] = 0, BS_AUTORADIOBUTTON Or WS_GROUP);
        Dummy := NbCheck(10, 44, 160, 511, '24 heures', NatN[2] = 1, BS_AUTORADIOBUTTON);
        NbText(0, 84, 200, 'Avant midi (AM) :');
        Dummy := NbEntry(184, 82, 60, 512, NatS[1]);
        NbText(0, 112, 200, 'Apres midi (PM) :');
        Dummy := NbEntry(184, 110, 60, 513, NatS[2]);
        NbText(0, 140, 200, 'Separateur :');
        Dummy := NbEntry(184, 138, 40, 514, NatS[3]);
      End;
    2 :
      Begin
        NbText(0, 0, 330, 'Ordre de la date :');
        NbCombo(0, 20, 270, 520);
        NbComboItem(520, 'Mois, jour, annee (MM/JJ/AAAA)');
        NbComboItem(520, 'Jour, mois, annee (JJ/MM/AAAA)');
        NbComboItem(520, 'Annee, mois, jour (AAAA/MM/JJ)');
        NbComboSel(520, NatN[3]);
        NbText(0, 70, 200, 'Separateur :');
        Dummy := NbEntry(184, 68, 40, 521, NatS[4]);
      End;
    3 :
      Begin
        NbText(0, 2, 200, 'Separateur des milliers :');
        Dummy := NbEntry(214, 0, 40, 530, NatS[5]);
        NbText(0, 30, 200, 'Separateur decimal :');
        Dummy := NbEntry(214, 28, 40, 531, NatS[6]);
        NbText(0, 58, 200, 'Decimales :');
        NbCombo(214, 56, 60, 532);
        For K := 0 To 3 Do NbComboItem(532, IStr(K));
        NbComboSel(532, MinI(3, NatN[4]));
        Dummy := NbCheck(0, 84, 300, 533, 'Zero avant la virgule (0,5)', NatN[5] <> 0, BS_AUTOCHECKBOX);
        NbText(0, 114, 200, 'Symbole monetaire :');
        Dummy := NbEntry(214, 112, 60, 534, NatS[7]);
        NbText(0, 142, 200, 'Position du symbole :');
        NbCombo(214, 140, 100, 535);
        NbComboItem(535, NatS[7] + '1'); NbComboItem(535, '1' + NatS[7]);
        NbComboItem(535, NatS[7] + ' 1'); NbComboItem(535, '1 ' + NatS[7]);
        NbComboSel(535, NatN[6]);
      End;
    4 :
      Begin
        NbText(0, 0, 330, 'Titre :');
        Dummy := NbEntry(0, 22, 220, 540, CountryTitle);
        Dummy := NbButton(226, 20, 80, 541, 'Changer');
      End;
  End;
  If NbTab < 4 Then
  Begin
    Dummy := NbButton(0, 262, 80, 590, 'Annuler');
    Dummy := NbButton(86, 262, 90, 591, 'Par defaut');
    Dummy := NbButton(182, 262, 70, 592, 'Aide');
  End;
  NbBusy := 0;
End;

{ exemple de la page (dessine par NbPaint) }
Procedure CountryPaint(Hps, W, H : LongInt);
Var Dt : Array[0..15] Of Byte; Y : LongInt; S : String;
Begin
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Y := H - 18 - 230;
  Case NbTab Of
    0 : S := 'Exemple : 1' + NatS[0] + '2' + NatS[0] + '3';
    1 : S := 'Exemple : ' + NatTime(Dt[0], Dt[1], Dt[2]);
    2 : S := 'Exemple : ' + NatDate(Dt[4], Dt[5], Dt[6] Or (Dt[7] Shl 8));
    3 : S := 'Exemple : ' + NatMoney(123456789, False) + '   ' + NatMoney(1234550, True);
  Else
    S := '';
  End;
  If S <> '' Then GText(Hps, 40, Y, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure NbClear;
Var K : LongInt;
Begin
  For K := 0 To NbN - 1 Do
    If NbCtl[K] <> 0 Then Dummy := WinDestroyWindow(NbCtl[K]);
  NbN := 0;
End;

{ onglets du carnet courant }
Function TabCnt : LongInt;
Begin
  If NbKind = 1 Then TabCnt := 6 Else If NbKind = 2 Then TabCnt := 5 Else TabCnt := NbTabs;
End;

Function TabName(K : LongInt) : String;
Begin
  If NbKind = 1 Then TabName := MouTabName[K] Else If NbKind = 2 Then TabName := CtyTabName[K]
  Else TabName := NbTabName[K];
End;

{ --- carnet Souris : curseurs (sliders), cadres, zone d'essai --- }
Procedure SlAdd(Id, X, YTop, W, Cnt, Val : LongInt);
Begin
  If SlN >= 4 Then Exit;
  SlId[SlN] := Id; SlX[SlN] := X; SlY[SlN] := YTop; SlW[SlN] := W; SlCnt[SlN] := Cnt;
  SlVal[SlN] := MaxI(0, MinI(Cnt - 1, Val));
  Inc(SlN);
End;

Procedure GbAdd(X, YTop, W, Hh : LongInt; S : String);
Begin
  If GbN >= 4 Then Exit;
  GbX[GbN] := X; GbY[GbN] := YTop; GbW[GbN] := W; GbH[GbN] := Hh; GbS[GbN] := S;
  Inc(GbN);
End;

{ position (client) de la graduation V du curseur K ; Yc : axe }
Function SlPos(K, V : LongInt) : LongInt;
Begin
  SlPos := 40 + SlX[K] + 4 + (V * (SlW[K] - 8)) Div MaxI(1, SlCnt[K] - 1);
End;

Function SlAxis(K, H : LongInt) : LongInt;
Begin
  SlAxis := H - 18 - SlY[K] - 8;
End;

Procedure SlPaint(Hps, K, H : LongInt);
Var X1, X2, Yc, I, Tx : LongInt;
Begin
  X1 := 40 + SlX[K]; X2 := X1 + SlW[K]; Yc := SlAxis(K, H);
  FBox(Hps, X1, Yc - 2, X2, Yc + 2, CLR_WHITE, CLR_DARKGRAY);
  For I := 0 To SlCnt[K] - 1 Do
  Begin
    Tx := SlPos(K, I);
    GLn(Hps, Tx, Yc - 12, Tx, Yc - 8, CLR_BLACK);
  End;
  Tx := SlPos(K, SlVal[K]);
  FBox(Hps, Tx - 4, Yc - 8, Tx + 4, Yc + 8, CLR_PALEGRAY, CLR_BLACK);
  GLn(Hps, Tx - 3, Yc + 7, Tx + 3, Yc + 7, CLR_WHITE);
  GLn(Hps, Tx - 3, Yc - 7, Tx - 3, Yc + 7, CLR_WHITE);
  GLn(Hps, Tx, Yc - 4, Tx, Yc + 4, CLR_DARKGRAY);
  { fleches }
  FBox(Hps, X2 + 6, Yc - 6, X2 + 18, Yc + 6, CLR_PALEGRAY, CLR_BLACK);
  FBox(Hps, X2 + 19, Yc - 6, X2 + 31, Yc + 6, CLR_PALEGRAY, CLR_BLACK);
  For I := 0 To 3 Do
  Begin
    GLn(Hps, X2 + 10 + I, Yc - I, X2 + 10 + I, Yc + I, CLR_BLACK);
    GLn(Hps, X2 + 27 - I, Yc - I, X2 + 27 - I, Yc + I, CLR_BLACK);
  End;
End;

{ zone d'essai du double clic (coordonnees du client) }
Procedure TestRect(H : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Begin
  X1 := 40 + 240; X2 := X1 + 80; Y2 := H - 18 - 34; Y1 := Y2 - 70;
End;

{ fleche du pointeur, taille 1 ou 2, en (X, Y haut) : segments
  horizontaux de meme couleur }
Procedure PtrPreview(Hps, X, Y, K : LongInt);
Var R, C, N, Cur, Run, Col, Rr, Yy : LongInt;
Begin
  For R := 0 To 15 Do
  Begin
    Cur := -1; Run := 0;
    For C := 0 To 16 Do
    Begin
      Col := -1;
      If C < 16 Then
      Begin
        N := $8000 Shr C;
        If (PvB[R] And N) <> 0 Then
        Begin
          If CfgPtrInv = 0 Then Col := CLR_BLACK Else Col := CLR_WHITE;
        End
        Else If (PvW[R] And N) <> 0 Then
        Begin
          If CfgPtrInv = 0 Then Col := CLR_WHITE Else Col := CLR_BLACK;
        End;
      End;
      If Col <> Cur Then
      Begin
        If Cur <> -1 Then
          For Rr := 0 To K - 1 Do
          Begin
            Yy := Y - R * K - Rr - 1;
            GLn(Hps, X + Run * K, Yy, X + C * K - 1, Yy, Cur);
          End;
        Cur := Col; Run := C;
      End;
    End;
  End;
End;

{ dessins propres aux pages du carnet Souris }
Procedure MousePaint(Hps, W, H : LongInt);
Var K, X1, Y1, X2, Y2, Yt : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  For K := 0 To GbN - 1 Do
  Begin
    X1 := 40 + GbX[K]; X2 := X1 + GbW[K]; Y2 := H - 18 - GbY[K] - 8; Y1 := Y2 - GbH[K];
    GBox(Hps, X1, Y1, X2, Y2, CLR_DARKGRAY, DRO_OUTLINE);
    GBox(Hps, X1 + 1, Y1 - 1, X2 + 1, Y2 - 1, CLR_WHITE, DRO_OUTLINE);
    GText(Hps, X1 + 8, Y2 - 8, GbS[K], CLR_DARKBLUE, CLR_PALEGRAY);
  End;
  For K := 0 To SlN - 1 Do SlPaint(Hps, K, H);
  Case NbTab Of
    0 :
      Begin
        TestRect(H, X1, Y1, X2, Y2);
        GText(Hps, X1 + 6, Y2 + 2, 'Essai ici', CLR_DARKBLUE, CLR_PALEGRAY);
        If TestOn <> 0 Then FBox(Hps, X1, Y1, X2, Y2, CLR_DARKCYAN, CLR_BLACK)
        Else FBox(Hps, X1, Y1, X2, Y2, CLR_PALEGRAY, CLR_BLACK);
        GBox(Hps, X1 + 2, Y1 + 2, X2 - 2, Y2 - 2, CLR_WHITE, DRO_OUTLINE);
        If TestOn <> 0 Then GText(Hps, X1 + 11, Y1 + 28, 'Reussi', CLR_WHITE, CLR_DARKCYAN);
      End;
    1 :
      Begin
        { souris : boutons 1 et 2 selon la main }
        X1 := 40 + 230; Yt := H - 18 - 40;
        FBox(Hps, X1, Yt - 110, X1 + 80, Yt, CLR_WHITE, CLR_BLACK);
        FBox(Hps, X1 + 4, Yt - 40, X1 + 38, Yt - 4, CLR_PALEGRAY, CLR_BLACK);
        FBox(Hps, X1 + 42, Yt - 40, X1 + 76, Yt - 4, CLR_PALEGRAY, CLR_BLACK);
        GLn(Hps, X1 + 40, Yt, X1 + 40, Yt + 16, CLR_BLACK);
        If CfgSwap = 0 Then
        Begin
          GText(Hps, X1 + 17, Yt - 30, '1', CLR_BLACK, CLR_PALEGRAY); GText(Hps, X1 + 55, Yt - 30, '2', CLR_BLACK, CLR_PALEGRAY);
        End
        Else
        Begin
          GText(Hps, X1 + 17, Yt - 30, '2', CLR_BLACK, CLR_PALEGRAY); GText(Hps, X1 + 55, Yt - 30, '1', CLR_BLACK, CLR_PALEGRAY);
        End;
      End;
    3 :
      Begin
        GText(Hps, 40 + 220, H - 18 - 36, 'Apercu :', CLR_DARKBLUE, CLR_PALEGRAY);
        Rc[0] := 40 + 220; Rc[1] := H - 18 - 130; Rc[2] := 40 + 320; Rc[3] := H - 18 - 40;
        Dummy := WinFillRect(Hps, LongInt(@Rc), DeskColor);
        GBox(Hps, Rc[0], Rc[1], Rc[2], Rc[3], CLR_BLACK, DRO_OUTLINE);
        PtrPreview(Hps, 40 + 250, H - 18 - 60, 1 + CfgPtrBig);
      End;
  End;
End;

Procedure MouseBuild;
Var B, Hw, K_Dbl : LongInt;
Begin
  Case NbTab Of
    0 :
      Begin
        GbAdd(0, 0, 334, 120, 'Double clic');
        K_Dbl := 4;
        For B := 0 To 8 Do
          If DblSlide[B] >= CfgDbl Then K_Dbl := B;
        SlAdd(400, 10, 40, 180, 9, K_Dbl);
        NbText(10, 70, 60, 'Lent'); NbText(150, 70, 60, 'Rapide');
        GbAdd(0, 140, 260, 90, 'Vitesse de deplacement');
        SlAdd(401, 10, 180, 180, 9, CfgSpeed);
        NbText(10, 210, 60, 'Lent'); NbText(150, 210, 60, 'Rapide');
        Dummy := NbButton(0, 262, 80, 470, 'Annuler');
        Dummy := NbButton(86, 262, 90, 471, 'Par defaut');
        Dummy := NbButton(182, 262, 70, 472, 'Aide');
      End;
    1 :
      Begin
        NbText(0, 0, 330, 'Configuration des boutons :');
        Dummy := NbCheck(10, 28, 200, 420, 'droitier', CfgSwap = 0, BS_AUTORADIOBUTTON Or WS_GROUP);
        Dummy := NbCheck(10, 52, 200, 421, 'gaucher', CfgSwap <> 0, BS_AUTORADIOBUTTON);
        NbText(0, 160, 220, 'Bouton 1 : choisir, ouvrir');
        NbText(0, 180, 220, 'Bouton 2 : menus, glisser');
      End;
    2 :
      Begin
        NbText(0, 0, 330, 'Liste des fenetres :');
        Dummy := NbCheck(10, 20, 320, 410, 'clic du bouton 3 (milieu)', CfgMapList = 0, BS_AUTORADIOBUTTON Or WS_GROUP);
        Dummy := NbCheck(10, 42, 320, 411, 'double clic du bouton 1 sur le bureau', CfgMapList = 1, BS_AUTORADIOBUTTON);
        Dummy := NbCheck(10, 64, 320, 412, 'aucun', CfgMapList = 2, BS_AUTORADIOBUTTON);
        NbText(0, 96, 330, 'Menus contextuels :');
        Dummy := NbCheck(10, 116, 320, 413, 'clic du bouton 2', CfgMapMenu = 0, BS_AUTORADIOBUTTON Or WS_GROUP);
        Dummy := NbCheck(10, 138, 320, 414, 'Maj + clic du bouton 1', CfgMapMenu <> 0, BS_AUTORADIOBUTTON);
        NbText(0, 170, 330, 'Glisser-deposer :');
        Dummy := NbCheck(10, 190, 320, 415, 'bouton 2 (et bouton 1)', CfgMapDrag = 0, BS_AUTORADIOBUTTON Or WS_GROUP);
        Dummy := NbCheck(10, 212, 320, 416, 'bouton 1 seulement', CfgMapDrag <> 0, BS_AUTORADIOBUTTON);
      End;
    3 :
      Begin
        NbText(0, 0, 200, 'Taille du pointeur :');
        Dummy := NbCheck(10, 20, 200, 450, 'normale (16 x 16)', CfgPtrBig = 0, BS_AUTORADIOBUTTON Or WS_GROUP);
        Dummy := NbCheck(10, 42, 200, 451, 'grande (32 x 32)', CfgPtrBig <> 0, BS_AUTORADIOBUTTON);
        NbText(0, 76, 200, 'Couleurs :');
        Dummy := NbCheck(10, 96, 200, 452, 'blanc, bord noir', CfgPtrInv = 0, BS_AUTORADIOBUTTON Or WS_GROUP);
        Dummy := NbCheck(10, 118, 200, 453, 'noir, bord blanc', CfgPtrInv <> 0, BS_AUTORADIOBUTTON);
      End;
    4 :
      Begin
        Dummy := NbCheck(0, 0, 320, 430, 'Pointeur comete (trainee du pointeur)', CfgComet <> 0, BS_AUTOCHECKBOX);
        GbAdd(0, 40, 260, 90, 'Longueur de la trainee');
        SlAdd(440, 10, 80, 150, 6, CfgCometLen - 1);
        NbText(10, 110, 60, 'Courte'); NbText(130, 110, 60, 'Longue');
      End;
    5 :
      Begin
        NbText(0, 0, 330, 'Titre de l''objet :');
        Hw := NbAdd(WC_ENTRYFIELD, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN, 0, 22, 220, 20, 460, MouseTitle);
        Dummy := NbButton(230, 21, 90, 461, 'Appliquer');
        B := 0;
        If MouH = 0 Then Dummy := MouOpen(0, LongInt(@MouH));
        If MouH <> 0 Then Dummy := MouGetNumButtons(LongInt(@B), MouH);
        If B > 0 Then NbText(0, 70, 330, 'Souris PS/2 a ' + IStr(B And $FFFF) + ' boutons.')
        Else NbText(0, 70, 330, 'Pas de souris.');
        NbText(0, 94, 330, 'Double clic : ' + IStr(CfgDbl) + ' ms ; vitesse ' + IStr(CfgSpeed + 1) + ' sur 9.');
      End;
  End;
End;

{ selection courante de la liste des resolutions }
Procedure NbSelectMode(W, H, B : LongInt);
Var K, Lb : LongInt;
Begin
  Lb := WinWindowFromID(NbClient, 300);
  For K := 0 To NbModeN - 1 Do
    If (NbMW[K] = W) And (NbMH[K] = H) And (NbMB[K] = B) Then Dummy := WinSendMsg(Lb, LM_SELECTITEM, K, 1);
End;

Procedure NbBuild;
Var Lb, K, Sel : LongInt; M : Array[0..3] Of LongInt; Vb : Array[0..31] Of LongInt; S : String;
Begin
  NbClear;
  NbLblN := 0; SlN := 0; GbN := 0; SlDrag := -1;
  If NbKind = 1 Then
  Begin
    MouseBuild;
    Dummy := WinInvalidateRect(NbClient, 0, 1);
    Exit;
  End;
  If NbKind = 2 Then
  Begin
    CountryBuild;
    Dummy := WinInvalidateRect(NbClient, 0, 1);
    Exit;
  End;
  Case NbTab Of
    0 :
      Begin
        Vb[0] := 0;
        If VioQueryVbe(LongInt(@Vb)) <> 0 Then
          S := 'VESA ' + IStr((Vb[0] Shr 8) And 255) + '.' + IStr(Vb[0] And 255) + ', ' + IStr(Vb[1]) + ' Ko'
        Else S := 'VGA';
        NbText(0, 0, 330, 'Ecran choisi : ' + S);
        NbText(0, 24, 330, 'Resolution de l''ecran :');
        Lb := NbList(0, 44, 300, 124, 300);
        LoadModes;
        For K := 0 To NbModeN - 1 Do
          NbItem(Lb, IStr(NbMW[K]) + ' x ' + IStr(NbMH[K]) + ' x ' + ColorsOf(NbMB[K]));
        M[0] := 640; M[1] := 480; M[2] := 4;
        Dummy := WinQueryScreenMode(LongInt(@M));
        NbSelectMode(M[0], M[1], M[2]);
        NbText(0, 172, 330, 'largeur x hauteur x nombre de couleurs');
        NbText(0, 196, 330, 'Frequence de balayage :');
        Lb := NbList(0, 216, 120, 36, 301);
        NbItem(Lb, '60');
        Dummy := WinSendMsg(Lb, LM_SELECTITEM, 0, 1);
        NbText(130, 226, 200, 'frequence verticale en Hz');
        Dummy := NbButton(0, 262, 80, 310, 'Appliquer');
        Dummy := NbButton(86, 262, 80, 311, 'Annuler');
        Dummy := NbButton(172, 262, 80, 312, 'Par defaut');
        Dummy := NbButton(258, 262, 80, 313, 'Capacites');
      End;
    1 :
      Begin
        NbText(0, 0, 330, 'Demander une confirmation avant :');
        Dummy := NbCheck(10, 28, 320, 320, 'la suppression d''un dossier', CfgConf[0] <> 0, BS_AUTOCHECKBOX);
        Dummy := NbCheck(10, 52, 320, 321, 'la suppression d''un fichier ou d''un raccourci', CfgConf[1] <> 0,
                         BS_AUTOCHECKBOX);
        Dummy := NbCheck(10, 76, 320, 322, 'l''arret du systeme', CfgConf[2] <> 0, BS_AUTOCHECKBOX);
      End;
    2 :
      Begin
        NbText(0, 0, 330, 'Quand un objet du meme nom existe deja :');
        Dummy := NbCheck(10, 28, 320, 330, 'ajouter un numero au nom', CfgTitle = 0, BS_AUTORADIOBUTTON Or WS_GROUP);
        Dummy := NbCheck(10, 52, 320, 331, 'avertir et ne pas creer l''objet', CfgTitle <> 0, BS_AUTORADIOBUTTON);
      End;
    3 :
      Begin
        NbText(0, 0, 330, 'Ouverture d''un objet deja ouvert :');
        Dummy := NbCheck(10, 28, 320, 340, 'afficher la fenetre existante', CfgWin = 0, BS_AUTORADIOBUTTON Or WS_GROUP);
        Dummy := NbCheck(10, 52, 320, 341, 'ouvrir une nouvelle fenetre', CfgWin <> 0, BS_AUTORADIOBUTTON);
      End;
    4 :
      Begin
        NbText(0, 0, 330, 'Souris - delai du double clic :');
        Lb := NbList(10, 22, 160, 96, 350);
        Sel := 2;
        For K := 0 To 4 Do
        Begin
          NbItem(Lb, IStr(DblTab[K]) + ' ms');
          If DblTab[K] = CfgDbl Then Sel := K;
        End;
        Dummy := WinSendMsg(Lb, LM_SELECTITEM, Sel, 1);
        Dummy := NbCheck(10, 128, 320, 351, 'boutons inverses (gaucher)', CfgSwap <> 0, BS_AUTOCHECKBOX);
      End;
    5 :
      Begin
        NbText(0, 0, 330, 'Logo affiche au demarrage du bureau :');
        Dummy := NbCheck(10, 28, 320, 360, 'aucun', CfgLogo = 0, BS_AUTORADIOBUTTON Or WS_GROUP);
        Dummy := NbCheck(10, 52, 320, 361, '3 secondes', CfgLogo = 3, BS_AUTORADIOBUTTON);
        Dummy := NbCheck(10, 76, 320, 362, '5 secondes', CfgLogo = 5, BS_AUTORADIOBUTTON);
        Dummy := NbCheck(10, 100, 320, 363, 'jusqu''a un clic', CfgLogo < 0, BS_AUTORADIOBUTTON);
      End;
    6 :
      Begin
        NbText(0, 0, 330, 'Couleur du fond du bureau :');
        Lb := NbList(10, 22, 200, 196, 370);
        For K := 0 To 15 Do NbItem(Lb, ClrName[K]);
        Dummy := WinSendMsg(Lb, LM_SELECTITEM, CfgClr, 1);
      End;
    7 :
      Begin
        NbText(0, 0, 330, 'Langue des programmes (SET LANGUAGE=) :');
        Lb := NbList(10, 22, 220, 168, 380);
        For K := 0 To NLang - 1 Do NbItem(Lb, LangNames[K]);
        Dummy := WinSendMsg(Lb, LM_SELECTITEM, CurLang, 1);
        Dummy := WinSetFocus(HWND_DESKTOP, Lb);
        NbText(0, 200, 330, 'La langue est gardee dans CONFIG.SYS');
        NbText(0, 218, 330, 'et sert aux programmes lances ensuite');
        NbText(0, 236, 330, '(CMD.EXE et les commandes).');
      End;
  End;
  Dummy := WinInvalidateRect(NbClient, 0, 1);
End;

Procedure NbSelect(T : LongInt);
Begin
  If (T < 0) Or (T >= TabCnt) Or (T = NbTab) Then Exit;
  NbTab := T;
  NbBuild;
End;

{ rectangle de l'onglet T (client de largeur W, hauteur H) }
Procedure TabRect(T, W, H : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Begin
  X1 := W - 116 + T * 2; X2 := W - 8;
  Y2 := H - 10 - T * 28; Y1 := Y2 - 24;
End;

Procedure NbPaint(H : LongInt);
Var Hps, K, X1, Y1, X2, Y2, Pr : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  Hps := WinBeginPaint(H, 0, LongInt(@Rc));
  If Hps = 0 Then Exit;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
  Pr := Rc[2] - 120;
  { pages (avec l'epaisseur du carnet) et reliure a spirale }
  FBox(Hps, 30, 28, Pr + 4, Rc[3] - 4, CLR_PALEGRAY, CLR_DARKGRAY);
  FBox(Hps, 27, 31, Pr + 1, Rc[3] - 7, CLR_PALEGRAY, CLR_DARKGRAY);
  FBox(Hps, 24, 34, Pr - 2, Rc[3] - 10, CLR_PALEGRAY, CLR_BLACK);
  K := 40;
  While K < Rc[3] - 16 Do
  Begin
    GBox(Hps, 6, K, 30, K + 6, CLR_DARKGRAY, DRO_OUTLINE);
    GLn(Hps, 7, K + 5, 29, K + 5, CLR_WHITE);
    K := K + 16;
  End;
  { onglets }
  For K := 0 To TabCnt - 1 Do
  Begin
    TabRect(K, Rc[2], Rc[3], X1, Y1, X2, Y2);
    If K = NbTab Then
    Begin
      FBox(Hps, Pr - 3, Y1, X2, Y2, CLR_PALEGRAY, CLR_BLACK);
      GLn(Hps, Pr - 2, Y1 + 1, Pr - 2, Y2 - 1, CLR_PALEGRAY);
    End
    Else FBox(Hps, X1, Y1, X2, Y2, CLR_PALEGRAY, CLR_DARKGRAY);
    GLn(Hps, X1 + 1, Y2 - 1, X2 - 1, Y2 - 1, CLR_WHITE);
    GText(Hps, X1 + 6, Y1 + 4, TabName(K), CLR_BLACK, CLR_PALEGRAY);
  End;
  GText(Hps, Pr - 210, 8, TabName(NbTab) + ' - Page 1 sur 1', CLR_BLACK, CLR_PALEGRAY);
  If NbKind = 1 Then MousePaint(Hps, Rc[2], Rc[3]);
  If NbKind = 2 Then CountryPaint(Hps, Rc[2], Rc[3]);
  { textes de la page }
  For K := 0 To NbLblN - 1 Do
    GText(Hps, 40 + NbLblX[K], Rc[3] - 18 - NbLblY[K] - 16, NbLblS[K], CLR_DARKBLUE, CLR_PALEGRAY);
  Dummy := WinEndPaint(Hps);
End;

Function NbChecked(Id : LongInt) : Boolean;
Begin
  NbChecked := WinSendMsg(WinWindowFromID(NbClient, Id), BM_QUERYCHECK, 0, 0) <> 0;
End;

Procedure CountryControl(Id, Code : LongInt);
Var Sel : LongInt; Changed : Boolean;
Begin
  If NbBusy <> 0 Then Exit;
  Changed := False;
  Case Id Of
    500 : If Code = 3 Then
          Begin
            Sel := WinSendMsg(WinWindowFromID(NbClient, 500), LM_QUERYSELECTION, -1, 0);
            If (Sel >= 0) And (Sel < NCty) And (CtyCodes[Sel] <> NatN[0]) Then
            Begin
              CountryApply(CtyCodes[Sel]);
              NbBuild;
              Dummy := WinSetFocus(HWND_DESKTOP, WinWindowFromID(NbClient, 500));
              Exit;
            End;
          End;
    501, 520, 532, 535 :
      If Code = 3 Then
      Begin
        Sel := WinSendMsg(WinWindowFromID(NbClient, Id), LM_QUERYSELECTION, -1, 0);
        If Sel >= 0 Then
        Begin
          Case Id Of
            501 : NatN[1] := Sel;
            520 : NatN[3] := Sel;
            532 : NatN[4] := Sel;
          Else
            NatN[6] := Sel;
          End;
          Changed := True;
        End;
      End;
    510, 511 :
      Begin
        If NbChecked(511) Then NatN[2] := 1 Else NatN[2] := 0;
        Changed := True;
      End;
    533 :
      Begin
        NatN[5] := Ord(NbChecked(533));
        Changed := True;
      End;
    502, 512, 513, 514, 521, 530, 531, 534 :
      If Code = 4 Then
      Begin
        Case Id Of
          502 : NatS[0] := NbEntryText(502);
          512 : NatS[1] := NbEntryText(512);
          513 : NatS[2] := NbEntryText(513);
          514 : NatS[3] := NbEntryText(514);
          521 : NatS[4] := NbEntryText(521);
          530 : NatS[5] := NbEntryText(530);
          531 : NatS[6] := NbEntryText(531);
        Else
          NatS[7] := NbEntryText(534);
        End;
        Changed := True;
      End;
  End;
  If Changed Then
  Begin
    CountrySave;
    Dummy := WinInvalidateRect(NbClient, 0, 1);
  End;
End;

Procedure CountryCommand(Id : LongInt);
Var K, Sel : LongInt; S : String;
Begin
  Case Id Of
    590 :
      Begin
        For K := 0 To 6 Do NatN[K] := UndoN[K];
        For K := 0 To 7 Do NatS[K] := UndoS[K];
        CountrySave;
        SetCfgLine('COUNTRY=', 'COUNTRY=' + Copy(IStr(1000 + NatN[0]), 2, 3) + ',C:\COUNTRY.SYS');
        NbBuild;
      End;
    591 :
      Begin
        CountryApply(NatN[0]);
        NbBuild;
      End;
    592 : ShowMsg('Pays : codes et formats du pays (ligne COUNTRY= de CONFIG.SYS). Heure, Date, Nombres : formats ' +
                  'utilises par les programmes de Presentation Manager (OS2.INI, PM_National). Annuler : valeurs a ' +
                  'l''ouverture du carnet ; Par defaut : valeurs du pays.', 'Aide - Pays', MB_OK Or MB_INFORMATION);
    541 :
      Begin
        S := NbEntryText(540);
        If S <> '' Then
        Begin
          CountryTitle := S;
          CountrySave;
          Dummy := WinSetWindowText(WinQueryWindow(NbClient, QW_PARENT), Z(CountryTitle + ' - Parametres'));
          Sel := FindView(VK_SETUP, '');
          If Sel >= 0 Then
          Begin
            Populate(Sel);
            Dummy := WinInvalidateRect(Vw(Sel)^.Client, 0, 1);
          End;
        End;
      End;
  End;
End;

Procedure NbControl(Id, Code : LongInt);
Var Sel : LongInt;
Begin
  If NbKind = 2 Then
  Begin
    CountryControl(Id, Code);
    Exit;
  End;
  Case Id Of
    380 : If (Code = LN_SELECT) Or (Code = LN_ENTER) Then
          Begin
            Sel := WinSendMsg(WinWindowFromID(NbClient, 380), LM_QUERYSELECTION, -1, 0);
            If (Sel >= 0) And (Sel < NLang) And (Sel <> CurLang) Then SetLanguage(Sel);
          End;
    300 : If Code = LN_ENTER Then
          Begin
            Sel := WinSendMsg(WinWindowFromID(NbClient, 300), LM_QUERYSELECTION, -1, 0);
            If (Sel >= 0) And (Sel < NbModeN) Then ApplyResolution(NbMW[Sel], NbMH[Sel], NbMB[Sel]);
          End;
    320, 321, 322 :
      Begin
        If NbChecked(Id) Then CfgConf[Id - 320] := 1 Else CfgConf[Id - 320] := 0;
        SaveSettings;
      End;
    330, 331 :
      Begin
        If NbChecked(331) Then CfgTitle := 1 Else CfgTitle := 0;
        SaveSettings;
      End;
    340, 341 :
      Begin
        If NbChecked(341) Then CfgWin := 1 Else CfgWin := 0;
        SaveSettings;
      End;
    350 : If (Code = LN_SELECT) Or (Code = LN_ENTER) Then
          Begin
            Sel := WinSendMsg(WinWindowFromID(NbClient, 350), LM_QUERYSELECTION, -1, 0);
            If (Sel >= 0) And (Sel <= 4) Then CfgDbl := DblTab[Sel];
            ApplySettings; SaveSettings;
          End;
    351 :
      Begin
        If NbChecked(351) Then CfgSwap := 1 Else CfgSwap := 0;
        ApplySettings; SaveSettings;
      End;
    360, 361, 362, 363 :
      Begin
        If NbChecked(361) Then CfgLogo := 3
        Else If NbChecked(362) Then CfgLogo := 5
        Else If NbChecked(363) Then CfgLogo := -1
        Else CfgLogo := 0;
        SaveSettings;
      End;
    { carnet Souris }
    420, 421 :
      Begin
        If NbChecked(421) Then CfgSwap := 1 Else CfgSwap := 0;
        ApplySettings; SaveSettings;
        Dummy := WinInvalidateRect(NbClient, 0, 1);
      End;
    410, 411, 412 :
      Begin
        If NbChecked(411) Then CfgMapList := 1 Else If NbChecked(412) Then CfgMapList := 2 Else CfgMapList := 0;
        SaveSettings;
      End;
    413, 414 :
      Begin
        If NbChecked(414) Then CfgMapMenu := 1 Else CfgMapMenu := 0;
        SaveSettings;
      End;
    415, 416 :
      Begin
        If NbChecked(416) Then CfgMapDrag := 1 Else CfgMapDrag := 0;
        SaveSettings;
      End;
    450, 451, 452, 453 :
      Begin
        If NbChecked(451) Then CfgPtrBig := 1 Else CfgPtrBig := 0;
        If NbChecked(453) Then CfgPtrInv := 1 Else CfgPtrInv := 0;
        ApplyPointer; SaveSettings;
        Dummy := WinInvalidateRect(NbClient, 0, 1);
      End;
    430 :
      Begin
        If NbChecked(430) Then CfgComet := 1 Else CfgComet := 0;
        ApplyPointer; SaveSettings;
      End;
    370 : If (Code = LN_SELECT) Or (Code = LN_ENTER) Then
          Begin
            Sel := WinSendMsg(WinWindowFromID(NbClient, 370), LM_QUERYSELECTION, -1, 0);
            If (Sel >= 0) And (Sel <= 15) Then CfgClr := Sel;
            ApplySettings; SaveSettings;
            SetDeskColor;
            If Desk <> 0 Then Dummy := WinInvalidateRect(Desk, 0, 1);
          End;
  End;
End;

Procedure NbCommand(Id : LongInt);
Var Sel : LongInt; M : Array[0..3] Of LongInt; Vb : Array[0..31] Of LongInt; S : String;
Begin
  If NbKind = 2 Then
  Begin
    CountryCommand(Id);
    Exit;
  End;
  Case Id Of
    310 :
      Begin
        Sel := WinSendMsg(WinWindowFromID(NbClient, 300), LM_QUERYSELECTION, -1, 0);
        If (Sel >= 0) And (Sel < NbModeN) Then ApplyResolution(NbMW[Sel], NbMH[Sel], NbMB[Sel]);
      End;
    311 :
      Begin
        M[0] := 640; M[1] := 480; M[2] := 4;
        Dummy := WinQueryScreenMode(LongInt(@M));
        NbSelectMode(M[0], M[1], M[2]);
      End;
    312 : NbSelectMode(640, 480, 4);
    470, 471 :
      Begin
        If Id = 470 Then
        Begin
          CfgDbl := UndoDbl; CfgSpeed := UndoSpeed;
        End
        Else
        Begin
          CfgDbl := 500; CfgSpeed := 3;
        End;
        ApplySettings; SaveSettings;
        NbBuild;
      End;
    472 : ShowMsg('Double clic : faites glisser le curseur, puis double-cliquez dans la zone d''essai (elle change ' +
                  'de couleur si le double clic est reconnu). Vitesse de deplacement : distance parcourue par le ' +
                  'pointeur pour un meme mouvement de la souris.', 'Aide - Souris', MB_OK Or MB_INFORMATION);
    461 :
      Begin
        Vb[0] := 0;
        Dummy := WinQueryWindowText(WinWindowFromID(NbClient, 460), 40, LongInt(@Vb));
        S := GetZ(LongInt(@Vb));
        If S <> '' Then
        Begin
          MouseTitle := S;
          SaveSettings;
          Dummy := WinSetWindowText(WinQueryWindow(NbClient, QW_PARENT), Z(MouseTitle + ' - Parametres'));
          Sel := FindView(VK_SETUP, '');
          If Sel >= 0 Then
          Begin
            Populate(Sel);
            Dummy := WinInvalidateRect(Vw(Sel)^.Client, 0, 1);
          End;
        End;
      End;
    313 :
      Begin
        Vb[0] := 0;
        If VioQueryVbe(LongInt(@Vb)) <> 0 Then
          S := 'Carte VESA (VBE ' + IStr((Vb[0] Shr 8) And 255) + '.' + IStr(Vb[0] And 255) + ') : ' +
               GetZ(LongInt(@Vb) + 8) + '. Memoire video : ' + IStr(Vb[1]) + ' Ko. ' + IStr(NbModeN) +
               ' resolutions (VGA et VESA a memoire lineaire, 256 a 16 777 216 couleurs).'
        Else S := 'Carte VGA sans BIOS VESA : 640 x 480 x 16 couleurs.';
        ShowMsg(S, 'Capacites de l''ecran', MB_OK Or MB_INFORMATION);
      End;
  End;
End;

{ valeur choisie sur le curseur K }
Procedure SlCommit(K : LongInt);
Begin
  Case SlId[K] Of
    400 : CfgDbl := DblSlide[SlVal[K]];
    401 : CfgSpeed := SlVal[K];
    440 : CfgCometLen := SlVal[K] + 1;
  End;
  ApplySettings; SaveSettings;
End;

Procedure SlSet(K, V : LongInt; Commit : Boolean);
Begin
  V := MaxI(0, MinI(SlCnt[K] - 1, V));
  If V <> SlVal[K] Then
  Begin
    SlVal[K] := V;
    Dummy := WinInvalidateRect(NbClient, 0, 1);
  End;
  If Commit Then SlCommit(K);
End;

{ graduation la plus proche de x (client) sur le curseur K }
Function SlFromX(K, X : LongInt) : LongInt;
Var X1 : LongInt;
Begin
  X1 := 40 + SlX[K] + 4;
  SlFromX := ((X - X1) * (SlCnt[K] - 1) + (SlW[K] - 8) Div 2) Div MaxI(1, SlW[K] - 8);
End;

{ clic sur un curseur (vrai si traite) }
Function SlClick(X, Y, H : LongInt) : Boolean;
Var K, X1, X2, Yc : LongInt;
Begin
  SlClick := False;
  For K := 0 To SlN - 1 Do
  Begin
    X1 := 40 + SlX[K]; X2 := X1 + SlW[K]; Yc := SlAxis(K, H);
    If (Y >= Yc - 12) And (Y <= Yc + 12) Then
    Begin
      If (X >= X1 - 4) And (X <= X2 + 4) Then
      Begin
        SlDrag := K;
        SlSet(K, SlFromX(K, X), False);
        Dummy := WinSetCapture(HWND_DESKTOP, NbClient);
        SlClick := True;
      End
      Else If (X >= X2 + 6) And (X <= X2 + 18) Then
      Begin
        SlSet(K, SlVal[K] - 1, True);
        SlClick := True;
      End
      Else If (X >= X2 + 19) And (X <= X2 + 31) Then
      Begin
        SlSet(K, SlVal[K] + 1, True);
        SlClick := True;
      End;
    End;
  End;
End;

Function NotebookProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var V, X, Y, K, X1, Y1, X2, Y2, Fs, Vk : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  NotebookProc := 0;
  V := ViewOf(H);
  If (V < 0) And (Msg = WM_CREATE) And (Creating >= 0) Then
  Begin
    Vw(Creating)^.Client := H;
    NbClient := H; NbN := 0;
    Exit;
  End;
  Case Msg Of
    WM_SIZE : If NbN = 0 Then NbBuild;
    WM_PAINT : NbPaint(H);
    WM_BUTTON1DOWN :
      Begin
        NotebookProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        If SlClick(X, Y, Rc[3]) Then
        Begin
          NotebookProc := 1;
          Exit;
        End;
        For K := 0 To TabCnt - 1 Do
        Begin
          TabRect(K, Rc[2], Rc[3], X1, Y1, X2, Y2);
          If (X >= X1) And (X < X2) And (Y >= Y1) And (Y < Y2) Then NbSelect(K);
        End;
        NotebookProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        If (SlDrag >= 0) And (SlDrag < SlN) Then SlSet(SlDrag, SlFromX(SlDrag, S16(Mp1)), False);
        NotebookProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_BUTTON1UP :
      Begin
        If (SlDrag >= 0) And (SlDrag < SlN) Then
        Begin
          Dummy := WinSetCapture(HWND_DESKTOP, 0);
          SlSet(SlDrag, SlFromX(SlDrag, S16(Mp1)), True);
        End;
        SlDrag := -1;
        NotebookProc := 1;
      End;
    WM_BUTTON1DBLCLK :
      Begin
        { zone d'essai du double clic }
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        TestRect(Rc[3], X1, Y1, X2, Y2);
        If (NbKind = 1) And (NbTab = 0) And (X >= X1) And (X < X2) And (Y >= Y1) And (Y < Y2) Then
        Begin
          TestOn := 1 - TestOn;
          Dummy := WinInvalidateRect(H, 0, 1);
        End;
        NotebookProc := 1;
      End;
    WM_CONTROL : NbControl(Lo16(Mp1), Hi16(Mp1));
    WM_COMMAND : NbCommand(Lo16(Mp1));
    WM_CHAR :
      Begin
        Fs := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fs And KC_KEYUP) = 0) And ((Fs And KC_VIRTUALKEY) <> 0) And (Vk = VK_PAGEDOWN) Then
          NbSelect((NbTab + 1) Mod TabCnt)
        Else If ((Fs And KC_KEYUP) = 0) And ((Fs And KC_VIRTUALKEY) <> 0) And (Vk = VK_PAGEUP) Then
          NbSelect((NbTab + TabCnt - 1) Mod TabCnt)
        Else If ((Fs And KC_KEYUP) = 0) And ((Fs And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) And (V >= 0) Then
          CloseView(V)
        Else NotebookProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE :
      If V >= 0 Then
      Begin
        NbN := 0; NbClient := 0;
        CloseView(V);
      End;
    WM_DESTROY :
      Begin
        NbN := 0; NbClient := 0;
      End;
  Else
    NotebookProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ carnet Kind (0 : Systeme, 1 : Souris, 2 : Pays) ; un seul carnet ouvert
  a la fois }
Procedure OpenNb(Kind, Tab : LongInt);
Var V, K : LongInt; P, T : String;
Begin
  If Kind = 1 Then P := 'SOURIS' Else If Kind = 2 Then P := 'PAYS' Else P := '';
  V := FindView(VK_NOTE, P);
  If V >= 0 Then
  Begin
    ActivateView(V);
    NbSelect(Tab);
    Exit;
  End;
  For K := 0 To 2 Do
  Begin
    If K = 0 Then T := '' Else If K = 1 Then T := 'SOURIS' Else T := 'PAYS';
    If T <> P Then
    Begin
      V := FindView(VK_NOTE, T);
      If V >= 0 Then CloseView(V);
    End;
  End;
  If Kind = 1 Then T := MouseTitle + ' - Parametres' Else If Kind = 2 Then T := CountryTitle + ' - Parametres'
  Else T := 'Systeme - Parametres';
  V := NewView(VK_NOTE, P, T);
  If V < 0 Then Exit;
  NbKind := Kind; NbTab := Tab; NbN := 0; SlN := 0; GbN := 0; SlDrag := -1; TestOn := 0;
  UndoDbl := CfgDbl; UndoSpeed := CfgSpeed;
  For K := 0 To 6 Do UndoN[K] := NatN[K];
  For K := 0 To 7 Do UndoS[K] := NatS[K];
  If Not OpenFrame(V, 'WPNotebook', FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON, MaxI(0, (ScrW - 500) Div 2),
                   MaxI(0, (ScrH - 440) Div 2), 500, 440) Then Exit;
  If NbN = 0 Then NbBuild;
End;

Procedure OpenNotebook(Tab : LongInt);
Begin
  OpenNb(0, Tab);
End;

{ --- logo du demarrage --- }
Function LogoProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  LogoProc := 0;
  Case Msg Of
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, LongInt(@Rc));
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_DARKBLUE);
        FBox(Hps, 4, 4, Rc[2] - 5, Rc[3] - 5, CLR_DARKBLUE, CLR_WHITE);
        FBox(Hps, 30, 60, 110, 140, CLR_RED, CLR_WHITE);
        FBox(Hps, 50, 80, 90, 120, CLR_DARKBLUE, CLR_WHITE);
        GText(Hps, 130, 110, 'OS/2-0', CLR_WHITE, CLR_DARKBLUE);
        GText(Hps, 130, 86, 'Workplace Shell', CLR_YELLOW, CLR_DARKBLUE);
        GText(Hps, 130, 62, 'version 0.1', CLR_WHITE, CLR_DARKBLUE);
        Dummy := WinEndPaint(Hps);
      End;
    WM_TIMER, WM_BUTTON1DOWN, WM_CHAR :
      Begin
        Dummy := WinStopTimer(Hab, H, 7);
        Dummy := WinDestroyWindow(H);
        LogoH := 0;
        LogoProc := 1;
      End;
  Else
    LogoProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Procedure ShowLogo;
Begin
  If CfgLogo = 0 Then Exit;
  LogoH := WinCreateWindow(HWND_DESKTOP, Z('WPLogo'), Z2('Logo'), WS_VISIBLE, (ScrW - 320) Div 2, (ScrH - 200) Div 2,
                           320, 200, 0, HWND_TOP, 9, 0, 0);
  If (LogoH <> 0) And (CfgLogo > 0) Then Dummy := WinStartTimer(Hab, LogoH, 7, CfgLogo * 1000);
  If LogoH <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, LogoH);
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
    WM_SYSVALUECHANGED :
      { taille de l'ecran changee par l'hote (VirtualBox) : le bureau suit }
      If (H = Desk) And (Mp1 = 20) Then ScreenResized;
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
        { correspondances (carnet Souris) : Maj + clic du bouton 1 = menu }
        If (CfgMapMenu <> 0) And ((Hi16(Mp2) And KC_SHIFT) <> 0) Then
        Begin
          ContextMenu(V, K, X, Y);
          ViewProc := 1;
          Exit;
        End;
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
        If K >= 0 Then OpenItem(K)
        Else If (CfgMapList = 1) And (Vw(V)^.Kind = VK_DESK) Then OpenWinList;
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
        { correspondances : glisser avec le bouton 1 seulement }
        If (K >= 0) And (CfgMapDrag = 0) Then
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
    WM_BUTTON3CLICK :
      Begin
        { correspondances : liste des fenetres }
        If CfgMapList = 0 Then OpenWinList;
        ViewProc := 1;
      End;
    WM_BUTTON2CLICK :
      Begin
        If (NoMenu = 0) And (CfgMapMenu = 0) Then
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

{ programme de PM (jeux, Audio numerique) : il s'execute dans la session
  de Presentation Manager, en meme temps que le bureau }
Procedure RunPm(P, Params : String);
Var Res : Array[0..1] Of LongInt; Rc : LongInt;
Begin
  { arguments : programme, nul, parametres, nul, nul }
  PutZ(LongInt(@ArgBuf), P);
  PutZ(LongInt(@ArgBuf) + Length(P) + 1, Params);
  WrB(LongInt(@ArgBuf) + Length(P) + Length(Params) + 2, 0);
  PutZ(LongInt(@NameZ2), P);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), LongInt(@NameZ2));
  If Rc <> 0 Then
    ShowMsg('SYS1041: Impossible de lancer ' + P + ' (erreur ' + IStr(Rc) + ').', 'Bureau', MB_OK Or MB_ERROR);
End;

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

{ resolution "LxHxB" (largeur, hauteur, bits par pel) ; faux si la
  chaine n'est pas valable }
Function ParseRes(S : String; Var W, H, B : LongInt) : Boolean;
Var P, C : LongInt;
Begin
  ParseRes := False;
  S := UpStr(S);
  P := Pos('X', S);
  If P < 2 Then Exit;
  Val(Copy(S, 1, P - 1), W, C);
  If C <> 0 Then Exit;
  S := Copy(S, P + 1, 255);
  P := Pos('X', S);
  If P < 2 Then Exit;
  Val(Copy(S, 1, P - 1), H, C);
  If C <> 0 Then Exit;
  Val(Copy(S, P + 1, 255), B, C);
  If C <> 0 Then Exit;
  ParseRes := (W >= 320) And (H >= 200) And (B >= 1);
End;

{ resolution de l'ecran : OS2.INI (PM_Display, RESOLUTION), sinon
  SET PMRESOLUTION=1024x768x16 dans CONFIG.SYS ; appliquee par PMWIN a
  la premiere file de messages (WINSETSCREENMODE) }
Procedure InitResolution;
Var S : String; W, H, B : LongInt;
Begin
  S := PrfStr('PM_Display', 'RESOLUTION');
  If S = '' Then S := GetEnvS('PMRESOLUTION');
  If ParseRes(S, W, H, B) Then Dummy := WinSetScreenMode(W, H, B);
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
  ShieldOk := 0;
  Hab := WinInitialize(0);
  InitResolution;
  Hmq := WinCreateMsgQueue(Hab, 64);
  If Hmq = 0 Then
  Begin
    WriteLn('PMSHELL : Presentation Manager (PMWIN.DLL) ne peut pas demarrer.');
    Halt(1);
  End;
  LoadSettings;
  CountryLoad;
  SetDeskColor;
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20); ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  If ScrW <= 0 Then ScrW := 640;
  If ScrH <= 0 Then ScrH := 480;
  Dummy := WinRegisterClass(Hab, Z('WPDesktop'), LongInt(@ViewProc), 0, 8);
  Dummy := WinRegisterClass(Hab, Z('WPFolder'), LongInt(@ViewProc), 0, 8);
  Dummy := WinRegisterClass(Hab, Z('WPView'), LongInt(@ListProc), 0, 8);
  Dummy := WinRegisterClass(Hab, Z('WPList'), LongInt(@ListProc), 0, 8);
  Dummy := WinRegisterClass(Hab, Z('WPNotebook'), LongInt(@NotebookProc), 0, 8);
  Dummy := WinRegisterClass(Hab, Z('WPLogo'), LongInt(@LogoProc), 0, 8);
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
  ShowLogo;
  StartLaunchPad;
  { boucle des messages (WM_QUIT est ignore : le bureau ne se termine pas) }
  Repeat
    If WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Then Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Until False;
END.
