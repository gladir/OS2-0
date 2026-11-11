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
    Partie 7  - Memoire : tas du noyau et memoire physique
    Partie 8  - Pagination : fenetre des processus (00400000h-007FFFFFh)
    Partie 9  - Pilote ATAPI (CD-ROM IDE, mode PIO)
    Partie 10 - Systeme de fichiers ISO 9660 et disque virtuel en memoire
    Partie 11 - Table des handles, chemins et repertoire courant
    Partie 12 - Couche API (DOSCALLS) utilisee par le runtime de OS2PC
    Partie 13 - Chargeur de programmes PE et processus
    Partie 14 - Demarrage du systeme : CONFIG.SYS et CMD.EXE

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

  Les programmes s'executent en anneau 0, dans une fenetre de 4 Mo
  (00400000h-007FFFFFh) propre a chaque processus (pagination) ; un
  processus lance par CreateProcessA s'execute jusqu'a sa fin avant que
  le parent ne reprenne (comme DosExecPgm en mode synchrone). }

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
  PhysProcBase  = $00800000;   { memoire physique des processus (>= 8 Mo) }

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
  MaxFiles      = 32;
  MaxFinds      = 16;
  MaxProcs      = 8;
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
    Time     : LongInt;      { date et heure DOS }
    Owner    : LongInt;      { processus proprietaire }
    Name     : String[127];
  End;

  { Recherche FindFirst/FindNext }
  TFind = Record
    Used     : Boolean;
    Dir      : String[127];  { repertoire (chemin complet) }
    Mask     : String[12];
    IsoIdx   : LongInt;      { position dans le repertoire ISO }
    RamIdx   : LongInt;      { position dans le disque virtuel }
    Owner    : LongInt;
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
    CurDir    : String[127];
  End;

Var
  { Console }
  CurRow, CurCol   : LongInt;
  TextAttr         : LongInt;
  SerialOk         : Boolean;
  SerialMute       : Boolean;       { pas de copie serie (edition de ligne) }

  { Processeur }
  Gdt              : Array[0..7] Of LongInt;
  GdtPtr           : TDescPtr;
  Idt              : Array[0..255] Of TGate;
  IdtPtr           : TDescPtr;
  TrapFrame        : LongInt;

  { Minuterie }
  Ticks            : LongInt;

  { Clavier }
  KbdBuf           : Array[0..63] Of LongInt;   { (scan shl 8) or ascii }
  KbdHead, KbdTail : LongInt;
  KbdShift, KbdCtrl, KbdAlt, KbdCaps, KbdNum, KbdE0 : Boolean;
  History          : Array[0..15] Of String[127];
  HistCount        : LongInt;
  LineBuf          : String;
  LinePos          : LongInt;       { prochain caractere a rendre par ReadFile }
  LineReady        : Boolean;

  { Memoire }
  HeapStart, HeapEnd : LongInt;
  MemTotalKb       : LongInt;
  PhysNext         : LongInt;       { prochaine memoire physique des processus }
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
Procedure PutPStr(A : LongInt; Const S : String; Max : LongInt);
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

Procedure UpdateCursor;
Var P : LongInt;
Begin
  P := CurRow * ScrCols + CurCol;
  Port[$3D4] := $0F; Port[$3D5] := P And $FF;
  Port[$3D4] := $0E; Port[$3D5] := (P Shr 8) And $FF;
End;

Procedure ScrollUp;
Var I : LongInt;
Begin
  MoveMem(VideoBase + ScrCols * 2, VideoBase, ScrCols * (ScrRows - 1) * 2);
  For I := 0 To ScrCols - 1 Do
    MemW[0:VideoBase + ((ScrRows - 1) * ScrCols + I) * 2] := (TextAttr Shl 8) Or $20;
End;

Procedure ClearScreen;
Var I : LongInt;
Begin
  For I := 0 To ScrCols * ScrRows - 1 Do
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
  If CurRow >= ScrRows Then
  Begin
    ScrollUp;
    CurRow := ScrRows - 1;
  End;
End;

Procedure ConPutC(C : Char);
Begin
  ConPutRaw(C);
  UpdateCursor;
End;

Procedure ConPutS(Const S : String);
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do ConPutRaw(S[I]);
  UpdateCursor;
End;

Procedure ConPutLn(Const S : String);
Begin
  ConPutS(S + #13#10);
End;

{ Journal du noyau : console et port serie }
Procedure KLog(Const S : String);
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
  Gdt[6] := 0;          Gdt[7] := 0;
  GdtPtr.Limit := 3 * 8 - 1;
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

Procedure IrqTimer;
Begin
  Inc(Ticks);
  Port[$20] := $20;
End;

{ PIT canal 0 a 100 Hz }
Procedure InitTimer;
Begin
  Port[$43] := $36;
  Port[$40] := 11932 And $FF;
  Port[$40] := 11932 Shr 8;
End;

Procedure Idle;
Begin
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

Procedure KbdPush(V : LongInt);
Var N : LongInt;
Begin
  N := (KbdHead + 1) And 63;
  If N = KbdTail Then Exit;      { tampon plein }
  KbdBuf[KbdHead] := V;
  KbdHead := N;
End;

Procedure IrqKeyboard;
Var Sc, Ch, Up : LongInt;
Begin
  Sc := Port[$60];
  If Sc = $E0 Then
  Begin
    KbdE0 := True;
    Port[$20] := $20;
    Exit;
  End;
  Up := Sc And $80;
  Sc := Sc And $7F;
  Case Sc Of
    $2A, $36 : KbdShift := Up = 0;
    $1D      : KbdCtrl := Up = 0;
    $38      : KbdAlt := Up = 0;
  Else
    If Up = 0 Then
    Begin
      If Sc = $3A Then KbdCaps := Not KbdCaps
      Else If Sc = $45 Then KbdNum := Not KbdNum
      Else
      Begin
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
        End;
        KbdPush((Sc Shl 8) Or Ch);
      End;
    End;
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
Var V : LongInt;
Begin
  While KbdHead = KbdTail Do Idle;
  asm
    cli
  end;
  V := KbdBuf[KbdTail];
  KbdTail := (KbdTail + 1) And 63;
  asm
    sti
  end;
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
    While (StartRow > 0) And ((StartRow * ScrCols + StartCol + OldLen) > ScrRows * ScrCols - 1) Do
      Dec(StartRow);
    CurRow := StartRow + (StartCol + Pos) Div ScrCols;
    CurCol := (StartCol + Pos) Mod ScrCols;
    If CurRow >= ScrRows Then CurRow := ScrRows - 1;
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
    MemL[0:PageDir + I * 4] := (I Shl 22) Or $83;     { present, R/W, 4 Mo }
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
Function IsoLookup(Const Path : String; Var Lba, Size, Attr, Time : LongInt) : Boolean;
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
Function RamFind(Const Path : String) : LongInt;
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

Function RamNew(Const Path : String; Attr : LongInt) : LongInt;
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
Function ParentDir(Const Path : String) : String;
Var P : LongInt;
Begin
  P := Length(Path);
  While (P > 3) And (Path[P] <> '\') Do Dec(P);
  If P <= 3 Then ParentDir := Copy(Path, 1, 3) Else ParentDir := Copy(Path, 1, P - 1);
End;

Function BaseName(Const Path : String) : String;
Var P : LongInt;
Begin
  P := Length(Path);
  While (P > 0) And (Path[P] <> '\') Do Dec(P);
  BaseName := Copy(Path, P + 1, 255);
End;

{ Existence d'un chemin (disque virtuel puis CD-ROM) }
Function PathInfo(Const Path : String; Var Attr, Size, Time, Lba, RamIdx : LongInt) : Boolean;
Var R : LongInt;
Begin
  PathInfo := False;
  RamIdx := -1; Lba := 0;
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

Function IsDir(Const Path : String) : Boolean;
Var A, S, T, L, R : LongInt;
Begin
  IsDir := PathInfo(Path, A, S, T, L, R) And ((A And FileAttrDirectory) <> 0);
End;

{ Comparaison avec un masque DOS (* et ?) }
Function MatchMask(Const Name, Mask : String) : Boolean;
Var N, M : String; PN, PM : LongInt;

  Function Glob(Const S, P : String) : Boolean;
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
Function FullPath(Name : String) : String;
Var Base, Res, Comp : String; P : LongInt;
Begin
  Name := UpStr(Trim(Name));
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
  FullPath := Res;
End;

{ Seule l'unite C: (CD-ROM + disque virtuel) existe }
Function DriveOk(Const Path : String) : Boolean;
Begin
  DriveOk := (Length(Path) >= 3) And (Path[1] = 'C');
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
      Files[I].RamIdx := -1; Files[I].Lba := 0; Files[I].Size := 0; Files[I].Pos := 0;
      Files[I].CanWrite := False; Files[I].Time := 0;
      Files[I].Owner := CurProc;
      Files[I].Name := '';
      NewFileSlot := I;
      Exit;
    End;
End;

Procedure ConWrite(Buf, N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do ConPutRaw(Chr(Mem[0:Buf + I]));
  UpdateCursor;
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
    MemL[0:A - 8] := CurProc;              { libere a la fin du processus }
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

Function GetModuleHandleA(Name : LongInt) : LongInt;
Begin
  If CurProc >= 0 Then GetModuleHandleA := ProcWinBase Else GetModuleHandleA := $00100000;
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
Function EnvFind(Const Name : String) : LongInt;
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
Procedure EnvSet(Const AName, AValue : String);
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
  If CurRow >= ScrRows Then CurRow := ScrRows - 1;
  UpdateCursor;
  SetConsoleCursorPosition := 1;
End;

Function GetConsoleScreenBufferInfo(H, P : LongInt) : LongInt;
Begin
  MemW[0:P] := ScrCols;       MemW[0:P + 2] := ScrRows;
  MemW[0:P + 4] := CurCol;    MemW[0:P + 6] := CurRow;
  MemW[0:P + 8] := TextAttr;
  MemW[0:P + 10] := 0;        MemW[0:P + 12] := 0;
  MemW[0:P + 14] := ScrCols - 1; MemW[0:P + 16] := ScrRows - 1;
  MemW[0:P + 18] := ScrCols;  MemW[0:P + 20] := ScrRows;
  GetConsoleScreenBufferInfo := 1;
End;

Function SetConsoleScreenBufferSize(H, Size : LongInt) : LongInt;
Begin
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
  Path := FullPath(Nm);
  Files[H].Name := Path;
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
  If Exists And (Ram < 0) Then
  Begin
    { fichier du CD-ROM : lecture seule }
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
    Files[F].Used := False;
    Exit;
  End;
  If (H >= HProcBase) And (H < HProcBase + MaxProcs) Then
  Begin
    If Not Procs[H - HProcBase].Running Then Procs[H - HProcBase].Used := False;
    Exit;
  End;
  If (H = HStdIn) Or (H = HStdOut) Or (H = HStdErr) Then Exit;
  LastError := ErrInvalidHandle;
  CloseHandle := 0;
End;

Function ReadFile(H, Buf, N, PRead, Ovl : LongInt) : LongInt;
Var F, Got, A, Sect, Ofs, Chunk, Ram : LongInt; S : String;
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
    If Files[F].IsNul Then
      Got := 0
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

Function WriteFile(H, Buf, N, PWritten, Ovl : LongInt) : LongInt;
Var F, Ram : LongInt;
Begin
  WriteFile := 1;
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
    Else If Files[F].IsNul Then
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
  If Files[F].IsRam Then FileSizeOf := RamFiles[Files[F].RamIdx].Size
  Else FileSizeOf := Files[F].Size;
End;

Function SetFilePointer(H, Dist, PHigh, Method : LongInt) : LongInt;
Var F, NP : LongInt;
Begin
  F := FileSlot(H);
  If F < 0 Then
  Begin
    LastError := ErrInvalidHandle;
    SetFilePointer := -1;
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
Var F : LongInt;
Begin
  SetEndOfFile := 0;
  F := FileSlot(H);
  If (F < 0) Or Not Files[F].IsRam Then Exit;
  If Files[F].Pos < RamFiles[Files[F].RamIdx].Size Then
    RamFiles[Files[F].RamIdx].Size := Files[F].Pos;
  SetEndOfFile := 1;
End;

Function FlushFileBuffers(H : LongInt) : LongInt;
Begin
  FlushFileBuffers := 1;
End;

Function GetFileTime(H, PCreate, PAccess, PWrite : LongInt) : LongInt;
Var F, T : LongInt;
Begin
  GetFileTime := 0;
  F := FileSlot(H);
  If F < 0 Then Exit;
  T := Files[F].Time;
  If Files[F].IsRam Then T := RamFiles[Files[F].RamIdx].Time;
  If PWrite <> 0 Then DosDateTimeToFileTime(T Shr 16, T, PWrite);
  If PCreate <> 0 Then DosDateTimeToFileTime(T Shr 16, T, PCreate);
  If PAccess <> 0 Then DosDateTimeToFileTime(T Shr 16, T, PAccess);
  GetFileTime := 1;
End;

Function SetFileTime(H, PCreate, PAccess, PWrite : LongInt) : LongInt;
Var F : LongInt;
Begin
  SetFileTime := 0;
  F := FileSlot(H);
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
Var Path : String; R : LongInt;
Begin
  SetFileAttributesA := 0;
  Path := FullPath(PStr(PName));
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
  S := FullPath(PStr(PName));
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
Procedure FillFindData(P : LongInt; Const Name : String; Attr, Size, Time : LongInt);
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

Function FindFirstFileA(PName, P : LongInt) : LongInt;
Var Path, Dir, Mask : String; F, I : LongInt;
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
  Finds[F].Dir := Dir;
  Finds[F].Mask := Mask;
  Finds[F].IsoIdx := 0;
  Finds[F].RamIdx := 0;
  Finds[F].Owner := CurProc;
  If FindStep(F, P) Then
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
  If FindStep(F, P) Then FindNextFileA := 1
  Else LastError := ErrNoMoreFiles;
End;

Function FindClose(H : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := H - HFindBase;
  If (F >= 0) And (F < MaxFinds) Then Finds[F].Used := False;
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

Function KernelExport(Const Name : String) : LongInt;
Var I, O : LongInt; U : String;
Begin
  KernelExport := 0;
  U := UpStr(Name);
  For I := 0 To KExpCount - 1 Do
    If UpStr(PStr($00100000 + MemL[0:KExpNames + I * 4])) = U Then
    Begin
      O := MemW[0:KExpOrds + I * 2];
      KernelExport := $00100000 + MemL[0:KExpFuncs + O * 4];
      Exit;
    End;
End;

{ Lire tout un fichier dans un bloc du tas ; rend l'adresse ou 0 }
Function ReadWholeFile(Const Path : String; Var Size : LongInt) : LongInt;
Var Attr, Time, Lba, Ram, Buf, Done, A, N : LongInt;
Begin
  ReadWholeFile := 0;
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

Function FileExists(Const Path : String) : Boolean;
Var A, S, T, L, R : LongInt;
Begin
  FileExists := PathInfo(Path, A, S, T, L, R) And ((A And FileAttrDirectory) = 0);
End;

{ Trouver un programme : nom tel quel puis .EXE, repertoire courant,
  repertoires de PATH, racine. Le resultat est calcule dans Res et
  affecte a la fin : le resultat d'une fonction chaine est un tampon de
  l'anneau du runtime, qui serait reutilise par les appels intermediaires. }
Function FindProgram(Name : String) : String;
Var Cands : Array[0..1] Of String; NC, I, P : LongInt; Dirs, D, Path, Res : String;
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
      Cands[0] := Name + '.EXE'; Cands[1] := Name; NC := 2;
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
  FindProgram := Res;
End;

{ Charger un programme PE ; rend le numero de processus ou -1 }
Function LoadProgram(Const Path, CmdLine : String) : LongInt;
Var
  Buf, Size, Pe, Opt, NSect, OptSize, Base, ImgSize, HdrSize, Entry : LongInt;
  Total, Phys, PhysSize, Pid, I, Sec, VSize, VAddr, RawSize, RawPtr, N : LongInt;
  ImpRva, Desc, Thunks, Iat, J, V, Adr : LongInt;
  Nm : String;
Begin
  LoadProgram := -1;
  Buf := ReadWholeFile(Path, Size);
  If Buf = 0 Then Exit;
  LastError := ErrBadFormat;
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
  Phys := PhysNext;
  If Phys + PhysSize > PhysTop Then
  Begin
    LastError := ErrNotEnoughMem;
    KFree(Buf);
    Exit;
  End;
  Pid := -1;
  For I := 0 To MaxProcs - 1 Do
    If Not Procs[I].Used Then
    Begin
      Pid := I;
      Break;
    End;
  If Pid < 0 Then
    For I := 0 To MaxProcs - 1 Do
      If Not Procs[I].Running And (I <> CurProc) Then
      Begin
        Pid := I;
        Break;
      End;
  If Pid < 0 Then
  Begin
    LastError := 164;   { plus de processus }
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
          Exit;
        End;
        Nm := PStr(Phys + V + 2);
        Adr := KernelExport(Nm);
        If Adr = 0 Then
        Begin
          ConPutLn('SYS0191: ' + Nm + ' introuvable dans DOSCALLS.DLL (' + Path + ').');
          LastError := 127;
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
  Procs[Pid].CurDir := CurDir;
  ProcEntry[Pid] := ProcWinBase + Entry;
  ProcStack[Pid] := Phys + PhysSize - 16;
  PhysNext := (Phys + PhysSize + 4095) And Not 4095;
  LastError := 0;
  LoadProgram := Pid;
End;

{ Demarrer le point d'entree sur la pile du processus. ExitProcess (ou
  une exception) revient ici par KillCurrentProcess. }
Procedure RunEntry(Entry, StackTop : LongInt);
Begin
  asm
    pushad
    mov TmpEsp,esp
  end;
  Procs[CurProc].SavedEsp := TmpEsp;
  asm
    mov eax,Entry
    mov ecx,StackTop
    mov esp,ecx
    sti
    call eax
  end;
  KillCurrentProcess(0);
End;

{ Executer un processus charge jusqu'a sa fin ; rend son code de sortie }
Function RunProcess(Pid : LongInt) : LongInt;
Begin
  Procs[Pid].Running := True;
  Procs[Pid].Parent := CurProc;
  CurProc := Pid;
  MapWindow(Pid);
  RunEntry(ProcEntry[Pid], ProcStack[Pid]);
  RunProcess := Procs[Pid].ExitCode;
End;

Procedure KillCurrentProcess(Code : LongInt);
Var Pid, I : LongInt;
Begin
  Pid := CurProc;
  If Pid < 0 Then Exit;
  Procs[Pid].ExitCode := Code;
  Procs[Pid].Running := False;
  For I := 0 To MaxFiles - 1 Do
    If Files[I].Used And (Files[I].Owner = Pid) Then Files[I].Used := False;
  For I := 0 To MaxFinds - 1 Do
    If Finds[I].Used And (Finds[I].Owner = Pid) Then Finds[I].Used := False;
  KFreeOwner(Pid);
  KFree(Procs[Pid].CmdBuf);
  KFree(Procs[Pid].PtAlloc);
  PhysNext := Procs[Pid].PhysBase;
  CurProc := Procs[Pid].Parent;
  MapWindow(CurProc);
  LineReady := False;
  TmpEsp := Procs[Pid].SavedEsp;
  asm
    mov eax,TmpEsp
    mov esp,eax
    popad
    sti
    mov esp,ebp
    pop ebp
    ret
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
    MemL[0:PInfo + 4] := HProcBase + Pid;
    MemL[0:PInfo + 8] := Pid + 1;
    MemL[0:PInfo + 12] := Pid + 1;
  End;
  { execution synchrone (comme DosExecPgm EXEC_SYNC) }
  RunProcess(Pid);
  CreateProcessA := 1;
End;

Function WaitForSingleObject(H, Ms : LongInt) : LongInt;
Begin
  WaitForSingleObject := 0;
End;

Function GetExitCodeProcess(H, PCode : LongInt) : LongInt;
Begin
  GetExitCodeProcess := 0;
  If (H < HProcBase) Or (H >= HProcBase + MaxProcs) Then Exit;
  If PCode <> 0 Then MemL[0:PCode] := Procs[H - HProcBase].ExitCode;
  GetExitCodeProcess := 1;
End;

{ ==================================================================== }
{ Partie 14 - Demarrage du systeme                                     }
{ ==================================================================== }

{ CONFIG.SYS : PROTSHELL=, SET NOM=VALEUR ; les autres lignes (DEVICE=,
  LIBPATH=, IFS=...) sont acceptees sans effet }
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

Procedure Banner;
Begin
  TextAttr := $1F;
  ConPutLn(' OS/2-0 version ' + KVersion + ' - noyau 32 bits OS2KRNL (Pascal, OS2PC)               ');
  TextAttr := $07;
  ConPutLn('Memoire : ' + IntStr(MemTotalKb) + ' Ko, tas du noyau : ' +
           IntStr((HeapEnd - HeapStart) Div 1024) + ' Ko, pagination active.');
End;

Var
  KBase, KSize, Pid, Code, Runs : LongInt;
  ShellCmd, P2 : String;
  I : LongInt;

BEGIN
  TextAttr := $07;
  CurRow := Mem[0:BootInfo + $28];
  CurCol := 0;
  CurProc := -1;
  KernelDir := 'C:\';
  SerialInit;
  InitGdt;
  InitIdt;
  InitPic;
  InitTimer;
  InitKeyboard;
  asm
    sti
  end;
  { memoire : tas du noyau entre la fin de l'image et 4 Mo }
  KBase := MemL[0:BootInfo + $1C];
  KSize := MemL[0:BootInfo + $20];
  MemTotalKb := MemL[0:BootInfo + $14] + 1024;
  PhysTop := MemTotalKb * 1024;
  PhysNext := PhysProcBase;
  HeapInit(KBase + KSize + 65536, ProcWinBase);
  InitPaging;
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
  If Not AtaFound Then
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
  ReadConfigSys;
  EnvSet('COMSPEC', ShellPath);
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
    Code := RunProcess(Pid);
    Procs[Pid].Used := False;
    Inc(Runs);
    KLog('');
    KLog('Le processeur de commandes s''est termine (code ' + IntStr(Code) + ') ; relance...');
  Until False;
END.
