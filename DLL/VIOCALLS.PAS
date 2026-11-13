{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 VIOCALLS.DLL de OS/2-0 (sous-systeme
                video VIO : fonctions Vio* et AVIO).
}

Library VIOCALLS;

{$IMAGEBASE $00F00000}
{$R-,S-,I-}

{ Compilation : OS2PC VIOCALLS.PAS   (produit VIOCALLS.DLL)

  VIOCALLS.DLL est le sous-systeme video d'OS/2 (VIO) : ecriture et
  lecture de l'ecran texte, defilement, curseur, modes, etats du VGA
  (palette, couleurs, bordure, clignotement), polices, sortie en mode
  teletype avec les sequences ANSI, fenetres surgissantes, verrou de
  l'ecran, tampon video logique (LVB), impression de l'ecran, ainsi que
  les espaces de presentation AVIO (VioCreatePS...).

  Modes : texte 80 x 25 et, par VioSetMode, les modes graphiques du VGA
  640 x 480 x 16 (12h), 640 x 480 x 2 (11h), 640 x 350 x 16 (10h),
  640 x 200 x 16 (0Eh), 320 x 200 x 16 (0Dh) et 320 x 200 x 256 (13h) :
  memoire en 000A0000h (VioGetPhysBuf), fonctions du mode texte refusees
  (ERROR_VIO_MODE), retour au texte par VioSetMode (police et palette
  rechargees).

  Dans OS/2-0, les programmes et les DLL s'executent en anneau 0 :
  VIOCALLS.DLL ecrit directement dans la memoire de l'ecran (000B8000h)
  et programme le VGA par ses ports (CRTC, controleur d'attributs, DAC,
  sequenceur). La position du curseur et l'attribut courant sont ceux de
  la console du noyau (SetConsoleCursorPosition, GetConsoleScreenBuffer-
  Info...), de sorte que VIO et WriteLn restent coherents ; VioWrtTty
  passe par la console du noyau (copie sur le port serie, zone de
  defilement reduite par FKA.DLL respectee).

  Convention _System (comme DOSCALLS.DLL) : toutes les valeurs passees
  sont de 32 bits ; les pointeurs sont des adresses lineaires. Un
  pointeur vers une valeur simple (pusRow, pcb, pfAnsi...) designe un
  LongInt ; les structures (VIOMODEINFO, VIOCURSORINFO, VIOCONFIGINFO,
  VIOFONTINFO, VIOPHYSBUF, etats VIO...) gardent leur disposition d'OS/2
  (champs USHORT de 16 bits). Exemple :

    Function VioWrtCharStr(PStr, Cb, Row, Col, Hvio : LongInt) : LongInt;
      External 'VIOCALLS';

  Le handle hvio 0 designe l'ecran ; un handle rendu par VioCreatePS
  designe un espace de presentation AVIO (tampon de cellules en memoire,
  affiche a l'ecran par VioShowPS une fois associe par VioAssociate).

  Fonctions exportees (ordinaux d'origine de VIOCALLS.DLL) :

     1 VioEndPopup        27 VioGetCurType        53 VioWrtNChar
     2 VioGetPhysBuf      28 VioSavRedrawUndo     54 VioShellInit
     3 VioGetAnsi         29 VioGetFont           55 VioAssociate
     4 VioFree            30 VioReadCharStr       56 VioCreatePS
     5 VioSetAnsi         31 VioGetBuf            57 VioDeleteSetId
     6 VioDeRegister      32 VioSetCurType        58 VioGetDeviceCellSize
     7 VioScrollUp        33 VioSetFont           59 VioGetOrg
     8 VioPrtSc           34 VioHetInit           60 VioCreateLogFont
     9 VioGetCurPos       35 VioModeUndo          61 VioDestroyPS
    10 VioWrtCellStr      36 VioSswSwitch         62 VioQuerySetIds
    11 VioPopUp           37 VioModeWait          63 VioSetOrg
    12 VioScrollRt (VioScrollRi)                  64 VioQueryFonts
    13 VioWrtCharStr      38 Avs_PrtscToggle      65 VioSetDeviceCellSize
    14 Avs_Prtsc          39 VioInit              66 VioShowPS
    15 VioSetCurPos (VioSetCursorPos)             67 VioGetPSAddress
    16 VioSrfUnblock      40 VioGetCp             68 VioQueryConsole
    17 VioSrfBlock        41 VioRestore           69 VioRedrawSize
    18 VioScrUnlock       42 VioSetCp             70 VioGlobalReg
    19 VioWrtTty          43 VioShowBuf           71 XVioSetCAState
    20 VioSave            44 VioScrollLf (VioScrollLe)
    21 VioGetMode         45 VioRegister          72 XVioCheckCharType
    22 VioSetMode         46 VioGetConfig         73 XVioDestroyCA
    23 VioScrLock         47 VioScrollDn          74 XVioCreateCA
    24 VioReadCellStr     48 VioWrtCharStrAtt     75 VioCheckCharType
    25 VioSavRedrawWait   49 VioGetState          76 XVioGetCAState
    26 VioWrtNAttr        50 VioPrtScToggle
                          51 VioSetState
                          52 VioWrtNCell

  Le detail des parametres est donne avec chaque fonction. Fonctions non
  documentees d'OS/2 (VioFree, VioSave, VioRestore, VioSswSwitch,
  VioInit, VioShellInit, VioHetInit, VioSrfBlock, VioSrfUnblock,
  VioGetPSAddress, VioQueryConsole, VioRedrawSize, Avs_*, XVio*) : leur
  role et leurs parametres dans OS/2-0 sont decrits avec leur code.

  Remplacement du sous-systeme (VioRegister, VioGlobalReg) : pour chaque
  fonction choisie par les masques flFun1/flFun2 (bits VR_* d'OS/2), la
  fonction de remplacement est appelee (convention _System) par
    Entree(Fonction, pParametres, NombreDeParametres)
  ou Fonction est le numero du bit VR_* (0 = VioGetCurPos ... 40 =
  VioSetState) et pParametres l'adresse des parametres d'appel (LongInt,
  dans l'ordre de declaration). Si elle rend la valeur de poursuite (-1
  pour VioRegister, usReturn pour VioGlobalReg), la fonction de base est
  executee ; sinon sa valeur est rendue a l'appelant.

  Organisation :
    Partie 1  - Constantes, types et variables
    Partie 2  - Services du noyau et de DOSCALLS.DLL
    Partie 3  - Utilitaires (memoire, chaines, ports)
    Partie 4  - Surfaces : ecran, ecran bloque, espaces AVIO
    Partie 5  - Materiel VGA : curseur, palette, polices
    Partie 6  - Remplacement du sous-systeme (VioRegister)
    Partie 7  - Ecriture, lecture et defilement
    Partie 8  - Teletype et ANSI
    Partie 9  - Fonctions Vio* de base
    Partie 10 - Modes, etats, polices et configuration
    Partie 11 - Sessions : fenetres surgissantes, verrou, sauvegarde
    Partie 12 - Espaces de presentation AVIO
    Partie 13 - Jeux de caracteres a double octet (XVio*)
    Exportations et initialisation }

{ ==================================================================== }
{ Partie 1 - Constantes, types et variables                            }
{ ==================================================================== }

Const
  NO_ERROR                  = 0;
  ERROR_ACCESS_DENIED       = 5;
  ERROR_INVALID_PARAMETER   = 87;
  ERROR_INTERRUPT           = 95;
  ERROR_VIO_INVALID_MASK    = 349;
  ERROR_VIO_PTR             = 350;
  ERROR_VIO_MODE            = 355;
  ERROR_VIO_WIDTH           = 356;
  ERROR_VIO_ATTR            = 357;
  ERROR_VIO_ROW             = 358;
  ERROR_VIO_COL             = 359;
  ERROR_VIO_TOPROW          = 360;
  ERROR_VIO_BOTROW          = 361;
  ERROR_VIO_RIGHTCOL        = 362;
  ERROR_VIO_LEFTCOL         = 363;
  ERROR_VIO_WAIT_FLAG       = 366;
  ERROR_VIO_UNLOCK          = 367;
  ERROR_VIO_NO_SAVE_RESTORE_THD = 393;
  ERROR_VIO_NO_MODE_THREAD  = 395;
  ERROR_VIO_REGISTER        = 404;
  ERROR_VIO_NO_POPUP        = 405;
  ERROR_VIO_EXISTING_POPUP  = 406;
  ERROR_VIO_INVALID_PARMS   = 421;
  ERROR_VIO_DEREGISTER      = 427;
  ERROR_VIO_INVALID_HANDLE  = 436;
  ERROR_VIO_INVALID_LENGTH  = 438;
  ERROR_VIO_BAD_CP          = 465;
  ERROR_VIO_FONT            = 467;
  ERROR_VIO_USER_FONT       = 468;
  ERROR_VIO_NA_CP           = 469;
  ERROR_VIO_LOCK            = 375;

  ScrBase   = $000B8000;          { memoire de l'ecran texte }
  FontMem   = $000A0000;          { plan 2 : generateur de caracteres }
  NCols     = 80;
  NRows     = 25;
  ScrBytes  = NCols * NRows * 2;

  MaxPS     = 8;                  { espaces de presentation AVIO }
  MaxLcid   = 4;
  MaxLvb    = 8;
  MaxCA     = 8;

  { types de caracteres (VioCheckCharType) }
  VCC_SBCSCHAR     = 0;
  VCC_DBCSFULLCHAR = 1;
  VCC_DBCS1STHALF  = 2;
  VCC_DBCS2NDHALF  = 3;

  { bits VR_* (VioRegister) : numero de la fonction dans les masques }
  VB_GETCURPOS = 0;  VB_GETCURTYPE = 1;  VB_GETMODE = 2;    VB_GETBUF = 3;
  VB_GETPHYSBUF = 4; VB_SETCURPOS = 5;   VB_SETCURTYPE = 6; VB_SETMODE = 7;
  VB_SHOWBUF = 8;    VB_READCHARSTR = 9; VB_READCELLSTR = 10; VB_WRTNCHAR = 11;
  VB_WRTNATTR = 12;  VB_WRTNCELL = 13;   VB_WRTTTY = 14;    VB_WRTCHARSTR = 15;
  VB_WRTCHARSTRATT = 16; VB_WRTCELLSTR = 17; VB_SCROLLUP = 18; VB_SCROLLDN = 19;
  VB_SCROLLLF = 20;  VB_SCROLLRT = 21;   VB_SETANSI = 22;   VB_GETANSI = 23;
  VB_PRTSC = 24;     VB_SCRLOCK = 25;    VB_SCRUNLOCK = 26; VB_SAVREDRAWWAIT = 27;
  VB_SAVREDRAWUNDO = 28; VB_POPUP = 29;  VB_ENDPOPUP = 30;  VB_PRTSCTOGGLE = 31;
  VB_MODEWAIT = 32;  VB_MODEUNDO = 33;   VB_GETFONT = 34;   VB_GETCONFIG = 35;
  VB_SETCP = 36;     VB_GETCP = 37;      VB_SETFONT = 38;   VB_GETSTATE = 39;
  VB_SETSTATE = 40;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

  { espace de presentation AVIO }
  TPS = Record
    Used     : Boolean;
    Owner    : LongInt;       { processus }
    Rows     : LongInt;       { profondeur }
    Cols     : LongInt;       { largeur }
    CellSz   : LongInt;       { 2 (format CGA) ou 4 (format a 4 octets) }
    Buf      : LongInt;       { cellules }
    CurRow, CurCol : LongInt;
    CurStart, CurEnd, CurAttr : LongInt;
    OrgRow, OrgCol : LongInt; { cellule affichee en haut a gauche }
    Hdc      : LongInt;       { contexte associe (0 = aucun) }
    WinCx, WinCy : LongInt;   { taille de la fenetre du DC (WM_SIZE par
                                WinDefAVioWindowProc de PMVIOP ; 0 : inconnue) }
    CellH, CellW : LongInt;   { taille d'une cellule en pels }
    Attr     : LongInt;       { attribut du teletype }
    Ansi     : Boolean;
    Lcid     : Array[0..MaxLcid - 1] Of LongInt;   { identificateurs locaux (0 = libre) }
    LcH      : Array[0..MaxLcid - 1] Of LongInt;   { hauteur de la police }
  End;

  TLvb = Record
    Pid      : LongInt;
    Addr     : LongInt;
  End;

  { jeu d'attributs de caracteres etendus (XVio) }
  TCA = Record
    Used     : Boolean;
    Flags    : LongInt;       { 1 souligne, 2 inverse, 4 clignotant,
                                8 intense, 16 cache }
    Color    : LongInt;       { attribut de couleur (-1 = inchange) }
  End;

Var
  PS        : Array[1..MaxPS] Of TPS;
  Lvbs      : Array[0..MaxLvb - 1] Of TLvb;
  CAs       : Array[1..MaxCA] Of TCA;
  CurCA     : LongInt;        { jeu actif (0 = aucun) }
  CAOn      : Boolean;

  { ecran }
  ScrAnsi   : Boolean;
  CodePage  : LongInt;
  CurStart, CurEnd, CurWidth, CurAttr : LongInt;   { forme du curseur }
  CellHeight : LongInt;
  Blocked   : Boolean;        { VioSrfBlock : ecritures dans Shadow }
  Shadow    : Array[0..ScrBytes - 1] Of Byte;
  ShRow, ShCol : LongInt;
  ScrLocked : Boolean;
  LockPid   : LongInt;
  InPopup   : Boolean;
  PopPid    : LongInt;
  PopBuf    : Array[0..ScrBytes - 1] Of Byte;
  PopRow, PopCol, PopAttr : LongInt;
  Saved     : Boolean;        { VioSave }
  SaveBuf   : Array[0..ScrBytes - 1] Of Byte;
  SaveRow, SaveCol, SaveAttr : LongInt;
  SwapBuf   : Array[0..ScrBytes - 1] Of Byte;
  PrtEcho   : Boolean;        { Ctrl+PrtSc : copie du teletype }
  PrtFile   : String;
  ModeWaitPid, RedrawWaitPid : LongInt;
  Underline : LongInt;
  Target    : LongInt;
  Overscan  : LongInt;
  Blink     : LongInt;        { 0 clignotement, 1 fond intense }

  { polices : courante et d'origine (lue au chargement de la DLL) }
  FontBuf   : Array[0..8191] Of Byte;
  RomFont   : Array[0..8191] Of Byte;
  RomOk     : Boolean;
  DefPal    : Array[0..15] Of Byte;
  DefDac    : Array[0..767] Of Byte;

  { teletype et ANSI : sequence en cours (peut s'etendre sur plusieurs
    appels de VioWrtTty) }
  EscState  : LongInt;        { 0 texte, 1 ESC lu, 2 dans ESC[ }
  EscBuf    : String;
  AnsiRow, AnsiCol : LongInt; { ESC[s / ESC[u }
  TtyAttr   : LongInt;        { attribut du teletype (surfaces autres que l'ecran) }

  { remplacement du sous-systeme }
  RegEntry, RegFun1, RegFun2, RegPass : LongInt;
  GlbEntry, GlbFun1, GlbFun2, GlbPass : LongInt;
  InHook    : Boolean;
  HookRet   : LongInt;
  Prm       : Array[0..7] Of LongInt;

  Scratch   : Array[0..1023] Of Byte;
  PrtName   : Array[0..127] Of Byte;
  LcNames   : Array[0..MaxPS * MaxLcid * 32 - 1] Of Byte;  { noms des polices logiques }
  InfoBuf   : Array[0..31] Of Word;
  LineBuf   : Array[0..255] Of Byte;
  ConH      : LongInt;
  Dummy     : LongInt;
  { mode graphique : numero du mode VGA (0 : texte 80 x 25), largeur,
    hauteur, bits par pel, octets d'un plan }
  GrMode, GrW, GrH, GrBits, GrPlane : LongInt;   { mode du materiel }
  GrLfb, GrPitch : LongInt;                { mode VESA : memoire lineaire, octets par ligne }
  VesaN : LongInt;                         { modes VESA du BIOS (-1 : pas encore lus) }
  VesaNo, VesaW, VesaH, VesaB, VesaPitch, VesaLfb : Array[0..95] Of LongInt;
  SesAddr, HookOk : LongInt;               { etat des sessions du noyau }
  SesGr : Array[0..15] Of LongInt;         { mode graphique de chaque session }
  PopGr     : LongInt;        { mode graphique a rendre apres VioEndPopup }

{ ==================================================================== }
{ Partie 2 - Services du noyau et de DOSCALLS.DLL                      }
{ ==================================================================== }

Function KGetStdHandle(N : LongInt) : LongInt; External 'DOSCALLS' Name 'GetStdHandle';
Function KWriteConsoleA(H, Buf, N, PWritten, Res : LongInt) : LongInt; External 'DOSCALLS' Name 'WriteConsoleA';
Function KSetConsoleCursorPosition(H, Coord : LongInt) : LongInt; External 'DOSCALLS' Name 'SetConsoleCursorPosition';
Function KGetConsoleScreenBufferInfo(H, P : LongInt) : LongInt; External 'DOSCALLS' Name 'GetConsoleScreenBufferInfo';
Function KSetConsoleTextAttribute(H, Attr : LongInt) : LongInt; External 'DOSCALLS' Name 'SetConsoleTextAttribute';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KGetProcessHeap : LongInt; External 'DOSCALLS' Name 'GetProcessHeap';
Function KHeapAlloc(H, Flags, Size : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapAlloc';
Function KHeapFree(H, Flags, P : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapFree';
Function KBeep(Freq, Dur : LongInt) : LongInt; External 'DOSCALLS' Name 'Beep';
Function DosLoadModule(PFail, CbFail, PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryModuleHandle(PName, PH : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Dist, Method, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';
Function KVid(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnVideo';

{ ==================================================================== }
{ Partie 3 - Utilitaires (memoire, chaines, ports)                     }
{ ==================================================================== }

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

Procedure MoveB(Src, Dst, N : LongInt);
Var PS, PD : PByte;
Begin
  If (N <= 0) Or (Src = 0) Or (Dst = 0) Then Exit;
  PS := Pointer(Src);
  PD := Pointer(Dst);
  Move(PS^, PD^, N);
End;

Procedure FillB(Dst, N, V : LongInt);
Var PD : PByte;
Begin
  If (N <= 0) Or (Dst = 0) Then Exit;
  PD := Pointer(Dst);
  FillChar(PD^, N, V);
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

Procedure PutZ(A : LongInt; S : String; Max : LongInt);
Var I, L : LongInt;
Begin
  If (A = 0) Or (Max <= 0) Then Exit;
  L := Length(S);
  If L > Max - 1 Then L := Max - 1;
  For I := 1 To L Do WrB(A + I - 1, Ord(S[I]));
  WrB(A + L, 0);
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@Scratch), S, 512);
  Z := LongInt(@Scratch);
End;

{ Valeur signee d'un USHORT (FFFFh = -1) }
Function S16(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V >= $8000 Then V := V - $10000;
  S16 := V;
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

{ --- ports d'entree/sortie (anneau 0) --- }

{ l'ecran est-il a la session de l'appelant ? (sinon, les ports du VGA
  ne sont pas touches : ils appartiennent a la session au premier plan) }
Function Mine : Boolean;
Type PLong = ^LongInt;
Var Q : PLong; F, C, S : LongInt;
Begin
  If SesAddr = 0 Then SesAddr := KSes(15, 0, 0);
  If SesAddr = 0 Then
  Begin
    Mine := True;
    Exit;
  End;
  Q := Pointer(SesAddr); F := Q^;
  Q := Pointer(SesAddr + 4); C := Q^;
  Q := Pointer(SesAddr + 12); S := Q^;
  Mine := (F = C) Or (S <> 0);
End;

Function CurSesNo : LongInt;
Type PLong = ^LongInt;
Var Q : PLong;
Begin
  If SesAddr = 0 Then SesAddr := KSes(15, 0, 0);
  If SesAddr = 0 Then CurSesNo := 0
  Else
  Begin
    Q := Pointer(SesAddr + 4);
    CurSesNo := Q^ And 15;
  End;
End;

Procedure OutB(P, V : LongInt);
Begin
  If Not Mine Then Exit;
  asm
    mov edx,P
    mov eax,V
    out dx,al
  end;
End;

Function InB(P : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  asm
    mov edx,P
    xor eax,eax
    in al,dx
    mov R,eax
  end;
  InB := R;
End;

Function CrtcGet(I : LongInt) : LongInt;
Begin
  OutB($3D4, I);
  CrtcGet := InB($3D5);
End;

Procedure CrtcSet(I, V : LongInt);
Begin
  OutB($3D4, I);
  OutB($3D5, V);
End;

{ Controleur d'attributs : lecture et ecriture d'un registre (3C0h/3C1h) }
Function AcGet(I : LongInt) : LongInt;
Var V : LongInt;
Begin
  Dummy := InB($3DA);
  OutB($3C0, I);
  V := InB($3C1);
  Dummy := InB($3DA);
  OutB($3C0, $20);
  AcGet := V;
End;

Procedure AcSet(I, V : LongInt);
Begin
  Dummy := InB($3DA);
  OutB($3C0, I);
  OutB($3C0, V);
  Dummy := InB($3DA);
  OutB($3C0, $20);
End;

Procedure DacGet(I, A : LongInt);
Begin
  OutB($3C7, I);
  WrB(A, InB($3C9));
  WrB(A + 1, InB($3C9));
  WrB(A + 2, InB($3C9));
End;

Procedure DacSet(I, A : LongInt);
Begin
  OutB($3C8, I);
  OutB($3C9, RdB(A) And 63);
  OutB($3C9, RdB(A + 1) And 63);
  OutB($3C9, RdB(A + 2) And 63);
End;

{ Acces au plan 2 du VGA (generateur de caracteres) en 000A0000h }
Procedure FontPlaneOn;
Begin
  OutB($3C4, 2); OutB($3C5, 4);          { ecriture : plan 2 }
  OutB($3C4, 4); OutB($3C5, 7);          { memoire sequentielle }
  OutB($3CE, 4); OutB($3CF, 2);          { lecture : plan 2 }
  OutB($3CE, 5); OutB($3CF, 0);
  OutB($3CE, 6); OutB($3CF, 4);          { 000A0000h, 64 Ko }
End;

Procedure FontPlaneOff;
Begin
  OutB($3C4, 2); OutB($3C5, 3);
  OutB($3C4, 4); OutB($3C5, 3);
  OutB($3CE, 4); OutB($3CF, 0);
  OutB($3CE, 5); OutB($3CF, $10);
  OutB($3CE, 6); OutB($3CF, $0E);
End;

{ Lire la police du VGA (Height lignes par caractere) dans Dst }
Procedure ReadFont(Dst, Height : LongInt);
Var C : LongInt;
Begin
  FontPlaneOn;
  For C := 0 To 255 Do MoveB(FontMem + C * 32, Dst + C * Height, Height);
  FontPlaneOff;
End;

Procedure WriteFont(Src, Height : LongInt);
Var C : LongInt;
Begin
  FontPlaneOn;
  For C := 0 To 255 Do
  Begin
    MoveB(Src + C * Height, FontMem + C * 32, Height);
    If Height < 32 Then FillB(FontMem + C * 32 + Height, 32 - Height, 0);
  End;
  FontPlaneOff;
End;

{ Fichier d'impression (VioPrtSc, Ctrl+PrtSc) : ajouter N octets }
Procedure PrtWrite(Buf, N : LongInt);
Var H, Act, Got, NewPos : LongInt;
Begin
  PutZ(LongInt(@PrtName), PrtFile, 128);
  If DosOpen(LongInt(@PrtName), LongInt(@H), LongInt(@Act), 0, 0, $11, $42, 0) = 0 Then
  Begin
    DosSetFilePtr(H, 0, 2, LongInt(@NewPos));
    DosWrite(H, Buf, N, LongInt(@Got));
    DosClose(H);
  End;
End;

{ ==================================================================== }
{ Partie 4 - Surfaces : ecran, ecran bloque, espaces AVIO              }
{ ==================================================================== }
{ Une surface est l'ecran (hvio 0 ; le tampon Shadow pendant
  VioSrfBlock) ou un espace de presentation AVIO (handle 1 a MaxPS). }

{ Code d'erreur si le handle n'est pas utilisable par le processus }
Function SurfErr(Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If Hvio <> 0 Then
  Begin
    If (Hvio < 1) Or (Hvio > MaxPS) Then R := ERROR_VIO_INVALID_HANDLE
    Else If Not PS[Hvio].Used Then R := ERROR_VIO_INVALID_HANDLE
    Else If PS[Hvio].Owner <> MyPid Then R := ERROR_VIO_INVALID_HANDLE;
  End;
  SurfErr := R;
End;

Function SBase(S : LongInt) : LongInt;
Begin
  If S <> 0 Then SBase := PS[S].Buf
  Else If Blocked Then SBase := LongInt(@Shadow)
  Else SBase := ScrBase;
End;

Function SCols(S : LongInt) : LongInt;
Begin
  If S <> 0 Then SCols := PS[S].Cols Else SCols := NCols;
End;

Function SRows(S : LongInt) : LongInt;
Begin
  If S <> 0 Then SRows := PS[S].Rows Else SRows := NRows;
End;

Function SCell(S : LongInt) : LongInt;
Begin
  If S <> 0 Then SCell := PS[S].CellSz Else SCell := 2;
End;

Function CellAt(S, R, C : LongInt) : LongInt;
Begin
  CellAt := SBase(S) + (R * SCols(S) + C) * SCell(S);
End;

{ Etat de la console du noyau dans InfoBuf : [0] colonnes, [1] lignes de
  la zone de defilement, [2] colonne, [3] ligne, [4] attribut }
Procedure ConInfo;
Begin
  KGetConsoleScreenBufferInfo(ConH, LongInt(@InfoBuf));
End;

Procedure GetCur(S : LongInt; Var R, C : LongInt);
Begin
  If S <> 0 Then
  Begin
    R := PS[S].CurRow; C := PS[S].CurCol;
  End
  Else If Blocked Then
  Begin
    R := ShRow; C := ShCol;
  End
  Else
  Begin
    ConInfo;
    R := InfoBuf[3]; C := InfoBuf[2];
  End;
End;

Procedure SetCur(S, R, C : LongInt);
Begin
  If S <> 0 Then
  Begin
    PS[S].CurRow := R; PS[S].CurCol := C;
  End
  Else If Blocked Then
  Begin
    ShRow := R; ShCol := C;
  End
  Else
    KSetConsoleCursorPosition(ConH, (R Shl 16) Or C);
End;

{ Lignes de la zone de teletype (l'ecran peut etre reduit par FKA.DLL) }
Function TtyRows(S : LongInt) : LongInt;
Begin
  If S <> 0 Then TtyRows := PS[S].Rows
  Else If Blocked Then TtyRows := NRows
  Else
  Begin
    ConInfo;
    TtyRows := InfoBuf[1];
  End;
End;

Function GetAttr(S : LongInt) : LongInt;
Begin
  If S <> 0 Then GetAttr := PS[S].Attr
  Else If Blocked Then GetAttr := TtyAttr
  Else
  Begin
    ConInfo;
    GetAttr := InfoBuf[4] And $FF;
  End;
End;

Procedure SetAttr(S, A : LongInt);
Begin
  A := A And $FF;
  If S <> 0 Then PS[S].Attr := A
  Else
  Begin
    TtyAttr := A;
    If Not Blocked Then KSetConsoleTextAttribute(ConH, A);
  End;
End;

Function AnsiOf(S : LongInt) : Boolean;
Begin
  If S <> 0 Then AnsiOf := PS[S].Ansi Else AnsiOf := ScrAnsi;
End;

{ Attribut modifie par le jeu de caracteres etendus actif (XVio) }
Function ApplyCA(A : LongInt) : LongInt;
Var F : LongInt;
Begin
  If CAOn And (CurCA >= 1) And (CurCA <= MaxCA) Then
    If CAs[CurCA].Used Then
    Begin
      If CAs[CurCA].Color >= 0 Then A := CAs[CurCA].Color;
      F := CAs[CurCA].Flags;
      If (F And 2) <> 0 Then A := (A And $88) Or ((A And 7) Shl 4) Or ((A Shr 4) And 7);
      If (F And 4) <> 0 Then A := A Or $80;
      If (F And 8) <> 0 Then A := A Or 8;
      If (F And 16) <> 0 Then A := (A And $F0) Or ((A Shr 4) And 7);
    End;
  ApplyCA := A And $FF;
End;

{ Attribut etendu (troisieme octet d'une cellule de 4 octets) }
Function ExtAttr : LongInt;
Begin
  ExtAttr := 0;
  If CAOn And (CurCA >= 1) And (CurCA <= MaxCA) Then
    If CAs[CurCA].Used Then ExtAttr := CAs[CurCA].Flags And $FF;
End;

{ Afficher sur l'ecran les cellules d'un espace AVIO associe (region de
  Depth lignes et Width colonnes a partir de la cellule Ofs) }
{ --- PS associe au DC d'une fenetre de PM (WinOpenWindowDC : 4443xxxxh) :
  les cellules sont dessinees dans la fenetre par PMWIN.DLL (appels
  dynamiques : PMWIN importe VIOCALLS) --- }
Var
  PmFn : Array[0..4] Of LongInt;   { WinWindowFromDC, WinGetPS, WinReleasePS, WinDrawText, WinQueryWindowRect }
  PmFnOk : LongInt;
  PmName : Array[0..31] Of Byte;

Function CallSys1(F, A1 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,4
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallSys1 := R;
End;

Function CallSys2(F, A1, A2 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,8
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallSys2 := R;
End;

Function CallSys7(F, A1, A2, A3, A4, A5, A6, A7 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A7
    push eax
    mov eax,A6
    push eax
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
    add esp,28
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallSys7 := R;
End;

Function PmAddr(H : LongInt; S : String) : LongInt;
Var K, P : LongInt;
Begin
  For K := 1 To Length(S) Do PmName[K - 1] := Ord(S[K]);
  PmName[Length(S)] := 0;
  P := 0;
  If DosQueryProcAddr(H, 0, LongInt(@PmName), LongInt(@P)) <> 0 Then P := 0;
  PmAddr := P;
End;

{ points d'entree de PMWIN (PMWIN.DLL chargee : programme de PM) }
Function PmReady : Boolean;
Var H : LongInt;
Begin
  If PmFnOk = 0 Then
  Begin
    H := 0;
    PmName[0] := Ord('P'); PmName[1] := Ord('M'); PmName[2] := Ord('W'); PmName[3] := Ord('I');
    PmName[4] := Ord('N'); PmName[5] := 0;
    If (DosQueryModuleHandle(LongInt(@PmName), LongInt(@H)) = 0) And (H <> 0) Then
    Begin
      PmFn[0] := PmAddr(H, 'WinWindowFromDC'); PmFn[1] := PmAddr(H, 'WinGetPS');
      PmFn[2] := PmAddr(H, 'WinReleasePS'); PmFn[3] := PmAddr(H, 'WinDrawText');
      PmFn[4] := PmAddr(H, 'WinQueryWindowRect');
      If (PmFn[0] <> 0) And (PmFn[1] <> 0) And (PmFn[2] <> 0) And (PmFn[3] <> 0) And (PmFn[4] <> 0) Then PmFnOk := 1;
    End;
  End;
  PmReady := PmFnOk <> 0;
End;

Function IsWinDC(Hdc : LongInt) : Boolean;
Begin
  IsWinDC := (Hdc >= $44430000) And (Hdc < $44440000);
End;

{ couleurs du VGA -> couleurs de PM (CLR_*) }
Function PmClr(V : LongInt) : LongInt;
Begin
  Case V And 15 Of
    0 : PmClr := -1;  1 : PmClr := 9;   2 : PmClr := 12;  3 : PmClr := 13;
    4 : PmClr := 10;  5 : PmClr := 11;  6 : PmClr := 14;  7 : PmClr := 15;
    8 : PmClr := 8;   9 : PmClr := 1;   10 : PmClr := 4;  11 : PmClr := 5;
    12 : PmClr := 2;  13 : PmClr := 3;  14 : PmClr := 6;
  Else
    PmClr := -2;
  End;
End;

{ taille de la fenetre du PS I (WM_SIZE, sinon rectangle de la fenetre) }
Procedure WinSizeOf(I, H : LongInt; Var Cx, Cy : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Cx := PS[I].WinCx; Cy := PS[I].WinCy;
  If (Cx <= 0) Or (Cy <= 0) Then
  Begin
    Rc[0] := 0; Rc[1] := 0; Rc[2] := 0; Rc[3] := 0;
    If CallSys2(PmFn[4], H, LongInt(@Rc)) <> 0 Then
    Begin
      Cx := Rc[2] - Rc[0]; Cy := Rc[3] - Rc[1];
    End;
  End;
End;

{ lignes R0 a R0 + Depth - 1, colonnes C0 a C0 + Width - 1 du PS dans la
  fenetre : cellule (OrgRow, OrgCol) en haut a gauche, CellH pels par ligne }
Procedure PaintWin(I, R0, C0, Depth, Width : LongInt);
Var H, Hps, Cx, Cy, VisR, VisC, R, C, CE, Cs, N, A, A0, Ch : LongInt; Rc : Array[0..3] Of LongInt;
    B : Array[0..255] Of Byte;
Begin
  If Not PmReady Then Exit;
  H := CallSys1(PmFn[0], PS[I].Hdc);
  If H = 0 Then Exit;
  WinSizeOf(I, H, Cx, Cy);
  If PS[I].CellH < 1 Then Exit;
  VisR := Cy Div PS[I].CellH; VisC := Cx Div 8;
  If (VisR <= 0) Or (VisC <= 0) Then Exit;
  Hps := CallSys1(PmFn[1], H);
  If Hps = 0 Then Exit;
  For R := R0 To R0 + Depth - 1 Do
    If (R >= PS[I].OrgRow) And (R < PS[I].OrgRow + VisR) And (R < PS[I].Rows) Then
    Begin
      C := C0;
      If C < PS[I].OrgCol Then C := PS[I].OrgCol;
      CE := C0 + Width;
      If CE > PS[I].Cols Then CE := PS[I].Cols;
      If CE > PS[I].OrgCol + VisC Then CE := PS[I].OrgCol + VisC;
      While C < CE Do
      Begin
        Cs := C; N := 0;
        A0 := RdB(PS[I].Buf + (R * PS[I].Cols + C) * PS[I].CellSz + 1);
        A := A0;
        While (C < CE) And (A = A0) And (N < 255) Do
        Begin
          Ch := RdB(PS[I].Buf + (R * PS[I].Cols + C) * PS[I].CellSz);
          If Ch = 0 Then Ch := 32;
          B[N] := Ch;
          Inc(N); Inc(C);
          If C < CE Then A := RdB(PS[I].Buf + (R * PS[I].Cols + C) * PS[I].CellSz + 1);
        End;
        Rc[0] := (Cs - PS[I].OrgCol) * 8; Rc[2] := Rc[0] + N * 8;
        Rc[1] := Cy - (R - PS[I].OrgRow + 1) * PS[I].CellH; Rc[3] := Rc[1] + PS[I].CellH;
        Dummy := CallSys7(PmFn[3], Hps, N, LongInt(@B), LongInt(@Rc), PmClr(A0), PmClr(A0 Shr 4), 0);
      End;
    End;
  Dummy := CallSys1(PmFn[2], Hps);
End;

Procedure PaintPS(I, Ofs, Depth, Width : LongInt);
Var R0, C0, R, C, SR, SC, A, D : LongInt;
Begin
  If (I < 1) Or (I > MaxPS) Then Exit;
  If Not PS[I].Used Or (PS[I].Hdc = 0) Then Exit;
  If IsWinDC(PS[I].Hdc) Then
  Begin
    PaintWin(I, Ofs Div PS[I].Cols, Ofs Mod PS[I].Cols, Depth, Width);
    Exit;
  End;
  R0 := Ofs Div PS[I].Cols;
  C0 := Ofs Mod PS[I].Cols;
  For R := R0 To R0 + Depth - 1 Do
    For C := C0 To C0 + Width - 1 Do
      If (R < PS[I].Rows) And (C < PS[I].Cols) Then
      Begin
        SR := R - PS[I].OrgRow;
        SC := C - PS[I].OrgCol;
        If (SR >= 0) And (SR < NRows) And (SC >= 0) And (SC < NCols) Then
        Begin
          A := PS[I].Buf + (R * PS[I].Cols + C) * PS[I].CellSz;
          If Blocked Then D := LongInt(@Shadow) + (SR * NCols + SC) * 2
          Else D := ScrBase + (SR * NCols + SC) * 2;
          WrW(D, RdW(A));
        End;
      End;
End;

{ ==================================================================== }
{ Partie 5 - Materiel VGA : curseur, palette, polices                  }
{ ==================================================================== }

{ Forme du curseur materiel (registres 0Ah et 0Bh du CRTC) }
Procedure CursorApply;
Begin
  If (CurAttr And $FFFF) = $FFFF Then CrtcSet($0A, $20)
  Else
  Begin
    CrtcSet($0A, CurStart And $1F);
    CrtcSet($0B, CurEnd And $1F);
  End;
End;

{ Ligne du curseur : valeur negative = pourcentage de la hauteur }
Function CurLine(V, H : LongInt) : LongInt;
Var R : LongInt;
Begin
  V := S16(V);
  If V >= 0 Then R := V
  Else
  Begin
    R := (H * (-V) + 99) Div 100 - 1;
    If R < 0 Then R := 0;
  End;
  If R > H - 1 Then R := H - 1;
  CurLine := R;
End;

{ Etat d'origine du VGA (chargement de la DLL) }
Procedure HwCapture;
Var I : LongInt;
Begin
  CellHeight := (CrtcGet(9) And $1F) + 1;
  If (CellHeight < 8) Or (CellHeight > 32) Then CellHeight := 16;
  CurStart := CrtcGet($0A) And $1F;
  CurEnd := CrtcGet($0B) And $1F;
  CurAttr := 0;
  CurWidth := 1;
  If CurStart > CurEnd Then
  Begin
    CurStart := CellHeight - 3;
    CurEnd := CellHeight - 2;
  End;
  For I := 0 To 15 Do DefPal[I] := AcGet(I);
  For I := 0 To 255 Do DacGet(I, LongInt(@DefDac) + I * 3);
  Overscan := AcGet($11);
  If (AcGet($10) And 8) <> 0 Then Blink := 0 Else Blink := 1;
  Underline := CrtcGet($14) And $1F;
  ReadFont(LongInt(@RomFont), CellHeight);
  MoveB(LongInt(@RomFont), LongInt(@FontBuf), 256 * CellHeight);
  RomOk := True;
End;

{ Retablir la palette, les couleurs, la police et le curseur d'origine }
Procedure HwReset;
Var I, M : LongInt;
Begin
  If Not RomOk Then Exit;
  For I := 0 To 15 Do AcSet(I, DefPal[I]);
  For I := 0 To 255 Do DacSet(I, LongInt(@DefDac) + I * 3);
  M := AcGet($10);
  If Blink = 0 Then AcSet($10, M Or 8) Else AcSet($10, M And Not 8);
  WriteFont(LongInt(@RomFont), CellHeight);
  MoveB(LongInt(@RomFont), LongInt(@FontBuf), 256 * CellHeight);
  CurStart := CellHeight - 3;
  CurEnd := CellHeight - 2;
  CurAttr := 0;
  CursorApply;
End;

{ --- modes graphiques du VGA ---
  Registres de chaque mode : Misc (3C2h), sequenceur (5), CRTC (25),
  controleur graphique (9), controleur d'attributs (21) : 61 valeurs.
  Ordre : 03h texte 80 x 25, 0Dh 320 x 200 x 16, 0Eh 640 x 200 x 16,
  10h 640 x 350 x 16, 11h 640 x 480 x 2, 12h 640 x 480 x 16,
  13h 320 x 200 x 256 }
Const
  NVgaModes = 7;
  VgaModeNo : Array[0..6] Of LongInt = ($03, $0D, $0E, $10, $11, $12, $13);
  VgaModeW  : Array[0..6] Of LongInt = (720, 320, 640, 640, 640, 640, 320);
  VgaModeH  : Array[0..6] Of LongInt = (400, 200, 200, 350, 480, 480, 200);
  VgaModeB  : Array[0..6] Of LongInt = (4, 4, 4, 4, 1, 4, 8);
  VgaRegs : Array[0..426] Of LongInt = (
    { 03h }
    $67, $03, $00, $03, $00, $02,
    $5F, $4F, $50, $82, $55, $81, $BF, $1F, $00, $4F, $0D, $0E, $00, $00, $00, $00,
    $9C, $8E, $8F, $28, $1F, $96, $B9, $A3, $FF,
    $00, $00, $00, $00, $00, $10, $0E, $00, $FF,
    $00, $01, $02, $03, $04, $05, $14, $07, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F,
    $0C, $00, $0F, $08, $00,
    { 0Dh }
    $63, $03, $09, $0F, $00, $06,
    $2D, $27, $28, $90, $2B, $80, $BF, $1F, $00, $C0, $00, $00, $00, $00, $00, $00,
    $9C, $8E, $8F, $14, $00, $96, $B9, $E3, $FF,
    $00, $00, $00, $00, $00, $00, $05, $0F, $FF,
    $00, $01, $02, $03, $04, $05, $06, $07, $10, $11, $12, $13, $14, $15, $16, $17,
    $01, $00, $0F, $00, $00,
    { 0Eh }
    $63, $03, $01, $0F, $00, $06,
    $5F, $4F, $50, $82, $54, $80, $BF, $1F, $00, $C1, $00, $00, $00, $00, $00, $00,
    $9C, $8E, $8F, $28, $00, $96, $B9, $E3, $FF,
    $00, $00, $00, $00, $00, $00, $05, $0F, $FF,
    $00, $01, $02, $03, $04, $05, $06, $07, $10, $11, $12, $13, $14, $15, $16, $17,
    $01, $00, $0F, $00, $00,
    { 10h }
    $A3, $03, $01, $0F, $00, $06,
    $5F, $4F, $50, $82, $54, $80, $BF, $1F, $00, $40, $00, $00, $00, $00, $00, $00,
    $83, $85, $5D, $28, $0F, $63, $BA, $E3, $FF,
    $00, $00, $00, $00, $00, $00, $05, $0F, $FF,
    $00, $01, $02, $03, $04, $05, $14, $07, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F,
    $01, $00, $0F, $00, $00,
    { 11h }
    $E3, $03, $01, $0F, $00, $06,
    $5F, $4F, $50, $82, $54, $80, $0B, $3E, $00, $40, $00, $00, $00, $00, $00, $00,
    $EA, $0C, $DF, $28, $00, $E7, $04, $E3, $FF,
    $00, $00, $00, $00, $00, $00, $05, $0F, $FF,
    $00, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F,
    $01, $00, $0F, $00, $00,
    { 12h }
    $E3, $03, $01, $0F, $00, $06,
    $5F, $4F, $50, $82, $54, $80, $0B, $3E, $00, $40, $00, $00, $00, $00, $00, $00,
    $EA, $0C, $DF, $28, $00, $E7, $04, $E3, $FF,
    $00, $00, $00, $00, $00, $00, $05, $0F, $FF,
    $00, $01, $02, $03, $04, $05, $14, $07, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F,
    $01, $00, $0F, $00, $00,
    { 13h }
    $63, $03, $01, $0F, $00, $0E,
    $5F, $4F, $50, $82, $54, $80, $BF, $1F, $00, $41, $00, $00, $00, $00, $00, $00,
    $9C, $0E, $8F, $28, $40, $96, $B9, $A3, $FF,
    $00, $00, $00, $00, $00, $40, $05, $0F, $FF,
    $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F,
    $41, $00, $0F, $00, $00);

{ Programmer le VGA avec les registres du mode numero K (0 a 6) }
Procedure VgaLoad(K : LongInt);
Var B, I : LongInt;
Begin
  B := K * 61;
  OutB($3C2, VgaRegs[B]);
  OutB($3C4, 0); OutB($3C5, 1);                  { remise a zero synchrone }
  For I := 1 To 4 Do
  Begin
    OutB($3C4, I); OutB($3C5, VgaRegs[B + 1 + I]);
  End;
  OutB($3C4, 0); OutB($3C5, 3);
  CrtcSet($11, CrtcGet($11) And $7F);            { deverrouiller CRTC 0-7 }
  For I := 0 To 24 Do
  Begin
    If I = 3 Then CrtcSet(I, VgaRegs[B + 6 + I] Or $80)
    Else If I = $11 Then CrtcSet(I, VgaRegs[B + 6 + I] And $7F)
    Else CrtcSet(I, VgaRegs[B + 6 + I]);
  End;
  CrtcSet($11, VgaRegs[B + 6 + $11]);
  For I := 0 To 8 Do
  Begin
    OutB($3CE, I); OutB($3CF, VgaRegs[B + 31 + I]);
  End;
  Dummy := InB($3DA);
  For I := 0 To 20 Do
  Begin
    OutB($3C0, I); OutB($3C0, VgaRegs[B + 40 + I]);
  End;
  Dummy := InB($3DA);
  OutB($3C0, $20);
End;

{ Effacer la memoire graphique (000A0000h, 64 Ko, les 4 plans) }
Procedure GrClear;
Begin
  OutB($3C4, 2); OutB($3C5, $0F);
  OutB($3CE, 1); OutB($3CF, 0);                  { pas de fixation/remise }
  OutB($3CE, 3); OutB($3CF, 0);
  OutB($3CE, 8); OutB($3CF, $FF);
  FillB($000A0000, 65536, 0);
End;

{ Palette de 256 couleurs du mode 13h : 16 couleurs du VGA, 16 gris,
  cube de 6 x 6 x 6 couleurs, puis gris }
Procedure Dac256;
Var I, R, G, B : LongInt; C : Array[0..2] Of Byte;
Begin
  For I := 0 To 15 Do
  Begin
    C[0] := DefDac[DefPal[I] * 3]; C[1] := DefDac[DefPal[I] * 3 + 1]; C[2] := DefDac[DefPal[I] * 3 + 2];
    DacSet(I, LongInt(@C));
  End;
  For I := 0 To 15 Do
  Begin
    C[0] := I * 4 + 3; C[1] := C[0]; C[2] := C[0];
    DacSet(16 + I, LongInt(@C));
  End;
  For I := 0 To 215 Do
  Begin
    R := I Div 36; G := (I Div 6) Mod 6; B := I Mod 6;
    C[0] := R * 12 + R Div 2; C[1] := G * 12 + G Div 2; C[2] := B * 12 + B Div 2;
    DacSet(32 + I, LongInt(@C));
  End;
  For I := 248 To 255 Do
  Begin
    C[0] := (I - 248) * 8 + 7; C[1] := C[0]; C[2] := C[0];
    DacSet(I, LongInt(@C));
  End;
End;

{ Passer au mode graphique numero K (1 a 6) }
Procedure GrEnter(K : LongInt);
Var I : LongInt;
Begin
  { la police courante est dans FontBuf (rechargee au retour au texte) ;
    un mode VESA est d'abord quitte par le BIOS }
  If GrMode >= $10000 Then Dummy := KVid(4, 3, 0);
  VgaLoad(K);
  GrClear;
  If VgaModeB[K] = 8 Then Dac256
  Else For I := 0 To 255 Do DacSet(I, LongInt(@DefDac) + I * 3);
  If VgaModeNo[K] = $13 Then
  Begin
    OutB($3C4, 2); OutB($3C5, $0F);
  End;
  GrMode := VgaModeNo[K]; GrW := VgaModeW[K]; GrH := VgaModeH[K]; GrBits := VgaModeB[K];
  GrLfb := 0; GrPitch := 0;
  SesGr[CurSesNo] := GrMode;
  If GrBits = 8 Then GrPlane := GrW * GrH Else GrPlane := (GrW Div 8) * GrH;
End;

{ Revenir au mode texte 80 x 25 : registres, police, palette, curseur }
Procedure GrLeave;
Var I, M : LongInt;
Begin
  If GrMode = 0 Then Exit;
  { mode VESA : le BIOS rend le mode texte (INT 10h, 03h) }
  If GrMode >= $10000 Then Dummy := KVid(4, 3, 0);
  VgaLoad(0);
  If CellHeight <> 16 Then CrtcSet(9, (CrtcGet(9) And $E0) Or (CellHeight - 1));
  WriteFont(LongInt(@FontBuf), CellHeight);
  For I := 0 To 255 Do DacSet(I, LongInt(@DefDac) + I * 3);
  For I := 0 To 15 Do AcSet(I, DefPal[I]);
  AcSet($11, Overscan);
  M := AcGet($10);
  If Blink = 0 Then AcSet($10, M Or 8) Else AcSet($10, M And Not 8);
  GrMode := 0; GrW := 0; GrH := 0; GrBits := 0; GrPlane := 0; GrLfb := 0; GrPitch := 0;
  SesGr[CurSesNo] := 0;
  CursorApply;
End;

{ --- modes VESA (BIOS VBE, par le noyau : KrnVideo) ---
  Un mode VESA est note $10000 + numero du mode VBE (SesGr, GrMode) ;
  la memoire de l'ecran est lineaire (GrLfb, GrPitch octets par ligne),
  8 bits par pel (palette de 256 couleurs, comme le mode 13h) ou 15, 16,
  24, 32 bits (couleurs directes). }
Procedure VesaLoad;
Var I, N : LongInt; E : Array[0..12] Of LongInt;
Begin
  If VesaN >= 0 Then Exit;
  VesaN := 0;
  If KVid(0, 0, 0) = 0 Then Exit;
  N := KVid(1, 0, 0);
  For I := 0 To N - 1 Do
    If (VesaN < 96) And (KVid(2, I, LongInt(@E)) <> 0) Then
    Begin
      VesaNo[VesaN] := E[0]; VesaW[VesaN] := E[1]; VesaH[VesaN] := E[2]; VesaB[VesaN] := E[3];
      VesaPitch[VesaN] := E[4]; VesaLfb[VesaN] := E[5];
      Inc(VesaN);
    End;
End;

{ mode VESA de la resolution donnee (-1 : aucun) }
Function VesaFind(W, H, Bits : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  VesaLoad;
  R := -1;
  For I := VesaN - 1 DownTo 0 Do
    If (VesaW[I] = W) And (VesaH[I] = H) And (VesaB[I] = Bits) Then R := I;
  VesaFind := R;
End;

Function VesaOf(Code : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  VesaLoad;
  R := -1;
  For I := 0 To VesaN - 1 Do
    If VesaNo[I] + $10000 = Code Then R := I;
  VesaOf := R;
End;

{ passer au mode VESA numero I de la table }
Function VesaEnter(I : LongInt) : Boolean;
Begin
  VesaEnter := False;
  If (I < 0) Or (I >= VesaN) Then Exit;
  If KVid(3, VesaNo[I], 0) <> 0 Then Exit;
  GrMode := $10000 + VesaNo[I]; GrW := VesaW[I]; GrH := VesaH[I]; GrBits := VesaB[I];
  GrPitch := VesaPitch[I]; GrLfb := VesaLfb[I];
  GrPlane := GrPitch * GrH;
  SesGr[CurSesNo] := GrMode;
  If GrBits = 8 Then Dac256;
  VesaEnter := True;
End;

{ passer au mode graphique note Code (VGA ou VESA) }
Procedure GrEnterCode(Code : LongInt);
Var I : LongInt;
Begin
  If Code >= $10000 Then
  Begin
    If Not VesaEnter(VesaOf(Code)) Then GrEnter(5);
  End
  Else
    For I := 1 To NVgaModes - 1 Do
      If VgaModeNo[I] = Code Then GrEnter(I);
End;

{ VioQueryModes(i, p) : modes graphiques possibles (interne, ordinal
  1002) ; p = 0 : nombre ; sinon 16 octets en p : largeur, hauteur, bits
  par pel, genre (0 VGA, 1 VESA) ; le mode 0 est le VGA 640 x 480 x 16 }
Function VioQueryModes(I, P : LongInt) : LongInt;
Begin
  VesaLoad;
  If P = 0 Then
  Begin
    VioQueryModes := VesaN + 1;
    Exit;
  End;
  VioQueryModes := 0;
  If I = 0 Then
  Begin
    WrL(P, 640); WrL(P + 4, 480); WrL(P + 8, 4); WrL(P + 12, 0);
    VioQueryModes := 1;
  End
  Else If (I > 0) And (I <= VesaN) Then
  Begin
    WrL(P, VesaW[I - 1]); WrL(P + 4, VesaH[I - 1]); WrL(P + 8, VesaB[I - 1]); WrL(P + 12, 1);
    VioQueryModes := 1;
  End;
End;

{ VioQueryVbe(p) : version du VBE, memoire (Ko) et constructeur (ASCIIZ)
  en p (interne, ordinal 1003) ; 0 : pas de BIOS VESA }
Function VioQueryVbe(P : LongInt) : LongInt;
Begin
  VioQueryVbe := KVid(5, 0, P);
End;

{ Code d'erreur des fonctions du mode texte (ERROR_VIO_MODE en mode
  graphique pour l'ecran) }
Function TextErr(Hvio : LongInt) : LongInt;
Begin
  If (Hvio = 0) And (SesGr[CurSesNo] <> 0) Then TextErr := ERROR_VIO_MODE
  Else TextErr := SurfErr(Hvio);
End;

{ ==================================================================== }
{ Partie 6 - Remplacement du sous-systeme (VioRegister)                }
{ ==================================================================== }

Function CallPtr3(F, A1, A2, A3 : LongInt) : LongInt;
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
  CallPtr3 := R;
End;

Function BitIn(Bit, F1, F2 : LongInt) : Boolean;
Begin
  If Bit < 32 Then BitIn := ((F1 Shr Bit) And 1) <> 0
  Else BitIn := ((F2 Shr (Bit - 32)) And 1) <> 0;
End;

{ La fonction Bit est-elle remplacee ? Si oui, appeler le remplacant ;
  vrai si sa valeur (HookRet) doit etre rendue a l'appelant. }
Function Hooked(Bit, N, A1, A2, A3, A4, A5, A6, A7 : LongInt) : Boolean;
Var E, Pass, R : LongInt; Res : Boolean;
Begin
  Res := False;
  If Not InHook Then
  Begin
    E := 0; Pass := -1;
    If (RegEntry <> 0) And BitIn(Bit, RegFun1, RegFun2) Then
    Begin
      E := RegEntry; Pass := RegPass;
    End
    Else If (GlbEntry <> 0) And BitIn(Bit, GlbFun1, GlbFun2) Then
    Begin
      E := GlbEntry; Pass := GlbPass;
    End;
    If E <> 0 Then
    Begin
      Prm[0] := A1; Prm[1] := A2; Prm[2] := A3; Prm[3] := A4;
      Prm[4] := A5; Prm[5] := A6; Prm[6] := A7;
      InHook := True;
      R := CallPtr3(E, Bit, LongInt(@Prm), N);
      InHook := False;
      If R <> Pass Then
      Begin
        HookRet := R;
        Res := True;
      End;
    End;
  End;
  Hooked := Res;
End;

{ Charger le module et trouver le point d'entree d'un remplacant }
Function LoadEntry(PMod, PEntry : LongInt; Var Entry : LongInt) : LongInt;
Var R, H : LongInt;
Begin
  Entry := 0;
  If (PMod = 0) Or (PEntry = 0) Then R := ERROR_VIO_REGISTER
  Else
  Begin
    R := DosLoadModule(LongInt(@LineBuf), 64, PMod, LongInt(@H));
    If R = NO_ERROR Then R := DosQueryProcAddr(H, 0, PEntry, LongInt(@Entry));
    If (R <> NO_ERROR) Or (Entry = 0) Then R := ERROR_VIO_REGISTER;
  End;
  LoadEntry := R;
End;

{ ==================================================================== }
{ Partie 7 - Ecriture, lecture et defilement                           }
{ ==================================================================== }
{ Les ecritures et lectures commencent en (Row, Col) et continuent sur
  les lignes suivantes ; elles s'arretent a la fin de la surface. }

{ Verifier la position ; rend le nombre de cellules disponibles dans N }
Function PosErr(S, Row, Col : LongInt; Var Avail : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  Avail := 0;
  If (Row < 0) Or (Row >= SRows(S)) Then R := ERROR_VIO_ROW
  Else If (Col < 0) Or (Col >= SCols(S)) Then R := ERROR_VIO_COL
  Else Avail := SRows(S) * SCols(S) - (Row * SCols(S) + Col);
  PosErr := R;
End;

{ Mode d'ecriture : 0 caractere, 1 attribut, 2 cellule (caractere et
  attribut), 3 caractere et attribut constant. Src avance de Step octets
  par cellule (0 = repetition). }
Function WriteRun(Hvio, Row, Col, Src, Count, Step, Mode, AttrC : LongInt) : LongInt;
Var R, Avail, I, A, CS, Ext : LongInt;
Begin
  R := TextErr(Hvio);
  If R = NO_ERROR Then R := PosErr(Hvio, Row, Col, Avail);
  If R = NO_ERROR Then
  Begin
    If Count > Avail Then Count := Avail;
    CS := SCell(Hvio);
    Ext := ExtAttr;
    A := CellAt(Hvio, Row, Col);
    For I := 0 To Count - 1 Do
    Begin
      Case Mode Of
        0 : WrB(A, RdB(Src));
        1 : WrB(A + 1, ApplyCA(RdB(Src)));
        2 : Begin
              MoveB(Src, A, CS);
              WrB(A + 1, ApplyCA(RdB(Src + 1)));
              If (CS = 4) And (Ext <> 0) Then WrB(A + 2, RdB(A + 2) Or Ext);
            End;
        3 : Begin
              WrB(A, RdB(Src));
              WrB(A + 1, ApplyCA(AttrC));
              If CS = 4 Then WrB(A + 2, Ext);
            End;
      End;
      A := A + CS;
      Src := Src + Step;
    End;
    If (Hvio <> 0) And (PS[Hvio].Hdc <> 0) Then
      PaintPS(Hvio, Row * PS[Hvio].Cols + Col, (Col + Count + PS[Hvio].Cols - 1) Div PS[Hvio].Cols, PS[Hvio].Cols);
  End;
  WriteRun := R;
End;

{ Lire des cellules (Mode 2) ou des caracteres (Mode 0) ; *PCb : taille
  du tampon en octets en entree, octets lus en sortie }
Function ReadRun(Hvio, Row, Col, Dst, PCb, Mode : LongInt) : LongInt;
Var R, Avail, Count, I, A, CS, USz : LongInt;
Begin
  R := TextErr(Hvio);
  If R = NO_ERROR Then R := PosErr(Hvio, Row, Col, Avail);
  If R = NO_ERROR Then
  Begin
    CS := SCell(Hvio);
    If Mode = 2 Then USz := CS Else USz := 1;
    Count := RdL(PCb) Div USz;
    If Count > Avail Then Count := Avail;
    A := CellAt(Hvio, Row, Col);
    For I := 0 To Count - 1 Do
    Begin
      If Mode = 2 Then MoveB(A, Dst + I * CS, CS) Else WrB(Dst + I, RdB(A));
      A := A + CS;
    End;
    WrL(PCb, Count * USz);
  End
  Else
    WrL(PCb, 0);
  ReadRun := R;
End;

{ Defilement d'un rectangle : Dir 0 haut, 1 bas, 2 gauche, 3 droite ;
  N = FFFFh ou plus que la region : la region est effacee }
Function ScrollRect(Hvio, Top, Left, Bot, Right, N, PCell, Dir : LongInt) : LongInt;
Var R, CS, Rows, Cols, Y, X, H, W, Fill0, Fill1 : LongInt;
Begin
  R := TextErr(Hvio);
  If R = NO_ERROR Then
  Begin
    Rows := SRows(Hvio); Cols := SCols(Hvio); CS := SCell(Hvio);
    Top := Top And $FFFF; Left := Left And $FFFF;
    Bot := Bot And $FFFF; Right := Right And $FFFF;
    If Bot >= Rows Then Bot := Rows - 1;
    If Right >= Cols Then Right := Cols - 1;
    If Top >= Rows Then R := ERROR_VIO_TOPROW
    Else If Left >= Cols Then R := ERROR_VIO_LEFTCOL
    Else If Bot < Top Then R := ERROR_VIO_BOTROW
    Else If Right < Left Then R := ERROR_VIO_RIGHTCOL
    Else If PCell = 0 Then R := ERROR_VIO_PTR;
  End;
  If R = NO_ERROR Then
  Begin
    H := Bot - Top + 1;
    W := Right - Left + 1;
    N := N And $FFFF;
    If ((Dir <= 1) And (N > H)) Or ((Dir >= 2) And (N > W)) Then
    Begin
      If Dir <= 1 Then N := H Else N := W;
    End;
    Fill0 := RdB(PCell);
    Fill1 := RdB(PCell + 1);
    If N > 0 Then
      Case Dir Of
        0 : For Y := Top To Bot - N Do
              MoveB(CellAt(Hvio, Y + N, Left), CellAt(Hvio, Y, Left), W * CS);
        1 : For Y := Bot DownTo Top + N Do
              MoveB(CellAt(Hvio, Y - N, Left), CellAt(Hvio, Y, Left), W * CS);
        2 : For Y := Top To Bot Do
              For X := Left To Right - N Do
                MoveB(CellAt(Hvio, Y, X + N), CellAt(Hvio, Y, X), CS);
        3 : For Y := Top To Bot Do
              For X := Right DownTo Left + N Do
                MoveB(CellAt(Hvio, Y, X - N), CellAt(Hvio, Y, X), CS);
      End;
    { cellules liberees }
    For Y := Top To Bot Do
      For X := Left To Right Do
        If ((Dir = 0) And (Y > Bot - N)) Or ((Dir = 1) And (Y < Top + N)) Or
           ((Dir = 2) And (X > Right - N)) Or ((Dir = 3) And (X < Left + N)) Then
        Begin
          WrB(CellAt(Hvio, Y, X), Fill0);
          WrB(CellAt(Hvio, Y, X) + 1, Fill1);
          If CS = 4 Then
          Begin
            WrB(CellAt(Hvio, Y, X) + 2, RdB(PCell + 2));
            WrB(CellAt(Hvio, Y, X) + 3, 0);
          End;
        End;
    If (Hvio <> 0) And (PS[Hvio].Hdc <> 0) Then
      PaintPS(Hvio, Top * PS[Hvio].Cols + Left, H, W);
  End;
  ScrollRect := R;
End;

{ ==================================================================== }
{ Partie 8 - Teletype et ANSI                                          }
{ ==================================================================== }
{ VioWrtTty : CR, LF, BS, TAB, BEL, retour a la ligne et defilement ;
  avec ANSI actif, sequences ESC[ : A B C D (deplacements), H f
  (position), s u (sauver/rendre la position), J (effacer l'ecran), K
  (effacer la fin de la ligne), m (attributs : 0 1 5 7 8, 30-37
  caractere, 40-47 fond), =nh =nl (modes, sans effet). Sur l'ecran, le
  texte passe par la console du noyau. }

Var
  TtyN : LongInt;          { caracteres en attente dans LineBuf }

{ Ecrire un caractere sur une surface autre que la console du noyau }
Procedure RenderCh(S, Ch : LongInt);
Var R, C, Rows, Cols, A, Y, X : LongInt;
Begin
  GetCur(S, R, C);
  Rows := TtyRows(S); Cols := SCols(S);
  Case Ch Of
    13 : C := 0;
    10 : Inc(R);
    8  : If C > 0 Then Dec(C);
    9  : C := (C + 8) And Not 7;
    7  : KBeep(800, 100);
  Else
    Begin
      A := CellAt(S, R, C);
      WrB(A, Ch);
      WrB(A + 1, ApplyCA(GetAttr(S)));
      Inc(C);
    End;
  End;
  If C >= Cols Then
  Begin
    C := 0;
    Inc(R);
  End;
  If R >= Rows Then
  Begin
    { defilement d'une ligne }
    For Y := 0 To Rows - 2 Do
      MoveB(CellAt(S, Y + 1, 0), CellAt(S, Y, 0), Cols * SCell(S));
    For X := 0 To Cols - 1 Do
    Begin
      WrB(CellAt(S, Rows - 1, X), 32);
      WrB(CellAt(S, Rows - 1, X) + 1, GetAttr(S));
    End;
    R := Rows - 1;
    If (S <> 0) And (PS[S].Hdc <> 0) Then PaintPS(S, 0, PS[S].Rows, PS[S].Cols);
  End;
  SetCur(S, R, C);
  If (S <> 0) And (PS[S].Hdc <> 0) And (Ch >= 32) Then PaintPS(S, R * PS[S].Cols, 1, PS[S].Cols);
End;

Procedure TtyFlush(S : LongInt);
Var I, W : LongInt;
Begin
  If TtyN > 0 Then
  Begin
    If (S = 0) And Not Blocked Then KWriteConsoleA(ConH, LongInt(@LineBuf), TtyN, LongInt(@W), 0)
    Else
      For I := 0 To TtyN - 1 Do RenderCh(S, LineBuf[I]);
    TtyN := 0;
  End;
End;

Procedure TtyCh(S, Ch : LongInt);
Begin
  LineBuf[TtyN] := Ch;
  Inc(TtyN);
  If TtyN >= 255 Then TtyFlush(S);
End;

{ Parametre numero K (0..) de la sequence, ou Def }
Function EscParm(K, Def : LongInt) : LongInt;
Var I, N, V : LongInt; Have : Boolean;
Begin
  N := 0; V := 0; Have := False;
  For I := 1 To Length(EscBuf) Do
  Begin
    If EscBuf[I] = ';' Then
    Begin
      If N = K Then
      Begin
        If Have Then EscParm := V Else EscParm := Def;
        Exit;
      End;
      Inc(N); V := 0; Have := False;
    End
    Else If (EscBuf[I] >= '0') And (EscBuf[I] <= '9') Then
    Begin
      V := V * 10 + Ord(EscBuf[I]) - 48;
      Have := True;
    End;
  End;
  If (N = K) And Have Then EscParm := V Else EscParm := Def;
End;

Function EscCount : LongInt;
Var I, N : LongInt;
Begin
  N := 1;
  For I := 1 To Length(EscBuf) Do If EscBuf[I] = ';' Then Inc(N);
  EscCount := N;
End;

{ Couleur ANSI -> couleur VGA }
Function AnsiColor(N : LongInt) : LongInt;
Begin
  Case N Of
    1 : AnsiColor := 4;
    3 : AnsiColor := 6;
    4 : AnsiColor := 1;
    6 : AnsiColor := 3;
  Else
    AnsiColor := N;
  End;
End;

Procedure EscExec(S, Fin : LongInt);
Var R, C, K, A, P, Rows, Cols, X, Y : LongInt;
Begin
  GetCur(S, R, C);
  Rows := TtyRows(S); Cols := SCols(S);
  If (Length(EscBuf) > 0) And (EscBuf[1] = '=') Then Exit;      { modes }
  Case Chr(Fin) Of
    'A' : Begin R := R - EscParm(0, 1); If R < 0 Then R := 0; SetCur(S, R, C); End;
    'B' : Begin R := R + EscParm(0, 1); If R >= Rows Then R := Rows - 1; SetCur(S, R, C); End;
    'C' : Begin C := C + EscParm(0, 1); If C >= Cols Then C := Cols - 1; SetCur(S, R, C); End;
    'D' : Begin C := C - EscParm(0, 1); If C < 0 Then C := 0; SetCur(S, R, C); End;
    'H', 'f' :
      Begin
        R := EscParm(0, 1) - 1; C := EscParm(1, 1) - 1;
        If R < 0 Then R := 0;
        If C < 0 Then C := 0;
        If R >= Rows Then R := Rows - 1;
        If C >= Cols Then C := Cols - 1;
        SetCur(S, R, C);
      End;
    's' : Begin AnsiRow := R; AnsiCol := C; End;
    'u' : SetCur(S, AnsiRow, AnsiCol);
    'J' :
      Begin
        A := GetAttr(S);
        For Y := 0 To Rows - 1 Do
          For X := 0 To Cols - 1 Do
          Begin
            WrB(CellAt(S, Y, X), 32);
            WrB(CellAt(S, Y, X) + 1, A);
          End;
        SetCur(S, 0, 0);
        If (S <> 0) And (PS[S].Hdc <> 0) Then PaintPS(S, 0, PS[S].Rows, PS[S].Cols);
      End;
    'K' :
      Begin
        A := GetAttr(S);
        For X := C To Cols - 1 Do
        Begin
          WrB(CellAt(S, R, X), 32);
          WrB(CellAt(S, R, X) + 1, A);
        End;
        If (S <> 0) And (PS[S].Hdc <> 0) Then PaintPS(S, R * PS[S].Cols, 1, PS[S].Cols);
      End;
    'm' :
      Begin
        A := GetAttr(S);
        For K := 0 To EscCount - 1 Do
        Begin
          P := EscParm(K, 0);
          If P = 0 Then A := 7
          Else If P = 1 Then A := A Or 8
          Else If P = 5 Then A := A Or $80
          Else If P = 7 Then A := (A And $88) Or ((A And 7) Shl 4) Or ((A Shr 4) And 7)
          Else If P = 8 Then A := (A And $F0) Or ((A Shr 4) And 7)
          Else If (P >= 30) And (P <= 37) Then A := (A And $F8) Or AnsiColor(P - 30)
          Else If (P >= 40) And (P <= 47) Then A := (A And $8F) Or (AnsiColor(P - 40) Shl 4);
        End;
        SetAttr(S, A);
      End;
  End;
End;

{ Sortie teletype de N octets de Buf sur la surface S }
Procedure TtyWrite(S, Buf, N : LongInt);
Var I, Ch : LongInt;
Begin
  TtyN := 0;
  For I := 0 To N - 1 Do
  Begin
    Ch := RdB(Buf + I);
    Case EscState Of
      1 :
        If Ch = 91 Then
        Begin
          EscState := 2;
          EscBuf := '';
        End
        Else
        Begin
          EscState := 0;
          TtyCh(S, Ch);
        End;
      2 :
        If ((Ch >= 48) And (Ch <= 57)) Or (Ch = 59) Or (Ch = 61) Or (Ch = 63) Then
        Begin
          If Length(EscBuf) < 40 Then EscBuf := EscBuf + Chr(Ch);
        End
        Else
        Begin
          EscState := 0;
          EscExec(S, Ch);
        End;
    Else
      If (Ch = 27) And AnsiOf(S) Then
      Begin
        TtyFlush(S);
        EscState := 1;
      End
      Else
        TtyCh(S, Ch);
    End;
  End;
  TtyFlush(S);
  If PrtEcho Then PrtWrite(Buf, N);
End;

{ ==================================================================== }
{ Partie 9 - Fonctions Vio* de base                                    }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  VioGetCurPos(pusRow, pusColumn, hvio) : position du curseur }
Function VioGetCurPos(PRow, PCol, Hvio : LongInt) : LongInt;
Var R, Y, X : LongInt;
Begin
  If Hooked(VB_GETCURPOS, 3, PRow, PCol, Hvio, 0, 0, 0, 0) Then
  Begin
    VioGetCurPos := HookRet;
    Exit;
  End;
  R := TextErr(Hvio);
  If (R = NO_ERROR) And ((PRow = 0) Or (PCol = 0)) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    GetCur(Hvio, Y, X);
    WrL(PRow, Y);
    WrL(PCol, X);
  End;
  VioGetCurPos := R;
End;

{ ---------------------------------------------------------------------
  VioSetCurPos(usRow, usColumn, hvio) : placer le curseur (aussi
  exportee sous le nom VioSetCursorPos) }
Function VioSetCurPos(Row, Col, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_SETCURPOS, 3, Row, Col, Hvio, 0, 0, 0, 0) Then
  Begin
    VioSetCurPos := HookRet;
    Exit;
  End;
  R := TextErr(Hvio);
  If R = NO_ERROR Then
  Begin
    If (Row < 0) Or (Row >= SRows(Hvio)) Then R := ERROR_VIO_ROW
    Else If (Col < 0) Or (Col >= SCols(Hvio)) Then R := ERROR_VIO_COL
    Else SetCur(Hvio, Row, Col);
  End;
  VioSetCurPos := R;
End;

{ ---------------------------------------------------------------------
  VioGetCurType(pvioCursorInfo, hvio) : forme du curseur
  VIOCURSORINFO : yStart, cEnd, cx, attr (FFFFh = cache), mots de 16 bits }
Function VioGetCurType(PInfo, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_GETCURTYPE, 2, PInfo, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioGetCurType := HookRet;
    Exit;
  End;
  R := TextErr(Hvio);
  If (R = NO_ERROR) And (PInfo = 0) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    If Hvio = 0 Then
    Begin
      WrW(PInfo, CurStart); WrW(PInfo + 2, CurEnd);
      WrW(PInfo + 4, CurWidth); WrW(PInfo + 6, CurAttr);
    End
    Else
    Begin
      WrW(PInfo, PS[Hvio].CurStart); WrW(PInfo + 2, PS[Hvio].CurEnd);
      WrW(PInfo + 4, 1); WrW(PInfo + 6, PS[Hvio].CurAttr);
    End;
  End;
  VioGetCurType := R;
End;

{ ---------------------------------------------------------------------
  VioSetCurType(pvioCursorInfo, hvio) : forme du curseur (lignes de
  debut et de fin ; valeurs negatives : pourcentage de la hauteur de la
  cellule ; attr FFFFh : curseur cache) }
Function VioSetCurType(PInfo, Hvio : LongInt) : LongInt;
Var R, St, En, H : LongInt;
Begin
  If Hooked(VB_SETCURTYPE, 2, PInfo, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioSetCurType := HookRet;
    Exit;
  End;
  R := TextErr(Hvio);
  If (R = NO_ERROR) And (PInfo = 0) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    If Hvio = 0 Then H := CellHeight Else H := PS[Hvio].CellH;
    St := CurLine(RdW(PInfo), H);
    En := CurLine(RdW(PInfo + 2), H);
    If (RdW(PInfo + 4) > 1) Then R := ERROR_VIO_WIDTH
    Else If Hvio = 0 Then
    Begin
      CurStart := St; CurEnd := En; CurAttr := RdW(PInfo + 6);
      If RdW(PInfo + 4) = 0 Then CurWidth := 1 Else CurWidth := RdW(PInfo + 4);
      CursorApply;
    End
    Else
    Begin
      PS[Hvio].CurStart := St; PS[Hvio].CurEnd := En; PS[Hvio].CurAttr := RdW(PInfo + 6);
    End;
  End;
  VioSetCurType := R;
End;

{ ---------------------------------------------------------------------
  VioWrtCharStr(pchStr, cb, usRow, usColumn, hvio) : ecrire des
  caracteres en gardant les attributs }
Function VioWrtCharStr(PStr, Cb, Row, Col, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_WRTCHARSTR, 5, PStr, Cb, Row, Col, Hvio, 0, 0) Then
  Begin
    VioWrtCharStr := HookRet;
    Exit;
  End;
  VioWrtCharStr := WriteRun(Hvio, Row, Col, PStr, Cb, 1, 0, 0);
End;

{ ---------------------------------------------------------------------
  VioWrtCharStrAtt(pchStr, cb, usRow, usColumn, pAttr, hvio) : ecrire
  des caracteres avec un attribut constant }
Function VioWrtCharStrAtt(PStr, Cb, Row, Col, PAttr, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_WRTCHARSTRATT, 6, PStr, Cb, Row, Col, PAttr, Hvio, 0) Then
  Begin
    VioWrtCharStrAtt := HookRet;
    Exit;
  End;
  If PAttr = 0 Then VioWrtCharStrAtt := ERROR_VIO_PTR
  Else VioWrtCharStrAtt := WriteRun(Hvio, Row, Col, PStr, Cb, 1, 3, RdB(PAttr));
End;

{ ---------------------------------------------------------------------
  VioWrtCellStr(pchCellStr, cb, usRow, usColumn, hvio) : ecrire des
  cellules (caractere, attribut ; 4 octets dans un espace AVIO a 4
  octets) ; cb en octets }
Function VioWrtCellStr(PCells, Cb, Row, Col, Hvio : LongInt) : LongInt;
Var CS : LongInt;
Begin
  If Hooked(VB_WRTCELLSTR, 5, PCells, Cb, Row, Col, Hvio, 0, 0) Then
  Begin
    VioWrtCellStr := HookRet;
    Exit;
  End;
  If TextErr(Hvio) <> NO_ERROR Then CS := 2 Else CS := SCell(Hvio);
  VioWrtCellStr := WriteRun(Hvio, Row, Col, PCells, Cb Div CS, CS, 2, 0);
End;

{ ---------------------------------------------------------------------
  VioWrtNChar(pch, cb, usRow, usColumn, hvio) : repeter un caractere cb
  fois (attributs inchanges) }
Function VioWrtNChar(PCh, Cb, Row, Col, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_WRTNCHAR, 5, PCh, Cb, Row, Col, Hvio, 0, 0) Then
  Begin
    VioWrtNChar := HookRet;
    Exit;
  End;
  VioWrtNChar := WriteRun(Hvio, Row, Col, PCh, Cb, 0, 0, 0);
End;

{ ---------------------------------------------------------------------
  VioWrtNAttr(pAttr, cb, usRow, usColumn, hvio) : repeter un attribut
  cb fois (caracteres inchanges) }
Function VioWrtNAttr(PAttr, Cb, Row, Col, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_WRTNATTR, 5, PAttr, Cb, Row, Col, Hvio, 0, 0) Then
  Begin
    VioWrtNAttr := HookRet;
    Exit;
  End;
  VioWrtNAttr := WriteRun(Hvio, Row, Col, PAttr, Cb, 0, 1, 0);
End;

{ ---------------------------------------------------------------------
  VioWrtNCell(pCell, cb, usRow, usColumn, hvio) : repeter une cellule cb
  fois }
Function VioWrtNCell(PCell, Cb, Row, Col, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_WRTNCELL, 5, PCell, Cb, Row, Col, Hvio, 0, 0) Then
  Begin
    VioWrtNCell := HookRet;
    Exit;
  End;
  VioWrtNCell := WriteRun(Hvio, Row, Col, PCell, Cb, 0, 2, 0);
End;

{ ---------------------------------------------------------------------
  VioReadCharStr(pchCharStr, pcb, usRow, usColumn, hvio) : lire des
  caracteres ; *pcb : taille du tampon, puis caracteres lus }
Function VioReadCharStr(PBuf, PCb, Row, Col, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_READCHARSTR, 5, PBuf, PCb, Row, Col, Hvio, 0, 0) Then
  Begin
    VioReadCharStr := HookRet;
    Exit;
  End;
  If (PBuf = 0) Or (PCb = 0) Then VioReadCharStr := ERROR_VIO_PTR
  Else VioReadCharStr := ReadRun(Hvio, Row, Col, PBuf, PCb, 0);
End;

{ ---------------------------------------------------------------------
  VioReadCellStr(pchCellStr, pcb, usRow, usColumn, hvio) : lire des
  cellules ; *pcb en octets }
Function VioReadCellStr(PBuf, PCb, Row, Col, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_READCELLSTR, 5, PBuf, PCb, Row, Col, Hvio, 0, 0) Then
  Begin
    VioReadCellStr := HookRet;
    Exit;
  End;
  If (PBuf = 0) Or (PCb = 0) Then VioReadCellStr := ERROR_VIO_PTR
  Else VioReadCellStr := ReadRun(Hvio, Row, Col, PBuf, PCb, 2);
End;

{ ---------------------------------------------------------------------
  VioScrollUp / VioScrollDn / VioScrollLf / VioScrollRt
    (usTopRow, usLeftCol, usBotRow, usRightCol, cbLines, pbCell, hvio)
  Defiler un rectangle de cbLines lignes (ou colonnes) ; les cellules
  liberees prennent la cellule pbCell ; cbLines = FFFFh efface le
  rectangle. VioScrollLf est aussi exportee sous le nom VioScrollLe, et
  VioScrollRt sous le nom VioScrollRi. }
Function VioScrollUp(Top, Left, Bot, Right, N, PCell, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_SCROLLUP, 7, Top, Left, Bot, Right, N, PCell, Hvio) Then
  Begin
    VioScrollUp := HookRet;
    Exit;
  End;
  VioScrollUp := ScrollRect(Hvio, Top, Left, Bot, Right, N, PCell, 0);
End;

Function VioScrollDn(Top, Left, Bot, Right, N, PCell, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_SCROLLDN, 7, Top, Left, Bot, Right, N, PCell, Hvio) Then
  Begin
    VioScrollDn := HookRet;
    Exit;
  End;
  VioScrollDn := ScrollRect(Hvio, Top, Left, Bot, Right, N, PCell, 1);
End;

Function VioScrollLf(Top, Left, Bot, Right, N, PCell, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_SCROLLLF, 7, Top, Left, Bot, Right, N, PCell, Hvio) Then
  Begin
    VioScrollLf := HookRet;
    Exit;
  End;
  VioScrollLf := ScrollRect(Hvio, Top, Left, Bot, Right, N, PCell, 2);
End;

Function VioScrollRt(Top, Left, Bot, Right, N, PCell, Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_SCROLLRT, 7, Top, Left, Bot, Right, N, PCell, Hvio) Then
  Begin
    VioScrollRt := HookRet;
    Exit;
  End;
  VioScrollRt := ScrollRect(Hvio, Top, Left, Bot, Right, N, PCell, 3);
End;

{ ---------------------------------------------------------------------
  VioWrtTty(pch, cb, hvio) : ecrire en mode teletype (sequences ANSI
  interpretees si ANSI est actif) }
Function VioWrtTty(PCh, Cb, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_WRTTTY, 3, PCh, Cb, Hvio, 0, 0, 0, 0) Then
  Begin
    VioWrtTty := HookRet;
    Exit;
  End;
  R := TextErr(Hvio);
  If (R = NO_ERROR) And (PCh = 0) And (Cb > 0) Then R := ERROR_VIO_PTR;
  If (R = NO_ERROR) And (Cb > 0) Then TtyWrite(Hvio, PCh, Cb);
  VioWrtTty := R;
End;

{ ---------------------------------------------------------------------
  VioGetAnsi(pfAnsi, hvio) : *pfAnsi <- 1 si ANSI est actif (0 sinon) }
Function VioGetAnsi(PAnsi, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_GETANSI, 2, PAnsi, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioGetAnsi := HookRet;
    Exit;
  End;
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And (PAnsi = 0) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    If AnsiOf(Hvio) Then WrL(PAnsi, 1) Else WrL(PAnsi, 0);
  End;
  VioGetAnsi := R;
End;

{ ---------------------------------------------------------------------
  VioSetAnsi(fAnsi, hvio) : 1 ANSI actif, 0 inactif }
Function VioSetAnsi(FAnsi, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_SETANSI, 2, FAnsi, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioSetAnsi := HookRet;
    Exit;
  End;
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And (FAnsi <> 0) And (FAnsi <> 1) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then
  Begin
    If Hvio = 0 Then ScrAnsi := FAnsi = 1 Else PS[Hvio].Ansi := FAnsi = 1;
    EscState := 0;
  End;
  VioSetAnsi := R;
End;

{ ---------------------------------------------------------------------
  VioGetBuf(pLVB, pcbLVB, hvio) : adresse et taille du tampon video
  logique (LVB) du processus, initialise avec le contenu de l'ecran ;
  pour un espace AVIO, son tampon de cellules }
Function VioGetBuf(PLvb, PCb, Hvio : LongInt) : LongInt;
Var R, I, Pid, F : LongInt;
Begin
  If Hooked(VB_GETBUF, 3, PLvb, PCb, Hvio, 0, 0, 0, 0) Then
  Begin
    VioGetBuf := HookRet;
    Exit;
  End;
  R := TextErr(Hvio);
  If (R = NO_ERROR) And ((PLvb = 0) Or (PCb = 0)) Then R := ERROR_VIO_PTR;
  If (R = NO_ERROR) And (Hvio <> 0) Then
  Begin
    WrL(PLvb, PS[Hvio].Buf);
    WrL(PCb, PS[Hvio].Rows * PS[Hvio].Cols * PS[Hvio].CellSz);
  End
  Else If R = NO_ERROR Then
  Begin
    Pid := MyPid;
    F := -1;
    For I := 0 To MaxLvb - 1 Do
      If (Lvbs[I].Addr <> 0) And (Lvbs[I].Pid = Pid) Then F := I;
    If F < 0 Then
    Begin
      For I := MaxLvb - 1 DownTo 0 Do
        If Lvbs[I].Addr = 0 Then F := I;
      If F < 0 Then F := 0;
      Lvbs[F].Pid := Pid;
      Lvbs[F].Addr := KHeapAlloc(KGetProcessHeap, 8, ScrBytes);
    End;
    If Lvbs[F].Addr = 0 Then R := 8
    Else
    Begin
      MoveB(SBase(0), Lvbs[F].Addr, ScrBytes);
      WrL(PLvb, Lvbs[F].Addr);
      WrL(PCb, ScrBytes);
    End;
  End;
  VioGetBuf := R;
End;

{ ---------------------------------------------------------------------
  VioShowBuf(offLVB, cb, hvio) : recopier une partie du LVB a l'ecran }
Function VioShowBuf(Ofs, Cb, Hvio : LongInt) : LongInt;
Var R, I, F : LongInt;
Begin
  If Hooked(VB_SHOWBUF, 3, Ofs, Cb, Hvio, 0, 0, 0, 0) Then
  Begin
    VioShowBuf := HookRet;
    Exit;
  End;
  R := TextErr(Hvio);
  If R = NO_ERROR Then
  Begin
    If (Ofs < 0) Or (Cb < 0) Then R := ERROR_VIO_INVALID_LENGTH
    Else If Hvio <> 0 Then
    Begin
      If Ofs + Cb > PS[Hvio].Rows * PS[Hvio].Cols * PS[Hvio].CellSz Then R := ERROR_VIO_INVALID_LENGTH
      Else PaintPS(Hvio, Ofs Div PS[Hvio].CellSz, (Cb + PS[Hvio].Cols * PS[Hvio].CellSz - 1) Div
                   (PS[Hvio].Cols * PS[Hvio].CellSz) + 1, PS[Hvio].Cols);
    End
    Else
    Begin
      F := -1;
      For I := 0 To MaxLvb - 1 Do
        If (Lvbs[I].Addr <> 0) And (Lvbs[I].Pid = MyPid) Then F := I;
      If F < 0 Then R := ERROR_VIO_INVALID_PARMS
      Else If Ofs + Cb > ScrBytes Then R := ERROR_VIO_INVALID_LENGTH
      Else MoveB(Lvbs[F].Addr + Ofs, SBase(0) + Ofs, Cb);
    End;
  End;
  VioShowBuf := R;
End;

{ ---------------------------------------------------------------------
  VioGetPhysBuf(pvioPhysBuf, usReserved) : acces au tampon physique.
  VIOPHYSBUF : pBuf (adresse physique, de 000A0000h a 000BFFFFh), cb,
  asel[0] (rendu : segment reel de l'adresse ; dans OS/2-0, la memoire
  est projetee a l'identique et pBuf est aussi l'adresse lineaire) }
Function VioGetPhysBuf(PPhys, Reserved : LongInt) : LongInt;
Var R, A, N : LongInt;
Begin
  If Hooked(VB_GETPHYSBUF, 2, PPhys, Reserved, 0, 0, 0, 0, 0) Then
  Begin
    VioGetPhysBuf := HookRet;
    Exit;
  End;
  R := NO_ERROR;
  If PPhys = 0 Then R := ERROR_VIO_PTR
  Else
  Begin
    A := RdL(PPhys);
    N := RdL(PPhys + 4);
    If A = 0 Then
    Begin
      If GrMode >= $10000 Then A := GrLfb
      Else If GrMode <> 0 Then A := $000A0000 Else A := ScrBase;
      WrL(PPhys, A);
    End;
    If N = 0 Then
    Begin
      If GrMode = $13 Then N := 65536
      Else If GrMode <> 0 Then N := GrPlane
      Else N := ScrBytes;
      WrL(PPhys + 4, N);
    End;
    If (GrMode >= $10000) And (A >= GrLfb) And (A + N <= GrLfb + GrPlane) And (N >= 0) Then WrW(PPhys + 8, 0)
    Else If (A < $000A0000) Or (A + N > $000C0000) Or (N < 0) Then R := ERROR_VIO_INVALID_PARMS
    Else WrW(PPhys + 8, A Shr 4);
  End;
  VioGetPhysBuf := R;
End;

{ ==================================================================== }
{ Partie 10 - Modes, etats, polices et configuration                   }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  VioGetMode(pvioModeInfo, hvio) : mode video courant.
  VIOMODEINFO : cb (2), fbType (1), color (1), col (2), row (2), hres (2),
  vres (2), fmt_ID (1), attrib (1), buf_addr (4), buf_length (4),
  full_length (4), partial_length (4), ext_data_addr (4) : 34 octets ;
  seuls les champs compris dans cb sont remplis. }
Function VioGetMode(PMode, Hvio : LongInt) : LongInt;
Var R, Cb, Cols, Rows : LongInt;
Begin
  If Hooked(VB_GETMODE, 2, PMode, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioGetMode := HookRet;
    Exit;
  End;
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And (PMode = 0) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    Cb := RdW(PMode);
    If Cb < 3 Then R := ERROR_VIO_INVALID_LENGTH
    Else
    Begin
      Cols := SCols(Hvio); Rows := SRows(Hvio);
      FillB(LongInt(@Scratch), 34, 0);
      If (Hvio = 0) And (SesGr[CurSesNo] <> 0) Then
      Begin
        { mode graphique : col x row = cellules de 8 x 8 (200 lignes),
          8 x 14 (350) ou 8 x 16 (480) }
        WrW(LongInt(@Scratch), Cb);
        WrB(LongInt(@Scratch) + 2, 3);              { VGMT_OTHER + VGMT_GRAPHICS }
        WrB(LongInt(@Scratch) + 3, GrBits);
        WrW(LongInt(@Scratch) + 4, GrW Div 8);
        If GrH = 200 Then WrW(LongInt(@Scratch) + 6, 25)
        Else If GrH = 350 Then WrW(LongInt(@Scratch) + 6, 25)
        Else WrW(LongInt(@Scratch) + 6, GrH Div 16);
        WrW(LongInt(@Scratch) + 8, GrW);
        WrW(LongInt(@Scratch) + 10, GrH);
        WrB(LongInt(@Scratch) + 12, 0);
        WrB(LongInt(@Scratch) + 13, 1);
        If GrMode >= $10000 Then
        Begin
          { VESA : memoire lineaire ; partial_length = octets par ligne }
          WrL(LongInt(@Scratch) + 14, GrLfb);
          WrL(LongInt(@Scratch) + 18, GrPlane);
          WrL(LongInt(@Scratch) + 22, GrPlane);
          WrL(LongInt(@Scratch) + 26, GrPitch);
        End
        Else
        Begin
          WrL(LongInt(@Scratch) + 14, $000A0000);
          WrL(LongInt(@Scratch) + 18, GrPlane);
          If GrBits = 8 Then WrL(LongInt(@Scratch) + 22, GrPlane)
          Else WrL(LongInt(@Scratch) + 22, GrPlane * 4);
          WrL(LongInt(@Scratch) + 26, GrPlane);
        End;
        If Cb > 34 Then Cb := 34;
        MoveB(LongInt(@Scratch), PMode, Cb);
        VioGetMode := R;
        Exit;
      End;
      WrW(LongInt(@Scratch), Cb);
      WrB(LongInt(@Scratch) + 2, 1);               { VGMT_OTHER : couleur, texte }
      WrB(LongInt(@Scratch) + 3, 4);               { 16 couleurs }
      WrW(LongInt(@Scratch) + 4, Cols);
      WrW(LongInt(@Scratch) + 6, Rows);
      WrW(LongInt(@Scratch) + 8, Cols * 9);
      WrW(LongInt(@Scratch) + 10, Rows * CellHeight);
      WrB(LongInt(@Scratch) + 12, 0);
      WrB(LongInt(@Scratch) + 13, 1);
      If Hvio = 0 Then WrL(LongInt(@Scratch) + 14, ScrBase) Else WrL(LongInt(@Scratch) + 14, PS[Hvio].Buf);
      WrL(LongInt(@Scratch) + 18, Cols * Rows * SCell(Hvio));
      WrL(LongInt(@Scratch) + 22, Cols * Rows * SCell(Hvio) + 256 * CellHeight);
      WrL(LongInt(@Scratch) + 26, Cols * Rows * SCell(Hvio));
      If Cb > 34 Then Cb := 34;
      MoveB(LongInt(@Scratch), PMode, Cb);
    End;
  End;
  VioGetMode := R;
End;

{ ---------------------------------------------------------------------
  VioSetMode(pvioModeInfo, hvio) : fixer le mode video (VIOMODEINFO,
  voir VioGetMode ; les champs absents de cb prennent la valeur par
  defaut). fbType : 01h VGMT_OTHER (couleur), 02h VGMT_GRAPHICS, 04h
  VGMT_DISABLEBURST ; color : bits par pel (1, 4 ou 8). Modes :
    texte 80 x 25 (16 couleurs ou monochrome) ;
    graphiques (fbType 03h) : 640 x 480 x 16 (mode VGA 12h, par defaut),
    640 x 480 x 2 (11h), 640 x 350 x 16 (10h), 640 x 200 x 16 (0Eh),
    320 x 200 x 16 (0Dh), 320 x 200 x 256 (13h) ; la resolution est
    donnee par hres et vres (ou col x 8 et row x 8, 14 ou 16) ;
    modes VESA du BIOS de la carte (VBE, par le noyau) : toute resolution
    proposee par la carte (800 x 600, 1024 x 768, 1280 x 1024...) en 8
    bits par pel (256 couleurs) ou 15, 16, 24, 32 bits (couleurs
    directes) ; voir VIOQUERYMODES (ordinal 1002).
  En mode graphique, la memoire de l'ecran est en 000A0000h
  (VioGetPhysBuf) : plans de bits du VGA (mode 13h : un octet par pel) ;
  en mode VESA, elle est lineaire : buf_addr (adresse physique),
  buf_length, et partial_length = octets par ligne (VioGetMode) ;
  les fonctions du mode texte rendent ERROR_VIO_MODE. Le retour au mode
  texte recharge la police, la palette et efface l'ecran. }
Function VioSetMode(PMode, Hvio : LongInt) : LongInt;
Var R, Cb, I, Fb, Bits, Cols, Rows, W, H, K, Kv : LongInt;
Begin
  If Hooked(VB_SETMODE, 2, PMode, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioSetMode := HookRet;
    Exit;
  End;
  R := NO_ERROR; K := -1; Kv := -1;
  If Hvio <> 0 Then R := ERROR_VIO_INVALID_HANDLE
  Else If PMode = 0 Then R := ERROR_VIO_PTR
  Else
  Begin
    Cb := RdW(PMode);
    If Cb < 3 Then R := ERROR_VIO_INVALID_LENGTH
    Else
    Begin
      Fb := RdB(PMode + 2);
      Bits := 0; Cols := 0; Rows := 0; W := 0; H := 0;
      If Cb >= 4 Then Bits := RdB(PMode + 3);
      If Cb >= 6 Then Cols := RdW(PMode + 4);
      If Cb >= 8 Then Rows := RdW(PMode + 6);
      If Cb >= 10 Then W := RdW(PMode + 8);
      If Cb >= 12 Then H := RdW(PMode + 10);
      If (Fb And 2) <> 0 Then
      Begin
        If Bits = 0 Then Bits := 4;
        If W = 0 Then W := Cols * 8;
        If (W = 0) And (Bits = 8) Then W := 320;
        If W = 0 Then W := 640;
        If H = 0 Then
        Begin
          If (Rows = 25) And (W = 320) Then H := 200
          Else If Rows = 25 Then H := 350
          Else If Rows = 30 Then H := 480
          Else If Rows = 43 Then H := 350
          Else If Rows = 60 Then H := 480
          Else If W = 320 Then H := 200
          Else H := 480;
        End;
        For I := 1 To NVgaModes - 1 Do
          If (VgaModeW[I] = W) And (VgaModeH[I] = H) And (VgaModeB[I] = Bits) Then K := I;
        { sinon un mode VESA (8, 15, 16, 24 ou 32 bits par pel) }
        If K < 0 Then
        Begin
          Kv := VesaFind(W, H, Bits);
          If Kv < 0 Then R := ERROR_VIO_MODE;
        End;
      End
      Else If Bits > 4 Then R := ERROR_VIO_MODE
      Else If (Cols <> 0) And (Cols <> NCols) Then R := ERROR_VIO_MODE
      Else If (Rows <> 0) And (Rows <> NRows) Then R := ERROR_VIO_MODE;
    End;
  End;
  { crochet de bascule des sessions (retour au mode texte) }
  If HookOk = 0 Then
  Begin
    HookOk := 1;
    PutZ(LongInt(@Scratch), 'VIOCALLS', 64);
    I := 0;
    If DosLoadModule(LongInt(@Scratch) + 512, 64, LongInt(@Scratch), LongInt(@I)) = 0 Then
      If DosQueryProcAddr(I, 1001, 0, LongInt(@Cb)) = 0 Then Dummy := KSes(6, Cb, 0);
  End;
  If (R = NO_ERROR) And (K > 0) Then
  Begin
    SesGr[CurSesNo] := VgaModeNo[K];
    If Mine Then GrEnter(K);
  End
  Else If (R = NO_ERROR) And (Kv >= 0) Then
  Begin
    SesGr[CurSesNo] := $10000 + VesaNo[Kv];
    If Mine Then
      If Not VesaEnter(Kv) Then
      Begin
        SesGr[CurSesNo] := 0;
        R := ERROR_VIO_MODE;
      End;
  End
  Else If R = NO_ERROR Then
  Begin
    SesGr[CurSesNo] := 0;
    If Mine Then GrLeave;
    For I := 0 To NCols * NRows - 1 Do WrW(SBase(0) + I * 2, $0720);
    SetAttr(0, 7);
    SetCur(0, 0, 0);
    CurStart := CellHeight - 3; CurEnd := CellHeight - 2; CurAttr := 0; CurWidth := 1;
    CursorApply;
  End;
  VioSetMode := R;
End;


{ ---------------------------------------------------------------------
  VioGetConfig(usConfigId, pvioin, hvio) : configuration materielle
  (usConfigId 0 courante, 1 principale ; pas d'ecran secondaire).
  VIOCONFIGINFO : cb, adapter (3 = VGA), display (4 = ecran couleur
  VGA), cbMemory (4), Configuration, VDHVersion, Flags, HWBufferSize (4),
  FullSaveSize (4), PartSaveSize (4), EMAdaptersOFF, EMDisplaysOFF }
Function VioGetConfig(ConfigId, PInfo, Hvio : LongInt) : LongInt;
Var R, Cb : LongInt;
Begin
  If Hooked(VB_GETCONFIG, 3, ConfigId, PInfo, Hvio, 0, 0, 0, 0) Then
  Begin
    VioGetConfig := HookRet;
    Exit;
  End;
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And (PInfo = 0) Then R := ERROR_VIO_PTR;
  If (R = NO_ERROR) And (ConfigId <> 0) And (ConfigId <> 1) Then R := ERROR_VIO_INVALID_PARMS;
  If R = NO_ERROR Then
  Begin
    Cb := RdW(PInfo);
    If Cb < 2 Then R := ERROR_VIO_INVALID_LENGTH
    Else
    Begin
      FillB(LongInt(@Scratch), 34, 0);
      WrW(LongInt(@Scratch), Cb);
      WrW(LongInt(@Scratch) + 2, 3);
      WrW(LongInt(@Scratch) + 4, 4);
      WrL(LongInt(@Scratch) + 6, 262144);
      WrW(LongInt(@Scratch) + 10, 1);
      WrW(LongInt(@Scratch) + 12, 1);
      WrW(LongInt(@Scratch) + 14, 0);
      WrL(LongInt(@Scratch) + 16, ScrBytes);
      WrL(LongInt(@Scratch) + 20, ScrBytes + 256 * 32 + 64 + 768);
      WrL(LongInt(@Scratch) + 24, ScrBytes);
      If Cb > 34 Then Cb := 34;
      MoveB(LongInt(@Scratch), PInfo, Cb);
    End;
  End;
  VioGetConfig := R;
End;

{ Lire (SetIt faux) ou fixer un etat video ; P = VIOPALSTATE (0),
  VIOOVERSCAN (1), VIOINTENSITY (2), VIOCOLORREG (3), VIOSETULINELOC (5),
  VIOSETTARGET (6) }
Function StateOp(P : LongInt; SetIt : Boolean) : LongInt;
Var R, Cb, T, I, N, F, A, M : LongInt;
Begin
  R := NO_ERROR;
  Cb := RdW(P);
  T := RdW(P + 2);
  Case T Of
    0 :
      Begin
        F := RdW(P + 4);
        N := (Cb - 6) Div 2;
        If (Cb < 8) Or (F > 15) Or (F + N > 16) Then R := ERROR_VIO_INVALID_PARMS
        Else
          For I := 0 To N - 1 Do
            If SetIt Then AcSet(F + I, RdW(P + 6 + I * 2) And $3F)
            Else WrW(P + 6 + I * 2, AcGet(F + I));
      End;
    1 :
      If Cb < 6 Then R := ERROR_VIO_INVALID_LENGTH
      Else If SetIt Then
      Begin
        Overscan := RdW(P + 4) And $FF;
        AcSet($11, Overscan);
      End
      Else WrW(P + 4, AcGet($11));
    2 :
      If Cb < 6 Then R := ERROR_VIO_INVALID_LENGTH
      Else If SetIt Then
      Begin
        M := AcGet($10);
        If RdW(P + 4) = 0 Then
        Begin
          Blink := 0;
          AcSet($10, M Or 8);
        End
        Else
        Begin
          Blink := 1;
          AcSet($10, M And Not 8);
        End;
      End
      Else If (AcGet($10) And 8) <> 0 Then WrW(P + 4, 0) Else WrW(P + 4, 1);
    3 :
      Begin
        F := RdW(P + 4);
        N := RdW(P + 6);
        A := RdL(P + 8);
        If (Cb < 12) Or (A = 0) Or (F > 255) Or (F + N > 256) Then R := ERROR_VIO_INVALID_PARMS
        Else
          For I := 0 To N - 1 Do
            If SetIt Then DacSet(F + I, A + I * 3) Else DacGet(F + I, A + I * 3);
      End;
    5 :
      If Cb < 6 Then R := ERROR_VIO_INVALID_LENGTH
      Else If SetIt Then
      Begin
        Underline := RdW(P + 4) And $1F;
        CrtcSet($14, (CrtcGet($14) And $E0) Or Underline);
      End
      Else WrW(P + 4, CrtcGet($14) And $1F);
    6 :
      If Cb < 6 Then R := ERROR_VIO_INVALID_LENGTH
      Else If SetIt Then Target := RdW(P + 4)
      Else WrW(P + 4, Target);
  Else
    R := ERROR_VIO_INVALID_PARMS;
  End;
  StateOp := R;
End;

{ ---------------------------------------------------------------------
  VioGetState(pState, hvio) / VioSetState(pState, hvio) : palette (type
  0 : cb, type, iFirst, acolor[]), bordure (1 : color), intensite (2 :
  0 clignotement, 1 fond intense), registres de couleur (3 : first, num,
  adresse des triplets RVB), soulignement (5 : ligne), cible (6) }
Function VioGetState(PState, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_GETSTATE, 2, PState, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioGetState := HookRet;
    Exit;
  End;
  If Hvio <> 0 Then R := ERROR_VIO_INVALID_HANDLE
  Else If PState = 0 Then R := ERROR_VIO_PTR
  Else R := StateOp(PState, False);
  VioGetState := R;
End;

Function VioSetState(PState, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_SETSTATE, 2, PState, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioSetState := HookRet;
    Exit;
  End;
  If Hvio <> 0 Then R := ERROR_VIO_INVALID_HANDLE
  Else If PState = 0 Then R := ERROR_VIO_PTR
  Else R := StateOp(PState, True);
  VioSetState := R;
End;

{ ---------------------------------------------------------------------
  VioGetFont(pviofi, hvio) : police affichee (type 0) ou d'origine
  (type 1). VIOFONTINFO : cb, type, cxCell, cyCell, pbData (4), cbData.
  pbData = 0 : l'adresse d'une copie interne est rendue. Permise en mode
  graphique (police du mode texte, pour dessiner les caracteres). }
Function VioGetFont(PInfo, Hvio : LongInt) : LongInt;
Var R, T, Need, Src : LongInt;
Begin
  If Hooked(VB_GETFONT, 2, PInfo, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioGetFont := HookRet;
    Exit;
  End;
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And (PInfo = 0) Then R := ERROR_VIO_PTR;
  If (R = NO_ERROR) And (RdW(PInfo) < 14) Then R := ERROR_VIO_INVALID_LENGTH;
  If R = NO_ERROR Then
  Begin
    T := RdW(PInfo + 2);
    Need := 256 * CellHeight;
    If T = 0 Then
    Begin
      { en mode graphique, le plan 2 ne contient plus la police }
      If GrMode = 0 Then ReadFont(LongInt(@FontBuf), CellHeight);
      Src := LongInt(@FontBuf);
    End
    Else If T = 1 Then
    Begin
      If ((RdW(PInfo + 6) <> 0) And (RdW(PInfo + 6) <> CellHeight)) Or
         ((RdW(PInfo + 4) <> 0) And (RdW(PInfo + 4) <> 8) And (RdW(PInfo + 4) <> 9)) Then
        R := ERROR_VIO_FONT;
      Src := LongInt(@RomFont);
    End
    Else
      R := ERROR_VIO_INVALID_PARMS;
    If R = NO_ERROR Then
    Begin
      WrW(PInfo + 4, 9);
      WrW(PInfo + 6, CellHeight);
      If RdL(PInfo + 8) = 0 Then WrL(PInfo + 8, Src)
      Else If RdW(PInfo + 12) < Need Then R := ERROR_VIO_INVALID_LENGTH
      Else MoveB(Src, RdL(PInfo + 8), Need);
      WrW(PInfo + 12, Need);
    End;
  End;
  VioGetFont := R;
End;

{ ---------------------------------------------------------------------
  VioSetFont(pviofi, hvio) : charger une police dans le generateur de
  caracteres (type 0, hauteur egale a celle du mode : cbData / cyCell
  caracteres a partir du caractere 0) }
Function VioSetFont(PInfo, Hvio : LongInt) : LongInt;
Var R, H, N, C : LongInt;
Begin
  If Hooked(VB_SETFONT, 2, PInfo, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioSetFont := HookRet;
    Exit;
  End;
  R := TextErr(Hvio);
  If (R = NO_ERROR) And (PInfo = 0) Then R := ERROR_VIO_PTR;
  If (R = NO_ERROR) And (RdW(PInfo) < 14) Then R := ERROR_VIO_INVALID_LENGTH;
  If R = NO_ERROR Then
  Begin
    H := RdW(PInfo + 6);
    If RdW(PInfo + 2) <> 0 Then R := ERROR_VIO_INVALID_PARMS
    Else If H <> CellHeight Then R := ERROR_VIO_USER_FONT
    Else If (RdW(PInfo + 4) <> 8) And (RdW(PInfo + 4) <> 9) Then R := ERROR_VIO_USER_FONT
    Else If RdL(PInfo + 8) = 0 Then R := ERROR_VIO_PTR
    Else
    Begin
      N := RdW(PInfo + 12) Div H;
      If N > 256 Then N := 256;
      If N < 1 Then R := ERROR_VIO_INVALID_LENGTH
      Else
      Begin
        ReadFont(LongInt(@FontBuf), H);
        For C := 0 To N - 1 Do MoveB(RdL(PInfo + 8) + C * H, LongInt(@FontBuf) + C * H, H);
        WriteFont(LongInt(@FontBuf), H);
      End;
    End;
  End;
  VioSetFont := R;
End;

{ Page de codes acceptee ? (DBCS : 932 936 942 949 950) }
Function CpOk(Cp : LongInt) : Boolean;
Begin
  CpOk := (Cp = 437) Or (Cp = 850) Or (Cp = 852) Or (Cp = 857) Or (Cp = 860) Or (Cp = 861) Or
          (Cp = 863) Or (Cp = 865) Or (Cp = 866) Or (Cp = 932) Or (Cp = 936) Or (Cp = 942) Or
          (Cp = 949) Or (Cp = 950);
End;

Function IsDbcsCp : Boolean;
Begin
  IsDbcsCp := (CodePage = 932) Or (CodePage = 936) Or (CodePage = 942) Or (CodePage = 949) Or
              (CodePage = 950);
End;

{ ---------------------------------------------------------------------
  VioGetCp(usReserved, pIdCodePage, hvio) : page de codes de l'affichage }
Function VioGetCp(Reserved, PCp, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_GETCP, 3, Reserved, PCp, Hvio, 0, 0, 0, 0) Then
  Begin
    VioGetCp := HookRet;
    Exit;
  End;
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And (PCp = 0) Then R := ERROR_VIO_PTR;
  If (R = NO_ERROR) And (Reserved <> 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then WrL(PCp, CodePage);
  VioGetCp := R;
End;

{ ---------------------------------------------------------------------
  VioSetCp(usReserved, idCodePage, hvio) : page de codes de l'affichage
  (0 : page par defaut, 850) }
Function VioSetCp(Reserved, Cp, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_SETCP, 3, Reserved, Cp, Hvio, 0, 0, 0, 0) Then
  Begin
    VioSetCp := HookRet;
    Exit;
  End;
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And (Reserved <> 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then
  Begin
    If Cp = 0 Then Cp := 850;
    If CpOk(Cp) Then CodePage := Cp Else R := ERROR_VIO_BAD_CP;
  End;
  VioSetCp := R;
End;

{ ==================================================================== }
{ Partie 11 - Sessions : fenetres surgissantes, verrou, sauvegarde     }
{ ==================================================================== }
{ OS/2-0 n'a qu'une session plein ecran : les attentes du gestionnaire
  de sessions (VioSavRedrawWait, VioModeWait) ne seraient jamais
  satisfaites et rendent ERROR_INTERRUPT ; les fonctions de sauvegarde
  et de bascule travaillent sur un ecran de reserve. }

Procedure ScreenSave(Dst : LongInt; Var R, C, A : LongInt);
Begin
  MoveB(SBase(0), Dst, ScrBytes);
  GetCur(0, R, C);
  A := GetAttr(0);
End;

Procedure ScreenRestore(Src, R, C, A : LongInt);
Begin
  MoveB(Src, SBase(0), ScrBytes);
  SetCur(0, R, C);
  SetAttr(0, A);
End;

{ ---------------------------------------------------------------------
  VioPopUp(pfWait, hvio) : fenetre surgissante plein ecran (texte 80 x
  25). *pfWait : bit 0 attendre (VP_WAIT), bit 1 transparente (l'ecran
  n'est pas efface). L'ecran est rendu par VioEndPopup. }
Function VioPopUp(PWait, Hvio : LongInt) : LongInt;
Var R, F, I : LongInt;
Begin
  If Hooked(VB_POPUP, 2, PWait, Hvio, 0, 0, 0, 0, 0) Then
  Begin
    VioPopUp := HookRet;
    Exit;
  End;
  R := NO_ERROR;
  If Hvio <> 0 Then R := ERROR_VIO_INVALID_HANDLE
  Else If PWait = 0 Then R := ERROR_VIO_PTR
  Else
  Begin
    F := RdL(PWait);
    If (F And Not 3) <> 0 Then R := ERROR_VIO_WAIT_FLAG
    Else If InPopup Then
    Begin
      If (PopPid = MyPid) Or ((F And 1) <> 0) Then R := ERROR_VIO_EXISTING_POPUP
      Else R := ERROR_VIO_NO_POPUP;
    End
    Else
    Begin
      { en mode graphique : la fenetre surgissante est en mode texte ; le
        mode graphique est rendu (efface) par VioEndPopup }
      PopGr := GrMode;
      If PopGr > 0 Then
      Begin
        GrLeave;
        F := F And Not 2;
      End;
      ScreenSave(LongInt(@PopBuf), PopRow, PopCol, PopAttr);
      InPopup := True;
      PopPid := MyPid;
      If (F And 2) = 0 Then
        For I := 0 To NCols * NRows - 1 Do WrW(SBase(0) + I * 2, $0720);
      SetAttr(0, 7);
      SetCur(0, 0, 0);
    End;
  End;
  VioPopUp := R;
End;

{ ---------------------------------------------------------------------
  VioEndPopup(hvio) : fin de la fenetre surgissante ; l'ecran, le curseur
  et l'attribut d'avant sont rendus }
Function VioEndPopup(Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_ENDPOPUP, 1, Hvio, 0, 0, 0, 0, 0, 0) Then
  Begin
    VioEndPopup := HookRet;
    Exit;
  End;
  R := NO_ERROR;
  If Hvio <> 0 Then R := ERROR_VIO_INVALID_HANDLE
  Else If Not InPopup Or (PopPid <> MyPid) Then R := ERROR_VIO_NO_POPUP
  Else
  Begin
    ScreenRestore(LongInt(@PopBuf), PopRow, PopCol, PopAttr);
    InPopup := False;
    PopPid := 0;
    If PopGr > 0 Then GrEnterCode(PopGr);
    PopGr := 0;
  End;
  VioEndPopup := R;
End;

{ ---------------------------------------------------------------------
  VioScrLock(fWait, pfNotLocked, hvio) : verrouiller l'ecran physique.
  fWait 0 sans attente, 1 avec attente ; *pfNotLocked <- 0 verrouille,
  1 non verrouille (deja pris par un autre processus) }
Function VioScrLock(FWait, PNot, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_SCRLOCK, 3, FWait, PNot, Hvio, 0, 0, 0, 0) Then
  Begin
    VioScrLock := HookRet;
    Exit;
  End;
  R := NO_ERROR;
  If Hvio <> 0 Then R := ERROR_VIO_INVALID_HANDLE
  Else If (FWait <> 0) And (FWait <> 1) Then R := ERROR_VIO_WAIT_FLAG
  Else If PNot = 0 Then R := ERROR_VIO_PTR
  Else If ScrLocked And (LockPid <> MyPid) Then
  Begin
    WrL(PNot, 1);
    If FWait = 1 Then R := ERROR_VIO_LOCK;   { le possesseur attend un processus fils }
  End
  Else
  Begin
    ScrLocked := True;
    LockPid := MyPid;
    WrL(PNot, 0);
  End;
  VioScrLock := R;
End;

{ ---------------------------------------------------------------------
  VioScrUnlock(hvio) : rendre le verrou de l'ecran }
Function VioScrUnlock(Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_SCRUNLOCK, 1, Hvio, 0, 0, 0, 0, 0, 0) Then
  Begin
    VioScrUnlock := HookRet;
    Exit;
  End;
  R := NO_ERROR;
  If Hvio <> 0 Then R := ERROR_VIO_INVALID_HANDLE
  Else If Not ScrLocked Or (LockPid <> MyPid) Then R := ERROR_VIO_UNLOCK
  Else
  Begin
    ScrLocked := False;
    LockPid := 0;
  End;
  VioScrUnlock := R;
End;

{ ---------------------------------------------------------------------
  VioSavRedrawWait(usRedrawInd, pNotifyType, usReserved) : attendre
  qu'une sauvegarde ou un retracage de l'ecran soit demande
  (usRedrawInd 0 sauvegarde et retracage, 1 retracage). Sans changement
  de session, l'attente rend ERROR_INTERRUPT ; le processus devient le
  processus de sauvegarde (VioSavRedrawUndo). }
Function VioSavRedrawWait(RedrawInd, PNotify, Reserved : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_SAVREDRAWWAIT, 3, RedrawInd, PNotify, Reserved, 0, 0, 0, 0) Then
  Begin
    VioSavRedrawWait := HookRet;
    Exit;
  End;
  If (RedrawInd <> 0) And (RedrawInd <> 1) Then R := ERROR_VIO_INVALID_PARMS
  Else If PNotify = 0 Then R := ERROR_VIO_PTR
  Else If (RedrawWaitPid <> 0) And (RedrawWaitPid <> MyPid) Then R := ERROR_VIO_INVALID_PARMS
  Else
  Begin
    RedrawWaitPid := MyPid;
    R := ERROR_INTERRUPT;
  End;
  VioSavRedrawWait := R;
End;

{ ---------------------------------------------------------------------
  VioSavRedrawUndo(usOwnerInd, usKillInd, usReserved) : annuler l'attente
  de VioSavRedrawWait (usOwnerInd 0 garder la propriete, 1 la rendre ;
  usKillInd 0 rendre une erreur au processus leger, 1 le terminer) }
Function VioSavRedrawUndo(OwnerInd, KillInd, Reserved : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_SAVREDRAWUNDO, 3, OwnerInd, KillInd, Reserved, 0, 0, 0, 0) Then
  Begin
    VioSavRedrawUndo := HookRet;
    Exit;
  End;
  R := NO_ERROR;
  If ((OwnerInd <> 0) And (OwnerInd <> 1)) Or ((KillInd <> 0) And (KillInd <> 1)) Then
    R := ERROR_VIO_INVALID_PARMS
  Else If RedrawWaitPid <> MyPid Then R := ERROR_VIO_NO_SAVE_RESTORE_THD
  Else If OwnerInd = 1 Then RedrawWaitPid := 0;
  VioSavRedrawUndo := R;
End;

{ ---------------------------------------------------------------------
  VioModeWait(usReqType, pNotifyType, usReserved) : attendre qu'un mode
  graphique doive etre retabli (usReqType 0) ; rend ERROR_INTERRUPT
  (pas de changement de session) }
Function VioModeWait(ReqType, PNotify, Reserved : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_MODEWAIT, 3, ReqType, PNotify, Reserved, 0, 0, 0, 0) Then
  Begin
    VioModeWait := HookRet;
    Exit;
  End;
  If ReqType <> 0 Then R := ERROR_VIO_INVALID_PARMS
  Else If PNotify = 0 Then R := ERROR_VIO_PTR
  Else If (ModeWaitPid <> 0) And (ModeWaitPid <> MyPid) Then R := ERROR_VIO_INVALID_PARMS
  Else
  Begin
    ModeWaitPid := MyPid;
    R := ERROR_INTERRUPT;
  End;
  VioModeWait := R;
End;

{ ---------------------------------------------------------------------
  VioModeUndo(usOwnerInd, usKillInd, usReserved) : annuler VioModeWait }
Function VioModeUndo(OwnerInd, KillInd, Reserved : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(VB_MODEUNDO, 3, OwnerInd, KillInd, Reserved, 0, 0, 0, 0) Then
  Begin
    VioModeUndo := HookRet;
    Exit;
  End;
  R := NO_ERROR;
  If ((OwnerInd <> 0) And (OwnerInd <> 1)) Or ((KillInd <> 0) And (KillInd <> 1)) Then
    R := ERROR_VIO_INVALID_PARMS
  Else If ModeWaitPid <> MyPid Then R := ERROR_VIO_NO_MODE_THREAD
  Else If OwnerInd = 1 Then ModeWaitPid := 0;
  VioModeUndo := R;
End;

{ Imprimer l'ecran : texte des 25 lignes (espaces de fin retires) ajoute
  au fichier d'impression }
Procedure PrintScreen;
Var R, C, L, N : LongInt;
Begin
  For R := 0 To NRows - 1 Do
  Begin
    L := NCols;
    While (L > 0) And (RdB(SBase(0) + (R * NCols + L - 1) * 2) = 32) Do Dec(L);
    N := 0;
    For C := 0 To L - 1 Do
    Begin
      Scratch[N] := RdB(SBase(0) + (R * NCols + C) * 2);
      Inc(N);
    End;
    Scratch[N] := 13; Scratch[N + 1] := 10;
    PrtWrite(LongInt(@Scratch), N + 2);
  End;
End;

{ ---------------------------------------------------------------------
  VioPrtSc(hvio) : touche Impr ecran (appelee par le gestionnaire de
  sessions) : le texte de l'ecran est ajoute au fichier d'impression
  C:\PRTSC.TXT (pas d'imprimante dans OS/2-0) }
Function VioPrtSc(Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_PRTSC, 1, Hvio, 0, 0, 0, 0, 0, 0) Then
  Begin
    VioPrtSc := HookRet;
    Exit;
  End;
  If Hvio <> 0 Then VioPrtSc := ERROR_VIO_INVALID_HANDLE
  Else
  Begin
    PrintScreen;
    VioPrtSc := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  VioPrtScToggle(hvio) : Ctrl+Impr ecran : la sortie teletype est aussi
  copiee dans le fichier d'impression (bascule) }
Function VioPrtScToggle(Hvio : LongInt) : LongInt;
Begin
  If Hooked(VB_PRTSCTOGGLE, 1, Hvio, 0, 0, 0, 0, 0, 0) Then
  Begin
    VioPrtScToggle := HookRet;
    Exit;
  End;
  If Hvio <> 0 Then VioPrtScToggle := ERROR_VIO_INVALID_HANDLE
  Else
  Begin
    PrtEcho := Not PrtEcho;
    VioPrtScToggle := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  Avs_Prtsc(pBuf, pcb, hvio) : capture de l'ecran : si pBuf <> 0, les
  cellules de l'ecran (2 octets chacune, *pcb octets au plus) sont
  copiees dans pBuf et *pcb recoit la taille copiee ; sinon l'ecran est
  imprime comme par VioPrtSc. }
Function Avs_Prtsc(PBuf, PCb, Hvio : LongInt) : LongInt;
Var R, N : LongInt;
Begin
  R := NO_ERROR;
  If Hvio <> 0 Then R := ERROR_VIO_INVALID_HANDLE
  Else If PBuf = 0 Then PrintScreen
  Else If PCb = 0 Then R := ERROR_VIO_PTR
  Else
  Begin
    N := RdL(PCb);
    If N > ScrBytes Then N := ScrBytes;
    If N < 0 Then N := 0;
    MoveB(SBase(0), PBuf, N);
    WrL(PCb, N);
  End;
  Avs_Prtsc := R;
End;

{ ---------------------------------------------------------------------
  Avs_PrtscToggle(hvio) : activer ou desactiver la capture (copie de la
  sortie teletype dans le fichier d'impression), comme VioPrtScToggle }
Function Avs_PrtscToggle(Hvio : LongInt) : LongInt;
Begin
  If Hvio <> 0 Then Avs_PrtscToggle := ERROR_VIO_INVALID_HANDLE
  Else
  Begin
    PrtEcho := Not PrtEcho;
    Avs_PrtscToggle := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  VioSave(hvio) : sauvegarder l'ecran (cellules, curseur, attribut) dans
  l'ecran de reserve du gestionnaire de sessions }
Function VioSave(Hvio : LongInt) : LongInt;
Begin
  If Hvio <> 0 Then VioSave := ERROR_VIO_INVALID_HANDLE
  Else
  Begin
    ScreenSave(LongInt(@SaveBuf), SaveRow, SaveCol, SaveAttr);
    Saved := True;
    VioSave := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  VioRestore(hvio) : retablir l'ecran sauvegarde par VioSave }
Function VioRestore(Hvio : LongInt) : LongInt;
Begin
  If Hvio <> 0 Then VioRestore := ERROR_VIO_INVALID_HANDLE
  Else If Not Saved Then VioRestore := ERROR_VIO_INVALID_PARMS
  Else
  Begin
    ScreenRestore(LongInt(@SaveBuf), SaveRow, SaveCol, SaveAttr);
    VioRestore := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  VioSswSwitch(hvio) : basculer entre l'ecran courant et l'ecran de
  reserve (deux "sessions" ; la premiere bascule montre un ecran vide) }
Function VioSswSwitch(Hvio : LongInt) : LongInt;
Var R, C, A, I : LongInt;
Begin
  If Hvio <> 0 Then VioSswSwitch := ERROR_VIO_INVALID_HANDLE
  Else
  Begin
    If Not Saved Then
    Begin
      For I := 0 To NCols * NRows - 1 Do
      Begin
        SaveBuf[I * 2] := 32;
        SaveBuf[I * 2 + 1] := 7;
      End;
      SaveRow := 0; SaveCol := 0; SaveAttr := 7;
      Saved := True;
    End;
    ScreenSave(LongInt(@SwapBuf), R, C, A);
    ScreenRestore(LongInt(@SaveBuf), SaveRow, SaveCol, SaveAttr);
    MoveB(LongInt(@SwapBuf), LongInt(@SaveBuf), ScrBytes);
    SaveRow := R; SaveCol := C; SaveAttr := A;
    VioSswSwitch := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  VioRedrawSize(pcbRedraw) : *pcbRedraw <- taille du tampon necessaire
  pour sauvegarder et retracer l'ecran }
Function VioRedrawSize(PCb : LongInt) : LongInt;
Begin
  If PCb = 0 Then VioRedrawSize := ERROR_VIO_PTR
  Else
  Begin
    WrL(PCb, ScrBytes);
    VioRedrawSize := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  VioSrfBlock(hvio) : bloquer l'affichage : les ecritures VIO vont dans
  un ecran fantome jusqu'a VioSrfUnblock, qui l'affiche d'un coup }
Function VioSrfBlock(Hvio : LongInt) : LongInt;
Begin
  If Hvio <> 0 Then VioSrfBlock := ERROR_VIO_INVALID_HANDLE
  Else
  Begin
    If Not Blocked Then
    Begin
      MoveB(ScrBase, LongInt(@Shadow), ScrBytes);
      GetCur(0, ShRow, ShCol);
      TtyAttr := GetAttr(0);
      Blocked := True;
    End;
    VioSrfBlock := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  VioSrfUnblock(hvio) : debloquer l'affichage (l'ecran fantome est
  affiche, avec le curseur et l'attribut) }
Function VioSrfUnblock(Hvio : LongInt) : LongInt;
Begin
  If Hvio <> 0 Then VioSrfUnblock := ERROR_VIO_INVALID_HANDLE
  Else If Not Blocked Then VioSrfUnblock := ERROR_VIO_INVALID_PARMS
  Else
  Begin
    Blocked := False;
    MoveB(LongInt(@Shadow), ScrBase, ScrBytes);
    SetCur(0, ShRow, ShCol);
    SetAttr(0, TtyAttr);
    VioSrfUnblock := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  VioQueryConsole(pInfo, cb, hvio) : etat de la console (cb octets au
  plus de : colonnes, lignes de la zone de defilement, ligne et colonne
  du curseur, attribut, ANSI, page de codes, indicateurs (1 fenetre
  surgissante, 2 ecran verrouille, 4 affichage bloque, 8 ecran
  sauvegarde, 16 copie vers l'impression) : 8 mots de 16 bits) }
Function VioQueryConsole(PInfo, Cb, Hvio : LongInt) : LongInt;
Var R, Y, X, F : LongInt;
Begin
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And (PInfo = 0) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    GetCur(Hvio, Y, X);
    F := 0;
    If InPopup Then F := F Or 1;
    If ScrLocked Then F := F Or 2;
    If Blocked Then F := F Or 4;
    If Saved Then F := F Or 8;
    If PrtEcho Then F := F Or 16;
    WrW(LongInt(@Scratch), SCols(Hvio));
    WrW(LongInt(@Scratch) + 2, TtyRows(Hvio));
    WrW(LongInt(@Scratch) + 4, Y);
    WrW(LongInt(@Scratch) + 6, X);
    WrW(LongInt(@Scratch) + 8, GetAttr(Hvio));
    If AnsiOf(Hvio) Then WrW(LongInt(@Scratch) + 10, 1) Else WrW(LongInt(@Scratch) + 10, 0);
    WrW(LongInt(@Scratch) + 12, CodePage);
    WrW(LongInt(@Scratch) + 14, F);
    If Cb > 16 Then Cb := 16;
    MoveB(LongInt(@Scratch), PInfo, Cb);
  End;
  VioQueryConsole := R;
End;

{ ---------------------------------------------------------------------
  VioInit(usReserved) : initialiser VIO pour le processus (ANSI actif,
  sequence ANSI en cours abandonnee) }
Function VioInit(Reserved : LongInt) : LongInt;
Begin
  ScrAnsi := True;
  EscState := 0;
  VioInit := NO_ERROR;
End;

{ Liberer ce que le processus courant possede }
Procedure FreeProcess(Pid : LongInt);
Var I : LongInt;
Begin
  For I := 0 To MaxLvb - 1 Do
    If (Lvbs[I].Addr <> 0) And (Lvbs[I].Pid = Pid) Then
    Begin
      KHeapFree(KGetProcessHeap, 0, Lvbs[I].Addr);
      Lvbs[I].Addr := 0;
    End;
  For I := 1 To MaxPS Do
    If PS[I].Used And (PS[I].Owner = Pid) Then
    Begin
      KHeapFree(KGetProcessHeap, 0, PS[I].Buf);
      PS[I].Used := False;
    End;
  If InPopup And (PopPid = Pid) Then
  Begin
    ScreenRestore(LongInt(@PopBuf), PopRow, PopCol, PopAttr);
    InPopup := False;
  End;
  If ScrLocked And (LockPid = Pid) Then ScrLocked := False;
  If ModeWaitPid = Pid Then ModeWaitPid := 0;
  If RedrawWaitPid = Pid Then RedrawWaitPid := 0;
End;

{ ---------------------------------------------------------------------
  VioShellInit(usReserved) : initialiser l'environnement video de
  l'interpreteur de commandes (ANSI actif, attribut 07h, affichage
  debloque, ressources VIO du processus liberees) }
Function VioShellInit(Reserved : LongInt) : LongInt;
Begin
  If Blocked Then VioSrfUnblock(0);
  FreeProcess(MyPid);
  VioInit(0);
  CAOn := False;
  SetAttr(0, 7);
  VioShellInit := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  VioHetInit(usReserved) : reinitialiser le materiel video : palette,
  registres de couleur, clignotement, police et curseur d'origine }
Function VioHetInit(Reserved : LongInt) : LongInt;
Begin
  Blink := 0;
  HwReset;
  VioHetInit := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  VioFree(hvio) : liberer les ressources VIO du processus (LVB, espaces
  AVIO, fenetre surgissante, verrou de l'ecran, attentes) }
Function VioFree(Hvio : LongInt) : LongInt;
Begin
  If Hvio <> 0 Then VioFree := ERROR_VIO_INVALID_HANDLE
  Else
  Begin
    FreeProcess(MyPid);
    VioFree := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  VioRegister(pszModName, pszEntryName, flFun1, flFun2) : remplacer les
  fonctions choisies (bits VR_*) pour la session par la fonction
  pszEntryName du module pszModName (voir l'en-tete) }
Function VioRegister(PMod, PEntry, Fun1, Fun2 : LongInt) : LongInt;
Var R, E : LongInt;
Begin
  If RegEntry <> 0 Then R := ERROR_VIO_REGISTER
  Else If (Fun1 = 0) And ((Fun2 And $1FF) = 0) Then R := ERROR_VIO_INVALID_MASK
  Else If (Fun2 And Not $1FF) <> 0 Then R := ERROR_VIO_INVALID_MASK
  Else R := LoadEntry(PMod, PEntry, E);
  If R = NO_ERROR Then
  Begin
    RegEntry := E; RegFun1 := Fun1; RegFun2 := Fun2; RegPass := -1;
  End;
  VioRegister := R;
End;

{ ---------------------------------------------------------------------
  VioDeRegister : retirer le remplacement de la session }
Function VioDeRegister : LongInt;
Begin
  If RegEntry = 0 Then VioDeRegister := ERROR_VIO_DEREGISTER
  Else
  Begin
    RegEntry := 0; RegFun1 := 0; RegFun2 := 0;
    VioDeRegister := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  VioGlobalReg(pszModName, pszEntryName, flFun1, flFun2, usReturn) :
  remplacement pour tous les programmes plein ecran ; usReturn est la
  valeur par laquelle le remplacant demande la fonction de base }
Function VioGlobalReg(PMod, PEntry, Fun1, Fun2, UsReturn : LongInt) : LongInt;
Var R, E : LongInt;
Begin
  If GlbEntry <> 0 Then R := ERROR_VIO_REGISTER
  Else If (Fun1 = 0) And ((Fun2 And $1FF) = 0) Then R := ERROR_VIO_INVALID_MASK
  Else If (Fun2 And Not $1FF) <> 0 Then R := ERROR_VIO_INVALID_MASK
  Else R := LoadEntry(PMod, PEntry, E);
  If R = NO_ERROR Then
  Begin
    GlbEntry := E; GlbFun1 := Fun1; GlbFun2 := Fun2; GlbPass := UsReturn;
  End;
  VioGlobalReg := R;
End;

{ ==================================================================== }
{ Partie 12 - Espaces de presentation AVIO                             }
{ ==================================================================== }
{ Un espace de presentation (PS) est un tableau de cellules en memoire
  (format CGA : caractere et attribut ; format a 4 octets : plus un
  attribut etendu et un octet reserve). Les fonctions Vio* recoivent
  son handle a la place de hvio 0. Sans Presentation Manager, le
  "contexte de peripherique" d'un PS associe (VioAssociate) est l'ecran
  texte : VioShowPS y affiche les cellules, a partir de l'origine fixee
  par VioSetOrg. Une seule police est disponible : "System VIO" (cellules
  de 8 ou 9 pels de large et 8, 14 ou 16 de haut). }

Const
  FontFace = 'System VIO';

{ ---------------------------------------------------------------------
  VioCreatePS(phvps, sDepth, sWidth, sFormat, sAttrs, hvpsReserved) :
  creer un PS de sDepth lignes et sWidth colonnes ; sFormat 1 (CGA,
  sAttrs = 1) ou 3 (4 octets, sAttrs = 3) ; *phvps <- handle }
Function VioCreatePS(PHvps, Depth, Width, Format, Attrs, Reserved : LongInt) : LongInt;
Var R, I, F, CS, Size, J : LongInt;
Begin
  R := NO_ERROR;
  CS := 0;
  If PHvps = 0 Then R := ERROR_VIO_PTR
  Else If Reserved <> 0 Then R := ERROR_VIO_INVALID_PARMS
  Else If (Format = 0) Or (Format = 1) Then
  Begin
    CS := 2;
    If (Attrs <> 1) And (Attrs <> 0) Then R := ERROR_VIO_ATTR;
  End
  Else If Format = 3 Then
  Begin
    CS := 4;
    If (Attrs <> 3) And (Attrs <> 0) Then R := ERROR_VIO_ATTR;
  End
  Else R := ERROR_VIO_INVALID_PARMS;
  If (R = NO_ERROR) And ((Depth < 1) Or (Width < 1) Or (Width > 255) Or (Depth * Width > 32767)) Then
    R := ERROR_VIO_INVALID_PARMS;
  F := 0;
  If R = NO_ERROR Then
  Begin
    For I := MaxPS DownTo 1 Do
      If Not PS[I].Used Then F := I;
    If F = 0 Then R := ERROR_VIO_INVALID_HANDLE;
  End;
  If R = NO_ERROR Then
  Begin
    Size := Depth * Width * CS;
    PS[F].Buf := KHeapAlloc(KGetProcessHeap, 8, Size);
    If PS[F].Buf = 0 Then R := 8
    Else
    Begin
      PS[F].Used := True;
      PS[F].Owner := MyPid;
      PS[F].Rows := Depth; PS[F].Cols := Width; PS[F].CellSz := CS;
      For J := 0 To Depth * Width - 1 Do
      Begin
        WrB(PS[F].Buf + J * CS, 32);
        WrB(PS[F].Buf + J * CS + 1, 7);
      End;
      PS[F].CurRow := 0; PS[F].CurCol := 0;
      PS[F].CellH := 16; PS[F].CellW := 8;
      PS[F].CurStart := 13; PS[F].CurEnd := 14; PS[F].CurAttr := 0;
      PS[F].OrgRow := 0; PS[F].OrgCol := 0;
      PS[F].Hdc := 0; PS[F].WinCx := 0; PS[F].WinCy := 0;
      PS[F].Attr := 7;
      PS[F].Ansi := True;
      For J := 0 To MaxLcid - 1 Do PS[F].Lcid[J] := 0;
      WrL(PHvps, F);
    End;
  End;
  VioCreatePS := R;
End;

{ ---------------------------------------------------------------------
  VioDestroyPS(hvps) : detruire un PS }
Function VioDestroyPS(Hvps : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hvps = 0 Then R := ERROR_VIO_INVALID_HANDLE Else R := SurfErr(Hvps);
  If R = NO_ERROR Then
  Begin
    KHeapFree(KGetProcessHeap, 0, PS[Hvps].Buf);
    PS[Hvps].Used := False;
    PS[Hvps].Hdc := 0;
  End;
  VioDestroyPS := R;
End;

{ ---------------------------------------------------------------------
  VioAssociate(hdc, hvps) : associer le PS a un contexte de peripherique
  (hdc <> 0 : l'ecran ; le PS y est affiche ; DC d'une fenetre de PM,
  WinOpenWindowDC : le PS est dessine dans la fenetre) ou le dissocier
  (hdc = 0) }
Function VioAssociate(Hdc, Hvps : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hvps = 0 Then R := ERROR_VIO_INVALID_HANDLE Else R := SurfErr(Hvps);
  If R = NO_ERROR Then
  Begin
    PS[Hvps].Hdc := Hdc; PS[Hvps].WinCx := 0; PS[Hvps].WinCy := 0;
    If Hdc <> 0 Then PaintPS(Hvps, 0, PS[Hvps].Rows, PS[Hvps].Cols);
  End;
  VioAssociate := R;
End;

{ ---------------------------------------------------------------------
  VIOAVIOSIZE(hdc, cx, cy) (interne, ordinal 1004 ; appele par
  WinDefAVioWindowProc de PMVIOP.DLL sur WM_SIZE) : taille de la fenetre
  des PS associes au DC hdc ; ils sont redessines. Rend leur nombre. }
Function VioAvioSize(Hdc, Cx, Cy : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  If Hdc <> 0 Then
    For I := 1 To MaxPS Do
      If PS[I].Used And (PS[I].Hdc = Hdc) Then
      Begin
        PS[I].WinCx := Cx; PS[I].WinCy := Cy;
        PaintPS(I, 0, PS[I].Rows, PS[I].Cols);
        Inc(N);
      End;
  VioAvioSize := N;
End;

{ VIOQUERYAVIOSIZE(hvps, p) (interne, ordinal 1005) : taille de la
  fenetre connue du PS (cx, cy), lignes et colonnes visibles }
Function VioQueryAvioSize(Hvps, P : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hvps = 0 Then R := ERROR_VIO_INVALID_HANDLE Else R := SurfErr(Hvps);
  If (R = NO_ERROR) And (P = 0) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    WrL(P, PS[Hvps].WinCx); WrL(P + 4, PS[Hvps].WinCy);
    If PS[Hvps].CellH > 0 Then WrL(P + 8, PS[Hvps].WinCy Div PS[Hvps].CellH) Else WrL(P + 8, 0);
    WrL(P + 12, PS[Hvps].WinCx Div 8);
  End;
  VioQueryAvioSize := R;
End;

{ ---------------------------------------------------------------------
  VioShowPS(sDepth, sWidth, sCellOffset, hvps) : afficher un rectangle
  du PS (sDepth lignes, sWidth colonnes, a partir de la cellule
  sCellOffset) }
Function VioShowPS(Depth, Width, Ofs, Hvps : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hvps = 0 Then R := ERROR_VIO_INVALID_HANDLE Else R := SurfErr(Hvps);
  If R = NO_ERROR Then
  Begin
    If PS[Hvps].Hdc = 0 Then R := ERROR_VIO_INVALID_PARMS
    Else If (Ofs < 0) Or (Ofs >= PS[Hvps].Rows * PS[Hvps].Cols) Or (Depth < 0) Or (Width < 0) Then
      R := ERROR_VIO_INVALID_PARMS
    Else PaintPS(Hvps, Ofs, Depth, Width);
  End;
  VioShowPS := R;
End;

{ ---------------------------------------------------------------------
  VioSetOrg(sRow, sColumn, hvps) : cellule du PS affichee en haut a
  gauche de la fenetre (l'ecran est retrace si le PS est associe) }
Function VioSetOrg(Row, Col, Hvps : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hvps = 0 Then R := ERROR_VIO_INVALID_HANDLE Else R := SurfErr(Hvps);
  If R = NO_ERROR Then
  Begin
    If (Row < 0) Or (Row >= PS[Hvps].Rows) Then R := ERROR_VIO_ROW
    Else If (Col < 0) Or (Col >= PS[Hvps].Cols) Then R := ERROR_VIO_COL
    Else
    Begin
      PS[Hvps].OrgRow := Row;
      PS[Hvps].OrgCol := Col;
      If PS[Hvps].Hdc <> 0 Then PaintPS(Hvps, 0, PS[Hvps].Rows, PS[Hvps].Cols);
    End;
  End;
  VioSetOrg := R;
End;

{ ---------------------------------------------------------------------
  VioGetOrg(psRow, psColumn, hvps) : origine de l'affichage du PS }
Function VioGetOrg(PRow, PCol, Hvps : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hvps = 0 Then R := ERROR_VIO_INVALID_HANDLE Else R := SurfErr(Hvps);
  If (R = NO_ERROR) And ((PRow = 0) Or (PCol = 0)) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    WrL(PRow, PS[Hvps].OrgRow);
    WrL(PCol, PS[Hvps].OrgCol);
  End;
  VioGetOrg := R;
End;

{ Nom de la police logique I du PS Hvps (32 octets) }
Function LcNameAt(Hvps, I : LongInt) : LongInt;
Begin
  LcNameAt := LongInt(@LcNames) + ((Hvps - 1) * MaxLcid + I) * 32;
End;

Function CellSizeOk(H, W : LongInt) : Boolean;
Begin
  CellSizeOk := ((H = 8) Or (H = 14) Or (H = 16)) And ((W = 8) Or (W = 9));
End;

{ ---------------------------------------------------------------------
  VioGetDeviceCellSize(psHeight, psWidth, hvps) : taille d'une cellule
  en pels }
Function VioGetDeviceCellSize(PHeight, PWidth, Hvps : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := SurfErr(Hvps);
  If (R = NO_ERROR) And ((PHeight = 0) Or (PWidth = 0)) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    If Hvps = 0 Then
    Begin
      WrL(PHeight, CellHeight);
      WrL(PWidth, 9);
    End
    Else
    Begin
      WrL(PHeight, PS[Hvps].CellH);
      WrL(PWidth, PS[Hvps].CellW);
    End;
  End;
  VioGetDeviceCellSize := R;
End;

{ ---------------------------------------------------------------------
  VioSetDeviceCellSize(sHeight, sWidth, hvps) : taille d'une cellule
  (polices disponibles : 8 x 8, 8 x 14, 8 x 16, ou 9 de large) }
Function VioSetDeviceCellSize(Height, Width, Hvps : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hvps = 0 Then R := ERROR_VIO_INVALID_HANDLE Else R := SurfErr(Hvps);
  If (R = NO_ERROR) And Not CellSizeOk(Height, Width) Then R := ERROR_VIO_INVALID_PARMS;
  If R = NO_ERROR Then
  Begin
    PS[Hvps].CellH := Height;
    PS[Hvps].CellW := Width;
  End;
  VioSetDeviceCellSize := R;
End;

{ ---------------------------------------------------------------------
  VioCreateLogFont(pfatattrs, llcid, pName, hvps) : associer une police
  logique a l'identificateur local llcid (1 a 254) du PS.
  FATTRS : usRecordLength, fsSelection, lMatch (4), szFacename[32],
  idRegistry, usCodePage, lMaxBaselineExt (4), lAveCharWidth (4),
  fsType, fsFontUse ; pName : nom de 8 caracteres (STR8) }
Function VioCreateLogFont(PAttrs, Lcid, PName, Hvps : LongInt) : LongInt;
Var R, I, F, H, W : LongInt; Face : String;
Begin
  If Hvps = 0 Then R := ERROR_VIO_INVALID_HANDLE Else R := SurfErr(Hvps);
  If (R = NO_ERROR) And (PAttrs = 0) Then R := ERROR_VIO_PTR;
  If (R = NO_ERROR) And ((Lcid < 1) Or (Lcid > 254)) Then R := ERROR_VIO_INVALID_PARMS;
  If R = NO_ERROR Then
  Begin
    Face := GetZ(PAttrs + 8);
    H := RdL(PAttrs + 44);
    W := RdL(PAttrs + 48);
    If H = 0 Then H := 16;
    If W = 0 Then W := 8;
    If (Face <> '') And (Face <> FontFace) Then R := ERROR_VIO_FONT
    Else If Not CellSizeOk(H, W) Then R := ERROR_VIO_FONT;
  End;
  If R = NO_ERROR Then
  Begin
    F := -1;
    For I := MaxLcid - 1 DownTo 0 Do
    Begin
      If PS[Hvps].Lcid[I] = Lcid Then R := ERROR_VIO_INVALID_PARMS;
      If PS[Hvps].Lcid[I] = 0 Then F := I;
    End;
    If (R = NO_ERROR) And (F < 0) Then R := ERROR_VIO_INVALID_PARMS;
    If R = NO_ERROR Then
    Begin
      PS[Hvps].Lcid[F] := Lcid;
      PS[Hvps].LcH[F] := H;
      FillB(LcNameAt(Hvps, F), 32, 0);
      If PName <> 0 Then MoveB(PName, LcNameAt(Hvps, F), 8);
    End;
  End;
  VioCreateLogFont := R;
End;

{ ---------------------------------------------------------------------
  VioDeleteSetId(lcid, hvps) : liberer un identificateur local
  (-1 : tous) }
Function VioDeleteSetId(Lcid, Hvps : LongInt) : LongInt;
Var R, I, Found : LongInt;
Begin
  If Hvps = 0 Then R := ERROR_VIO_INVALID_HANDLE Else R := SurfErr(Hvps);
  If R = NO_ERROR Then
  Begin
    Found := 0;
    For I := 0 To MaxLcid - 1 Do
      If (PS[Hvps].Lcid[I] <> 0) And ((Lcid = -1) Or (PS[Hvps].Lcid[I] = Lcid)) Then
      Begin
        PS[Hvps].Lcid[I] := 0;
        Inc(Found);
      End;
    If (Found = 0) And (Lcid <> -1) Then R := ERROR_VIO_INVALID_PARMS;
  End;
  VioDeleteSetId := R;
End;

{ ---------------------------------------------------------------------
  VioQuerySetIds(allcids, pNames, alTypes, lcount, hvps) : identificateurs
  locaux du PS (lcount au plus) : lcid (LONG), nom (STR8), type (6 =
  LCIDT_FONT) }
Function VioQuerySetIds(PLcids, PNames, PTypes, Count, Hvps : LongInt) : LongInt;
Var R, I, N : LongInt;
Begin
  If Hvps = 0 Then R := ERROR_VIO_INVALID_HANDLE Else R := SurfErr(Hvps);
  If R = NO_ERROR Then
  Begin
    N := 0;
    For I := 0 To MaxLcid - 1 Do
      If (PS[Hvps].Lcid[I] <> 0) And (N < Count) Then
      Begin
        WrL(PLcids + N * 4, PS[Hvps].Lcid[I]);
        If PNames <> 0 Then MoveB(LcNameAt(Hvps, I), PNames + N * 8, 8);
        WrL(PTypes + N * 4, 6);
        Inc(N);
      End;
  End;
  VioQuerySetIds := R;
End;

{ ---------------------------------------------------------------------
  VioQueryFonts(plRemFonts, afmMetrics, lMetricsLength, plFonts,
  pszFacename, flOptions, hvps) : polices disponibles ("System VIO" en
  8, 14 et 16 pels de haut). *plFonts : nombre demande, puis rendu ;
  *plRemFonts <- polices non rendues ; afmMetrics : FONTMETRICS de
  lMetricsLength octets chacun (noms de famille et de police, hauteurs,
  largeurs, caracteres, taille en points) }
Function VioQueryFonts(PRem, PMetrics, MLen, PCount, PFace, Options, Hvps : LongInt) : LongInt;
Var R, Want, Total, I, H, A, N : LongInt; Face : String;
Begin
  R := SurfErr(Hvps);
  If (R = NO_ERROR) And (PCount = 0) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    Face := '';
    If PFace <> 0 Then Face := GetZ(PFace);
    If (Face = '') Or (Face = FontFace) Then Total := 3 Else Total := 0;
    Want := RdL(PCount);
    If Want > Total Then Want := Total;
    If (PMetrics = 0) Or (MLen <= 0) Then Want := 0;
    For I := 0 To Want - 1 Do
    Begin
      Case I Of
        0 : H := 8;
        1 : H := 14;
      Else
        H := 16;
      End;
      FillB(LongInt(@Scratch), 228, 0);
      A := LongInt(@Scratch);
      PutZ(A, FontFace, 32);
      PutZ(A + 32, FontFace, 32);
      WrW(A + 66, CodePage);
      WrL(A + 68, H);                      { lEmHeight }
      WrL(A + 72, H Div 2);                { lXHeight }
      WrL(A + 76, H - 2);                  { lMaxAscender }
      WrL(A + 80, 2);                      { lMaxDescender }
      WrL(A + 100, 8);                     { lAveCharWidth }
      WrL(A + 104, 8);                     { lMaxCharInc }
      WrL(A + 108, 8);                     { lEmInc }
      WrL(A + 112, H);                     { lMaxBaselineExt }
      WrW(A + 122, 5);                     { usWeightClass : normal }
      WrW(A + 124, 5);                     { usWidthClass }
      WrW(A + 130, 1);                     { sFirstChar }
      WrW(A + 132, 254);                   { sLastChar }
      WrW(A + 134, 32);                    { sDefaultChar }
      WrW(A + 136, 32);                    { sBreakChar }
      WrW(A + 138, H * 10 Div 2);          { sNominalPointSize (dixiemes) }
      WrW(A + 144, 1);                     { fsType : FM_TYPE_FIXED }
      N := MLen;
      If N > 228 Then N := 228;
      MoveB(A, PMetrics + I * MLen, N);
    End;
    WrL(PCount, Want);
    WrL(PRem, Total - Want);
  End;
  VioQueryFonts := R;
End;

{ ---------------------------------------------------------------------
  VioGetPSAddress(ppBuf, hvps) : *ppBuf <- adresse des cellules du PS
  (hvps 0 : l'ecran) }
Function VioGetPSAddress(PPBuf, Hvps : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := SurfErr(Hvps);
  If (R = NO_ERROR) And (PPBuf = 0) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then WrL(PPBuf, SBase(Hvps));
  VioGetPSAddress := R;
End;

{ ==================================================================== }
{ Partie 13 - Jeux de caracteres a double octet (XVio*)                }
{ ==================================================================== }
{ Avec une page de codes DBCS (932, 936, 942, 949, 950), un caractere
  peut occuper deux cellules (octet de tete puis octet de queue).
  Les jeux d'attributs etendus (CA) modifient les attributs ecrits :
  CAINFO = cb, fsAttr (1 souligne, 2 inverse, 4 clignotant, 8 intense,
  16 cache), color (attribut de couleur, FFFFh = inchange). }

Function IsLead(B : LongInt) : Boolean;
Begin
  If (CodePage = 932) Or (CodePage = 942) Then
    IsLead := ((B >= $81) And (B <= $9F)) Or ((B >= $E0) And (B <= $FC))
  Else
    IsLead := (B >= $81) And (B <= $FE);
End;

{ ---------------------------------------------------------------------
  VioCheckCharType(pType, usRow, usColumn, hvio) : type du caractere de
  la cellule : 0 simple, 1 double complet (cellule de 4 octets), 2 premiere
  moitie, 3 seconde moitie d'un caractere double }
Function VioCheckCharType(PType, Row, Col, Hvio : LongInt) : LongInt;
Var R, Avail, I, T, C : LongInt;
Begin
  R := TextErr(Hvio);
  If (R = NO_ERROR) And (PType = 0) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then R := PosErr(Hvio, Row, Col, Avail);
  If R = NO_ERROR Then
  Begin
    T := VCC_SBCSCHAR;
    If IsDbcsCp Then
    Begin
      I := 0;
      While I < Col Do
      Begin
        C := RdB(CellAt(Hvio, Row, I));
        If IsLead(C) Then I := I + 2 Else I := I + 1;
      End;
      If I > Col Then T := VCC_DBCS2NDHALF
      Else If IsLead(RdB(CellAt(Hvio, Row, Col))) Then
      Begin
        If SCell(Hvio) = 4 Then T := VCC_DBCSFULLCHAR Else T := VCC_DBCS1STHALF;
      End;
    End;
    WrL(PType, T);
  End;
  VioCheckCharType := R;
End;

{ ---------------------------------------------------------------------
  XVioCheckCharType(pType, usRow, usColumn, hvio) : comme
  VioCheckCharType }
Function XVioCheckCharType(PType, Row, Col, Hvio : LongInt) : LongInt;
Begin
  XVioCheckCharType := VioCheckCharType(PType, Row, Col, Hvio);
End;

{ ---------------------------------------------------------------------
  XVioCreateCA(phca, pCAInfo, hvio) : creer un jeu d'attributs etendus ;
  *phca <- handle }
Function XVioCreateCA(PHca, PInfo, Hvio : LongInt) : LongInt;
Var R, I, F : LongInt;
Begin
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And ((PHca = 0) Or (PInfo = 0)) Then R := ERROR_VIO_PTR;
  If (R = NO_ERROR) And (RdW(PInfo) < 6) Then R := ERROR_VIO_INVALID_LENGTH;
  If (R = NO_ERROR) And ((RdW(PInfo + 2) And Not $1F) <> 0) Then R := ERROR_VIO_INVALID_PARMS;
  F := 0;
  If R = NO_ERROR Then
  Begin
    For I := MaxCA DownTo 1 Do
      If Not CAs[I].Used Then F := I;
    If F = 0 Then R := ERROR_VIO_INVALID_HANDLE;
  End;
  If R = NO_ERROR Then
  Begin
    CAs[F].Used := True;
    CAs[F].Flags := RdW(PInfo + 2);
    If RdW(PInfo + 4) = $FFFF Then CAs[F].Color := -1 Else CAs[F].Color := RdW(PInfo + 4) And $FF;
    WrL(PHca, F);
  End;
  XVioCreateCA := R;
End;

Function CAErr(Hca : LongInt) : LongInt;
Begin
  CAErr := NO_ERROR;
  If (Hca < 1) Or (Hca > MaxCA) Then CAErr := ERROR_VIO_INVALID_HANDLE
  Else If Not CAs[Hca].Used Then CAErr := ERROR_VIO_INVALID_HANDLE;
End;

{ ---------------------------------------------------------------------
  XVioDestroyCA(hca, hvio) : detruire un jeu d'attributs }
Function XVioDestroyCA(Hca, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := SurfErr(Hvio);
  If R = NO_ERROR Then R := CAErr(Hca);
  If R = NO_ERROR Then
  Begin
    CAs[Hca].Used := False;
    If CurCA = Hca Then
    Begin
      CurCA := 0;
      CAOn := False;
    End;
  End;
  XVioDestroyCA := R;
End;

{ ---------------------------------------------------------------------
  XVioSetCAState(hca, fState, hvio) : activer (fState 1) le jeu hca pour
  les ecritures suivantes, ou desactiver (0) les attributs etendus }
Function XVioSetCAState(Hca, FState, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And (FState <> 0) And (FState <> 1) Then R := ERROR_VIO_INVALID_PARMS;
  If (R = NO_ERROR) And (FState = 1) Then R := CAErr(Hca);
  If R = NO_ERROR Then
  Begin
    If FState = 1 Then CurCA := Hca;
    CAOn := FState = 1;
  End;
  XVioSetCAState := R;
End;

{ ---------------------------------------------------------------------
  XVioGetCAState(phca, pfState, hvio) : jeu actif et etat }
Function XVioGetCAState(PHca, PState, Hvio : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := SurfErr(Hvio);
  If (R = NO_ERROR) And ((PHca = 0) Or (PState = 0)) Then R := ERROR_VIO_PTR;
  If R = NO_ERROR Then
  Begin
    WrL(PHca, CurCA);
    If CAOn Then WrL(PState, 1) Else WrL(PState, 0);
  End;
  XVioGetCAState := R;
End;

{ VIOSESSSWITCH (ordinal 1001, interne) : appele par le noyau quand une
  session en mode texte passe au premier plan : le VGA revient au mode
  texte (registres, police, palette) }
Function VioSessSwitch(Op : LongInt) : LongInt;
Var V : LongInt;
Begin
  { le mode de la session de l'appelant (qui n'est pas celle qui passe au
    premier plan) est garde }
  V := SesGr[CurSesNo];
  If GrMode <> 0 Then GrLeave;
  SesGr[CurSesNo] := V;
  VioSessSwitch := 0;
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  VioEndPopup Index 1, VioGetPhysBuf Index 2, VioGetAnsi Index 3, VioFree Index 4,
  VioSetAnsi Index 5, VioDeRegister Index 6, VioScrollUp Index 7, VioPrtSc Index 8,
  VioGetCurPos Index 9, VioWrtCellStr Index 10, VioPopUp Index 11,
  VioScrollRt Index 12, VioScrollRt Name 'VioScrollRi' Index 12,
  VioWrtCharStr Index 13, Avs_Prtsc Name 'Avs_Prtsc' Index 14,
  VioSetCurPos Index 15, VioSetCurPos Name 'VioSetCursorPos' Index 15,
  VioSrfUnblock Index 16, VioSrfBlock Index 17, VioScrUnlock Index 18, VioWrtTty Index 19,
  VioSave Index 20, VioGetMode Index 21, VioSetMode Index 22, VioScrLock Index 23,
  VioReadCellStr Index 24, VioSavRedrawWait Index 25, VioWrtNAttr Index 26,
  VioGetCurType Index 27, VioSavRedrawUndo Index 28, VioGetFont Index 29,
  VioReadCharStr Index 30, VioGetBuf Index 31, VioSetCurType Index 32, VioSetFont Index 33,
  VioHetInit Index 34, VioModeUndo Index 35, VioSswSwitch Index 36, VioModeWait Index 37,
  Avs_PrtscToggle Name 'Avs_PrtscToggle' Index 38, VioInit Index 39, VioGetCp Index 40,
  VioRestore Index 41, VioSetCp Index 42, VioShowBuf Index 43,
  VioScrollLf Index 44, VioScrollLf Name 'VioScrollLe' Index 44,
  VioRegister Index 45, VioGetConfig Index 46, VioScrollDn Index 47,
  VioWrtCharStrAtt Index 48, VioGetState Index 49, VioPrtScToggle Index 50,
  VioSetState Index 51, VioWrtNCell Index 52, VioWrtNChar Index 53, VioShellInit Index 54,
  VioAssociate Index 55, VioCreatePS Index 56, VioDeleteSetId Index 57,
  VioGetDeviceCellSize Index 58, VioGetOrg Index 59, VioCreateLogFont Index 60,
  VioDestroyPS Index 61, VioQuerySetIds Index 62, VioSetOrg Index 63, VioQueryFonts Index 64,
  VioSetDeviceCellSize Index 65, VioShowPS Index 66, VioGetPSAddress Index 67,
  VioQueryConsole Index 68, VioRedrawSize Index 69, VioGlobalReg Index 70,
  XVioSetCAState Index 71, XVioCheckCharType Index 72, XVioDestroyCA Index 73,
  XVioCreateCA Index 74, VioCheckCharType Index 75, XVioGetCAState Index 76,
  VioSessSwitch Name 'VIOSESSSWITCH' Index 1001,
  VioQueryModes Name 'VIOQUERYMODES' Index 1002, VioQueryVbe Name 'VIOQUERYVBE' Index 1003,
  VioAvioSize Name 'VIOAVIOSIZE' Index 1004, VioQueryAvioSize Name 'VIOQUERYAVIOSIZE' Index 1005;

Var
  InitI : LongInt;

BEGIN
  PmFnOk := 0;
  ConH := KGetStdHandle(-11);
  ScrAnsi := True;
  CodePage := 850;
  PrtFile := 'C:\PRTSC.TXT';
  TtyAttr := 7;
  EscState := 0;
  CurCA := 0;
  CAOn := False;
  Target := 0;
  For InitI := 1 To MaxPS Do PS[InitI].Used := False;
  For InitI := 1 To MaxCA Do CAs[InitI].Used := False;
  For InitI := 0 To MaxLvb - 1 Do Lvbs[InitI].Addr := 0;
  VesaN := -1;
  HwCapture;
END.
