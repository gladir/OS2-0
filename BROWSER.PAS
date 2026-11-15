{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BROWSER - Navigateur Web de Presentation Manager pour
                OS/2-0 (HTML, CSS, JavaScript, images GIF, PNG, JPEG et
                BMP, formulaires, signets, historique, code source,
                codes QR, outils de developpement F12).
}

Program BROWSER;

{$R-,S-,I-}

{ Compilation : OS2PC BROWSER.PAS   (produit BROWSER.EXE)

  Adaptation pour OS/2-0 du navigateur graphique BROWSER.PAS du depot
  DEV-COOLS (Turbo Pascal / Free Pascal, unite Graph, WinInet) : meme
  architecture (source HTML, analyseur qui construit un arbre de noeuds,
  moteur de rendu par balises, decodeurs d'images, historique, favoris,
  barre d'adresse et boutons Precedent / Suivant / Actualiser /
  Favori), mais :

  - interface de Presentation Manager avec l'apparence d'OS/2 Warp 3 :
    fenetre cadre redimensionnable, vrai menu de PM, barre d'outils dont
    les boutons portent des icones d'OS/2 (WinCreatePointerIndirect,
    WinDrawPointer, grisees par DP_HALFTONED), champ d'adresse
    (WC_ENTRYFIELD), barre de defilement (WC_SCROLLBAR), barre d'etat
    gravee, boites de message de PM, signets dans OS2.INI ;
  - dessin par GPI (couleurs RGB, polices mises a l'echelle par
    GpiSetCharBox, images par GpiDrawBits) a partir d'une liste
    d'affichage : la mise en page est faite une fois, le defilement ne
    fait que redessiner la partie visible ;
  - reseau par TCPIP32.DLL (HTTP/1.1 : redirections, transfert en blocs
    "chunked", proxy HTTP), dans un fil d'execution a part : la fenetre
    reste vivante pendant le chargement (bouton Arreter) ;
  - memoire : arene privee du processus (DosAllocMem), videe a chaque
    page ; le tas du noyau n'est jamais utilise (GetMem d'OS2PC) ;
  - chaines courtes d'OS2PC : les textes, valeurs d'attributs et
    feuilles de style sont gardes dans l'arene, sans limite de 255
    caracteres.

  Corrections des defauts du navigateur d'origine (plantages sur
  www.google.ca et www.gladir.com) : contenu de <script>, <style> et
  <textarea> lu comme texte brut (un "a<b" dans un script ne cree plus de
  balises), profondeur de l'arbre et de la recursion bornees, tableaux
  aux colonnes et lignes bornees, attributs sans valeur ou mal fermes,
  entites inconnues, texte UTF-8 converti en page de codes 850, memoire
  epuisee geree (page tronquee au lieu d'un plantage), corps de reponse
  et images de taille bornee, decodeurs d'images verifies a chaque
  lecture (fichier tronque ou corrompu : image ignoree).

  Ajouts par rapport a l'original :
  - JavaScript (sous-ensemble d'ECMAScript 5 et 6) : variables, fonctions
    et fonctions flechees, objets, tableaux, chaines, Math, Date, JSON,
    try/catch, document.write, DOM (getElementById, querySelector,
    innerHTML, style, classList, createElement...), evenements (onclick,
    addEventListener, onload, onsubmit, onchange), setTimeout et
    setInterval, console ; budget d'instructions (une boucle sans fin
    est arretee) et memoire bornee ;
  - menu contextuel de la page (bouton 2) : liens, navigation, code
    source, enregistrement, code QR, inspection ;
  - affichage du code source (view-source:, Ctrl+U) colore et numerote ;
  - codes QR (versions 1 a 10, correction L, Reed-Solomon) de la page ou
    d'un lien, pour l'ouvrir sur un telephone ;
  - outils de developpement (F12), a la maniere de Firebug : Inspecteur
    (arbre du DOM, attributs, style calcule, selection a la souris),
    Debogueur (scripts de la page), Editeur de style (feuilles modifiees
    en direct), Console (journal et evaluation d'expressions) et Reseau
    (requetes, types, tailles, durees) ;
  - redessin partiel : seules les zones changees par un script sont
    redessinees (pas de scintillement).

  HTTPS demande un proxy (Options - Proxy, ou SET HTTP_PROXY=hote:port).
  SET BROWSER_TRACE=1 recopie la console et les etapes du chargement sur
  la sortie standard (journal du port serie sous QEMU). }

Const
  { --- messages et styles de PM --- }
  WM_CREATE = $0001; WM_DESTROY = $0002; WM_SIZE = $0007; WM_SETFOCUS = $000F;
  WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024;
  WM_CLOSE = $0029; WM_QUIT = $002A; WM_CONTROL = $0030; WM_VSCROLL = $0031; WM_HSCROLL = $0032;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
  WM_BUTTON2DOWN = $0074; WM_CHAR = $007A; WM_USER = $1000;
  WM_PAGEDONE = $1001;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20;
  FCF_DLGBORDER = $200; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_HIDE = $10; SWP_ACTIVATE = $80;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000; WS_CLIPCHILDREN = $20000000;
  WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006; WC_LISTBOX = $FFFF0007;
  WC_SCROLLBAR = $FFFF0008;
  BS_PUSHBUTTON = 0; BS_DEFAULT = $0400; SS_TEXT = 1; ES_AUTOSCROLL = 4; ES_MARGIN = 8; SBS_VERT = 1;
  EM_SETTEXTLIMIT = $0143; EM_SETSEL = $0142; EN_SETFOCUS = 1;
  SBM_SETSCROLLBAR = $01A0; SBM_SETPOS = $01A1; SBM_QUERYPOS = $01A2;
  SB_LINEUP = 1; SB_LINEDOWN = 2; SB_PAGEUP = 3; SB_PAGEDOWN = 4; SB_SLIDERTRACK = 5; SB_SLIDERPOSITION = 6;
  LM_DELETEALL = $016E; LM_INSERTITEM = $0161; LM_QUERYSELECTION = $0165; LM_SELECTITEM = $0164;
  LN_ENTER = 5;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  WM_BUTTON2CLICK = $0416;
  MIA_CHECKED = $2000; MIA_DISABLED = $4000; MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_OKCANCEL = 1; MB_YESNO = 4; MB_INFORMATION = $30; MB_WARNING = $20; MB_ERROR = $40;
  MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_OK = 1; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_TAB = $06; VK_NEWLINE = $08; VK_ESC = $0F; VK_SPACE = $10;
  VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14; VK_LEFT = $15; VK_UP = $16;
  VK_RIGHT = $17; VK_DOWN = $18; VK_DELETE = $1B; VK_ENTER = $1E; VK_F1 = $20; VK_F5 = $24;
  SPTR_ARROW = 1; SPTR_TEXT = 2; SPTR_WAIT = 3; SPTR_HAND = 21;
  DP_NORMAL = 0; DP_HALFTONED = 1;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9;
  CLR_PALEGRAY = 15;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  BM_LEAVEALONE = 5;

  { --- commandes --- }
  CM_OPENURL = 101; CM_OPENFILE = 102; CM_SAVE = 103; CM_QUIT = 104;
  CM_BACK = 111; CM_FORWARD = 112; CM_RELOAD = 113; CM_STOP = 114; CM_HOME = 115;
  CM_SOURCE = 121; CM_IMAGES = 122; CM_BIGFONT = 123;
  CM_ADDMARK = 131; CM_MARKS = 132;
  CM_SETHOME = 141; CM_PROXY = 142;
  CM_HELP = 151; CM_ABOUT = 152;
  CM_QR = 161; CM_DEVTOOLS = 162; CM_OPENLINK = 163; CM_QRLINK = 164; CM_COPYLINK = 165; CM_INSPECT = 166;
  CM_HIST0 = 300;                     { 300..315 : pages de l'historique (menu Aller) }
  ID_URL = 10; ID_GO = 11; ID_VSCROLL = 12; ID_VIEW = 13;
  ID_DOK = 1; ID_DCANCEL = 2; ID_DEF = 20; ID_DLIST = 21; ID_DDEL = 22;

  { --- limites (corrections de robustesse) --- }
  HTTP_UA = 'Mozilla/4.0 (compatible; OS/2-0 Navigateur Web 1.0; OS/2)';
  REFRESH_MAX = 20;                { <meta refresh> enchaines au plus (anti-boucle) }
  ARENA_SIZE = 12582912;          { 12 Mo par page : arbre, textes, mise en page, images }
  SRC_MAX = 4194304;              { corps de reponse : 4 Mo au plus }
  MAX_DEPTH = 60;                 { profondeur de l'arbre HTML }
  MAX_REDIRECT = 8;
  MAX_HIST = 64;
  MAX_MARKS = 64;
  MAX_LINKS = 2000;
  MAX_FORMS = 64;
  MAX_CTRLS = 400;
  MAX_IMGS = 200;
  MAX_COLS = 40;
  MAX_CSS = 600;
  HIST_MENU = 16;

  { --- types de noeuds et balises (memes valeurs que le navigateur
    d'origine) --- }
  NODE_ELEM = 1; NODE_TEXT = 2; NODE_COMMENT = 3;
  TAG_HTML = 1; TAG_HEAD = 2; TAG_BODY = 3; TAG_DIV = 4; TAG_SPAN = 5; TAG_SECTION = 6; TAG_ARTICLE = 7;
  TAG_NAV = 8; TAG_ASIDE = 9; TAG_HEADER = 10; TAG_FOOTER = 11; TAG_MAIN = 12;
  TAG_H1 = 20; TAG_H2 = 21; TAG_H3 = 22; TAG_H4 = 23; TAG_H5 = 24; TAG_H6 = 25;
  TAG_P = 30; TAG_BR = 31; TAG_HR = 32; TAG_STRONG = 33; TAG_B = 34; TAG_EM = 35; TAG_I = 36;
  TAG_U = 37; TAG_S = 38; TAG_STRIKE = 39; TAG_DEL = 40; TAG_INS = 41; TAG_SUB = 42; TAG_SUP = 43;
  TAG_SMALL = 44; TAG_BIG = 45; TAG_MARK = 46; TAG_ABBR = 47; TAG_CITE = 48; TAG_DFN = 49;
  TAG_CODE = 50; TAG_PRE = 51; TAG_KBD = 52; TAG_SAMP = 53; TAG_VAR = 54; TAG_Q = 55;
  TAG_BLOCKQUOTE = 56; TAG_FONT = 57;
  TAG_A = 60; TAG_IMG = 61; TAG_AUDIO = 62; TAG_VIDEO = 63; TAG_EMBED = 66; TAG_OBJECT = 67;
  TAG_IFRAME = 69; TAG_CANVAS = 70; TAG_SVG = 71; TAG_PICTURE = 72; TAG_FIGURE = 73; TAG_FIGCAPTION = 74;
  TAG_UL = 80; TAG_OL = 81; TAG_LI = 82; TAG_DL = 83; TAG_DT = 84; TAG_DD = 85; TAG_MENU = 86;
  TAG_TABLE = 90; TAG_TR = 91; TAG_TD = 92; TAG_TH = 93; TAG_THEAD = 94; TAG_TBODY = 95;
  TAG_TFOOT = 96; TAG_CAPTION = 97; TAG_COLGROUP = 98; TAG_COL = 99;
  TAG_FORM = 100; TAG_INPUT = 101; TAG_BUTTON = 102; TAG_SELECT = 103; TAG_OPTION = 104;
  TAG_OPTGROUP = 105; TAG_TEXTAREA = 106; TAG_LABEL = 107; TAG_FIELDSET = 108; TAG_LEGEND = 109;
  TAG_TITLE = 120; TAG_META = 121; TAG_LINK = 122; TAG_STYLE = 123; TAG_SCRIPT = 124;
  TAG_NOSCRIPT = 125; TAG_BASE = 126; TAG_TEMPLATE = 127;
  TAG_ADDRESS = 130; TAG_TIME = 131; TAG_DETAILS = 133; TAG_SUMMARY = 134; TAG_DIALOG = 135;
  TAG_WBR = 150; TAG_MAP = 153; TAG_AREA = 154; TAG_CENTER = 155;
  TAG_UNKNOWN = 255;

  { --- liste d'affichage --- }
  OP_TEXT = 1; OP_RECT = 2; OP_FRAME = 3; OP_LINE = 4; OP_IMAGE = 5; OP_CTRL = 6; OP_BULLET = 7;

  { styles du texte }
  ST_BOLD = 1; ST_ITALIC = 2; ST_UNDER = 4; ST_STRIKE = 8; ST_MONO = 16;

  { types de controles de formulaire }
  CT_TEXT = 1; CT_PASSWORD = 2; CT_SUBMIT = 3; CT_CHECK = 4; CT_RADIO = 5; CT_SELECT = 6;
  CT_TEXTAREA = 7; CT_HIDDEN = 8; CT_BUTTON = 9; CT_RESET = 10; CT_IMAGE = 11;

Type
  PLong = ^LongInt;
  TIp4 = Array[0..3] Of Byte;
  PByteP = ^Byte;
  PAttr = ^TAttr;
  PNode = ^TNode;
  TAttr = Record
    Name : String[31];
    Val, VLen : LongInt;          { valeur dans l'arene }
    Next : PAttr;
  End;
  TNode = Record
    Kind, Tag : Byte;
    Name : String[23];
    Txt, TLen : LongInt;          { texte (noeud texte) dans l'arene }
    Attr : PAttr;
    First, Last, Next, Parent : PNode;
    Css : LongInt;                { style calcule (adresse dans l'arene) ou 0 }
    Aux : LongInt;                { controle de formulaire ou image (indice + 1) }
    MinW, MaxW, MGen : LongInt;   { largeurs mesurees (tableaux), generation }
  End;

  { style d'un element : proprietes reconnues des feuilles de style }
  PStyle = ^TStyle;
  TStyle = Record
    Color, Back : LongInt;        { -1 : herite / transparent }
    Display : Byte;               { 0 herite, 1 none, 2 block, 3 inline }
    Align : Byte;                 { 0, 1 gauche, 2 centre, 3 droite }
    Bold, Italic, Under : Byte;   { 0 herite, 1 oui, 2 non }
    Size : Byte;                  { 0 herite, sinon 1 a 7 (comme <font size>) }
    Width : LongInt;              { 0 ou largeur en pels }
    { marges et retraits (margin, padding) en pels ; -1 : non precise }
    MarT, MarR, MarB, MarL, PadT, PadR, PadB, PadL : LongInt;
  End;

  { operation de la liste d'affichage (dans l'arene) }
  POp = ^TOp;
  TOp = Record
    Kind : Byte;
    Style, Size : Byte;
    X, Y, W, H : LongInt;
    Color, Back : LongInt;
    Data, Len : LongInt;          { texte, image ou controle }
    Link : LongInt;               { lien (0 aucun) }
    Elem : PNode;                 { element du DOM (evenements, inspecteur) }
    Next : POp;
  End;

Var
  Dummy : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;

{ ==================================================================== }
{ API d'OS/2 (PMWIN, PMGPI, DOSCALLS, PMMERGE, TCPIP32)                 }
{ ==================================================================== }

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
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryFocus(HD : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetPointer(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysPointer(HD, Id, Ld : LongInt) : LongInt; External 'PMWIN';
Function WinCreatePointerIndirect(HD, P : LongInt) : LongInt; External 'PMWIN';
Function WinDrawPointer(Hps, X, Y, H, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinShowWindow(H, Sh : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinUpdateWindow(H : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiCharStringAt(Hps, PPt, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetCharBox(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetBackMix(Hps, M : LongInt) : LongInt; External 'PMGPI';
Function GpiCreateLogColorTable(Hps, Opt, Fmt, St, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function GpiCreateBitmap(Hps, PHdr, Fl, PInit, Pbmi : LongInt) : LongInt; External 'PMGPI';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeMem(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosLoadModule(PObj, Cb, PName, PH : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE';
Function SockInit : LongInt; External 'TCPIP32' Name 'sock_init';
Function Socket(D, T, P : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function Connect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function Send(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function Recv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function SoClose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function SockErrno : LongInt; External 'TCPIP32' Name 'sock_errno';
Function GetHostByName(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Function RdB(A : LongInt) : LongInt;
Var Q : PByteP;
Begin
  Q := Pointer(A);
  RdB := Q^ And $FF;
End;

Procedure WrB(A, V : LongInt);
Var Q : PByteP;
Begin
  Q := Pointer(A);
  Q^ := V And $FF;
End;

Function RdL(A : LongInt) : LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Procedure WrL(A, V : LongInt);
Var Q : PLong;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Procedure MemCopy(Src, Dst, N : LongInt);
Var I : LongInt;
Begin
  If (N <= 0) Or (Src = 0) Or (Dst = 0) Then Exit;
  If Dst <= Src Then
  Begin
    I := 0;
    While I + 4 <= N Do
    Begin
      WrL(Dst + I, RdL(Src + I));
      I := I + 4;
    End;
    While I < N Do
    Begin
      WrB(Dst + I, RdB(Src + I));
      Inc(I);
    End;
  End
  Else
    For I := N - 1 DownTo 0 Do WrB(Dst + I, RdB(Src + I));
End;

Procedure MemFill(Dst, N, V : LongInt);
Var I, W : LongInt;
Begin
  If (N <= 0) Or (Dst = 0) Then Exit;
  V := V And $FF;
  W := V Or (V Shl 8) Or (V Shl 16) Or (V Shl 24);
  I := 0;
  While I + 4 <= N Do
  Begin
    WrL(Dst + I, W);
    I := I + 4;
  End;
  While I < N Do
  Begin
    WrB(Dst + I, V);
    Inc(I);
  End;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  K := 0;
  If A <> 0 Then
    While (K < 255) And (RdB(A + K) <> 0) Do
    Begin
      S := S + Chr(RdB(A + K));
      Inc(K);
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

Function SVal(S : String; Def : LongInt) : LongInt;
Var V, C, K : LongInt;
Begin
  K := 1;
  While (K <= Length(S)) And (S[K] = ' ') Do Inc(K);
  V := 0; C := 0;
  If (K <= Length(S)) And (S[K] = '-') Then Inc(K);
  If (K > Length(S)) Or Not (S[K] In ['0'..'9']) Then
  Begin
    SVal := Def;
    Exit;
  End;
  While (K <= Length(S)) And (S[K] In ['0'..'9']) And (C < 9) Do
  Begin
    V := V * 10 + Ord(S[K]) - 48;
    Inc(K); Inc(C);
  End;
  If (Length(S) > 0) And (Pos('-', S) > 0) And (Pos('-', S) < K) Then V := -V;
  SVal := V;
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

Function LowStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'A') And (S[K] <= 'Z') Then S[K] := Chr(Ord(S[K]) + 32);
  LowStr := S;
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'a') And (S[K] <= 'z') Then S[K] := Chr(Ord(S[K]) - 32);
  UpStr := S;
End;

Function TrimS(S : String) : String;
Begin
  While (Length(S) > 0) And (S[1] <= ' ') Do Delete(S, 1, 1);
  While (Length(S) > 0) And (S[Length(S)] <= ' ') Do Delete(S, Length(S), 1);
  TrimS := S;
End;

Function StartsWith(S, P : String) : Boolean;
Begin
  StartsWith := LowStr(Copy(S, 1, Length(P))) = LowStr(P);
End;

Function GetEnvS(N : String) : String;
Var P : LongInt;
Begin
  P := 0;
  If DosScanEnv(Z(N), LongInt(@P)) = 0 Then GetEnvS := GetZ(P) Else GetEnvS := '';
End;

{ trace de diagnostic (SET BROWSER_TRACE=1) : sortie standard -> journal }
Var TraceOn : LongInt;
Procedure Trace(S : String);
Var B : Array[0..259] Of Byte; W : LongInt;
Begin
  If TraceOn = 0 Then
  Begin
    If GetEnvS('BROWSER_TRACE') = '1' Then TraceOn := 1 Else TraceOn := 2;
  End;
  If TraceOn <> 1 Then Exit;
  S := 'BROWSER: ' + Copy(S, 1, 200) + #13#10;
  For W := 1 To Length(S) Do B[W - 1] := Ord(S[W]);
  W := 0;
  Dummy := DosWrite(1, LongInt(@B), Length(S), LongInt(@W));
End;

Function PrfStr(App, Key : String) : String;
Var B : Array[0..299] Of Byte;
Begin
  B[0] := 0;
  Dummy := PrfQueryProfileString(-1, Z(App), Z2(Key), 0, LongInt(@B), 290);
  PrfStr := GetZ(LongInt(@B));
End;

Procedure PrfPut(App, Key, Value : String);
Var B : Array[0..299] Of Byte;
Begin
  PutZ(LongInt(@B), Value);
  If Value = '' Then Dummy := PrfWriteProfileString(-1, Z(App), Z2(Key), 0)
  Else Dummy := PrfWriteProfileString(-1, Z(App), Z2(Key), LongInt(@B));
End;

Function HexCh(V : LongInt) : Char;
Begin
  If V < 10 Then HexCh := Chr(48 + V) Else HexCh := Chr(55 + V);
End;

Function HexStr8(V : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  For K := 7 DownTo 0 Do S := S + HexCh((V Shr (K * 4)) And 15);
  HexStr8 := S;
End;

Function HexDigit(C : Char) : LongInt;
Begin
  If (C >= '0') And (C <= '9') Then HexDigit := Ord(C) - 48
  Else If (C >= 'a') And (C <= 'f') Then HexDigit := Ord(C) - 87
  Else If (C >= 'A') And (C <= 'F') Then HexDigit := Ord(C) - 55
  Else HexDigit := -1;
End;

{ ==================================================================== }
{ Arene de la page : memoire privee du processus, videe a chaque page   }
{ ==================================================================== }

Var
  ArBase, ArUsed, ArSize : LongInt;
  ArFull : Boolean;

Procedure ArenaInit;
Begin
  ArBase := 0; ArSize := ARENA_SIZE;
  While (ArBase = 0) And (ArSize >= 1048576) Do
  Begin
    If DosAllocMem(LongInt(@ArBase), ArSize, $13) <> 0 Then
    Begin
      ArBase := 0;
      ArSize := ArSize Div 2;
    End;
  End;
  ArUsed := 0; ArFull := False;
End;

Procedure ArenaReset;
Begin
  ArUsed := 0; ArFull := False;
End;

{ bloc de N octets mis a zero ; 0 si l'arene est pleine }
Function ArAlloc(N : LongInt) : LongInt;
Begin
  ArAlloc := 0;
  If (ArBase = 0) Or (N < 0) Then Exit;
  N := (N + 3) And Not 3;
  If ArUsed + N > ArSize Then
  Begin
    ArFull := True;
    Exit;
  End;
  ArAlloc := ArBase + ArUsed;
  MemFill(ArBase + ArUsed, N, 0);
  ArUsed := ArUsed + N;
End;

{ copie d'une chaine dans l'arene }
Function ArStr(S : String) : LongInt;
Var A, K : LongInt;
Begin
  A := ArAlloc(Length(S) + 1);
  If A <> 0 Then
    For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  ArStr := A;
End;

{ chaine (255 au plus) lue dans l'arene }
Function ArGet(A, N : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  If (A <> 0) And (N > 0) Then
  Begin
    If N > 254 Then N := 254;      { + NUL de OS2PC : 256 octets }
    S[0] := Chr(N);
    For K := 1 To N Do S[K] := Chr(RdB(A + K - 1));
  End;
  ArGet := S;
End;

{ ==================================================================== }
{ Jeux de caracteres : la police de PM est celle du VGA (page de codes  }
{ 437) ; UTF-8, ISO-8859-1 et windows-1252 y sont convertis             }
{ ==================================================================== }

Const
  { U+00A0..U+00FF -> page de codes 437 (lettre sans accent si absente) }
  Lat2Cp : Array[0..95] Of Byte = (
    255, 173, 155, 156, 63, 157, 124, 21, 34, 99, 166, 174, 170, 0, 82, 45,
    248, 241, 253, 51, 39, 230, 20, 250, 44, 49, 167, 175, 172, 171, 63, 168,
    65, 65, 65, 65, 142, 143, 146, 128, 69, 144, 69, 69, 73, 73, 73, 73,
    68, 165, 79, 79, 79, 79, 153, 120, 79, 85, 85, 85, 154, 89, 63, 225,
    133, 160, 131, 97, 132, 134, 145, 135, 138, 130, 136, 137, 141, 161, 140, 139,
    100, 164, 149, 162, 147, 111, 148, 246, 111, 151, 163, 150, 129, 121, 63, 152);
  { page de codes 437 (128..255) -> Unicode (envoi des formulaires) }
  Cp2Uni : Array[0..127] Of LongInt = (
    $00C7, $00FC, $00E9, $00E2, $00E4, $00E0, $00E5, $00E7, $00EA, $00EB, $00E8, $00EF, $00EE, $00EC, $00C4, $00C5,
    $00C9, $00E6, $00C6, $00F4, $00F6, $00F2, $00FB, $00F9, $00FF, $00D6, $00DC, $00A2, $00A3, $00A5, $20A7, $0192,
    $00E1, $00ED, $00F3, $00FA, $00F1, $00D1, $00AA, $00BA, $00BF, $2310, $00AC, $00BD, $00BC, $00A1, $00AB, $00BB,
    $2591, $2592, $2593, $2502, $2524, $2561, $2562, $2556, $2555, $2563, $2551, $2557, $255D, $255C, $255B, $2510,
    $2514, $2534, $252C, $251C, $2500, $253C, $255E, $255F, $255A, $2554, $2569, $2566, $2560, $2550, $256C, $2567,
    $2568, $2564, $2565, $2559, $2558, $2552, $2553, $256B, $256A, $2518, $250C, $2588, $2584, $258C, $2590, $2580,
    $03B1, $00DF, $0393, $03C0, $03A3, $03C3, $00B5, $03C4, $03A6, $0398, $03A9, $03B4, $221E, $03C6, $03B5, $2229,
    $2261, $00B1, $2265, $2264, $2320, $2321, $00F7, $2248, $00B0, $2219, $00B7, $221A, $207F, $00B2, $25A0, $00A0);
  { windows-1252, 80h..9Fh -> Unicode }
  W1252 : Array[0..31] Of LongInt = (
    $20AC, 0, $201A, $0192, $201E, $2026, $2020, $2021, $02C6, $2030, $0160, $2039, $0152, 0, $017D, 0,
    0, $2018, $2019, $201C, $201D, $2022, $2013, $2014, $02DC, $2122, $0161, $203A, $0153, 0, $017E, $0178);

{ point de code Unicode -> caractere de la page 437 ; 0 : a omettre }
Function UniToCp(U : LongInt) : LongInt;
Begin
  If U < 0 Then UniToCp := 63
  Else If U < 128 Then UniToCp := U
  Else If U < 160 Then UniToCp := 32
  Else If U < 256 Then UniToCp := Lat2Cp[U - 160]
  Else
    Case U Of
      $2018, $2019, $201A, $2032, $02BC : UniToCp := 39;
      $201C, $201D, $201E, $2033 : UniToCp := 34;
      $2013, $2014, $2010, $2011, $2012, $2015, $2212 : UniToCp := 45;
      $2022, $2219, $25CF, $25E6 : UniToCp := 7;
      $2026 : UniToCp := 46;
      $20AC : UniToCp := 69;
      $2122 : UniToCp := 84;
      $2039 : UniToCp := 60;
      $203A : UniToCp := 62;
      $0152 : UniToCp := 79;
      $0153 : UniToCp := 111;
      $0160 : UniToCp := 83;
      $0161 : UniToCp := 115;
      $0178 : UniToCp := 89;
      $2002, $2003, $2009, $200A, $202F, $205F, $3000 : UniToCp := 32;
      $200B, $200C, $200D, $200E, $200F, $FEFF, $00AD : UniToCp := 0;
      $00B7 : UniToCp := 250;
      $2190 : UniToCp := 27;
      $2192 : UniToCp := 26;
      $2191 : UniToCp := 24;
      $2193 : UniToCp := 25;
      $25B2 : UniToCp := 30;
      $25BC : UniToCp := 31;
      $25BA, $25B6 : UniToCp := 16;
      $25C4, $25C0 : UniToCp := 17;
      $2264 : UniToCp := 243;
      $2265 : UniToCp := 242;
      $00D7, $2715, $2716 : UniToCp := 120;
      $2713, $2714 : UniToCp := 251;
    Else
      UniToCp := 63;
    End;
End;

{ caractere de la page 437 -> point de code Unicode }
Function CpToUni(C : LongInt) : LongInt;
Begin
  C := C And 255;
  If C < 128 Then CpToUni := C Else CpToUni := Cp2Uni[C - 128];
End;

{ ==================================================================== }
{ Adresses (URL)                                                        }
{ ==================================================================== }

Var
  UScheme, UHost, UPath : String;
  UPort : LongInt;

{ decoupe "schema://hote:port/chemin" ; faux si l'adresse n'est pas
  reconnue }
Function SplitUrl(U : String) : Boolean;
Var K : LongInt; H : String;
Begin
  SplitUrl := False;
  UScheme := ''; UHost := ''; UPath := '/'; UPort := 80;
  K := Pos('://', U);
  If K = 0 Then Exit;
  UScheme := LowStr(Copy(U, 1, K - 1));
  Delete(U, 1, K + 2);
  If UScheme = 'https' Then UPort := 443
  Else If UScheme = 'ftp' Then UPort := 21;
  K := 1;
  While (K <= Length(U)) And (U[K] <> '/') And (U[K] <> '?') And (U[K] <> '#') Do Inc(K);
  H := Copy(U, 1, K - 1);
  UPath := Copy(U, K, 255);
  If (UPath = '') Or (UPath[1] <> '/') Then UPath := '/' + UPath;
  K := Pos('#', UPath);
  If K > 0 Then UPath := Copy(UPath, 1, K - 1);
  { utilisateur:motdepasse@ ignores }
  K := Pos('@', H);
  If K > 0 Then Delete(H, 1, K);
  K := Pos(':', H);
  If K > 0 Then
  Begin
    UPort := SVal(Copy(H, K + 1, 6), UPort);
    H := Copy(H, 1, K - 1);
  End;
  UHost := LowStr(H);
  SplitUrl := UHost <> '';
End;

{ adresse tapee par l'utilisateur -> adresse complete }
Function NormalizeUrl(U : String) : String;
Begin
  U := TrimS(U);
  If U = '' Then
  Begin
    NormalizeUrl := '';
    Exit;
  End;
  { view-source:adresse : code source de la page (adresse normalisee) }
  If StartsWith(LowStr(U), 'view-source:') Then
  Begin
    U := Copy(U, 13, 255);
    If U = '' Then NormalizeUrl := '' Else NormalizeUrl := 'view-source:' + NormalizeUrl(U);
    Exit;
  End;
  If (Length(U) >= 2) And (U[2] = ':') And (UpCase(U[1]) In ['A'..'Z']) Then
    U := 'file:///' + U
  Else If StartsWith(U, 'about:') Or StartsWith(U, 'file:') Or (Pos('://', U) > 0) Then
  Else If StartsWith(U, 'www.') Or (Pos('.', U) > 0) Then U := 'http://' + U
  Else U := 'http://www.' + U + '.com/';
  If (Pos('://', U) > 0) And (Pos('/', Copy(U, Pos('://', U) + 3, 255)) = 0) And Not StartsWith(U, 'file:') Then
    U := U + '/';
  NormalizeUrl := U;
End;

{ adresse relative R par rapport a la base B (RFC 3986, simplifie) }
Function ResolveUrl(B, R : String) : String;
Var K : LongInt; Dir, Q, Root : String;
Begin
  R := TrimS(R);
  { entites deja decodees ; espaces encodes }
  While Pos(' ', R) > 0 Do
  Begin
    K := Pos(' ', R);
    Delete(R, K, 1);
    Insert('%20', R, K);
  End;
  If R = '' Then
  Begin
    ResolveUrl := B;
    Exit;
  End;
  If (Pos('://', R) > 0) And (Pos('://', R) < 12) Then
  Begin
    ResolveUrl := R;
    Exit;
  End;
  If StartsWith(R, 'about:') Or StartsWith(R, 'mailto:') Or StartsWith(R, 'javascript:') Or
     StartsWith(R, 'data:') Or StartsWith(R, 'file:') Then
  Begin
    ResolveUrl := R;
    Exit;
  End;
  K := Pos('://', B);
  If K = 0 Then
  Begin
    ResolveUrl := R;
    Exit;
  End;
  { racine : schema://hote:port }
  Root := B;
  K := K + 3;
  While (K <= Length(Root)) And (Root[K] <> '/') And (Root[K] <> '?') And (Root[K] <> '#') Do Inc(K);
  Q := Copy(B, K, 255);
  Root := Copy(B, 1, K - 1);
  If StartsWith(B, 'file:') Then Root := 'file://';
  If Copy(R, 1, 2) = '//' Then
  Begin
    ResolveUrl := Copy(B, 1, Pos('://', B)) + R;
    Exit;
  End;
  If R[1] = '/' Then
  Begin
    ResolveUrl := Root + R;
    Exit;
  End;
  { chemin de la base sans requete ni fragment }
  K := Pos('#', Q);
  If K > 0 Then Q := Copy(Q, 1, K - 1);
  If R[1] = '#' Then
  Begin
    ResolveUrl := Root + Q + R;
    Exit;
  End;
  K := Pos('?', Q);
  If K > 0 Then Q := Copy(Q, 1, K - 1);
  If R[1] = '?' Then
  Begin
    ResolveUrl := Root + Q + R;
    Exit;
  End;
  If Q = '' Then Q := '/';
  Dir := Q;
  While (Length(Dir) > 0) And (Dir[Length(Dir)] <> '/') Do Delete(Dir, Length(Dir), 1);
  If Dir = '' Then Dir := '/';
  { ./ et ../ }
  Repeat
    If Copy(R, 1, 2) = './' Then Delete(R, 1, 2)
    Else If Copy(R, 1, 3) = '../' Then
    Begin
      Delete(R, 1, 3);
      If Length(Dir) > 1 Then
      Begin
        Delete(Dir, Length(Dir), 1);
        While (Length(Dir) > 0) And (Dir[Length(Dir)] <> '/') Do Delete(Dir, Length(Dir), 1);
        If Dir = '' Then Dir := '/';
      End;
    End
    Else If R = '..' Then
    Begin
      R := '';
      If Length(Dir) > 1 Then
      Begin
        Delete(Dir, Length(Dir), 1);
        While (Length(Dir) > 0) And (Dir[Length(Dir)] <> '/') Do Delete(Dir, Length(Dir), 1);
      End;
    End
    Else Break;
  Until False;
  ResolveUrl := Root + Dir + R;
End;

{ encodage d'une valeur de formulaire (application/x-www-form-urlencoded,
  UTF-8) }
Function FormEncode(S : String) : String;
Var K, U : LongInt; R : String; C : Char;
Const Hx : String[16] = '0123456789ABCDEF';
Begin
  R := '';
  For K := 1 To Length(S) Do
  Begin
    C := S[K];
    If Length(R) > 240 Then Break;
    If C In ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '*'] Then R := R + C
    Else If C = ' ' Then R := R + '+'
    Else
    Begin
      U := CpToUni(Ord(C));
      If U < $80 Then R := R + '%' + Hx[(U Shr 4) + 1] + Hx[(U And 15) + 1]
      Else If U < $800 Then
        R := R + '%' + Hx[((($C0 Or (U Shr 6)) Shr 4) And 15) + 1] + Hx[(($C0 Or (U Shr 6)) And 15) + 1] +
             '%' + Hx[((($80 Or (U And 63)) Shr 4) And 15) + 1] + Hx[(($80 Or (U And 63)) And 15) + 1]
      Else
        R := R + '%' + Hx[((($E0 Or (U Shr 12)) Shr 4) And 15) + 1] + Hx[(($E0 Or (U Shr 12)) And 15) + 1] +
             '%' + Hx[((($80 Or ((U Shr 6) And 63)) Shr 4) And 15) + 1] + Hx[(($80 Or ((U Shr 6) And 63)) And 15) + 1] +
             '%' + Hx[((($80 Or (U And 63)) Shr 4) And 15) + 1] + Hx[(($80 Or (U And 63)) And 15) + 1];
    End;
  End;
  FormEncode := R;
End;

{ %XX d'un chemin de fichier local }
Function UrlDecode(S : String) : String;
Var K : LongInt; R : String;
Begin
  R := '';
  K := 1;
  While K <= Length(S) Do
  Begin
    If (S[K] = '%') And (K + 2 <= Length(S)) And (HexDigit(S[K + 1]) >= 0) And (HexDigit(S[K + 2]) >= 0) Then
    Begin
      R := R + Chr(HexDigit(S[K + 1]) * 16 + HexDigit(S[K + 2]));
      K := K + 3;
    End
    Else
    Begin
      R := R + S[K];
      Inc(K);
    End;
  End;
  UrlDecode := R;
End;

{ ==================================================================== }
{ Chargement (HTTP par TCPIP32.DLL, fichiers locaux, pages internes),   }
{ dans un fil d'execution a part                                        }
{ ==================================================================== }

Var
  { tampon du document (source HTML) et tampon d'une image }
  SrcBuf, SrcLen, ImgBuf, ImgLen : LongInt;
  { requete en cours (fil de chargement) }
  FUrl, FPost, FCType, FLocation, FErr, FFinalUrl : String;
  FStatus, FBytes, FTotal, FTarget, FBuf, FCap : LongInt;
  FBusy, FDone, FAbort : LongInt;
  FHdr : Array[0..8191] Of Byte;
  FNet : Array[0..16383] Of Byte;
  ProxyHost : String;
  ProxyPort : LongInt;
  NetReady : LongInt;
  ThreadTid : LongInt;

Procedure ProxyLoad;
Var S : String; K : LongInt;
Begin
  S := PrfStr('BROWSER', 'PROXY');
  If S = '' Then S := GetEnvS('HTTP_PROXY');
  If StartsWith(S, 'http://') Then Delete(S, 1, 7);
  While (Length(S) > 0) And (S[Length(S)] = '/') Do Delete(S, Length(S), 1);
  ProxyHost := ''; ProxyPort := 0;
  K := Pos(':', S);
  If K > 1 Then
  Begin
    ProxyHost := Copy(S, 1, K - 1);
    ProxyPort := SVal(Copy(S, K + 1, 6), 0);
    If ProxyPort <= 0 Then ProxyHost := '';
  End;
End;

{ ajoute des octets au tampon de destination (borne : FCap) }
Procedure FPut(P, N : LongInt);
Begin
  If N <= 0 Then Exit;
  If FTotal + N > FCap Then N := FCap - FTotal;
  If N > 0 Then
  Begin
    MemCopy(P, FBuf + FTotal, N);
    FTotal := FTotal + N;
  End;
End;

Procedure FPutS(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If FTotal < FCap Then
    Begin
      WrB(FBuf + FTotal, Ord(S[K]));
      Inc(FTotal);
    End;
End;

{ adresse IPv4 (ordre du reseau) d'un nom d'hote ; 0 si inconnu }
Function HostAddr(H : String; Var A : TIp4) : Boolean;
Var K, P, N, V : LongInt; Num : Boolean; B : Array[0..255] Of Byte; R : LongInt;
Begin
  HostAddr := False;
  Num := H <> '';
  For K := 1 To Length(H) Do
    If Not (H[K] In ['0'..'9', '.']) Then Num := False;
  If Num Then
  Begin
    N := 0; V := 0;
    For K := 1 To Length(H) Do
      If H[K] = '.' Then
      Begin
        If N < 4 Then A[N] := V And 255;
        Inc(N); V := 0;
      End
      Else V := V * 10 + Ord(H[K]) - 48;
    If N = 3 Then
    Begin
      A[3] := V And 255;
      HostAddr := True;
    End;
    Exit;
  End;
  For K := 1 To Length(H) Do B[K - 1] := Ord(H[K]);
  B[Length(H)] := 0;
  R := GetHostByName(LongInt(@B));
  If R = 0 Then Exit;
  P := RdL(RdL(R + 16));
  If P = 0 Then Exit;
  For K := 0 To 3 Do A[K] := RdB(P + K);
  HostAddr := True;
End;

{ une requete HTTP ; FStatus : code HTTP, ou -1 (erreur, FErr) }
Procedure HttpOnce(Url : String);
Var S, K, N, Hl, Port, St, Clen, Chunk, Ln, I : LongInt;
    Ad : Array[0..15] Of Byte; Ip : TIp4;
    Req, Host, Line, HName, HVal, PathQ : String;
    Chunked, InHdr, Eoh : Boolean; C : Byte;
Begin
  FStatus := -1; FCType := ''; FLocation := ''; FTotal := 0;
  If Not SplitUrl(Url) Then
  Begin
    FErr := 'Adresse non valable : ' + Url;
    Exit;
  End;
  If (UScheme <> 'http') And Not ((UScheme = 'https') And (ProxyHost <> '')) Then
  Begin
    If UScheme = 'https' Then
      FErr := 'Les pages securisees (https://) demandent un proxy HTTP : menu Options - Proxy, ' +
              'ou SET HTTP_PROXY=hote:port dans CONFIG.SYS.'
    Else FErr := 'Protocole non pris en charge : ' + UScheme + '://';
    Exit;
  End;
  If NetReady = 0 Then
  Begin
    If SockInit = 0 Then NetReady := 1 Else NetReady := -1;
  End;
  If NetReady < 0 Then
  Begin
    NetReady := 0;
    FErr := 'Le reseau n''est pas disponible (carte reseau, DHCP : voir IFCONFIG).';
    Exit;
  End;
  Host := UHost; Port := UPort;
  PathQ := UPath;
  If ProxyHost <> '' Then
  Begin
    Host := ProxyHost; Port := ProxyPort;
    PathQ := Url;
    K := Pos('#', PathQ);
    If K > 0 Then PathQ := Copy(PathQ, 1, K - 1);
  End;
  If Not HostAddr(Host, Ip) Then
  Begin
    FErr := 'Hote inconnu : ' + Host + ' (serveur de noms injoignable ou nom inexistant).';
    Exit;
  End;
  For K := 0 To 15 Do Ad[K] := 0;
  Ad[0] := 16; Ad[1] := 2; Ad[2] := Port Shr 8; Ad[3] := Port And 255;
  For K := 0 To 3 Do Ad[4 + K] := Ip[K];
  S := Socket(2, 1, 0);
  If S < 0 Then
  Begin
    FErr := 'Impossible de creer une connexion (socket).';
    Exit;
  End;
  If Connect(S, LongInt(@Ad), 16) <> 0 Then
  Begin
    FErr := 'Connexion impossible a ' + Host + ':' + IStr(Port) + ' (erreur ' + IStr(SockErrno) + ').';
    Dummy := SoClose(S);
    Exit;
  End;
  { requete }
  If FPost <> '' Then Req := 'POST ' Else Req := 'GET ';
  Req := Req + PathQ + ' HTTP/1.1' + #13#10 + 'Host: ' + UHost;
  If (UPort <> 80) And (UScheme = 'http') Then Req := Req + ':' + IStr(UPort);
  K := 0;
  For I := 1 To Length(Req) Do
  Begin
    FNet[K] := Ord(Req[I]);
    Inc(K);
  End;
  Req := #13#10 + 'User-Agent: ' + HTTP_UA + #13#10 +
         'Accept: text/html, text/plain, image/gif, image/png, image/jpeg, image/bmp, */*;q=0.1' + #13#10;
  For I := 1 To Length(Req) Do
  Begin
    FNet[K] := Ord(Req[I]);
    Inc(K);
  End;
  Req := 'Accept-Language: fr-CA, fr, en' + #13#10 + 'Accept-Charset: utf-8, iso-8859-1' + #13#10 +
         'Accept-Encoding: identity' + #13#10 + 'Connection: close' + #13#10;
  For I := 1 To Length(Req) Do
  Begin
    FNet[K] := Ord(Req[I]);
    Inc(K);
  End;
  If FPost <> '' Then
  Begin
    Req := 'Content-Type: application/x-www-form-urlencoded' + #13#10 + 'Content-Length: ' +
           IStr(Length(FPost)) + #13#10;
    For I := 1 To Length(Req) Do
    Begin
      FNet[K] := Ord(Req[I]);
      Inc(K);
    End;
  End;
  FNet[K] := 13; FNet[K + 1] := 10; K := K + 2;
  For I := 1 To Length(FPost) Do
  Begin
    FNet[K] := Ord(FPost[I]);
    Inc(K);
  End;
  If Send(S, LongInt(@FNet), K, 0) <> K Then
  Begin
    FErr := 'Envoi de la requete impossible a ' + Host + '.';
    Dummy := SoClose(S);
    Exit;
  End;
  { reponse : en-tetes puis corps (Content-Length, blocs ou fin de
    connexion) }
  Hl := 0; InHdr := True; St := 0; Clen := -1; Chunked := False;
  Chunk := -1; Ln := 0; Line := '';
  Repeat
    If FAbort <> 0 Then
    Begin
      FErr := 'Chargement interrompu.';
      Break;
    End;
    N := Recv(S, LongInt(@FNet), SizeOf(FNet), 0);
    If N <= 0 Then Break;
    FBytes := FBytes + N;
    I := 0;
    While I < N Do
    Begin
      If InHdr Then
      Begin
        C := FNet[I];
        Inc(I);
        If Hl < SizeOf(FHdr) Then
        Begin
          FHdr[Hl] := C;
          Inc(Hl);
        End;
        If C = 10 Then
        Begin
          { ligne d'en-tete complete }
          If Line = '' Then
          Begin
            InHdr := False;
            If Clen = 0 Then I := N;
          End
          Else If St = 0 Then
          Begin
            { HTTP/1.x 200 OK }
            K := Pos(' ', Line);
            If K > 0 Then St := SVal(Copy(Line, K + 1, 3), 0);
            FStatus := St;
          End
          Else
          Begin
            K := Pos(':', Line);
            If K > 0 Then
            Begin
              HName := LowStr(TrimS(Copy(Line, 1, K - 1)));
              HVal := TrimS(Copy(Line, K + 1, 255));
              If HName = 'content-type' Then FCType := LowStr(HVal)
              Else If HName = 'location' Then FLocation := HVal
              Else If HName = 'content-length' Then Clen := SVal(HVal, -1)
              Else If (HName = 'transfer-encoding') And (Pos('chunked', LowStr(HVal)) > 0) Then Chunked := True;
            End;
          End;
          Line := '';
        End
        Else If (C <> 13) And (Length(Line) < 250) Then Line := Line + Chr(C);
      End
      Else If Chunked Then
      Begin
        If Chunk <= 0 Then
        Begin
          { taille du bloc (hexadecimal) puis CR LF ; 0 : fin }
          C := FNet[I];
          Inc(I);
          If C = 10 Then
          Begin
            If Line <> '' Then
            Begin
              Chunk := 0;
              For K := 1 To Length(Line) Do
                If (HexDigit(Line[K]) >= 0) And (Chunk < $1000000) Then Chunk := Chunk * 16 + HexDigit(Line[K])
                Else If Line[K] = ';' Then Break;
              If Chunk = 0 Then
              Begin
                I := N;
                Clen := -2;
              End;
              Line := '';
            End;
          End
          Else If (C <> 13) And (Length(Line) < 20) Then Line := Line + Chr(C);
        End
        Else
        Begin
          K := MinI(Chunk, N - I);
          FPut(LongInt(@FNet) + I, K);
          I := I + K;
          Chunk := Chunk - K;
          If Chunk = 0 Then Chunk := -1;
        End;
      End
      Else
      Begin
        K := N - I;
        If (Clen >= 0) And (FTotal + K > Clen) Then K := Clen - FTotal;
        FPut(LongInt(@FNet) + I, K);
        I := N;
      End;
    End;
    If (Not InHdr) And (Clen >= 0) And (FTotal >= Clen) Then Break;
    If Clen = -2 Then Break;
    If FTotal >= FCap Then Break;
  Until False;
  Dummy := SoClose(S);
  If (FStatus = -1) And (FErr = '') Then
  Begin
    If FBytes = 0 Then FErr := 'Le serveur ' + Host + ' n''a rien repondu.'
    Else FErr := 'Reponse du serveur non valable.';
  End;
End;

{ fichier local (file:///C:/... ou C:\...) }
Procedure FileOnce(Url : String);
Var P : String; H, Act, N, K : LongInt; B : Array[0..299] Of Byte;
Begin
  FStatus := -1; FTotal := 0; FCType := '';
  P := Url;
  If StartsWith(P, 'file:') Then
  Begin
    Delete(P, 1, 5);
    While (Length(P) > 0) And (P[1] = '/') Do Delete(P, 1, 1);
  End;
  P := UrlDecode(P);
  K := Pos('?', P);
  If K > 0 Then P := Copy(P, 1, K - 1);
  K := Pos('#', P);
  If K > 0 Then P := Copy(P, 1, K - 1);
  For K := 1 To Length(P) Do
    If P[K] = '/' Then P[K] := '\';
  If (Length(P) >= 2) And (P[2] = '|') Then P[2] := ':';
  PutZ(LongInt(@B), P);
  H := 0; Act := 0;
  If DosOpen(LongInt(@B), LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) <> 0 Then
  Begin
    FErr := 'Fichier introuvable : ' + P;
    Exit;
  End;
  Repeat
    N := 0;
    If DosRead(H, LongInt(@FNet), SizeOf(FNet), LongInt(@N)) <> 0 Then N := 0;
    FPut(LongInt(@FNet), N);
    FBytes := FBytes + N;
  Until (N <= 0) Or (FTotal >= FCap) Or (FAbort <> 0);
  Dummy := DosClose(H);
  FStatus := 200;
  P := LowStr(P);
  If (Pos('.htm', P) > 0) Or (Pos('.html', P) > 0) Then FCType := 'text/html'
  Else If Pos('.gif', P) > 0 Then FCType := 'image/gif'
  Else If Pos('.png', P) > 0 Then FCType := 'image/png'
  Else If (Pos('.jpg', P) > 0) Or (Pos('.jpeg', P) > 0) Then FCType := 'image/jpeg'
  Else If Pos('.bmp', P) > 0 Then FCType := 'image/bmp'
  Else FCType := 'text/plain';
End;

{ page interne : accueil du navigateur }
Procedure AboutHome;
Begin
  FTotal := 0; FStatus := 200; FCType := 'text/html; charset=ibm437';
  FPutS('<html><head><title>Bienvenue dans le Navigateur Web d''OS/2-0</title></head>');
  FPutS('<body bgcolor="#FFFFFF" text="#000000" link="#0000A8" vlink="#800080">');
  FPutS('<table width="100%" cellpadding="8" bgcolor="#000080"><tr><td>');
  FPutS('<font color="#FFFFFF" size="6"><b>Navigateur Web d''OS/2-0</b></font><br>');
  FPutS('<font color="#C0C0FF">Le Web sur votre bureau OS/2, sans quitter Presentation Manager.</font>');
  FPutS('</td></tr></table>');
  FPutS('<h2>Pour commencer</h2><p>Tapez une adresse dans le champ <b>Adresse</b>, puis Entr' + Chr(130) +
        'e ou <b>Aller</b>. Quelques sites :</p><ul>');
  FPutS('<li><a href="http://www.google.ca/">Google Canada</a> - recherche sur le Web</li>');
  FPutS('<li><a href="http://www.gladir.com/">Gladir.com</a> - le site du projet OS/2-0</li>');
  FPutS('<li><a href="http://www.gladir.com/os2-0/">OS/2-0</a> - documentation du clone d''OS/2</li>');
  FPutS('<li><a href="file:///C:/">C:\</a> - fichiers HTML de votre disque (file:///)</li></ul>');
  FPutS('<h2>Ce que sait faire ce navigateur</h2><table border="1" cellpadding="4">');
  FPutS('<tr><th>Fonction</th><th>Description</th></tr>');
  FPutS('<tr><td>HTML</td><td>Titres, paragraphes, listes, tableaux, formulaires, liens, polices et couleurs</td></tr>');
  FPutS('<tr><td>Images</td><td>GIF, PNG, JPEG et BMP</td></tr>');
  FPutS('<tr><td>Feuilles de style</td><td>Couleurs, fonds, alignement, gras, italique, soulignement, display: none</td></tr>');
  FPutS('<tr><td>Navigation</td><td>Pr' + Chr(130) + 'c' + Chr(130) + 'dent, Suivant, Actualiser, Arr' + Chr(136) +
        'ter, Accueil, historique, signets</td></tr>');
  FPutS('<tr><td>R' + Chr(130) + 'seau</td><td>HTTP/1.1 par TCPIP32.DLL, proxy HTTP (n' + Chr(130) +
        'cessaire pour https://)</td></tr></table>');
  FPutS('<p><small>OS/2-0 - programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.</small></p>');
  FPutS('</body></html>');
End;

{ page d'erreur }
Procedure ErrorPage(Url, Msg : String);
Begin
  FTotal := 0; FStatus := 200; FCType := 'text/html; charset=ibm437';
  FPutS('<html><head><title>Page introuvable</title></head><body bgcolor="#FFFFFF">');
  FPutS('<table cellpadding="6"><tr><td bgcolor="#A80000"><font color="#FFFFFF" size="5"><b>!</b></font></td><td>');
  FPutS('<h2>Impossible d''afficher la page</h2></td></tr></table>');
  FPutS('<p><b>Adresse :</b> ' + Url + '</p><p>' + Msg + '</p>');
  FPutS('<p>V' + Chr(130) + 'rifiez l''adresse, la connexion r' + Chr(130) + 'seau (IFCONFIG) et le proxy (menu Options), ');
  FPutS('puis cliquez <b>Actualiser</b>.</p><p><a href="about:home">Page d''accueil du navigateur</a></p></body></html>');
End;

{ chargement complet d'une adresse : redirections, pages internes ;
  resultat dans FBuf (FTotal octets), FCType, FFinalUrl }
Procedure FetchUrl(Url : String; ErrPage : Boolean);
Var R : LongInt; L : String;
Begin
  FErr := ''; FBytes := 0; FFinalUrl := Url;
  R := 0;
  Repeat
    FFinalUrl := Url;
    If StartsWith(Url, 'about:') Then
    Begin
      If ErrPage Then AboutHome Else FStatus := -1;
      Exit;
    End;
    If StartsWith(Url, 'file:') Then FileOnce(Url)
    Else HttpOnce(Url);
    If (FStatus >= 300) And (FStatus < 400) And (FLocation <> '') And (R < MAX_REDIRECT) Then
    Begin
      L := ResolveUrl(Url, FLocation);
      { 303 et ancien usage de 301/302 : la redirection se fait en GET }
      If FStatus <> 307 Then FPost := '';
      Url := L;
      Inc(R);
    End
    Else Break;
  Until FAbort <> 0;
  If FStatus < 0 Then
  Begin
    If ErrPage Then ErrorPage(Url, FErr);
  End
  Else If (FStatus >= 400) And ErrPage And (FTotal < 64) Then
    ErrorPage(Url, 'Le serveur a repondu : erreur ' + IStr(FStatus) + '.');
End;

{ fil de chargement : FTarget 0 : document (SrcBuf), 1 : image (ImgBuf) }
Function FetchThread(Arg : LongInt) : LongInt;
Begin
  If FTarget = 0 Then
  Begin
    FBuf := SrcBuf; FCap := SRC_MAX;
    FetchUrl(FUrl, True);
    SrcLen := FTotal;
  End
  Else
  Begin
    FBuf := ImgBuf; FCap := SRC_MAX;
    FetchUrl(FUrl, False);
    If (FStatus < 200) Or (FStatus >= 300) Then FTotal := 0;
    ImgLen := FTotal;
  End;
  FDone := 1;
  FBusy := 0;
  FetchThread := 0;
End;

{ lance un chargement ; faux si un chargement est deja en cours }
Function StartFetch(Url, Post : String; Target : LongInt) : Boolean;
Begin
  StartFetch := False;
  If FBusy <> 0 Then Exit;
  FUrl := Url; FPost := Post; FTarget := Target;
  FDone := 0; FAbort := 0; FBusy := 1; FBytes := 0; FTotal := 0;
  If DosCreateThread(LongInt(@ThreadTid), LongInt(@FetchThread), 0, 0, 65536) <> 0 Then
  Begin
    { sans fil : chargement direct }
    Dummy := FetchThread(0);
  End;
  StartFetch := True;
End;

{ ==================================================================== }
{ Conversion du document en page de codes 437 (sur place)               }
{ ==================================================================== }

{ jeu de caracteres : en-tete Content-Type, sinon <meta charset> }
Function DocCharset(CType : String) : LongInt;
Var K, I, N : LongInt; S : String;
Begin
  { 0 : UTF-8, 1 : ISO-8859-1 / windows-1252, 2 : deja 437 }
  DocCharset := -1;
  K := Pos('charset=', CType);
  If K > 0 Then
  Begin
    S := Copy(CType, K + 8, 20);
    If (Pos('utf-8', S) > 0) Or (Pos('utf8', S) > 0) Then DocCharset := 0
    Else If Pos('437', S) > 0 Then DocCharset := 2
    Else DocCharset := 1;
    Exit;
  End;
  { <meta charset="..."> ou http-equiv dans les 4 premiers Ko }
  N := MinI(SrcLen, 4096);
  S := '';
  For I := 0 To N - 1 Do
  Begin
    If Length(S) >= 250 Then Delete(S, 1, 100);
    S := S + Chr(RdB(SrcBuf + I) Or $20);
    K := Pos('charset=', S);
    If (K > 0) And (Length(S) > K + 12) Then
    Begin
      S := Copy(S, K + 8, 12);
      If (Pos('utf-8', S) > 0) Or (Pos('utf8', S) > 0) Then DocCharset := 0 Else DocCharset := 1;
      Exit;
    End;
  End;
End;

{ y a-t-il des suites UTF-8 valables ? (document sans jeu declare) }
Function LooksUtf8 : Boolean;
Var I, J, N, B, Good, Bad : LongInt; Ok : Boolean;
Begin
  Good := 0; Bad := 0;
  I := 0;
  While (I < SrcLen) And (I < 200000) Do
  Begin
    B := RdB(SrcBuf + I);
    Inc(I);
    If B >= $80 Then
    Begin
      { longueur de la suite d'apres l'octet de tete }
      If (B >= $C2) And (B <= $DF) Then N := 1
      Else If (B >= $E0) And (B <= $EF) Then N := 2
      Else If (B >= $F0) And (B <= $F4) Then N := 3
      Else N := 0;
      Ok := N > 0;
      J := 0;
      While Ok And (J < N) Do
      Begin
        If (I + J >= SrcLen) Or ((RdB(SrcBuf + I + J) And $C0) <> $80) Then Ok := False;
        Inc(J);
      End;
      If Ok Then
      Begin
        Inc(Good); I := I + N;
      End
      Else Inc(Bad);
    End;
  End;
  LooksUtf8 := Good > Bad;
End;

Procedure ConvertSource(CType : String);
Var Cs, I, O, B, U, N, K : LongInt;
Begin
  Cs := DocCharset(CType);
  If Cs = 2 Then Exit;
  If Cs < 0 Then
  Begin
    If LooksUtf8 Then Cs := 0 Else Cs := 1;
  End;
  I := 0; O := 0;
  { marque d'ordre des octets UTF-8 }
  If (SrcLen >= 3) And (RdB(SrcBuf) = $EF) And (RdB(SrcBuf + 1) = $BB) And (RdB(SrcBuf + 2) = $BF) Then
  Begin
    I := 3; Cs := 0;
  End;
  While I < SrcLen Do
  Begin
    B := RdB(SrcBuf + I);
    Inc(I);
    If B < $80 Then U := B
    Else If Cs = 0 Then
    Begin
      If (B And $E0) = $C0 Then
      Begin
        N := 1; U := B And $1F;
      End
      Else If (B And $F0) = $E0 Then
      Begin
        N := 2; U := B And $0F;
      End
      Else If (B And $F8) = $F0 Then
      Begin
        N := 3; U := B And $07;
      End
      Else
      Begin
        N := 0; U := 63;
      End;
      For K := 1 To N Do
        If (I < SrcLen) And ((RdB(SrcBuf + I) And $C0) = $80) Then
        Begin
          U := (U Shl 6) Or (RdB(SrcBuf + I) And $3F);
          Inc(I);
        End
        Else U := 63;
    End
    Else If (B >= $80) And (B < $A0) Then
    Begin
      U := W1252[B - $80];
      If U = 0 Then U := 63;
    End
    Else U := B;
    U := UniToCp(U);
    If U <> 0 Then
    Begin
      WrB(SrcBuf + O, U);
      Inc(O);
    End;
  End;
  SrcLen := O;
End;

{ ==================================================================== }
{ Analyseur HTML (d'apres ParseHTML du navigateur d'origine)            }
{ ==================================================================== }

Const
  { entites des lettres Latin-1 192..255 }
  EntL1 : Array[0..63] Of String[6] = (
    'Agrave', 'Aacute', 'Acirc', 'Atilde', 'Auml', 'Aring', 'AElig', 'Ccedil',
    'Egrave', 'Eacute', 'Ecirc', 'Euml', 'Igrave', 'Iacute', 'Icirc', 'Iuml',
    'ETH', 'Ntilde', 'Ograve', 'Oacute', 'Ocirc', 'Otilde', 'Ouml', 'times',
    'Oslash', 'Ugrave', 'Uacute', 'Ucirc', 'Uuml', 'Yacute', 'THORN', 'szlig',
    'agrave', 'aacute', 'acirc', 'atilde', 'auml', 'aring', 'aelig', 'ccedil',
    'egrave', 'eacute', 'ecirc', 'euml', 'igrave', 'iacute', 'icirc', 'iuml',
    'eth', 'ntilde', 'ograve', 'oacute', 'ocirc', 'otilde', 'ouml', 'divide',
    'oslash', 'ugrave', 'uacute', 'ucirc', 'uuml', 'yacute', 'thorn', 'yuml');

Var
  Root : PNode;
  DocTitle, BaseUrl, RefreshUrl : String;
  ParseTrunc : Boolean;

Function EntityCode(N : String) : LongInt;
Var K : LongInt; L : String;
Begin
  EntityCode := -1;
  For K := 0 To 63 Do
    If EntL1[K] = N Then
    Begin
      EntityCode := 192 + K;
      Exit;
    End;
  L := LowStr(N);
  If L = 'nbsp' Then EntityCode := 160
  Else If L = 'amp' Then EntityCode := 38
  Else If L = 'lt' Then EntityCode := 60
  Else If L = 'gt' Then EntityCode := 62
  Else If L = 'quot' Then EntityCode := 34
  Else If L = 'apos' Then EntityCode := 39
  Else If L = 'copy' Then EntityCode := 169
  Else If L = 'reg' Then EntityCode := 174
  Else If L = 'trade' Then EntityCode := $2122
  Else If L = 'hellip' Then EntityCode := $2026
  Else If L = 'mdash' Then EntityCode := $2014
  Else If L = 'ndash' Then EntityCode := $2013
  Else If L = 'laquo' Then EntityCode := 171
  Else If L = 'raquo' Then EntityCode := 187
  Else If L = 'lsquo' Then EntityCode := $2018
  Else If L = 'rsquo' Then EntityCode := $2019
  Else If L = 'ldquo' Then EntityCode := $201C
  Else If L = 'rdquo' Then EntityCode := $201D
  Else If L = 'bull' Then EntityCode := $2022
  Else If L = 'middot' Then EntityCode := 183
  Else If L = 'deg' Then EntityCode := 176
  Else If L = 'euro' Then EntityCode := $20AC
  Else If L = 'pound' Then EntityCode := 163
  Else If L = 'yen' Then EntityCode := 165
  Else If L = 'cent' Then EntityCode := 162
  Else If L = 'sect' Then EntityCode := 167
  Else If L = 'para' Then EntityCode := 182
  Else If L = 'shy' Then EntityCode := 173
  Else If L = 'iexcl' Then EntityCode := 161
  Else If L = 'iquest' Then EntityCode := 191
  Else If L = 'plusmn' Then EntityCode := 177
  Else If L = 'frac12' Then EntityCode := 189
  Else If L = 'frac14' Then EntityCode := 188
  Else If L = 'sup2' Then EntityCode := 178
  Else If L = 'micro' Then EntityCode := 181
  Else If L = 'ordf' Then EntityCode := 170
  Else If L = 'ordm' Then EntityCode := 186
  Else If L = 'not' Then EntityCode := 172
  Else If L = 'larr' Then EntityCode := $2190
  Else If L = 'rarr' Then EntityCode := $2192
  Else If L = 'uarr' Then EntityCode := $2191
  Else If L = 'darr' Then EntityCode := $2193
  Else If L = 'ensp' Then EntityCode := $2002
  Else If L = 'emsp' Then EntityCode := $2003
  Else If L = 'thinsp' Then EntityCode := $2009
  Else If L = 'zwnj' Then EntityCode := $200C
  Else If L = 'zwj' Then EntityCode := $200D
  Else If L = 'oelig' Then EntityCode := $0153
  Else If L = 'le' Then EntityCode := $2264
  Else If L = 'ge' Then EntityCode := $2265;
End;

{ decode les entites de Src[0..N-1] vers Dst (au plus N octets) ;
  rend la longueur ecrite }
Function DecodeTo(Src, N, Dst : LongInt) : LongInt;
Var I, O, J, C, D, Cp : LongInt; Nm : String; Hex, Ok : Boolean;
Begin
  I := 0; O := 0;
  While I < N Do
  Begin
    C := RdB(Src + I);
    If C <> 38 Then
    Begin
      WrB(Dst + O, C);
      Inc(O); Inc(I);
    End
    Else
    Begin
      { &nom; &#nnn; &#xhh; (le ; final est facultatif pour les nombres) }
      J := I + 1; Nm := '';
      While (J < N) And (J - I <= 10) And (RdB(Src + J) <> 59) And (Chr(RdB(Src + J)) In ['a'..'z', 'A'..'Z', '0'..'9', '#']) Do
      Begin
        Nm := Nm + Chr(RdB(Src + J));
        Inc(J);
      End;
      Cp := -1;
      If (Length(Nm) >= 2) And (Nm[1] = '#') Then
      Begin
        Hex := (Nm[2] = 'x') Or (Nm[2] = 'X');
        If Hex Then D := 3 Else D := 2;
        Cp := 0; Ok := D <= Length(Nm);
        While Ok And (D <= Length(Nm)) Do
        Begin
          If Hex And (HexDigit(Nm[D]) >= 0) Then Cp := Cp * 16 + HexDigit(Nm[D])
          Else If (Not Hex) And (Nm[D] In ['0'..'9']) Then Cp := Cp * 10 + Ord(Nm[D]) - 48
          Else Ok := False;
          If Cp > $10FFFF Then Ok := False;
          Inc(D);
        End;
        If Not Ok Then Cp := -1;
      End
      Else If (Nm <> '') And (J < N) And (RdB(Src + J) = 59) Then Cp := EntityCode(Nm)
      Else If (Nm = 'amp') Or (Nm = 'nbsp') Or (Nm = 'lt') Or (Nm = 'gt') Or (Nm = 'quot') Then Cp := EntityCode(Nm);
      If Cp >= 0 Then
      Begin
        Cp := UniToCp(Cp);
        If Cp <> 0 Then
        Begin
          WrB(Dst + O, Cp);
          Inc(O);
        End;
        I := J;
        If (I < N) And (RdB(Src + I) = 59) Then Inc(I);
      End
      Else
      Begin
        WrB(Dst + O, 38);
        Inc(O); Inc(I);
      End;
    End;
  End;
  DecodeTo := O;
End;

Function TagOf(N : String) : LongInt;
Var T : LongInt;
Begin
  T := TAG_UNKNOWN;
  If N = 'a' Then T := TAG_A
  Else If N = 'p' Then T := TAG_P
  Else If N = 'div' Then T := TAG_DIV
  Else If N = 'span' Then T := TAG_SPAN
  Else If N = 'br' Then T := TAG_BR
  Else If N = 'img' Then T := TAG_IMG
  Else If N = 'td' Then T := TAG_TD
  Else If N = 'tr' Then T := TAG_TR
  Else If N = 'th' Then T := TAG_TH
  Else If N = 'table' Then T := TAG_TABLE
  Else If N = 'li' Then T := TAG_LI
  Else If N = 'ul' Then T := TAG_UL
  Else If N = 'ol' Then T := TAG_OL
  Else If N = 'b' Then T := TAG_B
  Else If N = 'i' Then T := TAG_I
  Else If N = 'u' Then T := TAG_U
  Else If N = 'font' Then T := TAG_FONT
  Else If N = 'strong' Then T := TAG_STRONG
  Else If N = 'em' Then T := TAG_EM
  Else If N = 'input' Then T := TAG_INPUT
  Else If N = 'form' Then T := TAG_FORM
  Else If N = 'option' Then T := TAG_OPTION
  Else If N = 'select' Then T := TAG_SELECT
  Else If N = 'textarea' Then T := TAG_TEXTAREA
  Else If N = 'button' Then T := TAG_BUTTON
  Else If N = 'label' Then T := TAG_LABEL
  Else If N = 'h1' Then T := TAG_H1
  Else If N = 'h2' Then T := TAG_H2
  Else If N = 'h3' Then T := TAG_H3
  Else If N = 'h4' Then T := TAG_H4
  Else If N = 'h5' Then T := TAG_H5
  Else If N = 'h6' Then T := TAG_H6
  Else If N = 'hr' Then T := TAG_HR
  Else If N = 'center' Then T := TAG_CENTER
  Else If N = 'pre' Then T := TAG_PRE
  Else If N = 'code' Then T := TAG_CODE
  Else If N = 'tt' Then T := TAG_CODE
  Else If N = 'kbd' Then T := TAG_KBD
  Else If N = 'samp' Then T := TAG_SAMP
  Else If N = 'blockquote' Then T := TAG_BLOCKQUOTE
  Else If N = 'dl' Then T := TAG_DL
  Else If N = 'dt' Then T := TAG_DT
  Else If N = 'dd' Then T := TAG_DD
  Else If N = 'thead' Then T := TAG_THEAD
  Else If N = 'tbody' Then T := TAG_TBODY
  Else If N = 'tfoot' Then T := TAG_TFOOT
  Else If N = 'caption' Then T := TAG_CAPTION
  Else If N = 'col' Then T := TAG_COL
  Else If N = 'colgroup' Then T := TAG_COLGROUP
  Else If N = 'html' Then T := TAG_HTML
  Else If N = 'head' Then T := TAG_HEAD
  Else If N = 'body' Then T := TAG_BODY
  Else If N = 'title' Then T := TAG_TITLE
  Else If N = 'meta' Then T := TAG_META
  Else If N = 'link' Then T := TAG_LINK
  Else If N = 'style' Then T := TAG_STYLE
  Else If N = 'script' Then T := TAG_SCRIPT
  Else If N = 'noscript' Then T := TAG_NOSCRIPT
  Else If N = 'base' Then T := TAG_BASE
  Else If N = 'template' Then T := TAG_TEMPLATE
  Else If N = 'section' Then T := TAG_SECTION
  Else If N = 'article' Then T := TAG_ARTICLE
  Else If N = 'nav' Then T := TAG_NAV
  Else If N = 'aside' Then T := TAG_ASIDE
  Else If N = 'header' Then T := TAG_HEADER
  Else If N = 'footer' Then T := TAG_FOOTER
  Else If N = 'main' Then T := TAG_MAIN
  Else If N = 'small' Then T := TAG_SMALL
  Else If N = 'big' Then T := TAG_BIG
  Else If N = 's' Then T := TAG_S
  Else If N = 'strike' Then T := TAG_STRIKE
  Else If N = 'del' Then T := TAG_DEL
  Else If N = 'ins' Then T := TAG_INS
  Else If N = 'sub' Then T := TAG_SUB
  Else If N = 'sup' Then T := TAG_SUP
  Else If N = 'mark' Then T := TAG_MARK
  Else If N = 'abbr' Then T := TAG_ABBR
  Else If N = 'acronym' Then T := TAG_ABBR
  Else If N = 'cite' Then T := TAG_CITE
  Else If N = 'dfn' Then T := TAG_DFN
  Else If N = 'var' Then T := TAG_VAR
  Else If N = 'q' Then T := TAG_Q
  Else If N = 'address' Then T := TAG_ADDRESS
  Else If N = 'figure' Then T := TAG_FIGURE
  Else If N = 'figcaption' Then T := TAG_FIGCAPTION
  Else If N = 'fieldset' Then T := TAG_FIELDSET
  Else If N = 'legend' Then T := TAG_LEGEND
  Else If N = 'optgroup' Then T := TAG_OPTGROUP
  Else If N = 'iframe' Then T := TAG_IFRAME
  Else If N = 'frame' Then T := TAG_IFRAME
  Else If N = 'embed' Then T := TAG_EMBED
  Else If N = 'object' Then T := TAG_OBJECT
  Else If N = 'video' Then T := TAG_VIDEO
  Else If N = 'audio' Then T := TAG_AUDIO
  Else If N = 'canvas' Then T := TAG_CANVAS
  Else If N = 'svg' Then T := TAG_SVG
  Else If N = 'picture' Then T := TAG_PICTURE
  Else If N = 'menu' Then T := TAG_MENU
  Else If N = 'details' Then T := TAG_DETAILS
  Else If N = 'summary' Then T := TAG_SUMMARY
  Else If N = 'dialog' Then T := TAG_DIALOG
  Else If N = 'time' Then T := TAG_TIME
  Else If N = 'wbr' Then T := TAG_WBR
  Else If N = 'map' Then T := TAG_MAP
  Else If N = 'area' Then T := TAG_AREA;
  TagOf := T;
End;

Function IsVoid(N : String) : Boolean;
Begin
  IsVoid := (N = 'br') Or (N = 'img') Or (N = 'input') Or (N = 'hr') Or (N = 'meta') Or (N = 'link') Or
            (N = 'col') Or (N = 'area') Or (N = 'base') Or (N = 'embed') Or (N = 'param') Or
            (N = 'source') Or (N = 'track') Or (N = 'wbr') Or (N = 'keygen') Or (N = 'frame') Or
            (N = 'basefont') Or (N = 'isindex');
End;

{ elements de bloc (un <p> ouvert se ferme devant eux) }
Function ClosesP(T : LongInt) : Boolean;
Begin
  ClosesP := (T = TAG_P) Or (T = TAG_DIV) Or (T = TAG_UL) Or (T = TAG_OL) Or (T = TAG_DL) Or
             (T = TAG_TABLE) Or ((T >= TAG_H1) And (T <= TAG_H6)) Or (T = TAG_PRE) Or (T = TAG_BLOCKQUOTE) Or
             (T = TAG_FORM) Or (T = TAG_HR) Or (T = TAG_SECTION) Or (T = TAG_ARTICLE) Or (T = TAG_NAV) Or
             (T = TAG_ASIDE) Or (T = TAG_HEADER) Or (T = TAG_FOOTER) Or (T = TAG_MAIN) Or (T = TAG_ADDRESS) Or
             (T = TAG_FIELDSET) Or (T = TAG_FIGURE) Or (T = TAG_CENTER) Or (T = TAG_MENU) Or (T = TAG_DETAILS);
End;

Function NewNode(Kind : LongInt) : PNode;
Var N : PNode;
Begin
  N := Pointer(ArAlloc(SizeOf(TNode)));
  If N <> Nil Then N^.Kind := Kind;
  NewNode := N;
End;

Procedure AppendChild(P, C : PNode);
Begin
  If (P = Nil) Or (C = Nil) Then Exit;
  C^.Parent := P;
  If P^.Last = Nil Then P^.First := C Else P^.Last^.Next := C;
  P^.Last := C;
End;

Function SrcCh(I : LongInt) : LongInt;
Begin
  If (I < 0) Or (I >= SrcLen) Then SrcCh := 0 Else SrcCh := RdB(SrcBuf + I);
End;

Function IsSpaceC(C : LongInt) : Boolean;
Begin
  IsSpaceC := (C = 32) Or (C = 9) Or (C = 10) Or (C = 13) Or (C = 12);
End;

{ noeud texte a partir de Src[I..J-1] (entites decodees si Dec) }
Function MakeText(I, J : LongInt; Dec : Boolean) : PNode;
Var N : PNode; A : LongInt;
Begin
  MakeText := Nil;
  If J <= I Then Exit;
  N := NewNode(NODE_TEXT);
  If N = Nil Then Exit;
  A := ArAlloc(J - I + 1);
  If A = 0 Then Exit;
  If Dec Then N^.TLen := DecodeTo(SrcBuf + I, J - I, A)
  Else
  Begin
    MemCopy(SrcBuf + I, A, J - I);
    N^.TLen := J - I;
  End;
  N^.Txt := A;
  MakeText := N;
End;

{ valeur d'attribut : Src[I..J-1] decode dans l'arene }
Procedure AddAttr(N : PNode; Nm : String; I, J : LongInt);
Var A : PAttr; P : LongInt;
Begin
  If N = Nil Then Exit;
  A := Pointer(ArAlloc(SizeOf(TAttr)));
  If A = Nil Then Exit;
  A^.Name := Nm;
  If J > I Then
  Begin
    P := ArAlloc(J - I + 1);
    If P <> 0 Then
    Begin
      A^.Val := P;
      A^.VLen := DecodeTo(SrcBuf + I, J - I, P);
    End;
  End;
  A^.Next := N^.Attr;
  N^.Attr := A;
End;

Function FindAttr(N : PNode; Nm : String) : PAttr;
Var A : PAttr;
Begin
  FindAttr := Nil;
  If N = Nil Then Exit;
  A := N^.Attr;
  While A <> Nil Do
  Begin
    If A^.Name = Nm Then
    Begin
      FindAttr := A;
      Exit;
    End;
    A := A^.Next;
  End;
End;

Function GetAttr(N : PNode; Nm : String) : String;
Var A : PAttr; S : String; K : LongInt;
Begin
  A := FindAttr(N, Nm);
  If A = Nil Then GetAttr := ''
  Else
  Begin
    S := ArGet(A^.Val, A^.VLen);
    { retours de ligne et tabulations dans une valeur -> espaces }
    For K := 1 To Length(S) Do
      If S[K] < ' ' Then S[K] := ' ';
    GetAttr := S;
  End;
End;

Function HasAttr(N : PNode; Nm : String) : Boolean;
Begin
  HasAttr := FindAttr(N, Nm) <> Nil;
End;

{ recherche la fin d'un element de texte brut : "</nom" (casse
  ignoree) a partir de I ; rend la position du "<" ou SrcLen }
Function FindRawEnd(I : LongInt; Nm : String) : LongInt;
Var K, L : LongInt; Ok : Boolean;
Begin
  L := Length(Nm);
  While I < SrcLen Do
  Begin
    If (SrcCh(I) = 60) And (SrcCh(I + 1) = 47) Then
    Begin
      Ok := True;
      For K := 1 To L Do
        If (SrcCh(I + 1 + K) Or $20) <> Ord(Nm[K]) Then Ok := False;
      If Ok And Not (Chr(SrcCh(I + 2 + L) Or $20) In ['a'..'z', '0'..'9']) Then
      Begin
        FindRawEnd := I;
        Exit;
      End;
    End;
    Inc(I);
  End;
  FindRawEnd := SrcLen;
End;

{ les noeuds ouverts : Stack[0..Depth] (Stack[0] : racine) }
Var
  Stack : Array[0..MAX_DEPTH + 1] Of PNode;
  Depth : LongInt;

{ ferme jusqu'a l'element de nom T (compris), sans traverser les limites
  Lim (cellules, tableaux) ; faux si absent }
Function CloseTo(T : String; Lim : Boolean) : Boolean;
Var K, Tg : LongInt;
Begin
  CloseTo := False;
  K := Depth;
  While K >= 1 Do
  Begin
    If Stack[K]^.Name = T Then
    Begin
      Depth := K - 1;
      CloseTo := True;
      Exit;
    End;
    Tg := Stack[K]^.Tag;
    If Lim And ((Tg = TAG_TD) Or (Tg = TAG_TH) Or (Tg = TAG_TABLE) Or (Tg = TAG_BUTTON)) Then Exit;
    Dec(K);
  End;
End;

{ un element de nom N est-il ouvert (sans traverser une table) ? }
Function IsOpen(T : String) : Boolean;
Var K : LongInt;
Begin
  IsOpen := False;
  For K := Depth DownTo 1 Do
  Begin
    If Stack[K]^.Name = T Then
    Begin
      IsOpen := True;
      Exit;
    End;
    If (Stack[K]^.Tag = TAG_TABLE) Or (Stack[K]^.Tag = TAG_TD) Or (Stack[K]^.Tag = TAG_TH) Then Exit;
  End;
End;

{ fermetures implicites avant l'ouverture de Tg }
Procedure ImplicitClose(Tg : LongInt);
Begin
  If ClosesP(Tg) And IsOpen('p') Then Dummy := Ord(CloseTo('p', True));
  Case Tg Of
    TAG_LI : If IsOpen('li') Then Dummy := Ord(CloseTo('li', True));
    TAG_DT, TAG_DD :
      Begin
        If IsOpen('dt') Then Dummy := Ord(CloseTo('dt', True));
        If IsOpen('dd') Then Dummy := Ord(CloseTo('dd', True));
      End;
    TAG_OPTION :
      If (Depth >= 1) And (Stack[Depth]^.Tag = TAG_OPTION) Then Dec(Depth);
    TAG_TR :
      Begin
        If IsOpen('td') Then Dummy := Ord(CloseTo('td', False));
        If IsOpen('th') Then Dummy := Ord(CloseTo('th', False));
        If IsOpen('tr') Then Dummy := Ord(CloseTo('tr', True));
      End;
    TAG_TD, TAG_TH :
      Begin
        If IsOpen('td') Then Dummy := Ord(CloseTo('td', False))
        Else If IsOpen('th') Then Dummy := Ord(CloseTo('th', False));
      End;
    TAG_THEAD, TAG_TBODY, TAG_TFOOT :
      Begin
        If IsOpen('td') Then Dummy := Ord(CloseTo('td', False));
        If IsOpen('th') Then Dummy := Ord(CloseTo('th', False));
        If IsOpen('tr') Then Dummy := Ord(CloseTo('tr', True));
        If IsOpen('thead') Then Dummy := Ord(CloseTo('thead', True));
        If IsOpen('tbody') Then Dummy := Ord(CloseTo('tbody', True));
        If IsOpen('tfoot') Then Dummy := Ord(CloseTo('tfoot', True));
      End;
  End;
End;

{ texte blanc significatif ? (pas directement dans un tableau, une
  liste, une liste deroulante ou l'en-tete) }
Function KeepBlank : Boolean;
Var T : LongInt;
Begin
  T := Stack[Depth]^.Tag;
  KeepBlank := Not ((T = TAG_TABLE) Or (T = TAG_TR) Or (T = TAG_TBODY) Or (T = TAG_THEAD) Or
                    (T = TAG_TFOOT) Or (T = TAG_UL) Or (T = TAG_OL) Or (T = TAG_DL) Or (T = TAG_SELECT) Or
                    (T = TAG_HEAD) Or (T = TAG_HTML) Or (Depth = 0));
End;

Procedure ParseDocument;
Var I, J, K, Q, Tg, Ve, RefreshCount : LongInt;
    Nm, An : String; N, T : PNode; SelfClose, AllBlank : Boolean; C : LongInt;
Begin
  Root := NewNode(NODE_ELEM);
  If Root = Nil Then Exit;
  Root^.Name := '#document';
  Root^.Tag := TAG_HTML;
  Stack[0] := Root; Depth := 0;
  DocTitle := ''; RefreshUrl := ''; ParseTrunc := False; RefreshCount := 0;
  I := 0;
  While I < SrcLen Do
  Begin
    If ArFull Then
    Begin
      ParseTrunc := True;
      Break;
    End;
    { texte jusqu'au prochain "<" suivi d'une lettre, de "/" ou de "!" }
    J := I;
    While J < SrcLen Do
    Begin
      If SrcCh(J) = 60 Then
      Begin
        C := SrcCh(J + 1);
        If (Chr(C Or $20) In ['a'..'z']) Or (C = 47) Or (C = 33) Or (C = 63) Then Break;
      End;
      Inc(J);
    End;
    If J > I Then
    Begin
      AllBlank := True;
      For K := I To J - 1 Do
        If Not IsSpaceC(SrcCh(K)) Then
        Begin
          AllBlank := False;
          Break;
        End;
      If Not AllBlank Then AppendChild(Stack[Depth], MakeText(I, J, True))
      Else If KeepBlank And (Stack[Depth]^.Last <> Nil) Then
      Begin
        { un seul espace entre deux elements en ligne }
        N := NewNode(NODE_TEXT);
        If N <> Nil Then
        Begin
          N^.Txt := ArStr(' ');
          N^.TLen := 1;
          AppendChild(Stack[Depth], N);
        End;
      End;
    End;
    I := J;
    If I >= SrcLen Then Break;
    { I sur "<" }
    C := SrcCh(I + 1);
    If C = 33 Then
    Begin
      { <!-- commentaire -->, <!DOCTYPE>, <![CDATA[ ]]> }
      If (SrcCh(I + 2) = 45) And (SrcCh(I + 3) = 45) Then
      Begin
        K := I + 4;
        While (K < SrcLen) And Not ((SrcCh(K) = 45) And (SrcCh(K + 1) = 45) And (SrcCh(K + 2) = 62)) Do Inc(K);
        I := K + 3;
      End
      Else
      Begin
        K := I + 2;
        While (K < SrcLen) And (SrcCh(K) <> 62) Do Inc(K);
        I := K + 1;
      End;
      Continue;
    End;
    If C = 63 Then
    Begin
      { <?xml ...?> }
      K := I + 2;
      While (K < SrcLen) And (SrcCh(K) <> 62) Do Inc(K);
      I := K + 1;
      Continue;
    End;
    If C = 47 Then
    Begin
      { balise fermante }
      K := I + 2; Nm := '';
      While (K < SrcLen) And Not IsSpaceC(SrcCh(K)) And (SrcCh(K) <> 62) Do
      Begin
        If Length(Nm) < 20 Then Nm := Nm + Chr(SrcCh(K) Or $20);
        Inc(K);
      End;
      While (K < SrcLen) And (SrcCh(K) <> 62) Do Inc(K);
      I := K + 1;
      Tg := TagOf(Nm);
      If (Tg = TAG_TD) Or (Tg = TAG_TH) Or (Tg = TAG_TR) Or (Tg = TAG_TABLE) Or (Tg = TAG_TBODY) Or
         (Tg = TAG_THEAD) Or (Tg = TAG_TFOOT) Then Dummy := Ord(CloseTo(Nm, False))
      Else If (Nm = 'p') And Not IsOpen('p') Then
      Begin
        { </p> sans <p> : un paragraphe vide }
        N := NewNode(NODE_ELEM);
        If N <> Nil Then
        Begin
          N^.Name := 'p'; N^.Tag := TAG_P;
          AppendChild(Stack[Depth], N);
        End;
      End
      Else If (Nm = 'br') Then
      Begin
        N := NewNode(NODE_ELEM);
        If N <> Nil Then
        Begin
          N^.Name := 'br'; N^.Tag := TAG_BR;
          AppendChild(Stack[Depth], N);
        End;
      End
      Else Dummy := Ord(CloseTo(Nm, True));
      Continue;
    End;
    { balise ouvrante <nom attributs> }
    K := I + 1; Nm := '';
    While (K < SrcLen) And Not IsSpaceC(SrcCh(K)) And (SrcCh(K) <> 62) And (SrcCh(K) <> 47) Do
    Begin
      If Length(Nm) < 20 Then Nm := Nm + Chr(SrcCh(K) Or $20);
      Inc(K);
    End;
    Tg := TagOf(Nm);
    ImplicitClose(Tg);
    N := NewNode(NODE_ELEM);
    If N = Nil Then
    Begin
      ParseTrunc := True;
      Break;
    End;
    N^.Name := Nm; N^.Tag := Tg;
    { attributs }
    SelfClose := False;
    Repeat
      While (K < SrcLen) And (IsSpaceC(SrcCh(K)) Or (SrcCh(K) = 47)) Do
      Begin
        If SrcCh(K) = 47 Then SelfClose := True;
        Inc(K);
      End;
      If (K >= SrcLen) Or (SrcCh(K) = 62) Then Break;
      SelfClose := False;
      An := '';
      While (K < SrcLen) And Not IsSpaceC(SrcCh(K)) And (SrcCh(K) <> 62) And (SrcCh(K) <> 61) And
            Not ((SrcCh(K) = 47) And (SrcCh(K + 1) = 62)) Do
      Begin
        If Length(An) < 30 Then An := An + Chr(SrcCh(K) Or $20);
        Inc(K);
      End;
      While (K < SrcLen) And IsSpaceC(SrcCh(K)) Do Inc(K);
      If SrcCh(K) = 61 Then
      Begin
        Inc(K);
        While (K < SrcLen) And IsSpaceC(SrcCh(K)) Do Inc(K);
        Q := SrcCh(K);
        If (Q = 34) Or (Q = 39) Then
        Begin
          J := K + 1;
          While (J < SrcLen) And (SrcCh(J) <> Q) And (J - K < 16384) Do Inc(J);
          If SrcCh(J) <> Q Then
          Begin
            { guillemet non ferme : la valeur s'arrete au ">" }
            J := K + 1;
            While (J < SrcLen) And (SrcCh(J) <> 62) Do Inc(J);
            AddAttr(N, An, K + 1, J);
            K := J;
          End
          Else
          Begin
            AddAttr(N, An, K + 1, J);
            K := J + 1;
          End;
        End
        Else
        Begin
          J := K;
          While (J < SrcLen) And Not IsSpaceC(SrcCh(J)) And (SrcCh(J) <> 62) Do Inc(J);
          AddAttr(N, An, K, J);
          K := J;
        End;
      End
      Else If An <> '' Then AddAttr(N, An, K, K)
      Else Inc(K);
    Until K >= SrcLen;
    I := K + 1;
    AppendChild(Stack[Depth], N);
    { balises speciales }
    Case Tg Of
      TAG_BASE :
        If GetAttr(N, 'href') <> '' Then BaseUrl := ResolveUrl(BaseUrl, GetAttr(N, 'href'));
      TAG_META :
        If (LowStr(GetAttr(N, 'http-equiv')) = 'refresh') And (RefreshCount = 0) Then
        Begin
          An := GetAttr(N, 'content');
          J := Pos('url=', LowStr(An));
          If (J > 0) And (SVal(An, 99) <= 5) Then
          Begin
            An := TrimS(Copy(An, J + 4, 255));
            If (Length(An) > 0) And ((An[1] = '''') Or (An[1] = '"')) Then Delete(An, 1, 1);
            If (Length(An) > 0) And ((An[Length(An)] = '''') Or (An[Length(An)] = '"')) Then
              Delete(An, Length(An), 1);
            RefreshUrl := An;
            Inc(RefreshCount);
          End;
        End;
    End;
    { contenu brut : script, style, textarea, title, xmp }
    If (Tg = TAG_SCRIPT) Or (Tg = TAG_STYLE) Or (Tg = TAG_TEXTAREA) Or (Tg = TAG_TITLE) Or (Nm = 'xmp') Or
       (Nm = 'plaintext') Then
    Begin
      If SelfClose Then Continue;
      Ve := FindRawEnd(I, Nm);
      If Tg = TAG_TITLE Then
      Begin
        T := MakeText(I, Ve, True);
        If T <> Nil Then
        Begin
          AppendChild(N, T);
          If DocTitle = '' Then DocTitle := TrimS(ArGet(T^.Txt, T^.TLen));
        End;
      End
      Else AppendChild(N, MakeText(I, Ve, (Tg <> TAG_STYLE) And (Tg <> TAG_SCRIPT)));
      { sauter </nom> }
      K := Ve;
      While (K < SrcLen) And (SrcCh(K) <> 62) Do Inc(K);
      I := K + 1;
      Continue;
    End;
    { descendre dans l'element (sauf vide, auto-ferme ou trop profond) }
    If Not IsVoid(Nm) And Not SelfClose And (Depth < MAX_DEPTH) Then
    Begin
      Inc(Depth);
      Stack[Depth] := N;
    End;
  End;
End;

{ texte d'un noeud et de ses descendants (255 caracteres au plus) }
Function NodeText(N : PNode) : String;
Var S : String; C : PNode; K : LongInt;
Begin
  S := '';
  If N = Nil Then
  Begin
    NodeText := '';
    Exit;
  End;
  If N^.Kind = NODE_TEXT Then S := ArGet(N^.Txt, N^.TLen)
  Else
  Begin
    C := N^.First;
    While (C <> Nil) And (Length(S) < 250) Do
    Begin
      If C^.Kind = NODE_TEXT Then S := S + ArGet(C^.Txt, MinI(C^.TLen, 250 - Length(S)))
      Else If C^.Tag <> TAG_SCRIPT Then S := S + NodeText(C);
      C := C^.Next;
    End;
  End;
  For K := 1 To Length(S) Do
    If S[K] < ' ' Then S[K] := ' ';
  NodeText := S;
End;

{ ==================================================================== }
{ Feuilles de style (d'apres le parseur CSS du navigateur d'origine,    }
{ restreint aux proprietes utiles a l'affichage)                        }
{ ==================================================================== }

Type
  { regle : selecteur (jusqu'a 4 composes, du plus a droite au plus a
    gauche) et style }
  PRule = ^TRule;
  TRule = Record
    NPart : Byte;
    PTag : Array[0..3] Of String[15];
    PId : Array[0..3] Of String[23];
    PCls : Array[0..3] Of String[23];
    PCls2 : Array[0..3] Of String[23];
    Spec, Order : LongInt;
    St : TStyle;
  End;

Var
  Rules : Array[0..MAX_CSS - 1] Of PRule;
  NRules : LongInt;

{ couleur CSS / HTML -> RGB ; -1 si inconnue ou transparente }
Function ParseColor(S : String) : LongInt;
Var K, R, G, B, N : LongInt; T : String;
Begin
  ParseColor := -1;
  S := LowStr(TrimS(S));
  K := Pos('!', S);
  If K > 0 Then S := TrimS(Copy(S, 1, K - 1));
  If S = '' Then Exit;
  If (S[1] <> '#') And (Length(S) In [6, 3]) Then
  Begin
    { couleur sans # (attributs HTML anciens) }
    N := 0;
    For K := 1 To Length(S) Do
      If HexDigit(S[K]) >= 0 Then Inc(N);
    If N = Length(S) Then S := '#' + S;
  End;
  If S[1] = '#' Then
  Begin
    Delete(S, 1, 1);
    For K := 1 To Length(S) Do
      If HexDigit(S[K]) < 0 Then Exit;
    If Length(S) = 3 Then
      ParseColor := (HexDigit(S[1]) * 17 Shl 16) Or (HexDigit(S[2]) * 17 Shl 8) Or (HexDigit(S[3]) * 17)
    Else If Length(S) >= 6 Then
      ParseColor := ((HexDigit(S[1]) * 16 + HexDigit(S[2])) Shl 16) Or ((HexDigit(S[3]) * 16 + HexDigit(S[4])) Shl 8) Or
                    (HexDigit(S[5]) * 16 + HexDigit(S[6]));
    Exit;
  End;
  If (Copy(S, 1, 4) = 'rgb(') Or (Copy(S, 1, 5) = 'rgba(') Then
  Begin
    T := Copy(S, Pos('(', S) + 1, 255);
    R := SVal(T, 0);
    K := Pos(',', T); If K > 0 Then Delete(T, 1, K) Else T := '';
    G := SVal(T, 0);
    K := Pos(',', T); If K > 0 Then Delete(T, 1, K) Else T := '';
    B := SVal(T, 0);
    ParseColor := (MinI(255, MaxI(0, R)) Shl 16) Or (MinI(255, MaxI(0, G)) Shl 8) Or MinI(255, MaxI(0, B));
    Exit;
  End;
  If S = 'black' Then ParseColor := $000000
  Else If S = 'white' Then ParseColor := $FFFFFF
  Else If S = 'red' Then ParseColor := $FF0000
  Else If S = 'green' Then ParseColor := $008000
  Else If S = 'blue' Then ParseColor := $0000FF
  Else If S = 'yellow' Then ParseColor := $FFFF00
  Else If (S = 'gray') Or (S = 'grey') Then ParseColor := $808080
  Else If S = 'silver' Then ParseColor := $C0C0C0
  Else If S = 'navy' Then ParseColor := $000080
  Else If S = 'maroon' Then ParseColor := $800000
  Else If S = 'purple' Then ParseColor := $800080
  Else If S = 'teal' Then ParseColor := $008080
  Else If S = 'olive' Then ParseColor := $808000
  Else If S = 'lime' Then ParseColor := $00FF00
  Else If (S = 'aqua') Or (S = 'cyan') Then ParseColor := $00FFFF
  Else If (S = 'fuchsia') Or (S = 'magenta') Then ParseColor := $FF00FF
  Else If S = 'orange' Then ParseColor := $FFA500
  Else If (S = 'lightgray') Or (S = 'lightgrey') Then ParseColor := $D3D3D3
  Else If (S = 'darkgray') Or (S = 'darkgrey') Then ParseColor := $A9A9A9
  Else If S = 'darkblue' Then ParseColor := $00008B
  Else If S = 'darkred' Then ParseColor := $8B0000
  Else If S = 'darkgreen' Then ParseColor := $006400
  Else If S = 'brown' Then ParseColor := $A52A2A
  Else If S = 'pink' Then ParseColor := $FFC0CB
  Else If S = 'gold' Then ParseColor := $FFD700
  Else If S = 'beige' Then ParseColor := $F5F5DC
  Else If S = 'ivory' Then ParseColor := $FFFFF0
  Else If S = 'whitesmoke' Then ParseColor := $F5F5F5
  Else If S = 'gainsboro' Then ParseColor := $DCDCDC
  Else If S = 'lightblue' Then ParseColor := $ADD8E6
  Else If S = 'lightyellow' Then ParseColor := $FFFFE0
  Else If S = 'steelblue' Then ParseColor := $4682B4
  Else If S = 'royalblue' Then ParseColor := $4169E1
  Else If S = 'dimgray' Then ParseColor := $696969;
End;

{ taille CSS -> taille HTML 1..7 }
{ longueur CSS en pels (px, em, rem, pt ; auto et % : 0) bornee a 0..96 }
Function CssLen(S : String) : LongInt;
Var L : String; K, V, F, D : LongInt;
Begin
  L := LowStr(TrimS(S));
  CssLen := 0;
  K := 1; V := 0; F := 0; D := 1;
  If (L = '') Or (L[1] = '-') Then Exit;
  While (K <= Length(L)) And (L[K] In ['0'..'9']) And (V < 10000) Do
  Begin
    V := V * 10 + Ord(L[K]) - 48; Inc(K);
  End;
  If (K <= Length(L)) And (L[K] = '.') Then
  Begin
    Inc(K);
    While (K <= Length(L)) And (L[K] In ['0'..'9']) Do
    Begin
      If D < 100 Then
      Begin
        F := F * 10 + Ord(L[K]) - 48; D := D * 10;
      End;
      Inc(K);
    End;
  End;
  If Pos('%', L) > 0 Then Exit;
  If Pos('em', L) > 0 Then V := V * 16 + (F * 16) Div D
  Else If Pos('pt', L) > 0 Then V := (V * 4) Div 3
  Else If Pos('ex', L) > 0 Then V := V * 8 + (F * 8) Div D;
  CssLen := MinI(96, V);
End;

{ "margin: a b c d" (1 a 4 valeurs) -> haut, droite, bas, gauche }
Procedure CssBox(V : String; Var T, R, B, L : LongInt);
Var W : Array[0..3] Of String; N, K : LongInt;
Begin
  N := 0; W[0] := ''; W[1] := ''; W[2] := ''; W[3] := '';
  V := TrimS(V);
  For K := 1 To Length(V) Do
  Begin
    If V[K] = ' ' Then
    Begin
      If (W[N] <> '') And (N < 3) Then Inc(N);
    End
    Else W[N] := W[N] + V[K];
  End;
  If W[N] = '' Then Dec(N);
  If N < 0 Then Exit;
  T := CssLen(W[0]);
  If N = 0 Then
  Begin
    R := T; B := T; L := T;
  End
  Else If N = 1 Then
  Begin
    B := T; R := CssLen(W[1]); L := R;
  End
  Else If N = 2 Then
  Begin
    R := CssLen(W[1]); L := R; B := CssLen(W[2]);
  End
  Else
  Begin
    R := CssLen(W[1]); B := CssLen(W[2]); L := CssLen(W[3]);
  End;
End;

Function CssSize(S : String) : LongInt;
Var V : LongInt; L : String;
Begin
  L := LowStr(TrimS(S));
  CssSize := 0;
  If (L = 'xx-small') Or (L = 'x-small') Then CssSize := 1
  Else If L = 'small' Then CssSize := 2
  Else If L = 'medium' Then CssSize := 3
  Else If L = 'large' Then CssSize := 4
  Else If L = 'x-large' Then CssSize := 5
  Else If L = 'xx-large' Then CssSize := 6
  Else
  Begin
    V := SVal(L, 0);
    If V <= 0 Then Exit;
    If Pos('em', L) > 0 Then V := V * 16
    Else If Pos('%', L) > 0 Then V := (V * 16) Div 100
    Else If Pos('pt', L) > 0 Then V := (V * 4) Div 3;
    If V <= 11 Then CssSize := 1
    Else If V <= 14 Then CssSize := 2
    Else If V <= 18 Then CssSize := 3
    Else If V <= 22 Then CssSize := 4
    Else If V <= 28 Then CssSize := 5
    Else If V <= 34 Then CssSize := 6
    Else CssSize := 7;
  End;
End;

{ une declaration "prop: valeur" appliquee a St }
Procedure ApplyDecl(Var St : TStyle; P, V : String);
Var L : String; C, K : LongInt;
Begin
  P := LowStr(TrimS(P));
  V := TrimS(V);
  K := Pos('!important', LowStr(V));
  If K > 0 Then V := TrimS(Copy(V, 1, K - 1));
  L := LowStr(V);
  If P = 'color' Then
  Begin
    C := ParseColor(L);
    If C >= 0 Then St.Color := C;
  End
  Else If (P = 'background-color') Or (P = 'background') Then
  Begin
    If (L = 'transparent') Or (L = 'none') Then St.Back := -2
    Else
    Begin
      { premier mot de couleur de "background" }
      C := ParseColor(L);
      If C < 0 Then
      Begin
        K := Pos(' ', L);
        If K > 0 Then C := ParseColor(Copy(L, 1, K - 1));
        If (C < 0) And (Pos('#', L) > 0) Then C := ParseColor(Copy(L, Pos('#', L), 7));
      End;
      If C >= 0 Then St.Back := C;
    End;
  End
  Else If P = 'display' Then
  Begin
    If L = 'none' Then St.Display := 1
    Else If (L = 'block') Or (L = 'list-item') Or (L = 'flex') Or (L = 'grid') Or (L = 'table') Then St.Display := 2
    Else If (L = 'inline') Or (L = 'inline-block') Or (L = 'inline-flex') Then St.Display := 3;
  End
  Else If P = 'visibility' Then
  Begin
    If L = 'hidden' Then St.Display := 1;
  End
  Else If P = 'text-align' Then
  Begin
    If L = 'center' Then St.Align := 2
    Else If L = 'right' Then St.Align := 3
    Else If (L = 'left') Or (L = 'justify') Then St.Align := 1;
  End
  Else If P = 'font-weight' Then
  Begin
    If (L = 'bold') Or (L = 'bolder') Or (SVal(L, 0) >= 600) Then St.Bold := 1
    Else If (L = 'normal') Or (L = 'lighter') Or ((SVal(L, 0) > 0) And (SVal(L, 0) < 600)) Then St.Bold := 2;
  End
  Else If P = 'font-style' Then
  Begin
    If (L = 'italic') Or (L = 'oblique') Then St.Italic := 1 Else If L = 'normal' Then St.Italic := 2;
  End
  Else If (P = 'text-decoration') Or (P = 'text-decoration-line') Then
  Begin
    If Pos('underline', L) > 0 Then St.Under := 1 Else If L = 'none' Then St.Under := 2;
  End
  Else If P = 'font-size' Then
  Begin
    C := CssSize(L);
    If C > 0 Then St.Size := C;
  End
  Else If P = 'font' Then
  Begin
    If Pos('bold', L) > 0 Then St.Bold := 1;
    If Pos('italic', L) > 0 Then St.Italic := 1;
  End
  Else If P = 'width' Then
  Begin
    If (Pos('px', L) > 0) And (SVal(L, 0) > 0) Then St.Width := SVal(L, 0);
  End
  Else If P = 'margin' Then CssBox(L, St.MarT, St.MarR, St.MarB, St.MarL)
  Else If P = 'padding' Then CssBox(L, St.PadT, St.PadR, St.PadB, St.PadL)
  Else If P = 'margin-top' Then St.MarT := CssLen(L)
  Else If P = 'margin-right' Then St.MarR := CssLen(L)
  Else If P = 'margin-bottom' Then St.MarB := CssLen(L)
  Else If P = 'margin-left' Then St.MarL := CssLen(L)
  Else If P = 'padding-top' Then St.PadT := CssLen(L)
  Else If P = 'padding-right' Then St.PadR := CssLen(L)
  Else If P = 'padding-bottom' Then St.PadB := CssLen(L)
  Else If P = 'padding-left' Then St.PadL := CssLen(L);
End;

Procedure StyleInit(Var St : TStyle);
Begin
  St.Color := -1; St.Back := -1; St.Display := 0; St.Align := 0;
  St.Bold := 0; St.Italic := 0; St.Under := 0; St.Size := 0; St.Width := 0;
  St.MarT := -1; St.MarR := -1; St.MarB := -1; St.MarL := -1;
  St.PadT := -1; St.PadR := -1; St.PadB := -1; St.PadL := -1;
End;

{ declarations "a: b; c: d" lues dans l'arene (A, N) }
Procedure ApplyDecls(Var St : TStyle; A, N : LongInt);
Var I, C : LongInt; P, V : String; InVal : Boolean; Depth : LongInt;
Begin
  P := ''; V := ''; InVal := False; Depth := 0;
  For I := 0 To N Do
  Begin
    If I < N Then C := RdB(A + I) Else C := 59;
    If C = 40 Then Inc(Depth) Else If (C = 41) And (Depth > 0) Then Dec(Depth);
    If (C = 59) And (Depth = 0) Then
    Begin
      If InVal Then ApplyDecl(St, P, V);
      P := ''; V := ''; InVal := False;
    End
    Else If (C = 58) And Not InVal Then InVal := True
    Else If C >= 32 Then
    Begin
      If InVal Then
      Begin
        If Length(V) < 200 Then V := V + Chr(C);
      End
      Else If Length(P) < 40 Then P := P + Chr(C);
    End
    Else If InVal And (Length(V) < 200) Then V := V + ' ';
  End;
End;

{ selecteur compose "tag#id.cls.cls2" -> partie K de R ; faux si non pris
  en charge (attributs, pseudo-elements) }
Function ParseCompound(S : String; R : PRule; K : LongInt) : Boolean;
Var I : LongInt; Mode : Char; W : String;
Begin
  ParseCompound := False;
  R^.PTag[K] := ''; R^.PId[K] := ''; R^.PCls[K] := ''; R^.PCls2[K] := '';
  If S = '' Then Exit;
  If (Pos('[', S) > 0) Or (Pos('::', S) > 0) Then Exit;
  { pseudo-classes : seules :link et :visited (liens) sont gardees }
  I := Pos(':', S);
  If I > 0 Then
  Begin
    W := LowStr(Copy(S, I + 1, 20));
    If (W <> 'link') And (W <> 'visited') Then Exit;
    S := Copy(S, 1, I - 1);
    If S = '' Then S := 'a';
  End;
  Mode := 't'; W := '';
  For I := 1 To Length(S) + 1 Do
  Begin
    If (I > Length(S)) Or (S[I] = '#') Or (S[I] = '.') Then
    Begin
      If W <> '' Then
        Case Mode Of
          't' : If W <> '*' Then R^.PTag[K] := LowStr(Copy(W, 1, 15));
          '#' : R^.PId[K] := Copy(W, 1, 23);
          '.' : If R^.PCls[K] = '' Then R^.PCls[K] := Copy(W, 1, 23) Else R^.PCls2[K] := Copy(W, 1, 23);
        End;
      W := '';
      If I <= Length(S) Then Mode := S[I];
    End
    Else W := W + S[I];
  End;
  ParseCompound := True;
End;

{ un selecteur (sans virgule) et ses declarations }
Procedure AddRule(Sel : String; DA, DN : LongInt);
Var R : PRule; Parts : Array[0..3] Of String[63]; N, K, I : LongInt; W : String; Ok : Boolean;
Begin
  If NRules >= MAX_CSS Then Exit;
  Sel := TrimS(Sel);
  If Sel = '' Then Exit;
  { composes separes par des espaces ou ">" (traite comme descendant) }
  N := 0; W := '';
  For I := 1 To Length(Sel) + 1 Do
  Begin
    If (I > Length(Sel)) Or (Sel[I] = ' ') Or (Sel[I] = '>') Or (Sel[I] = '+') Or (Sel[I] = '~') Then
    Begin
      If W <> '' Then
      Begin
        If (Sel[MinI(I, Length(Sel))] = '+') Or (Sel[MinI(I, Length(Sel))] = '~') Then Exit;
        If N >= 4 Then Exit;
        Parts[N] := W;
        Inc(N);
      End;
      W := '';
    End
    Else W := W + Sel[I];
  End;
  If N = 0 Then Exit;
  R := Pointer(ArAlloc(SizeOf(TRule)));
  If R = Nil Then Exit;
  R^.NPart := N;
  R^.Spec := 0;
  Ok := True;
  For K := 0 To N - 1 Do
  Begin
    { partie 0 : la plus a droite }
    If Not ParseCompound(Parts[N - 1 - K], R, K) Then Ok := False;
    If R^.PId[K] <> '' Then R^.Spec := R^.Spec + 100;
    If R^.PCls[K] <> '' Then R^.Spec := R^.Spec + 10;
    If R^.PCls2[K] <> '' Then R^.Spec := R^.Spec + 10;
    If R^.PTag[K] <> '' Then R^.Spec := R^.Spec + 1;
  End;
  If Not Ok Then Exit;
  StyleInit(R^.St);
  ApplyDecls(R^.St, DA, DN);
  R^.Order := NRules;
  Rules[NRules] := R;
  Inc(NRules);
End;

{ feuille de style A..A+N-1 : regles "sel, sel (accolade) decl (accolade)", commentaires et
  @media (le contenu des @media screen/all est lu, les autres ignores) }
Procedure ParseCss(A, N : LongInt);
Var I, J, Lvl, B : LongInt; Sel, W : String; C : LongInt; Skip : Boolean;
Begin
  I := 0;
  While I < N Do
  Begin
    { commentaire }
    If (RdB(A + I) = 47) And (I + 1 < N) And (RdB(A + I + 1) = 42) Then
    Begin
      I := I + 2;
      While (I + 1 < N) And Not ((RdB(A + I) = 42) And (RdB(A + I + 1) = 47)) Do Inc(I);
      I := I + 2;
      Continue;
    End;
    { selecteur jusqu'a l'accolade ouvrante }
    Sel := '';
    While (I < N) And (RdB(A + I) <> 123) And (RdB(A + I) <> 125) Do
    Begin
      C := RdB(A + I);
      If (C = 47) And (I + 1 < N) And (RdB(A + I + 1) = 42) Then Break;
      If C < 32 Then C := 32;
      If (Length(Sel) < 250) And Not ((C = 32) And (Length(Sel) > 0) And (Sel[Length(Sel)] = ' ')) Then Sel := Sel + Chr(C);
      Inc(I);
    End;
    If I >= N Then Break;
    If (RdB(A + I) = 47) Then Continue;
    If RdB(A + I) = 125 Then
    Begin
      Inc(I);
      Continue;
    End;
    Inc(I);
    Sel := TrimS(Sel);
    If (Length(Sel) > 0) And (Sel[1] = '@') Then
    Begin
      W := LowStr(Sel);
      Skip := Not ((Copy(W, 1, 6) = '@media') And ((Pos('screen', W) > 0) Or (Pos('all', W) > 0)) And
                   (Pos('max-width', W) = 0) And (Pos('print', W) = 0));
      If Not Skip Then Continue;     { regles internes lues normalement }
      { bloc @ ignore (en entier, accolades imbriquees) }
      Lvl := 1;
      While (I < N) And (Lvl > 0) Do
      Begin
        If RdB(A + I) = 123 Then Inc(Lvl) Else If RdB(A + I) = 125 Then Dec(Lvl);
        Inc(I);
      End;
      Continue;
    End;
    { declarations jusqu'a l'accolade fermante }
    J := I;
    While (J < N) And (RdB(A + J) <> 125) Do Inc(J);
    B := 1;
    W := '';
    For B := 1 To Length(Sel) + 1 Do
    Begin
      If (B > Length(Sel)) Or (Sel[B] = ',') Then
      Begin
        AddRule(W, A + I, J - I);
        W := '';
      End
      Else W := W + Sel[B];
    End;
    I := J + 1;
  End;
End;

{ classes de l'element (liste separee par des espaces) : la classe C y
  est-elle ? }
Function HasClass(N : PNode; C : String) : Boolean;
Var A : PAttr; I, L, S, J : LongInt; Ok : Boolean;
Begin
  HasClass := False;
  A := FindAttr(N, 'class');
  If (A = Nil) Or (C = '') Then Exit;
  L := Length(C);
  I := 0;
  While I < A^.VLen Do
  Begin
    While (I < A^.VLen) And (RdB(A^.Val + I) <= 32) Do Inc(I);
    S := I;
    While (I < A^.VLen) And (RdB(A^.Val + I) > 32) Do Inc(I);
    If I - S = L Then
    Begin
      Ok := True;
      For J := 0 To L - 1 Do
        If Chr(RdB(A^.Val + S + J)) <> C[J + 1] Then Ok := False;
      If Ok Then
      Begin
        HasClass := True;
        Exit;
      End;
    End;
  End;
End;

Function MatchPart(N : PNode; R : PRule; K : LongInt) : Boolean;
Begin
  MatchPart := False;
  If (N = Nil) Or (N^.Kind <> NODE_ELEM) Then Exit;
  If (R^.PTag[K] <> '') And (R^.PTag[K] <> N^.Name) Then Exit;
  If (R^.PId[K] <> '') And (GetAttr(N, 'id') <> R^.PId[K]) Then Exit;
  If (R^.PCls[K] <> '') And Not HasClass(N, R^.PCls[K]) Then Exit;
  If (R^.PCls2[K] <> '') And Not HasClass(N, R^.PCls2[K]) Then Exit;
  MatchPart := True;
End;

Function MatchRule(N : PNode; R : PRule) : Boolean;
Var K : LongInt; P : PNode;
Begin
  MatchRule := False;
  If Not MatchPart(N, R, 0) Then Exit;
  P := N^.Parent;
  For K := 1 To R^.NPart - 1 Do
  Begin
    While (P <> Nil) And Not MatchPart(P, R, K) Do P := P^.Parent;
    If P = Nil Then Exit;
    P := P^.Parent;
  End;
  MatchRule := True;
End;

Procedure MergeStyle(Var D : TStyle; Var S : TStyle);
Begin
  If S.Color >= 0 Then D.Color := S.Color;
  If S.Back <> -1 Then D.Back := S.Back;
  If S.Display <> 0 Then D.Display := S.Display;
  If S.Align <> 0 Then D.Align := S.Align;
  If S.Bold <> 0 Then D.Bold := S.Bold;
  If S.Italic <> 0 Then D.Italic := S.Italic;
  If S.Under <> 0 Then D.Under := S.Under;
  If S.Size <> 0 Then D.Size := S.Size;
  If S.Width <> 0 Then D.Width := S.Width;
  If S.MarT >= 0 Then D.MarT := S.MarT;
  If S.MarR >= 0 Then D.MarR := S.MarR;
  If S.MarB >= 0 Then D.MarB := S.MarB;
  If S.MarL >= 0 Then D.MarL := S.MarL;
  If S.PadT >= 0 Then D.PadT := S.PadT;
  If S.PadR >= 0 Then D.PadR := S.PadR;
  If S.PadB >= 0 Then D.PadB := S.PadB;
  If S.PadL >= 0 Then D.PadL := S.PadL;
End;

{ style calcule d'un element (garde dans le noeud) ; Nil : aucun }
Function NodeStyle(N : PNode) : PStyle;
Var St : TStyle; K, J, Best, BestI : LongInt; Any : Boolean; A : PAttr; P : PStyle;
    Hit : Array[0..63] Of LongInt; NHit : LongInt;
Begin
  NodeStyle := Nil;
  If (N = Nil) Or (N^.Kind <> NODE_ELEM) Then Exit;
  If N^.Css = 1 Then Exit;
  If N^.Css > 1 Then
  Begin
    NodeStyle := Pointer(N^.Css);
    Exit;
  End;
  StyleInit(St);
  Any := False;
  { regles qui s'appliquent, par specificite puis ordre }
  NHit := 0;
  For K := 0 To NRules - 1 Do
    If (NHit < 64) And MatchRule(N, Rules[K]) Then
    Begin
      Hit[NHit] := K;
      Inc(NHit);
    End;
  For J := 1 To NHit Do
  Begin
    Best := 2147483647; BestI := -1;
    For K := 0 To NHit - 1 Do
      If Hit[K] >= 0 Then
      Begin
        If BestI < 0 Then
        Begin
          Best := Rules[Hit[K]]^.Spec; BestI := K;
        End
        Else If Rules[Hit[K]]^.Spec < Best Then
        Begin
          Best := Rules[Hit[K]]^.Spec; BestI := K;
        End
        Else If (Rules[Hit[K]]^.Spec = Best) And (Rules[Hit[K]]^.Order < Rules[Hit[BestI]]^.Order) Then
        Begin
          Best := Rules[Hit[K]]^.Spec; BestI := K;
        End;
      End;
    If BestI < 0 Then Break;
    MergeStyle(St, Rules[Hit[BestI]]^.St);
    Hit[BestI] := -1;
    Any := True;
  End;
  A := FindAttr(N, 'style');
  If A <> Nil Then
  Begin
    ApplyDecls(St, A^.Val, A^.VLen);
    Any := True;
  End;
  If Not Any Then
  Begin
    N^.Css := 1;
    Exit;
  End;
  P := Pointer(ArAlloc(SizeOf(TStyle)));
  If P = Nil Then
  Begin
    N^.Css := 1;
    Exit;
  End;
  P^ := St;
  N^.Css := LongInt(P);
  NodeStyle := P;
End;

{ toutes les feuilles <style> du document }
Procedure CollectStyles(N : PNode);
Var C : PNode;
Begin
  If N = Nil Then Exit;
  C := N^.First;
  While C <> Nil Do
  Begin
    If (C^.Kind = NODE_ELEM) And (C^.Tag = TAG_STYLE) Then
    Begin
      If (C^.First <> Nil) And (C^.First^.Kind = NODE_TEXT) And
         ((GetAttr(C, 'media') = '') Or (Pos('screen', LowStr(GetAttr(C, 'media'))) > 0) Or
          (Pos('all', LowStr(GetAttr(C, 'media'))) > 0)) Then
        ParseCss(C^.First^.Txt, C^.First^.TLen);
    End
    Else If (C^.Kind = NODE_ELEM) And (C^.Tag = TAG_LINK) Then
    Begin
      { feuille externe chargee par le navigateur (attribut interne #css) }
      If (FindAttr(C, '#css') <> Nil) And
         ((GetAttr(C, 'media') = '') Or (Pos('screen', LowStr(GetAttr(C, 'media'))) > 0) Or
          (Pos('all', LowStr(GetAttr(C, 'media'))) > 0)) Then
        ParseCss(FindAttr(C, '#css')^.Val, FindAttr(C, '#css')^.VLen);
    End
    Else If C^.Kind = NODE_ELEM Then CollectStyles(C);
    C := C^.Next;
  End;
End;

{ ==================================================================== }
{ Formulaires et images de la page (registres gardes entre deux mises  }
{ en page)                                                             }
{ ==================================================================== }

Var
  NForms : LongInt;
  FmNode : Array[0..MAX_FORMS - 1] Of PNode;
  NCtls : LongInt;
  CtType, CtForm, CtSel, CtImg : Array[0..MAX_CTRLS - 1] Of LongInt;
  CtNode : Array[0..MAX_CTRLS - 1] Of PNode;
  CtChk : Array[0..MAX_CTRLS - 1] Of Boolean;
  CtVal : Array[0..MAX_CTRLS - 1] Of String;
  CtX, CtY, CtW, CtH : Array[0..MAX_CTRLS - 1] Of LongInt;
  FocusCtl : LongInt;
  NImgs : LongInt;
  ImUrl, ImState, ImW, ImH, ImBits, ImBmi : Array[0..MAX_IMGS - 1] Of LongInt;
  ImgNext : LongInt;
  LoadImages : Boolean;
  PageBg, PageFg, LinkFg : LongInt;

Function CtlTypeOf(N : PNode) : LongInt;
Var T : String;
Begin
  CtlTypeOf := 0;
  Case N^.Tag Of
    TAG_SELECT : CtlTypeOf := CT_SELECT;
    TAG_TEXTAREA : CtlTypeOf := CT_TEXTAREA;
    TAG_BUTTON :
      Begin
        T := LowStr(GetAttr(N, 'type'));
        If T = 'reset' Then CtlTypeOf := CT_RESET
        Else If T = 'button' Then CtlTypeOf := CT_BUTTON
        Else CtlTypeOf := CT_SUBMIT;
      End;
    TAG_INPUT :
      Begin
        T := LowStr(GetAttr(N, 'type'));
        If (T = '') Or (T = 'text') Or (T = 'search') Or (T = 'email') Or (T = 'url') Or (T = 'tel') Or
           (T = 'number') Or (T = 'date') Then CtlTypeOf := CT_TEXT
        Else If T = 'password' Then CtlTypeOf := CT_PASSWORD
        Else If T = 'submit' Then CtlTypeOf := CT_SUBMIT
        Else If T = 'checkbox' Then CtlTypeOf := CT_CHECK
        Else If T = 'radio' Then CtlTypeOf := CT_RADIO
        Else If T = 'hidden' Then CtlTypeOf := CT_HIDDEN
        Else If T = 'button' Then CtlTypeOf := CT_BUTTON
        Else If T = 'reset' Then CtlTypeOf := CT_RESET
        Else If T = 'image' Then CtlTypeOf := CT_IMAGE
        Else If T = 'file' Then CtlTypeOf := CT_BUTTON
        Else CtlTypeOf := CT_TEXT;
      End;
  End;
End;

Function AddImage(Src : String) : LongInt;
Var K : LongInt; U : String;
Begin
  AddImage := -1;
  Src := TrimS(Src);
  If (Src = '') Or StartsWith(Src, 'data:') Or StartsWith(Src, 'javascript:') Then Exit;
  U := ResolveUrl(BaseUrl, Src);
  { meme image deja demandee }
  For K := 0 To NImgs - 1 Do
    If ArGet(ImUrl[K], RdB(ImUrl[K] - 1)) = U Then
    Begin
      AddImage := K;
      Exit;
    End;
  If NImgs >= MAX_IMGS Then Exit;
  K := ArAlloc(Length(U) + 2);
  If K = 0 Then Exit;
  WrB(K, Length(U));
  MemCopy(LongInt(@U[1]), K + 1, Length(U));
  ImUrl[NImgs] := K + 1;
  ImState[NImgs] := 0; ImW[NImgs] := 0; ImH[NImgs] := 0; ImBits[NImgs] := 0; ImBmi[NImgs] := 0;
  AddImage := NImgs;
  Inc(NImgs);
End;

Function ImgUrlOf(I : LongInt) : String;
Begin
  ImgUrlOf := ArGet(ImUrl[I], RdB(ImUrl[I] - 1));
End;

{ premier passage sur l'arbre : formulaires, controles, images, couleurs
  du corps du document }
Procedure ScanDoc(N : PNode; Form : LongInt);
Var C : PNode; T, K : LongInt; S : String;
Begin
  If N = Nil Then Exit;
  C := N^.First;
  While C <> Nil Do
  Begin
    If C^.Kind = NODE_ELEM Then
    Begin
      Case C^.Tag Of
        TAG_FORM :
          If NForms < MAX_FORMS Then
          Begin
            FmNode[NForms] := C;
            Inc(NForms);
            ScanDoc(C, NForms - 1);
            C := C^.Next;
            Continue;
          End;
        TAG_BODY :
          Begin
            S := GetAttr(C, 'bgcolor');
            If ParseColor(S) >= 0 Then PageBg := ParseColor(S);
            S := GetAttr(C, 'text');
            If ParseColor(S) >= 0 Then PageFg := ParseColor(S);
            S := GetAttr(C, 'link');
            If ParseColor(S) >= 0 Then LinkFg := ParseColor(S);
          End;
        TAG_IMG :
          C^.Aux := AddImage(GetAttr(C, 'src')) + 1;
      End;
      T := CtlTypeOf(C);
      If (T <> 0) And (NCtls < MAX_CTRLS) Then
      Begin
        K := NCtls;
        Inc(NCtls);
        C^.Aux := K + 1;
        CtType[K] := T; CtNode[K] := C; CtForm[K] := Form; CtChk[K] := HasAttr(C, 'checked');
        CtSel[K] := 0; CtImg[K] := -1;
        If T = CT_TEXTAREA Then CtVal[K] := NodeText(C)
        Else CtVal[K] := GetAttr(C, 'value');
        If T = CT_IMAGE Then CtImg[K] := AddImage(GetAttr(C, 'src'));
      End;
      If (C^.Tag <> TAG_SELECT) And (C^.Tag <> TAG_TEXTAREA) Then ScanDoc(C, Form);
    End;
    C := C^.Next;
  End;
End;

{ options d'une liste deroulante : nombre, texte et valeur de la Ieme }
Function OptCount(Sel : PNode) : LongInt;
Var C, G : PNode; N : LongInt;
Begin
  N := 0;
  C := Sel^.First;
  While C <> Nil Do
  Begin
    If (C^.Kind = NODE_ELEM) And (C^.Tag = TAG_OPTION) Then Inc(N)
    Else If (C^.Kind = NODE_ELEM) And (C^.Tag = TAG_OPTGROUP) Then
    Begin
      G := C^.First;
      While G <> Nil Do
      Begin
        If (G^.Kind = NODE_ELEM) And (G^.Tag = TAG_OPTION) Then Inc(N);
        G := G^.Next;
      End;
    End;
    C := C^.Next;
  End;
  OptCount := N;
End;

Function OptNode(Sel : PNode; I : LongInt) : PNode;
Var C, G : PNode; N : LongInt;
Begin
  OptNode := Nil;
  N := 0;
  C := Sel^.First;
  While C <> Nil Do
  Begin
    If (C^.Kind = NODE_ELEM) And (C^.Tag = TAG_OPTION) Then
    Begin
      If N = I Then
      Begin
        OptNode := C;
        Exit;
      End;
      Inc(N);
    End
    Else If (C^.Kind = NODE_ELEM) And (C^.Tag = TAG_OPTGROUP) Then
    Begin
      G := C^.First;
      While G <> Nil Do
      Begin
        If (G^.Kind = NODE_ELEM) And (G^.Tag = TAG_OPTION) Then
        Begin
          If N = I Then
          Begin
            OptNode := G;
            Exit;
          End;
          Inc(N);
        End;
        G := G^.Next;
      End;
    End;
    C := C^.Next;
  End;
End;

Function OptText(Sel : PNode; I : LongInt) : String;
Begin
  OptText := TrimS(NodeText(OptNode(Sel, I)));
End;

Function OptValue(Sel : PNode; I : LongInt) : String;
Var O : PNode;
Begin
  O := OptNode(Sel, I);
  If O = Nil Then OptValue := ''
  Else If HasAttr(O, 'value') Then OptValue := GetAttr(O, 'value')
  Else OptValue := TrimS(NodeText(O));
End;

Procedure InitSelects;
Var K, I : LongInt;
Begin
  For K := 0 To NCtls - 1 Do
    If CtType[K] = CT_SELECT Then
    Begin
      CtSel[K] := 0;
      For I := 0 To OptCount(CtNode[K]) - 1 Do
        If HasAttr(OptNode(CtNode[K], I), 'selected') Then CtSel[K] := I;
    End;
End;

{ ==================================================================== }
{ Mise en page : liste d'affichage dans une arene propre, refaite a     }
{ chaque changement de largeur ou d'image                               }
{ ==================================================================== }

Type
  TSt = Record
    Color, Back, Link : LongInt;
    Scale, Flags, Align, Pre, NoWrap : Byte;
  End;

Const
  CharWs : Array[1..3] Of LongInt = (8, 12, 16);
  CharHs : Array[1..3] Of LongInt = (16, 24, 32);
  MAX_LINE = 400;

Var
  LaBase, LaUsed, LaSize : LongInt;
  OpFirst, OpLast : POp;
  CurElem : PNode;                { element en cours de mise en page }
  LX0, LX1, CurY, CurAlign, VGap : LongInt;
  LnN, LnW : LongInt;
  LnOp : Array[0..MAX_LINE - 1] Of POp;
  PendSpace : Boolean;
  PageH, PageW, LayGen : LongInt;
  MLine, MMin, MMax : LongInt;
  NAnch : LongInt;
  AnchName : Array[0..199] Of String[31];
  AnchY : Array[0..199] Of LongInt;
  ViewSource : Boolean;
  PlainText : Boolean;            { document text/plain (noir, pas de couleurs de source) }

Procedure LaInit;
Begin
  LaBase := 0; LaSize := 4194304;
  If DosAllocMem(LongInt(@LaBase), LaSize, $13) <> 0 Then
  Begin
    LaBase := 0; LaSize := 1048576;
    If DosAllocMem(LongInt(@LaBase), LaSize, $13) <> 0 Then LaBase := 0;
  End;
  LaUsed := 0;
End;

Function LaAlloc(N : LongInt) : LongInt;
Begin
  LaAlloc := 0;
  N := (N + 3) And Not 3;
  If (LaBase = 0) Or (LaUsed + N > LaSize) Then Exit;
  LaAlloc := LaBase + LaUsed;
  MemFill(LaBase + LaUsed, N, 0);
  LaUsed := LaUsed + N;
End;

Function LaStr(S : String) : LongInt;
Var A, K : LongInt;
Begin
  A := LaAlloc(Length(S) + 1);
  If A <> 0 Then
    For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  LaStr := A;
End;

Function NewOp(Kind : LongInt) : POp;
Var O : POp;
Begin
  O := Pointer(LaAlloc(SizeOf(TOp)));
  If O <> Nil Then
  Begin
    O^.Kind := Kind;
    O^.Elem := CurElem;
    If OpLast = Nil Then OpFirst := O Else OpLast^.Next := O;
    OpLast := O;
  End;
  NewOp := O;
End;

{ rectangle plein (fond) ; la hauteur peut etre corrigee plus tard }
Function RectOp(X, Y, W, H, C : LongInt) : POp;
Var O : POp;
Begin
  O := NewOp(OP_RECT);
  If O <> Nil Then
  Begin
    O^.X := X; O^.Y := Y; O^.W := W; O^.H := H; O^.Color := C;
  End;
  RectOp := O;
End;

Function FrameOp(X, Y, W, H, C : LongInt) : POp;
Var O : POp;
Begin
  O := NewOp(OP_FRAME);
  If O <> Nil Then
  Begin
    O^.X := X; O^.Y := Y; O^.W := W; O^.H := H; O^.Color := C;
  End;
  FrameOp := O;
End;

Procedure ShiftOps(After, Last : POp; Dy : LongInt);
Var O : POp;
Begin
  If (Dy = 0) Or (Last = Nil) Then Exit;
  If After = Nil Then O := OpFirst Else O := After^.Next;
  While O <> Nil Do
  Begin
    O^.Y := O^.Y + Dy;
    If O = Last Then Exit;
    O := O^.Next;
  End;
End;

{ espace vertical (les marges consecutives se confondent) }
Procedure VSpace(M : LongInt);
Begin
  If M > VGap Then
  Begin
    CurY := CurY + M - VGap;
    VGap := M;
  End;
End;

{ fin de la ligne courante : hauteur, alignement, position verticale }
Procedure FlushLine;
Var K, H, Dx : LongInt;
Begin
  If LnN = 0 Then
  Begin
    LnW := 0;
    Exit;
  End;
  H := 0;
  For K := 0 To LnN - 1 Do
    If LnOp[K]^.H > H Then H := LnOp[K]^.H;
  Dx := 0;
  If CurAlign = 2 Then Dx := MaxI(0, (LX1 - LX0 - LnW) Div 2)
  Else If CurAlign = 3 Then Dx := MaxI(0, LX1 - LX0 - LnW);
  For K := 0 To LnN - 1 Do
  Begin
    LnOp[K]^.X := LnOp[K]^.X + Dx;
    LnOp[K]^.Y := CurY + H - LnOp[K]^.H;
  End;
  CurY := CurY + H + 2;
  VGap := 0;
  LnN := 0; LnW := 0;
  PendSpace := False;
End;

{ saut de ligne force (<br>) }
Procedure LineBreak(Var St : TSt);
Begin
  If LnN = 0 Then
  Begin
    CurY := CurY + CharHs[St.Scale] + 2;
    VGap := 0;
  End
  Else FlushLine;
End;

{ place un element de W x H pels sur la ligne (retour a la ligne si
  necessaire) ; rend sa position X }
Function PlaceItem(W : LongInt; Var St : TSt) : LongInt;
Var Sp : LongInt;
Begin
  If PendSpace And (LnN > 0) Then Sp := CharWs[St.Scale] Else Sp := 0;
  If (LnN > 0) And (St.NoWrap = 0) And (LnW + Sp + W > LX1 - LX0) Then
  Begin
    FlushLine;
    Sp := 0;
  End;
  PlaceItem := LX0 + LnW + Sp;
  LnW := LnW + Sp + W;
  PendSpace := False;
End;

Procedure PushLine(O : POp);
Begin
  If O = Nil Then Exit;
  If LnN >= MAX_LINE Then FlushLine;
  LnOp[LnN] := O;
  Inc(LnN);
End;

Procedure AddWord(A, N : LongInt; Var St : TSt);
Var O : POp; W, Cw, Fit, X : LongInt;
Begin
  Cw := CharWs[St.Scale];
  While N > 0 Do
  Begin
    W := N * Cw;
    { mot plus large que la ligne : coupe }
    Fit := N;
    If (W > LX1 - LX0) And (St.NoWrap = 0) Then
    Begin
      If LnN > 0 Then FlushLine;
      Fit := MaxI(1, (LX1 - LX0) Div Cw);
      If Fit > N Then Fit := N;
      W := Fit * Cw;
    End;
    X := PlaceItem(W, St);
    O := NewOp(OP_TEXT);
    If O = Nil Then Exit;
    O^.X := X; O^.W := W; O^.H := CharHs[St.Scale];
    O^.Data := A; O^.Len := Fit;
    O^.Color := St.Color; O^.Style := St.Flags; O^.Size := St.Scale; O^.Link := St.Link;
    PushLine(O);
    A := A + Fit; N := N - Fit;
  End;
End;

{ texte d'un noeud : mots, espaces regroupes (sauf <pre>) }
Procedure AddText(T : PNode; Var St : TSt);
Var I, J, N, C : LongInt;
Begin
  N := T^.TLen;
  I := 0;
  If St.Pre <> 0 Then
  Begin
    While I < N Do
    Begin
      J := I;
      While (J < N) And (RdB(T^.Txt + J) <> 10) And (RdB(T^.Txt + J) <> 13) Do Inc(J);
      If J > I Then AddWord(T^.Txt + I, J - I, St);
      If J < N Then
      Begin
        If RdB(T^.Txt + J) = 13 Then
        Begin
          If (J + 1 < N) And (RdB(T^.Txt + J + 1) = 10) Then Inc(J);
        End;
        LineBreak(St);
      End;
      I := J + 1;
    End;
    Exit;
  End;
  While I < N Do
  Begin
    C := RdB(T^.Txt + I);
    If (C = 32) Or (C = 9) Or (C = 10) Or (C = 13) Or (C = 12) Then
    Begin
      PendSpace := True;
      Inc(I);
    End
    Else
    Begin
      J := I;
      While J < N Do
      Begin
        C := RdB(T^.Txt + J);
        If (C = 32) Or (C = 9) Or (C = 10) Or (C = 13) Or (C = 12) Then Break;
        Inc(J);
      End;
      AddWord(T^.Txt + I, J - I, St);
      I := J;
    End;
  End;
End;

{ texte genere (puces, etiquettes) }
Procedure AddStr(S : String; Var St : TSt);
Var A : LongInt;
Begin
  If S = '' Then Exit;
  A := LaStr(S);
  If A <> 0 Then AddWord(A, Length(S), St);
End;

{ --- tailles des images et des controles --- }

Procedure AttrSize(N : PNode; Var W, H : LongInt);
Var S : String;
Begin
  W := 0; H := 0;
  S := GetAttr(N, 'width');
  If (S <> '') And (Pos('%', S) = 0) Then W := SVal(S, 0);
  S := GetAttr(N, 'height');
  If (S <> '') And (Pos('%', S) = 0) Then H := SVal(S, 0);
  If (W < 0) Or (W > 4000) Then W := 0;
  If (H < 0) Or (H > 4000) Then H := 0;
End;

Procedure ImgSize(N : PNode; I : LongInt; Var W, H : LongInt);
Var Aw, Ah : LongInt;
Begin
  AttrSize(N, Aw, Ah);
  W := Aw; H := Ah;
  If (I >= 0) And (ImState[I] = 1) And (ImW[I] > 0) And (ImH[I] > 0) Then
  Begin
    If (W = 0) And (H = 0) Then
    Begin
      W := ImW[I]; H := ImH[I];
    End
    Else If W = 0 Then W := (ImW[I] * H) Div ImH[I]
    Else If H = 0 Then H := (ImH[I] * W) Div ImW[I];
  End
  Else
  Begin
    If W = 0 Then
    Begin
      If GetAttr(N, 'alt') <> '' Then W := MinI(240, Length(GetAttr(N, 'alt')) * 8 + 8) Else W := 20;
    End;
    If H = 0 Then H := 20;
  End;
  If W < 1 Then W := 1;
  If H < 1 Then H := 1;
End;

Function CtlLabel(K : LongInt) : String;
Var S : String;
Begin
  S := CtVal[K];
  If CtNode[K]^.Tag = TAG_BUTTON Then S := TrimS(NodeText(CtNode[K]));
  If S = '' Then
    Case CtType[K] Of
      CT_SUBMIT : S := 'Envoyer';
      CT_RESET : S := 'Effacer';
      CT_IMAGE : S := GetAttr(CtNode[K], 'alt');
      CT_BUTTON : S := 'Bouton';
    End;
  If Length(S) > 40 Then S := Copy(S, 1, 40);
  CtlLabel := S;
End;

Procedure CtlSize(K : LongInt; Var W, H : LongInt);
Var N, I, L : LongInt; S : String;
Begin
  W := 0; H := 22;
  Case CtType[K] Of
    CT_TEXT, CT_PASSWORD :
      Begin
        N := SVal(GetAttr(CtNode[K], 'size'), 20);
        If (N < 2) Or (N > 80) Then N := 20;
        W := N * 8 + 8;
      End;
    CT_CHECK, CT_RADIO :
      Begin
        W := 14; H := 14;
      End;
    CT_SELECT :
      Begin
        L := 4;
        For I := 0 To MinI(OptCount(CtNode[K]), 60) - 1 Do
        Begin
          S := OptText(CtNode[K], I);
          If Length(S) > L Then L := Length(S);
        End;
        W := MinI(40, L) * 8 + 28;
      End;
    CT_TEXTAREA :
      Begin
        N := SVal(GetAttr(CtNode[K], 'cols'), 40);
        If (N < 4) Or (N > 100) Then N := 40;
        W := N * 8 + 8;
        N := SVal(GetAttr(CtNode[K], 'rows'), 3);
        If (N < 1) Or (N > 30) Then N := 3;
        H := N * 16 + 6;
      End;
    CT_IMAGE :
      If (CtImg[K] >= 0) Then ImgSize(CtNode[K], CtImg[K], W, H)
      Else W := Length(CtlLabel(K)) * 8 + 16;
    CT_HIDDEN : W := 0;
  Else
    W := Length(CtlLabel(K)) * 8 + 20;
  End;
End;

{ --- styles des elements --- }

Function IsBlockTag(T : LongInt) : Boolean;
Begin
  IsBlockTag := (T = TAG_P) Or (T = TAG_DIV) Or ((T >= TAG_H1) And (T <= TAG_H6)) Or (T = TAG_UL) Or
                (T = TAG_OL) Or (T = TAG_LI) Or (T = TAG_DL) Or (T = TAG_DT) Or (T = TAG_DD) Or (T = TAG_TABLE) Or
                (T = TAG_FORM) Or (T = TAG_HR) Or (T = TAG_PRE) Or (T = TAG_BLOCKQUOTE) Or (T = TAG_CENTER) Or
                (T = TAG_SECTION) Or (T = TAG_ARTICLE) Or (T = TAG_NAV) Or (T = TAG_ASIDE) Or (T = TAG_HEADER) Or
                (T = TAG_FOOTER) Or (T = TAG_MAIN) Or (T = TAG_ADDRESS) Or (T = TAG_FIELDSET) Or
                (T = TAG_LEGEND) Or (T = TAG_FIGURE) Or (T = TAG_FIGCAPTION) Or (T = TAG_DETAILS) Or
                (T = TAG_SUMMARY) Or (T = TAG_DIALOG) Or (T = TAG_MENU) Or (T = TAG_CAPTION) Or
                (T = TAG_BODY) Or (T = TAG_HTML) Or (T = TAG_NOSCRIPT) Or (T = TAG_TR) Or (T = TAG_TBODY) Or
                (T = TAG_THEAD) Or (T = TAG_TFOOT);
End;

Function IsHiddenTag(T : LongInt) : Boolean;
Begin
  IsHiddenTag := (T = TAG_HEAD) Or (T = TAG_SCRIPT) Or (T = TAG_STYLE) Or (T = TAG_TITLE) Or (T = TAG_TEMPLATE) Or
                 (T = TAG_META) Or (T = TAG_LINK) Or (T = TAG_BASE) Or (T = TAG_MAP) Or (T = TAG_AREA) Or
                 (T = TAG_OPTION) Or (T = TAG_OPTGROUP) Or (T = TAG_AUDIO) Or (T = TAG_VIDEO) Or
                 (T = TAG_CANVAS) Or (T = TAG_SVG) Or (T = TAG_EMBED) Or (T = TAG_OBJECT) Or (T = TAG_COLGROUP) Or
                 (T = TAG_COL) Or (T = TAG_DIALOG);
End;

Function FontScale(Size : LongInt) : LongInt;
Begin
  If Size >= 6 Then FontScale := 3
  Else If Size >= 5 Then FontScale := 2
  Else FontScale := 1;
End;

{ style herite + balise + attributs + CSS de N ; rend 0 : cache,
  1 : bloc, 2 : en ligne }
Function ApplyStyle(N : PNode; Var St : TSt) : LongInt;
Var D, Sz : LongInt; S : String; Cs : PStyle;
Begin
  If IsHiddenTag(N^.Tag) Or HasAttr(N, 'hidden') Then
  Begin
    ApplyStyle := 0;
    Exit;
  End;
  If IsBlockTag(N^.Tag) Then D := 1 Else D := 2;
  St.Back := -1;
  Case N^.Tag Of
    TAG_B, TAG_STRONG, TAG_TH, TAG_DT, TAG_SUMMARY, TAG_LEGEND : St.Flags := St.Flags Or ST_BOLD;
    TAG_I, TAG_EM, TAG_CITE, TAG_VAR, TAG_DFN, TAG_ADDRESS, TAG_Q : St.Flags := St.Flags Or ST_ITALIC;
    TAG_U, TAG_INS : St.Flags := St.Flags Or ST_UNDER;
    TAG_S, TAG_STRIKE, TAG_DEL : St.Flags := St.Flags Or ST_STRIKE;
    TAG_CODE, TAG_KBD, TAG_SAMP : St.Flags := St.Flags Or ST_MONO;
    TAG_PRE :
      Begin
        St.Pre := 1; St.Flags := St.Flags Or ST_MONO;
      End;
    TAG_H1 :
      Begin
        St.Scale := 3; St.Flags := St.Flags Or ST_BOLD;
      End;
    TAG_H2 :
      Begin
        St.Scale := 2; St.Flags := St.Flags Or ST_BOLD;
      End;
    TAG_H3, TAG_H4, TAG_H5, TAG_H6 :
      Begin
        St.Scale := 1; St.Flags := St.Flags Or ST_BOLD;
      End;
    TAG_BIG : If St.Scale < 3 Then Inc(St.Scale);
    TAG_CENTER : St.Align := 2;
    TAG_MARK : St.Back := $FFFF00;
    TAG_A :
      If HasAttr(N, 'href') Then
      Begin
        St.Link := LongInt(N);
        St.Color := LinkFg;
        St.Flags := St.Flags Or ST_UNDER;
      End;
    TAG_FONT :
      Begin
        S := GetAttr(N, 'color');
        If ParseColor(S) >= 0 Then St.Color := ParseColor(S);
        S := GetAttr(N, 'size');
        If S <> '' Then
        Begin
          If S[1] = '+' Then Sz := 3 + SVal(Copy(S, 2, 3), 0)
          Else If S[1] = '-' Then Sz := 3 - SVal(Copy(S, 2, 3), 0)
          Else Sz := SVal(S, 3);
          St.Scale := FontScale(Sz);
        End;
      End;
  End;
  { alignement (attribut align) }
  S := LowStr(GetAttr(N, 'align'));
  If (N^.Tag <> TAG_IMG) And (N^.Tag <> TAG_TABLE) Then
  Begin
    If S = 'center' Then St.Align := 2
    Else If S = 'right' Then St.Align := 3
    Else If S = 'left' Then St.Align := 1;
  End;
  S := GetAttr(N, 'bgcolor');
  If (S <> '') And (ParseColor(S) >= 0) Then St.Back := ParseColor(S);
  { feuilles de style }
  Cs := NodeStyle(N);
  If Cs <> Nil Then
  Begin
    If Cs^.Display = 1 Then
    Begin
      ApplyStyle := 0;
      Exit;
    End;
    If (Cs^.Display = 2) And (N^.Tag <> TAG_TD) And (N^.Tag <> TAG_TH) Then D := 1;
    If (Cs^.Display = 3) And (N^.Tag <> TAG_TABLE) And (N^.Tag <> TAG_TR) And (N^.Tag <> TAG_LI) Then D := 2;
    If Cs^.Color >= 0 Then St.Color := Cs^.Color;
    If Cs^.Back >= 0 Then St.Back := Cs^.Back;
    If Cs^.Align <> 0 Then St.Align := Cs^.Align;
    If Cs^.Bold = 1 Then St.Flags := St.Flags Or ST_BOLD Else If Cs^.Bold = 2 Then St.Flags := St.Flags And Not ST_BOLD;
    If Cs^.Italic = 1 Then St.Flags := St.Flags Or ST_ITALIC
    Else If Cs^.Italic = 2 Then St.Flags := St.Flags And Not ST_ITALIC;
    If Cs^.Under = 1 Then St.Flags := St.Flags Or ST_UNDER
    Else If Cs^.Under = 2 Then St.Flags := St.Flags And Not ST_UNDER;
    If Cs^.Size <> 0 Then St.Scale := FontScale(Cs^.Size);
  End;
  ApplyStyle := D;
End;

{ ==================================================================== }
{ Mesure des largeurs minimale et maximale (cellules de tableaux)       }
{ ==================================================================== }

{ marges et retraits CSS d'un element (0 si absents) }
Procedure CssEdges(C : PNode; Var T, R, B, L : LongInt; Var HasT, HasB : Boolean);
Var Cs : PStyle;
Begin
  T := 0; R := 0; B := 0; L := 0; HasT := False; HasB := False;
  Cs := NodeStyle(C);
  If Cs = Nil Then Exit;
  HasT := Cs^.MarT >= 0; HasB := Cs^.MarB >= 0;
  T := MaxI(0, Cs^.MarT) + MaxI(0, Cs^.PadT);
  B := MaxI(0, Cs^.MarB) + MaxI(0, Cs^.PadB);
  L := MaxI(0, Cs^.MarL) + MaxI(0, Cs^.PadL);
  R := MaxI(0, Cs^.MarR) + MaxI(0, Cs^.PadR);
End;

Procedure MeasureTable(T : PNode; Var St : TSt; Var Mn, Mx : LongInt); Forward;

Procedure MeasureFlow(N : PNode; Var St : TSt);
Var C : PNode; S2 : TSt; D, W, H, I, J, Cw, Len, SMin, SMax, SLine, Ind, K, ET, ER, EB, EL : LongInt;
    HasT, HasB : Boolean;
Begin
  C := N^.First;
  While C <> Nil Do
  Begin
    If C^.Kind = NODE_TEXT Then
    Begin
      Cw := CharWs[St.Scale];
      I := 0;
      While I < C^.TLen Do
      Begin
        J := I;
        While (J < C^.TLen) And (RdB(C^.Txt + J) > 32) Do Inc(J);
        If J > I Then
        Begin
          Len := (J - I) * Cw;
          If Len > MMin Then MMin := Len;
          MLine := MLine + Len;
        End;
        If J < C^.TLen Then
        Begin
          If (St.Pre <> 0) And (RdB(C^.Txt + J) = 10) Then
          Begin
            If MLine > MMax Then MMax := MLine;
            MLine := 0;
          End
          Else MLine := MLine + Cw;
        End;
        I := J + 1;
      End;
    End
    Else If C^.Kind = NODE_ELEM Then
    Begin
      S2 := St;
      D := ApplyStyle(C, S2);
      If D <> 0 Then
      Begin
        If C^.Tag = TAG_BR Then
        Begin
          If MLine > MMax Then MMax := MLine;
          MLine := 0;
        End
        Else If C^.Tag = TAG_IMG Then
        Begin
          ImgSize(C, C^.Aux - 1, W, H);
          If W > MMin Then MMin := W;
          MLine := MLine + W;
        End
        Else If (C^.Aux > 0) And (C^.Tag <> TAG_IMG) Then
        Begin
          CtlSize(C^.Aux - 1, W, H);
          If W > MMin Then MMin := W;
          MLine := MLine + W + 4;
        End
        Else If C^.Tag = TAG_TABLE Then
        Begin
          MeasureTable(C, S2, W, H);
          If MLine > MMax Then MMax := MLine;
          MLine := 0;
          If W > MMin Then MMin := W;
          If H > MMax Then MMax := H;
        End
        Else If D = 1 Then
        Begin
          { bloc : mesure a part, retrait compris }
          If MLine > MMax Then MMax := MLine;
          SMin := MMin; SMax := MMax;
          MMin := 0; MMax := 0; MLine := 0;
          MeasureFlow(C, S2);
          If MLine > MMax Then MMax := MLine;
          Ind := 0;
          If (C^.Tag = TAG_UL) Or (C^.Tag = TAG_OL) Or (C^.Tag = TAG_DD) Then Ind := 32
          Else If C^.Tag = TAG_BLOCKQUOTE Then Ind := 64;
          CssEdges(C, ET, ER, EB, EL, HasT, HasB);
          Ind := Ind + EL + ER;
          K := MMin + Ind;
          MMin := MaxI(SMin, K);
          MMax := MaxI(SMax, MMax + Ind);
          MLine := 0;
        End
        Else
        Begin
          CssEdges(C, ET, ER, EB, EL, HasT, HasB);
          MLine := MLine + EL;
          MeasureFlow(C, S2);
          MLine := MLine + ER;
        End;
      End;
    End;
    C := C^.Next;
  End;
End;

{ largeurs d'une cellule }
Procedure MeasureCell(C : PNode; Var St : TSt; Var Mn, Mx : LongInt);
Var SL, SMn, SMx : LongInt;
Begin
  SL := MLine; SMn := MMin; SMx := MMax;
  MLine := 0; MMin := 0; MMax := 0;
  MeasureFlow(C, St);
  If MLine > MMax Then MMax := MLine;
  Mn := MMin; Mx := MMax;
  MLine := SL; MMin := SMn; MMax := SMx;
End;

{ ==================================================================== }
{ Tableaux                                                              }
{ ==================================================================== }

Type
  PCell = ^TCell;
  TCell = Record
    Node : PNode;
    Row, Col, Span, RSpan : LongInt;
    Mn, Mx : LongInt;
  End;
  PLongArr = ^TLongArr;
  TLongArr = Array[0..MAX_COLS] Of LongInt;

Var
  TabDepth : LongInt;

{ cellules d'un tableau (lignes de <table>, <thead>, <tbody>, <tfoot>) ;
  Cells : tableau de PCell dans l'arene de mise en page }
Function CollectCells(T : PNode; Var Cells : LongInt; Var NRow, NCol : LongInt) : LongInt;
Var Sec, R, C : PNode; N, Col, Sp, K, Rs, Cap : LongInt; P : PCell; Occ : Array[0..MAX_COLS] Of LongInt;
Begin
  Cap := 2000;
  Cells := LaAlloc(Cap * 4);
  N := 0; NRow := 0; NCol := 0;
  For K := 0 To MAX_COLS Do Occ[K] := 0;
  If Cells = 0 Then
  Begin
    CollectCells := 0;
    Exit;
  End;
  Sec := T^.First;
  While Sec <> Nil Do
  Begin
    If (Sec^.Kind = NODE_ELEM) And ((Sec^.Tag = TAG_TR) Or (Sec^.Tag = TAG_THEAD) Or (Sec^.Tag = TAG_TBODY) Or
                                    (Sec^.Tag = TAG_TFOOT)) Then
    Begin
      If Sec^.Tag = TAG_TR Then R := Sec Else R := Sec^.First;
      While R <> Nil Do
      Begin
        If (R^.Kind = NODE_ELEM) And (R^.Tag = TAG_TR) And (NRow < 1000) Then
        Begin
          Col := 0;
          C := R^.First;
          While C <> Nil Do
          Begin
            If (C^.Kind = NODE_ELEM) And ((C^.Tag = TAG_TD) Or (C^.Tag = TAG_TH)) And (N < Cap) Then
            Begin
              While (Col < MAX_COLS) And (Occ[Col] > 0) Do Inc(Col);
              If Col >= MAX_COLS Then Break;
              Sp := SVal(GetAttr(C, 'colspan'), 1);
              If Sp < 1 Then Sp := 1;
              If Col + Sp > MAX_COLS Then Sp := MAX_COLS - Col;
              Rs := SVal(GetAttr(C, 'rowspan'), 1);
              If (Rs < 1) Or (Rs > 100) Then Rs := 1;
              P := Pointer(LaAlloc(SizeOf(TCell)));
              If P = Nil Then Break;
              P^.Node := C; P^.Row := NRow; P^.Col := Col; P^.Span := Sp; P^.RSpan := Rs;
              WrL(Cells + N * 4, LongInt(P));
              Inc(N);
              For K := Col To Col + Sp - 1 Do
                If Rs > 1 Then Occ[K] := Rs;
              Col := Col + Sp;
              If Col > NCol Then NCol := Col;
            End;
            C := C^.Next;
          End;
          Inc(NRow);
          For K := 0 To MAX_COLS - 1 Do
            If Occ[K] > 0 Then Dec(Occ[K]);
        End;
        If Sec^.Tag = TAG_TR Then R := Nil Else R := R^.Next;
      End;
    End;
    Sec := Sec^.Next;
  End;
  CollectCells := N;
End;

Function CellAt(Cells, I : LongInt) : PCell;
Begin
  CellAt := Pointer(RdL(Cells + I * 4));
End;

{ largeurs des colonnes : minimum et maximum de chaque colonne }
Procedure ColWidths(Cells, N, NCol, Pad : LongInt; Var St : TSt; CMn, CMx, CFx : PLongArr);
Var I, K, Need, Have, Sp, W, Mn1, Mx1 : LongInt; P : PCell; S2 : TSt; S : String;
Begin
  For K := 0 To NCol Do
  Begin
    CMn^[K] := 0; CMx^[K] := 0; CFx^[K] := 0;
  End;
  { cellules d'une colonne d'abord, puis cellules a plusieurs colonnes }
  For Sp := 1 To 2 Do
    For I := 0 To N - 1 Do
    Begin
      P := CellAt(Cells, I);
      If ((Sp = 1) And (P^.Span = 1)) Or ((Sp = 2) And (P^.Span > 1)) Then
      Begin
        If Sp = 1 Then
        Begin
          S2 := St;
          Mn1 := 0; Mx1 := 0;
          If ApplyStyle(P^.Node, S2) <> 0 Then MeasureCell(P^.Node, S2, Mn1, Mx1);
          P^.Mn := Mn1; P^.Mx := Mx1;
          P^.Mn := P^.Mn + 2 * Pad; P^.Mx := P^.Mx + 2 * Pad;
          S := GetAttr(P^.Node, 'width');
          If (S <> '') And (Pos('%', S) = 0) Then
          Begin
            W := SVal(S, 0);
            If (W > 0) And (W < 2000) Then
            Begin
              If W > CFx^[P^.Col] Then CFx^[P^.Col] := W;
              If W > P^.Mx Then P^.Mx := W;
            End;
          End;
          If P^.Mn > CMn^[P^.Col] Then CMn^[P^.Col] := P^.Mn;
          If P^.Mx > CMx^[P^.Col] Then CMx^[P^.Col] := P^.Mx;
        End
        Else
        Begin
          S2 := St;
          Mn1 := 0; Mx1 := 0;
          If ApplyStyle(P^.Node, S2) <> 0 Then MeasureCell(P^.Node, S2, Mn1, Mx1);
          P^.Mn := Mn1; P^.Mx := Mx1;
          P^.Mn := P^.Mn + 2 * Pad; P^.Mx := P^.Mx + 2 * Pad;
          Have := 0;
          For K := P^.Col To P^.Col + P^.Span - 1 Do Have := Have + CMn^[K];
          If P^.Mn > Have Then
          Begin
            Need := (P^.Mn - Have + P^.Span - 1) Div P^.Span;
            For K := P^.Col To P^.Col + P^.Span - 1 Do CMn^[K] := CMn^[K] + Need;
          End;
          Have := 0;
          For K := P^.Col To P^.Col + P^.Span - 1 Do Have := Have + CMx^[K];
          If P^.Mx > Have Then
          Begin
            Need := (P^.Mx - Have + P^.Span - 1) Div P^.Span;
            For K := P^.Col To P^.Col + P^.Span - 1 Do CMx^[K] := CMx^[K] + Need;
          End;
        End;
      End;
    End;
  For K := 0 To NCol - 1 Do
    If CMx^[K] < CMn^[K] Then CMx^[K] := CMn^[K];
End;

Procedure TableAttrs(T : PNode; Var Border, Pad, Spc : LongInt);
Var S : String;
Begin
  Border := 0;
  If HasAttr(T, 'border') Then
  Begin
    S := GetAttr(T, 'border');
    If S = '' Then Border := 1 Else Border := MinI(8, MaxI(0, SVal(S, 1)));
  End;
  Pad := MinI(30, MaxI(0, SVal(GetAttr(T, 'cellpadding'), 1)));
  Spc := MinI(30, MaxI(0, SVal(GetAttr(T, 'cellspacing'), 2)));
End;

Procedure MeasureTable(T : PNode; Var St : TSt; Var Mn, Mx : LongInt);
Var Cells, N, NRow, NCol, K, Border, Pad, Spc, Save : LongInt; CMn, CMx, CFx : PLongArr; S : String;
Begin
  If T^.MGen = LayGen Then
  Begin
    Mn := T^.MinW; Mx := T^.MaxW;
    Exit;
  End;
  Mn := 0; Mx := 0;
  If TabDepth > 12 Then
  Begin
    { trop profond : DoTable rendra le contenu en flot, on le mesure ainsi }
    MeasureCell(T, St, Mn, Mx);
    Exit;
  End;
  Inc(TabDepth);
  Save := LaUsed;
  TableAttrs(T, Border, Pad, Spc);
  N := CollectCells(T, Cells, NRow, NCol);
  CMn := Pointer(LaAlloc(SizeOf(TLongArr)));
  CMx := Pointer(LaAlloc(SizeOf(TLongArr)));
  CFx := Pointer(LaAlloc(SizeOf(TLongArr)));
  If (N > 0) And (CFx <> Nil) Then
  Begin
    ColWidths(Cells, N, NCol, Pad, St, CMn, CMx, CFx);
    For K := 0 To NCol - 1 Do
    Begin
      Mn := Mn + CMn^[K] + Spc;
      Mx := Mx + MaxI(CMx^[K], CFx^[K]) + Spc;
    End;
  End;
  Mn := Mn + Spc + 2 * Border; Mx := Mx + Spc + 2 * Border;
  S := GetAttr(T, 'width');
  If (S <> '') And (Pos('%', S) = 0) And (SVal(S, 0) > Mn) And (SVal(S, 0) < 3000) Then
  Begin
    Mn := SVal(S, 0); Mx := MaxI(Mx, Mn);
  End;
  { l'arene de mise en page est rendue (mesure seulement) }
  LaUsed := Save;
  T^.MinW := Mn; T^.MaxW := Mx; T^.MGen := LayGen;
  Dec(TabDepth);
End;

Procedure FlowChildren(N : PNode; Var St : TSt); Forward;

Procedure DoTable(T : PNode; Var St : TSt);
Var Cells, N, NRow, NCol, K, I, R, Border, Pad, Spc, Avail, TW, SumMn, Extra, Room, Give, X, Y0, RowY, RowH,
    CellH, Cx, Cw, TX, SaveX0, SaveX1, SaveAlign, Dy, VAl, Wt, TotW : LongInt;
    CMn, CMx, CFx, CW_, CX_ : PLongArr; P : PCell; S2, SR : TSt; S : String;
    TblBg, CellBg, RowOp : POp; Mark, Last : POp; RowN : PNode;
    CHt : Array[0..MAX_COLS] Of LongInt; CMark, CLast, CBg : Array[0..MAX_COLS] Of POp;
    CNode : Array[0..MAX_COLS] Of PCell;
Begin
  FlushLine;
  If TabDepth > 12 Then
  Begin
    FlowChildren(T, St);
    Exit;
  End;
  Inc(TabDepth);
  TableAttrs(T, Border, Pad, Spc);
  N := CollectCells(T, Cells, NRow, NCol);
  CMn := Pointer(LaAlloc(SizeOf(TLongArr)));
  CMx := Pointer(LaAlloc(SizeOf(TLongArr)));
  CFx := Pointer(LaAlloc(SizeOf(TLongArr)));
  CW_ := Pointer(LaAlloc(SizeOf(TLongArr)));
  CX_ := Pointer(LaAlloc(SizeOf(TLongArr)));
  If (N = 0) Or (CX_ = Nil) Or (NCol = 0) Then
  Begin
    Dec(TabDepth);
    FlowChildren(T, St);
    Exit;
  End;
  ColWidths(Cells, N, NCol, Pad, St, CMn, CMx, CFx);
  { largeur du tableau }
  Avail := MaxI(40, LX1 - LX0);
  SumMn := Spc * (NCol + 1) + 2 * Border;
  TotW := SumMn;
  For K := 0 To NCol - 1 Do
  Begin
    SumMn := SumMn + CMn^[K];
    TotW := TotW + MaxI(CMx^[K], CFx^[K]);
  End;
  S := GetAttr(T, 'width');
  If S = '' Then
  Begin
    If NodeStyle(T) <> Nil Then
      If NodeStyle(T)^.Width > 0 Then S := IStr(NodeStyle(T)^.Width);
  End;
  If (S <> '') And (Pos('%', S) > 0) Then TW := (Avail * MinI(100, MaxI(1, SVal(S, 100)))) Div 100
  Else If (S <> '') And (SVal(S, 0) > 0) Then TW := MinI(SVal(S, 0), MaxI(Avail, SumMn))
  Else TW := MinI(Avail, TotW);
  If TW < SumMn Then TW := SumMn;
  { colonnes : minimum, puis largeurs fixes, puis vers le maximum, puis
    le reste au prorata }
  For K := 0 To NCol - 1 Do CW_^[K] := CMn^[K];
  Extra := TW - SumMn;
  For K := 0 To NCol - 1 Do
    If (Extra > 0) And (CFx^[K] > CW_^[K]) Then
    Begin
      Give := MinI(Extra, CFx^[K] - CW_^[K]);
      CW_^[K] := CW_^[K] + Give;
      Extra := Extra - Give;
    End;
  If Extra > 0 Then
  Begin
    Room := 0;
    For K := 0 To NCol - 1 Do
      If CMx^[K] > CW_^[K] Then Room := Room + CMx^[K] - CW_^[K];
    If Room > 0 Then
    Begin
      Give := MinI(Extra, Room);
      Wt := 0;
      For K := 0 To NCol - 1 Do
        If CMx^[K] > CW_^[K] Then
        Begin
          I := (Give * (CMx^[K] - CW_^[K])) Div Room;
          CW_^[K] := CW_^[K] + I;
          Wt := Wt + I;
        End;
      Extra := Extra - Wt;
    End;
  End;
  If Extra > 0 Then
  Begin
    Wt := 0;
    For K := 0 To NCol - 1 Do
      If CFx^[K] = 0 Then Wt := Wt + MaxI(1, CW_^[K]);
    If Wt = 0 Then
      For K := 0 To NCol - 1 Do Wt := Wt + MaxI(1, CW_^[K]);
    Give := Extra;
    For K := 0 To NCol - 1 Do
      If (CFx^[K] = 0) Or (Wt = 0) Then
      Begin
        I := (Give * MaxI(1, CW_^[K])) Div MaxI(1, Wt);
        CW_^[K] := CW_^[K] + I;
        Extra := Extra - I;
      End;
    If Extra > 0 Then CW_^[NCol - 1] := CW_^[NCol - 1] + Extra;
  End;
  { position }
  S := LowStr(GetAttr(T, 'align'));
  TX := LX0;
  If (S = 'center') Or ((S = '') And (St.Align = 2)) Then TX := LX0 + MaxI(0, (Avail - TW) Div 2)
  Else If S = 'right' Then TX := LX0 + MaxI(0, Avail - TW);
  X := TX + Border + Spc;
  For K := 0 To NCol - 1 Do
  Begin
    CX_^[K] := X;
    X := X + CW_^[K] + Spc;
  End;
  SaveX0 := LX0; SaveX1 := LX1; SaveAlign := CurAlign;
  VSpace(2);
  Y0 := CurY;
  { fond du tableau }
  S2 := St;
  TblBg := Nil;
  S := GetAttr(T, 'bgcolor');
  If ParseColor(S) >= 0 Then TblBg := RectOp(TX, Y0, TW, 0, ParseColor(S))
  Else If NodeStyle(T) <> Nil Then
    If NodeStyle(T)^.Back >= 0 Then TblBg := RectOp(TX, Y0, TW, 0, NodeStyle(T)^.Back);
  { titre <caption> }
  RowN := T^.First;
  While RowN <> Nil Do
  Begin
    If (RowN^.Kind = NODE_ELEM) And (RowN^.Tag = TAG_CAPTION) Then
    Begin
      LX0 := TX; LX1 := TX + TW; CurAlign := 2;
      SR := St;
      If ApplyStyle(RowN, SR) <> 0 Then
      Begin
        FlowChildren(RowN, SR);
        FlushLine;
      End;
    End;
    RowN := RowN^.Next;
  End;
  CurY := CurY + Border + Spc;
  { lignes }
  I := 0;
  For R := 0 To NRow - 1 Do
  Begin
    RowY := CurY; RowH := 0;
    { attributs de la ligne }
    SR := St;
    RowOp := Nil;
    If (I < N) And (CellAt(Cells, I)^.Row = R) Then
    Begin
      RowN := CellAt(Cells, I)^.Node^.Parent;
      If ApplyStyle(RowN, SR) = 0 Then
      Begin
        { ligne cachee : sauter ses cellules }
        While (I < N) And (CellAt(Cells, I)^.Row = R) Do Inc(I);
        Continue;
      End;
      If SR.Back >= 0 Then RowOp := RectOp(TX + Border, RowY, TW - 2 * Border, 0, SR.Back);
    End;
    K := 0;
    While (I < N) And (CellAt(Cells, I)^.Row = R) Do
    Begin
      P := CellAt(Cells, I);
      Inc(I);
      If K > MAX_COLS Then Continue;
      S2 := SR;
      If P^.Node^.Tag = TAG_TH Then S2.Align := 2;
      If ApplyStyle(P^.Node, S2) = 0 Then Continue;
      Cx := CX_^[P^.Col];
      Cw := CX_^[P^.Col + P^.Span - 1] + CW_^[P^.Col + P^.Span - 1] - Cx;
      CellBg := Nil;
      If S2.Back >= 0 Then CellBg := RectOp(Cx, RowY, Cw, 0, S2.Back);
      Mark := OpLast;
      LX0 := Cx + Pad; LX1 := MaxI(LX0 + 8, Cx + Cw - Pad);
      CurAlign := S2.Align;
      CurY := RowY + Pad; VGap := Pad;
      PendSpace := False;
      FlowChildren(P^.Node, S2);
      FlushLine;
      CellH := CurY - RowY + Pad;
      If (P^.RSpan = 1) And (CellH > RowH) Then RowH := CellH;
      If P^.RSpan > 1 Then
        If CellH Div P^.RSpan > RowH Then RowH := CellH Div P^.RSpan;
      CHt[K] := CellH; CMark[K] := Mark; CLast[K] := OpLast; CBg[K] := CellBg; CNode[K] := P;
      Inc(K);
    End;
    If RowH < 2 * Pad + 4 Then RowH := MinI(2 * Pad + 4, 8);
    { alignement vertical, fonds et bordures des cellules }
    For Wt := 0 To K - 1 Do
    Begin
      P := CNode[Wt];
      S := LowStr(GetAttr(P^.Node, 'valign'));
      If S = '' Then S := LowStr(GetAttr(P^.Node^.Parent, 'valign'));
      Dy := 0;
      If (S = '') Or (S = 'middle') Or (S = 'center') Then Dy := (RowH - CHt[Wt]) Div 2
      Else If S = 'bottom' Then Dy := RowH - CHt[Wt];
      If (Dy > 0) And (CLast[Wt] <> CMark[Wt]) Then ShiftOps(CMark[Wt], CLast[Wt], Dy);
      If CBg[Wt] <> Nil Then CBg[Wt]^.H := RowH;
      If Border > 0 Then
      Begin
        Cx := CX_^[P^.Col];
        Cw := CX_^[P^.Col + P^.Span - 1] + CW_^[P^.Col + P^.Span - 1] - Cx;
        Dummy := LongInt(FrameOp(Cx, RowY, Cw, RowH, $808080));
      End;
    End;
    If RowOp <> Nil Then RowOp^.H := RowH;
    CurY := RowY + RowH + Spc;
  End;
  CurY := CurY + Border;
  If TblBg <> Nil Then TblBg^.H := CurY - Y0;
  If Border > 0 Then
  Begin
    Dummy := LongInt(FrameOp(TX, Y0, TW, CurY - Y0, $404040));
    If Border > 1 Then Dummy := LongInt(FrameOp(TX + 1, Y0 + 1, TW - 2, CurY - Y0 - 2, $C0C0C0));
  End;
  LX0 := SaveX0; LX1 := SaveX1; CurAlign := SaveAlign;
  VGap := 0;
  VSpace(2);
  PendSpace := False;
  If TX + TW > PageW Then PageW := TX + TW;
  Dec(TabDepth);
End;

{ ==================================================================== }
{ Elements                                                              }
{ ==================================================================== }

Var
  ListNum : Array[0..MAX_DEPTH] Of LongInt;
  ListKind : Array[0..MAX_DEPTH] Of LongInt;
  ListLvl : LongInt;

Procedure AddAnchor(N : PNode);
Var S : String;
Begin
  S := GetAttr(N, 'id');
  If (S = '') And (N^.Tag = TAG_A) Then S := GetAttr(N, 'name');
  If (S = '') Or (NAnch >= 200) Then Exit;
  AnchName[NAnch] := Copy(S, 1, 31);
  AnchY[NAnch] := CurY;
  Inc(NAnch);
End;

Procedure DoImage(N : PNode; Var St : TSt);
Var W, H, X, I : LongInt; O : POp; S : String;
Begin
  I := N^.Aux - 1;
  ImgSize(N, I, W, H);
  If W > LX1 - LX0 Then
  Begin
    H := (H * (LX1 - LX0)) Div W;
    W := LX1 - LX0;
    If H < 1 Then H := 1;
  End;
  X := PlaceItem(W, St);
  O := NewOp(OP_IMAGE);
  If O = Nil Then Exit;
  O^.X := X; O^.W := W; O^.H := H; O^.Data := I; O^.Link := St.Link;
  { texte de remplacement (image absente) }
  S := GetAttr(N, 'alt');
  If S <> '' Then
  Begin
    O^.Len := Length(S);
    O^.Back := LaStr(S);
  End;
  O^.Color := St.Color;
  PushLine(O);
  If (LowStr(GetAttr(N, 'align')) = 'right') Or (LowStr(GetAttr(N, 'align')) = 'left') Then PendSpace := True;
End;

Procedure DoControl(N : PNode; Var St : TSt);
Var K, W, H, X : LongInt; O : POp;
Begin
  K := N^.Aux - 1;
  If (K < 0) Or (K >= NCtls) Then Exit;
  If CtType[K] = CT_HIDDEN Then Exit;
  CtlSize(K, W, H);
  If W > LX1 - LX0 Then W := MaxI(16, LX1 - LX0);
  X := PlaceItem(W + 4, St);
  O := NewOp(OP_CTRL);
  If O = Nil Then Exit;
  O^.X := X + 2; O^.W := W; O^.H := H + 2; O^.Data := K;
  PushLine(O);
  PendSpace := True;
End;

Procedure DoHr(N : PNode; Var St : TSt);
Var O : POp; W, X : LongInt; S : String;
Begin
  FlushLine;
  VSpace(8);
  W := LX1 - LX0;
  S := GetAttr(N, 'width');
  If (S <> '') And (Pos('%', S) > 0) Then W := (W * MinI(100, SVal(S, 100))) Div 100
  Else If SVal(S, 0) > 0 Then W := MinI(W, SVal(S, 0));
  X := LX0;
  If LowStr(GetAttr(N, 'align')) <> 'left' Then X := LX0 + (LX1 - LX0 - W) Div 2;
  O := NewOp(OP_LINE);
  If O <> Nil Then
  Begin
    O^.X := X; O^.Y := CurY; O^.W := W; O^.H := 2; O^.Color := $808080; O^.Back := $FFFFFF;
  End;
  CurY := CurY + 2;
  VGap := 0;
  VSpace(8);
End;

{ puce ou numero d'un element de liste }
Procedure DoBullet(Var St : TSt);
Var O : POp; S : String; K, N : LongInt;
Begin
  K := 0; N := 0;
  If ListLvl > 0 Then
  Begin
    K := ListKind[ListLvl]; N := ListNum[ListLvl];
    Inc(ListNum[ListLvl]);
  End;
  If K >= 1 Then
  Begin
    { liste numerotee : 1. a. A. }
    If K = 2 Then S := Chr(97 + (N - 1) Mod 26) + '.'
    Else If K = 3 Then S := Chr(65 + (N - 1) Mod 26) + '.'
    Else S := IStr(N) + '.';
    O := NewOp(OP_TEXT);
    If O = Nil Then Exit;
    O^.X := LX0 - Length(S) * 8 - 6; O^.Y := CurY; O^.W := Length(S) * 8; O^.H := 16;
    O^.Data := LaStr(S); O^.Len := Length(S); O^.Color := St.Color; O^.Size := 1;
  End
  Else
  Begin
    O := NewOp(OP_BULLET);
    If O = Nil Then Exit;
    O^.X := LX0 - 14; O^.Y := CurY + (CharHs[St.Scale] - 6) Div 2; O^.W := 6; O^.H := 6;
    O^.Color := St.Color; O^.Style := ((ListLvl - 1) Mod 3);
  End;
End;

Procedure DoElem2(C : PNode; Var St : TSt); Forward;

{ element : les operations qu'il produit lui sont rattachees }
Procedure DoElem(C : PNode; Var St : TSt);
Var Save : PNode;
Begin
  Save := CurElem;
  CurElem := C;
  DoElem2(C, St);
  CurElem := Save;
End;

Procedure DoElem2(C : PNode; Var St : TSt);
Var S2 : TSt; D, SX0, SX1, SAl, Top, Bot, Ind, K, ET, ER, EB, EL : LongInt; Bg, Mark : POp; S : String;
    HasT, HasB : Boolean;
Begin
  S2 := St;
  D := ApplyStyle(C, S2);
  If D = 0 Then Exit;
  If HasAttr(C, 'id') Or ((C^.Tag = TAG_A) And HasAttr(C, 'name')) Then AddAnchor(C);
  Case C^.Tag Of
    TAG_BR :
      Begin
        LineBreak(S2);
        Exit;
      End;
    TAG_WBR : Exit;
    TAG_IMG :
      Begin
        DoImage(C, S2);
        Exit;
      End;
    TAG_INPUT, TAG_SELECT, TAG_TEXTAREA :
      Begin
        DoControl(C, S2);
        Exit;
      End;
    TAG_BUTTON :
      Begin
        If C^.Aux > 0 Then DoControl(C, S2);
        Exit;
      End;
    TAG_HR :
      Begin
        DoHr(C, S2);
        Exit;
      End;
    TAG_TABLE :
      Begin
        DoTable(C, S2);
        Exit;
      End;
    TAG_IFRAME :
      Begin
        { cadre : lien vers sa page }
        S := GetAttr(C, 'src');
        If (S <> '') And Not StartsWith(S, 'javascript:') And Not StartsWith(S, 'about:') Then
        Begin
          S2.Link := LongInt(C); S2.Color := LinkFg; S2.Flags := S2.Flags Or ST_UNDER;
          AddStr('[Cadre : ' + Copy(ResolveUrl(BaseUrl, S), 1, 60) + ']', S2);
        End;
        Exit;
      End;
  End;
  CssEdges(C, ET, ER, EB, EL, HasT, HasB);
  If D = 2 Then
  Begin
    { element en ligne : marges horizontales CSS de part et d'autre }
    If EL > 0 Then
    Begin
      If PendSpace And (LnN > 0) Then LnW := LnW + CharWs[S2.Scale];
      PendSpace := False;
      LnW := MinI(LnW + EL, MaxI(0, LX1 - LX0 - 8));
    End;
    FlowChildren(C, S2);
    If (ER > 0) And (LnN > 0) Then LnW := MinI(LnW + ER, LX1 - LX0);
    Exit;
  End;
  { element de bloc }
  FlushLine;
  SX0 := LX0; SX1 := LX1; SAl := CurAlign;
  Top := 0; Bot := 0; Ind := 0;
  Case C^.Tag Of
    TAG_P : Top := 12;
    TAG_H1 : Top := 16;
    TAG_H2 : Top := 14;
    TAG_H3, TAG_H4, TAG_H5, TAG_H6 : Top := 12;
    TAG_UL, TAG_OL, TAG_MENU :
      Begin
        If ListLvl = 0 Then Top := 10;
        Ind := 32;
      End;
    TAG_DL : Top := 8;
    TAG_DD : Ind := 40;
    TAG_BLOCKQUOTE :
      Begin
        Top := 12; Ind := 40;
        LX1 := LX1 - 40;
      End;
    TAG_PRE : Top := 12;
    TAG_FORM : Top := 0;
    TAG_FIELDSET :
      Begin
        Top := 8; Ind := 8;
        LX1 := LX1 - 8;
      End;
    TAG_FIGURE :
      Begin
        Top := 12; Ind := 40;
        LX1 := LX1 - 40;
      End;
  End;
  Bot := Top;
  If C^.Tag = TAG_FORM Then Bot := 12;
  If (C^.Tag <> TAG_BODY) And (C^.Tag <> TAG_HTML) Then
  Begin
    { marges CSS : remplacent celles par defaut ; retraits ajoutes }
    If HasT Then Top := ET Else Top := Top + ET;
    If HasB Then Bot := EB Else Bot := Bot + EB;
    Ind := Ind + EL;
    LX1 := MaxI(LX0 + 32, LX1 - ER);
  End;
  VSpace(Top);
  LX0 := MinI(LX1 - 16, LX0 + Ind);
  CurAlign := S2.Align;
  Bg := Nil;
  If (S2.Back >= 0) And (C^.Tag <> TAG_BODY) And (C^.Tag <> TAG_HTML) Then
    Bg := RectOp(SX0, CurY, SX1 - SX0, 0, S2.Back);
  K := CurY;
  If (C^.Tag = TAG_UL) Or (C^.Tag = TAG_OL) Or (C^.Tag = TAG_MENU) Then
  Begin
    If ListLvl < MAX_DEPTH Then
    Begin
      Inc(ListLvl);
      ListNum[ListLvl] := SVal(GetAttr(C, 'start'), 1);
      ListKind[ListLvl] := 0;
      If C^.Tag = TAG_OL Then
      Begin
        S := GetAttr(C, 'type');
        If S = 'a' Then ListKind[ListLvl] := 2
        Else If S = 'A' Then ListKind[ListLvl] := 3
        Else ListKind[ListLvl] := 1;
      End;
      FlowChildren(C, S2);
      Dec(ListLvl);
    End
    Else FlowChildren(C, S2);
  End
  Else If C^.Tag = TAG_LI Then
  Begin
    If ListLvl = 0 Then
    Begin
      LX0 := MinI(LX1 - 16, LX0 + 24);
      Inc(ListLvl); ListKind[ListLvl] := 0; ListNum[ListLvl] := 1;
      DoBullet(S2);
      FlowChildren(C, S2);
      Dec(ListLvl);
    End
    Else
    Begin
      DoBullet(S2);
      FlowChildren(C, S2);
    End;
  End
  Else FlowChildren(C, S2);
  FlushLine;
  If (C^.Tag = TAG_LI) And (CurY = K) Then CurY := CurY + CharHs[S2.Scale] + 2;
  If Bg <> Nil Then Bg^.H := CurY - Bg^.Y;
  VSpace(Bot);
  LX0 := SX0; LX1 := SX1; CurAlign := SAl;
End;

Procedure FlowChildren(N : PNode; Var St : TSt);
Var C : PNode;
Begin
  If N = Nil Then Exit;
  C := N^.First;
  While C <> Nil Do
  Begin
    If C^.Kind = NODE_TEXT Then AddText(C, St)
    Else If C^.Kind = NODE_ELEM Then DoElem(C, St);
    C := C^.Next;
  End;
End;

{ texte source de la page (Affichage - Source de la page) }
{ code source : numeros de ligne et coloration (balises, attributs,
  valeurs, commentaires, entites ; script et style restent du texte) }
Const
  SRC_TEXT = $000000; SRC_TAG = $800080; SRC_ATTR = $A04000; SRC_VAL = $0000C0;
  SRC_COMM = $008000; SRC_ENT = $008080; SRC_NUM = $909090;

Var SrcIndent : LongInt;   { retrait des suites de lignes coupees (pels) }

{ segment de couleur C : remplit la ligne, puis continue sur la suivante,
  alignee sur la colonne du code (apres le numero de ligne) }
Procedure SrcSeg(A, N, C : LongInt; Var St : TSt);
Var Cw, Room, Fit : LongInt;
Begin
  If N <= 0 Then Exit;
  St.Color := C;
  Cw := CharWs[St.Scale];
  While N > 0 Do
  Begin
    Room := (LX1 - LX0 - LnW) Div Cw;
    If Room < 1 Then
    Begin
      FlushLine;
      LnW := MinI(SrcIndent, MaxI(0, LX1 - LX0 - 8 * Cw));
      Room := MaxI(1, (LX1 - LX0 - LnW) Div Cw);
    End;
    Fit := MinI(N, Room);
    AddWord(A, Fit, St);
    A := A + Fit; N := N - Fit;
  End;
End;

Function SrcIs(P : LongInt; W : String) : Boolean;
Var K : LongInt;
Begin
  SrcIs := False;
  If P + Length(W) > SrcLen Then Exit;
  For K := 1 To Length(W) Do
    If (RdB(SrcBuf + P + K - 1) Or $20) <> (Ord(W[K]) Or $20) Then Exit;
  SrcIs := True;
End;

Procedure LayoutSource(Width : LongInt);
Var St : TSt; I, J, L, E, P, C, Ch, Run, RunC, State, Nx : LongInt; Tn, Raw : String; Num : String;
    QOpen, Closing : Boolean;
Begin
  St.Back := -1; St.Link := 0; St.Scale := 1; St.Flags := ST_MONO; St.Align := 1;
  St.Pre := 1; St.NoWrap := 0;
  State := 0; Tn := ''; Closing := False; Raw := ''; QOpen := False;
  If PlainText Then SrcIndent := 0 Else SrcIndent := 6 * CharWs[1];
  I := 0; L := 0;
  While (I < SrcLen) And (L < 20000) Do
  Begin
    E := I;
    While (E < SrcLen) And (RdB(SrcBuf + E) <> 10) Do Inc(E);
    J := E;
    If (J > I) And (RdB(SrcBuf + J - 1) = 13) Then Dec(J);
    { numero de ligne }
    If Not PlainText Then
    Begin
      Num := IStr(L + 1);
      While Length(Num) < 5 Do Num := ' ' + Num;
      Num := Num + ' ';
      P := LaStr(Num);
      If P <> 0 Then SrcSeg(P, Length(Num), SRC_NUM, St);
    End;
    Run := I; RunC := SRC_TEXT;
    P := I;
    While P < J Do
    Begin
      Ch := RdB(SrcBuf + P);
      Nx := 1;
      If PlainText Then C := SRC_TEXT
      Else
        Case State Of
          0 :
            If Raw <> '' Then
            Begin
              { contenu de script/style : jusqu'a la balise fermante }
              If (Ch = 60) And SrcIs(P, '</' + Raw) Then
              Begin
                Raw := ''; State := 1; Tn := ''; Closing := False; C := SRC_TAG;
              End
              Else C := SRC_TEXT;
            End
            Else If (Ch = 60) And SrcIs(P, '<!--') Then
            Begin
              State := 5; C := SRC_COMM; Nx := 4;
            End
            Else If Ch = 60 Then
            Begin
              State := 1; Tn := ''; Closing := False; C := SRC_TAG;
            End
            Else If Ch = 38 Then
            Begin
              State := 7; C := SRC_ENT;
            End
            Else C := SRC_TEXT;
          1 :
            Begin
              C := SRC_TAG;
              If (Ch = 32) Or (Ch = 9) Or (Ch = 13) Then
              Begin
                State := 2; C := SRC_TEXT;
              End
              Else If Ch = 62 Then
              Begin
                State := 0;
                If ((Tn = 'script') Or (Tn = 'style')) And Not Closing Then Raw := Tn;
              End
              Else If (Ch = 47) And (Tn = '') Then Closing := True
              Else If (Ch <> 47) And (Length(Tn) < 20) Then Tn := Tn + Chr(Ch Or $20);
            End;
          2 :
            If Ch = 62 Then
            Begin
              C := SRC_TAG; State := 0;
              If ((Tn = 'script') Or (Tn = 'style')) And Not Closing Then Raw := Tn;
            End
            Else If Ch = 47 Then C := SRC_TAG
            Else If Ch = 61 Then
            Begin
              C := SRC_TEXT;
              Nx := 1;
              { valeur : guillemets, apostrophes ou mot }
              QOpen := False;
              If (P + 1 < J) And (RdB(SrcBuf + P + 1) = 34) Then State := 3
              Else If (P + 1 < J) And (RdB(SrcBuf + P + 1) = 39) Then State := 4
              Else State := 6;
            End
            Else If (Ch = 32) Or (Ch = 9) Then C := SRC_TEXT
            Else C := SRC_ATTR;
          3, 4 :
            Begin
              C := SRC_VAL;
              If ((State = 3) And (Ch = 34)) Or ((State = 4) And (Ch = 39)) Then
              Begin
                If QOpen Then State := 2 Else QOpen := True;
              End;
            End;
          5 :
            Begin
              C := SRC_COMM;
              If (Ch = 45) And SrcIs(P, '-->') Then
              Begin
                Nx := 3; State := 0;
              End;
            End;
          6 :
            If (Ch = 32) Or (Ch = 9) Then
            Begin
              C := SRC_TEXT; State := 2;
            End
            Else If Ch = 62 Then
            Begin
              C := SRC_TAG; State := 0;
              If ((Tn = 'script') Or (Tn = 'style')) And Not Closing Then Raw := Tn;
            End
            Else C := SRC_VAL;
          7 :
            Begin
              C := SRC_ENT;
              If Ch = 59 Then State := 0
              Else If Not (Chr(Ch) In ['a'..'z', 'A'..'Z', '0'..'9', '#']) Then
              Begin
                State := 0; C := SRC_TEXT;
                If Ch = 60 Then
                Begin
                  State := 1; Tn := ''; Closing := False; C := SRC_TAG;
                End;
              End;
            End;
        Else
          C := SRC_TEXT;
        End;
      If C <> RunC Then
      Begin
        SrcSeg(SrcBuf + Run, P - Run, RunC, St);
        Run := P; RunC := C;
      End;
      If P + Nx > J Then Nx := J - P;
      If Nx < 1 Then Nx := 1;
      P := P + Nx;
    End;
    SrcSeg(SrcBuf + Run, J - Run, RunC, St);
    LineBreak(St);
    I := E + 1;
    Inc(L);
  End;
  FlushLine;
End;

{ mise en page complete pour une largeur de Width pels }
Procedure Layout(Width : LongInt);
Var St : TSt; B : PNode;
Begin
  LaUsed := 0;
  OpFirst := Nil; OpLast := Nil;
  Inc(LayGen);
  TabDepth := 0; ListLvl := 0; NAnch := 0;
  LX0 := 8; LX1 := MaxI(LX0 + 64, Width - 8);
  CurY := 8; CurAlign := 1; VGap := 8;
  LnN := 0; LnW := 0; PendSpace := False;
  CurElem := Nil;
  PageW := Width;
  If ViewSource Then LayoutSource(Width)
  Else If Root <> Nil Then
  Begin
    St.Color := PageFg; St.Back := -1; St.Link := 0; St.Scale := 1; St.Flags := 0; St.Align := 1;
    St.Pre := 0; St.NoWrap := 0;
    FlowChildren(Root, St);
    FlushLine;
  End;
  PageH := CurY + 16;
End;

{ remonte a l'element <a> ou <iframe> d'un lien : adresse cible }
Function LinkUrl(L : LongInt) : String;
Var N : PNode; S : String;
Begin
  LinkUrl := '';
  If L = 0 Then Exit;
  N := Pointer(L);
  If N^.Tag = TAG_IFRAME Then S := GetAttr(N, 'src') Else S := GetAttr(N, 'href');
  LinkUrl := ResolveUrl(BaseUrl, S);
End;

{ ==================================================================== }
{ Images : GIF, PNG, JPEG (de base) et BMP (d'apres les decodeurs du    }
{ navigateur d'origine) ; resultat : pels 24 bits (B, V, R) de bas   }
{ en haut, dessines par GpiDrawBits. Chaque lecture est bornee : un     }
{ fichier tronque ou corrompu donne une image ignoree, sans plantage.   }
{ ==================================================================== }

Const
  IMG_MAXPIX = 1500000;          { pels au plus (1,5 million) }
  SCRATCH = 8388608;             { memoire de travail des decodeurs }

Type
  THArr = Array[0..319] Of LongInt;

Var
  ScBase, ScUsed : LongInt;
  IErr : Boolean;
  IW, IH, IPix, IStride : LongInt;
  { LZW (GIF) }
  LzPre : Array[0..4095] Of LongInt;
  LzSuf : Array[0..4095] Of LongInt;
  LzStk : Array[0..4199] Of LongInt;
  { inflate }
  InSrc, InLen, InPos, InBit, InCnt : LongInt;
  OutBuf, OutCap, OutPos : LongInt;
  HLenCnt, HLenSym, HDstCnt, HDstSym, HLens : THArr;
  { JPEG (tableaux a une dimension : table * taille + indice) }
  JQ : Array[0..255] Of LongInt;
  JHBits : Array[0..143] Of LongInt;
  JHVal : Array[0..2047] Of LongInt;
  JHMax, JHMin, JHPtr : Array[0..143] Of LongInt;
  JNComp, JHmx, JVmx, JRst : LongInt;
  JCid, JCh, JCv, JCq, JCtd, JCta, JCpred, JCplane, JCw, JCh2 : Array[0..3] Of LongInt;
  JBitBuf, JBitCnt, JPos, JEnd : LongInt;
  JBlk, JTmp, JCos, JRow : Array[0..63] Of LongInt;

Procedure ScratchInit;
Begin
  ScBase := 0;
  If DosAllocMem(LongInt(@ScBase), SCRATCH, $13) <> 0 Then ScBase := 0;
  ScUsed := 0;
End;

Function ScAlloc(N : LongInt) : LongInt;
Begin
  ScAlloc := 0;
  N := (N + 3) And Not 3;
  If (ScBase = 0) Or (N <= 0) Or (ScUsed + N > SCRATCH) Then
  Begin
    IErr := True;
    Exit;
  End;
  ScAlloc := ScBase + ScUsed;
  ScUsed := ScUsed + N;
End;

{ octet I du fichier image (0 et erreur au-dela de la fin) }
Function IB(I : LongInt) : LongInt;
Begin
  If (I < 0) Or (I >= ImgLen) Then
  Begin
    IErr := True;
    IB := 0;
  End
  Else IB := RdB(ImgBuf + I);
End;

Function IW16(I : LongInt) : LongInt;
Begin
  IW16 := IB(I) Or (IB(I + 1) Shl 8);
End;

Function IB16(I : LongInt) : LongInt;
Begin
  IB16 := (IB(I) Shl 8) Or IB(I + 1);
End;

Function IL32(I : LongInt) : LongInt;
Begin
  IL32 := IB(I) Or (IB(I + 1) Shl 8) Or (IB(I + 2) Shl 16) Or (IB(I + 3) Shl 24);
End;

Function IB32(I : LongInt) : LongInt;
Begin
  IB32 := (IB(I) Shl 24) Or (IB(I + 1) Shl 16) Or (IB(I + 2) Shl 8) Or IB(I + 3);
End;

{ image de destination W x H (pels mis au fond de la page) }
Function NewImage(I, W, H : LongInt) : Boolean;
Var A, Bg, K : LongInt;
Begin
  NewImage := False;
  If (W <= 0) Or (H <= 0) Or (W > 4000) Or (H > 4000) Or (W * H > IMG_MAXPIX) Then Exit;
  { 24 bits par pel (B, V, R), lignes alignees sur 4 octets, de bas en
    haut : format des bitmaps d'OS/2 }
  IStride := ((W * 3 + 3) Div 4) * 4;
  A := ArAlloc(IStride * H + 16);
  If A = 0 Then Exit;
  ImBmi[I] := A;
  WrL(A, 16); WrL(A + 4, W); WrL(A + 8, H); WrL(A + 12, 1 Or (24 Shl 16));
  ImBits[I] := A + 16;
  ImW[I] := W; ImH[I] := H;
  IW := W; IH := H; IPix := A + 16;
  Bg := PageBg;
  For K := 0 To W - 1 Do
  Begin
    WrB(IPix + K * 3, Bg And 255); WrB(IPix + K * 3 + 1, (Bg Shr 8) And 255); WrB(IPix + K * 3 + 2, (Bg Shr 16) And 255);
  End;
  For K := 1 To H - 1 Do MemCopy(IPix, IPix + K * IStride, IStride);
  NewImage := True;
End;

{ pel (X, Y depuis le haut) en RVB }
Procedure PutPel(X, Y, Rgb : LongInt);
Var A : LongInt;
Begin
  If (X < 0) Or (Y < 0) Or (X >= IW) Or (Y >= IH) Then Exit;
  A := IPix + (IH - 1 - Y) * IStride + X * 3;
  WrB(A, Rgb And 255); WrB(A + 1, (Rgb Shr 8) And 255); WrB(A + 2, (Rgb Shr 16) And 255);
End;

{ pel avec transparence A (0..255) sur le fond de la page }
Procedure PutPelA(X, Y, Rgb, A : LongInt);
Var R, G, B, Bg : LongInt;
Begin
  If A >= 255 Then
  Begin
    PutPel(X, Y, Rgb);
    Exit;
  End;
  If A <= 0 Then Exit;
  Bg := PageBg;
  R := (((Rgb Shr 16) And 255) * A + ((Bg Shr 16) And 255) * (255 - A)) Div 255;
  G := (((Rgb Shr 8) And 255) * A + ((Bg Shr 8) And 255) * (255 - A)) Div 255;
  B := ((Rgb And 255) * A + (Bg And 255) * (255 - A)) Div 255;
  PutPel(X, Y, (R Shl 16) Or (G Shl 8) Or B);
End;

{ --- GIF (premiere image ; transparence) --- }

Function DecodeGif(Ix : LongInt) : Boolean;
Var P, Flags, Gct, GctN, LctN, Pal, Trans, L, T, W, H, Inter, MinCode, Data, DLen, N, K,
    Clear, Eoi, Avail, CodeSize, CodeMask, OldCode, Code, InCode, First, Sp, Bits, BitCnt, DPos, X, Y,
    Pass, Step, Cnt : LongInt; Stop : Boolean;
Begin
  DecodeGif := False;
  If Not NewImage(Ix, IW16(6), IW16(8)) Then Exit;
  Flags := IB(10);
  P := 13; Gct := 0; GctN := 0;
  If (Flags And $80) <> 0 Then
  Begin
    Gct := P; GctN := 2 Shl (Flags And 7);
    P := P + 3 * GctN;
  End;
  Trans := -1;
  Repeat
    If IErr Or (P >= ImgLen) Then Exit;
    K := IB(P);
    If K = $21 Then
    Begin
      { extension : controle graphique (transparence) }
      If (IB(P + 1) = $F9) And ((IB(P + 3) And 1) <> 0) Then Trans := IB(P + 6);
      P := P + 2;
      While (P < ImgLen) And (IB(P) <> 0) Do P := P + IB(P) + 1;
      Inc(P);
    End
    Else If K = $2C Then Break
    Else Exit;
  Until False;
  L := IW16(P + 1); T := IW16(P + 3); W := IW16(P + 5); H := IW16(P + 7); Flags := IB(P + 9);
  P := P + 10;
  Pal := Gct; LctN := GctN;
  If (Flags And $80) <> 0 Then
  Begin
    Pal := P; LctN := 2 Shl (Flags And 7);
    P := P + 3 * LctN;
  End;
  Inter := Flags And $40;
  If (Pal = 0) Or (W <= 0) Or (H <= 0) Then Exit;
  MinCode := IB(P);
  Inc(P);
  If (MinCode < 2) Or (MinCode > 11) Then Exit;
  { donnees LZW : sous-blocs concatenes }
  Data := ScAlloc(ImgLen);
  If Data = 0 Then Exit;
  DLen := 0;
  While (P < ImgLen) And (IB(P) <> 0) Do
  Begin
    N := IB(P);
    For K := 1 To N Do
      If P + K < ImgLen Then
      Begin
        WrB(Data + DLen, IB(P + K));
        Inc(DLen);
      End;
    P := P + N + 1;
  End;
  { decodage LZW }
  Clear := 1 Shl MinCode; Eoi := Clear + 1;
  Avail := Clear + 2; CodeSize := MinCode + 1; CodeMask := (1 Shl CodeSize) - 1;
  OldCode := -1; First := 0; Sp := 0;
  For K := 0 To 4095 Do
  Begin
    LzPre[K] := -1;
    If K < Clear Then LzSuf[K] := K Else LzSuf[K] := 0;
  End;
  Bits := 0; BitCnt := 0; DPos := 0;
  X := 0; Y := 0; Pass := 0;
  If Inter <> 0 Then Step := 8 Else Step := 1;
  Cnt := 0; Stop := False;
  While (Y < H) And (Cnt < W * H) And Not Stop Do
  Begin
    If Sp = 0 Then
    Begin
      While BitCnt < CodeSize Do
      Begin
        If DPos >= DLen Then
        Begin
          Stop := True;
          Break;
        End;
        Bits := Bits Or (RdB(Data + DPos) Shl BitCnt);
        Inc(DPos);
        BitCnt := BitCnt + 8;
      End;
      If Stop Then Break;
      Code := Bits And CodeMask;
      Bits := Bits Shr CodeSize;
      BitCnt := BitCnt - CodeSize;
      If Code = Clear Then
      Begin
        CodeSize := MinCode + 1; CodeMask := (1 Shl CodeSize) - 1; Avail := Clear + 2; OldCode := -1;
        Continue;
      End;
      If Code = Eoi Then Break;
      If OldCode = -1 Then
      Begin
        If Code >= Clear Then Break;
        LzStk[Sp] := LzSuf[Code]; Inc(Sp);
        OldCode := Code; First := Code;
      End
      Else
      Begin
        InCode := Code;
        If Code >= Avail Then
        Begin
          If Code > Avail Then Break;
          LzStk[Sp] := First; Inc(Sp);
          Code := OldCode;
        End;
        While (Code >= Clear) And (Sp < 4096) Do
        Begin
          LzStk[Sp] := LzSuf[Code]; Inc(Sp);
          Code := LzPre[Code];
          If Code < 0 Then Break;
        End;
        If (Code < 0) Or (Sp >= 4096) Then Break;
        First := LzSuf[Code];
        LzStk[Sp] := First; Inc(Sp);
        If Avail < 4096 Then
        Begin
          LzPre[Avail] := OldCode; LzSuf[Avail] := First;
          Inc(Avail);
          If ((Avail And CodeMask) = 0) And (Avail < 4096) Then
          Begin
            Inc(CodeSize);
            CodeMask := (1 Shl CodeSize) - 1;
          End;
        End;
        OldCode := InCode;
      End;
    End;
    { pel suivant }
    Dec(Sp);
    K := LzStk[Sp];
    If (K <> Trans) And (K < LctN) Then
      PutPel(L + X, T + Y, (IB(Pal + K * 3) Shl 16) Or (IB(Pal + K * 3 + 1) Shl 8) Or IB(Pal + K * 3 + 2));
    Inc(Cnt);
    Inc(X);
    If X >= W Then
    Begin
      X := 0;
      Y := Y + Step;
      If (Inter <> 0) And (Y >= H) Then
      Begin
        Inc(Pass);
        Case Pass Of
          1 :
            Begin
              Y := 4; Step := 8;
            End;
          2 :
            Begin
              Y := 2; Step := 4;
            End;
          3 :
            Begin
              Y := 1; Step := 2;
            End;
        End;
      End;
    End;
  End;
  DecodeGif := Cnt > 0;
End;

{ --- inflate (zlib, RFC 1950 / 1951 ; d'apres "puff" de Mark Adler) --- }

Function GetBit : LongInt;
Begin
  If InCnt = 0 Then
  Begin
    If InPos >= InLen Then
    Begin
      IErr := True;
      GetBit := 0;
      Exit;
    End;
    InBit := RdB(InSrc + InPos);
    Inc(InPos);
    InCnt := 8;
  End;
  GetBit := InBit And 1;
  InBit := InBit Shr 1;
  Dec(InCnt);
End;

Function GetBits(N : LongInt) : LongInt;
Var V, K : LongInt;
Begin
  V := 0;
  For K := 0 To N - 1 Do V := V Or (GetBit Shl K);
  GetBits := V;
End;

{ table de Huffman canonique : nombre de codes par longueur (Cnt[1..15])
  et symboles dans l'ordre des codes (Sym) }
Procedure HBuild(Var Cnt, Sym, Lens : THArr; N : LongInt);
Var Offs : Array[0..16] Of LongInt; K : LongInt;
Begin
  For K := 0 To 15 Do Cnt[K] := 0;
  For K := 0 To N - 1 Do Inc(Cnt[Lens[K] And 15]);
  Cnt[0] := 0;
  Offs[1] := 0;
  For K := 1 To 14 Do Offs[K + 1] := Offs[K] + Cnt[K];
  For K := 0 To N - 1 Do
    If Lens[K] <> 0 Then
    Begin
      Sym[Offs[Lens[K]]] := K;
      Inc(Offs[Lens[K]]);
    End;
End;

{ un symbole (D = 0 : longueurs et litteraux, D = 1 : distances) }
Function HDecode(D : LongInt) : LongInt;
Var Code, First, Idx, Len, Count : LongInt;
Begin
  Code := 0; First := 0; Idx := 0;
  For Len := 1 To 15 Do
  Begin
    Code := Code Or GetBit;
    If D = 0 Then Count := HLenCnt[Len] Else Count := HDstCnt[Len];
    If Code - Count < First Then
    Begin
      If D = 0 Then HDecode := HLenSym[Idx + (Code - First)] Else HDecode := HDstSym[Idx + (Code - First)];
      Exit;
    End;
    Idx := Idx + Count;
    First := (First + Count) Shl 1;
    Code := Code Shl 1;
    If IErr Then Break;
  End;
  IErr := True;
  HDecode := -1;
End;

Procedure OutByte(B : LongInt);
Begin
  If OutPos < OutCap Then WrB(OutBuf + OutPos, B) Else IErr := True;
  Inc(OutPos);
End;

Const
  LBase : Array[0..28] Of LongInt = (3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99,
                                     115, 131, 163, 195, 227, 258);
  LExt : Array[0..28] Of LongInt = (0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0);
  DBase : Array[0..29] Of LongInt = (1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025,
                                     1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577);
  DExt : Array[0..29] Of LongInt = (0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
                                    12, 12, 13, 13);
  CLOrd : Array[0..18] Of LongInt = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

Procedure InflateCodes;
Var S, L, D, K : LongInt;
Begin
  Repeat
    S := HDecode(0);
    If IErr Or (S < 0) Then Exit;
    If S < 256 Then OutByte(S)
    Else If S > 256 Then
    Begin
      S := S - 257;
      If S > 28 Then
      Begin
        IErr := True;
        Exit;
      End;
      L := LBase[S] + GetBits(LExt[S]);
      S := HDecode(1);
      If (S < 0) Or (S > 29) Then
      Begin
        IErr := True;
        Exit;
      End;
      D := DBase[S] + GetBits(DExt[S]);
      If D > OutPos Then
      Begin
        IErr := True;
        Exit;
      End;
      For K := 1 To L Do
      Begin
        If OutPos < OutCap Then WrB(OutBuf + OutPos, RdB(OutBuf + OutPos - D)) Else IErr := True;
        Inc(OutPos);
      End;
    End;
  Until (S = 256) Or IErr;
End;

Function Inflate(Src, SLen, Dst, DCap : LongInt) : LongInt;
Var Last, Typ, K, N, NLen, NDist, NCode, S, Rep, Prev : LongInt;
Begin
  InSrc := Src; InLen := SLen; InPos := 0; InCnt := 0; InBit := 0;
  OutBuf := Dst; OutCap := DCap; OutPos := 0;
  Repeat
    Last := GetBit;
    Typ := GetBits(2);
    If Typ = 0 Then
    Begin
      { bloc stocke }
      InCnt := 0;
      If InPos + 4 > InLen Then
      Begin
        IErr := True;
        Break;
      End;
      N := RdB(InSrc + InPos) Or (RdB(InSrc + InPos + 1) Shl 8);
      InPos := InPos + 4;
      For K := 1 To N Do
      Begin
        If InPos >= InLen Then
        Begin
          IErr := True;
          Break;
        End;
        OutByte(RdB(InSrc + InPos));
        Inc(InPos);
      End;
    End
    Else If Typ = 1 Then
    Begin
      { codes fixes }
      For K := 0 To 143 Do HLens[K] := 8;
      For K := 144 To 255 Do HLens[K] := 9;
      For K := 256 To 279 Do HLens[K] := 7;
      For K := 280 To 287 Do HLens[K] := 8;
      HBuild(HLenCnt, HLenSym, HLens, 288);
      For K := 0 To 29 Do HLens[K] := 5;
      HBuild(HDstCnt, HDstSym, HLens, 30);
      InflateCodes;
    End
    Else If Typ = 2 Then
    Begin
      { codes dynamiques }
      NLen := GetBits(5) + 257; NDist := GetBits(5) + 1; NCode := GetBits(4) + 4;
      If (NLen > 286) Or (NDist > 30) Then
      Begin
        IErr := True;
        Break;
      End;
      For K := 0 To 18 Do HLens[K] := 0;
      For K := 0 To NCode - 1 Do HLens[CLOrd[K]] := GetBits(3);
      HBuild(HLenCnt, HLenSym, HLens, 19);
      K := 0;
      While (K < NLen + NDist) And Not IErr Do
      Begin
        S := HDecode(0);
        If S < 0 Then Break;
        If S < 16 Then
        Begin
          HLens[K] := S;
          Inc(K);
        End
        Else
        Begin
          Prev := 0;
          If S = 16 Then
          Begin
            If K = 0 Then
            Begin
              IErr := True;
              Break;
            End;
            Prev := HLens[K - 1];
            Rep := 3 + GetBits(2);
          End
          Else If S = 17 Then Rep := 3 + GetBits(3)
          Else Rep := 11 + GetBits(7);
          If K + Rep > NLen + NDist Then
          Begin
            IErr := True;
            Break;
          End;
          While Rep > 0 Do
          Begin
            HLens[K] := Prev;
            Inc(K); Dec(Rep);
          End;
        End;
      End;
      If IErr Then Break;
      HBuild(HLenCnt, HLenSym, HLens, NLen);
      For K := 0 To NDist - 1 Do HLens[K] := HLens[NLen + K];
      HBuild(HDstCnt, HDstSym, HLens, NDist);
      InflateCodes;
    End
    Else IErr := True;
  Until (Last = 1) Or IErr;
  Inflate := OutPos;
End;

{ --- PNG --- }

Function Paeth(A, B, C : LongInt) : LongInt;
Var P, Pa, Pb, Pc : LongInt;
Begin
  P := A + B - C;
  Pa := Abs(P - A); Pb := Abs(P - B); Pc := Abs(P - C);
  If (Pa <= Pb) And (Pa <= Pc) Then Paeth := A
  Else If Pb <= Pc Then Paeth := B
  Else Paeth := C;
End;

{ defiltrage de H lignes de RowB octets (filtre en tete de ligne), Bpp
  octets par pel }
Function Unfilter(Src, RowB, H, Bpp : LongInt) : Boolean;
Var Y, X, F, R, Pr, A, B, C, V : LongInt;
Begin
  Unfilter := False;
  For Y := 0 To H - 1 Do
  Begin
    R := Src + Y * (RowB + 1);
    F := RdB(R);
    Inc(R);
    If Y > 0 Then Pr := Src + (Y - 1) * (RowB + 1) + 1 Else Pr := 0;
    If F > 4 Then Exit;
    If F <> 0 Then
      For X := 0 To RowB - 1 Do
      Begin
        If X >= Bpp Then A := RdB(R + X - Bpp) Else A := 0;
        If Pr <> 0 Then B := RdB(Pr + X) Else B := 0;
        If (Pr <> 0) And (X >= Bpp) Then C := RdB(Pr + X - Bpp) Else C := 0;
        V := RdB(R + X);
        Case F Of
          1 : V := V + A;
          2 : V := V + B;
          3 : V := V + (A + B) Div 2;
          4 : V := V + Paeth(A, B, C);
        End;
        WrB(R + X, V And 255);
      End;
  End;
  Unfilter := True;
End;

Var
  PngCT, PngBD, PngPal, PngPalN, PngTrns, PngTrnsN : LongInt;

{ pel X d'une ligne defiltree -> RVB et alpha }
Procedure PngPel(R, X : LongInt; Var Rgb, A : LongInt);
Var V, Sh, Mx, G : LongInt;
Begin
  A := 255; Rgb := 0;
  Case PngCT Of
    0, 3 :
      Begin
        If PngBD = 8 Then V := RdB(R + X)
        Else If PngBD = 16 Then V := RdB(R + X * 2)
        Else
        Begin
          Sh := 8 - PngBD - (X * PngBD) Mod 8;
          V := (RdB(R + (X * PngBD) Div 8) Shr Sh) And ((1 Shl PngBD) - 1);
        End;
        If PngCT = 3 Then
        Begin
          If V < PngPalN Then Rgb := (IB(PngPal + V * 3) Shl 16) Or (IB(PngPal + V * 3 + 1) Shl 8) Or IB(PngPal + V * 3 + 2);
          If V < PngTrnsN Then A := IB(PngTrns + V);
        End
        Else
        Begin
          If PngBD < 8 Then
          Begin
            Mx := (1 Shl PngBD) - 1;
            G := (V * 255) Div Mx;
          End
          Else G := V;
          Rgb := (G Shl 16) Or (G Shl 8) Or G;
          If (PngTrnsN >= 2) And (PngBD < 8) And (V = (IB(PngTrns + 1) And ((1 Shl PngBD) - 1))) Then A := 0;
          If (PngTrnsN >= 2) And (PngBD = 8) And (V = IB(PngTrns + 1)) Then A := 0;
        End;
      End;
    2 :
      If PngBD = 8 Then Rgb := (RdB(R + X * 3) Shl 16) Or (RdB(R + X * 3 + 1) Shl 8) Or RdB(R + X * 3 + 2)
      Else Rgb := (RdB(R + X * 6) Shl 16) Or (RdB(R + X * 6 + 2) Shl 8) Or RdB(R + X * 6 + 4);
    4 :
      If PngBD = 8 Then
      Begin
        G := RdB(R + X * 2); A := RdB(R + X * 2 + 1);
        Rgb := (G Shl 16) Or (G Shl 8) Or G;
      End
      Else
      Begin
        G := RdB(R + X * 4); A := RdB(R + X * 4 + 2);
        Rgb := (G Shl 16) Or (G Shl 8) Or G;
      End;
    6 :
      If PngBD = 8 Then
      Begin
        Rgb := (RdB(R + X * 4) Shl 16) Or (RdB(R + X * 4 + 1) Shl 8) Or RdB(R + X * 4 + 2);
        A := RdB(R + X * 4 + 3);
      End
      Else
      Begin
        Rgb := (RdB(R + X * 8) Shl 16) Or (RdB(R + X * 8 + 2) Shl 8) Or RdB(R + X * 8 + 4);
        A := RdB(R + X * 8 + 6);
      End;
  End;
End;

Const
  AX0 : Array[0..6] Of LongInt = (0, 4, 0, 2, 0, 1, 0);
  AY0 : Array[0..6] Of LongInt = (0, 0, 4, 0, 2, 0, 1);
  ADX : Array[0..6] Of LongInt = (8, 8, 4, 4, 2, 2, 1);
  ADY : Array[0..6] Of LongInt = (8, 8, 8, 4, 4, 2, 2);

Function DecodePng(Ix : LongInt) : Boolean;
Var P, L, T, W, H, Inter, Idat, ILen, Raw, RawCap, Got, Chans, BitsPx, Bpp, RowB, Y, X, Rgb, A, Pass, Pw, Ph,
    Off, Px0, Py0, Dx, Dy : LongInt;
Begin
  DecodePng := False;
  W := IB32(16); H := IB32(20); PngBD := IB(24); PngCT := IB(25); Inter := IB(28);
  If (W <= 0) Or (H <= 0) Or (W > 4000) Or (H > 4000) Or (W * H > IMG_MAXPIX) Then Exit;
  Case PngCT Of
    0, 3 : Chans := 1;
    2 : Chans := 3;
    4 : Chans := 2;
    6 : Chans := 4;
  Else
    Exit;
  End;
  If Not (PngBD In [1, 2, 4, 8, 16]) Then Exit;
  BitsPx := Chans * PngBD;
  Bpp := MaxI(1, BitsPx Div 8);
  { morceaux : PLTE, tRNS, IDAT }
  PngPal := 0; PngPalN := 0; PngTrns := 0; PngTrnsN := 0;
  Idat := ScAlloc(ImgLen);
  If Idat = 0 Then Exit;
  ILen := 0;
  P := 8;
  While (P + 8 <= ImgLen) And Not IErr Do
  Begin
    L := IB32(P); T := IB32(P + 4);
    If (L < 0) Or (P + 12 + L > ImgLen) Then Break;
    If T = $504C5445 Then
    Begin
      PngPal := P + 8; PngPalN := L Div 3;
    End
    Else If T = $74524E53 Then
    Begin
      PngTrns := P + 8; PngTrnsN := L;
    End
    Else If T = $49444154 Then
    Begin
      MemCopy(ImgBuf + P + 8, Idat + ILen, L);
      ILen := ILen + L;
    End
    Else If T = $49454E44 Then Break;
    P := P + 12 + L;
  End;
  IErr := False;
  If (ILen < 3) Or ((PngCT = 3) And (PngPal = 0)) Then Exit;
  { taille des donnees decompressees }
  RawCap := ((W * BitsPx + 7) Div 8 + 1) * H;
  If Inter <> 0 Then RawCap := RawCap * 2 + 64;
  Raw := ScAlloc(RawCap + 16);
  If Raw = 0 Then Exit;
  Got := Inflate(Idat + 2, ILen - 2, Raw, RawCap + 16);
  IErr := False;
  If Got <= 0 Then Exit;
  If Not NewImage(Ix, W, H) Then Exit;
  If Inter = 0 Then
  Begin
    RowB := (W * BitsPx + 7) Div 8;
    If Got < (RowB + 1) * H Then H := Got Div (RowB + 1);
    If Not Unfilter(Raw, RowB, H, Bpp) Then Exit;
    For Y := 0 To H - 1 Do
      For X := 0 To W - 1 Do
      Begin
        PngPel(Raw + Y * (RowB + 1) + 1, X, Rgb, A);
        PutPelA(X, Y, Rgb, A);
      End;
  End
  Else
  Begin
    { Adam7 : sept passes }
    Off := 0;
    For Pass := 0 To 6 Do
    Begin
      Px0 := AX0[Pass]; Py0 := AY0[Pass]; Dx := ADX[Pass]; Dy := ADY[Pass];
      If W > Px0 Then Pw := (W - Px0 + Dx - 1) Div Dx Else Pw := 0;
      If H > Py0 Then Ph := (H - Py0 + Dy - 1) Div Dy Else Ph := 0;
      If (Pw = 0) Or (Ph = 0) Then Continue;
      RowB := (Pw * BitsPx + 7) Div 8;
      If Off + (RowB + 1) * Ph > Got Then Break;
      If Not Unfilter(Raw + Off, RowB, Ph, Bpp) Then Exit;
      For Y := 0 To Ph - 1 Do
        For X := 0 To Pw - 1 Do
        Begin
          PngPel(Raw + Off + Y * (RowB + 1) + 1, X, Rgb, A);
          PutPelA(Px0 + X * Dx, Py0 + Y * Dy, Rgb, A);
        End;
      Off := Off + (RowB + 1) * Ph;
    End;
  End;
  DecodePng := True;
End;

{ --- BMP (1, 4, 8, 24 et 32 bits, non compresse) --- }

Function DecodeBmp(Ix : LongInt) : Boolean;
Var Hd, W, H, Bpp, Cmp, Pal, PalSz, Bits, Stride, X, Y, Yy, V, A, Top : LongInt;
Begin
  DecodeBmp := False;
  Hd := 14;
  If IL32(Hd) = 12 Then
  Begin
    W := IW16(Hd + 4); H := IW16(Hd + 6); Bpp := IW16(Hd + 10); Cmp := 0; PalSz := 3;
  End
  Else
  Begin
    W := IL32(Hd + 4); H := IL32(Hd + 8); Bpp := IW16(Hd + 14); Cmp := IL32(Hd + 16); PalSz := 4;
  End;
  Top := 0;
  If H < 0 Then
  Begin
    H := -H; Top := 1;
  End;
  If Not (Bpp In [1, 4, 8, 24, 32]) Or ((Cmp <> 0) And (Cmp <> 3)) Then Exit;
  Pal := Hd + IL32(Hd);
  Bits := IL32(10);
  Stride := ((W * Bpp + 31) Div 32) * 4;
  If Not NewImage(Ix, W, H) Then Exit;
  For Y := 0 To H - 1 Do
  Begin
    If Top = 1 Then Yy := Y Else Yy := H - 1 - Y;
    A := Bits + Yy * Stride;
    If A + Stride > ImgLen Then Continue;
    For X := 0 To W - 1 Do
    Begin
      Case Bpp Of
        1 : V := (IB(A + X Shr 3) Shr (7 - (X And 7))) And 1;
        4 : V := (IB(A + X Shr 1) Shr (4 * (1 - (X And 1)))) And 15;
        8 : V := IB(A + X);
        24 : V := -1 - ((IB(A + X * 3 + 2) Shl 16) Or (IB(A + X * 3 + 1) Shl 8) Or IB(A + X * 3));
      Else
        V := -1 - ((IB(A + X * 4 + 2) Shl 16) Or (IB(A + X * 4 + 1) Shl 8) Or IB(A + X * 4));
      End;
      If V >= 0 Then V := (IB(Pal + V * PalSz + 2) Shl 16) Or (IB(Pal + V * PalSz + 1) Shl 8) Or IB(Pal + V * PalSz)
      Else V := -1 - V;
      PutPel(X, Y, V);
    End;
  End;
  DecodeBmp := True;
End;

{ --- JPEG (de base, Huffman ; sous-echantillonnage, reprises) --- }

Const
  ZigZag : Array[0..63] Of LongInt = (0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48,
                                      41, 34, 27, 20, 13, 6, 7, 14, 21, 28, 35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15,
                                      23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63);
  { cos(k pi / 16) * 4096, k = 0..8 }
  CosT : Array[0..8] Of LongInt = (4096, 4017, 3784, 3406, 2896, 2276, 1567, 799, 0);

{ cosinus de l'IDCT : C(u) cos((2x + 1) u pi / 16) * 4096 }
Procedure JInitCos;
Var X, U, K, S : LongInt;
Begin
  For X := 0 To 7 Do
    For U := 0 To 7 Do
    Begin
      K := ((2 * X + 1) * U) Mod 32;
      S := 1;
      If K > 16 Then K := 32 - K;
      If K > 8 Then
      Begin
        K := 16 - K; S := -1;
      End;
      If U = 0 Then JCos[X * 8 + U] := 2896
      Else JCos[X * 8 + U] := S * CosT[K];
    End;
End;

Function JByte : LongInt;
Begin
  If JPos < JEnd Then
  Begin
    JByte := IB(JPos);
    Inc(JPos);
  End
  Else JByte := 0;
End;

Function JBit : LongInt;
Var B : LongInt;
Begin
  If JBitCnt = 0 Then
  Begin
    B := JByte;
    If B = $FF Then
    Begin
      { octet de bourrage FF00 ; un marqueur arrete les donnees }
      If (JPos < JEnd) And (IB(JPos) = 0) Then Inc(JPos)
      Else
      Begin
        Dec(JPos);
        B := 0;
      End;
    End;
    JBitBuf := B;
    JBitCnt := 8;
  End;
  Dec(JBitCnt);
  JBit := (JBitBuf Shr JBitCnt) And 1;
End;

Function JBits(N : LongInt) : LongInt;
Var V, K : LongInt;
Begin
  V := 0;
  For K := 1 To N Do V := (V Shl 1) Or JBit;
  JBits := V;
End;

Function JExtend(V, N : LongInt) : LongInt;
Begin
  If N = 0 Then JExtend := 0
  Else If V < (1 Shl (N - 1)) Then JExtend := V - (1 Shl N) + 1
  Else JExtend := V;
End;

Function JDecode(T : LongInt) : LongInt;
Var Code, L : LongInt;
Begin
  Code := JBit;
  L := 1;
  While (L <= 16) And ((JHMax[T * 18 + L] < 0) Or (Code > JHMax[T * 18 + L])) Do
  Begin
    Code := (Code Shl 1) Or JBit;
    Inc(L);
  End;
  If L > 16 Then
  Begin
    IErr := True;
    JDecode := 0;
    Exit;
  End;
  JDecode := JHVal[T * 256 + ((JHPtr[T * 18 + L] + Code - JHMin[T * 18 + L]) And 255)];
End;

{ IDCT 8 x 8 (separable, virgule fixe) de JBlk vers JTmp (0..255) }
Procedure JIdct;
Var X, Y, U, S : LongInt;
Begin
  For Y := 0 To 7 Do
    For X := 0 To 7 Do
    Begin
      S := 0;
      For U := 0 To 7 Do
        If JBlk[Y * 8 + U] <> 0 Then S := S + JBlk[Y * 8 + U] * JCos[X * 8 + U];
      JRow[Y * 8 + X] := S Div 4096;
    End;
  For X := 0 To 7 Do
    For Y := 0 To 7 Do
    Begin
      S := 0;
      For U := 0 To 7 Do S := S + JRow[U * 8 + X] * JCos[Y * 8 + U];
      S := S Div 16384 + 128;
      If S < 0 Then S := 0 Else If S > 255 Then S := 255;
      JTmp[Y * 8 + X] := S;
    End;
End;

Procedure JBlock(C, Bx, By : LongInt);
Var K, S, R, V, Q, X, Y, Pl, W : LongInt;
Begin
  For K := 0 To 63 Do JBlk[K] := 0;
  { coefficient continu }
  S := JDecode(JCtd[C]);
  If (S < 0) Or (S > 15) Then
  Begin
    IErr := True;
    Exit;
  End;
  V := JExtend(JBits(S), S);
  JCpred[C] := JCpred[C] + V;
  Q := JCq[C] * 64;
  JBlk[0] := JCpred[C] * JQ[Q];
  { coefficients alternatifs }
  K := 1;
  While (K < 64) And Not IErr Do
  Begin
    S := JDecode(4 + JCta[C]);
    R := (S Shr 4) And 15; S := S And 15;
    If S = 0 Then
    Begin
      If R = 15 Then K := K + 16 Else Break;
    End
    Else
    Begin
      K := K + R;
      If K > 63 Then Break;
      V := JExtend(JBits(S), S);
      JBlk[ZigZag[K]] := V * JQ[Q + K];
      Inc(K);
    End;
  End;
  JIdct;
  Pl := JCplane[C]; W := JCw[C];
  For Y := 0 To 7 Do
    If By + Y < JCh2[C] Then
      For X := 0 To 7 Do
        If Bx + X < W Then WrB(Pl + (By + Y) * W + Bx + X, JTmp[Y * 8 + X]);
End;

Function DecodeJpeg(Ix : LongInt) : Boolean;
Var P, M, L, K, J, T, N, C, Code, Cnt, Mx, My, Mcx, Mcy, X, Y, Yy, Cb, Cr, R, G, B, Sx, Sy, Restart,
    W, H, Base : LongInt; Done : Boolean;
Begin
  DecodeJpeg := False;
  JInitCos;
  For K := 0 To 143 Do JHMax[K] := -1;
  W := 0; H := 0; JNComp := 0; JRst := 0;
  P := 2; Done := False;
  While (P + 4 <= ImgLen) And Not Done And Not IErr Do
  Begin
    If IB(P) <> $FF Then
    Begin
      Inc(P);
      Continue;
    End;
    M := IB(P + 1);
    If (M = $FF) Or (M = $D8) Or ((M >= $D0) And (M <= $D7)) Or (M = 1) Then
    Begin
      Inc(P);
      Continue;
    End;
    L := IB16(P + 2);
    Base := P + 4;
    Case M Of
      $DB :
        Begin
          { tables de quantification }
          K := Base;
          While K < P + 2 + L Do
          Begin
            T := IB(K) And 3;
            If (IB(K) Shr 4) = 0 Then
            Begin
              For J := 0 To 63 Do JQ[T * 64 + J] := IB(K + 1 + J);
              K := K + 65;
            End
            Else
            Begin
              For J := 0 To 63 Do JQ[T * 64 + J] := IB16(K + 1 + J * 2);
              K := K + 129;
            End;
          End;
        End;
      $C0, $C1 :
        Begin
          H := IB16(Base + 1); W := IB16(Base + 3); JNComp := IB(Base + 5);
          If (JNComp <> 1) And (JNComp <> 3) Then Exit;
          JHmx := 1; JVmx := 1;
          For C := 0 To JNComp - 1 Do
          Begin
            JCid[C] := IB(Base + 6 + C * 3);
            JCh[C] := IB(Base + 7 + C * 3) Shr 4; JCv[C] := IB(Base + 7 + C * 3) And 15;
            JCq[C] := IB(Base + 8 + C * 3) And 3;
            If (JCh[C] < 1) Or (JCh[C] > 4) Or (JCv[C] < 1) Or (JCv[C] > 4) Then Exit;
            If JCh[C] > JHmx Then JHmx := JCh[C];
            If JCv[C] > JVmx Then JVmx := JCv[C];
          End;
        End;
      $C2, $C3, $C5, $C6, $C7, $C9, $CA, $CB, $CD, $CE, $CF : Exit;   { progressif, sans perte, arithmetique }
      $C4 :
        Begin
          { tables de Huffman }
          K := Base;
          While (K < P + 2 + L) And Not IErr Do
          Begin
            T := (IB(K) And 3) + ((IB(K) Shr 4) And 1) * 4;
            N := 0;
            For J := 1 To 16 Do
            Begin
              JHBits[T * 18 + J] := IB(K + J);
              N := N + JHBits[T * 18 + J];
            End;
            If N > 256 Then Exit;
            For J := 0 To N - 1 Do JHVal[T * 256 + J] := IB(K + 17 + J);
            { codes canoniques : minimum, maximum, indice }
            Code := 0; Cnt := 0;
            For J := 1 To 16 Do
            Begin
              JHPtr[T * 18 + J] := Cnt;
              JHMin[T * 18 + J] := Code;
              Code := Code + JHBits[T * 18 + J];
              Cnt := Cnt + JHBits[T * 18 + J];
              If JHBits[T * 18 + J] > 0 Then JHMax[T * 18 + J] := Code - 1 Else JHMax[T * 18 + J] := -1;
              Code := Code Shl 1;
            End;
            K := K + 17 + N;
          End;
        End;
      $DD : JRst := IB16(Base);
      $DA :
        Begin
          { debut des donnees : composantes du balayage }
          N := IB(Base);
          For J := 0 To N - 1 Do
            For C := 0 To JNComp - 1 Do
              If JCid[C] = IB(Base + 1 + J * 2) Then
              Begin
                JCtd[C] := (IB(Base + 2 + J * 2) Shr 4) And 3;
                JCta[C] := IB(Base + 2 + J * 2) And 3;
              End;
          JPos := P + 2 + L; JEnd := ImgLen;
          Done := True;
        End;
      $D9 : Exit;
    End;
    If Not Done Then P := P + 2 + L;
  End;
  If (Not Done) Or IErr Or (W <= 0) Or (H <= 0) Or (JNComp = 0) Or (W * H > IMG_MAXPIX) Then Exit;
  { plans des composantes (taille arrondie aux MCU) }
  Mcx := (W + 8 * JHmx - 1) Div (8 * JHmx);
  Mcy := (H + 8 * JVmx - 1) Div (8 * JVmx);
  For C := 0 To JNComp - 1 Do
  Begin
    JCw[C] := Mcx * JCh[C] * 8; JCh2[C] := Mcy * JCv[C] * 8;
    JCplane[C] := ScAlloc(JCw[C] * JCh2[C]);
    If JCplane[C] = 0 Then Exit;
    MemFill(JCplane[C], JCw[C] * JCh2[C], 128);
    JCpred[C] := 0;
  End;
  JBitCnt := 0; Restart := 0;
  For My := 0 To Mcy - 1 Do
  Begin
    For Mx := 0 To Mcx - 1 Do
    Begin
      If IErr Then Break;
      If (JRst > 0) And (Restart = JRst) Then
      Begin
        { marqueur de reprise RSTn }
        JBitCnt := 0;
        While (JPos + 1 < JEnd) And Not ((IB(JPos) = $FF) And (IB(JPos + 1) >= $D0) And (IB(JPos + 1) <= $D7)) Do
          Inc(JPos);
        JPos := JPos + 2;
        For C := 0 To JNComp - 1 Do JCpred[C] := 0;
        Restart := 0;
      End;
      For C := 0 To JNComp - 1 Do
        For Sy := 0 To JCv[C] - 1 Do
          For Sx := 0 To JCh[C] - 1 Do
            If Not IErr Then JBlock(C, (Mx * JCh[C] + Sx) * 8, (My * JCv[C] + Sy) * 8);
      Inc(Restart);
    End;
    If IErr Then Break;
  End;
  { image partielle gardee si les donnees sont tronquees }
  IErr := False;
  If Not NewImage(Ix, W, H) Then Exit;
  For Y := 0 To H - 1 Do
    For X := 0 To W - 1 Do
    Begin
      Yy := RdB(JCplane[0] + ((Y * JCv[0]) Div JVmx) * JCw[0] + (X * JCh[0]) Div JHmx);
      If JNComp = 3 Then
      Begin
        Cb := RdB(JCplane[1] + ((Y * JCv[1]) Div JVmx) * JCw[1] + (X * JCh[1]) Div JHmx) - 128;
        Cr := RdB(JCplane[2] + ((Y * JCv[2]) Div JVmx) * JCw[2] + (X * JCh[2]) Div JHmx) - 128;
        R := Yy + (91881 * Cr) Div 65536;
        G := Yy - (22554 * Cb + 46802 * Cr) Div 65536;
        B := Yy + (116130 * Cb) Div 65536;
        If R < 0 Then R := 0 Else If R > 255 Then R := 255;
        If G < 0 Then G := 0 Else If G > 255 Then G := 255;
        If B < 0 Then B := 0 Else If B > 255 Then B := 255;
        PutPel(X, Y, (R Shl 16) Or (G Shl 8) Or B);
      End
      Else PutPel(X, Y, (Yy Shl 16) Or (Yy Shl 8) Or Yy);
    End;
  DecodeJpeg := True;
End;

{ decode l'image I (ImgBuf, ImgLen octets) ; format reconnu par sa
  signature }
Function DecodeImage(I : LongInt) : Boolean;
Var Ok : Boolean; Save : LongInt;
Begin
  DecodeImage := False;
  If (ImgLen < 8) Or (I < 0) Or (I >= NImgs) Then Exit;
  If ScBase = 0 Then ScratchInit;
  If ScBase = 0 Then Exit;
  ScUsed := 0; IErr := False;
  Save := ArUsed;
  Ok := False;
  If (IB(0) = $47) And (IB(1) = $49) And (IB(2) = $46) Then Ok := DecodeGif(I)
  Else If (IB(0) = $89) And (IB(1) = $50) And (IB(2) = $4E) And (IB(3) = $47) Then Ok := DecodePng(I)
  Else If (IB(0) = $FF) And (IB(1) = $D8) Then Ok := DecodeJpeg(I)
  Else If (IB(0) = $42) And (IB(1) = $4D) Then Ok := DecodeBmp(I);
  If Not Ok Then
  Begin
    { memoire de l'image rendue a l'arene }
    ArUsed := Save;
    ImBits[I] := 0; ImBmi[I] := 0;
  End;
  DecodeImage := Ok;
End;

{ ==================================================================== }
{ JavaScript : interpreteur (sous-ensemble d'ECMAScript 5 et quelques   }
{ formes recentes) pour les scripts des pages, la console et le         }
{ debogueur des outils de developpement                                 }
{ ==================================================================== }
{ Le BROWSER.PAS d'origine evaluait le texte des scripts directement :
  return/break ne sortaient que du bloc courant, pas de fonctions
  anonymes ni de fermetures, setTimeout limite a une chaine et un seul
  minuteur, alert() muet.  Ici : analyse en arbre syntaxique (dans
  l'arene de la page), portees et fermetures, exceptions (try, catch,
  finally, throw), switch, do..while, for..in, fonctions flechees,
  plusieurs minuteurs, alert() et confirm() en boites de message de PM.
  Les chaines sont dans l'arene (sans limite de 255 caracteres).
  Garde-fous : budget d'operations par execution (boucle infinie ->
  erreur "script trop long"), profondeur d'appels, memoire de l'arene. }

Const
  { types de valeurs }
  JV_UNDEF = 0; JV_NULL = 1; JV_BOOL = 2; JV_NUM = 3; JV_STR = 4; JV_OBJ = 5; JV_FUN = 6; JV_NAT = 7;
  JV_NODE = 8;
  { types de noeuds de l'arbre syntaxique }
  JN_NUM = 1; JN_STR = 2; JN_IDENT = 3; JN_TRUE = 4; JN_FALSE = 5; JN_NULL = 6; JN_UNDEF = 7; JN_THIS = 8;
  JN_ARRAY = 9; JN_OBJECT = 10; JN_PROP = 11; JN_FUNC = 12; JN_MEMBER = 13; JN_INDEX = 14; JN_CALL = 15;
  JN_NEW = 16; JN_UNARY = 17; JN_BINARY = 18; JN_LOGIC = 19; JN_COND = 20; JN_ASSIGN = 21; JN_PREINC = 22;
  JN_POSTINC = 23; JN_SEQ = 24; JN_TYPEOF = 25; JN_DELETE = 26;
  JN_VAR = 40; JN_EXPR = 41; JN_IF = 42; JN_FOR = 43; JN_FORIN = 44; JN_WHILE = 45; JN_DOWHILE = 46;
  JN_RETURN = 47; JN_BREAK = 48; JN_CONTINUE = 49; JN_BLOCK = 50; JN_THROW = 51; JN_TRY = 52; JN_SWITCH = 53;
  JN_CASE = 54; JN_EMPTY = 55; JN_FUNDECL = 56; JN_DECL = 57; JN_SPREAD = 58;
  { jetons }
  JT_EOF = 0; JT_NUM = 1; JT_STR = 2; JT_ID = 3; JT_PUNC = 4; JT_TPL = 5;
  { controle }
  JC_NONE = 0; JC_BREAK = 1; JC_CONT = 2; JC_RET = 3; JC_THROW = 4;
  JS_BUDGET = 3000000;           { operations par execution }
  JS_MAXDEPTH = 120;             { appels imbriques }
  JS_MAXTIMERS = 16;
  JS_CONLINES = 200;             { lignes de la console }
  { classes d'objets }
  JO_PLAIN = 0; JO_DATE = 1; JO_ERROR = 2; JO_DOCUMENT = 10; JO_CONSOLE = 11; JO_MATH = 12; JO_JSON = 13;
  JO_NAVIGATOR = 14; JO_LOCATION = 15; JO_SCREEN = 16; JO_HISTORY = 17; JO_WINDOW = 18; JO_STYLE = 20;
  JO_EVENT = 21; JO_OBJECTCTOR = 22; JO_ARRAYCTOR = 23; JO_STRINGCTOR = 24; JO_NUMBERCTOR = 25; JO_DATECTOR = 26;
  JO_STORAGE = 27; JO_CLASSLIST = 28; JO_PROMISE = 29;
  JS_STKMAX = 16384;             { pile des arguments (valeurs) }

Type
  PJN = ^TJN;
  TJN = Record
    T, Op : LongInt;
    A, B, C, D, Next : PJN;
    N : Double;
    P, L : LongInt;              { texte (identifiant, chaine) dans l'arene }
    Line : LongInt;
  End;

  TJV = Record
    K : LongInt;
    N : Double;
    P, L : LongInt;              { chaine : adresse, longueur ; objet, fonction, noeud : pointeur }
  End;

  PJProp = ^TJProp;
  TJProp = Record
    P, L : LongInt;              { nom }
    V : TJV;
    Flags : LongInt;             { 1 : constante }
    Next : PJProp;
  End;

  PJObj = ^TJObj;
  TJObj = Record
    Props : PJProp;
    IsArr : Boolean;
    Elems, Cap, Len : LongInt;   { tableau : TJV contigus dans l'arene }
    Cls : LongInt;               { JO_* : objet, Date, Error, objets du navigateur }
    Num : Double;                { Date : millisecondes }
    Node : PNode;                { style d'un element, evenement : cible }
  End;

  PJEnv = ^TJEnv;
  TJEnv = Record
    Vars : PJProp;
    Parent : PJEnv;
    IsFunc : Boolean;            { portee de fonction (ou globale) : recoit les var }
  End;

  PJFun = ^TJFun;
  TJFun = Record
    Params, Body : PJN;
    Env : PJEnv;
    Arrow, ExprBody : Boolean;
    NP, NL : LongInt;            { nom }
    ThisV : TJV;                 { fonction flechee : this capture }
  End;

Var
  { analyse }
  JsSrc, JsLen, JsPos, JsLine : LongInt;
  JTokT, JTokP, JTokL, JTokLine : LongInt;
  JTokN : Double;
  JTokNL : Boolean;              { saut de ligne avant le jeton (insertion de ;) }
  JTokS : String;                { ponctuation }
  JsErr : Boolean; JsErrMsg : String; JsErrLine : LongInt;
  { execution }
  JsCtl : LongInt; JsRet : TJV; JsLabel : LongInt;
  JsGlobal : PJEnv; JsWindow : PJObj;
  JsSteps, JsDepth : LongInt;
  JsThis : TJV;
  JsReady : Boolean;
  { liens avec le navigateur : traites par l'interface apres l'execution }
  JsDirty : Boolean;             { DOM modifie : nouvelle mise en page }
  JsNavUrl : String;             { window.location = ... }
  JsAlertN : LongInt; JsAlerts : Array[0..7] Of String;
  JsWriteP, JsWriteL : LongInt;  { document.write en attente }
  JsTitleSet : Boolean;
  { minuteurs : code (chaine) ou fonction }
  JsTmUsed : Array[0..JS_MAXTIMERS - 1] Of Boolean;
  JsTmAt, JsTmEvery, JsTmId : Array[0..JS_MAXTIMERS - 1] Of LongInt;
  JsTmFn : Array[0..JS_MAXTIMERS - 1] Of TJV;
  JsTmNext : LongInt;
  { console : lignes (texte, genre 0 journal, 1 erreur, 2 commande, 3 resultat, 4 avertissement) }
  JsConN, JsConFirst : LongInt;
  JsCon : Array[0..JS_CONLINES - 1] Of String;
  JsConKind : Array[0..JS_CONLINES - 1] Of Byte;
  JsConGen : LongInt;            { change a chaque ajout (rafraichir la console) }
  { debogueur : scripts executes et erreurs }
  JsScriptN, JsFuncN, JsErrCount : LongInt;
  JsLastErr : String;
  JsDocCookie : String;
  { pile des arguments : TJV contigus (DosAllocMem) }
  JsStk, JsSp : LongInt;
  { exception en cours (JC_THROW) ; JsKill : arret force (budget) }
  JsExc : TJV; JsKill : Boolean; JsAbortMsg : String;
  { etat de la page fourni par l'interface }
  JsPageUrl, JsPageTitle : String;
  JsViewW, JsViewH, JsScreenW, JsScreenH : LongInt;
  JsPrevent : Boolean;           { evenement : preventDefault() / return false }
  JsRescan : Boolean;            { elements ajoutes : controles et images a recenser }
  JsHistCmd : LongInt;           { history.back() : -1, forward() : 1 }

{ ---------------- valeurs ---------------- }

Procedure JvUndef(Var V : TJV);
Begin
  V.K := JV_UNDEF; V.N := 0; V.P := 0; V.L := 0;
End;

Procedure JvNum(Var V : TJV; N : Double);
Begin
  V.K := JV_NUM; V.N := N; V.P := 0; V.L := 0;
End;

Procedure JvBool(Var V : TJV; B : Boolean);
Begin
  V.K := JV_BOOL; If B Then V.N := 1 Else V.N := 0; V.P := 0; V.L := 0;
End;

Procedure JvStrAL(Var V : TJV; A, L : LongInt);
Begin
  V.K := JV_STR; V.N := 0; V.P := A; V.L := L;
End;

{ chaine Pascal -> valeur (copiee dans l'arene) }
Procedure JvStr(Var V : TJV; S : String);
Var A : LongInt;
Begin
  A := 0;
  If Length(S) > 0 Then
  Begin
    A := ArAlloc(Length(S));
    If A <> 0 Then MemCopy(LongInt(@S[1]), A, Length(S));
  End;
  If A = 0 Then JvStrAL(V, 0, 0) Else JvStrAL(V, A, Length(S));
End;

Procedure JvObjV(Var V : TJV; O : PJObj);
Begin
  V.K := JV_OBJ; V.N := 0; V.P := LongInt(O); V.L := 0;
End;

Procedure JvNode(Var V : TJV; N : PNode);
Begin
  If N = Nil Then
  Begin
    V.K := JV_NULL; V.N := 0; V.P := 0; V.L := 0;
  End
  Else
  Begin
    V.K := JV_NODE; V.N := 0; V.P := LongInt(N); V.L := 0;
  End;
End;

Procedure JvNat(Var V : TJV; Id, Recv : LongInt);
Begin
  V.K := JV_NAT; V.N := 0; V.P := Id; V.L := Recv;
End;

{ acces aux objets d'une valeur (sans transtypage suivi de ^, que OS2PC
  n'accepte pas) }
Function JvArr(Var V : TJV) : PJObj;
Var O : PJObj;
Begin
  JvArr := Nil;
  If V.K <> JV_OBJ Then Exit;
  O := Pointer(V.P);
  If O^.IsArr Then JvArr := O;
End;

Function JvLen(Var V : TJV) : LongInt;
Var O : PJObj;
Begin
  O := JvArr(V);
  If O = Nil Then JvLen := 0 Else JvLen := O^.Len;
End;

Function JvCls(Var V : TJV) : LongInt;
Var O : PJObj;
Begin
  JvCls := -1;
  If V.K <> JV_OBJ Then Exit;
  O := Pointer(V.P);
  JvCls := O^.Cls;
End;

{ chaine de l'arene -> String (255 au plus) }
Function JsStrOf(A, L : LongInt) : String;
Begin
  JsStrOf := ArGet(A, L);
End;

Function JsSame(A1, L1, A2, L2 : LongInt) : Boolean;
Var K : LongInt;
Begin
  JsSame := False;
  If L1 <> L2 Then Exit;
  For K := 0 To L1 - 1 Do
    If RdB(A1 + K) <> RdB(A2 + K) Then Exit;
  JsSame := True;
End;

Function JsSameS(A, L : LongInt; S : String) : Boolean;
Var K : LongInt;
Begin
  JsSameS := False;
  If L <> Length(S) Then Exit;
  For K := 1 To L Do
    If RdB(A + K - 1) <> Ord(S[K]) Then Exit;
  JsSameS := True;
End;

Procedure JsError(S : String);
Begin
  If JsErr Then Exit;
  JsErr := True;
  JsErrMsg := S;
  JsErrLine := JTokLine;
End;

{ concatenation de deux chaines de l'arene }
Procedure JsConcat(Var R : TJV; A1, L1, A2, L2 : LongInt);
Var A : LongInt;
Begin
  If L1 + L2 = 0 Then
  Begin
    JvStrAL(R, 0, 0);
    Exit;
  End;
  If L1 + L2 > 4000000 Then
  Begin
    JsError('RangeError: chaine trop longue');
    JvStrAL(R, 0, 0);
    Exit;
  End;
  A := ArAlloc(L1 + L2);
  If A = 0 Then
  Begin
    JsError('Erreur : memoire de la page epuisee');
    JvStrAL(R, 0, 0);
    Exit;
  End;
  MemCopy(A1, A, L1);
  MemCopy(A2, A + L1, L2);
  JvStrAL(R, A, L1 + L2);
End;

{ ---------------- nombres ---------------- }

Function JsIsNaN(D : Double) : Boolean;
Begin
  JsIsNaN := D <> D;
End;

Function JsNaN : Double;
Var Z : Double;
Begin
  Z := 0;
  JsNaN := Z / Z;
End;

Function JsInf : Double;
Var Z : Double;
Begin
  Z := 0;
  JsInf := 1 / Z;
End;

{ partie entiere d'un reel quelconque (Trunc ne depasse pas 2^31) }
Function JsFTrunc(D : Double) : Double;
Var Hi, G : Double;
Begin
  If JsIsNaN(D) Or (D = JsInf) Or (D = -JsInf) Then
  Begin
    JsFTrunc := D;
    Exit;
  End;
  If (D < 2000000000.0) And (D > -2000000000.0) Then JsFTrunc := Trunc(D)
  Else
  Begin
    G := 1000000000;
    Hi := JsFTrunc(D / G);
    JsFTrunc := Hi * G + Trunc(D - Hi * G);
  End;
End;

Const
  JsE9 : Double = 1000000000.0;   { constante Double (pas de calcul en simple precision) }
  JsTen : Double = 10.0;

{ entier positif (exact jusqu'a 2^53) -> chiffres }
Function JsIntStr(D : Double) : String;
Var S : String; Hi, Lo : Double; K : LongInt;
Begin
  If D < JsE9 Then
  Begin
    JsIntStr := IStr(Trunc(D));
    Exit;
  End;
  Hi := JsFTrunc(D / JsE9);
  Lo := D - Hi * JsE9;
  If Lo < 0 Then Lo := 0;
  K := Trunc(Lo);
  If K > 999999999 Then K := 999999999;
  S := IStr(K);
  While Length(S) < 9 Do S := '0' + S;
  JsIntStr := JsIntStr(Hi) + S;
End;

{ nombre -> texte : entier (jusqu'a 1E21), decimales (9 au plus), ou
  notation exponentielle }
Function JsNumStr(D : Double) : String;
Var S, F : String; Neg : Boolean; E, K : LongInt; Ip, R : Double;
Begin
  If JsIsNaN(D) Then
  Begin
    JsNumStr := 'NaN';
    Exit;
  End;
  If D = JsInf Then
  Begin
    JsNumStr := 'Infinity';
    Exit;
  End;
  If D = -JsInf Then
  Begin
    JsNumStr := '-Infinity';
    Exit;
  End;
  Neg := D < 0;
  If Neg Then D := -D;
  If D = 0 Then
  Begin
    JsNumStr := '0';
    Exit;
  End;
  If (D >= 1E21) Or (D < 1E-6) Then
  Begin
    E := 0;
    While D >= JsTen Do
    Begin
      D := D / JsTen; Inc(E);
    End;
    While D < 1 Do
    Begin
      D := D * JsTen; Dec(E);
    End;
    S := JsNumStr(D);
    If E >= 0 Then S := S + 'e+' + IStr(E) Else S := S + 'e-' + IStr(-E);
    If Neg Then S := '-' + S;
    JsNumStr := S;
    Exit;
  End;
  Ip := JsFTrunc(D);
  R := D - Ip;
  S := JsIntStr(Ip);
  { decimales (9 chiffres au plus, zeros de fin retires) ; pas de
    decimales au-dela de 2^53 (le reel n'en a plus) }
  If (R > 0) And (D < 9007199254740992.0) Then
  Begin
    K := Round(R * JsE9);
    If K >= 1000000000 Then
    Begin
      S := JsIntStr(Ip + 1);
      K := 0;
    End;
    If K > 0 Then
    Begin
      F := IStr(K);
      While Length(F) < 9 Do F := '0' + F;
      While (Length(F) > 0) And (F[Length(F)] = '0') Do Delete(F, Length(F), 1);
      If F <> '' Then S := S + '.' + F;
    End;
  End;
  If Neg Then S := '-' + S;
  JsNumStr := S;
End;

{ texte -> nombre (decimal, 0x, exposant, Infinity) ; NaN si invalide }
Function JsParseNum(A, L : LongInt; Strict : Boolean) : Double;
Var I, C, E, Es : LongInt; V, F, Sc : Double; Neg, Any : Boolean;
Begin
  I := 0;
  While (I < L) And (RdB(A + I) <= 32) Do Inc(I);
  While (L > I) And (RdB(A + L - 1) <= 32) Do Dec(L);
  If I >= L Then
  Begin
    If Strict Then JsParseNum := 0 Else JsParseNum := JsNaN;
    Exit;
  End;
  Neg := False;
  If (RdB(A + I) = 45) Or (RdB(A + I) = 43) Then
  Begin
    Neg := RdB(A + I) = 45;
    Inc(I);
  End;
  V := 0; Any := False;
  If (I + 1 < L) And (RdB(A + I) = 48) And ((RdB(A + I + 1) Or $20) = Ord('x')) Then
  Begin
    I := I + 2;
    While I < L Do
    Begin
      C := RdB(A + I);
      If Chr(C) In ['0'..'9'] Then V := V * 16 + (C - 48)
      Else If Chr(C Or $20) In ['a'..'f'] Then V := V * 16 + ((C Or $20) - 87)
      Else Break;
      Any := True;
      Inc(I);
    End;
  End
  Else If JsSameS(A + I, MinI(8, L - I), 'Infinity') Then
  Begin
    V := JsInf; Any := True; I := I + 8;
  End
  Else
  Begin
    While (I < L) And (Chr(RdB(A + I)) In ['0'..'9']) Do
    Begin
      V := V * 10 + (RdB(A + I) - 48);
      Any := True;
      Inc(I);
    End;
    If (I < L) And (RdB(A + I) = 46) Then
    Begin
      Inc(I);
      Sc := 0.1;
      While (I < L) And (Chr(RdB(A + I)) In ['0'..'9']) Do
      Begin
        V := V + (RdB(A + I) - 48) * Sc;
        Sc := Sc / 10;
        Any := True;
        Inc(I);
      End;
    End;
    If Any And (I < L) And ((RdB(A + I) Or $20) = Ord('e')) Then
    Begin
      Inc(I);
      Es := 1;
      If (I < L) And ((RdB(A + I) = 45) Or (RdB(A + I) = 43)) Then
      Begin
        If RdB(A + I) = 45 Then Es := -1;
        Inc(I);
      End;
      E := 0;
      While (I < L) And (Chr(RdB(A + I)) In ['0'..'9']) And (E < 400) Do
      Begin
        E := E * 10 + (RdB(A + I) - 48);
        Inc(I);
      End;
      F := 1;
      While E > 0 Do
      Begin
        F := F * 10; Dec(E);
      End;
      If Es > 0 Then V := V * F Else V := V / F;
    End;
  End;
  If (Not Any) Or (Strict And (I < L)) Then
  Begin
    JsParseNum := JsNaN;
    Exit;
  End;
  If Neg Then V := -V;
  JsParseNum := V;
End;

{ ---------------- objets ---------------- }

Function JsNewObj : PJObj;
Var O : PJObj;
Begin
  O := Pointer(ArAlloc(SizeOf(TJObj)));
  If O = Nil Then JsError('Erreur : memoire de la page epuisee');
  JsNewObj := O;
End;

Function JsNewArr : PJObj;
Var O : PJObj;
Begin
  O := JsNewObj;
  If O <> Nil Then O^.IsArr := True;
  JsNewArr := O;
End;

Function JsElem(O : PJObj; I : LongInt) : LongInt;
Begin
  JsElem := O^.Elems + I * SizeOf(TJV);
End;

Procedure JsArrSet(O : PJObj; I : LongInt; Var V : TJV);
Var NC, NA, K : LongInt; U : TJV; Pv : ^TJV;
Begin
  If (O = Nil) Or (I < 0) Then Exit;
  If I > 1000000 Then
  Begin
    JsError('RangeError: indice de tableau trop grand');
    Exit;
  End;
  If I >= O^.Cap Then
  Begin
    NC := MaxI(8, O^.Cap * 2);
    While NC <= I Do NC := NC * 2;
    NA := ArAlloc(NC * SizeOf(TJV));
    If NA = 0 Then
    Begin
      JsError('Erreur : memoire de la page epuisee');
      Exit;
    End;
    If O^.Len > 0 Then MemCopy(O^.Elems, NA, O^.Len * SizeOf(TJV));
    O^.Elems := NA; O^.Cap := NC;
  End;
  JvUndef(U);
  For K := O^.Len To I - 1 Do
  Begin
    Pv := Pointer(JsElem(O, K));
    Pv^ := U;
  End;
  Pv := Pointer(JsElem(O, I));
  Pv^ := V;
  If I >= O^.Len Then O^.Len := I + 1;
End;

Procedure JsArrGet(O : PJObj; I : LongInt; Var V : TJV);
Var Pv : ^TJV;
Begin
  If (O = Nil) Or (I < 0) Or (I >= O^.Len) Then
  Begin
    JvUndef(V);
    Exit;
  End;
  Pv := Pointer(JsElem(O, I));
  V := Pv^;
End;

Procedure JsArrPush(O : PJObj; Var V : TJV);
Begin
  If O <> Nil Then JsArrSet(O, O^.Len, V);
End;

Function JsFindProp(O : PJObj; A, L : LongInt) : PJProp;
Var P : PJProp;
Begin
  JsFindProp := Nil;
  If O = Nil Then Exit;
  P := O^.Props;
  While P <> Nil Do
  Begin
    If JsSame(P^.P, P^.L, A, L) Then
    Begin
      JsFindProp := P;
      Exit;
    End;
    P := P^.Next;
  End;
End;

Procedure JsSetPropAL(O : PJObj; A, L : LongInt; Var V : TJV);
Var P, Q : PJProp;
Begin
  If O = Nil Then Exit;
  P := JsFindProp(O, A, L);
  If P = Nil Then
  Begin
    P := Pointer(ArAlloc(SizeOf(TJProp)));
    If P = Nil Then
    Begin
      JsError('Erreur : memoire de la page epuisee');
      Exit;
    End;
    P^.P := A; P^.L := L;
    { ajout en fin : l'ordre d'insertion est conserve (for..in) }
    If O^.Props = Nil Then O^.Props := P
    Else
    Begin
      Q := O^.Props;
      While Q^.Next <> Nil Do Q := Q^.Next;
      Q^.Next := P;
    End;
  End;
  P^.V := V;
End;

Procedure JsSetPropS(O : PJObj; S : String; Var V : TJV);
Var T : TJV;
Begin
  JvStr(T, S);
  JsSetPropAL(O, T.P, T.L, V);
End;

{ ---------------- console ---------------- }

Procedure JsConsole(S : String; Kind : LongInt);
Var K : LongInt;
Begin
  If JsConN < JS_CONLINES Then
  Begin
    K := (JsConFirst + JsConN) Mod JS_CONLINES;
    Inc(JsConN);
  End
  Else
  Begin
    K := JsConFirst;
    JsConFirst := (JsConFirst + 1) Mod JS_CONLINES;
  End;
  JsCon[K] := S;
  JsConKind[K] := Kind;
  Inc(JsConGen);
  Trace('console ' + IStr(Kind) + ' : ' + Copy(S, 1, 150));
End;

Function JsConLine(I : LongInt) : String;
Begin
  JsConLine := JsCon[(JsConFirst + I) Mod JS_CONLINES];
End;

Function JsConKindOf(I : LongInt) : LongInt;
Begin
  JsConKindOf := JsConKind[(JsConFirst + I) Mod JS_CONLINES];
End;

{ ---------------- analyse lexicale ---------------- }

Function JsCh(I : LongInt) : LongInt;
Begin
  If (I >= 0) And (I < JsLen) Then JsCh := RdB(JsSrc + I) Else JsCh := 0;
End;

Function JIsIdStart(C : LongInt) : Boolean;
Begin
  JIsIdStart := (Chr(C Or $20) In ['a'..'z']) Or (C = 95) Or (C = 36) Or (C >= 128);
End;

Function JIsIdChar(C : LongInt) : Boolean;
Begin
  JIsIdChar := JIsIdStart(C) Or (Chr(C) In ['0'..'9']);
End;

{ chaine litterale (guillemets, apostrophes, `modele` sans substitution) : texte
  decode dans l'arene ; les \uXXXX deviennent des caracteres 437 }
Procedure JLexString(Q : LongInt);
Var S, D, C, U, K, N : LongInt;
Begin
  S := JsPos + 1;
  { longueur maximale : celle du texte source }
  K := S;
  While (K < JsLen) And (JsCh(K) <> Q) Do
  Begin
    If JsCh(K) = 92 Then Inc(K);
    If (JsCh(K) = 10) And (Q <> 96) Then Break;
    Inc(K);
  End;
  D := ArAlloc(K - S + 1);
  If D = 0 Then
  Begin
    JsError('Erreur : memoire de la page epuisee');
    Exit;
  End;
  N := 0;
  K := S;
  While (K < JsLen) And (JsCh(K) <> Q) Do
  Begin
    C := JsCh(K);
    If (C = 10) And (Q <> 96) Then Break;
    If C = 10 Then Inc(JsLine);
    If C = 92 Then
    Begin
      Inc(K);
      C := JsCh(K);
      Case C Of
        110 : C := 10;
        114 : C := 13;
        116 : C := 9;
        98 : C := 8;
        102 : C := 12;
        118 : C := 11;
        48 : C := 0;
        10 : C := -1;           { continuation de ligne }
        117, 120 :
          Begin
            { \uXXXX, \u(accolade)X..., \xXX }
            If C = 120 Then U := 2 Else U := 4;
            C := 0;
            If JsCh(K + 1) = 123 Then
            Begin
              Inc(K);
              While (K + 1 < JsLen) And (JsCh(K + 1) <> 125) Do
              Begin
                Inc(K);
                C := C * 16 + HexDigit(Chr(JsCh(K)));
              End;
              Inc(K);
            End
            Else
              While (U > 0) And (K + 1 < JsLen) Do
              Begin
                Inc(K);
                C := C * 16 + HexDigit(Chr(JsCh(K)));
                Dec(U);
              End;
            C := UniToCp(C);
          End;
      End;
    End;
    If C >= 0 Then
    Begin
      WrB(D + N, C And 255);
      Inc(N);
    End;
    Inc(K);
  End;
  If JsCh(K) <> Q Then JsError('SyntaxError: chaine non terminee');
  JTokT := JT_STR; JTokP := D; JTokL := N;
  JsPos := K + 1;
End;

Procedure JNext;
Var C, C2, C3, S : LongInt; P : String;
Begin
  JTokNL := False;
  { blancs et commentaires }
  While JsPos < JsLen Do
  Begin
    C := JsCh(JsPos);
    If C = 10 Then
    Begin
      JTokNL := True; Inc(JsLine); Inc(JsPos);
    End
    Else If C <= 32 Then Inc(JsPos)
    Else If (C = 47) And (JsCh(JsPos + 1) = 47) Then
    Begin
      While (JsPos < JsLen) And (JsCh(JsPos) <> 10) Do Inc(JsPos);
    End
    Else If (C = 47) And (JsCh(JsPos + 1) = 42) Then
    Begin
      JsPos := JsPos + 2;
      While (JsPos < JsLen) And Not ((JsCh(JsPos) = 42) And (JsCh(JsPos + 1) = 47)) Do
      Begin
        If JsCh(JsPos) = 10 Then
        Begin
          JTokNL := True; Inc(JsLine);
        End;
        Inc(JsPos);
      End;
      JsPos := JsPos + 2;
    End
    Else If (C = 60) And (JsCh(JsPos + 1) = 33) And (JsCh(JsPos + 2) = 45) And (JsCh(JsPos + 3) = 45) Then
    Begin
      { <!-- au debut des vieux scripts : commentaire de ligne }
      While (JsPos < JsLen) And (JsCh(JsPos) <> 10) Do Inc(JsPos);
    End
    Else If (C = 45) And (JsCh(JsPos + 1) = 45) And (JsCh(JsPos + 2) = 62) Then
    Begin
      While (JsPos < JsLen) And (JsCh(JsPos) <> 10) Do Inc(JsPos);
    End
    Else Break;
  End;
  JTokLine := JsLine;
  If JsPos >= JsLen Then
  Begin
    JTokT := JT_EOF; JTokS := '';
    Exit;
  End;
  C := JsCh(JsPos);
  If JIsIdStart(C) Then
  Begin
    S := JsPos;
    While (JsPos < JsLen) And JIsIdChar(JsCh(JsPos)) Do Inc(JsPos);
    JTokT := JT_ID; JTokP := JsSrc + S; JTokL := JsPos - S;
    JTokS := '';
    Exit;
  End;
  If (Chr(C) In ['0'..'9']) Or ((C = 46) And (Chr(JsCh(JsPos + 1)) In ['0'..'9'])) Then
  Begin
    S := JsPos;
    If (C = 48) And ((JsCh(JsPos + 1) Or $20) = Ord('x')) Then
    Begin
      JsPos := JsPos + 2;
      While (JsPos < JsLen) And (Chr(JsCh(JsPos) Or $20) In ['0'..'9', 'a'..'f']) Do Inc(JsPos);
    End
    Else
    Begin
      While (JsPos < JsLen) And (Chr(JsCh(JsPos)) In ['0'..'9', '.']) Do Inc(JsPos);
      If (JsCh(JsPos) Or $20) = Ord('e') Then
      Begin
        Inc(JsPos);
        If (JsCh(JsPos) = 43) Or (JsCh(JsPos) = 45) Then Inc(JsPos);
        While (JsPos < JsLen) And (Chr(JsCh(JsPos)) In ['0'..'9']) Do Inc(JsPos);
      End;
    End;
    JTokT := JT_NUM;
    JTokN := JsParseNum(JsSrc + S, JsPos - S, True);
    JTokS := '';
    Exit;
  End;
  If (C = 34) Or (C = 39) Or (C = 96) Then
  Begin
    JLexString(C);
    JTokS := '';
    Exit;
  End;
  { ponctuation : la plus longue d'abord }
  C2 := JsCh(JsPos + 1); C3 := JsCh(JsPos + 2);
  P := Chr(C);
  If (C = 62) And (C2 = 62) And (C3 = 62) And (JsCh(JsPos + 3) = 61) Then P := '>>>='
  Else If ((C = 61) Or (C = 33)) And (C2 = 61) And (C3 = 61) Then P := Chr(C) + '=='
  Else If (C = 62) And (C2 = 62) And (C3 = 62) Then P := '>>>'
  Else If ((C = 60) And (C2 = 60) And (C3 = 61)) Or ((C = 62) And (C2 = 62) And (C3 = 61)) Then P := Chr(C) + Chr(C2) + '='
  Else If (C = 46) And (C2 = 46) And (C3 = 46) Then P := '...'
  Else If (C = 42) And (C2 = 42) And (C3 = 61) Then P := '**='
  Else If (C2 = 61) And (Chr(C) In ['=', '!', '<', '>', '+', '-', '*', '/', '%', '&', '|', '^']) Then P := Chr(C) + '='
  Else If ((C = 38) And (C2 = 38)) Or ((C = 124) And (C2 = 124)) Or ((C = 43) And (C2 = 43)) Or
          ((C = 45) And (C2 = 45)) Or ((C = 60) And (C2 = 60)) Or ((C = 62) And (C2 = 62)) Or
          ((C = 61) And (C2 = 62)) Or ((C = 63) And (C2 = 63)) Or ((C = 42) And (C2 = 42)) Or
          ((C = 63) And (C2 = 46) And Not (Chr(C3) In ['0'..'9'])) Then P := Chr(C) + Chr(C2);
  JsPos := JsPos + Length(P);
  JTokT := JT_PUNC; JTokS := P;
End;

Function JIs(S : String) : Boolean;
Begin
  JIs := (JTokT = JT_PUNC) And (JTokS = S);
End;

Function JIsKw(S : String) : Boolean;
Begin
  JIsKw := (JTokT = JT_ID) And JsSameS(JTokP, JTokL, S);
End;

Procedure JExpect(S : String);
Begin
  If JIs(S) Then JNext
  Else JsError('SyntaxError: "' + S + '" attendu');
End;

{ point-virgule, ou insertion automatique }
Procedure JSemi;
Begin
  If JIs(';') Then JNext
  Else If JIs('}') Or (JTokT = JT_EOF) Or JTokNL Then
  Else JsError('SyntaxError: ";" attendu');
End;

{ ---------------- analyse syntaxique (arbre dans l'arene) ---------------- }

Function JNode(T : LongInt) : PJN;
Var N : PJN;
Begin
  N := Pointer(ArAlloc(SizeOf(TJN)));
  If N = Nil Then JsError('Erreur : memoire de la page epuisee')
  Else
  Begin
    N^.T := T;
    N^.Line := JTokLine;
  End;
  JNode := N;
End;

Function JParseExpr : PJN; Forward;
Function JParseAssign : PJN; Forward;
Function JParseStatement : PJN; Forward;
Function JParseFunction(IsDecl : Boolean) : PJN; Forward;

{ liste de parametres "(a, b, c)" ; les valeurs par defaut et ...reste
  sont acceptees (valeur par defaut dans B, reste : Op = 1) }
Function JParseParams : PJN;
Var First, Last, P : PJN;
Begin
  First := Nil; Last := Nil;
  JExpect('(');
  While Not JIs(')') And (JTokT <> JT_EOF) And Not JsErr Do
  Begin
    P := JNode(JN_IDENT);
    If P = Nil Then Break;
    If JIs('...') Then
    Begin
      P^.Op := 1;
      JNext;
    End;
    If JTokT <> JT_ID Then
    Begin
      JsError('SyntaxError: nom de parametre attendu');
      Break;
    End;
    P^.P := JTokP; P^.L := JTokL;
    JNext;
    If JIs('=') Then
    Begin
      JNext;
      P^.B := JParseAssign;
    End;
    If First = Nil Then First := P Else Last^.Next := P;
    Last := P;
    If JIs(',') Then JNext Else Break;
  End;
  JExpect(')');
  JParseParams := First;
End;

{ corps entre accolades : suite d'instructions (JN_BLOCK) }
Function JParseBlock : PJN;
Var B, Last, S : PJN;
Begin
  B := JNode(JN_BLOCK);
  JExpect('{');
  Last := Nil;
  While Not JIs('}') And (JTokT <> JT_EOF) And Not JsErr Do
  Begin
    S := JParseStatement;
    If S = Nil Then Break;
    If B <> Nil Then
    Begin
      If Last = Nil Then B^.A := S Else Last^.Next := S;
      Last := S;
      { portee propre seulement si le bloc declare let, const ou function }
      If (S^.T = JN_FUNDECL) Or ((S^.T = JN_VAR) And (S^.Op <> 0)) Then B^.Op := 1;
    End;
  End;
  JExpect('}');
  JParseBlock := B;
End;

{ function [nom](params) puis le corps entre accolades }
Function JParseFunction(IsDecl : Boolean) : PJN;
Var F : PJN;
Begin
  If IsDecl Then F := JNode(JN_FUNDECL) Else F := JNode(JN_FUNC);
  JNext;                                   { "function" }
  If JIs('*') Then JNext;                  { generateur : traite comme une fonction }
  If F = Nil Then
  Begin
    JParseFunction := Nil;
    Exit;
  End;
  If JTokT = JT_ID Then
  Begin
    F^.P := JTokP; F^.L := JTokL;
    JNext;
  End
  Else If IsDecl Then JsError('SyntaxError: nom de fonction attendu');
  F^.A := JParseParams;
  F^.B := JParseBlock;
  Inc(JsFuncN);
  JParseFunction := F;
End;

{ fonction flechee a partir de la liste de parametres deja lue }
Function JParseArrowBody(Params : PJN) : PJN;
Var F : PJN;
Begin
  F := JNode(JN_FUNC);
  If F = Nil Then
  Begin
    JParseArrowBody := Nil;
    Exit;
  End;
  F^.Op := 1;                              { flechee }
  F^.A := Params;
  If JIs('{') Then F^.B := JParseBlock
  Else
  Begin
    F^.C := JParseAssign;                  { corps expression }
    F^.Op := 2;
  End;
  Inc(JsFuncN);
  JParseArrowBody := F;
End;

{ "(" deja vu : fonction flechee "(a, b) =>" ou expression entre parentheses }
Function JTryArrow : PJN;
Var K, Dep, C : LongInt; Params : PJN;
Begin
  JTryArrow := Nil;
  { "(" est le jeton courant : recherche de la parenthese fermante (en
    sautant les chaines) puis de "=>", sans analyser }
  K := JsPos; Dep := 1;
  While (K < JsLen) And (Dep > 0) Do
  Begin
    C := JsCh(K);
    If (C = 34) Or (C = 39) Or (C = 96) Then
    Begin
      Inc(K);
      While (K < JsLen) And (JsCh(K) <> C) Do
      Begin
        If JsCh(K) = 92 Then Inc(K);
        Inc(K);
      End;
    End
    Else If C = 40 Then Inc(Dep)
    Else If C = 41 Then Dec(Dep);
    Inc(K);
  End;
  While (K < JsLen) And (JsCh(K) <= 32) Do Inc(K);
  If Not ((JsCh(K) = 61) And (JsCh(K + 1) = 62)) Then Exit;
  Params := JParseParams;
  If JIs('=>') Then JNext Else JsError('SyntaxError: "=>" attendu');
  JTryArrow := JParseArrowBody(Params);
End;

Function JParsePrimary : PJN;
Var N, Last, E, Pn : PJN;
Begin
  N := Nil;
  If JsErr Then
  Begin
    JParsePrimary := Nil;
    Exit;
  End;
  Case JTokT Of
    JT_NUM :
      Begin
        N := JNode(JN_NUM);
        If N <> Nil Then N^.N := JTokN;
        JNext;
      End;
    JT_STR :
      Begin
        N := JNode(JN_STR);
        If N <> Nil Then
        Begin
          N^.P := JTokP; N^.L := JTokL;
        End;
        JNext;
      End;
    JT_ID :
      Begin
        If JIsKw('function') Then N := JParseFunction(False)
        Else If JIsKw('true') Then
        Begin
          N := JNode(JN_TRUE); JNext;
        End
        Else If JIsKw('false') Then
        Begin
          N := JNode(JN_FALSE); JNext;
        End
        Else If JIsKw('null') Then
        Begin
          N := JNode(JN_NULL); JNext;
        End
        Else If JIsKw('undefined') Then
        Begin
          N := JNode(JN_UNDEF); JNext;
        End
        Else If JIsKw('this') Then
        Begin
          N := JNode(JN_THIS); JNext;
        End
        Else
        Begin
          N := JNode(JN_IDENT);
          If N <> Nil Then
          Begin
            N^.P := JTokP; N^.L := JTokL;
          End;
          JNext;
          { x => ... }
          If JIs('=>') And (N <> Nil) Then
          Begin
            JNext;
            N := JParseArrowBody(N);
          End;
        End;
      End;
    JT_PUNC :
      If JIs('(') Then
      Begin
        N := JTryArrow;
        If (N = Nil) And Not JsErr Then
        Begin
          JNext;
          N := JParseExpr;
          JExpect(')');
        End;
      End
      Else If JIs('[') Then
      Begin
        N := JNode(JN_ARRAY);
        JNext;
        Last := Nil;
        While Not JIs(']') And (JTokT <> JT_EOF) And Not JsErr Do
        Begin
          If JIs(',') Then E := JNode(JN_UNDEF)
          Else If JIs('...') Then
          Begin
            JNext;
            E := JNode(JN_SPREAD);
            If E <> Nil Then E^.A := JParseAssign;
          End
          Else E := JParseAssign;
          If (N <> Nil) And (E <> Nil) Then
          Begin
            If Last = Nil Then N^.A := E Else Last^.Next := E;
            Last := E;
          End;
          If JIs(',') Then JNext Else Break;
        End;
        JExpect(']');
      End
      Else If JIs('{') Then
      Begin
        N := JNode(JN_OBJECT);
        JNext;
        Last := Nil;
        While Not JIs('}') And (JTokT <> JT_EOF) And Not JsErr Do
        Begin
          Pn := JNode(JN_PROP);
          If Pn = Nil Then Break;
          If (JTokT = JT_ID) Or (JTokT = JT_STR) Then
          Begin
            Pn^.P := JTokP; Pn^.L := JTokL;
          End
          Else If JTokT = JT_NUM Then
          Begin
            E := JNode(JN_STR);
            JvStr(JsRet, JsNumStr(JTokN));
            Pn^.P := JsRet.P; Pn^.L := JsRet.L;
          End
          Else
          Begin
            JsError('SyntaxError: nom de propriete attendu');
            Break;
          End;
          JNext;
          If JIs(':') Then
          Begin
            JNext;
            Pn^.A := JParseAssign;
          End
          Else If JIs('(') Then
          Begin
            { methode abregee "nom(params)" suivie du corps }
            E := JNode(JN_FUNC);
            If E <> Nil Then
            Begin
              E^.P := Pn^.P; E^.L := Pn^.L;
              E^.A := JParseParams;
              E^.B := JParseBlock;
            End;
            Pn^.A := E;
          End
          Else
          Begin
            { forme abregee : objet "a, b" (variables du meme nom) }
            E := JNode(JN_IDENT);
            If E <> Nil Then
            Begin
              E^.P := Pn^.P; E^.L := Pn^.L;
            End;
            Pn^.A := E;
          End;
          If N <> Nil Then
          Begin
            If Last = Nil Then N^.A := Pn Else Last^.Next := Pn;
            Last := Pn;
          End;
          If JIs(',') Then JNext Else Break;
        End;
        JExpect('}');
      End
      Else JsError('SyntaxError: jeton inattendu "' + JTokS + '"');
  Else
    JsError('SyntaxError: fin du script inattendue');
  End;
  JParsePrimary := N;
End;

{ arguments d'appel "(a, b)" -> liste }
Function JParseArgs : PJN;
Var First, Last, E : PJN;
Begin
  First := Nil; Last := Nil;
  JExpect('(');
  While Not JIs(')') And (JTokT <> JT_EOF) And Not JsErr Do
  Begin
    If JIs('...') Then
    Begin
      JNext;
      E := JNode(JN_SPREAD);
      If E <> Nil Then E^.A := JParseAssign;
    End
    Else E := JParseAssign;
    If E = Nil Then Break;
    If First = Nil Then First := E Else Last^.Next := E;
    Last := E;
    If JIs(',') Then JNext Else Break;
  End;
  JExpect(')');
  JParseArgs := First;
End;

Function JParsePostfixChain(N : PJN) : PJN;
Var M : PJN;
Begin
  While Not JsErr Do
  Begin
    If JIs('.') Or JIs('?.') Then
    Begin
      JNext;
      M := JNode(JN_MEMBER);
      If M = Nil Then Break;
      M^.A := N;
      If JTokT <> JT_ID Then
      Begin
        JsError('SyntaxError: nom de propriete attendu');
        Break;
      End;
      M^.P := JTokP; M^.L := JTokL;
      JNext;
      N := M;
    End
    Else If JIs('[') Then
    Begin
      JNext;
      M := JNode(JN_INDEX);
      If M = Nil Then Break;
      M^.A := N;
      M^.B := JParseExpr;
      JExpect(']');
      N := M;
    End
    Else If JIs('(') Then
    Begin
      M := JNode(JN_CALL);
      If M = Nil Then Break;
      M^.A := N;
      M^.B := JParseArgs;
      N := M;
    End
    Else Break;
  End;
  JParsePostfixChain := N;
End;

Function JParseUnary : PJN; Forward;

Function JParseNew : PJN;
Var N, C : PJN;
Begin
  JNext;                                   { "new" }
  N := JNode(JN_NEW);
  C := JParsePrimary;
  { membres sans appel : new a.b.C(...) }
  While (C <> Nil) And JIs('.') And Not JsErr Do
  Begin
    JNext;
    If N = Nil Then Break;
    If JTokT <> JT_ID Then Break;
    N^.D := JNode(JN_MEMBER);
    N^.D^.A := C; N^.D^.P := JTokP; N^.D^.L := JTokL;
    C := N^.D;
    JNext;
  End;
  If N <> Nil Then
  Begin
    N^.A := C;
    If JIs('(') Then N^.B := JParseArgs;
  End;
  JParseNew := JParsePostfixChain(N);
End;

Function JParsePostfix : PJN;
Var N, M : PJN;
Begin
  If JIsKw('new') Then N := JParseNew
  Else N := JParsePostfixChain(JParsePrimary);
  If (JIs('++') Or JIs('--')) And Not JTokNL Then
  Begin
    M := JNode(JN_POSTINC);
    If M <> Nil Then
    Begin
      M^.A := N;
      If JIs('++') Then M^.Op := 1 Else M^.Op := -1;
    End;
    JNext;
    N := M;
  End;
  JParsePostfix := N;
End;

Function JParseUnary : PJN;
Var N : PJN; Op : String;
Begin
  If JIs('!') Or JIs('-') Or JIs('+') Or JIs('~') Then
  Begin
    Op := JTokS;
    JNext;
    N := JNode(JN_UNARY);
    If N <> Nil Then
    Begin
      N^.Op := Ord(Op[1]);
      N^.A := JParseUnary;
    End;
  End
  Else If JIs('++') Or JIs('--') Then
  Begin
    N := JNode(JN_PREINC);
    If N <> Nil Then
      If JIs('++') Then N^.Op := 1 Else N^.Op := -1;
    JNext;
    If N <> Nil Then N^.A := JParseUnary;
  End
  Else If JIsKw('typeof') Then
  Begin
    JNext;
    N := JNode(JN_TYPEOF);
    If N <> Nil Then N^.A := JParseUnary;
  End
  Else If JIsKw('void') Then
  Begin
    JNext;
    N := JNode(JN_UNARY);
    If N <> Nil Then
    Begin
      N^.Op := Ord('v');
      N^.A := JParseUnary;
    End;
  End
  Else If JIsKw('delete') Then
  Begin
    JNext;
    N := JNode(JN_DELETE);
    If N <> Nil Then N^.A := JParseUnary;
  End
  Else N := JParsePostfix;
  JParseUnary := N;
End;

{ priorite des operateurs binaires (0 : pas un operateur binaire) }
Function JBinPrec : LongInt;
Var S : String;
Begin
  JBinPrec := 0;
  If JTokT = JT_ID Then
  Begin
    If JIsKw('instanceof') Or JIsKw('in') Then JBinPrec := 7;
    Exit;
  End;
  If JTokT <> JT_PUNC Then Exit;
  S := JTokS;
  If S = '??' Then JBinPrec := 1
  Else If S = '||' Then JBinPrec := 1
  Else If S = '&&' Then JBinPrec := 2
  Else If S = '|' Then JBinPrec := 3
  Else If S = '^' Then JBinPrec := 4
  Else If S = '&' Then JBinPrec := 5
  Else If (S = '==') Or (S = '!=') Or (S = '===') Or (S = '!==') Then JBinPrec := 6
  Else If (S = '<') Or (S = '>') Or (S = '<=') Or (S = '>=') Then JBinPrec := 7
  Else If (S = '<<') Or (S = '>>') Or (S = '>>>') Then JBinPrec := 8
  Else If (S = '+') Or (S = '-') Then JBinPrec := 9
  Else If (S = '*') Or (S = '/') Or (S = '%') Then JBinPrec := 10
  Else If S = '**' Then JBinPrec := 11;
End;

{ code d'operateur : 1..n }
Function JOpCode(S : String) : LongInt;
Begin
  If S = '+' Then JOpCode := 1 Else If S = '-' Then JOpCode := 2 Else If S = '*' Then JOpCode := 3
  Else If S = '/' Then JOpCode := 4 Else If S = '%' Then JOpCode := 5 Else If S = '<' Then JOpCode := 6
  Else If S = '>' Then JOpCode := 7 Else If S = '<=' Then JOpCode := 8 Else If S = '>=' Then JOpCode := 9
  Else If S = '==' Then JOpCode := 10 Else If S = '!=' Then JOpCode := 11 Else If S = '===' Then JOpCode := 12
  Else If S = '!==' Then JOpCode := 13 Else If S = '&' Then JOpCode := 14 Else If S = '|' Then JOpCode := 15
  Else If S = '^' Then JOpCode := 16 Else If S = '<<' Then JOpCode := 17 Else If S = '>>' Then JOpCode := 18
  Else If S = '>>>' Then JOpCode := 19 Else If S = '**' Then JOpCode := 20 Else If S = 'instanceof' Then JOpCode := 21
  Else If S = 'in' Then JOpCode := 22 Else If S = '&&' Then JOpCode := 30 Else If S = '||' Then JOpCode := 31
  Else If S = '??' Then JOpCode := 32 Else JOpCode := 0;
End;

Function JParseBinary(MinPrec : LongInt) : PJN;
Var L, R, N : PJN; P, Op : LongInt; S : String;
Begin
  L := JParseUnary;
  While Not JsErr Do
  Begin
    P := JBinPrec;
    If (P = 0) Or (P < MinPrec) Then Break;
    If JTokT = JT_ID Then S := JsStrOf(JTokP, JTokL) Else S := JTokS;
    Op := JOpCode(S);
    JNext;
    If Op = 20 Then R := JParseBinary(P) Else R := JParseBinary(P + 1);
    If Op >= 30 Then N := JNode(JN_LOGIC) Else N := JNode(JN_BINARY);
    If N = Nil Then Break;
    N^.Op := Op; N^.A := L; N^.B := R;
    L := N;
  End;
  JParseBinary := L;
End;

Function JParseCond : PJN;
Var C, N : PJN;
Begin
  C := JParseBinary(1);
  If JIs('?') And Not JsErr Then
  Begin
    JNext;
    N := JNode(JN_COND);
    If N <> Nil Then
    Begin
      N^.A := C;
      N^.B := JParseAssign;
      JExpect(':');
      N^.C := JParseAssign;
    End;
    C := N;
  End;
  JParseCond := C;
End;

Function JParseAssign : PJN;
Var L, N : PJN; S : String;
Begin
  L := JParseCond;
  If (JTokT = JT_PUNC) And Not JsErr Then
  Begin
    S := JTokS;
    If (S = '=') Or (S = '+=') Or (S = '-=') Or (S = '*=') Or (S = '/=') Or (S = '%=') Or (S = '&=') Or
       (S = '|=') Or (S = '^=') Or (S = '<<=') Or (S = '>>=') Or (S = '>>>=') Or (S = '**=') Then
    Begin
      If (L = Nil) Or Not (L^.T In [JN_IDENT, JN_MEMBER, JN_INDEX]) Then
      Begin
        JsError('SyntaxError: affectation invalide');
        JParseAssign := L;
        Exit;
      End;
      JNext;
      N := JNode(JN_ASSIGN);
      If N <> Nil Then
      Begin
        N^.A := L;
        If S = '=' Then N^.Op := 0 Else N^.Op := JOpCode(Copy(S, 1, Length(S) - 1));
        N^.B := JParseAssign;
      End;
      L := N;
    End;
  End;
  JParseAssign := L;
End;

Function JParseExpr : PJN;
Var L, N : PJN;
Begin
  L := JParseAssign;
  While JIs(',') And Not JsErr Do
  Begin
    JNext;
    N := JNode(JN_SEQ);
    If N = Nil Then Break;
    N^.A := L;
    N^.B := JParseAssign;
    L := N;
  End;
  JParseExpr := L;
End;

{ var/let/const a = 1, b ; Op : 0 var, 1 let, 2 const }
Function JParseVarDecl(InFor : Boolean) : PJN;
Var V, D, Last : PJN; Kind : LongInt;
Begin
  If JIsKw('const') Then Kind := 2 Else If JIsKw('let') Then Kind := 1 Else Kind := 0;
  JNext;
  V := JNode(JN_VAR);
  If V <> Nil Then V^.Op := Kind;
  Last := Nil;
  While Not JsErr Do
  Begin
    If JTokT <> JT_ID Then
    Begin
      JsError('SyntaxError: nom de variable attendu');
      Break;
    End;
    D := JNode(JN_DECL);
    If D = Nil Then Break;
    D^.P := JTokP; D^.L := JTokL;
    JNext;
    If JIs('=') Then
    Begin
      JNext;
      D^.A := JParseAssign;
    End;
    If V <> Nil Then
    Begin
      If Last = Nil Then V^.A := D Else Last^.Next := D;
      Last := D;
    End;
    If JIs(',') Then JNext Else Break;
  End;
  JParseVarDecl := V;
End;

Function JParseStatement : PJN;
Var N, E, Last, C : PJN;
Begin
  N := Nil;
  If JsErr Then
  Begin
    JParseStatement := Nil;
    Exit;
  End;
  Inc(JsSteps);
  If JIs('{') Then N := JParseBlock
  Else If JIs(';') Then
  Begin
    N := JNode(JN_EMPTY);
    JNext;
  End
  Else If JIsKw('var') Or JIsKw('let') Or JIsKw('const') Then
  Begin
    N := JParseVarDecl(False);
    JSemi;
  End
  Else If JIsKw('function') Then N := JParseFunction(True)
  Else If JIsKw('if') Then
  Begin
    JNext;
    N := JNode(JN_IF);
    JExpect('(');
    If N <> Nil Then N^.A := JParseExpr;
    JExpect(')');
    If N <> Nil Then N^.B := JParseStatement;
    If JIsKw('else') Then
    Begin
      JNext;
      If N <> Nil Then N^.C := JParseStatement;
    End;
  End
  Else If JIsKw('while') Then
  Begin
    JNext;
    N := JNode(JN_WHILE);
    JExpect('(');
    If N <> Nil Then N^.A := JParseExpr;
    JExpect(')');
    If N <> Nil Then N^.B := JParseStatement;
  End
  Else If JIsKw('do') Then
  Begin
    JNext;
    N := JNode(JN_DOWHILE);
    If N <> Nil Then N^.B := JParseStatement;
    If JIsKw('while') Then JNext Else JsError('SyntaxError: "while" attendu');
    JExpect('(');
    If N <> Nil Then N^.A := JParseExpr;
    JExpect(')');
    If JIs(';') Then JNext;
  End
  Else If JIsKw('for') Then
  Begin
    JNext;
    JExpect('(');
    E := Nil;
    If JIsKw('var') Or JIsKw('let') Or JIsKw('const') Then E := JParseVarDecl(True)
    Else If Not JIs(';') Then E := JParseExpr;
    If JIsKw('in') Or JIsKw('of') Then
    Begin
      N := JNode(JN_FORIN);
      If N <> Nil Then
      Begin
        If JIsKw('of') Then N^.Op := 1;
        N^.A := E;
      End;
      JNext;
      If N <> Nil Then N^.B := JParseExpr;
      JExpect(')');
      If N <> Nil Then N^.C := JParseStatement;
    End
    Else
    Begin
      N := JNode(JN_FOR);
      If N <> Nil Then N^.A := E;
      JExpect(';');
      If (N <> Nil) And Not JIs(';') Then N^.B := JParseExpr;
      JExpect(';');
      If (N <> Nil) And Not JIs(')') Then N^.C := JParseExpr;
      JExpect(')');
      If N <> Nil Then N^.D := JParseStatement;
    End;
  End
  Else If JIsKw('return') Then
  Begin
    JNext;
    N := JNode(JN_RETURN);
    If Not JIs(';') And Not JIs('}') And (JTokT <> JT_EOF) And Not JTokNL Then
      If N <> Nil Then N^.A := JParseExpr;
    JSemi;
  End
  Else If JIsKw('break') Or JIsKw('continue') Then
  Begin
    If JIsKw('break') Then N := JNode(JN_BREAK) Else N := JNode(JN_CONTINUE);
    JNext;
    If (JTokT = JT_ID) And Not JTokNL Then JNext;       { etiquette ignoree }
    JSemi;
  End
  Else If JIsKw('throw') Then
  Begin
    JNext;
    N := JNode(JN_THROW);
    If N <> Nil Then N^.A := JParseExpr;
    JSemi;
  End
  Else If JIsKw('try') Then
  Begin
    JNext;
    N := JNode(JN_TRY);
    If N <> Nil Then N^.A := JParseBlock;
    If JIsKw('catch') Then
    Begin
      JNext;
      If JIs('(') Then
      Begin
        JNext;
        If (JTokT = JT_ID) And (N <> Nil) Then
        Begin
          N^.P := JTokP; N^.L := JTokL;
          JNext;
        End;
        JExpect(')');
      End;
      If N <> Nil Then N^.B := JParseBlock;
    End;
    If JIsKw('finally') Then
    Begin
      JNext;
      If N <> Nil Then N^.C := JParseBlock;
    End;
  End
  Else If JIsKw('switch') Then
  Begin
    JNext;
    N := JNode(JN_SWITCH);
    JExpect('(');
    If N <> Nil Then N^.A := JParseExpr;
    JExpect(')');
    JExpect('{');
    Last := Nil;
    While Not JIs('}') And (JTokT <> JT_EOF) And Not JsErr Do
    Begin
      C := JNode(JN_CASE);
      If C = Nil Then Break;
      If JIsKw('case') Then
      Begin
        JNext;
        C^.A := JParseExpr;
      End
      Else If JIsKw('default') Then
      Begin
        JNext;
        C^.Op := 1;
      End
      Else
      Begin
        JsError('SyntaxError: "case" attendu');
        Break;
      End;
      JExpect(':');
      E := Nil;
      While Not JIs('}') And Not JIsKw('case') And Not JIsKw('default') And (JTokT <> JT_EOF) And Not JsErr Do
      Begin
        If E = Nil Then
        Begin
          C^.B := JParseStatement;
          E := C^.B;
        End
        Else
        Begin
          E^.Next := JParseStatement;
          If E^.Next <> Nil Then E := E^.Next;
        End;
      End;
      If N <> Nil Then
      Begin
        If Last = Nil Then N^.B := C Else Last^.Next := C;
        Last := C;
      End;
    End;
    JExpect('}');
  End
  Else
  Begin
    { etiquette "nom:" ignoree }
    If (JTokT = JT_ID) And (JsCh(JsPos) = 58) And Not JIsKw('default') Then
    Begin
      JNext; JNext;
      JParseStatement := JParseStatement;
      Exit;
    End;
    N := JNode(JN_EXPR);
    If N <> Nil Then N^.A := JParseExpr;
    JSemi;
  End;
  If JsErr Then N := Nil;
  JParseStatement := N;
End;

{ programme complet : liste d'instructions (JN_BLOCK) ; Nil si erreur }
Function JParseProgram(A, L, Line0 : LongInt) : PJN;
Var B, Last, S : PJN;
Begin
  JsSrc := A; JsLen := L; JsPos := 0; JsLine := Line0;
  JsErr := False; JsErrMsg := '';
  JNext;
  B := JNode(JN_BLOCK);
  Last := Nil;
  While (JTokT <> JT_EOF) And Not JsErr Do
  Begin
    S := JParseStatement;
    If S = Nil Then Break;
    If B <> Nil Then
    Begin
      If Last = Nil Then B^.A := S Else Last^.Next := S;
      Last := S;
    End;
  End;
  If JsErr Then B := Nil;
  JParseProgram := B;
End;

{ ---------------- execution ---------------- }

Procedure JsEval(N : PJN; Var R : TJV); Forward;
Procedure JsExec(N : PJN); Forward;
Procedure JsCallValue(Var F, ThisV : TJV; Argc : LongInt; Var R : TJV); Forward;
{ objets natifs et DOM (partie suivante) }
Procedure JsGetMember(Var O : TJV; A, L : LongInt; Var R : TJV); Forward;
Procedure JsSetMember(Var O : TJV; A, L : LongInt; Var V : TJV); Forward;
Procedure JsCallMethod(Var O : TJV; A, L, Argc : LongInt; Var R : TJV); Forward;
Procedure JsCallNative(Id : String; Var ThisV : TJV; Argc : LongInt; Var R : TJV); Forward;
Function JsNodeText(N : PNode) : String; Forward;

{ arguments : JsSp - Argc .. JsSp - 1 sur la pile des valeurs }
Function JsArgAdr(Argc, I : LongInt) : LongInt;
Begin
  JsArgAdr := JsStk + (JsSp - Argc + I) * SizeOf(TJV);
End;

Procedure JsArg(Argc, I : LongInt; Var V : TJV);
Var Pv : ^TJV;
Begin
  If (I < 0) Or (I >= Argc) Then
  Begin
    JvUndef(V);
    Exit;
  End;
  Pv := Pointer(JsArgAdr(Argc, I));
  V := Pv^;
End;

Function JsPush(Var V : TJV) : Boolean;
Var Pv : ^TJV;
Begin
  JsPush := False;
  If (JsStk = 0) Or (JsSp >= JS_STKMAX) Then Exit;
  Pv := Pointer(JsStk + JsSp * SizeOf(TJV));
  Pv^ := V;
  Inc(JsSp);
  JsPush := True;
End;

{ exception (TypeError, ReferenceError...) : capturable par try/catch }
Procedure JsThrowMsg(S : String);
Var O : PJObj; M : TJV;
Begin
  If JsCtl = JC_THROW Then Exit;
  O := JsNewObj;
  If O <> Nil Then
  Begin
    O^.Cls := JO_ERROR;
    If (Pos(':', S) > 0) And (Pos(':', S) < 16) Then
    Begin
      JvStr(M, Copy(S, Pos(':', S) + 2, 255));
      JsSetPropS(O, 'message', M);
      JvStr(M, Copy(S, 1, Pos(':', S) - 1));
    End
    Else
    Begin
      JvStr(M, S);
      JsSetPropS(O, 'message', M);
      JvStr(M, 'Error');
    End;
    JsSetPropS(O, 'name', M);
    JvObjV(JsExc, O);
  End
  Else JvStr(JsExc, S);
  JsCtl := JC_THROW;
End;

{ arret force (budget, memoire) : rien ne le capture }
Procedure JsAbort(S : String);
Begin
  JsAbortMsg := S;
  JsKill := True;
  JsThrowMsg(S);
  JsCtl := JC_THROW;
End;

Function JsStep : Boolean;
Begin
  Inc(JsSteps);
  If (JsSteps > JS_BUDGET) And Not JsKill Then
    JsAbort('Erreur : script trop long (plus de ' + IStr(JS_BUDGET) + ' operations), arrete');
  If ArFull And Not JsKill Then JsAbort('Erreur : memoire de la page epuisee');
  JsStep := Not JsKill;
End;

{ ---------------- conversions ---------------- }

Function JsToBool(Var V : TJV) : Boolean;
Begin
  Case V.K Of
    JV_UNDEF, JV_NULL : JsToBool := False;
    JV_BOOL : JsToBool := V.N <> 0;
    JV_NUM : JsToBool := (V.N <> 0) And Not JsIsNaN(V.N);
    JV_STR : JsToBool := V.L > 0;
  Else
    JsToBool := True;
  End;
End;

Procedure JsToStrV(Var V : TJV; Var R : TJV); Forward;

Function JsToNum(Var V : TJV) : Double;
Var T : TJV; O : PJObj;
Begin
  Case V.K Of
    JV_UNDEF : JsToNum := JsNaN;
    JV_NULL : JsToNum := 0;
    JV_BOOL, JV_NUM : JsToNum := V.N;
    JV_STR : JsToNum := JsParseNum(V.P, V.L, True);
    JV_OBJ :
      Begin
        O := Pointer(V.P);
        If O^.Cls = JO_DATE Then JsToNum := O^.Num
        Else If O^.IsArr And (O^.Len <= 1) Then
        Begin
          If O^.Len = 0 Then JsToNum := 0
          Else
          Begin
            JsArrGet(O, 0, T);
            JsToNum := JsToNum(T);
          End;
        End
        Else JsToNum := JsNaN;
      End;
  Else
    JsToNum := JsNaN;
  End;
End;

Function JsToInt(Var V : TJV) : LongInt;
Var D : Double;
Begin
  D := JsToNum(V);
  If JsIsNaN(D) Or (D > 2147483647.0) Or (D < -2147483648.0) Then
  Begin
    { modulo 2^32 pour les operations binaires }
    If JsIsNaN(D) Or (D = JsInf) Or (D = -JsInf) Then JsToInt := 0
    Else
    Begin
      While D > 2147483647.0 Do D := D - 4294967296.0;
      While D < -2147483648.0 Do D := D + 4294967296.0;
      JsToInt := Trunc(D);
    End;
  End
  Else JsToInt := Trunc(D);
End;

{ chaine d'un tableau : elements separes par Sep }
Procedure JsJoin(O : PJObj; Sep : String; Var R : TJV);
Var K : LongInt; E, S, Acc, SepV : TJV;
Begin
  JvStrAL(Acc, 0, 0);
  JvStr(SepV, Sep);
  For K := 0 To O^.Len - 1 Do
  Begin
    If K > 0 Then JsConcat(Acc, Acc.P, Acc.L, SepV.P, SepV.L);
    JsArrGet(O, K, E);
    If (E.K <> JV_UNDEF) And (E.K <> JV_NULL) Then
    Begin
      JsToStrV(E, S);
      JsConcat(Acc, Acc.P, Acc.L, S.P, S.L);
    End;
    If JsKill Or JsErr Then Break;
  End;
  R := Acc;
End;

Procedure JsToStrV(Var V : TJV; Var R : TJV);
Var O : PJObj; M : TJV; P : PJProp; N : PNode;
Begin
  Case V.K Of
    JV_UNDEF : JvStr(R, 'undefined');
    JV_NULL : JvStr(R, 'null');
    JV_BOOL : If V.N <> 0 Then JvStr(R, 'true') Else JvStr(R, 'false');
    JV_NUM : JvStr(R, JsNumStr(V.N));
    JV_STR : R := V;
    JV_OBJ :
      Begin
        O := Pointer(V.P);
        If O^.IsArr Then JsJoin(O, ',', R)
        Else If O^.Cls = JO_ERROR Then
        Begin
          { "nom: message" }
          JvStr(M, 'name');
          P := JsFindProp(O, M.P, M.L);
          If P <> Nil Then JsToStrV(P^.V, R) Else JvStr(R, 'Error');
          JvStr(M, 'message');
          P := JsFindProp(O, M.P, M.L);
          If P <> Nil Then
          Begin
            JvStr(M, ': ');
            JsConcat(R, R.P, R.L, M.P, M.L);
            JsToStrV(P^.V, M);
            JsConcat(R, R.P, R.L, M.P, M.L);
          End;
        End
        Else If O^.Cls = JO_DATE Then JsCallMethod(V, 0, 0, 0, R)
        Else If O^.Cls = JO_LOCATION Then JvStr(R, JsPageUrl)
        Else JvStr(R, '[object Object]');
      End;
    JV_FUN : JvStr(R, 'function () { [code] }');
    JV_NAT : JvStr(R, 'function () { [native code] }');
    JV_NODE :
      Begin
        N := Pointer(V.P);
        If N^.Kind = NODE_TEXT Then JvStr(R, '[object Text]')
        Else If (N^.Tag = TAG_A) And HasAttr(N, 'href') Then JvStr(R, ResolveUrl(BaseUrl, GetAttr(N, 'href')))
        Else JvStr(R, '[object HTML' + UpStr(Copy(N^.Name, 1, 1)) + Copy(N^.Name, 2, 30) + 'Element]');
      End;
  Else
    JvStr(R, '');
  End;
End;

{ texte Pascal (messages, console) }
Function JsToPStr(Var V : TJV) : String;
Var R : TJV;
Begin
  JsToStrV(V, R);
  JsToPStr := ArGet(R.P, R.L);
End;

{ forme lisible pour la console : chaines entre guillemets dans les
  tableaux et objets }
Function JsInspect(Var V : TJV; Depth : LongInt) : String;
Var O : PJObj; S : String; K : LongInt; E : TJV; P : PJProp; Nd : PNode;
Begin
  If (V.K = JV_STR) And (Depth > 0) Then
  Begin
    JsInspect := '"' + Copy(ArGet(V.P, V.L), 1, 120) + '"';
    Exit;
  End;
  If (V.K = JV_OBJ) And (Depth < 2) Then
  Begin
    O := Pointer(V.P);
    If O^.IsArr Then
    Begin
      S := '[';
      For K := 0 To O^.Len - 1 Do
      Begin
        If K > 0 Then S := S + ', ';
        JsArrGet(O, K, E);
        S := S + JsInspect(E, Depth + 1);
        If Length(S) > 200 Then
        Begin
          S := S + '...';
          Break;
        End;
      End;
      JsInspect := S + ']';
      Exit;
    End;
    If O^.Cls = JO_PLAIN Then
    Begin
      S := '{';
      P := O^.Props;
      While P <> Nil Do
      Begin
        If Length(S) > 1 Then S := S + ', ';
        S := S + ArGet(P^.P, P^.L) + ': ' + JsInspect(P^.V, Depth + 1);
        If Length(S) > 200 Then
        Begin
          S := S + '...';
          Break;
        End;
        P := P^.Next;
      End;
      JsInspect := S + '}';
      Exit;
    End;
  End;
  If V.K = JV_NODE Then
  Begin
    Nd := Pointer(V.P);
    JsInspect := '<' + Nd^.Name + '>';
    Exit;
  End;
  JsInspect := JsToPStr(V);
End;

Function JsTypeOf(Var V : TJV) : String;
Begin
  Case V.K Of
    JV_UNDEF : JsTypeOf := 'undefined';
    JV_NULL : JsTypeOf := 'object';
    JV_BOOL : JsTypeOf := 'boolean';
    JV_NUM : JsTypeOf := 'number';
    JV_STR : JsTypeOf := 'string';
    JV_FUN, JV_NAT : JsTypeOf := 'function';
  Else
    JsTypeOf := 'object';
  End;
End;

{ egalite stricte (===) et large (==) }
Function JsStrictEq(Var A, B : TJV) : Boolean;
Begin
  JsStrictEq := False;
  If A.K <> B.K Then Exit;
  Case A.K Of
    JV_UNDEF, JV_NULL : JsStrictEq := True;
    JV_BOOL, JV_NUM : JsStrictEq := A.N = B.N;
    JV_STR : JsStrictEq := JsSame(A.P, A.L, B.P, B.L);
    JV_NAT : JsStrictEq := JsSame(A.P, A.L, B.P, B.L);
  Else
    JsStrictEq := A.P = B.P;
  End;
End;

Function JsLooseEq(Var A, B : TJV) : Boolean;
Var SA, SB : TJV;
Begin
  If A.K = B.K Then JsLooseEq := JsStrictEq(A, B)
  Else If ((A.K = JV_UNDEF) Or (A.K = JV_NULL)) And ((B.K = JV_UNDEF) Or (B.K = JV_NULL)) Then JsLooseEq := True
  Else If (A.K = JV_UNDEF) Or (A.K = JV_NULL) Or (B.K = JV_UNDEF) Or (B.K = JV_NULL) Then JsLooseEq := False
  Else If (A.K In [JV_NUM, JV_BOOL, JV_STR]) And (B.K In [JV_NUM, JV_BOOL, JV_STR]) Then
    JsLooseEq := JsToNum(A) = JsToNum(B)
  Else
  Begin
    JsToStrV(A, SA); JsToStrV(B, SB);
    JsLooseEq := JsSame(SA.P, SA.L, SB.P, SB.L);
  End;
End;

{ comparaison de chaines (ordre des octets) : <0, 0, >0 }
Function JsStrCmp(A1, L1, A2, L2 : LongInt) : LongInt;
Var K, C1, C2 : LongInt;
Begin
  For K := 0 To MinI(L1, L2) - 1 Do
  Begin
    C1 := RdB(A1 + K); C2 := RdB(A2 + K);
    If C1 <> C2 Then
    Begin
      JsStrCmp := C1 - C2;
      Exit;
    End;
  End;
  JsStrCmp := L1 - L2;
End;

{ ---------------- portees ---------------- }

Function JsNewEnv(Parent : PJEnv) : PJEnv;
Var E : PJEnv;
Begin
  E := Pointer(ArAlloc(SizeOf(TJEnv)));
  If E = Nil Then JsAbort('Erreur : memoire de la page epuisee')
  Else E^.Parent := Parent;
  JsNewEnv := E;
End;

Function JsEnvFind(E : PJEnv; A, L : LongInt) : PJProp;
Var P : PJProp;
Begin
  JsEnvFind := Nil;
  While E <> Nil Do
  Begin
    P := E^.Vars;
    While P <> Nil Do
    Begin
      If JsSame(P^.P, P^.L, A, L) Then
      Begin
        JsEnvFind := P;
        Exit;
      End;
      P := P^.Next;
    End;
    E := E^.Parent;
  End;
End;

Procedure JsDeclare(E : PJEnv; A, L : LongInt; Var V : TJV; Flags : LongInt);
Var P : PJProp;
Begin
  If E = Nil Then Exit;
  P := E^.Vars;
  While P <> Nil Do
  Begin
    If JsSame(P^.P, P^.L, A, L) Then
    Begin
      P^.V := V; P^.Flags := Flags;
      Exit;
    End;
    P := P^.Next;
  End;
  P := Pointer(ArAlloc(SizeOf(TJProp)));
  If P = Nil Then
  Begin
    JsAbort('Erreur : memoire de la page epuisee');
    Exit;
  End;
  P^.P := A; P^.L := L; P^.V := V; P^.Flags := Flags;
  P^.Next := E^.Vars;
  E^.Vars := P;
End;

Var
  JsEnv : PJEnv;                 { portee courante }

{ declarations "function" d'un bloc : definies avant son execution }
Procedure JsHoist(First : PJN);
Var S : PJN; F : PJFun; V : TJV;
Begin
  S := First;
  While S <> Nil Do
  Begin
    If S^.T = JN_FUNDECL Then
    Begin
      F := Pointer(ArAlloc(SizeOf(TJFun)));
      If F = Nil Then Exit;
      F^.Params := S^.A; F^.Body := S^.B; F^.Env := JsEnv; F^.NP := S^.P; F^.NL := S^.L;
      V.K := JV_FUN; V.N := 0; V.P := LongInt(F); V.L := 0;
      JsDeclare(JsEnv, S^.P, S^.L, V, 0);
    End;
    S := S^.Next;
  End;
End;

{ ---------------- appels de fonctions ---------------- }

Procedure JsCallFun(F : PJFun; Var ThisV : TJV; Argc : LongInt; Var R : TJV);
Var SaveEnv : PJEnv; SaveThis, V, Rest : TJV; P : PJN; I : LongInt; O : PJObj;
Begin
  JvUndef(R);
  If JsDepth >= JS_MAXDEPTH Then
  Begin
    JsThrowMsg('RangeError: trop d''appels imbriques (recursion)');
    Exit;
  End;
  Inc(JsDepth);
  SaveEnv := JsEnv; SaveThis := JsThis;
  JsEnv := JsNewEnv(F^.Env);
  If JsEnv = Nil Then
  Begin
    JsEnv := SaveEnv;
    Dec(JsDepth);
    Exit;
  End;
  JsEnv^.IsFunc := True;
  If F^.Arrow Then JsThis := F^.ThisV Else JsThis := ThisV;
  { parametres (valeurs par defaut, reste) }
  P := F^.Params; I := 0;
  While P <> Nil Do
  Begin
    If P^.Op = 1 Then
    Begin
      O := JsNewArr;
      While I < Argc Do
      Begin
        JsArg(Argc, I, V);
        JsArrPush(O, V);
        Inc(I);
      End;
      JvObjV(Rest, O);
      JsDeclare(JsEnv, P^.P, P^.L, Rest, 0);
    End
    Else
    Begin
      JsArg(Argc, I, V);
      If (V.K = JV_UNDEF) And (P^.B <> Nil) Then JsEval(P^.B, V);
      JsDeclare(JsEnv, P^.P, P^.L, V, 0);
    End;
    Inc(I);
    P := P^.Next;
  End;
  { arguments }
  If Not F^.Arrow Then
  Begin
    O := JsNewArr;
    For I := 0 To Argc - 1 Do
    Begin
      JsArg(Argc, I, V);
      JsArrPush(O, V);
    End;
    JvObjV(V, O);
    JvStr(Rest, 'arguments');
    JsDeclare(JsEnv, Rest.P, Rest.L, V, 0);
  End;
  If F^.ExprBody Then
  Begin
    JsEval(F^.Body, R);
  End
  Else
  Begin
    JsHoist(F^.Body^.A);
    JsExec(F^.Body);
    If JsCtl = JC_RET Then
    Begin
      R := JsRet;
      JsCtl := JC_NONE;
    End
    Else If (JsCtl = JC_BREAK) Or (JsCtl = JC_CONT) Then JsCtl := JC_NONE;
  End;
  JsEnv := SaveEnv; JsThis := SaveThis;
  Dec(JsDepth);
End;

{ appel d'une valeur fonction ; les Argc arguments sont sur la pile }
Procedure JsCallValue(Var F, ThisV : TJV; Argc : LongInt; Var R : TJV);
Begin
  JvUndef(R);
  If F.K = JV_FUN Then JsCallFun(Pointer(F.P), ThisV, Argc, R)
  Else If F.K = JV_NAT Then JsCallNative(ArGet(F.P, F.L), ThisV, Argc, R)
  Else JsThrowMsg('TypeError: ce n''est pas une fonction');
End;

{ arguments d'un appel : evalues puis empiles ; rend leur nombre (-1 si erreur) }
Function JsPushArgs(A : PJN) : LongInt;
Var N, K : LongInt; V, E : TJV;
Begin
  N := 0;
  While A <> Nil Do
  Begin
    If A^.T = JN_SPREAD Then
    Begin
      JsEval(A^.A, V);
      If (JvArr(V) <> Nil) Then
      Begin
        For K := 0 To JvLen(V) - 1 Do
        Begin
          JsArrGet(Pointer(V.P), K, E);
          If JsPush(E) Then Inc(N);
        End;
        A := A^.Next;
        Continue;
      End;
    End
    Else JsEval(A, V);
    If JsCtl = JC_THROW Then
    Begin
      JsSp := JsSp - N;
      JsPushArgs := -1;
      Exit;
    End;
    If Not JsPush(V) Then
    Begin
      JsSp := JsSp - N;
      JsThrowMsg('RangeError: trop d''arguments');
      JsPushArgs := -1;
      Exit;
    End;
    Inc(N);
    A := A^.Next;
  End;
  JsPushArgs := N;
End;

{ nom de propriete d'un acces "o[k]" : chaine de l'arene }
Procedure JsKeyOf(Var K : TJV; Var R : TJV);
Begin
  If K.K = JV_STR Then R := K Else JsToStrV(K, R);
End;

{ indice entier d'une cle ("3", 3) ou -1 }
Function JsIndexOf(Var K : TJV) : LongInt;
Var D : Double;
Begin
  JsIndexOf := -1;
  If K.K = JV_NUM Then D := K.N
  Else If (K.K = JV_STR) And (K.L > 0) And (K.L < 10) And (Chr(RdB(K.P)) In ['0'..'9']) Then D := JsParseNum(K.P, K.L, True)
  Else Exit;
  If JsIsNaN(D) Or (D < 0) Or (D > 1000000000) Or (D <> JsFTrunc(D)) Then Exit;
  JsIndexOf := Trunc(D);
End;

{ lecture o[k] }
Procedure JsGetIndex(Var O, K : TJV; Var R : TJV);
Var I : LongInt; KS : TJV; Ob : PJObj;
Begin
  I := JsIndexOf(K);
  If (JvArr(O) <> Nil) And (I >= 0) Then
  Begin
    JsArrGet(Pointer(O.P), I, R);
    Exit;
  End;
  If (O.K = JV_STR) And (I >= 0) Then
  Begin
    If I < O.L Then JvStrAL(R, O.P + I, 1) Else JvUndef(R);
    Exit;
  End;
  JsKeyOf(K, KS);
  JsGetMember(O, KS.P, KS.L, R);
End;

Procedure JsSetIndex(Var O, K, V : TJV);
Var I : LongInt; KS : TJV;
Begin
  I := JsIndexOf(K);
  If (JvArr(O) <> Nil) And (I >= 0) Then
  Begin
    JsArrSet(Pointer(O.P), I, V);
    Exit;
  End;
  JsKeyOf(K, KS);
  JsSetMember(O, KS.P, KS.L, V);
End;

{ valeur d'un identifiant : portees, puis objets globaux du navigateur }
Procedure JsGetIdent(A, L : LongInt; Var R : TJV);
Var P : PJProp; W : TJV;
Begin
  P := JsEnvFind(JsEnv, A, L);
  If P <> Nil Then
  Begin
    R := P^.V;
    Exit;
  End;
  { proprietes de window (window.x = 1 puis x) }
  If JsWindow <> Nil Then
  Begin
    P := JsFindProp(JsWindow, A, L);
    If P <> Nil Then
    Begin
      R := P^.V;
      Exit;
    End;
    JvObjV(W, JsWindow);
    JsGetMember(W, A, L, R);
    If R.K <> JV_UNDEF Then Exit;
  End;
  If JsSameS(A, L, 'NaN') Then JvNum(R, JsNaN)
  Else If JsSameS(A, L, 'Infinity') Then JvNum(R, JsInf)
  Else JsThrowMsg('ReferenceError: ' + Copy(ArGet(A, L), 1, 60) + ' n''est pas d' + Chr(130) + 'fini');
End;

Procedure JsSetIdent(A, L : LongInt; Var V : TJV);
Var P : PJProp; W : TJV;
Begin
  P := JsEnvFind(JsEnv, A, L);
  If P <> Nil Then
  Begin
    If (P^.Flags And 1) <> 0 Then
    Begin
      JsThrowMsg('TypeError: affectation d''une constante : ' + Copy(ArGet(A, L), 1, 60));
      Exit;
    End;
    P^.V := V;
    Exit;
  End;
  { variable implicite : globale (propriete de window) }
  If JsSameS(A, L, 'location') Or JsSameS(A, L, 'onload') Or JsSameS(A, L, 'status') Then
  Begin
    JvObjV(W, JsWindow);
    JsSetMember(W, A, L, V);
    Exit;
  End;
  JsDeclare(JsGlobal, A, L, V, 0);
End;

{ ---------------- operateurs ---------------- }

Procedure JsBinary(Op : LongInt; Var A, B : TJV; Var R : TJV);
Var SA, SB : TJV; X, Y : Double; IA, IB : LongInt; O : PJObj;
Begin
  Case Op Of
    1 :
      Begin
        If (A.K = JV_STR) Or (B.K = JV_STR) Or ((A.K In [JV_OBJ, JV_NODE, JV_FUN]) And Not ((JvCls(A) = JO_DATE))) Or
           ((B.K In [JV_OBJ, JV_NODE, JV_FUN]) And Not ((JvCls(B) = JO_DATE))) Then
        Begin
          JsToStrV(A, SA); JsToStrV(B, SB);
          JsConcat(R, SA.P, SA.L, SB.P, SB.L);
        End
        Else JvNum(R, JsToNum(A) + JsToNum(B));
      End;
    2 : JvNum(R, JsToNum(A) - JsToNum(B));
    3 : JvNum(R, JsToNum(A) * JsToNum(B));
    4 :
      Begin
        X := JsToNum(A); Y := JsToNum(B);
        If Y = 0 Then
        Begin
          If (X = 0) Or JsIsNaN(X) Then JvNum(R, JsNaN)
          Else If X > 0 Then JvNum(R, JsInf) Else JvNum(R, -JsInf);
        End
        Else JvNum(R, X / Y);
      End;
    5 :
      Begin
        X := JsToNum(A); Y := JsToNum(B);
        If (Y = 0) Or JsIsNaN(X) Or JsIsNaN(Y) Then JvNum(R, JsNaN)
        Else JvNum(R, X - Y * JsFTrunc(X / Y));
      End;
    6, 7, 8, 9 :
      Begin
        If (A.K = JV_STR) And (B.K = JV_STR) Then
        Begin
          IA := JsStrCmp(A.P, A.L, B.P, B.L);
          Case Op Of
            6 : JvBool(R, IA < 0);
            7 : JvBool(R, IA > 0);
            8 : JvBool(R, IA <= 0);
            9 : JvBool(R, IA >= 0);
          End;
        End
        Else
        Begin
          X := JsToNum(A); Y := JsToNum(B);
          If JsIsNaN(X) Or JsIsNaN(Y) Then JvBool(R, False)
          Else
            Case Op Of
              6 : JvBool(R, X < Y);
              7 : JvBool(R, X > Y);
              8 : JvBool(R, X <= Y);
              9 : JvBool(R, X >= Y);
            End;
        End;
      End;
    10 : JvBool(R, JsLooseEq(A, B));
    11 : JvBool(R, Not JsLooseEq(A, B));
    12 : JvBool(R, JsStrictEq(A, B));
    13 : JvBool(R, Not JsStrictEq(A, B));
    14 : JvNum(R, JsToInt(A) And JsToInt(B));
    15 : JvNum(R, JsToInt(A) Or JsToInt(B));
    16 : JvNum(R, JsToInt(A) Xor JsToInt(B));
    17 : JvNum(R, JsToInt(A) Shl (JsToInt(B) And 31));
    18 :
      Begin
        IA := JsToInt(A); IB := JsToInt(B) And 31;
        If IA >= 0 Then JvNum(R, IA Shr IB)
        Else JvNum(R, -((-IA - 1) Shr IB) - 1);
      End;
    19 :
      Begin
        IA := JsToInt(A); IB := JsToInt(B) And 31;
        X := IA;
        If X < 0 Then X := X + 4294967296.0;
        While IB > 0 Do
        Begin
          X := JsFTrunc(X / 2); Dec(IB);
        End;
        JvNum(R, X);
      End;
    20 :
      Begin
        X := JsToNum(A); Y := JsToNum(B);
        If (Abs(Y) < 1000) And (Y = JsFTrunc(Y)) Then
        Begin
          R.N := 1;
          IA := Trunc(Abs(Y));
          While IA > 0 Do
          Begin
            R.N := R.N * X; Dec(IA);
          End;
          If Y < 0 Then R.N := 1 / R.N;
          JvNum(R, R.N);
        End
        Else If X > 0 Then JvNum(R, Exp(Y * Ln(X)))
        Else JvNum(R, JsNaN);
      End;
    21 :
      Begin
        { instanceof : Array, Date, Error, Object }
        JvBool(R, False);
        If (A.K = JV_OBJ) And (B.K = JV_NAT) Then
        Begin
          O := Pointer(A.P);
          SB.K := 0;
          If JsSameS(B.P, B.L, 'Array') Then JvBool(R, O^.IsArr)
          Else If JsSameS(B.P, B.L, 'Date') Then JvBool(R, O^.Cls = JO_DATE)
          Else If JsSameS(B.P, B.L, 'Error') Then JvBool(R, O^.Cls = JO_ERROR)
          Else If JsSameS(B.P, B.L, 'Object') Then JvBool(R, True);
        End;
      End;
    22 :
      Begin
        { "cle" in objet }
        JvBool(R, False);
        If B.K = JV_OBJ Then
        Begin
          O := Pointer(B.P);
          IA := JsIndexOf(A);
          If O^.IsArr And (IA >= 0) Then JvBool(R, IA < O^.Len)
          Else
          Begin
            JsKeyOf(A, SA);
            JvBool(R, JsFindProp(O, SA.P, SA.L) <> Nil);
          End;
        End;
      End;
  Else
    JvUndef(R);
  End;
End;

{ affectation a une cible (identifiant, membre, indice) }
Procedure JsAssign(T : PJN; Var V : TJV);
Var O, K : TJV;
Begin
  Case T^.T Of
    JN_IDENT : JsSetIdent(T^.P, T^.L, V);
    JN_MEMBER :
      Begin
        JsEval(T^.A, O);
        If JsCtl = JC_THROW Then Exit;
        JsSetMember(O, T^.P, T^.L, V);
      End;
    JN_INDEX :
      Begin
        JsEval(T^.A, O);
        If JsCtl = JC_THROW Then Exit;
        JsEval(T^.B, K);
        If JsCtl = JC_THROW Then Exit;
        JsSetIndex(O, K, V);
      End;
  End;
End;

Procedure JsMakeFun(N : PJN; Var R : TJV);
Var F : PJFun;
Begin
  F := Pointer(ArAlloc(SizeOf(TJFun)));
  If F = Nil Then
  Begin
    JsAbort('Erreur : memoire de la page epuisee');
    JvUndef(R);
    Exit;
  End;
  F^.Params := N^.A; F^.Env := JsEnv; F^.NP := N^.P; F^.NL := N^.L;
  F^.Arrow := N^.Op >= 1;
  F^.ExprBody := N^.Op = 2;
  If F^.ExprBody Then F^.Body := N^.C Else F^.Body := N^.B;
  F^.ThisV := JsThis;
  R.K := JV_FUN; R.N := 0; R.P := LongInt(F); R.L := 0;
End;

Procedure JsEval(N : PJN; Var R : TJV);
Var A, B, C, ThisV : TJV; Argc : LongInt; O : PJObj; E : PJN; D : Double;
Begin
  JvUndef(R);
  If (N = Nil) Or Not JsStep Then Exit;
  Case N^.T Of
    JN_NUM : JvNum(R, N^.N);
    JN_STR : JvStrAL(R, N^.P, N^.L);
    JN_TRUE : JvBool(R, True);
    JN_FALSE : JvBool(R, False);
    JN_NULL : R.K := JV_NULL;
    JN_UNDEF : ;
    JN_THIS : R := JsThis;
    JN_IDENT : JsGetIdent(N^.P, N^.L, R);
    JN_FUNC : JsMakeFun(N, R);
    JN_ARRAY :
      Begin
        O := JsNewArr;
        E := N^.A;
        While (E <> Nil) And (JsCtl <> JC_THROW) Do
        Begin
          If E^.T = JN_SPREAD Then
          Begin
            { ...tableau ou ...chaine }
            JsEval(E^.A, A);
            If (JvArr(A) <> Nil) Then
              For Argc := 0 To JvLen(A) - 1 Do
              Begin
                JsArrGet(Pointer(A.P), Argc, B);
                JsArrPush(O, B);
              End
            Else If A.K = JV_STR Then
              For Argc := 0 To A.L - 1 Do
              Begin
                JvStrAL(B, A.P + Argc, 1);
                JsArrPush(O, B);
              End;
          End
          Else
          Begin
            JsEval(E, A);
            JsArrPush(O, A);
          End;
          E := E^.Next;
        End;
        If O <> Nil Then JvObjV(R, O);
      End;
    JN_OBJECT :
      Begin
        O := JsNewObj;
        E := N^.A;
        While (E <> Nil) And (JsCtl <> JC_THROW) Do
        Begin
          JsEval(E^.A, A);
          JsSetPropAL(O, E^.P, E^.L, A);
          E := E^.Next;
        End;
        If O <> Nil Then JvObjV(R, O);
      End;
    JN_MEMBER :
      Begin
        JsEval(N^.A, A);
        If JsCtl = JC_THROW Then Exit;
        If (A.K = JV_UNDEF) Or (A.K = JV_NULL) Then
          JsThrowMsg('TypeError: impossible de lire "' + Copy(ArGet(N^.P, N^.L), 1, 40) + '" de ' + JsToPStr(A))
        Else JsGetMember(A, N^.P, N^.L, R);
      End;
    JN_INDEX :
      Begin
        JsEval(N^.A, A);
        If JsCtl = JC_THROW Then Exit;
        JsEval(N^.B, B);
        If JsCtl = JC_THROW Then Exit;
        If (A.K = JV_UNDEF) Or (A.K = JV_NULL) Then
          JsThrowMsg('TypeError: impossible de lire la propriete ' + JsToPStr(B) + ' de ' + JsToPStr(A))
        Else JsGetIndex(A, B, R);
      End;
    JN_CALL :
      Begin
        E := N^.A;
        If (E^.T = JN_MEMBER) Or (E^.T = JN_INDEX) Then
        Begin
          { methode : this = objet }
          JsEval(E^.A, ThisV);
          If JsCtl = JC_THROW Then Exit;
          If (ThisV.K = JV_UNDEF) Or (ThisV.K = JV_NULL) Then
          Begin
            JsThrowMsg('TypeError: ' + JsToPStr(ThisV) + ' n''a pas de methodes');
            Exit;
          End;
          If E^.T = JN_MEMBER Then
          Begin
            C.P := E^.P; C.L := E^.L;
          End
          Else
          Begin
            JsEval(E^.B, B);
            If JsCtl = JC_THROW Then Exit;
            JsKeyOf(B, C);
          End;
          { methode definie par le script (propriete fonction) ? }
          JvUndef(A);
          If ThisV.K = JV_OBJ Then
            If JsFindProp(Pointer(ThisV.P), C.P, C.L) <> Nil Then A := JsFindProp(Pointer(ThisV.P), C.P, C.L)^.V;
          Argc := JsPushArgs(N^.B);
          If Argc < 0 Then Exit;
          If (A.K = JV_FUN) Or (A.K = JV_NAT) Then JsCallValue(A, ThisV, Argc, R)
          Else JsCallMethod(ThisV, C.P, C.L, Argc, R);
          JsSp := JsSp - Argc;
        End
        Else
        Begin
          JsEval(E, A);
          If JsCtl = JC_THROW Then Exit;
          Argc := JsPushArgs(N^.B);
          If Argc < 0 Then Exit;
          JvUndef(ThisV);
          If (A.K <> JV_FUN) And (A.K <> JV_NAT) Then
          Begin
            If E^.T = JN_IDENT Then
              JsThrowMsg('TypeError: ' + Copy(ArGet(E^.P, E^.L), 1, 60) + ' n''est pas une fonction')
            Else JsThrowMsg('TypeError: ce n''est pas une fonction');
          End
          Else JsCallValue(A, ThisV, Argc, R);
          JsSp := JsSp - Argc;
        End;
      End;
    JN_NEW :
      Begin
        JsEval(N^.A, A);
        If JsCtl = JC_THROW Then Exit;
        Argc := JsPushArgs(N^.B);
        If Argc < 0 Then Exit;
        If A.K = JV_NAT Then
        Begin
          { constructeur natif : Date, Array, Object, Error... }
          JvStr(ThisV, 'new');
          JsCallNative(ArGet(A.P, A.L), ThisV, Argc, R);
        End
        Else If A.K = JV_FUN Then
        Begin
          O := JsNewObj;
          JvObjV(ThisV, O);
          JsCallValue(A, ThisV, Argc, R);
          If (R.K <> JV_OBJ) And (JsCtl <> JC_THROW) Then R := ThisV;
        End
        Else JsThrowMsg('TypeError: ce n''est pas un constructeur');
        JsSp := JsSp - Argc;
      End;
    JN_UNARY :
      Begin
        JsEval(N^.A, A);
        If JsCtl = JC_THROW Then Exit;
        Case N^.Op Of
          33 : JvBool(R, Not JsToBool(A));
          45 : JvNum(R, -JsToNum(A));
          43 : JvNum(R, JsToNum(A));
          126 : JvNum(R, Not JsToInt(A));
          118 : JvUndef(R);
        End;
      End;
    JN_TYPEOF :
      Begin
        If N^.A^.T = JN_IDENT Then
        Begin
          { typeof x : sans ReferenceError si x n'existe pas }
          JsGetIdent(N^.A^.P, N^.A^.L, A);
          If JsCtl = JC_THROW Then
          Begin
            JsCtl := JC_NONE;
            JvUndef(A);
          End;
        End
        Else
        Begin
          JsEval(N^.A, A);
          If JsCtl = JC_THROW Then Exit;
        End;
        JvStr(R, JsTypeOf(A));
      End;
    JN_DELETE :
      Begin
        JvBool(R, True);
        If N^.A^.T = JN_MEMBER Then
        Begin
          JsEval(N^.A^.A, A);
          JvUndef(B);
          If (A.K = JV_OBJ) And (JsCtl <> JC_THROW) Then JsSetPropAL(Pointer(A.P), N^.A^.P, N^.A^.L, B);
        End;
      End;
    JN_BINARY :
      Begin
        JsEval(N^.A, A);
        If JsCtl = JC_THROW Then Exit;
        JsEval(N^.B, B);
        If JsCtl = JC_THROW Then Exit;
        JsBinary(N^.Op, A, B, R);
      End;
    JN_LOGIC :
      Begin
        JsEval(N^.A, A);
        If JsCtl = JC_THROW Then Exit;
        Case N^.Op Of
          30 : If JsToBool(A) Then JsEval(N^.B, R) Else R := A;
          31 : If JsToBool(A) Then R := A Else JsEval(N^.B, R);
          32 : If (A.K = JV_UNDEF) Or (A.K = JV_NULL) Then JsEval(N^.B, R) Else R := A;
        End;
      End;
    JN_COND :
      Begin
        JsEval(N^.A, A);
        If JsCtl = JC_THROW Then Exit;
        If JsToBool(A) Then JsEval(N^.B, R) Else JsEval(N^.C, R);
      End;
    JN_ASSIGN :
      Begin
        If N^.Op = 0 Then JsEval(N^.B, R)
        Else
        Begin
          JsEval(N^.A, A);
          If JsCtl = JC_THROW Then Exit;
          JsEval(N^.B, B);
          If JsCtl = JC_THROW Then Exit;
          JsBinary(N^.Op, A, B, R);
        End;
        If JsCtl = JC_THROW Then Exit;
        JsAssign(N^.A, R);
      End;
    JN_PREINC, JN_POSTINC :
      Begin
        JsEval(N^.A, A);
        If JsCtl = JC_THROW Then Exit;
        D := JsToNum(A);
        JvNum(B, D + N^.Op);
        JsAssign(N^.A, B);
        If N^.T = JN_PREINC Then R := B Else JvNum(R, D);
      End;
    JN_SEQ :
      Begin
        JsEval(N^.A, A);
        If JsCtl = JC_THROW Then Exit;
        JsEval(N^.B, R);
      End;
  Else
    JsThrowMsg('Erreur interne : expression inconnue');
  End;
End;

{ suite d'instructions ; s'arrete sur break, continue, return, throw }
Procedure JsExecList(S : PJN);
Begin
  While (S <> Nil) And (JsCtl = JC_NONE) Do
  Begin
    JsExec(S);
    S := S^.Next;
  End;
End;

Procedure JsExecVar(N : PJN);
Var D : PJN; V : TJV; Fl : LongInt; Fe : PJEnv;
Begin
  D := N^.A;
  If N^.Op = 2 Then Fl := 1 Else Fl := 0;
  While (D <> Nil) And (JsCtl = JC_NONE) Do
  Begin
    JvUndef(V);
    If D^.A <> Nil Then JsEval(D^.A, V);
    If JsCtl <> JC_NONE Then Exit;
    If N^.Op = 0 Then
    Begin
      { var : portee de la fonction englobante }
      Fe := JsEnv;
      While (Fe <> Nil) And Not Fe^.IsFunc And (Fe^.Parent <> Nil) Do Fe := Fe^.Parent;
      If (D^.A <> Nil) Or (JsEnvFind(JsEnv, D^.P, D^.L) = Nil) Then JsDeclare(Fe, D^.P, D^.L, V, 0);
    End
    Else JsDeclare(JsEnv, D^.P, D^.L, V, Fl);
    D := D^.Next;
  End;
End;

Procedure JsExec(N : PJN);
Var V, K, Obj : TJV; SaveEnv : PJEnv; C : PJN; Hit : Boolean; I : LongInt; O : PJObj; P : PJProp;
    ExcSave : TJV; CtlSave : LongInt; RetSave : TJV;
Begin
  If (N = Nil) Or Not JsStep Then Exit;
  Case N^.T Of
    JN_EMPTY, JN_FUNDECL : ;
    JN_EXPR : JsEval(N^.A, V);
    JN_VAR : JsExecVar(N);
    JN_BLOCK :
      If N^.Op = 0 Then JsExecList(N^.A)
      Else
      Begin
        SaveEnv := JsEnv;
        JsEnv := JsNewEnv(JsEnv);
        If JsEnv = Nil Then
        Begin
          JsEnv := SaveEnv;
          Exit;
        End;
        JsHoist(N^.A);
        JsExecList(N^.A);
        JsEnv := SaveEnv;
      End;
    JN_IF :
      Begin
        JsEval(N^.A, V);
        If JsCtl <> JC_NONE Then Exit;
        If JsToBool(V) Then JsExec(N^.B) Else JsExec(N^.C);
      End;
    JN_WHILE, JN_DOWHILE :
      Begin
        Hit := N^.T = JN_DOWHILE;
        While JsCtl = JC_NONE Do
        Begin
          If Not Hit Then
          Begin
            JsEval(N^.A, V);
            If (JsCtl <> JC_NONE) Or Not JsToBool(V) Then Break;
          End;
          Hit := False;
          JsExec(N^.B);
          If JsCtl = JC_BREAK Then
          Begin
            JsCtl := JC_NONE;
            Break;
          End;
          If JsCtl = JC_CONT Then JsCtl := JC_NONE;
          If (N^.T = JN_DOWHILE) And (JsCtl = JC_NONE) Then
          Begin
            JsEval(N^.A, V);
            If (JsCtl <> JC_NONE) Or Not JsToBool(V) Then Break;
            Hit := True;
          End;
        End;
      End;
    JN_FOR :
      Begin
        SaveEnv := JsEnv;
        JsEnv := JsNewEnv(JsEnv);
        If JsEnv = Nil Then
        Begin
          JsEnv := SaveEnv;
          Exit;
        End;
        If N^.A <> Nil Then
        Begin
          If N^.A^.T = JN_VAR Then JsExecVar(N^.A) Else JsEval(N^.A, V);
        End;
        While JsCtl = JC_NONE Do
        Begin
          If N^.B <> Nil Then
          Begin
            JsEval(N^.B, V);
            If (JsCtl <> JC_NONE) Or Not JsToBool(V) Then Break;
          End;
          JsExec(N^.D);
          If JsCtl = JC_BREAK Then
          Begin
            JsCtl := JC_NONE;
            Break;
          End;
          If JsCtl = JC_CONT Then JsCtl := JC_NONE;
          If (JsCtl = JC_NONE) And (N^.C <> Nil) Then JsEval(N^.C, V);
        End;
        JsEnv := SaveEnv;
      End;
    JN_FORIN :
      Begin
        JsEval(N^.B, Obj);
        If JsCtl <> JC_NONE Then Exit;
        SaveEnv := JsEnv;
        JsEnv := JsNewEnv(JsEnv);
        If JsEnv = Nil Then
        Begin
          JsEnv := SaveEnv;
          Exit;
        End;
        { cible : var x / let x / x }
        If N^.A^.T = JN_VAR Then C := N^.A^.A Else C := N^.A;
        If (Obj.K = JV_OBJ) Then
        Begin
          O := Pointer(Obj.P);
          If O^.IsArr Then
          Begin
            I := 0;
            While (I < O^.Len) And (JsCtl = JC_NONE) Do
            Begin
              If N^.Op = 1 Then JsArrGet(O, I, V) Else JvStr(V, IStr(I));
              If C^.T = JN_DECL Then JsDeclare(JsEnv, C^.P, C^.L, V, 0) Else JsAssign(C, V);
              JsExec(N^.C);
              If JsCtl = JC_BREAK Then
              Begin
                JsCtl := JC_NONE;
                Break;
              End;
              If JsCtl = JC_CONT Then JsCtl := JC_NONE;
              Inc(I);
            End;
          End
          Else
          Begin
            P := O^.Props;
            While (P <> Nil) And (JsCtl = JC_NONE) Do
            Begin
              If N^.Op = 1 Then V := P^.V Else JvStrAL(V, P^.P, P^.L);
              If C^.T = JN_DECL Then JsDeclare(JsEnv, C^.P, C^.L, V, 0) Else JsAssign(C, V);
              JsExec(N^.C);
              If JsCtl = JC_BREAK Then
              Begin
                JsCtl := JC_NONE;
                Break;
              End;
              If JsCtl = JC_CONT Then JsCtl := JC_NONE;
              P := P^.Next;
            End;
          End;
        End
        Else If (Obj.K = JV_STR) And (N^.Op = 1) Then
        Begin
          I := 0;
          While (I < Obj.L) And (JsCtl = JC_NONE) Do
          Begin
            JvStrAL(V, Obj.P + I, 1);
            If C^.T = JN_DECL Then JsDeclare(JsEnv, C^.P, C^.L, V, 0) Else JsAssign(C, V);
            JsExec(N^.C);
            If JsCtl = JC_BREAK Then
            Begin
              JsCtl := JC_NONE;
              Break;
            End;
            If JsCtl = JC_CONT Then JsCtl := JC_NONE;
            Inc(I);
          End;
        End;
        JsEnv := SaveEnv;
      End;
    JN_RETURN :
      Begin
        JvUndef(JsRet);
        If N^.A <> Nil Then JsEval(N^.A, V) Else JvUndef(V);
        If JsCtl <> JC_NONE Then Exit;
        JsRet := V;
        JsCtl := JC_RET;
      End;
    JN_BREAK : JsCtl := JC_BREAK;
    JN_CONTINUE : JsCtl := JC_CONT;
    JN_THROW :
      Begin
        JsEval(N^.A, V);
        If JsCtl <> JC_NONE Then Exit;
        JsExc := V;
        JsCtl := JC_THROW;
      End;
    JN_TRY :
      Begin
        JsExec(N^.A);
        If (JsCtl = JC_THROW) And Not JsKill And (N^.B <> Nil) Then
        Begin
          JsCtl := JC_NONE;
          SaveEnv := JsEnv;
          JsEnv := JsNewEnv(JsEnv);
          If JsEnv <> Nil Then
          Begin
            If N^.L > 0 Then JsDeclare(JsEnv, N^.P, N^.L, JsExc, 2);
            JsExec(N^.B);
          End;
          JsEnv := SaveEnv;
        End;
        If (N^.C <> Nil) And Not JsKill Then
        Begin
          { finally : toujours execute, puis l'etat precedent reprend }
          CtlSave := JsCtl; ExcSave := JsExc; RetSave := JsRet;
          JsCtl := JC_NONE;
          JsExec(N^.C);
          If JsCtl = JC_NONE Then
          Begin
            JsCtl := CtlSave; JsExc := ExcSave; JsRet := RetSave;
          End;
        End;
      End;
    JN_SWITCH :
      Begin
        JsEval(N^.A, V);
        If JsCtl <> JC_NONE Then Exit;
        Hit := False;
        C := N^.B;
        While (C <> Nil) And Not Hit And (JsCtl = JC_NONE) Do
        Begin
          If C^.Op = 0 Then
          Begin
            JsEval(C^.A, K);
            If JsStrictEq(V, K) Then Hit := True Else C := C^.Next;
          End
          Else C := C^.Next;
        End;
        If Not Hit Then
        Begin
          C := N^.B;
          While (C <> Nil) And (C^.Op = 0) Do C := C^.Next;
        End;
        { execution a partir du cas trouve (passage aux suivants) }
        While (C <> Nil) And (JsCtl = JC_NONE) Do
        Begin
          JsExecList(C^.B);
          C := C^.Next;
        End;
        If JsCtl = JC_BREAK Then JsCtl := JC_NONE;
      End;
  Else
    JsEval(N, V);
  End;
End;

{ ---------------- objets natifs et DOM ---------------- }

Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';

Var
  JsDocObj, JsConObj, JsMathObj, JsJsonObj, JsNavObj, JsLocObj, JsScrObj, JsHistObj, JsStoreObj : PJObj;
  { auditeurs d'evenements (addEventListener) }
  JsLsN : LongInt;
  JsLsNode : Array[0..255] Of PNode;
  JsLsEv : Array[0..255] Of String[15];
  JsLsFn : Array[0..255] Of TJV;
  JsRand : LongInt;

Procedure JsArgStr(Argc, I : LongInt; Var R : TJV);
Var V : TJV;
Begin
  JsArg(Argc, I, V);
  JsToStrV(V, R);
End;

Function JsArgP(Argc, I : LongInt) : String;
Var V : TJV;
Begin
  JsArg(Argc, I, V);
  If V.K = JV_UNDEF Then JsArgP := '' Else JsArgP := JsToPStr(V);
End;

Function JsArgNum(Argc, I : LongInt; Def : Double) : Double;
Var V : TJV;
Begin
  JsArg(Argc, I, V);
  If V.K = JV_UNDEF Then JsArgNum := Def Else JsArgNum := JsToNum(V);
End;

Function JsArgInt(Argc, I, Def : LongInt) : LongInt;
Var V : TJV;
Begin
  JsArg(Argc, I, V);
  If V.K = JV_UNDEF Then JsArgInt := Def Else JsArgInt := JsToInt(V);
End;

{ recherche de B (longueur LB) dans A a partir de From ; -1 si absent }
Function JsFind(A, LA, B, LB, From : LongInt) : LongInt;
Var I, K : LongInt; Ok : Boolean;
Begin
  JsFind := -1;
  If From < 0 Then From := 0;
  For I := From To LA - LB Do
  Begin
    Ok := True;
    For K := 0 To LB - 1 Do
      If RdB(A + I + K) <> RdB(B + K) Then
      Begin
        Ok := False;
        Break;
      End;
    If Ok Then
    Begin
      JsFind := I;
      Exit;
    End;
  End;
End;

Procedure JsSub(Var S : TJV; I, J : LongInt; Var R : TJV);
Begin
  If I < 0 Then I := 0;
  If J > S.L Then J := S.L;
  If J <= I Then JvStrAL(R, 0, 0) Else JvStrAL(R, S.P + I, J - I);
End;

{ copie d'une chaine en changeant la casse }
Procedure JsCase(Var S : TJV; Up : Boolean; Var R : TJV);
Var A, K, C : LongInt;
Begin
  If S.L = 0 Then
  Begin
    R := S;
    Exit;
  End;
  A := ArAlloc(S.L);
  If A = 0 Then
  Begin
    JsAbort('Erreur : memoire de la page epuisee');
    Exit;
  End;
  For K := 0 To S.L - 1 Do
  Begin
    C := RdB(S.P + K);
    If Up And (Chr(C) In ['a'..'z']) Then C := C - 32
    Else If (Not Up) And (Chr(C) In ['A'..'Z']) Then C := C + 32
    Else If C >= 128 Then
    Begin
      { lettres accentuees de la page 437 }
      If Up Then
        Case C Of
          130 : C := 144; 135 : C := 128; 129 : C := 154; 132 : C := 142; 134 : C := 143; 148 : C := 153; 164 : C := 165;
        End
      Else
        Case C Of
          144 : C := 130; 128 : C := 135; 154 : C := 129; 142 : C := 132; 143 : C := 134; 153 : C := 148; 165 : C := 164;
        End;
    End;
    WrB(A + K, C);
  End;
  JvStrAL(R, A, S.L);
End;

Procedure JsSetResultArr(Var R : TJV; O : PJObj);
Begin
  If O = Nil Then JvUndef(R) Else JvObjV(R, O);
End;

{ ---------------- DOM : attributs, texte, serialisation ---------------- }

Procedure JsSetAttr(N : PNode; Nm : String; A, L : LongInt);
Var P : PAttr; D : LongInt;
Begin
  If (N = Nil) Or (N^.Kind <> NODE_ELEM) Then Exit;
  Nm := LowStr(Nm);
  D := 0;
  If L > 0 Then
  Begin
    D := ArAlloc(L);
    If D = 0 Then Exit;
    MemCopy(A, D, L);
  End;
  P := FindAttr(N, Nm);
  If P = Nil Then
  Begin
    P := Pointer(ArAlloc(SizeOf(TAttr)));
    If P = Nil Then Exit;
    P^.Name := Copy(Nm, 1, 31);
    P^.Next := N^.Attr;
    N^.Attr := P;
  End;
  P^.Val := D; P^.VLen := L;
  N^.Css := 0;
  JsDirty := True;
End;

Procedure JsSetAttrS(N : PNode; Nm, V : String);
Var T : TJV;
Begin
  JvStr(T, V);
  JsSetAttr(N, Nm, T.P, T.L);
End;

Procedure JsRemoveAttr(N : PNode; Nm : String);
Var P, Q : PAttr;
Begin
  If N = Nil Then Exit;
  Nm := LowStr(Nm);
  P := N^.Attr; Q := Nil;
  While P <> Nil Do
  Begin
    If P^.Name = Nm Then
    Begin
      If Q = Nil Then N^.Attr := P^.Next Else Q^.Next := P^.Next;
      N^.Css := 0;
      JsDirty := True;
      Exit;
    End;
    Q := P;
    P := P^.Next;
  End;
End;

{ valeur d'attribut (sans limite de longueur) }
Procedure JsGetAttrV(N : PNode; Nm : String; Var R : TJV);
Var P : PAttr;
Begin
  P := FindAttr(N, LowStr(Nm));
  If P = Nil Then R.K := JV_NULL Else JvStrAL(R, P^.Val, P^.VLen);
End;

{ texte d'un sous-arbre (textContent) }
Procedure JsTextOf(N : PNode; Var R : TJV);
Var C : PNode; T : TJV;
Begin
  If N = Nil Then
  Begin
    JvStrAL(R, 0, 0);
    Exit;
  End;
  If N^.Kind = NODE_TEXT Then
  Begin
    JvStrAL(R, N^.Txt, N^.TLen);
    Exit;
  End;
  JvStrAL(R, 0, 0);
  C := N^.First;
  While C <> Nil Do
  Begin
    If (C^.Kind = NODE_TEXT) Or ((C^.Kind = NODE_ELEM) And (C^.Tag <> TAG_SCRIPT) And (C^.Tag <> TAG_STYLE)) Then
    Begin
      JsTextOf(C, T);
      If T.L > 0 Then JsConcat(R, R.P, R.L, T.P, T.L);
    End;
    C := C^.Next;
    If JsKill Then Exit;
  End;
End;

Function JsNodeText(N : PNode) : String;
Var R : TJV;
Begin
  JsTextOf(N, R);
  JsNodeText := ArGet(R.P, R.L);
End;

Procedure JsAppendS(Var R : TJV; S : String);
Var T : TJV;
Begin
  JvStr(T, S);
  JsConcat(R, R.P, R.L, T.P, T.L);
End;

{ texte echappe pour le HTML }
Procedure JsAppendEsc(Var R : TJV; A, L : LongInt; Attr : Boolean);
Var K, S, C : LongInt;
Begin
  S := 0;
  For K := 0 To L - 1 Do
  Begin
    C := RdB(A + K);
    If (C = 60) Or (C = 62) Or (C = 38) Or (Attr And (C = 34)) Then
    Begin
      If K > S Then JsConcat(R, R.P, R.L, A + S, K - S);
      Case C Of
        60 : JsAppendS(R, '&lt;');
        62 : JsAppendS(R, '&gt;');
        38 : JsAppendS(R, '&amp;');
        34 : JsAppendS(R, '&quot;');
      End;
      S := K + 1;
    End;
  End;
  If L > S Then JsConcat(R, R.P, R.L, A + S, L - S);
End;

{ HTML d'un noeud (Self : balises comprises) }
Procedure JsSerialize(N : PNode; Self : Boolean; Var R : TJV);
Var C : PNode; P : PAttr;
Begin
  If (N = Nil) Or JsKill Then Exit;
  If N^.Kind = NODE_TEXT Then
  Begin
    JsAppendEsc(R, N^.Txt, N^.TLen, False);
    Exit;
  End;
  If N^.Kind <> NODE_ELEM Then Exit;
  If Self Then
  Begin
    JsAppendS(R, '<' + N^.Name);
    P := N^.Attr;
    While P <> Nil Do
    Begin
      JsAppendS(R, ' ' + P^.Name + '="');
      JsAppendEsc(R, P^.Val, P^.VLen, True);
      JsAppendS(R, '"');
      P := P^.Next;
    End;
    JsAppendS(R, '>');
    If IsVoid(N^.Name) Then Exit;
  End;
  C := N^.First;
  While C <> Nil Do
  Begin
    JsSerialize(C, True, R);
    C := C^.Next;
  End;
  If Self Then JsAppendS(R, '</' + N^.Name + '>');
End;

{ analyse d'un fragment HTML (A, L) : ses noeuds deviennent les enfants
  de Parent (avant Before, ou a la fin si Before = Nil) }
Procedure JsParseInto(Parent, Before : PNode; A, L : LongInt);
Var SB, SL : LongInt; SRoot, F, C, Nx, Prev : PNode; ST, SR, SBase : String; D : LongInt;
Begin
  If (Parent = Nil) Or (L <= 0) Then Exit;
  { copie : les noeuds texte bruts referencent le tampon analyse }
  D := ArAlloc(L);
  If D = 0 Then Exit;
  MemCopy(A, D, L);
  SB := SrcBuf; SL := SrcLen; SRoot := Root; ST := DocTitle; SR := RefreshUrl; SBase := BaseUrl;
  SrcBuf := D; SrcLen := L;
  ParseDocument;
  F := Root;
  SrcBuf := SB; SrcLen := SL; Root := SRoot; DocTitle := ST; RefreshUrl := SR; BaseUrl := SBase;
  If F = Nil Then Exit;
  { deplacer les enfants du document du fragment }
  C := F^.First;
  { on saute un <html>/<body> implicite s'il n'y en a pas : le parseur ne les cree pas }
  Prev := Nil;
  If Before <> Nil Then
  Begin
    Prev := Parent^.First;
    If Prev = Before Then Prev := Nil
    Else
      While (Prev <> Nil) And (Prev^.Next <> Before) Do Prev := Prev^.Next;
  End
  Else Prev := Parent^.Last;
  While C <> Nil Do
  Begin
    Nx := C^.Next;
    C^.Parent := Parent;
    C^.Next := Before;
    If Prev = Nil Then Parent^.First := C Else Prev^.Next := C;
    If Before = Nil Then Parent^.Last := C;
    Prev := C;
    C := Nx;
  End;
  JsDirty := True;
  JsRescan := True;
End;

Procedure JsClearChildren(N : PNode);
Begin
  N^.First := Nil; N^.Last := Nil;
  JsDirty := True;
End;

Procedure JsDetach(C : PNode);
Var P, Q : PNode;
Begin
  If (C = Nil) Or (C^.Parent = Nil) Then Exit;
  P := C^.Parent;
  If P^.First = C Then
  Begin
    P^.First := C^.Next;
    If P^.Last = C Then P^.Last := Nil;
  End
  Else
  Begin
    Q := P^.First;
    While (Q <> Nil) And (Q^.Next <> C) Do Q := Q^.Next;
    If Q <> Nil Then
    Begin
      Q^.Next := C^.Next;
      If P^.Last = C Then P^.Last := Q;
    End;
  End;
  C^.Parent := Nil; C^.Next := Nil;
  JsDirty := True;
End;

{ ---------------- DOM : recherches ---------------- }

Function JsById(N : PNode; Var Id : TJV) : PNode;
Var C, R : PNode; P : PAttr;
Begin
  JsById := Nil;
  If N = Nil Then Exit;
  If N^.Kind = NODE_ELEM Then
  Begin
    P := FindAttr(N, 'id');
    If (P <> Nil) And JsSame(P^.Val, P^.VLen, Id.P, Id.L) Then
    Begin
      JsById := N;
      Exit;
    End;
  End;
  C := N^.First;
  While C <> Nil Do
  Begin
    R := JsById(C, Id);
    If R <> Nil Then
    Begin
      JsById := R;
      Exit;
    End;
    C := C^.Next;
  End;
End;

{ selecteur simple : "#id", ".classe", "balise", "balise.classe", "[name=x]" ;
  une liste "a, b" ou une descendance "a b" garde la derniere partie }
Function JsMatchSel(N : PNode; Sel : String) : Boolean;
Var Tg, Cl, Id, Nm : String; K : LongInt; A : TJV;
Begin
  JsMatchSel := False;
  If (N = Nil) Or (N^.Kind <> NODE_ELEM) Then Exit;
  Tg := ''; Cl := ''; Id := ''; Nm := '';
  If Pos('[', Sel) > 0 Then
  Begin
    Nm := Copy(Sel, Pos('[', Sel) + 1, 255);
    Sel := Copy(Sel, 1, Pos('[', Sel) - 1);
    If Pos(']', Nm) > 0 Then Nm := Copy(Nm, 1, Pos(']', Nm) - 1);
  End;
  K := Pos('#', Sel);
  If K > 0 Then
  Begin
    Id := Copy(Sel, K + 1, 255);
    Sel := Copy(Sel, 1, K - 1);
    If Pos('.', Id) > 0 Then
    Begin
      Cl := Copy(Id, Pos('.', Id) + 1, 255);
      Id := Copy(Id, 1, Pos('.', Id) - 1);
    End;
  End;
  K := Pos('.', Sel);
  If K > 0 Then
  Begin
    Cl := Copy(Sel, K + 1, 255);
    Sel := Copy(Sel, 1, K - 1);
  End;
  Tg := LowStr(Sel);
  If (Tg <> '') And (Tg <> '*') And (Tg <> N^.Name) Then Exit;
  If (Id <> '') And (GetAttr(N, 'id') <> Id) Then Exit;
  If Cl <> '' Then
  Begin
    If Pos('.', Cl) > 0 Then Cl := Copy(Cl, 1, Pos('.', Cl) - 1);
    If Not HasClass(N, Cl) Then Exit;
  End;
  If Nm <> '' Then
  Begin
    K := Pos('=', Nm);
    If K = 0 Then
    Begin
      If Not HasAttr(N, LowStr(Nm)) Then Exit;
    End
    Else
    Begin
      Id := Copy(Nm, K + 1, 255);
      While (Length(Id) > 0) And (Id[1] In ['"', '''']) Do Delete(Id, 1, 1);
      While (Length(Id) > 0) And (Id[Length(Id)] In ['"', '''']) Do Delete(Id, Length(Id), 1);
      JsGetAttrV(N, LowStr(Copy(Nm, 1, K - 1)), A);
      If (A.K <> JV_STR) Or Not JsSameS(A.P, A.L, Id) Then Exit;
    End;
  End;
  JsMatchSel := True;
End;

{ Mode : 0 balise, 1 classe, 2 selecteur ; Sel : critere ; First : un seul }
Procedure JsCollect(N : PNode; Mode : LongInt; Sel : String; O : PJObj; First : Boolean);
Var C : PNode; Ok : Boolean; V : TJV;
Begin
  C := N^.First;
  While (C <> Nil) And Not JsKill Do
  Begin
    If C^.Kind = NODE_ELEM Then
    Begin
      Case Mode Of
        0 : Ok := (Sel = '*') Or (C^.Name = Sel);
        1 : Ok := HasClass(C, Sel);
      Else
        Ok := JsMatchSel(C, Sel);
      End;
      If Ok Then
      Begin
        JvNode(V, C);
        JsArrPush(O, V);
        If First Then Exit;
      End;
      JsCollect(C, Mode, Sel, O, First);
      If First And (O^.Len > 0) Then Exit;
    End;
    C := C^.Next;
  End;
End;

Function JsSelLast(S : String) : String;
Var K : LongInt;
Begin
  S := TrimS(S);
  K := Pos(',', S);
  If K > 0 Then S := TrimS(Copy(S, 1, K - 1));
  While Pos('>', S) > 0 Do S[Pos('>', S)] := ' ';
  S := TrimS(S);
  While Pos(' ', S) > 0 Do Delete(S, 1, Pos(' ', S));
  JsSelLast := S;
End;

Procedure JsQuery(N : PNode; Sel : String; All : Boolean; Var R : TJV);
Var O : PJObj;
Begin
  O := JsNewArr;
  If (O <> Nil) And (N <> Nil) Then JsCollect(N, 2, JsSelLast(Sel), O, Not All);
  If All Then JsSetResultArr(R, O)
  Else If (O <> Nil) And (O^.Len > 0) Then JsArrGet(O, 0, R)
  Else R.K := JV_NULL;
End;

{ ---------------- DOM : styles en ligne ---------------- }

{ backgroundColor -> background-color }
Function JsCssName(S : String) : String;
Var R : String; K : LongInt;
Begin
  R := '';
  For K := 1 To Length(S) Do
    If S[K] In ['A'..'Z'] Then R := R + '-' + Chr(Ord(S[K]) + 32) Else R := R + S[K];
  If R = 'css-float' Then R := 'float';
  JsCssName := R;
End;

{ valeur d'une propriete dans l'attribut style }
Function JsStyleGet(N : PNode; Prop : String) : String;
Var S, D, P, V : String; K : LongInt;
Begin
  JsStyleGet := '';
  S := GetAttr(N, 'style');
  While S <> '' Do
  Begin
    K := Pos(';', S);
    If K = 0 Then K := Length(S) + 1;
    D := Copy(S, 1, K - 1);
    Delete(S, 1, K);
    If Pos(':', D) > 0 Then
    Begin
      P := LowStr(TrimS(Copy(D, 1, Pos(':', D) - 1)));
      V := TrimS(Copy(D, Pos(':', D) + 1, 255));
      If P = Prop Then JsStyleGet := V;
    End;
  End;
End;

Procedure JsStyleSet(N : PNode; Prop, Val : String);
Var S, D, P, R : String; K : LongInt;
Begin
  S := GetAttr(N, 'style');
  R := '';
  While S <> '' Do
  Begin
    K := Pos(';', S);
    If K = 0 Then K := Length(S) + 1;
    D := TrimS(Copy(S, 1, K - 1));
    Delete(S, 1, K);
    If Pos(':', D) > 0 Then
    Begin
      P := LowStr(TrimS(Copy(D, 1, Pos(':', D) - 1)));
      If (P <> Prop) And (Length(R) + Length(D) < 230) Then R := R + D + '; ';
    End;
  End;
  If Val <> '' Then R := R + Prop + ': ' + Val;
  JsSetAttrS(N, 'style', R);
End;

{ ---------------- DOM : evenements ---------------- }

Procedure JsAddListener(N : PNode; Ev : String; Var F : TJV);
Var K : LongInt;
Begin
  For K := 0 To JsLsN - 1 Do
    If (JsLsNode[K] = N) And (JsLsEv[K] = Ev) And JsStrictEq(JsLsFn[K], F) Then Exit;
  If JsLsN > 255 Then Exit;
  JsLsNode[JsLsN] := N; JsLsEv[JsLsN] := Copy(Ev, 1, 15); JsLsFn[JsLsN] := F;
  Inc(JsLsN);
End;

Procedure JsRemoveListener(N : PNode; Ev : String; Var F : TJV);
Var K, J : LongInt;
Begin
  For K := 0 To JsLsN - 1 Do
    If (JsLsNode[K] = N) And (JsLsEv[K] = Ev) And JsStrictEq(JsLsFn[K], F) Then
    Begin
      For J := K To JsLsN - 2 Do
      Begin
        JsLsNode[J] := JsLsNode[J + 1]; JsLsEv[J] := JsLsEv[J + 1]; JsLsFn[J] := JsLsFn[J + 1];
      End;
      Dec(JsLsN);
      Exit;
    End;
End;

{ ---------------- Date ---------------- }

Function JsDaysFrom1970(Y, M, D : LongInt) : LongInt;
Var Days, K : LongInt;
Const Mdays : Array[1..12] Of LongInt = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
Begin
  Days := 0;
  For K := 1970 To Y - 1 Do
    If ((K Mod 4 = 0) And (K Mod 100 <> 0)) Or (K Mod 400 = 0) Then Days := Days + 366 Else Days := Days + 365;
  For K := 1 To M - 1 Do
  Begin
    Days := Days + Mdays[K];
    If (K = 2) And (((Y Mod 4 = 0) And (Y Mod 100 <> 0)) Or (Y Mod 400 = 0)) Then Inc(Days);
  End;
  JsDaysFrom1970 := Days + D - 1;
End;

{ millisecondes depuis 1970 (heure locale du systeme) }
Function JsNow : Double;
Var B : Array[0..15] Of Byte; Y : LongInt;
Begin
  Dummy := DosGetDateTime(LongInt(@B));
  Y := B[6] + B[7] * 256;
  If Y < 1970 Then Y := 1970;
  JsNow := (JsDaysFrom1970(Y, MaxI(1, B[5]), MaxI(1, B[4])) * 86400.0 + B[0] * 3600.0 + B[1] * 60.0 + B[2]) * 1000.0 +
           B[3] * 10.0;
End;

{ ms -> champs : annee, mois (0..11), jour, heures, minutes, secondes, jour de semaine }
Procedure JsDateFields(T : Double; Var Y, Mo, D, H, Mi, S, Wd : LongInt);
Var Days, Dim : LongInt; Rest : Double;
Const Mdays : Array[1..12] Of LongInt = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
Begin
  Days := Trunc(JsFTrunc(T / 86400000.0));
  Rest := T - Days * 86400000.0;
  If Rest < 0 Then
  Begin
    Dec(Days);
    Rest := Rest + 86400000.0;
  End;
  Wd := (Days + 4) Mod 7;
  If Wd < 0 Then Wd := Wd + 7;
  Y := 1970;
  While True Do
  Begin
    If ((Y Mod 4 = 0) And (Y Mod 100 <> 0)) Or (Y Mod 400 = 0) Then Dim := 366 Else Dim := 365;
    If Days < Dim Then Break;
    Days := Days - Dim;
    Inc(Y);
  End;
  Mo := 1;
  While Mo < 12 Do
  Begin
    Dim := Mdays[Mo];
    If (Mo = 2) And (((Y Mod 4 = 0) And (Y Mod 100 <> 0)) Or (Y Mod 400 = 0)) Then Inc(Dim);
    If Days < Dim Then Break;
    Days := Days - Dim;
    Inc(Mo);
  End;
  Dec(Mo);
  D := Days + 1;
  S := Trunc(Rest / 1000);
  H := S Div 3600; Mi := (S Div 60) Mod 60; S := S Mod 60;
End;

Function Z2s(V : LongInt) : String;
Begin
  If V < 10 Then Z2s := '0' + IStr(V) Else Z2s := IStr(V);
End;

{ ---------------- JSON ---------------- }

Procedure JsJsonOf(Var V : TJV; Var R : TJV; Depth : LongInt);
Var O : PJObj; K : LongInt; E : TJV; P : PJProp; First : Boolean;
Begin
  If Depth > 20 Then
  Begin
    JsAppendS(R, 'null');
    Exit;
  End;
  Case V.K Of
    JV_NULL, JV_UNDEF, JV_FUN, JV_NAT : JsAppendS(R, 'null');
    JV_BOOL : If V.N <> 0 Then JsAppendS(R, 'true') Else JsAppendS(R, 'false');
    JV_NUM : If JsIsNaN(V.N) Then JsAppendS(R, 'null') Else JsAppendS(R, JsNumStr(V.N));
    JV_STR :
      Begin
        JsAppendS(R, '"');
        For K := 0 To V.L - 1 Do
        Begin
          Case RdB(V.P + K) Of
            34 : JsAppendS(R, '\"');
            92 : JsAppendS(R, '\\');
            10 : JsAppendS(R, '\n');
            13 : JsAppendS(R, '\r');
            9 : JsAppendS(R, '\t');
          Else
            JsConcat(R, R.P, R.L, V.P + K, 1);
          End;
        End;
        JsAppendS(R, '"');
      End;
    JV_OBJ :
      Begin
        O := Pointer(V.P);
        If O^.IsArr Then
        Begin
          JsAppendS(R, '[');
          For K := 0 To O^.Len - 1 Do
          Begin
            If K > 0 Then JsAppendS(R, ',');
            JsArrGet(O, K, E);
            JsJsonOf(E, R, Depth + 1);
          End;
          JsAppendS(R, ']');
        End
        Else
        Begin
          JsAppendS(R, '{');
          P := O^.Props; First := True;
          While P <> Nil Do
          Begin
            If (P^.V.K <> JV_UNDEF) And (P^.V.K <> JV_FUN) Then
            Begin
              If Not First Then JsAppendS(R, ',');
              First := False;
              JvStrAL(E, P^.P, P^.L);
              JsJsonOf(E, R, Depth + 1);
              JsAppendS(R, ':');
              JsJsonOf(P^.V, R, Depth + 1);
            End;
            P := P^.Next;
          End;
          JsAppendS(R, '}');
        End;
      End;
  Else
    JsAppendS(R, '{}');
  End;
End;

{ ---------------- execution de code (chaines) ---------------- }

{ texte (A, L) : analyse et execution dans la portee globale ; Last :
  valeur de la derniere expression (console, eval) ; faux si erreur }
Function JsRunCode(A, L, Line0 : LongInt; Var ThisV : TJV; Var Last : TJV) : Boolean;
Var Prog, S : PJN; SaveEnv : PJEnv; SaveThis : TJV; SJs, SJl, SJp, SLn, STt, STp, STl, SNl : LongInt;
    STn : Double; STs : String; SNL2 : Boolean;
Begin
  JsRunCode := False;
  JvUndef(Last);
  { l'analyseur est reentrant pour eval() : sauvegarde de son etat }
  SJs := JsSrc; SJl := JsLen; SJp := JsPos; SLn := JsLine;
  STt := JTokT; STp := JTokP; STl := JTokL; STn := JTokN; STs := JTokS; SNl := JTokLine; SNL2 := JTokNL;
  Prog := JParseProgram(A, L, Line0);
  JsSrc := SJs; JsLen := SJl; JsPos := SJp; JsLine := SLn;
  JTokT := STt; JTokP := STp; JTokL := STl; JTokN := STn; JTokS := STs; JTokLine := SNl; JTokNL := SNL2;
  If (Prog = Nil) Or JsErr Then
  Begin
    If JsErr Then
    Begin
      JsLastErr := JsErrMsg + ' (ligne ' + IStr(JsErrLine) + ')';
      JsConsole(JsLastErr, 1);
      Inc(JsErrCount);
      JsErr := False;
    End;
    Exit;
  End;
  SaveEnv := JsEnv; SaveThis := JsThis;
  JsEnv := JsGlobal;
  JsThis := ThisV;
  JsHoist(Prog^.A);
  S := Prog^.A;
  While (S <> Nil) And (JsCtl = JC_NONE) Do
  Begin
    If (S^.T = JN_EXPR) And (S^.Next = Nil) Then JsEval(S^.A, Last)
    Else JsExec(S);
    S := S^.Next;
  End;
  JsEnv := SaveEnv; JsThis := SaveThis;
  JsRunCode := JsCtl <> JC_THROW;
End;

{ ---------------- fonctions globales ---------------- }

Procedure JsTimerAdd(Var F : TJV; Ms : LongInt; Every : Boolean; Var R : TJV);
Var K : LongInt;
Begin
  JvNum(R, 0);
  For K := 0 To JS_MAXTIMERS - 1 Do
    If Not JsTmUsed[K] Then
    Begin
      JsTmUsed[K] := True;
      If Ms < 10 Then Ms := 10;
      JsTmAt[K] := KTicks + Ms;
      If Every Then JsTmEvery[K] := Ms Else JsTmEvery[K] := 0;
      Inc(JsTmNext);
      JsTmId[K] := JsTmNext;
      JsTmFn[K] := F;
      JvNum(R, JsTmNext);
      Exit;
    End;
  JsConsole('Avertissement : trop de minuteurs (' + IStr(JS_MAXTIMERS) + ')', 4);
End;

Procedure JsTimerClear(Id : LongInt);
Var K : LongInt;
Begin
  For K := 0 To JS_MAXTIMERS - 1 Do
    If JsTmUsed[K] And (JsTmId[K] = Id) Then JsTmUsed[K] := False;
End;

{ encodeURIComponent (Comp) / encodeURI : UTF-8 %XX }
Procedure JsEncodeUri(Var S : TJV; Comp : Boolean; Var R : TJV);
Var K, C, U : LongInt; Keep : String;
Begin
  JvStrAL(R, 0, 0);
  If Comp Then Keep := '-_.!~*''()' Else Keep := '-_.!~*''();/?:@&=+$,#';
  For K := 0 To S.L - 1 Do
  Begin
    C := RdB(S.P + K);
    If (Chr(C) In ['A'..'Z', 'a'..'z', '0'..'9']) Or ((C < 128) And (Pos(Chr(C), Keep) > 0)) Then
      JsConcat(R, R.P, R.L, S.P + K, 1)
    Else If C < 128 Then JsAppendS(R, '%' + HexCh(C Shr 4) + HexCh(C And 15))
    Else
    Begin
      U := CpToUni(C);
      If U < $800 Then
        JsAppendS(R, '%' + HexCh((($C0 Or (U Shr 6)) Shr 4) And 15) + HexCh(($C0 Or (U Shr 6)) And 15) +
                     '%' + HexCh((($80 Or (U And 63)) Shr 4) And 15) + HexCh(($80 Or (U And 63)) And 15))
      Else
        JsAppendS(R, '%' + HexCh((($E0 Or (U Shr 12)) Shr 4) And 15) + HexCh(($E0 Or (U Shr 12)) And 15) +
                     '%' + HexCh((($80 Or ((U Shr 6) And 63)) Shr 4) And 15) + HexCh(($80 Or ((U Shr 6) And 63)) And 15) +
                     '%' + HexCh((($80 Or (U And 63)) Shr 4) And 15) + HexCh(($80 Or (U And 63)) And 15));
    End;
  End;
End;

Procedure JsDecodeUri(Var S : TJV; Var R : TJV);
Var K, C, U, N : LongInt; A : LongInt;
Begin
  A := ArAlloc(S.L + 1);
  If A = 0 Then
  Begin
    R := S;
    Exit;
  End;
  K := 0; N := 0;
  While K < S.L Do
  Begin
    C := RdB(S.P + K);
    If (C = 37) And (K + 2 < S.L) Then
    Begin
      C := HexDigit(Chr(RdB(S.P + K + 1))) * 16 + HexDigit(Chr(RdB(S.P + K + 2)));
      K := K + 3;
      If (C And $E0) = $C0 Then
      Begin
        U := C And $1F;
        If (K + 2 < S.L) And (RdB(S.P + K) = 37) Then
        Begin
          U := (U Shl 6) Or ((HexDigit(Chr(RdB(S.P + K + 1))) * 16 + HexDigit(Chr(RdB(S.P + K + 2)))) And 63);
          K := K + 3;
        End;
        C := UniToCp(U);
      End
      Else If (C And $F0) = $E0 Then
      Begin
        U := C And $0F;
        While (K + 2 < S.L) And (RdB(S.P + K) = 37) And
              (((HexDigit(Chr(RdB(S.P + K + 1))) * 16 + HexDigit(Chr(RdB(S.P + K + 2)))) And $C0) = $80) Do
        Begin
          U := (U Shl 6) Or ((HexDigit(Chr(RdB(S.P + K + 1))) * 16 + HexDigit(Chr(RdB(S.P + K + 2)))) And 63);
          K := K + 3;
        End;
        C := UniToCp(U);
      End;
    End
    Else Inc(K);
    WrB(A + N, C);
    Inc(N);
  End;
  JvStrAL(R, A, N);
End;

Procedure JsDateNew(Argc : LongInt; Var R : TJV);
Var O : PJObj; V : TJV; Y, Mo, D, H, Mi, S : LongInt;
Begin
  O := JsNewObj;
  If O = Nil Then Exit;
  O^.Cls := JO_DATE;
  If Argc = 0 Then O^.Num := JsNow
  Else If Argc = 1 Then
  Begin
    JsArg(Argc, 0, V);
    If V.K = JV_NUM Then O^.Num := V.N Else O^.Num := JsNaN;
  End
  Else
  Begin
    Y := JsArgInt(Argc, 0, 1970); Mo := JsArgInt(Argc, 1, 0); D := JsArgInt(Argc, 2, 1);
    H := JsArgInt(Argc, 3, 0); Mi := JsArgInt(Argc, 4, 0); S := JsArgInt(Argc, 5, 0);
    While Mo > 11 Do
    Begin
      Mo := Mo - 12; Inc(Y);
    End;
    O^.Num := (JsDaysFrom1970(Y, Mo + 1, MaxI(1, D)) * 86400.0 + H * 3600.0 + Mi * 60.0 + S) * 1000.0;
  End;
  JvObjV(R, O);
End;

Procedure JsShowAlert(S : String);
Begin
  If JsAlertN < 8 Then
  Begin
    JsAlerts[JsAlertN] := S;
    Inc(JsAlertN);
  End;
End;

Procedure JsCallNative(Id : String; Var ThisV : TJV; Argc : LongInt; Var R : TJV);
Var V, S : TJV; D : Double; K, Rad, C : LongInt; O : PJObj; IsNew : Boolean; T : String; Nn : PNode;
Begin
  JvUndef(R);
  IsNew := (ThisV.K = JV_STR) And JsSameS(ThisV.P, ThisV.L, 'new');
  If Id = 'alert' Then
  Begin
    JsShowAlert(JsArgP(Argc, 0));
    JsConsole('alert : ' + JsArgP(Argc, 0), 0);
  End
  Else If Id = 'confirm' Then
  Begin
    { boite de message de PM, maintenant (le script attend la reponse) }
    JvBool(R, WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, Z(Copy(JsArgP(Argc, 0), 1, 250)), Z2('Confirmation (page Web)'),
                            0, MB_YESNO Or MB_QUERY Or MB_MOVEABLE) = MBID_YES);
  End
  Else If Id = 'prompt' Then R.K := JV_NULL
  Else If Id = 'parseInt' Then
  Begin
    JsArgStr(Argc, 0, S);
    Rad := JsArgInt(Argc, 1, 10);
    K := 0;
    While (K < S.L) And (RdB(S.P + K) <= 32) Do Inc(K);
    D := 1;
    If (K < S.L) And ((RdB(S.P + K) = 45) Or (RdB(S.P + K) = 43)) Then
    Begin
      If RdB(S.P + K) = 45 Then D := -1;
      Inc(K);
    End;
    If ((Rad = 16) Or (Rad = 0)) And (K + 1 < S.L) And (RdB(S.P + K) = 48) And ((RdB(S.P + K + 1) Or $20) = 120) Then
    Begin
      Rad := 16; K := K + 2;
    End;
    If Rad = 0 Then Rad := 10;
    V.N := 0; C := 0;
    While K < S.L Do
    Begin
      Rad := Rad;
      If Chr(RdB(S.P + K)) In ['0'..'9'] Then T := Chr(RdB(S.P + K))
      Else T := Chr(RdB(S.P + K) Or $20);
      If T[1] In ['0'..'9'] Then C := Ord(T[1]) - 48
      Else If T[1] In ['a'..'z'] Then C := Ord(T[1]) - 87
      Else Break;
      If C >= Rad Then Break;
      V.N := V.N * Rad + C;
      Inc(K);
      Rad := Rad;
    End;
    If (K = 0) Or ((V.N = 0) And Not (Chr(RdB(S.P + MaxI(0, K - 1))) In ['0'..'9', 'a'..'z', 'A'..'Z'])) Then JvNum(R, JsNaN)
    Else JvNum(R, V.N * D);
  End
  Else If Id = 'parseFloat' Then
  Begin
    JsArgStr(Argc, 0, S);
    { prefixe numerique le plus long }
    K := 0;
    While (K < S.L) And (RdB(S.P + K) <= 32) Do Inc(K);
    C := K;
    If (C < S.L) And (RdB(S.P + C) In [43, 45]) Then Inc(C);
    While (C < S.L) And (Chr(RdB(S.P + C)) In ['0'..'9', '.', 'e', 'E']) Do Inc(C);
    JvNum(R, JsParseNum(S.P + K, C - K, False));
  End
  Else If Id = 'isNaN' Then JvBool(R, JsIsNaN(JsArgNum(Argc, 0, JsNaN)))
  Else If Id = 'isFinite' Then
  Begin
    D := JsArgNum(Argc, 0, JsNaN);
    JvBool(R, Not JsIsNaN(D) And (D <> JsInf) And (D <> -JsInf));
  End
  Else If (Id = 'setTimeout') Or (Id = 'setInterval') Then
  Begin
    JsArg(Argc, 0, V);
    JsTimerAdd(V, JsArgInt(Argc, 1, 0), Id = 'setInterval', R);
  End
  Else If (Id = 'clearTimeout') Or (Id = 'clearInterval') Then JsTimerClear(JsArgInt(Argc, 0, 0))
  Else If Id = 'String' Then
  Begin
    If Argc = 0 Then JvStrAL(R, 0, 0) Else JsArgStr(Argc, 0, R);
  End
  Else If Id = 'Number' Then
  Begin
    If Argc = 0 Then JvNum(R, 0) Else JvNum(R, JsArgNum(Argc, 0, 0));
  End
  Else If Id = 'Boolean' Then
  Begin
    JsArg(Argc, 0, V);
    JvBool(R, JsToBool(V));
  End
  Else If Id = 'Array' Then
  Begin
    O := JsNewArr;
    JsArg(Argc, 0, V);
    If (Argc = 1) And (V.K = JV_NUM) Then
    Begin
      JvUndef(S);
      If (V.N > 0) And (V.N < 100000) Then JsArrSet(O, Trunc(V.N) - 1, S);
    End
    Else
      For K := 0 To Argc - 1 Do
      Begin
        JsArg(Argc, K, V);
        JsArrPush(O, V);
      End;
    JsSetResultArr(R, O);
  End
  Else If Id = 'Object' Then
  Begin
    JsArg(Argc, 0, V);
    If V.K = JV_OBJ Then R := V
    Else
    Begin
      O := JsNewObj;
      If O <> Nil Then JvObjV(R, O);
    End;
  End
  Else If Id = 'Date' Then
  Begin
    If IsNew Then JsDateNew(Argc, R)
    Else
    Begin
      JsDateNew(0, V);
      JsToStrV(V, R);
    End;
  End
  Else If (Id = 'Error') Or (Id = 'TypeError') Or (Id = 'RangeError') Or (Id = 'SyntaxError') Or (Id = 'ReferenceError') Then
  Begin
    O := JsNewObj;
    If O <> Nil Then
    Begin
      O^.Cls := JO_ERROR;
      JsArgStr(Argc, 0, V);
      JsSetPropS(O, 'message', V);
      JvStr(V, Id);
      JsSetPropS(O, 'name', V);
      JvObjV(R, O);
    End;
  End
  Else If Id = 'Image' Then
  Begin
    { new Image(largeur, hauteur) : element <img> hors du document }
    R.K := JV_NULL;
    Nn := NewNode(NODE_ELEM);
    If Nn <> Nil Then
    Begin
      Nn^.Name := 'img';
      Nn^.Tag := TagOf('img');
      If Argc > 0 Then JsSetAttrS(Nn, 'width', JsIntStr(JsArgNum(Argc, 0, 0)));
      If Argc > 1 Then JsSetAttrS(Nn, 'height', JsIntStr(JsArgNum(Argc, 1, 0)));
      JvNode(R, Nn);
    End;
  End
  Else If Id = 'encodeURIComponent' Then
  Begin
    JsArgStr(Argc, 0, S);
    JsEncodeUri(S, True, R);
  End
  Else If (Id = 'encodeURI') Or (Id = 'escape') Then
  Begin
    JsArgStr(Argc, 0, S);
    JsEncodeUri(S, Id = 'escape', R);
  End
  Else If (Id = 'decodeURIComponent') Or (Id = 'decodeURI') Or (Id = 'unescape') Then
  Begin
    JsArgStr(Argc, 0, S);
    JsDecodeUri(S, R);
  End
  Else If Id = 'eval' Then
  Begin
    JsArg(Argc, 0, V);
    If V.K <> JV_STR Then R := V
    Else
    Begin
      JvUndef(S);
      Dummy := Ord(JsRunCode(V.P, V.L, 1, S, R));
    End;
  End
  Else If Id = 'Promise' Then JvUndef(R)
  Else JsThrowMsg('TypeError: ' + Id + ' n''est pas une fonction');
End;

{ ---------------- proprietes ---------------- }

Function JsIsGlobalFn(A, L : LongInt) : Boolean;
Var S : String;
Begin
  JsIsGlobalFn := False;
  If (L < 4) Or (L > 18) Then Exit;
  S := ArGet(A, L);
  JsIsGlobalFn := (S = 'alert') Or (S = 'confirm') Or (S = 'prompt') Or (S = 'parseInt') Or (S = 'parseFloat') Or
                  (S = 'isNaN') Or (S = 'isFinite') Or (S = 'setTimeout') Or (S = 'setInterval') Or
                  (S = 'clearTimeout') Or (S = 'clearInterval') Or (S = 'String') Or (S = 'Number') Or
                  (S = 'Boolean') Or (S = 'Array') Or (S = 'Object') Or (S = 'Date') Or (S = 'Error') Or
                  (S = 'TypeError') Or (S = 'RangeError') Or (S = 'SyntaxError') Or (S = 'ReferenceError') Or
                  (S = 'encodeURIComponent') Or (S = 'decodeURIComponent') Or (S = 'encodeURI') Or (S = 'decodeURI') Or
                  (S = 'escape') Or (S = 'unescape') Or (S = 'eval') Or (S = 'Promise');
End;

{ proprietes d'un element du DOM }
Procedure JsNodeGet(N : PNode; Nm : String; Var R : TJV);
Var K : LongInt; O : PJObj; C : PNode; V : TJV;
Begin
  JvUndef(R);
  If Nm = 'nodeType' Then
  Begin
    If N^.Kind = NODE_TEXT Then JvNum(R, 3) Else JvNum(R, 1);
  End
  Else If (Nm = 'tagName') Or (Nm = 'nodeName') Then
  Begin
    If N^.Kind = NODE_TEXT Then JvStr(R, '#text') Else JvStr(R, UpStr(N^.Name));
  End
  Else If (Nm = 'textContent') Or (Nm = 'innerText') Or (Nm = 'nodeValue') Or (Nm = 'data') Then JsTextOf(N, R)
  Else If Nm = 'innerHTML' Then
  Begin
    JvStrAL(R, 0, 0);
    JsSerialize(N, False, R);
  End
  Else If Nm = 'outerHTML' Then
  Begin
    JvStrAL(R, 0, 0);
    JsSerialize(N, True, R);
  End
  Else If Nm = 'id' Then
  Begin
    JsGetAttrV(N, 'id', R);
    If R.K = JV_NULL Then JvStrAL(R, 0, 0);
  End
  Else If Nm = 'className' Then
  Begin
    JsGetAttrV(N, 'class', R);
    If R.K = JV_NULL Then JvStrAL(R, 0, 0);
  End
  Else If Nm = 'parentNode' Then JvNode(R, N^.Parent)
  Else If Nm = 'parentElement' Then JvNode(R, N^.Parent)
  Else If (Nm = 'firstChild') Or (Nm = 'firstElementChild') Then
  Begin
    C := N^.First;
    If Nm = 'firstElementChild' Then
      While (C <> Nil) And (C^.Kind <> NODE_ELEM) Do C := C^.Next;
    JvNode(R, C);
  End
  Else If Nm = 'lastChild' Then JvNode(R, N^.Last)
  Else If (Nm = 'nextSibling') Or (Nm = 'nextElementSibling') Then
  Begin
    C := N^.Next;
    If Nm = 'nextElementSibling' Then
      While (C <> Nil) And (C^.Kind <> NODE_ELEM) Do C := C^.Next;
    JvNode(R, C);
  End
  Else If (Nm = 'childNodes') Or (Nm = 'children') Then
  Begin
    O := JsNewArr;
    C := N^.First;
    While (C <> Nil) And (O <> Nil) Do
    Begin
      If (Nm = 'childNodes') Or (C^.Kind = NODE_ELEM) Then
      Begin
        JvNode(V, C);
        JsArrPush(O, V);
      End;
      C := C^.Next;
    End;
    JsSetResultArr(R, O);
  End
  Else If Nm = 'style' Then
  Begin
    O := JsNewObj;
    If O <> Nil Then
    Begin
      O^.Cls := JO_STYLE; O^.Node := N;
      JvObjV(R, O);
    End;
  End
  Else If Nm = 'classList' Then
  Begin
    O := JsNewObj;
    If O <> Nil Then
    Begin
      O^.Cls := JO_CLASSLIST; O^.Node := N;
      JvObjV(R, O);
    End;
  End
  Else If (Nm = 'value') Or (Nm = 'checked') Or (Nm = 'selectedIndex') Then
  Begin
    K := N^.Aux - 1;
    If (K >= 0) And (K < NCtls) And (CtNode[K] = N) Then
    Begin
      If Nm = 'checked' Then JvBool(R, CtChk[K])
      Else If Nm = 'selectedIndex' Then JvNum(R, CtSel[K])
      Else If CtType[K] = CT_SELECT Then JvStr(R, OptValue(N, CtSel[K]))
      Else JvStr(R, CtVal[K]);
    End
    Else If Nm = 'value' Then
    Begin
      JsGetAttrV(N, 'value', R);
      If R.K = JV_NULL Then JvStrAL(R, 0, 0);
    End
    Else JvBool(R, HasAttr(N, 'checked'));
  End
  Else If (Nm = 'href') Or (Nm = 'src') Or (Nm = 'action') Then
  Begin
    If HasAttr(N, Nm) Then JvStr(R, ResolveUrl(BaseUrl, GetAttr(N, Nm))) Else JvStrAL(R, 0, 0);
  End
  Else If (Nm = 'title') Or (Nm = 'alt') Or (Nm = 'name') Or (Nm = 'type') Or (Nm = 'lang') Or (Nm = 'dir') Or
          (Nm = 'method') Or (Nm = 'target') Or (Nm = 'rel') Or (Nm = 'placeholder') Then
  Begin
    JsGetAttrV(N, Nm, R);
    If R.K = JV_NULL Then JvStrAL(R, 0, 0);
  End
  Else If ((Nm = 'width') Or (Nm = 'height')) And (N^.Tag In [TAG_IMG, TAG_CANVAS]) Then
    JvNum(R, SVal(GetAttr(N, Nm), 0))
  Else If Nm = 'disabled' Then JvBool(R, HasAttr(N, 'disabled'))
  Else If (Nm = 'offsetWidth') Or (Nm = 'clientWidth') Or (Nm = 'scrollWidth') Then JvNum(R, JsViewW)
  Else If (Nm = 'offsetHeight') Or (Nm = 'clientHeight') Or (Nm = 'scrollHeight') Then JvNum(R, 20)
  Else If (Nm = 'offsetLeft') Or (Nm = 'offsetTop') Or (Nm = 'scrollTop') Or (Nm = 'scrollLeft') Then JvNum(R, 0)
  Else If (Nm = 'length') And (N^.Tag = TAG_SELECT) Then JvNum(R, OptCount(N))
  Else If (Copy(Nm, 1, 2) = 'on') And HasAttr(N, Nm) Then JsGetAttrV(N, Nm, R)
  Else If Nm = 'ownerDocument' Then JvObjV(R, JsDocObj);
End;

Procedure JsNodeSet(N : PNode; Nm : String; Var V : TJV);
Var K : LongInt; S : TJV;
Begin
  If (Nm = 'innerHTML') Or (Nm = 'outerHTML') Then
  Begin
    JsToStrV(V, S);
    If Nm = 'innerHTML' Then
    Begin
      JsClearChildren(N);
      JsParseInto(N, Nil, S.P, S.L);
    End
    Else If N^.Parent <> Nil Then
    Begin
      JsParseInto(N^.Parent, N, S.P, S.L);
      JsDetach(N);
    End;
  End
  Else If (Nm = 'textContent') Or (Nm = 'innerText') Or (Nm = 'nodeValue') Or (Nm = 'data') Then
  Begin
    JsToStrV(V, S);
    If N^.Kind = NODE_TEXT Then
    Begin
      N^.Txt := S.P; N^.TLen := S.L;
    End
    Else
    Begin
      JsClearChildren(N);
      AppendChild(N, NewNode(NODE_TEXT));
      If N^.Last <> Nil Then
      Begin
        N^.Last^.Txt := S.P; N^.Last^.TLen := S.L;
      End;
    End;
    JsDirty := True;
  End
  Else If Nm = 'id' Then
  Begin
    JsToStrV(V, S);
    JsSetAttr(N, 'id', S.P, S.L);
  End
  Else If Nm = 'className' Then
  Begin
    JsToStrV(V, S);
    JsSetAttr(N, 'class', S.P, S.L);
  End
  Else If (Nm = 'value') Or (Nm = 'checked') Or (Nm = 'selectedIndex') Then
  Begin
    K := N^.Aux - 1;
    If (K >= 0) And (K < NCtls) And (CtNode[K] = N) Then
    Begin
      If Nm = 'checked' Then CtChk[K] := JsToBool(V)
      Else If Nm = 'selectedIndex' Then CtSel[K] := MaxI(0, JsToInt(V))
      Else CtVal[K] := JsToPStr(V);
      JsDirty := True;
    End
    Else
    Begin
      JsToStrV(V, S);
      JsSetAttr(N, Nm, S.P, S.L);
    End;
  End
  Else If Nm = 'disabled' Then
  Begin
    If JsToBool(V) Then JsSetAttrS(N, 'disabled', 'disabled') Else JsRemoveAttr(N, 'disabled');
  End
  Else If Nm = 'style' Then
  Begin
    JsToStrV(V, S);
    JsSetAttr(N, 'style', S.P, S.L);
  End
  Else If (Copy(Nm, 1, 2) = 'on') And ((V.K = JV_FUN) Or (V.K = JV_NAT)) Then
    JsAddListener(N, Copy(Nm, 3, 15), V)
  Else If (Copy(Nm, 1, 2) = 'on') And (V.K = JV_STR) Then JsSetAttr(N, Nm, V.P, V.L)
  Else If (Nm = 'href') Or (Nm = 'src') Or (Nm = 'title') Or (Nm = 'alt') Or (Nm = 'name') Or (Nm = 'type') Or
          (Nm = 'action') Or (Nm = 'method') Or (Nm = 'target') Or (Nm = 'placeholder') Or
          (((Nm = 'width') Or (Nm = 'height')) And (N^.Tag In [TAG_IMG, TAG_CANVAS])) Then
  Begin
    JsToStrV(V, S);
    JsSetAttr(N, Nm, S.P, S.L);
    If Nm = 'src' Then JsRescan := True;
  End;
End;

{ location : parties de l'adresse }
Procedure JsLocGet(Nm : String; Var R : TJV);
Var U, H : String; K : LongInt;
Begin
  U := JsPageUrl;
  If Nm = 'href' Then JvStr(R, U)
  Else If Nm = 'protocol' Then
  Begin
    If Pos(':', U) > 0 Then JvStr(R, Copy(U, 1, Pos(':', U))) Else JvStr(R, '');
  End
  Else If (Nm = 'host') Or (Nm = 'hostname') Or (Nm = 'origin') Or (Nm = 'pathname') Or (Nm = 'port') Then
  Begin
    H := '';
    If Pos('://', U) > 0 Then H := Copy(U, Pos('://', U) + 3, 255);
    K := Pos('/', H);
    If Nm = 'pathname' Then
    Begin
      If K > 0 Then H := Copy(H, K, 255) Else H := '/';
      If Pos('?', H) > 0 Then H := Copy(H, 1, Pos('?', H) - 1);
      If Pos('#', H) > 0 Then H := Copy(H, 1, Pos('#', H) - 1);
      JvStr(R, H);
      Exit;
    End;
    If K > 0 Then H := Copy(H, 1, K - 1);
    If Nm = 'hostname' Then
    Begin
      If Pos(':', H) > 0 Then H := Copy(H, 1, Pos(':', H) - 1);
    End
    Else If Nm = 'port' Then
    Begin
      If Pos(':', H) > 0 Then H := Copy(H, Pos(':', H) + 1, 10) Else H := '';
    End
    Else If Nm = 'origin' Then H := Copy(U, 1, Pos('://', U) + 2) + H;
    JvStr(R, H);
  End
  Else If Nm = 'search' Then
  Begin
    H := '';
    If Pos('?', U) > 0 Then H := Copy(U, Pos('?', U), 255);
    If Pos('#', H) > 0 Then H := Copy(H, 1, Pos('#', H) - 1);
    JvStr(R, H);
  End
  Else If Nm = 'hash' Then
  Begin
    If Pos('#', U) > 0 Then JvStr(R, Copy(U, Pos('#', U), 255)) Else JvStr(R, '');
  End
  Else JvUndef(R);
End;

Procedure JsGetMember(Var O : TJV; A, L : LongInt; Var R : TJV);
Var Ob : PJObj; P : PJProp; Nm : String; V : TJV; K : LongInt; Fn : PJFun;
Begin
  JvUndef(R);
  Nm := ArGet(A, MinI(L, 60));
  Case O.K Of
    JV_STR :
      If Nm = 'length' Then JvNum(R, O.L);
    JV_FUN, JV_NAT :
      If Nm = 'length' Then JvNum(R, 0)
      Else If Nm = 'name' Then
      Begin
        If O.K = JV_NAT Then JvStrAL(R, O.P, O.L)
        Else
        Begin
          Fn := Pointer(O.P);
          JvStrAL(R, Fn^.NP, Fn^.NL);
        End;
      End;
    JV_NODE : JsNodeGet(Pointer(O.P), Nm, R);
    JV_OBJ :
      Begin
        Ob := Pointer(O.P);
        If Ob^.IsArr And (Nm = 'length') Then
        Begin
          JvNum(R, Ob^.Len);
          Exit;
        End;
        P := JsFindProp(Ob, A, L);
        If P <> Nil Then
        Begin
          R := P^.V;
          Exit;
        End;
        Case Ob^.Cls Of
          JO_WINDOW :
            If (Nm = 'innerWidth') Or (Nm = 'outerWidth') Then JvNum(R, JsViewW)
            Else If (Nm = 'innerHeight') Or (Nm = 'outerHeight') Then JvNum(R, JsViewH)
            Else If (Nm = 'scrollX') Or (Nm = 'scrollY') Or (Nm = 'pageXOffset') Or (Nm = 'pageYOffset') Then JvNum(R, 0)
            Else If Nm = 'devicePixelRatio' Then JvNum(R, 1)
            Else If JsIsGlobalFn(A, L) Then JvNat(R, A, L);
          JO_DOCUMENT :
            If Nm = 'title' Then JvStr(R, JsPageTitle)
            Else If (Nm = 'URL') Or (Nm = 'documentURI') Then JvStr(R, JsPageUrl)
            Else If Nm = 'location' Then JvObjV(R, JsLocObj)
            Else If Nm = 'cookie' Then JvStr(R, JsDocCookie)
            Else If Nm = 'readyState' Then JvStr(R, 'complete')
            Else If (Nm = 'referrer') Or (Nm = 'lastModified') Then JvStr(R, '')
            Else If Nm = 'domain' Then JsLocGet('hostname', R)
            Else If Nm = 'characterSet' Then JvStr(R, 'UTF-8')
            Else If (Nm = 'documentElement') Or (Nm = 'body') Or (Nm = 'head') Then
            Begin
              { premier element (html), puis body/head s'ils existent }
              V.K := JV_UNDEF;
              If Root <> Nil Then
              Begin
                Ob := JsNewArr;
                If Nm = 'documentElement' Then JsCollect(Root, 0, 'html', Ob, True)
                Else JsCollect(Root, 0, Nm, Ob, True);
                If (Ob <> Nil) And (Ob^.Len > 0) Then JsArrGet(Ob, 0, R)
                Else If Nm <> 'head' Then JvNode(R, Root);
              End;
            End
            Else If (Nm = 'forms') Or (Nm = 'images') Or (Nm = 'links') Or (Nm = 'scripts') Then
            Begin
              Ob := JsNewArr;
              If (Ob <> Nil) And (Root <> Nil) Then
              Begin
                If Nm = 'forms' Then JsCollect(Root, 0, 'form', Ob, False)
                Else If Nm = 'images' Then JsCollect(Root, 0, 'img', Ob, False)
                Else If Nm = 'scripts' Then JsCollect(Root, 0, 'script', Ob, False)
                Else JsCollect(Root, 2, 'a[href]', Ob, False);
              End;
              JsSetResultArr(R, Ob);
            End
            Else If Nm = 'defaultView' Then JvObjV(R, JsWindow);
          JO_LOCATION : JsLocGet(Nm, R);
          JO_NAVIGATOR :
            If Nm = 'userAgent' Then JvStr(R, HTTP_UA)
            Else If Nm = 'appName' Then JvStr(R, 'Netscape')
            Else If Nm = 'appVersion' Then JvStr(R, '4.0 (OS/2)')
            Else If Nm = 'platform' Then JvStr(R, 'OS/2')
            Else If (Nm = 'language') Or (Nm = 'userLanguage') Then JvStr(R, 'fr-CA')
            Else If Nm = 'cookieEnabled' Then JvBool(R, True)
            Else If Nm = 'onLine' Then JvBool(R, True)
            Else If Nm = 'vendor' Then JvStr(R, 'OS/2-0');
          JO_SCREEN :
            If (Nm = 'width') Or (Nm = 'availWidth') Then JvNum(R, JsScreenW)
            Else If (Nm = 'height') Or (Nm = 'availHeight') Then JvNum(R, JsScreenH)
            Else If (Nm = 'colorDepth') Or (Nm = 'pixelDepth') Then JvNum(R, 24);
          JO_HISTORY : If Nm = 'length' Then JvNum(R, 1);
          JO_MATH :
            If Nm = 'PI' Then JvNum(R, 3.14159265358979)
            Else If Nm = 'E' Then JvNum(R, 2.71828182845905)
            Else If Nm = 'LN2' Then JvNum(R, 0.693147180559945)
            Else If Nm = 'LN10' Then JvNum(R, 2.30258509299405)
            Else If Nm = 'SQRT2' Then JvNum(R, 1.4142135623731);
          JO_STYLE : JvStr(R, JsStyleGet(Ob^.Node, JsCssName(Nm)));
          JO_CLASSLIST :
            If Nm = 'length' Then
            Begin
              K := 0;
              Nm := TrimS(GetAttr(Ob^.Node, 'class'));
              While Nm <> '' Do
              Begin
                Inc(K);
                If Pos(' ', Nm) = 0 Then Nm := '' Else Nm := TrimS(Copy(Nm, Pos(' ', Nm) + 1, 255));
              End;
              JvNum(R, K);
            End;
        End;
      End;
  End;
End;

Procedure JsSetMember(Var O : TJV; A, L : LongInt; Var V : TJV);
Var Ob : PJObj; Nm : String; S : TJV; K : LongInt; U : TJV;
Begin
  Nm := ArGet(A, MinI(L, 60));
  Case O.K Of
    JV_NODE : JsNodeSet(Pointer(O.P), Nm, V);
    JV_OBJ :
      Begin
        Ob := Pointer(O.P);
        If Ob^.IsArr And (Nm = 'length') Then
        Begin
          K := JsToInt(V);
          If (K >= 0) And (K < Ob^.Len) Then Ob^.Len := K
          Else If K > Ob^.Len Then
          Begin
            JvUndef(U);
            JsArrSet(Ob, K - 1, U);
          End;
          Exit;
        End;
        Case Ob^.Cls Of
          JO_DOCUMENT :
            If Nm = 'title' Then
            Begin
              JsPageTitle := JsToPStr(V);
              JsTitleSet := True;
              Exit;
            End
            Else If Nm = 'cookie' Then
            Begin
              { "nom=valeur; path=..." : la paire est gardee (session) }
              Nm := JsToPStr(V);
              If Pos(';', Nm) > 0 Then Nm := Copy(Nm, 1, Pos(';', Nm) - 1);
              If JsDocCookie = '' Then JsDocCookie := Nm
              Else If Length(JsDocCookie) + Length(Nm) < 250 Then JsDocCookie := JsDocCookie + '; ' + Nm;
              Exit;
            End
            Else If Nm = 'location' Then
            Begin
              JsNavUrl := JsToPStr(V);
              Exit;
            End;
          JO_WINDOW :
            If Nm = 'location' Then
            Begin
              JsNavUrl := JsToPStr(V);
              Exit;
            End;
          JO_LOCATION :
            Begin
              If Nm = 'href' Then JsNavUrl := JsToPStr(V)
              Else If Nm = 'hash' Then
              Begin
                Nm := JsToPStr(V);
                If Copy(Nm, 1, 1) <> '#' Then Nm := '#' + Nm;
                If Pos('#', JsPageUrl) > 0 Then JsNavUrl := Copy(JsPageUrl, 1, Pos('#', JsPageUrl) - 1) + Nm
                Else JsNavUrl := JsPageUrl + Nm;
              End
              Else If Nm = 'search' Then
              Begin
                Nm := JsToPStr(V);
                If Copy(Nm, 1, 1) <> '?' Then Nm := '?' + Nm;
                If Pos('?', JsPageUrl) > 0 Then JsNavUrl := Copy(JsPageUrl, 1, Pos('?', JsPageUrl) - 1) + Nm
                Else JsNavUrl := JsPageUrl + Nm;
              End;
              Exit;
            End;
          JO_STYLE :
            Begin
              JsStyleSet(Ob^.Node, JsCssName(Nm), JsToPStr(V));
              Exit;
            End;
        End;
        JsSetPropAL(Ob, A, L, V);
      End;
    JV_FUN : ;
  End;
End;

{ ---------------- methodes ---------------- }

{ fonction de rappel (forEach, map, sort...) : F(a, b, c) }
Procedure JsCall3(Var F : TJV; Var A, B, C : TJV; N : LongInt; Var R : TJV);
Var U : TJV;
Begin
  JvUndef(R);
  If (F.K <> JV_FUN) And (F.K <> JV_NAT) Then
  Begin
    JsThrowMsg('TypeError: une fonction est attendue');
    Exit;
  End;
  If Not JsPush(A) Then Exit;
  If (N >= 2) And Not JsPush(B) Then
  Begin
    Dec(JsSp);
    Exit;
  End;
  If N >= 3 Then
    If Not JsPush(C) Then
    Begin
      JsSp := JsSp - 2;
      Exit;
    End;
  JvUndef(U);
  JsCallValue(F, U, MinI(N, 3), R);
  JsSp := JsSp - MinI(N, 3);
End;

Procedure JsStrMethod(Var S : TJV; M : String; Argc : LongInt; Var R : TJV);
Var A, B, T : TJV; I, J, K, N : LongInt; O : PJObj;
Begin
  JvUndef(R);
  If M = 'charAt' Then
  Begin
    I := JsArgInt(Argc, 0, 0);
    If (I >= 0) And (I < S.L) Then JvStrAL(R, S.P + I, 1) Else JvStrAL(R, 0, 0);
  End
  Else If M = 'charCodeAt' Then
  Begin
    I := JsArgInt(Argc, 0, 0);
    If (I >= 0) And (I < S.L) Then JvNum(R, CpToUni(RdB(S.P + I))) Else JvNum(R, JsNaN);
  End
  Else If (M = 'indexOf') Or (M = 'includes') Or (M = 'startsWith') Or (M = 'endsWith') Or (M = 'search') Then
  Begin
    JsArgStr(Argc, 0, A);
    If M = 'startsWith' Then JvBool(R, (A.L <= S.L) And JsSame(S.P, A.L, A.P, A.L))
    Else If M = 'endsWith' Then JvBool(R, (A.L <= S.L) And JsSame(S.P + S.L - A.L, A.L, A.P, A.L))
    Else
    Begin
      I := JsFind(S.P, S.L, A.P, A.L, JsArgInt(Argc, 1, 0));
      If M = 'includes' Then JvBool(R, I >= 0) Else JvNum(R, I);
    End;
  End
  Else If M = 'lastIndexOf' Then
  Begin
    JsArgStr(Argc, 0, A);
    J := -1; I := 0;
    While True Do
    Begin
      I := JsFind(S.P, S.L, A.P, A.L, I);
      If I < 0 Then Break;
      J := I; Inc(I);
    End;
    JvNum(R, J);
  End
  Else If (M = 'substring') Or (M = 'slice') Or (M = 'substr') Then
  Begin
    I := JsArgInt(Argc, 0, 0);
    If M = 'substr' Then
    Begin
      If I < 0 Then I := MaxI(0, S.L + I);
      J := I + JsArgInt(Argc, 1, S.L);
    End
    Else
    Begin
      J := JsArgInt(Argc, 1, S.L);
      If M = 'slice' Then
      Begin
        If I < 0 Then I := MaxI(0, S.L + I);
        If J < 0 Then J := MaxI(0, S.L + J);
      End
      Else
      Begin
        I := MaxI(0, I); J := MaxI(0, J);
        If I > J Then
        Begin
          K := I; I := J; J := K;
        End;
      End;
    End;
    JsSub(S, MinI(I, S.L), MinI(J, S.L), R);
  End
  Else If (M = 'toUpperCase') Or (M = 'toLocaleUpperCase') Then JsCase(S, True, R)
  Else If (M = 'toLowerCase') Or (M = 'toLocaleLowerCase') Then JsCase(S, False, R)
  Else If (M = 'trim') Or (M = 'trimStart') Or (M = 'trimEnd') Then
  Begin
    I := 0; J := S.L;
    If M <> 'trimEnd' Then
      While (I < J) And (RdB(S.P + I) <= 32) Do Inc(I);
    If M <> 'trimStart' Then
      While (J > I) And (RdB(S.P + J - 1) <= 32) Do Dec(J);
    JsSub(S, I, J, R);
  End
  Else If M = 'split' Then
  Begin
    O := JsNewArr;
    JsArg(Argc, 0, A);
    If A.K = JV_UNDEF Then JsArrPush(O, S)
    Else
    Begin
      JsToStrV(A, A);
      N := JsArgInt(Argc, 1, 1000000);
      If A.L = 0 Then
        For I := 0 To S.L - 1 Do
        Begin
          If (O = Nil) Or (O^.Len >= N) Then Break;
          JvStrAL(T, S.P + I, 1);
          JsArrPush(O, T);
        End
      Else
      Begin
        I := 0;
        While (O <> Nil) And (O^.Len < N) And Not JsKill Do
        Begin
          J := JsFind(S.P, S.L, A.P, A.L, I);
          If J < 0 Then
          Begin
            JsSub(S, I, S.L, T);
            JsArrPush(O, T);
            Break;
          End;
          JsSub(S, I, J, T);
          JsArrPush(O, T);
          I := J + A.L;
        End;
      End;
    End;
    JsSetResultArr(R, O);
  End
  Else If (M = 'replace') Or (M = 'replaceAll') Then
  Begin
    JsArgStr(Argc, 0, A);
    JsArg(Argc, 1, B);
    R := S;
    I := 0;
    JvStrAL(R, 0, 0);
    K := 0;
    While Not JsKill Do
    Begin
      J := JsFind(S.P, S.L, A.P, A.L, I);
      If (J < 0) Or (A.L = 0) Then Break;
      If J > I Then JsConcat(R, R.P, R.L, S.P + I, J - I);
      If (B.K = JV_FUN) Or (B.K = JV_NAT) Then
      Begin
        JvStrAL(T, A.P, A.L);
        JsCall3(B, T, T, T, 1, T);
        JsToStrV(T, T);
      End
      Else JsToStrV(B, T);
      JsConcat(R, R.P, R.L, T.P, T.L);
      I := J + A.L;
      Inc(K);
      If M = 'replace' Then Break;
    End;
    If I < S.L Then JsConcat(R, R.P, R.L, S.P + I, S.L - I);
  End
  Else If M = 'repeat' Then
  Begin
    N := JsArgInt(Argc, 0, 0);
    JvStrAL(R, 0, 0);
    If N * S.L > 1000000 Then JsThrowMsg('RangeError: longueur invalide')
    Else
      For I := 1 To N Do JsConcat(R, R.P, R.L, S.P, S.L);
  End
  Else If M = 'concat' Then
  Begin
    R := S;
    For I := 0 To Argc - 1 Do
    Begin
      JsArgStr(Argc, I, T);
      JsConcat(R, R.P, R.L, T.P, T.L);
    End;
  End
  Else If (M = 'padStart') Or (M = 'padEnd') Then
  Begin
    N := JsArgInt(Argc, 0, 0);
    JsArg(Argc, 1, A);
    If A.K = JV_UNDEF Then JvStr(A, ' ') Else JsToStrV(A, A);
    JvStrAL(T, 0, 0);
    While (T.L + S.L < N) And (A.L > 0) And (N < 100000) Do JsConcat(T, T.P, T.L, A.P, MinI(A.L, N - S.L - T.L));
    If M = 'padStart' Then JsConcat(R, T.P, T.L, S.P, S.L) Else JsConcat(R, S.P, S.L, T.P, T.L);
  End
  Else If (M = 'toString') Or (M = 'valueOf') Then R := S
  Else If M = 'localeCompare' Then
  Begin
    JsArgStr(Argc, 0, A);
    I := JsStrCmp(S.P, S.L, A.P, A.L);
    If I < 0 Then JvNum(R, -1) Else If I > 0 Then JvNum(R, 1) Else JvNum(R, 0);
  End
  Else If M = 'match' Then R.K := JV_NULL
  Else JsThrowMsg('TypeError: methode de chaine inconnue : ' + M);
End;

{ tri par fusion (stable) d'un tableau ; comparateur Cmp ou ordre des chaines }
Function JsCmpVals(Var Cmp, A, B : TJV) : LongInt;
Var R, SA, SB : TJV; D : Double;
Begin
  If (A.K = JV_UNDEF) And (B.K = JV_UNDEF) Then JsCmpVals := 0
  Else If A.K = JV_UNDEF Then JsCmpVals := 1
  Else If B.K = JV_UNDEF Then JsCmpVals := -1
  Else If (Cmp.K = JV_FUN) Or (Cmp.K = JV_NAT) Then
  Begin
    JsCall3(Cmp, A, B, B, 2, R);
    D := JsToNum(R);
    If D < 0 Then JsCmpVals := -1 Else If D > 0 Then JsCmpVals := 1 Else JsCmpVals := 0;
  End
  Else
  Begin
    JsToStrV(A, SA); JsToStrV(B, SB);
    JsCmpVals := JsStrCmp(SA.P, SA.L, SB.P, SB.L);
  End;
End;

Procedure JsSortArr(O : PJObj; Var Cmp : TJV);
Var Tmp, W, I, J, K, Lo, Mid, Hi : LongInt; A, B : TJV; Pa, Pb : ^TJV;
Begin
  If O^.Len < 2 Then Exit;
  Tmp := ArAlloc(O^.Len * SizeOf(TJV));
  If Tmp = 0 Then Exit;
  W := 1;
  While W < O^.Len Do
  Begin
    Lo := 0;
    While Lo < O^.Len Do
    Begin
      Mid := MinI(Lo + W, O^.Len); Hi := MinI(Lo + 2 * W, O^.Len);
      I := Lo; J := Mid; K := Lo;
      While (I < Mid) Or (J < Hi) Do
      Begin
        If JsCtl = JC_THROW Then Exit;
        Pa := Pointer(JsElem(O, I)); Pb := Pointer(JsElem(O, J));
        If (J >= Hi) Or ((I < Mid) And (JsCmpVals(Cmp, Pa^, Pb^) <= 0)) Then
        Begin
          MemCopy(LongInt(Pa), Tmp + K * SizeOf(TJV), SizeOf(TJV));
          Inc(I);
        End
        Else
        Begin
          MemCopy(LongInt(Pb), Tmp + K * SizeOf(TJV), SizeOf(TJV));
          Inc(J);
        End;
        Inc(K);
      End;
      Lo := Hi;
    End;
    MemCopy(Tmp, O^.Elems, O^.Len * SizeOf(TJV));
    W := W * 2;
  End;
End;

Procedure JsArrMethod(Var OV : TJV; M : String; Argc : LongInt; Var R : TJV);
Var O, N : PJObj; V, F, E, I2, Acc : TJV; I, J, K, S : LongInt; Pv : ^TJV; D : Double;
Begin
  O := Pointer(OV.P);
  JvUndef(R);
  If M = 'push' Then
  Begin
    For I := 0 To Argc - 1 Do
    Begin
      JsArg(Argc, I, V);
      JsArrPush(O, V);
    End;
    JvNum(R, O^.Len);
  End
  Else If M = 'pop' Then
  Begin
    If O^.Len > 0 Then
    Begin
      JsArrGet(O, O^.Len - 1, R);
      Dec(O^.Len);
    End;
  End
  Else If M = 'shift' Then
  Begin
    If O^.Len > 0 Then
    Begin
      JsArrGet(O, 0, R);
      If O^.Len > 1 Then MemCopy(JsElem(O, 1), JsElem(O, 0), (O^.Len - 1) * SizeOf(TJV));
      Dec(O^.Len);
    End;
  End
  Else If M = 'unshift' Then
  Begin
    JvUndef(V);
    For I := 1 To Argc Do JsArrPush(O, V);
    For I := O^.Len - 1 DownTo Argc Do
    Begin
      Pv := Pointer(JsElem(O, I - Argc));
      JsArrSet(O, I, Pv^);
    End;
    For I := 0 To Argc - 1 Do
    Begin
      JsArg(Argc, I, V);
      JsArrSet(O, I, V);
    End;
    JvNum(R, O^.Len);
  End
  Else If (M = 'join') Or (M = 'toString') Then
  Begin
    JsArg(Argc, 0, V);
    If (M = 'join') And (V.K <> JV_UNDEF) Then JsJoin(O, JsToPStr(V), R) Else JsJoin(O, ',', R);
  End
  Else If (M = 'indexOf') Or (M = 'includes') Or (M = 'lastIndexOf') Then
  Begin
    JsArg(Argc, 0, V);
    K := -1;
    For I := 0 To O^.Len - 1 Do
    Begin
      JsArrGet(O, I, E);
      If JsStrictEq(E, V) Then
      Begin
        K := I;
        If M <> 'lastIndexOf' Then Break;
      End;
    End;
    If M = 'includes' Then JvBool(R, K >= 0) Else JvNum(R, K);
  End
  Else If M = 'slice' Then
  Begin
    I := JsArgInt(Argc, 0, 0); J := JsArgInt(Argc, 1, O^.Len);
    If I < 0 Then I := MaxI(0, O^.Len + I);
    If J < 0 Then J := MaxI(0, O^.Len + J);
    J := MinI(J, O^.Len);
    N := JsNewArr;
    For K := I To J - 1 Do
    Begin
      JsArrGet(O, K, E);
      JsArrPush(N, E);
    End;
    JsSetResultArr(R, N);
  End
  Else If M = 'splice' Then
  Begin
    S := JsArgInt(Argc, 0, 0);
    If S < 0 Then S := MaxI(0, O^.Len + S);
    S := MinI(S, O^.Len);
    K := MinI(MaxI(0, JsArgInt(Argc, 1, O^.Len - S)), O^.Len - S);
    N := JsNewArr;
    For I := S To S + K - 1 Do
    Begin
      JsArrGet(O, I, E);
      JsArrPush(N, E);
    End;
    { nouveau contenu : debut + elements inseres + fin }
    F.K := 0;
    I2.K := 0;
    Acc.K := 0;
    E.K := 0;
    J := Argc - 2;
    If J < 0 Then J := 0;
    { copie de la fin }
    D := O^.Len - S - K;
    V.K := 0;
    If (J <> K) Then
    Begin
      If J > K Then
      Begin
        JvUndef(V);
        For I := 1 To J - K Do JsArrPush(O, V);
        For I := O^.Len - 1 DownTo S + J Do
        Begin
          Pv := Pointer(JsElem(O, I - (J - K)));
          JsArrSet(O, I, Pv^);
        End;
      End
      Else
      Begin
        For I := S + J To O^.Len - (K - J) - 1 Do
        Begin
          Pv := Pointer(JsElem(O, I + (K - J)));
          JsArrSet(O, I, Pv^);
        End;
        O^.Len := O^.Len - (K - J);
      End;
    End;
    For I := 0 To J - 1 Do
    Begin
      JsArg(Argc, I + 2, V);
      JsArrSet(O, S + I, V);
    End;
    JsSetResultArr(R, N);
  End
  Else If M = 'concat' Then
  Begin
    N := JsNewArr;
    For I := 0 To O^.Len - 1 Do
    Begin
      JsArrGet(O, I, E);
      JsArrPush(N, E);
    End;
    For I := 0 To Argc - 1 Do
    Begin
      JsArg(Argc, I, V);
      If (JvArr(V) <> Nil) Then
        For K := 0 To JvLen(V) - 1 Do
        Begin
          JsArrGet(Pointer(V.P), K, E);
          JsArrPush(N, E);
        End
      Else JsArrPush(N, V);
    End;
    JsSetResultArr(R, N);
  End
  Else If M = 'reverse' Then
  Begin
    For I := 0 To O^.Len Div 2 - 1 Do
    Begin
      JsArrGet(O, I, E); JsArrGet(O, O^.Len - 1 - I, V);
      JsArrSet(O, I, V); JsArrSet(O, O^.Len - 1 - I, E);
    End;
    R := OV;
  End
  Else If M = 'sort' Then
  Begin
    JsArg(Argc, 0, F);
    JsSortArr(O, F);
    R := OV;
  End
  Else If (M = 'forEach') Or (M = 'map') Or (M = 'filter') Or (M = 'some') Or (M = 'every') Or (M = 'find') Or
          (M = 'findIndex') Then
  Begin
    JsArg(Argc, 0, F);
    N := Nil;
    If (M = 'map') Or (M = 'filter') Then N := JsNewArr;
    If M = 'some' Then JvBool(R, False) Else If M = 'every' Then JvBool(R, True)
    Else If M = 'findIndex' Then JvNum(R, -1);
    For I := 0 To O^.Len - 1 Do
    Begin
      If (JsCtl = JC_THROW) Or (I >= O^.Len) Then Break;
      JsArrGet(O, I, E);
      JvNum(I2, I);
      JsCall3(F, E, I2, OV, 3, V);
      If JsCtl = JC_THROW Then Break;
      If M = 'map' Then JsArrPush(N, V)
      Else If (M = 'filter') And JsToBool(V) Then JsArrPush(N, E)
      Else If (M = 'some') And JsToBool(V) Then
      Begin
        JvBool(R, True);
        Break;
      End
      Else If (M = 'every') And Not JsToBool(V) Then
      Begin
        JvBool(R, False);
        Break;
      End
      Else If (M = 'find') And JsToBool(V) Then
      Begin
        R := E;
        Break;
      End
      Else If (M = 'findIndex') And JsToBool(V) Then
      Begin
        JvNum(R, I);
        Break;
      End;
    End;
    If N <> Nil Then JsSetResultArr(R, N);
  End
  Else If M = 'reduce' Then
  Begin
    JsArg(Argc, 0, F);
    I := 0;
    If Argc >= 2 Then JsArg(Argc, 1, Acc)
    Else If O^.Len > 0 Then
    Begin
      JsArrGet(O, 0, Acc);
      I := 1;
    End
    Else
    Begin
      JsThrowMsg('TypeError: reduce d''un tableau vide sans valeur initiale');
      Exit;
    End;
    While (I < O^.Len) And (JsCtl <> JC_THROW) Do
    Begin
      JsArrGet(O, I, E);
      JvNum(I2, I);
      JsCall3(F, Acc, E, I2, 3, V);
      Acc := V;
      Inc(I);
    End;
    R := Acc;
  End
  Else If M = 'fill' Then
  Begin
    JsArg(Argc, 0, V);
    For I := JsArgInt(Argc, 1, 0) To MinI(O^.Len, JsArgInt(Argc, 2, O^.Len)) - 1 Do JsArrSet(O, I, V);
    R := OV;
  End
  Else If M = 'keys' Then
  Begin
    N := JsNewArr;
    For I := 0 To O^.Len - 1 Do
    Begin
      JvNum(V, I);
      JsArrPush(N, V);
    End;
    JsSetResultArr(R, N);
  End
  Else JsThrowMsg('TypeError: methode de tableau inconnue : ' + M);
End;

Procedure JsDateMethod(O : PJObj; M : String; Argc : LongInt; Var R : TJV);
Var Y, Mo, D, H, Mi, S, Wd : LongInt;
Const
  Mois : Array[0..11] Of String[9] = ('janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin', 'juillet', 'aout',
                                      'septembre', 'octobre', 'novembre', 'decembre');
  Jours : Array[0..6] Of String[8] = ('dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi');
Begin
  JsDateFields(O^.Num, Y, Mo, D, H, Mi, S, Wd);
  If (M = 'getTime') Or (M = 'valueOf') Then JvNum(R, O^.Num)
  Else If (M = 'getFullYear') Or (M = 'getUTCFullYear') Then JvNum(R, Y)
  Else If M = 'getYear' Then JvNum(R, Y - 1900)
  Else If (M = 'getMonth') Or (M = 'getUTCMonth') Then JvNum(R, Mo)
  Else If (M = 'getDate') Or (M = 'getUTCDate') Then JvNum(R, D)
  Else If (M = 'getDay') Or (M = 'getUTCDay') Then JvNum(R, Wd)
  Else If (M = 'getHours') Or (M = 'getUTCHours') Then JvNum(R, H)
  Else If (M = 'getMinutes') Or (M = 'getUTCMinutes') Then JvNum(R, Mi)
  Else If (M = 'getSeconds') Or (M = 'getUTCSeconds') Then JvNum(R, S)
  Else If M = 'getMilliseconds' Then JvNum(R, 0)
  Else If M = 'getTimezoneOffset' Then JvNum(R, 0)
  Else If M = 'setTime' Then
  Begin
    O^.Num := JsArgNum(Argc, 0, 0);
    JvNum(R, O^.Num);
  End
  Else If (M = 'toLocaleDateString') Or (M = 'toDateString') Then JvStr(R, Jours[Wd] + ' ' + IStr(D) + ' ' + Mois[Mo] + ' ' + IStr(Y))
  Else If M = 'toLocaleTimeString' Then JvStr(R, Z2s(H) + ':' + Z2s(Mi) + ':' + Z2s(S))
  Else If (M = 'toISOString') Or (M = 'toJSON') Then
    JvStr(R, IStr(Y) + '-' + Z2s(Mo + 1) + '-' + Z2s(D) + 'T' + Z2s(H) + ':' + Z2s(Mi) + ':' + Z2s(S) + '.000Z')
  Else
    JvStr(R, Jours[Wd] + ' ' + IStr(D) + ' ' + Mois[Mo] + ' ' + IStr(Y) + ' ' + Z2s(H) + ':' + Z2s(Mi) + ':' + Z2s(S));
End;

Procedure JsMathMethod(M : String; Argc : LongInt; Var R : TJV);
Var X, Y : Double; I : LongInt;
Begin
  X := JsArgNum(Argc, 0, JsNaN);
  If M = 'abs' Then JvNum(R, Abs(X))
  Else If M = 'floor' Then
  Begin
    Y := JsFTrunc(X);
    If Y > X Then Y := Y - 1;
    JvNum(R, Y);
  End
  Else If M = 'ceil' Then
  Begin
    Y := JsFTrunc(X);
    If Y < X Then Y := Y + 1;
    JvNum(R, Y);
  End
  Else If M = 'round' Then
  Begin
    Y := JsFTrunc(X + 0.5);
    If Y > X + 0.5 Then Y := Y - 1;
    JvNum(R, Y);
  End
  Else If M = 'trunc' Then JvNum(R, JsFTrunc(X))
  Else If M = 'sign' Then
  Begin
    If X > 0 Then JvNum(R, 1) Else If X < 0 Then JvNum(R, -1) Else JvNum(R, X);
  End
  Else If (M = 'max') Or (M = 'min') Then
  Begin
    If M = 'max' Then Y := -JsInf Else Y := JsInf;
    For I := 0 To Argc - 1 Do
    Begin
      X := JsArgNum(Argc, I, JsNaN);
      If JsIsNaN(X) Then
      Begin
        Y := X;
        Break;
      End;
      If (M = 'max') And (X > Y) Then Y := X;
      If (M = 'min') And (X < Y) Then Y := X;
    End;
    JvNum(R, Y);
  End
  Else If M = 'pow' Then
  Begin
    JvNum(R, X);
    JvNum(JsRet, JsArgNum(Argc, 1, JsNaN));
    JsBinary(20, R, JsRet, R);
  End
  Else If M = 'sqrt' Then
  Begin
    If X < 0 Then JvNum(R, JsNaN) Else JvNum(R, Sqrt(X));
  End
  Else If M = 'random' Then
  Begin
    JsRand := JsRand * 1103515245 + 12345;
    JvNum(R, ((JsRand Shr 8) And $FFFFFF) / 16777216.0);
  End
  Else If M = 'sin' Then JvNum(R, Sin(X))
  Else If M = 'cos' Then JvNum(R, Cos(X))
  Else If M = 'tan' Then JvNum(R, Sin(X) / Cos(X))
  Else If M = 'atan' Then JvNum(R, ArcTan(X))
  Else If M = 'atan2' Then
  Begin
    Y := X; X := JsArgNum(Argc, 1, JsNaN);
    If X > 0 Then JvNum(R, ArcTan(Y / X))
    Else If (X < 0) And (Y >= 0) Then JvNum(R, ArcTan(Y / X) + 3.14159265358979)
    Else If (X < 0) And (Y < 0) Then JvNum(R, ArcTan(Y / X) - 3.14159265358979)
    Else If Y > 0 Then JvNum(R, 1.5707963267949)
    Else If Y < 0 Then JvNum(R, -1.5707963267949)
    Else JvNum(R, 0);
  End
  Else If M = 'exp' Then JvNum(R, Exp(X))
  Else If M = 'log' Then
  Begin
    If X > 0 Then JvNum(R, Ln(X)) Else If X = 0 Then JvNum(R, -JsInf) Else JvNum(R, JsNaN);
  End
  Else JsThrowMsg('TypeError: Math.' + M + ' n''est pas une fonction');
End;

Procedure JsConsoleMethod(M : String; Argc : LongInt; Var R : TJV);
Var S : String; I, Kd : LongInt; V : TJV;
Begin
  JvUndef(R);
  S := '';
  For I := 0 To Argc - 1 Do
  Begin
    JsArg(Argc, I, V);
    If I > 0 Then S := S + ' ';
    S := S + JsInspect(V, 0);
  End;
  If M = 'error' Then Kd := 1 Else If M = 'warn' Then Kd := 4 Else Kd := 0;
  If M = 'clear' Then
  Begin
    JsConN := 0; JsConFirst := 0;
    Inc(JsConGen);
  End
  Else JsConsole(S, Kd);
End;

{ element : methodes du DOM }
Procedure JsNodeMethod(N : PNode; M : String; Argc : LongInt; Var R : TJV);
Var V, W : TJV; C, Ref, Q : PNode; O : PJObj; S : String; K : LongInt;
Begin
  JvUndef(R);
  If M = 'getAttribute' Then JsGetAttrV(N, JsArgP(Argc, 0), R)
  Else If M = 'setAttribute' Then
  Begin
    JsArgStr(Argc, 1, V);
    S := LowStr(JsArgP(Argc, 0));
    If (S = 'value') Or (S = 'checked') Then JsNodeSet(N, S, V) Else JsSetAttr(N, S, V.P, V.L);
  End
  Else If M = 'removeAttribute' Then JsRemoveAttr(N, JsArgP(Argc, 0))
  Else If M = 'hasAttribute' Then JvBool(R, HasAttr(N, LowStr(JsArgP(Argc, 0))))
  Else If (M = 'appendChild') Or (M = 'insertBefore') Or (M = 'append') Or (M = 'prepend') Then
  Begin
    JsArg(Argc, 0, V);
    If V.K = JV_STR Then
    Begin
      { append("texte") }
      C := NewNode(NODE_TEXT);
      If C <> Nil Then
      Begin
        C^.Txt := V.P; C^.TLen := V.L;
        JvNode(V, C);
      End;
    End;
    If V.K <> JV_NODE Then
    Begin
      JsThrowMsg('TypeError: ' + M + ' attend un noeud');
      Exit;
    End;
    C := Pointer(V.P);
    JsDetach(C);
    JsArg(Argc, 1, W);
    Ref := Nil;
    If W.K = JV_NODE Then Ref := Pointer(W.P);
    If (M = 'insertBefore') And (Ref <> Nil) And (Ref^.Parent = N) Then
    Begin
      C^.Parent := N;
      C^.Next := Ref;
      If N^.First = Ref Then N^.First := C
      Else
      Begin
        Q := N^.First;
        While (Q <> Nil) And (Q^.Next <> Ref) Do Q := Q^.Next;
        If Q <> Nil Then Q^.Next := C;
      End;
    End
    Else If (M = 'prepend') And (N^.First <> Nil) Then
    Begin
      C^.Parent := N;
      C^.Next := N^.First;
      N^.First := C;
    End
    Else AppendChild(N, C);
    JsDirty := True; JsRescan := True;
    R := V;
  End
  Else If M = 'removeChild' Then
  Begin
    JsArg(Argc, 0, V);
    If V.K = JV_NODE Then
    Begin
      C := Pointer(V.P);
      If C^.Parent = N Then JsDetach(C);
    End;
    R := V;
  End
  Else If M = 'remove' Then JsDetach(N)
  Else If M = 'replaceChild' Then
  Begin
    JsArg(Argc, 0, V); JsArg(Argc, 1, W);
    If (V.K = JV_NODE) And (W.K = JV_NODE) Then
    Begin
      C := Pointer(V.P); Ref := Pointer(W.P);
      If Ref^.Parent = N Then
      Begin
        JsDetach(C);
        C^.Parent := N; C^.Next := Ref^.Next;
        If N^.First = Ref Then N^.First := C
        Else
        Begin
          Q := N^.First;
          While (Q <> Nil) And (Q^.Next <> Ref) Do Q := Q^.Next;
          If Q <> Nil Then Q^.Next := C;
        End;
        If N^.Last = Ref Then N^.Last := C;
        Ref^.Parent := Nil; Ref^.Next := Nil;
        JsDirty := True; JsRescan := True;
      End;
    End;
    R := W;
  End
  Else If M = 'addEventListener' Then
  Begin
    JsArg(Argc, 1, V);
    JsAddListener(N, LowStr(JsArgP(Argc, 0)), V);
  End
  Else If M = 'removeEventListener' Then
  Begin
    JsArg(Argc, 1, V);
    JsRemoveListener(N, LowStr(JsArgP(Argc, 0)), V);
  End
  Else If (M = 'getElementsByTagName') Or (M = 'getElementsByClassName') Then
  Begin
    O := JsNewArr;
    If O <> Nil Then
      If M = 'getElementsByTagName' Then JsCollect(N, 0, LowStr(JsArgP(Argc, 0)), O, False)
      Else JsCollect(N, 1, JsArgP(Argc, 0), O, False);
    JsSetResultArr(R, O);
  End
  Else If (M = 'querySelector') Or (M = 'querySelectorAll') Then JsQuery(N, JsArgP(Argc, 0), M = 'querySelectorAll', R)
  Else If M = 'getElementById' Then
  Begin
    JsArgStr(Argc, 0, V);
    JvNode(R, JsById(N, V));
  End
  Else If M = 'contains' Then
  Begin
    JsArg(Argc, 0, V);
    JvBool(R, False);
    If V.K = JV_NODE Then
    Begin
      C := Pointer(V.P);
      While C <> Nil Do
      Begin
        If C = N Then
        Begin
          JvBool(R, True);
          Break;
        End;
        C := C^.Parent;
      End;
    End;
  End
  Else If M = 'closest' Then
  Begin
    S := JsSelLast(JsArgP(Argc, 0));
    C := N;
    While (C <> Nil) And Not JsMatchSel(C, S) Do C := C^.Parent;
    JvNode(R, C);
  End
  Else If M = 'matches' Then JvBool(R, JsMatchSel(N, JsSelLast(JsArgP(Argc, 0))))
  Else If M = 'hasChildNodes' Then JvBool(R, N^.First <> Nil)
  Else If M = 'cloneNode' Then
  Begin
    { copie superficielle : meme element, sans enfants (ou avec par HTML) }
    JvStrAL(V, 0, 0);
    JsArg(Argc, 0, W);
    C := NewNode(NODE_ELEM);
    If C <> Nil Then
    Begin
      C^.Tag := N^.Tag; C^.Name := N^.Name; C^.Attr := N^.Attr;
      If JsToBool(W) Then
      Begin
        JsSerialize(N, False, V);
        JsParseInto(C, Nil, V.P, V.L);
      End;
      JvNode(R, C);
    End;
  End
  Else If (M = 'focus') Or (M = 'blur') Or (M = 'scrollIntoView') Or (M = 'select') Then
  Else If (M = 'click') Or (M = 'submit') Or (M = 'reset') Then
  Begin
    { action differee : l'interface la fait apres le script }
    If JsAlertN < 8 Then
    Begin
      JsAlerts[JsAlertN] := #1 + M + #1 + IStr(LongInt(N));
      Inc(JsAlertN);
    End;
  End
  Else If M = 'getBoundingClientRect' Then
  Begin
    O := JsNewObj;
    JvNum(V, 0);
    JsSetPropS(O, 'left', V); JsSetPropS(O, 'top', V); JsSetPropS(O, 'x', V); JsSetPropS(O, 'y', V);
    JvNum(V, JsViewW);
    JsSetPropS(O, 'width', V); JsSetPropS(O, 'right', V);
    JvNum(V, 20);
    JsSetPropS(O, 'height', V); JsSetPropS(O, 'bottom', V);
    JsSetResultArr(R, O);
  End
  Else If M = 'toString' Then JsToStrV(R, R)
  Else JsThrowMsg('TypeError: methode d''element inconnue : ' + M);
End;

Procedure JsCallMethod(Var O : TJV; A, L, Argc : LongInt; Var R : TJV);
Var M, S : String; Ob, N : PJObj; V, W, T : TJV; K, Lp : LongInt; D : Double; P : PJProp; Nn : PNode;
Begin
  JvUndef(R);
  If L = 0 Then M := 'toString' Else M := ArGet(A, MinI(L, 40));
  Case O.K Of
    JV_STR : JsStrMethod(O, M, Argc, R);
    JV_NUM :
      If M = 'toFixed' Then
      Begin
        K := MaxI(0, MinI(10, JsArgInt(Argc, 0, 0)));
        D := 1;
        For Lp := 1 To K Do D := D * 10;
        S := JsNumStr(JsFTrunc(Abs(O.N) * D + 0.5) / D);
        If (K > 0) Then
        Begin
          If Pos('.', S) = 0 Then S := S + '.';
          While Length(S) - Pos('.', S) < K Do S := S + '0';
        End;
        If O.N < 0 Then S := '-' + S;
        JvStr(R, S);
      End
      Else If M = 'toString' Then
      Begin
        K := JsArgInt(Argc, 0, 10);
        If (K = 16) Or (K = 2) Or (K = 8) Then
        Begin
          S := '';
          D := JsFTrunc(Abs(O.N));
          If D = 0 Then S := '0';
          While (D >= 1) And (Length(S) < 64) Do
          Begin
            S := HexCh(Trunc(D - K * JsFTrunc(D / K))) + S;
            D := JsFTrunc(D / K);
          End;
          If O.N < 0 Then S := '-' + S;
          JvStr(R, LowStr(S));
        End
        Else JvStr(R, JsNumStr(O.N));
      End
      Else If M = 'valueOf' Then R := O
      Else If M = 'toLocaleString' Then JvStr(R, JsNumStr(O.N))
      Else JsThrowMsg('TypeError: methode de nombre inconnue : ' + M);
    JV_BOOL : JsToStrV(O, R);
    JV_NODE : JsNodeMethod(Pointer(O.P), M, Argc, R);
    JV_FUN, JV_NAT :
      If (M = 'call') Or (M = 'apply') Then
      Begin
        { f.call(this, a, b) / f.apply(this, [a, b]) : arguments recopies plus haut sur la pile }
        JsArg(Argc, 0, T);
        K := 0;
        If M = 'call' Then
        Begin
          For K := 1 To Argc - 1 Do
          Begin
            JsArg(Argc, K, V);
            Dummy := Ord(JsPush(V));
          End;
          K := MaxI(0, Argc - 1);
        End
        Else
        Begin
          JsArg(Argc, 1, W);
          If (JvArr(W) <> Nil) Then
          Begin
            For K := 0 To JvLen(W) - 1 Do
            Begin
              JsArrGet(Pointer(W.P), K, V);
              Dummy := Ord(JsPush(V));
            End;
            K := JvLen(W);
          End
          Else K := 0;
        End;
        JsCallValue(O, T, K, R);
        JsSp := JsSp - K;
      End
      Else If O.K = JV_NAT Then
      Begin
        { methodes statiques : Array.isArray, Object.keys, String.fromCharCode, Date.now... }
        S := ArGet(O.P, O.L);
        If (S = 'Array') And (M = 'isArray') Then
        Begin
          JsArg(Argc, 0, V);
          JvBool(R, (JvArr(V) <> Nil));
        End
        Else If (S = 'Array') And (M = 'from') Then
        Begin
          JsArg(Argc, 0, V);
          N := JsNewArr;
          If (JvArr(V) <> Nil) Then
            For K := 0 To JvLen(V) - 1 Do
            Begin
              JsArrGet(Pointer(V.P), K, W);
              JsArrPush(N, W);
            End
          Else If V.K = JV_STR Then
            For K := 0 To V.L - 1 Do
            Begin
              JvStrAL(W, V.P + K, 1);
              JsArrPush(N, W);
            End;
          JsSetResultArr(R, N);
        End
        Else If (S = 'Object') And ((M = 'keys') Or (M = 'values') Or (M = 'entries')) Then
        Begin
          JsArg(Argc, 0, V);
          N := JsNewArr;
          If V.K = JV_OBJ Then
          Begin
            Ob := Pointer(V.P);
            If Ob^.IsArr Then
              For K := 0 To Ob^.Len - 1 Do
              Begin
                If M = 'values' Then JsArrGet(Ob, K, W) Else JvStr(W, IStr(K));
                JsArrPush(N, W);
              End
            Else
            Begin
              P := Ob^.Props;
              While P <> Nil Do
              Begin
                If M = 'values' Then JsArrPush(N, P^.V)
                Else If M = 'keys' Then
                Begin
                  JvStrAL(W, P^.P, P^.L);
                  JsArrPush(N, W);
                End
                Else
                Begin
                  Ob := JsNewArr;
                  JvStrAL(W, P^.P, P^.L);
                  JsArrPush(Ob, W);
                  JsArrPush(Ob, P^.V);
                  JsSetResultArr(W, Ob);
                  JsArrPush(N, W);
                  Ob := Pointer(V.P);
                End;
                P := P^.Next;
              End;
            End;
          End;
          JsSetResultArr(R, N);
        End
        Else If (S = 'Object') And (M = 'assign') Then
        Begin
          JsArg(Argc, 0, R);
          If R.K = JV_OBJ Then
            For K := 1 To Argc - 1 Do
            Begin
              JsArg(Argc, K, V);
              If V.K = JV_OBJ Then
              Begin
                Ob := Pointer(V.P);
                P := Ob^.Props;
                While P <> Nil Do
                Begin
                  JsSetPropAL(Pointer(R.P), P^.P, P^.L, P^.V);
                  P := P^.Next;
                End;
              End;
            End;
        End
        Else If (S = 'Object') And ((M = 'freeze') Or (M = 'create')) Then
        Begin
          JsArg(Argc, 0, R);
          If (M = 'create') Or (R.K <> JV_OBJ) Then
          Begin
            Ob := JsNewObj;
            If Ob <> Nil Then JvObjV(R, Ob);
          End;
        End
        Else If (S = 'String') And (M = 'fromCharCode') Then
        Begin
          JvStrAL(R, 0, 0);
          For K := 0 To Argc - 1 Do
          Begin
            JvStr(V, Chr(UniToCp(JsArgInt(Argc, K, 32)) And 255));
            JsConcat(R, R.P, R.L, V.P, V.L);
          End;
        End
        Else If (S = 'Date') And (M = 'now') Then JvNum(R, JsNow)
        Else If (S = 'Number') And (M = 'isInteger') Then
        Begin
          JsArg(Argc, 0, V);
          JvBool(R, (V.K = JV_NUM) And (V.N = JsFTrunc(V.N)));
        End
        Else If (S = 'Number') And ((M = 'isNaN') Or (M = 'parseFloat') Or (M = 'parseInt')) Then
          JsCallNative(M, O, Argc, R)
        Else JsThrowMsg('TypeError: ' + S + '.' + M + ' n''est pas une fonction');
      End
      Else If M = 'toString' Then JsToStrV(O, R)
      Else JsThrowMsg('TypeError: methode de fonction inconnue : ' + M);
    JV_OBJ :
      Begin
        Ob := Pointer(O.P);
        If Ob^.IsArr Then
        Begin
          JsArrMethod(O, M, Argc, R);
          Exit;
        End;
        Case Ob^.Cls Of
          JO_DATE : JsDateMethod(Ob, M, Argc, R);
          JO_CONSOLE : JsConsoleMethod(M, Argc, R);
          JO_MATH : JsMathMethod(M, Argc, R);
          JO_JSON :
            If M = 'stringify' Then
            Begin
              JsArg(Argc, 0, V);
              JvStrAL(R, 0, 0);
              If V.K = JV_UNDEF Then JvUndef(R) Else JsJsonOf(V, R, 0);
            End
            Else If M = 'parse' Then
            Begin
              JsArgStr(Argc, 0, V);
              JvStr(W, '(');
              JsConcat(W, W.P, W.L, V.P, V.L);
              JvStr(T, ')');
              JsConcat(W, W.P, W.L, T.P, T.L);
              JvUndef(T);
              If Not JsRunCode(W.P, W.L, 1, T, R) Then
                If JsCtl <> JC_THROW Then JsThrowMsg('SyntaxError: JSON invalide');
            End
            Else JsThrowMsg('TypeError: JSON.' + M + ' n''est pas une fonction');
          JO_DOCUMENT :
            If (M = 'write') Or (M = 'writeln') Then
            Begin
              For K := 0 To Argc - 1 Do
              Begin
                JsArgStr(Argc, K, V);
                If JsWriteL = 0 Then
                Begin
                  JsWriteP := V.P; JsWriteL := V.L;
                End
                Else
                Begin
                  JsConcat(W, JsWriteP, JsWriteL, V.P, V.L);
                  JsWriteP := W.P; JsWriteL := W.L;
                End;
              End;
              If M = 'writeln' Then
              Begin
                JvStr(V, #10);
                JsConcat(W, JsWriteP, JsWriteL, V.P, V.L);
                JsWriteP := W.P; JsWriteL := W.L;
              End;
            End
            Else If M = 'getElementById' Then
            Begin
              JsArgStr(Argc, 0, V);
              JvNode(R, JsById(Root, V));
            End
            Else If (M = 'getElementsByTagName') Or (M = 'getElementsByClassName') Or (M = 'querySelector') Or
                    (M = 'querySelectorAll') Or (M = 'getElementsByName') Then
            Begin
              If Root = Nil Then
              Begin
                R.K := JV_NULL;
                Exit;
              End;
              If M = 'getElementsByName' Then
              Begin
                N := JsNewArr;
                If N <> Nil Then JsCollect(Root, 2, '[name=' + JsArgP(Argc, 0) + ']', N, False);
                JsSetResultArr(R, N);
              End
              Else JsNodeMethod(Root, M, Argc, R);
            End
            Else If (M = 'createElement') Or (M = 'createTextNode') Or (M = 'createDocumentFragment') Then
            Begin
              R.K := JV_NULL;
              If M = 'createTextNode' Then
              Begin
                JsArgStr(Argc, 0, V);
                Nn := NewNode(NODE_TEXT);
                If Nn <> Nil Then
                Begin
                  Nn^.Txt := V.P; Nn^.TLen := V.L;
                  JvNode(R, Nn);
                End;
              End
              Else
              Begin
                If M = 'createDocumentFragment' Then S := 'div' Else S := LowStr(JsArgP(Argc, 0));
                Nn := NewNode(NODE_ELEM);
                If Nn <> Nil Then
                Begin
                  Nn^.Name := Copy(S, 1, 23);
                  Nn^.Tag := TagOf(S);
                  JvNode(R, Nn);
                End;
              End;
            End
            Else If (M = 'addEventListener') Or (M = 'removeEventListener') Then
            Begin
              If Root <> Nil Then JsNodeMethod(Root, M, Argc, R);
            End
            Else If (M = 'open') Or (M = 'close') Or (M = 'hasFocus') Then JvBool(R, True)
            Else JsThrowMsg('TypeError: document.' + M + ' n''est pas une fonction');
          JO_WINDOW :
            If (M = 'addEventListener') Or (M = 'removeEventListener') Then
            Begin
              If Root <> Nil Then JsNodeMethod(Root, M, Argc, R);
            End
            Else If M = 'open' Then
            Begin
              JsNavUrl := JsArgP(Argc, 0);
              R.K := JV_NULL;
            End
            Else If (M = 'scrollTo') Or (M = 'scrollBy') Or (M = 'scroll') Or (M = 'focus') Or (M = 'blur') Or
                    (M = 'close') Or (M = 'print') Or (M = 'moveTo') Or (M = 'resizeTo') Then
            Else If M = 'getComputedStyle' Then
            Begin
              JsArg(Argc, 0, V);
              If V.K = JV_NODE Then JsNodeGet(Pointer(V.P), 'style', R);
            End
            Else JsCallNative(M, O, Argc, R);
          JO_LOCATION :
            If (M = 'reload') Then JsNavUrl := JsPageUrl
            Else If (M = 'assign') Or (M = 'replace') Then JsNavUrl := JsArgP(Argc, 0)
            Else If M = 'toString' Then JvStr(R, JsPageUrl);
          JO_HISTORY :
            If M = 'back' Then JsHistCmd := -1
            Else If M = 'forward' Then JsHistCmd := 1
            Else If M = 'go' Then JsHistCmd := JsArgInt(Argc, 0, 0);
          JO_STYLE :
            If M = 'setProperty' Then JsStyleSet(Ob^.Node, LowStr(JsArgP(Argc, 0)), JsArgP(Argc, 1))
            Else If M = 'getPropertyValue' Then JvStr(R, JsStyleGet(Ob^.Node, LowStr(JsArgP(Argc, 0))))
            Else If M = 'removeProperty' Then JsStyleSet(Ob^.Node, LowStr(JsArgP(Argc, 0)), '');
          JO_CLASSLIST :
            Begin
              S := JsArgP(Argc, 0);
              M := M;
              If M = 'contains' Then JvBool(R, HasClass(Ob^.Node, S))
              Else If (M = 'add') Or (M = 'remove') Or (M = 'toggle') Then
              Begin
                If HasClass(Ob^.Node, S) Then
                Begin
                  If M <> 'add' Then
                  Begin
                    { retirer le mot S }
                    T.P := 0;
                    M := ' ' + GetAttr(Ob^.Node, 'class') + ' ';
                    While Pos(' ' + S + ' ', M) > 0 Do Delete(M, Pos(' ' + S + ' ', M), Length(S) + 1);
                    JsSetAttrS(Ob^.Node, 'class', TrimS(M));
                    JvBool(R, False);
                  End;
                End
                Else If M <> 'remove' Then
                Begin
                  JsSetAttrS(Ob^.Node, 'class', TrimS(GetAttr(Ob^.Node, 'class') + ' ' + S));
                  JvBool(R, True);
                End;
              End;
            End;
          JO_STORAGE :
            If M = 'getItem' Then
            Begin
              JsArgStr(Argc, 0, V);
              P := JsFindProp(Ob, V.P, V.L);
              If P = Nil Then R.K := JV_NULL Else R := P^.V;
            End
            Else If M = 'setItem' Then
            Begin
              JsArgStr(Argc, 0, V);
              JsArgStr(Argc, 1, W);
              JsSetPropAL(Ob, V.P, V.L, W);
            End
            Else If M = 'removeItem' Then
            Begin
              JsArgStr(Argc, 0, V);
              R.K := JV_NULL;
              If JsFindProp(Ob, V.P, V.L) <> Nil Then JsFindProp(Ob, V.P, V.L)^.V := R;
              JvUndef(R);
            End
            Else If M = 'clear' Then Ob^.Props := Nil;
          JO_EVENT :
            If M = 'preventDefault' Then JsPrevent := True;
        Else
          If (M = 'hasOwnProperty') Then
          Begin
            JsArgStr(Argc, 0, V);
            JvBool(R, JsFindProp(Ob, V.P, V.L) <> Nil);
          End
          Else If M = 'toString' Then JsToStrV(O, R)
          Else If M = 'valueOf' Then R := O
          Else JsThrowMsg('TypeError: ' + M + ' n''est pas une fonction');
        End;
      End;
  Else
    JsThrowMsg('TypeError: ' + JsToPStr(O) + '.' + M + ' n''est pas une fonction');
  End;
End;

{ ---------------- initialisation, scripts, evenements, minuteurs ---------------- }

Function JsSingleton(Cls : LongInt; Name : String) : PJObj;
Var O : PJObj; V : TJV;
Begin
  O := JsNewObj;
  If O <> Nil Then
  Begin
    O^.Cls := Cls;
    JvObjV(V, O);
    If (JsWindow <> Nil) And (Name <> '') Then JsSetPropS(JsWindow, Name, V);
  End;
  JsSingleton := O;
End;

Procedure JsDefNat(Name : String);
Var V, N : TJV;
Begin
  JvStr(N, Name);
  JvNat(V, N.P, N.L);
  JsSetPropAL(JsWindow, N.P, N.L, V);
End;

{ nouvelle page : contexte vide (l'arene vient d'etre videe) }
Procedure JsInit;
Var V : TJV; K : LongInt;
Begin
  JsErr := False; JsCtl := JC_NONE; JsKill := False;
  JsSteps := 0; JsDepth := 0; JsSp := 0;
  JsDirty := False; JsNavUrl := ''; JsAlertN := 0; JsWriteP := 0; JsWriteL := 0; JsTitleSet := False;
  JsPrevent := False; JsRescan := False; JsHistCmd := 0;
  JsScriptN := 0; JsFuncN := 0; JsErrCount := 0; JsLastErr := '';
  JsLsN := 0;
  For K := 0 To JS_MAXTIMERS - 1 Do JsTmUsed[K] := False;
  JvUndef(JsThis);
  JsGlobal := JsNewEnv(Nil);
  If JsGlobal <> Nil Then JsGlobal^.IsFunc := True;
  JsEnv := JsGlobal;
  JsWindow := JsNewObj;
  JsReady := (JsGlobal <> Nil) And (JsWindow <> Nil) And (JsStk <> 0);
  If Not JsReady Then Exit;
  JsWindow^.Cls := JO_WINDOW;
  JvObjV(V, JsWindow);
  JsSetPropS(JsWindow, 'window', V);
  JsSetPropS(JsWindow, 'self', V);
  JsSetPropS(JsWindow, 'top', V);
  JsSetPropS(JsWindow, 'parent', V);
  JsSetPropS(JsWindow, 'globalThis', V);
  JsDocObj := JsSingleton(JO_DOCUMENT, 'document');
  JsConObj := JsSingleton(JO_CONSOLE, 'console');
  JsMathObj := JsSingleton(JO_MATH, 'Math');
  JsJsonObj := JsSingleton(JO_JSON, 'JSON');
  JsNavObj := JsSingleton(JO_NAVIGATOR, 'navigator');
  JsLocObj := JsSingleton(JO_LOCATION, 'location');
  JsScrObj := JsSingleton(JO_SCREEN, 'screen');
  JsHistObj := JsSingleton(JO_HISTORY, 'history');
  JsStoreObj := JsSingleton(JO_STORAGE, 'localStorage');
  JvObjV(V, JsStoreObj);
  JsSetPropS(JsWindow, 'sessionStorage', V);
  JsDefNat('alert'); JsDefNat('confirm'); JsDefNat('prompt'); JsDefNat('parseInt'); JsDefNat('parseFloat');
  JsDefNat('isNaN'); JsDefNat('isFinite'); JsDefNat('setTimeout'); JsDefNat('setInterval');
  JsDefNat('clearTimeout'); JsDefNat('clearInterval'); JsDefNat('String'); JsDefNat('Number'); JsDefNat('Boolean');
  JsDefNat('Array'); JsDefNat('Object'); JsDefNat('Image'); JsDefNat('Date'); JsDefNat('Error'); JsDefNat('TypeError');
  JsDefNat('RangeError'); JsDefNat('SyntaxError'); JsDefNat('ReferenceError'); JsDefNat('encodeURIComponent');
  JsDefNat('decodeURIComponent'); JsDefNat('encodeURI'); JsDefNat('decodeURI'); JsDefNat('escape');
  JsDefNat('unescape'); JsDefNat('eval');
  If JsRand = 0 Then JsRand := KTicks Or 1;
End;

{ execution d'un script de la page ; erreurs non capturees -> console }
Procedure JsRunScript(A, L, Line0 : LongInt; Var ThisV : TJV);
Var Last : TJV;
Begin
  If Not JsReady Then Exit;
  Inc(JsScriptN);
  JsSteps := 0; JsCtl := JC_NONE; JsKill := False; JsDepth := 0;
  If Not JsRunCode(A, L, Line0, ThisV, Last) Then
  Begin
    If JsCtl = JC_THROW Then
    Begin
      JsCtl := JC_NONE;
      If JsKill Then JsLastErr := JsAbortMsg
      Else JsLastErr := 'Exception non capturee : ' + JsToPStr(JsExc);
      JsConsole(JsLastErr, 1);
      Inc(JsErrCount);
    End;
  End;
  JsCtl := JC_NONE; JsKill := False;
End;

{ console : evaluation d'une commande, resultat affiche }
Procedure JsConsoleEval(S : String);
Var V, Last, U : TJV;
Begin
  JsConsole(S, 2);
  If Not JsReady Then
  Begin
    JsConsole('JavaScript indisponible (memoire)', 1);
    Exit;
  End;
  JsSteps := 0; JsCtl := JC_NONE; JsKill := False; JsDepth := 0;
  JvStr(V, S);
  JvUndef(U);
  If JsRunCode(V.P, V.L, 1, U, Last) Then JsConsole(JsInspect(Last, 0), 3)
  Else If JsCtl = JC_THROW Then
  Begin
    If JsKill Then JsConsole(JsAbortMsg, 1) Else JsConsole('Uncaught ' + JsToPStr(JsExc), 1);
    Inc(JsErrCount);
  End;
  JsCtl := JC_NONE; JsKill := False;
End;

{ evenement Ev sur N, propage vers les parents : attribut onXXX (code) et
  auditeurs ; vrai si l'action par defaut est annulee }
{ un gestionnaire de Ev existe-t-il sur N ou ses parents ? }
Function JsHasHandler(N : PNode; Ev : String) : Boolean;
Var C : PNode; K, Cnt : LongInt;
Begin
  JsHasHandler := False;
  C := N; Cnt := 0;
  While (C <> Nil) And (Cnt < 64) Do
  Begin
    If (C^.Kind = NODE_ELEM) And (FindAttr(C, 'on' + Ev) <> Nil) Then
    Begin
      JsHasHandler := True;
      Exit;
    End;
    For K := 0 To JsLsN - 1 Do
      If (JsLsNode[K] = C) And (JsLsEv[K] = Ev) Then
      Begin
        JsHasHandler := True;
        Exit;
      End;
    C := C^.Parent;
    Inc(Cnt);
  End;
End;

Function JsFire(N : PNode; Ev : String) : Boolean;
Var C : PNode; K, Cnt : LongInt; Evo : PJObj; EvV, ThisV, R, V : TJV; A : PAttr;
Begin
  JsFire := False;
  If Not JsReady Or (N = Nil) Then Exit;
  If Not JsHasHandler(N, Ev) Then Exit;
  JsPrevent := False;
  Evo := JsNewObj;
  If Evo = Nil Then Exit;
  Evo^.Cls := JO_EVENT; Evo^.Node := N;
  JvStr(V, Ev); JsSetPropS(Evo, 'type', V);
  JvNode(V, N); JsSetPropS(Evo, 'target', V); JsSetPropS(Evo, 'srcElement', V);
  JvObjV(EvV, Evo);
  C := N; Cnt := 0;
  While (C <> Nil) And (Cnt < 64) Do
  Begin
    JvNode(ThisV, C);
    JsSetPropS(Evo, 'currentTarget', ThisV);
    A := FindAttr(C, 'on' + Ev);
    If A <> Nil Then
    Begin
      { code de l'attribut : corps d'une fonction (return false annule) }
      JsSteps := 0; JsCtl := JC_NONE; JsKill := False; JsDepth := 0;
      JvStr(V, 'event');
      JsDeclare(JsGlobal, V.P, V.L, EvV, 0);
      JvStr(V, '(function(){');
      JsConcat(V, V.P, V.L, A^.Val, A^.VLen);
      JvStr(R, #10 + '})()');
      JsConcat(V, V.P, V.L, R.P, R.L);
      If JsRunCode(V.P, V.L, 1, ThisV, R) Then
      Begin
        If (R.K = JV_BOOL) And (R.N = 0) Then JsPrevent := True;
      End
      Else If JsCtl = JC_THROW Then
      Begin
        JsLastErr := 'Exception (on' + Ev + ') : ' + JsToPStr(JsExc);
        JsConsole(JsLastErr, 1);
        Inc(JsErrCount);
      End;
      JsCtl := JC_NONE;
    End;
    For K := 0 To JsLsN - 1 Do
      If (K < JsLsN) And (JsLsNode[K] = C) And (JsLsEv[K] = Ev) Then
      Begin
        JsSteps := 0; JsCtl := JC_NONE; JsKill := False; JsDepth := 0;
        If JsPush(EvV) Then
        Begin
          JsCallValue(JsLsFn[K], ThisV, 1, R);
          Dec(JsSp);
          If (R.K = JV_BOOL) And (R.N = 0) Then JsPrevent := True;
        End;
        If JsCtl = JC_THROW Then
        Begin
          JsLastErr := 'Exception (' + Ev + ') : ' + JsToPStr(JsExc);
          JsConsole(JsLastErr, 1);
          Inc(JsErrCount);
        End;
        JsCtl := JC_NONE;
      End;
    C := C^.Parent;
    Inc(Cnt);
  End;
  JsKill := False;
  JsFire := JsPrevent;
End;

{ minuteurs echus ; vrai si au moins un a ete execute }
Function JsRunTimers : Boolean;
Var K : LongInt; F, U, R : TJV; T : LongInt;
Begin
  JsRunTimers := False;
  If Not JsReady Then Exit;
  T := KTicks;
  For K := 0 To JS_MAXTIMERS - 1 Do
    If JsTmUsed[K] And (T - JsTmAt[K] >= 0) Then
    Begin
      F := JsTmFn[K];
      If JsTmEvery[K] > 0 Then JsTmAt[K] := T + JsTmEvery[K] Else JsTmUsed[K] := False;
      JsSteps := 0; JsCtl := JC_NONE; JsKill := False; JsDepth := 0;
      JvUndef(U);
      If F.K = JV_STR Then JsRunScript(F.P, F.L, 1, U)
      Else
      Begin
        JsCallValue(F, U, 0, R);
        If JsCtl = JC_THROW Then
        Begin
          JsLastErr := 'Exception (minuteur) : ' + JsToPStr(JsExc);
          JsConsole(JsLastErr, 1);
          Inc(JsErrCount);
        End;
        JsCtl := JC_NONE;
      End;
      JsRunTimers := True;
    End;
  JsKill := False;
End;

{ ==================================================================== }
{ Code QR (menu contextuel : "Creer un code QR pour cette page")       }
{ ==================================================================== }
{ Norme ISO/IEC 18004, algorithme de la bibliotheque de reference
  QR-Code-generator de Project Nayuki (licence MIT), comme dans le
  BROWSER.PAS d'origine : mode octet, correction de niveau L, masque
  choisi par les regles de penalite N1 a N4, Reed-Solomon sur GF(256)
  (polynome 11Dh).  L'original s'arretait a la version 5 (un seul bloc,
  106 octets) ; ici les versions 1 a 10 (blocs entrelaces et information
  de version des versions 7 et plus) couvrent toute adresse de 255
  octets (271 au plus en version 10). }

Const
  QR_MAXV = 10;
  QR_MAXS = 57;                            { 17 + 4 * 10 }
  QrEccPerBlock : Array[1..10] Of LongInt = (7, 10, 15, 20, 26, 18, 20, 24, 30, 18);
  QrNumBlocks : Array[1..10] Of LongInt = (1, 1, 1, 1, 1, 2, 2, 2, 2, 4);

Var
  QrSize : LongInt;
  QrMod : Array[0..QR_MAXS * QR_MAXS - 1] Of Byte;    { 1 : module sombre }
  QrFun : Array[0..QR_MAXS * QR_MAXS - 1] Of Byte;    { 1 : motif de fonction }
  QrData : Array[0..400] Of Byte;                     { mots de code de donnees }
  QrAll : Array[0..400] Of Byte;                      { donnees + correction, entrelaces }
  QrGen : Array[0..31] Of Byte;
  QrRem : Array[0..31] Of Byte;
  QrHist : Array[0..6] Of LongInt;

Function QrGet(X, Y : LongInt) : LongInt;
Begin
  QrGet := QrMod[Y * QR_MAXS + X];
End;

Procedure QrSetFun(X, Y, Dark : LongInt);
Begin
  If (X < 0) Or (Y < 0) Or (X >= QrSize) Or (Y >= QrSize) Then Exit;
  QrMod[Y * QR_MAXS + X] := Dark;
  QrFun[Y * QR_MAXS + X] := 1;
End;

Function QrRawModules(V : LongInt) : LongInt;
Var R, Na : LongInt;
Begin
  R := (16 * V + 128) * V + 64;
  If V >= 2 Then
  Begin
    Na := V Div 7 + 2;
    R := R - ((25 * Na - 10) * Na - 55);
    If V >= 7 Then R := R - 36;
  End;
  QrRawModules := R;
End;

Function QrDataCw(V : LongInt) : LongInt;
Begin
  QrDataCw := QrRawModules(V) Div 8 - QrEccPerBlock[V] * QrNumBlocks[V];
End;

{ octets utiles en mode octet (indicateur 4 bits + compteur 8 ou 16 bits) }
Function QrCapacity(V : LongInt) : LongInt;
Begin
  If V <= 9 Then QrCapacity := (QrDataCw(V) * 8 - 12) Div 8
  Else QrCapacity := (QrDataCw(V) * 8 - 20) Div 8;
End;

Function QrMul(X, Y : LongInt) : LongInt;
Var Z, I : LongInt;
Begin
  Z := 0;
  For I := 7 DownTo 0 Do
  Begin
    Z := (Z Shl 1) Xor ((Z Shr 7) * $11D);
    Z := Z Xor (((Y Shr I) And 1) * X);
  End;
  QrMul := Z And 255;
End;

Procedure QrDivisor(Deg : LongInt);
Var I, J, Root : LongInt;
Begin
  For I := 0 To 31 Do QrGen[I] := 0;
  QrGen[Deg - 1] := 1;
  Root := 1;
  For I := 0 To Deg - 1 Do
  Begin
    For J := 0 To Deg - 1 Do
    Begin
      QrGen[J] := QrMul(QrGen[J], Root);
      If J + 1 < Deg Then QrGen[J] := QrGen[J] Xor QrGen[J + 1];
    End;
    Root := QrMul(Root, 2);
  End;
End;

{ reste de la division des donnees QrData[Start..Start+Len-1] }
Procedure QrRemainder(Start, Len, Deg : LongInt);
Var I, J, F : LongInt;
Begin
  For I := 0 To 31 Do QrRem[I] := 0;
  For I := 0 To Len - 1 Do
  Begin
    F := QrData[Start + I] Xor QrRem[0];
    For J := 0 To Deg - 2 Do QrRem[J] := QrRem[J + 1];
    QrRem[Deg - 1] := 0;
    For J := 0 To Deg - 1 Do QrRem[J] := QrRem[J] Xor QrMul(QrGen[J], F);
  End;
End;

Procedure QrFinder(X, Y : LongInt);
Var Dx, Dy, D : LongInt;
Begin
  For Dy := -4 To 4 Do
    For Dx := -4 To 4 Do
    Begin
      D := MaxI(Abs(Dx), Abs(Dy));
      QrSetFun(X + Dx, Y + Dy, Ord((D <> 2) And (D <> 4)));
    End;
End;

Procedure QrAlign(X, Y : LongInt);
Var Dx, Dy : LongInt;
Begin
  For Dy := -2 To 2 Do
    For Dx := -2 To 2 Do
      QrSetFun(X + Dx, Y + Dy, Ord(MaxI(Abs(Dx), Abs(Dy)) <> 1));
End;

{ information de format (niveau L : bits 01) et masque }
Procedure QrFormatBits(Mask : LongInt);
Var Data, Rm, Bits, I : LongInt;
Begin
  Data := (1 Shl 3) Or Mask;
  Rm := Data;
  For I := 1 To 10 Do Rm := (Rm Shl 1) Xor ((Rm Shr 9) * $537);
  Bits := ((Data Shl 10) Or (Rm And $3FF)) Xor $5412;
  For I := 0 To 5 Do QrSetFun(8, I, (Bits Shr I) And 1);
  QrSetFun(8, 7, (Bits Shr 6) And 1);
  QrSetFun(8, 8, (Bits Shr 7) And 1);
  QrSetFun(7, 8, (Bits Shr 8) And 1);
  For I := 9 To 14 Do QrSetFun(14 - I, 8, (Bits Shr I) And 1);
  For I := 0 To 7 Do QrSetFun(QrSize - 1 - I, 8, (Bits Shr I) And 1);
  For I := 8 To 14 Do QrSetFun(8, QrSize - 15 + I, (Bits Shr I) And 1);
  QrSetFun(8, QrSize - 8, 1);
End;

Procedure QrVersionBits(V : LongInt);
Var Rm, Bits, I, A, B, Bit : LongInt;
Begin
  If V < 7 Then Exit;
  Rm := V;
  For I := 1 To 12 Do Rm := (Rm Shl 1) Xor ((Rm Shr 11) * $1F25);
  Bits := (V Shl 12) Or (Rm And $FFF);
  For I := 0 To 17 Do
  Begin
    Bit := (Bits Shr I) And 1;
    A := QrSize - 11 + I Mod 3;
    B := I Div 3;
    QrSetFun(A, B, Bit);
    QrSetFun(B, A, Bit);
  End;
End;

Procedure QrFunctionPatterns(V : LongInt);
Var I, J, Na, Stp, Ps, Last : LongInt; Pos : Array[0..6] Of LongInt;
Begin
  For I := 0 To QrSize - 1 Do
  Begin
    QrSetFun(6, I, Ord(I Mod 2 = 0));
    QrSetFun(I, 6, Ord(I Mod 2 = 0));
  End;
  QrFinder(3, 3);
  QrFinder(QrSize - 4, 3);
  QrFinder(3, QrSize - 4);
  If V >= 2 Then
  Begin
    Na := V Div 7 + 2;
    Stp := ((V * 4 + Na * 2 + 1) Div (Na * 2 - 2)) * 2;
    Pos[0] := 6;
    Ps := V * 4 + 10;
    For I := Na - 1 DownTo 1 Do
    Begin
      Pos[I] := Ps;
      Ps := Ps - Stp;
    End;
    Last := Na - 1;
    For I := 0 To Na - 1 Do
      For J := 0 To Na - 1 Do
        If Not (((I = 0) And (J = 0)) Or ((I = 0) And (J = Last)) Or ((I = Last) And (J = 0))) Then
          QrAlign(Pos[I], Pos[J]);
  End;
  QrFormatBits(0);
  QrVersionBits(V);
End;

{ placement en zigzag des mots de code (QrAll, N octets) }
Procedure QrCodewords(N : LongInt);
Var I, Right, Vert, J, X, Y : LongInt; Up : Boolean;
Begin
  I := 0;
  Right := QrSize - 1;
  While Right >= 1 Do
  Begin
    If Right = 6 Then Right := 5;
    For Vert := 0 To QrSize - 1 Do
      For J := 0 To 1 Do
      Begin
        X := Right - J;
        Up := ((Right + 1) And 2) = 0;
        If Up Then Y := QrSize - 1 - Vert Else Y := Vert;
        If (QrFun[Y * QR_MAXS + X] = 0) And (I < N * 8) Then
        Begin
          QrMod[Y * QR_MAXS + X] := (QrAll[I Shr 3] Shr (7 - (I And 7))) And 1;
          Inc(I);
        End;
      End;
    Right := Right - 2;
  End;
End;

Procedure QrApplyMask(M : LongInt);
Var X, Y : LongInt; Inv : Boolean;
Begin
  For Y := 0 To QrSize - 1 Do
    For X := 0 To QrSize - 1 Do
      If QrFun[Y * QR_MAXS + X] = 0 Then
      Begin
        Case M Of
          0 : Inv := (X + Y) Mod 2 = 0;
          1 : Inv := Y Mod 2 = 0;
          2 : Inv := X Mod 3 = 0;
          3 : Inv := (X + Y) Mod 3 = 0;
          4 : Inv := (X Div 3 + Y Div 2) Mod 2 = 0;
          5 : Inv := (X * Y) Mod 2 + (X * Y) Mod 3 = 0;
          6 : Inv := ((X * Y) Mod 2 + (X * Y) Mod 3) Mod 2 = 0;
        Else
          Inv := ((X + Y) Mod 2 + (X * Y) Mod 3) Mod 2 = 0;
        End;
        If Inv Then QrMod[Y * QR_MAXS + X] := QrMod[Y * QR_MAXS + X] Xor 1;
      End;
End;

Procedure QrAddHist(Run : LongInt);
Var K : LongInt;
Begin
  If QrHist[0] = 0 Then Run := Run + QrSize;
  For K := 6 DownTo 1 Do QrHist[K] := QrHist[K - 1];
  QrHist[0] := Run;
End;

Function QrCountPat : LongInt;
Var N, R : LongInt; Core : Boolean;
Begin
  N := QrHist[1];
  Core := (N > 0) And (QrHist[2] = N) And (QrHist[3] = N * 3) And (QrHist[4] = N) And (QrHist[5] = N);
  R := 0;
  If Core And (QrHist[0] >= N * 4) And (QrHist[6] >= N) Then Inc(R);
  If Core And (QrHist[6] >= N * 4) And (QrHist[0] >= N) Then Inc(R);
  QrCountPat := R;
End;

Function QrTermCount(Color, Run : LongInt) : LongInt;
Begin
  If Color <> 0 Then
  Begin
    QrAddHist(Run);
    Run := 0;
  End;
  Run := Run + QrSize;
  QrAddHist(Run);
  QrTermCount := QrCountPat;
End;

Function QrPenalty : LongInt;
Var R, X, Y, K, Color, Run, Dark, Total, C : LongInt;
Begin
  R := 0;
  { lignes puis colonnes : series de meme couleur, motifs de repere }
  For K := 0 To 1 Do
    For Y := 0 To QrSize - 1 Do
    Begin
      Color := 0; Run := 0;
      For X := 0 To 6 Do QrHist[X] := 0;
      For X := 0 To QrSize - 1 Do
      Begin
        If K = 0 Then C := QrGet(X, Y) Else C := QrGet(Y, X);
        If C = Color Then
        Begin
          Inc(Run);
          If Run = 5 Then R := R + 3
          Else If Run > 5 Then Inc(R);
        End
        Else
        Begin
          QrAddHist(Run);
          If Color = 0 Then R := R + QrCountPat * 40;
          Color := C;
          Run := 1;
        End;
      End;
      R := R + QrTermCount(Color, Run) * 40;
    End;
  { blocs 2 x 2 }
  For Y := 0 To QrSize - 2 Do
    For X := 0 To QrSize - 2 Do
    Begin
      C := QrGet(X, Y);
      If (C = QrGet(X + 1, Y)) And (C = QrGet(X, Y + 1)) And (C = QrGet(X + 1, Y + 1)) Then R := R + 3;
    End;
  { equilibre sombre / clair }
  Dark := 0;
  For Y := 0 To QrSize - 1 Do
    For X := 0 To QrSize - 1 Do Dark := Dark + QrGet(X, Y);
  Total := QrSize * QrSize;
  K := (Abs(Dark * 20 - Total * 10) + Total - 1) Div Total - 1;
  R := R + K * 10;
  QrPenalty := R;
End;

Var QrBits : LongInt;                     { bits deja ecrits dans QrData }

Procedure QrAddBits(Value, Count : LongInt);
Var J : LongInt;
Begin
  For J := Count - 1 DownTo 0 Do
  Begin
    If ((Value Shr J) And 1) <> 0 Then
      QrData[QrBits Shr 3] := QrData[QrBits Shr 3] Or (1 Shl (7 - (QrBits And 7)));
    Inc(QrBits);
  End;
End;

{ code QR de S ; faux si S est trop long (plus de 271 octets) }
Function QrEncode(S : String) : Boolean;
Var V, N, Cap, I, K, Nb, Ecc, Raw, NShort, ShortLen, DatLen, Ofs, L, M, Best, BestP, P : LongInt;
Begin
  QrEncode := False;
  N := Length(S);
  V := 1;
  While (V <= QR_MAXV) And (QrCapacity(V) < N) Do Inc(V);
  If V > QR_MAXV Then Exit;
  QrSize := V * 4 + 17;
  { segment en mode octet, terminaison, octets de bourrage }
  Cap := QrDataCw(V);
  For I := 0 To 400 Do QrData[I] := 0;
  QrBits := 0;
  QrAddBits(4, 4);
  If V <= 9 Then QrAddBits(N, 8) Else QrAddBits(N, 16);
  For I := 1 To N Do QrAddBits(Ord(S[I]), 8);
  QrAddBits(0, MinI(4, Cap * 8 - QrBits));
  QrAddBits(0, (8 - QrBits Mod 8) Mod 8);
  K := $EC;
  While QrBits < Cap * 8 Do
  Begin
    QrAddBits(K, 8);
    K := K Xor ($EC Xor $11);
  End;
  { correction d'erreur par bloc, puis entrelacement }
  Nb := QrNumBlocks[V];
  Ecc := QrEccPerBlock[V];
  Raw := QrRawModules(V) Div 8;
  NShort := Nb - Raw Mod Nb;
  ShortLen := Raw Div Nb - Ecc;
  QrDivisor(Ecc);
  Ofs := 0;
  For I := 0 To Nb - 1 Do
  Begin
    If I < NShort Then DatLen := ShortLen Else DatLen := ShortLen + 1;
    QrRemainder(Ofs, DatLen, Ecc);
    L := I;
    For K := 0 To DatLen - 1 Do
    Begin
      If K = ShortLen Then L := L - NShort;
      QrAll[L] := QrData[Ofs + K];
      L := L + Nb;
    End;
    L := Cap + I;
    For K := 0 To Ecc - 1 Do
    Begin
      QrAll[L] := QrRem[K];
      L := L + Nb;
    End;
    Ofs := Ofs + DatLen;
  End;
  { matrice : motifs, donnees, meilleur masque }
  For I := 0 To QR_MAXS * QR_MAXS - 1 Do
  Begin
    QrMod[I] := 0; QrFun[I] := 0;
  End;
  QrFunctionPatterns(V);
  QrCodewords(Raw);
  Best := 0; BestP := 2147483647;
  For M := 0 To 7 Do
  Begin
    QrApplyMask(M);
    QrFormatBits(M);
    P := QrPenalty;
    If P < BestP Then
    Begin
      BestP := P; Best := M;
    End;
    QrApplyMask(M);
  End;
  QrApplyMask(Best);
  QrFormatBits(Best);
  QrEncode := True;
End;

{ ==================================================================== }
{ Interface de Presentation Manager                                     }
{ ==================================================================== }

Const
  TBH = 42;                   { barre d'outils }
  ADH = 30;                   { ligne de l'adresse }
  SBH = 22;                   { barre d'etat }
  SCW = 16;                   { barre de defilement }
  NBTN = 7;
  BT_BACK = 0; BT_FWD = 1; BT_STOP = 2; BT_RELOAD = 3; BT_HOME = 4; BT_MARK = 5; BT_SRC = 6;

Var
  Hab, Hmq, Frame, Client, View, UrlEf, GoBtn, VScroll, MenuHw : LongInt;
  CW, CH, VW, VH, ScrollY : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..4095] Of Byte;
  MenuLen : LongInt;
  BtnIcon : Array[0..NBTN] Of LongInt;
  BtnDown, BtnHover : LongInt;
  StatusText, LinkHover : String;
  CurUrl, PendUrl, PendPost, LoadUrl : String;
  Pending, LoadingPage, LoadingImg, TimerOn, NeedLayout, RefreshTick : LongInt;
  LastLayout, LoadStart : LongInt;
  HistUrl : Array[0..MAX_HIST - 1] Of String;
  HistPos, HistLen, HistMove : LongInt;
  Plain : Boolean;
  SrcMode : Boolean;               { chargement d'une adresse view-source: }
  RawBuf, RawLen : LongInt;       { page telle que recue (sans conversion) }
  QrFr, QrCl : LongInt; QrTitle, QrText : String;
  CtxMenu : LongInt; CtxLink : String; CtxElem : PNode; B2Down : Boolean;
  { ressources de la page (feuilles CSS et scripts externes) chargees avant
    la mise en page, dans l'ordre du document }
  ResN, ResNext, LoadingRes : LongInt;
  ResNode : Array[0..63] Of PNode;
  ResKind : Array[0..63] Of Byte;        { 1 CSS, 2 script }
  ResUrl : Array[0..63] Of String;
  { journal reseau (outils de developpement) }
  NetN, FetchT0 : LongInt;
  NetUrl : Array[0..99] Of String;
  NetMeth : Array[0..99] Of String[4];
  NetStat, NetSize, NetMs : Array[0..99] Of LongInt;
  NetType : Array[0..99] Of String[12];
  HoverElem : PNode;
  JsPendingOnload : Boolean;
  FetchU : String;
  { boites de dialogue }
  DlgFr, DlgCl, DlgEf, DlgLb, DlgMode : LongInt;
  DlgPrompt : String;
  IconHdr : Array[0..15] Of LongInt;
  IconBits : Array[0..32 * 32 * 3 + 64] Of Byte;
  IconMask : Array[0..4 * 64 + 16] Of Byte;
  IconPx : Array[0..32 * 32 - 1] Of LongInt;

{ --- outils --- }

{ etat des outils de developpement (voir plus bas) }
Const
  DT_INSP = 1; DT_DEBUG = 2; DT_STYLE = 3; DT_CONSOLE = 4; DT_NET = 5;
  DEV_TABH = 24; DEV_ROWH = 16; ID_DEVIN = 40; ID_DEVSB = 41;

Var
  DevOpen, DevPick : Boolean;
  DevWin, DevIn, DevSb, DevH, DevTab : LongInt;
  DevSel : PNode;
  DevTop : Array[1..5] Of LongInt;
  DevRowN : LongInt;
  DevRowNode : Array[0..79] Of PNode;
  DevRowX : Array[0..79] Of LongInt;
  DevColN : LongInt;
  DevCol : Array[0..511] Of PNode;
  DevSrcSel, DevScrSel : LongInt;     { feuille et script choisis }
  DevEditLine : LongInt;              { ligne en cours de modification (-1) }
  DevHistN, DevHistPos : LongInt;
  DevHist : Array[0..19] Of String;
  DevTotal : LongInt;                 { lignes de l'onglet (barre de defilement) }
  DevNetSel : LongInt;


Procedure ShowMsg(T, C : String; Fl : LongInt);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(T), Z2(C), 0, Fl Or MB_MOVEABLE);
End;

Procedure SetStatus(S : String);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = StatusText Then Exit;
  StatusText := S;
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CW; Rc[3] := SBH;
  Dummy := WinInvalidateRect(Client, LongInt(@Rc), 0);
End;

Procedure RedrawToolbar;
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[0] := 0; Rc[1] := CH - TBH; Rc[2] := CW; Rc[3] := CH;
  Dummy := WinInvalidateRect(Client, LongInt(@Rc), 0);
End;

Procedure RedrawView;
Begin
  Dummy := WinInvalidateRect(View, 0, 0);
End;

{ --- icones de la barre d'outils (API des pointeurs et icones d'OS/2) --- }

Type
  TPoly = Array[0..9] Of LongInt;

Procedure IPx(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < 32) And (Y >= 0) And (Y < 32) Then IconPx[Y * 32 + X] := C;
End;

Procedure IBar(X1, Y1, X2, Y2, C : LongInt);
Var X, Y : LongInt;
Begin
  For Y := Y1 To Y2 Do
    For X := X1 To X2 Do IPx(X, Y, C);
End;

{ disque plein (Y depuis le haut de l'icone) }
Procedure IDisc(Cx, Cy, R, C : LongInt);
Var X, Y : LongInt;
Begin
  For Y := -R To R Do
    For X := -R To R Do
      If X * X + Y * Y <= R * R + R Then IPx(Cx + X, Cy + Y, C);
End;

{ polygone convexe : remplissage par lignes }
Procedure IPoly(N : LongInt; Var Px, Py : TPoly; C : LongInt);
Var Y, K, J, Xa, Xb, X, Y1, Y2 : LongInt;
Begin
  Y1 := 99; Y2 := -99;
  For K := 0 To N - 1 Do
  Begin
    If Py[K] < Y1 Then Y1 := Py[K];
    If Py[K] > Y2 Then Y2 := Py[K];
  End;
  For Y := Y1 To Y2 Do
  Begin
    Xa := 99; Xb := -99;
    For K := 0 To N - 1 Do
    Begin
      J := (K + 1) Mod N;
      If ((Py[K] <= Y) And (Py[J] >= Y)) Or ((Py[J] <= Y) And (Py[K] >= Y)) Then
      Begin
        If Py[J] = Py[K] Then
        Begin
          If Px[K] < Xa Then Xa := Px[K];
          If Px[J] < Xa Then Xa := Px[J];
          If Px[K] > Xb Then Xb := Px[K];
          If Px[J] > Xb Then Xb := Px[J];
        End
        Else
        Begin
          X := Px[K] + ((Y - Py[K]) * (Px[J] - Px[K])) Div (Py[J] - Py[K]);
          If X < Xa Then Xa := X;
          If X > Xb Then Xb := X;
        End;
      End;
    End;
    For X := Xa To Xb Do IPx(X, Y, C);
  End;
End;

{ contour noir des pels opaques (relief des icones de Warp) }
Procedure IOutline;
Var X, Y : LongInt; Tmp : Array[0..32 * 32 - 1] Of LongInt;
Begin
  For X := 0 To 32 * 32 - 1 Do Tmp[X] := IconPx[X];
  For Y := 0 To 31 Do
    For X := 0 To 31 Do
      If Tmp[Y * 32 + X] < 0 Then
        If ((X > 0) And (Tmp[Y * 32 + X - 1] >= 0) And (Tmp[Y * 32 + X - 1] <> 0)) Or
           ((X < 31) And (Tmp[Y * 32 + X + 1] >= 0) And (Tmp[Y * 32 + X + 1] <> 0)) Or
           ((Y > 0) And (Tmp[(Y - 1) * 32 + X] >= 0) And (Tmp[(Y - 1) * 32 + X] <> 0)) Or
           ((Y < 31) And (Tmp[(Y + 1) * 32 + X] >= 0) And (Tmp[(Y + 1) * 32 + X] <> 0)) Then
          IconPx[Y * 32 + X] := 0;
End;

{ dessin de l'icone K (pels -1 : transparents) }
Procedure DrawIcon(K : LongInt);
Var Px, Py : TPoly; I : LongInt;
Begin
  For I := 0 To 32 * 32 - 1 Do IconPx[I] := -1;
  Case K Of
    BT_BACK, BT_FWD :
      Begin
        { fleche verte }
        Px[0] := 3; Py[0] := 15; Px[1] := 15; Py[1] := 4; Px[2] := 15; Py[2] := 10; Px[3] := 28; Py[3] := 10;
        Px[4] := 28; Py[4] := 20; Px[5] := 15; Py[5] := 20; Px[6] := 15; Py[6] := 26;
        If K = BT_FWD Then
          For I := 0 To 6 Do Px[I] := 31 - Px[I];
        IPoly(7, Px, Py, $00A000);
        { reflet }
        If K = BT_BACK Then IBar(15, 11, 27, 12, $60E060) Else IBar(4, 11, 16, 12, $60E060);
      End;
    BT_STOP :
      Begin
        { panneau rouge octogonal }
        Px[0] := 10; Py[0] := 3; Px[1] := 21; Py[1] := 3; Px[2] := 28; Py[2] := 10; Px[3] := 28; Py[3] := 21;
        Px[4] := 21; Py[4] := 28; Px[5] := 10; Py[5] := 28; Px[6] := 3; Py[6] := 21; Px[7] := 3; Py[7] := 10;
        IPoly(8, Px, Py, $D00000);
        IBar(8, 14, 23, 17, $FFFFFF);
      End;
    BT_RELOAD :
      Begin
        { fleche circulaire bleue }
        IDisc(16, 16, 11, $0050C8);
        IDisc(16, 16, 6, -1);
        IBar(17, 3, 28, 15, -1);
        Px[0] := 16; Py[0] := 2; Px[1] := 26; Py[1] := 9; Px[2] := 16; Py[2] := 15;
        IPoly(3, Px, Py, $0050C8);
      End;
    BT_HOME :
      Begin
        { maison : toit rouge, murs jaunes, porte }
        Px[0] := 16; Py[0] := 3; Px[1] := 30; Py[1] := 15; Px[2] := 2; Py[2] := 15;
        IPoly(3, Px, Py, $C00000);
        IBar(6, 15, 26, 28, $F0D060);
        IBar(13, 19, 19, 28, $804000);
        IBar(20, 18, 24, 22, $80C0FF);
      End;
    BT_MARK :
      Begin
        { livre de signets }
        IBar(6, 4, 25, 28, $0040A0);
        IBar(8, 6, 24, 26, $FFFFF0);
        IBar(8, 6, 9, 26, $0040A0);
        Px[0] := 17; Py[0] := 4; Px[1] := 22; Py[1] := 4; Px[2] := 22; Py[2] := 16; Px[3] := 19; Py[3] := 13;
        Px[4] := 17; Py[4] := 16;
        IPoly(5, Px, Py, $E00000);
      End;
    BT_SRC :
      Begin
        { page de source : feuille et balise </> }
        IBar(6, 3, 26, 28, $FFFFFF);
        IBar(22, 3, 26, 7, -1);
        For I := 0 To 3 Do IPx(22 + I, 3 + I, 0);
        IBar(10, 10, 22, 10, $808080);
        IBar(10, 13, 22, 13, $808080);
        Px[0] := 8; Py[0] := 21; Px[1] := 12; Py[1] := 17; Px[2] := 12; Py[2] := 25;
        IPoly(3, Px, Py, $0000C0);
        Px[0] := 24; Py[0] := 21; Px[1] := 20; Py[1] := 17; Px[2] := 20; Py[2] := 25;
        IPoly(3, Px, Py, $0000C0);
      End;
    NBTN :
      Begin
        { globe (chargement) }
        IDisc(16, 16, 13, $2060D0);
        IBar(9, 9, 15, 13, $30A030);
        IBar(17, 18, 24, 23, $30A030);
        IBar(6, 18, 9, 20, $30A030);
      End;
  End;
  IOutline;
End;

{ icone d'OS/2 : bitmap de couleurs (24 bits) et masque ET/OU exclusif
  (1 bit, deux fois plus haut), WinCreatePointerIndirect }
Function MakeIcon(K : LongInt) : LongInt;
Var X, Y, C, A, Hc, Hm : LongInt; PtrInfo : Array[0..6] Of LongInt; Mh : Array[0..7] Of LongInt;
Begin
  DrawIcon(K);
  For X := 0 To SizeOf(IconMask) - 1 Do IconMask[X] := 0;
  For Y := 0 To 31 Do
    For X := 0 To 31 Do
    Begin
      { lignes du bas vers le haut }
      C := IconPx[(31 - Y) * 32 + X];
      A := Y * 96 + X * 3;
      If C < 0 Then
      Begin
        IconBits[A] := 0; IconBits[A + 1] := 0; IconBits[A + 2] := 0;
        { masque ET (moitie haute : lignes 32..63) : 1 = transparent }
        IconMask[(Y + 32) * 4 + X Shr 3] := IconMask[(Y + 32) * 4 + X Shr 3] Or ($80 Shr (X And 7));
      End
      Else
      Begin
        IconBits[A] := C And 255; IconBits[A + 1] := (C Shr 8) And 255; IconBits[A + 2] := (C Shr 16) And 255;
      End;
    End;
  { BITMAPINFOHEADER2 : cbFix 16, cx, cy, plans, bits }
  IconHdr[0] := 16; IconHdr[1] := 32; IconHdr[2] := 32; IconHdr[3] := 1 Or (24 Shl 16);
  Hc := GpiCreateBitmap(0, LongInt(@IconHdr), 4, LongInt(@IconBits), LongInt(@IconHdr));
  Mh[0] := 16; Mh[1] := 32; Mh[2] := 64; Mh[3] := 1 Or (1 Shl 16); Mh[4] := 0; Mh[5] := $FFFFFF;
  Hm := GpiCreateBitmap(0, LongInt(@Mh), 4, LongInt(@IconMask), LongInt(@Mh));
  { POINTERINFO : fPointer, xHotspot, yHotspot, hbmPointer, hbmColor,
    hbmMiniPointer, hbmMiniColor }
  PtrInfo[0] := 0; PtrInfo[1] := 0; PtrInfo[2] := 0; PtrInfo[3] := Hm; PtrInfo[4] := Hc; PtrInfo[5] := 0;
  PtrInfo[6] := 0;
  MakeIcon := WinCreatePointerIndirect(HWND_DESKTOP, LongInt(@PtrInfo));
End;

{ --- dessin (GPI, couleurs RVB) --- }

Var
  Ps : LongInt;

Procedure RgbMode(H : LongInt);
Begin
  Dummy := GpiCreateLogColorTable(H, 0, 3, 0, 0, 0);
End;

Procedure GBoxF(X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  Dummy := GpiSetColor(Ps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Ps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiBox(Ps, DRO_FILL, LongInt(@P), 0, 0);
End;

Procedure GBoxO(X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Ps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Ps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiBox(Ps, DRO_OUTLINE, LongInt(@P), 0, 0);
End;

Procedure GLn(X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Ps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Ps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiLine(Ps, LongInt(@P));
End;

{ relief de Warp 3 : saillant ou creux }
Procedure Bevel(X1, Y1, X2, Y2 : LongInt; Raised : Boolean);
Var A, B : LongInt;
Begin
  If Raised Then
  Begin
    A := $FFFFFF; B := $808080;
  End
  Else
  Begin
    A := $808080; B := $FFFFFF;
  End;
  GLn(X1, Y2, X2, Y2, A); GLn(X1, Y1, X1, Y2, A);
  GLn(X1, Y1, X2, Y1, B); GLn(X2, Y1, X2, Y2, B);
End;

{ cadre enfonce des champs : visible aussi sur un fond blanc }
Procedure Sunken(X1, Y1, X2, Y2 : LongInt);
Begin
  GLn(X1, Y2, X2, Y2, $808080); GLn(X1, Y1, X1, Y2, $808080);
  GLn(X1, Y1, X2, Y1, $C0C0C0); GLn(X2, Y1, X2, Y2, $C0C0C0);
  GLn(X1 + 1, Y2 - 1, X2 - 1, Y2 - 1, $404040); GLn(X1 + 1, Y1 + 1, X1 + 1, Y2 - 1, $404040);
  GLn(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1, $E0E0E0); GLn(X2 - 1, Y1 + 1, X2 - 1, Y2 - 1, $E0E0E0);
End;

Var
  CurBox : LongInt;

Procedure SetBox(Scale : LongInt);
Var Sz : Array[0..1] Of LongInt;
Begin
  If Scale = CurBox Then Exit;
  CurBox := Scale;
  Sz[0] := CharWs[Scale] * 65536; Sz[1] := CharHs[Scale] * 65536;
  Dummy := GpiSetCharBox(Ps, LongInt(@Sz));
End;

{ texte : X a gauche, Yt : haut de la ligne (coordonnees de la fenetre) }
Procedure TextAt(X, Yt, Scale, Fl, C, A, N : LongInt);
Var P : Array[0..1] Of LongInt; Base, W : LongInt;
Begin
  If N <= 0 Then Exit;
  SetBox(Scale);
  Dummy := GpiSetColor(Ps, C);
  Base := Yt - (CharHs[Scale] * 3) Div 4;
  P[0] := X; P[1] := Base;
  Dummy := GpiCharStringAt(Ps, LongInt(@P), N, A);
  If (Fl And ST_BOLD) <> 0 Then
  Begin
    P[0] := X + 1; P[1] := Base;
    Dummy := GpiCharStringAt(Ps, LongInt(@P), N, A);
  End;
  W := N * CharWs[Scale];
  If (Fl And ST_UNDER) <> 0 Then GLn(X, Base - 2, X + W - 1, Base - 2, C);
  If (Fl And ST_STRIKE) <> 0 Then GLn(X, Base + CharHs[Scale] Div 4, X + W - 1, Base + CharHs[Scale] Div 4, C);
End;

Procedure TextS(X, Yt : LongInt; S : String; C : LongInt);
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  TextAt(X, Yt, 1, 0, C, LongInt(@TxtBuf), Length(S));
End;

{ --- controles de formulaire (dessin) --- }

Procedure DrawCtl(K, X, Yt, W, H : LongInt);
Var Yb, M, I : LongInt; S, T : String;
Begin
  Yb := Yt - H + 1;
  Case CtType[K] Of
    CT_TEXT, CT_PASSWORD, CT_TEXTAREA :
      Begin
        GBoxF(X, Yb, X + W - 1, Yt, $FFFFFF);
        Sunken(X, Yb, X + W - 1, Yt);
        S := CtVal[K];
        If CtType[K] = CT_PASSWORD Then
        Begin
          T := '';
          For I := 1 To Length(S) Do T := T + '*';
          S := T;
        End;
        M := (W - 8) Div 8;
        If CtType[K] = CT_TEXTAREA Then
        Begin
          I := 0;
          While (S <> '') And (I * 16 + 20 <= H) Do
          Begin
            TextS(X + 4, Yt - 3 - I * 16, Copy(S, 1, M), 0);
            Delete(S, 1, M);
            Inc(I);
          End;
        End
        Else
        Begin
          If Length(S) > M Then S := Copy(S, Length(S) - M + 1, M);
          TextS(X + 4, Yt - 3, S, 0);
          If K = FocusCtl Then GLn(X + 4 + Length(S) * 8, Yb + 3, X + 4 + Length(S) * 8, Yt - 3, 0);
        End;
        If K = FocusCtl Then GBoxO(X + 1, Yb + 1, X + W - 2, Yt - 1, $000080);
      End;
    CT_CHECK, CT_RADIO :
      Begin
        GBoxF(X, Yb, X + W - 1, Yt, $FFFFFF);
        Sunken(X, Yb, X + W - 1, Yt);
        If CtChk[K] Then
        Begin
          If CtType[K] = CT_RADIO Then GBoxF(X + 4, Yb + 4, X + W - 5, Yt - 4, 0)
          Else
          Begin
            GLn(X + 3, Yb + 3, X + W - 4, Yt - 3, 0); GLn(X + 3, Yt - 3, X + W - 4, Yb + 3, 0);
            GLn(X + 4, Yb + 3, X + W - 3, Yt - 3, 0); GLn(X + 4, Yt - 3, X + W - 3, Yb + 3, 0);
          End;
        End;
      End;
    CT_SELECT :
      Begin
        GBoxF(X, Yb, X + W - 1, Yt, $FFFFFF);
        Sunken(X, Yb, X + W - 1, Yt);
        GBoxF(X + W - 18, Yb + 2, X + W - 3, Yt - 2, $C0C0C0);
        Bevel(X + W - 18, Yb + 2, X + W - 3, Yt - 2, True);
        For I := 0 To 3 Do GLn(X + W - 14 + I, Yt - 9 - I, X + W - 7 - I, Yt - 9 - I, 0);
        S := OptText(CtNode[K], CtSel[K]);
        TextS(X + 4, Yt - 3, Copy(S, 1, MaxI(0, (W - 26) Div 8)), 0);
        If K = FocusCtl Then GBoxO(X + 1, Yb + 1, X + W - 20, Yt - 1, $000080);
      End;
  Else
    Begin
      { bouton (envoyer, effacer, bouton, image sans image) }
      If (CtType[K] = CT_IMAGE) And (CtImg[K] >= 0) And (ImState[CtImg[K]] = 1) Then Exit;
      GBoxF(X, Yb, X + W - 1, Yt, $C0C0C0);
      GBoxO(X, Yb, X + W - 1, Yt, 0);
      Bevel(X + 1, Yb + 1, X + W - 2, Yt - 1, True);
      S := CtlLabel(K);
      TextS(X + (W - Length(S) * 8) Div 2, Yt - (H - 16) Div 2, S, 0);
    End;
  End;
End;

{ --- page (fenetre de vue) --- }

Procedure DrawImageOp(O : POp; X, Yt : LongInt);
Var I, Yb : LongInt; P : Array[0..7] Of LongInt; S : String;
Begin
  I := O^.Data;
  Yb := Yt - O^.H + 1;
  If (I >= 0) And (I < NImgs) And (ImState[I] = 1) And (ImBits[I] <> 0) Then
  Begin
    P[0] := X; P[1] := Yb; P[2] := X + O^.W; P[3] := Yb + O^.H;
    P[4] := 0; P[5] := 0; P[6] := ImW[I]; P[7] := ImH[I];
    Dummy := GpiDrawBits(Ps, ImBits[I], ImBmi[I], 4, LongInt(@P), $CC, 2);
    If O^.Link <> 0 Then GBoxO(X, Yb, X + O^.W - 1, Yt, LinkFg);
  End
  Else
  Begin
    { image absente : cadre et texte de remplacement }
    Bevel(X, Yb, X + O^.W - 1, Yt, False);
    If (O^.W > 12) And (O^.H > 12) Then
    Begin
      GBoxF(X + 3, Yt - 10, X + 9, Yt - 4, $C0C0C0);
      GBoxO(X + 3, Yt - 10, X + 9, Yt - 4, $808080);
    End;
    If (O^.Len > 0) And (O^.H >= 16) Then
    Begin
      S := ArGet(O^.Back, O^.Len);
      S := Copy(S, 1, MaxI(0, (O^.W - 14) Div 8));
      PutZ(LongInt(@TxtBuf), S);
      TextAt(X + 12, Yt - (O^.H - 16) Div 2, 1, 0, $404040, LongInt(@TxtBuf), Length(S));
    End;
  End;
End;

Procedure PaintView(H : LongInt);
Var O : POp; X, Yt, Yb, Bx0, By0, Bx1, By1, D : LongInt; Rc : Array[0..3] Of LongInt; E : PNode;
Begin
  Ps := WinBeginPaint(H, 0, LongInt(@Rc));
  If Ps = 0 Then Exit;
  RgbMode(Ps);
  Dummy := GpiSetBackMix(Ps, BM_LEAVEALONE);
  CurBox := 0;
  GBoxF(0, 0, VW, VH, PageBg);
  O := OpFirst;
  While O <> Nil Do
  Begin
    X := O^.X;
    Yt := VH - 1 - (O^.Y - ScrollY);
    Yb := Yt - O^.H + 1;
    If (Yb <= Rc[3]) And (Yt >= Rc[1] - 1) And (Yt >= -1) And (Yb <= VH) Then
      Case O^.Kind Of
        OP_TEXT : TextAt(X, Yt, MaxI(1, MinI(3, O^.Size)), O^.Style, MaxI(0, O^.Color), O^.Data, O^.Len);
        OP_RECT : GBoxF(X, Yb, X + O^.W - 1, Yt, O^.Color);
        OP_FRAME : GBoxO(X, Yb, X + O^.W - 1, Yt, O^.Color);
        OP_LINE :
          Begin
            GLn(X, Yt, X + O^.W - 1, Yt, $808080);
            GLn(X, Yt - 1, X + O^.W - 1, Yt - 1, $FFFFFF);
          End;
        OP_BULLET :
          Case O^.Style Of
            0 : GBoxF(X, Yb, X + O^.W - 1, Yt, O^.Color);
            1 : GBoxO(X, Yb, X + O^.W - 1, Yt, O^.Color);
          Else
            Begin
              GBoxF(X, Yb, X + O^.W - 1, Yt, O^.Color);
              GBoxF(X + 2, Yb + 2, X + O^.W - 3, Yt - 2, PageBg);
            End;
          End;
        OP_IMAGE : DrawImageOp(O, X, Yt);
        OP_CTRL : DrawCtl(O^.Data, X, Yt, O^.W, O^.H - 2);
      End;
    O := O^.Next;
  End;
  { inspecteur : cadre autour de l'element choisi }
  If DevOpen And (DevSel <> Nil) And (DevTab = DT_INSP) Then
  Begin
    Bx0 := 1000000; By0 := 1000000; Bx1 := -1; By1 := -1;
    O := OpFirst;
    While O <> Nil Do
    Begin
      E := O^.Elem; D := 0;
      While (E <> Nil) And (E <> DevSel) And (D < 80) Do
      Begin
        E := E^.Parent; Inc(D);
      End;
      If (E = DevSel) And (O^.W > 0) Then
      Begin
        Bx0 := MinI(Bx0, O^.X); By0 := MinI(By0, O^.Y);
        Bx1 := MaxI(Bx1, O^.X + O^.W); By1 := MaxI(By1, O^.Y + O^.H);
      End;
      O := O^.Next;
    End;
    If Bx1 >= 0 Then
    Begin
      Yt := VH - 1 - (By0 - ScrollY); Yb := VH - 1 - (By1 - ScrollY);
      GBoxO(Bx0 - 2, Yb - 1, Bx1 + 1, Yt + 2, $FF8000);
      GBoxO(Bx0 - 1, Yb, Bx1, Yt + 1, $FF8000);
    End;
  End;
  Dummy := WinEndPaint(Ps);
End;

{ --- defilement --- }

Procedure UpdateScroll;
Var Mx : LongInt;
Begin
  Mx := MaxI(0, PageH - VH);
  If ScrollY > Mx Then ScrollY := Mx;
  If ScrollY < 0 Then ScrollY := 0;
  Dummy := WinSendMsg(VScroll, SBM_SETSCROLLBAR, ScrollY Div 16, (((Mx + 15) Div 16) Shl 16));
  Dummy := WinEnableWindow(VScroll, Ord(Mx > 0));
End;

Procedure ScrollTo(Y : LongInt);
Begin
  ScrollY := Y;
  UpdateScroll;
  RedrawView;
End;

{ --- mise en page et affichage --- }

{ Redessin partiel : apres chaque mise en page, chaque operation de
  dessin est resumee (position + empreinte du contenu) ; a la suivante,
  seules les operations qui different sont invalidees. Une horloge en JavaScript
  ne fait ainsi redessiner que son texte, sans scintillement de la page. }
Const SIG_MAX = 3000;
Var
  SigX, SigY, SigW, SigH, SigK : Array[0..SIG_MAX - 1] Of LongInt;
  SigN, DX0, DY0, DX1, DY1 : LongInt;

Function SgMix(H, V : LongInt) : LongInt;
Begin
  SgMix := ((H And $FFFFFF) * 33) Xor V;
End;

Function OpSig(O : POp) : LongInt;
Var H, K, I : LongInt; S : String;
Begin
  H := O^.Kind * 31 + O^.Style * 7 + O^.Size;
  H := SgMix(H, O^.Color); H := SgMix(H, O^.Back); H := SgMix(H, O^.Len);
  H := SgMix(H, O^.Link); H := SgMix(H, O^.Data);
  Case O^.Kind Of
    OP_TEXT :
      For K := 0 To MinI(O^.Len, 400) - 1 Do H := SgMix(H, RdB(O^.Data + K));
    OP_IMAGE :
      Begin
        I := O^.Data;
        If (I >= 0) And (I < NImgs) Then
        Begin
          H := SgMix(H, ImState[I]); H := SgMix(H, ImBits[I]);
        End;
      End;
    OP_CTRL :
      Begin
        I := O^.Data;
        If (I >= 0) And (I < NCtls) Then
        Begin
          H := SgMix(H, CtType[I]); H := SgMix(H, Ord(CtChk[I])); H := SgMix(H, CtSel[I]);
          S := CtVal[I];
          For K := 1 To Length(S) Do H := SgMix(H, Ord(S[K]));
        End;
      End;
  End;
  OpSig := H;
End;

Procedure SigTake;
Var O : POp;
Begin
  SigN := 0;
  O := OpFirst;
  While O <> Nil Do
  Begin
    If SigN >= SIG_MAX Then
    Begin
      SigN := -1;
      Exit;
    End;
    SigX[SigN] := O^.X; SigY[SigN] := O^.Y; SigW[SigN] := O^.W; SigH[SigN] := O^.H;
    SigK[SigN] := OpSig(O);
    Inc(SigN);
    O := O^.Next;
  End;
End;

Procedure SigAdd(X, Y, W, H : LongInt);
Begin
  If W <= 0 Then W := 1;
  If H <= 0 Then H := 1;
  DX0 := MinI(DX0, X); DY0 := MinI(DY0, Y); DX1 := MaxI(DX1, X + W); DY1 := MaxI(DY1, Y + H);
End;

Procedure Relayout;
Var Pos, OldPH, OldBg, OldVW, N : LongInt; O : POp; Rc : Array[0..3] Of LongInt;
Begin
  Pos := ScrollY;
  OldPH := PageH; OldBg := PageBg; OldVW := PageW;
  Layout(MaxI(80, VW));
  ScrollY := Pos;
  UpdateScroll;
  NeedLayout := 0;
  LastLayout := KTicks;
  If (SigN < 0) Or (ScrollY <> Pos) Or (PageH <> OldPH) Or (PageBg <> OldBg) Or (PageW <> OldVW) Or
     ViewSource Then
  Begin
    RedrawView;
    SigTake;
    Exit;
  End;
  DX0 := 1000000; DY0 := 1000000; DX1 := -1; DY1 := -1;
  N := 0;
  O := OpFirst;
  While O <> Nil Do
  Begin
    If (N >= SigN) Or (SigX[N] <> O^.X) Or (SigY[N] <> O^.Y) Or (SigW[N] <> O^.W) Or (SigH[N] <> O^.H) Or
       (SigK[N] <> OpSig(O)) Then
    Begin
      SigAdd(O^.X, O^.Y, O^.W, O^.H);
      If N < SigN Then SigAdd(SigX[N], SigY[N], SigW[N], SigH[N]);
    End;
    Inc(N);
    O := O^.Next;
  End;
  While N < SigN Do
  Begin
    SigAdd(SigX[N], SigY[N], SigW[N], SigH[N]);
    Inc(N);
  End;
  SigTake;
  If DX1 < 0 Then Exit;
  { page -> fenetre (origine en bas a gauche), 2 points de marge }
  Rc[0] := MaxI(0, DX0 - 2);
  Rc[2] := MinI(VW, DX1 + 2);
  Rc[3] := MinI(VH, VH - (DY0 - ScrollY) + 2);
  Rc[1] := MaxI(0, VH - (DY1 - ScrollY) - 2);
  If (Rc[2] <= Rc[0]) Or (Rc[3] <= Rc[1]) Then Exit;
  Dummy := WinInvalidateRect(View, LongInt(@Rc), 0);
End;

{ adresse affichee ; si le champ a le focus, elle reste toute
  selectionnee (la frappe suivante la remplace) }
Procedure SetUrlText(U : String);
Begin
  Dummy := WinSetWindowText(UrlEf, Z(U));
  If WinQueryFocus(HWND_DESKTOP) = UrlEf Then Dummy := WinSendMsg(UrlEf, EM_SETSEL, 255 Shl 16, 0);
End;

Procedure SetTitle;
Var S : String;
Begin
  If DocTitle <> '' Then S := Copy(DocTitle, 1, 80) + ' - Navigateur Web'
  Else S := 'Navigateur Web d''OS/2-0';
  Dummy := WinSetWindowText(Frame, Z(S));
End;

Procedure UpdateButtons;
Begin
  RedrawToolbar;
End;

{ --- chargement des pages --- }

Procedure StartTimer;
Begin
  If TimerOn = 0 Then
  Begin
    Dummy := WinStartTimer(Hab, Client, 1, 100);
    TimerOn := 1;
  End;
End;

Procedure ScrollToAnchor(A : String); Forward;
Procedure HistAdd(U : String); Forward;

Procedure Navigate(Url, Post : String; AddHist : Boolean);
Begin
  Url := NormalizeUrl(Url);
  If Url = '' Then Exit;
  If AddHist Then HistMove := 0 Else HistMove := 1;
  { ancre de la page courante : defilement seulement }
  If (Post = '') And (Pos('#', Url) > 0) And (Copy(Url, 1, Pos('#', Url) - 1) = Copy(CurUrl, 1, Pos('#', CurUrl + '#') - 1)) And
     (Root <> Nil) Then
  Begin
    ScrollToAnchor(Copy(Url, Pos('#', Url) + 1, 255));
    CurUrl := Url;
    If AddHist Then HistAdd(Url);
    SetUrlText(Url);
    UpdateButtons;
    Exit;
  End;
  PendUrl := Url; PendPost := Post; Pending := 1;
  If FBusy <> 0 Then FAbort := 1;
  StartTimer;
End;

{ demarrage effectif d'un chargement en attente (fil libre) }
Procedure StartPending;
Begin
  If (Pending = 0) Or (FBusy <> 0) Then Exit;
  Pending := 0;
  LoadingImg := 0;
  LoadUrl := PendUrl;
  ViewSource := False;
  NetN := 0;
  LoadingRes := 0;
  { view-source:adresse : la page est chargee puis montree comme code source }
  SrcMode := StartsWith(LowStr(LoadUrl), 'view-source:');
  If SrcMode Then FetchU := Copy(LoadUrl, 13, 255) Else FetchU := LoadUrl;
  If SplitUrl(FetchU) Then SetStatus('Connexion a ' + UHost + '...')
  Else SetStatus('Ouverture de ' + FetchU + '...');
  SetUrlText(LoadUrl);
  LoadingPage := 1;
  LoadStart := KTicks;
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, SPTR_WAIT, 0));
  FetchT0 := KTicks;
  If Not StartFetch(FetchU, PendPost, 0) Then
  Begin
    LoadingPage := 0;
    Pending := 1;
  End;
  UpdateButtons;
End;

Procedure HistAdd(U : String);
Var K : LongInt;
Begin
  If (HistLen > 0) And (HistUrl[HistPos] = U) Then Exit;
  If HistLen > 0 Then HistLen := HistPos + 1;
  If HistLen >= MAX_HIST Then
  Begin
    For K := 0 To MAX_HIST - 2 Do HistUrl[K] := HistUrl[K + 1];
    HistLen := MAX_HIST - 1;
  End;
  HistUrl[HistLen] := U;
  HistPos := HistLen;
  Inc(HistLen);
End;

Procedure ScrollToAnchor(A : String);
Var K : LongInt;
Begin
  For K := 0 To NAnch - 1 Do
    If AnchName[K] = A Then
    Begin
      ScrollTo(MaxI(0, AnchY[K] - 4));
      Exit;
    End;
End;

Procedure NextImage; Forward;
Procedure SubmitForm(K : LongInt); Forward;
Procedure PageFinish; Forward;
Procedure CheckItem(Id : LongInt; On : Boolean); Forward;
Procedure JsAfterRun; Forward;
Procedure DevRedraw; Forward;
Var DevConSeen : LongInt;
Procedure GoBack; Forward;
Procedure GoForward; Forward;

{ ---------------- JavaScript et ressources de la page ---------------- }

Function ScriptTypeOk(N : PNode) : Boolean;
Var T : String;
Begin
  T := LowStr(GetAttr(N, 'type'));
  ScriptTypeOk := (T = '') Or (Pos('javascript', T) > 0) Or (Pos('ecmascript', T) > 0) Or (T = 'module');
End;

{ CSS <link rel=stylesheet> et <script src> du document, dans l'ordre }
Procedure CollectRes(N : PNode);
Var C : PNode;
Begin
  If N = Nil Then Exit;
  C := N^.First;
  While C <> Nil Do
  Begin
    If C^.Kind = NODE_ELEM Then
    Begin
      If (ResN < 64) And (C^.Tag = TAG_LINK) And (Pos('stylesheet', LowStr(GetAttr(C, 'rel'))) > 0) And
         (GetAttr(C, 'href') <> '') Then
      Begin
        ResNode[ResN] := C; ResKind[ResN] := 1; ResUrl[ResN] := ResolveUrl(BaseUrl, GetAttr(C, 'href'));
        Inc(ResN);
      End
      Else If (ResN < 64) And (C^.Tag = TAG_SCRIPT) And (GetAttr(C, 'src') <> '') And ScriptTypeOk(C) Then
      Begin
        ResNode[ResN] := C; ResKind[ResN] := 2; ResUrl[ResN] := ResolveUrl(BaseUrl, GetAttr(C, 'src'));
        Inc(ResN);
      End;
      CollectRes(C);
    End;
    C := C^.Next;
  End;
End;

Procedure NextRes;
Var U : String;
Begin
  While ResNext < ResN Do
  Begin
    U := ResUrl[ResNext];
    If StartsWith(U, 'http:') Or StartsWith(U, 'https:') Or StartsWith(U, 'file:') Then
    Begin
      If ResKind[ResNext] = 1 Then SetStatus('Feuille de style : ' + Copy(U, 1, 80))
      Else SetStatus('Script : ' + Copy(U, 1, 80));
      FetchT0 := KTicks;
      If StartFetch(U, '', 1) Then Exit;
    End;
    Inc(ResNext);
  End;
  PageFinish;
End;

{ ressource recue (ImgBuf) : convertie en page 437 et gardee dans
  l'attribut interne #css ou #js de son element }
Procedure ResLoaded;
Var SB, SL : LongInt;
Begin
  If (ResNext < ResN) And (FStatus < 400) And (ImgLen > 0) Then
  Begin
    SB := SrcBuf; SL := SrcLen;
    SrcBuf := ImgBuf; SrcLen := ImgLen;
    ConvertSource(FCType);
    ImgLen := SrcLen;
    SrcBuf := SB; SrcLen := SL;
    If ResKind[ResNext] = 1 Then JsSetAttr(ResNode[ResNext], '#css', ImgBuf, ImgLen)
    Else JsSetAttr(ResNode[ResNext], '#js', ImgBuf, ImgLen);
  End;
  Inc(ResNext);
  NextRes;
End;

{ noeud suivant dans l'ordre du document (sans entrer dans script, style) }
Function NextInDoc(N : PNode) : PNode;
Begin
  If (N^.First <> Nil) And (N^.Kind = NODE_ELEM) And (N^.Tag <> TAG_SCRIPT) And (N^.Tag <> TAG_STYLE) Then
  Begin
    NextInDoc := N^.First;
    Exit;
  End;
  While N <> Nil Do
  Begin
    If N^.Next <> Nil Then
    Begin
      NextInDoc := N^.Next;
      Exit;
    End;
    N := N^.Parent;
  End;
  NextInDoc := Nil;
End;

Procedure SetJsPage;
Begin
  JsPageUrl := CurUrl; JsPageTitle := DocTitle;
  JsViewW := VW; JsViewH := VH;
  JsScreenW := WinQuerySysValue(HWND_DESKTOP, 20); JsScreenH := WinQuerySysValue(HWND_DESKTOP, 21);
End;

{ scripts de la page, dans l'ordre ; le texte de document.write() est
  insere apres son script (et ses propres scripts sont executes) }
Procedure RunPageScripts;
Var N : PNode; A : PAttr; U : TJV; Cnt : LongInt;
Begin
  SetJsPage;
  N := Root; Cnt := 0;
  While (N <> Nil) And (Cnt < 500) Do
  Begin
    If (N^.Kind = NODE_ELEM) And (N^.Tag = TAG_SCRIPT) And ScriptTypeOk(N) Then
    Begin
      Inc(Cnt);
      JvUndef(U);
      A := FindAttr(N, '#js');
      If A <> Nil Then JsRunScript(A^.Val, A^.VLen, 1, U)
      Else If (GetAttr(N, 'src') = '') And (N^.First <> Nil) And (N^.First^.Kind = NODE_TEXT) Then
        JsRunScript(N^.First^.Txt, N^.First^.TLen, 1, U);
      If JsWriteL > 0 Then
      Begin
        JsParseInto(N^.Parent, N^.Next, JsWriteP, JsWriteL);
        JsWriteL := 0;
      End;
    End;
    N := NextInDoc(N);
  End;
  If JsTitleSet Then
  Begin
    DocTitle := JsPageTitle;
    JsTitleSet := False;
  End;
  JsPendingOnload := True;
  JsDirty := False;
End;

{ controles et images apres une modification du DOM : les valeurs deja
  saisies sont gardees }
Procedure RescanDoc;
Var Old, K, J, N, Ni : LongInt;
Begin
  JsRescan := False;
  N := NCtls;
  Old := ArAlloc(N * 16 + 16);
  If Old = 0 Then Exit;
  For K := 0 To N - 1 Do
  Begin
    WrL(Old + K * 16, LongInt(CtNode[K]));
    WrL(Old + K * 16 + 4, Ord(CtChk[K]));
    WrL(Old + K * 16 + 8, CtSel[K]);
    WrL(Old + K * 16 + 12, ArStr(CtVal[K]));
  End;
  Ni := NImgs;
  NForms := 0; NCtls := 0;
  ScanDoc(Root, -1);
  InitSelects;
  For J := 0 To NCtls - 1 Do
    For K := 0 To N - 1 Do
      If RdL(Old + K * 16) = LongInt(CtNode[J]) Then
      Begin
        CtChk[J] := RdL(Old + K * 16 + 4) <> 0;
        CtSel[J] := RdL(Old + K * 16 + 8);
        If RdL(Old + K * 16 + 12) <> 0 Then CtVal[J] := ArGet(RdL(Old + K * 16 + 12) + 1, RdB(RdL(Old + K * 16 + 12)));
      End;
  { nouvelles images a charger }
  If (NImgs > Ni) And LoadImages And (LoadingImg = 0) And (FBusy = 0) Then
  Begin
    ImgNext := 0;
    NextImage;
  End;
End;

Function JsTimersActive : Boolean;
Var K : LongInt;
Begin
  JsTimersActive := False;
  For K := 0 To JS_MAXTIMERS - 1 Do
    If JsTmUsed[K] Then JsTimersActive := True;
End;

{ code d'une adresse javascript: (%XX decodes) }
Procedure RunJsUrl(U : String);
Var V, D, T : TJV;
Begin
  JvStr(V, Copy(U, 12, 255));
  JsDecodeUri(V, D);
  JvUndef(T);
  SetJsPage;
  JsRunScript(D.P, D.L, 1, T);
  JsAfterRun;
End;

Procedure ClickElem(N : PNode); Forward;

{ apres un script (evenement, minuteur, console) : messages, titre,
  navigation, nouvelle mise en page }
Procedure JsAfterRun;
Var K, P : LongInt; S, A, U : String; N : PNode; Dom : Boolean;
Begin
  If JsTitleSet Then
  Begin
    DocTitle := JsPageTitle;
    JsTitleSet := False;
    SetTitle;
  End;
  K := 0;
  While K < JsAlertN Do
  Begin
    S := JsAlerts[K];
    Inc(K);
    If (Length(S) > 0) And (S[1] = #1) Then
    Begin
      { action differee sur un element : #1action#1adresse }
      Delete(S, 1, 1);
      P := Pos(#1, S);
      A := Copy(S, 1, P - 1);
      N := Pointer(SVal(Copy(S, P + 1, 20), 0));
      If N <> Nil Then
      Begin
        If A = 'click' Then ClickElem(N)
        Else If (A = 'submit') And (N^.Tag = TAG_FORM) Then
        Begin
          For P := 0 To NCtls - 1 Do
            If (CtForm[P] >= 0) And (FmNode[CtForm[P]] = N) Then
            Begin
              SubmitForm(P);
              Break;
            End;
        End;
      End;
    End
    Else
      Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(Copy(S, 1, 250)), Z2('Message de la page Web'), 0,
                             MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
  End;
  JsAlertN := 0;
  If JsRescan Then RescanDoc;
  Dom := JsDirty;
  If JsDirty Then
  Begin
    JsDirty := False;
    LayGen := LayGen + 1;
    Relayout;
  End;
  If JsHistCmd < 0 Then GoBack Else If JsHistCmd > 0 Then GoForward;
  JsHistCmd := 0;
  If JsNavUrl <> '' Then
  Begin
    U := JsNavUrl;
    JsNavUrl := '';
    If StartsWith(LowStr(U), 'javascript:') Then RunJsUrl(U)
    Else Navigate(ResolveUrl(BaseUrl, U), '', True);
  End;
  If JsTimersActive Then StartTimer;
  { outils : redessin seulement si l'onglet affiche a change (sinon une
    horloge en JavaScript redessinerait le panneau chaque seconde) }
  If (JsConGen <> DevConSeen) And (DevTab = DT_CONSOLE) Then DevRedraw
  Else If Dom And ((DevTab = DT_INSP) Or (DevTab = DT_DEBUG)) Then DevRedraw;
  DevConSeen := JsConGen;
End;

{ evenements de chargement : DOMContentLoaded, onload du corps, window.onload }
Procedure PageOnload;
Var B : PNode; Ob : PJObj; V, U, R : TJV;
Begin
  If Not JsReady Or (Root = Nil) Then Exit;
  SetJsPage;
  Dummy := Ord(JsFire(Root, 'domcontentloaded'));
  B := Root;
  Ob := JsNewArr;
  If Ob <> Nil Then
  Begin
    JsCollect(Root, 0, 'body', Ob, True);
    If Ob^.Len > 0 Then
    Begin
      JsArrGet(Ob, 0, V);
      B := Pointer(V.P);
    End;
  End;
  Dummy := Ord(JsFire(B, 'load'));
  { window.onload = function }
  JvStr(U, 'onload');
  If JsFindProp(JsWindow, U.P, U.L) <> Nil Then
  Begin
    V := JsFindProp(JsWindow, U.P, U.L)^.V;
    If (V.K = JV_FUN) Or (V.K = JV_NAT) Then
    Begin
      JsSteps := 0; JsCtl := JC_NONE; JsKill := False; JsDepth := 0;
      JvUndef(U);
      JsCallValue(V, U, 0, R);
      If JsCtl = JC_THROW Then
      Begin
        JsLastErr := 'Exception (onload) : ' + JsToPStr(JsExc);
        JsConsole(JsLastErr, 1);
        Inc(JsErrCount);
      End;
      JsCtl := JC_NONE; JsKill := False;
    End;
  End;
  JsAfterRun;
End;

{ journal reseau : requete terminee }
Procedure NetLogAdd(U : String);
Var K : LongInt; T : String;
Begin
  If NetN >= 100 Then
  Begin
    For K := 0 To 98 Do
    Begin
      NetUrl[K] := NetUrl[K + 1]; NetMeth[K] := NetMeth[K + 1]; NetStat[K] := NetStat[K + 1];
      NetSize[K] := NetSize[K + 1]; NetMs[K] := NetMs[K + 1]; NetType[K] := NetType[K + 1];
    End;
    NetN := 99;
  End;
  K := NetN;
  NetUrl[K] := U;
  If (FTarget = 0) And (PendPost <> '') Then NetMeth[K] := 'POST' Else NetMeth[K] := 'GET';
  NetStat[K] := FStatus;
  If FTarget = 0 Then NetSize[K] := SrcLen Else NetSize[K] := ImgLen;
  NetMs[K] := KTicks - FetchT0;
  T := LowStr(FCType);
  If Pos('html', T) > 0 Then NetType[K] := 'document'
  Else If Pos('css', T) > 0 Then NetType[K] := 'feuille CSS'
  Else If Pos('javascript', T) > 0 Then NetType[K] := 'script'
  Else If StartsWith(T, 'image/') Then NetType[K] := 'image'
  Else If StartsWith(T, 'text/') Then NetType[K] := 'texte'
  Else If T = '' Then NetType[K] := '?'
  Else NetType[K] := Copy(T, 1, 12);
  Inc(NetN);
  If DevTab = DT_NET Then DevRedraw;
End;


{ page recue : conversion, analyse, mise en page, images }
Procedure PageLoaded;
Var CT, S : String; K : LongInt; B : PNode; Cs : PStyle;
Begin
  LoadingPage := 0;
  CT := FCType;
  ArenaReset;
  JsInit;
  HoverElem := Nil;
  DevSel := Nil; DevColN := 0; DevPick := False; DevEditLine := -1; DevSrcSel := 0; DevScrSel := 0;
  For K := 1 To 5 Do If K <> DT_CONSOLE Then DevTop[K] := 0;
  NRules := 0; NForms := 0; NCtls := 0; NImgs := 0; FocusCtl := -1;
  PageBg := $FFFFFF; PageFg := $000000; LinkFg := $0000EE;
  Root := Nil; DocTitle := '';
  CurUrl := FFinalUrl;
  BaseUrl := CurUrl;
  Plain := False; PlainText := False;
  { octets recus, avant conversion en page 437 (Enregistrer sous) }
  RawLen := 0;
  If RawBuf <> 0 Then
  Begin
    MemCopy(SrcBuf, RawBuf, SrcLen);
    RawLen := SrcLen;
  End;
  If SrcMode Then
  Begin
    { code source : rien n'est analyse ; l'adresse garde son prefixe }
    ConvertSource(CT);
    ViewSource := True;
    DocTitle := 'Source de ' + CurUrl;
    CurUrl := 'view-source:' + CurUrl;
  End
  Else If StartsWith(CT, 'image/') Then
  Begin
    { image seule : petite page qui l'affiche }
    FBuf := SrcBuf; FCap := SRC_MAX; FTotal := 0;
    FPutS('<html><head><title>' + CurUrl + '</title></head><body><img src="' + CurUrl + '"></body></html>');
    SrcLen := FTotal;
  End
  Else If StartsWith(CT, 'text/plain') Then
  Begin
    ConvertSource(CT);
    Plain := True; PlainText := True;
  End
  Else ConvertSource(CT);
  If SrcMode Then
  Begin
    PageFinish;
    Exit;
  End;
  If Plain Then
  Begin
    ViewSource := True;
    DocTitle := CurUrl;
    PageFinish;
    Exit;
  End;
  Begin
    Trace('analyse ' + IStr(SrcLen));
    ParseDocument;
    Trace('noeuds');
    ScanDoc(Root, -1);
    InitSelects;
    { feuilles de style et scripts externes : charges d'abord }
    ResN := 0; ResNext := 0;
    CollectRes(Root);
    If ResN > 0 Then
    Begin
      LoadingRes := 1;
      NextRes;
      Exit;
    End;
    PageFinish;
    Exit;
  End;
  PageFinish;
End;

{ page analysee, ressources chargees : scripts, styles, mise en page }
Procedure PageFinish;
Var S : String; K : LongInt; B : PNode; Cs : PStyle;
Begin
  LoadingRes := 0;
  If (Not SrcMode) And (Not Plain) And (Root <> Nil) Then
  Begin
    RunPageScripts;
    Trace('styles');
    NRules := 0;
    CollectStyles(Root);
    Trace('styles ' + IStr(NRules));
    { fond et couleur du corps par les feuilles de style }
    B := Root^.First;
    While B <> Nil Do
    Begin
      If (B^.Kind = NODE_ELEM) And ((B^.Tag = TAG_HTML) Or (B^.Tag = TAG_BODY)) Then
      Begin
        Cs := NodeStyle(B);
        If Cs <> Nil Then
        Begin
          If Cs^.Back >= 0 Then PageBg := Cs^.Back;
          If Cs^.Color >= 0 Then PageFg := Cs^.Color;
        End;
        If B^.Tag = TAG_HTML Then B := B^.First Else B := Nil;
      End
      Else B := B^.Next;
    End;
  End;
  SetTitle;
  SetUrlText(CurUrl);
  CheckItem(CM_SOURCE, ViewSource);
  If HistMove = 0 Then HistAdd(CurUrl) Else If (HistLen > 0) Then HistUrl[HistPos] := CurUrl;
  ScrollY := 0;
  Trace('mise en page');
  Relayout;
  RedrawView;
  Trace('mise en page faite ' + IStr(PageH));
  K := Pos('#', CurUrl);
  If K > 0 Then ScrollToAnchor(Copy(CurUrl, K + 1, 255));
  S := 'Document : termine';
  If ParseTrunc Or ArFull Then S := 'Document : tronque (page trop grande pour la memoire du navigateur)';
  If (FStatus >= 400) Then S := 'Le serveur a repondu : erreur ' + IStr(FStatus);
  SetStatus(S);
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, SPTR_ARROW, 0));
  { redirection <meta http-equiv="refresh"> }
  If (RefreshUrl <> '') And (RefreshTick < REFRESH_MAX) Then
  Begin
    S := ResolveUrl(BaseUrl, RefreshUrl);
    If S <> CurUrl Then
    Begin
      Inc(RefreshTick);
      Navigate(S, '', False);
      Exit;
    End;
  End;
  RefreshTick := 0;
  { evenements de chargement (scripts de la page) }
  If JsPendingOnload Then
  Begin
    JsPendingOnload := False;
    PageOnload;
  End;
  ImgNext := 0;
  If LoadImages And Not ViewSource Then NextImage;
  UpdateButtons;
End;

Procedure NextImage;
Begin
  LoadingImg := 0;
  While (ImgNext < NImgs) And (ImState[ImgNext] <> 0) Do Inc(ImgNext);
  If (ImgNext >= NImgs) Or (Pending <> 0) Then
  Begin
    If NeedLayout <> 0 Then Relayout;
    Exit;
  End;
  SetStatus('Image ' + IStr(ImgNext + 1) + ' sur ' + IStr(NImgs) + ' : ' + Copy(ImgUrlOf(ImgNext), 1, 80));
  FetchT0 := KTicks;
  If StartFetch(ImgUrlOf(ImgNext), '', 1) Then
  Begin
    LoadingImg := 1;
    StartTimer;
  End;
End;

Procedure ImageLoaded;
Begin
  LoadingImg := 0;
  If (ImgNext < NImgs) Then
  Begin
    If (ImgLen > 0) And DecodeImage(ImgNext) Then
    Begin
      ImState[ImgNext] := 1;
      NeedLayout := 1;
    End
    Else ImState[ImgNext] := 2;
    Inc(ImgNext);
  End;
  { mise en page refaite au plus toutes les 1,5 s pendant le chargement }
  If (NeedLayout <> 0) And (KTicks - LastLayout > 1500) Then Relayout;
  NextImage;
  If (LoadingImg = 0) And (Pending = 0) Then
  Begin
    If NeedLayout <> 0 Then Relayout;
    SetStatus('Document : termine');
  End;
End;

Procedure TimerTick;
Var S : String;
Begin
  If (FBusy = 0) And (FDone <> 0) Then
  Begin
    FDone := 0;
    If FTarget = 0 Then
    Begin
      NetLogAdd(LoadUrl);
      If Pending = 0 Then PageLoaded Else LoadingPage := 0;
    End
    Else If LoadingRes <> 0 Then
    Begin
      If ResNext < ResN Then NetLogAdd(ResUrl[ResNext]);
      ResLoaded;
    End
    Else
    Begin
      If ImgNext < NImgs Then NetLogAdd(ImgUrlOf(ImgNext));
      ImageLoaded;
    End;
  End;
  { minuteurs des scripts (setTimeout, setInterval) }
  If (FBusy = 0) And (LoadingRes = 0) And JsTimersActive Then
    If JsRunTimers Then JsAfterRun;
  If (Pending <> 0) And (FBusy = 0) Then StartPending;
  If (LoadingPage <> 0) And (FBusy <> 0) Then
  Begin
    S := 'Reception de ' + LoadUrl;
    If FBytes > 0 Then S := 'Reception : ' + IStr(FBytes) + ' octets de ' + Copy(LoadUrl, 1, 60);
    SetStatus(S);
  End;
  If (FBusy = 0) And (Pending = 0) And (LoadingPage = 0) And (LoadingImg = 0) And (LoadingRes = 0) And
     Not JsTimersActive Then
  Begin
    Dummy := WinStopTimer(Hab, Client, 1);
    TimerOn := 0;
    If NeedLayout <> 0 Then Relayout;
    UpdateButtons;
  End;
End;

Procedure StopLoading;
Begin
  If FBusy <> 0 Then FAbort := 1;
  Pending := 0;
  ImgNext := NImgs;
  SetStatus('Chargement arrete');
  Dummy := WinSetPointer(HWND_DESKTOP, WinQuerySysPointer(HWND_DESKTOP, SPTR_ARROW, 0));
End;

Procedure GoBack;
Begin
  If HistPos > 0 Then
  Begin
    Dec(HistPos);
    Navigate(HistUrl[HistPos], '', False);
  End;
End;

Procedure GoForward;
Begin
  If HistPos < HistLen - 1 Then
  Begin
    Inc(HistPos);
    Navigate(HistUrl[HistPos], '', False);
  End;
End;

Function HomeUrl : String;
Var S : String;
Begin
  S := PrfStr('BROWSER', 'ACCUEIL');
  If S = '' Then S := 'about:home';
  HomeUrl := S;
End;

{ --- formulaires --- }

Procedure SubmitForm(K : LongInt);
Var F, J, T : LongInt; Q, Nm, Act, Meth, U : String; N : PNode;
Begin
  F := CtForm[K];
  If (F < 0) Or (F >= NForms) Then Exit;
  N := FmNode[F];
  { evenement submit des scripts : return false / preventDefault annule l'envoi }
  If JsHasHandler(N, 'submit') Then
  Begin
    SetJsPage;
    If JsFire(N, 'submit') Then
    Begin
      JsAfterRun;
      Exit;
    End;
    JsAfterRun;
  End;
  Act := GetAttr(N, 'action');
  Meth := LowStr(GetAttr(N, 'method'));
  Q := '';
  For J := 0 To NCtls - 1 Do
    If (CtForm[J] = F) And Not HasAttr(CtNode[J], 'disabled') Then
    Begin
      Nm := GetAttr(CtNode[J], 'name');
      T := CtType[J];
      If (Nm = '') And Not ((T = CT_IMAGE) And (J = K)) Then Continue;
      Case T Of
        CT_TEXT, CT_PASSWORD, CT_HIDDEN, CT_TEXTAREA :
          Q := Q + '&' + FormEncode(Nm) + '=' + FormEncode(CtVal[J]);
        CT_CHECK, CT_RADIO :
          If CtChk[J] Then
          Begin
            If HasAttr(CtNode[J], 'value') Then Q := Q + '&' + FormEncode(Nm) + '=' + FormEncode(CtVal[J])
            Else Q := Q + '&' + FormEncode(Nm) + '=on';
          End;
        CT_SELECT : Q := Q + '&' + FormEncode(Nm) + '=' + FormEncode(OptValue(CtNode[J], CtSel[J]));
        CT_SUBMIT : If J = K Then Q := Q + '&' + FormEncode(Nm) + '=' + FormEncode(CtlLabel(J));
        CT_IMAGE :
          If J = K Then
          Begin
            If Nm <> '' Then Q := Q + '&' + FormEncode(Nm) + '.x=1&' + FormEncode(Nm) + '.y=1'
            Else Q := Q + '&x=1&y=1';
          End;
      End;
    End;
  If (Q <> '') And (Q[1] = '&') Then Delete(Q, 1, 1);
  U := ResolveUrl(BaseUrl, Act);
  If Act = '' Then U := CurUrl;
  If Meth = 'post' Then Navigate(U, Q, True)
  Else
  Begin
    J := Pos('?', U);
    If J > 0 Then U := Copy(U, 1, J - 1);
    J := Pos('#', U);
    If J > 0 Then U := Copy(U, 1, J - 1);
    Navigate(U + '?' + Q, '', True);
  End;
End;

Procedure ResetForm(K : LongInt);
Var J : LongInt;
Begin
  For J := 0 To NCtls - 1 Do
    If CtForm[J] = CtForm[K] Then
    Begin
      CtChk[J] := HasAttr(CtNode[J], 'checked');
      If CtType[J] = CT_TEXTAREA Then CtVal[J] := NodeText(CtNode[J])
      Else If CtType[J] In [CT_TEXT, CT_PASSWORD] Then CtVal[J] := GetAttr(CtNode[J], 'value');
    End;
  InitSelects;
  RedrawView;
End;

Procedure CtlClick(K : LongInt; Shift : Boolean);
Var J, N : LongInt; Nm : String;
Begin
  Case CtType[K] Of
    CT_TEXT, CT_PASSWORD, CT_TEXTAREA : FocusCtl := K;
    CT_CHECK :
      Begin
        CtChk[K] := Not CtChk[K];
        FocusCtl := K;
      End;
    CT_RADIO :
      Begin
        Nm := GetAttr(CtNode[K], 'name');
        For J := 0 To NCtls - 1 Do
          If (CtType[J] = CT_RADIO) And (CtForm[J] = CtForm[K]) And (GetAttr(CtNode[J], 'name') = Nm) Then
            CtChk[J] := False;
        CtChk[K] := True;
        FocusCtl := K;
      End;
    CT_SELECT :
      Begin
        N := OptCount(CtNode[K]);
        If N > 0 Then
        Begin
          If Shift Then CtSel[K] := (CtSel[K] + N - 1) Mod N Else CtSel[K] := (CtSel[K] + 1) Mod N;
        End;
        FocusCtl := K;
        SetStatus('Liste : ' + OptText(CtNode[K], CtSel[K]) + '   (clic : suivant, Maj+clic : precedent)');
        If JsFire(CtNode[K], 'change') Then ;
        JsAfterRun;
      End;
    CT_SUBMIT, CT_IMAGE : SubmitForm(K);
    CT_RESET : ResetForm(K);
    CT_BUTTON : SetStatus('Ce bouton demande JavaScript, qui n''est pas pris en charge.');
  End;
  RedrawView;
End;

{ frappe dans un champ de saisie ; vrai si traitee }
Function CtlKey(Fl, Ch, Vk : LongInt) : Boolean;
Var K, N : LongInt; R : Boolean;
Begin
  R := False;
  CtlKey := False;
  K := FocusCtl;
  If (K < 0) Or (K >= NCtls) Then Exit;
  If CtType[K] In [CT_TEXT, CT_PASSWORD, CT_TEXTAREA] Then
  Begin
    If ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
    Begin
      If CtType[K] = CT_TEXTAREA Then CtVal[K] := CtVal[K] + ' ' Else SubmitForm(K);
      R := True;
    End
    Else If ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_BACKSPACE) Then
    Begin
      If Length(CtVal[K]) > 0 Then Delete(CtVal[K], Length(CtVal[K]), 1);
      R := True;
    End
    Else If ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then
    Begin
      FocusCtl := -1;
      R := True;
    End
    Else If ((Fl And KC_CHAR) <> 0) And (Ch >= 32) And (Ch < 256) And ((Fl And KC_CTRL) = 0) Then
    Begin
      If Length(CtVal[K]) < 200 Then CtVal[K] := CtVal[K] + Chr(Ch);
      R := True;
    End;
  End
  Else If (CtType[K] = CT_SELECT) And ((Fl And KC_VIRTUALKEY) <> 0) Then
  Begin
    N := OptCount(CtNode[K]);
    If (Vk = VK_DOWN) And (CtSel[K] < N - 1) Then
    Begin
      Inc(CtSel[K]);
      R := True;
    End
    Else If (Vk = VK_UP) And (CtSel[K] > 0) Then
    Begin
      Dec(CtSel[K]);
      R := True;
    End;
  End
  Else If (CtType[K] In [CT_CHECK, CT_RADIO]) And ((Fl And KC_CHAR) <> 0) And (Ch = 32) Then
  Begin
    CtlClick(K, False);
    R := True;
  End;
  { (le nom de la fonction lu ici serait un appel recursif) }
  If R Then RedrawView;
  CtlKey := R;
End;

{ --- souris dans la page --- }

Function HitOp(X, Y : LongInt) : POp;
Var O, R : POp; Py : LongInt;
Begin
  R := Nil;
  Py := VH - 1 - Y + ScrollY;
  O := OpFirst;
  While O <> Nil Do
  Begin
    If (X >= O^.X) And (X < O^.X + O^.W) And (Py >= O^.Y) And (Py < O^.Y + O^.H) Then
      If (O^.Kind = OP_TEXT) Or (O^.Kind = OP_IMAGE) Or (O^.Kind = OP_CTRL) Then R := O;
    O := O^.Next;
  End;
  HitOp := R;
End;

{ action par defaut d'un clic : controle, ou lien (U) }
Procedure DefaultClick(Ctl : LongInt; U : String; Shift : Boolean);
Begin
  If Ctl >= 0 Then
  Begin
    CtlClick(Ctl, Shift);
    Exit;
  End;
  If FocusCtl >= 0 Then
  Begin
    FocusCtl := -1;
    RedrawView;
  End;
  If U <> '' Then
  Begin
    If StartsWith(LowStr(U), 'javascript:') Then RunJsUrl(U)
    Else If StartsWith(U, 'mailto:') Then ShowMsg('Adresse de courrier : ' + Copy(U, 8, 200), 'Courrier', MB_OK Or MB_INFORMATION)
    Else Navigate(U, '', True);
  End;
End;

Procedure DevPicked(N : PNode); Forward;

Procedure ViewClick(X, Y : LongInt; Shift : Boolean);
Var O : POp; U : String; Ctl : LongInt; Tgt : PNode;
Begin
  O := HitOp(X, Y);
  Ctl := -1; U := ''; Tgt := Nil;
  If O <> Nil Then
  Begin
    Tgt := O^.Elem;
    If O^.Kind = OP_CTRL Then Ctl := O^.Data;
    If O^.Link <> 0 Then U := LinkUrl(O^.Link);
  End;
  { outils de developpement : selection d'un element de la page }
  If DevPick Then
  Begin
    DevPicked(Tgt);
    Exit;
  End;
  { evenement click des scripts ; preventDefault / return false annule }
  If Tgt <> Nil Then
  Begin
    SetJsPage;
    If JsFire(Tgt, 'click') Then
    Begin
      JsAfterRun;
      Exit;
    End;
    JsAfterRun;
  End;
  DefaultClick(Ctl, U, Shift);
End;

{ element.click() d'un script }
Procedure ClickElem(N : PNode);
Var K : LongInt;
Begin
  If N = Nil Then Exit;
  If JsFire(N, 'click') Then Exit;
  K := N^.Aux - 1;
  If (K >= 0) And (K < NCtls) And (CtNode[K] = N) Then DefaultClick(K, '', False)
  Else If (N^.Tag = TAG_A) And HasAttr(N, 'href') Then DefaultClick(-1, ResolveUrl(BaseUrl, GetAttr(N, 'href')), False);
End;

Procedure ViewHover(X, Y : LongInt);
Var O : POp; S : String; E : PNode; Fired : Boolean;
Begin
  O := HitOp(X, Y);
  S := '';
  If (O <> Nil) And (O^.Link <> 0) Then S := LinkUrl(O^.Link);
  { mouseover / mouseout des scripts }
  If O <> Nil Then E := O^.Elem Else E := Nil;
  If E <> HoverElem Then
  Begin
    Fired := False;
    If (HoverElem <> Nil) And JsHasHandler(HoverElem, 'mouseout') Then
    Begin
      Dummy := Ord(JsFire(HoverElem, 'mouseout'));
      Fired := True;
    End;
    HoverElem := E;
    If (E <> Nil) And JsHasHandler(E, 'mouseover') Then
    Begin
      Dummy := Ord(JsFire(E, 'mouseover'));
      Fired := True;
    End;
    If Fired Then JsAfterRun;
  End;
  If S <> LinkHover Then
  Begin
    LinkHover := S;
    If S <> '' Then SetStatus(S)
    Else If (LoadingPage = 0) And (LoadingImg = 0) Then SetStatus('Document : termine');
  End;
End;

Procedure ShowContext(X, Y : LongInt); Forward;

Function ViewProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk, Ch : LongInt;
Begin
  ViewProc := 0;
  Case Msg Of
    WM_PAINT : PaintView(H);
    WM_BUTTON2DOWN :
      Begin
        B2Down := True;
        ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_BUTTON2CLICK :
      Begin
        { seulement apres un bouton 2 enfonce dans la page : un clic
          synthetise en retard (menu du bureau qui a lance le navigateur)
          n'ouvre pas le menu contextuel }
        If B2Down Then
        Begin
          B2Down := False;
          Dummy := WinSetFocus(HWND_DESKTOP, H);
          ShowContext(S16(Mp1), S16(Mp1 Shr 16));
        End;
        ViewProc := 1;
      End;
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinDefWindowProc(H, Msg, Mp1, Mp2);
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        ViewClick(S16(Mp1), S16(Mp1 Shr 16), (Hi16(Mp2) And KC_SHIFT) <> 0);
        ViewProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        ViewHover(S16(Mp1), S16(Mp1 Shr 16));
        ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := Hi16(Mp2);
        If (Fl And KC_KEYUP) <> 0 Then Exit;
        If CtlKey(Fl, Ch And 255, Vk) Then Exit;
        If (Fl And KC_VIRTUALKEY) <> 0 Then
          Case Vk Of
            VK_UP : ScrollTo(ScrollY - 16);
            VK_DOWN : ScrollTo(ScrollY + 16);
            VK_PAGEUP : ScrollTo(ScrollY - VH + 24);
            VK_PAGEDOWN, VK_SPACE : ScrollTo(ScrollY + VH - 24);
            VK_HOME : ScrollTo(0);
            VK_END : ScrollTo(PageH);
            VK_BACKSPACE : GoBack;
          Else
            ViewProc := WinSendMsg(Client, Msg, Mp1, Mp2);
          End
        Else ViewProc := WinSendMsg(Client, Msg, Mp1, Mp2);
      End;
  Else
    ViewProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ --- barre d'outils --- }

Function BtnX(K : LongInt) : LongInt;
Begin
  If K >= BT_MARK Then BtnX := 6 + K * 38 + 10 Else BtnX := 6 + K * 38;
End;

Function BtnEnabled(K : LongInt) : Boolean;
Begin
  Case K Of
    BT_BACK : BtnEnabled := HistPos > 0;
    BT_FWD : BtnEnabled := HistPos < HistLen - 1;
    BT_STOP : BtnEnabled := (FBusy <> 0) Or (Pending <> 0) Or (LoadingPage <> 0) Or (LoadingImg <> 0);
    BT_SRC : BtnEnabled := CurUrl <> '';
  Else
    BtnEnabled := True;
  End;
End;

Function BtnHint(K : LongInt) : String;
Begin
  Case K Of
    BT_BACK : BtnHint := 'Precedent : page precedente (Alt+Fleche gauche)';
    BT_FWD : BtnHint := 'Suivant : page suivante (Alt+Fleche droite)';
    BT_STOP : BtnHint := 'Arreter le chargement (Echap)';
    BT_RELOAD : BtnHint := 'Actualiser la page (F5)';
    BT_HOME : BtnHint := 'Page d''accueil';
    BT_MARK : BtnHint := 'Favori : ajouter cette page aux signets';
  Else
    BtnHint := 'Source de la page';
  End;
End;

Procedure PaintClient(H : LongInt);
Var Rc : Array[0..3] Of LongInt; K, X, Y, A : LongInt; Dn : Boolean;
Begin
  Ps := WinBeginPaint(H, 0, 0);
  If Ps = 0 Then Exit;
  RgbMode(Ps);
  Dummy := GpiSetBackMix(Ps, BM_LEAVEALONE);
  CurBox := 0;
  { fonds : barre d'outils, ligne de l'adresse, barre d'etat (la page et
    la barre de defilement se peignent elles-memes) }
  GBoxF(0, CH - TBH - ADH, CW, CH, $CCCCCC);
  GBoxF(0, 0, CW, SBH - 1, $CCCCCC);
  GBoxF(0, SBH, 1, CH - TBH - ADH, $CCCCCC);
  GBoxF(2 + VW + SCW, SBH, CW, CH - TBH - ADH, $CCCCCC);
  { barre d'outils }
  Bevel(0, CH - TBH, CW - 1, CH - 1, True);
  Y := CH - TBH + 4;
  For K := 0 To NBTN - 1 Do
  Begin
    X := BtnX(K);
    Dn := (BtnDown = K) And (BtnHover = K);
    GBoxF(X, Y, X + 35, Y + 33, $CCCCCC);
    GBoxO(X - 1, Y - 1, X + 36, Y + 34, $000000);
    Bevel(X, Y, X + 35, Y + 33, Not Dn);
    If Dn Then A := 1 Else A := 0;
    If BtnEnabled(K) Then Dummy := WinDrawPointer(Ps, X + 2 + A, Y + 1 - A, BtnIcon[K], DP_NORMAL)
    Else Dummy := WinDrawPointer(Ps, X + 2, Y + 1, BtnIcon[K], DP_HALFTONED);
  End;
  { separateur }
  GLn(BtnX(BT_MARK) - 7, Y, BtnX(BT_MARK) - 7, Y + 33, $808080);
  GLn(BtnX(BT_MARK) - 6, Y, BtnX(BT_MARK) - 6, Y + 33, $FFFFFF);
  { globe : chargement en cours }
  X := CW - 44;
  If X > BtnX(NBTN - 1) + 44 Then
  Begin
    GBoxF(X, Y, X + 35, Y + 33, $000000);
    Bevel(X - 1, Y - 1, X + 36, Y + 34, False);
    If (FBusy <> 0) Or (LoadingPage <> 0) Or (LoadingImg <> 0) Then
      Dummy := WinDrawPointer(Ps, X + 2, Y + 1, BtnIcon[NBTN], DP_NORMAL)
    Else Dummy := WinDrawPointer(Ps, X + 2, Y + 1, BtnIcon[NBTN], DP_HALFTONED);
  End;
  { ligne de l'adresse }
  TextS(6, CH - TBH - 7, 'Adresse :', $000000);
  { barre d'etat }
  Bevel(2, 2, CW - 3, SBH - 3, False);
  TextS(8, SBH - 3, Copy(StatusText, 1, MaxI(0, (CW - 20) Div 8)), $000000);
  Dummy := WinEndPaint(Ps);
  Dummy := WinInvalidateRect(UrlEf, 0, 0);
  Dummy := WinInvalidateRect(GoBtn, 0, 0);
End;

Function BtnAt(X, Y : LongInt) : LongInt;
Var K, By : LongInt;
Begin
  BtnAt := -1;
  By := CH - TBH + 4;
  If (Y < By) Or (Y > By + 33) Then Exit;
  For K := 0 To NBTN - 1 Do
    If (X >= BtnX(K)) And (X <= BtnX(K) + 35) Then BtnAt := K;
End;

{ ==================================================================== }
{ Boites de dialogue : saisie d'un texte, liste (signets, historique)   }
{ ==================================================================== }

Const
  DM_URL = 1; DM_PROXY = 2; DM_FILE = 3; DM_SAVE = 4; DM_MARKS = 11; DM_HIST = 12;

Procedure CloseDlg;
Begin
  If DlgFr <> 0 Then Dummy := WinDestroyWindow(DlgFr);
  DlgFr := 0; DlgCl := 0; DlgEf := 0; DlgLb := 0;
End;

{ nom de fichier propose : dernier segment de l'adresse (sans ? ni #),
  index.html s'il est vide, .html s'il n'a pas d'extension ; caracteres
  interdits remplaces par _ }
Function DefaultSaveName : String;
Var U, N : String; K : LongInt;
Begin
  U := CurUrl;
  If StartsWith(U, 'view-source:') Then U := Copy(U, 13, 255);
  If Pos('?', U) > 0 Then U := Copy(U, 1, Pos('?', U) - 1);
  If Pos('#', U) > 0 Then U := Copy(U, 1, Pos('#', U) - 1);
  If Pos('://', U) > 0 Then U := Copy(U, Pos('://', U) + 3, 255);
  N := '';
  For K := Length(U) DownTo 1 Do
    If (U[K] = '/') Or (U[K] = '\') Then
    Begin
      N := Copy(U, K + 1, 255);
      Break;
    End;
  If N = '' Then N := 'index.html';
  If Pos('.', N) = 0 Then N := N + '.html';
  For K := 1 To Length(N) Do
    If N[K] In [':', '*', '?', '"', '<', '>', '|', '%'] Then N[K] := '_';
  DefaultSaveName := 'C:\' + Copy(N, 1, 60);
End;

Function FileThere(F : String) : Boolean;
Var B : Array[0..299] Of Byte; H, Act : LongInt;
Begin
  PutZ(LongInt(@B), F);
  H := 0; Act := 0;
  { ouvrir seulement s'il existe (lecture) }
  If DosOpen(LongInt(@B), LongInt(@H), LongInt(@Act), 0, 0, $01, $40, 0) = 0 Then
  Begin
    Dummy := DosClose(H);
    FileThere := True;
  End
  Else FileThere := False;
End;

Procedure OpenInput(Mode : LongInt; Title, Prompt, Def : String);
Var Fl, Sw, Sh : LongInt;
Begin
  CloseDlg;
  DlgMode := Mode; DlgPrompt := Prompt;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DlgCl := 0;
  DlgFr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('WEBINPUT'), Z2(Title), 0, 0, 0, LongInt(@DlgCl));
  If DlgFr = 0 Then Exit;
  Dummy := WinSetWindowText(DlgEf, Z(Def));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(DlgFr, HWND_TOP, MaxI(0, (Sw - 460) Div 2), MaxI(0, (Sh - 130) Div 2), 460, 130,
                           SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, DlgFr);
  Dummy := WinSetFocus(HWND_DESKTOP, DlgEf);
End;

{ signets : OS2.INI, application BROWSER_SIGNETS, cles 1..64 "adresse|titre" }
Function MarkGet(K : LongInt) : String;
Begin
  MarkGet := PrfStr('BROWSER_SIGNETS', IStr(K));
End;

Function MarkCount : LongInt;
Var K : LongInt;
Begin
  K := 0;
  While (K < MAX_MARKS) And (MarkGet(K + 1) <> '') Do Inc(K);
  MarkCount := K;
End;

Procedure AddMark;
Var N : LongInt; T : String;
Begin
  If CurUrl = '' Then Exit;
  N := MarkCount;
  If N >= MAX_MARKS Then
  Begin
    ShowMsg('La liste des signets est pleine (64).', 'Signets', MB_OK Or MB_WARNING);
    Exit;
  End;
  T := DocTitle;
  If T = '' Then T := CurUrl;
  PrfPut('BROWSER_SIGNETS', IStr(N + 1), Copy(CurUrl + '|' + Copy(T, 1, 60), 1, 250));
  SetStatus('Signet ajoute : ' + T);
End;

Procedure DelMark(I : LongInt);
Var N, K : LongInt;
Begin
  N := MarkCount;
  For K := I To N - 1 Do PrfPut('BROWSER_SIGNETS', IStr(K), MarkGet(K + 1));
  PrfPut('BROWSER_SIGNETS', IStr(N), '');
End;

Procedure FillList;
Var K, N : LongInt; S : String;
Begin
  Dummy := WinSendMsg(DlgLb, LM_DELETEALL, 0, 0);
  If DlgMode = DM_MARKS Then
  Begin
    N := MarkCount;
    For K := 1 To N Do
    Begin
      S := MarkGet(K);
      If Pos('|', S) > 0 Then S := Copy(S, Pos('|', S) + 1, 80) + '  (' + Copy(S, 1, Pos('|', S) - 1) + ')';
      Dummy := WinSendMsg(DlgLb, LM_INSERTITEM, -1, Z(Copy(S, 1, 200)));
    End;
  End
  Else
    For K := HistLen - 1 DownTo 0 Do Dummy := WinSendMsg(DlgLb, LM_INSERTITEM, -1, Z(HistUrl[K]));
  Dummy := WinSendMsg(DlgLb, LM_SELECTITEM, 0, 1);
End;

Procedure OpenList(Mode : LongInt; Title : String);
Var Fl, Sw, Sh : LongInt;
Begin
  CloseDlg;
  DlgMode := Mode;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DlgCl := 0;
  DlgFr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('WEBLIST'), Z2(Title), 0, 0, 0, LongInt(@DlgCl));
  If DlgFr = 0 Then Exit;
  FillList;
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(DlgFr, HWND_TOP, MaxI(0, (Sw - 480) Div 2), MaxI(0, (Sh - 300) Div 2), 480, 300,
                           SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, DlgFr);
  Dummy := WinSetFocus(HWND_DESKTOP, DlgLb);
End;

Procedure SavePage(F : String);
Var B : Array[0..299] Of Byte; H, Act, W : LongInt;
Begin
  PutZ(LongInt(@B), F);
  H := 0; Act := 0;
  If DosOpen(LongInt(@B), LongInt(@H), LongInt(@Act), 0, 0, $12, $41, 0) <> 0 Then
  Begin
    ShowMsg('Impossible de creer le fichier ' + F + '.', 'Enregistrer', MB_OK Or MB_ERROR);
    Exit;
  End;
  W := 0;
  If RawLen > 0 Then Dummy := DosWrite(H, RawBuf, RawLen, LongInt(@W))
  Else Dummy := DosWrite(H, SrcBuf, SrcLen, LongInt(@W));
  Dummy := DosClose(H);
  SetStatus('Page enregistree : ' + F + ' (' + IStr(W) + ' octets)');
End;

Procedure DlgDone;
Var S : String; I : LongInt;
Begin
  If DlgEf <> 0 Then
  Begin
    Dummy := WinQueryWindowText(DlgEf, 250, LongInt(@TxtBuf));
    S := TrimS(GetZ(LongInt(@TxtBuf)));
  End
  Else S := '';
  I := -1;
  If DlgLb <> 0 Then I := WinSendMsg(DlgLb, LM_QUERYSELECTION, -1, 0);
  Case DlgMode Of
    DM_URL : If S <> '' Then Navigate(S, '', True);
    DM_FILE :
      If S <> '' Then
      Begin
        While Pos('\', S) > 0 Do S[Pos('\', S)] := '/';
        Navigate('file:///' + S, '', True);
      End;
    DM_PROXY :
      Begin
        PrfPut('BROWSER', 'PROXY', S);
        ProxyLoad;
        If ProxyHost <> '' Then SetStatus('Proxy : ' + ProxyHost + ':' + IStr(ProxyPort))
        Else SetStatus('Connexion directe (sans proxy)');
      End;
    DM_SAVE :
      If S <> '' Then
      Begin
        If FileThere(S) Then
        Begin
          If WinMessageBox(HWND_DESKTOP, Frame, Z('Le fichier existe d' + Chr(130) + 'j' + Chr(133) + ' : ' + S + '. Le remplacer ?'),
                           Z2('Confirmer le remplacement'), 0, MB_YESNO Or MB_QUERY Or MB_MOVEABLE) = MBID_YES Then
            SavePage(S);
        End
        Else SavePage(S);
      End;
    DM_MARKS :
      If (I >= 0) And (I < MarkCount) Then
      Begin
        S := MarkGet(I + 1);
        If Pos('|', S) > 0 Then S := Copy(S, 1, Pos('|', S) - 1);
        Navigate(S, '', True);
      End;
    DM_HIST :
      If (I >= 0) And (I < HistLen) Then Navigate(HistUrl[HistLen - 1 - I], '', True);
  End;
  CloseDlg;
End;

Function InputProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk, P : LongInt; Rc, Tr : Array[0..3] Of LongInt;
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
        P := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(P, LongInt(@Rc), CLR_PALEGRAY);
        Tr[0] := 8; Tr[1] := Rc[3] - 26; Tr[2] := Rc[2] - 8; Tr[3] := Rc[3] - 8;
        PutZ(LongInt(@TxtBuf), DlgPrompt);
        Dummy := WinDrawText(P, -1, LongInt(@TxtBuf), LongInt(@Tr), CLR_BLACK, CLR_PALEGRAY, 0);
        Dummy := WinEndPaint(P);
      End;
    WM_COMMAND :
      If Lo16(Mp1) = ID_DOK Then DlgDone Else If Lo16(Mp1) = ID_DCANCEL Then CloseDlg;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
          DlgDone
        Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then CloseDlg
        Else InputProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE : CloseDlg;
  Else
    InputProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Function ListProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk, P, I : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  ListProc := 0;
  Case Msg Of
    WM_CREATE :
      Begin
        DlgCl := H;
        DlgLb := WinCreateWindow(H, WC_LISTBOX, 0, WS_VISIBLE Or WS_TABSTOP, 8, 40, 456, 220, H, HWND_TOP, ID_DLIST, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Ouvrir'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                                 8, 8, 90, 24, H, HWND_TOP, ID_DOK, 0, 0);
        If DlgMode = DM_MARKS Then
          Dummy := WinCreateWindow(H, WC_BUTTON, Z('Supprimer'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                   106, 8, 90, 24, H, HWND_TOP, ID_DDEL, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Fermer'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                 374, 8, 90, 24, H, HWND_TOP, ID_DCANCEL, 0, 0);
      End;
    WM_PAINT :
      Begin
        P := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(P, LongInt(@Rc), CLR_PALEGRAY);
        Dummy := WinEndPaint(P);
      End;
    WM_COMMAND :
      If Lo16(Mp1) = ID_DOK Then DlgDone
      Else If Lo16(Mp1) = ID_DDEL Then
      Begin
        I := WinSendMsg(DlgLb, LM_QUERYSELECTION, -1, 0);
        If I >= 0 Then
        Begin
          DelMark(I + 1);
          FillList;
        End;
      End
      Else If Lo16(Mp1) = ID_DCANCEL Then CloseDlg;
    WM_CONTROL :
      If (Lo16(Mp1) = ID_DLIST) And (Hi16(Mp1) = LN_ENTER) Then DlgDone;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then CloseDlg
        Else ListProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE : CloseDlg;
  Else
    ListProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Code QR de la page (menu contextuel)                                  }
{ ==================================================================== }

{ adresse pour le code QR : caracteres non ASCII en UTF-8 (%XX) }
Function QrUrl(U : String) : String;
Var K, C : LongInt; R : String;
Begin
  R := '';
  For K := 1 To Length(U) Do
  Begin
    C := Ord(U[K]);
    If C < 128 Then R := R + U[K]
    Else
    Begin
      C := CpToUni(C);
      If C < $800 Then
        R := R + '%' + HexCh((($C0 Or (C Shr 6)) Shr 4) And 15) + HexCh(($C0 Or (C Shr 6)) And 15) +
             '%' + HexCh((($80 Or (C And 63)) Shr 4) And 15) + HexCh(($80 Or (C And 63)) And 15)
      Else
        R := R + '%' + HexCh((($E0 Or (C Shr 12)) Shr 4) And 15) + HexCh(($E0 Or (C Shr 12)) And 15) +
             '%' + HexCh((($80 Or ((C Shr 6) And 63)) Shr 4) And 15) + HexCh(($80 Or ((C Shr 6) And 63)) And 15) +
             '%' + HexCh((($80 Or (C And 63)) Shr 4) And 15) + HexCh(($80 Or (C And 63)) And 15);
    End;
  End;
  QrUrl := R;
End;

Function QrScale : LongInt;
Begin
  QrScale := MaxI(2, MinI(6, 300 Div (QrSize + 8)));
End;

Function QrProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var P, Sc, X0, Y0, X, Y, Fl, K, C : LongInt; Rc : Array[0..3] Of LongInt; S : String;
Begin
  QrProc := 0;
  Case Msg Of
    WM_CREATE : QrCl := H;
    WM_PAINT :
      Begin
        P := WinBeginPaint(H, 0, 0);
        Ps := P;
        RgbMode(Ps);
        CurBox := 0;
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Sc := QrScale;
        X0 := (Rc[2] - QrSize * Sc) Div 2;
        Y0 := Rc[3] - 4 * Sc - QrSize * Sc;
        { fond blanc autour du code seulement : pas de scintillement }
        GBoxF(0, Y0 + QrSize * Sc, Rc[2] - 1, Rc[3] - 1, $FFFFFF);
        GBoxF(0, 0, Rc[2] - 1, Y0 - 1, $FFFFFF);
        GBoxF(0, Y0, X0 - 1, Y0 + QrSize * Sc - 1, $FFFFFF);
        GBoxF(X0 + QrSize * Sc, Y0, Rc[2] - 1, Y0 + QrSize * Sc - 1, $FFFFFF);
        { chaque ligne : suites de modules de meme couleur }
        For Y := 0 To QrSize - 1 Do
        Begin
          X := 0;
          While X < QrSize Do
          Begin
            Fl := QrGet(X, Y);
            K := X;
            While (K + 1 < QrSize) And (QrGet(K + 1, Y) = Fl) Do Inc(K);
            If Fl <> 0 Then C := 0 Else C := $FFFFFF;
            GBoxF(X0 + X * Sc, Y0 + (QrSize - 1 - Y) * Sc, X0 + (K + 1) * Sc - 1, Y0 + (QrSize - Y) * Sc - 1, C);
            X := K + 1;
          End;
        End;
        S := Copy(QrText, 1, MaxI(8, (Rc[2] - 16) Div 8));
        TextS(MaxI(8, (Rc[2] - Length(S) * 8) Div 2), 40, S, $000080);
        S := IStr(Length(QrText)) + ' octets, version ' + IStr((QrSize - 17) Div 4) + ', correction L';
        TextS(MaxI(8, (Rc[2] - Length(S) * 8) Div 2), 20, S, $606060);
        Dummy := WinEndPaint(P);
      End;
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinDefWindowProc(H, Msg, Mp1, Mp2);
        QrProc := 1;
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1);
        If (Fl And KC_KEYUP) = 0 Then Dummy := WinPostMsg(H, WM_CLOSE, 0, 0);
      End;
    WM_CLOSE :
      Begin
        If QrFr <> 0 Then Dummy := WinDestroyWindow(QrFr);
        QrFr := 0; QrCl := 0;
      End;
  Else
    QrProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ fenetre du code QR de U (titre T) }
Procedure OpenQr(U, T : String);
Var Fl, Sw, Sh, W, Ht : LongInt;
Begin
  U := QrUrl(U);
  If U = '' Then Exit;
  If Not QrEncode(U) Then
  Begin
    ShowMsg('Adresse trop longue pour un code QR (271 octets au plus ; celle-ci en a ' + IStr(Length(U)) + ').',
            'Code QR', MB_OK Or MB_WARNING);
    Exit;
  End;
  QrText := U;
  If QrFr <> 0 Then Dummy := WinDestroyWindow(QrFr);
  QrFr := 0; QrCl := 0;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  QrFr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('WEBQR'), Z2('Code QR - ' + Copy(T, 1, 50)), 0, 0, 0,
                             LongInt(@QrCl));
  If QrFr = 0 Then Exit;
  W := MinI(620, MaxI(MaxI(300, (QrSize + 8) * QrScale + 24), Length(U) * 8 + 24));
  Ht := (QrSize + 8) * QrScale + 50 + 32;
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(QrFr, HWND_TOP, MaxI(0, (Sw - W) Div 2), MaxI(0, (Sh - Ht) Div 2), W, Ht,
                           SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, QrFr);
  Dummy := WinSetFocus(HWND_DESKTOP, QrCl);
  SetStatus('Code QR : ' + U);
End;

{ ==================================================================== }
{ Outils de developpement (F12, menu contextuel "Inspecter")            }
{ ==================================================================== }
{ Panneau ancre sous la page, a la maniere de Firebug et du BROWSER.PAS
  d'origine : Inspecteur (arbre du DOM, selecteur d'element, attributs
  et style calcule), Debogueur (scripts de la page, etat, erreurs),
  Editeur de style (feuilles de la page, modifiables ligne par ligne et
  appliquees aussitot), Console (journal et evaluation de JavaScript),
  Reseau (requetes de la page : etat, methode, domaine, fichier, type,
  taille, duree). }

Procedure LayoutChildren; Forward;

Function DevTabName(K : LongInt) : String;
Begin
  Case K Of
    DT_INSP : DevTabName := 'Inspecteur';
    DT_DEBUG : DevTabName := 'D' + Chr(130) + 'bogueur';
    DT_STYLE : DevTabName := Chr(144) + 'diteur de style';
    DT_CONSOLE : DevTabName := 'Console';
  Else
    DevTabName := 'R' + Chr(130) + 'seau';
  End;
End;

Function DevTabX(K : LongInt) : LongInt;
Var X, I : LongInt;
Begin
  X := 34;
  For I := 1 To K - 1 Do X := X + Length(DevTabName(I)) * 8 + 18;
  DevTabX := X;
End;

Function DevCollapsed(N : PNode) : Boolean;
Var K : LongInt;
Begin
  DevCollapsed := False;
  For K := 0 To DevColN - 1 Do
    If DevCol[K] = N Then
    Begin
      DevCollapsed := True;
      Exit;
    End;
End;

Procedure DevToggleNode(N : PNode);
Var K, J : LongInt;
Begin
  For K := 0 To DevColN - 1 Do
    If DevCol[K] = N Then
    Begin
      For J := K To DevColN - 2 Do DevCol[J] := DevCol[J + 1];
      Dec(DevColN);
      Exit;
    End;
  If DevColN < 512 Then
  Begin
    DevCol[DevColN] := N;
    Inc(DevColN);
  End;
End;

{ noeud affiche dans l'inspecteur (texte vide et commentaires exclus) }
Function DevShown(N : PNode) : Boolean;
Var K : LongInt;
Begin
  DevShown := False;
  If N^.Kind = NODE_ELEM Then DevShown := True
  Else If N^.Kind = NODE_TEXT Then
    For K := 0 To N^.TLen - 1 Do
      If RdB(N^.Txt + K) > 32 Then
      Begin
        DevShown := True;
        Exit;
      End;
End;

Function DevHasKids(N : PNode) : Boolean;
Var C : PNode;
Begin
  DevHasKids := False;
  If N^.Kind <> NODE_ELEM Then Exit;
  C := N^.First;
  While C <> Nil Do
  Begin
    If DevShown(C) Then
    Begin
      DevHasKids := True;
      Exit;
    End;
    C := C^.Next;
  End;
End;

{ ligne suivante de l'arbre (profondeur Dep) en tenant compte des noeuds replies }
Function DevNextRow(N : PNode; Var Dep : LongInt) : PNode;
Var C : PNode;
Begin
  DevNextRow := Nil;
  If (N^.Kind = NODE_ELEM) And Not DevCollapsed(N) Then
  Begin
    C := N^.First;
    While (C <> Nil) And Not DevShown(C) Do C := C^.Next;
    If C <> Nil Then
    Begin
      Inc(Dep);
      DevNextRow := C;
      Exit;
    End;
  End;
  While N <> Nil Do
  Begin
    C := N^.Next;
    While (C <> Nil) And Not DevShown(C) Do C := C^.Next;
    If C <> Nil Then
    Begin
      DevNextRow := C;
      Exit;
    End;
    N := N^.Parent;
    Dec(Dep);
    If (N = Nil) Or (N = Root) Then Exit;
  End;
End;

Function DevFirstRow : PNode;
Var C : PNode;
Begin
  DevFirstRow := Nil;
  If Root = Nil Then Exit;
  C := Root^.First;
  While (C <> Nil) And Not DevShown(C) Do C := C^.Next;
  DevFirstRow := C;
End;

{ texte d'une ligne de l'inspecteur, en segments colores }
Procedure DevDrawNode(N : PNode; X, Yt : LongInt; Sel : Boolean);
Var P : PAttr; S : String; Ct, Ca, Cv, Cx : LongInt;
Begin
  If Sel Then
  Begin
    Ct := $FFFFFF; Ca := $FFFF80; Cv := $C0FFC0; Cx := $FFFFFF;
  End
  Else
  Begin
    Ct := $000080; Ca := $A04000; Cv := $008000; Cx := $000000;
  End;
  If N^.Kind = NODE_TEXT Then
  Begin
    S := ArGet(N^.Txt, MinI(N^.TLen, 120));
    While (Length(S) > 0) And (S[1] <= ' ') Do Delete(S, 1, 1);
    For Ct := 1 To Length(S) Do If S[Ct] < ' ' Then S[Ct] := ' ';
    TextS(X, Yt, '"' + Copy(S, 1, 90) + '"', Cx);
    Exit;
  End;
  TextS(X, Yt, '<' + N^.Name, Ct);
  X := X + (Length(N^.Name) + 1) * 8;
  P := N^.Attr;
  While (P <> Nil) And (X < 2000) Do
  Begin
    If Copy(P^.Name, 1, 1) <> '#' Then
    Begin
      TextS(X + 8, Yt, P^.Name, Ca);
      X := X + (Length(P^.Name) + 1) * 8;
      S := ArGet(P^.Val, MinI(P^.VLen, 60));
      If P^.VLen > 60 Then S := S + '...';
      TextS(X, Yt, '="', Cx);
      TextS(X + 16, Yt, S, Cv);
      X := X + (Length(S) + 2) * 8;
      TextS(X, Yt, '"', Cx);
      X := X + 8;
    End;
    P := P^.Next;
  End;
  TextS(X, Yt, '>', Ct);
End;

{ proprietes de l'element choisi (colonne de droite de l'inspecteur) }
Procedure DevDrawProps(X0, Yt, Ybot : LongInt);
Var P : PAttr; Cs : PStyle; Y : LongInt; S : String;
Begin
  Y := Yt;
  If DevSel = Nil Then
  Begin
    TextS(X0, Y, 'Choisissez un ' + Chr(130) + 'l' + Chr(130) + 'ment (clic, ou bouton', $606060);
    TextS(X0, Y - 16, 'de s' + Chr(130) + 'lection puis la page).', $606060);
    Exit;
  End;
  If DevSel^.Kind <> NODE_ELEM Then
  Begin
    TextS(X0, Y, 'Noeud texte (' + IStr(DevSel^.TLen) + ' caract' + Chr(138) + 'res)', $000080);
    Exit;
  End;
  TextS(X0, Y, '<' + DevSel^.Name + '>  attributs', $000080);
  Y := Y - 16;
  P := DevSel^.Attr;
  While (P <> Nil) And (Y > Ybot + 16) Do
  Begin
    If Copy(P^.Name, 1, 1) <> '#' Then
    Begin
      TextS(X0 + 8, Y, P^.Name, $A04000);
      TextS(X0 + 8 + (Length(P^.Name) + 1) * 8, Y, Copy(ArGet(P^.Val, MinI(P^.VLen, 40)), 1, 30), $008000);
      Y := Y - 16;
    End;
    P := P^.Next;
  End;
  If Y <= Ybot + 32 Then Exit;
  Y := Y - 4;
  TextS(X0, Y, 'Style calcul' + Chr(130), $000080);
  Y := Y - 16;
  Cs := NodeStyle(DevSel);
  If Cs = Nil Then
  Begin
    TextS(X0 + 8, Y, '(aucune r' + Chr(138) + 'gle CSS)', $606060);
    Exit;
  End;
  If (Cs^.Color >= 0) And (Y > Ybot) Then
  Begin
    TextS(X0 + 8, Y, 'color: #' + Copy(HexStr8(Cs^.Color), 3, 6), 0);
    GBoxF(X0 + 150, Y - 12, X0 + 162, Y - 2, Cs^.Color);
    Y := Y - 16;
  End;
  If (Cs^.Back >= 0) And (Y > Ybot) Then
  Begin
    TextS(X0 + 8, Y, 'background: #' + Copy(HexStr8(Cs^.Back), 3, 6), 0);
    GBoxF(X0 + 150, Y - 12, X0 + 162, Y - 2, Cs^.Back);
    Y := Y - 16;
  End;
  If (Cs^.Display <> 0) And (Y > Ybot) Then
  Begin
    Case Cs^.Display Of
      1 : S := 'none';
      2 : S := 'block';
    Else
      S := 'inline';
    End;
    TextS(X0 + 8, Y, 'display: ' + S, 0);
    Y := Y - 16;
  End;
  If (Cs^.Size <> 0) And (Y > Ybot) Then
  Begin
    TextS(X0 + 8, Y, 'font-size: ' + IStr(Cs^.Size) + ' (1 ' + Chr(133) + ' 7)', 0);
    Y := Y - 16;
  End;
  If (Cs^.Bold = 1) And (Y > Ybot) Then
  Begin
    TextS(X0 + 8, Y, 'font-weight: bold', 0);
    Y := Y - 16;
  End;
  If (Cs^.Width > 0) And (Y > Ybot) Then
  Begin
    TextS(X0 + 8, Y, 'width: ' + IStr(Cs^.Width) + 'px', 0);
    Y := Y - 16;
  End;
  If (Cs^.MarL >= 0) And (Y > Ybot) Then
  Begin
    TextS(X0 + 8, Y, 'margin-left: ' + IStr(Cs^.MarL) + 'px', 0);
    Y := Y - 16;
  End;
  If (Cs^.PadL >= 0) And (Y > Ybot) Then TextS(X0 + 8, Y, 'padding-left: ' + IStr(Cs^.PadL) + 'px', 0);
End;

{ sources CSS de la page : <style> et <link> charges, dans l'ordre }
Function DevCssCount : LongInt; Forward;
Function DevCssNode(I : LongInt) : PNode; Forward;

Procedure DevCssWalk(N : PNode; Var Cnt : LongInt; Want : LongInt; Var R : PNode);
Var C : PNode;
Begin
  If (N = Nil) Or (R <> Nil) Then Exit;
  C := N^.First;
  While (C <> Nil) And (R = Nil) Do
  Begin
    If C^.Kind = NODE_ELEM Then
    Begin
      If ((C^.Tag = TAG_STYLE) And (C^.First <> Nil)) Or ((C^.Tag = TAG_LINK) And (FindAttr(C, '#css') <> Nil)) Then
      Begin
        If Cnt = Want Then R := C;
        Inc(Cnt);
      End
      Else DevCssWalk(C, Cnt, Want, R);
    End;
    C := C^.Next;
  End;
End;

Function DevCssCount : LongInt;
Var Cnt : LongInt; R : PNode;
Begin
  Cnt := 0; R := Nil;
  DevCssWalk(Root, Cnt, -1, R);
  DevCssCount := Cnt;
End;

Function DevCssNode(I : LongInt) : PNode;
Var Cnt : LongInt; R : PNode;
Begin
  Cnt := 0; R := Nil;
  DevCssWalk(Root, Cnt, I, R);
  DevCssNode := R;
End;

{ texte d'une source (CSS ou script) : adresse, longueur }
Procedure DevSrcText(N : PNode; Var A, L : LongInt);
Var P : PAttr;
Begin
  A := 0; L := 0;
  If N = Nil Then Exit;
  P := FindAttr(N, '#css');
  If P = Nil Then P := FindAttr(N, '#js');
  If P <> Nil Then
  Begin
    A := P^.Val; L := P^.VLen;
  End
  Else If (N^.First <> Nil) And (N^.First^.Kind = NODE_TEXT) Then
  Begin
    A := N^.First^.Txt; L := N^.First^.TLen;
  End;
End;

Function DevSrcName(N : PNode; I : LongInt) : String;
Begin
  If N = Nil Then DevSrcName := ''
  Else If HasAttr(N, 'href') Then DevSrcName := GetAttr(N, 'href')
  Else If HasAttr(N, 'src') Then DevSrcName := GetAttr(N, 'src')
  Else If N^.Tag = TAG_STYLE Then DevSrcName := '<style> n' + Chr(248) + IStr(I + 1)
  Else DevSrcName := '<script> n' + Chr(248) + IStr(I + 1);
End;

Procedure DevScrWalk(N : PNode; Var Cnt : LongInt; Want : LongInt; Var R : PNode);
Var C : PNode;
Begin
  If (N = Nil) Or (R <> Nil) Then Exit;
  C := N^.First;
  While (C <> Nil) And (R = Nil) Do
  Begin
    If C^.Kind = NODE_ELEM Then
    Begin
      If C^.Tag = TAG_SCRIPT Then
      Begin
        If Cnt = Want Then R := C;
        Inc(Cnt);
      End
      Else DevScrWalk(C, Cnt, Want, R);
    End;
    C := C^.Next;
  End;
End;

Function DevScrCount : LongInt;
Var Cnt : LongInt; R : PNode;
Begin
  Cnt := 0; R := Nil;
  DevScrWalk(Root, Cnt, -1, R);
  DevScrCount := Cnt;
End;

Function DevScrNode(I : LongInt) : PNode;
Var Cnt : LongInt; R : PNode;
Begin
  Cnt := 0; R := Nil;
  DevScrWalk(Root, Cnt, I, R);
  DevScrNode := R;
End;

{ ligne K (0..) d'un texte (A, L) : adresse et longueur }
Function DevLineAt(A, L, K : LongInt; Var LA, LL : LongInt) : Boolean;
Var I, N, S : LongInt;
Begin
  DevLineAt := False;
  I := 0; N := 0; S := 0;
  While I <= L Do
  Begin
    If (I = L) Or (RdB(A + I) = 10) Then
    Begin
      If N = K Then
      Begin
        LA := A + S; LL := I - S;
        If (LL > 0) And (RdB(LA + LL - 1) = 13) Then Dec(LL);
        DevLineAt := True;
        Exit;
      End;
      Inc(N);
      S := I + 1;
    End;
    Inc(I);
  End;
End;

Function DevLines(A, L : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 1;
  For I := 0 To L - 1 Do If RdB(A + I) = 10 Then Inc(N);
  If L = 0 Then N := 0;
  DevLines := N;
End;

{ ligne de code coloree (CSS : proprietes et valeurs ; JS : mots-cles,
  chaines, nombres, commentaires) }
Procedure DevCodeLine(X, Yt, A, L, MaxC : LongInt; Js : Boolean);
Var K, S, C, Col, Q : LongInt; W : String;
Begin
  K := 0;
  L := MinI(L, MaxC);
  While K < L Do
  Begin
    S := K;
    C := RdB(A + K);
    If (C = 47) And (K + 1 < L) And ((RdB(A + K + 1) = 47) Or (RdB(A + K + 1) = 42)) Then
    Begin
      K := L; Col := $808080;
    End
    Else If (C = 34) Or (C = 39) Then
    Begin
      Q := C; Inc(K);
      While (K < L) And (RdB(A + K) <> Q) Do Inc(K);
      If K < L Then Inc(K);
      Col := $008000;
    End
    Else If Chr(C) In ['0'..'9'] Then
    Begin
      While (K < L) And (Chr(RdB(A + K)) In ['0'..'9', '.', 'x', 'a'..'f', '%']) Do Inc(K);
      Col := $008080;
    End
    Else If (Chr(C Or $20) In ['a'..'z']) Or (C = 95) Or (C = 36) Or (C = 45) Or (C = 35) Then
    Begin
      While (K < L) And ((Chr(RdB(A + K) Or $20) In ['a'..'z', '0'..'9']) Or (RdB(A + K) In [95, 36, 45, 35])) Do Inc(K);
      W := ArGet(A + S, MinI(K - S, 20));
      Col := 0;
      If Js Then
      Begin
        If (W = 'var') Or (W = 'let') Or (W = 'const') Or (W = 'function') Or (W = 'return') Or (W = 'if') Or
           (W = 'else') Or (W = 'for') Or (W = 'while') Or (W = 'do') Or (W = 'new') Or (W = 'this') Or
           (W = 'typeof') Or (W = 'true') Or (W = 'false') Or (W = 'null') Or (W = 'undefined') Or
           (W = 'try') Or (W = 'catch') Or (W = 'throw') Or (W = 'switch') Or (W = 'case') Or (W = 'break') Or
           (W = 'continue') Or (W = 'document') Or (W = 'window') Or (W = 'console') Then Col := $0000C0;
      End
      Else
      Begin
        { propriete "nom:" ; selecteurs }
        Q := K;
        While (Q < L) And (RdB(A + Q) = 32) Do Inc(Q);
        If (Q < L) And (RdB(A + Q) = 58) Then Col := $A00000 Else Col := $800080;
      End;
    End
    Else
    Begin
      Inc(K);
      If Chr(C) In ['{', '}', ';', ':', '(', ')', '=', '+', '-', '*', '<', '>', '!', '&', '|'] Then Col := $A04000
      Else Col := 0;
    End;
    If K > S Then TextAt(X + S * 8, Yt, 1, 0, Col, A + S, K - S);
  End;
End;

Procedure DevUpdateSb(Vis : LongInt);
Var Mx : LongInt;
Begin
  If DevSb = 0 Then Exit;
  Mx := MaxI(0, DevTotal - Vis);
  If DevTop[DevTab] > Mx Then DevTop[DevTab] := Mx;
  If DevTop[DevTab] < 0 Then DevTop[DevTab] := 0;
  Dummy := WinSendMsg(DevSb, SBM_SETSCROLLBAR, DevTop[DevTab], Mx Shl 16);
End;

Procedure DevPaint(H : LongInt);
Var Rc : Array[0..3] Of LongInt; W, Ht, K, X, Y, Yt, Vis, Dep, Row, A, L, LA, LL, LeftW, Cnt, Kd, C : LongInt;
    N : PNode; S, T : String;
Begin
  Ps := WinBeginPaint(H, 0, LongInt(@Rc));
  If Ps = 0 Then Exit;
  RgbMode(Ps);
  Dummy := GpiSetBackMix(Ps, BM_LEAVEALONE);
  CurBox := 0;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  W := Rc[2] - SCW; Ht := Rc[3];
  GBoxF(0, 0, Rc[2], Ht, $C0C0C0);
  { barre des onglets : bouton de selection, onglets, fermeture }
  Bevel(0, Ht - 1, Rc[2] - 1, Ht - 1, True);
  If DevPick Then GBoxF(4, Ht - 21, 26, Ht - 4, $000080) Else GBoxF(4, Ht - 21, 26, Ht - 4, $C0C0C0);
  Bevel(4, Ht - 21, 26, Ht - 4, Not DevPick);
  If DevPick Then C := $FFFFFF Else C := 0;
  GBoxO(9, Ht - 16, 19, Ht - 9, C);
  GLn(16, Ht - 13, 22, Ht - 19, C); GLn(17, Ht - 13, 23, Ht - 19, C);
  For K := 1 To 5 Do
  Begin
    X := DevTabX(K);
    If K = DevTab Then
    Begin
      GBoxF(X, Ht - DEV_TABH + 1, X + Length(DevTabName(K)) * 8 + 12, Ht - 2, $FFFFFF);
      Bevel(X, Ht - DEV_TABH + 1, X + Length(DevTabName(K)) * 8 + 12, Ht - 2, True);
    End
    Else Bevel(X, Ht - DEV_TABH + 3, X + Length(DevTabName(K)) * 8 + 12, Ht - 3, True);
    TextS(X + 6, Ht - 4, DevTabName(K), 0);
  End;
  GBoxF(Rc[2] - 22, Ht - 21, Rc[2] - 4, Ht - 4, $C0C0C0);
  Bevel(Rc[2] - 22, Ht - 21, Rc[2] - 4, Ht - 4, True);
  TextS(Rc[2] - 17, Ht - 5, 'x', 0);
  { zone de contenu }
  Yt := Ht - DEV_TABH - 2;
  If DevTab = DT_CONSOLE Then K := 30 Else K := 2;
  GBoxF(2, K, W - 1, Yt, $FFFFFF);
  Sunken(1, K - 1, W, Yt + 1);
  Vis := MaxI(1, (Yt - K - 4) Div DEV_ROWH);
  Y := Yt - 2;
  DevRowN := 0;
  Case DevTab Of
    DT_INSP :
      Begin
        LeftW := MaxI(200, (W * 3) Div 5);
        N := DevFirstRow; Dep := 0; Row := 0; DevTotal := 0;
        While N <> Nil Do
        Begin
          If (Row >= DevTop[DT_INSP]) And (DevRowN < Vis) And (DevRowN < 80) Then
          Begin
            X := 8 + Dep * 16;
            If N = DevSel Then GBoxF(3, Y - DEV_ROWH + 1, LeftW - 4, Y, $000080);
            If DevHasKids(N) Then
            Begin
              If DevCollapsed(N) Then T := '+' Else T := '-';
              If N = DevSel Then C := $FFFFFF Else C := $606060;
              TextS(X, Y, T, C);
            End;
            DevDrawNode(N, X + 12, Y, N = DevSel);
            DevRowNode[DevRowN] := N; DevRowX[DevRowN] := X;
            Inc(DevRowN);
            Y := Y - DEV_ROWH;
          End;
          Inc(Row);
          N := DevNextRow(N, Dep);
        End;
        DevTotal := Row;
        { colonne des proprietes }
        GBoxF(LeftW, 3, W - 2, Yt - 1, $F0F0F0);
        GLn(LeftW, 3, LeftW, Yt - 1, $808080);
        DevDrawProps(LeftW + 8, Yt - 2, 4);
        If Root = Nil Then TextS(8, Yt - 2, '(pas de document HTML)', $606060);
      End;
    DT_DEBUG :
      Begin
        { etat, puis liste des scripts et code du script choisi }
        S := 'Scripts : ' + IStr(DevScrCount) + '   fonctions : ' + IStr(JsFuncN) + '   erreurs : ' + IStr(JsErrCount);
        If Not JsReady Then S := 'JavaScript indisponible';
        TextS(8, Y, S, $000080);
        Y := Y - DEV_ROWH;
        If JsLastErr <> '' Then TextS(8, Y, Copy('Derni' + Chr(138) + 're erreur : ' + JsLastErr, 1, (W - 16) Div 8), $C00000)
        Else TextS(8, Y, 'Aucune erreur JavaScript.', $008000);
        Y := Y - DEV_ROWH - 4;
        LeftW := MinI(260, MaxI(160, W Div 4));
        GLn(3, Y + 2, W - 2, Y + 2, $808080);
        GLn(LeftW, 3, LeftW, Y + 2, $808080);
        Cnt := DevScrCount;
        If DevScrSel >= Cnt Then DevScrSel := 0;
        For K := 0 To MinI(Cnt, 40) - 1 Do
          If Y - K * DEV_ROWH > 4 + DEV_ROWH Then
          Begin
            N := DevScrNode(K);
            S := Copy(DevSrcName(N, K), 1, (LeftW - 12) Div 8);
            If K = DevScrSel Then
            Begin
              GBoxF(3, Y - K * DEV_ROWH - DEV_ROWH + 1, LeftW - 2, Y - K * DEV_ROWH, $000080);
              TextS(6, Y - K * DEV_ROWH, S, $FFFFFF);
            End
            Else TextS(6, Y - K * DEV_ROWH, S, 0);
          End;
        If Cnt = 0 Then TextS(8, Y, '(aucun script)', $606060);
        N := DevScrNode(DevScrSel);
        DevSrcText(N, A, L);
        DevTotal := DevLines(A, L);
        Vis := MaxI(1, (Y - 6) Div DEV_ROWH);
        For K := 0 To Vis - 1 Do
          If DevLineAt(A, L, DevTop[DT_DEBUG] + K, LA, LL) Then
          Begin
            S := IStr(DevTop[DT_DEBUG] + K + 1);
            While Length(S) < 4 Do S := ' ' + S;
            TextS(LeftW + 4, Y - K * DEV_ROWH, S, $909090);
            DevCodeLine(LeftW + 44, Y - K * DEV_ROWH, LA, LL, MaxI(1, (W - LeftW - 50) Div 8), True);
          End;
      End;
    DT_STYLE :
      Begin
        LeftW := MinI(260, MaxI(160, W Div 4));
        GLn(LeftW, 3, LeftW, Yt - 1, $808080);
        Cnt := DevCssCount;
        If DevSrcSel >= Cnt Then DevSrcSel := 0;
        For K := 0 To MinI(Cnt, 40) - 1 Do
          If Y - K * DEV_ROWH > 4 + DEV_ROWH Then
          Begin
            N := DevCssNode(K);
            S := Copy(DevSrcName(N, K), 1, (LeftW - 12) Div 8);
            If K = DevSrcSel Then
            Begin
              GBoxF(3, Y - K * DEV_ROWH - DEV_ROWH + 1, LeftW - 2, Y - K * DEV_ROWH, $000080);
              TextS(6, Y - K * DEV_ROWH, S, $FFFFFF);
            End
            Else TextS(6, Y - K * DEV_ROWH, S, 0);
          End;
        If Cnt = 0 Then TextS(8, Y, 'Aucune feuille CSS', $606060)
        Else TextS(6, 20, 'Double clic : modifier', $606060);
        N := DevCssNode(DevSrcSel);
        DevSrcText(N, A, L);
        DevTotal := DevLines(A, L);
        For K := 0 To Vis - 1 Do
          If DevLineAt(A, L, DevTop[DT_STYLE] + K, LA, LL) Then
          Begin
            If DevTop[DT_STYLE] + K = DevEditLine Then GBoxF(LeftW + 1, Y - K * DEV_ROWH - DEV_ROWH + 1, W - 2, Y - K * DEV_ROWH, $FFFFC0);
            S := IStr(DevTop[DT_STYLE] + K + 1);
            While Length(S) < 4 Do S := ' ' + S;
            TextS(LeftW + 4, Y - K * DEV_ROWH, S, $909090);
            DevCodeLine(LeftW + 44, Y - K * DEV_ROWH, LA, LL, MaxI(1, (W - LeftW - 50) Div 8), False);
          End;
      End;
    DT_CONSOLE :
      Begin
        DevTotal := JsConN;
        { dernieres lignes en bas (la barre de defilement remonte) }
        Cnt := Vis;
        K := MaxI(0, JsConN - Cnt - DevTop[DT_CONSOLE]);
        Y := Yt - 2;
        While (K < JsConN - DevTop[DT_CONSOLE]) And (Y > 30 + DEV_ROWH - 2) Do
        Begin
          S := JsConLine(K);
          Kd := JsConKindOf(K);
          Case Kd Of
            1 :
              Begin
                GBoxF(3, Y - DEV_ROWH + 1, W - 2, Y, $FFF0F0);
                TextS(6, Y, Chr(19) + ' ' + Copy(S, 1, (W - 30) Div 8), $C00000);
              End;
            2 : TextS(6, Y, '>> ' + Copy(S, 1, (W - 40) Div 8), $0000C0);
            3 : TextS(6, Y, '<- ' + Copy(S, 1, (W - 40) Div 8), $606060);
            4 :
              Begin
                GBoxF(3, Y - DEV_ROWH + 1, W - 2, Y, $FFFFE0);
                TextS(6, Y, '! ' + Copy(S, 1, (W - 30) Div 8), $806000);
              End;
          Else
            TextS(6, Y, Copy(S, 1, (W - 16) Div 8), 0);
          End;
          Y := Y - DEV_ROWH;
          Inc(K);
        End;
        If JsConN = 0 Then TextS(8, Yt - 2, 'Console JavaScript : tapez une expression puis Entr' + Chr(130) + 'e (' + Chr(24) + Chr(25) + ' : historique).', $606060);
        TextS(6, 22, '>>', $0000C0);
      End;
    DT_NET :
      Begin
        { colonnes }
        GBoxF(3, Y - DEV_ROWH + 1, W - 2, Y, $E0E0E0);
        TextS(6, Y, Chr(144) + 'tat', 0); TextS(56, Y, 'M' + Chr(130) + 'th.', 0);
        TextS(106, Y, 'Domaine', 0); TextS((W * 35) Div 100, Y, 'Fichier', 0);
        TextS((W * 62) Div 100, Y, 'Type', 0); TextS((W * 76) Div 100, Y, 'Taille', 0);
        TextS((W * 88) Div 100, Y, 'Dur' + Chr(130) + 'e', 0);
        Y := Y - DEV_ROWH;
        DevTotal := NetN;
        A := 0; L := 0;
        For K := 0 To NetN - 1 Do
        Begin
          A := A + NetSize[K];
          L := L + NetMs[K];
        End;
        For K := DevTop[DT_NET] To NetN - 1 Do
        Begin
          If Y < 4 + 2 * DEV_ROWH Then Break;
          If K = DevNetSel Then GBoxF(3, Y - DEV_ROWH + 1, W - 2, Y, $D0D8FF);
          If NetStat[K] >= 400 Then C := $C00000 Else If NetStat[K] >= 300 Then C := $806000 Else C := $008000;
          If NetStat[K] = 0 Then S := 'err.' Else S := IStr(NetStat[K]);
          TextS(6, Y, S, C);
          TextS(56, Y, NetMeth[K], 0);
          S := NetUrl[K];
          T := '';
          If Pos('://', S) > 0 Then
          Begin
            T := Copy(S, Pos('://', S) + 3, 255);
            If Pos('/', T) > 0 Then
            Begin
              S := Copy(T, Pos('/', T), 255);
              T := Copy(T, 1, Pos('/', T) - 1);
            End
            Else S := '/';
          End;
          If Pos('?', S) > 0 Then S := Copy(S, 1, Pos('?', S) - 1);
          While Pos('/', S) > 0 Do
            If Pos('/', S) = Length(S) Then Break Else Delete(S, 1, Pos('/', S));
          TextS(106, Y, Copy(T, 1, MaxI(1, ((W * 35) Div 100 - 110) Div 8)), 0);
          TextS((W * 35) Div 100, Y, Copy(S, 1, MaxI(1, ((W * 27) Div 100 - 4) Div 8)), $000080);
          TextS((W * 62) Div 100, Y, Copy(NetType[K], 1, MaxI(1, ((W * 14) Div 100 - 4) Div 8)), $606060);
          If NetSize[K] >= 10240 Then S := IStr(NetSize[K] Div 1024) + ' Ko' Else S := IStr(NetSize[K]) + ' o';
          TextS((W * 76) Div 100, Y, S, 0);
          TextS((W * 88) Div 100, Y, IStr(NetMs[K]) + ' ms', 0);
          Y := Y - DEV_ROWH;
        End;
        S := IStr(NetN) + ' requ' + Chr(136) + 'te(s), ' + IStr((A + 512) Div 1024) + ' Ko, ' + IStr(L) + ' ms';
        GBoxF(3, 4, W - 2, 4 + DEV_ROWH, $E0E0E0);
        TextS(6, 4 + DEV_ROWH - 1, S, $000080);
      End;
  End;
  If DevTab = DT_CONSOLE Then DevUpdateSb(Vis) Else DevUpdateSb(Vis);
  Dummy := WinEndPaint(Ps);
  If DevIn <> 0 Then Dummy := WinInvalidateRect(DevIn, 0, 0);
End;

Procedure DevRedraw;
Begin
  If DevOpen And (DevWin <> 0) Then Dummy := WinInvalidateRect(DevWin, 0, 0);
End;

{ position du champ de saisie : console (en bas) ou ligne de style modifiee }
Procedure DevPlaceInput;
Var Rc : Array[0..3] Of LongInt; W, LeftW, Y : LongInt;
Begin
  If DevIn = 0 Then Exit;
  Dummy := WinQueryWindowRect(DevWin, LongInt(@Rc));
  W := Rc[2] - SCW;
  If DevTab = DT_CONSOLE Then
  Begin
    Dummy := WinSetWindowPos(DevIn, HWND_TOP, 28, 5, MaxI(40, W - 34), 18, SWP_MOVE Or SWP_SIZE Or SWP_SHOW);
  End
  Else If (DevTab = DT_STYLE) And (DevEditLine >= 0) Then
  Begin
    LeftW := MinI(260, MaxI(160, W Div 4));
    Y := Rc[3] - DEV_TABH - 4 - (DevEditLine - DevTop[DT_STYLE] + 1) * DEV_ROWH;
    Dummy := WinSetWindowPos(DevIn, HWND_TOP, LeftW + 42, MaxI(4, Y), MaxI(40, W - LeftW - 46), 18,
                             SWP_MOVE Or SWP_SIZE Or SWP_SHOW);
  End
  Else Dummy := WinShowWindow(DevIn, 0);
End;

Procedure DevSetTab(K : LongInt);
Begin
  DevTab := K;
  DevEditLine := -1;
  If K <> DT_INSP Then DevPick := False;
  DevPlaceInput;
  If K = DT_CONSOLE Then
  Begin
    Dummy := WinSetWindowText(DevIn, Z(''));
    Dummy := WinSetFocus(HWND_DESKTOP, DevIn);
  End;
  DevRedraw;
  RedrawView;
End;

Procedure DevShow(On : Boolean);
Begin
  If On = DevOpen Then
  Begin
    If On Then DevRedraw;
    Exit;
  End;
  DevOpen := On;
  If Not On Then
  Begin
    DevPick := False;
    If DevWin <> 0 Then Dummy := WinShowWindow(DevWin, 0);
  End
  Else If DevWin <> 0 Then Dummy := WinShowWindow(DevWin, 1);
  LayoutChildren;
  Relayout;
  RedrawView;
  If On Then DevSetTab(DevTab);
End;

{ element choisi dans la page (selecteur) : ses parents sont deplies et
  sa ligne devient visible }
Procedure DevSelect(N : PNode);
Var P, R : PNode; K, Row, Dep : LongInt;
Begin
  DevSel := N;
  If N = Nil Then Exit;
  P := N^.Parent;
  While P <> Nil Do
  Begin
    If DevCollapsed(P) Then DevToggleNode(P);
    P := P^.Parent;
  End;
  { rang de la ligne }
  R := DevFirstRow; Dep := 0; Row := 0;
  While (R <> Nil) And (R <> N) Do
  Begin
    Inc(Row);
    R := DevNextRow(R, Dep);
  End;
  If R = N Then DevTop[DT_INSP] := MaxI(0, Row - 3);
  K := 0;
  DevRedraw;
  RedrawView;
End;

Procedure DevPicked(N : PNode);
Begin
  DevPick := False;
  If N = Nil Then N := Root;
  DevSetTab(DT_INSP);
  DevSelect(N);
  If N <> Nil Then SetStatus('Inspecteur : <' + N^.Name + '>');
End;

{ modification d'une ligne d'une feuille de style : nouveau texte dans
  l'arene, styles recalcules, nouvelle mise en page }
Procedure DevApplyLine(Txt : String);
Var N, C : PNode; A, L, LA, LL, D, P : LongInt; T : TJV;
Begin
  N := DevCssNode(DevSrcSel);
  If (N = Nil) Or (DevEditLine < 0) Then Exit;
  DevSrcText(N, A, L);
  If Not DevLineAt(A, L, DevEditLine, LA, LL) Then Exit;
  D := ArAlloc(L - LL + Length(Txt) + 1);
  If D = 0 Then Exit;
  P := LA - A;
  MemCopy(A, D, P);
  If Length(Txt) > 0 Then MemCopy(LongInt(@Txt[1]), D + P, Length(Txt));
  MemCopy(LA + LL, D + P + Length(Txt), L - P - LL);
  L := L - LL + Length(Txt);
  If FindAttr(N, '#css') <> Nil Then JsSetAttr(N, '#css', D, L)
  Else If (N^.First <> Nil) And (N^.First^.Kind = NODE_TEXT) Then
  Begin
    N^.First^.Txt := D; N^.First^.TLen := L;
  End;
  { styles recalcules : caches des noeuds remis a zero }
  C := Root;
  While C <> Nil Do
  Begin
    C^.Css := 0;
    C := NextInDoc(C);
  End;
  NRules := 0;
  CollectStyles(Root);
  Inc(LayGen);
  Relayout;
  SetStatus('Style appliqu' + Chr(130) + ' (' + IStr(NRules) + ' r' + Chr(138) + 'gles)');
End;

Procedure DevEnter;
Var S : String; K : LongInt;
Begin
  Dummy := WinQueryWindowText(DevIn, 250, LongInt(@TxtBuf));
  S := GetZ(LongInt(@TxtBuf));
  If DevTab = DT_CONSOLE Then
  Begin
    If TrimS(S) = '' Then Exit;
    If DevHistN < 20 Then Inc(DevHistN) Else
      For K := 0 To 18 Do DevHist[K] := DevHist[K + 1];
    DevHist[DevHistN - 1] := S;
    DevHistPos := DevHistN;
    SetJsPage;
    JsConsoleEval(S);
    Dummy := WinSetWindowText(DevIn, Z(''));
    DevTop[DT_CONSOLE] := 0;
    JsAfterRun;
    DevRedraw;
  End
  Else If (DevTab = DT_STYLE) And (DevEditLine >= 0) Then
  Begin
    DevApplyLine(S);
    DevEditLine := -1;
    DevPlaceInput;
    DevRedraw;
  End;
End;

Procedure DevClick(X, Y : LongInt; Dbl : Boolean);
Var Rc : Array[0..3] Of LongInt; W, Ht, K, Row, LeftW, A, L, LA, LL : LongInt; N : PNode;
Begin
  Dummy := WinQueryWindowRect(DevWin, LongInt(@Rc));
  W := Rc[2] - SCW; Ht := Rc[3];
  If Y >= Ht - DEV_TABH Then
  Begin
    { barre des onglets }
    If X < 30 Then
    Begin
      DevPick := Not DevPick;
      If DevPick Then
      Begin
        DevTab := DT_INSP;
        SetStatus('Cliquez un ' + Chr(130) + 'l' + Chr(130) + 'ment de la page pour l''inspecter');
      End;
      DevSetTab(DevTab);
      Exit;
    End;
    If X > Rc[2] - 24 Then
    Begin
      DevShow(False);
      Exit;
    End;
    For K := 1 To 5 Do
      If (X >= DevTabX(K)) And (X <= DevTabX(K) + Length(DevTabName(K)) * 8 + 12) Then DevSetTab(K);
    Exit;
  End;
  Row := (Ht - DEV_TABH - 4 - Y) Div DEV_ROWH;
  Case DevTab Of
    DT_INSP :
      If (Row >= 0) And (Row < DevRowN) Then
      Begin
        N := DevRowNode[Row];
        If (X >= DevRowX[Row] - 2) And (X < DevRowX[Row] + 10) And DevHasKids(N) Then DevToggleNode(N)
        Else If Dbl And DevHasKids(N) Then DevToggleNode(N);
        DevSel := N;
        DevRedraw;
        RedrawView;
      End;
    DT_DEBUG :
      Begin
        LeftW := MinI(260, MaxI(160, W Div 4));
        If X < LeftW Then
        Begin
          K := Row - 2;
          If (K >= 0) And (K < DevScrCount) Then
          Begin
            DevScrSel := K;
            DevTop[DT_DEBUG] := 0;
            DevRedraw;
          End;
        End;
      End;
    DT_STYLE :
      Begin
        LeftW := MinI(260, MaxI(160, W Div 4));
        If X < LeftW Then
        Begin
          If (Row >= 0) And (Row < DevCssCount) Then
          Begin
            DevSrcSel := Row;
            DevTop[DT_STYLE] := 0;
            DevEditLine := -1;
            DevPlaceInput;
            DevRedraw;
          End;
        End
        Else If Dbl Then
        Begin
          { modifier la ligne }
          N := DevCssNode(DevSrcSel);
          DevSrcText(N, A, L);
          If DevLineAt(A, L, DevTop[DT_STYLE] + Row, LA, LL) Then
          Begin
            DevEditLine := DevTop[DT_STYLE] + Row;
            Dummy := WinSetWindowText(DevIn, Z(ArGet(LA, MinI(LL, 250))));
            DevPlaceInput;
            Dummy := WinSetFocus(HWND_DESKTOP, DevIn);
            DevRedraw;
          End;
        End;
      End;
    DT_CONSOLE : Dummy := WinSetFocus(HWND_DESKTOP, DevIn);
    DT_NET :
      Begin
        K := DevTop[DT_NET] + Row - 1;
        If (K >= 0) And (K < NetN) Then
        Begin
          DevNetSel := K;
          SetStatus(NetMeth[K] + ' ' + NetUrl[K] + '  (' + IStr(NetStat[K]) + ', ' + NetType[K] + ')');
          DevRedraw;
        End;
      End;
  End;
End;

Function DevProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk, Cmd, Vis : LongInt;
Begin
  DevProc := 0;
  Case Msg Of
    WM_PAINT : DevPaint(H);
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
      Begin
        Dummy := WinDefWindowProc(H, Msg, Mp1, Mp2);
        If DevTab <> DT_CONSOLE Then Dummy := WinSetFocus(HWND_DESKTOP, H);
        DevClick(S16(Mp1), S16(Mp1 Shr 16), Msg = WM_BUTTON1DBLCLK);
        DevProc := 1;
      End;
    WM_VSCROLL :
      Begin
        Cmd := Hi16(Mp2);
        Vis := MaxI(1, (DevH - DEV_TABH - 34) Div DEV_ROWH);
        Case Cmd Of
          SB_LINEUP : Dec(DevTop[DevTab]);
          SB_LINEDOWN : Inc(DevTop[DevTab]);
          SB_PAGEUP : DevTop[DevTab] := DevTop[DevTab] - Vis;
          SB_PAGEDOWN : DevTop[DevTab] := DevTop[DevTab] + Vis;
          SB_SLIDERTRACK, SB_SLIDERPOSITION : DevTop[DevTab] := S16(Mp2);
        End;
        If DevTop[DevTab] < 0 Then DevTop[DevTab] := 0;
        DevEditLine := -1;
        DevPlaceInput;
        DevRedraw;
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) Then
        Begin
          If (Vk = VK_ENTER) Or (Vk = VK_NEWLINE) Then DevEnter
          Else If Vk = VK_ESC Then
          Begin
            If DevEditLine >= 0 Then
            Begin
              DevEditLine := -1;
              DevPlaceInput;
              DevRedraw;
            End
            Else DevShow(False);
          End
          Else If (DevTab = DT_CONSOLE) And ((Vk = VK_UP) Or (Vk = VK_DOWN)) Then
          Begin
            { historique des commandes }
            If (Vk = VK_UP) And (DevHistPos > 0) Then Dec(DevHistPos);
            If (Vk = VK_DOWN) And (DevHistPos < DevHistN) Then Inc(DevHistPos);
            If DevHistPos < DevHistN Then Dummy := WinSetWindowText(DevIn, Z(DevHist[DevHistPos]))
            Else Dummy := WinSetWindowText(DevIn, Z(''));
            Dummy := WinSendMsg(DevIn, EM_SETSEL, 255 Shl 16 Or 255, 0);
          End
          Else If Vk = VK_UP Then
          Begin
            Dec(DevTop[DevTab]);
            DevRedraw;
          End
          Else If Vk = VK_DOWN Then
          Begin
            Inc(DevTop[DevTab]);
            DevRedraw;
          End
          Else If Vk = VK_F1 + 11 Then DevShow(False)
          Else DevProc := WinSendMsg(Client, Msg, Mp1, Mp2);
        End
        Else DevProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_SIZE :
      Begin
        If DevSb <> 0 Then
          Dummy := WinSetWindowPos(DevSb, 0, Lo16(Mp2) - SCW, 2, SCW, MaxI(10, Hi16(Mp2) - DEV_TABH - 4), SWP_MOVE Or SWP_SIZE);
        DevPlaceInput;
      End;
  Else
    DevProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Procedure DevCreate;
Begin
  If DevWin <> 0 Then Exit;
  DevWin := WinCreateWindow(Client, Z('WEBDEV'), 0, 0, 0, 0, 100, 100, Client, HWND_TOP, 30, 0, 0);
  If DevWin = 0 Then Exit;
  DevIn := WinCreateWindow(DevWin, WC_ENTRYFIELD, 0, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN, 0, 0, 100, 18,
                           DevWin, HWND_TOP, ID_DEVIN, 0, 0);
  Dummy := WinSendMsg(DevIn, EM_SETTEXTLIMIT, 250, 0);
  DevSb := WinCreateWindow(DevWin, WC_SCROLLBAR, 0, WS_VISIBLE Or SBS_VERT, 0, 0, SCW, 100, DevWin, HWND_TOP,
                           ID_DEVSB, 0, 0);
End;

{ ==================================================================== }
{ Fenetre principale                                                    }
{ ==================================================================== }

Procedure LayoutChildren;
Var Rc : Array[0..3] Of LongInt;
Begin
  Dummy := WinQueryWindowRect(Client, LongInt(@Rc));
  CW := Rc[2]; CH := Rc[3];
  VW := MaxI(40, CW - SCW - 4); VH := MaxI(40, CH - TBH - ADH - SBH - 2);
  { outils de developpement : panneau sous la page (1/3 de la hauteur) }
  DevH := 0;
  If DevOpen And (DevWin <> 0) Then
  Begin
    DevH := MinI(300, MaxI(170, CH Div 3));
    If VH - DevH < 60 Then DevH := MaxI(0, VH - 60);
    VH := VH - DevH;
    Dummy := WinSetWindowPos(DevWin, 0, 2, SBH, CW - 4, DevH, SWP_MOVE Or SWP_SIZE Or SWP_SHOW);
  End;
  Dummy := WinSetWindowPos(UrlEf, 0, 84, CH - TBH - ADH + 6, MaxI(60, CW - 84 - 76), 18, SWP_MOVE Or SWP_SIZE);
  Dummy := WinSetWindowPos(GoBtn, 0, CW - 68, CH - TBH - ADH + 3, 62, 24, SWP_MOVE Or SWP_SIZE);
  Dummy := WinSetWindowPos(View, 0, 2, SBH + DevH, VW, VH, SWP_MOVE Or SWP_SIZE);
  Dummy := WinSetWindowPos(VScroll, 0, 2 + VW, SBH + DevH, SCW, VH, SWP_MOVE Or SWP_SIZE);
End;

Procedure CheckItem(Id : LongInt; On : Boolean);
Begin
  If MenuHw = 0 Then Exit;
  If On Then Dummy := WinSendMsg(MenuHw, MM_SETITEMATTR, Id Or (1 Shl 16), MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(MenuHw, MM_SETITEMATTR, Id Or (1 Shl 16), MIA_CHECKED);
End;

Procedure GoTyped;
Var S : String;
Begin
  Dummy := WinQueryWindowText(UrlEf, 250, LongInt(@TxtBuf));
  S := TrimS(GetZ(LongInt(@TxtBuf)));
  If S <> '' Then
  Begin
    Navigate(S, '', True);
    Dummy := WinSetFocus(HWND_DESKTOP, View);
  End;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_OPENURL : OpenInput(DM_URL, 'Ouvrir une adresse', 'Adresse de la page (http://..., file:///C:/..., about:home) :', CurUrl);
    CM_OPENFILE : OpenInput(DM_FILE, 'Ouvrir un fichier', 'Fichier HTML (exemple : C:\PAGE.HTM) :', 'C:\');
    CM_SAVE : OpenInput(DM_SAVE, 'Enregistrer sous...', 'Nom du fichier (la page telle que re' + Chr(135) + 'ue) :', DefaultSaveName);
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_BACK : GoBack;
    CM_FORWARD : GoForward;
    CM_RELOAD : If CurUrl <> '' Then Navigate(CurUrl, '', False);
    CM_STOP : StopLoading;
    CM_HOME : Navigate(HomeUrl, '', True);
    CM_SOURCE :
      { va et vient entre la page et son code source (view-source:) }
      If StartsWith(CurUrl, 'view-source:') Then Navigate(Copy(CurUrl, 13, 255), '', True)
      Else If CurUrl <> '' Then Navigate('view-source:' + CurUrl, '', True);
    CM_IMAGES :
      Begin
        LoadImages := Not LoadImages;
        CheckItem(CM_IMAGES, LoadImages);
        If LoadImages Then PrfPut('BROWSER', 'IMAGES', '') Else PrfPut('BROWSER', 'IMAGES', '0');
        If LoadImages And (FBusy = 0) Then
        Begin
          ImgNext := 0;
          NextImage;
        End;
      End;
    CM_QR :
      If StartsWith(CurUrl, 'view-source:') Then OpenQr(Copy(CurUrl, 13, 255), DocTitle)
      Else OpenQr(CurUrl, DocTitle);
    CM_OPENLINK : If CtxLink <> '' Then Navigate(CtxLink, '', True);
    CM_DEVTOOLS :
      Begin
        DevCreate;
        DevShow(Not DevOpen);
      End;
    CM_INSPECT :
      Begin
        { "Inspecter" du menu contextuel : l'element sous le pointeur }
        DevCreate;
        DevShow(True);
        DevPicked(CtxElem);
      End;
    CM_QRLINK : If CtxLink <> '' Then OpenQr(CtxLink, CtxLink);
    CM_COPYLINK :
      { presse-papiers d'OS/2, format texte (CF_TEXT = 1), copie par PMWIN }
      If (CtxLink <> '') And (WinOpenClipbrd(Hab) <> 0) Then
      Begin
        Dummy := WinEmptyClipbrd(Hab);
        Dummy := WinSetClipbrdData(Hab, Z(CtxLink), 1, $400);
        Dummy := WinCloseClipbrd(Hab);
        SetStatus('Adresse copi' + Chr(130) + 'e : ' + CtxLink);
      End;
    CM_ADDMARK : AddMark;
    CM_MARKS : OpenList(DM_MARKS, 'Signets');
    CM_HIST0 : OpenList(DM_HIST, 'Historique');
    CM_SETHOME :
      Begin
        PrfPut('BROWSER', 'ACCUEIL', CurUrl);
        SetStatus('Page d''accueil : ' + CurUrl);
      End;
    CM_PROXY :
      OpenInput(DM_PROXY, 'Proxy HTTP', 'Proxy (hote:port, vide : connexion directe ; necessaire pour https://) :',
                PrfStr('BROWSER', 'PROXY'));
    CM_HELP :
      ShowMsg('Tapez une adresse puis Entree. Liens : clic ; Precedent / Suivant : Alt+fleches ; Actualiser : F5 ; ' +
              'Arreter : Echap ; defilement : fleches, Pg.prec., Pg.suiv., barre d''espacement. Formulaires : cliquez ' +
              'un champ pour y taper, Entree l''envoie ; listes : clic (suivant), Maj+clic (precedent).',
              'Navigateur Web - Aide', MB_OK Or MB_INFORMATION);
    CM_ABOUT :
      ShowMsg('Navigateur Web d''OS/2-0 : adaptation pour Presentation Manager du navigateur BROWSER.PAS de ' +
              'DEV-COOLS (HTML, feuilles de style, images GIF, PNG, JPEG et BMP, formulaires, signets). ' +
              'Programme ecrit en Pascal et compile par OS2PC.', 'A propos du Navigateur Web', MB_OK Or MB_INFORMATION);
  End;
  UpdateButtons;
End;

Procedure ToolPress(K : LongInt);
Begin
  If Not BtnEnabled(K) Then Exit;
  Case K Of
    BT_BACK : Command(CM_BACK);
    BT_FWD : Command(CM_FORWARD);
    BT_STOP : Command(CM_STOP);
    BT_RELOAD : Command(CM_RELOAD);
    BT_HOME : Command(CM_HOME);
    BT_MARK : Command(CM_ADDMARK);
    BT_SRC : Command(CM_SOURCE);
  End;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk, K, Cmd : LongInt;
Begin
  MainProc := 0;
  Case Msg Of
    WM_SIZE :
      If View <> 0 Then
      Begin
        K := VW;
        LayoutChildren;
        If K <> VW Then Relayout Else UpdateScroll;
      End;
    WM_PAINT : PaintClient(H);
    WM_CONTROL :
      { champ Adresse : tout son texte est selectionne quand il recoit le
        focus (la frappe remplace l'adresse) ; poste pour passer apres le clic }
      If (Lo16(Mp1) = ID_URL) And (Hi16(Mp1) = EN_SETFOCUS) Then
        Dummy := WinPostMsg(UrlEf, EM_SETSEL, 255 Shl 16, 0);
    WM_TIMER : If Lo16(Mp1) = 1 Then TimerTick;
    WM_COMMAND :
      Begin
        If Lo16(Mp1) = ID_GO Then GoTyped Else Command(Lo16(Mp1));
      End;
    WM_VSCROLL :
      Begin
        Cmd := Hi16(Mp2);
        Case Cmd Of
          SB_LINEUP : ScrollTo(ScrollY - 32);
          SB_LINEDOWN : ScrollTo(ScrollY + 32);
          SB_PAGEUP : ScrollTo(ScrollY - VH + 24);
          SB_PAGEDOWN : ScrollTo(ScrollY + VH - 24);
          SB_SLIDERTRACK, SB_SLIDERPOSITION : ScrollTo(S16(Mp2) * 16);
        End;
      End;
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinDefWindowProc(H, Msg, Mp1, Mp2);
        BtnDown := BtnAt(S16(Mp1), S16(Mp1 Shr 16));
        BtnHover := BtnDown;
        If BtnDown >= 0 Then RedrawToolbar;
        MainProc := 1;
      End;
    WM_BUTTON1UP :
      Begin
        K := BtnAt(S16(Mp1), S16(Mp1 Shr 16));
        If (BtnDown >= 0) And (K = BtnDown) Then
        Begin
          BtnDown := -1;
          ToolPress(K);
        End;
        BtnDown := -1;
        RedrawToolbar;
        MainProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        K := BtnAt(S16(Mp1), S16(Mp1 Shr 16));
        If K <> BtnHover Then
        Begin
          BtnHover := K;
          If K >= 0 Then SetStatus(BtnHint(K));
          If BtnDown >= 0 Then RedrawToolbar;
        End;
        MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) Then
        Begin
          If (Vk = VK_ENTER) Or (Vk = VK_NEWLINE) Then GoTyped
          Else If Vk = VK_F5 Then Command(CM_RELOAD)
          Else If Vk = VK_ESC Then Command(CM_STOP)
          Else If (Vk = VK_LEFT) And ((Fl And KC_ALT) <> 0) Then Command(CM_BACK)
          Else If (Vk = VK_RIGHT) And ((Fl And KC_ALT) <> 0) Then Command(CM_FORWARD)
          Else If Vk = VK_F1 Then Command(CM_HELP)
          Else If Vk = VK_F1 + 11 Then Command(CM_DEVTOOLS)
          Else If (Vk = VK_F1 + 9) And ((Fl And KC_SHIFT) <> 0) Then ShowContext(VW Div 2, VH Div 2)
          Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
        End
        Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_CTRL) <> 0) And ((Fl And KC_CHAR) <> 0) And
                ((Lo16(Mp2) And $DF) = Ord('U')) Then Command(CM_SOURCE)
        Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE :
      Begin
        StopLoading;
        CloseDlg;
        Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
      End;
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ --- menu (gabarit MENUTEMPLATE) --- }

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
  MenuT[H] := (MenuLen - H) And 255; MenuT[H + 1] := ((MenuLen - H) Shr 8) And 255;
  MenuT[H + 4] := Count And 255; MenuT[H + 5] := 0;
End;

Procedure MItem(Style, Id : LongInt; S : String);
Var K : LongInt;
Begin
  MW(Style); MW(0); MW(Id);
  If (Style And MIS_SEPARATOR) = 0 Then
  Begin
    For K := 1 To Length(S) Do MB(Ord(S[K]));
    MB(0);
  End;
End;

Procedure BuildMenu;
Var H0, H1 : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 100, '~Fichier');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_OPENURL, '~Ouvrir une adresse...');
  MItem(MIS_TEXT, CM_OPENFILE, 'Ouvrir un ~fichier...');
  MItem(MIS_TEXT, CM_SAVE, '~Enregistrer la page sous...');
  MItem(MIS_SEPARATOR, 0, '');
  MItem(MIS_TEXT, CM_QUIT, '~Quitter');
  MenuClose(H1, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 110, '~Affichage');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_RELOAD, '~Actualiser' + Chr(9) + 'F5');
  MItem(MIS_TEXT, CM_STOP, 'A~rr' + Chr(136) + 'ter' + Chr(9) + Chr(144) + 'chap');
  MItem(MIS_SEPARATOR, 0, '');
  MItem(MIS_TEXT, CM_SOURCE, '~Source de la page');
  MItem(MIS_TEXT, CM_IMAGES, '~Charger les images');
  MItem(MIS_SEPARATOR, 0, '');
  MItem(MIS_TEXT, CM_DEVTOOLS, '~Outils de d' + Chr(130) + 'veloppement' + Chr(9) + 'F12');
  MenuClose(H1, 7);
  MItem(MIS_TEXT Or MIS_SUBMENU, 120, 'A~ller');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_BACK, '~Pr' + Chr(130) + 'c' + Chr(130) + 'dent' + Chr(9) + 'Alt+Gauche');
  MItem(MIS_TEXT, CM_FORWARD, '~Suivant' + Chr(9) + 'Alt+Droite');
  MItem(MIS_TEXT, CM_HOME, 'Page d''~accueil');
  MItem(MIS_SEPARATOR, 0, '');
  MItem(MIS_TEXT, CM_HIST0, '~Historique...');
  MenuClose(H1, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 130, '~Signets');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_ADDMARK, '~Ajouter cette page');
  MItem(MIS_TEXT, CM_MARKS, '~G' + Chr(130) + 'rer les signets...');
  MenuClose(H1, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 140, '~Options');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_SETHOME, '~D' + Chr(130) + 'finir comme page d''accueil');
  MItem(MIS_TEXT, CM_PROXY, '~Proxy...');
  MenuClose(H1, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 150, 'A~ide');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_HELP, '~Utilisation' + Chr(9) + 'F1');
  MItem(MIS_SEPARATOR, 0, '');
  MItem(MIS_TEXT, CM_ABOUT, '~A propos du Navigateur Web');
  MenuClose(H1, 3);
  MenuClose(H0, 6);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

{ --- menu contextuel de la page (clic du bouton 2, Maj+F10) --- }

Procedure MItemA(Id : LongInt; Dis : Boolean; S : String);
Var K : LongInt;
Begin
  MW(MIS_TEXT);
  If Dis Then MW(MIA_DISABLED) Else MW(0);
  MW(Id);
  For K := 1 To Length(S) Do MB(Ord(S[K]));
  MB(0);
End;

Procedure ShowContext(X, Y : LongInt);
Var H0, N : LongInt; O : POp; Src : Boolean;
Begin
  O := HitOp(X, Y);
  CtxLink := '';
  CtxElem := Nil;
  If O <> Nil Then CtxElem := O^.Elem;
  If (O <> Nil) And (O^.Link <> 0) Then CtxLink := LinkUrl(O^.Link);
  If StartsWith(CtxLink, 'javascript:') Or StartsWith(CtxLink, 'mailto:') Then CtxLink := '';
  Src := StartsWith(CurUrl, 'view-source:');
  MenuLen := 0;
  H0 := MenuOpen;
  N := 0;
  If CtxLink <> '' Then
  Begin
    MItemA(CM_OPENLINK, False, 'Ouvrir le ~lien');
    MItemA(CM_QRLINK, False, 'Code QR du l~ien');
    MItemA(CM_COPYLINK, False, 'Copier l''~adresse du lien');
    MItem(MIS_SEPARATOR, 0, '');
    N := N + 4;
  End;
  MItemA(CM_BACK, HistPos <= 0, '~Pr' + Chr(130) + 'c' + Chr(130) + 'dent' + Chr(9) + 'Alt+Gauche');
  MItemA(CM_FORWARD, HistPos >= HistLen - 1, '~Suivant' + Chr(9) + 'Alt+Droite');
  MItemA(CM_RELOAD, CurUrl = '', '~Actualiser' + Chr(9) + 'F5');
  MItem(MIS_SEPARATOR, 0, '');
  If Src Then MItemA(CM_SOURCE, False, 'Voir la ~page' + Chr(9) + 'Ctrl+U')
  Else MItemA(CM_SOURCE, CurUrl = '', 'Voir le ~code source' + Chr(9) + 'Ctrl+U');
  MItem(MIS_SEPARATOR, 0, '');
  MItemA(CM_SAVE, RawLen + SrcLen = 0, '~Enregistrer sous...');
  MItemA(CM_QR, CurUrl = '', 'Cr' + Chr(130) + 'er un code ~QR pour cette page');
  MItem(MIS_SEPARATOR, 0, '');
  MItemA(CM_INSPECT, False, '~Inspecter' + Chr(9) + 'F12');
  N := N + 10;
  MenuClose(H0, N);
  If CtxMenu <> 0 Then Dummy := WinDestroyWindow(CtxMenu);
  CtxMenu := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuT));
  If CtxMenu <> 0 Then Dummy := WinPopupMenu(View, Client, CtxMenu, X, Y, 0, 0);
End;

Var
  Fl, Sw, Sh, Ww, Wh, K : LongInt;
  StartUrl : String;

BEGIN
  TraceOn := 0;
  ArenaInit; LaInit;
  SrcBuf := 0; ImgBuf := 0;
  Dummy := DosAllocMem(LongInt(@SrcBuf), SRC_MAX + 16, $13);
  Dummy := DosAllocMem(LongInt(@ImgBuf), SRC_MAX + 16, $13);
  RawBuf := 0; RawLen := 0; QrFr := 0; QrCl := 0; CtxMenu := 0; CtxLink := '';
  Dummy := DosAllocMem(LongInt(@RawBuf), SRC_MAX + 16, $13);
  JsStk := 0; JsSp := 0; JsConN := 0; JsConFirst := 0; JsRand := 0; NetN := 0; LoadingRes := 0; HoverElem := Nil;
  JsPendingOnload := False;
  Dummy := DosAllocMem(LongInt(@JsStk), JS_STKMAX * SizeOf(TJV) + 16, $13);
  SrcLen := 0; ImgLen := 0;
  FBusy := 0; FDone := 0; FAbort := 0; NetReady := 0;
  Root := Nil; OpFirst := Nil; OpLast := Nil; PageH := 0; ScrollY := 0; LayGen := 0;
  PageBg := $FFFFFF; PageFg := 0; LinkFg := $0000EE;
  HistPos := 0; HistLen := 0; HistMove := 0;
  Pending := 0; LoadingPage := 0; LoadingImg := 0; TimerOn := 0; NeedLayout := 0; RefreshTick := 0; SigN := -1;
  BtnDown := -1; BtnHover := -1; StatusText := ''; LinkHover := ''; CurUrl := '';
  DlgFr := 0; DlgCl := 0; DlgEf := 0; DlgLb := 0; MenuHw := 0;
  NImgs := 0; NCtls := 0; NForms := 0; FocusCtl := -1; ViewSource := False; Plain := False; PlainText := False; SrcMode := False;
  LoadImages := PrfStr('BROWSER', 'IMAGES') <> '0';
  ProxyLoad;
  If (SrcBuf = 0) Or (ImgBuf = 0) Or (ArBase = 0) Or (LaBase = 0) Then
  Begin
    Writeln('BROWSER : memoire insuffisante.');
    Halt(1);
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  Dummy := WinRegisterClass(Hab, Z('WEBMAIN'), LongInt(@MainProc), WS_CLIPCHILDREN, 0);
  Dummy := WinRegisterClass(Hab, Z('WEBVIEW'), LongInt(@ViewProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('WEBINPUT'), LongInt(@InputProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('WEBLIST'), LongInt(@ListProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('WEBQR'), LongInt(@QrProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('WEBDEV'), LongInt(@DevProc), WS_CLIPCHILDREN, 0);
  DevOpen := False; DevPick := False; DevWin := 0; DevIn := 0; DevSb := 0; DevH := 0; DevTab := DT_INSP;
  DevSel := Nil; DevColN := 0; DevSrcSel := 0; DevScrSel := 0; DevEditLine := -1; DevHistN := 0; DevHistPos := 0;
  DevNetSel := -1; CtxElem := Nil; B2Down := False;
  For K := 1 To 5 Do DevTop[K] := 0;
  for K := 0 To NBTN Do BtnIcon[K] := MakeIcon(K);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('WEBMAIN'), Z2('Navigateur Web d''OS/2-0'), 0, 0, 0,
                              LongInt(@Client));
  BuildMenu;
  CheckItem(CM_IMAGES, LoadImages);
  UrlEf := WinCreateWindow(Client, WC_ENTRYFIELD, 0, WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
                           84, 0, 300, 18, Client, HWND_TOP, ID_URL, 0, 0);
  Dummy := WinSendMsg(UrlEf, EM_SETTEXTLIMIT, 250, 0);
  GoBtn := WinCreateWindow(Client, WC_BUTTON, Z('Aller'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                           0, 0, 62, 24, Client, HWND_TOP, ID_GO, 0, 0);
  View := WinCreateWindow(Client, Z('WEBVIEW'), 0, WS_VISIBLE, 0, 0, 100, 100, Client, HWND_TOP, ID_VIEW, 0, 0);
  VScroll := WinCreateWindow(Client, WC_SCROLLBAR, 0, WS_VISIBLE Or SBS_VERT, 0, 0, SCW, 100, Client, HWND_TOP,
                             ID_VSCROLL, 0, 0);
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Ww := MinI(Sw, 760); Wh := MinI(Sh - 20, 560);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - Ww) Div 2), MaxI(0, (Sh - Wh) Div 2), Ww, Wh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  LayoutChildren;
  StartUrl := '';
  If ParamCount > 0 Then StartUrl := ParamStr(1);
  If StartUrl = '' Then StartUrl := HomeUrl;
  Navigate(StartUrl, '', True);
  { page d'accueil : on tape d'abord une adresse ; sinon la page a le focus }
  If ParamCount > 0 Then Dummy := WinSetFocus(HWND_DESKTOP, View)
  Else Dummy := WinSetFocus(HWND_DESKTOP, UrlEf);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
