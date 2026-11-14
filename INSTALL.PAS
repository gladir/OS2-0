{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: INSTALL - programme d'installation graphique d'OS/2-0 sur
                un disque dur (CD-ROM d'installation IMAGE/OS2INST.ISO).
}

Program INSTALL;

{$R-,S-,I-}

{ Compilation : OS2PC INSTALL.PAS   (produit INSTALL.EXE)

  INSTALL.EXE est le processeur de commandes (PROTSHELL) du CD-ROM
  d'installation IMAGE/OS2INST.ISO : OS/2-0 demarre directement dans ce
  programme de Presentation Manager, a l'apparence de l'installation
  d'OS/2 Warp 3 (fenetres sur fond turquoise). Etapes :

    1. Bienvenue : installation facile (disque entier, choix par defaut)
       ou avancee ;
    2. Configuration du systeme (le tableau de bord de Warp 3) : pays,
       clavier, LANGUE (nouveau : francais par defaut, anglais, allemand,
       espagnol, italien, albanais, portugais, suedois, danois, japonais
       en romaji ; CONFIG.SYS recoit SET LANGUAGE=FR, EN, GR, SP, IT,
       ALB, PT, SE, DK ou JP ; l'assistant change aussitot de langue, les
       quatre dernieres etant affichees en anglais), souris, port serie,
       affichage principal (VGA ou mode VESA :
       SET PMRESOLUTION=), affichage secondaire, gestion de
       l'alimentation, PCMCIA, CD-ROM, imprimante, multimedia, SCSI ;
       cliquer sur l'icone d'un choix ouvre la liste des valeurs, les
       champs a fleches changent de valeur ;
    3. Partitionnement du disque dur (comme FDISK) : disques IDE,
       partitions principales et espace libre, creation d'une partition
       HPFS (taille en Mo), suppression, choix de la partition ;
    4. Formatage : HPFS (FS_FSCTL 8000h de HPFS.IFS, par le noyau :
       KrnDiskCtl), nom du volume, ou conservation des fichiers d'une
       partition HPFS existante ;
    5. Composants : bureau et LaunchPad, utilitaires, programmes
       d'essai, disque virtuel, jeux (Solitaire - Klondike, Echecs,
       Mahjongg : dossier Jeux de Systeme OS/2), multimedia (Audio
       numerique, MDM.DLL, pilotes des cartes son, sons) ;
    6. Transfert des fichiers (barre de progression aux logos OS/2) :
       copie des fichiers du CD-ROM, CONFIG.SYS du disque dur, zone
       d'amorcage (secteurs 1 et suivants du disque : repertoire
       'OS20BOOT', OS2LDR, OS2KRNL, HPFS.IFS) et secteur d'amorce
       principal (KERNEL/HDBOOT.ASM : tableau MbrCode) avec la partition
       active ;
    7. Fin : retirer le CD-ROM et redemarrer ; OS/2-0 demarre alors du
       disque dur (C: = la partition HPFS).

  Parametres : /AUTO (installation facile sans question, pour les
  essais), /LANG:xx (langue de l'assistant). }

Const
  { messages }
  WM_CREATE = $0001; WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024;
  WM_CLOSE = $0029; WM_CONTROL = $0030; WM_ACTIVATE = $000D; WM_BUTTON1DOWN = $0071; WM_CHAR = $007A; WM_USER = $1000;
  WM_DOFORMAT = $1001; WM_DOAUTO = $1002; WM_OPENCHOICE = $1003;
  { styles et fenetres }
  WS_VISIBLE = $80000000; WS_GROUP = $00010000; WS_TABSTOP = $00020000;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_DLGBORDER = $200;
  HWND_DESKTOP = 1; HWND_TOP = 3; HWND_BOTTOM = 4;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  WC_BUTTON = $FFFF0003; WC_ENTRYFIELD = $FFFF0006; WC_LISTBOX = $FFFF0007;
  BS_PUSHBUTTON = 0; BS_AUTOCHECKBOX = 2; BS_AUTORADIOBUTTON = 4; BS_DEFAULT = $0400;
  ES_AUTOSCROLL = 4; ES_MARGIN = 8;
  BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
  LM_INSERTITEM = $0161; LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165; LM_DELETEALL = $016E;
  LN_SELECT = 1; LN_ENTER = 5;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_WARNING = $20; MB_ERROR = $40; MB_MOVEABLE = $4000;
  MBID_YES = 6;
  KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_KEYUP = $40; VK_TAB = 6; VK_BACKTAB = 7; VK_UP = $16; VK_DOWN = $18;
  VK_ESC = $0F; VK_F1 = $20;
  { couleurs }
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  { pages de l'assistant }
  PG_WELCOME = 0; PG_CONFIG = 1; PG_DISK = 2; PG_FORMAT = 3; PG_COMP = 4; PG_COPY = 5; PG_DONE = 6;
  { commandes }
  ID_EASY = 101; ID_ADV = 102; ID_QUIT = 103; ID_OK = 110; ID_HELP = 111; ID_BACK = 112;
  ID_PLIST = 200; ID_PSIZE = 201; ID_PCREATE = 202; ID_PDELETE = 203; ID_PINSTALL = 205; ID_PPREV = 207;
  ID_PNEXT = 208;
  ID_FHPFS = 300; ID_FFAT = 301; ID_FKEEP = 302; ID_FLABEL = 303; ID_FGO = 310;
  ID_CBASE = 400; ID_CDESK = 401; ID_CUTIL = 402; ID_CTEST = 403; ID_CRAM = 404; ID_CGAMES = 405; ID_CMM = 406; ID_CGO = 410;
  ID_REBOOT = 600;
  ID_CHLIST = 700; ID_CHOK = 701; ID_CHCANCEL = 702;
  { configuration du systeme : choix }
  CF_COUNTRY = 0; CF_KBD = 1; CF_LANG = 2; CF_MOUSE = 3; CF_SERIAL = 4; CF_DISP = 5; CF_DISP2 = 6;
  CF_APM = 7; CF_PCMCIA = 8; CF_CDROM = 9; CF_PRINTER = 10; CF_MMEDIA = 11; CF_SCSI = 12;
  NCfg = 13;
  { disque : zone d'amorcage (secteurs 1 a 8191), premiere partition creee }
  FirstLba = 8192;
  MinFree = 4096;
  { etapes du transfert }
  CS_LIST = 0; CS_FILE = 1; CS_DIRS = 2; CS_BOOT = 3; CS_MBR = 4; CS_END = 5;
  MaxFiles = 200;
  ChunkSize = 32768;

  { secteur d'amorce principal : code de KERNEL/HDBOOT.ASM (446 octets) }
  MbrCode : Array[0..445] Of Byte = (
    $FA, $31, $C0, $8E, $D8, $8E, $C0, $8E, $D0, $BC, $00, $7C, $FB, $FC, $88, $16, $93, $7D, $BE, $31,
    $7D, $E8, $04, $01, $BE, $BE, $7D, $B9, $04, $00, $F6, $04, $80, $75, $0B, $83, $C6, $10, $E2, $F6,
    $BE, $39, $7D, $E9, $FD, $00, $66, $8B, $44, $08, $66, $A3, $38, $05, $66, $8B, $44, $0C, $66, $A3,
    $3C, $05, $B4, $41, $BB, $AA, $55, $8A, $16, $93, $7D, $CD, $13, $72, $06, $81, $FB, $55, $AA, $74,
    $06, $BE, $51, $7D, $E9, $D4, $00, $C7, $06, $96, $7D, $01, $00, $C7, $06, $98, $7D, $00, $00, $C7,
    $06, $9A, $7D, $00, $10, $66, $C7, $06, $9C, $7D, $01, $00, $00, $00, $E8, $94, $00, $1E, $B8, $00,
    $10, $8E, $D8, $66, $81, $3E, $00, $00, $4F, $53, $32, $30, $75, $7D, $66, $81, $3E, $04, $00, $42,
    $4F, $4F, $54, $75, $72, $66, $A1, $20, $00, $66, $8B, $1E, $24, $00, $1F, $66, $A3, $0C, $05, $66,
    $89, $1E, $10, $05, $66, $A3, $9C, $7D, $66, $81, $C3, $FF, $01, $00, $00, $66, $C1, $EB, $09, $66,
    $83, $FB, $7F, $76, $03, $BB, $7F, $00, $89, $1E, $96, $7D, $C7, $06, $98, $7D, $00, $00, $C7, $06,
    $9A, $7D, $00, $20, $E8, $3A, $00, $C7, $06, $00, $05, $4F, $42, $A0, $93, $7D, $A2, $02, $05, $C6,
    $06, $03, $05, $00, $66, $C7, $06, $04, $05, $01, $00, $00, $00, $66, $C7, $06, $08, $05, $00, $02,
    $00, $00, $C7, $06, $34, $05, $48, $44, $8A, $16, $93, $7D, $30, $F6, $EA, $00, $00, $00, $20, $1F,
    $BE, $69, $7D, $EB, $22, $BE, $94, $7D, $8A, $16, $93, $7D, $B4, $42, $CD, $13, $72, $01, $C3, $BE,
    $81, $7D, $EB, $0F, $AC, $08, $C0, $74, $09, $B4, $0E, $BB, $07, $00, $CD, $10, $EB, $F2, $C3, $E8,
    $EE, $FF, $F4, $EB, $FD, $4F, $53, $2F, $32, $2D, $30, $20, $00, $50, $61, $73, $20, $64, $65, $20,
    $70, $61, $72, $74, $69, $74, $69, $6F, $6E, $20, $61, $63, $74, $69, $76, $65, $00, $49, $4E, $54,
    $20, $31, $33, $68, $20, $65, $74, $65, $6E, $64, $75, $65, $20, $61, $62, $73, $65, $6E, $74, $65,
    $00, $5A, $6F, $6E, $65, $20, $64, $27, $61, $6D, $6F, $72, $63, $61, $67, $65, $20, $61, $62, $73,
    $65, $6E, $74, $65, $00, $45, $72, $72, $65, $75, $72, $20, $64, $65, $20, $6C, $65, $63, $74, $75,
    $72, $65, $00, $00, $10, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00);

Var
  Hab, Hmq, Frame, Client, BgWin, ChFrame, ChClient, ChList, Dummy : LongInt;
  CW, CH, ScrW, ScrH : LongInt;
  Page, Lang, Advanced, AutoMode : LongInt;
  NameZ, NameZ2 : Array[0..511] Of Byte;
  TxtBuf : Array[0..511] Of Byte;
  Qmsg : Array[0..7] Of LongInt;
  { controles de la page }
  Ctl : Array[0..39] Of LongInt;
  NCtl : LongInt;
  { configuration du systeme }
  CfgVal, CfgCnt : Array[0..NCfg - 1] Of LongInt;
  CfgX, CfgY : Array[0..NCfg - 1] Of LongInt;      { icone (haut gauche, depuis le haut) }
  CfgSpin : Array[0..NCfg - 1] Of Boolean;
  ChItem : LongInt;                                { choix en cours de modification (-1) }
  DispW, DispH, DispB : Array[0..31] Of LongInt;   { modes d'affichage proposes }
  NDisp : LongInt;
  { disques et partitions }
  NDiskT, DiskCur : LongInt;
  DiskSec : Array[0..3] Of LongInt;
  DiskModel : Array[0..3] Of String[40];
  Mbr : Array[0..511] Of Byte;
  PType, PStart, PCount, PFlag : Array[0..3] Of LongInt;
  RowKind, RowA, RowB : Array[0..15] Of LongInt;   { 0 partition (RowA = entree), 1 espace libre (A..B) }
  NRow, SelRow : LongInt;
  TgtEntry, TgtDrive, TgtStart, TgtCount, Formatted : LongInt;
  StatusMsg : String;
  { composants }
  OptDesk, OptUtil, OptTest, OptRam, OptGames, OptMM : LongInt;
  { transfert }
  FName : Array[0..MaxFiles - 1] Of String[16];
  FSize : Array[0..MaxFiles - 1] Of LongInt;
  NFiles, CurF, HSrc, HDst, CopyStep, TotBytes, DoneBytes, CopiedFiles : LongInt;
  CurName, CopyErr, ShownName : String;
  ShownFill : LongInt;
  CopyBuf : Array[0..ChunkSize - 1] Of Byte;
  Prm : Array[0..3] Of LongInt;
  BootLbaT, BootSizeT : Array[0..2] Of LongInt;

{ --- DOSCALLS.DLL et noyau --- }
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function KDisk(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnDiskCtl';
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
Function WinUpdateWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindowEnabled(H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryFocus(HDesk : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';
Function VioQueryModes(I, P : LongInt) : LongInt; External 'VIOCALLS' Name 'VIOQUERYMODES';

{ --- PMGPI.DLL --- }
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';

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

Function Mb(Sectors : LongInt) : LongInt;
Begin
  Mb := Sectors Div 2048;
End;

{ ==================================================================== }
{ Langue : francais (defaut), anglais, allemand, espagnol, italien,    }
{ albanais                                                              }
{ ==================================================================== }

{ texte de l'assistant : francais, anglais, allemand, espagnol, italien,
  albanais ; le portugais, le suedois, le danois et le japonais (romaji)
  sont proposes pour LANGUAGE, l'assistant les affiche en anglais }
Function L(F, E, G, S, I, A : String) : String;
Begin
  Case Lang Of
    0 : L := F;
    2 : L := G;
    3 : L := S;
    4 : L := I;
    5 : L := A;
  Else
    L := E;
  End;
End;

{ valeur de LANGUAGE (CONFIG.SYS) : FR (defaut), EN, GR, SP, IT, ALB,
  PT, SE, DK, JP ; sont aussi reconnus ES, DE, SQ, PRT, SWE, DNK, JPN }
Function LangCode(N : LongInt) : String;
Begin
  Case N Of
    1 : LangCode := 'EN';
    2 : LangCode := 'GR';
    3 : LangCode := 'SP';
    4 : LangCode := 'IT';
    5 : LangCode := 'ALB';
    6 : LangCode := 'PT';
    7 : LangCode := 'SE';
    8 : LangCode := 'DK';
    9 : LangCode := 'JP';
  Else
    LangCode := 'FR';
  End;
End;

Function LangOfCode(S : String) : LongInt;
Var K : LongInt;
Begin
  LangOfCode := 0;
  S := UpStr(S);
  If S = 'ES' Then S := 'SP';
  If S = 'DE' Then S := 'GR';
  If S = 'SQ' Then S := 'ALB';
  If S = 'PRT' Then S := 'PT';
  If S = 'SWE' Then S := 'SE';
  If S = 'DNK' Then S := 'DK';
  If S = 'JPN' Then S := 'JP';
  For K := 0 To NLang - 1 Do
    If LangCode(K) = S Then LangOfCode := K;
End;

Function LangName(N : LongInt) : String;
Begin
  Case N Of
    1 : LangName := 'English (EN)';
    2 : LangName := 'Deutsch (GR)';
    3 : LangName := 'Espa'#164'ol (SP)';
    4 : LangName := 'Italiano (IT)';
    5 : LangName := 'Shqip (ALB)';
    6 : LangName := 'Portugu'#136's (PT)';
    7 : LangName := 'Svenska (SE)';
    8 : LangName := 'Dansk (DK)';
    9 : LangName := 'Nihongo (JP)';
  Else
    LangName := 'Fran'#135'ais (FR)';
  End;
End;

{ pays (code de pays de CONFIG.SYS) et clavier (disposition) par defaut
  de chaque langue : France, Etats-Unis, Allemagne, Espagne, Italie,
  Albanie }
Const
  NLang = 10;
  NCountry = 14;
  CountryName : Array[0..NCountry - 1] Of String[24] = ('France', 'United States', 'Deutschland', 'Espa'#164'a',
    'Italia', 'Shqip'#137'ria', 'Canada', 'Belgique', 'Suisse', 'United Kingdom', 'Portugal', 'Sverige', 'Danmark',
    'Nippon');
  CountryCode : Array[0..NCountry - 1] Of String[3] = ('033', '001', '049', '034', '039', '355', '002', '032',
    '041', '044', '351', '046', '045', '081');
  KbdName : Array[0..NCountry - 1] Of String[24] = ('Fran'#135'ais', 'US English', 'Deutsch', 'Espa'#164'ol',
    'Italiano', 'Shqip', 'Canadien fran'#135'ais', 'Belge', 'Suisse romand', 'UK English', 'Portugu'#136's', 'Svenska',
    'Dansk', 'Nihongo');
  KbdCode : Array[0..NCountry - 1] Of String[4] = ('FR', 'US', 'GR', 'SP', 'IT', 'AL', 'CF', 'BE', 'SF', 'UK', 'PO',
    'SV', 'DK', 'JP');
  KbdLayout : Array[0..NCountry - 1] Of String[4] = ('189', '103', '129', '172', '141', '452', '058', '120',
    '150f', '166', '163', '153', '159', '106');
  DefCountry : Array[0..NLang - 1] Of LongInt = (0, 1, 2, 3, 4, 5, 10, 11, 12, 13);

Function CfgTitle(I : LongInt) : String;
Begin
  Case I Of
    CF_COUNTRY : CfgTitle := L('Pays', 'Country', 'Land', 'Pa'#161's', 'Paese', 'Shteti');
    CF_KBD : CfgTitle := L('Clavier', 'Keyboard', 'Tastatur', 'Teclado', 'Tastiera', 'Tastiera');
    CF_LANG : CfgTitle := L('Langue', 'Language', 'Sprache', 'Idioma', 'Lingua', 'Gjuha');
    CF_MOUSE : CfgTitle := L('Souris', 'Mouse', 'Maus', 'Rat'#162'n', 'Mouse', 'Miu');
    CF_SERIAL : CfgTitle := L('Ports s'#130'rie', 'Serial Device Support', 'Serielle Anschl'#129'sse',
                              'Puertos serie', 'Porte seriali', 'Portat seriale');
    CF_DISP : CfgTitle := L('Affichage principal', 'Primary Display', 'Prim'#132're Anzeige', 'Pantalla principal',
                            'Schermo principale', 'Ekrani kryesor');
    CF_DISP2 : CfgTitle := L('Affichage secondaire', 'Secondary Display', 'Sekund'#132're Anzeige',
                             'Pantalla secundaria', 'Schermo secondario', 'Ekrani dyt'#137'sor');
    CF_APM : CfgTitle := L('Gestion de l''alimentation', 'Advanced Power Management', 'Energieverwaltung (APM)',
                           'Gesti'#162'n de energ'#161'a', 'Gestione energia', 'Menaxhimi i energjis'#137);
    CF_PCMCIA : CfgTitle := L('Cartes PCMCIA', 'PCMCIA Support', 'PCMCIA-Unterst'#129'tzung', 'Soporte PCMCIA',
                              'Supporto PCMCIA', 'Mb'#137'shtetja PCMCIA');
    CF_CDROM : CfgTitle := L('Lecteur de CD-ROM', 'CD-ROM Device Support', 'CD-ROM-Laufwerk', 'Unidad de CD-ROM',
                             'Unit'#133' CD-ROM', 'Nj'#137'sia CD-ROM');
    CF_PRINTER : CfgTitle := L('Imprimante', 'Printer', 'Drucker', 'Impresora', 'Stampante', 'Printeri');
    CF_MMEDIA : CfgTitle := L('Multim'#130'dia', 'Multimedia Device Support', 'Multimedia', 'Multimedia',
                              'Multimedia', 'Multimedia');
  Else
    CfgTitle := L('Adaptateur SCSI', 'SCSI Adapter Support', 'SCSI-Adapter', 'Adaptador SCSI', 'Adattatore SCSI',
                  'P'#137'rshtat'#137'si SCSI');
  End;
End;

Function TxtNone : String;
Begin
  TxtNone := L('Aucun pilote install'#130, 'No Support Installed', 'Keine Unterst'#129'tzung installiert',
               'Sin controlador instalado', 'Nessun driver installato', 'Asnj'#137' drejtues i instaluar');
End;

Function CfgText(I, V : LongInt) : String;
Var S : String;
Begin
  S := '';
  Case I Of
    CF_COUNTRY : S := CountryName[V] + ' (' + CountryCode[V] + ')';
    CF_KBD : S := KbdName[V] + ' (' + KbdLayout[V] + ')';
    CF_LANG : S := LangName(V);
    CF_MOUSE : If V = 0 Then S := L('Souris PS/2', 'PS/2 (tm) Style Pointing Device', 'PS/2-Maus', 'Rat'#162'n PS/2',
                                    'Mouse PS/2', 'Miu PS/2')
               Else S := L('Aucune souris', 'No Mouse', 'Keine Maus', 'Sin rat'#162'n', 'Nessun mouse', 'Pa mi');
    CF_SERIAL : If V = 0 Then S := TxtNone Else S := 'COM1, COM2';
    CF_DISP :
      If V = 0 Then S := 'VGA 640 x 480 (16 ' + L('couleurs', 'colors', 'Farben', 'colores', 'colori', 'ngjyra') + ')'
      Else S := 'VESA ' + IStr(DispW[V]) + ' x ' + IStr(DispH[V]) + ' x ' + IStr(DispB[V]) + ' bits';
    CF_DISP2 : S := L('Aucun', 'None', 'Keine', 'Ninguna', 'Nessuno', 'Asnj'#137);
    CF_APM : If V = 0 Then S := L('Pilote install'#130, 'Support Installed', 'Installiert', 'Instalado',
                                  'Installato', 'I instaluar')
             Else S := TxtNone;
    CF_PCMCIA : S := TxtNone;
    CF_CDROM :
      Case V Of
        0 : S := 'IDE (ATAPI)';
        1 : S := L('Autre', 'Other', 'Andere', 'Otro', 'Altro', 'Tjet'#137'r');
      Else
        S := L('Aucun', 'None', 'Keines', 'Ninguno', 'Nessuno', 'Asnj'#137);
      End;
    CF_PRINTER : If V = 0 Then S := L('Aucune imprimante', 'No printers attached', 'Kein Drucker',
                                      'Sin impresora', 'Nessuna stampante', 'Asnj'#137' printer')
                 Else S := 'IBM Null (LPT1)';
    CF_MMEDIA : If V = 0 Then S := L('Aucun', 'None', 'Keine', 'Ninguno', 'Nessuno', 'Asnj'#137)
                Else S := 'Sound Blaster';
    CF_SCSI : If V = 0 Then S := L('Aucun', 'None', 'Keiner', 'Ninguno', 'Nessuno', 'Asnj'#137)
              Else S := L('Autre', 'Other', 'Andere', 'Otro', 'Altro', 'Tjet'#137'r');
  End;
  CfgText := S;
End;

Function TxtSetup : String;
Begin
  TxtSetup := L('Installation d''OS/2-0', 'OS/2-0 Installation', 'OS/2-0-Installation', 'Instalaci'#162'n de OS/2-0',
                'Installazione di OS/2-0', 'Instalimi i OS/2-0');
End;

Function TxtPrev : String;
Begin
  TxtPrev := L('Pr'#130'c'#130'dent', 'Back', 'Zur'#129'ck', 'Atr'#160's', 'Indietro', 'Prapa');
End;

Function TxtHelp : String;
Begin
  TxtHelp := L('Aide', 'Help', 'Hilfe', 'Ayuda', 'Aiuto', 'Ndihm'#137);
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Procedure GBox(Hps, X1, Y1, X2, Y2, C, Fl, R : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiBox(Hps, Fl, LongInt(@P), R, R);
End;

Procedure FBox(Hps, X1, Y1, X2, Y2, Fill, Edge : LongInt);
Begin
  GBox(Hps, X1, Y1, X2, Y2, Fill, DRO_FILL, 0);
  If Edge <> Fill Then GBox(Hps, X1, Y1, X2, Y2, Edge, DRO_OUTLINE, 0);
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

{ texte a la position (X, haut YT) de la zone client }
Procedure TextAt(Hps, X, YT : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := CH - YT - 16; Rc[2] := X + Length(S) * 8; Rc[3] := CH - YT;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

Procedure TextCenter(Hps, YT : LongInt; S : String; Fg : LongInt);
Begin
  TextAt(Hps, (CW - Length(S) * 8) Div 2, YT, S, Fg, CLR_PALEGRAY);
End;

{ texte coupe en lignes de W caracteres au plus ; rend la hauteur }
Function WrapAt(Hps, X, YT, W : LongInt; S : String; Fg : LongInt) : LongInt;
Var P, N : LongInt; T : String;
Begin
  N := 0;
  While S <> '' Do
  Begin
    If Length(S) <= W Then
    Begin
      T := S; S := '';
    End
    Else
    Begin
      P := W + 1;
      While (P > 1) And (S[P] <> ' ') Do Dec(P);
      If P <= 1 Then P := W;
      T := Copy(S, 1, P - 1);
      S := Copy(S, P + 1, 255);
    End;
    If Hps <> 0 Then TextAt(Hps, X, YT + N * 16, T, Fg, CLR_PALEGRAY);
    Inc(N);
  End;
  WrapAt := N * 16;
End;

{ cadre de groupe (titre en bleu fonce) : haut YT, hauteur H }
Procedure Group(Hps, X, YT, W, H : LongInt; S : String);
Var Y1, Y2 : LongInt;
Begin
  Y2 := CH - YT - 8; Y1 := CH - YT - H;
  GLn(Hps, X, Y2, X + W, Y2, CLR_DARKGRAY);
  GLn(Hps, X, Y1, X + W, Y1, CLR_WHITE);
  GLn(Hps, X, Y1, X, Y2, CLR_DARKGRAY);
  GLn(Hps, X + W, Y1, X + W, Y2, CLR_WHITE);
  TextAt(Hps, X + 4, YT, S, CLR_DARKBLUE, CLR_PALEGRAY);
End;

{ --- icones (28 x 28, coin haut gauche X, YT) --- }
Procedure IcoBase(Hps, X, YT : LongInt; Var B : LongInt);
Begin
  B := CH - YT - 28;
  FBox(Hps, X, B, X + 27, B + 27, CLR_PALEGRAY, CLR_DARKGRAY);
  GLn(Hps, X, B + 27, X + 27, B + 27, CLR_WHITE);
  GLn(Hps, X, B, X, B + 27, CLR_WHITE);
End;

Procedure IcoMonitor(Hps, X, B, Scr : LongInt);
Begin
  FBox(Hps, X + 4, B + 9, X + 23, B + 24, CLR_DARKGRAY, CLR_BLACK);
  FBox(Hps, X + 6, B + 11, X + 21, B + 22, Scr, Scr);
  FBox(Hps, X + 10, B + 5, X + 17, B + 8, CLR_DARKGRAY, CLR_BLACK);
End;

Procedure DrawIcon(Hps, I, X, YT : LongInt);
Var B, K : LongInt;
Begin
  IcoBase(Hps, X, YT, B);
  Case I Of
    CF_COUNTRY :
      Begin
        GBox(Hps, X + 4, B + 4, X + 23, B + 23, CLR_BLUE, DRO_FILL, 20);
        FBox(Hps, X + 8, B + 12, X + 13, B + 19, CLR_GREEN, CLR_GREEN);
        FBox(Hps, X + 15, B + 7, X + 20, B + 13, CLR_GREEN, CLR_GREEN);
      End;
    CF_KBD :
      Begin
        FBox(Hps, X + 2, B + 8, X + 25, B + 19, CLR_WHITE, CLR_BLACK);
        For K := 0 To 4 Do GLn(Hps, X + 4 + K * 4, B + 15, X + 6 + K * 4, B + 15, CLR_DARKGRAY);
        GLn(Hps, X + 7, B + 11, X + 20, B + 11, CLR_DARKGRAY);
      End;
    CF_LANG :
      Begin
        FBox(Hps, X + 3, B + 10, X + 15, B + 24, CLR_WHITE, CLR_DARKBLUE);
        TextAt(Hps, X + 5, YT + 6, 'A', CLR_DARKBLUE, CLR_WHITE);
        FBox(Hps, X + 12, B + 3, X + 24, B + 17, CLR_YELLOW, CLR_DARKRED);
        TextAt(Hps, X + 14, YT + 12, 'z', CLR_DARKRED, CLR_YELLOW);
      End;
    CF_MOUSE :
      Begin
        GBox(Hps, X + 7, B + 3, X + 20, B + 22, CLR_WHITE, DRO_FILL, 10);
        GBox(Hps, X + 7, B + 3, X + 20, B + 22, CLR_BLACK, DRO_OUTLINE, 10);
        GLn(Hps, X + 7, B + 15, X + 20, B + 15, CLR_BLACK);
        GLn(Hps, X + 13, B + 15, X + 13, B + 22, CLR_BLACK);
        GLn(Hps, X + 13, B + 22, X + 13, B + 26, CLR_BLACK);
      End;
    CF_SERIAL :
      Begin
        FBox(Hps, X + 5, B + 9, X + 22, B + 18, CLR_PALEGRAY, CLR_BLACK);
        For K := 0 To 3 Do FBox(Hps, X + 7 + K * 4, B + 13, X + 8 + K * 4, B + 14, CLR_BLACK, CLR_BLACK);
        FBox(Hps, X + 11, B + 18, X + 16, B + 25, CLR_DARKGRAY, CLR_BLACK);
      End;
    CF_DISP : IcoMonitor(Hps, X, B, CLR_CYAN);
    CF_DISP2 : IcoMonitor(Hps, X, B, CLR_DARKCYAN);
    CF_APM :
      Begin
        FBox(Hps, X + 9, B + 4, X + 18, B + 22, CLR_GREEN, CLR_BLACK);
        FBox(Hps, X + 12, B + 22, X + 15, B + 25, CLR_DARKGRAY, CLR_BLACK);
        FBox(Hps, X + 9, B + 4, X + 18, B + 10, CLR_DARKGREEN, CLR_BLACK);
      End;
    CF_PCMCIA :
      Begin
        FBox(Hps, X + 5, B + 4, X + 22, B + 23, CLR_DARKGRAY, CLR_BLACK);
        FBox(Hps, X + 8, B + 12, X + 19, B + 20, CLR_YELLOW, CLR_BLACK);
      End;
    CF_CDROM :
      Begin
        GBox(Hps, X + 3, B + 3, X + 24, B + 24, CLR_WHITE, DRO_FILL, 22);
        GBox(Hps, X + 3, B + 3, X + 24, B + 24, CLR_DARKGRAY, DRO_OUTLINE, 22);
        GBox(Hps, X + 11, B + 11, X + 16, B + 16, CLR_PALEGRAY, DRO_FILL, 6);
        GBox(Hps, X + 11, B + 11, X + 16, B + 16, CLR_DARKGRAY, DRO_OUTLINE, 6);
      End;
    CF_PRINTER :
      Begin
        FBox(Hps, X + 8, B + 14, X + 19, B + 24, CLR_WHITE, CLR_BLACK);
        FBox(Hps, X + 3, B + 6, X + 24, B + 15, CLR_PALEGRAY, CLR_BLACK);
        FBox(Hps, X + 8, B + 3, X + 19, B + 8, CLR_WHITE, CLR_BLACK);
      End;
    CF_MMEDIA :
      Begin
        GBox(Hps, X + 5, B + 4, X + 12, B + 10, CLR_DARKBLUE, DRO_FILL, 6);
        GBox(Hps, X + 15, B + 7, X + 22, B + 13, CLR_DARKBLUE, DRO_FILL, 6);
        GLn(Hps, X + 11, B + 7, X + 11, B + 22, CLR_DARKBLUE);
        GLn(Hps, X + 21, B + 10, X + 21, B + 24, CLR_DARKBLUE);
        GLn(Hps, X + 11, B + 22, X + 21, B + 24, CLR_DARKBLUE);
      End;
  Else
    Begin
      FBox(Hps, X + 7, B + 7, X + 20, B + 20, CLR_DARKGRAY, CLR_BLACK);
      For K := 0 To 3 Do
      Begin
        GLn(Hps, X + 9 + K * 3, B + 3, X + 9 + K * 3, B + 7, CLR_BLACK);
        GLn(Hps, X + 9 + K * 3, B + 20, X + 9 + K * 3, B + 24, CLR_BLACK);
      End;
    End;
  End;
End;

{ logo OS/2 de la barre de progression : anneau de couleur }
Procedure Ring(Hps, X, Y, C : LongInt);
Begin
  GBox(Hps, X, Y, X + 21, Y + 21, C, DRO_OUTLINE, 22);
  GBox(Hps, X + 1, Y + 1, X + 20, Y + 20, C, DRO_OUTLINE, 20);
  GLn(Hps, X + 7, Y + 11, X + 14, Y + 11, C);
End;

{ ==================================================================== }
{ Controles de la page                                                  }
{ ==================================================================== }

Procedure ClearCtls;
Var K : LongInt;
Begin
  For K := 0 To NCtl - 1 Do Dummy := WinDestroyWindow(Ctl[K]);
  NCtl := 0;
End;

Function AddCtl(Cls, Style, X, YT, W, H, Id : LongInt; Text : String) : LongInt;
Var Hw : LongInt;
Begin
  Hw := WinCreateWindow(Client, Cls, Z(Text), WS_VISIBLE Or Style, X, CH - YT - H, W, H, Client, HWND_BOTTOM, Id,
                        0, 0);
  If NCtl < 40 Then
  Begin
    Ctl[NCtl] := Hw;
    Inc(NCtl);
  End;
  AddCtl := Hw;
End;

Function Button(X, YT, W, Id : LongInt; Text : String) : LongInt;
Begin
  If W = 0 Then W := Length(Text) * 8 + 24;
  Button := AddCtl(WC_BUTTON, BS_PUSHBUTTON Or WS_TABSTOP, X, YT, W, 24, Id, Text);
End;

Function Check(X, YT, Id : LongInt; Text : String; On : Boolean; Style : LongInt) : LongInt;
Var Hw : LongInt;
Begin
  Hw := AddCtl(WC_BUTTON, Style Or WS_TABSTOP, X, YT, Length(Text) * 8 + 28, 20, Id, Text);
  If On Then Dummy := WinSendMsg(Hw, BM_SETCHECK, 1, 0);
  Check := Hw;
End;

Function Checked(Hw : LongInt) : Boolean;
Begin
  Checked := WinSendMsg(Hw, BM_QUERYCHECK, 0, 0) <> 0;
End;

Procedure ShowMsg(Text, Cap : String; Style : LongInt);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Style Or MB_MOVEABLE);
End;

Function AskYes(Text : String) : Boolean;
Begin
  AskYes := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(TxtSetup), 0, MB_YESNO Or MB_WARNING Or MB_MOVEABLE) = MBID_YES;
End;

{ ==================================================================== }
{ Disques et partitions (KrnDiskCtl du noyau)                          }
{ ==================================================================== }

Function DiskRW(D, Lba, N, Addr : LongInt; Wr : Boolean) : LongInt;
Begin
  Prm[0] := Lba; Prm[1] := N; Prm[2] := Addr;
  If Wr Then DiskRW := KDisk(3, D, LongInt(@Prm)) Else DiskRW := KDisk(2, D, LongInt(@Prm));
End;

Procedure ScanDisks;
Var K : LongInt; Info : Array[0..15] Of LongInt;
Begin
  NDiskT := MinI(KDisk(0, 0, 0), 4);
  For K := 0 To NDiskT - 1 Do
  Begin
    FillChar(Info, SizeOf(Info), 0);
    Dummy := KDisk(1, K, LongInt(@Info));
    DiskSec[K] := Info[0];
    DiskModel[K] := GetZ(LongInt(@Info) + 12);
  End;
  If DiskCur >= NDiskT Then DiskCur := 0;
End;

{ table des partitions du disque D (secteur 0) }
Procedure ReadTable(D : LongInt);
Var K, E : LongInt;
Begin
  FillChar(Mbr, 512, 0);
  If (D < 0) Or (D >= NDiskT) Then Exit;
  If DiskRW(D, 0, 1, LongInt(@Mbr), False) <> 0 Then FillChar(Mbr, 512, 0);
  If (Mbr[510] <> $55) Or (Mbr[511] <> $AA) Then FillChar(Mbr, 512, 0);
  For K := 0 To 3 Do
  Begin
    E := 446 + K * 16;
    PFlag[K] := Mbr[E]; PType[K] := Mbr[E + 4];
    PStart[K] := RdL(LongInt(@Mbr) + E + 8); PCount[K] := RdL(LongInt(@Mbr) + E + 12);
    If (PType[K] = 0) Or (PCount[K] <= 0) Then
    Begin
      PType[K] := 0; PStart[K] := 0; PCount[K] := 0; PFlag[K] := 0;
    End;
  End;
End;

{ CHS d'un secteur (255 tetes, 63 secteurs ; FEh FFh FFh au-dela) }
Procedure PutChs(A, Lba : LongInt);
Var C, H, S : LongInt;
Begin
  C := Lba Div (255 * 63);
  If C > 1023 Then
  Begin
    WrB(A, $FE); WrB(A + 1, $FF); WrB(A + 2, $FF);
  End
  Else
  Begin
    H := (Lba Div 63) Mod 255; S := (Lba Mod 63) + 1;
    WrB(A, H); WrB(A + 1, S Or ((C Shr 2) And $C0)); WrB(A + 2, C And $FF);
  End;
End;

{ ecrire la table (et le code d'amorce d'OS/2-0) au secteur 0 du disque }
Function WriteTable(D : LongInt; WithCode : Boolean) : Boolean;
Var K, E : LongInt;
Begin
  If WithCode Or ((Mbr[0] = 0) And (Mbr[1] = 0)) Then
    For K := 0 To 445 Do Mbr[K] := MbrCode[K];
  For K := 0 To 3 Do
  Begin
    E := 446 + K * 16;
    FillChar(Mbr[E], 16, 0);
    If PType[K] <> 0 Then
    Begin
      Mbr[E] := PFlag[K]; Mbr[E + 4] := PType[K];
      PutChs(LongInt(@Mbr) + E + 1, PStart[K]);
      PutChs(LongInt(@Mbr) + E + 5, PStart[K] + PCount[K] - 1);
      WrL(LongInt(@Mbr) + E + 8, PStart[K]); WrL(LongInt(@Mbr) + E + 12, PCount[K]);
    End;
  End;
  Mbr[510] := $55; Mbr[511] := $AA;
  WriteTable := DiskRW(D, 0, 1, LongInt(@Mbr), True) = 0;
End;

Function PartTypeName(T : LongInt) : String;
Begin
  Case T Of
    $01 : PartTypeName := 'FAT12';
    $04, $06, $0E : PartTypeName := 'FAT16';
    $05, $0F : PartTypeName := L('Etendue', 'Extended', 'Erweitert', 'Extendida', 'Estesa', 'E zgjeruar');
    $07 : PartTypeName := 'HPFS (07h)';
    $0B, $0C : PartTypeName := 'FAT32';
    $0A : PartTypeName := 'Boot Manager';
    $82 : PartTypeName := 'Linux swap';
    $83 : PartTypeName := 'Linux';
  Else
    PartTypeName := 'Type ' + IStr(T);
  End;
End;

{ premier secteur occupe par une partition (fin de la zone d'amorcage) }
Function FirstUsed : LongInt;
Var K, R : LongInt;
Begin
  R := DiskSec[DiskCur];
  For K := 0 To 3 Do
    If PType[K] <> 0 Then R := MinI(R, PStart[K]);
  FirstUsed := R;
End;

{ lignes de la liste : partitions dans l'ordre du disque et espaces libres }
Procedure BuildRows;
Var Ord4 : Array[0..3] Of LongInt; N, K, J, T, Pos0 : LongInt;
Begin
  NRow := 0;
  N := 0;
  For K := 0 To 3 Do
    If PType[K] <> 0 Then
    Begin
      Ord4[N] := K;
      Inc(N);
    End;
  For K := 1 To N - 1 Do
  Begin
    T := Ord4[K]; J := K - 1;
    While (J >= 0) And (PStart[Ord4[J]] > PStart[T]) Do
    Begin
      Ord4[J + 1] := Ord4[J];
      Dec(J);
    End;
    Ord4[J + 1] := T;
  End;
  Pos0 := FirstLba;
  For K := 0 To N Do
  Begin
    If K < N Then T := PStart[Ord4[K]] Else T := DiskSec[DiskCur];
    If T - Pos0 >= 2048 Then
    Begin
      RowKind[NRow] := 1; RowA[NRow] := Pos0; RowB[NRow] := T;
      Inc(NRow);
    End;
    If K < N Then
    Begin
      RowKind[NRow] := 0; RowA[NRow] := Ord4[K]; RowB[NRow] := 0;
      Inc(NRow);
      Pos0 := MaxI(Pos0, PStart[Ord4[K]] + PCount[Ord4[K]]);
    End;
  End;
End;

Function RowText(R : LongInt) : String;
Var S, T : String; E, D : LongInt;
Begin
  If RowKind[R] = 1 Then
  Begin
    S := '   ' + L('Espace libre', 'Free space', 'Freier Speicher', 'Espacio libre', 'Spazio libero',
                     'Hap'#137'sir'#137' e lir'#137);
    While Length(S) < 30 Do S := S + ' ';
    S := S + IStr(Mb(RowB[R] - RowA[R])) + ' Mo';
  End
  Else
  Begin
    E := RowA[R];
    S := IStr(E + 1) + '  ' + PartTypeName(PType[E]);
    While Length(S) < 22 Do S := S + ' ';
    D := KDisk(4, DiskCur, PStart[E]);
    If D >= 2 Then S := S + Chr(65 + D) + ':' Else S := S + '  ';
    T := IStr(Mb(PCount[E])) + ' Mo';
    While Length(T) < 10 Do T := ' ' + T;
    S := S + '  ' + T;
    If (PFlag[E] And $80) <> 0 Then S := S + '  ' + L('amor'#135'able', 'startable', 'startbar', 'de arranque',
                                                      'avviabile', 'nisese');
  End;
  RowText := S;
End;

{ ==================================================================== }
{ Choix d'une valeur (liste, comme les dialogues de Warp)               }
{ ==================================================================== }

Function CfgNames(I, V : LongInt) : String;
Begin
  CfgNames := CfgText(I, V);
End;

Procedure ApplyLang(N : LongInt);
Begin
  Lang := N;
  CfgVal[CF_LANG] := N;
  CfgVal[CF_COUNTRY] := DefCountry[N];
  CfgVal[CF_KBD] := DefCountry[N];
  { l'environnement du systeme suit (programmes lances ensuite) }
  PutZ(LongInt(@TxtBuf), LangCode(N));
  Dummy := KSetEnv(Z2('LANGUAGE'), LongInt(@TxtBuf));
End;

Procedure BuildPage; Forward;

Procedure CloseChoice;
Begin
  If ChFrame <> 0 Then Dummy := WinDestroyWindow(ChFrame);
  ChFrame := 0; ChClient := 0; ChList := 0; ChItem := -1;
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
End;

Procedure ChoiceDone;
Var V, It : LongInt;
Begin
  It := ChItem;
  If (ChList <> 0) And (ChItem >= 0) Then
  Begin
    V := WinSendMsg(ChList, LM_QUERYSELECTION, -1, 0);
    If (V >= 0) And (V < CfgCnt[ChItem]) Then
    Begin
      If ChItem = CF_LANG Then ApplyLang(V) Else CfgVal[ChItem] := V;
    End;
  End;
  CloseChoice;
  { nouvelle langue : boutons et titre recrees }
  If It = CF_LANG Then BuildPage Else Dummy := WinInvalidateRect(Client, 0, 1);
End;

Function ChoiceProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Hps : LongInt;
Begin
  ChoiceProc := 0;
  Case Msg Of
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
        Dummy := WinEndPaint(Hps);
      End;
    WM_COMMAND :
      If Lo16(Mp1) = ID_CHOK Then ChoiceDone Else CloseChoice;
    WM_CONTROL :
      If (Lo16(Mp1) = ID_CHLIST) And (Hi16(Mp1) = LN_ENTER) Then ChoiceDone;
    WM_CLOSE : CloseChoice;
  Else
    ChoiceProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ liste des valeurs du choix I (clic sur son icone ou son titre) }
Procedure OpenChoice(I : LongInt);
Var Fl, K, W, Hh, Hw : LongInt;
Begin
  If ChFrame <> 0 Then CloseChoice;
  ChItem := I;
  Fl := FCF_TITLEBAR Or FCF_DLGBORDER;
  ChClient := 0;
  ChFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('INSTCHOICE'), Z2(CfgTitle(I)), 0, 0, 0,
                                LongInt(@ChClient));
  If (ChFrame = 0) Or (ChClient = 0) Then Exit;
  W := 360; Hh := 270;
  Dummy := WinSetWindowPos(ChFrame, HWND_TOP, (ScrW - W) Div 2, (ScrH - Hh) Div 2, W, Hh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  ChList := WinCreateWindow(ChClient, WC_LISTBOX, Z(''), WS_VISIBLE Or WS_TABSTOP, 10, 44, W - 28, Hh - 84, ChClient,
                            HWND_BOTTOM, ID_CHLIST, 0, 0);
  For K := 0 To CfgCnt[I] - 1 Do Dummy := WinSendMsg(ChList, LM_INSERTITEM, -1, Z(CfgNames(I, K)));
  Dummy := WinSendMsg(ChList, LM_SELECTITEM, CfgVal[I], 1);
  Hw := WinCreateWindow(ChClient, WC_BUTTON, Z('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_DEFAULT, 10, 8, 90, 26,
                        ChClient, HWND_BOTTOM, ID_CHOK, 0, 0);
  Hw := WinCreateWindow(ChClient, WC_BUTTON, Z(L('Annuler', 'Cancel', 'Abbrechen', 'Cancelar', 'Annulla', 'Anulo')),
                        WS_VISIBLE Or WS_TABSTOP, 110, 8, 100, 26, ChClient, HWND_BOTTOM, ID_CHCANCEL, 0, 0);
  Dummy := WinSetFocus(HWND_DESKTOP, ChList);
End;

{ ==================================================================== }
{ Pages                                                                 }
{ ==================================================================== }

Function PageTitle(P : LongInt) : String;
Begin
  Case P Of
    PG_WELCOME : PageTitle := L('Bienvenue', 'Welcome', 'Willkommen', 'Bienvenido', 'Benvenuto', 'Mir'#137' se vini');
    PG_CONFIG : PageTitle := L('Configuration du syst'#138'me', 'System Configuration', 'Systemkonfiguration',
                               'Configuraci'#162'n del sistema', 'Configurazione del sistema', 'Konfigurimi i sistemit');
    PG_DISK : PageTitle := L('Partitionnement du disque dur', 'Hard Disk Partitioning', 'Festplatte partitionieren',
                             'Particiones del disco duro', 'Partizioni del disco fisso', 'Ndarja e diskut');
    PG_FORMAT : PageTitle := L('Formatage', 'Formatting', 'Formatieren', 'Formateo', 'Formattazione', 'Formatimi');
    PG_COMP : PageTitle := L('Choix des composants', 'Select Components', 'Komponenten', 'Componentes',
                             'Componenti', 'Zgjedhja e p'#137'rb'#137'r'#137'sve');
    PG_COPY : PageTitle := L('Transfert des fichiers', 'Transferring Files', 'Dateien werden kopiert',
                             'Transfiriendo archivos', 'Trasferimento dei file', 'Transferimi i skedar'#137've');
  Else
    PageTitle := L('Installation termin'#130'e', 'Installation Complete', 'Installation abgeschlossen',
                   'Instalaci'#162'n terminada', 'Installazione completata', 'Instalimi p'#137'rfundoi');
  End;
End;

Procedure FillPartList;
Var Lb, K : LongInt;
Begin
  ReadTable(DiskCur);
  BuildRows;
  Lb := Ctl[0];
  Dummy := WinSendMsg(Lb, LM_DELETEALL, 0, 0);
  For K := 0 To NRow - 1 Do Dummy := WinSendMsg(Lb, LM_INSERTITEM, -1, Z(RowText(K)));
  If SelRow >= NRow Then SelRow := NRow - 1;
  If SelRow >= 0 Then Dummy := WinSendMsg(Lb, LM_SELECTITEM, SelRow, 1);
End;

{ espace necessaire (octets) selon les composants choisis }
Function Wanted(N : String) : Boolean;
Var U : String;
Begin
  U := UpStr(N);
  Wanted := True;
  If (U = 'CONFIG.SYS') Or (U = 'OS2BOOT') Or (U = 'INSTALL.EXE') Then Wanted := False
  Else If Copy(U, 1, 4) = 'TEST' Then Wanted := OptTest <> 0
  Else If (U = 'PMSHELL.EXE') Or (U = 'LAUNCHPD.EXE') Then Wanted := OptDesk <> 0
  Else If (U = 'KLONDIKE.EXE') Or (U = 'ECHECS.EXE') Or (U = 'MAHJONGG.EXE') Then Wanted := OptGames <> 0
  Else If (U = 'DIGAUDIO.EXE') Or (U = 'MDM.DLL') Or (U = 'SBAUDIO.DLL') Or (U = 'ICHAUDIO.DLL') Or
          (U = 'ESAUDIO.DLL') Or (Pos('.WAV', U) > 0) Then Wanted := OptMM <> 0
  Else If (Pos('.EXE', U) > 0) And (U <> 'CMD.EXE') Then Wanted := OptUtil <> 0;
End;

Procedure ListFiles;
Var H, N, Rc, Off, A, K : LongInt; S : String; Fb : Array[0..4095] Of Byte;
Begin
  NFiles := 0; TotBytes := 0;
  H := -1; N := 1;
  Rc := DosFindFirst(Z('C:\*.*'), LongInt(@H), $27, LongInt(@Fb), 4096, LongInt(@N), 1);
  While (Rc = 0) And (N > 0) Do
  Begin
    Off := 0;
    While N > 0 Do
    Begin
      A := RdL(LongInt(@Fb) + Off + 24);
      S := '';
      For K := 0 To RdB(LongInt(@Fb) + Off + 28) - 1 Do S := S + Chr(RdB(LongInt(@Fb) + Off + 29 + K));
      If ((A And $10) = 0) And (NFiles < MaxFiles) And (Length(S) <= 16) And Wanted(S) Then
      Begin
        FName[NFiles] := UpStr(S);
        FSize[NFiles] := RdL(LongInt(@Fb) + Off + 16);
        TotBytes := TotBytes + FSize[NFiles];
        Inc(NFiles);
      End;
      Dec(N);
      If RdL(LongInt(@Fb) + Off) = 0 Then N := 0 Else Off := Off + RdL(LongInt(@Fb) + Off);
    End;
    N := 1;
    Rc := DosFindNext(H, LongInt(@Fb), 4096, LongInt(@N));
  End;
  If H <> -1 Then Dummy := DosFindClose(H);
End;

Function FreeKb(D : LongInt) : LongInt;
Var Fs : Array[0..5] Of LongInt;
Begin
  FreeKb := 0;
  If DosQueryFSInfo(D + 1, 1, LongInt(@Fs), 18) = 0 Then
    FreeKb := (RdL(LongInt(@Fs) + 12) * MaxI(1, RdL(LongInt(@Fs) + 4)) Div 2) * ((RdL(LongInt(@Fs) + 16) And $FFFF) Div 512);
End;

Procedure BuildPage;
Var Y, K, Hw : LongInt;
Begin
  ClearCtls;
  Dummy := WinSetWindowText(Frame, Z(TxtSetup + ' - ' + PageTitle(Page)));
  Case Page Of
    PG_WELCOME :
      Begin
        Hw := Button(40, CH - 50, 180, ID_EASY, L('Installation facile', 'Easy Installation', 'Einfache Installation',
                     'Instalaci'#162'n f'#160'cil', 'Installazione facile', 'Instalim i thjesht'#137));
        Dummy := WinSetFocus(HWND_DESKTOP, Hw);
        Hw := Button(236, CH - 50, 196, ID_ADV, L('Installation avanc'#130'e', 'Advanced Installation',
                     'Erweiterte Installation', 'Instalaci'#162'n avanzada', 'Installazione avanzata',
                     'Instalim i avancuar'));
        Hw := Button(CW - 140, CH - 50, 100, ID_QUIT, L('Quitter', 'Exit', 'Beenden', 'Salir', 'Esci', 'Dil'));
      End;
    PG_CONFIG :
      Begin
        Hw := Button(40, CH - 40, 90, ID_OK, 'OK');
        Dummy := WinSetFocus(HWND_DESKTOP, Hw);
        Hw := Button(150, CH - 40, 0, ID_BACK, TxtPrev);
        Hw := Button(CW - 130, CH - 40, 90, ID_HELP, TxtHelp);
      End;
    PG_DISK :
      Begin
        ScanDisks;
        Hw := AddCtl(WC_LISTBOX, WS_TABSTOP, 16, 92, CW - 32, 150, ID_PLIST, '');
        Hw := AddCtl(WC_ENTRYFIELD, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN, 16 + 15 * 8, 254, 80, 22, ID_PSIZE, '');
        Hw := Button(240, 252, 0, ID_PCREATE, L('Cr'#130'er', 'Create', 'Erstellen', 'Crear', 'Crea', 'Krijo'));
        Hw := Button(360, 252, 0, ID_PDELETE, L('Supprimer', 'Delete', 'L'#148'schen', 'Eliminar', 'Elimina', 'Fshi'));
        Hw := Button(40, CH - 40, 0, ID_PINSTALL, L('Installer sur cette partition', 'Install on this partition',
                     'Auf dieser Partition installieren', 'Instalar en esta partici'#162'n', 'Installa su questa partizione',
                     'Instalo n'#137' k'#137't'#137' ndarje'));
        Hw := Button(320, CH - 40, 0, ID_PPREV, TxtPrev);
        Hw := Button(CW - 110, CH - 40, 80, ID_HELP, TxtHelp);
        If NDiskT > 1 Then Hw := Button(CW - 120, 52, 100, ID_PNEXT, L('Disque suivant', 'Next disk', 'N'#132'chste',
                                        'Siguiente', 'Successivo', 'Tjetri'));
        If NDiskT > 0 Then FillPartList;
        Dummy := WinSetFocus(HWND_DESKTOP, Ctl[0]);
      End;
    PG_FORMAT :
      Begin
        Hw := Check(30, 110, ID_FHPFS, L('HPFS - syst'#138'me de fichiers haute performance (recommand'#130')',
                    'HPFS - High Performance File System (recommended)', 'HPFS - High Performance File System (empfohlen)',
                    'HPFS - sistema de archivos de alto rendimiento', 'HPFS - file system ad alte prestazioni',
                    'HPFS - sistem skedar'#137'sh me performanc'#137' t'#137' lart'#137), True,
                    BS_AUTORADIOBUTTON Or WS_GROUP);
        Hw := Check(30, 134, ID_FFAT, L('FAT (non disponible dans OS/2-0)', 'FAT (not available in OS/2-0)',
                    'FAT (in OS/2-0 nicht verf'#129'gbar)', 'FAT (no disponible en OS/2-0)', 'FAT (non disponibile in OS/2-0)',
                    'FAT (nuk ofrohet n'#137' OS/2-0)'), False, BS_AUTORADIOBUTTON);
        Dummy := WinEnableWindow(Hw, 0);
        Hw := Check(30, 170, ID_FKEEP, L('Ne pas formater : conserver les fichiers de la partition HPFS',
                    'Do not format: keep the files of the HPFS partition', 'Nicht formatieren: Dateien behalten',
                    'No formatear: conservar los archivos', 'Non formattare: conservare i file',
                    'Mos e formato: ruaj skedar'#137't'), False, BS_AUTOCHECKBOX);
        If TgtDrive < 2 Then Dummy := WinEnableWindow(Hw, 0);
        Hw := AddCtl(WC_ENTRYFIELD, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN, 30 + 20 * 8, 210, 140, 22, ID_FLABEL,
                     'OS2-0');
        Hw := Button(40, CH - 40, 0, ID_FGO, L('Formater', 'Format', 'Formatieren', 'Formatear', 'Formatta', 'Formato'));
        Dummy := WinSetFocus(HWND_DESKTOP, Hw);
        Hw := Button(220, CH - 40, 0, ID_BACK, TxtPrev);
        Hw := Button(CW - 110, CH - 40, 80, ID_HELP, TxtHelp);
      End;
    PG_COMP :
      Begin
        Y := 90;
        Hw := Check(30, Y, ID_CBASE, L('Syst'#138'me de base et Presentation Manager', 'Base system and Presentation Manager',
                    'Basissystem und Presentation Manager', 'Sistema base y Presentation Manager',
                    'Sistema di base e Presentation Manager', 'Sistemi baz'#137' dhe Presentation Manager'), True,
                    BS_AUTOCHECKBOX);
        Dummy := WinEnableWindow(Hw, 0);
        Hw := Check(30, Y + 26, ID_CDESK, L('Bureau (Workplace Shell) et LaunchPad', 'Desktop (Workplace Shell) and LaunchPad',
                    'Arbeitsoberfl'#132'che und LaunchPad', 'Escritorio y LaunchPad', 'Scrivania e LaunchPad',
                    'Desktopi dhe LaunchPad'), OptDesk <> 0, BS_AUTOCHECKBOX);
        Hw := Check(30, Y + 52, ID_CUTIL, L('Utilitaires (ATTRIB, XCOPY, EDLIN...)', 'Utilities (ATTRIB, XCOPY, EDLIN...)',
                    'Dienstprogramme (ATTRIB, XCOPY...)', 'Utilidades (ATTRIB, XCOPY...)', 'Utilit'#133' (ATTRIB, XCOPY...)',
                    'Mjete (ATTRIB, XCOPY...)'), OptUtil <> 0, BS_AUTOCHECKBOX);
        Hw := Check(30, Y + 78, ID_CTEST, L('Programmes d''essai des biblioth'#138'ques (TEST*.EXE)',
                    'Library test programs (TEST*.EXE)', 'Testprogramme (TEST*.EXE)', 'Programas de prueba (TEST*.EXE)',
                    'Programmi di prova (TEST*.EXE)', 'Programe prove (TEST*.EXE)'), OptTest <> 0, BS_AUTOCHECKBOX);
        Hw := Check(30, Y + 104, ID_CRAM, L('Disque virtuel en m'#130'moire de 4 Mo', 'Virtual disk in memory (4 MB)',
                    'Virtuelle Platte im Speicher (4 MB)', 'Disco virtual en memoria (4 MB)',
                    'Disco virtuale in memoria (4 MB)', 'Disk virtual n'#137' kujtes'#137' (4 MB)'), OptRam <> 0,
                    BS_AUTOCHECKBOX);
        Hw := Check(30, Y + 130, ID_CGAMES, L('Jeux (Solitaire - Klondike, Echecs, Mahjongg)',
                    'Games (Klondike Solitaire, Chess, Mahjongg)', 'Spiele (Klondike, Schach, Mahjongg)',
                    'Juegos (Klondike, Ajedrez, Mahjongg)', 'Giochi (Klondike, Scacchi, Mahjongg)',
                    'Loj'#137'ra (Klondike, Shah, Mahjongg)'), OptGames <> 0, BS_AUTOCHECKBOX);
        Hw := Check(30, Y + 156, ID_CMM, L('Multim'#130'dia (Audio num'#130'rique, pilotes des cartes son)',
                    'Multimedia (Digital Audio, sound card drivers)', 'Multimedia (Digital Audio, Soundkarten)',
                    'Multimedia (Audio digital, tarjetas de sonido)', 'Multimedia (Audio digitale, schede audio)',
                    'Multimedia (Audio dixhital, kartat e z'#137'rit)'), OptMM <> 0, BS_AUTOCHECKBOX);
        Hw := Button(40, CH - 40, 0, ID_CGO, L('Installer', 'Install', 'Installieren', 'Instalar', 'Installa', 'Instalo'));
        Dummy := WinSetFocus(HWND_DESKTOP, Hw);
        Hw := Button(220, CH - 40, 0, ID_BACK, TxtPrev);
        Hw := Button(CW - 110, CH - 40, 80, ID_HELP, TxtHelp);
      End;
    PG_DONE :
      Begin
        Hw := Button((CW - 180) Div 2, CH - 50, 180, ID_REBOOT, L('Red'#130'marrer', 'Restart', 'Neu starten',
                     'Reiniciar', 'Riavvia', 'Rinis'));
        Dummy := WinSetFocus(HWND_DESKTOP, Hw);
      End;
  End;
  Dummy := WinInvalidateRect(Client, 0, 1);
End;

Procedure GoPage(P : LongInt);
Begin
  Page := P;
  StatusMsg := '';
  BuildPage;
End;

{ ==================================================================== }
{ Dessin des pages                                                      }
{ ==================================================================== }

Procedure PaintWelcome(Hps : LongInt);
Var K, H : LongInt;
Begin
  For K := 0 To 4 Do
  Begin
    Case K Of
      0 : H := CLR_RED;
      1 : H := CLR_YELLOW;
      2 : H := CLR_CYAN;
      3 : H := CLR_GREEN;
    Else
      H := CLR_DARKBLUE;
    End;
    Ring(Hps, CW Div 2 - 70 + K * 26, CH - 70 + (K Mod 2) * 10, H);
  End;
  TextCenter(Hps, 80, L('Bienvenue dans OS/2-0', 'Welcome to OS/2-0', 'Willkommen bei OS/2-0', 'Bienvenido a OS/2-0',
             'Benvenuto in OS/2-0', 'Mir'#137' se vini n'#137' OS/2-0'), CLR_DARKBLUE);
  H := WrapAt(Hps, 30, 116, (CW - 60) Div 8, L(
    'Ce programme installe OS/2-0 sur un disque dur de votre ordinateur. OS/2-0 d'#130'marrera ensuite du disque dur, '
    + 'sans le CD-ROM.',
    'This program installs OS/2-0 on a hard disk of your computer. OS/2-0 will then start from the hard disk, '
    + 'without the CD-ROM.',
    'Dieses Programm installiert OS/2-0 auf einer Festplatte. OS/2-0 startet danach von der Festplatte, ohne CD-ROM.',
    'Este programa instala OS/2-0 en un disco duro. OS/2-0 arrancar'#160' despu'#130's desde el disco duro, sin el CD-ROM.',
    'Questo programma installa OS/2-0 su un disco fisso. OS/2-0 si avvier'#133' poi dal disco fisso, senza CD-ROM.',
    'Ky program instalon OS/2-0 n'#137' nj'#137' disk t'#137' kompjuterit. M'#137' pas OS/2-0 do t'#137' niset nga disku, pa CD-ROM.'),
    CLR_BLACK);
  H := WrapAt(Hps, 30, 116 + H + 12, (CW - 60) Div 8, L(
    'Installation facile : OS/2-0 utilise le premier disque dur (partition HPFS existante ou tout l''espace libre) et '
    + 'les choix par d'#130'faut. Installation avanc'#130'e : vous partitionnez le disque, choisissez le formatage et les '
    + 'composants.',
    'Easy Installation: OS/2-0 uses the first hard disk (existing HPFS partition or all the free space) and the default '
    + 'choices. Advanced Installation: you partition the disk and choose the formatting and the components.',
    'Einfache Installation: erste Festplatte und Standardwerte. Erweiterte Installation: Sie partitionieren die '
    + 'Festplatte und w'#132'hlen Formatierung und Komponenten.',
    'Instalaci'#162'n f'#160'cil: primer disco duro y valores por defecto. Instalaci'#162'n avanzada: usted crea las '
    + 'particiones y elige el formateo y los componentes.',
    'Installazione facile: primo disco fisso e scelte predefinite. Installazione avanzata: si creano le partizioni e '
    + 'si scelgono formattazione e componenti.',
    'Instalim i thjesht'#137': disku i par'#137' dhe zgjedhjet e paracaktuara. Instalim i avancuar: ju ndani diskun '
    + 'dhe zgjidhni formatimin dhe p'#137'rb'#137'r'#137'sit.'), CLR_BLACK);
  If NDiskT = 0 Then
    H := WrapAt(Hps, 30, CH - 110, (CW - 60) Div 8, L('Aucun disque dur IDE n''a '#130't'#130' trouv'#130'.',
         'No IDE hard disk was found.', 'Keine IDE-Festplatte gefunden.', 'No se encontr'#162' ning'#163'n disco duro IDE.',
         'Nessun disco fisso IDE trovato.', 'Nuk u gjet asnj'#137' disk IDE.'), CLR_DARKRED);
End;

Procedure PaintConfig(Hps : LongInt);
Var I, X, Y, H, B : LongInt;
Begin
  H := WrapAt(Hps, 12, 4, (CW - 24) Div 8, L(
    'Si les choix suivants sont corrects, s'#130'lectionnez OK. Pour modifier un choix, s'#130'lectionnez l''ic'#147'ne '
    + 'qui le pr'#130'c'#138'de.',
    'If the following hardware and country choices are correct, select OK. To change a choice, select the icon next to it.',
    'Wenn die folgenden Angaben stimmen, w'#132'hlen Sie OK. Zum '#142'ndern das Symbol daneben ausw'#132'hlen.',
    'Si las opciones siguientes son correctas, seleccione OK. Para cambiar una opci'#162'n, seleccione su icono.',
    'Se le scelte seguenti sono corrette, selezionare OK. Per cambiarne una, selezionare la sua icona.',
    'N'#137'se zgjedhjet e m'#137'poshtme jan'#137' t'#137' sakta, zgjidhni OK. P'#137'r t'#137' ndryshuar nj'#137' '
    + 'zgjedhje, zgjidhni ikon'#137'n e saj.'), CLR_DARKBLUE);
  Group(Hps, 8, 40, CW - 16, 84, L('Param'#138'tres r'#130'gionaux', 'Locale', 'Gebietsschema', 'Configuraci'#162'n regional',
        'Impostazioni locali', 'Cil'#137'simet vendore'));
  Group(Hps, 8, 128, CW - 16, 84, L('Syst'#138'me', 'System', 'System', 'Sistema', 'Sistema', 'Sistemi'));
  Group(Hps, 8, 216, CW - 16, 124, L('P'#130'riph'#130'riques install'#130's', 'Currently Installed Peripherals',
        'Installierte Peripherieger'#132'te', 'Perif'#130'ricos instalados', 'Periferiche installate',
        'Pajisjet e instaluara'));
  For I := 0 To NCfg - 1 Do
  Begin
    X := CfgX[I]; Y := CfgY[I];
    DrawIcon(Hps, I, X, Y);
    TextAt(Hps, X + 36, Y - 2, CfgTitle(I), CLR_DARKBLUE, CLR_PALEGRAY);
    If CfgSpin[I] Then
    Begin
      { champ a fleches (comme les champs de Warp) }
      B := CH - Y - 34;
      FBox(Hps, X + 36, B, X + 36 + 200, B + 18, CLR_WHITE, CLR_DARKGRAY);
      TextAt(Hps, X + 40, Y + 16, Copy(CfgText(I, CfgVal[I]), 1, 22), CLR_BLACK, CLR_WHITE);
      FBox(Hps, X + 238, B + 9, X + 250, B + 18, CLR_PALEGRAY, CLR_DARKGRAY);
      FBox(Hps, X + 238, B, X + 250, B + 8, CLR_PALEGRAY, CLR_DARKGRAY);
      GLn(Hps, X + 241, B + 11, X + 244, B + 16, CLR_BLACK); GLn(Hps, X + 244, B + 16, X + 247, B + 11, CLR_BLACK);
      GLn(Hps, X + 241, B + 7, X + 244, B + 2, CLR_BLACK); GLn(Hps, X + 244, B + 2, X + 247, B + 7, CLR_BLACK);
    End
    Else TextAt(Hps, X + 36, Y + 14, Copy(CfgText(I, CfgVal[I]), 1, 30), CLR_BLACK, CLR_PALEGRAY);
  End;
End;

Procedure PaintDisk(Hps : LongInt);
Var S : String; H : LongInt;
Begin
  H := WrapAt(Hps, 16, 4, (CW - 32) Div 8, L(
    'Choisissez la partition o'#151' installer OS/2-0. Pour cr'#130'er une partition HPFS, choisissez un espace libre, '
    + 'indiquez sa taille en Mo et s'#130'lectionnez Cr'#130'er.',
    'Select the partition where OS/2-0 is to be installed. To create an HPFS partition, select a free space, enter its '
    + 'size in MB and select Create.',
    'W'#132'hlen Sie die Partition f'#129'r OS/2-0. Zum Erstellen einer HPFS-Partition freien Speicher w'#132'hlen, '
    + 'Gr'#148#225'e in MB eingeben und Erstellen w'#132'hlen.',
    'Elija la partici'#162'n donde instalar OS/2-0. Para crear una partici'#162'n HPFS, elija un espacio libre, indique '
    + 'su tama'#164'o en MB y seleccione Crear.',
    'Scegliere la partizione dove installare OS/2-0. Per creare una partizione HPFS, scegliere uno spazio libero, '
    + 'indicarne la dimensione in MB e selezionare Crea.',
    'Zgjidhni ndarjen ku do t'#137' instalohet OS/2-0. P'#137'r t'#137' krijuar nj'#137' ndarje HPFS, zgjidhni nj'#137' '
    + 'hap'#137'sir'#137' t'#137' lir'#137', shkruani madh'#137'sin'#137' n'#137' MB dhe zgjidhni Krijo.'), CLR_DARKBLUE);
  If NDiskT = 0 Then
  Begin
    TextAt(Hps, 16, 60, L('Aucun disque dur IDE.', 'No IDE hard disk.', 'Keine IDE-Festplatte.', 'Ning'#163'n disco duro IDE.',
           'Nessun disco fisso IDE.', 'Asnj'#137' disk IDE.'), CLR_DARKRED, CLR_PALEGRAY);
    Exit;
  End;
  S := L('Disque ', 'Disk ', 'Platte ', 'Disco ', 'Disco ', 'Disku ') + IStr(DiskCur + 1) + ' / ' + IStr(NDiskT) + ' : ' +
       DiskModel[DiskCur] + ', ' + IStr(Mb(DiskSec[DiskCur])) + ' Mo';
  TextAt(Hps, 16, 56, Copy(S, 1, 60), CLR_BLACK, CLR_PALEGRAY);
  TextAt(Hps, 16, 74, L('Partition / type / unit'#130' / taille', 'Partition / type / drive / size',
         'Partition / Typ / Laufwerk / Gr'#148#225'e', 'Partici'#162'n / tipo / unidad / tama'#164'o',
         'Partizione / tipo / unit'#133' / dimensione', 'Ndarja / lloji / nj'#137'sia / madh'#137'sia'), CLR_DARKGRAY,
         CLR_PALEGRAY);
  TextAt(Hps, 16, 257, L('Taille (Mo) :', 'Size (MB):', 'Gr'#148#225'e (MB):', 'Tama'#164'o (MB):', 'Dimensione (MB):',
         'Madh'#137'sia (MB):'), CLR_BLACK, CLR_PALEGRAY);
  If StatusMsg <> '' Then H := WrapAt(Hps, 16, 290, (CW - 32) Div 8, StatusMsg, CLR_DARKRED);
End;

Procedure PaintFormat(Hps : LongInt);
Var S : String; H : LongInt;
Begin
  S := L('Partition choisie : ', 'Selected partition: ', 'Gew'#132'hlte Partition: ', 'Partici'#162'n elegida: ',
         'Partizione scelta: ', 'Ndarja e zgjedhur: ') + L('disque ', 'disk ', 'Platte ', 'disco ', 'disco ', 'disku ') +
       IStr(DiskCur + 1) + ', ' + IStr(Mb(TgtCount)) + ' Mo';
  If TgtDrive >= 2 Then S := S + ' (' + Chr(65 + TgtDrive) + ':)';
  TextAt(Hps, 30, 20, S, CLR_BLACK, CLR_PALEGRAY);
  TextAt(Hps, 30, 80, L('Syst'#138'me de fichiers :', 'File system:', 'Dateisystem:', 'Sistema de archivos:',
         'File system:', 'Sistemi i skedar'#137've:'), CLR_DARKBLUE, CLR_PALEGRAY);
  TextAt(Hps, 30, 213, L('Nom du volume :', 'Volume label:', 'Datentr'#132'gername:', 'Etiqueta:', 'Etichetta:',
         'Emri i v'#137'llimit:'), CLR_BLACK, CLR_PALEGRAY);
  H := WrapAt(Hps, 30, 250, (CW - 60) Div 8, L(
    'Attention : le formatage efface toutes les donn'#130'es de la partition.',
    'Warning: formatting erases all the data on the partition.',
    'Achtung: Formatieren l'#148'scht alle Daten der Partition.',
    'Atenci'#162'n: el formateo borra todos los datos de la partici'#162'n.',
    'Attenzione: la formattazione cancella tutti i dati della partizione.',
    'Kujdes: formatimi fshin t'#137' gjitha t'#137' dh'#137'nat e ndarjes.'), CLR_DARKRED);
  If StatusMsg <> '' Then H := WrapAt(Hps, 30, 290, (CW - 60) Div 8, StatusMsg, CLR_DARKBLUE);
End;

Procedure PaintComp(Hps : LongInt);
Var H, Need, K : LongInt;
Begin
  H := WrapAt(Hps, 30, 20, (CW - 60) Div 8, L(
    'Choisissez les composants d''OS/2-0 '#133' installer sur l''unit'#130' ',
    'Select the OS/2-0 components to install on drive ', 'W'#132'hlen Sie die Komponenten f'#129'r Laufwerk ',
    'Elija los componentes a instalar en la unidad ', 'Scegliere i componenti da installare sull''unit'#133' ',
    'Zgjidhni p'#137'rb'#137'r'#137'sit p'#137'r nj'#137'sin'#137' ') + Chr(65 + TgtDrive) + ':.', CLR_DARKBLUE);
  ListFiles;
  Need := TotBytes Div 1024;
  TextAt(Hps, 30, 288, L('Espace n'#130'cessaire : ', 'Space needed: ', 'Ben'#148'tigter Platz: ', 'Espacio necesario: ',
         'Spazio necessario: ', 'Hap'#137'sira e nevojshme: ') + IStr(Need) + ' Ko', CLR_BLACK, CLR_PALEGRAY);
  K := FreeKb(TgtDrive);
  TextAt(Hps, 30, 306, L('Espace disponible : ', 'Space available: ', 'Verf'#129'gbarer Platz: ', 'Espacio disponible: ',
         'Spazio disponibile: ', 'Hap'#137'sira e lir'#137': ') + IStr(K) + ' Ko', CLR_BLACK, CLR_PALEGRAY);
End;

{ largeur remplie de la barre de progression (pels) }
Function BarFill : LongInt;
Var Wd : LongInt;
Begin
  Wd := CW - 64;
  If CopyStep >= CS_DIRS Then BarFill := Wd
  Else If TotBytes > 0 Then BarFill := (Wd * (DoneBytes Div 1024)) Div MaxI(1, TotBytes Div 1024)
  Else BarFill := 0;
End;

Procedure PaintCopy(Hps : LongInt);
Var X1, X2, Y1, Y2, Fill, X, Y, K, C : LongInt;
Begin
  { imprimante et disque (icone de Warp) }
  FBox(Hps, CW Div 2 - 14, CH - 52, CW Div 2 + 14, CH - 34, CLR_PALEGRAY, CLR_BLACK);
  FBox(Hps, CW Div 2 - 8, CH - 34, CW Div 2 + 8, CH - 24, CLR_WHITE, CLR_BLACK);
  GLn(Hps, CW Div 2 - 10, CH - 44, CW Div 2 + 10, CH - 44, CLR_DARKGRAY);
  TextCenter(Hps, 70, L('Transfert des fichiers sur votre disque dur.', 'Transferring files to your hard disk.',
             'Dateien werden auf die Festplatte kopiert.', 'Transfiriendo archivos a su disco duro.',
             'Trasferimento dei file sul disco fisso.', 'Skedar'#137't po transferohen n'#137' diskun tuaj.'),
             CLR_DARKBLUE);
  TextCenter(Hps, 90, L('Veuillez patienter...', 'Please wait...', 'Bitte warten...', 'Espere por favor...',
             'Attendere prego...', 'Ju lutemi prisni...'), CLR_DARKBLUE);
  TextAt(Hps, 30, 140, L('Fichier courant :', 'Current File:', 'Aktuelle Datei:', 'Archivo actual:', 'File corrente:',
         'Skedari aktual:'), CLR_DARKBLUE, CLR_PALEGRAY);
  TextAt(Hps, 30, 158, CurName, CLR_DARKBLUE, CLR_PALEGRAY);
  { barre de progression : logos OS/2 sur fond noir }
  X1 := 30; X2 := CW - 30; Y2 := CH - 200; Y1 := Y2 - 64;
  FBox(Hps, X1, Y1, X2, Y2, CLR_BLACK, CLR_DARKCYAN);
  FBox(Hps, X1 + 2, Y2 - 12, X2 - 2, Y2 - 2, CLR_PALEGRAY, CLR_PALEGRAY);
  Fill := BarFill;
  ShownFill := Fill Div 14; ShownName := CurName;
  X := X1 + 4; K := 0;
  While X + 22 <= X1 + 2 + Fill Do
  Begin
    Case K Mod 5 Of
      0 : C := CLR_RED;
      1 : C := CLR_YELLOW;
      2 : C := CLR_CYAN;
      3 : C := CLR_GREEN;
    Else
      C := CLR_WHITE;
    End;
    If Odd(K) Then Y := Y1 + 4 Else Y := Y1 + 20;
    Ring(Hps, X, Y, C);
    X := X + 14; Inc(K);
  End;
  TextAt(Hps, X1, CH - Y1 + 2, '0%', CLR_BLACK, CLR_PALEGRAY);
  TextAt(Hps, (X1 + X2) Div 2 - 12, CH - Y1 + 2, '50%', CLR_BLACK, CLR_PALEGRAY);
  TextAt(Hps, X2 - 32, CH - Y1 + 2, '100%', CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintDone(Hps : LongInt);
Var H : LongInt;
Begin
  If CopyErr <> '' Then
  Begin
    TextCenter(Hps, 40, L('L''installation a '#130'chou'#130'.', 'The installation failed.', 'Die Installation ist fehlgeschlagen.',
               'La instalaci'#162'n ha fallado.', 'L''installazione non '#138' riuscita.', 'Instalimi d'#137'shtoi.'),
               CLR_DARKRED);
    H := WrapAt(Hps, 30, 80, (CW - 60) Div 8, CopyErr, CLR_BLACK);
    Exit;
  End;
  TextCenter(Hps, 40, L('L''installation d''OS/2-0 est termin'#130'e.', 'The installation of OS/2-0 is complete.',
             'Die Installation von OS/2-0 ist abgeschlossen.', 'La instalaci'#162'n de OS/2-0 ha terminado.',
             'L''installazione di OS/2-0 '#138' completata.', 'Instalimi i OS/2-0 p'#137'rfundoi.'), CLR_DARKBLUE);
  H := WrapAt(Hps, 30, 80, (CW - 60) Div 8, IStr(CopiedFiles) + L(' fichiers copi'#130's (', ' files copied (',
       ' Dateien kopiert (', ' archivos copiados (', ' file copiati (', ' skedar'#137' u kopjuan (') + IStr(TotBytes Div 1024) +
       ' Ko). ' + L('Le disque dur d'#130'marre maintenant OS/2-0 : la partition HPFS sera l''unit'#130' C:.',
       'The hard disk now starts OS/2-0: the HPFS partition will be drive C:.',
       'Die Festplatte startet jetzt OS/2-0: die HPFS-Partition wird Laufwerk C:.',
       'El disco duro arranca ahora OS/2-0: la partici'#162'n HPFS ser'#160' la unidad C:.',
       'Il disco fisso avvia ora OS/2-0: la partizione HPFS sar'#133' l''unit'#133' C:.',
       'Disku nis tani OS/2-0: ndarja HPFS do t'#137' jet'#137' nj'#137'sia C:.'), CLR_BLACK);
  H := WrapAt(Hps, 30, 170, (CW - 60) Div 8, L(
    'Retirez le CD-ROM du lecteur, puis s'#130'lectionnez Red'#130'marrer. La langue (' + LangName(Lang) + ') et les '
    + 'autres r'#130'glages pourront '#136'tre modifi'#130's dans la Configuration du syst'#138'me.',
    'Remove the CD-ROM from the drive, then select Restart. The language (' + LangName(Lang) + ') and the other '
    + 'settings can be changed later in System Setup.',
    'Entnehmen Sie die CD-ROM und w'#132'hlen Sie Neu starten. Die Sprache (' + LangName(Lang) + ') kann sp'#132'ter in '
    + 'der Systemkonfiguration ge'#132'ndert werden.',
    'Retire el CD-ROM y seleccione Reiniciar. El idioma (' + LangName(Lang) + ') se puede cambiar despu'#130's en la '
    + 'Configuraci'#162'n del sistema.',
    'Rimuovere il CD-ROM e selezionare Riavvia. La lingua (' + LangName(Lang) + ') si potr'#133' cambiare nella '
    + 'Configurazione del sistema.',
    'Hiqni CD-ROM dhe zgjidhni Rinis. Gjuha (' + LangName(Lang) + ') mund t'#137' ndryshohet m'#137' von'#137' n'#137' '
    + 'Konfigurimin e sistemit.'), CLR_BLACK);
End;

Procedure PaintPage(H : LongInt);
Var Hps : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  If Hps = 0 Then Exit;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
  Case Page Of
    PG_WELCOME : PaintWelcome(Hps);
    PG_CONFIG : PaintConfig(Hps);
    PG_DISK : PaintDisk(Hps);
    PG_FORMAT : PaintFormat(Hps);
    PG_COMP : PaintComp(Hps);
    PG_COPY : PaintCopy(Hps);
    PG_DONE : PaintDone(Hps);
  End;
  Dummy := WinEndPaint(Hps);
End;

{ ==================================================================== }
{ Configuration du systeme                                              }
{ ==================================================================== }

Procedure InitConfig;
Var K, N, M : LongInt; Q : Array[0..7] Of LongInt; Dup : Boolean;
Begin
  For K := 0 To NCfg - 1 Do
  Begin
    CfgVal[K] := 0; CfgCnt[K] := 1; CfgSpin[K] := False;
  End;
  CfgCnt[CF_COUNTRY] := NCountry; CfgCnt[CF_KBD] := NCountry; CfgCnt[CF_LANG] := NLang;
  CfgCnt[CF_MOUSE] := 2; CfgCnt[CF_SERIAL] := 2; CfgCnt[CF_APM] := 2; CfgCnt[CF_CDROM] := 3;
  CfgCnt[CF_PRINTER] := 2; CfgCnt[CF_MMEDIA] := 2; CfgCnt[CF_SCSI] := 2;
  CfgSpin[CF_CDROM] := True; CfgSpin[CF_PRINTER] := True; CfgSpin[CF_MMEDIA] := True; CfgSpin[CF_SCSI] := True;
  CfgVal[CF_LANG] := Lang; CfgVal[CF_COUNTRY] := DefCountry[Lang]; CfgVal[CF_KBD] := DefCountry[Lang];
  { affichage : VGA, puis les modes VESA de 800 x 600 au moins (256
    couleurs et plus) }
  NDisp := 1; DispW[0] := 640; DispH[0] := 480; DispB[0] := 4;
  K := 1;
  M := 0;
  While (K <= 200) And (NDisp < 32) And (M = 0) Do
  Begin
    FillChar(Q, SizeOf(Q), 0);
    If VioQueryModes(K, LongInt(@Q)) = 0 Then M := 1
    Else
    Begin
      Dup := False;
      For N := 0 To NDisp - 1 Do
        If (DispW[N] = Q[0]) And (DispH[N] = Q[1]) And (DispB[N] = Q[2]) Then Dup := True;
      If (Not Dup) And (Q[0] >= 800) And (Q[0] <= 1280) And ((Q[2] = 8) Or (Q[2] = 16) Or (Q[2] = 32)) Then
      Begin
        DispW[NDisp] := Q[0]; DispH[NDisp] := Q[1]; DispB[NDisp] := Q[2];
        Inc(NDisp);
      End;
    End;
    Inc(K);
  End;
  CfgCnt[CF_DISP] := NDisp;
  { positions : deux colonnes ; parametres regionaux, systeme, peripheriques }
  CfgX[CF_COUNTRY] := 16; CfgY[CF_COUNTRY] := 58;
  CfgX[CF_KBD] := 300; CfgY[CF_KBD] := 58;
  CfgX[CF_LANG] := 16; CfgY[CF_LANG] := 92;
  CfgX[CF_MOUSE] := 16; CfgY[CF_MOUSE] := 146;
  CfgX[CF_DISP] := 300; CfgY[CF_DISP] := 146;
  CfgX[CF_SERIAL] := 16; CfgY[CF_SERIAL] := 180;
  CfgX[CF_DISP2] := 300; CfgY[CF_DISP2] := 180;
  CfgX[CF_APM] := 16; CfgY[CF_APM] := 234;
  CfgX[CF_PCMCIA] := 300; CfgY[CF_PCMCIA] := 234;
  CfgX[CF_CDROM] := 16; CfgY[CF_CDROM] := 268;
  CfgX[CF_PRINTER] := 300; CfgY[CF_PRINTER] := 268;
  CfgX[CF_MMEDIA] := 16; CfgY[CF_MMEDIA] := 302;
  CfgX[CF_SCSI] := 300; CfgY[CF_SCSI] := 302;
End;

{ clic dans la page de configuration : icone ou titre -> liste ; fleches }
Procedure ConfigClick(X, Y : LongInt);
Var I, T : LongInt;
Begin
  T := CH - Y;          { distance depuis le haut }
  For I := 0 To NCfg - 1 Do
  Begin
    If (X >= CfgX[I]) And (X < CfgX[I] + 28) And (T >= CfgY[I]) And (T < CfgY[I] + 28) Then
    Begin
      If CfgCnt[I] > 1 Then Dummy := WinPostMsg(Client, WM_OPENCHOICE, I, 0);
      Exit;
    End;
    If (X >= CfgX[I] + 36) And (X < CfgX[I] + 36 + Length(CfgTitle(I)) * 8) And (T >= CfgY[I] - 2) And
       (T < CfgY[I] + 14) Then
    Begin
      If CfgCnt[I] > 1 Then Dummy := WinPostMsg(Client, WM_OPENCHOICE, I, 0);
      Exit;
    End;
    If CfgSpin[I] And (X >= CfgX[I] + 238) And (X <= CfgX[I] + 250) And (T >= CfgY[I] + 16) And (T <= CfgY[I] + 34) Then
    Begin
      If T < CfgY[I] + 25 Then CfgVal[I] := (CfgVal[I] + 1) Mod CfgCnt[I]
      Else CfgVal[I] := (CfgVal[I] + CfgCnt[I] - 1) Mod CfgCnt[I];
      Dummy := WinInvalidateRect(Client, 0, 1);
      Exit;
    End;
  End;
End;

{ ==================================================================== }
{ Partition cible : choix, creation, formatage                          }
{ ==================================================================== }

Procedure SetStatus(S : String);
Begin
  StatusMsg := S;
  Dummy := WinInvalidateRect(Client, 0, 1);
End;

Function SelectedRow : LongInt;
Begin
  SelectedRow := -1;
  If (Page = PG_DISK) And (NCtl > 0) Then SelectedRow := WinSendMsg(Ctl[0], LM_QUERYSELECTION, -1, 0);
End;

{ creer une partition HPFS (07h) dans l'espace libre A..B ; Mo = taille }
Function CreatePart(A, B, MbW : LongInt) : LongInt;
Var K, E, N : LongInt;
Begin
  CreatePart := -1;
  E := -1;
  For K := 3 DownTo 0 Do
    If PType[K] = 0 Then E := K;
  If E < 0 Then
  Begin
    SetStatus(L('La table des partitions est pleine (4 partitions principales).', 'The partition table is full.',
              'Die Partitionstabelle ist voll.', 'La tabla de particiones est'#160' llena.',
              'La tabella delle partizioni '#138' piena.', 'Tabela e ndarjeve '#137'sht'#137' plot'#137'.'));
    Exit;
  End;
  A := MaxI(A, FirstLba);
  A := ((A + 2047) Div 2048) * 2048;
  N := MbW * 2048;
  If (N <= 0) Or (A + N > B) Then N := B - A;
  N := (N Div 2048) * 2048;
  If N < 16 * 2048 Then
  Begin
    SetStatus(L('Une partition doit avoir au moins 16 Mo.', 'A partition needs at least 16 MB.',
              'Eine Partition braucht mindestens 16 MB.', 'Una partici'#162'n necesita al menos 16 MB.',
              'Una partizione richiede almeno 16 MB.', 'Nj'#137' ndarje do t'#137' ket'#137' t'#137' pakt'#137'n 16 MB.'));
    Exit;
  End;
  PType[E] := 7; PStart[E] := A; PCount[E] := N; PFlag[E] := 0;
  If Not WriteTable(DiskCur, False) Then
  Begin
    SetStatus(L('Erreur d''ecriture du disque.', 'Disk write error.', 'Schreibfehler.', 'Error de escritura.',
              'Errore di scrittura.', 'Gabim n'#137' shkrim.'));
    Exit;
  End;
  CreatePart := E;
End;

Procedure DiskCommand(Id : LongInt);
Var R, E, MbW, K, Hw : LongInt; S : String;
Begin
  R := SelectedRow;
  Case Id Of
    ID_PNEXT :
      Begin
        DiskCur := (DiskCur + 1) Mod MaxI(1, NDiskT);
        SelRow := 0;
        FillPartList;
        Dummy := WinInvalidateRect(Client, 0, 1);
      End;
    ID_PCREATE :
      If (R >= 0) And (R < NRow) And (RowKind[R] = 1) Then
      Begin
        Dummy := WinQueryWindowText(Ctl[1], 16, LongInt(@TxtBuf));
        S := GetZ(LongInt(@TxtBuf));
        Val(S, MbW, K);
        If (K <> 0) Or (S = '') Then MbW := 0;
        E := CreatePart(RowA[R], RowB[R], MbW);
        If E >= 0 Then
        Begin
          SelRow := R;
          StatusMsg := '';
          FillPartList;
          { la nouvelle partition est a la place de l'espace libre }
          For K := 0 To NRow - 1 Do
            If (RowKind[K] = 0) And (RowA[K] = E) Then SelRow := K;
          Dummy := WinSendMsg(Ctl[0], LM_SELECTITEM, SelRow, 1);
          Dummy := WinInvalidateRect(Client, 0, 1);
        End;
      End
      Else SetStatus(L('Choisissez d''abord un espace libre.', 'Select a free space first.', 'Zuerst freien Speicher w'#132'hlen.',
                       'Elija primero un espacio libre.', 'Scegliere prima uno spazio libero.',
                       'Zgjidhni s'#137' pari nj'#137' hap'#137'sir'#137' t'#137' lir'#137'.'));
    ID_PDELETE :
      If (R >= 0) And (R < NRow) And (RowKind[R] = 0) Then
      Begin
        E := RowA[R];
        If AskYes(L('Supprimer la partition ', 'Delete partition ', 'Partition l'#148'schen: ', 'Eliminar la partici'#162'n ',
                    'Eliminare la partizione ', 'Fshi ndarjen ') + IStr(E + 1) + ' (' + IStr(Mb(PCount[E])) + ' Mo) ? ' +
                  L('Toutes ses donn'#130'es seront perdues.', 'All its data will be lost.', 'Alle Daten gehen verloren.',
                    'Se perder'#160'n todos sus datos.', 'Tutti i dati andranno persi.', 'T'#137' gjitha t'#137' dh'#137'nat do t'#137' humbasin.')) Then
        Begin
          Dummy := KDisk(6, DiskCur, PStart[E]);
          PType[E] := 0; PStart[E] := 0; PCount[E] := 0; PFlag[E] := 0;
          If Not WriteTable(DiskCur, False) Then SetStatus('Erreur d''ecriture du disque.');
          StatusMsg := '';
          FillPartList;
          Dummy := WinInvalidateRect(Client, 0, 1);
        End;
      End;
    ID_PINSTALL :
      If (R >= 0) And (R < NRow) And (RowKind[R] = 0) And (PType[RowA[R]] = 7) Then
      Begin
        E := RowA[R];
        If FirstUsed < MinFree Then
          SetStatus(L('Le d'#130'but du disque doit '#136'tre libre (2 Mo) pour la zone d''amor'#135'age d''OS/2-0 : '
                      + 'supprimez et recr'#130'ez les partitions.',
                      'The start of the disk must be free (2 MB) for the OS/2-0 boot area: delete and create the partitions again.',
                      'Der Anfang der Platte (2 MB) muss frei sein: Partitionen neu erstellen.',
                      'El principio del disco (2 MB) debe estar libre: vuelva a crear las particiones.',
                      'L''inizio del disco (2 MB) deve essere libero: ricreare le partizioni.',
                      'Fillimi i diskut (2 MB) duhet t'#137' jet'#137' i lir'#137': krijoni p'#137'rs'#137'ri ndarjet.'))
        Else
        Begin
          TgtEntry := E; TgtStart := PStart[E]; TgtCount := PCount[E];
          TgtDrive := KDisk(4, DiskCur, TgtStart);
          SelRow := R;
          GoPage(PG_FORMAT);
        End;
      End
      Else SetStatus(L('Choisissez une partition HPFS (07h), ou cr'#130'ez-en une dans un espace libre.',
                       'Select an HPFS (07h) partition, or create one in a free space.',
                       'W'#132'hlen Sie eine HPFS-Partition (07h) oder erstellen Sie eine.',
                       'Elija una partici'#162'n HPFS (07h) o cree una.', 'Scegliere una partizione HPFS (07h) o crearne una.',
                       'Zgjidhni nj'#137' ndarje HPFS (07h) ose krijoni nj'#137'.'));
    ID_PPREV : GoPage(PG_CONFIG);
  End;
End;

{ formatage (ou montage si les fichiers sont conserves) de la partition }
Function DoFormat(Keep : Boolean; Lbl : String) : Boolean;
Var R : LongInt;
Begin
  DoFormat := False;
  If Keep And (TgtDrive >= 2) Then
  Begin
    DoFormat := True;
    Exit;
  End;
  PutZ(LongInt(@TxtBuf), Copy(Lbl, 1, 11));
  Prm[0] := TgtStart; Prm[1] := TgtCount; Prm[2] := LongInt(@TxtBuf); Prm[3] := -1;
  R := KDisk(5, DiskCur, LongInt(@Prm));
  If (R = 0) And (Prm[3] >= 3) Then
  Begin
    TgtDrive := Prm[3];
    Formatted := 1;
    DoFormat := True;
  End
  Else CopyErr := L('Le formatage a '#130'chou'#130' (erreur ', 'Formatting failed (error ', 'Formatieren fehlgeschlagen (Fehler ',
                    'Error al formatear (error ', 'Formattazione non riuscita (errore ', 'Formatimi d'#137'shtoi (gabim ') +
                  IStr(R) + ').';
End;

{ installation facile : premier disque, partition HPFS existante (la plus
  grande) ou tout l'espace libre }
Function EasyDisk : Boolean;
Var K, E, Best : LongInt;
Begin
  EasyDisk := False;
  ScanDisks;
  If NDiskT = 0 Then
  Begin
    CopyErr := L('Aucun disque dur IDE n''a '#130't'#130' trouv'#130'.', 'No IDE hard disk was found.',
                 'Keine IDE-Festplatte gefunden.', 'No se encontr'#162' ning'#163'n disco duro IDE.',
                 'Nessun disco fisso IDE trovato.', 'Nuk u gjet asnj'#137' disk IDE.');
    Exit;
  End;
  DiskCur := 0;
  ReadTable(0);
  E := -1;
  If FirstUsed >= MinFree Then
    For K := 0 To 3 Do
      If PType[K] = 7 Then
        If (E < 0) Or (PCount[K] > PCount[E]) Then E := K;
  If E < 0 Then
  Begin
    BuildRows;
    Best := -1;
    For K := 0 To NRow - 1 Do
      If RowKind[K] = 1 Then
        If (Best < 0) Or (RowB[K] - RowA[K] > RowB[Best] - RowA[Best]) Then Best := K;
    If (Best >= 0) And (FirstUsed >= MinFree) Then E := CreatePart(RowA[Best], RowB[Best], 0);
  End;
  If E < 0 Then
  Begin
    CopyErr := L('Pas d''espace libre sur le premier disque dur : utilisez l''installation avanc'#130'e.',
                 'No free space on the first hard disk: use the Advanced Installation.',
                 'Kein freier Speicher: verwenden Sie die erweiterte Installation.',
                 'No hay espacio libre: utilice la instalaci'#162'n avanzada.',
                 'Nessuno spazio libero: usare l''installazione avanzata.',
                 'Nuk ka hap'#137'sir'#137' t'#137' lir'#137': p'#137'rdorni instalimin e avancuar.');
    Exit;
  End;
  TgtEntry := E; TgtStart := PStart[E]; TgtCount := PCount[E];
  TgtDrive := KDisk(4, 0, TgtStart);
  EasyDisk := DoFormat(False, 'OS2-0');
End;

{ ==================================================================== }
{ Transfert des fichiers, CONFIG.SYS, zone d'amorcage, MBR             }
{ ==================================================================== }

Function Dst(N : String) : String;
Begin
  Dst := Chr(65 + TgtDrive) + ':\' + N;
End;

Procedure Fail(S : String);
Begin
  If CopyErr = '' Then CopyErr := S;
  CopyStep := CS_END;
End;

Function OpenRead(N : String) : LongInt;
Var H, A : LongInt;
Begin
  H := 0; A := 0;
  If DosOpen(Z(N), LongInt(@H), LongInt(@A), 0, 0, 1, $40, 0) <> 0 Then H := 0;
  OpenRead := H;
End;

Function OpenWrite(N : String) : LongInt;
Var H, A : LongInt;
Begin
  H := 0; A := 0;
  If DosOpen(Z(N), LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0) <> 0 Then H := 0;
  OpenWrite := H;
End;

Procedure WLine(H : LongInt; S : String);
Var W : LongInt;
Begin
  S := S + #13#10;
  PutZ(LongInt(@TxtBuf), S);
  Dummy := DosWrite(H, LongInt(@TxtBuf), Length(S), LongInt(@W));
End;

{ CONFIG.SYS du disque dur }
Function WriteConfig : Boolean;
Var H : LongInt; S : String;
Begin
  WriteConfig := False;
  H := OpenWrite(Dst('CONFIG.SYS'));
  If H = 0 Then Exit;
  WLine(H, 'REM CONFIG.SYS de OS/2-0 (installe sur le disque dur par INSTALL.EXE)');
  If OptDesk <> 0 Then WLine(H, 'PROTSHELL=C:\PMSHELL.EXE') Else WLine(H, 'PROTSHELL=C:\CMD.EXE');
  WLine(H, 'LIBPATH=C:\;');
  S := 'IFS=C:\HPFS.IFS /CACHE:64 /AUTOCHECK:C';
  If OptRam <> 0 Then S := S + ' /RAMDISK:4096';
  WLine(H, S);
  WLine(H, 'SET COMSPEC=C:\CMD.EXE');
  WLine(H, 'SET PATH=C:\;');
  WLine(H, 'SET LANGUAGE=' + LangCode(Lang));
  WLine(H, 'SET HELP=C:\AIDE;');
  WLine(H, 'SET OS2_SHELL=C:\CMD.EXE');
  If OptDesk <> 0 Then WLine(H, 'SET RUNWORKPLACE=C:\PMSHELL.EXE');
  If OptMM <> 0 Then
  Begin
    WLine(H, 'REM Son : SET AUDIODRIVER=SBAUDIO, ICHAUDIO, ESAUDIO ou NONE (sans elle : detection)');
    WLine(H, 'REM SET BLASTER=A220 I5 D1 H5 T6');
  End;
  If CfgVal[CF_DISP] > 0 Then
    WLine(H, 'SET PMRESOLUTION=' + IStr(DispW[CfgVal[CF_DISP]]) + 'x' + IStr(DispH[CfgVal[CF_DISP]]) + 'x' +
          IStr(DispB[CfgVal[CF_DISP]]));
  WLine(H, 'COUNTRY=' + CountryCode[CfgVal[CF_COUNTRY]] + ',C:\COUNTRY.SYS');
  WLine(H, 'CODEPAGE=850,437');
  WLine(H, 'DEVINFO=KBD,' + KbdCode[CfgVal[CF_KBD]] + ',C:\KEYBOARD.DCP');
  If CfgVal[CF_MOUSE] = 0 Then WLine(H, 'DEVICE=C:\MOUSE.SYS TYPE=PS2$');
  If CfgVal[CF_SERIAL] = 1 Then WLine(H, 'DEVICE=C:\COM.SYS');
  If CfgVal[CF_APM] = 0 Then WLine(H, 'DEVICE=C:\APM.SYS');
  If CfgVal[CF_CDROM] = 0 Then WLine(H, 'BASEDEV=IBMIDECD.FLT');
  If CfgVal[CF_PRINTER] = 1 Then WLine(H, 'REM Imprimante : IBM Null sur LPT1 (file LPT1Q de PMSPL.DLL)');
  Dummy := DosClose(H);
  WriteConfig := True;
End;

{ zone d'amorcage : repertoire au secteur 1, puis OS2LDR, OS2KRNL et
  HPFS.IFS (secteurs de 512 octets) }
Function WriteBootArea : Boolean;
Var K, Lba, N, Got, H, Sec, J : LongInt; Nm : String;
Begin
  WriteBootArea := False;
  Lba := 2;
  For K := 0 To 2 Do
  Begin
    Case K Of
      0 : Nm := 'OS2LDR';
      1 : Nm := 'OS2KRNL';
    Else
      Nm := 'HPFS.IFS';
    End;
    BootSizeT[K] := -1;
    For J := 0 To NFiles - 1 Do
      If FName[J] = Nm Then BootSizeT[K] := FSize[J];
    If BootSizeT[K] < 0 Then
    Begin
      Fail(Nm + L(' introuvable sur le CD-ROM.', ' not found on the CD-ROM.', ' fehlt auf der CD-ROM.',
                  ' no se encuentra en el CD-ROM.', ' non trovato sul CD-ROM.', ' nuk gjendet n'#137' CD-ROM.'));
      Exit;
    End;
    BootLbaT[K] := Lba;
    Lba := Lba + (BootSizeT[K] + 511) Div 512;
  End;
  If Lba > FirstUsed Then
  Begin
    Fail(L('La zone d''amor'#135'age (d'#130'but du disque) est trop petite.', 'The boot area (start of the disk) is too small.',
           'Der Startbereich ist zu klein.', 'El '#160'rea de arranque es demasiado peque'#164'a.',
           'L''area di avvio '#138' troppo piccola.', 'Zona e nisjes '#137'sht'#137' shum'#137' e vog'#137'l.'));
    Exit;
  End;
  { repertoire }
  FillChar(CopyBuf, 512, 0);
  PutZ(LongInt(@CopyBuf), 'OS20BOOT');
  WrL(LongInt(@CopyBuf) + 8, 3);
  For K := 0 To 2 Do
  Begin
    Case K Of
      0 : Nm := 'OS2LDR';
      1 : Nm := 'OS2KRNL';
    Else
      Nm := 'HPFS.IFS';
    End;
    PutZ(LongInt(@CopyBuf) + 16 + K * 32, Nm);
    WrL(LongInt(@CopyBuf) + 16 + K * 32 + 16, BootLbaT[K]);
    WrL(LongInt(@CopyBuf) + 16 + K * 32 + 20, BootSizeT[K]);
  End;
  If DiskRW(DiskCur, 1, 1, LongInt(@CopyBuf), True) <> 0 Then
  Begin
    Fail('Erreur d''ecriture du disque (zone d''amorcage).');
    Exit;
  End;
  { fichiers }
  For K := 0 To 2 Do
  Begin
    Case K Of
      0 : Nm := 'OS2LDR';
      1 : Nm := 'OS2KRNL';
    Else
      Nm := 'HPFS.IFS';
    End;
    H := OpenRead('C:\' + Nm);
    If H = 0 Then
    Begin
      Fail(Nm + L(' illisible.', ' cannot be read.', ' nicht lesbar.', ' ilegible.', ' illeggibile.', ' nuk lexohet.'));
      Exit;
    End;
    Sec := BootLbaT[K];
    Repeat
      FillChar(CopyBuf, ChunkSize, 0);
      Got := 0;
      Dummy := DosRead(H, LongInt(@CopyBuf), ChunkSize, LongInt(@Got));
      If Got > 0 Then
      Begin
        N := (Got + 511) Div 512;
        If DiskRW(DiskCur, Sec, N, LongInt(@CopyBuf), True) <> 0 Then
        Begin
          Dummy := DosClose(H);
          Fail('Erreur d''ecriture du disque (zone d''amorcage).');
          Exit;
        End;
        Sec := Sec + N;
      End;
    Until Got < ChunkSize;
    Dummy := DosClose(H);
  End;
  WriteBootArea := True;
End;

{ secteur 0 : code d'amorce d'OS/2-0 et partition active }
Function WriteMbr : Boolean;
Var K : LongInt;
Begin
  ReadTable(DiskCur);
  For K := 0 To 3 Do
    If (PType[K] <> 0) And (PStart[K] = TgtStart) Then PFlag[K] := $80 Else PFlag[K] := 0;
  WriteMbr := WriteTable(DiskCur, True);
End;

Procedure StartCopy;
Begin
  CopyErr := ''; CurName := ''; DoneBytes := 0; CopiedFiles := 0; CurF := 0; HSrc := 0; HDst := 0;
  CopyStep := CS_LIST; ShownName := ''; ShownFill := 0;
  GoPage(PG_COPY);
  Dummy := WinStartTimer(Hab, Client, 1, 20);
End;

{ une etape du transfert (minuterie) : 256 Ko au plus }
Procedure CopyTick;
Var Budget, Got, W : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  Budget := 8;
  While (Budget > 0) And (CopyStep <> CS_END) Do
  Begin
    Dec(Budget);
    Case CopyStep Of
      CS_LIST :
        Begin
          ListFiles;
          If NFiles = 0 Then Fail('Aucun fichier sur le CD-ROM.') Else CopyStep := CS_FILE;
        End;
      CS_FILE :
        If CurF >= NFiles Then CopyStep := CS_DIRS
        Else
        Begin
          If HSrc = 0 Then
          Begin
            CurName := 'C:\' + FName[CurF];
            HSrc := OpenRead('C:\' + FName[CurF]);
            HDst := OpenWrite(Dst(FName[CurF]));
            If (HSrc = 0) Or (HDst = 0) Then
            Begin
              If HSrc <> 0 Then Dummy := DosClose(HSrc);
              If HDst <> 0 Then Dummy := DosClose(HDst);
              HSrc := 0; HDst := 0;
              Fail(L('Impossible de copier ', 'Cannot copy ', 'Kopieren unm'#148'glich: ', 'No se puede copiar ',
                     'Impossibile copiare ', 'Nuk kopjohet ') + FName[CurF] + '.');
            End;
            Budget := 0;
          End
          Else
          Begin
            Got := 0;
            Dummy := DosRead(HSrc, LongInt(@CopyBuf), ChunkSize, LongInt(@Got));
            If Got > 0 Then
            Begin
              W := 0;
              If (DosWrite(HDst, LongInt(@CopyBuf), Got, LongInt(@W)) <> 0) Or (W <> Got) Then
              Begin
                Fail(L('Le disque est plein ou illisible : ', 'The disk is full or cannot be written: ',
                       'Platte voll oder nicht beschreibbar: ', 'Disco lleno o ilegible: ', 'Disco pieno o non scrivibile: ',
                       'Disku '#137'sht'#137' plot ose nuk shkruhet: ') + FName[CurF]);
                Got := 0;
              End;
              DoneBytes := DoneBytes + Got;
            End;
            If Got < ChunkSize Then
            Begin
              Dummy := DosClose(HSrc); Dummy := DosClose(HDst);
              HSrc := 0; HDst := 0;
              Inc(CopiedFiles);
              Inc(CurF);
              Budget := 0;
            End;
          End;
        End;
      CS_DIRS :
        Begin
          Dummy := DosCreateDir(Z(Dst('DESKTOP')), 0);
          Dummy := DosCreateDir(Z(Dst('AIDE')), 0);
          If WriteConfig Then CopyStep := CS_BOOT
          Else Fail(L('Impossible d''ecrire CONFIG.SYS.', 'Cannot write CONFIG.SYS.', 'CONFIG.SYS nicht schreibbar.',
                      'No se puede escribir CONFIG.SYS.', 'Impossibile scrivere CONFIG.SYS.', 'Nuk shkruhet CONFIG.SYS.'));
          CurName := Chr(65 + TgtDrive) + ':\CONFIG.SYS';
          Budget := 0;
        End;
      CS_BOOT :
        Begin
          CurName := L('Zone d''amor'#135'age du disque', 'Disk boot area', 'Startbereich der Platte', ''#181'rea de arranque',
                       'Area di avvio', 'Zona e nisjes');
          If WriteBootArea Then CopyStep := CS_MBR;
          Budget := 0;
        End;
      CS_MBR :
        Begin
          If WriteMbr Then
          Begin
            Dummy := KDisk(8, 0, 0);
            CopyStep := CS_END;
          End
          Else Fail('Erreur d''ecriture du secteur d''amorce.');
        End;
    End;
  End;
  { seules les zones qui changent sont redessinees }
  If CurName <> ShownName Then
  Begin
    Rc[0] := 30; Rc[1] := CH - 176; Rc[2] := CW - 30; Rc[3] := CH - 156;
    Dummy := WinInvalidateRect(Client, LongInt(@Rc), 1);
  End;
  If BarFill Div 14 <> ShownFill Then
  Begin
    Rc[0] := 30; Rc[1] := CH - 264; Rc[2] := CW - 30; Rc[3] := CH - 200;
    Dummy := WinInvalidateRect(Client, LongInt(@Rc), 1);
  End;
  If CopyStep = CS_END Then
  Begin
    Dummy := WinStopTimer(Hab, Client, 1);
    If HSrc <> 0 Then Dummy := DosClose(HSrc);
    If HDst <> 0 Then Dummy := DosClose(HDst);
    HSrc := 0; HDst := 0;
    Dummy := KDisk(8, 0, 0);
    GoPage(PG_DONE);
  End;
End;

{ ==================================================================== }
{ Fenetres                                                              }
{ ==================================================================== }

Procedure HelpPage;
Var S : String;
Begin
  Case Page Of
    PG_CONFIG : S := L('Cliquez sur l''ic'#147'ne ou le titre d''un choix pour voir la liste des valeurs ; les champs a '
                       + 'fl'#138'ches changent avec les fl'#138'ches. La langue choisie devient SET LANGUAGE= dans CONFIG.SYS.',
                       'Select the icon or the title of a choice to see its values; the fields with arrows change with '
                       + 'the arrows. The language becomes SET LANGUAGE= in CONFIG.SYS.',
                       'Symbol oder Titel w'#132'hlen, um die Werte zu sehen. Die Sprache wird SET LANGUAGE= in CONFIG.SYS.',
                       'Seleccione el icono o el t'#161'tulo para ver los valores. El idioma se escribe en CONFIG.SYS.',
                       'Selezionare l''icona o il titolo per vedere i valori. La lingua viene scritta in CONFIG.SYS.',
                       'Zgjidhni ikon'#137'n ose titullin p'#137'r t'#137' par'#137' vlerat. Gjuha shkruhet n'#137' CONFIG.SYS.');
    PG_DISK : S := L('OS/2-0 s''installe sur une partition principale HPFS (07h). Les 4 premiers Mo du disque restent '
                     + 'libres : ils recoivent la zone d''amor'#135'age (OS2LDR, OS2KRNL, HPFS.IFS).',
                     'OS/2-0 is installed on an HPFS (07h) primary partition. The first 4 MB of the disk stay free for the '
                     + 'boot area (OS2LDR, OS2KRNL, HPFS.IFS).',
                     'OS/2-0 wird auf einer primaeren HPFS-Partition installiert. Die ersten 4 MB bleiben frei (Startbereich).',
                     'OS/2-0 se instala en una partici'#162'n primaria HPFS. Los primeros 4 MB quedan libres (arranque).',
                     'OS/2-0 si installa su una partizione primaria HPFS. I primi 4 MB restano liberi (avvio).',
                     'OS/2-0 instalohet n'#137' nj'#137' ndarje kryesore HPFS. 4 MB e para mbeten t'#137' lira (nisja).');
    PG_FORMAT : S := L('Le formatage HPFS est fait par le pilote HPFS.IFS. Choisissez Ne pas formater pour r'#130'installer '
                       + 'OS/2-0 sur une partition HPFS en gardant ses fichiers.',
                       'HPFS formatting is done by the HPFS.IFS driver. Select Do not format to reinstall OS/2-0 on an HPFS '
                       + 'partition and keep its files.', 'HPFS.IFS formatiert die Partition.', 'HPFS.IFS formatea la partici'#162'n.',
                       'HPFS.IFS formatta la partizione.', 'HPFS.IFS formaton ndarjen.');
  Else
    S := L('Utilisez la souris ou la touche Tab et Entr'#130'e pour choisir.', 'Use the mouse, or Tab and Enter.',
           'Maus oder Tabulator und Eingabe verwenden.', 'Use el rat'#162'n, o Tab y Intro.', 'Usare il mouse, o Tab e Invio.',
           'P'#137'rdorni miun, ose Tab dhe Enter.');
  End;
  ShowMsg(S, TxtHelp, MB_OK Or MB_INFORMATION);
End;

Procedure Command(Id : LongInt);
Var Keep : Boolean; K : LongInt;
Begin
  If ChFrame <> 0 Then Exit;
  Case Id Of
    ID_EASY :
      Begin
        Advanced := 0;
        GoPage(PG_CONFIG);
      End;
    ID_ADV :
      Begin
        Advanced := 1;
        GoPage(PG_CONFIG);
      End;
    ID_QUIT :
      If AskYes(L('Quitter l''installation et red'#130'marrer l''ordinateur ?', 'Exit the installation and restart the computer?',
                  'Installation beenden und neu starten?', ''#168'Salir de la instalaci'#162'n y reiniciar?',
                  'Uscire dall''installazione e riavviare?', 'T'#137' dilet nga instalimi dhe t'#137' riniset kompjuteri?')) Then
        Dummy := KDisk(9, 0, 0);
    ID_BACK :
      Case Page Of
        PG_CONFIG : GoPage(PG_WELCOME);
        PG_FORMAT : GoPage(PG_DISK);
        PG_COMP : If Advanced <> 0 Then GoPage(PG_FORMAT) Else GoPage(PG_CONFIG);
      End;
    ID_HELP : HelpPage;
    ID_OK :
      If Page = PG_CONFIG Then
      Begin
        If Advanced <> 0 Then GoPage(PG_DISK)
        Else
        Begin
          SetStatus('');
          If EasyDisk Then
          Begin
            CopyErr := '';
            StartCopy;
          End
          Else
          Begin
            ShowMsg(CopyErr, TxtSetup, MB_OK Or MB_ERROR);
            CopyErr := '';
          End;
        End;
      End;
    ID_PCREATE, ID_PDELETE, ID_PINSTALL, ID_PPREV, ID_PNEXT : DiskCommand(Id);
    ID_FGO :
      Begin
        Keep := False;
        For K := 0 To NCtl - 1 Do
          If (K = 2) And Checked(Ctl[K]) Then Keep := True;
        If Not Keep Then
          If Not AskYes(L('Formater la partition ? Toutes ses donn'#130'es seront perdues.',
                          'Format the partition? All its data will be lost.', 'Partition formatieren? Alle Daten gehen verloren.',
                          ''#168'Formatear la partici'#162'n? Se perder'#160'n todos los datos.',
                          'Formattare la partizione? Tutti i dati andranno persi.',
                          'T'#137' formatohet ndarja? T'#137' gjitha dh'#137'nat do t'#137' humbasin.')) Then Exit;
        Dummy := WinQueryWindowText(Ctl[3], 12, LongInt(@NameZ2));
        StatusMsg := L('Formatage en cours, veuillez patienter...', 'Formatting, please wait...',
                       'Formatierung l'#132'uft, bitte warten...', 'Formateando, espere por favor...',
                       'Formattazione in corso, attendere...', 'Po formatohet, ju lutemi prisni...');
        Dummy := WinInvalidateRect(Client, 0, 1);
        If Keep Then Dummy := WinPostMsg(Client, WM_DOFORMAT, 1, 0) Else Dummy := WinPostMsg(Client, WM_DOFORMAT, 0, 0);
      End;
    ID_CGO :
      Begin
        For K := 0 To NCtl - 1 Do
        Begin
          If K = 1 Then OptDesk := Ord(Checked(Ctl[K]));
          If K = 2 Then OptUtil := Ord(Checked(Ctl[K]));
          If K = 3 Then OptTest := Ord(Checked(Ctl[K]));
          If K = 4 Then OptRam := Ord(Checked(Ctl[K]));
          If K = 5 Then OptGames := Ord(Checked(Ctl[K]));
          If K = 6 Then OptMM := Ord(Checked(Ctl[K]));
        End;
        StartCopy;
      End;
    ID_REBOOT : Dummy := KDisk(9, 0, 0);
  End;
End;

{ Tab, Maj+Tab : controle suivant ou precedent de la page }
Procedure TabFocus(Back : Boolean);
Var F, K, I, N : LongInt;
Begin
  If NCtl = 0 Then Exit;
  F := WinQueryFocus(HWND_DESKTOP);
  I := -1;
  For K := 0 To NCtl - 1 Do
    If Ctl[K] = F Then I := K;
  N := 0;
  Repeat
    If Back Then I := (I + NCtl - 1) Mod NCtl Else I := (I + 1) Mod NCtl;
    If I < 0 Then I := 0;
    Inc(N);
  Until (WinIsWindowEnabled(Ctl[I]) <> 0) Or (N > NCtl);
  Dummy := WinSetFocus(HWND_DESKTOP, Ctl[I]);
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Lbl : String; Ok : Boolean;
Begin
  MainProc := 0;
  Case Msg Of
    WM_PAINT : PaintPage(H);
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CONTROL :
      If (Page = PG_COMP) And (Lo16(Mp1) >= ID_CDESK) And (Lo16(Mp1) <= ID_CMM) Then
      Begin
        OptDesk := Ord(Checked(Ctl[1])); OptUtil := Ord(Checked(Ctl[2]));
        OptTest := Ord(Checked(Ctl[3])); OptRam := Ord(Checked(Ctl[4])); OptGames := Ord(Checked(Ctl[5])); OptMM := Ord(Checked(Ctl[6]));
        Dummy := WinInvalidateRect(Client, 0, 1);
      End
      Else If (Page = PG_DISK) And (Lo16(Mp1) = ID_PLIST) Then
      Begin
        If Hi16(Mp1) = LN_ENTER Then DiskCommand(ID_PINSTALL)
        Else If Hi16(Mp1) = LN_SELECT Then
        Begin
          SelRow := SelectedRow;
          If (SelRow >= 0) And (SelRow < NRow) And (RowKind[SelRow] = 1) Then
          Begin
            PutZ(LongInt(@TxtBuf), IStr(Mb(RowB[SelRow] - MaxI(RowA[SelRow], FirstLba))));
            Dummy := WinSetWindowText(Ctl[1], LongInt(@TxtBuf));
          End;
        End;
      End;
    WM_BUTTON1DOWN :
      Begin
        If (Page = PG_CONFIG) And (ChFrame = 0) Then ConfigClick(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_TIMER : If (Page = PG_COPY) And (Lo16(Mp1) = 1) Then CopyTick;
    WM_OPENCHOICE : If (Page = PG_CONFIG) And (ChFrame = 0) Then OpenChoice(Mp1);
    WM_DOFORMAT :
      Begin
        Lbl := GetZ(LongInt(@NameZ2));
        If Lbl = '' Then Lbl := 'OS2-0';
        CopyErr := '';
        Ok := DoFormat(Mp1 <> 0, Lbl);
        StatusMsg := '';
        If Ok Then GoPage(PG_COMP)
        Else
        Begin
          ShowMsg(CopyErr, TxtSetup, MB_OK Or MB_ERROR);
          CopyErr := '';
          Dummy := WinInvalidateRect(Client, 0, 1);
        End;
      End;
    WM_DOAUTO :
      Begin
        If EasyDisk Then StartCopy
        Else
        Begin
          CopyStep := CS_END;
          GoPage(PG_DONE);
        End;
      End;
    WM_CLOSE : Command(ID_QUIT);
    WM_CHAR :
      If ((Lo16(Mp1) And KC_KEYUP) = 0) And ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And
         ((Hi16(Mp2) = VK_TAB) Or (Hi16(Mp2) = VK_BACKTAB)) Then
      Begin
        TabFocus((Hi16(Mp2) = VK_BACKTAB) Or ((Lo16(Mp1) And KC_SHIFT) <> 0));
        MainProc := 1;
      End
      Else If ((Lo16(Mp1) And KC_KEYUP) = 0) And ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And (Hi16(Mp2) = VK_F1) Then
        HelpPage
      Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ fond de l'ecran (turquoise, comme l'installation de Warp 3) }
Function BgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  BgProc := 0;
  If Msg = WM_ACTIVATE Then
  Begin
    If Mp1 <> 0 Then Dummy := WinSetWindowPos(H, HWND_BOTTOM, 0, 0, 0, 0, SWP_ZORDER);
    BgProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End
  Else If Msg = WM_PAINT Then
  Begin
    Hps := WinBeginPaint(H, 0, 0);
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
    Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_DARKCYAN);
    PutZ(LongInt(@TxtBuf), 'OS/2-0');
    Rc[0] := Rc[2] - 64; Rc[1] := 4; Rc[3] := 20;
    Dummy := WinDrawText(Hps, 6, LongInt(@TxtBuf), LongInt(@Rc), CLR_WHITE, CLR_DARKCYAN, 0);
    Dummy := WinEndPaint(Hps);
  End
  Else BgProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

Var
  Fl, I : LongInt;
  Rc0 : Array[0..3] Of LongInt;
  P : String;

BEGIN
  Lang := 0; AutoMode := 0; Advanced := 0; Page := PG_WELCOME;
  NCtl := 0; ChFrame := 0; ChClient := 0; ChList := 0; ChItem := -1;
  DiskCur := 0; SelRow := 0; TgtDrive := -1; Formatted := 0;
  OptDesk := 1; OptUtil := 1; OptTest := 0; OptRam := 0; OptGames := 1; OptMM := 1;
  CopyErr := ''; StatusMsg := ''; CurName := ''; CopyStep := CS_LIST; TotBytes := 0; DoneBytes := 0;
  { langue de l'environnement (CONFIG.SYS du CD-ROM), puis parametres }
  I := 0;
  If DosScanEnv(Z('LANGUAGE'), LongInt(@I)) = 0 Then Lang := LangOfCode(GetZ(I));
  For I := 1 To ParamCount Do
  Begin
    P := UpStr(ParamStr(I));
    If P = '/AUTO' Then AutoMode := 1;
    If Copy(P, 1, 6) = '/LANG:' Then Lang := LangOfCode(Copy(P, 7, 5));
  End;
  InitConfig;
  ScanDisks;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  Dummy := WinRegisterClass(Hab, Z('INSTALL'), LongInt(@MainProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('INSTBG'), LongInt(@BgProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('INSTCHOICE'), LongInt(@ChoiceProc), 0, 0);
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20); ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  BgWin := WinCreateWindow(HWND_DESKTOP, Z('INSTBG'), Z(''), WS_VISIBLE, 0, 0, ScrW, ScrH, 0, HWND_BOTTOM, 1, 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('INSTALL'), Z2(TxtSetup), 0, 0, 0, LongInt(@Client));
  Dummy := WinSetWindowPos(Frame, HWND_TOP, (ScrW - 600) Div 2, (ScrH - 440) Div 2, 600, 440,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinQueryWindowRect(Client, LongInt(@Rc0));
  CW := Rc0[2]; CH := Rc0[3];
  BuildPage;
  If AutoMode <> 0 Then Dummy := WinPostMsg(Client, WM_DOAUTO, 0, 0);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
END.
