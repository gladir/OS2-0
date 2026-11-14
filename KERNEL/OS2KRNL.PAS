{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2KRNL)
  @description: Noyau OS/2-0 32 bits (OS2KRNL).
}

Program OS2KRNL;

{ Compilation : OS2PC -COS2KRNL OS2KRNL.PAS   (produit le fichier OS2KRNL)

  OS2KRNL est une image PE 80386 liee a l'adresse 00100000h (1 Mo).
  OS2LDR la recopie a cette adresse, passe en mode protege (GDT plate,
  08h = code, 10h = donnees) et saute au programme principal avec une
  pile en 00090000h. Le bloc d'information d'amorcage est en 00000500h.

  Le noyau est ecrit en un seul fichier, par parties :

    Partie 1  - Constantes, types et variables
    Partie 2  - Utilitaires (memoire, chaines, nombres)
    Partie 3  - Console VGA texte et port serie COM1 (journal)
    Partie 4  - Processeur : GDT, IDT, exceptions (ecran TRAP), PIC
    Partie 5  - Minuterie (PIT), horloge temps reel (CMOS), haut-parleur
    Partie 6  - Clavier (IRQ 1) et editeur de ligne de commande
    Partie 6b - Souris PS/2 (IRQ 12), lue par MOUCALLS.DLL
    Partie 6c - Imprimante (ports paralleles) et moniteurs (MONCALLS.DLL)
    Partie 7  - Memoire : tas du noyau et memoire physique
    Partie 8  - Pagination : fenetre des processus (00400000h-007FFFFFh)
    Partie 9  - Pilote ATAPI (CD-ROM IDE, mode PIO)
    Partie 9b - Peripheriques bloc : disques durs IDE (PIO) et disque
                virtuel pour les systemes de fichiers installables
    Partie 10 - Systeme de fichiers ISO 9660 et disque virtuel en memoire
    Partie 11 - Table des handles, chemins et repertoire courant
    Partie 11b- Systemes de fichiers installables (IFS= : HPFS.IFS),
                FSH_DOVOLIO et aiguillage des unites D: a Z:
    Partie 12 - Couche API (DOSCALLS) utilisee par le runtime de OS2PC
    Partie 13 - Chargeur de programmes PE et processus
    Partie 14 - Demarrage du systeme : CONFIG.SYS et CMD.EXE
    Video     - appel du BIOS en mode reel (KERNEL/BIOSCALL.ASM, recopie
                en 0000:7000) et modes VESA du BIOS VBE : KrnVideo
                (liste des modes a memoire lineaire, passage a un mode
                VESA ou a un mode du BIOS), utilise par VIOCALLS.DLL

  Couche API : le runtime genere par OS2PC (WriteLn, ReadLn, unites Crt
  et Dos, fichiers...) appelle des fonctions de style Win32 (WriteFile,
  CreateFileA, FindFirstFileA...). Pour la cible -COS2KRNL, le compilateur
  relie chacun de ces appels a la procedure Pascal du noyau de meme nom
  et les publie dans la table d'exportation DOSCALLS.DLL de l'image. Le
  meme runtime sert donc au noyau lui-meme et aux programmes OS/2-0
  (CMD.EXE compile avec OS2PC -COS2), dont les importations sont liees
  par le chargeur de la partie 13. Les parametres de ces procedures sont
  des valeurs 32 bits (LongInt) : les pointeurs sont des adresses
  lineaires lues et ecrites avec Mem, MemW et MemL[0:adresse].

  Unites : C: est le CD-ROM d'amorcage (avec un disque virtuel superpose
  pour les fichiers crees) ; les volumes reconnus par un pilote IFS
  (partitions de type 07h des disques durs IDE, puis disque virtuel
  /RAMDISK:n) recoivent les lettres D: et suivantes, et leurs fichiers
  sont confies aux points d'entree FS_* du pilote.

  Les programmes s'executent en anneau 0, dans une fenetre de 4 Mo
  (00400000h-007FFFFFh) propre a chaque processus (pagination).

  Multitache : chaque fil d'execution est une tache (la tache 0 est le
  noyau) ; CtxSwitch change de pile. Une attente (Idle) cede le
  processeur aux autres taches (arret du processeur quand toutes
  attendent) ; la minuterie (100 Hz) interrompt toutes les 30 ms une
  tache qui execute le code de son programme : le noyau et les DLL, dont
  les donnees sont globales, ne sont jamais interrompus, et un programme
  de PM (PMWIN.DLL appelle ses procedures de fenetre) n'est pas preempte.
  CreateProcessA est asynchrone (WaitForSingleObject attend la fin) ;
  KrnTaskCtl sert DOSCALLS.DLL (fils, attentes, etat des processus).

  Sessions : une session a son ecran (tampon video logique de 32 Ko), sa
  console (curseur, attribut, lignes) et sa file du clavier. La table de
  pages des 4 premiers Mo est propre a chaque session : celle qui est au
  premier plan voit le VGA en 000A0000h et 000B8000h, les autres leur
  tampon (et une zone perdue pour la memoire graphique). Les ports du VGA
  ne sont programmes que par la session au premier plan (VIOCALLS,
  PMWIN, PMGPI). Alt+Echap passe a la session suivante, Ctrl+Echap
  revient a Presentation Manager ; KrnSesCtl cree les sessions, les met
  au premier plan et fait entrer les programmes de PM dans la session de
  PM. }

{$R-,S-,I-}

{ ==================================================================== }
{ Partie 1 - Constantes, types et variables                            }
{ ==================================================================== }

Const
  KVersion      = '0.1';
  BootInfo      = $00000500;
  E820Table     = $00000600;
  VideoBase     = $000B8000;
  ScrCols       = 80;
  ScrRows       = 25;
  Com1          = $3F8;

  { Selecteurs de la GDT }
  SelCode       = $08;
  SelData       = $10;

  { Fenetre des processus }
  ProcWinBase   = $00400000;
  ProcWinSize   = $00400000;
  ProcStackSize = $00040000;   { 256 Ko de pile par processus }
  PhysProcBase  = $01000000;   { memoire physique des processus (>= 16 Mo) }
  DllBase       = $00800000;   { region des DLL (8 Mo - 16 Mo), partagee }
  DllTop        = $01000000;
  ModFirstCap   = 16;          { table des modules : 16 entrees, doublee au besoin }
  DllAlign      = $00010000;   { placement des DLL relogees : 64 Ko }

  { Tas du noyau }
  HeapMagicUsed = $55534544;   { 'DESU' }
  HeapMagicFree = $45455246;   { 'FREE' }

  { Handles }
  HStdIn        = $10;
  HStdOut       = $11;
  HStdErr       = $12;
  HFileBase     = $100;
  HFindBase     = $200;
  HProcBase     = $300;
  MaxFiles      = 128;
  MaxFinds      = 64;
  MaxProcs      = 64;
  MaxTasks      = 128;         { taches (fils d'execution) ; la 0 est le noyau }
  MaxSess       = 16;          { sessions (ecran et clavier) }
  MaxPBlk       = 192;         { blocs de memoire physique des processus }
  HThreadBase   = $400;        { handles de fils (CreateProcessA) }
  ThreadStackMin = $00010000;  { pile minimale d'un fil (64 Ko) }
  MaxRamFiles   = 128;

  { Codes d'erreur (GetLastError, compatibles DOS/Win32) }
  ErrNone       = 0;
  ErrFileNotFound = 2;
  ErrPathNotFound = 3;
  ErrTooManyOpen  = 4;
  ErrAccessDenied = 5;
  ErrInvalidHandle = 6;
  ErrNotEnoughMem = 8;
  ErrBadFormat    = 11;
  ErrInvalidDrive = 15;
  ErrCurrentDir   = 16;
  ErrNoMoreFiles  = 18;
  ErrWriteProtect = 19;
  ErrNotReady     = 21;
  ErrFileExists   = 80;
  ErrInvalidParam = 87;
  ErrDirNotEmpty  = 145;
  ErrAlreadyExists = 183;

  FileAttrReadOnly  = $01;
  FileAttrHidden    = $02;
  FileAttrSystem    = $04;
  FileAttrDirectory = $10;
  FileAttrArchive   = $20;
  FileAttrNormal    = $80;

Type
  TGate = Record
    OfsLo  : Word;
    Sel    : Word;
    Flags  : Word;
    OfsHi  : Word;
  End;

  TDescPtr = Record
    Limit  : Word;
    Base   : LongInt;
  End;

  { Fichier ouvert }
  TOpenFile = Record
    Used     : Boolean;
    IsRam    : Boolean;      { fichier du disque virtuel }
    RamIdx   : LongInt;
    Lba      : LongInt;      { premier secteur ISO 9660 }
    Size     : LongInt;
    Pos      : LongInt;
    CanWrite : Boolean;
    IsNul    : Boolean;      { peripherique NUL }
    IsCon    : Boolean;      { peripherique CON }
    IsPrn    : Boolean;      { imprimante PRN, LPT1 a LPT3 }
    PrnIdx   : LongInt;      { 0 = LPT1 }
    Time     : LongInt;      { date et heure DOS }
    Owner    : LongInt;      { processus proprietaire }
    Name     : String[127];
    IsIfs    : Boolean;      { fichier d'un volume IFS (HPFS.IFS...) }
    IfsDrv   : LongInt;      { unite (3 = D:) }
    IsFlp    : Boolean;      { fichier de la disquette A: (Lba = 1er cluster) }
    Sffsi    : Array[0..63] Of Byte;   { SFT : partie du noyau }
    Sffsd    : Array[0..31] Of Byte;   { SFT : partie du pilote }
  End;

  { Recherche FindFirst/FindNext }
  TFind = Record
    Used     : Boolean;
    Dir      : String[127];  { repertoire (chemin complet) }
    Mask     : String[12];
    IsoIdx   : LongInt;      { position dans le repertoire ISO }
    RamIdx   : LongInt;      { position dans le disque virtuel }
    Owner    : LongInt;
    IsIfs    : Boolean;      { recherche sur un volume IFS }
    IfsDrv   : LongInt;
    IsFlp    : Boolean;      { recherche sur la disquette A: (IsoIdx : entree) }
    FlpClus  : LongInt;      { cluster du repertoire (0 : racine) }
    Fsfsi    : Array[0..7] Of Byte;
    Fsfsd    : Array[0..31] Of Byte;
  End;

  { Fichier ou repertoire du disque virtuel (cree en cours d'execution) }
  TRamFile = Record
    Used     : Boolean;
    Path     : String[127];  { chemin complet en majuscules, ex. C:\TMP\A.TXT }
    Attr     : LongInt;
    Data     : LongInt;      { adresse du contenu dans le tas }
    Size     : LongInt;
    Cap      : LongInt;
    Time     : LongInt;      { date et heure au format DOS }
    Deleted  : Boolean;      { masque un fichier du CD-ROM (suppression) }
  End;

  { Processus }
  TProcess = Record
    Used      : Boolean;
    Running   : Boolean;
    Parent    : LongInt;
    PhysBase  : LongInt;     { memoire physique de la fenetre }
    PhysSize  : LongInt;
    PageTable : LongInt;     { table des pages de la fenetre }
    ExitCode  : LongInt;
    SavedEsp  : LongInt;     { pile du parent (retour de ExitProcess) }
    Filter    : LongInt;     { SetUnhandledExceptionFilter }
    CmdBuf    : LongInt;     { ligne de commande ASCIIZ (GetCommandLineA) }
    PtAlloc   : LongInt;     { bloc du tas de la table des pages }
    ImageSize : LongInt;
    CmdLine   : String;
    Name      : String[63];
    Path      : String[127];
    Serial    : LongInt;     { identificateur de processus (PID) unique }
    StdOutH   : LongInt;     { sortie standard redirigee (0 : console) }
    CurDir    : String[127];
    MemLive   : Boolean;     { memoire physique pas encore rendue }
    HandleOpen : Boolean;    { handle du processus ouvert (code de sortie) }
    NoPreempt : Boolean;     { pas de preemption (programme de PM) }
    NextTid   : LongInt;     { prochain identificateur de fil }
    Sess      : LongInt;     { session (ecran et clavier) }
    ConSess   : LongInt;     { session de la console (sortie standard) }
    IsLx      : Boolean;     { programme LX d'OS/2 (partie 13c) }
    LxEip     : LongInt;     { point d'entree }
    LxTib     : LongInt;     { bloc d'information de tache (FS:0) }
    LxFs      : LongInt;     { selecteur de FS }
  End;

Var
  { Console }
  CurRow, CurCol   : LongInt;
  ConRows          : LongInt;       { lignes de la console (les lignes du bas
                                      peuvent etre reservees, ex. FKA.DLL) }
  ConRowsOwner     : LongInt;       { processus qui a reduit la console }
  TextAttr         : LongInt;
  SerialOk         : Boolean;
  SerialMute       : Boolean;       { pas de copie serie (edition de ligne) }

  { Processeur }
  Gdt              : Array[0..19] Of LongInt;
  GdtPtr           : TDescPtr;
  Idt              : Array[0..255] Of TGate;
  IdtPtr           : TDescPtr;
  TrapFrame        : LongInt;

  { Minuterie }
  Ticks            : LongInt;

  { Clavier }
  KbdBuf           : Array[0..63] Of LongInt;   { (scan shl 8) or ascii }
  KbdHead, KbdTail : LongInt;
  KbdXt, KbdTm     : Array[0..63] Of LongInt;   { etat et heure (ms) }
  KbdState         : LongInt;       { etat des touches (fsState d'OS/2) }
  KbdMode          : LongInt;       { 1 changements d'etat, 2 relachements }
  KbdE1            : LongInt;
  KbdMonOn         : Boolean;       { moniteurs KBD$ actifs (MONCALLS.DLL) }
  KbdMonPid        : LongInt;
  MonKV, MonKX, MonKT : Array[0..63] Of LongInt;   { frappes pour les moniteurs }
  MonKHead, MonKTail : LongInt;
  KbdShift, KbdCtrl, KbdAlt, KbdCaps, KbdNum, KbdE0 : Boolean;
  History          : Array[0..15] Of String[127];
  HistCount        : LongInt;
  LineBuf          : String;
  LinePos          : LongInt;       { prochain caractere a rendre par ReadFile }
  LineReady        : Boolean;

  { Memoire }
  HeapStart, HeapEnd : LongInt;
  MemTotalKb       : LongInt;
  PhysTop          : LongInt;

  { Pagination }
  PageDir          : LongInt;
  PagingOn         : Boolean;

  { ATAPI }
  AtaBase, AtaCtrl : LongInt;
  AtaSlave         : Boolean;
  AtaFound         : Boolean;
  SectBuf          : Array[0..2047] Of Byte;
  SectBufLba       : LongInt;
  UseBiosCache     : Boolean;

  { ISO 9660 }
  RootLba, RootSize : LongInt;

  { Fichiers, recherches, disque virtuel }
  Files            : Array[0..MaxFiles - 1] Of TOpenFile;
  Finds            : Array[0..MaxFinds - 1] Of TFind;
  RamFiles         : Array[0..MaxRamFiles - 1] Of TRamFile;
  LastError        : LongInt;

  { Processus }
  Procs            : Array[0..MaxProcs - 1] Of TProcess;
  CurProc          : LongInt;       { -1 = noyau }
  KernelDir        : String[127];
  EnvBlock         : Array[0..2047] Of Byte;  { NOM=VALEUR#0...#0#0 }
  EnvSize          : LongInt;
  ShellPath        : String[127];
  KCmdLine         : Array[0..255] Of Byte;
  ExcFilter        : LongInt;
  LibPath          : String;        { LIBPATH= de CONFIG.SYS }
  NextSerial       : LongInt;       { prochain PID }

  { Taches (multitache) : la tache 0 est le noyau ; chaque processus a son
    fil 1 et ses fils crees par KrnTaskCtl }
  TkUsed           : Array[0..MaxTasks - 1] Of LongInt;   { 0 libre, 1 active, 2 morte }
  TkProc, TkEsp, TkStack, TkLastErr, TkTid, TkFn, TkArg : Array[0..MaxTasks - 1] Of LongInt;
  CurTask, NTasks, IdleStreak, SliceStart, SwSave, SwNew, TmpIntEbp : LongInt;
  SwPde            : LongInt;       { entree 0 du repertoire de la tache reprise }
  SessNoPde        : Boolean;       { SessSwap sans changer l'entree 0 }
  TkEsp0           : Array[0..MaxTasks - 1] Of LongInt;  { pile de l'anneau 0 (TSS) }
  TkFs             : Array[0..MaxTasks - 1] Of LongInt;  { selecteur FS (TIB des programmes LX) }
  FsTmp            : LongInt;
  Tss              : Array[0..31] Of LongInt;            { TSS du processeur (InitTss) }
  TssBase          : LongInt;
  { machine virtuelle DOS (partie 13b) : en cours, sa tache, sa session,
    son processus, son premier Mo (memoire physique) }
  VmOn             : Boolean;
  VmTask, VmSess, VmPid, VmRamPhys : LongInt;
  { memoire physique des processus : blocs tries par adresse }
  PBase, PSize     : Array[0..MaxPBlk - 1] Of LongInt;
  PCount           : LongInt;

  { Sessions : chaque session a son ecran (tampon video logique de 32 Ko,
    projete en 000B8000h quand elle n'est pas au premier plan), sa
    console et sa file du clavier }
  SUsed, SNew, SPause, SPrompt : Array[0..MaxSess - 1] Of Boolean;
  SPT, SLvb, SMode, SRet : Array[0..MaxSess - 1] Of LongInt;
  SCurRow, SCurCol, SAttr, SConRows, SConOwn, SKbdMode, SKbdHead, SKbdTail, SLinePos : Array[0..MaxSess - 1] Of LongInt;
  SLineReady       : Array[0..MaxSess - 1] Of Boolean;
  SLineBuf         : Array[0..MaxSess - 1] Of String;
  STitle           : Array[0..MaxSess - 1] Of String[47];
  SKbdBuf, SKbdXt, SKbdTm : Array[0..MaxSess * 64 - 1] Of LongInt;
  SesFlags         : Array[0..7] Of LongInt;   { lus par les DLL (KrnSesCtl 15) }
  FgSess, CurSess, Epoch, Switching, PmSess, PendSwitch, NextSess, SwHook : LongInt;
  KernPT, GfxScratch : LongInt;
  PauseMsg         : String;

{ ==================================================================== }
{ Partie 2 - Utilitaires                                               }
{ ==================================================================== }

{ Copier N octets de Src a Dst (adresses lineaires) }
Procedure MoveMem(Src, Dst, N : LongInt);
Begin
  If N <= 0 Then Exit;
  asm
    push esi
    push edi
    mov esi,Src
    mov edi,Dst
    mov ecx,N
    cld
    cmp esi,edi
    jae @fwd
    add esi,ecx
    add edi,ecx
    dec esi
    dec edi
    std
    rep movsb
    cld
    jmp @done
  @fwd:
    rep movsb
  @done:
    pop edi
    pop esi
  end;
End;

{ Remplir N octets a partir de Dst avec la valeur B }
Procedure FillMem(Dst, N, B : LongInt);
Begin
  If N <= 0 Then Exit;
  asm
    push edi
    mov edi,Dst
    mov ecx,N
    mov eax,B
    cld
    rep stosb
    pop edi
  end;
End;

{ Chaine ASCIIZ (adresse lineaire) -> chaine Pascal }
Function PStr(A : LongInt) : String;
Var S : String; N : LongInt; C : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    C := Mem[0:A];
    While (C <> 0) And (N < 255) Do
    Begin
      S := S + Chr(C);
      Inc(N);
      C := Mem[0:A + N];
    End;
  End;
  PStr := S;
End;

{ Chaine Pascal -> ASCIIZ a l'adresse A (au plus Max octets, zero compris) }
Procedure PutPStr(A : LongInt; S : String; Max : LongInt);
Var I, L : LongInt;
Begin
  L := Length(S);
  If L > Max - 1 Then L := Max - 1;
  For I := 1 To L Do Mem[0:A + I - 1] := Ord(S[I]);
  Mem[0:A + L] := 0;
End;

Function UpStr(S : String) : String;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do
    If (S[I] >= 'a') And (S[I] <= 'z') Then S[I] := Chr(Ord(S[I]) - 32);
  UpStr := S;
End;

Function IntStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IntStr := S;
End;

Function HexStr(V : LongInt; Digits : LongInt) : String;
Const Hx : String[16] = '0123456789ABCDEF';
Var S : String; I : LongInt;
Begin
  S := '';
  For I := 1 To Digits Do
  Begin
    S := Hx[(V And 15) + 1] + S;
    V := V Shr 4;
  End;
  HexStr := S;
End;

Function Trim(S : String) : String;
Begin
  While (Length(S) > 0) And (S[1] = ' ') Do Delete(S, 1, 1);
  While (Length(S) > 0) And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
  Trim := S;
End;

{ ==================================================================== }
{ Partie 3 - Console VGA texte et port serie COM1                      }
{ ==================================================================== }

Procedure SerialInit;
Begin
  Port[Com1 + 1] := $00;          { pas d'interruption }
  Port[Com1 + 3] := $80;          { DLAB }
  Port[Com1 + 0] := $01;          { 115200 bauds }
  Port[Com1 + 1] := $00;
  Port[Com1 + 3] := $03;          { 8N1 }
  Port[Com1 + 2] := $C7;          { FIFO }
  Port[Com1 + 4] := $03;
  SerialOk := Port[Com1 + 5] <> $FF;
End;

Procedure SerialPut(C : Char);
Var N : LongInt;
Begin
  If (Not SerialOk) Or SerialMute Then Exit;
  N := 0;
  While ((Port[Com1 + 5] And $20) = 0) And (N < 100000) Do Inc(N);
  Port[Com1] := Ord(C);
End;

{ etat des sessions publie pour les DLL : 0 premier plan, 1 session
  courante, 2 compteur des bascules, 3 bascule en cours, 4 session PM }
Procedure SyncFlags;
Begin
  SesFlags[0] := FgSess; SesFlags[1] := CurSess; SesFlags[2] := Epoch;
  SesFlags[3] := Switching; SesFlags[4] := PmSess;
End;

Procedure UpdateCursor;
Var P : LongInt;
Begin
  If (CurSess <> FgSess) And (Switching = 0) Then Exit;
  P := CurRow * ScrCols + CurCol;
  Port[$3D4] := $0F; Port[$3D5] := P And $FF;
  Port[$3D4] := $0E; Port[$3D5] := (P Shr 8) And $FF;
End;

Procedure ScrollUp;
Var I : LongInt;
Begin
  MoveMem(VideoBase + ScrCols * 2, VideoBase, ScrCols * (ConRows - 1) * 2);
  For I := 0 To ScrCols - 1 Do
    MemW[0:VideoBase + ((ConRows - 1) * ScrCols + I) * 2] := (TextAttr Shl 8) Or $20;
End;

Procedure ClearScreen;
Var I : LongInt;
Begin
  For I := 0 To ScrCols * ConRows - 1 Do
    MemW[0:VideoBase + I * 2] := (TextAttr Shl 8) Or $20;
  CurRow := 0; CurCol := 0;
  UpdateCursor;
End;

Procedure Beep(Freq, Dur : LongInt); Forward;

{ Afficher un caractere (sans mise a jour du curseur materiel) }
Procedure ConPutRaw(C : Char);
Begin
  SerialPut(C);
  Case C Of
    #13 : CurCol := 0;
    #10 : Inc(CurRow);
    #8  : If CurCol > 0 Then Dec(CurCol);
    #9  : CurCol := (CurCol + 8) And Not 7;
    #7  : Beep(800, 100);
  Else
    Begin
      MemW[0:VideoBase + (CurRow * ScrCols + CurCol) * 2] := (TextAttr Shl 8) Or Ord(C);
      Inc(CurCol);
    End;
  End;
  If CurCol >= ScrCols Then
  Begin
    CurCol := 0;
    Inc(CurRow);
  End;
  If CurRow >= ConRows Then
  Begin
    ScrollUp;
    CurRow := ConRows - 1;
  End;
End;

Procedure ConPutC(C : Char);
Begin
  ConPutRaw(C);
  UpdateCursor;
End;

Procedure ConPutS(S : String);
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do ConPutRaw(S[I]);
  UpdateCursor;
End;

Procedure ConPutLn(S : String);
Begin
  ConPutS(S + #13#10);
End;

{ Journal du noyau : console et port serie }
Procedure KLog(S : String);
Begin
  ConPutLn(S);
End;

{ ==================================================================== }
{ Partie 4 - Processeur : GDT, IDT, exceptions, PIC                    }
{ ==================================================================== }

Procedure SetGate(N, Addr : LongInt);
Begin
  Idt[N].OfsLo := Addr And $FFFF;
  Idt[N].Sel := SelCode;
  Idt[N].Flags := $8E00;          { porte d'interruption 32 bits, DPL 0 }
  Idt[N].OfsHi := (Addr Shr 16) And $FFFF;
End;

Procedure InitGdt;
Begin
  Gdt[0] := 0;          Gdt[1] := 0;
  Gdt[2] := $0000FFFF;  Gdt[3] := $00CF9A00;    { 08h code 32 bits }
  Gdt[4] := $0000FFFF;  Gdt[5] := $00CF9200;    { 10h donnees 32 bits }
  Gdt[6] := $0000FFFF;  Gdt[7] := $00CF9200;    { 18h donnees 32 bits }
  Gdt[8] := 0;          Gdt[9] := 0;
  Gdt[10] := 0;         Gdt[11] := 0;           { 28h TSS (InitTss) }
  Gdt[12] := 0;         Gdt[13] := 0;           { 30h LDT (InitTss) }
  Gdt[14] := 0;         Gdt[15] := 0;
  Gdt[16] := $0400FFFF; Gdt[17] := $0000F200;   { 40h donnees du BIOS, anneau 3 (DPMI) }
  Gdt[18] := 0;         Gdt[19] := 0;
  GdtPtr.Limit := 10 * 8 - 1;
  GdtPtr.Base := LongInt(@Gdt);
  asm
    lgdt GdtPtr
    mov ax,10h
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
  end;
End;

Procedure KillCurrentProcess(Code : LongInt); Forward;

Var
  ExcRec    : Array[0..19] Of LongInt;   { EXCEPTION_RECORD }
  ExcPtrs   : Array[0..1] Of LongInt;    { EXCEPTION_POINTERS }
  FilterAdr : LongInt;
  FilterArg : LongInt;

Const
  ExcNames : Array[0..19] Of String[40] = (
    'Division par zero', 'Debogage', 'NMI', 'Point d''arret',
    'Debordement', 'Hors limites', 'Code operation invalide',
    'Coprocesseur absent', 'Double faute', 'Depassement coprocesseur',
    'TSS invalide', 'Segment absent', 'Faute de pile',
    'Protection generale', 'Faute de page', 'Reserve',
    'Erreur virgule flottante', 'Alignement', 'Verification machine',
    'Exception SIMD');

{ Ecran TRAP (a la maniere d'OS/2) puis fin du processus fautif ou arret.
  Frame : valeur de EBP de la procedure Interrupt (PUSHAD en EBP+4). }
Procedure Trap(Vec : LongInt; HasErr : Boolean);
Var F, Eip, Err, FaultAdr : LongInt; Nm : String;
Begin
  asm
    mov eax,[ebp]
    mov F,eax
    mov eax,cr2
    mov FaultAdr,eax
  end;
  { DS et ES sauves apres PUSHAD (procedures Interrupt du noyau) }
  F := F + 8;
  If HasErr Then
  Begin
    Err := MemL[0:F + 36];
    Eip := MemL[0:F + 40];
  End
  Else
  Begin
    Err := 0;
    Eip := MemL[0:F + 36];
  End;
  If Vec <= 19 Then Nm := ExcNames[Vec] Else Nm := 'Exception';
  { un programme OS2PC installe un filtre (SetUnhandledExceptionFilter) qui
    affiche "Runtime error N at ..." et termine le processus }
  If (CurProc >= 0) And (Procs[CurProc].Filter <> 0) Then
  Begin
    Case Vec Of
      0  : ExcRec[0] := LongInt($C0000094);
      4  : ExcRec[0] := LongInt($C0000095);
      6  : ExcRec[0] := LongInt($C000001D);
      16 : ExcRec[0] := LongInt($C0000090);
    Else
      ExcRec[0] := LongInt($C0000005);
    End;
    ExcRec[1] := 0; ExcRec[2] := 0; ExcRec[3] := Eip;
    ExcPtrs[0] := LongInt(@ExcRec); ExcPtrs[1] := 0;
    FilterAdr := Procs[CurProc].Filter;
    Procs[CurProc].Filter := 0;
    FilterArg := LongInt(@ExcPtrs);
    asm
      mov eax,FilterArg
      push eax
      mov eax,FilterAdr
      call eax
    end;
  End;
  TextAttr := $1F;
  ConPutLn('');
  If CurProc >= 0 Then
  Begin
    ConPutLn('SYS3175: Le processus ' + Procs[CurProc].Name +
             ' a provoque une exception et a ete arrete.');
  End
  Else
    ConPutLn('Le systeme a detecte une erreur interne et a ete arrete.');
  ConPutLn('TRAP ' + HexStr(Vec, 4) + ' (' + Nm + ')  ERRCD=' + HexStr(Err, 4) +
           '  EIP=' + HexStr(Eip, 8) + '  CR2=' + HexStr(FaultAdr, 8));
  ConPutLn('EAX=' + HexStr(MemL[0:F + 32], 8) + ' EBX=' + HexStr(MemL[0:F + 20], 8) +
           ' ECX=' + HexStr(MemL[0:F + 28], 8) + ' EDX=' + HexStr(MemL[0:F + 24], 8));
  ConPutLn('ESI=' + HexStr(MemL[0:F + 8], 8) + ' EDI=' + HexStr(MemL[0:F + 4], 8) +
           ' EBP=' + HexStr(MemL[0:F], 8) + ' ESP=' + HexStr(F + 36, 8));
  TextAttr := $07;
  If CurProc >= 0 Then
    KillCurrentProcess(-1);
  ConPutLn('Redemarrez l''ordinateur.');
  asm
    cli
  @h:
    hlt
    jmp @h
  end;
End;

Procedure Exc00; Interrupt; Begin Trap(0, False) End;
Procedure Exc01; Interrupt; Begin Trap(1, False) End;
Procedure Exc02; Interrupt; Begin Trap(2, False) End;
Procedure Exc03; Interrupt; Begin Trap(3, False) End;
Procedure Exc04; Interrupt; Begin Trap(4, False) End;
Procedure Exc05; Interrupt; Begin Trap(5, False) End;
Procedure Exc06; Interrupt; Begin Trap(6, False) End;
Procedure Exc07; Interrupt; Begin Trap(7, False) End;
Procedure Exc08; Interrupt; Begin Trap(8, True) End;
Procedure Exc09; Interrupt; Begin Trap(9, False) End;
Procedure Exc0A; Interrupt; Begin Trap(10, True) End;
Procedure Exc0B; Interrupt; Begin Trap(11, True) End;
Procedure Exc0C; Interrupt; Begin Trap(12, True) End;
Procedure Exc0D; Interrupt; Begin Trap(13, True) End;
Procedure Exc0E; Interrupt; Begin Trap(14, True) End;
Procedure Exc10; Interrupt; Begin Trap(16, False) End;
Procedure Exc11; Interrupt; Begin Trap(17, True) End;
Procedure Exc12; Interrupt; Begin Trap(18, False) End;
Procedure Exc13; Interrupt; Begin Trap(19, False) End;
Procedure ExcOther; Interrupt; Begin Trap(255, False) End;

{ Programmer les deux 8259A : IRQ 0-7 -> 20h-27h, IRQ 8-15 -> 28h-2Fh }
Procedure InitPic;
Begin
  Port[$20] := $11; Port[$A0] := $11;
  Port[$21] := $20; Port[$A1] := $28;
  Port[$21] := $04; Port[$A1] := $02;
  Port[$21] := $01; Port[$A1] := $01;
  { IRQ 0 (minuterie), 1 (clavier) et 2 (cascade) seulement }
  Port[$21] := $F8; Port[$A1] := $FF;
End;

Procedure IrqMaster; Interrupt;
Begin
  Port[$20] := $20;
End;

Procedure IrqSlave; Interrupt;
Begin
  Port[$A0] := $20;
  Port[$20] := $20;
End;

Procedure IrqTimer; Interrupt; Forward;
Procedure IrqKeyboard; Interrupt; Forward;
{ machine virtuelle DOS (partie 13b) }
Procedure DosKeyIn(Up : Boolean; Sc : LongInt; Ext : Boolean; Ch : LongInt); Forward;
Procedure DosMouIn(Dx, Dy, Btn : LongInt); Forward;
Procedure VmTick(B : LongInt); Forward;
Procedure VmSwitchOut; Forward;
Procedure VmSwitchIn; Forward;
Procedure DosStop; Forward;
Function IsDosFile(Path : String) : Boolean; Forward;
Function LoadDosProgram(Path, CmdLine : String) : LongInt; Forward;
{ chargeur LX (partie 13c) }
Function LxHeader(Buf, Size : LongInt) : LongInt; Forward;
Function LxLoadDll(Path : String; Buf, Size, M : LongInt) : Boolean; Forward;
Function LxLoadExe(Path, CmdLine : String; Buf, Size : LongInt) : LongInt; Forward;
Function LxLastErr : String; Forward;
Procedure SelFree(Sel, N : LongInt); Forward;

Procedure InitIdt;
Var I : LongInt;
Begin
  For I := 0 To 255 Do SetGate(I, LongInt(@ExcOther));
  SetGate(0, LongInt(@Exc00));  SetGate(1, LongInt(@Exc01));
  SetGate(2, LongInt(@Exc02));  SetGate(3, LongInt(@Exc03));
  SetGate(4, LongInt(@Exc04));  SetGate(5, LongInt(@Exc05));
  SetGate(6, LongInt(@Exc06));  SetGate(7, LongInt(@Exc07));
  SetGate(8, LongInt(@Exc08));  SetGate(9, LongInt(@Exc09));
  SetGate(10, LongInt(@Exc0A)); SetGate(11, LongInt(@Exc0B));
  SetGate(12, LongInt(@Exc0C)); SetGate(13, LongInt(@Exc0D));
  SetGate(14, LongInt(@Exc0E)); SetGate(16, LongInt(@Exc10));
  SetGate(17, LongInt(@Exc11)); SetGate(18, LongInt(@Exc12));
  SetGate(19, LongInt(@Exc13));
  For I := $20 To $27 Do SetGate(I, LongInt(@IrqMaster));
  For I := $28 To $2F Do SetGate(I, LongInt(@IrqSlave));
  SetGate($20, LongInt(@IrqTimer));
  SetGate($21, LongInt(@IrqKeyboard));
  IdtPtr.Limit := 256 * 8 - 1;
  IdtPtr.Base := LongInt(@Idt);
  asm
    lidt IdtPtr
  end;
End;

{ ==================================================================== }
{ Partie 5 - Minuterie, horloge temps reel, haut-parleur               }
{ ==================================================================== }

Procedure Preempt; Forward;
Procedure Yield; Forward;

{ Minuterie : a la fin de la tranche (30 ms), une tache interrompue dans le
  code de son programme (fenetre 00400000h-007FFFFFh) cede la place ; le
  noyau et les DLL ne sont jamais interrompus (donnees globales). }
Procedure IrqTimer;
Begin
  Inc(Ticks);
  Port[$20] := $20;
  IdleStreak := 0;
  asm
    mov eax,ebp
    mov TmpIntEbp,eax
  end;
  { code 16 bits de la machine virtuelle DOS (mode V86) ou de son client
    DPMI (anneau 3) : interruptions virtuelles, puis partage du temps }
  If VmOn And (CurTask = VmTask) And (((MemL[0:TmpIntEbp + 52] And $20000) <> 0) Or
     ((MemL[0:TmpIntEbp + 48] And 3) = 3)) Then
  Begin
    VmTick(TmpIntEbp + 12);
    If (NTasks > 1) And (Ticks - SliceStart >= 3) Then Preempt;
    Exit;
  End;
  If (NTasks > 1) And (CurTask > 0) And (Ticks - SliceStart >= 3) Then
  Begin
    If (MemL[0:TmpIntEbp + 44] >= ProcWinBase) And (MemL[0:TmpIntEbp + 44] < ProcWinBase + ProcWinSize) Then
      Preempt;
  End;
End;

{ PIT canal 0 a 100 Hz }
Procedure InitTimer;
Begin
  Port[$43] := $36;
  Port[$40] := 11932 And $FF;
  Port[$40] := 11932 Shr 8;
End;

{ Attente : les autres taches s'executent ; quand toutes attendent depuis
  la derniere interruption, le processeur s'arrete jusqu'a la suivante }
Procedure Idle;
Begin
  If NTasks > 1 Then
  Begin
    Inc(IdleStreak);
    If IdleStreak > NTasks * 2 Then
    Begin
      IdleStreak := 0;
      asm
        sti
        hlt
      end;
    End
    Else Yield;
  End
  Else
    asm
      sti
      hlt
    end;
End;

{ Attendre Ms millisecondes }
Procedure KDelay(Ms : LongInt);
Var Target : LongInt;
Begin
  Target := Ticks + (Ms + 9) Div 10;
  While Ticks < Target Do Idle;
End;

Procedure Beep(Freq, Dur : LongInt);
Var D, B : LongInt;
Begin
  If Freq < 37 Then Freq := 37;
  D := 1193180 Div Freq;
  Port[$43] := $B6;
  Port[$42] := D And $FF;
  Port[$42] := (D Shr 8) And $FF;
  B := Port[$61];
  Port[$61] := B Or 3;
  KDelay(Dur);
  Port[$61] := B And $FC;
End;

Function CmosRead(R : LongInt) : LongInt;
Begin
  Port[$70] := R;
  CmosRead := Port[$71];
End;

Function Bcd(V : LongInt) : LongInt;
Begin
  If (CmosRead($0B) And 4) <> 0 Then Bcd := V
  Else Bcd := (V Shr 4) * 10 + (V And 15);
End;

Var
  RtcYear, RtcMonth, RtcDay, RtcHour, RtcMin, RtcSec, RtcDow : LongInt;

Procedure ReadRtc;
Var N : LongInt;
Begin
  N := 0;
  While ((CmosRead($0A) And $80) <> 0) And (N < 100000) Do Inc(N);
  RtcSec := Bcd(CmosRead($00));
  RtcMin := Bcd(CmosRead($02));
  RtcHour := Bcd(CmosRead($04) And $7F);
  RtcDay := Bcd(CmosRead($07));
  RtcMonth := Bcd(CmosRead($08));
  RtcYear := Bcd(CmosRead($09)) + 2000;
  RtcDow := Bcd(CmosRead($06)) - 1;
  If (RtcDow < 0) Or (RtcDow > 6) Then RtcDow := 0;
End;

{ Date et heure au format DOS (date shl 16 or heure) }
Function DosNow : LongInt;
Begin
  ReadRtc;
  DosNow := (((RtcYear - 1980) Shl 9) Or (RtcMonth Shl 5) Or RtcDay) Shl 16 Or
            ((RtcHour Shl 11) Or (RtcMin Shl 5) Or (RtcSec Div 2));
End;

{ ==================================================================== }
{ Partie 6 - Clavier et editeur de ligne de commande                   }
{ ==================================================================== }

Const
  { table scancode -> ASCII (jeu 1, clavier americain). Les touches sans
    caractere sont notees X (minuscules) ou x (majuscules) ; Echap, Retour
    arriere, Tab et Entree sont traitees a part. }
  KeyLow  = 'XX1234567890-=XXqwertyuiop[]XXasdfghjkl;''`X\zxcvbnm,./X*X ';
  KeyHigh = 'xx!@#$%^&*()_+xxQWERTYUIOP{}xxASDFGHJKL:"~x|ZXCVBNM<>?x*x ';

Var
  KeyLowV, KeyHighV : String;   { copies des tables (indexation fiable) }

{ Etat des touches au format fsState d'OS/2 (KBDCALLS.DLL) :
  0001h Maj droite, 0002h Maj gauche, 0004h Ctrl, 0008h Alt,
  0010h/0020h/0040h/0080h Arret defil/Verr num/Verr maj/Inser actifs,
  0100h Ctrl gauche, 0200h Alt gauche, 0400h Ctrl droite, 0800h Alt
  droite, 1000h/2000h/4000h Arret defil/Verr num/Verr maj enfoncees,
  8000h Syst. }
Procedure KbdSyncFlags;
Begin
  KbdShift := (KbdState And $0003) <> 0;
  KbdCtrl := (KbdState And $0004) <> 0;
  KbdAlt := (KbdState And $0008) <> 0;
  KbdNum := (KbdState And $0020) <> 0;
  KbdCaps := (KbdState And $0040) <> 0;
End;

{ Ranger une touche ; Xt : etat des touches (bits 0 a 15), 10000h
  prefixe E0h, 20000h touche relachee, 40000h changement d'etat seul }
Function KbdPushRaw(V, Xt, Tm : LongInt) : Boolean;
Var N, B : LongInt;
Begin
  KbdPushRaw := False;
  If FgSess <> CurSess Then
  Begin
    { la session au premier plan n'est pas celle de la tache courante :
      file sauvee de la session }
    B := FgSess * 64;
    N := (SKbdHead[FgSess] + 1) And 63;
    If N = SKbdTail[FgSess] Then Exit;
    SKbdBuf[B + SKbdHead[FgSess]] := V;
    SKbdXt[B + SKbdHead[FgSess]] := Xt;
    SKbdTm[B + SKbdHead[FgSess]] := Tm;
    SKbdHead[FgSess] := N;
    KbdPushRaw := True;
    Exit;
  End;
  N := (KbdHead + 1) And 63;
  If N = KbdTail Then Exit;      { tampon plein }
  KbdBuf[KbdHead] := V;
  KbdXt[KbdHead] := Xt;
  KbdTm[KbdHead] := Tm;
  KbdHead := N;
  KbdPushRaw := True;
End;

{ Avec des moniteurs KBD$ (MONCALLS.DLL), la frappe va d'abord a la
  chaine de moniteurs, qui la rend au tampon (KrnMonIo) ; 80000h :
  touche deja traduite (caractere et code rendus par les moniteurs,
  fbStatus dans les bits 24 a 31) }
Procedure KbdPushX(V, Xt : LongInt);
Var N : LongInt; D : Boolean;
Begin
  If KbdMonOn Then
  Begin
    N := (MonKTail + 1) And 63;
    If N = MonKHead Then Exit;
    MonKV[MonKTail] := V;
    MonKX[MonKTail] := Xt;
    MonKT[MonKTail] := Ticks * 10;
    MonKTail := N;
  End
  Else
    D := KbdPushRaw(V, Xt, Ticks * 10);
End;

Procedure KbdPush(V : LongInt);
Begin
  KbdPushX(V, KbdState);
End;

Procedure KbdSetBit(B : LongInt; On : Boolean);
Begin
  If On Then KbdState := KbdState Or B
  Else KbdState := KbdState And Not B;
End;

{ Voyants du clavier d'apres les verrouillages }
Procedure KbdLeds;
Var N, L : LongInt;
Begin
  L := 0;
  If (KbdState And $10) <> 0 Then L := L Or 1;
  If (KbdState And $20) <> 0 Then L := L Or 2;
  If (KbdState And $40) <> 0 Then L := L Or 4;
  N := 0;
  While ((Port[$64] And 2) <> 0) And (N < 100000) Do Inc(N);
  Port[$60] := $ED;
  N := 0;
  While ((Port[$64] And 2) <> 0) And (N < 100000) Do Inc(N);
  Port[$60] := L;
End;

{ session suivante pour Alt+Echap : sessions qui ont un processus, et la
  session de Presentation Manager }
Function NextSessOf(S : LongInt) : LongInt;
Var I, T, P : LongInt; Ok : Boolean;
Begin
  NextSessOf := S;
  For I := 1 To MaxSess Do
  Begin
    T := (S + I) Mod MaxSess;
    If SUsed[T] Then
    Begin
      Ok := T = PmSess;
      For P := 0 To MaxProcs - 1 Do
        If Procs[P].Used And Procs[P].Running And (Procs[P].Sess = T) Then Ok := True;
      If Ok Then
      Begin
        NextSessOf := T;
        Exit;
      End;
    End;
  End;
End;

{ caractere d'une touche enfoncee (comme ci-dessous ; session DOS) }
Function VmKeyChar(Sc : LongInt) : LongInt;
Var Ch : LongInt;
Begin
  Ch := 0;
  If KbdE0 Then
  Begin
    If Sc = $1C Then Ch := 13
    Else If Sc = $35 Then Ch := Ord('/');
  End
  Else If Sc < 58 Then
  Begin
    If KbdShift Then
    Begin
      Ch := Ord(KeyHighV[Sc + 1]);
      If Ch = Ord('x') Then Ch := 0;
    End
    Else
    Begin
      Ch := Ord(KeyLowV[Sc + 1]);
      If Ch = Ord('X') Then Ch := 0;
    End;
    Case Sc Of
      $01 : Ch := 27;
      $0E : Ch := 8;
      $0F : Ch := 9;
      $1C : Ch := 13;
    End;
    If KbdCaps And (Chr(Ch) In ['a'..'z']) Then Ch := Ch - 32
    Else If KbdCaps And (Chr(Ch) In ['A'..'Z']) Then Ch := Ch + 32;
    If KbdCtrl And (Chr(Ch) In ['a'..'z']) Then Ch := Ch - 96
    Else If KbdCtrl And (Chr(Ch) In ['A'..'Z']) Then Ch := Ch - 64;
    If KbdAlt Then Ch := 0;
  End;
  VmKeyChar := Ch;
End;

Procedure IrqKeyboard;
Var Sc, Ch, Up, Old, Ext, B : LongInt; Toggle : Boolean;
Begin
  Sc := Port[$60];
  If Sc = $E0 Then
  Begin
    KbdE0 := True;
    Port[$20] := $20;
    Exit;
  End;
  If Sc = $E1 Then
  Begin
    KbdE1 := 2;                  { Pause : E1 1D 45 E1 9D C5 }
    Port[$20] := $20;
    Exit;
  End;
  If (Sc = $FA) Or (Sc = $FE) Or (KbdE1 > 0) Then
  Begin
    { accuse de reception (voyants) ou suite de Pause }
    If KbdE1 > 0 Then
    Begin
      Dec(KbdE1);
      If (KbdE1 = 0) And (Sc = $45) Then KbdPushX($4500, KbdState Or $10000);
    End;
    KbdE0 := False;
    Port[$20] := $20;
    Exit;
  End;
  Up := Sc And $80;
  Sc := Sc And $7F;
  Ext := 0;
  If KbdE0 Then Ext := $10000;
  Old := KbdState;
  Toggle := False;
  B := 0;
  If KbdE0 And ((Sc = $2A) Or (Sc = $36)) Then
    Sc := 0                      { fausses touches Maj (Impr. ecran...) }
  Else
    Case Sc Of
      $2A : KbdSetBit($0002, Up = 0);
      $36 : KbdSetBit($0001, Up = 0);
      $1D : Begin
              If KbdE0 Then KbdSetBit($0400, Up = 0) Else KbdSetBit($0100, Up = 0);
              KbdSetBit($0004, (KbdState And $0500) <> 0);
            End;
      $38 : Begin
              If KbdE0 Then KbdSetBit($0800, Up = 0) Else KbdSetBit($0200, Up = 0);
              KbdSetBit($0008, (KbdState And $0A00) <> 0);
            End;
      $3A : B := $40;
      $45 : B := $20;
      $46 : If Not KbdE0 Then B := $10;
      $54 : KbdSetBit($8000, Up = 0);
    End;
  If B <> 0 Then
  Begin
    { touche de verrouillage : bascule a l'enfoncement (sans la
      repetition automatique) }
    If Up = 0 Then
    Begin
      If (KbdState And (B Shl 8)) = 0 Then
      Begin
        KbdState := KbdState Xor B;
        Toggle := True;
      End;
      KbdState := KbdState Or (B Shl 8);
    End
    Else
      KbdState := KbdState And Not (B Shl 8);
  End;
  KbdSyncFlags;
  { Ctrl+Alt+Suppr : redemarrage (impulsion de remise a zero du
    controleur du clavier) }
  If (Up = 0) And (Sc = $53) And ((KbdState And $000C) = $000C) Then Port[$64] := $FE;
  { Alt+Echap : session suivante ; Ctrl+Echap (hors de PM) : retour a
    Presentation Manager }
  If (Up = 0) And (Sc = $01) And Not KbdE0 And ((KbdState And $000C) <> 0) Then
    If ((KbdState And $0008) <> 0) Or ((PmSess >= 0) And (FgSess <> PmSess)) Then
    Begin
      If (KbdState And $0008) <> 0 Then PendSwitch := NextSessOf(FgSess) Else PendSwitch := PmSess;
      KbdE0 := False;
      Port[$20] := $20;
      Exit;
    End;
  { session DOS au premier plan : codes de balayage vers la machine }
  If VmOn And (FgSess = VmSess) Then
  Begin
    If (Sc <> 0) And ((KbdState <> Old) Or (Up <> 0) Or (Sc = $54)) Then
      DosKeyIn(Up <> 0, Sc, KbdE0, 0)
    Else If (Sc <> 0) And (Up = 0) Then
    Begin
      If (Sc = $52) And (KbdE0 Or Not KbdNum Or KbdShift) Then KbdState := KbdState Xor $0080;
      DosKeyIn(False, Sc, KbdE0, VmKeyChar(Sc));
    End;
    If Toggle Then KbdLeds;
    KbdE0 := False;
    Port[$20] := $20;
    Exit;
  End;
  If (Sc = 0) Or (KbdState <> Old) Or (Sc = $54) Then
  Begin
    { touche d'etat : signalee seulement en mode de rapport }
    If (Sc <> 0) And (KbdState <> Old) And (((KbdMode And 1) <> 0) Or KbdMonOn) Then
    Begin
      If Up <> 0 Then KbdPushX(Sc Shl 8, KbdState Or Ext Or $60000)
      Else KbdPushX(Sc Shl 8, KbdState Or Ext Or $40000);
    End;
    If Toggle Then KbdLeds;
  End
  Else If Up <> 0 Then
  Begin
    If ((KbdMode And 2) <> 0) Or KbdMonOn Then KbdPushX(Sc Shl 8, KbdState Or Ext Or $20000);
  End
  Else
  Begin
    { Inser bascule l'etat d'insertion }
    If (Sc = $52) And (KbdE0 Or Not KbdNum Or KbdShift) Then KbdState := KbdState Xor $0080;
    Ch := 0;
    If KbdE0 Then
    Begin
      { touches etendues : fleches, Inser, Suppr, Debut, Fin... }
      If Sc = $1C Then Ch := 13
      Else If Sc = $35 Then Ch := Ord('/');
    End
    Else If Sc < 58 Then
    Begin
      If KbdShift Then
      Begin
        Ch := Ord(KeyHighV[Sc + 1]);
        If Ch = Ord('x') Then Ch := 0;
      End
      Else
      Begin
        Ch := Ord(KeyLowV[Sc + 1]);
        If Ch = Ord('X') Then Ch := 0;
      End;
      Case Sc Of
        $01 : Ch := 27;
        $0E : Ch := 8;
        $0F : Ch := 9;
        $1C : Ch := 13;
      End;
      If KbdCaps And (Chr(Ch) In ['a'..'z']) Then Ch := Ch - 32
      Else If KbdCaps And (Chr(Ch) In ['A'..'Z']) Then Ch := Ch + 32;
      If KbdCtrl And (Chr(Ch) In ['a'..'z']) Then Ch := Ch - 96
      Else If KbdCtrl And (Chr(Ch) In ['A'..'Z']) Then Ch := Ch - 64;
      If KbdAlt Then Ch := 0;
    End
    Else If (Sc >= $47) And (Sc <= $53) And KbdNum And Not KbdShift Then
    Begin
      { pave numerique }
      Case Sc Of
        $47 : Ch := Ord('7'); $48 : Ch := Ord('8'); $49 : Ch := Ord('9');
        $4A : Ch := Ord('-'); $4B : Ch := Ord('4'); $4C : Ch := Ord('5');
        $4D : Ch := Ord('6'); $4E : Ch := Ord('+'); $4F : Ch := Ord('1');
        $50 : Ch := Ord('2'); $51 : Ch := Ord('3'); $52 : Ch := Ord('0');
        $53 : Ch := Ord('.');
      End;
    End
    Else If (Sc = $4A) Or (Sc = $4E) Then
    Begin
      If Sc = $4A Then Ch := Ord('-') Else Ch := Ord('+');
    End;
    KbdPushX((Sc Shl 8) Or Ch, KbdState Or Ext);
  End;
  KbdE0 := False;
  Port[$20] := $20;
End;

{ Vider le tampon de sortie du controleur 8042 (une donnee restee depuis
  le BIOS bloquerait les interruptions suivantes du clavier) }
Procedure InitKeyboard;
Var N, X : LongInt;
Begin
  KeyLowV := KeyLow;
  KeyHighV := KeyHigh;
  KbdHead := 0; KbdTail := 0;
  KbdState := 0; KbdMode := 0; KbdE1 := 0;
  KbdMonOn := False; KbdMonPid := 0; MonKHead := 0; MonKTail := 0;
  KbdSyncFlags;
  N := 0;
  While ((Port[$64] And 1) <> 0) And (N < 64) Do
  Begin
    X := Port[$60];
    Inc(N);
  End;
End;

Function KeyAvail : Boolean;
Begin
  KeyAvail := KbdHead <> KbdTail;
End;

{ Lire une touche : (scancode shl 8) or ascii }
Function GetKey : LongInt;
Var V, X : LongInt;
Begin
  Repeat
    While KbdHead = KbdTail Do Idle;
    asm
      cli
    end;
    V := KbdBuf[KbdTail];
    X := KbdXt[KbdTail];
    KbdTail := (KbdTail + 1) And 63;
    asm
      sti
    end;
  Until (X And $60000) = 0;     { relachements et changements d'etat ignores }
  { touche traduite par un moniteur : E0h (touche grise) -> 00h }
  If ((X And $80000) <> 0) And ((V And $FF) = $E0) And (((V Shr 8) And $FF) <> $E0) Then
    V := V And $FF00;
  GetKey := V;
End;

{ Editeur de ligne : saisie avec echo, retour arriere, fleches gauche et
  droite, Debut, Fin, Suppr, Echap, historique (fleches haut et bas) }
Procedure ReadLine(Var S : String);
Var
  K, Ch, Sc, Pos, I, StartRow, StartCol, HistIdx, OldLen : LongInt;

  Procedure Redraw;
  Var J : LongInt;
  Begin
    SerialMute := True;
    CurRow := StartRow; CurCol := StartCol;
    For J := 1 To Length(S) Do ConPutRaw(S[J]);
    For J := Length(S) + 1 To OldLen Do ConPutRaw(' ');
    { la saisie a pu faire defiler l'ecran }
    While (StartRow > 0) And ((StartRow * ScrCols + StartCol + OldLen) > ConRows * ScrCols - 1) Do
      Dec(StartRow);
    CurRow := StartRow + (StartCol + Pos) Div ScrCols;
    CurCol := (StartCol + Pos) Mod ScrCols;
    If CurRow >= ConRows Then CurRow := ConRows - 1;
    UpdateCursor;
    If Length(S) > OldLen Then OldLen := Length(S);
    SerialMute := False;
  End;

Begin
  S := ''; Pos := 0; OldLen := 0;
  StartRow := CurRow; StartCol := CurCol;
  HistIdx := HistCount;
  Repeat
    K := GetKey;
    Ch := K And $FF;
    Sc := (K Shr 8) And $FF;
    If Ch = 13 Then Break;
    If Ch = 8 Then
    Begin
      If Pos > 0 Then
      Begin
        Delete(S, Pos, 1);
        Dec(Pos);
        Redraw;
      End;
    End
    Else If Ch = 27 Then
    Begin
      S := ''; Pos := 0;
      Redraw;
    End
    Else If Ch = 0 Then
    Begin
      Case Sc Of
        $4B : If Pos > 0 Then Begin Dec(Pos); Redraw End;               { gauche }
        $4D : If Pos < Length(S) Then Begin Inc(Pos); Redraw End;       { droite }
        $47 : Begin Pos := 0; Redraw End;                               { Debut }
        $4F : Begin Pos := Length(S); Redraw End;                       { Fin }
        $53 : If Pos < Length(S) Then Begin Delete(S, Pos + 1, 1); Redraw End;
        $48 : If HistIdx > 0 Then                                       { haut }
              Begin
                Dec(HistIdx);
                S := History[HistIdx]; Pos := Length(S);
                Redraw;
              End;
        $50 : If HistIdx < HistCount Then                               { bas }
              Begin
                Inc(HistIdx);
                If HistIdx = HistCount Then S := '' Else S := History[HistIdx];
                Pos := Length(S);
                Redraw;
              End;
      End;
    End
    Else If (Ch >= 32) And (Length(S) < 250) Then
    Begin
      Insert(Chr(Ch), S, Pos + 1);
      Inc(Pos);
      Redraw;
    End;
  Until False;
  Pos := Length(S);
  Redraw;
  For I := 1 To Length(S) Do SerialPut(S[I]);
  ConPutS(#13#10);
  If S <> '' Then
  Begin
    If HistCount = 16 Then
    Begin
      For I := 0 To 14 Do History[I] := History[I + 1];
      HistCount := 15;
    End;
    History[HistCount] := S;
    Inc(HistCount);
  End;
End;

{ ==================================================================== }
{ Partie 6b - Souris PS/2 (port auxiliaire du 8042, IRQ 12)            }
{ ==================================================================== }
{ Le pilote assemble les paquets de 3 octets de la souris (boutons,
  deplacements X et Y en mickeys) dans une file ; MOUCALLS.DLL les lit
  par KrnMouRead et gere position, evenements et pointeur. }

Const
  MouQSize = 128;

Var
  MouOk      : Boolean;
  MouPk      : Array[0..2] Of LongInt;
  MouIdx     : LongInt;
  MouQDx, MouQDy, MouQBtn, MouQTime : Array[0..MouQSize - 1] Of LongInt;
  MouHead, MouTail, MouLost : LongInt;
  MouMonOn  : Boolean;                  { moniteurs MOUSE$ actifs }
  MouMonPid : LongInt;
  MouMDx, MouMDy, MouMBtn, MouMTime : Array[0..MouQSize - 1] Of LongInt;
  MouMHead, MouMTail : LongInt;

{ Ranger un paquet de la souris pour MOUCALLS.DLL (Y vers le bas) }
Function MouPush(Dx, Dy, Btn, Tm : LongInt) : Boolean;
Var N : LongInt;
Begin
  MouPush := False;
  N := (MouTail + 1) Mod MouQSize;
  If N = MouHead Then Exit;
  MouQDx[MouTail] := Dx;
  MouQDy[MouTail] := Dy;
  MouQBtn[MouTail] := Btn;
  MouQTime[MouTail] := Tm;
  MouTail := N;
  MouPush := True;
End;

Procedure IrqMouse; Interrupt;
Var B, N, Dx, Dy : LongInt;
Begin
  If (Port[$64] And $21) = $21 Then
  Begin
    B := Port[$60];
    { premier octet : bit 3 toujours a 1 (resynchronisation) }
    If (MouIdx = 0) And ((B And 8) = 0) Then
    Else
    Begin
      MouPk[MouIdx] := B;
      Inc(MouIdx);
      If MouIdx = 3 Then
      Begin
        MouIdx := 0;
        Dx := MouPk[1];
        If (MouPk[0] And $10) <> 0 Then Dx := Dx - 256;
        Dy := MouPk[2];
        If (MouPk[0] And $20) <> 0 Then Dy := Dy - 256;
        If (MouPk[0] And $C0) <> 0 Then
        Begin
          Dx := 0; Dy := 0;                 { debordement : paquet ignore }
        End;
        If VmOn And (FgSess = VmSess) Then DosMouIn(Dx, -Dy, MouPk[0] And 7)
        Else If MouMonOn Then
        Begin
          { vers la chaine de moniteurs MOUSE$ }
          N := (MouMTail + 1) Mod MouQSize;
          If N = MouMHead Then Inc(MouLost)
          Else
          Begin
            MouMDx[MouMTail] := Dx;
            MouMDy[MouMTail] := -Dy;
            MouMBtn[MouMTail] := MouPk[0] And 7;
            MouMTime[MouMTail] := Ticks * 10;
            MouMTail := N;
          End;
        End
        Else If Not MouPush(Dx, -Dy, MouPk[0] And 7, Ticks * 10) Then Inc(MouLost);
      End;
    End;
  End;
  Port[$A0] := $20;
  Port[$20] := $20;
End;

{ Attendre que le 8042 accepte une ecriture }
Function MouWaitIn : Boolean;
Var N : LongInt;
Begin
  N := 0;
  While ((Port[$64] And 2) <> 0) And (N < 100000) Do Inc(N);
  MouWaitIn := N < 100000;
End;

{ Attendre une donnee du 8042 ; rend -1 si rien }
Function MouReadByte : LongInt;
Var N, R : LongInt;
Begin
  N := 0;
  R := -1;
  While (R < 0) And (N < 200000) Do
  Begin
    If (Port[$64] And 1) <> 0 Then R := Port[$60];
    Inc(N);
  End;
  MouReadByte := R;
End;

{ Commande a la souris (D4h puis l'octet) ; vrai si FAh (ACK) }
Function MouCmd(B : LongInt) : Boolean;
Begin
  MouWaitIn;
  Port[$64] := $D4;
  MouWaitIn;
  Port[$60] := B;
  MouCmd := MouReadByte = $FA;
End;

Procedure InitMouse;
Var Cb, X : LongInt;
Begin
  MouOk := False;
  MouIdx := 0; MouHead := 0; MouTail := 0; MouLost := 0;
  MouMonOn := False; MouMonPid := 0; MouMHead := 0; MouMTail := 0;
  asm
    cli
  end;
  MouWaitIn;
  Port[$64] := $A8;                       { activer le port auxiliaire }
  MouWaitIn;
  Port[$64] := $20;                       { octet de commande }
  Cb := MouReadByte;
  If Cb >= 0 Then
  Begin
    { IRQ 12 coupee pendant la configuration }
    MouWaitIn;
    Port[$64] := $60;
    MouWaitIn;
    Port[$60] := (Cb And Not $22) And $FF;
    If MouCmd($F6) Then                   { valeurs par defaut }
      If MouCmd($F4) Then                 { envoi des paquets }
        MouOk := True;
    X := MouReadByte;
    If MouOk Then Cb := (Cb Or 2) And Not $20 Else Cb := Cb And Not 2;
    MouWaitIn;
    Port[$64] := $60;
    MouWaitIn;
    Port[$60] := Cb And $FF;
  End;
  If MouOk Then
  Begin
    SetGate($2C, LongInt(@IrqMouse));
    Port[$A1] := Port[$A1] And Not $10;   { IRQ 12 }
  End;
  asm
    sti
  end;
End;

{ KrnMouRead(P) : paquet suivant de la souris dans P (deplacement X,
  deplacement Y vers le bas en mickeys, boutons : bit 0 gauche, bit 1
  droit, bit 2 milieu, instant en ms) ; rend 1, ou 0 si la file est vide }
Function KrnMouRead(P : LongInt) : LongInt;
Begin
  KrnMouRead := 0;
  If MouHead <> MouTail Then
  Begin
    MemL[0:P] := MouQDx[MouHead];
    MemL[0:P + 4] := MouQDy[MouHead];
    MemL[0:P + 8] := MouQBtn[MouHead];
    MemL[0:P + 12] := MouQTime[MouHead];
    MouHead := (MouHead + 1) Mod MouQSize;
    KrnMouRead := 1;
  End;
End;

{ KrnMouInfo(P) : souris presente (1/0), nombre de boutons, paquets
  perdus, resolution (mickeys par cm) ; rend 1 si la souris est presente }
Function KrnMouInfo(P : LongInt) : LongInt;
Begin
  If MouOk Then MemL[0:P] := 1 Else MemL[0:P] := 0;
  MemL[0:P + 4] := 3;
  MemL[0:P + 8] := MouLost;
  MemL[0:P + 12] := 40;
  If MouOk Then KrnMouInfo := 1 Else KrnMouInfo := 0;
End;

{ KrnKbdRead(P, Flags) : touche suivante du clavier (KBDCALLS.DLL).
  P^ : (scan shl 8) or ascii, etat et indicateurs (voir KbdPushX), heure
  en ms. Flags : 1 lire sans retirer, 2 attendre une touche. Rend 1 si
  une touche est rendue, 0 si le tampon est vide. }
Function KrnKbdRead(P, Flags : LongInt) : LongInt;
Begin
  KrnKbdRead := 0;
  If (Flags And 2) <> 0 Then
    While KbdHead = KbdTail Do Idle;
  If KbdHead <> KbdTail Then
  Begin
    MemL[0:P] := KbdBuf[KbdTail];
    MemL[0:P + 4] := KbdXt[KbdTail];
    MemL[0:P + 8] := KbdTm[KbdTail];
    If (Flags And 1) = 0 Then KbdTail := (KbdTail + 1) And 63;
    KrnKbdRead := 1;
  End;
End;

{ KrnKbdCtl(Op, V) : 0 etat des touches ; 1 changer les verrouillages
  (bits 10h a 80h de V, voyants mis a jour) ; 2 mode (1 changements
  d'etat, 2 relachements ; rend l'ancien) ; 3 vider le tampon ;
  4 nombre de touches en attente }
Function KrnKbdCtl(Op, V : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  Case Op Of
    0 : R := KbdState;
    1 : Begin
          KbdState := (KbdState And Not $F0) Or (V And $F0);
          KbdSyncFlags;
          KbdLeds;
          R := KbdState;
        End;
    2 : Begin
          R := KbdMode;
          KbdMode := V And 3;
        End;
    3 : KbdTail := KbdHead;
    4 : R := (KbdHead - KbdTail + 64) And 63;
  End;
  KrnKbdCtl := R;
End;


{ ==================================================================== }
{ Partie 6c - Imprimante (ports paralleles) et moniteurs               }
{ ==================================================================== }

{ Les ecritures sur PRN et LPT1 a LPT3 vont au port parallele (adresses
  du BIOS en 0408h) ; avec des moniteurs (MONCALLS.DLL), elles passent
  d'abord par la chaine de moniteurs, par paquets de 64 octets au plus.
  KrnMonIo sert les chaines de KBD$, MOUSE$ et LPT1 a LPT3. }

Const
  PrnMQSize = 32;
  PrnPkMax  = 64;

Var
  PrnMonOn  : Array[0..2] Of Boolean;
  PrnMonPid : Array[0..2] Of LongInt;
  PrnMLpt, PrnMLen : Array[0..PrnMQSize - 1] Of LongInt;
  PrnMData  : Array[0..PrnMQSize * PrnPkMax - 1] Of Byte;
  PrnMHead, PrnMTail : LongInt;

Function LptBase(Lpt : LongInt) : LongInt;
Begin
  LptBase := 0;
  If (Lpt >= 0) And (Lpt <= 2) Then LptBase := MemW[0:$408 + Lpt * 2];
End;

{ Envoyer N octets au port parallele ; rend le nombre d'octets envoyes
  (-1 : pas de port) }
Function PrnOut(Lpt, Buf, N : LongInt) : LongInt;
Var B, I, T : LongInt;
Begin
  B := LptBase(Lpt);
  If B = 0 Then
  Begin
    PrnOut := -1;
    Exit;
  End;
  I := 0;
  While I < N Do
  Begin
    T := 0;
    While ((Port[B + 1] And $80) = 0) And (T < 500000) Do Inc(T);   { occupee }
    If T >= 500000 Then
    Begin
      PrnOut := I;
      Exit;
    End;
    Port[B] := Mem[0:Buf + I];
    Port[B + 2] := $0D;                   { impulsion STROBE }
    Port[B + 2] := $0C;
    Inc(I);
  End;
  PrnOut := N;
End;

{ Ecriture sur l'imprimante Lpt : rend le nombre d'octets acceptes }
Function PrnWrite(Lpt, Buf, N : LongInt) : LongInt;
Var Done, C, Nx : LongInt;
Begin
  If PrnMonOn[Lpt] Then
  Begin
    Done := 0;
    While Done < N Do
    Begin
      Nx := (PrnMTail + 1) Mod PrnMQSize;
      If Nx = PrnMHead Then
      Begin
        PrnWrite := Done;
        Exit;
      End;
      C := N - Done;
      If C > PrnPkMax Then C := PrnPkMax;
      MoveMem(Buf + Done, LongInt(@PrnMData) + PrnMTail * PrnPkMax, C);
      PrnMLpt[PrnMTail] := Lpt;
      PrnMLen[PrnMTail] := C;
      PrnMTail := Nx;
      Done := Done + C;
    End;
    PrnWrite := Done;
  End
  Else
    PrnWrite := PrnOut(Lpt, Buf, N);
End;

Function ProcAlive(Pid : LongInt) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := Pid = 1;
  For I := 0 To MaxProcs - 1 Do
    If Procs[I].Running And (Procs[I].Serial = Pid) Then R := True;
  ProcAlive := R;
End;

Function MonPid : LongInt;
Begin
  If CurProc >= 0 Then MonPid := Procs[CurProc].Serial Else MonPid := 1;
End;

{ Arreter la surveillance du peripherique Dev : les paquets en attente
  sont rendus au peripherique }
Procedure MonStop(Dev : LongInt);
Var D : Boolean; L : LongInt;
Begin
  asm
    cli
  end;
  If Dev = 0 Then
  Begin
    While MonKHead <> MonKTail Do
    Begin
      D := KbdPushRaw(MonKV[MonKHead], MonKX[MonKHead], MonKT[MonKHead]);
      MonKHead := (MonKHead + 1) And 63;
    End;
    KbdMonOn := False;
  End
  Else If Dev = 1 Then
  Begin
    While MouMHead <> MouMTail Do
    Begin
      D := MouPush(MouMDx[MouMHead], MouMDy[MouMHead], MouMBtn[MouMHead], MouMTime[MouMHead]);
      MouMHead := (MouMHead + 1) Mod MouQSize;
    End;
    MouMonOn := False;
  End
  Else If (Dev >= 2) And (Dev <= 4) Then
    PrnMonOn[Dev - 2] := False;
  asm
    sti
  end;
  If (Dev >= 2) And (Dev <= 4) Then
    While PrnMHead <> PrnMTail Do
    Begin
      L := PrnOut(PrnMLpt[PrnMHead], LongInt(@PrnMData) + PrnMHead * PrnPkMax, PrnMLen[PrnMHead]);
      PrnMHead := (PrnMHead + 1) Mod PrnMQSize;
    End;
End;

{ KrnMonIo(Dev, Op, P) : chaines de moniteurs (MONCALLS.DLL).
  Dev : 0 KBD$, 1 MOUSE$, 2 a 4 LPT1 a LPT3.
  Op 0 : surveillance activee (P <> 0) ou arretee (P = 0 ; paquets en
         attente rendus au peripherique) ; rend l'ancien etat (1/0).
  Op 1 : paquet suivant pour la chaine dans P ; rend 1, ou 0 si aucun.
  Op 2 : rendre le paquet P au peripherique (fin de la chaine) ; rend 1,
         ou 0 si le peripherique ne peut le prendre.
  Op 3 : nombre de paquets en attente pour la chaine.
  Op 4 : le processus P est-il actif ? (1/0)
  Op 5 : adresse du port de LPTn (0 : absent) ; souris presente pour
         MOUSE$.
  Paquets : clavier P^ = touche ((code shl 8) or caractere), etat et
  indicateurs (KbdPushX), heure ; souris P^ = dx, dy, boutons, heure ;
  imprimante P^ = longueur puis octets (64 au plus). }
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt;
Var R, L : LongInt; On : Boolean;
Begin
  R := 0;
  Case Op Of
    0 : Begin
          On := P <> 0;
          If Dev = 0 Then
          Begin
            If KbdMonOn Then R := 1;
            If On And Not KbdMonOn Then
            Begin
              MonKHead := 0; MonKTail := 0;
              KbdMonPid := MonPid;
              KbdMonOn := True;
            End
            Else If (Not On) And KbdMonOn Then MonStop(0);
          End
          Else If Dev = 1 Then
          Begin
            If MouMonOn Then R := 1;
            If On And Not MouMonOn Then
            Begin
              MouMHead := 0; MouMTail := 0;
              MouMonPid := MonPid;
              MouMonOn := True;
            End
            Else If (Not On) And MouMonOn Then MonStop(1);
          End
          Else If (Dev >= 2) And (Dev <= 4) Then
          Begin
            If PrnMonOn[Dev - 2] Then R := 1;
            If On And Not PrnMonOn[Dev - 2] Then
            Begin
              PrnMonPid[Dev - 2] := MonPid;
              PrnMonOn[Dev - 2] := True;
            End
            Else If (Not On) And PrnMonOn[Dev - 2] Then MonStop(Dev);
          End;
        End;
    1 : If Dev = 0 Then
        Begin
          If MonKHead <> MonKTail Then
          Begin
            MemL[0:P] := MonKV[MonKHead];
            MemL[0:P + 4] := MonKX[MonKHead];
            MemL[0:P + 8] := MonKT[MonKHead];
            MonKHead := (MonKHead + 1) And 63;
            R := 1;
          End;
        End
        Else If Dev = 1 Then
        Begin
          If MouMHead <> MouMTail Then
          Begin
            MemL[0:P] := MouMDx[MouMHead];
            MemL[0:P + 4] := MouMDy[MouMHead];
            MemL[0:P + 8] := MouMBtn[MouMHead];
            MemL[0:P + 12] := MouMTime[MouMHead];
            MouMHead := (MouMHead + 1) Mod MouQSize;
            R := 1;
          End;
        End
        Else If (Dev >= 2) And (Dev <= 4) Then
        Begin
          If (PrnMHead <> PrnMTail) And (PrnMLpt[PrnMHead] = Dev - 2) Then
          Begin
            L := PrnMLen[PrnMHead];
            MemL[0:P] := L;
            MoveMem(LongInt(@PrnMData) + PrnMHead * PrnPkMax, P + 4, L);
            PrnMHead := (PrnMHead + 1) Mod PrnMQSize;
            R := 1;
          End;
        End;
    2 : If Dev = 0 Then
        Begin
          If KbdPushRaw(MemL[0:P], MemL[0:P + 4], MemL[0:P + 8]) Then R := 1;
        End
        Else If Dev = 1 Then
        Begin
          If MouPush(MemL[0:P], MemL[0:P + 4], MemL[0:P + 8], MemL[0:P + 12]) Then R := 1;
        End
        Else If (Dev >= 2) And (Dev <= 4) Then
        Begin
          L := MemL[0:P];
          If (L >= 0) And (L <= 256) Then
            If PrnOut(Dev - 2, P + 4, L) = L Then R := 1;
        End;
    3 : If Dev = 0 Then R := (MonKTail - MonKHead + 64) And 63
        Else If Dev = 1 Then R := (MouMTail - MouMHead + MouQSize) Mod MouQSize
        Else If (Dev >= 2) And (Dev <= 4) Then
          If (PrnMHead <> PrnMTail) And (PrnMLpt[PrnMHead] = Dev - 2) Then R := 1;
    4 : If ProcAlive(P) Then R := 1;
    5 : If Dev = 1 Then
        Begin
          If MouOk Then R := 1;
        End
        Else If Dev = 0 Then R := 1
        Else R := LptBase(Dev - 2);
  End;
  KrnMonIo := R;
End;

{ Fin d'un processus : ses chaines de moniteurs sont arretees }
Procedure MonProcessExit(Pid : LongInt);
Var I : LongInt;
Begin
  If KbdMonOn And (KbdMonPid = Pid) Then MonStop(0);
  If MouMonOn And (MouMonPid = Pid) Then MonStop(1);
  For I := 0 To 2 Do
    If PrnMonOn[I] And (PrnMonPid[I] = Pid) Then MonStop(I + 2);
End;

{ ==================================================================== }
{ Partie 7 - Memoire : tas du noyau et memoire physique                }
{ ==================================================================== }
{ Le tas est une suite de blocs : en-tete de 16 octets
    +0 signature (utilise / libre)  +4 taille totale du bloc
    +8 processus proprietaire        +12 reserve                       }

Procedure HeapInit(Start, Stop : LongInt);
Begin
  HeapStart := (Start + 15) And Not 15;
  HeapEnd := Stop And Not 15;
  MemL[0:HeapStart] := HeapMagicFree;
  MemL[0:HeapStart + 4] := HeapEnd - HeapStart;
  MemL[0:HeapStart + 8] := -1;
End;

Function KAlloc(Size : LongInt) : LongInt;
Var P, BS, Need : LongInt;
Begin
  KAlloc := 0;
  If Size <= 0 Then Size := 1;
  Need := ((Size + 15) And Not 15) + 16;
  P := HeapStart;
  While P < HeapEnd Do
  Begin
    BS := MemL[0:P + 4];
    If BS <= 0 Then Exit;   { tas corrompu }
    If (MemL[0:P] = HeapMagicFree) Then
    Begin
      { fusionner les blocs libres suivants }
      While (P + BS < HeapEnd) And (MemL[0:P + BS] = HeapMagicFree) Do
      Begin
        BS := BS + MemL[0:P + BS + 4];
        MemL[0:P + 4] := BS;
      End;
      If BS >= Need Then
      Begin
        If BS - Need >= 32 Then
        Begin
          MemL[0:P + Need] := HeapMagicFree;
          MemL[0:P + Need + 4] := BS - Need;
          MemL[0:P + 4] := Need;
        End;
        MemL[0:P] := HeapMagicUsed;
        MemL[0:P + 8] := -1;          { proprietaire : noyau (voir HeapAlloc) }
        KAlloc := P + 16;
        Exit;
      End;
    End;
    P := P + BS;
  End;
End;

Procedure KFree(A : LongInt);
Begin
  If (A < HeapStart + 16) Or (A >= HeapEnd) Then Exit;
  If MemL[0:A - 16] <> HeapMagicUsed Then Exit;
  MemL[0:A - 16] := HeapMagicFree;
End;

Function KBlockSize(A : LongInt) : LongInt;
Begin
  If (A >= HeapStart + 16) And (A < HeapEnd) And (MemL[0:A - 16] = HeapMagicUsed) Then
    KBlockSize := MemL[0:A - 12] - 16
  Else
    KBlockSize := -1;
End;

{ Liberer tous les blocs d'un processus termine }
Procedure KFreeOwner(Pid : LongInt);
Var P, BS : LongInt;
Begin
  P := HeapStart;
  While P < HeapEnd Do
  Begin
    BS := MemL[0:P + 4];
    If BS <= 0 Then Exit;
    If (MemL[0:P] = HeapMagicUsed) And (MemL[0:P + 8] = Pid) Then
      MemL[0:P] := HeapMagicFree;
    P := P + BS;
  End;
End;

Function HeapFreeBytes : LongInt;
Var P, BS, T : LongInt;
Begin
  T := 0;
  P := HeapStart;
  While P < HeapEnd Do
  Begin
    BS := MemL[0:P + 4];
    If BS <= 0 Then Break;
    If MemL[0:P] = HeapMagicFree Then T := T + BS;
    P := P + BS;
  End;
  HeapFreeBytes := T;
End;

{ ==================================================================== }
{ Partie 8 - Pagination                                                }
{ ==================================================================== }
{ Le repertoire de pages projette les 4 Go a l'identique par pages de
  4 Mo (PSE), sauf l'entree 1 (00400000h-007FFFFFh) qui designe la table
  de pages du processus courant. }

Procedure InitPaging;
Var I : LongInt;
Begin
  PageDir := KAlloc(8192);
  PageDir := (PageDir + 4095) And Not 4095;
  For I := 0 To 1023 Do
    MemL[0:PageDir + I * 4] := (I Shl 22) Or $87;     { present, R/W, utilisateur (DPMI), 4 Mo }
  MemL[0:PageDir + 4] := 0;                           { fenetre vide }
  asm
    mov eax,cr4
    or eax,10h
    mov cr4,eax
    mov eax,PageDir
    mov cr3,eax
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
  end;
  PagingOn := True;
End;

Procedure FlushTlb;
Begin
  asm
    mov eax,cr3
    mov cr3,eax
  end;
End;

{ Installer la fenetre du processus Pid (ou aucune si Pid < 0) }
Procedure MapWindow(Pid : LongInt);
Begin
  If (Pid >= 0) And Procs[Pid].Used Then
    MemL[0:PageDir + 4] := Procs[Pid].PageTable Or $03
  Else
    MemL[0:PageDir + 4] := 0;
  FlushTlb;
End;

{ Construire la table de pages d'un processus dans le bloc Alloc (8 Ko) :
  la fenetre virtuelle 00400000h + i*4 Ko -> PhysBase + i*4 Ko }
Function BuildPageTableAt(Alloc, PhysBase, PhysSize : LongInt) : LongInt;
Var T, I, NPages : LongInt;
Begin
  BuildPageTableAt := 0;
  If Alloc = 0 Then Exit;
  T := (Alloc + 4095) And Not 4095;
  NPages := PhysSize Div 4096;
  For I := 0 To 1023 Do
    If I < NPages Then MemL[0:T + I * 4] := (PhysBase + I * 4096) Or $03
    Else MemL[0:T + I * 4] := 0;
  BuildPageTableAt := T;
End;

{ ==================================================================== }
{ Partie 9 - Pilote ATAPI (CD-ROM IDE, mode PIO, sans interruption)    }
{ ==================================================================== }

Const
  CacheSlots = 16;

Var
  CacheLba  : Array[0..CacheSlots - 1] Of LongInt;
  CacheData : Array[0..CacheSlots - 1] Of LongInt;   { 2 Ko chacun }
  CacheNext : LongInt;

{ Attendre que BSY retombe ; rend le registre d'etat ou -1 }
Function AtaWaitBusy : LongInt;
Var N, St : LongInt;
Begin
  N := 0;
  Repeat
    St := Port[AtaBase + 7];
    If (St And $80) = 0 Then
    Begin
      AtaWaitBusy := St;
      Exit;
    End;
    Inc(N);
  Until N > 2000000;
  AtaWaitBusy := -1;
End;

Procedure AtaDelay;
Var I, X : LongInt;
Begin
  For I := 1 To 4 Do X := Port[AtaCtrl];
End;

Procedure AtaSelect;
Begin
  If AtaSlave Then Port[AtaBase + 6] := $B0 Else Port[AtaBase + 6] := $A0;
  AtaDelay;
End;

{ IDENTIFY PACKET DEVICE (A1h) : vrai si un lecteur ATAPI repond }
Function AtaProbe(Base, Ctrl : LongInt; Slave : Boolean) : Boolean;
Var St, I, X : LongInt;
Begin
  AtaProbe := False;
  AtaBase := Base; AtaCtrl := Ctrl; AtaSlave := Slave;
  If Port[Base + 7] = $FF Then Exit;          { bus absent }
  Port[Ctrl] := 2;                             { nIEN : pas d'IRQ }
  AtaSelect;
  If Port[Base + 7] = 0 Then Exit;
  Port[Base + 7] := $A1;
  AtaDelay;
  St := AtaWaitBusy;
  If (St < 0) Or ((St And 1) <> 0) Or ((St And 8) = 0) Then Exit;
  For I := 0 To 255 Do X := PortW[Base];
  AtaProbe := True;
End;

Procedure AtaInit;
Begin
  AtaFound := AtaProbe($170, $376, False);
  If Not AtaFound Then AtaFound := AtaProbe($170, $376, True);
  If Not AtaFound Then AtaFound := AtaProbe($1F0, $3F6, False);
  If Not AtaFound Then AtaFound := AtaProbe($1F0, $3F6, True);
End;

{ Lire un secteur de 2048 octets (commande PACKET, READ(10)) a l'adresse Dst }
Function AtaReadSector(Lba, Dst : LongInt) : Boolean;
Var St, Cnt, Got, Tries, B : LongInt;
Begin
  AtaReadSector := False;
  If Not AtaFound Then Exit;
  For Tries := 1 To 3 Do
  Begin
    AtaSelect;
    If AtaWaitBusy < 0 Then Continue;
    Port[AtaBase + 1] := 0;                   { PIO }
    Port[AtaBase + 4] := 2048 And $FF;
    Port[AtaBase + 5] := 2048 Shr 8;
    Port[AtaBase + 7] := $A0;                 { PACKET }
    AtaDelay;
    St := AtaWaitBusy;
    If (St < 0) Or ((St And 8) = 0) Then Continue;
    { paquet READ(10) : 12 octets }
    PortW[AtaBase] := $0028;
    PortW[AtaBase] := ((Lba Shr 24) And $FF) Or (((Lba Shr 16) And $FF) Shl 8);
    PortW[AtaBase] := ((Lba Shr 8) And $FF) Or ((Lba And $FF) Shl 8);
    PortW[AtaBase] := $0000;
    PortW[AtaBase] := $0001;
    PortW[AtaBase] := $0000;
    Got := 0;
    Repeat
      AtaDelay;
      St := AtaWaitBusy;
      If (St < 0) Or ((St And 1) <> 0) Then Break;
      If (St And 8) = 0 Then Break;
      Cnt := Port[AtaBase + 4] Or (Port[AtaBase + 5] Shl 8);
      If (Cnt <= 0) Or (Got + Cnt > 2048) Then Break;
      B := Dst + Got;
      asm
        push edi
        mov edi,B
        mov ecx,Cnt
        shr ecx,1
        mov edx,AtaBase
        cld
        rep insw
        pop edi
      end;
      Got := Got + Cnt;
    Until Got >= 2048;
    AtaWaitBusy;
    If Got = 2048 Then
    Begin
      AtaReadSector := True;
      Exit;
    End;
  End;
End;

{ Secteur Lba via l'antememoire ; rend l'adresse des 2048 octets ou 0 }
Function CdSector(Lba : LongInt) : LongInt;
Var I : LongInt;
Begin
  For I := 0 To CacheSlots - 1 Do
    If (CacheLba[I] = Lba) And (CacheData[I] <> 0) Then
    Begin
      CdSector := CacheData[I];
      Exit;
    End;
  I := CacheNext;
  CacheNext := (CacheNext + 1) Mod CacheSlots;
  If CacheData[I] = 0 Then CacheData[I] := KAlloc(2048);
  CacheLba[I] := -1;
  If AtaReadSector(Lba, CacheData[I]) Then
  Begin
    CacheLba[I] := Lba;
    CdSector := CacheData[I];
  End
  Else
    CdSector := 0;
End;

{ ==================================================================== }
{ Partie 9b - Peripheriques bloc : disques durs IDE et disque virtuel  }
{ ==================================================================== }
{ Les volumes des systemes de fichiers installables (IFS) sont sur des
  peripheriques bloc de secteurs de 512 octets : partitions d'un disque
  dur IDE/ATA (mode PIO 28 bits, sans interruption) ou disque virtuel en
  memoire (/RAMDISK:n de la ligne IFS=). Les pilotes IFS y accedent par
  FSH_DOVOLIO (secteurs relatifs au debut du volume). }

Const
  MaxBlk  = 8;
  BlkAta  = 1;
  BlkRam  = 2;

Type
  TBlk = Record
    Used   : Boolean;
    Kind   : LongInt;
    Base   : LongInt;       { ports ATA }
    Ctrl   : LongInt;
    Slave  : Boolean;
    Start  : LongInt;       { premier secteur (LBA) du volume sur le disque }
    Count  : LongInt;       { nombre de secteurs }
    Mem    : LongInt;       { disque virtuel : adresse en memoire }
    PType  : LongInt;       { type de partition (07h = HPFS/IFS) }
    Disk   : LongInt;       { disque dur (table Disks), -1 : disque virtuel }
    Seen   : Boolean;       { deja presente aux pilotes IFS }
  End;

  { disque dur IDE (KrnDiskCtl : partitionnement et installation) }
  TDisk = Record
    Base, Ctrl : LongInt;
    Slave      : Boolean;
    Sectors    : LongInt;
    Model      : String[40];
  End;

  { pilote IFS charge (IFS= de CONFIG.SYS) : points d'entree FS_* }
  TIfs = Record
    Used     : Boolean;
    Module   : LongInt;
    Name     : String[15];      { FS_NAME : HPFS... }
    FInit, FMount, FOpen, FClose, FRead, FWrite, FSeek, FNewSize, FCommit : LongInt;
    FFileInfo, FPathInfo, FFileAttr, FDelete, FMkDir, FRmDir, FMove, FChDir : LongInt;
    FFindFirst, FFindNext, FFindClose, FFsInfo, FFlush, FFsCtl, FExit, FShutdown : LongInt;
  End;

  { volume monte par un IFS : unite D: a Z: (le hVPB est le numero
    d'unite, 3 = D:) }
  TIfsVol = Record
    Mounted  : Boolean;
    Blk      : LongInt;
    Ifs      : LongInt;
    Vpfsi    : Array[0..43] Of Byte;
    Vpfsd    : Array[0..63] Of Byte;
  End;

Const
  MaxIfs = 4;

Var
  Blks   : Array[0..MaxBlk - 1] Of TBlk;
  NBlk   : LongInt;
  HdBuf  : Array[0..511] Of Byte;
  Ifss   : Array[0..MaxIfs - 1] Of TIfs;
  NIfs   : LongInt;
  IfsVols : Array[0..25] Of TIfsVol;
  IfsLines : Array[0..MaxIfs - 1] Of String;   { lignes IFS= de CONFIG.SYS }
  RamDiskKb : LongInt;                           { /RAMDISK:n de la ligne IFS= }
  NIfsLines : LongInt;
  Disks  : Array[0..3] Of TDisk;
  NDisk  : LongInt;
  { amorcage depuis un disque dur (MBR d'OS/2-0, zone d'amorcage) : C:
    est la partition HPFS active ; OS2LDR a charge HPFS.IFS en memoire }
  HdBoot      : Boolean;
  BootPartLba : LongInt;
  BootIfsBuf  : LongInt;
  BootIfsSize : LongInt;

Function HdWait(Base : LongInt) : LongInt;
Var N, St : LongInt;
Begin
  N := 0;
  St := -1;
  Repeat
    St := Port[Base + 7];
    Inc(N);
  Until ((St And $80) = 0) Or (N > 1000000);
  If (St And $80) <> 0 Then St := -1;
  HdWait := St;
End;

{ IDENTIFY DEVICE (ECh) : vrai si un disque ATA repond ; Sectors <-
  nombre de secteurs adressables (LBA 28 bits) }
Function HdIdentify(Base, Ctrl : LongInt; Slave : Boolean; Var Sectors : LongInt) : Boolean;
Var St, I, X, A : LongInt; R : Boolean;
Begin
  R := False;
  Sectors := 0;
  If Port[Base + 7] <> $FF Then
  Begin
    Port[Ctrl] := 2;
    If Slave Then Port[Base + 6] := $B0 Else Port[Base + 6] := $A0;
    For I := 1 To 4 Do X := Port[Ctrl];
    Port[Base + 2] := 0; Port[Base + 3] := 0; Port[Base + 4] := 0; Port[Base + 5] := 0;
    Port[Base + 7] := $EC;
    For I := 1 To 4 Do X := Port[Ctrl];
    St := Port[Base + 7];
    If St <> 0 Then
    Begin
      St := HdWait(Base);
      { un lecteur ATAPI repond par la signature 14h/EBh et une erreur }
      If (St >= 0) And (Port[Base + 4] = 0) And (Port[Base + 5] = 0) Then
      Begin
        I := 0;
        Repeat
          St := Port[Base + 7];
          Inc(I);
        Until ((St And 9) <> 0) Or (I > 1000000);
        If (St And 9) = 8 Then
        Begin
          A := LongInt(@HdBuf);
          asm
            push edi
            mov edi,A
            mov ecx,256
            mov edx,Base
            cld
            rep insw
            pop edi
          end;
          Sectors := MemW[0:A + 120] Or (MemW[0:A + 122] Shl 16);
          R := Sectors > 0;
        End;
      End;
    End;
  End;
  HdIdentify := R;
End;

{ Lire ou ecrire N secteurs (1 a 128) a partir de Lba (disque IDE aux
  ports Base et Ctrl) }
Function HdIOx(Base, Ctrl : LongInt; Slave : Boolean; Lba, N, Addr : LongInt; Wr : Boolean) : Boolean;
Var St, I, X, A, Tries : LongInt; Ok : Boolean;
Begin
  Ok := False;
  Tries := 0;
  While (Not Ok) And (Tries < 3) Do
  Begin
    Inc(Tries);
    Ok := True;
    If Slave Then Port[Base + 6] := $F0 Or ((Lba Shr 24) And $0F)
    Else Port[Base + 6] := $E0 Or ((Lba Shr 24) And $0F);
    For I := 1 To 4 Do X := Port[Ctrl];
    If HdWait(Base) < 0 Then Ok := False;
    If Ok Then
    Begin
      Port[Base + 1] := 0;
      Port[Base + 2] := N And $FF;
      Port[Base + 3] := Lba And $FF;
      Port[Base + 4] := (Lba Shr 8) And $FF;
      Port[Base + 5] := (Lba Shr 16) And $FF;
      If Wr Then Port[Base + 7] := $30 Else Port[Base + 7] := $20;
      I := 0;
      While Ok And (I < N) Do
      Begin
        For X := 1 To 4 Do St := Port[Ctrl];
        St := HdWait(Base);
        If (St < 0) Or ((St And 1) <> 0) Or ((St And 8) = 0) Then Ok := False
        Else
        Begin
          A := Addr + I * 512;
          If Wr Then
          Begin
            asm
              push esi
              mov esi,A
              mov ecx,256
              mov edx,Base
              cld
              rep outsw
              pop esi
            end;
          End
          Else
          Begin
            asm
              push edi
              mov edi,A
              mov ecx,256
              mov edx,Base
              cld
              rep insw
              pop edi
            end;
          End;
          Inc(I);
        End;
      End;
      If Ok And Wr Then
      Begin
        St := HdWait(Base);
        Port[Base + 7] := $E7;                    { CACHE FLUSH }
        St := HdWait(Base);
        If (St < 0) Or ((St And 1) <> 0) Then Ok := False;
      End;
    End;
  End;
  HdIOx := Ok;
End;

Function HdIO(B, Lba, N, Addr : LongInt; Wr : Boolean) : Boolean;
Begin
  HdIO := HdIOx(Blks[B].Base, Blks[B].Ctrl, Blks[B].Slave, Lba, N, Addr, Wr);
End;

Function NewBlk : LongInt;
Var R : LongInt;
Begin
  R := -1;
  If NBlk < MaxBlk Then
  Begin
    R := NBlk;
    Inc(NBlk);
    Blks[R].Used := True;
    Blks[R].Kind := 0; Blks[R].Base := 0; Blks[R].Ctrl := 0; Blks[R].Slave := False;
    Blks[R].Start := 0; Blks[R].Count := 0; Blks[R].Mem := 0; Blks[R].PType := 0;
    Blks[R].Disk := -1; Blks[R].Seen := False;
  End;
  NewBlk := R;
End;

{ Volumes d'un disque : partitions principales de type 07h de la table
  du secteur 0, ou disque entier s'il commence par un secteur d'amorce
  HPFS (sans table de partitions) }
Procedure ScanDisk(Dk : LongInt);
Var B, I, E, T, S, N, Base, Ctrl, Sectors : LongInt; Found, Slave : Boolean;
Begin
  Base := Disks[Dk].Base; Ctrl := Disks[Dk].Ctrl; Slave := Disks[Dk].Slave; Sectors := Disks[Dk].Sectors;
  B := NewBlk;
  If B < 0 Then Exit;
  Blks[B].Kind := BlkAta; Blks[B].Base := Base; Blks[B].Ctrl := Ctrl; Blks[B].Slave := Slave;
  Blks[B].Start := 0; Blks[B].Count := Sectors; Blks[B].Disk := Dk;
  If Not HdIO(B, 0, 1, LongInt(@HdBuf), False) Then
  Begin
    Dec(NBlk);
    Exit;
  End;
  Found := False;
  If (HdBuf[54] = Ord('H')) And (HdBuf[55] = Ord('P')) And (HdBuf[56] = Ord('F')) And (HdBuf[57] = Ord('S')) Then
  Begin
    Blks[B].PType := 7;
    Found := True;
  End
  Else If (HdBuf[510] = $55) And (HdBuf[511] = $AA) Then
  Begin
    Dec(NBlk);
    For I := 0 To 3 Do
    Begin
      E := LongInt(@HdBuf) + 446 + I * 16;
      T := Mem[0:E + 4];
      S := MemL[0:E + 8];
      N := MemL[0:E + 12];
      If (T = 7) And (N > 0) And (S + N <= Sectors) Then
      Begin
        B := NewBlk;
        If B >= 0 Then
        Begin
          Blks[B].Kind := BlkAta; Blks[B].Base := Base; Blks[B].Ctrl := Ctrl; Blks[B].Slave := Slave;
          Blks[B].Start := S; Blks[B].Count := N; Blks[B].PType := T; Blks[B].Disk := Dk;
          Found := True;
        End;
      End;
    End;
  End
  Else
    Dec(NBlk);
  If Found Then
    KLog('Disque IDE ' + HexStr(Base, 3) + 'h ' + IntStr(Ord(Slave)) + ' : ' +
         IntStr(Sectors Div 2048) + ' Mo, volume(s) de type 07h.');
End;

{ Chercher les disques durs IDE (sauf le lecteur de CD-ROM) : table des
  disques (KrnDiskCtl) et volumes de type 07h }
Procedure HdInit;
Var I, K, Base, Ctrl, Sectors : LongInt; Slave : Boolean; M : String;
Begin
  If NDisk > 0 Then Exit;
  For I := 0 To 3 Do
  Begin
    If I < 2 Then
    Begin
      Base := $1F0; Ctrl := $3F6;
    End
    Else
    Begin
      Base := $170; Ctrl := $376;
    End;
    Slave := Odd(I);
    If Not (AtaFound And (Base = AtaBase) And (Slave = AtaSlave)) Then
      If HdIdentify(Base, Ctrl, Slave, Sectors) And (NDisk < 4) Then
      Begin
        { modele : mots 27 a 46 d'IDENTIFY (octets inverses) }
        M := '';
        For K := 0 To 19 Do M := M + Chr(HdBuf[54 + K * 2 + 1]) + Chr(HdBuf[54 + K * 2]);
        While (Length(M) > 0) And ((M[Length(M)] = ' ') Or (M[Length(M)] = #0)) Do Delete(M, Length(M), 1);
        Disks[NDisk].Base := Base; Disks[NDisk].Ctrl := Ctrl; Disks[NDisk].Slave := Slave;
        Disks[NDisk].Sectors := Sectors; Disks[NDisk].Model := M;
        Inc(NDisk);
        ScanDisk(NDisk - 1);
      End;
  End;
  { le lecteur de CD-ROM redevient le peripherique selectionne }
  AtaSelect;
End;

{ Disque virtuel de Kb Ko pris en haut de la memoire physique }
Function RamDiskNew(Kb : LongInt) : LongInt;
Var B, Size : LongInt;
Begin
  RamDiskNew := -1;
  Size := ((Kb * 1024) + 4095) And Not 4095;
  If (Size < 512 * 1024) Or (PhysTop - Size < PhysProcBase + $00800000) Then Exit;
  B := NewBlk;
  If B < 0 Then Exit;
  PhysTop := PhysTop - Size;
  Blks[B].Kind := BlkRam; Blks[B].Disk := -1;
  Blks[B].Mem := PhysTop;
  Blks[B].Count := Size Div 512;
  Blks[B].PType := 7;
  FillMem(PhysTop, Size, 0);
  RamDiskNew := B;
End;

{ Entree/sortie de secteurs d'un peripherique bloc }
Function BlkIO(B, Op, Sec, N, Addr : LongInt) : LongInt;
Var R, K, Done : LongInt;
Begin
  R := 0;
  If (B < 0) Or (B >= NBlk) Or (Blks[B].Kind = 0) Then R := 21
  Else If (Sec < 0) Or (N < 0) Or (Sec + N > Blks[B].Count) Then R := 27   { secteur introuvable }
  Else If Blks[B].Kind = BlkRam Then
  Begin
    If (Op And 1) <> 0 Then MoveMem(Addr, Blks[B].Mem + Sec * 512, N * 512)
    Else MoveMem(Blks[B].Mem + Sec * 512, Addr, N * 512);
  End
  Else
  Begin
    Done := 0;
    While (R = 0) And (Done < N) Do
    Begin
      K := N - Done;
      If K > 128 Then K := 128;
      If Not HdIO(B, Blks[B].Start + Sec + Done, K, Addr + Done * 512, (Op And 1) <> 0) Then
      Begin
        If (Op And 1) <> 0 Then R := 29 Else R := 30;
      End
      Else
        Done := Done + K;
    End;
    AtaSelect;
  End;
  BlkIO := R;
End;

{ ==================================================================== }
{ Partie 10 - ISO 9660 et disque virtuel en memoire                    }
{ ==================================================================== }
{ Le CD-ROM d'amorcage est l'unite C:. Il est en lecture seule : les
  fichiers et repertoires crees en cours d'execution (redirections, MD,
  COPY...) sont places dans un disque virtuel en memoire superpose au
  CD-ROM (perdu a l'arret). }

Function GetD(A : LongInt) : LongInt;
Begin
  GetD := MemL[0:A];
End;

{ Date ISO 9660 (7 octets) -> date et heure DOS }
Function IsoTime(A : LongInt) : LongInt;
Var Y : LongInt;
Begin
  Y := Mem[0:A] + 1900;
  If Y < 1980 Then Y := 1980;
  IsoTime := (((Y - 1980) Shl 9) Or (Mem[0:A + 1] Shl 5) Or Mem[0:A + 2]) Shl 16 Or
             ((Mem[0:A + 3] Shl 11) Or (Mem[0:A + 4] Shl 5) Or (Mem[0:A + 5] Div 2));
End;

{ Entree numero Index (0 = premiere) d'un repertoire ISO 9660.
  Les entrees "." et ".." ne sont rendues que hors de la racine. }
Function IsoDirEntry(DirLba, DirSize, Index : LongInt; Var Name : String;
                     Var Lba, Size, Attr, Time : LongInt) : Boolean;
Var Sect, NSect, A, Ofs, Len, N, I, Cnt, NL : LongInt; C : Char;
Begin
  IsoDirEntry := False;
  Cnt := 0;
  NSect := (DirSize + 2047) Div 2048;
  For Sect := 0 To NSect - 1 Do
  Begin
    A := CdSector(DirLba + Sect);
    If A = 0 Then Exit;
    Ofs := 0;
    While Ofs < 2048 Do
    Begin
      Len := Mem[0:A + Ofs];
      If Len = 0 Then Ofs := 2048
      Else
      Begin
        NL := Mem[0:A + Ofs + 32];
        Name := '';
        If (NL = 1) And (Mem[0:A + Ofs + 33] = 0) Then Name := '.'
        Else If (NL = 1) And (Mem[0:A + Ofs + 33] = 1) Then Name := '..'
        Else
          For I := 0 To NL - 1 Do
          Begin
            C := Chr(Mem[0:A + Ofs + 33 + I]);
            If C = ';' Then Break;
            Name := Name + UpCase(C);
          End;
        If (Length(Name) > 1) And (Name[Length(Name)] = '.') Then
          Delete(Name, Length(Name), 1);
        If Not (((Name = '.') Or (Name = '..')) And (DirLba = RootLba)) Then
        Begin
          If Cnt = Index Then
          Begin
            Lba := GetD(A + Ofs + 2);
            Size := GetD(A + Ofs + 10);
            If (Mem[0:A + Ofs + 25] And 2) <> 0 Then Attr := FileAttrDirectory Or FileAttrReadOnly
            Else Attr := FileAttrReadOnly Or FileAttrArchive;
            If (Mem[0:A + Ofs + 25] And 1) <> 0 Then Attr := Attr Or FileAttrHidden;
            Time := IsoTime(A + Ofs + 18);
            IsoDirEntry := True;
            Exit;
          End;
          Inc(Cnt);
        End;
        Ofs := Ofs + Len;
      End;
    End;
  End;
End;

{ Chercher un chemin complet (C:\A\B) sur le CD-ROM }
Function IsoLookup(Path : String; Var Lba, Size, Attr, Time : LongInt) : Boolean;
Var Rest, Comp, Nm : String; P, I : LongInt; Found : Boolean;
    ELba, ESize, EAttr, ETime : LongInt;
Begin
  IsoLookup := False;
  Lba := RootLba; Size := RootSize; Attr := FileAttrDirectory Or FileAttrReadOnly; Time := 0;
  Rest := Copy(Path, 4, 255);
  While Rest <> '' Do
  Begin
    P := Pos('\', Rest);
    If P > 0 Then
    Begin
      Comp := Copy(Rest, 1, P - 1);
      Rest := Copy(Rest, P + 1, 255);
    End
    Else
    Begin
      Comp := Rest; Rest := '';
    End;
    If Comp = '' Then Continue;
    If (Attr And FileAttrDirectory) = 0 Then Exit;
    Found := False;
    I := 0;
    While IsoDirEntry(Lba, Size, I, Nm, ELba, ESize, EAttr, ETime) Do
    Begin
      If Nm = Comp Then
      Begin
        Lba := ELba; Size := ESize; Attr := EAttr; Time := ETime;
        Found := True;
        Break;
      End;
      Inc(I);
    End;
    If Not Found Then Exit;
  End;
  IsoLookup := True;
End;

{ Disque virtuel : chercher une entree par chemin complet }
Function RamFind(Path : String) : LongInt;
Var I : LongInt;
Begin
  RamFind := -1;
  For I := 0 To MaxRamFiles - 1 Do
    If RamFiles[I].Used And (RamFiles[I].Path = Path) Then
    Begin
      RamFind := I;
      Exit;
    End;
End;

Function RamNew(Path : String; Attr : LongInt) : LongInt;
Var I : LongInt;
Begin
  RamNew := -1;
  For I := 0 To MaxRamFiles - 1 Do
    If Not RamFiles[I].Used Then
    Begin
      RamFiles[I].Used := True;
      RamFiles[I].Deleted := False;
      RamFiles[I].Path := Path;
      RamFiles[I].Attr := Attr;
      RamFiles[I].Data := 0;
      RamFiles[I].Size := 0;
      RamFiles[I].Cap := 0;
      RamFiles[I].Time := DosNow;
      RamNew := I;
      Exit;
    End;
End;

{ Repertoire parent d'un chemin complet (C:\A\B -> C:\A ; C:\A -> C:\) }
Function ParentDir(Path : String) : String;
Var P : LongInt;
Begin
  P := Length(Path);
  While (P > 3) And (Path[P] <> '\') Do Dec(P);
  If P <= 3 Then ParentDir := Copy(Path, 1, 3) Else ParentDir := Copy(Path, 1, P - 1);
End;

Function BaseName(Path : String) : String;
Var P : LongInt;
Begin
  P := Length(Path);
  While (P > 0) And (Path[P] <> '\') Do Dec(P);
  BaseName := Copy(Path, P + 1, 255);
End;

Function IfsDrive(Path : String) : LongInt; Forward;
Function IfsStat(Path : String; Var Attr, Size, Time : LongInt) : LongInt; Forward;

{ ==================================================================== }
{ Partie 10b - Lecteur de disquettes A: (765, DMA, FAT12)              }
{ ==================================================================== }
{ Le lecteur A: (declare dans le CMOS, registre 10h) : controleur 765
  (ports 3F0h-3F7h, IRQ 6), DMA canal 2 par un tampon de 512 octets du
  tas du noyau (sous 16 Mo, sans traverser une page de 64 Ko) ; debit
  essaye a 500 kbit/s (1,44 Mo), puis 250 (720 Ko) et 300 (360 Ko),
  geometrie d'apres le BPB (pilote repris de Pasdows 95). Systeme de
  fichiers FAT12 (et FAT16) en lecture : repertoires, chaines de
  clusters ; un changement de disquette (ligne DSKCHG, port 3F7h) est
  detecte a chaque acces et le volume est relu. Les fichiers de A: sont
  vus par toutes les API de fichiers du noyau (CMD, sessions DOS). }

Var
  FdOk, FdMounted, FdIrqF, Fat16 : Boolean;
  FdRate, FdSpt, FdHeads, FdSecs, FdLastCyl, FdBuf, FdBlk : LongInt;
  FdRes : Array[0..6] Of LongInt;
  FlpSpc, FlpRes, FlpNFat, FlpRootN, FlpSpf, FlpRootLba, FlpDataLba, FlpClusN : LongInt;
  FlpFat, FlpSec, FlpSecLba : LongInt;      { FAT entiere ; secteur en cache }
  FlpLabel : String[11];
  FlpSerial : LongInt;

Procedure IrqFloppy; Interrupt;
Begin
  FdIrqF := True;
  Port[$20] := $20;
End;

Function FdWaitIrq : Boolean;
Var T : LongInt;
Begin
  T := Ticks + 150;
  While Not FdIrqF And (Ticks - T < 0) Do Idle;
  FdWaitIrq := FdIrqF;
  FdIrqF := False;
End;

Function FdOut(B : LongInt) : Boolean;
Var N : LongInt;
Begin
  FdOut := False;
  N := 0;
  While (Port[$3F4] And $C0) <> $80 Do
  Begin
    Inc(N);
    If N > 200000 Then Exit;
  End;
  Port[$3F5] := B;
  FdOut := True;
End;

Function FdIn : LongInt;
Var N : LongInt;
Begin
  FdIn := -1;
  N := 0;
  While (Port[$3F4] And $C0) <> $C0 Do
  Begin
    Inc(N);
    If N > 200000 Then Exit;
  End;
  FdIn := Port[$3F5];
End;

Procedure FdSense;
Begin
  FdOut($08);
  FdRes[0] := FdIn;
  FdRes[1] := FdIn;
End;

Procedure FdReset;
Var I : LongInt;
Begin
  FdIrqF := False;
  Port[$3F2] := 0;
  For I := 1 To 1000 Do Port[$80] := 0;
  Port[$3F2] := $1C;
  FdWaitIrq;
  For I := 1 To 4 Do FdSense;
  Port[$3F7] := FdRate;
  FdOut($03); FdOut($DF); FdOut($02);
  FdLastCyl := -1;
End;

Function FdSeek(C, H : LongInt) : Boolean;
Begin
  FdIrqF := False;
  If C = 0 Then
  Begin
    FdOut($07); FdOut(0);
  End
  Else
  Begin
    FdOut($0F); FdOut(H Shl 2); FdOut(C);
  End;
  FdWaitIrq;
  FdSense;
  FdSeek := (FdRes[0] And $C0) = 0;
  If (FdRes[0] And $C0) = 0 Then FdLastCyl := C Else FdLastCyl := -1;
End;

{ un secteur Lba lu par le tampon DMA }
Function FdXfer(Lba, Buf : LongInt) : Boolean;
Var C, H, S, T, I : LongInt;
Begin
  FdXfer := False;
  If (FdSpt <= 0) Or (FdHeads <= 0) Then Exit;
  C := Lba Div (FdSpt * FdHeads);
  H := (Lba Div FdSpt) Mod FdHeads;
  S := Lba Mod FdSpt + 1;
  For T := 1 To 3 Do
  Begin
    If FdLastCyl <> C Then FdSeek(C, H);
    { DMA canal 2 : 512 octets en FdBuf }
    Port[$0A] := 6;
    Port[$0C] := 0;
    Port[$0B] := $46;
    Port[$04] := FdBuf And $FF; Port[$04] := (FdBuf Shr 8) And $FF;
    Port[$81] := (FdBuf Shr 16) And $FF;
    Port[$05] := $FF; Port[$05] := 1;
    Port[$0A] := 2;
    FdIrqF := False;
    FdOut($E6);
    FdOut(H Shl 2);
    FdOut(C); FdOut(H); FdOut(S); FdOut(2);
    FdOut(FdSpt); FdOut($1B); FdOut($FF);
    FdWaitIrq;
    For I := 0 To 6 Do FdRes[I] := FdIn;
    If (FdRes[0] And $C0) = 0 Then
    Begin
      MoveMem(FdBuf, Buf, 512);
      FdXfer := True;
      Exit;
    End;
    FdReset;
  End;
End;

{ debits essayes : 500 kbit/s (1,44 Mo), 1 Mbit/s (2,88 Mo), 250 (720 Ko),
  300 (360 Ko) }
Function FdRate3(I : LongInt) : LongInt;
Begin
  If I = 0 Then FdRate3 := 0 Else If I = 1 Then FdRate3 := 3
  Else If I = 2 Then FdRate3 := 2 Else FdRate3 := 1;
End;

{ secteur 0 de la disquette : debit et geometrie ; False sans disquette }
Function FdProbe : Boolean;
Var I : LongInt;
Begin
  FdProbe := False;
  For I := 0 To 3 Do
  Begin
    FdRate := FdRate3(I);
    FdReset;
    FdSpt := 18; FdHeads := 2;
    FdSeek(0, 0);
    If FdXfer(0, FlpSec) Then
    Begin
      If (MemW[0:FlpSec + 11] = 512) And (MemW[0:FlpSec + 24] >= 8) And
         (MemW[0:FlpSec + 24] <= 36) And (MemW[0:FlpSec + 26] >= 1) And
         (MemW[0:FlpSec + 26] <= 2) Then
      Begin
        FdSpt := MemW[0:FlpSec + 24];
        FdHeads := MemW[0:FlpSec + 26];
        FdSecs := MemW[0:FlpSec + 19];
        FdProbe := True;
      End;
      Exit;
    End;
  End;
End;

Procedure FdInit;
Begin
  FdOk := (CmosRead($10) Shr 4) <> 0;
  FdMounted := False;
  If Not FdOk Then Exit;
  FdBlk := KAlloc(2048);
  FdBuf := (FdBlk + 511) And Not 511;
  If (FdBuf And $FFFF) > $FE00 Then FdBuf := FdBuf + 512;
  FlpSec := KAlloc(512);
  FlpFat := KAlloc(512 * 12);
  FlpSecLba := -1;
  FdRate := 0;
  SetGate($26, LongInt(@IrqFloppy));
  Port[$21] := Port[$21] And Not $40;
End;

{ monter la disquette : BPB et FAT }
Function FlpMount : Boolean;
Var I : LongInt;
Begin
  FlpMount := False;
  FdMounted := False;
  FlpSecLba := -1;
  If Not FdProbe Then Exit;
  FlpSpc := Mem[0:FlpSec + 13];
  FlpRes := MemW[0:FlpSec + 14];
  FlpNFat := Mem[0:FlpSec + 16];
  FlpRootN := MemW[0:FlpSec + 17];
  FlpSpf := MemW[0:FlpSec + 22];
  If (FlpSpc = 0) Or (FlpSpf = 0) Or (FlpSpf > 12) Then Exit;
  FlpLabel := '';
  For I := 0 To 10 Do FlpLabel := FlpLabel + Chr(Mem[0:FlpSec + 43 + I]);
  FlpSerial := MemL[0:FlpSec + 39];
  If Mem[0:FlpSec + 38] <> $29 Then
  Begin
    FlpLabel := ''; FlpSerial := 0;
  End;
  FlpRootLba := FlpRes + FlpNFat * FlpSpf;
  FlpDataLba := FlpRootLba + (FlpRootN * 32 + 511) Div 512;
  FlpClusN := (FdSecs - FlpDataLba) Div FlpSpc + 2;
  Fat16 := FlpClusN > 4085;
  For I := 0 To FlpSpf - 1 Do
    If Not FdXfer(FlpRes + I, FlpFat + I * 512) Then Exit;
  FdMounted := True;
  FlpMount := True;
End;

{ disquette changee (ligne DSKCHG) ou pas encore lue : la relire }
Function FlpReady : Boolean;
Begin
  FlpReady := False;
  If Not FdOk Then Exit;
  Port[$3F2] := $1C;
  If (Port[$3F7] And $80) <> 0 Then
  Begin
    FdMounted := False;
    FdSeek(1, 0);
    FdSeek(0, 0);
  End;
  If Not FdMounted Then FlpMount;
  FlpReady := FdMounted;
End;

Function FlpSector(Lba : LongInt) : LongInt;
Begin
  FlpSector := 0;
  If FlpSecLba <> Lba Then
  Begin
    FlpSecLba := -1;
    If Not FdXfer(Lba, FlpSec) Then Exit;
    FlpSecLba := Lba;
  End;
  FlpSector := FlpSec;
End;

Function FlpNext(C : LongInt) : LongInt;
Var O, V : LongInt;
Begin
  If Fat16 Then FlpNext := MemW[0:FlpFat + C * 2]
  Else
  Begin
    O := C * 3 Div 2;
    V := Mem[0:FlpFat + O] Or (Mem[0:FlpFat + O + 1] Shl 8);
    If (C And 1) <> 0 Then V := V Shr 4 Else V := V And $FFF;
    If V >= $FF8 Then V := $FFFF;
    FlpNext := V;
  End;
End;

{ entree Idx (32 octets) d'un repertoire (Clus 0 : racine) ; adresse
  ou 0 a la fin }
Function FlpDirEnt(Clus, Idx : LongInt) : LongInt;
Var Lba, N, C, A : LongInt;
Begin
  FlpDirEnt := 0;
  If Clus = 0 Then
  Begin
    If Idx >= FlpRootN Then Exit;
    Lba := FlpRootLba + Idx Div 16;
  End
  Else
  Begin
    N := Idx Div (16 * FlpSpc);
    C := Clus;
    While (N > 0) And (C >= 2) And (C < $FF0) Do
    Begin
      C := FlpNext(C);
      Dec(N);
    End;
    If (C < 2) Or (C >= $FF0) Then Exit;
    Lba := FlpDataLba + (C - 2) * FlpSpc + (Idx Div 16) Mod FlpSpc;
  End;
  A := FlpSector(Lba);
  If A = 0 Then Exit;
  A := A + (Idx Mod 16) * 32;
  If Mem[0:A] = 0 Then Exit;
  FlpDirEnt := A;
End;

Function FlpEntName(A : LongInt) : String;
Var N, E : String; I : LongInt;
Begin
  N := ''; E := '';
  For I := 0 To 7 Do If Mem[0:A + I] <> 32 Then N := N + Chr(Mem[0:A + I]);
  For I := 8 To 10 Do If Mem[0:A + I] <> 32 Then E := E + Chr(Mem[0:A + I]);
  If Mem[0:A] = 5 Then N[1] := Chr($E5);
  If E <> '' Then N := N + '.' + E;
  FlpEntName := N;
End;

{ entree utilisable (pas supprimee, pas d'etiquette ni de nom long) }
Function FlpEntOk(A : LongInt) : Boolean;
Begin
  FlpEntOk := (Mem[0:A] <> $E5) And ((Mem[0:A + 11] And 8) = 0);
End;

{ chercher A:\X\Y : cluster, attributs, taille, date ; Path complet }
Function FlpLookup(Path : String; Var Clus, Attr, Size, Time : LongInt) : Boolean;
Var Rest, Comp : String; P, I, A, C : LongInt; Found : Boolean;
Begin
  FlpLookup := False;
  If Not FlpReady Then Exit;
  Clus := 0; Attr := $10; Size := 0; Time := 0;
  Rest := Copy(Path, 4, 255);
  While Rest <> '' Do
  Begin
    P := Pos('\', Rest);
    If P > 0 Then
    Begin
      Comp := Copy(Rest, 1, P - 1);
      Rest := Copy(Rest, P + 1, 255);
    End
    Else
    Begin
      Comp := Rest;
      Rest := '';
    End;
    If Comp = '' Then Continue;
    If (Attr And $10) = 0 Then Exit;
    C := Clus;
    Found := False;
    I := 0;
    A := FlpDirEnt(C, I);
    While (A <> 0) And Not Found Do
    Begin
      If FlpEntOk(A) And (FlpEntName(A) = Comp) Then
      Begin
        Found := True;
        Clus := MemW[0:A + 26];
        Attr := Mem[0:A + 11];
        Size := MemL[0:A + 28];
        Time := (MemW[0:A + 24] Shl 16) Or MemW[0:A + 22];
      End
      Else
      Begin
        Inc(I);
        A := FlpDirEnt(C, I);
      End;
    End;
    If Not Found Then Exit;
  End;
  FlpLookup := True;
End;

Function FlpPath(Path : String) : Boolean;
Begin
  FlpPath := FdOk And (Length(Path) >= 2) And (Path[1] = 'A') And (Path[2] = ':');
End;

{ lire N octets du fichier (1er cluster Clus, taille Size) a Pos }
Function FlpRead(Clus, Size, P0, Buf, N : LongInt) : LongInt;
Var Got, CB, K, C, Ofs, Chunk, A, Lba : LongInt;
Begin
  FlpRead := -1;
  If Not FlpReady Then Exit;
  If P0 + N > Size Then N := Size - P0;
  Got := 0;
  CB := FlpSpc * 512;
  While Got < N Do
  Begin
    K := (P0 + Got) Div CB;
    C := Clus;
    While (K > 0) And (C >= 2) And (C < $FF0) Do
    Begin
      C := FlpNext(C);
      Dec(K);
    End;
    If (C < 2) Or (C >= $FF0) Then Break;
    Ofs := (P0 + Got) Mod CB;
    Lba := FlpDataLba + (C - 2) * FlpSpc + Ofs Div 512;
    A := FlpSector(Lba);
    If A = 0 Then Exit;
    Chunk := 512 - Ofs Mod 512;
    If Chunk > N - Got Then Chunk := N - Got;
    MoveMem(A + Ofs Mod 512, Buf + Got, Chunk);
    Got := Got + Chunk;
  End;
  FlpRead := Got;
End;

{ Existence d'un chemin (volume IFS, ou disque virtuel puis CD-ROM) }
Function PathInfo(Path : String; Var Attr, Size, Time, Lba, RamIdx : LongInt) : Boolean;
Var R : LongInt;
Begin
  PathInfo := False;
  RamIdx := -1; Lba := 0;
  If FlpPath(Path) Then
  Begin
    RamIdx := -3;
    PathInfo := FlpLookup(Path, Lba, Attr, Size, Time);
    Exit;
  End;
  If IfsDrive(Path) >= 0 Then
  Begin
    RamIdx := -2;
    PathInfo := IfsStat(Path, Attr, Size, Time) = 0;
    Exit;
  End;
  If Length(Path) = 3 Then
  Begin
    Attr := FileAttrDirectory; Size := 0; Time := 0; Lba := RootLba;
    PathInfo := True;
    Exit;
  End;
  R := RamFind(Path);
  If R >= 0 Then
  Begin
    If RamFiles[R].Deleted Then Exit;
    RamIdx := R;
    Attr := RamFiles[R].Attr; Size := RamFiles[R].Size; Time := RamFiles[R].Time;
    PathInfo := True;
    Exit;
  End;
  PathInfo := IsoLookup(Path, Lba, Size, Attr, Time);
End;

Function IsDir(Path : String) : Boolean;
Var A, S, T, L, R : LongInt;
Begin
  IsDir := PathInfo(Path, A, S, T, L, R) And ((A And FileAttrDirectory) <> 0);
End;

{ Comparaison avec un masque DOS (* et ?) }
Function MatchMask(Name, Mask : String) : Boolean;
Var N, M : String; PN, PM : LongInt;

  Function Glob(S, P : String) : Boolean;
  Var I, J, StarI, StarJ : LongInt;
  Begin
    I := 1; J := 1; StarI := 0; StarJ := 0;
    While I <= Length(S) Do
    Begin
      If (J <= Length(P)) And ((P[J] = '?') Or (P[J] = S[I])) Then
      Begin
        Inc(I); Inc(J);
      End
      Else If (J <= Length(P)) And (P[J] = '*') Then
      Begin
        StarJ := J; StarI := I; Inc(J);
      End
      Else If StarJ > 0 Then
      Begin
        J := StarJ + 1; Inc(StarI); I := StarI;
      End
      Else
      Begin
        Glob := False;
        Exit;
      End;
    End;
    While (J <= Length(P)) And (P[J] = '*') Do Inc(J);
    Glob := J > Length(P);
  End;

Begin
  N := UpStr(Name); M := UpStr(Mask);
  If (M = '*.*') Or (M = '*') Or (M = '') Then
  Begin
    MatchMask := True;
    Exit;
  End;
  { NOM.EXT : comparer nom et extension separement (comme DOS) }
  PN := Pos('.', N); PM := Pos('.', M);
  If (PM > 0) And (N <> '.') And (N <> '..') Then
  Begin
    If PN = 0 Then
      MatchMask := Glob(N, Copy(M, 1, PM - 1)) And Glob('', Copy(M, PM + 1, 255))
    Else
      MatchMask := Glob(Copy(N, 1, PN - 1), Copy(M, 1, PM - 1)) And
                   Glob(Copy(N, PN + 1, 255), Copy(M, PM + 1, 255));
  End
  Else
    MatchMask := Glob(N, M);
End;

{ Agrandir le contenu d'un fichier du disque virtuel }
Function RamReserve(R, NewSize : LongInt) : Boolean;
Var NewCap, NewData : LongInt;
Begin
  RamReserve := True;
  If NewSize <= RamFiles[R].Cap Then Exit;
  NewCap := RamFiles[R].Cap * 2;
  If NewCap < NewSize Then NewCap := NewSize;
  If NewCap < 1024 Then NewCap := 1024;
  NewData := KAlloc(NewCap);
  If NewData = 0 Then
  Begin
    RamReserve := False;
    Exit;
  End;
  FillMem(NewData, NewCap, 0);
  If RamFiles[R].Data <> 0 Then
  Begin
    MoveMem(RamFiles[R].Data, NewData, RamFiles[R].Size);
    KFree(RamFiles[R].Data);
  End;
  RamFiles[R].Data := NewData;
  RamFiles[R].Cap := NewCap;
End;

{ ==================================================================== }
{ Partie 11 - Handles, chemins et repertoire courant                   }
{ ==================================================================== }

Function CurDir : String;
Begin
  If CurProc >= 0 Then CurDir := Procs[CurProc].CurDir Else CurDir := KernelDir;
End;

{ Chemin complet en majuscules : C:\REP\FICHIER (unite, ., .., / acceptes) }
Function FullPathX(Name : String; Up : Boolean) : String;
Var Base, Res, Comp : String; P : LongInt;
Begin
  If Up Then Name := UpStr(Trim(Name))
  Else
  Begin
    Name := Trim(Name);
    If (Length(Name) >= 2) And (Name[2] = ':') Then Name[1] := UpCase(Name[1]);
  End;
  For P := 1 To Length(Name) Do If Name[P] = '/' Then Name[P] := '\';
  If (Length(Name) >= 2) And (Name[2] = ':') Then
  Begin
    If Name[1] = Copy(CurDir, 1, 1) Then Base := CurDir Else Base := Name[1] + ':\';
    Name := Copy(Name, 3, 255);
  End
  Else
    Base := CurDir;
  If (Length(Name) > 0) And (Name[1] = '\') Then
  Begin
    Res := Copy(Base, 1, 3);
    Name := Copy(Name, 2, 255);
  End
  Else
    Res := Base;
  While Name <> '' Do
  Begin
    P := Pos('\', Name);
    If P > 0 Then
    Begin
      Comp := Copy(Name, 1, P - 1);
      Name := Copy(Name, P + 1, 255);
    End
    Else
    Begin
      Comp := Name; Name := '';
    End;
    If (Comp = '') Or (Comp = '.') Then Continue;
    If Comp = '..' Then
    Begin
      Res := ParentDir(Res);
      Continue;
    End;
    If Res[Length(Res)] <> '\' Then Res := Res + '\';
    Res := Res + Comp;
  End;
  FullPathX := Res;
End;

Function FullPath(Name : String) : String;
Begin
  FullPath := FullPathX(Name, True);
End;

{ Unite d'un volume IFS monte (3 = D:...), ou -1 }
Function IfsDrive(Path : String) : LongInt;
Var D : LongInt;
Begin
  IfsDrive := -1;
  If (Length(Path) >= 2) And (Path[2] = ':') Then
  Begin
    D := Ord(UpCase(Path[1])) - 65;
    { C: aussi, quand le systeme a demarre d'un disque dur (HPFS) }
    If (D >= 2) And (D <= 25) Then
      If IfsVols[D].Mounted Then IfsDrive := D;
  End;
End;

{ Chemin complet : en majuscules, sauf sur un volume IFS (HPFS conserve
  la casse des noms) }
Function FullPathOf(A : LongInt) : String;
Var S, P : String;
Begin
  S := PStr(A);
  P := FullPath(S);
  If IfsDrive(P) >= 0 Then P := FullPathX(S, False);
  FullPathOf := P;
End;

{ Unite C: (CD-ROM + disque virtuel) et volumes IFS montes }
Function DriveOk(Path : String) : Boolean;
Begin
  DriveOk := ((Length(Path) >= 3) And (Path[1] = 'C')) Or (IfsDrive(Path) >= 0) Or
             ((Length(Path) >= 3) And FlpPath(Path) And FlpReady);
End;

Function FileSlot(H : LongInt) : LongInt;
Begin
  FileSlot := -1;
  If (H >= HFileBase) And (H < HFileBase + MaxFiles) Then
    If Files[H - HFileBase].Used Then FileSlot := H - HFileBase;
End;

Function NewFileSlot : LongInt;
Var I : LongInt;
Begin
  NewFileSlot := -1;
  For I := 0 To MaxFiles - 1 Do
    If Not Files[I].Used Then
    Begin
      Files[I].Used := True;
      Files[I].IsRam := False; Files[I].IsNul := False; Files[I].IsCon := False;
      Files[I].IsPrn := False; Files[I].PrnIdx := 0;
      Files[I].RamIdx := -1; Files[I].Lba := 0; Files[I].Size := 0; Files[I].Pos := 0;
      Files[I].CanWrite := False; Files[I].Time := 0;
      Files[I].Owner := CurProc;
      Files[I].Name := '';
      Files[I].IsIfs := False;
      Files[I].IsFlp := False;
      NewFileSlot := I;
      Exit;
    End;
End;

Procedure SessSwap(NS : LongInt); Forward;

Procedure ConWrite0(Buf, N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do ConPutRaw(Chr(Mem[0:Buf + I]));
  UpdateCursor;
End;

{ un processus passe dans une autre session (programme de PM lance depuis
  une invite de commandes) ecrit toujours dans la console de la session
  ou il a ete lance }
Procedure ConWrite(Buf, N : LongInt);
Var Old : LongInt;
Begin
  If (CurProc >= 0) And (Procs[CurProc].ConSess <> CurSess) And SUsed[Procs[CurProc].ConSess] Then
  Begin
    Old := CurSess;
    asm
      cli
    end;
    SessSwap(Procs[CurProc].ConSess);
    asm
      sti
    end;
    ConWrite0(Buf, N);
    asm
      cli
    end;
    SessSwap(Old);
    asm
      sti
    end;
  End
  Else ConWrite0(Buf, N);
End;

{ ==================================================================== }
{ Partie 11b - Systemes de fichiers installables (IFS)                 }
{ ==================================================================== }
{ Les fichiers des unites D: a Z: montees par un pilote IFS (HPFS.IFS)
  sont confies aux points d'entree FS_* du pilote, appeles selon la
  convention _System (parametres de droite a gauche, pile nettoyee par
  l'appelant). Les structures passees sont decrites dans DLL\HPFS.PAS. }

Var
  IfsArg   : Array[0..15] Of LongInt;
  IfsName  : Array[0..263] Of Byte;    { chemin ASCIIZ }
  IfsName2 : Array[0..263] Of Byte;
  IfsCd    : Array[0..271] Of Byte;    { CDFSI }
  IfsCdd   : Array[0..15] Of Byte;     { CDFSD }
  IfsInfo  : Array[0..511] Of Byte;
  IfsCnt   : LongInt;
  IfsAct   : LongInt;

{ Appeler le point d'entree Fn avec les N parametres de IfsArg }
Function IfsCall(Fn, N : LongInt) : LongInt;
Var R, A : LongInt;
Begin
  R := 1;
  A := LongInt(@IfsArg);
  If Fn <> 0 Then
  Begin
    asm
      push ebx
      push esi
      push edi
      mov ecx,N
      mov esi,A
    @lp:
      cmp ecx,0
      je @go
      dec ecx
      mov eax,ecx
      shl eax,2
      add eax,esi
      mov edx,[eax]
      push edx
      jmp @lp
    @go:
      mov eax,Fn
      call eax
      mov ecx,N
      shl ecx,2
      add esp,ecx
      mov R,eax
      pop edi
      pop esi
      pop ebx
    end;
  End;
  IfsCall := R;
End;

Procedure IfsArgs4(A0, A1, A2, A3 : LongInt);
Begin
  IfsArg[0] := A0; IfsArg[1] := A1; IfsArg[2] := A2; IfsArg[3] := A3;
End;

Procedure IfsArgs8(A4, A5, A6, A7 : LongInt);
Begin
  IfsArg[4] := A4; IfsArg[5] := A5; IfsArg[6] := A6; IfsArg[7] := A7;
End;

{ Preparer le chemin et le CDFSI d'une operation sur l'unite D }
Procedure IfsPrep(D : LongInt; Path : String);
Begin
  PutPStr(LongInt(@IfsName), Path, 260);
  FillMem(LongInt(@IfsCd), 272, 0);
  MemL[0:LongInt(@IfsCd)] := D;
  MemL[0:LongInt(@IfsCd) + 4] := -1;
  If Copy(CurDir, 1, 1) = Copy(Path, 1, 1) Then PutPStr(LongInt(@IfsCd) + 12, CurDir, 260)
  Else PutPStr(LongInt(@IfsCd) + 12, Copy(Path, 1, 2) + '\', 260);
  FillMem(LongInt(@IfsCdd), 16, 0);
End;

Function IfsOf(D : LongInt) : LongInt;
Begin
  IfsOf := IfsVols[D].Ifs;
End;

{ Attributs, taille et date (DOS) d'un chemin d'un volume IFS ; rend le
  code d'erreur OS/2 }
Function IfsStat(Path : String; Var Attr, Size, Time : LongInt) : LongInt;
Var D, R, A : LongInt;
Begin
  D := IfsDrive(Path);
  IfsPrep(D, Path);
  A := LongInt(@IfsInfo);
  IfsArgs4(0, LongInt(@IfsCd), LongInt(@IfsCdd), LongInt(@IfsName));
  IfsArgs8(-1, 1, A, 24);
  R := IfsCall(Ifss[IfsOf(D)].FPathInfo, 8);
  If R = 0 Then
  Begin
    Attr := MemL[0:A + 20];
    Size := MemL[0:A + 12];
    Time := (MemW[0:A + 8] Shl 16) Or MemW[0:A + 10];
  End;
  IfsStat := R;
End;

{ Operation sur un chemin : FS_DELETE, FS_RMDIR (4 parametres) }
Function IfsPathOp(Fn : LongInt; Path : String) : LongInt;
Var D : LongInt;
Begin
  D := IfsDrive(Path);
  IfsPrep(D, Path);
  IfsArgs4(LongInt(@IfsCd), LongInt(@IfsCdd), LongInt(@IfsName), -1);
  IfsPathOp := IfsCall(Fn, 4);
End;

{ Ouvrir ou creer un fichier d'un volume IFS dans l'entree H de Files }
Function IfsOpen(H : LongInt; Path : String; Access, Share, Disp : LongInt) : LongInt;
Var D, I, R, Mode, Flag : LongInt; Exists : Boolean;
Begin
  D := IfsDrive(Path);
  I := IfsOf(D);
  Files[H].IsIfs := True;
  Files[H].IfsDrv := D;
  FillMem(LongInt(@Files[H].Sffsi), 64, 0);
  FillMem(LongInt(@Files[H].Sffsd), 32, 0);
  MemL[0:LongInt(@Files[H].Sffsi) + 4] := D;
  If CurProc >= 0 Then MemL[0:LongInt(@Files[H].Sffsi) + 32] := Procs[CurProc].Serial
  Else MemL[0:LongInt(@Files[H].Sffsi) + 32] := 1;
  { acces et partage OS/2 }
  If ((Access And $40000000) <> 0) And ((Access And $80000000) <> 0) Then Mode := 2
  Else If (Access And $40000000) <> 0 Then Mode := 1
  Else Mode := 0;
  Case Share And 3 Of
    0 : Mode := Mode Or $10;
    1 : Mode := Mode Or $20;
    2 : Mode := Mode Or $30;
  Else
    Mode := Mode Or $40;
  End;
  MemL[0:LongInt(@Files[H].Sffsi)] := Mode;
  Case Disp Of
    1 : Flag := $10;          { CREATE_NEW }
    2 : Flag := $12;          { CREATE_ALWAYS }
    3 : Flag := $01;          { OPEN_EXISTING }
    4 : Flag := $11;          { OPEN_ALWAYS }
    5 : Flag := $02;          { TRUNCATE_EXISTING }
  Else
    Flag := $01;
  End;
  IfsPrep(D, Path);
  IfsArgs4(LongInt(@IfsCd), LongInt(@IfsCdd), LongInt(@IfsName), -1);
  IfsArgs8(LongInt(@Files[H].Sffsi), LongInt(@Files[H].Sffsd), Mode, Flag);
  IfsArg[8] := LongInt(@IfsAct);
  IfsArg[9] := 0;
  IfsArg[10] := 0;
  IfsArg[11] := LongInt(@IfsCnt);
  R := IfsCall(Ifss[I].FOpen, 12);
  If R = 110 Then
  Begin
    { ERROR_OPEN_FAILED : le fichier existe (CREATE_NEW) ou n'existe pas }
    If Disp = 1 Then R := ErrFileExists Else R := ErrFileNotFound;
  End;
  If R = 0 Then
  Begin
    Files[H].CanWrite := (Mode And 7) <> 0;
    Files[H].Time := MemL[0:LongInt(@Files[H].Sffsi) + 16];
  End
  Else
    Files[H].IsIfs := False;
  IfsOpen := R;
End;

Function IfsClose(F : LongInt) : LongInt;
Var I, D, R : LongInt;
Begin
  D := Files[F].IfsDrv;
  I := IfsOf(D);
  IfsArgs4(2, 0, LongInt(@Files[F].Sffsi), LongInt(@Files[F].Sffsd));
  R := IfsCall(Ifss[I].FClose, 4);
  IfsArg[0] := D; IfsArg[1] := 0;
  IfsCall(Ifss[I].FFlush, 2);
  Files[F].IsIfs := False;
  IfsClose := R;
End;

{ FS_READ / FS_WRITE : N octets ; rend le code et le nombre traite }
Function IfsRW(F, Buf, N : LongInt; Wr : Boolean; Var Done : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  I := IfsOf(Files[F].IfsDrv);
  IfsCnt := N;
  IfsArgs4(LongInt(@Files[F].Sffsi), LongInt(@Files[F].Sffsd), Buf, LongInt(@IfsCnt));
  IfsArg[4] := 0;
  If Wr Then R := IfsCall(Ifss[I].FWrite, 5) Else R := IfsCall(Ifss[I].FRead, 5);
  Done := IfsCnt;
  IfsRW := R;
End;

{ Fermer les fichiers et recherches IFS d'un processus termine }
Procedure IfsProcessExit(Pid : LongInt);
Var I, J, Serial : LongInt;
Begin
  For I := 0 To MaxFiles - 1 Do
    If Files[I].Used And (Files[I].Owner = Pid) And Files[I].IsIfs Then IfsClose(I);
  For I := 0 To MaxFinds - 1 Do
    If Finds[I].Used And (Finds[I].Owner = Pid) And Finds[I].IsIfs Then
    Begin
      IfsArg[0] := LongInt(@Finds[I].Fsfsi); IfsArg[1] := LongInt(@Finds[I].Fsfsd);
      IfsCall(Ifss[IfsOf(Finds[I].IfsDrv)].FFindClose, 2);
      Finds[I].IsIfs := False;
    End;
  If Pid >= 0 Then Serial := Procs[Pid].Serial Else Serial := 1;
  For J := 0 To NIfs - 1 Do
  Begin
    IfsArg[0] := 0; IfsArg[1] := Serial; IfsArg[2] := 0;
    IfsCall(Ifss[J].FExit, 3);
  End;
End;

{ FSH_DOVOLIO(Op, fAllowed, hVPB, pData, pcSec, iSec) : service offert
  aux pilotes IFS : lire (Op bit 0 = 0) ou ecrire *pcSec secteurs du
  volume hVPB a partir du secteur iSec ; *pcSec <- secteurs traites. }
Function FSH_DoVolIO(Op, Allowed, HVpb, PData, PcSec, ISec : LongInt) : LongInt;
Var R, N : LongInt;
Begin
  If (HVpb < 0) Or (HVpb > 25) Then R := ErrInvalidDrive
  Else If IfsVols[HVpb].Blk < 0 Then R := ErrInvalidDrive
  Else
  Begin
    N := MemL[0:PcSec];
    R := BlkIO(IfsVols[HVpb].Blk, Op, ISec, N, PData);
    If R <> 0 Then MemL[0:PcSec] := 0;
  End;
  FSH_DoVolIO := R;
End;

{ ==================================================================== }
{ Partie 12 - Couche API (exportee sous le nom DOSCALLS.DLL)           }
{ ==================================================================== }
{ Ces procedures sont appelees par le runtime de OS2PC (dans le noyau et
  dans les programmes). Les noms et l'ordre des parametres sont ceux de
  l'API Win32 que le runtime utilise ; les pointeurs sont des adresses
  lineaires (LongInt). }

{ --- Processus et memoire --- }

Function GetStdHandle(N : LongInt) : LongInt;
Begin
  Case N Of
    -10 : GetStdHandle := HStdIn;
    -11 : GetStdHandle := HStdOut;
    -12 : GetStdHandle := HStdErr;
  Else
    GetStdHandle := -1;
  End;
End;

{ SetStdHandle(N, H) : rediriger la sortie standard (N = -11) du
  processus vers le fichier H (HStdOut : retour a la console). Les
  processus lances ensuite heritent de la redirection. }
Function SetStdHandle(N, H : LongInt) : LongInt;
Begin
  SetStdHandle := 0;
  If (N <> -11) Or (CurProc < 0) Then
  Begin
    LastError := ErrInvalidHandle;
    Exit;
  End;
  If (H = HStdOut) Or (H = 0) Then Procs[CurProc].StdOutH := 0
  Else If FileSlot(H) >= 0 Then Procs[CurProc].StdOutH := H
  Else
  Begin
    LastError := ErrInvalidHandle;
    Exit;
  End;
  SetStdHandle := 1;
End;

Function GetProcessHeap : LongInt;
Begin
  GetProcessHeap := 1;
End;

Function HeapAlloc(Heap, Flags, Size : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := KAlloc(Size);
  If A <> 0 Then
  Begin
    { tas 2 : memoire partagee (DLL, DosAllocSharedMem), jamais liberee a
      la fin du processus ; sinon liberee a la fin du processus }
    If Heap = 2 Then MemL[0:A - 8] := -1 Else MemL[0:A - 8] := CurProc;
    If (Flags And 8) <> 0 Then FillMem(A, Size, 0);
  End;
  HeapAlloc := A;
End;

Function HeapFree(Heap, Flags, A : LongInt) : LongInt;
Begin
  If A <> 0 Then KFree(A);
  HeapFree := 1;
End;

Function HeapSize(Heap, Flags, A : LongInt) : LongInt;
Begin
  HeapSize := KBlockSize(A);
End;

Function SetUnhandledExceptionFilter(F : LongInt) : LongInt;
Begin
  If CurProc >= 0 Then
  Begin
    SetUnhandledExceptionFilter := Procs[CurProc].Filter;
    Procs[CurProc].Filter := F;
  End
  Else
  Begin
    SetUnhandledExceptionFilter := ExcFilter;
    ExcFilter := F;
  End;
End;

Function GetLastError : LongInt;
Begin
  GetLastError := LastError;
End;

Function GetVersion : LongInt;
Begin
  { comme OS/2 2.x : DosVersion rend 20.00 }
  GetVersion := 20;
End;

Function ModuleHandleByName(Name : String) : LongInt; Forward;

Function GetModuleHandleA(Name : LongInt) : LongInt;
Begin
  If Name <> 0 Then
    GetModuleHandleA := ModuleHandleByName(PStr(Name))
  Else If CurProc >= 0 Then GetModuleHandleA := ProcWinBase
  Else GetModuleHandleA := $00100000;
End;

Function GetCommandLineA : LongInt;
Begin
  If CurProc >= 0 Then GetCommandLineA := Procs[CurProc].CmdBuf
  Else GetCommandLineA := LongInt(@KCmdLine);
End;

Function GetEnvironmentStringsA : LongInt;
Begin
  GetEnvironmentStringsA := LongInt(@EnvBlock);
End;

{ Chercher NOM= dans l'environnement ; rend l'adresse de la valeur ou 0 }
Function EnvFind(Name : String) : LongInt;
Var P, Q : LongInt; S : String;
Begin
  EnvFind := 0;
  P := 0;
  While (P < EnvSize) And (EnvBlock[P] <> 0) Do
  Begin
    S := PStr(LongInt(@EnvBlock) + P);
    Q := Pos('=', S);
    If (Q > 0) And (UpStr(Copy(S, 1, Q - 1)) = UpStr(Name)) Then
    Begin
      EnvFind := LongInt(@EnvBlock) + P + Q;
      Exit;
    End;
    P := P + Length(S) + 1;
    { une variable de plus de 255 caracteres }
    While (P < EnvSize) And (EnvBlock[P - 1] <> 0) Do Inc(P);
  End;
End;

Function GetEnvironmentVariableA(Name, Buf, Size : LongInt) : LongInt;
Var A : LongInt; S : String;
Begin
  A := EnvFind(PStr(Name));
  If A = 0 Then
  Begin
    LastError := 203;
    GetEnvironmentVariableA := 0;
    Exit;
  End;
  S := PStr(A);
  If Length(S) + 1 > Size Then
    GetEnvironmentVariableA := Length(S) + 1
  Else
  Begin
    PutPStr(Buf, S, Size);
    GetEnvironmentVariableA := Length(S);
  End;
End;

{ Definir NOM=VALEUR dans l'environnement (CONFIG.SYS) }
Procedure EnvSet(AName, AValue : String);
Var P, Q, L : LongInt; S, Item, Name, Value : String;
Begin
  { copies locales : les parametres peuvent designer l'anneau des
    resultats de fonctions chaine du runtime }
  Name := AName; Value := AValue;
  { retirer l'ancienne valeur }
  P := 0;
  While (P < EnvSize) And (EnvBlock[P] <> 0) Do
  Begin
    S := PStr(LongInt(@EnvBlock) + P);
    L := Length(S) + 1;
    Q := Pos('=', S);
    If (Q > 0) And (UpStr(Copy(S, 1, Q - 1)) = UpStr(Name)) Then
    Begin
      MoveMem(LongInt(@EnvBlock) + P + L, LongInt(@EnvBlock) + P, EnvSize - P - L);
      EnvSize := EnvSize - L;
    End
    Else
      P := P + L;
  End;
  If Value = '' Then Exit;
  Item := UpStr(Name) + '=' + Value;
  If EnvSize + Length(Item) + 2 > SizeOf(EnvBlock) Then Exit;
  PutPStr(LongInt(@EnvBlock) + EnvSize - 1, Item, 256);
  EnvSize := EnvSize + Length(Item) + 1;
  EnvBlock[EnvSize - 1] := 0;
End;

{ --- Temps --- }

Function GetTickCount : LongInt;
Begin
  GetTickCount := Ticks * 10;
End;

Procedure Sleep(Ms : LongInt);
Begin
  KDelay(Ms);
End;

Procedure GetLocalTime(P : LongInt);
Begin
  ReadRtc;
  MemW[0:P] := RtcYear;
  MemW[0:P + 2] := RtcMonth;
  MemW[0:P + 4] := RtcDow;
  MemW[0:P + 6] := RtcDay;
  MemW[0:P + 8] := RtcHour;
  MemW[0:P + 10] := RtcMin;
  MemW[0:P + 12] := RtcSec;
  MemW[0:P + 14] := (Ticks Mod 100) * 10;
End;

Function ToBcd(V : LongInt) : LongInt;
Begin
  If (CmosRead($0B) And 4) <> 0 Then ToBcd := V
  Else ToBcd := ((V Div 10) Shl 4) Or (V Mod 10);
End;

Procedure CmosWrite(R, V : LongInt);
Begin
  Port[$70] := R;
  Port[$71] := V;
End;

Function SetLocalTime(P : LongInt) : LongInt;
Var Y : LongInt;
Begin
  Y := MemW[0:P];
  If (Y >= 1980) And (MemW[0:P + 2] >= 1) And (MemW[0:P + 2] <= 12) And
     (MemW[0:P + 6] >= 1) And (MemW[0:P + 6] <= 31) Then
  Begin
    CmosWrite($09, ToBcd(Y Mod 100));
    CmosWrite($08, ToBcd(MemW[0:P + 2]));
    CmosWrite($07, ToBcd(MemW[0:P + 6]));
  End;
  If (MemW[0:P + 8] <= 23) And (MemW[0:P + 10] <= 59) And (MemW[0:P + 12] <= 59) Then
  Begin
    CmosWrite($04, ToBcd(MemW[0:P + 8]));
    CmosWrite($02, ToBcd(MemW[0:P + 10]));
    CmosWrite($00, ToBcd(MemW[0:P + 12]));
  End;
  SetLocalTime := 1;
End;

{ Les FILETIME du noyau contiennent directement la date et l'heure DOS
  (mot double bas) et la signature 'OS2T' (mot double haut). }
Function FileTimeToLocalFileTime(Src, Dst : LongInt) : LongInt;
Var A, B : LongInt;
Begin
  A := MemL[0:Src]; B := MemL[0:Src + 4];
  MemL[0:Dst] := A; MemL[0:Dst + 4] := B;
  FileTimeToLocalFileTime := 1;
End;

Function LocalFileTimeToFileTime(Src, Dst : LongInt) : LongInt;
Begin
  LocalFileTimeToFileTime := FileTimeToLocalFileTime(Src, Dst);
End;

Function FileTimeToDosDateTime(Ft, PDate, PTime : LongInt) : LongInt;
Var T : LongInt;
Begin
  T := MemL[0:Ft];
  MemW[0:PDate] := (T Shr 16) And $FFFF;
  MemW[0:PTime] := T And $FFFF;
  FileTimeToDosDateTime := 1;
End;

Function DosDateTimeToFileTime(DDate, DTime, Ft : LongInt) : LongInt;
Begin
  MemL[0:Ft] := ((DDate And $FFFF) Shl 16) Or (DTime And $FFFF);
  MemL[0:Ft + 4] := $5432534F;
  DosDateTimeToFileTime := 1;
End;

{ --- Console --- }

Function SetConsoleTextAttribute(H, Attr : LongInt) : LongInt;
Begin
  TextAttr := Attr And $FF;
  SetConsoleTextAttribute := 1;
End;

Function SetConsoleCursorPosition(H, Coord : LongInt) : LongInt;
Begin
  CurCol := Coord And $FFFF;
  CurRow := (Coord Shr 16) And $FFFF;
  If CurCol >= ScrCols Then CurCol := ScrCols - 1;
  If CurRow >= ConRows Then CurRow := ConRows - 1;
  UpdateCursor;
  SetConsoleCursorPosition := 1;
End;

Function GetConsoleScreenBufferInfo(H, P : LongInt) : LongInt;
Begin
  MemW[0:P] := ScrCols;       MemW[0:P + 2] := ConRows;
  MemW[0:P + 4] := CurCol;    MemW[0:P + 6] := CurRow;
  MemW[0:P + 8] := TextAttr;
  MemW[0:P + 10] := 0;        MemW[0:P + 12] := 0;
  MemW[0:P + 14] := ScrCols - 1; MemW[0:P + 16] := ConRows - 1;
  MemW[0:P + 18] := ScrCols;  MemW[0:P + 20] := ConRows;
  GetConsoleScreenBufferInfo := 1;
End;

{ Hauteur de la zone de defilement de la console (80 colonnes, 1 a 25
  lignes) : les lignes du bas restent libres pour l'application (zone des
  touches de fonction de FKA.DLL). Retablie a la fin du processus. }
Function SetConsoleScreenBufferSize(H, Size : LongInt) : LongInt;
Var Rows : LongInt;
Begin
  SetConsoleScreenBufferSize := 0;
  Rows := (Size Shr 16) And $FFFF;
  If (Rows < 1) Or (Rows > ScrRows) Or ((Size And $FFFF) <> ScrCols) Then
  Begin
    LastError := ErrInvalidParam;
    Exit;
  End;
  ConRows := Rows;
  If Rows < ScrRows Then ConRowsOwner := CurProc Else ConRowsOwner := -2;
  While CurRow >= ConRows Do
  Begin
    ScrollUp;
    Dec(CurRow);
  End;
  UpdateCursor;
  SetConsoleScreenBufferSize := 1;
End;

Function FillConsoleOutputCharacterA(H, Ch, Len, Coord, PWritten : LongInt) : LongInt;
Var P, I : LongInt;
Begin
  P := ((Coord Shr 16) And $FFFF) * ScrCols + (Coord And $FFFF);
  I := 0;
  While (I < Len) And (P + I < ScrCols * ScrRows) Do
  Begin
    Mem[0:VideoBase + (P + I) * 2] := Ch And $FF;
    Inc(I);
  End;
  If PWritten <> 0 Then MemL[0:PWritten] := I;
  FillConsoleOutputCharacterA := 1;
End;

Function FillConsoleOutputAttribute(H, Attr, Len, Coord, PWritten : LongInt) : LongInt;
Var P, I : LongInt;
Begin
  P := ((Coord Shr 16) And $FFFF) * ScrCols + (Coord And $FFFF);
  I := 0;
  While (I < Len) And (P + I < ScrCols * ScrRows) Do
  Begin
    Mem[0:VideoBase + (P + I) * 2 + 1] := Attr And $FF;
    Inc(I);
  End;
  If PWritten <> 0 Then MemL[0:PWritten] := I;
  FillConsoleOutputAttribute := 1;
End;

{ Deplacer un rectangle de l'ecran ; les cellules liberees prennent Fill }
Function ScrollConsoleScreenBufferA(H, PRect, PClip, Dest, PFill : LongInt) : LongInt;
Var L, T, R, B, DX, DY, W, Hh, X, Y, Tmp, FillCell, SX, SY : LongInt;
Begin
  ScrollConsoleScreenBufferA := 1;
  L := MemW[0:PRect]; T := MemW[0:PRect + 2];
  R := MemW[0:PRect + 4]; B := MemW[0:PRect + 6];
  If R >= ScrCols Then R := ScrCols - 1;
  If B >= ScrRows Then B := ScrRows - 1;
  DX := Dest And $FFFF; DY := (Dest Shr 16) And $FFFF;
  W := R - L + 1; Hh := B - T + 1;
  If (W <= 0) Or (Hh <= 0) Then Exit;
  FillCell := (MemW[0:PFill + 2] Shl 8) Or (MemW[0:PFill] And $FF);
  Tmp := KAlloc(W * Hh * 2);
  If Tmp = 0 Then Exit;
  For Y := 0 To Hh - 1 Do
    MoveMem(VideoBase + ((T + Y) * ScrCols + L) * 2, Tmp + Y * W * 2, W * 2);
  { liberer la source }
  For Y := T To B Do
    For X := L To R Do
      MemW[0:VideoBase + (Y * ScrCols + X) * 2] := FillCell;
  { recopier a la destination }
  For Y := 0 To Hh - 1 Do
  Begin
    SY := DY + Y;
    If (SY >= 0) And (SY < ScrRows) Then
      For X := 0 To W - 1 Do
      Begin
        SX := DX + X;
        If (SX >= 0) And (SX < ScrCols) Then
          MemW[0:VideoBase + (SY * ScrCols + SX) * 2] := MemW[0:Tmp + (Y * W + X) * 2];
      End;
  End;
  KFree(Tmp);
End;

Function GetConsoleMode(H, PMode : LongInt) : LongInt;
Begin
  If PMode <> 0 Then MemL[0:PMode] := 7;
  GetConsoleMode := 1;
End;

Function SetConsoleMode(H, Mode : LongInt) : LongInt;
Begin
  SetConsoleMode := 1;
End;

Function FlushConsoleInputBuffer(H : LongInt) : LongInt;
Begin
  KbdTail := KbdHead;
  FlushConsoleInputBuffer := 1;
End;

{ Code de touche virtuelle Win32 d'apres le code de balayage }
Function VirtKey(Sc, Ch : LongInt) : LongInt;
Begin
  Case Sc Of
    $48 : VirtKey := $26; $50 : VirtKey := $28; $4B : VirtKey := $25; $4D : VirtKey := $27;
    $47 : VirtKey := $24; $4F : VirtKey := $23; $49 : VirtKey := $21; $51 : VirtKey := $22;
    $52 : VirtKey := $2D; $53 : VirtKey := $2E; $1C : VirtKey := $0D; $01 : VirtKey := $1B;
    $0E : VirtKey := $08; $0F : VirtKey := $09; $39 : VirtKey := $20;
    $3B..$44 : VirtKey := $70 + Sc - $3B;
  Else
    If (Ch >= Ord('a')) And (Ch <= Ord('z')) Then VirtKey := Ch - 32
    Else VirtKey := Ch;
  End;
End;

{ Remplir un INPUT_RECORD (20 octets) avec la touche K }
Procedure MakeKeyRecord(P, K : LongInt);
Var St : LongInt;
Begin
  FillMem(P, 20, 0);
  MemW[0:P] := 1;                             { KEY_EVENT }
  MemL[0:P + 4] := 1;                         { touche enfoncee }
  MemW[0:P + 8] := 1;
  MemW[0:P + 10] := VirtKey((K Shr 8) And $FF, K And $FF);
  MemW[0:P + 12] := (K Shr 8) And $FF;
  Mem[0:P + 14] := K And $FF;
  St := 0;
  If KbdShift Then St := St Or $10;
  If KbdCtrl Then St := St Or $08;
  If KbdAlt Then St := St Or $02;
  MemL[0:P + 16] := St;
End;

Function GetNumberOfConsoleInputEvents(H, PCount : LongInt) : LongInt;
Begin
  MemL[0:PCount] := (KbdHead - KbdTail + 64) And 63;
  GetNumberOfConsoleInputEvents := 1;
End;

Function PeekConsoleInputA(H, P, N, PRead : LongInt) : LongInt;
Begin
  { relachements et changements d'etat (moniteurs, KBDCALLS) ecartes }
  If KbdMode = 0 Then
    While KeyAvail And ((KbdXt[KbdTail] And $60000) <> 0) Do KbdTail := (KbdTail + 1) And 63;
  If KeyAvail And (N > 0) Then
  Begin
    MakeKeyRecord(P, KbdBuf[KbdTail]);
    MemL[0:PRead] := 1;
  End
  Else
    MemL[0:PRead] := 0;
  PeekConsoleInputA := 1;
End;

Function ReadConsoleInputA(H, P, N, PRead : LongInt) : LongInt;
Begin
  MakeKeyRecord(P, GetKey);
  MemL[0:PRead] := 1;
  ReadConsoleInputA := 1;
End;

{ --- Fichiers --- }

Function CreateFileA(PName, Access, Share, Sec, Disp, Flags, Templ : LongInt) : LongInt;
Var Path, Nm : String; H, R, Attr, Size, Time, Lba, Ram : LongInt; Exists, Wr : Boolean;
Begin
  CreateFileA := -1;
  Nm := UpStr(Trim(PStr(PName)));
  H := NewFileSlot;
  If H < 0 Then
  Begin
    LastError := ErrTooManyOpen;
    Exit;
  End;
  Wr := (Access And $40000000) <> 0;
  { peripheriques }
  If (Nm = 'CON') Or (Nm = 'CON:') Then
  Begin
    Files[H].IsCon := True; Files[H].CanWrite := True; Files[H].Name := 'CON';
    CreateFileA := HFileBase + H;
    Exit;
  End;
  If (Nm = 'NUL') Or (Nm = 'NUL:') Then
  Begin
    Files[H].IsNul := True; Files[H].CanWrite := True; Files[H].Name := 'NUL';
    CreateFileA := HFileBase + H;
    Exit;
  End;
  If (Length(Nm) = 5) And (Nm[5] = ':') And (Copy(Nm, 1, 3) = 'LPT') Then Nm := Copy(Nm, 1, 4);
  If (Nm = 'PRN') Or (Nm = 'PRN:') Or (Nm = 'LPT1') Or (Nm = 'LPT2') Or (Nm = 'LPT3') Then
  Begin
    { imprimante : port parallele }
    Files[H].IsPrn := True; Files[H].CanWrite := True;
    If (Nm = 'PRN') Or (Nm = 'PRN:') Then Files[H].PrnIdx := 0
    Else Files[H].PrnIdx := Ord(Nm[4]) - Ord('1');
    Files[H].Name := Nm;
    CreateFileA := HFileBase + H;
    Exit;
  End;
  Path := FullPath(Nm);
  Files[H].Name := Path;
  If IfsDrive(Path) >= 0 Then
  Begin
    { volume IFS : FS_OPENCREATE }
    Path := FullPathOf(PName);
    Files[H].Name := Path;
    R := IfsOpen(H, Path, Access, Share, Disp);
    If R <> 0 Then
    Begin
      Files[H].Used := False;
      LastError := R;
      Exit;
    End;
    CreateFileA := HFileBase + H;
    Exit;
  End;
  If Not DriveOk(Path) Then
  Begin
    Files[H].Used := False;
    LastError := ErrPathNotFound;
    Exit;
  End;
  Exists := PathInfo(Path, Attr, Size, Time, Lba, Ram);
  If Exists And ((Attr And FileAttrDirectory) <> 0) Then
  Begin
    Files[H].Used := False;
    LastError := ErrAccessDenied;
    Exit;
  End;
  { 1 CREATE_NEW, 2 CREATE_ALWAYS, 3 OPEN_EXISTING, 4 OPEN_ALWAYS, 5 TRUNCATE_EXISTING }
  If (Disp = 3) Or (Disp = 5) Then
    If Not Exists Then
    Begin
      Files[H].Used := False;
      LastError := ErrFileNotFound;
      Exit;
    End;
  If (Disp = 1) And Exists Then
  Begin
    Files[H].Used := False;
    LastError := ErrFileExists;
    Exit;
  End;
  If FlpPath(Path) And (Not Exists Or Wr Or (Disp = 2) Or (Disp = 5)) Then
  Begin
    { disquette A: : lecture seule }
    Files[H].Used := False;
    If Exists Then LastError := 19 Else LastError := ErrFileNotFound;
    Exit;
  End;
  If Exists And (Ram < 0) Then
  Begin
    { fichier du CD-ROM ou de la disquette : lecture seule }
    Files[H].IsFlp := Ram = -3;
    If Wr Or (Disp = 2) Or (Disp = 5) Then
    Begin
      Files[H].Used := False;
      LastError := ErrAccessDenied;
      Exit;
    End;
    Files[H].Lba := Lba; Files[H].Size := Size; Files[H].Time := Time;
    CreateFileA := HFileBase + H;
    Exit;
  End;
  If Not Exists Then
  Begin
    If Not IsDir(ParentDir(Path)) Then
    Begin
      Files[H].Used := False;
      LastError := ErrPathNotFound;
      Exit;
    End;
    R := RamFind(Path);
    If R >= 0 Then
    Begin
      { reutiliser une entree supprimee }
      RamFiles[R].Deleted := False; RamFiles[R].Size := 0;
      RamFiles[R].Attr := FileAttrArchive; RamFiles[R].Time := DosNow;
    End
    Else
      R := RamNew(Path, FileAttrArchive);
    If R < 0 Then
    Begin
      Files[H].Used := False;
      LastError := ErrTooManyOpen;
      Exit;
    End;
    Ram := R;
  End;
  If (Disp = 2) Or (Disp = 5) Then
  Begin
    RamFiles[Ram].Size := 0;
    RamFiles[Ram].Time := DosNow;
  End;
  If Wr And ((RamFiles[Ram].Attr And FileAttrReadOnly) <> 0) Then
  Begin
    Files[H].Used := False;
    LastError := ErrAccessDenied;
    Exit;
  End;
  Files[H].IsRam := True; Files[H].RamIdx := Ram;
  Files[H].CanWrite := Wr;
  Files[H].Time := RamFiles[Ram].Time;
  CreateFileA := HFileBase + H;
End;

Function CloseHandle(H : LongInt) : LongInt;
Var F : LongInt;
Begin
  CloseHandle := 1;
  F := FileSlot(H);
  If F >= 0 Then
  Begin
    If Files[F].IsIfs Then IfsClose(F);
    Files[F].Used := False;
    Exit;
  End;
  If (H >= HProcBase) And (H < HProcBase + MaxProcs) Then
  Begin
    Procs[H - HProcBase].HandleOpen := False;
    If Not Procs[H - HProcBase].Running And Not Procs[H - HProcBase].MemLive Then
      Procs[H - HProcBase].Used := False;
    Exit;
  End;
  If (H >= HThreadBase) And (H < HThreadBase + MaxProcs) Then Exit;
  If (H = HStdIn) Or (H = HStdOut) Or (H = HStdErr) Then Exit;
  LastError := ErrInvalidHandle;
  CloseHandle := 0;
End;

Function ReadFile(H, Buf, N, PRead, Ovl : LongInt) : LongInt;
Var F, Got, A, Sect, Ofs, Chunk, Ram, IR : LongInt; S : String;
Begin
  ReadFile := 1;
  Got := 0;
  If (H = HStdIn) Or ((FileSlot(H) >= 0) And Files[FileSlot(H)].IsCon) Then
  Begin
    { lecture de la console en mode ligne : echo, edition, CR LF final }
    If Not LineReady Then
    Begin
      ReadLine(S);
      LineBuf := S + #13#10;
      LinePos := 1;
      LineReady := True;
    End;
    While (Got < N) And (LinePos <= Length(LineBuf)) Do
    Begin
      Mem[0:Buf + Got] := Ord(LineBuf[LinePos]);
      Inc(Got); Inc(LinePos);
    End;
    If LinePos > Length(LineBuf) Then LineReady := False;
  End
  Else
  Begin
    F := FileSlot(H);
    If F < 0 Then
    Begin
      LastError := ErrInvalidHandle;
      If PRead <> 0 Then MemL[0:PRead] := 0;
      ReadFile := 0;
      Exit;
    End;
    If Files[F].IsIfs Then
    Begin
      IR := IfsRW(F, Buf, N, False, Got);
      If IR <> 0 Then
      Begin
        LastError := IR;
        ReadFile := 0;
      End;
    End
    Else If Files[F].IsNul Or Files[F].IsPrn Then
      Got := 0
    Else If Files[F].IsFlp Then
    Begin
      Got := FlpRead(Files[F].Lba, Files[F].Size, Files[F].Pos, Buf, N);
      If Got < 0 Then
      Begin
        Got := 0;
        LastError := ErrNotReady;
        ReadFile := 0;
      End;
      Files[F].Pos := Files[F].Pos + Got;
    End
    Else If Files[F].IsRam Then
    Begin
      Ram := Files[F].RamIdx;
      Got := RamFiles[Ram].Size - Files[F].Pos;
      If Got > N Then Got := N;
      If Got < 0 Then Got := 0;
      MoveMem(RamFiles[Ram].Data + Files[F].Pos, Buf, Got);
      Files[F].Pos := Files[F].Pos + Got;
    End
    Else
    Begin
      While (Got < N) And (Files[F].Pos < Files[F].Size) Do
      Begin
        Sect := Files[F].Pos Div 2048;
        Ofs := Files[F].Pos Mod 2048;
        A := CdSector(Files[F].Lba + Sect);
        If A = 0 Then
        Begin
          LastError := ErrNotReady;
          ReadFile := 0;
          Break;
        End;
        Chunk := 2048 - Ofs;
        If Chunk > N - Got Then Chunk := N - Got;
        If Chunk > Files[F].Size - Files[F].Pos Then Chunk := Files[F].Size - Files[F].Pos;
        MoveMem(A + Ofs, Buf + Got, Chunk);
        Got := Got + Chunk;
        Files[F].Pos := Files[F].Pos + Chunk;
      End;
    End;
  End;
  If PRead <> 0 Then MemL[0:PRead] := Got;
End;

{ Sortie standard du processus courant : 0 (console) ou handle de
  fichier (SetStdHandle, redirection > de CMD) }
Function StdOutTarget : LongInt;
Var T : LongInt;
Begin
  T := 0;
  If CurProc >= 0 Then T := Procs[CurProc].StdOutH;
  If (T <> 0) And (FileSlot(T) < 0) Then T := 0;     { fichier ferme }
  StdOutTarget := T;
End;

Function WriteFile(H, Buf, N, PWritten, Ovl : LongInt) : LongInt;
Var F, Ram, IR, Done : LongInt;
Begin
  WriteFile := 1;
  If H = HStdOut Then
    If StdOutTarget <> 0 Then H := StdOutTarget;
  If (H = HStdOut) Or (H = HStdErr) Then
    ConWrite(Buf, N)
  Else
  Begin
    F := FileSlot(H);
    If F < 0 Then
    Begin
      LastError := ErrInvalidHandle;
      WriteFile := 0;
      N := 0;
    End
    Else If Files[F].IsCon Then
      ConWrite(Buf, N)
    Else If Files[F].IsIfs Then
    Begin
      IR := IfsRW(F, Buf, N, True, Done);
      N := Done;
      If IR <> 0 Then
      Begin
        LastError := IR;
        WriteFile := 0;
      End;
    End
    Else If Files[F].IsNul Then
    Else If Files[F].IsPrn Then
    Begin
      Done := PrnWrite(Files[F].PrnIdx, Buf, N);
      If Done < 0 Then
      Begin
        LastError := ErrNotReady;
        WriteFile := 0;
        N := 0;
      End
      Else
        N := Done;
    End
    Else If Not (Files[F].IsRam And Files[F].CanWrite) Then
    Begin
      LastError := ErrAccessDenied;
      WriteFile := 0;
      N := 0;
    End
    Else
    Begin
      Ram := Files[F].RamIdx;
      If Not RamReserve(Ram, Files[F].Pos + N) Then
      Begin
        LastError := ErrNotEnoughMem;
        WriteFile := 0;
        N := 0;
      End
      Else
      Begin
        MoveMem(Buf, RamFiles[Ram].Data + Files[F].Pos, N);
        Files[F].Pos := Files[F].Pos + N;
        If Files[F].Pos > RamFiles[Ram].Size Then RamFiles[Ram].Size := Files[F].Pos;
        RamFiles[Ram].Time := DosNow;
      End;
    End;
  End;
  { le runtime passe parfois l'adresse en lpOverlapped (INT 21h AH=02h) }
  If PWritten <> 0 Then MemL[0:PWritten] := N;
End;

Function WriteConsoleA(H, Buf, N, PWritten, Res : LongInt) : LongInt;
Begin
  ConWrite(Buf, N);
  If PWritten <> 0 Then MemL[0:PWritten] := N;
  WriteConsoleA := 1;
End;

Function FileSizeOf(F : LongInt) : LongInt;
Begin
  If Files[F].IsIfs Then FileSizeOf := MemL[0:LongInt(@Files[F].Sffsi) + 20]
  Else If Files[F].IsRam Then FileSizeOf := RamFiles[Files[F].RamIdx].Size
  Else FileSizeOf := Files[F].Size;
End;

Function SetFilePointer(H, Dist, PHigh, Method : LongInt) : LongInt;
Var F, NP, R : LongInt;
Begin
  F := FileSlot(H);
  If F < 0 Then
  Begin
    LastError := ErrInvalidHandle;
    SetFilePointer := -1;
    Exit;
  End;
  If Files[F].IsIfs Then
  Begin
    IfsArgs4(LongInt(@Files[F].Sffsi), LongInt(@Files[F].Sffsd), Dist, Method);
    IfsArg[4] := 0;
    R := IfsCall(Ifss[IfsOf(Files[F].IfsDrv)].FSeek, 5);
    If R <> 0 Then
    Begin
      LastError := R;
      SetFilePointer := -1;
      Exit;
    End;
    NP := MemL[0:LongInt(@Files[F].Sffsi) + 24];
    Files[F].Pos := NP;
    If PHigh <> 0 Then MemL[0:PHigh] := 0;
    LastError := 0;
    SetFilePointer := NP;
    Exit;
  End;
  Case Method Of
    0 : NP := Dist;
    1 : NP := Files[F].Pos + Dist;
    2 : NP := FileSizeOf(F) + Dist;
  Else
    NP := -1;
  End;
  If NP < 0 Then
  Begin
    LastError := 131;
    SetFilePointer := -1;
    Exit;
  End;
  Files[F].Pos := NP;
  If PHigh <> 0 Then MemL[0:PHigh] := 0;
  LastError := 0;
  SetFilePointer := NP;
End;

Function GetFileSize(H, PHigh : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := FileSlot(H);
  If PHigh <> 0 Then MemL[0:PHigh] := 0;
  If F < 0 Then GetFileSize := -1 Else GetFileSize := FileSizeOf(F);
End;

Function SetEndOfFile(H : LongInt) : LongInt;
Var F, R : LongInt;
Begin
  SetEndOfFile := 0;
  F := FileSlot(H);
  If F >= 0 Then
    If Files[F].IsIfs Then
    Begin
      IfsArgs4(LongInt(@Files[F].Sffsi), LongInt(@Files[F].Sffsd), MemL[0:LongInt(@Files[F].Sffsi) + 24], 0);
      R := IfsCall(Ifss[IfsOf(Files[F].IfsDrv)].FNewSize, 4);
      If R = 0 Then SetEndOfFile := 1 Else LastError := R;
      Exit;
    End;
  If (F < 0) Or Not Files[F].IsRam Then Exit;
  If Files[F].Pos < RamFiles[Files[F].RamIdx].Size Then
    RamFiles[Files[F].RamIdx].Size := Files[F].Pos;
  SetEndOfFile := 1;
End;

Function FlushFileBuffers(H : LongInt) : LongInt;
Var F : LongInt;
Begin
  FlushFileBuffers := 1;
  F := FileSlot(H);
  If F >= 0 Then
    If Files[F].IsIfs Then
    Begin
      IfsArgs4(0, 0, LongInt(@Files[F].Sffsi), LongInt(@Files[F].Sffsd));
      If IfsCall(Ifss[IfsOf(Files[F].IfsDrv)].FCommit, 4) <> 0 Then FlushFileBuffers := 0;
    End;
End;

Function GetFileTime(H, PCreate, PAccess, PWrite : LongInt) : LongInt;
Var F, T : LongInt;
Begin
  GetFileTime := 0;
  F := FileSlot(H);
  If F < 0 Then Exit;
  T := Files[F].Time;
  If Files[F].IsRam Then T := RamFiles[Files[F].RamIdx].Time;
  If Files[F].IsIfs Then T := MemL[0:LongInt(@Files[F].Sffsi) + 16];
  If PWrite <> 0 Then DosDateTimeToFileTime(T Shr 16, T, PWrite);
  If PCreate <> 0 Then DosDateTimeToFileTime(T Shr 16, T, PCreate);
  If PAccess <> 0 Then DosDateTimeToFileTime(T Shr 16, T, PAccess);
  GetFileTime := 1;
End;

Function SetFileTime(H, PCreate, PAccess, PWrite : LongInt) : LongInt;
Var F, T, A : LongInt;
Begin
  SetFileTime := 0;
  F := FileSlot(H);
  If (F >= 0) And (PWrite <> 0) Then
    If Files[F].IsIfs Then
    Begin
      T := MemL[0:PWrite];
      A := LongInt(@IfsInfo);
      FillMem(A, 24, 0);
      MemW[0:A + 8] := (T Shr 16) And $FFFF;
      MemW[0:A + 10] := T And $FFFF;
      MemL[0:A + 20] := MemL[0:LongInt(@Files[F].Sffsi) + 52];
      IfsArgs4(1, LongInt(@Files[F].Sffsi), LongInt(@Files[F].Sffsd), 1);
      IfsArgs8(A, 24, 0, 0);
      If IfsCall(Ifss[IfsOf(Files[F].IfsDrv)].FFileInfo, 7) = 0 Then
      Begin
        MemL[0:LongInt(@Files[F].Sffsi) + 16] := T;
        SetFileTime := 1;
      End;
      Exit;
    End;
  If (F < 0) Or Not Files[F].IsRam Or (PWrite = 0) Then Exit;
  RamFiles[Files[F].RamIdx].Time := MemL[0:PWrite];
  SetFileTime := 1;
End;

Function GetFileAttributesA(PName : LongInt) : LongInt;
Var Path : String; A, S, T, L, R : LongInt;
Begin
  Path := FullPath(PStr(PName));
  If DriveOk(Path) And PathInfo(Path, A, S, T, L, R) Then
    GetFileAttributesA := A
  Else
  Begin
    LastError := ErrFileNotFound;
    GetFileAttributesA := -1;
  End;
End;

Function SetFileAttributesA(PName, Attr : LongInt) : LongInt;
Var Path : String; R, D, A : LongInt;
Begin
  SetFileAttributesA := 0;
  Path := FullPath(PStr(PName));
  If FlpPath(Path) Then
  Begin
    LastError := 19;          { disquette protegee en ecriture (lecture seule) }
    Exit;
  End;
  D := IfsDrive(Path);
  If D >= 0 Then
  Begin
    IfsPrep(D, FullPathOf(PName));
    A := Attr And $27;
    IfsArgs4(1, LongInt(@IfsCd), LongInt(@IfsCdd), LongInt(@IfsName));
    IfsArg[4] := -1;
    IfsArg[5] := LongInt(@A);
    R := IfsCall(Ifss[IfsOf(D)].FFileAttr, 6);
    If R = 0 Then SetFileAttributesA := 1 Else LastError := R;
    Exit;
  End;
  R := RamFind(Path);
  If (R < 0) Or RamFiles[R].Deleted Then
  Begin
    If GetFileAttributesA(PName) <> -1 Then LastError := ErrAccessDenied;
    Exit;
  End;
  RamFiles[R].Attr := (Attr And $27) Or (RamFiles[R].Attr And FileAttrDirectory);
  SetFileAttributesA := 1;
End;

Function DeleteFileA(PName : LongInt) : LongInt;
Var Path : String; R, I : LongInt;
Begin
  DeleteFileA := 0;
  Path := FullPath(PStr(PName));
  If FlpPath(Path) Then
  Begin
    LastError := 19;          { disquette protegee en ecriture (lecture seule) }
    Exit;
  End;
  If IfsDrive(Path) >= 0 Then
  Begin
    R := IfsPathOp(Ifss[IfsOf(IfsDrive(Path))].FDelete, FullPathOf(PName));
    If R = 0 Then DeleteFileA := 1 Else LastError := R;
    Exit;
  End;
  R := RamFind(Path);
  If (R < 0) Or RamFiles[R].Deleted Then
  Begin
    If GetFileAttributesA(PName) <> -1 Then LastError := ErrAccessDenied
    Else LastError := ErrFileNotFound;
    Exit;
  End;
  If (RamFiles[R].Attr And (FileAttrDirectory Or FileAttrReadOnly)) <> 0 Then
  Begin
    LastError := ErrAccessDenied;
    Exit;
  End;
  For I := 0 To MaxFiles - 1 Do
    If Files[I].Used And Files[I].IsRam And (Files[I].RamIdx = R) Then
    Begin
      LastError := 32;     { partage }
      Exit;
    End;
  If RamFiles[R].Data <> 0 Then KFree(RamFiles[R].Data);
  RamFiles[R].Used := False;
  DeleteFileA := 1;
End;

Function MoveFileA(PSrc, PDst : LongInt) : LongInt;
Var Src, Dst : String; R, A, S, T, L, Rr : LongInt;
Begin
  MoveFileA := 0;
  Src := FullPath(PStr(PSrc));
  Dst := FullPath(PStr(PDst));
  If FlpPath(Src) Or FlpPath(Dst) Then
  Begin
    LastError := 19;          { disquette protegee en ecriture (lecture seule) }
    Exit;
  End;
  If (IfsDrive(Src) >= 0) Or (IfsDrive(Dst) >= 0) Then
  Begin
    If IfsDrive(Src) <> IfsDrive(Dst) Then
    Begin
      LastError := 17;                       { ERROR_NOT_SAME_DEVICE }
      Exit;
    End;
    Src := FullPathOf(PSrc);
    Dst := FullPathOf(PDst);
    IfsPrep(IfsDrive(Src), Src);
    PutPStr(LongInt(@IfsName2), Dst, 260);
    IfsArgs4(LongInt(@IfsCd), LongInt(@IfsCdd), LongInt(@IfsName), -1);
    IfsArg[4] := LongInt(@IfsName2); IfsArg[5] := -1; IfsArg[6] := 0;
    R := IfsCall(Ifss[IfsOf(IfsDrive(Src))].FMove, 7);
    If R = 0 Then MoveFileA := 1 Else LastError := R;
    Exit;
  End;
  R := RamFind(Src);
  If (R < 0) Or RamFiles[R].Deleted Then
  Begin
    If GetFileAttributesA(PSrc) <> -1 Then LastError := ErrAccessDenied
    Else LastError := ErrFileNotFound;
    Exit;
  End;
  If PathInfo(Dst, A, S, T, L, Rr) Then
  Begin
    LastError := ErrAlreadyExists;
    Exit;
  End;
  If Not IsDir(ParentDir(Dst)) Then
  Begin
    LastError := ErrPathNotFound;
    Exit;
  End;
  RamFiles[R].Path := Dst;
  MoveFileA := 1;
End;

Function CreateDirectoryA(PName, Sec : LongInt) : LongInt;
Var Path : String; A, S, T, L, R : LongInt;
Begin
  CreateDirectoryA := 0;
  Path := FullPath(PStr(PName));
  If FlpPath(Path) Then
  Begin
    LastError := 19;          { disquette protegee en ecriture (lecture seule) }
    Exit;
  End;
  If IfsDrive(Path) >= 0 Then
  Begin
    IfsPrep(IfsDrive(Path), FullPathOf(PName));
    IfsArgs4(LongInt(@IfsCd), LongInt(@IfsCdd), LongInt(@IfsName), -1);
    IfsArg[4] := 0; IfsArg[5] := 0;
    R := IfsCall(Ifss[IfsOf(IfsDrive(Path))].FMkDir, 6);
    If R = 0 Then CreateDirectoryA := 1 Else LastError := R;
    Exit;
  End;
  If Not DriveOk(Path) Or (Length(Path) <= 3) Then
  Begin
    LastError := ErrPathNotFound;
    Exit;
  End;
  If PathInfo(Path, A, S, T, L, R) Then
  Begin
    LastError := ErrAccessDenied;
    Exit;
  End;
  If Not IsDir(ParentDir(Path)) Then
  Begin
    LastError := ErrPathNotFound;
    Exit;
  End;
  If RamNew(Path, FileAttrDirectory) < 0 Then
  Begin
    LastError := ErrAccessDenied;
    Exit;
  End;
  CreateDirectoryA := 1;
End;

Function RemoveDirectoryA(PName : LongInt) : LongInt;
Var Path, Pfx : String; R, I : LongInt;
Begin
  RemoveDirectoryA := 0;
  Path := FullPath(PStr(PName));
  If FlpPath(Path) Then
  Begin
    LastError := 19;          { disquette protegee en ecriture (lecture seule) }
    Exit;
  End;
  If IfsDrive(Path) >= 0 Then
  Begin
    If UpStr(Path) = UpStr(CurDir) Then
    Begin
      LastError := ErrCurrentDir;
      Exit;
    End;
    R := IfsPathOp(Ifss[IfsOf(IfsDrive(Path))].FRmDir, FullPathOf(PName));
    If R = 0 Then RemoveDirectoryA := 1 Else LastError := R;
    Exit;
  End;
  R := RamFind(Path);
  If (R < 0) Or ((RamFiles[R].Attr And FileAttrDirectory) = 0) Then
  Begin
    If IsDir(Path) Then LastError := ErrAccessDenied Else LastError := ErrPathNotFound;
    Exit;
  End;
  If Path = CurDir Then
  Begin
    LastError := ErrCurrentDir;
    Exit;
  End;
  Pfx := Path + '\';
  For I := 0 To MaxRamFiles - 1 Do
    If RamFiles[I].Used And Not RamFiles[I].Deleted And
       (Copy(RamFiles[I].Path, 1, Length(Pfx)) = Pfx) Then
    Begin
      LastError := ErrAccessDenied;
      Exit;
    End;
  RamFiles[R].Used := False;
  RemoveDirectoryA := 1;
End;

Function SetCurrentDirectoryA(PName : LongInt) : LongInt;
Var Path : String;
Begin
  SetCurrentDirectoryA := 0;
  Path := FullPath(PStr(PName));
  If Not DriveOk(Path) Then
  Begin
    LastError := ErrInvalidDrive;
    Exit;
  End;
  If Not IsDir(Path) Then
  Begin
    LastError := ErrPathNotFound;
    Exit;
  End;
  If IfsDrive(Path) >= 0 Then Path := FullPathOf(PName);
  If CurProc >= 0 Then Procs[CurProc].CurDir := Path Else KernelDir := Path;
  SetCurrentDirectoryA := 1;
End;

Function GetCurrentDirectoryA(N, Buf : LongInt) : LongInt;
Var S : String;
Begin
  S := CurDir;
  If Length(S) + 1 > N Then
    GetCurrentDirectoryA := Length(S) + 1
  Else
  Begin
    PutPStr(Buf, S, N);
    GetCurrentDirectoryA := Length(S);
  End;
End;

Function GetFullPathNameA(PName, N, Buf, PFile : LongInt) : LongInt;
Var S : String; P : LongInt;
Begin
  S := FullPathOf(PName);
  If Length(S) + 1 > N Then
  Begin
    GetFullPathNameA := Length(S) + 1;
    Exit;
  End;
  PutPStr(Buf, S, N);
  If PFile <> 0 Then
  Begin
    P := Length(S);
    While (P > 0) And (S[P] <> '\') Do Dec(P);
    MemL[0:PFile] := Buf + P;
  End;
  GetFullPathNameA := Length(S);
End;

Function GetDiskFreeSpaceA(PRoot, PSpc, PBps, PFree, PTotal : LongInt) : LongInt;
Var Root : String;
Begin
  GetDiskFreeSpaceA := 0;
  If PRoot <> 0 Then Root := UpStr(PStr(PRoot)) Else Root := CurDir;
  If FlpPath(Root) Then
  Begin
    If Not FlpReady Then
    Begin
      LastError := ErrNotReady;
      Exit;
    End;
    If PSpc <> 0 Then MemL[0:PSpc] := FlpSpc;
    If PBps <> 0 Then MemL[0:PBps] := 512;
    If PFree <> 0 Then MemL[0:PFree] := 0;
    If PTotal <> 0 Then MemL[0:PTotal] := FlpClusN - 2;
    GetDiskFreeSpaceA := 1;
    Exit;
  End;
  If IfsDrive(Root) >= 0 Then
  Begin
    IfsArg[0] := 0; IfsArg[1] := IfsDrive(Root); IfsArg[2] := LongInt(@IfsInfo);
    IfsArg[3] := 18; IfsArg[4] := 1;
    If IfsCall(Ifss[IfsOf(IfsDrive(Root))].FFsInfo, 5) <> 0 Then
    Begin
      LastError := ErrNotReady;
      Exit;
    End;
    MemL[0:PSpc] := MemL[0:LongInt(@IfsInfo) + 4];
    MemL[0:PBps] := MemW[0:LongInt(@IfsInfo) + 16];
    MemL[0:PFree] := MemL[0:LongInt(@IfsInfo) + 12];
    MemL[0:PTotal] := MemL[0:LongInt(@IfsInfo) + 8];
    GetDiskFreeSpaceA := 1;
    Exit;
  End;
  If (Root = '') Or (Root[1] <> 'C') Then
  Begin
    LastError := ErrInvalidDrive;
    Exit;
  End;
  MemL[0:PSpc] := 1;
  MemL[0:PBps] := 2048;
  MemL[0:PFree] := HeapFreeBytes Div 2048;
  MemL[0:PTotal] := MemL[0:PFree] + RootSize Div 2048 + 2048;
  GetDiskFreeSpaceA := 1;
End;

{ --- Recherche de fichiers (FindFirstFileA / FindNextFileA) --- }

{ Remplir WIN32_FIND_DATAA (320 octets) }
Procedure FillFindData(P : LongInt; Name : String; Attr, Size, Time : LongInt);
Begin
  FillMem(P, 320, 0);
  MemL[0:P] := Attr;
  DosDateTimeToFileTime(Time Shr 16, Time, P + 4);
  DosDateTimeToFileTime(Time Shr 16, Time, P + 12);
  DosDateTimeToFileTime(Time Shr 16, Time, P + 20);
  MemL[0:P + 32] := Size;
  PutPStr(P + 44, Name, 260);
  PutPStr(P + 304, Name, 14);
End;

{ Entree suivante de la recherche F ; vrai si trouvee }
Function FindStep(F, P : LongInt) : Boolean;
Var Nm, Pfx, Rest : String; Lba, Size, Attr, Time, DLba, DSize, DAttr, DTime, I : LongInt;
Begin
  FindStep := False;
  { disquette A: }
  If Finds[F].IsFlp Then
  Begin
    If Not FlpReady Then Exit;
    I := FlpDirEnt(Finds[F].FlpClus, Finds[F].IsoIdx);
    While I <> 0 Do
    Begin
      Inc(Finds[F].IsoIdx);
      If FlpEntOk(I) Then
      Begin
        Nm := FlpEntName(I);
        If (Nm <> '.') And (Nm <> '..') And MatchMask(Nm, Finds[F].Mask) Then
        Begin
          FillFindData(P, Nm, Mem[0:I + 11], MemL[0:I + 28], (MemW[0:I + 24] Shl 16) Or MemW[0:I + 22]);
          FindStep := True;
          Exit;
        End;
      End;
      I := FlpDirEnt(Finds[F].FlpClus, Finds[F].IsoIdx);
    End;
    Exit;
  End;
  { 1) entrees du CD-ROM }
  If Finds[F].IsoIdx >= 0 Then
  Begin
    If IsoLookup(Finds[F].Dir, DLba, DSize, DAttr, DTime) And
       ((DAttr And FileAttrDirectory) <> 0) Then
    Begin
      While IsoDirEntry(DLba, DSize, Finds[F].IsoIdx, Nm, Lba, Size, Attr, Time) Do
      Begin
        Inc(Finds[F].IsoIdx);
        { une entree supprimee ou remplacee dans le disque virtuel est masquee }
        If Length(Finds[F].Dir) = 3 Then I := RamFind(Finds[F].Dir + Nm)
        Else I := RamFind(Finds[F].Dir + '\' + Nm);
        If I >= 0 Then Continue;
        If MatchMask(Nm, Finds[F].Mask) Then
        Begin
          FillFindData(P, Nm, Attr, Size, Time);
          FindStep := True;
          Exit;
        End;
      End;
    End;
    Finds[F].IsoIdx := -1;
  End;
  { 2) entrees du disque virtuel situees dans ce repertoire }
  If Length(Finds[F].Dir) = 3 Then Pfx := Finds[F].Dir Else Pfx := Finds[F].Dir + '\';
  While Finds[F].RamIdx < MaxRamFiles Do
  Begin
    I := Finds[F].RamIdx;
    Inc(Finds[F].RamIdx);
    If RamFiles[I].Used And Not RamFiles[I].Deleted And
       (Copy(RamFiles[I].Path, 1, Length(Pfx)) = Pfx) Then
    Begin
      Rest := Copy(RamFiles[I].Path, Length(Pfx) + 1, 255);
      If (Pos('\', Rest) = 0) And MatchMask(Rest, Finds[F].Mask) Then
      Begin
        FillFindData(P, Rest, RamFiles[I].Attr, RamFiles[I].Size, RamFiles[I].Time);
        FindStep := True;
        Exit;
      End;
    End;
  End;
End;

{ Recherche sur un volume IFS : entree de niveau 1 (FILEFINDBUF3) dans
  IfsInfo -> WIN32_FIND_DATAA }
Procedure IfsFillFind(P : LongInt);
Var A : LongInt;
Begin
  A := LongInt(@IfsInfo);
  FillFindData(P, PStr(A + 29), MemL[0:A + 24], MemL[0:A + 16], (MemW[0:A + 12] Shl 16) Or MemW[0:A + 14]);
End;

Function IfsFindFirst(F : LongInt; Pattern : String; P : LongInt) : Boolean;
Var D, R : LongInt;
Begin
  D := IfsDrive(Pattern);
  Finds[F].IsIfs := True;
  Finds[F].IfsDrv := D;
  FillMem(LongInt(@Finds[F].Fsfsi), 8, 0);
  FillMem(LongInt(@Finds[F].Fsfsd), 32, 0);
  MemL[0:LongInt(@Finds[F].Fsfsi)] := D;
  IfsPrep(D, Pattern);
  IfsCnt := 1;
  IfsArgs4(LongInt(@IfsCd), LongInt(@IfsCdd), LongInt(@IfsName), -1);
  IfsArgs8($37, LongInt(@Finds[F].Fsfsi), LongInt(@Finds[F].Fsfsd), LongInt(@IfsInfo));
  IfsArg[8] := 300; IfsArg[9] := LongInt(@IfsCnt); IfsArg[10] := 1; IfsArg[11] := 0;
  R := IfsCall(Ifss[IfsOf(D)].FFindFirst, 12);
  If R = 0 Then IfsFillFind(P)
  Else
  Begin
    Finds[F].IsIfs := False;
    If R = 18 Then LastError := ErrFileNotFound Else LastError := R;
  End;
  IfsFindFirst := R = 0;
End;

Function FindFirstFileA(PName, P : LongInt) : LongInt;
Var Path, Dir, Mask : String; F, I, C1, A1, S1, T1 : LongInt;
Begin
  FindFirstFileA := -1;
  Path := FullPath(PStr(PName));
  If Not DriveOk(Path) Then
  Begin
    LastError := ErrPathNotFound;
    Exit;
  End;
  If Length(Path) = 3 Then
  Begin
    Dir := Path; Mask := '*.*';
  End
  Else
  Begin
    Dir := ParentDir(Path);
    Mask := BaseName(Path);
  End;
  If Not IsDir(Dir) Then
  Begin
    LastError := ErrPathNotFound;
    Exit;
  End;
  F := -1;
  For I := 0 To MaxFinds - 1 Do
    If Not Finds[I].Used Then
    Begin
      F := I;
      Break;
    End;
  If F < 0 Then
  Begin
    LastError := ErrTooManyOpen;
    Exit;
  End;
  Finds[F].Used := True;
  Finds[F].IsIfs := False;
  Finds[F].IsFlp := False;
  If FlpPath(Dir) Then
  Begin
    Finds[F].IsFlp := True;
    Finds[F].FlpClus := 0;
    If FlpLookup(Dir, C1, A1, S1, T1) Then Finds[F].FlpClus := C1;
  End;
  Finds[F].Dir := Dir;
  Finds[F].Mask := Mask;
  Finds[F].IsoIdx := 0;
  Finds[F].RamIdx := 0;
  Finds[F].Owner := CurProc;
  If IfsDrive(Path) >= 0 Then
  Begin
    Path := FullPathOf(PName);
    If Length(Path) = 3 Then Path := Path + '*';
    If IfsFindFirst(F, Path, P) Then FindFirstFileA := HFindBase + F
    Else Finds[F].Used := False;
  End
  Else If FindStep(F, P) Then
    FindFirstFileA := HFindBase + F
  Else
  Begin
    Finds[F].Used := False;
    LastError := ErrFileNotFound;
  End;
End;

Function FindNextFileA(H, P : LongInt) : LongInt;
Var F : LongInt;
Begin
  FindNextFileA := 0;
  F := H - HFindBase;
  If (F < 0) Or (F >= MaxFinds) Or Not Finds[F].Used Then
  Begin
    LastError := ErrInvalidHandle;
    Exit;
  End;
  If Finds[F].IsIfs Then
  Begin
    IfsCnt := 1;
    IfsArgs4(LongInt(@Finds[F].Fsfsi), LongInt(@Finds[F].Fsfsd), LongInt(@IfsInfo), 300);
    IfsArg[4] := LongInt(@IfsCnt); IfsArg[5] := 1; IfsArg[6] := 0;
    If IfsCall(Ifss[IfsOf(Finds[F].IfsDrv)].FFindNext, 7) = 0 Then
    Begin
      IfsFillFind(P);
      FindNextFileA := 1;
    End
    Else
      LastError := ErrNoMoreFiles;
  End
  Else If FindStep(F, P) Then FindNextFileA := 1
  Else LastError := ErrNoMoreFiles;
End;

Function FindClose(H : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := H - HFindBase;
  If (F >= 0) And (F < MaxFinds) Then
  Begin
    If Finds[F].Used And Finds[F].IsIfs Then
    Begin
      IfsArg[0] := LongInt(@Finds[F].Fsfsi); IfsArg[1] := LongInt(@Finds[F].Fsfsd);
      IfsCall(Ifss[IfsOf(Finds[F].IfsDrv)].FFindClose, 2);
      Finds[F].IsIfs := False;
    End;
    Finds[F].Used := False;
  End;
  FindClose := 1;
End;

{ --- Chaines (unite Strings) --- }

Function lstrlenA(P : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  If P <> 0 Then
    While Mem[0:P + N] <> 0 Do Inc(N);
  lstrlenA := N;
End;

Function lstrcpyA(Dst, Src : LongInt) : LongInt;
Begin
  MoveMem(Src, Dst, lstrlenA(Src) + 1);
  lstrcpyA := Dst;
End;

Function lstrcatA(Dst, Src : LongInt) : LongInt;
Begin
  MoveMem(Src, Dst + lstrlenA(Dst), lstrlenA(Src) + 1);
  lstrcatA := Dst;
End;

Function lstrcmpA(A, B : LongInt) : LongInt;
Var I, CA, CB : LongInt;
Begin
  I := 0;
  Repeat
    CA := Mem[0:A + I]; CB := Mem[0:B + I];
    Inc(I);
  Until (CA <> CB) Or (CA = 0);
  lstrcmpA := CA - CB;
End;

Function lstrcmpiA(A, B : LongInt) : LongInt;
Var I, CA, CB : LongInt;
Begin
  I := 0;
  Repeat
    CA := Mem[0:A + I]; CB := Mem[0:B + I];
    If (CA >= 97) And (CA <= 122) Then CA := CA - 32;
    If (CB >= 97) And (CB <= 122) Then CB := CB - 32;
    Inc(I);
  Until (CA <> CB) Or (CA = 0);
  lstrcmpiA := CA - CB;
End;

{ --- Fonction absente --- }

Procedure ApiMissing(Name : LongInt);
Begin
  TextAttr := $4F;
  ConPutLn('SYS1804: La fonction ' + PStr(Name) + ' de DOSCALLS.DLL n''est pas disponible.');
  TextAttr := $07;
  If CurProc >= 0 Then KillCurrentProcess(-1);
  ConPutLn('Le systeme est arrete.');
  asm
    cli
  @h:
    hlt
    jmp @h
  end;
End;

{ ==================================================================== }
{ Partie 13 - Chargeur de programmes PE et processus                   }
{ ==================================================================== }
{ Un programme OS/2-0 est une image PE 80386 liee a 00400000h (OS2PC
  -COS2). Sa memoire physique (image + pile) est prise au-dessus de 8 Mo
  et projetee dans la fenetre 00400000h-007FFFFFh ; la pile reste
  accessible a son adresse physique (projection a l'identique), ce qui
  permet de changer de fenetre sans perdre la pile. Les importations
  (DOSCALLS.DLL, ou kernel32/user32/gdi32/msvcrt d'un programme Win32 de
  TPCW32) sont liees par nom a la table d'exportation du noyau. }

Var
  ProcEntry : Array[0..MaxProcs - 1] Of LongInt;
  ProcStack : Array[0..MaxProcs - 1] Of LongInt;
  TmpEsp    : LongInt;
  KExpCount, KExpFuncs, KExpNames, KExpOrds : LongInt;

{ Table d'exportation du noyau (sa propre image PE, en 00100000h) }
Procedure InitExports;
Var Pe, Dir : LongInt;
Begin
  Pe := $00100000 + MemL[0:$0010003C];
  Dir := MemL[0:Pe + 24 + 96];
  KExpCount := 0;
  If Dir = 0 Then Exit;
  Dir := $00100000 + Dir;
  KExpCount := MemL[0:Dir + 24];
  KExpFuncs := $00100000 + MemL[0:Dir + 28];
  KExpNames := $00100000 + MemL[0:Dir + 32];
  KExpOrds := $00100000 + MemL[0:Dir + 36];
End;

{ Comparer (sans tenir compte de la casse) la chaine ASCIIZ en A avec U
  (en majuscules), sans chaine temporaire : les resultats de fonctions
  chaine du runtime occupent un anneau de tampons qu'une longue boucle
  ferait deborder. }
Function MemNameEq(A : LongInt; U : String) : Boolean;
Var I, C : LongInt;
Begin
  MemNameEq := False;
  For I := 1 To Length(U) Do
  Begin
    C := Mem[0:A + I - 1];
    If (C >= 97) And (C <= 122) Then C := C - 32;
    If C <> Ord(U[I]) Then Exit;
  End;
  MemNameEq := Mem[0:A + Length(U)] = 0;
End;

Function KernelExport(Name : String) : LongInt;
Var I, O : LongInt; U : String;
Begin
  KernelExport := 0;
  U := UpStr(Name);
  For I := 0 To KExpCount - 1 Do
    If MemNameEq($00100000 + MemL[0:KExpNames + I * 4], U) Then
    Begin
      O := MemW[0:KExpOrds + I * 2];
      KernelExport := $00100000 + MemL[0:KExpFuncs + O * 4];
      Exit;
    End;
End;

{ Lire tout un fichier dans un bloc du tas ; rend l'adresse ou 0 }
Function ReadWholeFile(Path : String; Var Size : LongInt) : LongInt;
Var Attr, Time, Lba, Ram, Buf, Done, A, N, H, Got : LongInt;
Begin
  ReadWholeFile := 0;
  If IfsDrive(Path) >= 0 Then
  Begin
    { volume IFS : lecture par le pilote }
    H := NewFileSlot;
    If H < 0 Then
    Begin
      LastError := ErrTooManyOpen;
      Exit;
    End;
    N := IfsOpen(H, Path, $80000000, 3, 3);
    If N <> 0 Then
    Begin
      Files[H].Used := False;
      LastError := N;
      Exit;
    End;
    Size := MemL[0:LongInt(@Files[H].Sffsi) + 20];
    Buf := KAlloc(Size + 1);
    If Buf <> 0 Then
    Begin
      N := IfsRW(H, Buf, Size, False, Got);
      If (N <> 0) Or (Got <> Size) Then
      Begin
        KFree(Buf);
        Buf := 0;
        LastError := ErrNotReady;
      End;
    End
    Else
      LastError := ErrNotEnoughMem;
    IfsClose(H);
    Files[H].Used := False;
    ReadWholeFile := Buf;
    Exit;
  End;
  If Not PathInfo(Path, Attr, Size, Time, Lba, Ram) Then
  Begin
    LastError := ErrFileNotFound;
    Exit;
  End;
  If (Attr And FileAttrDirectory) <> 0 Then
  Begin
    LastError := ErrAccessDenied;
    Exit;
  End;
  Buf := KAlloc(Size + 1);
  If Buf = 0 Then
  Begin
    LastError := ErrNotEnoughMem;
    Exit;
  End;
  If Ram >= 0 Then
    MoveMem(RamFiles[Ram].Data, Buf, Size)
  Else
  Begin
    Done := 0;
    While Done < Size Do
    Begin
      A := CdSector(Lba + Done Div 2048);
      If A = 0 Then
      Begin
        KFree(Buf);
        LastError := ErrNotReady;
        Exit;
      End;
      N := Size - Done;
      If N > 2048 Then N := 2048;
      MoveMem(A, Buf + Done, N);
      Done := Done + N;
    End;
  End;
  Mem[0:Buf + Size] := 0;
  ReadWholeFile := Buf;
End;

Function FileExists(Path : String) : Boolean;
Var A, S, T, L, R : LongInt;
Begin
  FileExists := PathInfo(Path, A, S, T, L, R) And ((A And FileAttrDirectory) = 0);
End;

{ Trouver un programme : nom tel quel puis .EXE, repertoire courant,
  repertoires de PATH, racine. Le resultat est calcule dans Res et
  affecte a la fin : le resultat d'une fonction chaine est un tampon de
  l'anneau du runtime, qui serait reutilise par les appels intermediaires. }
Function FindProgram(Name : String) : String;
Var Cands : Array[0..2] Of String; NC, I, P : LongInt; Dirs, D, Path, Res : String;
    Explicit : Boolean;
Begin
  Res := '';
  Name := UpStr(Trim(Name));
  NC := 0;
  If Name <> '' Then
  Begin
    If Pos('.', BaseName(Name)) > 0 Then
    Begin
      Cands[0] := Name; NC := 1;
    End
    Else
    Begin
      Cands[0] := Name + '.EXE'; Cands[1] := Name + '.COM'; Cands[2] := Name; NC := 3;
    End;
  End;
  For I := 0 To NC - 1 Do
    If Res = '' Then
    Begin
      Path := FullPath(Cands[I]);
      If DriveOk(Path) And FileExists(Path) Then Res := Path;
    End;
  Explicit := (Pos('\', Name) > 0) Or (Pos(':', Name) > 0);
  If (Res = '') And (NC > 0) And Not Explicit Then
  Begin
    P := EnvFind('PATH');
    If P <> 0 Then Dirs := PStr(P) Else Dirs := '';
    Dirs := Dirs + ';C:\';
    While (Dirs <> '') And (Res = '') Do
    Begin
      P := Pos(';', Dirs);
      If P > 0 Then
      Begin
        D := Copy(Dirs, 1, P - 1);
        Dirs := Copy(Dirs, P + 1, 255);
      End
      Else
      Begin
        D := Dirs; Dirs := '';
      End;
      D := Trim(D);
      If D <> '' Then
      Begin
        If D[Length(D)] <> '\' Then D := D + '\';
        For I := 0 To NC - 1 Do
          If Res = '' Then
          Begin
            Path := FullPath(D + Cands[I]);
            If DriveOk(Path) And FileExists(Path) Then Res := Path;
          End;
      End;
    End;
  End;
  { COMMAND.COM absent : l'interpreteur integre de la session DOS }
  If (Res = '') And ((Name = 'COMMAND') Or (Name = 'COMMAND.COM') Or
     (Copy(Name, Length(Name) - 11, 12) = '\COMMAND.COM')) Then Res := 'C:\COMMAND.COM';
  FindProgram := Res;
End;

{ --- Modules de liens dynamiques (DLL) ---
  Une DLL OS/2-0 (OS2PC, Library) est une image PE chargee (une seule
  fois) dans la region 00800000h-00FFFFFFh, projetee a l'identique et
  partagee par tous les processus. Elle est placee a sa base preferee
  (directive $IMAGEBASE d'OS2PC) si cette place est libre, sinon a la
  premiere place libre de la region : ses adresses absolues sont alors
  corrigees (section .reloc). Ses importations sont liees, puis son code
  d'initialisation (point d'entree) est execute. La table des modules est
  allouee dans le tas du noyau et doublee au besoin : le nombre de DLL
  n'est limite que par la place dans la region. }

Type
  TModule = Record
    Used     : Boolean;
    Name     : String[63];      { nom en majuscules, ex. DOSCALLS.DLL }
    Path     : String[127];
    Base     : LongInt;
    Size     : LongInt;
    NExp, Funcs, Names, Ords : LongInt;
    OrdBase, NFunc : LongInt;   { base des ordinaux, entrees de l'EAT }
  End;

  TModArr = Array[0..4095] Of TModule;
  PModArr = ^TModArr;

Var
  Mods      : PModArr;          { table des modules (tas du noyau) }
  ModCap    : LongInt;          { nombre d'entrees de la table }
  EntryTmp  : LongInt;

{ Entree libre de la table des modules (la table est doublee si elle est
  pleine) ; -1 si le tas du noyau est epuise }
Function NewModSlot : LongInt;
Var I, NC, A : LongInt;
Begin
  For I := 0 To ModCap - 1 Do
    If Not Mods^[I].Used Then
    Begin
      NewModSlot := I;
      Exit;
    End;
  If ModCap = 0 Then NC := ModFirstCap Else NC := ModCap * 2;
  NewModSlot := -1;
  A := KAlloc(NC * SizeOf(TModule));
  If A = 0 Then Exit;
  FillMem(A, NC * SizeOf(TModule), 0);
  If ModCap > 0 Then
  Begin
    MoveMem(LongInt(Mods), A, ModCap * SizeOf(TModule));
    KFree(LongInt(Mods));
  End;
  Mods := Pointer(A);
  NewModSlot := ModCap;
  ModCap := NC;
End;

{ La place [B, B + Sz[ de la region des DLL est-elle libre ? }
Function DllSpaceFree(B, Sz : LongInt) : Boolean;
Var I : LongInt; Ok : Boolean;
Begin
  Ok := (B >= DllBase) And (B + Sz <= DllTop) And (B + Sz <= PhysTop);
  For I := 0 To ModCap - 1 Do
    If Ok And Mods^[I].Used And (B < Mods^[I].Base + Mods^[I].Size) And (Mods^[I].Base < B + Sz) Then Ok := False;
  DllSpaceFree := Ok;
End;

{ Premiere place libre de Sz octets dans la region des DLL (0 : aucune) }
Function DllFindSpace(Sz : LongInt) : LongInt;
Var B, R : LongInt;
Begin
  R := 0;
  B := DllBase;
  While (R = 0) And (B + Sz <= DllTop) Do
  Begin
    If DllSpaceFree(B, Sz) Then R := B;
    B := B + DllAlign;
  End;
  DllFindSpace := R;
End;

{ Appliquer les relocalisations de base (IMAGE_REL_BASED_HIGHLOW) d'une
  image chargee a Base au lieu de sa base preferee (Delta) }
Procedure DllRelocate(Base, RelRva, RelSize, Delta : LongInt);
Var P, E, Page, BS, K, Ent, A : LongInt;
Begin
  P := Base + RelRva;
  E := P + RelSize;
  While P + 8 <= E Do
  Begin
    Page := MemL[0:P];
    BS := MemL[0:P + 4];
    If BS < 8 Then BS := E - P;              { bloc invalide : fin }
    For K := 0 To (BS - 8) Div 2 - 1 Do
    Begin
      Ent := MemW[0:P + 8 + K * 2];
      If (Ent Shr 12) = 3 Then
      Begin
        A := Base + Page + (Ent And 4095);
        MemL[0:A] := MemL[0:A] + Delta;
      End;
    End;
    P := P + BS;
  End;
End;

Function ModuleExport(M : LongInt; Name : String; Ordinal : LongInt) : LongInt;
Var I, O, Base : LongInt; U : String;
Begin
  ModuleExport := 0;
  If (M < 0) Or Not Mods^[M].Used Then Exit;
  Base := Mods^[M].Base;
  If Name = '' Then
  Begin
    { par ordinal (base des ordinaux de la DLL, entree non nulle) }
    I := Ordinal - Mods^[M].OrdBase;
    If (I >= 0) And (I < Mods^[M].NFunc) Then
      If MemL[0:Mods^[M].Funcs + I * 4] <> 0 Then
        ModuleExport := Base + MemL[0:Mods^[M].Funcs + I * 4];
    Exit;
  End;
  U := UpStr(Name);
  For I := 0 To Mods^[M].NExp - 1 Do
    If MemNameEq(Base + MemL[0:Mods^[M].Names + I * 4], U) Then
    Begin
      O := MemW[0:Mods^[M].Ords + I * 2];
      ModuleExport := Base + MemL[0:Mods^[M].Funcs + O * 4];
      Exit;
    End;
End;

Function FindModule(Name : String) : LongInt;
Var I : LongInt;
Begin
  FindModule := -1;
  Name := UpStr(BaseName(Name));
  If Pos('.', Name) = 0 Then Name := Name + '.DLL';
  For I := 0 To ModCap - 1 Do
    If Mods^[I].Used And (Mods^[I].Name = Name) Then
    Begin
      FindModule := I;
      Exit;
    End;
End;

Procedure CallEntry(E : LongInt);
Begin
  EntryTmp := E;
  asm
    pushad
    mov eax,EntryTmp
    call eax
    popad
  end;
End;

Function LoadModule(Name : String) : LongInt; Forward;

{ Adresse d'une importation : couche de base du noyau, puis DLL nommee }
Function ResolveImport(ADll, ANm : String) : LongInt;
Var A, M : LongInt; Dll, Nm : String;
Begin
  Dll := ADll; Nm := ANm;
  A := KernelExport(Nm);
  If A = 0 Then
  Begin
    M := LoadModule(Dll);
    If M >= 0 Then A := ModuleExport(M, Nm, 0);
  End;
  ResolveImport := A;
End;

{ Chercher le fichier d'une DLL : nom tel quel, LIBPATH, PATH, racine }
Function FindLibrary(Name : String) : String;
Var Dirs, D, Path, Res : String; P : LongInt;
Begin
  Res := '';
  Name := UpStr(Trim(Name));
  If Pos('.', BaseName(Name)) = 0 Then Name := Name + '.DLL';
  If (Pos('\', Name) > 0) Or (Pos(':', Name) > 0) Then
  Begin
    Path := FullPath(Name);
    If FileExists(Path) Then Res := Path;
  End
  Else
  Begin
    Dirs := LibPath + ';C:\;C:\DLL';
    P := EnvFind('PATH');
    If P <> 0 Then Dirs := Dirs + ';' + PStr(P);
    While (Dirs <> '') And (Res = '') Do
    Begin
      P := Pos(';', Dirs);
      If P > 0 Then
      Begin
        D := Trim(Copy(Dirs, 1, P - 1));
        Dirs := Copy(Dirs, P + 1, 255);
      End
      Else
      Begin
        D := Trim(Dirs); Dirs := '';
      End;
      If D <> '' Then
      Begin
        If D[Length(D)] <> '\' Then D := D + '\';
        Path := FullPath(D + Name);
        If DriveOk(Path) And FileExists(Path) Then Res := Path;
      End;
    End;
  End;
  FindLibrary := Res;
End;

Function LoadModule(Name : String) : LongInt;
Var
  M, I, Buf, Size, Pe, Opt, NSect, OptSize, Base, ImgSize, HdrSize, Entry : LongInt;
  Sec, VSize, VAddr, RawSize, RawPtr, N, ImpRva, ExpRva, Desc, Thunks, Iat, J, V, Adr : LongInt;
  Pref, RelRva, RelSize : LongInt;
  Path, Nm, Dll : String;
  SaveFilter, SaveProc : LongInt;
Begin
  M := FindModule(Name);
  LoadModule := M;
  If M >= 0 Then Exit;
  LoadModule := -1;
  LastError := 126;                        { ERROR_MOD_NOT_FOUND }
  Buf := 0;
  If HdBoot And (Not IfsVols[2].Mounted) And (BootIfsSize > 0) And (UpStr(BaseName(Trim(Name))) = 'HPFS.IFS') Then
  Begin
    { demarrage d'un disque dur : le pilote de C: a ete charge en memoire
      par OS2LDR (zone d'amorcage), C: n'est pas encore monte }
    Path := 'C:\HPFS.IFS';
    Size := BootIfsSize;
    Buf := KAlloc(Size + 1);
    If Buf = 0 Then Exit;
    MoveMem(BootIfsBuf, Buf, Size);
  End
  Else
  Begin
    Path := FindLibrary(Name);
    If Path = '' Then Exit;
  End;
  M := NewModSlot;
  If M < 0 Then
  Begin
    If Buf <> 0 Then KFree(Buf);
    LastError := 8;                        { ERROR_NOT_ENOUGH_MEMORY }
    Exit;
  End;
  If Buf = 0 Then Buf := ReadWholeFile(Path, Size);
  If Buf = 0 Then Exit;
  LastError := ErrBadFormat;
  { DLL d'OS/2 au format LX }
  If LxHeader(Buf, Size) <> 0 Then
  Begin
    If LxLoadDll(Path, Buf, Size, M) Then
    Begin
      LastError := 0;
      LoadModule := M;
    End
    Else
    Begin
      ConPutLn('SYS0191: ' + Path + ' : ' + LxLastErr + '.');
      KLog('LX : ' + Path + ' : ' + LxLastErr);
    End;
    KFree(Buf);
    Exit;
  End;
  Pe := Buf + MemL[0:Buf + $3C];
  If (MemW[0:Buf] <> $5A4D) Or (MemL[0:Pe] <> $00004550) Or (MemW[0:Pe + 4] <> $014C) Then
  Begin
    KFree(Buf);
    Exit;
  End;
  NSect := MemW[0:Pe + 6];
  OptSize := MemW[0:Pe + 20];
  Opt := Pe + 24;
  Entry := MemL[0:Opt + 16];
  Pref := MemL[0:Opt + 28];
  ImgSize := (MemL[0:Opt + 56] + 4095) And Not 4095;
  HdrSize := MemL[0:Opt + 60];
  ExpRva := MemL[0:Opt + 96];
  ImpRva := MemL[0:Opt + 104];
  RelRva := MemL[0:Opt + 136];
  RelSize := MemL[0:Opt + 140];
  { place dans la region des DLL : la base preferee si elle est libre,
    sinon (DLL relocalisable) la premiere place libre }
  Base := Pref;
  If Not DllSpaceFree(Base, ImgSize) Then
  Begin
    If (RelRva = 0) Or (RelSize = 0) Then
    Begin
      ConPutLn('SYS0191: ' + Path + ' n''est pas relocalisable et sa place (' + HexStr(Pref, 8) +
               'h) est prise ou hors de la region des DLL (00800000h-00FFFFFFh).');
      KFree(Buf);
      Exit;
    End;
    Base := DllFindSpace(ImgSize);
    If Base = 0 Then
    Begin
      ConPutLn('SYS0191: plus de place dans la region des DLL pour ' + Path + '.');
      LastError := 8;
      KFree(Buf);
      Exit;
    End;
  End;
  FillMem(Base, ImgSize, 0);
  MoveMem(Buf, Base, HdrSize);
  Sec := Opt + OptSize;
  For I := 0 To NSect - 1 Do
  Begin
    VSize := MemL[0:Sec + 8];
    VAddr := MemL[0:Sec + 12];
    RawSize := MemL[0:Sec + 16];
    RawPtr := MemL[0:Sec + 20];
    N := RawSize;
    If (VSize > 0) And (N > VSize) Then N := VSize;
    If (N > 0) And (VAddr + N <= ImgSize) And (RawPtr + N <= Size) Then
      MoveMem(Buf + RawPtr, Base + VAddr, N);
    Sec := Sec + 40;
  End;
  KFree(Buf);
  If Base <> Pref Then
  Begin
    DllRelocate(Base, RelRva, RelSize, Base - Pref);
    MemL[0:Base + MemL[0:Base + $3C] + 52] := Base;     { ImageBase de l'en-tete }
    KLog(UpStr(BaseName(Path)) + ' relogee en ' + HexStr(Base, 8) + 'h (base ' + HexStr(Pref, 8) + 'h prise).');
  End;
  Mods^[M].Used := True;
  Mods^[M].Name := UpStr(BaseName(Path));
  Mods^[M].Path := Path;
  Mods^[M].Base := Base;
  Mods^[M].Size := ImgSize;
  Mods^[M].NExp := 0;
  Mods^[M].OrdBase := 1;
  Mods^[M].NFunc := 0;
  If ExpRva <> 0 Then
  Begin
    Mods^[M].NExp := MemL[0:Base + ExpRva + 24];
    Mods^[M].OrdBase := MemL[0:Base + ExpRva + 16];
    Mods^[M].NFunc := MemL[0:Base + ExpRva + 20];
    Mods^[M].Funcs := Base + MemL[0:Base + ExpRva + 28];
    Mods^[M].Names := Base + MemL[0:Base + ExpRva + 32];
    Mods^[M].Ords := Base + MemL[0:Base + ExpRva + 36];
  End;
  { importations }
  If ImpRva <> 0 Then
  Begin
    Desc := Base + ImpRva;
    While MemL[0:Desc + 12] <> 0 Do
    Begin
      Dll := PStr(Base + MemL[0:Desc + 12]);
      Thunks := MemL[0:Desc];
      Iat := MemL[0:Desc + 16];
      If Thunks = 0 Then Thunks := Iat;
      J := 0;
      V := MemL[0:Base + Thunks];
      While V <> 0 Do
      Begin
        Nm := PStr(Base + V + 2);
        Adr := KernelExport(Nm);
        If (Adr = 0) And (UpStr(Dll) <> Mods^[M].Name) Then
        Begin
          I := LoadModule(Dll);
          If I >= 0 Then Adr := ModuleExport(I, Nm, 0);
        End;
        If Adr = 0 Then Adr := ModuleExport(M, Nm, 0);
        If Adr = 0 Then
        Begin
          ConPutLn('SYS0191: ' + Nm + ' introuvable (' + Path + ').');
          Mods^[M].Used := False;
          LastError := 127;
          Exit;
        End;
        MemL[0:Base + Iat + J * 4] := Adr;
        Inc(J);
        V := MemL[0:Base + Thunks + J * 4];
      End;
      Desc := Desc + 20;
    End;
  End;
  { initialisation de la DLL (sans modifier le filtre d'exceptions) }
  If Entry <> 0 Then
  Begin
    If CurProc >= 0 Then SaveFilter := Procs[CurProc].Filter Else SaveFilter := ExcFilter;
    SaveProc := CurProc;
    CallEntry(Base + Entry);
    If SaveProc >= 0 Then Procs[SaveProc].Filter := SaveFilter Else ExcFilter := SaveFilter;
  End;
  LastError := 0;
  LoadModule := M;
End;

{ Charger un programme PE ; rend le numero de processus ou -1 }
Function LoadProgram(Path, CmdLine : String) : LongInt;
Var
  Buf, Size, Pe, Opt, NSect, OptSize, Base, ImgSize, HdrSize, Entry : LongInt;
  Total, Phys, PhysSize, Pid, I, Sec, VSize, VAddr, RawSize, RawPtr, N : LongInt;
  ImpRva, Desc, Thunks, Iat, J, V, Adr : LongInt;
  Nm : String;
Begin
  LoadProgram := -1;
  { programme MS-DOS : machine virtuelle DOS }
  If IsDosFile(Path) Then
  Begin
    LoadProgram := LoadDosProgram(Path, CmdLine);
    Exit;
  End;
  Buf := ReadWholeFile(Path, Size);
  If Buf = 0 Then Exit;
  LastError := ErrBadFormat;
  { programme d'OS/2 au format LX }
  If LxHeader(Buf, Size) <> 0 Then
  Begin
    LoadProgram := LxLoadExe(Path, CmdLine, Buf, Size);
    KFree(Buf);
    Exit;
  End;
  If (Size < 512) Or (MemW[0:Buf] <> $5A4D) Then
  Begin
    KFree(Buf);
    Exit;
  End;
  Pe := Buf + MemL[0:Buf + $3C];
  If (MemL[0:Pe] <> $00004550) Or (MemW[0:Pe + 4] <> $014C) Then
  Begin
    KFree(Buf);
    Exit;
  End;
  NSect := MemW[0:Pe + 6];
  OptSize := MemW[0:Pe + 20];
  Opt := Pe + 24;
  Entry := MemL[0:Opt + 16];
  Base := MemL[0:Opt + 28];
  ImgSize := MemL[0:Opt + 56];
  HdrSize := MemL[0:Opt + 60];
  ImpRva := MemL[0:Opt + 104];
  If Base <> ProcWinBase Then
  Begin
    ConPutLn('SYS0193: ' + Path + ' n''est pas lie a l''adresse 00400000h.');
    KFree(Buf);
    Exit;
  End;
  Total := (ImgSize + 4095) And Not 4095;
  PhysSize := Total + ProcStackSize;
  If Total > ProcWinSize Then
  Begin
    LastError := ErrNotEnoughMem;
    KFree(Buf);
    Exit;
  End;
  Pid := -1;
  For I := MaxProcs - 1 DownTo 0 Do
    If Not Procs[I].Used Then Pid := I;
  If Pid < 0 Then
  Begin
    LastError := 164;   { plus de processus }
    KFree(Buf);
    Exit;
  End;
  Phys := PAlloc(PhysSize);
  If Phys = 0 Then
  Begin
    LastError := ErrNotEnoughMem;
    KFree(Buf);
    Exit;
  End;
  { image : en-tetes puis sections }
  FillMem(Phys, PhysSize, 0);
  MoveMem(Buf, Phys, HdrSize);
  Sec := Opt + OptSize;
  For I := 0 To NSect - 1 Do
  Begin
    VSize := MemL[0:Sec + 8];
    VAddr := MemL[0:Sec + 12];
    RawSize := MemL[0:Sec + 16];
    RawPtr := MemL[0:Sec + 20];
    N := RawSize;
    If (VSize > 0) And (N > VSize) Then N := VSize;
    If (N > 0) And (VAddr + N <= Total) And (RawPtr + N <= Size) Then
      MoveMem(Buf + RawPtr, Phys + VAddr, N);
    Sec := Sec + 40;
  End;
  KFree(Buf);
  { liaison des importations par nom }
  If ImpRva <> 0 Then
  Begin
    Desc := Phys + ImpRva;
    While MemL[0:Desc + 12] <> 0 Do
    Begin
      Thunks := MemL[0:Desc];
      Iat := MemL[0:Desc + 16];
      If Thunks = 0 Then Thunks := Iat;
      J := 0;
      V := MemL[0:Phys + Thunks];
      While V <> 0 Do
      Begin
        If V < 0 Then
        Begin
          ConPutLn('SYS0191: importation par ordinal non prise en charge.');
          PFree(Phys);
          Exit;
        End;
        Nm := PStr(Phys + V + 2);
        Adr := ResolveImport(PStr(Phys + MemL[0:Desc + 12]), Nm);
        If Adr = 0 Then
        Begin
          ConPutLn('SYS0191: ' + Nm + ' introuvable dans ' +
                   PStr(Phys + MemL[0:Desc + 12]) + ' (' + Path + ').');
          LastError := 127;
          PFree(Phys);
          Exit;
        End;
        MemL[0:Phys + Iat + J * 4] := Adr;
        Inc(J);
        V := MemL[0:Phys + Thunks + J * 4];
      End;
      Desc := Desc + 20;
    End;
  End;
  { processus }
  Procs[Pid].Used := True;
  Procs[Pid].Running := False;
  Procs[Pid].Parent := CurProc;
  Procs[Pid].PhysBase := Phys;
  Procs[Pid].PhysSize := PhysSize;
  Procs[Pid].ImageSize := Total;
  Procs[Pid].PtAlloc := KAlloc(8192);
  Procs[Pid].PageTable := BuildPageTableAt(Procs[Pid].PtAlloc, Phys, Total);
  Procs[Pid].ExitCode := 259;
  Procs[Pid].Filter := 0;
  Procs[Pid].CmdLine := CmdLine;
  Procs[Pid].CmdBuf := KAlloc(Length(CmdLine) + 1);
  PutPStr(Procs[Pid].CmdBuf, CmdLine, 256);
  Procs[Pid].Name := BaseName(Path);
  Procs[Pid].Path := Path;
  If NextSerial < 2 Then NextSerial := 2;      { PID 1 : le noyau }
  Procs[Pid].Serial := NextSerial;
  Inc(NextSerial);
  { la redirection de la sortie standard est heritee du parent }
  Procs[Pid].StdOutH := 0;
  If CurProc >= 0 Then Procs[Pid].StdOutH := Procs[CurProc].StdOutH;
  Procs[Pid].CurDir := CurDir;
  Procs[Pid].MemLive := True;
  Procs[Pid].HandleOpen := False;
  Procs[Pid].NoPreempt := False;
  Procs[Pid].NextTid := 2;
  Procs[Pid].Sess := 0;
  If CurProc >= 0 Then Procs[Pid].Sess := Procs[CurProc].Sess;
  If (NextSess >= 0) And SUsed[NextSess] Then
  Begin
    Procs[Pid].Sess := NextSess;
    SNew[NextSess] := False;
    NextSess := -1;
  End;
  Procs[Pid].ConSess := Procs[Pid].Sess;
  Procs[Pid].IsLx := False; Procs[Pid].LxFs := 0; Procs[Pid].LxTib := 0;
  ProcEntry[Pid] := ProcWinBase + Entry;
  ProcStack[Pid] := Phys + PhysSize - 16;
  LastError := 0;
  LoadProgram := Pid;
End;

{ --- Memoire physique des processus (blocs tries par adresse) --- }
Function PAlloc(Size : LongInt) : LongInt;
Var I, J, Cand : LongInt;
Begin
  PAlloc := 0;
  Size := (Size + 4095) And Not 4095;
  If (Size <= 0) Or (PCount >= MaxPBlk) Then Exit;
  Cand := PhysProcBase;
  I := 0;
  While I < PCount Do
  Begin
    If Cand + Size <= PBase[I] Then Break;
    If PBase[I] + PSize[I] > Cand Then Cand := (PBase[I] + PSize[I] + 4095) And Not 4095;
    Inc(I);
  End;
  If Cand + Size > PhysTop Then Exit;
  For J := PCount DownTo I + 1 Do
  Begin
    PBase[J] := PBase[J - 1]; PSize[J] := PSize[J - 1];
  End;
  PBase[I] := Cand; PSize[I] := Size;
  Inc(PCount);
  PAlloc := Cand;
End;

{ grands blocs de memoire d'un processus (KrnTaskCtl 15 a 17 :
  DosAllocMem de 64 Ko et plus) : memoire physique au-dela de 16 Mo, vue
  a la meme adresse lineaire, rendue a la fin du processus }
Const
  MaxXBlk = 64;
Var
  XBase, XOwner : Array[0..MaxXBlk - 1] Of LongInt;

Procedure PFree(Base : LongInt);
Var I, J : LongInt;
Begin
  For I := 0 To PCount - 1 Do
    If PBase[I] = Base Then
    Begin
      For J := I To PCount - 2 Do
      Begin
        PBase[J] := PBase[J + 1]; PSize[J] := PSize[J + 1];
      End;
      Dec(PCount);
      Exit;
    End;
End;

Function PhysFree : LongInt;
Var I, T : LongInt;
Begin
  T := PhysTop - PhysProcBase;
  For I := 0 To PCount - 1 Do T := T - PSize[I];
  PhysFree := T;
End;

{ --- Sessions --- }

Procedure SessMap(S : LongInt; Fg : Boolean);
Var I : LongInt;
Begin
  For I := 0 To 15 Do
    If Fg Then MemL[0:SPT[S] + ($A0 + I) * 4] := (($A0 + I) Shl 12) Or 7
    Else MemL[0:SPT[S] + ($A0 + I) * 4] := (GfxScratch + I * 4096) Or 7;
  For I := 0 To 7 Do
    If Fg Then MemL[0:SPT[S] + ($B8 + I) * 4] := (($B8 + I) Shl 12) Or 7
    Else MemL[0:SPT[S] + ($B8 + I) * 4] := (SLvb[S] + I * 4096) Or 7;
End;

Function NewSessAt(S : LongInt; Title : String; Mode : LongInt) : Boolean;
Var I : LongInt;
Begin
  NewSessAt := False;
  SPT[S] := PAlloc(4096);
  SLvb[S] := PAlloc(32768);
  If (SPT[S] = 0) Or (SLvb[S] = 0) Then Exit;
  For I := 0 To 1023 Do MemL[0:SPT[S] + I * 4] := (I Shl 12) Or 3;
  For I := 0 To 16383 Do MemW[0:SLvb[S] + I * 2] := $0720;
  SUsed[S] := True; SNew[S] := False; SPause[S] := False; SPrompt[S] := False; SMode[S] := Mode; STitle[S] := Title; SRet[S] := CurSess;
  SCurRow[S] := 0; SCurCol[S] := 0; SAttr[S] := 7; SConRows[S] := ScrRows; SConOwn[S] := -2;
  SKbdMode[S] := 0; SKbdHead[S] := 0; SKbdTail[S] := 0; SLinePos[S] := 0;
  SLineReady[S] := False; SLineBuf[S] := '';
  SessMap(S, False);
  NewSessAt := True;
End;

Function NewSess(Title : String; Mode : LongInt) : LongInt;
Var I, S : LongInt;
Begin
  S := -1;
  For I := MaxSess - 1 DownTo 1 Do
    If Not SUsed[I] Then S := I;
  If (S >= 0) And Not NewSessAt(S, Title, Mode) Then S := -1;
  NewSess := S;
End;

Procedure FreeSess(S : LongInt);
Begin
  PFree(SPT[S]); PFree(SLvb[S]);
  SUsed[S] := False;
  If PmSess = S Then PmSess := -1;
  SyncFlags;
End;

Procedure SaveSess(S : LongInt);
Var I : LongInt;
Begin
  SCurRow[S] := CurRow; SCurCol[S] := CurCol; SAttr[S] := TextAttr; SConRows[S] := ConRows;
  SConOwn[S] := ConRowsOwner; SKbdMode[S] := KbdMode; SKbdHead[S] := KbdHead; SKbdTail[S] := KbdTail;
  SLinePos[S] := LinePos; SLineReady[S] := LineReady; SLineBuf[S] := LineBuf;
  For I := 0 To 63 Do
  Begin
    SKbdBuf[S * 64 + I] := KbdBuf[I]; SKbdXt[S * 64 + I] := KbdXt[I]; SKbdTm[S * 64 + I] := KbdTm[I];
  End;
End;

Procedure LoadSess(S : LongInt);
Var I : LongInt;
Begin
  CurRow := SCurRow[S]; CurCol := SCurCol[S]; TextAttr := SAttr[S]; ConRows := SConRows[S];
  ConRowsOwner := SConOwn[S]; KbdMode := SKbdMode[S]; KbdHead := SKbdHead[S]; KbdTail := SKbdTail[S];
  LinePos := SLinePos[S]; LineReady := SLineReady[S]; LineBuf := SLineBuf[S];
  For I := 0 To 63 Do
  Begin
    KbdBuf[I] := SKbdBuf[S * 64 + I]; KbdXt[I] := SKbdXt[S * 64 + I]; KbdTm[I] := SKbdTm[S * 64 + I];
  End;
End;

{ la tache qui reprend appartient a la session NS (interruptions masquees) }
Procedure SessSwap(NS : LongInt);
Begin
  If (NS = CurSess) Or (NS < 0) Or Not SUsed[NS] Then Exit;
  SaveSess(CurSess);
  LoadSess(NS);
  CurSess := NS;
  If Not SessNoPde Then
  Begin
    MemL[0:PageDir] := SPT[NS] Or 7;
    FlushTlb;
  End;
  SyncFlags;
End;

{ entree 0 du repertoire de pages de la tache courante : la table de
  sa session, sauf pour les taches du noyau dans la session de la
  machine virtuelle DOS (pages d'identite) }
Function CurPde : LongInt;
Begin
  If VmOn And (VmSess = CurSess) And (TkProc[CurTask] < 0) Then CurPde := KernPT Or 7
  Else CurPde := SPT[CurSess] Or 7;
End;

Function SessProcs(S : LongInt) : LongInt;
Var P, N : LongInt;
Begin
  N := 0;
  For P := 0 To MaxProcs - 1 Do
    If Procs[P].Used And Procs[P].Running And (Procs[P].Sess = S) Then Inc(N);
  SessProcs := N;
End;

{ Mettre la session T au premier plan : l'ecran de la session quittee est
  garde dans son tampon, celui de T est affiche (mode texte : crochet de
  VIOCALLS.DLL ; Presentation Manager se redessine en voyant changer le
  compteur des bascules) }
Procedure DoSwitch(T : LongInt);
Var From, H, R, C, P : LongInt;
Begin
  If (T < 0) Or (T >= MaxSess) Or Not SUsed[T] Or (T = FgSess) Then Exit;
  asm
    cli
  end;
  Switching := 1;
  From := FgSess;
  MemL[0:PageDir] := KernPT Or 7;
  FlushTlb;
  If VmOn And (From = VmSess) Then VmSwitchOut;
  If SUsed[From] And (SMode[From] = 0) Then MoveMem($B8000, SLvb[From], 32768);
  If SUsed[From] Then SessMap(From, False);
  SessMap(T, True);
  FgSess := T;
  Inc(Epoch);
  SyncFlags;
  If SMode[T] = 0 Then
  Begin
    H := SwHook;
    If H <> 0 Then
      asm
        push 0
        mov eax,H
        call eax
        add esp,4
      end;
    MoveMem(SLvb[T], $B8000, 32768);
    If T = CurSess Then
    Begin
      R := CurRow; C := CurCol;
    End
    Else
    Begin
      R := SCurRow[T]; C := SCurCol[T];
    End;
    P := R * ScrCols + C;
    Port[$3D4] := $0F; Port[$3D5] := P And $FF;
    Port[$3D4] := $0E; Port[$3D5] := (P Shr 8) And $FF;
  End;
  If VmOn And (T = VmSess) Then VmSwitchIn;
  MemL[0:PageDir] := CurPde;
  FlushTlb;
  Switching := 0;
  SyncFlags;
  asm
    sti
  end;
End;

Procedure CheckPending;
Var T : LongInt;
Begin
  If PendSwitch < 0 Then Exit;
  T := PendSwitch;
  PendSwitch := -1;
  DoSwitch(T);
End;

Procedure InitSessions;
Var I : LongInt;
Begin
  For I := 0 To MaxSess - 1 Do
  Begin
    SUsed[I] := False; SNew[I] := False;
  End;
  KernPT := PAlloc(4096);
  For I := 0 To 1023 Do MemL[0:KernPT + I * 4] := (I Shl 12) Or 3;
  GfxScratch := PAlloc(65536);
  CurSess := 0; FgSess := 0; PmSess := -1; Epoch := 0; Switching := 0;
  PendSwitch := -1; NextSess := -1; SwHook := 0;
  PauseMsg := ' Programme termine. Appuyez sur une touche pour revenir au bureau.';
  If NewSessAt(0, 'Noyau', 0) Then
  Begin
    SessMap(0, True);
    MemL[0:PageDir] := SPT[0] Or 7;
    FlushTlb;
  End;
  SyncFlags;
End;

{ --- Taches --- }

{ Changer de pile : les registres et les drapeaux sont sauves sur la pile
  de la tache courante (ESP dans SwSave^), puis ceux de la tache dont la
  pile est SwNew sont repris ; on revient dans la tache reprise, a la
  sortie de son propre appel a CtxSwitch. }
Procedure CtxSwitch;
Begin
  asm
    pushfd
    cli
    pushad
    mov eax,SwSave
    mov [eax],esp
    mov eax,SwNew
    mov esp,eax
    mov eax,SwPde
    test eax,eax
    jz @nopde
    mov edx,PageDir
    mov [edx],eax
    mov eax,cr3
    mov cr3,eax
  @nopde:
    popad
    popfd
  end;
End;

Function NextTask : LongInt;
Var I, T : LongInt;
Begin
  NextTask := CurTask;
  For I := 1 To MaxTasks Do
  Begin
    T := (CurTask + I) Mod MaxTasks;
    If TkUsed[T] = 1 Then
    Begin
      NextTask := T;
      Exit;
    End;
  End;
End;

{ Passer a la tache N (interruptions masquees par l'appelant) }
Procedure SwitchTo(N : LongInt);
Begin
  If (N = CurTask) Or (N < 0) Then Exit;
  TkLastErr[CurTask] := LastError;
  SessNoPde := True;
  If TkProc[N] >= 0 Then SessSwap(Procs[TkProc[N]].Sess) Else SessSwap(0);
  SessNoPde := False;
  { entree 0 du repertoire (table de la session) changee par CtxSwitch
    apres le changement de pile (la pile de la tache 0 est en memoire
    basse) ; dans la session de la machine virtuelle DOS, dont le premier
    Mo est celui de la machine, les taches du noyau gardent les pages
    d'identite }
  If VmOn And (VmSess = CurSess) And (TkProc[N] < 0) Then SwPde := KernPT Or 7
  Else SwPde := SPT[CurSess] Or 7;
  If TkProc[N] <> TkProc[CurTask] Then MapWindow(TkProc[N]);
  SwSave := LongInt(@TkEsp) + CurTask * 4;
  SwNew := TkEsp[N];
  If TkEsp0[N] <> 0 Then Tss[1] := TkEsp0[N];
  { FS : TIB des programmes LX (sinon les donnees du noyau) }
  asm
    xor eax,eax
    mov ax,fs
    mov FsTmp,eax
  end;
  TkFs[CurTask] := FsTmp;
  FsTmp := TkFs[N];
  If FsTmp = 0 Then FsTmp := $10;
  asm
    mov eax,FsTmp
    mov fs,ax
  end;
  CurTask := N;
  CurProc := TkProc[N];
  LastError := TkLastErr[N];
  SliceStart := Ticks;
  CtxSwitch;
End;

{ Rendre la memoire des taches et des processus termines }
Procedure Reap;
Var T, P, K : LongInt; Alive : Boolean;
Begin
  For T := 1 To MaxTasks - 1 Do
    If (TkUsed[T] = 2) And (T <> CurTask) Then
    Begin
      If TkStack[T] <> 0 Then PFree(TkStack[T]);
      TkStack[T] := 0;
      TkUsed[T] := 0;
    End;
  For P := 0 To MaxProcs - 1 Do
    If Procs[P].Used And Not Procs[P].Running And Procs[P].MemLive Then
    Begin
      Alive := False;
      For K := 0 To MaxTasks - 1 Do
        If (TkUsed[K] <> 0) And (TkProc[K] = P) Then Alive := True;
      If Not Alive Then
      Begin
        For K := 0 To MaxXBlk - 1 Do
          If (XBase[K] <> 0) And (XOwner[K] = P) Then
          Begin
            PFree(XBase[K]);
            XBase[K] := 0;
          End;
        PFree(Procs[P].PhysBase);
        KFree(Procs[P].PtAlloc);
        Procs[P].MemLive := False;
        If Not Procs[P].HandleOpen Then Procs[P].Used := False;
      End;
    End;
  { sessions sans processus : retour a la session d'origine, puis fin }
  For P := 1 To MaxSess - 1 Do
    If SUsed[P] And Not SNew[P] And (P <> CurSess) And (P <> NextSess) And (SessProcs(P) = 0) Then
    Begin
      If FgSess = P Then
      Begin
        { pause a la fin : invite sur la derniere ligne, puis une touche }
        If SPause[P] Then
        Begin
          If Not SPrompt[P] Then
          Begin
            SPrompt[P] := True;
            SKbdTail[P] := SKbdHead[P];
            MemL[0:PageDir] := KernPT Or 7;
            FlushTlb;
            For K := 0 To ScrCols - 1 Do
              If K < Length(PauseMsg) Then MemW[0:$B8000 + (24 * ScrCols + K) * 2] := $7000 Or Ord(PauseMsg[K + 1])
              Else MemW[0:$B8000 + (24 * ScrCols + K) * 2] := $7020;
            MemL[0:PageDir] := CurPde;
            FlushTlb;
          End
          Else If SKbdHead[P] <> SKbdTail[P] Then SPause[P] := False;
        End;
        If Not SPause[P] Then
        Begin
          K := 0;
          If SUsed[SRet[P]] And (SRet[P] <> P) Then K := SRet[P]
          Else If (PmSess >= 0) And (PmSess <> P) Then K := PmSess;
          PendSwitch := K;
        End;
      End
      Else FreeSess(P);
    End;
End;

{ Ceder le processeur (attente cooperative) }
Procedure Yield;
Begin
  CheckPending;
  asm
    cli
  end;
  Reap;
  SwitchTo(NextTask);
  asm
    sti
  end;
End;

{ Preemption par la minuterie (interruptions masquees) }
Procedure Preempt;
Begin
  If (CurProc >= 0) And Procs[CurProc].NoPreempt Then Exit;
  SwitchTo(NextTask);
End;

Procedure EndThread(Code : LongInt); Forward;

{ Premiere execution d'une tache : fil 1 d'un processus (point d'entree du
  programme) ou fil cree par KrnTaskCtl (fonction _System (argument)) }
Procedure TaskStart;
Var F, A, R : LongInt;
Begin
  asm
    sti
  end;
  F := TkFn[CurTask]; A := TkArg[CurTask];
  If TkTid[CurTask] = 1 Then
  Begin
    asm
      mov eax,F
      call eax
    end;
    KillCurrentProcess(0);
  End;
  R := 0;
  asm
    mov eax,A
    push eax
    mov eax,F
    call eax
    add esp,4
    mov R,eax
  end;
  EndThread(R);
End;

{ Nouvelle tache du processus Proc ; pile dont le sommet est StackTop
  (bloc physique StackBlk a rendre a la fin, 0 pour la pile du processus) }
Function NewTask(Proc, Fn, Arg, StackTop, StackBlk, Tid : LongInt) : LongInt;
Var T, S, F, E, K : LongInt;
Begin
  NewTask := -1;
  T := -1;
  For K := MaxTasks - 1 DownTo 1 Do
    If TkUsed[K] = 0 Then T := K;
  If T < 0 Then Exit;
  S := StackTop And Not 15;
  MemL[0:S - 4] := LongInt(@TaskStart);
  MemL[0:S - 8] := 0;
  F := S - 8;
  E := F - 36;
  For K := 0 To 8 Do MemL[0:E + K * 4] := 0;
  MemL[0:E + 8] := F;          { EBP repris par POPAD }
  MemL[0:E + 32] := $202;      { EFLAGS : IF }
  TkEsp[T] := E;
  TkProc[T] := Proc; TkStack[T] := StackBlk; TkLastErr[T] := 0; TkTid[T] := Tid;
  TkFn[T] := Fn; TkArg[T] := Arg;
  TkFs[T] := 0;
  If (Proc >= 0) And Procs[Proc].IsLx Then TkFs[T] := Procs[Proc].LxFs;
  asm
    cli
  end;
  TkUsed[T] := 1;
  Inc(NTasks);
  asm
    sti
  end;
  NewTask := T;
End;

{ Demarrer le fil 1 d'un processus charge }
Function StartProcess(Pid : LongInt) : Boolean;
Var Ok : Boolean;
Begin
  Procs[Pid].Running := True;
  Procs[Pid].NextTid := 2;
  Ok := NewTask(Pid, ProcEntry[Pid], 0, ProcStack[Pid], 0, 1) >= 0;
  If Not Ok Then Procs[Pid].Running := False;
  StartProcess := Ok;
End;

{ Fin de la tache courante (sans retour) }
Procedure EndThread(Code : LongInt);
Var K : LongInt; Others : Boolean;
Begin
  Others := False;
  For K := 1 To MaxTasks - 1 Do
    If (K <> CurTask) And (TkUsed[K] = 1) And (TkProc[K] = CurProc) Then Others := True;
  If (Not Others) Or (TkTid[CurTask] = 1) Then KillCurrentProcess(Code);
  asm
    cli
  end;
  TkUsed[CurTask] := 2;
  Dec(NTasks);
  SwitchTo(NextTask);
End;

{ Fin du processus courant : ses ressources sont rendues, ses fils
  arretes ; la tache passe la main et ne reprend jamais. }
Procedure KillCurrentProcess(Code : LongInt);
Var Pid, I : LongInt;
Begin
  Pid := CurProc;
  If Pid < 0 Then Exit;
  If VmOn And (Pid = VmPid) Then DosStop;
  If Procs[Pid].IsLx And (Procs[Pid].LxFs <> 0) Then
  Begin
    SelFree(Procs[Pid].LxFs, 1);
    Procs[Pid].LxFs := 0;
    asm
      mov ax,10h
      mov fs,ax
    end;
  End;
  Procs[Pid].ExitCode := Code;
  KbdMode := 0;
  MonProcessExit(Procs[Pid].Serial);
  IfsProcessExit(Pid);
  For I := 0 To MaxFiles - 1 Do
    If Files[I].Used And (Files[I].Owner = Pid) Then Files[I].Used := False;
  For I := 0 To MaxFinds - 1 Do
    If Finds[I].Used And (Finds[I].Owner = Pid) Then Finds[I].Used := False;
  KFreeOwner(Pid);
  { console reduite par ce processus : rendre toutes les lignes }
  If (ConRows < ScrRows) And (ConRowsOwner = Pid) Then
  Begin
    For I := ConRows * ScrCols To ScrRows * ScrCols - 1 Do
      MemW[0:VideoBase + I * 2] := $0720;
    ConRows := ScrRows;
    ConRowsOwner := -2;
  End;
  KFree(Procs[Pid].CmdBuf);
  Procs[Pid].CmdBuf := 0;
  LineReady := False;
  asm
    cli
  end;
  Procs[Pid].Running := False;
  For I := 1 To MaxTasks - 1 Do
    If (TkUsed[I] = 1) And (TkProc[I] = Pid) Then
    Begin
      TkUsed[I] := 2;
      Dec(NTasks);
    End;
  SwitchTo(NextTask);
  { jamais atteint }
  asm
    cli
  @h:
    hlt
    jmp @h
  end;
End;

Procedure ExitProcess(Code : LongInt);
Begin
  If CurProc >= 0 Then KillCurrentProcess(Code);
  ConPutLn('OS2KRNL: fin du noyau.');
  asm
    cli
  @h:
    hlt
    jmp @h
  end;
End;

Function CreateProcessA(App, Cmd, PAttr, TAttr, Inherit, Flags, Env, Dir, SInfo, PInfo : LongInt) : LongInt;
Var CmdS, Prog, Path : String; P, Pid : LongInt;
Begin
  CreateProcessA := 0;
  CmdS := Trim(PStr(Cmd));
  If App <> 0 Then
    Prog := PStr(App)
  Else If (Length(CmdS) > 0) And (CmdS[1] = '"') Then
  Begin
    P := Pos('"', Copy(CmdS, 2, 255));
    If P = 0 Then P := Length(CmdS);
    Prog := Copy(CmdS, 2, P - 1);
  End
  Else
  Begin
    P := Pos(' ', CmdS);
    If P = 0 Then Prog := CmdS Else Prog := Copy(CmdS, 1, P - 1);
  End;
  Path := FindProgram(Prog);
  If Path = '' Then
  Begin
    LastError := ErrFileNotFound;
    Exit;
  End;
  Pid := LoadProgram(Path, CmdS);
  If Pid < 0 Then Exit;
  If Dir <> 0 Then Procs[Pid].CurDir := FullPath(PStr(Dir));
  If PInfo <> 0 Then
  Begin
    MemL[0:PInfo] := HProcBase + Pid;
    MemL[0:PInfo + 4] := HThreadBase + Pid;
    MemL[0:PInfo + 8] := Procs[Pid].Serial;
    MemL[0:PInfo + 12] := 1;
  End;
  { le processus s'execute en parallele ; WaitForSingleObject attend sa fin }
  Procs[Pid].HandleOpen := True;
  If Not StartProcess(Pid) Then
  Begin
    Procs[Pid].HandleOpen := False;
    LastError := 164;
    Exit;
  End;
  CreateProcessA := 1;
End;

{ Attendre la fin d'un processus (handle de CreateProcessA) ; Ms -1 :
  sans limite. Rend 0 (termine) ou 258 (delai ecoule). }
Function WaitForSingleObject(H, Ms : LongInt) : LongInt;
Var P, T0 : LongInt;
Begin
  WaitForSingleObject := 0;
  If (H < HProcBase) Or (H >= HProcBase + MaxProcs) Then Exit;
  P := H - HProcBase;
  T0 := Ticks;
  While Procs[P].Used And Procs[P].Running Do
  Begin
    If (Ms <> -1) And ((Ticks - T0) * 10 >= Ms) Then
    Begin
      WaitForSingleObject := 258;
      Exit;
    End;
    Idle;
  End;
End;

Function GetExitCodeProcess(H, PCode : LongInt) : LongInt;
Begin
  GetExitCodeProcess := 0;
  If (H < HProcBase) Or (H >= HProcBase + MaxProcs) Then Exit;
  If PCode <> 0 Then
  Begin
    If Procs[H - HProcBase].Running Then MemL[0:PCode] := 259     { STILL_ACTIVE }
    Else MemL[0:PCode] := Procs[H - HProcBase].ExitCode;
  End;
  GetExitCodeProcess := 1;
End;

{ KrnTaskCtl(op, p1, p2, p3) : taches et processus (DOSCALLS.DLL)
    0 ceder le processeur
    1 creer un fil : p1 fonction _System (argument), p2 argument, p3
      taille de la pile ; rend l'identificateur du fil (0 : erreur)
    2 attendre la fin du processus de PID p1 (p2 delai en ms, -1 sans
      limite) : 0 termine, 258 delai ecoule, -1 inconnu
    3 etat du processus de PID p1 : 1 en cours, 0 termine (p2^ : code de
      sortie), -1 inconnu
    4 preemption du processus courant permise (p1 = 0) ou non (p1 = 1)
    5 arreter le processus de PID p1 (code p2)
    6 identificateur du fil courant
    7 attendre la fin du fil p1 du processus (p2 delai) : 0 ou 258
    8 terminer le fil courant (code p1)
    9 etat du fil p1 du processus : 1 actif, 0 termine
   10 nombre de taches actives
   11 PID du parent du processus de PID p1
   12 nombre de taches qui peuvent encore agir pour l'appelant (autres
      fils du processus, autres processus qui ne sont pas ses ancetres)
   13 arreter le fil p1 du processus (pas le fil courant)
   14 identificateur du prochain fil cree (p1) }
Function ProcBySerial(S : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxProcs - 1 Do
    If Procs[I].Used And (Procs[I].Serial = S) Then R := I;
  ProcBySerial := R;
End;

Function TaskOfTid(Tid : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 1 To MaxTasks - 1 Do
    If (TkUsed[K] = 1) And (TkProc[K] = CurProc) And (TkTid[K] = Tid) Then R := K;
  TaskOfTid := R;
End;

Procedure KillOther(P, Code : LongInt);
Var K : LongInt;
Begin
  If VmOn And (P = VmPid) Then DosStop;
  If Procs[P].IsLx And (Procs[P].LxFs <> 0) Then
  Begin
    SelFree(Procs[P].LxFs, 1);
    Procs[P].LxFs := 0;
  End;
  For K := 0 To MaxFiles - 1 Do
    If Files[K].Used And (Files[K].Owner = P) Then Files[K].Used := False;
  For K := 0 To MaxFinds - 1 Do
    If Finds[K].Used And (Finds[K].Owner = P) Then Finds[K].Used := False;
  MonProcessExit(Procs[P].Serial);
  KFreeOwner(P);
  asm
    cli
  end;
  Procs[P].ExitCode := Code;
  Procs[P].Running := False;
  For K := 1 To MaxTasks - 1 Do
    If (TkUsed[K] = 1) And (TkProc[K] = P) Then
    Begin
      TkUsed[K] := 2;
      Dec(NTasks);
    End;
  asm
    sti
  end;
End;

Function KrnTaskCtl(Op, P1, P2, P3 : LongInt) : LongInt;
Var P, S, Sz, T0, K : LongInt;
Begin
  KrnTaskCtl := 0;
  Case Op Of
    0 : Yield;
    1 : If CurProc >= 0 Then
        Begin
          Sz := P3;
          If Sz < ThreadStackMin Then Sz := ThreadStackMin;
          Sz := (Sz + 4095) And Not 4095;
          S := PAlloc(Sz);
          If S <> 0 Then
          Begin
            K := NewTask(CurProc, P1, P2, S + Sz - 16, S, Procs[CurProc].NextTid);
            If K < 0 Then PFree(S)
            Else
            Begin
              KrnTaskCtl := Procs[CurProc].NextTid;
              Inc(Procs[CurProc].NextTid);
            End;
          End;
        End;
    2 : Begin
          P := ProcBySerial(P1);
          If P < 0 Then
          Begin
            KrnTaskCtl := -1;
            Exit;
          End;
          T0 := Ticks;
          While Procs[P].Used And Procs[P].Running And (Procs[P].Serial = P1) Do
          Begin
            If (P2 <> -1) And ((Ticks - T0) * 10 >= P2) Then
            Begin
              KrnTaskCtl := 258;
              Exit;
            End;
            Idle;
          End;
        End;
    3 : Begin
          P := ProcBySerial(P1);
          If P < 0 Then KrnTaskCtl := -1
          Else If Procs[P].Running Then KrnTaskCtl := 1
          Else If P2 <> 0 Then MemL[0:P2] := Procs[P].ExitCode;
        End;
    4 : If CurProc >= 0 Then Procs[CurProc].NoPreempt := P1 <> 0;
    5 : Begin
          P := ProcBySerial(P1);
          If (P < 0) Or Not Procs[P].Running Then KrnTaskCtl := -1
          Else If P = CurProc Then KillCurrentProcess(P2)
          Else KillOther(P, P2);
        End;
    6 : If CurTask > 0 Then KrnTaskCtl := TkTid[CurTask] Else KrnTaskCtl := 1;
    7 : Begin
          T0 := Ticks;
          While TaskOfTid(P1) >= 0 Do
          Begin
            If (P2 <> -1) And ((Ticks - T0) * 10 >= P2) Then
            Begin
              KrnTaskCtl := 258;
              Exit;
            End;
            Idle;
          End;
        End;
    8 : EndThread(P1);
    9 : If TaskOfTid(P1) >= 0 Then KrnTaskCtl := 1;
   10 : KrnTaskCtl := NTasks;
   11 : Begin
          P := ProcBySerial(P1);
          If (P >= 0) And (Procs[P].Parent >= 0) Then KrnTaskCtl := Procs[Procs[P].Parent].Serial
          Else If P >= 0 Then KrnTaskCtl := 1;
        End;
   12 : Begin
          S := 0;
          For K := 1 To MaxTasks - 1 Do
            If (TkUsed[K] = 1) And (K <> CurTask) Then
            Begin
              { les ancetres de l'appelant attendent sa fin }
              P := CurProc; Sz := 0;
              If TkProc[K] <> CurProc Then
              Begin
                While (P >= 0) And (Sz = 0) Do
                Begin
                  P := Procs[P].Parent;
                  If P = TkProc[K] Then Sz := 1;
                End;
              End;
              If Sz = 0 Then Inc(S);
            End;
          KrnTaskCtl := S;
        End;
   13 : Begin
          K := TaskOfTid(P1);
          If (K > 0) And (K <> CurTask) Then
          Begin
            asm
              cli
            end;
            TkUsed[K] := 2;
            Dec(NTasks);
            asm
              sti
            end;
          End
          Else KrnTaskCtl := -1;
        End;
   14 : If (CurProc >= 0) And (P1 > 1) Then Procs[CurProc].NextTid := P1;
   18 : If (CurProc >= 0) And Procs[CurProc].IsLx Then KrnTaskCtl := Procs[CurProc].LxTib;
   { grands blocs de memoire du processus : 15 allouer (P1 octets),
     16 liberer (P1 adresse), 17 le bloc P1 existe-t-il ? }
   15 : If (CurProc >= 0) And (P1 > 0) Then
        Begin
          K := 0;
          While (K < MaxXBlk) And (XBase[K] <> 0) Do Inc(K);
          If K < MaxXBlk Then
          Begin
            Sz := (P1 + 4095) And Not 4095;
            S := PAlloc(Sz);
            If S <> 0 Then
            Begin
              FillMem(S, Sz, 0);
              XBase[K] := S; XOwner[K] := CurProc;
              KrnTaskCtl := S;
            End;
          End;
        End;
   16 : For K := 0 To MaxXBlk - 1 Do
          If (P1 <> 0) And (XBase[K] = P1) Then
          Begin
            PFree(P1);
            XBase[K] := 0;
            KrnTaskCtl := 1;
          End;
   17 : For K := 0 To MaxXBlk - 1 Do
          If (P1 <> 0) And (XBase[K] = P1) Then KrnTaskCtl := 1;
  End;
End;

{ ==================================================================== }
{ Video : appel du BIOS en mode reel, modes VESA (VBE)                 }
{ ==================================================================== }
{ BiosCode : KERNEL/BIOSCALL.ASM assemble (nasm -f bin), recopie en
  0000:7000 ; bloc de parametres en 0000:7E00 (voir BIOSCALL.ASM) ;
  tampons du VBE : 0000:8000 (VbeInfoBlock, 512 octets) et 0000:8200
  (ModeInfoBlock, 256 octets). La memoire basse au-dessous de 80000h
  n'est plus utilisee apres le demarrage (OS2LDR). }
Const
  BiosCodeLen = 490;
  BiosCode : Array[0..BiosCodeLen - 1] Of Byte = (
    $60, $9C, $FA, $89, $25, $D8, $71, $00, $00, $0F, $01, $05, $CC, $71, $00, $00,
    $0F, $01, $0D, $D2, $71, $00, $00, $0F, $20, $C0, $A3, $DC, $71, $00, $00, $0F,
    $20, $D8, $A3, $E0, $71, $00, $00, $0F, $20, $E0, $A3, $E4, $71, $00, $00, $A0,
    $20, $7E, $00, $00, $A2, $CD, $70, $00, $00, $0F, $01, $15, $C0, $71, $00, $00,
    $EA, $47, $70, $00, $00, $18, $00, $B8, $20, $00, $8E, $D8, $8E, $C0, $8E, $E0,
    $8E, $E8, $8E, $D0, $0F, $20, $C0, $66, $25, $FE, $FF, $FF, $7F, $0F, $22, $C0,
    $EA, $65, $70, $00, $00, $31, $C0, $8E, $D8, $8E, $C0, $8E, $E0, $8E, $E8, $8E,
    $D0, $BC, $F0, $6F, $0F, $01, $1E, $C6, $71, $E4, $21, $A2, $E8, $71, $E4, $A1,
    $A2, $E9, $71, $B0, $11, $E6, $20, $E6, $A0, $B0, $08, $E6, $21, $B0, $70, $E6,
    $A1, $B0, $04, $E6, $21, $B0, $02, $E6, $A1, $B0, $01, $E6, $21, $E6, $A1, $B0,
    $FF, $E6, $21, $E6, $A1, $66, $A1, $00, $7E, $66, $8B, $1E, $04, $7E, $66, $8B,
    $0E, $08, $7E, $66, $8B, $16, $0C, $7E, $66, $8B, $36, $10, $7E, $66, $8B, $3E,
    $14, $7E, $FF, $36, $1A, $7E, $FF, $36, $18, $7E, $07, $1F, $CD, $10, $1E, $50,
    $31, $C0, $8E, $D8, $58, $66, $A3, $00, $7E, $66, $89, $1E, $04, $7E, $66, $89,
    $0E, $08, $7E, $66, $89, $16, $0C, $7E, $66, $89, $36, $10, $7E, $66, $89, $3E,
    $14, $7E, $8C, $06, $18, $7E, $8F, $06, $1A, $7E, $66, $9C, $66, $8F, $06, $1C,
    $7E, $FA, $B0, $11, $E6, $20, $E6, $A0, $B0, $20, $E6, $21, $B0, $28, $E6, $A1,
    $B0, $04, $E6, $21, $B0, $02, $E6, $A1, $B0, $01, $E6, $21, $E6, $A1, $A0, $E8,
    $71, $E6, $21, $A0, $E9, $71, $E6, $A1, $0F, $01, $16, $C0, $71, $0F, $20, $C0,
    $66, $83, $C8, $01, $0F, $22, $C0, $66, $EA, $3F, $71, $00, $00, $08, $00, $66,
    $B8, $10, $00, $8E, $D8, $8E, $C0, $8E, $E0, $8E, $E8, $8E, $D0, $A1, $E0, $71,
    $00, $00, $0F, $22, $D8, $A1, $E4, $71, $00, $00, $0F, $22, $E0, $A1, $DC, $71,
    $00, $00, $0F, $22, $C0, $EB, $00, $0F, $01, $15, $CC, $71, $00, $00, $0F, $01,
    $1D, $D2, $71, $00, $00, $EA, $7C, $71, $00, $00, $08, $00, $66, $B8, $10, $00,
    $8E, $D8, $8E, $C0, $8E, $E0, $8E, $E8, $8E, $D0, $8B, $25, $D8, $71, $00, $00,
    $9D, $61, $C3, $90, $90, $90, $90, $90, $00, $00, $00, $00, $00, $00, $00, $00,
    $FF, $FF, $00, $00, $00, $9A, $CF, $00, $FF, $FF, $00, $00, $00, $92, $CF, $00,
    $FF, $FF, $00, $00, $00, $9A, $00, $00, $FF, $FF, $00, $00, $00, $92, $00, $00,
    $27, $00, $98, $71, $00, $00, $FF, $03, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00);
  BiosAt = $7000;
  BiosParm = $7E00;
  VbeMax = 96;

Var
  BiosReady : Boolean;
  VbeScanned : Boolean;
  VbeVer, VbeMemKb, VbeCount : LongInt;
  VbeOem : String[79];
  VmNo, VmW, VmH, VmBpp, VmPitch, VmLfb, VmModel : Array[0..VbeMax - 1] Of LongInt;
  VmRPos, VmRSize, VmGPos, VmGSize, VmBPos, VmBSize : Array[0..VbeMax - 1] Of LongInt;

{ INT N du BIOS avec les registres du bloc 0000:7E00 }
Procedure BiosInt(N : LongInt);
Var I : LongInt;
Begin
  If Not BiosReady Then
  Begin
    For I := 0 To BiosCodeLen - 1 Do Mem[0:BiosAt + I] := BiosCode[I];
    BiosReady := True;
  End;
  Mem[0:BiosParm + $20] := N;
  asm
    mov eax,7000h
    call eax
  end;
End;

Procedure BiosRegs(RAx, RBx, RCx, RDx, RSi, RDi, REs : LongInt);
Begin
  MemL[0:BiosParm] := RAx; MemL[0:BiosParm + 4] := RBx; MemL[0:BiosParm + 8] := RCx;
  MemL[0:BiosParm + 12] := RDx; MemL[0:BiosParm + 16] := RSi; MemL[0:BiosParm + 20] := RDi;
  MemW[0:BiosParm + $18] := REs; MemW[0:BiosParm + $1A] := 0;
End;

{ adresse lineaire d'un pointeur long (segment:deplacement) }
Function FarLin(P : LongInt) : LongInt;
Begin
  FarLin := ((P Shr 16) And $FFFF) * 16 + (P And $FFFF);
End;

{ Releve des modes VESA utilisables : graphiques, memoire lineaire,
  640 x 480 au moins, 8 bits (palette) ou 15/16/24/32 bits (couleurs
  directes) }
Procedure VbeScan;
Var I, N, M, A, Attr, Bpp, Model, L : LongInt; List : Array[0..255] Of LongInt; S : String;
Begin
  If VbeScanned Then Exit;
  VbeScanned := True;
  VbeVer := 0; VbeCount := 0; VbeMemKb := 0; VbeOem := '';
  For I := 0 To 511 Do Mem[0:$8000 + I] := 0;
  Mem[0:$8000] := Ord('V'); Mem[0:$8001] := Ord('B'); Mem[0:$8002] := Ord('E'); Mem[0:$8003] := Ord('2');
  BiosRegs($4F00, 0, 0, 0, 0, 0, $0800);
  BiosInt($10);
  If (MemL[0:BiosParm] And $FFFF) <> $004F Then Exit;
  If (Mem[0:$8000] <> Ord('V')) Or (Mem[0:$8001] <> Ord('E')) Or (Mem[0:$8002] <> Ord('S')) Or
     (Mem[0:$8003] <> Ord('A')) Then Exit;
  VbeVer := MemW[0:$8004];
  VbeMemKb := MemW[0:$8012] * 64;
  A := FarLin(MemL[0:$8006]);
  S := '';
  If (A > 0) And (A < $100000) Then
    While (Length(S) < 79) And (Mem[0:A + Length(S)] <> 0) Do S := S + Chr(Mem[0:A + Length(S)]);
  VbeOem := S;
  A := FarLin(MemL[0:$800E]);
  N := 0;
  If (A > 0) And (A < $100000) Then
    While (N < 256) And (MemW[0:A + N * 2] <> $FFFF) Do
    Begin
      List[N] := MemW[0:A + N * 2];
      Inc(N);
    End;
  For I := 0 To N - 1 Do
    If VbeCount < VbeMax Then
    Begin
      M := List[I];
      For L := 0 To 255 Do Mem[0:$8200 + L] := 0;
      BiosRegs($4F01, 0, M, 0, 0, 0, $0820);
      BiosInt($10);
      If (MemL[0:BiosParm] And $FFFF) = $004F Then
      Begin
        Attr := MemW[0:$8200];
        Bpp := Mem[0:$8219]; Model := Mem[0:$821B];
        If (Bpp = 16) And (Mem[0:$8221] = 5) Then Bpp := 15;
        If ((Attr And $91) = $91) And (MemL[0:$8228] <> 0) And (MemW[0:$8212] >= 640) And (MemW[0:$8214] >= 480) And
           (((Model = 4) And (Bpp = 8)) Or ((Model = 6) And ((Bpp = 15) Or (Bpp = 16) Or (Bpp = 24) Or (Bpp = 32)))) Then
        Begin
          L := VbeCount;
          VmNo[L] := M; VmW[L] := MemW[0:$8212]; VmH[L] := MemW[0:$8214]; VmBpp[L] := Bpp; VmModel[L] := Model;
          VmPitch[L] := MemW[0:$8210];
          If (VbeVer >= $0300) And (MemW[0:$8232] <> 0) Then VmPitch[L] := MemW[0:$8232];
          VmLfb[L] := MemL[0:$8228];
          VmRSize[L] := Mem[0:$821F]; VmRPos[L] := Mem[0:$8220];
          VmGSize[L] := Mem[0:$8221]; VmGPos[L] := Mem[0:$8222];
          VmBSize[L] := Mem[0:$8223]; VmBPos[L] := Mem[0:$8224];
          Inc(VbeCount);
        End;
      End;
    End;
End;

{ KrnVideo(op, p1, p2) : carte video (VIOCALLS.DLL)
    0 : version du VBE (0 : pas de VESA)    1 : nombre de modes utilisables
    2 : mode p1 -> 52 octets en p2 : numero, largeur, hauteur, bits par
        pel, octets par ligne, adresse de la memoire lineaire, modele,
        position et taille des champs rouge, vert, bleu
    3 : passer au mode VESA p1 (memoire lineaire) ; 0 si reussi
    4 : passer au mode p1 du BIOS (INT 10h, AH = 0 ; 03h : texte)
    5 : informations : version, memoire (Ko), constructeur (ASCIIZ) en p2 }
Function KrnVideo(Op, P1, P2 : LongInt) : LongInt;
Begin
  KrnVideo := 0;
  Case Op Of
    0 : Begin
          VbeScan;
          KrnVideo := VbeVer;
        End;
    1 : Begin
          VbeScan;
          KrnVideo := VbeCount;
        End;
    2 : Begin
          VbeScan;
          If (P1 >= 0) And (P1 < VbeCount) And (P2 <> 0) Then
          Begin
            MemL[0:P2] := VmNo[P1]; MemL[0:P2 + 4] := VmW[P1]; MemL[0:P2 + 8] := VmH[P1];
            MemL[0:P2 + 12] := VmBpp[P1]; MemL[0:P2 + 16] := VmPitch[P1]; MemL[0:P2 + 20] := VmLfb[P1];
            MemL[0:P2 + 24] := VmModel[P1];
            MemL[0:P2 + 28] := VmRPos[P1]; MemL[0:P2 + 32] := VmRSize[P1];
            MemL[0:P2 + 36] := VmGPos[P1]; MemL[0:P2 + 40] := VmGSize[P1];
            MemL[0:P2 + 44] := VmBPos[P1]; MemL[0:P2 + 48] := VmBSize[P1];
            KrnVideo := 1;
          End;
        End;
    3 : Begin
          VbeScan;
          BiosRegs($4F02, (P1 And $1FF) Or $4000, 0, 0, 0, 0, 0);
          BiosInt($10);
          If (MemL[0:BiosParm] And $FFFF) <> $004F Then KrnVideo := 1;
        End;
    4 : Begin
          BiosRegs(P1 And $FF, 0, 0, 0, 0, 0, 0);
          BiosInt($10);
        End;
    5 : If P2 <> 0 Then
        Begin
          VbeScan;
          MemL[0:P2] := VbeVer; MemL[0:P2 + 4] := VbeMemKb;
          PutPStr(P2 + 8, VbeOem, 80);
          KrnVideo := VbeVer;
        End;
  End;
End;

{ KrnSesCtl(op, p1, p2) : sessions (SESMGR.DLL, PMWIN.DLL, VIOCALLS.DLL)
    0 session au premier plan     1 session de l'appelant
    2 compteur des bascules       3 mettre la session p1 au premier plan
    4 creer une session (p1 titre ASCIIZ, p2 mode 0 texte, 1 PM)
    5 l'appelant rejoint la session de Presentation Manager (creee au
      besoin et mise au premier plan) ; rend son numero
    6 crochet de bascule (VIOCALLS : remettre le mode texte)
    7 description de la session p1 dans p2 : utilisee, premier plan,
      mode, processus, titre (48 octets) ; rend 1 si elle existe
    8 mode de la session de l'appelant (p1)
    9 l'ecran est-il a l'appelant (session au premier plan) ?
   10 session de PM (-1 : aucune)  11 titre de la session p1 (p2)
   12 le prochain processus cree va dans la session p1
   13 session du processus de PID p1
   15 adresse de l'etat des sessions (SesFlags)
   16 pause a la fin de la session p1 (p2 = 1) : une touche avant le
      retour a la session d'origine
   17 supprimer la session p1 (sans processus, pas au premier plan)
   18 ecran de la session p1 dans p2 : tampon video, ligne et colonne du
      curseur, lignes, colonnes, processus (PMVIOP.DLL)
   19 touche p2 (caractere + code Shl 8, etat) pour la session p1
   20 terminer les processus de la session p1 (fenetre OS/2 fermee) }
Function KrnSesCtl(Op, P1, P2 : LongInt) : LongInt;
Var S, Old : LongInt;
Begin
  KrnSesCtl := 0;
  Case Op Of
    0 : KrnSesCtl := FgSess;
    1 : KrnSesCtl := CurSess;
    2 : KrnSesCtl := Epoch;
    3 : If (P1 >= 0) And (P1 < MaxSess) And SUsed[P1] Then DoSwitch(P1) Else KrnSesCtl := -1;
    4 : Begin
          If P1 <> 0 Then S := NewSess(PStr(P1), P2) Else S := NewSess('Session', P2);
          If S >= 0 Then SNew[S] := True;
          KrnSesCtl := S;
        End;
    5 : If CurProc < 0 Then KrnSesCtl := -1
        Else
        Begin
          If PmSess < 0 Then
          Begin
            PmSess := NewSess('Presentation Manager', 1);
            SyncFlags;
          End;
          If PmSess >= 0 Then
          Begin
            Old := Procs[CurProc].Sess;
            If Old <> PmSess Then
            Begin
              If SUsed[PmSess] Then SRet[PmSess] := Old;
              Procs[CurProc].Sess := PmSess;
              asm
                cli
              end;
              SessSwap(PmSess);
              asm
                sti
              end;
            End;
            DoSwitch(PmSess);
          End;
          KrnSesCtl := PmSess;
        End;
    6 : SwHook := P1;
    7 : If (P1 >= 0) And (P1 < MaxSess) And SUsed[P1] And (P2 <> 0) Then
        Begin
          MemL[0:P2] := 1;
          If FgSess = P1 Then MemL[0:P2 + 4] := 1 Else MemL[0:P2 + 4] := 0;
          MemL[0:P2 + 8] := SMode[P1];
          MemL[0:P2 + 12] := SessProcs(P1);
          PutPStr(P2 + 16, STitle[P1], 48);
          KrnSesCtl := 1;
        End;
    8 : SMode[CurSess] := P1;
    9 : If (CurSess = FgSess) Or (Switching <> 0) Then KrnSesCtl := 1;
   10 : KrnSesCtl := PmSess;
   11 : If (P1 >= 0) And (P1 < MaxSess) And SUsed[P1] And (P2 <> 0) Then STitle[P1] := PStr(P2);
   12 : If (P1 >= 0) And (P1 < MaxSess) And SUsed[P1] Then NextSess := P1 Else NextSess := -1;
   13 : Begin
          S := ProcBySerial(P1);
          If S >= 0 Then KrnSesCtl := Procs[S].Sess Else KrnSesCtl := -1;
        End;
   15 : KrnSesCtl := LongInt(@SesFlags);
   16 : If (P1 >= 0) And (P1 < MaxSess) And SUsed[P1] Then SPause[P1] := P2 <> 0;
   17 : If (P1 > 0) And (P1 < MaxSess) And SUsed[P1] And (SessProcs(P1) = 0) And (P1 <> FgSess) Then
        Begin
          If NextSess = P1 Then NextSess := -1;
          FreeSess(P1);
        End;
   18 : If (P1 >= 0) And (P1 < MaxSess) And SUsed[P1] And (P2 <> 0) Then
        Begin
          { ecran d'une session (PMVIOP.DLL : fenetre OS/2) : tampon video
            (B8000h si elle est au premier plan), curseur, lignes, colonnes }
          If P1 = FgSess Then MemL[0:P2] := $B8000 Else MemL[0:P2] := SLvb[P1];
          If P1 = CurSess Then
          Begin
            MemL[0:P2 + 4] := CurRow; MemL[0:P2 + 8] := CurCol;
          End
          Else
          Begin
            MemL[0:P2 + 4] := SCurRow[P1]; MemL[0:P2 + 8] := SCurCol[P1];
          End;
          MemL[0:P2 + 12] := ScrRows; MemL[0:P2 + 16] := ScrCols;
          MemL[0:P2 + 20] := SessProcs(P1);
          KrnSesCtl := 1;
        End;
   19 : If (P1 >= 0) And (P1 < MaxSess) And SUsed[P1] And (P2 <> 0) Then
        Begin
          { touche (p2 : caractere + code Shl 8, etat des touches) dans la
            file du clavier de la session p1 (fenetre OS/2) }
          asm
            cli
          end;
          If P1 = CurSess Then
          Begin
            S := (KbdHead + 1) And 63;
            If S <> KbdTail Then
            Begin
              KbdBuf[KbdHead] := MemL[0:P2]; KbdXt[KbdHead] := MemL[0:P2 + 4]; KbdTm[KbdHead] := Ticks * 10;
              KbdHead := S;
              KrnSesCtl := 1;
            End;
          End
          Else
          Begin
            S := (SKbdHead[P1] + 1) And 63;
            If S <> SKbdTail[P1] Then
            Begin
              SKbdBuf[P1 * 64 + SKbdHead[P1]] := MemL[0:P2]; SKbdXt[P1 * 64 + SKbdHead[P1]] := MemL[0:P2 + 4];
              SKbdTm[P1 * 64 + SKbdHead[P1]] := Ticks * 10;
              SKbdHead[P1] := S;
              KrnSesCtl := 1;
            End;
          End;
          asm
            sti
          end;
        End;
   20 : If (P1 > 0) And (P1 < MaxSess) And SUsed[P1] And (P1 <> CurSess) Then
        Begin
          { fermeture d'une fenetre OS/2 : fin des processus de la session }
          Old := 0;
          For S := 0 To MaxProcs - 1 Do
            If Procs[S].Used And Procs[S].Running And (Procs[S].Sess = P1) Then
            Begin
              KillOther(S, 1);
              Inc(Old);
            End;
          KrnSesCtl := Old;
        End;
  End;
End;


{ --- Couche de base : modules, volume, memoire, processus --- }

Function ModuleHandleByName(Name : String) : LongInt;
Var M : LongInt;
Begin
  M := FindModule(Name);
  If M >= 0 Then ModuleHandleByName := Mods^[M].Base
  Else If UpStr(Name) = 'OS2KRNL' Then ModuleHandleByName := $00100000
  Else ModuleHandleByName := 0;
End;

Function LoadLibraryA(PName : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := LoadModule(PStr(PName));
  If M >= 0 Then LoadLibraryA := Mods^[M].Base Else LoadLibraryA := 0;
End;

Function ModuleOfHandle(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  ModuleOfHandle := -1;
  For I := 0 To ModCap - 1 Do
    If Mods^[I].Used And (Mods^[I].Base = H) Then ModuleOfHandle := I;
End;

{ GetProcAddress(module, nom ou ordinal < 65536) }
Function GetProcAddress(H, PName : LongInt) : LongInt;
Var M, A : LongInt;
Begin
  GetProcAddress := 0;
  If (H = 0) Or (H = $00100000) Then
  Begin
    If (PName And $FFFF0000) <> 0 Then GetProcAddress := KernelExport(PStr(PName));
    Exit;
  End;
  M := ModuleOfHandle(H);
  If M < 0 Then
  Begin
    LastError := ErrInvalidHandle;
    Exit;
  End;
  If (PName And $FFFF0000) = 0 Then A := ModuleExport(M, '', PName)
  Else A := ModuleExport(M, PStr(PName), 0);
  If A = 0 Then LastError := 127;
  GetProcAddress := A;
End;

Function FreeLibrary(H : LongInt) : LongInt;
Begin
  { les DLL restent residentes (memoire partagee) }
  If ModuleOfHandle(H) >= 0 Then FreeLibrary := 1 Else FreeLibrary := 0;
End;

Function GetModuleFileNameA(H, Buf, Size : LongInt) : LongInt;
Var S : String; M : LongInt;
Begin
  S := '';
  If (H = 0) Or (H = ProcWinBase) Then
  Begin
    If CurProc >= 0 Then S := Procs[CurProc].Path Else S := 'C:\OS2KRNL';
  End
  Else If H = $00100000 Then S := 'C:\OS2KRNL'
  Else
  Begin
    M := ModuleOfHandle(H);
    If M >= 0 Then S := Mods^[M].Path;
  End;
  If S = '' Then
  Begin
    LastError := ErrInvalidHandle;
    GetModuleFileNameA := 0;
    Exit;
  End;
  PutPStr(Buf, S, Size);
  If Length(S) >= Size Then GetModuleFileNameA := Size Else GetModuleFileNameA := Length(S);
End;

Function KrnModuleFromAddr(A : LongInt) : LongInt;
Var I : LongInt;
Begin
  KrnModuleFromAddr := 0;
  If (A >= ProcWinBase) And (A < ProcWinBase + ProcWinSize) And (CurProc >= 0) Then
    KrnModuleFromAddr := ProcWinBase
  Else If (A >= $00100000) And (A < HeapStart) Then
    KrnModuleFromAddr := $00100000
  Else
    For I := 0 To ModCap - 1 Do
      If Mods^[I].Used And (A >= Mods^[I].Base) And (A < Mods^[I].Base + Mods^[I].Size) Then
        KrnModuleFromAddr := Mods^[I].Base;
End;

{ Etiquette du volume (descripteur primaire ISO 9660), numero de serie, CDFS }
Function GetVolumeInformationA(PRoot, PVol, VolSize, PSerial, PMaxComp, PFlags, PFs, FsSize : LongInt) : LongInt;
Var A, I, Sum, D : LongInt; S : String;
Begin
  GetVolumeInformationA := 0;
  If PRoot <> 0 Then S := PStr(PRoot) Else S := CurDir;
  If FlpPath(UpStr(S)) Then
  Begin
    { disquette A: : etiquette et numero de serie du BPB, FAT }
    If Not FlpReady Then
    Begin
      LastError := ErrNotReady;
      Exit;
    End;
    If PVol <> 0 Then PutPStr(PVol, Trim(FlpLabel), VolSize);
    If PSerial <> 0 Then MemL[0:PSerial] := FlpSerial;
    If PMaxComp <> 0 Then MemL[0:PMaxComp] := 12;
    If PFlags <> 0 Then MemL[0:PFlags] := 0;
    If PFs <> 0 Then PutPStr(PFs, 'FAT', FsSize);
    GetVolumeInformationA := 1;
    Exit;
  End;
  D := IfsDrive(S);
  If D >= 0 Then
  Begin
    { volume IFS : nom et numero de serie du VPB, nom du systeme de fichiers }
    A := LongInt(@IfsVols[D].Vpfsi);
    If PVol <> 0 Then PutPStr(PVol, PStr(A + 24), VolSize);
    If PSerial <> 0 Then MemL[0:PSerial] := MemL[0:A];
    If PMaxComp <> 0 Then MemL[0:PMaxComp] := 254;
    If PFlags <> 0 Then MemL[0:PFlags] := 2;     { casse conservee }
    If PFs <> 0 Then PutPStr(PFs, Ifss[IfsVols[D].Ifs].Name, FsSize);
    GetVolumeInformationA := 1;
    Exit;
  End;
  A := CdSector(16);
  If A = 0 Then
  Begin
    LastError := ErrNotReady;
    Exit;
  End;
  S := '';
  For I := 0 To 31 Do S := S + Chr(Mem[0:A + 40 + I]);
  S := Trim(S);
  Sum := 0;
  For I := 813 To 829 Do Sum := Sum * 31 + Mem[0:A + I];
  If PVol <> 0 Then PutPStr(PVol, S, VolSize);
  If PSerial <> 0 Then MemL[0:PSerial] := Sum;
  If PMaxComp <> 0 Then MemL[0:PMaxComp] := 255;
  If PFlags <> 0 Then MemL[0:PFlags] := $00080000;   { lecture seule }
  If PFs <> 0 Then PutPStr(PFs, 'CDFS', FsSize);
  GetVolumeInformationA := 1;
End;

{ MEMORYSTATUS : longueur, charge, memoire physique totale et libre... }
Procedure GlobalMemoryStatus(P : LongInt);
Var Free : LongInt;
Begin
  Free := HeapFreeBytes + PhysFree;
  MemL[0:P] := 32;
  MemL[0:P + 4] := 100 - (Free Div 1024) * 100 Div MemTotalKb;
  MemL[0:P + 8] := MemTotalKb * 1024;
  MemL[0:P + 12] := Free;
  MemL[0:P + 16] := 0;
  MemL[0:P + 20] := 0;
  MemL[0:P + 24] := ProcWinSize;
  MemL[0:P + 28] := HeapFreeBytes;
End;

Function GetCurrentProcessId : LongInt;
Begin
  If CurProc >= 0 Then GetCurrentProcessId := Procs[CurProc].Serial
  Else GetCurrentProcessId := 1;           { le noyau }
End;

Function GetCurrentThreadId : LongInt;
Begin
  If CurTask > 0 Then GetCurrentThreadId := TkTid[CurTask] Else GetCurrentThreadId := 1;
End;

Function KrnGetParentPid : LongInt;
Begin
  KrnGetParentPid := 0;
  If CurProc >= 0 Then
  Begin
    If Procs[CurProc].Parent >= 0 Then KrnGetParentPid := Procs[Procs[CurProc].Parent].Serial
    Else KrnGetParentPid := 1;
  End;
End;

{ ==================================================================== }
{ Partie 14 - Demarrage du systeme                                     }
{ ==================================================================== }

{ CONFIG.SYS : PROTSHELL=, LIBPATH=, IFS=, COUNTRY=, SET NOM=VALEUR ; les autres
  lignes (DEVICE=, BUFFERS=...) sont acceptees sans effet }
Procedure ReadConfigSys;
Var Buf, Size, I, P : LongInt; Line, U : String; C : Char;

  Procedure DoLine;
  Begin
    Line := Trim(Line);
    U := UpStr(Line);
    If (U = '') Or (Copy(U, 1, 3) = 'REM') Then Exit;
    If Copy(U, 1, 10) = 'PROTSHELL=' Then
    Begin
      ShellPath := Trim(Copy(Line, 11, 255));
      P := Pos(' ', ShellPath);
      If P > 0 Then ShellPath := Copy(ShellPath, 1, P - 1);
    End
    Else If Copy(U, 1, 8) = 'LIBPATH=' Then
      LibPath := Trim(Copy(Line, 9, 255))
    Else If Copy(U, 1, 4) = 'IFS=' Then
    Begin
      If NIfsLines < MaxIfs Then
      Begin
        IfsLines[NIfsLines] := Trim(Copy(Line, 5, 255));
        Inc(NIfsLines);
      End;
    End
    Else If Copy(U, 1, 8) = 'COUNTRY=' Then
    Begin
      { COUNTRY=033,C:\COUNTRY.SYS : variable COUNTRY (code du pays, lu
        par DOSCALLS.DLL et NLS.DLL) }
      Line := Trim(Copy(Line, 9, 255));
      P := Pos(',', Line);
      If P > 0 Then Line := Copy(Line, 1, P - 1);
      While (Length(Line) > 1) And (Line[1] = '0') Do Delete(Line, 1, 1);
      If Line <> '' Then EnvSet('COUNTRY', Line);
    End
    Else If Copy(U, 1, 4) = 'SET ' Then
    Begin
      Line := Trim(Copy(Line, 5, 255));
      P := Pos('=', Line);
      If P > 1 Then EnvSet(Trim(Copy(Line, 1, P - 1)), Trim(Copy(Line, P + 1, 255)));
    End;
  End;

Begin
  Buf := ReadWholeFile('C:\CONFIG.SYS', Size);
  If Buf = 0 Then Exit;
  Line := '';
  For I := 0 To Size - 1 Do
  Begin
    C := Chr(Mem[0:Buf + I]);
    If (C = #13) Or (C = #10) Then
    Begin
      DoLine;
      Line := '';
    End
    Else If (C <> #26) And (Length(Line) < 250) Then Line := Line + C;
  End;
  DoLine;
  KFree(Buf);
End;

{ /RAMDISK:n : disque virtuel de n Ko (propre a OS/2-0) }
Procedure ParseRamDisk(Parm : String);
Var P, A : LongInt;
Begin
  P := Pos('/RAMDISK:', UpStr(Parm));
  If P > 0 Then
  Begin
    A := 0;
    P := P + 9;
    While (P <= Length(Parm)) And (Parm[P] >= '0') And (Parm[P] <= '9') Do
    Begin
      A := A * 10 + Ord(Parm[P]) - 48;
      Inc(P);
    End;
    RamDiskKb := A;
  End;
End;

{ Charger un pilote IFS (ligne IFS= : chemin et parametres) }
Procedure LoadIfs(Line : String);
Var P, M, I, A, R : LongInt; Path, Parm : String;
Begin
  P := Pos(' ', Line);
  If P > 0 Then
  Begin
    Path := Copy(Line, 1, P - 1);
    Parm := Trim(Copy(Line, P + 1, 255));
  End
  Else
  Begin
    Path := Line; Parm := '';
  End;
  If NIfs >= MaxIfs Then Exit;
  M := LoadModule(Path);
  If M < 0 Then
  Begin
    KLog('SYS1719: Le systeme de fichiers ' + Path + ' n''a pas pu etre charge (erreur ' +
         IntStr(LastError) + ').');
    Exit;
  End;
  { pilote deja charge (celui de C: au demarrage d'un disque dur) : seul
    /RAMDISK:n est pris en compte }
  For I := 0 To NIfs - 1 Do
    If Ifss[I].Module = M Then
    Begin
      ParseRamDisk(Parm);
      Exit;
    End;
  I := NIfs;
  Ifss[I].Used := True;
  Ifss[I].Module := M;
  Ifss[I].FInit := ModuleExport(M, 'FS_INIT', 0);
  Ifss[I].FMount := ModuleExport(M, 'FS_MOUNT', 0);
  Ifss[I].FOpen := ModuleExport(M, 'FS_OPENCREATE', 0);
  Ifss[I].FClose := ModuleExport(M, 'FS_CLOSE', 0);
  Ifss[I].FRead := ModuleExport(M, 'FS_READ', 0);
  Ifss[I].FWrite := ModuleExport(M, 'FS_WRITE', 0);
  Ifss[I].FSeek := ModuleExport(M, 'FS_CHGFILEPTR', 0);
  Ifss[I].FNewSize := ModuleExport(M, 'FS_NEWSIZE', 0);
  Ifss[I].FCommit := ModuleExport(M, 'FS_COMMIT', 0);
  Ifss[I].FFileInfo := ModuleExport(M, 'FS_FILEINFO', 0);
  Ifss[I].FPathInfo := ModuleExport(M, 'FS_PATHINFO', 0);
  Ifss[I].FFileAttr := ModuleExport(M, 'FS_FILEATTRIBUTE', 0);
  Ifss[I].FDelete := ModuleExport(M, 'FS_DELETE', 0);
  Ifss[I].FMkDir := ModuleExport(M, 'FS_MKDIR', 0);
  Ifss[I].FRmDir := ModuleExport(M, 'FS_RMDIR', 0);
  Ifss[I].FMove := ModuleExport(M, 'FS_MOVE', 0);
  Ifss[I].FChDir := ModuleExport(M, 'FS_CHDIR', 0);
  Ifss[I].FFindFirst := ModuleExport(M, 'FS_FINDFIRST', 0);
  Ifss[I].FFindNext := ModuleExport(M, 'FS_FINDNEXT', 0);
  Ifss[I].FFindClose := ModuleExport(M, 'FS_FINDCLOSE', 0);
  Ifss[I].FFsInfo := ModuleExport(M, 'FS_FSINFO', 0);
  Ifss[I].FFlush := ModuleExport(M, 'FS_FLUSHBUF', 0);
  Ifss[I].FFsCtl := ModuleExport(M, 'FS_FSCTL', 0);
  Ifss[I].FExit := ModuleExport(M, 'FS_EXIT', 0);
  Ifss[I].FShutdown := ModuleExport(M, 'FS_SHUTDOWN', 0);
  A := ModuleExport(M, 'FS_NAME', 0);
  If A <> 0 Then Ifss[I].Name := PStr(A) Else Ifss[I].Name := Mods^[M].Name;
  If (Ifss[I].FMount = 0) Or (Ifss[I].FOpen = 0) Then
  Begin
    KLog('SYS1719: ' + Path + ' n''est pas un pilote IFS.');
    Exit;
  End;
  PutPStr(LongInt(@IfsName), Parm, 260);
  IfsArgs4(LongInt(@IfsName), 0, 0, 0);
  R := IfsCall(Ifss[I].FInit, 3);
  If R <> 0 Then
  Begin
    KLog('SYS1719: ' + Path + ' : FS_INIT a echoue (erreur ' + IntStr(R) + ').');
    Exit;
  End;
  Inc(NIfs);
  KLog(Mods^[M].Name + ' (' + Ifss[I].Name + ') charge en ' + HexStr(Mods^[M].Base, 8) + 'h.');
  ParseRamDisk(Parm);
End;

{ Presenter le peripherique bloc B aux pilotes IFS et, s'il est reconnu,
  lui donner la lettre D (2 = C:, 3 = D:...). Fmt : formater le volume
  (FS_MOUNT 3 puis FS_FSCTL 8000h, nom Lbl) ; un disque virtuel non
  reconnu est toujours formate par le premier pilote }
Function MountBlk(B, D : LongInt; Fmt : Boolean; Lbl : String) : Boolean;
Var I, R, V, A : LongInt; Ok : Boolean; S1 : String;
Begin
  MountBlk := False;
  If (D < 2) Or (D > 25) Then Exit;
  IfsVols[D].Blk := B;
  IfsVols[D].Mounted := False;
  V := LongInt(@IfsVols[D].Vpfsi);
  FillMem(V, 44, 0);
  FillMem(LongInt(@IfsVols[D].Vpfsd), 64, 0);
  MemL[0:V + 4] := B;
  MemL[0:V + 8] := 512;
  MemL[0:V + 12] := Blks[B].Count;
  MemL[0:V + 16] := 63;
  MemL[0:V + 20] := 16;
  MemL[0:V + 36] := D;
  MemL[0:V + 40] := B;
  Ok := False;
  If (Not Fmt) And (BlkIO(B, 0, 0, 1, LongInt(@HdBuf)) = 0) Then
    For I := 0 To NIfs - 1 Do
      If Not Ok Then
      Begin
        IfsArgs4(0, V, LongInt(@IfsVols[D].Vpfsd), D);
        IfsArg[4] := LongInt(@HdBuf);
        If IfsCall(Ifss[I].FMount, 5) = 0 Then
        Begin
          Ok := True;
          IfsVols[D].Ifs := I;
        End;
      End;
  If (Not Ok) And (Fmt Or (Blks[B].Kind = BlkRam)) And (NIfs > 0) And (Ifss[0].FFsCtl <> 0) Then
  Begin
    IfsArgs4(3, V, LongInt(@IfsVols[D].Vpfsd), D);
    IfsArg[4] := LongInt(@HdBuf);
    IfsCall(Ifss[0].FMount, 5);
    If Lbl = '' Then
    Begin
      If Blks[B].Kind = BlkRam Then Lbl := 'RAMDISK' Else Lbl := 'OS2';
    End;
    PutPStr(LongInt(@IfsName2), Lbl, 12);
    A := LongInt(@IfsInfo);
    MemL[0:A] := D;
    MemL[0:A + 4] := LongInt(@IfsName2);
    IfsArgs4(0, 3, $8000, A);
    IfsArgs8(8, LongInt(@IfsCnt), 0, 0);
    IfsArg[8] := LongInt(@IfsCnt);
    R := IfsCall(Ifss[0].FFsCtl, 9);
    If R = 0 Then
    Begin
      Ok := True;
      IfsVols[D].Ifs := 0;
    End
    Else
    Begin
      KLog('SYS1719: formatage de ' + Chr(65 + D) + ': impossible (erreur ' + IntStr(R) + ').');
      IfsArgs4(2, V, LongInt(@IfsVols[D].Vpfsd), D);
      IfsArg[4] := 0;
      IfsCall(Ifss[0].FMount, 5);
    End;
  End;
  If Ok And (Ifss[IfsVols[D].Ifs].FFsCtl <> 0) And Not Fmt Then
  Begin
    { volume mal ferme et lettre citee par /AUTOCHECK : verification
      et correction (FS_FSCTL 8002h puis 8001h) }
    A := LongInt(@IfsInfo);
    MemL[0:A] := D;
    FillMem(A + 64, 40, 0);
    IfsArgs4(0, 3, $8002, A);
    IfsArgs8(4, 0, A + 64, 40);
    IfsArg[8] := LongInt(@IfsCnt);
    If (IfsCall(Ifss[IfsVols[D].Ifs].FFsCtl, 9) = 0) And (MemL[0:A + 96] <> 0) And
       (MemL[0:A + 100] <> 0) Then
    Begin
      MemL[0:A + 4] := 1;
      IfsArgs4(0, 3, $8001, A);
      IfsArgs8(8, 0, A + 64, 36);
      IfsArg[8] := LongInt(@IfsCnt);
      If IfsCall(Ifss[IfsVols[D].Ifs].FFsCtl, 9) = 0 Then
        KLog('Verification automatique de ' + Chr(65 + D) + ': (volume mal ferme) : ' +
             IntStr(MemL[0:A + 64]) + ' erreur(s), ' + IntStr(MemL[0:A + 68]) +
             ' secteur(s) perdu(s) recupere(s).');
    End;
  End;
  If Ok Then
  Begin
    IfsVols[D].Mounted := True;
    If Blks[B].Kind = BlkRam Then S1 := 'disque virtuel' Else S1 := 'disque IDE';
    KLog('Unite ' + Chr(65 + D) + ': ' + Ifss[IfsVols[D].Ifs].Name + ' (' + S1 + ', ' +
         IntStr(Blks[B].Count Div 2) + ' Ko) : ' + PStr(V + 24));
  End
  Else
    IfsVols[D].Blk := -1;
  MountBlk := Ok;
End;

{ premiere lettre libre a partir de D: }
Function FreeLetter : LongInt;
Var D : LongInt;
Begin
  D := 3;
  While (D <= 25) And IfsVols[D].Mounted Do Inc(D);
  FreeLetter := D;
End;

{ Presenter aux pilotes IFS les peripheriques bloc qui ne l'ont pas encore
  ete et donner une lettre d'unite (D: et suivantes) aux volumes reconnus ;
  au demarrage d'un disque dur, la partition d'amorcage devient C: }
Procedure MountIfsVolumes;
Var B, D : LongInt;
Begin
  For B := 0 To NBlk - 1 Do
    If (Blks[B].Kind <> 0) And Not Blks[B].Seen Then
    Begin
      Blks[B].Seen := True;
      If HdBoot And (Not IfsVols[2].Mounted) And (Blks[B].Kind = BlkAta) And (Blks[B].Start = BootPartLba) Then D := 2
      Else D := FreeLetter;
      If D <= 25 Then MountBlk(B, D, False, '');
    End;
End;

{ Lettre de la partition qui commence au secteur Start du disque Dk (-1) }
Function PartLetter(Dk, Start : LongInt) : LongInt;
Var D : LongInt;
Begin
  PartLetter := -1;
  For D := 2 To 25 Do
    If IfsVols[D].Mounted Then
      If (Blks[IfsVols[D].Blk].Kind = BlkAta) And (Blks[IfsVols[D].Blk].Disk = Dk) And
         (Blks[IfsVols[D].Blk].Start = Start) Then PartLetter := D;
End;

{ Peripherique bloc de la partition (cree au besoin) }
Function PartBlk(Dk, Start, Count : LongInt) : LongInt;
Var B, K : LongInt;
Begin
  PartBlk := -1;
  For B := 0 To NBlk - 1 Do
    If (Blks[B].Kind = BlkAta) And (Blks[B].Disk = Dk) And (Blks[B].Start = Start) Then
    Begin
      Blks[B].Count := Count;
      PartBlk := B;
      Exit;
    End;
  B := NewBlk;
  If B < 0 Then
  Begin
    { reprendre une entree liberee (partition demontee) }
    For K := NBlk - 1 DownTo 0 Do
      If Blks[K].Kind = 0 Then B := K;
    If B < 0 Then Exit;
  End;
  Blks[B].Used := True;
  Blks[B].Kind := BlkAta; Blks[B].Base := Disks[Dk].Base; Blks[B].Ctrl := Disks[Dk].Ctrl;
  Blks[B].Slave := Disks[Dk].Slave; Blks[B].Start := Start; Blks[B].Count := Count;
  Blks[B].PType := 7; Blks[B].Disk := Dk; Blks[B].Seen := True; Blks[B].Mem := 0;
  PartBlk := B;
End;

{ Demonter l'unite D (vidage des tampons du pilote) }
Procedure Unmount(D : LongInt);
Var V : LongInt;
Begin
  If Not IfsVols[D].Mounted Then Exit;
  IfsArg[0] := D; IfsArg[1] := 0;
  IfsCall(Ifss[IfsVols[D].Ifs].FFlush, 2);
  V := LongInt(@IfsVols[D].Vpfsi);
  IfsArgs4(2, V, LongInt(@IfsVols[D].Vpfsd), D);
  IfsArg[4] := 0;
  IfsCall(Ifss[IfsVols[D].Ifs].FMount, 5);
  IfsVols[D].Mounted := False;
End;

{ Vider les tampons de tous les volumes }
Procedure FlushAllVolumes;
Var D : LongInt;
Begin
  For D := 2 To 25 Do
    If IfsVols[D].Mounted Then
    Begin
      IfsArg[0] := D; IfsArg[1] := 0;
      IfsCall(Ifss[IfsVols[D].Ifs].FFlush, 2);
    End;
End;

{ KrnDiskCtl(op, p1, p2) : disques durs (INSTALL.EXE, DOSCALLS.DLL)
    0 nombre de disques durs IDE
    1 description du disque p1 dans p2 : secteurs, ports, esclave (0/1),
      modele ASCIIZ (41 octets en +12) ; rend 1 s'il existe
    2 lire, 3 ecrire des secteurs du disque p1 : p2 = LBA, nombre, adresse
      (rend 0, ou le code d'erreur)
    4 lettre (2 = C:) de la partition du disque p1 qui commence au
      secteur p2 (-1 : non montee)
    5 formater (HPFS) la partition du disque p1 : p2 = debut, nombre de
      secteurs, nom de volume ASCIIZ (ou 0), lettre en retour (+12) ; la
      partition est montee (rend 0, ou le code d'erreur)
    6 demonter la partition du disque p1 qui commence au secteur p2
    7 monter la partition du disque p1 : p2 = debut, nombre, lettre en
      retour (+8) ; rend 0 si un pilote IFS la reconnait
    8 vider les tampons de tous les volumes
    9 redemarrer l'ordinateur (apres vidage)
   10 demarrage : rend 1 si le systeme a demarre d'un disque dur (p2 :
      debut de la partition d'amorcage) }
Function KrnDiskCtl(Op, P1, P2 : LongInt) : LongInt;
Var R, B, D, N, Done, K : LongInt;
Begin
  KrnDiskCtl := 0;
  Case Op Of
    0 : KrnDiskCtl := NDisk;
    1 : If (P1 >= 0) And (P1 < NDisk) And (P2 <> 0) Then
        Begin
          MemL[0:P2] := Disks[P1].Sectors; MemL[0:P2 + 4] := Disks[P1].Base;
          MemL[0:P2 + 8] := Ord(Disks[P1].Slave);
          PutPStr(P2 + 12, Disks[P1].Model, 41);
          KrnDiskCtl := 1;
        End;
    2, 3 :
        If (P1 < 0) Or (P1 >= NDisk) Or (P2 = 0) Then KrnDiskCtl := 15
        Else
        Begin
          N := MemL[0:P2 + 4];
          If (MemL[0:P2] < 0) Or (N < 0) Or (MemL[0:P2] + N > Disks[P1].Sectors) Then KrnDiskCtl := 27
          Else
          Begin
            R := 0; Done := 0;
            While (R = 0) And (Done < N) Do
            Begin
              K := N - Done;
              If K > 128 Then K := 128;
              If Not HdIOx(Disks[P1].Base, Disks[P1].Ctrl, Disks[P1].Slave, MemL[0:P2] + Done, K,
                           MemL[0:P2 + 8] + Done * 512, Op = 3) Then
              Begin
                If Op = 3 Then R := 29 Else R := 30;
              End
              Else Done := Done + K;
            End;
            AtaSelect;
            KrnDiskCtl := R;
          End;
        End;
    4 : KrnDiskCtl := PartLetter(P1, P2);
    5 : If (P1 < 0) Or (P1 >= NDisk) Or (P2 = 0) Or (NIfs = 0) Then KrnDiskCtl := 15
        Else
        Begin
          D := PartLetter(P1, MemL[0:P2]);
          If D = 2 Then KrnDiskCtl := 5
          Else
          Begin
            If D >= 0 Then Unmount(D) Else D := FreeLetter;
            B := PartBlk(P1, MemL[0:P2], MemL[0:P2 + 4]);
            If (B < 0) Or (D > 25) Then KrnDiskCtl := 8
            Else If MountBlk(B, D, True, PStr(MemL[0:P2 + 8])) Then MemL[0:P2 + 12] := D
            Else KrnDiskCtl := 31;
          End;
        End;
    6 : Begin
          D := PartLetter(P1, P2);
          If D = 2 Then KrnDiskCtl := 5
          Else If D > 2 Then
          Begin
            Unmount(D);
            B := IfsVols[D].Blk;
            If (B >= 0) And (B < NBlk) Then Blks[B].Kind := 0;
          End;
        End;
    7 : If (P1 < 0) Or (P1 >= NDisk) Or (P2 = 0) Or (NIfs = 0) Then KrnDiskCtl := 15
        Else
        Begin
          D := PartLetter(P1, MemL[0:P2]);
          If D < 0 Then
          Begin
            D := FreeLetter;
            B := PartBlk(P1, MemL[0:P2], MemL[0:P2 + 4]);
            If (B < 0) Or (D > 25) Then KrnDiskCtl := 8
            Else If Not MountBlk(B, D, False, '') Then KrnDiskCtl := 31;
          End;
          If PartLetter(P1, MemL[0:P2]) >= 0 Then MemL[0:P2 + 8] := PartLetter(P1, MemL[0:P2]);
        End;
    8 : FlushAllVolumes;
    9 : Begin
          FlushAllVolumes;
          asm
            cli
          end;
          K := 0;
          While ((Port[$64] And 2) <> 0) And (K < 100000) Do Inc(K);
          Port[$64] := $FE;
          K := 0;
          While K < 10000000 Do Inc(K);
          { remise a zero par le processeur : IDT vide puis interruption }
          asm
            push 0
            push 0
            lidt [esp]
            int 3
          end;
        End;
   10 : Begin
          If P2 <> 0 Then MemL[0:P2] := BootPartLba;
          KrnDiskCtl := Ord(HdBoot);
        End;
  End;
End;

{ SetEnvironmentVariableA(nom, valeur) : environnement du systeme (les
  programmes lances ensuite le recoivent) ; valeur 0 ou vide : supprimer }
Function SetEnvironmentVariableA(PName, PValue : LongInt) : LongInt;
Begin
  SetEnvironmentVariableA := 0;
  If PName = 0 Then Exit;
  If PValue = 0 Then EnvSet(PStr(PName), '') Else EnvSet(PStr(PName), PStr(PValue));
  SetEnvironmentVariableA := 1;
End;

{ VDM-DEBUT }
{ ==================================================================== }
{ Partie 13b - Machine virtuelle DOS (VDM, mode virtuel 8086)          }
{ ==================================================================== }
{ Comme OS/2 2.0, OS/2-0 execute les programmes MS-DOS (.COM, et .EXE
  sans en-tete PE ni NE) dans une machine virtuelle DOS : une tache du
  noyau execute leur code en mode virtuel 8086. Le moniteur, le BIOS, le
  DOS, la souris, XMS, EMS et le serveur DPMI viennent de la machine
  virtuelle de Pasdows 95 (projet gladir/Pasdows95, VMM32.PAS, partie
  17), adaptes au noyau d'OS/2-0 :

  - la machine occupe une session plein ecran (celle du programme qui la
    lance, ou une session "DOS plein ecran" du bureau) ; son premier
    megaoctet est projete par la table de pages de cette session
    (entree 0 du repertoire de pages, qui change avec la session) : 0 a
    9FFFFh, B0000h a B7FFFh et C0000h a FFFFFh sont la memoire de la
    machine, A0000h a AFFFFh et B8000h a BFFFFh l'ecran de la session
    (la carte VGA au premier plan, le tampon de la session sinon). Dans
    la tache de la machine, l'adresse lineaire 0 est donc l'adresse 0
    de la machine (VmRam = 0) ;
  - au premier plan, un programme en mode graphique utilise directement
    la carte VGA (modes et services graphiques du vrai BIOS, ports de la
    carte), comme les sessions DOS plein ecran d'OS/2 ; a l'arriere-plan
    il est suspendu, et son ecran (mode, plans, palette) est sauve puis
    rendu a son retour ;
  - le clavier (codes de balayage) et la souris PS/2 de la session au
    premier plan sont envoyes a la machine ;
  - les fichiers sont ceux du noyau (CD-ROM, disque virtuel, volumes
    HPFS) ;
  - les interruptions de la machine passent par la TSS (pile de l'anneau
    0 de sa tache) et la LDT (selecteurs des clients DPMI). }

Const
  LdtMax = 2048;
  INVALID_HANDLE = -1;
  VmMaxBlk = 256;

Var
  Ldt : Array[0..LdtMax * 2 - 1] Of LongInt;
  LdtUsed : Array[0..LdtMax - 1] Of Boolean;
  GOwner : Array[0..LdtMax - 1] Of LongInt;
  VmHeapOwn : LongInt;
  { blocs de la machine : adresse et genre (1 tas du noyau, 2 memoire
    physique) ; rendus a la fin de la machine }
  VmBlkA, VmBlkK : Array[0..VmMaxBlk - 1] Of LongInt;
  VmFontBuf : LongInt;        { police 8x16 de la carte VGA (4096 octets) }
  VmCwdBuf : Array[0..259] Of Byte;

{ ------------------------------------------------------------------ }
{ TSS et LDT                                                         }
{ ------------------------------------------------------------------ }

Procedure InitTss;
Var B, I : LongInt;
Begin
  { TSS : pile de l'anneau 0 (SS0 = 10h), pas de table d'E/S }
  FillMem(LongInt(@Tss), 128, 0);
  TssBase := LongInt(@Tss);
  Tss[2] := $10;
  Tss[25] := 104 Shl 16;
  B := TssBase;
  Gdt[10] := 103 Or ((B And $FFFF) Shl 16);
  Gdt[11] := ((B Shr 16) And $FF) Or $8900 Or (B And LongInt($FF000000));
  B := LongInt(@Ldt);
  Gdt[12] := ((LdtMax * 8 - 1) And $FFFF) Or ((B And $FFFF) Shl 16);
  Gdt[13] := ((B Shr 16) And $FF) Or $8200 Or (B And LongInt($FF000000));
  For I := 0 To LdtMax - 1 Do
  Begin
    LdtUsed[I] := False;
    Ldt[I * 2] := 0; Ldt[I * 2 + 1] := 0;
  End;
  LdtUsed[0] := True;
  asm
    mov ax,28h
    ltr ax
    mov ax,30h
    lldt ax
  end;
  For I := 0 To MaxTasks - 1 Do TkEsp0[I] := 0;
  VmOn := False; VmTask := -1; VmSess := -1; VmPid := -1;
  VmHeapOwn := 0;
  For I := 0 To VmMaxBlk - 1 Do VmBlkA[I] := 0;
End;

{ Acc : $FA code 16 bits, $F2 donnees 16 bits (anneau 3) }
Procedure DescSet(I, Base, Limit, Acc : LongInt);
Var G : LongInt;
Begin
  G := 0;
  If Limit > $FFFFF Then
  Begin
    Limit := Limit Shr 12;
    G := $800000;
  End;
  Ldt[I * 2] := (Limit And $FFFF) Or ((Base And $FFFF) Shl 16);
  Ldt[I * 2 + 1] := ((Base Shr 16) And $FF) Or (Acc Shl 8) Or
                    (Limit And $F0000) Or G Or (Base And LongInt($FF000000));
End;

Function SelBase(Sel : LongInt) : LongInt;
Var I : LongInt;
Begin
  SelBase := 0;
  If (Sel And $FFF8) = $40 Then SelBase := $400;
  If (Sel And 4) = 0 Then Exit;
  I := (Sel Shr 3) And $1FFF;
  If I >= LdtMax Then Exit;
  SelBase := ((Ldt[I * 2] Shr 16) And $FFFF) Or
             ((Ldt[I * 2 + 1] And $FF) Shl 16) Or
             (Ldt[I * 2 + 1] And LongInt($FF000000));
End;

Function SelLimit(Sel : LongInt) : LongInt;
Var I, L : LongInt;
Begin
  SelLimit := 0;
  If (Sel And 4) = 0 Then Exit;
  I := (Sel Shr 3) And $1FFF;
  If I >= LdtMax Then Exit;
  L := (Ldt[I * 2] And $FFFF) Or (Ldt[I * 2 + 1] And $F0000);
  If (Ldt[I * 2 + 1] And $800000) <> 0 Then L := (L Shl 12) Or $FFF;
  SelLimit := L;
End;

Function SelValid(Sel : LongInt) : Boolean;
Var I : LongInt;
Begin
  I := (Sel Shr 3) And $1FFF;
  SelValid := ((Sel And 4) <> 0) And (I > 0) And (I < LdtMax) And
              LdtUsed[I];
End;

{ N selecteurs consecutifs ; selecteur du premier ou 0 }
Function SelAlloc(N : LongInt) : LongInt;
Var I, K, Run : LongInt;
Begin
  SelAlloc := 0;
  Run := 0;
  For I := 1 To LdtMax - 1 Do
  Begin
    If LdtUsed[I] Then Run := 0 Else Inc(Run);
    If Run = N Then
    Begin
      For K := I - N + 1 To I Do
      Begin
        LdtUsed[K] := True;
        GOwner[K] := VmHeapOwn;
        Ldt[K * 2] := 0; Ldt[K * 2 + 1] := 0;
      End;
      SelAlloc := ((I - N + 1) Shl 3) Or 7;
      Exit;
    End;
  End;
  VmLog('DOS : LDT pleine');
End;

Procedure SelFree(Sel, N : LongInt);
Var I, K : LongInt;
Begin
  I := (Sel Shr 3) And $1FFF;
  For K := I To I + N - 1 Do
    If (K > 0) And (K < LdtMax) Then
    Begin
      LdtUsed[K] := False;
      Ldt[K * 2] := 0; Ldt[K * 2 + 1] := 0;
    End;
End;

{ ------------------------------------------------------------------ }
{ Liaisons avec le noyau d'OS/2-0                                    }
{ ------------------------------------------------------------------ }

{ journal de la machine : port serie seulement (l'ecran est celui du
  programme DOS) }
Procedure VmLog(S : String);
Var I : LongInt;
Begin
  If Not SerialOk Then Exit;
  For I := 1 To Length(S) Do SerialPut(S[I]);
  SerialPut(#13); SerialPut(#10);
End;

Function Min(A, B : LongInt) : LongInt;
Begin
  If A < B Then Min := A Else Min := B;
End;

Function Max(A, B : LongInt) : LongInt;
Begin
  If A > B Then Max := A Else Max := B;
End;

Function UpCh(C : LongInt) : LongInt;
Begin
  If (C >= 97) And (C <= 122) Then C := C - 32;
  UpCh := C;
End;

Function StrLenZ(A : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  If A <> 0 Then
    While Mem[0:A + N] <> 0 Do Inc(N);
  StrLenZ := N;
End;

Function PStrN(A, N : LongInt) : String;
Var S : String; I : LongInt;
Begin
  S := '';
  If N > 255 Then N := 255;
  For I := 0 To N - 1 Do S := S + Chr(Mem[0:A + I]);
  PStrN := S;
End;

Procedure PutB(Var A : LongInt; B : LongInt);
Begin
  Mem[0:A] := B And $FF;
  Inc(A);
End;

Procedure PutD(Var A : LongInt; D : LongInt);
Begin
  MemL[0:A] := D;
  A := A + 4;
End;

{ millisecondes ecoulees (minuterie a 100 Hz) }
Function VmMsNow : LongInt;
Begin
  VmMsNow := Ticks * 10;
End;

{ attendre Ms millisecondes (au moins un top) : les autres taches
  s'executent }
Procedure VmSleep(Ms : LongInt);
Var T : LongInt;
Begin
  T := Ticks + (Ms + 9) Div 10;
  If T <= Ticks Then T := Ticks + 1;
  While Ticks < T Do Idle;
End;

{ blocs de la machine (VmHeapOwn <> 0) : grands blocs en memoire
  physique, petits dans le tas du noyau ; rendus par VmFreeAll }
Function VmKAlloc(N : LongInt) : LongInt;
Var A, K, I : LongInt;
Begin
  If N >= 65536 Then
  Begin
    A := PAlloc(N);
    K := 2;
  End
  Else
  Begin
    A := KAlloc(N);
    K := 1;
  End;
  If (A <> 0) And ((VmHeapOwn <> 0) Or (K = 2)) Then
  Begin
    I := 0;
    While (I < VmMaxBlk) And (VmBlkA[I] <> 0) Do Inc(I);
    If I < VmMaxBlk Then
    Begin
      VmBlkA[I] := A; VmBlkK[I] := K;
    End;
  End;
  VmKAlloc := A;
End;

Procedure VmKFree(A : LongInt);
Var I : LongInt;
Begin
  If A = 0 Then Exit;
  For I := 0 To VmMaxBlk - 1 Do
    If VmBlkA[I] = A Then
    Begin
      If VmBlkK[I] = 2 Then PFree(A) Else KFree(A);
      VmBlkA[I] := 0;
      Exit;
    End;
  KFree(A);
End;

Procedure VmFreeAll;
Var I : LongInt;
Begin
  For I := 0 To VmMaxBlk - 1 Do
    If VmBlkA[I] <> 0 Then
    Begin
      If VmBlkK[I] = 2 Then PFree(VmBlkA[I]) Else KFree(VmBlkA[I]);
      VmBlkA[I] := 0;
    End;
End;

Function VmEnvFind(Name : String; Var Vs : LongInt) : Boolean;
Begin
  Vs := EnvFind(Name);
  VmEnvFind := Vs <> 0;
End;

{ langue (SET LANGUAGE=) : francais, anglais, allemand, italien, espagnol }
Function VmLang : LongInt;
Var A : LongInt; S : String;
Begin
  VmLang := 0;
  A := EnvFind('LANGUAGE');
  If A = 0 Then Exit;
  S := UpStr(Copy(PStr(A), 1, 2));
  If (S = 'EN') Or (S = 'US') Or (S = 'UK') Then VmLang := 1
  Else If (S = 'GR') Or (S = 'DE') Then VmLang := 2
  Else If S = 'IT' Then VmLang := 3
  Else If (S = 'SP') Or (S = 'ES') Then VmLang := 4;
End;

Function VmL(A, B, C, D, E : String) : String;
Begin
  Case VmLang Of
    1 : VmL := B;
    2 : VmL := C;
    3 : VmL := D;
    4 : VmL := E;
  Else
    VmL := A;
  End;
End;

{ repertoire courant du processus de la machine (C: -> C:\) }
Procedure VmSetCwd(S : String);
Begin
  If Length(S) = 2 Then S := S + '\';
  If CurProc >= 0 Then Procs[CurProc].CurDir := S Else KernelDir := S;
End;

{ ouvrir un fichier du noyau (Disp de CreateFile) ; INVALID_HANDLE }
Function KOpenFile(Name : String; Wr : Boolean; Disp : LongInt) : LongInt;
Var Acc, H : LongInt;
Begin
  PutPStr(LongInt(@VmCwdBuf), Name, 256);
  Acc := LongInt($80000000);
  If Wr Then Acc := Acc Or $40000000;
  H := CreateFileA(LongInt(@VmCwdBuf), Acc, 3, 0, Disp, $80, 0);
  If (H = 0) Or (H = -1) Then H := INVALID_HANDLE;
  KOpenFile := H;
End;

Function KReadFile(H, Buf, N : LongInt; Var Got : LongInt) : Boolean;
Var G : LongInt;
Begin
  G := 0;
  KReadFile := ReadFile(H, Buf, N, LongInt(@G), 0) <> 0;
  Got := G;
End;

Function KWriteFile(H, Buf, N : LongInt) : LongInt;
Var G : LongInt;
Begin
  G := 0;
  If WriteFile(H, Buf, N, LongInt(@G), 0) = 0 Then KWriteFile := -1
  Else KWriteFile := G;
End;

{ unites presentes : C:, volumes IFS (et A: avec une disquette) }
Function GetLogicalDrives : LongInt;
Var R, D : LongInt;
Begin
  R := 4;
  If FdOk Then R := R Or 1;
  For D := 0 To 25 Do
    If IfsVols[D].Mounted Then R := R Or (1 Shl D);
  GetLogicalDrives := R;
End;

Procedure FatFlush;
Begin
  FlushAllVolumes;
End;

Function VmIsFg : Boolean;
Begin
  VmIsFg := VmOn And (FgSess = VmSess);
End;

{ attendre le premier plan (programme en mode graphique) }
Procedure VmFgWait;
Begin
  While VmOn And (FgSess <> VmSess) Do Idle;
End;


{ memoire physique libre (XMS, EMS, DPMI) }
Function VmMemFree : LongInt;
Begin
  VmMemFree := PhysFree;
End;

{ Moniteur V86 (repris de Pasdows 95) : les instructions sensibles
  (INT, IRET, PUSHF, POPF, CLI, STI, HLT, IN, OUT) provoquent une faute
  de protection generale (0Dh) que le moniteur emule ; l'indicateur IF
  de la machine est virtuel. Le BIOS et le DOS sont ecrits ici en
  Pascal : chaque vecteur de la table des interruptions de la machine
  pointe sur un octet HLT en F000:0100h + n. Un INT n vers ce vecteur est
  servi directement ; un programme qui a detourne le vecteur et rappelle
  l'ancien gestionnaire (PUSHF + CALL FAR) arrive sur le HLT, qui sert
  l'interruption et revient (IRET). L'horloge (INT 08h et 1Ch, 18,2 Hz)
  et le clavier (INT 09h, port 60h) sont des interruptions virtuelles,
  delivrees quand IF le permet.

  Le DOS gere les blocs de memoire (MCB), les PSP, le chargement des
  .COM et .EXE (relocations ; EXEC 4B00h, 4B01h et 4B03h ; fin avec
  retour au programme parent par la pile sauvee dans son PSP, comme
  MS-DOS), les fichiers par une table de fichiers systeme (fichiers du
  noyau), la recherche des fichiers (noms courts 8.3) et un repertoire
  courant par lecteur. }

Const
  { cadre des registres du moniteur (apres PUSHAD) }
  fEdi = 0; fEsi = 4; fEbp = 8; fEbx = 16; fEdx = 20; fEcx = 24;
  fEax = 28; fEip = 32; fCs = 36; fFl = 40; fEsp = 44; fSs = 48;
  fEs = 52; fDs = 56; fFs = 60; fGs = 64;
  VmBios = $F000;
  VmStubO = $0100;          { F000:0100h + n : HLT de l'interruption n }
  VmExitO = $0200;          { fin du programme principal }
  VmCpmO = $0201;           { CALL 5 (CP/M) }
  VmMRetO = $0202;          { retour du gestionnaire de la souris }
  VmCfgO = $0210;           { configuration (INT 15h C0h) }
  VmFuncO = $0220;          { fonctions video (INT 10h 1Bh) }
  VmEgaO = $0240;           { palette EGA par defaut }
  VmFontO = $1000;          { police 8x16 }
  VmFont8O = $FA6E;         { police 8x8 (0-127, adresse de la ROM) }
  VmFont8H = $3000;         { police 8x8 (128-255, INT 1Fh) }
  VmFont14O = $3400;        { police 8x14 }
  VmDosSeg = $0060;         { donnees du DOS en 0600h }
  VmLolO = $0010;           { liste des listes (INT 21h 52h) }
  VmDbcsO = $0080;          { table DBCS vide }
  VmUpO = $0090;            { majuscules (128 caracteres) }
  VmFirstMcb = $0080;
  VmRootPsp = $0081;        { PSP racine (interpreteur fictif) }
  VmRootEnv = $0092;
  VmMaxSft = 64;
  VmKqMax = 64;
  VmMaxFind = 16;
  ShSig = $48534450;        { 'PDSH' : interpreteur integre }

Var
  VmRam : LongInt;              { adresse de la machine dans sa tache (0) }
  VmPd, VmPt : LongInt;         { repertoire et table de pages (session) }
  VmF : LongInt;                { cadre des registres en cours }
  VmVec, VmErrCode : LongInt;   { vecteur et code d'erreur de la faute }
  VmKEsp, VmE0P : LongInt;      { pile du noyau a l'entree, ESP0 }
  VmEnterS, VmLeaveS : LongInt; { souches d'entree et de sortie }
  VmCtx : Array[0..17] Of LongInt;  { registres du contexte courant }
  VmPM : Boolean;               { contexte en mode protege (DPMI) }
  VmPad : LongInt;              { bourrage du cadre a la sortie (0, 16) }
  VmStubsOk : Boolean;
  VmImg : Array[0..16] Of LongInt; { registres initiaux (cadre) }
  VmIF : Boolean;               { IF virtuel }
  VmFlHi : LongInt;             { bits 12-14 (IOPL, NT) virtuels }
  VmNoIret : Boolean;           { le service a change le flot }
  VmExitCode, VmRetCode : LongInt;
  VmProg, VmArgs : String;
  VmCurPsp, VmDta, VmTopPsp : LongInt;
  VmDtaPM : Boolean;            { DTA fixee en mode protege (VmDtaLin) }
  VmDtaLin : LongInt;
  Vm32 : Boolean;               { client DPMI 32 bits }
  VmPspSel : LongInt;           { selecteur du PSP du client DPMI }
  VmDrive : LongInt;
  VmDir : Array[0..25] Of String[66];
  VmStrat, VmBreak, VmVerify : LongInt;
  VmLastErr : LongInt;
  VmPendScan : LongInt;         { 2e octet d'une touche etendue (AH=07h) }
  { horloge et controleur d'interruptions virtuels }
  VmLastMs, VmPitAcc, VmPitDiv, VmTickDue : LongInt;
  VmPicMask, VmIsr : LongInt;
  VmPitMode, VmPitLatch, VmPitLo : LongInt;
  VmIdleN : LongInt;
  { clavier : file remplie par la tache 0 (bits 0-15 code BIOS, 16-23
    code de balayage, 24 prefixe E0h, 25 code BIOS present) }
  VmKq : Array[0..VmKqMax - 1] Of LongInt;
  VmKqHead, VmKqTail : LongInt;
  VmCurKey, VmPort60, VmPort61 : LongInt;
  { ecran }
  VmBlink : Boolean;
  VmCrtIdx, VmDacIdx, VmDacRd, VmDacK, VmAttrFF, VmRetr : LongInt;
  VmDac : Array[0..767] Of Byte;
  VmGfx : Boolean;
  { fichiers : table des fichiers systeme }
  SftH, SftRef, SftDev, SftMode : Array[0..VmMaxSft - 1] Of LongInt;
  VmFindH, VmFindSeq : Array[0..VmMaxFind - 1] Of LongInt;
  VmFindNext, VmFindCnt : LongInt;
  VmTmp : LongInt;              { tampon du noyau (1 Ko) }
  VmLine : String;              { reste d'une ligne lue sur CON }
  VmLineOk : Boolean;
  { souris (INT 33h) }
  VmMouOn : Boolean;
  VmMouX, VmMouY, VmMouBtn, VmMouShow : LongInt;
  VmMouMask, VmMouSeg, VmMouOfs, VmMouEv, VmMouBusy : LongInt;
  VmMouSave : Array[0..16] Of LongInt;
  VmMouMinX, VmMouMaxX, VmMouMinY, VmMouMaxY : LongInt;
  VmMouPress, VmMouRel : Array[0..2] Of LongInt;
  VmMouPX, VmMouPY, VmMouRX, VmMouRY : Array[0..2] Of LongInt;
  VmMouMkX, VmMouMkY : LongInt;
  VmMouCell : LongInt;          { cellule du pointeur affiche (-1) }
  VmTrace : Boolean;            { journal des appels (variable DOSTRACE) }

{ ------------------------------------------------------------------ }
{ Registres et memoire de la machine                                 }
{ ------------------------------------------------------------------ }

Function VR(Ofs : LongInt) : LongInt;
Begin
  VR := MemL[0:VmF + Ofs] And $FFFF;
End;

Procedure VS(Ofs, V : LongInt);
Begin
  MemL[0:VmF + Ofs] := (MemL[0:VmF + Ofs] And LongInt($FFFF0000)) Or
                       (V And $FFFF);
End;

Function VRL(Ofs : LongInt) : LongInt;
Begin
  VRL := MemL[0:VmF + Ofs] And $FF;
End;

Function VRH(Ofs : LongInt) : LongInt;
Begin
  VRH := (MemL[0:VmF + Ofs] Shr 8) And $FF;
End;

Procedure VSL(Ofs, V : LongInt);
Begin
  Mem[0:VmF + Ofs] := V And $FF;
End;

Procedure VSH(Ofs, V : LongInt);
Begin
  Mem[0:VmF + Ofs + 1] := V And $FF;
End;

Procedure VSeg(Ofs, V : LongInt);
Begin
  MemL[0:VmF + Ofs] := V And $FFFF;
End;

{ adresse lineaire (noyau) de Seg:Ofs dans la machine }
Function VmLin(Seg, Ofs : LongInt) : LongInt;
Begin
  VmLin := VmRam + ((((Seg And $FFFF) Shl 4) + (Ofs And $FFFF)) And
                    $FFFFF);
End;

Function VmPtr(SegR, OfsR : LongInt) : LongInt;
Var L, O : LongInt;
Begin
  If VmPM Then
  Begin
    { client DPMI : selecteur:decalage (extensions MS-DOS) }
    If Vm32 Then O := MemL[0:VmF + OfsR] Else O := VR(OfsR);
    L := SelBase(VR(SegR)) + O;
    If (L >= 0) And (L < $100000) Then L := VmRam + L;
    VmPtr := L;
  End
  Else VmPtr := VmLin(VR(SegR), VR(OfsR));
End;

Function VmGetW(Seg, Ofs : LongInt) : LongInt;
Begin
  VmGetW := Mem[0:VmLin(Seg, Ofs)] Or (Mem[0:VmLin(Seg, Ofs + 1)] Shl 8);
End;

Procedure VmPutW(Seg, Ofs, V : LongInt);
Begin
  Mem[0:VmLin(Seg, Ofs)] := V And $FF;
  Mem[0:VmLin(Seg, Ofs + 1)] := (V Shr 8) And $FF;
End;

Function VmBda(Ofs : LongInt) : LongInt;
Begin
  VmBda := VmRam + $400 + Ofs;
End;

Procedure VmSetCF(B : Boolean);
Begin
  If B Then MemL[0:VmF + fFl] := MemL[0:VmF + fFl] Or 1
  Else MemL[0:VmF + fFl] := MemL[0:VmF + fFl] And Not 1;
End;

Procedure VmSetZF(B : Boolean);
Begin
  If B Then MemL[0:VmF + fFl] := MemL[0:VmF + fFl] Or $40
  Else MemL[0:VmF + fFl] := MemL[0:VmF + fFl] And Not $40;
End;

Procedure VmPush(V : LongInt);
Var Sp : LongInt;
Begin
  Sp := (VR(fEsp) - 2) And $FFFF;
  VS(fEsp, Sp);
  VmPutW(VR(fSs), Sp, V);
End;

Function VmPop : LongInt;
Var Sp : LongInt;
Begin
  Sp := VR(fEsp);
  VmPop := VmGetW(VR(fSs), Sp);
  VS(fEsp, Sp + 2);
End;

Procedure VmGoto(Seg, Ofs : LongInt);
Begin
  VSeg(fCs, Seg);
  MemL[0:VmF + fEip] := Ofs And $FFFF;
End;

{ FLAGS vus par la machine (IF virtuel) }
Function VmVFlags : LongInt;
Begin
  VmVFlags := (MemL[0:VmF + fFl] And $0DD5) Or 2 Or (Ord(VmIF) * $200) Or
              VmFlHi;
End;

{ Charger FLAGS depuis la machine (POPF, IRET) }
Procedure VmLoadFlags(V : LongInt);
Begin
  VmIF := (V And $200) <> 0;
  VmFlHi := V And $7000;
  MemL[0:VmF + fFl] := (MemL[0:VmF + fFl] And LongInt($FFFFF000)) Or
                       (V And $0DD5) Or $202;
End;

Function VmRegStr : String;
Begin
  VmRegStr := 'AX=' + HexStr(VR(fEax), 4) + ' BX=' + HexStr(VR(fEbx), 4) +
    ' CX=' + HexStr(VR(fEcx), 4) + ' DX=' + HexStr(VR(fEdx), 4) +
    ' SI=' + HexStr(VR(fEsi), 4) + ' DI=' + HexStr(VR(fEdi), 4) +
    ' BP=' + HexStr(VR(fEbp), 4) + ' DS=' + HexStr(VR(fDs), 4) +
    ' ES=' + HexStr(VR(fEs), 4) + ' SS:SP=' + HexStr(VR(fSs), 4) + ':' +
    HexStr(VR(fEsp), 4) + ' PSP=' + HexStr(VmCurPsp, 4);
End;

{ ------------------------------------------------------------------ }

Procedure VmMouDraw; Forward;

{ Pagination et souches d'entree / de sortie / de faute               }
{ ------------------------------------------------------------------ }

Procedure SetCr3(V : LongInt);
Begin
  asm
    mov eax,V
    mov cr3,eax
  end;
End;

Function GetCr3 : LongInt;
Var V : LongInt;
Begin
  asm
    mov eax,cr3
    mov V,eax
  end;
  GetCr3 := V;
End;

Function GetCr2 : LongInt;
Var V : LongInt;
Begin
  asm
    mov eax,cr2
    mov V,eax
  end;
  GetCr2 := V;
End;

{ Pagination : celle du noyau (repertoire unique, entree 0 = table de
  pages de la session courante) }
Function PagingInit : Boolean;
Begin
  VmPd := PageDir;
  PagingInit := True;
End;

Procedure V86Trap(F : LongInt); Forward;

Procedure VmJmp(Var A : LongInt; Target : LongInt);
Begin
  PutB(A, $E9);
  PutD(A, Target - (A + 4));
End;

{ Saut court conditionnel a corriger (PutJcc puis FixJcc) }
Procedure PutJcc(Var A : LongInt; Op : LongInt; Var Fix : LongInt);
Begin
  PutB(A, Op);
  Fix := A;
  PutB(A, 0);
End;

Procedure FixJcc(Fix, Target : LongInt);
Begin
  Mem[0:Fix] := (Target - (Fix + 1)) And $FF;
End;

{ ss: cmp [CurTask], VmTask (EAX preserve) }
Procedure PutIsVmT(Var A : LongInt);
Begin
  PutB(A, $50);                                     { push eax }
  PutB(A, $36); PutB(A, $A1); PutD(A, LongInt(@CurTask));
  PutB(A, $36); PutB(A, $3B); PutB(A, $05); PutD(A, LongInt(@VmTask));
  PutB(A, $58);                                     { pop eax }
End;

{ Souches de faute et d'interruption. Un evenement du mode V86, ou du
  code en anneau 3 de la tache de la machine (client DPMI), va au
  moniteur ; les autres au gestionnaire d'origine. Le cadre fait
  toujours 88 octets sous ESP0 : CR3, PUSHAD, GS FS ES DS, puis le
  cadre du processeur (V86 : 9 mots ; anneau 3 : 16 octets de bourrage
  et 5 mots). La sortie le reconstruit selon le mode du contexte, ce
  qui permet de passer du mode V86 au mode protege et inversement. }
{ vecteurs d'exception detournes vers le moniteur }
Function VmVecOf(I : LongInt) : LongInt;
Begin
  Case I Of
    0 : VmVecOf := 0;   1 : VmVecOf := 1;   2 : VmVecOf := 3;
    3 : VmVecOf := 4;   4 : VmVecOf := 5;   5 : VmVecOf := 6;
    6 : VmVecOf := 7;   7 : VmVecOf := 10;  8 : VmVecOf := 11;
    9 : VmVecOf := 12;  10 : VmVecOf := 13; 11 : VmVecOf := 14;
    12 : VmVecOf := 16;
  Else
    VmVecOf := 17;
  End;
End;

Procedure VmBuildStubs;
Var A, Base, Common, ExitL, I, V, Orig, K, J1, J2, J3, Err, VmLb, OrL : LongInt;
Begin
  If VmStubsOk Then Exit;
  Base := KAlloc(2048 + 16);
  Base := (Base + 15) And Not 15;
  { partie commune : segments, PUSHAD, segments du noyau, CR3 du noyau }
  A := Base;
  Common := A;
  PutB(A, $1E); PutB(A, $06);                       { push ds ; push es }
  PutB(A, $0F); PutB(A, $A0); PutB(A, $0F); PutB(A, $A8);   { fs ; gs }
  PutB(A, $60);
  PutB(A, $66); PutB(A, $B8); PutB(A, $10); PutB(A, 0);
  PutB(A, $8E); PutB(A, $D8); PutB(A, $8E); PutB(A, $C0);
  PutB(A, $8E); PutB(A, $E8);
  PutB(A, $66); PutB(A, $B8); PutB(A, $18); PutB(A, 0);
  PutB(A, $8E); PutB(A, $E0);
  { CR3 garde dans le cadre (le repertoire de pages est celui du noyau,
    dont l'entree 0 suit la session) }
  PutB(A, $0F); PutB(A, $20); PutB(A, $D8);         { mov eax,cr3 }
  PutB(A, $50);
  PutB(A, $FC);
  PutB(A, $89); PutB(A, $E0);                       { mov eax,esp }
  PutB(A, $83); PutB(A, $C0); PutB(A, 4);           { add eax,4 }
  PutB(A, $50);
  PutB(A, $B8); PutD(A, LongInt(@V86Trap));
  PutB(A, $FF); PutB(A, $D0);                       { call eax }
  PutB(A, $83); PutB(A, $C4); PutB(A, 4);           { add esp,4 }
  ExitL := A;
  PutB(A, $58);                                     { pop eax }
  PutB(A, $0F); PutB(A, $22); PutB(A, $D8);         { mov cr3,eax (TLB) }
  PutB(A, $61);                                     { popad }
  PutB(A, $0F); PutB(A, $A9); PutB(A, $0F); PutB(A, $A1);   { gs ; fs }
  PutB(A, $07); PutB(A, $1F);                       { pop es ; pop ds }
  PutB(A, $36); PutB(A, $03); PutB(A, $25);       { add esp,ss:[VmPad] }
  PutD(A, LongInt(@VmPad));
  PutB(A, $CF);                                     { iretd }
  { entree : EAX = VmImg (17 registres du cadre, mode V86) }
  VmEnterS := A;
  PutB(A, $55); PutB(A, $53); PutB(A, $56); PutB(A, $57);
  PutB(A, $89); PutB(A, $25); PutD(A, LongInt(@VmKEsp));
  PutB(A, $89); PutB(A, $25); PutD(A, TssBase + 4);
  PutB(A, $8B); PutB(A, $15); PutD(A, LongInt(@VmE0P));
  PutB(A, $89); PutB(A, $22);                       { mov [edx],esp }
  PutB(A, $B9); PutD(A, 9);
  PutB(A, $8D); PutB(A, $70); PutB(A, 64);          { lea esi,[eax+64] }
  PutB(A, $FF); PutB(A, $36);                       { push [esi] }
  PutB(A, $83); PutB(A, $EE); PutB(A, 4);           { sub esi,4 }
  PutB(A, $E2); PutB(A, $F9);                       { loop }
  For K := 1 To 4 Do
  Begin
    PutB(A, $6A); PutB(A, 0);                       { push 0 }
  End;
  PutB(A, $B9); PutD(A, 8);
  PutB(A, $FF); PutB(A, $36);
  PutB(A, $83); PutB(A, $EE); PutB(A, 4);
  PutB(A, $E2); PutB(A, $F9);
  PutB(A, $FF); PutB(A, $35); PutD(A, LongInt(@VmPd));
  PutB(A, $C7); PutB(A, $05); PutD(A, LongInt(@VmPad)); PutD(A, 0);
  VmJmp(A, ExitL);
  { sortie : retour de l'appel d'entree }
  VmLeaveS := A;
  PutB(A, $FA);
  PutB(A, $8B); PutB(A, $25); PutD(A, LongInt(@VmKEsp));
  PutB(A, $5F); PutB(A, $5E); PutB(A, $5B); PutB(A, $5D);
  PutB(A, $C3);
  { une souche par vecteur d'exception }
  A := (A + 15) And Not 15;
  For I := 0 To 13 Do
  Begin
    V := VmVecOf(I);
    Err := Ord(V In [10..14, 17]);
    Orig := (LongInt(Idt[V].OfsHi) Shl 16) Or Idt[V].OfsLo;
    SetGate(V, A);
    PutB(A, $F6); PutB(A, $44); PutB(A, $24);
    PutB(A, 10 + 4 * Err); PutB(A, 2);              { test VM }
    PutJcc(A, $75, J1);                             { jnz vm }
    PutB(A, $F6); PutB(A, $44); PutB(A, $24);
    PutB(A, 4 + 4 * Err); PutB(A, 3);               { test RPL de CS }
    PutJcc(A, $74, J2);                             { jz orig }
    PutIsVmT(A);
    PutJcc(A, $75, J3);                             { jne orig }
    { anneau 3 de la machine : client DPMI }
    If Err <> 0 Then
    Begin
      PutB(A, $36); PutB(A, $8F); PutB(A, $05); PutD(A, LongInt(@VmErrCode));
    End;
    For K := 1 To 4 Do
    Begin
      PutB(A, $6A); PutB(A, 0);
    End;
    PutB(A, $36); PutB(A, $C7); PutB(A, $05);
    PutD(A, LongInt(@VmVec)); PutD(A, V);
    VmJmp(A, Common);
    VmLb := A;
    FixJcc(J1, VmLb);
    If Err <> 0 Then
    Begin
      PutB(A, $36); PutB(A, $8F); PutB(A, $05); PutD(A, LongInt(@VmErrCode));
    End;
    PutB(A, $36); PutB(A, $C7); PutB(A, $05);
    PutD(A, LongInt(@VmVec)); PutD(A, V);
    VmJmp(A, Common);
    OrL := A;
    FixJcc(J2, OrL); FixJcc(J3, OrL);
    VmJmp(A, Orig);
    A := (A + 15) And Not 15;
  End;
  { pas de portes de niveau 3 : un INT n d'un client DPMI provoque une
    faute de protection generale (portes de niveau 0), servie par le
    moniteur (les vecteurs 20h a 2Fh sont les IRQ du noyau) }
  VmStubsOk := True;
  VmLog('DOS : souches en ' + HexStr(Base, 8) + ', sortie ' +
       HexStr(ExitL, 8));
End;

{ Executer la machine jusqu'a sa fin (VmQuit) }
Procedure VmRun;
Var A, S : LongInt;
Begin
  VmE0P := LongInt(@TkEsp0[CurTask]);
  A := LongInt(@VmImg);
  S := VmEnterS;
  asm
    mov eax,A
    mov ecx,S
    call ecx
    sti
  end;
End;

Procedure VmQuit(Code : LongInt);
Var S : LongInt;
Begin
  VmExitCode := Code;
  S := VmLeaveS;
  asm
    mov eax,S
    jmp eax
  end;
End;

{ ------------------------------------------------------------------ }

{ Ecran texte de la machine                                          }
{ ------------------------------------------------------------------ }

Function VmPage : LongInt;
Begin
  VmPage := Mem[0:VmBda($62)] And 7;
End;

Function VmScrA(Pg : LongInt) : LongInt;
Begin
  If Mem[0:VmBda($49)] = 7 Then VmScrA := VmRam + $B0000
  Else VmScrA := VmRam + $B8000 + Pg * $1000;
End;

Procedure VmGetCur(Pg : LongInt; Var X, Y : LongInt);
Begin
  X := Mem[0:VmBda($50 + Pg * 2)];
  Y := Mem[0:VmBda($51 + Pg * 2)];
End;

Procedure VmSetCur(Pg, X, Y : LongInt);
Begin
  Mem[0:VmBda($50 + Pg * 2)] := X;
  Mem[0:VmBda($51 + Pg * 2)] := Y;
End;

{ Defiler la fenetre (R1,C1)-(R2,C2) de N lignes (0 : effacer) }
Procedure VmScroll(Pg, N, Attr, R1, C1, R2, C2 : LongInt; Up : Boolean);
Var A, R, C, H, Src : LongInt;
Begin
  If R2 > 24 Then R2 := 24;
  If C2 > 79 Then C2 := 79;
  If (R1 > R2) Or (C1 > C2) Then Exit;
  A := VmScrA(Pg);
  H := R2 - R1 + 1;
  If (N = 0) Or (N > H) Then N := H;
  For R := 0 To H - 1 Do
  Begin
    If Up Then
    Begin
      Src := R1 + R + N;
      For C := C1 To C2 Do
        If Src <= R2 Then
          MemW[0:A + ((R1 + R) * 80 + C) * 2] :=
            MemW[0:A + (Src * 80 + C) * 2]
        Else MemW[0:A + ((R1 + R) * 80 + C) * 2] := (Attr Shl 8) Or 32;
    End
    Else
    Begin
      Src := R2 - R - N;
      For C := C1 To C2 Do
        If Src >= R1 Then
          MemW[0:A + ((R2 - R) * 80 + C) * 2] :=
            MemW[0:A + (Src * 80 + C) * 2]
        Else MemW[0:A + ((R2 - R) * 80 + C) * 2] := (Attr Shl 8) Or 32;
    End;
  End;
End;

{ Ecriture teletype (INT 10h 0Eh) sur la page active }
Procedure VmTty(Ch : LongInt);
Var Pg, X, Y, A : LongInt;
Begin
  Pg := VmPage;
  VmGetCur(Pg, X, Y);
  A := VmScrA(Pg);
  Case Ch And 255 Of
    7 : ;
    8 : If X > 0 Then Dec(X);
    10 : Inc(Y);
    13 : X := 0;
  Else
    Mem[0:A + (Y * 80 + X) * 2] := Ch;
    Inc(X);
    If X >= 80 Then
    Begin
      X := 0;
      Inc(Y);
    End;
  End;
  If Y >= 25 Then
  Begin
    VmScroll(Pg, 1, Mem[0:A + (24 * 80 + X) * 2 + 1], 0, 0, 24, 79, True);
    Y := 24;
  End;
  VmSetCur(Pg, X, Y);
End;

{ Sortie de caractere du DOS (tabulations) }
Procedure VmConOut(Ch : LongInt);
Var X, Y : LongInt;
Begin
  If (Ch And 255) = 9 Then
  Begin
    Repeat
      VmTty(32);
      VmGetCur(VmPage, X, Y);
    Until (X Mod 8) = 0;
  End
  Else VmTty(Ch);
End;

Procedure VmConStr(Const S : String);
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do VmConOut(Ord(S[I]));
End;

Procedure VmClearScr;
Var I, A : LongInt;
Begin
  A := VmRam + $B8000;
  For I := 0 To 8 * 2048 - 1 Do MemW[0:A + I * 2] := $0720;
  For I := 0 To 7 Do VmSetCur(I, 0, 0);
End;

{ ------------------------------------------------------------------ }
{ Interruptions de la machine                                        }
{ ------------------------------------------------------------------ }

Procedure VmService(N : LongInt); Forward;

Function VmVecDefault(N : LongInt) : Boolean;
Begin
  VmVecDefault := MemL[0:VmRam + N * 4] = (LongInt(VmBios) Shl 16) +
                  VmStubO + N;
End;

{ INT N : FLAGS, CS et IP empiles, IF et TF effaces, puis le vecteur ;
  un vecteur du BIOS ou du DOS de Pasdows est servi aussitot }
Procedure VmInt(N : LongInt);
Var V : LongInt;
Begin
  If VmTrace And Not (N In [8, 9, $16, $21, $28, $33]) Then
    VmLog('INT ' + HexStr(N, 2) + 'h AX=' + HexStr(VR(fEax), 4) + ' de ' +
         HexStr(VR(fCs), 4) + ':' + HexStr(VR(fEip), 4));
  VmPush(VmVFlags);
  VmPush(VR(fCs));
  VmPush(VR(fEip));
  VmIF := False;
  MemL[0:VmF + fFl] := MemL[0:VmF + fFl] And Not $100;
  V := MemL[0:VmRam + N * 4];
  VmGoto(V Shr 16, V And $FFFF);
  If V = (LongInt(VmBios) Shl 16) + VmStubO + N Then VmService(N);
End;

{ Retour d'un service (IRET) : CF, ZF... du resultat, IF de l'appelant }
Procedure VmIretRet;
Var Ip, Cs, Fl, Cur : LongInt;
Begin
  Ip := VmPop; Cs := VmPop; Fl := VmPop;
  Cur := MemL[0:VmF + fFl];
  VmGoto(Cs, Ip);
  VmIF := (Fl And $200) <> 0;
  MemL[0:VmF + fFl] := (Cur And LongInt($FFFFF000) And Not $500) Or
                       (Cur And $8D5) Or (Fl And $500) Or $202;
End;

{ Temps ecoule : tops d'horloge (INT 08h) a delivrer }
Procedure VmTimeUpd;
Var Ms : LongInt;
Begin
  Ms := VmMsNow - VmLastMs;
  If Ms <= 0 Then Exit;
  VmLastMs := VmMsNow;
  If Ms > 1000 Then Ms := 1000;
  VmPitAcc := VmPitAcc + Ms * 1193;
  While VmPitAcc >= VmPitDiv Do
  Begin
    VmPitAcc := VmPitAcc - VmPitDiv;
    If VmTickDue < 8 Then Inc(VmTickDue);
  End;
End;

Function VmIrqPending : Boolean;
Begin
  VmTimeUpd;
  VmIrqPending := ((VmTickDue > 0) And ((VmPicMask And 1) = 0) And
                   ((VmIsr And 1) = 0)) Or
                  ((VmKqHead <> VmKqTail) And ((VmPicMask And 2) = 0) And
                   ((VmIsr And 3) = 0));
End;

{ Delivrer une interruption materielle virtuelle si IF le permet }
Procedure VmCheckIrq;
Begin
  If VmMouShow >= 0 Then VmMouDraw;
  If Not VmIF Then Exit;
  VmTimeUpd;
  If (VmTickDue > 0) And ((VmPicMask And 1) = 0) And
     ((VmIsr And 1) = 0) Then
  Begin
    Dec(VmTickDue);
    VmIsr := VmIsr Or 1;
    VmInt(8);
    Exit;
  End;
  If (VmKqHead <> VmKqTail) And ((VmPicMask And 2) = 0) And
     ((VmIsr And 3) = 0) Then
  Begin
    VmCurKey := VmKq[VmKqHead];
    VmKqHead := (VmKqHead + 1) Mod VmKqMax;
    VmPort60 := (VmCurKey Shr 16) And $FF;
    VmIsr := VmIsr Or 2;
    VmInt(9);
  End;
End;

{ Interruption d'horloge du noyau pendant le code 16 bits (cadre B) }
Procedure VmTickPM(B : LongInt); Forward;

Var VmDbgN : LongInt;

Procedure VmTick(B : LongInt);
Begin
  Inc(VmDbgN);
  If VmDbgN < 4 Then VmLog('TICK ' + HexStr(B, 8) + ' ' + HexStr(MemL[0:B + 32], 8) + ' ' + HexStr(MemL[0:B + 36], 8) + ' ' + HexStr(MemL[0:B + 40], 8) + ' esp0=' + HexStr(Tss[1], 8));
  { programme en mode graphique a l'arriere-plan : suspendu }
  If VmGfx And (FgSess <> VmSess) Then VmFgWait;
  If (MemL[0:B + 40] And $20000) <> 0 Then
  Begin
    VmF := B;
    VmCheckIrq;
    If VmDbgN < 4 Then VmLog('TICK fin ' + HexStr(MemL[0:B + 32], 8) + ' ' + HexStr(MemL[0:B + 36], 8) + ' ' + HexStr(MemL[0:B + 40], 8));
  End
  Else VmTickPM(B);
End;

{ ------------------------------------------------------------------ }

{ Clavier                                                            }
{ ------------------------------------------------------------------ }

Function VmBufHas : Boolean;
Begin
  VmBufHas := MemW[0:VmBda($1A)] <> MemW[0:VmBda($1C)];
End;

Function VmBufPeek : LongInt;
Begin
  VmBufPeek := MemW[0:VmRam + $400 + MemW[0:VmBda($1A)]];
End;

Function VmBufPop : LongInt;
Var H : LongInt;
Begin
  H := MemW[0:VmBda($1A)];
  VmBufPop := MemW[0:VmRam + $400 + H];
  H := H + 2;
  If H >= MemW[0:VmBda($82)] Then H := MemW[0:VmBda($80)];
  MemW[0:VmBda($1A)] := H;
End;

Function VmBufPush(K : LongInt) : Boolean;
Var T, N : LongInt;
Begin
  T := MemW[0:VmBda($1C)];
  N := T + 2;
  If N >= MemW[0:VmBda($82)] Then N := MemW[0:VmBda($80)];
  VmBufPush := N <> MemW[0:VmBda($1A)];
  If N = MemW[0:VmBda($1A)] Then Exit;
  MemW[0:VmRam + $400 + T] := K;
  MemW[0:VmBda($1C)] := N;
End;

{ Etat des touches de controle (0417h, 0418h) : etat du clavier du noyau
  (KbdState : bits 0 a 7 comme 0417h ; 100h Ctrl gauche, 200h Alt
  gauche, 1000h a 4000h verrouillages enfonces, 8000h Syst) }
Procedure VmShiftUpd;
Var C : LongInt;
Begin
  Mem[0:VmBda($17)] := KbdState And $FF;
  C := (KbdState Shr 8) And 3;
  If (KbdState And $8000) <> 0 Then C := C Or 4;
  C := C Or ((KbdState Shr 8) And $70);
  Mem[0:VmBda($18)] := C;
End;

Var
  VmPadCh : String;     { '789-456+1230.' (VmSetup) }

Function VmAltNav(Sc : LongInt) : LongInt;
Begin
  Case Sc Of
    $47 : VmAltNav := $97; $48 : VmAltNav := $98; $49 : VmAltNav := $99;
    $4B : VmAltNav := $9B; $4D : VmAltNav := $9D; $4F : VmAltNav := $9F;
    $50 : VmAltNav := $A0; $51 : VmAltNav := $A1; $52 : VmAltNav := $A2;
    $53 : VmAltNav := $A3;
  Else
    VmAltNav := 0;
  End;
End;

Function VmCtlNav(Sc : LongInt) : LongInt;
Begin
  Case Sc Of
    $47 : VmCtlNav := $77; $48 : VmCtlNav := $8D; $49 : VmCtlNav := $84;
    $4B : VmCtlNav := $73; $4D : VmCtlNav := $74; $4F : VmCtlNav := $75;
    $50 : VmCtlNav := $91; $51 : VmCtlNav := $76; $52 : VmCtlNav := $92;
    $53 : VmCtlNav := $93;
  Else
    VmCtlNav := 0;
  End;
End;

{ Code du BIOS (balayage * 256 + ASCII) d'une touche ; 0 : aucun.
  Ch : caractere calcule par le pilote du clavier du noyau }
Function VmBiosKey(Sc : LongInt; Ext : Boolean; Ch : LongInt) : LongInt;
Var Sh, Ct, Al, Num : Boolean; A : LongInt;
Begin
  VmBiosKey := 0;
  Sh := (KbdState And 3) <> 0;
  Ct := (KbdState And 4) <> 0;
  Al := (KbdState And 8) <> 0;
  Num := (KbdState And $20) <> 0;
  Case Sc Of
    $1D, $2A, $36, $38, $3A, $45, $46, 0 : Exit;
  End;
  If Ext And (Sc = $1C) Then
  Begin
    If Ct Then VmBiosKey := $E00A Else VmBiosKey := $E00D;
    Exit;
  End;
  If Ext And (Sc = $35) Then
  Begin
    VmBiosKey := $E02F;
    Exit;
  End;
  If (Sc >= $3B) And (Sc <= $44) Then
  Begin
    If Al Then A := Sc + $2D Else If Ct Then A := Sc + $23
    Else If Sh Then A := Sc + $19 Else A := Sc;
    VmBiosKey := A Shl 8;
    Exit;
  End;
  If (Sc = $57) Or (Sc = $58) Then
  Begin
    A := Sc + $2E;
    If Al Then A := A + 6 Else If Ct Then A := A + 4
    Else If Sh Then A := A + 2;
    VmBiosKey := A Shl 8;
    Exit;
  End;
  If (Sc >= $47) And (Sc <= $53) Then
  Begin
    If (Sc = $4A) Or (Sc = $4E) Then
    Begin
      VmBiosKey := (Sc Shl 8) Or Ord(VmPadCh[Sc - $46]);
      Exit;
    End;
    If Al Then
    Begin
      If VmAltNav(Sc) <> 0 Then VmBiosKey := VmAltNav(Sc) Shl 8;
      Exit;
    End;
    If Ct Then
    Begin
      If VmCtlNav(Sc) <> 0 Then VmBiosKey := VmCtlNav(Sc) Shl 8;
      Exit;
    End;
    If Not Ext And (Num <> Sh) Then
      VmBiosKey := (Sc Shl 8) Or Ord(VmPadCh[Sc - $46])
    Else If Ext Then VmBiosKey := (Sc Shl 8) Or $E0
    Else VmBiosKey := Sc Shl 8;
    Exit;
  End;
  If Al Then
  Begin
    Case Sc Of
      $02..$0D : A := Sc + $76;
      $0F : A := $A5;
    Else
      A := Sc;
    End;
    If Sc = $39 Then VmBiosKey := $3920 Else VmBiosKey := A Shl 8;
    Exit;
  End;
  If Ct Then
  Begin
    Case Sc Of
      $01 : A := $011B; $03 : A := $0300; $07 : A := $071E;
      $0C : A := $0C1F; $0E : A := $0E7F; $0F : A := $9400;
      $1A : A := $1A1B; $1B : A := $1B1D; $1C : A := $1C0A;
      $2B : A := $2B1C; $39 : A := $3920; $37 : A := $9600;
    Else
      If (Ch >= 1) And (Ch <= 26) Then A := (Sc Shl 8) Or Ch
      Else A := 0;
    End;
    VmBiosKey := A;
    Exit;
  End;
  Case Sc Of
    $01 : A := $011B;
    $0E : A := $0E08;
    $0F : If Sh Then A := $0F00 Else A := $0F09;
    $1C : A := $1C0D;
    $39 : A := $3920;
  Else
    If Ch = 0 Then A := 0 Else A := (Sc Shl 8) Or (Ch And 255);
  End;
  VmBiosKey := A;
End;

{ Touche de la session de la machine au premier plan (interruption du
  clavier du noyau) : code de balayage (Up : relachement), prefixe E0h
  et caractere calcule par le noyau }
Procedure DosKeyIn(Up : Boolean; Sc : LongInt; Ext : Boolean; Ch : LongInt);
Var K, N : LongInt;
Begin
  If Not VmOn Then Exit;
  Sc := Sc And $7F;
  K := (Sc Or (Ord(Up) * $80)) Shl 16;
  If Ext Then K := K Or $1000000;
  If Not Up Then
  Begin
    N := VmBiosKey(Sc, Ext, Ch);
    If N <> 0 Then K := K Or $2000000 Or (N And $FFFF);
  End;
  N := (VmKqTail + 1) Mod VmKqMax;
  If N <> VmKqHead Then
  Begin
    VmKq[VmKqTail] := K;
    VmKqTail := N;
  End;
End;

{ Tops et touches servis par le noyau (attente dans un service, sans
  passer par les gestionnaires de la machine) }
Procedure VmPumpNative;
Var K, T : LongInt;
Begin
  VmTimeUpd;
  While VmTickDue > 0 Do
  Begin
    Dec(VmTickDue);
    T := MemL[0:VmBda($6C)] + 1;
    If T >= $1800B0 Then
    Begin
      T := 0;
      Mem[0:VmBda($70)] := 1;
    End;
    MemL[0:VmBda($6C)] := T;
  End;
  While VmKqHead <> VmKqTail Do
  Begin
    K := VmKq[VmKqHead];
    VmKqHead := (VmKqHead + 1) Mod VmKqMax;
    If (K And $2000000) <> 0 Then VmBufPush(K And $FFFF);
  End;
End;

{ Le service courant reprendra apres une interruption detournee : rend
  True si une interruption a ete delivree (le HLT du service sera
  reexecute a son retour) }
Function VmIrqRestart : Boolean;
Var Hook : Boolean;
Begin
  VmIrqRestart := False;
  VmTimeUpd;
  Hook := ((VmTickDue > 0) And Not (VmVecDefault(8) And
           VmVecDefault($1C))) Or
          ((VmKqHead <> VmKqTail) And Not VmVecDefault(9));
  If Not Hook Then Exit;
  VmIF := True;
  VmCheckIrq;
  VmNoIret := True;
  VmIrqRestart := True;
End;

{ Attendre une touche (services du DOS) : code du BIOS }
Function VmWaitKey : LongInt;
Begin
  Repeat
    If VmBufHas Then
    Begin
      VmWaitKey := VmBufPop;
      Exit;
    End;
    VmPumpNative;
    If Not VmBufHas Then VmSleep(2);
  Until False;
End;

{ Programme inactif (INT 28h, INT 2Fh 1680h, scrutation du clavier) }
Procedure VmIdle;
Begin
  Inc(VmIdleN);
  If VmIdleN >= 4 Then
  Begin
    VmIdleN := 0;
    VmSleep(1);
  End;
End;

Procedure VmInt09;
Var K : LongInt;
Begin
  K := VmCurKey;
  VmCurKey := 0;
  If (K And $2000000) <> 0 Then
  Begin
    VmBufPush(K And $FFFF);
    VmIdleN := 0;
  End;
  VmIsr := VmIsr And Not 2;
End;

Procedure VmInt08;
Var T : LongInt;
Begin
  T := MemL[0:VmBda($6C)] + 1;
  If T >= $1800B0 Then
  Begin
    T := 0;
    Mem[0:VmBda($70)] := 1;
  End;
  MemL[0:VmBda($6C)] := T;
  VmIsr := VmIsr And Not 1;
  { INT 1Ch detourne : il recoit le cadre d'interruption (son IRET
    revient au code interrompu) }
  If Not VmVecDefault($1C) Then
  Begin
    T := MemL[0:VmRam + $1C * 4];
    VmGoto(T Shr 16, T And $FFFF);
    VmNoIret := True;
  End;
End;

Procedure VmInt16;
Var AH, K : LongInt;
Begin
  AH := VRH(fEax);
  VmShiftUpd;
  Case AH Of
    $00, $10 :
    Begin
      Repeat
        If VmBufHas Then
        Begin
          K := VmBufPop;
          If (AH = 0) And ((K And $FF) = $E0) And (K > $FF) Then
            K := K And $FF00;
          VS(fEax, K);
          VmIdleN := 0;
          Exit;
        End;
        If VmIrqRestart Then Exit;
        VmPumpNative;
        If Not VmBufHas Then VmSleep(2);
      Until False;
    End;
    $01, $11 :
    Begin
      If Not VmBufHas Then
      Begin
        If VmIrqRestart Then Exit;
        VmPumpNative;
      End;
      If VmBufHas Then
      Begin
        K := VmBufPeek;
        If (AH = 1) And ((K And $FF) = $E0) And (K > $FF) Then
          K := K And $FF00;
        VS(fEax, K);
        VmSetZF(False);
      End
      Else
      Begin
        VmSetZF(True);
        VmIdle;
      End;
    End;
    $02 : VSL(fEax, Mem[0:VmBda($17)]);
    $12 :
    Begin
      VSL(fEax, Mem[0:VmBda($17)]);
      VSH(fEax, Mem[0:VmBda($18)] And $73);
    End;
    $05 : VSL(fEax, Ord(Not VmBufPush(VR(fEcx))));
    $09 : VSL(fEax, $20);
    $0A : VS(fEbx, $41AB);
  End;
End;

{ ------------------------------------------------------------------ }

{ ------------------------------------------------------------------ }
{ Ecran : la carte VGA de la session plein ecran                     }
{ ------------------------------------------------------------------ }
{ Comme une session DOS plein ecran d'OS/2, la machine au premier plan
  utilise directement la carte : en mode texte, sa memoire B8000h est
  celle de la carte (le tampon de la session a l'arriere-plan) ; en
  mode graphique, le vrai BIOS change de mode et dessine (INT 10h
  appele en mode reel par BiosInt, avec la zone video de la BDA et les
  tampons de la machine recopies), et les ports de la carte (3B0h a
  3DFh) sont ceux du materiel. A l'arriere-plan, un programme en mode
  graphique est suspendu ; son ecran (plans, palette) est sauve quand on
  quitte la session et rendu a son retour. }

Const
  VmBounce = $60000;            { tampon physique des appels du BIOS }

Var
  VgMode, VgW, VgH : LongInt;
  VgAc : Array[0..20] Of LongInt;
  VgSeq : Array[0..7] Of LongInt;
  VgGc : Array[0..8] Of LongInt;
  VgSeqI, VgGcI, VgAcI, VgStart, VgDLo, VgDHi : LongInt;
  VgPalDirty, VgPlanar : Boolean;
  VgHwGfx : Boolean;            { la carte est dans un mode graphique de la machine }
  VgSave : LongInt;             { ecran sauve : 4 plans de 64 Ko + DAC (768) }
  VgSaved : Boolean;
  VgBdaV : Array[0..63] Of Byte;  { zone video de la BDA (49h-66h, 84h-8Ah) }
  VgBuf : LongInt;              { tampon du noyau (8 Ko) }

Procedure VgDims(M : LongInt);
Begin
  Case M And $7F Of
    4, 5, $0D, $13 : Begin VgW := 320; VgH := 200; End;
    6, $0E : Begin VgW := 640; VgH := 200; End;
    $0F, $10 : Begin VgW := 640; VgH := 350; End;
    $11, $12 : Begin VgW := 640; VgH := 480; End;
  Else
    Begin VgW := 640; VgH := 400; End;
  End;
End;

{ INT 10h du vrai BIOS avec les registres de la machine ; Kind : tampon
  de la machine (0 aucun, 1 ES:DX, 3 ES:DI) de Len octets (le bloc de
  BIOSCALL n'a pas BP : les services ES:BP sont emules) }
Procedure VmBiosVideo(Kind, Len : LongInt);
Var I, P, RDx, RDi, REs : LongInt;
Begin
  If VgBuf = 0 Then VgBuf := KAlloc(8192);
  If Len > 8192 Then Len := 8192;
  For I := 0 To 29 Do VgBdaV[I] := Mem[0:VmBda($49 + I)];
  For I := 0 To 6 Do VgBdaV[32 + I] := Mem[0:VmBda($84 + I)];
  P := 0;
  If Kind = 1 Then P := VmPtr(fEs, fEdx)
  Else If Kind = 3 Then P := VmPtr(fEs, fEdi);
  If (P <> 0) And (Len > 0) Then MoveMem(P, VgBuf, Len);
  RDx := VR(fEdx); RDi := VR(fEdi); REs := VR(fEs);
  If Kind = 1 Then RDx := 0;
  If Kind = 3 Then RDi := 0;
  If Kind <> 0 Then REs := VmBounce Shr 4;
  asm
    cli
  end;
  MemL[0:PageDir] := KernPT Or 7;
  FlushTlb;
  For I := 0 To 29 Do Mem[0:$449 + I] := VgBdaV[I];
  For I := 0 To 6 Do Mem[0:$484 + I] := VgBdaV[32 + I];
  If (P <> 0) And (Len > 0) Then MoveMem(VgBuf, VmBounce, Len);
  BiosRegs(VR(fEax), VR(fEbx), VR(fEcx), RDx, VR(fEsi), RDi, REs);
  BiosInt($10);
  For I := 0 To 29 Do VgBdaV[I] := Mem[0:$449 + I];
  For I := 0 To 6 Do VgBdaV[32 + I] := Mem[0:$484 + I];
  If (P <> 0) And (Len > 0) Then MoveMem(VmBounce, VgBuf, Len);
  RDx := MemL[0:BiosParm + 12];
  VS(fEax, MemL[0:BiosParm]); VS(fEbx, MemL[0:BiosParm + 4]);
  VS(fEcx, MemL[0:BiosParm + 8]);
  If Kind <> 1 Then VS(fEdx, RDx);
  MemL[0:PageDir] := CurPde;
  FlushTlb;
  asm
    sti
  end;
  For I := 0 To 29 Do Mem[0:VmBda($49 + I)] := VgBdaV[I];
  For I := 0 To 6 Do Mem[0:VmBda($84 + I)] := VgBdaV[32 + I];
  If (P <> 0) And (Len > 0) Then MoveMem(VgBuf, P, Len);
End;

{ curseur materiel (texte, premier plan) d'apres la BDA de la machine }
Procedure VmHwCursor;
Var P, Pg, Sh : LongInt;
Begin
  If Not VmIsFg Or VmGfx Then Exit;
  Pg := Mem[0:VmBda($62)] And 7;
  P := Pg * 2048 + Mem[0:VmBda($51 + Pg * 2)] * 80 + Mem[0:VmBda($50 + Pg * 2)];
  Port[$3D4] := $0F; Port[$3D5] := P And $FF;
  Port[$3D4] := $0E; Port[$3D5] := (P Shr 8) And $FF;
  Sh := MemW[0:VmBda($60)];
  Port[$3D4] := $0A; Port[$3D5] := (Sh Shr 8) And $3F;
  Port[$3D4] := $0B; Port[$3D5] := Sh And $1F;
  { page affichee (adresse de debut) }
  P := Pg * 2048;
  Port[$3D4] := $0C; Port[$3D5] := (P Shr 8) And $FF;
  Port[$3D4] := $0D; Port[$3D5] := P And $FF;
End;

{ Mode video M (INT 10h AH=00h) : graphique (vrai BIOS, premier plan)
  ou texte }
Procedure VgSetMode(M : LongInt);
Var Ax : LongInt;
Begin
  VgMode := M And $7F;
  VgStart := 0;
  VgDims(M);
  VgPlanar := VgMode In [$0D, $0E, $0F, $10, $11, $12];
  If VmGfx Then
  Begin
    VmFgWait;
    Ax := VR(fEax);
    VS(fEax, M And $FF);
    VmBiosVideo(0, 0);
    VS(fEax, Ax);
    VgHwGfx := True;
  End
  Else If VgHwGfx Or (VgMode <> 3) Then
  Begin
    { retour au texte (ou mode texte 40 colonnes, monochrome) }
    If VmIsFg Then
    Begin
      Ax := VR(fEax);
      VS(fEax, M And $FF);
      VmBiosVideo(0, 0);
      VS(fEax, Ax);
      VgHwGfx := False;
    End;
  End;
End;

{ Quitter la session de la machine (DoSwitch, pages du noyau, carte au
  premier plan) : l'ecran graphique est sauve, la carte revient au
  texte }
Procedure VmSwitchOut;
Var P, I : LongInt;
Begin
  If Not VmOn Or Not VgHwGfx Then Exit;
  If VgSave = 0 Then VgSave := PAlloc(4 * 65536 + 4096);
  If VgSave <> 0 Then
  Begin
    If VgPlanar Then
      For P := 0 To 3 Do
      Begin
        Port[$3CE] := 4; Port[$3CF] := P;
        Port[$3CE] := 5; Port[$3CF] := 0;
        MoveMem($A0000, VgSave + P * 65536, 65536);
      End
    Else If VgMode = $13 Then MoveMem($A0000, VgSave, 65536)
    Else MoveMem($B8000, VgSave, 32768);
    Port[$3C7] := 0;
    For I := 0 To 767 Do Mem[0:VgSave + 4 * 65536 + I] := Port[$3C9];
    VgSaved := True;
  End;
  BiosRegs(3, 0, 0, 0, 0, 0, 0);
  BiosInt($10);
  VgHwGfx := False;
End;

{ Revenir a la session de la machine (DoSwitch, pages du noyau) : mode
  graphique, plans et palette rendus ; curseur en mode texte }
Procedure VmSwitchIn;
Var P, I, Pg : LongInt;
Begin
  If Not VmOn Then Exit;
  If VmGfx Then
  Begin
    BiosRegs(VgMode Or $80, 0, 0, 0, 0, 0, 0);
    BiosInt($10);
    VgHwGfx := True;
    If VgSaved And (VgSave <> 0) Then
    Begin
      If VgPlanar Then
      Begin
        Port[$3CE] := 5; Port[$3CF] := 0;
        Port[$3CE] := 3; Port[$3CF] := 0;
        Port[$3CE] := 1; Port[$3CF] := 0;
        Port[$3CE] := 8; Port[$3CF] := $FF;
        For P := 0 To 3 Do
        Begin
          Port[$3C4] := 2; Port[$3C5] := 1 Shl P;
          MoveMem(VgSave + P * 65536, $A0000, 65536);
        End;
        Port[$3C4] := 2; Port[$3C5] := $0F;
      End
      Else If VgMode = $13 Then MoveMem(VgSave, $A0000, 65536)
      Else MoveMem(VgSave, $B8000, 32768);
      Port[$3C8] := 0;
      For I := 0 To 767 Do Port[$3C9] := Mem[0:VgSave + 4 * 65536 + I];
    End;
  End
  Else
  Begin
    { curseur : BDA de la machine (memoire physique) }
    Pg := Mem[0:VmRamPhys + $462] And 7;
    P := Pg * 2048 + Mem[0:VmRamPhys + $451 + Pg * 2] * 80 + Mem[0:VmRamPhys + $450 + Pg * 2];
    Port[$3D4] := $0F; Port[$3D5] := P And $FF;
    Port[$3D4] := $0E; Port[$3D5] := (P Shr 8) And $FF;
    I := MemW[0:VmRamPhys + $460];
    Port[$3D4] := $0A; Port[$3D5] := (I Shr 8) And $3F;
    Port[$3D4] := $0B; Port[$3D5] := I And $1F;
  End;
End;

{ Texte du BIOS en mode graphique (INT 10h 09h, 0Ah, 0Eh, 0Ch, 0Dh,
  13h) : le vrai BIOS, au premier plan }
Procedure VgBiosGfx(Kind, Len : LongInt);
Begin
  VmFgWait;
  VmBiosVideo(Kind, Len);
End;

{ INT 10h AH=13h en mode graphique : caractere par caractere (AH=09h
  puis AH=02h) }
Procedure VgWriteStr(Mode, Attr, N, X, Y, P : LongInt);
Var I, C, A, Ax, Bx, Cx, Dx, Ox, Oy, Pg, W : LongInt;
Begin
  VmFgWait;
  Ax := VR(fEax); Bx := VR(fEbx); Cx := VR(fEcx); Dx := VR(fEdx);
  Pg := (Bx Shr 8) And 7;
  Ox := Mem[0:VmBda($50 + Pg * 2)]; Oy := Mem[0:VmBda($51 + Pg * 2)];
  W := MemW[0:VmBda($4A)];
  If W <= 0 Then W := 80;
  A := Attr;
  For I := 0 To N - 1 Do
  Begin
    If (Mode And 2) <> 0 Then
    Begin
      C := Mem[0:P + I * 2]; A := Mem[0:P + I * 2 + 1];
    End
    Else C := Mem[0:P + I];
    VS(fEax, $0200); VS(fEbx, Pg Shl 8); VS(fEdx, (Y Shl 8) Or X);
    VmBiosVideo(0, 0);
    VS(fEax, $0900 Or C); VS(fEbx, (Pg Shl 8) Or A); VS(fEcx, 1);
    VmBiosVideo(0, 0);
    Inc(X);
    If X >= W Then
    Begin
      X := 0; Inc(Y);
    End;
  End;
  If (Mode And 1) = 0 Then
  Begin
    X := Ox; Y := Oy;
  End;
  VS(fEax, $0200); VS(fEbx, Pg Shl 8); VS(fEdx, (Y Shl 8) Or X);
  VmBiosVideo(0, 0);
  VS(fEax, Ax); VS(fEbx, Bx); VS(fEcx, Cx); VS(fEdx, Dx);
End;

Procedure VgPalSync;
Begin
  VgPalDirty := False;
End;

{ pointeur de la souris en mode texte : attribut inverse de la cellule
  (memoire de l'ecran de la machine) }
Var
  VmMouCellA, VmMouCellV : LongInt;

Procedure VmMouHide;
Begin
  If VmMouCellA <> 0 Then
  Begin
    Mem[0:VmMouCellA] := VmMouCellV;
    VmMouCellA := 0;
  End;
End;

Procedure VmMouDraw;
Var A, Pg : LongInt;
Begin
  If (VmMouShow < 0) Or VmGfx Then
  Begin
    VmMouHide;
    Exit;
  End;
  Pg := Mem[0:VmBda($62)] And 7;
  A := VmRam + $B8000 + Pg * $1000 + ((VmMouY Div 8) * 80 + VmMouX Div 8) * 2 + 1;
  If A = VmMouCellA Then Exit;
  VmMouHide;
  VmMouCellA := A;
  VmMouCellV := Mem[0:A];
  Mem[0:A] := VmMouCellV Xor $77;
End;

{ BIOS : video (INT 10h)                                             }
{ ------------------------------------------------------------------ }

Procedure VmSetMode(M : LongInt);
Var I : LongInt;
Begin
  Mem[0:VmBda($49)] := M And $7F;
  VmGfx := Not ((M And $7F) In [0..3, 7]);
  If (M And $7F) In [0, 1] Then MemW[0:VmBda($4A)] := 40
  Else If (M And $7F) = $13 Then MemW[0:VmBda($4A)] := 40
  Else MemW[0:VmBda($4A)] := 80;
  MemW[0:VmBda($4C)] := $1000;
  MemW[0:VmBda($4E)] := 0;
  Mem[0:VmBda($62)] := 0;
  MemW[0:VmBda($60)] := $0607;
  Mem[0:VmBda($84)] := 24;
  MemW[0:VmBda($85)] := 16;
  If ((M And $80) = 0) And Not VmGfx Then VmClearScr;
  For I := 0 To 7 Do VmSetCur(I, 0, 0);
  VmBlink := True;
  VgSetMode(M);
  If VmGfx Then
  Begin
    { lignes et hauteur des caracteres du BIOS en mode graphique }
    If VgH <= 200 Then I := 8 Else If VgH = 350 Then I := 14 Else I := 16;
    Mem[0:VmBda($84)] := VgH Div I - 1;
    MemW[0:VmBda($85)] := I;
    MemW[0:VmBda($4A)] := VgW Div 8;
    { INT 43h : police de ce mode }
    If I = 8 Then I := VmFont8O Else If I = 14 Then I := VmFont14O
    Else I := VmFontO;
    MemL[0:VmRam + $43 * 4] := (LongInt(VmBios) Shl 16) + I;
    VmMouMaxY := VgH - 1;
  End
  Else MemL[0:VmRam + $43 * 4] := (LongInt(VmBios) Shl 16) + VmFontO;
  VmHwCursor;
End;

Procedure VmWriteStr(Pg, Mode, Attr, N, X, Y, P : LongInt);
Var I, C, A, Ox, Oy : LongInt;
Begin
  VmGetCur(Pg, Ox, Oy);
  VmSetCur(Pg, X, Y);
  A := Attr;
  For I := 0 To N - 1 Do
  Begin
    If (Mode And 2) <> 0 Then
    Begin
      C := Mem[0:P + I * 2]; A := Mem[0:P + I * 2 + 1];
    End
    Else C := Mem[0:P + I];
    If C In [7, 8, 10, 13] Then VmTty(C)
    Else
    Begin
      VmGetCur(Pg, X, Y);
      MemW[0:VmScrA(Pg) + (Y * 80 + X) * 2] := (A Shl 8) Or C;
      VmTty(C);
    End;
  End;
  If (Mode And 1) = 0 Then VmSetCur(Pg, Ox, Oy);
End;

Procedure VmInt10;
Var AH, AL, Pg, X, Y, A, I, N, P : LongInt;
Begin
  AH := VRH(fEax); AL := VRL(fEax);
  { mode graphique : texte et points par le vrai BIOS (premier plan) }
  If VmGfx And (AH In [$02, $03, $09, $0A, $0C, $0D, $0E]) Then
  Begin
    VgBiosGfx(0, 0);
    Exit;
  End;
  If VmGfx And (AH = $13) Then
  Begin
    VgWriteStr(AL, VRL(fEbx), VR(fEcx), VRL(fEdx), VRH(fEdx), VmPtr(fEs, fEbp));
    Exit;
  End;
  { palette au premier plan : la carte }
  If (AH = $10) And VmIsFg Then
  Begin
    Case AL Of
      $02, $09 : VmBiosVideo(1, 17);
      $12, $17 : VmBiosVideo(1, Min(256, VR(fEcx)) * 3);
    Else
      VmBiosVideo(0, 0);
    End;
    If AL = $03 Then VmBlink := VRL(fEbx) <> 0;
    Exit;
  End;
  Case AH Of
    $00 : VmSetMode(AL);
    $01 :
    Begin
      MemW[0:VmBda($60)] := VR(fEcx);
      VmHwCursor;
    End;
    $02 :
    Begin
      VmSetCur(VRH(fEbx) And 7, VRL(fEdx), VRH(fEdx));
      VmHwCursor;
    End;
    $03 :
    Begin
      VmGetCur(VRH(fEbx) And 7, X, Y);
      VS(fEdx, (Y Shl 8) Or X);
      VS(fEcx, MemW[0:VmBda($60)]);
      VS(fEax, 0);
    End;
    $05 :
    Begin
      Mem[0:VmBda($62)] := AL And 7;
      MemW[0:VmBda($4E)] := (AL And 7) * $1000;
      VmHwCursor;
    End;
    $06, $07 :
      VmScroll(VmPage, AL, VRH(fEbx), VRH(fEcx), VRL(fEcx), VRH(fEdx),
               VRL(fEdx), AH = 6);
    $08 :
    Begin
      Pg := VRH(fEbx) And 7;
      VmGetCur(Pg, X, Y);
      VS(fEax, MemW[0:VmScrA(Pg) + (Y * 80 + X) * 2]);
    End;
    $09, $0A :
    Begin
      Pg := VRH(fEbx) And 7;
      VmGetCur(Pg, X, Y);
      A := VmScrA(Pg) + (Y * 80 + X) * 2;
      N := VR(fEcx);
      If N > 2000 - (Y * 80 + X) Then N := 2000 - (Y * 80 + X);
      For I := 0 To N - 1 Do
      Begin
        Mem[0:A + I * 2] := AL;
        If AH = 9 Then Mem[0:A + I * 2 + 1] := VRL(fEbx);
      End;
    End;
    $0E :
    Begin
      VmTty(AL);
      VmHwCursor;
    End;
    $0F :
    Begin
      VSL(fEax, Mem[0:VmBda($49)]);
      VSH(fEax, MemW[0:VmBda($4A)]);
      VSH(fEbx, VmPage);
    End;
    $10 :
    Begin
      VgPalDirty := True;
      Case AL Of
        $00 : If VRL(fEbx) < 16 Then VgAc[VRL(fEbx)] := VRH(fEbx);
        $01 : VgAc[$11] := VRH(fEbx);
        $02 :
        Begin
          P := VmPtr(fEs, fEdx);
          For I := 0 To 15 Do VgAc[I] := Mem[0:P + I];
          VgAc[$11] := Mem[0:P + 16];
        End;
        $03 : VmBlink := VRL(fEbx) <> 0;
        $07 : VSH(fEbx, VgAc[VRL(fEbx) And 31]);
        $08 : VSH(fEbx, VgAc[$11]);
        $09 :
        Begin
          P := VmPtr(fEs, fEdx);
          For I := 0 To 15 Do Mem[0:P + I] := VgAc[I];
          Mem[0:P + 16] := VgAc[$11];
        End;
        $10 :
        Begin
          I := VR(fEbx) * 3;
          If I < 768 Then
          Begin
            VmDac[I] := VRH(fEdx) And 63; VmDac[I + 1] := VRH(fEcx) And 63;
            VmDac[I + 2] := VRL(fEcx) And 63;
          End;
        End;
        $12, $17 :
        Begin
          P := VmPtr(fEs, fEdx);
          For I := VR(fEbx) * 3 To Min(767, (VR(fEbx) + VR(fEcx)) * 3 - 1)
          Do
            If AL = $12 Then VmDac[I] := Mem[0:P + I - VR(fEbx) * 3]
            Else Mem[0:P + I - VR(fEbx) * 3] := VmDac[I];
        End;
        $15 :
        Begin
          I := VRL(fEbx) * 3;
          VSH(fEdx, VmDac[I]); VSH(fEcx, VmDac[I + 1]);
          VSL(fEcx, VmDac[I + 2]);
        End;
        $1A : VS(fEbx, 0);
      End;
    End;
    $11 :
      If AL = $30 Then
      Begin
        { polices : 0 INT 1Fh, 1 INT 43h, 2 8x14, 3 et 4 8x8, 6 8x16 }
        VSeg(fEs, VmBios);
        Case VRH(fEbx) Of
          0, 1 :
          Begin
            I := MemL[0:VmRam + ($1F + ($43 - $1F) * VRH(fEbx)) * 4];
            VSeg(fEs, I Shr 16); VS(fEbp, I);
          End;
          2 : VS(fEbp, VmFont14O);
          3 : VS(fEbp, VmFont8O);
          4 : VS(fEbp, VmFont8H);
          6 : VS(fEbp, VmFontO);
        Else
          VS(fEbp, VmFuncO + 15);
        End;
        VS(fEcx, MemW[0:VmBda($85)]);
        VSL(fEdx, Mem[0:VmBda($84)]);
      End;
    $12 :
      Case VRL(fEbx) Of
        $10 :
        Begin
          VS(fEbx, $0003);
          VS(fEcx, $0009);
        End;
        $30..$36 : VSL(fEax, $12);
      End;
    $13 :
      VmWriteStr(VRH(fEbx) And 7, AL, VRL(fEbx), VR(fEcx), VRL(fEdx),
                 VRH(fEdx), VmPtr(fEs, fEbp));
    $1A :
      If AL = 0 Then
      Begin
        VSL(fEax, $1A);
        VS(fEbx, $0008);
      End
      Else VSL(fEax, $1A);
    $1B :
    Begin
      P := VmPtr(fEs, fEdi);
      FillMem(P, 64, 0);
      MemW[0:P] := VmFuncO; MemW[0:P + 2] := VmBios;
      Mem[0:P + 4] := Mem[0:VmBda($49)];
      MemW[0:P + 5] := MemW[0:VmBda($4A)];
      MemW[0:P + 7] := MemW[0:VmBda($4C)];
      MemW[0:P + 9] := MemW[0:VmBda($4E)];
      MoveMem(VmBda($50), P + $0B, 16);
      Mem[0:P + $1B] := Mem[0:VmBda($60)];
      Mem[0:P + $1C] := Mem[0:VmBda($61)];
      Mem[0:P + $1D] := VmPage;
      MemW[0:P + $1E] := $3D4;
      Mem[0:P + $22] := 25;
      MemW[0:P + $23] := 16;
      Mem[0:P + $25] := 8;
      MemW[0:P + $27] := 16;
      Mem[0:P + $29] := 8;
      Mem[0:P + $2A] := 2;
      Mem[0:P + $2D] := $20 * Ord(Not VmBlink);
      Mem[0:P + $31] := 3;
      VSL(fEax, $1B);
    End;
  End;
End;

{ ------------------------------------------------------------------ }
{ BIOS : horloge, systeme, disques, imprimante                       }
{ ------------------------------------------------------------------ }

Function VmToBcd(V : LongInt) : LongInt;
Begin
  VmToBcd := ((V Div 10) Shl 4) Or (V Mod 10);
End;

Procedure VmInt1A;
Begin
  VmSetCF(False);
  Case VRH(fEax) Of
    $00 :
    Begin
      VmPumpNative;
      VS(fEcx, MemL[0:VmBda($6C)] Shr 16);
      VS(fEdx, MemL[0:VmBda($6C)]);
      VSL(fEax, Mem[0:VmBda($70)]);
      Mem[0:VmBda($70)] := 0;
    End;
    $01 : MemL[0:VmBda($6C)] := (VR(fEcx) Shl 16) Or VR(fEdx);
    $02 :
    Begin
      ReadRtc;
      VS(fEcx, (VmToBcd(RtcHour) Shl 8) Or VmToBcd(RtcMin));
      VS(fEdx, VmToBcd(RtcSec) Shl 8);
    End;
    $04 :
    Begin
      ReadRtc;
      VS(fEcx, (VmToBcd(RtcYear Div 100) Shl 8) Or VmToBcd(RtcYear Mod 100));
      VS(fEdx, (VmToBcd(RtcMonth) Shl 8) Or VmToBcd(RtcDay));
    End;
    $03, $05, $06, $07 : ;
  Else
    VmSetCF(True);
  End;
End;

Procedure VmInt15;
Var AH, Us : LongInt;
Begin
  AH := VRH(fEax);
  VmSetCF(False);
  Case AH Of
    $C0 :
    Begin
      VSeg(fEs, VmBios);
      VS(fEbx, VmCfgO);
      VSH(fEax, 0);
    End;
    $88 : VS(fEax, 0);
    $86 :
    Begin
      Us := (VR(fEcx) Shl 16) Or VR(fEdx);
      If Us >= 1000 Then VmSleep(Us Div 1000);
      VSH(fEax, 0);
    End;
    $4F : VmSetCF(True);
    $90, $91 : VSH(fEax, 0);
  Else
    VSH(fEax, $86);
    VmSetCF(True);
  End;
End;

Procedure VmInt13;
Begin
  If VRH(fEax) = 0 Then
  Begin
    VmSetCF(False);
    VSH(fEax, 0);
  End
  Else If VRH(fEax) = $15 Then
  Begin
    VmSetCF(False);
    VSH(fEax, 0);
  End
  Else
  Begin
    VmSetCF(True);
    VSH(fEax, 1);
  End;
End;

{ ------------------------------------------------------------------ }

{ DOS : blocs de memoire (MCB)                                       }
{ ------------------------------------------------------------------ }
{ MCB : +0 'M' ou 'Z' (dernier), +1 proprietaire (PSP, 0 libre),
  +3 taille en paragraphes, +8 nom du programme }

Function McbA(Seg : LongInt) : LongInt;
Begin
  McbA := VmRam + Seg * 16;
End;

{ Reunir les blocs libres qui suivent le bloc M }
Procedure McbMerge(M : LongInt);
Var N : LongInt;
Begin
  While Mem[0:McbA(M)] = Ord('M') Do
  Begin
    N := M + 1 + MemW[0:McbA(M) + 3];
    If (N >= $A000) Or (MemW[0:McbA(N) + 1] <> 0) Then Exit;
    If Not (Mem[0:McbA(N)] In [Ord('M'), Ord('Z')]) Then Exit;
    Mem[0:McbA(M)] := Mem[0:McbA(N)];
    MemW[0:McbA(M) + 3] := MemW[0:McbA(M) + 3] + 1 + MemW[0:McbA(N) + 3];
  End;
End;

{ Couper le bloc M a Paras paragraphes (le reste devient libre) }
Procedure McbSplit(M, Paras : LongInt);
Var Sz, N : LongInt;
Begin
  Sz := MemW[0:McbA(M) + 3];
  If Sz <= Paras Then Exit;
  N := M + 1 + Paras;
  Mem[0:McbA(N)] := Mem[0:McbA(M)];
  MemW[0:McbA(N) + 1] := 0;
  MemW[0:McbA(N) + 3] := Sz - Paras - 1;
  FillMem(McbA(N) + 5, 11, 0);
  Mem[0:McbA(M)] := Ord('M');
  MemW[0:McbA(M) + 3] := Paras;
  McbMerge(N);
End;

{ Allouer Paras paragraphes ; segment du bloc (0 : echec, Max = plus
  grand bloc libre) }
Function McbAlloc(Paras, Owner : LongInt; Var Max : LongInt) : LongInt;
Var M, Sz, Best, BestSz : LongInt;
Begin
  McbAlloc := 0;
  Max := 0;
  M := VmFirstMcb;
  Best := 0; BestSz := 0;
  Repeat
    If Not (Mem[0:McbA(M)] In [Ord('M'), Ord('Z')]) Then Exit;
    If MemW[0:McbA(M) + 1] = 0 Then
    Begin
      McbMerge(M);
      Sz := MemW[0:McbA(M) + 3];
      If Sz > Max Then Max := Sz;
      If (Sz >= Paras) And ((Best = 0) Or ((VmStrat And 3) = 2) Or
         (((VmStrat And 3) = 1) And (Sz < BestSz))) Then
      Begin
        Best := M; BestSz := Sz;
      End;
    End;
    If Mem[0:McbA(M)] = Ord('Z') Then Break;
    M := M + 1 + MemW[0:McbA(M) + 3];
  Until M >= $A000;
  If Best = 0 Then Exit;
  If (VmStrat And 3) = 2 Then
  Begin
    { dernier bloc : la fin du bloc libre }
    If BestSz > Paras Then
    Begin
      McbSplit(Best, BestSz - Paras - 1);
      Best := Best + BestSz - Paras;
    End;
  End
  Else McbSplit(Best, Paras);
  MemW[0:McbA(Best) + 1] := Owner;
  McbAlloc := Best + 1;
End;

Function McbValid(Seg : LongInt) : Boolean;
Begin
  McbValid := (Seg > VmFirstMcb) And (Seg < $A000) And
              (Mem[0:McbA(Seg - 1)] In [Ord('M'), Ord('Z')]);
End;

Procedure McbFree(Seg : LongInt);
Begin
  If McbValid(Seg) Then MemW[0:McbA(Seg - 1) + 1] := 0;
End;

{ Redimensionner le bloc Seg ; False (Max = taille possible) }
Function McbResize(Seg, Paras : LongInt; Var Max : LongInt) : Boolean;
Var M, Own : LongInt;
Begin
  McbResize := False;
  Max := 0;
  If Not McbValid(Seg) Then Exit;
  M := Seg - 1;
  Own := MemW[0:McbA(M) + 1];
  MemW[0:McbA(M) + 1] := 0;
  McbMerge(M);
  MemW[0:McbA(M) + 1] := Own;
  Max := MemW[0:McbA(M) + 3];
  If Max < Paras Then Exit;
  McbSplit(M, Paras);
  McbResize := True;
End;

Procedure McbFreeOwner(Owner : LongInt);
Var M : LongInt;
Begin
  M := VmFirstMcb;
  Repeat
    If Not (Mem[0:McbA(M)] In [Ord('M'), Ord('Z')]) Then Exit;
    If MemW[0:McbA(M) + 1] = Owner Then MemW[0:McbA(M) + 1] := 0;
    If Mem[0:McbA(M)] = Ord('Z') Then Exit;
    M := M + 1 + MemW[0:McbA(M) + 3];
  Until M >= $A000;
End;

{ ------------------------------------------------------------------ }
{ DOS : chemins, fichiers et poignees                                }
{ ------------------------------------------------------------------ }

Function VmDriveOk(D : LongInt) : Boolean;
Begin
  VmDriveOk := (D >= 0) And (D < 26) And
               ((GetLogicalDrives And (1 Shl D)) <> 0);
End;

{ Chemin complet (X:\...) d'un nom DOS }
Function VmFullPath(S : String) : String;
Var D, P : LongInt; R, Part : String;
Begin
  S := UpStr(Trim(S));
  For P := 1 To Length(S) Do If S[P] = '/' Then S[P] := '\';
  D := VmDrive;
  If (Length(S) >= 2) And (S[2] = ':') Then
  Begin
    D := Ord(S[1]) - 65;
    S := Copy(S, 3, 255);
  End;
  If (D < 0) Or (D > 25) Then D := VmDrive;
  If (S = '') Or (S[1] <> '\') Then S := VmDir[D] + '\' + S;
  R := '';
  While S <> '' Do
  Begin
    While (Length(S) > 0) And (S[1] = '\') Do S := Copy(S, 2, 255);
    If S = '' Then Break;
    P := Pos('\', S);
    If P > 0 Then
    Begin
      Part := Copy(S, 1, P - 1);
      S := Copy(S, P + 1, 255);
    End
    Else
    Begin
      Part := S;
      S := '';
    End;
    While (Length(Part) > 0) And (Part[Length(Part)] = ' ') Do
      Part := Copy(Part, 1, Length(Part) - 1);
    If (Part = '.') Or (Part = '') Then Continue;
    If Part = '..' Then
    Begin
      P := Length(R);
      While (P > 0) And (R[P] <> '\') Do Dec(P);
      R := Copy(R, 1, P - 1);
      If P = 0 Then R := '';
      Continue;
    End;
    R := R + '\' + Part;
  End;
  If R = '' Then R := '\';
  VmFullPath := Chr(65 + D) + ':' + R;
End;

{ Chaine ASCIIZ de la machine -> chemin complet ; ecrit aussi en
  ASCIIZ dans VmTmp + K }
Function VmPathAt(Lin, K : LongInt) : String;
Var S : String;
Begin
  S := VmFullPath(PStr(Lin));
  PutPStr(VmTmp + K, S, 256);
  VmPathAt := S;
End;

{ Nom de peripherique (CON, NUL...) : 0 aucun, 1 CON, 2 NUL et
  autres, 3 inconnu du systeme (EMMXXXX0...) }
Function VmDevName(Path : String) : LongInt;
Var B : String; P : LongInt;
Begin
  B := BaseName(Path);
  P := Pos('.', B);
  If P > 0 Then B := Copy(B, 1, P - 1);
  VmDevName := 0;
  If B = 'CON' Then VmDevName := 1
  Else If (B = 'NUL') Or (B = 'PRN') Or (B = 'AUX') Or (B = 'LPT1') Or
     (B = 'LPT2') Or (B = 'LPT3') Or (B = 'COM1') Or (B = 'COM2') Or
     (B = 'COM3') Or (B = 'COM4') Or (B = 'CLOCK$') Then VmDevName := 2
  Else If (B = 'EMMXXXX0') Or (B = 'EMMQXXX0') Or (B = 'XMSXXXX0') Then
    VmDevName := 2
  Else If B = '$MMXXXX0' Then VmDevName := 3;
End;

Function SftNew(H, Dev, Mode : LongInt) : LongInt;
Var I : LongInt;
Begin
  SftNew := -1;
  For I := 0 To VmMaxSft - 1 Do
    If SftRef[I] = 0 Then
    Begin
      SftH[I] := H; SftDev[I] := Dev; SftMode[I] := Mode;
      SftRef[I] := 1;
      SftNew := I;
      Exit;
    End;
  If Dev = 0 Then CloseHandle(H);
End;

Procedure SftRelease(S : LongInt);
Begin
  If (S < 0) Or (S >= VmMaxSft) Or (SftRef[S] <= 0) Then Exit;
  Dec(SftRef[S]);
  If (SftRef[S] = 0) And (SftDev[S] = 0) Then CloseHandle(SftH[S]);
End;

{ Table des fichiers du processus (JFT) : adresse de l'entree H }
Function VmJft(H : LongInt) : LongInt;
Var P : LongInt;
Begin
  VmJft := 0;
  P := VmLin(VmCurPsp, 0);
  If (H < 0) Or (H >= MemW[0:P + $32]) Then Exit;
  VmJft := VmLin(MemW[0:P + $36], MemW[0:P + $34] + H);
End;

Function VmSftOf(H : LongInt) : LongInt;
Var J : LongInt;
Begin
  VmSftOf := -1;
  J := VmJft(H And $FFFF);
  If J = 0 Then Exit;
  If (Mem[0:J] = $FF) Or (Mem[0:J] >= VmMaxSft) Then Exit;
  If SftRef[Mem[0:J]] <= 0 Then Exit;
  VmSftOf := Mem[0:J];
End;

{ Nouvelle poignee du processus pour l'entree S ; -1 : plus de place }
Function VmHNew(S : LongInt) : LongInt;
Var I, P, N : LongInt;
Begin
  VmHNew := -1;
  P := VmLin(VmCurPsp, 0);
  N := MemW[0:P + $32];
  For I := 0 To N - 1 Do
    If Mem[0:VmJft(I)] = $FF Then
    Begin
      Mem[0:VmJft(I)] := S;
      VmHNew := I;
      Exit;
    End;
End;

Procedure VmHClose(H : LongInt);
Var J : LongInt;
Begin
  J := VmJft(H);
  If J = 0 Then Exit;
  If Mem[0:J] <> $FF Then SftRelease(Mem[0:J]);
  Mem[0:J] := $FF;
End;

{ Erreur Win32 du noyau -> code d'erreur du DOS }
Function VmErrOf(Def : LongInt) : LongInt;
Var E : LongInt;
Begin
  E := LastError;
  Case E Of
    2, 3, 4, 5, 6, 8, 15, 16, 17, 18, 32, 80 : ;
    183 : E := 80;
    145 : E := 5;
  Else
    E := Def;
  End;
  VmErrOf := E;
End;

Procedure VmFail(E : LongInt);
Begin
  VmLastErr := E;
  VS(fEax, E);
  VmSetCF(True);
End;

{ Ouvrir un fichier (Disp de CreateFile) ; entree de la table ou -1
  (VmLastErr) }
Function VmOpen(Path : String; Mode, Disp : LongInt) : LongInt;
Var D, H, S : LongInt; Wr : Boolean;
Begin
  VmOpen := -1;
  D := VmDevName(Path);
  If D = 3 Then
  Begin
    VmLastErr := 2;
    Exit;
  End;
  If D > 0 Then
  Begin
    S := SftNew(0, D, Mode);
    VmOpen := S;
    If S < 0 Then VmLastErr := 4;
    Exit;
  End;
  Wr := ((Mode And 3) <> 0) Or (Disp <> 3);
  H := KOpenFile(Path, Wr, Disp);
  If (H = INVALID_HANDLE) And ((Mode And 3) = 2) And (Disp = 3) Then
  Begin
    { lecture et ecriture refusees (CD-ROM...) : lecture seule }
    H := KOpenFile(Path, False, 3);
    If H <> INVALID_HANDLE Then Mode := Mode And Not 3;
  End;
  If H = INVALID_HANDLE Then
  Begin
    VmLastErr := VmErrOf(2);
    Exit;
  End;
  S := SftNew(H, 0, Mode);
  VmOpen := S;
  If S < 0 Then VmLastErr := 4;
End;

Procedure VmOpenH(Path : String; Mode, Disp : LongInt);
Var S, H : LongInt;
Begin
  S := VmOpen(Path, Mode, Disp);
  If S < 0 Then
  Begin
    VmFail(VmLastErr);
    Exit;
  End;
  If (Mode And $80) <> 0 Then SftMode[S] := SftMode[S] Or $80;
  H := VmHNew(S);
  If H < 0 Then
  Begin
    SftRelease(S);
    VmFail(4);
    Exit;
  End;
  VS(fEax, H);
End;

{ ------------------------------------------------------------------ }
{ DOS : console                                                      }
{ ------------------------------------------------------------------ }

{ Ligne frappee au clavier avec echo (au plus Max caracteres) }
Function VmReadLine(Max : LongInt) : String;
Var S : String; K, C : LongInt;
Begin
  S := '';
  Repeat
    K := VmWaitKey;
    C := K And $FF;
    If C = 13 Then Break;
    If C = 8 Then
    Begin
      If Length(S) > 0 Then
      Begin
        S := Copy(S, 1, Length(S) - 1);
        VmTty(8); VmTty(32); VmTty(8);
      End;
    End
    Else If C = 27 Then
    Begin
      While Length(S) > 0 Do
      Begin
        S := Copy(S, 1, Length(S) - 1);
        VmTty(8); VmTty(32); VmTty(8);
      End;
    End
    Else If (C <> 0) And (C <> $E0) And (Length(S) < Max) Then
    Begin
      S := S + Chr(C);
      VmConOut(C);
    End;
  Until False;
  VmTty(13);
  VmReadLine := S;
End;

{ Lecture de CON (mode ligne) : N octets au plus }
Function VmConRead(Buf, N : LongInt) : LongInt;
Var I : LongInt;
Begin
  If Not VmLineOk Then
  Begin
    VmLine := VmReadLine(126) + #13#10;
    VmTty(10);
    VmLineOk := True;
  End;
  I := 0;
  While (I < N) And (VmLine <> '') Do
  Begin
    Mem[0:Buf + I] := Ord(VmLine[1]);
    VmLine := Copy(VmLine, 2, 255);
    Inc(I);
  End;
  If VmLine = '' Then VmLineOk := False;
  VmConRead := I;
End;

{ Lecture d'un caractere (AH=01h, 07h, 08h) }
Function VmGetCh : LongInt;
Var K : LongInt;
Begin
  If VmPendScan >= 0 Then
  Begin
    VmGetCh := VmPendScan;
    VmPendScan := -1;
    Exit;
  End;
  K := VmWaitKey;
  If ((K And $FF) = 0) Or (((K And $FF) = $E0) And (K > $FF)) Then
  Begin
    VmPendScan := K Shr 8;
    VmGetCh := 0;
  End
  Else VmGetCh := K And $FF;
End;

{ ------------------------------------------------------------------ }
{ DOS : PSP, chargement et fin des programmes                        }
{ ------------------------------------------------------------------ }

{ FCB non ouvert depuis le debut de la chaine S (nom de fichier) }
Procedure VmFcbName(F : LongInt; Var S : String);
Var I, K : LongInt;
Begin
  FillMem(F + 1, 11, 32);
  Mem[0:F] := 0;
  While (S <> '') And (S[1] In [' ', #9, ',', ';', '=']) Do S := Copy(S, 2, 255);
  If (Length(S) >= 2) And (S[2] = ':') Then
  Begin
    Mem[0:F] := Ord(UpCase(S[1])) - 64;
    S := Copy(S, 3, 255);
  End;
  I := 0; K := 0;
  While (S <> '') And Not (S[1] In [' ', #9, ',', ';', '=', '/', '\',
        #13]) Do
  Begin
    If S[1] = '.' Then K := 8
    Else If S[1] = '*' Then
    Begin
      If K < 8 Then While K < 8 Do
      Begin
        Mem[0:F + 1 + K] := Ord('?'); Inc(K);
      End
      Else While K < 11 Do
      Begin
        Mem[0:F + 1 + K] := Ord('?'); Inc(K);
      End;
    End
    Else If ((K < 8) And (S[1] <> '.')) Or ((K >= 8) And (K < 11)) Then
    Begin
      Mem[0:F + 1 + K] := Ord(UpCase(S[1]));
      Inc(K);
    End;
    S := Copy(S, 2, 255);
    Inc(I);
  End;
End;

{ Construire le PSP de Seg (bloc de Size paragraphes) }
Procedure VmMakePsp(Seg, Size, Env, Parent : LongInt; Tail : String);
Var P, PP, I, S, N : LongInt; T : String;
Begin
  P := VmLin(Seg, 0);
  FillMem(P, 256, 0);
  MemW[0:P] := $20CD;
  MemW[0:P + 2] := Seg + Size;
  Mem[0:P + 5] := $9A;
  MemW[0:P + 6] := VmCpmO; MemW[0:P + 8] := VmBios;
  MemL[0:P + $0A] := MemL[0:VmRam + $22 * 4];
  MemL[0:P + $0E] := MemL[0:VmRam + $23 * 4];
  MemL[0:P + $12] := MemL[0:VmRam + $24 * 4];
  MemW[0:P + $16] := Parent;
  FillMem(P + $18, 20, $FF);
  { fichiers herites du parent }
  If Parent <> 0 Then
  Begin
    PP := VmLin(Parent, 0);
    N := Min(20, MemW[0:PP + $32]);
    For I := 0 To N - 1 Do
    Begin
      S := Mem[0:VmLin(MemW[0:PP + $36], MemW[0:PP + $34] + I)];
      If (S < VmMaxSft) And (SftRef[S] > 0) And
         ((SftMode[S] And $80) = 0) Then
      Begin
        Mem[0:P + $18 + I] := S;
        Inc(SftRef[S]);
      End;
    End;
  End;
  MemW[0:P + $2C] := Env;
  MemW[0:P + $32] := 20;
  MemW[0:P + $34] := $18; MemW[0:P + $36] := Seg;
  MemL[0:P + $38] := -1;
  MemW[0:P + $40] := $0007;
  Mem[0:P + $50] := $CD; Mem[0:P + $51] := $21; Mem[0:P + $52] := $CB;
  If Length(Tail) > 126 Then Tail := Copy(Tail, 1, 126);
  T := Tail;
  VmFcbName(P + $5C, T);
  VmFcbName(P + $6C, T);
  Mem[0:P + $80] := Length(Tail);
  For I := 1 To Length(Tail) Do Mem[0:P + $80 + I] := Ord(Tail[I]);
  Mem[0:P + $81 + Length(Tail)] := 13;
End;

{ Taille (octets) des variables d'un environnement }
Function VmEnvLen(Seg : LongInt) : LongInt;
Var A, N : LongInt;
Begin
  A := VmLin(Seg, 0);
  N := 0;
  While (N < 32000) And Not ((Mem[0:A + N] = 0) And
        ((N = 0) Or (Mem[0:A + N - 1] = 0))) Do Inc(N);
  If N = 0 Then N := 1 Else N := N + 1;
  VmEnvLen := N;
End;

{ Charger le programme Path (EXEC) ; 0 ou code d'erreur du DOS.
  Mode 3 (recouvrement) : LoadSeg et Reloc ; sinon un PSP est cree. }
Function VmLoad(Path, Tail : String; EnvSeg, Mode, LoadSeg, Reloc : LongInt;
                Var Psp, Cs, Ip, Ss, Sp : LongInt) : LongInt;
Var H, Got, I, N, Hdr, Img, MinA, MaxA, Need, Want, Max, Seg, Env,
    EnvN, Base, R, A, FSize : LongInt; Exe, Sh : Boolean; Nm : String;
Begin
  VmLoad := 2;
  Psp := 0;
  H := KOpenFile(Path, False, 3);
  { pas de COMMAND.COM : l'interpreteur integre }
  Sh := (H = INVALID_HANDLE) And (Mode <> 3) And
        (UpStr(BaseName(Path)) = 'COMMAND.COM');
  If (H = INVALID_HANDLE) And Not Sh Then
  Begin
    VmLoad := VmErrOf(2);
    Exit;
  End;
  FillMem(VmTmp, 64, 0);
  Got := 0;
  If Sh Then FSize := 16
  Else
  Begin
    FSize := GetFileSize(H, 0);
    KReadFile(H, VmTmp, 32, Got);
  End;
  Exe := (Got >= 28) And ((MemW[0:VmTmp] = $5A4D) Or
                          (MemW[0:VmTmp] = $4D5A));
  If Exe Then
  Begin
    Hdr := MemW[0:VmTmp + 8] * 16;
    Img := MemW[0:VmTmp + 4] * 512;
    If MemW[0:VmTmp + 2] <> 0 Then Img := Img - 512 + MemW[0:VmTmp + 2];
    Img := Img - Hdr;
    If Img > FSize - Hdr Then Img := FSize - Hdr;
    MinA := MemW[0:VmTmp + 10];
    MaxA := MemW[0:VmTmp + 12];
    If (MinA = 0) And (MaxA = 0) Then MaxA := $FFFF;
  End
  Else
  Begin
    Hdr := 0;
    Img := FSize;
    If Img > $FF00 Then
    Begin
      If Not Sh Then CloseHandle(H);
      VmLoad := 11;
      Exit;
    End;
    MinA := $1000 - ((Img + 15) Shr 4);
    MaxA := $FFFF;
    If Sh Then
    Begin
      MinA := $F0; MaxA := $F0;
    End;
  End;
  If Img < 0 Then
  Begin
    If Not Sh Then CloseHandle(H);
    VmLoad := 11;
    Exit;
  End;
  { recouvrement : chargement sans PSP }
  If Mode = 3 Then
  Begin
    Base := LoadSeg;
    R := Reloc;
  End
  Else
  Begin
    { environnement : variables, mot 1, nom complet du programme }
    If EnvSeg = 0 Then EnvSeg := MemW[0:VmLin(VmCurPsp, $2C)];
    EnvN := VmEnvLen(EnvSeg);
    Env := McbAlloc((EnvN + 3 + Length(Path) + 15) Shr 4, 1, Max);
    If Env = 0 Then
    Begin
      If Not Sh Then CloseHandle(H);
      VmLoad := 8;
      Exit;
    End;
    MoveMem(VmLin(EnvSeg, 0), VmLin(Env, 0), EnvN);
    MemW[0:VmLin(Env, EnvN)] := 1;
    PutPStr(VmLin(Env, EnvN + 2), Path, 128);
    { bloc du programme : le plus grand possible, au plus MaxAlloc }
    Need := ((Img + 15) Shr 4) + $10 + MinA;
    Want := ((Img + 15) Shr 4) + $10 + MaxA;
    If Want > $FFFF Then Want := $FFFF;
    McbAlloc($FFFF, 0, Max);
    If Max < Need Then
    Begin
      McbFree(Env);
      If Not Sh Then CloseHandle(H);
      VmLoad := 8;
      Exit;
    End;
    If Want > Max Then Want := Max;
    Seg := McbAlloc(Want, 1, Max);
    If Seg = 0 Then
    Begin
      McbFree(Env);
      If Not Sh Then CloseHandle(H);
      VmLoad := 8;
      Exit;
    End;
    MemW[0:McbA(Seg - 1) + 1] := Seg;
    MemW[0:McbA(Env - 1) + 1] := Seg;
    Nm := BaseName(Path);
    If Pos('.', Nm) > 0 Then Nm := Copy(Nm, 1, Pos('.', Nm) - 1);
    FillMem(McbA(Seg - 1) + 8, 8, 0);
    For I := 1 To Min(8, Length(Nm)) Do
      Mem[0:McbA(Seg - 1) + 7 + I] := Ord(Nm[I]);
    VmMakePsp(Seg, Want, Env, VmCurPsp, Tail);
    Psp := Seg;
    If Exe Then Base := Seg + $10 Else Base := Seg;
    R := Base;
  End;
  { image }
  If Exe Then
  Begin
    SetFilePointer(H, Hdr, 0, 0);
    KReadFile(H, VmLin(Base, 0), Img, Got);
    N := MemW[0:VmTmp + 6];
    If N > 0 Then
    Begin
      I := VmHeapOwn; VmHeapOwn := 0;
      A := VmKAlloc(N * 4);
      VmHeapOwn := I;
      If A <> 0 Then
      Begin
        SetFilePointer(H, MemW[0:VmTmp + $18], 0, 0);
        KReadFile(H, A, N * 4, Got);
        For I := 0 To N - 1 Do
          VmPutW(Base + MemW[0:A + I * 4 + 2], MemW[0:A + I * 4],
                 VmGetW(Base + MemW[0:A + I * 4 + 2], MemW[0:A + I * 4]) +
                 R);
        VmKFree(A);
      End;
    End;
    Cs := (Base + MemW[0:VmTmp + $16]) And $FFFF;
    Ip := MemW[0:VmTmp + $14];
    Ss := (Base + MemW[0:VmTmp + $0E]) And $FFFF;
    Sp := MemW[0:VmTmp + $10];
  End
  Else
  Begin
    If Sh Then
    Begin
      { HLT ; INT 21h ; JMP 100h ; signature ; mode (1 : /C) }
      A := VmLin(Base, $100);
      MemL[0:A] := $EB21CDF4; Mem[0:A + 4] := $FB;
      MemL[0:A + 5] := ShSig;
      Nm := UpStr(Trim(Tail));
      Mem[0:A + $10] := Ord(Copy(Nm, 1, 2) = '/C');
      Mem[0:A + $11] := 0;
    End
    Else
    Begin
      SetFilePointer(H, 0, 0, 0);
      If Mode = 3 Then KReadFile(H, VmLin(Base, 0), Img, Got)
      Else KReadFile(H, VmLin(Base, $100), Img, Got);
    End;
    Cs := Base; Ip := $100; Ss := Base;
    If Mode <> 3 Then
    Begin
      If MemW[0:VmLin(Psp, 2)] - Psp >= $1000 Then Sp := $FFFE
      Else Sp := (MemW[0:VmLin(Psp, 2)] - Psp) * 16 - 2;
      VmPutW(Ss, Sp, 0);
    End;
  End;
  If Not Sh Then CloseHandle(H);
  VmLoad := 0;
End;

{ Registres de l'appelant de l'INT 21h sauves sous sa pile ; le PSP
  courant garde SS:SP (comme MS-DOS, pour le retour d'un EXEC) }
Procedure VmDosSave;
Var Ss, Sp, P : LongInt;
Begin
  Ss := VR(fSs); Sp := (VR(fEsp) - 18) And $FFFF;
  VmPutW(Ss, Sp, VR(fEs));
  VmPutW(Ss, Sp + 2, VR(fDs));
  VmPutW(Ss, Sp + 4, VR(fEbp));
  VmPutW(Ss, Sp + 6, VR(fEdi));
  VmPutW(Ss, Sp + 8, VR(fEsi));
  VmPutW(Ss, Sp + 10, VR(fEdx));
  VmPutW(Ss, Sp + 12, VR(fEcx));
  VmPutW(Ss, Sp + 14, VR(fEbx));
  VmPutW(Ss, Sp + 16, VR(fEax));
  P := VmLin(VmCurPsp, 0);
  MemW[0:P + $2E] := Sp;
  MemW[0:P + $30] := Ss;
End;

{ Fin du programme courant (AH=4Ch, 31h, INT 20h, 27h) }
Procedure DpEnd; Forward;

Procedure VmTerminate(Code : LongInt; Tsr : Boolean; Keep : LongInt);
Var Child, Parent, P, I, Ss, Sp, Max : LongInt;
Begin
  { client DPMI : retour au mode reel }
  If VmDpmi And (VmCurPsp = VmDpmiPsp) And Not Tsr Then DpEnd;
  VmPM := False;
  VSeg(fFs, 0); VSeg(fGs, 0);
  Child := VmCurPsp;
  P := VmLin(Child, 0);
  Parent := MemW[0:P + $16];
  VmRetCode := Code And $FF;
  If Tsr Then VmRetCode := VmRetCode Or $300;
  MemL[0:VmRam + $22 * 4] := MemL[0:P + $0A];
  MemL[0:VmRam + $23 * 4] := MemL[0:P + $0E];
  MemL[0:VmRam + $24 * 4] := MemL[0:P + $12];
  If Tsr Then
  Begin
    If Keep < 6 Then Keep := 6;
    McbResize(Child, Keep, Max);
  End
  Else
  Begin
    For I := 0 To MemW[0:P + $32] - 1 Do VmHClose(I);
    McbFreeOwner(Child);
  End;
  If (Parent = VmRootPsp) Or (Parent = Child) Or (Parent = 0) Then
    VmQuit(Code And $FF);
  VmCurPsp := Parent;
  VmDta := (Parent Shl 16) Or $80; VmDtaPM := False;
  { pile du parent sauvee a son dernier appel du DOS }
  P := VmLin(Parent, 0);
  Ss := MemW[0:P + $30]; Sp := MemW[0:P + $2E];
  VSeg(fSs, Ss);
  VSeg(fEs, VmGetW(Ss, Sp));
  VSeg(fDs, VmGetW(Ss, Sp + 2));
  VS(fEbp, VmGetW(Ss, Sp + 4));
  VS(fEdi, VmGetW(Ss, Sp + 6));
  VS(fEsi, VmGetW(Ss, Sp + 8));
  VS(fEdx, VmGetW(Ss, Sp + 10));
  VS(fEcx, VmGetW(Ss, Sp + 12));
  VS(fEbx, VmGetW(Ss, Sp + 14));
  VS(fEax, VmGetW(Ss, Sp + 16));
  VS(fEsp, Sp + 18 + 6);
  VmLoadFlags(VmGetW(Ss, Sp + 22) Or $200);
  I := MemL[0:VmLin(Child, $0A)];
  VmGoto(I Shr 16, I And $FFFF);
  VmSetCF(False);
  VmNoIret := True;
End;

{ AH=4Bh : EXEC }
Procedure VmExec;
Var AL, Pb, Err, Psp, Cs, Ip, Ss, Sp, T, I : LongInt; Path, Tail : String;
Begin
  AL := VRL(fEax);
  Path := VmFullPath(PStr(VmPtr(fDs, fEdx)));
  Pb := VmPtr(fEs, fEbx);
  If AL = 3 Then
  Begin
    Err := VmLoad(Path, '', 0, 3, MemW[0:Pb], MemW[0:Pb + 2], Psp, Cs, Ip,
                  Ss, Sp);
    If Err <> 0 Then VmFail(Err) Else VmSetCF(False);
    Exit;
  End;
  If (AL <> 0) And (AL <> 1) Then
  Begin
    VmFail(1);
    Exit;
  End;
  T := MemL[0:Pb + 2];
  T := VmLin(T Shr 16, T And $FFFF);
  Tail := '';
  For I := 1 To Mem[0:T] Do
    If Mem[0:T + I] <> 13 Then Tail := Tail + Chr(Mem[0:T + I]);
  Err := VmLoad(Path, Tail, MemW[0:Pb], AL, 0, 0, Psp, Cs, Ip, Ss, Sp);
  If Err <> 0 Then
  Begin
    VmFail(Err);
    Exit;
  End;
  { FCB fournis par l'appelant }
  T := MemL[0:Pb + 6];
  If (T <> 0) And (T <> -1) Then
    MoveMem(VmLin(T Shr 16, T And $FFFF), VmLin(Psp, $5C), 16);
  T := MemL[0:Pb + 10];
  If (T <> 0) And (T <> -1) Then
    MoveMem(VmLin(T Shr 16, T And $FFFF), VmLin(Psp, $6C), 16);
  { retour au parent : l'instruction qui suit son INT 21h }
  I := (VmGetW(VR(fSs), VR(fEsp) + 2) Shl 16) Or VmGetW(VR(fSs), VR(fEsp));
  MemL[0:VmLin(Psp, $0A)] := I;
  MemL[0:VmRam + $22 * 4] := I;
  VmCurPsp := Psp;
  VmDta := (Psp Shl 16) Or $80; VmDtaPM := False;
  If AL = 1 Then
  Begin
    Sp := (Sp - 2) And $FFFF;
    VmPutW(Ss, Sp, 0);
    MemW[0:Pb + $0E] := Sp; MemW[0:Pb + $10] := Ss;
    MemW[0:Pb + $12] := Ip; MemW[0:Pb + $14] := Cs;
    VmSetCF(False);
    Exit;
  End;
  VSeg(fSs, Ss); VS(fEsp, Sp);
  VSeg(fDs, Psp); VSeg(fEs, Psp);
  VS(fEax, 0); VS(fEbx, 0); VS(fEcx, $FF); VS(fEdx, Psp);
  VS(fEsi, Ip); VS(fEdi, Sp); VS(fEbp, $091C);
  VmGoto(Cs, Ip);
  VmIF := True;
  VmSetCF(False);
  VmNoIret := True;
End;

{ ------------------------------------------------------------------ }
{ DOS : recherche des fichiers (AH=4Eh, 4Fh)                          }
{ ------------------------------------------------------------------ }
{ DTA : +0 'P', +1 recherche, +2 numero, +12 attributs demandes ;
  +15h attributs, +16h heure, +18h date, +1Ah taille, +1Eh nom }

Procedure VmFindStep(Dta : LongInt; First : Boolean);
Var H, K, Fd, Ok, A, Mask, D, T : LongInt; S : String;
Begin
  Fd := VmTmp + 512;
  If First Then
  Begin
    Mask := VR(fEcx) And $FF;
    If Mask = 8 Then
    Begin
      VmFail(18);
      Exit;
    End;
    S := VmPathAt(VmPtr(fDs, fEdx), 0);
    H := FindFirstFileA(VmTmp, Fd);
    If H = INVALID_HANDLE Then
    Begin
      { aucun fichier : 12h si le repertoire existe, sinon 03h }
      PutPStr(VmTmp + 256, ParentDir(S), 256);
      If (Length(ParentDir(S)) = 3) Or
         ((GetFileAttributesA(VmTmp + 256) <> -1) And
          ((GetFileAttributesA(VmTmp + 256) And $10) <> 0)) Then
        VmFail(18)
      Else VmFail(3);
      Exit;
    End;
    { une recherche par entree de la table ; la plus ancienne est
      fermee quand la table est pleine }
    K := VmFindNext;
    VmFindNext := (VmFindNext + 1) Mod VmMaxFind;
    If VmFindH[K] <> 0 Then FindClose(VmFindH[K]);
    Inc(VmFindCnt);
    VmFindH[K] := H; VmFindSeq[K] := VmFindCnt And $FFFF;
    Mem[0:Dta] := Ord('P'); Mem[0:Dta + 1] := K;
    MemW[0:Dta + 2] := VmFindSeq[K];
    Mem[0:Dta + 12] := Mask;
    Ok := 1;
  End
  Else
  Begin
    K := Mem[0:Dta + 1];
    If (Mem[0:Dta] <> Ord('P')) Or (K >= VmMaxFind) Or
       (VmFindH[K] = 0) Or (MemW[0:Dta + 2] <> VmFindSeq[K]) Then
    Begin
      VmFail(18);
      Exit;
    End;
    H := VmFindH[K];
    Mask := Mem[0:Dta + 12];
    Ok := FindNextFileA(H, Fd);
  End;
  While Ok <> 0 Do
  Begin
    A := MemL[0:Fd] And $3F;
    S := PStr(Fd + 304);
    If S = '' Then S := PStr(Fd + 44);
    S := UpStr(S);
    If ((A And $16 And Not Mask) = 0) And (Length(S) <= 12) Then
    Begin
      Mem[0:Dta + $15] := A;
      D := 0; T := 0;
      FileTimeToDosDateTime(Fd + 20, LongInt(@D), LongInt(@T));
      MemW[0:Dta + $16] := T; MemW[0:Dta + $18] := D;
      MemL[0:Dta + $1A] := MemL[0:Fd + 32];
      FillMem(Dta + $1E, 13, 0);
      PutPStr(Dta + $1E, S, 13);
      VmSetCF(False);
      Exit;
    End;
    Ok := FindNextFileA(H, Fd);
  End;
  FindClose(H);
  VmFindH[K] := 0;
  VmFail(18);
End;

{ ------------------------------------------------------------------ }
{ Interpreteur de commandes integre (COMMAND.COM)                     }
{ ------------------------------------------------------------------ }
{ COMSPEC designe C:\COMMAND.COM ; sans ce fichier (l'Invite MS-DOS de
  OS/2-0, CMD.EXE, est un programme 32 bits), EXEC charge un
  interpreteur integre :
  un .COM de 5 octets (HLT ; INT 21h ; JMP 100h) dont le HLT donne la
  main au moniteur. Les commandes internes sont executees ici ; pour
  un programme, le moniteur prepare un EXEC (AX=4B00h) que l'INT 21h
  suivant execute ; a la fin du programme, le JMP ramene au HLT, donc a
  l'invite. COMMAND /C commande execute une commande puis se termine
  (outils de l'EDI de Turbo Pascal, commande Fichier > DOS shell). }

Function VmIsShell(Cs, Ip : LongInt) : Boolean;
Begin
  VmIsShell := (Ip = $100) And (MemL[0:VmLin(Cs, $105)] = ShSig);
End;

Function ShCurDir : String;
Begin
  If VmDir[VmDrive] = '' Then ShCurDir := Chr(65 + VmDrive) + ':\'
  Else ShCurDir := Chr(65 + VmDrive) + ':' + VmDir[VmDrive];
End;

{ Premier mot de S (retire de S) }
Function ShWord(Var S : String) : String;
Var P : LongInt;
Begin
  S := Trim(S);
  P := 1;
  While (P <= Length(S)) And Not (S[P] In [' ', #9, '/', ',', ';', '=']) Do
    Inc(P);
  If (P = 1) And (P <= Length(S)) Then P := 2;
  ShWord := Copy(S, 1, P - 1);
  S := Trim(Copy(S, P, 255));
End;

{ Variable de l'environnement du processus courant }
Function ShEnv(Const Name : String) : String;
Var A, N : LongInt; T : String;
Begin
  ShEnv := '';
  A := VmLin(MemW[0:VmLin(VmCurPsp, $2C)], 0);
  N := 0;
  While (N < 32000) And (Mem[0:A + N] <> 0) Do
  Begin
    T := PStr(A + N);
    If UpStr(Copy(T, 1, Length(Name) + 1)) = Name + '=' Then
    Begin
      ShEnv := Copy(T, Length(Name) + 2, 255);
      Exit;
    End;
    While Mem[0:A + N] <> 0 Do Inc(N);
    Inc(N);
  End;
End;

Function ShExists(Const F : String; Var Attr : LongInt) : Boolean;
Begin
  PutPStr(VmTmp + 512, F, 256);
  Attr := GetFileAttributesA(VmTmp + 512);
  ShExists := Attr <> -1;
End;

{ Programme N : repertoire courant puis chemins de PATH }
Function ShExt(I : LongInt) : String;
Begin
  If I = 0 Then ShExt := '.COM' Else If I = 1 Then ShExt := '.EXE' Else ShExt := '.BAT';
End;

Function ShFindProg(N : String) : String;
Var Dirs, D, F : String; I, P, A : LongInt;
Begin
  ShFindProg := '';
  N := UpStr(N);
  Dirs := '';
  If (Pos('\', N) = 0) And (Pos(':', N) = 0) Then Dirs := ShEnv('PATH');
  D := '';
  Repeat
    If D = '' Then F := VmFullPath(N)
    Else
    Begin
      If D[Length(D)] <> '\' Then D := D + '\';
      F := VmFullPath(D + N);
    End;
    If Pos('.', BaseName(F)) > 0 Then
    Begin
      If ShExists(F, A) And ((A And $10) = 0) Then
      Begin
        ShFindProg := F;
        Exit;
      End;
    End
    Else
      For I := 0 To 2 Do
        If ShExists(F + ShExt(I), A) And ((A And $10) = 0) Then
        Begin
          ShFindProg := F + ShExt(I);
          Exit;
        End;
    If Dirs = '' Then Exit;
    P := Pos(';', Dirs);
    If P = 0 Then P := Length(Dirs) + 1;
    D := Trim(Copy(Dirs, 1, P - 1));
    Dirs := Copy(Dirs, P + 1, 255);
  Until D = '';
End;

Function ShPad(S : String; N : LongInt; Left : Boolean) : String;
Begin
  While Length(S) < N Do
    If Left Then S := ' ' + S Else S := S + ' ';
  ShPad := S;
End;

{ Nombre avec separateur des milliers }
Function ShNum(V : LongInt) : String;
Var S, R : String; I : LongInt;
Begin
  S := IntStr(V);
  R := '';
  For I := Length(S) DownTo 1 Do
  Begin
    R := S[I] + R;
    If ((Length(S) - I) Mod 3 = 2) And (I > 1) Then R := ' ' + R;
  End;
  ShNum := R;
End;

Function Dig2(V : LongInt) : String;
Begin
  Dig2 := Chr(48 + (V Div 10) Mod 10) + Chr(48 + V Mod 10);
End;

Procedure ShDir(Arg : String);
Var H, Fd, Ok, N, Tot, A, D, T, P, Spc : LongInt; S, Nm, Ex : String;
Begin
  While (Arg <> '') And (Arg[1] = '/') Do ShWord(Arg);
  S := VmFullPath(Arg);
  If (Arg = '') Or (ShExists(S, A) And ((A And $10) <> 0)) Then
  Begin
    If S[Length(S)] <> '\' Then S := S + '\';
    S := S + '*.*';
  End
  Else If Pos('.', BaseName(S)) = 0 Then S := S + '.*';
  VmConStr(VmL(' R'#130'pertoire de ', ' Directory of ', ' Verzeichnis von ',
             ' Directory di ', ' Directorio de ') + ParentDir(S) +
           #13#10#13#10);
  Fd := VmTmp + 512;
  PutPStr(VmTmp, S, 256);
  H := FindFirstFileA(VmTmp, Fd);
  N := 0; Tot := 0;
  Ok := Ord(H <> INVALID_HANDLE);
  While Ok <> 0 Do
  Begin
    Nm := UpStr(PStr(Fd + 304));
    If Nm = '' Then Nm := UpStr(PStr(Fd + 44));
    A := MemL[0:Fd];
    If (A And 6) = 0 Then
    Begin
      Ex := '';
      P := Pos('.', Nm);
      If (P > 1) Then
      Begin
        Ex := Copy(Nm, P + 1, 3);
        Nm := Copy(Nm, 1, P - 1);
      End;
      S := ShPad(Copy(Nm, 1, 8), 9, False) + ShPad(Ex, 4, False);
      If (A And $10) <> 0 Then S := S + '<REP>         '
      Else
      Begin
        S := S + ShPad(ShNum(MemL[0:Fd + 32]), 13, True) + ' ';
        Tot := Tot + MemL[0:Fd + 32];
      End;
      D := 0; T := 0;
      FileTimeToDosDateTime(Fd + 20, LongInt(@D), LongInt(@T));
      S := S + ' ' + Dig2(D And 31) + '/' + Dig2((D Shr 5) And 15) + '/' +
           Dig2(((D Shr 9) + 80) Mod 100) + '  ' +
           ShPad(IntStr(T Shr 11), 2, True) + ':' + Dig2((T Shr 5) And 63);
      VmConStr(S + #13#10);
      Inc(N);
    End;
    Ok := FindNextFileA(H, Fd);
  End;
  If H <> INVALID_HANDLE Then FindClose(H);
  VmConStr(ShPad(IntStr(N), 9, True) + VmL(' fichier(s) ', ' file(s) ',
           ' Datei(en) ', ' file ', ' archivo(s) ') +
           ShPad(ShNum(Tot), 14, True) + VmL(' octets', ' bytes', ' Bytes',
           ' byte', ' bytes') + #13#10);
  PutPStr(VmTmp, Chr(65 + VmDrive) + ':\', 8);
  If GetDiskFreeSpaceA(VmTmp, VmTmp + 16, VmTmp + 20, VmTmp + 24,
                       VmTmp + 28) <> 0 Then
  Begin
    Spc := MemL[0:VmTmp + 16] * MemL[0:VmTmp + 20];
    If MemL[0:VmTmp + 24] < $7FFFFFFF Div Max(Spc, 1) Then
      VmConStr(ShPad(ShNum(MemL[0:VmTmp + 24] * Spc), 39, True) +
               VmL(' octets libres', ' bytes free', ' Bytes frei',
                 ' byte liberi', ' bytes libres') + #13#10)
    Else
      VmConStr(ShPad(ShNum(MemL[0:VmTmp + 24] * (Spc Div 1024)), 39,
                     True) + VmL(' Ko libres', ' KB free', ' KB frei',
                     ' KB liberi', ' KB libres') + #13#10);
  End;
End;

Procedure ShType(Arg : String);
Var H, N, I, C : LongInt;
Begin
  H := KOpenFile(VmFullPath(ShWord(Arg)), False, 3);
  If H = INVALID_HANDLE Then
  Begin
    VmConStr(VmL('Fichier introuvable', 'File not found',
               'Datei nicht gefunden', 'File non trovato',
               'Archivo no encontrado') + #13#10);
    Exit;
  End;
  Repeat
    If Not KReadFile(H, VmTmp + 512, 256, N) Then N := 0;
    For I := 0 To N - 1 Do
    Begin
      C := Mem[0:VmTmp + 512 + I];
      If C = 26 Then
      Begin
        N := 0;
        Break;
      End;
      VmConOut(C);
    End;
  Until N < 256;
  CloseHandle(H);
End;

Procedure ShCopy(Arg : String);
Var Src, Dst : String; A, H1, H2, N, Tot : LongInt;
Begin
  Src := VmFullPath(ShWord(Arg));
  Dst := Trim(Arg);
  If Dst = '' Then Dst := ShCurDir;
  Dst := VmFullPath(Dst);
  If ShExists(Dst, A) And ((A And $10) <> 0) Then
  Begin
    If Dst[Length(Dst)] <> '\' Then Dst := Dst + '\';
    Dst := Dst + BaseName(Src);
  End;
  H1 := KOpenFile(Src, False, 3);
  If H1 = INVALID_HANDLE Then
  Begin
    VmConStr(VmL('Fichier introuvable', 'File not found',
               'Datei nicht gefunden', 'File non trovato',
               'Archivo no encontrado') + ' - ' + Src + #13#10);
    Exit;
  End;
  H2 := KOpenFile(Dst, True, 2);
  If H2 = INVALID_HANDLE Then
  Begin
    CloseHandle(H1);
    VmConStr(VmL('Impossible de creer ', 'Cannot create ',
               'Kann nicht erstellen: ', 'Impossibile creare ',
               'No se puede crear ') + Dst + #13#10);
    Exit;
  End;
  Tot := 0;
  Repeat
    If Not KReadFile(H1, VmTmp + 512, 512, N) Then N := 0;
    If N > 0 Then KWriteFile(H2, VmTmp + 512, N);
    Tot := Tot + N;
  Until N < 512;
  CloseHandle(H1);
  CloseHandle(H2);
  VmConStr(VmL('        1 fichier(s) copie(s)', '        1 file(s) copied',
             '        1 Datei(en) kopiert', '        1 file copiati',
             '        1 archivo(s) copiado(s)') + #13#10);
End;

Procedure ShDel(Arg : String);
Var S, Dir : String; H, Fd, Ok, A, N : LongInt;
Begin
  S := VmFullPath(ShWord(Arg));
  If ShExists(S, A) And ((A And $10) <> 0) Then
    S := S + '\*.*';
  Dir := ParentDir(S);
  If Dir[Length(Dir)] <> '\' Then Dir := Dir + '\';
  Fd := VmTmp + 512;
  PutPStr(VmTmp, S, 256);
  H := FindFirstFileA(VmTmp, Fd);
  N := 0;
  Ok := Ord(H <> INVALID_HANDLE);
  While Ok <> 0 Do
  Begin
    If (MemL[0:Fd] And $17) = 0 Then
    Begin
      PutPStr(VmTmp + 300, Dir + PStr(Fd + 44), 200);
      If DeleteFileA(VmTmp + 300) <> 0 Then Inc(N);
    End;
    Ok := FindNextFileA(H, Fd);
  End;
  If H <> INVALID_HANDLE Then FindClose(H);
  If N = 0 Then
    VmConStr(VmL('Fichier introuvable', 'File not found',
               'Datei nicht gefunden', 'File non trovato',
               'Archivo no encontrado') + #13#10);
End;

{ Changer de repertoire (INT 21h 3Bh et CD) ; False : introuvable }
Function VmChDir(Const Name : String) : Boolean;
Var Path : String; D, A : LongInt;
Begin
  VmChDir := False;
  Path := VmFullPath(Name);
  D := Ord(Path[1]) - 65;
  If Not VmDriveOk(D) Or (Length(Path) > 66) Then Exit;
  If Length(Path) > 3 Then
    If Not ShExists(Path, A) Or ((A And $10) = 0) Then Exit;
  VmDir[D] := Copy(Path, 3, 66);
  If VmDir[D] = '\' Then VmDir[D] := '';
  If D = VmDrive Then
  Begin
    VmSetCwd(Copy(Path, 1, 2) + VmDir[D]);
  End;
  VmChDir := True;
End;

Procedure ShExit;
Begin
  VS(fEax, $4C00 Or (VmRetCode And $FF));
  MemL[0:VmF + fEip] := $101;
End;

{ Executer une ligne ; True : la machine reprend (EXEC ou fin) }
Function ShExec(Line : String) : Boolean;
Var Cmd, Arg, F, T : String; P, A, I, Max : LongInt;
Begin
  ShExec := False;
  Arg := Trim(Line);
  If Arg = '' Then Exit;
  Cmd := UpStr(ShWord(Arg));
  { CD.. CD\ : commande collee a son argument }
  If (Copy(Cmd, 1, 2) = 'CD') And (Length(Cmd) > 2) And
     (Cmd[3] In ['.', '\']) Then
  Begin
    Arg := Copy(Cmd, 3, 255) + ' ' + Arg;
    Cmd := 'CD';
  End;
  If (Length(Cmd) = 2) And (Cmd[2] = ':') Then
  Begin
    If VmDriveOk(Ord(Cmd[1]) - 65) Then
    Begin
      VmDrive := Ord(Cmd[1]) - 65;
      VmSetCwd(Copy(Cmd, 1, 2) + VmDir[VmDrive]);
    End
    Else VmConStr(VmL('Lecteur non valide', 'Invalid drive specification',
                    'Laufwerk ungueltig', 'Unita non valida',
                    'Unidad no valida') + #13#10);
  End
  Else If (Cmd = 'CD') Or (Cmd = 'CHDIR') Then
  Begin
    If Arg = '' Then VmConStr(ShCurDir + #13#10)
    Else If Not VmChDir(Trim(Arg)) Then
      VmConStr(VmL('Repertoire non valide', 'Invalid directory',
                 'Ungueltiges Verzeichnis', 'Directory non valida',
                 'Directorio no valido') + #13#10);
  End
  Else If Cmd = 'DIR' Then ShDir(Arg)
  Else If Cmd = 'CLS' Then
  Begin
    VmScroll(VmPage, 0, 7, 0, 0, 24, 79, True);
    VmSetCur(VmPage, 0, 0);
  End
  Else If Cmd = 'ECHO' Then VmConStr(Arg + #13#10)
  Else If Cmd = 'VER' Then
    VmConStr(#13#10 + VmL('Systeme d''exploitation OS/2-0, version ',
               'The Operating System/2-0 Version is ', 'OS/2-0 Version ',
               'Sistema operativo OS/2-0, versione ',
               'Sistema operativo OS/2-0, version ') + '20.00' + #13#10 +
             VmL('Session DOS (DOS 5.00)', 'DOS session (DOS 5.00)',
               'DOS-Sitzung (DOS 5.00)', 'Sessione DOS (DOS 5.00)',
               'Sesion DOS (DOS 5.00)') + #13#10)
  Else If Cmd = 'TYPE' Then ShType(Arg)
  Else If (Cmd = 'DEL') Or (Cmd = 'ERASE') Then ShDel(Arg)
  Else If Cmd = 'COPY' Then ShCopy(Arg)
  Else If (Cmd = 'MD') Or (Cmd = 'MKDIR') Or (Cmd = 'RD') Or
          (Cmd = 'RMDIR') Then
  Begin
    PutPStr(VmTmp, VmFullPath(ShWord(Arg)), 256);
    If Cmd[1] = 'M' Then I := CreateDirectoryA(VmTmp, 0)
    Else I := RemoveDirectoryA(VmTmp);
    If I = 0 Then
      VmConStr(VmL('Impossible de creer ou supprimer le repertoire',
                 'Unable to create or remove directory',
                 'Verzeichnis nicht erstellt oder entfernt',
                 'Impossibile creare o rimuovere la directory',
                 'No se puede crear o quitar el directorio') + #13#10);
  End
  Else If (Cmd = 'REN') Or (Cmd = 'RENAME') Then
  Begin
    F := VmFullPath(ShWord(Arg));
    T := ParentDir(F);
    If T[Length(T)] <> '\' Then T := T + '\';
    PutPStr(VmTmp, F, 256);
    PutPStr(VmTmp + 256, T + UpStr(ShWord(Arg)), 256);
    If MoveFileA(VmTmp, VmTmp + 256) = 0 Then
      VmConStr(VmL('Nom de fichier en double ou fichier introuvable',
                 'Duplicate file name or file not found',
                 'Doppelter Dateiname oder Datei nicht gefunden',
                 'Nome duplicato o file non trovato',
                 'Nombre duplicado o archivo no encontrado') + #13#10);
  End
  Else If (Cmd = 'SET') And (Arg = '') Then
  Begin
    A := VmLin(MemW[0:VmLin(VmCurPsp, $2C)], 0);
    P := 0;
    While (P < 32000) And (Mem[0:A + P] <> 0) Do
    Begin
      VmConStr(PStr(A + P) + #13#10);
      While Mem[0:A + P] <> 0 Do Inc(P);
      Inc(P);
    End;
  End
  Else If (Cmd = 'PATH') And (Arg = '') Then
    VmConStr('PATH=' + ShEnv('PATH') + #13#10)
  Else If Cmd = 'MEM' Then
  Begin
    McbAlloc($FFFF, 0, Max);
    VmConStr(#13#10 + ShPad(ShNum(655360), 11, True) +
             VmL(' octets de memoire conventionnelle',
               ' bytes total conventional memory',
               ' Bytes konventioneller Speicher',
               ' byte di memoria convenzionale',
               ' bytes de memoria convencional') + #13#10 +
             ShPad(ShNum(Max * 16), 11, True) +
             VmL(' octets disponibles', ' bytes available to MS-DOS',
               ' Bytes verfuegbar', ' byte disponibili',
               ' bytes disponibles') + #13#10);
  End
  Else If (Cmd = 'HELP') Or (Cmd = '?') Then
    VmConStr('CD CLS COPY DEL DIR ECHO EXIT MD MEM PATH REN RD SET TYPE ' +
             'VER X:'#13#10)
  Else If Cmd = 'EXIT' Then
  Begin
    ShExit;
    ShExec := True;
  End
  Else
  Begin
    { programme : EXEC prepare dans le PSP de l'interpreteur }
    F := ShFindProg(Cmd);
    If F = '' Then
    Begin
      VmConStr(VmL('Commande ou nom de fichier incorrect',
                 'Bad command or file name', 'Befehl oder Dateiname ungueltig',
                 'Comando o nome di file non valido',
                 'Comando o nombre de archivo incorrecto') + #13#10);
      Exit;
    End;
    If (Copy(F, Length(F) - 3, 4) = '.BAT') Or Not IsDosFile(F) Then
    Begin
      VmConStr(VmL('Ce programme ne peut pas etre execute en mode MS-DOS.',
                 'This program cannot be run in MS-DOS mode.',
                 'Dieses Programm kann nicht im MS-DOS-Modus laufen.',
                 'Impossibile eseguire il programma in modalita MS-DOS.',
                 'Este programa no se puede ejecutar en modo MS-DOS.') +
               #13#10);
      Exit;
    End;
    P := VR(fCs);
    PutPStr(VmLin(P, $180), F, 128);
    If Arg <> '' Then Arg := ' ' + Arg;
    If Length(Arg) > 120 Then Arg := Copy(Arg, 1, 120);
    Mem[0:VmLin(P, $140)] := Length(Arg);
    For I := 1 To Length(Arg) Do Mem[0:VmLin(P, $140 + I)] := Ord(Arg[I]);
    Mem[0:VmLin(P, $141 + Length(Arg))] := 13;
    T := Arg;
    VmFcbName(VmLin(P, $5C), T);
    VmFcbName(VmLin(P, $6C), T);
    MemW[0:VmLin(P, $120)] := 0;
    MemL[0:VmLin(P, $122)] := (P Shl 16) Or $140;
    MemL[0:VmLin(P, $126)] := (P Shl 16) Or $5C;
    MemL[0:VmLin(P, $12A)] := (P Shl 16) Or $6C;
    VSeg(fDs, P); VS(fEdx, $180);
    VSeg(fEs, P); VS(fEbx, $120);
    VS(fEax, $4B00);
    MemL[0:VmF + fEip] := $101;
    ShExec := True;
  End;
End;

{ HLT de l'interpreteur : commandes jusqu'au prochain programme }
Procedure VmShell;
Var P, A : LongInt; Line : String;
Begin
  P := VR(fCs);
  A := VmLin(P, $100);
  If Mem[0:A + $10] = 2 Then
  Begin
    ShExit;
    Exit;
  End;
  If Mem[0:A + $10] = 1 Then
  Begin
    { COMMAND /C commande }
    Mem[0:A + $10] := 2;
    Line := '';
    For P := 1 To Mem[0:A - $80] Do Line := Line + Chr(Mem[0:A - $80 + P]);
    Line := Trim(Line);
    Line := Trim(Copy(Line, 3, 255));
    If Not ShExec(Line) Then ShExit;
    Exit;
  End;
  If Mem[0:A + $11] = 0 Then
  Begin
    Mem[0:A + $11] := 1;
    If VmCurPsp = VmTopPsp Then
      { session DOS (DOS plein ecran du bureau, COMMAND de CMD.EXE) }
      VmConStr(#13#10 + VmL('Session DOS d''OS/2-0 (DOS 5.00). Tapez EXIT pour la fermer.',
               'OS/2-0 DOS session (DOS 5.00). Type EXIT to close it.',
               'DOS-Sitzung von OS/2-0 (DOS 5.00). EXIT beendet sie.',
               'Sessione DOS di OS/2-0 (DOS 5.00). Digitare EXIT per chiuderla.',
               'Sesion DOS de OS/2-0 (DOS 5.00). Escriba EXIT para cerrarla.') + #13#10)
    Else
      VmConStr(#13#10 + VmL('Tapez EXIT pour revenir au programme.',
             'Type EXIT to return to the program.',
             'Geben Sie EXIT ein, um zurueckzukehren.',
             'Digitare EXIT per tornare al programma.',
             'Escriba EXIT para volver al programa.') + #13#10);
  End;
  Repeat
    VmConStr(#13#10 + ShCurDir + '>');
    Line := VmReadLine(126);
    VmTty(10);
    If ShExec(Line) Then Exit;
  Until False;
End;

{ ------------------------------------------------------------------ }
{ DOS : INT 21h                                                      }
{ ------------------------------------------------------------------ }

Procedure VmDiskFree(D : LongInt);
Var Spc, Bps, Fr, Tot : LongInt;
Begin
  If D = 0 Then D := VmDrive Else D := D - 1;
  If Not VmDriveOk(D) Then
  Begin
    VS(fEax, $FFFF);
    Exit;
  End;
  PutPStr(VmTmp + 400, Chr(65 + D) + ':\', 8);
  If GetDiskFreeSpaceA(VmTmp + 400, VmTmp, VmTmp + 4, VmTmp + 8,
                       VmTmp + 12) = 0 Then
  Begin
    VS(fEax, $FFFF);
    Exit;
  End;
  Spc := MemL[0:VmTmp]; Bps := MemL[0:VmTmp + 4];
  Fr := MemL[0:VmTmp + 8]; Tot := MemL[0:VmTmp + 12];
  { au plus FFFFh grappes (comme MS-DOS 7 sur un grand disque) }
  While ((Tot > $FFFF) Or (Fr > $FFFF)) And (Spc < 128) Do
  Begin
    Spc := Spc * 2; Tot := Tot Div 2; Fr := Fr Div 2;
  End;
  VS(fEax, Spc); VS(fEbx, Min(Fr, $FFFF));
  VS(fEcx, Bps); VS(fEdx, Min(Tot, $FFFF));
End;

Procedure VmIoctl;
Var AL, S, D : LongInt;
Begin
  AL := VRL(fEax);
  VmSetCF(False);
  Case AL Of
    $00, $01, $06, $07, $0A :
    Begin
      S := VmSftOf(VR(fEbx));
      If S < 0 Then
      Begin
        VmFail(6);
        Exit;
      End;
      Case AL Of
        $00 :
          If SftDev[S] = 1 Then VS(fEdx, $80D3)
          Else If SftDev[S] = 2 Then VS(fEdx, $8084)
          Else VS(fEdx, $40 Or (VmDrive And $1F));
        $01 : ;
        $06 :
          If SftDev[S] = 1 Then
          Begin
            VmPumpNative;
            VSL(fEax, $FF * Ord(VmBufHas Or VmLineOk));
          End
          Else If SftDev[S] = 2 Then VSL(fEax, 0)
          Else VSL(fEax, $FF * Ord(SetFilePointer(SftH[S], 0, 0, 1) <
                                   GetFileSize(SftH[S], 0)));
        $07 : VSL(fEax, $FF);
        $0A : VS(fEdx, 0);
      End;
    End;
    $08 :
    Begin
      D := VRL(fEbx);
      If D = 0 Then D := VmDrive Else D := D - 1;
      If Not VmDriveOk(D) Then VmFail(15)
      Else VS(fEax, Ord(D <> 3));
    End;
    $09 :
    Begin
      D := VRL(fEbx);
      If D = 0 Then D := VmDrive Else D := D - 1;
      If Not VmDriveOk(D) Then VmFail(15)
      Else If D = 3 Then VS(fEdx, $1000) Else VS(fEdx, 0);
    End;
    $0B : ;
    $0E, $0F : VSL(fEax, 0);
  Else
    VmFail(1);
  End;
End;

Procedure VmCountry;
Var P : LongInt;
Begin
  P := VmPtr(fDs, fEdx);
  FillMem(P, 34, 0);
  If VmLang = 1 Then MemW[0:P] := 0 Else MemW[0:P] := 1;
  Mem[0:P + 2] := Ord('$');
  Mem[0:P + 7] := Ord(' '); Mem[0:P + 9] := Ord(',');
  Mem[0:P + 11] := Ord('/'); Mem[0:P + 13] := Ord(':');
  Mem[0:P + 16] := 2;
  If VmLang = 1 Then Mem[0:P + 17] := 0 Else Mem[0:P + 17] := 1;
  If VmLang = 1 Then
  Begin
    Mem[0:P + 7] := Ord(','); Mem[0:P + 9] := Ord('.');
  End;
  MemW[0:P + 18] := VmCpmO + 2; MemW[0:P + 20] := VmBios;
  Mem[0:P + 22] := Ord(',');
  VS(fEbx, 1);
  VmSetCF(False);
End;

Procedure VmCountryX;
Var AL, P, I, N : LongInt;
Begin
  AL := VRL(fEax);
  VmSetCF(False);
  Case AL Of
    $01 :
    Begin
      P := VmPtr(fEs, fEdi);
      Mem[0:P] := 1; MemW[0:P + 1] := 38; MemW[0:P + 3] := 1;
      MemW[0:P + 5] := 437;
      MemW[0:VmTmp + 900] := VR(fEdx);
      VS(fEdx, P);
      FillMem(P + 7, 34, 0);
      VS(fEdx, MemW[0:VmTmp + 900]);
      VS(fEcx, 41);
    End;
    $02, $04, $06 :
    Begin
      P := VmPtr(fEs, fEdi);
      Mem[0:P] := AL;
      MemW[0:P + 1] := VmUpO; MemW[0:P + 3] := VmDosSeg;
      VS(fEcx, 5);
    End;
    $07 :
    Begin
      P := VmPtr(fEs, fEdi);
      Mem[0:P] := 7;
      MemW[0:P + 1] := VmDbcsO; MemW[0:P + 3] := VmDosSeg;
      VS(fEcx, 5);
    End;
    $20 : VSL(fEdx, UpCh(VRL(fEdx)));
    $21 :
    Begin
      P := VmPtr(fDs, fEdx);
      For I := 0 To VR(fEcx) - 1 Do Mem[0:P + I] := UpCh(Mem[0:P + I]);
    End;
    $22 :
    Begin
      P := VmPtr(fDs, fEdx);
      N := 0;
      While (N < 65535) And (Mem[0:P + N] <> 0) Do
      Begin
        Mem[0:P + N] := UpCh(Mem[0:P + N]);
        Inc(N);
      End;
    End;
  Else
    VmFail(1);
  End;
End;

{ AH=29h : analyser un nom de fichier vers un FCB }
Procedure VmParseFcb;
Var P, F, I, N, AL : LongInt; S : String;
Begin
  P := VmPtr(fDs, fEsi);
  F := VmPtr(fEs, fEdi);
  AL := VRL(fEax);
  S := '';
  For I := 0 To 127 Do
  Begin
    If Mem[0:P + I] In [0, 13] Then Break;
    S := S + Chr(Mem[0:P + I]);
  End;
  N := Length(S);
  If (AL And 1) <> 0 Then
    While (S <> '') And (S[1] In [' ', #9, ',', ';', '=', ':', '+']) Do
      S := Copy(S, 2, 255);
  VmFcbName(F, S);
  VS(fEsi, VR(fEsi) + N - Length(S));
  I := 0;
  For N := 1 To 11 Do If Mem[0:F + N] = Ord('?') Then I := 1;
  If (Mem[0:F] <> 0) And Not VmDriveOk(Mem[0:F] - 1) Then I := $FF;
  VSL(fEax, I);
End;

Function DpDos(AH, AL : LongInt) : Boolean; Forward;

Procedure VmInt21;
Var AH, AL, S, H, N, R, P, D, T, Max : LongInt; Path : String;
Begin
  AH := VRH(fEax); AL := VRL(fEax);
  If VmTrace Then
  Begin
    If AH In [$39..$3D, $41, $43, $4B, $4E, $56, $5A, $5B] Then
      Path := ' "' + Copy(PStr(VmPtr(fDs, fEdx)), 1, 60) + '"'
    Else Path := '';
    VmLog('INT 21h ' + VmRegStr + ' de ' +
         HexStr(VmGetW(VR(fSs), VR(fEsp) + 2), 4) + ':' +
         HexStr(VmGetW(VR(fSs), VR(fEsp)), 4) + Path);
  End;
  If Not (AH In [$33, $50, $51, $59, $62, $64]) And Not VmPM Then
    VmDosSave;
  { client DPMI : fonctions propres au mode protege }
  If VmPM And DpDos(AH, AL) Then Exit;
  VmSetCF(False);
  Case AH Of
    $00 : VmTerminate(0, False, 0);
    $01 :
    Begin
      N := VmGetCh;
      VSL(fEax, N);
      If N <> 0 Then VmConOut(N);
    End;
    $02 : VmConOut(VRL(fEdx));
    $03 : VSL(fEax, 0);
    $04, $05 : ;
    $06 :
      If VRL(fEdx) = $FF Then
      Begin
        VmPumpNative;
        If (VmPendScan >= 0) Or VmBufHas Then
        Begin
          VSL(fEax, VmGetCh);
          VmSetZF(False);
        End
        Else
        Begin
          VSL(fEax, 0);
          VmSetZF(True);
          VmIdle;
        End;
      End
      Else VmConOut(VRL(fEdx));
    $07, $08 : VSL(fEax, VmGetCh);
    $09 :
    Begin
      P := VmPtr(fDs, fEdx);
      N := 0;
      While (Mem[0:P + N] <> Ord('$')) And (N < 65535) Do
      Begin
        VmConOut(Mem[0:P + N]);
        Inc(N);
      End;
      VSL(fEax, Ord('$'));
    End;
    $0A :
    Begin
      P := VmPtr(fDs, fEdx);
      N := Mem[0:P] - 1;
      If N < 0 Then N := 0;
      Path := VmReadLine(N);
      Mem[0:P + 1] := Length(Path);
      For N := 1 To Length(Path) Do Mem[0:P + 1 + N] := Ord(Path[N]);
      Mem[0:P + 2 + Length(Path)] := 13;
    End;
    $0B :
    Begin
      VmPumpNative;
      VSL(fEax, $FF * Ord(VmBufHas Or (VmPendScan >= 0)));
      If Not VmBufHas Then VmIdle;
    End;
    $0C :
    Begin
      While VmBufHas Do VmBufPop;
      VmPendScan := -1;
      If AL In [1, 6, 7, 8, $0A] Then
      Begin
        VS(fEax, (AL Shl 8) Or VRL(fEdx));
        VmInt21;
        Exit;
      End;
    End;
    $0D : FatFlush;
    $0E :
    Begin
      If VmDriveOk(VRL(fEdx)) Then
      Begin
        VmDrive := VRL(fEdx);
        VmSetCwd(Chr(65 + VmDrive) + ':' + VmDir[VmDrive]);
        If Length(CurDir) = 3 Then VmSetCwd(Copy(CurDir, 1, 2));
      End;
      VSL(fEax, 26);
    End;
    $0F..$17, $21..$24, $27, $28 : VSL(fEax, $FF);
    $18, $1D, $1E, $20 : VSL(fEax, 0);
    $19 : VSL(fEax, VmDrive);
    $1A :
    Begin
      VmDta := (VR(fDs) Shl 16) Or VR(fEdx);
      VmDtaPM := VmPM;
      VmDtaLin := VmPtr(fDs, fEdx);
    End;
    $1B, $1C :
    Begin
      D := VRL(fEdx);
      If AH = $1B Then D := 0;
      VmDiskFree(D);
      If VR(fEax) <> $FFFF Then
      Begin
        VS(fEdx, VR(fEdx));
        Mem[0:VmLin(VmDosSeg, $1F0)] := $F8;
        VSeg(fDs, VmDosSeg); VS(fEbx, $1F0);
      End
      Else VSL(fEax, $FF);
    End;
    $1F, $32 : VSL(fEax, $FF);
    $25 : MemL[0:VmRam + AL * 4] := (VR(fDs) Shl 16) Or VR(fEdx);
    $26 :
    Begin
      D := VR(fEdx);
      MoveMem(VmLin(VmCurPsp, 0), VmLin(D, 0), 256);
      MemW[0:VmLin(D, 2)] := MemW[0:VmLin(VmCurPsp, 2)];
    End;
    $29 : VmParseFcb;
    $2A :
    Begin
      GetLocalTime(VmTmp);
      VS(fEcx, MemW[0:VmTmp]);
      VS(fEdx, (MemW[0:VmTmp + 2] Shl 8) Or MemW[0:VmTmp + 6]);
      VSL(fEax, MemW[0:VmTmp + 4]);
    End;
    $2B, $2D : VSL(fEax, 0);
    $2C :
    Begin
      GetLocalTime(VmTmp);
      VS(fEcx, (MemW[0:VmTmp + 8] Shl 8) Or MemW[0:VmTmp + 10]);
      VS(fEdx, (MemW[0:VmTmp + 12] Shl 8) Or ((VmMsNow Div 10) Mod 100));
    End;
    $2E : VmVerify := AL And 1;
    $2F :
    Begin
      VSeg(fEs, VmDta Shr 16);
      VS(fEbx, VmDta);
    End;
    $30 :
    Begin
      { DOS 5.00, comme les sessions DOS d'OS/2 (DOS_VERSION) }
      VS(fEax, $0005);
      If AL = 1 Then VS(fEbx, $0000) Else VS(fEbx, $FF00);
      VS(fEcx, 0);
    End;
    $31 : VmTerminate(AL, True, VR(fEdx));
    $33 :
      Case AL Of
        0 : VSL(fEdx, VmBreak);
        1 : VmBreak := VRL(fEdx) And 1;
        2 :
        Begin
          N := VmBreak; VmBreak := VRL(fEdx) And 1; VSL(fEdx, N);
        End;
        5 : VSL(fEdx, 3);
        6 :
        Begin
          VS(fEbx, $0005); VS(fEdx, $1000);
        End;
      Else
        VSL(fEax, $FF);
      End;
    $34 :
    Begin
      VSeg(fEs, VmDosSeg);
      VS(fEbx, 0);
    End;
    $35 :
    Begin
      N := MemL[0:VmRam + AL * 4];
      VSeg(fEs, N Shr 16);
      VS(fEbx, N);
    End;
    $36 : VmDiskFree(VRL(fEdx));
    $37 :
      If AL = 0 Then
      Begin
        VSL(fEdx, Ord('/'));
        VSL(fEax, 0);
      End
      Else VSL(fEax, 0);
    $38 : If AL = 0 Then VmCountry Else VmSetCF(False);
    $39, $3A :
    Begin
      VmPathAt(VmPtr(fDs, fEdx), 0);
      If AH = $39 Then N := CreateDirectoryA(VmTmp, 0)
      Else N := RemoveDirectoryA(VmTmp);
      If N = 0 Then VmFail(VmErrOf(5));
    End;
    $3B : If Not VmChDir(PStr(VmPtr(fDs, fEdx))) Then VmFail(3);
    $3C : VmOpenH(VmPathAt(VmPtr(fDs, fEdx), 0), 2, 2);
    $5B : VmOpenH(VmPathAt(VmPtr(fDs, fEdx), 0), 2, 1);
    $3D : VmOpenH(VmPathAt(VmPtr(fDs, fEdx), 0), AL, 3);
    $5A :
    Begin
      P := VmPtr(fDs, fEdx);
      Path := PStr(P);
      If (Path <> '') And Not (Path[Length(Path)] In ['\', ':']) Then
        Path := Path + '\';
      Repeat
        Inc(VmFindCnt);
        S := VmOpen(VmFullPath(Path + 'PD' + HexStr(VmMsNow + VmFindCnt, 6)),
                    2, 1);
      Until (S >= 0) Or (VmLastErr <> 80);
      If S < 0 Then VmFail(VmLastErr)
      Else
      Begin
        PutPStr(P, Path + 'PD' + HexStr(VmMsNow + VmFindCnt, 6), 128);
        H := VmHNew(S);
        If H < 0 Then
        Begin
          SftRelease(S);
          VmFail(4);
        End
        Else VS(fEax, H);
      End;
    End;
    $3E :
    Begin
      If VmSftOf(VR(fEbx)) < 0 Then VmFail(6) Else VmHClose(VR(fEbx));
    End;
    $3F :
    Begin
      S := VmSftOf(VR(fEbx));
      If S < 0 Then VmFail(6)
      Else If SftDev[S] = 1 Then VS(fEax, VmConRead(VmPtr(fDs, fEdx),
                                                     VR(fEcx)))
      Else If SftDev[S] = 2 Then VS(fEax, 0)
      Else If KReadFile(SftH[S], VmPtr(fDs, fEdx), VR(fEcx), N) Then
        VS(fEax, N)
      Else VmFail(5);
    End;
    $40 :
    Begin
      S := VmSftOf(VR(fEbx));
      N := VR(fEcx);
      If S < 0 Then VmFail(6)
      Else If SftDev[S] = 1 Then
      Begin
        P := VmPtr(fDs, fEdx);
        For R := 0 To N - 1 Do VmConOut(Mem[0:P + R]);
        VS(fEax, N);
      End
      Else If SftDev[S] = 2 Then VS(fEax, N)
      Else If (SftMode[S] And 3) = 0 Then VmFail(5)
      Else If N = 0 Then
      Begin
        SetEndOfFile(SftH[S]);
        VS(fEax, 0);
      End
      Else
      Begin
        R := KWriteFile(SftH[S], VmPtr(fDs, fEdx), N);
        If R < 0 Then VmFail(5) Else VS(fEax, R);
      End;
    End;
    $41 :
    Begin
      VmPathAt(VmPtr(fDs, fEdx), 0);
      If DeleteFileA(VmTmp) = 0 Then VmFail(VmErrOf(2));
    End;
    $42 :
    Begin
      S := VmSftOf(VR(fEbx));
      If S < 0 Then VmFail(6)
      Else If SftDev[S] <> 0 Then VS(fEax, 0)
      Else If AL > 2 Then VmFail(1)
      Else
      Begin
        R := SetFilePointer(SftH[S], (VR(fEcx) Shl 16) Or VR(fEdx), 0, AL);
        If R = -1 Then VmFail(25)
        Else
        Begin
          VS(fEax, R);
          VS(fEdx, R Shr 16);
        End;
      End;
    End;
    $43 :
    Begin
      VmPathAt(VmPtr(fDs, fEdx), 0);
      If AL = 0 Then
      Begin
        R := GetFileAttributesA(VmTmp);
        If R = -1 Then VmFail(VmErrOf(2))
        Else
        Begin
          If R = $80 Then R := 0;
          VS(fEcx, R And $3F);
          VS(fEax, R And $3F);
        End;
      End
      Else If AL = 1 Then
      Begin
        If GetFileAttributesA(VmTmp) = -1 Then VmFail(2)
        Else SetFileAttributesA(VmTmp, VR(fEcx));
      End
      Else VmFail(1);
    End;
    $44 : VmIoctl;
    $45 :
    Begin
      S := VmSftOf(VR(fEbx));
      If S < 0 Then VmFail(6)
      Else
      Begin
        H := VmHNew(S);
        If H < 0 Then VmFail(4)
        Else
        Begin
          Inc(SftRef[S]);
          VS(fEax, H);
        End;
      End;
    End;
    $46 :
    Begin
      S := VmSftOf(VR(fEbx));
      If (S < 0) Or (VmJft(VR(fEcx)) = 0) Then VmFail(6)
      Else
      Begin
        VmHClose(VR(fEcx));
        Mem[0:VmJft(VR(fEcx))] := S;
        Inc(SftRef[S]);
      End;
    End;
    $47 :
    Begin
      D := VRL(fEdx);
      If D = 0 Then D := VmDrive Else D := D - 1;
      If Not VmDriveOk(D) Then VmFail(15)
      Else
      Begin
        PutPStr(VmPtr(fDs, fEsi), Copy(VmDir[D], 2, 66), 64);
        VS(fEax, $0100);
      End;
    End;
    $48 :
    Begin
      N := McbAlloc(VR(fEbx), VmCurPsp, Max);
      If N = 0 Then
      Begin
        VmFail(8);
        VS(fEbx, Max);
      End
      Else VS(fEax, N);
    End;
    $49 : If McbValid(VR(fEs)) Then McbFree(VR(fEs)) Else VmFail(9);
    $4A :
      If Not McbValid(VR(fEs)) Then VmFail(9)
      Else If Not McbResize(VR(fEs), VR(fEbx), Max) Then
      Begin
        VmFail(8);
        VS(fEbx, Max);
      End
      Else If VR(fEs) = VmCurPsp Then
        MemW[0:VmLin(VmCurPsp, 2)] := VmCurPsp + VR(fEbx);
    $4B : VmExec;
    $4C : VmTerminate(AL, False, 0);
    $4D :
    Begin
      VS(fEax, VmRetCode);
      VmRetCode := 0;
    End;
    $4E, $4F :
    Begin
      If VmDtaPM Then P := VmDtaLin Else P := VmLin(VmDta Shr 16, VmDta);
      VmFindStep(P, AH = $4E);
    End;
    $50 : VmCurPsp := VR(fEbx);
    $51, $62 : VS(fEbx, VmCurPsp);
    $52 :
    Begin
      VSeg(fEs, VmDosSeg);
      VS(fEbx, VmLolO);
    End;
    $54 : VSL(fEax, VmVerify);
    $55 :
    Begin
      D := VR(fEdx);
      VmMakePsp(D, VR(fEsi) - D, MemW[0:VmLin(VmCurPsp, $2C)], VmCurPsp,
                '');
      MoveMem(VmLin(VmCurPsp, $80), VmLin(D, $80), 128);
      VmCurPsp := D;
    End;
    $56 :
    Begin
      VmPathAt(VmPtr(fDs, fEdx), 0);
      VmPathAt(VmPtr(fEs, fEdi), 256);
      If MoveFileA(VmTmp, VmTmp + 256) = 0 Then VmFail(VmErrOf(5));
    End;
    $57 :
    Begin
      S := VmSftOf(VR(fEbx));
      If (S < 0) Or (SftDev[S] <> 0) Then
      Begin
        If S < 0 Then VmFail(6);
      End
      Else If AL = 0 Then
      Begin
        D := 0; T := 0;
        If GetFileTime(SftH[S], 0, 0, VmTmp) <> 0 Then
          FileTimeToDosDateTime(VmTmp, LongInt(@D), LongInt(@T));
        VS(fEcx, T); VS(fEdx, D);
      End
      Else If AL = 1 Then
      Begin
        DosDateTimeToFileTime(VR(fEdx), VR(fEcx), VmTmp);
        SetFileTime(SftH[S], 0, 0, VmTmp);
      End
      Else VmFail(1);
    End;
    $58 :
      Case AL Of
        0 : VS(fEax, VmStrat);
        1 : VmStrat := VR(fEbx);
        2 : VSL(fEax, 0);
        3 : ;
      Else
        VmFail(1);
      End;
    $59 :
    Begin
      VS(fEax, VmLastErr);
      VS(fEbx, $0D01);
      VSH(fEcx, 1);
    End;
    $5C : ;
    $60 :
    Begin
      Path := VmFullPath(PStr(VmPtr(fDs, fEsi)));
      PutPStr(VmPtr(fEs, fEdi), Path, 128);
    End;
    $63 :
    Begin
      VSeg(fDs, VmDosSeg);
      VS(fEsi, VmDbcsO);
      VSL(fEax, 0);
    End;
    $65 : VmCountryX;
    $66 :
    Begin
      VS(fEbx, 437);
      VS(fEdx, 437);
    End;
    $67 :
    Begin
      N := VR(fEbx);
      P := VmLin(VmCurPsp, 0);
      If N <= MemW[0:P + $32] Then
      Begin
        If N < 20 Then N := 20;
      End
      Else
      Begin
        D := McbAlloc((N + 15) Shr 4, VmCurPsp, Max);
        If D = 0 Then VmFail(8)
        Else
        Begin
          FillMem(VmLin(D, 0), N, $FF);
          MoveMem(VmLin(MemW[0:P + $36], MemW[0:P + $34]), VmLin(D, 0),
                  MemW[0:P + $32]);
          MemW[0:P + $32] := N;
          MemW[0:P + $34] := 0; MemW[0:P + $36] := D;
        End;
      End;
    End;
    $68, $6A :
    Begin
      S := VmSftOf(VR(fEbx));
      If S < 0 Then VmFail(6)
      Else If SftDev[S] = 0 Then FlushFileBuffers(SftH[S]);
    End;
    $69 :
      If AL = 0 Then
      Begin
        P := VmPtr(fDs, fEdx);
        MemW[0:P] := 0; MemL[0:P + 2] := $1995095;
        PutPStr(VmTmp + 800, 'NO NAME    FAT16   ', 20);
        MoveMem(VmTmp + 800, P + 6, 19);
      End;
    $6C :
    Begin
      Path := VmPathAt(VmPtr(fDs, fEsi), 0);
      D := VR(fEdx);
      If GetFileAttributesA(VmTmp) <> -1 Then
      Begin
        Case D And 3 Of
          1 :
          Begin
            N := 3; R := 1;
          End;
          2 :
          Begin
            N := 2; R := 3;
          End;
        Else
          N := 0;
        End;
      End
      Else If (D And $10) <> 0 Then
      Begin
        N := 1; R := 2;
      End
      Else N := -1;
      If N = 0 Then VmFail(80)
      Else If N < 0 Then VmFail(2)
      Else
      Begin
        VmOpenH(Path, VRL(fEbx), N);
        If (MemL[0:VmF + fFl] And 1) = 0 Then VS(fEcx, R);
      End;
    End;
    $71 : VmFail($7100);
    $73 : VmFail($7300);
  Else
    VmFail(1);
  End;
End;

{ ------------------------------------------------------------------ }

{ Souris (INT 33h) : pointeur texte dans la console                  }
{ ------------------------------------------------------------------ }

Procedure VmMouReset;
Var I : LongInt;
Begin
  VmMouHide;
  VmMouShow := -1;
  VmMouMinX := 0; VmMouMaxX := 639; VmMouMinY := 0; VmMouMaxY := 199;
  { plage verticale du mode video (ecran graphique de 350 ou 480 lignes) }
  If VmGfx And (VgH > 200) Then VmMouMaxY := VgH - 1;
  VmMouX := 320; VmMouY := (VmMouMaxY + 1) Div 2;
  VmMouMask := 0; VmMouSeg := 0; VmMouOfs := 0; VmMouEv := 0;
  VmMouMkX := 0; VmMouMkY := 0;
  For I := 0 To 2 Do
  Begin
    VmMouPress[I] := 0; VmMouRel[I] := 0;
  End;
End;

Procedure VmMouClip;
Begin
  If VmMouX < VmMouMinX Then VmMouX := VmMouMinX;
  If VmMouX > VmMouMaxX Then VmMouX := VmMouMaxX;
  If VmMouY < VmMouMinY Then VmMouY := VmMouMinY;
  If VmMouY > VmMouMaxY Then VmMouY := VmMouMaxY;
End;

{ Paquet de la souris PS/2 (interruption du noyau, session de la
  machine au premier plan) : deplacement (mickeys, Y vers le bas) et
  boutons (1 gauche, 2 droit, 4 milieu) ; aucun acces a la memoire de la
  machine (une autre session peut etre projetee) }
Procedure DosMouIn(Dx, Dy, Btn : LongInt);
Var Ev, I, Ch : LongInt;
Begin
  If Not VmOn Then Exit;
  Ev := 0;
  If (Dx <> 0) Or (Dy <> 0) Then
  Begin
    VmMouMkX := VmMouMkX + Dx;
    VmMouMkY := VmMouMkY + Dy;
    VmMouX := VmMouX + Dx;
    VmMouY := VmMouY + Dy;
    VmMouClip;
    Ev := 1;
  End;
  Btn := Btn And 7;
  Ch := Btn Xor VmMouBtn;
  For I := 0 To 2 Do
    If (Ch And (1 Shl I)) <> 0 Then
    Begin
      If (Btn And (1 Shl I)) <> 0 Then
      Begin
        If I = 0 Then Ev := Ev Or 2 Else If I = 1 Then Ev := Ev Or 8 Else Ev := Ev Or $20;
        Inc(VmMouPress[I]);
        VmMouPX[I] := VmMouX; VmMouPY[I] := VmMouY;
      End
      Else
      Begin
        If I = 0 Then Ev := Ev Or 4 Else If I = 1 Then Ev := Ev Or $10 Else Ev := Ev Or $40;
        Inc(VmMouRel[I]);
        VmMouRX[I] := VmMouX; VmMouRY[I] := VmMouY;
      End;
    End;
  VmMouBtn := Btn;
  VmMouEv := VmMouEv Or Ev;
End;

{ Appeler le gestionnaire d'evenements du programme (fonction 0Ch) }
Function VmMouCall : Boolean;
Var Ev : LongInt;
Begin
  VmMouCall := False;
  Ev := VmMouEv And VmMouMask;
  If (Ev = 0) Or (VmMouBusy <> 0) Or ((VmMouSeg = 0) And (VmMouOfs = 0))
  Then
  Begin
    If VmMouBusy = 0 Then VmMouEv := 0;
    Exit;
  End;
  VmMouEv := 0;
  MoveMem(VmF, LongInt(@VmMouSave), 68);
  VmMouBusy := 1 + Ord(VmIF);
  VS(fEax, Ev); VS(fEbx, VmMouBtn); VS(fEcx, VmMouX); VS(fEdx, VmMouY);
  VS(fEsi, VmMouMkX); VS(fEdi, VmMouMkY);
  VmPush(VmBios); VmPush(VmMRetO);
  VmGoto(VmMouSeg, VmMouOfs);
  VmIF := False;
  VmMouCall := True;
End;

Procedure VmInt33;
Var AX, B : LongInt;
Begin
  AX := VR(fEax);
  Case AX Of
    $00, $21 :
    Begin
      VmMouReset;
      VS(fEax, $FFFF);
      VS(fEbx, 2);
    End;
    $01 :
    Begin
      If VmMouShow < 0 Then Inc(VmMouShow);
      VmMouDraw;
    End;
    $02 :
    Begin
      Dec(VmMouShow);
      VmMouDraw;
    End;
    $03 :
    Begin
      VS(fEbx, VmMouBtn); VS(fEcx, VmMouX); VS(fEdx, VmMouY);
      VmIdle;
    End;
    $04 :
    Begin
      VmMouX := VR(fEcx) And Not 7; VmMouY := VR(fEdx) And Not 7;
      VmMouClip;
      VmMouDraw;
    End;
    $05, $06 :
    Begin
      B := VR(fEbx);
      If B > 2 Then B := 0;
      VS(fEax, VmMouBtn);
      If AX = 5 Then
      Begin
        VS(fEbx, VmMouPress[B]); VS(fEcx, VmMouPX[B]);
        VS(fEdx, VmMouPY[B]);
        VmMouPress[B] := 0;
      End
      Else
      Begin
        VS(fEbx, VmMouRel[B]); VS(fEcx, VmMouRX[B]);
        VS(fEdx, VmMouRY[B]);
        VmMouRel[B] := 0;
      End;
    End;
    $07 :
    Begin
      VmMouMinX := Min(VR(fEcx), VR(fEdx));
      VmMouMaxX := Max(VR(fEcx), VR(fEdx));
      VmMouClip;
    End;
    $08 :
    Begin
      VmMouMinY := Min(VR(fEcx), VR(fEdx));
      VmMouMaxY := Max(VR(fEcx), VR(fEdx));
      VmMouClip;
    End;
    $0B :
    Begin
      VS(fEcx, VmMouMkX); VS(fEdx, VmMouMkY);
      VmMouMkX := 0; VmMouMkY := 0;
    End;
    $0C :
    Begin
      VmMouMask := VR(fEcx); VmMouSeg := VR(fEs); VmMouOfs := VR(fEdx);
    End;
    $14 :
    Begin
      B := VmMouMask; VmMouMask := VR(fEcx); VS(fEcx, B);
      B := VmMouSeg; VmMouSeg := VR(fEs); VSeg(fEs, B);
      B := VmMouOfs; VmMouOfs := VR(fEdx); VS(fEdx, B);
    End;
    $15 : VS(fEbx, 16);
    $1B :
    Begin
      VS(fEbx, 50); VS(fEcx, 50); VS(fEdx, 50);
    End;
    $1D, $1E : VS(fEbx, 0);
    $24 :
    Begin
      VS(fEbx, $0626); VS(fEcx, $0400);
    End;
    $26 :
    Begin
      VS(fEbx, 0); VS(fEcx, 639); VS(fEdx, 199);
    End;
  End;
End;

{ ------------------------------------------------------------------ }

{ Multiplexage (INT 2Fh) et ports d'E/S                              }
{ ------------------------------------------------------------------ }

Procedure VmInt2F;
Var AX : LongInt;
Begin
  AX := VR(fEax);
  Case AX Of
    $1600 : VSL(fEax, 0);
    $1680 :
    Begin
      VSL(fEax, 0);
      VmSleep(1);
    End;
    $1689 : VmSleep(1);
    $4300 : VSL(fEax, $80);
    $4310 :
    Begin
      VSeg(fEs, VmBios); VS(fEbx, VmXmsO);
    End;
    $1687 :
    Begin
      { serveur DPMI : 32 bits, processeur 486, version 0.90 }
      VS(fEax, 0); VS(fEbx, 1); VSL(fEcx, 4); VS(fEdx, $005A);
      VS(fEsi, $100); VSeg(fEs, VmBios); VS(fEdi, VmDpmiO);
    End;
    $4A01, $4A02 :
    Begin
      VS(fEbx, 0);
      VSeg(fEs, $FFFF); VS(fEdi, $FFFF);
    End;
    $1A00, $B700, $1100, $0800, $AD00, $1000 : VSL(fEax, 0);
  End;
End;

Function VmIn(Pt : LongInt) : LongInt;
Var V : LongInt;
Begin
  { carte VGA de la session au premier plan : le materiel }
  If (Pt >= $3B0) And (Pt <= $3DF) And VmIsFg Then
  Begin
    If (Pt = $3DA) Or (Pt = $3BA) Then VmAttrFF := 0;
    VmIn := Port[Pt];
    Exit;
  End;
  V := $FF;
  Case Pt Of
    $20 : V := 0;
    $21 : V := VmPicMask;
    $A0, $A1 : V := 0;
    $40 :
    Begin
      If VmPitMode = 0 Then
      Begin
        VmPitLatch := (VmPitDiv - ((VmMsNow * 1193 + VmPitAcc) Mod VmPitDiv))
                      And $FFFF;
        VmPitMode := 1;
        V := VmPitLatch And $FF;
      End
      Else
      Begin
        V := (VmPitLatch Shr 8) And $FF;
        VmPitMode := 0;
      End;
    End;
    $60 : V := VmPort60;
    $61 :
    Begin
      VmPort61 := VmPort61 Xor $10;
      V := VmPort61;
    End;
    $64 : V := $1C;
    $3C1 : V := VgAc[VgAcI And 31];
    $3C4 : V := VgSeqI;
    $3C5 : V := VgSeq[VgSeqI And 7];
    $3CE : V := VgGcI;
    $3CF : If VgGcI <= 8 Then V := VgGc[VgGcI];
    $3C9 :
    Begin
      V := VmDac[VmDacRd Mod 768];
      VmDacRd := (VmDacRd + 1) Mod 768;
    End;
    $3CC : V := $67;
    $3D5 :
      Case VmCrtIdx Of
        $0A : V := Mem[0:VmBda($61)];
        $0B : V := Mem[0:VmBda($60)];
        $0E, $0F :
        Begin
          V := Mem[0:VmBda($51)] * 80 + Mem[0:VmBda($50)];
          If VmCrtIdx = $0E Then V := V Shr 8 Else V := V And $FF;
        End;
      Else
        V := 0;
      End;
    $3D4 : V := VmCrtIdx;
    $3DA, $3BA :
    Begin
      VmRetr := VmRetr Xor 9;
      VmAttrFF := 0;
      V := VmRetr;
    End;
  End;
  VmIn := V;
End;

Procedure VmOut(Pt, V : LongInt);
Var P : LongInt;
Begin
  V := V And $FF;
  If VmIsFg Then
  Begin
    { carte VGA et haut-parleur (canal 2 de la minuterie, port 61h) }
    If (Pt >= $3B0) And (Pt <= $3DF) Then Port[Pt] := V
    Else If Pt = $42 Then Port[$42] := V
    Else If (Pt = $43) And ((V And $C0) = $80) Then
    Begin
      Port[$43] := V;
      Exit;
    End
    Else If Pt = $61 Then Port[$61] := (Port[$61] And $FC) Or (V And 3);
  End;
  Case Pt Of
    $20 :
      If V = $20 Then
      Begin
        If (VmIsr And 1) <> 0 Then VmIsr := VmIsr And Not 1
        Else VmIsr := VmIsr And Not 2;
      End
      Else If (V And $F8) = $60 Then VmIsr := VmIsr And Not (1 Shl (V And 7));
    $21 : VmPicMask := V;
    $43 :
      If (V And $C0) = 0 Then
      Begin
        If (V And $30) = 0 Then VmPitMode := 0
        Else VmPitMode := 2;
      End;
    $40 :
      If VmPitMode = 2 Then
      Begin
        VmPitLo := V;
        VmPitMode := 3;
      End
      Else If VmPitMode = 3 Then
      Begin
        VmPitDiv := VmPitLo Or (V Shl 8);
        If VmPitDiv = 0 Then VmPitDiv := 65536;
        If VmPitDiv < 1193 Then VmPitDiv := 1193;
        VmPitMode := 0;
      End;
    $61 : VmPort61 := V;
    $3D4 : VmCrtIdx := V;
    $3D5 :
      Case VmCrtIdx Of
        $0A : Mem[0:VmBda($61)] := V;
        $0B : Mem[0:VmBda($60)] := V;
        $0E, $0F :
        Begin
          P := Mem[0:VmBda($51)] * 80 + Mem[0:VmBda($50)];
          If VmCrtIdx = $0E Then P := (P And $FF) Or (V Shl 8)
          Else P := (P And $FF00) Or V;
          If P < 2000 Then VmSetCur(0, P Mod 80, P Div 80);
        End;
        $0C, $0D :
        Begin
          If VmCrtIdx = $0C Then VgStart := (VgStart And $FF) Or (V Shl 8)
          Else VgStart := (VgStart And $FF00) Or V;
          VgDLo := 0; VgDHi := VgH - 1;
        End;
      End;
    $3C7 :
    Begin
      VmDacRd := V * 3;
    End;
    $3C8 :
    Begin
      VmDacIdx := V * 3;
    End;
    $3C9 :
    Begin
      VmDac[VmDacIdx Mod 768] := V And $3F;
      VmDacIdx := (VmDacIdx + 1) Mod 768;
      VgPalDirty := True;
    End;
    $3C0 :
    Begin
      If VmAttrFF = 0 Then VgAcI := V And $1F
      Else If VgAcI <= 20 Then
      Begin
        VgAc[VgAcI] := V;
        VgPalDirty := True;
      End;
      VmAttrFF := VmAttrFF Xor 1;
    End;
    $3C4 : VgSeqI := V;
    $3C5 : VgSeq[VgSeqI And 7] := V;
    $3CE : VgGcI := V;
    $3CF : If VgGcI <= 8 Then VgGc[VgGcI] := V;
  End;
End;

{ ------------------------------------------------------------------ }
{ Moniteur : fautes du mode V86                                      }
{ ------------------------------------------------------------------ }

Procedure VmCrash(Const Why : String);
Var S, B : String; I : LongInt;
Begin
  S := HexStr(VR(fCs), 4) + ':' + HexStr(VR(fEip), 4);
  VmLog('DOS : ' + Why + ' en ' + S);
  B := '';
  For I := -8 To 7 Do
    B := B + HexStr(Mem[0:VmLin(VR(fCs), VR(fEip) + I)], 2) + ' ';
  VmLog('  ' + VmRegStr);
  VmLog('  code ' + B);
  VmConStr(#13#10 + 'OS/2-0 (session DOS) : ' + Why + ' en ' + S + #13#10);
  VmTerminate(255, False, 0);
End;

Function VmCode(Cs, Ip : LongInt) : LongInt;
Begin
  VmCode := Mem[0:VmLin(Cs, Ip)];
End;

{ ------------------------------------------------------------------ }

{ Instructions d'E/S : IN, OUT, INS, OUTS }
Procedure VmPortOp(Op, Cs, Ip, N : LongInt; O32, Rep : Boolean);
Var Port, Sz, Cnt, I, V, Di, Si, K : LongInt;
Begin
  If Op In [$E4..$E7] Then
  Begin
    Port := VmCode(Cs, Ip + N);
    Inc(N);
  End
  Else Port := VR(fEdx);
  If Op In [$E4, $E6, $EC, $EE, $6C, $6E] Then Sz := 1
  Else If O32 Then Sz := 4 Else Sz := 2;
  Case Op Of
    $E4, $E5, $EC, $ED :
    Begin
      V := 0;
      For K := 0 To Sz - 1 Do V := V Or (VmIn(Port + K) Shl (K * 8));
      If Sz = 1 Then VSL(fEax, V)
      Else If Sz = 2 Then VS(fEax, V)
      Else MemL[0:VmF + fEax] := V;
    End;
    $E6, $E7, $EE, $EF :
    Begin
      V := MemL[0:VmF + fEax];
      For K := 0 To Sz - 1 Do VmOut(Port + K, V Shr (K * 8));
    End;
    $6C, $6D, $6E, $6F :
    Begin
      If Rep Then Cnt := VR(fEcx) Else Cnt := 1;
      For I := 1 To Cnt Do
      Begin
        If Op In [$6C, $6D] Then
        Begin
          Di := VR(fEdi);
          For K := 0 To Sz - 1 Do
            Mem[0:VmLin(VR(fEs), Di + K)] := VmIn(Port + K);
          If (MemL[0:VmF + fFl] And $400) <> 0 Then VS(fEdi, Di - Sz)
          Else VS(fEdi, Di + Sz);
        End
        Else
        Begin
          Si := VR(fEsi);
          For K := 0 To Sz - 1 Do
            VmOut(Port + K, Mem[0:VmLin(VR(fDs), Si + K)]);
          If (MemL[0:VmF + fFl] And $400) <> 0 Then VS(fEsi, Si - Sz)
          Else VS(fEsi, Si + Sz);
        End;
      End;
      If Rep Then VS(fEcx, 0);
    End;
  End;
  MemL[0:VmF + fEip] := (Ip + N) And $FFFF;
End;

Function VmHostRm(Ip : LongInt) : Boolean; Forward;

{ Faute de protection generale : instruction sensible a emuler }
Procedure VmGp;
Var Cs, Ip, N, Op, V : LongInt; O32, Rep : Boolean;
Begin
  Cs := VR(fCs); Ip := VR(fEip);
  N := 0; O32 := False; Rep := False;
  Repeat
    Op := VmCode(Cs, Ip + N);
    Inc(N);
    Case Op Of
      $66 : O32 := True;
      $F2, $F3 : Rep := True;
      $26, $2E, $36, $3E, $64, $65, $67, $F0 : ;
    Else
      Break;
    End;
  Until N > 14;
  Case Op Of
    $CD :
    Begin
      V := VmCode(Cs, Ip + N);
      MemL[0:VmF + fEip] := (Ip + N + 1) And $FFFF;
      VmInt(V);
    End;
    $CC :
    Begin
      MemL[0:VmF + fEip] := (Ip + N) And $FFFF;
      VmInt(3);
    End;
    $CE :
    Begin
      MemL[0:VmF + fEip] := (Ip + N) And $FFFF;
      If (MemL[0:VmF + fFl] And $800) <> 0 Then VmInt(4);
    End;
    $CF :
    Begin
      If O32 Then
      Begin
        V := VmPop; VmPop;
        VmGoto(VmPop, V); VmPop;
        V := VmPop; VmPop;
        VmLoadFlags(V);
      End
      Else
      Begin
        V := VmPop; VmGoto(VmPop, V);
        VmLoadFlags(VmPop);
      End;
    End;
    $9C :
    Begin
      MemL[0:VmF + fEip] := (Ip + N) And $FFFF;
      If O32 Then VmPush(0);
      VmPush(VmVFlags);
    End;
    $9D :
    Begin
      MemL[0:VmF + fEip] := (Ip + N) And $FFFF;
      V := VmPop;
      If O32 Then VmPop;
      VmLoadFlags(V);
    End;
    $FA :
    Begin
      MemL[0:VmF + fEip] := (Ip + N) And $FFFF;
      VmIF := False;
    End;
    $FB :
    Begin
      MemL[0:VmF + fEip] := (Ip + N) And $FFFF;
      VmIF := True;
    End;
    $F4 :
      If (Cs = VmBios) And (Ip >= VmStubO) And (Ip < VmStubO + 256) Then
        VmService(Ip - VmStubO)
      Else If (Cs = VmBios) And (Ip = VmExitO) Then VmQuit(VmRetCode)
      Else If (Cs = VmBios) And (Ip = VmMRetO) Then
      Begin
        MoveMem(LongInt(@VmMouSave), VmF, 68);
        VmIF := VmMouBusy = 2;
        VmMouBusy := 0;
      End
      Else If VmIsShell(Cs, Ip) Then VmShell
      Else If (Cs = VmBios) And VmHostRm(Ip) Then
      Else If (Cs = VmBios) And (Ip = VmCpmO) Then
      Begin
        { CALL 5 : fonction CL du DOS, puis retour a l'appelant }
        VmPop;
        V := VmPop;
        VmGoto(V, VmPop);
        VSH(fEax, VRL(fEcx));
        VmPush(VmVFlags); VmPush(VR(fCs)); VmPush(VR(fEip));
        VmService($21);
      End
      Else
      Begin
        MemL[0:VmF + fEip] := (Ip + N) And $FFFF;
        If VmIF Then
          While Not VmIrqPending And (VmMouEv And VmMouMask = 0) Do
            VmSleep(1);
      End;
    $E4..$E7, $EC..$EF, $6C..$6F : VmPortOp(Op, Cs, Ip, N, O32, Rep);
  Else
    VmCrash('instruction ' + HexStr(Op, 2) + 'h non geree');
  End;
End;

{ Unite Crt de Turbo Pascal 7 (et 6) : l'etalonnage de Delay divise
  par 55 le nombre de tours de boucle d'un top d'horloge (NOT AX, NOT
  DX, MOV CX,55, DIV CX) ; sur un processeur rapide le quotient depasse
  16 bits et le programme s'arretait sur l'erreur 200 (Division by
  zero). Le quotient est ici limite a FFFFh, comme le font les
  correctifs de l'unite Crt. }
Function VmCrtPat(I : LongInt) : LongInt;
Begin
  Case I Of
    0 : VmCrtPat := $F7; 1 : VmCrtPat := $D0; 2 : VmCrtPat := $F7;
    3 : VmCrtPat := $D2; 4 : VmCrtPat := $B9; 5 : VmCrtPat := $37;
    6 : VmCrtPat := $00; 7 : VmCrtPat := $F7;
  Else
    VmCrtPat := $F1;
  End;
End;

Function VmCrtFix : Boolean;
Var Cs, Ip, I : LongInt;
Begin
  VmCrtFix := False;
  Cs := VR(fCs); Ip := VR(fEip);
  For I := 0 To 8 Do
    If VmCode(Cs, Ip - 7 + I) <> VmCrtPat(I) Then Exit;
  VS(fEax, $FFFF);
  VS(fEdx, 0);
  MemL[0:VmF + fEip] := (Ip + 2) And $FFFF;
  VmCrtFix := True;
End;

{ Selecteur de segment valide pour l'anneau 3 (sinon 0) }
Function VmSelOk(S : LongInt) : LongInt;
Begin
  S := S And $FFFF;
  If ((S And 7) = 7) And SelValid(S) Then VmSelOk := S
  Else If (S And $FFF8) = $40 Then VmSelOk := S
  Else VmSelOk := 0;
End;

{ Cadre des souches (EDI en F) -> contexte VmCtx }
Procedure VmLoadCtx(F : LongInt);
Begin
  MoveMem(F, LongInt(@VmCtx), 32);
  If (MemL[0:F + 56] And $20000) <> 0 Then
  Begin
    VmPM := False;
    MoveMem(F + 48, LongInt(@VmCtx) + 32, 36);
  End
  Else
  Begin
    VmPM := True;
    MoveMem(F + 64, LongInt(@VmCtx) + 32, 20);
    VmCtx[13] := MemL[0:F + 40] And $FFFF;
    VmCtx[14] := MemL[0:F + 44] And $FFFF;
    VmCtx[15] := MemL[0:F + 36] And $FFFF;
    VmCtx[16] := MemL[0:F + 32] And $FFFF;
  End;
End;

{ Contexte -> cadre de sortie, selon le mode (V86 ou anneau 3) }
Procedure VmStoreCtx(F : LongInt);
Var Fl : LongInt;
Begin
  MoveMem(LongInt(@VmCtx), F, 32);
  Fl := (VmCtx[10] And $FFFFF And Not $27000) Or $202;
  If VmPM Then
  Begin
    MemL[0:F + 32] := VmSelOk(VmCtx[16]);
    MemL[0:F + 36] := VmSelOk(VmCtx[15]);
    MemL[0:F + 40] := VmSelOk(VmCtx[13]);
    MemL[0:F + 44] := VmSelOk(VmCtx[14]);
    FillMem(F + 48, 16, 0);
    MemL[0:F + 64] := VmCtx[8];
    MemL[0:F + 68] := VmCtx[9] And $FFFF;
    MemL[0:F + 72] := Fl;
    MemL[0:F + 76] := VmCtx[11];
    MemL[0:F + 80] := VmCtx[12] And $FFFF;
    VmPad := 16;
    If VmTrace And False Then
      VmLog('PM : ' + HexStr(MemL[0:F + 64], 8) + ' ' +
           HexStr(MemL[0:F + 68], 8) + ' ' + HexStr(MemL[0:F + 72], 8) +
           ' ' + HexStr(MemL[0:F + 76], 8) + ' ' + HexStr(MemL[0:F + 80], 8) +
           ' ds ' + HexStr(MemL[0:F + 44], 4) + ' es ' +
           HexStr(MemL[0:F + 40], 4) + ' F=' + HexStr(F, 8));
  End
  Else
  Begin
    FillMem(F + 32, 16, 0);
    MemL[0:F + 48] := VmCtx[8] And $FFFF;
    MemL[0:F + 52] := VmCtx[9] And $FFFF;
    MemL[0:F + 56] := Fl Or $20000;
    MemL[0:F + 60] := VmCtx[11] And $FFFF;
    MemL[0:F + 64] := VmCtx[12] And $FFFF;
    MemL[0:F + 68] := VmCtx[13] And $FFFF;
    MemL[0:F + 72] := VmCtx[14] And $FFFF;
    MemL[0:F + 76] := VmCtx[15] And $FFFF;
    MemL[0:F + 80] := VmCtx[16] And $FFFF;
    VmPad := 0;
  End;
End;

Procedure VmPmTrap; Forward;
Procedure VmPostTrap; Forward;

{ Point d'entree des souches : faute ou trappe du mode V86, ou du
  client DPMI en anneau 3 }
Procedure V86Trap(F : LongInt);
Begin
  VmLoadCtx(F);
  VmF := LongInt(@VmCtx);
  asm
    sti
  end;
  { programme en mode graphique a l'arriere-plan : suspendu }
  If VmGfx And (FgSess <> VmSess) Then VmFgWait;
  If VmPM Then VmPmTrap
  Else
    Case VmVec Of
      0 : If Not VmCrtFix Then VmInt(0);
      13 : VmGp;
      14 :
        VmCrash('acces a la memoire hors de la machine (' +
                HexStr(GetCr2, 8) + ')');
      6 : VmCrash('code d''operation invalide');
      7, 10, 11, 12, 16, 17 : VmCrash('exception ' + IntStr(VmVec));
    Else
      VmInt(VmVec);
    End;
  VmPostTrap;
  asm
    cli
  end;
  VmStoreCtx(F);
End;

{ ------------------------------------------------------------------ }

{ Memoire etendue XMS 3.0 (pilote HIMEM.SYS)                         }
{ ------------------------------------------------------------------ }
{ INT 2Fh AX=4300h annonce le pilote, AX=4310h donne son point d'entree
  (F000:VmXmsO, un HLT appele par CALL FAR). Les blocs (EMB) sont pris
  dans le tas du noyau ; leur adresse lineaire (verrouillage, fonction
  0Ch) est aussi leur adresse physique. Pas de HMA ni d'UMB : la zone
  haute de la machine est occupee par le noyau, et le DOS est en bas. }

Const
  XmsMax = 32;
  XmsCapKB = 16384;              { 16 Mo au plus pour la machine }

Var
  XmsLin, XmsKB, XmsLck : Array[0..XmsMax - 1] Of LongInt;  { KB -1 : libre }

Procedure XmsReset;
Var I : LongInt;
Begin
  For I := 0 To XmsMax - 1 Do
  Begin
    XmsKB[I] := -1; XmsLin[I] := 0; XmsLck[I] := 0;
  End;
End;

Function XmsUsedKB : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To XmsMax - 1 Do If XmsKB[I] > 0 Then N := N + XmsKB[I];
  XmsUsedKB := N;
End;

{ Memoire libre pour les blocs : le plafond, et ce que le tas peut
  donner en gardant 8 Mo au systeme }
Function XmsFreeKB : LongInt;
Var N : LongInt;
Begin
  N := XmsCapKB - XmsUsedKB;
  If N > VmMemFree Div 1024 - 8192 Then N := VmMemFree Div 1024 - 8192;
  If N < 0 Then N := 0;
  XmsFreeKB := N;
End;

Function XmsHandle(H : LongInt) : LongInt;
Begin
  H := (H And $FFFF) - 1;
  If (H >= 0) And (H < XmsMax) And (XmsKB[H] >= 0) Then XmsHandle := H
  Else XmsHandle := -1;
End;

Function XmsAlloc(KB : LongInt; Var H : LongInt) : LongInt;
Var I, A, Own : LongInt;
Begin
  XmsAlloc := $A1;
  H := -1;
  For I := 0 To XmsMax - 1 Do
    If XmsKB[I] < 0 Then
    Begin
      H := I;
      Break;
    End;
  If H < 0 Then Exit;
  XmsAlloc := $A0;
  If KB > XmsFreeKB Then Exit;
  A := 0;
  If KB > 0 Then
  Begin
    Own := VmHeapOwn; VmHeapOwn := 1;
    A := VmKAlloc(KB * 1024);
    VmHeapOwn := Own;
    If A = 0 Then Exit;
  End;
  XmsKB[H] := KB; XmsLin[H] := A; XmsLck[H] := 0;
  XmsAlloc := 0;
End;

{ Adresse (noyau) de l'octet Ofs d'un bloc (H = 0 : Seg:Ofs de la
  machine) ; 0 si hors du bloc }
Function XmsAddr(H, Ofs, Len : LongInt) : LongInt;
Var K : LongInt;
Begin
  XmsAddr := 0;
  If H = 0 Then
  Begin
    XmsAddr := VmLin(Ofs Shr 16, Ofs And $FFFF);
    Exit;
  End;
  K := XmsHandle(H);
  If K < 0 Then Exit;
  If (Ofs < 0) Or (Len < 0) Or (Ofs + Len > XmsKB[K] * 1024) Then Exit;
  XmsAddr := XmsLin[K] + Ofs;
End;

Procedure XOk;
Begin
  VS(fEax, 1);
End;

Procedure XFail(E : LongInt);
Begin
  VS(fEax, 0);
  VSL(fEbx, E);
End;

{ Appel du pilote : AH = fonction ; AX = 1 succes, 0 et BL = erreur }
Procedure VmXms;
Var AH, K, H, N, P, Len, Src, Dst, A, B : LongInt;
Begin
  AH := VRH(fEax);
  Case AH Of
    $00 :
    Begin
      VS(fEax, $0300); VS(fEbx, $0301); VS(fEdx, 0);
    End;
    $01, $02 : XFail($91);
    $03, $04, $05, $06 :
    Begin
      XOk; VSL(fEbx, 0);
    End;
    $07 :
    Begin
      XOk; VSL(fEbx, 0);
    End;
    $08, $88 :
    Begin
      N := XmsFreeKB;
      If AH = $08 Then
      Begin
        VS(fEax, Min(N, $FFFF)); VS(fEdx, Min(N, $FFFF));
      End
      Else
      Begin
        MemL[0:VmF + fEax] := N; MemL[0:VmF + fEdx] := N;
        MemL[0:VmF + fEcx] := PhysTop - 1;
      End;
      If N = 0 Then VSL(fEbx, $A0) Else VSL(fEbx, 0);
    End;
    $09, $89 :
    Begin
      If AH = $09 Then N := VR(fEdx) Else N := MemL[0:VmF + fEdx];
      K := XmsAlloc(N, H);
      If K <> 0 Then XFail(K)
      Else
      Begin
        XOk; VS(fEdx, H + 1);
      End;
    End;
    $0A :
    Begin
      K := XmsHandle(VR(fEdx));
      If K < 0 Then XFail($A2)
      Else If XmsLck[K] > 0 Then XFail($AB)
      Else
      Begin
        If XmsLin[K] <> 0 Then VmKFree(XmsLin[K]);
        XmsKB[K] := -1; XmsLin[K] := 0;
        XOk;
      End;
    End;
    $0B :
    Begin
      { DS:SI : longueur, poignee source, decalage, poignee but, decalage }
      P := VmPtr(fDs, fEsi);
      Len := MemL[0:P];
      Src := XmsAddr(MemW[0:P + 4], MemL[0:P + 6], Len);
      Dst := XmsAddr(MemW[0:P + 10], MemL[0:P + 12], Len);
      If (Len And 1) <> 0 Then XFail($A7)
      Else If (MemW[0:P + 4] <> 0) And (XmsHandle(MemW[0:P + 4]) < 0) Then
        XFail($A3)
      Else If (MemW[0:P + 10] <> 0) And (XmsHandle(MemW[0:P + 10]) < 0) Then
        XFail($A5)
      Else If Src = 0 Then XFail($A4)
      Else If Dst = 0 Then XFail($A6)
      Else
      Begin
        MoveMem(Src, Dst, Len);
        XOk;
      End;
    End;
    $0C :
    Begin
      K := XmsHandle(VR(fEdx));
      If K < 0 Then XFail($A2)
      Else
      Begin
        Inc(XmsLck[K]);
        XOk;
        VS(fEdx, XmsLin[K] Shr 16); VS(fEbx, XmsLin[K]);
      End;
    End;
    $0D :
    Begin
      K := XmsHandle(VR(fEdx));
      If K < 0 Then XFail($A2)
      Else If XmsLck[K] = 0 Then XFail($AA)
      Else
      Begin
        Dec(XmsLck[K]);
        XOk;
      End;
    End;
    $0E, $8E :
    Begin
      K := XmsHandle(VR(fEdx));
      If K < 0 Then XFail($A2)
      Else
      Begin
        N := 0;
        For H := 0 To XmsMax - 1 Do If XmsKB[H] < 0 Then Inc(N);
        XOk;
        VSH(fEbx, XmsLck[K]);
        If AH = $0E Then
        Begin
          VSL(fEbx, N); VS(fEdx, XmsKB[K]);
        End
        Else
        Begin
          VS(fEcx, N); MemL[0:VmF + fEdx] := XmsKB[K];
        End;
      End;
    End;
    $0F, $8F :
    Begin
      K := XmsHandle(VR(fEdx));
      If AH = $0F Then N := VR(fEbx) Else N := MemL[0:VmF + fEbx];
      If K < 0 Then XFail($A2)
      Else If XmsLck[K] > 0 Then XFail($AB)
      Else If N - XmsKB[K] > XmsFreeKB Then XFail($A0)
      Else
      Begin
        A := 0;
        If N > 0 Then
        Begin
          B := VmHeapOwn; VmHeapOwn := 1;
          A := VmKAlloc(N * 1024);
          VmHeapOwn := B;
        End;
        If (N > 0) And (A = 0) Then XFail($A0)
        Else
        Begin
          If (A <> 0) And (XmsLin[K] <> 0) Then
            MoveMem(XmsLin[K], A, Min(N, XmsKB[K]) * 1024);
          If XmsLin[K] <> 0 Then VmKFree(XmsLin[K]);
          XmsLin[K] := A; XmsKB[K] := N;
          XOk;
        End;
      End;
    End;
    $10 :
    Begin
      XFail($B1); VS(fEdx, 0);
    End;
    $11, $12 : XFail($B2);
  Else
    XFail($80);
  End;
End;

{ ------------------------------------------------------------------ }
{ Memoire paginee EMS 4.0 (LIM, pilote EMM386)                       }
{ ------------------------------------------------------------------ }
{ Le cadre de pages de 64 Ko est en E000h (4 pages physiques de 16 Ko).
  Les pages logiques sont prises dans un bloc de 4 Mo du tas ; projeter
  une page (fonctions 44h, 50h, restauration des contextes) change
  simplement les 4 entrees de la table de pages de la machine : aucune
  copie, et le programme voit directement la page. Le nom du pilote
  (EMMXXXX0) est dans l'en-tete de peripherique en F000:000Ah, ou pointe
  le vecteur 67h, et s'ouvre comme fichier (peripherique). }

Const
  EmsPages = 256;                { 4 Mo }
  EmsHMax = 64;
  EmsFrame = $E000;

Var
  EmsPool, EmsPoolBlk : LongInt;
  EmsPgH, EmsPgL : Array[0..EmsPages - 1] Of LongInt;   { H -1 : libre }
  EmsHUsed : Array[0..EmsHMax - 1] Of Boolean;
  EmsHName : Array[0..EmsHMax - 1] Of String[8];
  EmsHSaved : Array[0..EmsHMax - 1] Of Boolean;
  EmsSvH, EmsSvL : Array[0..EmsHMax * 4 - 1] Of LongInt;
  EmsMapH, EmsMapL : Array[0..3] Of LongInt;

Procedure EmsReset;
Var I : LongInt;
Begin
  EmsPool := 0; EmsPoolBlk := 0;
  For I := 0 To EmsPages - 1 Do EmsPgH[I] := -1;
  For I := 0 To EmsHMax - 1 Do
  Begin
    EmsHUsed[I] := False; EmsHName[I] := ''; EmsHSaved[I] := False;
  End;
  EmsHUsed[0] := True;               { poignee du systeme }
  For I := 0 To 3 Do
  Begin
    EmsMapH[I] := -1; EmsMapL[I] := -1;
  End;
End;

{ Bloc des pages logiques, au premier besoin }
Function EmsPoolOk : Boolean;
Var Own : LongInt;
Begin
  If EmsPool = 0 Then
  Begin
    Own := VmHeapOwn; VmHeapOwn := 1;
    EmsPoolBlk := VmKAlloc(EmsPages * 16384 + 4096);
    VmHeapOwn := Own;
    If EmsPoolBlk <> 0 Then EmsPool := (EmsPoolBlk + 4095) And Not 4095;
  End;
  EmsPoolOk := EmsPool <> 0;
End;

Function EmsFree : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To EmsPages - 1 Do If EmsPgH[I] < 0 Then Inc(N);
  EmsFree := N;
End;

Function EmsCount(H : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To EmsPages - 1 Do If EmsPgH[I] = H Then Inc(N);
  EmsCount := N;
End;

{ Page du bloc qui porte la page logique L de la poignee H (-1) }
Function EmsFind(H, L : LongInt) : LongInt;
Var I : LongInt;
Begin
  EmsFind := -1;
  For I := 0 To EmsPages - 1 Do
    If (EmsPgH[I] = H) And (EmsPgL[I] = L) Then
    Begin
      EmsFind := I;
      Exit;
    End;
End;

Function EmsHOk(H : LongInt) : Boolean;
Begin
  EmsHOk := (H >= 0) And (H < EmsHMax) And EmsHUsed[H];
End;

{ Projeter la page physique P (0-3) : pages de la machine E0h + 4 P }
Procedure EmsSetMap(P, H, L : LongInt);
Var I, K, A : LongInt;
Begin
  K := -1;
  If H >= 0 Then K := EmsFind(H, L);
  If K < 0 Then
  Begin
    H := -1; L := -1;
  End;
  EmsMapH[P] := H; EmsMapL[P] := L;
  For I := 0 To 3 Do
  Begin
    If K >= 0 Then A := EmsPool + K * 16384 + I * 4096
    Else A := VmRamPhys + $E0000 + (P * 4 + I) * 4096;
    MemL[0:VmPt + ($E0 + P * 4 + I) * 4] := A Or 7;
  End;
End;

Function EmsAllocP(H, N : LongInt) : Boolean;
Var I, L : LongInt;
Begin
  EmsAllocP := False;
  If (N > EmsFree) Or Not EmsPoolOk Then Exit;
  L := EmsCount(H);
  For I := 0 To EmsPages - 1 Do
    If (N > 0) And (EmsPgH[I] < 0) Then
    Begin
      EmsPgH[I] := H; EmsPgL[I] := L;
      FillMem(EmsPool + I * 16384, 16384, 0);
      Inc(L); Dec(N);
    End;
  EmsAllocP := True;
End;

{ Adresse (noyau) d'une region de la fonction 57h (Typ 0 : memoire
  conventionnelle Seg:Ofs ; 1 : poignee H, page L, decalage Ofs) }
Function EmsRegion(Typ, H, Ofs, Seg, Len : LongInt; Var Err : LongInt)
  : LongInt;
Var K : LongInt;
Begin
  EmsRegion := 0;
  If Typ = 0 Then
  Begin
    EmsRegion := VmLin(Seg, Ofs);
    Exit;
  End;
  If Not EmsHOk(H) Or (H = 0) Then
  Begin
    Err := $83;
    Exit;
  End;
  If Ofs >= 16384 Then
  Begin
    Err := $95;
    Exit;
  End;
  K := EmsFind(H, Seg);
  If (K < 0) Or (Seg * 16384 + Ofs + Len > EmsCount(H) * 16384) Then
  Begin
    Err := $93;
    Exit;
  End;
  EmsRegion := -1;
End;

{ Copier N octets entre memoire conventionnelle et pages logiques }
Procedure EmsCopy(STyp, SH, SOfs, SSeg, DTyp, DH, DOfs, DSeg, N : LongInt;
                  Xchg : Boolean);
Var A, B, K, C, T : LongInt;
Begin
  While N > 0 Do
  Begin
    C := N;
    If STyp = 1 Then
    Begin
      K := EmsFind(SH, SSeg);
      A := EmsPool + K * 16384 + SOfs;
      C := Min(C, 16384 - SOfs);
    End
    Else A := VmLin(SSeg, SOfs);
    If DTyp = 1 Then
    Begin
      K := EmsFind(DH, DSeg);
      B := EmsPool + K * 16384 + DOfs;
      C := Min(C, 16384 - DOfs);
    End
    Else B := VmLin(DSeg, DOfs);
    If STyp = 0 Then C := Min(C, $10000 - SOfs);
    If DTyp = 0 Then C := Min(C, $10000 - DOfs);
    If Xchg Then
      For K := 0 To C - 1 Do
      Begin
        T := Mem[0:A + K]; Mem[0:A + K] := Mem[0:B + K]; Mem[0:B + K] := T;
      End
    Else MoveMem(A, B, C);
    N := N - C;
    SOfs := SOfs + C; DOfs := DOfs + C;
    If STyp = 1 Then
      If SOfs >= 16384 Then
      Begin
        SOfs := SOfs - 16384; Inc(SSeg);
      End;
    If STyp = 0 Then
      If SOfs >= $10000 Then
      Begin
        SOfs := SOfs - 16; Inc(SSeg);
      End;
    If DTyp = 1 Then
      If DOfs >= 16384 Then
      Begin
        DOfs := DOfs - 16384; Inc(DSeg);
      End;
    If DTyp = 0 Then
      If DOfs >= $10000 Then
      Begin
        DOfs := DOfs - 16; Inc(DSeg);
      End;
  End;
End;

Procedure VmInt67;
Var AH, AL, H, L, P, I, N, K, E : LongInt;
Begin
  AH := VRH(fEax); AL := VRL(fEax);
  E := 0;
  Case AH Of
    $40 : ;
    $41 : VS(fEbx, EmsFrame);
    $42 :
    Begin
      VS(fEbx, EmsFree); VS(fEdx, EmsPages);
    End;
    $43, $5A :
    Begin
      N := VR(fEbx);
      If (AH = $43) And (N = 0) Then E := $89
      Else If N > EmsPages Then E := $87
      Else If N > EmsFree Then E := $88
      Else
      Begin
        H := -1;
        For I := 1 To EmsHMax - 1 Do
          If Not EmsHUsed[I] Then
          Begin
            H := I;
            Break;
          End;
        If H < 0 Then E := $85
        Else If Not EmsAllocP(H, N) Then E := $88
        Else
        Begin
          EmsHUsed[H] := True; EmsHName[H] := ''; EmsHSaved[H] := False;
          VS(fEdx, H);
        End;
      End;
    End;
    $44 :
    Begin
      H := VR(fEdx); L := VR(fEbx);
      If Not EmsHOk(H) Then E := $83
      Else If AL > 3 Then E := $8B
      Else If (L <> $FFFF) And (EmsFind(H, L) < 0) Then E := $8A
      Else If L = $FFFF Then EmsSetMap(AL, -1, -1)
      Else EmsSetMap(AL, H, L);
    End;
    $45 :
    Begin
      H := VR(fEdx);
      If Not EmsHOk(H) Then E := $83
      Else If EmsHSaved[H] Then E := $86
      Else
      Begin
        For I := 0 To 3 Do If EmsMapH[I] = H Then EmsSetMap(I, -1, -1);
        For I := 0 To EmsPages - 1 Do If EmsPgH[I] = H Then EmsPgH[I] := -1;
        If H <> 0 Then EmsHUsed[H] := False;
        EmsHName[H] := '';
      End;
    End;
    $46 : VSL(fEax, $40);
    $47, $48 :
    Begin
      H := VR(fEdx);
      If Not EmsHOk(H) Then E := $83
      Else If AH = $47 Then
      Begin
        If EmsHSaved[H] Then E := $8D
        Else
        Begin
          For I := 0 To 3 Do
          Begin
            EmsSvH[H * 4 + I] := EmsMapH[I]; EmsSvL[H * 4 + I] := EmsMapL[I];
          End;
          EmsHSaved[H] := True;
        End;
      End
      Else If Not EmsHSaved[H] Then E := $8E
      Else
      Begin
        For I := 0 To 3 Do EmsSetMap(I, EmsSvH[H * 4 + I], EmsSvL[H * 4 + I]);
        EmsHSaved[H] := False;
      End;
    End;
    $4B :
    Begin
      N := 0;
      For I := 0 To EmsHMax - 1 Do If EmsHUsed[I] Then Inc(N);
      VS(fEbx, N);
    End;
    $4C :
      If Not EmsHOk(VR(fEdx)) Then E := $83
      Else VS(fEbx, EmsCount(VR(fEdx)));
    $4D :
    Begin
      P := VmPtr(fEs, fEdi);
      N := 0;
      For I := 0 To EmsHMax - 1 Do
        If EmsHUsed[I] Then
        Begin
          MemW[0:P + N * 4] := I; MemW[0:P + N * 4 + 2] := EmsCount(I);
          Inc(N);
        End;
      VS(fEbx, N);
    End;
    $4E, $4F :
    Begin
      { contexte : 4 x (poignee, page) ; 4Fh : nombre de pages en tete }
      K := 16;
      If AH = $4F Then K := 18;
      Case AL Of
        0 :
        Begin
          If AH = $4E Then P := VmPtr(fEs, fEdi) Else P := VmPtr(fEs, fEdi);
          If AH = $4F Then
          Begin
            MemW[0:P] := 4; P := P + 2;
          End;
          For I := 0 To 3 Do
          Begin
            MemW[0:P + I * 4] := EmsMapH[I] And $FFFF;
            MemW[0:P + I * 4 + 2] := EmsMapL[I] And $FFFF;
          End;
        End;
        1 :
        Begin
          P := VmPtr(fDs, fEsi);
          If AH = $4F Then P := P + 2;
          For I := 0 To 3 Do
          Begin
            H := MemW[0:P + I * 4]; L := MemW[0:P + I * 4 + 2];
            If H = $FFFF Then H := -1;
            EmsSetMap(I, H, L);
          End;
        End;
        2 :
          If AH = $4E Then
          Begin
            P := VmPtr(fEs, fEdi);
            For I := 0 To 3 Do
            Begin
              MemW[0:P + I * 4] := EmsMapH[I] And $FFFF;
              MemW[0:P + I * 4 + 2] := EmsMapL[I] And $FFFF;
            End;
            P := VmPtr(fDs, fEsi);
            For I := 0 To 3 Do
            Begin
              H := MemW[0:P + I * 4]; L := MemW[0:P + I * 4 + 2];
              If H = $FFFF Then H := -1;
              EmsSetMap(I, H, L);
            End;
          End
          Else VSL(fEax, K);
        3 : VSL(fEax, K);
      Else
        E := $8F;
      End;
    End;
    $50 :
    Begin
      H := VR(fEdx);
      P := VmPtr(fDs, fEsi);
      If Not EmsHOk(H) Then E := $83
      Else If AL > 1 Then E := $8F
      Else
        For I := 0 To VR(fEcx) - 1 Do
        Begin
          L := MemW[0:P + I * 4]; K := MemW[0:P + I * 4 + 2];
          If AL = 1 Then K := (K - EmsFrame) Div $400;
          If (K < 0) Or (K > 3) Then E := $8B
          Else If L = $FFFF Then EmsSetMap(K, -1, -1)
          Else If EmsFind(H, L) < 0 Then E := $8A
          Else EmsSetMap(K, H, L);
        End;
    End;
    $51 :
    Begin
      H := VR(fEdx); N := VR(fEbx);
      If Not EmsHOk(H) Then E := $83
      Else
      Begin
        K := EmsCount(H);
        If N > K Then
        Begin
          If Not EmsAllocP(H, N - K) Then E := $88;
        End
        Else
        Begin
          For I := 0 To EmsPages - 1 Do
            If (EmsPgH[I] = H) And (EmsPgL[I] >= N) Then EmsPgH[I] := -1;
          For I := 0 To 3 Do
            If (EmsMapH[I] = H) And (EmsMapL[I] >= N) Then
              EmsSetMap(I, -1, -1);
        End;
        VS(fEbx, EmsCount(H));
      End;
    End;
    $52 :
      If Not EmsHOk(VR(fEdx)) Then E := $83
      Else If AL = 0 Then VSL(fEax, 0)
      Else If AL = 1 Then
      Begin
        If VRL(fEbx) <> 0 Then E := $91;
      End
      Else If AL = 2 Then VSL(fEax, 0)
      Else E := $8F;
    $53 :
    Begin
      H := VR(fEdx);
      If Not EmsHOk(H) Then E := $83
      Else If AL = 0 Then
      Begin
        P := VmPtr(fEs, fEdi);
        FillMem(P, 8, 0);
        For I := 1 To Length(EmsHName[H]) Do
          Mem[0:P + I - 1] := Ord(EmsHName[H][I]);
      End
      Else If AL = 1 Then
      Begin
        P := VmPtr(fDs, fEsi);
        EmsHName[H] := '';
        For I := 0 To 7 Do
          If Mem[0:P + I] <> 0 Then
            EmsHName[H] := EmsHName[H] + Chr(Mem[0:P + I]);
      End
      Else E := $8F;
    End;
    $54 :
      Case AL Of
        0 :
        Begin
          P := VmPtr(fEs, fEdi);
          N := 0;
          For I := 0 To EmsHMax - 1 Do
            If EmsHUsed[I] Then
            Begin
              MemW[0:P + N * 10] := I;
              FillMem(P + N * 10 + 2, 8, 0);
              For K := 1 To Length(EmsHName[I]) Do
                Mem[0:P + N * 10 + 1 + K] := Ord(EmsHName[I][K]);
              Inc(N);
            End;
          VSL(fEax, N);
        End;
        1 :
        Begin
          P := VmPtr(fDs, fEsi);
          E := $A0;
          For I := 1 To EmsHMax - 1 Do
            If EmsHUsed[I] And (EmsHName[I] <> '') And
               (EmsHName[I] = PStrN(P, 8)) Then
            Begin
              VS(fEdx, I);
              E := 0;
            End;
        End;
        2 : VS(fEbx, EmsHMax);
      Else
        E := $8F;
      End;
    $57 :
    Begin
      { DS:SI : longueur (dword), source (type, poignee, decalage,
        segment ou page), but (idem) }
      P := VmPtr(fDs, fEsi);
      N := MemL[0:P];
      If N > $100000 Then E := $96
      Else If (EmsRegion(Mem[0:P + 4], MemW[0:P + 5], MemW[0:P + 7],
                         MemW[0:P + 9], N, E) <> 0) And
              (EmsRegion(Mem[0:P + 11], MemW[0:P + 12], MemW[0:P + 14],
                         MemW[0:P + 16], N, E) <> 0) Then
      Begin
          EmsCopy(Mem[0:P + 4], MemW[0:P + 5], MemW[0:P + 7], MemW[0:P + 9],
                  Mem[0:P + 11], MemW[0:P + 12], MemW[0:P + 14],
                  MemW[0:P + 16], N, AL = 1);
      End;
    End;
    $58 :
    Begin
      If AL = 0 Then
      Begin
        P := VmPtr(fEs, fEdi);
        For I := 0 To 3 Do
        Begin
          MemW[0:P + I * 4] := EmsFrame + I * $400;
          MemW[0:P + I * 4 + 2] := I;
        End;
      End;
      VS(fEcx, 4);
    End;
    $59 :
      If AL = 1 Then
      Begin
        VS(fEbx, EmsFree); VS(fEdx, EmsPages);
      End
      Else E := $A4;
    $5B : If AL = 0 Then
          Begin
            VSL(fEbx, 0); VSeg(fEs, 0); VS(fEdi, 0);
          End
          Else E := $8F;
    $5C : ;
    $5D : E := $A4;
  Else
    E := $84;
  End;
  VSH(fEax, E);
End;

{ ------------------------------------------------------------------ }
{ Serveur DPMI 0.9 (mode protege des programmes DOS)                 }
{ ------------------------------------------------------------------ }
{ INT 2Fh AX=1687h annonce le serveur et donne son point d'entree
  (F000:VmDpmiO). Le client (16 ou 32 bits) passe en mode protege dans
  la meme tache : son code tourne en anneau 3 avec des selecteurs de la
  LDT du noyau (ceux de Win16), sous le repertoire de pages de la
  machine (le premier megaoctet est celui de la machine, la memoire
  allouee par 0501h est prise dans le tas). Le contexte de registres du
  moniteur passe d'un mode a l'autre : une interruption logicielle sans
  gestionnaire en mode protege est reflechie en mode reel (pile reelle
  du serveur, retour par F000:VmRmRetO), comme 0300h-0302h ; les
  rappels en mode reel (0303h), la commutation brute (0306h) et les
  gestionnaires d'exceptions (0202h/0203h) passent par de petites
  souches HLT du segment de code du serveur (anneau 3). Les
  interruptions materielles virtuelles (horloge, clavier) vont aux
  gestionnaires installes en mode protege, sinon au mode reel. }

Const
  VmXmsO = $0260;           { F000 : point d'entree XMS (HLT) }
  VmDpmiO = $0261;          { entree en mode protege (HLT) }
  VmRmRetO = $0262;         { fin d'une interruption reflechie (HLT) }
  VmRawPmO = $0263;         { commutation brute reel -> protege (HLT) }
  VmRetfO = $0264;          { RETF (sauvegarde d'etat, 0305h) }
  VmCbO = $0270;            { 16 rappels en mode reel (HLT) }
  VmPmDefO = $0400;         { gestionnaires par defaut (HLT) }
  VmExcRetO = $0500;        { fin d'un gestionnaire d'exception }
  VmCbRetO = $0501;         { fin d'un rappel (IRET du client) }
  VmRawRmO = $0502;         { commutation brute protege -> reel }
  VmIrqRetO = $0503;        { fin d'une interruption materielle }
  VmExcDefO = $0504;        { gestionnaire d'exception par defaut }
  VmPmRetfO = $0505;        { RETF en mode protege }
  VmVendorO = $0506;        { API du fournisseur 'MS-DOS' (CALL FAR) }
  DpOwner = $DD;            { proprietaire des selecteurs du client }
  VmSvMax = 16;
  VmSvW = 22;               { mots par contexte sauve }

Var
  VmDpmi : Boolean;
  VmDpmiPsp, VmDpmiEnv, VmHostCs : LongInt;
  VmPmVSel, VmPmVOfs : Array[0..255] Of LongInt;
  VmExcSel, VmExcOfs : Array[0..31] Of LongInt;
  VmRmStk, VmRmSp : LongInt;
  VmPmStkSel, VmPmStkLin, VmPmStkTop, VmCbStkSel : LongInt;
  VmSv : Array[0..VmSvMax * VmSvW - 1] Of LongInt;
  VmSvN : LongInt;
  VmMbLin, VmMbSize, VmMbBlk : Array[0..63] Of LongInt;
  VmCbUsed : Array[0..15] Of Boolean;
  VmCbPSel, VmCbPOfs, VmCbSSel, VmCbSOfs : Array[0..15] Of LongInt;
  VmSgSeg, VmSgSel : Array[0..63] Of LongInt;
  VmSgN : LongInt;
  VmIrqSv : Array[0..47] Of LongInt;
  VmIrqN : LongInt;
  VmLdtSel : LongInt;           { alias de la LDT (API 'MS-DOS' 0100h) }

{ ------------------------- descripteurs ---------------------------- }

Function VmDescI(Sel : LongInt) : LongInt;
Begin
  VmDescI := -1;
  If (Sel And 4) = 0 Then Exit;
  Sel := (Sel Shr 3) And $1FFF;
  If (Sel > 0) And (Sel < LdtMax) And LdtUsed[Sel] Then VmDescI := Sel;
End;

{ Acc : octet d'acces (bits 0-7) et drapeaux G, D/B, AVL (bits 12-15) }
Procedure VmDescSet(I, Base, Limit, Acc : LongInt);
Var G : LongInt;
Begin
  G := Acc And $8000;
  If (Limit < 0) Or (Limit > $FFFFF) Then
  Begin
    Limit := (Limit Shr 12) And $FFFFF;
    G := $8000;
  End
  Else If G <> 0 Then Limit := Limit Shr 12;
  Ldt[I * 2] := (Limit And $FFFF) Or ((Base And $FFFF) Shl 16);
  Ldt[I * 2 + 1] := ((Base Shr 16) And $FF) Or ((Acc And $FF) Shl 8) Or
                    (Limit And $F0000) Or ((Acc And $7000) Shl 8) Or
                    (G Shl 8) Or (Base And LongInt($FF000000));
End;

Function VmDescAcc(I : LongInt) : LongInt;
Begin
  VmDescAcc := ((Ldt[I * 2 + 1] Shr 8) And $FF) Or
               ((Ldt[I * 2 + 1] Shr 8) And $F000);
End;

{ Selecteurs du client (proprietaire DpOwner) }
Function VmSelNew(N, Base, Limit, Acc : LongInt) : LongInt;
Var S, I : LongInt;
Begin
  S := SelAlloc(N);
  VmSelNew := S;
  If S = 0 Then Exit;
  For I := 0 To N - 1 Do
  Begin
    GOwner[(S Shr 3) + I] := DpOwner;
    VmDescSet((S Shr 3) + I, Base + I * $10000, Limit, Acc);
  End;
End;

Function VmSelOwn(S : LongInt) : Boolean;
Var I : LongInt;
Begin
  I := VmDescI(S);
  VmSelOwn := (I > 0) And (GOwner[I] = DpOwner);
End;

{ Adresse (noyau) d'une adresse lineaire du client : le premier Mo est
  celui de la machine }
Function VmLK(L : LongInt) : LongInt;
Begin
  If (L >= 0) And (L < $100000) Then VmLK := VmRam + L Else VmLK := L;
End;

Function VmPmLin(Sel, Ofs : LongInt) : LongInt;
Begin
  VmPmLin := VmLK(SelBase(Sel And $FFFF) + Ofs);
End;

Function VmSelBig(Sel : LongInt) : Boolean;
Var I : LongInt;
Begin
  I := VmDescI(Sel);
  VmSelBig := (I > 0) And ((Ldt[I * 2 + 1] And $400000) <> 0);
End;

{ (E)DI, (E)SI, (E)DX selon la taille du client }
Function VmOfsR(R : LongInt) : LongInt;
Begin
  If Vm32 Then VmOfsR := MemL[0:VmF + R] Else VmOfsR := VR(R);
End;

Function VmPmPtr(SegR, OfsR : LongInt) : LongInt;
Begin
  VmPmPtr := VmPmLin(VR(SegR), VmOfsR(OfsR));
End;

{ ------------------------ pile du client --------------------------- }

Procedure VmPmPush(V, Sz : LongInt);
Var Sp : LongInt;
Begin
  If VmSelBig(VR(fSs)) Then Sp := MemL[0:VmF + fEsp] - Sz
  Else Sp := (VR(fEsp) - Sz) And $FFFF;
  If VmSelBig(VR(fSs)) Then MemL[0:VmF + fEsp] := Sp Else VS(fEsp, Sp);
  If Sz = 4 Then MemL[0:VmPmLin(VR(fSs), Sp)] := V
  Else MemW[0:VmPmLin(VR(fSs), Sp)] := V And $FFFF;
End;

Function VmPmPop(Sz : LongInt) : LongInt;
Var Sp : LongInt;
Begin
  If VmSelBig(VR(fSs)) Then Sp := MemL[0:VmF + fEsp]
  Else Sp := VR(fEsp);
  If Sz = 4 Then VmPmPop := MemL[0:VmPmLin(VR(fSs), Sp)]
  Else VmPmPop := MemW[0:VmPmLin(VR(fSs), Sp)];
  If VmSelBig(VR(fSs)) Then MemL[0:VmF + fEsp] := Sp + Sz
  Else VS(fEsp, Sp + Sz);
End;

Function VmPmSz : LongInt;
Begin
  If Vm32 Then VmPmSz := 4 Else VmPmSz := 2;
End;

Procedure VmPmGo(Sel, Ofs : LongInt);
Begin
  VSeg(fCs, Sel);
  If Vm32 Then MemL[0:VmF + fEip] := Ofs
  Else MemL[0:VmF + fEip] := Ofs And $FFFF;
End;

{ FLAGS du client (IF virtuel) }
Function VmPmFlags : LongInt;
Begin
  VmPmFlags := (MemL[0:VmF + fFl] And $0DD5) Or 2 Or (Ord(VmIF) * $200);
End;

{ --------------------- contextes sauves ---------------------------- }
{ mots 0-17 : registres ; 18 : sorte (1 interruption, 2 appel 0300h, 3
  rappel, 4 exception) ; 19 : auxiliaire ; 20 : IF virtuel ; 21 : mode }

Procedure VmSave(Kind, Aux : LongInt);
Var B : LongInt;
Begin
  If VmSvN >= VmSvMax Then
  Begin
    VmCrash('DPMI : trop de changements de mode imbriques');
    Exit;
  End;
  B := VmSvN * VmSvW;
  MoveMem(LongInt(@VmCtx), LongInt(@VmSv[B]), 72);
  VmSv[B + 18] := Kind; VmSv[B + 19] := Aux;
  VmSv[B + 20] := Ord(VmIF); VmSv[B + 21] := Ord(VmPM);
  Inc(VmSvN);
End;

{ Passer au mode reel sur la pile reelle du serveur (registres generaux
  gardes) }
Procedure VmToRm;
Begin
  VmPM := False;
  VSeg(fDs, 0); VSeg(fEs, 0); VSeg(fFs, 0); VSeg(fGs, 0);
  VSeg(fSs, VmRmStk);
  VmRmSp := VmRmSp - 256;
  MemL[0:VmF + fEsp] := VmRmSp + 256;
  MemL[0:VmF + fFl] := MemL[0:VmF + fFl] And Not $100;
End;

{ Interruption N reflechie en mode reel ; PopFr : un cadre IRET du
  client est a retirer au retour (gestionnaire par defaut atteint) }
Procedure VmReflect(N : LongInt; PopFr : Boolean);
Var V : LongInt;
Begin
  VmSave(1, Ord(PopFr));
  VmToRm;
  VmPush(VmVFlags); VmPush(VmBios); VmPush(VmRmRetO);
  VmIF := False;
  V := MemL[0:VmRam + N * 4];
  VmGoto(V Shr 16, V And $FFFF);
  If V = (LongInt(VmBios) Shl 16) + VmStubO + N Then VmService(N);
End;

{ Retour au mode protege (F000:VmRmRetO atteint en mode reel) }
Procedure VmRmReturn;
Var B, K, L, Fl, I : LongInt; R : Array[0..17] Of LongInt;
Begin
  Dec(VmSvN);
  B := VmSvN * VmSvW;
  K := VmSv[B + 18];
  MoveMem(LongInt(@VmCtx), LongInt(@R), 72);
  VmRmSp := VmRmSp + 256;
  MoveMem(LongInt(@VmSv[B]), LongInt(@VmCtx), 72);
  VmIF := VmSv[B + 20] <> 0;
  VmPM := VmSv[B + 21] <> 0;
  Fl := R[10];
  If K = 1 Then
  Begin
    { interruption : registres generaux et indicateurs du resultat }
    For I := 0 To 7 Do
      If I <> 3 Then VmCtx[I] := R[I];
    VmCtx[10] := (VmCtx[10] And Not $8D5) Or (Fl And $8D5);
    If VmSv[B + 19] <> 0 Then
    Begin
      { IRET du cadre empile par le client }
      L := VmPmPop(VmPmSz);
      I := VmPmPop(VmPmSz);
      VmPmGo(I, L);
      L := VmPmPop(VmPmSz);
      VmIF := (L And $200) <> 0;
      VmCtx[10] := (VmCtx[10] And $8D5) Or (L And $500) Or $202;
    End;
  End
  Else If K = 2 Then
  Begin
    { 0300h-0302h : registres reels ecrits dans la structure }
    L := VmSv[B + 19];
    MemL[0:L] := R[0]; MemL[0:L + 4] := R[1]; MemL[0:L + 8] := R[2];
    MemL[0:L + 16] := R[4]; MemL[0:L + 20] := R[5];
    MemL[0:L + 24] := R[6]; MemL[0:L + 28] := R[7];
    MemW[0:L + 32] := Fl And $FFFF;
    MemW[0:L + 34] := R[13]; MemW[0:L + 36] := R[14];
    MemW[0:L + 38] := R[15]; MemW[0:L + 40] := R[16];
    MemW[0:L + 42] := R[8]; MemW[0:L + 44] := R[9];
    MemW[0:L + 46] := R[11]; MemW[0:L + 48] := R[12];
    VmSetCF(False);
  End;
End;

{ ---------------------- entree en mode protege --------------------- }

Function DpSegSel(Seg : LongInt) : LongInt;
Var I : LongInt;
Begin
  For I := 0 To VmSgN - 1 Do
    If VmSgSeg[I] = Seg Then
    Begin
      DpSegSel := VmSgSel[I];
      Exit;
    End;
  I := VmSelNew(1, Seg * 16, $FFFF, $F2);
  If (I <> 0) And (VmSgN < 64) Then
  Begin
    VmSgSeg[VmSgN] := Seg; VmSgSel[VmSgN] := I;
    Inc(VmSgN);
  End;
  DpSegSel := I;
End;

{ CALL FAR F000:VmDpmiO : AX bit 0 = client 32 bits }
Procedure DpEnter;
Var Ip, Cs, Max, I, Own, CsS, DsS, SsS, Ps, En : LongInt;
Begin
  Ip := VmPop; Cs := VmPop;
  VmGoto(Cs, Ip);
  If VmDpmi Then
  Begin
    VmSetCF(True);
    VS(fEax, $8011);
    Exit;
  End;
  Vm32 := (VR(fEax) And 1) <> 0;
  VmSgN := 0; VmSvN := 0; VmIrqN := 0;
  For I := 0 To 63 Do VmMbBlk[I] := 0;
  For I := 0 To 15 Do VmCbUsed[I] := False;
  { pile reelle du serveur : les 4 Ko (SI = 100h paragraphes) donnes
    par le client dans ES ; pile protegee de 8 Ko }
  VmRmStk := VR(fEs);
  If VmRmStk = 0 Then VmRmStk := McbAlloc(256, VmCurPsp, Max);
  Own := VmHeapOwn; VmHeapOwn := 1;
  VmPmStkLin := VmKAlloc(8192);
  VmHeapOwn := Own;
  If (VmRmStk = 0) Or (VmPmStkLin = 0) Then
  Begin
    VmSetCF(True);
    VS(fEax, $8012);
    Exit;
  End;
  VmRmSp := 4096 - 16;
  VmPmStkTop := 8192 - 16;
  I := $40FA * Ord(Vm32) + $FA * Ord(Not Vm32);
  VmHostCs := VmSelNew(1, $F0000, $FFFF, I);
  VmPmStkSel := VmSelNew(1, VmPmStkLin, 8191, $F2 Or ($4000 * Ord(Vm32)));
  VmCbStkSel := VmSelNew(1, 0, $FFFF, $F2);
  CsS := VmSelNew(1, Cs * 16, $FFFF, $FA);
  DsS := DpSegSel(VR(fDs));
  If VR(fSs) = VR(fDs) Then SsS := DsS
  Else SsS := VmSelNew(1, VR(fSs) * 16, $FFFF, $F2);
  Ps := VmSelNew(1, VmCurPsp * 16, $FF, $F2);
  VmDpmiEnv := MemW[0:VmLin(VmCurPsp, $2C)];
  En := VmSelNew(1, VmDpmiEnv * 16, $FFFF, $F2);
  If (VmHostCs = 0) Or (CsS = 0) Or (SsS = 0) Or (Ps = 0) Then
  Begin
    VmSetCF(True);
    VS(fEax, $8011);
    Exit;
  End;
  MemW[0:VmLin(VmCurPsp, $2C)] := En;
  VmPspSel := Ps;
  { alias de la LDT : ses pages deviennent accessibles a l'anneau 3 }
  VmLdtSel := VmSelNew(1, LongInt(@Ldt), LdtMax * 8 - 1, $F2);
  For I := LongInt(@Ldt) Shr 12 To (LongInt(@Ldt) + LdtMax * 8 - 1) Shr 12 Do
    If I < 1024 Then MemL[0:VmPt + I * 4] := (I Shl 12) Or 7;
  For I := 0 To 255 Do
  Begin
    VmPmVSel[I] := VmHostCs; VmPmVOfs[I] := VmPmDefO + I;
  End;
  For I := 0 To 31 Do
  Begin
    VmExcSel[I] := 0; VmExcOfs[I] := 0;
  End;
  VmDpmiPsp := VmCurPsp;
  VmDpmi := True;
  VmPM := True;
  VSeg(fCs, CsS); MemL[0:VmF + fEip] := Ip;
  VSeg(fSs, SsS); MemL[0:VmF + fEsp] := VR(fEsp);
  VSeg(fDs, DsS); VSeg(fEs, Ps); VSeg(fFs, 0); VSeg(fGs, 0);
  VmSetCF(False);
  VmLog('DPMI : client ' + IntStr(16 + 16 * Ord(Vm32)) + ' bits, PSP ' +
       HexStr(VmDpmiPsp, 4) + ' CS=' + HexStr(CsS, 4) + ' DS=' +
       HexStr(DsS, 4) + ' SS=' + HexStr(SsS, 4) + ' ES=' + HexStr(Ps, 4) +
       ' ' + HexStr(Ldt[(CsS Shr 3) * 2], 8) + ' ' +
       HexStr(Ldt[(CsS Shr 3) * 2 + 1], 8));
End;

{ Fin du client : selecteurs, memoire, rappels }
Procedure DpEnd;
Var I : LongInt;
Begin
  If Not VmDpmi Then Exit;
  For I := 1 To LdtMax - 1 Do
    If LdtUsed[I] And (GOwner[I] = DpOwner) Then SelFree((I Shl 3) Or 7, 1);
  For I := 0 To 63 Do
    If VmMbBlk[I] <> 0 Then
    Begin
      VmKFree(VmMbBlk[I]);
      VmMbBlk[I] := 0;
    End;
  If VmPmStkLin <> 0 Then VmKFree(VmPmStkLin);
  VmPmStkLin := 0;
  If VmRam <> 0 Then
    For I := LongInt(@Ldt) Shr 12 To (LongInt(@Ldt) + LdtMax * 8 - 1) Shr 12
    Do
      If (I >= 272) And (I < 1024) Then MemL[0:VmPt + I * 4] := (I Shl 12) Or 7;
  If VmRam <> 0 Then MemW[0:VmLin(VmDpmiPsp, $2C)] := VmDpmiEnv;
  VmDpmi := False;
  VmSvN := 0; VmIrqN := 0;
  VmPM := False;
  VmLog('DPMI : fin du client');
End;

{ ----------------------- services INT 31h -------------------------- }

Procedure DpFail(E : LongInt);
Begin
  VS(fEax, E);
  VmSetCF(True);
End;

{ 0300h-0302h : appel en mode reel avec la structure ES:(E)DI }
Procedure DpRmCall(Fn : LongInt);
Var L, Sp, Ss, N, V, Src, IntN : LongInt;
Begin
  IntN := VRL(fEbx);
  L := VmPmPtr(fEs, fEdi);
  N := VR(fEcx);
  Src := VmPmLin(VR(fSs), VmOfsR(fEsp));
  If Not VmSelBig(VR(fSs)) Then Src := VmPmLin(VR(fSs), VR(fEsp));
  VmSetCF(False);
  VmSave(2, L);
  VmPM := False;
  MemL[0:VmF + fEdi] := MemL[0:L]; MemL[0:VmF + fEsi] := MemL[0:L + 4];
  MemL[0:VmF + fEbp] := MemL[0:L + 8];
  MemL[0:VmF + fEbx] := MemL[0:L + 16]; MemL[0:VmF + fEdx] := MemL[0:L + 20];
  MemL[0:VmF + fEcx] := MemL[0:L + 24]; MemL[0:VmF + fEax] := MemL[0:L + 28];
  VmLoadFlags(MemW[0:L + 32]);
  VSeg(fEs, MemW[0:L + 34]); VSeg(fDs, MemW[0:L + 36]);
  VSeg(fFs, MemW[0:L + 38]); VSeg(fGs, MemW[0:L + 40]);
  Sp := MemW[0:L + 46]; Ss := MemW[0:L + 48];
  VmRmSp := VmRmSp - 256;
  If (Sp = 0) And (Ss = 0) Then
  Begin
    Ss := VmRmStk; Sp := VmRmSp + 256;
  End;
  VSeg(fSs, Ss); MemL[0:VmF + fEsp] := Sp;
  { parametres copies de la pile protegee }
  If N > 0 Then
  Begin
    Sp := (Sp - N * 2) And $FFFF;
    VS(fEsp, Sp);
    MoveMem(Src, VmLin(Ss, Sp), N * 2);
  End;
  If Fn <> $0301 Then VmPush(VmVFlags);
  VmPush(VmBios); VmPush(VmRmRetO);
  If Fn = $0300 Then
  Begin
    VmIF := False;
    V := MemL[0:VmRam + IntN * 4];
    VmGoto(V Shr 16, V And $FFFF);
    If V = (LongInt(VmBios) Shl 16) + VmStubO + IntN Then VmService(IntN);
  End
  Else VmGoto(MemW[0:L + 44], MemW[0:L + 42]);
End;

Procedure DpMemInfo;
Var P, F : LongInt;
Begin
  P := VmPmPtr(fEs, fEdi);
  FillMem(P, 48, $FF);
  F := VmMemFree - 8 * 1048576;
  If F < 0 Then F := 0;
  MemL[0:P] := F;
  MemL[0:P + 4] := F Div 4096; MemL[0:P + 8] := F Div 4096;
  MemL[0:P + $0C] := (PhysTop - PhysProcBase) Div 4096;
  MemL[0:P + $10] := F Div 4096; MemL[0:P + $14] := F Div 4096;
  MemL[0:P + $18] := (PhysTop - PhysProcBase) Div 4096;
  MemL[0:P + $1C] := F Div 4096;
  MemL[0:P + $20] := 0;
End;

Function DpMemNew(Size : LongInt; Var H : LongInt) : Boolean;
Var I, A, Own : LongInt;
Begin
  DpMemNew := False;
  H := -1;
  For I := 0 To 63 Do
    If VmMbBlk[I] = 0 Then
    Begin
      H := I;
      Break;
    End;
  If (H < 0) Or (Size <= 0) Or (Size > VmMemFree - 8 * 1048576) Then
    Exit;
  Own := VmHeapOwn; VmHeapOwn := 1;
  A := VmKAlloc(Size + 4096);
  VmHeapOwn := Own;
  If A = 0 Then Exit;
  VmMbBlk[H] := A;
  VmMbLin[H] := (A + 4095) And Not 4095;
  VmMbSize[H] := Size;
  DpMemNew := True;
End;

Procedure DpCall;
Var AX, I, S, B, L, N, P, Max, H, K, Acc : LongInt;
Begin
  AX := VR(fEax);
  VmSetCF(False);
  Case AX Of
    $0000 :
    Begin
      N := VR(fEcx);
      If N = 0 Then N := 1;
      S := VmSelNew(N, 0, 0, $F2);
      If S = 0 Then DpFail($8011) Else VS(fEax, S);
    End;
    $0001 :
      If Not VmSelOwn(VR(fEbx)) Then DpFail($8022)
      Else SelFree(VR(fEbx), 1);
    $0002 :
    Begin
      S := DpSegSel(VR(fEbx));
      If S = 0 Then DpFail($8011) Else VS(fEax, S);
    End;
    $0003 : VS(fEax, 8);
    $0006 :
      If VmDescI(VR(fEbx)) < 0 Then DpFail($8022)
      Else
      Begin
        B := SelBase(VR(fEbx));
        VS(fEcx, B Shr 16); VS(fEdx, B);
      End;
    $0007, $0008, $0009 :
    Begin
      I := VmDescI(VR(fEbx));
      If (I < 0) Or Not VmSelOwn(VR(fEbx)) Then DpFail($8022)
      Else
      Begin
        B := SelBase(VR(fEbx)); L := SelLimit(VR(fEbx));
        Acc := VmDescAcc(I);
        If AX = $0007 Then B := (VR(fEcx) Shl 16) Or VR(fEdx)
        Else If AX = $0008 Then
        Begin
          L := (VR(fEcx) Shl 16) Or VR(fEdx);
          Acc := Acc And Not $8000;
          If (L < 0) Or (L > $FFFFF) Then
          Begin
            If (L And $FFF) <> $FFF Then
            Begin
              DpFail($8021);
              Exit;
            End;
            Acc := Acc Or $8000;
          End;
        End
        Else
        Begin
          K := VR(fEcx);
          If ((K And $60) <> $60) Or ((K And $10) = 0) Then
          Begin
            DpFail($8021);
            Exit;
          End;
          Acc := (K And $FF) Or (((K Shr 8) And $D0) Shl 8);
        End;
        If (Acc And $8000) <> 0 Then
          VmDescSet(I, B, (L And LongInt($FFFFF000)) Or $FFF, Acc)
        Else VmDescSet(I, B, L, Acc);
      End;
    End;
    $000A :
    Begin
      I := VmDescI(VR(fEbx));
      If I < 0 Then DpFail($8022)
      Else
      Begin
        S := VmSelNew(1, 0, 0, $F2);
        If S = 0 Then DpFail($8011)
        Else
        Begin
          Ldt[(S Shr 3) * 2] := Ldt[I * 2];
          Ldt[(S Shr 3) * 2 + 1] := (Ldt[I * 2 + 1] And Not $0F00) Or $0200;
          VS(fEax, S);
        End;
      End;
    End;
    $000B :
    Begin
      I := VmDescI(VR(fEbx));
      If I < 0 Then DpFail($8022)
      Else
      Begin
        P := VmPmPtr(fEs, fEdi);
        MemL[0:P] := Ldt[I * 2]; MemL[0:P + 4] := Ldt[I * 2 + 1];
      End;
    End;
    $000C :
    Begin
      I := VmDescI(VR(fEbx));
      P := VmPmPtr(fEs, fEdi);
      If (I < 0) Or Not VmSelOwn(VR(fEbx)) Then DpFail($8022)
      Else If ((MemL[0:P + 4] And $8000) <> 0) And
              (((MemL[0:P + 4] And $6000) <> $6000) Or
               ((MemL[0:P + 4] And $1000) = 0)) Then DpFail($8021)
      Else
      Begin
        Ldt[I * 2] := MemL[0:P]; Ldt[I * 2 + 1] := MemL[0:P + 4];
      End;
    End;
    $0100 :
    Begin
      N := VR(fEbx);
      S := McbAlloc(N, VmDpmiPsp, Max);
      If S = 0 Then
      Begin
        DpFail(8); VS(fEbx, Max);
      End
      Else
      Begin
        K := (N * 16 + $FFFF) Div $10000;
        If K = 0 Then K := 1;
        I := VmSelNew(K, S * 16, N * 16 - 1, $F2);
        If I = 0 Then
        Begin
          McbFree(S);
          DpFail($8011);
        End
        Else
        Begin
          For P := 0 To K - 1 Do
            VmDescSet((I Shr 3) + P, S * 16 + P * $10000,
                      Min(N * 16 - P * $10000 - 1, $FFFF), $F2);
          VS(fEax, S); VS(fEdx, I);
        End;
      End;
    End;
    $0101, $0102 :
    Begin
      I := VmDescI(VR(fEdx));
      If (I < 0) Or Not VmSelOwn(VR(fEdx)) Then DpFail($8022)
      Else
      Begin
        S := SelBase(VR(fEdx)) Div 16;
        K := (SelLimit(VR(fEdx)) + $10000) Div $10000;
        If AX = $0101 Then
        Begin
          McbFree(S);
          SelFree(VR(fEdx), K);
        End
        Else
        Begin
          N := VR(fEbx);
          If ((N * 16 + $FFFF) Div $10000 > K) Or
             Not McbResize(S, N, Max) Then
          Begin
            DpFail(8); VS(fEbx, Max);
          End
          Else
            VmDescSet(I, S * 16, Min(N * 16 - 1, $FFFF), $F2);
        End;
      End;
    End;
    $0200 :
    Begin
      L := MemL[0:VmRam + VRL(fEbx) * 4];
      VS(fEcx, L Shr 16); VS(fEdx, L);
    End;
    $0201 : MemL[0:VmRam + VRL(fEbx) * 4] := (VR(fEcx) Shl 16) Or VR(fEdx);
    $0202 :
    Begin
      I := VRL(fEbx) And 31;
      If VmExcSel[I] = 0 Then
      Begin
        VS(fEcx, VmHostCs); MemL[0:VmF + fEdx] := VmExcDefO;
      End
      Else
      Begin
        VS(fEcx, VmExcSel[I]); MemL[0:VmF + fEdx] := VmExcOfs[I];
      End;
    End;
    $0203 :
    Begin
      I := VRL(fEbx) And 31;
      If (VR(fEcx) = VmHostCs) And (VmOfsR(fEdx) = VmExcDefO) Then
        VmExcSel[I] := 0
      Else
      Begin
        VmExcSel[I] := VR(fEcx); VmExcOfs[I] := VmOfsR(fEdx);
      End;
    End;
    $0204 :
    Begin
      I := VRL(fEbx);
      VS(fEcx, VmPmVSel[I]);
      If Vm32 Then MemL[0:VmF + fEdx] := VmPmVOfs[I]
      Else VS(fEdx, VmPmVOfs[I]);
    End;
    $0205 :
    Begin
      I := VRL(fEbx);
      VmPmVSel[I] := VR(fEcx); VmPmVOfs[I] := VmOfsR(fEdx);
    End;
    $0300, $0301, $0302 : DpRmCall(AX);
    $0303 :
    Begin
      K := -1;
      For I := 0 To 15 Do
        If Not VmCbUsed[I] Then
        Begin
          K := I;
          Break;
        End;
      If K < 0 Then DpFail($8015)
      Else
      Begin
        VmCbUsed[K] := True;
        VmCbPSel[K] := VR(fDs); VmCbPOfs[K] := VmOfsR(fEsi);
        VmCbSSel[K] := VR(fEs); VmCbSOfs[K] := VmOfsR(fEdi);
        VS(fEcx, VmBios); VS(fEdx, VmCbO + K);
      End;
    End;
    $0304 :
    Begin
      K := VR(fEdx) - VmCbO;
      If (VR(fEcx) <> VmBios) Or (K < 0) Or (K > 15) Then DpFail($8024)
      Else VmCbUsed[K] := False;
    End;
    $0305 :
    Begin
      VS(fEax, 0);
      VS(fEbx, VmBios); VS(fEcx, VmRetfO);
      VS(fEsi, VmHostCs); MemL[0:VmF + fEdi] := VmPmRetfO;
    End;
    $0306 :
    Begin
      VS(fEbx, VmBios); VS(fEcx, VmRawPmO);
      VS(fEsi, VmHostCs); MemL[0:VmF + fEdi] := VmRawRmO;
    End;
    $0400 :
    Begin
      VS(fEax, $005A); VS(fEbx, 1); VS(fEcx, 4); VS(fEdx, $0870);
    End;
    $0500 : DpMemInfo;
    $0501 :
    Begin
      N := (VR(fEbx) Shl 16) Or VR(fEcx);
      If Not DpMemNew(N, H) Then DpFail($8012)
      Else
      Begin
        VS(fEbx, VmMbLin[H] Shr 16); VS(fEcx, VmMbLin[H]);
        VS(fEsi, 0); VS(fEdi, H + 1);
      End;
    End;
    $0502 :
    Begin
      H := ((VR(fEsi) Shl 16) Or VR(fEdi)) - 1;
      If (H < 0) Or (H > 63) Or (VmMbBlk[H] = 0) Then DpFail($8023)
      Else
      Begin
        VmKFree(VmMbBlk[H]);
        VmMbBlk[H] := 0;
      End;
    End;
    $0503 :
    Begin
      H := ((VR(fEsi) Shl 16) Or VR(fEdi)) - 1;
      N := (VR(fEbx) Shl 16) Or VR(fEcx);
      If (H < 0) Or (H > 63) Or (VmMbBlk[H] = 0) Then DpFail($8023)
      Else If Not DpMemNew(N, K) Then DpFail($8012)
      Else
      Begin
        MoveMem(VmMbLin[H], VmMbLin[K], Min(N, VmMbSize[H]));
        VmKFree(VmMbBlk[H]);
        VmMbBlk[H] := VmMbBlk[K]; VmMbLin[H] := VmMbLin[K];
        VmMbSize[H] := VmMbSize[K];
        VmMbBlk[K] := 0;
        VS(fEbx, VmMbLin[H] Shr 16); VS(fEcx, VmMbLin[H]);
      End;
    End;
    $0600, $0601, $0602, $0603, $0702, $0703, $0801 : ;
    $0604 :
    Begin
      VS(fEbx, 0); VS(fEcx, 4096);
    End;
    $0800 :
    Begin
      L := (VR(fEbx) Shl 16) Or VR(fEcx);
      If (L >= 0) And (L < $100000) Then DpFail($8021);
    End;
    $0900 :
    Begin
      VSL(fEax, Ord(VmIF)); VmIF := False;
    End;
    $0901 :
    Begin
      VSL(fEax, Ord(VmIF)); VmIF := True;
    End;
    $0902 : VSL(fEax, Ord(VmIF));
    $0A00 :
      If PStrN(VmPmPtr(fDs, fEsi), 7) = 'MS-DOS' Then
      Begin
        VSeg(fEs, VmHostCs); MemL[0:VmF + fEdi] := VmVendorO;
      End
      Else DpFail($8001);
  Else
    DpFail($8001);
  End;
End;

{ ----------------------- interruptions ----------------------------- }

Procedure VmPmDefault(N : LongInt; Frame : Boolean); Forward;
Procedure VmPmIret; Forward;

Function VmPmDef(N : LongInt) : Boolean;
Begin
  VmPmDef := (VmPmVSel[N] = VmHostCs) And (VmPmVOfs[N] = VmPmDefO + N);
End;

{ Interruption N vers le client : gestionnaire installe (cadre IRET ;
  materielle : retour par VmIrqRetO pour retablir IF), sinon reflexion
  en mode reel }
Procedure VmPmDeliver(N : LongInt; Hw : Boolean);
Var Sz : LongInt;
Begin
  If VmPmDef(N) Then
  Begin
    VmPmDefault(N, False);
    Exit;
  End;
  Sz := VmPmSz;
  If Hw Then
  Begin
    If VmIrqN >= 16 Then Exit;
    VmIrqSv[VmIrqN * 3] := VR(fCs);
    VmIrqSv[VmIrqN * 3 + 1] := MemL[0:VmF + fEip];
    VmIrqSv[VmIrqN * 3 + 2] := MemL[0:VmF + fFl];
    Inc(VmIrqN);
    VmPmPush(VmPmFlags, Sz); VmPmPush(VmHostCs, Sz); VmPmPush(VmIrqRetO, Sz);
    VmIF := False;
  End
  Else
  Begin
    VmPmPush(VmPmFlags, Sz); VmPmPush(VR(fCs), Sz);
    VmPmPush(MemL[0:VmF + fEip], Sz);
  End;
  MemL[0:VmF + fFl] := MemL[0:VmF + fFl] And Not $100;
  VmPmGo(VmPmVSel[N], VmPmVOfs[N]);
End;

{ Gestionnaire par defaut du serveur pour l'interruption N : INT 31h
  (services DPMI), INT 21h (DOS, pointeurs traduits), INT 2Fh 1686h et
  168Ah ; les autres sont reflechies en mode reel. Frame : un cadre IRET
  du client est sur sa pile (gestionnaire chaine). }
Procedure VmPmDefault(N : LongInt; Frame : Boolean);
Var T : String; Spec : Boolean;
Begin
  Spec := (N = $31) Or (N = $21) Or
          ((N = $2F) And ((VR(fEax) = $1686) Or (VR(fEax) = $168A)));
  If Not Spec Then
  Begin
    VmReflect(N, Frame);
    Exit;
  End;
  If Frame Then VmPmIret;
  If N = $21 Then VmInt21
  Else If N = $31 Then
  Begin
    If VmTrace Then T := 'INT 31h ' + VmRegStr;
    DpCall;
    If VmTrace Then
      VmLog(T + ' -> CF=' + IntStr(MemL[0:VmF + fFl] And 1) + ' AX=' +
           HexStr(VR(fEax), 4) + ' BX=' + HexStr(VR(fEbx), 4) + ' CX=' +
           HexStr(VR(fEcx), 4) + ' DX=' + HexStr(VR(fEdx), 4));
  End
  Else If VR(fEax) = $1686 Then VS(fEax, 0)
  Else If PStrN(VmPmPtr(fDs, fEsi), 7) = 'MS-DOS' Then
  Begin
    VSL(fEax, 0);
    VSeg(fEs, VmHostCs); MemL[0:VmF + fEdi] := VmVendorO;
  End;
End;

{ INT N execute par le client (EIP apres l'instruction) }
Procedure VmPmSoftInt(N : LongInt);
Begin
  VmPmDeliver(N, False);
End;

Function VmPmCode(Ofs : LongInt) : LongInt;
Begin
  VmPmCode := Mem[0:VmPmLin(VR(fCs), Ofs)];
End;

{ Exception du client : son gestionnaire (0203h) sur la pile du
  serveur, ou fin du programme }
Procedure VmPmExc(V : LongInt);
Var Sz, Sp, P : LongInt;
Begin
  If (V < 32) And (VmExcSel[V] <> 0) And (VmPmStkTop > 1024) Then
  Begin
    If VmTrace Then
      VmLog('PM exception ' + HexStr(V, 2) + ' code ' + HexStr(VmErrCode, 4) +
           ' en ' + HexStr(VR(fCs), 4) + ':' +
           HexStr(MemL[0:VmF + fEip], 8) + ' ' + VmRegStr + ' octets ' +
           HexStr(VmPmCode(MemL[0:VmF + fEip]), 2) + ' ' +
           HexStr(VmPmCode(MemL[0:VmF + fEip] + 1), 2) + ' ' +
           HexStr(VmPmCode(MemL[0:VmF + fEip] + 2), 2) + ' ' +
           HexStr(VmPmCode(MemL[0:VmF + fEip] + 3), 2));
    Sz := VmPmSz;
    Sp := VmPmStkTop - 8 * Sz;
    VmPmStkTop := VmPmStkTop - 1024;
    P := VmPmStkLin + Sp;
    If Sz = 4 Then
    Begin
      MemL[0:P] := VmExcRetO; MemL[0:P + 4] := VmHostCs;
      MemL[0:P + 8] := VmErrCode; MemL[0:P + 12] := MemL[0:VmF + fEip];
      MemL[0:P + 16] := VR(fCs); MemL[0:P + 20] := VmPmFlags;
      MemL[0:P + 24] := MemL[0:VmF + fEsp]; MemL[0:P + 28] := VR(fSs);
    End
    Else
    Begin
      MemW[0:P] := VmExcRetO; MemW[0:P + 2] := VmHostCs;
      MemW[0:P + 4] := VmErrCode; MemW[0:P + 6] := VR(fEip);
      MemW[0:P + 8] := VR(fCs); MemW[0:P + 10] := VmPmFlags;
      MemW[0:P + 12] := VR(fEsp); MemW[0:P + 14] := VR(fSs);
    End;
    VSeg(fSs, VmPmStkSel); MemL[0:VmF + fEsp] := Sp;
    VmPmGo(VmExcSel[V], VmExcOfs[V]);
    Exit;
  End;
  If V In [0, 1, 3, 4, 5, 7] Then
  Begin
    VmPmDeliver(V, False);
    Exit;
  End;
  VmLog('DPMI : exception ' + HexStr(V, 2) + 'h code ' +
       HexStr(VmErrCode, 4) + ' en ' + HexStr(VR(fCs), 4) + ':' +
       HexStr(MemL[0:VmF + fEip], 8) + ' ' + VmRegStr);
  Sz := MemL[0:VmF + fEip];
  For P := 0 To 9 Do
    VmConStr(HexStr(VmPmCode(Sz + P), 2) + ' ');
  VmConStr(#13#10'DPMI : exception ' + HexStr(V, 2) + 'h en ' +
           HexStr(VR(fCs), 4) + ':' + HexStr(MemL[0:VmF + fEip], 8) +
           #13#10);
  VmPM := False;
  VmTerminate(255, False, 0);
End;

{ Rappel en mode reel (CALL FAR F000:VmCbO + K) : procedure protegee
  du client avec DS:(E)SI = pile reelle, ES:(E)DI = structure }
Procedure DpCallback(K : LongInt);
Var L, Sz : LongInt;
Begin
  If Not VmCbUsed[K] Or (VmPmStkTop <= 1024) Then
  Begin
    VmCrash('DPMI : rappel ' + IntStr(K) + ' invalide');
    Exit;
  End;
  L := VmPmLin(VmCbSSel[K], VmCbSOfs[K]);
  MemL[0:L] := MemL[0:VmF + fEdi]; MemL[0:L + 4] := MemL[0:VmF + fEsi];
  MemL[0:L + 8] := MemL[0:VmF + fEbp]; MemL[0:L + 12] := 0;
  MemL[0:L + 16] := MemL[0:VmF + fEbx]; MemL[0:L + 20] := MemL[0:VmF + fEdx];
  MemL[0:L + 24] := MemL[0:VmF + fEcx]; MemL[0:L + 28] := MemL[0:VmF + fEax];
  MemW[0:L + 32] := VmVFlags;
  MemW[0:L + 34] := VR(fEs); MemW[0:L + 36] := VR(fDs);
  MemW[0:L + 38] := VR(fFs); MemW[0:L + 40] := VR(fGs);
  MemW[0:L + 42] := VR(fEip); MemW[0:L + 44] := VR(fCs);
  MemW[0:L + 46] := VR(fEsp); MemW[0:L + 48] := VR(fSs);
  VmSave(3, K);
  VmDescSet(VmCbStkSel Shr 3, VR(fSs) * 16, $FFFF, $F2);
  VmPM := True;
  VSeg(fDs, VmCbStkSel); MemL[0:VmF + fEsi] := VR(fEsp);
  VSeg(fEs, VmCbSSel[K]); MemL[0:VmF + fEdi] := VmCbSOfs[K];
  VSeg(fFs, 0); VSeg(fGs, 0);
  VSeg(fSs, VmPmStkSel); MemL[0:VmF + fEsp] := VmPmStkTop;
  VmPmStkTop := VmPmStkTop - 1024;
  Sz := VmPmSz;
  VmPmPush(VmPmFlags, Sz); VmPmPush(VmHostCs, Sz); VmPmPush(VmCbRetO, Sz);
  VmIF := False;
  VmPmGo(VmCbPSel[K], VmCbPOfs[K]);
End;

{ HLT d'une souche du serveur en mode reel (F000:Ip) ; False si ce
  n'en est pas une }
Function VmHostRm(Ip : LongInt) : Boolean;
Var V : LongInt;
Begin
  If VmTrace And (Ip <> VmRmRetO) Then
    VmLog('RM souche ' + HexStr(Ip, 4) + ' ' + VmRegStr);
  VmHostRm := True;
  If Ip = VmXmsO Then
  Begin
    VmXms;
    V := VmPop; VmGoto(VmPop, V);
  End
  Else If Ip = VmDpmiO Then DpEnter
  Else If (Ip = VmRmRetO) And (VmSvN > 0) Then VmRmReturn
  Else If (Ip >= VmCbO) And (Ip < VmCbO + 16) And VmDpmi Then
    DpCallback(Ip - VmCbO)
  Else If (Ip = VmRawPmO) And VmDpmi Then
  Begin
    VmPM := True;
    VSeg(fDs, VR(fEax)); VSeg(fEs, VR(fEcx)); VSeg(fSs, VR(fEdx));
    If Vm32 Then MemL[0:VmF + fEsp] := MemL[0:VmF + fEbx]
    Else MemL[0:VmF + fEsp] := VR(fEbx);
    VSeg(fFs, 0); VSeg(fGs, 0);
    VmPmGo(VR(fEsi), VmOfsR(fEdi));
  End
  Else VmHostRm := False;
End;

{ IRET d'un cadre empile par le client (indicateurs du resultat
  gardes) }
Procedure VmPmIret;
Var Ip, Cs, Fl, Sz : LongInt;
Begin
  Sz := VmPmSz;
  Ip := VmPmPop(Sz); Cs := VmPmPop(Sz); Fl := VmPmPop(Sz);
  VmPmGo(Cs, Ip);
  VmIF := (Fl And $200) <> 0;
  MemL[0:VmF + fFl] := (MemL[0:VmF + fFl] And $8D5) Or (Fl And $500) Or $202;
End;

{ Memoire DOS en selecteurs (0100h et INT 21h 48h) : Sel ou 0 }
Function DpDosAlloc(N : LongInt; Var Seg, Max : LongInt) : LongInt;
Var K, I, P : LongInt;
Begin
  DpDosAlloc := 0;
  Seg := McbAlloc(N, VmDpmiPsp, Max);
  If Seg = 0 Then Exit;
  K := (N * 16 + $FFFF) Div $10000;
  If K = 0 Then K := 1;
  I := VmSelNew(K, Seg * 16, N * 16 - 1, $F2);
  If I = 0 Then
  Begin
    McbFree(Seg);
    Exit;
  End;
  For P := 0 To K - 1 Do
    VmDescSet((I Shr 3) + P, Seg * 16 + P * $10000,
              Min(N * 16 - P * $10000 - 1, $FFFF), $F2);
  DpDosAlloc := I;
End;

{ EXEC demande en mode protege : chemin, bloc de parametres, ligne de
  commande et FCB recopies dans la pile reelle du serveur, puis INT 21h
  en mode reel (le retour du programme revient en mode protege) }
Procedure DpExec;
Var Pb, B, T, V, I : LongInt; Path : String;
Begin
  Path := PStr(VmPtr(fDs, fEdx));
  Pb := VmPtr(fEs, fEbx);
  B := VmLin(VmRmStk, 0);
  PutPStr(B, Path, 128);
  V := MemW[0:Pb];
  If (V And 4) <> 0 Then V := SelBase(V) Shr 4;
  MemW[0:B + 128] := V;
  MemL[0:B + 130] := (VmRmStk Shl 16) Or 144;
  MemL[0:B + 134] := (VmRmStk Shl 16) Or 272;
  MemL[0:B + 138] := (VmRmStk Shl 16) Or 288;
  FillMem(B + 144, 160, 0);
  Mem[0:B + 145] := 13;
  T := MemL[0:Pb + 2];
  If T <> 0 Then MoveMem(VmPmLin(T Shr 16, T And $FFFF), B + 144, 128);
  For I := 0 To 1 Do
  Begin
    T := MemL[0:Pb + 6 + I * 4];
    If (T <> 0) And (T <> -1) Then
      MoveMem(VmPmLin(T Shr 16, T And $FFFF), B + 272 + I * 16, 16);
  End;
  VmSave(1, 0);
  VmToRm;
  VSeg(fDs, VmRmStk); VS(fEdx, 0);
  VSeg(fEs, VmRmStk); VS(fEbx, 128);
  VS(fEax, $4B00);
  VmPush(VmVFlags); VmPush(VmBios); VmPush(VmRmRetO);
  VmIF := False;
  V := MemL[0:VmRam + $21 * 4];
  VmGoto(V Shr 16, V And $FFFF);
  If V = (LongInt(VmBios) Shl 16) + VmStubO + $21 Then VmService($21);
End;

{ INT 21h en mode protege : fonctions propres aux extensions MS-DOS
  (vecteurs, memoire et PSP en selecteurs, EXEC) ; False : la fonction
  ordinaire (pointeurs traduits par VmPtr) }
Function DpDos(AH, AL : LongInt) : Boolean;
Var S, Max, Seg, K : LongInt;
Begin
  DpDos := True;
  VmSetCF(False);
  Case AH Of
    $25 :
    Begin
      VmPmVSel[AL] := VR(fDs); VmPmVOfs[AL] := VmOfsR(fEdx);
    End;
    $35 :
    Begin
      VSeg(fEs, VmPmVSel[AL]);
      If Vm32 Then MemL[0:VmF + fEbx] := VmPmVOfs[AL]
      Else VS(fEbx, VmPmVOfs[AL]);
    End;
    $2F :
    Begin
      If VmDtaPM Then VSeg(fEs, VmDta Shr 16)
      Else VSeg(fEs, DpSegSel(VmDta Shr 16));
      If Vm32 Then MemL[0:VmF + fEbx] := VmDta And $FFFF
      Else VS(fEbx, VmDta);
    End;
    $34, $52 :
    Begin
      VSeg(fEs, DpSegSel(VmDosSeg));
      If AH = $34 Then VS(fEbx, 0) Else VS(fEbx, VmLolO);
    End;
    $63 :
    Begin
      VSeg(fDs, DpSegSel(VmDosSeg)); VS(fEsi, VmDbcsO); VSL(fEax, 0);
    End;
    $48 :
    Begin
      S := DpDosAlloc(VR(fEbx), Seg, Max);
      If S = 0 Then
      Begin
        VmFail(8); VS(fEbx, Max);
      End
      Else VS(fEax, S);
    End;
    $49, $4A :
      If Not VmSelOwn(VR(fEs)) Then VmFail(9)
      Else
      Begin
        Seg := SelBase(VR(fEs)) Div 16;
        K := (SelLimit(VR(fEs)) + $10000) Div $10000;
        If AH = $49 Then
        Begin
          McbFree(Seg);
          SelFree(VR(fEs), K);
          VSeg(fEs, 0);
        End
        Else If ((VR(fEbx) * 16 + $FFFF) Div $10000 > K) Or
                Not McbResize(Seg, VR(fEbx), Max) Then
        Begin
          VmFail(8); VS(fEbx, Max);
        End
        Else
          VmDescSet(VR(fEs) Shr 3, Seg * 16, Min(VR(fEbx) * 16 - 1, $FFFF),
                    $F2);
      End;
    $4B : If AL = 0 Then DpExec Else VmFail(1);
    $50 : If (VR(fEbx) And 4) <> 0 Then
            VmCurPsp := SelBase(VR(fEbx)) Shr 4
          Else VmCurPsp := VR(fEbx);
    $51, $62 :
      If VmCurPsp = VmDpmiPsp Then VS(fEbx, VmPspSel)
      Else VS(fEbx, DpSegSel(VmCurPsp));
  Else
    DpDos := False;
  End;
End;

{ HLT d'une souche du serveur en mode protege }
Procedure VmHostPm(Ip : LongInt);
Var Sz, P, B, L : LongInt;
Begin
  If VmTrace And (Ip <> VmPmDefO + $21) And (Ip <> VmPmDefO + $31) Then
    VmLog('PM souche ' + HexStr(Ip, 4) + ' ' + VmRegStr);
  Sz := VmPmSz;
  If (Ip >= VmPmDefO) And (Ip < VmPmDefO + 256) Then
    VmPmDefault(Ip - VmPmDefO, True)
  Else If Ip = VmVendorO Then
  Begin
    { API 'MS-DOS' : 0100h = alias de la LDT ; puis RETF }
    If VR(fEax) = $0100 Then
    Begin
      VS(fEax, VmLdtSel); VmSetCF(False);
    End
    Else VmSetCF(True);
    P := VmPmPop(Sz); B := VmPmPop(Sz);
    VmPmGo(B, P);
  End
  Else If Ip = VmIrqRetO Then
  Begin
    If VmIrqN > 0 Then
    Begin
      Dec(VmIrqN);
      VSeg(fCs, VmIrqSv[VmIrqN * 3]);
      MemL[0:VmF + fEip] := VmIrqSv[VmIrqN * 3 + 1];
      MemL[0:VmF + fFl] := VmIrqSv[VmIrqN * 3 + 2];
    End;
    VmIF := True;
  End
  Else If Ip = VmExcRetO Then
  Begin
    { RETF du gestionnaire : SS:ESP sur le code d'erreur }
    P := VmPmLin(VR(fSs), MemL[0:VmF + fEsp]);
    If Not VmSelBig(VR(fSs)) Then P := VmPmLin(VR(fSs), VR(fEsp));
    VmPmStkTop := VmPmStkTop + 1024;
    If Sz = 4 Then
    Begin
      VSeg(fCs, MemL[0:P + 8]); MemL[0:VmF + fEip] := MemL[0:P + 4];
      L := MemL[0:P + 12];
      MemL[0:VmF + fEsp] := MemL[0:P + 16]; VSeg(fSs, MemL[0:P + 20]);
    End
    Else
    Begin
      VSeg(fCs, MemW[0:P + 4]); MemL[0:VmF + fEip] := MemW[0:P + 2];
      L := MemW[0:P + 6];
      MemL[0:VmF + fEsp] := MemW[0:P + 8]; VSeg(fSs, MemW[0:P + 10]);
    End;
    VmIF := (L And $200) <> 0;
    MemL[0:VmF + fFl] := (L And $DD5) Or $202;
  End
  Else If Ip = VmCbRetO Then
  Begin
    { IRET du rappel : ES:(E)DI = structure des registres reels }
    P := VmPmPtr(fEs, fEdi);
    Dec(VmSvN);
    VmPmStkTop := VmPmStkTop + 1024;
    VmPM := False;
    MemL[0:VmF + fEdi] := MemL[0:P]; MemL[0:VmF + fEsi] := MemL[0:P + 4];
    MemL[0:VmF + fEbp] := MemL[0:P + 8];
    MemL[0:VmF + fEbx] := MemL[0:P + 16]; MemL[0:VmF + fEdx] := MemL[0:P + 20];
    MemL[0:VmF + fEcx] := MemL[0:P + 24]; MemL[0:VmF + fEax] := MemL[0:P + 28];
    VmLoadFlags(MemW[0:P + 32]);
    VSeg(fEs, MemW[0:P + 34]); VSeg(fDs, MemW[0:P + 36]);
    VSeg(fFs, MemW[0:P + 38]); VSeg(fGs, MemW[0:P + 40]);
    VmGoto(MemW[0:P + 44], MemW[0:P + 42]);
    VSeg(fSs, MemW[0:P + 48]); MemL[0:VmF + fEsp] := MemW[0:P + 46];
  End
  Else If Ip = VmRawRmO Then
  Begin
    VmPM := False;
    B := VR(fEsi); L := VR(fEdi);
    VSeg(fDs, VR(fEax)); VSeg(fEs, VR(fEcx)); VSeg(fSs, VR(fEdx));
    MemL[0:VmF + fEsp] := VR(fEbx);
    VSeg(fFs, 0); VSeg(fGs, 0);
    VmGoto(B, L);
  End
  Else If Ip = VmExcDefO Then
  Begin
    { un gestionnaire d'exception a rappele celui du serveur }
    VmPmStkTop := VmPmStkTop + 1024;
    VmPmExc(13);
  End
  Else VmPmExc(13);
End;

{ Faute de protection generale du client : INT n, CLI, STI, HLT, IN,
  OUT ; sinon exception }
Procedure VmGpPM;
Var Ip, N, Op, V, K, Sz, Port : LongInt; O32, Big : Boolean;
Begin
  Ip := MemL[0:VmF + fEip];
  Big := VmSelBig(VR(fCs));
  If Not Big Then Ip := Ip And $FFFF;
  N := 0; O32 := Big;
  Repeat
    Op := VmPmCode(Ip + N);
    Inc(N);
    Case Op Of
      $66 : O32 := Not Big;
      $26, $2E, $36, $3E, $64, $65, $67, $F0, $F2, $F3 : ;
    Else
      Break;
    End;
  Until N > 14;
  Case Op Of
    $CD :
    Begin
      V := VmPmCode(Ip + N);
      MemL[0:VmF + fEip] := Ip + N + 1;
      VmPmSoftInt(V);
    End;
    $CC, $CE :
    Begin
      MemL[0:VmF + fEip] := Ip + N;
      If Op = $CC Then VmPmSoftInt(3)
      Else If (MemL[0:VmF + fFl] And $800) <> 0 Then VmPmSoftInt(4);
    End;
    $FA, $FB :
    Begin
      MemL[0:VmF + fEip] := Ip + N;
      VmIF := Op = $FB;
    End;
    $F4 :
      If VR(fCs) = VmHostCs Then VmHostPm(Ip)
      Else
      Begin
        MemL[0:VmF + fEip] := Ip + N;
        If VmIF Then
          While Not VmIrqPending Do VmSleep(1);
      End;
    $E4..$E7, $EC..$EF :
    Begin
      If Op In [$E4..$E7] Then
      Begin
        Port := VmPmCode(Ip + N);
        Inc(N);
      End
      Else Port := VR(fEdx);
      If Op In [$E4, $E6, $EC, $EE] Then Sz := 1
      Else If O32 Then Sz := 4 Else Sz := 2;
      If Op In [$E4, $E5, $EC, $ED] Then
      Begin
        V := 0;
        For K := 0 To Sz - 1 Do V := V Or (VmIn(Port + K) Shl (K * 8));
        If Sz = 1 Then VSL(fEax, V)
        Else If Sz = 2 Then VS(fEax, V)
        Else MemL[0:VmF + fEax] := V;
      End
      Else
        For K := 0 To Sz - 1 Do
          VmOut(Port + K, MemL[0:VmF + fEax] Shr (K * 8));
      MemL[0:VmF + fEip] := Ip + N;
    End;
  Else
    VmPmExc(13);
  End;
End;

{ Faute ou trappe du client en mode protege }
Procedure VmPmTrap;
Begin
  If VmTrace And (VmVec <> $131) And (VmVec <> 13) Then
    VmLog('PM trappe ' + HexStr(VmVec, 3) + ' en ' + HexStr(VR(fCs), 4) +
         ':' + HexStr(MemL[0:VmF + fEip], 8) + ' err ' +
         HexStr(VmErrCode, 4) + ' ' + VmRegStr);
  If VmVec >= $100 Then VmPmSoftInt(VmVec - $100)
  Else If VmVec = 13 Then VmGpPM
  Else VmPmExc(VmVec);
End;

{ Interruptions virtuelles vers le client en mode protege }
Procedure VmCheckIrqPM;
Begin
  If Not VmIF Then Exit;
  VmTimeUpd;
  If (VmTickDue > 0) And ((VmPicMask And 1) = 0) And
     ((VmIsr And 1) = 0) Then
  Begin
    Dec(VmTickDue);
    VmIsr := VmIsr Or 1;
    VmPmDeliver(8, True);
    Exit;
  End;
  If (VmKqHead <> VmKqTail) And ((VmPicMask And 2) = 0) And
     ((VmIsr And 3) = 0) Then
  Begin
    VmCurKey := VmKq[VmKqHead];
    VmKqHead := (VmKqHead + 1) Mod VmKqMax;
    VmPort60 := (VmCurKey Shr 16) And $FF;
    VmIsr := VmIsr Or 2;
    VmPmDeliver(9, True);
  End;
End;

{ Interruption d'horloge du noyau pendant le code du client (cadre B de
  l'interruption, sans changement de mode) }
Procedure VmTickPM(B : LongInt);
Var T : LongInt;
Begin
  VmF := B;
  If Not VmIF Then Exit;
  VmTimeUpd;
  If (VmTickDue > 0) And ((VmPicMask And 1) = 0) And
     ((VmIsr And 1) = 0) Then
  Begin
    If Not VmPmDef(8) Then
    Begin
      Dec(VmTickDue);
      VmIsr := VmIsr Or 1;
      VmPmDeliver(8, True);
      Exit;
    End
    Else If VmVecDefault(8) And VmVecDefault($1C) Then
    Begin
      Dec(VmTickDue);
      T := MemL[0:VmBda($6C)] + 1;
      If T >= $1800B0 Then
      Begin
        T := 0;
        Mem[0:VmBda($70)] := 1;
      End;
      MemL[0:VmBda($6C)] := T;
    End;
  End;
  If (VmKqHead <> VmKqTail) And ((VmPicMask And 2) = 0) And
     ((VmIsr And 3) = 0) Then
  Begin
    If Not VmPmDef(9) Then
    Begin
      VmCurKey := VmKq[VmKqHead];
      VmKqHead := (VmKqHead + 1) Mod VmKqMax;
      VmPort60 := (VmCurKey Shr 16) And $FF;
      VmIsr := VmIsr Or 2;
      VmPmDeliver(9, True);
    End
    Else If VmVecDefault(9) Then
    Begin
      VmCurKey := VmKq[VmKqHead];
      VmKqHead := (VmKqHead + 1) Mod VmKqMax;
      If (VmCurKey And $2000000) <> 0 Then VmBufPush(VmCurKey And $FFFF);
      VmCurKey := 0;
    End;
  End;
End;

{ Apres chaque faute : retours en mode protege, interruptions }
Procedure VmPostTrap;
Var K : LongInt;
Begin
  For K := 1 To 2 Do
  Begin
    While (Not VmPM) And (VmSvN > 0) And (VR(fCs) = VmBios) And
          (VR(fEip) = VmRmRetO) Do VmRmReturn;
    If K = 2 Then Exit;
    If VmPM Then
    Begin
      If VmIF And (VmMouEv And VmMouMask <> 0) And (VmMouBusy = 0) And
         ((VmMouSeg <> 0) Or (VmMouOfs <> 0)) Then
      Begin
        { gestionnaire de la souris (mode reel) appele depuis le mode
          protege : passage par le mode reel }
        VmSave(1, 0);
        VmToRm;
        VmGoto(VmBios, VmRmRetO);
        VmMouCall;
      End
      Else VmCheckIrqPM;
    End
    Else If VmIF And (VmMouEv <> 0) Then
    Begin
      If Not VmMouCall Then VmCheckIrq;
    End
    Else VmCheckIrq;
  End;
End;

{ Services du BIOS et du DOS de la machine (IRET a la fin) }
Procedure VmService(N : LongInt);
Var V : LongInt;
Begin
  VmNoIret := False;
  Case N Of
    $00 :
    Begin
      VmConStr(#13#10'Divide overflow'#13#10);
      VmTerminate(255, False, 0);
    End;
    $06 : VmCrash('code d''operation invalide');
    $08 : VmInt08;
    $09 : VmInt09;
    $10 : VmInt10;
    $11 : VS(fEax, MemW[0:VmBda($10)]);
    $12 : VS(fEax, MemW[0:VmBda($13)]);
    $13 : VmInt13;
    $14 : VSH(fEax, $80);
    $15 : VmInt15;
    $16 : VmInt16;
    $17 : VSH(fEax, $90);
    $1A : VmInt1A;
    $20 : VmTerminate(0, False, 0);
    $21 : VmInt21;
    $24 : VSL(fEax, 3);
    $25, $26 :
    Begin
      { lecture et ecriture absolues : erreur ; le mot des indicateurs
        reste sur la pile (RETF) }
      VS(fEax, $0208);
      VmSetCF(True);
      V := VmPop; VmGoto(VmPop, V);
      VmPush(VmVFlags);
      VmNoIret := True;
    End;
    $27 : VmTerminate(0, True, (VR(fEdx) + 15) Shr 4);
    $28 : VmIdle;
    $29 : VmTty(VRL(fEax));
    $2A : VSH(fEax, 0);
    $2F : VmInt2F;
    $33 : VmInt33;
    $67 : VmInt67;
    $0A..$0F, $70..$77 : ;
  End;
  If Not VmNoIret Then VmIretRet;
End;

{ ------------------------------------------------------------------ }

{ ------------------------------------------------------------------ }
{ Creation de la machine, tache, fin et lancement                    }
{ ------------------------------------------------------------------ }

{ police 8x16 de la carte VGA, lue au demarrage en mode texte dans le
  plan 2 (generateur de caracteres : 32 octets par caractere) }
Procedure VmGrabFont;
Var C, R : LongInt;
Begin
  If VmFontBuf <> 0 Then Exit;
  VmFontBuf := KAlloc(4096);
  If VmFontBuf = 0 Then Exit;
  asm
    cli
  end;
  Port[$3C4] := 2; Port[$3C5] := 4;
  Port[$3C4] := 4; Port[$3C5] := 7;
  Port[$3CE] := 4; Port[$3CF] := 2;
  Port[$3CE] := 5; Port[$3CF] := 0;
  Port[$3CE] := 6; Port[$3CF] := 0;
  For C := 0 To 255 Do
    For R := 0 To 15 Do
      Mem[0:VmFontBuf + C * 16 + R] := Mem[0:$A0000 + C * 32 + R];
  Port[$3C4] := 2; Port[$3C5] := 3;
  Port[$3C4] := 4; Port[$3C5] := 3;
  Port[$3CE] := 4; Port[$3CF] := 0;
  Port[$3CE] := 5; Port[$3CF] := $10;
  Port[$3CE] := 6; Port[$3CF] := $0E;
  asm
    sti
  end;
End;

Function VmSetup : Boolean;
Var I, A, D, EnvP, S, Z : LongInt; E : String;
Begin
  VmSetup := False;
  If Not PagingInit Then Exit;
  VmBuildStubs;
  If VmTmp = 0 Then VmTmp := KAlloc(1024);
  VmPadCh := '789-456+1230.';
  VmHeapOwn := 1;
  VmRamPhys := PAlloc($100000);
  If (VmRamPhys = 0) Or (VmTmp = 0) Then Exit;
  VmRam := 0;
  VmPt := SPT[VmSess];
  { pages de la session : le premier Mo est la memoire de la machine,
    sauf l'ecran (A0000h-AFFFFh et B8000h-BFFFFh : la carte ou le tampon
    de la session) ; la zone haute (HMA) au noyau seulement ; le reste
    des 4 premiers Mo (tas du noyau) accessible a l'anneau 3 (DPMI) }
  For I := 0 To 255 Do
    If Not (((I >= $A0) And (I <= $AF)) Or ((I >= $B8) And (I <= $BF))) Then
      MemL[0:VmPt + I * 4] := (VmRamPhys + I * 4096) Or 7;
  For I := 256 To 271 Do MemL[0:VmPt + I * 4] := (I * 4096) Or 3;
  For I := 272 To 1023 Do MemL[0:VmPt + I * 4] := (I * 4096) Or 7;
  SessMap(VmSess, FgSess = VmSess);
  FlushTlb;
  FillMem(VmRamPhys, $A0000, 0);
  FillMem(VmRamPhys + $B0000, $8000, 0);
  FillMem(VmRamPhys + $C0000, $40000, 0);
  { table des interruptions : un HLT par vecteur }
  For I := 0 To 255 Do
    MemL[0:VmRam + I * 4] := (LongInt(VmBios) Shl 16) + VmStubO + I;
  MemL[0:VmRam + $1F * 4] := (LongInt(VmBios) Shl 16) + VmFont8H;
  MemL[0:VmRam + $43 * 4] := (LongInt(VmBios) Shl 16) + VmFontO;
  MemL[0:VmRam + $1D * 4] := (LongInt(VmBios) Shl 16) + $0300;
  MemL[0:VmRam + $1E * 4] := (LongInt(VmBios) Shl 16) + $0300;
  MemL[0:VmRam + $41 * 4] := (LongInt(VmBios) Shl 16) + $0300;
  MemL[0:VmRam + $46 * 4] := (LongInt(VmBios) Shl 16) + $0300;
  { BIOS : souches, tables, police }
  A := VmRam + $F0000;
  FillMem(A + VmStubO, 256, $F4);
  Mem[0:A + VmExitO] := $F4; Mem[0:A + VmCpmO] := $F4;
  Mem[0:A + VmMRetO] := $F4; Mem[0:A + VmCpmO + 2] := $CB;
  MemW[0:A + VmCfgO] := 8; Mem[0:A + VmCfgO + 2] := $FC;
  Mem[0:A + VmCfgO + 3] := 1; Mem[0:A + VmCfgO + 5] := $70;
  Mem[0:A + VmFuncO] := $FF; Mem[0:A + VmFuncO + 1] := $E0;
  Mem[0:A + VmFuncO + 2] := $0F; Mem[0:A + VmFuncO + 7] := 7;
  Mem[0:A + VmFuncO + 8] := 2; Mem[0:A + VmFuncO + 9] := 8;
  For I := 0 To 7 Do
  Begin
    Mem[0:A + VmEgaO + I] := I;
    Mem[0:A + VmEgaO + 8 + I] := $38 + I;
  End;
  Mem[0:A + VmEgaO + 6] := $14;
  If VmFontBuf <> 0 Then
  Begin
    MoveMem(VmFontBuf, A + VmFontO, 4096);
    { polices 8x8 et 8x14 tirees de la 8x16 (lignes reunies deux a deux,
      ou sans la premiere et la derniere) }
    For I := 0 To 255 Do
    Begin
      For S := 0 To 7 Do
      Begin
        D := Mem[0:VmFontBuf + I * 16 + S * 2] Or
             Mem[0:VmFontBuf + I * 16 + S * 2 + 1];
        If I < 128 Then Mem[0:A + VmFont8O + I * 8 + S] := D
        Else Mem[0:A + VmFont8H + (I - 128) * 8 + S] := D;
      End;
      For S := 0 To 13 Do
        Mem[0:A + VmFont14O + I * 14 + S] := Mem[0:VmFontBuf + I * 16 + S + 1];
    End;
  End;
  Mem[0:A + $FFF0] := $EA; MemW[0:A + $FFF1] := $E05B;
  MemW[0:A + $FFF3] := VmBios;
  PutPStr(A + $FFF5, '11/14/26', 9);
  Mem[0:A + $FFFE] := $FC;
  { zone de donnees du BIOS }
  MemW[0:VmBda($10)] := $0026;
  MemW[0:VmBda($13)] := 640;
  MemW[0:VmBda($1A)] := $1E; MemW[0:VmBda($1C)] := $1E;
  MemW[0:VmBda($80)] := $1E; MemW[0:VmBda($82)] := $3E;
  VgMode := 3; VgStart := 0; VgHwGfx := False; VgSaved := False;
  VmGfx := False;
  { XMS, EMS, DPMI : souches HLT du serveur, nom du pilote EMS }
  VmDpmi := False; VmPM := False; VmSvN := 0;
  XmsReset; EmsReset;
  FillMem(A + VmXmsO, $20, $F4);
  FillMem(A + VmPmDefO, $106, $F4);
  Mem[0:A + VmRetfO] := $CB; Mem[0:A + VmPmRetfO] := $CB;
  PutPStr(A + $0A, 'EMMXXXX0', 9);
  VmSetMode($83);
  MemW[0:VmBda($63)] := $3D4;
  Mem[0:VmBda($65)] := $29; Mem[0:VmBda($66)] := $30;
  Mem[0:VmBda($75)] := 1;
  Mem[0:VmBda($87)] := $60; Mem[0:VmBda($88)] := $09;
  Mem[0:VmBda($89)] := $11; Mem[0:VmBda($8A)] := $0B;
  Mem[0:VmBda($96)] := $10;
  ReadRtc;
  S := RtcHour * 3600 + RtcMin * 60 + RtcSec;
  MemL[0:VmBda($6C)] := S * 18 + (S * 2065) Div 10000;
  { donnees du DOS : liste des listes, peripherique NUL, tables }
  D := VmLin(VmDosSeg, 0);
  MemW[0:D + VmLolO - 2] := VmFirstMcb;
  MemL[0:D + VmLolO] := -1; MemL[0:D + VmLolO + 4] := -1;
  MemW[0:D + VmLolO + $10] := 512;
  Mem[0:D + VmLolO + $20] := 2; Mem[0:D + VmLolO + $21] := 26;
  MemL[0:D + VmLolO + $22] := -1;
  MemW[0:D + VmLolO + $26] := $8004;
  PutPStr(D + VmLolO + $2C, 'NUL     ', 9);
  MemW[0:D + VmUpO] := 128;
  For I := 0 To 127 Do Mem[0:D + VmUpO + 2 + I] := 128 + I;
  { premier bloc : PSP racine, puis son environnement }
  E := 'COMSPEC=C:\COMMAND.COM';
  EnvP := (EnvSize + Length(E) + 24 + 15) Shr 4;
  Z := VmRootEnv + EnvP;
  Mem[0:McbA(VmFirstMcb)] := Ord('M');
  MemW[0:McbA(VmFirstMcb) + 1] := VmRootPsp;
  MemW[0:McbA(VmFirstMcb) + 3] := $10;
  PutPStr(McbA(VmFirstMcb) + 8, 'COMMAND', 8);
  Mem[0:McbA(VmRootEnv - 1)] := Ord('M');
  MemW[0:McbA(VmRootEnv - 1) + 1] := VmRootPsp;
  MemW[0:McbA(VmRootEnv - 1) + 3] := EnvP;
  Mem[0:McbA(Z)] := Ord('Z');
  MemW[0:McbA(Z) + 1] := 0;
  MemW[0:McbA(Z) + 3] := $9FFF - Z;
  { variables du systeme ; COMSPEC : l'interpreteur de la machine }
  A := VmLin(VmRootEnv, 0);
  I := 0; S := 0;
  While (S < EnvSize) And (EnvBlock[S] <> 0) Do
  Begin
    E := PStr(LongInt(@EnvBlock) + S);
    If UpStr(Copy(E, 1, 8)) <> 'COMSPEC=' Then
    Begin
      PutPStr(A + I, E, 256);
      I := I + Length(E) + 1;
    End;
    S := S + StrLenZ(LongInt(@EnvBlock) + S) + 1;
  End;
  E := 'COMSPEC=C:\COMMAND.COM';
  PutPStr(A + I, E, 64);
  I := I + Length(E) + 1;
  Mem[0:A + I] := 0;
  MemW[0:A + I + 1] := 1;
  PutPStr(A + I + 3, 'C:\COMMAND.COM', 16);
  { fichiers : CON (0-2), AUX et PRN (NUL) }
  For I := 0 To VmMaxSft - 1 Do SftRef[I] := 0;
  SftDev[0] := 1; SftRef[0] := 3; SftMode[0] := 2;
  SftDev[1] := 2; SftRef[1] := 1; SftMode[1] := 2;
  SftDev[2] := 2; SftRef[2] := 1; SftMode[2] := 2;
  VmMakePsp(VmRootPsp, $10, VmRootEnv, 0, '');
  A := VmLin(VmRootPsp, 0);
  MemW[0:A + $16] := VmRootPsp;
  Mem[0:A + $18] := 0; Mem[0:A + $19] := 0; Mem[0:A + $1A] := 0;
  Mem[0:A + $1B] := 1; Mem[0:A + $1C] := 2;
  MemL[0:A + $0A] := (LongInt(VmBios) Shl 16) + VmExitO;
  MemL[0:VmRam + $22 * 4] := MemL[0:A + $0A];
  VmCurPsp := VmRootPsp;
  VmDta := (VmRootPsp Shl 16) Or $80; VmDtaPM := False;
  For I := 0 To VmMaxFind - 1 Do VmFindH[I] := 0;
  { lecteurs : repertoire courant du lecteur courant }
  For I := 0 To 25 Do VmDir[I] := '';
  E := CurDir;
  VmDrive := Ord(UpCase(E[1])) - 65;
  If (VmDrive < 0) Or (VmDrive > 25) Then VmDrive := 2;
  E := Copy(E, 3, 66);
  If E = '\' Then E := '';
  VmDir[VmDrive] := E;
  { horloge, clavier, souris }
  VmPitDiv := 65536; VmPitAcc := 0; VmTickDue := 0; VmPitMode := 0;
  VmLastMs := VmMsNow;
  VmPicMask := 0; VmIsr := 0;
  VmKqHead := 0; VmKqTail := 0; VmCurKey := 0; VmPort60 := 0;
  VmPort61 := 0; VmRetr := 0;
  VmMouCellA := 0;
  VmMouReset; VmMouBusy := 0; VmMouBtn := 0;
  VmStrat := 0; VmBreak := 0; VmVerify := 0; VmLastErr := 0;
  VmPendScan := -1; VmLineOk := False; VmLine := ''; VmRetCode := 0;
  VmIdleN := 0; VmFlHi := 0;
  VmTrace := EnvFind('DOSTRACE') <> 0;
  { ecran : celui de la session (curseur de sa console) }
  VmSetCur(0, CurCol, CurRow);
  VmHwCursor;
  VmSetup := True;
End;

{ Fin de la machine : fichiers fermes, memoire rendue, pages de la
  session remises en identite, ecran texte }
Procedure DosStop;
Var I, Fg : LongInt;
Begin
  If Not VmOn Then Exit;
  For I := 0 To VmMaxSft - 1 Do
  Begin
    If (SftRef[I] > 0) And (SftDev[I] = 0) Then CloseHandle(SftH[I]);
    SftRef[I] := 0;
  End;
  For I := 0 To VmMaxFind - 1 Do
    If VmFindH[I] <> 0 Then
    Begin
      FindClose(VmFindH[I]);
      VmFindH[I] := 0;
    End;
  VmRam := -1;      { DpEnd : ne plus toucher a la memoire de la machine }
  DpEnd;
  VmRam := 0;
  asm
    cli
  end;
  Fg := Ord(FgSess = VmSess);
  MemL[0:PageDir] := KernPT Or 7;
  FlushTlb;
  { curseur de la console de la session : celui de la machine }
  If (VmRamPhys <> 0) And (CurSess = VmSess) Then
  Begin
    CurCol := Mem[0:VmRamPhys + $450];
    CurRow := Mem[0:VmRamPhys + $451];
    If CurRow > ScrRows - 1 Then CurRow := ScrRows - 1;
  End;
  { mode graphique au premier plan : retour au texte }
  If VgHwGfx And (Fg <> 0) Then
  Begin
    BiosRegs(3, 0, 0, 0, 0, 0, 0);
    BiosInt($10);
  End;
  VgHwGfx := False;
  If (VmSess >= 0) And SUsed[VmSess] Then
  Begin
    For I := 0 To 1023 Do MemL[0:SPT[VmSess] + I * 4] := (I Shl 12) Or 3;
    SessMap(VmSess, Fg <> 0);
  End;
  MemL[0:PageDir] := CurPde;
  FlushTlb;
  asm
    sti
  end;
  If VmRamPhys <> 0 Then PFree(VmRamPhys);
  VmRamPhys := 0;
  If VgSave <> 0 Then PFree(VgSave);
  VgSave := 0;
  VmFreeAll;
  VmHeapOwn := 0;
  VmGfx := False;
  If VmTask >= 0 Then TkEsp0[VmTask] := 0;
  VmOn := False;
  VmTask := -1;
  VmPid := -1;
  VmSess := -1;
  VmLog('DOS : fin de la machine virtuelle');
End;

{ Tache de la machine (fil 1 du processus) : creer la machine, charger
  le programme puis l'executer }
Procedure DosMain;
Var Err, Psp, Cs, Ip, Ss, Sp : LongInt;
Begin
  VmTask := CurTask;
  If Not VmSetup Then
  Begin
    ConPutLn('SYS0008: Memoire insuffisante pour la session DOS.');
    DosStop;
    KillCurrentProcess(8);
  End;
  Err := VmLoad(VmProg, VmArgs, 0, 0, 0, 0, Psp, Cs, Ip, Ss, Sp);
  If Err <> 0 Then
  Begin
    VmConStr(VmL('Impossible de lancer ', 'Cannot run ', 'Kann nicht ',
               'Impossibile eseguire ', 'No se puede ejecutar ') +
             VmProg + ' (' + IntStr(Err) + ')'#13#10);
    VmLog('DOS : chargement de ' + VmProg + ' impossible (' + IntStr(Err) + ')');
    DosStop;
    KillCurrentProcess(Err);
  End;
  MemL[0:VmLin(Psp, $0A)] := (LongInt(VmBios) Shl 16) + VmExitO;
  VmTopPsp := Psp;
  VmCurPsp := Psp;
  VmDta := (Psp Shl 16) Or $80; VmDtaPM := False;
  FillMem(LongInt(@VmImg), SizeOf(VmImg), 0);
  VmImg[fEip Div 4] := Ip; VmImg[fCs Div 4] := Cs;
  VmImg[fFl Div 4] := $20202;
  VmImg[fEsp Div 4] := Sp; VmImg[fSs Div 4] := Ss;
  VmImg[fEs Div 4] := Psp; VmImg[fDs Div 4] := Psp;
  VmImg[fEcx Div 4] := $FF; VmImg[fEdx Div 4] := Psp;
  VmImg[fEsi Div 4] := Ip; VmImg[fEdi Div 4] := Sp;
  VmImg[fEbp Div 4] := $091C;
  VmIF := True;
  VmLastMs := VmMsNow;
  VmLog('DOS : execution de ' + VmProg + ' en ' + HexStr(Cs, 4) + ':' +
       HexStr(Ip, 4) + ', PSP ' + HexStr(Psp, 4));
  VmRun;
  Err := VmExitCode;
  VmLog('DOS : ' + VmProg + ' termine (code ' + IntStr(Err) + ')');
  DosStop;
  KillCurrentProcess(Err);
End;

{ Programme MS-DOS : .COM, ou MZ sans en-tete PE ni NE (un NE pour OS/2
  1.x des programmes DPMI de Borland se lance par son talon MS-DOS) ;
  C:\COMMAND.COM absent : l'interpreteur integre de la machine }
Function IsDosFile(Path : String) : Boolean;
Var H, Got, L : LongInt; B : Array[0..63] Of Byte; Ext : String;
Begin
  IsDosFile := False;
  If UpStr(BaseName(Path)) = 'COMMAND.COM' Then
  Begin
    IsDosFile := True;
    Exit;
  End;
  Ext := UpStr(Copy(Path, Length(Path) - 3, 4));
  If (Ext <> '.EXE') And (Ext <> '.COM') Then Exit;
  H := KOpenFile(Path, False, 3);
  If H = INVALID_HANDLE Then Exit;
  FillMem(LongInt(@B), 64, 0);
  Got := 0;
  If Not KReadFile(H, LongInt(@B), 64, Got) Then Got := 0;
  If (Got >= 2) And (((B[0] = $4D) And (B[1] = $5A)) Or
                     ((B[0] = $5A) And (B[1] = $4D))) Then
  Begin
    IsDosFile := True;
    L := MemL[0:LongInt(@B) + $3C];
    If (Got = 64) And (L >= 64) And (L < GetFileSize(H, 0) - 4) Then
    Begin
      SetFilePointer(H, L, 0, 0);
      FillMem(LongInt(@B), 64, 0);
      If Not KReadFile(H, LongInt(@B), 64, Got) Then Got := 0;
      If (Got >= 4) And (B[1] = $45) And ((B[0] = $50) Or
         ((B[0] = $4E) And (B[$36] <> 1))) Then
        IsDosFile := False;
    End;
  End
  Else IsDosFile := Ext = '.COM';
  CloseHandle(H);
End;

{ Charger un programme MS-DOS : processus (une seule machine a la fois)
  dont le fil 1 est DosMain ; rend le numero de processus ou -1 }
Function LoadDosProgram(Path, CmdLine : String) : LongInt;
Var Pid, I, Phys, PhysSize, P : LongInt; A : String;
Begin
  LoadDosProgram := -1;
  If VmOn Then
  Begin
    ConPutLn('SYS1804: Une session DOS est deja ouverte (une seule a la fois).');
    LastError := 164;
    Exit;
  End;
  Pid := -1;
  For I := MaxProcs - 1 DownTo 0 Do
    If Not Procs[I].Used Then Pid := I;
  If Pid < 0 Then
  Begin
    LastError := 164;
    Exit;
  End;
  PhysSize := $20000;
  Phys := PAlloc(PhysSize);
  If Phys = 0 Then
  Begin
    LastError := ErrNotEnoughMem;
    Exit;
  End;
  FillMem(Phys, PhysSize, 0);
  Procs[Pid].Used := True;
  Procs[Pid].Running := False;
  Procs[Pid].Parent := CurProc;
  Procs[Pid].PhysBase := Phys;
  Procs[Pid].PhysSize := PhysSize;
  Procs[Pid].ImageSize := 0;
  Procs[Pid].PtAlloc := KAlloc(8192);
  Procs[Pid].PageTable := BuildPageTableAt(Procs[Pid].PtAlloc, Phys, PhysSize);
  Procs[Pid].ExitCode := 259;
  Procs[Pid].Filter := 0;
  Procs[Pid].CmdLine := CmdLine;
  Procs[Pid].CmdBuf := KAlloc(Length(CmdLine) + 1);
  PutPStr(Procs[Pid].CmdBuf, CmdLine, 256);
  Procs[Pid].Name := BaseName(Path);
  Procs[Pid].Path := Path;
  If NextSerial < 2 Then NextSerial := 2;
  Procs[Pid].Serial := NextSerial;
  Inc(NextSerial);
  Procs[Pid].StdOutH := 0;
  Procs[Pid].CurDir := CurDir;
  Procs[Pid].MemLive := True;
  Procs[Pid].HandleOpen := False;
  Procs[Pid].NoPreempt := False;
  Procs[Pid].NextTid := 2;
  Procs[Pid].Sess := 0;
  If CurProc >= 0 Then Procs[Pid].Sess := Procs[CurProc].Sess;
  If (NextSess >= 0) And SUsed[NextSess] Then
  Begin
    Procs[Pid].Sess := NextSess;
    SNew[NextSess] := False;
    NextSess := -1;
  End;
  Procs[Pid].ConSess := Procs[Pid].Sess;
  Procs[Pid].IsLx := False; Procs[Pid].LxFs := 0; Procs[Pid].LxTib := 0;
  ProcEntry[Pid] := LongInt(@DosMain);
  ProcStack[Pid] := Phys + PhysSize - 16;
  { arguments : la ligne de commande sans le nom du programme }
  A := Trim(CmdLine);
  If (Length(A) > 0) And (A[1] = '"') Then
  Begin
    A := Copy(A, 2, 255);
    P := Pos('"', A);
    If P > 0 Then A := Copy(A, P + 1, 255) Else A := '';
  End
  Else
  Begin
    P := Pos(' ', A);
    If P > 0 Then A := Copy(A, P, 255) Else A := '';
  End;
  A := Trim(A);
  If A <> '' Then VmArgs := ' ' + A Else VmArgs := '';
  VmProg := Path;
  VmOn := True;
  VmPid := Pid;
  VmSess := Procs[Pid].Sess;
  VmTask := -1;
  VmLog('Lancement de ' + Path + ' (session DOS ' + IntStr(VmSess) + ')');
  LastError := 0;
  LoadDosProgram := Pid;
End;

{ processus de la machine arrete de l'exterieur (KillOther) }
Procedure DosKilled(Pid : LongInt);
Begin
  If VmOn And (Pid = VmPid) Then DosStop;
End;

Var VmDbgK : LongInt;
Procedure VmLogDbg(N : LongInt);
Var E : LongInt;
Begin
  Inc(VmDbgK);
  If VmDbgK > 8 Then Exit;
  asm
    mov E,esp
  end;
  VmLog('DBG ' + IntStr(N) + ' tache ' + IntStr(CurTask) + ' esp ' + HexStr(E, 8) + ' NextTask ' + IntStr(NextTask) + ' TkEsp ' + HexStr(TkEsp[NextTask], 8));
End;

{ VDM-FIN }

{ LX-DEBUT }
{ ==================================================================== }
{ Partie 13c - Chargeur LX : programmes et DLL d'OS/2 2.x, 3 et 4      }
{ ==================================================================== }
{ Les vrais programmes d'OS/2 32 bits sont au format LX (Linear
  eXecutable). Le chargeur place les objets (code, donnees) dans la
  fenetre du processus (programme) ou dans la region des DLL, decompresse
  les pages iterees (EXEPACK 1 et 2), applique les corrections (fixups)
  internes et les importations (par ordinal ou par nom) vers les DLL
  d'OS/2-0, dont les fonctions suivent la convention _System, et appelle
  l'initialisation des DLL (_DLL_InitTerm). Le module recoit un en-tete
  PE synthetique (MZ, PE, table d'exportation et repertoire des
  ressources) : son handle (HMODULE) est utilisable par DosGetResource,
  DosQueryProcAddr, WinLoadDlg... comme celui d'un module d'OS/2-0. Le
  programme demarre comme sous OS/2 : [ESP] adresse de retour, puis
  handle du module, 0, environnement et ligne de commande ; FS designe
  son bloc d'information de tache (TIB, chaine des gestionnaires
  d'exceptions en FS:[0]). }

Const
  LxMaxObj = 64;
  LxMaxRes = 2048;

Var
  LxB, LxH, LxNObj : LongInt;          { image lue, en-tete LX, objets }
  LxObjAdr, LxObjLin, LxObjSize, LxObjFl : Array[0..LxMaxObj - 1] Of LongInt;
  LxModHdl : Array[0..255] Of LongInt; { modules importes (indice Mods, -1) }
  LxEntAdr : LongInt;                  { adresses des ordinaux (tableau) }
  LxNEnt : LongInt;
  LxPath : String;
  LxErr : String;

Function LxL(O : LongInt) : LongInt;
Begin
  LxL := MemL[0:LxB + O];
End;

Function LxW(O : LongInt) : LongInt;
Begin
  LxW := MemW[0:LxB + O];
End;

Function LxBy(O : LongInt) : LongInt;
Begin
  LxBy := Mem[0:LxB + O];
End;

{ en-tete LX de l'image Buf (0 : pas un module LX) }
Function LxHeader(Buf, Size : LongInt) : LongInt;
Var H : LongInt;
Begin
  LxHeader := 0;
  If Size < 64 Then Exit;
  H := 0;
  If MemW[0:Buf] = $5A4D Then H := MemL[0:Buf + $3C];
  If (H < 0) Or (H + $B0 > Size) Then Exit;
  If (Mem[0:Buf + H] = Ord('L')) And (Mem[0:Buf + H + 1] = Ord('X')) Then LxHeader := H;
End;

{ page iteree (EXEPACK 1) : enregistrements (repetitions, longueur,
  donnees) }
Procedure LxIter1(Src, N, Dst, Max : LongInt);
Var P, Q, Cnt, L, K : LongInt;
Begin
  P := 0; Q := 0;
  While P + 4 <= N Do
  Begin
    Cnt := MemW[0:Src + P]; L := MemW[0:Src + P + 2];
    P := P + 4;
    If (Cnt = 0) Or (L = 0) Then Break;
    For K := 1 To Cnt Do
    Begin
      If Q + L > Max Then Exit;
      MoveMem(Src + P, Dst + Q, L);
      Q := Q + L;
    End;
    P := P + L;
  End;
End;

{ page compressee (EXEPACK 2) : suites de commandes (litteraux, copies
  d'une partie deja decompressee) }
Procedure LxIter2(Src, N, Dst, Max : LongInt);
Var P, Q, C, L, D, K, B2 : LongInt;
Begin
  P := 0; Q := 0;
  While (P < N) And (Q < Max) Do
  Begin
    C := Mem[0:Src + P];
    Case C And 3 Of
      0 :
        If C = 0 Then
        Begin
          { repetition d'un octet : 00 n b }
          If P + 2 >= N Then Exit;
          L := Mem[0:Src + P + 1];
          If L = 0 Then Exit;
          B2 := Mem[0:Src + P + 2];
          For K := 0 To L - 1 Do If Q < Max Then
          Begin
            Mem[0:Dst + Q] := B2; Inc(Q);
          End;
          P := P + 3;
        End
        Else
        Begin
          { litteraux : C shr 2 octets }
          L := C Shr 2;
          For K := 0 To L - 1 Do If Q < Max Then
          Begin
            Mem[0:Dst + Q] := Mem[0:Src + P + 1 + K]; Inc(Q);
          End;
          P := P + 1 + L;
        End;
      1 :
        Begin
          { 0-3 litteraux puis copie courte }
          C := C Or (Mem[0:Src + P + 1] Shl 8);
          L := (C Shr 2) And 3;
          For K := 0 To L - 1 Do If Q < Max Then
          Begin
            Mem[0:Dst + Q] := Mem[0:Src + P + 2 + K]; Inc(Q);
          End;
          P := P + 2 + L;
          L := ((C Shr 4) And 7) + 3;
          D := (C Shr 7) And $1FF;
          For K := 0 To L - 1 Do If (Q < Max) And (Q - D >= 0) Then
          Begin
            Mem[0:Dst + Q] := Mem[0:Dst + Q - D]; Inc(Q);
          End;
        End;
      2 :
        Begin
          { copie courte sans litteraux }
          C := C Or (Mem[0:Src + P + 1] Shl 8);
          P := P + 2;
          L := ((C Shr 2) And 3) + 3;
          D := (C Shr 4) And $FFF;
          For K := 0 To L - 1 Do If (Q < Max) And (Q - D >= 0) Then
          Begin
            Mem[0:Dst + Q] := Mem[0:Dst + Q - D]; Inc(Q);
          End;
        End;
      3 :
        Begin
          { 0-15 litteraux puis copie longue }
          C := C Or (Mem[0:Src + P + 1] Shl 8) Or (Mem[0:Src + P + 2] Shl 16);
          L := (C Shr 2) And $F;
          For K := 0 To L - 1 Do If Q < Max Then
          Begin
            Mem[0:Dst + Q] := Mem[0:Src + P + 3 + K]; Inc(Q);
          End;
          P := P + 3 + L;
          L := (C Shr 6) And $3F;
          D := (C Shr 12) And $FFF;
          For K := 0 To L - 1 Do If (Q < Max) And (Q - D >= 0) Then
          Begin
            Mem[0:Dst + Q] := Mem[0:Dst + Q - D]; Inc(Q);
          End;
        End;
    End;
  End;
End;

{ etat du chargeur (modules charges recursivement) }
Function LxSave : LongInt;
Var A, I : LongInt;
Begin
  A := KAlloc(LxMaxObj * 16 + 256 * 4 + 64);
  If A = 0 Then
  Begin
    LxSave := 0;
    Exit;
  End;
  For I := 0 To LxMaxObj - 1 Do
  Begin
    MemL[0:A + I * 16] := LxObjAdr[I]; MemL[0:A + I * 16 + 4] := LxObjLin[I];
    MemL[0:A + I * 16 + 8] := LxObjSize[I]; MemL[0:A + I * 16 + 12] := LxObjFl[I];
  End;
  For I := 0 To 255 Do MemL[0:A + LxMaxObj * 16 + I * 4] := LxModHdl[I];
  I := A + LxMaxObj * 16 + 1024;
  MemL[0:I] := LxB; MemL[0:I + 4] := LxH; MemL[0:I + 8] := LxNObj;
  MemL[0:I + 12] := LxEntAdr; MemL[0:I + 16] := LxNEnt;
  LxSave := A;
End;

Procedure LxRestore(A : LongInt);
Var I : LongInt;
Begin
  If A = 0 Then Exit;
  For I := 0 To LxMaxObj - 1 Do
  Begin
    LxObjAdr[I] := MemL[0:A + I * 16]; LxObjLin[I] := MemL[0:A + I * 16 + 4];
    LxObjSize[I] := MemL[0:A + I * 16 + 8]; LxObjFl[I] := MemL[0:A + I * 16 + 12];
  End;
  For I := 0 To 255 Do LxModHdl[I] := MemL[0:A + LxMaxObj * 16 + I * 4];
  I := A + LxMaxObj * 16 + 1024;
  LxB := MemL[0:I]; LxH := MemL[0:I + 4]; LxNObj := MemL[0:I + 8];
  LxEntAdr := MemL[0:I + 12]; LxNEnt := MemL[0:I + 16];
  KFree(A);
End;

{ module importe numero K (1..n) : indice dans Mods (charge au besoin) }
Function LxImpMod(K : LongInt) : LongInt;
Var P, I, L, Sv, M : LongInt; S : String;
Begin
  LxImpMod := -1;
  If (K < 1) Or (K > 255) Then Exit;
  If LxModHdl[K] <> -2 Then
  Begin
    LxImpMod := LxModHdl[K];
    Exit;
  End;
  P := LxH + LxL(LxH + $70);
  For I := 1 To K - 1 Do P := P + LxBy(P) + 1;
  L := LxBy(P);
  S := '';
  For I := 1 To L Do S := S + Chr(LxBy(P + I));
  S := UpStr(S);
  If Pos('.', S) = 0 Then S := S + '.DLL';
  { chargement d'une dependance (peut-etre un autre module LX) : etat du
    chargeur sauve }
  Sv := LxSave;
  M := LoadModule(S);
  LxRestore(Sv);
  LxModHdl[K] := M;
  If LxModHdl[K] < 0 Then LxErr := 'module ' + S + ' introuvable';
  LxImpMod := LxModHdl[K];
End;

{ nom de procedure importee a l'offset O de la table des noms }
Function LxImpName(O : LongInt) : String;
Var P, I, L : LongInt; S : String;
Begin
  P := LxH + LxL(LxH + $78) + O;
  L := LxBy(P);
  S := '';
  For I := 1 To L Do S := S + Chr(LxBy(P + I));
  LxImpName := S;
End;

{ importations absentes : une souche par importation (PUSH n ; JMP
  LxMissing) qui journalise le module et l'ordinal (ou le nom) et rend
  ERROR_INVALID_FUNCTION (1) ; le programme continue }
Var
  LxMissN : LongInt;
  LxMissName : Array[0..511] Of String[47];
  LxMissBlk : LongInt;

Procedure LxMissing;
Var N, R : LongInt;
Begin
  asm
    mov eax,[ebp+8]
    mov N,eax
  end;
  If (N >= 0) And (N < LxMissN) Then KLog('LX : fonction absente appelee : ' + LxMissName[N]);
End;

Function LxStub(Nm : String) : LongInt;
Var A, T : LongInt;
Begin
  LxStub := 0;
  If LxMissN >= 512 Then Exit;
  If LxMissBlk = 0 Then LxMissBlk := KAlloc(512 * 32 + 64);
  If LxMissBlk = 0 Then Exit;
  A := ((LxMissBlk + 15) And Not 15) + LxMissN * 32;
  LxMissName[LxMissN] := Nm;
  T := LongInt(@LxMissing);
  { pushad ; push n ; call LxMissing ; add esp,4 ; popad ; mov eax,1 ; ret }
  Mem[0:A] := $60;
  Mem[0:A + 1] := $68; MemL[0:A + 2] := LxMissN;
  Mem[0:A + 6] := $E8; MemL[0:A + 7] := T - (A + 11);
  Mem[0:A + 11] := $83; Mem[0:A + 12] := $C4; Mem[0:A + 13] := 4;
  Mem[0:A + 14] := $61;
  Mem[0:A + 15] := $B8; MemL[0:A + 16] := 1;
  Mem[0:A + 20] := $C3;
  LxStub := A;
  Inc(LxMissN);
End;

Function LxStubFor(Nm : String) : LongInt;
Var I : LongInt;
Begin
  For I := 0 To LxMissN - 1 Do
    If LxMissName[I] = Nm Then
    Begin
      LxStubFor := ((LxMissBlk + 15) And Not 15) + I * 32;
      Exit;
    End;
  KLog('LX : importation absente : ' + Nm);
  LxStubFor := LxStub(Nm);
End;

{ adresse de l'ordinal Ord du module en cours de chargement (0 : aucun) }
Function LxSelfOrd(Ord : LongInt) : LongInt;
Begin
  LxSelfOrd := 0;
  If (Ord >= 1) And (Ord <= LxNEnt) And (LxEntAdr <> 0) Then
    LxSelfOrd := MemL[0:LxEntAdr + (Ord - 1) * 4];
End;

{ table des points d'entree : adresse de chaque ordinal ; les renvois
  (forwarders) sont resolus vers le module cible }
Procedure LxEntries;
Var P, Cnt, Typ, Obj, K, Ord, A, Fl, MI, V, M : LongInt;
Begin
  { premier passage : nombre d'ordinaux }
  P := LxH + LxL(LxH + $5C);
  Ord := 0;
  Repeat
    Cnt := LxBy(P);
    If Cnt = 0 Then Break;
    Typ := LxBy(P + 1);
    If Typ = 0 Then
    Begin
      Ord := Ord + Cnt;
      P := P + 2;
    End
    Else
    Begin
      Ord := Ord + Cnt;
      Case Typ Of
        1 : P := P + 4 + Cnt * 3;
        2 : P := P + 4 + Cnt * 5;
        3 : P := P + 4 + Cnt * 5;
        4 : P := P + 4 + Cnt * 7;
      Else
        Break;
      End;
    End;
  Until False;
  LxNEnt := Ord;
  LxEntAdr := 0;
  If Ord = 0 Then Exit;
  LxEntAdr := KAlloc(Ord * 4 + 4);
  FillMem(LxEntAdr, Ord * 4 + 4, 0);
  P := LxH + LxL(LxH + $5C);
  Ord := 0;
  Repeat
    Cnt := LxBy(P);
    If Cnt = 0 Then Break;
    Typ := LxBy(P + 1);
    If Typ = 0 Then
    Begin
      Ord := Ord + Cnt;
      P := P + 2;
      Continue;
    End;
    Obj := LxW(P + 2);
    P := P + 4;
    For K := 1 To Cnt Do
    Begin
      Inc(Ord);
      A := 0;
      Case Typ Of
        1 :
          Begin
            If (Obj >= 1) And (Obj <= LxNObj) Then A := LxObjLin[Obj - 1] + LxW(P + 1);
            P := P + 3;
          End;
        2 :
          Begin
            If (Obj >= 1) And (Obj <= LxNObj) Then A := LxObjLin[Obj - 1] + LxW(P + 1);
            P := P + 5;
          End;
        3 :
          Begin
            If (Obj >= 1) And (Obj <= LxNObj) Then A := LxObjLin[Obj - 1] + LxL(P + 1);
            P := P + 5;
          End;
        4 :
          Begin
            Fl := LxBy(P);
            MI := LxW(P + 1);
            V := LxL(P + 3);
            M := LxImpMod(MI);
            If M >= 0 Then
            Begin
              If (Fl And 1) <> 0 Then A := ModuleExport(M, '', V)
              Else A := ModuleExport(M, LxImpName(V), 0);
            End;
            P := P + 7;
          End;
      End;
      MemL[0:LxEntAdr + (Ord - 1) * 4] := A;
    End;
  Until False;
End;

{ corrections d'une page (indice logique Pg, 0..) chargee a l'adresse
  (noyau) PgAdr, vue par le programme en PgLin ; False : importation
  introuvable }
Function LxFixPage(Pg, PgAdr, PgLin : LongInt) : Boolean;
Var Q, E, Src, Tf, Cnt, SrcOff, Typ, Obj, Ofs, M, Ord, T, Add, K, Lst, Sel, A : LongInt;
    Nm : String;
Begin
  LxFixPage := True;
  Q := LxH + LxL(LxH + $6C) + LxL(LxH + LxL(LxH + $68) + Pg * 4);
  E := LxH + LxL(LxH + $6C) + LxL(LxH + LxL(LxH + $68) + Pg * 4 + 4);
  While Q < E Do
  Begin
    Src := LxBy(Q); Tf := LxBy(Q + 1);
    Q := Q + 2;
    Cnt := 0; SrcOff := 0; Lst := 0;
    If (Src And $20) <> 0 Then
    Begin
      Cnt := LxBy(Q);
      Q := Q + 1;
    End
    Else
    Begin
      SrcOff := LxW(Q);
      If SrcOff >= $8000 Then SrcOff := SrcOff - $10000;
      Q := Q + 2;
    End;
    T := 0; Sel := $10;
    Typ := Tf And 3;
    If Typ = 0 Then
    Begin
      If (Tf And $40) <> 0 Then
      Begin
        Obj := LxW(Q); Q := Q + 2;
      End
      Else
      Begin
        Obj := LxBy(Q); Q := Q + 1;
      End;
      Ofs := 0;
      If (Src And $F) <> 2 Then
      Begin
        If (Tf And $10) <> 0 Then
        Begin
          Ofs := LxL(Q); Q := Q + 4;
        End
        Else
        Begin
          Ofs := LxW(Q); Q := Q + 2;
        End;
      End;
      If (Obj >= 1) And (Obj <= LxNObj) Then
      Begin
        T := LxObjLin[Obj - 1] + Ofs;
        If (LxObjFl[Obj - 1] And 4) <> 0 Then Sel := $08;
      End;
    End
    Else If Typ = 3 Then
    Begin
      If (Tf And $40) <> 0 Then
      Begin
        Ord := LxW(Q); Q := Q + 2;
      End
      Else
      Begin
        Ord := LxBy(Q); Q := Q + 1;
      End;
      T := LxSelfOrd(Ord);
    End
    Else
    Begin
      If (Tf And $40) <> 0 Then
      Begin
        M := LxW(Q); Q := Q + 2;
      End
      Else
      Begin
        M := LxBy(Q); Q := Q + 1;
      End;
      If Typ = 1 Then
      Begin
        If (Tf And $80) <> 0 Then
        Begin
          Ord := LxBy(Q); Q := Q + 1;
        End
        Else If (Tf And $10) <> 0 Then
        Begin
          Ord := LxL(Q); Q := Q + 4;
        End
        Else
        Begin
          Ord := LxW(Q); Q := Q + 2;
        End;
        K := LxImpMod(M);
        If K >= 0 Then T := ModuleExport(K, '', Ord);
        If T = 0 Then
        Begin
          If K >= 0 Then Nm := Mods^[K].Name Else Nm := 'module ' + IntStr(M);
          Nm := Nm + '.' + IntStr(Ord);
          T := LxStubFor(Nm);
          If T = 0 Then LxFixPage := False;
        End;
        Sel := $08;
      End
      Else
      Begin
        If (Tf And $10) <> 0 Then
        Begin
          Ofs := LxL(Q); Q := Q + 4;
        End
        Else
        Begin
          Ofs := LxW(Q); Q := Q + 2;
        End;
        Nm := LxImpName(Ofs);
        K := LxImpMod(M);
        If K >= 0 Then T := ModuleExport(K, Nm, 0);
        If T = 0 Then T := KernelExport(Nm);
        If T = 0 Then
        Begin
          T := LxStubFor(Nm);
          If T = 0 Then LxFixPage := False;
        End;
        Sel := $08;
      End;
    End;
    Add := 0;
    If (Tf And 4) <> 0 Then
    Begin
      If (Tf And $20) <> 0 Then
      Begin
        Add := LxL(Q); Q := Q + 4;
      End
      Else
      Begin
        Add := LxW(Q); Q := Q + 2;
      End;
    End;
    T := T + Add;
    If (Src And $20) <> 0 Then
    Begin
      Lst := Q;
      Q := Q + Cnt * 2;
    End
    Else Cnt := 1;
    For K := 0 To Cnt - 1 Do
    Begin
      If Lst <> 0 Then
      Begin
        SrcOff := LxW(Lst + K * 2);
        If SrcOff >= $8000 Then SrcOff := SrcOff - $10000;
      End;
      A := PgAdr + SrcOff;
      Case Src And $F Of
        0 : Mem[0:A] := T And $FF;
        2 : MemW[0:A] := Sel;
        3 :
          Begin
            MemW[0:A] := T And $FFFF;
            MemW[0:A + 2] := Sel;
          End;
        5 : MemW[0:A] := T And $FFFF;
        6 :
          Begin
            MemL[0:A] := T;
            MemW[0:A + 4] := Sel;
          End;
        7 : MemL[0:A] := T;
        8 : MemL[0:A] := T - (PgLin + SrcOff + 4);
      End;
    End;
  End;
End;

{ charger les objets de l'image (LxB) : Mem (noyau) et Lin (programme)
  sont l'adresse de la zone ; Hdr octets reserves devant (en-tete PE
  synthetique) ; rend False et LxErr en cas d'echec }
Function LxLoadObjects(Mem0, Lin0, Hdr : LongInt) : Boolean;
Var I, O, Vs, Fl, Pmi, Pmn, Pg, PO, PSz, PFl, A, Off, DataPg, Shift : LongInt;
Begin
  LxLoadObjects := False;
  Off := Hdr;
  For I := 0 To LxNObj - 1 Do
  Begin
    LxObjAdr[I] := Mem0 + Off;
    LxObjLin[I] := Lin0 + Off;
    Off := Off + ((LxObjSize[I] + 4095) And Not 4095);
  End;
  DataPg := LxL(LxH + $80);
  Shift := LxL(LxH + $2C);
  For I := 0 To LxNObj - 1 Do
  Begin
    O := LxH + LxL(LxH + $40) + I * 24;
    Vs := LxL(O); Fl := LxL(O + 8); Pmi := LxL(O + 12); Pmn := LxL(O + 16);
    FillMem(LxObjAdr[I], (Vs + 4095) And Not 4095, 0);
    For Pg := 0 To Pmn - 1 Do
    Begin
      A := LxH + LxL(LxH + $48) + (Pmi - 1 + Pg) * 8;
      PO := MemL[0:LxB + A]; PSz := MemW[0:LxB + A + 4]; PFl := MemW[0:LxB + A + 6];
      If Pg * 4096 >= ((Vs + 4095) And Not 4095) Then Break;
      Case PFl Of
        0 : MoveMem(LxB + DataPg + (PO Shl Shift), LxObjAdr[I] + Pg * 4096, Min(PSz, 4096));
        1 : LxIter1(LxB + DataPg + (PO Shl Shift), PSz, LxObjAdr[I] + Pg * 4096, 4096);
        5 : LxIter2(LxB + DataPg + (PO Shl Shift), PSz, LxObjAdr[I] + Pg * 4096, 4096);
      End;
    End;
  End;
  LxEntries;
  { corrections, page par page }
  For I := 0 To LxNObj - 1 Do
  Begin
    O := LxH + LxL(LxH + $40) + I * 24;
    Vs := LxL(O); Pmi := LxL(O + 12); Pmn := LxL(O + 16);
    For Pg := 0 To Pmn - 1 Do
      If Not LxFixPage(Pmi - 1 + Pg, LxObjAdr[I] + Pg * 4096, LxObjLin[I] + Pg * 4096) Then
      Begin
        LxLoadObjects := False;
        Exit;
      End;
  End;
  LxLoadObjects := True;
End;

{ nombre d'ordinaux de la table des points d'entree }
Function LxCountEnt : LongInt;
Var P, Cnt, Typ, Ord : LongInt;
Begin
  P := LxH + LxL(LxH + $5C);
  Ord := 0;
  Repeat
    Cnt := LxBy(P);
    If Cnt = 0 Then Break;
    Typ := LxBy(P + 1);
    Ord := Ord + Cnt;
    Case Typ Of
      0 : P := P + 2;
      1 : P := P + 4 + Cnt * 3;
      2, 3 : P := P + 4 + Cnt * 5;
      4 : P := P + 4 + Cnt * 7;
    Else
      Break;
    End;
  Until False;
  LxCountEnt := Ord;
End;

{ taille de l'en-tete PE synthetique : exportations et ressources }
Function LxHdrSize : LongInt;
Var N, P : LongInt;
Begin
  N := 4096;
  P := LxH + LxL(LxH + $58);
  While LxBy(P) <> 0 Do
  Begin
    N := N + LxBy(P) + 12;
    P := P + LxBy(P) + 3;
  End;
  N := N + LxL(LxH + $8C) * 2;
  N := N + LxCountEnt * 4;
  N := N + LxL(LxH + $54) * 64;
  LxHdrSize := (N + 4095) And Not 4095;
End;

Var
  LxNmAdr, LxNmOrd : Array[0..4095] Of LongInt;   { noms exportes : adresse, ordinal }
  LxNmN : LongInt;

{ ajouter les noms d'une table de noms (residents ou non residents) ;
  Q : ecriture des chaines (adresse noyau), QL : leur adresse lineaire }
Procedure LxAddNames(P, Stop : LongInt; Var Q, QL : LongInt);
Var L, I, O : LongInt; First : Boolean;
Begin
  First := True;
  While (P < Stop) And (LxBy(P) <> 0) Do
  Begin
    L := LxBy(P);
    O := LxW(P + 1 + L);
    If Not First And (O <> 0) And (LxNmN < 4096) Then
    Begin
      For I := 0 To L - 1 Do Mem[0:Q + I] := UpCh(LxBy(P + 1 + I));
      Mem[0:Q + L] := 0;
      LxNmAdr[LxNmN] := QL; LxNmOrd[LxNmN] := O;
      Inc(LxNmN);
      Q := Q + L + 1; QL := QL + L + 1;
    End;
    First := False;
    P := P + L + 3;
  End;
End;

{ en-tete PE synthetique en Mem0 (vu en Lin0, le handle du module) :
  MZ, PE, exportations (ordinaux et noms) et repertoire des ressources
  (type, nom, langue unique) }
Procedure LxBuildHdr(Mem0, Lin0, Size, Entry : LongInt);
Var Pe, Opt, Ex, Q, QL, I, J, K, NRes, R, Typ, Nm, Obj, Ofs, Sz, Root, NT, D, E, T0 : LongInt;
    Types : Array[0..63] Of LongInt;
Begin
  FillMem(Mem0, 1024, 0);
  MemW[0:Mem0] := $5A4D;
  MemL[0:Mem0 + $3C] := $40;
  Pe := Mem0 + $40;
  MemL[0:Pe] := $00004550;
  MemW[0:Pe + 4] := $014C;
  MemW[0:Pe + 20] := 224;
  Opt := Pe + 24;
  MemW[0:Opt] := $10B;
  If Entry <> 0 Then MemL[0:Opt + 16] := Entry - Lin0;
  MemL[0:Opt + 28] := Lin0;
  MemL[0:Opt + 56] := Size;
  MemL[0:Opt + 60] := 1024;
  { exportations }
  LxNmN := 0;
  Q := Mem0 + 1024; QL := Lin0 + 1024;
  LxAddNames(LxH + LxL(LxH + $58), LxH + LxL(LxH + $5C), Q, QL);
  If LxL(LxH + $88) <> 0 Then
    LxAddNames(LxL(LxH + $88), LxL(LxH + $88) + LxL(LxH + $8C), Q, QL);
  Q := (Q + 3) And Not 3; QL := (QL + 3) And Not 3;
  Ex := Q;
  MemL[0:Opt + 96] := QL - Lin0;
  MemL[0:Opt + 100] := 40;
  FillMem(Ex, 40, 0);
  MemL[0:Ex + 16] := 1;
  MemL[0:Ex + 20] := LxNEnt;
  MemL[0:Ex + 24] := LxNmN;
  Q := Q + 40; QL := QL + 40;
  MemL[0:Ex + 28] := QL - Lin0;
  For I := 0 To LxNEnt - 1 Do
  Begin
    If MemL[0:LxEntAdr + I * 4] <> 0 Then MemL[0:Q + I * 4] := MemL[0:LxEntAdr + I * 4] - Lin0
    Else MemL[0:Q + I * 4] := 0;
  End;
  Q := Q + LxNEnt * 4; QL := QL + LxNEnt * 4;
  MemL[0:Ex + 32] := QL - Lin0;
  For I := 0 To LxNmN - 1 Do MemL[0:Q + I * 4] := LxNmAdr[I] - Lin0;
  Q := Q + LxNmN * 4; QL := QL + LxNmN * 4;
  MemL[0:Ex + 36] := QL - Lin0;
  For I := 0 To LxNmN - 1 Do MemW[0:Q + I * 2] := LxNmOrd[I] - 1;
  Q := Q + LxNmN * 2 + 4; QL := QL + LxNmN * 2 + 4;
  Q := (Q + 3) And Not 3; QL := (QL + 3) And Not 3;
  { ressources : table LX (type, nom, taille, objet, deplacement) }
  NRes := LxL(LxH + $54);
  If NRes > 0 Then
  Begin
    R := LxH + LxL(LxH + $50);
    NT := 0;
    For I := 0 To NRes - 1 Do
    Begin
      Typ := LxW(R + I * 14);
      K := 0;
      For J := 0 To NT - 1 Do If Types[J] = Typ Then K := 1;
      If (K = 0) And (NT < 64) Then
      Begin
        Types[NT] := Typ; Inc(NT);
      End;
    End;
    Root := Q;
    MemL[0:Opt + 112] := QL - Lin0;
    MemL[0:Opt + 116] := 16;
    FillMem(Root, 16 + NT * 8, 0);
    MemW[0:Root + 14] := NT;
    Q := Q + 16 + NT * 8;
    For J := 0 To NT - 1 Do
    Begin
      { sous-repertoire des noms du type Types[J] }
      D := Q;
      K := 0;
      For I := 0 To NRes - 1 Do If LxW(R + I * 14) = Types[J] Then Inc(K);
      FillMem(D, 16 + K * 8, 0);
      MemW[0:D + 14] := K;
      MemL[0:Root + 16 + J * 8] := Types[J];
      MemL[0:Root + 16 + J * 8 + 4] := (D - Root) Or LongInt($80000000);
      Q := Q + 16 + K * 8;
      K := 0;
      For I := 0 To NRes - 1 Do
        If LxW(R + I * 14) = Types[J] Then
        Begin
          Nm := LxW(R + I * 14 + 2); Sz := LxL(R + I * 14 + 4);
          Obj := LxW(R + I * 14 + 8); Ofs := LxL(R + I * 14 + 10);
          { langue : un repertoire d'une entree, puis la donnee }
          E := Q;
          FillMem(E, 16 + 8 + 16, 0);
          MemW[0:E + 14] := 1;
          MemL[0:E + 16] := 0;
          MemL[0:E + 20] := E + 24 - Root;
          T0 := 0;
          If (Obj >= 1) And (Obj <= LxNObj) Then T0 := LxObjLin[Obj - 1] + Ofs;
          MemL[0:E + 24] := T0 - Lin0;
          MemL[0:E + 28] := Sz;
          MemL[0:D + 16 + K * 8] := Nm;
          MemL[0:D + 16 + K * 8 + 4] := (E - Root) Or LongInt($80000000);
          Q := Q + 40;
          Inc(K);
        End;
    End;
  End;
End;

{ lire l'en-tete LX et la table des objets de l'image Buf ; taille
  totale des objets (alignes a 4 Ko) }
Function LxPrepare(Buf, Size : LongInt) : LongInt;
Var I, O, T : LongInt;
Begin
  LxPrepare := -1;
  LxB := Buf;
  LxH := LxHeader(Buf, Size);
  If LxH = 0 Then Exit;
  LxNObj := LxL(LxH + $44);
  If (LxNObj <= 0) Or (LxNObj > LxMaxObj) Then Exit;
  T := 0;
  For I := 0 To LxNObj - 1 Do
  Begin
    O := LxH + LxL(LxH + $40) + I * 24;
    LxObjSize[I] := LxL(O);
    LxObjFl[I] := LxL(O + 8);
    T := T + ((LxObjSize[I] + 4095) And Not 4095);
  End;
  For I := 0 To 255 Do LxModHdl[I] := -2;
  LxErr := '';
  LxEntAdr := 0; LxNEnt := 0;
  LxPrepare := T;
End;

{ point d'entree (objet:deplacement de l'en-tete) ; 0 : aucun }
Function LxEip : LongInt;
Var O : LongInt;
Begin
  LxEip := 0;
  O := LxL(LxH + $18);
  If (O >= 1) And (O <= LxNObj) Then LxEip := LxObjLin[O - 1] + LxL(LxH + $1C);
End;

{ DLL LX : objets dans la region des DLL ; module M (table des modules)
  rempli ; False et LxErr en cas d'echec. L'initialisation
  (_DLL_InitTerm(hmod, 0), convention _System) est appelee. }
Function LxLoadDll(Path : String; Buf, Size, M : LongInt) : Boolean;
Var T, Hdr, Base, E, R, H : LongInt;
Begin
  LxLoadDll := False;
  T := LxPrepare(Buf, Size);
  If T < 0 Then Exit;
  Hdr := LxHdrSize;
  Base := DllFindSpace(T + Hdr);
  If Base = 0 Then
  Begin
    LxErr := 'plus de place dans la region des DLL';
    Exit;
  End;
  { le module est inscrit avant les importations (dependances
    circulaires) }
  Mods^[M].Used := True;
  Mods^[M].Name := UpStr(BaseName(Path));
  Mods^[M].Path := Path;
  Mods^[M].Base := Base;
  Mods^[M].Size := T + Hdr;
  Mods^[M].NExp := 0; Mods^[M].OrdBase := 1; Mods^[M].NFunc := 0;
  FillMem(Base, Hdr, 0);
  If Not LxLoadObjects(Base, Base, Hdr) Then
  Begin
    Mods^[M].Used := False;
    Exit;
  End;
  E := LxEip;
  LxBuildHdr(Base, Base, T + Hdr, E);
  H := Base + MemL[0:Base + $40 + 24 + 96];
  Mods^[M].NExp := MemL[0:H + 24];
  Mods^[M].OrdBase := MemL[0:H + 16];
  Mods^[M].NFunc := MemL[0:H + 20];
  Mods^[M].Funcs := Base + MemL[0:H + 28];
  Mods^[M].Names := Base + MemL[0:H + 32];
  Mods^[M].Ords := Base + MemL[0:H + 36];
  If LxEntAdr <> 0 Then KFree(LxEntAdr);
  LxEntAdr := 0;
  KLog(Mods^[M].Name + ' (module LX) charge en ' + HexStr(Base, 8) + 'h.');
  If E <> 0 Then
  Begin
    R := 0;
    asm
      push ebx
      push esi
      push edi
      push 0
      mov eax,Base
      push eax
      mov eax,E
      call eax
      add esp,8
      mov R,eax
      pop edi
      pop esi
      pop ebx
    end;
    If R = 0 Then KLog(Mods^[M].Name + ' : _DLL_InitTerm a refuse le chargement.');
  End;
  LxLoadDll := True;
End;

{ fil 1 d'un programme LX : bloc d'information de tache (TIB, FS),
  environnement et ligne de commande au format d'OS/2, puis le point
  d'entree : EAX = main(hmod, 0, env, cmd) ; fin du processus au retour }
Procedure LxStart;
Var P, E, H, En, Cm, R, Tib, Sel, I, K : LongInt; Args : String;
Begin
  P := CurProc;
  E := Procs[P].LxEip;
  H := ProcWinBase;
  Tib := (Procs[P].PhysBase + Procs[P].ImageSize + 4095) And Not 4095;
  FillMem(Tib, 4096, 0);
  MemL[0:Tib] := -1;                                  { fin de la chaine d'exceptions }
  MemL[0:Tib + 4] := Tib + 4096;                      { bas de la pile }
  MemL[0:Tib + 8] := Procs[P].PhysBase + Procs[P].PhysSize;
  MemL[0:Tib + 12] := Tib + 24;                       { TIB2 }
  MemL[0:Tib + 16] := 20;
  MemL[0:Tib + 20] := 1;
  MemL[0:Tib + 24] := 1;                              { identificateur du fil }
  MemL[0:Tib + 28] := $200;
  MemL[0:Tib + 32] := 20;
  Procs[P].LxTib := Tib;
  Sel := SelAlloc(1);
  If Sel <> 0 Then
  Begin
    DescSet((Sel Shr 3) And $1FFF, Tib, $FFF, $92);
    Sel := (Sel And $FFF8) Or 4;                      { LDT, anneau 0 }
    Procs[P].LxFs := Sel;
    TkFs[CurTask] := Sel;
    asm
      mov eax,Sel
      mov fs,ax
    end;
  End;
  { environnement : NOM=VALEUR#0...#0 }
  En := Tib + 1024;
  K := EnvSize;
  If K > 2048 Then K := 2048;
  MoveMem(LongInt(@EnvBlock), En, K);
  Mem[0:En + K] := 0; Mem[0:En + K + 1] := 0;
  { ligne de commande : programme#0 arguments#0#0 }
  Cm := En + K + 4;
  PutPStr(Cm, Procs[P].Path, 256);
  I := Length(Procs[P].Path) + 1;
  Args := Trim(Procs[P].CmdLine);
  If (Length(Args) > 0) And (Args[1] = '"') Then
  Begin
    Args := Copy(Args, 2, 255);
    K := Pos('"', Args);
    If K > 0 Then Args := Copy(Args, K + 1, 255) Else Args := '';
  End
  Else
  Begin
    K := Pos(' ', Args);
    If K > 0 Then Args := Copy(Args, K, 255) Else Args := '';
  End;
  Args := Trim(Args);
  PutPStr(Cm + I, Args, 256);
  Mem[0:Cm + I + Length(Args) + 1] := 0;
  KLog('LX : demarrage de ' + Procs[P].Path + ' en ' + HexStr(E, 8) + 'h');
  R := 0;
  asm
    mov eax,Cm
    push eax
    mov eax,En
    push eax
    push 0
    mov eax,H
    push eax
    mov eax,E
    call eax
    add esp,16
    mov R,eax
  end;
  KillCurrentProcess(R);
End;

{ programme LX : processus dont la fenetre (00400000h) contient
  l'en-tete synthetique (le HMODULE du programme) puis les objets ; son
  fil 1 commence par LxStart ; -1 en cas d'echec }
Function LxLoadExe(Path, CmdLine : String; Buf, Size : LongInt) : LongInt;
Var T, Hdr, Pid, I, Phys, PhysSize, Total, E : LongInt;
Begin
  LxLoadExe := -1;
  LastError := ErrBadFormat;
  T := LxPrepare(Buf, Size);
  If T < 0 Then Exit;
  Hdr := LxHdrSize;
  Total := Hdr + T;
  If Total > ProcWinSize Then
  Begin
    LastError := ErrNotEnoughMem;
    Exit;
  End;
  Pid := -1;
  For I := MaxProcs - 1 DownTo 0 Do
    If Not Procs[I].Used Then Pid := I;
  If Pid < 0 Then
  Begin
    LastError := 164;
    Exit;
  End;
  PhysSize := Total + ProcStackSize;
  Phys := PAlloc(PhysSize);
  If Phys = 0 Then
  Begin
    LastError := ErrNotEnoughMem;
    Exit;
  End;
  FillMem(Phys, PhysSize, 0);
  { les importations peuvent charger des DLL : le processus est reserve }
  Procs[Pid].Used := True;
  Procs[Pid].Running := False;
  Procs[Pid].MemLive := True;
  If Not LxLoadObjects(Phys, ProcWinBase, Hdr) Then
  Begin
    ConPutLn('SYS0191: ' + Path + ' : ' + LxErr + '.');
    KLog('LX : ' + Path + ' : ' + LxErr);
    Procs[Pid].Used := False;
    PFree(Phys);
    If LxEntAdr <> 0 Then KFree(LxEntAdr);
    LastError := 127;
    Exit;
  End;
  E := LxEip;
  LxBuildHdr(Phys, ProcWinBase, Total, E);
  If LxEntAdr <> 0 Then KFree(LxEntAdr);
  LxEntAdr := 0;
  Procs[Pid].Parent := CurProc;
  Procs[Pid].PhysBase := Phys;
  Procs[Pid].PhysSize := PhysSize;
  Procs[Pid].ImageSize := Total;
  Procs[Pid].PtAlloc := KAlloc(8192);
  Procs[Pid].PageTable := BuildPageTableAt(Procs[Pid].PtAlloc, Phys, Total);
  Procs[Pid].ExitCode := 259;
  Procs[Pid].Filter := 0;
  Procs[Pid].CmdLine := CmdLine;
  Procs[Pid].CmdBuf := KAlloc(Length(CmdLine) + 1);
  PutPStr(Procs[Pid].CmdBuf, CmdLine, 256);
  Procs[Pid].Name := BaseName(Path);
  Procs[Pid].Path := Path;
  If NextSerial < 2 Then NextSerial := 2;
  Procs[Pid].Serial := NextSerial;
  Inc(NextSerial);
  Procs[Pid].StdOutH := 0;
  If CurProc >= 0 Then Procs[Pid].StdOutH := Procs[CurProc].StdOutH;
  Procs[Pid].CurDir := CurDir;
  Procs[Pid].HandleOpen := False;
  Procs[Pid].NoPreempt := False;
  Procs[Pid].NextTid := 2;
  Procs[Pid].Sess := 0;
  If CurProc >= 0 Then Procs[Pid].Sess := Procs[CurProc].Sess;
  If (NextSess >= 0) And SUsed[NextSess] Then
  Begin
    Procs[Pid].Sess := NextSess;
    SNew[NextSess] := False;
    NextSess := -1;
  End;
  Procs[Pid].ConSess := Procs[Pid].Sess;
  Procs[Pid].IsLx := True;
  Procs[Pid].LxEip := E;
  ProcEntry[Pid] := LongInt(@LxStart);
  { pile : le haut du bloc physique (vue par son adresse physique, comme
    les programmes d'OS/2-0) }
  ProcStack[Pid] := Phys + PhysSize - 16;
  KLog('LX : ' + Path + ' charge (' + IntStr(LxNObj) + ' objets, point d''entree ' + HexStr(E, 8) + 'h).');
  LastError := 0;
  LxLoadExe := Pid;
End;

Function LxLastErr : String;
Begin
  LxLastErr := LxErr;
End;
{ LX-FIN }

Procedure Banner;
Begin
  TextAttr := $1F;
  ConPutLn(' OS/2-0 version ' + KVersion + ' - noyau 32 bits OS2KRNL (Pascal, OS2PC)               ');
  TextAttr := $07;
  ConPutLn('Memoire : ' + IntStr(MemTotalKb) + ' Ko, tas du noyau : ' +
           IntStr((HeapEnd - HeapStart) Div 1024) + ' Ko, pagination active.');
  { carte video : modes VESA releves par le BIOS (INT 10h, 4F00h/4F01h) }
  If KrnVideo(0, 0, 0) <> 0 Then
    ConPutLn('Video : VESA (VBE ' + IntStr(VbeVer Shr 8) + '.' + IntStr(VbeVer And 255) + ', ' + IntStr(VbeMemKb) +
             ' Ko, ' + IntStr(VbeCount) + ' modes graphiques utilisables) ' + VbeOem + '.')
  Else ConPutLn('Video : VGA (pas de BIOS VESA).');
End;

Var
  KBase, KSize, Pid, Code, Runs : LongInt;
  ShellCmd, P2 : String;
  I : LongInt;

BEGIN
  TextAttr := $07;
  ConRows := ScrRows;
  ConRowsOwner := -2;
  CurRow := Mem[0:BootInfo + $28];
  CurCol := 0;
  CurProc := -1;
  KernelDir := 'C:\';
  SerialInit;
  InitGdt;
  InitIdt;
  InitTss;
  InitPic;
  InitTimer;
  InitKeyboard;
  asm
    sti
  end;
  InitMouse;
  { memoire : tas du noyau entre la fin de l'image et 4 Mo }
  KBase := MemL[0:BootInfo + $1C];
  KSize := MemL[0:BootInfo + $20];
  MemTotalKb := MemL[0:BootInfo + $14] + 1024;
  PhysTop := MemTotalKb * 1024;
  PCount := 0;
  { tache 0 : le noyau }
  For I := 0 To MaxTasks - 1 Do TkUsed[I] := 0;
  TkUsed[0] := 1; TkProc[0] := -1; TkTid[0] := 1; TkStack[0] := 0;
  CurTask := 0; NTasks := 1; IdleStreak := 0; SliceStart := 0;
  HeapInit(KBase + KSize + 65536, ProcWinBase);
  { demarrage d'un disque dur (bloc d'amorcage +34h = 'HD') : partition
    d'amorcage (+38h) et pilote HPFS.IFS charge par OS2LDR (+40h adresse,
    +44h taille), recopie avant la pagination }
  NDisk := 0;
  HdBoot := MemW[0:BootInfo + $34] = $4448;
  BootPartLba := 0; BootIfsBuf := 0; BootIfsSize := 0;
  If HdBoot Then
  Begin
    BootPartLba := MemL[0:BootInfo + $38];
    BootIfsSize := MemL[0:BootInfo + $44];
    If BootIfsSize > 0 Then
    Begin
      BootIfsBuf := KAlloc(BootIfsSize);
      If BootIfsBuf <> 0 Then MoveMem(MemL[0:BootInfo + $40], BootIfsBuf, BootIfsSize)
      Else BootIfsSize := 0;
    End;
  End;
  Mods := Nil;
  ModCap := 0;
  InitPaging;
  InitSessions;
  VmGrabFont;
  FdInit;
  InitExports;
  RootLba := MemL[0:BootInfo + 4];
  RootSize := MemL[0:BootInfo + 8];
  For I := 0 To CacheSlots - 1 Do
  Begin
    CacheLba[I] := -1;
    CacheData[I] := 0;
  End;
  Banner;
  If PhysTop < PhysProcBase + $00400000 Then
    KLog('OS2KRNL: au moins 12 Mo de memoire sont necessaires.');
  AtaInit;
  If (Not AtaFound) And (Not HdBoot) Then
  Begin
    KLog('OS2KRNL: lecteur de CD-ROM ATAPI introuvable.');
    ExitProcess(1);
  End;
  { environnement par defaut, puis CONFIG.SYS }
  EnvSize := 1;
  EnvBlock[0] := 0;
  ShellPath := 'C:\CMD.EXE';
  EnvSet('PATH', 'C:\');
  EnvSet('PROMPT', '$i[$p]');
  EnvSet('OS2_SHELL', 'C:\CMD.EXE');
  If HdBoot Then
  Begin
    { C: : partition HPFS du disque dur, montee avant la lecture de
      CONFIG.SYS par le pilote charge en memoire par OS2LDR }
    LoadIfs('C:\HPFS.IFS /CACHE:64 /AUTOCHECK:C');
    HdInit;
    MountIfsVolumes;
    If Not IfsVols[2].Mounted Then
    Begin
      KLog('OS2KRNL: la partition d''amorcage (secteur ' + IntStr(BootPartLba) + ') ne peut pas etre montee en C:.');
      ExitProcess(1);
    End;
  End;
  ReadConfigSys;
  { COMSPEC : celui de CONFIG.SYS (SET COMSPEC=), sinon le PROTSHELL }
  If EnvFind('COMSPEC') = 0 Then EnvSet('COMSPEC', ShellPath);
  { bibliotheque DOSCALLS.DLL (API Dos* d'OS/2), si elle est presente }
  If FindLibrary('DOSCALLS.DLL') <> '' Then
  Begin
    I := LoadModule('DOSCALLS.DLL');
    If I >= 0 Then
      KLog('DOSCALLS.DLL chargee en ' + HexStr(Mods^[I].Base, 8) + 'h (' +
           IntStr(Mods^[I].NExp) + ' fonctions).');
  End;
  { systemes de fichiers installables (IFS=) et leurs volumes }
  For I := 0 To NIfsLines - 1 Do LoadIfs(IfsLines[I]);
  If NIfs > 0 Then
  Begin
    { partitions des disques durs, puis disque virtuel }
    HdInit;
    If RamDiskKb > 0 Then
      If RamDiskNew(RamDiskKb) < 0 Then
        KLog('SYS1719: disque virtuel de ' + IntStr(RamDiskKb) + ' Ko impossible.');
    MountIfsVolumes;
  End;
  PutPStr(LongInt(@KCmdLine), 'OS2KRNL', 256);
  { processeur de commandes (PROTSHELL) : relance a sa fin }
  Runs := 0;
  Repeat
    P2 := FindProgram(ShellPath);
    If P2 = '' Then
    Begin
      KLog('SYS1041: Le processeur de commandes ' + ShellPath + ' est introuvable.');
      ExitProcess(1);
    End;
    ShellCmd := '"' + P2 + '"';
    Pid := LoadProgram(P2, ShellCmd);
    If Pid < 0 Then
    Begin
      KLog('SYS1041: Impossible de charger ' + P2 + ' (erreur ' + IntStr(LastError) + ').');
      ExitProcess(1);
    End;
    Procs[Pid].HandleOpen := True;
    Procs[Pid].Parent := -1;
    If Not StartProcess(Pid) Then
    Begin
      KLog('SYS1041: Impossible de demarrer ' + P2 + '.');
      ExitProcess(1);
    End;
    While Procs[Pid].Running Do Idle;
    Code := Procs[Pid].ExitCode;
    Procs[Pid].HandleOpen := False;
    Yield;
    Inc(Runs);
    KLog('');
    KLog('Le processeur de commandes s''est termine (code ' + IntStr(Code) + ') ; relance...');
  Until False;
END.
