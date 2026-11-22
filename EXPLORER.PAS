{ EXPLORER.PAS - Explorateur OS2-Zero (Presentation Manager).

  Compilation : OS2PC EXPLORER.PAS EXPLORER.EXE

  Explorateur de fichiers dans le style de Windows 95, porte de
  l'Explorateur Pasdows (KERNEL/VMM32.PAS de Pasdows 95, ou il faisait
  partie du noyau) vers l'API d'OS/2 : c'est une application de
  Presentation Manager independante, qui ne change rien au Workplace Shell.
  Elle complete les dossiers d'objets du bureau pour ceux qui preferent un
  explorateur a deux volets :
    - a gauche, l'arbre "Tous les dossiers" : Bureau, Poste de travail,
      lecteurs, dossiers (cases + et -, traits pointilles, deplie a la
      demande) ;
    - a droite, le "Contenu de" du dossier choisi : Grandes icones (comme
      Pasdows 95) ou Details (nom, taille, type, date de modification) ;
    - en bas, la barre d'etat en deux parties (objets ou objet choisi,
      espace disque libre).
  Double clic ou Entree : ouvre un dossier ou un lecteur, lance un
  programme (.EXE, .COM ; .CMD et .BAT par CMD.EXE), ouvre un document
  avec son application (texte et sources : Pascal Developer ; .WAV : Audio
  numerique ; .HTM : Navigateur Web). Retour arriere : dossier parent ; F5 :
  actualiser ; Tab : passe de l'arbre au contenu ; fleches, Debut, Fin,
  Pg.prec., Pg.suiv. ; bouton 2 : menu contextuel (Ouvrir, Proprietes).
  Proprietes d'un lecteur : boite "Proprietes de (C:)" de Pasdows 95
  (onglets General, Outils, Partage ; nom du volume modifiable ; espace
  utilise et libre ; camembert en relief) ; EXPLORER /PROPS:C: ouvre cette
  boite seule (dossier Lecteurs du bureau) ; EXPLORER /FPROPS fichier...
  ouvre seule la boite Proprietes de fichiers ou de dossiers (menu
  contextuel du bureau et des dossiers).
  Edition et bouton 2 : Couper, Copier, Coller (fichiers et dossiers,
  d'un lecteur a l'autre), Supprimer, Renommer, Nouveau dossier,
  Selectionner tout ; Ctrl+clic, Maj+clic, Ctrl+A, Ctrl+X, Ctrl+C,
  Ctrl+V, Suppr, F2 ; Proprietes d'un fichier, d'un dossier ou de
  plusieurs elements (dates, attributs modifiables). .MP3 : Lecteur MP3.
  Outils (et bouton 2 sur le Poste de travail) : Connecter un lecteur
  reseau... (lettre, \\serveur\partage, utilisateur, mot de passe, "Se
  reconnecter a l'ouverture de session" : OS2.INI, PM_NetworkDrives) et
  Deconnecter un lecteur reseau... ; DosFSAttach et SMB.IFS (SMB2,
  NTLMv2), voir la section "Lecteurs reseau" plus bas.

  API d'OS/2 : DosFindFirst/DosFindNext (FILEFINDBUF3), DosQueryCurrentDisk,
  DosQueryFSInfo (etiquette, espace libre), DosSetFSInfo (nom du volume),
  DosQueryFSAttach (CDFS, HPFS,
  NTFS...), DosExecPgm, WinCreateStdWindow, gabarit de menu et
  WinPopupMenu, WinFillRect, GpiLine, WinDrawText, WinMessageBox.
  Langue : variable LANGUAGE (FR, EN, GR, IT, SP). }

Program Explorer;

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074;
  WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20;
  FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_CHECKED = $2000; MIA_DISABLED = $4000; MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_INFORMATION = $30; MB_WARNING = $20; MB_ERROR = $40; MB_MOVEABLE = $4000;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08; VK_ESC = $0F;
  VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14; VK_LEFT = $15; VK_UP = $16;
  VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E; VK_F5 = $24;
  VK_SHIFTK = $09; VK_CTRLK = $0A; VK_DELETE = $1B; VK_F2 = $21;
  { couleurs (palette de PM ; equivalents de Windows 95) }
  cBlue = 1; cRed = 2; cLime = 4; cAqua = 5; cYellow = 6; cGray = 8; cNavy = 9;
  cMaroon = 10; cGreen = 12; cTeal = 13; cOlive = 14; cSilver = 15;
  cWhite = -2; cBlack = -1;
  DT_RIGHT = $200;
  { icones (numeros de Pasdows 95) }
  icComputer = 1; icText = 6; icFolder = 7; icCdrom = 8; icFloppy = 9; icDisplay = 11;
  icDocs = 23; icApp = 25; icHardDisk = 26; icExplorer = 28; icWeb = 39; icSound = 32; icNetDrive = 41;
  { types d'entrees }
  ekFile = 0; ekDir = 1; ekHdd = 2; ekCd = 3; ekFloppy = 4; ekNet = 5;
  { commandes }
  cmOpen = 101; cmProps = 102; cmClose = 103;
  cmIcons = 111; cmDetails = 112; cmRefresh = 113;
  cmUp = 121; cmComputer = 122;
  cmAbout = 131;
  cmMapNet = 141; cmUnmapNet = 142; cmDisconnect = 143;
  cmCut = 151; cmCopy = 152; cmPaste = 153; cmDelete = 154; cmRename = 155; cmSelAll = 156;
  cmNewDir = 157; cmInvSel = 158; cmPasteIn = 159; cmPasteTree = 160;
  { controles de PM (boites Connecter et Deconnecter un lecteur reseau) }
  WC_COMBOBOX = $FFFF0002; WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006;
  WC_LISTBOX = $FFFF0007;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000;
  BS_PUSHBUTTON = 0; BS_AUTOCHECKBOX = 2; BS_DEFAULT = $0400;
  SS_TEXT = 1; DT_VCENTER = $0400; CBS_DROPDOWNLIST = 4;
  ES_AUTOSCROLL = 4; ES_MARGIN = 8; ES_UNREADABLE = $80;
  EM_SETTEXTLIMIT = $0143; EM_SETSEL = $0142;
  BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
  LM_INSERTITEM = $0161; LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165;
  ID_OK = 1; ID_CANCEL = 2;
  HINI_USERPROFILE = -1;
  NetApp = 'PM_NetworkDrives';     { OS2.INI : lettre -> chemin, utilisateur, cle }
  { dimensions }
  MaxE = 1500;
  TreeMax = 256;
  TreeRow = 18;
  CellW = 100; CellH = 70;
  RowH = 18;
  SbW = 17;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  TEnt = Record
    Nm : String;
    Size, Kind, FDate, FTime, Attr : LongInt;
  End;
  PEnt = ^TEnt;

Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
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
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFSAttach(PDev, Ordinal, Level, PBuf, PCb : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetDefaultDisk(Disk : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetCurrentDir(PName : LongInt) : LongInt; External 'DOSCALLS';
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosFSAttach(PDev, PFsd, PData, CbData, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosLoadModule(PObj, CbObj, PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function KDiskCtl(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnDiskCtl';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysPointer(HD, Id, Load : LongInt) : LongInt; External 'PMWIN';
Function WinSetPointer(HD, Hptr : LongInt) : LongInt; External 'PMWIN';
Function WinQueryFocus(HD : LongInt) : LongInt; External 'PMWIN';
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosDeleteDir(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosMove(POld, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosCopy(PSrc, PDst, Opt : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetPathInfo(PName, Level, PInfo, Cb, Fl : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocSharedMem(PPb, PName, Cb, Fl : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetNamedSharedMem(PPb, PName, Fl : LongInt) : LongInt; External 'DOSCALLS';
Function WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetClipbrdData(Hab, D, Fmt, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt; External 'PMWIN';
Function WinGetKeyState(HD, Vk : LongInt) : LongInt; External 'PMWIN';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE';

Var
  Hab, Hmq, Frame, Client, MenuHw, Lang, Dummy : LongInt;
  NameZ, NameZ2, TxtBuf, ArgBuf, FailBuf : Array[0..1023] Of Byte;
  FindBuf : Array[0..4095] Of Byte;
  MenuT : Array[0..2047] Of Byte;
  MenuLen : LongInt;
  CW, CH, Hps : LongInt;
  { contenu du dossier affiche }
  CurPath : String;            { '' : Poste de travail ; 'C:' ; 'C:\DIR' }
  EntBase, NEnt, Sel, Top, View : LongInt;
  Idx : Array[0..MaxE - 1] Of LongInt;
  SelF : Array[0..MaxE - 1] Of Boolean;   { elements choisis (Ctrl+clic, Maj+clic) }
  SelA : LongInt;                         { ancre de Maj+clic }
  Truncated : Boolean;
  { arbre : '*' Bureau, '' Poste de travail, 'C:', 'C:\DIR' ; F : 1
    deplie, 2 sans sous-dossier }
  NdP : Array[0..TreeMax - 1] Of String[79];
  NdD, NdF : Array[0..TreeMax - 1] Of LongInt;
  TN, TTop, TSel, TVis : LongInt;
  Focus : LongInt;             { 0 contenu, 1 arbre }
  { lecteurs }
  DrvLbl : Array[0..25] Of String[15];
  DrvFs : Array[0..25] Of String[15];
  DrvKind : Array[0..25] Of LongInt;
  DrvRem : Array[0..25] Of String[79];   { lecteur reseau : \\serveur\partage }
  DrvMap : LongInt;
  { icones }
  IcX, IcY, IcS : LongInt;
  { menu contextuel }
  CtxMenu : LongInt;
  FpuCw : Word;
  DirNames : Array[0..127] Of String[40];

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Procedure WrB(A, V : LongInt);
Var Q : PByte;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Function RdB(A : LongInt) : LongInt;
Var Q : PByte;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Function RdL(A : LongInt) : LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Function RdW(A : LongInt) : LongInt;
Begin
  RdW := RdB(A) Or (RdB(A + 1) Shl 8);
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Procedure WrL(A, V : LongInt);
Var Q : PLong;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

{ LongInt non signe -> Double (tailles de plus de 2 Go) }
Function GlUns(V : LongInt) : Double;
Begin
  If V < 0 Then GlUns := V + 4294967296.0 Else GlUns := V;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; C : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    C := RdB(A);
    While (C <> 0) And (Length(S) < 250) Do
    Begin
      S := S + Chr(C);
      Inc(A);
      C := RdB(A);
    End;
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

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
End;

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
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

Function GetEnvS(N : String) : String;
Var P : LongInt;
Begin
  P := 0;
  If DosScanEnv(Z(N), LongInt(@P)) = 0 Then GetEnvS := GetZ(P) Else GetEnvS := '';
End;

Function FileExists(N : String) : Boolean;
Var H, C, Rc : LongInt;
Begin
  H := -1; C := 1;
  Rc := DosFindFirst(Z(N), LongInt(@H), $07, LongInt(@FindBuf), 4096, LongInt(@C), 1);
  If H <> -1 Then Dummy := DosFindClose(H);
  FileExists := (Rc = 0) And (C > 0);
End;

{ Texte dans la langue courante (page de codes 850) }
Function L(Fr, En, De, It, Es : String) : String;
Begin
  Case Lang Of
    1 : L := En;
    2 : L := De;
    3 : L := It;
    4 : L := Es;
  Else
    L := Fr;
  End;
End;

Procedure LangInit;
Var S : String;
Begin
  S := UpStr(GetEnvS('LANGUAGE'));
  If (S <> '') And (S[1] = '"') Then Delete(S, 1, 1);
  S := Copy(S, 1, 2);
  If (S = '') Or (S = 'FR') Then Lang := 0
  Else If (S = 'GR') Or (S = 'DE') Then Lang := 2
  Else If S = 'IT' Then Lang := 3
  Else If (S = 'SP') Or (S = 'ES') Then Lang := 4
  Else Lang := 1;
End;

Function AppName : String;
Begin
  AppName := L('Explorateur OS2-Zero', 'OS2-Zero Explorer', 'OS2-Zero-Explorer', 'Esplora risorse OS2-Zero',
               'Explorador de OS2-Zero');
End;

Procedure Msg(S : String; Fl : LongInt);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2(AppName), 0, Fl Or MB_MOVEABLE);
End;

Function BaseName(P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> '\') Do Dec(K);
  BaseName := Copy(P, K + 1, 255);
End;

Function ExtOf(Nm : String) : String;
Var K : LongInt;
Begin
  K := Length(Nm);
  While (K > 0) And (Nm[K] <> '.') Do Dec(K);
  If K = 0 Then ExtOf := '' Else ExtOf := UpStr(Copy(Nm, K + 1, 255));
End;

{ Taille courte : Ko, Mo ou Go (comme Pasdows 95) }
Function SizeKb(Kb : Double) : String;
Var G : LongInt; S : String;
Begin
  If Kb < 1024 Then S := IStr(Trunc(Kb)) + L(' Ko', ' KB', ' KB', ' KB', ' KB')
  Else If Kb < 1048576 Then S := IStr(Trunc(Kb / 1024)) + L(' Mo', ' MB', ' MB', ' MB', ' MB')
  Else
  Begin
    G := Round(Kb / 10485.76);
    S := IStr(G Mod 100);
    If Length(S) < 2 Then S := '0' + S;
    S := IStr(G Div 100) + L(',', '.', ',', ',', ',') + S + L(' Go', ' GB', ' GB', ' GB', ' GB');
  End;
  SizeKb := S;
End;

{ nombre avec separateur des milliers }
Function Thousands(V : LongInt) : String;
Var R, T, Sep : String; I : LongInt;
Begin
  R := IStr(V);
  Sep := L(' ', ',', '.', '.', '.');
  T := '';
  For I := 1 To Length(R) Do
  Begin
    T := T + R[I];
    If ((Length(R) - I) Mod 3 = 0) And (I < Length(R)) Then T := T + Sep;
  End;
  Thousands := T;
End;

Function Two(V : LongInt) : String;
Begin
  If V < 10 Then Two := '0' + IStr(V) Else Two := IStr(V);
End;

{ date et heure de FILEFINDBUF3 (fdateLastWrite, ftimeLastWrite) }
Function DateStr(D, T : LongInt) : String;
Var S : String;
Begin
  If D = 0 Then
  Begin
    DateStr := '';
    Exit;
  End;
  If Lang = 1 Then
    S := Two((D Shr 5) And 15) + '/' + Two(D And 31) + '/' + IStr(1980 + ((D Shr 9) And 127))
  Else S := Two(D And 31) + '/' + Two((D Shr 5) And 15) + '/' + IStr(1980 + ((D Shr 9) And 127));
  DateStr := S + ' ' + Two((T Shr 11) And 31) + ':' + Two((T Shr 5) And 63);
End;

{ ==================================================================== }
{ Lecteurs                                                              }
{ ==================================================================== }

Function FsOf(D : LongInt) : String;
Var Cb : LongInt; B : Array[0..63] Of Byte;
Begin
  Cb := 64;
  FsOf := '';
  If DosQueryFSAttach(Z(Chr(64 + D) + ':'), 0, 1, LongInt(@B), LongInt(@Cb)) = 0 Then
    FsOf := UpStr(GetZ(LongInt(@B) + 11));
End;

{ lecteur reseau (DosQueryFSAttach : FSAT_REMOTEDRV) : \\serveur\partage,
  sinon '' }
Function RemoteOf(D : LongInt) : String;
Var Cb, N : LongInt; B : Array[0..299] Of Byte;
Begin
  RemoteOf := '';
  Cb := 300;
  If DosQueryFSAttach(Z(Chr(64 + D) + ':'), 0, 1, LongInt(@B), LongInt(@Cb)) <> 0 Then Exit;
  If RdW(LongInt(@B)) <> 4 Then Exit;
  N := RdW(LongInt(@B) + 2);
  RemoteOf := Copy(GetZ(LongInt(@B) + 8 + N + 1 + RdW(LongInt(@B) + 4) + 1), 1, 79);
End;

Procedure ScanDrives;
Var D, Cur, K : LongInt; B : Array[0..63] Of Byte; S : String;
Begin
  Cur := 0; DrvMap := 0;
  Dummy := DosQueryCurrentDisk(LongInt(@Cur), LongInt(@DrvMap));
  For K := 0 To 25 Do
  Begin
    DrvLbl[K] := ''; DrvFs[K] := ''; DrvKind[K] := ekHdd; DrvRem[K] := '';
    If (DrvMap And (1 Shl K)) <> 0 Then
    Begin
      D := K + 1;
      If K < 2 Then DrvKind[K] := ekFloppy
      Else
      Begin
        S := FsOf(D);
        DrvFs[K] := Copy(S, 1, 15);
        If (S = 'CDFS') Or (S = 'ISO9660') Or (S = 'UDF') Then DrvKind[K] := ekCd;
        DrvRem[K] := RemoteOf(D);
        If DrvRem[K] <> '' Then
        Begin
          { lecteur reseau : pas de nom de volume a lire (le serveur peut
            etre eteint : la connexion se fait au premier acces) }
          DrvKind[K] := ekNet;
          S := DrvRem[K];
          While Pos('\', S) > 0 Do Delete(S, 1, Pos('\', S));
          DrvLbl[K] := Copy(UpStr(S), 1, 15);
          Continue;
        End;
        FillChar(B, SizeOf(B), 0);
        If DosQueryFSInfo(D, 2, LongInt(@B), 64) = 0 Then
          If (B[4] > 0) And (B[4] < 13) Then
          Begin
            S := '';
            For D := 1 To B[4] Do S := S + Chr(B[4 + D]);
            While (S <> '') And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
            DrvLbl[K] := S;
          End;
      End;
    End;
  End;
End;

{ \\serveur\partage -> partage sur 'serveur' (comme Windows 95) }
Function NetName(R : String) : String;
Var K : LongInt; Srv, Sh : String;
Begin
  If Copy(R, 1, 2) = '\\' Then Delete(R, 1, 2);
  K := Pos('\', R);
  If K = 0 Then
  Begin
    NetName := R;
    Exit;
  End;
  Srv := Copy(R, 1, K - 1); Sh := Copy(R, K + 1, 255);
  NetName := Sh + L(' sur ''', ' on ''', ' auf ''', ' su ''', ' en ''') + Srv + '''';
End;

Function DriveName(C : Char) : String;
Var K : LongInt; S : String;
Begin
  K := Ord(UpCase(C)) - 65;
  If (K < 0) Or (K > 25) Then
  Begin
    DriveName := C + ':';
    Exit;
  End;
  If DrvKind[K] = ekNet Then
  Begin
    DriveName := NetName(DrvRem[K]) + ' (' + UpCase(C) + ':)';
    Exit;
  End;
  If DrvKind[K] = ekFloppy Then
    S := L('Disquette', 'Floppy', 'Diskette', 'Floppy', 'Disquete')
  Else S := DrvLbl[K];
  If S = '' Then
  Begin
    If DrvKind[K] = ekCd Then S := 'CD-ROM'
    Else S := L('Disque local', 'Local Disk', 'Lokaler Datentr'#132'ger', 'Disco locale', 'Disco local');
  End;
  DriveName := S + ' (' + UpCase(C) + ':)';
End;

{ espace libre et capacite en Ko ; faux si le lecteur ne repond pas }
Function DriveSpace(C : Char; Var FreeKb, TotKb : Double) : Boolean;
Var B : Array[0..31] Of Byte; K, Spc, Tot, Fr, Bps : LongInt;
Begin
  DriveSpace := False;
  FreeKb := 0; TotKb := 0;
  K := Ord(UpCase(C)) - 64;
  If (K < 1) Or (K > 26) Then Exit;
  If DrvKind[K - 1] = ekFloppy Then Exit;
  If DosQueryFSInfo(K, 1, LongInt(@B), 18) <> 0 Then Exit;
  Spc := RdL(LongInt(@B) + 4); Tot := RdL(LongInt(@B) + 8); Fr := RdL(LongInt(@B) + 12);
  Bps := RdW(LongInt(@B) + 16);
  FreeKb := Fr * 1.0 * Spc * Bps / 1024;
  TotKb := Tot * 1.0 * Spc * Bps / 1024;
  DriveSpace := TotKb > 0;
End;

{ ==================================================================== }
{ Contenu d'un dossier                                                  }
{ ==================================================================== }

Function E(I : LongInt) : PEnt;
Begin
  E := Pointer(EntBase + Idx[I] * SizeOf(TEnt));
End;

Function Slot(N : LongInt) : PEnt;
Begin
  Slot := Pointer(EntBase + N * SizeOf(TEnt));
End;

{ comparaison sans distinction des majuscules : dossiers d'abord }
Function Before(A, B : LongInt) : Boolean;
Var Pa, Pb : PEnt; K, N, Ca, Cb : LongInt;
Begin
  Pa := Slot(A); Pb := Slot(B);
  If (Pa^.Kind = ekDir) <> (Pb^.Kind = ekDir) Then
  Begin
    Before := Pa^.Kind = ekDir;
    Exit;
  End;
  N := MinI(Length(Pa^.Nm), Length(Pb^.Nm));
  For K := 1 To N Do
  Begin
    Ca := Ord(UpCase(Pa^.Nm[K])); Cb := Ord(UpCase(Pb^.Nm[K]));
    If Ca <> Cb Then
    Begin
      Before := Ca < Cb;
      Exit;
    End;
  End;
  Before := Length(Pa^.Nm) < Length(Pb^.Nm);
End;

Procedure SortEntries;
Var Gap, I, J, T : LongInt;
Begin
  Gap := NEnt Div 2;
  While Gap > 0 Do
  Begin
    For I := Gap To NEnt - 1 Do
    Begin
      T := Idx[I]; J := I;
      While (J >= Gap) And Before(T, Idx[J - Gap]) Do
      Begin
        Idx[J] := Idx[J - Gap];
        J := J - Gap;
      End;
      Idx[J] := T;
    End;
    Gap := Gap Div 2;
  End;
End;

Procedure AddEnt(Nm : String; Kind, Size, D, T, A : LongInt);
Var P : PEnt;
Begin
  If NEnt >= MaxE Then
  Begin
    Truncated := True;
    Exit;
  End;
  P := Slot(NEnt);
  P^.Nm := Nm; P^.Kind := Kind; P^.Size := Size; P^.FDate := D; P^.FTime := T; P^.Attr := A;
  Idx[NEnt] := NEnt;
  Inc(NEnt);
End;

{ dossier P : '' lecteurs, sinon fichiers et sous-dossiers ; Dirs : les
  sous-dossiers seulement (arbre) }
{ selection : Sel est l'element courant, SelF les elements choisis }
Procedure ClearSel;
Var K : LongInt;
Begin
  For K := 0 To MaxE - 1 Do SelF[K] := False;
  Sel := -1;
End;

Procedure SelOne(I : LongInt);
Begin
  ClearSel;
  If (I >= 0) And (I < NEnt) Then
  Begin
    SelF[I] := True;
    Sel := I; SelA := I;
  End;
End;

Function SelCount : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To NEnt - 1 Do If SelF[K] Then Inc(N);
  SelCount := N;
End;

Procedure SelAll;
Var K : LongInt;
Begin
  For K := 0 To NEnt - 1 Do SelF[K] := True;
  If (Sel < 0) And (NEnt > 0) Then Sel := 0;
End;

Procedure SelInvert;
Var K : LongInt;
Begin
  For K := 0 To NEnt - 1 Do SelF[K] := Not SelF[K];
End;

{ Maj : de l'ancre a I }
Procedure SelRange(I : LongInt);
Var K, A, B : LongInt;
Begin
  If (SelA < 0) Or (SelA >= NEnt) Then SelA := I;
  For K := 0 To MaxE - 1 Do SelF[K] := False;
  A := MinI(SelA, I); B := MaxI(SelA, I);
  For K := A To B Do If (K >= 0) And (K < NEnt) Then SelF[K] := True;
  Sel := I;
End;

Function KeyDown(Vk : LongInt) : Boolean;
Begin
  KeyDown := (WinGetKeyState(HWND_DESKTOP, Vk) And $8000) <> 0;
End;

Procedure ListDir(P : String; Dirs : Boolean);
Var H, N, Off, A, K, Rc : LongInt; S : String;
Begin
  NEnt := 0; Truncated := False;
  ClearSel; SelA := -1;
  If P = '' Then
  Begin
    For K := 0 To 25 Do
      If (DrvMap And (1 Shl K)) <> 0 Then AddEnt(Chr(65 + K) + ':', DrvKind[K], 0, 0, 0, 0);
    Exit;
  End;
  H := -1; N := 1;
  Rc := DosFindFirst(Z(P + '\*.*'), LongInt(@H), $37, LongInt(@FindBuf), 4096, LongInt(@N), 1);
  While (Rc = 0) And (N > 0) Do
  Begin
    Off := 0;
    While N > 0 Do
    Begin
      A := RdL(LongInt(@FindBuf) + Off + 24);
      S := '';
      For K := 0 To RdB(LongInt(@FindBuf) + Off + 28) - 1 Do S := S + Chr(RdB(LongInt(@FindBuf) + Off + 29 + K));
      If (S <> '.') And (S <> '..') And (S <> '') Then
        If (A And $10) <> 0 Then
          AddEnt(S, ekDir, 0, RdW(LongInt(@FindBuf) + Off + 12), RdW(LongInt(@FindBuf) + Off + 14), A)
        Else If Not Dirs Then
          AddEnt(S, ekFile, RdL(LongInt(@FindBuf) + Off + 16), RdW(LongInt(@FindBuf) + Off + 12),
                 RdW(LongInt(@FindBuf) + Off + 14), A);
      Dec(N);
      If RdL(LongInt(@FindBuf) + Off) = 0 Then N := 0
      Else Off := Off + RdL(LongInt(@FindBuf) + Off);
    End;
    N := 1;
    Rc := DosFindNext(H, LongInt(@FindBuf), 4096, LongInt(@N));
  End;
  If H <> -1 Then Dummy := DosFindClose(H);
  SortEntries;
End;

{ nom affiche d'une entree }
Function EntName(I : LongInt) : String;
Begin
  If CurPath = '' Then EntName := DriveName(E(I)^.Nm[1]) Else EntName := E(I)^.Nm;
End;

Function EntPath(I : LongInt) : String;
Begin
  If CurPath = '' Then EntPath := E(I)^.Nm Else EntPath := CurPath + '\' + E(I)^.Nm;
End;

Function FileIcon(Nm : String; Kind : LongInt) : LongInt;
Var X : String;
Begin
  X := ExtOf(Nm);
  Case Kind Of
    ekDir : FileIcon := icFolder;
    ekHdd : FileIcon := icHardDisk;
    ekCd : FileIcon := icCdrom;
    ekFloppy : FileIcon := icFloppy;
    ekNet : FileIcon := icNetDrive;
  Else
    If (X = 'EXE') Or (X = 'COM') Or (X = 'CMD') Or (X = 'BAT') Then FileIcon := icApp
    Else If (X = 'TXT') Or (X = 'INI') Or (X = 'SYS') Or (X = 'PAS') Or (X = 'LOG') Or (X = 'CFG') Or
            (X = 'ME') Or (X = 'DOC') Or (X = 'INC') Or (X = 'ASM') Then FileIcon := icText
    Else If (X = 'HTM') Or (X = 'HTML') Then FileIcon := icWeb
    Else If X = 'WAV' Then FileIcon := icSound
    Else FileIcon := icDocs;
  End;
End;

Function TypeName(Nm : String; Kind : LongInt) : String;
Var X : String;
Begin
  X := ExtOf(Nm);
  Case Kind Of
    ekDir : TypeName := L('Dossier de fichiers', 'File Folder', 'Dateiordner', 'Cartella di file',
                          'Carpeta de archivos');
    ekHdd : TypeName := L('Disque local', 'Local Disk', 'Lokaler Datentr'#132'ger', 'Disco locale', 'Disco local');
    ekCd : TypeName := L('Disque compact', 'CD-ROM Disc', 'CD-ROM', 'CD-ROM', 'CD-ROM');
    ekFloppy : TypeName := L('Disquette', 'Floppy Disk', 'Diskette', 'Floppy', 'Disquete');
    ekNet : TypeName := L('Lecteur r'#130'seau', 'Network Drive', 'Netzlaufwerk', 'Unit'#133' di rete',
                          'Unidad de red');
  Else
    If (X = 'EXE') Or (X = 'COM') Then TypeName := L('Application', 'Application', 'Anwendung', 'Applicazione',
                                                   'Aplicaci'#162'n')
    Else If (X = 'CMD') Or (X = 'BAT') Then TypeName := L('Fichier de commandes', 'Batch File', 'Stapelverarbeitung',
                                                          'File batch', 'Archivo por lotes')
    Else If X = 'DLL' Then TypeName := L('Biblioth'#138'que (DLL)', 'Dynamic Link Library', 'Programmbibliothek',
                                         'Libreria (DLL)', 'Biblioteca (DLL)')
    Else If X = 'TXT' Then TypeName := L('Document texte', 'Text Document', 'Textdokument', 'Documento di testo',
                                         'Documento de texto')
    Else If X = 'PAS' Then TypeName := L('Source Pascal', 'Pascal Source', 'Pascal-Quelltext', 'Sorgente Pascal',
                                         'Fuente Pascal')
    Else If (X = 'HTM') Or (X = 'HTML') Then TypeName := L('Document HTML', 'HTML Document', 'HTML-Dokument',
                                                          'Documento HTML', 'Documento HTML')
    Else If X = 'WAV' Then TypeName := L('Son Wave', 'Wave Sound', 'Wave-Klang', 'Suono Wave', 'Sonido Wave')
    Else If (X = 'BMP') Or (X = 'DIB') Then TypeName := L('Image bitmap', 'Bitmap Image', 'Bitmap-Bild', 'Immagine bitmap',
                                                          'Imagen de mapa de bits')
    Else If X = '' Then TypeName := L('Fichier', 'File', 'Datei', 'File', 'Archivo')
    Else TypeName := L('Fichier ', '', '', 'File ', 'Archivo ') + X + L('', ' File', '-Datei', '', '');
  End;
End;

{ ==================================================================== }
{ Dessin (coordonnees de la zone client, Y vers le bas)                 }
{ ==================================================================== }

{ rectangle plein, bornes incluses }
Procedure FBar(X1, Y1, X2, Y2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  Rc[0] := X1; Rc[1] := CH - 1 - Y2; Rc[2] := X2 + 1; Rc[3] := CH - Y1;
  Dummy := WinFillRect(Hps, LongInt(@Rc), C);
End;

Procedure HLine(X1, X2, Y, C : LongInt);
Begin
  FBar(X1, Y, X2, Y, C);
End;

Procedure VLine(X, Y1, Y2, C : LongInt);
Begin
  FBar(X, Y1, X, Y2, C);
End;

Procedure Pix(X, Y, C : LongInt);
Begin
  FBar(X, Y, X, Y, C);
End;

Procedure DLine(X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := CH - 1 - Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := CH - 1 - Y2;
  Dummy := GpiLine(Hps, LongInt(@P));
End;

Procedure Box(X1, Y1, X2, Y2, C : LongInt);
Begin
  HLine(X1, X2, Y1, C); HLine(X1, X2, Y2, C);
  VLine(X1, Y1, Y2, C); VLine(X2, Y1, Y2, C);
End;

{ cadre d'un pixel : haut et gauche Lt, bas et droite Dk }
Procedure Edge(X1, Y1, X2, Y2, Lt, Dk : LongInt);
Begin
  HLine(X1, X2, Y1, Lt); VLine(X1, Y1, Y2, Lt);
  HLine(X1, X2, Y2, Dk); VLine(X2, Y1, Y2, Dk);
End;

{ relief de Windows 95 (bouton : contour noir) }
Procedure Raised(X1, Y1, X2, Y2 : LongInt; Btn : Boolean);
Begin
  FBar(X1, Y1, X2, Y2, cSilver);
  If Btn Then
  Begin
    Edge(X1, Y1, X2, Y2, cWhite, cBlack);
    HLine(X1 + 1, X2 - 1, Y2 - 1, cGray); VLine(X2 - 1, Y1 + 1, Y2 - 1, cGray);
  End
  Else Edge(X1, Y1, X2, Y2, cWhite, cGray);
End;

{ champ en creux (fond F) }
Procedure Sunken(X1, Y1, X2, Y2, F : LongInt);
Begin
  FBar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2, F);
  Edge(X1, Y1, X2, Y2, cGray, cWhite);
  Edge(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, cBlack, cSilver);
End;

{ texte : coin haut gauche (police du systeme 8 x 16) }
Procedure OutTxt(X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := CH - Y - 16; Rc[2] := X + Length(S) * 8; Rc[3] := CH - Y;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ texte aligne a droite sur X2 }
Procedure OutRight(X2, Y : LongInt; S : String; Fg, Bg : LongInt);
Begin
  OutTxt(X2 - Length(S) * 8, Y, S, Fg, Bg);
End;

Function TextW(S : String) : LongInt;
Begin
  TextW := Length(S) * 8;
End;

{ texte tenant dans W points (points de suspension) }
Function Fit(S : String; W : LongInt) : String;
Var N : LongInt;
Begin
  N := W Div 8;
  If N < 0 Then N := 0;
  If Length(S) > N Then
  Begin
    If N > 3 Then S := Copy(S, 1, N - 3) + '...' Else S := Copy(S, 1, N);
  End;
  Fit := S;
End;

{ triangle : Dir 1 bas, 2 haut }
Procedure Arrow(X, Y, Dir, C : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 3 Do
    If Dir = 1 Then HLine(X + I, X + 6 - I, Y + I, C)
    Else HLine(X + 3 - I, X + 3 + I, Y + I, C);
End;

{ --- icones de Pasdows 95 : grille de 32 x 32 mise a l'echelle S --- }

Function IcP(V : LongInt) : LongInt;
Begin
  IcP := V * IcS Div 32;
End;

Procedure QR(X1, Y1, X2, Y2, C : LongInt);
Begin
  FBar(IcX + IcP(X1), IcY + IcP(Y1), IcX + IcP(X2 + 1) - 1, IcY + IcP(Y2 + 1) - 1, C);
End;

Procedure QB(X1, Y1, X2, Y2, C : LongInt);
Begin
  Box(IcX + IcP(X1), IcY + IcP(Y1), IcX + IcP(X2 + 1) - 1, IcY + IcP(Y2 + 1) - 1, C);
End;

Procedure QL(X1, Y1, X2, Y2, C : LongInt);
Begin
  DLine(IcX + IcP(X1), IcY + IcP(Y1), IcX + IcP(X2), IcY + IcP(Y2), C);
End;

Function ISqrt(V : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  While (R + 1) * (R + 1) <= V Do Inc(R);
  ISqrt := R;
End;

Procedure QD(CX, CY, R, C : LongInt);
Var X, Y, Rr, Dy, W : LongInt;
Begin
  X := IcX + IcP(CX); Y := IcY + IcP(CY); Rr := IcP(R);
  For Dy := -Rr To Rr Do
  Begin
    W := ISqrt(Rr * Rr - Dy * Dy);
    HLine(X - W, X + W, Y + Dy, C);
  End;
End;

Procedure QC(CX, CY, R, C : LongInt);
Var X, Y, Rr, Dy, W, Pw : LongInt;
Begin
  X := IcX + IcP(CX); Y := IcY + IcP(CY); Rr := IcP(R);
  Pw := 0;
  For Dy := 0 To Rr Do
  Begin
    W := ISqrt(Rr * Rr - Dy * Dy);
    If Dy = 0 Then Pw := W;
    HLine(X + W, X + MaxI(W, Pw - 1), Y + Dy, C); HLine(X - MaxI(W, Pw - 1), X - W, Y + Dy, C);
    HLine(X + W, X + MaxI(W, Pw - 1), Y - Dy, C); HLine(X - MaxI(W, Pw - 1), X - W, Y - Dy, C);
    Pw := W;
  End;
End;

Procedure IFrame(X1, Y1, X2, Y2, F : LongInt);
Begin
  QR(X1, Y1, X2, Y2, F);
  QB(X1, Y1, X2, Y2, cBlack);
End;

Procedure IconMonitor(Screen : LongInt);
Begin
  IFrame(4, 2, 27, 21, cSilver);
  QR(5, 3, 26, 3, cWhite);
  IFrame(7, 5, 24, 17, Screen);
  IFrame(11, 22, 20, 24, cSilver);
End;

Procedure IconFolder(C : LongInt);
Begin
  IFrame(3, 6, 13, 10, C);
  IFrame(3, 9, 28, 27, C);
  QR(4, 10, 27, 10, cWhite);
End;

Procedure IconPage;
Begin
  IFrame(6, 2, 25, 29, cWhite);
  QR(20, 2, 25, 7, cSilver);
  QL(20, 2, 25, 7, cBlack);
End;

Procedure PaintIcon(Id, X, Y, S : LongInt);
Var I : LongInt;
Begin
  IcX := X; IcY := Y; IcS := S;
  Case Id Of
    icComputer :
    Begin
      IconMonitor(cTeal);
      IFrame(2, 25, 29, 29, cSilver);
      QR(5, 27, 26, 27, cGray);
    End;
    icDisplay :
    Begin
      IconMonitor(cBlue);
      QR(8, 12, 23, 16, cGreen);
      QD(19, 9, 3, cYellow);
    End;
    icText :
    Begin
      IconPage;
      For I := 0 To 4 Do QR(9, 10 + I * 4, 22, 10 + I * 4, cGray);
    End;
    icFolder : IconFolder(cYellow);
    icDocs :
    Begin
      IconPage;
      QR(9, 10, 22, 13, cNavy);
      For I := 0 To 2 Do QR(9, 17 + I * 4, 22, 17 + I * 4, cGray);
    End;
    icCdrom :
    Begin
      IFrame(3, 14, 28, 25, cSilver);
      QR(6, 20, 25, 21, cBlack);
      QR(22, 16, 25, 17, cLime);
      QD(16, 8, 7, cSilver);
      QC(16, 8, 7, cGray);
      QD(16, 8, 2, cWhite);
      QL(12, 4, 15, 7, cAqua);
    End;
    icNetDrive :
    Begin
      { disque dur et son cable reseau }
      IFrame(3, 6, 28, 17, cSilver);
      QR(4, 7, 27, 7, cWhite);
      QR(6, 13, 12, 14, cGray);
      QR(23, 14, 25, 15, cLime);
      QR(15, 18, 16, 24, cBlack);
      QR(3, 25, 28, 26, cBlack);
      QR(13, 23, 18, 28, cNavy);
    End;
    icFloppy, icHardDisk :
    Begin
      IFrame(3, 12, 28, 23, cSilver);
      QR(4, 13, 27, 13, cWhite);
      If Id = icFloppy Then QR(8, 17, 23, 18, cBlack)
      Else QR(6, 19, 12, 20, cGray);
      QR(23, 20, 25, 21, cLime);
    End;
    icWeb :
    Begin
      QD(16, 16, 13, cBlue);
      QR(9, 8, 15, 12, cGreen); QR(8, 12, 13, 15, cGreen);
      QR(18, 17, 24, 22, cGreen); QR(20, 22, 22, 25, cGreen);
      QR(5, 18, 8, 20, cGreen); QR(19, 6, 22, 8, cWhite);
      QC(16, 16, 13, cNavy);
    End;
    icSound :
    Begin
      IconPage;
      QR(9, 12, 13, 20, cGray);
      QL(13, 12, 18, 7, cBlack); QL(13, 20, 18, 25, cBlack); QL(18, 7, 18, 25, cBlack);
      QR(20, 13, 21, 19, cNavy);
    End;
    icApp :
    Begin
      IFrame(3, 6, 28, 26, cSilver);
      QR(4, 7, 27, 10, cNavy);
      QR(4, 11, 27, 25, cWhite);
    End;
    icExplorer :
    Begin
      IconFolder(cYellow);
      QD(19, 18, 6, cAqua);
      QC(19, 18, 6, cNavy);
      QL(14, 23, 9, 28, cBlack);
      QL(15, 23, 10, 28, cBlack);
    End;
  End;
End;

{ ==================================================================== }
{ Arbre des dossiers                                                    }
{ ==================================================================== }

{ sous-dossiers de P dans DirNames (ordre alphabetique, 128 au plus) }
Procedure ListDirNames(P : String; Var N : LongInt);
Var H, C, Off, A, K, J, Rc : LongInt; S, T : String;
Begin
  N := 0;
  H := -1; C := 1;
  Rc := DosFindFirst(Z(P + '\*.*'), LongInt(@H), $37, LongInt(@FindBuf), 4096, LongInt(@C), 1);
  While (Rc = 0) And (C > 0) Do
  Begin
    Off := 0;
    While C > 0 Do
    Begin
      A := RdL(LongInt(@FindBuf) + Off + 24);
      S := '';
      For K := 0 To RdB(LongInt(@FindBuf) + Off + 28) - 1 Do S := S + Chr(RdB(LongInt(@FindBuf) + Off + 29 + K));
      If ((A And $10) <> 0) And (S <> '.') And (S <> '..') And (S <> '') And (N < 128) And (Length(S) <= 40) Then
      Begin
        DirNames[N] := S;
        Inc(N);
      End;
      Dec(C);
      If RdL(LongInt(@FindBuf) + Off) = 0 Then C := 0
      Else Off := Off + RdL(LongInt(@FindBuf) + Off);
    End;
    C := 1;
    Rc := DosFindNext(H, LongInt(@FindBuf), 4096, LongInt(@C));
  End;
  If H <> -1 Then Dummy := DosFindClose(H);
  For J := 1 To N - 1 Do
  Begin
    T := DirNames[J]; K := J - 1;
    While (K >= 0) And (UpStr(DirNames[K]) > UpStr(T)) Do
    Begin
      DirNames[K + 1] := DirNames[K];
      Dec(K);
    End;
    DirNames[K + 1] := T;
  End;
End;

Function TreeW : LongInt;
Begin
  TreeW := MaxI(110, MinI(230, (CW * 2) Div 5));
End;

Function PathTitle(P : String) : String;
Begin
  If P = '' Then PathTitle := L('Poste de travail', 'My Computer', 'Arbeitsplatz', 'Risorse del computer', 'Mi PC')
  Else If P = '*' Then PathTitle := L('Bureau', 'Desktop', 'Desktop', 'Desktop', 'Escritorio')
  Else If Length(P) = 2 Then PathTitle := DriveName(P[1])
  Else PathTitle := BaseName(P);
End;

Procedure SetTitle;
Begin
  Dummy := WinSetWindowText(Frame, Z(AppName + ' - ' + PathTitle(CurPath)));
End;

Procedure NodeCopy(Dst, Src : LongInt);
Begin
  NdP[Dst] := NdP[Src]; NdD[Dst] := NdD[Src]; NdF[Dst] := NdF[Src];
End;

Procedure TreeIns(At : LongInt; P : String; D : LongInt);
Var I : LongInt;
Begin
  If TN >= TreeMax Then Exit;
  For I := TN - 1 DownTo At Do NodeCopy(I + 1, I);
  NdP[At] := P; NdD[At] := D; NdF[At] := 0;
  Inc(TN);
  If TSel >= At Then Inc(TSel);
End;

{ deplier le noeud I : ses sous-dossiers (ordre alphabetique) ou, pour le
  Poste de travail, les lecteurs }
Procedure TreeExpand(I : LongInt);
Var K, N, M, D : LongInt; P : String;
Begin
  If (NdF[I] And 3) <> 0 Then Exit;
  NdF[I] := NdF[I] Or 1;
  P := NdP[I];
  If P = '*' Then Exit;
  D := NdD[I] + 1;
  M := 0;
  If P = '' Then
  Begin
    For K := 0 To 25 Do
      If (DrvMap And (1 Shl K)) <> 0 Then
      Begin
        TreeIns(I + 1 + M, Chr(65 + K) + ':', D);
        Inc(M);
      End;
  End
  Else
  Begin
    { sous-dossiers (le contenu affiche est garde a part) }
    ListDirNames(P, N);
    For K := 0 To N - 1 Do
      If Length(P) + 1 + Length(DirNames[K]) <= 79 Then
      Begin
        TreeIns(I + 1 + M, P + '\' + DirNames[K], D);
        Inc(M);
      End;
  End;
  If M = 0 Then NdF[I] := 2;
End;

Procedure TreeCollapse(I : LongInt);
Var J, K, D : LongInt;
Begin
  D := NdD[I];
  J := I + 1;
  While (J < TN) And (NdD[J] > D) Do Inc(J);
  K := J - I - 1;
  If K > 0 Then
  Begin
    If (TSel > I) And (TSel < J) Then TSel := I
    Else If TSel >= J Then TSel := TSel - K;
    For J := I + 1 To TN - 1 - K Do NodeCopy(J, J + K);
    TN := TN - K;
  End;
  NdF[I] := NdF[I] And Not 1;
End;

Function TreeFind(P : String) : LongInt;
Var I, R : LongInt; U : String;
Begin
  R := -1; U := UpStr(P);
  For I := 0 To TN - 1 Do
    If (R < 0) And (UpStr(NdP[I]) = U) Then R := I;
  TreeFind := R;
End;

{ l'arbre suit le dossier affiche : branches depliees, noeud choisi visible }
Procedure TreeSync;
Var P, Cur, Rest, C : String; I, J, K : LongInt;
Begin
  P := CurPath;
  I := TreeFind('');
  If I < 0 Then Exit;
  If P <> '' Then
  Begin
    TreeExpand(I);
    Cur := Copy(P, 1, 2);
    J := TreeFind(Cur);
    If J >= 0 Then
    Begin
      I := J;
      Rest := Copy(P, 4, 255);
      While Rest <> '' Do
      Begin
        TreeExpand(I);
        K := Pos('\', Rest);
        If K = 0 Then K := Length(Rest) + 1;
        C := Copy(Rest, 1, K - 1);
        Rest := Copy(Rest, K + 1, 255);
        Cur := Cur + '\' + C;
        J := TreeFind(Cur);
        If J < 0 Then Rest := ''
        Else I := J;
      End;
    End;
  End;
  TSel := I;
  If TVis < 1 Then TVis := 10;
  If TSel < TTop Then TTop := TSel;
  If TSel >= TTop + TVis Then TTop := TSel - TVis + 1;
End;

Procedure TreeInit;
Begin
  TN := 0; TTop := 0; TSel := 0; TVis := 10;
  TreeIns(0, '*', 0);
  NdF[0] := 1;
  TreeIns(1, '', 1);
  TreeExpand(1);
End;

{ le noeud R a-t-il un frere apres lui au niveau D ? (traits) }
Function TreeNext(R, D : LongInt) : Boolean;
Var J : LongInt;
Begin
  J := R + 1;
  While (J < TN) And (NdD[J] > D) Do Inc(J);
  TreeNext := (J < TN) And (NdD[J] = D);
End;

Procedure DotV(X, Y1, Y2 : LongInt);
Var Y : LongInt;
Begin
  Y := Y1;
  While Y <= Y2 Do
  Begin
    If ((X + Y) And 1) = 0 Then Pix(X, Y, cGray);
    Inc(Y);
  End;
End;

Procedure DotH(X1, X2, Y : LongInt);
Var X : LongInt;
Begin
  For X := X1 To X2 Do
    If ((X + Y) And 1) = 0 Then Pix(X, Y, cGray);
End;

{ barre de defilement verticale de Windows 95 (X : bord gauche) }
Procedure VScroll(X, Y1, Y2, Pos, Max : LongInt);
Var TY : LongInt;
Begin
  FBar(X, Y1, X + SbW - 2, Y2, cSilver);
  Raised(X, Y1, X + SbW - 2, Y1 + 15, True);
  Arrow(X + 4, Y1 + 6, 2, cBlack);
  Raised(X, Y2 - 15, X + SbW - 2, Y2, True);
  Arrow(X + 4, Y2 - 9, 1, cBlack);
  If (Max > 0) And (Y2 - Y1 > 50) Then
  Begin
    TY := Y1 + 16 + (Pos * (Y2 - Y1 - 48)) Div Max;
    Raised(X, TY, X + SbW - 2, TY + 16, True);
  End;
End;

{ clic dans une barre : -1 ligne, +1 ligne, -2 page, +2 page }
Function ScrollHit(Y, Y1, Y2, Pos, Max : LongInt) : LongInt;
Var TY : LongInt;
Begin
  If Y <= Y1 + 15 Then ScrollHit := -1
  Else If Y >= Y2 - 15 Then ScrollHit := 1
  Else
  Begin
    TY := Y1 + 16;
    If Max > 0 Then TY := Y1 + 16 + (Pos * (Y2 - Y1 - 48)) Div Max;
    If Y < TY Then ScrollHit := -2 Else ScrollHit := 2;
  End;
End;

Function NodeIcon(P : String) : LongInt;
Begin
  If P = '*' Then NodeIcon := icDisplay
  Else If P = '' Then NodeIcon := icComputer
  Else If Length(P) = 2 Then
  Begin
    Case DrvKind[Ord(UpCase(P[1])) - 65] Of
      ekCd : NodeIcon := icCdrom;
      ekFloppy : NodeIcon := icFloppy;
      ekNet : NodeIcon := icNetDrive;
    Else
      NodeIcon := icHardDisk;
    End;
  End
  Else NodeIcon := icFolder;
End;

Procedure PaintTree(X1, Y1, X2, Y2 : LongInt);
Var R, Y, D, C, K, Fg, Bg, XR : LongInt; Nm : String; Sb : Boolean;
Begin
  Sunken(X1, Y1, X2, Y2, cWhite);
  TVis := MaxI(1, (Y2 - Y1 - 4) Div TreeRow);
  If TTop > MaxI(0, TN - TVis) Then TTop := MaxI(0, TN - TVis);
  If TTop < 0 Then TTop := 0;
  Sb := TN > TVis;
  XR := X2 - 2;
  If Sb Then XR := X2 - 2 - SbW;
  For R := TTop To MinI(TN - 1, TTop + TVis - 1) Do
  Begin
    Y := Y1 + 2 + (R - TTop) * TreeRow;
    D := NdD[R];
    { traits pointilles des niveaux superieurs, puis vers l'icone }
    For K := 1 To D - 1 Do
      If TreeNext(R, K) Then DotV(X1 + 4 + K * 16 - 8, Y, Y + TreeRow - 1);
    C := X1 + 4 + D * 16 - 8;
    If D >= 1 Then
    Begin
      DotV(C, Y, Y + 8);
      If TreeNext(R, D) Then DotV(C, Y + 8, Y + TreeRow - 1);
      DotH(C, C + 7, Y + 8);
      If (NdF[R] And 2) = 0 Then
      Begin
        { case + / - }
        FBar(C - 4, Y + 4, C + 4, Y + 12, cWhite);
        Box(C - 4, Y + 4, C + 4, Y + 12, cGray);
        HLine(C - 2, C + 2, Y + 8, cBlack);
        If (NdF[R] And 1) = 0 Then VLine(C, Y + 6, Y + 10, cBlack);
      End;
    End;
    If C + 24 < XR Then PaintIcon(NodeIcon(NdP[R]), C + 8, Y + 1, 16);
    Nm := Fit(PathTitle(NdP[R]), XR - C - 30);
    Fg := cBlack; Bg := cWhite;
    If R = TSel Then
    Begin
      If Focus = 1 Then Bg := cNavy Else Bg := cGray;
      Fg := cWhite;
      If Nm <> '' Then FBar(C + 26, Y, C + 29 + TextW(Nm), Y + 16, Bg);
    End;
    OutTxt(C + 28, Y, Nm, Fg, Bg);
  End;
  If Sb Then VScroll(X2 - 1 - SbW, Y1 + 2, Y2 - 2, TTop, TN - TVis);
End;

{ ==================================================================== }
{ Contenu                                                               }
{ ==================================================================== }

Var
  PX1, PY1, PX2, PY2 : LongInt;    { volet du contenu (cadre en creux) }
  TX1, TY1, TX2, TY2 : LongInt;    { volet de l'arbre }

Procedure Geometry;
Var Tw : LongInt;
Begin
  Tw := TreeW;
  TX1 := 0; TY1 := 22; TX2 := Tw; TY2 := CH - 23;
  PX1 := Tw + 3; PY1 := 22; PX2 := CW - 1; PY2 := CH - 23;
End;

{ colonnes et lignes visibles du contenu }
Function Cols : LongInt;
Begin
  If View = 1 Then Cols := 1
  Else Cols := MaxI(1, (PX2 - PX1 - 8 - SbW) Div CellW);
End;

Function VisRows : LongInt;
Begin
  If View = 1 Then VisRows := MaxI(1, (PY2 - PY1 - 24) Div RowH)
  Else VisRows := MaxI(1, (PY2 - PY1 - 8) Div CellH);
End;

Function TotRows : LongInt;
Begin
  TotRows := (NEnt + Cols - 1) Div Cols;
End;

Procedure ClampTop;
Begin
  If Top > TotRows - VisRows Then Top := TotRows - VisRows;
  If Top < 0 Then Top := 0;
End;

{ le choix reste visible }
Procedure ShowSel;
Var R : LongInt;
Begin
  If Sel < 0 Then Exit;
  R := Sel Div Cols;
  If R < Top Then Top := R;
  If R >= Top + VisRows Then Top := R - VisRows + 1;
  ClampTop;
End;

{ etiquette d'une icone : deux lignes de 12 caracteres au plus, centrees }
Procedure DrawLabel(X, Y, W : LongInt; S : String; IsSel : Boolean);
Var A, B : String; N, K, Fg, Bg : LongInt;
Begin
  N := W Div 8;
  If Length(S) <= N Then
  Begin
    A := S; B := '';
  End
  Else
  Begin
    K := N;
    While (K > 1) And (S[K] <> ' ') And (S[K] <> '-') And (S[K] <> '.') And (S[K] <> '_') Do Dec(K);
    If K <= 1 Then K := N;
    A := Copy(S, 1, K);
    B := Fit(Copy(S, K + 1, 255), W);
    While (A <> '') And (A[Length(A)] = ' ') Do Delete(A, Length(A), 1);
  End;
  Fg := cBlack; Bg := cWhite;
  If IsSel Then
  Begin
    Fg := cWhite;
    If Focus = 0 Then Bg := cNavy Else Bg := cGray;
  End;
  If IsSel Then FBar(X + (W - TextW(A)) Div 2 - 1, Y, X + (W + TextW(A)) Div 2, Y + 15, Bg);
  OutTxt(X + (W - TextW(A)) Div 2, Y, A, Fg, Bg);
  If B <> '' Then
  Begin
    If IsSel Then FBar(X + (W - TextW(B)) Div 2 - 1, Y + 16, X + (W + TextW(B)) Div 2, Y + 31, Bg);
    OutTxt(X + (W - TextW(B)) Div 2, Y + 16, B, Fg, Bg);
  End;
End;

Function SizeCol(I : LongInt) : String;
Begin
  If E(I)^.Kind <> ekFile Then SizeCol := ''
  Else SizeCol := Thousands((E(I)^.Size + 1023) Div 1024) + L(' Ko', ' KB', ' KB', ' KB', ' KB');
End;

Procedure PaintContents;
Var CX, CY, X, Y, I, R, C, N, NC, VR, W1, W2, W3, W4, XR, Fg, Bg : LongInt; S : String; Sb : Boolean;
Begin
  Sunken(PX1, PY1, PX2, PY2, cWhite);
  CX := PX1; CY := PY1;
  ClampTop;
  NC := Cols; VR := VisRows;
  Sb := TotRows > VR;
  XR := PX2 - 2;
  If Sb Then XR := PX2 - 2 - SbW;
  If View = 1 Then
  Begin
    { Details : en-tetes de colonnes, une ligne par objet }
    { colonnes selon la largeur : Nom et Taille, puis Type, puis Modifie ;
      le nom prend le reste }
    W2 := 88; W3 := 0; W4 := 0;
    If XR - CX - 4 >= 136 + W2 + 104 Then W3 := 104;
    If XR - CX - 4 >= 150 + W2 + 170 + 136 Then W3 := 170;
    If XR - CX - 4 >= 150 + W2 + W3 + 136 Then W4 := 136;
    W1 := MaxI(120, XR - CX - 4 - W2 - W3 - W4);
    Raised(CX + 2, CY + 2, CX + 2 + W1 - 1, CY + 19, True);
    OutTxt(CX + 6, CY + 3, Fit(L('Nom', 'Name', 'Name', 'Nome', 'Nombre'), W1 - 8), cBlack, cSilver);
    If CX + 2 + W1 + W2 <= XR Then
    Begin
      Raised(CX + 2 + W1, CY + 2, CX + 1 + W1 + W2, CY + 19, True);
      OutRight(CX + W1 + W2 - 4, CY + 3, L('Taille', 'Size', 'Gr'#148#225'e', 'Dim.', 'Tama'#164'o'), cBlack, cSilver);
    End;
    If W3 > 0 Then
    Begin
      Raised(CX + 2 + W1 + W2, CY + 2, CX + 1 + W1 + W2 + W3, CY + 19, True);
      OutTxt(CX + 6 + W1 + W2, CY + 3, L('Type', 'Type', 'Typ', 'Tipo', 'Tipo'), cBlack, cSilver);
    End;
    If W4 > 0 Then
    Begin
      Raised(CX + 2 + W1 + W2 + W3, CY + 2, XR, CY + 19, True);
      OutTxt(CX + 6 + W1 + W2 + W3, CY + 3, L('Modifi'#130, 'Modified', 'Ge'#132'ndert', 'Modificato', 'Modificado'),
             cBlack, cSilver);
    End
    Else If CX + 2 + W1 + W2 + W3 < XR Then Raised(CX + 2 + W1 + W2 + W3, CY + 2, XR, CY + 19, True);
    For R := 0 To VR - 1 Do
    Begin
      I := Top + R;
      If I < NEnt Then
      Begin
        Y := CY + 21 + R * RowH;
        PaintIcon(FileIcon(E(I)^.Nm, E(I)^.Kind), CX + 5, Y + 1, 16);
        S := Fit(EntName(I), W1 - 30);
        Fg := cBlack; Bg := cWhite;
        If SelF[I] Then
        Begin
          Fg := cWhite;
          If Focus = 0 Then Bg := cNavy Else Bg := cGray;
          FBar(CX + 24, Y, CX + 27 + TextW(S), Y + 16, Bg);
        End;
        OutTxt(CX + 26, Y, S, Fg, Bg);
        If CX + 2 + W1 + W2 <= XR Then OutRight(CX + W1 + W2 - 4, Y, SizeCol(I), cBlack, cWhite);
        If W3 > 0 Then
          OutTxt(CX + 6 + W1 + W2, Y, Fit(TypeName(E(I)^.Nm, E(I)^.Kind), W3 - 8), cBlack, cWhite);
        If W4 > 0 Then
          OutTxt(CX + 6 + W1 + W2 + W3, Y, DateStr(E(I)^.FDate, E(I)^.FTime), cBlack, cWhite);
      End;
    End;
  End
  Else
  Begin
    { Grandes icones (Pasdows 95) : cellules de 100 x 70 }
    For R := 0 To VR - 1 Do
      For C := 0 To NC - 1 Do
      Begin
        I := (Top + R) * NC + C;
        If I < NEnt Then
        Begin
          X := CX + 6 + C * CellW;
          Y := CY + 6 + R * CellH;
          PaintIcon(FileIcon(E(I)^.Nm, E(I)^.Kind), X + 32, Y, 32);
          DrawLabel(X, Y + 34, CellW - 4, EntName(I), SelF[I]);
        End;
      End;
  End;
  If NEnt = 0 Then
  Begin
    If CurPath = '' Then S := ''
    Else S := L('Ce dossier est vide.', 'This folder is empty.', 'Dieser Ordner ist leer.',
                'La cartella '#138' vuota.', 'Esta carpeta est'#160' vac'#161'a.');
    OutTxt(CX + 10, CY + 30, Fit(S, XR - CX - 20), cGray, cWhite);
  End;
  If Sb Then VScroll(PX2 - 1 - SbW, PY1 + 2, PY2 - 2, Top, TotRows - VR);
End;

{ texte de la barre d'etat (partie gauche) }
Function StatusText : String;
Var S : String; Fr, Tot : Double; K, N : LongInt;
Begin
  N := SelCount;
  If N > 1 Then
  Begin
    Tot := 0;
    For K := 0 To NEnt - 1 Do
      If SelF[K] And (E(K)^.Kind = ekFile) Then Tot := Tot + GlUns(E(K)^.Size);
    S := IStr(N) + L(' objet(s) s'#130'lectionn'#130'(s)', ' object(s) selected', ' Objekt(e) markiert',
                     ' oggetti selezionati', ' objeto(s) seleccionado(s)');
    If Tot > 0 Then S := S + ' : ' + SizeKb(Tot / 1024);
  End
  Else If (Sel >= 0) And (Sel < NEnt) And SelF[Sel] Then
  Begin
    If CurPath = '' Then
    Begin
      If DriveSpace(E(Sel)^.Nm[1], Fr, Tot) Then
        S := L('Espace libre : ', 'Free Space: ', 'Freier Speicher: ', 'Spazio libero: ', 'Espacio libre: ') +
             SizeKb(Fr) + L(', capacit'#130' : ', ', Capacity: ', ', Kapazit'#132't: ', ', capacit'#133': ',
                            ', capacidad: ') + SizeKb(Tot)
      Else S := EntName(Sel);
    End
    Else If E(Sel)^.Kind = ekFile Then
      S := E(Sel)^.Nm + ' : ' + Thousands(E(Sel)^.Size) + L(' octets', ' bytes', ' Byte', ' byte', ' bytes')
    Else S := E(Sel)^.Nm;
  End
  Else
  Begin
    S := IStr(NEnt) + ' ' + L('objet(s)', 'object(s)', 'Objekt(e)', 'oggetti', 'objeto(s)');
    If Truncated Then S := S + ' (+)';
  End;
  StatusText := S;
End;

Procedure PaintAll(H : LongInt);
Var Tw : LongInt; S, S2 : String; Fr, Tot : Double;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  Geometry;
  Tw := TX2;
  { en-tetes "Tous les dossiers" et "Contenu de" }
  FBar(0, 0, CW - 1, 21, cSilver);
  Raised(0, 1, Tw, 20, False);
  OutTxt(4, 3, Fit(L('Tous les dossiers', 'All Folders', 'Alle Ordner', 'Tutte le cartelle', 'Todas las carpetas'),
                   Tw - 8), cBlack, cSilver);
  Raised(Tw + 3, 1, CW - 1, 20, False);
  OutTxt(Tw + 7, 3, Fit(L('Contenu de ''', 'Contents of ''', 'Inhalt von ''', 'Contenuto di ''', 'Contenido de ''') +
                        PathTitle(CurPath) + '''', CW - Tw - 14), cBlack, cSilver);
  FBar(Tw + 1, 22, Tw + 2, CH - 23, cSilver);
  PaintTree(TX1, TY1, TX2, TY2);
  PaintContents;
  { barre d'etat en deux parties : objets, espace libre du lecteur }
  FBar(0, CH - 22, CW - 1, CH - 1, cSilver);
  Edge(0, CH - 20, Tw, CH - 1, cGray, cWhite);
  OutTxt(4, CH - 18, Fit(StatusText, Tw - 8), cBlack, cSilver);
  Edge(Tw + 3, CH - 20, CW - 1, CH - 1, cGray, cWhite);
  S2 := '';
  If (CurPath <> '') And DriveSpace(CurPath[1], Fr, Tot) Then
    S2 := L('Espace disque libre : ', 'Disk free space: ', 'Freier Speicher: ', 'Spazio libero: ', 'Espacio libre: ') +
          SizeKb(Fr);
  OutTxt(Tw + 7, CH - 18, Fit(S2, CW - Tw - 14), cBlack, cSilver);
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ ==================================================================== }
{ Navigation et ouverture                                               }
{ ==================================================================== }

Procedure Navigate(P : String);
Begin
  CurPath := P;
  ListDir(P, False);
  Sel := -1; Top := 0;
  TreeSync;
  SetTitle;
  Redraw;
End;

Procedure Refresh;
Var K, Old : LongInt; Nm : String;
Begin
  ScanDrives;
  Nm := '';
  If (Sel >= 0) And (Sel < NEnt) Then Nm := E(Sel)^.Nm;
  Old := Top;
  ListDir(CurPath, False);
  Sel := -1;
  For K := 0 To NEnt - 1 Do
    If (Nm <> '') And (E(K)^.Nm = Nm) Then SelOne(K);
  Top := Old;
  { l'arbre est reconstruit (dossiers crees ou supprimes) }
  TreeInit;
  TreeSync;
  Redraw;
End;

Procedure GoUp;
Var P : LongInt;
Begin
  If CurPath = '' Then Exit;
  If Length(CurPath) <= 2 Then Navigate('')
  Else
  Begin
    P := Length(CurPath);
    While (P > 0) And (CurPath[P] <> '\') Do Dec(P);
    Navigate(Copy(CurPath, 1, P - 1));
  End;
End;

Function Comspec : String;
Var S : String;
Begin
  S := GetEnvS('COMSPEC');
  If (S = '') Or (Pos('PMSHELL', UpStr(S)) > 0) Then S := 'C:\CMD.EXE';
  Comspec := S;
End;

{ programme d'OS/2-0 : racine de C: ou repertoire de l'interpreteur }
Function AppPath(N : String) : String;
Var S : String;
Begin
  AppPath := '';
  If FileExists('C:\' + N) Then AppPath := 'C:\' + N
  Else
  Begin
    S := Comspec;
    While (S <> '') And (S[Length(S)] <> '\') Do Delete(S, Length(S), 1);
    If (S <> '') And FileExists(S + N) Then AppPath := S + N;
  End;
End;

Procedure SetDir(Dir : String);
Begin
  If (Length(Dir) >= 2) And (Dir[2] = ':') Then
  Begin
    Dummy := DosSetDefaultDisk(Ord(UpCase(Dir[1])) - 64);
    If Length(Dir) = 2 Then Dir := Dir + '\';
    Dummy := DosSetCurrentDir(Z(Dir));
  End;
End;

{ programme de PM ou de texte : nouvelle session (comme les objets
  programme du bureau ; un programme de PM revient dans la session de
  Presentation Manager) }
Procedure RunProgram(Prog, Params, Dir : String);
Var Res : Array[0..1] Of LongInt; Rc, K, S : LongInt;
Begin
  SetDir(Dir);
  PutZ(LongInt(@ArgBuf), Prog);
  K := Length(Prog) + 1;
  PutZ(LongInt(@ArgBuf) + K, Params);
  WrB(LongInt(@ArgBuf) + K + Length(Params) + 1, 0);
  S := KSes(4, Z(UpStr(BaseName(Prog))), 0);
  If S < 0 Then
  Begin
    Msg(L('Trop de sessions : fermez un programme.', 'Too many sessions: close a program.',
          'Zu viele Sitzungen: Programm schlie'#225'en.', 'Troppe sessioni: chiudere un programma.',
          'Demasiadas sesiones: cierre un programa.'), MB_OK Or MB_WARNING);
    Exit;
  End;
  Dummy := KSes(16, S, 1);
  Dummy := KSes(12, S, 0);
  PutZ(LongInt(@NameZ2), Prog);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), LongInt(@NameZ2));
  If Rc <> 0 Then
  Begin
    Dummy := KSes(12, -1, 0);
    Dummy := KSes(17, S, 0);
    Msg('SYS1041: ' + L('Impossible de lancer ', 'Cannot start ', 'Kann nicht starten: ', 'Impossibile avviare ',
        'No se puede iniciar ') + Prog + ' (' + IStr(Rc) + ').', MB_OK Or MB_ERROR);
  End
  Else Dummy := KSes(3, S, 0);
End;

{ application de PM dans la session de Presentation Manager }
{ argument d'un chemin avec des espaces : entre guillemets (le runtime
  d'OS2PC et CMD.EXE en font un seul parametre) }
Function QArg(S : String) : String;
Begin
  If (Pos(' ', S) > 0) And (Copy(S, 1, 1) <> '"') Then QArg := '"' + S + '"' Else QArg := S;
End;

Procedure RunPm(P, Params : String);
Var Res : Array[0..1] Of LongInt; Rc : LongInt;
Begin
  PutZ(LongInt(@ArgBuf), P);
  PutZ(LongInt(@ArgBuf) + Length(P) + 1, Params);
  WrB(LongInt(@ArgBuf) + Length(P) + Length(Params) + 2, 0);
  PutZ(LongInt(@NameZ2), P);
  Res[0] := 0; Res[1] := 0;
  Rc := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), LongInt(@NameZ2));
  If Rc <> 0 Then
    Msg('SYS1041: ' + L('Impossible de lancer ', 'Cannot start ', 'Kann nicht starten: ', 'Impossibile avviare ',
        'No se puede iniciar ') + P + ' (' + IStr(Rc) + ').', MB_OK Or MB_ERROR);
End;

{ programme de Presentation Manager ? En-tete LX/LE (indicateurs du
  module : 300h, application PM), NE (type d'application 300h) ou PE
  (table d'importation : PMWIN, PMGPI ou PMMERGE). Un tel programme est
  lance dans la session de PM, comme les objets du bureau : une nouvelle
  session plein ecran passerait l'ecran en mode texte puis le rendrait a
  PM aussitot (affichage perdu en 1024 x 768 x 32 bits). }
Var
  PmH, PmNSec, PmOptEnd : LongInt;
  PmB : Array[0..255] Of Byte;

Function PmReadAt(Pos, N : LongInt) : Boolean;
Var A : LongInt;
Begin
  A := 0;
  PmReadAt := False;
  If DosSetFilePtr(PmH, Pos, 0, LongInt(@A)) <> 0 Then Exit;
  A := 0;
  If DosRead(PmH, LongInt(@PmB), N, LongInt(@A)) <> 0 Then Exit;
  PmReadAt := A = N;
End;

Function PmW(I : LongInt) : LongInt;
Begin
  PmW := PmB[I] Or (PmB[I + 1] Shl 8);
End;

Function PmD(I : LongInt) : LongInt;
Begin
  PmD := PmW(I) Or (PmW(I + 2) Shl 16);
End;

{ deplacement dans le fichier d'une adresse virtuelle relative (PE) }
Function PmFileOfs(R : LongInt) : LongInt;
Var I, VS, VA, Raw, RS : LongInt;
Begin
  PmFileOfs := -1;
  For I := 0 To PmNSec - 1 Do
    If PmReadAt(PmOptEnd + I * 40, 40) Then
    Begin
      VS := PmD(8); VA := PmD(12); RS := PmD(16); Raw := PmD(20);
      If VS < RS Then VS := RS;
      If (R >= VA) And (R < VA + VS) Then
      Begin
        PmFileOfs := R - VA + Raw;
        Exit;
      End;
    End;
End;

Function IsPmProgram(Path : String) : Boolean;
Var A, Ne, Imp, Off, K, J, Rva, NmOff, Opt : LongInt; S : String; R : Boolean;
Begin
  IsPmProgram := False;
  R := False;
  PmH := 0; A := 0;
  If DosOpen(Z(Path), LongInt(@PmH), LongInt(@A), 0, 0, 1, $40, 0) <> 0 Then Exit;
  If PmReadAt(0, 64) And (PmB[0] = Ord('M')) And (PmB[1] = Ord('Z')) Then
  Begin
    Ne := PmD($3C);
    If (Ne > 0) And PmReadAt(Ne, 248) Then
    Begin
      If (PmB[0] = Ord('L')) And ((PmB[1] = Ord('X')) Or (PmB[1] = Ord('E'))) Then
        R := (PmD($10) And $700) = $300
      Else If (PmB[0] = Ord('N')) And (PmB[1] = Ord('E')) Then
        R := (PmW($0C) And $300) = $300
      Else If (PmB[0] = Ord('P')) And (PmB[1] = Ord('E')) And (PmB[2] = 0) And (PmB[3] = 0) Then
      Begin
        PmNSec := PmW(6); Opt := Ne + 24; PmOptEnd := Opt + PmW(20);
        If PmW(24) = $20B Then Imp := PmD(24 + 120) Else Imp := PmD(24 + 104);
        Off := -1;
        If (Imp <> 0) And (PmNSec > 0) And (PmNSec < 64) Then Off := PmFileOfs(Imp);
        K := 0;
        While (Off > 0) And (K < 64) Do
        Begin
          If Not PmReadAt(Off + K * 20, 20) Then K := 64
          Else
          Begin
            Rva := PmD(12);
            If Rva = 0 Then K := 64
            Else
            Begin
              NmOff := PmFileOfs(Rva);
              S := '';
              If (NmOff > 0) And PmReadAt(NmOff, 16) Then
              Begin
                J := 0;
                While (J < 16) And (PmB[J] <> 0) Do
                Begin
                  S := S + UpCase(Chr(PmB[J]));
                  Inc(J);
                End;
              End;
              If (Copy(S, 1, 5) = 'PMWIN') Or (Copy(S, 1, 5) = 'PMGPI') Or (Copy(S, 1, 7) = 'PMMERGE') Then
              Begin
                R := True;
                K := 64;
              End;
              Inc(K);
            End;
          End;
        End;
      End;
    End;
  End;
  Dummy := DosClose(PmH);
  IsPmProgram := R;
End;


Procedure OpenFile(P : String);
Var X, A : String;
Begin
  X := ExtOf(P);
  If (X = 'EXE') And IsPmProgram(P) Then
  Begin
    SetDir(CurPath);
    RunPm(P, '');
  End
  Else If (X = 'EXE') Or (X = 'COM') Then RunProgram(P, '', CurPath)
  Else If (X = 'CMD') Or (X = 'BAT') Then RunProgram(Comspec, '/C ' + QArg(P), CurPath)
  Else
  Begin
    A := '';
    If ((X = 'DOC') Or (X = 'DOCX') Or (X = 'WPD') Or (X = 'GAT') Or (X = 'GPX') Or (X = 'PDF')) And
       (AppPath('WORDIUM.EXE') <> '') Then
    Begin
      { document : WorDium (ses boites Ouvrir et Enregistrer montrent ce dossier) }
      A := AppPath('WORDIUM.EXE');
      SetDir(CurPath);
    End
    Else If ((X = 'XLC') Or (X = 'XLS') Or (X = 'XLSX')) And (AppPath('EXCELSIO.EXE') <> '') Then
    Begin
      { classeur : Excelsior (ses boites Ouvrir et Enregistrer montrent ce dossier) }
      A := AppPath('EXCELSIO.EXE');
      SetDir(CurPath);
    End
    Else If (X = 'TXT') Or (X = 'PAS') Or (X = 'INI') Or (X = 'SYS') Or (X = 'LOG') Or (X = 'CFG') Or (X = 'ME') Or
       (X = 'INC') Or (X = 'ASM') Or (X = 'DOC') Or (X = '') Then A := AppPath('PASDEV.EXE')
    Else If X = 'WAV' Then A := AppPath('DIGAUDIO.EXE')
    Else If (X = 'MP3') Or (X = 'M3U') Or (X = 'PLS') Then
    Begin
      { Lecteur MP3 : sa liste de lecture part de ce dossier }
      A := AppPath('MP3PLAY.EXE');
      If A <> '' Then SetDir(CurPath);
    End
    Else If (X = 'SON') Or (X = 'MID') Then
    Begin
      { Notator : ses boites Charger et Sauver montrent ce dossier }
      A := AppPath('NOTATOR.EXE');
      If A <> '' Then SetDir(CurPath);
    End
    Else If (X = 'HTM') Or (X = 'HTML') Then A := AppPath('BROWSER.EXE')
    Else If (X = 'BMP') Or (X = 'PCX') Or (X = 'GIF') Or (X = 'PNG') Or (X = 'JPG') Or (X = 'JPE') Or
            (X = 'TIF') Or (X = 'ICO') Or (X = 'CUR') Or (X = 'PPM') Or (X = 'LBM') Or (X = 'DIB') Then
    Begin
      { image : Paint (ses boites Ouvrir et Enregistrer montrent ce dossier) }
      A := AppPath('PAINT.EXE');
      If A <> '' Then SetDir(CurPath);
    End;
    If A <> '' Then RunPm(A, QArg(P))
    Else
      Msg(L('Aucune application n''est associ'#130'e '#133' ce fichier :', 'No application is associated with ' +
            'this file:', 'Dieser Datei ist keine Anwendung zugeordnet:', 'Nessuna applicazione associata al ' +
            'file:', 'Ning'#163'n programa asociado a este archivo:') + Chr(10) + P, MB_OK Or MB_INFORMATION);
  End;
End;

Procedure OpenItem(I : LongInt);
Begin
  If (I < 0) Or (I >= NEnt) Then Exit;
  If E(I)^.Kind = ekFile Then OpenFile(EntPath(I))
  Else Navigate(EntPath(I));
End;

{ ==================================================================== }
{ Proprietes d'un lecteur : comme la boite de Pasdows 95, onglets      }
{ General (nom du volume, type, espace utilise et libre, capacite,      }
{ camembert en relief), Outils et Partage ; OK, Annuler, Appliquer.    }
{ La fenetre est independante (l'Explorateur reste utilisable) ;       }
{ EXPLORER /PROPS:C: l'ouvre seule (dossier Lecteurs du bureau).       }
{ ==================================================================== }

Const
  PW = 440; PH = 408;            { zone client }
  cFuchsia = 3; cPurple = 11;    { CLR_PINK, CLR_DARKPINK }
  PropTop = 27; PropBot = 364;   { cadre des onglets }
  ID_PROPS = 1;

Function DosSetFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';

Var
  PFrame, PClient, PCH, PTab, PCaretOn : LongInt;
  PDrive : Char;
  PLabel, PLabel0 : String;
  PFree, PTot : Double;
  PEdit, PDirty, PAlone : Boolean;

{ nombre (Double) avec separateur des milliers }
Function ThousandsD(V : Double) : String;
Var R, T, Sep : String; I, D : LongInt; Q : Double;
Begin
  If V < 0 Then V := 0;
  V := Int(V + 0.5);
  R := '';
  Repeat
    Q := Int(V / 10);
    D := Round(V - Q * 10);
    If D < 0 Then D := 0;
    If D > 9 Then D := 9;
    R := Chr(48 + D) + R;
    V := Q;
  Until V < 1;
  Sep := L(' ', ',', '.', '.', '.');
  T := '';
  For I := 1 To Length(R) Do
  Begin
    T := T + R[I];
    If ((Length(R) - I) Mod 3 = 0) And (I < Length(R)) Then T := T + Sep;
  End;
  ThousandsD := T;
End;

{ taille courte : Ko, Mo (une decimale), Go (deux decimales) }
Function ShortSize(Kb : Double) : String;
Var V : LongInt; S, Dc : String;
Begin
  Dc := L(',', '.', ',', ',', ',');
  If Kb < 1024 Then S := IStr(Round(Kb)) + L(' Ko', ' KB', ' KB', ' KB', ' KB')
  Else If Kb < 1048576 Then
  Begin
    V := Round(Kb / 102.4);
    S := IStr(V Div 10) + Dc + IStr(V Mod 10) + L(' Mo', ' MB', ' MB', ' MB', ' MB');
  End
  Else
  Begin
    V := Round(Kb / 10485.76);
    S := IStr(V Mod 100);
    If Length(S) < 2 Then S := '0' + S;
    S := IStr(V Div 100) + Dc + S + L(' Go', ' GB', ' GB', ' GB', ' GB');
  End;
  ShortSize := S;
End;

Function PropDisk : LongInt;
Begin
  PropDisk := Ord(UpCase(PDrive)) - 64;
End;

{ nom du volume modifiable : disque dur ou disque virtuel }
Function PropWritable : Boolean;
Var K : LongInt;
Begin
  K := PropDisk - 1;
  PropWritable := (K >= 2) And (K <= 25) And (DrvKind[K] = ekHdd);
End;

Function PropTypeText : String;
Var K : LongInt; S : String;
Begin
  K := PropDisk - 1;
  If DrvKind[K] = ekCd Then S := L('Disque CD-ROM', 'CD-ROM Disc', 'CD-ROM', 'Disco CD-ROM', 'Disco CD-ROM')
  Else If DrvKind[K] = ekNet Then S := L('Lecteur r'#130'seau', 'Network Drive', 'Netzlaufwerk', 'Unit'#133' di rete',
                                         'Unidad de red')
  Else If DrvKind[K] = ekFloppy Then S := L('Disquette', 'Floppy Disk', 'Diskette', 'Dischetto', 'Disquete')
  Else If UpStr(DrvLbl[K]) = 'RAMDISK' Then
    S := L('Disque virtuel', 'RAM Disk', 'RAM-Laufwerk', 'Disco virtuale', 'Disco virtual')
  Else S := L('Disque local', 'Local Disk', 'Lokaler Datentr'#132'ger', 'Disco locale', 'Disco local');
  If DrvFs[K] <> '' Then S := S + ' (' + DrvFs[K] + ')';
  PropTypeText := S;
End;

Function PropTabName(I : LongInt) : String;
Begin
  Case I Of
    0 : PropTabName := L('G'#130'n'#130'ral', 'General', 'Allgemein', 'Generale', 'General');
    1 : PropTabName := L('Outils', 'Tools', 'Extras', 'Strumenti', 'Herramientas');
  Else
    PropTabName := L('Partage', 'Sharing', 'Freigabe', 'Condivisione', 'Compartir');
  End;
End;

{ onglet I : X1..X2 }
Procedure PropTabRect(I : LongInt; Var X1, X2 : LongInt);
Var K : LongInt;
Begin
  X1 := 8;
  For K := 0 To I - 1 Do X1 := X1 + TextW(PropTabName(K)) + 20;
  X2 := X1 + TextW(PropTabName(I)) + 19;
End;

{ boutons du bas : 0 OK, 1 Annuler, 2 Appliquer }
Procedure PropBtnRect(I : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Begin
  X2 := PW - 10 - (2 - I) * 90; X1 := X2 - 82;
  Y1 := PH - 36; Y2 := PH - 12;
End;

{ bouton "Verifier maintenant..." etc. de l'onglet Outils }
Procedure PropToolRect(I : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Begin
  X2 := PW - 30; X1 := X2 - 224;
  Y1 := 106 + I * 106; Y2 := Y1 + 22;
End;

Function PropBtnText(I : LongInt) : String;
Begin
  Case I Of
    0 : PropBtnText := 'OK';
    1 : PropBtnText := L('Annuler', 'Cancel', 'Abbrechen', 'Annulla', 'Cancelar');
  Else
    PropBtnText := L('Appliquer', 'Apply', #154'bernehmen', 'Applica', 'Aplicar');
  End;
End;

{ texte grise en relief (element inactif) }
Procedure GrayTxt(X, Y : LongInt; S : String);
Begin
  OutTxt(X, Y, S, cGray, cSilver);
End;

{ bouton en relief, texte centre (Def : cadre noir du bouton par defaut) }
Procedure PButton(X1, Y1, X2, Y2 : LongInt; S : String; En, Def : Boolean);
Var X : LongInt;
Begin
  Raised(X1, Y1, X2, Y2, True);
  If Def Then Box(X1 - 1, Y1 - 1, X2 + 1, Y2 + 1, cBlack);
  X := (X1 + X2 + 1 - TextW(S)) Div 2;
  If En Then OutTxt(X, Y1 + 4, S, cBlack, cSilver) Else GrayTxt(X, Y1 + 4, S);
End;

{ cadre grave (trait gris et trait blanc) avec titre }
Procedure GroupBox(X1, Y1, X2, Y2 : LongInt; T : String);
Begin
  Box(X1, Y1, X2 - 1, Y2 - 1, cGray);
  Box(X1 + 1, Y1 + 1, X2, Y2, cWhite);
  OutTxt(X1 + 8, Y1 - 8, ' ' + T + ' ', cBlack, cSilver);
End;

{ texte coupe aux espaces dans une largeur de W points }
Procedure WrapText(X, Y, W : LongInt; S : String; C : LongInt; Gray : Boolean);
Var Ln, Wd : String; P : LongInt;
Begin
  Ln := '';
  While S <> '' Do
  Begin
    P := Pos(' ', S);
    If P = 0 Then
    Begin
      Wd := S; S := '';
    End
    Else
    Begin
      Wd := Copy(S, 1, P - 1); Delete(S, 1, P);
    End;
    If (Ln <> '') And (TextW(Ln + ' ' + Wd) > W) Then
    Begin
      If Gray Then GrayTxt(X, Y, Ln) Else OutTxt(X, Y, Ln, C, cSilver);
      Y := Y + 17;
      Ln := Wd;
    End
    Else If Ln = '' Then Ln := Wd
    Else Ln := Ln + ' ' + Wd;
  End;
  If Ln <> '' Then
    If Gray Then GrayTxt(X, Y, Ln) Else OutTxt(X, Y, Ln, C, cSilver);
End;

{ case d'option ronde }
Procedure Radio(X, Y : LongInt; T : String; On, En : Boolean);
Var Dy, W, Cx, Cy : LongInt;
Begin
  Cx := X + 6; Cy := Y + 8;
  For Dy := -6 To 6 Do
  Begin
    W := ISqrt(36 - Dy * Dy);
    If Dy < 0 Then HLine(Cx - W, Cx + W, Cy + Dy, cGray) Else HLine(Cx - W, Cx + W, Cy + Dy, cWhite);
  End;
  For Dy := -5 To 5 Do
  Begin
    W := ISqrt(25 - Dy * Dy) - 1;
    If W >= 0 Then HLine(Cx - W, Cx + W, Cy + Dy, cWhite);
  End;
  If On Then
    For Dy := -2 To 2 Do
    Begin
      W := ISqrt(4 - Dy * Dy);
      HLine(Cx - W, Cx + W, Cy + Dy, cBlack);
    End;
  If En Then OutTxt(X + 20, Y, T, cBlack, cSilver) Else GrayTxt(X + 20, Y, T);
End;

{ angle de (X, Y) dans [0, 2 pi[, sens trigonometrique (arc tangente
  approchee a 0,005 radian pres, comme VpAng de Pasdows 95) }
Function VpAng(X, Y : Double) : Double;
Var AX, AY, Zz, T : Double;
Begin
  AX := Abs(X); AY := Abs(Y);
  If AX + AY < 0.000001 Then
  Begin
    VpAng := 0;
    Exit;
  End;
  If AX >= AY Then
  Begin
    Zz := AY / AX;
    T := Zz * (0.7853981634 + 0.273 * (1 - Zz));
  End
  Else
  Begin
    Zz := AX / AY;
    T := 1.5707963268 - Zz * (0.7853981634 + 0.273 * (1 - Zz));
  End;
  If X < 0 Then T := 3.1415926536 - T;
  If Y < 0 Then T := 6.2831853072 - T;
  VpAng := T;
End;

{ camembert en relief : ellipse de rayons A et B, epaisseur Dp ; part
  libre (Pm pour mille, magenta) a partir de 0 degre dans le sens
  trigonometrique, puis part utilisee (bleu) ; dessin par segments }
Procedure VpPie(CX, CY, A, B, Dp, Pm : LongInt);
Var X, Y, H, C, Run, RunC : LongInt; Th : Double;
Begin
  Th := Pm * 0.0062831853072;
  { flanc : de gauche a droite, une colonne par point }
  For X := -A To A Do
  Begin
    H := (B * ISqrt(A * A - X * X)) Div A;
    If VpAng(X, -H * A / B) < Th Then C := cPurple Else C := cNavy;
    VLine(CX + X, CY + H + 1, CY + H + Dp, C);
    Pix(CX + X, CY + H + Dp + 1, cBlack);
  End;
  VLine(CX - A - 1, CY, CY + Dp, cBlack);
  VLine(CX + A + 1, CY, CY + Dp, cBlack);
  { dessus : chaque ligne en segments de meme couleur }
  For Y := -B To B Do
  Begin
    H := (A * ISqrt(B * B - Y * Y)) Div B;
    Run := -H; RunC := -1;
    For X := -H To H + 1 Do
    Begin
      If X > H Then C := -100
      Else If VpAng(X, -Y * A / B) < Th Then C := cFuchsia Else C := cBlue;
      If C <> RunC Then
      Begin
        If RunC <> -1 Then HLine(CX + Run, CX + X - 1, CY + Y, RunC);
        Run := X; RunC := C;
      End;
    End;
    Pix(CX - H - 1, CY + Y, cBlack);
    Pix(CX + H + 1, CY + Y, cBlack);
  End;
End;

{ ligne d'espace : carre de couleur, libelle, octets, taille courte }
Procedure SpaceRow(Y, C : LongInt; T : String; Kb : Double);
Var B : String;
Begin
  If C <> -100 Then
  Begin
    FBar(24, Y + 2, 36, Y + 14, C);
    Box(24, Y + 2, 36, Y + 14, cBlack);
  End;
  OutTxt(44, Y, T, cBlack, cSilver);
  B := ThousandsD(Kb * 1024.0);
  { au-dela de 100 Go (partage reseau), sans le mot octets : la colonne
    des Go reste libre }
  If Length(B) < 13 Then B := B + L(' octets', ' bytes', ' Byte', ' byte', ' bytes');
  OutRight(PW - 104, Y, B, cBlack, cSilver);
  OutRight(PW - 26, Y, ShortSize(Kb), cBlack, cSilver);
End;

Procedure PropPaintGeneral;
Var Pm, X : LongInt; S : String;
Begin
  PaintIcon(NodeIcon(PDrive + ':'), 24, 42, 32);
  OutTxt(76, 50, L('Nom :', 'Label:', 'Bezeichnung:', 'Etichetta:', 'Etiqueta:'), cBlack, cSilver);
  If PropWritable Then Sunken(176, 46, PW - 24, 68, cWhite) Else Sunken(176, 46, PW - 24, 68, cSilver);
  If PropWritable Then OutTxt(180, 49, PLabel, cBlack, cWhite) Else OutTxt(180, 49, PLabel, cBlack, cSilver);
  If PEdit And (PCaretOn <> 0) Then
  Begin
    X := 181 + TextW(PLabel);
    VLine(X, 50, 64, cBlack);
  End;
  OutTxt(76, 80, L('Type :', 'Type:', 'Typ:', 'Tipo:', 'Tipo:'), cBlack, cSilver);
  OutTxt(176, 80, PropTypeText, cBlack, cSilver);
  HLine(16, PW - 17, 106, cGray); HLine(16, PW - 17, 107, cWhite);
  SpaceRow(116, cBlue, L('Espace utilis'#130' :', 'Used space:', 'Belegt:', 'Spazio usato:', 'Espacio usado:'),
           PTot - PFree);
  SpaceRow(140, cFuchsia, L('Espace libre :', 'Free space:', 'Frei:', 'Spazio libero:', 'Espacio libre:'), PFree);
  HLine(16, PW - 17, 164, cGray); HLine(16, PW - 17, 165, cWhite);
  SpaceRow(174, -100, L('Capacit'#130' :', 'Capacity:', 'Kapazit'#132't:', 'Capacit'#133':', 'Capacidad:'), PTot);
  If PTot > 0 Then Pm := Round(PFree / PTot * 1000) Else Pm := 0;
  VpPie(PW Div 2, 252, 96, 38, 14, Pm);
  S := L('Lecteur ', 'Drive ', 'Laufwerk ', 'Unit'#133' ', 'Unidad ') + UpCase(PDrive);
  OutTxt((PW - TextW(S)) Div 2, 312, S, cBlack, cSilver);
End;

{ textes de l'onglet Outils : groupe I, partie P (0 titre, 1 texte, 2 bouton) }
Function ToolText(I, P : LongInt) : String;
Var S : String;
Begin
  S := '';
  If (I = 0) And (P = 0) Then
    S := L('V'#130'rification des erreurs', 'Error-checking status', 'Fehler'#129'berpr'#129'fung',
           'Controllo errori', 'Comprobaci'#162'n de errores');
  If (I = 0) And (P = 1) Then
    S := L('CHKDSK v'#130'rifie le syst'#138'me de fichiers de ce lecteur et signale les erreurs.',
           'CHKDSK checks the file system of this drive and reports errors.',
           'CHKDSK pr'#129'ft das Dateisystem dieses Laufwerks.',
           'CHKDSK controlla il file system di questa unit'#133'.',
           'CHKDSK comprueba el sistema de archivos de esta unidad.');
  If (I = 0) And (P = 2) Then
    S := L('V'#130'rifier maintenant...', 'Check Now...', 'Jetzt pr'#129'fen...', 'Controlla ora...',
           'Comprobar ahora...');
  If (I = 1) And (P = 0) Then
    S := L(''#144'tat de la sauvegarde', 'Backup status', 'Sicherung', 'Backup', 'Copia de seguridad');
  If (I = 1) And (P = 1) Then
    S := L('Aucune sauvegarde n''a encore '#130't'#130' faite sur ce lecteur.',
           'OS/2-0 has no record of when you last backed up this drive.', 'Keine Sicherung vorhanden.',
           'Nessun backup.', 'No hay copia de seguridad.');
  If (I = 1) And (P = 2) Then
    S := L('Sauvegarder maintenant...', 'Backup Now...', 'Jetzt sichern...', 'Backup ora...',
           'Copiar ahora...');
  If (I = 2) And (P = 0) Then
    S := L(''#144'tat de la d'#130'fragmentation', 'Defragmentation status', 'Defragmentierung',
           'Deframmentazione', 'Desfragmentaci'#162'n');
  If (I = 2) And (P = 1) Then
    S := L('HPFS et NTFS r'#130'partissent les fichiers sans les fragmenter : aucune d'#130'fragmentation.',
           'HPFS and NTFS allocate files without fragmenting them: no defragmentation needed.',
           'HPFS und NTFS brauchen keine Defragmentierung.', 'HPFS e NTFS non richiedono deframmentazione.',
           'HPFS y NTFS no necesitan desfragmentaci'#162'n.');
  If (I = 2) And (P = 2) Then
    S := L('D'#130'fragmenter maintenant...', 'Defragment Now...', 'Jetzt defragmentieren...',
           'Deframmenta ora...', 'Desfragmentar ahora...');
  ToolText := S;
End;

Procedure PropPaintTools;
Var I, X1, Y1, X2, Y2 : LongInt; T : String; En : Boolean;
Begin
  For I := 0 To 2 Do
  Begin
    T := ToolText(I, 0);
    GroupBox(16, 44 + I * 106, PW - 17, 138 + I * 106, T);
    T := ToolText(I, 1);
    WrapText(28, 58 + I * 106, PW - 56, T, cBlack, False);
    PropToolRect(I, X1, Y1, X2, Y2);
    T := ToolText(I, 2);
    En := (I = 0) And (DrvKind[PropDisk - 1] <> ekFloppy) And (DrvKind[PropDisk - 1] <> ekNet);
    PButton(X1, Y1, X2, Y2, T, En, False);
  End;
End;

Procedure PropPaintSharing;
Begin
  Radio(24, 46, L('Non partag'#130, 'Not Shared', 'Nicht freigegeben', 'Non condiviso', 'No compartido'),
        True, True);
  Radio(24, 70, L('Partag'#130' en tant que :', 'Shared As:', 'Freigegeben als:', 'Condiviso come:',
                  'Compartido como:'), False, False);
  WrapText(24, 104, PW - 48, L('Le partage de fichiers et d''imprimantes n''est pas install'#130' : ce lecteur ' +
           'ne peut pas '#136'tre partag'#130' sur le r'#130'seau.', 'File and printer sharing is not ' +
           'installed: this drive cannot be shared on the network.',
           'Datei- und Druckerfreigabe ist nicht installiert.', 'Condivisione file non installata.',
           'Compartir archivos no est'#160' instalado.'), cGray, True);
End;

Procedure PropPaint(H : LongInt);
Var SvH, SvC, I, X1, X2, Y1, Y2 : LongInt;
Begin
  SvH := Hps; SvC := CH;
  Hps := WinBeginPaint(H, 0, 0);
  CH := PCH;
  FBar(0, 0, PW + 40, PCH, cSilver);
  { cadre et onglets (l'onglet choisi est plus haut et ouvert en bas) }
  Edge(6, PropTop, PW - 7, PropBot, cWhite, cBlack);
  HLine(7, PW - 8, PropBot - 1, cGray); VLine(PW - 8, PropTop + 1, PropBot - 1, cGray);
  For I := 0 To 2 Do
  Begin
    PropTabRect(I, X1, X2);
    If I = PTab Then
    Begin
      X1 := X1 - 2; X2 := X2 + 2;
      FBar(X1, 4, X2, PropTop + 1, cSilver);
      HLine(X1 + 1, X2 - 1, 4, cWhite); VLine(X1, 5, PropTop, cWhite);
      VLine(X2, 5, PropTop, cBlack); VLine(X2 - 1, 5, PropTop, cGray);
      OutTxt(X1 + 12, 8, PropTabName(I), cBlack, cSilver);
    End
    Else
    Begin
      HLine(X1 + 1, X2 - 1, 7, cWhite); VLine(X1, 8, PropTop - 1, cWhite);
      VLine(X2, 8, PropTop - 1, cBlack); VLine(X2 - 1, 8, PropTop - 1, cGray);
      OutTxt(X1 + 10, 10, PropTabName(I), cBlack, cSilver);
    End;
  End;
  Case PTab Of
    0 : PropPaintGeneral;
    1 : PropPaintTools;
  Else
    PropPaintSharing;
  End;
  For I := 0 To 2 Do
  Begin
    PropBtnRect(I, X1, Y1, X2, Y2);
    PButton(X1, Y1, X2, Y2, PropBtnText(I), (I < 2) Or PDirty, I = 0);
  End;
  Dummy := WinEndPaint(Hps);
  Hps := SvH; CH := SvC;
End;

{ ecrire le nom du volume (VOLUMELABEL : longueur puis texte) }
Function PropApply : Boolean;
Var B : Array[0..15] Of Byte; K, Rc : LongInt;
Begin
  PropApply := True;
  If Not PDirty Then Exit;
  FillChar(B, SizeOf(B), 0);
  B[0] := Length(PLabel);
  For K := 1 To Length(PLabel) Do B[K] := Ord(UpCase(PLabel[K]));
  Rc := DosSetFSInfo(PropDisk, 2, LongInt(@B), Length(PLabel) + 2);
  If Rc <> 0 Then
  Begin
    Dummy := WinMessageBox(HWND_DESKTOP, PFrame, Z(L('Impossible de changer le nom du volume (erreur ', 'Cannot ' +
             'change the volume label (error ', 'Bezeichnung nicht ge'#132'ndert (Fehler ', 'Impossibile cambiare ' +
             'l''etichetta (errore ', 'No se puede cambiar la etiqueta (error ') + IStr(Rc) + ').'), Z2(AppName),
             0, MB_OK Or MB_ERROR Or MB_MOVEABLE);
    PropApply := False;
    Exit;
  End;
  PLabel := UpStr(PLabel); PLabel0 := PLabel; PDirty := False;
  ScanDrives;
  If (Client <> 0) And Not PAlone Then
  Begin
    TreeSync;
    SetTitle;
    Redraw;
  End;
End;

Procedure PropClose;
Var F : LongInt;
Begin
  F := PFrame;
  PFrame := 0; PClient := 0;
  { l'Explorateur redevient la fenetre active (avant la destruction de la
    boite, sinon PM active une autre fenetre) }
  If (Not PAlone) And (Frame <> 0) Then
  Begin
    Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
    Dummy := WinSetFocus(HWND_DESKTOP, Client);
  End;
  If F <> 0 Then Dummy := WinDestroyWindow(F);
  If PAlone Then Dummy := WinPostMsg(0, WM_QUIT, 0, 0)
  Else If Frame <> 0 Then
  Begin
    Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
    Dummy := WinSetFocus(HWND_DESKTOP, Client);
  End;
End;

Procedure PropInval;
Begin
  If PClient <> 0 Then Dummy := WinInvalidateRect(PClient, 0, 0);
End;

{ verification du lecteur par CHKDSK, dans une session plein ecran }
Procedure PropCheck;
Begin
  RunProgram(Comspec, '/K CHKDSK ' + UpCase(PDrive) + ':', UpCase(PDrive) + ':\');
End;

Procedure PropClick(X, Y : LongInt);
Var I, X1, X2, Y1, Y2 : LongInt;
Begin
  If Y < PropTop Then
  Begin
    For I := 0 To 2 Do
    Begin
      PropTabRect(I, X1, X2);
      If (X >= X1) And (X <= X2) And (PTab <> I) Then
      Begin
        PTab := I; PEdit := (I = 0) And PropWritable;
        PropInval;
      End;
    End;
    Exit;
  End;
  For I := 0 To 2 Do
  Begin
    PropBtnRect(I, X1, Y1, X2, Y2);
    If (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2) Then
    Begin
      Case I Of
        0 : If PropApply Then PropClose;
        1 : PropClose;
      Else
        If PDirty Then
        Begin
          Dummy := PropApply;
          PropInval;
        End;
      End;
      Exit;
    End;
  End;
  If PTab = 0 Then
  Begin
    PEdit := PropWritable And (X >= 176) And (X <= PW - 24) And (Y >= 46) And (Y <= 68);
    PCaretOn := 1;
    PropInval;
  End
  Else If PTab = 1 Then
  Begin
    PropToolRect(0, X1, Y1, X2, Y2);
    If (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2) And (DrvKind[PropDisk - 1] <> ekFloppy) And
       (DrvKind[PropDisk - 1] <> ekNet) Then PropCheck;
  End;
End;

Function PropKey(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk, Act : LongInt; Done : Boolean;
Begin
  Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := Hi16(Mp2);
  Done := True; Act := 0;
  If (Fl And KC_KEYUP) <> 0 Then Act := 0
  Else If ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then Act := 1
  Else If ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_NEWLINE) Or (Vk = VK_ENTER)) Then Act := 2
  Else If ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_TAB) Then Act := 3
  Else If ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_BACKTAB) Then Act := 4
  Else If ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_BACKSPACE) Then Act := 5
  Else If PEdit And ((Fl And KC_CHAR) <> 0) And (Ch > 32) And (Ch < 127) Then Act := 6
  Else Done := False;
  If Act = 1 Then PropClose
  Else If Act = 2 Then
  Begin
    If PropApply Then PropClose;
  End
  Else If (Act = 3) Or (Act = 4) Then
  Begin
    If Act = 3 Then PTab := (PTab + 1) Mod 3 Else PTab := (PTab + 2) Mod 3;
    PEdit := (PTab = 0) And PropWritable;
    PropInval;
  End
  Else If (Act = 5) And PEdit And (PLabel <> '') Then
  Begin
    Delete(PLabel, Length(PLabel), 1);
    PDirty := PLabel <> PLabel0;
    PropInval;
  End
  Else If (Act = 6) And (Length(PLabel) < 11) And (Pos(Chr(Ch), '*?/\|.,;:+=<>[]"') = 0) Then
  Begin
    PLabel := PLabel + UpCase(Chr(Ch));
    PDirty := PLabel <> PLabel0;
    PropInval;
  End;
  PropKey := Done;
End;

Function PropProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  PropProc := 0;
  Case Msg Of
    WM_SIZE :
    Begin
      Dummy := WinQueryWindowRect(H, LongInt(@Rc));
      PCH := Rc[3];
    End;
    WM_PAINT : PropPaint(H);
    WM_BUTTON1DOWN :
    Begin
      Dummy := WinSetFocus(HWND_DESKTOP, H);
      PropClick(S16(Mp1), PCH - 1 - S16(Mp1 Shr 16));
      PropProc := 1;
    End;
    WM_CHAR :
      If PropKey(Mp1, Mp2) Then PropProc := 1
      Else PropProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_CLOSE : PropClose;
  Else
    PropProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ouvrir la boite des proprietes du lecteur C (une seule a la fois) }
Procedure DriveProps(C : Char);
Var Fl, Fw, Fh, Sw, Sh, K : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  If PFrame <> 0 Then PropClose;
  PAlone := PAlone And (Client = 0);
  PDrive := UpCase(C);
  K := PropDisk - 1;
  If (K < 0) Or (K > 25) Then Exit;
  PLabel := DrvLbl[K]; PLabel0 := PLabel;
  If Not DriveSpace(PDrive, PFree, PTot) Then
  Begin
    PFree := 0; PTot := 0;
  End;
  PTab := 0; PDirty := False; PCaretOn := 1; PCH := PH;
  PEdit := PropWritable;   { le champ du nom a le focus, comme sous Windows 95 }
  Dummy := WinRegisterClass(Hab, Z('EXPPROPS'), LongInt(@PropProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  If PAlone Then Fl := Fl Or FCF_TASKLIST;
  PClient := 0;
  PFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('EXPPROPS'),
                               Z2(L('Propri'#130't'#130's de (', 'Properties of (', 'Eigenschaften von (',
                                    'Propriet'#133' di (', 'Propiedades de (') + PDrive + ':)'), 0, 0, ID_PROPS,
                               LongInt(@PClient));
  If PFrame = 0 Then Exit;
  Rc[0] := 0; Rc[1] := 0; Rc[2] := PW; Rc[3] := PH;
  Dummy := WinCalcFrameRect(PFrame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(PFrame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, PFrame);
  Dummy := WinSetFocus(HWND_DESKTOP, PClient);
End;

{ boite Proprietes : lecteur (camembert de Pasdows 95), fichiers et
  dossiers choisis, ou dossier affiche (FileProps, plus bas) }
Procedure FileProps; Forward;

Procedure Props;
Var S : String;
Begin
  If CurPath = '' Then
  Begin
    If (Sel >= 0) And (Sel < NEnt) Then DriveProps(E(Sel)^.Nm[1])
    Else
    Begin
      S := PathTitle('') + Chr(10) + IStr(NEnt) + ' ' + L('lecteur(s)', 'drive(s)', 'Laufwerk(e)', 'unit'#133,
                                                          'unidad(es)');
      Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2(L('Propri'#130't'#130's', 'Properties', 'Eigenschaften',
                             'Propriet'#133, 'Propiedades')), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
    End;
  End
  Else If (Length(CurPath) = 2) And (SelCount = 0) Then DriveProps(CurPath[1])
  Else FileProps;
End;

Procedure About;
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame,
                         Z(AppName + Chr(10) + L('Explorateur de fichiers dans le style de Windows 95',
                           'Windows 95 style file explorer', 'Datei-Explorer im Stil von Windows 95',
                           'Esplora file in stile Windows 95', 'Explorador de archivos estilo Windows 95') + Chr(10) +
                           L('Port'#130' de l''Explorateur Pasdows', 'Ported from the Pasdows Explorer',
                             'Portiert vom Pasdows-Explorer', 'Portato da Esplora risorse Pasdows',
                             'Portado del Explorador de Pasdows') + Chr(10) + 'Copyright Gladir.com 2026'),
                         Z2(L('A propos de l''Explorateur', 'About Explorer', #154'ber Explorer',
                              'Informazioni su Esplora risorse', 'Acerca del Explorador')),
                         0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

{ ==================================================================== }
{ Operations sur les fichiers : selection multiple, Couper, Copier,     }
{ Coller, Supprimer, Renommer, Nouveau dossier, Proprietes              }
{ ==================================================================== }
{ Comme l'Explorateur de Pasdows 95 (et de Windows 95) : Ctrl+clic,
  Maj+clic, Selectionner tout (Ctrl+A) ; Couper (Ctrl+X), Copier
  (Ctrl+C) et Coller (Ctrl+V) des fichiers et des dossiers (avec leur
  contenu) d'un lecteur a l'autre (HPFS, NTFS, disque virtuel, lecteurs
  reseau SMB, depuis le CD-ROM) ; Couper deplace (DosMove sur le meme
  lecteur, sinon DosCopy puis suppression). Copier dans le meme dossier
  cree "Copie de nom" ; un element qui existe deja fait demander s'il
  faut le remplacer. La liste des fichiers est gardee dans une memoire
  partagee nommee (\SHAREMEM\EXPLORER.CLP, d'un Explorateur a l'autre) et
  le presse-papiers de PM recoit leurs chemins en texte (CF_TEXT) : un
  autre texte copie depuis remplace la liste. Proprietes : boite de PM
  (type, emplacement, taille, contenu d'un dossier, dates de creation,
  de modification et de dernier acces, attributs Lecture seule, Masque,
  Archive, Systeme modifiables par DosSetPathInfo). }

Const
  ClipName = '\SHAREMEM\EXPLORER.CLP';
  ClipSz = 65536;
  ClipTxt = 32768;                      { copie du texte du presse-papiers }
  MB_YESNO = 4; MB_YESNOCANCEL = 5; MB_ICONQUESTION = $10;
  MBID_YES = 6; MBID_NO = 7; MBID_CANCEL = 2;

Var
  FoErr : LongInt;                      { premiere erreur d'une operation }
  FoErrNm : String;
  FoStop : Boolean;
  PrN, PrFiles, PrDirs : LongInt;       { boite Proprietes }
  PrSize : Double;
  PrPath : Array[0..63] Of String[127];
  PrAttr0, PrIcon : LongInt;
  PrCk : Array[0..3] Of LongInt;
  PrRO : Boolean;
  RnOld : String;


{ ==================================================================== }
{ Lecteurs reseau : Connecter un lecteur reseau, Deconnecter            }
{ ==================================================================== }
{ Boites de Presentation Manager (controles du systeme : liste
  deroulante, champs de saisie, case a cocher, boutons), comme la boite
  "Connecter un lecteur reseau" de Pasdows 95. Le lecteur est attache par
  DosFSAttach(lettre, "SMB", "\\serveur\partage" 0 utilisateur 0 mot de
  passe 0, FS_ATTACH) ; SMB.IFS ouvre la session (SMB2, NTLMv2) et
  SMBLASTERROR en explique l'echec. "Se reconnecter a l'ouverture de
  session" garde la connexion dans OS2.INI (application PM_NetworkDrives,
  cle = lettre : chemin, utilisateur et cle NT du mot de passe, jamais le
  mot de passe lui-meme) ; le bureau (PMSHELL) la retablit au demarrage. }

Var
  NdFr, NdCl, NdEnd, NdCombo, NdPath, NdUser, NdPass, NdCk, NdList, NdMode : LongInt;
  NdLet : Array[0..25] Of Char;
  NdTab : Array[0..9] Of LongInt;       { ordre de Tab }
  NdTabN : LongInt;
  NdN : LongInt;
  NdRegDone : Boolean;
  NdTitleS : String;                    { titre des boites 2 (Renommer) et 4 (Proprietes) }
  NdData : Array[0..767] Of Byte;

Function NdCtl(Cls, Txt : LongInt; Style, X, Y, W, H, Id : LongInt) : LongInt;
Var C : LongInt;
Begin
  C := WinCreateWindow(NdCl, Cls, Txt, Style Or WS_VISIBLE, X, Y, W, H, NdCl, HWND_TOP, Id, 0, 0);
  If ((Style And WS_TABSTOP) <> 0) And (NdTabN < 10) And (C <> 0) Then
  Begin
    NdTab[NdTabN] := C;
    Inc(NdTabN);
  End;
  NdCtl := C;
End;

{ Tab et Maj+Tab : controle suivant ou precedent }
Procedure NdNext(Dir : LongInt);
Var F, I, K : LongInt;
Begin
  If NdTabN = 0 Then Exit;
  F := WinQueryFocus(HWND_DESKTOP);
  K := -1;
  For I := 0 To NdTabN - 1 Do If NdTab[I] = F Then K := I;
  If K < 0 Then K := 0 Else K := (K + Dir + NdTabN) Mod NdTabN;
  Dummy := WinSetFocus(HWND_DESKTOP, NdTab[K]);
End;

Procedure NdGray(H : LongInt);
Var C : LongInt;
Begin
  C := cSilver;
  Dummy := WinSetPresParam(H, 4, 4, LongInt(@C));
End;

Function NdText(H : LongInt) : String;
Var N : LongInt; B : Array[0..259] Of Byte; S : String;
Begin
  FillChar(B, SizeOf(B), 0);
  N := WinQueryWindowText(H, 250, LongInt(@B));
  S := '';
  While (Length(S) < N) And (B[Length(S)] <> 0) Do S := S + Chr(B[Length(S)]);
  NdText := S;
End;

Procedure NdLabel(S : String; X, Y, W : LongInt);
Begin
  NdGray(NdCtl(WC_STATIC, Z(S), SS_TEXT Or DT_VCENTER, X, Y, W, 20, 0));
End;

{ texte de la derniere erreur de SMB.IFS (point d'entree SMBLASTERROR) }
Function SmbText : String;
Var H, F, R : LongInt; Fail : Array[0..63] Of Byte; B : Array[0..259] Of Byte;
Begin
  SmbText := '';
  H := 0; F := 0;
  If DosLoadModule(LongInt(@Fail), 64, Z('C:\SMB.IFS'), LongInt(@H)) <> 0 Then Exit;
  If DosQueryProcAddr(H, 0, Z('SMBLASTERROR'), LongInt(@F)) <> 0 Then Exit;
  If F = 0 Then Exit;
  FillChar(B, SizeOf(B), 0);
  R := LongInt(@B);
  asm
    mov eax,256
    push eax
    mov eax,R
    push eax
    mov eax,F
    call eax
    add esp,8
  end;
  SmbText := GetZ(LongInt(@B));
End;

Function NetErrText(E : LongInt) : String;
Begin
  Case E Of
    5 : NetErrText := L('Acc'#138's refus'#130'.', 'Access is denied.', 'Zugriff verweigert.', 'Accesso negato.',
                        'Acceso denegado.');
    15 : NetErrText := L('Lecteur incorrect.', 'Invalid drive.', 'Ung'#129'ltiges Laufwerk.', 'Unit'#133' non valida.',
                         'Unidad no v'#160'lida.');
    53 : NetErrText := L('Le chemin r'#130'seau est introuvable.', 'The network path was not found.',
                         'Der Netzwerkpfad wurde nicht gefunden.', 'Percorso di rete non trovato.',
                         'No se encontr'#162' la ruta de red.');
    59 : NetErrText := L('Erreur r'#130'seau inattendue.', 'An unexpected network error occurred.',
                         'Unerwarteter Netzwerkfehler.', 'Errore di rete imprevisto.', 'Error de red inesperado.');
    64 : NetErrText := L('Le serveur ne r'#130'pond plus.', 'The network name is no longer available.',
                         'Der Server antwortet nicht mehr.', 'Il server non risponde.', 'El servidor no responde.');
    65 : NetErrText := L('Acc'#138's au partage refus'#130'.', 'Network access is denied.',
                         'Netzwerkzugriff verweigert.', 'Accesso alla rete negato.', 'Acceso a la red denegado.');
    67 : NetErrText := L('Le nom du partage est introuvable.', 'The network name cannot be found.',
                         'Der Netzwerkname wurde nicht gefunden.', 'Nome di rete non trovato.',
                         'No se encuentra el nombre de red.');
    85 : NetErrText := L('Cette lettre de lecteur est d'#130'j'#133' utilis'#130'e.', 'The drive letter is already in use.',
                         'Der Laufwerkbuchstabe wird bereits verwendet.', 'Lettera di unit'#133' gi'#133' in uso.',
                         'La letra de unidad ya est'#160' en uso.');
    86 : NetErrText := L('Nom d''utilisateur ou mot de passe incorrect.', 'Unknown user name or bad password.',
                         'Benutzername oder Kennwort falsch.', 'Nome utente o password errati.',
                         'Usuario o contrase'#164'a incorrectos.');
    124 : NetErrText := L('Le syst'#138'me de fichiers SMB.IFS est absent.', 'The SMB.IFS file system is missing.',
                          'Das Dateisystem SMB.IFS fehlt.', 'Il file system SMB.IFS manca.',
                          'Falta el sistema de archivos SMB.IFS.');
  Else
    NetErrText := L('Erreur ', 'Error ', 'Fehler ', 'Errore ', 'Error ') + IStr(E) + '.';
  End;
End;

Procedure NdPut(Var P : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
  Begin
    NdData[P] := Ord(S[K]);
    Inc(P);
  End;
  NdData[P] := 0;
  Inc(P);
End;

{ OS2.INI : la connexion permanente C: (chemin, utilisateur, #cle NT
  donnee par SMB.IFS ; KrnDiskCtl 15 = informations de FS_ATTACH) }
Procedure NetSave(C : Char);
Var Q : Array[0..1] Of LongInt; B : Array[0..511] Of Byte; R, Us, Hs : String; K : LongInt;
Begin
  FillChar(B, SizeOf(B), 0);
  Q[0] := LongInt(@B); Q[1] := 512;
  If KDiskCtl(15, Ord(C) - 65, LongInt(@Q)) <> 0 Then Exit;
  K := LongInt(@B) + Length(GetZ(LongInt(@B))) + 1;
  R := GetZ(K); K := K + Length(R) + 1;
  Us := GetZ(K); K := K + Length(Us) + 1;
  Hs := GetZ(K);
  PutZ(LongInt(@TxtBuf), R + Chr(9) + Us + Chr(9) + Hs);
  Dummy := PrfWriteProfileString(HINI_USERPROFILE, Z(NetApp), Z2(C), LongInt(@TxtBuf));
End;

Procedure NetForget(C : Char);
Begin
  Dummy := PrfWriteProfileString(HINI_USERPROFILE, Z(NetApp), Z2(C), 0);
End;

{ Connecter : 0 ou le code d'erreur }
Function NetMap(C : Char; Remote, User, Pass : String) : LongInt;
Var P : LongInt;
Begin
  P := 0;
  NdPut(P, Remote); NdPut(P, User); NdPut(P, Pass);
  PutZ(LongInt(@ArgBuf), C + ':');
  NetMap := DosFSAttach(LongInt(@ArgBuf), Z('SMB'), LongInt(@NdData), P, 0);
  FillChar(NdData, SizeOf(NdData), 0);       { pas de mot de passe en memoire }
End;

Function NetUnmap(C : Char) : LongInt;
Begin
  PutZ(LongInt(@ArgBuf), C + ':');
  NetUnmap := DosFSAttach(LongInt(@ArgBuf), Z('SMB'), 0, 0, 1);
End;

{ apres un changement : lecteurs, arbre et contenu a jour }
Procedure NetChanged(Open : Char);
Begin
  ScanDrives;
  If (Length(CurPath) >= 2) And ((DrvMap And (1 Shl (Ord(UpCase(CurPath[1])) - 65))) = 0) Then CurPath := '';
  Refresh;
  If Open <> ' ' Then Navigate(Open + ':');
End;

Function NetTitle(Mode : LongInt) : String;
Begin
  If Mode >= 2 Then NetTitle := NdTitleS
  Else If Mode = 0 Then
    NetTitle := L('Connecter un lecteur r'#130'seau', 'Map Network Drive', 'Netzlaufwerk verbinden',
                  'Connetti unit'#133' di rete', 'Conectar a unidad de red')
  Else
    NetTitle := L('D'#130'connecter un lecteur r'#130'seau', 'Disconnect Network Drive', 'Netzlaufwerk trennen',
                  'Disconnetti unit'#133' di rete', 'Desconectar unidad de red');
End;

Procedure NdClose;
Begin
  Dummy := WinEnableWindow(Frame, 1);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  Dummy := WinDestroyWindow(NdFr);
  NdFr := 0;
End;

Procedure NdMsg(S : String; Fl : LongInt);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, NdFr, Z(S), Z2(NetTitle(NdMode)), 0, Fl Or MB_MOVEABLE);
End;

{ OK de la boite Connecter }
Procedure MapOk;
Var C : Char; T, Remote, User, Pass, D : String; R, Ptr : LongInt;
Begin
  T := UpStr(NdText(NdCombo));
  C := ' ';
  If (Length(T) >= 1) And (T[1] >= 'A') And (T[1] <= 'Z') Then C := T[1];
  Remote := NdText(NdPath);
  While (Remote <> '') And (Remote[1] = ' ') Do Delete(Remote, 1, 1);
  While (Remote <> '') And ((Remote[Length(Remote)] = ' ') Or (Remote[Length(Remote)] = '\')) Do
    Delete(Remote, Length(Remote), 1);
  For R := 1 To Length(Remote) Do If Remote[R] = '/' Then Remote[R] := '\';
  If Copy(Remote, 1, 2) <> '\\' Then Remote := '\\' + Remote;
  T := Copy(Remote, 3, 255);
  If (C = ' ') Or (Pos('\', T) < 2) Or (Pos('\', T) = Length(T)) Then
  Begin
    NdMsg(L('Tapez le chemin r'#130'seau sous la forme \\serveur\partage.',
            'Type the network path as \\server\share.', 'Geben Sie den Netzwerkpfad als \\Server\Freigabe ein.',
            'Digitare il percorso di rete come \\server\condivisione.',
            'Escriba la ruta de red como \\servidor\recurso.'), MB_OK Or MB_WARNING);
    Dummy := WinSetFocus(HWND_DESKTOP, NdPath);
    Exit;
  End;
  User := NdText(NdUser);
  Pass := NdText(NdPass);
  Ptr := WinQuerySysPointer(HWND_DESKTOP, 3, 0);        { SPTR_WAIT }
  If Ptr <> 0 Then Dummy := WinSetPointer(HWND_DESKTOP, Ptr);
  R := NetMap(C, Remote, User, Pass);
  Pass := '';
  Ptr := WinQuerySysPointer(HWND_DESKTOP, 1, 0);        { SPTR_ARROW }
  If Ptr <> 0 Then Dummy := WinSetPointer(HWND_DESKTOP, Ptr);
  If R <> 0 Then
  Begin
    D := SmbText;
    T := NetErrText(R);
    { detail de SMB.IFS (en francais), s'il ajoute quelque chose }
    If (D <> '') And (Lang = 0) And (Pos(Copy(T, 1, Length(T) - 1), D) <> 1) Then T := T + Chr(10) + D;
    T := L('Impossible de connecter ', 'Cannot connect ', 'Verbindung nicht m'#148'glich: ', 'Impossibile connettere ',
           'No se puede conectar ') + C + ': ' + L(#133, 'to', 'mit', 'a', 'a') + ' ' + Remote + '.' + Chr(10) + T;
    NdMsg(T, MB_OK Or MB_ERROR);
    If (R = 86) Or (R = 5) Then
    Begin
      Dummy := WinSetFocus(HWND_DESKTOP, NdPass);
      Dummy := WinSendMsg(NdPass, EM_SETSEL, 255 Shl 16, 0);
    End
    Else Dummy := WinSetFocus(HWND_DESKTOP, NdPath);
    Exit;
  End;
  If WinSendMsg(NdCk, BM_QUERYCHECK, 0, 0) <> 0 Then NetSave(C) Else NetForget(C);
  NdLet[0] := C;
  NdEnd := ID_OK;
End;

{ OK de la boite Deconnecter }
Procedure UnmapOk;
Var I, R : LongInt; C : Char;
Begin
  I := WinSendMsg(NdList, LM_QUERYSELECTION, -1, 0);
  If (I < 0) Or (I >= NdN) Then
  Begin
    NdMsg(L('Choisissez le lecteur r'#130'seau '#133' d'#130'connecter.', 'Select the network drive to disconnect.',
            'W'#132'hlen Sie das zu trennende Netzlaufwerk.', 'Selezionare l''unit'#133' di rete da disconnettere.',
            'Seleccione la unidad de red que desea desconectar.'), MB_OK Or MB_WARNING);
    Exit;
  End;
  C := NdLet[I];
  R := NetUnmap(C);
  If R <> 0 Then
  Begin
    NdMsg(NetErrText(R), MB_OK Or MB_ERROR);
    Exit;
  End;
  NetForget(C);
  NdEnd := ID_OK;
End;

Procedure RenameOk; Forward;
Function PropsApply : Boolean; Forward;

Function NdProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Ps, Fl, Vk, SvH, SvC : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  NdProc := 0;
  Case Msg Of
    WM_PAINT :
    Begin
      Ps := WinBeginPaint(H, 0, 0);
      Dummy := WinQueryWindowRect(H, LongInt(@Rc));
      Dummy := WinFillRect(Ps, LongInt(@Rc), cSilver);
      If NdMode = 4 Then
      Begin
        { Proprietes : icone de l'element et trait sous le nom }
        SvH := Hps; SvC := CH;
        Hps := Ps; CH := Rc[3];
        PaintIcon(PrIcon, 22, 10, 32);
        HLine(14, Rc[2] - 15, 52, cGray);
        HLine(14, Rc[2] - 15, 53, cWhite);
        Hps := SvH; CH := SvC;
      End;
      Dummy := WinEndPaint(Ps);
    End;
    WM_COMMAND :
      If Lo16(Mp1) = ID_OK Then
      Begin
        Case NdMode Of
          0 : MapOk;
          1 : UnmapOk;
          2 : RenameOk;
          4 : If PropsApply Then NdEnd := ID_OK;
        End;
      End
      Else If Lo16(Mp1) = 30 Then
      Begin
        If NdMode = 4 Then Dummy := PropsApply;
      End
      Else If Lo16(Mp1) = ID_CANCEL Then NdEnd := ID_CANCEL;
    WM_CHAR :
    Begin
      Fl := Lo16(Mp1); Vk := Hi16(Mp2);
      NdProc := 1;
      If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
        Dummy := WinPostMsg(H, WM_COMMAND, ID_OK, 0)
      Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then NdEnd := ID_CANCEL
      Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_TAB) And
              ((Fl And KC_SHIFT) = 0) Then NdNext(1)
      Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_BACKTAB) Or (Vk = VK_TAB)) Then
        NdNext(-1)
      Else NdProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
    WM_CLOSE : NdEnd := ID_CANCEL;
  Else
    NdProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Function NdOpen(W, H : LongInt) : Boolean;
Var Fl, X, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  If Not NdRegDone Then
  Begin
    Dummy := WinRegisterClass(Hab, Z('EXPNETDLG'), LongInt(@NdProc), 0, 0);
    NdRegDone := True;
  End;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  NdCl := 0; NdTabN := 0;
  NdFr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('EXPNETDLG'), Z2(NetTitle(NdMode)), 0, 0, 0,
                             LongInt(@NdCl));
  NdOpen := NdFr <> 0;
  If NdFr = 0 Then Exit;
  Rc[0] := 0; Rc[1] := 0; Rc[2] := W; Rc[3] := H;
  Dummy := WinCalcFrameRect(NdFr, LongInt(@Rc), 0);
  W := Rc[2] - Rc[0]; H := Rc[3] - Rc[1];
  X := MaxI(0, (WinQuerySysValue(HWND_DESKTOP, 20) - W) Div 2);
  Y := MaxI(0, (WinQuerySysValue(HWND_DESKTOP, 21) - H) Div 2);
  Dummy := WinSetWindowPos(NdFr, HWND_TOP, X, Y, W, H, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
End;

Function NdRun(Foc : LongInt) : LongInt;
Var Qm : Array[0..7] Of LongInt;
Begin
  Dummy := WinEnableWindow(Frame, 0);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, NdFr);
  If Foc <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Foc);
  NdEnd := 0;
  While NdEnd = 0 Do
    If WinGetMsg(Hab, LongInt(@Qm), 0, 0, 0) = 0 Then NdEnd := ID_CANCEL
    Else Dummy := WinDispatchMsg(Hab, LongInt(@Qm));
  NdRun := NdEnd;
End;

Procedure NdButtons(W : LongInt);
Begin
  Dummy := NdCtl(WC_BUTTON, Z('OK'), WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT, W - 208, 8, 96, 26, ID_OK);
  Dummy := NdCtl(WC_BUTTON, Z(L('Annuler', 'Cancel', 'Abbrechen', 'Annulla', 'Cancelar')), WS_TABSTOP Or BS_PUSHBUTTON,
                 W - 104, 8, 96, 26, ID_CANCEL);
End;

{ Connecter un lecteur reseau... }
Procedure MapDialog;
Var W, H, K, Sel0 : LongInt; Open : Char;
Begin
  If Frame = 0 Then Exit;
  ScanDrives;
  NdN := 0;
  For K := 3 To 25 Do
    If (DrvMap And (1 Shl K)) = 0 Then
    Begin
      NdLet[NdN] := Chr(65 + K);
      Inc(NdN);
    End;
  If NdN = 0 Then
  Begin
    Msg(L('Aucune lettre de lecteur n''est libre.', 'No drive letter is available.', 'Kein Laufwerkbuchstabe frei.',
          'Nessuna lettera di unit'#133' libera.', 'No hay letras de unidad libres.'), MB_OK Or MB_WARNING);
    Exit;
  End;
  NdMode := 0;
  W := 470; H := 214;
  If Not NdOpen(W, H) Then Exit;
  NdLabel(L('Lecteur :', 'Drive:', 'Laufwerk:', 'Unit'#133':', 'Unidad:'), 12, H - 36, 160);
  NdCombo := NdCtl(WC_COMBOBOX, 0, WS_TABSTOP Or CBS_DROPDOWNLIST, 176, H - 36, 80, 20, 11);
  For K := 0 To NdN - 1 Do Dummy := WinSendMsg(NdCombo, LM_INSERTITEM, -1, Z(NdLet[K] + ':'));
  { premiere lettre libre apres les disques (comme Windows 95) }
  Sel0 := 0;
  Dummy := WinSendMsg(NdCombo, LM_SELECTITEM, Sel0, 1);
  Dummy := WinSetWindowText(NdCombo, Z(NdLet[Sel0] + ':'));
  NdLabel(L('Chemin :', 'Path:', 'Pfad:', 'Percorso:', 'Ruta:'), 12, H - 66, 160);
  NdPath := NdCtl(WC_ENTRYFIELD, 0, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN, 176, H - 66, W - 188, 20, 12);
  Dummy := WinSendMsg(NdPath, EM_SETTEXTLIMIT, 200, 0);
  Dummy := WinSetWindowText(NdPath, Z('\\'));
  Dummy := WinSendMsg(NdPath, EM_SETSEL, 2 Or (2 Shl 16), 0);
  NdLabel(L('Nom d''utilisateur :', 'User name:', 'Benutzername:', 'Nome utente:', 'Usuario:'), 12, H - 96, 160);
  NdUser := NdCtl(WC_ENTRYFIELD, 0, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN, 176, H - 96, W - 188, 20, 13);
  Dummy := WinSendMsg(NdUser, EM_SETTEXTLIMIT, 100, 0);
  NdLabel(L('(DOMAINE\nom ; vide : invit'#130')', '(DOMAIN\name; empty: guest)', '(DOM'#142'NE\Name; leer: Gast)',
            '(DOMINIO\nome; vuoto: ospite)', '(DOMINIO\nombre; vac'#161'o: invitado)'), 176, H - 118, W - 188);
  NdLabel(L('Mot de passe :', 'Password:', 'Kennwort:', 'Password:', 'Contrase'#164'a:'), 12, H - 144, 160);
  NdPass := NdCtl(WC_ENTRYFIELD, 0, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN Or ES_UNREADABLE, 176, H - 144,
                  W - 188, 20, 14);
  Dummy := WinSendMsg(NdPass, EM_SETTEXTLIMIT, 100, 0);
  NdCk := NdCtl(WC_BUTTON, Z(L('Se reconnecter '#133' l''ouverture de session', 'Reconnect at logon',
                               'Verbindung beim Anmelden wiederherstellen', 'Riconnetti all''accesso',
                               'Volver a conectar al iniciar sesi'#162'n')),
                WS_TABSTOP Or BS_AUTOCHECKBOX, 12, 44, W - 24, 20, 15);
  NdGray(NdCk);
  Dummy := WinSendMsg(NdCk, BM_SETCHECK, 1, 0);
  NdButtons(W);
  Open := ' ';
  If NdRun(NdPath) = ID_OK Then Open := NdLet[0];
  NdClose;
  If Open <> ' ' Then NetChanged(Open);
End;

{ Deconnecter un lecteur reseau... (Only : une lettre deja choisie) }
Procedure UnmapDialog(Only : Char);
Var W, H, K, R : LongInt;
Begin
  If Frame = 0 Then Exit;
  ScanDrives;
  NdMode := 1;
  If Only <> ' ' Then
  Begin
    R := NetUnmap(Only);
    If R <> 0 Then Msg(NetErrText(R), MB_OK Or MB_ERROR)
    Else NetForget(Only);
    NetChanged(' ');
    Exit;
  End;
  NdN := 0;
  For K := 3 To 25 Do
    If ((DrvMap And (1 Shl K)) <> 0) And (DrvKind[K] = ekNet) Then
    Begin
      NdLet[NdN] := Chr(65 + K);
      Inc(NdN);
    End;
  If NdN = 0 Then
  Begin
    Msg(L('Aucun lecteur r'#130'seau n''est connect'#130'.', 'No network drive is connected.',
          'Es sind keine Netzlaufwerke verbunden.', 'Nessuna unit'#133' di rete connessa.',
          'No hay unidades de red conectadas.'), MB_OK Or MB_INFORMATION);
    Exit;
  End;
  W := 400; H := 190;
  If Not NdOpen(W, H) Then Exit;
  NdLabel(L('Lecteur r'#130'seau '#133' d'#130'connecter :', 'Network drive to disconnect:', 'Zu trennendes Laufwerk:',
            'Unit'#133' da disconnettere:', 'Unidad que desea desconectar:'), 12, H - 30, W - 24);
  NdList := NdCtl(WC_LISTBOX, 0, WS_TABSTOP, 12, 44, W - 24, H - 82, 16);
  For K := 0 To NdN - 1 Do
    Dummy := WinSendMsg(NdList, LM_INSERTITEM, -1, Z(NdLet[K] + ':   ' + DrvRem[Ord(NdLet[K]) - 65]));
  Dummy := WinSendMsg(NdList, LM_SELECTITEM, 0, 1);
  NdButtons(W);
  R := NdRun(NdList);
  NdClose;
  If R = ID_OK Then NetChanged(' ');
End;

Function DirOfP(P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> '\') Do Dec(K);
  If K = 3 Then DirOfP := Copy(P, 1, 2)          { C:\X -> C: }
  Else If K > 0 Then DirOfP := Copy(P, 1, K - 1)
  Else DirOfP := '';
End;

Function JoinP(Dir, Nm : String) : String;
Begin
  If (Dir <> '') And (Dir[Length(Dir)] = '\') Then JoinP := Dir + Nm Else JoinP := Dir + '\' + Nm;
End;

{ FILESTATUS3 du chemin P dans B (24 octets) ; faux s'il n'existe pas }
Function StatOf(P : String; B : LongInt) : Boolean;
Begin
  StatOf := DosQueryPathInfo(Z(P), 1, B, 24) = 0;
End;

Function PathExists(P : String) : Boolean;
Var B : Array[0..31] Of Byte;
Begin
  PathExists := StatOf(P, LongInt(@B));
End;

Function IsDirP(P : String) : Boolean;
Var B : Array[0..31] Of Byte;
Begin
  IsDirP := StatOf(P, LongInt(@B)) And ((RdL(LongInt(@B) + 20) And $10) <> 0);
End;

{ lecteur en lecture seule (CD-ROM) }
Function ReadOnlyDrv(P : String) : Boolean;
Var K : LongInt;
Begin
  ReadOnlyDrv := False;
  If Length(P) < 2 Then Exit;
  K := Ord(UpCase(P[1])) - 65;
  If (K >= 0) And (K <= 25) Then ReadOnlyDrv := DrvKind[K] = ekCd;
End;

Function FileErrText(R : LongInt) : String;
Begin
  Case R Of
    2, 3 : FileErrText := L('Fichier ou dossier introuvable.', 'File or folder not found.',
                            'Datei oder Ordner nicht gefunden.', 'File o cartella non trovati.',
                            'No se encuentra el archivo o la carpeta.');
    19 : FileErrText := L('Le disque est prot'#130'g'#130' en '#130'criture (CD-ROM).', 'The disk is write-protected.',
                          'Der Datentr'#132'ger ist schreibgesch'#129'tzt.', 'Il disco '#138' protetto da scrittura.',
                          'El disco est'#160' protegido contra escritura.');
    32 : FileErrText := L('Le fichier est utilis'#130' par un autre programme.', 'The file is in use.',
                          'Die Datei wird verwendet.', 'Il file '#138' in uso.', 'El archivo est'#160' en uso.');
    80, 183 : FileErrText := L('Le fichier existe d'#130'j'#133'.', 'The file already exists.',
                               'Die Datei ist bereits vorhanden.', 'Il file esiste gi'#133'.', 'El archivo ya existe.');
    112 : FileErrText := L('Le disque est plein.', 'The disk is full.', 'Der Datentr'#132'ger ist voll.',
                           'Il disco '#138' pieno.', 'El disco est'#160' lleno.');
    123, 206 : FileErrText := L('Nom de fichier incorrect.', 'Invalid file name.', 'Ung'#129'ltiger Dateiname.',
                                'Nome di file non valido.', 'Nombre de archivo no v'#160'lido.');
  Else
    FileErrText := NetErrText(R);
  End;
End;

Procedure FoNote(R : LongInt; Nm : String);
Begin
  If (R <> 0) And (FoErr = 0) Then
  Begin
    FoErr := R;
    FoErrNm := Nm;
  End;
End;

Procedure FoReport;
Begin
  If FoErr <> 0 Then
    Msg(L('Impossible de traiter ', 'Cannot process ', 'Fehler bei ', 'Impossibile elaborare ', 'No se puede procesar ') +
        FoErrNm + Chr(10) + FileErrText(FoErr), MB_OK Or MB_ERROR);
End;

Procedure WaitPtr(On : Boolean);
Var P : LongInt;
Begin
  If On Then P := WinQuerySysPointer(HWND_DESKTOP, 3, 0) Else P := WinQuerySysPointer(HWND_DESKTOP, 1, 0);
  If P <> 0 Then Dummy := WinSetPointer(HWND_DESKTOP, P);
End;

{ supprimer un fichier ou un dossier et tout son contenu }
Function DeleteTree(P : String) : LongInt;
Var H, N, R, A : LongInt; B : Array[0..299] Of Byte; S : String; Found : Boolean;
    St : Array[0..31] Of Byte;
Begin
  If Not StatOf(P, LongInt(@St)) Then
  Begin
    DeleteTree := 2;
    Exit;
  End;
  A := RdL(LongInt(@St) + 20);
  If (A And $10) = 0 Then
  Begin
    { lecture seule, systeme, masque : retires pour supprimer }
    If (A And 7) <> 0 Then
    Begin
      WrB(LongInt(@St) + 20, A And $20);
      Dummy := DosSetPathInfo(Z(P), 1, LongInt(@St), 24, 0);
    End;
    DeleteTree := DosDelete(Z(P));
    Exit;
  End;
  { dossier : supprimer le premier element tant qu'il en reste }
  R := 0;
  Repeat
    Found := False;
    H := -1; N := 1;
    If DosFindFirst(Z(P + '\*'), LongInt(@H), $37, LongInt(@B), 300, LongInt(@N), 1) = 0 Then
    Begin
      Repeat
        S := '';
        For A := 0 To RdB(LongInt(@B) + 28) - 1 Do S := S + Chr(RdB(LongInt(@B) + 29 + A));
        If (S <> '.') And (S <> '..') And (S <> '') Then Found := True
        Else
        Begin
          N := 1;
          If DosFindNext(H, LongInt(@B), 300, LongInt(@N)) <> 0 Then N := 0;
        End;
      Until Found Or (N = 0);
    End;
    If H <> -1 Then Dummy := DosFindClose(H);
    If Found Then R := DeleteTree(P + '\' + S);
  Until (Not Found) Or (R <> 0);
  If R = 0 Then R := DosDeleteDir(Z(P));
  DeleteTree := R;
End;

{ taille, fichiers et dossiers d'une arborescence }
Procedure TreeStats(P : String; Var Files, Dirs : LongInt; Var Size : Double);
Var H, N, A, K : LongInt; B : Array[0..299] Of Byte; S : String;
Begin
  H := -1; N := 1;
  If DosFindFirst(Z(P + '\*'), LongInt(@H), $37, LongInt(@B), 300, LongInt(@N), 1) = 0 Then
    Repeat
      S := '';
      For K := 0 To RdB(LongInt(@B) + 28) - 1 Do S := S + Chr(RdB(LongInt(@B) + 29 + K));
      A := RdL(LongInt(@B) + 24);
      If (S <> '.') And (S <> '..') And (S <> '') Then
      Begin
        If (A And $10) <> 0 Then
        Begin
          Inc(Dirs);
          If Length(P) + Length(S) < 250 Then TreeStats(P + '\' + S, Files, Dirs, Size);
        End
        Else
        Begin
          Inc(Files);
          Size := Size + GlUns(RdL(LongInt(@B) + 16));
        End;
      End;
      N := 1;
    Until DosFindNext(H, LongInt(@B), 300, LongInt(@N)) <> 0;
  If H <> -1 Then Dummy := DosFindClose(H);
End;

{ ---------------------------------------------------- presse-papiers }

Function ClipMem : LongInt;
Var P : LongInt;
Begin
  P := 0;
  If DosGetNamedSharedMem(LongInt(@P), Z(ClipName), 3) <> 0 Then
  Begin
    P := 0;
    If DosAllocSharedMem(LongInt(@P), Z(ClipName), ClipSz, $13) <> 0 Then P := 0
    Else WrL(P, 0);
  End;
  ClipMem := P;
End;

{ texte du presse-papiers de PM (CF_TEXT) egal a celui pose par Copier ? }
Function ClipCurrent(P : LongInt) : Boolean;
Var D, K : LongInt;
Begin
  ClipCurrent := False;
  If (P = 0) Or (RdL(P) = 0) Then Exit;
  If WinOpenClipbrd(Hab) = 0 Then Exit;
  D := WinQueryClipbrdData(Hab, 1);
  If D <> 0 Then
  Begin
    K := 0;
    While (K < 16000) And (RdB(D + K) = RdB(P + ClipTxt + K)) And (RdB(D + K) <> 0) Do Inc(K);
    ClipCurrent := (RdB(D + K) = 0) And (RdB(P + ClipTxt + K) = 0);
  End;
  Dummy := WinCloseClipbrd(Hab);
End;

{ Couper (Mode 2) ou Copier (Mode 1) les elements choisis }
Procedure ClipPut(Mode : LongInt);
Var P, I, N, Q, T, K : LongInt; S : String;
Begin
  If (CurPath = '') Or (SelCount = 0) Then Exit;
  P := ClipMem;
  If P = 0 Then Exit;
  N := 0; Q := P + 16; T := P + ClipTxt;
  For I := 0 To NEnt - 1 Do
    If SelF[I] And (Q - P < ClipTxt - 300) And (T - P < ClipSz - 300) Then
    Begin
      S := EntPath(I);
      PutZ(Q, S); Q := Q + Length(S) + 1;
      If N > 0 Then
      Begin
        WrB(T, 13); WrB(T + 1, 10); T := T + 2;
      End;
      For K := 1 To Length(S) Do WrB(T + K - 1, Ord(S[K]));
      T := T + Length(S);
      Inc(N);
    End;
  WrB(T, 0);
  WrL(P + 4, N);
  WrL(P, Mode);
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    Dummy := WinSetClipbrdData(Hab, P + ClipTxt, 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
End;

Function ClipReady : Boolean;
Begin
  ClipReady := ClipCurrent(ClipMem);
End;

{ "Copie de nom", "Copie (2) de nom"... }
Function CopyName(Dir, Nm : String) : String;
Var K : LongInt; S : String;
Begin
  K := 1;
  Repeat
    If K = 1 Then S := L('Copie de ', 'Copy of ', 'Kopie von ', 'Copia di ', 'Copia de ') + Nm
    Else S := L('Copie (', 'Copy (', 'Kopie (', 'Copia (', 'Copia (') + IStr(K) + L(') de ', ') of ', ') von ',
              ') di ', ') de ') + Nm;
    Inc(K);
  Until Not PathExists(JoinP(Dir, S)) Or (K > 99);
  CopyName := S;
End;

Function SameDrive(A, B : String) : Boolean;
Begin
  SameDrive := (Length(A) >= 2) And (Length(B) >= 2) And (UpCase(A[1]) = UpCase(B[1]));
End;

{ un element S colle dans Dir (Cut : deplacer) ; faux pour tout arreter }
Function PasteOne(S, Dir : String; Cut : Boolean) : Boolean;
Var Nm, D, US, UD : String; R : LongInt;
Begin
  PasteOne := True;
  Nm := BaseName(S);
  US := UpStr(S); UD := UpStr(Dir);
  If Not PathExists(S) Then
  Begin
    FoNote(2, Nm);
    Exit;
  End;
  { un dossier dans lui-meme ou dans un de ses sous-dossiers }
  If (UD = US) Or (Copy(UD, 1, Length(US) + 1) = US + '\') Then
  Begin
    Msg(L('Impossible de copier ', 'Cannot copy ', 'Kann nicht kopieren: ', 'Impossibile copiare ',
          'No se puede copiar ') + Nm + ' : ' +
        L('le dossier de destination est un sous-dossier du dossier source.',
          'the destination folder is a subfolder of the source folder.',
          'der Zielordner ist ein Unterordner des Quellordners.',
          'la cartella di destinazione '#138' una sottocartella dell''origine.',
          'la carpeta de destino es una subcarpeta de la carpeta de origen.'), MB_OK Or MB_ERROR);
    Exit;
  End;
  If UpStr(DirOfP(S)) = UD Then
  Begin
    If Cut Then Exit;                      { deja la }
    D := JoinP(Dir, CopyName(Dir, Nm));
  End
  Else
  Begin
    D := JoinP(Dir, Nm);
    If PathExists(D) Then
    Begin
      R := WinMessageBox(HWND_DESKTOP, Frame,
                         Z(L('Ce dossier contient d'#130'j'#133' un '#130'l'#130'ment nomm'#130' ',
                             'This folder already contains an item named ',
                             'Dieser Ordner enth'#132'lt bereits ', 'Questa cartella contiene gi'#133' ',
                             'Esta carpeta ya contiene ') + Nm + '.' + Chr(10) + Chr(10) +
                           L('Voulez-vous le remplacer ?', 'Do you want to replace it?', 'Ersetzen?',
                             'Sostituirlo?', #168'Desea reemplazarlo?')),
                         Z2(L('Confirmer le remplacement', 'Confirm File Replace', 'Ersetzen best'#132'tigen',
                              'Conferma sostituzione', 'Confirmar reemplazo')), 0,
                         MB_YESNOCANCEL Or MB_ICONQUESTION Or MB_MOVEABLE);
      If R = MBID_CANCEL Then
      Begin
        PasteOne := False;
        Exit;
      End;
      If R <> MBID_YES Then Exit;
      R := DeleteTree(D);
      If R <> 0 Then
      Begin
        FoNote(R, D);
        Exit;
      End;
    End;
  End;
  If Cut And SameDrive(S, D) Then
  Begin
    R := DosMove(Z(S), Z2(D));
    If R = 0 Then Exit;
  End;
  R := DosCopy(Z(S), Z2(D), 0);
  If R <> 0 Then
  Begin
    FoNote(R, Nm);
    Exit;
  End;
  If Cut Then FoNote(DeleteTree(S), Nm);
End;

{ Coller dans Dir }
Procedure DoPaste(Dir : String);
Var P, N, I, Q, Mode : LongInt; S : String;
Begin
  If Dir = '' Then Exit;
  P := ClipMem;
  If Not ClipCurrent(P) Then
  Begin
    WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  If ReadOnlyDrv(Dir) Then
  Begin
    Msg(FileErrText(19), MB_OK Or MB_ERROR);
    Exit;
  End;
  Mode := RdL(P); N := RdL(P + 4);
  FoErr := 0; FoErrNm := '';
  WaitPtr(True);
  Q := P + 16;
  For I := 1 To N Do
  Begin
    S := GetZ(Q);
    Q := Q + Length(S) + 1;
    If Not PasteOne(S, Dir, Mode = 2) Then Break;
  End;
  WaitPtr(False);
  { Couper : la liste ne sert qu'une fois }
  If Mode = 2 Then
  Begin
    WrL(P, 0);
    If WinOpenClipbrd(Hab) <> 0 Then
    Begin
      Dummy := WinEmptyClipbrd(Hab);
      Dummy := WinCloseClipbrd(Hab);
    End;
  End;
  Refresh;
  FoReport;
End;

{ ---------------------------------------------------------- Supprimer }

Procedure DoDelete;
Var N, I, R : LongInt; S : String;
Begin
  If CurPath = '' Then Exit;
  N := SelCount;
  If N = 0 Then Exit;
  If ReadOnlyDrv(CurPath) Then
  Begin
    Msg(FileErrText(19), MB_OK Or MB_ERROR);
    Exit;
  End;
  If N = 1 Then
  Begin
    S := '';
    For I := 0 To NEnt - 1 Do If SelF[I] Then S := E(I)^.Nm;
    S := L('Voulez-vous vraiment supprimer '#174' ', 'Are you sure you want to delete ''',
           'M'#148'chten Sie '#174' ', 'Eliminare '#174' ', #168'Desea eliminar '#174' ') + S +
         L(' '#175' ?', '''?', ' '#175' wirklich l'#148'schen?', ' '#175'?', ' '#175'?');
  End
  Else
    S := L('Voulez-vous vraiment supprimer ces ', 'Are you sure you want to delete these ',
           'M'#148'chten Sie diese ', 'Eliminare questi ', #168'Desea eliminar estos ') + IStr(N) +
         L(' '#130'l'#130'ments ?', ' items?', ' Elemente wirklich l'#148'schen?', ' elementi?', ' elementos?');
  R := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2(L('Confirmer la suppression', 'Confirm Delete',
                     'L'#148'schen best'#132'tigen', 'Conferma eliminazione', 'Confirmar eliminaci'#162'n')), 0,
                     MB_YESNO Or MB_ICONQUESTION Or MB_MOVEABLE);
  If R <> MBID_YES Then Exit;
  FoErr := 0; FoErrNm := '';
  WaitPtr(True);
  For I := 0 To NEnt - 1 Do
    If SelF[I] Then FoNote(DeleteTree(EntPath(I)), E(I)^.Nm);
  WaitPtr(False);
  Refresh;
  FoReport;
End;

{ ------------------------------------------- Renommer, Nouveau dossier }

Function BadName(S : String) : Boolean;
Var K : LongInt;
Begin
  BadName := (S = '') Or (S = '.') Or (S = '..');
  For K := 1 To Length(S) Do
    If Pos(S[K], '\/:*?"<>|') > 0 Then BadName := True;
End;

Procedure RenameOk;
Var S : String; R : LongInt;
Begin
  S := NdText(NdPath);
  While (S <> '') And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
  While (S <> '') And (S[1] = ' ') Do Delete(S, 1, 1);
  If S = BaseName(RnOld) Then
  Begin
    NdEnd := ID_CANCEL;
    Exit;
  End;
  If BadName(S) Then
  Begin
    NdMsg(L('Un nom de fichier ne peut pas contenir les caract'#138'res suivants :', 'A file name cannot contain ' +
            'any of the following characters:', 'Ein Dateiname darf diese Zeichen nicht enthalten:',
            'Un nome di file non pu'#149' contenere:', 'Un nombre de archivo no puede contener:') +
          Chr(10) + '\ / : * ? " < > |', MB_OK Or MB_WARNING);
    Exit;
  End;
  R := DosMove(Z(RnOld), Z2(JoinP(DirOfP(RnOld), S)));
  If R <> 0 Then
  Begin
    NdMsg(FileErrText(R), MB_OK Or MB_ERROR);
    Exit;
  End;
  RnOld := S;
  NdEnd := ID_OK;
End;

{ boite Renommer pour P ; vrai si renomme (RnOld <- nouveau nom) }
Function RenameDialog(P : String) : Boolean;
Var W, H : LongInt; S : String;
Begin
  RenameDialog := False;
  If ReadOnlyDrv(P) Then
  Begin
    Msg(FileErrText(19), MB_OK Or MB_ERROR);
    Exit;
  End;
  RnOld := P;
  S := BaseName(P);
  NdMode := 2;
  NdTitleS := L('Renommer', 'Rename', 'Umbenennen', 'Rinomina', 'Cambiar nombre');
  W := 400; H := 96;
  If Not NdOpen(W, H) Then Exit;
  NdLabel(L('Nouveau nom de ', 'New name for ', 'Neuer Name f'#129'r ', 'Nuovo nome di ', 'Nuevo nombre de ') + S + ' :',
          12, H - 30, W - 24);
  NdPath := NdCtl(WC_ENTRYFIELD, 0, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN, 12, H - 56, W - 24, 20, 12);
  Dummy := WinSendMsg(NdPath, EM_SETTEXTLIMIT, 250, 0);
  Dummy := WinSetWindowText(NdPath, Z(S));
  Dummy := WinSendMsg(NdPath, EM_SETSEL, 255 Shl 16, 0);
  NdButtons(W);
  If NdRun(NdPath) = ID_OK Then RenameDialog := True;
  NdClose;
End;

{ choisit l'element nomme Nm apres une actualisation }
Procedure SelectName(Nm : String);
Var K : LongInt;
Begin
  For K := 0 To NEnt - 1 Do
    If UpStr(E(K)^.Nm) = UpStr(Nm) Then
    Begin
      SelOne(K);
      Focus := 0;
      Geometry;
      ShowSel;
    End;
  Redraw;
End;

Procedure DoRename;
Begin
  If (CurPath = '') Or (Sel < 0) Or (Sel >= NEnt) Or (SelCount <> 1) Or Not SelF[Sel] Then Exit;
  If RenameDialog(EntPath(Sel)) Then
  Begin
    Refresh;
    SelectName(RnOld);
  End;
End;

Procedure DoNewDir;
Var S : String; R, K : LongInt;
Begin
  If CurPath = '' Then Exit;
  If ReadOnlyDrv(CurPath) Then
  Begin
    Msg(FileErrText(19), MB_OK Or MB_ERROR);
    Exit;
  End;
  S := L('Nouveau dossier', 'New Folder', 'Neuer Ordner', 'Nuova cartella', 'Nueva carpeta');
  K := 1;
  While PathExists(JoinP(CurPath, S)) And (K < 99) Do
  Begin
    Inc(K);
    S := L('Nouveau dossier', 'New Folder', 'Neuer Ordner', 'Nuova cartella', 'Nueva carpeta') + ' (' + IStr(K) + ')';
  End;
  R := DosCreateDir(Z(JoinP(CurPath, S)), 0);
  If R <> 0 Then
  Begin
    Msg(FileErrText(R), MB_OK Or MB_ERROR);
    Exit;
  End;
  Refresh;
  SelectName(S);
  { comme Windows : le nom se tape aussitot }
  If RenameDialog(JoinP(CurPath, S)) Then S := RnOld;
  Refresh;
  SelectName(S);
End;

{ ---------------------------------------------------------- Proprietes }

Function DayName(D : LongInt) : String;
Begin
  Case D Of
    0 : DayName := L('dimanche', 'Sunday', 'Sonntag', 'domenica', 'domingo');
    1 : DayName := L('lundi', 'Monday', 'Montag', 'luned'#141, 'lunes');
    2 : DayName := L('mardi', 'Tuesday', 'Dienstag', 'marted'#141, 'martes');
    3 : DayName := L('mercredi', 'Wednesday', 'Mittwoch', 'mercoled'#141, 'mi'#130'rcoles');
    4 : DayName := L('jeudi', 'Thursday', 'Donnerstag', 'gioved'#141, 'jueves');
    5 : DayName := L('vendredi', 'Friday', 'Freitag', 'venerd'#141, 'viernes');
  Else
    DayName := L('samedi', 'Saturday', 'Samstag', 'sabato', 's'#160'bado');
  End;
End;

Function MonthName(M : LongInt) : String;
Begin
  Case M Of
    1 : MonthName := L('janvier', 'January', 'Januar', 'gennaio', 'enero');
    2 : MonthName := L('f'#130'vrier', 'February', 'Februar', 'febbraio', 'febrero');
    3 : MonthName := L('mars', 'March', 'M'#132'rz', 'marzo', 'marzo');
    4 : MonthName := L('avril', 'April', 'April', 'aprile', 'abril');
    5 : MonthName := L('mai', 'May', 'Mai', 'maggio', 'mayo');
    6 : MonthName := L('juin', 'June', 'Juni', 'giugno', 'junio');
    7 : MonthName := L('juillet', 'July', 'Juli', 'luglio', 'julio');
    8 : MonthName := L('ao'#150't', 'August', 'August', 'agosto', 'agosto');
    9 : MonthName := L('septembre', 'September', 'September', 'settembre', 'septiembre');
    10 : MonthName := L('octobre', 'October', 'Oktober', 'ottobre', 'octubre');
    11 : MonthName := L('novembre', 'November', 'November', 'novembre', 'noviembre');
  Else
    MonthName := L('d'#130'cembre', 'December', 'Dezember', 'dicembre', 'diciembre');
  End;
End;

{ date et heure FAT -> "samedi 21 novembre 2026 21:51:30" }
Function LongDate(D, T : LongInt) : String;
Var Y, M, Dd, A, Yy, W : LongInt; S : String;
Begin
  If D = 0 Then
  Begin
    LongDate := L('(inconnue)', '(unknown)', '(unbekannt)', '(sconosciuta)', '(desconocida)');
    Exit;
  End;
  Y := 1980 + ((D Shr 9) And 127); M := (D Shr 5) And 15; Dd := D And 31;
  If (M < 1) Or (M > 12) Then M := 1;
  { jour de la semaine (Sakamoto) }
  A := 0;
  Case M Of
    1 : A := 0; 2 : A := 3; 3 : A := 2; 4 : A := 5; 5 : A := 0; 6 : A := 3;
    7 : A := 5; 8 : A := 1; 9 : A := 4; 10 : A := 6; 11 : A := 2; 12 : A := 4;
  End;
  Yy := Y;
  If M < 3 Then Dec(Yy);
  W := (Yy + Yy Div 4 - Yy Div 100 + Yy Div 400 + A + Dd) Mod 7;
  If Lang = 1 Then S := DayName(W) + ', ' + MonthName(M) + ' ' + IStr(Dd) + ', ' + IStr(Y)
  Else If Lang = 2 Then S := DayName(W) + ', ' + IStr(Dd) + '. ' + MonthName(M) + ' ' + IStr(Y)
  Else S := DayName(W) + ' ' + IStr(Dd) + ' ' + MonthName(M) + ' ' + IStr(Y);
  LongDate := S + ' ' + Two((T Shr 11) And 31) + ':' + Two((T Shr 5) And 63) + ':' + Two((T And 31) * 2);
End;

Function SizeText(V : Double) : String;
Begin
  SizeText := SizeKb(V / 1024) + ' (' + ThousandsD(V) + L(' octets', ' bytes', ' Byte', ' byte', ' bytes') + ')';
End;

{ Appliquer : attributs coches ou decoches (seulement ceux qui changent) }
Function PropsApply : Boolean;
Var K, I, Want, Chg, A, R : LongInt; B : Array[0..31] Of Byte; Bits : Array[0..3] Of LongInt;
Begin
  PropsApply := True;
  If PrRO Then Exit;
  Bits[0] := 1; Bits[1] := 2; Bits[2] := $20; Bits[3] := 4;
  Want := 0; Chg := 0;
  For K := 0 To 3 Do
    If PrCk[K] <> 0 Then
    Begin
      If WinSendMsg(PrCk[K], BM_QUERYCHECK, 0, 0) <> 0 Then Want := Want Or Bits[K];
      If ((Want And Bits[K]) <> 0) <> ((PrAttr0 And Bits[K]) <> 0) Then Chg := Chg Or Bits[K];
    End;
  If Chg = 0 Then Exit;
  For I := 0 To PrN - 1 Do
    If StatOf(PrPath[I], LongInt(@B)) Then
    Begin
      A := RdL(LongInt(@B) + 20);
      A := (A And Not Chg) Or (Want And Chg);
      WrL(LongInt(@B) + 20, A And $37);
      R := DosSetPathInfo(Z(PrPath[I]), 1, LongInt(@B), 24, 0);
      If R <> 0 Then
      Begin
        NdMsg(BaseName(PrPath[I]) + Chr(10) + FileErrText(R), MB_OK Or MB_ERROR);
        PropsApply := False;
        Exit;
      End;
    End;
  PrAttr0 := (PrAttr0 And Not Chg) Or (Want And Chg);
End;

Procedure PrRow(W, H : LongInt; Var Y : LongInt; Lb, V : String);
Begin
  NdLabel(Lb, 14, H - Y - 20, 120);
  NdLabel(Fit(V, W - 160), 140, H - Y - 20, W - 150);
  Y := Y + 22;
End;

{ boite Proprietes des elements de PrPath[0..PrN-1] }
Procedure PropsDialog;
Var W, H, Y, K, A, All, Any, F, D : LongInt; B : Array[0..31] Of Byte; S, T, Ty : String; Sz : Double;
    Bits : Array[0..3] Of LongInt;

Begin
  If PrN = 0 Then Exit;
  PrRO := ReadOnlyDrv(PrPath[0]);
  Bits[0] := 1; Bits[1] := 2; Bits[2] := $20; Bits[3] := 4;
  { attributs communs ; taille et contenu }
  All := $27; Any := 0; Sz := 0; F := 0; D := 0;
  WaitPtr(True);
  For K := 0 To PrN - 1 Do
    If StatOf(PrPath[K], LongInt(@B)) Then
    Begin
      A := RdL(LongInt(@B) + 20);
      All := All And A; Any := Any Or A;
      If (A And $10) <> 0 Then
      Begin
        If PrN > 1 Then Inc(D);
        TreeStats(PrPath[K], F, D, Sz);
      End
      Else
      Begin
        Inc(F);
        Sz := Sz + GlUns(RdL(LongInt(@B) + 12));
      End;
    End;
  WaitPtr(False);
  PrAttr0 := All;
  NdMode := 4;
  W := 430;
  If PrN = 1 Then H := 380 Else H := 260;
  NdTitleS := L('Propri'#130't'#130's de ', 'Properties of ', 'Eigenschaften von ', 'Propriet'#133' di ',
                'Propiedades de ');
  If PrN = 1 Then NdTitleS := NdTitleS + BaseName(PrPath[0])
  Else NdTitleS := L('Propri'#130't'#130's', 'Properties', 'Eigenschaften', 'Propriet'#133, 'Propiedades');
  If Not NdOpen(W, H) Then Exit;
  Y := 14;
  If PrN = 1 Then
  Begin
    S := BaseName(PrPath[0]);
    If Not StatOf(PrPath[0], LongInt(@B)) Then FillChar(B, SizeOf(B), 0);
    A := RdL(LongInt(@B) + 20);
    If (A And $10) <> 0 Then
    Begin
      PrIcon := icFolder;
      Ty := TypeName(S, ekDir);
    End
    Else
    Begin
      PrIcon := FileIcon(S, ekFile);
      Ty := TypeName(S, ekFile);
    End;
    NdLabel(Fit(S, W - 90), 70, H - Y - 26, W - 84);
    Y := 60;
    PrRow(W, H, Y, L('Type :', 'Type:', 'Typ:', 'Tipo:', 'Tipo:'), Ty);
    PrRow(W, H, Y, L('Emplacement :', 'Location:', 'Ort:', 'Percorso:', 'Ubicaci'#162'n:'), DirOfP(PrPath[0]));
    PrRow(W, H, Y, L('Taille :', 'Size:', 'Gr'#148#225'e:', 'Dimensione:', 'Tama'#164'o:'), SizeText(Sz));
    If (A And $10) <> 0 Then
      PrRow(W, H, Y, L('Contenu :', 'Contains:', 'Inhalt:', 'Contenuto:', 'Contiene:'),
          IStr(F) + L(' fichier(s), ', ' file(s), ', ' Datei(en), ', ' file, ', ' archivo(s), ') + IStr(D) +
          L(' dossier(s)', ' folder(s)', ' Ordner', ' cartelle', ' carpeta(s)'));
    Y := Y + 10;
    PrRow(W, H, Y, L('Cr'#130#130' le :', 'Created:', 'Erstellt:', 'Creato:', 'Creado:'), LongDate(RdW(LongInt(@B)),
        RdW(LongInt(@B) + 2)));
    PrRow(W, H, Y, L('Modifi'#130' le :', 'Modified:', 'Ge'#132'ndert:', 'Modificato:', 'Modificado:'),
        LongDate(RdW(LongInt(@B) + 8), RdW(LongInt(@B) + 10)));
    PrRow(W, H, Y, L('Dernier acc'#138's :', 'Accessed:', 'Letzter Zugriff:', 'Ultimo accesso:', #351'ltimo acceso:'),
        LongDate(RdW(LongInt(@B) + 4), RdW(LongInt(@B) + 6)));
  End
  Else
  Begin
    PrIcon := icDocs;
    T := DirOfP(PrPath[0]);
    For K := 1 To PrN - 1 Do If UpStr(DirOfP(PrPath[K])) <> UpStr(T) Then T := '';
    NdLabel(IStr(F) + L(' fichier(s), ', ' file(s), ', ' Datei(en), ', ' file, ', ' archivo(s), ') + IStr(D) +
            L(' dossier(s)', ' folder(s)', ' Ordner', ' cartelle', ' carpeta(s)'), 70, H - Y - 26, W - 84);
    Y := 60;
    PrRow(W, H, Y, L('Type :', 'Type:', 'Typ:', 'Tipo:', 'Tipo:'), L('Plusieurs types', 'Multiple types', 'Verschiedene Typen',
        'Tipi diversi', 'Varios tipos'));
    If T <> '' Then
      PrRow(W, H, Y, L('Emplacement :', 'Location:', 'Ort:', 'Percorso:', 'Ubicaci'#162'n:'), L('Tous dans ', 'All in ',
          'Alle in ', 'Tutti in ', 'Todos en ') + T);
    PrRow(W, H, Y, L('Taille :', 'Size:', 'Gr'#148#225'e:', 'Dimensione:', 'Tama'#164'o:'), SizeText(Sz));
  End;
  Y := Y + 10;
  NdLabel(L('Attributs :', 'Attributes:', 'Attribute:', 'Attributi:', 'Atributos:'), 14, H - Y - 20, 120);
  For K := 0 To 3 Do
  Begin
    Case K Of
      0 : S := L('~Lecture seule', '~Read-only', '~Schreibgesch'#129'tzt', 'Sola ~lettura', 'S'#162'lo ~lectura');
      1 : S := L('~Masqu'#130, '~Hidden', '~Versteckt', '~Nascosto', '~Oculto');
      2 : S := L('~Archive', '~Archive', '~Archiv', '~Archivio', '~Modificado');
    Else
      S := L('S~yst'#138'me', 'S~ystem', 'S~ystem', 'S~istema', 'S~istema');
    End;
    PrCk[K] := NdCtl(WC_BUTTON, Z(S), WS_TABSTOP Or BS_AUTOCHECKBOX, 140 + (K Mod 2) * 140,
                     H - Y - 20 - (K Div 2) * 24, 136, 20, 20 + K);
    NdGray(PrCk[K]);
    If (All And Bits[K]) <> 0 Then Dummy := WinSendMsg(PrCk[K], BM_SETCHECK, 1, 0);
    If PrRO Then Dummy := WinEnableWindow(PrCk[K], 0);
  End;
  Dummy := NdCtl(WC_BUTTON, Z('OK'), WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT, W - 312, 8, 96, 26, ID_OK);
  Dummy := NdCtl(WC_BUTTON, Z(L('Annuler', 'Cancel', 'Abbrechen', 'Annulla', 'Cancelar')), WS_TABSTOP Or BS_PUSHBUTTON,
                 W - 208, 8, 96, 26, ID_CANCEL);
  K := NdCtl(WC_BUTTON, Z(L('A~ppliquer', '~Apply', '~'#154'bernehmen', '~Applica', 'Apl~icar')),
             WS_TABSTOP Or BS_PUSHBUTTON, W - 104, 8, 96, 26, 30);
  If PrRO Then Dummy := WinEnableWindow(K, 0);
  Dummy := NdRun(0);
  NdClose;
  For K := 0 To 3 Do PrCk[K] := 0;
End;

{ Proprietes des elements choisis (ou du dossier affiche) }
Procedure FileProps;
Var I : LongInt;
Begin
  PrN := 0;
  For I := 0 To NEnt - 1 Do
    If SelF[I] And (PrN < 64) Then
    Begin
      PrPath[PrN] := EntPath(I);
      Inc(PrN);
    End;
  If (PrN = 0) And (Length(CurPath) > 2) Then
  Begin
    PrPath[0] := CurPath;
    PrN := 1;
  End;
  PropsDialog;
  Refresh;
End;

{ ==================================================================== }
{ Menus                                                                 }
{ ==================================================================== }

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
  WrW(LongInt(@MenuT) + H, MenuLen - H);
  WrW(LongInt(@MenuT) + H + 4, Count);
End;

Procedure MItem(Style, Attr, Id : LongInt; S : String);
Var K : LongInt;
Begin
  MW(Style); MW(Attr); MW(Id);
  If (Style And MIS_SEPARATOR) = 0 Then
  Begin
    For K := 1 To Length(S) Do MB(Ord(S[K]));
    MB(0);
  End;
End;

{ Connecter un lecteur reseau..., Deconnecter un lecteur reseau... }
Procedure MapItems;
Begin
  MItem(MIS_TEXT, 0, cmMapNet, L('~Connecter un lecteur r'#130'seau...', '~Map Network Drive...',
        'Netzlaufwerk ~verbinden...', '~Connetti unit'#133' di rete...', '~Conectar a unidad de red...'));
  MItem(MIS_TEXT, 0, cmUnmapNet, L('~D'#130'connecter un lecteur r'#130'seau...', '~Disconnect Network Drive...',
        'Netzlaufwerk ~trennen...', '~Disconnetti unit'#133' di rete...', '~Desconectar unidad de red...'));
End;

Procedure BuildMenu;
Var H0, H1 : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, L('~Fichier', '~File', '~Datei', '~File', '~Archivo'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, cmOpen, L('~Ouvrir', '~Open', #148'~ffnen', '~Apri', '~Abrir') + Chr(9) + L('Entr'#130'e',
        'Enter', 'Eingabe', 'Invio', 'Entrar'));
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, cmNewDir, L('~Nouveau dossier', '~New Folder', '~Neuer Ordner', '~Nuova cartella',
        '~Nueva carpeta'));
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, cmDelete, L('~Supprimer', '~Delete', '~L'#148'schen', '~Elimina', '~Eliminar') + Chr(9) +
        L('Suppr', 'Del', 'Entf', 'Canc', 'Supr'));
  MItem(MIS_TEXT, 0, cmRename, L('Reno~mmer', 'Rena~me', '~Umbenennen', '~Rinomina', 'Cambiar ~nombre') + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, cmProps, L('Pr~opri'#130't'#130's', 'P~roperties', '~Eigenschaften', 'P~ropriet'#133,
        '~Propiedades') + Chr(9) + 'Alt+Entr' + L(#130'e', 'er', 'ag', 'o', 'ar'));
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, cmClose, L('~Fermer', '~Close', '~Schlie'#225'en', '~Chiudi', '~Cerrar'));
  MenuClose(H1, 9);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 105, L('~Edition', '~Edit', '~Bearbeiten', '~Modifica', '~Edici'#162'n'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, cmCut, L('Co~uper', 'Cu~t', '~Ausschneiden', '~Taglia', 'Cor~tar') + Chr(9) + 'Ctrl+X');
  MItem(MIS_TEXT, 0, cmCopy, L('~Copier', '~Copy', '~Kopieren', '~Copia', '~Copiar') + Chr(9) + 'Ctrl+C');
  MItem(MIS_TEXT, 0, cmPaste, L('C~oller', '~Paste', '~Einf'#129'gen', 'I~ncolla', '~Pegar') + Chr(9) + 'Ctrl+V');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, cmSelAll, L('~S'#130'lectionner tout', 'Select ~All', 'Alles ~markieren', 'Seleziona ~tutto',
        'Seleccionar ~todo') + Chr(9) + 'Ctrl+A');
  MItem(MIS_TEXT, 0, cmInvSel, L('~Inverser la s'#130'lection', '~Invert Selection', 'Markierung ~umkehren',
        '~Inverti selezione', '~Invertir selecci'#162'n'));
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 110, L('~Affichage', '~View', '~Ansicht', '~Visualizza', '~Ver'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, MIA_CHECKED, cmIcons, L('~Grandes ic'#147'nes', 'Lar~ge Icons', '~Gro'#225'e Symbole',
        'Icone ~grandi', 'Iconos ~grandes'));
  MItem(MIS_TEXT, 0, cmDetails, L('~D'#130'tails', '~Details', '~Details', '~Dettagli', '~Detalles'));
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, cmRefresh, L('~Actualiser', '~Refresh', '~Aktualisieren', '~Aggiorna', '~Actualizar') +
        Chr(9) + 'F5');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 120, L('A~ller '#133, '~Go', '~Wechseln', '~Vai', '~Ir'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, cmUp, L('~Dossier parent', '~Up One Level', '~Eine Ebene h'#148'her', '~Livello superiore',
        '~Subir un nivel') + Chr(9) + L('Retour', 'Backspace', 'R'#129'cktaste', 'Backspace', 'Retroceso'));
  MItem(MIS_TEXT, 0, cmComputer, PathTitle(''));
  MenuClose(H1, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 125, L('~Outils', '~Tools', '~Extras', '~Strumenti', '~Herramientas'));
  H1 := MenuOpen;
  MapItems;
  MenuClose(H1, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 130, '~?');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, cmAbout, L('~A propos de l''Explorateur...', '~About Explorer...', #154'ber ~Explorer...',
        '~Informazioni su Esplora risorse...', '~Acerca del Explorador...'));
  MenuClose(H1, 1);
  MenuClose(H0, 6);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

Procedure SetView(V : LongInt);
Var M : LongInt;
Begin
  If Sel >= 0 Then Top := Sel Div Cols Else Top := 0;
  View := V;
  M := WinWindowFromID(Frame, $8005);
  If V = 0 Then
  Begin
    Dummy := WinSendMsg(M, MM_SETITEMATTR, cmIcons Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16));
    Dummy := WinSendMsg(M, MM_SETITEMATTR, cmDetails Or $10000, MIA_CHECKED);
  End
  Else
  Begin
    Dummy := WinSendMsg(M, MM_SETITEMATTR, cmDetails Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16));
    Dummy := WinSendMsg(M, MM_SETITEMATTR, cmIcons Or $10000, MIA_CHECKED);
  End;
  Geometry;
  If Sel >= 0 Then Top := Sel Div Cols;
  ShowSel;
  Redraw;
End;

{ menu contextuel (X, Y : coordonnees de PM), comme Windows 95 :
  - element choisi : Ouvrir, Couper, Copier, Coller (dossier), Supprimer,
    Renommer, Selectionner tout, Proprietes ;
  - fond d'un dossier : Selectionner tout, Actualiser, Coller, Nouveau
    dossier, Proprietes ;
  - Poste de travail et lecteurs : Ouvrir, Connecter et Deconnecter un
    lecteur reseau (lecteur reseau : Deconnecter), Proprietes ;
  - dossier de l'arbre : Ouvrir, Coller, Nouveau dossier, Proprietes }
Var
  CtxN : LongInt;

Procedure It(Id : LongInt; S : String);
Begin
  MItem(MIS_TEXT, 0, Id, S);
  Inc(CtxN);
End;

Procedure Sep;
Begin
  MItem(MIS_SEPARATOR, 0, 0, '');
  Inc(CtxN);
End;

Procedure Context(X, Y : LongInt; Tree : Boolean);
Var Pc, Net, Item, IsDir : Boolean;
Begin
  MenuLen := 0;
  MW(0); MW(0); MW(0);
  CtxN := 0;
  If Tree Then
  Begin
    Pc := (TSel >= 0) And (TSel < TN) And (NdD[TSel] <= 2) And ((NdP[TSel] = '') Or (Length(NdP[TSel]) = 2));
    Net := (TSel >= 0) And (TSel < TN) And (Length(NdP[TSel]) = 2) And (DrvKind[Ord(UpCase(NdP[TSel][1])) - 65] = ekNet);
    Item := False;
  End
  Else
  Begin
    Pc := CurPath = '';
    Net := Pc And (Sel >= 0) And (Sel < NEnt) And (E(Sel)^.Kind = ekNet);
    Item := (Not Pc) And (Sel >= 0) And (Sel < NEnt) And SelF[Sel];
  End;
  If Item Or Net Or Pc Or Tree Then
  Begin
    It(cmOpen, L('~Ouvrir', '~Open', #148'~ffnen', '~Apri', '~Abrir'));
    Sep;
  End;
  If Item Then
  Begin
    IsDir := (E(Sel)^.Kind = ekDir) And (SelCount = 1);
    It(cmCut, L('Co~uper', 'Cu~t', '~Ausschneiden', '~Taglia', 'Cor~tar'));
    It(cmCopy, L('~Copier', '~Copy', '~Kopieren', '~Copia', '~Copiar'));
    If IsDir Then It(cmPasteIn, L('C~oller', '~Paste', '~Einf'#129'gen', 'I~ncolla', '~Pegar'));
    Sep;
    It(cmDelete, L('~Supprimer', '~Delete', '~L'#148'schen', '~Elimina', '~Eliminar'));
    If SelCount = 1 Then It(cmRename, L('Reno~mmer', 'Rena~me', '~Umbenennen', '~Rinomina', 'Cambiar ~nombre'));
    Sep;
    It(cmSelAll, L('~S'#130'lectionner tout', 'Select ~All', 'Alles ~markieren', 'Seleziona ~tutto',
       'Seleccionar ~todo'));
    Sep;
  End
  Else If Net Then
  Begin
    It(cmDisconnect, L('~D'#130'connecter', '~Disconnect', '~Trennen', '~Disconnetti', '~Desconectar'));
    Sep;
  End
  Else If Pc Then
  Begin
    MapItems;
    CtxN := CtxN + 2;
    Sep;
  End
  Else If Tree Then
  Begin
    It(cmPasteTree, L('C~oller', '~Paste', '~Einf'#129'gen', 'I~ncolla', '~Pegar'));
    It(cmNewDir, L('~Nouveau dossier', '~New Folder', '~Neuer Ordner', '~Nuova cartella', '~Nueva carpeta'));
    Sep;
  End
  Else
  Begin
    { fond du dossier }
    It(cmSelAll, L('~S'#130'lectionner tout', 'Select ~All', 'Alles ~markieren', 'Seleziona ~tutto',
       'Seleccionar ~todo'));
    It(cmRefresh, L('~Actualiser', '~Refresh', '~Aktualisieren', '~Aggiorna', '~Actualizar'));
    Sep;
    It(cmPaste, L('C~oller', '~Paste', '~Einf'#129'gen', 'I~ncolla', '~Pegar'));
    Sep;
    It(cmNewDir, L('~Nouveau dossier', '~New Folder', '~Neuer Ordner', '~Nuova cartella', '~Nueva carpeta'));
    Sep;
  End;
  It(cmProps, L('Pr~opri'#130't'#130's', 'P~roperties', '~Eigenschaften', 'P~ropriet'#133, '~Propiedades'));
  MenuClose(0, CtxN);
  If CtxMenu <> 0 Then Dummy := WinDestroyWindow(CtxMenu);
  CtxMenu := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuT));
  If Item Or Net Or Pc Or Tree Then CtxN := cmOpen Else CtxN := cmSelAll;
  If CtxMenu <> 0 Then Dummy := WinPopupMenu(Client, Client, CtxMenu, X, Y, CtxN, 0);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    cmOpen :
      If Focus = 1 Then
      Begin
        If (TSel >= 0) And (TSel < TN) Then
          If NdP[TSel] = '*' Then Navigate('') Else Navigate(NdP[TSel]);
      End
      Else If Sel >= 0 Then OpenItem(Sel);
    cmProps : Props;
    cmClose : Dummy := WinPostMsg(Client, WM_QUIT, 0, 0);
    cmIcons : SetView(0);
    cmDetails : SetView(1);
    cmRefresh : Refresh;
    cmUp : GoUp;
    cmComputer : Navigate('');
    cmAbout : About;
    cmCut : If Focus = 0 Then ClipPut(2);
    cmCopy : If Focus = 0 Then ClipPut(1);
    cmPaste : DoPaste(CurPath);
    cmPasteIn : If (Sel >= 0) And (Sel < NEnt) And (E(Sel)^.Kind = ekDir) Then DoPaste(EntPath(Sel));
    cmPasteTree : If (TSel >= 0) And (TSel < TN) And (Length(NdP[TSel]) >= 2) Then DoPaste(NdP[TSel]);
    cmDelete : DoDelete;
    cmRename : DoRename;
    cmNewDir : DoNewDir;
    cmSelAll :
    Begin
      Focus := 0;
      SelAll;
      Redraw;
    End;
    cmInvSel :
    Begin
      Focus := 0;
      SelInvert;
      Redraw;
    End;
    cmMapNet : MapDialog;
    cmUnmapNet : UnmapDialog(' ');
    cmDisconnect :
      If Focus = 1 Then
      Begin
        If (TSel >= 0) And (TSel < TN) And (Length(NdP[TSel]) = 2) Then UnmapDialog(UpCase(NdP[TSel][1]));
      End
      Else If (CurPath = '') And (Sel >= 0) And (Sel < NEnt) Then UnmapDialog(UpCase(E(Sel)^.Nm[1]));
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Procedure TreeClick(X, Y : LongInt; Dbl : Boolean);
Var R, D, C, Hh : LongInt; P : String;
Begin
  Focus := 1;
  If (TN > TVis) And (X >= TX2 - 1 - SbW) Then
  Begin
    Hh := ScrollHit(Y, TY1 + 2, TY2 - 2, TTop, TN - TVis);
    If Abs(Hh) = 1 Then TTop := TTop + Hh Else TTop := TTop + (Hh Div 2) * TVis;
    If TTop > TN - TVis Then TTop := TN - TVis;
    If TTop < 0 Then TTop := 0;
    Redraw;
    Exit;
  End;
  R := TTop + (Y - TY1 - 2) Div TreeRow;
  If (R < 0) Or (R >= TN) Or (Y < TY1 + 2) Then
  Begin
    Redraw;
    Exit;
  End;
  D := NdD[R];
  C := 4 + D * 16 - 8;
  If (D >= 1) And (X >= C - 6) And (X <= C + 6) And ((NdF[R] And 2) = 0) Then
  Begin
    If (NdF[R] And 1) <> 0 Then TreeCollapse(R) Else TreeExpand(R);
    Redraw;
    Exit;
  End;
  If Dbl And (D >= 1) Then
  Begin
    If (NdF[R] And 1) <> 0 Then TreeCollapse(R) Else TreeExpand(R);
  End;
  P := NdP[R];
  If P = '*' Then P := '';
  TSel := R;
  If UpStr(P) <> UpStr(CurPath) Then Navigate(P) Else Redraw;
End;

Function HitItem(X, Y : LongInt) : LongInt;
Var I, C : LongInt;
Begin
  HitItem := -1;
  If View = 1 Then
  Begin
    If Y < PY1 + 21 Then Exit;
    I := Top + (Y - PY1 - 21) Div RowH;
    If (Y - PY1 - 21) Div RowH >= VisRows Then Exit;
  End
  Else
  Begin
    If (X < PX1 + 6) Or (Y < PY1 + 6) Then Exit;
    C := (X - PX1 - 6) Div CellW;
    If C >= Cols Then Exit;
    If (Y - PY1 - 6) Div CellH >= VisRows Then Exit;
    I := ((Y - PY1 - 6) Div CellH + Top) * Cols + C;
  End;
  If (I >= 0) And (I < NEnt) Then HitItem := I;
End;

Procedure ContentClick(X, Y : LongInt; Dbl, Btn2 : Boolean);
Var I, Hh : LongInt;
Begin
  Focus := 0;
  If (TotRows > VisRows) And (X >= PX2 - 1 - SbW) And Not Btn2 Then
  Begin
    Hh := ScrollHit(Y, PY1 + 2, PY2 - 2, Top, TotRows - VisRows);
    If Abs(Hh) = 1 Then Top := Top + Hh Else Top := Top + (Hh Div 2) * VisRows;
    ClampTop;
    Redraw;
    Exit;
  End;
  I := HitItem(X, Y);
  If Btn2 Then
  Begin
    { bouton 2 : sur un element deja choisi, la selection reste }
    If I < 0 Then ClearSel
    Else If Not SelF[I] Then SelOne(I)
    Else Sel := I;
  End
  Else If I < 0 Then
  Begin
    If Not KeyDown(VK_CTRLK) Then ClearSel;
  End
  Else If KeyDown(VK_CTRLK) And Not Dbl Then
  Begin
    SelF[I] := Not SelF[I];
    Sel := I; SelA := I;
  End
  Else If KeyDown(VK_SHIFTK) And Not Dbl Then SelRange(I)
  Else SelOne(I);
  Redraw;
  If Dbl And (I >= 0) Then OpenItem(I);
End;

Procedure Mouse(Mp1 : LongInt; Dbl, Btn2 : Boolean);
Var X, Y : LongInt;
Begin
  Geometry;
  X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
  If (X >= TX1) And (X <= TX2) And (Y >= TY1) And (Y <= TY2) Then
  Begin
    If Btn2 Then
    Begin
      TreeClick(X, Y, False);
      Context(S16(Mp1), S16(Mp1 Shr 16), True);
    End
    Else TreeClick(X, Y, Dbl);
  End
  Else If (X >= PX1) And (X <= PX2) And (Y >= PY1) And (Y <= PY2) Then
  Begin
    ContentClick(X, Y, Dbl, Btn2);
    If Btn2 Then Context(S16(Mp1), S16(Mp1 Shr 16), False);
  End;
End;

{ arbre au clavier : haut et bas (le dossier suit), gauche replie ou
  remonte, droite deplie }
Procedure TreeKey(Vk : LongInt);
Var J, D : LongInt; P : String;
Begin
  Case Vk Of
    VK_UP : If TSel > 0 Then Dec(TSel);
    VK_DOWN : If TSel < TN - 1 Then Inc(TSel);
    VK_HOME : TSel := 0;
    VK_END : TSel := TN - 1;
    VK_PAGEUP : TSel := MaxI(0, TSel - TVis);
    VK_PAGEDOWN : TSel := MinI(TN - 1, TSel + TVis);
    VK_RIGHT :
      If (NdF[TSel] And 1) = 0 Then TreeExpand(TSel)
      Else If (TSel + 1 < TN) And (NdD[TSel + 1] > NdD[TSel]) Then Inc(TSel);
    VK_LEFT :
      If (NdF[TSel] And 1) <> 0 Then TreeCollapse(TSel)
      Else
      Begin
        D := NdD[TSel]; J := TSel - 1;
        While (J >= 0) And (NdD[J] >= D) Do Dec(J);
        If J >= 0 Then TSel := J;
      End;
  Else
    Exit;
  End;
  If TSel < TTop Then TTop := TSel;
  If TSel >= TTop + TVis Then TTop := TSel - TVis + 1;
  P := NdP[TSel];
  If P = '*' Then P := '';
  J := TSel;
  If UpStr(P) <> UpStr(CurPath) Then Navigate(P);
  TSel := J;
  Redraw;
End;

Procedure ContentKey(Vk : LongInt);
Var C, N : LongInt;
Begin
  If NEnt = 0 Then Exit;
  C := Cols; N := Sel;
  Case Vk Of
    VK_LEFT : If View = 0 Then N := N - 1;
    VK_RIGHT : If View = 0 Then N := N + 1;
    VK_UP : N := N - C;
    VK_DOWN : If N < 0 Then N := 0 Else N := N + C;
    VK_HOME : N := 0;
    VK_END : N := NEnt - 1;
    VK_PAGEUP : N := N - C * VisRows;
    VK_PAGEDOWN : N := N + C * VisRows;
  Else
    Exit;
  End;
  If N < 0 Then N := 0;
  If N >= NEnt Then N := NEnt - 1;
  If KeyDown(VK_SHIFTK) Then SelRange(N) Else SelOne(N);
  ShowSel;
  Redraw;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Vk, Ch, K, J : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  Geometry;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    Case Vk Of
      VK_ENTER, VK_NEWLINE :
      Begin
        If (Fl And KC_ALT) <> 0 Then Props Else Command(cmOpen);
        Exit;
      End;
      VK_BACKSPACE :
      Begin
        GoUp;
        Exit;
      End;
      VK_F5 :
      Begin
        Refresh;
        Exit;
      End;
      VK_DELETE :
      Begin
        If Focus = 0 Then DoDelete;
        Exit;
      End;
      VK_F2 :
      Begin
        If Focus = 0 Then DoRename;
        Exit;
      End;
      VK_TAB, VK_BACKTAB :
      Begin
        Focus := 1 - Focus;
        If (Focus = 0) And (Sel < 0) And (NEnt > 0) Then SelOne(0);
        Redraw;
        Exit;
      End;
      VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_HOME, VK_END, VK_PAGEUP, VK_PAGEDOWN :
      Begin
        If Focus = 1 Then TreeKey(Vk) Else ContentKey(Vk);
        Exit;
      End;
    End;
  End;
  { Ctrl+A, Ctrl+X, Ctrl+C, Ctrl+V }
  If ((Fl And KC_CTRL) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
  Begin
    If (Ch = 1) Or (UpCase(Chr(Ch)) = 'A') Then Command(cmSelAll)
    Else If (Ch = 24) Or (UpCase(Chr(Ch)) = 'X') Then Command(cmCut)
    Else If (Ch = 3) Or (UpCase(Chr(Ch)) = 'C') Then Command(cmCopy)
    Else If (Ch = 22) Or (UpCase(Chr(Ch)) = 'V') Then Command(cmPaste)
    Else KeyChar := False;
    Exit;
  End;
  { lettre : objet suivant dont le nom commence par elle }
  If ((Fl And KC_CHAR) <> 0) And ((Fl And (KC_CTRL Or KC_ALT)) = 0) And (Ch > 32) And (Ch < 256) And (Focus = 0) And
     (NEnt > 0) Then
  Begin
    For K := 1 To NEnt Do
    Begin
      J := (MaxI(Sel, -1) + K) Mod NEnt;
      If UpCase(EntName(J)[1]) = UpCase(Chr(Ch)) Then
      Begin
        SelOne(J);
        ShowSel;
        Redraw;
        Exit;
      End;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  ClientProc := 0;
  Case Msg Of
    WM_SIZE :
    Begin
      Dummy := WinQueryWindowRect(H, LongInt(@Rc));
      CW := Rc[2]; CH := Rc[3];
      Geometry;
      ShowSel;
    End;
    WM_PAINT : PaintAll(H);
    WM_BUTTON1DOWN :
    Begin
      Dummy := WinSetFocus(HWND_DESKTOP, H);
      Mouse(Mp1, False, False);
      ClientProc := 1;
    End;
    WM_BUTTON1DBLCLK :
    Begin
      Mouse(Mp1, True, False);
      ClientProc := 1;
    End;
    WM_BUTTON2DOWN :
    Begin
      Dummy := WinSetFocus(HWND_DESKTOP, H);
      Mouse(Mp1, False, True);
      ClientProc := 1;
    End;
    WM_CHAR :
      If KeyChar(Mp1, Mp2) Then ClientProc := 1
      Else ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Var
  Fl, Sw, Sh, Fw, Fh, X, Y : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  Start : String;

BEGIN
  FpuCw := $037F;
  asm
    fldcw FpuCw
  end;
  LangInit;
  EntBase := 0;
  If DosAllocMem(LongInt(@EntBase), MaxE * SizeOf(TEnt), $13) <> 0 Then EntBase := 0;
  If EntBase = 0 Then Halt(8);
  NEnt := 0; Sel := -1; Top := 0; View := 0; Focus := 1; CtxMenu := 0;
  NdFr := 0; NdRegDone := False;
  CW := 620; CH := 400;
  ScanDrives;
  { dossier de depart : parametre, sinon C: }
  Start := '';
  PFrame := 0; PClient := 0; PAlone := False;
  If ParamCount > 0 Then Start := UpStr(ParamStr(1));
  { EXPLORER /PROPS:C: : seulement la boite des proprietes du lecteur }
  If (Copy(Start, 1, 7) = '/PROPS:') And (Length(Start) >= 8) Then
  Begin
    Hab := WinInitialize(0);
    Hmq := WinCreateMsgQueue(Hab, 0);
    Client := 0; Frame := 0; PAlone := True;
    DriveProps(Start[8]);
    While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
    Halt(0);
  End;
  { EXPLORER /FPROPS fichier... : seulement la boite Proprietes de ces
    fichiers ou dossiers (menu contextuel du bureau et des dossiers) }
  If (Start = '/FPROPS') And (ParamCount >= 2) Then
  Begin
    Hab := WinInitialize(0);
    Hmq := WinCreateMsgQueue(Hab, 0);
    Client := 0; Frame := 0; PAlone := True;
    PrN := 0;
    For I := 2 To ParamCount Do
      If PrN < 64 Then
      Begin
        PrPath[PrN] := ParamStr(I);
        Inc(PrN);
      End;
    PropsDialog;
    Halt(0);
  End;
  While (Length(Start) > 2) And (Start[Length(Start)] = '\') Do Delete(Start, Length(Start), 1);
  If Start = '' Then
  Begin
    If (DrvMap And 4) <> 0 Then Start := 'C:';
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('OS2EXPLORER'), LongInt(@ClientProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('OS2EXPLORER'), Z2(AppName), 0, 0, 0,
                              LongInt(@Client));
  BuildMenu;
  TreeInit;
  CurPath := Start;
  ListDir(CurPath, False);
  TreeSync;
  SetTitle;
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Fw := MinI(Sw, 620); Fh := MinI(Sh - 40, 440);
  If Sw >= 1000 Then
  Begin
    Fw := 760; Fh := 540;
  End;
  X := MaxI(0, (Sw - Fw) Div 2); Y := MaxI(0, (Sh - Fh) Div 2);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
