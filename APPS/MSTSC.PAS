{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: MSTSC - Connexion Bureau a distance (client RDP) d'OS/2-0
  (Presentation Manager), porte de la Connexion Bureau a distance de
  Pasdows 95 (APPS/MSTSC.PAS, Win32).
}

Program MSTSC;

{$R-,S-,I-}

{ Compilation : OS2PC APPS\MSTSC.PAS MSTSC.EXE

  Bureau, dossier Outils reseau, Connexion Bureau a distance.
  Client du protocole RDP (Remote Desktop Protocol) de Windows, pour
  ouvrir une session sur Windows Server 2008 a 2022 (et Windows 7 a 11,
  xrdp, FreeRDP).
  - Securite : TLS 1.2 (ECDHE x25519, AES-128-GCM, ecrit ici en Pascal)
    et l'authentification NLA de Windows Server 2019 (CredSSP version 6 :
    NTLMv2 avec signature et scellement RC4, cle publique du serveur liee
    par SHA-256 avec un nonce, TSCredentials). La securite RDP standard
    (RC4 de RDP 5) n'est pas proposee : Windows Server 2019 utilise TLS
    ou NLA par defaut.
  - Connexion : X.224 (negociation de la securite), MCS et GCC (donnees
    du client : 16 bits par point, taille choisie), Erect Domain, Attach
    User, Channel Join, Client Info (ouverture de session automatique),
    licence, Demand Active / Confirm Active (capacites : sans ordres de
    dessin, l'ecran arrive en bitmaps), Synchronize, Control, Font List.
  - Affichage : mises a jour par le chemin rapide (fast-path, fragments
    reassembles) ou classiques, bitmaps non compresses ou compresses en
    RLE entrelace (8, 15, 16 et 24 bits) et palette, copies dans une
    image de 24 bits par point (de bas en haut, comme les bitmaps d'OS/2)
    montree par GpiDrawBits.
  - Entrees : clavier par codes de balayage (WM_CHAR de PM : touche
    enfoncee puis relachee, Maj, Ctrl et Alt autour), souris (boutons 1
    a 3, deplacements), molette (WM_VSCROLL sans barre de defilement,
    envoye par PMWIN pour la molette de la souris), par le chemin rapide ;
    Ctrl+Alt+Fin envoie Ctrl+Alt+Suppr, Ctrl+Alt+Pause ou Ctrl+Alt+Entree
    bascule le plein ecran ; menu Session (Ctrl+Alt+Suppr, plein ecran,
    deconnexion).

  Portage vers l'API d'OS/2 (OS/2-0) :
  - boite de connexion : fenetre de PM (cadre a bordure de boite de
    dialogue, barre de menus, liste des taches) aux controles natifs
    (WC_STATIC, WC_ENTRYFIELD dont ES_UNREADABLE pour le mot de passe,
    WC_COMBOBOX en liste deroulante pour la taille de l'ecran, WC_BUTTON),
    gris d'OS/2 Warp 3 ; Tab et Maj+Tab d'un controle a l'autre, Entree :
    Connexion, Echap : Quitter ;
  - fenetre de la session : cadre standard (ou plein ecran sans cadre),
    barres de defilement WC_SCROLLBAR quand l'ecran distant est plus grand,
    dessin par GpiDrawBits (PMGPI, 24 bits), coordonnees de PM (origine
    en bas a gauche) ;
  - la reception tourne dans une tache (DosCreateThread) ; les envois sont
    proteges par un semaphore d'exclusion (DosCreateMutexSem,
    DosRequestMutexSem, DosReleaseMutexSem) ; la tache ne parle a
    l'interface que par WinPostMsg (zones a redessiner, etat, fin) ;
  - reseau : TCPIP32.DLL (sock_init, gethostbyname, socket, connect, send,
    recv, select : attente des donnees sans limite de temps, soclose) ;
  - le dernier ordinateur, le nom d'utilisateur de chaque serveur, le
    domaine et la taille de l'ecran sont gardes dans OS2.INI (application
    PM_RemoteDesktop) au lieu du registre de Windows ; le mot de passe
    n'est jamais enregistre ;
  - aleas : compteur de cycles (RDTSC), horloge (DosGetDateTime,
    QSV_MS_COUNT) et position de la souris. }

Const
  { messages de PM }
  WM_CREATE = $0001; WM_DESTROY = $0002; WM_SIZE = $0007; WM_SETFOCUS = $000F;
  WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029;
  WM_QUIT = $002A; WM_CONTROL = $0030; WM_VSCROLL = $0031; WM_HSCROLL = $0032;
  WM_ERASEBACKGROUND = $004F;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072;
  WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074; WM_BUTTON2UP = $0075;
  WM_BUTTON2DBLCLK = $0076; WM_BUTTON3DOWN = $0077; WM_BUTTON3UP = $0078;
  WM_BUTTON3DBLCLK = $0079; WM_CHAR = $007A; WM_USER = $1000;
  WM_RDPSTATUS = WM_USER + 1; WM_RDPACTIVE = WM_USER + 2; WM_RDPEND = WM_USER + 3;
  WM_RDPDIRTY = WM_USER + 4;
  { fenetres }
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MENU = 4; FCF_SIZEBORDER = 8;
  FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_HIDE = $10;
  SWP_ACTIVATE = $80;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000; WS_GROUP = $00010000;
  WC_COMBOBOX = $FFFF0002; WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005;
  WC_ENTRYFIELD = $FFFF0006; WC_SCROLLBAR = $FFFF0008;
  BS_PUSHBUTTON = 0; BS_DEFAULT = $0400;
  SS_TEXT = 1; SS_GROUPBOX = 2; DT_VCENTER = $0400; DT_WORDBREAK = $4000;
  ES_AUTOSCROLL = 4; ES_MARGIN = 8; ES_UNREADABLE = $80;
  CBS_DROPDOWNLIST = 4;
  SBS_HORZ = 0; SBS_VERT = 1;
  EM_SETSEL = $0142; EM_SETTEXTLIMIT = $0143;
  LM_INSERTITEM = $0161; LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165;
  SBM_SETSCROLLBAR = $01A0; SBM_SETPOS = $01A1; SBM_QUERYPOS = $01A2;
  SBM_SETTHUMBSIZE = $01A6;
  SB_LINEUP = 1; SB_LINEDOWN = 2; SB_PAGEUP = 3; SB_PAGEDOWN = 4;
  SB_SLIDERTRACK = 5; SB_SLIDERPOSITION = 6; SB_ENDSCROLL = 7;
  MIS_TEXT = 1; MIS_SUBMENU = $10; MIS_SEPARATOR = 4;
  SV_CXSCREEN = 20; SV_CYSCREEN = 21;
  { boites de message (valeurs de PM) }
  MB_OK = 0; MB_OKCANCEL = 1; MB_YESNO = 4;
  MB_ICONQUESTION = $10; MB_ICONWARNING = $20; MB_ICONINFO = $30;
  MB_ICONERROR = $40; MB_MOVEABLE = $4000;
  MBID_OK = 1;
  { clavier de PM }
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SCANCODE = 4; KC_SHIFT = 8; KC_CTRL = $10;
  KC_ALT = $20; KC_KEYUP = $40;
  PVK_BREAK = $04; PVK_BACKSPACE = $05; PVK_TAB = $06; PVK_BACKTAB = $07;
  PVK_NEWLINE = $08; PVK_SHIFT = $09; PVK_CTRL = $0A; PVK_ALT = $0B;
  PVK_PAUSE = $0D; PVK_CAPSLOCK = $0E; PVK_ESC = $0F; PVK_SPACE = $10;
  PVK_PAGEUP = $11; PVK_PAGEDOWN = $12; PVK_END = $13; PVK_HOME = $14;
  PVK_LEFT = $15; PVK_UP = $16; PVK_RIGHT = $17; PVK_DOWN = $18;
  PVK_PRINTSCRN = $19; PVK_INSERT = $1A; PVK_DELETE = $1B; PVK_SCRLLOCK = $1C;
  PVK_NUMLOCK = $1D; PVK_ENTER = $1E; PVK_F1 = $20; PVK_F12 = $2B;
  { couleurs (RVB) }
  ClrFace = $CCCCCC; ClrShadow = $808080; ClrHi = $FFFFFF; ClrDark = 0;
  ClrNavy = $000080;
  { commandes }
  ID_CONNECT = 1; ID_QUIT = 2; ID_ABOUT = 3; ID_HOST = 10; ID_USER = 11;
  ID_PASS = 12; ID_DOM = 13; ID_SIZE = 14; ID_STAT = 15;
  ID_CAD = 40; ID_FULL = 41; ID_DISC = 42;
  IniApp = 'PM_RemoteDesktop';

Type
  PByt = ^Byte;
  PLng = ^LongInt;
  TlPtr = LongInt;

{ ---- DOSCALLS ---- }
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosQuerySysInfo(A, B, P, N : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateMutexSem(PName, PH, Attr, State : LongInt) : LongInt; External 'DOSCALLS';
Function DosRequestMutexSem(H, Timeout : LongInt) : LongInt; External 'DOSCALLS';
Function DosReleaseMutexSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosExit(Act, Code : LongInt) : LongInt; External 'DOSCALLS';
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
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
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
Function WinQueryPointerPos(HD, P : LongInt) : LongInt; External 'PMWIN';
Function WinGetKeyState(HD, Vk : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindow(H, Cmd : LongInt) : LongInt; External 'PMWIN';
{ ---- PMGPI ---- }
Function GpiCreateLogColorTable(Hps, Opt, Fmt, St, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiCharStringAt(Hps, PPt, N, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetBackMix(Hps, M : LongInt) : LongInt; External 'PMGPI';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
{ ---- profils (OS2.INI) ---- }
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE';

Var
  Hab, Hmq, Dummy, OemOut : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  Qmsg : Array[0..7] Of LongInt;

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt; P : PByt;
Begin
  For K := 1 To Length(S) Do
  Begin
    P := PByt(A + K - 1); P^ := Ord(S[K]);
  End;
  P := PByt(A + Length(S)); P^ := 0;
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

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
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

Function Lo16(V : LongInt) : LongInt;
Begin
  Lo16 := V And $FFFF;
End;

Function Hi16(V : LongInt) : LongInt;
Begin
  Hi16 := (V Shr 16) And $FFFF;
End;

Function Mk2(A, B : LongInt) : LongInt;
Begin
  Mk2 := (A And $FFFF) Or ((B And $FFFF) Shl 16);
End;

Function UpS(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpS := S;
End;

Function TrimS(S : String) : String;
Begin
  While (S <> '') And (S[1] <= ' ') Do Delete(S, 1, 1);
  While (S <> '') And (S[Length(S)] <= ' ') Do Delete(S, Length(S), 1);
  TrimS := S;
End;

Function Two(V : LongInt) : String;
Begin
  Two := Chr(48 + (V Div 10) Mod 10) + Chr(48 + V Mod 10);
End;

{ ANSI (1252) -> page 850/437 de la police d'OS/2-0 : les textes du
  programme sont ecrits en ANSI (comme Pasdows) et les noms recus du
  serveur sont convertis de l'Unicode vers l'ANSI }
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

Function Disp(S : String) : String;
Var K : LongInt;
Begin
  If OemOut <> 0 Then
    For K := 1 To Length(S) Do
      If Ord(S[K]) >= 128 Then S[K] := Chr(AnsiOem[Ord(S[K])]);
  Disp := S;
End;

{ inverse (texte lu dans un controle -> ANSI) }
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

{ ==================================================================== }
{ Memoire, taches, reseau                                               }
{ ==================================================================== }

Function GB(A : LongInt) : LongInt;
Begin
  GB := PByt(A)^;
End;

Procedure SB(A, V : LongInt);
Begin
  PByt(A)^ := V And 255;
End;

{ mots et doubles mots petit-boutistes }
Function GW(A : LongInt) : LongInt;
Begin
  GW := PByt(A)^ Or (PByt(A + 1)^ Shl 8);
End;

Procedure SW(A, V : LongInt);
Begin
  PByt(A)^ := V And 255; PByt(A + 1)^ := (V Shr 8) And 255;
End;

Function GL(A : LongInt) : LongInt;
Begin
  GL := PLng(A)^;
End;

Procedure SL(A, V : LongInt);
Begin
  PLng(A)^ := V;
End;

{ mots gros-boutistes (TPKT, MCS) }
Function GWB(A : LongInt) : LongInt;
Begin
  GWB := (PByt(A)^ Shl 8) Or PByt(A + 1)^;
End;

Procedure SWB(A, V : LongInt);
Begin
  PByt(A)^ := (V Shr 8) And 255; PByt(A + 1)^ := V And 255;
End;

{ copie de N octets (vers le haut : les zones peuvent se recouvrir si la
  destination est avant la source) }
Procedure MoveB(Src, Dst, N : LongInt);
Begin
  If N <= 0 Then Exit;
  asm
    push esi
    push edi
    mov esi,Src
    mov edi,Dst
    mov ecx,N
    cld
    rep movsb
    pop edi
    pop esi
  end;
End;

Procedure ZeroB(A, N : LongInt);
Begin
  If N <= 0 Then Exit;
  asm
    push edi
    mov edi,A
    mov ecx,N
    xor eax,eax
    cld
    rep stosb
    pop edi
  end;
End;

{ memoire neuve (pages a zero) : PAG_COMMIT Or PAG_READ Or PAG_WRITE }
Function NewMem(N : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := 0;
  If DosAllocMem(LongInt(@P), N, $13) <> 0 Then P := 0;
  NewMem := P;
End;

Function MsCount : LongInt;
Var V : LongInt;
Begin
  V := 0;
  Dummy := DosQuerySysInfo(14, 14, LongInt(@V), 4);   { QSV_MS_COUNT }
  MsCount := V;
End;

{ ---- fonctions attendues par la couche TLS ---- }

Var
  TlCert : Array[0..8191] Of Byte;       { certificat du serveur (DER) }
  TlCertLen : LongInt;
  NetStop : Boolean;                      { deconnexion demandee }
  NetReady : Boolean;

Function TlGet(A : TlPtr) : LongInt;
Begin
  TlGet := PByt(A)^;
End;

Procedure TlPut(A : TlPtr; V : LongInt);
Begin
  PByt(A)^ := V And 255;
End;

Function TlNew(N : LongInt) : TlPtr;
Begin
  TlNew := NewMem(N);
End;

Procedure TlEntropy; Forward;

Function TlSockSend(S, A, N : LongInt) : LongInt;
Begin
  TlSockSend := send(S, A, N, 0);
End;

{ reception : attente par select (la session peut rester muette plus de
  60 s, limite d'un recv de TCPIP32) ; -1 si la deconnexion est demandee }
Function TlSockRecv(S, A, N : LongInt) : LongInt;
Var Fs : Array[0..0] Of LongInt; R : LongInt;
Begin
  TlSockRecv := -1;
  Repeat
    If NetStop Then Exit;
    Fs[0] := S;
    R := select(LongInt(@Fs[0]), 1, 0, 0, 500);
    If R < 0 Then Exit;
  Until R > 0;
  If NetStop Then Exit;
  TlSockRecv := recv(S, A, N, 0);
End;

Procedure TlSockClose(S : LongInt);
Begin
  Dummy := shutdown(S, 2);
  Dummy := soclose(S);
End;

Function TlIsIp(S : String) : Boolean;
Var K : LongInt;
Begin
  TlIsIp := False;
  For K := 1 To Length(S) Do
    If Not (S[K] In ['0'..'9', '.']) Then Exit;
  TlIsIp := S <> '';
End;

{ connexion TCP : socket ou -1 (Err : message) }
Function TcpOpen(Host : String; Port : LongInt; Var Err : String) : LongInt;
Var A : Array[0..15] Of Byte; S, IP, H : LongInt;
Begin
  TcpOpen := -1;
  If Not NetReady Then
  Begin
    If sock_init <> 0 Then
    Begin
      Err := 'R'#233'seau absent (TCP/IP n''est pas configur'#233').';
      Exit;
    End;
    NetReady := True;
  End;
  PutZ(LongInt(@NameZ2), Host);
  IP := inet_addr(LongInt(@NameZ2));
  If (IP = -1) Or (IP = 0) Then
  Begin
    H := gethostbyname(LongInt(@NameZ2));
    If H = 0 Then
    Begin
      Err := 'Ordinateur introuvable : ' + Host;
      Exit;
    End;
    { hostent d'OS/2 : h_addr_list en +16 }
    IP := GL(GL(GL(H + 16)));
  End;
  S := socket(2, 1, 0);
  If S = -1 Then
  Begin
    Err := 'Socket impossible';
    Exit;
  End;
  ZeroB(LongInt(@A[0]), 16);
  { sockaddr_in de TCP/IP 4 : sin_len, sin_family }
  A[0] := 16; A[1] := 2; A[2] := (Port Shr 8) And 255; A[3] := Port And 255;
  SL(LongInt(@A[4]), IP);
  If connect(S, LongInt(@A[0]), 16) <> 0 Then
  Begin
    Err := 'L''ordinateur distant ne r'#233'pond pas sur le port ' + IStr(Port) +
           ' (Bureau '#224' distance d'#233'sactiv'#233' ou pare-feu).';
    Dummy := soclose(S);
    Exit;
  End;
  TcpOpen := S;
End;
{ ==================================================================== }
{ Cryptographie de TLS 1.2 : SHA-256, HMAC, PRF, AES-128-GCM, X25519  }
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
    M : Array[0..63] Of LongInt;     { GHASH : 16 multiples de H }
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
  TlLast4 : Array[0..15] Of LongInt = ($0000, $1C20, $3840, $2460,
    $7080, $6CA0, $48C0, $54E0, $E100, $FD20, $D940, $C560, $9180,
    $8DA0, $A9C0, $B5E0);

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

{ ---- HMAC-SHA256 (cle de 64 octets au plus) et PRF de TLS 1.2 ---- }

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
  TlShaAdd(C, Msg, MLen);
  If M2Len > 0 Then TlShaAdd(C, Msg2, M2Len);
  TlShaDone(C, TlPtr(@In0[0]));
  For I := 0 To 63 Do Pad[I] := Pad[I] Xor ($36 Xor $5C);
  TlShaInit(C);
  TlShaAdd(C, TlPtr(@Pad[0]), 64);
  TlShaAdd(C, TlPtr(@In0[0]), 32);
  TlShaDone(C, Out0);
End;

{ PRF(secret, label + seed) sur N octets }
Procedure TlPrf(Sec : TlPtr; SLen : LongInt; Const Lbl : String;
  Seed : TlPtr; SdLen : LongInt; Out0 : TlPtr; N : LongInt);
Var LS : Array[0..127] Of Byte; A, T : Array[0..31] Of Byte;
    I, L, Done : LongInt;
Begin
  L := Length(Lbl);
  For I := 1 To L Do LS[I - 1] := Ord(Lbl[I]);
  For I := 0 To SdLen - 1 Do LS[L + I] := TlGet(Seed + I);
  L := L + SdLen;
  TlHmac(Sec, SLen, TlPtr(@LS[0]), L, TlPtr(@LS[0]), 0, TlPtr(@A[0]));
  Done := 0;
  While Done < N Do
  Begin
    TlHmac(Sec, SLen, TlPtr(@A[0]), 32, TlPtr(@LS[0]), L,
           TlPtr(@T[0]));
    I := 0;
    While (I < 32) And (Done < N) Do
    Begin
      TlPut(Out0 + Done, T[I]); Inc(I); Inc(Done);
    End;
    TlHmac(Sec, SLen, TlPtr(@A[0]), 32, TlPtr(@A[0]), 0, TlPtr(@A[0]));
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

{ cle de 16 octets ; prepare aussi les tables de GHASH (H = E(0)) }
Procedure TlAesKey(Var A : TlAes; Var Key : TlBlk);
Const Rc : Array[0..9] Of LongInt = ($01, $02, $04, $08, $10, $20,
  $40, $80, $1B, $36);
Var I, T, V0, V1, V2, V3, J, B : LongInt; Z : TlBlk;
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
  For I := 0 To 15 Do Z[I] := 0;
  TlAesEnc(A, Z, Z);
  V0 := TlGetW(Z, 0); V1 := TlGetW(Z, 4);
  V2 := TlGetW(Z, 8); V3 := TlGetW(Z, 12);
  For I := 0 To 3 Do A.M[I] := 0;
  A.M[32] := V0; A.M[33] := V1; A.M[34] := V2; A.M[35] := V3;
  I := 4;
  While I > 0 Do
  Begin
    B := V3 And 1;
    V3 := (V3 Shr 1) Or (V2 Shl 31);
    V2 := (V2 Shr 1) Or (V1 Shl 31);
    V1 := (V1 Shr 1) Or (V0 Shl 31);
    V0 := V0 Shr 1;
    If B <> 0 Then V0 := V0 Xor LongInt($E1000000);
    A.M[I * 4] := V0; A.M[I * 4 + 1] := V1;
    A.M[I * 4 + 2] := V2; A.M[I * 4 + 3] := V3;
    I := I Div 2;
  End;
  I := 2;
  While I <= 8 Do
  Begin
    For J := 1 To I - 1 Do
      For B := 0 To 3 Do
        A.M[(I + J) * 4 + B] := A.M[I * 4 + B] Xor A.M[J * 4 + B];
    I := I * 2;
  End;
End;

{ Y := Y * H dans GF(2^128) (tables de 4 bits, comme mbed TLS) }
Procedure TlGMul(Var A : TlAes; Var Y : TlBlk);
Var Z0, Z1, Z2, Z3, I, Lo, Hi, R : LongInt;
Begin
  Lo := Y[15] And 15;
  Z0 := A.M[Lo * 4]; Z1 := A.M[Lo * 4 + 1];
  Z2 := A.M[Lo * 4 + 2]; Z3 := A.M[Lo * 4 + 3];
  For I := 15 DownTo 0 Do
  Begin
    Lo := Y[I] And 15; Hi := (Y[I] Shr 4) And 15;
    If I <> 15 Then
    Begin
      R := Z3 And 15;
      Z3 := (Z3 Shr 4) Or (Z2 Shl 28); Z2 := (Z2 Shr 4) Or (Z1 Shl 28);
      Z1 := (Z1 Shr 4) Or (Z0 Shl 28);
      Z0 := (Z0 Shr 4) Xor (TlLast4[R] Shl 16);
      Z0 := Z0 Xor A.M[Lo * 4]; Z1 := Z1 Xor A.M[Lo * 4 + 1];
      Z2 := Z2 Xor A.M[Lo * 4 + 2]; Z3 := Z3 Xor A.M[Lo * 4 + 3];
    End;
    R := Z3 And 15;
    Z3 := (Z3 Shr 4) Or (Z2 Shl 28); Z2 := (Z2 Shr 4) Or (Z1 Shl 28);
    Z1 := (Z1 Shr 4) Or (Z0 Shl 28);
    Z0 := (Z0 Shr 4) Xor (TlLast4[R] Shl 16);
    Z0 := Z0 Xor A.M[Hi * 4]; Z1 := Z1 Xor A.M[Hi * 4 + 1];
    Z2 := Z2 Xor A.M[Hi * 4 + 2]; Z3 := Z3 Xor A.M[Hi * 4 + 3];
  End;
  TlPutW(Y, 0, Z0); TlPutW(Y, 4, Z1); TlPutW(Y, 8, Z2); TlPutW(Y, 12, Z3);
End;

{ AES-128-GCM sur N octets a l'adresse D (chiffre ou dechiffre sur
  place) ; Iv : 12 octets, Aad : NA octets ; Tag : 16 octets calcules
  (sur le texte chiffre) }
Procedure TlGcm(Var A : TlAes; Var Iv : TlBlk; Var Aad : TlBlk;
  NA : LongInt; D : TlPtr; N : LongInt; Enc : Boolean; Var Tag : TlBlk);
Var J0, Cb, Ks, Y : TlBlk; I, K, L, C : LongInt;
Begin
  For I := 0 To 11 Do J0[I] := Iv[I];
  J0[12] := 0; J0[13] := 0; J0[14] := 0; J0[15] := 1;
  Cb := J0;
  For I := 0 To 15 Do Y[I] := 0;
  For I := 0 To NA - 1 Do Y[I] := Aad[I];
  If NA > 0 Then TlGMul(A, Y);
  K := 0;
  While K < N Do
  Begin
    { compteur sur 32 bits }
    I := 15;
    Repeat
      C := (Cb[I] + 1) And 255; Cb[I] := C; Dec(I);
    Until (C <> 0) Or (I < 12);
    TlAesEnc(A, Cb, Ks);
    L := N - K; If L > 16 Then L := 16;
    For I := 0 To L - 1 Do
    Begin
      C := TlGet(D + K + I);
      If Enc Then
      Begin
        C := C Xor Ks[I]; TlPut(D + K + I, C);
      End
      Else TlPut(D + K + I, C Xor Ks[I]);
      Y[I] := Y[I] Xor C;
    End;
    TlGMul(A, Y);
    K := K + L;
  End;
  { longueurs en bits (64 bits chacune) }
  For I := 0 To 15 Do Ks[I] := 0;
  TlPutW(Ks, 4, NA * 8);
  TlPutW(Ks, 8, N Shr 29); TlPutW(Ks, 12, N Shl 3);
  For I := 0 To 15 Do Y[I] := Y[I] Xor Ks[I];
  TlGMul(A, Y);
  TlAesEnc(A, J0, Ks);
  For I := 0 To 15 Do Tag[I] := Y[I] Xor Ks[I];
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

{ ---- TLS 1.2 client : ECDHE (x25519) + AES-128-GCM + SHA-256 ---- }
{ Suites TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (C02F) et              }
{ TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 (C02B). Le certificat du    }
{ serveur n'est pas verifie (OS/2-0 n'a pas de magasin de            }
{ certificats racines) : la connexion est chiffree, pas authentifiee. }

Const
  TlMaxConn = 4;
  TlRecMax = 18500;                  { enregistrement chiffre + marge }
  TlHsMax = 65536;                   { messages de la poignee de main }

Type
  TlConn = Record
    Used, Tls, Enc, Dec, Eof : Boolean;
    Sock : LongInt;
    CAes, SAes : TlAes;
    CIv, SIv : TlBlk;
    CSeq, SSeq : LongInt;
    RB : Array[0..TlRecMax - 1] Of Byte;   { enregistrement recu }
    RPos, REnd : LongInt;                  { texte clair disponible }
    OB : Array[0..TlRecMax - 1] Of Byte;   { enregistrement a envoyer }
  End;

  PTlConn = ^TlConn;
  TlHsBuf = Array[0..TlHsMax - 1] Of Byte;
  PTlHsBuf = ^TlHsBuf;

Var
  TlC : Array[0..TlMaxConn - 1] Of PTlConn;  { alloues au premier usage }
  TlHs : PTlHsBuf;
  TlHsLen : LongInt;
  TlErr : String;
  TlPool : TlSha;
  TlPoolN : LongInt;

{ ---- aleas : SHA-256 d'un compteur et des evenements du systeme ---- }

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

{ ---- envoi et reception d'enregistrements ---- }

Function TlSendAll(Var C : TlConn; A : TlPtr; N : LongInt) : Boolean;
Var R : LongInt;
Begin
  TlSendAll := False;
  While N > 0 Do
  Begin
    R := TlSockSend(C.Sock, A, N);
    If R <= 0 Then Begin TlErr := 'envoi TCP impossible'; Exit; End;
    A := A + R; N := N - R;
  End;
  TlSendAll := True;
End;

Function TlRecvAll(Var C : TlConn; A : TlPtr; N : LongInt) : Boolean;
Var R : LongInt;
Begin
  TlRecvAll := False;
  While N > 0 Do
  Begin
    R := TlSockRecv(C.Sock, A, N);
    If R <= 0 Then Begin TlErr := 'connexion fermee'; Exit; End;
    A := A + R; N := N - R;
  End;
  TlRecvAll := True;
End;

Procedure TlSeqBytes(Seq : LongInt; Var B : TlBlk; Ofs : LongInt);
Begin
  B[Ofs] := 0; B[Ofs + 1] := 0; B[Ofs + 2] := 0; B[Ofs + 3] := 0;
  B[Ofs + 4] := (Seq Shr 24) And 255; B[Ofs + 5] := (Seq Shr 16) And 255;
  B[Ofs + 6] := (Seq Shr 8) And 255; B[Ofs + 7] := Seq And 255;
End;

{ envoie un enregistrement de type Typ (N octets a l'adresse A) }
Function TlSendRec(Var C : TlConn; Typ : LongInt; A : TlPtr;
  N : LongInt) : Boolean;
Var Iv, Aad, Tag : TlBlk; I, L : LongInt; P : TlPtr;
Begin
  P := TlPtr(@C.OB[0]);
  C.OB[0] := Typ; C.OB[1] := 3; C.OB[2] := 3;
  If C.Enc Then
  Begin
    For I := 0 To N - 1 Do C.OB[13 + I] := TlGet(A + I);
    For I := 0 To 3 Do Iv[I] := C.CIv[I];
    TlSeqBytes(C.CSeq, Iv, 4);
    For I := 0 To 7 Do C.OB[5 + I] := Iv[4 + I];
    TlSeqBytes(C.CSeq, Aad, 0);
    Aad[8] := Typ; Aad[9] := 3; Aad[10] := 3;
    Aad[11] := (N Shr 8) And 255; Aad[12] := N And 255;
    TlGcm(C.CAes, Iv, Aad, 13, P + 13, N, True, Tag);
    For I := 0 To 15 Do C.OB[13 + N + I] := Tag[I];
    Inc(C.CSeq);
    L := N + 24;
  End
  Else
  Begin
    For I := 0 To N - 1 Do C.OB[5 + I] := TlGet(A + I);
    L := N;
  End;
  C.OB[3] := (L Shr 8) And 255; C.OB[4] := L And 255;
  TlSendRec := TlSendAll(C, P, L + 5);
End;

{ lit un enregistrement : type rendu, texte clair dans RB[RPos..REnd) ;
  -1 en cas d'erreur }
Function TlRecvRec(Var C : TlConn) : LongInt;
Var Typ, L, I : LongInt; Iv, Aad, Tag : TlBlk; P : TlPtr;
Begin
  TlRecvRec := -1;
  P := TlPtr(@C.RB[0]);
  If Not TlRecvAll(C, P, 5) Then Exit;
  Typ := C.RB[0];
  L := (C.RB[3] Shl 8) Or C.RB[4];
  If (L > TlRecMax - 5) Or (C.RB[1] <> 3) Then
  Begin
    TlErr := 'enregistrement TLS invalide'; Exit;
  End;
  If Not TlRecvAll(C, P + 5, L) Then Exit;
  C.RPos := 5; C.REnd := 5 + L;
  If C.Dec Then
  Begin
    If L < 24 Then Begin TlErr := 'enregistrement trop court'; Exit; End;
    For I := 0 To 3 Do Iv[I] := C.SIv[I];
    For I := 0 To 7 Do Iv[4 + I] := C.RB[5 + I];
    L := L - 24;
    TlSeqBytes(C.SSeq, Aad, 0);
    Aad[8] := Typ; Aad[9] := 3; Aad[10] := 3;
    Aad[11] := (L Shr 8) And 255; Aad[12] := L And 255;
    TlGcm(C.SAes, Iv, Aad, 13, P + 13, L, False, Tag);
    For I := 0 To 15 Do
      If Tag[I] <> C.RB[13 + L + I] Then
      Begin
        TlErr := 'enregistrement TLS altere (GCM)'; Exit;
      End;
    Inc(C.SSeq);
    C.RPos := 13; C.REnd := 13 + L;
  End;
  If Typ = 21 Then
  Begin
    If (C.REnd - C.RPos >= 2) And (C.RB[C.RPos + 1] = 0) Then
    Begin
      C.Eof := True; C.RPos := C.REnd; TlRecvRec := 23; Exit;
    End;
    Str(C.RB[C.RPos + 1], TlErr);
    TlErr := 'alerte TLS ' + TlErr;
    Exit;
  End;
  TlRecvRec := Typ;
End;

{ ---- poignee de main ---- }

{ message de la poignee de main suivant : type, corps dans TlHs^[4..] }
Function TlNextHs(Var C : TlConn; Var Tr : TlSha; Var Body : LongInt)
  : LongInt;
Var Typ, L, I : LongInt;
Begin
  TlNextHs := -1;
  { completer TlHs avec les enregistrements de type 22 }
  While True Do
  Begin
    If TlHsLen >= 4 Then
    Begin
      L := (TlHs^[1] Shl 16) Or (TlHs^[2] Shl 8) Or TlHs^[3];
      If L + 4 > TlHsMax Then Begin TlErr := 'message trop long'; Exit; End;
      If TlHsLen >= L + 4 Then Break;
    End;
    If C.RPos >= C.REnd Then
    Begin
      Typ := TlRecvRec(C);
      If Typ < 0 Then Exit;
      If Typ <> 22 Then Begin TlErr := 'message inattendu'; Exit; End;
    End;
    While (C.RPos < C.REnd) And (TlHsLen < TlHsMax) Do
    Begin
      TlHs^[TlHsLen] := C.RB[C.RPos]; Inc(TlHsLen); Inc(C.RPos);
    End;
  End;
  Typ := TlHs^[0];
  Body := L;
  TlShaAdd(Tr, TlPtr(@TlHs^[0]), L + 4);
  TlNextHs := Typ;
End;

{ retire le message traite de TlHs }
Procedure TlDropHs;
Var L, I : LongInt;
Begin
  L := ((TlHs^[1] Shl 16) Or (TlHs^[2] Shl 8) Or TlHs^[3]) + 4;
  For I := L To TlHsLen - 1 Do TlHs^[I - L] := TlHs^[I];
  TlHsLen := TlHsLen - L;
End;

{ messages de la poignee de main en construction (procedures globales :
  OS2PC n'aime pas les procedures imbriquees qui touchent les variables
  de leur parent) }
Var
  HsM : Array[0..511] Of Byte;
  HsN : LongInt;

Procedure HsPutB(V : LongInt);
Begin
  HsM[HsN] := V And 255; Inc(HsN);
End;

Procedure HsPutW(V : LongInt);
Begin
  HsPutB(V Shr 8); HsPutB(V);
End;

Function TlHandshake(Var C : TlConn; Host : String) : Boolean;
Var I, L, Typ, Body, Suite, P : LongInt;
    Tr, T2 : TlSha; CR, SR, Priv, Pub, SPub, Pms : TlKey32;
    Ms : Array[0..47] Of Byte; Kb : Array[0..39] Of Byte;
    Seed : Array[0..63] Of Byte; Hh : TlKey32; Key : TlBlk;
    GotKey : Boolean;

Begin
  TlHandshake := False;
  C.Enc := False; C.Dec := False; C.CSeq := 0; C.SSeq := 0;
  C.RPos := 0; C.REnd := 0; C.Eof := False;
  TlHsLen := 0;
  TlRandom(TlPtr(@CR[0]), 32);
  TlRandom(TlPtr(@Priv[0]), 32);
  { ClientHello }
  HsN := 0;
  HsPutB(1); HsPutB(0); HsPutB(0); HsPutB(0);
  HsPutB(3); HsPutB(3);
  For I := 0 To 31 Do HsPutB(CR[I]);
  HsPutB(0);
  HsPutW(6); HsPutW($C02F); HsPutW($C02B); HsPutW($00FF);
  HsPutB(1); HsPutB(0);
  L := HsN; HsPutW(0);                      { longueur des extensions }
  { nom du serveur (SNI), pas pour une adresse IP }
  If Not TlIsIp(Host) Then
  Begin
    HsPutW(0); HsPutW(Length(Host) + 5); HsPutW(Length(Host) + 3); HsPutB(0);
    HsPutW(Length(Host));
    For I := 1 To Length(Host) Do HsPutB(Ord(Host[I]));
  End;
  HsPutW($000A); HsPutW(6); HsPutW(4); HsPutW($001D); HsPutW($0017);
  HsPutW($000B); HsPutW(2); HsPutB(1); HsPutB(0);
  HsPutW($000D); HsPutW(22); HsPutW(20);
  HsPutW($0401); HsPutW($0501); HsPutW($0601); HsPutW($0403); HsPutW($0503); HsPutW($0603);
  HsPutW($0804); HsPutW($0805); HsPutW($0806); HsPutW($0201);
  HsM[L] := ((HsN - L - 2) Shr 8) And 255; HsM[L + 1] := (HsN - L - 2) And 255;
  HsM[1] := 0; HsM[2] := ((HsN - 4) Shr 8) And 255; HsM[3] := (HsN - 4) And 255;
  TlShaInit(Tr);
  TlShaAdd(Tr, TlPtr(@HsM[0]), HsN);
  If Not TlSendRec(C, 22, TlPtr(@HsM[0]), HsN) Then Exit;
  { ServerHello ... ServerHelloDone }
  GotKey := False; Suite := 0;
  Repeat
    Typ := TlNextHs(C, Tr, Body);
    If Typ < 0 Then Exit;
    If Typ = 2 Then
    Begin
      If (TlHs^[4] <> 3) Or (TlHs^[5] <> 3) Then
      Begin
        TlErr := 'le serveur refuse TLS 1.2'; Exit;
      End;
      For I := 0 To 31 Do SR[I] := TlHs^[6 + I];
      P := 38 + TlHs^[38] + 1;
      Suite := (TlHs^[P] Shl 8) Or TlHs^[P + 1];
      If (Suite <> $C02F) And (Suite <> $C02B) Then
      Begin
        TlErr := 'suite de chiffrement non prise en charge'; Exit;
      End;
    End
    Else If Typ = 12 Then
    Begin
      If (TlHs^[4] <> 3) Or (TlHs^[5] <> 0) Or (TlHs^[6] <> $1D) Or
         (TlHs^[7] <> 32) Then
      Begin
        TlErr := 'courbe x25519 refusee par le serveur'; Exit;
      End;
      For I := 0 To 31 Do SPub[I] := TlHs^[8 + I];
      GotKey := True;
    End
    Else If Typ = 11 Then
    Begin
      { premier certificat (cle publique du serveur pour CredSSP) }
      L := (TlHs^[7] Shl 16) Or (TlHs^[8] Shl 8) Or TlHs^[9];
      If L > SizeOf(TlCert) Then L := SizeOf(TlCert);
      For I := 0 To L - 1 Do TlCert[I] := TlHs^[10 + I];
      TlCertLen := L;
    End
    Else If Typ = 13 Then
    Begin
      TlErr := 'certificat client demande'; Exit;
    End;
    TlDropHs;
  Until Typ = 14;
  If (Suite = 0) Or Not GotKey Then
  Begin
    TlErr := 'poignee de main incomplete'; Exit;
  End;
  { ClientKeyExchange, cles }
  For I := 0 To 31 Do Pub[I] := 0;
  Pub[0] := 9;
  TlX25519(Pub, Priv, Pub);
  TlX25519(Pms, Priv, SPub);
  HsN := 0;
  HsPutB(16); HsPutB(0); HsPutB(0); HsPutB(33); HsPutB(32);
  For I := 0 To 31 Do HsPutB(Pub[I]);
  TlShaAdd(Tr, TlPtr(@HsM[0]), HsN);
  If Not TlSendRec(C, 22, TlPtr(@HsM[0]), HsN) Then Exit;
  For I := 0 To 31 Do
  Begin
    Seed[I] := CR[I]; Seed[32 + I] := SR[I];
  End;
  TlPrf(TlPtr(@Pms[0]), 32, 'master secret', TlPtr(@Seed[0]), 64,
        TlPtr(@Ms[0]), 48);
  For I := 0 To 31 Do
  Begin
    Seed[I] := SR[I]; Seed[32 + I] := CR[I];
  End;
  TlPrf(TlPtr(@Ms[0]), 48, 'key expansion', TlPtr(@Seed[0]), 64,
        TlPtr(@Kb[0]), 40);
  For I := 0 To 15 Do Key[I] := Kb[I];
  TlAesKey(C.CAes, Key);
  For I := 0 To 15 Do Key[I] := Kb[16 + I];
  TlAesKey(C.SAes, Key);
  For I := 0 To 3 Do
  Begin
    C.CIv[I] := Kb[32 + I]; C.SIv[I] := Kb[36 + I];
  End;
  { ChangeCipherSpec et Finished }
  HsM[0] := 1;
  If Not TlSendRec(C, 20, TlPtr(@HsM[0]), 1) Then Exit;
  C.Enc := True;
  T2 := Tr; TlShaDone(T2, TlPtr(@Hh[0]));
  HsM[0] := 20; HsM[1] := 0; HsM[2] := 0; HsM[3] := 12;
  TlPrf(TlPtr(@Ms[0]), 48, 'client finished', TlPtr(@Hh[0]), 32,
        TlPtr(@HsM[4]), 12);
  TlShaAdd(Tr, TlPtr(@HsM[0]), 16);
  If Not TlSendRec(C, 22, TlPtr(@HsM[0]), 16) Then Exit;
  { ChangeCipherSpec et Finished du serveur }
  Repeat
    Typ := TlRecvRec(C);
    If Typ < 0 Then Exit;
    If Typ = 22 Then
    Begin
      { NewSessionTicket eventuel avant le ChangeCipherSpec }
      C.RPos := C.REnd;
    End
    Else If Typ <> 20 Then Begin TlErr := 'ChangeCipherSpec attendu'; Exit;
    End;
  Until Typ = 20;
  C.Dec := True;
  C.RPos := C.REnd;
  T2 := Tr; TlShaDone(T2, TlPtr(@Hh[0]));
  TlPrf(TlPtr(@Ms[0]), 48, 'server finished', TlPtr(@Hh[0]), 32,
        TlPtr(@HsM[100]), 12);
  TlHsLen := 0;
  Typ := TlNextHs(C, T2, Body);
  If (Typ <> 20) Or (Body <> 12) Then
  Begin
    If Typ >= 0 Then TlErr := 'Finished du serveur attendu';
    Exit;
  End;
  For I := 0 To 11 Do
    If TlHs^[4 + I] <> HsM[100 + I] Then
    Begin
      TlErr := 'Finished du serveur invalide'; Exit;
    End;
  TlHandshake := True;
End;

{ ---- donnees de l'application ---- }

{ lit au plus N octets ; 0 a la fin, -1 en cas d'erreur }
Function TlRead(Var C : TlConn; A : TlPtr; N : LongInt) : LongInt;
Var Typ, K : LongInt;
Begin
  TlRead := -1;
  If Not C.Tls Then
  Begin
    TlRead := TlSockRecv(C.Sock, A, N);
    Exit;
  End;
  While C.RPos >= C.REnd Do
  Begin
    If C.Eof Then Begin TlRead := 0; Exit; End;
    Typ := TlRecvRec(C);
    If Typ < 0 Then
    Begin
      { fermeture TCP sans close_notify : fin des donnees }
      If TlErr = 'connexion fermee' Then TlRead := 0;
      Exit;
    End;
    If Typ <> 23 Then C.RPos := C.REnd;
  End;
  K := C.REnd - C.RPos;
  If K > N Then K := N;
  For Typ := 0 To K - 1 Do TlPut(A + Typ, C.RB[C.RPos + Typ]);
  C.RPos := C.RPos + K;
  TlRead := K;
End;

Function TlWrite(Var C : TlConn; A : TlPtr; N : LongInt) : Boolean;
Var K : LongInt;
Begin
  TlWrite := False;
  If Not C.Tls Then
  Begin
    TlWrite := TlSendAll(C, A, N); Exit;
  End;
  While N > 0 Do
  Begin
    K := N; If K > 16384 Then K := 16384;
    If Not TlSendRec(C, 23, A, K) Then Exit;
    A := A + K; N := N - K;
  End;
  TlWrite := True;
End;

Const
  Md5K : Array[0..63] Of LongWord = (
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
  Md5S : Array[0..15] Of Byte = (7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16,
    23, 6, 10, 15, 21);
  Md4S : Array[0..11] Of Byte = (3, 7, 11, 19, 3, 5, 9, 13, 3, 9, 11, 15);
  Md4K2 : Array[0..15] Of Byte = (0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14,
    3, 7, 11, 15);
  Md4K3 : Array[0..15] Of Byte = (0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13,
    3, 11, 7, 15);
  { SPNEGO : OID de SPNEGO puis mechTypes (NTLMSSP) }
  SpnOid : Array[0..7] Of Byte = ($06, $06, $2B, $06, $01, $05, $05, $02);
  SpnMech : Array[0..15] Of Byte = ($A0, $0E, $30, $0C, $06, $0A, $2B,
    $06, $01, $04, $01, $82, $37, $02, $02, $0A);

Type
  TMd = Record
    H : Array[0..3] Of LongInt;
    B : Array[0..63] Of Byte;
    N, Len : LongInt;
    Four : Boolean;                  { MD4 (sinon MD5) }
  End;

{ ---- MD4 et MD5 (RFC 1320 et 1321) ---- }

Function MdRol(X, N : LongInt) : LongInt;
Begin
  MdRol := (X Shl N) Or (X Shr (32 - N));
End;

Procedure MdBlock(Var C : TMd);
Var M : Array[0..15] Of LongInt; X : Array[0..3] Of LongInt;
    I, T, A, B, Cc, D, F, G, S : LongInt;
Begin
  For I := 0 To 15 Do
    M[I] := C.B[I * 4] Or (C.B[I * 4 + 1] Shl 8) Or (C.B[I * 4 + 2] Shl 16)
            Or (C.B[I * 4 + 3] Shl 24);
  For I := 0 To 3 Do X[I] := C.H[I];
  If C.Four Then
    For I := 0 To 47 Do
    Begin
      T := (4 - (I And 3)) And 3;
      A := X[T]; B := X[(T + 1) And 3]; Cc := X[(T + 2) And 3];
      D := X[(T + 3) And 3];
      If I < 16 Then
      Begin
        F := (B And Cc) Or ((Not B) And D); G := I; S := Md4S[I And 3];
      End
      Else If I < 32 Then
      Begin
        F := (B And Cc) Or (B And D) Or (Cc And D);
        F := F + $5A827999; G := Md4K2[I - 16]; S := Md4S[4 + (I And 3)];
      End
      Else
      Begin
        F := (B Xor Cc Xor D) + LongInt($6ED9EBA1); G := Md4K3[I - 32];
        S := Md4S[8 + (I And 3)];
      End;
      X[T] := MdRol(A + F + M[G], S);
    End
  Else
    For I := 0 To 63 Do
    Begin
      T := (4 - (I And 3)) And 3;
      A := X[T]; B := X[(T + 1) And 3]; Cc := X[(T + 2) And 3];
      D := X[(T + 3) And 3];
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
      X[T] := B + MdRol(A + F + LongInt(Md5K[I]) + M[G],
                        Md5S[(I Shr 4) * 4 + (I And 3)]);
    End;
  For I := 0 To 3 Do C.H[I] := C.H[I] + X[I];
End;

Procedure MdInit(Var C : TMd; Four : Boolean);
Begin
  C.H[0] := $67452301; C.H[1] := LongInt($EFCDAB89);
  C.H[2] := LongInt($98BADCFE); C.H[3] := $10325476;
  C.N := 0; C.Len := 0; C.Four := Four;
End;

Procedure MdAdd(Var C : TMd; A, N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do
  Begin
    C.B[C.N] := GB(A + I);
    Inc(C.N);
    If C.N = 64 Then
    Begin
      MdBlock(C);
      C.N := 0;
    End;
  End;
  C.Len := C.Len + N;
End;

Procedure MdDone(Var C : TMd; Out0 : LongInt);
Var Z : Array[0..7] Of Byte; L, I : LongInt;
Begin
  L := C.Len;
  Z[0] := $80;
  MdAdd(C, LongInt(@Z[0]), 1);
  Z[0] := 0;
  While C.N <> 56 Do MdAdd(C, LongInt(@Z[0]), 1);
  Z[0] := (L Shl 3) And 255; Z[1] := (L Shr 5) And 255;
  Z[2] := (L Shr 13) And 255; Z[3] := (L Shr 21) And 255;
  Z[4] := (L Shr 29) And 7; Z[5] := 0; Z[6] := 0; Z[7] := 0;
  MdAdd(C, LongInt(@Z[0]), 8);
  For I := 0 To 3 Do SL(Out0 + I * 4, C.H[I]);
End;

{ HMAC-MD5 (cle de 64 octets au plus) de Msg puis Msg2 }
Procedure HmacMd5(Key, KLen, Msg, MLen, Msg2, M2Len, Out0 : LongInt);
Var C : TMd; Pad : Array[0..63] Of Byte; In0 : Array[0..15] Of Byte;
    I : LongInt;
Begin
  For I := 0 To 63 Do
    If I < KLen Then Pad[I] := GB(Key + I) Xor $36 Else Pad[I] := $36;
  MdInit(C, False);
  MdAdd(C, LongInt(@Pad[0]), 64);
  MdAdd(C, Msg, MLen);
  If M2Len > 0 Then MdAdd(C, Msg2, M2Len);
  MdDone(C, LongInt(@In0[0]));
  For I := 0 To 63 Do Pad[I] := Pad[I] Xor ($36 Xor $5C);
  MdInit(C, False);
  MdAdd(C, LongInt(@Pad[0]), 64);
  MdAdd(C, LongInt(@In0[0]), 16);
  MdDone(C, Out0);
End;

{ Chaine (Latin-1) en UTF-16LE en A ; octets ecrits }
Function Uni16(A : LongInt; S : String) : LongInt;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do SW(A + (I - 1) * 2, Ord(S[I]));
  Uni16 := Length(S) * 2;
End;

{ Hachage NT : MD4 du mot de passe en UTF-16LE }
Procedure NtHash(Pw : String; Out0 : LongInt);
Var C : TMd; B : Array[0..511] Of Byte; N : LongInt;
Begin
  N := Uni16(LongInt(@B[0]), Pw);
  MdInit(C, True);
  MdAdd(C, LongInt(@B[0]), N);
  MdDone(C, Out0);
End;


{ ---- RC4 (scellement NTLM) ---- }

Type
  TRc4 = Record
    S : Array[0..255] Of Byte;
    I, J : LongInt;
  End;

Procedure Rc4Init(Var R : TRc4; Key, N : LongInt);
Var I, J, T : LongInt;
Begin
  For I := 0 To 255 Do R.S[I] := I;
  J := 0;
  For I := 0 To 255 Do
  Begin
    J := (J + R.S[I] + GB(Key + I Mod N)) And 255;
    T := R.S[I]; R.S[I] := R.S[J]; R.S[J] := T;
  End;
  R.I := 0; R.J := 0;
End;

Procedure Rc4(Var R : TRc4; Src, Dst, N : LongInt);
Var K, T : LongInt;
Begin
  For K := 0 To N - 1 Do
  Begin
    R.I := (R.I + 1) And 255;
    R.J := (R.J + R.S[R.I]) And 255;
    T := R.S[R.I]; R.S[R.I] := R.S[R.J]; R.S[R.J] := T;
    SB(Dst + K, GB(Src + K) Xor R.S[(R.S[R.I] + R.S[R.J]) And 255]);
  End;
End;

Procedure Md5Of(A, N, Out0 : LongInt);
Var C : TMd;
Begin
  MdInit(C, False);
  MdAdd(C, A, N);
  MdDone(C, Out0);
End;

{ ==================================================================== }
{ NTLMv2 (avec signature et scellement) et CredSSP (MS-CSSP)            }
{ ==================================================================== }

Const
  { UNICODE, REQUEST_TARGET, SIGN, SEAL, NTLM, ALWAYS_SIGN,
    EXTENDED_SESSIONSECURITY, TARGET_INFO, 128, KEY_EXCH, 56 }
  NtlmCFlags = LongInt($E0888235);

Var
  NtUser, NtDom, NtPass : String;
  NtKeyX : Array[0..15] Of Byte;          { ExportedSessionKey }
  NtSignK : Array[0..15] Of Byte;         { client -> serveur }
  NtSeal : TRc4;
  NtSeq : LongInt;
  Wk1, Wk2, Wk3 : LongInt;                { tampons de travail (16 Ko) }

{ Tag, longueur DER puis N octets de Src en Dst ; octets ecrits }
Function DerWrap(Tag, Src, N, Dst : LongInt) : LongInt;
Var H : LongInt;
Begin
  SB(Dst, Tag);
  If N < 128 Then
  Begin
    SB(Dst + 1, N); H := 2;
  End
  Else If N < 256 Then
  Begin
    SB(Dst + 1, $81); SB(Dst + 2, N); H := 3;
  End
  Else
  Begin
    SB(Dst + 1, $82); SB(Dst + 2, N Shr 8); SB(Dst + 3, N); H := 4;
  End;
  MoveB(Src, Dst + H, N);
  DerWrap := H + N;
End;

{ Longueur DER en A : valeur ; Hl : octets de l'entete (tag compris) }
Function DerLen(A : LongInt; Var Hl : LongInt) : LongInt;
Var L, K, I : LongInt;
Begin
  L := GB(A + 1);
  Hl := 2;
  If L >= $80 Then
  Begin
    K := L And $7F; L := 0;
    For I := 1 To K Do L := (L Shl 8) Or GB(A + 1 + I);
    Hl := 2 + K;
  End;
  DerLen := L;
End;

Function NtlmFind(A, N : LongInt) : LongInt;
Var I : LongInt;
Begin
  NtlmFind := 0;
  For I := 0 To N - 8 Do
    If (GL(A + I) = $4D4C544E) And (GL(A + I + 4) = $00505353) Then
    Begin
      NtlmFind := A + I;
      Exit;
    End;
End;

Procedure NtlmField(M, F, Len, Ofs : LongInt);
Begin
  SW(M + F, Len); SW(M + F + 2, Len); SL(M + F + 4, Ofs);
End;

Function NtlmNegotiate(Dst : LongInt) : LongInt;
Begin
  ZeroB(Dst, 32);
  SL(Dst, $4D4C544E); SL(Dst + 4, $00505353);
  SL(Dst + 8, 1); SL(Dst + 12, NtlmCFlags);
  NtlmNegotiate := 32;
End;

{ cle derivee : MD5(cle exportee + constante + 0) }
Procedure NtlmKey(Magic : String; Out0 : LongInt);
Var B : Array[0..99] Of Byte; K : LongInt;
Begin
  MoveB(LongInt(@NtKeyX[0]), LongInt(@B[0]), 16);
  For K := 1 To Length(Magic) Do B[15 + K] := Ord(Magic[K]);
  B[16 + Length(Magic)] := 0;
  Md5Of(LongInt(@B[0]), 17 + Length(Magic), Out0);
End;

{ AUTHENTICATE (NTLMv2) d'apres le CHALLENGE C ; octets ecrits en Dst }
Function NtlmAuth(C, CLen, Dst : LongInt) : LongInt;
Var TI, TLen, P, K, Q, Id, Ln, Tmp, TmpN, Fl : LongInt;
    NtV2, Proof, Base, Hash : Array[0..15] Of Byte; SealK : Array[0..15] Of Byte;
    Ts, Cc : Array[0..7] Of Byte; U : Array[0..299] Of Byte; Dom : String;
    R : TRc4;
Begin
  TLen := GW(C + 40); TI := C + GL(C + 44);
  If GL(C + 44) + TLen > CLen Then TLen := 0;
  Fl := NtlmCFlags And GL(C + 20);
  Dom := NtDom;
  If Dom = '' Then
  Begin
    K := GW(C + 12); Q := C + GL(C + 16);
    For P := 0 To MinI(K Div 2, 63) - 1 Do Dom := Dom + Chr(GB(Q + P * 2));
  End;
  { horodatage du serveur (MsvAvTimestamp) }
  ZeroB(LongInt(@Ts[0]), 8);
  P := 0;
  While P + 4 <= TLen Do
  Begin
    Id := GW(TI + P); Ln := GW(TI + P + 2);
    If Id = 0 Then Break;
    If (Id = 7) And (Ln = 8) Then MoveB(TI + P + 4, LongInt(@Ts[0]), 8);
    P := P + 4 + Ln;
  End;
  TlRandom(LongInt(@Cc[0]), 8);
  NtHash(NtPass, LongInt(@Hash[0]));
  K := Uni16(LongInt(@U[0]), UpS(NtUser));
  K := K + Uni16(LongInt(@U[K]), Dom);
  HmacMd5(LongInt(@Hash[0]), 16, LongInt(@U[0]), K, 0, 0, LongInt(@NtV2[0]));
  ZeroB(Dst, 64);
  SL(Dst, $4D4C544E); SL(Dst + 4, $00505353); SL(Dst + 8, 3);
  SL(Dst + 60, Fl);
  P := 64;
  K := Uni16(Dst + P, Dom); NtlmField(Dst, 28, K, P); P := P + K;
  K := Uni16(Dst + P, NtUser); NtlmField(Dst, 36, K, P); P := P + K;
  K := Uni16(Dst + P, 'OS2-0'); NtlmField(Dst, 44, K, P); P := P + K;
  ZeroB(Dst + P, 24); NtlmField(Dst, 12, 24, P); P := P + 24;
  Tmp := Dst + P + 16;
  ZeroB(Tmp, 28);
  SB(Tmp, 1); SB(Tmp + 1, 1);
  MoveB(LongInt(@Ts[0]), Tmp + 8, 8);
  MoveB(LongInt(@Cc[0]), Tmp + 16, 8);
  MoveB(TI, Tmp + 28, TLen);
  ZeroB(Tmp + 28 + TLen, 4);
  TmpN := 32 + TLen;
  HmacMd5(LongInt(@NtV2[0]), 16, C + 24, 8, Tmp, TmpN, LongInt(@Proof[0]));
  MoveB(LongInt(@Proof[0]), Dst + P, 16);
  NtlmField(Dst, 20, 16 + TmpN, P); P := P + 16 + TmpN;
  { cle de session : SessionBaseKey ; avec KEY_EXCH, une cle aleatoire
    chiffree par RC4 (EncryptedRandomSessionKey) }
  HmacMd5(LongInt(@NtV2[0]), 16, LongInt(@Proof[0]), 16, 0, 0,
          LongInt(@Base[0]));
  If (Fl And $40000000) <> 0 Then
  Begin
    TlRandom(LongInt(@NtKeyX[0]), 16);
    Rc4Init(R, LongInt(@Base[0]), 16);
    Rc4(R, LongInt(@NtKeyX[0]), Dst + P, 16);
    NtlmField(Dst, 52, 16, P); P := P + 16;
  End
  Else
  Begin
    MoveB(LongInt(@Base[0]), LongInt(@NtKeyX[0]), 16);
    NtlmField(Dst, 52, 0, P);
  End;
  NtlmKey('session key to client-to-server signing key magic constant',
          LongInt(@NtSignK[0]));
  NtlmKey('session key to client-to-server sealing key magic constant',
          LongInt(@SealK[0]));
  Rc4Init(NtSeal, LongInt(@SealK[0]), 16);
  NtSeq := 0;
  NtlmAuth := P;
End;

{ Scellement (EncryptMessage) : signature de 16 octets puis le message
  chiffre ; octets ecrits en Dst }
Function NtlmSeal(Src, N, Dst : LongInt) : LongInt;
Var Mac : Array[0..15] Of Byte; Sq : Array[0..3] Of Byte;
    Chk : Array[0..7] Of Byte;
Begin
  SL(LongInt(@Sq[0]), NtSeq);
  HmacMd5(LongInt(@NtSignK[0]), 16, LongInt(@Sq[0]), 4, Src, N,
          LongInt(@Mac[0]));
  Rc4(NtSeal, Src, Dst + 16, N);
  Rc4(NtSeal, LongInt(@Mac[0]), LongInt(@Chk[0]), 8);
  SL(Dst, 1);
  MoveB(LongInt(@Chk[0]), Dst + 4, 8);
  SL(Dst + 12, NtSeq);
  Inc(NtSeq);
  NtlmSeal := N + 16;
End;

{ TSRequest (version 6) : jeton NTLM, authInfo, pubKeyAuth, clientNonce
  (N = 0 : absent) ; octets ecrits en Dst }
Function TsReq(Tok, TokN, Auth, AuthN, Pub, PubN, Nonce, NonceN,
               Dst : LongInt) : LongInt;
Var K, L : LongInt;
Begin
  K := 0;
  SB(Wk1, $A0); SB(Wk1 + 1, 3); SB(Wk1 + 2, 2); SB(Wk1 + 3, 1);
  SB(Wk1 + 4, 6);
  K := 5;
  If TokN > 0 Then
  Begin
    L := DerWrap($04, Tok, TokN, Wk2);
    L := DerWrap($A0, Wk2, L, Wk3);
    L := DerWrap($30, Wk3, L, Wk2);
    L := DerWrap($30, Wk2, L, Wk3);
    K := K + DerWrap($A1, Wk3, L, Wk1 + K);
  End;
  If AuthN > 0 Then
  Begin
    L := DerWrap($04, Auth, AuthN, Wk2);
    K := K + DerWrap($A2, Wk2, L, Wk1 + K);
  End;
  If PubN > 0 Then
  Begin
    L := DerWrap($04, Pub, PubN, Wk2);
    K := K + DerWrap($A3, Wk2, L, Wk1 + K);
  End;
  If NonceN > 0 Then
  Begin
    L := DerWrap($04, Nonce, NonceN, Wk2);
    K := K + DerWrap($A5, Wk2, L, Wk1 + K);
  End;
  TsReq := DerWrap($30, Wk1, K, Dst);
End;

{ Champ [Tag] de premier niveau d'un TSRequest (A, N) : adresse de son
  contenu, 0 s'il manque }
Function TsField(A, N, Tag : LongInt; Var FL : LongInt) : LongInt;
Var P, E, Hl, L : LongInt;
Begin
  TsField := 0;
  L := DerLen(A, Hl);
  P := A + Hl; E := A + Hl + L;
  If E > A + N Then E := A + N;
  While P < E Do
  Begin
    L := DerLen(P, Hl);
    If GB(P) = Tag Then
    Begin
      TsField := P + Hl; FL := L;
      Exit;
    End;
    P := P + Hl + L;
  End;
End;

{ Cle publique du certificat du serveur (subjectPublicKey sans l'octet
  des bits inutilises) : adresse et longueur }
Function CertPubKey(Var N : LongInt) : LongInt;
Var P, Hl, L, I, A : LongInt;
Begin
  CertPubKey := 0; N := 0;
  If TlCertLen < 32 Then Exit;
  A := LongInt(@TlCert[0]);
  L := DerLen(A, Hl);                     { Certificate }
  P := A + Hl;
  L := DerLen(P, Hl);                     { tbsCertificate }
  P := P + Hl;
  If GB(P) = $A0 Then                     { [0] version }
  Begin
    L := DerLen(P, Hl); P := P + Hl + L;
  End;
  { serialNumber, signature, issuer, validity, subject }
  For I := 1 To 5 Do
  Begin
    L := DerLen(P, Hl); P := P + Hl + L;
  End;
  L := DerLen(P, Hl);                     { subjectPublicKeyInfo }
  P := P + Hl;
  L := DerLen(P, Hl); P := P + Hl + L;    { algorithm }
  If GB(P) <> $03 Then Exit;              { BIT STRING }
  L := DerLen(P, Hl);
  CertPubKey := P + Hl + 1;
  N := L - 1;
End;

{ ==================================================================== }
{ Protocole RDP (MS-RDPBCGR) : X.224, MCS/GCC, CredSSP, activation,     }
{ mises a jour graphiques (bitmaps, RLE entrelace), entrees             }
{ ==================================================================== }

Var
  Tc : TlConn;
  RdpHost, RdpUser, RdpDom, RdpPass : String;
  RdpPort, KbdLay : LongInt;
  ReqW, ReqH : LongInt;                   { taille demandee }
  FbW, FbH, FbPitch, Fb : LongInt;        { ecran distant 24 bits, de bas en haut }
  IoChan, UserChan, ShareId, SrvChan, Proto : LongInt;
  Tx, Rx, InB, Frag, FragLen, DecB, Pool, ViewX, ViewY : LongInt;
  SendSem, FbSem : LongInt;               { semaphores d'exclusion }
  Active, Licensed, Connected, FirstAct : Boolean;
  ErrInfo : LongInt;
  RdpErr, RdpStatus : String;
  PalRgb : Array[0..255] Of LongInt;      { palette (8 bits par point) en RVB }
  Bmi : Array[0..3] Of LongInt;           { BITMAPINFOHEADER2 (16 octets) }
  SessWnd, DlgWnd : LongInt;              { fenetres clientes (session, boite) }
  DirtyL, DirtyT, DirtyR, DirtyB : LongInt;
  PendL, PendT, PendR, PendB : LongInt;   { zone a redessiner remise a l'interface }
  PendPosted : Boolean;

Function HexS(V : LongInt) : String;
Const D : String[16] = '0123456789ABCDEF';
Var S : String; I : LongInt;
Begin
  S := '';
  For I := 7 DownTo 0 Do S := S + D[((V Shr (I * 4)) And 15) + 1];
  HexS := S;
End;

Function PoolB(I : LongInt) : LongInt;
Begin
  PoolB := Pool + I * 16384;
End;

Procedure Status(S : String);
Begin
  RdpStatus := S;
  If DlgWnd <> 0 Then Dummy := WinPostMsg(DlgWnd, WM_RDPSTATUS, 0, 0);
End;


{ ---- transport ---- }

Function SendRaw(A, N : LongInt) : Boolean;
Begin
  Dummy := DosRequestMutexSem(SendSem, -1);
  SendRaw := TlWrite(Tc, A, N);
  Dummy := DosReleaseMutexSem(SendSem);
End;

Function RecvAll(A, N : LongInt) : Boolean;
Var R : LongInt;
Begin
  RecvAll := False;
  While N > 0 Do
  Begin
    R := TlRead(Tc, A, N);
    If R <= 0 Then Exit;
    A := A + R; N := N - R;
  End;
  RecvAll := True;
End;

{ PDU suivante dans Rx : 1 (TPKT), 2 (chemin rapide), 0 erreur ; Len :
  octets de la PDU entiere }
Function RecvPdu(Var Len : LongInt) : LongInt;
Var B, L : LongInt;
Begin
  RecvPdu := 0; Len := 0;
  If Not RecvAll(Rx, 1) Then Exit;
  B := GB(Rx);
  If B = 3 Then
  Begin
    If Not RecvAll(Rx + 1, 3) Then Exit;
    L := GWB(Rx + 2);
    If (L < 4) Or (L > 65535) Then Exit;
    If Not RecvAll(Rx + 4, L - 4) Then Exit;
    Len := L;
    RecvPdu := 1;
    Exit;
  End;
  If (B And 3) <> 0 Then Exit;
  If Not RecvAll(Rx + 1, 1) Then Exit;
  L := GB(Rx + 1);
  If (L And $80) <> 0 Then
  Begin
    If Not RecvAll(Rx + 2, 1) Then Exit;
    L := ((L And $7F) Shl 8) Or GB(Rx + 2);
    If Not RecvAll(Rx + 3, L - 3) Then Exit;
  End
  Else If Not RecvAll(Rx + 2, L - 2) Then Exit;
  Len := L;
  RecvPdu := 2;
End;

{ TPKT et X.224 (donnees) autour de N octets deja places en A + 7 }
Function SendTpkt(A, N : LongInt) : Boolean;
Begin
  SB(A, 3); SB(A + 1, 0); SWB(A + 2, N + 7);
  SB(A + 4, 2); SB(A + 5, $F0); SB(A + 6, $80);
  SendTpkt := SendRaw(A, N + 7);
End;

{ MCS Send Data Request vers Chan : le contenu (N octets) est en A + 15 }
Function SendMcs(A, Chan, N : LongInt) : Boolean;
Begin
  SB(A + 7, $64);
  SWB(A + 8, UserChan - 1001);
  SWB(A + 10, Chan);
  SB(A + 12, $70);
  SB(A + 13, $80 Or ((N Shr 8) And $7F)); SB(A + 14, N And 255);
  SendMcs := SendTpkt(A, N + 8);
End;

{ PDU de donnees (Share Data) de type Typ2 : contenu de N octets en
  Tx + 33 }
Function SendData(Typ2, N : LongInt) : Boolean;
Var P : LongInt;
Begin
  P := Tx + 15;
  SW(P, N + 18); SW(P + 2, $17); SW(P + 4, UserChan);
  SL(P + 6, ShareId); SB(P + 10, 0); SB(P + 11, 1);
  SW(P + 12, N + 4); SB(P + 14, Typ2); SB(P + 15, 0); SW(P + 16, 0);
  SendData := SendMcs(Tx, IoChan, N + 18);
End;


{ ---- CredSSP (NLA) ---- }

Function RecvTs(Dst : LongInt) : LongInt;
Var L, K, I : LongInt;
Begin
  RecvTs := 0;
  If Not RecvAll(Dst, 2) Then Exit;
  L := GB(Dst + 1); K := 0;
  If (L And $80) <> 0 Then
  Begin
    K := L And $7F;
    If (K < 1) Or (K > 3) Then Exit;
    If Not RecvAll(Dst + 2, K) Then Exit;
    L := 0;
    For I := 0 To K - 1 Do L := (L Shl 8) Or GB(Dst + 2 + I);
  End;
  If L > 16000 Then Exit;
  If Not RecvAll(Dst + 2 + K, L) Then Exit;
  RecvTs := L + 2 + K;
End;

{ errorCode d'un TSRequest (0 : aucun) }
Function TsError(A, N : LongInt) : LongInt;
Var P, L, V, I : LongInt;
Begin
  TsError := 0;
  P := TsField(A, N, $A4, L);
  If (P = 0) Or (GB(P) <> 2) Then Exit;
  V := 0;
  For I := 1 To GB(P + 1) Do V := (V Shl 8) Or GB(P + 1 + I);
  TsError := V;
End;

Function CredSsp : Boolean;
Var Tok, Chal, Seal, Msg, CrA, CrB, CrC, K, L, S, Ver, P, FL, PK, PN,
    E : LongInt;
    Nonce : Array[0..31] Of Byte; Hash : Array[0..31] Of Byte;
    Sh : TlSha; Mag : String;
Begin
  CredSsp := False;
  Tok := PoolB(0); Chal := PoolB(1); Seal := PoolB(2); Msg := PoolB(3);
  CrA := PoolB(4); CrB := PoolB(5); CrC := PoolB(6);
  NtUser := RdpUser; NtDom := RdpDom; NtPass := RdpPass;
  { NEGOTIATE }
  K := NtlmNegotiate(Tok);
  L := TsReq(Tok, K, 0, 0, 0, 0, 0, 0, Msg);
  If Not SendRaw(Msg, L) Then Exit;
  { CHALLENGE }
  L := RecvTs(Msg);
  If L = 0 Then
  Begin
    RdpErr := 'Le serveur a ferm'#233' la connexion (CredSSP).';
    Exit;
  End;
  E := TsError(Msg, L);
  P := TsField(Msg, L, $A0, FL);
  Ver := 2;
  If (P <> 0) And (GB(P) = 2) Then Ver := GB(P + 1 + GB(P + 1));
  P := NtlmFind(Msg, L);
  If (P = 0) Or (E <> 0) Then
  Begin
    RdpErr := 'R'#233'ponse NTLM invalide du serveur.';
    Exit;
  End;
  FL := Msg + L - P;
  MoveB(P, Chal, FL);
  { AUTHENTICATE et cle publique du serveur }
  K := NtlmAuth(Chal, FL, Tok);
  PK := CertPubKey(PN);
  If PK = 0 Then
  Begin
    RdpErr := 'Certificat du serveur illisible.';
    Exit;
  End;
  If Ver >= 5 Then
  Begin
    TlRandom(LongInt(@Nonce[0]), 32);
    { (WPC perd un #0 final : l'octet nul est ajoute a part) }
    Mag := 'CredSSP Client-To-Server Binding Hash';
    TlShaInit(Sh);
    TlShaAdd(Sh, LongInt(@Mag[1]), Length(Mag));
    TlShaByte(Sh, 0);
    TlShaAdd(Sh, LongInt(@Nonce[0]), 32);
    TlShaAdd(Sh, PK, PN);
    TlShaDone(Sh, LongInt(@Hash[0]));
    S := NtlmSeal(LongInt(@Hash[0]), 32, Seal);
    L := TsReq(Tok, K, 0, 0, Seal, S, LongInt(@Nonce[0]), 32, Msg);
  End
  Else
  Begin
    S := NtlmSeal(PK, PN, Seal);
    L := TsReq(Tok, K, 0, 0, Seal, S, 0, 0, Msg);
  End;
  If Not SendRaw(Msg, L) Then Exit;
  { pubKeyAuth du serveur, ou erreur (mauvais mot de passe...) }
  L := RecvTs(Msg);
  E := 0;
  If L > 0 Then E := TsError(Msg, L);
  If (L = 0) Or (E <> 0) Or (TsField(Msg, L, $A3, FL) = 0) Then
  Begin
    If (E = LongInt($C000006D)) Or (E = LongInt($8009030C)) Or (L = 0) Then
      RdpErr := 'Nom d''utilisateur ou mot de passe incorrect.'
    Else If E = LongInt($C0000072) Then RdpErr := 'Ce compte est d'#233'sactiv'#233'.'
    Else If E = LongInt($C0000071) Then RdpErr := 'Le mot de passe a expir'#233'.'
    Else RdpErr := 'Authentification refus'#233'e (code ' + HexS(E) + ').';
    Exit;
  End;
  { TSCredentials : TSPasswordCreds (domaine, utilisateur, mot de passe) }
  K := 0;
  S := Uni16(CrC, RdpDom); S := DerWrap($04, CrC, S, CrB);
  K := K + DerWrap($A0, CrB, S, CrA + K);
  S := Uni16(CrC, RdpUser); S := DerWrap($04, CrC, S, CrB);
  K := K + DerWrap($A1, CrB, S, CrA + K);
  S := Uni16(CrC, RdpPass); S := DerWrap($04, CrC, S, CrB);
  K := K + DerWrap($A2, CrB, S, CrA + K);
  S := DerWrap($30, CrA, K, CrB);
  S := DerWrap($04, CrB, S, CrC);
  SB(CrA, $A0); SB(CrA + 1, 3); SB(CrA + 2, 2); SB(CrA + 3, 1); SB(CrA + 4, 1);
  S := DerWrap($A1, CrC, S, CrA + 5);
  S := DerWrap($30, CrA, S + 5, CrB);
  S := NtlmSeal(CrB, S, Seal);
  ZeroB(CrB, 600);
  L := TsReq(0, 0, Seal, S, 0, 0, 0, 0, Msg);
  If Not SendRaw(Msg, L) Then Exit;
  CredSsp := True;
End;

{ ---- connexion MCS ---- }

Function BerInt(V, Dst : LongInt) : LongInt;
Begin
  SB(Dst, 2);
  If V < $80 Then
  Begin
    SB(Dst + 1, 1); SB(Dst + 2, V); BerInt := 3;
  End
  Else If V < $8000 Then
  Begin
    SB(Dst + 1, 2); SWB(Dst + 2, V); BerInt := 4;
  End
  Else
  Begin
    SB(Dst + 1, 3); SB(Dst + 2, 0); SWB(Dst + 3, V); BerInt := 5;
  End;
End;

Function BerWrap(Tag, Src, N, Dst : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := 0;
  If Tag > 255 Then
  Begin
    SB(Dst, Tag Shr 8); H := 1;
  End;
  SB(Dst + H, Tag And 255); Inc(H);
  If N < 128 Then
  Begin
    SB(Dst + H, N); Inc(H);
  End
  Else
  Begin
    SB(Dst + H, $82); SWB(Dst + H + 1, N); H := H + 3;
  End;
  MoveB(Src, Dst + H, N);
  BerWrap := H + N;
End;

Function DomParams(A, B, C, D, E, F, G, H, Dst : LongInt) : LongInt;
Var T : Array[0..63] Of Byte; K : LongInt;
Begin
  K := 0;
  K := K + BerInt(A, LongInt(@T[K])); K := K + BerInt(B, LongInt(@T[K]));
  K := K + BerInt(C, LongInt(@T[K])); K := K + BerInt(D, LongInt(@T[K]));
  K := K + BerInt(E, LongInt(@T[K])); K := K + BerInt(F, LongInt(@T[K]));
  K := K + BerInt(G, LongInt(@T[K])); K := K + BerInt(H, LongInt(@T[K]));
  DomParams := BerWrap($30, LongInt(@T[0]), K, Dst);
End;

{ MCS Connect-Initial avec la demande GCC (donnees du client) dans Tx }
Function ConnectInitial : Boolean;
Var U, G, M, K, N, L : LongInt; Nm : String;
Begin
  U := PoolB(0); G := PoolB(1); M := PoolB(2);
  ZeroB(U, 600);
  { CS_CORE }
  SW(U, $C001); SW(U + 2, 216);
  SL(U + 4, $00080004);
  SW(U + 8, ReqW); SW(U + 10, ReqH);
  SW(U + 12, $CA01); SW(U + 14, $AA03);
  SL(U + 16, KbdLay);                     { disposition du clavier }
  SL(U + 20, 2600);
  Nm := 'OS2-0';
  Dummy := Uni16(U + 24, Nm);
  SL(U + 56, 4); SL(U + 60, 0); SL(U + 64, 12);
  SW(U + 132, $CA01); SW(U + 134, 1); SL(U + 136, 0);
  SW(U + 140, 16);                        { highColorDepth }
  SW(U + 142, $0006);                     { 15 et 16 bits }
  SW(U + 144, $0001);                     { SUPPORT_ERRINFO_PDU }
  SL(U + 212, Proto);                     { serverSelectedProtocol }
  K := 216;
  { CS_SECURITY, CS_NET, CS_CLUSTER }
  SW(U + K, $C002); SW(U + K + 2, 12); K := K + 12;
  SW(U + K, $C003); SW(U + K + 2, 8); K := K + 8;
  SW(U + K, $C004); SW(U + K + 2, 12); SL(U + K + 4, $0D); K := K + 12;
  { GCC Conference Create Request (PER) }
  N := 0;
  SB(G, 0); SB(G + 1, 5); SB(G + 2, 0); SB(G + 3, $14); SB(G + 4, $7C);
  SB(G + 5, 0); SB(G + 6, 1);
  SB(G + 7, $80 Or ((K + 14) Shr 8)); SB(G + 8, (K + 14) And 255);
  SB(G + 9, 0); SB(G + 10, 8); SB(G + 11, 0); SB(G + 12, $10);
  SB(G + 13, 0); SB(G + 14, 1); SB(G + 15, $C0); SB(G + 16, 0);
  SB(G + 17, Ord('D')); SB(G + 18, Ord('u')); SB(G + 19, Ord('c'));
  SB(G + 20, Ord('a'));
  SB(G + 21, $80 Or (K Shr 8)); SB(G + 22, K And 255);
  MoveB(U, G + 23, K);
  N := 23 + K;
  { MCS Connect-Initial (BER) }
  L := 0;
  SB(M, 4); SB(M + 1, 1); SB(M + 2, 1);
  SB(M + 3, 4); SB(M + 4, 1); SB(M + 5, 1);
  SB(M + 6, 1); SB(M + 7, 1); SB(M + 8, $FF);
  L := 9;
  L := L + DomParams(34, 2, 0, 1, 0, 1, $FFFF, 2, M + L);
  L := L + DomParams(1, 1, 1, 1, 0, 1, $420, 2, M + L);
  L := L + DomParams($FFFF, $FC17, $FFFF, 1, 0, 1, $FFFF, 2, M + L);
  L := L + BerWrap(4, G, N, M + L);
  L := BerWrap($7F65, M, L, Tx + 7);
  ConnectInitial := SendTpkt(Tx, L);
End;

{ Canal d'E/S d'apres la reponse MCS Connect-Response (donnees GCC) }
Function ConnectResponse(Len : LongInt) : Boolean;
Var P, E, T, L : LongInt;
Begin
  ConnectResponse := False;
  P := Rx + 7; E := Rx + Len;
  While (P < E - 4) And (GL(P) <> $6E44634D) Do Inc(P);   { "McDn" }
  If P >= E - 4 Then
  Begin
    RdpErr := 'R'#233'ponse MCS invalide.';
    Exit;
  End;
  P := P + 4;
  If (GB(P) And $80) <> 0 Then P := P + 2 Else P := P + 1;
  IoChan := 1003;
  While P + 4 <= E Do
  Begin
    T := GW(P); L := GW(P + 2);
    If L < 4 Then Break;
    If T = $0C03 Then IoChan := GW(P + 4);
    P := P + L;
  End;
  ConnectResponse := True;
End;

{ Erect Domain, Attach User, Channel Join (utilisateur et E/S) }
Function McsAttach : Boolean;
Var L, K, Ch : LongInt;
Begin
  McsAttach := False;
  SB(Tx + 7, $04); SB(Tx + 8, 1); SB(Tx + 9, 0); SB(Tx + 10, 1);
  SB(Tx + 11, 0);
  If Not SendTpkt(Tx, 5) Then Exit;
  SB(Tx + 7, $28);
  If Not SendTpkt(Tx, 1) Then Exit;
  If RecvPdu(L) <> 1 Then Exit;
  If (GB(Rx + 7) And $FC) <> $2C Then
  Begin
    RdpErr := 'Attach User refus'#233'.';
    Exit;
  End;
  UserChan := GWB(Rx + 9) + 1001;
  For K := 0 To 1 Do
  Begin
    If K = 0 Then Ch := UserChan Else Ch := IoChan;
    SB(Tx + 7, $38); SWB(Tx + 8, UserChan - 1001); SWB(Tx + 10, Ch);
    If Not SendTpkt(Tx, 5) Then Exit;
    If RecvPdu(L) <> 1 Then Exit;
    If ((GB(Rx + 7) And $FC) <> $3C) Or (GB(Rx + 8) <> 0) Then
    Begin
      RdpErr := 'Channel Join refus'#233'.';
      Exit;
    End;
  End;
  McsAttach := True;
End;

{ Client Info PDU (utilisateur, domaine, mot de passe, performances) }
Function SendClientInfo : Boolean;
Var P, K, N : LongInt; S : String;
Begin
  P := Tx + 15;
  SW(P, $40); SW(P + 2, 0);              { SEC_INFO_PKT }
  K := P + 4;
  ZeroB(K, 1200);
  SL(K, 0);
  SL(K + 4, $1 Or $2 Or $8 Or $10 Or $20 Or $40 Or $100 Or $20000 Or
            $80000);
  SW(K + 8, Length(RdpDom) * 2); SW(K + 10, Length(RdpUser) * 2);
  SW(K + 12, Length(RdpPass) * 2); SW(K + 14, 0); SW(K + 16, 0);
  N := K + 18;
  N := N + Uni16(N, RdpDom) + 2;
  N := N + Uni16(N, RdpUser) + 2;
  N := N + Uni16(N, RdpPass) + 2;
  N := N + 2 + 2;                         { shell et dossier vides }
  { informations etendues }
  S := '0.0.0.0';
  SW(N, 2); SW(N + 2, Length(S) * 2 + 2); N := N + 4;
  N := N + Uni16(N, S) + 2;
  S := 'C:\WINDOWS\MSTSC.EXE';
  SW(N, Length(S) * 2 + 2); N := N + 2;
  N := N + Uni16(N, S) + 2;
  N := N + 172;                           { fuseau horaire }
  SL(N, 0); SL(N + 4, $6F); SW(N + 8, 0);
  N := N + 10;
  SendClientInfo := SendMcs(Tx, IoChan, N - P);
End;

{ ---- activation : Confirm Active et capacites ---- }

Var
  CapP, CapN : LongInt;

Function Cap(Typ, Len : LongInt) : LongInt;
Begin
  SW(CapP, Typ); SW(CapP + 2, Len);
  ZeroB(CapP + 4, Len - 4);
  Cap := CapP + 4;
  CapP := CapP + Len;
  Inc(CapN);
End;

Function SendConfirmActive : Boolean;
Var P, C, Caps, Tot : LongInt;
Begin
  P := Tx + 15;
  SL(P + 6, ShareId);
  SW(P + 10, $03EA);
  SW(P + 12, 6);
  SB(P + 16, Ord('M')); SB(P + 17, Ord('S')); SB(P + 18, Ord('T'));
  SB(P + 19, Ord('S')); SB(P + 20, Ord('C')); SB(P + 21, 0);
  Caps := P + 22;
  CapP := Caps + 4; CapN := 0;
  C := Cap(1, 24);                        { General }
  SW(C, 1); SW(C + 2, 3); SW(C + 4, $200);
  SW(C + 10, $0001 Or $0004 Or $0400);    { fast-path, sans en-tete }
  SB(C + 18, 1); SB(C + 19, 1);
  C := Cap(2, 28);                        { Bitmap }
  SW(C, 16); SW(C + 2, 1); SW(C + 4, 1); SW(C + 6, 1);
  SW(C + 8, FbW); SW(C + 10, FbH);
  SW(C + 14, 1); SW(C + 16, 1); SW(C + 20, 1);
  C := Cap(3, 88);                        { Order : aucun ordre }
  SW(C + 20, 1); SW(C + 22, 20); SW(C + 26, 1);
  SW(C + 30, $2A);
  C := Cap(4, 40);                        { BitmapCache }
  C := Cap(5, 12);                        { Control }
  SW(C + 4, 2); SW(C + 6, 2);
  C := Cap(7, 12);                        { Activation }
  C := Cap(8, 10);                        { Pointer }
  SW(C, 1); SW(C + 2, 20); SW(C + 4, 20);
  C := Cap(9, 8);                         { Share }
  C := Cap(10, 8);                        { ColorCache }
  SW(C, 6);
  C := Cap(12, 8);                        { Sound }
  C := Cap(13, 88);                       { Input }
  SW(C, $0001 Or $0004 Or $0010 Or $0020);
  SL(C + 4, KbdLay); SL(C + 8, 4); SL(C + 12, 0); SL(C + 16, 12);
  C := Cap(14, 8);                        { Font }
  SW(C, 1);
  C := Cap(15, 8);                        { Brush }
  C := Cap(16, 52);                       { GlyphCache }
  C := Cap(17, 12);                       { OffscreenCache }
  C := Cap(20, 12);                       { VirtualChannel }
  SL(C + 4, 1600);
  SW(Caps, CapN); SW(Caps + 2, 0);
  SW(P + 14, CapP - Caps);
  Tot := CapP - P;
  SW(P, Tot); SW(P + 2, $13); SW(P + 4, UserChan);
  SendConfirmActive := SendMcs(Tx, IoChan, Tot);
End;

{ Synchronize, Control (Cooperate, Request Control), Font List }
Function SendFinalize : Boolean;
Var P : LongInt;
Begin
  SendFinalize := False;
  P := Tx + 33;
  SW(P, 1); SW(P + 2, SrvChan);
  If Not SendData(31, 4) Then Exit;
  SW(P, 4); SW(P + 2, 0); SL(P + 4, 0);
  If Not SendData(20, 8) Then Exit;
  SW(P, 1); SW(P + 2, 0); SL(P + 4, 0);
  If Not SendData(20, 8) Then Exit;
  SW(P, 0); SW(P + 2, 0); SW(P + 4, 3); SW(P + 6, $32);
  SendFinalize := SendData(39, 8);
End;

{ Demand Active : partage, taille de l'ecran distant }
Procedure DemandActive(A, N : LongInt);
Var P, E, Nc, I, T, L, W, H, Ls, Lc : LongInt;
Begin
  SrvChan := GW(A + 4);
  ShareId := GL(A + 6);
  Ls := GW(A + 10); Lc := GW(A + 12);
  P := A + 14 + Ls;
  Nc := GW(P); P := P + 4;
  E := A + N;
  W := FbW; H := FbH;
  For I := 1 To Nc Do
  Begin
    If P + 4 > E Then Break;
    T := GW(P); L := GW(P + 2);
    If L < 4 Then Break;
    If T = 2 Then
    Begin
      W := GW(P + 12); H := GW(P + 14);
    End;
    P := P + L;
  End;
  If (W <> FbW) Or (H <> FbH) Or (Fb = 0) Then
  Begin
    { image de 24 bits par point, de bas en haut (bitmap d'OS/2) ; la
      fenetre de la session la lit sous le meme verrou }
    Dummy := DosRequestMutexSem(FbSem, -1);
    FbW := W; FbH := H;
    FbPitch := (FbW * 3 + 3) And Not 3;
    Fb := NewMem(FbPitch * FbH + 64);
    Bmi[0] := 16; Bmi[1] := FbW; Bmi[2] := FbH;
    Bmi[3] := 1 Or (24 Shl 16);           { 1 plan, 24 bits }
    Dummy := DosReleaseMutexSem(FbSem);
    If FirstAct Then Dummy := WinPostMsg(DlgWnd, WM_RDPACTIVE, 1, 0);
  End;
  If SendConfirmActive Then
    If SendFinalize Then
    Begin
      Active := True;
      If Not FirstAct Then
      Begin
        FirstAct := True;
        Dummy := WinPostMsg(DlgWnd, WM_RDPACTIVE, 0, 0);
      End;
    End;
End;

{ ---- bitmaps ---- }

Procedure Dirty(L, T, R, B : LongInt);
Begin
  If DirtyR <= DirtyL Then
  Begin
    DirtyL := L; DirtyT := T; DirtyR := R; DirtyB := B;
  End
  Else
  Begin
    DirtyL := MinI(DirtyL, L); DirtyT := MinI(DirtyT, T);
    DirtyR := MaxI(DirtyR, R); DirtyB := MaxI(DirtyB, B);
  End;
End;

{ zone changee remise a l'interface (WM_RDPDIRTY : un seul message en
  attente, les zones suivantes s'y ajoutent) }
Procedure FlushDirty;
Begin
  If DirtyR <= DirtyL Then Exit;
  Dummy := DosRequestMutexSem(FbSem, -1);
  If PendR <= PendL Then
  Begin
    PendL := DirtyL; PendT := DirtyT; PendR := DirtyR; PendB := DirtyB;
  End
  Else
  Begin
    PendL := MinI(PendL, DirtyL); PendT := MinI(PendT, DirtyT);
    PendR := MaxI(PendR, DirtyR); PendB := MaxI(PendB, DirtyB);
  End;
  DirtyR := DirtyL;
  If (Not PendPosted) And (SessWnd <> 0) Then
    If WinPostMsg(SessWnd, WM_RDPDIRTY, 0, 0) <> 0 Then PendPosted := True;
  Dummy := DosReleaseMutexSem(FbSem);
End;

Function RdPx(A, Bp : LongInt) : LongInt;
Begin
  Case Bp Of
    1 : RdPx := GB(A);
    2 : RdPx := GW(A);
  Else
    RdPx := GW(A) Or (GB(A + 2) Shl 16);
  End;
End;

Procedure WrPx(A, Bp, V : LongInt);
Begin
  Case Bp Of
    1 : SB(A, V);
    2 : SW(A, V);
  Else
    Begin
      SW(A, V); SB(A + 2, V Shr 16);
    End;
  End;
End;

Var
  RlD, RlDE, RlRow, RlFg, RlBp : LongInt;
  RlFirst : Boolean;

Procedure RlPut(V : LongInt);
Begin
  If RlD + RlBp <= RlDE Then WrPx(RlD, RlBp, V);
  RlD := RlD + RlBp;
End;

Function RlAbove : LongInt;
Begin
  RlAbove := RdPx(RlD - RlRow, RlBp);
End;

Procedure RlFgBg(Bits, N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do
  Begin
    If RlFirst Then
    Begin
      If (Bits And (1 Shl I)) <> 0 Then RlPut(RlFg) Else RlPut(0);
    End
    Else If (Bits And (1 Shl I)) <> 0 Then RlPut(RlAbove Xor RlFg)
    Else RlPut(RlAbove);
  End;
End;

{ RLE entrelace (MS-RDPBCGR 2.2.9.1.1.3.1.2.4), Bp octets par point ;
  le resultat (de bas en haut) est dans DecB ; False si invalide }
Function RleDecode(Src, SLen, W, H, Bp : LongInt) : Boolean;
Var S, E, Code, Len, Px, Px2, Mask, K, Adv, White, B0 : LongInt;
    InsFg : Boolean;

Begin
  RleDecode := False;
  RlBp := Bp;
  S := Src; E := Src + SLen; RlD := DecB; RlRow := W * Bp; RlDE := DecB + RlRow * H;
  RlFg := $FFFFFF; If Bp = 2 Then RlFg := $FFFF; If Bp = 1 Then RlFg := $FF;
  White := RlFg;
  RlFirst := True; InsFg := False;
  While (S < E) And (RlD < RlDE) Do
  Begin
    If RlFirst And (RlD - DecB >= RlRow) Then
    Begin
      RlFirst := False; InsFg := False;
    End;
    B0 := GB(S);
    If (B0 And $F0) = $F0 Then Code := B0
    Else
    Begin
      Code := B0 Shr 5;
      If Code > 4 Then Code := B0 Shr 4;
    End;
    { longueur }
    Adv := 1;
    Case Code Of
      0, 1, 3, 4 :
      Begin
        Len := B0 And $1F;
        If Len = 0 Then Begin Len := GB(S + 1) + 32; Adv := 2; End;
      End;
      2 :
      Begin
        Len := B0 And $1F;
        If Len = 0 Then Begin Len := GB(S + 1) + 1; Adv := 2; End
        Else Len := Len * 8;
      End;
      $C, $E :
      Begin
        Len := B0 And $0F;
        If Len = 0 Then Begin Len := GB(S + 1) + 16; Adv := 2; End;
      End;
      $RlD :
      Begin
        Len := B0 And $0F;
        If Len = 0 Then Begin Len := GB(S + 1) + 1; Adv := 2; End
        Else Len := Len * 8;
      End;
      $F0, $F1, $F2, $F3, $F4, $F6, $F7, $F8 :
      Begin
        Len := GW(S + 1); Adv := 3;
      End;
    Else
      Begin
        Len := 0; Adv := 1;
      End;
    End;
    S := S + Adv;
    { fond (copie de la ligne precedente) }
    If (Code = 0) Or (Code = $F0) Then
    Begin
      If RlFirst Then
      Begin
        If InsFg Then Begin RlPut(RlFg); Dec(Len); End;
        While Len > 0 Do Begin RlPut(0); Dec(Len); End;
      End
      Else
      Begin
        If InsFg Then Begin RlPut(RlAbove Xor RlFg); Dec(Len); End;
        While Len > 0 Do Begin RlPut(RlAbove); Dec(Len); End;
      End;
      InsFg := True;
      Continue;
    End;
    InsFg := False;
    Case Code Of
      1, $F1, $C, $F6 :
      Begin
        If (Code = $C) Or (Code = $F6) Then
        Begin
          RlFg := RdPx(S, Bp); S := S + Bp;
        End;
        While Len > 0 Do
        Begin
          If RlFirst Then RlPut(RlFg) Else RlPut(RlAbove Xor RlFg);
          Dec(Len);
        End;
      End;
      $E, $F8 :
      Begin
        Px := RdPx(S, Bp); Px2 := RdPx(S + Bp, Bp); S := S + 2 * Bp;
        While Len > 0 Do
        Begin
          RlPut(Px); RlPut(Px2); Dec(Len);
        End;
      End;
      3, $F3 :
      Begin
        Px := RdPx(S, Bp); S := S + Bp;
        While Len > 0 Do Begin RlPut(Px); Dec(Len); End;
      End;
      2, $F2, $RlD, $F7 :
      Begin
        If (Code = $RlD) Or (Code = $F7) Then
        Begin
          RlFg := RdPx(S, Bp); S := S + Bp;
        End;
        While Len > 8 Do
        Begin
          Mask := GB(S); Inc(S);
          RlFgBg(Mask, 8);
          Len := Len - 8;
        End;
        If Len > 0 Then
        Begin
          Mask := GB(S); Inc(S);
          RlFgBg(Mask, Len);
        End;
      End;
      4, $F4 :
      Begin
        K := Len * Bp;
        If RlD + K <= RlDE Then MoveB(S, RlD, K);
        RlD := RlD + K; S := S + K;
      End;
      $F9 : RlFgBg($03, 8);
      $FA : RlFgBg($05, 8);
      $FD : RlPut(White);
      $FE : RlPut(0);
    Else
      Exit;
    End;
  End;
  RleDecode := True;
End;

{ Point (format Bpp) -> RVB ($RRVVBB) }
Function ToRgb(V, Bpp : LongInt) : LongInt;
Var R, G, B : LongInt;
Begin
  Case Bpp Of
    16 :
      Begin
        R := (V Shr 11) And $1F; G := (V Shr 5) And $3F; B := V And $1F;
        ToRgb := (((R Shl 3) Or (R Shr 2)) Shl 16) Or (((G Shl 2) Or (G Shr 4)) Shl 8) Or
                 ((B Shl 3) Or (B Shr 2));
      End;
    15 :
      Begin
        R := (V Shr 10) And $1F; G := (V Shr 5) And $1F; B := V And $1F;
        ToRgb := (((R Shl 3) Or (R Shr 2)) Shl 16) Or (((G Shl 3) Or (G Shr 2)) Shl 8) Or
                 ((B Shl 3) Or (B Shr 2));
      End;
    8 : ToRgb := PalRgb[V And 255];
  Else
    ToRgb := V And $FFFFFF;
  End;
End;

{ Rectangle decode (W x H, de bas en haut, en A) -> Fb en (L, T)..(R, B) ;
  Fb est de bas en haut, en 24 bits (bleu, vert, rouge) }
Procedure Blit(A, W, H, Bpp, L, T, R, B : LongInt);
Var Y, X, Bp, Sr, Dr, Cx, V, C : LongInt;
Begin
  Bp := (Bpp + 7) Div 8;
  If R >= FbW Then R := FbW - 1;
  If B >= FbH Then B := FbH - 1;
  Cx := R - L + 1;
  If Cx > W Then Cx := W;
  For Y := 0 To B - T Do
  Begin
    If Y >= H Then Break;
    Sr := A + (H - 1 - Y) * W * Bp;
    Dr := Fb + (FbH - 1 - T - Y) * FbPitch + L * 3;
    If Bpp = 24 Then MoveB(Sr, Dr, Cx * 3)
    Else
      For X := 0 To Cx - 1 Do
      Begin
        If Bp = 4 Then V := GL(Sr + X * 4) And $FFFFFF
        Else V := RdPx(Sr + X * Bp, Bp);
        C := ToRgb(V, Bpp);
        PByt(Dr)^ := C And 255; PByt(Dr + 1)^ := (C Shr 8) And 255; PByt(Dr + 2)^ := (C Shr 16) And 255;
        Dr := Dr + 3;
      End;
  End;
  Dirty(L, T, R + 1, B + 1);
End;

{ TS_UPDATE_BITMAP_DATA (updateType, numberRectangles, rectangles) }
Procedure BitmapUpdate(A, N : LongInt);
Var P, E, I, Cnt, L, T, R, B, W, H, Bpp, Fl, Len, D, DL : LongInt;
Begin
  If Fb = 0 Then Exit;
  Cnt := GW(A + 2); P := A + 4; E := A + N;
  For I := 1 To Cnt Do
  Begin
    If P + 18 > E Then Break;
    L := GW(P); T := GW(P + 2); R := GW(P + 4); B := GW(P + 6);
    W := GW(P + 8); H := GW(P + 10); Bpp := GW(P + 12); Fl := GW(P + 14);
    Len := GW(P + 16);
    P := P + 18;
    D := P; DL := Len;
    If (W > 0) And (H > 0) And (W * H <= 1048576) And (L < FbW) And
       (T < FbH) Then
    Begin
      If (Fl And 1) <> 0 Then
      Begin
        If (Fl And $400) = 0 Then
        Begin
          D := D + 8; DL := DL - 8;
        End;
        If RleDecode(D, DL, W, H, (Bpp + 7) Div 8) Then
          Blit(DecB, W, H, Bpp, L, T, R, B);
      End
      Else Blit(D, W, H, Bpp, L, T, R, B);
    End;
    P := P + Len;
  End;
  FlushDirty;
End;

Procedure PaletteUpdate(A, N : LongInt);
Var I, C, P : LongInt;
Begin
  C := GL(A + 4);
  If C > 256 Then C := 256;
  For I := 0 To C - 1 Do
  Begin
    P := A + 8 + I * 3;
    PalRgb[I] := (GB(P) Shl 16) Or (GB(P + 1) Shl 8) Or GB(P + 2);
  End;
End;

{ ---- PDU recues ---- }

{ Chemin rapide : mises a jour (fragments reassembles) }
Procedure FastPath(Len : LongInt);
Var P, E, H, Code, Fr, Sz, Cf : LongInt;
Begin
  P := Rx + 2;
  If (GB(Rx + 1) And $80) <> 0 Then P := Rx + 3;
  E := Rx + Len;
  While P + 3 <= E Do
  Begin
    H := GB(P); Inc(P);
    Code := H And $0F; Fr := (H Shr 4) And 3;
    Cf := 0;
    If ((H Shr 6) And 3) = 2 Then
    Begin
      Cf := GB(P); Inc(P);
    End;
    Sz := GW(P); P := P + 2;
    If P + Sz > E Then Break;
    If (Cf And $20) = 0 Then
    Begin
      If Fr = 0 Then
      Begin
        If Code = 1 Then BitmapUpdate(P, Sz)
        Else If Code = 2 Then PaletteUpdate(P, Sz);
      End
      Else
      Begin
        If Fr = 2 Then FragLen := 0;
        If FragLen + Sz <= 4194304 Then
        Begin
          MoveB(P, Frag + FragLen, Sz);
          FragLen := FragLen + Sz;
        End;
        If Fr = 1 Then
        Begin
          If Code = 1 Then BitmapUpdate(Frag, FragLen)
          Else If Code = 2 Then PaletteUpdate(Frag, FragLen);
          FragLen := 0;
        End;
      End;
    End;
    P := P + Sz;
  End;
End;

{ Client New License Request (reponse a LICENSE_REQUEST) : sans cle
  RSA du serveur, le secret est un alea ; les serveurs sans gestionnaire
  de licences (xrdp, Windows en mode administration) l'acceptent }
Procedure SendLicenseRequest(A, N : LongInt);
Var P, K, L : LongInt; S : String;
Begin
  P := Tx + 15;
  SW(P, $80); SW(P + 2, 0);
  SB(P + 4, $13); SB(P + 5, $83);
  K := P + 8;
  SL(K, 1); SL(K + 4, $04010000);
  TlRandom(K + 8, 32);
  K := K + 40;
  SW(K, 2); SW(K + 2, 72); TlRandom(K + 4, 64); ZeroB(K + 68, 8);
  K := K + 76;
  S := Copy(RdpUser, 1, 60);
  SW(K, $0F); SW(K + 2, Length(S) + 1);
  For L := 1 To Length(S) Do SB(K + 3 + L, Ord(S[L]));
  SB(K + 4 + Length(S), 0);
  K := K + 5 + Length(S);
  S := 'OS2-0';
  SW(K, $10); SW(K + 2, Length(S) + 1);
  For L := 1 To Length(S) Do SB(K + 3 + L, Ord(S[L]));
  SB(K + 4 + Length(S), 0);
  K := K + 5 + Length(S);
  SW(P + 6, K - P - 4);
  Dummy := Ord(SendMcs(Tx, IoChan, K - P));
End;

{ PDU sur le canal d'E/S (A : en-tete de partage ou de securite) ;
  False : fin de la session }
Function SlowPdu(A, N : LongInt) : Boolean;
Var Typ, T2, P, Er : LongInt;
Begin
  SlowPdu := True;
  If N < 4 Then Exit;
  { licence : en-tete de securite SEC_LICENSE_PKT (le premier mot d'une
    PDU de partage est sa longueur) }
  If (GW(A) <> N) And (GW(A) <> $8000) And ((GW(A) And $80) <> 0) Then
  Begin
    Case GB(A + 4) Of
      $FF :                               { ERROR_ALERT }
        If (GL(A + 8) = 7) Or (GL(A + 8) = 0) Then Licensed := True
        Else
        Begin
          RdpErr := 'Erreur de licence du serveur (code ' + IStr(GL(A + 8)) + ').';
          SlowPdu := False;
        End;
      1 : SendLicenseRequest(A + 8, N - 8);   { LICENSE_REQUEST }
      2 :                                 { PLATFORM_CHALLENGE }
      Begin
        RdpErr := 'Le serveur exige une licence d''acc'#232's client (CAL) ' +
                  'des services Bureau '#224' distance, qu''OS/2-0 ne sait pas encore ' +
                  'obtenir. Les deux sessions d''administration de Windows ' +
                  'Server n''en demandent pas.';
        SlowPdu := False;
      End;
      3, 4 : Licensed := True;            { NEW_LICENSE, UPGRADE_LICENSE }
    End;
    Exit;
  End;
  If GW(A) = $8000 Then Exit;             { controle de flux }
  Typ := GW(A + 2) And $0F;
  Case Typ Of
    1 : DemandActive(A, N);
    6 : Active := False;                  { Deactivate All }
    7 :
    Begin
      T2 := GB(A + 14);
      P := A + 18;
      If GB(A + 15) <> 0 Then Exit;       { compresse : non demande }
      Case T2 Of
        2 :
          If GW(P) = 1 Then BitmapUpdate(P, N - 18)
          Else If GW(P) = 2 Then PaletteUpdate(P, N - 18);
        47 :
        Begin
          Er := GL(P);
          If Er <> 0 Then ErrInfo := Er;
        End;
        36 :                              { Shutdown Denied }
          ;
      End;
    End;
  End;
End;

{ ---- entrees (chemin rapide, depuis la fenetre) ---- }

Function SendInput(N, Cnt : LongInt) : Boolean;
Begin
  SendInput := False;
  If Not Active Then Exit;
  { en-tete : action 0, nombre d'evenements ; longueur sur 1 ou 2 octets }
  SB(InB, Cnt Shl 2);
  If N + 2 < 128 Then
  Begin
    SB(InB + 1, N + 2);
    MoveB(InB + 8, InB + 2, N);
    SendInput := SendRaw(InB, N + 2);
  End
  Else
  Begin
    SB(InB + 1, $80 Or ((N + 3) Shr 8)); SB(InB + 2, (N + 3) And 255);
    MoveB(InB + 8, InB + 3, N);
    SendInput := SendRaw(InB, N + 3);
  End;
End;

Procedure SendKey(Sc : LongInt; Ext, Up : Boolean);
Var F : LongInt;
Begin
  F := 0;
  If Up Then F := F Or 1;
  If Ext Then F := F Or 2;
  SB(InB + 8, F); SB(InB + 9, Sc);
  Dummy := Ord(SendInput(2, 1));
End;

Procedure SendMouse(Fl, X, Y : LongInt);
Begin
  SB(InB + 8, 1 Shl 5);
  SW(InB + 9, Fl); SW(InB + 11, X); SW(InB + 13, Y);
  Dummy := Ord(SendInput(7, 1));
End;

Procedure SendSync(Fl : LongInt);
Begin
  SB(InB + 8, (3 Shl 5) Or (Fl And $1F));
  Dummy := Ord(SendInput(1, 1));
End;

{ ---- session (tache de connexion et de reception) ---- }

Function X224Connect(S : LongInt) : Boolean;
Var N, L, P : LongInt; Ck : String;
Begin
  X224Connect := False;
  Ck := 'Cookie: mstshash=' + Copy(RdpUser, 1, 9) + #13#10;
  N := 11 + Length(Ck) + 8;
  SB(Tx, 3); SB(Tx + 1, 0); SWB(Tx + 2, N);
  SB(Tx + 4, N - 5); SB(Tx + 5, $E0);
  SW(Tx + 6, 0); SW(Tx + 8, 0); SB(Tx + 10, 0);
  For L := 1 To Length(Ck) Do SB(Tx + 10 + L, Ord(Ck[L]));
  P := Tx + 11 + Length(Ck);
  SB(P, 1); SB(P + 1, 0); SW(P + 2, 8);
  SL(P + 4, 3);                           { TLS et CredSSP (NLA) }
  If Not SendRaw(Tx, N) Then Exit;
  If RecvPdu(L) <> 1 Then
  Begin
    RdpErr := 'Pas de r'#233'ponse X.224 du serveur.';
    Exit;
  End;
  Proto := 0;
  If L >= 19 Then
  Begin
    If GB(Rx + 11) = 2 Then Proto := GL(Rx + 15)
    Else If GB(Rx + 11) = 3 Then
    Begin
      Case GL(Rx + 15) Of
        2 : RdpErr := 'Le serveur n''accepte que la s'#233'curit'#233' RDP standard ' +
                      '(activez TLS ou NLA sur le serveur).';
        5 : RdpErr := 'Le serveur exige l''authentification NLA.';
      Else
        RdpErr := 'N'#233'gociation de la s'#233'curit'#233' refus'#233'e (code ' +
                  IStr(GL(Rx + 15)) + ').';
      End;
      Exit;
    End;
  End;
  If (Proto <> 1) And (Proto <> 2) Then
  Begin
    RdpErr := 'Le serveur n''accepte que la s'#233'curit'#233' RDP standard, que ' +
              'OS/2-0 ne g'#232're pas (activez TLS ou NLA).';
    Exit;
  End;
  X224Connect := True;
End;

Function RdpSession : Boolean;
Var S, L, K : LongInt; E : String;
Begin
  RdpSession := False;
  Status('Connexion '#224' ' + RdpHost + '...');
  S := TcpOpen(RdpHost, RdpPort, E);
  If S < 0 Then
  Begin
    RdpErr := E;
    Exit;
  End;
  Tc.Sock := S; Tc.Tls := False; Tc.Used := True;
  Tc.Enc := False; Tc.Dec := False; Tc.RPos := 0; Tc.REnd := 0;
  Tc.Eof := False;
  If Not X224Connect(S) Then Exit;
  Status('S'#233'curisation de la connexion (TLS)...');
  Tc.Tls := True;
  If Not TlHandshake(Tc, RdpHost) Then
  Begin
    RdpErr := 'TLS : ' + TlErr;
    Exit;
  End;
  If Proto = 2 Then
  Begin
    Status('Authentification (NLA)...');
    If Not CredSsp Then Exit;
  End;
  Status('Ouverture de la session...');
  If Not ConnectInitial Then Exit;
  K := RecvPdu(L);
  If (K <> 1) Or Not ConnectResponse(L) Then
  Begin
    If RdpErr = '' Then RdpErr := 'Le serveur a refus'#233' la connexion MCS.';
    Exit;
  End;
  If Not McsAttach Then
  Begin
    If RdpErr = '' Then RdpErr := 'Connexion MCS interrompue.';
    Exit;
  End;
  If Not SendClientInfo Then Exit;
  Connected := True;
  Status('Bureau '#224' distance...');
  { reception jusqu'a la fin de la session }
  Repeat
    K := RecvPdu(L);
    If K = 2 Then FastPath(L)
    Else If K = 1 Then
    Begin
      { MCS : Send Data Indication ou Disconnect Provider Ultimatum }
      If (GB(Rx + 7) And $FC) = $20 Then Break;
      If (GB(Rx + 7) And $FC) = $68 Then
      Begin
        If (GB(Rx + 13) And $80) <> 0 Then K := Rx + 15 Else K := Rx + 14;
        If Not SlowPdu(K, Rx + L - K) Then Break;
      End;
    End;
  Until (K = 0) Or NetStop;
  RdpSession := True;
End;

{ tache : session complete puis message de fin a la boite }

{ tache : session complete puis message de fin a la boite }
Function RdpThread(P : LongInt) : LongInt;
Begin
  RdpThread := 0;
  RdpErr := ''; ErrInfo := 0;
  Dummy := Ord(RdpSession);
  If Tc.Sock >= 0 Then TlSockClose(Tc.Sock);
  Tc.Sock := -1;
  Active := False;
  Dummy := WinPostMsg(DlgWnd, WM_RDPEND, 0, 0);
End;

{ ---- aleas ---- }

Function Rdtsc : LongInt;
Var V : LongInt;
Begin
  V := 0;
  asm
    db 0Fh, 31h
    mov V,eax
  end;
  Rdtsc := V;
End;

Procedure TlEntropy;
Var Q : Array[0..1] Of LongInt; Pt : Array[0..1] Of LongInt; Dt : Array[0..3] Of LongInt;
Begin
  TlSeed(Rdtsc); TlSeed(MsCount);
  Dt[0] := 0; Dt[1] := 0; Dt[2] := 0;
  Dummy := DosGetDateTime(LongInt(@Dt[0]));
  TlSeed(Dt[0]); TlSeed(Dt[1]); TlSeed(Dt[2]);
  Pt[0] := 0; Pt[1] := 0;
  Dummy := WinQueryPointerPos(HWND_DESKTOP, LongInt(@Pt[0]));
  TlSeed(Pt[0] * 65536 + Pt[1]);
  TlSeed(LongInt(@Q[0]));
  TlSeed(Rdtsc);
End;

{ ==================================================================== }
{ Interface : boite Connexion Bureau a distance et fenetre de session   }
{ ==================================================================== }

Const
  SbW = 16;

Var
  DlgFr, SessFr : LongInt;
  EHost, EUser, EPass, EDom, LSize, SStat, BConn, BQuit, HSb, VSb : LongInt;
  FullScr, Busy : Boolean;
  SessCW, SessCH, SessBase, ScrW, ScrH : LongInt;
  QuitBuf : Array[0..15] Of Byte;
  TabCtl : Array[0..7] Of LongInt;
  TabN : LongInt;
  PaintH : LongInt;
  MnTpl : Array[0..1023] Of Byte;
  MnLen, MnCnt, MnSubHdr, MnSubOuter : LongInt;

{ ---- dessin (GPI en couleurs RVB ; Y : haut de la zone, vers le bas) ---- }

Procedure Bar(Hps, X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := PaintH - Y2;
  Dummy := GpiMove(Hps, LongInt(@P[0]));
  P[0] := X2 - 1; P[1] := PaintH - Y1 - 1;
  Dummy := GpiBox(Hps, 3, LongInt(@P[0]), 0, 0);
End;

{ rectangle plein en coordonnees de PM (bas a gauche), X2, Y2 exclus }
Procedure BarPm(Hps, X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If (X2 <= X1) Or (Y2 <= Y1) Then Exit;
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P[0]));
  P[0] := X2 - 1; P[1] := Y2 - 1;
  Dummy := GpiBox(Hps, 3, LongInt(@P[0]), 0, 0);
End;

Procedure Txt(Hps, X, Y : LongInt; S : String; Fg : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), Disp(S));
  Dummy := GpiSetColor(Hps, Fg);
  P[0] := X; P[1] := PaintH - Y - 12;
  Dummy := GpiCharStringAt(Hps, LongInt(@P[0]), Length(S), LongInt(@TxtBuf));
End;

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Var Ow : LongInt;
Begin
  Ow := DlgFr;
  If (SessFr <> 0) And Busy Then Ow := SessFr;
  Ask := WinMessageBox(HWND_DESKTOP, Ow, Z(Disp(Text)), Z2(Disp(Cap)), 0, Fl Or MB_MOVEABLE);
End;

{ ---- controles ---- }

Function Ctl(P, Cls : LongInt; T : String; Style, X, Y, W, H, Id : LongInt) : LongInt;
Var C : LongInt;
Begin
  C := WinCreateWindow(P, Cls, Z(Disp(T)), WS_VISIBLE Or Style, X, Y, W, H, P, HWND_TOP, Id, 0, 0);
  If ((Style And WS_TABSTOP) <> 0) And (TabN < 8) And (C <> 0) Then
  Begin
    TabCtl[TabN] := C;
    Inc(TabN);
  End;
  Ctl := C;
End;

{ fond gris d'OS/2 (CLR_PALEGRAY) pour les textes fixes }
Procedure Gray(H : LongInt);
Var C : LongInt;
Begin
  C := 15;
  Dummy := WinSetPresParam(H, 4, 4, LongInt(@C));
End;

Function CtlText(H : LongInt) : String;
Var N : LongInt;
Begin
  ZeroB(LongInt(@TxtBuf), 260);
  N := WinQueryWindowText(H, 255, LongInt(@TxtBuf));
  If N < 0 Then N := 0;
  CtlText := UnDisp(GetZ(LongInt(@TxtBuf)));
End;

Procedure SetText(H : LongInt; S : String);
Begin
  Dummy := WinSetWindowText(H, Z(Disp(S)));
End;

{ Tab et Maj+Tab : controle suivant ou precedent de la boite }
Procedure TabNext(Dir : LongInt);
Var F, I, K, N : LongInt;
Begin
  If TabN = 0 Then Exit;
  F := WinQueryFocus(HWND_DESKTOP);
  K := -1;
  { le focus peut etre sur un enfant du controle (champ de la liste
    deroulante) : on remonte les parents }
  N := 0;
  While (K < 0) And (F <> 0) And (F <> 1) And (N < 4) Do
  Begin
    For I := 0 To TabN - 1 Do If TabCtl[I] = F Then K := I;
    If K < 0 Then F := WinQueryWindow(F, 5);
    Inc(N);
  End;
  If K < 0 Then K := 0 Else K := (K + Dir + TabN) Mod TabN;
  N := 0;
  While (N < TabN) And Busy And (TabCtl[K] <> BQuit) Do
  Begin
    K := (K + Dir + TabN) Mod TabN;
    Inc(N);
  End;
  Dummy := WinSetFocus(HWND_DESKTOP, TabCtl[K]);
  If (TabCtl[K] = EHost) Or (TabCtl[K] = EUser) Or (TabCtl[K] = EPass) Or (TabCtl[K] = EDom) Then
    Dummy := WinSendMsg(TabCtl[K], EM_SETSEL, 255 Shl 16, 0);
End;

{ ---- menus (gabarits de PM : MENUTEMPLATE) ---- }

Procedure MStart;
Begin
  MnLen := 6; MnCnt := 0;
End;

Procedure MAdd(Id : LongInt; S : String);
Begin
  S := Disp(S);
  If Id = 0 Then SW(LongInt(@MnTpl) + MnLen, MIS_SEPARATOR) Else SW(LongInt(@MnTpl) + MnLen, MIS_TEXT);
  SW(LongInt(@MnTpl) + MnLen + 2, 0);
  SW(LongInt(@MnTpl) + MnLen + 4, Id);
  MnLen := MnLen + 6;
  If Id <> 0 Then
  Begin
    PutZ(LongInt(@MnTpl) + MnLen, S);
    MnLen := MnLen + Length(S) + 1;
  End;
  Inc(MnCnt);
End;

Procedure MSubBegin(Id : LongInt; S : String);
Begin
  S := Disp(S);
  SW(LongInt(@MnTpl) + MnLen, MIS_TEXT Or MIS_SUBMENU);
  SW(LongInt(@MnTpl) + MnLen + 2, 0);
  SW(LongInt(@MnTpl) + MnLen + 4, Id);
  MnLen := MnLen + 6;
  PutZ(LongInt(@MnTpl) + MnLen, S);
  MnLen := MnLen + Length(S) + 1;
  MnSubOuter := MnCnt + 1;
  MnSubHdr := MnLen;
  MnLen := MnLen + 6;
  MnCnt := 0;
End;

Procedure MSubEnd;
Begin
  SW(LongInt(@MnTpl) + MnSubHdr, MnLen - MnSubHdr);
  SW(LongInt(@MnTpl) + MnSubHdr + 2, 0);
  SW(LongInt(@MnTpl) + MnSubHdr + 4, MnCnt);
  MnCnt := MnSubOuter;
End;

Function MDone(Frame : LongInt) : LongInt;
Begin
  SW(LongInt(@MnTpl), MnLen); SW(LongInt(@MnTpl) + 2, 0); SW(LongInt(@MnTpl) + 4, MnCnt);
  MDone := WinCreateMenu(Frame, LongInt(@MnTpl));
End;

{ ---- OS2.INI : dernier ordinateur et utilisateur (comme mstsc) ---- }

Function IniRead(Key : String) : String;
Var B : Array[0..299] Of Byte;
Begin
  B[0] := 0;
  Dummy := PrfQueryProfileString(-1, Z(IniApp), Z2(Key), 0, LongInt(@B), 290);
  IniRead := GetZ(LongInt(@B));
End;

Procedure IniWrite(Key, V : String);
Var B : Array[0..299] Of Byte;
Begin
  PutZ(LongInt(@B), V);
  If V = '' Then Dummy := PrfWriteProfileString(-1, Z(IniApp), Z2(Key), 0)
  Else Dummy := PrfWriteProfileString(-1, Z(IniApp), Z2(Key), LongInt(@B));
End;

{ ---- fenetre de session ---- }

{ barres de defilement (WC_SCROLLBAR) quand l'ecran distant depasse la
  fenetre ; SessCW, SessCH : zone visible ; SessBase : hauteur de la
  barre horizontale (bas de la zone visible) }
Procedure SetScrolls;
Var Rc : Array[0..3] Of LongInt; CW, CH : LongInt; NH, NV : Boolean;
Begin
  If SessWnd = 0 Then Exit;
  Rc[2] := 0; Rc[3] := 0;
  Dummy := WinQueryWindowRect(SessWnd, LongInt(@Rc));
  CW := Rc[2]; CH := Rc[3];
  If (CW <= 0) Or (CH <= 0) Then Exit;
  NH := FbW > CW; NV := FbH > CH;
  If NH Then CH := CH - SbW;
  If NV Then CW := CW - SbW;
  If Not NH And (FbW > CW) Then
  Begin
    NH := True; CH := CH - SbW;
  End;
  If FullScr Then
  Begin
    NH := False; NV := False; CW := Rc[2]; CH := Rc[3];
  End;
  SessCW := CW; SessCH := CH;
  If NH Then SessBase := SbW Else SessBase := 0;
  If ViewX > FbW - SessCW Then ViewX := MaxI(0, FbW - SessCW);
  If ViewY > FbH - SessCH Then ViewY := MaxI(0, FbH - SessCH);
  If NH Then
  Begin
    If HSb = 0 Then
      HSb := WinCreateWindow(SessWnd, WC_SCROLLBAR, 0, WS_VISIBLE Or SBS_HORZ, 0, 0, CW, SbW, SessWnd,
                             HWND_TOP, 30, 0, 0)
    Else Dummy := WinSetWindowPos(HSb, 0, 0, 0, CW, SbW, SWP_MOVE Or SWP_SIZE Or SWP_SHOW);
    Dummy := WinSendMsg(HSb, SBM_SETSCROLLBAR, ViewX, Mk2(0, FbW - SessCW));
    Dummy := WinSendMsg(HSb, SBM_SETTHUMBSIZE, Mk2(SessCW, FbW), 0);
  End
  Else If HSb <> 0 Then
  Begin
    Dummy := WinDestroyWindow(HSb); HSb := 0;
  End;
  If NV Then
  Begin
    If VSb = 0 Then
      VSb := WinCreateWindow(SessWnd, WC_SCROLLBAR, 0, WS_VISIBLE Or SBS_VERT, CW, SessBase, SbW, CH, SessWnd,
                             HWND_TOP, 31, 0, 0)
    Else Dummy := WinSetWindowPos(VSb, 0, CW, SessBase, SbW, CH, SWP_MOVE Or SWP_SIZE Or SWP_SHOW);
    Dummy := WinSendMsg(VSb, SBM_SETSCROLLBAR, ViewY, Mk2(0, FbH - SessCH));
    Dummy := WinSendMsg(VSb, SBM_SETTHUMBSIZE, Mk2(SessCH, FbH), 0);
  End
  Else If VSb <> 0 Then
  Begin
    Dummy := WinDestroyWindow(VSb); VSb := 0;
  End;
End;

{ defilement local (barres) : Horz, commande SB_*, position }
Procedure ScrollTo(Horz : Boolean; Code, Pos : LongInt);
Var V, Mx, Pg : LongInt;
Begin
  If Horz Then
  Begin
    V := ViewX; Mx := MaxI(0, FbW - SessCW); Pg := SessCW;
  End
  Else
  Begin
    V := ViewY; Mx := MaxI(0, FbH - SessCH); Pg := SessCH;
  End;
  Case Code Of
    SB_LINEUP : V := V - 16;
    SB_LINEDOWN : V := V + 16;
    SB_PAGEUP : V := V - Pg;
    SB_PAGEDOWN : V := V + Pg;
    SB_SLIDERTRACK, SB_SLIDERPOSITION : V := Pos;
  Else
    Exit;
  End;
  If V > Mx Then V := Mx;
  If V < 0 Then V := 0;
  If Horz Then ViewX := V Else ViewY := V;
  If Horz And (HSb <> 0) Then Dummy := WinSendMsg(HSb, SBM_SETPOS, V, 0);
  If (Not Horz) And (VSb <> 0) Then Dummy := WinSendMsg(VSb, SBM_SETPOS, V, 0);
  Dummy := WinInvalidateRect(SessWnd, 0, 0);
End;

{ dessin de la zone visible : image distante par GpiDrawBits (24 bits),
  noir au-dela de l'ecran distant }
Procedure PaintSession(H : LongInt);
Var Hps, Tx1, Ty1, Tx2, Ty2, Vw, Vh, Oy, Top : LongInt; Rc : Array[0..3] Of LongInt;
    P : Array[0..7] Of LongInt;
Begin
  Rc[0] := 0; Rc[1] := 0; Rc[2] := 0; Rc[3] := 0;
  Hps := WinBeginPaint(H, 0, LongInt(@Rc));
  If Hps = 0 Then Exit;
  Dummy := GpiCreateLogColorTable(Hps, 0, 3, 0, 0, 0);
  If (Rc[2] <= Rc[0]) Or (Rc[3] <= Rc[1]) Then
  Begin
    Rc[0] := 0; Rc[1] := 0; Rc[2] := SessCW; Rc[3] := SessBase + SessCH;
  End;
  Top := SessBase + SessCH;
  Dummy := DosRequestMutexSem(FbSem, -1);
  If Fb = 0 Then BarPm(Hps, 0, SessBase, SessCW, Top, 0)
  Else
  Begin
    Vw := MinI(SessCW, FbW - ViewX);
    Vh := MinI(SessCH, FbH - ViewY);
    Tx1 := MaxI(Rc[0], 0); Tx2 := MinI(Rc[2], Vw);
    Ty1 := MaxI(Rc[1], Top - Vh); Ty2 := MinI(Rc[3], Top);
    If (Tx2 > Tx1) And (Ty2 > Ty1) Then
    Begin
      Oy := FbH - ViewY - Top;
      P[0] := Tx1; P[1] := Ty1; P[2] := Tx2; P[3] := Ty2;
      P[4] := Tx1 + ViewX; P[5] := Ty1 + Oy; P[6] := Tx2 + ViewX; P[7] := Ty2 + Oy;
      Dummy := GpiDrawBits(Hps, Fb, LongInt(@Bmi[0]), 4, LongInt(@P[0]), $CC, 0);
    End;
    If Vw < SessCW Then BarPm(Hps, MaxI(Vw, 0), SessBase, SessCW, Top, 0);
    If Vh < SessCH Then BarPm(Hps, 0, SessBase, SessCW, Top - MaxI(Vh, 0), 0);
  End;
  Dummy := DosReleaseMutexSem(FbSem);
  { coin entre les deux barres }
  If (HSb <> 0) And (VSb <> 0) Then BarPm(Hps, SessCW, 0, SessCW + SbW, SbW, ClrFace);
  Dummy := WinEndPaint(Hps);
End;

{ zone changee (coordonnees distantes) -> rectangle de la fenetre }
Procedure TakeDirty;
Var L, T, R, B : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  Dummy := DosRequestMutexSem(FbSem, -1);
  L := PendL; T := PendT; R := PendR; B := PendB;
  PendR := PendL;
  PendPosted := False;
  Dummy := DosReleaseMutexSem(FbSem);
  If (R <= L) Or (SessWnd = 0) Then Exit;
  Rc[0] := MaxI(0, L - ViewX); Rc[2] := MinI(SessCW, R - ViewX);
  Rc[1] := SessBase + SessCH - (B - ViewY); Rc[3] := SessBase + SessCH - (T - ViewY);
  If Rc[1] < SessBase Then Rc[1] := SessBase;
  If Rc[3] > SessBase + SessCH Then Rc[3] := SessBase + SessCH;
  If (Rc[2] > Rc[0]) And (Rc[3] > Rc[1]) Then Dummy := WinInvalidateRect(SessWnd, LongInt(@Rc), 0);
End;

{ verrouillages (synchronisation : 1 defilement, 2 numerique, 4 majuscules) }
Function LockFlags : LongInt;
Var F : LongInt;
Begin
  F := 0;
  If (WinGetKeyState(HWND_DESKTOP, PVK_SCRLLOCK) And 1) <> 0 Then F := F Or 1;
  If (WinGetKeyState(HWND_DESKTOP, PVK_NUMLOCK) And 1) <> 0 Then F := F Or 2;
  If (WinGetKeyState(HWND_DESKTOP, PVK_CAPSLOCK) And 1) <> 0 Then F := F Or 4;
  LockFlags := F;
End;

{ relacher les touches de modification }
Procedure ReleaseMods;
Begin
  SendKey($1D, False, True); SendKey($38, False, True);
  SendKey($2A, False, True); SendKey($36, False, True);
  SendKey($1D, True, True); SendKey($38, True, True);
End;

{ Ctrl+Alt+Suppr sur l'ordinateur distant }
Procedure SendCad;
Begin
  SendKey($1D, False, False); SendKey($38, False, False);
  SendKey($53, True, False); SendKey($53, True, True);
  SendKey($38, False, True); SendKey($1D, False, True);
End;

{ touche de PM (WM_CHAR) -> code de balayage du clavier PC (jeu 1) et
  indicateur de touche etendue ; 0 si aucun }
Function KeyScan(Fs, Sc, Vk, Ch : LongInt; Var Ext : Boolean) : LongInt;
Var R : LongInt;
Begin
  Ext := False;
  R := 0;
  If (Fs And KC_VIRTUALKEY) <> 0 Then
    Case Vk Of
      PVK_BACKSPACE : R := $0E;
      PVK_TAB, PVK_BACKTAB : R := $0F;
      PVK_NEWLINE : R := $1C;
      PVK_ENTER : Begin R := $1C; Ext := True; End;
      PVK_ESC : R := $01;
      PVK_SPACE : R := $39;
      PVK_CAPSLOCK : R := $3A;
      PVK_NUMLOCK : R := $45;
      PVK_SCRLLOCK : R := $46;
      PVK_PRINTSCRN : Begin R := $37; Ext := True; End;
      PVK_PAGEUP : R := $49;
      PVK_PAGEDOWN : R := $51;
      PVK_END : R := $4F;
      PVK_HOME : R := $47;
      PVK_LEFT : R := $4B;
      PVK_UP : R := $48;
      PVK_RIGHT : R := $4D;
      PVK_DOWN : R := $50;
      PVK_INSERT : R := $52;
      PVK_DELETE : R := $53;
    Else
      If (Vk >= PVK_F1) And (Vk <= PVK_F1 + 9) Then R := $3B + Vk - PVK_F1
      Else If Vk = PVK_F1 + 10 Then R := $57
      Else If Vk = PVK_F1 + 11 Then R := $58;
    End;
  { pave de direction : touches grises (etendues), sauf les chiffres du
    pave numerique (verrouillage numerique) }
  If (R >= $47) And (R <= $53) And (R <> $4A) And (R <> $4E) Then
  Begin
    If ((Ch >= Ord('0')) And (Ch <= Ord('9'))) Or (Ch = Ord('.')) Or (Ch = Ord(',')) Then R := Sc
    Else Ext := True;
  End;
  If R = 0 Then
  Begin
    R := Sc And $7F;
    { Alt+chiffre du BIOS (78h a 83h) -> chiffres de la rangee du haut }
    If (Sc >= $78) And (Sc <= $83) Then R := Sc - $76;
    If (Sc = $E0) Or (Sc = 0) Then R := 0;
  End;
  KeyScan := R;
End;

Procedure MakeSession; Forward;

Procedure Disconnect;
Begin
  { MCS Disconnect Provider Ultimatum ; la tache ferme la connexion }
  QuitBuf[7] := $21; QuitBuf[8] := $80;
  QuitBuf[0] := 3; QuitBuf[1] := 0; QuitBuf[2] := 0; QuitBuf[3] := 9;
  QuitBuf[4] := 2; QuitBuf[5] := $F0; QuitBuf[6] := $80;
  If Active Then Dummy := Ord(SendRaw(LongInt(@QuitBuf[0]), 9));
  NetStop := True;
  Active := False;
End;

Procedure ToggleFull;
Begin
  FullScr := Not FullScr;
  MakeSession;
End;

Function SessProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var X, Y, Fl, Fs, Sc, Vk, Ch : LongInt; Ext, KCtl, KAlt, KSh : Boolean;
Begin
  SessProc := 0;
  Case Msg Of
    WM_PAINT : PaintSession(H);
    WM_ERASEBACKGROUND : SessProc := 0;
    WM_SIZE : SetScrolls;
    WM_RDPDIRTY : TakeDirty;
    WM_HSCROLL :
      Begin
        ScrollTo(True, Hi16(Mp2), S16(Mp2));
        { le clavier reste a la session (pas a la barre de defilement) }
        Dummy := WinSetFocus(HWND_DESKTOP, H);
      End;
    WM_VSCROLL :
      If Lo16(Mp1) = 31 Then
      Begin
        ScrollTo(False, Hi16(Mp2), S16(Mp2));
        Dummy := WinSetFocus(HWND_DESKTOP, H);
      End
      Else
      Begin
        { molette de la souris (WM_VSCROLL sans barre de defilement) :
          rotation de 120 vers le haut ou vers le bas }
        If Hi16(Mp2) = SB_LINEUP Then SendMouse($0200 Or 120, 0, 0)
        Else If Hi16(Mp2) = SB_LINEDOWN Then SendMouse($0200 Or ((-120) And $1FF), 0, 0)
        Else If Hi16(Mp2) = SB_PAGEUP Then SendMouse($0200 Or 120, 0, 0)
        Else If Hi16(Mp2) = SB_PAGEDOWN Then SendMouse($0200 Or ((-120) And $1FF), 0, 0);
      End;
    WM_MOUSEMOVE, WM_BUTTON1DOWN, WM_BUTTON1UP, WM_BUTTON1DBLCLK, WM_BUTTON2DOWN, WM_BUTTON2UP,
    WM_BUTTON2DBLCLK, WM_BUTTON3DOWN, WM_BUTTON3UP, WM_BUTTON3DBLCLK :
      Begin
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        X := MaxI(0, X + ViewX);
        Y := MaxI(0, ViewY + (SessBase + SessCH - 1 - Y));
        If X >= FbW Then X := FbW - 1;
        If Y >= FbH Then Y := FbH - 1;
        Case Msg Of
          WM_MOUSEMOVE : Fl := $0800;
          WM_BUTTON1DOWN, WM_BUTTON1DBLCLK : Fl := $8000 Or $1000;
          WM_BUTTON1UP : Fl := $1000;
          WM_BUTTON2DOWN, WM_BUTTON2DBLCLK : Fl := $8000 Or $2000;
          WM_BUTTON2UP : Fl := $2000;
          WM_BUTTON3DOWN, WM_BUTTON3DBLCLK : Fl := $8000 Or $4000;
        Else
          Fl := $4000;
        End;
        If (Fl And $8000) <> 0 Then
        Begin
          Dummy := WinSetFocus(HWND_DESKTOP, H);
          Dummy := WinSetCapture(HWND_DESKTOP, H);
        End
        Else If Msg <> WM_MOUSEMOVE Then Dummy := WinSetCapture(HWND_DESKTOP, 0);
        If Active Then SendMouse(Fl, X, Y);
        If Msg = WM_MOUSEMOVE Then SessProc := WinDefWindowProc(H, Msg, Mp1, Mp2)
        Else SessProc := 1;
      End;
    WM_CHAR :
      Begin
        Fs := Lo16(Mp1);
        SessProc := 1;
        If (Fs And KC_KEYUP) <> 0 Then Exit;
        Sc := (Mp1 Shr 24) And 255; Vk := Hi16(Mp2); Ch := Lo16(Mp2) And 255;
        If (Fs And KC_VIRTUALKEY) = 0 Then Vk := 0;
        KCtl := (Fs And KC_CTRL) <> 0; KAlt := (Fs And KC_ALT) <> 0; KSh := (Fs And KC_SHIFT) <> 0;
        { Ctrl+Alt+Fin : Ctrl+Alt+Suppr sur l'ordinateur distant ;
          Ctrl+Alt+Pause (comme mstsc) ou Ctrl+Alt+Entree : plein ecran
          ou fenetre }
        If KCtl And KAlt Then
        Begin
          If (Vk = PVK_END) Or (Sc = $4F) Or (Sc = $75) Then
          Begin
            If Active Then SendCad;
            Exit;
          End;
          If (Vk = PVK_NEWLINE) Or (Vk = PVK_ENTER) Or (Vk = PVK_PAUSE) Or (Vk = PVK_BREAK) Then
          Begin
            ToggleFull;
            Exit;
          End;
        End;
        If Not Active Then Exit;
        Sc := KeyScan(Fs, Sc, Vk, Ch, Ext);
        If Sc = 0 Then Exit;
        { PM ne rapporte que les touches enfoncees : Maj, Ctrl et Alt sont
          envoyes autour de chaque touche }
        If KCtl Then SendKey($1D, False, False);
        If KAlt Then SendKey($38, False, False);
        If KSh Then SendKey($2A, False, False);
        SendKey(Sc, Ext, False);
        SendKey(Sc, Ext, True);
        If KSh Then SendKey($2A, False, True);
        If KAlt Then SendKey($38, False, True);
        If KCtl Then SendKey($1D, False, True);
      End;
    WM_COMMAND :
      Case Lo16(Mp1) Of
        ID_CAD : If Active Then SendCad;
        ID_FULL : ToggleFull;
        ID_DISC :
          If Ask('Votre session '#224' distance va '#234'tre d'#233'connect'#233'e.',
                 'Connexion Bureau '#224' distance', MB_OKCANCEL Or MB_ICONINFO) = MBID_OK Then Disconnect;
      End;
    WM_CLOSE :
      If Ask('Votre session '#224' distance va '#234'tre d'#233'connect'#233'e.',
             'Connexion Bureau '#224' distance', MB_OKCANCEL Or MB_ICONINFO) = MBID_OK
      Then Disconnect;
  Else
    SessProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ (re)creer la fenetre de session : plein ecran (sans cadre) ou fenetre
  standard de PM, avec barres de defilement si l'ecran distant est plus
  grand, et menu Session }
Procedure MakeSession;
Var Old, W, H, Fl, Fr, Cl : LongInt; Rc : Array[0..3] Of LongInt; T : String;
Begin
  Old := SessFr;
  ViewX := 0; ViewY := 0;
  HSb := 0; VSb := 0;
  SessWnd := 0;
  T := RdpHost + ' - Connexion Bureau '#224' distance';
  Cl := 0;
  If FullScr Then
  Begin
    Fl := FCF_TASKLIST;
    Fr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('MstscSess'), Z2(Disp(T)), 0, 0, 0, LongInt(@Cl));
    SessCW := ScrW; SessCH := ScrH;
    Dummy := WinSetWindowPos(Fr, HWND_TOP, 0, 0, ScrW, ScrH,
                             SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  End
  Else
  Begin
    Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_SIZEBORDER Or FCF_TASKLIST;
    Fr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('MstscSess'), Z2(Disp(T)), 0, 0, 0, LongInt(@Cl));
    MStart;
    MSubBegin(300, 'Session');
    MAdd(ID_CAD, 'Envoyer Ctrl+Alt+Suppr'#9'Ctrl+Alt+Fin');
    MAdd(ID_FULL, 'Plein '#233'cran'#9'Ctrl+Alt+Entr'#233'e');
    MAdd(0, '');
    MAdd(ID_DISC, 'D'#233'connecter');
    MSubEnd;
    Dummy := MDone(Fr);
    W := FbW; H := FbH;
    Rc[0] := 0; Rc[1] := 0; Rc[2] := W; Rc[3] := H;
    Dummy := WinCalcFrameRect(Fr, LongInt(@Rc), 0);
    W := Rc[2] - Rc[0]; H := Rc[3] - Rc[1];
    { trop grand pour l'ecran : fenetre de la taille de l'ecran, barres de
      defilement }
    If W > ScrW Then W := ScrW;
    If H > ScrH Then H := ScrH;
    Dummy := WinSetWindowPos(Fr, HWND_TOP, MaxI(0, (ScrW - W) Div 2), MaxI(0, (ScrH - H) Div 2), W, H,
                             SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  End;
  SessFr := Fr;
  Dummy := DosRequestMutexSem(FbSem, -1);
  SessWnd := Cl;
  PendR := PendL; PendPosted := False;
  Dummy := DosReleaseMutexSem(FbSem);
  If Old <> 0 Then Dummy := WinDestroyWindow(Old);
  SetScrolls;
  Dummy := WinInvalidateRect(SessWnd, 0, 1);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, SessFr);
  Dummy := WinSetFocus(HWND_DESKTOP, SessWnd);
End;

{ ---- boite de connexion ---- }

Procedure SetBusy(B : Boolean);
Begin
  Busy := B;
  Dummy := WinEnableWindow(BConn, Ord(Not B));
  Dummy := WinEnableWindow(EHost, Ord(Not B));
  Dummy := WinEnableWindow(EUser, Ord(Not B));
  Dummy := WinEnableWindow(EPass, Ord(Not B));
  Dummy := WinEnableWindow(EDom, Ord(Not B));
  Dummy := WinEnableWindow(LSize, Ord(Not B));
  If B Then
  Begin
    SetText(SStat, '');
    SetText(BQuit, 'Annuler');
    Dummy := WinSetFocus(HWND_DESKTOP, BQuit);
  End
  Else SetText(BQuit, 'Quitter');
End;

Function SizeSel : LongInt;
Var S, T : LongInt; X : String;
Begin
  S := WinSendMsg(LSize, LM_QUERYSELECTION, -1, 0);
  X := CtlText(LSize);
  T := -1;
  If Pos('640', X) = 1 Then T := 0
  Else If Pos('800', X) = 1 Then T := 1
  Else If Pos('1024', X) = 1 Then T := 2
  Else If X <> '' Then T := 3;
  If T >= 0 Then S := T;
  If (S < 0) Or (S > 3) Then S := 1;
  SizeSel := S;
End;

Procedure StartConnect;
Var U, H0 : String; K, S, Tid : LongInt;
Begin
  If Busy Then Exit;
  H0 := TrimS(CtlText(EHost));
  RdpHost := H0;
  { serveur:port (3389 par defaut), comme mstsc }
  RdpPort := 3389;
  K := Pos(':', RdpHost);
  If K > 0 Then
  Begin
    Val(Copy(RdpHost, K + 1, 5), RdpPort, S);
    If (S <> 0) Or (RdpPort <= 0) Then RdpPort := 3389;
    RdpHost := Copy(RdpHost, 1, K - 1);
  End;
  { clavier d'OS/2-0 : disposition americaine (codes de balayage) }
  KbdLay := $0409;
  U := TrimS(CtlText(EUser));
  RdpPass := CtlText(EPass);
  RdpDom := TrimS(CtlText(EDom));
  If RdpHost = '' Then
  Begin
    Dummy := Ask('Tapez le nom ou l''adresse IP de l''ordinateur distant.',
                 'Connexion Bureau '#224' distance', MB_OK Or MB_ICONWARNING);
    Dummy := WinSetFocus(HWND_DESKTOP, EHost);
    Exit;
  End;
  { DOMAINE\utilisateur }
  K := Pos('\', U);
  If K > 0 Then
  Begin
    RdpDom := Copy(U, 1, K - 1); U := Copy(U, K + 1, 255);
  End;
  RdpUser := U;
  IniWrite('MRU0', H0);
  IniWrite('User ' + UpS(RdpHost), TrimS(CtlText(EUser)));
  IniWrite('Domain', RdpDom);
  S := SizeSel;
  IniWrite('Size', IStr(S));
  FullScr := False;
  Case S Of
    0 : Begin ReqW := 640; ReqH := 480; End;
    1 : Begin ReqW := 800; ReqH := 600; End;
    2 : Begin ReqW := 1024; ReqH := 768; End;
  Else
    Begin
      ReqW := ScrW; ReqH := ScrH;
      FullScr := True;
    End;
  End;
  { ecran de la session precedente efface }
  If Fb <> 0 Then ZeroB(Fb, FbPitch * FbH);
  FbW := ReqW; FbH := ReqH;
  NetStop := False; Active := False; FirstAct := False; Connected := False;
  Licensed := False; Tc.Sock := -1; FragLen := 0;
  SetBusy(True);
  Tid := 0;
  If DosCreateThread(LongInt(@Tid), LongInt(@RdpThread), 0, 0, 262144) <> 0 Then
  Begin
    SetBusy(False);
    Dummy := Ask('Impossible de cr'#233'er la t'#226'che de connexion.', 'Connexion Bureau '#224' distance',
                 MB_OK Or MB_ICONERROR);
  End;
End;

Procedure PaintBanner(H : LongInt);
Var Hps, I : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  If Hps = 0 Then Exit;
  Rc[2] := 0; Rc[3] := 0;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  PaintH := Rc[3];
  Dummy := GpiCreateLogColorTable(Hps, 0, 3, 0, 0, 0);
  Bar(Hps, 0, 66, Rc[2], Rc[3], ClrFace);
  Bar(Hps, 0, 0, Rc[2], 64, ClrNavy);
  For I := 0 To 5 Do Bar(Hps, 330 + I * 14, 10 + I * 9, Rc[2], 64, $000090 + I * $10);
  Bar(Hps, 0, 64, Rc[2], 65, ClrShadow);
  Bar(Hps, 0, 65, Rc[2], 66, ClrHi);
  Txt(Hps, 16, 14, 'Connexion Bureau '#224' distance', $FFFFFF);
  Txt(Hps, 16, 38, 'OS/2-0 - client RDP (TLS, NLA)', $FFFF00);
  Dummy := WinEndPaint(Hps);
End;

Procedure EndMessage;
Var S : String;
Begin
  S := '';
  If RdpErr <> '' Then S := RdpErr
  Else If Not NetStop Then
    Case ErrInfo Of
      0, $C, $B : If Not FirstAct Then S := 'La connexion a '#233't'#233' interrompue.';
      1 : S := 'La session a '#233't'#233' d'#233'connect'#233'e par un administrateur.';
      2 : S := 'La session a '#233't'#233' ferm'#233'e par un administrateur.';
      3 : S := 'Session d'#233'connect'#233'e : d'#233'lai d''inactivit'#233' d'#233'pass'#233'.';
      4 : S := 'Session d'#233'connect'#233'e : d'#233'lai d''ouverture de session d'#233'pass'#233'.';
      5 : S := 'Un autre utilisateur s''est connect'#233' '#224' la session.';
      7 : S := 'Le serveur a refus'#233' la connexion.';
      9 : S := 'Vous n''avez pas l''autorisation d''ouvrir une session ' +
               'Bureau '#224' distance (groupe Utilisateurs du Bureau '#224' distance).';
    Else
      S := 'La session a '#233't'#233' d'#233'connect'#233'e (code ' + HexS(ErrInfo) + ').';
    End;
  If S <> '' Then
    Dummy := Ask(S, 'Connexion Bureau '#224' distance', MB_OK Or MB_ICONERROR);
End;

Function DlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk, F : LongInt;
Begin
  DlgProc := 0;
  Case Msg Of
    WM_PAINT : PaintBanner(H);
    WM_ERASEBACKGROUND : DlgProc := 0;
    WM_COMMAND :
      Case Lo16(Mp1) Of
        ID_CONNECT : StartConnect;
        ID_QUIT :
          If Busy Then Disconnect
          Else Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
        ID_ABOUT :
          Dummy := Ask('Connexion Bureau '#224' distance'#10#10 +
                       'Client RDP d''OS/2-0 : TLS 1.2, authentification NLA (CredSSP, NTLMv2), ' +
                       'bitmaps RLE, clavier, souris et molette.'#10 +
                       'Port'#233' de la Connexion Bureau '#224' distance de Pasdows 95.',
                       'A propos', MB_OK Or MB_ICONINFO);
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        DlgProc := 1;
        If ((Fl And KC_KEYUP) <> 0) Or ((Fl And KC_VIRTUALKEY) = 0) Then
          DlgProc := WinDefWindowProc(H, Msg, Mp1, Mp2)
        Else If (Vk = PVK_NEWLINE) Or (Vk = PVK_ENTER) Then
        Begin
          F := WinQueryFocus(HWND_DESKTOP);
          If F = BQuit Then Dummy := WinPostMsg(H, WM_COMMAND, ID_QUIT, 0)
          Else Dummy := WinPostMsg(H, WM_COMMAND, ID_CONNECT, 0);
        End
        Else If Vk = PVK_ESC Then Dummy := WinPostMsg(H, WM_COMMAND, ID_QUIT, 0)
        Else If (Vk = PVK_TAB) And ((Fl And KC_SHIFT) = 0) Then TabNext(1)
        Else If (Vk = PVK_BACKTAB) Or (Vk = PVK_TAB) Then TabNext(-1)
        Else DlgProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_RDPSTATUS : SetText(SStat, RdpStatus);
    WM_RDPACTIVE :
      Begin
        MakeSession;
        If Mp1 = 0 Then
        Begin
          Dummy := WinShowWindow(DlgFr, 0);
          SendSync(LockFlags);
        End;
      End;
    WM_RDPEND :
      Begin
        F := SessFr;
        SessWnd := 0; SessFr := 0;
        If F <> 0 Then Dummy := WinDestroyWindow(F);
        Dummy := WinShowWindow(DlgFr, 1);
        Dummy := WinSetActiveWindow(HWND_DESKTOP, DlgFr);
        SetBusy(False);
        SetText(SStat, '');
        EndMessage;
        Dummy := WinSetFocus(HWND_DESKTOP, EPass);
      End;
    WM_CLOSE :
      Begin
        If Busy Then Disconnect;
        Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
      End;
  Else
    DlgProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Procedure Lbl(T : String; Y : LongInt);
Begin
  Gray(Ctl(DlgWnd, WC_STATIC, T, SS_TEXT Or DT_VCENTER, 12, Y, 158, 22, 0));
End;

Var
  K, Fl, CW, CH : LongInt;
  S, Hs : String;
  Rc : Array[0..3] Of LongInt;

BEGIN
  OemOut := 1;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  SendSem := 0; FbSem := 0;
  Dummy := DosCreateMutexSem(0, LongInt(@SendSem), 0, 0);
  Dummy := DosCreateMutexSem(0, LongInt(@FbSem), 0, 0);
  Tx := NewMem(70000); Rx := NewMem(70000); InB := NewMem(256);
  Pool := NewMem(16384 * 8); Wk1 := NewMem(16384); Wk2 := NewMem(16384);
  Wk3 := NewMem(16384);
  Frag := NewMem(4194304 + 64); DecB := NewMem(4194304 + 64);
  TlHs := PTlHsBuf(TlNew(SizeOf(TlHsBuf)));
  TlInit;
  Fb := 0; FbW := 0; FbH := 0; SessWnd := 0; SessFr := 0; Busy := False; HSb := 0; VSb := 0;
  PendL := 0; PendR := 0; PendPosted := False; Tc.Sock := -1; NetReady := False;
  For K := 0 To 255 Do
    PalRgb[K] := ((((K Shr 5) And 7) * 255 Div 7) Shl 16) Or ((((K Shr 2) And 7) * 255 Div 7) Shl 8) Or
                 ((K And 3) * 85);
  ScrW := WinQuerySysValue(HWND_DESKTOP, SV_CXSCREEN);
  ScrH := WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN);
  Dummy := WinRegisterClass(Hab, Z('MstscDlg'), LongInt(@DlgProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('MstscSess'), LongInt(@SessProc), 0, 0);
  { boite : cadre de boite de dialogue, barre de menus, liste des taches }
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  DlgWnd := 0;
  DlgFr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('MstscDlg'),
                              Z2(Disp('Connexion Bureau '#224' distance')), 0, 0, 0, LongInt(@DlgWnd));
  If DlgFr = 0 Then Dummy := DosExit(1, 1);
  MStart;
  MSubBegin(200, 'Connexion');
  MAdd(ID_CONNECT, 'Connexion'#9'Entr'#233'e');
  MAdd(0, '');
  MAdd(ID_QUIT, 'Quitter'#9'Echap');
  MSubEnd;
  MSubBegin(201, 'Aide');
  MAdd(ID_ABOUT, 'A propos de Connexion Bureau '#224' distance');
  MSubEnd;
  Dummy := MDone(DlgFr);
  CW := 420; CH := 318;
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CW; Rc[3] := CH;
  Dummy := WinCalcFrameRect(DlgFr, LongInt(@Rc), 0);
  Dummy := WinSetWindowPos(DlgFr, HWND_TOP, MaxI(0, (ScrW - (Rc[2] - Rc[0])) Div 2),
                           MaxI(0, (ScrH - (Rc[3] - Rc[1])) Div 2), Rc[2] - Rc[0], Rc[3] - Rc[1],
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  TabN := 0;
  Lbl('Ordinateur :', 218);
  EHost := Ctl(DlgWnd, WC_ENTRYFIELD, '', ES_AUTOSCROLL Or ES_MARGIN Or WS_TABSTOP, 170, 218, 232, 22, ID_HOST);
  Lbl('Nom d''utilisateur :', 190);
  EUser := Ctl(DlgWnd, WC_ENTRYFIELD, '', ES_AUTOSCROLL Or ES_MARGIN Or WS_TABSTOP, 170, 190, 232, 22, ID_USER);
  Lbl('Mot de passe :', 162);
  EPass := Ctl(DlgWnd, WC_ENTRYFIELD, '', ES_AUTOSCROLL Or ES_MARGIN Or ES_UNREADABLE Or WS_TABSTOP, 170, 162,
               232, 22, ID_PASS);
  Lbl('Domaine :', 134);
  EDom := Ctl(DlgWnd, WC_ENTRYFIELD, '', ES_AUTOSCROLL Or ES_MARGIN Or WS_TABSTOP, 170, 134, 232, 22, ID_DOM);
  Lbl('Taille de l'''#233'cran :', 106);
  LSize := Ctl(DlgWnd, WC_COMBOBOX, '', CBS_DROPDOWNLIST Or WS_TABSTOP, 170, 106, 232, 22, ID_SIZE);
  Dummy := WinSendMsg(LSize, LM_INSERTITEM, -1, Z('640 x 480'));
  Dummy := WinSendMsg(LSize, LM_INSERTITEM, -1, Z('800 x 600'));
  Dummy := WinSendMsg(LSize, LM_INSERTITEM, -1, Z('1024 x 768'));
  Dummy := WinSendMsg(LSize, LM_INSERTITEM, -1, Z(Disp('Plein '#233'cran')));
  SStat := Ctl(DlgWnd, WC_STATIC, '', SS_TEXT Or DT_WORDBREAK, 16, 12, 210, 44, ID_STAT);
  Gray(SStat);
  BConn := Ctl(DlgWnd, WC_BUTTON, 'Connexion', BS_PUSHBUTTON Or BS_DEFAULT Or WS_TABSTOP, 236, 14, 84, 26,
               ID_CONNECT);
  BQuit := Ctl(DlgWnd, WC_BUTTON, 'Quitter', BS_PUSHBUTTON Or WS_TABSTOP, 326, 14, 78, 26, ID_QUIT);
  Dummy := WinSendMsg(EHost, EM_SETTEXTLIMIT, 250, 0);
  Dummy := WinSendMsg(EUser, EM_SETTEXTLIMIT, 250, 0);
  Dummy := WinSendMsg(EPass, EM_SETTEXTLIMIT, 250, 0);
  Dummy := WinSendMsg(EDom, EM_SETTEXTLIMIT, 250, 0);
  { valeurs de la derniere connexion (OS2.INI) }
  Hs := IniRead('MRU0');
  SetText(EHost, Hs);
  K := Pos(':', Hs);
  If K > 0 Then S := Copy(Hs, 1, K - 1) Else S := Hs;
  If Hs <> '' Then SetText(EUser, IniRead('User ' + UpS(TrimS(S))));
  S := IniRead('Domain');
  If Pos('\', CtlText(EUser)) = 0 Then SetText(EDom, S);
  S := IniRead('Size');
  K := 1;
  If ScrW < 1024 Then K := 3;
  If (S <> '') And (S[1] >= '0') And (S[1] <= '3') Then K := Ord(S[1]) - 48;
  Dummy := WinSendMsg(LSize, LM_SELECTITEM, K, 1);
  Case K Of
    0 : SetText(LSize, '640 x 480');
    1 : SetText(LSize, '800 x 600');
    2 : SetText(LSize, '1024 x 768');
  Else
    SetText(LSize, 'Plein '#233'cran');
  End;
  Dummy := WinSetActiveWindow(HWND_DESKTOP, DlgFr);
  If Hs = '' Then Dummy := WinSetFocus(HWND_DESKTOP, EHost) Else Dummy := WinSetFocus(HWND_DESKTOP, EPass);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  If Busy Then
  Begin
    NetStop := True;
    Dummy := DosSleep(600);
  End;
  Dummy := DosExit(1, 0);
END.
