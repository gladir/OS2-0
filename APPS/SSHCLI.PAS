{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: SSHCLI - Client SSH d'OS/2-0 (Presentation Manager),
  porte du Client SSH de Pasdows 95 (APPS/SSHCLI.PAS, Win32), dans le
  genre de MobaXterm.
}

Program SSHCLI;

{$R-,S-,I-}

{ Compilation : OS2PC APPS\SSHCLI.PAS SSHCLI.EXE

  Bureau, dossier Outils reseau, Client SSH.
  - SSH-2 (echange de cles curve25519-sha256, cles d'hote ssh-ed25519,
    rsa-sha2-512 et rsa-sha2-256 verifiees, aes128-ctr, hmac-sha2-256,
    "kex strict", mot de passe ou clavier interactif) ; pseudo-terminal
    xterm, shell ou commande, changement de taille, maintien de la
    connexion, code de sortie (exit-status) affiche a la fin.
  - Terminal xterm : couleurs (16, 256 et RVB ramenees a 16), UTF-8
    affiche avec la police de l'ecran (page 437, cadres), graphismes DEC,
    region de defilement, ecran alternatif (vi, less, top, mc), historique,
    selection a la souris, copier, coller.
  - Fenetre de MobaXterm : barre d'outils a grandes icones, panneau de
    gauche a quatre onglets (Sessions, Outils, Macros, SFTP), onglets des
    sessions (accueil, 8 sessions au plus, MultiExec), menus deroulants et
    contextuels, barre d'etat.
  - Sessions enregistrees dans sessions.xml (dossiers, mot de passe
    facultatif en base64), connexion rapide (utilisateur@serveur:port),
    macros (macros.xml), parametres (settings.xml), cles d'hote connues
    (knownhosts.txt, commun avec le Client FTP). Ces fichiers sont dans
    C:\RESEAU\ (cree au besoin), ou D:\RESEAU\ si C: n'est pas inscriptible
    (demarrage depuis le CD-ROM).
  - Navigateur SFTP de la session active (seconde connexion SSH) :
    telecharger, envoyer, creer, renommer, supprimer.

  Portage vers l'API d'OS/2 (OS/2-0) :
  - fenetres et messages de Presentation Manager (PMWIN) : cadre standard
    a bordure de taille et liste des taches, fenetres enfants (panneau,
    listes, terminal) de classes enregistrees, controles natifs de PM
    (WC_ENTRYFIELD, WC_BUTTON, WC_STATIC, WC_LISTBOX, WC_SCROLLBAR),
    minuterie (WinStartTimer), barre de menus et menus contextuels faits
    de modeles de menus (WinCreateMenu, WinPopupMenu), boites de message
    (WinMessageBox), presse-papiers (WinOpenClipbrd, WinSetClipbrdData,
    WinQueryClipbrdData, CF_TEXT) ;
  - dessin par GPI (PMGPI) en couleurs RVB (GpiCreateLogColorTable),
    coordonnees de PM (origine en bas a gauche) : la couche de dessin
    retourne les ordonnees ; police de l'ecran 8 x 16 pour le terminal,
    ramenee a 6 x 16 (GpiSetCharBox) pour les petits textes de la fenetre ;
  - boites Ouvrir et Enregistrer faites de controles de PM (WinFileDlg de
    PMCTLS n'est pas disponible) ;
  - une tache par session et par navigateur SFTP (DosCreateThread) ; le
    verrou est un semaphore d'exclusion de DOSCALLS (DosCreateMutexSem,
    DosRequestMutexSem, DosReleaseMutexSem) qui echange les variables SSH
    de la tache qui le prend (variables par tache emulees par une table
    des identificateurs de taches : DosGetInfoBlocks) ; le navigateur SFTP
    attend ses commandes sur un semaphore d'evenement (DosCreateEventSem,
    DosWaitEventSem, DosPostEventSem) ; les taches reseau ne parlent a
    l'interface que par WinPostMsg (la question sur une cle d'hote
    inconnue est posee par la tache de l'interface) ;
  - reseau : TCPIP32.DLL (sock_init, gethostbyname, socket, connect, send,
    recv, select, shutdown, soclose) ; fichiers : DosOpen, DosRead,
    DosWrite, DosClose, DosFindFirst, DosCreateDir ; heure : DosGetDateTime,
    DosQuerySysInfo (QSV_MS_COUNT) ;
  - outils : programmes d'OS/2-0 lances par DosExecPgm (Bloc-notes,
    Calculatrice, Explorateur OS2-Zero, Gestionnaire des taches,
    Gestionnaire de peripheriques, Client FTP, Navigateur Web), l'Invite de
    commandes dans sa propre session ; Table ASCII et generateur de mots de
    passe integres. }

Const
  { messages de PM }
  WM_CREATE = $0001; WM_SIZE = $0007; WM_SETFOCUS = $000F; WM_COMMAND = $0020;
  WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_CONTROL = $0030; WM_VSCROLL = $0031; WM_ERASEBACKGROUND = $004F;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072;
  WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074; WM_BUTTON2UP = $0075;
  WM_BUTTON3DOWN = $0077; WM_CHAR = $007A; WM_USER = $1000;
  { evenements des procedures de l'interface (numeros de Pasdows ; les
    procedures de PM les traduisent : coordonnees vers le bas, touches) }
  EvDestroy = $0002; EvSize = $0005; EvSetFocus = $0007; EvKillFocus = $0008;
  EvPaint = $000F; EvClose = $0010; EvErase = $0014;
  EvKeyDown = $0100; EvChar = $0102; EvCommand = $0111; EvTimer = $0113;
  EvVScroll = $0115; EvMove = $0200; EvLDown = $0201; EvLUp = $0202;
  EvLDbl = $0203; EvRDown = $0204; EvMDown = $0207; EvWheel = $020A;
  EvTermData = WM_USER + 1;            { donnees recues (WP : session) }
  EvSessState = WM_USER + 2;           { etat d'une session }
  EvSftpList = WM_USER + 3;            { liste SFTP arrivee }
  EvSftpState = WM_USER + 4;           { etat ou progression SFTP }
  EvHostAsk = WM_USER + 5;             { cle d'hote : question posee ici }
  EvMenus = WM_USER + 6;               { menus a refaire }
  NoProc = $7FFF5A5A;                  { evenement non traite }
  { fenetres }
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10;
  FCF_MAXBUTTON = $20; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3; QW_PARENT = 5;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  WS_VISIBLE = $80000000; WS_CLIPCHILDREN = $20000000; WS_GROUP = $00010000;
  WS_TABSTOP = $00020000;
  WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006;
  WC_LISTBOX = $FFFF0007; WC_SCROLLBAR = $FFFF0008;
  BS_PUSHBUTTON = 0; BS_AUTOCHECKBOX = 2; BS_AUTORADIOBUTTON = 4; BS_DEFAULT = $0400;
  SS_TEXT = 1; SS_GROUPBOX = 2; DT_VCENTER = $0400;
  ES_AUTOSCROLL = 4; ES_MARGIN = 8; ES_READONLY = $20; ES_UNREADABLE = $80;
  SBS_VERT = 1;
  EM_SETSEL = $0142; EM_SETTEXTLIMIT = $0143;
  BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
  LM_INSERTITEM = $0161; LM_QUERYSELECTION = $0165; LM_DELETEALL = $016E;
  LN_SELECT = 1; LN_ENTER = 5;
  SBM_SETSCROLLBAR = $01A0; SBM_SETPOS = $01A1; SBM_SETTHUMBSIZE = $01A6;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  SV_CXSCREEN = 20; SV_CYSCREEN = 21;
  { boites de message (valeurs de PM) }
  MB_OK = 0; MB_OKCANCEL = 1; MB_YESNO = 4; MB_YESNOCANCEL = 5;
  MB_ICONQUESTION = $10; MB_ICONWARNING = $20; MB_ICONINFO = $30;
  MB_ICONERROR = $40; MB_MOVEABLE = $4000;
  IDOK = 1; IDCANCEL = 2; IDYES = 6; IDNO = 7;
  { clavier de PM }
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20;
  KC_KEYUP = $40;
  PVK_BACKSPACE = $05; PVK_TAB = $06; PVK_BACKTAB = $07; PVK_NEWLINE = $08;
  PVK_SHIFT = $09; PVK_CTRL = $0A; PVK_ESC = $0F; PVK_PAGEUP = $11;
  PVK_PAGEDOWN = $12; PVK_END = $13; PVK_HOME = $14; PVK_LEFT = $15;
  PVK_UP = $16; PVK_RIGHT = $17; PVK_DOWN = $18; PVK_INSERT = $1A;
  PVK_DELETE = $1B; PVK_ENTER = $1E; PVK_F1 = $20; PVK_F12 = $2B;
  { touches virtuelles des procedures (numeros de Pasdows) }
  VK_BACK = $08; VK_TAB = $09; VK_RETURN = $0D; VK_SHIFT = $10;
  VK_CONTROL = $11; VK_ESCAPE = $1B; VK_SPACE = $20; VK_PRIOR = $21;
  VK_NEXT = $22; VK_END = $23; VK_HOME = $24; VK_LEFT = $25; VK_UP = $26;
  VK_RIGHT = $27; VK_DOWN = $28; VK_INSERT = $2D; VK_DELETE = $2E;
  VK_F1 = $70; VK_F2 = $71; VK_F3 = $72; VK_F4 = $73; VK_F5 = $74;
  VK_F6 = $75; VK_F7 = $76; VK_F8 = $77; VK_F9 = $78; VK_F10 = $79;
  VK_F11 = $7A; VK_F12 = $7B;
  { couleurs (0BBGGRR, comme Pasdows ; converties en RVB au dessin) }
  ClrFace = $CCCCCC; ClrShadow = $808080; ClrHi = $FFFFFF; ClrDark = 0;
  ClrSel = $800000; ClrWin = $FFFFFF; ClrBlack = 0;
  ClrNavy = $800000; ClrGreen = $008000; ClrRed = $0000C0;
  ClrGray = $808080; ClrYellow = $00FFFF; ClrOlive = $008080;
  ClrMaroon = $000080; ClrBlue = $FF0000; ClrTeal = $808000;

Type
  PByt = ^Byte;
  PLng = ^LongInt;
  TlPtr = LongInt;

{ ---- DOSCALLS ---- }
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosQuerySysInfo(A, B, P, N : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetInfoBlocks(PPTib, PPPib : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flag, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateMutexSem(PName, PH, Attr, State : LongInt) : LongInt; External 'DOSCALLS';
Function DosRequestMutexSem(H, Timeout : LongInt) : LongInt; External 'DOSCALLS';
Function DosReleaseMutexSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateEventSem(PName, PH, Attr, State : LongInt) : LongInt; External 'DOSCALLS';
Function DosPostEventSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosWaitEventSem(H, Timeout : LongInt) : LongInt; External 'DOSCALLS';
Function DosResetEventSem(H, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosExit(Act, Code : LongInt) : LongInt; External 'DOSCALLS';
{ sessions d'OS/2-0 (comme l'Explorateur et le bureau) : l'Invite de
  commandes a son propre ecran }
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';
{ ---- TCPIP32 ---- }
Function sock_init : LongInt; External 'TCPIP32' Name 'sock_init';
Function socket(D, T, P : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function connect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function send(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function recv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function soclose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function shutdown(S, H : LongInt) : LongInt; External 'TCPIP32' Name 'shutdown';
Function gethostbyname(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
Function inet_addr(P : LongInt) : LongInt; External 'TCPIP32' Name 'inet_addr';
Function select(PS, NR, NW, NE, Tm : LongInt) : LongInt; External 'TCPIP32' Name 'select';
{ ---- PMWIN ---- }
Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinTerminate(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyMsgQueue(Hmq : LongInt) : LongInt; External 'PMWIN';
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
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt; External 'PMWIN';
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryFocus(HD : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinShowWindow(H, Sh : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindow(H, Cmd : LongInt) : LongInt; External 'PMWIN';
Function WinMapWindowPoints(HFrom, HTo, P, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetKeyState(HD, Vk : LongInt) : LongInt; External 'PMWIN';
{ ---- PMGPI ---- }
Function GpiCreateLogColorTable(Hps, Opt, Fmt, St, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiCharStringAt(Hps, PPt, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetCharBox(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetBackMix(Hps, M : LongInt) : LongInt; External 'PMGPI';

Var
  Dummy0 : LongInt;

Function TlGet(A : TlPtr) : LongInt;
Begin
  TlGet := PByt(A)^;
End;

Procedure TlPut(A : TlPtr; V : LongInt);
Begin
  PByt(A)^ := V And 255;
End;
{ ---- OS/2 : memoire, temps, fils (variables par fil) ---- }

Function TlNew(N : LongInt) : TlPtr;
Var P : LongInt;
Begin
  P := 0;
  { PAG_COMMIT Or PAG_READ Or PAG_WRITE ; pages neuves : a zero }
  If DosAllocMem(LongInt(@P), N, $13) <> 0 Then P := 0;
  TlNew := P;
End;

Function MsCount : LongInt;
Var V : LongInt;
Begin
  V := 0;
  Dummy0 := DosQuerySysInfo(14, 14, LongInt(@V), 4);   { QSV_MS_COUNT }
  MsCount := V;
End;

{ identificateur du fil courant (TIB2 de DosGetInfoBlocks) }
Function CurTid : LongInt;
Var Tib, Pib : LongInt;
Begin
  Tib := 0; Pib := 0;
  Dummy0 := DosGetInfoBlocks(LongInt(@Tib), LongInt(@Pib));
  If Tib = 0 Then CurTid := 1 Else CurTid := PLng(PLng(Tib + 12)^)^;
End;

{ valeurs par fil (TlsAlloc, TlsGetValue, TlsSetValue de Win32) }
Const
  MaxTlsT = 32;
Var
  TlsTid : Array[0..MaxTlsT - 1] Of LongInt;
  TlsVal : Array[0..MaxTlsT - 1] Of LongInt;

Function TlsGet(Idx : LongInt) : LongInt;
Var I, T : LongInt;
Begin
  TlsGet := 0;
  T := CurTid;
  For I := 0 To MaxTlsT - 1 Do
    If TlsTid[I] = T Then TlsGet := TlsVal[I];
End;

Procedure TlsSet(Idx, V : LongInt);
Var I, T, F : LongInt;
Begin
  T := CurTid;
  F := -1;
  For I := MaxTlsT - 1 DownTo 0 Do
    If (TlsTid[I] = T) Or ((F < 0) And (TlsTid[I] = 0)) Then F := I;
  For I := 0 To MaxTlsT - 1 Do
    If TlsTid[I] = T Then F := I;
  If F < 0 Then Exit;
  If V = 0 Then TlsTid[F] := 0 Else TlsTid[F] := T;
  TlsVal[F] := V;
End;
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
{ Protocole SSH-2 (RFC 4251 a 4254 : curve25519-sha256, ssh-ed25519 /   }
{ rsa-sha2-256 et rsa-sha2-512, aes128-ctr, hmac-sha2-256, mot de passe }
{ ou clavier interactif) et SFTP version 3. Les variables Ss*, Sh*, Sf* }
{ sont celles de la connexion de la tache courante : le verrou les      }
{ echange (CtxSave / CtxLoad) quand une autre tache prend la main.      }
{ Fonctions attendues de l'appelant : NetOpen, NetSend, NetRecv,        }
{ NetClose, LogMsg, Lf*, HostAsk, XferStep, KnownHost, SaveHost.        }
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
  ShTerm, ShEnded : Boolean;           { canal du terminal ; canal ferme }
  ShExit : LongInt;                    { code de sortie (exit-status) }
  { SFTP }
  SfBuf : TlPtr;                       { octets du canal pas encore lus }
  SfLen, SfId : LongInt;
  SfPk : TlPtr;                        { paquet SFTP recu (charge) }
  SfPkLen, SfStatus : LongInt;
  SfMsg : String;
  { file : progression }
  XfDone : Double;
  XfCancel : Boolean;
  XBuf, KxIc, KxIs : TlPtr;           { tampons de la connexion }

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
Procedure TermIn(A : TlPtr; N : LongInt); Forward;
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
      If ShTerm Then TermIn(P, N)
      Else If T = 94 Then
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
      { terminal : EOF puis exit-status puis CLOSE ; fin sur CLOSE }
      If ShTerm Then
      Begin
        If T = 97 Then
        Begin
          ShEnded := True;
          Exit;
        End;
      End
      Else
      Begin
        SsErr := 'Le serveur a ferm'#233' le canal SFTP.';
        Exit;
      End;
    End;
    98 :
    Begin
      R := RdU32; S := RdStr; A := RdByte;
      If S = 'exit-status' Then ShExit := RdU32;
      If A <> 0 Then
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

Function ShConnect(Sftp : Boolean) : Boolean;
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
  ShVc := 'SSH-2.0-PasdowsSSH_1.0';
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
  If Not Sftp Then
  Begin
    ShConnect := True;
    Exit;
  End;
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

{ ==================================================================== }
{ Connexions : contexte de chaque tache, terminal (pty + shell) et      }
{ operations SFTP du navigateur                                         }
{ ==================================================================== }

Type
  { variables d'une connexion SSH, echangees par le verrou : chaque
    tache reseau a la sienne (TlsGetValue), l'interface n'en a pas }
  TCtx = Record
    Owner : LongInt;                    { session (onglet) }
    Sock, Port : LongInt;
    Host, User, Pass, Cwd, Err : String;
    Open, Lost : Boolean;
    POut, PIn : TlPtr;
    InLen, Pos, OutLen : LongInt;
    Enc, Strict : Boolean;
    SeqC, SeqS : LongInt;
    AesC, AesS : TlAes;
    CtrC, CtrS : TlBlk;
    MacC, MacS, Sid : TlKey32;
    Vs : String;
    Chan, RWin, RMax, LWin : LongInt;
    Term, Ended : Boolean;
    ExitCode : LongInt;
    FBuf, FPk, QB, XB, KIc, KIs : TlPtr;
    FLen, FId, FPkLen, FStatus, QLen, SPos : LongInt;
    FMsg : String;
    XDone : Double;
    XCancel : Boolean;
  End;
  PCtx = ^TCtx;

Var
  TlsIdx : LongInt;

Procedure CtxSave(C : PCtx);
Begin
  C^.Sock := SsSock; C^.Port := SsPort;
  C^.Host := SsHost; C^.User := SsUser; C^.Pass := SsPass;
  C^.Cwd := SsCwd; C^.Err := SsErr;
  C^.Open := SsOpen; C^.Lost := SsLost;
  C^.POut := ShOut; C^.PIn := ShIn;
  C^.InLen := ShInLen; C^.Pos := ShPos; C^.OutLen := ShOutLen;
  C^.Enc := ShEnc; C^.Strict := ShStrict;
  C^.SeqC := ShSeqC; C^.SeqS := ShSeqS;
  C^.AesC := ShAesC; C^.AesS := ShAesS;
  C^.CtrC := ShCtrC; C^.CtrS := ShCtrS;
  C^.MacC := ShMacC; C^.MacS := ShMacS; C^.Sid := ShSid;
  C^.Vs := ShVs;
  C^.Chan := ShChan; C^.RWin := ShRWin; C^.RMax := ShRMax; C^.LWin := ShLWin;
  C^.Term := ShTerm; C^.Ended := ShEnded; C^.ExitCode := ShExit;
  C^.FBuf := SfBuf; C^.FPk := SfPk; C^.QB := SqB; C^.XB := XBuf;
  C^.KIc := KxIc; C^.KIs := KxIs;
  C^.FLen := SfLen; C^.FId := SfId; C^.FPkLen := SfPkLen;
  C^.FStatus := SfStatus; C^.QLen := SqLen; C^.SPos := SpPos;
  C^.FMsg := SfMsg;
  C^.XDone := XfDone; C^.XCancel := XfCancel;
End;

Procedure CtxLoad(C : PCtx);
Begin
  SsSock := C^.Sock; SsPort := C^.Port;
  SsHost := C^.Host; SsUser := C^.User; SsPass := C^.Pass;
  SsCwd := C^.Cwd; SsErr := C^.Err;
  SsOpen := C^.Open; SsLost := C^.Lost;
  ShOut := C^.POut; ShIn := C^.PIn;
  ShInLen := C^.InLen; ShPos := C^.Pos; ShOutLen := C^.OutLen;
  ShEnc := C^.Enc; ShStrict := C^.Strict;
  ShSeqC := C^.SeqC; ShSeqS := C^.SeqS;
  ShAesC := C^.AesC; ShAesS := C^.AesS;
  ShCtrC := C^.CtrC; ShCtrS := C^.CtrS;
  ShMacC := C^.MacC; ShMacS := C^.MacS; ShSid := C^.Sid;
  ShVs := C^.Vs;
  ShChan := C^.Chan; ShRWin := C^.RWin; ShRMax := C^.RMax; ShLWin := C^.LWin;
  ShTerm := C^.Term; ShEnded := C^.Ended; ShExit := C^.ExitCode;
  SfBuf := C^.FBuf; SfPk := C^.FPk; SqB := C^.QB; XBuf := C^.XB;
  KxIc := C^.KIc; KxIs := C^.KIs;
  SfLen := C^.FLen; SfId := C^.FId; SfPkLen := C^.FPkLen;
  SfStatus := C^.FStatus; SqLen := C^.QLen; SpPos := C^.SPos;
  SfMsg := C^.FMsg;
  XfDone := C^.XDone; XfCancel := C^.XCancel;
  SsProto := PrSftp;
End;

{ contexte neuf (les tampons deja alloues sont gardes) }
Procedure CtxReset(C : PCtx; Owner : LongInt);
Var O, I, Q, X, K1, K2, F1, F2 : TlPtr;
Begin
  O := C^.POut; I := C^.PIn; Q := C^.QB; X := C^.XB;
  K1 := C^.KIc; K2 := C^.KIs; F1 := C^.FBuf; F2 := C^.FPk;
  FillChar(C^, SizeOf(TCtx), 0);
  C^.POut := O; C^.PIn := I; C^.QB := Q; C^.XB := X;
  C^.KIc := K1; C^.KIs := K2; C^.FBuf := F1; C^.FPk := F2;
  C^.Owner := Owner; C^.Sock := -1;
End;

Function CurCtx : PCtx;
Begin
  CurCtx := PCtx(TlsGet(TlsIdx));
End;

{ ---- terminal ---- }

{ attend la reponse a une requete du canal (99 : succes, 100 : echec,
  0 : erreur) ; les donnees qui arrivent entre-temps vont au terminal }
Function ShReply : LongInt;
Var T, R, N : LongInt; P : TlPtr;
Begin
  Repeat
    T := PkRecv;
    Case T Of
      93 : Begin R := RdU32; ShRWin := ShRWin + RdU32; T := -1; End;
      94, 95 :
      Begin
        R := RdU32;
        If T = 95 Then R := RdU32;
        RdBin(P, N);
        TermIn(P, N);
        ShLWin := ShLWin - N;
        T := -1;
      End;
      96 : T := -1;
    End;
  Until T <> -1;
  ShReply := T;
End;

{ canal "session" avec pseudo-terminal xterm, puis shell (ou commande) }
Function ShShell(Cols, Rows : LongInt; TermName, Cmd : String) : Boolean;
Var T : LongInt;
Begin
  ShShell := False;
  ShTerm := True; ShEnded := False; ShExit := -1;
  ShLWin := 2097152;
  PkStart(90); PkStr('session'); PkU32(0); PkU32(ShLWin); PkU32(32768);
  If Not PkSend Then Exit;
  T := ShReply;
  If T <> 91 Then
  Begin
    If SsErr = '' Then SsErr := 'Ouverture du canal refus'#233'e.';
    Exit;
  End;
  T := RdU32; ShChan := RdU32; ShRWin := RdU32; ShRMax := RdU32;
  If ShRMax > 32768 Then ShRMax := 32768;
  { pty-req : terminal, taille, modes (VERASE = 127, fin) }
  PkStart(98); PkU32(ShChan); PkStr('pty-req'); PkByte(1);
  PkStr(TermName); PkU32(Cols); PkU32(Rows); PkU32(Cols * 8);
  PkU32(Rows * 16);
  PkU32(6); PkByte(3); PkU32(127); PkByte(0);
  If Not PkSend Then Exit;
  T := ShReply;
  If T = 0 Then Exit;
  If T <> 99 Then LogMsg(LgError, 'Le serveur refuse le pseudo-terminal.');
  PkStart(98); PkU32(ShChan);
  If Cmd = '' Then
  Begin
    PkStr('shell'); PkByte(1);
  End
  Else
  Begin
    PkStr('exec'); PkByte(1); PkStr(AToU8(Cmd));
  End;
  If Not PkSend Then Exit;
  T := ShReply;
  If T <> 99 Then
  Begin
    If SsErr = '' Then SsErr := 'Le serveur refuse d''ouvrir le shell.';
    Exit;
  End;
  ShShell := True;
End;

Function ShWinChange(Cols, Rows : LongInt) : Boolean;
Begin
  PkStart(98); PkU32(ShChan); PkStr('window-change'); PkByte(0);
  PkU32(Cols); PkU32(Rows); PkU32(Cols * 8); PkU32(Rows * 16);
  ShWinChange := PkSend;
End;

{ maintien de la connexion (SSH_MSG_IGNORE) }
Function ShKeepAlive : Boolean;
Begin
  PkStart(2); PkStr('');
  ShKeepAlive := PkSend;
End;

Procedure ShEof;
Begin
  PkStart(97); PkU32(ShChan);
  If PkSend Then;
End;

{ ---- connexion ---- }

Procedure SsClose;
Begin
  If SsSock >= 0 Then
  Begin
    If SsOpen And Not SsLost Then
    Begin
      PkStart(1); PkU32(11); PkStr('Fermeture'); PkStr('');
      If PkSend Then;
    End;
    NetClose(SsSock);
  End;
  SsSock := -1;
  SsOpen := False;
End;

Function SsConnect(Sftp : Boolean) : Boolean;
Var E : String;
Begin
  SsConnect := False;
  SsErr := ''; SsLost := False; SsProto := PrSftp;
  LogMsg(LgStatus, 'R'#233'solution de l''adresse de ' + SsHost + '...');
  SsSock := NetOpen(SsHost, SsPort, E);
  If SsSock < 0 Then
  Begin
    SsErr := E;
    Exit;
  End;
  LogMsg(LgStatus, 'Connexion '#233'tablie avec ' + SsHost + ':' +
         IStr(SsPort) + '...');
  SsOpen := ShConnect(Sftp);
  If Not SsOpen Then
  Begin
    NetClose(SsSock); SsSock := -1;
    Exit;
  End;
  SsConnect := True;
End;

{ ---- SFTP (navigateur) ---- }

Function SsCd(P : String) : Boolean;
Var R : String; H : THnd;
Begin
  SsCd := False;
  SsErr := '';
  If (P <> '') And (P[1] <> '/') Then P := RJoin(SsCwd, P);
  If Not SfRealPath(P, R) Then Exit;
  SqStart(11, True); SqStr(AToU8(R));
  If Not SqSend Then Exit;
  If Not SfHandle('Dossier ' + R, H) Then Exit;
  SqStart(4, True); SqHnd(H);
  If Not SqSend Then Exit;
  If Not SfOk('Fermeture') Then Exit;
  SsCwd := R;
  SsCd := True;
End;

{ Op : 1 creer un dossier, 2 supprimer un dossier, 3 supprimer un fichier }
Function SsOp(Op : LongInt; P : String) : Boolean;
Begin
  SsOp := False;
  SsErr := '';
  Case Op Of
    1 : Begin SqStart(14, True); SqStr(AToU8(P)); SqU32(0); End;
    2 : Begin SqStart(15, True); SqStr(AToU8(P)); End;
  Else
    Begin SqStart(13, True); SqStr(AToU8(P)); End;
  End;
  If Not SqSend Then Exit;
  If Not SfOk(P) Then Exit;
  SsOp := True;
End;

Function SsRename(A, B : String) : Boolean;
Begin
  SsRename := False;
  SsErr := '';
  SqStart(18, True); SqStr(AToU8(A)); SqStr(AToU8(B));
  If Not SqSend Then Exit;
  If Not SfOk(A) Then Exit;
  SsRename := True;
End;

Function SsGet(Rem, Loc : String) : Boolean;
Begin
  SsErr := '';
  XfCancel := False;
  SsGet := SfXfer(Rem, Loc, True);
End;

Function SsPut(Loc, Rem : String) : Boolean;
Begin
  SsErr := '';
  XfCancel := False;
  SsPut := SfXfer(Rem, Loc, False);
End;
{ ==================================================================== }
{ Reseau (TCPIP32.DLL d'OS/2-0) et fichiers locaux (DOSCALLS.DLL)        }
{ Les appels bloquants liberent le verrou de l'interface (BigUnlock).   }
{ ==================================================================== }

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

{ entropie : compteur de millisecondes, date et heure, compteur de la
  minuterie }
Procedure TlEntropy;
Var D : Array[0..3] Of LongInt;
Begin
  D[0] := 0; D[1] := 0; D[2] := 0;
  Dummy0 := DosGetDateTime(LongInt(@D[0]));
  TlSeed(D[0]); TlSeed(D[1]); TlSeed(MsCount); TlSeed(CurTid);
End;

{ socket connecte (sock_init, gethostbyname, socket, connect) ; -1 }
Function NetOpen(Host : String; Port : LongInt; Var Err : String) : LongInt;
Var A : Array[0..15] Of Byte; S, IP, H, I, R : LongInt;
Begin
  NetOpen := -1;
  If Not NetReady Then
  Begin
    If sock_init <> 0 Then
    Begin
      Err := 'R'#233'seau absent (TCP/IP non configur'#233').';
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
      Err := 'Ordinateur introuvable : ' + Host;
      Exit;
    End;
    { hostent d'OS/2 : h_addr_list en +16 }
    IP := GetLE(GetLE(GetLE(H + 16)));
  End;
  S := socket(2, 1, 0);
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

{ attend des donnees au plus Ms millisecondes (verrou libere) : select
  d'OS/2 ; True si des donnees (ou la fermeture) sont arrivees }
Function NetReadable(S, Ms : LongInt) : Boolean;
Var Fs : Array[0..0] Of LongInt; R : LongInt;
Begin
  Fs[0] := S;
  BigUnlock;
  R := select(LongInt(@Fs[0]), 1, 0, 0, Ms);
  BigLock;
  NetReadable := R <> 0;
End;

Procedure NetClose(S : LongInt);
Begin
  Dummy0 := shutdown(S, 2);
  Dummy0 := soclose(S);
End;

{ fichiers : DosOpen (OPEN_ACCESS_READONLY, OPEN_SHARE_DENYWRITE ; ou
  creer/remplacer en ecriture) ; -1 en cas d'echec }
Function LfOpen(Name : String) : LongInt;
Var H, Act : LongInt;
Begin
  PutZ(LongInt(@NetZ[0]), Name);
  H := 0; Act := 0;
  If DosOpen(LongInt(@NetZ[0]), LongInt(@H), LongInt(@Act), 0, 0, $01, $20, 0) <> 0 Then H := -1;
  LfOpen := H;
End;

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
{ Utilitaires de l'interface et couche de Presentation Manager          }
{ ==================================================================== }

Const
  CW = 6;                               { petite police 6 x 13 }
  RH = 16;                              { hauteur d'une ligne de liste }
  HH = 17;                              { en-tete des colonnes }

Var
  Hab, Hmq, Frame, MainWnd, Dummy, OemOut, Fnt : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  Qmsg : Array[0..7] Of LongInt;
  LockSem : LongInt;                    { semaphore d'exclusion (DOSCALLS) }
  LockOn : Boolean;
  AppDir : String;

Var
  LockDepth : LongInt;                  { profondeur (tache qui le tient) }

{ le verrou echange les variables de connexion : la tache qui le prend
  retrouve les siennes (contexte de la tache, s'il y en a un) }
Procedure BigLock;
Var C : LongInt;
Begin
  If Not LockOn Then Exit;
  Dummy0 := DosRequestMutexSem(LockSem, -1);
  Inc(LockDepth);
  If LockDepth = 1 Then
  Begin
    C := TlsGet(TlsIdx);
    If C <> 0 Then CtxLoad(PCtx(C));
  End;
End;

Procedure BigUnlock;
Var C : LongInt;
Begin
  If Not LockOn Then Exit;
  If LockDepth = 1 Then
  Begin
    C := TlsGet(TlsIdx);
    If C <> 0 Then CtxSave(PCtx(C));
  End;
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

{ ANSI (1252) -> page 437 de la police de l'ecran (celle de PMGPI, lue
  par VioGetFont) }
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

{ texte ANSI tel qu'il s'affiche (page 437) }
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

{ boite de message de PM (| : saut de ligne) ; S2 : suite du texte
  (messages de plus de 255 caracteres) }
Function Ask2(Text, Text2, Cap : String; Fl : LongInt) : LongInt;
Var D, I, N : LongInt; A : Array[0..767] Of Byte; B : Array[0..255] Of Byte;
Begin
  Text := Disp(Text); Text2 := Disp(Text2);
  N := 0;
  For I := 1 To Length(Text) Do
  Begin
    If Text[I] = '|' Then A[N] := 10 Else A[N] := Ord(Text[I]);
    Inc(N);
  End;
  For I := 1 To Length(Text2) Do
  Begin
    If Text2[I] = '|' Then A[N] := 10 Else A[N] := Ord(Text2[I]);
    Inc(N);
  End;
  A[N] := 0;
  PutZ(LongInt(@B[0]), Disp(Cap));
  D := LockDepthRelease;
  Ask2 := WinMessageBox(HWND_DESKTOP, Frame, LongInt(@A[0]), LongInt(@B[0]), 0, Fl Or MB_MOVEABLE);
  LockDepthRestore(D);
End;

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := Ask2(Text, '', Cap, Fl);
End;

{ ---- dessin par GPI ---------------------------------------------------
  Les procedures de dessin recoivent des coordonnees de Pasdows (origine
  en haut a gauche, X2 et Y2 exclus) ; PaintH (hauteur de la fenetre
  dessinee) sert a les retourner pour PM (origine en bas a gauche). }

Var
  PaintH, CurFont, PaintWnd : LongInt;

{ 0BBGGRR (Pasdows) -> RRGGBB (GPI, LCOLF_RGB) }
Function Rgb(C : LongInt) : LongInt;
Begin
  Rgb := ((C And $FF) Shl 16) Or (C And $FF00) Or ((C Shr 16) And $FF);
End;

Function WinH(H : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[3] := 0;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  WinH := Rc[3];
End;

{ WinBeginPaint ; Ps[0] : espace de presentation, Ps[2..5] : rectangle a
  redessiner (gauche, haut, droite, bas, coordonnees de Pasdows) }
Function PBegin(H, P : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Hps : LongInt;
Begin
  Rc[0] := 0; Rc[1] := 0; Rc[2] := 0; Rc[3] := 0;
  Hps := WinBeginPaint(H, 0, LongInt(@Rc));
  PaintWnd := H;
  PaintH := WinH(H);
  If (Rc[2] <= Rc[0]) Or (Rc[3] <= Rc[1]) Then
  Begin
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  End;
  PLng(P)^ := Hps;
  PLng(P + 8)^ := Rc[0]; PLng(P + 12)^ := PaintH - Rc[3];
  PLng(P + 16)^ := Rc[2]; PLng(P + 20)^ := PaintH - Rc[1];
  { couleurs RVB (le fond des textes reste tel quel : BM_LEAVEALONE par defaut) }
  Dummy := GpiCreateLogColorTable(Hps, 0, 3, 0, 0, 0);
  CurFont := -1;
  PBegin := Hps;
End;

Function PEnd(H, P : LongInt) : LongInt;
Begin
  PEnd := 0;
  Dummy := WinEndPaint(PLng(P)^);
End;

{ police : 1 petite (police de l'ecran ramenee a 6 x 16), 2 celle de
  l'ecran (8 x 16) ; rend la precedente }
Function SelFont(Dc, F : LongInt) : LongInt;
Var B : Array[0..1] Of LongInt;
Begin
  SelFont := CurFont;
  If (F = CurFont) Or (F < 1) Then Exit;
  CurFont := F;
  If F = 1 Then Begin B[0] := 6 * 65536; B[1] := 16 * 65536; End
  Else Begin B[0] := 8 * 65536; B[1] := 16 * 65536; End;
  Dummy := GpiSetCharBox(Dc, LongInt(@B[0]));
End;

{ dessin : rectangle plein, texte, reliefs }
Procedure Bar(Dc, X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  Dummy := GpiSetColor(Dc, Rgb(C));
  P[0] := X1; P[1] := PaintH - Y2;
  Dummy := GpiMove(Dc, LongInt(@P[0]));
  P[0] := X2 - 1; P[1] := PaintH - Y1 - 1;
  { DRO_OUTLINEFILL : un rectangle d'un pel de large (trait) est trace }
  Dummy := GpiBox(Dc, 3, LongInt(@P[0]), 0, 0);
End;

{ hauteur de la police courante }
Function FontH : LongInt;
Begin
  FontH := 16;
End;

{ texte (deja dans la page de l'ecran) a partir de A, N caracteres ; Y :
  haut de la ligne }
Procedure TxtRaw(Dc, X, Y, A, N, Fg : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If N <= 0 Then Exit;
  If CurFont < 1 Then Dummy := SelFont(Dc, 1);
  Dummy := GpiSetColor(Dc, Rgb(Fg));
  P[0] := X; P[1] := PaintH - Y - (FontH * 12 + 8) Div 16;
  Dummy := GpiCharStringAt(Dc, LongInt(@P[0]), N, A);
End;

{ texte (police courante), fond transparent }
Procedure Txt(Dc, X, Y : LongInt; S : String; Fg : LongInt);
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), Disp(S));
  TxtRaw(Dc, X, Y, LongInt(@TxtBuf), Length(S), Fg);
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

{ ---- fenetres ---- }

{ rectangle de la fenetre : 0, 0, largeur, hauteur }
Function CliRect(H, P : LongInt) : LongInt;
Begin
  CliRect := 1;
  PLng(P)^ := 0; PLng(P + 4)^ := 0; PLng(P + 8)^ := 0; PLng(P + 12)^ := 0;
  Dummy := WinQueryWindowRect(H, P);
End;

{ a redessiner : toute la fenetre (P = 0) ou le rectangle de Pasdows P }
Function Inval(H, P : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Hh : LongInt;
Begin
  Inval := 1;
  If H = 0 Then Exit;
  If P = 0 Then
  Begin
    Dummy := WinInvalidateRect(H, 0, 0);
    Exit;
  End;
  Hh := WinH(H);
  Rc[0] := PLng(P)^; Rc[2] := PLng(P + 8)^;
  Rc[1] := Hh - PLng(P + 12)^; Rc[3] := Hh - PLng(P + 4)^;
  Dummy := WinInvalidateRect(H, LongInt(@Rc), 0);
End;

{ place la fenetre enfant H (coordonnees de Pasdows dans son parent) }
Function Place(H, X, Y, W, Hh : LongInt) : LongInt;
Var Ph : LongInt;
Begin
  Place := 1;
  If H = 0 Then Exit;
  Ph := WinH(WinQueryWindow(H, QW_PARENT));
  If W < 0 Then W := 0;
  If Hh < 0 Then Hh := 0;
  Dummy := WinSetWindowPos(H, 0, X, Ph - Y - Hh, W, Hh, SWP_SIZE Or SWP_MOVE);
End;

Function Show(H, N : LongInt) : LongInt;
Begin
  Show := WinShowWindow(H, Ord(N <> 0));
End;

Function FocusTo(H : LongInt) : LongInt;
Begin
  FocusTo := 1;
  If H <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, H);
End;

Function FocusWnd : LongInt;
Begin
  FocusWnd := WinQueryFocus(HWND_DESKTOP);
End;

Function Capture(H : LongInt) : LongInt;
Begin
  Capture := WinSetCapture(HWND_DESKTOP, H);
End;

{ point de la fenetre H (coordonnees de Pasdows) -> ecran (coordonnees
  de PM) }
Function ToScreen(H, P : LongInt) : LongInt;
Var Pt : Array[0..1] Of LongInt;
Begin
  Pt[0] := PLng(P)^; Pt[1] := WinH(H) - 1 - PLng(P + 4)^;
  Dummy := WinMapWindowPoints(H, HWND_DESKTOP, LongInt(@Pt[0]), 1);
  PLng(P)^ := Pt[0]; PLng(P + 4)^ := Pt[1];
  ToScreen := 1;
End;

{ Maj ou Ctrl enfoncee : etat de PM, plus celui du WM_CHAR en cours }
Var
  KeyFl : LongInt;

Function GetKeyState(V : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If V = VK_SHIFT Then
  Begin
    R := WinGetKeyState(HWND_DESKTOP, PVK_SHIFT);
    If (KeyFl And KC_SHIFT) <> 0 Then R := R Or $8000;
  End
  Else If V = VK_CONTROL Then
  Begin
    R := WinGetKeyState(HWND_DESKTOP, PVK_CTRL);
    If (KeyFl And KC_CTRL) <> 0 Then R := R Or $8000;
  End;
  GetKeyState := R;
End;

{ barres de defilement de PM }
Procedure SbSet(H, Pos, Max, Vis : LongInt);
Begin
  If H = 0 Then Exit;
  Dummy := WinSendMsg(H, SBM_SETTHUMBSIZE, MaxI(Vis, 1) Or (MaxI(Max + Vis, 1) Shl 16), 0);
  Dummy := WinSendMsg(H, SBM_SETSCROLLBAR, Pos, MaxI(Max, 1) Shl 16);
End;

{ controle de PM, enfant (et possede) de P ; coordonnees de Pasdows }
Function MkCtl(P, Cls : LongInt; T : String; Style, X, Y, W, H, Id : LongInt) : LongInt;
Var R : LongInt;
Begin
  PutZ(LongInt(@NameZ), Disp(T));
  { HWND_BOTTOM : ordre de creation = ordre de la touche Tab }
  R := WinCreateWindow(P, Cls, LongInt(@NameZ), Style Or WS_VISIBLE, X, WinH(P) - Y - H, W, H, P, 4,
                       Id, 0, 0);
  MkCtl := R;
End;

{ fond gris de PM (texte, cases, groupes sur une boite) }
Procedure Gray(H : LongInt);
Var C : LongInt;
Begin
  C := Rgb(ClrFace);
  If H <> 0 Then Dummy := WinSetPresParam(H, 3, 4, LongInt(@C));
End;

Function CtlText(H : LongInt) : String;
Begin
  TxtBuf[0] := 0;
  Dummy := WinQueryWindowText(H, 255, LongInt(@TxtBuf));
  CtlText := UnDisp(GetZ(LongInt(@TxtBuf)));
End;

Procedure SetText(H : LongInt; S : String);
Begin
  Dummy := WinSetWindowText(H, Z(Disp(S)));
End;

Function Checked(H : LongInt) : Boolean;
Begin
  Checked := WinSendMsg(H, BM_QUERYCHECK, 0, 0) <> 0;
End;

Procedure SetCheck(H : LongInt; On : Boolean);
Begin
  Dummy := WinSendMsg(H, BM_SETCHECK, Ord(On), 0);
End;

{ ---- menus ----------------------------------------------------------
  Les menus sont tenus ici (articles, sous-menus, coches) puis donnes a
  PM sous forme de modeles : WinCreateMenu sur le cadre pour la barre de
  menus, WinCreateMenu + WinPopupMenu pour les menus contextuels.
  Menus 1 a 12 : menus permanents ; 13 a 23 : menus contextuels (reutilises). }

Const
  MnMax = 23; MnItems = 44;

Var
  MnN : Array[1..MnMax] Of LongInt;
  MnId, MnSub, MnFl : Array[1..MnMax, 0..MnItems - 1] Of LongInt;
  MnTx : Array[1..MnMax, 0..MnItems - 1] Of String[63];
  MnPerm, MnTemp : LongInt;
  MnTpl : Array[0..16383] Of Byte;
  MnLen, MnBarH, MnPopH : LongInt;

Function MkMenu : LongInt;
Begin
  If MnPerm < 12 Then
  Begin
    Inc(MnPerm);
    MkMenu := MnPerm;
    MnN[MnPerm] := 0;
    Exit;
  End;
  Inc(MnTemp);
  If (MnTemp < 13) Or (MnTemp > MnMax) Then MnTemp := 13;
  MnN[MnTemp] := 0;
  MkMenu := MnTemp;
End;

{ menu contextuel neuf (meme apres les menus permanents) }
Function MkPopup : LongInt;
Begin
  If MnPerm < 12 Then MnPerm := 12;
  MkPopup := MkMenu;
End;

Procedure MAdd(M, Id, Sub, Fl : LongInt; S : String);
Var K : LongInt;
Begin
  If (M < 1) Or (M > MnMax) Or (MnN[M] >= MnItems) Then Exit;
  K := MnN[M];
  MnId[M, K] := Id; MnSub[M, K] := Sub; MnFl[M, K] := Fl; MnTx[M, K] := Copy(Disp(S), 1, 63);
  Inc(MnN[M]);
End;

{ article (Id 0 : separateur) ; ~ : lettre soulignee }
Procedure MItem(M, Id : LongInt; S : String);
Begin
  MAdd(M, Id, 0, 0, S);
End;

Procedure MSub(Bar0, P : LongInt; S : String);
Begin
  MAdd(Bar0, 900 + P, P, 0, S);
End;

Procedure MClear(M : LongInt);
Begin
  If (M >= 1) And (M <= MnMax) Then MnN[M] := 0;
End;

Procedure MSetFl(M, Id, Bit : LongInt; On : Boolean);
Var K : LongInt;
Begin
  If (M < 1) Or (M > MnMax) Then Exit;
  For K := 0 To MnN[M] - 1 Do
    If MnId[M, K] = Id Then
    Begin
      If On Then MnFl[M, K] := MnFl[M, K] Or Bit
      Else MnFl[M, K] := MnFl[M, K] And Not Bit;
    End;
End;

Procedure MCheck(M, Id : LongInt; On : Boolean);
Begin
  MSetFl(M, Id, MIA_CHECKED, On);
End;

Procedure MEnable(M, Id : LongInt; On : Boolean);
Begin
  MSetFl(M, Id, MIA_DISABLED, Not On);
End;

Procedure MB(V : LongInt);
Begin
  If MnLen < 16383 Then
  Begin
    MnTpl[MnLen] := V And 255;
    Inc(MnLen);
  End;
End;

Procedure MW(V : LongInt);
Begin
  MB(V And 255); MB((V Shr 8) And 255);
End;

{ modele du menu M (en-tete : longueur, page de codes, nombre ; articles :
  style, attributs, identificateur, texte, modele du sous-menu) }
Procedure MTemplate(M, Depth : LongInt);
Var H, K, I, St : LongInt; S : String;
Begin
  H := MnLen;
  MW(0); MW(0); MW(0);
  If Depth > 3 Then Exit;
  For K := 0 To MnN[M] - 1 Do
  Begin
    If MnId[M, K] = 0 Then
    Begin
      MW(MIS_SEPARATOR); MW(0); MW(0);
    End
    Else
    Begin
      St := MIS_TEXT;
      If MnSub[M, K] <> 0 Then St := St Or MIS_SUBMENU;
      MW(St); MW(MnFl[M, K]); MW(MnId[M, K]);
      S := MnTx[M, K];
      For I := 1 To Length(S) Do MB(Ord(S[I]));
      MB(0);
      If MnSub[M, K] <> 0 Then MTemplate(MnSub[M, K], Depth + 1);
    End;
  End;
  MnTpl[H] := (MnLen - H) And 255; MnTpl[H + 1] := ((MnLen - H) Shr 8) And 255;
  MnTpl[H + 4] := MnN[M] And 255; MnTpl[H + 5] := 0;
End;

{ barre de menus du cadre : creee une fois d'apres son modele
  (WinCreateMenu) ; ensuite, chaque sous-menu de PM est mis a jour sur
  place : articles changes (MM_DELETEITEM, MM_INSERTITEM), coches et
  articles grises (MM_SETITEMATTR) }
Const
  MM_INSERTITEM = $0180; MM_DELETEITEM = $0181; MM_QUERYITEM = $0182;
  MM_QUERYITEMCOUNT = $0184; MM_ITEMIDFROMPOSITION = $0190; MM_SETITEMATTR = $0192;

Var
  MnPm : Array[1..12] Of LongInt;       { fenetre de PM du menu permanent }
  MnSig : Array[1..12] Of LongInt;      { empreinte des articles envoyes }

Function MSign(M : LongInt) : LongInt;
Var K, I, V : LongInt; S : String;
Begin
  V := MnN[M];
  For K := 0 To MnN[M] - 1 Do
  Begin
    V := V * 31 + MnId[M, K];
    S := MnTx[M, K];
    For I := 1 To Length(S) Do V := (V * 7 + Ord(S[I])) And $FFFFFFF;
  End;
  MSign := V;
End;

{ fenetres de PM des sous-menus (MM_QUERYITEM : hwndSubMenu) }
Procedure MFindPm(M, H : LongInt);
Var K, Sub : LongInt; It : Array[0..3] Of LongInt;
Begin
  If (M < 1) Or (M > 12) Then Exit;
  MnPm[M] := H;
  MnSig[M] := MSign(M);
  For K := 0 To MnN[M] - 1 Do
  Begin
    Sub := MnSub[M, K];
    If Sub <> 0 Then
    Begin
      It[0] := 0; It[1] := 0; It[2] := 0; It[3] := 0;
      If WinSendMsg(H, MM_QUERYITEM, MnId[M, K] Or (1 Shl 16), LongInt(@It[0])) <> 0 Then MFindPm(Sub, It[2]);
    End;
  End;
End;

{ sous-menu M de PM refait d'apres le modele }
Procedure MRefill(M : LongInt);
Var H, N, K, Id : LongInt; It : Array[0..3] Of LongInt;
Begin
  H := MnPm[M];
  N := WinSendMsg(H, MM_QUERYITEMCOUNT, 0, 0);
  While N > 0 Do
  Begin
    Id := WinSendMsg(H, MM_ITEMIDFROMPOSITION, 0, 0);
    Dummy := WinSendMsg(H, MM_DELETEITEM, Id And $FFFF, 0);
    Dec(N);
  End;
  For K := 0 To MnN[M] - 1 Do
  Begin
    { MENUITEM : iPosition (MIT_END), afStyle, afAttribute, id,
      hwndSubMenu, hItem }
    If MnId[M, K] = 0 Then It[0] := $FFFF Or (MIS_SEPARATOR Shl 16)
    Else It[0] := $FFFF Or (MIS_TEXT Shl 16);
    It[1] := (MnFl[M, K] And $FFFF) Or (MnId[M, K] Shl 16);
    It[2] := 0; It[3] := 0;
    Dummy := WinSendMsg(H, MM_INSERTITEM, LongInt(@It[0]), Z(MnTx[M, K]));
  End;
End;

Procedure MenuBarSet(M : LongInt);
Var I, K : LongInt;
Begin
  If MnBarH = 0 Then
  Begin
    MnLen := 0;
    MTemplate(M, 0);
    MnBarH := WinCreateMenu(Frame, LongInt(@MnTpl));
    For I := 1 To 12 Do MnPm[I] := 0;
    If MnBarH <> 0 Then MFindPm(M, MnBarH);
    Exit;
  End;
  For I := 1 To 12 Do
    If MnPm[I] <> 0 Then
    Begin
      If MSign(I) <> MnSig[I] Then
      Begin
        MRefill(I);
        MnSig[I] := MSign(I);
      End
      Else
        For K := 0 To MnN[I] - 1 Do
          If MnId[I, K] <> 0 Then
            Dummy := WinSendMsg(MnPm[I], MM_SETITEMATTR, MnId[I, K],
                                (MIA_CHECKED Or MIA_DISABLED) Or ((MnFl[I, K] And $FFFF) Shl 16));
    End;
End;

{ menu contextuel M au point X, Y de l'ecran (coordonnees de PM) }
Procedure TrackMenu(M, X, Y : LongInt);
Begin
  MnLen := 0;
  MTemplate(M, 0);
  If MnPopH <> 0 Then Dummy := WinDestroyWindow(MnPopH);
  MnPopH := WinCreateMenu(HWND_DESKTOP, LongInt(@MnTpl));
  If MnPopH <> 0 Then Dummy := WinPopupMenu(HWND_DESKTOP, MainWnd, MnPopH, X, Y, 0, 0);
End;

Procedure MsgLoop;
Begin
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do
    Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
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

{ D est-il un dossier ou l'on peut ecrire ? (cree au besoin) }
Function DirWritable(D : String) : Boolean;
Var H, Act : LongInt;
Begin
  Dummy := DosCreateDir(Z(Copy(D, 1, Length(D) - 1)), 0);
  H := 0; Act := 0;
  { OPEN_ACTION_CREATE_IF_NEW Or OPEN_ACTION_REPLACE_IF_EXISTS,
    ecriture seule }
  If DosOpen(Z(D + 'SSHCLI.$$$'), LongInt(@H), LongInt(@Act), 0, 0, $12, $21, 0) <> 0 Then
  Begin
    DirWritable := False;
    Exit;
  End;
  Dummy := DosClose(H);
  Dummy := DosDelete(Z(D + 'SSHCLI.$$$'));
  DirWritable := True;
End;

{ dossier des fichiers (sessions.xml, macros.xml, settings.xml,
  knownhosts.txt) : C:\RESEAU\, sinon D:\RESEAU\ (C: en lecture seule :
  demarrage depuis le CD-ROM) ; meme regle que le Client FTP }
Procedure FindAppDir;
Begin
  AppDir := 'C:\RESEAU\';
  If Not DirWritable(AppDir) Then
  Begin
    AppDir := 'D:\RESEAU\';
    If Not DirWritable(AppDir) Then AppDir := 'C:\RESEAU\';
  End;
End;
{ ==================================================================== }
{ Emulateur de terminal xterm                                           }
{ L'etat du terminal courant est dans T (TmLoad / TmSave pour passer    }
{ d'une session a l'autre). Cellule : caractere (page 437, police de    }
{ l'ecran) + couleurs (bits 8 a 11 : texte, 12 a 15 : fond) + 65536     }
{ pour le souligne.                                                     }
{ ==================================================================== }

Const
  MaxCols = 160; MaxRows = 80;
  HistMax = 2000;                       { lignes d'historique au plus }
  RowBytes = MaxCols * 4;
  TFW = 8; TFH = 16;                     { police du terminal }

Type
  TTerm = Record
    Cols, Rows : LongInt;
    Scr, AltS, Hist : TlPtr;             { ecran, ecran alternatif, historique }
    HistN, HistHead, HistLim : LongInt;
    HistTotal : Double;                  { lignes entrees dans l'historique }
    AltOn : Boolean;
    CX, CY : LongInt;
    WrapNext : Boolean;
    Fg, Bg, DefFg, DefBg : LongInt;
    Bold, Rev, Under, Hidden : Boolean;
    Top, Bot : LongInt;                  { region de defilement }
    SvX, SvY, SvFg, SvBg : LongInt;
    SvBold, SvRev, SvUnder, SvG0 : Boolean;
    AppCursor, AppKeypad, CurVis, AutoWrap, Origin, InsMode : Boolean;
    Paste2004 : Boolean;
    G0Line, G1Line, ShiftOut : Boolean;  { graphismes DEC }
    St : LongInt;                        { 0 texte, 1 ESC, 2 CSI, 3 OSC,
                                           4 ESC ( 5 ESC ) 6 ESC # 7 OSC ESC
                                           8 DCS }
    Prm : Array[0..15] Of LongInt;
    PrmN : LongInt;
    Priv : LongInt;                      { '?', '>', '=' ou 0 }
    Inter : LongInt;
    Osc : String;
    U8Need, U8Val : LongInt;
    LastCh : LongInt;
    Tabs : Array[0..MaxCols - 1] Of Boolean;
    Title : String;
    TitleSet : Boolean;
    Bell : Boolean;
    ScrollOff : LongInt;                 { lignes remontees dans l'historique }
    SelOn, Selecting : Boolean;
    SelA, SelB : Double;                 { debut et fin : ligne * 1000 + col }
    DirtyA, DirtyB : LongInt;            { lignes a redessiner (A > B : aucune) }
  End;
  PTerm = ^TTerm;

Var
  T : TTerm;
  Pal : Array[0..15] Of LongInt;
  TmOut : String;                         { reponses au serveur (DSR, DA) }

Const
  { page 437 -> Unicode (128 a 255) }
  Cp437U : Array[128..255] Of LongInt = (
    $C7, $FC, $E9, $E2, $E4, $E0, $E5, $E7, $EA, $EB, $E8, $EF, $EE, $EC,
    $C4, $C5, $C9, $E6, $C6, $F4, $F6, $F2, $FB, $F9, $FF, $D6, $DC, $A2,
    $A3, $A5, $20A7, $192, $E1, $ED, $F3, $FA, $F1, $D1, $AA, $BA, $BF,
    $2310, $AC, $BD, $BC, $A1, $AB, $BB, $2591, $2592, $2593, $2502, $2524,
    $2561, $2562, $2556, $2555, $2563, $2551, $2557, $255D, $255C, $255B,
    $2510, $2514, $2534, $252C, $251C, $2500, $253C, $255E, $255F, $255A,
    $2554, $2569, $2566, $2560, $2550, $256C, $2567, $2568, $2564, $2565,
    $2559, $2558, $2552, $2553, $256B, $256A, $2518, $250C, $2588, $2584,
    $258C, $2590, $2580, $3B1, $DF, $393, $3C0, $3A3, $3C3, $B5, $3C4,
    $3A6, $398, $3A9, $3B4, $221E, $3C6, $3B5, $2229, $2261, $B1, $2265,
    $2264, $2320, $2321, $F7, $2248, $B0, $2219, $B7, $221A, $207F, $B2,
    $25A0, $A0);
  { lettres sans accent de U+00C0 a U+00FF }
  NoAcc : String[64] =
    'AAAAAAACEEEEIIIIDNOOOOOxOUUUUYPsaaaaaaaceeeeiiiidnooooo/ouuuuypy';
  { graphismes DEC (ESC ( 0) : caracteres 96 a 126 }
  DecGr : Array[96..126] Of Byte = (
    4, 177, 9, 12, 13, 10, 248, 241, 10, 11, 217, 191, 218, 192, 197, 196,
    196, 196, 196, 196, 195, 180, 193, 194, 179, 243, 242, 227, 33, 156, 250);

{ ---- couleurs ---- }

Procedure PalInit;
Const
  V : Array[0..15] Of LongInt = ($000000, $0000AA, $00AA00, $0055AA,
    $AA0000, $AA00AA, $AAAA00, $AAAAAA, $555555, $5555FF, $55FF55, $55FFFF,
    $FF5555, $FF55FF, $FFFF55, $FFFFFF);
Var I : LongInt;
Begin
  For I := 0 To 15 Do Pal[I] := V[I];
End;

{ couleur RVB la plus proche parmi les 16 }
Function Near16(R, G, B : LongInt) : LongInt;
Var I, D, Best, BD, Pr, Pg, Pb : LongInt;
Begin
  Best := 0; BD := 2147483647;
  For I := 0 To 15 Do
  Begin
    Pr := Pal[I] And 255; Pg := (Pal[I] Shr 8) And 255;
    Pb := (Pal[I] Shr 16) And 255;
    D := (R - Pr) * (R - Pr) + (G - Pg) * (G - Pg) + (B - Pb) * (B - Pb);
    If D < BD Then Begin BD := D; Best := I; End;
  End;
  Near16 := Best;
End;

{ couleur de la palette xterm 256 -> 16 }
Function Map256(N : LongInt) : LongInt;
Var R, G, B, V : LongInt;
Begin
  If N < 16 Then Map256 := N
  Else If N < 232 Then
  Begin
    N := N - 16;
    R := N Div 36; G := (N Div 6) Mod 6; B := N Mod 6;
    If R > 0 Then R := 55 + R * 40;
    If G > 0 Then G := 55 + G * 40;
    If B > 0 Then B := 55 + B * 40;
    Map256 := Near16(R, G, B);
  End
  Else
  Begin
    V := 8 + (N - 232) * 10;
    Map256 := Near16(V, V, V);
  End;
End;

{ ---- cellules ---- }

Function RowPtr(Base : TlPtr; R : LongInt) : TlPtr;
Begin
  RowPtr := Base + R * RowBytes;
End;

Function CurScr : TlPtr;
Begin
  If T.AltOn Then CurScr := T.AltS Else CurScr := T.Scr;
End;

Function BlankCell : LongInt;
Begin
  BlankCell := 32 Or (T.Fg Shl 8) Or (T.Bg Shl 12);
End;

Function DefBlank : LongInt;
Begin
  DefBlank := 32 Or (T.DefFg Shl 8) Or (T.DefBg Shl 12);
End;

Procedure Dirty(A, B : LongInt);
Begin
  If T.DirtyA > T.DirtyB Then
  Begin
    T.DirtyA := A; T.DirtyB := B;
  End
  Else
  Begin
    If A < T.DirtyA Then T.DirtyA := A;
    If B > T.DirtyB Then T.DirtyB := B;
  End;
End;

Procedure FillCells(P : TlPtr; N, V : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do PLng(P + I * 4)^ := V;
End;

Procedure MoveCells(Src, Dst : TlPtr; N : LongInt);
Var I : LongInt;
Begin
  If N <= 0 Then Exit;
  If Dst < Src Then
    For I := 0 To N - 1 Do PLng(Dst + I * 4)^ := PLng(Src + I * 4)^
  Else
    For I := N - 1 DownTo 0 Do PLng(Dst + I * 4)^ := PLng(Src + I * 4)^;
End;

{ ligne de l'ecran principal dans l'historique }
Procedure HistPush(P : TlPtr);
Var I : LongInt;
Begin
  If T.HistLim <= 0 Then Exit;
  If T.HistN < T.HistLim Then
  Begin
    I := (T.HistHead + T.HistN) Mod HistMax;
    Inc(T.HistN);
  End
  Else
  Begin
    I := T.HistHead;
    T.HistHead := (T.HistHead + 1) Mod HistMax;
  End;
  MoveCells(P, RowPtr(T.Hist, I), MaxCols);
  T.HistTotal := T.HistTotal + 1;
  If T.ScrollOff > 0 Then
    If T.ScrollOff < T.HistN Then Inc(T.ScrollOff);
End;

Procedure ScrollUp(A, B, N : LongInt);
Var S : TlPtr; R : LongInt;
Begin
  If N <= 0 Then Exit;
  If N > B - A + 1 Then N := B - A + 1;
  S := CurScr;
  If (A = 0) And Not T.AltOn Then
    For R := 0 To N - 1 Do HistPush(RowPtr(S, R));
  For R := A To B - N Do
    MoveCells(RowPtr(S, R + N), RowPtr(S, R), MaxCols);
  For R := B - N + 1 To B Do FillCells(RowPtr(S, R), MaxCols, BlankCell);
  Dirty(A, B);
End;

Procedure ScrollDown(A, B, N : LongInt);
Var S : TlPtr; R : LongInt;
Begin
  If N <= 0 Then Exit;
  If N > B - A + 1 Then N := B - A + 1;
  S := CurScr;
  For R := B DownTo A + N Do
    MoveCells(RowPtr(S, R - N), RowPtr(S, R), MaxCols);
  For R := A To A + N - 1 Do FillCells(RowPtr(S, R), MaxCols, BlankCell);
  Dirty(A, B);
End;

Procedure LineFeed;
Begin
  T.WrapNext := False;
  If T.CY = T.Bot Then ScrollUp(T.Top, T.Bot, 1)
  Else If T.CY < T.Rows - 1 Then Inc(T.CY);
End;

Procedure RevIndex;
Begin
  T.WrapNext := False;
  If T.CY = T.Top Then ScrollDown(T.Top, T.Bot, 1)
  Else If T.CY > 0 Then Dec(T.CY);
End;

Procedure ClampCur;
Begin
  If T.CX < 0 Then T.CX := 0;
  If T.CX >= T.Cols Then T.CX := T.Cols - 1;
  If T.CY < 0 Then T.CY := 0;
  If T.CY >= T.Rows Then T.CY := T.Rows - 1;
End;

Procedure PutCell(Ch : LongInt);
Var P : TlPtr; F, B, V : LongInt;
Begin
  If T.WrapNext Then
  Begin
    If T.AutoWrap Then
    Begin
      T.CX := 0;
      LineFeed;
    End;
    T.WrapNext := False;
  End;
  P := RowPtr(CurScr, T.CY);
  If T.InsMode Then
    MoveCells(P + T.CX * 4, P + (T.CX + 1) * 4, T.Cols - T.CX - 1);
  F := T.Fg; B := T.Bg;
  If T.Bold And (F < 8) Then F := F + 8;
  If T.Rev Then Begin V := F; F := B; B := V; End;
  If T.Hidden Then F := B;
  V := (Ch And 255) Or (F Shl 8) Or (B Shl 12);
  If T.Under Then V := V Or 65536;
  PLng(P + T.CX * 4)^ := V;
  Dirty(T.CY, T.CY);
  T.LastCh := Ch;
  If T.CX >= T.Cols - 1 Then T.WrapNext := True
  Else Inc(T.CX);
End;

{ caractere Unicode -> page 437 }
Function UniToOem(U : LongInt) : LongInt;
Var I : LongInt;
Begin
  If U < 128 Then
  Begin
    UniToOem := U;
    Exit;
  End;
  For I := 128 To 255 Do
    If Cp437U[I] = U Then
    Begin
      UniToOem := I;
      Exit;
    End;
  Case U Of
    $C0..$FF : UniToOem := Ord(NoAcc[U - $C0 + 1]);
    $2018, $2019, $201A, $2032 : UniToOem := 39;
    $201C, $201D, $201E, $2033 : UniToOem := 34;
    $2010..$2015, $2212 : UniToOem := 45;
    $2026 : UniToOem := 250;
    $2022, $25CF : UniToOem := 7;
    $2190 : UniToOem := 27; $2191 : UniToOem := 24;
    $2192 : UniToOem := 26; $2193 : UniToOem := 25;
    $25B2 : UniToOem := 30; $25BC : UniToOem := 31;
    $25B6, $25BA : UniToOem := 16; $25C0, $25C4 : UniToOem := 17;
    $2666, $25C6 : UniToOem := 4;
    $2713, $2714 : UniToOem := 251;
    $20AC : UniToOem := 69;
    $2501, $2504, $2505, $2508, $2509, $254C, $254D : UniToOem := 196;
    $2503, $2506, $2507, $250A, $250B, $254E, $254F : UniToOem := 179;
    $250D..$250F, $256D : UniToOem := 218;
    $2511..$2513, $256E : UniToOem := 191;
    $2515..$2517, $2570 : UniToOem := 192;
    $2519..$251B, $256F : UniToOem := 217;
    $251D..$2523 : UniToOem := 195;
    $2525..$252B : UniToOem := 180;
    $252D..$2533 : UniToOem := 194;
    $2535..$253B : UniToOem := 193;
    $253D..$254B : UniToOem := 197;
    $2574, $2576, $2578, $257A, $257C, $257E : UniToOem := 196;
    $2575, $2577, $2579, $257B, $257D, $257F : UniToOem := 179;
    $2581..$2583 : UniToOem := 220;
    $2585..$2587, $2589..$258B : UniToOem := 219;
    $258D..$258F : UniToOem := 221;
    $2594 : UniToOem := 223;
    $2595 : UniToOem := 222;
    $25A1, $25AA, $25AB : UniToOem := 254;
    $FEFF, $200B..$200F : UniToOem := -1;   { invisibles }
  Else
    UniToOem := 63;
  End;
End;

Function OemToUni(C : LongInt) : LongInt;
Begin
  If C < 128 Then OemToUni := C Else OemToUni := Cp437U[C];
End;

Function U8Of(U : LongInt) : String;
Begin
  If U < $80 Then U8Of := Chr(U)
  Else If U < $800 Then
    U8Of := Chr($C0 Or (U Shr 6)) + Chr($80 Or (U And $3F))
  Else
    U8Of := Chr($E0 Or (U Shr 12)) + Chr($80 Or ((U Shr 6) And $3F)) +
            Chr($80 Or (U And $3F));
End;

{ ---- etats ---- }

Procedure SgrReset;
Begin
  T.Fg := T.DefFg; T.Bg := T.DefBg;
  T.Bold := False; T.Rev := False; T.Under := False; T.Hidden := False;
End;

Procedure TmFullReset;
Var I : LongInt;
Begin
  SgrReset;
  T.CX := 0; T.CY := 0; T.WrapNext := False;
  T.Top := 0; T.Bot := T.Rows - 1;
  T.AppCursor := False; T.AppKeypad := False; T.CurVis := True;
  T.AutoWrap := True; T.Origin := False; T.InsMode := False;
  T.Paste2004 := False;
  T.G0Line := False; T.G1Line := False; T.ShiftOut := False;
  T.St := 0; T.U8Need := 0;
  For I := 0 To MaxCols - 1 Do T.Tabs[I] := (I Mod 8) = 0;
  T.SvX := 0; T.SvY := 0; T.SvFg := T.DefFg; T.SvBg := T.DefBg;
  T.SvBold := False; T.SvRev := False; T.SvUnder := False; T.SvG0 := False;
  If T.AltOn Then T.AltOn := False;
  For I := 0 To MaxRows - 1 Do
  Begin
    FillCells(RowPtr(T.Scr, I), MaxCols, DefBlank);
    FillCells(RowPtr(T.AltS, I), MaxCols, DefBlank);
  End;
  Dirty(0, T.Rows - 1);
End;

{ terminal neuf : tampons alloues }
Procedure TmCreate(P : PTerm; C, R, Hist, Fg, Bg : LongInt);
Begin
  FillChar(T, SizeOf(TTerm), 0);
  T.Scr := TlNew(MaxRows * RowBytes);
  T.AltS := TlNew(MaxRows * RowBytes);
  T.Hist := TlNew(HistMax * RowBytes);
  T.Cols := MinI(MaxI(C, 10), MaxCols);
  T.Rows := MinI(MaxI(R, 3), MaxRows);
  T.HistLim := MinI(Hist, HistMax);
  T.DefFg := Fg; T.DefBg := Bg;
  T.DirtyA := 1; T.DirtyB := 0;
  TmFullReset;
  P^ := T;
End;

Procedure TmLoad(P : PTerm);
Begin
  T := P^;
End;

Procedure TmSave(P : PTerm);
Begin
  P^ := T;
End;

{ nouvelle taille (lignes du haut envoyees dans l'historique) }
Procedure TmResize(C, R : LongInt);
Var K : LongInt;
Begin
  C := MinI(MaxI(C, 10), MaxCols);
  R := MinI(MaxI(R, 3), MaxRows);
  If (C = T.Cols) And (R = T.Rows) Then Exit;
  If T.CY >= R Then
  Begin
    K := T.CY - R + 1;
    ScrollUp(0, T.Rows - 1, K);
    T.CY := T.CY - K;
  End;
  T.Cols := C; T.Rows := R;
  T.Top := 0; T.Bot := R - 1;
  T.WrapNext := False;
  ClampCur;
  Dirty(0, R - 1);
End;

Procedure EraseLine(R, A, B : LongInt);
Var P : TlPtr;
Begin
  If B < A Then Exit;
  P := RowPtr(CurScr, R);
  FillCells(P + A * 4, B - A + 1, BlankCell);
  Dirty(R, R);
End;

Procedure SaveCursor;
Begin
  T.SvX := T.CX; T.SvY := T.CY; T.SvFg := T.Fg; T.SvBg := T.Bg;
  T.SvBold := T.Bold; T.SvRev := T.Rev; T.SvUnder := T.Under;
  T.SvG0 := T.G0Line;
End;

Procedure RestoreCursor;
Begin
  T.CX := T.SvX; T.CY := T.SvY; T.Fg := T.SvFg; T.Bg := T.SvBg;
  T.Bold := T.SvBold; T.Rev := T.SvRev; T.Under := T.SvUnder;
  T.G0Line := T.SvG0;
  T.WrapNext := False;
  ClampCur;
End;

Procedure SetAlt(On : Boolean; Save : Boolean);
Var I : LongInt;
Begin
  If On = T.AltOn Then Exit;
  If On Then
  Begin
    If Save Then SaveCursor;
    T.AltOn := True;
    For I := 0 To MaxRows - 1 Do
      FillCells(RowPtr(T.AltS, I), MaxCols, BlankCell);
  End
  Else
  Begin
    T.AltOn := False;
    If Save Then RestoreCursor;
  End;
  T.ScrollOff := 0;
  Dirty(0, T.Rows - 1);
End;

Function P0(I, D : LongInt) : LongInt;
Begin
  If (I >= T.PrmN) Or (T.Prm[I] <= 0) Then P0 := D Else P0 := T.Prm[I];
End;

Procedure DoSgr;
Var I, V, N : LongInt;
Begin
  If T.PrmN = 0 Then Begin SgrReset; Exit; End;
  I := 0;
  While I < T.PrmN Do
  Begin
    V := T.Prm[I];
    Case V Of
      0 : SgrReset;
      1 : T.Bold := True;
      4 : T.Under := True;
      7 : T.Rev := True;
      8 : T.Hidden := True;
      21, 22 : T.Bold := False;
      24 : T.Under := False;
      27 : T.Rev := False;
      28 : T.Hidden := False;
      30..37 : T.Fg := V - 30;
      39 : T.Fg := T.DefFg;
      40..47 : T.Bg := V - 40;
      49 : T.Bg := T.DefBg;
      90..97 : T.Fg := V - 90 + 8;
      100..107 : T.Bg := V - 100 + 8;
      38, 48 :
      Begin
        N := -1;
        If (I + 2 < T.PrmN) And (T.Prm[I + 1] = 5) Then
        Begin
          N := Map256(T.Prm[I + 2] And 255);
          I := I + 2;
        End
        Else If (I + 4 < T.PrmN) And (T.Prm[I + 1] = 2) Then
        Begin
          N := Near16(T.Prm[I + 2] And 255, T.Prm[I + 3] And 255,
                      T.Prm[I + 4] And 255);
          I := I + 4;
        End;
        If N >= 0 Then
          If V = 38 Then T.Fg := N Else T.Bg := N;
      End;
    End;
    Inc(I);
  End;
End;

Procedure DoMode(On : Boolean);
Var I : LongInt;
Begin
  For I := 0 To T.PrmN - 1 Do
    If T.Priv = 63 Then
      Case T.Prm[I] Of
        1 : T.AppCursor := On;
        6 : Begin T.Origin := On; T.CX := 0;
              If On Then T.CY := T.Top Else T.CY := 0; End;
        7 : T.AutoWrap := On;
        25 : Begin T.CurVis := On; Dirty(T.CY, T.CY); End;
        47, 1047 : SetAlt(On, False);
        1048 : If On Then SaveCursor Else RestoreCursor;
        1049 : SetAlt(On, True);
        2004 : T.Paste2004 := On;
      End
    Else If T.Priv = 0 Then
      If T.Prm[I] = 4 Then T.InsMode := On;
End;

Procedure DoCsi(F : LongInt);
Var N, I, R, C : LongInt; P : TlPtr;
Begin
  If (T.Priv <> 0) And (T.Priv <> 63) And (F <> 99) Then Exit;
  Case F Of
    64 :                                         { @ ICH }
    Begin
      N := MinI(P0(0, 1), T.Cols - T.CX);
      P := RowPtr(CurScr, T.CY);
      MoveCells(P + T.CX * 4, P + (T.CX + N) * 4, T.Cols - T.CX - N);
      FillCells(P + T.CX * 4, N, BlankCell);
      Dirty(T.CY, T.CY);
    End;
    65 : Begin T.CY := MaxI(T.CY - P0(0, 1), 0);           { A }
           If (T.CY < T.Top) And (T.CY + P0(0, 1) >= T.Top) Then T.CY := T.Top;
         End;
    66, 101 : Begin T.CY := MinI(T.CY + P0(0, 1), T.Rows - 1);  { B e }
           If (T.CY > T.Bot) And (T.CY - P0(0, 1) <= T.Bot) Then T.CY := T.Bot;
         End;
    67, 97 : T.CX := MinI(T.CX + P0(0, 1), T.Cols - 1);     { C a }
    68 : T.CX := MaxI(T.CX - P0(0, 1), 0);                 { D }
    69 : Begin T.CY := MinI(T.CY + P0(0, 1), T.Rows - 1); T.CX := 0; End;
    70 : Begin T.CY := MaxI(T.CY - P0(0, 1), 0); T.CX := 0; End;
    71, 96 : T.CX := MinI(P0(0, 1) - 1, T.Cols - 1);       { G ` }
    72, 102 :                                    { H f }
    Begin
      R := P0(0, 1) - 1; C := P0(1, 1) - 1;
      If T.Origin Then R := R + T.Top;
      T.CY := R; T.CX := C;
      ClampCur;
    End;
    73 :                                         { I : tabulations }
      For I := 1 To P0(0, 1) Do
      Begin
        Repeat Inc(T.CX) Until (T.CX >= T.Cols - 1) Or T.Tabs[T.CX];
        If T.CX > T.Cols - 1 Then T.CX := T.Cols - 1;
      End;
    74 :                                         { J ED }
    Begin
      N := P0(0, 0);
      If T.PrmN = 0 Then N := 0;
      If N = 0 Then
      Begin
        EraseLine(T.CY, T.CX, T.Cols - 1);
        For R := T.CY + 1 To T.Rows - 1 Do EraseLine(R, 0, T.Cols - 1);
      End
      Else If N = 1 Then
      Begin
        For R := 0 To T.CY - 1 Do EraseLine(R, 0, T.Cols - 1);
        EraseLine(T.CY, 0, T.CX);
      End
      Else If N = 2 Then
        For R := 0 To T.Rows - 1 Do EraseLine(R, 0, T.Cols - 1)
      Else If N = 3 Then
      Begin
        T.HistN := 0; T.ScrollOff := 0;
      End;
    End;
    75 :                                         { K EL }
    Begin
      N := 0;
      If T.PrmN > 0 Then N := T.Prm[0];
      If N = 0 Then EraseLine(T.CY, T.CX, T.Cols - 1)
      Else If N = 1 Then EraseLine(T.CY, 0, T.CX)
      Else EraseLine(T.CY, 0, T.Cols - 1);
    End;
    76 : If (T.CY >= T.Top) And (T.CY <= T.Bot) Then          { L IL }
           ScrollDown(T.CY, T.Bot, P0(0, 1));
    77 : If (T.CY >= T.Top) And (T.CY <= T.Bot) Then          { M DL }
           ScrollUp(T.CY, T.Bot, P0(0, 1));
    80 :                                         { P DCH }
    Begin
      N := MinI(P0(0, 1), T.Cols - T.CX);
      P := RowPtr(CurScr, T.CY);
      MoveCells(P + (T.CX + N) * 4, P + T.CX * 4, T.Cols - T.CX - N);
      FillCells(P + (T.Cols - N) * 4, N, BlankCell);
      Dirty(T.CY, T.CY);
    End;
    83 : ScrollUp(T.Top, T.Bot, P0(0, 1));       { S }
    84 : ScrollDown(T.Top, T.Bot, P0(0, 1));     { T }
    88 : EraseLine(T.CY, T.CX, MinI(T.CX + P0(0, 1) - 1, T.Cols - 1));  { X }
    90 :                                         { Z : tabulation arriere }
      For I := 1 To P0(0, 1) Do
        Repeat
          If T.CX > 0 Then Dec(T.CX);
        Until (T.CX = 0) Or T.Tabs[T.CX];
    98 :                                         { b : repeter }
      For I := 1 To MinI(P0(0, 1), 1000) Do PutCell(T.LastCh);
    99 :                                         { c : DA }
      If T.Priv = 62 Then TmOut := TmOut + #27'[>0;95;0c'
      Else If T.Priv = 0 Then TmOut := TmOut + #27'[?1;2c';
    100 : Begin                                  { d VPA }
            T.CY := MinI(P0(0, 1) - 1, T.Rows - 1);
            If T.Origin Then T.CY := MinI(T.CY + T.Top, T.Rows - 1);
          End;
    103 :                                        { g : effacer tabulations }
      If (T.PrmN = 0) Or (T.Prm[0] = 0) Then T.Tabs[T.CX] := False
      Else If T.Prm[0] = 3 Then
        For I := 0 To MaxCols - 1 Do T.Tabs[I] := False;
    104 : DoMode(True);                          { h }
    108 : DoMode(False);                         { l }
    109 : If T.Priv = 0 Then DoSgr;              { m }
    110 :                                        { n : DSR }
      If T.Priv = 0 Then
        If P0(0, 0) = 5 Then TmOut := TmOut + #27'[0n'
        Else If P0(0, 0) = 6 Then
          TmOut := TmOut + #27'[' + IStr(T.CY + 1) + ';' + IStr(T.CX + 1) + 'R';
    114 :                                        { r : region }
      If T.Priv = 0 Then
      Begin
        R := P0(0, 1) - 1; C := P0(1, T.Rows) - 1;
        If C >= T.Rows Then C := T.Rows - 1;
        If R < C Then
        Begin
          T.Top := R; T.Bot := C;
          T.CX := 0;
          If T.Origin Then T.CY := T.Top Else T.CY := 0;
        End;
      End;
    115 : If T.Priv = 0 Then SaveCursor;         { s }
    117 : If T.Priv = 0 Then RestoreCursor;      { u }
  End;
  T.WrapNext := False;
End;

Procedure DoOsc;
Var I, N : LongInt; S : String;
Begin
  I := Pos(';', T.Osc);
  If I = 0 Then Exit;
  N := SVal(Copy(T.Osc, 1, I - 1));
  S := Copy(T.Osc, I + 1, 255);
  If (N = 0) Or (N = 2) Then
  Begin
    T.Title := S;
    T.TitleSet := True;
  End;
End;

Procedure DoEsc(C : LongInt);
Var I : LongInt;
Begin
  T.St := 0;
  Case C Of
    91 : Begin T.St := 2; T.PrmN := 0; T.Priv := 0; T.Inter := 0;
           For I := 0 To 15 Do T.Prm[I] := 0; End;      { [ }
    93 : Begin T.St := 3; T.Osc := ''; End;             { ] }
    80 : T.St := 8;                                     { P : DCS }
    40 : T.St := 4;                                     { ( }
    41 : T.St := 5;                                     { ) }
    35 : T.St := 6;                                     { # }
    37, 42, 43 : T.St := 9;                             { % * + : ignore }
    55 : SaveCursor;                                    { 7 }
    56 : RestoreCursor;                                 { 8 }
    68 : LineFeed;                                      { D IND }
    69 : Begin T.CX := 0; LineFeed; End;                { E NEL }
    72 : T.Tabs[T.CX] := True;                          { H HTS }
    77 : RevIndex;                                      { M RI }
    99 : TmFullReset;                                   { c RIS }
    61 : T.AppKeypad := True;                           { = }
    62 : T.AppKeypad := False;                          { > }
  End;
End;

Procedure TmChar(C : LongInt);
Var U : LongInt;
Begin
  Case T.St Of
    1 :
    Begin
      DoEsc(C);
      Exit;
    End;
    2 :
    Begin
      If (C >= 48) And (C <= 57) Then
      Begin
        If T.PrmN = 0 Then T.PrmN := 1;
        If T.Prm[T.PrmN - 1] < 100000 Then
          T.Prm[T.PrmN - 1] := T.Prm[T.PrmN - 1] * 10 + C - 48;
      End
      Else If (C = 59) Or (C = 58) Then
      Begin
        If T.PrmN = 0 Then T.PrmN := 1;
        If T.PrmN < 16 Then Inc(T.PrmN);
      End
      Else If (C >= 60) And (C <= 63) Then T.Priv := C
      Else If (C >= 32) And (C <= 47) Then T.Inter := C
      Else If (C >= 64) And (C <= 126) Then
      Begin
        T.St := 0;
        If T.Inter = 0 Then DoCsi(C)
        Else If (T.Inter = 33) And (C = 112) Then TmFullReset;  { ! p }
      End
      Else If C = 27 Then T.St := 1
      Else If C < 32 Then
      Begin
        { controle au milieu d'une sequence : execute }
        U := T.St; T.St := 0; TmChar(C); T.St := U;
      End;
      Exit;
    End;
    3 :
    Begin
      If C = 7 Then Begin DoOsc; T.St := 0; End
      Else If C = 27 Then T.St := 7
      Else If Length(T.Osc) < 250 Then T.Osc := T.Osc + Chr(C);
      Exit;
    End;
    7 :
    Begin
      DoOsc;
      T.St := 0;
      If C <> 92 Then TmChar(C);
      Exit;
    End;
    8 :
    Begin
      If C = 27 Then T.St := 10;
      Exit;
    End;
    10 :
    Begin
      T.St := 0;
      If C <> 92 Then T.St := 8;
      Exit;
    End;
    4, 5 :
    Begin
      If T.St = 4 Then T.G0Line := C = 48 Else T.G1Line := C = 48;
      T.St := 0;
      Exit;
    End;
    6 :
    Begin
      T.St := 0;
      Exit;
    End;
    9 :
    Begin
      T.St := 0;
      Exit;
    End;
  End;
  { texte }
  If C < 32 Then
  Begin
    Case C Of
      7 : T.Bell := True;
      8 : If T.CX > 0 Then Begin Dec(T.CX); T.WrapNext := False; End;
      9 :
      Begin
        Repeat
          If T.CX < T.Cols - 1 Then Inc(T.CX);
        Until (T.CX >= T.Cols - 1) Or T.Tabs[T.CX];
      End;
      10, 11, 12 : LineFeed;
      13 : Begin T.CX := 0; T.WrapNext := False; End;
      14 : T.ShiftOut := True;
      15 : T.ShiftOut := False;
      27 : T.St := 1;
    End;
    Exit;
  End;
  If C = 127 Then Exit;
  If ((T.ShiftOut And T.G1Line) Or (Not T.ShiftOut And T.G0Line)) And
     (C >= 96) And (C <= 126) Then
    C := DecGr[C];
  PutCell(C);
End;

{ octets recus (UTF-8) }
Procedure TmFeed(A : TlPtr; N : LongInt);
Var I, B, U : LongInt;
Begin
  For I := 0 To N - 1 Do
  Begin
    B := TlGet(A + I);
    If T.U8Need > 0 Then
    Begin
      If (B And $C0) = $80 Then
      Begin
        T.U8Val := (T.U8Val Shl 6) Or (B And $3F);
        Dec(T.U8Need);
        If T.U8Need = 0 Then
        Begin
          If T.St = 0 Then
          Begin
            U := UniToOem(T.U8Val);
            If U >= 0 Then PutCell(U);
          End;
        End;
        Continue;
      End;
      T.U8Need := 0;
      If T.St = 0 Then PutCell(63);
    End;
    If B < 128 Then TmChar(B)
    Else If (B And $E0) = $C0 Then Begin T.U8Need := 1; T.U8Val := B And $1F; End
    Else If (B And $F0) = $E0 Then Begin T.U8Need := 2; T.U8Val := B And $0F; End
    Else If (B And $F8) = $F0 Then Begin T.U8Need := 3; T.U8Val := B And $07; End
    Else If T.St = 0 Then PutCell(UniToOem(B));   { Latin-1 egare }
  End;
End;

{ texte local (messages de connexion), deja en page 437 ; S peut
  contenir des sequences d'echappement }
Procedure TmText(S : String);
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do TmChar(Ord(S[I]));
End;

{ ---- affichage ---- }

{ cellule de la ligne V de la vue (historique ou ecran) }
Function ViewRow(V : LongInt) : TlPtr;
Var A : LongInt;
Begin
  A := V - T.ScrollOff;
  If A >= 0 Then ViewRow := RowPtr(CurScr, A)
  Else ViewRow := RowPtr(T.Hist, (T.HistHead + T.HistN + A) Mod HistMax);
End;

{ position absolue (ligne * 1000 + colonne) d'une cellule de la vue }
Function ViewAbs(V, C : LongInt) : Double;
Begin
  ViewAbs := (T.HistTotal - T.ScrollOff + V) * 1000.0 + C;
End;

Function InSel(V, C : LongInt) : Boolean;
Var P, A, B : Double;
Begin
  InSel := False;
  If Not T.SelOn Then Exit;
  P := ViewAbs(V, C);
  If T.SelA <= T.SelB Then Begin A := T.SelA; B := T.SelB; End
  Else Begin A := T.SelB; B := T.SelA; End;
  InSel := (P >= A) And (P <= B);
End;

Var
  RunBuf : Array[0..MaxCols + 1] Of Byte;

Procedure TmPaint(Dc, X0, Y0, R0, R1 : LongInt; Focus, Blink : Boolean);
Var V, C, K, Cell, A, Fg, Bg, X : LongInt; P : TlPtr; Cur, Sel : Boolean;
Begin
  If R0 < 0 Then R0 := 0;
  If R1 > T.Rows - 1 Then R1 := T.Rows - 1;
  For V := R0 To R1 Do
  Begin
    P := ViewRow(V);
    C := 0;
    While C < T.Cols Do
    Begin
      { suite de cellules de memes couleurs }
      K := 0;
      A := -1;
      While C + K < T.Cols Do
      Begin
        Cell := PLng(P + (C + K) * 4)^;
        Fg := (Cell Shr 8) And 15; Bg := (Cell Shr 12) And 15;
        Cur := T.CurVis And (T.ScrollOff = 0) And (V = T.CY) And
               (C + K = T.CX) And (Blink Or Not Focus);
        Sel := InSel(V, C + K);
        If Cur Or Sel Then
        Begin
          X := Fg; Fg := Bg; Bg := X;
          If Cur And Not Focus Then Begin Fg := (Cell Shr 8) And 15;
            Bg := (Cell Shr 12) And 15; End;
        End;
        If A = -1 Then A := Fg Or (Bg Shl 4) Or ((Cell Shr 16) And 1) Shl 8
        Else If A <> (Fg Or (Bg Shl 4) Or ((Cell Shr 16) And 1) Shl 8) Then
          Break;
        RunBuf[K] := Cell And 255;
        If RunBuf[K] = 0 Then RunBuf[K] := 32;
        Inc(K);
        If Cur Or Sel Then Break;
      End;
      { fond de la suite puis ses caracteres (police de l'ecran 8 x 16) }
      Bar(Dc, X0 + C * TFW, Y0 + V * TFH, X0 + (C + K) * TFW, Y0 + (V + 1) * TFH, Pal[(A Shr 4) And 15]);
      TxtRaw(Dc, X0 + C * TFW, Y0 + V * TFH, LongInt(@RunBuf[0]), K, Pal[A And 15]);
      If (A And 256) <> 0 Then
        Bar(Dc, X0 + C * TFW, Y0 + V * TFH + TFH - 2, X0 + (C + K) * TFW,
            Y0 + V * TFH + TFH - 1, Pal[A And 15]);
      { curseur sans le focus : cadre }
      If T.CurVis And (T.ScrollOff = 0) And (V = T.CY) And Not Focus And
         (T.CX >= C) And (T.CX < C + K) Then
      Begin
        X := X0 + T.CX * TFW;
        Bar(Dc, X, Y0 + V * TFH, X + TFW, Y0 + V * TFH + 1, Pal[T.DefFg]);
        Bar(Dc, X, Y0 + V * TFH + TFH - 1, X + TFW, Y0 + V * TFH + TFH, Pal[T.DefFg]);
        Bar(Dc, X, Y0 + V * TFH, X + 1, Y0 + V * TFH + TFH, Pal[T.DefFg]);
        Bar(Dc, X + TFW - 1, Y0 + V * TFH, X + TFW, Y0 + V * TFH + TFH, Pal[T.DefFg]);
      End;
      C := C + K;
    End;
  End;
End;

{ ---- selection et copie ---- }

{ texte de la selection (lignes separees par CR LF), page 437, dans B ;
  longueur }
Function TmSelText(B : TlPtr; Max : LongInt) : LongInt;
Var A, Z, L, LA, LZ, C, CA, CZ, N, Last, V, K : LongInt; P : TlPtr;
    Base : Double; S0, S1 : Double;
Begin
  N := 0;
  TmSelText := 0;
  If Not T.SelOn Then Exit;
  If T.SelA <= T.SelB Then Begin S0 := T.SelA; S1 := T.SelB; End
  Else Begin S0 := T.SelB; S1 := T.SelA; End;
  Base := T.HistTotal - T.HistN;         { ligne absolue de Hist[0] }
  LA := Trunc(S0 / 1000) - Trunc(Base); CA := Trunc(S0 - Trunc(S0 / 1000) * 1000.0);
  LZ := Trunc(S1 / 1000) - Trunc(Base); CZ := Trunc(S1 - Trunc(S1 / 1000) * 1000.0);
  If LA < 0 Then Begin LA := 0; CA := 0; End;
  For L := LA To LZ Do
  Begin
    { ligne L : historique (0..HistN-1) ou ecran }
    If L < T.HistN Then P := RowPtr(T.Hist, (T.HistHead + L) Mod HistMax)
    Else If L - T.HistN < T.Rows Then P := RowPtr(CurScr, L - T.HistN)
    Else Break;
    If L = LA Then A := CA Else A := 0;
    If L = LZ Then Z := CZ Else Z := T.Cols - 1;
    If Z > T.Cols - 1 Then Z := T.Cols - 1;
    { sans les espaces de fin de ligne }
    Last := A - 1;
    For C := A To Z Do
      If (PLng(P + C * 4)^ And 255) > 32 Then Last := C;
    If L < LZ Then
      If Z < T.Cols - 1 Then Last := Z;
    For C := A To Last Do
      If N < Max - 3 Then
      Begin
        V := PLng(P + C * 4)^ And 255;
        If V = 0 Then V := 32;
        TlPut(B + N, V); Inc(N);
      End;
    If (L < LZ) And (N < Max - 3) Then
    Begin
      TlPut(B + N, 13); TlPut(B + N + 1, 10); N := N + 2;
    End;
  End;
  TlPut(B + N, 0);
  TmSelText := N;
End;

{ mot autour de la cellule (double clic) }
Function IsWordCh(P : TlPtr; X : LongInt) : Boolean;
Var Ch : LongInt;
Begin
  Ch := PLng(P + X * 4)^ And 255;
  IsWordCh := (Ch > 32) And (Pos(Chr(Ch), ' "''`()[]{}<>|;,') = 0);
End;

Procedure TmSelWord(V, C : LongInt);
Var P : TlPtr; A, Z : LongInt;
Begin
  P := ViewRow(V);
  A := C; Z := C;
  If Not IsWordCh(P, C) Then Exit;
  While (A > 0) And IsWordCh(P, A - 1) Do Dec(A);
  While (Z < T.Cols - 1) And IsWordCh(P, Z + 1) Do Inc(Z);
  T.SelOn := True;
  T.SelA := ViewAbs(V, A); T.SelB := ViewAbs(V, Z);
  Dirty(V, V);
End;

{ ---- clavier ---- }

{ touche speciale -> sequence a envoyer ('' : aucune) }
Function TmKey(VK : LongInt; Shift, Ctrl : Boolean) : String;
Var M, S : String;
Begin
  M := '';
  If Shift And Ctrl Then M := ';6'
  Else If Ctrl Then M := ';5'
  Else If Shift Then M := ';2';
  S := '';
  Case VK Of
    VK_UP, VK_DOWN, VK_RIGHT, VK_LEFT, VK_HOME, VK_END :
    Begin
      Case VK Of
        VK_UP : S := 'A'; VK_DOWN : S := 'B'; VK_RIGHT : S := 'C';
        VK_LEFT : S := 'D'; VK_HOME : S := 'H';
      Else
        S := 'F';
      End;
      If M <> '' Then S := #27'[1' + M + S
      Else If T.AppCursor Then S := #27'O' + S
      Else S := #27'[' + S;
    End;
    VK_INSERT : S := #27'[2' + M + '~';
    VK_DELETE : S := #27'[3' + M + '~';
    VK_PRIOR : S := #27'[5' + M + '~';
    VK_NEXT : S := #27'[6' + M + '~';
    VK_F1 : If M = '' Then S := #27'OP' Else S := #27'[1' + M + 'P';
    VK_F2 : If M = '' Then S := #27'OQ' Else S := #27'[1' + M + 'Q';
    VK_F3 : If M = '' Then S := #27'OR' Else S := #27'[1' + M + 'R';
    VK_F4 : If M = '' Then S := #27'OS' Else S := #27'[1' + M + 'S';
    VK_F5 : S := #27'[15' + M + '~';
    VK_F6 : S := #27'[17' + M + '~';
    VK_F7 : S := #27'[18' + M + '~';
    VK_F8 : S := #27'[19' + M + '~';
    VK_F9 : S := #27'[20' + M + '~';
    VK_F10 : S := #27'[21' + M + '~';
    VK_F11 : S := #27'[23' + M + '~';
    VK_F12 : S := #27'[24' + M + '~';
  End;
  TmKey := S;
End;
{ ==================================================================== }
{ Fichiers XML : sessions.xml, macros.xml, settings.xml ; cles d'hote   }
{ connues (knownhosts.txt, commun avec le Client FTP)                   }
{ ==================================================================== }

Const
  MaxDef = 200;
  MaxMacro = 60;
  MaxFolder = 40;

Type
  TSessDef = Record
    Name, Folder, Host, User, Pass, Cmd, Comment, TermName : String;
    Port : LongInt;
    SavePw : Boolean;
  End;
  TDefArr = Array[0..MaxDef - 1] Of TSessDef;
  PDefArr = ^TDefArr;
  TMacro = Record
    Name, Keys : String;                  { Keys : octets envoyes }
  End;

Var
  Defs : PDefArr;
  DefN : LongInt;
  Folders : Array[0..MaxFolder - 1] Of String;   { dossiers (meme vides) }
  FolderOpen : Array[0..MaxFolder - 1] Of Boolean;
  FolderN : LongInt;
  Macros : Array[0..MaxMacro - 1] Of TMacro;
  MacroN : LongInt;
  { parametres }
  OptScheme, OptHist, OptKeepAlive, OptPanelTab : LongInt;
  OptCopySel, OptRightPaste, OptBsDel, OptAutoSftp, OptSftpSwitch,
  OptBanner, OptPanel, OptToolbar, OptStatus, OptBell : Boolean;
  OptTerm, OptDlDir, OptLastUser : String;
  XBufA : TlPtr;
  XLen : LongInt;
  XOut : TlPtr;
  XOutN : LongInt;

Procedure DefClear(Var D : TSessDef);
Begin
  D.Name := ''; D.Folder := ''; D.Host := ''; D.User := ''; D.Pass := '';
  D.Cmd := ''; D.Comment := ''; D.TermName := 'xterm';
  D.Port := 22; D.SavePw := False;
End;

Procedure OptDefaults;
Begin
  OptScheme := 0; OptHist := 1000; OptKeepAlive := 60; OptPanelTab := 0;
  OptCopySel := True; OptRightPaste := False; OptBsDel := True;
  OptAutoSftp := True; OptSftpSwitch := False; OptBanner := True;
  OptPanel := True; OptToolbar := True; OptStatus := True; OptBell := True;
  OptTerm := 'xterm'; OptDlDir := Copy(AppDir, 1, 3); OptLastUser := '';
End;

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

{ macros : octets de controle notes \r \n \t \e \\ \xHH }
Function MacEnc(S : String) : String;
Const Hx : String[16] = '0123456789ABCDEF';
Var R : String; I, C : LongInt;
Begin
  R := '';
  For I := 1 To Length(S) Do
  Begin
    C := Ord(S[I]);
    If C = 13 Then R := R + '\r'
    Else If C = 10 Then R := R + '\n'
    Else If C = 9 Then R := R + '\t'
    Else If C = 27 Then R := R + '\e'
    Else If C = 92 Then R := R + '\\'
    Else If (C < 32) Or (C = 127) Then
      R := R + '\x' + Hx[(C Shr 4) + 1] + Hx[(C And 15) + 1]
    Else R := R + Chr(C);
  End;
  MacEnc := R;
End;

Function MacDec(S : String) : String;
Var R : String; I, V : LongInt;
Begin
  R := ''; I := 1;
  While I <= Length(S) Do
  Begin
    If (S[I] = '\') And (I < Length(S)) Then
    Begin
      Inc(I);
      Case S[I] Of
        'r' : R := R + #13;
        'n' : R := R + #10;
        't' : R := R + #9;
        'e' : R := R + #27;
        'x' :
        Begin
          V := SVal('$' + Copy(S, I + 1, 2));
          If V > 0 Then R := R + Chr(V);
          I := I + 2;
        End;
      Else
        R := R + S[I];
      End;
    End
    Else R := R + S[I];
    Inc(I);
  End;
  MacDec := R;
End;

{ ---- lecture : balises et attributs ---- }

{ valeur de l'attribut Nm dans la balise XBufA[A .. B[ }
Function TagAttr(A, B : LongInt; Nm : String) : String;
Var I, K, N, Q : LongInt; S : String; Ok : Boolean;
Begin
  TagAttr := '';
  N := Length(Nm);
  I := A;
  While I + N + 1 < B Do
  Begin
    Ok := (TlGet(XBufA + I - 1) <= 32) And (TlGet(XBufA + I + N) = 61);
    If Ok Then
      For K := 1 To N Do
        If TlGet(XBufA + I + K - 1) <> Ord(Nm[K]) Then Ok := False;
    If Ok Then
    Begin
      Q := TlGet(XBufA + I + N + 1);
      If (Q = 34) Or (Q = 39) Then
      Begin
        S := '';
        K := I + N + 2;
        While (K < B) And (TlGet(XBufA + K) <> Q) Do
        Begin
          If Length(S) < 255 Then S := S + Chr(TlGet(XBufA + K));
          Inc(K);
        End;
        TagAttr := XmlDecode(S);
        Exit;
      End;
    End;
    Inc(I);
  End;
End;

Function FolderIdx(F : String) : LongInt;
Var I : LongInt;
Begin
  FolderIdx := -1;
  For I := 0 To FolderN - 1 Do
    If UpS(Folders[I]) = UpS(F) Then FolderIdx := I;
End;

Procedure AddFolder(F : String);
Begin
  If (F = '') Or (FolderIdx(F) >= 0) Or (FolderN >= MaxFolder) Then Exit;
  Folders[FolderN] := F; FolderOpen[FolderN] := True;
  Inc(FolderN);
End;

{ parcourt le fichier lu ; Kind 0 sessions, 1 macros, 2 parametres }
Procedure ParseXml(Kind : LongInt);
Var I, A, B, Q : LongInt; Nm, Folder, V : String; Closing : Boolean;
    D : TSessDef;
Begin
  I := 0; Folder := '';
  While I < XLen Do
  Begin
    If TlGet(XBufA + I) <> 60 Then Begin Inc(I); Continue; End;
    A := I + 1;
    { fin de la balise (guillemets respectes) }
    B := A; Q := 0;
    While (B < XLen) And ((TlGet(XBufA + B) <> 62) Or (Q <> 0)) Do
    Begin
      If (TlGet(XBufA + B) = 34) Then Q := 1 - Q;
      Inc(B);
    End;
    I := B + 1;
    Closing := TlGet(XBufA + A) = 47;
    If Closing Then Inc(A);
    Nm := '';
    While (A < B) And (TlGet(XBufA + A) > 32) And (TlGet(XBufA + A) <> 47) Do
    Begin
      If Length(Nm) < 40 Then Nm := Nm + Chr(TlGet(XBufA + A));
      Inc(A);
    End;
    If Nm = 'Folder' Then
    Begin
      If Closing Then Folder := ''
      Else
      Begin
        Folder := TagAttr(A, B, 'name');
        If Kind = 0 Then
        Begin
          AddFolder(Folder);
          If (FolderIdx(Folder) >= 0) And (TagAttr(A, B, 'expanded') = '0') Then
            FolderOpen[FolderIdx(Folder)] := False;
        End;
        If TlGet(XBufA + B - 1) = 47 Then Folder := '';
      End;
    End
    Else If Closing Then
    Else If (Nm = 'Session') And (Kind = 0) And (DefN < MaxDef) Then
    Begin
      DefClear(D);
      D.Name := TagAttr(A, B, 'name');
      D.Folder := Folder;
      D.Host := TagAttr(A, B, 'host');
      V := TagAttr(A, B, 'port');
      If V <> '' Then D.Port := SVal(V);
      If D.Port <= 0 Then D.Port := 22;
      D.User := TagAttr(A, B, 'user');
      V := TagAttr(A, B, 'password');
      If V <> '' Then
      Begin
        D.Pass := U8ToA(StrB64Dec(V));
        D.SavePw := True;
      End;
      D.Cmd := TagAttr(A, B, 'command');
      D.Comment := TagAttr(A, B, 'comment');
      V := TagAttr(A, B, 'terminal');
      If V <> '' Then D.TermName := V;
      If D.Name = '' Then D.Name := D.Host;
      If D.Host <> '' Then
      Begin
        Defs^[DefN] := D;
        Inc(DefN);
      End;
    End
    Else If (Nm = 'Macro') And (Kind = 1) And (MacroN < MaxMacro) Then
    Begin
      Macros[MacroN].Name := TagAttr(A, B, 'name');
      Macros[MacroN].Keys := MacDec(TagAttr(A, B, 'keys'));
      If Macros[MacroN].Name <> '' Then Inc(MacroN);
    End
    Else If (Nm = 'Option') And (Kind = 2) Then
    Begin
      Nm := TagAttr(A, B, 'name'); V := TagAttr(A, B, 'value');
      If Nm = 'ColorScheme' Then OptScheme := SVal(V)
      Else If Nm = 'History' Then OptHist := SVal(V)
      Else If Nm = 'KeepAlive' Then OptKeepAlive := SVal(V)
      Else If Nm = 'PanelTab' Then OptPanelTab := SVal(V)
      Else If Nm = 'CopyOnSelect' Then OptCopySel := V = '1'
      Else If Nm = 'RightClickPaste' Then OptRightPaste := V = '1'
      Else If Nm = 'BackspaceDel' Then OptBsDel := V = '1'
      Else If Nm = 'AutoSftp' Then OptAutoSftp := V = '1'
      Else If Nm = 'SftpSwitch' Then OptSftpSwitch := V = '1'
      Else If Nm = 'Banner' Then OptBanner := V = '1'
      Else If Nm = 'Panel' Then OptPanel := V = '1'
      Else If Nm = 'Toolbar' Then OptToolbar := V = '1'
      Else If Nm = 'StatusBar' Then OptStatus := V = '1'
      Else If Nm = 'Bell' Then OptBell := V = '1'
      Else If Nm = 'Terminal' Then OptTerm := V
      Else If Nm = 'DownloadDir' Then OptDlDir := V
      Else If Nm = 'LastUser' Then OptLastUser := V;
    End;
  End;
End;

Procedure LoadDefs;
Begin
  DefN := 0; FolderN := 0;
  If LoadAll(AppDir + 'sessions.xml') Then ParseXml(0);
End;

{ sessions d'un autre fichier ajoutees ; nombre }
Function ImportDefs(F : String) : LongInt;
Var N : LongInt;
Begin
  N := DefN;
  If LoadAll(F) Then ParseXml(0);
  ImportDefs := DefN - N;
End;

Procedure LoadMacros;
Begin
  MacroN := 0;
  If LoadAll(AppDir + 'macros.xml') Then ParseXml(1)
  Else
  Begin
    { exemples }
    Macros[0].Name := 'Espace disque (df -h)'; Macros[0].Keys := 'df -h'#13;
    Macros[1].Name := 'Processus (top)'; Macros[1].Keys := 'top'#13;
    Macros[2].Name := 'Qui suis-je ?'; Macros[2].Keys := 'whoami; hostname; uptime'#13;
    MacroN := 3;
  End;
End;

Procedure LoadOptions;
Begin
  OptDefaults;
  If LoadAll(AppDir + 'settings.xml') Then ParseXml(2);
  If (OptHist < 0) Or (OptHist > HistMax) Then OptHist := 1000;
  If (OptScheme < 0) Or (OptScheme > 3) Then OptScheme := 0;
End;

{ ---- ecriture ---- }

Procedure XHead(Root : String);
Begin
  XOutN := 0;
  XW('<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>'#13#10);
  XW('<' + Root + ' version="1">'#13#10);
End;

Procedure XSession(Var D : TSessDef; Ind : String);
Begin
  XW(Ind + '<Session name="' + XmlEnc(D.Name) + '" host="' + XmlEnc(D.Host) +
     '" port="' + IStr(D.Port) + '" user="' + XmlEnc(D.User) + '"');
  If D.SavePw And (D.Pass <> '') Then
    XW(' password="' + StrB64Enc(AToU8(D.Pass)) + '"');
  If D.Cmd <> '' Then XW(' command="' + XmlEnc(D.Cmd) + '"');
  If D.TermName <> 'xterm' Then XW(' terminal="' + XmlEnc(D.TermName) + '"');
  If D.Comment <> '' Then XW(' comment="' + XmlEnc(D.Comment) + '"');
  XW(' />'#13#10);
End;

Function SaveDefsTo(F : String) : Boolean;
Var I, K : LongInt;
Begin
  XHead('SshSessions');
  For K := 0 To FolderN - 1 Do
  Begin
    XW(#9'<Folder name="' + XmlEnc(Folders[K]) + '" expanded="' +
       IStr(Ord(FolderOpen[K])) + '">'#13#10);
    For I := 0 To DefN - 1 Do
      If UpS(Defs^[I].Folder) = UpS(Folders[K]) Then XSession(Defs^[I], #9#9);
    XW(#9'</Folder>'#13#10);
  End;
  For I := 0 To DefN - 1 Do
    If FolderIdx(Defs^[I].Folder) < 0 Then XSession(Defs^[I], #9);
  XW('</SshSessions>'#13#10);
  SaveDefsTo := SaveAll(F);
End;

Function SaveDefs : Boolean;
Begin
  SaveDefs := SaveDefsTo(AppDir + 'sessions.xml');
End;

Procedure SaveMacros;
Var I : LongInt;
Begin
  XHead('SshMacros');
  For I := 0 To MacroN - 1 Do
    XW(#9'<Macro name="' + XmlEnc(Macros[I].Name) + '" keys="' +
       XmlEnc(MacEnc(Macros[I].Keys)) + '" />'#13#10);
  XW('</SshMacros>'#13#10);
  If SaveAll(AppDir + 'macros.xml') Then;
End;

Procedure XOpt(Nm, V : String);
Begin
  XW(#9'<Option name="' + Nm + '" value="' + XmlEnc(V) + '" />'#13#10);
End;

Procedure SaveOptions;
Begin
  XHead('SshSettings');
  XOpt('ColorScheme', IStr(OptScheme));
  XOpt('History', IStr(OptHist));
  XOpt('KeepAlive', IStr(OptKeepAlive));
  XOpt('PanelTab', IStr(OptPanelTab));
  XOpt('CopyOnSelect', IStr(Ord(OptCopySel)));
  XOpt('RightClickPaste', IStr(Ord(OptRightPaste)));
  XOpt('BackspaceDel', IStr(Ord(OptBsDel)));
  XOpt('AutoSftp', IStr(Ord(OptAutoSftp)));
  XOpt('SftpSwitch', IStr(Ord(OptSftpSwitch)));
  XOpt('Banner', IStr(Ord(OptBanner)));
  XOpt('Panel', IStr(Ord(OptPanel)));
  XOpt('Toolbar', IStr(Ord(OptToolbar)));
  XOpt('StatusBar', IStr(Ord(OptStatus)));
  XOpt('Bell', IStr(Ord(OptBell)));
  XOpt('Terminal', OptTerm);
  XOpt('DownloadDir', OptDlDir);
  XOpt('LastUser', OptLastUser);
  XW('</SshSettings>'#13#10);
  If SaveAll(AppDir + 'settings.xml') Then;
End;

{ ---- cles d'hote ---- }

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
Var I, St, K, N : LongInt; L : String; Same : Boolean;
Begin
  XOutN := 0;
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
        If Same Then Same := L[N + 1] = ' ';
        If (L <> '') And Not Same Then XW(L + #13#10);
      End;
  End;
  XW(Key + ' ' + Val + #13#10);
  If SaveAll(AppDir + 'knownhosts.txt') Then;
End;
{ ==================================================================== }
{ Sessions : taches reseau du terminal et du navigateur SFTP            }
{ ==================================================================== }

Const
  MaxSess = 8;
  InMax = 131072;                       { octets recus en attente }
  OutMax = 16384;                       { frappes a envoyer }
  StNone = 0; StConn = 1; StOpen = 2; StEnded = 3; StFailed = 4;
  FsNone = 0; FsConn = 1; FsReady = 2; FsBusy = 3; FsFailed = 4;
  FcList = 1; FcGet = 2; FcPut = 3; FcMkdir = 4; FcDelete = 5;
  FcRename = 6; FcCd = 7;

Type
  TSess = Record
    Used : Boolean;
    Def : TSessDef;
    Title : String;
    State : LongInt;
    Err : String;
    Ctx, FCtx : TCtx;
    Term : TTerm;
    InBuf : TlPtr;
    InLen : LongInt;
    InPosted : Boolean;
    OutBuf : TlPtr;
    OutLen : LongInt;
    WantCols, WantRows : LongInt;
    ResizeReq, CloseReq, ThreadOn : Boolean;
    Gen : LongInt;
    HostFp : String;
    { SFTP }
    FState : LongInt;
    FErr, FCwd, FMsg : String;
    FList : PEntArr;
    FN : LongInt;
    FCmd : LongInt;
    FArg1, FArg2 : String;
    FThreadOn, FCancel, FPosted : Boolean;
    FDone, FTotal : Double;
    FEv : LongInt;
    FLast : LongInt;
  End;
  TSessArr = Array[0..MaxSess - 1] Of TSess;
  PSessArr = ^TSessArr;

Var
  Sess : PSessArr;
  Active : LongInt;                     { onglet affiche (-1 : accueil) }
  TermWnd : LongInt;
  TermCols, TermRows : LongInt;
  AppQuit : Boolean;

{ session de la tache courante et nature de sa connexion }
Function MySess(Var Sftp : Boolean) : LongInt;
Var C : PCtx; O : LongInt;
Begin
  MySess := -1; Sftp := False;
  C := CurCtx;
  If C = Nil Then Exit;
  O := C^.Owner;
  If O >= 100 Then Begin Sftp := True; O := O - 100; End;
  MySess := O;
End;

Procedure PostTerm(I : LongInt);
Begin
  If Not Sess^[I].InPosted Then
  Begin
    Sess^[I].InPosted := True;
    Dummy := WinPostMsg(MainWnd, EvTermData, I, 0);
  End;
End;

{ octets pour le terminal (tache reseau, verrou tenu) }
Procedure TermPut(I : LongInt; A : TlPtr; N : LongInt);
Var D : LongInt;
Begin
  While Sess^[I].InLen + N > InMax Do
  Begin
    { l'interface n'a pas encore tout affiche : attendre }
    PostTerm(I);
    D := LockDepthRelease;
    Dummy0 := DosSleep(20);
    LockDepthRestore(D);
    If AppQuit Or Not Sess^[I].Used Then Exit;
  End;
  CopyB(A, Sess^[I].InBuf + Sess^[I].InLen, N);
  Sess^[I].InLen := Sess^[I].InLen + N;
  PostTerm(I);
End;

Procedure TermIn(A : TlPtr; N : LongInt);
Var I : LongInt; F : Boolean;
Begin
  I := MySess(F);
  If (I < 0) Or F Then Exit;
  TermPut(I, A, N);
End;

{ texte (ANSI) ecrit dans le terminal de la session I }
Procedure TermSay(I : LongInt; S : String);
Begin
  S := AToU8(S);
  If S <> '' Then TermPut(I, TlPtr(@S[1]), Length(S));
End;

Procedure LogMsg(Kind : LongInt; S : String);
Var I : LongInt; F : Boolean;
Begin
  I := MySess(F);
  If I < 0 Then Exit;
  If F Then
  Begin
    Sess^[I].FMsg := S;
    Dummy := WinPostMsg(MainWnd, EvSftpState, I, 0);
    Exit;
  End;
  Case Kind Of
    LgError : TermSay(I, #27'[1;31m' + S + #27'[0m'#13#10);
    LgReply : If OptBanner Then
                TermSay(I, #27'[0;36m' + S + #27'[0m'#13#10);
  Else
    TermSay(I, #27'[1;30m' + S + #27'[0m'#13#10);
  End;
End;

Procedure PostState(I : LongInt);
Begin
  Dummy := WinPostMsg(MainWnd, EvSessState, I, 0);
End;

{ cle d'hote inconnue ou changee : 2 toujours, 1 cette fois, 0 non. La
  question est posee par la tache de l'interface (EvHostAsk) : la tache
  reseau attend sa reponse, verrou libere. }
Var
  HaS1, HaS2 : String;
  HaPending : Boolean;
  HaRes : LongInt;

Function HostAsk(Fp, Alg : String; Changed : Boolean) : LongInt;
Var I, R, D : LongInt; F : Boolean; S : String;
Begin
  I := MySess(F);
  If (I >= 0) And (Sess^[I].HostFp = Fp) Then
  Begin
    HostAsk := 1;
    Exit;
  End;
  { une seule question a la fois }
  While HaPending And Not AppQuit Do
  Begin
    D := LockDepthRelease;
    Dummy0 := DosSleep(50);
    LockDepthRestore(D);
  End;
  If Changed Then
    S := 'ATTENTION : la cl'#233' d''h'#244'te du serveur a CHANG'#201' depuis la ' +
         'derni'#232're connexion. Il peut s''agir d''une attaque.'
  Else
    S := 'La cl'#233' d''h'#244'te du serveur est inconnue. Vous n''avez aucune ' +
         'garantie que le serveur est bien l''ordinateur que vous pensez.';
  HaS1 := S + '||Serveur : ' + SsHost + ':' + IStr(SsPort) + '|Type de cl'#233' : ' + Alg + '|';
  HaS2 := 'Empreinte :|' + Fp + '||Faire confiance '#224' cet h'#244'te ?||' +
          'Oui : toujours|Non : cette fois seulement|Annuler : ne pas se connecter';
  HaRes := IDCANCEL;
  HaPending := True;
  Dummy0 := WinPostMsg(MainWnd, EvHostAsk, 0, 0);
  D := LockDepthRelease;
  While HaPending And Not AppQuit Do Dummy0 := DosSleep(50);
  LockDepthRestore(D);
  HaPending := False;
  R := HaRes;
  If R = IDYES Then HostAsk := 2
  Else If R = IDNO Then HostAsk := 1
  Else HostAsk := 0;
  If (I >= 0) And ((R = IDYES) Or (R = IDNO)) Then Sess^[I].HostFp := Fp;
End;

{ progression SFTP (bloc transfere) }
Procedure XferStep;
Var I, D, T : LongInt; F : Boolean;
Begin
  I := MySess(F);
  If (I < 0) Or Not F Then Exit;
  Sess^[I].FDone := XfDone;
  If Sess^[I].FCancel Or AppQuit Then XfCancel := True;
  T := MsCount;
  If T - Sess^[I].FLast > 250 Then
  Begin
    Sess^[I].FLast := T;
    Dummy := WinPostMsg(MainWnd, EvSftpState, I, 1);
    D := LockDepthRelease;
    Dummy0 := DosSleep(20);
    LockDepthRestore(D);
  End;
End;

{ ---- tache du terminal ---- }

{ tache (DosCreateThread) : P = numero de la session }
Function TermThread(P : LongInt) : LongInt;
Var I, G, N, Ka : LongInt; Ok, Up : Boolean;
    Buf : Array[0..4095] Of Byte;
Begin
  TermThread := 0;
  I := P;
  Dummy := TlsSet(TlsIdx, LongInt(@Sess^[I].Ctx));
  BigLock;
  G := Sess^[I].Gen;
  SsHost := Sess^[I].Def.Host; SsPort := Sess^[I].Def.Port;
  SsUser := Sess^[I].Def.User; SsPass := Sess^[I].Def.Pass;
  Ok := SsConnect(False);
  If Ok Then
  Begin
    Sess^[I].ResizeReq := False;
    Ok := ShShell(Sess^[I].WantCols, Sess^[I].WantRows,
                  Sess^[I].Def.TermName, Sess^[I].Def.Cmd);
  End;
  If Not Ok Then
  Begin
    Sess^[I].Err := SsErr;
    If SsErr <> '' Then LogMsg(LgError, SsErr);
    SsClose;
    Sess^[I].State := StFailed;
    TermSay(I, #13#10#27'[0;33mConnexion impossible. Appuyez sur R pour ' +
            'recommencer ou sur Entr'#233'e pour fermer l''onglet.'#27'[0m'#13#10);
    Sess^[I].ThreadOn := False;
    PostState(I);
    BigUnlock;
    TlsSet(TlsIdx, 0);
    Exit;
  End;
  Sess^[I].State := StOpen;
  PostState(I);
  Ka := MsCount;
  Repeat
    If AppQuit Or Not Sess^[I].Used Or Sess^[I].CloseReq Or
       (Sess^[I].Gen <> G) Then Break;
    Up := False;
    { frappes }
    If Sess^[I].OutLen > 0 Then
    Begin
      N := MinI(Sess^[I].OutLen, 4096);
      CopyB(Sess^[I].OutBuf, TlPtr(@Buf[0]), N);
      CopyB(Sess^[I].OutBuf + N, Sess^[I].OutBuf, Sess^[I].OutLen - N);
      Sess^[I].OutLen := Sess^[I].OutLen - N;
      If Not ShWrite(TlPtr(@Buf[0]), N) Then Break;
      Up := True;
    End;
    If Sess^[I].ResizeReq Then
    Begin
      Sess^[I].ResizeReq := False;
      If Not ShWinChange(Sess^[I].WantCols, Sess^[I].WantRows) Then Break;
      Up := True;
    End;
    If Up Then Ka := MsCount
    Else If (OptKeepAlive > 0) And
            (MsCount - Ka > OptKeepAlive * 1000) Then
    Begin
      If Not ShKeepAlive Then Break;
      Ka := MsCount;
    End;
    If Sess^[I].OutLen = 0 Then
      If NetReadable(SsSock, 30) Then
      Begin
        If Not ShPump Then Break;
        Ka := MsCount;
      End;
    If ShEnded Then Break;
  Until False;
  If (Sess^[I].Gen = G) And Sess^[I].Used Then
  Begin
    If ShEnded Then
    Begin
      If ShExit >= 0 Then
        TermSay(I, #13#10#27'[0;33mSession termin'#233'e (code de sortie ' +
                IStr(ShExit) + ').')
      Else TermSay(I, #13#10#27'[0;33mSession termin'#233'e.');
    End
    Else If Not Sess^[I].CloseReq Then
    Begin
      If SsErr = '' Then SsErr := 'Connexion perdue.';
      TermSay(I, #13#10#27'[1;31m' + SsErr);
    End;
    If Not Sess^[I].CloseReq Then
      TermSay(I, ' Appuyez sur Entr'#233'e pour fermer l''onglet ou sur R ' +
              'pour relancer la session.'#27'[0m'#13#10);
    Sess^[I].State := StEnded;
    Sess^[I].FCancel := True;
  End;
  SsClose;
  Sess^[I].ThreadOn := False;
  PostState(I);
  BigUnlock;
  TlsSet(TlsIdx, 0);
End;

{ ---- tache du navigateur SFTP ---- }

Procedure SftpList(I : LongInt);
Var N : LongInt;
Begin
  N := 0;
  If SfList(Sess^[I].FList, N) Then
  Begin
    Sess^[I].FN := N;
    Sess^[I].FCwd := SsCwd;
    Sess^[I].FErr := '';
  End
  Else Sess^[I].FErr := SsErr;
  Dummy := WinPostMsg(MainWnd, EvSftpList, I, 0);
End;

Function SftpThread(P : LongInt) : LongInt;
Var I, G, C, D, Ka, Ka0 : LongInt; A1, A2 : String; Ok : Boolean;
Begin
  SftpThread := 0;
  I := P;
  Dummy := TlsSet(TlsIdx, LongInt(@Sess^[I].FCtx));
  BigLock;
  G := Sess^[I].Gen;
  Sess^[I].FState := FsConn;
  Sess^[I].FMsg := 'Connexion SFTP '#224' ' + Sess^[I].Def.Host + '...';
  Dummy := WinPostMsg(MainWnd, EvSftpState, I, 0);
  SsHost := Sess^[I].Def.Host; SsPort := Sess^[I].Def.Port;
  SsUser := Sess^[I].Def.User; SsPass := Sess^[I].Def.Pass;
  If Not SsConnect(True) Then
  Begin
    Sess^[I].FErr := SsErr;
    Sess^[I].FState := FsFailed;
    Sess^[I].FThreadOn := False;
    Dummy := WinPostMsg(MainWnd, EvSftpState, I, 0);
    BigUnlock;
    TlsSet(TlsIdx, 0);
    Exit;
  End;
  Sess^[I].FState := FsBusy;
  SftpList(I);
  Sess^[I].FState := FsReady;
  Dummy := WinPostMsg(MainWnd, EvSftpState, I, 0);
  Ka := MsCount;
  Repeat
    If AppQuit Or Not Sess^[I].Used Or (Sess^[I].Gen <> G) Or
       (Sess^[I].State = StEnded) Or (Sess^[I].State = StFailed) Then Break;
    C := Sess^[I].FCmd;
    If C = 0 Then
    Begin
      If (OptKeepAlive > 0) And (MsCount - Ka > OptKeepAlive * 1000) Then
      Begin
        If Not ShKeepAlive Then Break;
        Ka := MsCount;
      End;
      D := LockDepthRelease;
      { semaphore d'evenement : commande de l'interface (500 ms au plus) }
      Dummy := DosWaitEventSem(Sess^[I].FEv, 500);
      Dummy := DosResetEventSem(Sess^[I].FEv, LongInt(@Ka0));
      LockDepthRestore(D);
      Continue;
    End;
    A1 := Sess^[I].FArg1; A2 := Sess^[I].FArg2;
    Sess^[I].FCmd := 0;
    Sess^[I].FState := FsBusy; Sess^[I].FCancel := False;
    Sess^[I].FDone := 0;
    Dummy := WinPostMsg(MainWnd, EvSftpState, I, 0);
    Ok := True;
    Case C Of
      FcCd : Ok := SsCd(A1);
      FcGet :
      Begin
        Sess^[I].FMsg := 'T'#233'l'#233'chargement de ' + BaseOf(A1) + '...';
        Ok := SsGet(A1, A2);
        If Ok Then Sess^[I].FMsg := BaseOf(A1) + ' t'#233'l'#233'charg'#233' dans ' + A2;
      End;
      FcPut :
      Begin
        Sess^[I].FMsg := 'Envoi de ' + BaseOf(A1) + '...';
        Ok := SsPut(A1, A2);
        If Ok Then Sess^[I].FMsg := BaseOf(A1) + ' envoy'#233'.';
      End;
      FcMkdir : Ok := SsOp(1, A1);
      FcDelete : If A2 = '1' Then Ok := SsOp(2, A1) Else Ok := SsOp(3, A1);
      FcRename : Ok := SsRename(A1, A2);
    End;
    If SsLost Or (SsSock < 0) Then Break;
    If Not Ok Then Sess^[I].FErr := SsErr Else Sess^[I].FErr := '';
    If Not Ok And (Sess^[I].FErr <> '') Then
      Sess^[I].FMsg := 'Erreur : ' + Sess^[I].FErr;
    { liste a jour apres chaque operation }
    If C <> FcGet Then
    Begin
      A1 := Sess^[I].FErr;
      SftpList(I);
      If A1 <> '' Then Begin Sess^[I].FErr := A1; Sess^[I].FMsg := 'Erreur : ' + A1; End;
    End;
    Sess^[I].FState := FsReady;
    Dummy := WinPostMsg(MainWnd, EvSftpState, I, 0);
    Ka := MsCount;
  Until False;
  SsClose;
  If Sess^[I].Gen = G Then
  Begin
    If Sess^[I].FState <> FsFailed Then Sess^[I].FState := FsNone;
    Sess^[I].FN := 0;
  End;
  Sess^[I].FThreadOn := False;
  Dummy := WinPostMsg(MainWnd, EvSftpState, I, 0);
  BigUnlock;
  TlsSet(TlsIdx, 0);
End;

{ ---- depuis l'interface (verrou tenu) ---- }

Procedure SendKeys(I : LongInt; S : String);
Var K : LongInt;
Begin
  If (I < 0) Or Not Sess^[I].Used Or (Sess^[I].State <> StOpen) Then Exit;
  For K := 1 To Length(S) Do
    If Sess^[I].OutLen < OutMax Then
    Begin
      TlPut(Sess^[I].OutBuf + Sess^[I].OutLen, Ord(S[K]));
      Inc(Sess^[I].OutLen);
    End;
End;

Procedure StartThread(I : LongInt);
Var Tid : LongInt;
Begin
  Inc(Sess^[I].Gen);
  CtxReset(@Sess^[I].Ctx, I);
  Sess^[I].State := StConn;
  Sess^[I].Err := '';
  Sess^[I].OutLen := 0;
  Sess^[I].CloseReq := False;
  Sess^[I].ThreadOn := True;
  Sess^[I].FCancel := False;
  Sess^[I].WantCols := TermCols; Sess^[I].WantRows := TermRows;
  Tid := 0;
  If DosCreateThread(LongInt(@Tid), LongInt(@TermThread), I, 0, 262144) <> 0 Then
  Begin
    Sess^[I].ThreadOn := False;
    Sess^[I].State := StFailed;
  End;
End;

Procedure StartSftp(I : LongInt);
Var Tid : LongInt;
Begin
  If Sess^[I].FThreadOn Or (Sess^[I].State <> StOpen) Then Exit;
  CtxReset(@Sess^[I].FCtx, 100 + I);
  If Sess^[I].FList = Nil Then Sess^[I].FList := PEntArr(TlNew(SizeOf(TEntArr)));
  If Sess^[I].FEv = 0 Then Dummy := DosCreateEventSem(0, LongInt(@Sess^[I].FEv), 0, 0);
  Sess^[I].FThreadOn := True;
  Sess^[I].FCmd := 0; Sess^[I].FErr := '';
  Tid := 0;
  If DosCreateThread(LongInt(@Tid), LongInt(@SftpThread), I, 0, 262144) <> 0 Then
    Sess^[I].FThreadOn := False;
End;

Procedure SftpCmd(I, C : LongInt; A1, A2 : String);
Begin
  If (I < 0) Or Not Sess^[I].FThreadOn Then Exit;
  Sess^[I].FArg1 := A1; Sess^[I].FArg2 := A2;
  Sess^[I].FCmd := C;
  Dummy := DosPostEventSem(Sess^[I].FEv);
End;
{ ==================================================================== }
{ Utilitaires : presse-papiers, boites Ouvrir / Enregistrer, icones     }
{ ==================================================================== }

Const
  { icones 16 x 16 }
  IcComputer = 1; IcFolder = 2; IcFolderOpen = 3; IcTerm = 4; IcDos = 5;
  IcTask = 6; IcInfo = 7; IcControl = 8; IcNote = 9; IcCalc = 10;
  IcChar = 11; IcAscii = 12; IcKey = 13; IcFtp = 14; IcRdp = 15; IcWeb = 16;
  IcMacro = 17; IcFile = 18; IcDir = 19; IcUp = 20; IcLink = 21; IcRec = 22;

Var
  TermFnt : LongInt;
  ClipBuf : TlPtr;                      { texte copie ou colle (64 Ko) }
  CopyBufA : TlPtr;                     { texte donne au presse-papiers }

Function HexB(V : LongInt) : String;
Const Hx : String[16] = '0123456789ABCDEF';
Begin
  HexB := Hx[((V Shr 4) And 15) + 1] + Hx[(V And 15) + 1];
End;

{ octets (page de l'ecran) dans le presse-papiers de PM (CF_TEXT ; avec
  CFI_POINTER, PM garde sa propre copie du texte) }
Procedure CopyBytes(A : TlPtr; N : LongInt);
Var P, I : LongInt;
Begin
  If CopyBufA = 0 Then CopyBufA := TlNew(65536 + 16);
  P := CopyBufA;
  If P = 0 Then Exit;
  If N > 65536 Then N := 65536;
  For I := 0 To N - 1 Do TlPut(P + I, TlGet(A + I));
  TlPut(P + N, 0);
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    Dummy := WinSetClipbrdData(Hab, P, 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
End;

Procedure CopyText(S : String);
Begin
  S := Disp(S);
  If S <> '' Then CopyBytes(TlPtr(@S[1]), Length(S));
End;

{ texte du presse-papiers (CF_TEXT) dans ClipBuf ; longueur }
Function ClipGet : LongInt;
Var P, N : LongInt;
Begin
  ClipGet := 0;
  If ClipBuf = 0 Then ClipBuf := TlNew(65536);
  If WinOpenClipbrd(Hab) = 0 Then Exit;
  P := WinQueryClipbrdData(Hab, 1);
  N := 0;
  If P <> 0 Then
    While (N < 65535) And (TlGet(P + N) <> 0) Do
    Begin
      TlPut(ClipBuf + N, TlGet(P + N));
      Inc(N);
    End;
  Dummy := WinCloseClipbrd(Hab);
  ClipGet := N;
End;

{ ---- icones dessinees (16 x 16) ---- }

Procedure Box(Dc, X1, Y1, X2, Y2, Frame, Fill : LongInt);
Begin
  Bar(Dc, X1, Y1, X2, Y2, Frame);
  Bar(Dc, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, Fill);
End;

Procedure Icon16(Dc, K, X, Y : LongInt);
Begin
  Case K Of
    IcComputer :
    Begin
      Box(Dc, X + 1, Y + 1, X + 15, Y + 11, ClrBlack, ClrShadow);
      Bar(Dc, X + 3, Y + 3, X + 13, Y + 9, ClrTeal);
      Bar(Dc, X + 5, Y + 11, X + 11, Y + 13, ClrShadow);
      Bar(Dc, X + 2, Y + 13, X + 14, Y + 15, ClrBlack);
    End;
    IcFolder, IcFolderOpen, IcDir :
    Begin
      Box(Dc, X + 1, Y + 3, X + 7, Y + 6, ClrBlack, ClrYellow);
      Box(Dc, X + 1, Y + 5, X + 15, Y + 14, ClrBlack, ClrYellow);
      If K = IcFolderOpen Then
        Box(Dc, X + 3, Y + 8, X + 16, Y + 14, ClrBlack, $80FFFF);
    End;
    IcTerm, IcDos :
    Begin
      Box(Dc, X + 1, Y + 2, X + 15, Y + 14, ClrBlack, ClrBlack);
      If K = IcTerm Then Bar(Dc, X + 1, Y + 2, X + 15, Y + 4, ClrNavy)
      Else Bar(Dc, X + 1, Y + 2, X + 15, Y + 4, ClrShadow);
      Bar(Dc, X + 3, Y + 6, X + 5, Y + 7, ClrHi); Bar(Dc, X + 5, Y + 7, X + 6, Y + 8, ClrHi);
      Bar(Dc, X + 3, Y + 8, X + 5, Y + 9, ClrHi);
      Bar(Dc, X + 7, Y + 9, X + 11, Y + 10, ClrHi);
    End;
    IcTask :
    Begin
      Box(Dc, X + 1, Y + 1, X + 15, Y + 15, ClrBlack, ClrBlack);
      Bar(Dc, X + 3, Y + 10, X + 5, Y + 13, ClrGreen);
      Bar(Dc, X + 6, Y + 6, X + 8, Y + 13, $00FF00);
      Bar(Dc, X + 9, Y + 8, X + 11, Y + 13, ClrGreen);
      Bar(Dc, X + 12, Y + 4, X + 14, Y + 13, $00FF00);
    End;
    IcInfo :
    Begin
      Box(Dc, X + 2, Y + 1, X + 14, Y + 15, ClrNavy, ClrBlue);
      Bar(Dc, X + 7, Y + 3, X + 9, Y + 5, ClrHi);
      Bar(Dc, X + 7, Y + 6, X + 9, Y + 13, ClrHi);
    End;
    IcControl :
    Begin
      Box(Dc, X + 1, Y + 2, X + 15, Y + 14, ClrBlack, ClrFace);
      Bar(Dc, X + 3, Y + 4, X + 7, Y + 8, ClrRed); Bar(Dc, X + 9, Y + 4, X + 13, Y + 8, ClrGreen);
      Bar(Dc, X + 3, Y + 9, X + 7, Y + 13, ClrBlue); Bar(Dc, X + 9, Y + 9, X + 13, Y + 13, ClrYellow);
    End;
    IcNote, IcFile :
    Begin
      Box(Dc, X + 3, Y + 1, X + 13, Y + 15, ClrBlack, ClrWin);
      If K = IcNote Then
      Begin
        Bar(Dc, X + 5, Y + 4, X + 11, Y + 5, ClrNavy); Bar(Dc, X + 5, Y + 7, X + 11, Y + 8, ClrNavy);
        Bar(Dc, X + 5, Y + 10, X + 10, Y + 11, ClrNavy);
      End
      Else
      Begin
        Bar(Dc, X + 5, Y + 4, X + 11, Y + 5, ClrShadow); Bar(Dc, X + 5, Y + 7, X + 11, Y + 8, ClrShadow);
      End;
    End;
    IcCalc :
    Begin
      Box(Dc, X + 3, Y + 1, X + 13, Y + 15, ClrBlack, ClrShadow);
      Bar(Dc, X + 5, Y + 3, X + 11, Y + 6, $C0FFC0);
      Bar(Dc, X + 5, Y + 8, X + 7, Y + 10, ClrHi); Bar(Dc, X + 9, Y + 8, X + 11, Y + 10, ClrHi);
      Bar(Dc, X + 5, Y + 11, X + 7, Y + 13, ClrHi); Bar(Dc, X + 9, Y + 11, X + 11, Y + 13, ClrRed);
    End;
    IcChar, IcAscii :
    Begin
      Box(Dc, X + 1, Y + 1, X + 15, Y + 15, ClrBlack, ClrWin);
      Bar(Dc, X + 5, Y + 1, X + 6, Y + 15, ClrShadow); Bar(Dc, X + 10, Y + 1, X + 11, Y + 15, ClrShadow);
      Bar(Dc, X + 1, Y + 5, X + 15, Y + 6, ClrShadow); Bar(Dc, X + 1, Y + 10, X + 15, Y + 11, ClrShadow);
      If K = IcAscii Then Bar(Dc, X + 6, Y + 6, X + 10, Y + 10, ClrNavy)
      Else Bar(Dc, X + 2, Y + 2, X + 5, Y + 5, ClrRed);
    End;
    IcKey :
    Begin
      Box(Dc, X + 1, Y + 4, X + 7, Y + 10, ClrBlack, ClrYellow);
      Bar(Dc, X + 3, Y + 6, X + 5, Y + 8, ClrBlack);
      Bar(Dc, X + 7, Y + 6, X + 15, Y + 8, ClrOlive);
      Bar(Dc, X + 11, Y + 8, X + 13, Y + 11, ClrOlive); Bar(Dc, X + 14, Y + 8, X + 15, Y + 10, ClrOlive);
    End;
    IcFtp :
    Begin
      Box(Dc, X + 1, Y + 3, X + 15, Y + 14, ClrBlack, ClrYellow);
      Bar(Dc, X + 4, Y + 5, X + 6, Y + 12, ClrGreen); Bar(Dc, X + 3, Y + 6, X + 7, Y + 7, ClrGreen);
      Bar(Dc, X + 10, Y + 5, X + 12, Y + 12, ClrBlue); Bar(Dc, X + 9, Y + 10, X + 13, Y + 11, ClrBlue);
    End;
    IcRdp :
    Begin
      Box(Dc, X + 4, Y + 1, X + 15, Y + 9, ClrBlack, ClrBlue);
      Box(Dc, X + 1, Y + 6, X + 11, Y + 14, ClrBlack, ClrTeal);
    End;
    IcWeb :
    Begin
      Box(Dc, X + 2, Y + 2, X + 14, Y + 14, ClrNavy, ClrBlue);
      Bar(Dc, X + 4, Y + 4, X + 8, Y + 8, ClrGreen); Bar(Dc, X + 9, Y + 8, X + 12, Y + 12, ClrGreen);
    End;
    IcMacro :
    Begin
      Box(Dc, X + 1, Y + 2, X + 15, Y + 14, ClrBlack, ClrWin);
      Bar(Dc, X + 5, Y + 4, X + 6, Y + 12, ClrGreen); Bar(Dc, X + 6, Y + 5, X + 8, Y + 11, ClrGreen);
      Bar(Dc, X + 8, Y + 6, X + 10, Y + 10, ClrGreen); Bar(Dc, X + 10, Y + 7, X + 11, Y + 9, ClrGreen);
    End;
    IcUp :
    Begin
      Box(Dc, X + 1, Y + 5, X + 15, Y + 14, ClrBlack, ClrYellow);
      Bar(Dc, X + 7, Y + 2, X + 9, Y + 11, ClrBlack);
      Bar(Dc, X + 5, Y + 4, X + 11, Y + 5, ClrBlack); Bar(Dc, X + 6, Y + 3, X + 10, Y + 4, ClrBlack);
    End;
    IcLink :
    Begin
      Box(Dc, X + 3, Y + 1, X + 13, Y + 15, ClrBlack, ClrWin);
      Box(Dc, X + 1, Y + 9, X + 7, Y + 15, ClrBlack, ClrWin);
      Bar(Dc, X + 3, Y + 11, X + 5, Y + 13, ClrBlue);
    End;
    IcRec :
    Begin
      Box(Dc, X + 3, Y + 3, X + 13, Y + 13, ClrMaroon, ClrRed);
    End;
  End;
End;
{ ==================================================================== }
{ Boites de dialogue                                                    }
{ ==================================================================== }

Const
  DkInput = 1; DkSess = 2; DkConf = 3; DkMacro = 4; DkAscii = 5; DkPass = 6;
  DkFile = 7;
  IdInput = 100;
  IdName = 101; IdHost = 102; IdPort = 103; IdUser = 104; IdPass = 105;
  IdSavePw = 106; IdFolder = 107; IdCmd = 108; IdTerm = 109; IdComment = 110;
  IdScheme = 111;                       { 111 a 114 }
  IdHist = 115; IdCopySel = 116; IdRPaste = 117; IdBsDel = 118; IdBell = 119;
  IdKeep = 120; IdBanner = 121; IdAutoSftp = 122; IdSftpSw = 123;
  IdDlDir = 124; IdTermT = 125;
  IdMName = 126; IdMKeys = 127;
  IdPLen = 130; IdPUp = 131; IdPLow = 132; IdPDig = 133; IdPSym = 134;
  IdPOut = 135; IdPGen = 136; IdPCopy = 137;
  IdAsciiInfo = 138;
  IdFName = 141; IdFDir = 142; IdFList = 143;

Var
  DlgWnd, DlgFrm, DlgKind, DlgRes, DlgH : LongInt;
  DlgDone, DlgSc : Boolean;
  DlgText, DlgText2 : String;
  DCtl : Array[100..150] Of LongInt;
  AsciiSel : LongInt;

{ les boites de Pasdows sont faites pour la police 6 x 13 ; les controles
  de PM ecrivent avec la police 8 x 16 : coordonnees agrandies }
Function SX(X : LongInt) : LongInt;
Begin
  If DlgSc Then SX := (X * 4) Div 3 Else SX := X;
End;

Function SY(Y : LongInt) : LongInt;
Begin
  If DlgSc Then SY := (Y * 23 + 10) Div 20 Else SY := Y;
End;

{ boucle de la boite : la fenetre principale est desactivee ; le verrou
  est libere pendant l'attente des messages }
Procedure ModalLoop;
Var D : LongInt; Q : Boolean;
Begin
  Dummy := WinEnableWindow(Frame, 0);
  Q := False;
  While Not DlgDone Do
  Begin
    D := LockDepthRelease;
    If WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) = 0 Then
    Begin
      LockDepthRestore(D);
      Q := True;
      Break;
    End;
    LockDepthRestore(D);
    Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  End;
  Dummy := WinEnableWindow(Frame, 1);
  If DlgFrm <> 0 Then Dummy := WinDestroyWindow(DlgFrm);
  DlgFrm := 0; DlgWnd := 0;
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := FocusTo(MainWnd);
  If Q Then Dummy := WinPostMsg(0, WM_QUIT, 0, 0);
End;

{ cadre de PM (titre, menu systeme, bordure de boite) et sa zone client
  (classe SSHDLG) ; W x H : zone client (coordonnees de Pasdows) }
Function DlgCreate(Title : String; W, H : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Fl, Fw, Fh, I : LongInt;
Begin
  DlgDone := False; DlgRes := IDCANCEL;
  For I := 100 To 150 Do DCtl[I] := 0;
  W := SX(W); H := SY(H);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DlgWnd := 0;
  PutZ(LongInt(@NameZ2), 'SSHDLG');
  DlgFrm := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), LongInt(@NameZ2), Z(Disp(Title)), 0, 0, 0,
                               LongInt(@DlgWnd));
  If DlgFrm = 0 Then
  Begin
    DlgCreate := 0;
    Exit;
  End;
  Rc[0] := 0; Rc[1] := 0; Rc[2] := W; Rc[3] := H;
  Dummy := WinCalcFrameRect(DlgFrm, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Dummy := WinSetWindowPos(DlgFrm, HWND_TOP,
                           MaxI(0, (WinQuerySysValue(HWND_DESKTOP, SV_CXSCREEN) - Fw) Div 2),
                           MaxI(0, (WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN) - Fh) Div 2),
                           Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER);
  DlgH := WinH(DlgWnd);
  DlgCreate := DlgWnd;
End;

Procedure DlgShow;
Begin
  Dummy := WinShowWindow(DlgFrm, 1);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, DlgFrm);
End;

{ controles de la boite (coordonnees de Pasdows, agrandies) }
Function DCtlMake(Cls : LongInt; S : String; Style, X, Y, W, H, Id : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := MkCtl(DlgWnd, Cls, S, Style, SX(X), SY(Y), SX(W), SY(H), Id);
  If (Id >= 100) And (Id <= 150) Then DCtl[Id] := R;
  DCtlMake := R;
End;

Procedure Lbl(P : LongInt; S : String; X, Y, W : LongInt);
Begin
  Gray(DCtlMake(WC_STATIC, S, SS_TEXT Or DT_VCENTER, X, Y - 1, W, 15, 0));
End;

Function DEdit(Id : LongInt; S : String; X, Y, W : LongInt; Pw : Boolean) : LongInt;
Var St, R : LongInt;
Begin
  St := ES_AUTOSCROLL Or ES_MARGIN Or WS_TABSTOP;
  If Pw Then St := St Or ES_UNREADABLE;
  R := DCtlMake(WC_ENTRYFIELD, '', St, X, Y, W, 20, Id);
  Dummy := WinSendMsg(R, EM_SETTEXTLIMIT, 250, 0);
  SetText(R, S);
  DEdit := R;
End;

Procedure DCheck(Id : LongInt; S : String; X, Y, W : LongInt; On : Boolean);
Var R : LongInt;
Begin
  R := DCtlMake(WC_BUTTON, S, BS_AUTOCHECKBOX Or WS_TABSTOP, X, Y, W, 16, Id);
  Gray(R);
  SetCheck(R, On);
End;

Function DRadio(Id : LongInt; S : String; X, Y, W : LongInt; First : Boolean) : LongInt;
Var St, R : LongInt;
Begin
  St := BS_AUTORADIOBUTTON;
  If First Then St := St Or WS_GROUP Or WS_TABSTOP;
  R := DCtlMake(WC_BUTTON, S, St, X, Y, W, 16, Id);
  Gray(R);
  DRadio := R;
End;

Procedure DGroup(S : String; X, Y, W, H : LongInt);
Begin
  Gray(DCtlMake(WC_STATIC, S, SS_GROUPBOX, X, Y, W, H, 0));
End;

Function DBtn(Id : LongInt; S : String; X, Y, W, H : LongInt; Def : Boolean) : LongInt;
Var St : LongInt;
Begin
  St := BS_PUSHBUTTON Or WS_TABSTOP;
  If Def Then St := St Or BS_DEFAULT;
  DBtn := DCtlMake(WC_BUTTON, S, St, X, Y, W, H, Id);
End;

Procedure DButtons(W, Y : LongInt);
Begin
  Dummy := DBtn(IDOK, 'OK', W - 172, Y, 76, 24, True);
  Dummy := DBtn(IDCANCEL, 'Annuler', W - 88, Y, 76, 24, False);
End;

Function DTxt(Id : LongInt) : String;
Begin
  DTxt := CtlText(DCtl[Id]);
End;

{ ---- saisie d'un texte ---- }

Function InputBox(Title, Prompt : String; Var S : String; Pw : Boolean) : Boolean;
Var E, W : LongInt;
Begin
  InputBox := False;
  DlgKind := DkInput;
  DlgSc := DlgKind <> DkAscii;
  W := MaxI(300, Length(Prompt) * CW + 24);
  If W > 460 Then W := 460;
  If DlgCreate(Title, W, 96) = 0 Then Exit;
  Lbl(DlgWnd, Prompt, 12, 10, W - 24);
  E := DEdit(IdInput, S, 12, 30, W - 24, Pw);
  DButtons(W, 62);
  DlgShow;
  Dummy := FocusTo(E);
  Dummy := WinSendMsg(E, EM_SETSEL, $7FFF Shl 16, 0);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    S := DlgText;
    InputBox := True;
  End;
End;

{ ---- proprietes d'une session ---- }

Var
  EdDef : TSessDef;

Procedure PaintSshTile(Dc : LongInt);
Begin
  { tuile "SSH" choisie, comme la rangee des types de session }
  Bar(Dc, SX(12), SY(10), SX(64), SY(56), ClrWin);
  Thin(Dc, SX(12), SY(10), SX(64), SY(56), False);
  Bar(Dc, SX(26), SY(16), SX(50), SY(34), ClrBlack); Bar(Dc, SX(28), SY(18), SX(48), SY(32), ClrNavy);
  Dummy := SelFont(Dc, TermFnt);
  Txt(Dc, SX(30), SY(18), '>_', ClrHi);
  Bar(Dc, SX(34), SY(34), SX(42), SY(37), ClrShadow);
  Txt(Dc, SX(28), SY(39), 'SSH', ClrBlack);
  Txt(Dc, SX(76), SY(12), 'Session SSH (Secure Shell) :', ClrBlack);
  Txt(Dc, SX(76), SY(30), 'terminal xterm et navigateur SFTP', ClrShadow);
End;

Function EditSession(Title : String; Var D : TSessDef) : Boolean;
Const W = 420;
Begin
  EditSession := False;
  DlgKind := DkSess;
  DlgSc := DlgKind <> DkAscii;
  EdDef := D;
  If DlgCreate(Title, W, 330) = 0 Then Exit;
  DGroup('Param'#232'tres SSH de base', 8, 62, W - 16, 120);
  Lbl(DlgWnd, 'H'#244'te distant :', 18, 84, 90);
  DEdit(IdHost, D.Host, 110, 82, 168, False);
  Lbl(DlgWnd, 'Port :', 290, 84, 40);
  DEdit(IdPort, IStr(D.Port), 330, 82, 70, False);
  Lbl(DlgWnd, 'Utilisateur :', 18, 110, 90);
  DEdit(IdUser, D.User, 110, 108, 168, False);
  Lbl(DlgWnd, 'Mot de passe :', 18, 136, 90);
  DEdit(IdPass, D.Pass, 110, 134, 168, True);
  DCheck(IdSavePw, 'M'#233'moriser', 290, 136, 110, D.SavePw);
  Lbl(DlgWnd, '(vide : demand'#233' '#224' la connexion)', 110, 158, 260);
  DGroup('Param'#232'tres avanc'#233's', 8, 188, W - 16, 100);
  Lbl(DlgWnd, 'Nom :', 18, 208, 90);
  DEdit(IdName, D.Name, 110, 206, 290, False);
  Lbl(DlgWnd, 'Dossier :', 18, 234, 90);
  DEdit(IdFolder, D.Folder, 110, 232, 120, False);
  Lbl(DlgWnd, 'Terminal :', 240, 234, 60);
  DEdit(IdTerm, D.TermName, 300, 232, 100, False);
  Lbl(DlgWnd, 'Commande :', 18, 260, 90);
  DEdit(IdCmd, D.Cmd, 110, 258, 290, False);
  Lbl(DlgWnd, 'Commentaire :', 8, 298, 90);
  DEdit(IdComment, D.Comment, 96, 296, 130, False);
  DButtons(W, 296);
  DlgShow;
  Dummy := FocusTo(DCtl[IdHost]);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    D := EdDef;
    EditSession := True;
  End;
End;

Function SessOk : Boolean;
Begin
  SessOk := False;
  EdDef.Host := TrimS(DTxt(IdHost));
  If EdDef.Host = '' Then
  Begin
    Dummy := Ask('Indiquez l''h'#244'te distant.', 'Session', MB_OK Or MB_ICONINFO);
    Exit;
  End;
  EdDef.Port := SVal(TrimS(DTxt(IdPort)));
  If EdDef.Port <= 0 Then EdDef.Port := 22;
  EdDef.User := TrimS(DTxt(IdUser));
  EdDef.Pass := DTxt(IdPass);
  EdDef.SavePw := Checked(DCtl[IdSavePw]);
  EdDef.Name := TrimS(DTxt(IdName));
  If EdDef.Name = '' Then
  Begin
    EdDef.Name := EdDef.Host;
    If EdDef.User <> '' Then EdDef.Name := EdDef.User + '@' + EdDef.Host;
  End;
  EdDef.Folder := TrimS(DTxt(IdFolder));
  EdDef.TermName := TrimS(DTxt(IdTerm));
  If EdDef.TermName = '' Then EdDef.TermName := 'xterm';
  EdDef.Cmd := TrimS(DTxt(IdCmd));
  EdDef.Comment := DTxt(IdComment);
  SessOk := True;
End;

{ ---- configuration ---- }

Function ConfigBox : Boolean;
Const W = 460;
Var I : LongInt;
Begin
  ConfigBox := False;
  DlgKind := DkConf;
  DlgSc := DlgKind <> DkAscii;
  If DlgCreate('Configuration du Client SSH', W, 380) = 0 Then Exit;
  DGroup('Terminal', 8, 6, W - 16, 170);
  Lbl(DlgWnd, 'Couleurs :', 18, 26, 70);
  Dummy := DRadio(IdScheme, 'Blanc sur noir', 90, 24, 110, True);
  Dummy := DRadio(IdScheme + 1, 'Noir sur blanc', 210, 24, 110, False);
  Dummy := DRadio(IdScheme + 2, 'Vert sur noir', 90, 42, 110, False);
  Dummy := DRadio(IdScheme + 3, 'Ambre sur noir', 210, 42, 110, False);
  For I := 0 To 3 Do SetCheck(DCtl[IdScheme + I], OptScheme = I);
  Lbl(DlgWnd, 'Lignes d''historique :', 18, 68, 130);
  DEdit(IdHist, IStr(OptHist), 150, 66, 60, False);
  Lbl(DlgWnd, 'Type (TERM) :', 230, 68, 90);
  DEdit(IdTermT, OptTerm, 320, 66, 120, False);
  DCheck(IdCopySel, 'Copier le texte s'#233'lectionn'#233' '#224' la souris', 18, 94, 300, OptCopySel);
  DCheck(IdRPaste, 'Le clic droit colle (sinon : menu contextuel)', 18, 112, 300, OptRightPaste);
  DCheck(IdBsDel, 'Retour arri'#232're envoie ^? (DEL), sinon ^H', 18, 130, 300, OptBsDel);
  DCheck(IdBell, 'Signal sonore (BEL)', 18, 148, 300, OptBell);
  DGroup('SSH et SFTP', 8, 182, W - 16, 156);
  Lbl(DlgWnd, 'Maintien de la connexion toutes les', 18, 204, 210);
  DEdit(IdKeep, IStr(OptKeepAlive), 230, 202, 50, False);
  Lbl(DlgWnd, 'secondes (0 : jamais)', 288, 204, 150);
  DCheck(IdBanner, 'Afficher la banni'#232're et la version du serveur', 18, 228, 320, OptBanner);
  DCheck(IdAutoSftp, 'Ouvrir le navigateur SFTP apr'#232's la connexion', 18, 246, 320, OptAutoSftp);
  DCheck(IdSftpSw, 'Basculer automatiquement vers l''onglet SFTP', 18, 264, 320, OptSftpSwitch);
  Lbl(DlgWnd, 'Dossier des t'#233'l'#233'chargements :', 18, 290, 170);
  DEdit(IdDlDir, OptDlDir, 190, 288, 250, False);
  Lbl(DlgWnd, 'Fichiers dans ' + AppDir + ' : sessions.xml, macros.xml, settings.xml', 18, 314, 424);
  DButtons(W, 348);
  DlgShow;
  ModalLoop;
  ConfigBox := DlgRes = IDOK;
End;

Procedure ConfOk;
Var I : LongInt;
Begin
  For I := 0 To 3 Do
    If Checked(DCtl[IdScheme + I]) Then OptScheme := I;
  OptHist := MinI(MaxI(SVal(TrimS(DTxt(IdHist))), 0), HistMax);
  OptTerm := TrimS(DTxt(IdTermT));
  If OptTerm = '' Then OptTerm := 'xterm';
  OptCopySel := Checked(DCtl[IdCopySel]);
  OptRightPaste := Checked(DCtl[IdRPaste]);
  OptBsDel := Checked(DCtl[IdBsDel]);
  OptBell := Checked(DCtl[IdBell]);
  OptKeepAlive := MaxI(SVal(TrimS(DTxt(IdKeep))), 0);
  OptBanner := Checked(DCtl[IdBanner]);
  OptAutoSftp := Checked(DCtl[IdAutoSftp]);
  OptSftpSwitch := Checked(DCtl[IdSftpSw]);
  OptDlDir := TrimS(DTxt(IdDlDir));
  If OptDlDir = '' Then OptDlDir := Copy(AppDir, 1, 3);
End;

{ ---- macro ---- }

Function MacroBox(Title : String; Var Nm, Keys : String) : Boolean;
Const W = 420;
Begin
  MacroBox := False;
  DlgKind := DkMacro;
  DlgSc := DlgKind <> DkAscii;
  If DlgCreate(Title, W, 150) = 0 Then Exit;
  Lbl(DlgWnd, 'Nom :', 12, 14, 80);
  DEdit(IdMName, Nm, 100, 12, W - 112, False);
  Lbl(DlgWnd, 'Touches :', 12, 42, 80);
  DEdit(IdMKeys, MacEnc(Keys), 100, 40, W - 112, False);
  Lbl(DlgWnd, '\r Entr'#233'e, \t Tab, \e '#201'chap, \n saut de ligne, \xHH octet', 100, 66, W - 112);
  Lbl(DlgWnd, 'Exemple : ls -l\r', 100, 84, W - 112);
  DButtons(W, 116);
  DlgShow;
  Dummy := FocusTo(DCtl[IdMName]);
  ModalLoop;
  If DlgRes = IDOK Then
  Begin
    Nm := TrimS(DlgText);
    Keys := MacDec(DlgText2);
    MacroBox := Nm <> '';
  End;
End;

{ ---- table ASCII (page 437 de l'ecran) ---- }

Const
  AsX = 34; AsY = 24; AsW = 22; AsH = 18;

Procedure AsciiPaint(Dc : LongInt);
Var R, C, X, Y, V, Fg : LongInt; B : Array[0..1] Of Byte;
Const Hx : String[16] = '0123456789ABCDEF';
Begin
  Dummy := SelFont(Dc, Fnt);
  For C := 0 To 15 Do Txt(Dc, AsX + C * AsW + 8, 6, Hx[C + 1], ClrNavy);
  For R := 0 To 15 Do Txt(Dc, 10, AsY + R * AsH + 3, Hx[R + 1] + '_', ClrNavy);
  Bar(Dc, AsX - 1, AsY - 1, AsX + 16 * AsW + 1, AsY + 16 * AsH + 1, ClrShadow);
  Dummy := SelFont(Dc, TermFnt);
  For R := 0 To 15 Do
    For C := 0 To 15 Do
    Begin
      V := R * 16 + C;
      X := AsX + C * AsW; Y := AsY + R * AsH;
      If V = AsciiSel Then Bar(Dc, X, Y, X + AsW - 1, Y + AsH - 1, ClrNavy)
      Else Bar(Dc, X, Y, X + AsW - 1, Y + AsH - 1, ClrWin);
      B[0] := V; If V = 0 Then B[0] := 32;
      If V = AsciiSel Then Fg := ClrHi Else Fg := ClrBlack;
      TxtRaw(Dc, X + 7, Y + 1, LongInt(@B[0]), 1, Fg);
    End;
End;

Procedure AsciiInfo;
Var S : String; U : LongInt;
Begin
  U := OemToUni(AsciiSel);
  S := 'D'#233'cimal ' + IStr(AsciiSel) + '   Hexa ' + HexB(AsciiSel) +
       '   Unicode U+' + HexB(U Shr 8) + HexB(U And 255);
  SetText(DCtl[IdAsciiInfo], S);
End;

Procedure AsciiBox;
Var W, H : LongInt;
Begin
  DlgKind := DkAscii;
  DlgSc := DlgKind <> DkAscii;
  W := AsX + 16 * AsW + 14; H := AsY + 16 * AsH + 64;
  DlgSc := False;
  W := W + 60;
  If DlgCreate('Table ASCII (page de code 437)', W, H) = 0 Then Exit;
  AsciiSel := 65;
  Gray(DCtlMake(WC_STATIC, '', SS_TEXT Or DT_VCENTER, 10, AsY + 16 * AsH + 8, W - 110, 18, IdAsciiInfo));
  AsciiInfo;
  Dummy := DBtn(IDOK, 'Fermer', W - 92, H - 32, 80, 26, True);
  DlgShow;
  ModalLoop;
End;

{ ---- generateur de mots de passe ---- }

Procedure PassGen;
Var Pool, S : String; N, I : LongInt; B : Array[0..63] Of Byte;
Begin
  Pool := '';
  If Checked(DCtl[IdPUp]) Then Pool := Pool + 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  If Checked(DCtl[IdPLow]) Then Pool := Pool + 'abcdefghijkmnopqrstuvwxyz';
  If Checked(DCtl[IdPDig]) Then Pool := Pool + '23456789';
  If Checked(DCtl[IdPSym]) Then Pool := Pool + '!#$%&*+-=?@_.:';
  If Pool = '' Then Pool := 'abcdefghijkmnopqrstuvwxyz';
  N := MinI(MaxI(SVal(TrimS(DTxt(IdPLen))), 4), 64);
  TlEntropy;
  TlRandom(TlPtr(@B[0]), N);
  S := '';
  For I := 0 To N - 1 Do S := S + Pool[(B[I] Mod Length(Pool)) + 1];
  SetText(DCtl[IdPOut], S);
End;

Procedure PassBox;
Const W = 360;
Begin
  DlgKind := DkPass;
  DlgSc := DlgKind <> DkAscii;
  If DlgCreate('G'#233'n'#233'rateur de mots de passe', W, 170) = 0 Then Exit;
  Lbl(DlgWnd, 'Longueur :', 12, 14, 80);
  DEdit(IdPLen, '16', 100, 12, 50, False);
  DCheck(IdPUp, 'Majuscules', 12, 40, 110, True);
  DCheck(IdPLow, 'Minuscules', 130, 40, 110, True);
  DCheck(IdPDig, 'Chiffres', 12, 58, 110, True);
  DCheck(IdPSym, 'Symboles', 130, 58, 110, False);
  Dummy := DCtlMake(WC_ENTRYFIELD, '', ES_AUTOSCROLL Or ES_MARGIN Or ES_READONLY, 12, 86, W - 24, 20, IdPOut);
  Dummy := DBtn(IdPGen, 'G'#233'n'#233'rer', 12, 136, 90, 24, True);
  Dummy := DBtn(IdPCopy, 'Copier', 108, 136, 90, 24, False);
  Dummy := DBtn(IDCANCEL, 'Fermer', W - 88, 136, 76, 24, False);
  PassGen;
  DlgShow;
  ModalLoop;
End;

{ ---- procedure des boites ---- }

{ ---- boites Ouvrir et Enregistrer (controles de PM : WinFileDlg de
  PMCTLS n'est pas disponible dans OS/2-0) ---- }

Var
  FdDir, FdMask, FdRes : String;
  FdN : LongInt;
  FdItem : Array[0..399] Of String[64];
  FindBuf : Array[0..4095] Of Byte;

Function FdMatch(N, M : String) : Boolean;
Var I, J, SI, SJ : LongInt;
Begin
  N := UpS(N); M := UpS(M);
  I := 1; J := 1; SI := 0; SJ := 0;
  While I <= Length(N) Do
  Begin
    If (J <= Length(M)) And ((M[J] = '?') Or (M[J] = N[I])) Then Begin Inc(I); Inc(J); End
    Else If (J <= Length(M)) And (M[J] = '*') Then Begin SJ := J; SI := I; Inc(J); End
    Else If SJ > 0 Then Begin J := SJ + 1; Inc(SI); I := SI; End
    Else Begin FdMatch := False; Exit; End;
  End;
  While (J <= Length(M)) And (M[J] = '*') Do Inc(J);
  FdMatch := J > Length(M);
End;

Procedure FdAdd(S : String);
Begin
  If FdN > 399 Then Exit;
  FdItem[FdN] := S; Inc(FdN);
  Dummy := WinSendMsg(DCtl[IdFList], LM_INSERTITEM, -1, Z(Disp(S)));
End;

{ dossiers puis fichiers du masque (DosFindFirst, niveau 1) }
Procedure FdFill;
Var H, N, Rc, Off, A, K, Pass : LongInt; S : String;
Begin
  Dummy := WinSendMsg(DCtl[IdFList], LM_DELETEALL, 0, 0);
  FdN := 0;
  If Length(FdDir) > 3 Then FdAdd('[..]');
  For Pass := 1 To 2 Do
  Begin
    H := -1; N := 1;
    Rc := DosFindFirst(Z(FdDir + '*.*'), LongInt(@H), $37, LongInt(@FindBuf), SizeOf(FindBuf), LongInt(@N), 1);
    While (Rc = 0) And (N > 0) Do
    Begin
      Off := 0;
      While N > 0 Do
      Begin
        A := FindBuf[Off + 24];
        S := '';
        For K := 0 To FindBuf[Off + 28] - 1 Do S := S + Chr(FindBuf[Off + 29 + K]);
        If (S <> '.') And (S <> '..') Then
        Begin
          If Pass = 1 Then
          Begin
            If (A And $10) <> 0 Then FdAdd('[' + S + ']');
          End
          Else If ((A And $10) = 0) And ((FdMask = '*.*') Or FdMatch(S, FdMask)) Then FdAdd(S);
        End;
        Dec(N);
        K := FindBuf[Off] Or (FindBuf[Off + 1] Shl 8);
        If K = 0 Then N := 0 Else Off := Off + K;
      End;
      N := 1;
      Rc := DosFindNext(H, LongInt(@FindBuf), SizeOf(FindBuf), LongInt(@N));
    End;
    If H <> -1 Then Dummy := DosFindClose(H);
  End;
  SetText(DCtl[IdFDir], FdDir + FdMask);
End;

Procedure FdEnter(D : String);
Var K : LongInt;
Begin
  If D = '..' Then
  Begin
    K := Length(FdDir) - 1;
    While (K > 0) And (FdDir[K] <> '\') Do Dec(K);
    If K > 0 Then FdDir := Copy(FdDir, 1, K);
  End
  Else FdDir := FdDir + D + '\';
  FdFill;
End;

{ choix du nom S (champ ou liste) : True si la boite est finie }
Function FdChoose(S : String) : Boolean;
Var H, N, A : LongInt;
Begin
  FdChoose := False;
  S := TrimS(S);
  If S = '' Then Exit;
  If (S[1] = '[') And (S[Length(S)] = ']') Then
  Begin
    FdEnter(Copy(S, 2, Length(S) - 2));
    Exit;
  End;
  If (Pos('*', S) > 0) Or (Pos('?', S) > 0) Then
  Begin
    FdMask := S; FdFill;
    Exit;
  End;
  If (Length(S) = 2) And (S[2] = ':') Then S := S + '\';
  If (Pos(':', S) = 0) And (S[1] <> '\') Then S := FdDir + S
  Else If S[1] = '\' Then S := Copy(FdDir, 1, 2) + S;
  If S[Length(S)] = '\' Then
  Begin
    FdDir := S; FdFill;
    Exit;
  End;
  { dossier existant : on y entre }
  H := -1; N := 1;
  If DosFindFirst(Z(S), LongInt(@H), $37, LongInt(@FindBuf), SizeOf(FindBuf), LongInt(@N), 1) = 0 Then
  Begin
    A := FindBuf[24];
    Dummy := DosFindClose(H);
    If (A And $10) <> 0 Then
    Begin
      FdDir := S + '\'; FdFill;
      Exit;
    End;
  End;
  FdRes := S;
  FdChoose := True;
End;

{ liste : un clic met le nom dans le champ, un double clic choisit }
Procedure FdControl(Code : LongInt);
Var I : LongInt;
Begin
  I := WinSendMsg(DCtl[IdFList], LM_QUERYSELECTION, -1, 0);
  If (I < 0) Or (I >= FdN) Then Exit;
  If Code = LN_ENTER Then
  Begin
    If FdChoose(FdItem[I]) Then
    Begin
      DlgRes := IDOK; DlgDone := True;
    End;
  End
  Else If (Code = LN_SELECT) And (FdItem[I][1] <> '[') Then SetText(DCtl[IdFName], FdItem[I]);
End;

{ boite Ouvrir (Save False) ou Enregistrer sous ; Filt : "Desc|*.ext|..." ;
  Path : nom propose, recoit le nom complet choisi }
Function FileDlg(Save : Boolean; Title, Filt : String; Var Path : String) : Boolean;
Const W = 420; H = 300;
Var I : LongInt; S : String;
Begin
  FileDlg := False;
  DlgKind := DkFile;
  DlgSc := True;
  { masque : second champ du filtre }
  FdMask := '*.*';
  I := Pos('|', Filt);
  If I > 0 Then
  Begin
    S := Copy(Filt, I + 1, 255);
    I := Pos('|', S);
    If I > 0 Then S := Copy(S, 1, I - 1);
    If S <> '' Then FdMask := S;
  End;
  I := Length(Path);
  While (I > 0) And (Path[I] <> '\') Do Dec(I);
  FdDir := Copy(Path, 1, I);
  If FdDir = '' Then FdDir := 'C:\';
  S := Copy(Path, I + 1, 255);
  If (Pos('*', S) > 0) Or (Pos('?', S) > 0) Then
  Begin
    FdMask := S;
    S := '';
  End;
  If DlgCreate(Title, W, H) = 0 Then Exit;
  Lbl(DlgWnd, 'Nom du fichier :', 10, 10, 120);
  Dummy := DEdit(IdFName, S, 10, 26, W - 20, False);
  Lbl(DlgWnd, 'Dossier :', 10, 54, 60);
  Gray(DCtlMake(WC_STATIC, '', SS_TEXT Or DT_VCENTER, 70, 53, W - 80, 15, IdFDir));
  Dummy := DCtlMake(WC_LISTBOX, '', WS_TABSTOP, 10, 72, W - 20, H - 72 - 40, IdFList);
  If Save Then S := 'Enregistrer' Else S := 'Ouvrir';
  Dummy := DBtn(IDOK, S, W - 188, H - 32, 84, 24, True);
  Dummy := DBtn(IDCANCEL, 'Annuler', W - 96, H - 32, 84, 24, False);
  FdFill;
  FdRes := '';
  DlgShow;
  Dummy := FocusTo(DCtl[IdFName]);
  ModalLoop;
  If (DlgRes = IDOK) And (FdRes <> '') Then
  Begin
    Path := FdRes;
    FileDlg := True;
  End;
End;

{ fond gris de la boite (et dessins de la boite Session et de la table
  ASCII) }
Procedure DlgPaint(H : LongInt);
Var Ps : Array[0..15] Of LongInt; Dc : LongInt;
Begin
  Dc := PBegin(H, LongInt(@Ps));
  Bar(Dc, 0, 0, 2000, 2000, ClrFace);
  If DlgKind = DkSess Then PaintSshTile(Dc);
  If DlgKind = DkAscii Then AsciiPaint(Dc);
  Dummy := PEnd(H, LongInt(@Ps));
End;

Function DlgProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var Id, X, Y : LongInt; S : String;
Begin
  DlgProc0 := 0;
  Case Msg Of
    EvPaint : DlgPaint(H);
    EvLDown, EvLDbl :
      If DlgKind = DkAscii Then
      Begin
        X := (S16(LP) - AsX) Div AsW; Y := (S16(LP Shr 16) - AsY) Div AsH;
        If (S16(LP) >= AsX) And (S16(LP Shr 16) >= AsY) And (X < 16) And (Y < 16) Then
        Begin
          AsciiSel := Y * 16 + X;
          AsciiInfo;
          Dummy := Inval(H, 0);
          If Msg = EvLDbl Then
          Begin
            S := U8Of(OemToUni(AsciiSel));
            If (AsciiSel >= 32) Then SendKeys(Active, S);
          End;
        End;
      End;
    EvCommand :
    Begin
      Id := WP And $FFFF;
      If (DlgKind = DkPass) And (Id = IdPGen) Then PassGen
      Else If (DlgKind = DkPass) And (Id = IdPCopy) Then CopyText(DTxt(IdPOut))
      Else If (Id = IDOK) Or (Id = IDCANCEL) Then
      Begin
        If Id = IDOK Then
          Case DlgKind Of
            DkInput : DlgText := DTxt(IdInput);
            DkSess : If Not SessOk Then Exit;
            DkConf : ConfOk;
            DkMacro : Begin DlgText := DTxt(IdMName); DlgText2 := DTxt(IdMKeys); End;
            DkFile : If Not FdChoose(DTxt(IdFName)) Then Exit;
          End;
        DlgRes := Id; DlgDone := True;
      End;
    End;
    EvClose :
    Begin
      DlgRes := IDCANCEL; DlgDone := True;
    End;
  Else
    DlgProc0 := NoProc;
  End;
End;

{ ==================================================================== }
{ Panneau de gauche : listes (arbre des sessions, outils, macros,       }
{ fichiers SFTP), onglets horizontaux et petites barres d'outils        }
{ ==================================================================== }

Const
  LkSess = 0; LkTools = 1; LkMacro = 2; LkSftp = 3;
  LRH = 18;                              { hauteur d'une ligne }
  LHdr = 17;                             { en-tete des colonnes (SFTP) }
  SbW = 16;
  QcRowH = 42; PTabH = 22; MiniH = 24; PathH = 24; FStH = 18;
  { commandes (menus, petites barres d'outils) }
  CmNewSess = 200; CmNewFolder = 201; CmEditSess = 202; CmDelSess = 203;
  CmConnSess = 204; CmRenSess = 205; CmDupSess = 206; CmImport = 207;
  CmExport = 208; CmConnAs = 209;
  CmCopy = 210; CmPaste = 211; CmSelAll = 212; CmClearHist = 213;
  CmResetTerm = 214; CmSaveText = 215; CmReconnect = 216; CmCloseTab = 217;
  CmDupTab = 218; CmExit = 219; CmNextTab = 220; CmPrevTab = 221;
  CmRenTab = 222;
  CmPanel = 230; CmPTab0 = 231; CmToolbar = 235; CmStatus = 236;
  CmConfig = 240; CmScheme0 = 241; CmCopySel = 245; CmRPaste = 246;
  CmMultiExec = 247;
  CmRecMacro = 250; CmStopMacro = 251; CmNewMacro = 252; CmEditMacro = 253;
  CmDelMacro = 254; CmRunMacro = 255;
  CmHelp = 260; CmKeys = 261; CmAbout = 262;
  CmFUp = 270; CmFRefresh = 271; CmFGet = 272; CmFPut = 273; CmFMkdir = 274;
  CmFDel = 275; CmFRen = 276; CmFHome = 277; CmFOpen = 278; CmFConnect = 279;
  CmTool0 = 300;                         { + outil }
  CmMacro0 = 400;                        { + macro }
  CmSess0 = 500;                         { + session enregistree }
  ToolN = 12;

Type
  PEntry = ^TEntry;
  TLst = Record
    H, Sb, Top, Cur : LongInt;
  End;

Var
  Lst : Array[0..3] Of TLst;
  PanelWnd, QcEdit, QcBtn, PathEdit : LongInt;
  PanelW, PanelTab : LongInt;
  { arbre des sessions : 0 racine, 1 dossier, 2 session }
  TrKind, TrIdx : Array[0..MaxDef + MaxFolder] Of LongInt;
  TrN : LongInt;
  SfIdx : Array[0..MaxEnt] Of LongInt;   { liste SFTP triee (-1 : ..) }
  SfN : LongInt;
  RecOn : Boolean;
  RecKeys : String;
  MiniHot : LongInt;
  StatusTip : String;

Procedure SetTip(S : String); Forward;
Procedure DoCmd(Cmd : LongInt); Forward;
Procedure ListActivate(K, I : LongInt); Forward;
Procedure ListMenu(K, I, X, Y : LongInt); Forward;

{ ---- outils ---- }

Procedure ToolInfo(I : LongInt; Var Nm, Exe : String; Var Ic : LongInt; Var Hdr : Boolean);
Begin
  { programmes d'OS/2-0 (ceux de Pasdows 95 remplaces) }
  Hdr := False; Exe := ''; Ic := 0;
  Case I Of
    0 : Begin Nm := 'Syst'#232'me'; Hdr := True; End;
    1 : Begin Nm := 'Invite de commandes'; Exe := 'CMD.EXE'; Ic := IcDos; End;
    2 : Begin Nm := 'Gestionnaire des t'#226'ches'; Exe := 'TASKMGR.EXE'; Ic := IcTask; End;
    3 : Begin Nm := 'Gestionnaire de p'#233'riph'#233'riques'; Exe := 'DEVMGR.EXE'; Ic := IcInfo; End;
    4 : Begin Nm := 'Explorateur OS2-Zero'; Exe := 'EXPLORER.EXE'; Ic := IcComputer; End;
    5 : Begin Nm := 'Bureautique'; Hdr := True; End;
    6 : Begin Nm := 'Bloc-notes'; Exe := 'NOTEPAD.EXE'; Ic := IcNote; End;
    7 : Begin Nm := 'Calculatrice'; Exe := 'CALC.EXE'; Ic := IcCalc; End;
    8 : Begin Nm := 'Table ASCII'; Exe := '*ASCII'; Ic := IcAscii; End;
    9 : Begin Nm := 'R'#233'seau'; Hdr := True; End;
    10 : Begin Nm := 'Client FTP'; Exe := 'FTPCLI.EXE'; Ic := IcFtp; End;
    11 : Begin Nm := 'Navigateur Web'; Exe := 'BROWSER.EXE'; Ic := IcWeb; End;
  Else
    Begin Nm := 'G'#233'n'#233'rateur de mots de passe'; Exe := '*PASS'; Ic := IcKey; End;
  End;
End;

{ programme d'OS/2-0 : racine de C:, sinon dossier de l'interpreteur de
  commandes (COMSPEC) ; '' s'il n'existe pas }
Function AppPath(N : String) : String;
Var S : String; P, H, C : LongInt; B : Array[0..63] Of Byte;
Begin
  AppPath := '';
  S := 'C:\' + N;
  H := -1; C := 1;
  If DosFindFirst(Z(S), LongInt(@H), $27, LongInt(@B), SizeOf(B), LongInt(@C), 1) = 0 Then
  Begin
    Dummy := DosFindClose(H);
    AppPath := S;
    Exit;
  End;
  P := 0;
  If DosScanEnv(Z('COMSPEC'), LongInt(@P)) = 0 Then
  Begin
    S := GetZ(P);
    While (S <> '') And (S[Length(S)] <> '\') Do Delete(S, Length(S), 1);
    If S <> '' Then
    Begin
      H := -1; C := 1;
      If DosFindFirst(Z(S + N), LongInt(@H), $27, LongInt(@B), SizeOf(B), LongInt(@C), 1) = 0 Then
      Begin
        Dummy := DosFindClose(H);
        AppPath := S + N;
      End;
    End;
  End;
End;

{ lance un programme : DosExecPgm en arriere-plan (EXEC_BACKGROUND, le
  programme de PM rejoint la session de PM) ; l'Invite de commandes
  (mode texte) dans une session a elle (sessions d'OS/2-0, comme le
  bureau et l'Explorateur) }
Function RunExe(Exe : String) : Boolean;
Var P : String; Res : Array[0..1] Of LongInt; Fail : Array[0..63] Of Byte;
    Arg : Array[0..299] Of Byte; Rc, S : LongInt;
Begin
  RunExe := False;
  P := AppPath(Exe);
  If P = '' Then Exit;
  PutZ(LongInt(@Arg), P);
  Arg[Length(P) + 1] := 0; Arg[Length(P) + 2] := 0;
  S := -1;
  If Exe = 'CMD.EXE' Then
  Begin
    S := KSes(4, Z(Exe), 0);
    If S < 0 Then Exit;
    Dummy := KSes(16, S, 1);
    Dummy := KSes(12, S, 0);
  End;
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@Fail), 64, 4, LongInt(@Arg), 0, LongInt(@Res), Z2(P));
  If S >= 0 Then
  Begin
    If Rc <> 0 Then
    Begin
      Dummy := KSes(12, -1, 0);
      Dummy := KSes(17, S, 0);
    End
    Else Dummy := KSes(3, S, 0);
  End;
  RunExe := Rc = 0;
End;

Procedure RunTool(I : LongInt);
Var Nm, Exe : String; Ic : LongInt; Hdr : Boolean;
Begin
  ToolInfo(I, Nm, Exe, Ic, Hdr);
  If Hdr Or (Exe = '') Then Exit;
  If Exe = '*ASCII' Then AsciiBox
  Else If Exe = '*PASS' Then PassBox
  Else If Not RunExe(Exe) Then
    Ask('Impossible de lancer ' + Exe + '.', 'Outils', MB_OK Or MB_ICONERROR);
End;

{ ---- arbre des sessions ---- }

Procedure TreeBuild;
Var F, I : LongInt;
Begin
  TrN := 0;
  TrKind[0] := 0; TrIdx[0] := 0; TrN := 1;
  For F := 0 To FolderN - 1 Do
  Begin
    TrKind[TrN] := 1; TrIdx[TrN] := F; Inc(TrN);
    If FolderOpen[F] Then
      For I := 0 To DefN - 1 Do
        If UpS(Defs^[I].Folder) = UpS(Folders[F]) Then
        Begin
          TrKind[TrN] := 2; TrIdx[TrN] := I; Inc(TrN);
        End;
  End;
  For I := 0 To DefN - 1 Do
    If FolderIdx(Defs^[I].Folder) < 0 Then
    Begin
      TrKind[TrN] := 2; TrIdx[TrN] := I; Inc(TrN);
    End;
End;

{ session enregistree choisie dans l'arbre (-1 : aucune) }
Function TreeDef : LongInt;
Var C : LongInt;
Begin
  TreeDef := -1;
  C := Lst[LkSess].Cur;
  If (C >= 0) And (C < TrN) And (TrKind[C] = 2) Then TreeDef := TrIdx[C];
End;

Function TreeFolder : String;
Var C : LongInt;
Begin
  TreeFolder := '';
  C := Lst[LkSess].Cur;
  If (C < 0) Or (C >= TrN) Then Exit;
  If TrKind[C] = 1 Then TreeFolder := Folders[TrIdx[C]]
  Else If TrKind[C] = 2 Then TreeFolder := Defs^[TrIdx[C]].Folder;
End;

{ ---- liste SFTP triee ---- }

Function SfBefore(L : PEntArr; A, B : LongInt) : Boolean;
Begin
  If L^[A].Dir <> L^[B].Dir Then SfBefore := L^[A].Dir
  Else SfBefore := UpS(L^[A].Name) < UpS(L^[B].Name);
End;

Procedure SftpSort;
Var I, J, V, N : LongInt; L : PEntArr;
Begin
  SfN := 0;
  If (Active < 0) Or (Sess^[Active].FList = Nil) Or
     (Sess^[Active].FState = FsNone) Or (Sess^[Active].FState = FsFailed) Or
     (Sess^[Active].FState = FsConn) Then Exit;
  L := Sess^[Active].FList;
  If Sess^[Active].FCwd <> '/' Then
  Begin
    SfIdx[0] := -1; SfN := 1;
  End;
  N := Sess^[Active].FN;
  For I := 0 To N - 1 Do
  Begin
    SfIdx[SfN] := I; Inc(SfN);
  End;
  { insertion (quelques centaines d'elements) }
  For I := 1 To SfN - 1 Do
  Begin
    V := SfIdx[I];
    If V < 0 Then Continue;
    J := I - 1;
    While (J >= 0) And (SfIdx[J] >= 0) And SfBefore(L, V, SfIdx[J]) Do
    Begin
      SfIdx[J + 1] := SfIdx[J]; Dec(J);
    End;
    SfIdx[J + 1] := V;
  End;
End;

Function SfEntry(I : LongInt) : PEntry;
Begin
  If (I < 0) Or (I >= SfN) Or (SfIdx[I] < 0) Then SfEntry := Nil
  Else SfEntry := @Sess^[Active].FList^[SfIdx[I]];
End;

{ ---- donnees des listes ---- }

Function LCount(K : LongInt) : LongInt;
Begin
  Case K Of
    LkSess : LCount := TrN;
    LkTools : LCount := ToolN + 1;
    LkMacro : LCount := MacroN;
  Else
    LCount := SfN;
  End;
End;

Procedure LItem(K, I : LongInt; Var S, C2, C3 : String; Var Ic, Ind : LongInt;
                Var Hdr : Boolean);
Var Exe : String; E : PEntry;
Begin
  S := ''; C2 := ''; C3 := ''; Ic := 0; Ind := 0; Hdr := False;
  Case K Of
    LkSess :
      Case TrKind[I] Of
        0 : Begin S := 'Sessions utilisateur'; Ic := IcComputer; End;
        1 : Begin S := Folders[TrIdx[I]]; Ind := 1;
              If FolderOpen[TrIdx[I]] Then Ic := IcFolderOpen Else Ic := IcFolder; End;
      Else
        Begin
          S := Defs^[TrIdx[I]].Name; Ic := IcTerm;
          If FolderIdx(Defs^[TrIdx[I]].Folder) >= 0 Then Ind := 2 Else Ind := 1;
        End;
      End;
    LkTools : ToolInfo(I, S, Exe, Ic, Hdr);
    LkMacro : Begin S := Macros[I].Name; Ic := IcMacro; End;
  Else
    Begin
      E := SfEntry(I);
      If E = Nil Then Begin S := '..'; Ic := IcUp; End
      Else
      Begin
        S := E^.Name;
        If E^.Dir Then Ic := IcDir
        Else If E^.Link Then Ic := IcLink
        Else
        Begin
          Ic := IcFile;
          C2 := Group(IStr(Trunc((E^.Size + 1023) / 1024)));
        End;
        C3 := E^.Time;
      End;
    End;
  End;
End;

{ ---- controle de liste ---- }

Function LRows(K : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; H : LongInt;
Begin
  Dummy := CliRect(Lst[K].H, LongInt(@Rc));
  H := Rc[3];
  If K = LkSftp Then H := H - LHdr;
  LRows := MaxI(1, H Div LRH);
End;

Procedure LSync(K : LongInt);
Var N, R, M : LongInt;
Begin
  N := LCount(K);
  If Lst[K].Cur >= N Then Lst[K].Cur := N - 1;
  R := LRows(K);
  M := MaxI(0, N - R);
  If Lst[K].Cur >= 0 Then
  Begin
    If Lst[K].Cur < Lst[K].Top Then Lst[K].Top := Lst[K].Cur;
    If Lst[K].Cur >= Lst[K].Top + R Then Lst[K].Top := Lst[K].Cur - R + 1;
  End;
  If Lst[K].Top > M Then Lst[K].Top := M;
  If Lst[K].Top < 0 Then Lst[K].Top := 0;
  SbSet(Lst[K].Sb, Lst[K].Top, M, R);
  Dummy := WinEnableWindow(Lst[K].Sb, Ord(M > 0));
End;

Procedure LRepaint(K : LongInt);
Begin
  LSync(K);
  Dummy := Inval(Lst[K].H, 0);
End;

Function LKind(H : LongInt) : LongInt;
Var K : LongInt;
Begin
  LKind := 0;
  For K := 0 To 3 Do If Lst[K].H = H Then LKind := K;
End;

Procedure LPaint(H : LongInt);
Var Ps : Array[0..15] Of LongInt; Rc : Array[0..3] Of LongInt;
    Dc, Old, K, I, Y, W, X, Ic, Ind, N, Fg, Y0, Tw : LongInt;
    S, C2, C3 : String; Hdr, Foc : Boolean;
Begin
  Dc := PBegin(H, LongInt(@Ps));
  Old := SelFont(Dc, Fnt);
  K := LKind(H);
  Dummy := CliRect(H, LongInt(@Rc));
  W := Rc[2] - SbW;
  Foc := FocusWnd = H;
  Y0 := 0;
  If K = LkSftp Then
  Begin
    Bar(Dc, 0, 0, W, LHdr, ClrFace);
    Thin(Dc, 0, 0, W - 84, LHdr, True);
    Thin(Dc, W - 84, 0, W - 40, LHdr, True);
    Thin(Dc, W - 40, 0, W, LHdr, True);
    Txt(Dc, 4, 2, 'Nom', ClrBlack);
    Txt(Dc, W - 80, 2, 'Ko', ClrBlack);
    Txt(Dc, W - 36, 2, 'Date', ClrBlack);
    Y0 := LHdr;
  End;
  N := LCount(K);
  I := Lst[K].Top;
  Y := Y0;
  While Y < Rc[3] Do
  Begin
    If I < N Then
    Begin
      LItem(K, I, S, C2, C3, Ic, Ind, Hdr);
      If Hdr Then
      Begin
        Bar(Dc, 0, Y, W, Y + LRH, ClrFace);
        Txt(Dc, 6, Y + 3, S, ClrNavy);
        Bar(Dc, 6, Y + LRH - 2, W - 6, Y + LRH - 1, ClrShadow);
      End
      Else
      Begin
        Bar(Dc, 0, Y, W, Y + LRH, ClrWin);
        X := 2 + Ind * 14;
        If (K = LkSess) And (TrKind[I] = 1) Then
        Begin
          { +/- du dossier }
          Box(Dc, X - 12, Y + 5, X - 3, Y + 14, ClrShadow, ClrWin);
          Bar(Dc, X - 10, Y + 9, X - 5, Y + 10, ClrBlack);
          If Not FolderOpen[TrIdx[I]] Then Bar(Dc, X - 8, Y + 7, X - 7, Y + 12, ClrBlack);
        End;
        If Ic <> 0 Then Icon16(Dc, Ic, X, Y + 1);
        X := X + 20;
        Fg := ClrBlack;
        If I = Lst[K].Cur Then
        Begin
          Tw := Length(S) * CW + 3;
          If K = LkSftp Then Tw := MinI(Tw, W - 86 - X);
          If Foc Then
          Begin
            Bar(Dc, X - 2, Y + 1, MinI(X + Tw, W), Y + LRH - 1, ClrSel);
            Fg := ClrHi;
          End
          Else Bar(Dc, X - 2, Y + 1, MinI(X + Tw, W), Y + LRH - 1, ClrFace);
        End;
        If K = LkSftp Then
        Begin
          Txt(Dc, X, Y + 3, Fit(S, W - 86 - X), Fg);
          Txt(Dc, W - 43 - Length(C2) * CW, Y + 3, C2, ClrBlack);
          Txt(Dc, W - 37, Y + 3, Copy(C3, 6, 5), ClrShadow);
        End
        Else Txt(Dc, X, Y + 3, Fit(S, W - X), Fg);
      End;
    End
    Else Bar(Dc, 0, Y, W, Y + LRH, ClrWin);
    Y := Y + LRH;
    Inc(I);
  End;
  Dummy := SelFont(Dc, Old);
  Dummy := PEnd(H, LongInt(@Ps));
End;

Function LHit(K, Y : LongInt) : LongInt;
Var I : LongInt;
Begin
  If K = LkSftp Then Y := Y - LHdr;
  LHit := -1;
  If Y < 0 Then Exit;
  I := Lst[K].Top + Y Div LRH;
  If I < LCount(K) Then LHit := I;
End;

Procedure ToggleFolder(I : LongInt);
Begin
  If (I < 0) Or (I >= TrN) Or (TrKind[I] <> 1) Then Exit;
  FolderOpen[TrIdx[I]] := Not FolderOpen[TrIdx[I]];
  TreeBuild;
  LRepaint(LkSess);
End;

Function LProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var K, I, X, Y, N : LongInt; P : Array[0..1] Of LongInt;
    S, C2, C3 : String; Ic, Ind : LongInt; Hdr : Boolean;
Begin
  LProc0 := 0;
  K := LKind(H);
  Case Msg Of
    EvPaint : LPaint(H);
    EvErase : LProc0 := 1;
    EvSize : LSync(K);
    EvSetFocus, EvKillFocus : Dummy := Inval(H, 0);
    EvLDown, EvLDbl, EvRDown :
    Begin
      Dummy := FocusTo(H);
      X := S16(LP); Y := S16(LP Shr 16);
      I := LHit(K, Y);
      If I >= 0 Then
      Begin
        LItem(K, I, S, C2, C3, Ic, Ind, Hdr);
        If Not Hdr Then Lst[K].Cur := I;
        LRepaint(K);
        If Msg = EvLDbl Then
        Begin
          If (K = LkSess) And (TrKind[I] = 1) Then ToggleFolder(I)
          Else If Not Hdr Then ListActivate(K, I);
        End
        Else If (Msg = EvLDown) And (K = LkSess) And (TrKind[I] = 1) And
                (X < 2 + Ind * 14) Then ToggleFolder(I);
      End;
      If Msg = EvRDown Then
      Begin
        P[0] := X; P[1] := Y;
        Dummy := ToScreen(H, LongInt(@P[0]));
        ListMenu(K, I, P[0], P[1]);
      End;
    End;
    EvWheel :
    Begin
      If S16(WP Shr 16) > 0 Then Lst[K].Top := Lst[K].Top - 3
      Else Lst[K].Top := Lst[K].Top + 3;
      N := Lst[K].Cur; Lst[K].Cur := -1;
      LRepaint(K);
      Lst[K].Cur := N;
      Dummy := Inval(H, 0);
    End;
    EvVScroll :
    Begin
      Case WP And $FFFF Of
        0 : Dec(Lst[K].Top);
        1 : Inc(Lst[K].Top);
        2 : Lst[K].Top := Lst[K].Top - LRows(K);
        3 : Lst[K].Top := Lst[K].Top + LRows(K);
        4, 5 : Lst[K].Top := (WP Shr 16) And $FFFF;
      End;
      N := Lst[K].Cur; Lst[K].Cur := -1;
      LRepaint(K);
      Lst[K].Cur := N;
      Dummy := Inval(H, 0);
    End;
    EvKeyDown :
    Begin
      N := LCount(K);
      Case WP Of
        VK_UP : If Lst[K].Cur > 0 Then Dec(Lst[K].Cur);
        VK_DOWN : If Lst[K].Cur < N - 1 Then Inc(Lst[K].Cur);
        VK_HOME : Lst[K].Cur := 0;
        VK_END : Lst[K].Cur := N - 1;
        VK_PRIOR : Lst[K].Cur := MaxI(0, Lst[K].Cur - LRows(K));
        VK_NEXT : Lst[K].Cur := MinI(N - 1, Lst[K].Cur + LRows(K));
        VK_RETURN : If Lst[K].Cur >= 0 Then
                      If (K = LkSess) And (TrKind[Lst[K].Cur] = 1) Then
                        ToggleFolder(Lst[K].Cur)
                      Else ListActivate(K, Lst[K].Cur);
        VK_DELETE :
          Case K Of
            LkSess : DoCmd(CmDelSess);
            LkMacro : DoCmd(CmDelMacro);
            LkSftp : DoCmd(CmFDel);
          End;
        VK_F2 :
          Case K Of
            LkSess : DoCmd(CmRenSess);
            LkMacro : DoCmd(CmEditMacro);
            LkSftp : DoCmd(CmFRen);
          End;
        VK_BACK : If K = LkSftp Then DoCmd(CmFUp);
        VK_F5 : If K = LkSftp Then DoCmd(CmFRefresh);
      End;
      LRepaint(K);
    End;
  Else
    LProc0 := NoProc;
  End;
End;


{ ---- panneau : onglets et petites barres d'outils ---- }

Function PTabName(I : LongInt) : String;
Begin
  Case I Of
    0 : PTabName := 'Sessions';
    1 : PTabName := 'Outils';
    2 : PTabName := 'Macros';
  Else
    PTabName := 'SFTP';
  End;
End;

Function PTabX(I : LongInt) : LongInt;
Var K, X : LongInt;
Begin
  X := 2;
  For K := 0 To I - 1 Do X := X + Length(PTabName(K)) * CW + 12;
  PTabX := X;
End;

{ boutons de la petite barre de l'onglet courant }
Function MiniCount : LongInt;
Begin
  Case PanelTab Of
    LkSess : MiniCount := 5;
    LkMacro : MiniCount := 5;
    LkSftp : MiniCount := 8;
  Else
    MiniCount := 0;
  End;
End;

Function MiniCmd(I : LongInt) : LongInt;
Begin
  MiniCmd := 0;
  Case PanelTab Of
    LkSess :
      Case I Of
        0 : MiniCmd := CmNewSess; 1 : MiniCmd := CmNewFolder;
        2 : MiniCmd := CmConnSess; 3 : MiniCmd := CmEditSess;
        4 : MiniCmd := CmDelSess;
      End;
    LkMacro :
      Case I Of
        0 : If RecOn Then MiniCmd := CmStopMacro Else MiniCmd := CmRecMacro;
        1 : MiniCmd := CmRunMacro; 2 : MiniCmd := CmNewMacro;
        3 : MiniCmd := CmEditMacro; 4 : MiniCmd := CmDelMacro;
      End;
    LkSftp :
      Case I Of
        0 : MiniCmd := CmFUp; 1 : MiniCmd := CmFHome; 2 : MiniCmd := CmFRefresh;
        3 : MiniCmd := CmFGet; 4 : MiniCmd := CmFPut; 5 : MiniCmd := CmFMkdir;
        6 : MiniCmd := CmFRen; 7 : MiniCmd := CmFDel;
      End;
  End;
End;

Function CmdTip(C : LongInt) : String;
Begin
  Case C Of
    CmNewSess : CmdTip := 'Nouvelle session';
    CmNewFolder : CmdTip := 'Nouveau dossier de sessions';
    CmConnSess : CmdTip := 'Se connecter '#224' la session choisie';
    CmEditSess : CmdTip := 'Modifier la session';
    CmDelSess : CmdTip := 'Supprimer la session ou le dossier';
    CmRecMacro : CmdTip := 'Enregistrer une nouvelle macro (frappes au clavier)';
    CmStopMacro : CmdTip := 'Arr'#234'ter l''enregistrement de la macro';
    CmRunMacro : CmdTip := 'Ex'#233'cuter la macro dans le terminal';
    CmNewMacro : CmdTip := 'Nouvelle macro';
    CmEditMacro : CmdTip := 'Modifier la macro';
    CmDelMacro : CmdTip := 'Supprimer la macro';
    CmFUp : CmdTip := 'Dossier parent';
    CmFHome : CmdTip := 'Dossier personnel';
    CmFRefresh : CmdTip := 'Actualiser';
    CmFGet : CmdTip := 'T'#233'l'#233'charger le fichier choisi';
    CmFPut : CmdTip := 'Envoyer un fichier dans ce dossier';
    CmFMkdir : CmdTip := 'Cr'#233'er un dossier';
    CmFRen : CmdTip := 'Renommer';
    CmFDel : CmdTip := 'Supprimer';
  Else
    CmdTip := '';
  End;
End;

Procedure MiniIcon(Dc, C, X, Y : LongInt);
Begin
  Case C Of
    CmNewSess : Begin Icon16(Dc, IcTerm, X, Y); Bar(Dc, X + 10, Y, X + 16, Y + 2, ClrGreen);
                  Bar(Dc, X + 12, Y - 2, X + 14, Y + 4, ClrGreen); End;
    CmNewFolder, CmFMkdir : Begin Icon16(Dc, IcFolder, X, Y);
                  Bar(Dc, X + 9, Y + 1, X + 15, Y + 3, ClrGreen); Bar(Dc, X + 11, Y - 1, X + 13, Y + 5, ClrGreen); End;
    CmConnSess : Begin Bar(Dc, X + 2, Y + 4, X + 6, Y + 12, ClrBlack); Bar(Dc, X + 10, Y + 4, X + 14, Y + 12, ClrBlack);
                  Bar(Dc, X + 6, Y + 7, X + 10, Y + 9, ClrGreen); End;
    CmEditSess, CmEditMacro, CmFRen :
    Begin
      Box(Dc, X + 2, Y + 2, X + 14, Y + 14, ClrBlack, ClrWin);
      Bar(Dc, X + 5, Y + 10, X + 7, Y + 12, ClrNavy); Bar(Dc, X + 7, Y + 8, X + 9, Y + 10, ClrNavy);
      Bar(Dc, X + 9, Y + 6, X + 11, Y + 8, ClrNavy); Bar(Dc, X + 11, Y + 4, X + 13, Y + 6, ClrRed);
    End;
    CmDelSess, CmDelMacro, CmFDel :
    Begin
      Bar(Dc, X + 3, Y + 3, X + 5, Y + 5, ClrRed); Bar(Dc, X + 5, Y + 5, X + 7, Y + 7, ClrRed);
      Bar(Dc, X + 7, Y + 7, X + 9, Y + 9, ClrRed); Bar(Dc, X + 9, Y + 9, X + 11, Y + 11, ClrRed);
      Bar(Dc, X + 11, Y + 11, X + 13, Y + 13, ClrRed);
      Bar(Dc, X + 11, Y + 3, X + 13, Y + 5, ClrRed); Bar(Dc, X + 9, Y + 5, X + 11, Y + 7, ClrRed);
      Bar(Dc, X + 5, Y + 9, X + 7, Y + 11, ClrRed); Bar(Dc, X + 3, Y + 11, X + 5, Y + 13, ClrRed);
    End;
    CmRecMacro : Icon16(Dc, IcRec, X, Y);
    CmStopMacro : Box(Dc, X + 3, Y + 3, X + 13, Y + 13, ClrBlack, ClrNavy);
    CmRunMacro, CmNewMacro :
    Begin
      Icon16(Dc, IcMacro, X, Y);
      If C = CmNewMacro Then
      Begin
        Bar(Dc, X + 10, Y, X + 16, Y + 2, ClrGreen); Bar(Dc, X + 12, Y - 2, X + 14, Y + 4, ClrGreen);
      End;
    End;
    CmFUp : Icon16(Dc, IcUp, X, Y);
    CmFHome :
    Begin
      Bar(Dc, X + 7, Y + 2, X + 9, Y + 3, ClrMaroon); Bar(Dc, X + 5, Y + 3, X + 11, Y + 5, ClrMaroon);
      Bar(Dc, X + 3, Y + 5, X + 13, Y + 7, ClrMaroon);
      Box(Dc, X + 4, Y + 7, X + 12, Y + 14, ClrBlack, ClrYellow);
      Bar(Dc, X + 7, Y + 10, X + 9, Y + 14, ClrMaroon);
    End;
    CmFRefresh :
    Begin
      Bar(Dc, X + 3, Y + 3, X + 12, Y + 5, ClrGreen); Bar(Dc, X + 3, Y + 3, X + 5, Y + 9, ClrGreen);
      Bar(Dc, X + 10, Y + 1, X + 12, Y + 7, ClrGreen);
      Bar(Dc, X + 4, Y + 11, X + 13, Y + 13, ClrBlue); Bar(Dc, X + 11, Y + 7, X + 13, Y + 13, ClrBlue);
      Bar(Dc, X + 4, Y + 9, X + 6, Y + 15, ClrBlue);
    End;
    CmFGet, CmFPut :
    Begin
      Bar(Dc, X + 2, Y + 13, X + 14, Y + 15, ClrShadow);
      Bar(Dc, X + 7, Y + 1, X + 9, Y + 12, ClrBlue);
      If C = CmFGet Then
      Begin
        Bar(Dc, X + 4, Y + 8, X + 12, Y + 9, ClrBlue); Bar(Dc, X + 5, Y + 9, X + 11, Y + 10, ClrBlue);
        Bar(Dc, X + 6, Y + 10, X + 10, Y + 11, ClrBlue);
      End
      Else
      Begin
        Bar(Dc, X + 4, Y + 4, X + 12, Y + 5, ClrGreen); Bar(Dc, X + 5, Y + 3, X + 11, Y + 4, ClrGreen);
        Bar(Dc, X + 6, Y + 2, X + 10, Y + 3, ClrGreen); Bar(Dc, X + 7, Y + 1, X + 9, Y + 12, ClrGreen);
      End;
    End;
  End;
End;

Function MiniY : LongInt;
Begin
  MiniY := QcRowH + PTabH + 2;
End;

Function MiniHit(X, Y : LongInt) : LongInt;
Var I : LongInt;
Begin
  MiniHit := -1;
  If (Y < MiniY) Or (Y >= MiniY + 22) Then Exit;
  For I := 0 To MiniCount - 1 Do
    If (X >= 4 + I * 23) And (X < 4 + I * 23 + 22) Then MiniHit := I;
End;

{ zone de la liste dans le panneau }
Procedure PanelLayout;
Var Rc : Array[0..3] Of LongInt; W, H, Y, B, K : LongInt;
Begin
  If PanelWnd = 0 Then Exit;
  Dummy := CliRect(PanelWnd, LongInt(@Rc));
  W := Rc[2]; H := Rc[3];
  Dummy := Place(QcEdit, 4, 18, W - 34, 20);
  Dummy := Place(QcBtn, W - 28, 17, 24, 22);
  Y := QcRowH + PTabH + 2;
  If MiniCount > 0 Then Y := Y + MiniH;
  B := H - 2;
  If PanelTab = LkSftp Then
  Begin
    Dummy := Place(PathEdit, 4, Y, W - 8, 20);
    Dummy := Show(PathEdit, 1);
    Y := Y + PathH;
    B := H - FStH - 2;
  End
  Else Dummy := Show(PathEdit, 0);
  For K := 0 To 3 Do
    If K = PanelTab Then
    Begin
      Dummy := Place(Lst[K].H, 2, Y, W - 4, B - Y);
      Dummy := Place(Lst[K].Sb, W - 4 - SbW, 0, SbW, B - Y);
      Dummy := Show(Lst[K].H, 1);
      LSync(K);
    End
    Else Dummy := Show(Lst[K].H, 0);
  Dummy := Inval(PanelWnd, 0);
End;

Function SftpStatus : String;
Var S : String;
Begin
  If Active < 0 Then
  Begin
    SftpStatus := 'Aucune session active.';
    Exit;
  End;
  Case Sess^[Active].FState Of
    FsNone :
      If Sess^[Active].State = StOpen Then S := 'Cliquez sur Actualiser pour ouvrir le SFTP.'
      Else S := 'Non connect'#233'.';
    FsConn : S := 'Connexion SFTP...';
    FsFailed : S := 'Erreur : ' + Sess^[Active].FErr;
    FsBusy :
      If Sess^[Active].FDone > 0 Then S := Sess^[Active].FMsg + ' ' + SizeTxt(Sess^[Active].FDone)
      Else S := Sess^[Active].FMsg;
  Else
    If Sess^[Active].FMsg <> '' Then S := Sess^[Active].FMsg
    Else S := IStr(Sess^[Active].FN) + ' '#233'l'#233'ment(s)';
  End;
  SftpStatus := S;
End;

Procedure PanelPaint(H : LongInt);
Var Ps : Array[0..15] Of LongInt; Rc : Array[0..3] Of LongInt;
    Dc, Old, W, I, X, Tw, Y, C : LongInt;
Begin
  Dc := PBegin(H, LongInt(@Ps));
  Old := SelFont(Dc, Fnt);
  Dummy := CliRect(H, LongInt(@Rc));
  W := Rc[2];
  Bar(Dc, 0, 0, W, Rc[3], ClrFace);
  Txt(Dc, 4, 3, 'Connexion rapide :', ClrBlack);
  { onglets horizontaux }
  Y := QcRowH;
  For I := 0 To 3 Do
  Begin
    X := PTabX(I); Tw := Length(PTabName(I)) * CW + 12;
    If I = PanelTab Then
    Begin
      Bar(Dc, X - 2, Y, X + Tw + 2, Y + PTabH + 1, ClrFace);
      Bar(Dc, X - 2, Y, X + Tw + 2, Y + 1, ClrHi);
      Bar(Dc, X - 2, Y, X - 1, Y + PTabH, ClrHi);
      Bar(Dc, X + Tw + 1, Y + 1, X + Tw + 2, Y + PTabH, ClrDark);
      Bar(Dc, X + Tw, Y + 1, X + Tw + 1, Y + PTabH, ClrShadow);
      Txt(Dc, X + 6, Y + 4, PTabName(I), ClrBlack);
    End
    Else
    Begin
      Bar(Dc, X, Y + 2, X + Tw, Y + 3, ClrHi);
      Bar(Dc, X, Y + 2, X + 1, Y + PTabH, ClrHi);
      Bar(Dc, X + Tw - 1, Y + 3, X + Tw, Y + PTabH, ClrShadow);
      Txt(Dc, X + 6, Y + 6, PTabName(I), ClrBlack);
    End;
  End;
  Bar(Dc, 0, Y + PTabH, PTabX(PanelTab) - 2, Y + PTabH + 1, ClrHi);
  Bar(Dc, PTabX(PanelTab + 1), Y + PTabH, W, Y + PTabH + 1, ClrHi);
  { petite barre d'outils }
  For I := 0 To MiniCount - 1 Do
  Begin
    C := MiniCmd(I);
    X := 4 + I * 23;
    If I = MiniHot Then Thin(Dc, X, MiniY, X + 22, MiniY + 22, True);
    MiniIcon(Dc, C, X + 3, MiniY + 3);
  End;
  If PanelTab = LkSftp Then
  Begin
    Thin(Dc, 2, Rc[3] - FStH, W - 2, Rc[3] - 1, False);
    Txt(Dc, 6, Rc[3] - FStH + 3, Fit(SftpStatus, W - 12), ClrBlack);
  End;
  If (PanelTab = LkMacro) And RecOn Then
    Txt(Dc, 4 + MiniCount * 23 + 4, MiniY + 5, Fit('Enregistrement...', W - MiniCount * 23 - 10), ClrRed);
  Dummy := SelFont(Dc, Old);
  Dummy := PEnd(H, LongInt(@Ps));
  { sans WS_CLIPCHILDREN : la liste se redessine par-dessus le fond }
  Dummy := Inval(Lst[PanelTab].H, 0);
End;

Procedure SetPanelTab(I : LongInt);
Begin
  PanelTab := I;
  OptPanelTab := I;
  MiniHot := -1;
  If I = LkSftp Then
  Begin
    SftpSort;
    If Active >= 0 Then SetText(PathEdit, Sess^[Active].FCwd) Else SetText(PathEdit, '');
    If (Active >= 0) And (Sess^[Active].State = StOpen) And
       Not Sess^[Active].FThreadOn Then StartSftp(Active);
  End;
  PanelLayout;
  Dummy := FocusTo(Lst[I].H);
End;

Function PanelProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var X, Y, I : LongInt;
Begin
  PanelProc0 := 0;
  Case Msg Of
    EvPaint : PanelPaint(H);
    EvErase : PanelProc0 := 1;
    EvSize : PanelLayout;
    EvLDown :
    Begin
      X := S16(LP); Y := S16(LP Shr 16);
      If (Y >= QcRowH) And (Y < QcRowH + PTabH) Then
      Begin
        For I := 0 To 3 Do
          If (X >= PTabX(I)) And (X < PTabX(I + 1)) Then SetPanelTab(I);
      End
      Else
      Begin
        I := MiniHit(X, Y);
        If I >= 0 Then DoCmd(MiniCmd(I));
      End;
    End;
    EvMove :
    Begin
      I := MiniHit(S16(LP), S16(LP Shr 16));
      If I <> MiniHot Then
      Begin
        MiniHot := I;
        If I >= 0 Then SetTip(CmdTip(MiniCmd(I))) Else SetTip('');
        Dummy := Inval(H, 0);
      End;
    End;
    EvCommand : DoCmd(WP And $FFFF);
  Else
    PanelProc0 := NoProc;
  End;
End;

{ ==================================================================== }
{ Fenetre principale                                                    }
{ ==================================================================== }

Const
  CmQuick = 199;
  TbH = 50; StH = 20; TabH = 23; SplitW = 4;
  TbN = 10;

Var
  CW0, CH0 : LongInt;
  TermSb : LongInt;
  TbHot, TbDown : LongInt;
  MultiExec, Blink, Selecting : Boolean;
  MainMenu, MView, MSet, MMac, MTools, MSess : LongInt;
  Splitting, MenuPending : Boolean;
  TabX : Array[0..MaxSess] Of LongInt;   { abscisse de chaque onglet }
  TabOrder : Array[0..MaxSess - 1] Of LongInt;
  TabN : LongInt;
  HomeHit : Array[0..15] Of LongInt;      { sessions de l'accueil }
  HomeN : LongInt;

Procedure SetTip(S : String);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = StatusTip Then Exit;
  StatusTip := S;
  Rc[0] := 0; Rc[1] := CH0 - StH; Rc[2] := CW0; Rc[3] := CH0;
  Dummy := Inval(MainWnd, LongInt(@Rc));
End;

{ ---- schemas de couleurs ---- }

Procedure SchemeColors(Var Fg, Bg : LongInt);
Begin
  Case OptScheme Of
    1 : Begin Fg := 0; Bg := 15; End;
    2 : Begin Fg := 10; Bg := 0; End;
    3 : Begin Fg := 11; Bg := 0; End;
  Else
    Begin Fg := 7; Bg := 0; End;
  End;
End;

Function TermX0 : LongInt;
Begin
  If OptPanel Then TermX0 := PanelW + SplitW Else TermX0 := 0;
End;

Function TermY0 : LongInt;
Var Y : LongInt;
Begin
  Y := 0;
  If OptToolbar Then Y := TbH;
  TermY0 := Y + TabH;
End;

Function TabsY : LongInt;
Begin
  If OptToolbar Then TabsY := TbH Else TabsY := 0;
End;

{ ---- barre d'outils ---- }

Function TbLabel(I : LongInt) : String;
Begin
  Case I Of
    0 : TbLabel := 'Session';
    1 : TbLabel := 'Sessions';
    2 : TbLabel := 'Outils';
    3 : TbLabel := 'Affichage';
    4 : TbLabel := 'MultiExec';
    5 : TbLabel := 'Macros';
    6 : TbLabel := 'SFTP';
    7 : TbLabel := 'Param'#232'tres';
    8 : TbLabel := 'Aide';
  Else
    TbLabel := 'Quitter';
  End;
End;

Function TbTip(I : LongInt) : String;
Begin
  Case I Of
    0 : TbTip := 'Cr'#233'er une nouvelle session SSH';
    1 : TbTip := 'Ouvrir une session enregistr'#233'e (sessions.xml)';
    2 : TbTip := 'Outils d''OS/2-0';
    3 : TbTip := 'Afficher ou masquer le panneau de gauche';
    4 : TbTip := 'MultiExec : la frappe va dans tous les terminaux ouverts';
    5 : TbTip := 'Macros enregistr'#233'es';
    6 : TbTip := 'Navigateur SFTP de la session active';
    7 : TbTip := 'Configuration du Client SSH';
    8 : TbTip := 'Aide et '#224' propos';
  Else
    TbTip := 'Quitter le Client SSH';
  End;
End;

Function TbX(I : LongInt) : LongInt;
Begin
  If I = TbN - 1 Then TbX := CW0 - 60
  Else TbX := 4 + I * 59;
End;

Procedure TbIcon(Dc, I, X, Y : LongInt);
Var K : LongInt;
Begin
  Case I Of
    0 :
    Begin
      Box(Dc, X + 1, Y + 2, X + 23, Y + 18, ClrBlack, ClrNavy);
      Bar(Dc, X + 3, Y + 5, X + 21, Y + 16, ClrBlack);
      Txt(Dc, X + 5, Y + 4, '>_', $00FF00);
      Bar(Dc, X + 8, Y + 18, X + 16, Y + 21, ClrShadow);
      Bar(Dc, X + 15, Y + 13, X + 25, Y + 15, ClrGreen); Bar(Dc, X + 19, Y + 9, X + 21, Y + 19, ClrGreen);
    End;
    1 :
    Begin
      Bar(Dc, X + 10, Y + 1, X + 14, Y + 8, ClrYellow); Bar(Dc, X + 2, Y + 8, X + 22, Y + 12, ClrYellow);
      Bar(Dc, X + 6, Y + 12, X + 18, Y + 17, ClrYellow); Bar(Dc, X + 4, Y + 17, X + 9, Y + 22, ClrYellow);
      Bar(Dc, X + 15, Y + 17, X + 20, Y + 22, ClrYellow);
      Bar(Dc, X + 10, Y + 12, X + 14, Y + 15, ClrOlive);
    End;
    2 :
    Begin
      Bar(Dc, X + 4, Y + 15, X + 20, Y + 22, ClrMaroon); Bar(Dc, X + 6, Y + 17, X + 18, Y + 20, ClrRed);
      Bar(Dc, X + 11, Y + 2, X + 13, Y + 15, ClrShadow);
      Bar(Dc, X + 7, Y + 2, X + 17, Y + 6, ClrBlack);
    End;
    3 :
    Begin
      Box(Dc, X + 1, Y + 2, X + 23, Y + 20, ClrBlack, ClrWin);
      Bar(Dc, X + 1, Y + 2, X + 23, Y + 5, ClrNavy);
      Bar(Dc, X + 2, Y + 5, X + 9, Y + 19, ClrFace);
      Bar(Dc, X + 9, Y + 5, X + 10, Y + 19, ClrShadow);
    End;
    4 :
    Begin
      Bar(Dc, X + 11, Y + 2, X + 13, Y + 12, ClrNavy);
      Bar(Dc, X + 4, Y + 12, X + 20, Y + 14, ClrNavy);
      Bar(Dc, X + 4, Y + 12, X + 6, Y + 20, ClrNavy); Bar(Dc, X + 11, Y + 12, X + 13, Y + 20, ClrNavy);
      Bar(Dc, X + 18, Y + 12, X + 20, Y + 20, ClrNavy);
      Box(Dc, X + 1, Y + 18, X + 9, Y + 23, ClrBlack, ClrBlack);
      Box(Dc, X + 8, Y + 18, X + 16, Y + 23, ClrBlack, ClrBlack);
      Box(Dc, X + 15, Y + 18, X + 23, Y + 23, ClrBlack, ClrBlack);
      If MultiExec Then Bar(Dc, X + 2, Y + 19, X + 22, Y + 22, $00FF00);
    End;
    5 :
    Begin
      Box(Dc, X + 2, Y + 3, X + 22, Y + 21, ClrBlack, ClrWin);
      For K := 0 To 3 Do Bar(Dc, X + 5, Y + 6 + K * 4, X + 7, Y + 8 + K * 4, ClrNavy);
      For K := 0 To 3 Do Bar(Dc, X + 9, Y + 6 + K * 4, X + 19, Y + 8 + K * 4, ClrShadow);
      Box(Dc, X + 13, Y + 13, X + 23, Y + 23, ClrMaroon, ClrRed);
    End;
    6 :
    Begin
      Box(Dc, X + 1, Y + 5, X + 13, Y + 21, ClrBlack, ClrYellow);
      Box(Dc, X + 1, Y + 3, X + 7, Y + 6, ClrBlack, ClrYellow);
      Box(Dc, X + 12, Y + 3, X + 23, Y + 21, ClrBlack, ClrTeal);
      Bar(Dc, X + 14, Y + 6, X + 21, Y + 8, ClrHi); Bar(Dc, X + 14, Y + 10, X + 21, Y + 12, ClrHi);
      Bar(Dc, X + 14, Y + 14, X + 21, Y + 16, ClrHi);
    End;
    7 :
    Begin
      Box(Dc, X + 6, Y + 6, X + 18, Y + 18, ClrNavy, ClrBlue);
      Bar(Dc, X + 10, Y + 2, X + 14, Y + 22, ClrNavy); Bar(Dc, X + 2, Y + 10, X + 22, Y + 14, ClrNavy);
      Box(Dc, X + 9, Y + 9, X + 15, Y + 15, ClrNavy, ClrFace);
    End;
    8 :
    Begin
      Box(Dc, X + 3, Y + 2, X + 21, Y + 22, ClrNavy, ClrBlue);
      Txt(Dc, X + 9, Y + 6, '?', ClrHi); Txt(Dc, X + 10, Y + 6, '?', ClrHi);
    End;
  Else
    Begin
      Box(Dc, X + 3, Y + 2, X + 21, Y + 22, ClrMaroon, ClrRed);
      Bar(Dc, X + 11, Y + 5, X + 13, Y + 13, ClrHi);
      Bar(Dc, X + 7, Y + 9, X + 9, Y + 18, ClrHi); Bar(Dc, X + 15, Y + 9, X + 17, Y + 18, ClrHi);
      Bar(Dc, X + 7, Y + 17, X + 17, Y + 19, ClrHi);
    End;
  End;
End;

{ ---- onglets des sessions ---- }

Procedure TabsBuild;
Var I : LongInt;
Begin
  TabN := 0;
  For I := 0 To MaxSess - 1 Do
    If Sess^[I].Used Then
    Begin
      TabOrder[TabN] := I; Inc(TabN);
    End;
End;

Function TabTitle(I : LongInt) : String;
Begin
  TabTitle := IStr(I + 1) + '. ' + Sess^[I].Title;
End;

Function TabW(I : LongInt) : LongInt;
Begin
  TabW := MinI(Length(TabTitle(I)), 18) * CW + 44;
End;

Procedure PaintTabs(Dc : LongInt);
Var X, Y, K, I, W, C : LongInt; Sel : Boolean;
Begin
  Y := TabsY;
  X := TermX0;
  Bar(Dc, X, Y, CW0, Y + TabH, ClrFace);
  { accueil }
  Sel := Active < 0;
  If Sel Then Bevel(Dc, X + 2, Y + 1, X + 30, Y + TabH + 1, True)
  Else Thin(Dc, X + 2, Y + 3, X + 30, Y + TabH, True);
  Bar(Dc, X + 15, Y + 6, X + 17, Y + 7, ClrMaroon); Bar(Dc, X + 12, Y + 7, X + 20, Y + 9, ClrMaroon);
  Bar(Dc, X + 10, Y + 9, X + 22, Y + 11, ClrMaroon);
  Box(Dc, X + 11, Y + 11, X + 21, Y + 19, ClrBlack, ClrWin);
  Bar(Dc, X + 15, Y + 14, X + 17, Y + 19, ClrNavy);
  X := X + 32;
  TabX[0] := X;
  For K := 0 To TabN - 1 Do
  Begin
    I := TabOrder[K];
    W := TabW(I);
    If X + W > CW0 - 26 Then W := MaxI(40, CW0 - 26 - X);
    Sel := I = Active;
    If Sel Then
    Begin
      Bar(Dc, X, Y + 1, X + W, Y + TabH + 1, ClrFace);
      Bar(Dc, X, Y + 1, X + W, Y + 2, ClrHi); Bar(Dc, X, Y + 1, X + 1, Y + TabH, ClrHi);
      Bar(Dc, X + W - 1, Y + 1, X + W, Y + TabH, ClrDark);
    End
    Else
    Begin
      Bar(Dc, X, Y + 3, X + W, Y + 4, ClrHi); Bar(Dc, X, Y + 3, X + 1, Y + TabH, ClrHi);
      Bar(Dc, X + W - 1, Y + 3, X + W, Y + TabH, ClrShadow);
    End;
    { etat : vert ouvert, jaune connexion, rouge termine }
    Case Sess^[I].State Of
      StOpen : C := $00C000;
      StConn : C := $00C0C0;
    Else
      C := $0000C0;
    End;
    Icon16(Dc, IcTerm, X + 4, Y + 4);
    Bar(Dc, X + 15, Y + 13, X + 20, Y + 18, C);
    Txt(Dc, X + 24, Y + 6, Fit(TabTitle(I), W - 42), ClrBlack);
    { croix de fermeture }
    Bar(Dc, X + W - 14, Y + 8, X + W - 12, Y + 10, ClrShadow);
    Bar(Dc, X + W - 12, Y + 10, X + W - 10, Y + 12, ClrShadow);
    Bar(Dc, X + W - 10, Y + 12, X + W - 8, Y + 14, ClrShadow);
    Bar(Dc, X + W - 10, Y + 8, X + W - 8, Y + 10, ClrShadow);
    Bar(Dc, X + W - 14, Y + 12, X + W - 12, Y + 14, ClrShadow);
    X := X + W + 1;
    TabX[K + 1] := X;
  End;
  { + : nouvelle session }
  Thin(Dc, X + 2, Y + 5, X + 22, Y + TabH - 1, True);
  Bar(Dc, X + 8, Y + 12, X + 16, Y + 14, ClrBlack); Bar(Dc, X + 11, Y + 9, X + 13, Y + 17, ClrBlack);
  Bar(Dc, TermX0, Y + TabH - 1, CW0, Y + TabH, ClrShadow);
End;

{ ---- terminal : mise a jour ---- }

Procedure TermSbSync;
Var M : LongInt;
Begin
  If Active < 0 Then
  Begin
    SbSet(TermSb, 0, 0, 1);
    Dummy := WinEnableWindow(TermSb, 0);
    Exit;
  End;
  M := Sess^[Active].Term.HistN;
  SbSet(TermSb, M - Sess^[Active].Term.ScrollOff, M, TermRows);
  Dummy := WinEnableWindow(TermSb, Ord(M > 0));
End;

Procedure TermInval(A, B : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[0] := 0; Rc[1] := A * TFH; Rc[2] := TermCols * TFW + 1; Rc[3] := (B + 1) * TFH;
  Dummy := Inval(TermWnd, LongInt(@Rc));
End;

Procedure UpdateTitle;
Var S : String;
Begin
  S := 'Client SSH';
  If (Active >= 0) And Sess^[Active].Used Then
  Begin
    If Sess^[Active].Term.TitleSet Then S := Sess^[Active].Term.Title + ' - ' + S
    Else S := Sess^[Active].Title + ' - ' + S;
  End;
  SetText(Frame, S);
End;

Procedure SetActive(I : LongInt);
Begin
  Active := I;
  If I >= 0 Then Sess^[I].Term.DirtyA := 1;
  TabsBuild;
  TermSbSync;
  SftpSort;
  If PanelTab = LkSftp Then
  Begin
    If Active >= 0 Then SetText(PathEdit, Sess^[Active].FCwd) Else SetText(PathEdit, '');
    If (Active >= 0) And (Sess^[Active].State = StOpen) And
       Not Sess^[Active].FThreadOn And OptAutoSftp Then StartSftp(Active);
    LRepaint(LkSftp);
  End;
  Dummy := Inval(PanelWnd, 0);
  Dummy := Inval(TermWnd, 0);
  Dummy := Inval(MainWnd, 0);
  UpdateTitle;
  Dummy := FocusTo(TermWnd);
End;

{ octets recus d'une session : au terminal (par paquets) }
Procedure TermData(I : LongInt);
Var N : LongInt;
Begin
  Sess^[I].InPosted := False;
  If Not Sess^[I].Used Then Exit;
  N := MinI(Sess^[I].InLen, 16384);
  If N <= 0 Then Exit;
  TmLoad(@Sess^[I].Term);
  T.DirtyA := 1; T.DirtyB := 0;
  TmOut := '';
  TmFeed(Sess^[I].InBuf, N);
  CopyB(Sess^[I].InBuf + N, Sess^[I].InBuf, Sess^[I].InLen - N);
  Sess^[I].InLen := Sess^[I].InLen - N;
  If T.Bell Then
  Begin
    T.Bell := False;
    If OptBell Then Dummy := WinAlarm(HWND_DESKTOP, 0);
  End;
  If T.TitleSet And (I = Active) Then UpdateTitle;
  TmSave(@Sess^[I].Term);
  If TmOut <> '' Then SendKeys(I, TmOut);
  If I = Active Then
  Begin
    If Sess^[I].Term.ScrollOff > 0 Then Dummy := Inval(TermWnd, 0)
    Else If Sess^[I].Term.DirtyA <= Sess^[I].Term.DirtyB Then
      TermInval(Sess^[I].Term.DirtyA, Sess^[I].Term.DirtyB);
    TermInval(Sess^[I].Term.CY, Sess^[I].Term.CY);
    TermSbSync;
  End;
  If Sess^[I].InLen > 0 Then PostTerm(I);
End;

{ taille du terminal d'apres la vue }
Procedure TermFit;
Var Rc : Array[0..3] Of LongInt; C, R, I : LongInt;
Begin
  Dummy := CliRect(TermWnd, LongInt(@Rc));
  C := MinI(MaxI((Rc[2] - SbW) Div TFW, 10), MaxCols);
  R := MinI(MaxI(Rc[3] Div TFH, 3), MaxRows);
  If (C = TermCols) And (R = TermRows) Then Exit;
  TermCols := C; TermRows := R;
  For I := 0 To MaxSess - 1 Do
    If Sess^[I].Used Then
    Begin
      TmLoad(@Sess^[I].Term);
      TmResize(C, R);
      TmSave(@Sess^[I].Term);
      Sess^[I].WantCols := C; Sess^[I].WantRows := R;
      If Sess^[I].State = StOpen Then Sess^[I].ResizeReq := True;
    End;
  Dummy := Place(TermSb, Rc[2] - SbW, 0, SbW, Rc[3]);
  Dummy := Inval(TermWnd, 0);
End;

{ ---- sessions : ouvrir, fermer ---- }

Function NewSlot : LongInt;
Var I : LongInt;
Begin
  NewSlot := -1;
  For I := 0 To MaxSess - 1 Do
    If Not Sess^[I].Used And Not Sess^[I].ThreadOn And Not Sess^[I].FThreadOn Then
    Begin
      NewSlot := I;
      Exit;
    End;
End;

Procedure OpenSession(D : TSessDef);
Var I, Fg, Bg : LongInt; S : String;
Begin
  If D.User = '' Then
  Begin
    S := OptLastUser;
    If Not InputBox('Connexion '#224' ' + D.Host, 'Nom d''utilisateur :', S, False) Then Exit;
    D.User := TrimS(S);
    If D.User = '' Then Exit;
  End;
  If D.Pass = '' Then
  Begin
    S := '';
    If Not InputBox('Connexion '#224' ' + D.Host, 'Mot de passe de ' + D.User + '@' + D.Host + ' :',
                    S, True) Then Exit;
    D.Pass := S;
  End;
  OptLastUser := D.User;
  I := NewSlot;
  If I < 0 Then
  Begin
    Ask('Trop de sessions ouvertes (' + IStr(MaxSess) + ' au plus).', 'Client SSH',
        MB_OK Or MB_ICONINFO);
    Exit;
  End;
  SchemeColors(Fg, Bg);
  Sess^[I].Def := D;
  Sess^[I].Title := D.Name;
  If Sess^[I].InBuf = 0 Then
  Begin
    Sess^[I].InBuf := TlNew(InMax + 16);
    Sess^[I].OutBuf := TlNew(OutMax + 16);
    TmCreate(@Sess^[I].Term, TermCols, TermRows, OptHist, Fg, Bg);
  End
  Else
  Begin
    TmLoad(@Sess^[I].Term);
    T.DefFg := Fg; T.DefBg := Bg; T.HistLim := OptHist;
    T.HistN := 0; T.HistHead := 0; T.ScrollOff := 0; T.SelOn := False;
    T.Title := ''; T.TitleSet := False;
    TmResize(TermCols, TermRows);
    TmFullReset;
    TmSave(@Sess^[I].Term);
  End;
  Sess^[I].InLen := 0; Sess^[I].InPosted := False;
  Sess^[I].HostFp := '';
  Sess^[I].FState := FsNone; Sess^[I].FN := 0; Sess^[I].FCwd := '';
  Sess^[I].FMsg := ''; Sess^[I].FErr := '';
  Sess^[I].Used := True;
  TmLoad(@Sess^[I].Term);
  TmText(#27'[1;37mClient SSH d''OS/2-0'#27'[0m'#13#10);
  TmText(#27'[1;30mConnexion '#133' ' + Disp(D.User + '@' + D.Host + ':' + IStr(D.Port)) +
         '...'#27'[0m'#13#10);
  TmSave(@Sess^[I].Term);
  StartThread(I);
  SetActive(I);
  SaveOptions;
End;

Procedure Reconnect(I : LongInt);
Var Fg, Bg : LongInt;
Begin
  If (I < 0) Or Not Sess^[I].Used Then Exit;
  If Sess^[I].ThreadOn Or Sess^[I].FThreadOn Then
  Begin
    Sess^[I].CloseReq := True;
    Ask('La session se ferme ; r'#233'essayez dans un instant.', 'Reconnecter', MB_OK Or MB_ICONINFO);
    Exit;
  End;
  SchemeColors(Fg, Bg);
  TmLoad(@Sess^[I].Term);
  TmText(#13#10#27'[1;30mReconnexion '#133' ' + Disp(Sess^[I].Def.Host) + '...'#27'[0m'#13#10);
  TmSave(@Sess^[I].Term);
  Sess^[I].InLen := 0;
  Sess^[I].FState := FsNone; Sess^[I].FN := 0;
  StartThread(I);
  SetActive(I);
End;

Procedure CloseTab(I : LongInt);
Var K, J : LongInt;
Begin
  If (I < 0) Or Not Sess^[I].Used Then Exit;
  If Sess^[I].State = StOpen Then
    If Ask('Fermer la session "' + Sess^[I].Title + '" ?', 'Client SSH',
           MB_YESNO Or MB_ICONQUESTION) <> IDYES Then Exit;
  Sess^[I].CloseReq := True;
  Sess^[I].FCancel := True;
  Sess^[I].Used := False;
  If Sess^[I].FEv <> 0 Then Dummy := DosPostEventSem(Sess^[I].FEv);
  { onglet voisin }
  J := -1;
  For K := 0 To TabN - 1 Do
    If TabOrder[K] = I Then
    Begin
      If K + 1 < TabN Then J := TabOrder[K + 1]
      Else If K > 0 Then J := TabOrder[K - 1];
    End;
  If Active = I Then SetActive(J) Else SetActive(Active);
End;

{ ---- presse-papiers et texte ---- }

Procedure SendInput(S : String);
Var I : LongInt;
Begin
  If RecOn And (Length(RecKeys) + Length(S) < 250) Then RecKeys := RecKeys + S;
  If MultiExec Then
  Begin
    For I := 0 To MaxSess - 1 Do
      If Sess^[I].Used And (Sess^[I].State = StOpen) Then SendKeys(I, S);
  End
  Else SendKeys(Active, S);
  If (Active >= 0) And (Sess^[Active].Term.ScrollOff > 0) Then
  Begin
    Sess^[Active].Term.ScrollOff := 0;
    TermSbSync;
    Dummy := Inval(TermWnd, 0);
  End;
End;

{ caractere tape (page de l'ecran) -> UTF-8 }
Function KeyU8(C : LongInt) : String;
Begin
  If C < 128 Then KeyU8 := Chr(C)
  Else If OemOut <> 0 Then KeyU8 := U8Of(OemToUni(C))
  Else KeyU8 := U8Of(C);
End;

Procedure DoPaste;
Var N, I, C : LongInt; S : String;
Begin
  If (Active < 0) Or (Sess^[Active].State <> StOpen) Then Exit;
  N := ClipGet;
  If N = 0 Then Exit;
  If Sess^[Active].Term.Paste2004 Then SendInput(#27'[200~');
  S := '';
  For I := 0 To N - 1 Do
  Begin
    C := TlGet(ClipBuf + I);
    If C = 10 Then
    Begin
      If (I = 0) Or (TlGet(ClipBuf + I - 1) <> 13) Then S := S + #13;
    End
    Else S := S + KeyU8(C);
    If Length(S) > 200 Then Begin SendInput(S); S := ''; End;
  End;
  If S <> '' Then SendInput(S);
  If Sess^[Active].Term.Paste2004 Then SendInput(#27'[201~');
End;

Procedure DoCopy;
Var N : LongInt;
Begin
  If Active < 0 Then Exit;
  If ClipBuf = 0 Then ClipBuf := TlNew(65536);
  TmLoad(@Sess^[Active].Term);
  N := TmSelText(ClipBuf, 65536);
  If N > 0 Then CopyBytes(ClipBuf, N);
End;

Procedure SaveTermText;
Var P : String; H, L, C, N, Last, V : LongInt; R : TlPtr; B : Array[0..MaxCols + 2] Of Byte;
Begin
  If Active < 0 Then Exit;
  P := LJoin(OptDlDir, 'terminal.txt');
  If Not FileDlg(True, 'Enregistrer le texte du terminal', 'Fichiers texte (*.txt)|*.txt|Tous les fichiers|*.*', P) Then Exit;
  H := LfCreate(P, False);
  If H = -1 Then
  Begin
    Ask('Impossible de cr'#233'er ' + P + '.', 'Client SSH', MB_OK Or MB_ICONERROR);
    Exit;
  End;
  TmLoad(@Sess^[Active].Term);
  For L := 0 To T.HistN + T.Rows - 1 Do
  Begin
    If L < T.HistN Then R := RowPtr(T.Hist, (T.HistHead + L) Mod HistMax)
    Else R := RowPtr(CurScr, L - T.HistN);
    Last := -1;
    For C := 0 To T.Cols - 1 Do
      If (PLng(R + C * 4)^ And 255) > 32 Then Last := C;
    N := 0;
    For C := 0 To Last Do
    Begin
      V := PLng(R + C * 4)^ And 255;
      If V = 0 Then V := 32;
      B[N] := V; Inc(N);
    End;
    B[N] := 13; B[N + 1] := 10;
    If LfWrite(H, TlPtr(@B[0]), N + 2) Then;
  End;
  LfClose(H);
End;

{ ---- vue du terminal ---- }

Procedure HomePaint(Dc, W, H : LongInt);
Var Old, Y, I, X : LongInt; D : TSessDef;
Begin
  Bar(Dc, 0, 0, W, H, ClrWin);
  Bar(Dc, 0, 0, W, 64, ClrNavy);
  Old := SelFont(Dc, TermFnt);
  Txt(Dc, 20, 14, 'Client SSH d''OS/2-0', ClrHi);
  Dummy := SelFont(Dc, Fnt);
  Txt(Dc, 20, 38, 'Terminal xterm, navigateur SFTP, macros, sessions en XML', $FFFF80);
  { boutons }
  Bevel(Dc, 20, 80, 190, 110, True);
  Icon16(Dc, IcTerm, 28, 87);
  Txt(Dc, 50, 89, 'Nouvelle session...', ClrBlack);
  Bevel(Dc, 200, 80, 370, 110, True);
  Icon16(Dc, IcComputer, 208, 87);
  Txt(Dc, 230, 89, 'Configuration...', ClrBlack);
  Txt(Dc, 20, 126, 'Sessions enregistr'#233'es (double-cliquez pour ouvrir) :', ClrNavy);
  Bar(Dc, 20, 142, W - 20, 143, ClrShadow);
  Y := 150;
  HomeN := 0;
  For I := 0 To DefN - 1 Do
    If (Y + 18 < H - 24) And (HomeN < 16) Then
    Begin
      D := Defs^[I];
      Icon16(Dc, IcTerm, 24, Y);
      Txt(Dc, 46, Y + 2, Fit(D.Name, 200), ClrBlack);
      X := 260;
      Txt(Dc, X, Y + 2, Fit(D.User + '@' + D.Host + ':' + IStr(D.Port), W - X - 20), ClrShadow);
      HomeHit[HomeN] := I; Inc(HomeN);
      Y := Y + 20;
    End;
  If DefN = 0 Then
    Txt(Dc, 24, Y, '(aucune : utilisez Nouvelle session ou la connexion rapide '#224' gauche)', ClrShadow);
  Txt(Dc, 20, H - 20, 'Connexion rapide : utilisateur@serveur:port, puis Entr'#233'e.', ClrShadow);
  Dummy := SelFont(Dc, Old);
End;

Procedure TermPaint(H : LongInt);
Var Ps : Array[0..15] Of LongInt; Rc : Array[0..3] Of LongInt; Dc, Old, R0, R1, W : LongInt;
Begin
  Dc := PBegin(H, LongInt(@Ps));
  Dummy := CliRect(H, LongInt(@Rc));
  W := Rc[2] - SbW;
  If Active < 0 Then HomePaint(Dc, W, Rc[3])
  Else
  Begin
    Old := SelFont(Dc, TermFnt);
    TmLoad(@Sess^[Active].Term);
    R0 := Ps[3] Div TFH; R1 := (Ps[5] - 1) Div TFH;
    TmPaint(Dc, 0, 0, R0, R1, FocusWnd = H, Blink);
    { marges }
    Bar(Dc, T.Cols * TFW, 0, W, Rc[3], Pal[T.DefBg]);
    Bar(Dc, 0, T.Rows * TFH, T.Cols * TFW, Rc[3], Pal[T.DefBg]);
    Dummy := SelFont(Dc, Old);
  End;
  Dummy := PEnd(H, LongInt(@Ps));
End;

Procedure TermScroll(N : LongInt);
Begin
  If Active < 0 Then Exit;
  TmLoad(@Sess^[Active].Term);
  T.ScrollOff := MinI(MaxI(T.ScrollOff + N, 0), T.HistN);
  TmSave(@Sess^[Active].Term);
  TermSbSync;
  Dummy := Inval(TermWnd, 0);
End;

Procedure TermMenu(X, Y : LongInt);
Var M : LongInt; P : Array[0..1] Of LongInt;
Begin
  M := MkPopup;
  MItem(M, CmCopy, '~Copier');
  MItem(M, CmPaste, 'C~oller');
  MItem(M, CmSelAll, '~S'#233'lectionner tout');
  MItem(M, 0, '');
  MItem(M, CmClearHist, '~Effacer l''historique');
  MItem(M, CmResetTerm, '~R'#233'initialiser le terminal');
  MItem(M, CmSaveText, 'E~nregistrer le texte du terminal...');
  MItem(M, 0, '');
  MItem(M, CmReconnect, 'Re~connecter');
  MItem(M, CmDupTab, '~Dupliquer l''onglet');
  MItem(M, CmCloseTab, '~Fermer l''onglet');
  P[0] := X; P[1] := Y;
  Dummy := ToScreen(TermWnd, LongInt(@P[0]));
  TrackMenu(M, P[0], P[1]);
End;

Procedure HomeClick(X, Y : LongInt; Dbl : Boolean);
Var I : LongInt;
Begin
  If (Y >= 80) And (Y < 110) Then
  Begin
    If (X >= 20) And (X < 190) Then DoCmd(CmNewSess)
    Else If (X >= 200) And (X < 370) Then DoCmd(CmConfig);
    Exit;
  End;
  I := (Y - 150) Div 20;
  If (Y >= 150) And (I < HomeN) And Dbl Then OpenSession(Defs^[HomeHit[I]]);
End;

Function TermProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var X, Y, C, V : LongInt; S : String; Sh, Ct : Boolean; A : Double;
Begin
  TermProc0 := 0;
  Case Msg Of
    EvPaint : TermPaint(H);
    EvErase : TermProc0 := 1;
    EvSize : TermFit;
    EvSetFocus, EvKillFocus :
      If Active >= 0 Then TermInval(Sess^[Active].Term.CY, Sess^[Active].Term.CY);
    EvLDown, EvLDbl :
    Begin
      Dummy := FocusTo(H);
      X := S16(LP); Y := S16(LP Shr 16);
      If Active < 0 Then
      Begin
        HomeClick(X, Y, Msg = EvLDbl);
        Exit;
      End;
      C := MinI(MaxI(X Div TFW, 0), TermCols - 1);
      V := MinI(MaxI(Y Div TFH, 0), TermRows - 1);
      TmLoad(@Sess^[Active].Term);
      If Msg = EvLDbl Then
      Begin
        T.SelOn := False;
        TmSelWord(V, C);
        TmSave(@Sess^[Active].Term);
        If OptCopySel Then DoCopy;
      End
      Else
      Begin
        T.SelOn := False;
        A := ViewAbs(V, C);
        T.SelA := A; T.SelB := A;
        TmSave(@Sess^[Active].Term);
        Selecting := True;
        Dummy := Capture(H);
      End;
      Dummy := Inval(H, 0);
    End;
    EvMove :
      If Selecting And (Active >= 0) Then
      Begin
        X := S16(LP); Y := S16(LP Shr 16);
        If Y < 0 Then TermScroll(1)
        Else If Y >= TermRows * TFH Then TermScroll(-1);
        C := MinI(MaxI(X Div TFW, 0), TermCols - 1);
        V := MinI(MaxI(Y Div TFH, 0), TermRows - 1);
        TmLoad(@Sess^[Active].Term);
        A := ViewAbs(V, C);
        If A <> T.SelB Then
        Begin
          T.SelB := A;
          T.SelOn := T.SelA <> T.SelB;
          TmSave(@Sess^[Active].Term);
          Dummy := Inval(H, 0);
        End;
      End;
    EvLUp :
      If Selecting Then
      Begin
        Selecting := False;
        Dummy := Capture(0);
        If (Active >= 0) And Sess^[Active].Term.SelOn And OptCopySel Then DoCopy;
      End;
    EvRDown :
      If Active >= 0 Then
      Begin
        If OptRightPaste And ((GetKeyState(VK_SHIFT) And $8000) = 0) Then DoPaste
        Else TermMenu(S16(LP), S16(LP Shr 16));
      End;
    EvMDown : DoPaste;
    EvWheel :
      If S16(WP Shr 16) > 0 Then TermScroll(3) Else TermScroll(-3);
    EvVScroll :
      If Active >= 0 Then
      Begin
        Case WP And $FFFF Of
          0 : TermScroll(1);
          1 : TermScroll(-1);
          2 : TermScroll(TermRows);
          3 : TermScroll(-TermRows);
          4, 5 : TermScroll((Sess^[Active].Term.HistN - ((WP Shr 16) And $FFFF)) -
                            Sess^[Active].Term.ScrollOff);
        End;
      End;
    EvKeyDown :
    Begin
      If Active < 0 Then Exit;
      Sh := (GetKeyState(VK_SHIFT) And $8000) <> 0;
      Ct := (GetKeyState(VK_CONTROL) And $8000) <> 0;
      If Sh And (WP = VK_PRIOR) Then TermScroll(TermRows - 1)
      Else If Sh And (WP = VK_NEXT) Then TermScroll(-(TermRows - 1))
      Else If Sh And (WP = VK_INSERT) Then DoPaste
      Else If Ct And (WP = VK_INSERT) Then DoCopy
      Else If Sess^[Active].State = StOpen Then
      Begin
        TmLoad(@Sess^[Active].Term);
        S := TmKey(WP, Sh, Ct);
        If S <> '' Then SendInput(S);
      End;
    End;
    EvChar :
    Begin
      If Active < 0 Then Exit;
      C := WP And 255;
      If (Sess^[Active].State = StEnded) Or (Sess^[Active].State = StFailed) Then
      Begin
        If C = 13 Then CloseTab(Active)
        Else If (C = 82) Or (C = 114) Then Reconnect(Active);
        Exit;
      End;
      If Sess^[Active].State <> StOpen Then Exit;
      If C = 8 Then
      Begin
        If OptBsDel Then SendInput(#127) Else SendInput(#8);
      End
      Else SendInput(KeyU8(C));
    End;
  Else
    TermProc0 := NoProc;
  End;
End;


{ ---- menus ---- }

Procedure BuildMenus;
Var M, Sub, I : LongInt; Nm, Exe : String; Ic : LongInt; Hdr : Boolean;
Begin
  MainMenu := MkMenu;
  M := MkMenu;
  MItem(M, CmNewSess, '~Nouvel onglet SSH...');
  MItem(M, CmDupTab, '~Dupliquer l''onglet');
  MItem(M, CmReconnect, '~Reconnecter');
  MItem(M, CmCloseTab, '~Fermer l''onglet');
  MItem(M, 0, '');
  MItem(M, CmCopy, '~Copier'#9'Ctrl+Inser');
  MItem(M, CmPaste, 'C~oller'#9'Maj+Inser');
  MItem(M, CmSelAll, '~S'#233'lectionner tout');
  MItem(M, 0, '');
  MItem(M, CmClearHist, '~Effacer l''historique');
  MItem(M, CmResetTerm, 'R'#233'~initialiser le terminal');
  MItem(M, CmSaveText, 'Enre~gistrer le texte du terminal...');
  MItem(M, 0, '');
  MItem(M, CmExit, '~Quitter');
  MSub(MainMenu, M, '~Terminal');
  MSess := MkMenu;
  MSub(MainMenu, MSess, '~Sessions');
  MView := MkMenu;
  MItem(MView, CmPanel, '~Panneau lat'#233'ral');
  MItem(MView, 0, '');
  MItem(MView, CmPTab0, 'Onglet ~Sessions');
  MItem(MView, CmPTab0 + 1, 'Onglet ~Outils');
  MItem(MView, CmPTab0 + 2, 'Onglet ~Macros');
  MItem(MView, CmPTab0 + 3, 'Onglet S~FTP');
  MItem(MView, 0, '');
  MItem(MView, CmToolbar, '~Barre d''outils');
  MItem(MView, CmStatus, 'Barre d'''#233'~tat');
  MItem(MView, 0, '');
  MItem(MView, CmNextTab, 'Onglet suiva~nt');
  MItem(MView, CmPrevTab, 'Onglet pr'#233'c'#233'~dent');
  MSub(MainMenu, MView, '~Affichage');
  MTools := MkMenu;
  For I := 0 To ToolN Do
  Begin
    ToolInfo(I, Nm, Exe, Ic, Hdr);
    If Hdr Then
    Begin
      If I > 0 Then MItem(MTools, 0, '');
    End
    Else MItem(MTools, CmTool0 + I, Nm);
  End;
  MSub(MainMenu, MTools, '~Outils');
  MSet := MkMenu;
  MItem(MSet, CmConfig, '~Configuration...');
  MItem(MSet, 0, '');
  Sub := MkMenu;
  MItem(Sub, CmScheme0, '~Blanc sur noir');
  MItem(Sub, CmScheme0 + 1, '~Noir sur blanc');
  MItem(Sub, CmScheme0 + 2, '~Vert sur noir');
  MItem(Sub, CmScheme0 + 3, '~Ambre sur noir');
  MSub(MSet, Sub, '~Couleurs du terminal');
  MItem(MSet, CmCopySel, 'Copier '#224' la ~s'#233'lection');
  MItem(MSet, CmRPaste, 'Le clic ~droit colle');
  MItem(MSet, CmMultiExec, '~MultiExec (frappe dans tous les terminaux)');
  MSub(MainMenu, MSet, '~Param'#232'tres');
  MMac := MkMenu;
  MSub(MainMenu, MMac, '~Macros');
  M := MkMenu;
  MItem(M, CmHelp, '~Aide');
  MItem(M, CmKeys, '~Raccourcis clavier');
  MItem(M, 0, '');
  MItem(M, CmAbout, '~A propos du Client SSH...');
  MSub(MainMenu, M, '~?');
  MenuBarSet(MainMenu);
End;

{ menus dont le contenu change : sessions, macros, coches }
Procedure RefreshMenus;
Var I, K : LongInt;
Begin
  MClear(MSess);
  MItem(MSess, CmNewSess, '~Nouvelle session...');
  MItem(MSess, CmNewFolder, 'Nouveau ~dossier...');
  MItem(MSess, CmEditSess, '~Modifier la session...');
  MItem(MSess, 0, '');
  K := 0;
  For I := 0 To DefN - 1 Do
    If K < 30 Then
    Begin
      MItem(MSess, CmSess0 + I, Defs^[I].Name);
      Inc(K);
    End;
  If DefN > 0 Then MItem(MSess, 0, '');
  MItem(MSess, CmImport, '~Importer des sessions (XML)...');
  MItem(MSess, CmExport, '~Exporter les sessions (XML)...');
  MClear(MMac);
  If RecOn Then MItem(MMac, CmStopMacro, '~Arr'#234'ter l''enregistrement')
  Else MItem(MMac, CmRecMacro, '~Enregistrer une nouvelle macro');
  MItem(MMac, CmNewMacro, '~Nouvelle macro...');
  MItem(MMac, 0, '');
  For I := 0 To MacroN - 1 Do MItem(MMac, CmMacro0 + I, Macros[I].Name);
  MCheck(MView, CmPanel, OptPanel);
  For I := 0 To 3 Do MCheck(MView, CmPTab0 + I, PanelTab = I);
  MCheck(MView, CmToolbar, OptToolbar);
  MCheck(MView, CmStatus, OptStatus);
  For I := 0 To 3 Do MCheck(MSet, CmScheme0 + I, OptScheme = I);
  MCheck(MSet, CmCopySel, OptCopySel);
  MCheck(MSet, CmRPaste, OptRightPaste);
  MCheck(MSet, CmMultiExec, MultiExec);
  { la barre de menus de PM est refaite apres le message en cours (le
    menu qui a envoye la commande peut etre encore ouvert) }
  If Not MenuPending And (MainWnd <> 0) Then
  Begin
    MenuPending := True;
    Dummy := WinPostMsg(MainWnd, EvMenus, 0, 0);
  End;
End;

{ ---- disposition ---- }

Procedure Layout;
Var Y0, B : LongInt;
Begin
  If TermWnd = 0 Then Exit;
  Y0 := TabsY;
  B := CH0;
  If OptStatus Then B := B - StH;
  If OptPanel Then
  Begin
    Dummy := Place(PanelWnd, 0, Y0, PanelW, B - Y0);
    Dummy := Show(PanelWnd, 1);
  End
  Else Dummy := Show(PanelWnd, 0);
  Dummy := Place(TermWnd, TermX0, TermY0, CW0 - TermX0, B - TermY0);
  TermFit;
  Dummy := Inval(MainWnd, 0);
End;

Function StatusText : String;
Var S : String;
Begin
  If StatusTip <> '' Then
  Begin
    StatusText := StatusTip;
    Exit;
  End;
  If Active < 0 Then S := 'Pr'#234't - ' + IStr(DefN) + ' session(s) enregistr'#233'e(s)'
  Else
  Begin
    S := Sess^[Active].Def.User + '@' + Sess^[Active].Def.Host + ':' + IStr(Sess^[Active].Def.Port);
    Case Sess^[Active].State Of
      StConn : S := S + ' - connexion...';
      StOpen : S := S + ' - SSH-2 - ' + IStr(TermCols) + ' x ' + IStr(TermRows) + ' - ' +
                    Sess^[Active].Def.TermName + ' - UTF-8';
      StFailed : S := S + ' - ' + Sess^[Active].Err;
    Else
      S := S + ' - session termin'#233'e';
    End;
  End;
  If MultiExec Then S := 'MultiExec - ' + S;
  If RecOn Then S := 'Enregistrement de macro - ' + S;
  StatusText := S;
End;

Procedure MainPaint(H : LongInt);
Var Ps : Array[0..15] Of LongInt; Dc, Old, I, X, Y, B : LongInt;
Begin
  Dc := PBegin(H, LongInt(@Ps));
  Old := SelFont(Dc, Fnt);
  If OptToolbar Then
  Begin
    Bar(Dc, 0, 0, CW0, TbH, ClrFace);
    Bar(Dc, 0, 0, CW0, 1, ClrHi);
    For I := 0 To TbN - 1 Do
    Begin
      X := TbX(I);
      If I = TbDown Then Bevel(Dc, X, 2, X + 57, TbH - 3, False)
      Else If (I = TbHot) Or ((I = 4) And MultiExec) Or ((I = 3) And OptPanel) Then
        Thin(Dc, X, 2, X + 57, TbH - 3, True);
      TbIcon(Dc, I, X + 16 + Ord(I = TbDown), 4 + Ord(I = TbDown));
      Txt(Dc, X + 29 - Length(TbLabel(I)) * CW Div 2, 32, TbLabel(I), ClrBlack);
    End;
    Bar(Dc, 0, TbH - 2, CW0, TbH - 1, ClrShadow); Bar(Dc, 0, TbH - 1, CW0, TbH, ClrHi);
  End;
  PaintTabs(Dc);
  B := CH0;
  If OptStatus Then B := CH0 - StH;
  { separateur du panneau }
  If OptPanel Then
  Begin
    Y := TabsY;
    Bar(Dc, PanelW, Y, PanelW + SplitW, B, ClrFace);
    Bar(Dc, PanelW + SplitW - 1, Y, PanelW + SplitW, B, ClrShadow);
  End;
  If OptStatus Then
  Begin
    Y := CH0 - StH;
    Bar(Dc, 0, Y, CW0, CH0, ClrFace);
    Thin(Dc, 2, Y + 2, CW0 - 2, CH0 - 2, False);
    Txt(Dc, 6, Y + 4, Fit(StatusText, CW0 - 12), ClrBlack);
  End;
  Dummy := SelFont(Dc, Old);
  Dummy := PEnd(H, LongInt(@Ps));
End;

Function TbAt(X, Y : LongInt) : LongInt;
Var I : LongInt;
Begin
  TbAt := -1;
  If Not OptToolbar Or (Y < 2) Or (Y >= TbH - 3) Then Exit;
  For I := 0 To TbN - 1 Do
    If (X >= TbX(I)) And (X < TbX(I) + 57) Then TbAt := I;
End;

Procedure PopupAt(M, X, Y : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  P[0] := X; P[1] := Y;
  Dummy := ToScreen(MainWnd, LongInt(@P[0]));
  TrackMenu(M, P[0], P[1]);
End;

Procedure TbClick(I : LongInt);
Begin
  RefreshMenus;
  Case I Of
    0 : DoCmd(CmNewSess);
    1 : PopupAt(MSess, TbX(1), TbH - 2);
    2 : PopupAt(MTools, TbX(2), TbH - 2);
    3 : DoCmd(CmPanel);
    4 : DoCmd(CmMultiExec);
    5 : PopupAt(MMac, TbX(5), TbH - 2);
    6 : Begin If Not OptPanel Then DoCmd(CmPanel); SetPanelTab(LkSftp); End;
    7 : DoCmd(CmConfig);
    8 : DoCmd(CmAbout);
  Else
    DoCmd(CmExit);
  End;
End;

{ onglet sous le point (-2 : rien, -1 : accueil, MaxSess : +) ; Close }
Function TabAt(X, Y : LongInt; Var Close : Boolean) : LongInt;
Var K : LongInt;
Begin
  TabAt := -2; Close := False;
  If (Y < TabsY) Or (Y >= TabsY + TabH) Or (X < TermX0) Then Exit;
  If X < TermX0 + 32 Then Begin TabAt := -1; Exit; End;
  For K := 0 To TabN - 1 Do
    If (X >= TabX[K]) And (X < TabX[K + 1] - 1) Then
    Begin
      TabAt := TabOrder[K];
      Close := X >= TabX[K + 1] - 17;
      Exit;
    End;
  If (X >= TabX[TabN]) And (X < TabX[TabN] + 24) Then TabAt := MaxSess;
End;

{ ---- commandes ---- }

Procedure ListActivate(K, I : LongInt);
Var E : PEntry;
Begin
  Case K Of
    LkSess : If (I >= 0) And (I < TrN) And (TrKind[I] = 2) Then OpenSession(Defs^[TrIdx[I]]);
    LkTools : RunTool(I);
    LkMacro : DoCmd(CmRunMacro);
    LkSftp :
    Begin
      E := SfEntry(I);
      If E = Nil Then DoCmd(CmFUp)
      Else If E^.Dir Or E^.Link Then SftpCmd(Active, FcCd, RJoin(Sess^[Active].FCwd, E^.Name), '')
      Else DoCmd(CmFGet);
    End;
  End;
End;

Procedure ListMenu(K, I, X, Y : LongInt);
Var M : LongInt;
Begin
  M := MkPopup;
  Case K Of
    LkSess :
    Begin
      If (I >= 0) And (I < TrN) And (TrKind[I] = 2) Then
      Begin
        MItem(M, CmConnSess, '~Connexion');
        MItem(M, CmConnAs, 'Connexion ~en tant que...');
        MItem(M, 0, '');
        MItem(M, CmEditSess, '~Modifier la session...');
        MItem(M, CmRenSess, '~Renommer la session');
        MItem(M, CmDupSess, '~Dupliquer la session');
        MItem(M, CmDelSess, '~Supprimer la session');
        MItem(M, 0, '');
      End
      Else If (I >= 0) And (I < TrN) And (TrKind[I] = 1) Then
      Begin
        MItem(M, CmRenSess, '~Renommer le dossier');
        MItem(M, CmDelSess, '~Supprimer le dossier');
        MItem(M, 0, '');
      End;
      MItem(M, CmNewSess, '~Nouvelle session...');
      MItem(M, CmNewFolder, 'Nouveau ~dossier...');
    End;
    LkTools : If I >= 0 Then MItem(M, CmTool0 + I, '~Ex'#233'cuter');
    LkMacro :
    Begin
      If I >= 0 Then
      Begin
        MItem(M, CmRunMacro, '~Ex'#233'cuter');
        MItem(M, CmEditMacro, '~Modifier...');
        MItem(M, CmDelMacro, '~Supprimer');
        MItem(M, 0, '');
      End;
      MItem(M, CmNewMacro, '~Nouvelle macro...');
      If RecOn Then MItem(M, CmStopMacro, '~Arr'#234'ter l''enregistrement')
      Else MItem(M, CmRecMacro, 'En~registrer une macro');
    End;
    LkSftp :
    Begin
      If (I >= 0) And (SfEntry(I) <> Nil) Then
      Begin
        If SfEntry(I)^.Dir Then MItem(M, CmFOpen, '~Ouvrir')
        Else MItem(M, CmFGet, '~T'#233'l'#233'charger...');
        MItem(M, CmFRen, '~Renommer');
        MItem(M, CmFDel, '~Supprimer');
        MItem(M, 0, '');
      End;
      MItem(M, CmFPut, '~Envoyer un fichier...');
      MItem(M, CmFMkdir, '~Cr'#233'er un dossier...');
      MItem(M, CmFRefresh, 'Ac~tualiser');
    End;
  End;
  TrackMenu(M, X, Y);
End;

Procedure SessSaved;
Begin
  If Not SaveDefs Then
    Ask('Impossible d''enregistrer ' + AppDir + 'sessions.xml.', 'Sessions', MB_OK Or MB_ICONERROR);
  TreeBuild;
  LRepaint(LkSess);
  RefreshMenus;
  If Active < 0 Then Dummy := Inval(TermWnd, 0);
End;

Procedure QuickConnect;
Var D : TSessDef; S : String; I : LongInt;
Begin
  S := TrimS(CtlText(QcEdit));
  If S = '' Then
  Begin
    Ask('Tapez utilisateur@serveur (ou serveur:port) puis Entr'#233'e.', 'Connexion rapide',
        MB_OK Or MB_ICONINFO);
    Exit;
  End;
  DefClear(D);
  If LoS(Copy(S, 1, 6)) = 'ssh://' Then Delete(S, 1, 6);
  I := Pos('@', S);
  If I > 0 Then Begin D.User := Copy(S, 1, I - 1); S := Copy(S, I + 1, 255); End;
  I := Pos(':', S);
  If I > 0 Then Begin D.Port := SVal(Copy(S, I + 1, 6)); S := Copy(S, 1, I - 1); End;
  If D.Port <= 0 Then D.Port := 22;
  D.Host := S;
  D.Name := S;
  If D.User <> '' Then D.Name := D.User + '@' + S;
  OpenSession(D);
End;

Procedure DoCmd(Cmd : LongInt);
Var D : TSessDef; I, K : LongInt; S, Nm, Keys : String; E : PEntry;
Begin
  Case Cmd Of
    CmQuick :
      If (FocusWnd = PathEdit) And (Active >= 0) Then
        SftpCmd(Active, FcCd, TrimS(CtlText(PathEdit)), '')
      Else QuickConnect;
    CmNewSess :
    Begin
      DefClear(D);
      D.Folder := TreeFolder;
      D.User := OptLastUser;
      If EditSession('Nouvelle session SSH', D) Then
      Begin
        If DefN < MaxDef Then
        Begin
          AddFolder(D.Folder);
          Defs^[DefN] := D; Inc(DefN);
          SessSaved;
        End;
        OpenSession(D);
      End;
    End;
    CmNewFolder :
    Begin
      S := 'Nouveau dossier';
      If InputBox('Nouveau dossier', 'Nom du dossier de sessions :', S, False) Then
        If TrimS(S) <> '' Then
        Begin
          AddFolder(TrimS(S));
          SessSaved;
        End;
    End;
    CmConnSess, CmConnAs :
    Begin
      I := TreeDef;
      If I < 0 Then Exit;
      D := Defs^[I];
      If Cmd = CmConnAs Then Begin D.User := ''; D.Pass := ''; End;
      OpenSession(D);
    End;
    CmEditSess :
    Begin
      I := TreeDef;
      If I < 0 Then Exit;
      D := Defs^[I];
      If EditSession('Session : ' + D.Name, D) Then
      Begin
        AddFolder(D.Folder);
        Defs^[I] := D;
        SessSaved;
      End;
    End;
    CmDupSess :
    Begin
      I := TreeDef;
      If (I < 0) Or (DefN >= MaxDef) Then Exit;
      Defs^[DefN] := Defs^[I];
      Defs^[DefN].Name := Defs^[I].Name + ' (2)';
      Inc(DefN);
      SessSaved;
    End;
    CmRenSess :
    Begin
      K := Lst[LkSess].Cur;
      If (K < 0) Or (K >= TrN) Or (TrKind[K] = 0) Then Exit;
      If TrKind[K] = 2 Then S := Defs^[TrIdx[K]].Name Else S := Folders[TrIdx[K]];
      Nm := S;
      If InputBox('Renommer', 'Nouveau nom de "' + Nm + '" :', S, False) Then
        If TrimS(S) <> '' Then
        Begin
          If TrKind[K] = 2 Then Defs^[TrIdx[K]].Name := TrimS(S)
          Else
          Begin
            For I := 0 To DefN - 1 Do
              If UpS(Defs^[I].Folder) = UpS(Nm) Then Defs^[I].Folder := TrimS(S);
            Folders[TrIdx[K]] := TrimS(S);
          End;
          SessSaved;
        End;
    End;
    CmDelSess :
    Begin
      K := Lst[LkSess].Cur;
      If (K < 0) Or (K >= TrN) Or (TrKind[K] = 0) Then Exit;
      If TrKind[K] = 2 Then
      Begin
        If Ask('Supprimer la session "' + Defs^[TrIdx[K]].Name + '" ?', 'Sessions',
               MB_YESNO Or MB_ICONQUESTION) <> IDYES Then Exit;
        For I := TrIdx[K] To DefN - 2 Do Defs^[I] := Defs^[I + 1];
        Dec(DefN);
      End
      Else
      Begin
        Nm := Folders[TrIdx[K]];
        If Ask('Supprimer le dossier "' + Nm + '" et ses sessions ?', 'Sessions',
               MB_YESNO Or MB_ICONQUESTION) <> IDYES Then Exit;
        I := 0;
        While I < DefN Do
          If UpS(Defs^[I].Folder) = UpS(Nm) Then
          Begin
            For K := I To DefN - 2 Do Defs^[K] := Defs^[K + 1];
            Dec(DefN);
          End
          Else Inc(I);
        K := FolderIdx(Nm);
        If K >= 0 Then
        Begin
          For I := K To FolderN - 2 Do
          Begin
            Folders[I] := Folders[I + 1]; FolderOpen[I] := FolderOpen[I + 1];
          End;
          Dec(FolderN);
        End;
      End;
      SessSaved;
    End;
    CmImport :
    Begin
      S := 'C:\sessions.xml';
      If FileDlg(False, 'Importer des sessions', 'Sessions XML (*.xml)|*.xml|Tous les fichiers|*.*', S) Then
      Begin
        K := ImportDefs(S);
        SessSaved;
        Ask(IStr(K) + ' session(s) import'#233'e(s).', 'Importer', MB_OK Or MB_ICONINFO);
      End;
    End;
    CmExport :
    Begin
      S := 'C:\sessions-export.xml';
      If FileDlg(True, 'Exporter les sessions', 'Sessions XML (*.xml)|*.xml', S) Then
        If SaveDefsTo(S) Then Ask(IStr(DefN) + ' session(s) export'#233'e(s) dans ' + S + '.', 'Exporter', MB_OK Or MB_ICONINFO)
        Else Ask('Impossible d''enregistrer ' + S + '.', 'Exporter', MB_OK Or MB_ICONERROR);
    End;
    CmCopy : DoCopy;
    CmPaste : DoPaste;
    CmSelAll :
      If Active >= 0 Then
      Begin
        TmLoad(@Sess^[Active].Term);
        T.SelOn := True;
        T.SelA := (T.HistTotal - T.HistN) * 1000.0;
        T.SelB := (T.HistTotal + T.Rows - 1) * 1000.0 + T.Cols - 1;
        TmSave(@Sess^[Active].Term);
        Dummy := Inval(TermWnd, 0);
        If OptCopySel Then DoCopy;
      End;
    CmClearHist :
      If Active >= 0 Then
      Begin
        Sess^[Active].Term.HistN := 0; Sess^[Active].Term.ScrollOff := 0;
        Sess^[Active].Term.SelOn := False;
        TermSbSync;
        Dummy := Inval(TermWnd, 0);
      End;
    CmResetTerm :
      If Active >= 0 Then
      Begin
        TmLoad(@Sess^[Active].Term);
        TmFullReset;
        TmSave(@Sess^[Active].Term);
        Dummy := Inval(TermWnd, 0);
        SendInput(#12);
      End;
    CmSaveText : SaveTermText;
    CmReconnect : Reconnect(Active);
    CmCloseTab : CloseTab(Active);
    CmDupTab : If Active >= 0 Then OpenSession(Sess^[Active].Def);
    CmRenTab :
      If Active >= 0 Then
      Begin
        S := Sess^[Active].Title;
        If InputBox('Renommer l''onglet', 'Titre :', S, False) Then
        Begin
          Sess^[Active].Title := S;
          Dummy := Inval(MainWnd, 0);
        End;
      End;
    CmNextTab, CmPrevTab :
      If TabN > 0 Then
      Begin
        K := -1;
        For I := 0 To TabN - 1 Do If TabOrder[I] = Active Then K := I;
        If Cmd = CmNextTab Then K := K + 1 Else K := K - 1;
        If K >= TabN Then K := -1;
        If K < -1 Then K := TabN - 1;
        If K < 0 Then SetActive(-1) Else SetActive(TabOrder[K]);
      End;
    CmExit : Dummy := WinPostMsg(MainWnd, WM_CLOSE, 0, 0);
    CmPanel : Begin OptPanel := Not OptPanel; Layout; SaveOptions; End;
    CmPTab0..CmPTab0 + 3 :
    Begin
      If Not OptPanel Then Begin OptPanel := True; Layout; End;
      SetPanelTab(Cmd - CmPTab0);
    End;
    CmToolbar : Begin OptToolbar := Not OptToolbar; Layout; SaveOptions; End;
    CmStatus : Begin OptStatus := Not OptStatus; Layout; SaveOptions; End;
    CmConfig :
    Begin
      K := OptScheme;
      If ConfigBox Then
      Begin
        SaveOptions;
        If K <> OptScheme Then DoCmd(CmScheme0 + OptScheme);
        PanelLayout;
      End;
    End;
    CmScheme0..CmScheme0 + 3 :
    Begin
      OptScheme := Cmd - CmScheme0;
      SchemeColors(I, K);
      SaveOptions;
      For I := 0 To MaxSess - 1 Do
        If Sess^[I].Used Then
        Begin
          SchemeColors(Sess^[I].Term.DefFg, Sess^[I].Term.DefBg);
          Sess^[I].Term.Fg := Sess^[I].Term.DefFg; Sess^[I].Term.Bg := Sess^[I].Term.DefBg;
        End;
      Dummy := Inval(TermWnd, 0);
    End;
    CmCopySel : Begin OptCopySel := Not OptCopySel; SaveOptions; End;
    CmRPaste : Begin OptRightPaste := Not OptRightPaste; SaveOptions; End;
    CmMultiExec : Begin MultiExec := Not MultiExec; Dummy := Inval(MainWnd, 0); End;
    CmRecMacro :
    Begin
      RecOn := True; RecKeys := '';
      Dummy := Inval(PanelWnd, 0); Dummy := Inval(MainWnd, 0);
      Dummy := FocusTo(TermWnd);
    End;
    CmStopMacro :
    Begin
      RecOn := False;
      Dummy := Inval(PanelWnd, 0); Dummy := Inval(MainWnd, 0);
      If RecKeys = '' Then Exit;
      Nm := 'Macro ' + IStr(MacroN + 1); Keys := RecKeys;
      If MacroBox('Nouvelle macro', Nm, Keys) And (MacroN < MaxMacro) Then
      Begin
        Macros[MacroN].Name := Nm; Macros[MacroN].Keys := Keys; Inc(MacroN);
        SaveMacros;
        LRepaint(LkMacro);
      End;
    End;
    CmNewMacro :
    Begin
      Nm := ''; Keys := '';
      If MacroBox('Nouvelle macro', Nm, Keys) And (MacroN < MaxMacro) Then
      Begin
        Macros[MacroN].Name := Nm; Macros[MacroN].Keys := Keys; Inc(MacroN);
        SaveMacros;
        LRepaint(LkMacro);
      End;
    End;
    CmEditMacro :
    Begin
      I := Lst[LkMacro].Cur;
      If (I < 0) Or (I >= MacroN) Then Exit;
      Nm := Macros[I].Name; Keys := Macros[I].Keys;
      If MacroBox('Modifier la macro', Nm, Keys) Then
      Begin
        Macros[I].Name := Nm; Macros[I].Keys := Keys;
        SaveMacros;
        LRepaint(LkMacro);
      End;
    End;
    CmDelMacro :
    Begin
      I := Lst[LkMacro].Cur;
      If (I < 0) Or (I >= MacroN) Then Exit;
      If Ask('Supprimer la macro "' + Macros[I].Name + '" ?', 'Macros',
             MB_YESNO Or MB_ICONQUESTION) <> IDYES Then Exit;
      For K := I To MacroN - 2 Do Macros[K] := Macros[K + 1];
      Dec(MacroN);
      SaveMacros;
      LRepaint(LkMacro);
    End;
    CmRunMacro :
    Begin
      I := Lst[LkMacro].Cur;
      If (I >= 0) And (I < MacroN) Then DoCmd(CmMacro0 + I);
    End;
    CmHelp :
      Ask2('Ouvrez une session avec la connexion rapide (utilisateur@serveur:port), le bouton Session ou '+
          'l''onglet Sessions (double clic). Chaque session a son onglet. La s'#233'lection '+
          #224' la souris copie le texte ; ', 'Maj+Inser ou le clic du milieu colle. L''onglet SFTP '+
          'parcourt les fichiers de la session active. Les sessions sont gard'#233'es dans ' + AppDir +
          'sessions.xml.', 'Aide', MB_OK Or MB_ICONINFO);
    CmKeys :
      Ask2('Maj+Page pr'#233'c. / Page suiv. : historique|Ctrl+Inser : copier|Maj+Inser : coller|'+
          'Double clic : s'#233'lectionner un mot|', 'Clic droit : menu (ou coller)|'+
          'Entr'#233'e (session termin'#233'e) : fermer l''onglet|R (session termin'#233'e) : relancer',
          'Raccourcis clavier', MB_OK Or MB_ICONINFO);
    CmAbout :
      Ask2('Client SSH pour OS/2-0 - version 1.0|SSH-2 (curve25519, Ed25519, RSA, AES-CTR, '+
          'HMAC-SHA2), terminal xterm, SFTP|', #169' 2026 Sylvain Maltais|Port'#233' du Client SSH de Pasdows 95, '+
          'compil'#233' par OS2PC (Presentation Manager).', 'A propos du Client SSH', MB_OK Or MB_ICONINFO);
    CmFUp :
      If (Active >= 0) And (Sess^[Active].FCwd <> '') Then
        SftpCmd(Active, FcCd, RParent(Sess^[Active].FCwd), '');
    CmFHome : SftpCmd(Active, FcCd, '~', '');
    CmFRefresh :
      If Active >= 0 Then
      Begin
        If Not Sess^[Active].FThreadOn Then StartSftp(Active)
        Else SftpCmd(Active, FcCd, Sess^[Active].FCwd, '');
      End;
    CmFOpen : ListActivate(LkSftp, Lst[LkSftp].Cur);
    CmFGet :
    Begin
      E := SfEntry(Lst[LkSftp].Cur);
      If (E = Nil) Or (Active < 0) Then Exit;
      If E^.Dir Then
      Begin
        Ask('Choisissez un fichier (les dossiers ne se t'#233'l'#233'chargent pas).', 'SFTP', MB_OK Or MB_ICONINFO);
        Exit;
      End;
      S := LJoin(OptDlDir, E^.Name);
      If FileDlg(True, 'T'#233'l'#233'charger ' + E^.Name, 'Tous les fichiers|*.*', S) Then
        SftpCmd(Active, FcGet, RJoin(Sess^[Active].FCwd, E^.Name), S);
    End;
    CmFPut :
    Begin
      If (Active < 0) Or Not Sess^[Active].FThreadOn Then Exit;
      S := LJoin(OptDlDir, '*.*');
      If FileDlg(False, 'Envoyer un fichier', 'Tous les fichiers|*.*', S) Then
        SftpCmd(Active, FcPut, S, RJoin(Sess^[Active].FCwd, BaseOf(S)));
    End;
    CmFMkdir :
    Begin
      If (Active < 0) Or Not Sess^[Active].FThreadOn Then Exit;
      S := 'nouveau_dossier';
      If InputBox('Cr'#233'er un dossier', 'Nom du dossier :', S, False) Then
        If TrimS(S) <> '' Then SftpCmd(Active, FcMkdir, RJoin(Sess^[Active].FCwd, TrimS(S)), '');
    End;
    CmFDel :
    Begin
      E := SfEntry(Lst[LkSftp].Cur);
      If (E = Nil) Or (Active < 0) Then Exit;
      If Ask('Supprimer "' + E^.Name + '" du serveur ?', 'SFTP', MB_YESNO Or MB_ICONQUESTION) <> IDYES Then Exit;
      If E^.Dir Then S := '1' Else S := '0';
      SftpCmd(Active, FcDelete, RJoin(Sess^[Active].FCwd, E^.Name), S);
    End;
    CmFRen :
    Begin
      E := SfEntry(Lst[LkSftp].Cur);
      If (E = Nil) Or (Active < 0) Then Exit;
      S := E^.Name; Nm := S;
      If InputBox('Renommer', 'Nouveau nom de "' + Nm + '" :', S, False) Then
        If (TrimS(S) <> '') And (S <> Nm) Then
          SftpCmd(Active, FcRename, RJoin(Sess^[Active].FCwd, Nm), RJoin(Sess^[Active].FCwd, TrimS(S)));
    End;
  Else
    If (Cmd >= CmTool0) And (Cmd <= CmTool0 + ToolN) Then RunTool(Cmd - CmTool0)
    Else If (Cmd >= CmMacro0) And (Cmd < CmMacro0 + MacroN) Then
    Begin
      If Active < 0 Then Exit;
      SendInput(Macros[Cmd - CmMacro0].Keys);
      Dummy := FocusTo(TermWnd);
    End
    Else If (Cmd >= CmSess0) And (Cmd < CmSess0 + DefN) Then OpenSession(Defs^[Cmd - CmSess0]);
  End;
  RefreshMenus;
End;

{ ---- procedure de la fenetre ---- }

Function MainProc0(H, Msg, WP, LP : LongInt) : LongInt;
Var X, Y, I, Code : LongInt; Cl : Boolean;
Begin
  MainProc0 := 0;
  Case Msg Of
    EvSize :
    Begin
      CW0 := LP And $FFFF; CH0 := (LP Shr 16) And $FFFF;
      If PanelW > CW0 - 200 Then PanelW := MaxI(140, CW0 - 200);
      Layout;
    End;
    EvPaint : MainPaint(H);
    EvErase : MainProc0 := 1;
    EvSetFocus : Dummy := FocusTo(TermWnd);
    EvCommand : DoCmd(WP And $FFFF);
    EvLDown, EvLDbl :
    Begin
      X := S16(LP); Y := S16(LP Shr 16);
      I := TbAt(X, Y);
      If I >= 0 Then
      Begin
        TbDown := I;
        Dummy := Capture(H);
        Dummy := Inval(H, 0);
        Exit;
      End;
      If OptPanel And (X >= PanelW) And (X < PanelW + SplitW) And (Y > TabsY) Then
      Begin
        Splitting := True;
        Dummy := Capture(H);
        Exit;
      End;
      I := TabAt(X, Y, Cl);
      If I = MaxSess Then DoCmd(CmNewSess)
      Else If I = -1 Then SetActive(-1)
      Else If I >= 0 Then
      Begin
        If Cl Then CloseTab(I) Else SetActive(I);
      End;
    End;
    EvRDown :
    Begin
      I := TabAt(S16(LP), S16(LP Shr 16), Cl);
      If (I >= 0) And (I < MaxSess) Then
      Begin
        SetActive(I);
        Code := MkPopup;
        MItem(Code, CmReconnect, '~Reconnecter');
        MItem(Code, CmDupTab, '~Dupliquer l''onglet');
        MItem(Code, CmRenTab, 'Re~nommer l''onglet...');
        MItem(Code, 0, '');
        MItem(Code, CmCloseTab, '~Fermer l''onglet');
        PopupAt(Code, S16(LP), S16(LP Shr 16));
      End;
    End;
    EvLUp :
    Begin
      If Splitting Then
      Begin
        Splitting := False;
        Dummy := Capture(0);
        Layout;
        PanelLayout;
      End;
      If TbDown >= 0 Then
      Begin
        Dummy := Capture(0);
        I := TbAt(S16(LP), S16(LP Shr 16));
        Code := TbDown;
        TbDown := -1;
        Dummy := Inval(H, 0);
        If I = Code Then TbClick(I);
      End;
    End;
    EvMove :
    Begin
      X := S16(LP);
      If Splitting Then
      Begin
        PanelW := MinI(MaxI(X, 140), CW0 - 160);
        Exit;
      End;
      I := TbAt(X, S16(LP Shr 16));
      If I <> TbHot Then
      Begin
        TbHot := I;
        If I >= 0 Then SetTip(TbTip(I)) Else SetTip('');
        Dummy := Inval(H, 0);
      End;
    End;
    EvTimer :
    Begin
      Blink := Not Blink;
      If (Active >= 0) And (FocusWnd = TermWnd) Then
        TermInval(Sess^[Active].Term.CY, Sess^[Active].Term.CY);
    End;
    EvTermData : TermData(WP);
    EvSessState :
    Begin
      I := WP;
      If Sess^[I].Used And (Sess^[I].State = StOpen) Then
      Begin
        If OptAutoSftp Or (PanelTab = LkSftp) Then StartSftp(I);
        If OptSftpSwitch And (I = Active) And OptPanel Then SetPanelTab(LkSftp);
      End;
      Dummy := Inval(H, 0);
    End;
    EvSftpList :
      If WP = Active Then
      Begin
        SftpSort;
        Lst[LkSftp].Top := 0; Lst[LkSftp].Cur := 0;
        SetText(PathEdit, Sess^[Active].FCwd);
        LRepaint(LkSftp);
        Dummy := Inval(PanelWnd, 0);
      End;
    EvSftpState :
      If WP = Active Then
      Begin
        If LP = 0 Then
        Begin
          SftpSort;
          LRepaint(LkSftp);
        End;
        Dummy := Inval(PanelWnd, 0);
      End;
    EvClose :
    Begin
      Code := 0;
      For I := 0 To MaxSess - 1 Do
        If Sess^[I].Used And (Sess^[I].State = StOpen) Then Inc(Code);
      If Code > 0 Then
        If Ask(IStr(Code) + ' session(s) ouverte(s). Voulez-vous vraiment quitter ?', 'Client SSH',
               MB_YESNO Or MB_ICONQUESTION) <> IDYES Then Exit;
      SaveOptions;
      Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
    End;
    EvHostAsk :
    Begin
      { question d'une tache reseau (cle d'hote) }
      HaRes := Ask2(HaS1, HaS2, 'Cl'#233' d''h'#244'te', MB_YESNOCANCEL Or MB_ICONWARNING);
      HaPending := False;
    End;
    EvMenus :
    Begin
      MenuPending := False;
      MenuBarSet(MainMenu);
    End;
  Else
    MainProc0 := NoProc;
  End;
End;


{ ==================================================================== }
{ Procedures de fenetre de PM : les messages de PM sont traduits en     }
{ evenements des procedures de l'interface (MainProc0, PanelProc0,      }
{ LProc0, TermProc0, DlgProc0), appelees sous le verrou                 }
{ ==================================================================== }

Const
  KdMain = 1; KdPanel = 2; KdList = 3; KdTerm = 4; KdDlg = 5;

{ touche virtuelle de PM -> numero de l'interface (0 : aucune) }
Function UiVk(Vk : LongInt) : LongInt;
Begin
  Case Vk Of
    PVK_BACKSPACE : UiVk := VK_BACK;
    PVK_TAB, PVK_BACKTAB : UiVk := VK_TAB;
    PVK_NEWLINE, PVK_ENTER : UiVk := VK_RETURN;
    PVK_ESC : UiVk := VK_ESCAPE;
    PVK_PAGEUP : UiVk := VK_PRIOR;
    PVK_PAGEDOWN : UiVk := VK_NEXT;
    PVK_END : UiVk := VK_END;
    PVK_HOME : UiVk := VK_HOME;
    PVK_LEFT : UiVk := VK_LEFT;
    PVK_UP : UiVk := VK_UP;
    PVK_RIGHT : UiVk := VK_RIGHT;
    PVK_DOWN : UiVk := VK_DOWN;
    PVK_INSERT : UiVk := VK_INSERT;
    PVK_DELETE : UiVk := VK_DELETE;
    PVK_F1..PVK_F12 : UiVk := VK_F1 + Vk - PVK_F1;
  Else
    UiVk := 0;
  End;
End;

Function CallUi(Kind, H, E, WP, LP : LongInt) : LongInt;
Var R : LongInt;
Begin
  BigLock;
  Case Kind Of
    KdMain : R := MainProc0(H, E, WP, LP);
    KdPanel : R := PanelProc0(H, E, WP, LP);
    KdList : R := LProc0(H, E, WP, LP);
    KdTerm : R := TermProc0(H, E, WP, LP);
  Else
    R := DlgProc0(H, E, WP, LP);
  End;
  BigUnlock;
  CallUi := R;
End;

{ position de la souris : PM (origine en bas) -> interface (en haut) }
Function MousePos(H, Mp1 : LongInt) : LongInt;
Var X, Y : LongInt;
Begin
  X := S16(Mp1); Y := WinH(H) - 1 - S16(Mp1 Shr 16);
  MousePos := (X And $FFFF) Or ((Y And $FFFF) Shl 16);
End;

Function PmChar(Kind, H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Ch, Vk, V, C : LongInt;
Begin
  PmChar := 1;
  Fl := Mp1 And $FFFF; Ch := Mp2 And $FFFF; Vk := (Mp2 Shr 16) And $FFFF;
  If (Fl And KC_KEYUP) <> 0 Then Exit;
  If (Fl And KC_VIRTUALKEY) = 0 Then Vk := 0;
  { Alt : mnemoniques de la barre de menus }
  If (Fl And KC_ALT) <> 0 Then
  Begin
    PmChar := WinDefWindowProc(H, Msg, Mp1, Mp2);
    Exit;
  End;
  If Kind = KdDlg Then
  Begin
    { Tab, Entree (bouton par defaut), Echap : WinDefDlgProc }
    If (Vk = PVK_TAB) Or (Vk = PVK_BACKTAB) Or (Vk = PVK_NEWLINE) Or (Vk = PVK_ENTER) Or (Vk = PVK_ESC) Or
       (((Vk = PVK_UP) Or (Vk = PVK_DOWN) Or (Vk = PVK_LEFT) Or (Vk = PVK_RIGHT)) And (FocusWnd <> H)) Then
      PmChar := WinDefDlgProc(H, Msg, Mp1, Mp2);
    Exit;
  End;
  If (Kind = KdPanel) And ((Vk = PVK_NEWLINE) Or (Vk = PVK_ENTER)) Then
  Begin
    { Entree dans la connexion rapide ou le chemin SFTP }
    Dummy := CallUi(KdPanel, H, EvCommand, CmQuick, 0);
    Exit;
  End;
  V := UiVk(Vk);
  C := -1;
  If ((Fl And KC_CHAR) <> 0) And (Ch <> 0) Then C := Ch And 255;
  If ((Fl And KC_CTRL) <> 0) And (Ch >= 64) And (Ch < 128) Then C := Ch And 31;
  If C < 0 Then
    Case V Of
      VK_BACK : C := 8;
      VK_TAB : C := 9;
      VK_RETURN : C := 13;
      VK_ESCAPE : C := 27;
    End;
  If (V = 0) And (C < 0) Then
  Begin
    PmChar := WinDefWindowProc(H, Msg, Mp1, Mp2);
    Exit;
  End;
  KeyFl := Fl;
  If V <> 0 Then Dummy := CallUi(Kind, H, EvKeyDown, V, 0);
  If C > 0 Then Dummy := CallUi(Kind, H, EvChar, C, 0);
  KeyFl := 0;
End;

Function PmProc(Kind, H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var R, E, Cmd : LongInt;
Begin
  PmProc := 0;
  Case Msg Of
    WM_PAINT :
      If CallUi(Kind, H, EvPaint, 0, 0) = NoProc Then PmProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_ERASEBACKGROUND : PmProc := 0;
    WM_SIZE : Dummy := CallUi(Kind, H, EvSize, 0, Mp2);
    WM_SETFOCUS :
      If (Mp2 And $FFFF) <> 0 Then Dummy := CallUi(Kind, H, EvSetFocus, Mp1, 0)
      Else Dummy := CallUi(Kind, H, EvKillFocus, Mp1, 0);
    WM_TIMER : Dummy := CallUi(Kind, H, EvTimer, Mp1 And $FFFF, 0);
    WM_COMMAND : Dummy := CallUi(Kind, H, EvCommand, Mp1 And $FFFF, 0);
    WM_CONTROL :
      If (Kind = KdDlg) And (DlgKind = DkFile) And ((Mp1 And $FFFF) = IdFList) Then
      Begin
        BigLock;
        FdControl((Mp1 Shr 16) And $FFFF);
        BigUnlock;
      End;
    WM_CLOSE : Dummy := CallUi(Kind, H, EvClose, 0, 0);
    WM_VSCROLL :
    Begin
      Cmd := (Mp2 Shr 16) And $FFFF;
      E := -1;
      Case Cmd Of
        1, 2, 3, 4 : E := Cmd - 1;
        5 : E := 5;
        6 : E := 4;
      End;
      If E >= 0 Then Dummy := CallUi(Kind, H, EvVScroll, E Or ((Mp2 And $FFFF) Shl 16), Mp1);
    End;
    WM_MOUSEMOVE :
    Begin
      If (Kind <> KdMain) And (TbHot >= 0) Then
      Begin
        { la souris a quitte la barre d'outils : bulle effacee }
        BigLock;
        TbHot := -1;
        SetTip('');
        Dummy := Inval(MainWnd, 0);
        BigUnlock;
      End;
      Dummy := CallUi(Kind, H, EvMove, 0, MousePos(H, Mp1));
      PmProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK, WM_BUTTON2DOWN, WM_BUTTON3DOWN :
    Begin
      { activation du cadre d'abord (PM), puis l'interface }
      Dummy := WinDefWindowProc(H, Msg, Mp1, Mp2);
      Case Msg Of
        WM_BUTTON1DOWN : E := EvLDown;
        WM_BUTTON1DBLCLK : E := EvLDbl;
        WM_BUTTON2DOWN : E := EvRDown;
      Else
        E := EvMDown;
      End;
      Dummy := CallUi(Kind, H, E, 0, MousePos(H, Mp1));
      PmProc := 1;
    End;
    WM_BUTTON1UP :
    Begin
      Dummy := CallUi(Kind, H, EvLUp, 0, MousePos(H, Mp1));
      PmProc := 1;
    End;
    WM_CHAR : PmProc := PmChar(Kind, H, Msg, Mp1, Mp2);
  Else
    If (Msg > WM_USER) And (Msg < WM_USER + 100) Then
    Begin
      R := CallUi(Kind, H, Msg, Mp1, Mp2);
      If R <> NoProc Then PmProc := R;
    End
    Else PmProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Function MainPm(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  MainPm := PmProc(KdMain, H, Msg, Mp1, Mp2);
End;

Function PanelPm(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  PanelPm := PmProc(KdPanel, H, Msg, Mp1, Mp2);
End;

Function ListPm(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  ListPm := PmProc(KdList, H, Msg, Mp1, Mp2);
End;

Function TermPm(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  TermPm := PmProc(KdTerm, H, Msg, Mp1, Mp2);
End;

Function DlgPm(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  DlgPm := PmProc(KdDlg, H, Msg, Mp1, Mp2);
End;

{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

Var
  Sw, Shh, K, Fl, Fw, Fh : LongInt;

Function NewChild(P : LongInt; Cls : String; Style, Id : LongInt) : LongInt;
Begin
  PutZ(LongInt(@NameZ2), Cls);
  NewChild := WinCreateWindow(P, LongInt(@NameZ2), 0, Style, 0, 0, 100, 100, P, HWND_TOP, Id, 0, 0);
End;

BEGIN
  OemOut := 1;                            { police de l'ecran : page 437 }
  Fnt := 1; TermFnt := 2;
  TlsIdx := 1;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  FindAppDir;
  Dummy := DosCreateMutexSem(0, LongInt(@LockSem), 0, 0);
  LockOn := True;
  PalInit;
  Sess := PSessArr(TlNew(SizeOf(TSessArr)));
  Defs := PDefArr(TlNew(SizeOf(TDefArr)));
  Active := -1; TbHot := -1; TbDown := -1; MiniHot := -1;
  TermCols := 80; TermRows := 24;
  { CS_SIZEREDRAW (4) : tout redessiner quand la taille change }
  Dummy := WinRegisterClass(Hab, Z('SSHMAIN'), LongInt(@MainPm), 4, 0);
  Dummy := WinRegisterClass(Hab, Z('SSHPANEL'), LongInt(@PanelPm), 4, 0);
  Dummy := WinRegisterClass(Hab, Z('SSHLIST'), LongInt(@ListPm), 4, 0);
  Dummy := WinRegisterClass(Hab, Z('SSHTERM'), LongInt(@TermPm), 4, 0);
  Dummy := WinRegisterClass(Hab, Z('SSHDLG'), LongInt(@DlgPm), 0, 0);
  BigLock;
  LoadOptions;
  LoadDefs;
  LoadMacros;
  TreeBuild;
  PanelTab := OptPanelTab;
  If (PanelTab < 0) Or (PanelTab > 3) Then PanelTab := 0;
  BigUnlock;
  Sw := WinQuerySysValue(HWND_DESKTOP, SV_CXSCREEN); Shh := WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN);
  PanelW := 214;
  If Sw <= 640 Then PanelW := 196;
  { cadre standard : titre, menu systeme, bordure de taille, reduction,
    agrandissement, liste des taches ; barre de menus par WinCreateMenu }
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  MainWnd := 0;
  PutZ(LongInt(@NameZ2), 'SSHMAIN');
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), LongInt(@NameZ2), Z('Client SSH'), WS_CLIPCHILDREN,
                              0, 0, LongInt(@MainWnd));
  BigLock;
  PanelWnd := NewChild(MainWnd, 'SSHPANEL', WS_VISIBLE Or WS_CLIPCHILDREN, 20);
  QcEdit := MkCtl(PanelWnd, WC_ENTRYFIELD, '', ES_AUTOSCROLL Or ES_MARGIN Or WS_TABSTOP, 4, 18, 150, 20, 21);
  Dummy := WinSendMsg(QcEdit, EM_SETTEXTLIMIT, 250, 0);
  QcBtn := MkCtl(PanelWnd, WC_BUTTON, '>', BS_PUSHBUTTON, 160, 17, 24, 22, CmQuick);
  PathEdit := MkCtl(PanelWnd, WC_ENTRYFIELD, '', ES_AUTOSCROLL Or ES_MARGIN Or WS_TABSTOP, 4, 100, 150, 20, 22);
  Dummy := WinSendMsg(PathEdit, EM_SETTEXTLIMIT, 250, 0);
  For K := 0 To 3 Do
  Begin
    Lst[K].H := NewChild(PanelWnd, 'SSHLIST', WS_TABSTOP Or WS_CLIPCHILDREN, 30 + K);
    Lst[K].Sb := WinCreateWindow(Lst[K].H, WC_SCROLLBAR, 0, WS_VISIBLE Or SBS_VERT, 0, 0, SbW, 100, Lst[K].H,
                                 HWND_TOP, 40 + K, 0, 0);
    Lst[K].Cur := -1;
  End;
  Lst[LkSess].Cur := 0;
  TermWnd := NewChild(MainWnd, 'SSHTERM', WS_VISIBLE Or WS_TABSTOP Or WS_CLIPCHILDREN, 23);
  TermSb := WinCreateWindow(TermWnd, WC_SCROLLBAR, 0, WS_VISIBLE Or SBS_VERT, 0, 0, SbW, 100, TermWnd, HWND_TOP,
                            24, 0, 0);
  BuildMenus;
  RefreshMenus;
  BigUnlock;
  Fw := MinI(Sw, 900); Fh := MinI(Shh - 20, 680);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, (Sw - Fw) Div 2, Shh - Fh, Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  BigLock;
  Layout;
  SetPanelTab(PanelTab);
  TermSbSync;
  BigUnlock;
  Dummy := WinStartTimer(Hab, MainWnd, 1, 500);
  Dummy := FocusTo(QcEdit);
  MsgLoop;
  AppQuit := True;
  Dummy := DosSleep(300);
  Dummy := WinDestroyWindow(Frame);
  Dummy := WinDestroyMsgQueue(Hmq);
  Dummy := WinTerminate(Hab);
  Dummy := DosExit(1, 0);
END.
