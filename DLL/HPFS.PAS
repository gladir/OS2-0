{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Pilote de systeme de fichiers installable OS/2 HPFS.IFS
                (High Performance File System) de OS/2-0.
}

Library HPFS;

{ Compilation : OS2PC HPFS.PAS HPFS.IFS   (produit HPFS.IFS)

  HPFS.IFS est le pilote de systeme de fichiers (FSD, "File System
  Driver") HPFS d'OS/2. Il est charge par le noyau OS2KRNL d'apres la
  ligne IFS= de CONFIG.SYS :

    IFS=C:\HPFS.IFS /CACHE:32 /AUTOCHECK:D /RAMDISK:4096

  puis le noyau lui presente chaque volume (partition de type 07h d'un
  disque dur IDE, ou disque virtuel en memoire demande par /RAMDISK:n Ko)
  par FS_MOUNT. Un volume reconnu recoit une lettre d'unite (D:, E:...) ;
  les fonctions de fichiers du noyau (CreateFileA, ReadFile,
  FindFirstFileA...) et donc DOSCALLS.DLL, CMD.EXE et tous les programmes
  passent alors par les points d'entree FS_* de ce pilote.

  Le format sur disque est le vrai format HPFS (OS/2 1.2 et suivants) :
    secteur 0       secteur d'amorce (BPB, signature "HPFS    ")
    secteur 16      superbloc (F995E849h) : racine, bitmaps, bande des
                    repertoires, table des identificateurs
    secteur 17      bloc de reserve (F9911849h) : etat, pages de codes
    bitmaps         4 secteurs par bande de 8 Mo (1 = secteur libre)
    fnode           un secteur par fichier ou repertoire (F7E40AAEh) :
                    nom, taille, arbre B+ des extensions, attributs
                    etendus (EA) residents
    anode           noeud d'arbre B+ d'allocation (37E40AAEh)
    dnode           bloc de repertoire de 4 secteurs (77E40AAEh) : arbre B
                    d'entrees (dirent) triees par nom, sans tenir compte
                    de la casse (table de majuscules de la page de codes
                    850, enregistree sur le volume)
  Les noms longs (254 caracteres), la casse, les dates (creation, acces,
  ecriture : secondes depuis 1970) et les attributs etendus sont geres.

  Interface (adaptee a OS/2-0 : toutes les valeurs sont de 32 bits, les
  pointeurs sont des adresses lineaires ; convention _System) :

  Structures fournies par le noyau
    VPFSI  (volume, 44 octets)
      +0 vpi_vid (numero de serie)  +4 vpi_hDEV  +8 vpi_bsize (512)
      +12 vpi_totsec  +16 vpi_trksec  +20 vpi_nhead
      +24 vpi_text[12] (nom de volume)  +36 vpi_drive (0 = A:)  +40 vpi_unit
    VPFSD  (zone du pilote dans le VPB, 64 octets)
    CDFSI  (repertoire courant, 272 octets)
      +0 cdi_hVPB  +4 cdi_end  +8 cdi_flags  +12 cdi_curdir[260]
    CDFSD  (zone du pilote, 16 octets)
    SFFSI  (fichier ouvert, 64 octets)
      +0 sfi_mode  +4 sfi_hVPB  +8 sfi_ctime  +12 sfi_atime  +16 sfi_mtime
      (dates et heures DOS : date shl 16 or heure)  +20 sfi_size
      +24 sfi_position  +28 sfi_UID  +32 sfi_PID  +36 sfi_PDB
      +40 sfi_selfsfn  +44 sfi_tstamp  +48 sfi_type  +52 sfi_DOSattr
    SFFSD  (zone du pilote, 32 octets)
    FSFSI  (recherche, 8 octets) : +0 fsi_hVPB
    FSFSD  (zone du pilote, 32 octets)
  Le hVPB d'un volume est le numero de son unite (3 = D:).

  Services du noyau utilises (exportations du noyau, stdcall)
    FSH_DOVOLIO(Op, fAllowed, hVPB, pData, pcSec, iSec)
      lecture (Op = 0) ou ecriture (Op = 1) de secteurs du volume
    GetLocalTime, GetProcessHeap, HeapAlloc, HeapFree

  Points d'entree (43, exportes par nom) :
    FS_ALLOCATEPAGESPACE FS_ATTACH FS_ATTRIBUTE (donnee) FS_CANCELLOCKREQUEST
    FS_CHDIR FS_CHGFILEPTR FS_CLOSE FS_COMMIT FS_COPY FS_DELETE
    FS_DOPAGEIO FS_EXIT FS_FILEATTRIBUTE FS_FILEINFO FS_FILEIO
    FS_FILELOCKS FS_FINDCLOSE FS_FINDFIRST FS_FINDFROMNAME FS_FINDNEXT
    FS_FINDNOTIFYCLOSE FS_FINDNOTIFYFIRST FS_FINDNOTIFYNEXT FS_FLUSHBUF
    FS_FSCTL FS_FSINFO FS_INIT FS_IOCTL FS_MKDIR FS_MOUNT FS_MOVE
    FS_NAME (donnee) FS_NEWSIZE FS_NMPIPE FS_OPENCREATE FS_OPENPAGEFILE
    FS_PATHINFO FS_PROCESSNAME FS_READ FS_RMDIR FS_SETSWAP FS_SHUTDOWN
    FS_WRITE
  Le detail des parametres de chacun est donne avec sa fonction
  (partie 13). Fonctions privees de FS_FSCTL : 8000h formater un volume,
  8001h verifier un volume (comme CHKDSK), 8002h statistiques.

  Organisation :
    Partie 1  - Constantes, types et variables
    Partie 2  - Services du noyau
    Partie 3  - Utilitaires (memoire, chaines, dates, noms)
    Partie 4  - Volumes et antememoire des secteurs
    Partie 5  - Bitmaps et allocation
    Partie 6  - Fnodes, anodes et extensions des fichiers
    Partie 7  - Attributs etendus (EA)
    Partie 8  - Repertoires : arbre B des dnodes
    Partie 9  - Chemins
    Partie 10 - Formatage, montage et verification
    Partie 11 - Objets fichiers, verrous et notifications
    Partie 12 - Lecture et ecriture des donnees
    Partie 13 - Points d'entree FS_*
    Exportations et initialisation }

{$R-,S-,I-}
{$IMAGEBASE $00E00000}

{ ==================================================================== }
{ Partie 1 - Constantes, types et variables                            }
{ ==================================================================== }

Const
  { donnees exportees : nom du systeme de fichiers et attributs du pilote
    (FSA_REMOTE 1, FSA_UNC 2, FSA_LOCK 4, FSA_LVL7 8, FSA_PSVR 16,
    FSA_LARGEFILE 32 : HPFS est local, sans verrou de serveur) }
  FS_NAME      = 'HPFS';
  FS_ATTRIBUTE = 8;

  NO_ERROR                = 0;
  ERROR_INVALID_FUNCTION  = 1;
  ERROR_FILE_NOT_FOUND    = 2;
  ERROR_PATH_NOT_FOUND    = 3;
  ERROR_TOO_MANY_OPEN_FILES = 4;
  ERROR_ACCESS_DENIED     = 5;
  ERROR_INVALID_HANDLE    = 6;
  ERROR_NOT_ENOUGH_MEMORY = 8;
  ERROR_INVALID_ACCESS    = 12;
  ERROR_INVALID_DATA      = 13;
  ERROR_INVALID_DRIVE     = 15;
  ERROR_CURRENT_DIRECTORY = 16;
  ERROR_NOT_SAME_DEVICE   = 17;
  ERROR_NO_MORE_FILES     = 18;
  ERROR_WRITE_PROTECT     = 19;
  ERROR_NOT_READY         = 21;
  ERROR_NOT_DOS_DISK      = 26;
  ERROR_SECTOR_NOT_FOUND  = 27;
  ERROR_WRITE_FAULT       = 29;
  ERROR_READ_FAULT        = 30;
  ERROR_SHARING_VIOLATION = 32;
  ERROR_LOCK_VIOLATION    = 33;
  ERROR_NOT_SUPPORTED     = 50;
  ERROR_FILE_EXISTS       = 80;
  ERROR_CANNOT_MAKE       = 82;
  ERROR_INVALID_PARAMETER = 87;
  ERROR_BUFFER_OVERFLOW   = 111;
  ERROR_DISK_FULL         = 112;
  ERROR_INVALID_CATEGORY  = 117;
  ERROR_INVALID_NAME      = 123;
  ERROR_INVALID_LEVEL     = 124;
  ERROR_NEGATIVE_SEEK     = 131;
  ERROR_DIR_NOT_EMPTY     = 145;
  ERROR_PATH_BUSY         = 148;
  ERROR_FILENAME_EXCED_RANGE = 206;
  ERROR_INVALID_EA_NAME   = 254;
  ERROR_EA_LIST_INCONSISTENT = 255;
  ERROR_CANNOT_COPY       = 266;
  ERROR_DIRECTORY         = 267;
  ERROR_EAS_DIDNT_FIT     = 275;
  ERROR_TIMEOUT           = 640;

  { attributs DOS }
  ATTR_READONLY  = $01;
  ATTR_HIDDEN    = $02;
  ATTR_SYSTEM    = $04;
  ATTR_LABEL     = $08;
  ATTR_DIRECTORY = $10;
  ATTR_ARCHIVE   = $20;
  ATTR_NOT8X3    = $40;     { indicateur HPFS : nom hors 8.3 }

  { FSH_DOVOLIO }
  DVIO_OPREAD    = 0;
  DVIO_OPWRITE   = 1;

  { signatures du format HPFS }
  SB_MAGIC     = $F995E849;
  SB_MAGIC1    = $FA53E9C5;
  SP_MAGIC     = $F9911849;
  SP_MAGIC1    = $FA5229C5;
  FNODE_MAGIC  = $F7E40AAE;
  ANODE_MAGIC  = $37E40AAE;
  DNODE_MAGIC  = $77E40AAE;
  CPDIR_MAGIC  = $494521F7;
  CPDATA_MAGIC = $894521F7;

  SECT         = 512;
  BAND_SECS    = 16384;     { 8 Mo par bande, 4 secteurs de bitmap }
  DNODE_SIZE   = 2048;
  DN_HDR       = 20;        { en-tete d'un dnode }

  { dirent }
  DE_LEN    = 0;  DE_FLAGS  = 2;  DE_ATTR  = 3;  DE_FNODE = 4;
  DE_WDATE  = 8;  DE_SIZE   = 12; DE_RDATE = 16; DE_CDATE = 20;
  DE_EASIZE = 24; DE_ACLS   = 28; DE_CPIX  = 29; DE_NLEN  = 30;
  DE_NAME   = 31;
  DF_FIRST  = $01;          { entree ^A^A (repertoire lui-meme) }
  DF_DOWN   = $04;          { pointeur vers un dnode fils (4 derniers octets) }
  DF_LAST   = $08;          { entree finale (nom FFh) }
  DF_HASEA  = $10;
  DF_NEEDEA = $80;

  { fnode }
  FN_LEN    = 12;  FN_NAME = 13;  FN_UP = 28;
  FN_EASIZEL = 44; FN_EASEC = 48; FN_EASIZES = 52; FN_FLAGS = 54;
  FN_BTREE  = 56;  FN_FSIZE = 160; FN_NEEDEA = 164; FN_EAOFS = 184;
  FN_EAAREA = 196;          { zone des EA residents : 196..511 }
  FN_EAMAX  = 316;
  FNF_DIR   = $0100;
  FNF_EAANODE = $0002;

  { en-tete d'arbre B+ (fnode +56, anode +12) }
  BP_INTERNAL = $80;
  BP_FNPARENT = $20;

  MaxVol   = 8;
  MaxBands = 256;           { volumes jusqu'a 2 Go }
  CacheMax = 64;            { antememoire : 64 secteurs au plus }
  MaxExt   = 480;           { 12 anodes de 40 extensions }
  MaxObj   = 32;            { fichiers ouverts (objets) }
  MaxOpen  = 64;            { ouvertures (SFT) }
  MaxFind  = 32;
  MaxLock  = 64;
  MaxNote  = 8;
  MaxLog   = 64;
  EaBufMax = 16384;         { taille maximale d'une liste d'EA }

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

  TVol = Record
    Used     : Boolean;
    Mounted  : Boolean;     { HPFS reconnu (sinon : accepte pour formatage) }
    HVpb     : LongInt;
    TotSec   : LongInt;
    Root     : LongInt;     { fnode de la racine }
    NBands   : LongInt;
    DirStart : LongInt;     { bande des repertoires }
    DirEnd   : LongInt;
    DirBmp   : LongInt;
    FreeSecs : LongInt;
    Serial   : LongInt;
    Dirty    : Boolean;
    WasDirty : Boolean;     { volume mal ferme au montage (bloc de reserve) }
    PVpfsi   : LongInt;
    Drive    : LongInt;
  End;

  { fichier ouvert, partage par les ouvertures d'un meme fnode }
  TObj = Record
    Used     : Boolean;
    Vol      : LongInt;
    Fnode    : LongInt;
    Dir      : LongInt;     { fnode du repertoire parent }
    Name     : String;      { nom exact (casse conservee) }
    Size     : LongInt;
    Attr     : LongInt;
    CTime, ATime, MTime : LongInt;   { secondes depuis 1970 }
    Refs     : LongInt;
    Dirty    : Boolean;
    Swap     : Boolean;
  End;

  TOpen = Record
    Used     : Boolean;
    Obj      : LongInt;
    Mode     : LongInt;
    Sffsi    : LongInt;
    Pid      : LongInt;
  End;

  TFind = Record
    Used     : Boolean;
    Vol      : LongInt;
    Dir      : LongInt;
    Parent   : LongInt;
    Mask     : String;
    Attr     : LongInt;
    Last     : String;      { dernier nom rendu ('' = debut) }
    Dots     : LongInt;     { 0 : rendre ".", 1 : "..", 2 : fini }
    Pid      : LongInt;
    FPos      : LongInt;
  End;

  TLock = Record
    Used     : Boolean;
    Obj      : LongInt;
    Owner    : LongInt;     { adresse du SFFSI de l'ouverture }
    Pid      : LongInt;
    Ofs, Len : LongInt;
    Shared   : Boolean;
  End;

  TNote = Record
    Used     : Boolean;
    Vol      : LongInt;
    Dir      : LongInt;
    Mask     : String;
    Attr     : LongInt;
    Seen     : LongInt;     { position dans le journal }
    Pid      : LongInt;
  End;

  TLogRec = Record
    Vol      : LongInt;
    Dir      : LongInt;
    Action   : LongInt;     { 1 cree, 2 supprime, 3 modifie }
    Name     : String;
  End;

Var
  Vols      : Array[0..MaxVol - 1] Of TVol;
  BandTab   : Array[0..MaxVol * MaxBands - 1] Of LongInt;   { secteur de bitmap de chaque bande }
  Objs      : Array[0..MaxObj - 1] Of TObj;
  Opens     : Array[0..MaxOpen - 1] Of TOpen;
  Finds     : Array[0..MaxFind - 1] Of TFind;
  Locks     : Array[0..MaxLock - 1] Of TLock;
  Notes     : Array[0..MaxNote - 1] Of TNote;
  ChgLog    : Array[0..MaxLog - 1] Of TLogRec;
  LogCount  : LongInt;

  { antememoire des secteurs de structure (ecriture immediate) }
  CacheN    : LongInt;
  CacheVol  : Array[0..CacheMax - 1] Of LongInt;
  CacheSec  : Array[0..CacheMax - 1] Of LongInt;
  CacheAge  : Array[0..CacheMax - 1] Of LongInt;
  CacheData : Array[0..CacheMax * 512 - 1] Of Byte;
  CacheTick : LongInt;
  CacheHits, CacheMiss : LongInt;

  { bitmap de bande courante et bitmap de la bande des repertoires }
  BmpBuf    : Array[0..2047] Of Byte;
  BmpVol, BmpBand : LongInt;
  DbBuf     : Array[0..2047] Of Byte;
  DbVol     : LongInt;

  { extensions du fichier courant }
  ExtF, ExtL, ExtD : Array[0..MaxExt - 1] Of LongInt;
  ExtN      : LongInt;
  ExtVol, ExtFnode : LongInt;          { proprietaire des extensions chargees }
  AnList    : Array[0..63] Of LongInt; { anodes de l'arbre charge }
  AnN       : LongInt;
  AnBuf     : Array[0..3] Of Array[0..511] Of Byte;

  { tampons de travail }
  SecBuf    : Array[0..511] Of Byte;
  SpareBuf  : Array[0..511] Of Byte;   { bloc de reserve (etat du volume) }
  ZeroBuf   : Array[0..511] Of Byte;
  FnBuf     : Array[0..511] Of Byte;
  FnBuf2    : Array[0..511] Of Byte;
  DnBuf     : Array[0..9] Of Array[0..2047] Of Byte;
  TmpBuf    : Array[0..4095] Of Byte;
  EntBuf    : Array[0..9] Of Array[0..319] Of Byte;
  DeOut     : Array[0..319] Of Byte;   { entree trouvee (copie) }
  DeOut2    : Array[0..319] Of Byte;
  NewDe     : Array[0..319] Of Byte;
  KeyBuf    : Array[0..259] Of Byte;   { nom cherche }
  KeyLen    : LongInt;
  EaBuf     : Array[0..EaBufMax + 511] Of Byte;  { liste d'EA au format HPFS }
  EaLen     : LongInt;
  EaBuf2    : Array[0..EaBufMax + 511] Of Byte;
  BigBuf    : Array[0..4095] Of Byte;  { copie de fichiers }
  PathBuf   : Array[0..519] Of Byte;
  TimeBuf   : Array[0..7] Of Word;

  { analyse d'un chemin }
  PComp     : Array[0..31] Of String;
  NComp     : LongInt;
  WDir      : LongInt;                 { repertoire parent du dernier composant }
  WFound    : Boolean;                 { dernier composant trouve (dans DeOut) }
  WIsRoot   : Boolean;

  Upper     : Array[0..255] Of Byte;   { majuscules (page de codes 850) }
  InitDone  : Boolean;
  OptCache  : LongInt;
  OptAuto   : String;
  ChkErrors : LongInt;
  ChkMap    : LongInt;                 { carte d'occupation construite par la verification }
  ChkDirs, ChkFiles, ChkUsed, ChkDnCount, ChkEa : LongInt;
  ShutDown  : Boolean;
  LastErr   : LongInt;
  ProcName  : String;

{ ==================================================================== }
{ Partie 2 - Services du noyau                                         }
{ ==================================================================== }
{ Les fonctions de la couche de base du noyau sont stdcall ; FSH_DOVOLIO
  est le service d'entree/sortie de volume offert aux pilotes IFS. }

Function FSH_DoVolIO(Op, Allowed, HVpb, PData, PcSec, ISec : LongInt) : LongInt; External 'DOSCALLS' Name 'FSH_DOVOLIO';
Function KGetLocalTime(P : LongInt) : LongInt; External 'DOSCALLS' Name 'GetLocalTime';
Function KGetProcessHeap : LongInt; External 'DOSCALLS' Name 'GetProcessHeap';
Function KHeapAlloc(H, Flags, Size : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapAlloc';
Function KHeapFree(H, Flags, P : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapFree';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';

{ ==================================================================== }
{ Partie 3 - Utilitaires                                               }
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

Function StrLenA(A : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  If A <> 0 Then
    While RdB(A + N) <> 0 Do Inc(N);
  StrLenA := N;
End;

{ Chaine ASCIIZ -> chaine Pascal (255 caracteres au plus) }
Function GetStr(A : LongInt) : String;
Var S : String; N, C : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    C := RdB(A);
    While (C <> 0) And (N < 255) Do
    Begin
      S := S + Chr(C);
      Inc(N);
      C := RdB(A + N);
    End;
  End;
  GetStr := S;
End;

{ Chaine Pascal -> ASCIIZ en A (Max octets au plus, zero compris) }
Procedure PutStr(A : LongInt; S : String; Max : LongInt);
Var I, L : LongInt;
Begin
  If (A = 0) Or (Max <= 0) Then Exit;
  L := Length(S);
  If L > Max - 1 Then L := Max - 1;
  For I := 1 To L Do WrB(A + I - 1, Ord(S[I]));
  WrB(A + L, 0);
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function Min(A, B : LongInt) : LongInt;
Begin
  If A < B Then Min := A Else Min := B;
End;

{ Table des majuscules : ASCII et page de codes 850 }
Procedure InitUpper;
Var I : LongInt;
Begin
  For I := 0 To 255 Do Upper[I] := I;
  For I := 97 To 122 Do Upper[I] := I - 32;
  Upper[129] := 154; Upper[130] := 144; Upper[131] := 182; Upper[132] := 142;
  Upper[133] := 183; Upper[134] := 143; Upper[135] := 128; Upper[136] := 210;
  Upper[137] := 211; Upper[138] := 212; Upper[139] := 216; Upper[140] := 215;
  Upper[141] := 222; Upper[145] := 146; Upper[147] := 226; Upper[148] := 153;
  Upper[149] := 227; Upper[150] := 234; Upper[151] := 235; Upper[155] := 157;
  Upper[160] := 181; Upper[161] := 214; Upper[162] := 224; Upper[163] := 233;
  Upper[164] := 165; Upper[198] := 199; Upper[208] := 209; Upper[213] := 73;
  Upper[228] := 229; Upper[231] := 232; Upper[236] := 237;
End;

Function UpStr(S : String) : String;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do S[I] := Chr(Upper[Ord(S[I])]);
  UpStr := S;
End;

{ Comparaison de noms en memoire, sans tenir compte de la casse :
  -1, 0 ou 1 }
Function CmpMem(A1, L1, A2, L2 : LongInt) : LongInt;
Var I, N, C1, C2, R : LongInt;
Begin
  R := 0;
  N := L1;
  If L2 < N Then N := L2;
  I := 0;
  While (I < N) And (R = 0) Do
  Begin
    C1 := Upper[RdB(A1 + I)];
    C2 := Upper[RdB(A2 + I)];
    If C1 < C2 Then R := -1
    Else If C1 > C2 Then R := 1;
    Inc(I);
  End;
  If R = 0 Then
  Begin
    If L1 < L2 Then R := -1
    Else If L1 > L2 Then R := 1;
  End;
  CmpMem := R;
End;

{ Placer un nom Pascal dans KeyBuf }
Procedure SetKey(S : String);
Var I : LongInt;
Begin
  KeyLen := Length(S);
  For I := 1 To KeyLen Do KeyBuf[I - 1] := Ord(S[I]);
End;

{ --- dates : secondes depuis le 1er janvier 1970 (heure locale) --- }

Function DaysFrom(Y, M, D : LongInt) : LongInt;
Var A, Era, Yoe, Doy, Doe : LongInt;
Begin
  { algorithme "days from civil" (calendrier gregorien) }
  If M <= 2 Then Y := Y - 1;
  Era := Y Div 400;
  Yoe := Y - Era * 400;
  If M > 2 Then A := M - 3 Else A := M + 9;
  Doy := (153 * A + 2) Div 5 + D - 1;
  Doe := Yoe * 365 + Yoe Div 4 - Yoe Div 100 + Doy;
  DaysFrom := Era * 146097 + Doe - 719468;
End;

{ Secondes depuis 1970 -> date et heure DOS (date shl 16 or heure) }
Function UnixToDos(T : LongInt) : LongInt;
Var Days, Secs, Z, Era, Doe, Yoe, Y, Doy, Mp, D, M : LongInt;
Begin
  If T < 315532800 Then T := 315532800;     { 1er janvier 1980 }
  Days := T Div 86400;
  Secs := T Mod 86400;
  Z := Days + 719468;
  Era := Z Div 146097;
  Doe := Z - Era * 146097;
  Yoe := (Doe - Doe Div 1460 + Doe Div 36524 - Doe Div 146096) Div 365;
  Y := Yoe + Era * 400;
  Doy := Doe - (365 * Yoe + Yoe Div 4 - Yoe Div 100);
  Mp := (5 * Doy + 2) Div 153;
  D := Doy - (153 * Mp + 2) Div 5 + 1;
  If Mp < 10 Then M := Mp + 3 Else M := Mp - 9;
  If M <= 2 Then Inc(Y);
  If Y > 2107 Then Y := 2107;
  UnixToDos := ((((Y - 1980) Shl 9) Or (M Shl 5) Or D) Shl 16) Or
               (((Secs Div 3600) Shl 11) Or (((Secs Div 60) Mod 60) Shl 5) Or ((Secs Mod 60) Div 2));
End;

Function DosToUnix(T : LongInt) : LongInt;
Var Dt, Tm, Y, M, D : LongInt;
Begin
  Dt := (T Shr 16) And $FFFF;
  Tm := T And $FFFF;
  Y := 1980 + (Dt Shr 9);
  M := (Dt Shr 5) And 15;
  D := Dt And 31;
  If (M < 1) Or (M > 12) Then M := 1;
  If D < 1 Then D := 1;
  DosToUnix := DaysFrom(Y, M, D) * 86400 + (Tm Shr 11) * 3600 + ((Tm Shr 5) And 63) * 60 +
               (Tm And 31) * 2;
End;

Function NowUnix : LongInt;
Begin
  KGetLocalTime(LongInt(@TimeBuf));
  NowUnix := DaysFrom(TimeBuf[0], TimeBuf[1], TimeBuf[3]) * 86400 +
             TimeBuf[4] * 3600 + TimeBuf[5] * 60 + TimeBuf[6];
End;

{ --- noms de fichiers --- }

{ Nom valide pour HPFS : 1 a 254 caracteres, sans < > | " / \ : * ? ni
  caractere de controle ; rend un code d'erreur }
Function CheckName(S : String) : LongInt;
Var I, C, R : LongInt;
Begin
  R := NO_ERROR;
  If (Length(S) = 0) Or (S = '.') Or (S = '..') Then R := ERROR_INVALID_NAME
  Else If Length(S) > 254 Then R := ERROR_FILENAME_EXCED_RANGE
  Else
    For I := 1 To Length(S) Do
    Begin
      C := Ord(S[I]);
      If (C < 32) Or (C = 34) Or (C = 42) Or (C = 47) Or (C = 58) Or (C = 60) Or
         (C = 62) Or (C = 63) Or (C = 92) Or (C = 124) Then R := ERROR_INVALID_NAME;
    End;
  CheckName := R;
End;

{ Le nom respecte-t-il la forme 8.3 de FAT ? }
Function Is8x3(S : String) : Boolean;
Var I, P, C : LongInt; R : Boolean;
Begin
  R := True;
  P := 0;
  For I := 1 To Length(S) Do
  Begin
    C := Ord(S[I]);
    If S[I] = '.' Then
    Begin
      If P > 0 Then R := False;
      P := I;
    End
    Else If (C = 32) Or (C = 43) Or (C = 44) Or (C = 59) Or (C = 61) Or (C = 91) Or (C = 93) Then
      R := False;
  End;
  If P = 0 Then
  Begin
    If Length(S) > 8 Then R := False;
  End
  Else
  Begin
    If (P = 1) Or (P > 9) Or (Length(S) - P > 3) Or (P = Length(S)) Then R := False;
  End;
  Is8x3 := R;
End;

{ Comparaison avec un masque * et ? (sans tenir compte de la casse) ;
  "NOM.*" accepte aussi "NOM", "*.*" accepte tout }
Function Glob(S, P : String) : Boolean;
Var I, J, StarI, StarJ : LongInt; R, Done : Boolean;
Begin
  I := 1; J := 1; StarI := 0; StarJ := 0;
  R := True; Done := False;
  While (I <= Length(S)) And Not Done Do
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
      R := False;
      Done := True;
    End;
  End;
  If R Then
  Begin
    While (J <= Length(P)) And (P[J] = '*') Do Inc(J);
    R := J > Length(P);
  End;
  Glob := R;
End;

Function MatchMask(Name, Mask : String) : Boolean;
Var N, M : String; R : Boolean;
Begin
  N := UpStr(Name); M := UpStr(Mask);
  If (M = '*.*') Or (M = '*') Or (M = '') Then R := True
  Else
  Begin
    R := Glob(N, M);
    If (Not R) And (Length(M) > 2) And (Copy(M, Length(M) - 1, 2) = '.*') And (Pos('.', N) = 0) Then
      R := Glob(N, Copy(M, 1, Length(M) - 2));
  End;
  MatchMask := R;
End;

Function HasWild(S : String) : Boolean;
Begin
  HasWild := (Pos('*', S) > 0) Or (Pos('?', S) > 0);
End;

{ ==================================================================== }
{ Partie 4 - Volumes et antememoire des secteurs                       }
{ ==================================================================== }
{ Les secteurs de structure (fnodes, anodes, dnodes, superbloc...) passent
  par une petite antememoire a ecriture immediate (/CACHE:n Ko, 32 Ko au
  plus). Les donnees des fichiers et les bitmaps sont lus et ecrits
  directement ; une ecriture directe invalide les copies en antememoire. }

Function FindVol(HVpb : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxVol - 1 Do
    If Vols[I].Used And (Vols[I].HVpb = HVpb) Then R := I;
  FindVol := R;
End;

{ Volume HPFS monte (sinon -1) }
Function MVol(HVpb : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := FindVol(HVpb);
  If V >= 0 Then
    If Not Vols[V].Mounted Then V := -1;
  MVol := V;
End;

{ Entree/sortie physique par le noyau }
Function DevIO(V, Op, Sec, N, Addr : LongInt) : LongInt;
Var Cnt, R : LongInt;
Begin
  If (Sec < 0) Or (N <= 0) Or (Sec + N > Vols[V].TotSec) Then
    R := ERROR_SECTOR_NOT_FOUND
  Else
  Begin
    Cnt := N;
    R := FSH_DoVolIO(Op, 0, Vols[V].HVpb, Addr, LongInt(@Cnt), Sec);
    If (R = NO_ERROR) And (Cnt <> N) Then
    Begin
      If Op = DVIO_OPWRITE Then R := ERROR_WRITE_FAULT Else R := ERROR_READ_FAULT;
    End;
  End;
  DevIO := R;
End;

Procedure CacheInvalidate(V, Sec, N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To CacheN - 1 Do
    If (CacheVol[I] = V) And (CacheSec[I] >= Sec) And (CacheSec[I] < Sec + N) Then
      CacheVol[I] := -1;
End;

Procedure CacheDropVol(V : LongInt);
Var I : LongInt;
Begin
  For I := 0 To CacheMax - 1 Do
    If CacheVol[I] = V Then CacheVol[I] := -1;
  If BmpVol = V Then BmpVol := -1;
  If DbVol = V Then DbVol := -1;
  If ExtVol = V Then ExtVol := -1;
End;

Function CacheFind(V, Sec : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  I := 0;
  While (I < CacheN) And (R < 0) Do
  Begin
    If (CacheVol[I] = V) And (CacheSec[I] = Sec) Then R := I;
    Inc(I);
  End;
  CacheFind := R;
End;

Function CacheVictim : LongInt;
Var I, R, Best : LongInt;
Begin
  R := 0; Best := 2147483647;
  For I := 0 To CacheN - 1 Do
  Begin
    If CacheVol[I] < 0 Then
    Begin
      If Best > -1 Then
      Begin
        R := I;
        Best := -1;
      End;
    End
    Else If (Best >= 0) And (CacheAge[I] < Best) Then
    Begin
      R := I;
      Best := CacheAge[I];
    End;
  End;
  CacheVictim := R;
End;

{ Lire N secteurs de structure }
Function ReadSecs(V, Sec, N, Addr : LongInt) : LongInt;
Var I, C, R : LongInt;
Begin
  R := NO_ERROR;
  If CacheN = 0 Then R := DevIO(V, DVIO_OPREAD, Sec, N, Addr)
  Else
    For I := 0 To N - 1 Do
      If R = NO_ERROR Then
      Begin
        C := CacheFind(V, Sec + I);
        If C < 0 Then
        Begin
          Inc(CacheMiss);
          C := CacheVictim;
          CacheVol[C] := -1;
          R := DevIO(V, DVIO_OPREAD, Sec + I, 1, LongInt(@CacheData[C * 512]));
          If R = NO_ERROR Then
          Begin
            CacheVol[C] := V;
            CacheSec[C] := Sec + I;
          End;
        End
        Else
          Inc(CacheHits);
        If R = NO_ERROR Then
        Begin
          Inc(CacheTick);
          CacheAge[C] := CacheTick;
          MoveB(LongInt(@CacheData[C * 512]), Addr + I * 512, 512);
        End;
      End;
  ReadSecs := R;
End;

Procedure MarkDirty(V : LongInt); Forward;

{ Ecrire N secteurs de structure (sur le volume et dans l'antememoire) }
Function WriteSecs(V, Sec, N, Addr : LongInt) : LongInt;
Var I, C, R : LongInt;
Begin
  MarkDirty(V);
  R := DevIO(V, DVIO_OPWRITE, Sec, N, Addr);
  If R = NO_ERROR Then
    For I := 0 To N - 1 Do
    Begin
      C := CacheFind(V, Sec + I);
      If (C < 0) And (CacheN > 0) And (N <= 4) Then
      Begin
        C := CacheVictim;
        CacheVol[C] := V;
        CacheSec[C] := Sec + I;
      End;
      If C >= 0 Then
      Begin
        Inc(CacheTick);
        CacheAge[C] := CacheTick;
        MoveB(Addr + I * 512, LongInt(@CacheData[C * 512]), 512);
      End;
    End
  Else
    CacheInvalidate(V, Sec, N);
  WriteSecs := R;
End;

{ Donnees des fichiers : pas d'antememoire }
Function DataRead(V, Sec, N, Addr : LongInt) : LongInt;
Begin
  DataRead := DevIO(V, DVIO_OPREAD, Sec, N, Addr);
End;

Function DataWrite(V, Sec, N, Addr : LongInt) : LongInt;
Begin
  MarkDirty(V);
  CacheInvalidate(V, Sec, N);
  DataWrite := DevIO(V, DVIO_OPWRITE, Sec, N, Addr);
End;

{ Etat du volume dans le bloc de reserve (secteur 17) : bit 0 = volume
  modifie et non ferme proprement }
Function SetSpareDirty(V : LongInt; Dirty : Boolean) : LongInt;
Var R, F : LongInt;
Begin
  R := DevIO(V, DVIO_OPREAD, 17, 1, LongInt(@SpareBuf));
  If R = NO_ERROR Then
  Begin
    F := SpareBuf[8];
    If Dirty Then F := F Or 1 Else F := F And $FE;
    If F <> SpareBuf[8] Then
    Begin
      SpareBuf[8] := F;
      CacheInvalidate(V, 17, 1);
      R := DevIO(V, DVIO_OPWRITE, 17, 1, LongInt(@SpareBuf));
    End;
  End;
  SetSpareDirty := R;
End;

Procedure MarkDirty(V : LongInt);
Begin
  If (V >= 0) And Vols[V].Mounted And Not Vols[V].Dirty Then
  Begin
    Vols[V].Dirty := True;
    SetSpareDirty(V, True);
  End;
End;

Function FlushVol(V : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If Vols[V].Mounted And Vols[V].Dirty Then
  Begin
    R := SetSpareDirty(V, False);
    If R = NO_ERROR Then Vols[V].Dirty := False;
  End;
  FlushVol := R;
End;

{ ==================================================================== }
{ Partie 5 - Bitmaps et allocation                                     }
{ ==================================================================== }
{ Chaque bande de 16384 secteurs a une bitmap de 4 secteurs (2048 octets,
  bit a 1 = secteur libre). La bitmap de la bande courante est gardee
  dans BmpBuf et reecrite a chaque modification. La bande des
  repertoires a sa propre bitmap (un bit par dnode de 4 secteurs). }

Function LoadBand(V, B : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If (BmpVol <> V) Or (BmpBand <> B) Then
  Begin
    BmpVol := -1;
    R := DevIO(V, DVIO_OPREAD, BandTab[V * MaxBands + B], 4, LongInt(@BmpBuf));
    If R = NO_ERROR Then
    Begin
      BmpVol := V;
      BmpBand := B;
    End;
  End;
  LoadBand := R;
End;

Function SaveBand : LongInt;
Begin
  MarkDirty(BmpVol);
  SaveBand := DevIO(BmpVol, DVIO_OPWRITE, BandTab[BmpVol * MaxBands + BmpBand], 4, LongInt(@BmpBuf));
End;

Function SecFree(V, S : LongInt) : Boolean;
Var B : LongInt;
Begin
  SecFree := False;
  If (S < 0) Or (S >= Vols[V].TotSec) Then Exit;
  If LoadBand(V, S Div BAND_SECS) <> NO_ERROR Then Exit;
  B := S Mod BAND_SECS;
  SecFree := (BmpBuf[B Shr 3] And (1 Shl (B And 7))) <> 0;
End;

{ Marquer N secteurs libres (Free) ou occupes }
Function MarkSecs(V, S, N : LongInt; Free : Boolean) : LongInt;
Var I, B, Band, R, M : LongInt; Changed : Boolean;
Begin
  R := NO_ERROR;
  Changed := False;
  Band := -1;
  I := 0;
  While (I < N) And (R = NO_ERROR) Do
  Begin
    If (S + I) Div BAND_SECS <> Band Then
    Begin
      If Changed Then R := SaveBand;
      Changed := False;
      Band := (S + I) Div BAND_SECS;
      If R = NO_ERROR Then R := LoadBand(V, Band);
    End;
    If R = NO_ERROR Then
    Begin
      B := (S + I) Mod BAND_SECS;
      M := 1 Shl (B And 7);
      If Free Then
      Begin
        If (BmpBuf[B Shr 3] And M) = 0 Then
        Begin
          BmpBuf[B Shr 3] := BmpBuf[B Shr 3] Or M;
          Inc(Vols[V].FreeSecs);
          Changed := True;
        End;
      End
      Else If (BmpBuf[B Shr 3] And M) <> 0 Then
      Begin
        BmpBuf[B Shr 3] := BmpBuf[B Shr 3] And Not M;
        Dec(Vols[V].FreeSecs);
        Changed := True;
      End;
    End;
    Inc(I);
  End;
  If Changed And (R = NO_ERROR) Then R := SaveBand;
  MarkSecs := R;
End;

{ Longueur (jusqu'a Want) de la suite de secteurs libres commencant en S }
Function FreeRunAt(V, S, Want : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  While (N < Want) And SecFree(V, S + N) Do Inc(N);
  FreeRunAt := N;
End;

{ Chercher une suite de secteurs libres : la premiere de longueur Want a
  partir de Near (puis depuis le debut), sinon la plus longue trouvee.
  Align : alignement du premier secteur (1 ou 4). Rend la longueur
  obtenue (0 = disque plein) et le premier secteur dans Start. }
Function FindRun(V, Near, Want, Align : LongInt; Var Start : LongInt) : LongInt;
Var S, Pass, Stop, L, BestS, BestL, B, Got : LongInt; Done : Boolean;
Begin
  BestS := 0; BestL := 0;
  Done := False;
  If (Near < 0) Or (Near >= Vols[V].TotSec) Then Near := 0;
  For Pass := 0 To 1 Do
  Begin
    If Done Then Continue;
    If Pass = 0 Then
    Begin
      S := Near; Stop := Vols[V].TotSec;
    End
    Else
    Begin
      S := 0; Stop := Near;
    End;
    If Align > 1 Then S := ((S + Align - 1) Div Align) * Align;
    While (S < Stop) And Not Done Do
    Begin
      { sauter rapidement les octets entierement occupes }
      If (S Mod 8 = 0) And (Align <= 8) Then
      Begin
        If LoadBand(V, S Div BAND_SECS) = NO_ERROR Then
        Begin
          B := S Mod BAND_SECS;
          If BmpBuf[B Shr 3] = 0 Then
          Begin
            S := S + 8;
            Continue;
          End;
        End;
      End;
      If SecFree(V, S) Then
      Begin
        L := FreeRunAt(V, S, Want);
        If L > BestL Then
        Begin
          BestL := L;
          BestS := S;
        End;
        If L >= Want Then Done := True
        Else
        Begin
          S := S + L;
          If Align > 1 Then S := ((S + Align - 1) Div Align) * Align;
        End;
      End
      Else
        S := S + Align;
    End;
  End;
  Got := BestL;
  If Align > 1 Then Got := (Got Div Align) * Align;
  Start := BestS;
  FindRun := Got;
End;

{ Allouer jusqu'a Want secteurs contigus pres de Near (au moins 1) }
Function AllocRun(V, Near, Want : LongInt; Var Start : LongInt) : LongInt;
Var Got : LongInt;
Begin
  Got := FindRun(V, Near, Want, 1, Start);
  If Got > Want Then Got := Want;
  If Got > 0 Then
    If MarkSecs(V, Start, Got, False) <> NO_ERROR Then Got := 0;
  AllocRun := Got;
End;

Function AllocSector(V, Near : LongInt) : LongInt;
Var S, R : LongInt;
Begin
  R := 0;
  If AllocRun(V, Near, 1, S) = 1 Then R := S;
  AllocSector := R;
End;

Function LoadDirBmp(V : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If DbVol <> V Then
  Begin
    DbVol := -1;
    R := DevIO(V, DVIO_OPREAD, Vols[V].DirBmp, 4, LongInt(@DbBuf));
    If R = NO_ERROR Then DbVol := V;
  End;
  LoadDirBmp := R;
End;

{ Allouer un dnode (4 secteurs alignes) : dans la bande des repertoires
  si possible, sinon ailleurs sur le volume }
Function AllocDnode(V, Near : LongInt) : LongInt;
Var I, N, S, R : LongInt;
Begin
  R := 0;
  If LoadDirBmp(V) = NO_ERROR Then
  Begin
    N := (Vols[V].DirEnd - Vols[V].DirStart + 1) Div 4;
    I := 0;
    While (I < N) And (R = 0) Do
    Begin
      If (DbBuf[I Shr 3] And (1 Shl (I And 7))) <> 0 Then
      Begin
        DbBuf[I Shr 3] := DbBuf[I Shr 3] And Not (1 Shl (I And 7));
        MarkDirty(V);
        If DevIO(V, DVIO_OPWRITE, Vols[V].DirBmp, 4, LongInt(@DbBuf)) = NO_ERROR Then
          R := Vols[V].DirStart + I * 4;
      End;
      Inc(I);
    End;
  End;
  If R = 0 Then
    If FindRun(V, Near, 4, 4, S) >= 4 Then
      If MarkSecs(V, S, 4, False) = NO_ERROR Then R := S;
  AllocDnode := R;
End;

Procedure FreeDnode(V, S : LongInt);
Var I : LongInt;
Begin
  CacheInvalidate(V, S, 4);
  If (S >= Vols[V].DirStart) And (S <= Vols[V].DirEnd) Then
  Begin
    If LoadDirBmp(V) = NO_ERROR Then
    Begin
      I := (S - Vols[V].DirStart) Div 4;
      DbBuf[I Shr 3] := DbBuf[I Shr 3] Or (1 Shl (I And 7));
      MarkDirty(V);
      DevIO(V, DVIO_OPWRITE, Vols[V].DirBmp, 4, LongInt(@DbBuf));
    End;
  End
  Else
    MarkSecs(V, S, 4, True);
End;

{ Dnodes libres dans la bande des repertoires }
Function FreeDirBand(V : LongInt) : LongInt;
Var I, N, C : LongInt;
Begin
  C := 0;
  If LoadDirBmp(V) = NO_ERROR Then
  Begin
    N := (Vols[V].DirEnd - Vols[V].DirStart + 1) Div 4;
    For I := 0 To N - 1 Do
      If (DbBuf[I Shr 3] And (1 Shl (I And 7))) <> 0 Then Inc(C);
  End;
  FreeDirBand := C;
End;

{ Compter les secteurs libres (au montage) }
Function CountFree(V : LongInt) : LongInt;
Var B, I, J, C, X : LongInt;
Begin
  C := 0;
  For B := 0 To Vols[V].NBands - 1 Do
    If LoadBand(V, B) = NO_ERROR Then
      For I := 0 To 2047 Do
      Begin
        X := BmpBuf[I];
        If X = 255 Then C := C + 8
        Else
          For J := 0 To 7 Do
            If (X And (1 Shl J)) <> 0 Then Inc(C);
      End;
  CountFree := C;
End;

{ ==================================================================== }
{ Partie 6 - Fnodes, anodes et extensions des fichiers                 }
{ ==================================================================== }
{ L'allocation d'un fichier est une liste d'extensions (secteur du
  fichier, longueur, secteur du disque) rangee dans un arbre B+ : jusqu'a
  8 extensions dans le fnode, sinon le fnode pointe vers des anodes de 40
  extensions (12 anodes au plus a l'ecriture ; la lecture accepte toute
  profondeur). La liste du fichier courant est gardee dans ExtF/ExtL/ExtD. }

Function ReadFnode(V, S, Addr : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := ReadSecs(V, S, 1, Addr);
  If R = NO_ERROR Then
    If RdL(Addr) <> FNODE_MAGIC Then R := ERROR_INVALID_DATA;
  ReadFnode := R;
End;

Function WriteFnode(V, S, Addr : LongInt) : LongInt;
Begin
  WriteFnode := WriteSecs(V, S, 1, Addr);
End;

Function LoadTree(V, Hdr, Lvl : LongInt) : LongInt;
Var I, N, R, A, Dn : LongInt;
Begin
  R := NO_ERROR;
  N := RdB(Hdr + 5);
  If (RdB(Hdr) And BP_INTERNAL) <> 0 Then
  Begin
    If Lvl > 3 Then R := ERROR_INVALID_DATA;
    I := 0;
    While (I < N) And (R = NO_ERROR) Do
    Begin
      Dn := RdL(Hdr + 8 + I * 8 + 4);
      A := LongInt(@AnBuf[Lvl]);
      R := ReadSecs(V, Dn, 1, A);
      If (R = NO_ERROR) And (RdL(A) <> ANODE_MAGIC) Then R := ERROR_INVALID_DATA;
      If R = NO_ERROR Then
      Begin
        If AnN < 64 Then
        Begin
          AnList[AnN] := Dn;
          Inc(AnN);
        End;
        R := LoadTree(V, A + 12, Lvl + 1);
      End;
      Inc(I);
    End;
  End
  Else
    For I := 0 To N - 1 Do
      If (R = NO_ERROR) And (ExtN < MaxExt) Then
      Begin
        ExtF[ExtN] := RdL(Hdr + 8 + I * 12);
        ExtL[ExtN] := RdL(Hdr + 8 + I * 12 + 4);
        ExtD[ExtN] := RdL(Hdr + 8 + I * 12 + 8);
        Inc(ExtN);
      End;
  LoadTree := R;
End;

{ Charger la liste d'extensions du fnode FnSec (contenu deja dans Fn) }
Function LoadExtents(V, FnSec, Fn : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If (ExtVol <> V) Or (ExtFnode <> FnSec) Then
  Begin
    ExtVol := -1;
    ExtN := 0; AnN := 0;
    R := LoadTree(V, Fn + FN_BTREE, 0);
    If R = NO_ERROR Then
    Begin
      ExtVol := V;
      ExtFnode := FnSec;
    End;
  End;
  LoadExtents := R;
End;

Function AllocatedSecs : LongInt;
Var I, T : LongInt;
Begin
  T := 0;
  For I := 0 To ExtN - 1 Do T := T + ExtL[I];
  AllocatedSecs := T;
End;

{ Secteur du disque du secteur FileSec du fichier courant ; Run = secteurs
  contigus restants (0 si hors allocation) }
Function MapSec(FileSec : LongInt; Var Run : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0; Run := 0;
  For I := 0 To ExtN - 1 Do
    If (FileSec >= ExtF[I]) And (FileSec < ExtF[I] + ExtL[I]) Then
    Begin
      R := ExtD[I] + FileSec - ExtF[I];
      Run := ExtF[I] + ExtL[I] - FileSec;
    End;
  MapSec := R;
End;

{ Reecrire l'arbre d'allocation (dans le fnode en memoire Fn, anodes sur
  le disque) d'apres ExtF/ExtL/ExtD ; le fnode est ecrit par l'appelant }
Function StoreExtents(V, FnSec, Fn : LongInt) : LongInt;
Var I, K, J, N, S, R, Hdr, A : LongInt; Secs : Array[0..11] Of LongInt;
Begin
  R := NO_ERROR;
  { fusionner les extensions contigues }
  K := 0;
  For I := 0 To ExtN - 1 Do
    If ExtL[I] > 0 Then
    Begin
      If (K > 0) And (ExtD[K - 1] + ExtL[K - 1] = ExtD[I]) And (ExtF[K - 1] + ExtL[K - 1] = ExtF[I]) Then
        ExtL[K - 1] := ExtL[K - 1] + ExtL[I]
      Else
      Begin
        ExtF[K] := ExtF[I]; ExtL[K] := ExtL[I]; ExtD[K] := ExtD[I];
        Inc(K);
      End;
    End;
  ExtN := K;
  { liberer les anodes de l'ancien arbre }
  For I := 0 To AnN - 1 Do
  Begin
    CacheInvalidate(V, AnList[I], 1);
    MarkSecs(V, AnList[I], 1, True);
  End;
  AnN := 0;
  Hdr := Fn + FN_BTREE;
  FillB(Hdr, 104, 0);
  If ExtN <= 8 Then
  Begin
    WrB(Hdr + 4, 8 - ExtN);
    WrB(Hdr + 5, ExtN);
    WrW(Hdr + 6, 8 + 12 * ExtN);
    For I := 0 To ExtN - 1 Do
    Begin
      WrL(Hdr + 8 + I * 12, ExtF[I]);
      WrL(Hdr + 8 + I * 12 + 4, ExtL[I]);
      WrL(Hdr + 8 + I * 12 + 8, ExtD[I]);
    End;
  End
  Else
  Begin
    K := (ExtN + 39) Div 40;
    If K > 12 Then R := ERROR_DISK_FULL;
    J := 0;
    While (J < K) And (R = NO_ERROR) Do
    Begin
      S := AllocSector(V, FnSec);
      If S = 0 Then R := ERROR_DISK_FULL
      Else
      Begin
        Secs[J] := S;
        AnList[AnN] := S;
        Inc(AnN);
        A := LongInt(@AnBuf[0]);
        FillB(A, 512, 0);
        WrL(A, ANODE_MAGIC);
        WrL(A + 4, S);
        WrL(A + 8, FnSec);
        N := ExtN - J * 40;
        If N > 40 Then N := 40;
        WrB(A + 12, BP_FNPARENT);
        WrB(A + 16, 40 - N);
        WrB(A + 17, N);
        WrW(A + 18, 8 + 12 * N);
        For I := 0 To N - 1 Do
        Begin
          WrL(A + 20 + I * 12, ExtF[J * 40 + I]);
          WrL(A + 20 + I * 12 + 4, ExtL[J * 40 + I]);
          WrL(A + 20 + I * 12 + 8, ExtD[J * 40 + I]);
        End;
        R := WriteSecs(V, S, 1, A);
      End;
      Inc(J);
    End;
    If R = NO_ERROR Then
    Begin
      WrB(Hdr, BP_INTERNAL);
      WrB(Hdr + 4, 12 - K);
      WrB(Hdr + 5, K);
      WrW(Hdr + 6, 8 + 8 * K);
      For J := 0 To K - 1 Do
      Begin
        If J < K - 1 Then WrL(Hdr + 8 + J * 8, ExtF[(J + 1) * 40])
        Else WrL(Hdr + 8 + J * 8, -1);
        WrL(Hdr + 8 + J * 8 + 4, Secs[J]);
      End;
    End;
  End;
  ExtVol := V;
  ExtFnode := FnSec;
  StoreExtents := R;
End;

{ Porter l'allocation du fichier (fnode FnSec, en memoire dans Fn) a NSec
  secteurs ; le fnode n'est pas ecrit }
Function GrowTo(V, FnSec, Fn, NSec : LongInt) : LongInt;
Var Cur, Near, Got, S, R : LongInt; Changed : Boolean;
Begin
  R := LoadExtents(V, FnSec, Fn);
  Changed := False;
  If R = NO_ERROR Then
  Begin
    Cur := AllocatedSecs;
    While (Cur < NSec) And (R = NO_ERROR) Do
    Begin
      If ExtN > 0 Then Near := ExtD[ExtN - 1] + ExtL[ExtN - 1] Else Near := FnSec + 1;
      Got := AllocRun(V, Near, NSec - Cur, S);
      If Got = 0 Then R := ERROR_DISK_FULL
      Else
      Begin
        Changed := True;
        If (ExtN > 0) And (S = Near) Then
          ExtL[ExtN - 1] := ExtL[ExtN - 1] + Got
        Else If ExtN >= MaxExt Then
        Begin
          MarkSecs(V, S, Got, True);
          R := ERROR_DISK_FULL;
          Got := 0;
        End
        Else
        Begin
          ExtF[ExtN] := Cur; ExtL[ExtN] := Got; ExtD[ExtN] := S;
          Inc(ExtN);
        End;
        Cur := Cur + Got;
      End;
    End;
    If Changed Then
      If StoreExtents(V, FnSec, Fn) <> NO_ERROR Then R := ERROR_DISK_FULL;
  End;
  GrowTo := R;
End;

{ Reduire l'allocation a NSec secteurs }
Function ShrinkTo(V, FnSec, Fn, NSec : LongInt) : LongInt;
Var I, K, R, Keep : LongInt; Changed : Boolean;
Begin
  R := LoadExtents(V, FnSec, Fn);
  Changed := False;
  If R = NO_ERROR Then
  Begin
    K := 0;
    For I := 0 To ExtN - 1 Do
    Begin
      If ExtF[I] >= NSec Then
      Begin
        MarkSecs(V, ExtD[I], ExtL[I], True);
        CacheInvalidate(V, ExtD[I], ExtL[I]);
        Changed := True;
      End
      Else
      Begin
        Keep := ExtL[I];
        If ExtF[I] + Keep > NSec Then
        Begin
          Keep := NSec - ExtF[I];
          MarkSecs(V, ExtD[I] + Keep, ExtL[I] - Keep, True);
          Changed := True;
        End;
        ExtF[K] := ExtF[I]; ExtL[K] := Keep; ExtD[K] := ExtD[I];
        Inc(K);
      End;
    End;
    ExtN := K;
    If Changed Then R := StoreExtents(V, FnSec, Fn);
  End;
  ShrinkTo := R;
End;

{ Liberer toute l'allocation d'un fichier (donnees, anodes, EA externes) }
Function FreeFileSpace(V, FnSec, Fn : LongInt) : LongInt;
Var I, R, L : LongInt;
Begin
  ExtVol := -1;
  R := LoadExtents(V, FnSec, Fn);
  If R = NO_ERROR Then
  Begin
    For I := 0 To ExtN - 1 Do MarkSecs(V, ExtD[I], ExtL[I], True);
    For I := 0 To AnN - 1 Do
    Begin
      CacheInvalidate(V, AnList[I], 1);
      MarkSecs(V, AnList[I], 1, True);
    End;
  End;
  L := RdL(Fn + FN_EASIZEL);
  If (L > 0) And ((RdW(Fn + FN_FLAGS) And FNF_EAANODE) = 0) Then
    MarkSecs(V, RdL(Fn + FN_EASEC), (L + 511) Div 512, True);
  ExtVol := -1;
  FreeFileSpace := R;
End;

{ Construire un fnode neuf dans Fn }
Procedure BuildFnode(Fn, Up : LongInt; Name : String; IsDir : Boolean);
Var I, L : LongInt;
Begin
  FillB(Fn, 512, 0);
  WrL(Fn, FNODE_MAGIC);
  L := Length(Name);
  WrB(Fn + FN_LEN, L);
  If L > 15 Then L := 15;
  For I := 1 To L Do WrB(Fn + FN_NAME + I - 1, Ord(Name[I]));
  WrL(Fn + FN_UP, Up);
  If IsDir Then WrW(Fn + FN_FLAGS, FNF_DIR);
  WrB(Fn + FN_BTREE + 4, 8);
  WrB(Fn + FN_BTREE + 5, 0);
  WrW(Fn + FN_BTREE + 6, 8);
  WrW(Fn + FN_EAOFS, FN_EAAREA);
End;

{ ==================================================================== }
{ Partie 7 - Attributs etendus (EA)                                    }
{ ==================================================================== }
{ Liste d'EA au format HPFS (dans le fnode a partir de l'octet 196, ou
  dans une suite de secteurs) : drapeaux (1 octet ; 80h = NEEDEA,
  01h = valeur indirecte), longueur du nom (1), longueur de la valeur (2),
  nom, zero, valeur. Interface OS/2 : FEA2LIST, GEA2LIST et EAOP2. }

Function EaNext(P : LongInt) : LongInt;
Begin
  EaNext := P + 5 + EaBuf[P + 1] + EaBuf[P + 2] + EaBuf[P + 3] * 256;
End;

{ Lire la liste d'EA du fnode Fn dans EaBuf }
Function LoadEAs(V, Fn : LongInt) : LongInt;
Var S, Ofs, L, Sec, R, N : LongInt;
Begin
  R := NO_ERROR;
  EaLen := 0;
  S := RdW(Fn + FN_EASIZES);
  Ofs := RdW(Fn + FN_EAOFS);
  If (S > 0) And (Ofs >= FN_EAAREA) And (Ofs + S <= 512) Then
  Begin
    MoveB(Fn + Ofs, LongInt(@EaBuf), S);
    EaLen := S;
  End;
  L := RdL(Fn + FN_EASIZEL);
  If (L > 0) And ((RdW(Fn + FN_FLAGS) And FNF_EAANODE) = 0) Then
  Begin
    If EaLen + L > EaBufMax Then R := ERROR_EAS_DIDNT_FIT
    Else
    Begin
      Sec := RdL(Fn + FN_EASEC);
      N := (L + 511) Div 512;
      R := DataRead(V, Sec, N, LongInt(@EaBuf2));
      If R = NO_ERROR Then
      Begin
        MoveB(LongInt(@EaBuf2), LongInt(@EaBuf) + EaLen, L);
        EaLen := EaLen + L;
      End;
    End;
  End;
  LoadEAs := R;
End;

{ Longueur reelle de la valeur de l'EA en P (valeur indirecte : longueur
  enregistree dans ses 4 premiers octets) }
Function EaValueLen(P : LongInt) : LongInt;
Var VL : LongInt;
Begin
  VL := EaBuf[P + 2] + EaBuf[P + 3] * 256;
  If (EaBuf[P] And 3) <> 0 Then VL := RdL(LongInt(@EaBuf) + P + 5 + EaBuf[P + 1]);
  EaValueLen := VL;
End;

{ Copier la valeur de l'EA en P a l'adresse Dst (au plus Max octets) }
Function EaValueGet(V, P, Dst, Max : LongInt) : LongInt;
Var VL, R, A, Sec : LongInt;
Begin
  R := NO_ERROR;
  A := LongInt(@EaBuf) + P + 5 + EaBuf[P + 1];
  VL := EaValueLen(P);
  If VL > Max Then R := ERROR_BUFFER_OVERFLOW
  Else If (EaBuf[P] And 3) = 0 Then MoveB(A, Dst, VL)
  Else If (EaBuf[P] And 2) <> 0 Then R := ERROR_EAS_DIDNT_FIT
  Else If VL > EaBufMax Then R := ERROR_EAS_DIDNT_FIT
  Else
  Begin
    Sec := RdL(A + 4);
    R := DataRead(V, Sec, (VL + 511) Div 512, LongInt(@EaBuf2));
    If R = NO_ERROR Then MoveB(LongInt(@EaBuf2), Dst, VL);
  End;
  EaValueGet := R;
End;

{ Position de l'EA de nom (Na, Nl) dans EaBuf, ou -1 }
Function EaFind(Na, Nl : LongInt) : LongInt;
Var P, R : LongInt;
Begin
  R := -1;
  P := 0;
  While (P < EaLen) And (R < 0) Do
  Begin
    If (EaBuf[P + 1] = Nl) And (CmpMem(Na, Nl, LongInt(@EaBuf) + P + 4, Nl) = 0) Then R := P
    Else P := EaNext(P);
  End;
  EaFind := R;
End;

{ Retirer l'EA en P (et liberer sa valeur indirecte) }
Procedure EaRemove(V, P : LongInt);
Var N, A : LongInt;
Begin
  If (EaBuf[P] And 3) = 1 Then
  Begin
    A := LongInt(@EaBuf) + P + 5 + EaBuf[P + 1];
    MarkSecs(V, RdL(A + 4), (RdL(A) + 511) Div 512, True);
  End;
  N := EaNext(P) - P;
  MoveB(LongInt(@EaBuf) + P + N, LongInt(@EaBuf) + P, EaLen - P - N);
  EaLen := EaLen - N;
End;

{ Ajouter un EA (nom mis en majuscules) ; rend un code d'erreur }
Function EaAdd(Flags, Na, Nl, Va, Vl : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := NO_ERROR;
  If EaLen + 5 + Nl + Vl > EaBufMax Then R := ERROR_EAS_DIDNT_FIT
  Else
  Begin
    EaBuf[EaLen] := Flags And $80;
    EaBuf[EaLen + 1] := Nl;
    EaBuf[EaLen + 2] := Vl And 255;
    EaBuf[EaLen + 3] := (Vl Shr 8) And 255;
    For I := 0 To Nl - 1 Do EaBuf[EaLen + 4 + I] := Upper[RdB(Na + I)];
    EaBuf[EaLen + 4 + Nl] := 0;
    MoveB(Va, LongInt(@EaBuf) + EaLen + 5 + Nl, Vl);
    EaLen := EaLen + 5 + Nl + Vl;
  End;
  EaAdd := R;
End;

Function EaNeedCount : LongInt;
Var P, C : LongInt;
Begin
  C := 0;
  P := 0;
  While P < EaLen Do
  Begin
    If (EaBuf[P] And $80) <> 0 Then Inc(C);
    P := EaNext(P);
  End;
  EaNeedCount := C;
End;

{ Taille de la liste au format FEA2LIST (cbList) }
Function EaFea2Size : LongInt;
Var P, T, S : LongInt;
Begin
  T := 4;
  P := 0;
  While P < EaLen Do
  Begin
    S := 9 + EaBuf[P + 1] + EaValueLen(P);
    P := EaNext(P);
    If P < EaLen Then S := (S + 3) And Not 3;
    T := T + S;
  End;
  EaFea2Size := T;
End;

{ Ecrire la liste EaBuf pour le fnode FnSec (en memoire dans Fn) : dans le
  fnode si elle tient (316 octets), sinon dans des secteurs contigus }
Function StoreEAs(V, FnSec, Fn : LongInt) : LongInt;
Var L, R, N, S : LongInt;
Begin
  R := NO_ERROR;
  L := RdL(Fn + FN_EASIZEL);
  If (L > 0) And ((RdW(Fn + FN_FLAGS) And FNF_EAANODE) = 0) Then
    MarkSecs(V, RdL(Fn + FN_EASEC), (L + 511) Div 512, True);
  WrL(Fn + FN_EASIZEL, 0);
  WrL(Fn + FN_EASEC, 0);
  WrW(Fn + FN_FLAGS, RdW(Fn + FN_FLAGS) And Not FNF_EAANODE);
  WrW(Fn + FN_EAOFS, FN_EAAREA);
  FillB(Fn + FN_EAAREA, FN_EAMAX, 0);
  If EaLen <= FN_EAMAX Then
  Begin
    WrW(Fn + FN_EASIZES, EaLen);
    MoveB(LongInt(@EaBuf), Fn + FN_EAAREA, EaLen);
  End
  Else
  Begin
    WrW(Fn + FN_EASIZES, 0);
    N := (EaLen + 511) Div 512;
    If FindRun(V, FnSec, N, 1, S) < N Then R := ERROR_DISK_FULL
    Else
    Begin
      R := MarkSecs(V, S, N, False);
      FillB(LongInt(@EaBuf) + EaLen, N * 512 - EaLen, 0);
      If R = NO_ERROR Then R := DataWrite(V, S, N, LongInt(@EaBuf));
      If R = NO_ERROR Then
      Begin
        WrL(Fn + FN_EASIZEL, EaLen);
        WrL(Fn + FN_EASEC, S);
      End;
    End;
  End;
  WrL(Fn + FN_NEEDEA, EaNeedCount);
  StoreEAs := R;
End;

{ Ecrire une FEA2 (nom, valeur de l'EA en P ou absente si P < 0) en Dst ;
  rend la longueur ecrite ou -1 si Room est insuffisant }
Function PutFea2(V, P, Dst, Room, Na, Nl : LongInt) : LongInt;
Var VL, Need, R : LongInt;
Begin
  If P >= 0 Then VL := EaValueLen(P) Else VL := 0;
  Need := 9 + Nl + VL;
  If Need > Room Then R := -1
  Else
  Begin
    WrL(Dst, 0);
    If P >= 0 Then WrB(Dst + 4, EaBuf[P] And $80) Else WrB(Dst + 4, 0);
    WrB(Dst + 5, Nl);
    WrW(Dst + 6, VL);
    MoveB(Na, Dst + 8, Nl);
    WrB(Dst + 8 + Nl, 0);
    R := Need;
    If P >= 0 Then
      If EaValueGet(V, P, Dst + 9 + Nl, VL) <> NO_ERROR Then WrW(Dst + 6, 0);
  End;
  PutFea2 := R;
End;

{ Remplir le FEA2LIST en F (cbList en entree = taille disponible) avec les
  EA demandes par le GEA2LIST en G, ou avec tous les EA si G = 0 }
Function QueryEAs(V, G, F : LongInt) : LongInt;
Var Room, FPos, Prev, P, Q, Na, Nl, L, R, GEnd : LongInt; More : Boolean;
Begin
  R := NO_ERROR;
  Room := RdL(F);
  If Room < 4 Then R := ERROR_BUFFER_OVERFLOW
  Else
  Begin
    FPos := 4; Prev := -1;
    If G <> 0 Then
    Begin
      GEnd := G + RdL(G);
      Q := G + 4;
      More := RdL(G) > 4;
      While More And (R = NO_ERROR) Do
      Begin
        Nl := RdB(Q + 4);
        Na := Q + 5;
        P := EaFind(Na, Nl);
        If Prev >= 0 Then FPos := (FPos + 3) And Not 3;
        L := PutFea2(V, P, F + FPos, Room - FPos, Na, Nl);
        If L < 0 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          If Prev >= 0 Then WrL(F + Prev, FPos - Prev);
          Prev := FPos;
          FPos := FPos + L;
        End;
        If RdL(Q) = 0 Then More := False
        Else
        Begin
          Q := Q + RdL(Q);
          If Q >= GEnd Then More := False;
        End;
      End;
    End
    Else
    Begin
      P := 0;
      While (P < EaLen) And (R = NO_ERROR) Do
      Begin
        If Prev >= 0 Then FPos := (FPos + 3) And Not 3;
        L := PutFea2(V, P, F + FPos, Room - FPos, LongInt(@EaBuf) + P + 4, EaBuf[P + 1]);
        If L < 0 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          If Prev >= 0 Then WrL(F + Prev, FPos - Prev);
          Prev := FPos;
          FPos := FPos + L;
        End;
        P := EaNext(P);
      End;
    End;
    If R = NO_ERROR Then WrL(F, FPos);
  End;
  QueryEAs := R;
End;

{ Nom d'EA valide : 1 a 255 caracteres, sans caractere interdit }
Function EaNameOk(Na, Nl : LongInt) : Boolean;
Var I, C : LongInt; R : Boolean;
Begin
  R := (Nl > 0);
  For I := 0 To Nl - 1 Do
  Begin
    C := RdB(Na + I);
    If (C < 32) Or (C = 42) Or (C = 63) Or (C = 92) Or (C = 47) Or (C = 58) Or
       (C = 60) Or (C = 62) Or (C = 124) Or (C = 34) Then R := False;
  End;
  EaNameOk := R;
End;

{ Appliquer un FEA2LIST (valeur vide = suppression) a EaBuf ; POErr recoit
  le deplacement de l'entree fautive }
Function ApplyFea2(V, F, POErr : LongInt) : LongInt;
Var Q, FEnd, Nl, Vl, P, R : LongInt; More : Boolean;
Begin
  R := NO_ERROR;
  If F = 0 Then
  Begin
    ApplyFea2 := NO_ERROR;
    Exit;
  End;
  FEnd := F + RdL(F);
  Q := F + 4;
  More := RdL(F) > 4;
  While More And (R = NO_ERROR) Do
  Begin
    Nl := RdB(Q + 5);
    Vl := RdW(Q + 6);
    If (Q + 9 + Nl + Vl > FEnd) Then R := ERROR_EA_LIST_INCONSISTENT
    Else If Not EaNameOk(Q + 8, Nl) Then R := ERROR_INVALID_EA_NAME
    Else
    Begin
      P := EaFind(Q + 8, Nl);
      If P >= 0 Then EaRemove(V, P);
      If Vl > 0 Then R := EaAdd(RdB(Q + 4), Q + 8, Nl, Q + 9 + Nl, Vl);
    End;
    If R <> NO_ERROR Then WrL(POErr, Q - F)
    Else If RdL(Q) = 0 Then More := False
    Else
    Begin
      Q := Q + RdL(Q);
      If Q >= FEnd Then More := False;
    End;
  End;
  ApplyFea2 := R;
End;

{ ==================================================================== }
{ Partie 8 - Repertoires : arbre B des dnodes                          }
{ ==================================================================== }
{ Un repertoire est un arbre B de dnodes (2048 octets) dont la racine est
  designee par l'unique extension du fnode du repertoire. Un dnode :
    +0 signature  +4 premier octet libre  +8 bit 0 = racine
    +12 parent (dnode, ou fnode pour la racine)  +16 lui-meme
    +20 entrees (dirent) triees, terminees par l'entree finale (nom FFh)
  Une entree peut porter (4 derniers octets) un pointeur vers le dnode
  des noms qui la precedent ; le pointeur de l'entree finale designe les
  noms qui suivent toutes les autres entrees du dnode. La racine commence
  par l'entree ^A^A qui designe le repertoire lui-meme. }

Var
  LkDn, LkOff : LongInt;      { dnode et position de la derniere entree trouvee }
  MxDn, MxOff : LongInt;
  UpBuf       : Array[0..2047] Of Byte;
  SplitBuf    : Array[0..2047] Of Byte;
  SplitOfs    : Array[0..199] Of LongInt;
  DirFn       : Array[0..511] Of Byte;

Function DeLen(E : LongInt) : LongInt;
Begin
  DeLen := RdW(E);
End;

Function DeIsLast(E : LongInt) : Boolean;
Begin
  DeIsLast := (RdB(E + DE_FLAGS) And DF_LAST) <> 0;
End;

Function DeHasDown(E : LongInt) : Boolean;
Begin
  DeHasDown := (RdB(E + DE_FLAGS) And DF_DOWN) <> 0;
End;

Function DeDown(E : LongInt) : LongInt;
Begin
  If DeHasDown(E) Then DeDown := RdL(E + RdW(E) - 4) Else DeDown := 0;
End;

{ Comparer le nom de l'entree E a la cle (Ka, Kl) : <0 si cle < entree }
Function CmpKey(Ka, Kl, E : LongInt) : LongInt;
Begin
  If DeIsLast(E) Then CmpKey := -1
  Else CmpKey := CmpMem(Ka, Kl, E + DE_NAME, RdB(E + DE_NLEN));
End;

{ Construire une entree en E ; rend sa longueur }
Function BuildDe(E : LongInt; Name : String; Attr, Fnode, Size, WDate, RDate, CDate : LongInt) : LongInt;
Var I, L, Len : LongInt;
Begin
  L := Length(Name);
  Len := (DE_NAME + L + 3) And Not 3;
  FillB(E, Len, 0);
  WrW(E, Len);
  WrB(E + DE_ATTR, Attr);
  WrL(E + DE_FNODE, Fnode);
  WrL(E + DE_WDATE, WDate);
  WrL(E + DE_SIZE, Size);
  WrL(E + DE_RDATE, RDate);
  WrL(E + DE_CDATE, CDate);
  WrB(E + DE_NLEN, L);
  For I := 1 To L Do WrB(E + DE_NAME + I - 1, Ord(Name[I]));
  BuildDe := Len;
End;

{ Entree finale (nom FFh) en E, avec pointeur Down si Down <> 0 }
Function BuildLast(E, Down : LongInt) : LongInt;
Var Len : LongInt;
Begin
  FillB(E, 36, 0);
  Len := 32;
  WrB(E + DE_FLAGS, DF_LAST);
  WrB(E + DE_NLEN, 1);
  WrB(E + DE_NAME, 255);
  If Down <> 0 Then
  Begin
    Len := 36;
    WrB(E + DE_FLAGS, DF_LAST Or DF_DOWN);
    WrL(E + 32, Down);
  End;
  WrW(E, Len);
  BuildLast := Len;
End;

Function ReadDnode(V, S, Addr : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := ReadSecs(V, S, 4, Addr);
  If R = NO_ERROR Then
    If (RdL(Addr) <> DNODE_MAGIC) Or (RdL(Addr + 16) <> S) Or (RdL(Addr + 4) > DNODE_SIZE) Or
       (RdL(Addr + 4) < DN_HDR + 32) Then R := ERROR_INVALID_DATA;
  ReadDnode := R;
End;

Function WriteDnode(V, S, Addr : LongInt) : LongInt;
Begin
  WriteDnode := WriteSecs(V, S, 4, Addr);
End;

Procedure InitDnode(D, Self, Up : LongInt; IsRoot : Boolean);
Begin
  FillB(D, DNODE_SIZE, 0);
  WrL(D, DNODE_MAGIC);
  WrL(D + 4, DN_HDR);
  If IsRoot Then WrB(D + 8, 1);
  WrL(D + 12, Up);
  WrL(D + 16, Self);
End;

{ Dnode racine du repertoire de fnode DirSec }
Function DirRoot(V, DirSec : LongInt; Var Dn : LongInt) : LongInt;
Var R : LongInt;
Begin
  Dn := 0;
  R := ReadFnode(V, DirSec, LongInt(@DirFn));
  If R = NO_ERROR Then
  Begin
    If ((RdW(LongInt(@DirFn) + FN_FLAGS) And FNF_DIR) = 0) Then R := ERROR_PATH_NOT_FOUND
    Else Dn := RdL(LongInt(@DirFn) + FN_BTREE + 8 + 8);
  End;
  DirRoot := R;
End;

{ Changer le parent d'un dnode }
Function SetUp(V, Child, NewUp : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := ReadDnode(V, Child, LongInt(@UpBuf));
  If (R = NO_ERROR) And (RdL(LongInt(@UpBuf) + 12) <> NewUp) Then
  Begin
    WrL(LongInt(@UpBuf) + 12, NewUp);
    R := WriteDnode(V, Child, LongInt(@UpBuf));
  End;
  SetUp := R;
End;

{ Chercher la cle KeyBuf/KeyLen dans le repertoire DirSec : l'entree est
  copiee dans DeOut, son dnode (dans DnBuf[0]) et sa position dans
  LkDn/LkOff. Rend vrai si trouvee. }
Function Lookup(V, DirSec : LongInt) : Boolean;
Var Dn, D, P, E, C, Guard : LongInt; Found, Done : Boolean;
Begin
  Found := False;
  If DirRoot(V, DirSec, Dn) = NO_ERROR Then
  Begin
    D := LongInt(@DnBuf[0]);
    Done := False;
    Guard := 0;
    While Not Done Do
    Begin
      Inc(Guard);
      If (Guard > 32) Or (ReadDnode(V, Dn, D) <> NO_ERROR) Then Done := True
      Else
      Begin
        P := DN_HDR;
        While Not Done Do
        Begin
          E := D + P;
          If (DeLen(E) < 32) Or (P + DeLen(E) > DNODE_SIZE) Then Done := True
          Else
          Begin
            C := CmpKey(LongInt(@KeyBuf), KeyLen, E);
            If C = 0 Then
            Begin
              Found := True;
              Done := True;
              LkDn := Dn; LkOff := P;
              MoveB(E, LongInt(@DeOut), DeLen(E));
            End
            Else If C < 0 Then
            Begin
              If DeHasDown(E) Then
              Begin
                Dn := DeDown(E);
                Break;
              End;
              Done := True;
            End
            Else
              P := P + DeLen(E);
          End;
        End;
      End;
    End;
  End;
  Lookup := Found;
End;

{ Feuille ou inserer la cle KeyBuf : dnode rendu dans Dn }
Function FindLeaf(V, DirSec : LongInt; Var Dn : LongInt) : LongInt;
Var D, P, E, R, Guard : LongInt; Done, Down : Boolean;
Begin
  R := DirRoot(V, DirSec, Dn);
  D := LongInt(@DnBuf[0]);
  Guard := 0;
  Done := R <> NO_ERROR;
  While Not Done Do
  Begin
    Inc(Guard);
    R := ReadDnode(V, Dn, D);
    If (Guard > 32) And (R = NO_ERROR) Then R := ERROR_INVALID_DATA;
    If R <> NO_ERROR Then Done := True
    Else
    Begin
      P := DN_HDR;
      Down := False;
      While (Not Done) And (Not Down) Do
      Begin
        E := D + P;
        If (DeLen(E) < 32) Or (P + DeLen(E) > DNODE_SIZE) Then
        Begin
          R := ERROR_INVALID_DATA;
          Done := True;
        End
        Else If CmpKey(LongInt(@KeyBuf), KeyLen, E) < 0 Then
        Begin
          If DeHasDown(E) Then
          Begin
            Dn := DeDown(E);
            Down := True;
          End
          Else
            Done := True;
        End
        Else
          P := P + DeLen(E);
      End;
    End;
  End;
  FindLeaf := R;
End;

{ Inserer l'entree en EA dans le dnode Dn (Lvl = niveau de recursion) ;
  separe le dnode s'il deborde }
Function InsertInto(V, Dn, EA, Lvl : LongInt) : LongInt;
Var D, T, TLen, P, E, L, ELen, R, N, M, Acc, I, Up, Lft, R2, Em, EmLen, Sb, Q, X : LongInt;
    Inserted, IsRoot, Done : Boolean;
Begin
  D := LongInt(@DnBuf[Lvl]);
  T := LongInt(@TmpBuf);
  R := ReadDnode(V, Dn, D);
  If (R = NO_ERROR) And (Lvl > 8) Then R := ERROR_INVALID_DATA;
  If R <> NO_ERROR Then
  Begin
    InsertInto := R;
    Exit;
  End;
  ELen := DeLen(EA);
  TLen := 0;
  Inserted := False;
  P := DN_HDR;
  Done := False;
  While Not Done Do
  Begin
    E := D + P;
    L := DeLen(E);
    If (L < 32) Or (P + L > DNODE_SIZE) Then
    Begin
      R := ERROR_INVALID_DATA;
      Done := True;
    End
    Else
    Begin
      If (Not Inserted) And (CmpKey(EA + DE_NAME, RdB(EA + DE_NLEN), E) < 0) Then
      Begin
        MoveB(EA, T + TLen, ELen);
        TLen := TLen + ELen;
        Inserted := True;
      End;
      MoveB(E, T + TLen, L);
      TLen := TLen + L;
      If DeIsLast(E) Then Done := True Else P := P + L;
    End;
  End;
  If R <> NO_ERROR Then
  Begin
    InsertInto := R;
    Exit;
  End;
  If DN_HDR + TLen <= DNODE_SIZE Then
  Begin
    MoveB(T, D + DN_HDR, TLen);
    FillB(D + DN_HDR + TLen, DNODE_SIZE - DN_HDR - TLen, 0);
    WrL(D + 4, DN_HDR + TLen);
    R := WriteDnode(V, Dn, D);
    If (R = NO_ERROR) And DeHasDown(EA) Then R := SetUp(V, DeDown(EA), Dn);
    InsertInto := R;
    Exit;
  End;
  { separation : entrees e0..e(m-1) -> nouveau dnode gauche, em monte
    dans le parent avec un pointeur vers ce dnode, la suite reste }
  N := 0; P := 0;
  While (P < TLen) And (N < 200) Do
  Begin
    SplitOfs[N] := P;
    Inc(N);
    P := P + DeLen(T + P);
  End;
  M := 0; Acc := 0;
  While (M < N - 1) And (Acc + DeLen(T + SplitOfs[M]) < TLen Div 2) Do
  Begin
    Acc := Acc + DeLen(T + SplitOfs[M]);
    Inc(M);
  End;
  If M < 1 Then M := 1;
  If M > N - 2 Then M := N - 2;
  Em := T + SplitOfs[M];
  EmLen := DeLen(Em);
  IsRoot := (RdB(D + 8) And 1) <> 0;
  Up := RdL(D + 12);
  Lft := AllocDnode(V, Dn);
  If Lft = 0 Then
  Begin
    InsertInto := ERROR_DISK_FULL;
    Exit;
  End;
  { dnode gauche }
  Sb := LongInt(@SplitBuf);
  If IsRoot Then InitDnode(Sb, Lft, Dn, False) Else InitDnode(Sb, Lft, Up, False);
  MoveB(T, Sb + DN_HDR, SplitOfs[M]);
  Q := DN_HDR + SplitOfs[M];
  Q := Q + BuildLast(Sb + Q, DeDown(Em));
  WrL(Sb + 4, Q);
  R := WriteDnode(V, Lft, Sb);
  { entree qui monte : em avec un pointeur vers le dnode gauche }
  X := LongInt(@EntBuf[Lvl + 1]);
  If DeHasDown(Em) Then L := EmLen - 4 Else L := EmLen;
  MoveB(Em, X, L);
  WrB(X + DE_FLAGS, RdB(X + DE_FLAGS) Or DF_DOWN);
  WrW(X, L + 4);
  WrL(X + L, Lft);
  If R = NO_ERROR Then
  Begin
    If IsRoot Then
    Begin
      R2 := AllocDnode(V, Dn);
      If R2 = 0 Then R := ERROR_DISK_FULL
      Else
      Begin
        { la suite va dans un second dnode ; la racine garde em et l'entree finale }
        InitDnode(D, R2, Dn, False);
        MoveB(T + SplitOfs[M + 1], D + DN_HDR, TLen - SplitOfs[M + 1]);
        WrL(D + 4, DN_HDR + TLen - SplitOfs[M + 1]);
        R := WriteDnode(V, R2, D);
        If R = NO_ERROR Then
        Begin
          InitDnode(Sb, Dn, Up, True);
          MoveB(X, Sb + DN_HDR, L + 4);
          Q := DN_HDR + L + 4;
          Q := Q + BuildLast(Sb + Q, R2);
          WrL(Sb + 4, Q);
          R := WriteDnode(V, Dn, Sb);
        End;
        { parents des fils deplaces }
        For I := M + 1 To N - 1 Do
          If (R = NO_ERROR) And DeHasDown(T + SplitOfs[I]) Then R := SetUp(V, DeDown(T + SplitOfs[I]), R2);
      End;
    End
    Else
    Begin
      InitDnode(D, Dn, Up, False);
      MoveB(T + SplitOfs[M + 1], D + DN_HDR, TLen - SplitOfs[M + 1]);
      WrL(D + 4, DN_HDR + TLen - SplitOfs[M + 1]);
      R := WriteDnode(V, Dn, D);
      For I := M + 1 To N - 1 Do
        If (R = NO_ERROR) And DeHasDown(T + SplitOfs[I]) Then R := SetUp(V, DeDown(T + SplitOfs[I]), Dn);
    End;
    For I := 0 To M Do
      If (R = NO_ERROR) And DeHasDown(T + SplitOfs[I]) Then R := SetUp(V, DeDown(T + SplitOfs[I]), Lft);
    If (R = NO_ERROR) And Not IsRoot Then R := InsertInto(V, Up, X, Lvl + 1);
  End;
  InsertInto := R;
End;

{ Ajouter l'entree EA (sans pointeur) au repertoire DirSec }
Function DirInsert(V, DirSec, EA : LongInt) : LongInt;
Var Dn, R, I : LongInt;
Begin
  KeyLen := RdB(EA + DE_NLEN);
  For I := 0 To KeyLen - 1 Do KeyBuf[I] := RdB(EA + DE_NAME + I);
  R := FindLeaf(V, DirSec, Dn);
  If R = NO_ERROR Then R := InsertInto(V, Dn, EA, 1);
  DirInsert := R;
End;

{ Operations sur un dnode en memoire }
Procedure DnRemove(D, Off : LongInt);
Var L, FF : LongInt;
Begin
  L := DeLen(D + Off);
  FF := RdL(D + 4);
  MoveB(D + Off + L, D + Off, FF - Off - L);
  FillB(D + FF - L, L, 0);
  WrL(D + 4, FF - L);
End;

Procedure DnClearDown(D, Off : LongInt);
Var E, L, FF : LongInt;
Begin
  E := D + Off;
  L := DeLen(E);
  FF := RdL(D + 4);
  MoveB(E + L, E + L - 4, FF - Off - L);
  WrL(D + FF - 4, 0);
  WrW(E, L - 4);
  WrB(E + DE_FLAGS, RdB(E + DE_FLAGS) And Not DF_DOWN);
  WrL(D + 4, FF - 4);
End;

Procedure DnAddDown(D, Off, Child : LongInt);
Var E, L, FF : LongInt;
Begin
  E := D + Off;
  L := DeLen(E);
  FF := RdL(D + 4);
  MoveB(E + L, E + L + 4, FF - Off - L);
  WrW(E, L + 4);
  WrB(E + DE_FLAGS, RdB(E + DE_FLAGS) Or DF_DOWN);
  WrL(E + L, Child);
  WrL(D + 4, FF + 4);
End;

{ Position de l'entree qui pointe vers Child dans le dnode D, ou -1 }
Function FindChildRef(D, Child : LongInt) : LongInt;
Var P, R : LongInt; Done : Boolean;
Begin
  R := -1;
  P := DN_HDR;
  Done := False;
  While Not Done Do
  Begin
    If (DeLen(D + P) < 32) Or (P + DeLen(D + P) > DNODE_SIZE) Then Done := True
    Else
    Begin
      If DeHasDown(D + P) And (DeDown(D + P) = Child) Then
      Begin
        R := P;
        Done := True;
      End
      Else If DeIsLast(D + P) Then Done := True
      Else P := P + DeLen(D + P);
    End;
  End;
  FindChildRef := R;
End;

{ Un dnode (non racine) qui ne contient plus que l'entree finale est
  retire de l'arbre ; on remonte tant que c'est le cas }
Function CheckEmpty(V, Dn : LongInt) : LongInt;
Var D, P, R, Pp, F, C : LongInt; Done : Boolean;
Begin
  R := NO_ERROR;
  D := LongInt(@DnBuf[8]);
  P := LongInt(@DnBuf[9]);
  Done := False;
  While Not Done Do
  Begin
    R := ReadDnode(V, Dn, D);
    If (R <> NO_ERROR) Or ((RdB(D + 8) And 1) <> 0) Or Not DeIsLast(D + DN_HDR) Then Done := True
    Else
    Begin
      Pp := RdL(D + 12);
      R := ReadDnode(V, Pp, P);
      If R = NO_ERROR Then
      Begin
        F := FindChildRef(P, Dn);
        If F < 0 Then R := ERROR_INVALID_DATA;
      End;
      If R <> NO_ERROR Then Done := True
      Else If DeHasDown(D + DN_HDR) Then
      Begin
        { un seul fils : le rattacher au parent }
        C := DeDown(D + DN_HDR);
        WrL(P + F + DeLen(P + F) - 4, C);
        R := WriteDnode(V, Pp, P);
        If R = NO_ERROR Then R := SetUp(V, C, Pp);
        FreeDnode(V, Dn);
        Done := True;
      End
      Else
      Begin
        DnClearDown(P, F);
        R := WriteDnode(V, Pp, P);
        FreeDnode(V, Dn);
        Dn := Pp;
        If R <> NO_ERROR Then Done := True;
      End;
    End;
  End;
  CheckEmpty := R;
End;

{ Plus grande entree du sous-arbre X : dnode dans MxDn, position dans
  MxOff, copie dans DeOut2 }
Function FindMax(V, X : LongInt) : Boolean;
Var D, P, Prev, Guard : LongInt; Found, Done : Boolean;
Begin
  Found := False;
  Done := False;
  D := LongInt(@DnBuf[2]);
  Guard := 0;
  While Not Done Do
  Begin
    Inc(Guard);
    If (Guard > 32) Or (ReadDnode(V, X, D) <> NO_ERROR) Then Done := True
    Else
    Begin
      P := DN_HDR; Prev := -1;
      While (Not DeIsLast(D + P)) And (DeLen(D + P) >= 32) And (P + DeLen(D + P) < DNODE_SIZE) Do
      Begin
        Prev := P;
        P := P + DeLen(D + P);
      End;
      If DeHasDown(D + P) Then X := DeDown(D + P)
      Else
      Begin
        If Prev >= 0 Then
        Begin
          Found := True;
          MxDn := X; MxOff := Prev;
          MoveB(D + Prev, LongInt(@DeOut2), DeLen(D + Prev));
        End;
        Done := True;
      End;
    End;
  End;
  FindMax := Found;
End;

{ Retirer du repertoire DirSec l'entree de nom KeyBuf }
Function DirDelete(V, DirSec : LongInt) : LongInt;
Var D, E, N, C, X, R, L, Dn : LongInt;
Begin
  If Not Lookup(V, DirSec) Then
  Begin
    DirDelete := ERROR_FILE_NOT_FOUND;
    Exit;
  End;
  D := LongInt(@DnBuf[0]);
  E := D + LkOff;
  Dn := LkDn;
  If Not DeHasDown(E) Then
  Begin
    DnRemove(D, LkOff);
    R := WriteDnode(V, Dn, D);
    If R = NO_ERROR Then R := CheckEmpty(V, Dn);
  End
  Else
  Begin
    C := DeDown(E);
    N := E + DeLen(E);
    If Not DeHasDown(N) Then
    Begin
      { l'entree suivante recoit le sous-arbre }
      DnRemove(D, LkOff);
      DnAddDown(D, LkOff, C);
      R := WriteDnode(V, Dn, D);
      If R = NO_ERROR Then R := CheckEmpty(V, Dn);
    End
    Else If Not FindMax(V, C) Then R := ERROR_INVALID_DATA
    Else
    Begin
      { remplacer par la plus grande entree du sous-arbre de gauche }
      D := LongInt(@DnBuf[2]);
      X := DeDown(D + MxOff);
      DnRemove(D, MxOff);
      If X <> 0 Then DnAddDown(D, MxOff, X);
      R := WriteDnode(V, MxDn, D);
      If R = NO_ERROR Then R := CheckEmpty(V, MxDn);
      If DeHasDown(LongInt(@DeOut2)) Then
      Begin
        L := DeLen(LongInt(@DeOut2)) - 4;
        WrW(LongInt(@DeOut2), L);
        WrB(LongInt(@DeOut2) + DE_FLAGS, RdB(LongInt(@DeOut2) + DE_FLAGS) And Not DF_DOWN);
      End;
      If (R = NO_ERROR) And Lookup(V, DirSec) Then
      Begin
        D := LongInt(@DnBuf[0]);
        E := D + LkOff;
        Dn := LkDn;
        If DeHasDown(E) Then
        Begin
          L := DeLen(LongInt(@DeOut2));
          WrL(LongInt(@DeOut2) + L, DeDown(E));
          WrW(LongInt(@DeOut2), L + 4);
          WrB(LongInt(@DeOut2) + DE_FLAGS, RdB(LongInt(@DeOut2) + DE_FLAGS) Or DF_DOWN);
        End;
        DnRemove(D, LkOff);
        R := WriteDnode(V, Dn, D);
        If R = NO_ERROR Then R := InsertInto(V, Dn, LongInt(@DeOut2), 1);
      End
      Else If R = NO_ERROR Then R := ERROR_INVALID_DATA;
    End;
  End;
  DirDelete := R;
End;

{ Entree qui suit la cle (Aa, Al) dans l'ordre des noms (toutes si
  HasAfter est faux) : copie dans DeOut ; vrai si trouvee }
Function SuccIn(V, Dn, Aa, Al : LongInt; HasAfter : Boolean; Lvl : LongInt) : Boolean;
Var D, P, E, C : LongInt; Found, Done : Boolean;
Begin
  Found := False;
  If (Lvl > 9) Then
  Begin
    SuccIn := False;
    Exit;
  End;
  D := LongInt(@DnBuf[Lvl]);
  If ReadDnode(V, Dn, D) = NO_ERROR Then
  Begin
    P := DN_HDR;
    Done := False;
    While Not Done Do
    Begin
      E := D + P;
      If (DeLen(E) < 32) Or (P + DeLen(E) > DNODE_SIZE) Then Done := True
      Else If DeIsLast(E) Then
      Begin
        If DeHasDown(E) Then Found := SuccIn(V, DeDown(E), Aa, Al, HasAfter, Lvl + 1);
        Done := True;
      End
      Else
      Begin
        If HasAfter Then C := CmpMem(E + DE_NAME, RdB(E + DE_NLEN), Aa, Al) Else C := 1;
        If C > 0 Then
        Begin
          If DeHasDown(E) Then Found := SuccIn(V, DeDown(E), Aa, Al, HasAfter, Lvl + 1);
          If Not Found Then
          Begin
            Found := True;
            MoveB(E, LongInt(@DeOut), DeLen(E));
          End;
          Done := True;
        End
        Else
          P := P + DeLen(E);
      End;
    End;
  End;
  SuccIn := Found;
End;

{ Entree suivant le nom After (chaine vide = premiere) du repertoire ;
  l'entree ^A^A est sautee }
Function DirNext(V, DirSec : LongInt; After : String) : Boolean;
Var Dn, I, L : LongInt; Found, Again : Boolean; Buf : Array[0..259] Of Byte;
Begin
  Found := False;
  If DirRoot(V, DirSec, Dn) = NO_ERROR Then
  Begin
    L := Length(After);
    For I := 1 To L Do Buf[I - 1] := Ord(After[I]);
    Again := True;
    While Again Do
    Begin
      Again := False;
      Found := SuccIn(V, Dn, LongInt(@Buf), L, L > 0, 1);
      If Found And ((DeOut[DE_FLAGS] And DF_FIRST) <> 0) Then
      Begin
        L := DeOut[DE_NLEN];
        For I := 0 To L - 1 Do Buf[I] := DeOut[DE_NAME + I];
        Again := True;
        Found := False;
      End;
    End;
  End;
  DirNext := Found;
End;

{ Nom de l'entree DeOut }
Function DeName(E : LongInt) : String;
Var S : String; I, L : LongInt;
Begin
  S := '';
  L := RdB(E + DE_NLEN);
  For I := 0 To L - 1 Do S := S + Chr(RdB(E + DE_NAME + I));
  DeName := S;
End;

{ Le repertoire est-il vide ? }
Function DirEmpty(V, DirSec : LongInt) : Boolean;
Begin
  DirEmpty := Not DirNext(V, DirSec, '');
End;

{ Liberer tous les dnodes d'un repertoire }
Procedure FreeDirTree(V, Dn, Lvl : LongInt);
Var D, P, E : LongInt; Done : Boolean;
Begin
  If Lvl > 9 Then Exit;
  D := LongInt(@DnBuf[Lvl]);
  If ReadDnode(V, Dn, D) = NO_ERROR Then
  Begin
    P := DN_HDR;
    Done := False;
    While Not Done Do
    Begin
      E := D + P;
      If (DeLen(E) < 32) Or (P + DeLen(E) > DNODE_SIZE) Then Done := True
      Else
      Begin
        If DeHasDown(E) Then FreeDirTree(V, DeDown(E), Lvl + 1);
        If DeIsLast(E) Then Done := True Else P := P + DeLen(E);
      End;
    End;
  End;
  FreeDnode(V, Dn);
End;

{ Mettre a jour l'entree de nom Name dans le repertoire DirSec :
  Mask 1 taille, 2 date d'ecriture, 4 date d'acces, 8 date de creation,
  16 attributs, 32 taille des EA et drapeaux EA }
Function DirUpdate(V, DirSec : LongInt; Name : String; Mask, Size, WDate, RDate, CDate, Attr, EaSize, EaFlags : LongInt) : LongInt;
Var D, E, R : LongInt;
Begin
  SetKey(Name);
  If Not Lookup(V, DirSec) Then R := ERROR_FILE_NOT_FOUND
  Else
  Begin
    D := LongInt(@DnBuf[0]);
    E := D + LkOff;
    If (Mask And 1) <> 0 Then WrL(E + DE_SIZE, Size);
    If (Mask And 2) <> 0 Then WrL(E + DE_WDATE, WDate);
    If (Mask And 4) <> 0 Then WrL(E + DE_RDATE, RDate);
    If (Mask And 8) <> 0 Then WrL(E + DE_CDATE, CDate);
    If (Mask And 16) <> 0 Then WrB(E + DE_ATTR, (RdB(E + DE_ATTR) And (ATTR_DIRECTORY Or ATTR_NOT8X3)) Or (Attr And $27));
    If (Mask And 32) <> 0 Then
    Begin
      WrL(E + DE_EASIZE, EaSize);
      WrB(E + DE_FLAGS, (RdB(E + DE_FLAGS) And Not (DF_HASEA Or DF_NEEDEA)) Or EaFlags);
    End;
    R := WriteDnode(V, LkDn, D);
    MoveB(E, LongInt(@DeOut), DeLen(E));
  End;
  DirUpdate := R;
End;

{ ==================================================================== }
{ Partie 9 - Chemins                                                   }
{ ==================================================================== }
{ Un chemin complet (D:\REP\NOM) est decoupe en composants (Comp) ; Walk
  parcourt les repertoires et laisse le repertoire parent du dernier
  composant dans WDir et son entree (si elle existe) dans DeOut. }

Function ParsePath(A : LongInt) : LongInt;
Var S, C : String; I, R : LongInt;
Begin
  R := NO_ERROR;
  S := GetStr(A);
  If (Length(S) >= 2) And (S[2] = ':') Then Delete(S, 1, 2);
  NComp := 0;
  C := '';
  For I := 1 To Length(S) + 1 Do
  Begin
    If (I > Length(S)) Or (S[I] = '\') Or (S[I] = '/') Then
    Begin
      If (C = '') Or (C = '.') Then
      Else If C = '..' Then
      Begin
        If NComp > 0 Then Dec(NComp);
      End
      Else If NComp >= 32 Then R := ERROR_FILENAME_EXCED_RANGE
      Else
      Begin
        PComp[NComp] := C;
        Inc(NComp);
      End;
      C := '';
    End
    Else
      C := C + S[I];
  End;
  ParsePath := R;
End;

Function LastComp : String;
Begin
  If NComp > 0 Then LastComp := PComp[NComp - 1] Else LastComp := '';
End;

{ Entree fictive de la racine dans DeOut }
Procedure RootDe(V : LongInt);
Begin
  BuildDe(LongInt(@DeOut), '', ATTR_DIRECTORY, Vols[V].Root, 0, 0, 0, 0);
  If ReadFnode(V, Vols[V].Root, LongInt(@DirFn)) = NO_ERROR Then;
End;

Function Walk(V, A : LongInt) : LongInt;
Var I, Dir, R : LongInt;
Begin
  R := ParsePath(A);
  Dir := Vols[V].Root;
  WFound := False;
  WIsRoot := False;
  I := 0;
  While (R = NO_ERROR) And (I < NComp - 1) Do
  Begin
    SetKey(PComp[I]);
    If HasWild(PComp[I]) Or Not Lookup(V, Dir) Then R := ERROR_PATH_NOT_FOUND
    Else If (DeOut[DE_ATTR] And ATTR_DIRECTORY) = 0 Then R := ERROR_PATH_NOT_FOUND
    Else Dir := RdL(LongInt(@DeOut) + DE_FNODE);
    Inc(I);
  End;
  WDir := Dir;
  If R = NO_ERROR Then
  Begin
    If NComp = 0 Then
    Begin
      WIsRoot := True;
      WFound := True;
      RootDe(V);
    End
    Else If Not HasWild(LastComp) Then
    Begin
      SetKey(LastComp);
      WFound := Lookup(V, Dir);
    End;
  End;
  Walk := R;
End;

{ ==================================================================== }
{ Partie 10 - Formatage, montage et verification                       }
{ ==================================================================== }
{ Disposition d'un volume formate par HPFS.IFS :
    0 amorce, 1-15 libres, 16 superbloc, 17 bloc de reserve,
    18-21 bitmap de la bande 0, 22-25 repertoire des bitmaps,
    26-29 liste des secteurs defectueux, 30-33 table de remplacement,
    34-35 pages de codes, 36-43 identificateurs, 44 fnode de la racine,
    45-48 bitmap de la bande des repertoires, 52.. bande des repertoires
    (le premier dnode est la racine) ; les bandes suivantes ont leur
    bitmap au debut (bande paire) ou a la fin (bande impaire). }

Function BandBitmapSec(B, TotSec : LongInt) : LongInt;
Var S : LongInt;
Begin
  If B = 0 Then S := 18
  Else If Odd(B) Then
  Begin
    S := B * BAND_SECS + BAND_SECS - 4;
    If S + 4 > TotSec Then S := TotSec - 4;
  End
  Else
    S := B * BAND_SECS;
  BandBitmapSec := S;
End;

Procedure PutAscii(A : LongInt; S : String);
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do WrB(A + I - 1, Ord(S[I]));
End;

{ Formater le volume V (TotSec deja connu) avec le nom Lbl }
Function FormatVol(V : LongInt; Lbl : String) : LongInt;
Var Tot, NB, NDir, DirStart, DirEnd, B, I, S, R, A, Bit, Used, Now, Serial, MaxDir : LongInt;
Begin
  R := NO_ERROR;
  Tot := Vols[V].TotSec;
  If Tot < 1024 Then
  Begin
    FormatVol := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  NB := (Tot + BAND_SECS - 1) Div BAND_SECS;
  { une derniere bande trop petite pour sa bitmap est abandonnee }
  If (NB > 1) And (Tot - (NB - 1) * BAND_SECS < 64) Then
  Begin
    Dec(NB);
    Tot := NB * BAND_SECS;
  End;
  If NB > MaxBands Then
  Begin
    NB := MaxBands;
    Tot := NB * BAND_SECS;
  End;
  Vols[V].TotSec := Tot;
  Vols[V].NBands := NB;
  NDir := Tot Div 512;
  If NDir < 16 Then NDir := 16;
  MaxDir := (Min(Tot, BAND_SECS) - 64) Div 8;
  If NDir > MaxDir Then NDir := MaxDir;
  If NDir > 2000 Then NDir := 2000;
  DirStart := 52;
  DirEnd := DirStart + NDir * 4 - 1;
  Vols[V].Root := 44;
  Vols[V].DirStart := DirStart;
  Vols[V].DirEnd := DirEnd;
  Vols[V].DirBmp := 45;
  Now := NowUnix;
  Serial := (Now Xor (Tot * 40503)) And $7FFFFFFF;
  Vols[V].Serial := Serial;
  CacheDropVol(V);
  { zone systeme }
  FillB(LongInt(@ZeroBuf), 512, 0);
  For S := 0 To DirStart - 1 Do
    If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, S, 1, LongInt(@ZeroBuf));
  { bitmaps des bandes }
  For B := 0 To NB - 1 Do
  Begin
    BandTab[V * MaxBands + B] := BandBitmapSec(B, Tot);
    FillB(LongInt(@BmpBuf), 2048, 0);
    For I := 0 To BAND_SECS - 1 Do
    Begin
      S := B * BAND_SECS + I;
      Used := 0;
      If (S >= Tot) Or (S <= 48) Or ((S >= DirStart) And (S <= DirEnd)) Then Used := 1
      Else If (S >= BandBitmapSec(B, Tot)) And (S < BandBitmapSec(B, Tot) + 4) Then Used := 1;
      If Used = 0 Then BmpBuf[I Shr 3] := BmpBuf[I Shr 3] Or (1 Shl (I And 7));
    End;
    If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, BandBitmapSec(B, Tot), 4, LongInt(@BmpBuf));
  End;
  BmpVol := -1;
  { repertoire des bitmaps }
  FillB(LongInt(@BmpBuf), 2048, 0);
  For B := 0 To NB - 1 Do WrL(LongInt(@BmpBuf) + B * 4, BandTab[V * MaxBands + B]);
  If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, 22, 4, LongInt(@BmpBuf));
  { bitmap de la bande des repertoires : dnode 0 (racine) occupe }
  FillB(LongInt(@DbBuf), 2048, 0);
  For I := 1 To NDir - 1 Do DbBuf[I Shr 3] := DbBuf[I Shr 3] Or (1 Shl (I And 7));
  If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, 45, 4, LongInt(@DbBuf));
  DbVol := -1;
  { pages de codes (850) }
  A := LongInt(@SecBuf);
  FillB(A, 512, 0);
  WrL(A, CPDIR_MAGIC);
  WrL(A + 4, 1);
  WrW(A + 18, 850);
  WrL(A + 24, 35);
  If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, 34, 1, A);
  FillB(A, 512, 0);
  WrL(A, CPDATA_MAGIC);
  WrL(A + 4, 1);
  WrW(A + 20, 26);
  WrW(A + 28, 850);
  For I := 0 To 127 Do WrB(A + 32 + I, Upper[128 + I]);
  If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, 35, 1, A);
  { superbloc }
  FillB(A, 512, 0);
  WrL(A, SB_MAGIC);
  WrL(A + 4, SB_MAGIC1);
  WrB(A + 8, 2);
  WrB(A + 9, 2);
  WrL(A + 12, 44);
  WrL(A + 16, Tot);
  WrL(A + 24, 22);
  WrL(A + 32, 26);
  WrL(A + 48, NDir * 4);
  WrL(A + 52, DirStart);
  WrL(A + 56, DirEnd);
  WrL(A + 60, 45);
  WrL(A + 96, 36);
  If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, 16, 1, A);
  { bloc de reserve }
  FillB(A, 512, 0);
  WrL(A, SP_MAGIC);
  WrL(A + 4, SP_MAGIC1);
  WrL(A + 12, 30);
  WrL(A + 32, 34);
  WrL(A + 36, 1);
  If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, 17, 1, A);
  { fnode et dnode de la racine }
  BuildFnode(LongInt(@FnBuf), 44, '', True);
  WrB(LongInt(@FnBuf) + FN_BTREE + 4, 7);
  WrB(LongInt(@FnBuf) + FN_BTREE + 5, 1);
  WrW(LongInt(@FnBuf) + FN_BTREE + 6, 20);
  WrL(LongInt(@FnBuf) + FN_BTREE + 8, 0);
  WrL(LongInt(@FnBuf) + FN_BTREE + 12, 4);
  WrL(LongInt(@FnBuf) + FN_BTREE + 16, DirStart);
  If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, 44, 1, LongInt(@FnBuf));
  A := LongInt(@DnBuf[0]);
  InitDnode(A, DirStart, 44, True);
  I := DN_HDR + BuildDe(A + DN_HDR, #1#1, ATTR_DIRECTORY, 44, 0, Now, Now, Now);
  WrB(A + DN_HDR + DE_FLAGS, DF_FIRST);
  I := I + BuildLast(A + I, 0);
  WrL(A + 4, I);
  If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, DirStart, 4, A);
  { secteur d'amorce }
  A := LongInt(@SecBuf);
  FillB(A, 512, 0);
  WrB(A, $EB); WrB(A + 1, $3C); WrB(A + 2, $90);
  PutAscii(A + 3, 'OS2-0 20');
  WrW(A + 11, 512);
  WrB(A + 13, 1);
  If Tot < 65536 Then WrW(A + 19, Tot) Else WrL(A + 32, Tot);
  WrB(A + 21, $F8);
  WrW(A + 24, 63);
  WrW(A + 26, 16);
  WrB(A + 36, $80);
  WrB(A + 38, $28);
  WrL(A + 39, Serial);
  For I := 0 To 10 Do WrB(A + 43 + I, 32);
  PutAscii(A + 43, Copy(UpStr(Lbl), 1, 11));
  PutAscii(A + 54, 'HPFS    ');
  { code : afficher un message et s'arreter }
  PutAscii(A + $3E, #$31#$C0#$8E#$D8#$BE#$5A#$7C#$AC#$0A#$C0#$74#$09#$B4#$0E#$BB#$07#$00#$CD#$10#$EB#$F2#$F4#$EB#$FD);
  PutAscii(A + $5A, 'Volume HPFS de OS/2-0 non amorcable.');
  WrB(A + $5A + 36, 13); WrB(A + $5A + 37, 10);
  WrW(A + 510, $AA55);
  If R = NO_ERROR Then R := DevIO(V, DVIO_OPWRITE, 0, 1, A);
  CacheDropVol(V);
  FormatVol := R;
End;

{ Reconnaitre le volume V (secteur d'amorce en Boot) et charger ses
  parametres ; rend NO_ERROR si c'est un volume HPFS }
Function MountVol(V, Boot : LongInt) : LongInt;
Var A, R, N, I, Tot : LongInt; S : String;
Begin
  R := NO_ERROR;
  S := '';
  For I := 0 To 7 Do S := S + Chr(RdB(Boot + 54 + I));
  If (RdW(Boot + 510) <> $AA55) Or (S <> 'HPFS    ') Then R := ERROR_NOT_DOS_DISK;
  A := LongInt(@SecBuf);
  If R = NO_ERROR Then R := DevIO(V, DVIO_OPREAD, 16, 1, A);
  If (R = NO_ERROR) And (RdL(A) <> SB_MAGIC) Then R := ERROR_NOT_DOS_DISK;
  If R = NO_ERROR Then
  Begin
    Tot := RdL(A + 16);
    If (Tot > 0) And (Tot < Vols[V].TotSec) Then Vols[V].TotSec := Tot;
    Vols[V].Root := RdL(A + 12);
    Vols[V].DirStart := RdL(A + 52);
    Vols[V].DirEnd := RdL(A + 56);
    Vols[V].DirBmp := RdL(A + 60);
    Vols[V].NBands := (Vols[V].TotSec + BAND_SECS - 1) Div BAND_SECS;
    If Vols[V].NBands > MaxBands Then R := ERROR_NOT_SUPPORTED;
    N := RdL(A + 24);
    If R = NO_ERROR Then R := DevIO(V, DVIO_OPREAD, N, 4, LongInt(@BmpBuf));
    If R = NO_ERROR Then
      For I := 0 To Vols[V].NBands - 1 Do BandTab[V * MaxBands + I] := RdL(LongInt(@BmpBuf) + I * 4);
    BmpVol := -1;
  End;
  If R = NO_ERROR Then
  Begin
    R := DevIO(V, DVIO_OPREAD, 17, 1, A);
    If (R = NO_ERROR) And (RdL(A) <> SP_MAGIC) Then R := ERROR_NOT_DOS_DISK;
    If R = NO_ERROR Then Vols[V].WasDirty := (RdB(A + 8) And 1) <> 0;
  End;
  If R = NO_ERROR Then
  Begin
    CacheDropVol(V);
    If ReadFnode(V, Vols[V].Root, LongInt(@FnBuf)) <> NO_ERROR Then R := ERROR_NOT_DOS_DISK;
  End;
  If R = NO_ERROR Then
  Begin
    Vols[V].Serial := RdL(Boot + 39);
    Vols[V].Mounted := True;
    Vols[V].Dirty := False;
    Vols[V].FreeSecs := CountFree(V);
  End;
  MountVol := R;
End;

{ Nom de volume (11 caracteres au plus, sans les espaces de fin) }
Function GetLabel(V : LongInt) : String;
Var S : String; I : LongInt;
Begin
  S := '';
  If DevIO(V, DVIO_OPREAD, 0, 1, LongInt(@SecBuf)) = NO_ERROR Then
    For I := 0 To 10 Do S := S + Chr(SecBuf[43 + I]);
  While (Length(S) > 0) And ((S[Length(S)] = ' ') Or (S[Length(S)] = #0)) Do Delete(S, Length(S), 1);
  GetLabel := S;
End;

Function SetLabel(V : LongInt; S : String) : LongInt;
Var I, R : LongInt;
Begin
  R := DevIO(V, DVIO_OPREAD, 0, 1, LongInt(@SecBuf));
  If R = NO_ERROR Then
  Begin
    S := UpStr(Copy(S, 1, 11));
    For I := 0 To 10 Do
      If I < Length(S) Then SecBuf[43 + I] := Ord(S[I + 1]) Else SecBuf[43 + I] := 32;
    MarkDirty(V);
    R := DevIO(V, DVIO_OPWRITE, 0, 1, LongInt(@SecBuf));
  End;
  SetLabel := R;
End;

{ --- verification (CHKDSK) --- }
{ Une carte des secteurs references est construite en parcourant toute
  l'arborescence, puis comparee aux bitmaps ; Fix corrige les bitmaps. }

Procedure ChkMark(S, N : LongInt);
Var I, B, A : LongInt;
Begin
  For I := 0 To N - 1 Do
  Begin
    B := S + I;
    If (B < 0) Or (ChkMap = 0) Then Inc(ChkErrors)
    Else
    Begin
      A := ChkMap + (B Shr 3);
      If (RdB(A) And (1 Shl (B And 7))) <> 0 Then Inc(ChkErrors)   { secteur partage }
      Else WrB(A, RdB(A) Or (1 Shl (B And 7)));
    End;
  End;
End;

Procedure ChkDnodes(V, Dn, Lvl : LongInt);
Var D, P, E : LongInt; Done : Boolean;
Begin
  If Lvl > 9 Then
  Begin
    Inc(ChkErrors);
    Exit;
  End;
  D := LongInt(@DnBuf[Lvl]);
  If ReadDnode(V, Dn, D) <> NO_ERROR Then
  Begin
    Inc(ChkErrors);
    Exit;
  End;
  Inc(ChkDnCount);
  If (Dn >= Vols[V].DirStart) And (Dn <= Vols[V].DirEnd) Then
  Begin
    If LoadDirBmp(V) = NO_ERROR Then
      If (DbBuf[((Dn - Vols[V].DirStart) Div 4) Shr 3] And (1 Shl (((Dn - Vols[V].DirStart) Div 4) And 7))) <> 0 Then
        Inc(ChkErrors);
  End
  Else
    ChkMark(Dn, 4);
  P := DN_HDR;
  Done := False;
  While Not Done Do
  Begin
    E := D + P;
    If (DeLen(E) < 32) Or (P + DeLen(E) > DNODE_SIZE) Then
    Begin
      Inc(ChkErrors);
      Done := True;
    End
    Else
    Begin
      If DeHasDown(E) Then
      Begin
        ChkDnodes(V, DeDown(E), Lvl + 1);
        ReadDnode(V, Dn, D);
      End;
      If DeIsLast(E) Then Done := True Else P := P + DeLen(E);
    End;
  End;
End;

Procedure ChkFnode(V, FnSec, Up : LongInt; IsDir : Boolean; Size, Depth : LongInt);
Var Fn, I, L, Dn : LongInt; Last : String; More : Boolean;
Begin
  If Depth > 30 Then Exit;
  Fn := LongInt(@FnBuf2);
  If ReadFnode(V, FnSec, Fn) <> NO_ERROR Then
  Begin
    Inc(ChkErrors);
    Exit;
  End;
  ChkMark(FnSec, 1);
  If (FnSec <> Vols[V].Root) And (RdL(Fn + FN_UP) <> Up) Then Inc(ChkErrors);
  L := RdL(Fn + FN_EASIZEL);
  If (L > 0) And ((RdW(Fn + FN_FLAGS) And FNF_EAANODE) = 0) Then
  Begin
    ChkMark(RdL(Fn + FN_EASEC), (L + 511) Div 512);
    Inc(ChkEa);
  End;
  If RdW(Fn + FN_EASIZES) > 0 Then Inc(ChkEa);
  If IsDir Then
  Begin
    Inc(ChkDirs);
    Dn := RdL(Fn + FN_BTREE + 16);
    ChkDnodes(V, Dn, 1);
    Last := '';
    More := True;
    While More Do
    Begin
      More := DirNext(V, FnSec, Last);
      If More Then
      Begin
        Last := DeName(LongInt(@DeOut));
        ChkFnode(V, RdL(LongInt(@DeOut) + DE_FNODE), FnSec,
                 (DeOut[DE_ATTR] And ATTR_DIRECTORY) <> 0, RdL(LongInt(@DeOut) + DE_SIZE), Depth + 1);
      End;
    End;
  End
  Else
  Begin
    Inc(ChkFiles);
    ExtVol := -1;
    If LoadExtents(V, FnSec, Fn) <> NO_ERROR Then Inc(ChkErrors)
    Else
    Begin
      For I := 0 To ExtN - 1 Do
      Begin
        ChkMark(ExtD[I], ExtL[I]);
        ChkUsed := ChkUsed + ExtL[I];
      End;
      For I := 0 To AnN - 1 Do ChkMark(AnList[I], 1);
      If AllocatedSecs * 512 < Size Then Inc(ChkErrors);
    End;
    ExtVol := -1;
  End;
End;

{ Verifier le volume ; Fix : corriger les bitmaps. Rend le nombre de
  secteurs perdus (occupes mais non references) dans Lost. }
Function CheckVol(V : LongInt; Fix : Boolean; Var Lost : LongInt) : LongInt;
Var Heap, Size, I, S, B, A : LongInt; InMap, Used : Boolean;
Begin
  ChkErrors := 0; ChkDirs := 0; ChkFiles := 0; ChkUsed := 0; ChkDnCount := 0; ChkEa := 0;
  Lost := 0;
  Size := Vols[V].TotSec Div 8 + 16;
  Heap := KGetProcessHeap;
  ChkMap := KHeapAlloc(Heap, 8, Size);
  If ChkMap = 0 Then
  Begin
    CheckVol := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  FillB(ChkMap, Size, 0);
  { structures systeme : amorce, superbloc, bloc de reserve, bitmaps,
    listes, pages de codes, identificateurs, bande des repertoires }
  ChkMark(0, 18);
  For B := 0 To Vols[V].NBands - 1 Do ChkMark(BandTab[V * MaxBands + B], 4);
  ChkMark(Vols[V].DirStart, Vols[V].DirEnd - Vols[V].DirStart + 1);
  ChkMark(Vols[V].DirBmp, 4);
  A := LongInt(@SecBuf);
  If DevIO(V, DVIO_OPREAD, 16, 1, A) = NO_ERROR Then
  Begin
    ChkMark(RdL(A + 24), 4);
    If RdL(A + 32) <> 0 Then ChkMark(RdL(A + 32), 4);
    If RdL(A + 96) <> 0 Then ChkMark(RdL(A + 96), 8);
  End;
  If DevIO(V, DVIO_OPREAD, 17, 1, A) = NO_ERROR Then
  Begin
    If RdL(A + 12) <> 0 Then ChkMark(RdL(A + 12), 4);
    For I := 0 To RdL(A + 28) - 1 Do
      If I < 100 Then ChkMark(RdL(A + 108 + I * 4), 4);
    S := RdL(A + 32);
    If S <> 0 Then
    Begin
      ChkMark(S, 1);
      If DevIO(V, DVIO_OPREAD, S, 1, A) = NO_ERROR Then
        For I := 0 To RdL(A + 4) - 1 Do
          If I < 31 Then ChkMark(RdL(A + 24 + I * 16), 1);
    End;
  End;
  ChkFnode(V, Vols[V].Root, Vols[V].Root, True, 0, 0);
  { comparer aux bitmaps }
  For S := 0 To Vols[V].TotSec - 1 Do
  Begin
    A := ChkMap + (S Shr 3);
    InMap := (RdB(A) And (1 Shl (S And 7))) <> 0;
    Used := Not SecFree(V, S);
    If Used And Not InMap Then
    Begin
      Inc(Lost);
      If Fix Then MarkSecs(V, S, 1, True);
    End
    Else If InMap And Not Used Then
    Begin
      Inc(ChkErrors);
      If Fix Then MarkSecs(V, S, 1, False);
    End;
  End;
  KHeapFree(Heap, 0, ChkMap);
  ChkMap := 0;
  If Fix Then
  Begin
    Vols[V].Dirty := True;
    FlushVol(V);
    Vols[V].WasDirty := False;
  End;
  I := NO_ERROR;
  CheckVol := I;
End;

{ ==================================================================== }
{ Partie 11 - Objets fichiers, ouvertures, verrous et notifications    }
{ ==================================================================== }
{ Un objet represente un fichier ouvert (un fnode) ; chaque ouverture
  (SFT du noyau) le designe par sa zone SFFSD :
    +0 numero d'ouverture + 1   +4 signature 'HPFS'   +8 fnode }

Const
  SFD_MAGIC = $53465048;     { 'HPFS' }

Function ObjFind(V, Fnode : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxObj - 1 Do
    If Objs[I].Used And (Objs[I].Vol = V) And (Objs[I].Fnode = Fnode) Then R := I;
  ObjFind := R;
End;

{ Objet du fichier decrit par l'entree DeOut du repertoire Dir }
Function ObjGet(V, Dir : LongInt) : LongInt;
Var I, R, Fn : LongInt;
Begin
  Fn := RdL(LongInt(@DeOut) + DE_FNODE);
  R := ObjFind(V, Fn);
  If R < 0 Then
  Begin
    For I := MaxObj - 1 DownTo 0 Do
      If Not Objs[I].Used Then R := I;
    If R >= 0 Then
    Begin
      Objs[R].Used := True;
      Objs[R].Vol := V;
      Objs[R].Fnode := Fn;
      Objs[R].Dir := Dir;
      Objs[R].Name := DeName(LongInt(@DeOut));
      Objs[R].Size := RdL(LongInt(@DeOut) + DE_SIZE);
      Objs[R].Attr := DeOut[DE_ATTR];
      Objs[R].CTime := RdL(LongInt(@DeOut) + DE_CDATE);
      Objs[R].ATime := RdL(LongInt(@DeOut) + DE_RDATE);
      Objs[R].MTime := RdL(LongInt(@DeOut) + DE_WDATE);
      Objs[R].Refs := 0;
      Objs[R].Dirty := False;
      Objs[R].Swap := False;
    End;
  End;
  If R >= 0 Then Inc(Objs[R].Refs);
  ObjGet := R;
End;

{ Ecrire la taille et les dates de l'objet dans son fnode et son entree }
Function ObjSync(O : LongInt) : LongInt;
Var V, R : LongInt;
Begin
  R := NO_ERROR;
  If Objs[O].Used And Objs[O].Dirty Then
  Begin
    V := Objs[O].Vol;
    R := ReadFnode(V, Objs[O].Fnode, LongInt(@FnBuf2));
    If R = NO_ERROR Then
    Begin
      WrL(LongInt(@FnBuf2) + FN_FSIZE, Objs[O].Size);
      R := WriteFnode(V, Objs[O].Fnode, LongInt(@FnBuf2));
    End;
    If R = NO_ERROR Then
      R := DirUpdate(V, Objs[O].Dir, Objs[O].Name, 1 + 2 + 4 + 16, Objs[O].Size, Objs[O].MTime,
                     Objs[O].ATime, 0, Objs[O].Attr, 0, 0);
    If R = NO_ERROR Then Objs[O].Dirty := False;
  End;
  ObjSync := R;
End;

Procedure ObjRelease(O : LongInt);
Var I : LongInt;
Begin
  If (O < 0) Or (O >= MaxObj) Then Exit;
  If Not Objs[O].Used Then Exit;
  Dec(Objs[O].Refs);
  If Objs[O].Refs <= 0 Then
  Begin
    ObjSync(O);
    Objs[O].Used := False;
    For I := 0 To MaxLock - 1 Do
      If Locks[I].Used And (Locks[I].Obj = O) Then Locks[I].Used := False;
  End;
End;

{ Fichier en cours d'utilisation ? }
Function InUse(V, Fnode : LongInt) : Boolean;
Begin
  InUse := ObjFind(V, Fnode) >= 0;
End;

{ Acces : 0 lecture, 1 ecriture, 2 les deux ; partage : 1 refus total,
  2 refus d'ecriture, 3 refus de lecture, 4 (ou 0) aucun refus }
Function WantsRead(Mode : LongInt) : Boolean;
Begin
  WantsRead := ((Mode And 7) = 0) Or ((Mode And 7) = 2);
End;

Function WantsWrite(Mode : LongInt) : Boolean;
Begin
  WantsWrite := ((Mode And 7) = 1) Or ((Mode And 7) = 2);
End;

Function DeniesRead(Mode : LongInt) : Boolean;
Begin
  DeniesRead := (((Mode Shr 4) And 7) = 1) Or (((Mode Shr 4) And 7) = 3);
End;

Function DeniesWrite(Mode : LongInt) : Boolean;
Begin
  DeniesWrite := (((Mode Shr 4) And 7) = 1) Or (((Mode Shr 4) And 7) = 2);
End;

{ Nouvelle ouverture de l'objet O ; rend son numero ou -1 (LastErr) }
Function OpenNew(O, Mode, Sffsi : LongInt) : LongInt;
Var I, R, M : LongInt;
Begin
  R := -1;
  LastErr := NO_ERROR;
  For I := 0 To MaxOpen - 1 Do
    If Opens[I].Used And (Opens[I].Obj = O) Then
    Begin
      M := Opens[I].Mode;
      If (WantsRead(Mode) And DeniesRead(M)) Or (WantsWrite(Mode) And DeniesWrite(M)) Or
         (WantsRead(M) And DeniesRead(Mode)) Or (WantsWrite(M) And DeniesWrite(Mode)) Then
        LastErr := ERROR_SHARING_VIOLATION;
    End;
  If LastErr = NO_ERROR Then
  Begin
    For I := MaxOpen - 1 DownTo 0 Do
      If Not Opens[I].Used Then R := I;
    If R < 0 Then LastErr := ERROR_TOO_MANY_OPEN_FILES
    Else
    Begin
      Opens[R].Used := True;
      Opens[R].Obj := O;
      Opens[R].Mode := Mode;
      Opens[R].Sffsi := Sffsi;
      Opens[R].Pid := RdL(Sffsi + 32);
    End;
  End;
  OpenNew := R;
End;

{ Ouverture designee par la zone SFFSD, ou -1 }
Function OpenOf(Sffsd : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  If Sffsd <> 0 Then
    If RdL(Sffsd + 4) = SFD_MAGIC Then
    Begin
      I := RdL(Sffsd) - 1;
      If (I >= 0) And (I < MaxOpen) Then
        If Opens[I].Used Then R := I;
    End;
  OpenOf := R;
End;

{ Verrous : la plage [Ofs, Ofs+Len) chevauche-t-elle un verrou pose par
  une autre ouverture ? Exclusive : acces en ecriture ou verrou exclusif
  (sinon seuls les verrous exclusifs des autres genent) }
Function LockConflict(O, Owner, Ofs, Len : LongInt; Exclusive : Boolean) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := False;
  If Len > 0 Then
    For I := 0 To MaxLock - 1 Do
      If Locks[I].Used And (Locks[I].Obj = O) And (Locks[I].Owner <> Owner) Then
        If (Ofs < Locks[I].Ofs + Locks[I].Len) And (Locks[I].Ofs < Ofs + Len) Then
          If Exclusive Or Not Locks[I].Shared Then R := True;
  LockConflict := R;
End;

{ Journal des modifications (DosFindNotify) }
Procedure LogChange(V, Dir, Action : LongInt; Name : String);
Var I : LongInt;
Begin
  I := LogCount Mod MaxLog;
  ChgLog[I].Vol := V;
  ChgLog[I].Dir := Dir;
  ChgLog[I].Action := Action;
  ChgLog[I].Name := Name;
  Inc(LogCount);
End;

{ ==================================================================== }
{ Partie 12 - Lecture et ecriture des donnees                          }
{ ==================================================================== }

{ Charger le fnode (dans FnBuf) et les extensions de l'objet O }
Function ObjLoad(O : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := ReadFnode(Objs[O].Vol, Objs[O].Fnode, LongInt(@FnBuf));
  If R = NO_ERROR Then R := LoadExtents(Objs[O].Vol, Objs[O].Fnode, LongInt(@FnBuf));
  ObjLoad := R;
End;

Function ReadData(O, FPos, Buf, N : LongInt; Var Got : LongInt) : LongInt;
Var V, R, Sec, Ofs, Run, Disk, K, Chunk : LongInt;
Begin
  Got := 0;
  R := NO_ERROR;
  V := Objs[O].Vol;
  If FPos >= Objs[O].Size Then N := 0
  Else If FPos + N > Objs[O].Size Then N := Objs[O].Size - FPos;
  If N > 0 Then R := ObjLoad(O);
  While (Got < N) And (R = NO_ERROR) Do
  Begin
    Sec := (FPos + Got) Div 512;
    Ofs := (FPos + Got) Mod 512;
    Disk := MapSec(Sec, Run);
    If Disk = 0 Then R := ERROR_READ_FAULT
    Else If (Ofs = 0) And (N - Got >= 512) Then
    Begin
      K := (N - Got) Div 512;
      If K > Run Then K := Run;
      R := DataRead(V, Disk, K, Buf + Got);
      If R = NO_ERROR Then Got := Got + K * 512;
    End
    Else
    Begin
      R := DataRead(V, Disk, 1, LongInt(@SecBuf));
      Chunk := 512 - Ofs;
      If Chunk > N - Got Then Chunk := N - Got;
      If R = NO_ERROR Then
      Begin
        MoveB(LongInt(@SecBuf) + Ofs, Buf + Got, Chunk);
        Got := Got + Chunk;
      End;
    End;
  End;
  ReadData := R;
End;

{ Ecrire Len octets de Src a la position FPos du fichier (allocation deja
  faite) ; Src = 0 : ecrire des zeros }
Function PutData(O, FPos, Src, Len : LongInt) : LongInt;
Var V, R, Done, Sec, Ofs, Run, Disk, K, Chunk, I : LongInt;
Begin
  R := NO_ERROR;
  V := Objs[O].Vol;
  Done := 0;
  While (Done < Len) And (R = NO_ERROR) Do
  Begin
    Sec := (FPos + Done) Div 512;
    Ofs := (FPos + Done) Mod 512;
    Disk := MapSec(Sec, Run);
    If Disk = 0 Then R := ERROR_WRITE_FAULT
    Else If (Ofs = 0) And (Len - Done >= 512) Then
    Begin
      K := (Len - Done) Div 512;
      If K > Run Then K := Run;
      If Src <> 0 Then
      Begin
        R := DataWrite(V, Disk, K, Src + Done);
        If R = NO_ERROR Then Done := Done + K * 512;
      End
      Else
      Begin
        FillB(LongInt(@ZeroBuf), 512, 0);
        For I := 0 To K - 1 Do
          If R = NO_ERROR Then R := DataWrite(V, Disk + I, 1, LongInt(@ZeroBuf));
        If R = NO_ERROR Then Done := Done + K * 512;
      End;
    End
    Else
    Begin
      { secteur partiel : lecture, modification, ecriture }
      If Sec * 512 < Objs[O].Size Then R := DataRead(V, Disk, 1, LongInt(@SecBuf))
      Else FillB(LongInt(@SecBuf), 512, 0);
      Chunk := 512 - Ofs;
      If Chunk > Len - Done Then Chunk := Len - Done;
      If Src <> 0 Then MoveB(Src + Done, LongInt(@SecBuf) + Ofs, Chunk)
      Else FillB(LongInt(@SecBuf) + Ofs, Chunk, 0);
      If R = NO_ERROR Then R := DataWrite(V, Disk, 1, LongInt(@SecBuf));
      If R = NO_ERROR Then Done := Done + Chunk;
    End;
  End;
  PutData := R;
End;

{ Allouer jusqu'a la taille NewSize (octets) ; ecrit le fnode }
Function ObjReserve(O, NewSize : LongInt) : LongInt;
Var R, R2, Need : LongInt;
Begin
  R := ObjLoad(O);
  Need := (NewSize + 511) Div 512;
  If (R = NO_ERROR) And (Need > AllocatedSecs) Then
  Begin
    R := GrowTo(Objs[O].Vol, Objs[O].Fnode, LongInt(@FnBuf), Need);
    R2 := WriteFnode(Objs[O].Vol, Objs[O].Fnode, LongInt(@FnBuf));
    If R = NO_ERROR Then R := R2;
  End;
  ObjReserve := R;
End;

Function WriteData(O, FPos, Buf, N : LongInt; Var Done : LongInt) : LongInt;
Var R, Room, OldSize : LongInt;
Begin
  Done := 0;
  R := NO_ERROR;
  If N > 0 Then
  Begin
    R := ObjReserve(O, FPos + N);
    If R = ERROR_DISK_FULL Then
    Begin
      { ecrire ce qui tient }
      Room := AllocatedSecs * 512 - FPos;
      If Room > 0 Then
      Begin
        N := Room;
        R := NO_ERROR;
      End;
    End;
    OldSize := Objs[O].Size;
    If (R = NO_ERROR) And (FPos > OldSize) Then
      R := PutData(O, OldSize, 0, FPos - OldSize);
    If R = NO_ERROR Then R := PutData(O, FPos, Buf, N);
    If R = NO_ERROR Then
    Begin
      Done := N;
      If FPos + N > Objs[O].Size Then Objs[O].Size := FPos + N;
      Objs[O].MTime := NowUnix;
      Objs[O].Attr := Objs[O].Attr Or ATTR_ARCHIVE;
      Objs[O].Dirty := True;
    End;
  End;
  WriteData := R;
End;

{ Changer la taille du fichier }
Function SetSize(O, NewSize : LongInt) : LongInt;
Var R, R2, V : LongInt;
Begin
  V := Objs[O].Vol;
  If NewSize < 0 Then R := ERROR_INVALID_PARAMETER
  Else If NewSize < Objs[O].Size Then
  Begin
    R := ObjLoad(O);
    If R = NO_ERROR Then
    Begin
      R := ShrinkTo(V, Objs[O].Fnode, LongInt(@FnBuf), (NewSize + 511) Div 512);
      WrL(LongInt(@FnBuf) + FN_FSIZE, NewSize);
      R2 := WriteFnode(V, Objs[O].Fnode, LongInt(@FnBuf));
      If R = NO_ERROR Then R := R2;
    End;
    If R = NO_ERROR Then Objs[O].Size := NewSize;
  End
  Else If NewSize > Objs[O].Size Then
  Begin
    R := ObjReserve(O, NewSize);
    If R = NO_ERROR Then R := PutData(O, Objs[O].Size, 0, NewSize - Objs[O].Size);
    If R = NO_ERROR Then Objs[O].Size := NewSize;
  End
  Else
    R := NO_ERROR;
  If R = NO_ERROR Then
  Begin
    Objs[O].MTime := NowUnix;
    Objs[O].Dirty := True;
  End;
  SetSize := R;
End;

{ ==================================================================== }
{ Partie 13 - Points d'entree FS_*                                     }
{ ==================================================================== }

{ --- utilitaires communs --- }

{ Volume d'une operation sur un chemin : hVPB du CDFSI, sinon la lettre
  d'unite du chemin }
Function VolOf(Pcdfsi, PName : LongInt) : LongInt;
Var V, I, D : LongInt;
Begin
  V := -1;
  If Pcdfsi <> 0 Then V := MVol(RdL(Pcdfsi));
  If (V < 0) And (PName <> 0) Then
    If RdB(PName + 1) = 58 Then
    Begin
      D := Upper[RdB(PName)] - 65;
      For I := 0 To MaxVol - 1 Do
        If Vols[I].Used And Vols[I].Mounted And (Vols[I].Drive = D) Then V := I;
    End;
  VolOf := V;
End;

Procedure PutDT(A, T : LongInt);
Var D : LongInt;
Begin
  D := UnixToDos(T);
  WrW(A, (D Shr 16) And $FFFF);
  WrW(A + 2, D And $FFFF);
End;

{ Date et heure (FDATE, FTIME) en A -> secondes, ou -1 si nulles }
Function GetDT(A : LongInt) : LongInt;
Begin
  If (RdW(A) = 0) And (RdW(A + 2) = 0) Then GetDT := -1
  Else GetDT := DosToUnix((RdW(A) Shl 16) Or RdW(A + 2));
End;

{ FILESTATUS3 (niveau 1, 24 octets) ou FILESTATUS4 (niveau 2, 28) }
Function PutStatus(A, Cb, Level, Attr, Size, C, Ac, M, CbList : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If (Level = 1) And (Cb < 24) Then R := ERROR_BUFFER_OVERFLOW
  Else If (Level = 2) And (Cb < 28) Then R := ERROR_BUFFER_OVERFLOW
  Else
  Begin
    PutDT(A, C);
    PutDT(A + 4, Ac);
    PutDT(A + 8, M);
    WrL(A + 12, Size);
    WrL(A + 16, ((Size + 511) Div 512) * 512);
    WrL(A + 20, Attr And $37);
    If Level = 2 Then WrL(A + 24, CbList);
  End;
  PutStatus := R;
End;

{ Taille FEA2LIST des EA du fnode Fn (lu dans FnBuf2) }
Function CbListOf(V, Fn : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 4;
  If ReadFnode(V, Fn, LongInt(@FnBuf2)) = NO_ERROR Then
    If LoadEAs(V, LongInt(@FnBuf2)) = NO_ERROR Then R := EaFea2Size;
  CbListOf := R;
End;

{ Remplacer les EA du fnode Fn par ceux du FEA2LIST F (Replace : liste
  vide d'abord) et mettre a jour l'entree de repertoire }
Function SetEAsOf(V, Fn, Dir : LongInt; Name : String; F, POErr : LongInt; Replace : Boolean) : LongInt;
Var R, Fl : LongInt;
Begin
  R := ReadFnode(V, Fn, LongInt(@FnBuf2));
  If R = NO_ERROR Then
  Begin
    If Replace Then EaLen := 0 Else R := LoadEAs(V, LongInt(@FnBuf2));
  End;
  If R = NO_ERROR Then R := ApplyFea2(V, F, POErr);
  If R = NO_ERROR Then R := StoreEAs(V, Fn, LongInt(@FnBuf2));
  If R = NO_ERROR Then R := WriteFnode(V, Fn, LongInt(@FnBuf2));
  If R = NO_ERROR Then
  Begin
    Fl := 0;
    If EaLen > 0 Then Fl := DF_HASEA;
    If EaNeedCount > 0 Then Fl := Fl Or DF_NEEDEA;
    R := DirUpdate(V, Dir, Name, 32, 0, 0, 0, 0, 0, EaLen, Fl);
  End;
  SetEAsOf := R;
End;

{ Le fichier passe-t-il le filtre d'attributs de recherche ? (octet bas :
  attributs caches/systeme/repertoire admis ; octet haut : obligatoires) }
Function AttrOk(FAttr, SAttr : LongInt) : Boolean;
Var Must : LongInt;
Begin
  Must := (SAttr Shr 8) And $37;
  AttrOk := ((FAttr And Not SAttr And (ATTR_HIDDEN Or ATTR_SYSTEM Or ATTR_DIRECTORY)) = 0) And
            ((FAttr And Must) = Must);
End;

{ Le repertoire Dir est-il Anc ou un de ses descendants ? }
Function IsInside(V, Dir, Anc : LongInt) : Boolean;
Var X, N : LongInt; R : Boolean;
Begin
  R := False;
  X := Dir;
  N := 0;
  While (N < 64) And Not R Do
  Begin
    If X = Anc Then R := True
    Else If X = Vols[V].Root Then N := 64
    Else If ReadFnode(V, X, LongInt(@FnBuf2)) <> NO_ERROR Then N := 64
    Else X := RdL(LongInt(@FnBuf2) + FN_UP);
    Inc(N);
  End;
  IsInside := R;
End;

{ Creer un fichier ou un repertoire vide Name dans Dir ; rend le fnode
  (0 si echec, erreur dans LastErr) ; l'entree creee est dans NewDe }
Function CreateNode(V, Dir : LongInt; Name : String; Attr : LongInt; IsDir : Boolean) : LongInt;
Var Fn, Dn, R, Now, I, A : LongInt;
Begin
  LastErr := CheckName(Name);
  If LastErr <> NO_ERROR Then
  Begin
    CreateNode := 0;
    Exit;
  End;
  Now := NowUnix;
  Fn := AllocSector(V, Dir);
  If Fn = 0 Then
  Begin
    LastErr := ERROR_DISK_FULL;
    CreateNode := 0;
    Exit;
  End;
  R := NO_ERROR;
  Dn := 0;
  BuildFnode(LongInt(@FnBuf2), Dir, Name, IsDir);
  If IsDir Then
  Begin
    Dn := AllocDnode(V, Fn);
    If Dn = 0 Then R := ERROR_DISK_FULL
    Else
    Begin
      A := LongInt(@FnBuf2) + FN_BTREE;
      WrB(A + 4, 7);
      WrB(A + 5, 1);
      WrW(A + 6, 20);
      WrL(A + 8, 0);
      WrL(A + 12, 4);
      WrL(A + 16, Dn);
      A := LongInt(@SplitBuf);
      InitDnode(A, Dn, Fn, True);
      I := DN_HDR + BuildDe(A + DN_HDR, #1#1, ATTR_DIRECTORY, Fn, 0, Now, Now, Now);
      WrB(A + DN_HDR + DE_FLAGS, DF_FIRST);
      I := I + BuildLast(A + I, 0);
      WrL(A + 4, I);
      R := WriteDnode(V, Dn, A);
    End;
  End;
  If R = NO_ERROR Then R := WriteFnode(V, Fn, LongInt(@FnBuf2));
  If R = NO_ERROR Then
  Begin
    Attr := Attr And $27;
    If IsDir Then Attr := (Attr And Not ATTR_ARCHIVE) Or ATTR_DIRECTORY;
    If Not Is8x3(Name) Then Attr := Attr Or ATTR_NOT8X3;
    BuildDe(LongInt(@NewDe), Name, Attr, Fn, 0, Now, Now, Now);
    R := DirInsert(V, Dir, LongInt(@NewDe));
  End;
  If R <> NO_ERROR Then
  Begin
    If Dn <> 0 Then FreeDnode(V, Dn);
    MarkSecs(V, Fn, 1, True);
    CacheInvalidate(V, Fn, 1);
    Fn := 0;
  End
  Else
    LogChange(V, Dir, 1, Name);
  LastErr := R;
  CreateNode := Fn;
End;

{ Supprimer le fichier (non repertoire) d'entree DeOut du repertoire Dir }
Function RemoveFile(V, Dir : LongInt) : LongInt;
Var Fn, R : LongInt; Name : String;
Begin
  Fn := RdL(LongInt(@DeOut) + DE_FNODE);
  Name := DeName(LongInt(@DeOut));
  SetKey(Name);
  R := DirDelete(V, Dir);
  If R = NO_ERROR Then
  Begin
    If ReadFnode(V, Fn, LongInt(@FnBuf2)) = NO_ERROR Then FreeFileSpace(V, Fn, LongInt(@FnBuf2));
    CacheInvalidate(V, Fn, 1);
    MarkSecs(V, Fn, 1, True);
    LogChange(V, Dir, 2, Name);
  End;
  RemoveFile := R;
End;

{ Remplir le SFFSI d'apres l'objet O }
Procedure FillSffsi(Sffsi, O : LongInt);
Begin
  WrL(Sffsi + 8, UnixToDos(Objs[O].CTime));
  WrL(Sffsi + 12, UnixToDos(Objs[O].ATime));
  WrL(Sffsi + 16, UnixToDos(Objs[O].MTime));
  WrL(Sffsi + 20, Objs[O].Size);
  WrL(Sffsi + 52, Objs[O].Attr And $37);
End;

{ ---------------------------------------------------------------------
  FS_INIT(szParm, pDevHlp, pMiniFSD)
    Initialisation du pilote. szParm : parametres de la ligne IFS=
    (/CACHE:n Ko d'antememoire, 0 a 32 ; /AUTOCHECK:lettres). }
Function FS_INIT(PParm, PDevHlp, PMiniFsd : LongInt) : LongInt;
Var S, U : String; I, P, N, C : LongInt;
Begin
  InitUpper;
  If Not InitDone Then
  Begin
    For I := 0 To MaxVol - 1 Do
  Begin
    Vols[I].Used := False;
    Vols[I].Mounted := False;
  End;
    For I := 0 To MaxObj - 1 Do Objs[I].Used := False;
    For I := 0 To MaxOpen - 1 Do Opens[I].Used := False;
    For I := 0 To MaxFind - 1 Do Finds[I].Used := False;
    For I := 0 To MaxLock - 1 Do Locks[I].Used := False;
    For I := 0 To MaxNote - 1 Do Notes[I].Used := False;
    For I := 0 To CacheMax - 1 Do CacheVol[I] := -1;
    LogCount := 0;
    BmpVol := -1; DbVol := -1; ExtVol := -1;
    CacheTick := 0; CacheHits := 0; CacheMiss := 0;
  End;
  { parametres (un nouvel appel ne change que les options) }
  OptCache := 32;
  OptAuto := '';
  S := GetStr(PParm);
  U := UpStr(S);
  P := Pos('/CACHE:', U);
  If P > 0 Then
  Begin
    N := 0;
    I := P + 7;
    While (I <= Length(U)) And (U[I] >= '0') And (U[I] <= '9') Do
    Begin
      N := N * 10 + Ord(U[I]) - 48;
      Inc(I);
    End;
    OptCache := N;
  End;
  P := Pos('/AUTOCHECK:', U);
  If P > 0 Then
  Begin
    I := P + 11;
    While (I <= Length(U)) And (U[I] <> ' ') And (U[I] <> '/') Do
    Begin
      OptAuto := OptAuto + U[I];
      Inc(I);
    End;
  End;
  C := OptCache * 2;
  If C > CacheMax Then C := CacheMax;
  If C < 0 Then C := 0;
  For I := 0 To CacheMax - 1 Do CacheVol[I] := -1;
  CacheN := C;
  ShutDown := False;
  InitDone := True;
  FS_INIT := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  FS_MOUNT(flag, pvpfsi, pvpfsd, hVPB, pBoot)
    flag 0 : reconnaitre le volume (pBoot = son secteur d'amorce) ;
    1 : volume retire ; 2 : liberer le volume ; 3 : accepter un volume
    non reconnu (pour le formater par FS_FSCTL 8000h). }
Function FS_MOUNT(Flag, PVpfsi, PVpfsd, HVpb, PBoot : LongInt) : LongInt;
Var V, I, R : LongInt; S : String;
Begin
  R := NO_ERROR;
  V := FindVol(HVpb);
  Case Flag Of
    0, 3 :
      Begin
        If V < 0 Then
          For I := MaxVol - 1 DownTo 0 Do
            If Not Vols[I].Used Then V := I;
        If V < 0 Then R := ERROR_TOO_MANY_OPEN_FILES
        Else
        Begin
          CacheDropVol(V);
          Vols[V].Used := True;
          Vols[V].Mounted := False;
          Vols[V].HVpb := HVpb;
          Vols[V].TotSec := RdL(PVpfsi + 12);
          Vols[V].Drive := RdL(PVpfsi + 36);
          Vols[V].PVpfsi := PVpfsi;
          Vols[V].Dirty := False;
          If Flag = 0 Then
          Begin
            R := MountVol(V, PBoot);
            If R = NO_ERROR Then
            Begin
              WrL(PVpfsi, Vols[V].Serial);
              WrL(PVpfsi + 12, Vols[V].TotSec);
              S := GetLabel(V);
              PutStr(PVpfsi + 24, S, 12);
              WrL(PVpfsd, V + 1);
              WrL(PVpfsd + 4, SFD_MAGIC);
            End
            Else
              Vols[V].Used := False;
          End;
        End;
      End;
    1, 2 :
      If V >= 0 Then
      Begin
        For I := 0 To MaxObj - 1 Do
          If Objs[I].Used And (Objs[I].Vol = V) Then
          Begin
            ObjSync(I);
            Objs[I].Used := False;
          End;
        FlushVol(V);
        CacheDropVol(V);
        Vols[V].Used := False;
        Vols[V].Mounted := False;
      End;
  Else
    R := ERROR_INVALID_PARAMETER;
  End;
  FS_MOUNT := R;
End;

{ ---------------------------------------------------------------------
  FS_ATTACH(flag, pDev, pvpfsd, pcdfsd, pParm, pLen)
    Rattachement d'une unite distante : HPFS est un systeme de fichiers
    local (pas de redirection). }
Function FS_ATTACH(Flag, PDev, PVpfsd, PCdfsd, PParm, PLen : LongInt) : LongInt;
Begin
  FS_ATTACH := ERROR_NOT_SUPPORTED;
End;

{ ---------------------------------------------------------------------
  FS_OPENCREATE(pcdfsi, pcdfsd, pName, iCurDirEnd, psffsi, psffsd,
                ulOpenMode, usOpenFlag, pusAction, usAttr, pcEABuf,
                pfgenflag)
    Ouvrir ou creer un fichier. usOpenFlag : bits 0-3 si le fichier
    existe (0 echec, 1 ouvrir, 2 remplacer), bits 4-7 s'il n'existe pas
    (0 echec, 1 creer). pusAction <- 1 existait, 2 cree, 3 remplace.
    pcEABuf : EAOP2 (EA du fichier cree ou remplace) ou 0. }
Function FS_OPENCREATE(Pcdfsi, Pcdfsd, PName, ICurDirEnd, Psffsi, Psffsd, OpenMode, OpenFlag,
                       PAction, Attr, PEABuf, PGenFlag : LongInt) : LongInt;
Var V, R, O, H, Dir, Act, Fn, IfEx, IfNew : LongInt; Name : String;
Begin
  R := NO_ERROR;
  Act := 0;
  V := MVol(RdL(Psffsi + 4));
  If V < 0 Then V := VolOf(Pcdfsi, PName);
  If V < 0 Then R := ERROR_INVALID_DRIVE
  Else If (OpenMode And $8000) <> 0 Then R := ERROR_NOT_SUPPORTED    { DASD }
  Else R := Walk(V, PName);
  If (R = NO_ERROR) And WIsRoot Then R := ERROR_ACCESS_DENIED;
  If (R = NO_ERROR) And HasWild(LastComp) Then R := ERROR_INVALID_NAME;
  IfEx := OpenFlag And $0F;
  IfNew := (OpenFlag Shr 4) And $0F;
  Dir := WDir;
  Name := LastComp;
  If R = NO_ERROR Then
  Begin
    If WFound Then
    Begin
      If (DeOut[DE_ATTR] And ATTR_DIRECTORY) <> 0 Then R := ERROR_ACCESS_DENIED
      Else If IfEx = 0 Then R := 110                   { ERROR_OPEN_FAILED }
      Else If (IfEx = 2) Or WantsWrite(OpenMode) Then
      Begin
        If (DeOut[DE_ATTR] And ATTR_READONLY) <> 0 Then R := ERROR_ACCESS_DENIED;
      End;
      If (R = NO_ERROR) And (IfEx = 2) Then Act := 3 Else Act := 1;
      If (R = NO_ERROR) And (IfEx > 2) Then R := ERROR_INVALID_PARAMETER;
    End
    Else If IfNew = 1 Then
    Begin
      Fn := CreateNode(V, Dir, Name, Attr Or ATTR_ARCHIVE, False);
      If Fn = 0 Then R := LastErr
      Else
      Begin
        Act := 2;
        MoveB(LongInt(@NewDe), LongInt(@DeOut), DeLen(LongInt(@NewDe)));
      End;
    End
    Else
      R := 110;
  End;
  O := -1;
  If R = NO_ERROR Then
  Begin
    O := ObjGet(V, Dir);
    If O < 0 Then R := ERROR_TOO_MANY_OPEN_FILES;
  End;
  H := -1;
  If R = NO_ERROR Then
  Begin
    H := OpenNew(O, OpenMode, Psffsi);
    If H < 0 Then R := LastErr;
  End;
  If (R = NO_ERROR) And (Act = 3) Then
  Begin
    R := SetSize(O, 0);
    If R = NO_ERROR Then
    Begin
      Objs[O].Attr := (Objs[O].Attr And (ATTR_NOT8X3 Or ATTR_DIRECTORY)) Or (Attr And $27) Or ATTR_ARCHIVE;
      Objs[O].Dirty := True;
      R := ObjSync(O);
    End;
  End;
  If (R = NO_ERROR) And (PEABuf <> 0) And ((Act = 2) Or (Act = 3)) Then
    If RdL(PEABuf + 4) <> 0 Then
      R := SetEAsOf(V, Objs[O].Fnode, Dir, Objs[O].Name, RdL(PEABuf + 4), PEABuf + 8, True);
  If R = NO_ERROR Then
  Begin
    WrL(Psffsd, H + 1);
    WrL(Psffsd + 4, SFD_MAGIC);
    WrL(Psffsd + 8, Objs[O].Fnode);
    WrL(Psffsi + 24, 0);
    FillSffsi(Psffsi, O);
    WrL(PAction, Act);
    WrL(PGenFlag, 0);
  End
  Else
  Begin
    If H >= 0 Then Opens[H].Used := False;
    If O >= 0 Then ObjRelease(O);
  End;
  FS_OPENCREATE := R;
End;

{ ---------------------------------------------------------------------
  FS_CLOSE(type, IOflag, psffsi, psffsd)
    type 0 : fermeture ordinaire, 1 : fin du processus, 2 : derniere
    fermeture (liberation de l'ouverture). }
Function FS_CLOSE(CType, IOFlag, Psffsi, Psffsd : LongInt) : LongInt;
Var H, O, I, R : LongInt;
Begin
  R := NO_ERROR;
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    O := Opens[H].Obj;
    { les verrous de cette ouverture sont leves }
    For I := 0 To MaxLock - 1 Do
      If Locks[I].Used And (Locks[I].Owner = Psffsi) Then Locks[I].Used := False;
    R := ObjSync(O);
    If CType = 2 Then
    Begin
      Opens[H].Used := False;
      WrL(Psffsd + 4, 0);
      ObjRelease(O);
    End;
  End;
  FS_CLOSE := R;
End;

{ ---------------------------------------------------------------------
  FS_READ(psffsi, psffsd, pData, pLen, IOflag)
    Lire *pLen octets a la position sfi_position ; *pLen <- lus. }
Function FS_READ(Psffsi, Psffsd, PData, PLen, IOFlag : LongInt) : LongInt;
Var H, O, R, N, Got, FPos : LongInt;
Begin
  Got := 0;
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else If Not WantsRead(Opens[H].Mode) Then R := ERROR_ACCESS_DENIED
  Else
  Begin
    O := Opens[H].Obj;
    N := RdL(PLen);
    FPos := RdL(Psffsi + 24);
    If LockConflict(O, Psffsi, FPos, N, False) Then R := ERROR_LOCK_VIOLATION
    Else R := ReadData(O, FPos, PData, N, Got);
    WrL(Psffsi + 24, FPos + Got);
  End;
  WrL(PLen, Got);
  FS_READ := R;
End;

{ ---------------------------------------------------------------------
  FS_WRITE(psffsi, psffsd, pData, pLen, IOflag)
    Ecrire *pLen octets a la position sfi_position (le fichier grandit
    au besoin) ; *pLen <- ecrits. }
Function FS_WRITE(Psffsi, Psffsd, PData, PLen, IOFlag : LongInt) : LongInt;
Var H, O, R, N, Done, FPos : LongInt;
Begin
  Done := 0;
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else If Not WantsWrite(Opens[H].Mode) Then R := ERROR_ACCESS_DENIED
  Else
  Begin
    O := Opens[H].Obj;
    N := RdL(PLen);
    FPos := RdL(Psffsi + 24);
    If LockConflict(O, Psffsi, FPos, N, True) Then R := ERROR_LOCK_VIOLATION
    Else R := WriteData(O, FPos, PData, N, Done);
    WrL(Psffsi + 24, FPos + Done);
    FillSffsi(Psffsi, O);
    If (IOFlag And $10) <> 0 Then ObjSync(O);       { ecriture immediate }
  End;
  WrL(PLen, Done);
  FS_WRITE := R;
End;

{ ---------------------------------------------------------------------
  FS_CHGFILEPTR(psffsi, psffsd, offset, type, IOflag)
    Deplacer sfi_position : type 0 debut, 1 position courante, 2 fin. }
Function FS_CHGFILEPTR(Psffsi, Psffsd, Offset, MType, IOFlag : LongInt) : LongInt;
Var H, R, NP : LongInt;
Begin
  R := NO_ERROR;
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    Case MType Of
      0 : NP := Offset;
      1 : NP := RdL(Psffsi + 24) + Offset;
      2 : NP := Objs[Opens[H].Obj].Size + Offset;
    Else
      Begin
        NP := 0;
        R := ERROR_INVALID_FUNCTION;
      End;
    End;
    If (R = NO_ERROR) And (NP < 0) Then R := ERROR_NEGATIVE_SEEK;
    If R = NO_ERROR Then WrL(Psffsi + 24, NP);
  End;
  FS_CHGFILEPTR := R;
End;

{ ---------------------------------------------------------------------
  FS_NEWSIZE(psffsi, psffsd, len, IOflag)
    Changer la taille du fichier (troncature ou extension par des zeros). }
Function FS_NEWSIZE(Psffsi, Psffsd, Len, IOFlag : LongInt) : LongInt;
Var H, R, O : LongInt;
Begin
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else If Not WantsWrite(Opens[H].Mode) Then R := ERROR_ACCESS_DENIED
  Else
  Begin
    O := Opens[H].Obj;
    R := SetSize(O, Len);
    FillSffsi(Psffsi, O);
  End;
  FS_NEWSIZE := R;
End;

{ ---------------------------------------------------------------------
  FS_COMMIT(type, IOflag, psffsi, psffsd)
    Ecrire sur le disque la taille, les dates et les attributs du
    fichier (DosResetBuffer). }
Function FS_COMMIT(CType, IOFlag, Psffsi, Psffsd : LongInt) : LongInt;
Var H, R : LongInt;
Begin
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    R := ObjSync(Opens[H].Obj);
    If R = NO_ERROR Then R := FlushVol(Objs[Opens[H].Obj].Vol);
  End;
  FS_COMMIT := R;
End;

{ --- informations sur les fichiers --- }

{ Interroger ou modifier les informations du fichier de fnode Fn (entree
  DeOut, repertoire Dir, objet O ou -1). Niveaux : 1 FILESTATUS3,
  2 FILESTATUS4 (cbList), 3 EA choisis (EAOP2), 4 tous les EA (EAOP2). }
Function InfoOp(V, Dir, O : LongInt; SetIt : Boolean; Level, PData, CbData : LongInt) : LongInt;
Var R, Fn, Attr, Size, C, Ac, M, T : LongInt; Name : String;
Begin
  R := NO_ERROR;
  Fn := RdL(LongInt(@DeOut) + DE_FNODE);
  Name := DeName(LongInt(@DeOut));
  Attr := DeOut[DE_ATTR];
  Size := RdL(LongInt(@DeOut) + DE_SIZE);
  C := RdL(LongInt(@DeOut) + DE_CDATE);
  Ac := RdL(LongInt(@DeOut) + DE_RDATE);
  M := RdL(LongInt(@DeOut) + DE_WDATE);
  If O >= 0 Then
  Begin
    Attr := Objs[O].Attr; Size := Objs[O].Size;
    C := Objs[O].CTime; Ac := Objs[O].ATime; M := Objs[O].MTime;
  End;
  If Not SetIt Then
  Begin
    Case Level Of
      1 : R := PutStatus(PData, CbData, 1, Attr, Size, C, Ac, M, 0);
      2 : R := PutStatus(PData, CbData, 2, Attr, Size, C, Ac, M, CbListOf(V, Fn));
      3, 4 :
        Begin
          If CbData < 12 Then R := ERROR_BUFFER_OVERFLOW
          Else R := ReadFnode(V, Fn, LongInt(@FnBuf2));
          If R = NO_ERROR Then R := LoadEAs(V, LongInt(@FnBuf2));
          If R = NO_ERROR Then
          Begin
            If Level = 3 Then R := QueryEAs(V, RdL(PData), RdL(PData + 4))
            Else R := QueryEAs(V, 0, RdL(PData + 4));
          End;
        End;
    Else
      R := ERROR_INVALID_LEVEL;
    End;
  End
  Else If Fn = Vols[V].Root Then R := ERROR_ACCESS_DENIED
  Else
  Begin
    Case Level Of
      1 :
        If CbData < 22 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          T := GetDT(PData); If T >= 0 Then C := T;
          T := GetDT(PData + 4); If T >= 0 Then Ac := T;
          T := GetDT(PData + 8); If T >= 0 Then M := T;
          If CbData >= 24 Then
          Begin
            T := RdL(PData + 20);
            If (T And Not $37) <> 0 Then R := ERROR_ACCESS_DENIED
            Else If ((T Xor Attr) And ATTR_DIRECTORY) <> 0 Then R := ERROR_ACCESS_DENIED
            Else Attr := (Attr And (ATTR_DIRECTORY Or ATTR_NOT8X3)) Or (T And $27);
          End;
          If R = NO_ERROR Then
            R := DirUpdate(V, Dir, Name, 2 + 4 + 8 + 16, 0, M, Ac, C, Attr, 0, 0);
          If (R = NO_ERROR) And (O >= 0) Then
          Begin
            Objs[O].Attr := Attr; Objs[O].CTime := C; Objs[O].ATime := Ac; Objs[O].MTime := M;
          End;
          LogChange(V, Dir, 3, Name);
        End;
      2 :
        If CbData < 12 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          R := SetEAsOf(V, Fn, Dir, Name, RdL(PData + 4), PData + 8, False);
          LogChange(V, Dir, 3, Name);
        End;
    Else
      R := ERROR_INVALID_LEVEL;
    End;
  End;
  InfoOp := R;
End;

{ ---------------------------------------------------------------------
  FS_FILEINFO(flag, psffsi, psffsd, level, pData, cbData, IOflag)
    flag 0 : interroger, 1 : modifier les informations d'un fichier
    ouvert (niveaux de InfoOp). }
Function FS_FILEINFO(Flag, Psffsi, Psffsd, Level, PData, CbData, IOFlag : LongInt) : LongInt;
Var H, O, R, V : LongInt;
Begin
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    O := Opens[H].Obj;
    V := Objs[O].Vol;
    ObjSync(O);
    SetKey(Objs[O].Name);
    If Not Lookup(V, Objs[O].Dir) Then R := ERROR_FILE_NOT_FOUND
    Else If ((Flag And 1) <> 0) And Not WantsWrite(Opens[H].Mode) Then R := ERROR_ACCESS_DENIED
    Else
    Begin
      R := InfoOp(V, Objs[O].Dir, O, (Flag And 1) <> 0, Level, PData, CbData);
      FillSffsi(Psffsi, O);
    End;
  End;
  FS_FILEINFO := R;
End;

{ Nom complet du chemin analyse, avec la casse enregistree (Exact) ou
  telle que donnee }
Function FullName(V : LongInt; Exact : Boolean) : String;
Var S : String; I, Dir : LongInt;
Begin
  S := Chr(65 + Vols[V].Drive) + ':';
  Dir := Vols[V].Root;
  For I := 0 To NComp - 1 Do
  Begin
    SetKey(PComp[I]);
    If Exact And Lookup(V, Dir) Then
    Begin
      S := S + '\' + DeName(LongInt(@DeOut));
      Dir := RdL(LongInt(@DeOut) + DE_FNODE);
    End
    Else
      S := S + '\' + PComp[I];
  End;
  If NComp = 0 Then S := S + '\';
  FullName := S;
End;

{ ---------------------------------------------------------------------
  FS_PATHINFO(flag, pcdfsi, pcdfsd, pName, iCurDirEnd, level, pData,
              cbData)
    Informations d'un fichier ou repertoire designe par son chemin :
    niveaux de InfoOp, plus 5 (nom complet) et 7 (nom complet avec la
    casse enregistree) en interrogation. }
Function FS_PATHINFO(Flag, Pcdfsi, Pcdfsd, PName, ICurDirEnd, Level, PData, CbData : LongInt) : LongInt;
Var V, R, O, Dir : LongInt; S : String;
Begin
  V := VolOf(Pcdfsi, PName);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PName);
  If (R = NO_ERROR) And HasWild(LastComp) Then R := ERROR_INVALID_NAME;
  If R = NO_ERROR Then
  Begin
    Dir := WDir;
    If ((Level = 5) Or (Level = 7)) And ((Flag And 1) = 0) Then
    Begin
      S := FullName(V, Level = 7);
      If Length(S) + 1 > CbData Then R := ERROR_BUFFER_OVERFLOW Else PutStr(PData, S, CbData);
    End
    Else If Not WFound Then R := ERROR_FILE_NOT_FOUND
    Else
    Begin
      O := ObjFind(V, RdL(LongInt(@DeOut) + DE_FNODE));
      If (O >= 0) And ((Flag And 1) <> 0) Then
      Begin
        ObjSync(O);
        SetKey(LastComp);
        Lookup(V, Dir);
      End;
      If WIsRoot Then
      Begin
        If (Flag And 1) <> 0 Then R := ERROR_ACCESS_DENIED
        Else If (Level = 1) Or (Level = 2) Then
          R := PutStatus(PData, CbData, Level, ATTR_DIRECTORY, 0, 0, 0, 0, CbListOf(V, Vols[V].Root))
        Else
          R := InfoOp(V, Dir, -1, False, Level, PData, CbData);
      End
      Else
        R := InfoOp(V, Dir, O, (Flag And 1) <> 0, Level, PData, CbData);
    End;
  End;
  FS_PATHINFO := R;
End;

{ ---------------------------------------------------------------------
  FS_FILEATTRIBUTE(flag, pcdfsi, pcdfsd, pName, iCurDirEnd, pAttr)
    flag 0 : lire les attributs DOS dans *pAttr, 1 : les modifier. }
Function FS_FILEATTRIBUTE(Flag, Pcdfsi, Pcdfsd, PName, ICurDirEnd, PAttr : LongInt) : LongInt;
Var V, R, O, A, Attr : LongInt;
Begin
  V := VolOf(Pcdfsi, PName);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PName);
  If (R = NO_ERROR) And Not WFound Then R := ERROR_FILE_NOT_FOUND;
  If R = NO_ERROR Then
  Begin
    O := ObjFind(V, RdL(LongInt(@DeOut) + DE_FNODE));
    Attr := DeOut[DE_ATTR];
    If O >= 0 Then Attr := Objs[O].Attr;
    If (Flag And 1) = 0 Then WrL(PAttr, Attr And $37)
    Else If WIsRoot Then R := ERROR_ACCESS_DENIED
    Else
    Begin
      A := RdL(PAttr);
      If ((A And Not $37) <> 0) Or (((A Xor Attr) And ATTR_DIRECTORY) <> 0) Then R := ERROR_ACCESS_DENIED
      Else
      Begin
        Attr := (Attr And (ATTR_DIRECTORY Or ATTR_NOT8X3)) Or (A And $27);
        R := DirUpdate(V, WDir, LastComp, 16, 0, 0, 0, 0, Attr, 0, 0);
        If O >= 0 Then Objs[O].Attr := Attr;
      End;
    End;
  End;
  FS_FILEATTRIBUTE := R;
End;

{ --- noms : creation, suppression, deplacement, copie --- }

{ ---------------------------------------------------------------------
  FS_DELETE(pcdfsi, pcdfsd, pFile, iCurDirEnd)
    Supprimer un fichier (pas un repertoire, ni un fichier en lecture
    seule ou ouvert). }
Function FS_DELETE(Pcdfsi, Pcdfsd, PFile, ICurDirEnd : LongInt) : LongInt;
Var V, R : LongInt;
Begin
  V := VolOf(Pcdfsi, PFile);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PFile);
  If (R = NO_ERROR) And (WIsRoot Or HasWild(LastComp)) Then R := ERROR_ACCESS_DENIED;
  If (R = NO_ERROR) And Not WFound Then R := ERROR_FILE_NOT_FOUND;
  If R = NO_ERROR Then
  Begin
    If (DeOut[DE_ATTR] And (ATTR_DIRECTORY Or ATTR_READONLY)) <> 0 Then R := ERROR_ACCESS_DENIED
    Else If InUse(V, RdL(LongInt(@DeOut) + DE_FNODE)) Then R := ERROR_SHARING_VIOLATION
    Else R := RemoveFile(V, WDir);
  End;
  FS_DELETE := R;
End;

{ ---------------------------------------------------------------------
  FS_MKDIR(pcdfsi, pcdfsd, pName, iCurDirEnd, pEABuf, flags)
    Creer un repertoire ; pEABuf : EAOP2 de ses EA ou 0. }
Function FS_MKDIR(Pcdfsi, Pcdfsd, PName, ICurDirEnd, PEABuf, Flags : LongInt) : LongInt;
Var V, R, Fn, Dir : LongInt; Name : String;
Begin
  V := VolOf(Pcdfsi, PName);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PName);
  If (R = NO_ERROR) And (WIsRoot Or WFound) Then R := ERROR_ACCESS_DENIED;
  If (R = NO_ERROR) And HasWild(LastComp) Then R := ERROR_INVALID_NAME;
  If R = NO_ERROR Then
  Begin
    Dir := WDir;
    Name := LastComp;
    Fn := CreateNode(V, Dir, Name, 0, True);
    If Fn = 0 Then R := LastErr
    Else If PEABuf <> 0 Then
      If RdL(PEABuf + 4) <> 0 Then R := SetEAsOf(V, Fn, Dir, Name, RdL(PEABuf + 4), PEABuf + 8, True);
  End;
  FS_MKDIR := R;
End;

{ ---------------------------------------------------------------------
  FS_RMDIR(pcdfsi, pcdfsd, pName, iCurDirEnd)
    Supprimer un repertoire vide. }
Function FS_RMDIR(Pcdfsi, Pcdfsd, PName, ICurDirEnd : LongInt) : LongInt;
Var V, R, Fn, Dir, Dn : LongInt; Name : String;
Begin
  V := VolOf(Pcdfsi, PName);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PName);
  If (R = NO_ERROR) And WIsRoot Then R := ERROR_ACCESS_DENIED;
  If (R = NO_ERROR) And Not WFound Then R := ERROR_PATH_NOT_FOUND;
  If (R = NO_ERROR) And ((DeOut[DE_ATTR] And ATTR_DIRECTORY) = 0) Then R := ERROR_DIRECTORY;
  If R = NO_ERROR Then
  Begin
    Dir := WDir;
    Fn := RdL(LongInt(@DeOut) + DE_FNODE);
    Name := DeName(LongInt(@DeOut));
    If Not DirEmpty(V, Fn) Then R := ERROR_DIR_NOT_EMPTY
    Else
    Begin
      R := DirRoot(V, Fn, Dn);
      If R = NO_ERROR Then
      Begin
        SetKey(Name);
        R := DirDelete(V, Dir);
      End;
      If R = NO_ERROR Then
      Begin
        FreeDirTree(V, Dn, 1);
        If ReadFnode(V, Fn, LongInt(@FnBuf2)) = NO_ERROR Then
        Begin
          { EA eventuels du repertoire }
          If (RdL(LongInt(@FnBuf2) + FN_EASIZEL) > 0) And ((RdW(LongInt(@FnBuf2) + FN_FLAGS) And FNF_EAANODE) = 0) Then
            MarkSecs(V, RdL(LongInt(@FnBuf2) + FN_EASEC), (RdL(LongInt(@FnBuf2) + FN_EASIZEL) + 511) Div 512, True);
        End;
        CacheInvalidate(V, Fn, 1);
        MarkSecs(V, Fn, 1, True);
        LogChange(V, Dir, 2, Name);
      End;
    End;
  End;
  FS_RMDIR := R;
End;

{ ---------------------------------------------------------------------
  FS_MOVE(pcdfsi, pcdfsd, pSrc, iSrcCurDirEnd, pDst, iDstCurDirEnd,
          flags)
    Renommer ou deplacer un fichier ou un repertoire sur le volume (le
    changement de casse seule est permis). }
Function FS_MOVE(Pcdfsi, Pcdfsd, PSrc, ISrcEnd, PDst, IDstEnd, Flags : LongInt) : LongInt;
Var V, R, SrcDir, DstDir, Fn, Attr, I, O : LongInt; SrcName, DstName : String; IsDir : Boolean;
Begin
  V := VolOf(Pcdfsi, PSrc);
  If V < 0 Then R := ERROR_INVALID_DRIVE
  Else If VolOf(Pcdfsi, PDst) <> V Then R := ERROR_NOT_SAME_DEVICE
  Else R := Walk(V, PSrc);
  If (R = NO_ERROR) And (WIsRoot Or HasWild(LastComp)) Then R := ERROR_ACCESS_DENIED;
  If (R = NO_ERROR) And Not WFound Then R := ERROR_FILE_NOT_FOUND;
  If R = NO_ERROR Then
  Begin
    SrcDir := WDir;
    SrcName := DeName(LongInt(@DeOut));
    Fn := RdL(LongInt(@DeOut) + DE_FNODE);
    IsDir := (DeOut[DE_ATTR] And ATTR_DIRECTORY) <> 0;
    MoveB(LongInt(@DeOut), LongInt(@DeOut2), DeLen(LongInt(@DeOut)));
    R := Walk(V, PDst);
    If (R = NO_ERROR) And (WIsRoot Or HasWild(LastComp)) Then R := ERROR_ACCESS_DENIED;
    DstDir := WDir;
    DstName := LastComp;
    If R = NO_ERROR Then R := CheckName(DstName);
    If (R = NO_ERROR) And WFound Then
      If RdL(LongInt(@DeOut) + DE_FNODE) <> Fn Then R := ERROR_ACCESS_DENIED;
    If (R = NO_ERROR) And IsDir Then
      If IsInside(V, DstDir, Fn) Then R := ERROR_ACCESS_DENIED;
    If (R = NO_ERROR) And (SrcDir = DstDir) And (SrcName = DstName) Then
    Begin
      FS_MOVE := NO_ERROR;
      Exit;
    End;
  End;
  If R = NO_ERROR Then
  Begin
    { nouvelle entree : memes donnees, nouveau nom }
    Attr := DeOut2[DE_ATTR] And Not ATTR_NOT8X3;
    If Not Is8x3(DstName) Then Attr := Attr Or ATTR_NOT8X3;
    BuildDe(LongInt(@NewDe), DstName, Attr, Fn, RdL(LongInt(@DeOut2) + DE_SIZE),
            RdL(LongInt(@DeOut2) + DE_WDATE), RdL(LongInt(@DeOut2) + DE_RDATE),
            RdL(LongInt(@DeOut2) + DE_CDATE));
    WrB(LongInt(@NewDe) + DE_FLAGS, DeOut2[DE_FLAGS] And (DF_HASEA Or DF_NEEDEA));
    WrL(LongInt(@NewDe) + DE_EASIZE, RdL(LongInt(@DeOut2) + DE_EASIZE));
    SetKey(SrcName);
    R := DirDelete(V, SrcDir);
    If R = NO_ERROR Then
    Begin
      R := DirInsert(V, DstDir, LongInt(@NewDe));
      If R <> NO_ERROR Then
      Begin
        { remettre l'entree d'origine }
        BuildDe(LongInt(@NewDe), SrcName, DeOut2[DE_ATTR], Fn, RdL(LongInt(@DeOut2) + DE_SIZE),
                RdL(LongInt(@DeOut2) + DE_WDATE), RdL(LongInt(@DeOut2) + DE_RDATE),
                RdL(LongInt(@DeOut2) + DE_CDATE));
        DirInsert(V, SrcDir, LongInt(@NewDe));
      End;
    End;
    If R = NO_ERROR Then
    Begin
      If ReadFnode(V, Fn, LongInt(@FnBuf2)) = NO_ERROR Then
      Begin
        WrB(LongInt(@FnBuf2) + FN_LEN, Length(DstName));
        FillB(LongInt(@FnBuf2) + FN_NAME, 15, 0);
        For I := 1 To Min(15, Length(DstName)) Do WrB(LongInt(@FnBuf2) + FN_NAME + I - 1, Ord(DstName[I]));
        WrL(LongInt(@FnBuf2) + FN_UP, DstDir);
        WriteFnode(V, Fn, LongInt(@FnBuf2));
      End;
      O := ObjFind(V, Fn);
      If O >= 0 Then
      Begin
        Objs[O].Dir := DstDir;
        Objs[O].Name := DstName;
      End;
      LogChange(V, SrcDir, 2, SrcName);
      LogChange(V, DstDir, 1, DstName);
    End;
  End;
  FS_MOVE := R;
End;

{ ---------------------------------------------------------------------
  FS_COPY(flag, pcdfsi, pcdfsd, pSrc, iSrcCurDirEnd, pDst, iDstCurDirEnd,
          nameType)
    Copier un fichier (donnees, attributs, dates et EA) sur le volume.
    flag bit 0 : remplacer la destination. Un repertoire n'est pas copie
    par le pilote (ERROR_CANNOT_COPY : le noyau le fait lui-meme). }
Function FS_COPY(Flag, Pcdfsi, Pcdfsd, PSrc, ISrcEnd, PDst, IDstEnd, NameType : LongInt) : LongInt;
Var V, R, SrcDir, DstDir, Fn, OS, OD, FPos, Got, Done, Attr : LongInt; DstName : String;
Begin
  V := VolOf(Pcdfsi, PSrc);
  OS := -1; OD := -1;
  If V < 0 Then R := ERROR_INVALID_DRIVE
  Else If VolOf(Pcdfsi, PDst) <> V Then R := ERROR_CANNOT_COPY
  Else R := Walk(V, PSrc);
  If (R = NO_ERROR) And (WIsRoot Or HasWild(LastComp)) Then R := ERROR_CANNOT_COPY;
  If (R = NO_ERROR) And Not WFound Then R := ERROR_FILE_NOT_FOUND;
  If (R = NO_ERROR) And ((DeOut[DE_ATTR] And ATTR_DIRECTORY) <> 0) Then R := ERROR_CANNOT_COPY;
  If R = NO_ERROR Then
  Begin
    SrcDir := WDir;
    Fn := RdL(LongInt(@DeOut) + DE_FNODE);
    Attr := DeOut[DE_ATTR];
    OS := ObjGet(V, SrcDir);
    If OS < 0 Then R := ERROR_TOO_MANY_OPEN_FILES
    Else ObjSync(OS);
  End;
  If R = NO_ERROR Then
  Begin
    R := Walk(V, PDst);
    If (R = NO_ERROR) And (WIsRoot Or HasWild(LastComp)) Then R := ERROR_ACCESS_DENIED;
    DstDir := WDir;
    DstName := LastComp;
    If (R = NO_ERROR) And WFound Then
    Begin
      If RdL(LongInt(@DeOut) + DE_FNODE) = Fn Then R := ERROR_ACCESS_DENIED
      Else If (Flag And 1) = 0 Then R := ERROR_FILE_EXISTS
      Else If (DeOut[DE_ATTR] And (ATTR_DIRECTORY Or ATTR_READONLY)) <> 0 Then R := ERROR_ACCESS_DENIED
      Else If InUse(V, RdL(LongInt(@DeOut) + DE_FNODE)) Then R := ERROR_SHARING_VIOLATION
      Else R := RemoveFile(V, DstDir);
    End;
  End;
  If R = NO_ERROR Then
  Begin
    If CreateNode(V, DstDir, DstName, Attr, False) = 0 Then R := LastErr
    Else
    Begin
      MoveB(LongInt(@NewDe), LongInt(@DeOut), DeLen(LongInt(@NewDe)));
      OD := ObjGet(V, DstDir);
      If OD < 0 Then R := ERROR_TOO_MANY_OPEN_FILES;
    End;
  End;
  If R = NO_ERROR Then
  Begin
    { donnees }
    R := ObjReserve(OD, Objs[OS].Size);
    FPos := 0;
    While (R = NO_ERROR) And (FPos < Objs[OS].Size) Do
    Begin
      R := ReadData(OS, FPos, LongInt(@BigBuf), 4096, Got);
      If (R = NO_ERROR) And (Got > 0) Then R := WriteData(OD, FPos, LongInt(@BigBuf), Got, Done);
      If Got <= 0 Then FPos := Objs[OS].Size Else FPos := FPos + Got;
    End;
    { dates et attributs d'origine }
    Objs[OD].Attr := Objs[OS].Attr;
    Objs[OD].CTime := Objs[OS].CTime;
    Objs[OD].MTime := Objs[OS].MTime;
    Objs[OD].Dirty := True;
    If R = NO_ERROR Then R := ObjSync(OD);
    { EA }
    If (R = NO_ERROR) And (ReadFnode(V, Objs[OS].Fnode, LongInt(@FnBuf2)) = NO_ERROR) Then
      If LoadEAs(V, LongInt(@FnBuf2)) = NO_ERROR Then
        If EaLen > 0 Then
        Begin
          R := ReadFnode(V, Objs[OD].Fnode, LongInt(@FnBuf2));
          If R = NO_ERROR Then R := StoreEAs(V, Objs[OD].Fnode, LongInt(@FnBuf2));
          If R = NO_ERROR Then R := WriteFnode(V, Objs[OD].Fnode, LongInt(@FnBuf2));
          If R = NO_ERROR Then
          Begin
            Attr := DF_HASEA;
            If EaNeedCount > 0 Then Attr := Attr Or DF_NEEDEA;
            R := DirUpdate(V, DstDir, DstName, 32, 0, 0, 0, 0, 0, EaLen, Attr);
          End;
        End;
  End;
  If OS >= 0 Then ObjRelease(OS);
  If OD >= 0 Then ObjRelease(OD);
  FS_COPY := R;
End;

{ ---------------------------------------------------------------------
  FS_CHDIR(flag, pcdfsi, pcdfsd, pDir, iCurDirEnd)
    flag 0 : changer de repertoire courant (verifier pDir et remplir la
    zone CDFSD : +0 fnode, +4 volume) ; 1 : verifier que le repertoire
    courant (cdi_curdir) existe toujours ; 2 : liberer la zone CDFSD. }
Function FS_CHDIR(Flag, Pcdfsi, Pcdfsd, PDir, ICurDirEnd : LongInt) : LongInt;
Var V, R, Fn : LongInt;
Begin
  R := NO_ERROR;
  Case Flag Of
    0, 1 :
      Begin
        If Flag = 1 Then PDir := Pcdfsi + 12;
        V := VolOf(Pcdfsi, PDir);
        If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PDir);
        If (R = NO_ERROR) And Not WFound Then R := ERROR_PATH_NOT_FOUND;
        If (R = NO_ERROR) And ((DeOut[DE_ATTR] And ATTR_DIRECTORY) = 0) Then R := ERROR_PATH_NOT_FOUND;
        If R = NO_ERROR Then
        Begin
          If WIsRoot Then Fn := Vols[V].Root Else Fn := RdL(LongInt(@DeOut) + DE_FNODE);
          WrL(Pcdfsd, Fn);
          WrL(Pcdfsd + 4, V);
        End;
      End;
    2 : WrL(Pcdfsd, 0);
  Else
    R := ERROR_INVALID_PARAMETER;
  End;
  FS_CHDIR := R;
End;

{ --- recherche de fichiers --- }

{ Ecrire une entree de recherche en Dst (Room octets) ; niveaux 1
  (FILEFINDBUF3), 2 (FILEFINDBUF4 : cbList) et 3 (FILEFINDBUF3 suivi du
  FEA2LIST des EA demandes par le GEA2LIST G). Rend la longueur ou -1. }
Function PutFind(V, Dst, Room, Level, G : LongInt; Name : String; Attr, Size, C, Ac, M, Fn : LongInt) : LongInt;
Var Need, NPos, R, L, Q : LongInt;
Begin
  R := -1;
  If Level = 2 Then NPos := 32 Else NPos := 28;
  Need := NPos + 2 + Length(Name);
  If (Level <> 3) And (Need <= Room) Then
  Begin
    R := Need;
    WrL(Dst, 0);
    PutDT(Dst + 4, C);
    PutDT(Dst + 8, Ac);
    PutDT(Dst + 12, M);
    WrL(Dst + 16, Size);
    WrL(Dst + 20, ((Size + 511) Div 512) * 512);
    WrL(Dst + 24, Attr And $37);
    If Level = 2 Then WrL(Dst + 28, CbListOf(V, Fn));
    WrB(Dst + NPos, Length(Name));
    PutStr(Dst + NPos + 1, Name, Length(Name) + 1);
  End
  Else If (Level = 3) And (Room > 32 + Length(Name)) Then
  Begin
    WrL(Dst, 0);
    PutDT(Dst + 4, C);
    PutDT(Dst + 8, Ac);
    PutDT(Dst + 12, M);
    WrL(Dst + 16, Size);
    WrL(Dst + 20, ((Size + 511) Div 512) * 512);
    WrL(Dst + 24, Attr And $37);
    Q := Dst + 28;
    WrL(Q, Room - 30 - Length(Name));
    L := -1;
    If ReadFnode(V, Fn, LongInt(@FnBuf2)) = NO_ERROR Then
      If LoadEAs(V, LongInt(@FnBuf2)) = NO_ERROR Then
        If QueryEAs(V, G, Q) = NO_ERROR Then L := RdL(Q);
    If L >= 4 Then
    Begin
      WrB(Q + L, Length(Name));
      PutStr(Q + L + 1, Name, Length(Name) + 1);
      R := 28 + L + 2 + Length(Name);
    End;
  End;
  PutFind := R;
End;

{ Entree "." ou ".." (dates de l'entree ^A^A du repertoire Dir) dans DeOut }
Procedure DotDe(V, Dir : LongInt; Name : String; Fn : LongInt);
Var Dn, C, Ac, M : LongInt;
Begin
  C := 0; Ac := 0; M := 0;
  If DirRoot(V, Dir, Dn) = NO_ERROR Then
    If SuccIn(V, Dn, 0, 0, False, 1) Then
    Begin
      C := RdL(LongInt(@DeOut) + DE_CDATE);
      Ac := RdL(LongInt(@DeOut) + DE_RDATE);
      M := RdL(LongInt(@DeOut) + DE_WDATE);
    End;
  BuildDe(LongInt(@DeOut), Name, ATTR_DIRECTORY, Fn, 0, M, Ac, C);
End;

{ Remplir pData avec au plus *pcMatch entrees de la recherche F }
Function DoFind(F, PData, CbData, PcMatch, Level, Flags : LongInt) : LongInt;
Var V, Want, Cnt, FPos, Prev, L, R, G, Start, SaveDots : LongInt;
    Name, SaveLast : String; Have, Stop : Boolean;
Begin
  R := NO_ERROR;
  V := Finds[F].Vol;
  Want := RdL(PcMatch);
  If Want <= 0 Then Want := 1;
  If (Level < 1) Or (Level > 3) Then
  Begin
    DoFind := ERROR_INVALID_LEVEL;
    Exit;
  End;
  G := 0;
  Start := 0;
  If Level = 3 Then
  Begin
    G := RdL(PData);
    Start := 12;
  End;
  Cnt := 0; FPos := Start; Prev := -1;
  Stop := False;
  While (Cnt < Want) And Not Stop Do
  Begin
    SaveLast := Finds[F].Last;
    SaveDots := Finds[F].Dots;
    Have := False;
    If Finds[F].Dots = 0 Then
    Begin
      Finds[F].Dots := 1;
      If (Finds[F].Dir <> Vols[V].Root) And MatchMask('.', Finds[F].Mask) And
         AttrOk(ATTR_DIRECTORY, Finds[F].Attr) Then
      Begin
        Name := '.';
        DotDe(V, Finds[F].Dir, '.', Finds[F].Dir);
        Have := True;
      End;
    End
    Else If Finds[F].Dots = 1 Then
    Begin
      Finds[F].Dots := 2;
      If (Finds[F].Dir <> Vols[V].Root) And MatchMask('..', Finds[F].Mask) And
         AttrOk(ATTR_DIRECTORY, Finds[F].Attr) Then
      Begin
        Name := '..';
        DotDe(V, Finds[F].Parent, '..', Finds[F].Parent);
        Have := True;
      End;
    End
    Else If Finds[F].Dots = 4 Then
    Begin
      Finds[F].Dots := 3;
      SetKey(Finds[F].Mask);
      If Lookup(V, Finds[F].Dir) Then
      Begin
        Name := DeName(LongInt(@DeOut));
        If AttrOk(DeOut[DE_ATTR], Finds[F].Attr) Then Have := True;
      End;
    End
    Else If Finds[F].Dots = 3 Then
      Stop := True                                    { nom exact deja rendu }
    Else If DirNext(V, Finds[F].Dir, Finds[F].Last) Then
    Begin
      Name := DeName(LongInt(@DeOut));
      Finds[F].Last := Name;
      If MatchMask(Name, Finds[F].Mask) And AttrOk(DeOut[DE_ATTR], Finds[F].Attr) Then Have := True;
    End
    Else
      Stop := True;
    If Have Then
    Begin
      If Prev >= 0 Then FPos := (FPos + 3) And Not 3;
      L := PutFind(V, PData + FPos, CbData - FPos, Level, G, Name, DeOut[DE_ATTR],
                   RdL(LongInt(@DeOut) + DE_SIZE), RdL(LongInt(@DeOut) + DE_CDATE),
                   RdL(LongInt(@DeOut) + DE_RDATE), RdL(LongInt(@DeOut) + DE_WDATE),
                   RdL(LongInt(@DeOut) + DE_FNODE));
      If L < 0 Then
      Begin
        { plus de place : l'entree sera rendue au prochain appel }
        Finds[F].Last := SaveLast;
        Finds[F].Dots := SaveDots;
        If Cnt = 0 Then R := ERROR_BUFFER_OVERFLOW;
        Stop := True;
      End
      Else
      Begin
        If Prev >= 0 Then WrL(PData + Prev, FPos - Prev);
        Prev := FPos;
        FPos := FPos + L;
        Inc(Cnt);
        Inc(Finds[F].FPos);
      End;
    End;
  End;
  WrL(PcMatch, Cnt);
  If (R = NO_ERROR) And (Cnt = 0) Then R := ERROR_NO_MORE_FILES;
  DoFind := R;
End;

Function FindOf(Pfsfsd : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  If Pfsfsd <> 0 Then
    If RdL(Pfsfsd + 4) = SFD_MAGIC Then
    Begin
      I := RdL(Pfsfsd) - 1;
      If (I >= 0) And (I < MaxFind) Then
        If Finds[I].Used Then R := I;
    End;
  FindOf := R;
End;

{ ---------------------------------------------------------------------
  FS_FINDFIRST(pcdfsi, pcdfsd, pName, iCurDirEnd, attr, pfsfsi, pfsfsd,
               pData, cbData, pcMatch, level, flags)
    Commencer une recherche (jokers * et ?) ; *pcMatch : nombre d'entrees
    voulues, puis rendues. Niveau 3 : pData commence par un EAOP2. }
Function FS_FINDFIRST(Pcdfsi, Pcdfsd, PName, ICurDirEnd, Attr, Pfsfsi, Pfsfsd, PData, CbData,
                      PcMatch, Level, Flags : LongInt) : LongInt;
Var V, R, F, I : LongInt;
Begin
  V := VolOf(Pcdfsi, PName);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PName);
  F := -1;
  If R = NO_ERROR Then
  Begin
    For I := MaxFind - 1 DownTo 0 Do
      If Not Finds[I].Used Then F := I;
    If F < 0 Then R := ERROR_TOO_MANY_OPEN_FILES;
  End;
  If R = NO_ERROR Then
  Begin
    Finds[F].Used := True;
    Finds[F].Vol := V;
    Finds[F].Dir := WDir;
    Finds[F].Parent := Vols[V].Root;
    If (WDir <> Vols[V].Root) And (ReadFnode(V, WDir, LongInt(@FnBuf2)) = NO_ERROR) Then
      Finds[F].Parent := RdL(LongInt(@FnBuf2) + FN_UP);
    Finds[F].Attr := Attr;
    Finds[F].Last := '';
    Finds[F].Dots := 0;
    Finds[F].FPos := 0;
    Finds[F].Pid := KGetCurrentProcessId;
    If NComp = 0 Then Finds[F].Mask := '*' Else Finds[F].Mask := LastComp;
    { nom exact : une seule entree au plus }
    If (NComp > 0) And Not HasWild(LastComp) Then Finds[F].Dots := 4;
    WrL(Pfsfsd, F + 1);
    WrL(Pfsfsd + 4, SFD_MAGIC);
    R := DoFind(F, PData, CbData, PcMatch, Level, Flags);
    If R <> NO_ERROR Then
    Begin
      Finds[F].Used := False;
      WrL(Pfsfsd + 4, 0);
    End;
  End
  Else
    WrL(PcMatch, 0);
  FS_FINDFIRST := R;
End;

{ ---------------------------------------------------------------------
  FS_FINDNEXT(pfsfsi, pfsfsd, pData, cbData, pcMatch, level, flag)
    Entrees suivantes de la recherche. }
Function FS_FINDNEXT(Pfsfsi, Pfsfsd, PData, CbData, PcMatch, Level, Flag : LongInt) : LongInt;
Var F, R : LongInt;
Begin
  F := FindOf(Pfsfsd);
  If F < 0 Then R := ERROR_INVALID_HANDLE
  Else R := DoFind(F, PData, CbData, PcMatch, Level, Flag);
  FS_FINDNEXT := R;
End;

{ ---------------------------------------------------------------------
  FS_FINDFROMNAME(pfsfsi, pfsfsd, pData, cbData, pcMatch, level,
                  position, pName, flags)
    Reprendre la recherche apres le fichier pName (nom sans chemin). }
Function FS_FINDFROMNAME(Pfsfsi, Pfsfsd, PData, CbData, PcMatch, Level, Position, PName, Flags : LongInt) : LongInt;
Var F, R : LongInt; S : String;
Begin
  F := FindOf(Pfsfsd);
  If F < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    S := GetStr(PName);
    If (S = '.') Or (S = '..') Then
    Begin
      If S = '.' Then Finds[F].Dots := 1 Else Finds[F].Dots := 2;
      Finds[F].Last := '';
    End
    Else
    Begin
      Finds[F].Dots := 2;
      Finds[F].Last := S;
    End;
    R := DoFind(F, PData, CbData, PcMatch, Level, Flags);
  End;
  FS_FINDFROMNAME := R;
End;

{ ---------------------------------------------------------------------
  FS_FINDCLOSE(pfsfsi, pfsfsd)
    Terminer une recherche. }
Function FS_FINDCLOSE(Pfsfsi, Pfsfsd : LongInt) : LongInt;
Var F, R : LongInt;
Begin
  R := NO_ERROR;
  F := FindOf(Pfsfsd);
  If F < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    Finds[F].Used := False;
    WrL(Pfsfsd + 4, 0);
  End;
  FS_FINDCLOSE := R;
End;

{ --- notification des changements (DosFindNotifyFirst/Next/Close) --- }

{ Rendre les changements notes depuis la derniere fois pour N }
Function NoteCollect(N, PData, CbData, PcMatch, Level : LongInt) : LongInt;
Var Want, Cnt, FPos, Prev, L, I, V, Size, Attr, C, Ac, M, Fn : LongInt;
Begin
  V := Notes[N].Vol;
  Want := RdL(PcMatch);
  If Want <= 0 Then Want := 1;
  If Notes[N].Seen < LogCount - MaxLog Then Notes[N].Seen := LogCount - MaxLog;
  Cnt := 0; FPos := 0; Prev := -1;
  While (Notes[N].Seen < LogCount) And (Cnt < Want) Do
  Begin
    I := Notes[N].Seen Mod MaxLog;
    Inc(Notes[N].Seen);
    If (ChgLog[I].Vol = V) And (ChgLog[I].Dir = Notes[N].Dir) And MatchMask(ChgLog[I].Name, Notes[N].Mask) Then
    Begin
      Size := 0; Attr := 0; C := 0; Ac := 0; M := 0; Fn := 0;
      SetKey(ChgLog[I].Name);
      If Lookup(V, Notes[N].Dir) Then
      Begin
        Attr := DeOut[DE_ATTR]; Size := RdL(LongInt(@DeOut) + DE_SIZE);
        C := RdL(LongInt(@DeOut) + DE_CDATE); Ac := RdL(LongInt(@DeOut) + DE_RDATE);
        M := RdL(LongInt(@DeOut) + DE_WDATE); Fn := RdL(LongInt(@DeOut) + DE_FNODE);
      End;
      If Prev >= 0 Then FPos := (FPos + 3) And Not 3;
      L := PutFind(V, PData + FPos, CbData - FPos, 1, 0, ChgLog[I].Name, Attr, Size, C, Ac, M, Fn);
      If L < 0 Then
      Begin
        Dec(Notes[N].Seen);
        Want := Cnt;
      End
      Else
      Begin
        If Prev >= 0 Then WrL(PData + Prev, FPos - Prev);
        Prev := FPos;
        FPos := FPos + L;
        Inc(Cnt);
      End;
    End;
  End;
  WrL(PcMatch, Cnt);
  NoteCollect := Cnt;
End;

{ ---------------------------------------------------------------------
  FS_FINDNOTIFYFIRST(pcdfsi, pcdfsd, pName, iCurDirEnd, attr, pHandle,
                     pData, cbData, pcMatch, level, timeout)
    Commencer la surveillance des changements d'un repertoire (masque
    pName) ; *pHandle <- numero de surveillance. Les changements sont
    rendus par FS_FINDNOTIFYNEXT (le pilote n'attend pas). }
Function FS_FINDNOTIFYFIRST(Pcdfsi, Pcdfsd, PName, ICurDirEnd, Attr, PHandle, PData, CbData, PcMatch,
                            Level, Timeout : LongInt) : LongInt;
Var V, R, N, I : LongInt;
Begin
  V := VolOf(Pcdfsi, PName);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PName);
  If (R = NO_ERROR) And (Level <> 1) Then R := ERROR_INVALID_LEVEL;
  N := -1;
  If R = NO_ERROR Then
  Begin
    For I := MaxNote - 1 DownTo 0 Do
      If Not Notes[I].Used Then N := I;
    If N < 0 Then R := ERROR_TOO_MANY_OPEN_FILES;
  End;
  If R = NO_ERROR Then
  Begin
    Notes[N].Used := True;
    Notes[N].Vol := V;
    Notes[N].Dir := WDir;
    If NComp = 0 Then Notes[N].Mask := '*' Else Notes[N].Mask := LastComp;
    Notes[N].Attr := Attr;
    Notes[N].Seen := LogCount;
    Notes[N].Pid := KGetCurrentProcessId;
    WrL(PHandle, N + 1);
    WrL(PcMatch, 0);
  End;
  FS_FINDNOTIFYFIRST := R;
End;

{ ---------------------------------------------------------------------
  FS_FINDNOTIFYNEXT(handle, pData, cbData, pcMatch, level, timeout)
    Rendre les changements survenus (entrees de niveau 1) ;
    ERROR_TIMEOUT s'il n'y en a aucun. }
Function FS_FINDNOTIFYNEXT(Handle, PData, CbData, PcMatch, Level, Timeout : LongInt) : LongInt;
Var N, R : LongInt;
Begin
  N := Handle - 1;
  If (N < 0) Or (N >= MaxNote) Then R := ERROR_INVALID_HANDLE
  Else If Not Notes[N].Used Then R := ERROR_INVALID_HANDLE
  Else If Level <> 1 Then R := ERROR_INVALID_LEVEL
  Else If NoteCollect(N, PData, CbData, PcMatch, Level) = 0 Then R := ERROR_TIMEOUT
  Else R := NO_ERROR;
  FS_FINDNOTIFYNEXT := R;
End;

{ ---------------------------------------------------------------------
  FS_FINDNOTIFYCLOSE(handle)
    Terminer une surveillance. }
Function FS_FINDNOTIFYCLOSE(Handle : LongInt) : LongInt;
Var N, R : LongInt;
Begin
  R := NO_ERROR;
  N := Handle - 1;
  If (N < 0) Or (N >= MaxNote) Then R := ERROR_INVALID_HANDLE
  Else If Not Notes[N].Used Then R := ERROR_INVALID_HANDLE
  Else Notes[N].Used := False;
  FS_FINDNOTIFYCLOSE := R;
End;

{ --- volume --- }

{ ---------------------------------------------------------------------
  FS_FSINFO(flag, hVPB, pData, cbData, level)
    flag 0 : interroger ; niveau 1 FSALLOCATE (idFileSystem, cSectorUnit,
    cUnit, cUnitAvail, cbSector : 18 octets), niveau 2 FSINFO (numero de
    serie, longueur et texte du nom de volume). flag 1, niveau 2 :
    changer le nom de volume (VOLUMELABEL : longueur, texte). }
Function FS_FSINFO(Flag, HVpb, PData, CbData, Level : LongInt) : LongInt;
Var V, R, L : LongInt; S : String;
Begin
  R := NO_ERROR;
  V := MVol(HVpb);
  If V < 0 Then R := ERROR_INVALID_DRIVE
  Else If (Flag And 1) = 0 Then
  Begin
    Case Level Of
      1 :
        If CbData < 18 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          WrL(PData, 0);
          WrL(PData + 4, 1);
          WrL(PData + 8, Vols[V].TotSec);
          WrL(PData + 12, Vols[V].FreeSecs);
          WrW(PData + 16, 512);
        End;
      2 :
        If CbData < 17 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          S := GetLabel(V);
          WrL(PData, Vols[V].Serial);
          WrB(PData + 4, Length(S));
          PutStr(PData + 5, S, 12);
        End;
    Else
      R := ERROR_INVALID_LEVEL;
    End;
  End
  Else If Level = 2 Then
  Begin
    L := RdB(PData);
    S := '';
    While Length(S) < L Do S := S + Chr(RdB(PData + 1 + Length(S)));
    If (L > 11) Or (CheckName(S) <> NO_ERROR) And (L > 0) Then R := ERROR_INVALID_NAME
    Else
    Begin
      R := SetLabel(V, S);
      If (R = NO_ERROR) And (Vols[V].PVpfsi <> 0) Then PutStr(Vols[V].PVpfsi + 24, UpStr(S), 12);
    End;
  End
  Else
    R := ERROR_INVALID_LEVEL;
  FS_FSINFO := R;
End;

{ ---------------------------------------------------------------------
  FS_FLUSHBUF(hVPB, flag)
    Ecrire tout ce qui concerne le volume (tailles et dates des fichiers
    ouverts, etat du volume). }
Function FS_FLUSHBUF(HVpb, Flag : LongInt) : LongInt;
Var V, I, R : LongInt;
Begin
  V := MVol(HVpb);
  If V < 0 Then R := ERROR_INVALID_DRIVE
  Else
  Begin
    For I := 0 To MaxObj - 1 Do
      If Objs[I].Used And (Objs[I].Vol = V) Then ObjSync(I);
    R := FlushVol(V);
  End;
  FS_FLUSHBUF := R;
End;

{ ---------------------------------------------------------------------
  FS_SHUTDOWN(type, reserved)
    type 0 : debut de l'arret du systeme (tout ecrire) ; type 1 : fin
    (les volumes sont marques fermes proprement). }
Function FS_SHUTDOWN(SType, Reserved : LongInt) : LongInt;
Var I : LongInt;
Begin
  For I := 0 To MaxObj - 1 Do
    If Objs[I].Used Then ObjSync(I);
  If SType = 1 Then
  Begin
    For I := 0 To MaxVol - 1 Do
      If Vols[I].Used And Vols[I].Mounted Then FlushVol(I);
    ShutDown := True;
  End;
  FS_SHUTDOWN := NO_ERROR;
End;

{ Message d'une erreur propre a HPFS (FSCTL_ERROR_INFO) }
Function ErrText(E : LongInt) : String;
Var S : String;
Begin
  Case E Of
    ERROR_INVALID_DATA      : S := 'Structure HPFS endommagee (lancer la verification du volume).';
    ERROR_DISK_FULL         : S := 'Le volume HPFS est plein.';
    ERROR_EAS_DIDNT_FIT     : S := 'Les attributs etendus ne tiennent pas sur le volume HPFS.';
    ERROR_INVALID_EA_NAME   : S := 'Nom d''attribut etendu incorrect.';
    ERROR_EA_LIST_INCONSISTENT : S := 'Liste d''attributs etendus incoherente.';
    ERROR_NOT_DOS_DISK      : S := 'Ce volume n''est pas un volume HPFS.';
    ERROR_FILENAME_EXCED_RANGE : S := 'Nom de fichier trop long (254 caracteres au plus).';
  Else
    S := '';
  End;
  ErrText := S;
End;

{ ---------------------------------------------------------------------
  FS_FSCTL(pArgdat, iArgType, func, pParm, lenParm, plenParmIO, pData,
           lenData, plenDataIO)
    Fonctions de controle du pilote :
      1      FSCTL_ERROR_INFO : *pParm = code -> texte dans pData
      2      FSCTL_MAX_EASIZE : pData <- taille maximale d'un EA (2
             octets) et d'une liste d'EA (4 octets)
      8000h  formater : pParm = hVPB, adresse du nom de volume (ou 0)
      8001h  verifier : pParm = hVPB, options (bit 0 : corriger) ;
             pData <- erreurs, secteurs perdus, repertoires, fichiers,
             dnodes, secteurs de donnees, secteurs libres, total, EA
      8002h  statistiques : pParm = hVPB ; pData <- lectures servies par
             l'antememoire, lectures du disque, secteurs libres, total,
             dnodes libres de la bande des repertoires, taille de la
             bande (dnodes), volume modifie, fichiers ouverts, volume mal
             ferme au montage, verification automatique demandee
             (/AUTOCHECK) }
Function FS_FSCTL(PArgdat, IArgType, Func, PParm, LenParm, PLenParmIO, PData, LenData, PLenDataIO : LongInt) : LongInt;
Var V, R, I, Lost, N : LongInt; S : String;
Begin
  R := NO_ERROR;
  Case Func Of
    1 :
      Begin
        S := ErrText(RdL(PParm));
        If S = '' Then R := ERROR_INVALID_PARAMETER
        Else If Length(S) + 1 > LenData Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          PutStr(PData, S, LenData);
          WrL(PLenDataIO, Length(S) + 1);
        End;
      End;
    2 :
      If LenData < 6 Then R := ERROR_BUFFER_OVERFLOW
      Else
      Begin
        WrW(PData, EaBufMax - 300);
        WrL(PData + 2, EaBufMax);
        WrL(PLenDataIO, 6);
      End;
    $8000 :
      Begin
        V := FindVol(RdL(PParm));
        If V < 0 Then R := ERROR_INVALID_DRIVE
        Else
        Begin
          For I := 0 To MaxObj - 1 Do
            If Objs[I].Used And (Objs[I].Vol = V) Then R := ERROR_PATH_BUSY;
          If R = NO_ERROR Then
          Begin
            Vols[V].Mounted := False;
            If LenParm >= 8 Then S := GetStr(RdL(PParm + 4)) Else S := '';
            R := FormatVol(V, S);
            If R = NO_ERROR Then R := DevIO(V, DVIO_OPREAD, 0, 1, LongInt(@ZeroBuf));
            If R = NO_ERROR Then R := MountVol(V, LongInt(@ZeroBuf));
            FillB(LongInt(@ZeroBuf), 512, 0);
            If (R = NO_ERROR) And (Vols[V].PVpfsi <> 0) Then
            Begin
              WrL(Vols[V].PVpfsi, Vols[V].Serial);
              WrL(Vols[V].PVpfsi + 12, Vols[V].TotSec);
              PutStr(Vols[V].PVpfsi + 24, GetLabel(V), 12);
            End;
          End;
        End;
      End;
    $8001 :
      Begin
        V := MVol(RdL(PParm));
        If V < 0 Then R := ERROR_INVALID_DRIVE
        Else If LenData < 36 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          For I := 0 To MaxObj - 1 Do
            If Objs[I].Used And (Objs[I].Vol = V) Then ObjSync(I);
          N := 0;
          If LenParm >= 8 Then N := RdL(PParm + 4);
          R := CheckVol(V, (N And 1) <> 0, Lost);
          If R = NO_ERROR Then
          Begin
            WrL(PData, ChkErrors);
            WrL(PData + 4, Lost);
            WrL(PData + 8, ChkDirs);
            WrL(PData + 12, ChkFiles);
            WrL(PData + 16, ChkDnCount);
            WrL(PData + 20, ChkUsed);
            WrL(PData + 24, Vols[V].FreeSecs);
            WrL(PData + 28, Vols[V].TotSec);
            WrL(PData + 32, ChkEa);
            WrL(PLenDataIO, 36);
          End;
        End;
      End;
    $8002 :
      Begin
        V := MVol(RdL(PParm));
        If V < 0 Then R := ERROR_INVALID_DRIVE
        Else If LenData < 32 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          N := 0;
          For I := 0 To MaxObj - 1 Do
            If Objs[I].Used And (Objs[I].Vol = V) Then Inc(N);
          WrL(PData, CacheHits);
          WrL(PData + 4, CacheMiss);
          WrL(PData + 8, Vols[V].FreeSecs);
          WrL(PData + 12, Vols[V].TotSec);
          WrL(PData + 16, FreeDirBand(V));
          WrL(PData + 20, (Vols[V].DirEnd - Vols[V].DirStart + 1) Div 4);
          If Vols[V].Dirty Then WrL(PData + 24, 1) Else WrL(PData + 24, 0);
          WrL(PData + 28, N);
          If LenData >= 40 Then
          Begin
            If Vols[V].WasDirty Then WrL(PData + 32, 1) Else WrL(PData + 32, 0);
            If Pos(Chr(65 + Vols[V].Drive), OptAuto) > 0 Then WrL(PData + 36, 1) Else WrL(PData + 36, 0);
            WrL(PLenDataIO, 40);
          End
          Else
            WrL(PLenDataIO, 32);
        End;
      End;
  Else
    R := ERROR_INVALID_FUNCTION;
  End;
  FS_FSCTL := R;
End;

{ ---------------------------------------------------------------------
  FS_IOCTL(psffsi, psffsd, cat, func, pParm, lenMaxParm, plenInOutParm,
           pData, lenMaxData, plenInOutData)
    Controle de peripherique sur un fichier ouvert du volume.
    Categorie 8 (disque), fonction 63h : parametres du peripherique
    (BPB du volume, cylindres, type, attributs : 31 octets). }
Function FS_IOCTL(Psffsi, Psffsd, Cat, Func, PParm, LenMaxParm, PLenParm, PData, LenMaxData, PLenData : LongInt) : LongInt;
Var V, R : LongInt;
Begin
  R := NO_ERROR;
  V := MVol(RdL(Psffsi + 4));
  If V < 0 Then R := ERROR_INVALID_DRIVE
  Else If Cat <> 8 Then R := ERROR_INVALID_CATEGORY
  Else If Func <> $63 Then R := ERROR_INVALID_FUNCTION
  Else If LenMaxData < 31 Then R := ERROR_BUFFER_OVERFLOW
  Else
  Begin
    R := DevIO(V, DVIO_OPREAD, 0, 1, LongInt(@SecBuf));
    If R = NO_ERROR Then
    Begin
      MoveB(LongInt(@SecBuf) + 11, PData, 25);
      WrW(PData + 25, Vols[V].TotSec Div (63 * 16));
      WrB(PData + 27, 5);
      WrW(PData + 28, 1);
      WrB(PData + 30, 0);
      WrL(PLenData, 31);
    End;
  End;
  FS_IOCTL := R;
End;

{ --- verrous et entrees/sorties groupees --- }

Function DoUnlock(O, Owner, Ofs, Len : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := ERROR_LOCK_VIOLATION;
  For I := 0 To MaxLock - 1 Do
    If (R <> NO_ERROR) And Locks[I].Used And (Locks[I].Obj = O) And (Locks[I].Owner = Owner) And
       (Locks[I].Ofs = Ofs) And (Locks[I].Len = Len) Then
    Begin
      Locks[I].Used := False;
      R := NO_ERROR;
    End;
  DoUnlock := R;
End;

Function DoLock(O, Owner, Ofs, Len : LongInt; Shared : Boolean) : LongInt;
Var I, R, F : LongInt;
Begin
  R := NO_ERROR;
  If (Ofs < 0) Or (Len < 0) Then R := ERROR_INVALID_PARAMETER
  Else If LockConflict(O, Owner, Ofs, Len, Not Shared) Then R := ERROR_LOCK_VIOLATION
  Else
  Begin
    F := -1;
    For I := MaxLock - 1 DownTo 0 Do
      If Not Locks[I].Used Then F := I;
    If F < 0 Then R := 36                               { ERROR_SHARING_BUFFER_EXCEEDED }
    Else
    Begin
      Locks[F].Used := True;
      Locks[F].Obj := O;
      Locks[F].Owner := Owner;
      Locks[F].Pid := RdL(Owner + 32);
      Locks[F].Ofs := Ofs;
      Locks[F].Len := Len;
      Locks[F].Shared := Shared;
    End;
  End;
  DoLock := R;
End;

{ ---------------------------------------------------------------------
  FS_FILELOCKS(psffsi, psffsd, pUnLockRange, pLockRange, timeout, flags)
    Lever puis poser un verrou de plage (FILELOCK : debut, longueur ;
    0 = aucun). flags bit 0 : verrou partage. Le pilote n'attend pas :
    une plage deja verrouillee rend ERROR_LOCK_VIOLATION. }
Function FS_FILELOCKS(Psffsi, Psffsd, PUnlock, PLock, Timeout, Flags : LongInt) : LongInt;
Var H, O, R : LongInt;
Begin
  R := NO_ERROR;
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    O := Opens[H].Obj;
    If PUnlock <> 0 Then
      If RdL(PUnlock + 4) > 0 Then R := DoUnlock(O, Psffsi, RdL(PUnlock), RdL(PUnlock + 4));
    If (R = NO_ERROR) And (PLock <> 0) Then
      If RdL(PLock + 4) > 0 Then R := DoLock(O, Psffsi, RdL(PLock), RdL(PLock + 4), (Flags And 1) <> 0);
  End;
  FS_FILELOCKS := R;
End;

{ ---------------------------------------------------------------------
  FS_CANCELLOCKREQUEST(psffsi, psffsd, pLockRange)
    Annuler une demande de verrou en attente : le pilote ne met jamais
    une demande en attente, il n'y a donc rien a annuler. }
Function FS_CANCELLOCKREQUEST(Psffsi, Psffsd, PLockRange : LongInt) : LongInt;
Begin
  If OpenOf(Psffsd) < 0 Then FS_CANCELLOCKREQUEST := ERROR_INVALID_HANDLE
  Else FS_CANCELLOCKREQUEST := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  FS_FILEIO(psffsi, psffsd, pCmdList, cbCmdList, poError, IOflag)
    Suite de commandes (format de DosFileIO) : 0 verrouiller (cmd,
    nombre, delai ; puis partage, debut, longueur), 1 deverrouiller
    (cmd, nombre ; puis debut, longueur), 2 deplacer (cmd, methode,
    distance, position rendue), 3 lire et 4 ecrire (cmd, tampon,
    longueur, longueur traitee). *poError <- position de la commande
    en erreur. }
Function FS_FILEIO(Psffsi, Psffsd, PCmd, CbCmd, POError, IOFlag : LongInt) : LongInt;
Var H, P, Stop, Cmd, N, I, R, Len : LongInt;
Begin
  R := NO_ERROR;
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE;
  P := PCmd;
  Stop := PCmd + CbCmd;
  While (P < Stop) And (R = NO_ERROR) Do
  Begin
    Cmd := RdW(P);
    Case Cmd Of
      0 :
        Begin
          N := RdW(P + 2);
          For I := 0 To N - 1 Do
            If R = NO_ERROR Then
              R := DoLock(Opens[H].Obj, Psffsi, RdL(P + 8 + I * 10 + 2), RdL(P + 8 + I * 10 + 6),
                          (RdW(P + 8 + I * 10) And 1) <> 0);
          If R = NO_ERROR Then P := P + 8 + N * 10;
        End;
      1 :
        Begin
          N := RdW(P + 2);
          For I := 0 To N - 1 Do
            If R = NO_ERROR Then R := DoUnlock(Opens[H].Obj, Psffsi, RdL(P + 4 + I * 8), RdL(P + 4 + I * 8 + 4));
          If R = NO_ERROR Then P := P + 4 + N * 8;
        End;
      2 :
        Begin
          R := FS_CHGFILEPTR(Psffsi, Psffsd, RdL(P + 4), RdW(P + 2), IOFlag);
          If R = NO_ERROR Then
          Begin
            WrL(P + 8, RdL(Psffsi + 24));
            P := P + 12;
          End;
        End;
      3, 4 :
        Begin
          Len := RdW(P + 6);
          If Cmd = 3 Then R := FS_READ(Psffsi, Psffsd, RdL(P + 2), LongInt(@Len), IOFlag)
          Else R := FS_WRITE(Psffsi, Psffsd, RdL(P + 2), LongInt(@Len), IOFlag);
          WrW(P + 8, Len);
          If R = NO_ERROR Then P := P + 10;
        End;
    Else
      R := ERROR_INVALID_FUNCTION;
    End;
  End;
  If R <> NO_ERROR Then WrL(POError, P - PCmd);
  FS_FILEIO := R;
End;

{ --- processus, tuyaux nommes, noms --- }

{ ---------------------------------------------------------------------
  FS_EXIT(uid, pid, pdb)
    Fin d'un processus : ses verrous, recherches et surveillances sont
    liberes. }
Function FS_EXIT(Uid, Pid, Pdb : LongInt) : LongInt;
Var I : LongInt;
Begin
  For I := 0 To MaxLock - 1 Do
    If Locks[I].Used And (Locks[I].Pid = Pid) Then Locks[I].Used := False;
  For I := 0 To MaxFind - 1 Do
    If Finds[I].Used And (Finds[I].Pid = Pid) Then Finds[I].Used := False;
  For I := 0 To MaxNote - 1 Do
    If Notes[I].Used And (Notes[I].Pid = Pid) Then Notes[I].Used := False;
  FS_EXIT := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  FS_NMPIPE(psffsi, psffsd, OpType, pOpRec, pData, pName)
    Operations sur les tuyaux nommes : les tuyaux nommes ne sont pas sur
    un volume HPFS (ils relevent du noyau). }
Function FS_NMPIPE(Psffsi, Psffsd, OpType, POpRec, PData, PName : LongInt) : LongInt;
Begin
  FS_NMPIPE := ERROR_NOT_SUPPORTED;
End;

{ ---------------------------------------------------------------------
  FS_PROCESSNAME(pNameBuf)
    Mettre un nom sous sa forme canonique HPFS (en place) : les points et
    espaces de fin de chaque composant sont retires. }
Function FS_PROCESSNAME(PNameBuf : LongInt) : LongInt;
Var S, T, C : String; I : LongInt;
Begin
  S := GetStr(PNameBuf);
  T := '';
  C := '';
  For I := 1 To Length(S) + 1 Do
  Begin
    If (I > Length(S)) Or (S[I] = '\') Or (S[I] = '/') Then
    Begin
      If (C <> '.') And (C <> '..') Then
        While (Length(C) > 0) And ((C[Length(C)] = '.') Or (C[Length(C)] = ' ')) Do Delete(C, Length(C), 1);
      T := T + C;
      If I <= Length(S) Then T := T + S[I];
      C := '';
    End
    Else
      C := C + S[I];
  End;
  PutStr(PNameBuf, T, Length(T) + 1);
  ProcName := T;
  FS_PROCESSNAME := NO_ERROR;
End;

{ --- fichier d'echange (pagination) --- }

{ ---------------------------------------------------------------------
  FS_SETSWAP(psffsi, psffsd)
    Le fichier ouvert devient le fichier d'echange du systeme. }
Function FS_SETSWAP(Psffsi, Psffsd : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := OpenOf(Psffsd);
  If H < 0 Then FS_SETSWAP := ERROR_INVALID_HANDLE
  Else
  Begin
    Objs[Opens[H].Obj].Swap := True;
    FS_SETSWAP := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  FS_OPENPAGEFILE(pFlags, pcMaxReq, pName, psffsi, psffsd, ulOpenMode,
                  usOpenFlag, usAttr, Reserved)
    Ouvrir ou creer le fichier d'echange ; *pcMaxReq <- nombre maximal de
    pages par appel de FS_DOPAGEIO, *pFlags <- 0 (adresses lineaires). }
Function FS_OPENPAGEFILE(PFlags, PcMaxReq, PName, Psffsi, Psffsd, OpenMode, OpenFlag, Attr, Reserved : LongInt) : LongInt;
Var R, Act, Gen, H : LongInt;
Begin
  R := FS_OPENCREATE(0, 0, PName, -1, Psffsi, Psffsd, OpenMode, OpenFlag, LongInt(@Act), Attr, 0, LongInt(@Gen));
  If R = NO_ERROR Then
  Begin
    H := OpenOf(Psffsd);
    Objs[Opens[H].Obj].Swap := True;
    WrL(PcMaxReq, 16);
    WrL(PFlags, 0);
  End;
  FS_OPENPAGEFILE := R;
End;

{ ---------------------------------------------------------------------
  FS_ALLOCATEPAGESPACE(psffsi, psffsd, lSize, lWantContig)
    Fixer la taille du fichier d'echange a lSize octets (allocation aussi
    contigue que possible). }
Function FS_ALLOCATEPAGESPACE(Psffsi, Psffsd, LSize, LWantContig : LongInt) : LongInt;
Var H, O, R : LongInt;
Begin
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    O := Opens[H].Obj;
    R := SetSize(O, LSize);
    FillSffsi(Psffsi, O);
    If R = NO_ERROR Then R := ObjSync(O);
  End;
  FS_ALLOCATEPAGESPACE := R;
End;

{ ---------------------------------------------------------------------
  FS_DOPAGEIO(psffsi, psffsd, pList)
    Lire ou ecrire des pages de 4 Ko du fichier d'echange. Liste :
      +0 nombre de commandes, +4 options, +8 options rendues, puis par
      commande (16 octets) : commande (1 lire, 2 ecrire, 3 verifier),
      etat rendu (0 ou code d'erreur), adresse de la page, position dans
      le fichier. }
Function FS_DOPAGEIO(Psffsi, Psffsd, PList : LongInt) : LongInt;
Var H, O, R, N, I, E, Got, Done, St : LongInt;
Begin
  R := NO_ERROR;
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    O := Opens[H].Obj;
    N := RdL(PList);
    WrL(PList + 8, 0);
    For I := 0 To N - 1 Do
    Begin
      E := PList + 12 + I * 16;
      Case RdL(E) Of
        1 :
          Begin
            St := ReadData(O, RdL(E + 12), RdL(E + 8), 4096, Got);
            If (St = NO_ERROR) And (Got < 4096) Then FillB(RdL(E + 8) + Got, 4096 - Got, 0);
          End;
        2 : St := WriteData(O, RdL(E + 12), RdL(E + 8), 4096, Done);
        3 : St := ReadData(O, RdL(E + 12), LongInt(@BigBuf), 4096, Got);
      Else
        St := ERROR_INVALID_FUNCTION;
      End;
      WrL(E + 4, St);
      If St <> NO_ERROR Then
      Begin
        R := St;
        WrL(PList + 8, 1);
      End;
    End;
    FillSffsi(Psffsi, O);
  End;
  FS_DOPAGEIO := R;
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  FS_ALLOCATEPAGESPACE, FS_ATTACH, FS_ATTRIBUTE, FS_CANCELLOCKREQUEST,
  FS_CHDIR, FS_CHGFILEPTR, FS_CLOSE, FS_COMMIT, FS_COPY, FS_DELETE,
  FS_DOPAGEIO, FS_EXIT, FS_FILEATTRIBUTE, FS_FILEINFO, FS_FILEIO,
  FS_FILELOCKS, FS_FINDCLOSE, FS_FINDFIRST, FS_FINDFROMNAME, FS_FINDNEXT,
  FS_FINDNOTIFYCLOSE, FS_FINDNOTIFYFIRST, FS_FINDNOTIFYNEXT, FS_FLUSHBUF,
  FS_FSCTL, FS_FSINFO, FS_INIT, FS_IOCTL, FS_MKDIR, FS_MOUNT, FS_MOVE,
  FS_NAME, FS_NEWSIZE, FS_NMPIPE, FS_OPENCREATE, FS_OPENPAGEFILE,
  FS_PATHINFO, FS_PROCESSNAME, FS_READ, FS_RMDIR, FS_SETSWAP, FS_SHUTDOWN,
  FS_WRITE;

BEGIN
  InitDone := False;
  FS_INIT(0, 0, 0);
END.
