{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: VIRTUAL - Virtualisation, gestionnaire de machines
                virtuelles d'OS/2-0 a la facon de VirtualBox, avec les
                menus et l'apparence du Presentation Manager (dossier
                Systeme OS/2).
}

Program VIRTUAL;

{$R-,S-,I-}

{ Compilation : OS2PC APPS\VIRTUAL.PAS VIRTUAL.EXE

  Virtualisation execute des machines virtuelles au format de VirtualBox
  (fichier de machine .vbox en XML, disques VHD fixes ou dynamiques, VDI
  fixes ou dynamiques, images brutes .IMG/.VMDK plates, disquettes de
  1,44 Mo). L'invite s'execute directement sur le processeur : c'est de
  la virtualisation et non de l'emulation. Le noyau (KrnVirt, partie 13e
  d'OS2KRNL) choisit, dans cet ordre :

  - AMD-V (SVM) avec les tables de pages imbriquees (NPT) ;
  - Intel VT-x (VMX) avec EPT et l'invite sans restriction ;
  - plan B : le mode virtuel 8086 du 80386 (comme les sessions DOS
    d'OS/2 2.x), sans mode protege dans l'invite.

  Le menu Machine, Information de virtualisation, montre la methode
  utilisee et tous ses details techniques (processeur, revision SVM ou
  VMX, ASID, EPT, adresses du VMCB/VMCS et des tables, compteurs des
  sorties de l'invite). Sans aucune methode, l'application refuse de
  demarrer.

  Comme KVM, le noyau ne fait que le processeur ; le reste de la machine
  est ici, en Pascal :
  - BIOS : talons des vecteurs (OUT 0EEh puis RETF 2) servis par
    l'application a chaque sortie d'E/S : INT 10h (texte 40/80 x 25 a 50,
    modes 04h, 05h, 06h et 13h, polices utilisateur de DISPLAY.SYS,
    palette), INT 11h, 12h, 13h (CHS, extensions LBA 41h a 48h), 14h, 15h
    (88h, 87h, E801h, E820h, C0h, 24xxh, 4Fh), 16h, 17h, 18h, 19h, 1Ah ;
    gestionnaires INT 08h et 09h de l'invite (code 16 bits ci-dessous) ;
  - controleur d'interruptions 8259A (maitre et esclave), minuterie
    8254 (canaux 0 et 2, port 61h), controleur du clavier 8042 (port 60h,
    64h, commandes du clavier, A20), horloge CMOS (ports 70h et 71h), VGA
    (CRTC, sequenceur, controleur graphique, attributs, DAC, 3DAh), port
    92h, port E9h (journal de l'invite), PCI absent ;
  - affichage dans une fenetre de PM (image de 8 bits par point montree
    par GpiDrawBits), clavier par codes de balayage (KEYB de l'invite
    garde sa disposition).

  - CD-ROM : image ISO 9660, amorcage El Torito (sans emulation, ou
    emulation d'une disquette de 1,2, 1,44 ou 2,88 Mo ou d'un disque
    dur), INT 13h E0h (secteurs de 2048 octets) et 4Bh ;
  - controleurs IDE en PIO : disques ATA sur 1F0h, CD-ROM ATAPI sur
    170h (invites en mode protege : OS2-Zero, Pasdows 95, Linux) ;
  - modes VGA planaires 16 couleurs (0Dh, 0Eh, 10h, 12h) : la fenetre
    A0000h est retiree a l'invite (KrnVirt 7) et chaque instruction qui
    y touche est emulee (plans, verrous, modes d'ecriture et de lecture).

  Fenetre de la machine : menu Peripheriques et clic sur la partie disque
  de la barre d'etat (icones des supports) : choisir ou ejecter l'image du
  CD-ROM ou de la disquette (change par la tache de la machine, note dans
  le .vbox), informations sur les disques. APM 1.2 (INT 15h AH=53h) :
  5307h hors tension eteint la machine et ferme sa fenetre.

  Nouvelle machine : le type est une liste deroulante ; MSDOS-0, UNIX-0,
  OS2-Zero et Pasdows95 sont telecharges a partir de GitHub (image ISO
  d'installation de raw.githubusercontent.com/gladir/..., https par
  TLS32.DLL, proxy HTTP_PROXY, fenetre de progression), puis la machine
  demarre sur ce CD-ROM ; DOS, Windows, Linux et Autre sont fournis
  localement.

  Parametres : /TEST (essais sans fenetre, resultat sur le port serie
  COM1) ; /START:nom (demarre la machine nommee) ; /BOOTTEST:disque ou
  image.ISO /HD:disque /HDMB:n /MEM:n /WAIT:n /RUN:n /KEYS:texte (| ou
  ^ : Entree, # : F5) ; /ADD:fichier (.vbox, disque ou image ISO) ;
  /NEW (Nouvelle machine virtuelle) ; /VMS:dossier ; /TRACE ;
  /SHOT:COM ou /SHOT:fichier.BMP (image de l'invite a la fin de
  /BOOTTEST). }

Const
  WM_CREATE = $0001; WM_DESTROY = $0002; WM_SIZE = $0007; WM_SETFOCUS = $000F;
  WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_CONTROL = $0030; WM_BUTTON1DOWN = $0071; WM_BUTTON1DBLCLK = $0073; WM_CHAR = $007A;
  WM_USER = $1000; WM_VMEND = WM_USER + 1; WM_VMTITLE = WM_USER + 2;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MENU = 4; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10;
  FCF_MAXBUTTON = $20; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_HIDE = $10; SWP_ACTIVATE = $80;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000; WS_GROUP = $00010000;
  WC_COMBOBOX = $FFFF0002; WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006;
  WC_LISTBOX = $FFFF0007;
  BS_PUSHBUTTON = 0; BS_CHECKBOX = 1; BS_AUTOCHECKBOX = 2; BS_DEFAULT = $0400;
  SS_TEXT = 1; SS_GROUPBOX = 2;
  ES_AUTOSCROLL = 4; ES_MARGIN = 8; ES_READONLY = $40;
  CBS_DROPDOWNLIST = 4;
  EM_SETTEXTLIMIT = $0143;
  LM_INSERTITEM = $0161; LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165; LM_DELETEALL = $016E;
  BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_OKCANCEL = 1; MB_YESNO = 4; MB_ICONQUESTION = $10; MB_ICONWARNING = $20;
  MB_INFORMATION = $30; MB_ERROR = $40; MB_MOVEABLE = $4000;
  MBID_OK = 1; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SCANCODE = 4; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20;
  KC_KEYUP = $40;
  VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_PAGEUP = $11; VK_PAGEDOWN = $12;
  VK_END = $13; VK_HOME = $14; VK_INSERT = $1A; VK_DELETE = $1B; VK_ENTER = $1E; VK_NEWLINE = $08;
  VK_F1 = $20;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKCYAN = 13;
  CLR_PALEGRAY = 15; CLR_BLUE = 1;
  { commandes }
  CM_NEW = 101; CM_ADD = 102; CM_REMOVE = 103; CM_QUIT = 104;
  CM_START = 201; CM_SETTINGS = 202; CM_INFO = 203; CM_REFRESH = 204;
  CM_HELP = 301; CM_ABOUT = 302;
  CM_PAUSE = 401; CM_RESET = 402; CM_CAD = 403; CM_POWER = 404; CM_FLOPPY = 405; CM_EJECT = 406;
  CM_ZOOM = 407; CM_VMINFO = 408;
  CM_CDCHOOSE = 410; CM_CDEJECT = 411; CM_FDCHOOSE = 412; CM_FDEJECT = 413; CM_DISKINFO = 414;
  WM_BUTTON2DOWN = $0074;
  ID_LIST = 10; ID_BNEW = 11; ID_BSET = 12; ID_BDEL = 13; ID_BSTART = 14; ID_BINFO = 15;
  ID_OK = 1; ID_CANCEL = 2;
  ID_NAME = 20; ID_TYPE = 21; ID_MEM = 22; ID_HD = 23; ID_FD = 24; ID_NEWHD = 25; ID_HDSZ = 26;
  ID_HD2 = 27;
  IniApp = 'PM_Virtualisation';
  { KrnVirt }
  VX_INFO = 0; VX_CREATE = 1; VX_RUN = 2; VX_DESTROY = 3; VX_FONT = 4; VX_CLEAR = 5;
  VXM_SVM = 1; VXM_VMX = 2; VXM_V86 = 3;
  VXE_IO = 1; VXE_HLT = 2; VXE_INTR = 3; VXE_SHUT = 4; VXE_NPF = 5; VXE_FAIL = 6; VXE_EXC = 7;
  VXE_OTHER = 8;
  { cadre des registres (indices de LongInt) }
  fAX = 0; fBX = 1; fCX = 2; fDX = 3; fSI = 4; fDI = 5; fBP = 6; fSP = 7; fIP = 8; fFL = 9;
  fCS = 10; fDS = 11; fES = 12; fSS = 13; fFS = 14; fGS = 15; fCSB = 16; fDSB = 17; fESB = 18;
  fSSB = 19; fFSB = 20; fGSB = 21; fCR0 = 22; fCR3 = 23; fCR4 = 24; fSET = 25; fIRQ = 26;
  fEXIT = 27; fINFO1 = 28; fINFO2 = 29; fNEXT = 30; fRAW = 31; fCPL = 32; fEFER = 33;
  fCSA = 34;                { bit 0 : segment de code 32 bits }
  { BIOS de l'invite }
  RomStub = $1000;          { F000:1000 + 8n : talon du vecteur n }
  RomInt08 = $E000; RomInt09 = $E03B; RomIrqM = $E04E; RomIrqS = $E055; RomPost = $E05E;
  RomIret = $FF53; RomCfg = $E6F5; RomFdpt = $EFC7; RomHdpt = $E401; RomVpt = $F0A4;
  RomF8 = $FA6E;            { police 8 x 8, caracteres 0 a 127 (adresse du PC) }
  RomF8A = $A000;           { police 8 x 8 complete (A400h : 128 a 255) }
  RomF16 = $C000;           { police 8 x 16 }
  RomF14 = $D000;           { police 8 x 14 }
  { etats de la machine }
  VS_OFF = 0; VS_RUN = 1; VS_PAUSE = 2; VS_HALT = 3;
  { disques }
  DK_RAW = 1; DK_VHDFIX = 2; DK_VHDDYN = 3; DK_VDIFIX = 4; DK_VDIDYN = 5;
  MaxVm = 32;
  { affichage : image de 640 x 480 ; hauteur montree ScrH : 400 (texte 80 x 25
    en 8 x 16, 320 x 200 double), 350 (mode 10h) ou 480 (mode 12h) }
  SW_ = 640; SH_ = 480;

  { code 16 bits du BIOS (nasm, org 0E000h, segment F000) :
    int08 : compteur 0040:006C (minuit 1800B0h), INT 1Ch, EOI ;
    int09 : IN AL,60h, INT 15h AH=4Fh, OUT 0EFh (traduction), EOI ;
    irqm / irqs : EOI du maitre / de l'esclave ; post : OUT 0EDh }
  BiosHex = '501EB840008ED8FF066C007504FF066E00833E6E00187219813E6C00B0007211C7066C000000C7066E000000C606700001CD1CFAB020E6201F58CF50E460B44FF9CD157302E6EFFAB020E62058CF50B020E62058CF50B020E6A0E62058CFE6EDEBFC';
  { secteur d'amorce de l'essai (/TEST) : INT 10h 0Eh, INT 13h 02h, 43h et
    42h, minuterie, INT 16h, mode 13h, INT 15h 88h ; resultats sur E9h }
  TBoot1 = 'FA31C08ED88EC08ED0BC007CFB8816127DBE237DE8EC00B80102BB0080B90200B6008A16127DCD13720C813E00805A5A7504B052E6E9C70600823412B443B000BE137D8A16127DCD13721FC70600820000B442BE137D8A16127DCD13720C813E008234127504B057E6E9A16C0483C005F439066C';
  TBoot3 = '00055564803E1005557406B041E6E9EB04B021E6E9B02EE6E9FAF4AC08C07409B40EBB0700CD10EBF2C3001000010000820000B80B0000000000004D616368696E65207669727475656C6C65203A20616D6F7263616765206475206469737175650D0A004573736169207465726D696E652E0D0A';
  TBoot2 = '0472F9B054E6E9B400CD16E6E9B81300CD10B800A08EC026C60600000FB40FCD103C137504B047E6E9B80300CD10BE4C7DE85B00B488CD1583F8007404B058E6E90F01E0A8017406B02DE6E9EB3B31C08EC0B8FFFF8EE0E49224FCE69226C6060005AA64803E1005AA751AE4920C02E69226C606';

Type
  PByte = ^Byte;
  TVm = Record
    Used : Boolean;
    Name, OsType, Vbox, Hd0, Hd1, Fd, Uuid, Hd0Uuid, Hd1Uuid, Cd, CdUuid, Distro : String;
    MemMb, BootFd, BootCd : LongInt;
  End;

{ ---- DOSCALLS ---- }
Function KrnVirt(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnVirt';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosQuerySysInfo(A, B, P, N : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt; External 'DOSCALLS';
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
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function WinShowWindow(H, Sh : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN';
{ ---- PMGPI ---- }
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiCreateLogColorTable(Hps, Opt, Fmt, St, N, P : LongInt) : LongInt; External 'PMGPI';
{ ---- VIOCALLS : police 8 x 16 du VGA ---- }
Function VioGetFont(PInfo, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetFont';
{ ---- profils (OS2.INI) ---- }
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE';

Var
  Hab, Hmq, Dummy, InDlg, TestMode : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  Qmsg : Array[0..7] Of LongInt;

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

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Function RdW(A : LongInt) : LongInt;
Begin
  RdW := RdB(A) Or (RdB(A + 1) Shl 8);
End;

Procedure WrL(A, V : LongInt);
Begin
  WrW(A, V And $FFFF);
  WrW(A + 2, (V Shr 16) And $FFFF);
End;

Function RdL(A : LongInt) : LongInt;
Begin
  RdL := RdB(A) Or (RdB(A + 1) Shl 8) Or (RdB(A + 2) Shl 16) Or (RdB(A + 3) Shl 24);
End;

{ grand-boutiste (VHD) }
Function RdBE(A : LongInt) : LongInt;
Begin
  RdBE := (RdB(A) Shl 24) Or (RdB(A + 1) Shl 16) Or (RdB(A + 2) Shl 8) Or RdB(A + 3);
End;

Procedure WrBE(A, V : LongInt);
Begin
  WrB(A, (V Shr 24) And 255); WrB(A + 1, (V Shr 16) And 255);
  WrB(A + 2, (V Shr 8) And 255); WrB(A + 3, V And 255);
End;

Procedure ZeroB(A, N : LongInt);
Var K : LongInt;
Begin
  For K := 0 To N - 1 Do WrB(A + K, 0);
End;

Procedure CopyB(Src, Dst, N : LongInt);
Var K : LongInt;
Begin
  If (N <= 0) Or (Src = Dst) Then Exit;
  If (Dst > Src) And (Dst < Src + N) Then
    For K := N - 1 DownTo 0 Do WrB(Dst + K, RdB(Src + K))
  Else
    For K := 0 To N - 1 Do WrB(Dst + K, RdB(Src + K));
End;

{ textes : `e -> e accent aigu, `g -> grave, `a -> a grave, `^ -> e
  circonflexe, `c -> cedille, `E -> E accent aigu, `o -> o circonflexe,
  `i -> i circonflexe, `u -> u grave, `A -> A grave, `b -> a circonflexe
  (page de code 850 de la police d'OS/2-0) }
Function Fr(S : String) : String;
Var R : String; K : LongInt; C : Char;
Begin
  R := ''; K := 1;
  While K <= Length(S) Do
  Begin
    C := S[K];
    If (C = '`') And (K < Length(S)) Then
    Begin
      Inc(K);
      Case S[K] Of
        'e' : C := Chr(130); 'g' : C := Chr(138); 'a' : C := Chr(133); '^' : C := Chr(136);
        'c' : C := Chr(135); 'E' : C := Chr(144); 'o' : C := Chr(147); 'i' : C := Chr(140);
        'u' : C := Chr(151); 'A' : C := Chr(183); 'b' : C := Chr(131); 'C' : C := Chr(128);
      Else
        C := S[K];
      End;
    End;
    R := R + C;
    Inc(K);
  End;
  Fr := R;
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

Function GetZ(A : LongInt) : String;
Var S : String; C : LongInt;
Begin
  S := '';
  C := RdB(A);
  While (C <> 0) And (Length(S) < 255) Do
  Begin
    S := S + Chr(C);
    Inc(A);
    C := RdB(A);
  End;
  GetZ := S;
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function SVal(S : String) : LongInt;
Var V, E : LongInt;
Begin
  Val(S, V, E);
  If E <> 0 Then V := 0;
  SVal := V;
End;

Function Hex(V, N : LongInt) : String;
Const D : String[16] = '0123456789ABCDEF';
Var S : String; I : LongInt;
Begin
  S := '';
  For I := N - 1 DownTo 0 Do S := S + D[((V Shr (I * 4)) And 15) + 1];
  Hex := S;
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

Function Bcd(V : LongInt) : LongInt;
Begin
  Bcd := ((V Div 10) Mod 10) * 16 + V Mod 10;
End;

{ millisecondes depuis le demarrage (QSV_MS_COUNT) }
Function NowMs : LongInt;
Var V : LongInt;
Begin
  V := 0;
  Dummy := DosQuerySysInfo(14, 14, LongInt(@V), 4);
  NowMs := V;
End;

{ journal : port serie COM1 }
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

{ chemins }
Function DirOf(P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> '\') And (P[K] <> '/') And (P[K] <> ':') Do Dec(K);
  DirOf := Copy(P, 1, K);
End;

Function NameOf(P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> '\') And (P[K] <> '/') And (P[K] <> ':') Do Dec(K);
  NameOf := Copy(P, K + 1, 255);
End;

Function ExtOf(P : String) : String;
Var K : LongInt;
Begin
  K := Length(P);
  While (K > 0) And (P[K] <> '.') And (P[K] <> '\') Do Dec(K);
  If (K > 0) And (P[K] = '.') Then ExtOf := UpS(Copy(P, K + 1, 8)) Else ExtOf := '';
End;

Function BaseOf(P : String) : String;
Var S : String; K : LongInt;
Begin
  S := NameOf(P);
  K := Length(S);
  While (K > 0) And (S[K] <> '.') Do Dec(K);
  If K > 1 Then S := Copy(S, 1, K - 1);
  BaseOf := S;
End;

{ fichiers (DosOpen) }
Function FOpen(Path : String; Wr : Boolean) : LongInt;
Var H, A, R : LongInt;
Begin
  H := -1; A := 0;
  If Wr Then R := DosOpen(Z(Path), LongInt(@H), LongInt(@A), 0, 0, $01, $42, 0)
  Else R := DosOpen(Z(Path), LongInt(@H), LongInt(@A), 0, 0, $01, $40, 0);
  If R <> 0 Then H := -1;
  FOpen := H;
End;

Function FCreate(Path : String) : LongInt;
Var H, A : LongInt;
Begin
  H := -1; A := 0;
  If DosOpen(Z(Path), LongInt(@H), LongInt(@A), 0, 0, $12, $42, 0) <> 0 Then H := -1;
  FCreate := H;
End;

Function FExists(Path : String) : Boolean;
Var H : LongInt;
Begin
  H := FOpen(Path, False);
  If H >= 0 Then Dummy := DosClose(H);
  FExists := H >= 0;
End;

Function FSeek(H, Pos : LongInt) : Boolean;
Var A : LongInt;
Begin
  A := 0;
  FSeek := DosSetFilePtr(H, Pos, 0, LongInt(@A)) = 0;
End;

Function FSize(H : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := 0;
  If DosSetFilePtr(H, 0, 2, LongInt(@A)) <> 0 Then A := 0;
  FSize := A;
End;

Function FRead(H, Pos, Buf, N : LongInt) : Boolean;
Var A : LongInt;
Begin
  FRead := False;
  If Not FSeek(H, Pos) Then Exit;
  A := 0;
  If DosRead(H, Buf, N, LongInt(@A)) <> 0 Then Exit;
  If A < N Then ZeroB(Buf + A, N - A);
  FRead := A > 0;
End;

Function FWrite(H, Pos, Buf, N : LongInt) : Boolean;
Var A : LongInt;
Begin
  FWrite := False;
  If Not FSeek(H, Pos) Then Exit;
  A := 0;
  If DosWrite(H, Buf, N, LongInt(@A)) <> 0 Then Exit;
  FWrite := A = N;
End;

{ ---- profils : OS2.INI, application PM_Virtualisation ---- }
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

{ messages longs (plus de 255 caracteres) : texte cumule dans LBuf }
Var
  LBuf : Array[0..8191] Of Byte;
  LLen : LongInt;

Procedure LClr;
Begin
  LLen := 0;
  LBuf[0] := 0;
End;

Procedure LAdd(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If LLen < 8190 Then
    Begin
      LBuf[LLen] := Ord(S[K]);
      Inc(LLen);
    End;
  LBuf[LLen] := 0;
End;

Procedure LLine(S : String);
Begin
  LAdd(S + Chr(10));
End;

{ ==================================================================== }
{ Telechargement d'une image (http:// et https:// par TLS32.DLL)        }
{ ==================================================================== }

{ Bloc insere apres p1.pas (utilitaires WrB, RdB, RdL, IStr, UpS, TrimS,
  Hex, NowMs, Log, DirOf, BaseOf...). Le telechargement tourne dans un
  fil d'execution a part (DosCreateThread) ; la fenetre de progression
  lit DlState, DlTotal, DlDone, DlRate et DlErr sur une minuterie, et
  met DlAbort a 1 pour annuler.

  Logique reprise de GETSRC.PAS : connexion TCP (TCPIP32.DLL), tunnel
  CONNECT du proxy (SET HTTP_PROXY=hote:port, ou HTTPS_PROXY), poignee
  de main TLS (TLS32.DLL, une seule connexion a la fois), requete
  HTTP/1.1, redirections 301/302/303/307/308 (8 au plus), corps
  "chunked", Content-Length ou jusqu'a la fermeture. Le proxy n'est pas
  utilise pour localhost et les adresses privees (10.x, 172.16-31.x,
  192.168.x, 127.x).

  Le corps est recu directement dans un tampon de 64 Ko, ecrit par blocs
  de 64 Ko dans Dest + '.TMP' (ou, si ce nom est refuse, le nom de Dest
  avec l'extension .TMP), puis renomme en Dest (DosMove ; sinon recopie)
  une fois complet. Le .TMP est efface en cas d'erreur ou d'annulation.

  Le fil n'utilise ni Z ni Z2 (tampons NameZ partages avec la fenetre)
  mais ses propres tampons DlZBuf et DlZBuf2. }

Const
  DL_IDLE = 0; DL_CONNECT = 1; DL_GET = 2; DL_DONE = 3; DL_ERROR = 4; DL_CANCEL = 5;
  DlRSz = 32768;
  DlWSz = 65536;

{ ---- TCPIP32 et TLS32 (comme GETSRC.PAS) ---- }
Function NetSockInit : LongInt; External 'TCPIP32' Name 'sock_init';
Function NetSocket(D, T, P : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function NetConnect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function NetSend(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function NetRecv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function NetSoClose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function NetSockErrno : LongInt; External 'TCPIP32' Name 'sock_errno';
Function NetGetHostByName(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
Function NetTlsOpen(S, PHost : LongInt) : LongInt; External 'TLS32' Name 'TLSOPEN';
Function NetTlsSend(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSSEND';
Function NetTlsRecv(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSRECV';
Function NetTlsClose(H : LongInt) : LongInt; External 'TLS32' Name 'TLSCLOSE';
Function NetTlsError(B, Cb : LongInt) : LongInt; External 'TLS32' Name 'TLSERROR';
{ ---- DOSCALLS (absents de p1.pas) ---- }
Function DlDosMove(POld, PNew : LongInt) : LongInt; External 'DOSCALLS' Name 'DosMove';
Function DlDosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS' Name 'DosScanEnv';
Function DlDosQueryFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryFSInfo';

Var
  { interface : etat partage avec la fenetre de progression }
  DlState, DlTotal, DlDone, DlAbort, DlRate, DlHttp : LongInt;
  DlErr, DlUrl, DlDest, DlTmp : String;
  { essai (/TEST) : annuler apres DlTestCut octets (0 : jamais) }
  DlTestCut : LongInt;
  { connexion }
  DlTid, DlNetOk, DlSock, DlTls, DlConn, DlFh, DlPort, DlPxPort, DlT0 : LongInt;
  DlScheme, DlHost, DlPath, DlPxHost, DlLoc : String;
  DlRBuf : Array[0..DlRSz - 1] Of Byte;
  DlRPos, DlRLen : LongInt;
  DlWBuf : Array[0..DlWSz - 1] Of Byte;
  DlWLen : LongInt;
  DlSBuf : Array[0..1023] Of Byte;
  DlZBuf, DlZBuf2 : Array[0..299] Of Byte;
  { vitesse : un releve toutes les 500 ms, moyenne sur les 4 dernieres secondes }
  DlRtT, DlRtB : Array[0..7] Of LongInt;
  DlRtN, DlYT : LongInt;
  DlCrcT : Array[0..255] Of LongInt;

Function DlZ(S : String) : LongInt;
Begin
  PutZ(LongInt(@DlZBuf), S);
  DlZ := LongInt(@DlZBuf);
End;

Function DlZ2(S : String) : LongInt;
Begin
  PutZ(LongInt(@DlZBuf2), S);
  DlZ2 := LongInt(@DlZBuf2);
End;

{ copie rapide (zones disjointes) }
Procedure DlMove(Src, Dst, N : LongInt);
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

Function DlLow(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do If (S[K] >= 'A') And (S[K] <= 'Z') Then S[K] := Chr(Ord(S[K]) + 32);
  DlLow := S;
End;

Function DlHexD(C : Char) : LongInt;
Begin
  If (C >= '0') And (C <= '9') Then DlHexD := Ord(C) - 48
  Else If (C >= 'a') And (C <= 'f') Then DlHexD := Ord(C) - 87
  Else If (C >= 'A') And (C <= 'F') Then DlHexD := Ord(C) - 55
  Else DlHexD := -1;
End;

{ nombre decimal ; Def si illisible }
Function DlNum(S : String; Def : LongInt) : LongInt;
Var V, E : LongInt;
Begin
  Val(TrimS(S), V, E);
  If E <> 0 Then DlNum := Def Else DlNum := V;
End;

Function DlEnv(N : String) : String;
Var P, K : LongInt; S : String;
Begin
  DlEnv := '';
  P := 0;
  If DlDosScanEnv(DlZ(N), LongInt(@P)) <> 0 Then Exit;
  If P = 0 Then Exit;
  S := ''; K := 0;
  While (K < 250) And (RdB(P + K) <> 0) Do
  Begin
    S := S + Chr(RdB(P + K));
    Inc(K);
  End;
  DlEnv := S;
End;

{ proxy : HTTP_PROXY (ou HTTPS_PROXY) = [http://]hote:port[/] }
Procedure DlReadProxy;
Var S : String; K : LongInt;
Begin
  S := TrimS(DlEnv('HTTP_PROXY'));
  If S = '' Then S := TrimS(DlEnv('HTTPS_PROXY'));
  If DlLow(Copy(S, 1, 7)) = 'http://' Then Delete(S, 1, 7);
  While (Length(S) > 0) And (S[Length(S)] = '/') Do Delete(S, Length(S), 1);
  DlPxHost := ''; DlPxPort := 0;
  K := Pos(':', S);
  If K > 1 Then
  Begin
    DlPxHost := Copy(S, 1, K - 1);
    DlPxPort := DlNum(Copy(S, K + 1, 6), 0);
    If (DlPxPort <= 0) Or (DlPxPort > 65535) Then DlPxHost := '';
  End;
End;

{ hote joint directement malgre le proxy : localhost et adresses privees }
Function DlDirect(H : String) : Boolean;
Var K, A, B : LongInt;
Begin
  H := DlLow(H);
  DlDirect := True;
  If (H = 'localhost') Or (Copy(H, 1, 4) = '127.') Or (Copy(H, 1, 3) = '10.') Or (Copy(H, 1, 8) = '192.168.') Then Exit;
  If Copy(H, 1, 4) = '172.' Then
  Begin
    A := 0; K := 5;
    While (K <= Length(H)) And (H[K] >= '0') And (H[K] <= '9') Do
    Begin
      A := A * 10 + Ord(H[K]) - 48;
      Inc(K);
    End;
    B := Ord((K <= Length(H)) And (H[K] = '.'));
    If (B = 1) And (A >= 16) And (A <= 31) Then Exit;
  End;
  DlDirect := False;
End;

Function DlSplit(Url : String) : Boolean;
Var K : LongInt; Rest : String;
Begin
  DlSplit := False;
  K := Pos('://', Url);
  If K = 0 Then Exit;
  DlScheme := DlLow(Copy(Url, 1, K - 1));
  Rest := Copy(Url, K + 3, 255);
  K := Pos('/', Rest);
  If K = 0 Then
  Begin
    DlHost := Rest; DlPath := '/';
  End
  Else
  Begin
    DlHost := Copy(Rest, 1, K - 1); DlPath := Copy(Rest, K, 255);
  End;
  If DlScheme = 'https' Then DlPort := 443 Else DlPort := 80;
  K := Pos(':', DlHost);
  If K > 0 Then
  Begin
    DlPort := DlNum(Copy(DlHost, K + 1, 6), DlPort);
    DlHost := Copy(DlHost, 1, K - 1);
  End;
  DlSplit := (DlHost <> '') And ((DlScheme = 'http') Or (DlScheme = 'https'));
End;

{ adresse de Location (absolue, //hote/..., /chemin ou relative) }
Function DlJoin(Url, Loc : String) : String;
Var Base : String; K : LongInt;
Begin
  If Pos('://', Loc) > 0 Then
  Begin
    DlJoin := Loc;
    Exit;
  End;
  If Not DlSplit(Url) Then
  Begin
    DlJoin := Loc;
    Exit;
  End;
  If Copy(Loc, 1, 2) = '//' Then
  Begin
    DlJoin := DlScheme + ':' + Loc;
    Exit;
  End;
  Base := DlScheme + '://' + DlHost;
  If ((DlScheme = 'https') And (DlPort <> 443)) Or ((DlScheme = 'http') And (DlPort <> 80)) Then
    Base := Base + ':' + IStr(DlPort);
  If Copy(Loc, 1, 1) = '/' Then DlJoin := Base + Loc
  Else
  Begin
    K := Length(DlPath);
    While (K > 0) And (DlPath[K] <> '/') Do Dec(K);
    DlJoin := Base + Copy(DlPath, 1, K) + Loc;
  End;
End;

Function DlHostIp(H : String; Var A0, A1, A2, A3 : LongInt) : Boolean;
Var K, N, V, R, P : LongInt; Num : Boolean; Ip : Array[0..3] Of LongInt; B : Array[0..259] Of Byte;
Begin
  DlHostIp := False;
  Num := H <> '';
  For K := 1 To Length(H) Do If Not (((H[K] >= '0') And (H[K] <= '9')) Or (H[K] = '.')) Then Num := False;
  If Num Then
  Begin
    N := 0; V := 0;
    For K := 1 To Length(H) Do
      If H[K] = '.' Then
      Begin
        If N < 4 Then Ip[N] := V And 255;
        Inc(N); V := 0;
      End
      Else V := V * 10 + Ord(H[K]) - 48;
    If N <> 3 Then Exit;
    Ip[3] := V And 255;
  End
  Else
  Begin
    For K := 1 To Length(H) Do B[K - 1] := Ord(H[K]);
    B[Length(H)] := 0;
    R := NetGetHostByName(LongInt(@B));
    If R = 0 Then Exit;
    P := RdL(RdL(R + 16));
    If P = 0 Then Exit;
    For K := 0 To 3 Do Ip[K] := RdB(P + K);
  End;
  A0 := Ip[0]; A1 := Ip[1]; A2 := Ip[2]; A3 := Ip[3];
  DlHostIp := True;
End;

Procedure DlClose;
Begin
  If DlConn <> 0 Then
  Begin
    If DlTls <> 0 Then Dummy := NetTlsClose(1);
    Dummy := NetSoClose(DlSock);
  End;
  DlConn := 0; DlTls := 0; DlRPos := 0; DlRLen := 0;
End;

Function DlSendB(P, N : LongInt) : Boolean;
Begin
  If DlTls <> 0 Then DlSendB := NetTlsSend(1, P, N) = N Else DlSendB := NetSend(DlSock, P, N, 0) = N;
End;

Function DlSendStr(S : String) : Boolean;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do DlSBuf[K - 1] := Ord(S[K]);
  DlSendStr := DlSendB(LongInt(@DlSBuf), Length(S));
End;

{ au plus N octets de la connexion ; 0 a la fermeture, -1 en cas d'erreur }
Function DlRecv(P, N : LongInt) : LongInt;
Begin
  If DlTls <> 0 Then DlRecv := NetTlsRecv(1, P, N) Else DlRecv := NetRecv(DlSock, P, N, 0);
End;

Function DlFill : Boolean;
Begin
  DlRPos := 0;
  DlRLen := DlRecv(LongInt(@DlRBuf), DlRSz);
  If DlRLen < 0 Then DlRLen := 0;
  DlFill := DlRLen > 0;
End;

Function DlGetB(Var C : LongInt) : Boolean;
Begin
  DlGetB := False;
  If DlRPos >= DlRLen Then If Not DlFill Then Exit;
  C := DlRBuf[DlRPos];
  Inc(DlRPos);
  DlGetB := True;
End;

{ ligne terminee par LF (sans CR) ; faux a la fermeture }
Function DlGetLine(Var S : String) : Boolean;
Var C : LongInt;
Begin
  DlGetLine := False;
  S := '';
  Repeat
    If Not DlGetB(C) Then Exit;
    If C = 10 Then
    Begin
      DlGetLine := True;
      Exit;
    End;
    If (C <> 13) And (Length(S) < 255) Then S := S + Chr(C);
  Until False;
End;

{ raison d'un echec de connect (sock_errno) }
Function DlSockMsg(E : LongInt; Who : String) : String;
Begin
  If E = 10061 Then DlSockMsg := Fr('Connexion refus`ee par ') + Who + '.'
  Else If E = 10060 Then DlSockMsg := Fr('Pas de r`eponse de ') + Who + Fr(' (d`elai d`epass`e).')
  Else If E = 10065 Then DlSockMsg := Who + Fr(' est injoignable (pas de route).')
  Else If E = 10050 Then DlSockMsg := Fr('Le r`eseau ne fonctionne pas (carte r`eseau, DHCP : voir IFCONFIG).')
  Else DlSockMsg := Fr('Connexion impossible `a ') + Who + ' (erreur ' + IStr(E) + ').';
End;

{ connexion a l'hote de DlHost/DlPort (proxy, tunnel CONNECT, TLS) }
Function DlOpen : Boolean;
Var Ad : Array[0..15] Of Byte; A0, A1, A2, A3, K, St, Port : LongInt; Host, Line : String;
    B : Array[0..259] Of Byte; Px : Boolean;
Begin
  DlOpen := False;
  DlClose;
  If DlNetOk = 0 Then
  Begin
    If NetSockInit = 0 Then DlNetOk := 1
    Else
    Begin
      DlErr := Fr('Le r`eseau n''est pas disponible (carte r`eseau, DHCP : voir IFCONFIG).');
      Exit;
    End;
  End;
  Px := (DlPxHost <> '') And Not DlDirect(DlHost);
  Host := DlHost; Port := DlPort;
  If Px Then
  Begin
    Host := DlPxHost; Port := DlPxPort;
  End;
  If Not DlHostIp(Host, A0, A1, A2, A3) Then
  Begin
    If Px Then DlErr := Fr('Proxy introuvable : ') + Host + ' (variable HTTP_PROXY).'
    Else DlErr := Fr('H`ote introuvable : ') + Host + Fr(' (nom inconnu ou serveur de noms injoignable).');
    Exit;
  End;
  For K := 0 To 15 Do Ad[K] := 0;
  Ad[0] := 16; Ad[1] := 2; Ad[2] := (Port Shr 8) And 255; Ad[3] := Port And 255;
  Ad[4] := A0; Ad[5] := A1; Ad[6] := A2; Ad[7] := A3;
  DlSock := NetSocket(2, 1, 0);
  If DlSock < 0 Then
  Begin
    DlErr := Fr('Impossible de cr`eer une connexion (socket).');
    Exit;
  End;
  If NetConnect(DlSock, LongInt(@Ad), 16) <> 0 Then
  Begin
    If Px Then DlErr := 'Proxy : ' + DlSockMsg(NetSockErrno, Host + ':' + IStr(Port))
    Else DlErr := DlSockMsg(NetSockErrno, Host + ':' + IStr(Port));
    Dummy := NetSoClose(DlSock);
    Exit;
  End;
  DlConn := 1; DlTls := 0; DlRPos := 0; DlRLen := 0;
  If DlScheme = 'https' Then
  Begin
    If Px Then
    Begin
      If Not DlSendStr('CONNECT ' + DlHost + ':' + IStr(DlPort) + ' HTTP/1.1' + #13#10 + 'Host: ' + DlHost + ':' +
                       IStr(DlPort) + #13#10#13#10) Then
      Begin
        DlErr := Fr('Le proxy ') + Host + Fr(' ne r`epond pas.');
        DlClose;
        Exit;
      End;
      St := 0;
      Repeat
        If Not DlGetLine(Line) Then
        Begin
          DlErr := Fr('Le proxy ') + Host + Fr(' a ferm`e la connexion.');
          DlClose;
          Exit;
        End;
        If (St = 0) And (Line <> '') Then
        Begin
          K := Pos(' ', Line);
          If K > 0 Then St := DlNum(Copy(Line, K + 1, 3), 0);
        End;
      Until Line = '';
      If (St < 200) Or (St > 299) Then
      Begin
        If St = 407 Then DlErr := Fr('Le proxy ') + Host + Fr(' demande une authentification (code 407).')
        Else DlErr := Fr('Le proxy ') + Host + ' refuse le tunnel vers ' + DlHost + ' (code ' + IStr(St) + ').';
        DlClose;
        Exit;
      End;
      { reste de la reponse du proxy : rien n'est attendu avant TLS }
      DlRPos := 0; DlRLen := 0;
    End;
    For K := 1 To Length(DlHost) Do B[K - 1] := Ord(DlHost[K]);
    B[Length(DlHost)] := 0;
    If NetTlsOpen(DlSock, LongInt(@B)) <> 1 Then
    Begin
      Dummy := NetTlsError(LongInt(@B), 250);
      Line := ''; K := 0;
      While (K < 200) And (B[K] <> 0) Do
      Begin
        Line := Line + Chr(B[K]);
        Inc(K);
      End;
      DlErr := Fr('Connexion s`ecuris`ee (TLS) impossible avec ') + DlHost + ' : ' + Line;
      Dummy := NetSoClose(DlSock);
      DlConn := 0;
      Exit;
    End;
    DlTls := 1;
  End;
  DlOpen := True;
End;

{ vitesse (octets par seconde sur les 4 dernieres secondes) ; cede le
  processeur toutes les 50 ms : TCPIP32 et TLS32 ne sont jamais
  interrompus par la minuterie, et sans cela la fenetre de progression
  (fil principal) ne serait pas servie pendant un transfert rapide }
Procedure DlTick;
Var T, I, J, Dt, Db : LongInt;
Begin
  T := NowMs;
  If (T - DlYT >= 50) Or (T < DlYT) Then
  Begin
    DlYT := T;
    Dummy := DosSleep(0);
  End;
  If (DlRtN > 0) And (T - DlRtT[(DlRtN - 1) And 7] < 500) Then Exit;
  I := DlRtN And 7;
  DlRtT[I] := T; DlRtB[I] := DlDone;
  Inc(DlRtN);
  If DlRtN > 8 Then J := DlRtN And 7 Else J := 0;
  Dt := T - DlRtT[J]; Db := DlDone - DlRtB[J];
  If Dt > 0 Then DlRate := (Db Div Dt) * 1000 + ((Db Mod Dt) * 1000) Div Dt;
End;

{ place libre en Ko sur l'unite du chemin P (0 : inconnue) }
Function DlFreeKb(P : String) : LongInt;
Var Buf : Array[0..23] Of Byte; D : LongInt;
Begin
  DlFreeKb := 0;
  D := 0;
  If (Length(P) >= 2) And (P[2] = ':') Then D := Ord(UpCase(P[1])) - 64;
  If DlDosQueryFSInfo(D, 1, LongInt(@Buf), 18) = 0 Then
    DlFreeKb := RdL(LongInt(@Buf) + 12) * ((RdL(LongInt(@Buf) + 4) * (RdB(LongInt(@Buf) + 16) Or
                (RdB(LongInt(@Buf) + 17) Shl 8))) Div 512) Div 2;
End;

{ tampon d'ecriture vers le .TMP ; faux si le disque est plein }
Function DlFlush : Boolean;
Var A, R : LongInt;
Begin
  DlFlush := True;
  If DlWLen <= 0 Then Exit;
  A := 0;
  R := DosWrite(DlFh, LongInt(@DlWBuf), DlWLen, LongInt(@A));
  If (R <> 0) Or (A <> DlWLen) Then
  Begin
    DlErr := Fr('Disque plein : impossible d''`ecrire ') + DlTmp + ' (' + IStr(DlDone) + Fr(' octets re`cus).');
    DlFlush := False;
  End;
  DlWLen := 0;
End;

{ octets recus : vitesse, tampon plein ecrit ; faux si le disque est plein }
Function DlGot(N : LongInt) : Boolean;
Begin
  DlGot := True;
  DlWLen := DlWLen + N;
  DlDone := DlDone + N;
  DlTick;
  If DlWLen >= DlWSz Then DlGot := DlFlush;
End;

{ au plus N octets du corps vers le tampon d'ecriture : d'abord ce qui
  reste dans DlRBuf, sinon directement de la connexion ; rend le nombre
  d'octets (0 : fermeture, -1 : erreur, -3 : disque plein) }
Function DlBody(N : LongInt) : LongInt;
Var R : LongInt;
Begin
  If N > DlWSz - DlWLen Then N := DlWSz - DlWLen;
  If DlRPos < DlRLen Then
  Begin
    If N > DlRLen - DlRPos Then N := DlRLen - DlRPos;
    DlMove(LongInt(@DlRBuf) + DlRPos, LongInt(@DlWBuf) + DlWLen, N);
    DlRPos := DlRPos + N;
    R := N;
  End
  Else
  Begin
    R := DlRecv(LongInt(@DlWBuf) + DlWLen, N);
    If R <= 0 Then
    Begin
      If R < 0 Then R := -1;
      DlBody := R;
      Exit;
    End;
  End;
  If Not DlGot(R) Then R := -3;
  DlBody := R;
End;

Procedure DlMkDirs(D : String);
Var K : LongInt;
Begin
  While (Length(D) > 3) And (D[Length(D)] = '\') Do Delete(D, Length(D), 1);
  If Length(D) <= 3 Then Exit;
  For K := 4 To Length(D) Do
    If D[K] = '\' Then Dummy := DosCreateDir(DlZ(Copy(D, 1, K - 1)), 0);
  Dummy := DosCreateDir(DlZ(D), 0);
End;

{ .TMP cree (Dest + '.TMP', sinon nom de Dest avec l'extension .TMP) }
Function DlCreateTmp : Boolean;
Var H, A : LongInt;
Begin
  DlCreateTmp := False;
  H := -1; A := 0;
  If DosOpen(DlZ(DlTmp), LongInt(@H), LongInt(@A), 0, 0, $12, $42, 0) <> 0 Then
  Begin
    { nom refuse (FAT 8.3 : deux points) }
    DlTmp := DirOf(DlDest) + BaseOf(DlDest) + '.TMP';
    H := -1; A := 0;
    If (UpS(DlTmp) = UpS(DlDest)) Or (DosOpen(DlZ(DlTmp), LongInt(@H), LongInt(@A), 0, 0, $12, $42, 0) <> 0) Then
    Begin
      DlErr := Fr('Impossible de cr`eer ') + DlTmp + Fr(' (disque plein, prot`eg`e ou dossier absent ?).');
      Exit;
    End;
  End;
  DlFh := H;
  DlCreateTmp := True;
End;

Procedure DlDropTmp;
Begin
  If DlFh >= 0 Then Dummy := DosClose(DlFh);
  DlFh := -1;
  Dummy := DosDelete(DlZ(DlTmp));
End;

{ une requete GET de Url ; corps ecrit dans le .TMP si la reponse est
  200 ; rend le code HTTP, -1 (erreur, DlErr) ou -2 (annule) ; DlLoc :
  en-tete Location }
Function DlGet(Url : String) : LongInt;
Var K, N, Chunk, Clen, Chunked, Got : LongInt; Line, HN, HV, PathQ, Req : String; Px : Boolean;
Begin
  DlGet := -1;
  DlLoc := '';
  If Not DlSplit(Url) Then
  Begin
    DlErr := 'Adresse non valable : ' + Url;
    Exit;
  End;
  If DlAbort <> 0 Then
  Begin
    DlGet := -2;
    Exit;
  End;
  DlState := DL_CONNECT;
  If Not DlOpen Then Exit;
  Px := (DlPxHost <> '') And Not DlDirect(DlHost);
  PathQ := DlPath;
  If Px And (DlScheme = 'http') Then PathQ := Url;
  Req := 'GET ' + PathQ + ' HTTP/1.1' + #13#10 + 'Host: ' + DlHost;
  If ((DlScheme = 'https') And (DlPort <> 443)) Or ((DlScheme = 'http') And (DlPort <> 80)) Then
    Req := Req + ':' + IStr(DlPort);
  Req := Req + #13#10 + 'User-Agent: OS2-0-Virtualisation/1.0 (OS/2-0)' + #13#10 + 'Accept: */*' + #13#10;
  If Not DlSendStr(Req) Then
  Begin
    DlClose;
    DlErr := 'Le serveur ' + DlHost + Fr(' a ferm`e la connexion.');
    Exit;
  End;
  If Not DlSendStr('Accept-Encoding: identity' + #13#10 + 'Connection: close' + #13#10#13#10) Then
  Begin
    DlClose;
    DlErr := 'Le serveur ' + DlHost + Fr(' a ferm`e la connexion.');
    Exit;
  End;
  If Not DlGetLine(Line) Then
  Begin
    DlClose;
    DlErr := 'Le serveur ' + DlHost + Fr(' a ferm`e la connexion sans r`epondre.');
    Exit;
  End;
  DlHttp := 0;
  K := Pos(' ', Line);
  If K > 0 Then DlHttp := DlNum(Copy(Line, K + 1, 3), 0);
  If (DlHttp < 100) Or (Copy(Line, 1, 5) <> 'HTTP/') Then
  Begin
    DlClose;
    DlErr := Fr('R`eponse illisible de ') + DlHost + ' (pas HTTP).';
    Exit;
  End;
  Clen := -1; Chunked := 0;
  Repeat
    If Not DlGetLine(Line) Then
    Begin
      DlClose;
      DlErr := Fr('R`eponse incompl`gte de ') + DlHost + '.';
      Exit;
    End;
    K := Pos(':', Line);
    If K > 0 Then
    Begin
      HN := DlLow(TrimS(Copy(Line, 1, K - 1))); HV := TrimS(Copy(Line, K + 1, 255));
      If HN = 'content-length' Then Clen := DlNum(HV, -1)
      Else If (HN = 'transfer-encoding') And (Pos('chunked', DlLow(HV)) > 0) Then Chunked := 1
      Else If HN = 'location' Then DlLoc := HV;
    End;
  Until Line = '';
  If DlHttp <> 200 Then
  Begin
    DlClose;
    DlGet := DlHttp;
    Exit;
  End;
  { 200 : le corps va dans le .TMP }
  If Chunked <> 0 Then Clen := -1;
  DlTotal := Clen;
  If Clen > 0 Then
  Begin
    K := DlFreeKb(DlTmp);
    If (K > 0) And (Clen Div 1024 + 64 > K) Then
    Begin
      DlClose;
      DlErr := 'Pas assez de place sur ' + Copy(DlDest, 1, 2) + ' : ' + IStr(Clen Div 1048576 + 1) + Fr(' Mo n`ecessaires, ') +
               IStr(K Div 1024) + ' Mo libres.';
      Exit;
    End;
  End;
  If Not DlCreateTmp Then
  Begin
    DlClose;
    Exit;
  End;
  DlState := DL_GET;
  DlWLen := 0; DlDone := 0; DlRtN := 0; DlRate := 0;
  DlTick;
  If Chunked <> 0 Then
  Begin
    Repeat
      If Not DlGetLine(Line) Then
      Begin
        DlErr := Fr('Connexion coup`ee pendant le t`el`echargement (') + IStr(DlDone) + Fr(' octets re`cus).');
        DlDropTmp; DlClose;
        Exit;
      End;
      Chunk := 0;
      K := 1;
      While (K <= Length(Line)) And (DlHexD(Line[K]) >= 0) Do
      Begin
        Chunk := Chunk * 16 + DlHexD(Line[K]);
        Inc(K);
      End;
      If Chunk = 0 Then
      Begin
        { fin : en-tetes de queue jusqu'a la ligne vide }
        Repeat Until (Not DlGetLine(Line)) Or (Line = '');
        Break;
      End;
      While Chunk > 0 Do
      Begin
        If DlAbort <> 0 Then
        Begin
          DlDropTmp; DlClose; DlGet := -2;
          Exit;
        End;
        N := DlBody(Chunk);
        If N <= 0 Then
        Begin
          If N <> -3 Then
            DlErr := Fr('Connexion coup`ee pendant le t`el`echargement (') + IStr(DlDone) + Fr(' octets re`cus).');
          DlDropTmp; DlClose;
          Exit;
        End;
        Chunk := Chunk - N;
      End;
      { CRLF apres le bloc }
      If Not DlGetLine(Line) Then
      Begin
        DlErr := Fr('Connexion coup`ee pendant le t`el`echargement (') + IStr(DlDone) + Fr(' octets re`cus).');
        DlDropTmp; DlClose;
        Exit;
      End;
    Until False;
  End
  Else
  Begin
    Got := 0;
    While (Clen < 0) Or (Got < Clen) Do
    Begin
      If DlAbort <> 0 Then
      Begin
        DlDropTmp; DlClose; DlGet := -2;
        Exit;
      End;
      If Clen >= 0 Then N := DlBody(Clen - Got) Else N := DlBody(DlWSz);
      If N = 0 Then
      Begin
        If Clen < 0 Then Break;
        DlErr := Fr('Transfert interrompu par ') + DlHost + ' (' + IStr(Got) + ' octets sur ' + IStr(Clen) + ').';
        DlDropTmp; DlClose;
        Exit;
      End;
      If N < 0 Then
      Begin
        If N <> -3 Then
        Begin
          If (DlTls = 0) And (NetSockErrno = 10060) Then
            DlErr := Fr('Connexion coup`ee : plus rien re`cu de ') + DlHost + ' depuis 60 s (' + IStr(Got) + ' octets).'
          Else
            DlErr := Fr('Connexion coup`ee pendant le t`el`echargement (') + IStr(Got) + Fr(' octets re`cus).');
        End;
        DlDropTmp; DlClose;
        Exit;
      End;
      Got := Got + N;
    End;
  End;
  DlClose;
  If Not DlFlush Then
  Begin
    DlDropTmp;
    Exit;
  End;
  Dummy := DosClose(DlFh);
  DlFh := -1;
  DlTotal := DlDone;
  DlGet := 200;
End;

Function DlHttpMsg(R : LongInt) : String;
Begin
  If R = 404 Then DlHttpMsg := Fr('Fichier introuvable sur le serveur (erreur HTTP 404).')
  Else If R = 410 Then DlHttpMsg := Fr('Fichier retir`e du serveur (erreur HTTP 410).')
  Else If (R = 401) Or (R = 403) Then DlHttpMsg := Fr('Acc`gs refus`e par le serveur (erreur HTTP ') + IStr(R) + ').'
  Else If R = 429 Then DlHttpMsg := Fr('Trop de demandes (erreur HTTP 429) : r`eessayez plus tard.')
  Else If R >= 500 Then DlHttpMsg := Fr('Erreur du serveur (HTTP ') + IStr(R) + Fr(') : r`eessayez plus tard.')
  Else DlHttpMsg := Fr('Le serveur a r`epondu : erreur HTTP ') + IStr(R) + '.';
End;

{ .TMP complet -> Dest (DosMove ; sinon recopie) }
Function DlRename : Boolean;
Var Hi, Ho, A, R, W : LongInt;
Begin
  DlRename := True;
  Dummy := DosDelete(DlZ(DlDest));
  If DlDosMove(DlZ(DlTmp), DlZ2(DlDest)) = 0 Then Exit;
  DlRename := False;
  Hi := -1; Ho := -1; A := 0;
  If DosOpen(DlZ(DlTmp), LongInt(@Hi), LongInt(@A), 0, 0, $01, $40, 0) <> 0 Then Hi := -1;
  A := 0;
  If DosOpen(DlZ2(DlDest), LongInt(@Ho), LongInt(@A), 0, 0, $12, $42, 0) <> 0 Then Ho := -1;
  If (Hi < 0) Or (Ho < 0) Then
  Begin
    If Hi >= 0 Then Dummy := DosClose(Hi);
    If Ho >= 0 Then Dummy := DosClose(Ho);
    DlErr := Fr('Impossible de cr`eer ') + DlDest + '.';
    Dummy := DosDelete(DlZ(DlTmp));
    Exit;
  End;
  Repeat
    R := 0;
    If DosRead(Hi, LongInt(@DlWBuf), DlWSz, LongInt(@R)) <> 0 Then R := -1;
    If R > 0 Then
    Begin
      W := 0;
      If (DosWrite(Ho, LongInt(@DlWBuf), R, LongInt(@W)) <> 0) Or (W <> R) Then R := -2;
    End;
  Until R <= 0;
  Dummy := DosClose(Hi);
  Dummy := DosClose(Ho);
  Dummy := DosDelete(DlZ(DlTmp));
  If R < 0 Then
  Begin
    Dummy := DosDelete(DlZ(DlDest));
    If R = -2 Then DlErr := Fr('Disque plein : impossible d''`ecrire ') + DlDest + '.'
    Else DlErr := 'Lecture impossible de ' + DlTmp + '.';
    Exit;
  End;
  DlRename := True;
End;

Function DlWorker(Arg : LongInt) : LongInt;
Var Url : String; R, Hops : LongInt; Again : Boolean;
Begin
  DlWorker := 0;
  Url := DlUrl; Hops := 0;
  DlMkDirs(DirOf(DlDest));
  Repeat
    Again := False;
    R := DlGet(Url);
    If (R = 301) Or (R = 302) Or (R = 303) Or (R = 307) Or (R = 308) Then
    Begin
      Inc(Hops);
      If DlLoc = '' Then
      Begin
        DlErr := 'Redirection (HTTP ' + IStr(R) + ') sans adresse.';
        R := -1;
      End
      Else If Hops > 8 Then
      Begin
        DlErr := 'Trop de redirections (' + Url + ').';
        R := -1;
      End
      Else
      Begin
        Url := DlJoin(Url, DlLoc);
        Again := True;
      End;
    End;
  Until Not Again;
  DlClose;
  If R = -2 Then
  Begin
    DlDropTmp;
    DlState := DL_CANCEL;
    Exit;
  End;
  If (R <> 200) And (R <> -1) Then DlErr := DlHttpMsg(R);
  If R <> 200 Then
  Begin
    DlDropTmp;
    DlState := DL_ERROR;
    Exit;
  End;
  If DlAbort <> 0 Then
  Begin
    DlDropTmp;
    DlState := DL_CANCEL;
    Exit;
  End;
  If Not DlRename Then
  Begin
    DlState := DL_ERROR;
    Exit;
  End;
  DlState := DL_DONE;
End;

Function DlBusy : Boolean;
Begin
  DlBusy := (DlState = DL_CONNECT) Or (DlState = DL_GET);
End;

{ lance le telechargement de Url dans le fichier Dest (fil a part) }
Procedure DlStart(Url, Dest : String);
Begin
  If DlBusy Then Exit;
  DlUrl := TrimS(Url); DlDest := TrimS(Dest); DlTmp := DlDest + '.TMP';
  DlErr := ''; DlTotal := -1; DlDone := 0; DlAbort := 0; DlRate := 0; DlHttp := 0;
  DlRtN := 0; DlFh := -1; DlConn := 0; DlTls := 0; DlRPos := 0; DlRLen := 0; DlWLen := 0;
  DlT0 := NowMs;
  DlReadProxy;
  DlState := DL_CONNECT;
  If DosCreateThread(LongInt(@DlTid), LongInt(@DlWorker), 0, 0, 131072) <> 0 Then Dummy := DlWorker(0);
End;

{ essai : telecharge, attend la fin, verifie la taille et la somme CRC-32
  du fichier obtenu ; resultat sur COM1 }
Procedure DlSelfTest(Url, Dest : String);
Var T, Last, H, A, N, Crc, Sz, K, J, C : LongInt;
Begin
  For K := 0 To 255 Do
  Begin
    C := K;
    For J := 1 To 8 Do
      If (C And 1) <> 0 Then C := ((C Shr 1) And $7FFFFFFF) Xor LongInt($EDB88320) Else C := (C Shr 1) And $7FFFFFFF;
    DlCrcT[K] := C;
  End;
  Log('DL : ' + Url + ' -> ' + Dest);
  T := NowMs; Last := T;
  DlStart(Url, Dest);
  If DlPxHost <> '' Then Log('DL : proxy ' + DlPxHost + ':' + IStr(DlPxPort));
  While DlBusy Do
  Begin
    Dummy := DosSleep(100);
    If (DlTestCut > 0) And (DlDone >= DlTestCut) Then DlAbort := 1;
    If NowMs - Last >= 5000 Then
    Begin
      Last := NowMs;
      Log('DL : ' + IStr(DlDone) + ' / ' + IStr(DlTotal) + ' octets, ' + IStr(DlRate Div 1024) + ' Ko/s');
    End;
  End;
  T := NowMs - T;
  If DlState = DL_CANCEL Then
  Begin
    Log(Fr('DL : annul`e apr`gs ') + IStr(DlDone) + ' octets ; .TMP ' + IStr(Ord(FExists(DlTmp))) + ' ; destination ' +
        IStr(Ord(FExists(DlDest))));
    Exit;
  End;
  If DlState <> DL_DONE Then
  Begin
    Log('DL : erreur ' + DlErr + ' ; .TMP ' + IStr(Ord(FExists(DlTmp))));
    Exit;
  End;
  { relecture du fichier final }
  H := FOpen(Dest, False);
  If H < 0 Then
  Begin
    Log(Fr('DL : erreur fichier ') + Dest + ' introuvable');
    Exit;
  End;
  Crc := -1; Sz := 0;
  Repeat
    N := 0;
    If DosRead(H, LongInt(@DlWBuf), DlWSz, LongInt(@N)) <> 0 Then N := 0;
    For K := 0 To N - 1 Do
      Crc := DlCrcT[(Crc Xor DlWBuf[K]) And 255] Xor ((Crc Shr 8) And $00FFFFFF);
    Sz := Sz + N;
  Until N <= 0;
  Dummy := DosClose(H);
  Crc := Crc Xor -1;
  If T <= 0 Then T := 1;
  Log('DL : ok ' + IStr(Sz) + ' octets CRC32 ' + Hex(Crc, 8) + ' (' + IStr(T) + ' ms, ' +
      IStr((Sz Div T) * 1000 Div 1024) + ' Ko/s ; annonce ' + IStr(DlTotal) + ' ; .TMP ' + IStr(Ord(FExists(DlTmp))) + ')');
End;

{ ==================================================================== }
{ Machines : fichiers .vbox (XML de VirtualBox) et registre (OS2.INI)  }
{ ==================================================================== }

Var
  Vms : Array[0..MaxVm - 1] Of TVm;
  NVm, CurVm : LongInt;
  XBuf : Array[0..65535] Of Byte;
  XLen : LongInt;
  Seed : LongInt;

Function Rnd(N : LongInt) : LongInt;
Begin
  Seed := (Seed * 1103515245 + 12345) And $7FFFFFFF;
  Rnd := (Seed Shr 8) Mod N;
End;

Function NewUuid : String;
Var S : String; K : LongInt;
Begin
  S := '{';
  For K := 1 To 32 Do
  Begin
    If (K = 9) Or (K = 13) Or (K = 17) Or (K = 21) Then S := S + '-';
    If K = 13 Then S := S + '4'
    Else S := S + Hex(Rnd(16), 1);
  End;
  S := S + '}';
  For K := 1 To Length(S) Do If (S[K] >= 'A') And (S[K] <= 'F') Then S[K] := Chr(Ord(S[K]) + 32);
  NewUuid := S;
End;

{ ---- lecture du XML : recherche de balises et d'attributs ---- }

Function XRead(Path : String) : Boolean;
Var H, N : LongInt;
Begin
  XRead := False; XLen := 0;
  H := FOpen(Path, False);
  If H < 0 Then Exit;
  N := FSize(H);
  If N > 65000 Then N := 65000;
  If N > 0 Then
    If FRead(H, 0, LongInt(@XBuf), N) Then XLen := N;
  Dummy := DosClose(H);
  XBuf[XLen] := 0;
  XRead := XLen > 0;
End;

{ position de la balise <Tag (a partir de From), -1 sinon }
Function XFind(Tag : String; From : LongInt) : LongInt;
Var I, K : LongInt; Ok : Boolean;
Begin
  XFind := -1;
  Tag := '<' + Tag;
  I := From;
  While I <= XLen - Length(Tag) Do
  Begin
    Ok := True;
    K := 1;
    While Ok And (K <= Length(Tag)) Do
    Begin
      If XBuf[I + K - 1] <> Ord(Tag[K]) Then Ok := False;
      Inc(K);
    End;
    If Ok Then
      If (XBuf[I + Length(Tag)] <= 32) Or (XBuf[I + Length(Tag)] = Ord('>')) Or
         (XBuf[I + Length(Tag)] = Ord('/')) Then
      Begin
        XFind := I;
        Exit;
      End;
    Inc(I);
  End;
End;

{ fin de la balise ouvrante en P (position du '>') }
Function XTagEnd(P : LongInt) : LongInt;
Begin
  While (P < XLen) And (XBuf[P] <> Ord('>')) Do Inc(P);
  XTagEnd := P;
End;

{ valeur de l'attribut Name de la balise en P }
Function XAttr(P : LongInt; Name : String) : String;
Var E, I, K : LongInt; Ok : Boolean; S : String; Q : Byte;
Begin
  XAttr := '';
  If P < 0 Then Exit;
  E := XTagEnd(P);
  Name := ' ' + Name + '=';
  I := P;
  While I < E Do
  Begin
    Ok := True;
    K := 1;
    While Ok And (K <= Length(Name)) Do
    Begin
      If (K = 1) Then
      Begin
        If XBuf[I] > 32 Then Ok := False;
      End
      Else If XBuf[I + K - 1] <> Ord(Name[K]) Then Ok := False;
      Inc(K);
    End;
    If Ok Then
    Begin
      I := I + Length(Name);
      Q := XBuf[I];
      Inc(I);
      S := '';
      While (I < E) And (XBuf[I] <> Q) And (Length(S) < 250) Do
      Begin
        S := S + Chr(XBuf[I]);
        Inc(I);
      End;
      { entites courantes }
      K := Pos('&amp;', S);
      While K > 0 Do
      Begin
        Delete(S, K + 1, 4);
        K := Pos('&amp;', S);
      End;
      XAttr := S;
      Exit;
    End;
    Inc(I);
  End;
End;

{ chemin d'un disque relatif au dossier du fichier .vbox ; un chemin
  d'un autre systeme (Linux, Mac) se ramene au nom du fichier }
Function VmPath(Vbox, Loc : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(Loc) Do If Loc[K] = '/' Then Loc[K] := '\';
  If Loc = '' Then VmPath := ''
  Else If (Length(Loc) > 2) And (Loc[2] = ':') Then
  Begin
    If FExists(Loc) Then VmPath := Loc Else VmPath := DirOf(Vbox) + NameOf(Loc);
  End
  Else If Loc[1] = '\' Then VmPath := DirOf(Vbox) + NameOf(Loc)
  Else VmPath := DirOf(Vbox) + Loc;
End;

{ emplacement du disque d'identifiant U (MediaRegistry) }
Function XMedia(Vbox, U : String) : String;
Var P : LongInt;
Begin
  XMedia := '';
  P := XFind('HardDisk', 0);
  While P >= 0 Do
  Begin
    If UpS(XAttr(P, 'uuid')) = UpS(U) Then
    Begin
      XMedia := VmPath(Vbox, XAttr(P, 'location'));
      Exit;
    End;
    P := XFind('HardDisk', P + 5);
  End;
  P := XFind('Image', 0);
  While P >= 0 Do
  Begin
    If (UpS(XAttr(P, 'uuid')) = UpS(U)) And (XAttr(P, 'location') <> '') Then
    Begin
      XMedia := VmPath(Vbox, XAttr(P, 'location'));
      Exit;
    End;
    P := XFind('Image', P + 5);
  End;
End;

{ machine decrite par un fichier .vbox (VirtualBox 1.x) }
Function VmLoad(Path : String; Var V : TVm) : Boolean;
Var P, Q, E, NHd : LongInt; T, U : String;
Begin
  VmLoad := False;
  If Not XRead(Path) Then Exit;
  P := XFind('Machine', 0);
  If P < 0 Then Exit;
  V.Used := True;
  V.Vbox := Path;
  V.Name := XAttr(P, 'name');
  If V.Name = '' Then V.Name := BaseOf(Path);
  V.OsType := XAttr(P, 'OSType');
  V.Uuid := XAttr(P, 'uuid');
  V.MemMb := 32;
  Q := XFind('Memory', 0);
  If Q >= 0 Then V.MemMb := SVal(XAttr(Q, 'RAMSize'));
  If V.MemMb < 2 Then V.MemMb := 2;
  If V.MemMb > 128 Then V.MemMb := 128;
  V.Hd0 := ''; V.Hd1 := ''; V.Fd := ''; V.Hd0Uuid := ''; V.Hd1Uuid := ''; V.BootFd := 0;
  V.Cd := ''; V.CdUuid := ''; V.BootCd := 0; V.Distro := '';
  { ordre d'amorcage : la disquette ou le CD-ROM (DVD) avant le disque dur ? }
  Q := XFind('Order', 0);
  If Q >= 0 Then
  Begin
    If (XAttr(Q, 'position') = '1') And (XAttr(Q, 'device') = 'Floppy') Then V.BootFd := 1;
    If (XAttr(Q, 'position') = '1') And (XAttr(Q, 'device') = 'DVD') Then V.BootCd := 1;
  End;
  { distribution telechargee (attribut de Virtualisation, ignore par VirtualBox) }
  Q := XFind('Description', 0);
  If Q >= 0 Then V.Distro := XAttr(Q, 'distribution');
  NHd := 0;
  Q := XFind('AttachedDevice', 0);
  While Q >= 0 Do
  Begin
    T := XAttr(Q, 'type');
    E := XFind('Image', Q);
    U := '';
    If (E > Q) And ((XFind('AttachedDevice', Q + 5) < 0) Or (E < XFind('AttachedDevice', Q + 5))) Then
      U := XAttr(E, 'uuid');
    If (T = 'HardDisk') And (U <> '') Then
    Begin
      If NHd = 0 Then Begin V.Hd0 := XMedia(Path, U); V.Hd0Uuid := U; End
      Else If NHd = 1 Then Begin V.Hd1 := XMedia(Path, U); V.Hd1Uuid := U; End;
      Inc(NHd);
    End;
    If (T = 'Floppy') And (U <> '') Then V.Fd := XMedia(Path, U);
    If (T = 'DVD') And (U <> '') Then Begin V.Cd := XMedia(Path, U); V.CdUuid := U; End;
    Q := XFind('AttachedDevice', Q + 5);
  End;
  { sans controleur : premier disque du registre des supports }
  If V.Hd0 = '' Then
  Begin
    Q := XFind('HardDisk', 0);
    If Q >= 0 Then
    Begin
      V.Hd0 := VmPath(Path, XAttr(Q, 'location'));
      V.Hd0Uuid := XAttr(Q, 'uuid');
    End;
  End;
  VmLoad := True;
End;

{ ---- ecriture du .vbox ---- }
Var
  WH, WPos : LongInt;

Procedure WOut(S : String);
Var B : Array[0..259] Of Byte; K : LongInt;
Begin
  S := S + Chr(13) + Chr(10);
  For K := 1 To Length(S) Do B[K - 1] := Ord(S[K]);
  If FWrite(WH, WPos, LongInt(@B), Length(S)) Then WPos := WPos + Length(S);
End;

{ emplacement d'un disque dans le .vbox : relatif s'il est dans le dossier
  de la machine, sinon chemin complet }
Function LocOf(Vbox, Disk : String) : String;
Begin
  If UpS(DirOf(Vbox)) = UpS(DirOf(Disk)) Then LocOf := NameOf(Disk) Else LocOf := Disk;
End;

Function DiskFmt(P : String) : String;
Var E : String;
Begin
  E := ExtOf(P);
  If E = 'VHD' Then DiskFmt := 'VHD'
  Else If E = 'VDI' Then DiskFmt := 'VDI'
  Else If E = 'VMDK' Then DiskFmt := 'VMDK'
  Else DiskFmt := 'RAW';
End;

Function VmSave(Var V : TVm) : Boolean;
Begin
  VmSave := False;
  If V.Uuid = '' Then V.Uuid := NewUuid;
  If (V.Hd0 <> '') And (V.Hd0Uuid = '') Then V.Hd0Uuid := NewUuid;
  If (V.Hd1 <> '') And (V.Hd1Uuid = '') Then V.Hd1Uuid := NewUuid;
  If (V.Cd <> '') And (V.CdUuid = '') Then V.CdUuid := NewUuid;
  If V.OsType = '' Then V.OsType := 'DOS';
  Dummy := DosDelete(Z(V.Vbox));
  WH := FCreate(V.Vbox);
  If WH < 0 Then Exit;
  WPos := 0;
  WOut('<?xml version="1.0"?>');
  WOut('<!-- Virtualisation d''OS/2-0 (format de VirtualBox) -->');
  WOut('<VirtualBox xmlns="http://www.virtualbox.org/" version="1.16-windows">');
  WOut('  <Machine uuid="' + V.Uuid + '" name="' + V.Name + '" OSType="' + V.OsType + '" snapshotFolder="Snapshots">');
  WOut('    <MediaRegistry>');
  WOut('      <HardDisks>');
  If V.Hd0 <> '' Then
    WOut('        <HardDisk uuid="' + V.Hd0Uuid + '" location="' + LocOf(V.Vbox, V.Hd0) + '" format="' + DiskFmt(V.Hd0) +
         '" type="Normal"/>');
  If V.Hd1 <> '' Then
    WOut('        <HardDisk uuid="' + V.Hd1Uuid + '" location="' + LocOf(V.Vbox, V.Hd1) + '" format="' + DiskFmt(V.Hd1) +
         '" type="Normal"/>');
  WOut('      </HardDisks>');
  If V.Cd <> '' Then
  Begin
    WOut('      <DVDImages>');
    WOut('        <Image uuid="' + V.CdUuid + '" location="' + LocOf(V.Vbox, V.Cd) + '"/>');
    WOut('      </DVDImages>');
  End;
  If V.Fd <> '' Then
  Begin
    WOut('      <FloppyImages>');
    WOut('        <Image uuid="{0f0f0f0f-0000-4000-8000-000000000001}" location="' + V.Fd + '"/>');
    WOut('      </FloppyImages>');
  End;
  WOut('    </MediaRegistry>');
  If V.Distro <> '' Then WOut('    <Description distribution="' + V.Distro + '"/>');
  WOut('    <Hardware>');
  WOut('      <CPU>');
  WOut('        <HardwareVirtExLargePages enabled="false"/>');
  WOut('      </CPU>');
  WOut('      <Memory RAMSize="' + IStr(V.MemMb) + '"/>');
  WOut('      <Boot>');
  If V.BootCd <> 0 Then
  Begin
    WOut('        <Order position="1" device="DVD"/>');
    WOut('        <Order position="2" device="HardDisk"/>');
    WOut('        <Order position="3" device="Floppy"/>');
  End
  Else If V.BootFd <> 0 Then
  Begin
    WOut('        <Order position="1" device="Floppy"/>');
    WOut('        <Order position="2" device="HardDisk"/>');
  End
  Else
  Begin
    WOut('        <Order position="1" device="HardDisk"/>');
    WOut('        <Order position="2" device="Floppy"/>');
  End;
  WOut('      </Boot>');
  WOut('      <Display VRAMSize="8"/>');
  WOut('    </Hardware>');
  WOut('    <StorageControllers>');
  WOut('      <StorageController name="IDE" type="PIIX4" PortCount="2" useHostIOCache="true" Bootable="true">');
  If V.Hd0 <> '' Then
  Begin
    WOut('        <AttachedDevice type="HardDisk" hotpluggable="false" port="0" device="0">');
    WOut('          <Image uuid="' + V.Hd0Uuid + '"/>');
    WOut('        </AttachedDevice>');
  End;
  If V.Hd1 <> '' Then
  Begin
    WOut('        <AttachedDevice type="HardDisk" hotpluggable="false" port="0" device="1">');
    WOut('          <Image uuid="' + V.Hd1Uuid + '"/>');
    WOut('        </AttachedDevice>');
  End;
  If V.Cd <> '' Then
  Begin
    WOut('        <AttachedDevice passthrough="false" type="DVD" hotpluggable="false" port="1" device="0">');
    WOut('          <Image uuid="' + V.CdUuid + '"/>');
    WOut('        </AttachedDevice>');
  End;
  WOut('      </StorageController>');
  WOut('      <StorageController name="Floppy" type="I82078" PortCount="1" useHostIOCache="true" Bootable="true">');
  WOut('        <AttachedDevice type="Floppy" hotpluggable="false" port="0" device="0">');
  If V.Fd <> '' Then WOut('          <Image uuid="{0f0f0f0f-0000-4000-8000-000000000001}"/>');
  WOut('        </AttachedDevice>');
  WOut('      </StorageController>');
  WOut('    </StorageControllers>');
  WOut('  </Machine>');
  WOut('</VirtualBox>');
  Dummy := DosClose(WH);
  VmSave := True;
End;

{ ---- registre : liste des fichiers .vbox dans OS2.INI ---- }

Procedure RegSave;
Var K : LongInt;
Begin
  IniWrite('Machines', IStr(NVm));
  For K := 0 To NVm - 1 Do IniWrite('Machine' + IStr(K), Vms[K].Vbox);
End;

Function VmAddFile(Path : String) : LongInt;
Var K : LongInt; V : TVm;
Begin
  VmAddFile := -1;
  For K := 0 To NVm - 1 Do
    If UpS(Vms[K].Vbox) = UpS(Path) Then
    Begin
      VmAddFile := K;
      Exit;
    End;
  If NVm >= MaxVm Then Exit;
  If Not VmLoad(Path, V) Then Exit;
  Vms[NVm] := V;
  VmAddFile := NVm;
  Inc(NVm);
End;

{ dossier des machines : C:\VMS, ou D:\VMS si C: est en lecture seule
  (OS/2-0 amorce depuis son CD-ROM) }
Var
  VmsRootS : String;

Function VmsDir : String;
Var H : LongInt; D : String; K : LongInt;
Begin
  If VmsRootS = '' Then
  Begin
    VmsRootS := 'C:\VMS\';
    For K := 0 To 1 Do
    Begin
      D := Chr(Ord('C') + K) + ':\VMS';
      Dummy := DosCreateDir(Z(D), 0);
      H := FCreate(D + '\VMS.TMP');
      If H >= 0 Then
      Begin
        Dummy := DosClose(H);
        Dummy := DosDelete(Z(D + '\VMS.TMP'));
        VmsRootS := D + '\';
        Break;
      End;
    End;
  End;
  VmsDir := VmsRootS;
End;

{ machine creee pour un disque seul (.vhd, .vdi, .img) : son .vbox est
  ecrit a cote du disque }
Function VmFromDisk(Disk : String) : LongInt;
Var V : TVm; K : LongInt;
Begin
  VmFromDisk := -1;
  For K := 0 To NVm - 1 Do
    If UpS(Vms[K].Hd0) = UpS(Disk) Then
    Begin
      VmFromDisk := K;
      Exit;
    End;
  If NVm >= MaxVm Then Exit;
  V.Used := True;
  V.Name := BaseOf(Disk);
  For K := 1 To Length(V.Name) Do If V.Name[K] = '_' Then V.Name[K] := ' ';
  V.OsType := 'DOS'; V.MemMb := 32; V.Hd0 := Disk; V.Hd1 := ''; V.Fd := ''; V.BootFd := 0;
  V.Cd := ''; V.CdUuid := ''; V.BootCd := 0; V.Distro := '';
  V.Uuid := ''; V.Hd0Uuid := ''; V.Hd1Uuid := '';
  V.Vbox := DirOf(Disk) + BaseOf(Disk) + '.VBOX';
  If ExtOf(Disk) = 'ISO' Then
  Begin
    { CD-ROM seul : machine amorcee par le CD-ROM, sans disque dur }
    V.Hd0 := ''; V.Cd := Disk; V.BootCd := 1;
  End;
  If FExists(V.Vbox) Then
  Begin
    VmFromDisk := VmAddFile(V.Vbox);
    Exit;
  End;
  If Not VmSave(V) Then
  Begin
    { dossier en lecture seule (CD-ROM) : .vbox dans C:\VMS }
    V.Vbox := VmsDir + BaseOf(Disk) + '.VBOX';
    If Not VmSave(V) Then Exit;
  End;
  Vms[NVm] := V;
  VmFromDisk := NVm;
  Inc(NVm);
End;

Function FindName(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  For K := 0 To RdB(A + 28) - 1 Do S := S + Chr(RdB(A + 29 + K));
  FindName := S;
End;

{ dossier C:\VMS : machines (.vbox) et disques sans machine }
Procedure ScanDir(Dir : String; Depth : LongInt);
Var Buf : Array[0..299] Of Byte; HD, Cnt, R : LongInt; N, E : String; Attr : LongInt;
Begin
  HD := -1; Cnt := 1;
  R := DosFindFirst(Z(Dir + '*.*'), LongInt(@HD), $37, LongInt(@Buf), SizeOf(Buf), LongInt(@Cnt), 1);
  While (R = 0) And (Cnt > 0) Do
  Begin
    N := FindName(LongInt(@Buf));
    Attr := RdL(LongInt(@Buf) + 24);
    If (N <> '.') And (N <> '..') Then
    Begin
      E := ExtOf(N);
      If (Attr And $10) <> 0 Then
      Begin
        If Depth < 1 Then ScanDir(Dir + N + '\', Depth + 1);
      End
      Else If E = 'VBOX' Then Dummy := VmAddFile(Dir + N);
    End;
    Cnt := 1;
    R := DosFindNext(HD, LongInt(@Buf), SizeOf(Buf), LongInt(@Cnt));
  End;
  If HD <> -1 Then Dummy := DosFindClose(HD);
  { disques sans .vbox }
  HD := -1; Cnt := 1;
  R := DosFindFirst(Z(Dir + '*.*'), LongInt(@HD), $27, LongInt(@Buf), SizeOf(Buf), LongInt(@Cnt), 1);
  While (R = 0) And (Cnt > 0) Do
  Begin
    N := FindName(LongInt(@Buf));
    E := ExtOf(N);
    If (E = 'VHD') Or (E = 'VDI') Then
      If Not FExists(Dir + BaseOf(N) + '.VBOX') Then Dummy := VmFromDisk(Dir + N);
    Cnt := 1;
    R := DosFindNext(HD, LongInt(@Buf), SizeOf(Buf), LongInt(@Cnt));
  End;
  If HD <> -1 Then Dummy := DosFindClose(HD);
End;

Procedure RegLoad;
Var N, K : LongInt; P : String;
Begin
  NVm := 0;
  N := SVal(IniRead('Machines'));
  For K := 0 To N - 1 Do
  Begin
    P := IniRead('Machine' + IStr(K));
    If (P <> '') And FExists(P) Then Dummy := VmAddFile(P);
  End;
  ScanDir(VmsDir, 0);
  RegSave;
End;

{ ==================================================================== }
{ Disques : VHD (fixe, dynamique), VDI (fixe, dynamique), brut, VMDK   }
{ plat ; disque 0 et 1 (80h, 81h), disquette (00h), CD-ROM ISO 9660    }
{ (unite 3, E0h) et image El Torito emulee (unite 4 : disquette ou     }
{ disque dur dans l'image du CD-ROM, meme fichier)                     }
{ ==================================================================== }

Const
  MaxBat = 16384;
  NDk = 5;
  DkCd = 3; DkEmu = 4;

Var
  DkH, DkKind, DkSect, DkCyl, DkHeads, DkSpt, DkRO, DkBlkSec, DkBmp, DkTbl, DkEnd, DkNBlk : Array[0..NDk - 1] Of LongInt;
  DkData, DkExtra, DkAlloc, DkReads, DkWrites : Array[0..NDk - 1] Of LongInt;
  DkPath, DkFmt : Array[0..NDk - 1] Of String;
  DkFoot : Array[0..NDk * 512 - 1] Of Byte;
  Bat : Array[0..NDk * MaxBat - 1] Of LongInt;
  SecBuf : Array[0..4095] Of Byte;
  ZBuf : Array[0..32767] Of Byte;
  DkErr : String;
  { El Torito : CdEmu = type de l'entree d'amorce (0 sans emulation,
    1 a 3 disquette de 1,2, 1,44 ou 2,88 Mo, 4 disque dur), CdOn = vrai
    si le CD-ROM est amorcable ; CdEmuOn : emulation active (amorce par
    le CD-ROM, jusqu'a INT 13h AX=4B00h) }
  CdOn, CdEmuOn : Boolean;
  { changement de support demande par la fenetre, fait par la tache de la
    machine : 1 CD-ROM insere (MedPath), 2 CD-ROM ejecte, 3 disquette
    inseree, 4 disquette ejectee }
  MedReq : LongInt;
  MedPath : String;
  FdChanged, MedMsgUntil : LongInt;  { MedMsgUntil : fin du message du changement }
  CdEmu, CdBootLba, CdBootCnt, CdLoadSeg : LongInt;

{ somme de controle des en-tetes VHD : complement a un de la somme des
  octets (champ de la somme a zero) }
Function VhdSum(A, N, SumOff : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  S := 0;
  For K := 0 To N - 1 Do
    If (K < SumOff) Or (K >= SumOff + 4) Then S := S + RdB(A + K);
  VhdSum := Not S;
End;

{ geometrie CHS d'un disque VHD (annexe de la specification) }
Procedure VhdGeom(Secs : LongInt; Var C, H, S : LongInt);
Var Cth : LongInt;
Begin
  If Secs > 65535 * 16 * 255 Then Secs := 65535 * 16 * 255;
  If Secs >= 65535 * 16 * 63 Then
  Begin
    S := 255; H := 16; Cth := Secs Div S;
  End
  Else
  Begin
    S := 17; Cth := Secs Div S;
    H := (Cth + 1023) Div 1024;
    If H < 4 Then H := 4;
    If (Cth >= H * 1024) Or (H > 16) Then
    Begin
      S := 31; H := 16; Cth := Secs Div S;
    End;
    If Cth >= H * 1024 Then
    Begin
      S := 63; H := 16; Cth := Secs Div S;
    End;
  End;
  C := Cth Div H;
End;

{ creer un VHD dynamique de Mb Mo (blocs de 2 Mo) }
Function VhdCreate(Path : String; Mb : LongInt) : Boolean;
Var H, Secs, NB, TblSz, C, Hd, S, K, Pos : LongInt; F, D : Array[0..1023] Of Byte;
Begin
  VhdCreate := False;
  If (Mb < 1) Or (Mb > 32000) Then Exit;
  Dummy := DosDelete(Z(Path));
  H := FCreate(Path);
  If H < 0 Then Exit;
  Secs := Mb * 2048;
  NB := (Mb + 1) Div 2;
  TblSz := ((NB * 4) + 511) And Not 511;
  { pied de page }
  ZeroB(LongInt(@F), 512);
  PutZ(LongInt(@F), 'conectix');
  WrBE(LongInt(@F) + 8, 2); WrBE(LongInt(@F) + 12, $00010000);
  WrBE(LongInt(@F) + 16, 0); WrBE(LongInt(@F) + 20, 512);
  WrBE(LongInt(@F) + 24, 838000000 + Rnd(100000));
  WrB(LongInt(@F) + 28, Ord('o')); WrB(LongInt(@F) + 29, Ord('s')); WrB(LongInt(@F) + 30, Ord('2'));
  WrB(LongInt(@F) + 31, Ord('z'));
  WrBE(LongInt(@F) + 32, $00010000); WrBE(LongInt(@F) + 36, $5769326B);
  WrBE(LongInt(@F) + 40, Mb Shr 12); WrBE(LongInt(@F) + 44, Mb Shl 20);
  WrBE(LongInt(@F) + 48, Mb Shr 12); WrBE(LongInt(@F) + 52, Mb Shl 20);
  VhdGeom(Secs, C, Hd, S);
  WrB(LongInt(@F) + 56, C Shr 8); WrB(LongInt(@F) + 57, C And 255);
  WrB(LongInt(@F) + 58, Hd); WrB(LongInt(@F) + 59, S);
  WrBE(LongInt(@F) + 60, 3);
  For K := 0 To 15 Do WrB(LongInt(@F) + 68 + K, Rnd(256));
  WrB(LongInt(@F) + 74, (RdB(LongInt(@F) + 74) And $0F) Or $40);
  WrBE(LongInt(@F) + 64, VhdSum(LongInt(@F), 512, 64));
  { en-tete dynamique }
  ZeroB(LongInt(@D), 1024);
  PutZ(LongInt(@D), 'cxsparse');
  WrBE(LongInt(@D) + 8, -1); WrBE(LongInt(@D) + 12, -1);
  WrBE(LongInt(@D) + 16, 0); WrBE(LongInt(@D) + 20, 1536);
  WrBE(LongInt(@D) + 24, $00010000);
  WrBE(LongInt(@D) + 28, NB);
  WrBE(LongInt(@D) + 32, $200000);
  WrBE(LongInt(@D) + 36, VhdSum(LongInt(@D), 1024, 36));
  Pos := 0;
  If Not FWrite(H, 0, LongInt(@F), 512) Then Begin Dummy := DosClose(H); Exit; End;
  If FWrite(H, 512, LongInt(@D), 1024) Then ;
  { table des blocs : FFFFFFFFh (non alloues) }
  For K := 0 To 511 Do WrB(LongInt(@ZBuf) + K, $FF);
  Pos := 1536;
  While Pos < 1536 + TblSz Do
  Begin
    If FWrite(H, Pos, LongInt(@ZBuf), 512) Then ;
    Pos := Pos + 512;
  End;
  For K := 0 To 511 Do WrB(LongInt(@ZBuf) + K, 0);
  If FWrite(H, Pos, LongInt(@F), 512) Then ;
  Dummy := DosClose(H);
  VhdCreate := True;
End;

Procedure DkClose(D : LongInt);
Begin
  { l'unite emulee partage le fichier du CD-ROM }
  If (D <> DkEmu) And (DkH[D] >= 0) Then Dummy := DosClose(DkH[D]);
  DkH[D] := -1; DkKind[D] := 0; DkSect[D] := 0; DkData[D] := 0;
  If D = DkCd Then
  Begin
    DkH[DkEmu] := -1; DkKind[DkEmu] := 0; DkSect[DkEmu] := 0;
    CdOn := False; CdEmuOn := False;
  End;
End;

{ geometrie BIOS : celle de la table des partitions (fin de la premiere
  partition), sinon traduction LBA (16 a 255 tetes, 63 secteurs) }
Procedure DkGeom(D : LongInt);
Var A, K, H, S, T : LongInt;
Begin
  T := DkSect[D];
  If (D = 2) Or ((D = DkEmu) And (CdEmu < 4)) Then
  Begin
    DkHeads[D] := 2;
    Case T Of
      720 : Begin DkCyl[D] := 40; DkSpt[D] := 9; End;
      1440 : Begin DkCyl[D] := 80; DkSpt[D] := 9; End;
      2400 : Begin DkCyl[D] := 80; DkSpt[D] := 15; End;
      5760 : Begin DkCyl[D] := 80; DkSpt[D] := 36; End;
    Else
      DkCyl[D] := 80; DkSpt[D] := 18;
    End;
    Exit;
  End;
  H := 0; S := 0;
  A := LongInt(@SecBuf);
  If (RdB(A + 510) = $55) And (RdB(A + 511) = $AA) Then
    For K := 0 To 3 Do
      If (H = 0) And (RdB(A + 446 + K * 16 + 4) <> 0) And ((RdB(A + 446 + K * 16 + 6) And 63) <> 0) Then
      Begin
        H := RdB(A + 446 + K * 16 + 5) + 1;
        S := RdB(A + 446 + K * 16 + 6) And 63;
      End;
  { geometrie improbable (moins de 2 tetes ou de 9 secteurs, disque de
    plus de 8 Mo) : traduction LBA }
  If (H < 2) Or (S < 9) Then If T > 16384 Then H := 0;
  If (H < 1) Or (S < 1) Then
  Begin
    S := 63;
    If T <= 1024 * 16 * 63 Then H := 16
    Else If T <= 1024 * 32 * 63 Then H := 32
    Else If T <= 1024 * 64 * 63 Then H := 64
    Else If T <= 1024 * 128 * 63 Then H := 128
    Else H := 255;
  End;
  DkHeads[D] := H; DkSpt[D] := S;
  DkCyl[D] := MinI(1024, T Div (H * S));
  If DkCyl[D] < 1 Then DkCyl[D] := 1;
End;

Function DkReadSec(D, Lba, Buf : LongInt) : Boolean; Forward;

Function DkOpen(D : LongInt; Path : String) : Boolean;
Var H, Sz, A, K, N, P, Fo, E : LongInt; S, L : String; Ok : Boolean;
Begin
  DkOpen := False;
  DkClose(D);
  DkPath[D] := Path; DkErr := ''; DkFmt[D] := ''; DkData[D] := 0;
  DkReads[D] := 0; DkWrites[D] := 0;
  If Path = '' Then Exit;
  DkRO[D] := 0;
  H := FOpen(Path, True);
  If H < 0 Then
  Begin
    H := FOpen(Path, False);
    DkRO[D] := 1;
  End;
  If H < 0 Then
  Begin
    DkErr := Fr('Fichier introuvable : ') + Path;
    Exit;
  End;
  DkH[D] := H;
  Sz := FSize(H);
  A := LongInt(@DkFoot) + D * 512;
  ZeroB(LongInt(@SecBuf), 1024);
  If FRead(H, 0, LongInt(@SecBuf), 512) Then ;
  Ok := False;
  { VDI de VirtualBox }
  If RdL(LongInt(@SecBuf) + $40) = LongInt($BEDA107F) Then
  Begin
    DkFmt[D] := 'VDI';
    DkNBlk[D] := RdL(LongInt(@SecBuf) + $180);
    DkTbl[D] := RdL(LongInt(@SecBuf) + $154);
    DkData[D] := RdL(LongInt(@SecBuf) + $158);
    DkBlkSec[D] := RdL(LongInt(@SecBuf) + $178) Div 512;
    DkExtra[D] := RdL(LongInt(@SecBuf) + $17C);
    DkAlloc[D] := RdL(LongInt(@SecBuf) + $184);
    DkSect[D] := (RdL(LongInt(@SecBuf) + $170) Shr 9) Or (RdL(LongInt(@SecBuf) + $174) Shl 23);
    If RdL(LongInt(@SecBuf) + $4C) = 2 Then DkKind[D] := DK_VDIFIX Else DkKind[D] := DK_VDIDYN;
    If (DkNBlk[D] > MaxBat) Or (DkBlkSec[D] < 1) Then
    Begin
      DkErr := 'VDI : trop de blocs';
      DkClose(D);
      Exit;
    End;
    For K := 0 To DkNBlk[D] - 1 Do
    Begin
      If K Mod 128 = 0 Then If FRead(H, DkTbl[D] + K * 4, LongInt(@SecBuf), 512) Then ;
      Bat[D * MaxBat + K] := RdL(LongInt(@SecBuf) + (K Mod 128) * 4);
    End;
    Ok := True;
  End;
  { VHD : pied de page a la fin (ou sa copie au debut, image tronquee) }
  If Not Ok Then
  Begin
    Fo := -1;
    If Sz >= 512 Then
    Begin
      If FRead(H, ((Sz - 512) Div 512) * 512, A, 512) Then ;
      If (RdL(A) = $656E6F63) And (RdL(A + 4) = $78697463) Then Fo := ((Sz - 512) Div 512) * 512;
      If Fo < 0 Then
      Begin
        If FRead(H, Sz - 512, A, 512) Then ;
        If (RdL(A) = $656E6F63) And (RdL(A + 4) = $78697463) Then Fo := Sz - 512;
      End;
    End;
    If Fo < 0 Then
    Begin
      If FRead(H, 0, A, 512) Then ;
      If (RdL(A) = $656E6F63) And (RdL(A + 4) = $78697463) Then Fo := -2;
    End;
    If Fo <> -1 Then
    Begin
      DkFmt[D] := 'VHD';
      DkSect[D] := (RdBE(A + 52) Shr 9) Or (RdBE(A + 48) Shl 23);
      If RdBE(A + 60) = 2 Then
      Begin
        DkKind[D] := DK_VHDFIX;
        If Fo < 0 Then Fo := Sz;
        If DkSect[D] * 512 > Fo Then DkSect[D] := Fo Div 512;
      End
      Else
      Begin
        DkKind[D] := DK_VHDDYN;
        P := RdBE(A + 20);
        If FRead(H, P, LongInt(@SecBuf), 1024) Then ;
        If (RdL(LongInt(@SecBuf)) <> $70737863) Then
        Begin
          DkErr := 'VHD : en-tete dynamique invalide';
          DkClose(D);
          Exit;
        End;
        DkTbl[D] := RdBE(LongInt(@SecBuf) + 20);
        DkNBlk[D] := RdBE(LongInt(@SecBuf) + 28);
        DkBlkSec[D] := RdBE(LongInt(@SecBuf) + 32) Div 512;
        If (DkNBlk[D] > MaxBat) Or (DkBlkSec[D] < 8) Then
        Begin
          DkErr := 'VHD : trop de blocs';
          DkClose(D);
          Exit;
        End;
        DkBmp[D] := ((DkBlkSec[D] Div 8) + 511) And Not 511;
        E := DkTbl[D] + ((DkNBlk[D] * 4 + 511) And Not 511);
        For K := 0 To DkNBlk[D] - 1 Do
        Begin
          If K Mod 128 = 0 Then If FRead(H, DkTbl[D] + K * 4, LongInt(@SecBuf), 512) Then ;
          N := RdBE(LongInt(@SecBuf) + (K Mod 128) * 4);
          Bat[D * MaxBat + K] := N;
          If N <> -1 Then
            If N * 512 + DkBmp[D] + DkBlkSec[D] * 512 > E Then E := N * 512 + DkBmp[D] + DkBlkSec[D] * 512;
        End;
        DkEnd[D] := E;
      End;
      Ok := True;
    End;
  End;
  { VMDK : descripteur texte d'une image plate }
  If Not Ok And (ExtOf(Path) = 'VMDK') Then
  Begin
    If (RdB(LongInt(@SecBuf)) = Ord('K')) And (RdB(LongInt(@SecBuf) + 1) = Ord('D')) Then
    Begin
      DkErr := 'VMDK clairseme : non pris en charge (convertir en VDI ou VHD)';
      DkClose(D);
      Exit;
    End;
    L := '';
    For K := 0 To 511 Do
    Begin
      N := RdB(LongInt(@SecBuf) + K);
      If (N = 10) Or (N = 0) Then
      Begin
        If (Pos('FLAT', L) > 0) And (Pos('"', L) > 0) Then
        Begin
          S := Copy(L, Pos('"', L) + 1, 255);
          If Pos('"', S) > 0 Then S := Copy(S, 1, Pos('"', S) - 1);
          Dummy := DosClose(H);
          DkH[D] := -1;
          DkOpen := DkOpen(D, DirOf(Path) + S);
          DkFmt[D] := 'VMDK';
          Exit;
        End;
        L := '';
        If N = 0 Then Break;
      End
      Else L := L + Chr(N);
    End;
  End;
  If Not Ok Then
  Begin
    DkFmt[D] := 'brut';
    DkKind[D] := DK_RAW;
    DkSect[D] := Sz Div 512;
  End;
  If DkSect[D] <= 0 Then
  Begin
    DkErr := 'Disque vide';
    DkClose(D);
    Exit;
  End;
  ZeroB(LongInt(@SecBuf), 512);
  If DkReadSec(D, 0, LongInt(@SecBuf)) Then ;
  DkGeom(D);
  DkOpen := True;
End;

{ position du secteur Lba dans le fichier, -1 : bloc non alloue }
Function DkPos(D, Lba : LongInt) : LongInt;
Var B, E : LongInt;
Begin
  DkPos := -1;
  Case DkKind[D] Of
    DK_RAW, DK_VHDFIX : DkPos := DkData[D] + Lba * 512;
    DK_VHDDYN :
      Begin
        B := Lba Div DkBlkSec[D];
        If B >= DkNBlk[D] Then Exit;
        E := Bat[D * MaxBat + B];
        If E <> -1 Then DkPos := E * 512 + DkBmp[D] + (Lba Mod DkBlkSec[D]) * 512;
      End;
    DK_VDIFIX, DK_VDIDYN :
      Begin
        B := Lba Div DkBlkSec[D];
        If B >= DkNBlk[D] Then Exit;
        E := Bat[D * MaxBat + B];
        If (E <> -1) And (E <> -2) Then
          DkPos := DkData[D] + E * (DkBlkSec[D] * 512 + DkExtra[D]) + DkExtra[D] + (Lba Mod DkBlkSec[D]) * 512;
      End;
  End;
End;

Function DkReadSec(D, Lba, Buf : LongInt) : Boolean;
Var P : LongInt;
Begin
  DkReadSec := False;
  If (DkH[D] < 0) Or (Lba < 0) Or (Lba >= DkSect[D]) Then Exit;
  Inc(DkReads[D]);
  P := DkPos(D, Lba);
  If P < 0 Then ZeroB(Buf, 512)
  Else If Not FRead(DkH[D], P, Buf, 512) Then ZeroB(Buf, 512);
  DkReadSec := True;
End;

{ nouveau bloc d'un disque dynamique (rempli de zeros) }
Function DkGrow(D, B : LongInt) : Boolean;
Var P, N, K, A : LongInt; Bm : Array[0..511] Of Byte;
Begin
  DkGrow := False;
  ZeroB(LongInt(@ZBuf), SizeOf(ZBuf));
  If DkKind[D] = DK_VHDDYN Then
  Begin
    P := DkEnd[D];
    For K := 0 To 511 Do Bm[K] := $FF;
    For K := 0 To DkBmp[D] Div 512 - 1 Do
      If Not FWrite(DkH[D], P + K * 512, LongInt(@Bm), 512) Then Exit;
    N := DkBlkSec[D] * 512;
    K := 0;
    While K < N Do
    Begin
      If Not FWrite(DkH[D], P + DkBmp[D] + K, LongInt(@ZBuf), MinI(SizeOf(ZBuf), N - K)) Then Exit;
      K := K + SizeOf(ZBuf);
    End;
    DkEnd[D] := P + DkBmp[D] + N;
    { pied de page a la nouvelle fin, entree de la table }
    A := LongInt(@DkFoot) + D * 512;
    If FWrite(DkH[D], DkEnd[D], A, 512) Then ;
    Bat[D * MaxBat + B] := P Div 512;
    WrBE(LongInt(@Bm), P Div 512);
    If FWrite(DkH[D], DkTbl[D] + B * 4, LongInt(@Bm), 4) Then ;
    DkGrow := True;
  End
  Else If DkKind[D] = DK_VDIDYN Then
  Begin
    N := DkBlkSec[D] * 512 + DkExtra[D];
    P := DkData[D] + DkAlloc[D] * N;
    K := 0;
    While K < N Do
    Begin
      If Not FWrite(DkH[D], P + K, LongInt(@ZBuf), MinI(SizeOf(ZBuf), N - K)) Then Exit;
      K := K + SizeOf(ZBuf);
    End;
    Bat[D * MaxBat + B] := DkAlloc[D];
    WrL(LongInt(@Bm), DkAlloc[D]);
    If FWrite(DkH[D], DkTbl[D] + B * 4, LongInt(@Bm), 4) Then ;
    Inc(DkAlloc[D]);
    WrL(LongInt(@Bm), DkAlloc[D]);
    If FWrite(DkH[D], $184, LongInt(@Bm), 4) Then ;
    DkGrow := True;
  End;
End;

Function DkWriteSec(D, Lba, Buf : LongInt) : Boolean;
Var P : LongInt;
Begin
  DkWriteSec := False;
  If (DkH[D] < 0) Or (DkRO[D] <> 0) Or (Lba < 0) Or (Lba >= DkSect[D]) Then Exit;
  Inc(DkWrites[D]);
  P := DkPos(D, Lba);
  If P < 0 Then
  Begin
    If Not DkGrow(D, Lba Div DkBlkSec[D]) Then Exit;
    P := DkPos(D, Lba);
    If P < 0 Then Exit;
  End;
  DkWriteSec := FWrite(DkH[D], P, Buf, 512);
End;

Procedure DkCloseAll;
Var D : LongInt;
Begin
  For D := 0 To NDk - 1 Do DkClose(D);
End;

{ CD-ROM : image ISO 9660 (unite 3, secteurs de 2048 octets = 4 secteurs
  de 512 de l'unite) ; lit l'entree d'amorce El Torito (descripteur au
  secteur 17, catalogue, entree initiale) et prepare l'unite 4 pour
  l'emulation d'une disquette ou d'un disque dur }
Function CdOpen(Path : String) : Boolean;
Var A, Cat, M, K, N, S, E : LongInt;
Begin
  CdOpen := False;
  DkClose(DkCd);
  If Not DkOpen(DkCd, Path) Then Exit;
  DkRO[DkCd] := 1;
  DkKind[DkCd] := DK_RAW; DkData[DkCd] := 0; DkFmt[DkCd] := 'ISO';
  CdOpen := True;
  CdOn := False; CdEmuOn := False; CdEmu := 0;
  A := LongInt(@SecBuf);
  If Not DkReadSec(DkCd, 17 * 4, A) Then Exit;
  If (RdB(A) <> 0) Or (RdB(A + 1) <> Ord('C')) Or (RdB(A + 2) <> Ord('D')) Or (RdB(A + 7) <> Ord('E')) Or
     (RdB(A + 8) <> Ord('L')) Or (RdB(A + 10) <> Ord('T')) Then Exit;
  Cat := RdL(A + $47);
  If Not DkReadSec(DkCd, Cat * 4, A) Then Exit;
  If (RdB(A) <> 1) Or (RdB(A + $1E) <> $55) Or (RdB(A + $1F) <> $AA) Then Exit;
  If RdB(A + $20) <> $88 Then Exit;
  M := RdB(A + $21) And 15;
  If M > 4 Then Exit;
  CdEmu := M;
  CdLoadSeg := RdW(A + $22);
  If CdLoadSeg = 0 Then CdLoadSeg := $07C0;
  CdBootCnt := RdW(A + $26);
  If CdBootCnt < 1 Then CdBootCnt := 1;
  CdBootLba := RdL(A + $28);
  CdOn := True;
  If M = 0 Then Exit;
  { unite emulee : meme fichier, a partir de l'image d'amorce }
  DkH[DkEmu] := DkH[DkCd]; DkKind[DkEmu] := DK_RAW; DkRO[DkEmu] := 1;
  DkData[DkEmu] := CdBootLba * 2048; DkPath[DkEmu] := Path; DkFmt[DkEmu] := 'El Torito';
  DkReads[DkEmu] := 0; DkWrites[DkEmu] := 0;
  Case M Of
    1 : DkSect[DkEmu] := 2400;
    2 : DkSect[DkEmu] := 2880;
    3 : DkSect[DkEmu] := 5760;
  Else
    Begin
      { disque dur : jusqu'a la fin de la derniere partition (ou du CD) }
      DkSect[DkEmu] := DkSect[DkCd] - CdBootLba * 4;
      If DkReadSec(DkEmu, 0, A) Then
      Begin
        N := 0;
        For K := 0 To 3 Do
        Begin
          S := RdL(A + 446 + K * 16 + 8); E := RdL(A + 446 + K * 16 + 12);
          If (RdB(A + 446 + K * 16 + 4) <> 0) And (S + E > N) Then N := S + E;
        End;
        If (N > 0) And (N < DkSect[DkEmu]) Then DkSect[DkEmu] := N;
      End;
    End;
  End;
  If DkSect[DkEmu] > DkSect[DkCd] - CdBootLba * 4 Then DkSect[DkEmu] := DkSect[DkCd] - CdBootLba * 4;
  ZeroB(A, 512);
  If DkReadSec(DkEmu, 0, A) Then ;
  DkGeom(DkEmu);
End;

{ ==================================================================== }
{ Machine : memoire de l'invite, BIOS, peripheriques                    }
{ ==================================================================== }

Var
  Fr_ : Array[0..39] Of LongInt;        { cadre des registres (KrnVirt) }
  GMem, GSize, VmMethod, VmState, VmTid, VmWin, VmFrame : LongInt;
  VmIdle, VmReqReset, VmReqStop, VmReqCad, VmHalted, VmIdleWait, VmPowerOff : LongInt;
  VmMsg : String;
  Info : Array[0..127] Of LongInt;
  { 8259A : 0 maitre, 1 esclave }
  PicImr, PicIrr, PicIsr, PicBase, PicIcw, PicRead : Array[0..1] Of LongInt;
  IrqPend, IrqWant : LongInt;            { vecteur demande au noyau, -1 aucun }
  IrqWantN : LongInt;
  { 8254 : canaux 0 et 2 }
  PitReload, PitMode, PitAcc, PitFlip, PitLatch, PitLatched, PitT0 : Array[0..2] Of LongInt;
  PitTicksDone, PitStartMs, Port61 : LongInt;
  { 8042 et clavier }
  KbData, KbStat, KbCmd, KbCmdByte, KbNextIrq, KbOut, KbDevCmd, A20 : LongInt;
  KbQ : Array[0..255] Of LongInt;        { codes a remettre (application -> invite) }
  KbQH, KbQT : LongInt;
  KbResp : Array[0..15] Of LongInt;      { reponses du clavier (prioritaires) }
  KbRN : LongInt;
  { CMOS }
  CmIdx : LongInt;
  CmRam : Array[0..127] Of Byte;
  { VGA }
  CrIdx, SqIdx, GcIdx, AcIdx, AcFlip, DacW, DacR, DacC, Misc, Stat3DA : LongInt;
  CrReg : Array[0..31] Of Byte;
  SqReg : Array[0..7] Of Byte;
  GcReg : Array[0..15] Of Byte;
  AcReg : Array[0..31] Of Byte;
  Dac : Array[0..767] Of Byte;
  VgaFont : Array[0..8191] Of Byte;      { police du plan 2 (32 octets par caractere) }
  Font16 : Array[0..4095] Of Byte;
  Font8 : Array[0..2047] Of Byte;
  FontLoad : LongInt;
  DbgLine : String;
  DbgOut : String;
  PciAddr, Port92 : LongInt;
  KeyFlags, KeyE0 : LongInt;
  BootDrive : LongInt;

{ ---- memoire de l'invite (adresses physiques) ---- }

Function GB(A : LongInt) : LongInt;
Begin
  If (A >= 0) And (A < GSize) Then GB := RdB(GMem + A) Else GB := $FF;
End;

Function GW(A : LongInt) : LongInt;
Begin
  GW := GB(A) Or (GB(A + 1) Shl 8);
End;

Function GL(A : LongInt) : LongInt;
Begin
  GL := GW(A) Or (GW(A + 2) Shl 16);
End;

Procedure SB(A, V : LongInt);
Begin
  If (A >= 0) And (A < GSize) Then WrB(GMem + A, V);
End;

Procedure SW(A, V : LongInt);
Begin
  SB(A, V And 255); SB(A + 1, (V Shr 8) And 255);
End;

Procedure SL(A, V : LongInt);
Begin
  SW(A, V And $FFFF); SW(A + 2, (V Shr 16) And $FFFF);
End;

{ adresse lineaire de l'invite -> physique (pagination de l'invite :
  EMM386, Windows en mode etendu) ; -1 si la page est absente }
Function GPhys(Lin : LongInt) : LongInt;
Var Pde, Pte : LongInt;
Begin
  If (Fr_[fCR0] And LongInt($80000000)) = 0 Then
  Begin
    GPhys := Lin;
    Exit;
  End;
  GPhys := -1;
  Pde := GL((Fr_[fCR3] And Not 4095) + ((Lin Shr 22) And 1023) * 4);
  If (Pde And 1) = 0 Then Exit;
  If ((Pde And $80) <> 0) And ((Fr_[fCR4] And $10) <> 0) Then
  Begin
    GPhys := (Pde And LongInt($FFC00000)) Or (Lin And $3FFFFF);
    Exit;
  End;
  Pte := GL((Pde And Not 4095) + ((Lin Shr 12) And 1023) * 4);
  If (Pte And 1) = 0 Then Exit;
  GPhys := (Pte And Not 4095) Or (Lin And 4095);
End;

Function LB(Lin : LongInt) : LongInt;
Begin
  LB := GB(GPhys(Lin));
End;

Function LW(Lin : LongInt) : LongInt;
Begin
  LW := LB(Lin) Or (LB(Lin + 1) Shl 8);
End;

Function LL(Lin : LongInt) : LongInt;
Begin
  LL := LW(Lin) Or (LW(Lin + 2) Shl 16);
End;

Procedure LSB(Lin, V : LongInt);
Begin
  SB(GPhys(Lin), V);
End;

Procedure LSW(Lin, V : LongInt);
Begin
  LSB(Lin, V And 255); LSB(Lin + 1, (V Shr 8) And 255);
End;

{ copie entre la memoire de l'invite (lineaire) et un tampon de l'hote }
Procedure ToGuest(Lin, Buf, N : LongInt);
Var K, P, C : LongInt;
Begin
  K := 0;
  While K < N Do
  Begin
    P := GPhys(Lin + K);
    C := MinI(N - K, 4096 - ((Lin + K) And 4095));
    If (P >= 0) And (P + C <= GSize) Then CopyB(Buf + K, GMem + P, C);
    K := K + C;
  End;
End;

Procedure FromGuest(Lin, Buf, N : LongInt);
Var K, P, C : LongInt;
Begin
  K := 0;
  While K < N Do
  Begin
    P := GPhys(Lin + K);
    C := MinI(N - K, 4096 - ((Lin + K) And 4095));
    If (P >= 0) And (P + C <= GSize) Then CopyB(GMem + P, Buf + K, C) Else ZeroB(Buf + K, C);
    K := K + C;
  End;
End;

{ ---- registres de l'invite ---- }

Function GAX : LongInt; Begin GAX := Fr_[fAX] And $FFFF; End;
Function GAL : LongInt; Begin GAL := Fr_[fAX] And $FF; End;
Function GAH : LongInt; Begin GAH := (Fr_[fAX] Shr 8) And $FF; End;
Function GBX : LongInt; Begin GBX := Fr_[fBX] And $FFFF; End;
Function GBL : LongInt; Begin GBL := Fr_[fBX] And $FF; End;
Function GBH : LongInt; Begin GBH := (Fr_[fBX] Shr 8) And $FF; End;
Function GCX : LongInt; Begin GCX := Fr_[fCX] And $FFFF; End;
Function GCL : LongInt; Begin GCL := Fr_[fCX] And $FF; End;
Function GCH : LongInt; Begin GCH := (Fr_[fCX] Shr 8) And $FF; End;
Function GDX : LongInt; Begin GDX := Fr_[fDX] And $FFFF; End;
Function GDL : LongInt; Begin GDL := Fr_[fDX] And $FF; End;
Function GDH : LongInt; Begin GDH := (Fr_[fDX] Shr 8) And $FF; End;

Procedure Set16(R, V : LongInt);
Begin
  Fr_[R] := (Fr_[R] And LongInt($FFFF0000)) Or (V And $FFFF);
End;

Procedure SetLo(R, V : LongInt);
Begin
  Fr_[R] := (Fr_[R] And Not $FF) Or (V And $FF);
End;

Procedure SetHi(R, V : LongInt);
Begin
  Fr_[R] := (Fr_[R] And Not $FF00) Or ((V And $FF) Shl 8);
End;

Procedure SetCF(B : Boolean);
Begin
  If B Then Fr_[fFL] := Fr_[fFL] Or 1 Else Fr_[fFL] := Fr_[fFL] And Not 1;
End;

Procedure SetZF(B : Boolean);
Begin
  If B Then Fr_[fFL] := Fr_[fFL] Or $40 Else Fr_[fFL] := Fr_[fFL] And Not $40;
End;

{ adresse lineaire seg:ofs (mode reel ou V86 : base = seg * 16) }
Function SegLin(Base, Ofs : LongInt) : LongInt;
Begin
  SegLin := Base + (Ofs And $FFFF);
End;

{ ---- donnees du BIOS (0040:xxxx) ---- }
Function BdaB(O : LongInt) : LongInt; Begin BdaB := GB($400 + O); End;
Function BdaW(O : LongInt) : LongInt; Begin BdaW := GW($400 + O); End;
Procedure BdaSB(O, V : LongInt); Begin SB($400 + O, V); End;
Procedure BdaSW(O, V : LongInt); Begin SW($400 + O, V); End;

{ ==================================================================== }
{ 8259A                                                                 }
{ ==================================================================== }

Procedure Irq(N : LongInt);
Begin
  If N < 8 Then PicIrr[0] := PicIrr[0] Or (1 Shl N)
  Else
  Begin
    PicIrr[1] := PicIrr[1] Or (1 Shl (N - 8));
    PicIrr[0] := PicIrr[0] Or 4;
  End;
End;

{ interruption la plus prioritaire en attente (vecteur), -1 sinon }
Function PicNext(P : LongInt; Var Line : LongInt) : LongInt;
Var K, M : LongInt;
Begin
  PicNext := -1; Line := -1;
  M := PicIrr[P] And Not PicImr[P];
  For K := 0 To 7 Do
  Begin
    If (PicIsr[P] And (1 Shl K)) <> 0 Then Exit;
    If (M And (1 Shl K)) <> 0 Then
    Begin
      Line := K;
      PicNext := PicBase[P] + K;
      Exit;
    End;
  End;
End;

Function PicVector(Var IrqN : LongInt) : LongInt;
Var V, L, L2 : LongInt;
Begin
  PicVector := -1; IrqN := -1;
  V := PicNext(0, L);
  If V < 0 Then Exit;
  If L = 2 Then
  Begin
    V := PicNext(1, L2);
    If V < 0 Then
    Begin
      PicIrr[0] := PicIrr[0] And Not 4;
      Exit;
    End;
    IrqN := 8 + L2;
  End
  Else IrqN := L;
  PicVector := V;
End;

{ l'invite a pris l'interruption IrqN : IRR -> ISR }
Procedure PicAck(IrqN : LongInt);
Begin
  If IrqN < 0 Then Exit;
  If IrqN >= 8 Then
  Begin
    PicIrr[1] := PicIrr[1] And Not (1 Shl (IrqN - 8));
    PicIsr[1] := PicIsr[1] Or (1 Shl (IrqN - 8));
    If PicIrr[1] = 0 Then PicIrr[0] := PicIrr[0] And Not 4;
    PicIsr[0] := PicIsr[0] Or 4;
  End
  Else
  Begin
    PicIrr[0] := PicIrr[0] And Not (1 Shl IrqN);
    PicIsr[0] := PicIsr[0] Or (1 Shl IrqN);
  End;
End;

Procedure PicOut(P, A, V : LongInt);
Var K : LongInt;
Begin
  If A = 0 Then
  Begin
    If (V And $10) <> 0 Then
    Begin
      PicIcw[P] := 2; PicImr[P] := 0; PicIsr[P] := 0; PicIrr[P] := 0; PicRead[P] := 0;
    End
    Else If (V And $18) = 8 Then
    Begin
      If (V And 3) = 2 Then PicRead[P] := 0;
      If (V And 3) = 3 Then PicRead[P] := 1;
    End
    Else If (V And $E0) = $20 Then
    Begin
      For K := 0 To 7 Do
        If (PicIsr[P] And (1 Shl K)) <> 0 Then
        Begin
          PicIsr[P] := PicIsr[P] And Not (1 Shl K);
          Exit;
        End;
    End
    Else If (V And $E0) = $60 Then PicIsr[P] := PicIsr[P] And Not (1 Shl (V And 7));
  End
  Else
  Begin
    Case PicIcw[P] Of
      2 : Begin PicBase[P] := V And $F8; PicIcw[P] := 3; End;
      3 : PicIcw[P] := 4;
      4 : PicIcw[P] := 0;
    Else
      PicImr[P] := V;
    End;
  End;
End;

Function PicIn(P, A : LongInt) : LongInt;
Begin
  If A = 1 Then PicIn := PicImr[P]
  Else If PicRead[P] <> 0 Then PicIn := PicIsr[P]
  Else PicIn := PicIrr[P];
End;

{ ==================================================================== }
{ 8254 (horloge de 1 193 182 Hz)                                        }
{ ==================================================================== }

Function PitClocks : LongInt;
Begin
  PitClocks := (NowMs - PitStartMs) * 1193;
End;

Function PitCount(C : LongInt) : LongInt;
Var R, E : LongInt;
Begin
  R := PitReload[C];
  If R <= 0 Then R := 65536;
  E := (PitClocks - PitT0[C]) Mod R;
  If E < 0 Then E := 0;
  PitCount := (R - E) And $FFFF;
End;

Procedure PitOut(A, V : LongInt);
Var C : LongInt;
Begin
  If A = 3 Then
  Begin
    C := (V Shr 6) And 3;
    If C = 3 Then Exit;
    If ((V Shr 4) And 3) = 0 Then
    Begin
      PitLatch[C] := PitCount(C);
      PitLatched[C] := 2;
      Exit;
    End;
    PitAcc[C] := (V Shr 4) And 3;
    PitMode[C] := (V Shr 1) And 7;
    PitFlip[C] := 0;
    Exit;
  End;
  C := A;
  Case PitAcc[C] Of
    1 : PitReload[C] := V;
    2 : PitReload[C] := V Shl 8;
  Else
    If PitFlip[C] = 0 Then
    Begin
      PitReload[C] := V;
      PitFlip[C] := 1;
      Exit;
    End;
    PitReload[C] := (PitReload[C] And $FF) Or (V Shl 8);
    PitFlip[C] := 0;
  End;
  If PitReload[C] = 0 Then PitReload[C] := 65536;
  PitT0[C] := PitClocks;
  If C = 0 Then
  Begin
    PitStartMs := NowMs;
    PitT0[0] := 0;
    PitTicksDone := 0;
  End;
End;

Function PitIn(A : LongInt) : LongInt;
Var V, C : LongInt;
Begin
  C := A;
  If PitLatched[C] > 0 Then
  Begin
    If PitLatched[C] = 2 Then V := PitLatch[C] And 255 Else V := (PitLatch[C] Shr 8) And 255;
    Dec(PitLatched[C]);
    PitIn := V;
    Exit;
  End;
  V := PitCount(C);
  Case PitAcc[C] Of
    1 : PitIn := V And 255;
    2 : PitIn := (V Shr 8) And 255;
  Else
    If PitFlip[C] = 0 Then
    Begin
      PitFlip[C] := 1;
      PitIn := V And 255;
    End
    Else
    Begin
      PitFlip[C] := 0;
      PitIn := (V Shr 8) And 255;
    End;
  End;
End;

{ tops du canal 0 dus depuis le dernier passage }
Function PitDue : LongInt;
Var R, N : LongInt;
Begin
  R := PitReload[0];
  If R <= 0 Then R := 65536;
  N := (PitClocks Div R) - PitTicksDone;
  If N > 20 Then
  Begin
    PitTicksDone := PitTicksDone + N - 20;
    N := 20;
  End;
  PitDue := N;
End;

{ ==================================================================== }
{ 8042 (clavier)                                                        }
{ ==================================================================== }

{ ligne A20 : le noyau remappe la zone HMA (100000h-10FFFFh) }
Procedure SetA20(V : LongInt);
Begin
  V := V And 1;
  If V = A20 Then Exit;
  A20 := V;
  Dummy := KrnVirt(6, V, 0);
End;

Procedure KbPushResp(V : LongInt);
Begin
  If KbRN < 16 Then
  Begin
    KbResp[KbRN] := V;
    Inc(KbRN);
  End;
End;

{ code de balayage pose par l'interface (autre tache) }
Procedure KbKey(V : LongInt);
Var N : LongInt;
Begin
  N := (KbQT + 1) And 255;
  If N = KbQH Then Exit;
  KbQ[KbQT] := V;
  KbQT := N;
End;

{ remplir le tampon de sortie du 8042 s'il est vide }
Procedure KbFill;
Var K : LongInt;
Begin
  If (KbStat And 1) <> 0 Then Exit;
  If KbRN > 0 Then
  Begin
    KbData := KbResp[0];
    For K := 0 To KbRN - 2 Do KbResp[K] := KbResp[K + 1];
    Dec(KbRN);
    KbStat := KbStat Or 1;
    If (KbCmdByte And 1) <> 0 Then Irq(1);
    Exit;
  End;
  If (KbQH <> KbQT) And ((KbCmdByte And $10) = 0) Then
  Begin
    KbData := KbQ[KbQH];
    KbQH := (KbQH + 1) And 255;
    KbStat := KbStat Or 1;
    If (KbCmdByte And 1) <> 0 Then Irq(1);
  End;
End;

Function KbIn(A : LongInt) : LongInt;
Begin
  If A = $60 Then
  Begin
    KbIn := KbData;
    KbStat := KbStat And Not 1;
  End
  Else KbIn := KbStat Or $14;
End;

Procedure KbWrite(A, V : LongInt);
Begin
  If A = $64 Then
  Begin
    KbCmd := 0;
    Case V Of
      $20 : KbPushResp(KbCmdByte);
      $60, $D1, $D2, $D4 : KbCmd := V;
      $AA : KbPushResp($55);
      $AB : KbPushResp(0);
      $A9 : KbPushResp($FF);
      $AD : KbCmdByte := KbCmdByte Or $10;
      $AE : KbCmdByte := KbCmdByte And Not $10;
      $D0 : KbPushResp(1 Or (A20 Shl 1));
      $DD : SetA20(0);
      $DF : SetA20(1);
      $FE : VmReqReset := 1;
      $C0 : KbPushResp($BF);
    End;
    Exit;
  End;
  { port 60h : donnee d'une commande du 8042, ou commande du clavier }
  Case KbCmd Of
    $60 : Begin KbCmdByte := V; KbCmd := 0; Exit; End;
    $D1 : Begin SetA20(V Shr 1); KbCmd := 0; If (V And 1) = 0 Then VmReqReset := 1; Exit; End;
    $D2 : Begin KbPushResp(V); KbCmd := 0; Exit; End;
    $D4 : Begin KbCmd := 0; Exit; End;
  End;
  If KbDevCmd <> 0 Then
  Begin
    KbDevCmd := 0;
    KbPushResp($FA);
    Exit;
  End;
  Case V Of
    $ED, $F3, $F0 : Begin KbDevCmd := V; KbPushResp($FA); End;
    $EE : KbPushResp($EE);
    $F2 : Begin KbPushResp($FA); KbPushResp($AB); KbPushResp($41); End;
    $FF : Begin KbPushResp($FA); KbPushResp($AA); End;
  Else
    KbPushResp($FA);
  End;
End;

{ ==================================================================== }
{ CMOS                                                                  }
{ ==================================================================== }

Function CmosIn : LongInt;
Var Dt : Array[0..15] Of Byte; I : LongInt;
Begin
  I := CmIdx And $7F;
  If I <= 9 Then
  Begin
    Dummy := DosGetDateTime(LongInt(@Dt));
    Case I Of
      0 : CmosIn := Bcd(Dt[2]);
      2 : CmosIn := Bcd(Dt[1]);
      4 : CmosIn := Bcd(Dt[0]);
      6 : CmosIn := Dt[10] + 1;
      7 : CmosIn := Bcd(Dt[4]);
      8 : CmosIn := Bcd(Dt[5]);
      9 : CmosIn := Bcd((Dt[6] Or (Dt[7] Shl 8)) Mod 100);
    Else
      CmosIn := 0;
    End;
    Exit;
  End;
  If I = $0A Then
  Begin
    { bit 7 : mise a jour en cours, alterne }
    CmRam[$0A] := CmRam[$0A] Xor $80;
    CmosIn := CmRam[$0A] And $7F;
    Exit;
  End;
  If I = $32 Then
  Begin
    Dummy := DosGetDateTime(LongInt(@Dt));
    CmosIn := Bcd((Dt[6] Or (Dt[7] Shl 8)) Div 100);
    Exit;
  End;
  CmosIn := CmRam[I];
End;

Procedure CmosInit;
Var K, Ext : LongInt;
Begin
  For K := 0 To 127 Do CmRam[K] := 0;
  CmRam[$0A] := $26; CmRam[$0B] := $02; CmRam[$0D] := $80;
  If DkH[2] >= 0 Then CmRam[$10] := $40;
  CmRam[$12] := $F0; CmRam[$19] := 47;
  CmRam[$14] := $06;
  If DkH[2] >= 0 Then CmRam[$14] := $07;
  CmRam[$15] := $80; CmRam[$16] := $02;
  Ext := MinI(GSize Div 1024 - 1024, 65535);
  If Ext < 0 Then Ext := 0;
  CmRam[$17] := Ext And 255; CmRam[$18] := Ext Shr 8;
  CmRam[$30] := Ext And 255; CmRam[$31] := Ext Shr 8;
End;

{ ==================================================================== }
{ VGA                                                                   }
{ ==================================================================== }

{ palette par defaut du VGA (DAC, 6 bits) }
Procedure DacDefault;
Const E : Array[0..15] Of LongInt = ($000000, $00002A, $002A00, $002A2A, $2A0000, $2A002A, $2A1500, $2A2A2A,
                                     $151515, $15153F, $153F15, $153F3F, $3F1515, $3F153F, $3F3F15, $3F3F3F);
Var K, C, V : LongInt;
Begin
  For K := 0 To 767 Do Dac[K] := 0;
  { EGA (0..15), puis tons de gris (16..31) et teintes }
  For K := 0 To 15 Do
  Begin
    Dac[K * 3] := (E[K] Shr 16) And 63; Dac[K * 3 + 1] := (E[K] Shr 8) And 63; Dac[K * 3 + 2] := E[K] And 63;
  End;
  For K := 0 To 15 Do
  Begin
    V := K * 4 + (K Div 4);
    If V > 63 Then V := 63;
    Dac[(16 + K) * 3] := V; Dac[(16 + K) * 3 + 1] := V; Dac[(16 + K) * 3 + 2] := V;
  End;
  For K := 32 To 247 Do
  Begin
    C := (K - 32) Mod 24;
    V := (K - 32) Div 72;
    { cercle des teintes : 24 nuances, 3 intensites }
    Case C Div 4 Of
      0 : Begin Dac[K * 3] := 63; Dac[K * 3 + 1] := 0; Dac[K * 3 + 2] := 63 - (C Mod 4) * 16; End;
      1 : Begin Dac[K * 3] := 63; Dac[K * 3 + 1] := (C Mod 4) * 16; Dac[K * 3 + 2] := 0; End;
      2 : Begin Dac[K * 3] := 63 - (C Mod 4) * 16; Dac[K * 3 + 1] := 63; Dac[K * 3 + 2] := 0; End;
      3 : Begin Dac[K * 3] := 0; Dac[K * 3 + 1] := 63; Dac[K * 3 + 2] := (C Mod 4) * 16; End;
      4 : Begin Dac[K * 3] := 0; Dac[K * 3 + 1] := 63 - (C Mod 4) * 16; Dac[K * 3 + 2] := 63; End;
    Else
      Dac[K * 3] := (C Mod 4) * 16; Dac[K * 3 + 1] := 0; Dac[K * 3 + 2] := 63;
    End;
    If V > 0 Then
    Begin
      Dac[K * 3] := Dac[K * 3] Div (V + 1) + 8 * V; Dac[K * 3 + 1] := Dac[K * 3 + 1] Div (V + 1) + 8 * V;
      Dac[K * 3 + 2] := Dac[K * 3 + 2] Div (V + 1) + 8 * V;
    End;
  End;
End;

Procedure AcDefault;
Const P : Array[0..15] Of Byte = (0, 1, 2, 3, 4, 5, $14, 7, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F);
Var K : LongInt;
Begin
  For K := 0 To 15 Do AcReg[K] := P[K];
  AcReg[$10] := $0C; AcReg[$11] := 0; AcReg[$12] := $0F; AcReg[$13] := 8; AcReg[$14] := 0;
End;

{ police utilisateur : 8 x Hgt -> plan 2 }
Procedure FontPut(Src, First, Count, Hgt : LongInt; Guest : Boolean);
Var C, R, V : LongInt;
Begin
  For C := 0 To Count - 1 Do
    If (First + C >= 0) And (First + C < 256) Then
      For R := 0 To 31 Do
      Begin
        V := 0;
        If R < Hgt Then
        Begin
          If Guest Then V := LB(Src + C * Hgt + R) Else V := RdB(Src + C * Hgt + R);
        End;
        VgaFont[(First + C) * 32 + R] := V;
      End;
End;

Procedure FontRom(Hgt : LongInt);
Var C, R : LongInt;
Begin
  For C := 0 To 255 Do
    For R := 0 To 31 Do
    Begin
      If (Hgt = 16) And (R < 16) Then VgaFont[C * 32 + R] := Font16[C * 16 + R]
      Else If (Hgt = 8) And (R < 8) Then VgaFont[C * 32 + R] := Font8[C * 8 + R]
      Else If (Hgt = 14) And (R < 14) Then VgaFont[C * 32 + R] := GB($FD000 + C * 14 + R)
      Else VgaFont[C * 32 + R] := 0;
    End;
End;

{ ecritures directes de la police (plan 2 en A0000h) : reprise quand la
  carte revient au mode texte }
Procedure FontCheck;
Var C, R : LongInt;
Begin
  If ((SqReg[2] And 4) <> 0) And ((SqReg[2] And 3) = 0) And ((GcReg[6] And $0C) <= 4) Then FontLoad := 1
  Else If (FontLoad <> 0) And ((GcReg[6] And $0C) >= 8) Then
  Begin
    FontLoad := 0;
    For C := 0 To 255 Do
      For R := 0 To 31 Do VgaFont[C * 32 + R] := GB($A0000 + C * 32 + R);
  End;
End;

Function VgaIn(P : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := $FF;
  Case P Of
    $3C0 : V := AcIdx;
    $3C1 : V := AcReg[AcIdx And 31];
    $3C2 : V := $10;
    $3C4 : V := SqIdx;
    $3C5 : V := SqReg[SqIdx And 7];
    $3C6 : V := $FF;
    $3C7 : V := 0;
    $3C8 : V := DacW;
    $3C9 : Begin
             V := Dac[(DacR * 3 + DacC) Mod 768];
             Inc(DacC);
             If DacC = 3 Then Begin DacC := 0; DacR := (DacR + 1) And 255; End;
           End;
    $3CC : V := Misc;
    $3CE : V := GcIdx;
    $3CF : V := GcReg[GcIdx And 15];
    $3D4, $3B4 : V := CrIdx;
    $3D5, $3B5 : V := CrReg[CrIdx And 31];
    $3DA, $3BA : Begin
                   AcFlip := 0;
                   Inc(Stat3DA);
                   V := 0;
                   If (Stat3DA And 3) = 0 Then V := 9 Else If (Stat3DA And 1) = 1 Then V := 1;
                 End;
  End;
  VgaIn := V;
End;

Procedure VgaOut(P, V : LongInt);
Begin
  Case P Of
    $3C0 : Begin
             If AcFlip = 0 Then AcIdx := V And $3F Else AcReg[AcIdx And 31] := V;
             AcFlip := AcFlip Xor 1;
           End;
    $3C2 : Misc := V;
    $3C4 : SqIdx := V;
    $3C5 : Begin SqReg[SqIdx And 7] := V; FontCheck; End;
    $3C7 : Begin DacR := V; DacC := 0; End;
    $3C8 : Begin DacW := V; DacC := 0; End;
    $3C9 : Begin
             Dac[(DacW * 3 + DacC) Mod 768] := V And 63;
             Inc(DacC);
             If DacC = 3 Then Begin DacC := 0; DacW := (DacW + 1) And 255; End;
           End;
    $3CE : GcIdx := V;
    $3CF : Begin GcReg[GcIdx And 15] := V; FontCheck; End;
    $3D4, $3B4 : CrIdx := V;
    $3D5, $3B5 : CrReg[CrIdx And 31] := V;
  End;
End;

{ ==================================================================== }
{ Ports d'E/S de l'invite                                               }
{ ==================================================================== }

{ ==================================================================== }
{ Controleurs IDE (PIO) : canal primaire 1F0h-1F7h/3F6h (disque 0 maitre,
  disque 1 esclave, ATA), canal secondaire 170h-177h/376h (CD-ROM ATAPI
  maitre) ; IRQ 14 et 15 ; commandes ATA usuelles (IDENTIFY, READ/WRITE
  SECTORS et MULTIPLE, LBA 28 bits et CHS) et paquets ATAPI (READ(10),
  READ(12), READ CAPACITY, READ TOC, INQUIRY, REQUEST SENSE, MODE SENSE,
  TEST UNIT READY...) pour les invites en mode protege (OS2-Zero,
  Pasdows 95 installes, Linux...)                                       }
{ ==================================================================== }

Const
  IdeBufSz = 65536;

Var
  IdeFeat, IdeCnt, IdeLbaL, IdeLbaM, IdeLbaH, IdeDev, IdeSt, IdeErr, IdeCtl : Array[0..1] Of LongInt;
  IdePos, IdeLen, IdeLeft, IdeLba, IdeWr, IdeUnit, IdePkt, IdeBlk : Array[0..1] Of LongInt;
  IdeSense, IdeAsc : Array[0..1] Of LongInt;
  IdeMult : Array[0..3] Of LongInt;
  IdeBuf : Array[0..2 * IdeBufSz - 1] Of Byte;
  IdeCmds, IdeUA : LongInt;           { IdeUA : disque change (UNIT ATTENTION) }

Procedure IdeInit;
Var C : LongInt;
Begin
  For C := 0 To 1 Do
  Begin
    IdeFeat[C] := 0; IdeCnt[C] := 1; IdeLbaL[C] := 1; IdeLbaM[C] := 0; IdeLbaH[C] := 0; IdeDev[C] := $A0;
    IdeSt[C] := $50; IdeErr[C] := 1; IdeCtl[C] := 0; IdePos[C] := 0; IdeLen[C] := 0; IdeLeft[C] := 0;
    IdeWr[C] := 0; IdePkt[C] := 0; IdeSense[C] := 0; IdeAsc[C] := 0;
  End;
  For C := 0 To 3 Do IdeMult[C] := 16;
  { signature ATAPI du lecteur de CD-ROM (toujours present, avec ou sans
    disque, comme le lecteur DVD de VirtualBox) }
  IdeLbaM[1] := $14; IdeLbaH[1] := $EB;
  IdeUA := 0;
  IdeCmds := 0;
End;

{ unite de la peripherique selectionnee (-1 : absente) }
Function IdeSel(C : LongInt) : LongInt;
Var D, U : LongInt;
Begin
  D := (IdeDev[C] Shr 4) And 1;
  U := -1;
  If C = 0 Then
  Begin
    If D = 0 Then U := 0 Else U := 1;
  End
  Else If D = 0 Then U := DkCd;
  If (U >= 0) And (U <> DkCd) And (DkH[U] < 0) Then U := -1;
  IdeSel := U;
End;

Procedure IdeIrq(C : LongInt);
Begin
  If (IdeCtl[C] And 2) = 0 Then Irq(14 + C);
End;

Procedure IdePutW(C, Off, V : LongInt);
Begin
  IdeBuf[C * IdeBufSz + Off] := V And 255;
  IdeBuf[C * IdeBufSz + Off + 1] := (V Shr 8) And 255;
End;

{ chaine ATA (octets permutes dans chaque mot) }
Procedure IdePutS(C, Off, N : LongInt; S : String);
Var K, Ch : LongInt;
Begin
  For K := 0 To N - 1 Do
  Begin
    If K < Length(S) Then Ch := Ord(S[K + 1]) Else Ch := 32;
    IdeBuf[C * IdeBufSz + Off + (K Xor 1)] := Ch;
  End;
End;

Procedure IdeError(C, E : LongInt);
Begin
  IdeErr[C] := E; IdeSt[C] := $51; IdeLen[C] := 0; IdePos[C] := 0; IdeLeft[C] := 0;
  IdeIrq(C);
End;

Procedure IdeDone(C : LongInt);
Begin
  IdeErr[C] := 0; IdeSt[C] := $50; IdeLen[C] := 0; IdePos[C] := 0;
  IdeIrq(C);
End;

{ IDENTIFY DEVICE (ECh) / IDENTIFY PACKET DEVICE (A1h) }
Procedure IdeIdentify(C, U : LongInt);
Var K, T : LongInt;
Begin
  For K := 0 To 511 Do IdeBuf[C * IdeBufSz + K] := 0;
  If U = DkCd Then
  Begin
    IdePutW(C, 0, $85C0);                        { ATAPI, CD-ROM, amovible, paquets de 12 octets }
    IdePutS(C, 20, 20, 'VX-CD0001');
    IdePutS(C, 46, 8, '1.0');
    IdePutS(C, 54, 40, 'OS2-0 Virtualisation CD-ROM');
    IdePutW(C, 98, $0200);                       { LBA }
    IdePutW(C, 106, 6);
    IdePutW(C, 160, $7E); IdePutW(C, 162, 0);
  End
  Else
  Begin
    T := DkSect[U];
    IdePutW(C, 0, $0040);
    IdePutW(C, 2, DkCyl[U]); IdePutW(C, 6, DkHeads[U]);
    IdePutW(C, 8, 512 * DkSpt[U]); IdePutW(C, 10, 512); IdePutW(C, 12, DkSpt[U]);
    IdePutS(C, 20, 20, 'VX-HD000' + IStr(U));
    IdePutW(C, 42, 512);
    IdePutS(C, 46, 8, '1.0');
    IdePutS(C, 54, 40, 'OS2-0 Virtualisation Disque ' + IStr(U));
    IdePutW(C, 94, $8010);                       { READ/WRITE MULTIPLE : 16 }
    IdePutW(C, 98, $0200);                       { LBA }
    IdePutW(C, 106, 7);
    IdePutW(C, 108, DkCyl[U]); IdePutW(C, 110, DkHeads[U]); IdePutW(C, 112, DkSpt[U]);
    IdePutW(C, 114, T And $FFFF); IdePutW(C, 116, T Shr 16);
    IdePutW(C, 118, $0100 Or IdeMult[U]);
    IdePutW(C, 120, T And $FFFF); IdePutW(C, 122, T Shr 16);
    IdePutW(C, 160, $7E); IdePutW(C, 162, 0);
    IdePutW(C, 164, $4000); IdePutW(C, 166, $4000); IdePutW(C, 168, $4000);
  End;
  IdePos[C] := 0; IdeLen[C] := 512; IdeLeft[C] := 0; IdeWr[C] := 0;
  IdeErr[C] := 0; IdeSt[C] := $58;
  IdeIrq(C);
End;

{ adresse de la commande (LBA 28 bits ou CHS) }
Function IdeAddr(C, U : LongInt) : LongInt;
Var Cy, H, S : LongInt;
Begin
  If (IdeDev[C] And $40) <> 0 Then
    IdeAddr := IdeLbaL[C] Or (IdeLbaM[C] Shl 8) Or (IdeLbaH[C] Shl 16) Or ((IdeDev[C] And 15) Shl 24)
  Else
  Begin
    Cy := IdeLbaM[C] Or (IdeLbaH[C] Shl 8); H := IdeDev[C] And 15; S := IdeLbaL[C];
    IdeAddr := (Cy * DkHeads[U] + H) * DkSpt[U] + S - 1;
  End;
End;

{ remplit le tampon avec le bloc suivant d'une lecture de disque }
Procedure IdeReadBlk(C : LongInt);
Var U, N, K : LongInt;
Begin
  U := IdeUnit[C];
  N := MinI(IdeLeft[C], IdeBlk[C]);
  For K := 0 To N - 1 Do
    If Not DkReadSec(U, IdeLba[C] + K, LongInt(@IdeBuf) + C * IdeBufSz + K * 512) Then
    Begin
      IdeError(C, $40);
      Exit;
    End;
  IdeLba[C] := IdeLba[C] + N;
  IdeLeft[C] := IdeLeft[C] - N;
  IdePos[C] := 0; IdeLen[C] := N * 512;
  IdeErr[C] := 0; IdeSt[C] := $58;
  IdeIrq(C);
End;

{ ecrit le bloc recu ; demande le suivant ou termine }
Procedure IdeWriteBlk(C : LongInt);
Var U, N, K : LongInt;
Begin
  U := IdeUnit[C];
  N := IdeLen[C] Div 512;
  For K := 0 To N - 1 Do
    If Not DkWriteSec(U, IdeLba[C] + K, LongInt(@IdeBuf) + C * IdeBufSz + K * 512) Then
    Begin
      IdeError(C, $40);
      Exit;
    End;
  IdeLba[C] := IdeLba[C] + N;
  IdeLeft[C] := IdeLeft[C] - N;
  If IdeLeft[C] <= 0 Then
  Begin
    IdeDone(C);
    Exit;
  End;
  IdePos[C] := 0; IdeLen[C] := MinI(IdeLeft[C], IdeBlk[C]) * 512;
  IdeSt[C] := $58;
  IdeIrq(C);
End;

{ ---- ATAPI ---- }

Procedure AtapiSense(C, Key, Asc : LongInt);
Begin
  IdeSense[C] := Key; IdeAsc[C] := Asc;
  IdeErr[C] := Key Shl 4;
  IdeCnt[C] := 3;
  IdeSt[C] := $51; IdeLen[C] := 0; IdeLeft[C] := 0;
  IdeIrq(C);
End;

{ donnees a rendre a l'hote : N octets deja dans le tampon (ou lecture de
  Left secteurs de 2048 octets a partir de Lba) }
Procedure AtapiData(C, N : LongInt);
Var Lim : LongInt;
Begin
  Lim := IdeLbaM[C] Or (IdeLbaH[C] Shl 8);
  If (Lim = 0) Or (Lim > $FFFE) Then Lim := $FFFE;
  If N > Lim Then N := Lim And Not 1;
  If N <= 0 Then
  Begin
    IdeCnt[C] := 3; IdeErr[C] := 0; IdeSt[C] := $50; IdeLen[C] := 0;
    IdeIrq(C);
    Exit;
  End;
  IdeLen[C] := N; IdePos[C] := 0;
  IdeLbaM[C] := N And 255; IdeLbaH[C] := (N Shr 8) And 255;
  IdeCnt[C] := 2; IdeErr[C] := 0; IdeSt[C] := $58;
  IdeIrq(C);
End;

{ bloc suivant d'un READ : jusqu'a 16 secteurs de 2048 octets, dans la
  limite d'octets de l'hote }
Procedure AtapiReadBlk(C : LongInt);
Var Lim, N, K : LongInt;
Begin
  Lim := IdeLbaM[C] Or (IdeLbaH[C] Shl 8);
  If (Lim = 0) Or (Lim > $FFFE) Then Lim := $FFFE;
  N := MinI(IdeLeft[C], MaxI(1, Lim Div 2048));
  N := MinI(N, 16);
  For K := 0 To N * 4 - 1 Do
    If Not DkReadSec(DkCd, IdeLba[C] * 4 + K, LongInt(@IdeBuf) + C * IdeBufSz + K * 512) Then
    Begin
      AtapiSense(C, 5, $21);
      Exit;
    End;
  IdeLba[C] := IdeLba[C] + N;
  IdeLeft[C] := IdeLeft[C] - N;
  IdeLen[C] := N * 2048; IdePos[C] := 0;
  IdeLbaM[C] := (N * 2048) And 255; IdeLbaH[C] := ((N * 2048) Shr 8) And 255;
  IdeCnt[C] := 2; IdeErr[C] := 0; IdeSt[C] := $58;
  IdeIrq(C);
End;

Function IdeBE(C, Off : LongInt) : LongInt;
Var B : LongInt;
Begin
  B := C * IdeBufSz + Off;
  IdeBE := (IdeBuf[B] Shl 24) Or (IdeBuf[B + 1] Shl 16) Or (IdeBuf[B + 2] Shl 8) Or IdeBuf[B + 3];
End;

Procedure IdeSetBE(C, Off, V : LongInt);
Var B : LongInt;
Begin
  B := C * IdeBufSz + Off;
  IdeBuf[B] := (V Shr 24) And 255; IdeBuf[B + 1] := (V Shr 16) And 255;
  IdeBuf[B + 2] := (V Shr 8) And 255; IdeBuf[B + 3] := V And 255;
End;

{ paquet de 12 octets recu : commande SCSI }
Procedure AtapiCmd(C : LongInt);
Var Op, B, K, N, Last, Al : LongInt;
Begin
  B := C * IdeBufSz;
  Op := IdeBuf[B];
  Inc(IdeCmds);
  IdePkt[C] := 0;
  Last := DkSect[DkCd] Div 4 - 1;
  { disque change : UNIT ATTENTION une fois (sauf INQUIRY, REQUEST SENSE) }
  If (IdeUA <> 0) And (Op <> $03) And (Op <> $12) Then
  Begin
    IdeUA := 0;
    AtapiSense(C, 6, $28);
    Exit;
  End;
  { pas de disque : NOT READY, MEDIUM NOT PRESENT }
  If (DkH[DkCd] < 0) And (Op In [$00, $25, $28, $A8, $43, $51, $BE]) Then
  Begin
    AtapiSense(C, 2, $3A);
    Exit;
  End;
  Case Op Of
    $00, $1B, $1E, $35, $2B, $BB, $A6 : Begin
                         IdeSense[C] := 0; IdeAsc[C] := 0;
                         AtapiData(C, 0);
                       End;
    $03 : Begin
            Al := IdeBuf[B + 4];
            For K := 0 To 17 Do IdeBuf[B + K] := 0;
            IdeBuf[B] := $70; IdeBuf[B + 2] := IdeSense[C]; IdeBuf[B + 7] := 10; IdeBuf[B + 12] := IdeAsc[C];
            IdeSense[C] := 0; IdeAsc[C] := 0;
            AtapiData(C, MinI(18, Al));
          End;
    $12 : Begin
            Al := IdeBuf[B + 4];
            For K := 0 To 35 Do IdeBuf[B + K] := 32;
            IdeBuf[B] := 5; IdeBuf[B + 1] := $80; IdeBuf[B + 2] := 0; IdeBuf[B + 3] := $21;
            IdeBuf[B + 4] := 31; IdeBuf[B + 5] := 0; IdeBuf[B + 6] := 0; IdeBuf[B + 7] := 0;
            For K := 1 To 8 Do IdeBuf[B + 7 + K] := Ord('OS2-0   '[K]);
            For K := 1 To 16 Do IdeBuf[B + 15 + K] := Ord('VIRTUAL CD-ROM  '[K]);
            For K := 1 To 4 Do IdeBuf[B + 31 + K] := Ord('1.0 '[K]);
            AtapiData(C, MinI(36, Al));
          End;
    $25 : Begin
            IdeSetBE(C, 0, Last); IdeSetBE(C, 4, 2048);
            AtapiData(C, 8);
          End;
    $28, $A8 : Begin
                 IdeLba[C] := IdeBE(C, 2);
                 If Op = $28 Then N := (IdeBuf[B + 7] Shl 8) Or IdeBuf[B + 8] Else N := IdeBE(C, 6);
                 If (IdeLba[C] < 0) Or (IdeLba[C] + N - 1 > Last) Then
                 Begin
                   AtapiSense(C, 5, $21);
                   Exit;
                 End;
                 If N = 0 Then Begin AtapiData(C, 0); Exit; End;
                 IdeLeft[C] := N;
                 AtapiReadBlk(C);
               End;
    $43 : Begin
            { READ TOC (format 0, une piste de donnees) }
            Al := (IdeBuf[B + 7] Shl 8) Or IdeBuf[B + 8];
            For K := 0 To 19 Do IdeBuf[B + K] := 0;
            IdeBuf[B + 1] := 18; IdeBuf[B + 2] := 1; IdeBuf[B + 3] := 1;
            IdeBuf[B + 5] := $14; IdeBuf[B + 6] := 1;
            IdeBuf[B + 13] := $14; IdeBuf[B + 14] := $AA;
            IdeSetBE(C, 16, Last + 1);
            AtapiData(C, MinI(20, Al));
          End;
    $1A, $5A : Begin
                 If Op = $1A Then Al := IdeBuf[B + 4] Else Al := (IdeBuf[B + 7] Shl 8) Or IdeBuf[B + 8];
                 For K := 0 To 7 Do IdeBuf[B + K] := 0;
                 If Op = $1A Then IdeBuf[B] := 3 Else IdeBuf[B + 1] := 6;
                 AtapiData(C, MinI(8, Al));
               End;
    $46 : Begin
            Al := (IdeBuf[B + 7] Shl 8) Or IdeBuf[B + 8];
            For K := 0 To 7 Do IdeBuf[B + K] := 0;
            IdeBuf[B + 3] := 4; IdeBuf[B + 7] := 8;     { profil courant : CD-ROM }
            AtapiData(C, MinI(8, Al));
          End;
    $4A : Begin
            Al := (IdeBuf[B + 7] Shl 8) Or IdeBuf[B + 8];
            For K := 0 To 7 Do IdeBuf[B + K] := 0;
            IdeBuf[B + 1] := 6; IdeBuf[B + 2] := 4; IdeBuf[B + 3] := $10;
            AtapiData(C, MinI(8, Al));
          End;
    $51 : Begin
            Al := (IdeBuf[B + 7] Shl 8) Or IdeBuf[B + 8];
            For K := 0 To 33 Do IdeBuf[B + K] := 0;
            IdeBuf[B + 1] := 32; IdeBuf[B + 2] := $0E; IdeBuf[B + 3] := 1; IdeBuf[B + 4] := 1;
            IdeBuf[B + 5] := 1; IdeBuf[B + 6] := 1;
            AtapiData(C, MinI(34, Al));
          End;
    $BD : Begin
            For K := 0 To 7 Do IdeBuf[B + K] := 0;
            AtapiData(C, 8);
          End;
  Else
    AtapiSense(C, 5, $20);
  End;
End;

{ commande ATA ecrite au port 1F7h/177h }
Procedure IdeCommand(C, Cmd : LongInt);
Var U : LongInt;
Begin
  U := IdeSel(C);
  Inc(IdeCmds);
  If U < 0 Then
  Begin
    { peripherique absente : pas de reponse }
    IdeSt[C] := 0;
    Exit;
  End;
  If U = DkCd Then
  Begin
    Case Cmd Of
      $A1 : IdeIdentify(C, U);
      $A0 : Begin
              IdePkt[C] := 1; IdePos[C] := 0; IdeLen[C] := 12; IdeWr[C] := 1;
              IdeCnt[C] := 1; IdeSt[C] := $58; IdeErr[C] := 0;
            End;
      $08 : Begin
              IdeLbaL[C] := 1; IdeCnt[C] := 1; IdeLbaM[C] := $14; IdeLbaH[C] := $EB;
              IdeErr[C] := 1; IdeSt[C] := 0;
            End;
      $EF, $E0..$E3, $E5, $E6, $E7, $91 : IdeDone(C);
    Else
      { ECh et autres : abandon, signature ATAPI }
      IdeLbaM[C] := $14; IdeLbaH[C] := $EB; IdeCnt[C] := 1; IdeLbaL[C] := 1;
      IdeError(C, 4);
    End;
    Exit;
  End;
  Case Cmd Of
    $EC : IdeIdentify(C, U);
    $20, $21, $C4 :
      Begin
        IdeUnit[C] := U; IdeLba[C] := IdeAddr(C, U); IdeWr[C] := 0;
        IdeLeft[C] := IdeCnt[C]; If IdeLeft[C] = 0 Then IdeLeft[C] := 256;
        If Cmd = $C4 Then IdeBlk[C] := IdeMult[U] Else IdeBlk[C] := 1;
        If IdeLba[C] + IdeLeft[C] > DkSect[U] Then IdeError(C, $10) Else IdeReadBlk(C);
      End;
    $30, $31, $C5 :
      Begin
        IdeUnit[C] := U; IdeLba[C] := IdeAddr(C, U); IdeWr[C] := 1;
        IdeLeft[C] := IdeCnt[C]; If IdeLeft[C] = 0 Then IdeLeft[C] := 256;
        If Cmd = $C5 Then IdeBlk[C] := IdeMult[U] Else IdeBlk[C] := 1;
        If (IdeLba[C] + IdeLeft[C] > DkSect[U]) Or (DkRO[U] <> 0) Then IdeError(C, $10)
        Else
        Begin
          IdePos[C] := 0; IdeLen[C] := MinI(IdeLeft[C], IdeBlk[C]) * 512;
          IdeErr[C] := 0; IdeSt[C] := $58;
        End;
      End;
    $C6 : Begin
            If (IdeCnt[C] >= 1) And (IdeCnt[C] <= 128) Then IdeMult[U] := IdeCnt[C];
            IdeDone(C);
          End;
    $40, $41, $10..$1F, $70..$7F, $91, $EF, $E7, $EA, $E0..$E3, $E6 : IdeDone(C);
    $E5 : Begin IdeCnt[C] := $FF; IdeDone(C); End;
    $F8 : Begin
            { READ NATIVE MAX ADDRESS }
            IdeLbaL[C] := (DkSect[U] - 1) And 255; IdeLbaM[C] := ((DkSect[U] - 1) Shr 8) And 255;
            IdeLbaH[C] := ((DkSect[U] - 1) Shr 16) And 255;
            IdeDev[C] := (IdeDev[C] And $F0) Or (((DkSect[U] - 1) Shr 24) And 15);
            IdeDone(C);
          End;
    $A1 : Begin
            IdeLbaM[C] := 0; IdeLbaH[C] := 0;
            IdeError(C, 4);
          End;
  Else
    IdeError(C, 4);
  End;
End;

{ lecture du port de donnees (Size = 2 ou 4 octets) }
Function IdeDataIn(C, Size : LongInt) : LongInt;
Var V, K, B : LongInt;
Begin
  V := 0;
  If (IdeWr[C] = 0) And (IdeLen[C] > 0) Then
  Begin
    B := C * IdeBufSz + IdePos[C];
    For K := Size - 1 DownTo 0 Do V := (V Shl 8) Or IdeBuf[B + K];
    IdePos[C] := IdePos[C] + Size;
    If IdePos[C] >= IdeLen[C] Then
    Begin
      IdeLen[C] := 0; IdePos[C] := 0;
      If IdeSel(C) = DkCd Then
      Begin
        If IdeLeft[C] > 0 Then AtapiReadBlk(C)
        Else
        Begin
          IdeCnt[C] := 3; IdeErr[C] := 0; IdeSt[C] := $50;
          IdeIrq(C);
        End;
      End
      Else If IdeLeft[C] > 0 Then IdeReadBlk(C)
      Else IdeSt[C] := $50;
    End;
  End;
  IdeDataIn := V;
End;

Procedure IdeDataOut(C, Size, V : LongInt);
Var K, B : LongInt;
Begin
  If (IdeWr[C] = 0) Or (IdeLen[C] <= 0) Then Exit;
  B := C * IdeBufSz + IdePos[C];
  For K := 0 To Size - 1 Do IdeBuf[B + K] := (V Shr (K * 8)) And 255;
  IdePos[C] := IdePos[C] + Size;
  If IdePos[C] >= IdeLen[C] Then
  Begin
    If IdePkt[C] <> 0 Then
    Begin
      IdeWr[C] := 0; IdeLen[C] := 0;
      AtapiCmd(C);
    End
    Else IdeWriteBlk(C);
  End;
End;

Function IdeIn(P, Size : LongInt) : LongInt;
Var C, R, U : LongInt;
Begin
  If (P >= $170) And (P <= $177) Or (P = $376) Then C := 1 Else C := 0;
  U := IdeSel(C);
  R := 0;
  Case P And 7 Of
    0 : If P And $200 = 0 Then
        Begin
          IdeIn := IdeDataIn(C, Size);
          Exit;
        End;
  End;
  If (P = $3F6) Or (P = $376) Then
  Begin
    If U < 0 Then R := 0 Else R := IdeSt[C];
  End
  Else
    Case P And 7 Of
      1 : R := IdeErr[C];
      2 : R := IdeCnt[C];
      3 : R := IdeLbaL[C];
      4 : R := IdeLbaM[C];
      5 : R := IdeLbaH[C];
      6 : R := IdeDev[C] Or $A0;
      7 : If U < 0 Then R := 0 Else R := IdeSt[C];
    End;
  IdeIn := R;
End;

Procedure IdeOut(P, Size, V : LongInt);
Var C : LongInt;
Begin
  If (P >= $170) And (P <= $177) Or (P = $376) Then C := 1 Else C := 0;
  If (P = $3F6) Or (P = $376) Then
  Begin
    { registre de controle : bit 2 = remise a zero, bit 1 = nIEN }
    If ((V And 4) <> 0) And ((IdeCtl[C] And 4) = 0) Then
    Begin
      IdeLen[C] := 0; IdeLeft[C] := 0; IdePkt[C] := 0;
      IdeErr[C] := 1; IdeCnt[C] := 1; IdeLbaL[C] := 1; IdeDev[C] := $A0;
      If C = 1 Then Begin IdeLbaM[C] := $14; IdeLbaH[C] := $EB; End
      Else Begin IdeLbaM[C] := 0; IdeLbaH[C] := 0; End;
      IdeSt[C] := $50;
    End;
    IdeCtl[C] := V And 255;
    Exit;
  End;
  Case P And 7 Of
    0 : IdeDataOut(C, Size, V);
    1 : IdeFeat[C] := V And 255;
    2 : IdeCnt[C] := V And 255;
    3 : IdeLbaL[C] := V And 255;
    4 : IdeLbaM[C] := V And 255;
    5 : IdeLbaH[C] := V And 255;
    6 : IdeDev[C] := V And 255;
    7 : IdeCommand(C, V And 255);
  End;
End;

Function IoIn(P, Size : LongInt) : LongInt;
Var V : LongInt;
Begin
  { IDE : le port de donnees rend 16 ou 32 bits }
  If ((P >= $1F0) And (P <= $1F7)) Or ((P >= $170) And (P <= $177)) Or (P = $3F6) Or (P = $376) Then
  Begin
    V := IdeIn(P, Size);
    If ((P And 7) <> 0) Or (P = $3F6) Or (P = $376) Then
    Begin
      If Size = 2 Then V := V Or $FF00 Else If Size = 4 Then V := V Or LongInt($FFFFFF00);
    End;
    IoIn := V;
    Exit;
  End;
  V := $FF;
  Case P Of
    $20, $21 : V := PicIn(0, P - $20);
    $A0, $A1 : V := PicIn(1, P - $A0);
    $40, $41, $42 : V := PitIn(P - $40);
    $60, $64 : V := KbIn(P);
    $61 : Begin
            Port61 := Port61 Xor $10;
            V := Port61 And $1F;
            If (PitCount(2) And $8000) <> 0 Then V := V Or $20;
          End;
    $70 : V := CmIdx;
    $71 : V := CmosIn;
    $92 : V := Port92 Or (A20 Shl 1);
    $3B0..$3DF : V := VgaIn(P);
    $CF8 : V := PciAddr;
    $CFC..$CFF : V := $FF;
  End;
  If Size = 2 Then V := V Or $FF00
  Else If Size = 4 Then
  Begin
    If P = $CFC Then V := -1 Else V := V Or LongInt($FFFFFF00);
  End;
  IoIn := V;
End;

Procedure IoOut(P, Size, V : LongInt);
Begin
  Case P Of
    $20, $21 : PicOut(0, P - $20, V And 255);
    $A0, $A1 : PicOut(1, P - $A0, V And 255);
    $40, $41, $42, $43 : PitOut(P - $40, V And 255);
    $60, $64 : KbWrite(P, V And 255);
    $61 : Port61 := (Port61 And $F0) Or (V And $0F);
    $70 : CmIdx := V And 255;
    $71 : CmRam[CmIdx And $7F] := V And 255;
    $92 : Begin
            Port92 := V And $FC;
            SetA20(V Shr 1);
            If (V And 1) <> 0 Then VmReqReset := 1;
          End;
    $E9 : Begin
            If (V And 255) = 10 Then
            Begin
              DbgOut := DbgOut + Chr(10);
            End
            Else If (V And 255) >= 32 Then DbgLine := DbgLine + Chr(V And 255);
            If Length(DbgLine) > 200 Then DbgLine := Copy(DbgLine, 101, 200);
          End;
    $3B0..$3DF : Begin
                   VgaOut(P, V And 255);
                   If Size >= 2 Then VgaOut(P + 1, (V Shr 8) And 255);
                 End;
    $CF8 : PciAddr := V;
    $1F0..$1F7, $170..$177, $3F6, $376 : IdeOut(P, Size, V);
  End;
End;
{ ==================================================================== }
{ VGA : modes graphiques planaires 16 couleurs (0Dh, 0Eh, 10h, 12h)     }
{ ==================================================================== }

{ La memoire A0000h-AFFFFh n'est pas de la RAM dans ces modes : quatre
  plans de 64 Ko (PlMem, plan p a p * 65536), quatre verrous (PlLatch)
  charges a chaque lecture, et le chemin d'ecriture du controleur
  graphique (modes d'ecriture 0 a 3, rotation, fonction logique,
  set/reset, masque de bits GcReg[8], masque de plans SqReg[2]).
  L'invite n'y accede jamais directement : chaque acces provoque une
  sortie (page absente des tables imbriquees, ou defaut de page en mode
  V86) et MmioEmu emule l'instruction fautive. }

Type
  PlFbArr = Array[0..SW_ * SH_ - 1] Of Byte;
  PlFbPtr = ^PlFbArr;

Var
  PlMem : Array[0..262143] Of Byte;
  PlLatch : Array[0..3] Of Byte;
  PlPal : Array[0..15] Of LongInt;      { index du DAC des 16 couleurs }
  PlLine : Array[0..2047] Of Byte;      { une ligne de points }
  PlFb : LongInt;                       { adresse de Fb (p7) : PlFb := LongInt(@Fb) }
  PlGen : LongInt;                      { compteur d'ecritures (signature) }
  MmioDef32 : Boolean;                  { segment de code de 32 bits }
  MmioCnt : LongInt;                    { instructions emulees }
  { decodage de l'instruction courante }
  MmioIp, MmioSeg, MmioRep, MmioMod, MmioReg, MmioRmN, MmioLin : LongInt;
  MmioOp32, MmioAd32, MmioIsReg : Boolean;

{ ---- registres ---- }

{ mode planaire : chaine-4 et pair/impair inactifs, mode graphique,
  memoire en A0000h }
Function PlActive : Boolean;
Begin
  PlActive := ((SqReg[4] And 8) = 0) And ((GcReg[5] And $10) = 0) And ((GcReg[6] And 1) <> 0) And
              ((GcReg[6] And 8) = 0);
End;

Function PlModeOk(M : LongInt) : Boolean;
Begin
  M := M And $7F;
  PlModeOk := (M = $0D) Or (M = $0E) Or (M = $10) Or (M = $12);
End;

{ octets par ligne et lignes du mode du BIOS }
Function PlBpl : LongInt;
Begin
  If (BdaB($49) And $7F) = $0D Then PlBpl := 40 Else PlBpl := 80;
End;

Function PlRows : LongInt;
Var M : LongInt;
Begin
  M := BdaB($49) And $7F;
  If M = $10 Then PlRows := 350 Else If M = $12 Then PlRows := 480 Else PlRows := 200;
End;

{ hauteur des caracteres du BIOS }
Function PlChH : LongInt;
Var M : LongInt;
Begin
  M := BdaB($49) And $7F;
  If M = $10 Then PlChH := 14 Else If M = $12 Then PlChH := 16 Else PlChH := 8;
End;

{ ---- acces de l'unite centrale ---- }

Function PlRead(Off : LongInt) : LongInt;
Var P, R, C : LongInt;
Begin
  Off := Off And $FFFF;
  PlLatch[0] := PlMem[Off]; PlLatch[1] := PlMem[Off + 65536];
  PlLatch[2] := PlMem[Off + 131072]; PlLatch[3] := PlMem[Off + 196608];
  If (GcReg[5] And 8) = 0 Then R := PlLatch[GcReg[4] And 3]
  Else
  Begin
    { mode de lecture 1 : bit a 1 si la couleur du point est celle de
      GcReg[2] (plans retenus par GcReg[7]) }
    R := 0;
    For P := 0 To 3 Do
      If (GcReg[7] And (1 Shl P)) <> 0 Then
      Begin
        If (GcReg[2] And (1 Shl P)) <> 0 Then C := $FF Else C := 0;
        R := R Or (PlLatch[P] Xor C);
      End;
    R := (Not R) And $FF;
  End;
  PlRead := R;
End;

Procedure PlWrite(Off, V : LongInt);
Var P, Md, Fn, Msk, Mm, D, L, Vr, K : LongInt;
Begin
  Off := Off And $FFFF;
  V := V And $FF;
  Md := GcReg[5] And 3; Fn := (GcReg[3] Shr 3) And 3;
  Msk := GcReg[8]; Mm := SqReg[2] And 15;
  Vr := V;
  If (Md = 0) Or (Md = 3) Then
  Begin
    K := GcReg[3] And 7;
    If K <> 0 Then Vr := ((V Shr K) Or (V Shl (8 - K))) And $FF;
  End;
  If Md = 3 Then Msk := Msk And Vr;
  For P := 0 To 3 Do
    If (Mm And (1 Shl P)) <> 0 Then
    Begin
      L := PlLatch[P];
      If Md = 1 Then D := L
      Else
      Begin
        If Md = 0 Then
        Begin
          If (GcReg[1] And (1 Shl P)) <> 0 Then D := ((GcReg[0] Shr P) And 1) * $FF Else D := Vr;
        End
        Else If Md = 2 Then D := ((V Shr P) And 1) * $FF
        Else D := ((GcReg[0] Shr P) And 1) * $FF;
        If Fn = 1 Then D := D And L
        Else If Fn = 2 Then D := D Or L
        Else If Fn = 3 Then D := D Xor L;
        D := (D And Msk) Or (L And (Not Msk) And $FF);
      End;
      PlMem[P * 65536 + Off] := D And $FF;
    End;
  Inc(PlGen);
End;

{ ---- mode video (tables de la VGA d'IBM) ---- }

Function PlHx(S : String; I : LongInt) : LongInt;
Begin
  PlHx := (Pos(S[I * 2 + 1], '0123456789ABCDEF') - 1) * 16 + Pos(S[I * 2 + 2], '0123456789ABCDEF') - 1;
End;

{ M : 0Dh, 0Eh, 10h, 12h (ou 13h : registres seuls) ; bit 7 : ne pas
  effacer. A appeler a la fin de SetMode (apres DacDefault). }
Procedure PlSetMode(M : LongInt);
Var Clr : Boolean; Mi, Sq, Cr, Ac, Gc : String; K, R, G, B : LongInt;
Begin
  Clr := (M And $80) = 0;
  M := M And $7F;
  Sq := '03010F0006';
  Gc := '000000000000050FFF';
  Ac := '000102030405140738393A3B3C3D3E3F01000F0000';
  Case M Of
    $0D : Begin
            Mi := '63'; Sq := '03090F0006';
            Cr := '2D2728902B80BF1F00C0' + '000000000000' + '9C8E8F140096B9E3FF';
            Ac := '0001020304050607101112131415161701000F0000';
          End;
    $0E : Begin
            Mi := '63';
            Cr := '5F4F50825480BF1F00C0' + '000000000000' + '9C8E8F280096B9E3FF';
            Ac := '0001020304050607101112131415161701000F0000';
          End;
    $10 : Begin
            Mi := 'A3';
            Cr := '5F4F50825480BF1F0040' + '000000000000' + '83855D280F63BAE3FF';
          End;
    $12 : Begin
            Mi := 'E3';
            Cr := '5F4F508254800B3E0040' + '000000000000' + 'EA8CDF2800E704E3FF';
          End;
    $13 : Begin
            Mi := '63'; Sq := '03010F000E';
            Cr := '5F4F50825480BF1F0041' + '000000000000' + '9C8E8F284096B9A3FF';
            Ac := '000102030405060708090A0B0C0D0E0F41000F0000';
            Gc := '000000000040050FFF';
          End;
  Else
    Exit;
  End;
  Misc := PlHx(Mi, 0);
  For K := 0 To 4 Do SqReg[K] := PlHx(Sq, K);
  For K := 0 To 24 Do CrReg[K] := PlHx(Cr, K);
  For K := 0 To 20 Do AcReg[K] := PlHx(Ac, K);
  For K := 0 To 8 Do GcReg[K] := PlHx(Gc, K);
  AcFlip := 0;
  If M = $13 Then Exit;
  { DAC 0-63 : palette de l'EGA (rgbRGB) en 350 et 480 lignes, de la CGA
    (bit 4 : intensite) en 200 lignes }
  For K := 0 To 63 Do
  Begin
    If (M = $0D) Or (M = $0E) Then
    Begin
      R := ((K Shr 2) And 1) * $2A + ((K Shr 4) And 1) * $15;
      G := ((K Shr 1) And 1) * $2A + ((K Shr 4) And 1) * $15;
      B := (K And 1) * $2A + ((K Shr 4) And 1) * $15;
      If (K And $17) = 6 Then G := $15;
    End
    Else
    Begin
      R := ((K Shr 2) And 1) * $2A + ((K Shr 5) And 1) * $15;
      G := ((K Shr 1) And 1) * $2A + ((K Shr 4) And 1) * $15;
      B := (K And 1) * $2A + ((K Shr 3) And 1) * $15;
    End;
    Dac[K * 3] := R; Dac[K * 3 + 1] := G; Dac[K * 3 + 2] := B;
  End;
  { donnees du BIOS : hauteur des caracteres, taille de la page }
  If M = $10 Then BdaSB($85, 14) Else If M = $12 Then BdaSB($85, 16) Else BdaSB($85, 8);
  Case M Of
    $0D : BdaSW($4C, $2000);
    $0E : BdaSW($4C, $4000);
    $10 : BdaSW($4C, $8000);
  Else
    BdaSW($4C, $9600);
  End;
  If Clr Then FillChar(PlMem, SizeOf(PlMem), 0);
  For K := 0 To 3 Do PlLatch[K] := 0;
  Inc(PlGen);
End;

{ ---- services du BIOS (INT 10h) ---- }

{ AH=0Ch : point (bit 7 de C : ou exclusif), page 0 }
Procedure PlPutPix(X, Y, C : LongInt);
Var Off, Msk, P, K, Bpl : LongInt;
Begin
  Bpl := PlBpl;
  If (X < 0) Or (Y < 0) Or (X >= Bpl * 8) Or (Y >= PlRows) Then Exit;
  Off := Y * Bpl + (X Shr 3);
  Msk := $80 Shr (X And 7);
  For P := 0 To 3 Do
  Begin
    K := P * 65536 + Off;
    If (C And $80) <> 0 Then
    Begin
      If (C And (1 Shl P)) <> 0 Then PlMem[K] := PlMem[K] Xor Msk;
    End
    Else If (C And (1 Shl P)) <> 0 Then PlMem[K] := PlMem[K] Or Msk
    Else PlMem[K] := PlMem[K] And ($FF Xor Msk);
  End;
  Inc(PlGen);
End;

{ AH=0Dh }
Function PlGetPix(X, Y : LongInt) : LongInt;
Var Off, P, R, Sh, Bpl : LongInt;
Begin
  R := 0;
  Bpl := PlBpl;
  If (X >= 0) And (Y >= 0) And (X < Bpl * 8) And (Y < PlRows) Then
  Begin
    Off := Y * Bpl + (X Shr 3);
    Sh := 7 - (X And 7);
    For P := 0 To 3 Do R := R Or (((PlMem[P * 65536 + Off] Shr Sh) And 1) Shl P);
  End;
  PlGetPix := R;
End;

{ ligne R de la police du caractere Ch (8 x H) }
Function PlFont(Ch, R, H : LongInt) : LongInt;
Var V : LongInt;
Begin
  Ch := Ch And 255;
  If H = 8 Then V := Font8[Ch * 8 + R]
  Else If H = 14 Then V := GB($F0000 + RomF14 + Ch * 14 + R)
  Else V := Font16[Ch * 16 + R];
  PlFont := V;
End;

{ caractere du BIOS (AH=09h/0Ah/0Eh) : couleur Attr (bit 7 : ou exclusif),
  fond noir }
Procedure PlGfxChar(Col, Row, Ch, Attr : LongInt);
Var H, Bpl, Off, R, B, P, K : LongInt;
Begin
  H := PlChH; Bpl := PlBpl;
  If (Col < 0) Or (Col >= Bpl) Or (Row < 0) Or ((Row + 1) * H > PlRows) Then Exit;
  Off := Row * H * Bpl + Col;
  For R := 0 To H - 1 Do
  Begin
    B := PlFont(Ch, R, H);
    For P := 0 To 3 Do
    Begin
      K := P * 65536 + Off + R * Bpl;
      If (Attr And $80) <> 0 Then
      Begin
        If (Attr And (1 Shl P)) <> 0 Then PlMem[K] := PlMem[K] Xor B;
      End
      Else If (Attr And (1 Shl P)) <> 0 Then PlMem[K] := B
      Else PlMem[K] := 0;
    End;
  End;
  Inc(PlGen);
End;

{ AH=06h/07h : defilement d'une fenetre de caracteres ; lignes vides de
  la couleur Attr }
Procedure PlScroll(Up : Boolean; N, Attr, R1, C1, R2, C2 : LongInt);
Var H, Bpl, Rows, R, L, P, C, Src, Dst, F : LongInt;
Begin
  H := PlChH; Bpl := PlBpl; Rows := PlRows Div H;
  If R2 >= Rows Then R2 := Rows - 1;
  If C2 >= Bpl Then C2 := Bpl - 1;
  If (R1 > R2) Or (C1 > C2) Or (R1 < 0) Or (C1 < 0) Then Exit;
  If (N = 0) Or (N > R2 - R1 + 1) Then N := R2 - R1 + 1;
  For L := 0 To (R2 - R1 + 1) * H - 1 Do
  Begin
    If Up Then R := R1 * H + L Else R := R2 * H + H - 1 - L;
    If Up Then Src := R + N * H Else Src := R - N * H;
    For P := 0 To 3 Do
    Begin
      If (Attr And (1 Shl P)) <> 0 Then F := $FF Else F := 0;
      For C := C1 To C2 Do
      Begin
        Dst := P * 65536 + R * Bpl + C;
        If (Src >= R1 * H) And (Src < (R2 + 1) * H) Then PlMem[Dst] := PlMem[P * 65536 + Src * Bpl + C]
        Else PlMem[Dst] := F;
      End;
    End;
  End;
  Inc(PlGen);
End;

{ ---- image (Fb de p7, adresse dans PlFb) ---- }

{ index du DAC de la couleur V (0-15) par le controleur d'attributs }
Function PlDacIdx(V : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := AcReg[(V And AcReg[$12]) And 15] And $3F;
  If (AcReg[$10] And $80) <> 0 Then P := (P And $0F) Or ((AcReg[$14] And 3) Shl 4);
  P := P Or ((AcReg[$14] And $0C) Shl 4);
  PlDacIdx := P;
End;

Procedure PlRender;
Var Hd, Vd, Ms, Lw, St, Lc, Dots, Sc, Px, Y, Row, Base, Prev, A, X, I, J, K, Sh, V, Fo, M : LongInt;
    B0, B1, B2, B3 : LongInt; D2, H256 : Boolean; F : PlFbPtr;
Begin
  If PlFb = 0 Then Exit;
  F := Pointer(PlFb);
  For K := 0 To 15 Do PlPal[K] := PlDacIdx(K);
  { geometrie d'apres le CRTC }
  Hd := CrReg[1] + 1;
  Vd := CrReg[$12] + ((CrReg[7] And 2) Shl 7) + ((CrReg[7] And $40) Shl 3) + 1;
  Ms := (CrReg[9] And $1F) + 1;
  If (CrReg[9] And $80) <> 0 Then Ms := Ms * 2;
  If (CrReg[$14] And $40) <> 0 Then Lw := CrReg[$13] * 8
  Else If (CrReg[$17] And $40) = 0 Then Lw := CrReg[$13] * 4
  Else Lw := CrReg[$13] * 2;
  D2 := (SqReg[1] And 8) <> 0;
  If (Hd < 20) Or (Vd < 100) Or (Lw = 0) Then
  Begin
    { registres non programmes : valeurs du mode du BIOS }
    M := BdaB($49) And $7F;
    Hd := 80; Vd := 400; Ms := 2; Lw := 80; D2 := False;
    If M = $0D Then Begin Hd := 40; Lw := 40; D2 := True; End
    Else If M = $10 Then Begin Vd := 350; Ms := 1; End
    Else If M = $12 Then Begin Vd := 480; Ms := 1; End;
  End;
  St := (CrReg[$0C] Shl 8) Or CrReg[$0D];
  Lc := CrReg[$18] + ((CrReg[7] And $10) Shl 4) + ((CrReg[9] And $40) Shl 3);
  H256 := (AcReg[$10] And $40) <> 0;
  Dots := Hd * 8; Sc := 0;
  If D2 Then Begin Dots := Dots * 2; Sc := 1; End;
  If H256 Then Sc := Sc + 1;
  If Dots > SW_ Then Dots := SW_;
  Px := (Dots + (1 Shl Sc) - 1) Shr Sc;
  If Px > 2040 Then Px := 2040;
  Prev := -1;
  For Y := 0 To SH_ - 1 Do
  Begin
    Fo := (SH_ - 1 - Y) * SW_;
    If Y >= Vd Then
    Begin
      For X := 0 To SW_ - 1 Do F^[Fo + X] := 0;
    End
    Else
    Begin
      If Y > Lc Then
      Begin
        Base := 0; Row := (Y - Lc - 1) Div Ms;
      End
      Else
      Begin
        Base := St; Row := Y Div Ms;
      End;
      A := Base + Row * Lw;
      If A <> Prev Then
      Begin
        Prev := A;
        If H256 Then
          For X := 0 To Px - 1 Do PlLine[X] := PlMem[(X And 3) * 65536 + ((A + (X Shr 2)) And $FFFF)]
        Else
          For I := 0 To (Px + 7) Div 8 - 1 Do
          Begin
            K := (A + I) And $FFFF;
            B0 := PlMem[K]; B1 := PlMem[K + 65536]; B2 := PlMem[K + 131072]; B3 := PlMem[K + 196608];
            For J := 0 To 7 Do
            Begin
              Sh := 7 - J;
              V := ((B0 Shr Sh) And 1) Or (((B1 Shr Sh) And 1) Shl 1) Or (((B2 Shr Sh) And 1) Shl 2) Or
                   (((B3 Shr Sh) And 1) Shl 3);
              PlLine[I * 8 + J] := PlPal[V];
            End;
          End;
      End;
      If Sc = 0 Then
        For X := 0 To Dots - 1 Do F^[Fo + X] := PlLine[X]
      Else
        For X := 0 To Dots - 1 Do F^[Fo + X] := PlLine[X Shr Sc];
      For X := Dots To SW_ - 1 Do F^[Fo + X] := 0;
    End;
  End;
End;

{ signature de l'image (ne recopier que si elle change) }
Function PlSum : LongInt;
Var S, K : LongInt;
Begin
  S := (PlGen * 7 + BdaB($49)) And $7FFFFFFF;
  For K := 0 To 24 Do S := (S * 31 + CrReg[K]) And $7FFFFFFF;
  For K := 0 To 20 Do S := (S * 31 + AcReg[K]) And $7FFFFFFF;
  For K := 0 To 767 Do S := (S * 7 + Dac[K]) And $7FFFFFFF;
  S := (S * 31 + SqReg[1] + SqReg[4] * 256 + GcReg[5] * 65536) And $7FFFFFFF;
  PlSum := S;
End;

{ ==================================================================== }
{ Emulation d'une instruction qui touche A0000h-AFFFFh                  }
{ ==================================================================== }

{ octet de l'adresse lineaire Lin : plans du VGA ou memoire de l'invite }
Function MmioRdB(Lin : LongInt) : LongInt;
Var P, R : LongInt;
Begin
  P := GPhys(Lin);
  If (P >= $A0000) And (P < $B0000) And PlActive Then R := PlRead(P - $A0000) Else R := GB(P);
  MmioRdB := R;
End;

Procedure MmioWrB(Lin, V : LongInt);
Var P : LongInt;
Begin
  P := GPhys(Lin);
  If (P >= $A0000) And (P < $B0000) And PlActive Then PlWrite(P - $A0000, V) Else SB(P, V And $FF);
End;

Function MmioRd(Lin, Sz : LongInt) : LongInt;
Var K, V : LongInt;
Begin
  V := 0;
  For K := 0 To Sz - 1 Do V := V Or (MmioRdB(Lin + K) Shl (K * 8));
  MmioRd := V;
End;

Procedure MmioWr(Lin, Sz, V : LongInt);
Var K : LongInt;
Begin
  For K := 0 To Sz - 1 Do MmioWrB(Lin + K, (V Shr (K * 8)) And $FF);
End;

Function MmioFetch : LongInt;
Var R : LongInt;
Begin
  R := LB(Fr_[fCSB] + MmioIp);
  MmioIp := MmioIp + 1;
  If Not MmioDef32 Then MmioIp := MmioIp And $FFFF;
  MmioFetch := R;
End;

Function MmioFetchW : LongInt;
Var R : LongInt;
Begin
  R := MmioFetch;
  R := R Or (MmioFetch Shl 8);
  MmioFetchW := R;
End;

Function MmioFetchL : LongInt;
Var R : LongInt;
Begin
  R := MmioFetchW;
  R := R Or (MmioFetchW Shl 16);
  MmioFetchL := R;
End;

Function MmioSx8(V : LongInt) : LongInt;
Begin
  V := V And $FF;
  If V >= $80 Then V := V Or LongInt($FFFFFF00);
  MmioSx8 := V;
End;

Function MmioSx16(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V >= $8000 Then V := V Or LongInt($FFFF0000);
  MmioSx16 := V;
End;

{ valeur immediate de Sz octets }
Function MmioImm(Sz : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Sz = 1 Then R := MmioFetch Else If Sz = 2 Then R := MmioFetchW Else R := MmioFetchL;
  MmioImm := R;
End;

Function MmioMask(Sz : LongInt) : LongInt;
Begin
  If Sz = 1 Then MmioMask := $FF Else If Sz = 2 Then MmioMask := $FFFF Else MmioMask := -1;
End;

Function MmioSign(Sz : LongInt) : LongInt;
Begin
  If Sz = 1 Then MmioSign := $80 Else If Sz = 2 Then MmioSign := $8000 Else MmioSign := LongInt($80000000);
End;

{ registre n (codage x86 : AX CX DX BX SP BP SI DI) -> indice du cadre }
Function MmioRi(R : LongInt) : LongInt;
Var I : LongInt;
Begin
  Case R And 7 Of
    0 : I := fAX;
    1 : I := fCX;
    2 : I := fDX;
    3 : I := fBX;
    4 : I := fSP;
    5 : I := fBP;
    6 : I := fSI;
  Else
    I := fDI;
  End;
  MmioRi := I;
End;

Function MmioGetR(R, Sz : LongInt) : LongInt;
Var V : LongInt;
Begin
  If Sz = 1 Then
  Begin
    If R < 4 Then V := Fr_[MmioRi(R)] And $FF Else V := (Fr_[MmioRi(R - 4)] Shr 8) And $FF;
  End
  Else If Sz = 2 Then V := Fr_[MmioRi(R)] And $FFFF
  Else V := Fr_[MmioRi(R)];
  MmioGetR := V;
End;

Procedure MmioSetR(R, Sz, V : LongInt);
Begin
  If Sz = 1 Then
  Begin
    If R < 4 Then SetLo(MmioRi(R), V) Else SetHi(MmioRi(R - 4), V);
  End
  Else If Sz = 2 Then Set16(MmioRi(R), V)
  Else Fr_[MmioRi(R)] := V;
End;

{ octet modR/M (et SIB, deplacement) : MmioIsReg/MmioRmN ou MmioLin }
Procedure MmioModRm;
Var M, Rm, Ofs, Sib, Idx, Bs, DSeg : LongInt;
Begin
  M := MmioFetch;
  MmioMod := (M Shr 6) And 3; MmioReg := (M Shr 3) And 7; Rm := M And 7;
  MmioIsReg := MmioMod = 3; MmioRmN := Rm;
  MmioLin := 0;
  If MmioIsReg Then Exit;
  DSeg := fDSB; Ofs := 0;
  If Not MmioAd32 Then
  Begin
    Case Rm Of
      0 : Ofs := Fr_[fBX] + Fr_[fSI];
      1 : Ofs := Fr_[fBX] + Fr_[fDI];
      2 : Begin Ofs := Fr_[fBP] + Fr_[fSI]; DSeg := fSSB; End;
      3 : Begin Ofs := Fr_[fBP] + Fr_[fDI]; DSeg := fSSB; End;
      4 : Ofs := Fr_[fSI];
      5 : Ofs := Fr_[fDI];
      6 : If MmioMod = 0 Then Ofs := MmioFetchW Else Begin Ofs := Fr_[fBP]; DSeg := fSSB; End;
    Else
      Ofs := Fr_[fBX];
    End;
    If MmioMod = 1 Then Ofs := Ofs + MmioSx8(MmioFetch)
    Else If MmioMod = 2 Then Ofs := Ofs + MmioFetchW;
    Ofs := Ofs And $FFFF;
  End
  Else
  Begin
    If Rm = 4 Then
    Begin
      Sib := MmioFetch;
      Idx := (Sib Shr 3) And 7; Bs := Sib And 7;
      If (Bs = 5) And (MmioMod = 0) Then Ofs := MmioFetchL
      Else
      Begin
        Ofs := Fr_[MmioRi(Bs)];
        If (Bs = 4) Or (Bs = 5) Then DSeg := fSSB;
      End;
      If Idx <> 4 Then Ofs := Ofs + (Fr_[MmioRi(Idx)] Shl ((Sib Shr 6) And 3));
    End
    Else If (Rm = 5) And (MmioMod = 0) Then Ofs := MmioFetchL
    Else
    Begin
      Ofs := Fr_[MmioRi(Rm)];
      If Rm = 5 Then DSeg := fSSB;
    End;
    If MmioMod = 1 Then Ofs := Ofs + MmioSx8(MmioFetch)
    Else If MmioMod = 2 Then Ofs := Ofs + MmioFetchL;
  End;
  If MmioSeg >= 0 Then DSeg := MmioSeg;
  MmioLin := Fr_[DSeg] + Ofs;
End;

Function MmioRdOp(Sz : LongInt) : LongInt;
Var V : LongInt;
Begin
  If MmioIsReg Then V := MmioGetR(MmioRmN, Sz) Else V := MmioRd(MmioLin, Sz);
  MmioRdOp := V;
End;

Procedure MmioWrOp(Sz, V : LongInt);
Begin
  If MmioIsReg Then MmioSetR(MmioRmN, Sz, V) Else MmioWr(MmioLin, Sz, V);
End;

{ ---- drapeaux : CF 1, PF 4, AF 10h, ZF 40h, SF 80h, OF 800h ---- }

Function MmioSZP(R, Sz : LongInt) : LongInt;
Var F, K, N : LongInt;
Begin
  F := 0;
  R := R And MmioMask(Sz);
  If R = 0 Then F := F Or $40;
  If (R And MmioSign(Sz)) <> 0 Then F := F Or $80;
  N := 0;
  For K := 0 To 7 Do If (R And (1 Shl K)) <> 0 Then Inc(N);
  If (N And 1) = 0 Then F := F Or 4;
  MmioSZP := F;
End;

{ A + B + C sur Sz octets ; Cy : retenue sortante (0/1) }
Function MmioAddC(A, B, C, Sz : LongInt; Var Cy : LongInt) : LongInt;
Var Lo, Hi, R : LongInt;
Begin
  Lo := (A And $FFFF) + (B And $FFFF) + C;
  Hi := ((A Shr 16) And $FFFF) + ((B Shr 16) And $FFFF) + ((Lo Shr 16) And 3);
  R := ((Hi And $FFFF) Shl 16) Or (Lo And $FFFF);
  If Sz = 1 Then Cy := (R Shr 8) And 1
  Else If Sz = 2 Then Cy := (Lo Shr 16) And 1
  Else Cy := (Hi Shr 16) And 1;
  MmioAddC := R And MmioMask(Sz);
End;

{ operation Op (0 ADD 1 OR 2 ADC 3 SBB 4 AND 5 SUB 6 XOR 7 CMP), drapeaux
  dans Fr_[fFL] }
Function MmioAlu(Op, A, B, Sz : LongInt) : LongInt;
Var R, F, Ci, Cy, Msk, Sg : LongInt;
Begin
  Msk := MmioMask(Sz); Sg := MmioSign(Sz);
  A := A And Msk; B := B And Msk;
  F := 0; Ci := 0; Cy := 0;
  If Op = 1 Then R := A Or B
  Else If Op = 4 Then R := A And B
  Else If Op = 6 Then R := A Xor B
  Else
  Begin
    If (Op = 2) Or (Op = 3) Then Ci := Fr_[fFL] And 1;
    If (Op = 0) Or (Op = 2) Then
    Begin
      R := MmioAddC(A, B, Ci, Sz, Cy);
      If Cy <> 0 Then F := F Or 1;
      If ((A Xor R) And (B Xor R) And Sg) <> 0 Then F := F Or $800;
    End
    Else
    Begin
      R := MmioAddC(A, (Not B) And Msk, 1 - Ci, Sz, Cy);
      If Cy = 0 Then F := F Or 1;
      If ((A Xor B) And (A Xor R) And Sg) <> 0 Then F := F Or $800;
    End;
    If ((A Xor B Xor R) And $10) <> 0 Then F := F Or $10;
  End;
  R := R And Msk;
  F := F Or MmioSZP(R, Sz);
  Fr_[fFL] := (Fr_[fFL] And Not $8D5) Or F;
  MmioAlu := R;
End;

{ decalages et rotations (0 ROL 1 ROR 2 RCL 3 RCR 4 SHL 5 SHR 6 SAL 7 SAR) }
Function MmioShift(Op, A, N, Sz : LongInt) : LongInt;
Var Bits, Msk, Sg, Cf, T, K, F, A0 : LongInt;
Begin
  Msk := MmioMask(Sz); Sg := MmioSign(Sz); Bits := Sz * 8;
  A := A And Msk; A0 := A;
  N := N And $1F;
  If N = 0 Then
  Begin
    MmioShift := A;
    Exit;
  End;
  Cf := Fr_[fFL] And 1;
  For K := 1 To N Do
    Case Op Of
      0 : Begin Cf := (A Shr (Bits - 1)) And 1; A := ((A Shl 1) Or Cf) And Msk; End;
      1 : Begin Cf := A And 1; A := ((A Shr 1) Or (Cf Shl (Bits - 1))) And Msk; End;
      2 : Begin T := (A Shr (Bits - 1)) And 1; A := ((A Shl 1) Or Cf) And Msk; Cf := T; End;
      3 : Begin T := A And 1; A := ((A Shr 1) Or (Cf Shl (Bits - 1))) And Msk; Cf := T; End;
      5 : Begin Cf := A And 1; A := (A Shr 1) And Msk; End;
      7 : Begin Cf := A And 1; A := ((A Shr 1) Or (A And Sg)) And Msk; End;
    Else
      Begin Cf := (A Shr (Bits - 1)) And 1; A := (A Shl 1) And Msk; End;
    End;
  F := Fr_[fFL];
  F := (F And Not 1) Or Cf;
  F := F And Not $800;
  If (Op = 0) Or (Op = 2) Or (Op = 4) Or (Op = 6) Then
  Begin
    If (((A Shr (Bits - 1)) And 1) Xor Cf) <> 0 Then F := F Or $800;
  End
  Else If (Op = 1) Or (Op = 3) Then
  Begin
    If (((A Shr (Bits - 1)) Xor (A Shr (Bits - 2))) And 1) <> 0 Then F := F Or $800;
  End
  Else If Op = 5 Then
  Begin
    If (A0 And Sg) <> 0 Then F := F Or $800;
  End;
  If Op >= 4 Then F := (F And Not $D4) Or MmioSZP(A, Sz);
  Fr_[fFL] := F;
  MmioShift := A;
End;

{ ---- instructions de chaine ---- }

Function MmioAm(V : LongInt) : LongInt;
Begin
  If MmioAd32 Then MmioAm := V Else MmioAm := V And $FFFF;
End;

Procedure MmioStepR(R, D : LongInt);
Begin
  If MmioAd32 Then Fr_[R] := Fr_[R] + D Else Set16(R, Fr_[R] + D);
End;

{ Op : A4 MOVS, A6 CMPS, AA STOS, AC LODS, AE SCAS }
Procedure MmioStr(Op, Sz : LongInt);
Var N, Step, SrcB, K, A, B, S, D : LongInt;
Begin
  If MmioRep <> 0 Then N := MmioAm(Fr_[fCX]) Else N := 1;
  If (Fr_[fFL] And $400) <> 0 Then Step := -Sz Else Step := Sz;
  SrcB := fDSB;
  If MmioSeg >= 0 Then SrcB := MmioSeg;
  While N <> 0 Do
  Begin
    S := MmioAm(Fr_[fSI]); D := MmioAm(Fr_[fDI]);
    If Op = $A4 Then
    Begin
      { octet par octet : lecture (verrous) puis ecriture }
      For K := 0 To Sz - 1 Do
        MmioWrB(Fr_[fESB] + MmioAm(D + K), MmioRdB(Fr_[SrcB] + MmioAm(S + K)));
    End
    Else If Op = $AA Then
    Begin
      For K := 0 To Sz - 1 Do MmioWrB(Fr_[fESB] + MmioAm(D + K), (Fr_[fAX] Shr (K * 8)) And $FF);
    End
    Else If Op = $AC Then
    Begin
      A := 0;
      For K := 0 To Sz - 1 Do A := A Or (MmioRdB(Fr_[SrcB] + MmioAm(S + K)) Shl (K * 8));
      MmioSetR(0, Sz, A);
    End
    Else
    Begin
      B := 0;
      For K := 0 To Sz - 1 Do B := B Or (MmioRdB(Fr_[fESB] + MmioAm(D + K)) Shl (K * 8));
      If Op = $A6 Then
      Begin
        A := 0;
        For K := 0 To Sz - 1 Do A := A Or (MmioRdB(Fr_[SrcB] + MmioAm(S + K)) Shl (K * 8));
      End
      Else A := MmioGetR(0, Sz);
      A := MmioAlu(7, A, B, Sz);
    End;
    If (Op = $A4) Or (Op = $A6) Or (Op = $AC) Then MmioStepR(fSI, Step);
    If Op <> $AC Then MmioStepR(fDI, Step);
    If MmioRep = 0 Then N := 0
    Else
    Begin
      N := MmioAm(N - 1);
      If MmioAd32 Then Fr_[fCX] := N Else Set16(fCX, N);
      If (Op = $A6) Or (Op = $AE) Then
      Begin
        If (MmioRep = $F3) And ((Fr_[fFL] And $40) = 0) Then N := 0;
        If (MmioRep = $F2) And ((Fr_[fFL] And $40) <> 0) Then N := 0;
      End;
    End;
  End;
End;

{ ---- instruction a CS:IP ---- }

Function MmioEmu : Boolean;
Var Op, Sz, W, A, B, R, Cnt, Cf : LongInt; Done, Ok : Boolean;
Begin
  MmioEmu := False;
  MmioIp := Fr_[fIP];
  If Not MmioDef32 Then MmioIp := MmioIp And $FFFF;
  MmioSeg := -1; MmioRep := 0; MmioOp32 := MmioDef32; MmioAd32 := MmioDef32;
  MmioIsReg := False; MmioLin := 0;
  Cnt := 0; Op := 0;
  Repeat
    Op := MmioFetch;
    Inc(Cnt);
    Done := False;
    Case Op Of
      $26 : MmioSeg := fESB;
      $2E : MmioSeg := fCSB;
      $36 : MmioSeg := fSSB;
      $3E : MmioSeg := fDSB;
      $64 : MmioSeg := fFSB;
      $65 : MmioSeg := fGSB;
      $66 : MmioOp32 := Not MmioDef32;
      $67 : MmioAd32 := Not MmioDef32;
      $F2, $F3 : MmioRep := Op;
      $F0 : ;
    Else
      Done := True;
    End;
  Until Done Or (Cnt >= 15);
  If Not Done Then Exit;
  If MmioOp32 Then Sz := 4 Else Sz := 2;
  If (Op And 1) = 0 Then W := 1 Else W := Sz;
  Ok := True;
  If (Op < $40) And ((Op And 7) <= 3) Then
  Begin
    { ADD OR ADC SBB AND SUB XOR CMP, formes r/m }
    MmioModRm;
    If (Op And 2) = 0 Then
    Begin
      A := MmioRdOp(W); B := MmioGetR(MmioReg, W);
    End
    Else
    Begin
      A := MmioGetR(MmioReg, W); B := MmioRdOp(W);
    End;
    R := MmioAlu((Op Shr 3) And 7, A, B, W);
    If ((Op Shr 3) And 7) <> 7 Then
    Begin
      If (Op And 2) = 0 Then MmioWrOp(W, R) Else MmioSetR(MmioReg, W, R);
    End;
  End
  Else If (Op >= $80) And (Op <= $83) Then
  Begin
    If (Op = $80) Or (Op = $82) Then W := 1 Else W := Sz;
    MmioModRm;
    If Op = $83 Then B := MmioSx8(MmioFetch) And MmioMask(W) Else B := MmioImm(W);
    A := MmioRdOp(W);
    R := MmioAlu(MmioReg, A, B, W);
    If MmioReg <> 7 Then MmioWrOp(W, R);
  End
  Else If (Op = $84) Or (Op = $85) Then
  Begin
    MmioModRm;
    A := MmioRdOp(W);
    R := MmioAlu(4, A, MmioGetR(MmioReg, W), W);
  End
  Else If (Op = $86) Or (Op = $87) Then
  Begin
    MmioModRm;
    A := MmioRdOp(W);
    MmioWrOp(W, MmioGetR(MmioReg, W));
    MmioSetR(MmioReg, W, A);
  End
  Else If (Op = $88) Or (Op = $89) Then
  Begin
    MmioModRm;
    MmioWrOp(W, MmioGetR(MmioReg, W));
  End
  Else If (Op = $8A) Or (Op = $8B) Then
  Begin
    MmioModRm;
    MmioSetR(MmioReg, W, MmioRdOp(W));
  End
  Else If (Op = $C6) Or (Op = $C7) Then
  Begin
    MmioModRm;
    If MmioReg <> 0 Then Exit;
    MmioWrOp(W, MmioImm(W));
  End
  Else If (Op >= $A0) And (Op <= $A3) Then
  Begin
    If MmioAd32 Then A := MmioFetchL Else A := MmioFetchW;
    If MmioSeg >= 0 Then A := Fr_[MmioSeg] + A Else A := Fr_[fDSB] + A;
    If Op <= $A1 Then MmioSetR(0, W, MmioRd(A, W)) Else MmioWr(A, W, MmioGetR(0, W));
  End
  Else If (Op >= $A4) And (Op <= $A7) Then MmioStr(Op And $FE, W)
  Else If (Op >= $AA) And (Op <= $AF) Then MmioStr(Op And $FE, W)
  Else If (Op = $C0) Or (Op = $C1) Or ((Op >= $D0) And (Op <= $D3)) Then
  Begin
    MmioModRm;
    If (Op = $C0) Or (Op = $C1) Then B := MmioFetch
    Else If Op >= $D2 Then B := Fr_[fCX] And $FF
    Else B := 1;
    A := MmioRdOp(W);
    If (B And $1F) <> 0 Then MmioWrOp(W, MmioShift(MmioReg, A, B, W));
  End
  Else If (Op = $F6) Or (Op = $F7) Then
  Begin
    MmioModRm;
    If MmioReg >= 4 Then Exit;
    If MmioReg <= 1 Then
    Begin
      B := MmioImm(W);
      A := MmioRdOp(W);
      R := MmioAlu(4, A, B, W);
    End
    Else If MmioReg = 2 Then MmioWrOp(W, Not MmioRdOp(W))
    Else
    Begin
      A := MmioRdOp(W);
      MmioWrOp(W, MmioAlu(5, 0, A, W));
    End;
  End
  Else If (Op = $FE) Or (Op = $FF) Then
  Begin
    MmioModRm;
    If MmioReg >= 2 Then Exit;
    A := MmioRdOp(W);
    Cf := Fr_[fFL] And 1;
    If MmioReg = 0 Then R := MmioAlu(0, A, 1, W) Else R := MmioAlu(5, A, 1, W);
    Fr_[fFL] := (Fr_[fFL] And Not 1) Or Cf;
    MmioWrOp(W, R);
  End
  Else If Op = $0F Then
  Begin
    Op := MmioFetch;
    If (Op <> $B6) And (Op <> $B7) And (Op <> $BE) And (Op <> $BF) Then Exit;
    MmioModRm;
    If (Op And 1) = 0 Then
    Begin
      A := MmioRdOp(1);
      If Op = $BE Then A := MmioSx8(A);
    End
    Else
    Begin
      A := MmioRdOp(2);
      If Op = $BF Then A := MmioSx16(A);
    End;
    MmioSetR(MmioReg, Sz, A);
  End
  Else Ok := False;
  If Not Ok Then Exit;
  If MmioDef32 Then Fr_[fIP] := MmioIp Else Fr_[fIP] := MmioIp And $FFFF;
  Inc(MmioCnt);
  MmioEmu := True;
End;

{ ==================================================================== }
{ BIOS : POST et services                                               }
{ ==================================================================== }

Procedure RomHex(At : LongInt; H : String);
Var I, V : LongInt;
Begin
  I := 1;
  While I < Length(H) Do
  Begin
    V := (Pos(H[I], '0123456789ABCDEF') - 1) * 16 + Pos(H[I + 1], '0123456789ABCDEF') - 1;
    SB(At, V);
    Inc(At);
    I := I + 2;
  End;
End;

Procedure SetVec(N, Seg, Ofs : LongInt);
Begin
  SW(N * 4, Ofs); SW(N * 4 + 2, Seg);
End;

{ curseur materiel (CRTC 0Eh/0Fh) d'apres la page active }
Procedure CrtCursor;
Var P, X, Y : LongInt;
Begin
  P := BdaB($62);
  X := BdaB($50 + P * 2); Y := BdaB($51 + P * 2);
  P := (BdaW($4E) Div 2) + Y * BdaW($4A) + X;
  CrReg[$0E] := (P Shr 8) And 255; CrReg[$0F] := P And 255;
End;

Function TextMode : Boolean;
Var M : LongInt;
Begin
  M := BdaB($49);
  TextMode := (M <= 3) Or (M = 7);
End;

{ mode video (INT 10h AH=00h) }
Procedure SetMode(M : LongInt);
Var Clr : Boolean; K, Cols : LongInt;
Begin
  Clr := (M And $80) = 0;
  M := M And $7F;
  If M = 7 Then M := 3;
  If Not (M In [0, 1, 2, 3, 4, 5, 6, $0D, $0E, $10, $12, $13]) Then M := 3;
  BdaSB($49, M);
  If M <= 1 Then Cols := 40 Else If (M <= 3) Or (M = 6) Then Cols := 80 Else Cols := 40;
  If (M = $12) Or (M = $0E) Or (M = $10) Then Cols := 80;
  BdaSW($4A, Cols);
  BdaSW($4E, 0); BdaSB($62, 0);
  For K := 0 To 15 Do BdaSB($50 + K, 0);
  BdaSB($84, 24);
  If M = $12 Then BdaSB($84, 29);
  If M <= 3 Then
  Begin
    BdaSB($85, 16);
    If Cols = 40 Then BdaSW($4C, 2048) Else BdaSW($4C, 4096);
    FontRom(16);
    If Clr Then For K := 0 To 16383 Do SW($B8000 + K * 2, $0720);
  End
  Else
  Begin
    BdaSB($85, 8);
    If M = $13 Then BdaSW($4C, 64000) Else BdaSW($4C, 16384);
    If Clr Then
    Begin
      If M >= $0D Then For K := 0 To 65535 Do SB($A0000 + K, 0)
      Else For K := 0 To 16383 Do SB($B8000 + K, 0);
    End;
  End;
  BdaSW($60, $0607);
  For K := 0 To 31 Do CrReg[K] := 0;
  CrReg[$0A] := 14; CrReg[$0B] := 15;
  AcDefault;
  If M = $13 Then AcReg[$10] := $41 Else If M > 3 Then AcReg[$10] := 1;
  DacDefault;
  SqReg[2] := 3; SqReg[4] := 2; GcReg[6] := $0E;
  If M >= $0D Then Begin SqReg[2] := $0F; SqReg[4] := 6; GcReg[6] := 5; End;
  { modes planaires du VGA (et registres du mode 13h) : tables d'IBM }
  If PlModeOk(M) Or (M = $13) Then
  Begin
    If Clr Then PlSetMode(M) Else PlSetMode(M Or $80);
  End;
  CrtCursor;
End;

Procedure ScrollWin(Up : Boolean; N, Attr, R1, C1, R2, C2 : LongInt);
Var Cols, Rows, R, C, Base, Src : LongInt;
Begin
  If PlModeOk(BdaB($49)) Then
  Begin
    PlScroll(Up, N, Attr, R1, C1, R2, C2);
    Exit;
  End;
  Cols := BdaW($4A); Rows := BdaB($84) + 1;
  If R2 >= Rows Then R2 := Rows - 1;
  If C2 >= Cols Then C2 := Cols - 1;
  If (R1 > R2) Or (C1 > C2) Then Exit;
  If (N = 0) Or (N > R2 - R1 + 1) Then N := R2 - R1 + 1;
  If BdaB($49) = $13 Then
  Begin
    { 320 x 200 : cases de 8 x 8 }
    If Up Then
      For R := R1 To R2 Do
        For C := 0 To 7 Do
        Begin
          If R + N <= R2 Then CopyB(GMem + $A0000 + ((R + N) * 8 + C) * 320 + C1 * 8,
                                    GMem + $A0000 + (R * 8 + C) * 320 + C1 * 8, (C2 - C1 + 1) * 8)
          Else For Src := C1 * 8 To C2 * 8 + 7 Do SB($A0000 + (R * 8 + C) * 320 + Src, Attr);
        End
    Else
      For R := R2 DownTo R1 Do
        For C := 0 To 7 Do
        Begin
          If R - N >= R1 Then CopyB(GMem + $A0000 + ((R - N) * 8 + C) * 320 + C1 * 8,
                                    GMem + $A0000 + (R * 8 + C) * 320 + C1 * 8, (C2 - C1 + 1) * 8)
          Else For Src := C1 * 8 To C2 * 8 + 7 Do SB($A0000 + (R * 8 + C) * 320 + Src, Attr);
        End;
    Exit;
  End;
  If Not TextMode Then Exit;
  Base := $B8000 + BdaW($4E);
  If Up Then
    For R := R1 To R2 Do
    Begin
      If R + N <= R2 Then CopyB(GMem + Base + ((R + N) * Cols + C1) * 2, GMem + Base + (R * Cols + C1) * 2,
                                (C2 - C1 + 1) * 2)
      Else For C := C1 To C2 Do SW(Base + (R * Cols + C) * 2, (Attr Shl 8) Or 32);
    End
  Else
    For R := R2 DownTo R1 Do
    Begin
      If R - N >= R1 Then CopyB(GMem + Base + ((R - N) * Cols + C1) * 2, GMem + Base + (R * Cols + C1) * 2,
                                (C2 - C1 + 1) * 2)
      Else For C := C1 To C2 Do SW(Base + (R * Cols + C) * 2, (Attr Shl 8) Or 32);
    End;
End;

{ caractere en mode graphique (polices 8 x 8) }
Procedure GfxChar(X, Y, Ch, Color : LongInt);
Var R, C, B, M, A : LongInt;
Begin
  If PlModeOk(BdaB($49)) Then
  Begin
    PlGfxChar(X, Y, Ch, Color);
    Exit;
  End;
  M := BdaB($49);
  For R := 0 To 7 Do
  Begin
    B := Font8[Ch * 8 + R];
    For C := 0 To 7 Do
      If M = $13 Then
      Begin
        If (B And ($80 Shr C)) <> 0 Then SB($A0000 + (Y * 8 + R) * 320 + X * 8 + C, Color)
        Else SB($A0000 + (Y * 8 + R) * 320 + X * 8 + C, 0);
      End
      Else If (M = 4) Or (M = 5) Then
      Begin
        A := $B8000 + ((Y * 8 + R) And 1) * $2000 + ((Y * 8 + R) Div 2) * 80 + (X * 8 + C) Div 4;
        If (B And ($80 Shr C)) <> 0 Then
          SB(A, (GB(A) And Not (3 Shl (6 - ((X * 8 + C) Mod 4) * 2))) Or ((Color And 3) Shl (6 - ((X * 8 + C) Mod 4) * 2)))
        Else SB(A, GB(A) And Not (3 Shl (6 - ((X * 8 + C) Mod 4) * 2)));
      End
      Else If M = 6 Then
      Begin
        A := $B8000 + ((Y * 8 + R) And 1) * $2000 + ((Y * 8 + R) Div 2) * 80 + X;
        SB(A, B);
      End;
  End;
End;

Procedure PutCh(Ch, Attr, Count : LongInt; UseAttr : Boolean);
Var P, X, Y, Cols, A, K : LongInt;
Begin
  P := GBH And 7;
  X := BdaB($50 + P * 2); Y := BdaB($51 + P * 2);
  Cols := BdaW($4A);
  If TextMode Then
  Begin
    A := $B8000 + P * BdaW($4C) + (Y * Cols + X) * 2;
    For K := 0 To Count - 1 Do
    Begin
      SB(A + K * 2, Ch);
      If UseAttr Then SB(A + K * 2 + 1, Attr);
    End;
  End
  Else
    For K := 0 To Count - 1 Do
      If X + K < Cols Then GfxChar(X + K, Y, Ch, Attr);
End;

{ teletype (INT 10h AH=0Eh) }
Procedure Tty(Ch, Color : LongInt);
Var P, X, Y, Cols, Rows, A : LongInt;
Begin
  P := BdaB($62);
  X := BdaB($50 + P * 2); Y := BdaB($51 + P * 2);
  Cols := BdaW($4A); Rows := BdaB($84) + 1;
  Case Ch Of
    7 : ;
    8 : If X > 0 Then Dec(X);
    10 : Inc(Y);
    13 : X := 0;
  Else
    If TextMode Then
    Begin
      A := $B8000 + P * BdaW($4C) + (Y * Cols + X) * 2;
      SB(A, Ch);
    End
    Else GfxChar(X, Y, Ch, Color);
    Inc(X);
    If X >= Cols Then
    Begin
      X := 0;
      Inc(Y);
    End;
  End;
  If Y >= Rows Then
  Begin
    If TextMode Then
    Begin
      A := GB($B8000 + P * BdaW($4C) + ((Rows - 1) * Cols + X) * 2 + 1);
      If A = 0 Then A := 7;
      ScrollWin(True, 1, A, 0, 0, Rows - 1, Cols - 1);
    End
    Else ScrollWin(True, 1, 0, 0, 0, Rows - 1, Cols - 1);
    Y := Rows - 1;
  End;
  BdaSB($50 + P * 2, X); BdaSB($51 + P * 2, Y);
  CrtCursor;
End;

Procedure PutPix(X, Y, C : LongInt);
Var M, A, Sh : LongInt;
Begin
  M := BdaB($49);
  If M = $13 Then
  Begin
    If (X < 320) And (Y < 200) Then
      If (C And $80) <> 0 Then SB($A0000 + Y * 320 + X, GB($A0000 + Y * 320 + X) Xor (C And $7F))
      Else SB($A0000 + Y * 320 + X, C);
  End
  Else If (M = 4) Or (M = 5) Then
  Begin
    A := $B8000 + (Y And 1) * $2000 + (Y Div 2) * 80 + X Div 4;
    Sh := 6 - (X Mod 4) * 2;
    If (C And $80) <> 0 Then SB(A, GB(A) Xor ((C And 3) Shl Sh))
    Else SB(A, (GB(A) And Not (3 Shl Sh)) Or ((C And 3) Shl Sh));
  End
  Else If M = 6 Then
  Begin
    A := $B8000 + (Y And 1) * $2000 + (Y Div 2) * 80 + X Div 8;
    If (C And 1) <> 0 Then SB(A, GB(A) Or ($80 Shr (X Mod 8))) Else SB(A, GB(A) And Not ($80 Shr (X Mod 8)));
  End;
End;

Function GetPix(X, Y : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := BdaB($49);
  GetPix := 0;
  If M = $13 Then GetPix := GB($A0000 + Y * 320 + X)
  Else If (M = 4) Or (M = 5) Then
    GetPix := (GB($B8000 + (Y And 1) * $2000 + (Y Div 2) * 80 + X Div 4) Shr (6 - (X Mod 4) * 2)) And 3
  Else If M = 6 Then
    GetPix := (GB($B8000 + (Y And 1) * $2000 + (Y Div 2) * 80 + X Div 8) Shr (7 - X Mod 8)) And 1;
End;

Procedure Int10;
Var Ah, P, K, N, A, Hgt : LongInt;
Begin
  Ah := GAH;
  Case Ah Of
    $00 : SetMode(GAL);
    $01 : Begin BdaSW($60, GCX); CrReg[$0A] := GCH; CrReg[$0B] := GCL; End;
    $02 : Begin
            P := GBH And 7;
            BdaSB($50 + P * 2, GDL); BdaSB($51 + P * 2, GDH);
            CrtCursor;
          End;
    $03 : Begin
            P := GBH And 7;
            Set16(fDX, BdaW($50 + P * 2));
            Set16(fCX, BdaW($60));
          End;
    $05 : Begin
            BdaSB($62, GAL And 7);
            BdaSW($4E, (GAL And 7) * BdaW($4C));
            CrReg[$0C] := (BdaW($4E) Div 2) Shr 8; CrReg[$0D] := (BdaW($4E) Div 2) And 255;
            CrtCursor;
          End;
    $06, $07 : ScrollWin(Ah = 6, GAL, GBH, GCH, GCL, GDH, GDL);
    $08 : Begin
            P := GBH And 7;
            If TextMode Then
              Set16(fAX, GW($B8000 + P * BdaW($4C) + (BdaB($51 + P * 2) * BdaW($4A) + BdaB($50 + P * 2)) * 2))
            Else Set16(fAX, 0);
          End;
    $09 : PutCh(GAL, GBL, GCX, True);
    $0A : PutCh(GAL, GBL, GCX, False);
    $0B : ;
    $0C : If PlModeOk(BdaB($49)) Then PlPutPix(GCX, GDX, GAL) Else PutPix(GCX, GDX, GAL);
    $0D : If PlModeOk(BdaB($49)) Then SetLo(fAX, PlGetPix(GCX, GDX)) Else SetLo(fAX, GetPix(GCX, GDX));
    $0E : Tty(GAL, GBL);
    $0F : Begin
            SetLo(fAX, BdaB($49));
            SetHi(fAX, BdaW($4A));
            SetHi(fBX, BdaB($62));
          End;
    $10 : Case GAL Of
            $00 : AcReg[GBL And 15] := GBH;
            $01 : AcReg[$11] := GBH;
            $02 : For K := 0 To 16 Do
                    If K < 16 Then AcReg[K] := LB(SegLin(Fr_[fESB], GDX + K)) Else AcReg[$11] := LB(SegLin(Fr_[fESB], GDX + K));
            $03 : If GBL = 0 Then AcReg[$10] := AcReg[$10] And Not 8 Else AcReg[$10] := AcReg[$10] Or 8;
            $07 : SetHi(fBX, AcReg[GBL And 31]);
            $08 : SetHi(fBX, AcReg[$11]);
            $09 : For K := 0 To 16 Do
                    If K < 16 Then LSB(SegLin(Fr_[fESB], GDX + K), AcReg[K]) Else LSB(SegLin(Fr_[fESB], GDX + K), AcReg[$11]);
            $10 : Begin
                    A := (GBX And 255) * 3;
                    Dac[A] := GDH And 63; Dac[A + 1] := GCH And 63; Dac[A + 2] := GCL And 63;
                  End;
            $12 : For K := 0 To GCX * 3 - 1 Do
                    If (GBX * 3 + K) < 768 Then Dac[GBX * 3 + K] := LB(SegLin(Fr_[fESB], GDX + K)) And 63;
            $15 : Begin
                    A := (GBX And 255) * 3;
                    SetHi(fDX, Dac[A]); SetHi(fCX, Dac[A + 1]); SetLo(fCX, Dac[A + 2]);
                  End;
            $17 : For K := 0 To GCX * 3 - 1 Do
                    If (GBX * 3 + K) < 768 Then LSB(SegLin(Fr_[fESB], GDX + K), Dac[GBX * 3 + K]);
            $1B : ;
          End;
    $11 : Begin
            Case GAL Of
              $00, $10 : Begin
                           Hgt := GBH;
                           If Hgt = 0 Then Hgt := 16;
                           FontPut(SegLin(Fr_[fESB], Fr_[fBP]), GDX, GCX, Hgt, True);
                           If GAL = $10 Then
                           Begin
                             BdaSB($85, Hgt);
                             BdaSB($84, 400 Div Hgt - 1);
                           End;
                         End;
              $01, $11 : Begin FontRom(14); If GAL = $11 Then Begin BdaSB($85, 14); BdaSB($84, 27); End; End;
              $02, $12 : Begin FontRom(8); If GAL = $12 Then Begin BdaSB($85, 8); BdaSB($84, 49); End; End;
              $04, $14 : Begin FontRom(16); If GAL = $14 Then Begin BdaSB($85, 16); BdaSB($84, 24); End; End;
              $03 : ;
              $20, $21, $22, $23, $24 : ;
              $30 : Begin
                      Case GBH Of
                        0 : Begin Fr_[fES] := GW($1F * 4 + 2); Set16(fBP, GW($1F * 4)); End;
                        1 : Begin Fr_[fES] := GW($43 * 4 + 2); Set16(fBP, GW($43 * 4)); End;
                        2, 5 : Begin Fr_[fES] := $F000; Set16(fBP, RomF14); End;
                        3 : Begin Fr_[fES] := $F000; Set16(fBP, RomF8); End;
                        4 : Begin Fr_[fES] := $F000; Set16(fBP, RomF8A + 1024); End;
                      Else
                        Fr_[fES] := $F000; Set16(fBP, RomF16);
                      End;
                      Fr_[fSET] := Fr_[fSET] Or 1;
                      Set16(fCX, BdaB($85));
                      SetLo(fDX, BdaB($84));
                    End;
            End;
          End;
    $12 : Case GBL Of
            $10 : Begin Set16(fBX, $0003); Set16(fCX, $0009); End;
            $30, $31, $32, $33, $34, $36 : SetLo(fAX, $12);
          End;
    $13 : Begin
            { chaine : ES:BP, CX caracteres, DH:DL position, BL attribut }
            P := GBH And 7;
            N := GCX;
            A := SegLin(Fr_[fESB], Fr_[fBP]);
            K := BdaW($50 + P * 2);
            BdaSB($50 + P * 2, GDL); BdaSB($51 + P * 2, GDH);
            For Hgt := 0 To N - 1 Do
            Begin
              If (GAL And 2) <> 0 Then
              Begin
                If (LB(A + Hgt * 2) >= 32) And TextMode Then
                  SB($B8000 + P * BdaW($4C) + (BdaB($51 + P * 2) * BdaW($4A) + BdaB($50 + P * 2)) * 2 + 1,
                     LB(A + Hgt * 2 + 1));
                Tty(LB(A + Hgt * 2), LB(A + Hgt * 2 + 1));
              End
              Else
              Begin
                If (LB(A + Hgt) >= 32) And TextMode Then
                  SB($B8000 + P * BdaW($4C) + (BdaB($51 + P * 2) * BdaW($4A) + BdaB($50 + P * 2)) * 2 + 1, GBL);
                Tty(LB(A + Hgt), GBL);
              End;
            End;
            If (GAL And 1) = 0 Then
            Begin
              BdaSW($50 + P * 2, K);
              CrtCursor;
            End;
          End;
    $1A : Begin
            If GAL = 0 Then Set16(fBX, $0008);
            SetLo(fAX, $1A);
          End;
    $1B : SetLo(fAX, 0);
    $4F : Set16(fAX, $014F);
  End;
End;

{ ---- INT 13h ---- }

{ lecteur du BIOS -> unite ; avec l'emulation El Torito, l'image du
  CD-ROM devient la disquette 00h (la vraie passe en 01h) ou le disque
  80h (les disques passent en 81h et 82h) ; E0h : le CD-ROM lui-meme }
Function DiskOf(Dl : LongInt) : LongInt;
Var D : LongInt;
Begin
  D := -1;
  If CdOn And (Dl = $E0) Then D := DkCd
  Else If CdEmuOn And (CdEmu < 4) Then
  Begin
    If Dl = 0 Then D := DkEmu
    Else If Dl = 1 Then D := 2
    Else If Dl = $80 Then D := 0
    Else If Dl = $81 Then D := 1;
  End
  Else If CdEmuOn Then
  Begin
    If Dl = $80 Then D := DkEmu
    Else If Dl = $81 Then D := 0
    Else If Dl = $82 Then D := 1
    Else If Dl = 0 Then D := 2;
  End
  Else If Dl = $80 Then D := 0
  Else If Dl = $81 Then D := 1
  Else If Dl = 0 Then D := 2;
  If (D >= 0) And (DkH[D] < 0) Then D := -1;
  DiskOf := D;
End;

{ unite de type disquette (2 ou image El Torito de disquette) }
Function IsFd(D : LongInt) : Boolean;
Begin
  IsFd := (D = 2) Or ((D = DkEmu) And (CdEmu < 4));
End;

{ type de disquette pour INT 13h 08h : 2 (1,2 Mo), 4 (1,44), 6 (2,88) }
Function FdType(D : LongInt) : LongInt;
Begin
  If DkSect[D] >= 5760 Then FdType := 6
  Else If DkSect[D] = 2400 Then FdType := 2
  Else If DkSect[D] <= 1440 Then FdType := 3
  Else FdType := 4;
End;

Procedure DiskRet(Dl, St : LongInt);
Begin
  SetHi(fAX, St);
  SetCF(St <> 0);
  If Dl >= $80 Then BdaSB($74, St) Else BdaSB($41, St);
End;

{ N secteurs de Lba <-> memoire de l'invite (lineaire Lin) ; rend le
  nombre traite }
Function DiskXfer(D, Lba, N, Lin : LongInt; Wr : Boolean) : LongInt;
Var K : LongInt;
Begin
  K := 0;
  While K < N Do
  Begin
    If Wr Then
    Begin
      FromGuest(Lin + K * 512, LongInt(@SecBuf), 512);
      If Not DkWriteSec(D, Lba + K, LongInt(@SecBuf)) Then Break;
    End
    Else
    Begin
      If Not DkReadSec(D, Lba + K, LongInt(@SecBuf)) Then Break;
      ToGuest(Lin + K * 512, LongInt(@SecBuf), 512);
    End;
    Inc(K);
  End;
  DiskXfer := K;
End;

Procedure Int13;
Var Ah, Dl, D, C, H, S, Lba, N, Done, A, Nh : LongInt;
Begin
  Ah := GAH; Dl := GDL;
  D := DiskOf(Dl);
  Nh := 0;
  If DkH[0] >= 0 Then Inc(Nh);
  If DkH[1] >= 0 Then Inc(Nh);
  If CdEmuOn And (CdEmu = 4) Then Inc(Nh);
  If (D = DkCd) And (Ah >= 2) And (Ah <= $3F) And (Ah <> 8) And (Ah <> $15) Then
  Begin
    DiskRet(Dl, 1);
    Exit;
  End;
  Case Ah Of
    $00, $0D : If (D >= 0) Or (Dl < $80) Then DiskRet(Dl, 0) Else DiskRet(Dl, 1);
    $16 : If (D = 2) And (FdChanged <> 0) Then
          Begin
            { disquette changee (menu Peripheriques de la fenetre) }
            FdChanged := 0;
            DiskRet(Dl, 6);
          End
          Else If D < 0 Then DiskRet(Dl, $80) Else DiskRet(Dl, 0);
    $01 : Begin
            If Dl >= $80 Then SetHi(fAX, BdaB($74)) Else SetHi(fAX, BdaB($41));
            SetCF(GAH <> 0);
          End;
    $02, $03, $04 :
      Begin
        If D < 0 Then Begin DiskRet(Dl, $80); SetLo(fAX, 0); Exit; End;
        C := GCH Or ((GCL And $C0) Shl 2); H := GDH; S := GCL And 63; N := GAL;
        If (S < 1) Or (S > DkSpt[D]) Or (H >= DkHeads[D]) Then Begin DiskRet(Dl, $04); SetLo(fAX, 0); Exit; End;
        Lba := (C * DkHeads[D] + H) * DkSpt[D] + S - 1;
        If Ah = 4 Then Begin DiskRet(Dl, 0); Exit; End;
        Done := DiskXfer(D, Lba, N, SegLin(Fr_[fESB], GBX), Ah = 3);
        SetLo(fAX, Done);
        If Done = N Then DiskRet(Dl, 0)
        Else If (Ah = 3) And (DkRO[D] <> 0) Then DiskRet(Dl, 3)
        Else DiskRet(Dl, 4);
      End;
    $08 : Begin
            If D < 0 Then
            Begin
              If Dl < $80 Then
              Begin
                Set16(fBX, 0); Set16(fCX, 0); Set16(fDX, 0); DiskRet(Dl, 0);
              End
              Else DiskRet(Dl, 7);
              Exit;
            End;
            If D = DkCd Then Begin DiskRet(Dl, 1); Exit; End;
            C := DkCyl[D] - 1;
            Set16(fCX, ((C And 255) Shl 8) Or ((C Shr 2) And $C0) Or DkSpt[D]);
            If IsFd(D) Then
            Begin
              SetHi(fDX, 1); SetLo(fDX, 1); Set16(fBX, FdType(D));
              If CdEmuOn And (CdEmu < 4) And (DkH[2] >= 0) Then SetLo(fDX, 2);
              Fr_[fES] := $F000; Set16(fDI, RomFdpt);
              Fr_[fSET] := Fr_[fSET] Or 1;
            End
            Else
            Begin
              SetHi(fDX, DkHeads[D] - 1); SetLo(fDX, Nh);
            End;
            SetLo(fAX, 0);
            DiskRet(Dl, 0);
          End;
    $10, $11, $0C, $17, $18 :
      Begin
        If D < 0 Then DiskRet(Dl, $80) Else DiskRet(Dl, 0);
        If (Ah = $18) And IsFd(D) Then
        Begin
          Fr_[fES] := $F000; Set16(fDI, RomFdpt);
          Fr_[fSET] := Fr_[fSET] Or 1;
        End;
      End;
    $15 : Begin
            If D < 0 Then
            Begin
              SetHi(fAX, 0); SetCF(Dl >= $80);
              Exit;
            End;
            If IsFd(D) Then SetHi(fAX, 2)
            Else If D = DkCd Then SetHi(fAX, 0)
            Else
            Begin
              SetHi(fAX, 3);
              Set16(fCX, DkSect[D] Shr 16); Set16(fDX, DkSect[D] And $FFFF);
            End;
            SetCF(False);
          End;
    $41 : If (D >= 0) And Not IsFd(D) And (GBX = $55AA) Then
          Begin
            Set16(fBX, $AA55); SetHi(fAX, $21); Set16(fCX, 1); SetCF(False);
          End
          Else DiskRet(Dl, 1);
    $42, $43, $44 :
      Begin
        If D < 0 Then Begin DiskRet(Dl, $80); Exit; End;
        A := SegLin(Fr_[fDSB], Fr_[fSI]);
        N := LW(A + 2);
        Lba := LL(A + 8);
        If Ah = $44 Then Begin DiskRet(Dl, 0); Exit; End;
        If D = DkCd Then
        Begin
          { secteurs de 2048 octets }
          If Ah = $43 Then Begin DiskRet(Dl, 3); Exit; End;
          Done := DiskXfer(D, Lba * 4, N * 4, SegLin(LW(A + 6) Shl 4, LW(A + 4)), False) Div 4;
        End
        Else Done := DiskXfer(D, Lba, N, SegLin(LW(A + 6) Shl 4, LW(A + 4)), Ah = $43);
        LSW(A + 2, Done);
        If Done = N Then DiskRet(Dl, 0) Else DiskRet(Dl, 4);
      End;
    $48 : Begin
            If (D < 0) Or IsFd(D) Then Begin DiskRet(Dl, 1); Exit; End;
            A := SegLin(Fr_[fDSB], Fr_[fSI]);
            If D = DkCd Then
            Begin
              LSW(A, 26); LSW(A + 2, $74);
              For C := 4 To 15 Do LSB(A + C, 0);
              LSW(A + 16, (DkSect[D] Div 4) And $FFFF); LSW(A + 18, (DkSect[D] Div 4) Shr 16);
              LSW(A + 20, 0); LSW(A + 22, 0); LSW(A + 24, 2048);
              DiskRet(Dl, 0);
              Exit;
            End;
            LSW(A, 26); LSW(A + 2, 2);
            LSW(A + 4, DkCyl[D]); LSW(A + 6, 0); LSW(A + 8, DkHeads[D]); LSW(A + 10, 0);
            LSW(A + 12, DkSpt[D]); LSW(A + 14, 0);
            LSW(A + 16, DkSect[D] And $FFFF); LSW(A + 18, DkSect[D] Shr 16); LSW(A + 20, 0); LSW(A + 22, 0);
            LSW(A + 24, 512);
            DiskRet(Dl, 0);
          End;
    $4B : Begin
            { El Torito : AL=00h fin de l'emulation, 01h etat (paquet de
              13h octets en DS:SI) }
            If Not CdOn Or (GAL > 1) Then Begin DiskRet(Dl, 1); Exit; End;
            A := SegLin(Fr_[fDSB], Fr_[fSI]);
            LSB(A, $13); LSB(A + 1, CdEmu);
            If CdEmu = 0 Then LSB(A + 2, $E0) Else If CdEmu < 4 Then LSB(A + 2, 0) Else LSB(A + 2, $80);
            LSB(A + 3, 0); LSW(A + 4, CdBootLba And $FFFF); LSW(A + 6, CdBootLba Shr 16);
            LSW(A + 8, 0); LSW(A + 10, 0); LSW(A + 12, CdLoadSeg); LSW(A + 14, CdBootCnt);
            If CdEmu > 0 Then
            Begin
              C := DkCyl[DkEmu] - 1;
              LSB(A + 16, C And 255); LSB(A + 17, ((C Shr 2) And $C0) Or DkSpt[DkEmu]); LSB(A + 18, DkHeads[DkEmu] - 1);
            End
            Else Begin LSB(A + 16, 0); LSB(A + 17, 0); LSB(A + 18, 0); End;
            If GAL = 0 Then CdEmuOn := False;
            DiskRet(Dl, 0);
          End;
  Else
    DiskRet(Dl, 1);
  End;
End;

{ ---- INT 15h ---- }

Procedure Int15;
Var Ah, A, Src, Dst, N, Ext, K : LongInt;
Begin
  Ah := GAH;
  Ext := GSize Div 1024 - 1024;
  If Ext < 0 Then Ext := 0;
  Case Ah Of
    $4F : Exit;
    $53 : Begin
            { APM 1.2 (gestion de l'alimentation), interface du mode reel :
              POWER ADV:OFF de MSDOS-0 (5301h, 530Eh, 5308h puis 5307h
              BX=0001h CX=0003h) eteint la machine }
            SetCF(False); SetHi(fAX, 0);
            Case GAL Of
              $00 : Begin Set16(fAX, $0102); Set16(fBX, $504D); Set16(fCX, 0); End;
              $01, $04, $06, $08, $09, $0D, $0F : ;
              $02, $03 : Begin SetHi(fAX, $86); SetCF(True); End;
              $05 : If (Fr_[fFL] And $200) <> 0 Then VmIdleWait := 1;
              $07 : Case GCX Of
                      2 : VmIdleWait := 1;
                      3 : If (GBX = 1) Or (GBX = $1FF) Or (GBX = 0) Then
                          Begin
                            VmMsg := Fr('L''invite a `eteint la machine (APM).');
                            VmPowerOff := 1;
                            VmReqStop := 1;
                          End;
                    End;
              $0A : Begin Set16(fBX, $01FF); Set16(fCX, $80FF); Set16(fDX, $FFFF); End;
              $0B : Begin SetHi(fAX, $80); SetCF(True); End;
              $0C : Set16(fCX, 0);
              $0E : Set16(fAX, $0102);
              $10 : Begin SetLo(fBX, 0); Set16(fCX, 0); End;
            Else
              Begin SetHi(fAX, $09); SetCF(True); End;
            End;
          End;
    $24 : Begin
            Case GAL Of
              0 : SetA20(0);
              1 : SetA20(1);
              2 : SetLo(fAX, A20);
              3 : Set16(fBX, 3);
            End;
            SetHi(fAX, 0); SetCF(False);
          End;
    $41, $85, $86, $90, $91 : Begin SetHi(fAX, 0); SetCF(False); End;
    $87 : Begin
            { copie : table de descripteurs en ES:SI }
            A := SegLin(Fr_[fESB], Fr_[fSI]);
            Src := LW(A + $12) Or (LB(A + $14) Shl 16) Or (LB(A + $17) Shl 24);
            Dst := LW(A + $1A) Or (LB(A + $1C) Shl 16) Or (LB(A + $1F) Shl 24);
            N := GCX * 2;
            For K := 0 To N - 1 Do SB(Dst + K, GB(Src + K));
            SetHi(fAX, 0); SetCF(False); SetZF(True);
          End;
    $88 : Begin Set16(fAX, MinI(Ext, $FC00)); SetCF(False); End;
    $C0 : Begin
            Fr_[fES] := $F000; Set16(fBX, RomCfg); Fr_[fSET] := Fr_[fSET] Or 1;
            SetHi(fAX, 0); SetCF(False);
          End;
    $E8 : If GAL = 1 Then
          Begin
            Set16(fAX, MinI(Ext, 15360)); Set16(fCX, MinI(Ext, 15360));
            If Ext > 15360 Then N := (Ext - 15360) Div 64 Else N := 0;
            Set16(fBX, N); Set16(fDX, N);
            SetCF(False);
          End
          Else If (GAL = $20) And (Fr_[fDX] = $534D4150) Then
          Begin
            A := SegLin(Fr_[fESB], Fr_[fDI]);
            K := Fr_[fBX];
            Case K Of
              0 : Begin Src := 0; N := $9FC00; Dst := 1; End;
              1 : Begin Src := $9FC00; N := $400; Dst := 2; End;
              2 : Begin Src := $F0000; N := $10000; Dst := 2; End;
            Else
              Src := $100000; N := GSize - $100000; Dst := 1;
            End;
            LSW(A, Src And $FFFF); LSW(A + 2, Src Shr 16); LSW(A + 4, 0); LSW(A + 6, 0);
            LSW(A + 8, N And $FFFF); LSW(A + 10, N Shr 16); LSW(A + 12, 0); LSW(A + 14, 0);
            LSW(A + 16, Dst); LSW(A + 18, 0);
            If K >= 3 Then Fr_[fBX] := 0 Else Fr_[fBX] := K + 1;
            Fr_[fAX] := $534D4150; Fr_[fCX] := 20;
            SetCF(False);
          End
          Else Begin SetHi(fAX, $86); SetCF(True); End;
  Else
    SetHi(fAX, $86); SetCF(True);
  End;
End;

{ ---- clavier : tampon 0040:001E (tete 1Ah, queue 1Ch) ---- }

Function KbufEmpty : Boolean;
Begin
  KbufEmpty := BdaW($1A) = BdaW($1C);
End;

Procedure KbufPut(W : LongInt);
Var T, N : LongInt;
Begin
  T := BdaW($1C);
  N := T + 2;
  If N >= BdaW($82) Then N := BdaW($80);
  If N = BdaW($1A) Then Exit;
  SW($400 + T, W);
  BdaSW($1C, N);
End;

Function KbufGet(Remove : Boolean) : LongInt;
Var H, N : LongInt;
Begin
  H := BdaW($1A);
  KbufGet := GW($400 + H);
  If Remove Then
  Begin
    N := H + 2;
    If N >= BdaW($82) Then N := BdaW($80);
    BdaSW($1A, N);
  End;
End;

Const
  KNorm : String[58] = #0#27'1234567890-='#8#9'qwertyuiop[]'#13#0'asdfghjkl;''`'#0'\zxcvbnm,./'#0'*'#0' ';
  KShift : String[58] = #0#27'!@#$%^&*()_+'#8#0'QWERTYUIOP{}'#13#0'ASDFGHJKL:"~'#0'|ZXCVBNM<>?'#0'*'#0' ';
  KPadN : String[13] = '789-456+1230.';

{ traduction d'un code de balayage (INT 09h du BIOS) }
Procedure KbdService(Sc : LongInt);
Var F, Brk, Mk, Ch, W, Ext : LongInt;
Begin
  F := BdaB($17);
  Ext := BdaB($96) And 2;
  If Sc = $E0 Then
  Begin
    BdaSB($96, BdaB($96) Or 2);
    Exit;
  End;
  BdaSB($96, BdaB($96) And Not 2);
  Brk := Sc And $80; Mk := Sc And $7F;
  Case Mk Of
    $2A : Begin If Brk = 0 Then F := F Or 2 Else F := F And Not 2; BdaSB($17, F); Exit; End;
    $36 : Begin If Brk = 0 Then F := F Or 1 Else F := F And Not 1; BdaSB($17, F); Exit; End;
    $1D : Begin If Brk = 0 Then F := F Or 4 Else F := F And Not 4; BdaSB($17, F); Exit; End;
    $38 : Begin If Brk = 0 Then F := F Or 8 Else F := F And Not 8; BdaSB($17, F); Exit; End;
    $3A : Begin If Brk = 0 Then F := F Xor $40; BdaSB($17, F); Exit; End;
    $45 : Begin If Brk = 0 Then F := F Xor $20; BdaSB($17, F); Exit; End;
    $46 : Begin If Brk = 0 Then F := F Xor $10; BdaSB($17, F); Exit; End;
  End;
  If Brk <> 0 Then Exit;
  { Ctrl+Alt+Suppr }
  If (Mk = $53) And ((F And $0C) = $0C) Then
  Begin
    SW($472, $1234);
    VmReqReset := 1;
    Exit;
  End;
  If Mk = $52 Then F := F Xor $80;
  BdaSB($17, F);
  Ch := 0;
  If (Mk >= $3B) And (Mk <= $44) Then
  Begin
    { F1..F10 }
    If (F And 8) <> 0 Then W := (Mk + $2D) Shl 8
    Else If (F And 4) <> 0 Then W := (Mk + $23) Shl 8
    Else If (F And 3) <> 0 Then W := (Mk + $19) Shl 8
    Else W := Mk Shl 8;
    KbufPut(W);
    Exit;
  End;
  If (Mk = $57) Or (Mk = $58) Then
  Begin
    If (F And 3) <> 0 Then W := (Mk + $30) Shl 8 Else W := (Mk + $2E) Shl 8;
    KbufPut(W);
    Exit;
  End;
  If (Mk >= $47) And (Mk <= $53) Then
  Begin
    { pave numerique ou touches grises (E0) }
    If (Ext = 0) And ((((F And $20) <> 0) Xor ((F And 3) <> 0))) Then
      KbufPut((Mk Shl 8) Or Ord(KPadN[Mk - $46]))
    Else If (Mk = $4A) Or (Mk = $4E) Then KbufPut((Mk Shl 8) Or Ord(KPadN[Mk - $46]))
    Else If (F And 4) <> 0 Then
    Begin
      Case Mk Of
        $47 : W := $77; $48 : W := $8D; $49 : W := $84; $4B : W := $73; $4D : W := $74;
        $4F : W := $75; $50 : W := $91; $51 : W := $76; $52 : W := $92; $53 : W := $93;
      Else
        W := Mk;
      End;
      KbufPut(W Shl 8);
    End
    Else If Ext <> 0 Then KbufPut((Mk Shl 8) Or $E0)
    Else KbufPut(Mk Shl 8);
    Exit;
  End;
  If (Mk = $1C) And (Ext <> 0) Then Begin KbufPut($E00D); Exit; End;
  If (Mk = $35) And (Ext <> 0) Then Begin KbufPut($E02F); Exit; End;
  If Mk > $39 Then Exit;
  If (F And 3) <> 0 Then Ch := Ord(KShift[Mk + 1]) Else Ch := Ord(KNorm[Mk + 1]);
  If ((F And $40) <> 0) And (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then
  Begin
    If (Ch >= 97) Then Ch := Ch - 32 Else Ch := Ch + 32;
  End;
  If (F And 8) <> 0 Then
  Begin
    If (Mk >= 2) And (Mk <= $0D) Then KbufPut((Mk + $76) Shl 8)
    Else KbufPut(Mk Shl 8);
    Exit;
  End;
  If (F And 4) <> 0 Then
  Begin
    If (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then Ch := Ord(UpCase(Chr(Ch))) - 64
    Else
      Case Mk Of
        $1A : Ch := $1B; $1B : Ch := $1D; $2B : Ch := $1C; $0C : Ch := $1F; $0E : Ch := $7F; $1C : Ch := $0A;
        $03 : Ch := 0;
      Else
        Exit;
      End;
  End;
  KbufPut((Mk Shl 8) Or Ch);
End;

{ INT 16h ; rend False si l'invite doit attendre une touche }
Function Int16 : Boolean;
Var Ah, W : LongInt;
Begin
  Int16 := True;
  Ah := GAH;
  Case Ah Of
    $00, $10 : Begin
                 If KbufEmpty Then
                 Begin
                   Int16 := False;
                   Exit;
                 End;
                 W := KbufGet(True);
                 If (Ah = 0) And ((W And 255) = $E0) Then W := W And $FF00;
                 Set16(fAX, W);
               End;
    $01, $11 : Begin
                 If KbufEmpty Then SetZF(True)
                 Else
                 Begin
                   W := KbufGet(False);
                   If (Ah = 1) And ((W And 255) = $E0) Then W := W And $FF00;
                   Set16(fAX, W);
                   SetZF(False);
                 End;
               End;
    $02 : SetLo(fAX, BdaB($17));
    $12 : Set16(fAX, BdaB($17) Or (BdaB($18) Shl 8));
    $05 : Begin KbufPut(GCX); SetLo(fAX, 0); End;
    $03, $04 : ;
    $09 : SetLo(fAX, $20);
    $0A : Set16(fBX, $41AB);
  End;
End;

Procedure Int1A;
Var Dt : Array[0..15] Of Byte;
Begin
  Dummy := DosGetDateTime(LongInt(@Dt));
  Case GAH Of
    0 : Begin
          Set16(fCX, BdaW($6E)); Set16(fDX, BdaW($6C));
          SetLo(fAX, BdaB($70)); BdaSB($70, 0);
        End;
    1 : Begin BdaSW($6E, GCX); BdaSW($6C, GDX); End;
    2 : Begin
          SetHi(fCX, Bcd(Dt[0])); SetLo(fCX, Bcd(Dt[1])); SetHi(fDX, Bcd(Dt[2])); SetLo(fDX, 0);
          SetCF(False);
        End;
    4 : Begin
          SetHi(fCX, Bcd((Dt[6] Or (Dt[7] Shl 8)) Div 100)); SetLo(fCX, Bcd((Dt[6] Or (Dt[7] Shl 8)) Mod 100));
          SetHi(fDX, Bcd(Dt[5])); SetLo(fDX, Bcd(Dt[4]));
          SetCF(False);
        End;
    3, 5, 6, 7 : SetCF(False);
  Else
    SetCF(True);
  End;
End;

Procedure Message(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Tty(Ord(S[K]), 7);
  Tty(13, 7); Tty(10, 7);
End;

{ amorcage : disquette (si demandee) puis disque dur }
{ amorcage par le CD-ROM (El Torito) : sans emulation, CdBootCnt
  secteurs de 512 octets en CdLoadSeg:0000 (DL = E0h) ; avec emulation,
  secteur 0 de l'image en 0000:7C00 (DL = 00h ou 80h) }
Function CdBoot : Boolean;
Var K : LongInt;
Begin
  CdBoot := False;
  If Not CdOn Then Exit;
  If CdEmu = 0 Then
  Begin
    For K := 0 To CdBootCnt - 1 Do
    Begin
      If Not DkReadSec(DkCd, CdBootLba * 4 + K, LongInt(@SecBuf)) Then Exit;
      CopyB(LongInt(@SecBuf), GMem + CdLoadSeg * 16 + K * 512, 512);
    End;
    BootDrive := $E0;
    Fr_[fCS] := CdLoadSeg; Fr_[fIP] := 0;
  End
  Else
  Begin
    If Not DkReadSec(DkEmu, 0, LongInt(@SecBuf)) Then Exit;
    CopyB(LongInt(@SecBuf), GMem + $7C00, 512);
    CdEmuOn := True;
    If CdEmu < 4 Then
    Begin
      BootDrive := 0;
      BdaSW($10, BdaW($10) Or 1);
      If DkH[2] >= 0 Then BdaSW($10, (BdaW($10) And Not $C0) Or $40);
    End
    Else
    Begin
      BootDrive := $80;
      BdaSB($75, BdaB($75) + 1);
    End;
    Fr_[fCS] := 0; Fr_[fIP] := $7C00;
  End;
  Fr_[fDX] := BootDrive;
  Fr_[fSS] := 0; Fr_[fSP] := $7C00;
  Fr_[fDS] := 0; Fr_[fES] := 0; Fr_[fFS] := 0; Fr_[fGS] := 0;
  Fr_[fFL] := $202;
  Fr_[fSET] := Fr_[fSET] Or 1;
  CdBoot := True;
End;

Function Boot : Boolean;
Var D, K : LongInt; Order : Array[0..1] Of LongInt;
Begin
  Boot := False;
  CdEmuOn := False;
  If (CurVm >= 0) And (Vms[CurVm].BootCd <> 0) And CdOn Then
    If CdBoot Then
    Begin
      Boot := True;
      Exit;
    End;
  If (CurVm >= 0) And (Vms[CurVm].BootFd <> 0) Then
  Begin
    Order[0] := 2; Order[1] := 0;
  End
  Else
  Begin
    Order[0] := 0; Order[1] := 2;
  End;
  For K := 0 To 1 Do
  Begin
    D := Order[K];
    If DkH[D] >= 0 Then
      If DkReadSec(D, 0, LongInt(@SecBuf)) Then
        If (SecBuf[510] = $55) And (SecBuf[511] = $AA) Then
        Begin
          CopyB(LongInt(@SecBuf), GMem + $7C00, 512);
          If D = 2 Then BootDrive := 0 Else BootDrive := $80;
          Fr_[fDX] := BootDrive;
          Fr_[fCS] := 0; Fr_[fIP] := $7C00; Fr_[fSS] := 0; Fr_[fSP] := $7C00;
          Fr_[fDS] := 0; Fr_[fES] := 0; Fr_[fFS] := 0; Fr_[fGS] := 0;
          Fr_[fFL] := $202;
          Fr_[fSET] := Fr_[fSET] Or 1;
          Boot := True;
          Exit;
        End;
  End;
  { CD-ROM en dernier recours }
  If CdOn And CdBoot Then Boot := True;
End;

{ POST : vecteurs, donnees du BIOS, ROM, peripheriques, amorcage }
Procedure Post;
Var K, Dt0, Ms : LongInt; Dt : Array[0..15] Of Byte;
Begin
  For K := 0 To $4FF Do SB(K, 0);
  { ROM : talons, code, tables, polices }
  For K := $F0000 To $FFFFF Do SB(K, 0);
  For K := 0 To 255 Do
  Begin
    SB($F0000 + RomStub + K * 8, $FB);
    SB($F0000 + RomStub + K * 8 + 1, $E6); SB($F0000 + RomStub + K * 8 + 2, $EE);
    SB($F0000 + RomStub + K * 8 + 3, $CA); SB($F0000 + RomStub + K * 8 + 4, 2); SB($F0000 + RomStub + K * 8 + 5, 0);
  End;
  RomHex($F0000 + RomInt08, BiosHex);
  SB($F0000 + RomIret, $CF);
  { F000:FFF0 : JMP F000:E05E ; date ; modele (AT) }
  SB($FFFF0, $EA); SW($FFFF1, RomPost); SW($FFFF3, $F000);
  RomHex($FFFF5, '31312F32322F3236');
  SB($FFFFE, $FC);
  { F000:FF00 : HLT du retour force (mode V86 du noyau) }
  SB($FFF00, $F4);
  { configuration (INT 15h C0h) }
  RomHex($F0000 + RomCfg, '0800FC010070000000');
  { disquette 1,44 Mo (INT 1Eh) }
  RomHex($F0000 + RomFdpt, 'AF02250212221BFF6CF60F08');
  CopyB(LongInt(@Font8), GMem + $F0000 + RomF8, 1024);
  CopyB(LongInt(@Font8), GMem + $F0000 + RomF8A, 2048);
  CopyB(LongInt(@Font16), GMem + $F0000 + RomF16, 4096);
  For K := 0 To 255 * 14 + 13 Do
    SB($F0000 + RomF14 + K, Font16[(K Div 14) * 16 + ((K Mod 14) * 16 + 7) Div 14]);
  { vecteurs }
  For K := 0 To 255 Do SetVec(K, $F000, RomIret);
  For K := $10 To $1A Do SetVec(K, $F000, RomStub + K * 8);
  SetVec($08, $F000, RomInt08);
  SetVec($09, $F000, RomInt09);
  For K := $0A To $0F Do SetVec(K, $F000, RomIrqM);
  For K := $70 To $77 Do SetVec(K, $F000, RomIrqS);
  SetVec($1C, $F000, RomIret);
  SetVec($1D, $F000, RomVpt);
  SetVec($1E, $F000, RomFdpt);
  SetVec($1F, $F000, RomF8A + 1024);
  SetVec($43, $F000, RomF8A);
  SetVec($41, $F000, RomHdpt);
  SetVec($46, $F000, RomHdpt);
  SetVec($40, $F000, RomStub + $13 * 8);
  { table du disque 0 (INT 41h) }
  If DkH[0] >= 0 Then
  Begin
    SW($F0000 + RomHdpt, DkCyl[0]); SB($F0000 + RomHdpt + 2, DkHeads[0]);
    SB($F0000 + RomHdpt + 14, DkSpt[0]);
  End;
  { donnees du BIOS }
  K := $22 Or $20;
  If DkH[2] >= 0 Then K := K Or 1;
  BdaSW($10, K);
  BdaSW($13, 640);
  BdaSW($1A, $1E); BdaSW($1C, $1E); BdaSW($80, $1E); BdaSW($82, $3E);
  BdaSB($17, 0); BdaSB($96, $10);
  K := 0;
  If DkH[0] >= 0 Then Inc(K);
  If DkH[1] >= 0 Then Inc(K);
  BdaSB($75, K);
  BdaSW($63, $3D4); BdaSB($65, $29); BdaSB($66, $30);
  BdaSB($87, $60); BdaSB($88, $09); BdaSB($89, $11); BdaSB($8A, $0B);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Dt0 := Dt[0] * 3600 + Dt[1] * 60 + Dt[2];
  Ms := (Dt0 Div 10) * 182 + ((Dt0 Mod 10) * 182) Div 10;
  BdaSW($6C, Ms And $FFFF); BdaSW($6E, Ms Shr 16);
  { peripheriques }
  PicImr[0] := $B8; PicImr[1] := $8F; PicIrr[0] := 0; PicIrr[1] := 0; PicIsr[0] := 0; PicIsr[1] := 0;
  PicBase[0] := 8; PicBase[1] := $70; PicIcw[0] := 0; PicIcw[1] := 0; PicRead[0] := 0; PicRead[1] := 0;
  For K := 0 To 2 Do
  Begin
    PitReload[K] := 65536; PitAcc[K] := 3; PitMode[K] := 3; PitFlip[K] := 0; PitLatched[K] := 0; PitT0[K] := 0;
  End;
  PitStartMs := NowMs; PitTicksDone := 0; Port61 := 0;
  KbStat := $10; KbCmdByte := $45; KbCmd := 0; KbDevCmd := 0; KbRN := 0; KbQH := 0; KbQT := 0;
  A20 := 0; SetA20(1);
  IdeInit;
  Port92 := 0; FontLoad := 0; CmIdx := 0; AcFlip := 0;
  CmosInit;
  IrqWant := -1; IrqWantN := -1;
  SetMode(3);
  Message('OS/2-0 Virtualisation - BIOS 1.0');
  Message('');
  Fr_[fSET] := Fr_[fSET] Or 5;
  If Not Boot Then
  Begin
    Message(Fr('Aucun disque amor`cable : ins`erez une disquette, un CD-ROM ou ajoutez un disque dur.'));
    Fr_[fCS] := $F000; Fr_[fIP] := $FFF0; Fr_[fFL] := 2; Fr_[fSET] := Fr_[fSET] Or 1;
    VmHalted := 1;
  End;
End;

{ ==================================================================== }
{ Execution de l'invite                                                 }
{ ==================================================================== }

Var
  TraceOn : LongInt;
  SvcCnt : Array[0..255] Of LongInt;
  PortCnt : Array[0..1023] Of LongInt;
  VmExits, VmIoExits, VmHltExits, VmIrqs, VmSvc, VmStart, VmLastErr : LongInt;
  VmFailMsg : String;

Function MethodName(M : LongInt) : String;
Begin
  Case M Of
    VXM_SVM : MethodName := 'AMD-V (SVM)';
    VXM_VMX : MethodName := 'Intel VT-x (VMX)';
    VXM_V86 : MethodName := 'Mode virtuel 8086';
  Else
    MethodName := 'aucune';
  End;
End;

{ service d'un talon du BIOS (OUT 0EEh) : vecteur d'apres l'adresse }
Procedure Service(Next : LongInt);
Var N : LongInt;
Begin
  Inc(VmSvc);
  N := (Next - 3 - RomStub) Div 8;
  If (N >= 0) And (N < 256) Then Inc(SvcCnt[N]);
  Case N Of
    $10 : Int10;
    $11 : Set16(fAX, BdaW($10));
    $12 : Set16(fAX, BdaW($13));
    $13 : Int13;
    $14 : SetHi(fAX, $80);
    $15 : Int15;
    $16 : If Not Int16 Then
          Begin
            { pas de touche : l'invite reprend au debut du talon (STI)
              et la machine attend la prochaine interruption }
            Fr_[fIP] := Next - 3;
            VmIdleWait := 1;
            Exit;
          End;
    $17 : SetHi(fAX, $30);
    $18 : Begin
            Message(Fr('Aucun syst`eme d''exploitation : la machine est arr`et`ee.'));
            VmHalted := 1;
          End;
    $19 : Begin VmReqReset := 1; Exit; End;
    $1A : Int1A;
  End;
  Fr_[fIP] := Next;
End;

{ sortie d'E/S (EXITINFO1 de SVM : bit 0 lecture, 2 chaine, 3 REP,
  4/5/6 taille, 16-31 port) }
Procedure IoExit;
Var I1, P, Sz, V, N, K, Lin, Step : LongInt; InDir, Str_, Rep, A32 : Boolean;
Begin
  Inc(VmIoExits);
  I1 := Fr_[fINFO1];
  P := (I1 Shr 16) And $FFFF;
  InDir := (I1 And 1) <> 0; Str_ := (I1 And 4) <> 0; Rep := (I1 And 8) <> 0;
  If (I1 And 16) <> 0 Then Sz := 1 Else If (I1 And 32) <> 0 Then Sz := 2 Else Sz := 4;
  Inc(PortCnt[P And 1023]);
  If Str_ Then
  Begin
    { INS / OUTS : adresses de 16 bits (SI, DI, CX) ou de 32 bits (ESI,
      EDI, ECX : bit 8 des informations de la sortie, invite en mode
      protege 32 bits comme le pilote ATAPI d'OS2-Zero) }
    A32 := (I1 And $100) <> 0;
    If Rep Then
    Begin
      If A32 Then N := Fr_[fCX] Else N := GCX;
    End
    Else N := 1;
    If (Fr_[fFL] And $400) <> 0 Then Step := -Sz Else Step := Sz;
    For K := 1 To N Do
    Begin
      If InDir Then
      Begin
        Lin := SegLin(Fr_[fESB], Fr_[fDI]);
        If A32 Then Lin := Fr_[fESB] + Fr_[fDI];
        V := IoIn(P, Sz);
        If Sz = 1 Then LSB(Lin, V) Else If Sz = 2 Then LSW(Lin, V)
        Else Begin LSW(Lin, V); LSW(Lin + 2, V Shr 16); End;
        If A32 Then Fr_[fDI] := Fr_[fDI] + Step Else Set16(fDI, Fr_[fDI] + Step);
      End
      Else
      Begin
        Lin := SegLin(Fr_[fDSB], Fr_[fSI]);
        If A32 Then Lin := Fr_[fDSB] + Fr_[fSI];
        If Sz = 1 Then V := LB(Lin) Else If Sz = 2 Then V := LW(Lin) Else V := LL(Lin);
        IoOut(P, Sz, V);
        If A32 Then Fr_[fSI] := Fr_[fSI] + Step Else Set16(fSI, Fr_[fSI] + Step);
      End;
    End;
    If Rep Then
    Begin
      If A32 Then Fr_[fCX] := 0 Else Set16(fCX, 0);
    End;
    Fr_[fIP] := Fr_[fNEXT];
    Exit;
  End;
  If InDir Then
  Begin
    V := IoIn(P, Sz);
    If Sz = 1 Then SetLo(fAX, V) Else If Sz = 2 Then Set16(fAX, V) Else Fr_[fAX] := V;
    Fr_[fIP] := Fr_[fNEXT];
    Exit;
  End;
  V := Fr_[fAX];
  If Sz = 1 Then V := V And 255 Else If Sz = 2 Then V := V And $FFFF;
  Case P Of
    $EE : Begin Service(Fr_[fNEXT]); Exit; End;
    $EF : Begin KbdService(V And 255); Fr_[fIP] := Fr_[fNEXT]; Exit; End;
    $ED : Begin
            Fr_[fIP] := Fr_[fNEXT];
            Post;
            Exit;
          End;
  End;
  IoOut(P, Sz, V);
  Fr_[fIP] := Fr_[fNEXT];
End;

{ remise a zero (Ctrl+Alt+Suppr, triple faute, 8042 FEh) }
Procedure VmReset;
Var K : LongInt;
Begin
  For K := 0 To 39 Do Fr_[K] := 0;
  Fr_[fIRQ] := -1;
  Fr_[fSET] := 5;
  VmHalted := 0; VmIdleWait := 0; VmReqReset := 0;
  Post;
  PlSync;
End;

{ codes de touche de l'hote -> file du 8042 }
Procedure SendCad;
Begin
  KbKey($1D); KbKey($38); KbKey($E0); KbKey($53);
  KbKey($E0); KbKey($D3); KbKey($B8); KbKey($9D);
End;

Function ScanFromChar(Ch : LongInt; Var Shift : Boolean) : LongInt;
Var K : LongInt;
Begin
  ScanFromChar := 0; Shift := False;
  For K := 2 To 58 Do
  Begin
    If Ord(KNorm[K]) = Ch Then Begin ScanFromChar := K - 1; Exit; End;
    If Ord(KShift[K]) = Ch Then Begin ScanFromChar := K - 1; Shift := True; Exit; End;
  End;
End;

{ texte tape au clavier de l'invite (| : Entree, # : F5) }
Procedure TypeText(S : String);
Var K, Sc : LongInt; Sh : Boolean;
Begin
  For K := 1 To Length(S) Do
  Begin
    If (S[K] = '|') Or (S[K] = '^') Then Begin KbKey($1C); KbKey($9C); End
    Else If S[K] = '#' Then Begin KbKey($3F); KbKey($BF); End
    Else
    Begin
      Sc := ScanFromChar(Ord(S[K]), Sh);
      If Sc <> 0 Then
      Begin
        If Sh Then KbKey($2A);
        KbKey(Sc); KbKey(Sc Or $80);
        If Sh Then KbKey($AA);
      End;
    End;
  End;
End;

{ une tranche : interruptions, execution jusqu'a la sortie suivante }
{ fenetre VGA de l'invite : absente (KrnVirt 7) tant que le mode est
  planaire, chaque acces y sort et l'instruction est emulee (MmioEmu) }
Var
  PlTrap : Boolean;

Procedure PlSync;
Var T : Boolean;
Begin
  T := PlActive;
  If T <> PlTrap Then
  Begin
    PlTrap := T;
    If T Then Dummy := KrnVirt(7, 1, 0) Else Dummy := KrnVirt(7, 0, 0);
  End;
End;

{ sortie due a un acces a A0000h-AFFFFh (defaut de page en V86, NPF des
  tables imbriquees) : vrai si traitee }
Function VgaFault(R : LongInt) : Boolean;
Var A, K : LongInt; S : String;
Begin
  VgaFault := False;
  A := -1;
  If R = VXE_NPF Then A := Fr_[fINFO2]
  Else If (R = VXE_EXC) And (VmMethod = VXM_V86) And (Fr_[fINFO1] = 14) Then A := Fr_[fINFO2];
  If (A < $A0000) Or (A >= $B0000) Then Exit;
  VgaFault := True;
  If Not PlActive Then
  Begin
    { fenetre restee absente : la remettre et reprendre l'instruction }
    PlTrap := True;
    PlSync;
    Exit;
  End;
  MmioDef32 := (VmMethod <> VXM_V86) And ((Fr_[fCR0] And 1) <> 0) And ((Fr_[fFL] And $20000) = 0) And
               ((Fr_[fCSA] And 1) <> 0);
  If MmioEmu Then Exit;
  S := '';
  For K := 0 To 7 Do S := S + ' ' + Hex(LB(Fr_[fCSB] + Fr_[fIP] + K), 2);
  VmFailMsg := Fr('Instruction VGA non `emul`ee en ') + Hex(Fr_[fCS], 4) + ':' + Hex(Fr_[fIP], 8) + ' :' + S;
  VmHalted := 1;
  VmMsg := VmFailMsg;
End;

{ support change par le menu Peripheriques (dans la tache de la machine,
  entre deux sorties) }
Procedure MedChange;
Var R : LongInt;
Begin
  R := MedReq;
  MedReq := 0;
  Case R Of
    1 : Begin
          If CdOpen(MedPath) Then VmMsg := Fr('CD-ROM ins`er`e : ') + NameOf(MedPath)
          Else VmMsg := Fr('CD-ROM : ') + DkErr;
          IdeUA := 1;
        End;
    2 : Begin
          DkClose(DkCd);
          IdeUA := 1;
          VmMsg := Fr('CD-ROM `eject`e.');
        End;
    3 : Begin
          If DkOpen(2, MedPath) Then VmMsg := Fr('Disquette ins`er`ee : ') + NameOf(MedPath)
          Else VmMsg := Fr('Disquette : ') + DkErr;
          FdChanged := 1;
          BdaSW($10, BdaW($10) Or 1);
        End;
    4 : Begin
          DkClose(2);
          FdChanged := 1;
          VmMsg := Fr('Disquette `eject`ee.');
        End;
  End;
  MedMsgUntil := NowMs + 5000;
End;

Procedure VmStep;
Var R, N, V, IrqN : LongInt;
Begin
  If MedReq <> 0 Then MedChange;
  If VmReqReset <> 0 Then VmReset;
  If VmReqCad <> 0 Then
  Begin
    VmReqCad := 0;
    SendCad;
  End;
  { minuterie et clavier }
  N := PitDue;
  If N > 0 Then
  Begin
    PitTicksDone := PitTicksDone + 1;
    Irq(0);
  End;
  KbFill;
  { interruption a livrer }
  If IrqWant < 0 Then
  Begin
    V := PicVector(IrqN);
    If V >= 0 Then
    Begin
      IrqWant := V; IrqWantN := IrqN;
      Fr_[fIRQ] := V;
    End;
  End;
  If (VmHalted <> 0) Or ((VmIdleWait <> 0) And (IrqWant < 0)) Then
  Begin
    Dummy := DosSleep(5);
    Exit;
  End;
  VmIdleWait := 0;
  If TraceOn <> 0 Then
    Log('> ' + Hex(Fr_[fCS], 4) + ':' + Hex(Fr_[fIP], 4) + ' ' + Hex(Fr_[fSS], 4) + ':' + Hex(Fr_[fSP], 4) + ' ' +
        Hex(Fr_[fFL], 5) + ' i' + IStr(Fr_[fIRQ]));
  R := KrnVirt(VX_RUN, LongInt(@Fr_), 0);
  Inc(VmExits);
  If TraceOn <> 0 Then
    Log('< ' + IStr(R) + ' ' + Hex(Fr_[fCS], 4) + ':' + Hex(Fr_[fIP], 4) + ' ' + Hex(Fr_[fSS], 4) + ':' +
        Hex(Fr_[fSP], 4) + ' ' + Hex(Fr_[fFL], 5) + ' ' + Hex(Fr_[fINFO1], 8) + ' i' + IStr(Fr_[fIRQ]));
  If (IrqWant >= 0) And (Fr_[fIRQ] < 0) Then
  Begin
    PicAck(IrqWantN);
    Inc(VmIrqs);
    IrqWant := -1; IrqWantN := -1;
  End;
  Case R Of
    VXE_IO : Begin
               IoExit;
               PlSync;
             End;
    VXE_HLT : Begin
                Inc(VmHltExits);
                Fr_[fIP] := Fr_[fNEXT];
                If (Fr_[fFL] And $200) = 0 Then
                Begin
                  VmHalted := 1;
                  VmMsg := Fr('L''invite est arr`et`ee (HLT, interruptions masqu`ees).');
                End
                Else If IrqWant < 0 Then VmIdleWait := 1;
              End;
    VXE_INTR : ;
    VXE_SHUT : Begin
                 VmMsg := Fr('Triple faute de l''invite : remise `a z`ero.');
                 VmReqReset := 1;
               End;
  Else
    If VgaFault(R) Then
    Begin
      PlSync;
      Exit;
    End;
    VmLastErr := R;
    If (R = VXE_EXC) And (VmMethod = VXM_V86) And ((Fr_[fINFO1] = 13) Or (Fr_[fINFO1] = 6)) And
       (LB(Fr_[fCSB] + Fr_[fIP]) = $0F) And (LB(Fr_[fCSB] + Fr_[fIP] + 1) In [1, $20, $22]) Then
    Begin
      { LGDT, LIDT, LMSW, MOV CR0 : l'invite veut le mode protege }
      VmHalted := 1;
      VmMsg := Fr('Ce syst`eme passe en mode prot`eg`e : il exige AMD-V ou VT-x (le mode V86 ne fait que le mode r`eel).');
      VmFailMsg := VmMsg;
      Exit;
    End;
    If (R = VXE_EXC) And (VmMethod = VXM_V86) And (Fr_[fINFO1] = 14) And (Fr_[fINFO2] >= $100000) And
       (Fr_[fINFO2] < $110000) Then
    Begin
      VmHalted := 1;
      VmMsg := Fr('M`emoire au-dessus de 1 Mo (HMA, chargeur en mode prot`eg`e) inaccessible en mode V86 : ce syst`eme exige AMD-V ou VT-x.');
      VmFailMsg := VmMsg;
      Exit;
    End;
    VmFailMsg := Fr('Sortie de l''invite non prise en charge (code ') + IStr(R) + ', ' + Hex(Fr_[fRAW], 8) +
                 ', info ' + Hex(Fr_[fINFO1], 8) + ' ' + Hex(Fr_[fINFO2], 8) + ') ' + Hex(Fr_[fCS], 4) + ':' +
                 Hex(Fr_[fIP], 8);
    VmHalted := 1;
    VmMsg := VmFailMsg;
  End;
End;

{ polices de l'hote : 8 x 16 du VGA, 8 x 8 derivee }
Procedure LoadFonts;
Var P, K, R : LongInt; Inf : Array[0..15] Of Byte;
Begin
  For K := 0 To 4095 Do Font16[K] := 0;
  If KrnVirt(VX_FONT, LongInt(@Font16), 0) = 0 Then
  Begin
    For K := 0 To 15 Do Inf[K] := 0;
    WrW(LongInt(@Inf), 14); WrW(LongInt(@Inf) + 2, 1);
    If VioGetFont(LongInt(@Inf), 0) = 0 Then
    Begin
      P := RdL(LongInt(@Inf) + 8);
      If P <> 0 Then For K := 0 To 4095 Do Font16[K] := RdB(P + K);
    End;
  End;
  For K := 0 To 255 Do
    For R := 0 To 7 Do Font8[K * 8 + R] := Font16[K * 16 + R * 2] Or Font16[K * 16 + R * 2 + 1];
End;

{ ouvrir les disques et creer la machine du noyau }
Function VmOpen(I : LongInt; Var Err : String) : Boolean;
Var K : LongInt;
Begin
  VmOpen := False;
  Err := '';
  DkCloseAll;
  CurVm := I;
  If Vms[I].Hd0 <> '' Then
    If Not DkOpen(0, Vms[I].Hd0) Then
    Begin
      Err := DkErr;
      Exit;
    End;
  If Vms[I].Hd1 <> '' Then If DkOpen(1, Vms[I].Hd1) Then ;
  If Vms[I].Fd <> '' Then If DkOpen(2, Vms[I].Fd) Then ;
  If Vms[I].Cd <> '' Then
    If Not CdOpen(Vms[I].Cd) Then
    Begin
      Err := Fr('CD-ROM : ') + DkErr;
      DkCloseAll;
      Exit;
    End;
  GSize := Vms[I].MemMb * 1024 * 1024;
  If GSize < $110000 Then GSize := $110000;
  GMem := KrnVirt(VX_CREATE, GSize, 0);
  If GMem = 0 Then
  Begin
    Err := Fr('Le noyau n''a pas pu cr`eer la machine (m`emoire ou processeur).');
    DkCloseAll;
    Exit;
  End;
  Dummy := KrnVirt(VX_INFO, LongInt(@Info), 0);
  VmMethod := Info[12];
  Dummy := KrnVirt(VX_CLEAR, 0, 0);
  VmExits := 0; VmIoExits := 0; VmHltExits := 0; VmIrqs := 0; VmSvc := 0; VmLastErr := 0;
  VmStart := NowMs;
  DbgLine := ''; DbgOut := ''; VmMsg := '';
  PlTrap := False;
  For K := 0 To 39 Do Fr_[K] := 0;
  Fr_[fIRQ] := -1;
  VmReqReset := 0; VmReqStop := 0; VmReqCad := 0; VmHalted := 0; VmIdleWait := 0; VmPowerOff := 0;
  MedReq := 0; FdChanged := 0; MedMsgUntil := 0;
  VmReset;
  VmOpen := True;
End;

Procedure VmClose;
Begin
  Dummy := KrnVirt(VX_DESTROY, 0, 0);
  DkCloseAll;
  GMem := 0;
End;

{ tache de la machine }
Function VmThread(P : LongInt) : LongInt;
Begin
  While VmReqStop = 0 Do
  Begin
    If VmState = VS_PAUSE Then Dummy := DosSleep(20)
    Else VmStep;
  End;
  VmState := VS_OFF;
  VmClose;
  If VmWin <> 0 Then Dummy := WinPostMsg(VmWin, WM_VMEND, 0, 0);
  VmThread := 0;
End;

{ ==================================================================== }
{ Ecran de l'invite                                                     }
{ ==================================================================== }

Var
  Fb : Array[0..SW_ * SH_ - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  ShadowSum, LastSum, BlinkOn, LastBlink, ScrH, DiskX : LongInt;
  Hps, CW, CH, StatH, MgrFrame, MgrClient, VmClient, InfoFrame, CfgFrame, CfgClient : LongInt;
  VmTitle, StatText : String;

Procedure InitBmi;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, SW_);
  WrL(LongInt(@Bmi) + 8, SH_);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
End;

Procedure DacToBmi;
Var K, A : LongInt;
Begin
  For K := 0 To 255 Do
  Begin
    A := LongInt(@Bmi) + 16 + K * 4;
    WrB(A, (Dac[K * 3 + 2] Shl 2) Or (Dac[K * 3 + 2] Shr 4));
    WrB(A + 1, (Dac[K * 3 + 1] Shl 2) Or (Dac[K * 3 + 1] Shr 4));
    WrB(A + 2, (Dac[K * 3] Shl 2) Or (Dac[K * 3] Shr 4));
  End;
End;

Procedure FbFill(C : LongInt);
Begin
  FillChar(Fb, SizeOf(Fb), C);
End;

{ point (X, Y) de l'ecran de l'invite (origine en haut a gauche) }
Procedure FbPix(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < SW_) And (Y >= 0) And (Y < SH_) Then Fb[(SH_ - 1 - Y) * SW_ + X] := C;
End;

{ texte de l'hote dans l'image (police 8 x 16) }
Procedure FbStr(X, Y : LongInt; S : String; C : LongInt);
Var I, R, B, K : LongInt;
Begin
  For I := 1 To Length(S) Do
    For R := 0 To 15 Do
    Begin
      B := Font16[Ord(S[I]) * 16 + R];
      For K := 0 To 7 Do If (B And ($80 Shr K)) <> 0 Then FbPix(X + (I - 1) * 8 + K, Y + R, C);
    End;
End;

Function AcColor(I : LongInt) : LongInt;
Begin
  AcColor := AcReg[I And 15] And $3F;
End;

Procedure RenderText;
Var Cols, Rows, Hgt, Start, R, C, A, Ch, At, Fg, Bg, Y, K, B, W, Line, Cur, CS, CE, X0, Blink, X : LongInt;
Begin
  Cols := BdaW($4A); Rows := BdaB($84) + 1; Hgt := BdaB($85);
  If (Cols <> 40) Then Cols := 80;
  If (Hgt < 8) Or (Hgt > 32) Then Hgt := 16;
  If Rows * Hgt > SH_ Then Rows := SH_ Div Hgt;
  Start := ((CrReg[$0C] Shl 8) Or CrReg[$0D]) * 2;
  Cur := ((CrReg[$0E] Shl 8) Or CrReg[$0F]) * 2 - Start;
  CS := CrReg[$0A] And 31; CE := CrReg[$0B] And 31;
  Blink := AcReg[$10] And 8;
  If Cols = 40 Then W := 2 Else W := 1;
  For R := 0 To Rows - 1 Do
    For C := 0 To Cols - 1 Do
    Begin
      A := $B8000 + Start + (R * Cols + C) * 2;
      Ch := GB(A); At := GB(A + 1);
      Fg := AcColor(At And 15);
      If Blink <> 0 Then
      Begin
        Bg := AcColor((At Shr 4) And 7);
        If ((At And $80) <> 0) And (BlinkOn = 0) Then Fg := Bg;
      End
      Else Bg := AcColor(At Shr 4);
      X0 := C * 8 * W;
      For Line := 0 To Hgt - 1 Do
      Begin
        Y := R * Hgt + Line;
        B := VgaFont[Ch * 32 + Line];
        If (Cur = (R * Cols + C) * 2) And (BlinkOn <> 0) And ((CrReg[$0A] And $20) = 0) Then
          If (Line >= CS) And (Line <= CE) Then B := $FF;
        K := (SH_ - 1 - Y) * SW_ + X0;
        If W = 1 Then
        Begin
          If (B And $80) <> 0 Then Fb[K] := Fg Else Fb[K] := Bg;
          If (B And $40) <> 0 Then Fb[K + 1] := Fg Else Fb[K + 1] := Bg;
          If (B And $20) <> 0 Then Fb[K + 2] := Fg Else Fb[K + 2] := Bg;
          If (B And $10) <> 0 Then Fb[K + 3] := Fg Else Fb[K + 3] := Bg;
          If (B And $08) <> 0 Then Fb[K + 4] := Fg Else Fb[K + 4] := Bg;
          If (B And $04) <> 0 Then Fb[K + 5] := Fg Else Fb[K + 5] := Bg;
          If (B And $02) <> 0 Then Fb[K + 6] := Fg Else Fb[K + 6] := Bg;
          If (B And $01) <> 0 Then Fb[K + 7] := Fg Else Fb[K + 7] := Bg;
        End
        Else
          For X := 0 To 7 Do
            If (B And ($80 Shr X)) <> 0 Then
            Begin
              Fb[K + X * 2] := Fg; Fb[K + X * 2 + 1] := Fg;
            End
            Else
            Begin
              Fb[K + X * 2] := Bg; Fb[K + X * 2 + 1] := Bg;
            End;
      End;
    End;
  { lignes restantes }
  For Y := Rows * Hgt To SH_ - 1 Do
    For K := 0 To SW_ - 1 Do Fb[(SH_ - 1 - Y) * SW_ + K] := 0;
End;

Procedure Render13;
Var X, Y, V, K, A : LongInt;
Begin
  For Y := 0 To 199 Do
  Begin
    A := GMem + $A0000 + Y * 320;
    K := (SH_ - 1 - Y * 2) * SW_;
    For X := 0 To 319 Do
    Begin
      V := RdB(A + X);
      Fb[K + X * 2] := V; Fb[K + X * 2 + 1] := V;
      Fb[K - SW_ + X * 2] := V; Fb[K - SW_ + X * 2 + 1] := V;
    End;
  End;
End;

Procedure RenderCga;
Var X, Y, V, M, C, K : LongInt;
Begin
  M := BdaB($49);
  For Y := 0 To 199 Do
  Begin
    K := (SH_ - 1 - Y * 2) * SW_;
    For X := 0 To 639 Do
    Begin
      If M = 6 Then
      Begin
        V := (GB($B8000 + (Y And 1) * $2000 + (Y Div 2) * 80 + X Div 8) Shr (7 - X Mod 8)) And 1;
        If V <> 0 Then C := AcColor(15) Else C := AcColor(0);
      End
      Else
      Begin
        V := (GB($B8000 + (Y And 1) * $2000 + (Y Div 2) * 80 + (X Div 2) Div 4) Shr (6 - ((X Div 2) Mod 4) * 2)) And 3;
        C := AcColor(V);
      End;
      Fb[K + X] := C;
      Fb[K - SW_ + X] := C;
    End;
  End;
End;

{ signature de l'ecran (pour ne recopier que s'il change) }
Function ScreenSum : LongInt;
Var S, K, M, N, A : LongInt;
Begin
  If PlActive Then
  Begin
    ScreenSum := (PlSum + VmHalted * 3) And $7FFFFFFF;
    Exit;
  End;
  M := BdaB($49);
  S := M * 7 + BlinkOn * 13 + CrReg[$0E] * 31 + CrReg[$0F] * 37 + CrReg[$0C] * 41 + CrReg[$0D] + VmHalted * 3;
  If M = $13 Then Begin A := $A0000; N := 64000; End
  Else If (M >= 4) And (M <= 6) Then Begin A := $B8000; N := 16384; End
  Else Begin A := $B8000 + ((CrReg[$0C] Shl 8) Or CrReg[$0D]) * 2; N := 8000; End;
  K := 0;
  While K < N Do
  Begin
    S := (S * 31 + RdL(GMem + A + K)) And $7FFFFFFF;
    K := K + 4;
  End;
  For K := 0 To 47 Do S := (S * 7 + Dac[K] + AcReg[K And 15]) And $7FFFFFFF;
  For K := 0 To 63 Do S := (S * 3 + VgaFont[65 * 32 + K]) And $7FFFFFFF;
  ScreenSum := S;
End;

Procedure RenderScreen;
Var M : LongInt;
Begin
  If GMem = 0 Then
  Begin
    FbFill(0);
    Exit;
  End;
  DacToBmi;
  M := BdaB($49);
  If PlActive Then
  Begin
    PlFb := LongInt(@Fb);
    PlRender;
  End
  Else If M = $13 Then Render13
  Else If (M >= 4) And (M <= 6) Then RenderCga
  Else If (M <= 3) Or (M = 7) Then RenderText
  Else
  Begin
    FbFill(0);
    WrB(LongInt(@Bmi) + 16 + 15 * 4, $FF); WrB(LongInt(@Bmi) + 16 + 15 * 4 + 1, $FF);
    WrB(LongInt(@Bmi) + 16 + 15 * 4 + 2, $FF);
    FbStr(120, 192, Fr('Mode graphique ') + Hex(M, 2) + Fr('h (plans du VGA) : non affich`e'), 15);
  End;
End;

{ hauteur montree : celle de l'affichage du CRTC en mode planaire (350 ou
  480 lignes), sinon 400 }
Function DispH : LongInt;
Var V : LongInt;
Begin
  DispH := 400;
  If (GMem = 0) Or Not PlActive Then Exit;
  V := CrReg[$12] Or ((CrReg[7] And 2) Shl 7) Or ((CrReg[7] And $40) Shl 3);
  If V >= 440 Then DispH := 480 Else If (V >= 340) And (V < 360) Then DispH := 350;
End;

Procedure BlitScreen(H : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  { les ScrH lignes du haut de l'image (rangee de bas en haut) }
  P[0] := 0; P[1] := CH - ScrH; P[2] := SW_; P[3] := CH;
  P[4] := 0; P[5] := SH_ - ScrH; P[6] := SW_; P[7] := SH_;
  Dummy := GpiDrawBits(H, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

{ ---- dessin de PM (couleurs RVB) ---- }

Procedure FBar(X1, Y1, X2, Y2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  Rc[0] := X1; Rc[1] := CH - 1 - Y2; Rc[2] := X2 + 1; Rc[3] := CH - Y1;
  Dummy := WinFillRect(Hps, LongInt(@Rc), C);
End;

Procedure Edge(X1, Y1, X2, Y2, Lt, Dk : LongInt);
Begin
  FBar(X1, Y1, X2, Y1, Lt); FBar(X1, Y1, X1, Y2, Lt);
  FBar(X1, Y2, X2, Y2, Dk); FBar(X2, Y1, X2, Y2, Dk);
End;

Procedure OutTxt(X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := CH - Y - 16; Rc[2] := X + Length(S) * 8; Rc[3] := CH - Y;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

Procedure RgbMode;
Begin
  Dummy := GpiCreateLogColorTable(Hps, 0, 3, 0, 0, 0);
End;

{ icones des supports a droite de la barre d'etat, comme VirtualBox :
  disque dur, CD-ROM (gris s'il est vide), disquette ; un clic ouvre le
  menu des supports }
Procedure DrawDevs;
Var X, Y : LongInt;
Begin
  Y := ScrH + 3;
  { disque dur : boitier gris fonce, temoin vert }
  X := CW - 88;
  FBar(X, Y + 3, X + 21, Y + 13, $303030); FBar(X + 1, Y + 4, X + 20, Y + 12, $8C8C8C);
  FBar(X + 1, Y + 4, X + 20, Y + 5, $B4B4B4);
  FBar(X + 3, Y + 9, X + 12, Y + 10, $303030);
  If DkReads[0] + DkWrites[0] > 0 Then FBar(X + 16, Y + 9, X + 18, Y + 10, $00E000)
  Else FBar(X + 16, Y + 9, X + 18, Y + 10, $005000);
  { CD-ROM : disque argente cercle de gris fonce (contour seul s'il est vide) }
  X := CW - 60;
  If DkH[DkCd] >= 0 Then
  Begin
    FBar(X + 5, Y, X + 14, Y + 15, $404050); FBar(X + 2, Y + 3, X + 17, Y + 12, $404050);
    FBar(X + 6, Y + 1, X + 13, Y + 14, $B8B8D0); FBar(X + 3, Y + 4, X + 16, Y + 11, $B8B8D0);
    FBar(X + 7, Y + 3, X + 12, Y + 6, $E8E8FF);
    FBar(X + 8, Y + 6, X + 11, Y + 9, $FFFFFF); FBar(X + 9, Y + 7, X + 10, Y + 8, $404050);
  End
  Else
  Begin
    FBar(X + 5, Y, X + 14, Y + 15, $606060); FBar(X + 2, Y + 3, X + 17, Y + 12, $606060);
    FBar(X + 6, Y + 1, X + 13, Y + 14, $CCCCCC); FBar(X + 3, Y + 4, X + 16, Y + 11, $CCCCCC);
    FBar(X + 9, Y + 7, X + 10, Y + 8, $606060);
  End;
  { disquette : bleu fonce, volet metallique, etiquette (contour seul si vide) }
  X := CW - 32;
  If DkH[2] >= 0 Then
  Begin
    FBar(X + 2, Y + 1, X + 17, Y + 15, $283C78); FBar(X + 5, Y + 1, X + 13, Y + 6, $C8C8C8);
    FBar(X + 10, Y + 2, X + 11, Y + 5, $283C78); FBar(X + 4, Y + 9, X + 15, Y + 15, $F4F4F4);
  End
  Else
  Begin
    FBar(X + 2, Y + 1, X + 17, Y + 15, $606060); FBar(X + 3, Y + 2, X + 16, Y + 14, $CCCCCC);
    FBar(X + 5, Y + 2, X + 13, Y + 6, $909090);
  End;
End;

{ barre d'etat de la fenetre de la machine }
Procedure DrawStatus;
Var S : String; Dt : LongInt;
Begin
  FBar(0, ScrH, CW - 1, CH - 1, $CCCCCC);
  Edge(0, ScrH, CW - 1, CH - 1, $FFFFFF, $808080);
  Dt := (NowMs - VmStart) Div 1000;
  S := ' ' + MethodName(VmMethod) + '  |  ' + IStr(VmExits) + ' sorties  |  disque ' + IStr(DkReads[0]) + 'L/' +
       IStr(DkWrites[0]) + 'E';
  If VmState = VS_PAUSE Then S := S + '  |  ' + Fr('En pause');
  If VmMsg <> '' Then S := ' ' + VmMsg;
  { debut de la partie disque (clic : menu des supports) }
  If Pos('disque', S) > 0 Then DiskX := 4 + (Pos('disque', S) - 1) * 8 Else DiskX := CW - 96;
  If DiskX > CW - 96 Then DiskX := CW - 96;
  OutTxt(4, ScrH + 3, Copy(S, 1, (CW - 108) Div 8), $101010, $CCCCCC);
  DrawDevs;
End;

{ ==================================================================== }
{ Menus (gabarits de PM)                                                }
{ ==================================================================== }

Var
  MenuT : Array[0..2047] Of Byte;
  MenuLen : LongInt;
  CurSel, ListBox, BtnNew, BtnSet, BtnDel, BtnStart, BtnInfo : LongInt;
  CfgEdit : LongInt;                  { machine modifiee (-1 : nouvelle) }
  StartKeys : String;
  CName, CType, CMem, CHd, CHd2, CFd, CNew, CSize, CBootFd, CCd, CBootCd : LongInt;
  { choix d'une image et menu des supports de la fenetre de la machine }
  PickFrame, PickClient, PickKind, PickN, PickList, PickPath : LongInt;
  PopMenu, PopUntil : LongInt;      { PopUntil : menu ouvert, pas de dessin par-dessus }

Procedure FillList; Forward;

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
  S := Fr(S);
  MW(Style); MW(Attr); MW(Id);
  If (Style And MIS_SEPARATOR) = 0 Then
  Begin
    For K := 1 To Length(S) Do MB(Ord(S[K]));
    MB(0);
  End;
End;

Function Ask(Text, Cap : String; Fl, Owner : LongInt) : LongInt;
Begin
  Inc(InDlg);
  Ask := WinMessageBox(HWND_DESKTOP, Owner, Z(Fr(Text)), Z2(Fr(Cap)), 0, Fl Or MB_MOVEABLE);
  Dec(InDlg);
End;

Function LMsgBox(Cap : String; Fl, Owner : LongInt) : LongInt;
Begin
  Inc(InDlg);
  LMsgBox := WinMessageBox(HWND_DESKTOP, Owner, LongInt(@LBuf), Z2(Fr(Cap)), 0, Fl Or MB_MOVEABLE);
  Dec(InDlg);
End;

Function Ctl(P, Cls : LongInt; T : String; Style, X, Y, W, H, Id : LongInt) : LongInt;
Begin
  { coordonnees de PM (origine en bas a gauche) : Y depuis le haut }
  Ctl := WinCreateWindow(P, Cls, Z(Fr(T)), WS_VISIBLE Or Style, X, CH - Y - H, W, H, P, HWND_TOP, Id, 0, 0);
End;

Procedure Gray(H : LongInt);
Var C : LongInt;
Begin
  C := 15;
  Dummy := WinSetPresParam(H, 4, 4, LongInt(@C));
End;

Function CtlText(H : LongInt) : String;
Begin
  ZeroB(LongInt(@TxtBuf), 260);
  Dummy := WinQueryWindowText(H, 255, LongInt(@TxtBuf));
  CtlText := TrimS(GetZ(LongInt(@TxtBuf)));
End;

Procedure SetText(H : LongInt; S : String);
Begin
  Dummy := WinSetWindowText(H, Z(S));
End;

Procedure CenterFrame(F, W, H : LongInt);
Var Rc : Array[0..3] Of LongInt; Fw, Fh, Sw, Sh, X, Y : LongInt;
Begin
  Rc[0] := 0; Rc[1] := 0; Rc[2] := W; Rc[3] := H;
  Dummy := WinCalcFrameRect(F, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (Sw - Fw) Div 2; Y := (Sh - Fh) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := 0;
  Dummy := WinSetWindowPos(F, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
End;

{ ==================================================================== }
{ Information de virtualisation                                         }
{ ==================================================================== }

Var
  InfoL : Array[0..63] Of String[95];
  InfoN : LongInt;

Procedure IAdd(S : String);
Begin
  If InfoN < 64 Then
  Begin
    InfoL[InfoN] := Copy(Fr(S), 1, 95);
    Inc(InfoN);
  End;
End;

Function YesNo(B : Boolean) : String;
Begin
  If B Then YesNo := 'oui' Else YesNo := 'non';
End;

Function Bit(V, N : LongInt) : Boolean;
Begin
  Bit := ((V Shr N) And 1) <> 0;
End;

Procedure BuildInfo;
Var Best, Fl, Fam, Mdl, Stp, M, K : LongInt; W, S : String;
Begin
  FillChar(Info, SizeOf(Info), 0);
  Best := KrnVirt(VX_INFO, LongInt(@Info), 0);
  Fl := Info[2];
  M := Info[12];
  If M = 0 Then M := Best;
  W := GetZ(LongInt(@Info) + 257);
  InfoN := 0;
  IAdd('#M`ethode de virtualisation');
  Case M Of
    VXM_SVM : IAdd('M`ethode utilis`ee|AMD-V (SVM) avec tables de pages imbriqu`ees (NPT)');
    VXM_VMX : IAdd('M`ethode utilis`ee|Intel VT-x (VMX) avec EPT et invit`e sans restriction');
  Else
    IAdd('M`ethode utilis`ee|Mode virtuel 8086 du 80386 (plan B)');
  End;
  IAdd('Ex`ecution|directe sur le processeur (virtualisation, pas d''`emulation)');
  If (M = VXM_V86) And (W <> '') Then IAdd('Mat`eriel absent|' + W);
  If M = VXM_V86 Then IAdd('Limites|invit`e en mode r`eel seulement (ni mode prot`eg`e ni HMA)')
  Else IAdd('Invit`e|mode r`eel, prot`eg`e, pagin`e et V86 (EMM386, Windows 3.1)');
  IAdd('#Processeur de l''h`ote');
  IAdd('Fabricant|' + GetZ(LongInt(@Info) + 161));
  S := GetZ(LongInt(@Info) + 193);
  If S <> '' Then IAdd('Mod`ele|' + S);
  Fam := (Info[7] Shr 8) And 15; Mdl := (Info[7] Shr 4) And 15; Stp := Info[7] And 15;
  If Fam = 15 Then Fam := Fam + ((Info[7] Shr 20) And 255);
  If Fam >= 6 Then Mdl := Mdl + ((Info[7] Shr 12) And $F0);
  If Info[1] <> 0 Then
    IAdd('Famille, mod`ele, r`evision|' + IStr(Fam) + ', ' + IStr(Mdl) + ', ' + IStr(Stp) + '  (CPUID 1 : ' +
         Hex(Info[7], 8) + ')')
  Else IAdd('CPUID|absent (80386 ou premier 80486)');
  If Bit(Fl, 0) Then
  Begin
    S := 'pr`esent, r`evision SVM ' + IStr(Info[3]) + ', ' + IStr(Info[4]) + ' ASID';
    If Bit(Fl, 1) Then S := S + ', d`esactiv`e par le BIOS';
    IAdd('AMD-V (SVM)|' + S);
    IAdd('Fonctions SVM|NPT : ' + YesNo(Bit(Fl, 2)) + ', NRIP : ' + YesNo(Bit(Fl, 3)) + ', verrou SVML : ' +
         YesNo(Bit(Fl, 9)));
  End
  Else IAdd('AMD-V (SVM)|absent');
  If Bit(Fl, 4) Then
  Begin
    S := 'pr`esent, r`evision VMCS ' + Hex(Info[5] And $7FFFFFFF, 8);
    If Bit(Fl, 5) Then S := S + ', d`esactiv`e par le BIOS';
    IAdd('Intel VT-x (VMX)|' + S);
    S := 'EPT : ' + YesNo(Bit(Fl, 6)) + ', invit`e sans restriction : ' + YesNo(Bit(Fl, 7)) + ', VPID : ' +
         YesNo(Bit(Fl, 8));
    If Bit(Fl, 6) Then
    Begin
      If Bit(Info[38], 14) Then S := S + ', EPT WB' Else S := S + ', EPT UC';
    End;
    IAdd('Fonctions VMX|' + S);
  End
  Else IAdd('Intel VT-x (VMX)|absent');
  IAdd('Mode V86|disponible (80386 et suivants)');
  IAdd('#Machine virtuelle');
  If (Info[12] <> 0) And (CurVm >= 0) Then
  Begin
    IAdd('Machine|' + Vms[CurVm].Name);
    IAdd('M`emoire de l''invite|' + IStr(Info[14] Div 1048576) + ' Mo `a l''adresse physique ' + Hex(Info[13], 8) + 'h');
    Case M Of
      VXM_SVM :
        Begin
          IAdd('VMCB|' + Hex(Info[15], 8) + 'h (zone de l''h`ote ' + Hex(Info[36], 8) + 'h, ASID 1)');
          IAdd('Tables NPT|r`epertoire ' + Hex(Info[16], 8) + 'h (2 niveaux, pages de 4 Ko)');
          IAdd('IOPM, MSRPM|' + Hex(Info[34], 8) + 'h, ' + Hex(Info[35], 8) + 'h (tout intercept`e)');
          IAdd('Interceptions|INTR, NMI, CPUID, INVD, HLT, E/S, MSR, arr`et, VMRUN...SKINIT');
          IAdd('Injection|EVENTINJ, fen`etre VINTR (V_IRQ)');
        End;
      VXM_VMX :
        Begin
          IAdd('VMCS|' + Hex(Info[15], 8) + 'h (r`egion VMXON ' + Hex(Info[36], 8) + 'h)');
          IAdd('Tables EPT|PDPT ' + Hex(Info[16], 8) + 'h (4 niveaux, pages de 4 Ko)');
          IAdd('Interceptions|interruptions externes, NMI, HLT, E/S, MSR, CPUID, MOV CR');
          IAdd('Injection|champ d''entr`ee, fen`etre d''interruption');
        End;
    Else
      IAdd('Table de pages|' + Hex(Info[16], 8) + 'h (premier Mo de l''invite)');
      IAdd('Interceptions|faute de protection : IN, OUT, INT, IRET, PUSHF, POPF, CLI, STI, HLT');
      IAdd('Injection|IF virtuel, retour forc`e par la minuterie (HLT en F000:FF00)');
    End;
    IAdd('Sorties de l''invite|' + IStr(Info[17]) + ' : E/S ' + IStr(Info[19]) + ', HLT ' + IStr(Info[20]) +
         ', interruptions ' + IStr(Info[21]) + ', CPUID ' + IStr(Info[27]) + ', MSR ' + IStr(Info[28]));
    IAdd('Services|' + IStr(VmSvc) + ' appels du BIOS, ' + IStr(VmIrqs) + ' interruptions inject`ees');
    IAdd('Disque 0|' + DkFmt[0] + ', ' + IStr(DkSect[0] Div 2048) + ' Mo, CHS ' + IStr(DkCyl[0]) + '/' +
         IStr(DkHeads[0]) + '/' + IStr(DkSpt[0]) + ', ' + IStr(DkReads[0]) + ' lectures, ' + IStr(DkWrites[0]) +
         ' `ecritures');
  End
  Else IAdd('Machine|aucune en fonction');
End;

Procedure InfoPaint(H : LongInt);
Var Rc : Array[0..3] Of LongInt; K, Y, P : LongInt; S : String;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  CW := Rc[2]; CH := Rc[3];
  RgbMode;
  FBar(0, 0, CW - 1, CH - 1, $CCCCCC);
  Y := 8;
  For K := 0 To InfoN - 1 Do
  Begin
    S := InfoL[K];
    If (S <> '') And (S[1] = '#') Then
    Begin
      If K > 0 Then Y := Y + 4;
      FBar(8, Y, CW - 9, Y + 17, $000080);
      OutTxt(14, Y + 1, Copy(S, 2, 90), $FFFFFF, $000080);
      Y := Y + 20;
    End
    Else
    Begin
      P := Pos('|', S);
      If P > 0 Then
      Begin
        OutTxt(16, Y, Copy(S, 1, P - 1), $000080, $CCCCCC);
        OutTxt(236, Y, Copy(S, P + 1, 80), $101010, $CCCCCC);
      End
      Else OutTxt(16, Y, S, $101010, $CCCCCC);
      Y := Y + 17;
    End;
  End;
  Dummy := WinEndPaint(Hps);
End;

Function InfoProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Begin
  InfoProc := 0;
  Case Msg0 Of
    WM_PAINT : InfoPaint(H);
    WM_COMMAND : Dummy := WinDestroyWindow(InfoFrame);
    WM_CLOSE : Dummy := WinDestroyWindow(InfoFrame);
    WM_DESTROY : Begin
                   InfoFrame := 0;
                   LastSum := -1;
                   If VmClient <> 0 Then Dummy := WinInvalidateRect(VmClient, 0, 0);
                 End;
  Else
    InfoProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
  End;
End;

Procedure ShowInfo;
Var Flg, C, H, K, Y : LongInt;
Begin
  BuildInfo;
  If InfoFrame <> 0 Then Dummy := WinDestroyWindow(InfoFrame);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER Or FCF_TASKLIST;
  C := 0;
  InfoFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('VBOXINFO'),
                                  Z2(Fr('Information de virtualisation')), 0, 0, 0, LongInt(@C));
  Y := 8;
  For K := 0 To InfoN - 1 Do
    If (InfoL[K] <> '') And (InfoL[K][1] = '#') Then Y := Y + 24 Else Y := Y + 17;
  H := Y + 50;
  CenterFrame(InfoFrame, 800, H);
  CH := H;
  Dummy := Ctl(C, WC_BUTTON, 'OK', BS_PUSHBUTTON Or BS_DEFAULT Or WS_TABSTOP, 800 Div 2 - 45, H - 38, 90, 28, ID_OK);
End;

{ ==================================================================== }
{ Fenetre de la machine                                                 }
{ ==================================================================== }

{ frappe de PM -> codes de balayage de l'invite (enfoncee puis relachee) }
Procedure VmKey(Mp1, Mp2 : LongInt);
Var Fl, Sc, Ch, Vk : LongInt; Ext, Sh : Boolean;
Begin
  Fl := Lo16(Mp1); Sc := (Mp1 Shr 24) And 255; Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then Exit;
  Ext := False; Sh := False;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
    Case Vk Of
      VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN, VK_PAGEUP, VK_PAGEDOWN, VK_END, VK_HOME, VK_INSERT, VK_DELETE :
        If (Fl And KC_CHAR) = 0 Then Ext := True;
    End;
  If Sc = 0 Then
  Begin
    Sc := ScanFromChar(Ch, Sh);
    If Sc = 0 Then Exit;
    If Sh Then Fl := Fl Or KC_SHIFT;
  End;
  If (Fl And KC_SHIFT) <> 0 Then KbKey($2A);
  If (Fl And KC_CTRL) <> 0 Then KbKey($1D);
  If (Fl And KC_ALT) <> 0 Then KbKey($38);
  If Ext Then KbKey($E0);
  KbKey(Sc);
  If Ext Then KbKey($E0);
  KbKey(Sc Or $80);
  If (Fl And KC_ALT) <> 0 Then KbKey($B8);
  If (Fl And KC_CTRL) <> 0 Then KbKey($9D);
  If (Fl And KC_SHIFT) <> 0 Then KbKey($AA);
End;

Procedure VmPaint(H : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  CW := Rc[2]; CH := Rc[3];
  RgbMode;
  DrawStatus;
  RenderScreen;
  BlitScreen(Hps);
  StatText := VmMsg;
  Dummy := WinEndPaint(Hps);
End;

Procedure VmTick(H : LongInt);
Var S : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  If (NowMs Div 400) And 1 = 1 Then BlinkOn := 1 Else BlinkOn := 0;
  { pas de dessin par-dessus les boites de l'application }
  If (GMem = 0) Or (InfoFrame <> 0) Or (InDlg <> 0) Or (PickFrame <> 0) Or (NowMs < PopUntil) Then Exit;
  If (MedMsgUntil <> 0) And (NowMs > MedMsgUntil) Then
  Begin
    MedMsgUntil := 0;
    VmMsg := '';
  End;
  S := DispH;
  If S <> ScrH Then
  Begin
    { l'invite change de hauteur d'ecran (350, 400, 480) : la fenetre suit }
    ScrH := S;
    CenterFrame(VmFrame, SW_, ScrH + 22);
    LastSum := -1;
  End;
  S := ScreenSum;
  If (S <> LastSum) Or (StatText <> VmMsg) Or ((NowMs Div 1000) <> LastBlink) Then
  Begin
    LastSum := S;
    LastBlink := NowMs Div 1000;
    Hps := WinGetPS(H);
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
    CW := Rc[2]; CH := Rc[3];
    RgbMode;
    DrawStatus;
    RenderScreen;
    BlitScreen(Hps);
    StatText := VmMsg;
    Dummy := WinReleasePS(Hps);
  End;
End;

{ ---- supports amovibles : menu Peripheriques, menu de la barre d'etat
  (clic sur la partie disque ou sur les icones), choix d'une image,
  informations sur les disques ---- }

Const
  MaxPick = 64;
  ID_PLIST = 40; ID_PPATH = 41;

Var
  PickF : Array[0..MaxPick - 1] Of String;

{ images trouvees (CD-ROM : .ISO ; disquette : .IMG, .IMA, .VFD) dans un
  dossier }
Procedure PickScan(Dir : String; Depth : LongInt);
Var Buf : Array[0..299] Of Byte; HD, Cnt, R, Attr : LongInt; N, E : String; Ok : Boolean;
Begin
  HD := -1; Cnt := 1;
  R := DosFindFirst(Z(Dir + '*.*'), LongInt(@HD), $37, LongInt(@Buf), SizeOf(Buf), LongInt(@Cnt), 1);
  While (R = 0) And (Cnt > 0) And (PickN < MaxPick) Do
  Begin
    N := FindName(LongInt(@Buf));
    Attr := RdL(LongInt(@Buf) + 24);
    If (N <> '.') And (N <> '..') Then
    Begin
      E := ExtOf(N);
      If (Attr And $10) <> 0 Then
      Begin
        If Depth < 1 Then PickScan(Dir + N + '\', Depth + 1);
      End
      Else
      Begin
        If PickKind = 1 Then Ok := E = 'ISO' Else Ok := (E = 'IMG') Or (E = 'IMA') Or (E = 'VFD');
        If Ok Then
        Begin
          PickF[PickN] := Dir + N;
          Inc(PickN);
        End;
      End;
    End;
    Cnt := 1;
    R := DosFindNext(HD, LongInt(@Buf), SizeOf(Buf), LongInt(@Cnt));
  End;
  If HD <> -1 Then Dummy := DosFindClose(HD);
End;

Procedure PickClose;
Begin
  If PickFrame <> 0 Then Dummy := WinDestroyWindow(PickFrame);
  PickFrame := 0;
  If VmFrame <> 0 Then Dummy := WinEnableWindow(VmFrame, 1);
End;

{ image choisie : changee par la tache de la machine, notee dans le .vbox }
Procedure PickOk;
Var P : String;
Begin
  P := CtlText(PickPath);
  If (P = '') Or Not FExists(P) Then
  Begin
    Dummy := Ask('Image introuvable : ' + P, 'Virtualisation', MB_OK Or MB_ICONWARNING, PickFrame);
    Exit;
  End;
  MedPath := P;
  MedReq := PickKind;
  If (CurVm >= 0) And (CurVm < NVm) Then
  Begin
    If PickKind = 1 Then Vms[CurVm].Cd := P Else Vms[CurVm].Fd := P;
    If Vms[CurVm].Vbox <> '' Then Dummy := VmSave(Vms[CurVm]);
  End;
  PickClose;
End;

Function PickProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; K : LongInt;
Begin
  PickProc := 0;
  Case Msg0 Of
    WM_PAINT : Begin
                 Hps := WinBeginPaint(H, 0, 0);
                 Dummy := WinQueryWindowRect(H, LongInt(@Rc));
                 Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
                 Dummy := WinEndPaint(Hps);
               End;
    WM_CONTROL : If Lo16(Mp1) = ID_PLIST Then
                 Begin
                   K := WinSendMsg(PickList, LM_QUERYSELECTION, -1, 0);
                   If (K >= 0) And (K < PickN) Then
                   Begin
                     SetText(PickPath, PickF[K]);
                     If Hi16(Mp1) = 5 Then PickOk;          { LN_ENTER : double clic }
                   End;
                 End;
    WM_COMMAND : Case Lo16(Mp1) Of
                   ID_OK : PickOk;
                   ID_CANCEL : PickClose;
                 End;
    WM_CLOSE : PickClose;
  Else
    PickProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
  End;
End;

{ choisir une image de CD-ROM (Kind = 1) ou de disquette (Kind = 3) }
Procedure ShowPick(Kind : LongInt);
Var Flg, W, H, K : LongInt; T, Cur : String;
Begin
  If PickFrame <> 0 Then Exit;
  PickKind := Kind;
  If Kind = 1 Then T := Fr('Choisir une image de CD-ROM') Else T := Fr('Choisir une image de disquette');
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  PickClient := 0;
  PickFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('VBOXPICK'), Z2(T), 0, 0, 0, LongInt(@PickClient));
  W := 560; H := 330;
  CenterFrame(PickFrame, W, H);
  CH := H;
  If Kind = 1 Then
    Gray(Ctl(PickClient, WC_STATIC, Fr('Images de CD-ROM (.ISO) trouv`ees :'), SS_TEXT, 12, 10, 400, 20, 0))
  Else
    Gray(Ctl(PickClient, WC_STATIC, Fr('Images de disquette (.IMG, .IMA, .VFD) trouv`ees :'), SS_TEXT, 12, 10, 450, 20, 0));
  PickList := Ctl(PickClient, WC_LISTBOX, '', WS_TABSTOP, 12, 32, W - 24, 190, ID_PLIST);
  PickN := 0;
  PickScan(VmsDir, 0);
  PickScan('C:\', 1);
  If UpS(Copy(VmsDir, 1, 2)) <> 'D:' Then PickScan('D:\', 1);
  For K := 0 To PickN - 1 Do Dummy := WinSendMsg(PickList, LM_INSERTITEM, -1, Z(PickF[K]));
  Gray(Ctl(PickClient, WC_STATIC, 'Fichier :', SS_TEXT, 12, 233, 80, 20, 0));
  Cur := '';
  If (CurVm >= 0) And (CurVm < NVm) Then
  Begin
    If Kind = 1 Then Cur := Vms[CurVm].Cd Else Cur := Vms[CurVm].Fd;
  End;
  PickPath := Ctl(PickClient, WC_ENTRYFIELD, Cur, ES_AUTOSCROLL Or ES_MARGIN Or WS_TABSTOP, 92, 230, W - 104, 24, ID_PPATH);
  Dummy := WinSendMsg(PickPath, EM_SETTEXTLIMIT, 250, 0);
  Dummy := Ctl(PickClient, WC_BUTTON, 'OK', BS_PUSHBUTTON Or BS_DEFAULT Or WS_TABSTOP, W - 210, H - 38, 90, 28, ID_OK);
  Dummy := Ctl(PickClient, WC_BUTTON, 'Annuler', BS_PUSHBUTTON Or WS_TABSTOP, W - 110, H - 38, 90, 28, ID_CANCEL);
  If VmFrame <> 0 Then Dummy := WinEnableWindow(VmFrame, 0);
  Dummy := WinSetFocus(HWND_DESKTOP, PickPath);
End;

Function MoOf(Sect : LongInt) : String;
Begin
  MoOf := IStr(Sect Div 2048) + ',' + IStr(((Sect Mod 2048) * 10) Div 2048) + ' Mo';
End;

{ Informations sur les disques de la machine en fonction }
Procedure DiskInfo;
Var K : LongInt; S : String;
Begin
  LClr;
  For K := 0 To 1 Do
  Begin
    If K = 0 Then S := Fr('Disque dur 0 (IDE primaire, ma`itre) : ') Else S := Fr('Disque dur 1 (IDE primaire, esclave) : ');
    If DkH[K] < 0 Then LLine(S + 'aucun')
    Else
    Begin
      LLine(S + DkPath[K]);
      S := '   ' + DkFmt[K] + ', ' + MoOf(DkSect[K]) + ', ' + IStr(DkSect[K]) + ' secteurs, CHS ' + IStr(DkCyl[K]) + '/' +
           IStr(DkHeads[K]) + '/' + IStr(DkSpt[K]) + ', ' + IStr(DkReads[K]) + ' lectures, ' + IStr(DkWrites[K]) +
           Fr(' `ecritures');
      If DkRO[K] <> 0 Then S := S + Fr(', lecture seule');
      LLine(S);
    End;
  End;
  S := Fr('CD-ROM (IDE secondaire, ma`itre, ATAPI) : ');
  If DkH[DkCd] < 0 Then LLine(S + 'vide')
  Else
  Begin
    LLine(S + DkPath[DkCd]);
    S := '   ISO 9660, ' + MoOf(DkSect[DkCd]) + ', ' + IStr(DkSect[DkCd] Div 4) + ' secteurs de 2048 octets, ' +
         IStr(DkReads[DkCd] + DkReads[DkEmu]) + ' lectures';
    If CdOn Then
    Begin
      Case CdEmu Of
        0 : S := S + Fr(', amor`cable (El Torito sans `emulation)');
        1, 2, 3 : S := S + Fr(', amor`cable (El Torito, disquette `emul`ee)');
      Else
        S := S + Fr(', amor`cable (El Torito, disque dur `emul`e)');
      End;
      If CdEmuOn Then S := S + Fr(', `emulation active');
    End;
    LLine(S);
  End;
  S := 'Disquette (A:) : ';
  If DkH[2] < 0 Then LLine(S + 'vide')
  Else
  Begin
    LLine(S + DkPath[2]);
    LLine('   ' + MoOf(DkSect[2]) + ', CHS ' + IStr(DkCyl[2]) + '/' + IStr(DkHeads[2]) + '/' + IStr(DkSpt[2]) + ', ' +
          IStr(DkReads[2]) + ' lectures, ' + IStr(DkWrites[2]) + Fr(' `ecritures'));
  End;
  Dummy := LMsgBox(Fr('Informations sur les disques'), MB_OK Or MB_INFORMATION, VmFrame);
End;

{ menu des supports (clic sur la partie disque de la barre d'etat) }
Procedure DevMenu(X, Y : LongInt);
Var N, A : LongInt; S : String;
Begin
  MenuLen := 0;
  MW(0); MW(0); MW(0);
  N := 0;
  If DkH[DkCd] >= 0 Then S := 'CD-ROM : ' + NameOf(DkPath[DkCd]) Else S := 'CD-ROM : vide';
  MItem(MIS_TEXT, MIA_DISABLED, 499, S); Inc(N);
  MItem(MIS_TEXT, 0, CM_CDCHOOSE, 'Choisir une image de ~CD-ROM...'); Inc(N);
  If DkH[DkCd] >= 0 Then A := 0 Else A := MIA_DISABLED;
  MItem(MIS_TEXT, A, CM_CDEJECT, '`~Ejecter le CD-ROM'); Inc(N);
  MItem(MIS_SEPARATOR, 0, 0, ''); Inc(N);
  If DkH[2] >= 0 Then S := 'Disquette : ' + NameOf(DkPath[2]) Else S := 'Disquette : vide';
  MItem(MIS_TEXT, MIA_DISABLED, 498, S); Inc(N);
  MItem(MIS_TEXT, 0, CM_FDCHOOSE, 'Choisir une image de ~disquette...'); Inc(N);
  If DkH[2] >= 0 Then A := 0 Else A := MIA_DISABLED;
  MItem(MIS_TEXT, A, CM_FDEJECT, '`Ejecter la dis~quette'); Inc(N);
  MItem(MIS_SEPARATOR, 0, 0, ''); Inc(N);
  MItem(MIS_TEXT, 0, CM_DISKINFO, '~Informations sur les disques...'); Inc(N);
  MenuClose(0, N);
  If PopMenu <> 0 Then Dummy := WinDestroyWindow(PopMenu);
  PopMenu := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuT));
  PopUntil := NowMs + 10000;
  If PopMenu <> 0 Then Dummy := WinPopupMenu(VmClient, VmClient, PopMenu, X, Y, CM_CDCHOOSE, 0);
End;

Procedure VmCommand(Id : LongInt);
Var S : String;
Begin
  PopUntil := 0;
  Case Id Of
    CM_CDCHOOSE : ShowPick(1);
    CM_FDCHOOSE : ShowPick(3);
    CM_CDEJECT : Begin
                   MedReq := 2;
                   If (CurVm >= 0) And (CurVm < NVm) Then
                   Begin
                     Vms[CurVm].Cd := '';
                     If Vms[CurVm].Vbox <> '' Then Dummy := VmSave(Vms[CurVm]);
                   End;
                 End;
    CM_FDEJECT : Begin
                   MedReq := 4;
                   If (CurVm >= 0) And (CurVm < NVm) Then
                   Begin
                     Vms[CurVm].Fd := '';
                     If Vms[CurVm].Vbox <> '' Then Dummy := VmSave(Vms[CurVm]);
                   End;
                 End;
    CM_DISKINFO : DiskInfo;
    CM_PAUSE : If VmState = VS_RUN Then VmState := VS_PAUSE Else If VmState = VS_PAUSE Then VmState := VS_RUN;
    CM_RESET : If Ask('R`einitialiser la machine ? Les donn`ees non enregistr`ees de l''invite seront perdues.',
                      'Virtualisation', MB_YESNO Or MB_ICONQUESTION, VmFrame) = MBID_YES Then VmReqReset := 1;
    CM_CAD : VmReqCad := 1;
    CM_POWER : If Ask('`Eteindre la machine (comme couper le courant) ?', 'Virtualisation',
                      MB_YESNO Or MB_ICONQUESTION, VmFrame) = MBID_YES Then VmReqStop := 1;
    CM_VMINFO : ShowInfo;
    CM_ABOUT : Begin
                 LClr;
                 LLine(Fr('Virtualisation pour OS/2-0'));
                 LLine('');
                 LLine(Fr('Machines virtuelles au format de VirtualBox, ex`ecut`ees directement sur le'));
                 LLine(Fr('processeur : AMD-V, Intel VT-x ou mode virtuel 8086.'));
                 LLine('');
                 LLine('(c) 2026 Sylvain Maltais - www.gladir.com');
                 Dummy := LMsgBox(Fr('`A propos de Virtualisation'), MB_OK Or MB_INFORMATION, VmFrame);
               End;
  End;
End;

Function VmProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  VmProc := 0;
  Case Msg0 Of
    WM_PAINT : VmPaint(H);
    WM_TIMER : VmTick(H);
    WM_CHAR : If ((Lo16(Mp1) And KC_ALT) <> 0) And (UpCase(Chr(Lo16(Mp2) And 255)) In ['M', 'P', 'A']) Then
                VmProc := WinDefWindowProc(H, Msg0, Mp1, Mp2)
              Else If InDlg = 0 Then VmKey(Mp1, Mp2);
    WM_BUTTON1DOWN, WM_BUTTON2DOWN :
      Begin
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        PopUntil := 0;
        { barre d'etat (en bas, coordonnees de PM) : partie disque ou icones }
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        If (Hi16(Mp1) <= Rc[3] - ScrH) And (Lo16(Mp1) >= DiskX - 8) Then DevMenu(Lo16(Mp1), Hi16(Mp1));
        VmProc := 1;
      End;
    WM_COMMAND : VmCommand(Lo16(Mp1));
    WM_CLOSE : If VmState <> VS_OFF Then
               Begin
                 If Ask('La machine est en fonction. L''`eteindre ?', 'Virtualisation', MB_YESNO Or MB_ICONQUESTION,
                        VmFrame) = MBID_YES Then VmReqStop := 1;
               End
               Else Dummy := WinDestroyWindow(VmFrame);
    WM_VMEND : Begin
                 Dummy := WinDestroyWindow(VmFrame);
               End;
    WM_DESTROY : Begin
                   VmFrame := 0; VmWin := 0; VmClient := 0;
                   If MgrClient <> 0 Then Dummy := WinInvalidateRect(MgrClient, 0, 0);
                 End;
  Else
    VmProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
  End;
End;

Procedure StartVm(I : LongInt);
Var Flg, H0, H1, M, Tid : LongInt; Err : String;
Begin
  If (I < 0) Or (I >= NVm) Then Exit;
  If VmFrame <> 0 Then
  Begin
    Dummy := Ask('Une machine est d`ej`a en fonction.', 'Virtualisation', MB_OK Or MB_ICONWARNING, MgrFrame);
    Exit;
  End;
  If Not VmOpen(I, Err) Then
  Begin
    Dummy := Ask('Impossible de d`emarrer la machine ' + Vms[I].Name + ' : ' + Err, 'Virtualisation',
                 MB_OK Or MB_ERROR, MgrFrame);
    Exit;
  End;
  If StartKeys <> '' Then TypeText(StartKeys);
  StartKeys := '';
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  VmClient := 0;
  VmTitle := Vms[I].Name + Fr(' [En fonction] - Virtualisation');
  VmFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('VBOXVM'), Z2(VmTitle), 0, 0, 0,
                                LongInt(@VmClient));
  VmWin := VmClient;
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 1100, '~Machine');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_PAUSE, '~Pause / reprise');
  MItem(MIS_TEXT, 0, CM_RESET, '~R`einitialiser');
  MItem(MIS_TEXT, 0, CM_CAD, 'Envoyer Ctrl+Alt+~Suppr');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_VMINFO, '~Information de virtualisation...');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_POWER, '`~Eteindre la machine');
  MenuClose(H1, 7);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 1200, '~P`eriph`eriques');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_CDCHOOSE, 'Choisir une image de ~CD-ROM...');
  MItem(MIS_TEXT, 0, CM_CDEJECT, '`~Ejecter le CD-ROM');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_FDCHOOSE, 'Choisir une image de ~disquette...');
  MItem(MIS_TEXT, 0, CM_FDEJECT, '`Ejecter la dis~quette');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_DISKINFO, '~Informations sur les disques...');
  MenuClose(H1, 7);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 1300, 'A~ide');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_ABOUT, '`~A propos de Virtualisation');
  MenuClose(H1, 1);
  MenuClose(H0, 3);
  M := WinCreateMenu(VmFrame, LongInt(@MenuT));
  ScrH := 400;
  CenterFrame(VmFrame, SW_, ScrH + 22);
  InitBmi;
  LastSum := -1;
  VmState := VS_RUN;
  Dummy := WinStartTimer(Hab, VmClient, 1, 50);
  Dummy := WinSetFocus(HWND_DESKTOP, VmClient);
  Tid := 0;
  If DosCreateThread(LongInt(@Tid), LongInt(@VmThread), 0, 0, 262144) <> 0 Then
  Begin
    VmState := VS_OFF;
    VmClose;
    Dummy := WinDestroyWindow(VmFrame);
  End;
  If MgrClient <> 0 Then Dummy := WinInvalidateRect(MgrClient, 0, 0);
End;

{ ==================================================================== }
{ Configuration d'une machine                                           }
{ ==================================================================== }

Procedure CfgClose;
Begin
  If CfgFrame <> 0 Then Dummy := WinDestroyWindow(CfgFrame);
  CfgFrame := 0;
  If MgrFrame <> 0 Then Dummy := WinEnableWindow(MgrFrame, 1);
End;

Function SafeName(S : String) : String;
Var K : LongInt; R : String;
Begin
  R := '';
  For K := 1 To Length(S) Do
    If S[K] In ['A'..'Z', 'a'..'z', '0'..'9', '-', '_'] Then R := R + S[K]
    Else If S[K] = ' ' Then R := R + '_';
  If R = '' Then R := 'MACHINE';
  SafeName := Copy(R, 1, 32);
End;

{ ---- types de systeme : distributions de GitHub (image ISO
  d'installation telechargee) et systemes fournis localement ---- }

Const
  NDist = 8;
  DistGit = 4;                        { 0 a 3 : telecharges de GitHub }

Function DistLabel(I : LongInt) : String;
Begin
  Case I Of
    0 : DistLabel := 'MSDOS-0 (t`el`echarger `a partir de GitHub)';
    1 : DistLabel := 'UNIX-0 (t`el`echarger `a partir de GitHub)';
    2 : DistLabel := 'OS2-Zero (t`el`echarger `a partir de GitHub)';
    3 : DistLabel := 'Pasdows95 (t`el`echarger `a partir de GitHub)';
    4 : DistLabel := 'DOS (fourni par vous localement)';
    5 : DistLabel := 'Windows (fourni par vous localement)';
    6 : DistLabel := 'Linux (fourni par vous localement)';
  Else
    DistLabel := 'Autre (fourni par vous localement)';
  End;
End;

Function DistName(I : LongInt) : String;
Begin
  Case I Of
    0 : DistName := 'MSDOS-0'; 1 : DistName := 'UNIX-0'; 2 : DistName := 'OS2-Zero'; 3 : DistName := 'Pasdows95';
    4 : DistName := 'DOS'; 5 : DistName := 'Windows'; 6 : DistName := 'Linux';
  Else
    DistName := 'Autre';
  End;
End;

{ OSType de VirtualBox }
Function DistOs(I : LongInt) : String;
Begin
  Case I Of
    0, 4 : DistOs := 'DOS';
    2 : DistOs := 'OS2Warp3';
    3, 5 : DistOs := 'Windows95';
    6 : DistOs := 'Linux';
  Else
    DistOs := 'Other';
  End;
End;

{ depot de GitHub (gladir/...) et image ISO d'installation (branche main) }
Function DistRepo(I : LongInt) : String;
Begin
  Case I Of
    0 : DistRepo := 'MSDOS-0'; 1 : DistRepo := 'UNIX-0'; 2 : DistRepo := 'OS2-0'; 3 : DistRepo := 'Pasdows95';
  Else
    DistRepo := '';
  End;
End;

Function DistPath(I : LongInt) : String;
Begin
  Case I Of
    0 : DistPath := 'IMAGE/INSTALLCD.ISO';
    1 : DistPath := 'IMAGES/UNIX0-CD.ISO';
    2 : DistPath := 'IMAGE/OS2INST.ISO';
    3 : DistPath := 'IMAGE/INSTALL.ISO';
  Else
    DistPath := '';
  End;
End;

Function DistUrl(I : LongInt) : String;
Begin
  DistUrl := 'https://raw.githubusercontent.com/gladir/' + DistRepo(I) + '/main/' + DistPath(I);
End;

{ memoire (Mo) et disque dur (Mo) proposes }
Function DistMem(I : LongInt) : LongInt;
Begin
  If (I = 2) Or (I = 3) Then DistMem := 64 Else If I = 1 Then DistMem := 16 Else DistMem := 32;
End;

Function DistHd(I : LongInt) : LongInt;
Begin
  If (I = 2) Or (I = 3) Then DistHd := 512 Else DistHd := 64;
End;

{ type d'une machine existante }
Function DistOf(Var V : TVm) : LongInt;
Var K : LongInt; T : String;
Begin
  For K := 0 To DistGit - 1 Do
    If UpS(V.Distro) = UpS(DistName(K)) Then
    Begin
      DistOf := K;
      Exit;
    End;
  T := UpS(V.OsType);
  If Copy(T, 1, 3) = 'DOS' Then DistOf := 4
  Else If Copy(T, 1, 3) = 'WIN' Then DistOf := 5
  Else If (Copy(T, 1, 5) = 'LINUX') Or (Copy(T, 1, 6) = 'UBUNTU') Or (Copy(T, 1, 6) = 'DEBIAN') Then DistOf := 6
  Else DistOf := 7;
End;

{ ---- telechargement de l'image ISO (fenetre de progression) ---- }

Var
  DwFrame, DwClient, DwDist : LongInt;
  PendV : TVm;
  PendHd : String;                    { disque neuf a effacer si le telechargement echoue }
  DwBtn : LongInt;

Procedure CfgFinish(Var V : TVm; Start : Boolean);
Var I : LongInt;
Begin
  If Not VmSave(V) Then
  Begin
    Dummy := Ask('Impossible d''`ecrire ' + V.Vbox + '.', 'Virtualisation', MB_OK Or MB_ERROR, MgrFrame);
    Exit;
  End;
  I := -1;
  If CfgEdit >= 0 Then
  Begin
    Vms[CfgEdit] := V;
    I := CfgEdit;
  End
  Else If NVm < MaxVm Then
  Begin
    Vms[NVm] := V;
    I := NVm;
    CurSel := NVm;
    Inc(NVm);
  End;
  RegSave;
  If MgrClient <> 0 Then
  Begin
    Dummy := WinPostMsg(MgrClient, WM_VMTITLE, 0, 0);
    Dummy := WinInvalidateRect(MgrClient, 0, 0);
  End;
  { installation : la machine demarre sur le CD-ROM telecharge }
  If Start And (I >= 0) And (VmFrame = 0) Then
  Begin
    CurSel := I;
    FillList;
    StartVm(I);
  End;
End;

Function MoStr(B : LongInt) : String;
Begin
  MoStr := IStr(B Div 1048576) + ',' + IStr(((B Mod 1048576) * 10) Div 1048576) + ' Mo';
End;

Procedure DwClose;
Begin
  If DwFrame <> 0 Then Dummy := WinDestroyWindow(DwFrame);
  DwFrame := 0; DwClient := 0;
  If MgrFrame <> 0 Then Dummy := WinEnableWindow(MgrFrame, 1);
End;

Procedure DwPaint(H : LongInt);
Var Rc : Array[0..3] Of LongInt; W, P, X : LongInt; S : String;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  CW := Rc[2]; CH := Rc[3];
  RgbMode;
  FBar(0, 0, CW - 1, CH - 1, $CCCCCC);
  OutTxt(16, 12, Fr('T`el`echargement de ') + DistName(DwDist) + Fr(' `a partir de GitHub'), $000080, $CCCCCC);
  OutTxt(16, 36, 'Source : github.com/gladir/' + DistRepo(DwDist), $101010, $CCCCCC);
  OutTxt(16, 54, 'Fichier : ' + Copy(PendV.Cd, 1, 52), $101010, $CCCCCC);
  { barre de progression }
  W := CW - 32;
  Edge(16, 80, 16 + W, 102, $808080, $FFFFFF);
  FBar(17, 81, 15 + W, 101, $FFFFFF);
  P := 0;
  If DlTotal > 0 Then P := (DlDone Div 1024) * 1000 Div MaxI(1, DlTotal Div 1024);
  If P > 1000 Then P := 1000;
  X := ((W - 2) * P) Div 1000;
  If X > 0 Then FBar(17, 81, 17 + X - 1, 101, $2050A0);
  If DlState <= 1 Then S := Fr('Connexion `a GitHub...')
  Else
  Begin
    S := MoStr(DlDone);
    If DlTotal > 0 Then S := S + ' sur ' + MoStr(DlTotal) + ' (' + IStr(P Div 10) + ' %)';
    If DlRate > 0 Then S := S + ' - ' + IStr(DlRate Div 1024) + ' Ko/s';
  End;
  OutTxt(16, 110, S, $101010, $CCCCCC);
  OutTxt(16, 132, Fr('La machine d`emarrera ensuite sur ce CD-ROM pour l''installation.'), $404040, $CCCCCC);
  Dummy := WinEndPaint(Hps);
End;

Function DwProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Var S : String;
Begin
  DwProc := 0;
  Case Msg0 Of
    WM_PAINT : DwPaint(H);
    WM_TIMER : Begin
                 If DlState = 3 Then
                 Begin
                   DwClose;
                   CfgFinish(PendV, True);
                 End
                 Else If DlState = 4 Then
                 Begin
                   S := DlErr;
                   DwClose;
                   If PendHd <> '' Then Dummy := DosDelete(Z(PendHd));
                   Dummy := Ask(Fr('Le t`el`echargement de ') + DistName(DwDist) + Fr(' a `echou`e : ') + S,
                                'Virtualisation', MB_OK Or MB_ERROR, MgrFrame);
                 End
                 Else If DlState = 5 Then
                 Begin
                   DwClose;
                   If PendHd <> '' Then Dummy := DosDelete(Z(PendHd));
                 End
                 Else Dummy := WinInvalidateRect(H, 0, 0);
               End;
    WM_COMMAND : If Lo16(Mp1) = ID_CANCEL Then DlAbort := 1;
    WM_CLOSE : DlAbort := 1;
  Else
    DwProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
  End;
End;

Procedure ShowDl(D : LongInt);
Var Flg : LongInt;
Begin
  DwDist := D;
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER Or FCF_TASKLIST;
  DwClient := 0;
  DwFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('VBOXDL'), Z2(Fr('T`el`echargement - Virtualisation')),
                                0, 0, 0, LongInt(@DwClient));
  CenterFrame(DwFrame, 540, 200);
  CH := 200;
  DwBtn := Ctl(DwClient, WC_BUTTON, 'Annuler', BS_PUSHBUTTON Or WS_TABSTOP, 540 - 110, 200 - 38, 90, 28, ID_CANCEL);
  If MgrFrame <> 0 Then Dummy := WinEnableWindow(MgrFrame, 0);
  DlStart(DistUrl(D), PendV.Cd);
  Dummy := WinStartTimer(Hab, DwClient, 2, 250);
End;

Procedure CfgOk;
Var V : TVm; Hd, Dir : String; Mb, Sel : LongInt; Git : Boolean;
Begin
  PendHd := '';
  V.Used := True;
  V.Name := CtlText(CName);
  If V.Name = '' Then
  Begin
    Dummy := Ask('Donnez un nom `a la machine.', 'Virtualisation', MB_OK Or MB_ICONWARNING, CfgFrame);
    Exit;
  End;
  Sel := WinSendMsg(CType, LM_QUERYSELECTION, -1, 0);
  If (Sel < 0) Or (Sel >= NDist) Then Sel := 4;
  Git := (CfgEdit < 0) And (Sel < DistGit);
  V.OsType := DistOs(Sel);
  V.Distro := '';
  If Sel < DistGit Then V.Distro := DistName(Sel);
  { type inchange d'une machine existante : on garde son OSType }
  If (CfgEdit >= 0) And (Sel = DistOf(Vms[CfgEdit])) Then
  Begin
    V.OsType := Vms[CfgEdit].OsType;
    V.Distro := Vms[CfgEdit].Distro;
  End;
  If Git And (V.Name = Fr('Nouvelle machine')) Then V.Name := DistName(Sel);
  V.MemMb := SVal(CtlText(CMem));
  If Git And (V.MemMb = 32) Then V.MemMb := DistMem(Sel);
  If (V.MemMb < 1) Or (V.MemMb > 128) Then
  Begin
    Dummy := Ask('La m`emoire vive doit `etre de 1 `a 128 Mo.', 'Virtualisation', MB_OK Or MB_ICONWARNING, CfgFrame);
    Exit;
  End;
  Hd := CtlText(CHd);
  If CfgEdit >= 0 Then
  Begin
    V.Vbox := Vms[CfgEdit].Vbox; V.Uuid := Vms[CfgEdit].Uuid;
    V.Hd0Uuid := Vms[CfgEdit].Hd0Uuid; V.Hd1Uuid := Vms[CfgEdit].Hd1Uuid; V.CdUuid := Vms[CfgEdit].CdUuid;
    If UpS(Hd) <> UpS(Vms[CfgEdit].Hd0) Then V.Hd0Uuid := '';
  End
  Else
  Begin
    Dir := VmsDir;
    Dir := Dir + SafeName(V.Name);
    Dummy := DosCreateDir(Z(Dir), 0);
    V.Vbox := Dir + '\' + SafeName(V.Name) + '.VBOX';
    V.Uuid := ''; V.Hd0Uuid := ''; V.Hd1Uuid := ''; V.CdUuid := '';
    If FExists(V.Vbox) Then
    Begin
      Dummy := Ask('Une machine nomm`ee ' + V.Name + ' existe d`ej`a (' + V.Vbox + ').', 'Virtualisation',
                   MB_OK Or MB_ICONWARNING, CfgFrame);
      Exit;
    End;
  End;
  { installation : un disque dur neuf s'il n'y en a pas }
  If Git And (Hd = '') Then Dummy := WinSendMsg(CNew, BM_SETCHECK, 1, 0);
  If WinSendMsg(CNew, BM_QUERYCHECK, 0, 0) <> 0 Then
  Begin
    Mb := SVal(CtlText(CSize));
    If Git And (Mb = 64) Then Mb := DistHd(Sel);
    If (Mb < 1) Or (Mb > 32768) Then Mb := 64;
    If Hd = '' Then Hd := DirOf(V.Vbox) + SafeName(V.Name) + '.VHD';
    If FExists(Hd) Then
    Begin
      Dummy := Ask('Le disque ' + Hd + ' existe d`ej`a.', 'Virtualisation', MB_OK Or MB_ICONWARNING, CfgFrame);
      Exit;
    End;
    If Not VhdCreate(Hd, Mb) Then
    Begin
      Dummy := Ask('Impossible de cr`eer le disque ' + Hd + '.', 'Virtualisation', MB_OK Or MB_ERROR, CfgFrame);
      Exit;
    End;
    PendHd := Hd;
  End
  Else If (Hd <> '') And Not FExists(Hd) Then
  Begin
    Dummy := Ask('Disque introuvable : ' + Hd, 'Virtualisation', MB_OK Or MB_ICONWARNING, CfgFrame);
    Exit;
  End;
  V.Hd0 := Hd;
  V.Hd1 := CtlText(CHd2);
  V.Fd := CtlText(CFd);
  V.Cd := CtlText(CCd);
  If Copy(V.Cd, 1, 1) = '(' Then V.Cd := '';
  If (V.Cd <> '') And Not FExists(V.Cd) And Not Git Then
  Begin
    Dummy := Ask('Image de CD-ROM introuvable : ' + V.Cd, 'Virtualisation', MB_OK Or MB_ICONWARNING, CfgFrame);
    Exit;
  End;
  If WinSendMsg(CBootFd, BM_QUERYCHECK, 0, 0) <> 0 Then V.BootFd := 1 Else V.BootFd := 0;
  If WinSendMsg(CBootCd, BM_QUERYCHECK, 0, 0) <> 0 Then V.BootCd := 1 Else V.BootCd := 0;
  If Git Then
  Begin
    { image ISO d'installation de GitHub dans le dossier de la machine }
    V.Cd := DirOf(V.Vbox) + NameOf(DistPath(Sel));
    V.BootCd := 1;
    CfgClose;
    If FExists(V.Cd) Then
    Begin
      CfgFinish(V, True);
      Exit;
    End;
    PendV := V;
    ShowDl(Sel);
    Exit;
  End;
  CfgClose;
  CfgFinish(V, False);
End;

{ type choisi dans la liste : pour une distribution de GitHub, nom,
  memoire, disque neuf et amorcage par le CD-ROM proposes }
Procedure CfgType;
Var Sel, K : LongInt; N : String; Std : Boolean;
Begin
  If CfgEdit >= 0 Then Exit;
  Sel := WinSendMsg(CType, LM_QUERYSELECTION, -1, 0);
  If (Sel < 0) Or (Sel >= DistGit) Then Exit;
  N := CtlText(CName);
  Std := N = Fr('Nouvelle machine');
  For K := 0 To DistGit - 1 Do If N = DistName(K) Then Std := True;
  If Std Then SetText(CName, DistName(Sel));
  SetText(CMem, IStr(DistMem(Sel)));
  If CtlText(CHd) = '' Then
  Begin
    Dummy := WinSendMsg(CNew, BM_SETCHECK, 1, 0);
    SetText(CSize, IStr(DistHd(Sel)));
  End;
  Dummy := WinSendMsg(CBootCd, BM_SETCHECK, 1, 0);
  SetText(CCd, Fr('(image t`el`echarg`ee de GitHub)'));
End;

Function CfgProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  CfgProc := 0;
  Case Msg0 Of
    WM_PAINT : Begin
                 Hps := WinBeginPaint(H, 0, 0);
                 Dummy := WinQueryWindowRect(H, LongInt(@Rc));
                 Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
                 Dummy := WinEndPaint(Hps);
               End;
    WM_COMMAND : Case Lo16(Mp1) Of
                   ID_OK : CfgOk;
                   ID_CANCEL : CfgClose;
                 End;
    WM_CONTROL : If (Lo16(Mp1) = ID_TYPE) And (Hi16(Mp1) = 3) Then CfgType;
    WM_CLOSE : CfgClose;
  Else
    CfgProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
  End;
End;

Procedure CfgLabel(S : String; Y : LongInt);
Begin
  Gray(Ctl(CfgClient, WC_STATIC, S, SS_TEXT, 16, Y + 3, 150, 20, 0));
End;

Function CfgEntry(S : String; Y, W, Id : LongInt) : LongInt;
Var E : LongInt;
Begin
  E := Ctl(CfgClient, WC_ENTRYFIELD, S, ES_AUTOSCROLL Or ES_MARGIN Or WS_TABSTOP, 172, Y, W, 24, Id);
  Dummy := WinSendMsg(E, EM_SETTEXTLIMIT, 250, 0);
  CfgEntry := E;
End;

Procedure ShowCfg(I : LongInt);
Var Flg, W, H, K : LongInt; V : TVm; T : String;
Begin
  If CfgFrame <> 0 Then Exit;
  CfgEdit := I;
  If I >= 0 Then V := Vms[I]
  Else
  Begin
    V.Name := 'Nouvelle machine'; V.OsType := 'DOS'; V.MemMb := 32; V.Hd0 := ''; V.Hd1 := ''; V.Fd := '';
    V.BootFd := 0; V.Cd := ''; V.BootCd := 0; V.Distro := '';
  End;
  If I >= 0 Then T := Fr('Configuration de ') + V.Name Else T := Fr('Nouvelle machine virtuelle');
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER Or FCF_TASKLIST;
  CfgClient := 0;
  CfgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('VBOXCFG'), Z2(T), 0, 0, 0, LongInt(@CfgClient));
  W := 600; H := 384;
  CenterFrame(CfgFrame, W, H);
  CH := H;
  Gray(Ctl(CfgClient, WC_STATIC, 'G`en`eral', SS_GROUPBOX, 8, 4, W - 16, 98, 0));
  CfgLabel('Nom :', 24);
  CName := CfgEntry(V.Name, 24, 400, ID_NAME);
  CfgLabel('Type (OSType) :', 50);
  { liste deroulante : systemes de GitHub (image ISO d'installation
    telechargee) ou fournis localement }
  CType := Ctl(CfgClient, WC_COMBOBOX, '', CBS_DROPDOWNLIST Or WS_TABSTOP, 172, 50, 400, 24, ID_TYPE);
  For K := 0 To NDist - 1 Do Dummy := WinSendMsg(CType, LM_INSERTITEM, -1, Z(Fr(DistLabel(K))));
  If I >= 0 Then K := DistOf(V) Else K := 4;
  Dummy := WinSendMsg(CType, LM_SELECTITEM, K, 1);
  CfgLabel('M`emoire vive (Mo) :', 76);
  CMem := CfgEntry(IStr(V.MemMb), 76, 80, ID_MEM);
  Gray(Ctl(CfgClient, WC_STATIC, 'Stockage', SS_GROUPBOX, 8, 108, W - 16, 226, 0));
  CfgLabel('Disque dur 0 :', 128);
  CHd := CfgEntry(V.Hd0, 128, 400, ID_HD);
  CNew := Ctl(CfgClient, WC_BUTTON, 'Nouveau disque ~dynamique (VHD) de', BS_AUTOCHECKBOX Or WS_TABSTOP,
              172, 156, 330, 22, ID_NEWHD);
  Gray(CNew);
  CSize := CfgEntry('64', 156, 60, ID_HDSZ);
  Dummy := WinSetWindowPos(CSize, 0, 506, CH - 156 - 24, 60, 24, SWP_MOVE Or SWP_SIZE);
  Gray(Ctl(CfgClient, WC_STATIC, 'Mo', SS_TEXT, 570, 159, 24, 20, 0));
  CfgLabel('Disque dur 1 :', 186);
  CHd2 := CfgEntry(V.Hd1, 186, 400, ID_HD2);
  CfgLabel('Disquette (A:) :', 214);
  CFd := CfgEntry(V.Fd, 214, 400, ID_FD);
  CfgLabel('CD-ROM (ISO) :', 242);
  CCd := CfgEntry(V.Cd, 242, 400, 29);
  CBootFd := Ctl(CfgClient, WC_BUTTON, '~Amorcer d''abord la disquette', BS_AUTOCHECKBOX Or WS_TABSTOP, 172, 272, 300, 22, 28);
  Gray(CBootFd);
  If V.BootFd <> 0 Then Dummy := WinSendMsg(CBootFd, BM_SETCHECK, 1, 0);
  CBootCd := Ctl(CfgClient, WC_BUTTON, 'Amorcer d''abord le ~CD-ROM', BS_AUTOCHECKBOX Or WS_TABSTOP, 172, 298, 300, 22, 30);
  Gray(CBootCd);
  If V.BootCd <> 0 Then Dummy := WinSendMsg(CBootCd, BM_SETCHECK, 1, 0);
  Dummy := Ctl(CfgClient, WC_BUTTON, 'OK', BS_PUSHBUTTON Or BS_DEFAULT Or WS_TABSTOP, W - 210, H - 38, 90, 28, ID_OK);
  Dummy := Ctl(CfgClient, WC_BUTTON, 'Annuler', BS_PUSHBUTTON Or WS_TABSTOP, W - 110, H - 38, 90, 28, ID_CANCEL);
  If MgrFrame <> 0 Then Dummy := WinEnableWindow(MgrFrame, 0);
  Dummy := WinSetFocus(HWND_DESKTOP, CName);
End;

{ ==================================================================== }
{ Gestionnaire (fenetre principale)                                     }
{ ==================================================================== }

Const
  TbH = 44;

Var
  MgrW, MgrH, ListW : LongInt;

Procedure FillList;
Var K : LongInt; S : String;
Begin
  If ListBox = 0 Then Exit;
  Dummy := WinSendMsg(ListBox, LM_DELETEALL, 0, 0);
  For K := 0 To NVm - 1 Do
  Begin
    S := Vms[K].Name;
    If (VmFrame <> 0) And (K = CurVm) Then S := S + Fr(' (en fonction)');
    Dummy := WinSendMsg(ListBox, LM_INSERTITEM, -1, Z(S));
  End;
  If (CurSel >= 0) And (CurSel < NVm) Then Dummy := WinSendMsg(ListBox, LM_SELECTITEM, CurSel, 1);
End;

{ icone d'ordinateur (ecran et clavier) }
Procedure DrawPc(X, Y : LongInt; On : Boolean);
Begin
  FBar(X, Y, X + 39, Y + 29, $404040);
  If On Then FBar(X + 3, Y + 3, X + 36, Y + 25, $108020) Else FBar(X + 3, Y + 3, X + 36, Y + 25, $203070);
  FBar(X + 6, Y + 6, X + 20, Y + 8, $C0C0C0);
  FBar(X + 16, Y + 30, X + 23, Y + 33, $404040);
  FBar(X + 6, Y + 34, X + 33, Y + 37, $606060);
End;

Procedure Section(Y : LongInt; T : String);
Begin
  FBar(ListW + 20, Y, MgrW - 12, Y + 19, $2050A0);
  OutTxt(ListW + 28, Y + 2, Fr(T), $FFFFFF, $2050A0);
End;

Procedure Field(Y : LongInt; L, V : String);
Begin
  OutTxt(ListW + 30, Y, Fr(L), $303030, $E8E8E8);
  OutTxt(ListW + 190, Y, Copy(V, 1, (MgrW - ListW - 210) Div 8), $101010, $E8E8E8);
End;

Function MethodLong(M : LongInt) : String;
Begin
  Case M Of
    VXM_SVM : MethodLong := 'AMD-V (SVM) avec NPT';
    VXM_VMX : MethodLong := 'Intel VT-x avec EPT';
  Else
    MethodLong := 'Mode virtuel 8086 (plan B)';
  End;
End;

Procedure MgrPaint(H : LongInt);
Var Rc : Array[0..3] Of LongInt; Y, Best : LongInt; V : TVm; S : String;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  CW := Rc[2]; CH := Rc[3];
  RgbMode;
  FBar(0, 0, CW - 1, TbH - 1, $CCCCCC);
  Edge(0, TbH - 2, CW - 1, TbH - 1, $808080, $FFFFFF);
  FBar(0, TbH, ListW + 11, CH - 1, $CCCCCC);
  FBar(ListW + 12, TbH, CW - 1, CH - 1, $E8E8E8);
  Edge(ListW + 12, TbH + 6, CW - 7, CH - 7, $808080, $FFFFFF);
  Best := KrnVirt(VX_INFO, 0, 0);
  If (CurSel < 0) Or (CurSel >= NVm) Then
  Begin
    OutTxt(ListW + 30, TbH + 30, Fr('Bienvenue dans Virtualisation !'), $000080, $E8E8E8);
    OutTxt(ListW + 30, TbH + 60, Fr('Cr`eez une machine (Nouvelle) ou copiez une machine de'), $101010, $E8E8E8);
    OutTxt(ListW + 30, TbH + 78, Fr('VirtualBox (.vbox, .vhd, .vdi) dans le dossier C:\VMS.'), $101010, $E8E8E8);
    OutTxt(ListW + 30, TbH + 110, Fr('M`ethode de ce processeur : ') + Fr(MethodLong(Best)), $101010, $E8E8E8);
  End
  Else
  Begin
    V := Vms[CurSel];
    DrawPc(ListW + 30, TbH + 18, (VmFrame <> 0) And (CurSel = CurVm));
    OutTxt(ListW + 84, TbH + 20, V.Name, $000080, $E8E8E8);
    If (VmFrame <> 0) And (CurSel = CurVm) Then S := 'En fonction' Else S := '`Eteinte';
    OutTxt(ListW + 84, TbH + 38, Fr(S), $101010, $E8E8E8);
    Y := TbH + 66;
    Section(Y, 'G`en`eral'); Y := Y + 24;
    Field(Y, 'Nom :', V.Name); Y := Y + 18;
    If V.Distro <> '' Then S := V.Distro + ' (' + V.OsType + ')' Else S := V.OsType;
    Field(Y, 'Syst`eme :', S); Y := Y + 22;
    Section(Y, 'Syst`eme'); Y := Y + 24;
    Field(Y, 'M`emoire vive :', IStr(V.MemMb) + ' Mo'); Y := Y + 18;
    If V.BootCd <> 0 Then S := 'CD-ROM, disque dur'
    Else If V.BootFd <> 0 Then S := 'Disquette, disque dur' Else S := 'Disque dur, disquette';
    Field(Y, 'Ordre d''amor`cage :', S); Y := Y + 18;
    Field(Y, 'Acc`el`eration :', Fr(MethodLong(Best))); Y := Y + 22;
    Section(Y, 'Stockage'); Y := Y + 24;
    If V.Hd0 <> '' Then S := NameOf(V.Hd0) + ' (' + DiskFmt(V.Hd0) + ')' Else S := Fr('vide');
    Field(Y, 'IDE primaire 0 :', S); Y := Y + 18;
    If V.Hd1 <> '' Then Begin Field(Y, 'IDE primaire 1 :', NameOf(V.Hd1)); Y := Y + 18; End;
    If V.Cd <> '' Then Begin Field(Y, 'IDE secondaire 0 :', NameOf(V.Cd) + ' (CD-ROM)'); Y := Y + 18; End;
    If V.Fd <> '' Then S := NameOf(V.Fd) Else S := Fr('vide');
    Field(Y, 'Disquette :', S); Y := Y + 22;
    Section(Y, 'Fichier'); Y := Y + 24;
    Field(Y, '', Copy(V.Vbox, 1, 40));
  End;
  Dummy := WinEndPaint(Hps);
End;

Procedure MgrCommand(Id : LongInt);
Var S : String; K : LongInt;
Begin
  Case Id Of
    CM_NEW, ID_BNEW : ShowCfg(-1);
    CM_SETTINGS, ID_BSET : If (CurSel >= 0) And (CurSel < NVm) Then
                           Begin
                             If (VmFrame <> 0) And (CurSel = CurVm) Then
                               Dummy := Ask('`Eteignez la machine avant de la configurer.', 'Virtualisation',
                                            MB_OK Or MB_ICONWARNING, MgrFrame)
                             Else ShowCfg(CurSel);
                           End;
    CM_START, ID_BSTART : StartVm(CurSel);
    CM_INFO, ID_BINFO : ShowInfo;
    CM_REMOVE, ID_BDEL :
      If (CurSel >= 0) And (CurSel < NVm) And Not ((VmFrame <> 0) And (CurSel = CurVm)) Then
        If Ask('Retirer la machine ' + Vms[CurSel].Name + ' de la liste ? (ses fichiers sont gard`es)',
               'Virtualisation', MB_YESNO Or MB_ICONQUESTION, MgrFrame) = MBID_YES Then
        Begin
          For K := CurSel To NVm - 2 Do Vms[K] := Vms[K + 1];
          Dec(NVm);
          If CurSel >= NVm Then CurSel := NVm - 1;
          IniWrite('Machine' + IStr(NVm), '');
          RegSave;
          FillList;
          Dummy := WinInvalidateRect(MgrClient, 0, 0);
        End;
    CM_REFRESH : Begin ScanDir(VmsDir, 0); RegSave; FillList; Dummy := WinInvalidateRect(MgrClient, 0, 0); End;
    CM_ADD : Begin
               S := 'C:\VMS';
               Dummy := Ask('Copiez le fichier .vbox (et ses disques) ou un disque .vhd/.vdi dans le dossier ' +
                            'C:\VMS puis choisissez Machine > Actualiser : la machine est ajout`ee.',
                            'Ajouter une machine', MB_OK Or MB_INFORMATION, MgrFrame);
             End;
    CM_QUIT : Dummy := WinPostMsg(MgrClient, WM_QUIT, 0, 0);
    CM_HELP : Begin
                LClr;
                LLine(Fr('Virtualisation ex`ecute des machines virtuelles de VirtualBox (.vbox, .vhd, .vdi).'));
                LLine('');
                LLine(Fr('- Nouvelle : cr`ee une machine (et au besoin un disque VHD dynamique).'));
                LLine(Fr('- Configuration : m`emoire, disques, disquette, ordre d''amor`cage.'));
                LLine(Fr('- D`emarrer : ouvre la fen`etre de la machine ; le clavier y est remis `a l''invite.'));
                LLine(Fr('- Machine > Information de virtualisation : m`ethode et d`etails techniques.'));
                LLine('');
                LLine(Fr('Les machines de C:\VMS sont trouv`ees au d`emarrage (Machine > Actualiser).'));
                Dummy := LMsgBox('Aide de Virtualisation', MB_OK Or MB_INFORMATION, MgrFrame);
              End;
    CM_ABOUT : VmCommand(CM_ABOUT);
  End;
End;

Function MgrProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Var N : LongInt;
Begin
  MgrProc := 0;
  Case Msg0 Of
    WM_PAINT : MgrPaint(H);
    WM_COMMAND : MgrCommand(Lo16(Mp1));
    WM_CONTROL : If Lo16(Mp1) = ID_LIST Then
                 Begin
                   N := WinSendMsg(ListBox, LM_QUERYSELECTION, -1, 0);
                   If (N >= 0) And (N < NVm) And (N <> CurSel) Then
                   Begin
                     CurSel := N;
                     Dummy := WinInvalidateRect(H, 0, 0);
                   End;
                   If Hi16(Mp1) = 5 Then StartVm(CurSel);
                 End;
    WM_VMTITLE : FillList;
    WM_CLOSE : Begin
                 If VmFrame <> 0 Then
                 Begin
                   If Ask('Une machine est en fonction. L''`eteindre et quitter ?', 'Virtualisation',
                          MB_YESNO Or MB_ICONQUESTION, MgrFrame) <> MBID_YES Then Exit;
                   VmReqStop := 1;
                   N := 0;
                   While (VmState <> VS_OFF) And (N < 300) Do
                   Begin
                     Dummy := DosSleep(10);
                     Inc(N);
                   End;
                 End;
                 Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
               End;
  Else
    MgrProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
  End;
End;

Procedure ShowManager;
Var Flg, H0, H1, M : LongInt;
Begin
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  MgrClient := 0;
  MgrFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('VBOXMAIN'), Z2('Virtualisation'), 0, 0, 0,
                                 LongInt(@MgrClient));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 1000, '~Fichier');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle machine...');
  MItem(MIS_TEXT, 0, CM_ADD, '~Ajouter une machine...');
  MItem(MIS_TEXT, 0, CM_REMOVE, '~Retirer la machine');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 1100, '~Machine');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_START, '~D`emarrer');
  MItem(MIS_TEXT, 0, CM_SETTINGS, '~Configuration...');
  MItem(MIS_TEXT, 0, CM_REFRESH, '~Actualiser');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_INFO, '~Information de virtualisation...');
  MenuClose(H1, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 1300, 'A~ide');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_HELP, '~Aide de Virtualisation');
  MItem(MIS_TEXT, 0, CM_ABOUT, '`~A propos de Virtualisation');
  MenuClose(H1, 2);
  MenuClose(H0, 3);
  M := WinCreateMenu(MgrFrame, LongInt(@MenuT));
  { ecran de 640 x 480 : fenetre et boutons plus etroits }
  If WinQuerySysValue(HWND_DESKTOP, 20) < 800 Then
  Begin
    MgrW := 624; MgrH := 400; ListW := 170;
  End
  Else
  Begin
    MgrW := 780; MgrH := 470; ListW := 250;
  End;
  CenterFrame(MgrFrame, MgrW, MgrH);
  CH := MgrH;
  BtnNew := Ctl(MgrClient, WC_BUTTON, '~Nouvelle', BS_PUSHBUTTON, 8, 8, 90, 28, ID_BNEW);
  BtnSet := Ctl(MgrClient, WC_BUTTON, '~Configuration', BS_PUSHBUTTON, 104, 8, 120, 28, ID_BSET);
  BtnDel := Ctl(MgrClient, WC_BUTTON, '~Retirer', BS_PUSHBUTTON, 230, 8, 80, 28, ID_BDEL);
  BtnStart := Ctl(MgrClient, WC_BUTTON, '~D`emarrer', BS_PUSHBUTTON, 316, 8, 90, 28, ID_BSTART);
  If MgrW < 700 Then
    BtnInfo := Ctl(MgrClient, WC_BUTTON, '~Information', BS_PUSHBUTTON, 412, 8, 110, 28, ID_BINFO)
  Else
    BtnInfo := Ctl(MgrClient, WC_BUTTON, '~Information de virtualisation', BS_PUSHBUTTON, 412, 8, 250, 28, ID_BINFO);
  ListBox := Ctl(MgrClient, WC_LISTBOX, '', WS_TABSTOP, 8, TbH + 6, ListW, MgrH - TbH - 14, ID_LIST);
  FillList;
  Dummy := WinSetFocus(HWND_DESKTOP, ListBox);
End;

{ ==================================================================== }
{ Essais (/TEST)                                                        }
{ ==================================================================== }

Function ScreenLine(R : LongInt) : String;
Var S : String; C, V : LongInt;
Begin
  S := '';
  For C := 0 To 79 Do
  Begin
    V := GB($B8000 + (R * 80 + C) * 2);
    If (V >= 32) And (V < 127) Then S := S + Chr(V) Else S := S + ' ';
  End;
  ScreenLine := TrimS(S);
End;

Procedure RunTests;
Var Ok, N, K, T0, Best, E : LongInt; V : TVm; Err, S : String; Key : Boolean;
Begin
  Ok := 0; N := 0;
  LoadFonts;
  Best := KrnVirt(VX_INFO, LongInt(@Info), 0);
  Log('VIRTUAL : methode ' + MethodName(Best) + ', ' + GetZ(LongInt(@Info) + 161) + ', drapeaux ' + Hex(Info[2], 4));
  { 1 : disque VHD dynamique cree, secteur d'amorce ecrit (allocation d'un bloc) }
  Inc(N);
  Dummy := DosDelete(Z('D:\VXTEST.VHD'));
  If VhdCreate('D:\VXTEST.VHD', 16) And DkOpen(0, 'D:\VXTEST.VHD') Then
  Begin
    ZeroB(LongInt(@SecBuf), 512);
    For K := 0 To 511 Do SecBuf[K] := 0;
    T0 := 0;
    For E := 1 To 3 Do
    Begin
    If E = 1 Then S := TBoot1 Else If E = 2 Then S := TBoot2 Else S := TBoot3;
    K := 1;
    While K < Length(S) Do
    Begin
      SecBuf[T0 + (K - 1) Div 2] := (Pos(S[K], '0123456789ABCDEF') - 1) * 16 + Pos(S[K + 1], '0123456789ABCDEF') - 1;
      K := K + 2;
    End;
    T0 := T0 + Length(S) Div 2;
    End;
    SecBuf[510] := $55; SecBuf[511] := $AA;
    If DkWriteSec(0, 0, LongInt(@SecBuf)) Then
    Begin
      For K := 0 To 511 Do SecBuf[K] := $5A;
      If DkWriteSec(0, 1, LongInt(@SecBuf)) Then
      Begin
        DkClose(0);
        If DkOpen(0, 'D:\VXTEST.VHD') And DkReadSec(0, 1, LongInt(@SecBuf)) And (SecBuf[0] = $5A) Then
        Begin
          Inc(Ok);
          Log('VIRTUAL : TEST1 VHD dynamique ' + IStr(DkSect[0] Div 2048) + ' Mo, CHS ' + IStr(DkCyl[0]) + '/' +
              IStr(DkHeads[0]) + '/' + IStr(DkSpt[0]) + ', blocs ' + IStr(DkNBlk[0]));
        End;
      End;
    End;
  End;
  DkCloseAll;
  { 2 : fichier .vbox ecrit puis relu }
  Inc(N);
  V.Used := True; V.Name := 'Essai DOS'; V.OsType := 'DOS'; V.MemMb := 4; V.Hd0 := 'D:\VXTEST.VHD'; V.Hd1 := '';
  V.Fd := ''; V.BootFd := 0; V.Uuid := ''; V.Hd0Uuid := ''; V.Hd1Uuid := ''; V.Vbox := 'D:\VXTEST.VBOX';
  V.Cd := ''; V.CdUuid := ''; V.BootCd := 0; V.Distro := '';
  If VmSave(V) And VmLoad('D:\VXTEST.VBOX', Vms[0]) Then
    If (Vms[0].Name = 'Essai DOS') And (Vms[0].MemMb = 4) And (UpS(Vms[0].Hd0) = 'D:\VXTEST.VHD') Then
    Begin
      Inc(Ok);
      Log('VIRTUAL : TEST2 .vbox ' + Vms[0].Name + ' ' + IStr(Vms[0].MemMb) + ' Mo ' + Vms[0].Hd0);
    End;
  NVm := 1;
  { 3 : amorcage de l'invite, BIOS, minuterie, clavier, mode 13h }
  Inc(N);
  If VmOpen(0, Err) Then
  Begin
    Log('VIRTUAL : machine creee, ' + MethodName(VmMethod) + ', memoire ' + Hex(GMem, 8));
    T0 := NowMs; Key := False;
    While (VmHalted = 0) And (NowMs - T0 < 30000) Do
    Begin
      VmStep;
      If (Pos('R', DbgLine) > 0) And (Err = '') Then Err := ScreenLine(2);
      If Not Key And (Pos('T', DbgLine) > 0) Then
      Begin
        KbKey($1E); KbKey($9E);
        Key := True;
      End;
    End;
    Log('VIRTUAL : invite "' + DbgLine + '" ' + IStr(VmExits) + ' sorties, ' + IStr(VmIrqs) + ' interruptions');
    Log('VIRTUAL : ecran "' + Err + '" / "' + ScreenLine(0) + '"');
    If VmMsg <> '' Then Log('VIRTUAL : ' + VmMsg);
    If ((DbgLine = 'RWTaGXA.') Or ((VmMethod = VXM_V86) And (DbgLine = 'RWTaGX-.'))) And (Err = 'Machine virtuelle : amorcage du disque') And
       (ScreenLine(0) = 'Essai termine.') Then
    Begin
      Inc(Ok);
      Log('VIRTUAL : TEST3 invite R(lecture) W(ecriture) T(minuterie) a(clavier) G(mode 13h) X(INT 15h) A(ligne A20)');
    End;
    { 4 : information de virtualisation }
    Inc(N);
    BuildInfo;
    If (InfoN > 10) And (Info[12] = VmMethod) And (Info[17] > 0) Then
    Begin
      Inc(Ok);
      Log('VIRTUAL : TEST4 information ' + IStr(InfoN) + ' lignes, ' + IStr(Info[17]) + ' sorties du noyau');
    End;
    VmClose;
  End
  Else Log('VIRTUAL : machine non creee : ' + Err);
  { 5 : ecriture de l'invite conservee dans le VHD }
  Inc(N);
  If DkOpen(0, 'D:\VXTEST.VHD') And DkReadSec(0, 3000, LongInt(@SecBuf)) Then
    If (SecBuf[0] = $34) And (SecBuf[1] = $12) Then
    Begin
      Inc(Ok);
      Log('VIRTUAL : TEST5 secteur 3000 ecrit par l''invite relu');
    End;
  DkCloseAll;
  Log('VIRTUAL : ' + IStr(Ok) + '/' + IStr(N) + ' essais reussis');
End;

{ diagnostic : demarrer un disque sans fenetre (/BOOTTEST:disque), taper
  /KEYS:texte apres /WAIT:n secondes, puis journal de l'ecran sur COM1 }
Var
  BootHd : String;
  BootHdMb, BootMem, BootRun, NewDlg : LongInt;
  BootShot : String;

{ ecran de l'invite dans un fichier BMP de 8 bits (essais) }
Procedure ShotBmp(Path : String);
Var H, Pos, Sz, Off : LongInt; Hd : Array[0..53] Of Byte; S : String;
Begin
  InitBmi;
  RenderScreen;
  ScrH := DispH;
  If UpS(Path) = 'COM' Then
  Begin
    { image brute sur COM1 : en-tete puis lignes hexadecimales }
    Log('SHOT ' + IStr(SW_) + ' ' + IStr(ScrH));
    For Pos := 0 To 255 Do
      Log('PAL ' + Hex(RdB(LongInt(@Bmi) + 16 + Pos * 4 + 2), 2) + Hex(RdB(LongInt(@Bmi) + 16 + Pos * 4 + 1), 2) +
          Hex(RdB(LongInt(@Bmi) + 16 + Pos * 4), 2));
    For Sz := 0 To ScrH - 1 Do
    Begin
      { ligne Sz depuis le haut }
      Off := (SH_ - 1 - Sz) * SW_;
      For H := 0 To 7 Do
      Begin
        S := 'PIX ' + IStr(Sz) + ' ';
        For Pos := 0 To 79 Do S := S + Hex(Fb[Off + H * 80 + Pos], 2);
        Log(S);
      End;
    End;
    Exit;
  End;
  H := FCreate(Path);
  If H < 0 Then Exit;
  Off := 54 + 1024;
  Sz := Off + SW_ * ScrH;
  FillChar(Hd, SizeOf(Hd), 0);
  Hd[0] := Ord('B'); Hd[1] := Ord('M');
  WrL(LongInt(@Hd) + 2, Sz); WrL(LongInt(@Hd) + 10, Off);
  WrL(LongInt(@Hd) + 14, 40); WrL(LongInt(@Hd) + 18, SW_); WrL(LongInt(@Hd) + 22, ScrH);
  WrW(LongInt(@Hd) + 26, 1); WrW(LongInt(@Hd) + 28, 8); WrL(LongInt(@Hd) + 34, SW_ * ScrH);
  Pos := 0;
  If FWrite(H, Pos, LongInt(@Hd), 54) Then ;
  { palette : celle du BITMAPINFO de PM (bleu, vert, rouge, 0) }
  If FWrite(H, 54, LongInt(@Bmi) + 16, 1024) Then ;
  { lignes du bas vers le haut : les ScrH lignes du haut de l'image }
  If FWrite(H, Off, LongInt(@Fb) + (SH_ - ScrH) * SW_, SW_ * ScrH) Then ;
  Dummy := DosClose(H);
End;

Procedure BootTest(Path, Keys : String; Wait : LongInt);
Var T0, K, Step : LongInt; Err, S : String;
Begin
  LoadFonts;
  Vms[0].Used := True; Vms[0].Name := BaseOf(Path); Vms[0].OsType := 'DOS'; Vms[0].Hd0 := Path; Vms[0].Hd1 := '';
  Vms[0].Fd := ''; Vms[0].BootFd := 0; Vms[0].Vbox := '';
  Vms[0].Cd := ''; Vms[0].CdUuid := ''; Vms[0].BootCd := 0; Vms[0].Distro := '';
  NVm := 1;
  Vms[0].MemMb := BootMem;
  If ExtOf(Path) = 'ISO' Then
  Begin
    { CD-ROM d'installation : amorce par le CD, disque dur /HD: (cree par
      /HDMB:n s'il n'existe pas) }
    Vms[0].Cd := Path; Vms[0].BootCd := 1; Vms[0].Hd0 := BootHd;
    If (BootHd <> '') And Not FExists(BootHd) And (BootHdMb > 0) Then
      If Not VhdCreate(BootHd, BootHdMb) Then Log('VIRTUAL : impossible de creer ' + BootHd);
  End;
  If Not VmOpen(0, Err) Then
  Begin
    Log('VIRTUAL : ' + Err);
    Exit;
  End;
  If Vms[0].Cd <> '' Then
    Log('VIRTUAL : CD-ROM ' + Path + ' (' + IStr(DkSect[DkCd] Div 4) + ' secteurs, El Torito ' + IStr(CdEmu) +
        ', image ' + IStr(CdBootLba) + ', ' + IStr(CdBootCnt) + ' secteurs en ' + Hex(CdLoadSeg, 4) + 'h)');
  If DkH[0] >= 0 Then
    Log('VIRTUAL : ' + DkPath[0] + ' (' + DkFmt[0] + ', ' + IStr(DkSect[0] Div 2048) + ' Mo, CHS ' + IStr(DkCyl[0]) + '/' +
        IStr(DkHeads[0]) + '/' + IStr(DkSpt[0]) + ') par ' + MethodName(VmMethod));
  T0 := NowMs; Step := 0;
  While (NowMs - T0 < (Wait + BootRun) * 1000) And (VmReqStop = 0) Do
  Begin
    VmStep;
    If (Step = 0) And (NowMs - T0 > Wait * 1000) Then
    Begin
      TypeText(Keys);
      Step := 1;
    End;
  End;
  Log('VIRTUAL : ' + IStr(VmExits) + ' sorties, ' + IStr(VmIrqs) + ' interruptions, ' + IStr(VmSvc) +
      ' services, ' + IStr(MmioCnt) + ' instructions VGA emulees, disque ' + IStr(DkReads[0]) + ' lectures ' +
      IStr(DkWrites[0]) + ' ecritures, CD ' +
      IStr(DkReads[DkCd] + DkReads[DkEmu]) + ' lectures, mode ' + Hex(BdaB($49), 2));
  If VmMsg <> '' Then Log('VIRTUAL : ' + VmMsg);
  If BootShot <> '' Then ShotBmp(BootShot);
  If DbgLine <> '' Then Log('VIRTUAL : port E9h "' + DbgLine + '"');
  S := '';
  For K := 0 To 255 Do If SvcCnt[K] > 0 Then S := S + ' ' + Hex(K, 2) + 'h:' + IStr(SvcCnt[K]);
  Log('VIRTUAL : services' + S);
  S := '';
  For K := 0 To 1023 Do If (PortCnt[K] > 100) And (Length(S) < 200) Then S := S + ' ' + Hex(K, 3) + 'h:' + IStr(PortCnt[K]);
  Log('VIRTUAL : ports' + S);
  For K := 0 To 24 Do
  Begin
    S := ScreenLine(K);
    If S <> '' Then Log('ECRAN ' + IStr(K) + ' : ' + S);
  End;
  VmClose;
End;

{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

Var
  K, E, Best : LongInt;
  S, StartName, BootPath, BootKeys, AddPath : String;
  BootWait : LongInt;
  Dt : Array[0..15] Of Byte;

BEGIN
  InDlg := 0; TestMode := 0; TraceOn := 0; NVm := 0; CurVm := -1; CurSel := -1; VmFrame := 0; VmWin := 0; MgrClient := 0;
  InfoFrame := 0; CfgFrame := 0; DwFrame := 0; PickFrame := 0; PopMenu := 0; PopUntil := 0; GMem := 0; VmsRootS := ''; VmState := VS_OFF; StartName := ''; BootPath := ''; BootKeys := ''; AddPath := ''; BootWait := 30;
  BootHd := ''; BootHdMb := 0; BootMem := 32; BootRun := 20; NewDlg := 0; BootShot := '';
  For K := 0 To NDk - 1 Do DkH[K] := -1;
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  For K := 1 To ParamCount Do
  Begin
    S := UpS(ParamStr(K));
    If S = '/TEST' Then TestMode := 1;
    If S = '/TRACE' Then TraceOn := 1;
    If S = '/NEW' Then NewDlg := 1;
    If Copy(S, 1, 7) = '/START:' Then StartName := Copy(ParamStr(K), 8, 255);
    If Copy(S, 1, 10) = '/BOOTTEST:' Then BootPath := Copy(ParamStr(K), 11, 255);
    If Copy(S, 1, 5) = '/ADD:' Then AddPath := Copy(ParamStr(K), 6, 255);
    If Copy(S, 1, 6) = '/KEYS:' Then
    Begin
      { le texte continue sur les mots suivants (espaces) jusqu'au prochain parametre }
      BootKeys := Copy(ParamStr(K), 7, 255);
      E := K + 1;
      While (E <= ParamCount) And (Copy(ParamStr(E), 1, 1) <> '/') Do
      Begin
        BootKeys := BootKeys + ' ' + ParamStr(E);
        Inc(E);
      End;
    End;
    If Copy(S, 1, 6) = '/WAIT:' Then BootWait := SVal(Copy(S, 7, 9));
    If Copy(S, 1, 4) = '/HD:' Then BootHd := Copy(ParamStr(K), 5, 255);
    If Copy(S, 1, 6) = '/HDMB:' Then BootHdMb := SVal(Copy(S, 7, 9));
    If Copy(S, 1, 5) = '/MEM:' Then BootMem := SVal(Copy(S, 6, 9));
    If Copy(S, 1, 5) = '/RUN:' Then BootRun := SVal(Copy(S, 6, 9));
    If Copy(S, 1, 6) = '/SHOT:' Then BootShot := Copy(ParamStr(K), 7, 250);
    If Copy(S, 1, 5) = '/VMS:' Then
    Begin
      VmsRootS := Copy(ParamStr(K), 6, 250);
      If Copy(VmsRootS, Length(VmsRootS), 1) <> '\' Then VmsRootS := VmsRootS + '\';
      Dummy := DosCreateDir(Z(Copy(VmsRootS, 1, Length(VmsRootS) - 1)), 0);
    End;
  End;
  StartKeys := BootKeys;
  If BootPath <> '' Then
  Begin
    BootTest(BootPath, BootKeys, BootWait);
    Halt(0);
  End;
  If TestMode <> 0 Then
  Begin
    RunTests;
    Halt(0);
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  Best := KrnVirt(VX_INFO, LongInt(@Info), 0);
  If (Best < VXM_SVM) Or (Best > VXM_V86) Then
  Begin
    Dummy := WinMessageBox(HWND_DESKTOP, HWND_DESKTOP,
      Z(Fr('Ce processeur n''offre aucune m`ethode de virtualisation (AMD-V, Intel VT-x ou mode V86) : ' +
           'Virtualisation ne peut pas d`emarrer.')), Z2('Virtualisation'), 0, MB_OK Or MB_ERROR Or MB_MOVEABLE);
    Halt(1);
  End;
  LoadFonts;
  Dummy := WinRegisterClass(Hab, Z('VBOXMAIN'), LongInt(@MgrProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('VBOXVM'), LongInt(@VmProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('VBOXINFO'), LongInt(@InfoProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('VBOXCFG'), LongInt(@CfgProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('VBOXDL'), LongInt(@DwProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('VBOXPICK'), LongInt(@PickProc), 0, 0);
  RegLoad;
  If AddPath <> '' Then
  Begin
    If ExtOf(AddPath) = 'VBOX' Then K := VmAddFile(AddPath) Else K := VmFromDisk(AddPath);
    If K >= 0 Then RegSave;
  End;
  If NVm > 0 Then CurSel := 0;
  ShowManager;
  If NewDlg <> 0 Then ShowCfg(-1);
  If StartName <> '' Then
    For K := 0 To NVm - 1 Do
      If UpS(Vms[K].Name) = UpS(StartName) Then
      Begin
        CurSel := K;
        FillList;
        StartVm(K);
      End;
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  If VmFrame <> 0 Then
  Begin
    VmReqStop := 1;
    E := 0;
    While (VmState <> VS_OFF) And (E < 300) Do
    Begin
      Dummy := DosSleep(10);
      Inc(E);
    End;
  End;
  Dummy := WinDestroyWindow(MgrFrame);
END.
