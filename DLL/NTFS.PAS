{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Pilote de systeme de fichiers installable OS/2 NTFS.IFS
                (NTFS 3.1 de Windows NT) de OS/2-0.
}

Library NTFS;

{ Compilation : OS2PC NTFS.PAS NTFS.IFS   (produit NTFS.IFS)

  NTFS.IFS est le pilote de systeme de fichiers (FSD) NTFS d'OS/2-0. Il
  est charge par le noyau OS2KRNL d'apres une ligne IFS= de CONFIG.SYS :

    IFS=C:\NTFS.IFS /CACHE:64 /AUTOCHECK:E

  puis le noyau lui presente chaque volume (partition de type 07h d'un
  disque dur IDE ou SATA) par FS_MOUNT. Le type 07h est partage avec
  HPFS : NTFS.IFS ne reconnait que les volumes dont le secteur d'amorce
  porte "NTFS    " en +3 (HPFS.IFS refuse ceux-la). Un volume reconnu
  recoit une lettre d'unite et les fonctions de fichiers du noyau, donc
  DOSCALLS.DLL, CMD.EXE et tous les programmes, passent alors par les
  points d'entree FS_* de ce pilote.

  Le code NTFS vient de Pasdows 95 (projet gladir/Pasdows95 : partie 3c
  de KERNEL/VMM32.PAS pour la lecture et l'ecriture, formatage NTFS 3.1
  de SETUP/INSTALL.PAS), adapte a l'interface IFS d'OS/2-0 (service de
  secteurs FSH_DOVOLIO du noyau au lieu des tableaux de volumes de
  Pasdows).

  Format sur disque (NTFS 3.x de Windows 2000, XP et suivants) :
    secteur 0       secteur d'amorce ("NTFS    " en +3, taille des
                    clusters, LCN de $MFT et de $MFTMirr, taille des
                    enregistrements et des blocs d'index)
    $MFT            table des fichiers : un enregistrement (1 Ko) par
                    fichier ("FILE", correctifs de secteurs), fait
                    d'attributs residents ou non residents (listes de
                    runs : VCN -> LCN), eventuellement repartis par une
                    liste d'attributs ($20)
    0 $MFT, 1 $MFTMirr (copie des 4 premiers), 2 $LogFile, 3 $Volume
    (nom, version, etat), 4 $AttrDef, 5 la racine, 6 $Bitmap (un bit par
    cluster), 7 $Boot, 8 $BadClus, 9 $Secure, 10 $UpCase (table des
    majuscules UTF-16, 128 Ko), 11 $Extend ; les fichiers des utilisateurs
    a partir de 24 (bitmap de la MFT : $B0 de l'enregistrement 0)
    repertoire     index $I30 : arbre B+ d'entrees triees (cle :
                    attribut $FILE_NAME du fichier), petit index dans
                    $INDEX_ROOT ($90) ou blocs "INDX" de $INDEX_ALLOCATION
                    ($A0) avec leur bitmap ($B0)
  Les noms sont en UTF-16 : ils sont convertis dans la page de codes 850
  d'OS/2-0 (les caracteres absents deviennent '_') et compares sans tenir
  compte de la casse par la table $UpCase du volume. Les dates (FILETIME,
  centaines de nanosecondes depuis 1601) sont converties en secondes
  depuis 1970. Les volumes de 2 To et les fichiers de 2 Go au plus sont
  geres (arithmetique de 32 bits, comme Pasdows).

  En ecriture : bitmap des clusters et de la MFT, fichiers residents puis
  non residents, extension de la MFT, index reconstruits a chaque
  modification (petit index dans $INDEX_ROOT ou arbre de blocs INDX),
  $MFTMirr. Le journal $LogFile n'est pas tenu : comme ntfs-3g, le pilote
  le vide (rempli de FFh) avant la premiere modification d'un volume pour
  que Windows ne rejoue pas d'anciennes transactions ; le bit "volume
  modifie" de $Volume est pose pendant les modifications et retire a
  chaque vidage (FS_FLUSHBUF, FS_COMMIT, fermeture, arret). Les fichiers
  compresses ou chiffres ne sont pas lus ; les attributs etendus (EA)
  d'OS/2 ne sont pas enregistres.

  Interface (adaptee a OS/2-0 : toutes les valeurs sont de 32 bits, les
  pointeurs sont des adresses lineaires ; convention _System) : la meme
  que HPFS.IFS (DLL/HPFS.PAS).

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
  (partie 13). Fonctions privees de FS_FSCTL : 8000h formater un volume
  (NTFS 3.1), 8001h verifier un volume (comme CHKDSK), 8002h
  statistiques.

  Organisation :
    Partie 1  - Constantes, types et variables
    Partie 2  - Services du noyau
    Partie 3  - Utilitaires (memoire, chaines, dates, noms, UTF-16)
    Partie 4  - Volumes et antememoire des secteurs
    Partie 5  - NTFS : enregistrements, runs et attributs
    Partie 6  - NTFS : noms, index des repertoires et montage
    Partie 7  - NTFS : bitmaps, attributs en ecriture, MFT
    Partie 8  - NTFS : ecriture des index, creation et suppression
    Partie 9  - Chemins
    Partie 10 - Formatage NTFS 3.1 et verification
    Partie 11 - Objets fichiers, verrous et notifications
    Partie 12 - Lecture et ecriture des donnees
    Partie 13 - Points d'entree FS_*
    Exportations et initialisation }

{$R-,S-,I-}
{$IMAGEBASE $00A60000}

{ ==================================================================== }
{ Partie 1 - Constantes, types et variables                            }
{ ==================================================================== }

Const
  { donnees exportees : nom du systeme de fichiers et attributs du pilote
    (FSA_LVL7 : NTFS est local, sans verrou de serveur) }
  FS_NAME      = 'NTFS';
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
  ERROR_CANNOT_COPY       = 266;
  ERROR_DIRECTORY         = 267;
  ERROR_EAS_NOT_SUPPORTED = 282;
  ERROR_TIMEOUT           = 640;

  { attributs DOS }
  ATTR_READONLY  = $01;
  ATTR_HIDDEN    = $02;
  ATTR_SYSTEM    = $04;
  ATTR_LABEL     = $08;
  ATTR_DIRECTORY = $10;
  ATTR_ARCHIVE   = $20;

  { FSH_DOVOLIO }
  DVIO_OPREAD    = 0;
  DVIO_OPWRITE   = 1;

  { signatures et attributs NTFS }
  REC_MAGIC   = $454C4946;  { 'FILE' }
  INDX_MAGIC  = $58444E49;  { 'INDX' }
  OEM_NTFS    = $5346544E;  { 'NTFS' en +3 du secteur d'amorce }
  AT_STDINFO  = $10;
  AT_ATTRLIST = $20;
  AT_FILENAME = $30;
  AT_VOLNAME  = $60;
  AT_VOLINFO  = $70;
  AT_DATA     = $80;
  AT_IDXROOT  = $90;
  AT_IDXALLOC = $A0;
  AT_BITMAP   = $B0;
  FA_DIR      = $10000000;  { indicateur repertoire de $FILE_NAME }
  ROOT_REC    = 5;          { enregistrement de la racine }
  FIRST_USER  = 16;         { premiers enregistrements : fichiers systeme }

  MaxVol   = 8;
  MaxRuns  = 2048;          { runs par attribut }
  RunBytes = 24576;         { MaxRuns * 12 }
  CacheMax = 128;           { antememoire : 128 secteurs au plus }
  MaxObj   = 32;            { fichiers ouverts (objets) }
  MaxOpen  = 64;            { ouvertures (SFT) }
  MaxFind  = 32;
  MaxLock  = 64;
  MaxNote  = 8;
  MaxLog   = 64;

  { page de codes 850 -> UNICODE (caracteres 128 a 255) }
  Cp850Hi : Array[0..127] Of Word = (
    $00C7, $00FC, $00E9, $00E2, $00E4, $00E0, $00E5, $00E7, $00EA, $00EB, $00E8, $00EF,
    $00EE, $00EC, $00C4, $00C5, $00C9, $00E6, $00C6, $00F4, $00F6, $00F2, $00FB, $00F9,
    $00FF, $00D6, $00DC, $00F8, $00A3, $00D8, $00D7, $0192, $00E1, $00ED, $00F3, $00FA,
    $00F1, $00D1, $00AA, $00BA, $00BF, $00AE, $00AC, $00BD, $00BC, $00A1, $00AB, $00BB,
    $2591, $2592, $2593, $2502, $2524, $00C1, $00C2, $00C0, $00A9, $2563, $2551, $2557,
    $255D, $00A2, $00A5, $2510, $2514, $2534, $252C, $251C, $2500, $253C, $00E3, $00C3,
    $255A, $2554, $2569, $2566, $2560, $2550, $256C, $00A4, $00F0, $00D0, $00CA, $00CB,
    $00C8, $0131, $00CD, $00CE, $00CF, $2518, $250C, $2588, $2584, $00A6, $00CC, $2580,
    $00D3, $00DF, $00D4, $00D2, $00F5, $00D5, $00B5, $00FE, $00DE, $00DA, $00DB, $00D9,
    $00FD, $00DD, $00AF, $00B4, $00AD, $00B1, $2017, $00BE, $00B6, $00A7, $00F7, $00B8,
    $00B0, $00A8, $00B7, $00B9, $00B3, $00B2, $25A0, $00A0);

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

  TVol = Record
    Used     : Boolean;
    Mounted  : Boolean;     { NTFS reconnu (sinon : accepte pour formatage) }
    HVpb     : LongInt;
    TotSec   : LongInt;
    Drive    : LongInt;
    PVpfsi   : LongInt;
    Serial   : LongInt;
    Dirty    : Boolean;     { modifie depuis le dernier vidage }
    WasDirty : Boolean;     { volume mal ferme au montage ($Volume) }
    LogDone  : Boolean;     { $LogFile deja vide depuis le montage }
    RO       : Boolean;     { lecture seule (version < 3, bitmaps absents) }
    Cb       : LongInt;     { octets par cluster }
    Spc      : LongInt;     { secteurs par cluster }
    RecSz    : LongInt;     { taille d'un enregistrement de la MFT }
    IdxSz    : LongInt;     { taille d'un bloc d'index }
    VcnSz    : LongInt;     { unite des VCN des blocs d'index }
    NClus    : LongInt;
    FreeClus : LongInt;
    MftLcn   : LongInt;
    MirrLcn  : LongInt;
    MirrN    : LongInt;     { enregistrements copies dans $MFTMirr }
    MftRA    : LongInt;     { runs de $MFT (tas) }
    MftRN    : LongInt;
    MftCap   : LongInt;     { runs que peut recevoir MftRA }
    RecN     : LongInt;     { enregistrements de la MFT }
    Bmp      : LongInt;     { $Bitmap en memoire (tas) }
    BmpLen   : LongInt;
    BmpRA    : LongInt;
    BmpRN    : LongInt;
    MBmp     : LongInt;     { bitmap de la MFT en memoire (tas) }
    MBmpLen  : LongInt;
    Upc      : LongInt;     { $UpCase (tas, 128 Ko) ou 0 }
    SecId    : LongInt;     { identifiant de securite des fichiers crees }
    Ver      : LongInt;     { version majeure }
    Hint     : LongInt;     { cluster de depart des recherches }
    IrB      : LongInt;     { taille des blocs d'index (racine) }
    IrC      : LongInt;     { clusters par bloc d'index }
  End;

  { fichier ouvert, partage par les ouvertures d'un meme enregistrement }
  TObj = Record
    Used     : Boolean;
    Vol      : LongInt;
    Rec      : LongInt;     { enregistrement de la MFT }
    Dir      : LongInt;     { enregistrement du repertoire parent }
    Name     : String;      { nom exact (page de codes 850) }
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
    Dots     : LongInt;     { 0 : rendre ".", 1 : "..", 2 : entrees, 3 fini, 4 nom exact }
    Pid      : LongInt;
    FPos     : LongInt;     { entrees rendues }
    Idx      : LongInt;     { prochaine entree de la liste }
    Gen      : LongInt;     { generation de la liste }
    LastN    : LongInt;     { dernier nom rendu (UTF-16, LastN caracteres) }
    LastU    : Array[0..255] Of Word;
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
  CacheData : LongInt;                 { CacheMax * 512 octets (tas) }
  CacheTick : LongInt;
  CacheHits, CacheMiss : LongInt;

  { entrees brutes d'un index (NtGather) : decalages dans NgBuf }
  NgN, NgBuf, NgCap, NgUsed, NgOff, NgOffCap : LongInt;
  { liste triee du repertoire en cours de recherche (copie de Ng) }
  LsVol, LsDir, LsN, LsBuf, LsCap, LsOff, LsOffCap, LsGen : LongInt;
  { runs de $DATA du fichier courant (ObjLoad) }
  RunRA, RunN, RunVol, RunRec, RunSize, RunInit, RunFlags : LongInt;
  RunRes    : Boolean;
  TmpRA     : LongInt;                 { runs temporaires (listes d'attributs) }

  { tampons de travail }
  IoBuf     : Array[0..511] Of Byte;   { secteur partiel des flux }
  SecBuf    : Array[0..511] Of Byte;
  ZeroBuf   : Array[0..4095] Of Byte;
  KeyBuf    : Array[0..519] Of Byte;   { nom cherche (UTF-16) }
  KeyLen    : LongInt;                 { en caracteres }
  DeOut     : Array[0..1023] Of Byte;  { entree d'index trouvee (copie) }
  DeOut2    : Array[0..1023] Of Byte;
  BigBuf    : Array[0..4095] Of Byte;  { copie de fichiers }
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
  ChkErrors, ChkLost, ChkDirs, ChkFiles, ChkRecs, ChkUsed, ChkMap, ChkRecMap : LongInt;
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

Procedure MoveMem(Src, Dst, N : LongInt);
Var PS, PD : PByte;
Begin
  If (N <= 0) Or (Src = 0) Or (Dst = 0) Then Exit;
  PS := Pointer(Src);
  PD := Pointer(Dst);
  Move(PS^, PD^, N);
End;

Procedure FillMem(Dst, N, V : LongInt);
Var PD : PByte;
Begin
  If (N <= 0) Or (Dst = 0) Then Exit;
  PD := Pointer(Dst);
  FillChar(PD^, N, V);
End;

{ Comparer N octets (multiple de 4) }
Function CompMem(A, B, N : LongInt) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := True;
  I := 0;
  While R And (I < N) Do
  Begin
    If RdL(A + I) <> RdL(B + I) Then R := False;
    I := I + 4;
  End;
  CompMem := R;
End;

{ Memoire du tas partage du noyau (tas 2 : jamais liberee a la fin d'un
  processus, le pilote sert tous les processus) ; mise a zero }
Function HAlloc(Size : LongInt) : LongInt;
Begin
  If Size < 16 Then Size := 16;
  HAlloc := KHeapAlloc(2, 8, Size);
End;

Procedure HFree(A : LongInt);
Begin
  If A <> 0 Then KHeapFree(2, 0, A);
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

Function Max(A, B : LongInt) : LongInt;
Begin
  If A > B Then Max := A Else Max := B;
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

{ --- page de codes 850 <-> UTF-16 --- }

Function C2U(C : LongInt) : LongInt;
Begin
  C := C And $FF;
  If C < 128 Then C2U := C Else C2U := Cp850Hi[C - 128];
End;

Function U2C(W : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  If W < 128 Then R := W
  Else
  Begin
    R := 95;                                     { '_' }
    For K := 0 To 127 Do
      If Cp850Hi[K] = W Then R := K + 128;
  End;
  U2C := R;
End;

{ Nom UTF-16 (A, N caracteres) -> chaine (page de codes 850) }
Function UName(A, N : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  If N > 255 Then N := 255;
  For K := 0 To N - 1 Do S := S + Chr(U2C(RdW(A + K * 2)));
  UName := S;
End;

{ Chaine (page 850) -> UTF-16 en A ; rend le nombre de caracteres }
Function PutUName(A : LongInt; S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrW(A + (K - 1) * 2, C2U(Ord(S[K])));
  PutUName := Length(S);
End;

{ Placer un nom dans KeyBuf (UTF-16) }
Procedure SetKey(S : String);
Begin
  KeyLen := PutUName(LongInt(@KeyBuf), S);
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

{ --- FILETIME (64 bits, centaines de nanosecondes depuis 1601) : calcul
  sur 4 mots de 16 bits (le compilateur n'a que des entiers de 32 bits) }

Const
  Ft1970 : Array[0..3] Of LongInt = ($9100, $B610, $0002, 0);  { 11644473600 s }

{ Secondes depuis 1970 -> FILETIME en A (8 octets) }
Procedure UnixToFt(T, A : LongInt);
Var W : Array[0..3] Of LongInt; I, C, X, M, K : LongInt;
Begin
  If T < 0 Then T := 0;
  W[0] := T And $FFFF; W[1] := (T Shr 16) And $FFFF; W[2] := 0; W[3] := 0;
  C := 0;
  For I := 0 To 3 Do
  Begin
    X := W[I] + Ft1970[I] + C;
    W[I] := X And $FFFF;
    C := X Shr 16;
  End;
  For K := 0 To 1 Do
  Begin
    If K = 0 Then M := 10000 Else M := 1000;
    C := 0;
    For I := 0 To 3 Do
    Begin
      X := W[I] * M + C;
      W[I] := X And $FFFF;
      C := X Shr 16;
    End;
  End;
  WrL(A, W[0] Or (W[1] Shl 16));
  WrL(A + 4, W[2] Or (W[3] Shl 16));
End;

{ FILETIME en A -> secondes depuis 1970 (0 avant 1970) }
Function FtToUnix(A : LongInt) : LongInt;
Var W : Array[0..3] Of LongInt; I, R, X, M, K, B : LongInt;
Begin
  W[0] := RdW(A); W[1] := RdW(A + 2); W[2] := RdW(A + 4); W[3] := RdW(A + 6);
  For K := 0 To 1 Do
  Begin
    If K = 0 Then M := 10000 Else M := 1000;
    R := 0;
    For I := 3 DownTo 0 Do
    Begin
      X := R * 65536 + W[I];
      W[I] := X Div M;
      R := X Mod M;
    End;
  End;
  B := 0;
  For I := 0 To 3 Do
  Begin
    X := W[I] - Ft1970[I] - B;
    If X < 0 Then
    Begin
      X := X + 65536;
      B := 1;
    End
    Else B := 0;
    W[I] := X;
  End;
  If B <> 0 Then FtToUnix := 0
  Else If (W[3] <> 0) Or (W[2] <> 0) Or (W[1] > $7FFF) Then FtToUnix := $7FFFFFFF
  Else FtToUnix := W[0] Or (W[1] Shl 16);
End;

{ --- noms de fichiers --- }

{ Nom valide pour NTFS (espace des noms Win32) : 1 a 255 caracteres, sans
  < > | " / \ : * ? ni caractere de controle ; rend un code d'erreur }
Function CheckName(S : String) : LongInt;
Var I, C, R : LongInt;
Begin
  R := NO_ERROR;
  If (Length(S) = 0) Or (S = '.') Or (S = '..') Then R := ERROR_INVALID_NAME
  Else
    For I := 1 To Length(S) Do
    Begin
      C := Ord(S[I]);
      If (C < 32) Or (C = 34) Or (C = 42) Or (C = 47) Or (C = 58) Or (C = 60) Or
         (C = 62) Or (C = 63) Or (C = 92) Or (C = 124) Then R := ERROR_INVALID_NAME;
    End;
  CheckName := R;
End;

{ Le nom respecte-t-il la forme 8.3 de FAT (en majuscules ASCII) ? Il
  est alors enregistre dans l'espace de noms "Win32 et DOS" (3), sinon
  dans l'espace POSIX (0), comme ntfs-3g (un nom Win32 seul (1) devrait
  etre accompagne d'un nom DOS (2) : Windows et ntfs-3g les cherchent
  ensemble) }
Function IsDosName(S : String) : Boolean;
Var I, P, C : LongInt; R : Boolean;
Begin
  R := Length(S) > 0;
  P := 0;
  For I := 1 To Length(S) Do
  Begin
    C := Ord(S[I]);
    If S[I] = '.' Then
    Begin
      If P > 0 Then R := False;
      P := I;
    End
    Else If (C <= 32) Or (C >= 127) Or ((C >= 97) And (C <= 122)) Or (C = 43) Or (C = 44) Or
            (C = 59) Or (C = 61) Or (C = 91) Or (C = 93) Then
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
  IsDosName := R;
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

Function Al8(N : LongInt) : LongInt;
Begin
  Al8 := (N + 7) And Not 7;
End;

{ ==================================================================== }
{ Partie 4 - Volumes et antememoire des secteurs                       }
{ ==================================================================== }
{ Les secteurs lus par petits groupes (enregistrements de la MFT, blocs
  d'index, bitmaps) passent par une petite antememoire a ecriture
  immediate (/CACHE:n Ko, 64 Ko au plus). Les lectures plus grandes (donnees
  des fichiers) sont faites directement ; toute ecriture met a jour les
  copies en antememoire. }

Function FindVol(HVpb : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxVol - 1 Do
    If Vols[I].Used And (Vols[I].HVpb = HVpb) Then R := I;
  FindVol := R;
End;

{ Volume NTFS monte (sinon -1) }
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

Procedure CacheDropVol(V : LongInt);
Var I : LongInt;
Begin
  For I := 0 To CacheMax - 1 Do
    If CacheVol[I] = V Then CacheVol[I] := -1;
  If RunVol = V Then RunVol := -1;
  If LsVol = V Then LsVol := -1;
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

Procedure MarkDirty(V : LongInt); Forward;

{ E/S de N secteurs relatifs au volume (Wr : ecriture) ; rend un code
  d'erreur }
Function SecIO(V, Sec, N, Addr : LongInt; Wr : Boolean) : LongInt;
Var I, C, R : LongInt;
Begin
  R := NO_ERROR;
  If Wr Then
  Begin
    MarkDirty(V);
    R := DevIO(V, DVIO_OPWRITE, Sec, N, Addr);
    For I := 0 To N - 1 Do
    Begin
      C := CacheFind(V, Sec + I);
      If C >= 0 Then
      Begin
        If R = NO_ERROR Then MoveMem(Addr + I * 512, CacheData + C * 512, 512)
        Else CacheVol[C] := -1;
      End;
    End;
  End
  Else If (CacheN = 0) Or (N > 8) Then R := DevIO(V, DVIO_OPREAD, Sec, N, Addr)
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
          R := DevIO(V, DVIO_OPREAD, Sec + I, 1, CacheData + C * 512);
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
          MoveMem(CacheData + C * 512, Addr + I * 512, 512);
        End;
      End;
  SecIO := R;
End;

{ E/S de secteurs (par groupes de 128) ; False en cas d'erreur }
Function NtIo(V, Lba, Cnt, Buf : LongInt; Wr : Boolean) : Boolean;
Var K, N : LongInt;
Begin
  NtIo := False;
  K := 0;
  While K < Cnt Do
  Begin
    N := Min(Cnt - K, 128);
    If SecIO(V, Lba + K, N, Buf + K * 512, Wr) <> NO_ERROR Then Exit;
    K := K + N;
  End;
  NtIo := True;
End;

Function NtClusIo(V, Lcn, N, Buf : LongInt; Wr : Boolean) : Boolean;
Begin
  NtClusIo := NtIo(V, Lcn * Vols[V].Spc, N * Vols[V].Spc, Buf, Wr);
End;

{ ==================================================================== }
{ Partie 5 - NTFS : enregistrements, runs et attributs                 }
{ ==================================================================== }
{ (Pasdows 95, VMM32.PAS partie 3c) Les enregistrements de la MFT et les
  blocs d'index sont proteges par des correctifs de secteurs : le dernier
  mot de chaque secteur est remplace sur le disque par le numero de
  sequence de mise a jour (USN), sa valeur reelle est gardee dans le
  tableau des correctifs. Un attribut non resident decrit ses donnees par
  une liste de runs (longueur, decalage de LCN signe) ; en memoire, les
  runs sont des triplets VCN, LCN (-1 : creux), longueur. }

{ Correctifs de secteurs : verification et restitution (lecture) }
Function NtUnfix(B, Size : LongInt) : Boolean;
Var UO, UC, Usn, I, P : LongInt;
Begin
  NtUnfix := False;
  UO := RdW(B + 4); UC := RdW(B + 6);
  If (UO < 8) Or (UO + UC * 2 > 1024) Then Exit;
  Usn := RdW(B + UO);
  For I := 1 To UC - 1 Do
    If I * 512 <= Size Then
    Begin
      P := B + I * 512 - 2;
      If RdW(P) <> Usn Then Exit;
      WrW(P, RdW(B + UO + I * 2));
    End;
  NtUnfix := True;
End;

{ Poser les correctifs avant l'ecriture (nouvel USN) }
Procedure NtFix(B, Size : LongInt);
Var UO, UC, Usn, I, P : LongInt;
Begin
  UO := RdW(B + 4); UC := RdW(B + 6);
  Usn := RdW(B + UO) + 1;
  If (Usn = 0) Or (Usn >= $FFFF) Then Usn := 1;
  WrW(B + UO, Usn);
  For I := 1 To UC - 1 Do
    If I * 512 <= Size Then
    Begin
      P := B + I * 512 - 2;
      WrW(B + UO + I * 2, RdW(P));
      WrW(P, Usn);
    End;
End;

{ Retirer les correctifs apres l'ecriture (le tampon redevient lisible) }
Procedure NtUnfixW(B, Size : LongInt);
Var UO, UC, I, P : LongInt;
Begin
  UO := RdW(B + 4); UC := RdW(B + 6);
  For I := 1 To UC - 1 Do
    If I * 512 <= Size Then
    Begin
      P := B + I * 512 - 2;
      WrW(P, RdW(B + UO + I * 2));
    End;
End;

{ ------------------------------------------------------------------ }
{ Runs (tableau de triplets VCN, LCN (-1 : creux), longueur)           }
{ ------------------------------------------------------------------ }

Function NtSigned(P, N : LongInt) : LongInt;
Var V, K : LongInt;
Begin
  V := 0;
  If N > 4 Then N := 4;
  For K := N - 1 DownTo 0 Do V := (V Shl 8) Or RdB(P + K);
  If (N < 4) And (N > 0) Then
    If (RdB(P + N - 1) And $80) <> 0 Then V := V - (1 Shl (8 * N));
  NtSigned := V;
End;

{ Ajouter les runs de l'attribut non resident At a (RA, RN) }
Function NtRunsDecode(At, RA : LongInt; Var RN : LongInt) : Boolean;
Var P, H, NL, NO, Len, Vcn, Lcn, E : LongInt;
Begin
  NtRunsDecode := False;
  P := At + RdW(At + $20);
  E := At + RdL(At + 4);
  Vcn := RdL(At + $10); Lcn := 0;
  While (P < E) And (RdB(P) <> 0) Do
  Begin
    H := RdB(P); NL := H And 15; NO := H Shr 4;
    If (NL = 0) Or (NL > 4) Or (RN >= MaxRuns) Then Exit;
    Len := NtSigned(P + 1, NL);
    If NL = 4 Then Len := RdL(P + 1);
    WrL(RA + RN * 12, Vcn);
    WrL(RA + RN * 12 + 8, Len);
    If NO = 0 Then WrL(RA + RN * 12 + 4, -1)
    Else
    Begin
      Lcn := Lcn + NtSigned(P + 1 + NL, NO);
      WrL(RA + RN * 12 + 4, Lcn);
    End;
    Inc(RN);
    Vcn := Vcn + Len;
    P := P + 1 + NL + NO;
  End;
  NtRunsDecode := True;
End;

{ LCN du VCN et nombre de clusters contigus ; False hors des runs }
Function NtVcnLcn(RA, RN, Vcn : LongInt; Var Lcn, Cnt : LongInt) : Boolean;
Var I, V0, L : LongInt; Found : Boolean;
Begin
  Found := False;
  I := 0;
  While (I < RN) And Not Found Do
  Begin
    V0 := RdL(RA + I * 12);
    L := RdL(RA + I * 12 + 8);
    If (Vcn >= V0) And (Vcn < V0 + L) Then
    Begin
      Lcn := RdL(RA + I * 12 + 4);
      If Lcn >= 0 Then Lcn := Lcn + Vcn - V0;
      Cnt := V0 + L - Vcn;
      Found := True;
    End;
    Inc(I);
  End;
  NtVcnLcn := Found;
End;

Function NtSigBytes(V : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 1;
  While (N < 4) And Not ((V >= -(1 Shl (8 * N - 1))) And (V < (1 Shl (8 * N - 1)))) Do Inc(N);
  NtSigBytes := N;
End;

{ Encoder les runs en Dst (0 : calculer seulement) ; rend la longueur
  (avec le 0 final) }
Function NtRunsEncode(RA, RN, Dst : LongInt) : LongInt;
Var I, P, Len, Lcn, Prev, D, NL, NO, K : LongInt;
Begin
  P := Dst; Prev := 0; D := 0;
  For I := 0 To RN - 1 Do
  Begin
    Len := RdL(RA + I * 12 + 8);
    Lcn := RdL(RA + I * 12 + 4);
    NL := NtSigBytes(Len);
    If Lcn < 0 Then NO := 0
    Else
    Begin
      D := Lcn - Prev;
      NO := NtSigBytes(D);
      Prev := Lcn;
    End;
    If Dst <> 0 Then
    Begin
      WrB(P, NL Or (NO Shl 4));
      For K := 0 To NL - 1 Do WrB(P + 1 + K, (Len Shr (8 * K)) And $FF);
      For K := 0 To NO - 1 Do WrB(P + 1 + NL + K, (D Shr (8 * K)) And $FF);
    End;
    P := P + 1 + NL + NO;
  End;
  If Dst <> 0 Then WrB(P, 0);
  NtRunsEncode := P - Dst + 1;
End;

{ Clusters couverts par les runs }
Function NtRunsLen(RA, RN : LongInt) : LongInt;
Begin
  If RN = 0 Then NtRunsLen := 0
  Else NtRunsLen := RdL(RA + (RN - 1) * 12) + RdL(RA + (RN - 1) * 12 + 8);
End;

{ Lire ou ecrire N octets a la position Off d'un flux non resident (par
  secteurs ; un secteur partiel est lu, modifie puis reecrit) }
Function NtStreamIo(V, RA, RN, Off, N, Buf : LongInt; Wr : Boolean) : Boolean;
Var Cb, Vcn, Co, L, Lcn, Cnt, Sec, So, K : LongInt;
Begin
  NtStreamIo := False;
  Cb := Vols[V].Cb;
  While N > 0 Do
  Begin
    Vcn := Off Div Cb; Co := Off Mod Cb;
    If Not NtVcnLcn(RA, RN, Vcn, Lcn, Cnt) Then Exit;
    If Cnt > 4096 Then Cnt := 4096;
    If Lcn < 0 Then
    Begin
      { creux : des zeros }
      If Wr Then Exit;
      L := Min(N, Cnt * Cb - Co);
      FillMem(Buf, L, 0);
    End
    Else
    Begin
      Sec := Lcn * Vols[V].Spc + Co Div 512;
      So := Co Mod 512;
      If (So = 0) And (N >= 512) Then
      Begin
        K := Min(N Div 512, (Cnt * Cb - Co) Div 512);
        If K > 128 Then K := 128;
        If Not NtIo(V, Sec, K, Buf, Wr) Then Exit;
        L := K * 512;
      End
      Else
      Begin
        L := Min(N, 512 - So);
        If Not NtIo(V, Sec, 1, LongInt(@IoBuf), False) Then Exit;
        If Wr Then
        Begin
          MoveMem(Buf, LongInt(@IoBuf) + So, L);
          If Not NtIo(V, Sec, 1, LongInt(@IoBuf), True) Then Exit;
        End
        Else MoveMem(LongInt(@IoBuf) + So, Buf, L);
      End;
    End;
    Off := Off + L; Buf := Buf + L; N := N - L;
  End;
  NtStreamIo := True;
End;

{ ------------------------------------------------------------------ }
{ Enregistrements de la MFT                                            }
{ ------------------------------------------------------------------ }

Function NtReadRec(V, N, Buf : LongInt) : Boolean;
Begin
  NtReadRec := False;
  If (N < 0) Or (N >= Vols[V].RecN) Then Exit;
  If Not NtStreamIo(V, Vols[V].MftRA, Vols[V].MftRN, N * Vols[V].RecSz, Vols[V].RecSz, Buf, False) Then Exit;
  If RdL(Buf) <> REC_MAGIC Then Exit;
  NtReadRec := NtUnfix(Buf, Vols[V].RecSz);
End;

Procedure RunInval(V, N : LongInt);
Begin
  If (RunVol = V) And (RunRec = N) Then RunVol := -1;
End;

Function NtWriteRec(V, N, Buf : LongInt) : Boolean;
Var Ok : Boolean; RS : LongInt;
Begin
  RunInval(V, N);
  RS := Vols[V].RecSz;
  NtFix(Buf, RS);
  Ok := NtStreamIo(V, Vols[V].MftRA, Vols[V].MftRN, N * RS, RS, Buf, True);
  { $MFTMirr : copie des premiers enregistrements (4, ou un cluster) }
  If Ok And (N < Vols[V].MirrN) And (Vols[V].MirrLcn > 0) Then
    NtIo(V, Vols[V].MirrLcn * Vols[V].Spc + (N * RS) Div 512, RS Div 512, Buf, True);
  NtUnfixW(Buf, RS);
  NtWriteRec := Ok;
End;

{ ------------------------------------------------------------------ }
{ Attributs                                                            }
{ ------------------------------------------------------------------ }

Function NtAttrNameIs(P : LongInt; Const Nm : String) : Boolean;
Var K, A : LongInt; R : Boolean;
Begin
  R := RdB(P + 9) = Length(Nm);
  If R Then
  Begin
    A := P + RdW(P + 10);
    For K := 1 To Length(Nm) Do
      If RdW(A + (K - 1) * 2) <> Ord(Nm[K]) Then R := False;
  End;
  NtAttrNameIs := R;
End;

{ Attribut suivant (apres P, ou le premier si P = 0) de type Typ et de nom
  Nm ('' : sans nom) dans l'enregistrement R ; 0 si absent }
Function NtAttrAfter(V, R, P, Typ : LongInt; Const Nm : String) : LongInt;
Var E, Res : LongInt; Done : Boolean;
Begin
  Res := 0;
  E := R + Vols[V].RecSz;
  If P = 0 Then P := R + RdW(R + $14)
  Else P := P + RdL(P + 4);
  Done := False;
  While (Not Done) And (P + 8 <= E) And (RdL(P) <> -1) And (RdL(P) <> 0) Do
  Begin
    If RdL(P + 4) <= 0 Then Done := True
    Else If (RdL(P) = Typ) And NtAttrNameIs(P, Nm) Then
    Begin
      Res := P;
      Done := True;
    End
    Else P := P + RdL(P + 4);
  End;
  NtAttrAfter := Res;
End;

Function NtAttr(V, R, Typ : LongInt; Const Nm : String) : LongInt;
Begin
  NtAttr := NtAttrAfter(V, R, 0, Typ, Nm);
End;

{ Valeur d'un attribut resident }
Function NtResVal(P : LongInt) : LongInt;
Begin
  NtResVal := P + RdW(P + $14);
End;

{ Taille des donnees d'un attribut (resident ou non) }
Function NtAttrSize(P : LongInt) : LongInt;
Begin
  If RdB(P + 8) = 0 Then NtAttrSize := RdL(P + $10)
  Else If (RdL(P + $34) <> 0) Or (RdL(P + $30) < 0) Then NtAttrSize := $7FFFFFFF  { 2 Go et plus }
  Else NtAttrSize := RdL(P + $30);
End;

{ Runs d'un attribut non resident de l'enregistrement de base R (numero
  N), en suivant la liste d'attributs ($20) ; RA recoit les runs, Size la
  taille (de l'extension de VCN 0), Res l'adresse de l'attribut s'il est
  resident dans R (0 sinon), Init la taille initialisee, Flags ses
  indicateurs (compression, chiffrement). False si absent. }
Function NtGetAttrX(V, N, R, Typ : LongInt; Const Nm : String; RA : LongInt;
                    Var RN, Size, Res, Init, Flags : LongInt) : Boolean;
Var P, L, LA, LS, Q, E, T, Ref, X, LRN, Ext, K : LongInt; Found : Boolean; S : String;
Begin
  NtGetAttrX := False;
  RN := 0; Size := 0; Res := 0; Init := 0; Flags := 0;
  L := NtAttr(V, R, AT_ATTRLIST, '');
  If (L = 0) Or (Typ = AT_ATTRLIST) Then
  Begin
    P := NtAttr(V, R, Typ, Nm);
    If P = 0 Then Exit;
    Flags := RdW(P + $0C);
    If RdB(P + 8) = 0 Then
    Begin
      Res := P;
      Size := RdL(P + $10);
      Init := Size;
    End
    Else
    Begin
      Size := NtAttrSize(P);
      Init := RdL(P + $38);
      If (RdL(P + $3C) <> 0) Or (Init < 0) Then Init := Size;
      If Not NtRunsDecode(P, RA, RN) Then Exit;
    End;
    NtGetAttrX := True;
    Exit;
  End;
  { liste d'attributs }
  LS := NtAttrSize(L);
  LA := HAlloc(LS + 16);
  If LA = 0 Then Exit;
  If RdB(L + 8) = 0 Then MoveMem(NtResVal(L), LA, LS)
  Else
  Begin
    LRN := 0;
    If (Not NtRunsDecode(L, TmpRA, LRN)) Or Not NtStreamIo(V, TmpRA, LRN, 0, LS, LA, False) Then
    Begin
      HFree(LA);
      Exit;
    End;
  End;
  Ext := HAlloc(Vols[V].RecSz);
  Found := False;
  Q := LA; E := LA + LS;
  While (Q + 26 <= E) And (RdW(Q + 4) > 0) Do
  Begin
    T := RdL(Q);
    S := '';
    For K := 0 To RdB(Q + 6) - 1 Do
      S := S + Chr(RdW(Q + RdB(Q + 7) + K * 2) And $FF);
    If (T = Typ) And (S = Nm) Then
    Begin
      Ref := RdL(Q + 16);
      If Ref = N Then X := R
      Else
      Begin
        X := 0;
        If Ext <> 0 Then
          If NtReadRec(V, Ref, Ext) Then X := Ext;
      End;
      If X <> 0 Then
      Begin
        P := NtAttr(V, X, Typ, Nm);
        While (P <> 0) And (RdW(P + 14) <> RdW(Q + 24)) Do
          P := NtAttrAfter(V, X, P, Typ, Nm);
        If P <> 0 Then
        Begin
          Found := True;
          If RdB(P + 8) = 0 Then
          Begin
            If X = R Then Res := P;
            Size := RdL(P + $10);
            Init := Size;
            Flags := RdW(P + $0C);
          End
          Else
          Begin
            If RdL(P + $10) = 0 Then
            Begin
              Size := RdL(P + $30);
              Init := RdL(P + $38);
              Flags := RdW(P + $0C);
            End;
            NtRunsDecode(P, RA, RN);
          End;
        End;
      End;
    End;
    Q := Q + RdW(Q + 4);
  End;
  If Ext <> 0 Then HFree(Ext);
  HFree(LA);
  NtGetAttrX := Found;
End;

Function NtGetAttr(V, N, R, Typ : LongInt; Const Nm : String; RA : LongInt;
                   Var RN, Size, Res : LongInt) : Boolean;
Var Init, Flags : LongInt;
Begin
  NtGetAttr := NtGetAttrX(V, N, R, Typ, Nm, RA, RN, Size, Res, Init, Flags);
End;

{ Lire tout le flux d'un attribut (resident ou non) dans un bloc du tas }
Function NtLoadAttr(V, N, R, Typ : LongInt; Const Nm : String; Var Size : LongInt) : LongInt;
Var RA, RN, Res, A : LongInt;
Begin
  NtLoadAttr := 0;
  RA := HAlloc(RunBytes);
  If RA = 0 Then Exit;
  If NtGetAttr(V, N, R, Typ, Nm, RA, RN, Size, Res) Then
  Begin
    A := HAlloc(Size + 16);
    If A <> 0 Then
    Begin
      If Res <> 0 Then MoveMem(NtResVal(Res), A, Size)
      Else If Not NtStreamIo(V, RA, RN, 0, Size, A, False) Then
      Begin
        HFree(A);
        A := 0;
      End;
    End;
    NtLoadAttr := A;
  End;
  HFree(RA);
End;

{ ==================================================================== }
{ Partie 6 - NTFS : noms, index des repertoires et montage             }
{ ==================================================================== }

{ Majuscule d'un caractere UTF-16 (table $UpCase du volume) }
Function NtUp(V, W : LongInt) : LongInt;
Begin
  If Vols[V].Upc <> 0 Then NtUp := RdW(Vols[V].Upc + W * 2)
  Else If (W >= 97) And (W <= 122) Then NtUp := W - 32
  Else NtUp := W;
End;

{ Comparaison sans tenir compte de la casse (majuscules puis longueur) :
  -1, 0 ou 1 }
Function NtCmpUp(V, A1, N1, A2, N2 : LongInt) : LongInt;
Var K, C1, C2, R, N : LongInt;
Begin
  R := 0;
  N := Min(N1, N2);
  K := 0;
  While (K < N) And (R = 0) Do
  Begin
    C1 := NtUp(V, RdW(A1 + K * 2)); C2 := NtUp(V, RdW(A2 + K * 2));
    If C1 < C2 Then R := -1
    Else If C1 > C2 Then R := 1;
    Inc(K);
  End;
  If R = 0 Then
  Begin
    If N1 < N2 Then R := -1
    Else If N1 > N2 Then R := 1;
  End;
  NtCmpUp := R;
End;

{ Ordre des noms dans un index $I30 : majuscules, longueur, puis casse
  exacte }
Function NtCollate(V, A1, N1, A2, N2 : LongInt) : LongInt;
Var K, C1, C2, R : LongInt;
Begin
  R := NtCmpUp(V, A1, N1, A2, N2);
  K := 0;
  While (R = 0) And (K < N1) Do
  Begin
    C1 := RdW(A1 + K * 2); C2 := RdW(A2 + K * 2);
    If C1 < C2 Then R := -1
    Else If C1 > C2 Then R := 1;
    Inc(K);
  End;
  NtCollate := R;
End;

{ Attributs DOS d'apres les indicateurs NTFS (FILE_ATTRIBUTE_*) }
Function DosAttr(Fl : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := Fl And $27;
  If (Fl And FA_DIR) <> 0 Then A := A Or ATTR_DIRECTORY;
  DosAttr := A;
End;

{ --- entree d'index trouvee (DeOut) : +0 reference (8 octets), +8
  longueur, +10 longueur de la cle, +12 indicateurs, +16 cle
  ($FILE_NAME : +0 parent, +8 creation, +10h modification, +18h
  changement, +20h acces, +28h taille allouee, +30h taille, +38h
  indicateurs, +40h longueur du nom, +41h espace de noms, +42h nom) --- }

Function DeKey : LongInt;
Begin
  DeKey := LongInt(@DeOut) + 16;
End;

Function DeRec : LongInt;
Begin
  DeRec := RdL(LongInt(@DeOut));
End;

Function DeAttr : LongInt;
Begin
  DeAttr := DosAttr(RdL(DeKey + $38));
End;

Function DeIsDir : Boolean;
Begin
  DeIsDir := (RdL(DeKey + $38) And FA_DIR) <> 0;
End;

Function DeSize : LongInt;
Begin
  If DeIsDir Then DeSize := 0 Else DeSize := RdL(DeKey + $30);
End;

Function DeName : String;
Begin
  DeName := UName(DeKey + $42, RdB(DeKey + $40));
End;

{ ------------------------------------------------------------------ }
{ Index des repertoires ($I30) : lecture                               }
{ ------------------------------------------------------------------ }

Procedure NtInval;
Begin
  LsVol := -1;
End;

Procedure NgReset;
Begin
  NgN := 0; NgUsed := 0;
End;

{ Ajouter une entree brute (reference 8 octets, cle) a la liste, a la
  position At (-1 : a la fin) }
Function NgAdd(RefLo, RefHi, Key, KLen, At : LongInt) : Boolean;
Var Need, NB, NO, I : LongInt;
Begin
  NgAdd := False;
  Need := 12 + KLen;
  If NgUsed + Need > NgCap Then
  Begin
    NB := HAlloc(NgCap * 2 + Need + 4096);
    If NB = 0 Then Exit;
    MoveMem(NgBuf, NB, NgUsed);
    HFree(NgBuf);
    NgBuf := NB; NgCap := NgCap * 2 + Need + 4096;
  End;
  If (NgN + 1) * 4 > NgOffCap Then
  Begin
    NO := HAlloc(NgN * 8 + 256);
    If NO = 0 Then Exit;
    MoveMem(NgOff, NO, NgN * 4);
    HFree(NgOff);
    NgOff := NO; NgOffCap := NgN * 8 + 256;
  End;
  WrL(NgBuf + NgUsed, RefLo);
  WrL(NgBuf + NgUsed + 4, RefHi);
  WrL(NgBuf + NgUsed + 8, KLen);
  MoveMem(Key, NgBuf + NgUsed + 12, KLen);
  If At < 0 Then At := NgN;
  For I := NgN DownTo At + 1 Do
    WrL(NgOff + I * 4, RdL(NgOff + (I - 1) * 4));
  WrL(NgOff + At * 4, NgUsed);
  NgUsed := NgUsed + Need;
  Inc(NgN);
  NgAdd := True;
End;

Function NgEnt(I : LongInt) : LongInt;
Begin
  NgEnt := NgBuf + RdL(NgOff + I * 4);
End;

Procedure NgDel(I : LongInt);
Var K : LongInt;
Begin
  For K := I To NgN - 2 Do
    WrL(NgOff + K * 4, RdL(NgOff + (K + 1) * 4));
  Dec(NgN);
End;

{ Lire le bloc d'index de VCN Sub dans un bloc du tas (0 si erreur) }
Function NtReadIndx(V, IaRA, IaRN, Sub : LongInt) : LongInt;
Var B : LongInt;
Begin
  B := HAlloc(Vols[V].IdxSz);
  If B <> 0 Then
    If Not NtStreamIo(V, IaRA, IaRN, Sub * Vols[V].VcnSz, Vols[V].IdxSz, B, False) Or
       (RdL(B) <> INDX_MAGIC) Or Not NtUnfix(B, Vols[V].IdxSz) Then
    Begin
      HFree(B);
      B := 0;
    End;
  NtReadIndx := B;
End;

{ Parcourir les entrees d'un noeud (entrees a partir de E) dans l'ordre et
  les ajouter a Ng }
Function NtWalk(V, E, Lim, IaRA, IaRN : LongInt; Depth : LongInt) : Boolean;
Var Fl, Len, KL, B, EO : LongInt; Ok, Done : Boolean;
Begin
  Ok := Depth <= 8;
  Done := Not Ok;
  While (Not Done) And (E + 16 <= Lim) Do
  Begin
    Len := RdW(E + 8); KL := RdW(E + 10); Fl := RdL(E + 12);
    If Len < 16 Then
    Begin
      Ok := False;
      Done := True;
    End
    Else
    Begin
      If (Fl And 1) <> 0 Then
      Begin
        B := NtReadIndx(V, IaRA, IaRN, RdL(E + Len - 8));
        If B = 0 Then Ok := False
        Else
        Begin
          EO := B + $18 + RdL(B + $18);
          If Not NtWalk(V, EO, B + $18 + RdL(B + $1C), IaRA, IaRN, Depth + 1) Then Ok := False;
          HFree(B);
        End;
      End;
      If (Fl And 2) <> 0 Then Done := True
      Else If Ok Then
      Begin
        If Not NgAdd(RdL(E), RdL(E + 4), E + 16, KL, -1) Then Ok := False;
        E := E + Len;
      End;
      If Not Ok Then Done := True;
    End;
  End;
  NtWalk := Ok;
End;

{ Enregistrement qui contient l'attribut Typ/Nm (VCN 0) d'un fichier a
  liste d'attributs (enregistrement de base N lu en R) ; -1 si absent }
Function NtAttrRecNo(V, N, R, Typ : LongInt; Const Nm : String) : LongInt;
Var L, LA, LS, Q, K, Res : LongInt; S : String;
Begin
  Res := -1;
  If NtAttr(V, R, Typ, Nm) <> 0 Then Res := N
  Else
  Begin
    L := NtAttr(V, R, AT_ATTRLIST, '');
    If L <> 0 Then
    Begin
      LA := NtLoadAttr(V, N, R, AT_ATTRLIST, '', LS);
      If LA <> 0 Then
      Begin
        Q := LA;
        While (Res < 0) And (Q + 26 <= LA + LS) And (RdW(Q + 4) > 0) Do
        Begin
          If (RdL(Q) = Typ) And (RdL(Q + 8) = 0) And (RdL(Q + 12) = 0) Then
          Begin
            S := '';
            For K := 0 To RdB(Q + 6) - 1 Do S := S + Chr(RdW(Q + RdB(Q + 7) + K * 2) And $FF);
            If S = Nm Then Res := RdL(Q + 16);
          End;
          Q := Q + RdW(Q + 4);
        End;
        HFree(LA);
      End;
    End;
  End;
  NtAttrRecNo := Res;
End;

{ $INDEX_ROOT $I30 du repertoire Dir (enregistrement de base lu en R) :
  adresse de l'attribut, dans R ou dans l'enregistrement d'extension lu
  en X (liste d'attributs) ; NX : enregistrement qui le contient ; 0 si
  absent }
Function NtIdxRoot(V, Dir, R, X : LongInt; Var NX : LongInt) : LongInt;
Var P : LongInt;
Begin
  NX := Dir;
  P := NtAttr(V, R, AT_IDXROOT, '$I30');
  If (P = 0) And (X <> 0) Then
  Begin
    NX := NtAttrRecNo(V, Dir, R, AT_IDXROOT, '$I30');
    If (NX >= 0) And (NX <> Dir) Then
      If NtReadRec(V, NX, X) Then P := NtAttr(V, X, AT_IDXROOT, '$I30');
  End;
  If P <> 0 Then
    If RdB(P + 8) <> 0 Then P := 0;
  NtIdxRoot := P;
End;

{ Toutes les entrees du repertoire Dir (enregistrement deja lu en R) }
Function NtGather(V, Dir, R : LongInt) : Boolean;
Var Ir, IaRA, IaRN, Sz, Res, H, X, NX : LongInt;
Begin
  NtGather := False;
  NgReset;
  X := HAlloc(Vols[V].RecSz);
  IaRA := HAlloc(RunBytes);
  If (X <> 0) And (IaRA <> 0) Then
  Begin
    Ir := NtIdxRoot(V, Dir, R, X, NX);
    If Ir <> 0 Then
    Begin
      Ir := NtResVal(Ir);
      IaRN := 0;
      NtGetAttr(V, Dir, R, AT_IDXALLOC, '$I30', IaRA, IaRN, Sz, Res);
      H := Ir + $10;
      NtGather := NtWalk(V, H + RdL(H), H + RdL(H + 4), IaRA, IaRN, 0);
    End;
  End;
  HFree(IaRA);
  HFree(X);
End;

{ Chercher le nom KeyBuf (KeyLen caracteres) dans le noeud d'entrees E ;
  l'entree trouvee est copiee dans DeOut }
Function NtFindIn(V, E, Lim, IaRA, IaRN, Depth : LongInt) : Boolean;
Var Fl, Len, C, K, B : LongInt; Done, R : Boolean;
Begin
  R := False;
  Done := Depth > 8;
  While (Not Done) And (E + 16 <= Lim) Do
  Begin
    Len := RdW(E + 8); Fl := RdL(E + 12);
    If Len < 16 Then Done := True
    Else
    Begin
      If (Fl And 2) = 0 Then
      Begin
        K := E + 16;
        C := NtCmpUp(V, LongInt(@KeyBuf), KeyLen, K + $42, RdB(K + $40));
        If C = 0 Then
        Begin
          MoveMem(E, LongInt(@DeOut), Min(Len, 1024));
          R := True;
          Done := True;
        End;
      End
      Else C := -1;
      If (Not Done) And (C < 0) Then
      Begin
        Done := True;
        If (Fl And 1) <> 0 Then
        Begin
          B := NtReadIndx(V, IaRA, IaRN, RdL(E + Len - 8));
          If B <> 0 Then
          Begin
            R := NtFindIn(V, B + $18 + RdL(B + $18), B + $18 + RdL(B + $1C), IaRA, IaRN, Depth + 1);
            HFree(B);
          End;
        End;
      End;
      E := E + Len;
    End;
  End;
  NtFindIn := R;
End;

{ Chercher le nom KeyBuf dans le repertoire Dir (arbre B+) ; DeOut }
Function NtLookup(V, Dir : LongInt) : Boolean;
Var R, Ir, IaRA, IaRN, Sz, Res, H, X, NX : LongInt; Ok : Boolean;
Begin
  Ok := False;
  R := HAlloc(Vols[V].RecSz * 2);
  IaRA := HAlloc(RunBytes);
  If (R <> 0) And (IaRA <> 0) Then
    If NtReadRec(V, Dir, R) Then
    Begin
      X := R + Vols[V].RecSz;
      Ir := NtIdxRoot(V, Dir, R, X, NX);
      If Ir <> 0 Then
      Begin
        IaRN := 0;
        NtGetAttr(V, Dir, R, AT_IDXALLOC, '$I30', IaRA, IaRN, Sz, Res);
        H := NtResVal(Ir) + $10;
        Ok := NtFindIn(V, H + RdL(H), H + RdL(H + 4), IaRA, IaRN, 0);
      End;
    End;
  HFree(IaRA);
  HFree(R);
  NtLookup := Ok;
End;

{ ------------------------------------------------------------------ }
{ Liste triee d'un repertoire (recherches FS_FINDFIRST/NEXT)           }
{ ------------------------------------------------------------------ }

Function LsEnt(I : LongInt) : LongInt;
Begin
  LsEnt := LsBuf + RdL(LsOff + I * 4);
End;

{ Construire la liste des entrees du repertoire Dir (sans les noms DOS
  des fichiers qui ont un nom long, ni les fichiers systeme) }
Function NtDirList(V, Dir : LongInt) : Boolean;
Var R, I, E, K : LongInt; Ok : Boolean;
Begin
  NtDirList := False;
  If (LsVol = V) And (LsDir = Dir) Then
  Begin
    NtDirList := True;
    Exit;
  End;
  LsVol := -1;
  R := HAlloc(Vols[V].RecSz);
  If R = 0 Then Exit;
  Ok := NtReadRec(V, Dir, R);
  If Ok Then Ok := (RdW(R + $16) And 2) <> 0;
  If Ok Then Ok := NtGather(V, Dir, R);
  HFree(R);
  If Not Ok Then Exit;
  If NgUsed + 16 > LsCap Then
  Begin
    HFree(LsBuf);
    LsCap := NgUsed + 4096;
    LsBuf := HAlloc(LsCap);
    If LsBuf = 0 Then
    Begin
      LsCap := 0;
      Exit;
    End;
  End;
  If (NgN + 1) * 4 > LsOffCap Then
  Begin
    HFree(LsOff);
    LsOffCap := (NgN + 1) * 4 + 256;
    LsOff := HAlloc(LsOffCap);
    If LsOff = 0 Then
    Begin
      LsOffCap := 0;
      Exit;
    End;
  End;
  MoveMem(NgBuf, LsBuf, NgUsed);
  LsN := 0;
  For I := 0 To NgN - 1 Do
  Begin
    E := NgEnt(I);
    K := E + 12;
    If (RdB(K + $41) <> 2) And (RdL(E) >= FIRST_USER) And (RdL(E + 8) >= $42) Then
    Begin
      WrL(LsOff + LsN * 4, RdL(NgOff + I * 4));
      Inc(LsN);
    End;
  End;
  LsVol := V; LsDir := Dir;
  Inc(LsGen);
  NtDirList := True;
End;

{ Copier l'entree I de la liste dans DeOut }
Procedure LsToDe(I : LongInt);
Var E, KL : LongInt;
Begin
  E := LsEnt(I);
  KL := Min(RdL(E + 8), 1000);
  FillMem(LongInt(@DeOut), 16, 0);
  WrL(LongInt(@DeOut), RdL(E));
  WrL(LongInt(@DeOut) + 4, RdL(E + 4));
  WrW(LongInt(@DeOut) + 8, Al8(16 + KL));
  WrW(LongInt(@DeOut) + 10, KL);
  MoveMem(E + 12, LongInt(@DeOut) + 16, KL);
End;

{ ------------------------------------------------------------------ }
{ Montage                                                              }
{ ------------------------------------------------------------------ }

Function BitCount(B : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  While B <> 0 Do
  Begin
    N := N + (B And 1);
    B := B Shr 1;
  End;
  BitCount := N;
End;

Function NtBmpGet(V, C : LongInt) : Boolean;
Begin
  NtBmpGet := (RdB(Vols[V].Bmp + C Shr 3) And (1 Shl (C And 7))) <> 0;
End;

{ Clusters libres d'apres le bitmap en memoire }
Function CountFree(V : LongInt) : LongInt;
Var I, N, Used, NB : LongInt; Cnt : Array[0..255] Of Byte;
Begin
  N := 0;
  If Vols[V].Bmp <> 0 Then
  Begin
    For I := 0 To 255 Do Cnt[I] := BitCount(I);
    NB := Vols[V].NClus Shr 3;
    If NB > Vols[V].BmpLen Then NB := Vols[V].BmpLen;
    Used := 0;
    For I := 0 To NB - 1 Do Used := Used + Cnt[RdB(Vols[V].Bmp + I)];
    For I := NB * 8 To Vols[V].NClus - 1 Do
      If (I Shr 3) < Vols[V].BmpLen Then
        If NtBmpGet(V, I) Then Inc(Used);
    N := Vols[V].NClus - Used;
  End;
  CountFree := N;
End;

{ Liberer la memoire d'un volume }
Procedure FreeVolMem(V : LongInt);
Var I : LongInt; Shared : Boolean;
Begin
  HFree(Vols[V].MftRA); Vols[V].MftRA := 0; Vols[V].MftCap := 0;
  HFree(Vols[V].Bmp); Vols[V].Bmp := 0;
  HFree(Vols[V].BmpRA); Vols[V].BmpRA := 0;
  HFree(Vols[V].MBmp); Vols[V].MBmp := 0;
  { la table $UpCase peut etre partagee avec un autre volume }
  Shared := False;
  For I := 0 To MaxVol - 1 Do
    If (I <> V) And (Vols[I].Upc = Vols[V].Upc) Then Shared := True;
  If Not Shared Then HFree(Vols[V].Upc);
  Vols[V].Upc := 0;
End;

{ Copie exacte (Cap runs de capacite) d'un tableau de runs }
Function RunsCopy(RA, RN, Cap : LongInt) : LongInt;
Var A : LongInt;
Begin
  If Cap < RN Then Cap := RN;
  A := HAlloc(Cap * 12 + 12);
  If A <> 0 Then MoveMem(RA, A, RN * 12);
  RunsCopy := A;
End;

{ Reconnaitre le volume V (secteur d'amorce en Boot) et charger ses
  parametres ; rend NO_ERROR si c'est un volume NTFS }
Function MountVol(V, Boot : LongInt) : LongInt;
Var A, R, C, Sz, Res, RN, Ret, Flg : LongInt; Ok : Boolean;
Begin
  Ret := ERROR_NOT_DOS_DISK;
  FreeVolMem(V);
  CacheDropVol(V);
  Ok := (RdL(Boot + 3) = OEM_NTFS) And (RdL(Boot + 7) = $20202020) And
        (RdW(Boot + 510) = $AA55) And (RdW(Boot + 11) = 512);
  If Ok Then
  Begin
    C := RdB(Boot + 13);
    Ok := (C > 0) And (C <= 128) And ((C And (C - 1)) = 0);
  End;
  If Ok Then
  Begin
    Vols[V].Spc := C;
    Vols[V].Cb := C * 512;
    If (RdL(Boot + $2C) <> 0) Or (RdL(Boot + $28) < 0) Then
    Begin
      Ok := False;
      Ret := ERROR_NOT_SUPPORTED;
    End;
  End;
  If Ok Then
  Begin
    Vols[V].NClus := RdL(Boot + $28) Div Vols[V].Spc;
    If RdL(Boot + $28) > Vols[V].TotSec Then Ok := False;
    Vols[V].MftLcn := RdL(Boot + $30);
    Vols[V].MirrLcn := RdL(Boot + $38);
    C := RdB(Boot + $40);
    If C < 128 Then Vols[V].RecSz := C * Vols[V].Cb Else Vols[V].RecSz := 1 Shl (256 - C);
    C := RdB(Boot + $44);
    If C < 128 Then Vols[V].IdxSz := C * Vols[V].Cb Else Vols[V].IdxSz := 1 Shl (256 - C);
    If Vols[V].IdxSz >= Vols[V].Cb Then Vols[V].VcnSz := Vols[V].Cb Else Vols[V].VcnSz := 512;
    Vols[V].Serial := RdL(Boot + $48);
    If (Vols[V].RecSz < 512) Or (Vols[V].RecSz > 4096) Or (Vols[V].IdxSz < 512) Or
       (Vols[V].IdxSz > 65536) Then Ok := False;
  End;
  R := 0;
  If Ok Then
  Begin
    { $MFT : enregistrement 0 lu directement, puis ses runs }
    Vols[V].MftRA := HAlloc(RunBytes);
    R := HAlloc(8192);
    Ok := (Vols[V].MftRA <> 0) And (R <> 0);
  End;
  If Ok Then
  Begin
    WrL(Vols[V].MftRA, 0);
    WrL(Vols[V].MftRA + 4, Vols[V].MftLcn);
    WrL(Vols[V].MftRA + 8, (Vols[V].RecSz + Vols[V].Cb - 1) Div Vols[V].Cb);
    Vols[V].MftRN := 1;
    Vols[V].RecN := 1;
    Vols[V].MirrN := 4;
    Ok := NtReadRec(V, 0, R);
  End;
  If Ok Then
  Begin
    RN := 0;
    Ok := NtGetAttr(V, 0, R, AT_DATA, '', Vols[V].MftRA, RN, Sz, Res);
    If Ok Then Ok := RN > 0;
  End;
  If Ok Then
  Begin
    Vols[V].MftRN := RN;
    Vols[V].RecN := Sz Div Vols[V].RecSz;
    { runs de la MFT : copie de la taille utile (+64 pour son extension) }
    A := RunsCopy(Vols[V].MftRA, RN, RN + 64);
    If A <> 0 Then
    Begin
      HFree(Vols[V].MftRA);
      Vols[V].MftRA := A;
      Vols[V].MftCap := RN + 64;
    End
    Else Vols[V].MftCap := MaxRuns;
    { bitmap de la MFT ($B0 de l'enregistrement 0) }
    Vols[V].MBmp := NtLoadAttr(V, 0, R, AT_BITMAP, '', Vols[V].MBmpLen);
    { $Volume : version et etat }
    Vols[V].Ver := 3;
    Vols[V].WasDirty := False;
    If NtReadRec(V, 3, R) Then
    Begin
      A := NtAttr(V, R, AT_VOLINFO, '');
      If A <> 0 Then
        If RdB(A + 8) = 0 Then
        Begin
          Vols[V].Ver := RdB(NtResVal(A) + 8);
          Flg := RdW(NtResVal(A) + $0A);
          Vols[V].WasDirty := (Flg And 1) <> 0;
        End;
    End;
    { $MFTMirr : nombre d'enregistrements copies }
    Vols[V].MirrN := 4;
    If Vols[V].Cb > 4 * Vols[V].RecSz Then Vols[V].MirrN := Vols[V].Cb Div Vols[V].RecSz;
    If NtReadRec(V, 1, R) Then
    Begin
      A := NtAttr(V, R, AT_DATA, '');
      If A <> 0 Then
        If (NtAttrSize(A) Div Vols[V].RecSz > 0) And (NtAttrSize(A) Div Vols[V].RecSz < 1024) Then
          Vols[V].MirrN := NtAttrSize(A) Div Vols[V].RecSz;
    End;
    { $UpCase }
    Vols[V].Upc := 0;
    If NtReadRec(V, 10, R) Then
    Begin
      Vols[V].Upc := NtLoadAttr(V, 10, R, AT_DATA, '', Sz);
      If (Vols[V].Upc <> 0) And (Sz < 131072) Then
      Begin
        HFree(Vols[V].Upc);
        Vols[V].Upc := 0;
      End;
      { meme table qu'un volume deja monte : partagee }
      If Vols[V].Upc <> 0 Then
        For C := 0 To MaxVol - 1 Do
          If (C <> V) And Vols[C].Used And (Vols[C].Upc <> 0) And (Vols[C].Upc <> Vols[V].Upc) Then
            If CompMem(Vols[C].Upc, Vols[V].Upc, 131072) Then
            Begin
              HFree(Vols[V].Upc);
              Vols[V].Upc := Vols[C].Upc;
            End;
    End;
    { $Bitmap : en memoire }
    Vols[V].BmpRA := HAlloc(RunBytes);
    Vols[V].Bmp := 0; Vols[V].BmpRN := 0; Vols[V].BmpLen := 0;
    If (Vols[V].BmpRA <> 0) And NtReadRec(V, 6, R) Then
    Begin
      RN := 0;
      If NtGetAttr(V, 6, R, AT_DATA, '', Vols[V].BmpRA, RN, Sz, Res) And (Res = 0) Then
      Begin
        Vols[V].BmpRN := RN; Vols[V].BmpLen := Sz;
        A := RunsCopy(Vols[V].BmpRA, RN, RN);
        If A <> 0 Then
        Begin
          HFree(Vols[V].BmpRA);
          Vols[V].BmpRA := A;
        End;
        Vols[V].Bmp := HAlloc(Sz + 16);
        If Vols[V].Bmp <> 0 Then
          If Not NtStreamIo(V, Vols[V].BmpRA, RN, 0, Sz, Vols[V].Bmp, False) Then
          Begin
            HFree(Vols[V].Bmp);
            Vols[V].Bmp := 0;
          End;
      End;
    End;
    Vols[V].FreeClus := CountFree(V);
    { racine : parametres d'index et identifiant de securite }
    Vols[V].SecId := 0; Vols[V].IrB := Vols[V].IdxSz; Vols[V].IrC := 1;
    Ok := NtReadRec(V, ROOT_REC, R);
    Flg := 0;
    If Ok Then Flg := NtIdxRoot(V, ROOT_REC, R, R + 4096, RN);
    Ok := Flg <> 0;
  End;
  If Ok Then
  Begin
    A := NtAttr(V, R, AT_STDINFO, '');
    If A <> 0 Then
      If RdL(A + $10) >= $38 Then Vols[V].SecId := RdL(NtResVal(A) + $34);
    Vols[V].IrB := RdL(NtResVal(Flg) + 8);
    Vols[V].IrC := RdB(NtResVal(Flg) + 12);
    Vols[V].RO := (Vols[V].Ver < 3) Or (Vols[V].Bmp = 0) Or (Vols[V].MBmp = 0);
    Vols[V].Hint := 0;
    Vols[V].Dirty := False;
    Vols[V].LogDone := False;
    Vols[V].Mounted := True;
    Ret := NO_ERROR;
  End
  Else
    FreeVolMem(V);
  HFree(R);
  NtInval;
  MountVol := Ret;
End;

{ Nom de volume ($VOLUME_NAME de $Volume) }
Function GetLabel(V : LongInt) : String;
Var R, A : LongInt; S : String;
Begin
  S := '';
  R := HAlloc(Vols[V].RecSz);
  If R <> 0 Then
  Begin
    If NtReadRec(V, 3, R) Then
    Begin
      A := NtAttr(V, R, AT_VOLNAME, '');
      If A <> 0 Then
        If RdB(A + 8) = 0 Then S := UName(NtResVal(A), RdL(A + $10) Div 2);
    End;
    HFree(R);
  End;
  GetLabel := S;
End;

{ ==================================================================== }
{ Partie 7 - NTFS : bitmaps, attributs en ecriture, MFT                }
{ ==================================================================== }

{ Ecrire les octets B0..B1 du bitmap en memoire (secteurs entiers) }
Procedure NtBmpSave(V, B0, B1 : LongInt);
Var S0, S1 : LongInt;
Begin
  S0 := (B0 Div 512) * 512;
  S1 := (B1 Div 512 + 1) * 512;
  If S1 > Vols[V].BmpLen Then S1 := Vols[V].BmpLen;
  If S1 > S0 Then
    NtStreamIo(V, Vols[V].BmpRA, Vols[V].BmpRN, S0, S1 - S0, Vols[V].Bmp + S0, True);
End;

Procedure NtBmpMark(V, C, N : LongInt; On : Boolean);
Var I, A, M : LongInt;
Begin
  If N <= 0 Then Exit;
  For I := C To C + N - 1 Do
  Begin
    A := Vols[V].Bmp + I Shr 3; M := 1 Shl (I And 7);
    If On Then
    Begin
      If (RdB(A) And M) = 0 Then Dec(Vols[V].FreeClus);
      WrB(A, RdB(A) Or M);
    End
    Else
    Begin
      If (RdB(A) And M) <> 0 Then Inc(Vols[V].FreeClus);
      WrB(A, RdB(A) And Not M);
    End;
  End;
  NtBmpSave(V, C Shr 3, (C + N - 1) Shr 3);
End;

{ Trouver et reserver au plus Want clusters contigus (a partir de Hint) }
Function NtAllocRun(V, Want, Hint : LongInt; Var Lcn, Len : LongInt) : Boolean;
Var C, N, Tot : LongInt; Done : Boolean;
Begin
  NtAllocRun := False;
  Tot := Vols[V].NClus;
  If (Hint < 0) Or (Hint >= Tot) Then Hint := 0;
  C := Hint; N := 0;
  Done := False;
  While (N < Tot) And Not Done Do
  Begin
    If ((C And 7) = 0) And (C + 8 <= Tot) And (RdB(Vols[V].Bmp + C Shr 3) = $FF) Then
    Begin
      C := C + 8; N := N + 8;
    End
    Else If NtBmpGet(V, C) Then
    Begin
      Inc(C); Inc(N);
    End
    Else Done := True;
    If C >= Tot Then C := 0;
  End;
  If Not Done Then Exit;
  Lcn := C; Len := 0;
  While (Len < Want) And (C + Len < Tot) And Not NtBmpGet(V, C + Len) Do
    Inc(Len);
  NtBmpMark(V, Lcn, Len, True);
  Vols[V].Hint := Lcn + Len;
  NtAllocRun := True;
End;

{ Ajouter des clusters jusqu'a Need au total }
Function NtExtend(V, RA : LongInt; Var RN : LongInt; Need : LongInt) : Boolean;
Var Have, Hint, L, N, Last : LongInt;
Begin
  NtExtend := False;
  Have := NtRunsLen(RA, RN);
  Hint := Vols[V].Hint;
  If RN > 0 Then
  Begin
    Last := RA + (RN - 1) * 12;
    If RdL(Last + 4) >= 0 Then Hint := RdL(Last + 4) + RdL(Last + 8);
  End;
  While Have < Need Do
  Begin
    If RN >= MaxRuns - 1 Then Exit;
    If Not NtAllocRun(V, Need - Have, Hint, L, N) Then Exit;
    If N = 0 Then Exit;
    Last := RA + (RN - 1) * 12;
    If (RN > 0) And (RdL(Last + 4) >= 0) And (RdL(Last + 4) + RdL(Last + 8) = L) Then
      WrL(Last + 8, RdL(Last + 8) + N)
    Else
    Begin
      WrL(RA + RN * 12, Have);
      WrL(RA + RN * 12 + 4, L);
      WrL(RA + RN * 12 + 8, N);
      Inc(RN);
    End;
    Have := Have + N;
    Hint := L + N;
  End;
  NtExtend := True;
End;

{ Liberer les clusters a partir du VCN Keep }
Procedure NtTruncRuns(V, RA : LongInt; Var RN : LongInt; Keep : LongInt);
Var I, V0, L, Lc, Cut : LongInt;
Begin
  I := RN - 1;
  While I >= 0 Do
  Begin
    V0 := RdL(RA + I * 12); Lc := RdL(RA + I * 12 + 4);
    L := RdL(RA + I * 12 + 8);
    If V0 + L <= Keep Then I := 0
    Else If V0 >= Keep Then
    Begin
      If Lc >= 0 Then NtBmpMark(V, Lc, L, False);
      RN := I;
    End
    Else
    Begin
      Cut := V0 + L - Keep;
      If Lc >= 0 Then NtBmpMark(V, Lc + L - Cut, Cut, False);
      WrL(RA + I * 12 + 8, L - Cut);
    End;
    Dec(I);
  End;
End;

Procedure NtFreeAllRuns(V, RA, RN : LongInt);
Var I : LongInt;
Begin
  For I := 0 To RN - 1 Do
    If RdL(RA + I * 12 + 4) >= 0 Then
      NtBmpMark(V, RdL(RA + I * 12 + 4), RdL(RA + I * 12 + 8), False);
End;

{ ------------------------------------------------------------------ }
{ Attributs dans un enregistrement                                     }
{ ------------------------------------------------------------------ }

Function NtAttrResize(V, R, P, NewLen : LongInt) : Boolean;
Var U, Old : LongInt;
Begin
  NtAttrResize := False;
  U := RdL(R + $18); Old := RdL(P + 4);
  If U - Old + NewLen > Vols[V].RecSz Then Exit;
  MoveMem(P + Old, P + NewLen, R + U - (P + Old));
  If NewLen > Old Then FillMem(P + Old, NewLen - Old, 0);
  WrL(P + 4, NewLen);
  WrL(R + $18, U - Old + NewLen);
  NtAttrResize := True;
End;

Procedure NtAttrDel(V, R, P : LongInt);
Var U, L : LongInt;
Begin
  U := RdL(R + $18); L := RdL(P + 4);
  MoveMem(P + L, P, R + U - (P + L));
  WrL(R + $18, U - L);
End;

{ Inserer un attribut (ordre : type puis nom) de longueur totale Len ;
  HdrLen : taille de l'en-tete sans le nom (18h resident, 40h non) }
Function NtAttrIns(V, R, Typ : LongInt; Const Nm : String; HdrLen, Len : LongInt) : LongInt;
Var P, E, U, K : LongInt; Done : Boolean;
Begin
  NtAttrIns := 0;
  U := RdL(R + $18);
  If U + Len > Vols[V].RecSz Then Exit;
  P := R + RdW(R + $14);
  E := R + Vols[V].RecSz;
  Done := False;
  While (Not Done) And (P + 8 <= E) And (RdL(P) <> -1) And (RdL(P) <> 0) Do
  Begin
    If (RdL(P) > Typ) Or ((RdL(P) = Typ) And (RdB(P + 9) > Length(Nm))) Then Done := True
    Else P := P + RdL(P + 4);
  End;
  MoveMem(P, P + Len, R + U - P);
  FillMem(P, Len, 0);
  WrL(P, Typ); WrL(P + 4, Len);
  WrB(P + 9, Length(Nm));
  WrW(P + 10, HdrLen);
  For K := 1 To Length(Nm) Do WrW(P + HdrLen + (K - 1) * 2, Ord(Nm[K]));
  WrW(P + 14, RdW(R + $28));
  WrW(R + $28, RdW(R + $28) + 1);
  WrL(R + $18, U + Len);
  NtAttrIns := P;
End;

Function NtAddRes(V, R, Typ : LongInt; Const Nm : String; VLen : LongInt) : LongInt;
Var P, VO : LongInt;
Begin
  VO := Al8($18 + Length(Nm) * 2);
  P := NtAttrIns(V, R, Typ, Nm, $18, Al8(VO + VLen));
  If P <> 0 Then
  Begin
    WrL(P + $10, VLen);
    WrW(P + $14, VO);
  End;
  NtAddRes := P;
End;

Function NtAddNonRes(V, R, Typ : LongInt; Const Nm : String) : LongInt;
Var P, RO : LongInt;
Begin
  RO := Al8($40 + Length(Nm) * 2);
  P := NtAttrIns(V, R, Typ, Nm, $40, RO + 8);
  If P <> 0 Then
  Begin
    WrB(P + 8, 1);
    WrW(P + $20, RO);
    WrL(P + $18, -1); WrL(P + $1C, -1);
  End;
  NtAddNonRes := P;
End;

{ Valeur residente : nouvelle longueur }
Function NtResSetLen(V, R, P, NewLen : LongInt) : Boolean;
Begin
  NtResSetLen := False;
  If Not NtAttrResize(V, R, P, Al8(RdW(P + $14) + NewLen)) Then Exit;
  WrL(P + $10, NewLen);
  NtResSetLen := True;
End;

{ Attribut non resident : runs et tailles }
Function NtSetRuns(V, R, P, RA, RN, DataSz, InitSz : LongInt) : Boolean;
Var L, Clus : LongInt;
Begin
  NtSetRuns := False;
  L := NtRunsEncode(RA, RN, 0);
  If Not NtAttrResize(V, R, P, Al8(RdW(P + $20) + L)) Then Exit;
  NtRunsEncode(RA, RN, P + RdW(P + $20));
  Clus := NtRunsLen(RA, RN);
  WrL(P + $10, 0); WrL(P + $14, 0);
  WrL(P + $18, Clus - 1);
  If Clus = 0 Then WrL(P + $1C, -1) Else WrL(P + $1C, 0);
  WrL(P + $28, Clus * Vols[V].Cb); WrL(P + $2C, 0);
  WrL(P + $30, DataSz); WrL(P + $34, 0);
  WrL(P + $38, InitSz); WrL(P + $3C, 0);
  NtSetRuns := True;
End;

{ ------------------------------------------------------------------ }
{ Bitmap et extension de la MFT                                        }
{ ------------------------------------------------------------------ }

{ Ecrire le bitmap de la MFT ($B0 de l'enregistrement 0) }
Function NtMBmpSave(V : LongInt) : Boolean;
Var R, P, RA, RN, Sz, Res : LongInt;
Begin
  NtMBmpSave := False;
  R := HAlloc(Vols[V].RecSz + RunBytes);
  If R = 0 Then Exit;
  RA := R + Vols[V].RecSz;
  If NtReadRec(V, 0, R) Then
  Begin
    P := NtAttr(V, R, AT_BITMAP, '');
    If P <> 0 Then
    Begin
      If RdB(P + 8) = 0 Then
      Begin
        MoveMem(Vols[V].MBmp, NtResVal(P), Min(RdL(P + $10), Vols[V].MBmpLen));
        NtMBmpSave := NtWriteRec(V, 0, R);
      End
      Else
      Begin
        RN := 0;
        If NtGetAttr(V, 0, R, AT_BITMAP, '', RA, RN, Sz, Res) Then
          NtMBmpSave := NtStreamIo(V, RA, RN, 0, Min(Sz, Vols[V].MBmpLen), Vols[V].MBmp, True);
      End;
    End;
  End;
  HFree(R);
End;

{ Enregistrement libre (en-tete seul) N en B }
Procedure NtEmptyRec(V, N, B : LongInt);
Begin
  FillMem(B, Vols[V].RecSz, 0);
  WrL(B, REC_MAGIC);
  WrW(B + 4, $30); WrW(B + 6, Vols[V].RecSz Div 512 + 1);
  WrW(B + $10, 1);
  WrW(B + $14, Al8($30 + 2 * RdW(B + 6)));
  WrL(B + $18, RdW(B + $14) + 8);
  WrL(B + $1C, Vols[V].RecSz);
  WrL(B + $2C, N);
  WrL(B + RdW(B + $14), -1);
End;

{ Ajouter 64 enregistrements a la MFT }
Function NtMftGrow(V : LongInt) : Boolean;
Var R, P, B, RA, RN, Clus, OldN, NewN, N, NB, BmRA, BmRN, Need : LongInt; Ok : Boolean;
Begin
  NtMftGrow := False;
  R := HAlloc(Vols[V].RecSz * 2 + RunBytes * 2);
  If R = 0 Then Exit;
  B := R + Vols[V].RecSz; RA := B + Vols[V].RecSz; BmRA := RA + RunBytes;
  Ok := NtReadRec(V, 0, R);
  P := 0;
  If Ok Then
  Begin
    P := NtAttr(V, R, AT_DATA, '');
    Ok := (P <> 0) And (NtAttr(V, R, AT_ATTRLIST, '') = 0);
    If Ok Then Ok := RdB(P + 8) <> 0;
  End;
  If Ok Then
  Begin
    OldN := Vols[V].RecN;
    NewN := OldN + 64;
    MoveMem(Vols[V].MftRA, RA, Vols[V].MftRN * 12);
    RN := Vols[V].MftRN;
    Clus := (NewN * Vols[V].RecSz + Vols[V].Cb - 1) Div Vols[V].Cb;
    Ok := NtExtend(V, RA, RN, Clus);
    If Ok And (RN > Vols[V].MftCap) Then
    Begin
      { place pour les nouveaux runs de la MFT }
      NB := RunsCopy(Vols[V].MftRA, Vols[V].MftRN, RN + 64);
      If NB <> 0 Then
      Begin
        HFree(Vols[V].MftRA);
        Vols[V].MftRA := NB;
        Vols[V].MftCap := RN + 64;
      End
      Else
      Begin
        NtTruncRuns(V, RA, RN, NtRunsLen(Vols[V].MftRA, Vols[V].MftRN));
        Ok := False;
      End;
    End;
  End;
  If Ok Then
  Begin
    { nouveaux enregistrements, libres }
    For N := OldN To NewN - 1 Do
    Begin
      NtEmptyRec(V, N, B);
      NtFix(B, Vols[V].RecSz);
      NtStreamIo(V, RA, RN, N * Vols[V].RecSz, Vols[V].RecSz, B, True);
    End;
    Ok := NtSetRuns(V, R, P, RA, RN, NewN * Vols[V].RecSz, NewN * Vols[V].RecSz);
  End;
  If Ok Then
  Begin
    { bitmap de la MFT : 8 octets de plus si besoin }
    Need := Al8((NewN + 7) Div 8);
    If Need > Vols[V].MBmpLen Then
    Begin
      NB := HAlloc(Need + 16);
      Ok := NB <> 0;
      If Ok Then
      Begin
        MoveMem(Vols[V].MBmp, NB, Vols[V].MBmpLen);
        P := NtAttr(V, R, AT_BITMAP, '');
        Ok := P <> 0;
      End;
      If Ok Then
      Begin
        If RdB(P + 8) = 0 Then
        Begin
          Ok := NtResSetLen(V, R, P, Need);
          If Ok Then MoveMem(NB, NtResVal(P), Need);
        End
        Else
        Begin
          BmRN := 0;
          NtRunsDecode(P, BmRA, BmRN);
          Ok := NtExtend(V, BmRA, BmRN, (Need + Vols[V].Cb - 1) Div Vols[V].Cb);
          If Ok Then Ok := NtSetRuns(V, R, P, BmRA, BmRN, Need, Need);
          If Ok Then NtStreamIo(V, BmRA, BmRN, 0, Need, NB, True);
        End;
      End;
      If Ok Then
      Begin
        HFree(Vols[V].MBmp);
        Vols[V].MBmp := NB; Vols[V].MBmpLen := Need;
      End
      Else HFree(NB);
    End;
  End;
  If Ok Then
  Begin
    { les runs servent a ecrire l'enregistrement 0 lui-meme }
    MoveMem(RA, Vols[V].MftRA, RN * 12);
    Vols[V].MftRN := RN;
    Vols[V].RecN := NewN;
    NtMftGrow := NtWriteRec(V, 0, R);
  End;
  HFree(R);
End;

{ Reserver un enregistrement libre de la MFT (a partir de 24) }
Function NtAllocRec(V : LongInt) : LongInt;
Var N, Tries, Res : LongInt; Done : Boolean;
Begin
  Res := -1;
  Done := False;
  Tries := 0;
  While (Not Done) And (Tries < 2) Do
  Begin
    N := 24;
    While (Not Done) And (N < Vols[V].RecN) And ((N Shr 3) < Vols[V].MBmpLen) Do
    Begin
      If (RdB(Vols[V].MBmp + N Shr 3) And (1 Shl (N And 7))) = 0 Then
      Begin
        WrB(Vols[V].MBmp + N Shr 3, RdB(Vols[V].MBmp + N Shr 3) Or (1 Shl (N And 7)));
        If NtMBmpSave(V) Then Res := N;
        Done := True;
      End;
      Inc(N);
    End;
    If Not Done Then
      If Not NtMftGrow(V) Then Done := True;
    Inc(Tries);
  End;
  NtAllocRec := Res;
End;

Procedure NtFreeRecBit(V, N : LongInt);
Begin
  If (N Shr 3) >= Vols[V].MBmpLen Then Exit;
  WrB(Vols[V].MBmp + N Shr 3, RdB(Vols[V].MBmp + N Shr 3) And Not (1 Shl (N And 7)));
  NtMBmpSave(V);
End;

{ ------------------------------------------------------------------ }
{ $LogFile et etat du volume                                           }
{ ------------------------------------------------------------------ }

{ Vider $LogFile (FFh) s'il contient un journal (comme ntfs-3g) }
Procedure NtLogReset(V : LongInt);
Var R, RA, RN, Sz, Res, B, Off, L, K : LongInt; Dirty, Ok : Boolean;
Begin
  R := HAlloc(Vols[V].RecSz + RunBytes + 65536);
  If R = 0 Then Exit;
  RA := R + Vols[V].RecSz; B := RA + RunBytes;
  RN := 0;
  If NtReadRec(V, 2, R) Then
    If NtGetAttr(V, 2, R, AT_DATA, '', RA, RN, Sz, Res) And (Res = 0) And (Sz > 4096) Then
      If NtStreamIo(V, RA, RN, 0, 4096, B, False) Then
      Begin
        Dirty := False;
        For K := 0 To 1023 Do If RdL(B + K * 4) <> -1 Then Dirty := True;
        If Dirty Then
        Begin
          FillMem(B, 65536, $FF);
          Off := 0;
          Ok := True;
          While Ok And (Off < Sz) Do
          Begin
            L := Min(65536, Sz - Off);
            Ok := NtStreamIo(V, RA, RN, Off, L, B, True);
            Off := Off + L;
          End;
        End;
      End;
  HFree(R);
End;

{ Indicateur "volume modifie" (bit 0 des indicateurs de
  $VOLUME_INFORMATION, enregistrement 3) }
Function SetVolDirty(V : LongInt; On : Boolean) : LongInt;
Var R, A, F, Ret : LongInt;
Begin
  Ret := ERROR_WRITE_FAULT;
  R := HAlloc(Vols[V].RecSz);
  If R <> 0 Then
  Begin
    If NtReadRec(V, 3, R) Then
    Begin
      A := NtAttr(V, R, AT_VOLINFO, '');
      If A <> 0 Then
        If RdB(A + 8) = 0 Then
        Begin
          F := RdW(NtResVal(A) + $0A);
          If On Then F := F Or 1 Else F := F And $FFFE;
          If F = RdW(NtResVal(A) + $0A) Then Ret := NO_ERROR
          Else
          Begin
            WrW(NtResVal(A) + $0A, F);
            If NtWriteRec(V, 3, R) Then Ret := NO_ERROR;
          End;
        End;
    End;
    HFree(R);
  End;
  SetVolDirty := Ret;
End;

{ Premiere modification du volume depuis son dernier vidage : journal
  vide (une fois par montage) et volume marque modifie }
Procedure MarkDirty(V : LongInt);
Begin
  If (V >= 0) And Vols[V].Mounted And Not Vols[V].Dirty Then
  Begin
    Vols[V].Dirty := True;
    If Not Vols[V].LogDone Then
    Begin
      Vols[V].LogDone := True;
      NtLogReset(V);
    End;
    SetVolDirty(V, True);
  End;
End;

Function FlushVol(V : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If Vols[V].Mounted And Vols[V].Dirty Then
  Begin
    R := SetVolDirty(V, False);
    If R = NO_ERROR Then Vols[V].Dirty := False;
  End;
  FlushVol := R;
End;

{ ==================================================================== }
{ Partie 8 - NTFS : ecriture des index, creation et suppression        }
{ ==================================================================== }
{ Les entrees de Ng (triees) sont reecrites a chaque modification :
  petit index dans $INDEX_ROOT si elles y tiennent, sinon arbre B+
  construit niveau par niveau (blocs INDX remplis, chaque bloc plein
  promouvant l'entree suivante au niveau superieur) jusqu'a ce que le
  dernier niveau tienne dans $INDEX_ROOT. }

Function NtEntSz(KL : LongInt; Sub : Boolean) : LongInt;
Begin
  If Sub Then NtEntSz := Al8(16 + KL) + 8 Else NtEntSz := Al8(16 + KL);
End;

Function NtKLen(KA, I : LongInt) : LongInt;
Begin
  NtKLen := RdL(NgEnt(RdL(KA + I * 4)) + 8);
End;

{ Taille des entrees I = A..B-1 (sous-noeud C[I]) et de l'entree de fin
  (sous-noeud C[B]) }
Function NtRangeSz(KA, CA, A, B : LongInt) : LongInt;
Var I, T : LongInt;
Begin
  T := 16;
  If RdL(CA + B * 4) >= 0 Then T := 24;
  For I := A To B - 1 Do
    T := T + NtEntSz(NtKLen(KA, I), RdL(CA + I * 4) >= 0);
  NtRangeSz := T;
End;

Function NtPutEntries(KA, CA, A, B, Dst : LongInt) : LongInt;
Var I, E, KL, L, P : LongInt; Sub : Boolean;
Begin
  P := Dst;
  For I := A To B - 1 Do
  Begin
    E := NgEnt(RdL(KA + I * 4)); KL := RdL(E + 8);
    Sub := RdL(CA + I * 4) >= 0;
    L := NtEntSz(KL, Sub);
    FillMem(P, L, 0);
    WrL(P, RdL(E)); WrL(P + 4, RdL(E + 4));
    WrW(P + 8, L); WrW(P + 10, KL);
    WrL(P + 12, Ord(Sub));
    MoveMem(E + 12, P + 16, KL);
    If Sub Then WrL(P + L - 8, RdL(CA + I * 4));
    P := P + L;
  End;
  Sub := RdL(CA + B * 4) >= 0;
  L := 16; If Sub Then L := 24;
  FillMem(P, L, 0);
  WrW(P + 8, L);
  WrL(P + 12, 2 Or Ord(Sub));
  If Sub Then WrL(P + 16, RdL(CA + B * 4));
  NtPutEntries := P + L - Dst;
End;

Function NtWriteNode(V, IaRA, IaRN, Vcn, KA, CA, A, B : LongInt) : Boolean;
Var Bf, EO, L, IS : LongInt;
Begin
  NtWriteNode := False;
  IS := Vols[V].IdxSz;
  Bf := HAlloc(IS);
  If Bf = 0 Then Exit;
  FillMem(Bf, IS, 0);
  WrL(Bf, INDX_MAGIC);
  WrW(Bf + 4, $28); WrW(Bf + 6, IS Div 512 + 1);
  WrL(Bf + $10, Vcn);
  EO := Al8($28 + 2 * RdW(Bf + 6));
  WrL(Bf + $18, EO - $18);
  L := NtPutEntries(KA, CA, A, B, Bf + EO);
  WrL(Bf + $1C, EO - $18 + L);
  WrL(Bf + $20, IS - $18);
  WrB(Bf + $24, Ord(RdL(CA + A * 4) >= 0));
  NtFix(Bf, IS);
  NtWriteNode := NtStreamIo(V, IaRA, IaRN, Vcn * Vols[V].VcnSz, IS, Bf, True);
  HFree(Bf);
End;

{ Construire les niveaux ; au retour KA/CA/N : sequence de la racine,
  Blocks : nombre de blocs INDX. Wr : ecrire les blocs. }
Function NtPack(V, IaRA, IaRN, RootAvail : LongInt; Wr, Force : Boolean;
                KA, CA, Tmp : LongInt; Var N, Blocks : LongInt) : Boolean;
Var I, St, Tot, Cap, NG, G, Vcn, ES, GA, GB, SP, NK, NC : LongInt;
    Child, Full, Res, Done : Boolean;
Begin
  Res := False; Done := False;
  N := NgN;
  For I := 0 To N - 1 Do WrL(KA + I * 4, I);
  For I := 0 To N Do WrL(CA + I * 4, -1);
  Blocks := 0;
  GA := Tmp; GB := GA + (NgN + 2) * 4; SP := GB + (NgN + 2) * 4;
  NK := SP + (NgN + 2) * 4; NC := NK + (NgN + 2) * 4;
  Cap := Vols[V].IdxSz - $40;
  Repeat
    If ((Blocks > 0) Or Not Force) And ($20 + NtRangeSz(KA, CA, 0, N) <= RootAvail) Then
    Begin
      Res := True;
      Done := True;
    End
    Else
    Begin
      Child := RdL(CA) >= 0;
      I := 0; NG := 0;
      While I < N Do
      Begin
        St := I;
        Tot := 16; If Child Then Tot := 24;
        Full := False;
        While (I < N) And Not Full Do
        Begin
          ES := NtEntSz(NtKLen(KA, I), Child);
          If Tot + ES > Cap Then Full := True
          Else
          Begin
            Tot := Tot + ES;
            Inc(I);
          End;
        End;
        If I = St Then Inc(I);
        WrL(GA + NG * 4, St); WrL(GB + NG * 4, I);
        If I < N Then
        Begin
          WrL(SP + NG * 4, I);
          Inc(I);
        End
        Else WrL(SP + NG * 4, -1);
        Inc(NG);
      End;
      If NG = 0 Then
      Begin
        { repertoire vide : un bloc vide }
        WrL(GA, 0); WrL(GB, 0); WrL(SP, -1);
        NG := 1;
      End;
      { le dernier element etait un separateur : pas de groupe a droite }
      G := NG - 1;
      If RdL(SP + G * 4) >= 0 Then
      Begin
        St := RdL(GA + G * 4); I := RdL(GB + G * 4);
        If I - St >= 2 Then
        Begin
          WrL(SP + G * 4, I - 1); WrL(GB + G * 4, I - 1);
          WrL(GA + NG * 4, I); WrL(GB + NG * 4, I + 1);
          WrL(SP + NG * 4, -1);
          Inc(NG);
        End
        Else
        Begin
          WrL(GB + G * 4, N);
          WrL(SP + G * 4, -1);
        End;
      End;
      G := 0;
      While (G < NG) And Not Done Do
      Begin
        Vcn := Blocks * (Vols[V].IdxSz Div Vols[V].VcnSz);
        Inc(Blocks);
        If Wr Then
          If Not NtWriteNode(V, IaRA, IaRN, Vcn, KA, CA, RdL(GA + G * 4), RdL(GB + G * 4)) Then
            Done := True;
        WrL(NC + G * 4, Vcn);
        If G < NG - 1 Then
          WrL(NK + G * 4, RdL(KA + RdL(SP + G * 4) * 4));
        Inc(G);
      End;
      If Not Done Then
      Begin
        N := NG - 1;
        For I := 0 To N - 1 Do WrL(KA + I * 4, RdL(NK + I * 4));
        For I := 0 To N Do WrL(CA + I * 4, RdL(NC + I * 4));
      End;
    End;
  Until Done Or (Blocks > 100000);
  NtPack := Res;
End;

Function NtWriteRoot(V, R, KA, CA, N, Large : LongInt) : Boolean;
Var IR, Vl, L : LongInt;
Begin
  NtWriteRoot := False;
  IR := NtAttr(V, R, AT_IDXROOT, '$I30');
  If IR = 0 Then Exit;
  If Not NtResSetLen(V, R, IR, $20 + NtRangeSz(KA, CA, 0, N)) Then Exit;
  Vl := NtResVal(IR);
  L := NtPutEntries(KA, CA, 0, N, Vl + $20);
  WrL(Vl + $10, $10);
  WrL(Vl + $14, $10 + L);
  WrL(Vl + $18, $10 + L);
  WrL(Vl + $1C, Large);
  NtWriteRoot := True;
End;

{ Reecrire l'index d'un repertoire avec Ng : RR enregistrement (numero
  NR) qui contient $INDEX_ROOT, AR (NA) celui qui contient
  $INDEX_ALLOCATION et $BITMAP (0 : absents). Split : repertoire a liste
  d'attributs (aucun attribut ne peut etre ajoute ni retire : l'index reste
  un grand index s'il l'etait) }
Function NtStoreIdx(V, NR, RR, NA, AR : LongInt; Split : Boolean) : Boolean;
Var IR, IA, BM, Base, RA, RN, KA, CA, Tmp, N, Blocks, Need, DSz, BmL, I, Bv, Avail : LongInt;
    Ok : Boolean;
Begin
  NtStoreIdx := False;
  IR := NtAttr(V, RR, AT_IDXROOT, '$I30');
  If IR = 0 Then Exit;
  IA := 0; BM := 0;
  If AR <> 0 Then
  Begin
    IA := NtAttr(V, AR, AT_IDXALLOC, '$I30'); BM := NtAttr(V, AR, AT_BITMAP, '$I30');
  End;
  If Split And ((IA = 0) <> (BM = 0)) Then Exit;
  Base := Vols[V].RecSz - RdL(RR + $18) + RdL(IR + 4) - RdW(IR + $14);
  If AR = RR Then
  Begin
    If IA <> 0 Then Base := Base + RdL(IA + 4);
    If BM <> 0 Then Base := Base + RdL(BM + 4);
  End;
  RA := HAlloc(RunBytes + (NgN + 2) * 4 * 7);
  If RA = 0 Then Exit;
  KA := RA + RunBytes; CA := KA + (NgN + 2) * 4;
  Tmp := CA + (NgN + 2) * 4;
  RN := 0;
  If IA <> 0 Then NtRunsDecode(IA, RA, RN);
  For I := 0 To NgN - 1 Do WrL(KA + I * 4, I);
  For I := 0 To NgN Do WrL(CA + I * 4, -1);
  If ($20 + NtRangeSz(KA, CA, 0, NgN) <= Base - 8) And ((Not Split) Or (IA = 0)) Then
  Begin
    { petit index : liberer l'allocation }
    If IA <> 0 Then
    Begin
      NtFreeAllRuns(V, RA, RN);
      NtAttrDel(V, RR, NtAttr(V, RR, AT_IDXALLOC, '$I30'));
    End;
    BM := NtAttr(V, RR, AT_BITMAP, '$I30');
    If BM <> 0 Then NtAttrDel(V, RR, BM);
    If NtWriteRoot(V, RR, KA, CA, NgN, 0) Then
      NtStoreIdx := NtWriteRec(V, NR, RR);
    HFree(RA);
    Exit;
  End;
  If Split And (IA = 0) Then
  Begin
    HFree(RA);
    Exit;
  End;
  { grand index }
  If AR = RR Then Avail := Base - 256 Else Avail := Base - 8;
  Ok := NtPack(V, RA, RN, Avail, False, Split, KA, CA, Tmp, N, Blocks);
  { racine reduite d'abord (place pour $INDEX_ALLOCATION et $BITMAP) ;
    elle est reecrite par NtWriteRoot }
  If Ok Then Ok := NtResSetLen(V, RR, IR, $38);
  If Ok Then
  Begin
    DSz := 0;
    If IA = 0 Then
    Begin
      AR := RR; NA := NR;
      IA := NtAddNonRes(V, AR, AT_IDXALLOC, '$I30');
      Ok := IA <> 0;
    End
    Else
    Begin
      IA := NtAttr(V, AR, AT_IDXALLOC, '$I30');
      DSz := RdL(IA + $30);
    End;
  End;
  If Ok Then
    If NtAttr(V, AR, AT_BITMAP, '$I30') = 0 Then
      Ok := NtAddRes(V, AR, AT_BITMAP, '$I30', 8) <> 0;
  If Ok Then
  Begin
    Need := (Blocks * Vols[V].IdxSz + Vols[V].Cb - 1) Div Vols[V].Cb;
    Ok := NtExtend(V, RA, RN, Need);
  End;
  If Ok Then
  Begin
    If Blocks * Vols[V].IdxSz > DSz Then DSz := Blocks * Vols[V].IdxSz;
    IA := NtAttr(V, AR, AT_IDXALLOC, '$I30');
    Ok := NtSetRuns(V, AR, IA, RA, RN, DSz, DSz);
  End;
  If Ok Then
  Begin
    BM := NtAttr(V, AR, AT_BITMAP, '$I30');
    BmL := Al8((DSz Div Vols[V].IdxSz + 7) Div 8);
    Ok := NtResSetLen(V, AR, BM, BmL);
  End;
  If Ok Then
  Begin
    Bv := NtResVal(BM);
    FillMem(Bv, BmL, 0);
    For I := 0 To Blocks - 1 Do
      WrB(Bv + I Shr 3, RdB(Bv + I Shr 3) Or (1 Shl (I And 7)));
    If NtPack(V, RA, RN, Avail, True, Split, KA, CA, Tmp, N, Blocks) Then
      If NtWriteRoot(V, RR, KA, CA, N, 1) Then
      Begin
        Ok := True;
        If AR <> RR Then Ok := NtWriteRec(V, NA, AR);
        If Ok Then NtStoreIdx := NtWriteRec(V, NR, RR);
      End;
  End;
  HFree(RA);
End;

{ Reecrire l'index du repertoire Dir (enregistrement de base en R) avec Ng }
Function NtStoreIndex(V, Dir, R : LongInt) : Boolean;
Var NR, NA, NB, RR, AR, X : LongInt; Ok : Boolean;
Begin
  If NtAttr(V, R, AT_ATTRLIST, '') = 0 Then NtStoreIndex := NtStoreIdx(V, Dir, R, Dir, R, False)
  Else
  Begin
    Ok := False;
    X := HAlloc(Vols[V].RecSz * 2);
    If X <> 0 Then
    Begin
      NR := NtAttrRecNo(V, Dir, R, AT_IDXROOT, '$I30');
      NA := NtAttrRecNo(V, Dir, R, AT_IDXALLOC, '$I30');
      NB := NtAttrRecNo(V, Dir, R, AT_BITMAP, '$I30');
      RR := 0; AR := 0;
      If NR = Dir Then RR := R
      Else If NR >= 0 Then
        If NtReadRec(V, NR, X) Then RR := X;
      If NA = Dir Then AR := R
      Else If NA = NR Then AR := RR
      Else If NA >= 0 Then
        If NtReadRec(V, NA, X + Vols[V].RecSz) Then AR := X + Vols[V].RecSz;
      If (RR <> 0) And (NA = NB) And ((NA < 0) Or (AR <> 0)) Then
        Ok := NtStoreIdx(V, NR, RR, NA, AR, True);
      HFree(X);
    End;
    NtStoreIndex := Ok;
  End;
End;

{ Position d'insertion du nom (Key + 42h, longueur Key + 40h) dans Ng }
Function NtInsPos(V, Key : LongInt) : LongInt;
Var I, E, R : LongInt;
Begin
  R := NgN;
  I := 0;
  While (I < NgN) And (R = NgN) Do
  Begin
    E := NgEnt(I) + 12;
    If NtCollate(V, Key + $42, RdB(Key + $40), E + $42, RdB(E + $40)) < 0 Then R := I;
    Inc(I);
  End;
  NtInsPos := R;
End;

{ Retirer du repertoire Dir les entrees de l'enregistrement N et, si Key
  <> 0, ajouter l'entree (N, Seq, Key) }
Function NtDirEdit(V, Dir, N, Seq, Key, KLen : LongInt) : Boolean;
Var R, I : LongInt;
Begin
  NtDirEdit := False;
  NtInval;
  R := HAlloc(Vols[V].RecSz);
  If R = 0 Then Exit;
  If NtReadRec(V, Dir, R) Then
    If NtGather(V, Dir, R) Then
    Begin
      For I := NgN - 1 DownTo 0 Do
        If RdL(NgEnt(I)) = N Then NgDel(I);
      If Key <> 0 Then NgAdd(N, Seq Shl 16, Key, KLen, NtInsPos(V, Key));
      NtDirEdit := NtStoreIndex(V, Dir, R);
    End;
  HFree(R);
  NtInval;
End;

{ ------------------------------------------------------------------ }
{ Mise a jour en place des entrees d'un fichier (dates, tailles,       }
{ attributs : la cle ne change pas de longueur ni de place)            }
{ ------------------------------------------------------------------ }

Var
  PtRec, PtFl, PtAlloc, PtSize, PtC, PtM, PtA : LongInt;
  PtMask : LongInt;   { 1 attributs, 2 tailles, 4 creation, 8 modification, 16 acces }

{ Mettre a jour une cle $FILE_NAME (K) d'apres Pt* }
Procedure PatchKey(K : LongInt);
Var Fl : LongInt;
Begin
  If (PtMask And 1) <> 0 Then
  Begin
    Fl := (RdL(K + $38) And Not $27) Or (PtFl And $27);
    WrL(K + $38, Fl);
  End;
  If (PtMask And 2) <> 0 Then
  Begin
    WrL(K + $28, PtAlloc); WrL(K + $2C, 0);
    WrL(K + $30, PtSize); WrL(K + $34, 0);
  End;
  If (PtMask And 4) <> 0 Then UnixToFt(PtC, K + $08);
  If (PtMask And 8) <> 0 Then
  Begin
    UnixToFt(PtM, K + $10);
    UnixToFt(PtM, K + $18);
  End;
  If (PtMask And 16) <> 0 Then UnixToFt(PtA, K + $20);
End;

{ Parcourir un noeud ; rend True si une entree a ete modifiee }
Function PatchNode(V, E, Lim, IaRA, IaRN, Depth : LongInt) : Boolean;
Var Fl, Len, B, Sub : LongInt; Ch, Done : Boolean;
Begin
  Ch := False;
  Done := Depth > 8;
  While (Not Done) And (E + 16 <= Lim) Do
  Begin
    Len := RdW(E + 8); Fl := RdL(E + 12);
    If Len < 16 Then Done := True
    Else
    Begin
      If (Fl And 1) <> 0 Then
      Begin
        Sub := RdL(E + Len - 8);
        B := NtReadIndx(V, IaRA, IaRN, Sub);
        If B <> 0 Then
        Begin
          If PatchNode(V, B + $18 + RdL(B + $18), B + $18 + RdL(B + $1C), IaRA, IaRN, Depth + 1) Then
          Begin
            NtFix(B, Vols[V].IdxSz);
            NtStreamIo(V, IaRA, IaRN, Sub * Vols[V].VcnSz, Vols[V].IdxSz, B, True);
          End;
          HFree(B);
        End;
      End;
      If (Fl And 2) <> 0 Then Done := True
      Else
      Begin
        If RdL(E) = PtRec Then
        Begin
          PatchKey(E + 16);
          Ch := True;
        End;
        E := E + Len;
      End;
    End;
  End;
  PatchNode := Ch;
End;

{ Mettre a jour les entrees de l'enregistrement PtRec dans le repertoire
  Dir }
Function NtPatchDir(V, Dir : LongInt) : Boolean;
Var R, Ir, IaRA, IaRN, Sz, Res, H, X, NX : LongInt; Ok : Boolean;
Begin
  Ok := False;
  NtInval;
  R := HAlloc(Vols[V].RecSz * 2);
  IaRA := HAlloc(RunBytes);
  If (R <> 0) And (IaRA <> 0) Then
    If NtReadRec(V, Dir, R) Then
    Begin
      X := R + Vols[V].RecSz;
      Ir := NtIdxRoot(V, Dir, R, X, NX);
      If Ir <> 0 Then
      Begin
        IaRN := 0;
        NtGetAttr(V, Dir, R, AT_IDXALLOC, '$I30', IaRA, IaRN, Sz, Res);
        H := NtResVal(Ir) + $10;
        If PatchNode(V, H + RdL(H), H + RdL(H + 4), IaRA, IaRN, 0) Then
        Begin
          If NX = Dir Then Ok := NtWriteRec(V, Dir, R) Else Ok := NtWriteRec(V, NX, X);
        End
        Else Ok := True;
      End;
    End;
  HFree(IaRA);
  HFree(R);
  NtPatchDir := Ok;
End;

{ ------------------------------------------------------------------ }
{ Fichiers et repertoires                                              }
{ ------------------------------------------------------------------ }

{ Cle $FILE_NAME (aussi valeur de l'attribut 30h) en K ; longueur. TP :
  4 FILETIME (creation, modification, changement, acces) }
Function NtKey(K, Parent, PSeq : LongInt; Const Name : String; Fl, Alloc, Size, TP : LongInt) : LongInt;
Var I : LongInt;
Begin
  FillMem(K, $42 + Length(Name) * 2, 0);
  WrL(K, Parent); WrW(K + 6, PSeq);
  For I := 0 To 3 Do
  Begin
    WrL(K + 8 + I * 8, RdL(TP + I * 8));
    WrL(K + 12 + I * 8, RdL(TP + 4 + I * 8));
  End;
  WrL(K + $28, Alloc); WrL(K + $30, Size);
  WrL(K + $38, Fl);
  WrB(K + $40, Length(Name));
  If IsDosName(Name) Then WrB(K + $41, 3) Else WrB(K + $41, 0);
  PutUName(K + $42, Name);
  NtKey := $42 + Length(Name) * 2;
End;

{ Creer le fichier ou repertoire Name dans Dir ; code d'erreur, NewN :
  l'enregistrement cree ; l'entree d'index creee est dans DeOut }
Function NtCreate(V, Dir : LongInt; Const Name : String; Attr : LongInt; IsDir : Boolean;
                  Var NewN : LongInt) : LongInt;
Var R, N, Seq, PSeq, P, K, KL, Fl, I, Now : LongInt;
    T : Array[0..7] Of LongInt;
Begin
  NtCreate := ERROR_DISK_FULL;
  NewN := -1;
  If Vols[V].RO Then
  Begin
    NtCreate := ERROR_WRITE_PROTECT;
    Exit;
  End;
  If (Length(Name) = 0) Or (Length(Name) > 255) Then
  Begin
    NtCreate := ERROR_INVALID_NAME;
    Exit;
  End;
  R := HAlloc(Vols[V].RecSz + 1024);
  If R = 0 Then
  Begin
    NtCreate := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  K := R + Vols[V].RecSz;
  If Not NtReadRec(V, Dir, R) Then
  Begin
    NtCreate := ERROR_PATH_NOT_FOUND;
    HFree(R);
    Exit;
  End;
  PSeq := RdW(R + $10);
  N := NtAllocRec(V);
  If N < 0 Then
  Begin
    HFree(R);
    Exit;
  End;
  Seq := 1;
  If NtStreamIo(V, Vols[V].MftRA, Vols[V].MftRN, N * Vols[V].RecSz, Vols[V].RecSz, R, False) Then
    If (RdL(R) = REC_MAGIC) And (RdW(R + $10) > 0) Then
      Seq := RdW(R + $10);
  Now := NowUnix;
  For I := 0 To 3 Do UnixToFt(Now, LongInt(@T) + I * 8);
  { en-tete }
  NtEmptyRec(V, N, R);
  WrW(R + $10, Seq); WrW(R + $12, 1);
  If IsDir Then WrW(R + $16, 3) Else WrW(R + $16, 1);
  { $STANDARD_INFORMATION }
  P := NtAddRes(V, R, AT_STDINFO, '', $48);
  MoveMem(LongInt(@T), NtResVal(P), 32);
  If IsDir Then Fl := Attr And $07 Else Fl := (Attr And $27) Or ATTR_ARCHIVE;
  WrL(NtResVal(P) + $20, Fl);
  WrL(NtResVal(P) + $34, Vols[V].SecId);
  { $FILE_NAME }
  If IsDir Then Fl := Fl Or FA_DIR;
  KL := NtKey(K, Dir, PSeq, Name, Fl, 0, 0, LongInt(@T));
  P := NtAddRes(V, R, AT_FILENAME, '', KL);
  WrB(P + $16, 1);
  MoveMem(K, NtResVal(P), KL);
  If IsDir Then
  Begin
    P := NtAddRes(V, R, AT_IDXROOT, '$I30', $30);
    WrL(NtResVal(P), AT_FILENAME); WrL(NtResVal(P) + 4, 1);
    WrL(NtResVal(P) + 8, Vols[V].IrB);
    WrB(NtResVal(P) + 12, Vols[V].IrC);
    WrL(NtResVal(P) + $10, $10); WrL(NtResVal(P) + $14, $20);
    WrL(NtResVal(P) + $18, $20);
    WrW(NtResVal(P) + $28, $10); WrL(NtResVal(P) + $2C, 2);
  End
  Else NtAddRes(V, R, AT_DATA, '', 0);
  If Not NtWriteRec(V, N, R) Then
  Begin
    NtFreeRecBit(V, N);
    NtCreate := ERROR_WRITE_FAULT;
    HFree(R);
    Exit;
  End;
  If Not NtDirEdit(V, Dir, N, Seq, K, KL) Then
  Begin
    WrW(R + $16, 0);
    NtWriteRec(V, N, R);
    NtFreeRecBit(V, N);
    HFree(R);
    Exit;
  End;
  { entree d'index creee (pour l'appelant) }
  FillMem(LongInt(@DeOut), 16, 0);
  WrL(LongInt(@DeOut), N);
  WrW(LongInt(@DeOut) + 6, Seq);
  WrW(LongInt(@DeOut) + 8, Al8(16 + KL));
  WrW(LongInt(@DeOut) + 10, KL);
  MoveMem(K, LongInt(@DeOut) + 16, KL);
  HFree(R);
  NewN := N;
  NtCreate := NO_ERROR;
End;

{ Liberer un enregistrement et ses clusters (extensions comprises) }
Procedure NtFreeRec(V, N, R : LongInt);
Var P, RA, RN, L, LS, LA, Q, Ref, X, Seq : LongInt;
Begin
  RA := HAlloc(RunBytes + Vols[V].RecSz);
  If RA = 0 Then Exit;
  X := RA + RunBytes;
  L := NtAttr(V, R, AT_ATTRLIST, '');
  If L <> 0 Then
  Begin
    LA := NtLoadAttr(V, N, R, AT_ATTRLIST, '', LS);
    If LA <> 0 Then
    Begin
      Q := LA;
      While (Q + 26 <= LA + LS) And (RdW(Q + 4) > 0) Do
      Begin
        Ref := RdL(Q + 16);
        If Ref <> N Then
          If NtReadRec(V, Ref, X) Then
            If (RdW(X + $16) And 1) <> 0 Then
            Begin
              P := X + RdW(X + $14);
              While (RdL(P) <> -1) And (RdL(P) > 0) Do
              Begin
                If RdB(P + 8) <> 0 Then
                Begin
                  RN := 0;
                  If NtRunsDecode(P, RA, RN) Then NtFreeAllRuns(V, RA, RN);
                End;
                P := P + RdL(P + 4);
              End;
              WrW(X + $16, 0);
              NtWriteRec(V, Ref, X);
              NtFreeRecBit(V, Ref);
            End;
        Q := Q + RdW(Q + 4);
      End;
      HFree(LA);
    End;
  End;
  P := R + RdW(R + $14);
  While (RdL(P) <> -1) And (RdL(P) > 0) Do
  Begin
    If RdB(P + 8) <> 0 Then
    Begin
      RN := 0;
      If NtRunsDecode(P, RA, RN) Then NtFreeAllRuns(V, RA, RN);
    End;
    P := P + RdL(P + 4);
  End;
  WrW(R + $16, 0);
  Seq := RdW(R + $10) + 1;
  If Seq > $FFFF Then Seq := 1;
  WrW(R + $10, Seq);
  NtWriteRec(V, N, R);
  NtFreeRecBit(V, N);
  HFree(RA);
End;

{ Supprimer le fichier ou le repertoire (vide) N du repertoire Dir }
Function NtRemove(V, Dir, N : LongInt; IsDir : Boolean) : LongInt;
Var R, Ret, P : LongInt;
Begin
  Ret := ERROR_ACCESS_DENIED;
  If Vols[V].RO Then
  Begin
    NtRemove := ERROR_WRITE_PROTECT;
    Exit;
  End;
  R := HAlloc(Vols[V].RecSz);
  If R = 0 Then
  Begin
    NtRemove := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  If NtReadRec(V, N, R) Then
  Begin
    Ret := NO_ERROR;
    { lien physique dans un autre repertoire : l'enregistrement est garde
      (non gere : refuse) }
    P := NtAttr(V, R, AT_FILENAME, '');
    While P <> 0 Do
    Begin
      If RdL(NtResVal(P)) <> Dir Then Ret := ERROR_ACCESS_DENIED;
      P := NtAttrAfter(V, R, P, AT_FILENAME, '');
    End;
    If (Ret = NO_ERROR) And IsDir Then
    Begin
      If Not NtGather(V, N, R) Then Ret := ERROR_ACCESS_DENIED
      Else If NgN > 0 Then Ret := ERROR_DIR_NOT_EMPTY;
    End;
    If Ret = NO_ERROR Then
      If Not NtDirEdit(V, Dir, N, 0, 0, 0) Then Ret := ERROR_ACCESS_DENIED;
    If Ret = NO_ERROR Then
    Begin
      { (relire : l'index de Dir peut etre dans le meme secteur) }
      If NtReadRec(V, N, R) Then NtFreeRec(V, N, R);
    End;
  End;
  HFree(R);
  NtInval;
  NtRemove := Ret;
End;

{ Renommer / deplacer l'enregistrement N du repertoire D1 vers D2 sous le
  nom Nm ; code d'erreur }
Function NtRename(V, N, D1, D2 : LongInt; Const Nm : String) : LongInt;
Var R, K, KL, P, Fl, Alloc, Size, PSeq, Seq, Si, Ret : LongInt; Dir : Boolean;
Begin
  Ret := ERROR_ACCESS_DENIED;
  If Vols[V].RO Then
  Begin
    NtRename := ERROR_WRITE_PROTECT;
    Exit;
  End;
  R := HAlloc(Vols[V].RecSz + 1024);
  If R = 0 Then
  Begin
    NtRename := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  K := R + Vols[V].RecSz;
  If NtReadRec(V, D2, R) Then
  Begin
    PSeq := RdW(R + $10);
    If NtReadRec(V, N, R) And (NtAttr(V, R, AT_ATTRLIST, '') = 0) Then
    Begin
      Seq := RdW(R + $10);
      Dir := (RdW(R + $16) And 2) <> 0;
      Si := NtAttr(V, R, AT_STDINFO, '');
      If Si <> 0 Then
      Begin
        Fl := RdL(NtResVal(Si) + $20) And $FFFF;
        If Dir Then Fl := Fl Or FA_DIR;
        Alloc := 0; Size := 0;
        P := NtAttr(V, R, AT_DATA, '');
        If P <> 0 Then
          If RdB(P + 8) = 0 Then
          Begin
            Size := RdL(P + $10);
            Alloc := Al8(Size);
          End
          Else
          Begin
            Alloc := RdL(P + $28); Size := RdL(P + $30);
          End;
        KL := NtKey(K, D2, PSeq, Nm, Fl, Alloc, Size, NtResVal(Si));
        P := NtAttr(V, R, AT_FILENAME, '');
        While P <> 0 Do
        Begin
          NtAttrDel(V, R, P);
          P := NtAttr(V, R, AT_FILENAME, '');
        End;
        P := NtAddRes(V, R, AT_FILENAME, '', KL);
        If P <> 0 Then
        Begin
          WrB(P + $16, 1);
          MoveMem(K, NtResVal(P), KL);
          WrW(R + $12, 1);
          If NtWriteRec(V, N, R) Then
          Begin
            If D1 <> D2 Then NtDirEdit(V, D1, N, 0, 0, 0);
            If NtDirEdit(V, D2, N, Seq, K, KL) Then Ret := NO_ERROR;
          End;
        End;
      End;
    End;
  End;
  HFree(R);
  NtInval;
  NtRename := Ret;
End;

{ Repertoire parent de l'enregistrement N (premier $FILE_NAME), -1 }
Function NtParent(V, N : LongInt) : LongInt;
Var R, P, Res : LongInt;
Begin
  Res := -1;
  R := HAlloc(Vols[V].RecSz);
  If R <> 0 Then
  Begin
    If NtReadRec(V, N, R) Then
    Begin
      P := NtAttr(V, R, AT_FILENAME, '');
      If P <> 0 Then Res := RdL(NtResVal(P));
    End;
    HFree(R);
  End;
  NtParent := Res;
End;

{ ==================================================================== }
{ Partie 9 - Chemins                                                   }
{ ==================================================================== }
{ Un chemin complet (D:\REP\NOM) est decoupe en composants (PComp) ;
  Walk parcourt les repertoires et laisse le repertoire parent du dernier
  composant dans WDir et son entree d'index (si elle existe) dans DeOut. }

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
Procedure RootDe;
Var K : LongInt;
Begin
  FillMem(LongInt(@DeOut), 16 + $42, 0);
  WrL(LongInt(@DeOut), ROOT_REC);
  WrW(LongInt(@DeOut) + 6, ROOT_REC);
  WrW(LongInt(@DeOut) + 8, 16 + $48);
  WrW(LongInt(@DeOut) + 10, $42);
  K := DeKey;
  WrL(K, ROOT_REC);
  WrL(K + $38, FA_DIR Or $06);
End;

Function Walk(V, A : LongInt) : LongInt;
Var I, Dir, R : LongInt;
Begin
  R := ParsePath(A);
  Dir := ROOT_REC;
  WFound := False;
  WIsRoot := False;
  I := 0;
  While (R = NO_ERROR) And (I < NComp - 1) Do
  Begin
    SetKey(PComp[I]);
    If HasWild(PComp[I]) Or (Length(PComp[I]) > 255) Then R := ERROR_PATH_NOT_FOUND
    Else If Not NtLookup(V, Dir) Then R := ERROR_PATH_NOT_FOUND
    Else If Not DeIsDir Then R := ERROR_PATH_NOT_FOUND
    Else Dir := DeRec;
    Inc(I);
  End;
  WDir := Dir;
  If R = NO_ERROR Then
  Begin
    If NComp = 0 Then
    Begin
      WIsRoot := True;
      WFound := True;
      RootDe;
    End
    Else If Length(LastComp) > 255 Then R := ERROR_FILENAME_EXCED_RANGE
    Else If Not HasWild(LastComp) Then
    Begin
      SetKey(LastComp);
      WFound := NtLookup(V, Dir);
    End;
  End;
  Walk := R;
End;

{ ==================================================================== }
{ Partie 10 - Formatage NTFS 3.1 et verification                       }
{ ==================================================================== }
{ (Pasdows 95, SETUP/INSTALL.PAS "Formatage NTFS 3.1") Clusters de 4 Ko,
  enregistrements de 1 Ko, blocs d'index de 4 Ko. Disposition : $Boot
  (clusters 0-1), $MFT (64 enregistrements), bitmap de la MFT, $LogFile
  (rempli de FFh), $AttrDef, $UpCase, $Secure:$SDS, $Bitmap, bloc d'index
  de la racine ; $MFTMirr au milieu du volume, copie du secteur d'amorce
  au dernier secteur. Les 64 enregistrements sont construits en memoire
  puis ecrits en une fois (avec les correctifs de secteurs). }
Const
  { table $UpCase : plages (debut, nombre, decalage, pas) (Pasdows 95, SETUP/INSTALL.PAS) }
  FmUpRuns : Array[0..535] Of LongInt = (
    97, 26, -32, 1, 224, 23, -32, 1, 248, 7, -32, 1, 255, 1, 121, 1, 257, 24,
    -1, 2, 307, 3, -1, 2, 314, 8, -1, 2, 331, 23, -1, 2, 378, 3, -1, 2, 384,
    1, 195, 1, 387, 2, -1, 2, 392, 1, -1, 1, 396, 1, -1, 1, 402, 1, -1, 1,
    405, 1, 97, 1, 409, 1, -1, 1, 410, 1, 163, 1, 414, 1, 130, 1, 417, 3, -1,
    2, 424, 1, -1, 1, 429, 1, -1, 1, 432, 1, -1, 1, 436, 2, -1, 2, 441, 1,
    -1, 1, 445, 1, -1, 1, 447, 1, 56, 1, 454, 1, -2, 1, 457, 1, -2, 1, 460,
    1, -2, 1, 462, 8, -1, 2, 477, 1, -79, 1, 479, 9, -1, 2, 499, 1, -2, 1,
    501, 1, -1, 1, 505, 20, -1, 2, 547, 9, -1, 2, 572, 1, -1, 1, 578, 1, -1,
    1, 583, 5, -1, 2, 592, 1, 10783, 1, 593, 1, 10780, 1, 595, 1, -210, 1,
    596, 1, -206, 1, 598, 2, -205, 1, 601, 1, -202, 1, 603, 1, -203, 1, 608,
    1, -205, 1, 611, 1, -207, 1, 616, 1, -209, 1, 617, 1, -211, 1, 619, 1,
    10743, 1, 623, 1, -211, 1, 625, 1, 10749, 1, 626, 1, -213, 1, 629, 1,
    -214, 1, 637, 1, 10727, 1, 640, 1, -218, 1, 643, 1, -218, 1, 648, 1,
    -218, 1, 649, 1, -69, 1, 650, 2, -217, 1, 652, 1, -71, 1, 658, 1, -219,
    1, 881, 2, -1, 2, 887, 1, -1, 1, 891, 3, 130, 1, 940, 1, -38, 1, 941, 3,
    -37, 1, 945, 17, -32, 1, 963, 9, -32, 1, 972, 1, -64, 1, 973, 2, -63, 1,
    983, 1, -8, 1, 985, 12, -1, 2, 1010, 1, 7, 1, 1016, 1, -1, 1, 1019, 1,
    -1, 1, 1072, 32, -32, 1, 1104, 16, -80, 1, 1121, 17, -1, 2, 1163, 27, -1,
    2, 1218, 7, -1, 2, 1231, 1, -15, 1, 1233, 42, -1, 2, 1377, 38, -48, 1,
    7545, 1, 35332, 1, 7549, 1, 3814, 1, 7681, 75, -1, 2, 7841, 48, -1, 2,
    7936, 8, 8, 1, 7952, 6, 8, 1, 7968, 8, 8, 1, 7984, 8, 8, 1, 8000, 6, 8,
    1, 8017, 4, 8, 2, 8032, 8, 8, 1, 8048, 2, 74, 1, 8050, 4, 86, 1, 8054, 2,
    100, 1, 8056, 2, 128, 1, 8058, 2, 112, 1, 8060, 2, 126, 1, 8064, 8, 8, 1,
    8080, 8, 8, 1, 8096, 8, 8, 1, 8112, 2, 8, 1, 8115, 1, 9, 1, 8131, 1, 9,
    1, 8144, 2, 8, 1, 8160, 2, 8, 1, 8165, 1, 7, 1, 8179, 1, 9, 1, 8526, 1,
    -28, 1, 8560, 16, -16, 1, 8580, 1, -1, 1, 9424, 26, -26, 1, 11312, 47,
    -48, 1, 11361, 1, -1, 1, 11365, 1, -10795, 1, 11366, 1, -10792, 1, 11368,
    3, -1, 2, 11379, 1, -1, 1, 11382, 1, -1, 1, 11393, 50, -1, 2, 11520, 38,
    -7264, 1, 42561, 16, -1, 2, 42595, 6, -1, 2, 42625, 12, -1, 2, 42787, 7,
    -1, 2, 42803, 31, -1, 2, 42874, 2, -1, 2, 42879, 5, -1, 2, 42892, 1, -1,
    1, 65345, 26, -32, 1);
  { $Secure : descripteurs ($SDS) et index $SDH, $SII (comme mkntfs) }
  FmSds : Array[0..255] Of Byte = (
    $F0, $12, $03, $F8, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $7C, $00, $00, $00, $01, $00, $04, $80, $48, $00, $00, $00,
    $58, $00, $00, $00, $00, $00, $00, $00, $14, $00, $00, $00, $02, $00,
    $34, $00, $02, $00, $00, $00, $00, $00, $14, $00, $89, $00, $12, $00,
    $01, $01, $00, $00, $00, $00, $00, $05, $12, $00, $00, $00, $00, $00,
    $18, $00, $89, $00, $12, $00, $01, $02, $00, $00, $00, $00, $00, $05,
    $20, $00, $00, $00, $20, $02, $00, $00, $01, $02, $00, $00, $00, $00,
    $00, $05, $20, $00, $00, $00, $20, $02, $00, $00, $01, $02, $00, $00,
    $00, $00, $00, $05, $20, $00, $00, $00, $20, $02, $00, $00, $00, $00,
    $00, $00, $51, $24, $B3, $00, $01, $01, $00, $00, $80, $00, $00, $00,
    $00, $00, $00, $00, $7C, $00, $00, $00, $01, $00, $04, $80, $48, $00,
    $00, $00, $58, $00, $00, $00, $00, $00, $00, $00, $14, $00, $00, $00,
    $02, $00, $34, $00, $02, $00, $00, $00, $00, $00, $14, $00, $9F, $01,
    $12, $00, $01, $01, $00, $00, $00, $00, $00, $05, $12, $00, $00, $00,
    $00, $00, $18, $00, $9F, $01, $12, $00, $01, $02, $00, $00, $00, $00,
    $00, $05, $20, $00, $00, $00, $20, $02, $00, $00, $01, $02, $00, $00,
    $00, $00, $00, $05, $20, $00, $00, $00, $20, $02, $00, $00, $01, $02,
    $00, $00, $00, $00, $00, $05, $20, $00, $00, $00, $20, $02, $00, $00,
    $00, $00, $00, $00);
  FmSdh : Array[0..143] Of Byte = (
    $00, $00, $00, $00, $12, $00, $00, $00, $00, $10, $00, $00, $01, $00,
    $00, $00, $10, $00, $00, $00, $80, $00, $00, $00, $80, $00, $00, $00,
    $00, $00, $00, $00, $18, $00, $14, $00, $00, $00, $00, $00, $30, $00,
    $08, $00, $00, $00, $00, $00, $51, $24, $B3, $00, $01, $01, $00, $00,
    $51, $24, $B3, $00, $01, $01, $00, $00, $80, $00, $00, $00, $00, $00,
    $00, $00, $7C, $00, $00, $00, $49, $00, $49, $00, $18, $00, $14, $00,
    $00, $00, $00, $00, $30, $00, $08, $00, $00, $00, $00, $00, $F0, $12,
    $03, $F8, $00, $01, $00, $00, $F0, $12, $03, $F8, $00, $01, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $7C, $00, $00, $00, $49, $00,
    $49, $00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $00, $00, $00,
    $02, $00, $00, $00);
  FmSii : Array[0..127] Of Byte = (
    $00, $00, $00, $00, $10, $00, $00, $00, $00, $10, $00, $00, $01, $00,
    $00, $00, $10, $00, $00, $00, $70, $00, $00, $00, $70, $00, $00, $00,
    $00, $00, $00, $00, $14, $00, $14, $00, $00, $00, $00, $00, $28, $00,
    $04, $00, $00, $00, $00, $00, $00, $01, $00, $00, $F0, $12, $03, $F8,
    $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $7C, $00,
    $00, $00, $14, $00, $14, $00, $00, $00, $00, $00, $28, $00, $04, $00,
    $00, $00, $00, $00, $01, $01, $00, $00, $51, $24, $B3, $00, $01, $01,
    $00, $00, $80, $00, $00, $00, $00, $00, $00, $00, $7C, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $10, $00, $00, $00, $02, $00,
    $00, $00);
  { $Quota ($O, $Q) et index vides ($ObjId:$O, $Reparse:$R) }
  FmQo : Array[0..87] Of Byte = (
    $00, $00, $00, $00, $11, $00, $00, $00, $00, $10, $00, $00, $01, $00,
    $00, $00, $10, $00, $00, $00, $48, $00, $00, $00, $48, $00, $00, $00,
    $00, $00, $00, $00, $20, $00, $04, $00, $00, $00, $00, $00, $28, $00,
    $10, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $05,
    $20, $00, $00, $00, $20, $02, $00, $00, $00, $01, $00, $00, $20, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $00, $00, $00,
    $02, $00, $00, $00);
  FmQq : Array[0..207] Of Byte = (
    $00, $00, $00, $00, $10, $00, $00, $00, $00, $10, $00, $00, $01, $00,
    $00, $00, $10, $00, $00, $00, $C0, $00, $00, $00, $C0, $00, $00, $00,
    $00, $00, $00, $00, $14, $00, $30, $00, $00, $00, $00, $00, $48, $00,
    $04, $00, $00, $00, $00, $00, $01, $00, $00, $00, $02, $00, $00, $00,
    $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $6B,
    $6A, $AB, $7C, $73, $DD, $01, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $14, $00, $40, $00, $00, $00, $00, $00,
    $58, $00, $04, $00, $00, $00, $00, $00, $00, $01, $00, $00, $02, $00,
    $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $6B, $6A, $AB, $7C, $73, $DD, $01, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00,
    $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $05, $20, $00,
    $00, $00, $20, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $10, $00, $00, $00, $02, $00, $00, $00);
  FmEmptyIx : Array[0..47] Of Byte = (
    $00, $00, $00, $00, $13, $00, $00, $00, $00, $10, $00, $00, $01, $00,
    $00, $00, $10, $00, $00, $00, $20, $00, $00, $00, $20, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $00,
    $00, $00, $02, $00, $00, $00);

Var
  { mise en page (LCN) du volume en cours de formatage }
  FmV, FmTot, FmC, FmNext, FmMftL, FmMBmpL, FmLogL, FmLogN, FmAdL, FmUpL, FmSdsL,
  FmSdsN, FmBmpL, FmBmpN, FmBmpLen, FmRootIx, FmMirr : LongInt;
  FmFt      : Array[0..1] Of LongInt;  { date de formatage (FILETIME) }
  FmMft     : LongInt;                 { 64 enregistrements (64 Ko, tas) }
  FmVal     : LongInt;                 { valeur d'attribut en construction (4 Ko) }
  FmCopy    : LongInt;                 { tampon d'ecriture (32 Ko) }
  FmIdx     : LongInt;                 { bloc d'index (4 Ko) }
  RBase, RPos, RId : LongInt;
  { entrees d'un repertoire en construction }
  KN        : LongInt;
  KRec, KSeq, KPar, KPSeq, KAll, KSiz, KFl : Array[0..23] Of LongInt;
  KNm       : Array[0..23] Of String[12];

{ Ecrire N secteurs (a partir du secteur S du volume) }
Function FmWrite(S, N, Addr : LongInt) : Boolean;
Var K, C : LongInt; Ok : Boolean;
Begin
  Ok := True;
  K := 0;
  While Ok And (K < N) Do
  Begin
    C := Min(N - K, 64);
    Ok := DevIO(FmV, DVIO_OPWRITE, S + K, C, Addr + K * 512) = NO_ERROR;
    K := K + C;
  End;
  FmWrite := Ok;
End;

Procedure PutFt(A : LongInt);
Begin
  WrL(A, FmFt[0]);
  WrL(A + 4, FmFt[1]);
End;

Function FmSigBytes(V : LongInt) : LongInt;
Begin
  If (V >= -128) And (V < 128) Then FmSigBytes := 1
  Else If (V >= -32768) And (V < 32768) Then FmSigBytes := 2
  Else If (V >= -8388608) And (V < 8388608) Then FmSigBytes := 3
  Else FmSigBytes := 4;
End;

{ ----- construction des enregistrements (en FmMft) ----- }

Procedure RInit(N, Seq, Flags, Links : LongInt);
Begin
  RBase := FmMft + N * 1024;
  FillMem(RBase, 1024, 0);
  WrL(RBase, REC_MAGIC);
  WrW(RBase + 4, $30); WrW(RBase + 6, 3);
  WrW(RBase + $10, Seq); WrW(RBase + $12, Links);
  WrW(RBase + $14, $38); WrW(RBase + $16, Flags);
  WrL(RBase + $1C, 1024);
  WrL(RBase + $2C, N);
  RPos := $38; RId := 0;
End;

Procedure RHdr(Typ : LongInt; Const Nm : String; Len : LongInt; NonRes : Boolean; HdrLen : LongInt);
Var I, P : LongInt;
Begin
  P := RBase + RPos;
  WrL(P, Typ); WrL(P + 4, Len);
  WrB(P + 8, Ord(NonRes));
  WrB(P + 9, Length(Nm));
  WrW(P + 10, HdrLen);
  WrW(P + 14, RId);
  For I := 1 To Length(Nm) Do WrW(P + HdrLen + (I - 1) * 2, Ord(Nm[I]));
End;

{ Attribut resident : valeur en FmVal (VLen octets) }
Procedure RRes(Typ : LongInt; Const Nm : String; VLen, Ix : LongInt);
Var VO, Len, P : LongInt;
Begin
  VO := Al8($18 + Length(Nm) * 2);
  Len := Al8(VO + VLen);
  RHdr(Typ, Nm, Len, False, $18);
  P := RBase + RPos;
  WrL(P + $10, VLen); WrW(P + $14, VO);
  WrB(P + $16, Ix);
  MoveMem(FmVal, P + VO, VLen);
  RPos := RPos + Len; Inc(RId);
End;

{ Attribut non resident a un run (Lcn < 0 : creux) ; tailles en octets
  (Hi : poids forts) }
Procedure RNonRes(Typ : LongInt; Const Nm : String; Lcn, Clus, AllocLo, AllocHi, SizeLo, SizeHi : LongInt);
Var RO, Len, P, Q, NL, NO, K : LongInt;
Begin
  RO := Al8($40 + Length(Nm) * 2);
  NL := FmSigBytes(Clus);
  If Lcn < 0 Then NO := 0 Else NO := FmSigBytes(Lcn);
  Len := Al8(RO + 1 + NL + NO + 1);
  RHdr(Typ, Nm, Len, True, $40);
  P := RBase + RPos;
  WrL(P + $18, Clus - 1);
  WrW(P + $20, RO);
  WrL(P + $28, AllocLo); WrL(P + $2C, AllocHi);
  WrL(P + $30, SizeLo); WrL(P + $34, SizeHi);
  WrL(P + $38, SizeLo); WrL(P + $3C, SizeHi);
  Q := P + RO;
  WrB(Q, NL Or (NO Shl 4));
  For K := 0 To NL - 1 Do WrB(Q + 1 + K, (Clus Shr (8 * K)) And $FF);
  For K := 0 To NO - 1 Do WrB(Q + 1 + NL + K, (Lcn Shr (8 * K)) And $FF);
  RPos := RPos + Len; Inc(RId);
End;

Procedure RDone;
Begin
  WrL(RBase + RPos, -1); WrL(RBase + RPos + 4, 0);
  WrL(RBase + $18, RPos + 8);
  WrW(RBase + $28, RId);
End;

{ $STANDARD_INFORMATION en FmVal ; longueur }
Function VSi(Fl, SecId : LongInt; Long : Boolean) : LongInt;
Var I : LongInt;
Begin
  FillMem(FmVal, 72, 0);
  For I := 0 To 3 Do PutFt(FmVal + I * 8);
  WrL(FmVal + $20, Fl);
  WrL(FmVal + $34, SecId);
  If Long Then VSi := 72 Else VSi := 48;
End;

{ $FILE_NAME (aussi cle d'index) en A ; longueur }
Function VFn(A, Parent, PSeq, AllocLo, SizeLo, Fl : LongInt; Const Nm : String; Ns : LongInt) : LongInt;
Var I : LongInt;
Begin
  FillMem(A, $42 + Length(Nm) * 2, 0);
  WrL(A, Parent); WrW(A + 6, PSeq);
  For I := 0 To 3 Do PutFt(A + 8 + I * 8);
  WrL(A + $28, AllocLo); WrL(A + $30, SizeLo);
  WrL(A + $38, Fl);
  WrB(A + $40, Length(Nm)); WrB(A + $41, Ns);
  For I := 1 To Length(Nm) Do WrW(A + $42 + (I - 1) * 2, Ord(Nm[I]));
  VFn := $42 + Length(Nm) * 2;
End;

{ ----- entrees des repertoires ----- }

Procedure KAdd(Rec, Seq, Parent, PSeq, AllocLo, SizeLo, Fl : LongInt; Const Nm : String);
Begin
  If KN > 23 Then Exit;
  KRec[KN] := Rec; KSeq[KN] := Seq; KPar[KN] := Parent; KPSeq[KN] := PSeq;
  KAll[KN] := AllocLo; KSiz[KN] := SizeLo; KFl[KN] := Fl; KNm[KN] := Nm;
  Inc(KN);
End;

{ Ordre $I30 : majuscules puis longueur puis casse exacte }
Function KLess(A, B : LongInt) : Boolean;
Var I, N, CA, CB : LongInt; R, Done : Boolean;
Begin
  R := False; Done := False;
  N := Min(Length(KNm[A]), Length(KNm[B]));
  I := 1;
  While (I <= N) And Not Done Do
  Begin
    CA := Upper[Ord(KNm[A][I])]; CB := Upper[Ord(KNm[B][I])];
    If CA <> CB Then
    Begin
      R := CA < CB;
      Done := True;
    End;
    Inc(I);
  End;
  If Not Done Then
  Begin
    If Length(KNm[A]) <> Length(KNm[B]) Then R := Length(KNm[A]) < Length(KNm[B])
    Else R := KNm[A] < KNm[B];
  End;
  KLess := R;
End;

{ Entrees triees de K* en Dst (avec l'entree de fin) ; longueur }
Function KPut(Dst : LongInt) : LongInt;
Var Ord0 : Array[0..23] Of LongInt; I, J, T, K, P, KL, L : LongInt;
Begin
  For I := 0 To KN - 1 Do Ord0[I] := I;
  For I := 1 To KN - 1 Do
  Begin
    J := I;
    While (J > 0) And KLess(Ord0[J], Ord0[J - 1]) Do
    Begin
      T := Ord0[J]; Ord0[J] := Ord0[J - 1]; Ord0[J - 1] := T;
      Dec(J);
    End;
  End;
  P := Dst;
  For I := 0 To KN - 1 Do
  Begin
    K := Ord0[I];
    KL := VFn(P + 16, KPar[K], KPSeq[K], KAll[K], KSiz[K], KFl[K], KNm[K], 3);
    L := Al8(16 + KL);
    WrL(P, KRec[K]); WrW(P + 4, 0); WrW(P + 6, KSeq[K]);
    WrW(P + 8, L); WrW(P + 10, KL); WrL(P + 12, 0);
    P := P + L;
  End;
  FillMem(P, 16, 0);
  WrW(P + 8, 16); WrL(P + 12, 2);
  KPut := P + 16 - Dst;
End;

{ $INDEX_ROOT d'un grand index (entree de fin -> bloc 0) en FmVal }
Function VBigRoot : LongInt;
Begin
  FillMem(FmVal, $38, 0);
  WrL(FmVal, AT_FILENAME); WrL(FmVal + 4, 1); WrL(FmVal + 8, 4096);
  WrB(FmVal + 12, 1);
  WrL(FmVal + $10, $10); WrL(FmVal + $14, $28); WrL(FmVal + $18, $28);
  WrB(FmVal + $1C, 1);
  WrW(FmVal + $28, 24); WrL(FmVal + $2C, 3); WrL(FmVal + $30, 0);
  VBigRoot := $38;
End;

{ Correctifs de secteurs du bloc B de Size octets (USN 1) }
Procedure Protect(B, Size : LongInt);
Var UO, I : LongInt;
Begin
  UO := B + RdW(B + 4);
  WrW(UO, 1);
  For I := 1 To Size Div 512 Do
  Begin
    WrW(UO + I * 2, RdW(B + I * 512 - 2));
    WrW(B + I * 512 - 2, 1);
  End;
End;

{ Bloc INDX (VCN 0) des entrees K* en FmIdx, ecrit au cluster Lcn }
Function WriteIndx(Lcn : LongInt) : Boolean;
Var L : LongInt;
Begin
  FillMem(FmIdx, 4096, 0);
  WrL(FmIdx, INDX_MAGIC);
  WrW(FmIdx + 4, $28); WrW(FmIdx + 6, 9);
  L := KPut(FmIdx + $40);
  WrL(FmIdx + $18, $28); WrL(FmIdx + $1C, $28 + L);
  WrL(FmIdx + $20, 4096 - $18);
  Protect(FmIdx, 4096);
  WriteIndx := FmWrite(Lcn * 8, 8, FmIdx);
End;

{ ----- donnees ----- }

Function FmAlloc(Clus : LongInt) : LongInt;
Begin
  FmAlloc := FmNext;
  FmNext := FmNext + Clus;
End;

{ Ecrire Clus clusters remplis de B a partir de Lcn }
Function FmFill(Lcn, Clus, B : LongInt) : Boolean;
Var N : LongInt; Ok : Boolean;
Begin
  FillMem(FmCopy, 32768, B);
  Ok := True;
  While Ok And (Clus > 0) Do
  Begin
    N := Min(Clus, 8);
    Ok := FmWrite(Lcn * 8, N * 8, FmCopy);
    Lcn := Lcn + N; Clus := Clus - N;
  End;
  FmFill := Ok;
End;

{ $AttrDef (2560 octets) en FmCopy }
Procedure GenAttrDef;
Var I, K, P, T, Fl, Mn, Mx : LongInt; Nm : String;
Begin
  FillMem(FmCopy, 4096, 0);
  For K := 0 To 14 Do
  Begin
    Case K Of
      0 : Begin Nm := '$STANDARD_INFORMATION'; T := $10; Fl := $40; Mn := 48; Mx := 72; End;
      1 : Begin Nm := '$ATTRIBUTE_LIST'; T := $20; Fl := $80; Mn := 0; Mx := -1; End;
      2 : Begin Nm := '$FILE_NAME'; T := $30; Fl := $42; Mn := 68; Mx := 578; End;
      3 : Begin Nm := '$OBJECT_ID'; T := $40; Fl := $40; Mn := 0; Mx := 256; End;
      4 : Begin Nm := '$SECURITY_DESCRIPTOR'; T := $50; Fl := $80; Mn := 0; Mx := -1; End;
      5 : Begin Nm := '$VOLUME_NAME'; T := $60; Fl := $40; Mn := 2; Mx := 256; End;
      6 : Begin Nm := '$VOLUME_INFORMATION'; T := $70; Fl := $40; Mn := 12; Mx := 12; End;
      7 : Begin Nm := '$DATA'; T := $80; Fl := 0; Mn := 0; Mx := -1; End;
      8 : Begin Nm := '$INDEX_ROOT'; T := $90; Fl := $40; Mn := 0; Mx := -1; End;
      9 : Begin Nm := '$INDEX_ALLOCATION'; T := $A0; Fl := $80; Mn := 0; Mx := -1; End;
      10 : Begin Nm := '$BITMAP'; T := $B0; Fl := $80; Mn := 0; Mx := -1; End;
      11 : Begin Nm := '$REPARSE_POINT'; T := $C0; Fl := $80; Mn := 0; Mx := 16384; End;
      12 : Begin Nm := '$EA_INFORMATION'; T := $D0; Fl := $40; Mn := 8; Mx := 8; End;
      13 : Begin Nm := '$EA'; T := $E0; Fl := 0; Mn := 0; Mx := 65536; End;
    Else
      Begin Nm := '$LOGGED_UTILITY_STREAM'; T := $100; Fl := $80; Mn := 0; Mx := 65536; End;
    End;
    P := FmCopy + K * 160;
    For I := 1 To Length(Nm) Do WrW(P + (I - 1) * 2, Ord(Nm[I]));
    WrL(P + 128, T); WrL(P + 140, Fl);
    WrL(P + 144, Mn); WrL(P + 152, Mx);
    If Mx = -1 Then WrL(P + 156, -1);
  End;
End;

{ $UpCase : 128 Ko, ecrits par blocs de 32 Ko (16384 caracteres) }
Function WriteUpCase(Lcn : LongInt) : Boolean;
Var B, I, R, K, C0, C, X : LongInt; Ok : Boolean;
Begin
  Ok := True;
  B := 0;
  While Ok And (B < 4) Do
  Begin
    C0 := B * 16384;
    For I := 0 To 16383 Do WrW(FmCopy + I * 2, C0 + I);
    For R := 0 To 133 Do
      For K := 0 To FmUpRuns[R * 4 + 1] - 1 Do
      Begin
        C := FmUpRuns[R * 4] + K * FmUpRuns[R * 4 + 3];
        If (C >= C0) And (C < C0 + 16384) Then
        Begin
          X := (C + FmUpRuns[R * 4 + 2]) And $FFFF;
          WrW(FmCopy + (C - C0) * 2, X);
        End;
      End;
    Ok := FmWrite((Lcn + B * 8) * 8, 64, FmCopy);
    Inc(B);
  End;
  WriteUpCase := Ok;
End;

{ $Bitmap : clusters 0..FmNext-1, $MFTMirr et ceux au-dela du volume }
Function WriteNtBitmap : Boolean;
Var Ch, I, C, N, X : LongInt; Ok : Boolean;
Begin
  Ok := True;
  Ch := 0;
  While Ok And (Ch < (FmBmpN + 7) Div 8) Do
  Begin
    FillMem(FmCopy, 32768, 0);
    For I := 0 To 32767 Do
    Begin
      C := Ch * 262144 + I * 8;                  { 32 Ko = 262144 bits }
      If C + 8 <= FmNext Then X := $FF
      Else If C >= FmC Then X := $FF
      Else
      Begin
        X := 0;
        For N := 0 To 7 Do
          If (C + N < FmNext) Or (C + N = FmMirr) Or (C + N >= FmC) Then X := X Or (1 Shl N);
      End;
      If (C <= FmMirr) And (FmMirr < C + 8) Then X := X Or (1 Shl (FmMirr - C));
      WrB(FmCopy + I, X);
    End;
    N := Min(8, FmBmpN - Ch * 8);
    Ok := FmWrite((FmBmpL + Ch * 8) * 8, N * 8, FmCopy);
    Inc(Ch);
  End;
  WriteNtBitmap := Ok;
End;

{ Enregistrement d'un fichier systeme de la racine (parent 5) }
Procedure SysRec(N, Seq : LongInt; Const Nm : String; Fl, SecId, Flags, AllocLo, SizeLo : LongInt);
Begin
  RInit(N, Seq, Flags, 1);
  RRes(AT_STDINFO, '', VSi(Fl, SecId, True), 0);
  If (Flags And 2) <> 0 Then Fl := Fl Or FA_DIR;
  RRes(AT_FILENAME, '', VFn(FmVal, 5, 5, AllocLo, SizeLo, Fl, Nm, 3), 1);
  KAdd(N, Seq, 5, 5, AllocLo, SizeLo, Fl, Nm);
End;

{ Formater le volume V (TotSec deja connu) avec le nom Lbl ; code
  d'erreur }
Function FormatVol(V : LongInt; Lbl : String) : LongInt;
Var I, K, Ln, N, BadLo, BadHi, Hidden, Spt, Heads, Bytes : LongInt; Ok : Boolean; Tx : String;
Begin
  FormatVol := ERROR_INVALID_PARAMETER;
  FmV := V;
  FmTot := Vols[V].TotSec;
  FmC := (FmTot - 1) Div 8;
  If FmC < 512 Then Exit;
  If FmC > 4194304 Then
  Begin
    { 16 Go au plus avec des clusters de 4 Ko (bitmap de 512 Ko) }
    FormatVol := ERROR_NOT_SUPPORTED;
    Exit;
  End;
  FormatVol := ERROR_NOT_ENOUGH_MEMORY;
  FmMft := HAlloc(65536);
  FmVal := HAlloc(4096);
  FmCopy := HAlloc(32768);
  FmIdx := HAlloc(4096);
  Ok := (FmMft <> 0) And (FmVal <> 0) And (FmCopy <> 0) And (FmIdx <> 0);
  If Ok Then
  Begin
    FormatVol := ERROR_WRITE_FAULT;
    CacheDropVol(V);
    { ancien secteur d'amorce : secteurs caches et geometrie }
    Hidden := 0; Spt := 63; Heads := 16;
    If DevIO(V, DVIO_OPREAD, 0, 1, FmIdx) = NO_ERROR Then
      If (RdW(FmIdx + 11) = 512) And (RdW(FmIdx + 510) = $AA55) Then
      Begin
        Hidden := RdL(FmIdx + $1C);
        If (RdW(FmIdx + $18) > 0) And (RdW(FmIdx + $18) <= 63) Then Spt := RdW(FmIdx + $18);
        If (RdW(FmIdx + $1A) > 0) And (RdW(FmIdx + $1A) <= 255) Then Heads := RdW(FmIdx + $1A);
      End;
    If Vols[V].PVpfsi <> 0 Then
    Begin
      If (RdL(Vols[V].PVpfsi + 16) > 0) And (RdL(Vols[V].PVpfsi + 16) <= 63) Then
        Spt := RdL(Vols[V].PVpfsi + 16);
      If (RdL(Vols[V].PVpfsi + 20) > 0) And (RdL(Vols[V].PVpfsi + 20) <= 255) Then
        Heads := RdL(Vols[V].PVpfsi + 20);
    End;
    UnixToFt(NowUnix, LongInt(@FmFt));
    { mise en page }
    FmNext := 2;
    FmMftL := FmAlloc(16); FmMBmpL := FmAlloc(1);
    Bytes := FmTot Div 2;                         { Ko }
    If Bytes < 2048 Then FmLogN := 64             { 256 Ko }
    Else If Bytes < 3907 Then FmLogN := 128       { 512 Ko }
    Else If Bytes <= 204800 Then FmLogN := 512    { 2 Mo }
    Else
    Begin
      FmLogN := FmTot Div 1600;                   { 1/200 du volume }
      If FmLogN > 16384 Then FmLogN := 16384;     { 64 Mo }
    End;
    FmLogL := FmAlloc(FmLogN);
    FmAdL := FmAlloc(1); FmUpL := FmAlloc(32);
    FmSdsN := (262144 + 256 + 4095) Div 4096; FmSdsL := FmAlloc(FmSdsN);
    FmBmpLen := ((FmC + 7) Div 8 + 7) And Not 7;
    FmBmpN := (FmBmpLen + 4095) Div 4096; FmBmpL := FmAlloc(FmBmpN);
    FmRootIx := FmAlloc(1);
    FmMirr := FmC Div 2;
    If FmNext >= FmMirr Then
    Begin
      Ok := False;
      FormatVol := ERROR_INVALID_PARAMETER;
    End;
  End;
  { donnees fixes }
  If Ok Then Ok := FmFill(FmLogL, FmLogN, $FF);
  If Ok Then
  Begin
    GenAttrDef;
    Ok := FmWrite(FmAdL * 8, 8, FmCopy);
  End;
  If Ok Then Ok := WriteUpCase(FmUpL);
  If Ok Then Ok := FmFill(FmSdsL, FmSdsN, 0);
  If Ok Then
  Begin
    { $SDS : descripteurs, puis leur copie 256 Ko plus loin }
    FillMem(FmCopy, 512, 0);
    For I := 0 To 255 Do WrB(FmCopy + I, FmSds[I]);
    Ok := FmWrite(FmSdsL * 8, 1, FmCopy);
    If Ok Then Ok := FmWrite((FmSdsL + 64) * 8, 1, FmCopy);
  End;
  If Ok Then
  Begin
    { index de $Extend : $ObjId, $Quota, $Reparse (petit index), prepare
      en FmCopy avant la liste de la racine }
    KN := 0;
    KAdd(25, 1, 11, 11, 0, 0, $20000026, '$ObjId');
    KAdd(24, 1, 11, 11, 0, 0, $20000026, '$Quota');
    KAdd(26, 1, 11, 11, 0, 0, $20000026, '$Reparse');
    FillMem(FmCopy, 4096, 0);
    WrL(FmCopy, AT_FILENAME); WrL(FmCopy + 4, 1); WrL(FmCopy + 8, 4096);
    WrB(FmCopy + 12, 1);
    Ln := KPut(FmCopy + $20);
    WrL(FmCopy + $10, $10); WrL(FmCopy + $14, $10 + Ln);
    WrL(FmCopy + $18, $10 + Ln); WrB(FmCopy + $1C, 0);
    K := $20 + Ln;
    KN := 0;
    SysRec(0, 1, '$MFT', 6, $100, 1, 65536, 65536);
    RNonRes(AT_DATA, '', FmMftL, 16, 65536, 0, 65536, 0);
    RNonRes(AT_BITMAP, '', FmMBmpL, 1, 4096, 0, 8, 0);
    RDone;
    SysRec(1, 1, '$MFTMirr', 6, $100, 1, 4096, 4096);
    RNonRes(AT_DATA, '', FmMirr, 1, 4096, 0, 4096, 0);
    RDone;
    SysRec(2, 2, '$LogFile', 6, $100, 1, FmLogN * 4096, FmLogN * 4096);
    RNonRes(AT_DATA, '', FmLogL, FmLogN, FmLogN * 4096, 0, FmLogN * 4096, 0);
    RDone;
    SysRec(3, 3, '$Volume', 6, $100, 1, 0, 0);
    Tx := Copy(Lbl, 1, 32);
    FillMem(FmVal, 64, 0);
    PutUName(FmVal, Tx);
    RRes(AT_VOLNAME, '', Length(Tx) * 2, 0);
    FillMem(FmVal, 12, 0);
    WrB(FmVal + 8, 3); WrB(FmVal + 9, 1);
    RRes(AT_VOLINFO, '', 12, 0);
    RRes(AT_DATA, '', 0, 0);
    RDone;
    SysRec(4, 4, '$AttrDef', 6, $100, 1, 4096, 2560);
    RNonRes(AT_DATA, '', FmAdL, 1, 4096, 0, 2560, 0);
    RDone;
    SysRec(6, 6, '$Bitmap', 6, $100, 1, FmBmpN * 4096, FmBmpLen);
    RNonRes(AT_DATA, '', FmBmpL, FmBmpN, FmBmpN * 4096, 0, FmBmpLen, 0);
    RDone;
    SysRec(7, 7, '$Boot', 6, $100, 1, 8192, 8192);
    RNonRes(AT_DATA, '', 0, 2, 8192, 0, 8192, 0);
    RDone;
    SysRec(8, 8, '$BadClus', 6, $100, 1, 0, 0);
    RRes(AT_DATA, '', 0, 0);
    BadLo := FmC Shl 12; BadHi := FmC Shr 20;
    RNonRes(AT_DATA, '$Bad', -1, FmC, BadLo, BadHi, BadLo, BadHi);
    RDone;
    SysRec(9, 9, '$Secure', $20000006, $101, 9, 0, 0);
    RNonRes(AT_DATA, '$SDS', FmSdsL, FmSdsN, FmSdsN * 4096, 0, 262144 + 256, 0);
    For I := 0 To 143 Do WrB(FmVal + I, FmSdh[I]);
    RRes(AT_IDXROOT, '$SDH', 144, 0);
    For I := 0 To 127 Do WrB(FmVal + I, FmSii[I]);
    RRes(AT_IDXROOT, '$SII', 128, 0);
    RDone;
    SysRec(10, 10, '$UpCase', 6, $100, 1, 131072, 131072);
    RNonRes(AT_DATA, '', FmUpL, 32, 131072, 0, 131072, 0);
    RDone;
    SysRec(11, 11, '$Extend', 6, $101, 3, 0, 0);
    MoveMem(FmCopy, FmVal, K);
    RRes(AT_IDXROOT, '$I30', K, 0);
    RDone;
    For N := 12 To 15 Do
    Begin
      RInit(N, N, 1, 0);
      RRes(AT_STDINFO, '', VSi(6, $100, True), 0);
      RRes(AT_DATA, '', 0, 0);
      RDone;
    End;
    For N := 16 To 23 Do
    Begin
      RInit(N, N, 0, 0);
      RRes(AT_STDINFO, '', VSi(0, 0, False), 0);
      RDone;
    End;
    { fichiers de $Extend }
    For N := 24 To 26 Do
    Begin
      RInit(N, 1, 13, 1);
      RRes(AT_STDINFO, '', VSi($20000026, $101, True), 0);
      If N = 24 Then Ln := VFn(FmVal, 11, 11, 0, 0, $20000026, '$Quota', 3)
      Else If N = 25 Then Ln := VFn(FmVal, 11, 11, 0, 0, $20000026, '$ObjId', 3)
      Else Ln := VFn(FmVal, 11, 11, 0, 0, $20000026, '$Reparse', 3);
      RRes(AT_FILENAME, '', Ln, 1);
      If N = 24 Then
      Begin
        For I := 0 To 87 Do WrB(FmVal + I, FmQo[I]);
        RRes(AT_IDXROOT, '$O', 88, 0);
        For I := 0 To 207 Do WrB(FmVal + I, FmQq[I]);
        RRes(AT_IDXROOT, '$Q', 208, 0);
      End
      Else
      Begin
        For I := 0 To 47 Do WrB(FmVal + I, FmEmptyIx[I]);
        If N = 25 Then RRes(AT_IDXROOT, '$O', 48, 0) Else RRes(AT_IDXROOT, '$R', 48, 0);
      End;
      RDone;
    End;
    { racine (5) : '.' et les fichiers systeme }
    KAdd(5, 5, 5, 5, 0, 0, $10000026, '.');
    Ok := WriteIndx(FmRootIx);
  End;
  If Ok Then
  Begin
    RInit(5, 5, 3, 1);
    RRes(AT_STDINFO, '', VSi($26, $101, True), 0);
    RRes(AT_FILENAME, '', VFn(FmVal, 5, 5, 0, 0, $10000026, '.', 3), 1);
    RRes(AT_IDXROOT, '$I30', VBigRoot, 0);
    RNonRes(AT_IDXALLOC, '$I30', FmRootIx, 1, 4096, 0, 4096, 0);
    FillMem(FmVal, 8, 0);
    WrB(FmVal, 1);
    RRes(AT_BITMAP, '$I30', 8, 0);
    RDone;
    { enregistrements libres }
    For N := 27 To 63 Do
    Begin
      RInit(N, 1, 0, 0);
      RDone;
    End;
    { correctifs et ecriture : MFT (64 Ko) et miroir (4 enregistrements) }
    For N := 0 To 63 Do Protect(FmMft + N * 1024, 1024);
    Ok := FmWrite(FmMftL * 8, 128, FmMft);
    If Ok Then Ok := FmWrite(FmMirr * 8, 8, FmMft);
  End;
  If Ok Then
  Begin
    { bitmap de la MFT : 0-15, 24-26 }
    FillMem(FmCopy, 4096, 0);
    For N := 0 To 26 Do
      If (N < 16) Or (N >= 24) Then
        WrB(FmCopy + N Shr 3, RdB(FmCopy + N Shr 3) Or (1 Shl (N And 7)));
    Ok := FmWrite(FmMBmpL * 8, 8, FmCopy);
  End;
  If Ok Then Ok := WriteNtBitmap;
  If Ok Then
  Begin
    { secteur d'amorce (sans programme d'amorcage : INT 18h), secteurs
      1-15 vides, et copie au dernier secteur }
    FillMem(FmCopy, 8192, 0);
    WrB(FmCopy, $EB); WrB(FmCopy + 1, $52); WrB(FmCopy + 2, $90);
    Tx := 'NTFS    ';
    For I := 1 To 8 Do WrB(FmCopy + 2 + I, Ord(Tx[I]));
    WrW(FmCopy + 11, 512); WrB(FmCopy + 13, 8);
    WrB(FmCopy + $15, $F8);
    WrW(FmCopy + $18, Spt); WrW(FmCopy + $1A, Heads);
    WrL(FmCopy + $1C, Hidden);
    WrB(FmCopy + $24, $80); WrB(FmCopy + $26, $80);
    WrL(FmCopy + $28, FmTot - 1);
    WrL(FmCopy + $30, FmMftL); WrL(FmCopy + $38, FmMirr);
    WrB(FmCopy + $40, $F6); WrB(FmCopy + $44, 1);
    WrL(FmCopy + $48, FmFt[0] Xor NowUnix);
    WrL(FmCopy + $4C, FmFt[1] Xor $5095);
    { programme : CD 18 (INT 18h : pas de systeme) puis boucle }
    WrB(FmCopy + $54, $CD); WrB(FmCopy + $55, $18);
    WrB(FmCopy + $56, $EB); WrB(FmCopy + $57, $FE);
    WrW(FmCopy + 510, $AA55);
    Ok := FmWrite(0, 16, FmCopy);
    If Ok Then Ok := FmWrite(FmTot - 1, 1, FmCopy);
  End;
  If Ok Then FormatVol := NO_ERROR;
  HFree(FmMft); HFree(FmVal); HFree(FmCopy); HFree(FmIdx);
  FmMft := 0; FmVal := 0; FmCopy := 0; FmIdx := 0;
  CacheDropVol(V);
End;

{ ------------------------------------------------------------------ }
{ Verification (CHKDSK)                                                }
{ ------------------------------------------------------------------ }
{ Tous les enregistrements en service de la MFT sont lus : leurs
  attributs non residents marquent leurs clusters dans une carte (un
  cluster reference deux fois est une erreur), puis la carte est comparee
  a $Bitmap (cluster utilise non marque : erreur ; cluster marque non
  utilise : perdu) ; le bitmap de la MFT est compare aux indicateurs "en
  service" des enregistrements. L'arborescence est ensuite parcourue :
  chaque entree d'index doit designer un enregistrement en service de
  meme numero de sequence. Fix corrige les bitmaps. }

Procedure ChkMarkRuns(V, RA, RN : LongInt);
Var I, C, L, K, A, M : LongInt;
Begin
  For I := 0 To RN - 1 Do
  Begin
    C := RdL(RA + I * 12 + 4);
    L := RdL(RA + I * 12 + 8);
    If C >= 0 Then
      For K := C To C + L - 1 Do
        If (K < 0) Or (K >= Vols[V].NClus) Then Inc(ChkErrors)
        Else
        Begin
          A := ChkMap + K Shr 3; M := 1 Shl (K And 7);
          If (RdB(A) And M) <> 0 Then Inc(ChkErrors)
          Else
          Begin
            WrB(A, RdB(A) Or M);
            Inc(ChkUsed);
          End;
        End;
  End;
End;

{ Parcourir le repertoire Dir (profondeur Depth) }
Procedure ChkDir(V, Dir, Depth : LongInt);
Var R, I, N, E, K, Subs, NSub, Fl, Seq : LongInt;
Begin
  If Depth > 32 Then
  Begin
    Inc(ChkErrors);
    Exit;
  End;
  Inc(ChkDirs);
  R := HAlloc(Vols[V].RecSz);
  If R = 0 Then Exit;
  Subs := 0; NSub := 0;
  If Not NtReadRec(V, Dir, R) Then Inc(ChkErrors)
  Else If Not NtGather(V, Dir, R) Then Inc(ChkErrors)
  Else
  Begin
    Subs := HAlloc(NgN * 4 + 16);
    For I := 0 To NgN - 1 Do
    Begin
      E := NgEnt(I);
      N := RdL(E);
      Seq := RdW(E + 6);
      K := E + 12;
      Fl := RdL(K + $38);
      If Not NtReadRec(V, N, R) Then Inc(ChkErrors)
      Else If (RdW(R + $16) And 1) = 0 Then Inc(ChkErrors)
      Else If (Seq <> 0) And (Seq <> RdW(R + $10)) Then Inc(ChkErrors)
      Else If (N >= FIRST_USER) And (RdB(K + $41) <> 2) Then
      Begin
        If (Fl And FA_DIR) <> 0 Then
        Begin
          If Subs <> 0 Then
          Begin
            WrL(Subs + NSub * 4, N);
            Inc(NSub);
          End;
        End
        Else Inc(ChkFiles);
      End;
    End;
  End;
  HFree(R);
  For I := 0 To NSub - 1 Do ChkDir(V, RdL(Subs + I * 4), Depth + 1);
  HFree(Subs);
End;

Function CheckVol(V : LongInt; Fix : Boolean; Var Lost : LongInt) : LongInt;
Var R, RA, RN, N, P, C, InB, InM, Ret : LongInt; InUse, InBmp : Boolean;
Begin
  Ret := NO_ERROR;
  ChkErrors := 0; ChkLost := 0; ChkDirs := 0; ChkFiles := 0; ChkRecs := 0; ChkUsed := 0;
  Lost := 0;
  ChkMap := HAlloc(Vols[V].NClus Div 8 + 16);
  R := HAlloc(Vols[V].RecSz);
  RA := HAlloc(RunBytes);
  If (ChkMap = 0) Or (R = 0) Or (RA = 0) Or (Vols[V].Bmp = 0) Then Ret := ERROR_NOT_ENOUGH_MEMORY
  Else
  Begin
    For N := 0 To Vols[V].RecN - 1 Do
    Begin
      InBmp := False;
      If (N Shr 3) < Vols[V].MBmpLen Then
        InBmp := (RdB(Vols[V].MBmp + N Shr 3) And (1 Shl (N And 7))) <> 0;
      InUse := False;
      If NtReadRec(V, N, R) Then InUse := (RdW(R + $16) And 1) <> 0
      Else If InBmp Then Inc(ChkErrors);
      If InUse Then
      Begin
        Inc(ChkRecs);
        If (Not InBmp) And (N >= FIRST_USER) Then Inc(ChkErrors);
        P := R + RdW(R + $14);
        While (P < R + Vols[V].RecSz - 8) And (RdL(P) <> -1) And (RdL(P) > 0) And (RdL(P + 4) > 0) Do
        Begin
          If RdB(P + 8) <> 0 Then
          Begin
            RN := 0;
            If NtRunsDecode(P, RA, RN) Then ChkMarkRuns(V, RA, RN) Else Inc(ChkErrors);
          End;
          P := P + RdL(P + 4);
        End;
      End
      Else If InBmp And (N >= 24) Then
      Begin
        { enregistrement reserve mais libre : perdu }
        Inc(Lost);
        If Fix Then
          WrB(Vols[V].MBmp + N Shr 3, RdB(Vols[V].MBmp + N Shr 3) And Not (1 Shl (N And 7)));
      End;
    End;
    If Fix And (Lost > 0) Then NtMBmpSave(V);
    { comparaison avec $Bitmap }
    For C := 0 To Vols[V].NClus - 1 Do
    Begin
      InM := RdB(ChkMap + C Shr 3) And (1 Shl (C And 7));
      InB := RdB(Vols[V].Bmp + C Shr 3) And (1 Shl (C And 7));
      If (InM <> 0) And (InB = 0) Then
      Begin
        Inc(ChkErrors);
        If Fix Then WrB(Vols[V].Bmp + C Shr 3, RdB(Vols[V].Bmp + C Shr 3) Or (1 Shl (C And 7)));
      End
      Else If (InM = 0) And (InB <> 0) Then
      Begin
        Inc(Lost);
        If Fix Then WrB(Vols[V].Bmp + C Shr 3, RdB(Vols[V].Bmp + C Shr 3) And Not (1 Shl (C And 7)));
      End;
    End;
    If Fix Then
    Begin
      NtBmpSave(V, 0, Vols[V].BmpLen - 1);
      Vols[V].FreeClus := CountFree(V);
    End;
    ChkDir(V, ROOT_REC, 0);
    NtInval;
  End;
  HFree(RA);
  HFree(R);
  HFree(ChkMap);
  ChkMap := 0;
  ChkLost := Lost;
  CheckVol := Ret;
End;

{ ==================================================================== }
{ Partie 11 - Objets fichiers, ouvertures, verrous et notifications    }
{ ==================================================================== }
{ Un objet represente un fichier ouvert (un enregistrement de la MFT) ;
  chaque ouverture (SFT du noyau) le designe par sa zone SFFSD :
    +0 numero d'ouverture + 1   +4 signature 'NTFS'   +8 enregistrement }

Const
  SFD_MAGIC = $5346544E;     { 'NTFS' }

Function ObjFind(V, Rec : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxObj - 1 Do
    If Objs[I].Used And (Objs[I].Vol = V) And (Objs[I].Rec = Rec) Then R := I;
  ObjFind := R;
End;

{ Attributs DOS, taille et dates de l'enregistrement N (d'apres
  $STANDARD_INFORMATION et $DATA) ; False s'il est illisible }
Function NtRecInfo(V, N : LongInt; Var Attr, Size, C, A, M : LongInt) : Boolean;
Var R, P, Ok, RA, RN, Sz, Rs : LongInt; Res : Boolean;
Begin
  Res := False;
  R := HAlloc(Vols[V].RecSz);
  If R <> 0 Then
  Begin
    If NtReadRec(V, N, R) Then
    Begin
      Res := True;
      Attr := 0; Size := 0; C := 0; A := 0; M := 0;
      P := NtAttr(V, R, AT_STDINFO, '');
      If P <> 0 Then
      Begin
        Ok := NtResVal(P);
        C := FtToUnix(Ok); M := FtToUnix(Ok + 8); A := FtToUnix(Ok + 24);
        Attr := RdL(Ok + $20) And $27;
      End;
      If (RdW(R + $16) And 2) <> 0 Then
        Attr := (Attr And Not ATTR_ARCHIVE) Or ATTR_DIRECTORY
      Else
      Begin
        P := NtAttr(V, R, AT_DATA, '');
        If P <> 0 Then Size := NtAttrSize(P)
        Else
        Begin
          RA := HAlloc(RunBytes);
          If RA <> 0 Then
          Begin
            If NtGetAttr(V, N, R, AT_DATA, '', RA, RN, Sz, Rs) Then Size := Sz;
            HFree(RA);
          End;
        End;
      End;
    End;
    HFree(R);
  End;
  NtRecInfo := Res;
End;

{ Objet du fichier decrit par l'entree DeOut du repertoire Dir }
Function ObjGet(V, Dir : LongInt) : LongInt;
Var I, R, Rec, Attr, Size, C, A, M : LongInt;
Begin
  Rec := DeRec;
  R := ObjFind(V, Rec);
  If R < 0 Then
  Begin
    For I := MaxObj - 1 DownTo 0 Do
      If Not Objs[I].Used Then R := I;
    If R >= 0 Then
    Begin
      If Not NtRecInfo(V, Rec, Attr, Size, C, A, M) Then
      Begin
        Attr := DeAttr; Size := DeSize;
        C := FtToUnix(DeKey + 8); M := FtToUnix(DeKey + $10); A := FtToUnix(DeKey + $20);
      End;
      Objs[R].Used := True;
      Objs[R].Vol := V;
      Objs[R].Rec := Rec;
      Objs[R].Dir := Dir;
      Objs[R].Name := DeName;
      Objs[R].Size := Size;
      Objs[R].Attr := Attr;
      Objs[R].CTime := C;
      Objs[R].ATime := A;
      Objs[R].MTime := M;
      Objs[R].Refs := 0;
      Objs[R].Dirty := False;
      Objs[R].Swap := False;
    End;
  End;
  If R >= 0 Then Inc(Objs[R].Refs);
  ObjGet := R;
End;

{ Ecrire dates, attributs et tailles de l'enregistrement N
  ($STANDARD_INFORMATION, $FILE_NAME) et de ses entrees dans le
  repertoire Dir. Mask : 1 attributs, 2 tailles, 4 creation,
  8 modification, 16 acces }
Function NtSetInfo(V, N, Dir, Mask, Attr, C, A, M : LongInt) : LongInt;
Var R, P, Si, Alloc, Size, Ret : LongInt;
Begin
  Ret := ERROR_WRITE_FAULT;
  If Vols[V].RO Then
  Begin
    NtSetInfo := ERROR_WRITE_PROTECT;
    Exit;
  End;
  R := HAlloc(Vols[V].RecSz);
  If R <> 0 Then
  Begin
    If NtReadRec(V, N, R) Then
    Begin
      Si := NtAttr(V, R, AT_STDINFO, '');
      If Si <> 0 Then
      Begin
        Si := NtResVal(Si);
        If (Mask And 1) <> 0 Then WrL(Si + $20, (RdL(Si + $20) And Not $27) Or (Attr And $27));
        If (Mask And 4) <> 0 Then UnixToFt(C, Si);
        If (Mask And 8) <> 0 Then UnixToFt(M, Si + 8);
        UnixToFt(NowUnix, Si + 16);
        If (Mask And 16) <> 0 Then UnixToFt(A, Si + 24);
      End;
      Alloc := 0; Size := 0;
      P := NtAttr(V, R, AT_DATA, '');
      If P = 0 Then Mask := Mask And Not 2
      Else If RdB(P + 8) = 0 Then
      Begin
        Size := RdL(P + $10);
        Alloc := Al8(Size);
      End
      Else
      Begin
        Alloc := RdL(P + $28); Size := RdL(P + $30);
      End;
      If (RdW(R + $16) And 2) <> 0 Then Mask := Mask And Not 2;
      PtRec := N; PtFl := Attr; PtAlloc := Alloc; PtSize := Size;
      PtC := C; PtM := M; PtA := A; PtMask := Mask;
      { $FILE_NAME de l'enregistrement }
      P := NtAttr(V, R, AT_FILENAME, '');
      While P <> 0 Do
      Begin
        PatchKey(NtResVal(P));
        P := NtAttrAfter(V, R, P, AT_FILENAME, '');
      End;
      If NtWriteRec(V, N, R) Then
        If NtPatchDir(V, Dir) Then Ret := NO_ERROR;
    End;
    HFree(R);
  End;
  NtSetInfo := Ret;
End;

{ Ecrire la taille et les dates de l'objet dans son enregistrement et
  ses entrees d'index }
Function ObjSync(O : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := NO_ERROR;
  If Objs[O].Used And Objs[O].Dirty Then
  Begin
    R := NtSetInfo(Objs[O].Vol, Objs[O].Rec, Objs[O].Dir, 1 + 2 + 4 + 8 + 16, Objs[O].Attr,
                   Objs[O].CTime, Objs[O].ATime, Objs[O].MTime);
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
Function InUse(V, Rec : LongInt) : Boolean;
Begin
  InUse := ObjFind(V, Rec) >= 0;
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

{ Charger les runs de $DATA de l'objet O (RunRA, RunN, RunRes...) }
Function ObjLoad(O : LongInt) : LongInt;
Var V, N, R, Res, Ret : LongInt;
Begin
  Ret := NO_ERROR;
  V := Objs[O].Vol; N := Objs[O].Rec;
  If (RunVol <> V) Or (RunRec <> N) Then
  Begin
    RunVol := -1;
    Ret := ERROR_READ_FAULT;
    R := HAlloc(Vols[V].RecSz);
    If R <> 0 Then
    Begin
      If NtReadRec(V, N, R) Then
        If NtGetAttrX(V, N, R, AT_DATA, '', RunRA, RunN, RunSize, Res, RunInit, RunFlags) Then
        Begin
          RunRes := Res <> 0;
          RunVol := V; RunRec := N;
          Ret := NO_ERROR;
        End
        Else Ret := ERROR_ACCESS_DENIED;
      HFree(R);
    End;
  End;
  If (Ret = NO_ERROR) And ((RunFlags And $4001) <> 0) Then Ret := ERROR_ACCESS_DENIED;
  ObjLoad := Ret;
End;

Function ReadData(O, FPos, Buf, N : LongInt; Var Got : LongInt) : LongInt;
Var V, R, Rec, P, K : LongInt;
Begin
  Got := 0;
  R := NO_ERROR;
  V := Objs[O].Vol;
  If FPos >= Objs[O].Size Then N := 0
  Else If FPos + N > Objs[O].Size Then N := Objs[O].Size - FPos;
  If N > 0 Then R := ObjLoad(O);
  If (R = NO_ERROR) And (N > 0) Then
  Begin
    If RunRes Then
    Begin
      R := ERROR_READ_FAULT;
      Rec := HAlloc(Vols[V].RecSz);
      If Rec <> 0 Then
      Begin
        If NtReadRec(V, Objs[O].Rec, Rec) Then
        Begin
          P := NtAttr(V, Rec, AT_DATA, '');
          If P <> 0 Then
            If RdB(P + 8) = 0 Then
            Begin
              K := RdL(P + $10) - FPos;
              If K > N Then K := N;
              If K > 0 Then MoveMem(NtResVal(P) + FPos, Buf, K) Else K := 0;
              If K < N Then FillMem(Buf + K, N - K, 0);
              Got := N;
              R := NO_ERROR;
            End;
        End;
        HFree(Rec);
      End;
    End
    Else
    Begin
      { au-dela de la taille initialisee : des zeros }
      K := N;
      If FPos + K > RunInit Then K := RunInit - FPos;
      If K < 0 Then K := 0;
      If K > 0 Then
        If Not NtStreamIo(V, RunRA, RunN, FPos, K, Buf, False) Then R := ERROR_READ_FAULT;
      If R = NO_ERROR Then
      Begin
        If K < N Then FillMem(Buf + K, N - K, 0);
        Got := N;
      End;
    End;
  End;
  ReadData := R;
End;

{ Ecrire des zeros (Src = 0) ou les donnees Src dans un flux non
  resident }
Function StreamPut(V, RA, RN, Off, N, Src : LongInt) : Boolean;
Var Ok : Boolean; L : LongInt;
Begin
  If Src <> 0 Then Ok := NtStreamIo(V, RA, RN, Off, N, Src, True)
  Else
  Begin
    FillMem(LongInt(@ZeroBuf), 4096, 0);
    Ok := True;
    While Ok And (N > 0) Do
    Begin
      L := Min(N, 4096);
      Ok := NtStreamIo(V, RA, RN, Off, L, LongInt(@ZeroBuf), True);
      Off := Off + L; N := N - L;
    End;
  End;
  StreamPut := Ok;
End;

{ Ecrire N octets de Src (0 : des zeros) a la position Pos0 (au plus la
  taille actuelle) du fichier de l'objet O ; code d'erreur }
Function NtWriteAt(O, Pos0, N, Src : LongInt) : LongInt;
Var V, R, P, NewEnd, Old, B, Need, RN, RA, OldClus, Ret, InitSz, Cb : LongInt; Ok : Boolean;
Begin
  V := Objs[O].Vol;
  Cb := Vols[V].Cb;
  If Vols[V].RO Then
  Begin
    NtWriteAt := ERROR_WRITE_PROTECT;
    Exit;
  End;
  RunInval(V, Objs[O].Rec);
  Ret := ERROR_ACCESS_DENIED;
  R := HAlloc(Vols[V].RecSz + RunBytes);
  If R = 0 Then
  Begin
    NtWriteAt := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  RA := R + Vols[V].RecSz;
  P := 0;
  If NtReadRec(V, Objs[O].Rec, R) Then
    If NtAttr(V, R, AT_ATTRLIST, '') = 0 Then
    Begin
      P := NtAttr(V, R, AT_DATA, '');
      If P <> 0 Then
        If (RdW(P + $0C) And $4001) <> 0 Then P := 0
        Else If NtAttrSize(P) = $7FFFFFFF Then P := 0;           { 2 Go et plus }
    End;
  If P = 0 Then
  Begin
    HFree(R);
    NtWriteAt := Ret;
    Exit;
  End;
  NewEnd := Max(NtAttrSize(P), Pos0 + N);
  If RdB(P + 8) = 0 Then
  Begin
    { resident : agrandir si l'enregistrement le permet }
    Old := RdL(P + $10);
    If (NewEnd <= 700) And (RdL(R + $18) + Al8(NewEnd) - Al8(Old) <= Vols[V].RecSz) Then
    Begin
      Ret := ERROR_WRITE_FAULT;
      If NtResSetLen(V, R, P, NewEnd) Then
      Begin
        If NewEnd > Old Then FillMem(NtResVal(P) + Old, NewEnd - Old, 0);
        If Src <> 0 Then MoveMem(Src, NtResVal(P) + Pos0, N) Else FillMem(NtResVal(P) + Pos0, N, 0);
        If NtWriteRec(V, Objs[O].Rec, R) Then
        Begin
          Objs[O].Size := NewEnd;
          Ret := NO_ERROR;
        End;
      End;
      HFree(R);
      NtWriteAt := Ret;
      Exit;
    End;
    { passage en non resident }
    B := HAlloc(Old + 16);
    If B = 0 Then
    Begin
      HFree(R);
      NtWriteAt := ERROR_NOT_ENOUGH_MEMORY;
      Exit;
    End;
    MoveMem(NtResVal(P), B, Old);
    RN := 0;
    Need := (NewEnd + Cb - 1) Div Cb;
    Ok := NtExtend(V, RA, RN, Need);
    If Ok And (Old > 0) Then Ok := NtStreamIo(V, RA, RN, 0, Old, B, True);
    HFree(B);
    If Ok Then
    Begin
      NtAttrDel(V, R, P);
      P := NtAddNonRes(V, R, AT_DATA, '');
      Ok := P <> 0;
    End;
    If Not Ok Then
    Begin
      NtFreeAllRuns(V, RA, RN);
      HFree(R);
      NtWriteAt := ERROR_DISK_FULL;
      Exit;
    End;
    OldClus := 0;
  End
  Else
  Begin
    RN := 0;
    NtRunsDecode(P, RA, RN);
    OldClus := NtRunsLen(RA, RN);
    InitSz := RdL(P + $38);
    { donnees non initialisees avant la position : des zeros }
    If InitSz < Pos0 Then
      If Not StreamPut(V, RA, RN, InitSz, Min(Pos0, OldClus * Cb) - InitSz, 0) Then
      Begin
        HFree(R);
        NtWriteAt := ERROR_WRITE_FAULT;
        Exit;
      End;
    Need := (NewEnd + Cb - 1) Div Cb;
    If OldClus < Need Then
      If Not NtExtend(V, RA, RN, Need) Then
      Begin
        NtTruncRuns(V, RA, RN, OldClus);
        HFree(R);
        NtWriteAt := ERROR_DISK_FULL;
        Exit;
      End;
  End;
  Ret := ERROR_WRITE_FAULT;
  If StreamPut(V, RA, RN, Pos0, N, Src) Then
  Begin
    If NtSetRuns(V, R, P, RA, RN, NewEnd, NewEnd) Then
    Begin
      If NtWriteRec(V, Objs[O].Rec, R) Then
      Begin
        Objs[O].Size := NewEnd;
        Ret := NO_ERROR;
      End;
    End
    Else
    Begin
      { liste de runs trop longue pour l'enregistrement }
      NtTruncRuns(V, RA, RN, OldClus);
      Ret := ERROR_DISK_FULL;
    End;
  End;
  HFree(R);
  NtWriteAt := Ret;
End;

Function WriteData(O, FPos, Buf, N : LongInt; Var Done : LongInt) : LongInt;
Var R, Z : LongInt;
Begin
  Done := 0;
  R := NO_ERROR;
  If N > 0 Then
  Begin
    { trou entre la fin du fichier et la position : des zeros }
    While (R = NO_ERROR) And (Objs[O].Size < FPos) Do
    Begin
      Z := Min(FPos - Objs[O].Size, 1048576);
      R := NtWriteAt(O, Objs[O].Size, Z, 0);
    End;
    If R = NO_ERROR Then R := NtWriteAt(O, FPos, N, Buf);
    If R = NO_ERROR Then
    Begin
      Done := N;
      Objs[O].MTime := NowUnix;
      Objs[O].Attr := Objs[O].Attr Or ATTR_ARCHIVE;
      Objs[O].Dirty := True;
    End;
  End;
  WriteData := R;
End;

{ Changer la taille du fichier }
Function SetSize(O, NewSize : LongInt) : LongInt;
Var V, R, Rec, P, RA, RN, Ret : LongInt;
Begin
  V := Objs[O].Vol;
  Ret := NO_ERROR;
  If NewSize < 0 Then Ret := ERROR_INVALID_PARAMETER
  Else If Vols[V].RO And (NewSize <> Objs[O].Size) Then Ret := ERROR_WRITE_PROTECT
  Else If NewSize > Objs[O].Size Then
  Begin
    While (Ret = NO_ERROR) And (Objs[O].Size < NewSize) Do
      Ret := NtWriteAt(O, Objs[O].Size, Min(NewSize - Objs[O].Size, 1048576), 0);
  End
  Else If NewSize < Objs[O].Size Then
  Begin
    RunInval(V, Objs[O].Rec);
    Ret := ERROR_ACCESS_DENIED;
    Rec := HAlloc(Vols[V].RecSz + RunBytes);
    If Rec <> 0 Then
    Begin
      RA := Rec + Vols[V].RecSz;
      If NtReadRec(V, Objs[O].Rec, Rec) And (NtAttr(V, Rec, AT_ATTRLIST, '') = 0) Then
      Begin
        P := NtAttr(V, Rec, AT_DATA, '');
        If P <> 0 Then
          If RdB(P + 8) = 0 Then
          Begin
            If NtResSetLen(V, Rec, P, NewSize) Then
              If NtWriteRec(V, Objs[O].Rec, Rec) Then Ret := NO_ERROR;
          End
          Else
          Begin
            RN := 0;
            NtRunsDecode(P, RA, RN);
            NtTruncRuns(V, RA, RN, (NewSize + Vols[V].Cb - 1) Div Vols[V].Cb);
            If NtSetRuns(V, Rec, P, RA, RN, NewSize, Min(NewSize, RdL(P + $38))) Then
              If NtWriteRec(V, Objs[O].Rec, Rec) Then Ret := NO_ERROR;
          End;
      End;
      HFree(Rec);
    End;
    If Ret = NO_ERROR Then Objs[O].Size := NewSize;
  End;
  If Ret = NO_ERROR Then
  Begin
    Objs[O].MTime := NowUnix;
    Objs[O].Dirty := True;
  End;
  SetSize := Ret;
End;

{ ==================================================================== }
{ Partie 13 - Points d'entree FS_*                                     }
{ ==================================================================== }

{ --- utilitaires communs --- }

{ Tampons du pilote (tas partage), alloues au premier besoin }
Procedure InitBufs;
Begin
  If CacheData = 0 Then CacheData := HAlloc(CacheMax * 512);
  If RunRA = 0 Then RunRA := HAlloc(RunBytes);
  If TmpRA = 0 Then TmpRA := HAlloc(RunBytes);
End;

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

{ Taille allouee (clusters entiers) }
Function AllocOf(V, Size : LongInt) : LongInt;
Var Cb : LongInt;
Begin
  Cb := Vols[V].Cb;
  AllocOf := ((Size + Cb - 1) Div Cb) * Cb;
End;

{ FILESTATUS3 (niveau 1, 24 octets) ou FILESTATUS4 (niveau 2, 28) }
Function PutStatus(V, A, Cb, Level, Attr, Size, C, Ac, M : LongInt) : LongInt;
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
    WrL(A + 16, AllocOf(V, Size));
    WrL(A + 20, Attr And $37);
    If Level = 2 Then WrL(A + 24, 4);              { pas d'EA : FEA2LIST vide }
  End;
  PutStatus := R;
End;

{ Taille d'une FEA2LIST (EAOP2 : +4 adresse) ; les EA ne sont pas
  enregistres : une liste non vide est refusee }
Function EaListOk(PEaop : LongInt) : LongInt;
Var F : LongInt;
Begin
  EaListOk := NO_ERROR;
  If PEaop <> 0 Then
  Begin
    F := RdL(PEaop + 4);
    If F <> 0 Then
      If RdL(F) > 4 Then EaListOk := ERROR_EAS_NOT_SUPPORTED;
  End;
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
    Else If (X = ROOT_REC) Or (X < 0) Then N := 64
    Else X := NtParent(V, X);
    Inc(N);
  End;
  IsInside := R;
End;

{ Informations de l'entree DeOut (objet O ou -1) }
Procedure DeInfo(V, O : LongInt; Var Attr, Size, C, Ac, M : LongInt);
Begin
  If O >= 0 Then
  Begin
    Attr := Objs[O].Attr; Size := Objs[O].Size;
    C := Objs[O].CTime; Ac := Objs[O].ATime; M := Objs[O].MTime;
  End
  Else If Not NtRecInfo(V, DeRec, Attr, Size, C, Ac, M) Then
  Begin
    Attr := DeAttr; Size := DeSize;
    C := FtToUnix(DeKey + 8); M := FtToUnix(DeKey + $10); Ac := FtToUnix(DeKey + $20);
  End;
End;

{ Creer un fichier ou un repertoire vide Name dans Dir ; rend son
  enregistrement (-1 si echec, erreur dans LastErr) ; l'entree creee est
  dans DeOut }
Function CreateNode(V, Dir : LongInt; Name : String; Attr : LongInt; IsDir : Boolean) : LongInt;
Var N, R : LongInt;
Begin
  N := -1;
  R := CheckName(Name);
  If R = NO_ERROR Then R := NtCreate(V, Dir, Name, Attr, IsDir, N);
  If R = NO_ERROR Then LogChange(V, Dir, 1, Name) Else N := -1;
  LastErr := R;
  CreateNode := N;
End;

{ Supprimer le fichier (non repertoire) d'entree DeOut du repertoire Dir }
Function RemoveFile(V, Dir : LongInt) : LongInt;
Var R : LongInt; Name : String;
Begin
  Name := DeName;
  R := NtRemove(V, Dir, DeRec, False);
  If R = NO_ERROR Then LogChange(V, Dir, 2, Name);
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
    (/CACHE:n Ko d'antememoire, 0 a 64 ; /AUTOCHECK:lettres). }
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
    RunVol := -1; LsVol := -1; LsGen := 0;
    CacheTick := 0; CacheHits := 0; CacheMiss := 0;
  End;
  InitBufs;
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
  If CacheData = 0 Then C := 0;
  For I := 0 To CacheMax - 1 Do CacheVol[I] := -1;
  CacheN := C;
  ShutDown := False;
  InitDone := True;
  FS_INIT := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  FS_MOUNT(flag, pvpfsi, pvpfsd, hVPB, pBoot)
    flag 0 : reconnaitre le volume (pBoot = son secteur d'amorce : "NTFS"
    en +3) ; 1 : volume retire ; 2 : liberer le volume ; 3 : accepter un
    volume non reconnu (pour le formater par FS_FSCTL 8000h). }
Function FS_MOUNT(Flag, PVpfsi, PVpfsd, HVpb, PBoot : LongInt) : LongInt;
Var V, I, R : LongInt; S : String;
Begin
  R := NO_ERROR;
  InitBufs;
  If (CacheN = 0) And (CacheData <> 0) Then CacheN := Min(OptCache * 2, CacheMax);
  V := FindVol(HVpb);
  Case Flag Of
    0, 3 :
      Begin
        If (Flag = 0) And (PBoot <> 0) Then
          If RdL(PBoot + 3) <> OEM_NTFS Then
          Begin
            { pas un volume NTFS (HPFS, FAT...) : rien n'est garde }
            FS_MOUNT := ERROR_NOT_DOS_DISK;
            Exit;
          End;
        If V < 0 Then
          For I := MaxVol - 1 DownTo 0 Do
            If Not Vols[I].Used Then V := I;
        If V < 0 Then R := ERROR_TOO_MANY_OPEN_FILES
        Else If (RunRA = 0) Or (TmpRA = 0) Then R := ERROR_NOT_ENOUGH_MEMORY
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
            If PBoot = 0 Then R := ERROR_NOT_DOS_DISK
            Else R := MountVol(V, PBoot);
            If R = NO_ERROR Then
            Begin
              WrL(PVpfsi, Vols[V].Serial);
              S := Copy(GetLabel(V), 1, 11);
              PutStr(PVpfsi + 24, S, 12);
              WrL(PVpfsd, V + 1);
              WrL(PVpfsd + 4, SFD_MAGIC);
            End
            Else
            Begin
              Vols[V].Used := False;
            End;
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
        FreeVolMem(V);
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
    Rattachement d'une unite distante : NTFS est un systeme de fichiers
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
    pcEABuf : EAOP2 (EA du fichier cree ou remplace, ignores) ou 0. }
Function FS_OPENCREATE(Pcdfsi, Pcdfsd, PName, ICurDirEnd, Psffsi, Psffsd, OpenMode, OpenFlag,
                       PAction, Attr, PEABuf, PGenFlag : LongInt) : LongInt;
Var V, R, O, H, Dir, Act, Rec, IfEx, IfNew, FA, Sz, C, Ac, M : LongInt; Name : String;
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
      DeInfo(V, ObjFind(V, DeRec), FA, Sz, C, Ac, M);
      If DeIsDir Then R := ERROR_ACCESS_DENIED
      Else If IfEx = 0 Then R := 110                   { ERROR_OPEN_FAILED }
      Else If (IfEx = 2) Or WantsWrite(OpenMode) Then
      Begin
        If (FA And ATTR_READONLY) <> 0 Then R := ERROR_ACCESS_DENIED
        Else If Vols[V].RO Then R := ERROR_WRITE_PROTECT;
      End;
      If (R = NO_ERROR) And (IfEx = 2) Then Act := 3 Else Act := 1;
      If (R = NO_ERROR) And (IfEx > 2) Then R := ERROR_INVALID_PARAMETER;
    End
    Else If IfNew = 1 Then
    Begin
      Rec := CreateNode(V, Dir, Name, Attr, False);
      If Rec < 0 Then R := LastErr Else Act := 2;
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
      Objs[O].Attr := (Objs[O].Attr And ATTR_DIRECTORY) Or (Attr And $27) Or ATTR_ARCHIVE;
      Objs[O].Dirty := True;
      R := ObjSync(O);
    End;
  End;
  If R = NO_ERROR Then
  Begin
    WrL(Psffsd, H + 1);
    WrL(Psffsd + 4, SFD_MAGIC);
    WrL(Psffsd + 8, Objs[O].Rec);
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

{ Interroger ou modifier les informations du fichier d'enregistrement
  Rec (repertoire Dir, objet O ou -1). Niveaux : 1 FILESTATUS3,
  2 FILESTATUS4 (cbList), 3 EA choisis (EAOP2), 4 tous les EA (EAOP2) :
  les EA ne sont pas enregistres sur un volume NTFS (liste vide). }
Function InfoOp(V, Dir, Rec, O : LongInt; SetIt : Boolean; Level, PData, CbData : LongInt) : LongInt;
Var R, Attr, Size, C, Ac, M, T, F : LongInt;
Begin
  R := NO_ERROR;
  If O >= 0 Then
  Begin
    Attr := Objs[O].Attr; Size := Objs[O].Size;
    C := Objs[O].CTime; Ac := Objs[O].ATime; M := Objs[O].MTime;
  End
  Else If Not NtRecInfo(V, Rec, Attr, Size, C, Ac, M) Then R := ERROR_FILE_NOT_FOUND;
  If R <> NO_ERROR Then
  Else If Not SetIt Then
  Begin
    Case Level Of
      1, 2 : R := PutStatus(V, PData, CbData, Level, Attr, Size, C, Ac, M);
      3, 4 :
        If CbData < 12 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          F := RdL(PData + 4);
          If F <> 0 Then
          Begin
            If RdL(F) < 4 Then R := ERROR_BUFFER_OVERFLOW Else WrL(F, 4);
          End;
        End;
    Else
      R := ERROR_INVALID_LEVEL;
    End;
  End
  Else If Rec = ROOT_REC Then R := ERROR_ACCESS_DENIED
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
            Else Attr := (Attr And ATTR_DIRECTORY) Or (T And $27);
          End;
          If R = NO_ERROR Then
            R := NtSetInfo(V, Rec, Dir, 1 + 4 + 8 + 16, Attr, C, Ac, M);
          If (R = NO_ERROR) And (O >= 0) Then
          Begin
            Objs[O].Attr := Attr; Objs[O].CTime := C; Objs[O].ATime := Ac; Objs[O].MTime := M;
          End;
          LogChange(V, Dir, 3, DeName);
        End;
      2 :
        If CbData < 12 Then R := ERROR_BUFFER_OVERFLOW
        Else R := EaListOk(PData);
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
    If ((Flag And 1) <> 0) And Not WantsWrite(Opens[H].Mode) Then R := ERROR_ACCESS_DENIED
    Else
    Begin
      SetKey(Objs[O].Name);
      If Not NtLookup(V, Objs[O].Dir) Then FillMem(LongInt(@DeOut), 16 + $42, 0);
      R := InfoOp(V, Objs[O].Dir, Objs[O].Rec, O, (Flag And 1) <> 0, Level, PData, CbData);
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
  Dir := ROOT_REC;
  For I := 0 To NComp - 1 Do
  Begin
    SetKey(PComp[I]);
    If Exact And NtLookup(V, Dir) Then
    Begin
      S := S + '\' + DeName;
      Dir := DeRec;
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
Var V, R, O, Dir, Rec : LongInt; S : String;
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
      Rec := DeRec;
      O := ObjFind(V, Rec);
      If (O >= 0) And ((Flag And 1) <> 0) Then ObjSync(O);
      If WIsRoot And ((Flag And 1) <> 0) Then R := ERROR_ACCESS_DENIED
      Else R := InfoOp(V, Dir, Rec, O, (Flag And 1) <> 0, Level, PData, CbData);
    End;
  End;
  FS_PATHINFO := R;
End;

{ ---------------------------------------------------------------------
  FS_FILEATTRIBUTE(flag, pcdfsi, pcdfsd, pName, iCurDirEnd, pAttr)
    flag 0 : lire les attributs DOS dans *pAttr, 1 : les modifier. }
Function FS_FILEATTRIBUTE(Flag, Pcdfsi, Pcdfsd, PName, ICurDirEnd, PAttr : LongInt) : LongInt;
Var V, R, O, A, Attr, Size, C, Ac, M : LongInt;
Begin
  V := VolOf(Pcdfsi, PName);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PName);
  If (R = NO_ERROR) And Not WFound Then R := ERROR_FILE_NOT_FOUND;
  If R = NO_ERROR Then
  Begin
    O := ObjFind(V, DeRec);
    If WIsRoot Then Attr := ATTR_DIRECTORY
    Else DeInfo(V, O, Attr, Size, C, Ac, M);
    If (Flag And 1) = 0 Then WrL(PAttr, Attr And $37)
    Else If WIsRoot Then R := ERROR_ACCESS_DENIED
    Else
    Begin
      A := RdL(PAttr);
      If ((A And Not $37) <> 0) Or (((A Xor Attr) And ATTR_DIRECTORY) <> 0) Then R := ERROR_ACCESS_DENIED
      Else
      Begin
        Attr := (Attr And ATTR_DIRECTORY) Or (A And $27);
        R := NtSetInfo(V, DeRec, WDir, 1, Attr, 0, 0, 0);
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
Var V, R, Attr, Size, C, Ac, M : LongInt;
Begin
  V := VolOf(Pcdfsi, PFile);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PFile);
  If (R = NO_ERROR) And (WIsRoot Or HasWild(LastComp)) Then R := ERROR_ACCESS_DENIED;
  If (R = NO_ERROR) And Not WFound Then R := ERROR_FILE_NOT_FOUND;
  If R = NO_ERROR Then
  Begin
    DeInfo(V, -1, Attr, Size, C, Ac, M);
    If DeIsDir Or ((Attr And ATTR_READONLY) <> 0) Then R := ERROR_ACCESS_DENIED
    Else If InUse(V, DeRec) Then R := ERROR_SHARING_VIOLATION
    Else R := RemoveFile(V, WDir);
  End;
  FS_DELETE := R;
End;

{ ---------------------------------------------------------------------
  FS_MKDIR(pcdfsi, pcdfsd, pName, iCurDirEnd, pEABuf, flags)
    Creer un repertoire ; pEABuf : EAOP2 de ses EA (ignores) ou 0. }
Function FS_MKDIR(Pcdfsi, Pcdfsd, PName, ICurDirEnd, PEABuf, Flags : LongInt) : LongInt;
Var V, R, Rec : LongInt;
Begin
  V := VolOf(Pcdfsi, PName);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PName);
  If (R = NO_ERROR) And (WIsRoot Or WFound) Then R := ERROR_ACCESS_DENIED;
  If (R = NO_ERROR) And HasWild(LastComp) Then R := ERROR_INVALID_NAME;
  If R = NO_ERROR Then
  Begin
    Rec := CreateNode(V, WDir, LastComp, 0, True);
    If Rec < 0 Then R := LastErr;
  End;
  FS_MKDIR := R;
End;

{ ---------------------------------------------------------------------
  FS_RMDIR(pcdfsi, pcdfsd, pName, iCurDirEnd)
    Supprimer un repertoire vide. }
Function FS_RMDIR(Pcdfsi, Pcdfsd, PName, ICurDirEnd : LongInt) : LongInt;
Var V, R : LongInt; Name : String;
Begin
  V := VolOf(Pcdfsi, PName);
  If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PName);
  If (R = NO_ERROR) And WIsRoot Then R := ERROR_ACCESS_DENIED;
  If (R = NO_ERROR) And Not WFound Then R := ERROR_PATH_NOT_FOUND;
  If (R = NO_ERROR) And Not DeIsDir Then R := ERROR_DIRECTORY;
  If R = NO_ERROR Then
  Begin
    Name := DeName;
    R := NtRemove(V, WDir, DeRec, True);
    If R = NO_ERROR Then LogChange(V, WDir, 2, Name);
  End;
  FS_RMDIR := R;
End;

{ ---------------------------------------------------------------------
  FS_MOVE(pcdfsi, pcdfsd, pSrc, iSrcCurDirEnd, pDst, iDstCurDirEnd,
          flags)
    Renommer ou deplacer un fichier ou un repertoire sur le volume (le
    changement de casse seule est permis). }
Function FS_MOVE(Pcdfsi, Pcdfsd, PSrc, ISrcEnd, PDst, IDstEnd, Flags : LongInt) : LongInt;
Var V, R, SrcDir, DstDir, Rec, O : LongInt; SrcName, DstName : String; IsDir : Boolean;
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
    SrcName := DeName;
    Rec := DeRec;
    IsDir := DeIsDir;
    R := Walk(V, PDst);
    If (R = NO_ERROR) And (WIsRoot Or HasWild(LastComp)) Then R := ERROR_ACCESS_DENIED;
    DstDir := WDir;
    DstName := LastComp;
    If R = NO_ERROR Then R := CheckName(DstName);
    If (R = NO_ERROR) And WFound Then
      If DeRec <> Rec Then R := ERROR_ACCESS_DENIED;
    If (R = NO_ERROR) And IsDir Then
      If IsInside(V, DstDir, Rec) Then R := ERROR_ACCESS_DENIED;
    If (R = NO_ERROR) And (SrcDir = DstDir) And (SrcName = DstName) Then
    Begin
      FS_MOVE := NO_ERROR;
      Exit;
    End;
  End;
  If R = NO_ERROR Then
  Begin
    O := ObjFind(V, Rec);
    If O >= 0 Then ObjSync(O);
    R := NtRename(V, Rec, SrcDir, DstDir, DstName);
    If R = NO_ERROR Then
    Begin
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
    Copier un fichier (donnees, attributs et dates) sur le volume.
    flag bit 0 : remplacer la destination. Un repertoire n'est pas copie
    par le pilote (ERROR_CANNOT_COPY : le noyau le fait lui-meme). }
Function FS_COPY(Flag, Pcdfsi, Pcdfsd, PSrc, ISrcEnd, PDst, IDstEnd, NameType : LongInt) : LongInt;
Var V, R, SrcDir, DstDir, Rec, OS, OD, FPos, Got, Done, Attr, Size, C, Ac, M : LongInt; DstName : String;
Begin
  V := VolOf(Pcdfsi, PSrc);
  OS := -1; OD := -1;
  If V < 0 Then R := ERROR_INVALID_DRIVE
  Else If VolOf(Pcdfsi, PDst) <> V Then R := ERROR_CANNOT_COPY
  Else R := Walk(V, PSrc);
  If (R = NO_ERROR) And (WIsRoot Or HasWild(LastComp)) Then R := ERROR_CANNOT_COPY;
  If (R = NO_ERROR) And Not WFound Then R := ERROR_FILE_NOT_FOUND;
  If (R = NO_ERROR) And DeIsDir Then R := ERROR_CANNOT_COPY;
  If R = NO_ERROR Then
  Begin
    SrcDir := WDir;
    Rec := DeRec;
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
      DeInfo(V, -1, Attr, Size, C, Ac, M);
      If DeRec = Rec Then R := ERROR_ACCESS_DENIED
      Else If (Flag And 1) = 0 Then R := ERROR_FILE_EXISTS
      Else If DeIsDir Or ((Attr And ATTR_READONLY) <> 0) Then R := ERROR_ACCESS_DENIED
      Else If InUse(V, DeRec) Then R := ERROR_SHARING_VIOLATION
      Else R := RemoveFile(V, DstDir);
    End;
  End;
  If R = NO_ERROR Then
  Begin
    If CreateNode(V, DstDir, DstName, Objs[OS].Attr, False) < 0 Then R := LastErr
    Else
    Begin
      OD := ObjGet(V, DstDir);
      If OD < 0 Then R := ERROR_TOO_MANY_OPEN_FILES;
    End;
  End;
  If R = NO_ERROR Then
  Begin
    { donnees }
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
  End;
  If OS >= 0 Then ObjRelease(OS);
  If OD >= 0 Then ObjRelease(OD);
  FS_COPY := R;
End;

{ ---------------------------------------------------------------------
  FS_CHDIR(flag, pcdfsi, pcdfsd, pDir, iCurDirEnd)
    flag 0 : changer de repertoire courant (verifier pDir et remplir la
    zone CDFSD : +0 enregistrement, +4 volume) ; 1 : verifier que le
    repertoire courant (cdi_curdir) existe toujours ; 2 : liberer la zone
    CDFSD. }
Function FS_CHDIR(Flag, Pcdfsi, Pcdfsd, PDir, ICurDirEnd : LongInt) : LongInt;
Var V, R : LongInt;
Begin
  R := NO_ERROR;
  Case Flag Of
    0, 1 :
      Begin
        If Flag = 1 Then PDir := Pcdfsi + 12;
        V := VolOf(Pcdfsi, PDir);
        If V < 0 Then R := ERROR_INVALID_DRIVE Else R := Walk(V, PDir);
        If (R = NO_ERROR) And Not WFound Then R := ERROR_PATH_NOT_FOUND;
        If (R = NO_ERROR) And Not DeIsDir Then R := ERROR_PATH_NOT_FOUND;
        If R = NO_ERROR Then
        Begin
          WrL(Pcdfsd, DeRec);
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
  (FILEFINDBUF3), 2 (FILEFINDBUF4 : cbList) et 3 (FILEFINDBUF3 suivi
  d'une FEA2LIST vide). Rend la longueur ou -1. }
Function PutFind(V, Dst, Room, Level : LongInt; Name : String; Attr, Size, C, Ac, M : LongInt) : LongInt;
Var Need, NPos, R : LongInt;
Begin
  R := -1;
  If Level = 1 Then NPos := 28 Else NPos := 32;
  Need := NPos + 2 + Length(Name);
  If Need <= Room Then
  Begin
    R := Need;
    WrL(Dst, 0);
    PutDT(Dst + 4, C);
    PutDT(Dst + 8, Ac);
    PutDT(Dst + 12, M);
    WrL(Dst + 16, Size);
    WrL(Dst + 20, AllocOf(V, Size));
    WrL(Dst + 24, Attr And $37);
    If Level >= 2 Then WrL(Dst + 28, 4);           { cbList / FEA2LIST vide }
    WrB(Dst + NPos, Length(Name));
    PutStr(Dst + NPos + 1, Name, Length(Name) + 1);
  End;
  PutFind := R;
End;

{ Entree "." ou ".." du repertoire Rec : dates et attributs }
Procedure DotInfo(V, Rec : LongInt; Var Attr, C, Ac, M : LongInt);
Var Size : LongInt;
Begin
  If Not NtRecInfo(V, Rec, Attr, Size, C, Ac, M) Then
  Begin
    C := 0; Ac := 0; M := 0;
  End;
  Attr := ATTR_DIRECTORY;
End;

{ Nom de la cle K (UTF-16) memorise comme dernier nom rendu }
Procedure SetLast(F, K : LongInt);
Var I, N : LongInt;
Begin
  N := RdB(K + $40);
  Finds[F].LastN := N;
  For I := 0 To N - 1 Do Finds[F].LastU[I] := RdW(K + $42 + I * 2);
End;

{ Remplir pData avec au plus *pcMatch entrees de la recherche F }
Function DoFind(F, PData, CbData, PcMatch, Level, Flags : LongInt) : LongInt;
Var V, Want, Cnt, FPos, Prev, L, R, Start, SaveDots, SaveIdx, SaveN, I, K, O,
    Attr, Size, C, Ac, M : LongInt;
    Name : String; Have, Stop : Boolean;
    SaveU : Array[0..255] Of Word;
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
  Start := 0;
  If Level = 3 Then Start := 12;
  Cnt := 0; FPos := Start; Prev := -1;
  Stop := False;
  While (Cnt < Want) And Not Stop Do
  Begin
    SaveDots := Finds[F].Dots;
    SaveIdx := Finds[F].Idx;
    SaveN := Finds[F].LastN;
    For I := 0 To SaveN - 1 Do SaveU[I] := Finds[F].LastU[I];
    Have := False;
    Attr := 0; Size := 0; C := 0; Ac := 0; M := 0;
    If Finds[F].Dots = 0 Then
    Begin
      Finds[F].Dots := 1;
      If (Finds[F].Dir <> ROOT_REC) And MatchMask('.', Finds[F].Mask) And
         AttrOk(ATTR_DIRECTORY, Finds[F].Attr) Then
      Begin
        Name := '.';
        DotInfo(V, Finds[F].Dir, Attr, C, Ac, M);
        Have := True;
      End;
    End
    Else If Finds[F].Dots = 1 Then
    Begin
      Finds[F].Dots := 2;
      Finds[F].Gen := -1;
      If (Finds[F].Dir <> ROOT_REC) And MatchMask('..', Finds[F].Mask) And
         AttrOk(ATTR_DIRECTORY, Finds[F].Attr) Then
      Begin
        Name := '..';
        DotInfo(V, Finds[F].Parent, Attr, C, Ac, M);
        Have := True;
      End;
    End
    Else If Finds[F].Dots = 4 Then
    Begin
      Finds[F].Dots := 3;
      SetKey(Finds[F].Mask);
      If NtLookup(V, Finds[F].Dir) Then
      Begin
        Name := DeName;
        DeInfo(V, ObjFind(V, DeRec), Attr, Size, C, Ac, M);
        If AttrOk(Attr, Finds[F].Attr) Then Have := True;
      End;
    End
    Else If Finds[F].Dots = 3 Then
      Stop := True                                    { nom exact deja rendu }
    Else If Not NtDirList(V, Finds[F].Dir) Then
      Stop := True
    Else
    Begin
      If Finds[F].Gen <> LsGen Then
      Begin
        { liste reconstruite : reprendre apres le dernier nom rendu }
        I := 0;
        If Finds[F].LastN > 0 Then
          While (I < LsN) And
                (NtCollate(V, LsEnt(I) + 12 + $42, RdB(LsEnt(I) + 12 + $40),
                           LongInt(@Finds[F].LastU), Finds[F].LastN) <= 0) Do Inc(I);
        Finds[F].Idx := I;
        Finds[F].Gen := LsGen;
      End;
      If Finds[F].Idx >= LsN Then Stop := True
      Else
      Begin
        I := Finds[F].Idx;
        Inc(Finds[F].Idx);
        LsToDe(I);
        K := DeKey;
        SetLast(F, K);
        Name := DeName;
        O := ObjFind(V, DeRec);
        If O >= 0 Then
        Begin
          Attr := Objs[O].Attr; Size := Objs[O].Size;
          C := Objs[O].CTime; Ac := Objs[O].ATime; M := Objs[O].MTime;
        End
        Else
        Begin
          Attr := DeAttr; Size := DeSize;
          C := FtToUnix(K + 8); M := FtToUnix(K + $10); Ac := FtToUnix(K + $20);
        End;
        If MatchMask(Name, Finds[F].Mask) And AttrOk(Attr, Finds[F].Attr) Then Have := True;
      End;
    End;
    If Have Then
    Begin
      If Prev >= 0 Then FPos := (FPos + 3) And Not 3;
      L := PutFind(V, PData + FPos, CbData - FPos, Level, Name, Attr, Size, C, Ac, M);
      If L < 0 Then
      Begin
        { plus de place : l'entree sera rendue au prochain appel }
        Finds[F].Dots := SaveDots;
        Finds[F].Idx := SaveIdx;
        Finds[F].LastN := SaveN;
        For I := 0 To SaveN - 1 Do Finds[F].LastU[I] := SaveU[I];
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
    Finds[F].Parent := ROOT_REC;
    If WDir <> ROOT_REC Then Finds[F].Parent := NtParent(V, WDir);
    Finds[F].Attr := Attr;
    Finds[F].LastN := 0;
    Finds[F].Idx := 0;
    Finds[F].Gen := -1;
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
Var F, R, I : LongInt; S : String;
Begin
  F := FindOf(Pfsfsd);
  If F < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    S := GetStr(PName);
    Finds[F].Gen := -1;
    If (S = '.') Or (S = '..') Then
    Begin
      If S = '.' Then Finds[F].Dots := 1 Else Finds[F].Dots := 2;
      Finds[F].LastN := 0;
    End
    Else
    Begin
      Finds[F].Dots := 2;
      Finds[F].LastN := Length(S);
      For I := 1 To Length(S) Do Finds[F].LastU[I - 1] := C2U(Ord(S[I]));
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
Var Want, Cnt, FPos, Prev, L, I, V, Size, Attr, C, Ac, M : LongInt;
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
      Size := 0; Attr := 0; C := 0; Ac := 0; M := 0;
      SetKey(ChgLog[I].Name);
      If NtLookup(V, Notes[N].Dir) Then DeInfo(V, ObjFind(V, DeRec), Attr, Size, C, Ac, M);
      If Prev >= 0 Then FPos := (FPos + 3) And Not 3;
      L := PutFind(V, PData + FPos, CbData - FPos, 1, ChgLog[I].Name, Attr, Size, C, Ac, M);
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

{ Changer le nom de volume ($VOLUME_NAME de $Volume) }
Function SetLabel(V : LongInt; S : String) : LongInt;
Var R, A, Ret : LongInt;
Begin
  Ret := ERROR_WRITE_FAULT;
  If Vols[V].RO Then
  Begin
    SetLabel := ERROR_WRITE_PROTECT;
    Exit;
  End;
  R := HAlloc(Vols[V].RecSz);
  If R <> 0 Then
  Begin
    If NtReadRec(V, 3, R) Then
    Begin
      A := NtAttr(V, R, AT_VOLNAME, '');
      If A = 0 Then A := NtAddRes(V, R, AT_VOLNAME, '', Length(S) * 2)
      Else If Not NtResSetLen(V, R, A, Length(S) * 2) Then A := 0;
      If A <> 0 Then
      Begin
        PutUName(NtResVal(A), S);
        If NtWriteRec(V, 3, R) Then Ret := NO_ERROR;
      End;
    End;
    HFree(R);
  End;
  SetLabel := Ret;
End;

{ ---------------------------------------------------------------------
  FS_FSINFO(flag, hVPB, pData, cbData, level)
    flag 0 : interroger ; niveau 1 FSALLOCATE (idFileSystem, cSectorUnit
    = secteurs par cluster, cUnit = clusters, cUnitAvail = clusters
    libres, cbSector : 18 octets), niveau 2 FSINFO (numero de serie,
    longueur et texte du nom de volume, 11 caracteres au plus). flag 1,
    niveau 2 : changer le nom de volume (VOLUMELABEL : longueur, texte). }
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
          WrL(PData + 4, Vols[V].Spc);
          WrL(PData + 8, Vols[V].NClus);
          WrL(PData + 12, Vols[V].FreeClus);
          WrW(PData + 16, 512);
        End;
      2 :
        If CbData < 17 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          S := Copy(GetLabel(V), 1, 11);
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
    If (L > 32) Or (CheckName(S) <> NO_ERROR) And (L > 0) Then R := ERROR_INVALID_NAME
    Else
    Begin
      R := SetLabel(V, S);
      If (R = NO_ERROR) And (Vols[V].PVpfsi <> 0) Then PutStr(Vols[V].PVpfsi + 24, Copy(S, 1, 11), 12);
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
  For I := 0 To MaxVol - 1 Do
    If Vols[I].Used And Vols[I].Mounted Then FlushVol(I);
  If SType = 1 Then ShutDown := True;
  FS_SHUTDOWN := NO_ERROR;
End;

{ Message d'une erreur propre a NTFS (FSCTL_ERROR_INFO) }
Function ErrText(E : LongInt) : String;
Var S : String;
Begin
  Case E Of
    ERROR_INVALID_DATA      : S := 'Structure NTFS endommagee (lancer la verification du volume).';
    ERROR_DISK_FULL         : S := 'Le volume NTFS est plein (ou la liste des clusters du fichier est trop longue).';
    ERROR_EAS_NOT_SUPPORTED : S := 'Les attributs etendus ne sont pas enregistres sur un volume NTFS.';
    ERROR_NOT_DOS_DISK      : S := 'Ce volume n''est pas un volume NTFS.';
    ERROR_WRITE_PROTECT     : S := 'Volume NTFS en lecture seule (version anterieure a 3.0).';
    ERROR_FILENAME_EXCED_RANGE : S := 'Nom de fichier trop long (255 caracteres au plus).';
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
             octets) et d'une liste d'EA (4 octets) : 0 (pas d'EA)
      8000h  formater (NTFS 3.1) : pParm = hVPB, adresse du nom de
             volume (ou 0) ; le volume doit avoir ete presente au pilote
             (FS_MOUNT 0 ou 3)
      8001h  verifier : pParm = hVPB, options (bit 0 : corriger les
             bitmaps) ; pData <- erreurs, clusters et enregistrements
             perdus, repertoires, fichiers, enregistrements de la MFT en
             service, clusters utilises, clusters libres, total des
             clusters, 0 (36 octets)
      8002h  statistiques : pParm = hVPB ; pData <- lectures servies par
             l'antememoire, lectures du disque, clusters libres, total
             des clusters, enregistrements de la MFT, octets par cluster,
             volume modifie, fichiers ouverts, volume mal ferme au montage,
             verification automatique demandee (/AUTOCHECK) }
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
        WrW(PData, 0);
        WrL(PData + 2, 0);
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
            CacheDropVol(V);
            FreeVolMem(V);
            If LenParm >= 8 Then S := GetStr(RdL(PParm + 4)) Else S := '';
            R := FormatVol(V, S);
            If R = NO_ERROR Then R := DevIO(V, DVIO_OPREAD, 0, 1, LongInt(@SecBuf));
            If R = NO_ERROR Then R := MountVol(V, LongInt(@SecBuf));
            If (R = NO_ERROR) And (Vols[V].PVpfsi <> 0) Then
            Begin
              WrL(Vols[V].PVpfsi, Vols[V].Serial);
              PutStr(Vols[V].PVpfsi + 24, Copy(GetLabel(V), 1, 11), 12);
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
          If ((N And 1) <> 0) And Vols[V].RO Then R := ERROR_WRITE_PROTECT
          Else R := CheckVol(V, (N And 1) <> 0, Lost);
          If (R = NO_ERROR) And ((N And 1) <> 0) Then
          Begin
            { volume corrige : il n'est plus marque modifie }
            Vols[V].Dirty := True;
            If FlushVol(V) = NO_ERROR Then Vols[V].WasDirty := False;
          End;
          If R = NO_ERROR Then
          Begin
            WrL(PData, ChkErrors);
            WrL(PData + 4, Lost);
            WrL(PData + 8, ChkDirs);
            WrL(PData + 12, ChkFiles);
            WrL(PData + 16, ChkRecs);
            WrL(PData + 20, ChkUsed);
            WrL(PData + 24, Vols[V].FreeClus);
            WrL(PData + 28, Vols[V].NClus);
            WrL(PData + 32, 0);
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
          WrL(PData + 8, Vols[V].FreeClus);
          WrL(PData + 12, Vols[V].NClus);
          WrL(PData + 16, Vols[V].RecN);
          WrL(PData + 20, Vols[V].Cb);
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
      MoveMem(LongInt(@SecBuf) + 11, PData, 25);
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
    un volume NTFS (ils relevent du noyau). }
Function FS_NMPIPE(Psffsi, Psffsd, OpType, POpRec, PData, PName : LongInt) : LongInt;
Begin
  FS_NMPIPE := ERROR_NOT_SUPPORTED;
End;

{ ---------------------------------------------------------------------
  FS_PROCESSNAME(pNameBuf)
    Mettre un nom sous sa forme canonique (en place) : les points et
    espaces de fin de chaque composant sont retires (regle Win32). }
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
            If (St = NO_ERROR) And (Got < 4096) Then FillMem(RdL(E + 8) + Got, 4096 - Got, 0);
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
  CacheData := 0; RunRA := 0; TmpRA := 0;
  FS_INIT(0, 0, 0);
END.
