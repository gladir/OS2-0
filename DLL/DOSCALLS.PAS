{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 DOSCALLS.DLL de OS/2-0 (API Dos*).
}

Library DOSCALLS;

{ Compilation : OS2PC DOSCALLS.PAS   (produit DOSCALLS.DLL)

  DOSCALLS.DLL est la bibliotheque des services de base d'OS/2 (fonctions
  Dos*). Elle est liee a l'adresse 00C00000h (region des DLL du noyau
  OS2KRNL), chargee au demarrage par le noyau et partagee par tous les
  processus. Ses fonctions suivent la convention _System d'OS/2
  (APIENTRY) : parametres empiles de droite a gauche, pile nettoyee par
  l'appelant, resultat (APIRET, 0 = NO_ERROR) dans EAX.

  Un programme compile avec OS2PC les declare ainsi :

    Function DosBeep(Freq, Duration : LongInt) : LongInt; External 'DOSCALLS';

  Dans OS/2-0, toutes les valeurs passees sont de 32 bits (LongInt) : les
  pointeurs (PULONG, PSZ, PVOID...) sont des adresses lineaires et les
  API 16 bits d'OS/2 1.x (DosAllocSeg, DosChgFilePtr, DosQCurDir...) sont
  fournies avec des parametres 32 bits ; un selecteur y est un numero
  ((index shl 3) or 7) associe a une adresse lineaire.

  DOSCALLS.DLL s'appuie sur la couche de base du noyau (WriteFile,
  CreateFileA, FindFirstFileA, CreateProcessA, HeapAlloc...) importee
  sous les noms K* (partie 2).

  Le noyau OS2KRNL execute un processus a la fois (le parent attend la
  fin de l'enfant) et un seul processus leger : DosCreateThread execute
  le processus leger jusqu'a sa fin (ou le garde suspendu jusqu'a
  DosResumeThread), les minuteries sont verifiees a chaque attente, et
  une attente qui ne pourrait jamais etre satisfaite rend ERROR_TIMEOUT
  ou ERROR_INTERRUPT au lieu de bloquer le systeme.

  Organisation :
    Partie 1  - Constantes et types
    Partie 2  - Importations de la couche de base du noyau
    Partie 3  - Utilitaires (memoire, chaines, appels de pointeurs)
    Partie 4  - Table des handles (fichiers, peripheriques, tuyaux)
    Partie 5  - Fichiers et repertoires
    Partie 6  - Recherche, informations et attributs de fichiers
    Partie 7  - Tuyaux anonymes et nommes
    Partie 8  - Memoire (objets, memoire partagee, segments, sous-allocation)
    Partie 9  - Semaphores (evenement, mutex, MuxWait, systeme, RAM)
    Partie 10 - Temps et minuteries
    Partie 11 - Processus et processus legers
    Partie 12 - Exceptions et signaux
    Partie 13 - Modules et ressources
    Partie 14 - Pays, pages de codes, messages et erreurs
    Partie 15 - Systeme, peripheriques, moniteurs et VDD
    Partie 16 - Fonctions internes et diverses
    Exportations et initialisation }

{$R-,S-,I-}

{ ==================================================================== }
{ Partie 1 - Constantes et types                                       }
{ ==================================================================== }

Const
  { Codes d'erreur (APIRET) }
  NO_ERROR                   = 0;
  ERROR_INVALID_FUNCTION     = 1;
  ERROR_FILE_NOT_FOUND       = 2;
  ERROR_PATH_NOT_FOUND       = 3;
  ERROR_TOO_MANY_OPEN_FILES  = 4;
  ERROR_ACCESS_DENIED        = 5;
  ERROR_INVALID_HANDLE       = 6;
  ERROR_NOT_ENOUGH_MEMORY    = 8;
  ERROR_INVALID_ACCESS       = 12;
  ERROR_INVALID_DATA         = 13;
  ERROR_INVALID_DRIVE        = 15;
  ERROR_CURRENT_DIRECTORY    = 16;
  ERROR_NO_MORE_FILES        = 18;
  ERROR_WRITE_PROTECT        = 19;
  ERROR_NOT_READY            = 21;
  ERROR_BAD_COMMAND          = 22;
  ERROR_BAD_LENGTH           = 24;
  ERROR_SHARING_VIOLATION    = 32;
  ERROR_LOCK_VIOLATION       = 33;
  ERROR_NOT_SUPPORTED        = 50;
  ERROR_FILE_EXISTS          = 80;
  ERROR_INVALID_PARAMETER    = 87;
  ERROR_INTERRUPT            = 95;
  ERROR_TOO_MANY_SEMAPHORES  = 100;
  ERROR_EXCL_SEM_ALREADY_OWNED = 101;
  ERROR_SEM_IS_SET           = 102;
  ERROR_TOO_MANY_SEM_REQUESTS = 103;
  ERROR_SEM_OWNER_DIED       = 105;
  ERROR_BROKEN_PIPE          = 109;
  ERROR_OPEN_FAILED          = 110;
  ERROR_BUFFER_OVERFLOW      = 111;
  ERROR_INVALID_TARGET_HANDLE = 114;
  ERROR_INVALID_CATEGORY     = 117;
  ERROR_CALL_NOT_IMPLEMENTED = 120;
  ERROR_SEM_TIMEOUT          = 121;
  ERROR_INSUFFICIENT_BUFFER  = 122;
  ERROR_INVALID_NAME         = 123;
  ERROR_INVALID_LEVEL        = 124;
  ERROR_MOD_NOT_FOUND        = 126;
  ERROR_PROC_NOT_FOUND       = 127;
  ERROR_WAIT_NO_CHILDREN     = 128;
  ERROR_CHILD_NOT_COMPLETE   = 129;
  ERROR_NEGATIVE_SEEK        = 131;
  ERROR_SEEK_ON_DEVICE       = 132;
  ERROR_DIR_NOT_EMPTY        = 145;
  ERROR_SIGNAL_REFUSED       = 156;
  ERROR_NOT_LOCKED           = 158;
  ERROR_INVALID_SEGMENT_NUMBER = 180;
  ERROR_INVALID_ORDINAL      = 182;
  ERROR_ALREADY_EXISTS       = 183;
  ERROR_SEM_NOT_FOUND        = 187;
  ERROR_INVALID_EXE_SIGNATURE = 191;
  ERROR_BAD_EXE_FORMAT       = 193;
  ERROR_ENVVAR_NOT_FOUND     = 203;
  ERROR_INVALID_SIGNAL_NUMBER = 209;
  ERROR_PIPE_BUSY            = 231;
  ERROR_NO_DATA              = 232;
  ERROR_PIPE_NOT_CONNECTED   = 233;
  ERROR_MORE_DATA            = 234;
  ERROR_EA_LIST_INCONSISTENT = 255;
  ERROR_INVALID_EA_NAME      = 254;
  ERROR_NO_MORE_ITEMS        = 259;
  ERROR_INVALID_FLAG_NUMBER  = 186;
  ERROR_DIRECTORY            = 267;
  ERROR_DUPLICATE_NAME       = 285;
  ERROR_EMPTY_MUXWAIT        = 286;
  ERROR_MUTEX_OWNED          = 287;
  ERROR_NOT_OWNER            = 288;
  ERROR_PARAM_TOO_SMALL      = 289;
  ERROR_TOO_MANY_HANDLES     = 290;
  ERROR_TOO_MANY_OPENS       = 291;
  ERROR_WRONG_TYPE           = 292;
  ERROR_THREAD_NOT_TERMINATED = 294;
  ERROR_INIT_ROUTINE_FAILED  = 295;
  ERROR_MODULE_IN_USE        = 296;
  ERROR_NOT_ENOUGH_WATCHPOINTS = 297;
  ERROR_TOO_MANY_POSTS       = 298;
  ERROR_ALREADY_POSTED       = 299;
  ERROR_ALREADY_RESET        = 300;
  ERROR_SEM_BUSY             = 301;
  ERROR_INVALID_PROCID       = 303;
  ERROR_INVALID_PDELTA       = 304;
  ERROR_INVALID_PCLASS       = 306;
  ERROR_INVALID_SCOPE        = 307;
  ERROR_INVALID_THREADID     = 309;
  ERROR_DOSSUB_SHRINK        = 310;
  ERROR_DOSSUB_NOMEM         = 311;
  ERROR_DOSSUB_OVERLAP       = 312;
  ERROR_DOSSUB_BADSIZE       = 313;
  ERROR_DOSSUB_BADFLAG       = 314;
  ERROR_DOSSUB_BADSELECTOR   = 315;
  ERROR_MR_MSG_TOO_LONG      = 316;
  ERROR_MR_MID_NOT_FOUND     = 317;
  ERROR_MR_UN_ACC_MSGF       = 318;
  ERROR_MR_INV_MSGF_FORMAT   = 319;
  ERROR_MR_INV_IVCOUNT       = 320;
  ERROR_MR_UN_PERFORM        = 321;
  ERROR_TS_WAKEUP            = 322;
  ERROR_TS_SEMHANDLE         = 323;
  ERROR_TS_NOTIMER           = 324;
  ERROR_TS_HANDLE            = 326;
  ERROR_TS_DATETIME          = 327;
  ERROR_SYS_INTERNAL         = 328;
  ERROR_QUE_CURRENT_NAME     = 329;
  ERROR_INVALID_CODE_PAGE    = 470;
  ERROR_CRITSEC_OVERFLOW     = 484;
  ERROR_CRITSEC_UNDERFLOW    = 485;
  ERROR_INVALID_ADDRESS      = 487;
  ERROR_INVALID_EXCEPTION_HANDLER = 499;
  ERROR_TIMEOUT              = 640;
  ERROR_VDD_NOT_FOUND        = 645;
  ERROR_INVALID_CALLER       = 646;

  { Ouverture de fichiers }
  OPEN_ACTION_FAIL_IF_EXISTS    = $0000;
  OPEN_ACTION_OPEN_IF_EXISTS    = $0001;
  OPEN_ACTION_REPLACE_IF_EXISTS = $0002;
  OPEN_ACTION_FAIL_IF_NEW       = $0000;
  OPEN_ACTION_CREATE_IF_NEW     = $0010;
  OPEN_ACCESS_READONLY          = $0000;
  OPEN_ACCESS_WRITEONLY         = $0001;
  OPEN_ACCESS_READWRITE         = $0002;
  OPEN_FLAGS_NOINHERIT          = $0080;
  FILE_EXISTED  = 1;
  FILE_CREATED  = 2;
  FILE_TRUNCATED = 3;
  FILE_BEGIN    = 0;
  FILE_CURRENT  = 1;
  FILE_END      = 2;
  FILE_READONLY  = $01;
  FILE_HIDDEN    = $02;
  FILE_SYSTEM    = $04;
  FILE_DIRECTORY = $10;
  FILE_ARCHIVED  = $20;
  HDIR_SYSTEM    = 1;
  HDIR_CREATE    = -1;
  FIL_STANDARD   = 1;
  FIL_QUERYEASIZE = 2;
  FIL_QUERYEASFROMLIST = 3;
  FIL_QUERYFULLNAME = 5;

  { Memoire }
  PAG_READ     = $0001;
  PAG_WRITE    = $0002;
  PAG_EXECUTE  = $0004;
  PAG_GUARD    = $0008;
  PAG_COMMIT   = $0010;
  PAG_DECOMMIT = $0020;
  OBJ_TILE     = $0040;
  OBJ_GIVEABLE = $0200;
  OBJ_GETTABLE = $0400;
  PAG_SHARED   = $2000;
  PAG_FREE     = $4000;
  PAG_BASE     = $10000;
  DOSSUB_INIT       = $01;
  DOSSUB_GROW       = $02;
  DOSSUB_SPARSE_OBJ = $04;
  DOSSUB_SERIALIZE  = $08;

  { Semaphores }
  SEM_INDEFINITE_WAIT = -1;
  SEM_IMMEDIATE_RETURN = 0;
  DC_SEM_SHARED   = $01;
  DCMW_WAIT_ANY   = $02;
  DCMW_WAIT_ALL   = $04;

  { Processus }
  EXEC_SYNC        = 0;
  EXEC_ASYNC       = 1;
  EXEC_ASYNCRESULT = 2;
  EXEC_TRACE       = 3;
  EXEC_BACKGROUND  = 4;
  EXEC_LOAD        = 5;
  EXEC_ASYNCRESULTDB = 6;
  EXIT_THREAD  = 0;
  EXIT_PROCESS = 1;
  TC_EXIT      = 0;
  TC_HARDERROR = 1;
  TC_TRAP      = 2;
  TC_KILLPROCESS = 3;
  TC_EXCEPTION = 4;
  DCWA_PROCESS = 0;
  DCWA_PROCESSTREE = 1;
  DCWW_WAIT    = 0;
  DCWW_NOWAIT  = 1;
  EXLST_ADD    = 1;
  EXLST_REMOVE = 2;
  EXLST_EXIT   = 3;
  CREATE_READY = 0;
  CREATE_SUSPENDED = 1;

  { Exceptions }
  XCPT_CONTINUE_SEARCH    = 0;
  XCPT_CONTINUE_EXECUTION = -1;
  XCPT_CONTINUE_STOP      = $00716668;
  EH_NONCONTINUABLE = $01;
  EH_UNWINDING      = $02;
  EH_EXIT_UNWIND    = $04;
  XCPT_SIGNAL                 = $C0010003;
  XCPT_SIGNAL_INTR            = 1;
  XCPT_SIGNAL_KILLPROC        = 3;
  XCPT_SIGNAL_BREAK           = 4;
  XCPT_ACCESS_VIOLATION       = $C0000005;
  XCPT_ILLEGAL_INSTRUCTION    = $C000001C;
  XCPT_FLOAT_INVALID_OPERATION = $C0000097;
  XCPT_INTEGER_DIVIDE_BY_ZERO = $C000009B;
  XCPT_INTEGER_OVERFLOW       = $C000009C;
  XCPT_PROCESS_TERMINATE      = $C0010001;

  { Informations systeme (DosQuerySysInfo) }
  QSV_MAX_PATH_LENGTH = 1;
  QSV_MS_COUNT        = 14;
  QSV_TIME_LOW        = 15;
  QSV_MAX             = 26;

  { Handles OS/2 : 0 entree standard, 1 sortie standard, 2 erreurs }
  MaxH       = 64;
  HK_FREE    = 0;
  HK_FILE    = 1;      { fichier du noyau (CreateFileA) }
  HK_DEV     = 2;      { peripherique (CON, NUL, entree/sortie standard) }
  HK_PIPER   = 3;      { tuyau anonyme : lecture }
  HK_PIPEW   = 4;      { tuyau anonyme : ecriture }
  HK_NPSRV   = 5;      { tuyau nomme : serveur }
  HK_NPCLI   = 6;      { tuyau nomme : client }

  OS2Major = 20;       { OS/2 2.x : version 20.00 }
  OS2Minor = 0;

Type
  THandleRec = Record
    Kind    : LongInt;
    KH      : LongInt;       { handle du noyau }
    Pipe    : LongInt;       { tuyau associe }
    Mode    : LongInt;       { mode d'ouverture (DosQueryFHState) }
    Owner   : LongInt;       { processus }
    LockId  : LongInt;       { DosProtect* }
    Path    : String[127];
  End;

Var
  Hd        : Array[0..MaxH - 1] Of THandleRec;
  KStdIn, KStdOut, KStdErr : LongInt;
  LastErr   : LongInt;       { erreur du noyau convertie }
  Verify    : LongInt;
  HardErrMode : LongInt;
  MaxFH     : LongInt;
  NextLock  : LongInt;
  Scratch   : Array[0..1023] Of Byte;   { tampons de travail }
  Scratch2  : Array[0..1023] Of Byte;
  ProcInfo  : Array[0..3] Of LongInt;   { PROCESS_INFORMATION }
  StartInfo : Array[0..16] Of LongInt;  { STARTUPINFO }

{ ==================================================================== }
{ Partie 2 - Importations de la couche de base du noyau                }
{ ==================================================================== }
{ Fonctions exportees par OS2KRNL (convention stdcall, noms Win32) ; elles
  sont renommees K* pour ne pas masquer les fonctions du runtime. }

Function KGetStdHandle(N : LongInt) : LongInt; External 'DOSCALLS' Name 'GetStdHandle';
Function KReadFile(H, Buf, N, PRead, Ovl : LongInt) : LongInt; External 'DOSCALLS' Name 'ReadFile';
Function KWriteFile(H, Buf, N, PWritten, Ovl : LongInt) : LongInt; External 'DOSCALLS' Name 'WriteFile';
Function KCreateFileA(PName, Access, Share, Sec, Disp, Flags, Templ : LongInt) : LongInt; External 'DOSCALLS' Name 'CreateFileA';
Function KCloseHandle(H : LongInt) : LongInt; External 'DOSCALLS' Name 'CloseHandle';
Function KSetFilePointer(H, Dist, PHigh, Method : LongInt) : LongInt; External 'DOSCALLS' Name 'SetFilePointer';
Function KGetFileSize(H, PHigh : LongInt) : LongInt; External 'DOSCALLS' Name 'GetFileSize';
Function KSetEndOfFile(H : LongInt) : LongInt; External 'DOSCALLS' Name 'SetEndOfFile';
Function KFlushFileBuffers(H : LongInt) : LongInt; External 'DOSCALLS' Name 'FlushFileBuffers';
Function KGetFileAttributesA(PName : LongInt) : LongInt; External 'DOSCALLS' Name 'GetFileAttributesA';
Function KSetFileAttributesA(PName, Attr : LongInt) : LongInt; External 'DOSCALLS' Name 'SetFileAttributesA';
Function KDeleteFileA(PName : LongInt) : LongInt; External 'DOSCALLS' Name 'DeleteFileA';
Function KMoveFileA(PSrc, PDst : LongInt) : LongInt; External 'DOSCALLS' Name 'MoveFileA';
Function KCreateDirectoryA(PName, Sec : LongInt) : LongInt; External 'DOSCALLS' Name 'CreateDirectoryA';
Function KRemoveDirectoryA(PName : LongInt) : LongInt; External 'DOSCALLS' Name 'RemoveDirectoryA';
Function KSetCurrentDirectoryA(PName : LongInt) : LongInt; External 'DOSCALLS' Name 'SetCurrentDirectoryA';
Function KGetCurrentDirectoryA(N, Buf : LongInt) : LongInt; External 'DOSCALLS' Name 'GetCurrentDirectoryA';
Function KGetFullPathNameA(PName, N, Buf, PFile : LongInt) : LongInt; External 'DOSCALLS' Name 'GetFullPathNameA';
Function KFindFirstFileA(PName, P : LongInt) : LongInt; External 'DOSCALLS' Name 'FindFirstFileA';
Function KFindNextFileA(H, P : LongInt) : LongInt; External 'DOSCALLS' Name 'FindNextFileA';
Function KFindClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'FindClose';
Function KGetFileTime(H, PC, PA, PW : LongInt) : LongInt; External 'DOSCALLS' Name 'GetFileTime';
Function KSetFileTime(H, PC, PA, PW : LongInt) : LongInt; External 'DOSCALLS' Name 'SetFileTime';
Function KFileTimeToDosDateTime(Ft, PDate, PTime : LongInt) : LongInt; External 'DOSCALLS' Name 'FileTimeToDosDateTime';
Function KDosDateTimeToFileTime(DDate, DTime, Ft : LongInt) : LongInt; External 'DOSCALLS' Name 'DosDateTimeToFileTime';
Procedure KGetLocalTime(P : LongInt); External 'DOSCALLS' Name 'GetLocalTime';
Function KSetLocalTime(P : LongInt) : LongInt; External 'DOSCALLS' Name 'SetLocalTime';
Function KGetTickCount : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Procedure KSleep(Ms : LongInt); External 'DOSCALLS' Name 'Sleep';
Procedure KBeep(Freq, Dur : LongInt); External 'DOSCALLS' Name 'Beep';
Function KGetLastError : LongInt; External 'DOSCALLS' Name 'GetLastError';
Function KGetCommandLineA : LongInt; External 'DOSCALLS' Name 'GetCommandLineA';
Function KGetEnvironmentStringsA : LongInt; External 'DOSCALLS' Name 'GetEnvironmentStringsA';
Function KGetEnvironmentVariableA(PName, Buf, Size : LongInt) : LongInt; External 'DOSCALLS' Name 'GetEnvironmentVariableA';
Function KCreateProcessA(App, Cmd, PA, TA, Inh, Flags, Env, Dir, SI, PI : LongInt) : LongInt; External 'DOSCALLS' Name 'CreateProcessA';
Function KGetExitCodeProcess(H, PCode : LongInt) : LongInt; External 'DOSCALLS' Name 'GetExitCodeProcess';
Procedure KExitProcess(Code : LongInt); External 'DOSCALLS' Name 'ExitProcess';
Function KHeapAlloc(Heap, Flags, Size : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapAlloc';
Function KHeapFree(Heap, Flags, A : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapFree';
Function KHeapSize(Heap, Flags, A : LongInt) : LongInt; External 'DOSCALLS' Name 'HeapSize';
Function KGetDiskFreeSpaceA(PRoot, PSpc, PBps, PFree, PTotal : LongInt) : LongInt; External 'DOSCALLS' Name 'GetDiskFreeSpaceA';
Function KSetUnhandledExceptionFilter(F : LongInt) : LongInt; External 'DOSCALLS' Name 'SetUnhandledExceptionFilter';
Function KPeekConsoleInputA(H, P, N, PRead : LongInt) : LongInt; External 'DOSCALLS' Name 'PeekConsoleInputA';
Function KReadConsoleInputA(H, P, N, PRead : LongInt) : LongInt; External 'DOSCALLS' Name 'ReadConsoleInputA';
Function KGetNumberOfConsoleInputEvents(H, PCount : LongInt) : LongInt; External 'DOSCALLS' Name 'GetNumberOfConsoleInputEvents';
Function KLoadLibraryA(PName : LongInt) : LongInt; External 'DOSCALLS' Name 'LoadLibraryA';
Function KGetProcAddress(H, PName : LongInt) : LongInt; External 'DOSCALLS' Name 'GetProcAddress';
Function KFreeLibrary(H : LongInt) : LongInt; External 'DOSCALLS' Name 'FreeLibrary';
Function KGetModuleFileNameA(H, Buf, Size : LongInt) : LongInt; External 'DOSCALLS' Name 'GetModuleFileNameA';
Function KGetModuleHandleA(PName : LongInt) : LongInt; External 'DOSCALLS' Name 'GetModuleHandleA';
Function KGetVolumeInformationA(PRoot, PVol, VolSize, PSerial, PMax, PFlags, PFs, FsSize : LongInt) : LongInt; External 'DOSCALLS' Name 'GetVolumeInformationA';
Procedure KGlobalMemoryStatus(P : LongInt); External 'DOSCALLS' Name 'GlobalMemoryStatus';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KGetParentPid : LongInt; External 'DOSCALLS' Name 'KrnGetParentPid';
Function KModuleFromAddr(A : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnModuleFromAddr';

{ ==================================================================== }
{ Partie 3 - Utilitaires                                               }
{ ==================================================================== }
{ Les adresses sont des LongInt ; on y accede par un pointeur type
  initialise par P := Pointer(Adresse). }

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Function PeekL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  PeekL := P^;
End;

Procedure PokeL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V;
End;

Function PeekW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  PeekW := P^;
End;

Procedure PokeW(A, V : LongInt);
Var P : PWord;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FFFF;
End;

Function PeekB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  PeekB := P^;
End;

Procedure PokeB(A, V : LongInt);
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
    While PeekB(A + N) <> 0 Do Inc(N);
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
    C := PeekB(A);
    While (C <> 0) And (N < 255) Do
    Begin
      S := S + Chr(C);
      Inc(N);
      C := PeekB(A + N);
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
  For I := 1 To L Do PokeB(A + I - 1, Ord(S[I]));
  PokeB(A + L, 0);
End;

{ Chaine Pascal en ASCIIZ dans un tampon de travail ; rend son adresse }
Function Z(S : String; N : LongInt) : LongInt;
Var A : LongInt;
Begin
  If N = 0 Then A := LongInt(@Scratch) Else A := LongInt(@Scratch2);
  PutStr(A, S, 512);
  Z := A;
End;

Function UpStr(S : String) : String;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do
    If (S[I] >= 'a') And (S[I] <= 'z') Then S[I] := Chr(Ord(S[I]) - 32);
  UpStr := S;
End;

Function CrLf : String;
Begin
  CrLf := Chr(13) + Chr(10);
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function Trim(S : String) : String;
Begin
  While (Length(S) > 0) And (S[1] = ' ') Do Delete(S, 1, 1);
  While (Length(S) > 0) And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
  Trim := S;
End;

{ Memoire partagee (tas 2 du noyau : jamais liberee a la fin d'un processus) }
Function SharedAlloc(N : LongInt) : LongInt;
Begin
  SharedAlloc := KHeapAlloc(2, 8, N);
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

{ Erreur du noyau -> code OS/2 }
Function KErr : LongInt;
Var E : LongInt;
Begin
  E := KGetLastError;
  If E = 0 Then E := ERROR_INVALID_FUNCTION;
  If E = 183 Then E := ERROR_ACCESS_DENIED;
  KErr := E;
End;

{ Appels de pointeurs de fonctions (convention _System : le dernier
  parametre est empile en premier, pile nettoyee par l'appelant) }
Function CallPtr0(F : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,F
    call eax
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPtr0 := R;
End;

Function CallPtr1(F, A1 : LongInt) : LongInt;
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
  CallPtr1 := R;
End;

Function CallPtr2(F, A1, A2 : LongInt) : LongInt;
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
  CallPtr2 := R;
End;

Function CallPtr4(F, A1, A2, A3, A4 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
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
    add esp,16
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPtr4 := R;
End;

{ Date et heure DOS compactees (date shl 16 or heure) <-> FDATE/FTIME }
Function NowDos : LongInt;
Var T : Array[0..7] Of Word; D : LongInt;
Begin
  KGetLocalTime(LongInt(@T));
  D := ((T[0] - 1980) Shl 9) Or (T[1] Shl 5) Or T[3];
  NowDos := (D Shl 16) Or ((T[4] Shl 11) Or (T[5] Shl 5) Or (T[6] Div 2));
End;

{ ==================================================================== }
{ Partie 4 - Table des handles                                         }
{ ==================================================================== }

Procedure InitHandles;
Var I : LongInt;
Begin
  For I := 0 To MaxH - 1 Do Hd[I].Kind := HK_FREE;
  KStdIn := KGetStdHandle(-10);
  KStdOut := KGetStdHandle(-11);
  KStdErr := KGetStdHandle(-12);
  MaxFH := 20;
  NextLock := $1000;
End;

{ Les handles 0, 1 et 2 sont toujours les entrees/sorties standard ; les
  autres appartiennent au processus qui les a ouverts. }
Function HValid(H : LongInt) : Boolean;
Begin
  HValid := False;
  If (H >= 0) And (H <= 2) Then
  Begin
    HValid := True;
    Exit;
  End;
  If (H < 3) Or (H >= MaxH) Then Exit;
  HValid := (Hd[H].Kind <> HK_FREE) And (Hd[H].Owner = MyPid);
End;

Function HKind(H : LongInt) : LongInt;
Begin
  If (H >= 0) And (H <= 2) And (Hd[H].Kind = HK_FREE) Then HKind := HK_DEV
  Else HKind := Hd[H].Kind;
End;

{ handle du noyau d'un handle OS/2 }
Function HKernel(H : LongInt) : LongInt;
Begin
  If (H >= 0) And (H <= 2) And (Hd[H].Kind = HK_FREE) Then
  Begin
    If H = 0 Then HKernel := KStdIn
    Else If H = 1 Then HKernel := KStdOut
    Else HKernel := KStdErr;
  End
  Else
    HKernel := Hd[H].KH;
End;

Function HAlloc : LongInt;
Var I, Pid : LongInt;
Begin
  HAlloc := -1;
  Pid := MyPid;
  For I := 3 To MaxH - 1 Do
    If Hd[I].Kind = HK_FREE Then
    Begin
      Hd[I].Kind := HK_DEV; Hd[I].KH := -1; Hd[I].Pipe := -1;
      Hd[I].Mode := 0; Hd[I].Owner := Pid; Hd[I].LockId := 0; Hd[I].Path := '';
      HAlloc := I;
      Exit;
    End;
  { table pleine : reprendre les handles d'autres processus (termines) }
  For I := 3 To MaxH - 1 Do
    If Hd[I].Owner <> Pid Then
    Begin
      Hd[I].Kind := HK_DEV; Hd[I].KH := -1; Hd[I].Pipe := -1;
      Hd[I].Mode := 0; Hd[I].Owner := Pid; Hd[I].LockId := 0; Hd[I].Path := '';
      HAlloc := I;
      Exit;
    End;
End;

{ Nombre de handles OS/2 partageant le meme handle du noyau }
Function KRefCount(KH : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxH - 1 Do
    If ((Hd[I].Kind = HK_FILE) Or (Hd[I].Kind = HK_DEV)) And (Hd[I].KH = KH) Then Inc(N);
  KRefCount := N;
End;

{ ==================================================================== }
{ Partie 5 - Fichiers et repertoires                                   }
{ ==================================================================== }

Function PipeRead(H, Buf, N : LongInt) : LongInt; Forward;
Function PipeWrite(H, Buf, N : LongInt; Var Written : LongInt) : LongInt; Forward;
Procedure PipeCloseEnd(H : LongInt); Forward;
Function NpClientOpen(Name : String; Var H : LongInt) : LongInt; Forward;

Function IsDevName(S : String) : Boolean;
Begin
  S := UpStr(S);
  If (Length(S) > 0) And (S[Length(S)] = ':') Then Delete(S, Length(S), 1);
  IsDevName := (S = 'CON') Or (S = 'NUL') Or (S = 'KBD$') Or (S = 'SCREEN$') Or
               (S = 'CLOCK$') Or (S = 'PRN') Or (S = 'LPT1') Or (S = 'COM1');
End;

{ Ouverture commune a DosOpen, DosOpen2, DosOpenL et DosProtectOpen }
Function OpenFile(PName, PHf, PAction, CbFile, Attr, Flags, Mode : LongInt) : LongInt;
Var
  Name, U : String; H, KH, Access, Disp, A, Action, Written, I : LongInt;
  Exists : Boolean;
Begin
  Name := Trim(GetStr(PName));
  U := UpStr(Name);
  If Name = '' Then
  Begin
    OpenFile := ERROR_FILE_NOT_FOUND;
    Exit;
  End;
  { tuyau nomme (client) }
  If Copy(U, 1, 6) = '\PIPE\' Then
  Begin
    I := NpClientOpen(U, H);
    If I = NO_ERROR Then
    Begin
      PokeL(PHf, H);
      PokeL(PAction, FILE_EXISTED);
    End;
    OpenFile := I;
    Exit;
  End;
  { peripheriques }
  If IsDevName(U) Then
  Begin
    H := HAlloc;
    If H < 0 Then
    Begin
      OpenFile := ERROR_TOO_MANY_OPEN_FILES;
      Exit;
    End;
    If Copy(U, 1, 3) = 'NUL' Then Name := 'NUL' Else Name := 'CON';
    If (U = 'CLOCK$') Or (Copy(U, 1, 3) = 'PRN') Or (Copy(U, 1, 3) = 'LPT') Or
       (Copy(U, 1, 3) = 'COM') Then Name := 'NUL';
    { imprimante : port parallele du noyau }
    If Copy(U, 1, 3) = 'PRN' Then Name := 'PRN';
    If (Copy(U, 1, 3) = 'LPT') And (Length(U) >= 4) Then
      If (U[4] >= '1') And (U[4] <= '3') Then Name := Copy(U, 1, 4);
    KH := KCreateFileA(Z(Name, 0), $C0000000, 3, 0, 3, $80, 0);
    If KH = -1 Then
    Begin
      Hd[H].Kind := HK_FREE;
      OpenFile := ERROR_OPEN_FAILED;
      Exit;
    End;
    Hd[H].Kind := HK_DEV; Hd[H].KH := KH; Hd[H].Mode := Mode; Hd[H].Path := U;
    PokeL(PHf, H);
    PokeL(PAction, FILE_EXISTED);
    OpenFile := NO_ERROR;
    Exit;
  End;
  A := KGetFileAttributesA(Z(Name, 0));
  Exists := A <> -1;
  If Exists And ((A And FILE_DIRECTORY) <> 0) Then
  Begin
    OpenFile := ERROR_ACCESS_DENIED;
    Exit;
  End;
  Case Mode And 7 Of
    OPEN_ACCESS_WRITEONLY : Access := $40000000;
    OPEN_ACCESS_READWRITE : Access := $C0000000;
  Else
    Access := $80000000;
  End;
  If Exists Then
  Begin
    Case Flags And $0F Of
      OPEN_ACTION_OPEN_IF_EXISTS :
        Begin Disp := 3; Action := FILE_EXISTED; End;
      OPEN_ACTION_REPLACE_IF_EXISTS :
        Begin Disp := 2; Action := FILE_TRUNCATED; End;
    Else
      Begin
        OpenFile := ERROR_OPEN_FAILED;
        Exit;
      End;
    End;
  End
  Else
  Begin
    If (Flags And $F0) = OPEN_ACTION_CREATE_IF_NEW Then
    Begin
      Disp := 1; Action := FILE_CREATED;
      If Access = $80000000 Then Access := $C0000000;
    End
    Else
    Begin
      OpenFile := ERROR_OPEN_FAILED;
      Exit;
    End;
  End;
  H := HAlloc;
  If H < 0 Then
  Begin
    OpenFile := ERROR_TOO_MANY_OPEN_FILES;
    Exit;
  End;
  KH := KCreateFileA(Z(Name, 0), Access, 3, 0, Disp, $80, 0);
  If KH = -1 Then
  Begin
    Hd[H].Kind := HK_FREE;
    OpenFile := KErr;
    Exit;
  End;
  Hd[H].Kind := HK_FILE; Hd[H].KH := KH; Hd[H].Mode := Mode;
  KGetFullPathNameA(Z(Name, 0), 128, LongInt(@Scratch2), 0);
  Hd[H].Path := GetStr(LongInt(@Scratch2));
  { taille initiale (fichier cree ou remplace) et attributs }
  If (Action <> FILE_EXISTED) And (CbFile > 0) Then
  Begin
    FillB(LongInt(@Scratch), 1024, 0);
    I := CbFile;
    While I > 0 Do
    Begin
      If I > 1024 Then A := 1024 Else A := I;
      KWriteFile(KH, LongInt(@Scratch), A, LongInt(@Written), 0);
      I := I - A;
    End;
    KSetFilePointer(KH, 0, 0, FILE_BEGIN);
  End;
  If (Action <> FILE_EXISTED) And ((Attr And $27) <> 0) Then
    KSetFileAttributesA(Z(Hd[H].Path, 0), Attr And $27);
  PokeL(PHf, H);
  PokeL(PAction, Action);
  OpenFile := NO_ERROR;
End;

Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt;
Begin
  DosOpen := OpenFile(PName, PHf, PAction, CbFile, Attr, Flags, Mode);
End;

Function DosOpen2(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop, Res : LongInt) : LongInt;
Begin
  DosOpen2 := OpenFile(PName, PHf, PAction, CbFile, Attr, Flags, Mode);
End;

Function DosOpenL(PName, PHf, PAction, CbLo, CbHi, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt;
Begin
  If CbHi <> 0 Then
  Begin
    DosOpenL := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  DosOpenL := OpenFile(PName, PHf, PAction, CbLo, Attr, Flags, Mode);
End;

Function DosClose(H : LongInt) : LongInt;
Var K : LongInt;
Begin
  If Not HValid(H) Then
  Begin
    DosClose := ERROR_INVALID_HANDLE;
    Exit;
  End;
  K := HKind(H);
  If (K = HK_PIPER) Or (K = HK_PIPEW) Or (K = HK_NPSRV) Or (K = HK_NPCLI) Then
    PipeCloseEnd(H)
  Else If (H > 2) Or (Hd[H].Kind <> HK_FREE) Then
  Begin
    If (Hd[H].KH <> -1) And (KRefCount(Hd[H].KH) <= 1) Then KCloseHandle(Hd[H].KH);
  End;
  Hd[H].Kind := HK_FREE;
  DosClose := NO_ERROR;
End;

Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt;
Var K, Got : LongInt;
Begin
  PokeL(PActual, 0);
  If Not HValid(H) Then
  Begin
    DosRead := ERROR_INVALID_HANDLE;
    Exit;
  End;
  K := HKind(H);
  If (K = HK_PIPER) Or (K = HK_NPSRV) Or (K = HK_NPCLI) Then
  Begin
    Got := PipeRead(H, Buf, Cb);
    If Got < 0 Then
    Begin
      DosRead := -Got;
      Exit;
    End;
    PokeL(PActual, Got);
    DosRead := NO_ERROR;
    Exit;
  End;
  If K = HK_PIPEW Then
  Begin
    DosRead := ERROR_ACCESS_DENIED;
    Exit;
  End;
  If (Hd[H].Kind = HK_FILE) And ((Hd[H].Mode And 7) = OPEN_ACCESS_WRITEONLY) Then
  Begin
    DosRead := ERROR_ACCESS_DENIED;
    Exit;
  End;
  Got := 0;
  If KReadFile(HKernel(H), Buf, Cb, LongInt(@Got), 0) = 0 Then
  Begin
    DosRead := KErr;
    Exit;
  End;
  PokeL(PActual, Got);
  DosRead := NO_ERROR;
End;

Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt;
Var K, Done : LongInt;
Begin
  PokeL(PActual, 0);
  If Not HValid(H) Then
  Begin
    DosWrite := ERROR_INVALID_HANDLE;
    Exit;
  End;
  K := HKind(H);
  If (K = HK_PIPEW) Or (K = HK_NPSRV) Or (K = HK_NPCLI) Then
  Begin
    Done := 0;
    DosWrite := PipeWrite(H, Buf, Cb, Done);
    PokeL(PActual, Done);
    Exit;
  End;
  If K = HK_PIPER Then
  Begin
    DosWrite := ERROR_ACCESS_DENIED;
    Exit;
  End;
  If (Hd[H].Kind = HK_FILE) And ((Hd[H].Mode And 7) = OPEN_ACCESS_READONLY) Then
  Begin
    DosWrite := ERROR_ACCESS_DENIED;
    Exit;
  End;
  Done := 0;
  If KWriteFile(HKernel(H), Buf, Cb, LongInt(@Done), 0) = 0 Then
  Begin
    DosWrite := KErr;
    Exit;
  End;
  PokeL(PActual, Done);
  DosWrite := NO_ERROR;
End;

Function DosReadAsync(H, HSem, PErr, Buf, Cb, PActual : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := DosRead(H, Buf, Cb, PActual);
  PokeL(PErr, R);
  PokeL(HSem, 0);            { semaphore RAM liberee : operation terminee }
  DosReadAsync := NO_ERROR;
End;

Function DosWriteAsync(H, HSem, PErr, Buf, Cb, PActual : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := DosWrite(H, Buf, Cb, PActual);
  PokeL(PErr, R);
  PokeL(HSem, 0);
  DosWriteAsync := NO_ERROR;
End;

Function DosSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Not HValid(H) Then
  Begin
    DosSetFilePtr := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If HKind(H) <> HK_FILE Then
  Begin
    DosSetFilePtr := ERROR_SEEK_ON_DEVICE;
    Exit;
  End;
  If (Method < 0) Or (Method > 2) Then
  Begin
    DosSetFilePtr := ERROR_INVALID_FUNCTION;
    Exit;
  End;
  R := KSetFilePointer(Hd[H].KH, Ib, 0, Method);
  If R = -1 Then
  Begin
    DosSetFilePtr := ERROR_NEGATIVE_SEEK;
    Exit;
  End;
  PokeL(PActual, R);
  DosSetFilePtr := NO_ERROR;
End;

Function DosChgFilePtr(H, Dist, Method, PNewPos : LongInt) : LongInt;
Begin
  DosChgFilePtr := DosSetFilePtr(H, Dist, Method, PNewPos);
End;

Function DosSetFilePtrL(H, IbLo, IbHi, Method, PActual : LongInt) : LongInt;
Var R : LongInt;
Begin
  If (IbHi <> 0) And (IbHi <> -1) Then
  Begin
    DosSetFilePtrL := ERROR_NEGATIVE_SEEK;
    Exit;
  End;
  R := DosSetFilePtr(H, IbLo, Method, PActual);
  PokeL(PActual + 4, 0);
  DosSetFilePtrL := R;
End;

Function DosSetFileSize(H, Cb : LongInt) : LongInt;
Var Cur, Size, N, W, A : LongInt;
Begin
  If Not HValid(H) Or (HKind(H) <> HK_FILE) Then
  Begin
    DosSetFileSize := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If Cb < 0 Then
  Begin
    DosSetFileSize := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Cur := KSetFilePointer(Hd[H].KH, 0, 0, FILE_CURRENT);
  Size := KGetFileSize(Hd[H].KH, 0);
  If Cb < Size Then
  Begin
    KSetFilePointer(Hd[H].KH, Cb, 0, FILE_BEGIN);
    If KSetEndOfFile(Hd[H].KH) = 0 Then
    Begin
      DosSetFileSize := ERROR_ACCESS_DENIED;
      Exit;
    End;
  End
  Else If Cb > Size Then
  Begin
    { agrandir avec des zeros }
    KSetFilePointer(Hd[H].KH, 0, 0, FILE_END);
    FillB(LongInt(@Scratch), 1024, 0);
    N := Cb - Size;
    While N > 0 Do
    Begin
      If N > 1024 Then A := 1024 Else A := N;
      If KWriteFile(Hd[H].KH, LongInt(@Scratch), A, LongInt(@W), 0) = 0 Then
      Begin
        DosSetFileSize := ERROR_ACCESS_DENIED;
        Exit;
      End;
      N := N - A;
    End;
  End;
  If Cur > Cb Then Cur := Cb;
  KSetFilePointer(Hd[H].KH, Cur, 0, FILE_BEGIN);
  DosSetFileSize := NO_ERROR;
End;

Function DosNewSize(H, Cb : LongInt) : LongInt;
Begin
  DosNewSize := DosSetFileSize(H, Cb);
End;

Function DosSetFileSizeL(H, CbLo, CbHi : LongInt) : LongInt;
Begin
  If CbHi <> 0 Then DosSetFileSizeL := ERROR_INVALID_PARAMETER
  Else DosSetFileSizeL := DosSetFileSize(H, CbLo);
End;

Function DosResetBuffer(H : LongInt) : LongInt;
Begin
  If H = -1 Then
  Begin
    DosResetBuffer := NO_ERROR;
    Exit;
  End;
  If Not HValid(H) Then
  Begin
    DosResetBuffer := ERROR_INVALID_HANDLE;
    Exit;
  End;
  KFlushFileBuffers(HKernel(H));
  DosResetBuffer := NO_ERROR;
End;

Function DosBufReset(H : LongInt) : LongInt;
Var K : LongInt;
Begin
  If HValid(H) Then
  Begin
    K := HKind(H);
    If (K = HK_PIPER) Or (K = HK_PIPEW) Or (K = HK_NPSRV) Or (K = HK_NPCLI) Then
      If Hd[H].Pipe < 0 Then
      Begin
        DosBufReset := ERROR_BROKEN_PIPE;
        Exit;
      End;
  End;
  DosBufReset := DosResetBuffer(H);
End;

Function DosDelete(PName : LongInt) : LongInt;
Begin
  If KDeleteFileA(PName) = 0 Then DosDelete := KErr Else DosDelete := NO_ERROR;
End;

Function DosForceDelete(PName : LongInt) : LongInt;
Begin
  { pas de corbeille (DELDIR) : suppression definitive dans les deux cas }
  DosForceDelete := DosDelete(PName);
End;

Function DosMove(POld, PNew : LongInt) : LongInt;
Begin
  If KMoveFileA(POld, PNew) = 0 Then DosMove := KErr Else DosMove := NO_ERROR;
End;

Function DosCreateDir(PName, PEaop2 : LongInt) : LongInt;
Begin
  If KCreateDirectoryA(PName, 0) = 0 Then DosCreateDir := KErr Else DosCreateDir := NO_ERROR;
End;

Function DosMkDir(PName, Reserved : LongInt) : LongInt;
Begin
  DosMkDir := DosCreateDir(PName, 0);
End;

Function DosMkDir2(PName, PEaop, Reserved : LongInt) : LongInt;
Begin
  DosMkDir2 := DosCreateDir(PName, 0);
End;

Function DosDeleteDir(PName : LongInt) : LongInt;
Begin
  If KRemoveDirectoryA(PName) = 0 Then DosDeleteDir := KErr Else DosDeleteDir := NO_ERROR;
End;

Function DosRmDir(PName, Reserved : LongInt) : LongInt;
Begin
  DosRmDir := DosDeleteDir(PName);
End;

Function DosSetCurrentDir(PName : LongInt) : LongInt;
Begin
  If KSetCurrentDirectoryA(PName) = 0 Then DosSetCurrentDir := KErr
  Else DosSetCurrentDir := NO_ERROR;
End;

Function DosChDir(PName, Reserved : LongInt) : LongInt;
Begin
  DosChDir := DosSetCurrentDir(PName);
End;

{ Repertoire courant sans unite ni barre initiale (ex. OS2\DLL) }
Function CurDirRel : String;
Var S : String;
Begin
  KGetCurrentDirectoryA(260, LongInt(@Scratch2));
  S := GetStr(LongInt(@Scratch2));
  If Length(S) >= 3 Then S := Copy(S, 4, 255) Else S := '';
  CurDirRel := S;
End;

{ Unites : C: (CD-ROM d'amorcage et disque virtuel) et les volumes des
  systemes de fichiers installables (HPFS.IFS : D: et suivantes) }
Function CurDrive : LongInt;
Var S : String;
Begin
  KGetCurrentDirectoryA(260, LongInt(@Scratch2));
  S := GetStr(LongInt(@Scratch2));
  If (Length(S) >= 2) And (S[2] = ':') Then CurDrive := Ord(UpCase(S[1])) - 64
  Else CurDrive := 3;
End;

{ Racine "X:\" de l'unite Disk (1 = A:, 0 = unite courante) }
Function DriveRoot(Disk : LongInt) : String;
Begin
  If Disk = 0 Then Disk := CurDrive;
  DriveRoot := Chr(64 + Disk) + ':\';
End;

Function DriveExists(Disk : LongInt) : Boolean;
Var Spc, Bps, Free, Total : LongInt;
Begin
  If Disk = 0 Then Disk := CurDrive;
  If Disk = 3 Then DriveExists := True
  Else If (Disk < 4) Or (Disk > 26) Then DriveExists := False
  Else DriveExists := KGetDiskFreeSpaceA(Z(DriveRoot(Disk), 0), LongInt(@Spc), LongInt(@Bps),
                                         LongInt(@Free), LongInt(@Total)) <> 0;
End;

Function DosQueryCurrentDir(Disk, PBuf, PCb : LongInt) : LongInt;
Var S : String;
Begin
  If Not DriveExists(Disk) Then
  Begin
    DosQueryCurrentDir := ERROR_INVALID_DRIVE;
    Exit;
  End;
  If (Disk = 0) Or (Disk = CurDrive) Then S := CurDirRel Else S := '';
  If PeekL(PCb) < Length(S) + 1 Then
  Begin
    PokeL(PCb, Length(S) + 1);
    DosQueryCurrentDir := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  PutStr(PBuf, S, PeekL(PCb));
  DosQueryCurrentDir := NO_ERROR;
End;

Function DosQCurDir(Drive, PBuf, PCb : LongInt) : LongInt;
Begin
  DosQCurDir := DosQueryCurrentDir(Drive, PBuf, PCb);
End;

Function DosQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt;
Var I, M : LongInt;
Begin
  M := 1 Shl 2;
  For I := 4 To 26 Do
    If DriveExists(I) Then M := M Or (1 Shl (I - 1));
  PokeL(PDisk, CurDrive);
  PokeL(PLogical, M);
  DosQueryCurrentDisk := NO_ERROR;
End;

Function DosQCurDisk(PDisk, PLogical : LongInt) : LongInt;
Begin
  DosQCurDisk := DosQueryCurrentDisk(PDisk, PLogical);
End;

Function DosSetDefaultDisk(Disk : LongInt) : LongInt;
Begin
  If (Disk < 1) Or Not DriveExists(Disk) Then DosSetDefaultDisk := ERROR_INVALID_DRIVE
  Else If Disk = CurDrive Then DosSetDefaultDisk := NO_ERROR
  Else
  Begin
    KSetCurrentDirectoryA(Z(DriveRoot(Disk), 0));
    DosSetDefaultDisk := NO_ERROR;
  End;
End;

Function DosSelectDisk(Drive : LongInt) : LongInt;
Begin
  DosSelectDisk := DosSetDefaultDisk(Drive);
End;

{ Copie d'un fichier (ou des fichiers d'un repertoire) }
Function CopyOneFile(Src, Dst : String; Option : LongInt) : LongInt;
Var HS, HD, Got, W, Disp, A : LongInt;
Begin
  HS := KCreateFileA(Z(Src, 0), $80000000, 3, 0, 3, $80, 0);
  If HS = -1 Then
  Begin
    CopyOneFile := KErr;
    Exit;
  End;
  A := KGetFileAttributesA(Z(Dst, 1));
  If (A <> -1) And ((Option And 1) = 0) And ((Option And 2) = 0) Then
  Begin
    KCloseHandle(HS);
    CopyOneFile := ERROR_ACCESS_DENIED;
    Exit;
  End;
  If (Option And 2) <> 0 Then Disp := 4 Else Disp := 2;
  HD := KCreateFileA(Z(Dst, 1), $C0000000, 3, 0, Disp, $80, 0);
  If HD = -1 Then
  Begin
    KCloseHandle(HS);
    CopyOneFile := KErr;
    Exit;
  End;
  If (Option And 2) <> 0 Then KSetFilePointer(HD, 0, 0, FILE_END);
  Repeat
    Got := 0;
    KReadFile(HS, LongInt(@Scratch), 1024, LongInt(@Got), 0);
    If Got > 0 Then KWriteFile(HD, LongInt(@Scratch), Got, LongInt(@W), 0);
  Until Got <= 0;
  KCloseHandle(HS);
  KCloseHandle(HD);
  CopyOneFile := NO_ERROR;
End;

Function DosCopy(PSrc, PDst, Option : LongInt) : LongInt;
Var Src, Dst, Nm : String; A, FH, R : LongInt; FD : Array[0..79] Of LongInt;
Begin
  Src := GetStr(PSrc);
  Dst := GetStr(PDst);
  A := KGetFileAttributesA(Z(Src, 0));
  If A = -1 Then
  Begin
    DosCopy := ERROR_FILE_NOT_FOUND;
    Exit;
  End;
  If (A And FILE_DIRECTORY) = 0 Then
  Begin
    { destination repertoire : y copier le fichier sous le meme nom }
    A := KGetFileAttributesA(Z(Dst, 0));
    If (A <> -1) And ((A And FILE_DIRECTORY) <> 0) Then
    Begin
      Nm := Src;
      While Pos('\', Nm) > 0 Do Delete(Nm, 1, Pos('\', Nm));
      If Dst[Length(Dst)] <> '\' Then Dst := Dst + '\';
      Dst := Dst + Nm;
    End;
    DosCopy := CopyOneFile(Src, Dst, Option);
    Exit;
  End;
  { repertoire : copier ses fichiers (et creer la destination) }
  KCreateDirectoryA(Z(Dst, 0), 0);
  If Src[Length(Src)] <> '\' Then Src := Src + '\';
  If Dst[Length(Dst)] <> '\' Then Dst := Dst + '\';
  FH := KFindFirstFileA(Z(Src + '*.*', 0), LongInt(@FD));
  R := NO_ERROR;
  If FH <> -1 Then
  Begin
    Repeat
      Nm := GetStr(LongInt(@FD) + 44);
      If (Nm <> '.') And (Nm <> '..') Then
      Begin
        If (FD[0] And FILE_DIRECTORY) <> 0 Then
          R := DosCopy(Z(Src + Nm, 0), Z(Dst + Nm, 1), Option)
        Else
          R := CopyOneFile(Src + Nm, Dst + Nm, Option);
      End;
    Until (R <> NO_ERROR) Or (KFindNextFileA(FH, LongInt(@FD)) = 0);
    KFindClose(FH);
  End;
  DosCopy := R;
End;

{ Etat d'un handle (mode d'ouverture) }
Function DosQueryFHState(H, PMode : LongInt) : LongInt;
Begin
  If Not HValid(H) Then
  Begin
    DosQueryFHState := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If (H <= 2) And (Hd[H].Kind = HK_FREE) Then
  Begin
    If H = 0 Then PokeL(PMode, OPEN_ACCESS_READONLY) Else PokeL(PMode, OPEN_ACCESS_WRITEONLY);
  End
  Else
    PokeL(PMode, Hd[H].Mode);
  DosQueryFHState := NO_ERROR;
End;

Function DosSetFHState(H, Mode : LongInt) : LongInt;
Begin
  If Not HValid(H) Then
  Begin
    DosSetFHState := ERROR_INVALID_HANDLE;
    Exit;
  End;
  { seuls l'heritage, l'ecriture immediate et le cache sont modifiables }
  If (Mode And Not $6180) <> 0 Then
  Begin
    DosSetFHState := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If (H > 2) Or (Hd[H].Kind <> HK_FREE) Then
    Hd[H].Mode := (Hd[H].Mode And Not $6180) Or Mode;
  DosSetFHState := NO_ERROR;
End;

Function DosQFHandState(H, PMode : LongInt) : LongInt;
Begin
  DosQFHandState := DosQueryFHState(H, PMode);
End;

Function DosSetFHandState(H, Mode : LongInt) : LongInt;
Begin
  DosSetFHandState := DosSetFHState(H, Mode);
End;

{ Type d'un handle : 0 fichier, 1 peripherique, 2 tuyau }
Function DosQueryHType(H, PType, PAttr : LongInt) : LongInt;
Var K : LongInt;
Begin
  If Not HValid(H) Then
  Begin
    DosQueryHType := ERROR_INVALID_HANDLE;
    Exit;
  End;
  K := HKind(H);
  If K = HK_FILE Then
  Begin
    PokeL(PType, 0); PokeL(PAttr, 0);
  End
  Else If K = HK_DEV Then
  Begin
    PokeL(PType, 1);
    If H = 0 Then PokeL(PAttr, $8081) Else If H <= 2 Then PokeL(PAttr, $8082)
    Else PokeL(PAttr, $8080);
  End
  Else
  Begin
    PokeL(PType, 2); PokeL(PAttr, 0);
  End;
  DosQueryHType := NO_ERROR;
End;

Function DosQHandType(H, PType, PAttr : LongInt) : LongInt;
Begin
  DosQHandType := DosQueryHType(H, PType, PAttr);
End;

{ Dupliquer un handle : *PH2 = $FFFFFFFF -> nouveau handle }
Function DosDupHandle(H, PH2 : LongInt) : LongInt;
Var T : LongInt;
Begin
  If Not HValid(H) Then
  Begin
    DosDupHandle := ERROR_INVALID_HANDLE;
    Exit;
  End;
  T := PeekL(PH2);
  If T = -1 Then
  Begin
    T := HAlloc;
    If T < 0 Then
    Begin
      DosDupHandle := ERROR_TOO_MANY_OPEN_FILES;
      Exit;
    End;
  End
  Else
  Begin
    If (T < 0) Or (T >= MaxH) Then
    Begin
      DosDupHandle := ERROR_INVALID_TARGET_HANDLE;
      Exit;
    End;
    If T = H Then
    Begin
      DosDupHandle := NO_ERROR;
      Exit;
    End;
    If HValid(T) And ((T > 2) Or (Hd[T].Kind <> HK_FREE)) Then DosClose(T);
  End;
  If (H <= 2) And (Hd[H].Kind = HK_FREE) Then
  Begin
    Hd[T].Kind := HK_DEV; Hd[T].KH := HKernel(H); Hd[T].Pipe := -1;
    Hd[T].Mode := 0; Hd[T].Path := 'CON';
  End
  Else
    Hd[T] := Hd[H];
  Hd[T].Owner := MyPid;
  PokeL(PH2, T);
  DosDupHandle := NO_ERROR;
End;

Function DosSetMaxFH(N : LongInt) : LongInt;
Begin
  If (N < 20) Or (N > MaxH) Then
  Begin
    DosSetMaxFH := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  MaxFH := N;
  DosSetMaxFH := NO_ERROR;
End;

Function DosSetRelMaxFH(PReq, PCur : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := MaxFH + PeekL(PReq);
  If N > MaxH Then N := MaxH;
  If N < 20 Then N := 20;
  MaxFH := N;
  PokeL(PCur, MaxFH);
  DosSetRelMaxFH := NO_ERROR;
End;

{ Verrous de plages : un seul processus s'execute a la fois, un verrou
  est donc toujours accorde (le handle et les plages sont verifies). }
Function DosSetFileLocks(H, PUnlock, PLock, Timeout, Flags : LongInt) : LongInt;
Begin
  If Not HValid(H) Or (HKind(H) <> HK_FILE) Then
  Begin
    DosSetFileLocks := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If ((PUnlock <> 0) And (PeekL(PUnlock + 4) < 0)) Or ((PLock <> 0) And (PeekL(PLock + 4) < 0)) Then
  Begin
    DosSetFileLocks := ERROR_LOCK_VIOLATION;
    Exit;
  End;
  DosSetFileLocks := NO_ERROR;
End;

Function DosSetFileLocksL(H, PUnlock, PLock, Timeout, Flags : LongInt) : LongInt;
Begin
  If Not HValid(H) Or (HKind(H) <> HK_FILE) Then DosSetFileLocksL := ERROR_INVALID_HANDLE
  Else DosSetFileLocksL := NO_ERROR;
End;

Function DosFileLocks(H, PUnlock, PLock : LongInt) : LongInt;
Begin
  DosFileLocks := DosSetFileLocks(H, PUnlock, PLock, 0, 0);
End;

Function DosCancelLockRequest(H, PLock : LongInt) : LongInt;
Begin
  If Not HValid(H) Then DosCancelLockRequest := ERROR_INVALID_HANDLE
  Else DosCancelLockRequest := NO_ERROR;
End;

Function DosCancelLockRequestL(H, PLock : LongInt) : LongInt;
Begin
  DosCancelLockRequestL := DosCancelLockRequest(H, PLock);
End;

{ DosFileIO : liste de commandes FIO_LOCK (0), FIO_UNLOCK (1), FIO_SEEK (2),
  FIO_READ (3), FIO_WRITE (4) ; chaque commande commence par un mot de
  commande. Seek : mot cmd, mot methode, mot double position, mot double
  resultat ; Read/Write : mot cmd, mot double tampon, mot cb, mot cbActuel. }
Function DosFileIO(H, PCmd, CbCmd, PError : LongInt) : LongInt;
Var P, Stop, Cmd, R, N, Act : LongInt;
Begin
  P := PCmd;
  Stop := PCmd + CbCmd;
  R := NO_ERROR;
  While (P < Stop) And (R = NO_ERROR) Do
  Begin
    Cmd := PeekW(P);
    Case Cmd Of
      0, 1 : Begin
               N := PeekW(P + 2);
               P := P + 8 + N * 10;
             End;
      2 : Begin
            R := DosSetFilePtr(H, PeekL(P + 4), PeekW(P + 2), P + 8);
            P := P + 12;
          End;
      3, 4 : Begin
               Act := 0;
               If Cmd = 3 Then R := DosRead(H, PeekL(P + 2), PeekW(P + 6), LongInt(@Act))
               Else R := DosWrite(H, PeekL(P + 2), PeekW(P + 6), LongInt(@Act));
               PokeW(P + 8, Act);
               P := P + 10;
             End;
    Else
      R := ERROR_INVALID_FUNCTION;
    End;
  End;
  If R <> NO_ERROR Then PokeL(PError, P - PCmd);
  DosFileIO := R;
End;

{ DosListIO : LISTIO = hFile, CmdFlag (LISTIO_READ 4, LISTIO_WRITE 8 ;
  origine 0/1/2 dans les bits 0-1), Offset, pBuffer, NumBytes, Actual,
  RetCode, Reserved (32 octets par entree) }
Function DoListIO(Count, PList, EntSize : LongInt; Long : Boolean) : LongInt;
Var I, E, Cmd, Ofs, R, Act, Buf, Nb, Pos : LongInt;
Begin
  DoListIO := NO_ERROR;
  For I := 0 To Count - 1 Do
  Begin
    E := PList + I * EntSize;
    Cmd := PeekL(E + 4);
    Ofs := PeekL(E + 8);
    If Long Then
    Begin
      Buf := PeekL(E + 16); Nb := PeekL(E + 20); Pos := 24;
    End
    Else
    Begin
      Buf := PeekL(E + 12); Nb := PeekL(E + 16); Pos := 20;
    End;
    R := DosSetFilePtr(PeekL(E), Ofs, Cmd And 3, LongInt(@Act));
    Act := 0;
    If R = NO_ERROR Then
    Begin
      If (Cmd And 4) <> 0 Then R := DosRead(PeekL(E), Buf, Nb, LongInt(@Act))
      Else If (Cmd And 8) <> 0 Then R := DosWrite(PeekL(E), Buf, Nb, LongInt(@Act))
      Else R := ERROR_INVALID_FUNCTION;
    End;
    PokeL(E + Pos, Act);
    PokeL(E + Pos + 4, R);
    If R <> NO_ERROR Then DoListIO := R;
  End;
End;

Function DosListIO(Mode, Count, PList : LongInt) : LongInt;
Begin
  DosListIO := DoListIO(Count, PList, 32, False);
End;

Function DosListIOL(Mode, Count, PList : LongInt) : LongInt;
Begin
  DosListIOL := DoListIO(Count, PList, 36, True);
End;

{ ==================================================================== }
{ Partie 6 - Recherche, informations et attributs de fichiers          }
{ ==================================================================== }

Const
  MaxFind = 16;

Type
  TFindRec = Record
    Used   : Boolean;
    KH     : LongInt;            { recherche du noyau }
    Attr   : LongInt;            { attributs demandes }
    Owner  : LongInt;
    Pending: Boolean;            { une entree est deja dans FD }
  End;

Var
  Finds   : Array[0..MaxFind - 1] Of TFindRec;
  FD      : Array[0..79] Of LongInt;      { WIN32_FIND_DATA de travail }

{ FDATE/FTIME (mots) a partir d'un FILETIME du noyau }
Procedure FtToFd(Ft, PDate, PTime : LongInt);
Begin
  KFileTimeToDosDateTime(Ft, PDate, PTime);
End;

{ L'entree courante (FD) satisfait-elle les attributs demandes ?
  octet bas : attributs permis (caches, systeme, repertoire) ;
  octet haut : attributs exiges (MUST_HAVE_xxx) }
Function AttrOk(A, Want : LongInt) : Boolean;
Var May, Must : LongInt;
Begin
  May := Want And $37;
  Must := (Want Shr 8) And $37;
  AttrOk := ((A And (FILE_HIDDEN Or FILE_SYSTEM Or FILE_DIRECTORY) And Not May) = 0) And
            ((A And Must) = Must);
End;

{ Ecrire l'entree FD au format FILEFINDBUF3 (niveau 1) ou FILEFINDBUF4
  (niveau 2) ; rend la taille de l'entree ou 0 si elle ne tient pas }
Function PutFindEntry(P, Room, Level : LongInt) : LongInt;
Var Nm : String; NameOfs, Size : LongInt;
Begin
  Nm := GetStr(LongInt(@FD) + 44);
  If Level = FIL_STANDARD Then NameOfs := 28 Else NameOfs := 32;
  Size := NameOfs + 1 + Length(Nm) + 1;
  Size := (Size + 3) And Not 3;
  If Size > Room Then
  Begin
    PutFindEntry := 0;
    Exit;
  End;
  FillB(P, Size, 0);
  PokeL(P, 0);                                    { oNextEntryOffset }
  FtToFd(LongInt(@FD) + 4, P + 4, P + 6);         { creation }
  FtToFd(LongInt(@FD) + 12, P + 8, P + 10);       { dernier acces }
  FtToFd(LongInt(@FD) + 20, P + 12, P + 14);      { derniere ecriture }
  PokeL(P + 16, FD[8]);                           { cbFile }
  PokeL(P + 20, (FD[8] + 2047) And Not 2047);     { cbFileAlloc }
  PokeL(P + 24, FD[0] And $37);                   { attrFile }
  If Level <> FIL_STANDARD Then PokeL(P + 28, 4); { cbList : pas d'EA }
  PokeB(P + NameOfs, Length(Nm));
  PutStr(P + NameOfs + 1, Nm, 256);
  PutFindEntry := Size;
End;

{ Remplir le tampon avec au plus Want entrees ; rend le nombre ecrit }
Function FillFind(F, PBuf, CbBuf, Want, Level : LongInt) : LongInt;
Var N, P, Prev, Sz : LongInt; Have : Boolean;
Begin
  N := 0; P := PBuf; Prev := 0;
  Have := Finds[F].Pending;
  While N < Want Do
  Begin
    If Not Have Then
      Have := KFindNextFileA(Finds[F].KH, LongInt(@FD)) <> 0;
    If Not Have Then Break;
    If AttrOk(FD[0], Finds[F].Attr) Then
    Begin
      Sz := PutFindEntry(P, PBuf + CbBuf - P, Level);
      If Sz = 0 Then Break;               { tampon plein : garder l'entree }
      If Prev <> 0 Then PokeL(Prev, P - Prev);
      Prev := P;
      P := P + Sz;
      Inc(N);
    End;
    Have := False;
  End;
  Finds[F].Pending := Have;
  FillFind := N;
End;

Function FindSlot(H : LongInt) : LongInt;
Begin
  FindSlot := -1;
  If (H >= 1) And (H <= MaxFind) Then
    If Finds[H - 1].Used And (Finds[H - 1].Owner = MyPid) Then FindSlot := H - 1;
End;

Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt;
Var F, H, N, Want, I : LongInt;
Begin
  If (Level <> FIL_STANDARD) And (Level <> FIL_QUERYEASIZE) And
     (Level <> FIL_QUERYEASFROMLIST) Then
  Begin
    DosFindFirst := ERROR_INVALID_LEVEL;
    Exit;
  End;
  H := PeekL(PHDir);
  F := -1;
  If H = HDIR_CREATE Then
  Begin
    For I := 1 To MaxFind - 1 Do
      If (F < 0) And (Not Finds[I].Used Or (Finds[I].Owner <> MyPid)) Then F := I;
  End
  Else If (H = HDIR_SYSTEM) Or (FindSlot(H) >= 0) Then
  Begin
    F := H - 1;
    If Finds[F].Used And (Finds[F].Owner = MyPid) Then KFindClose(Finds[F].KH);
  End;
  If F < 0 Then
  Begin
    DosFindFirst := ERROR_TOO_MANY_OPEN_FILES;
    Exit;
  End;
  Finds[F].KH := KFindFirstFileA(PSpec, LongInt(@FD));
  Finds[F].Used := Finds[F].KH <> -1;
  Finds[F].Attr := Attr;
  Finds[F].Owner := MyPid;
  Finds[F].Pending := True;
  If Not Finds[F].Used Then
  Begin
    PokeL(PCount, 0);
    If KGetLastError = 3 Then DosFindFirst := ERROR_PATH_NOT_FOUND
    Else DosFindFirst := ERROR_NO_MORE_FILES;
    Exit;
  End;
  Want := PeekL(PCount);
  If Want <= 0 Then Want := 1;
  N := FillFind(F, PBuf, CbBuf, Want, Level);
  PokeL(PCount, N);
  PokeL(PHDir, F + 1);
  If N = 0 Then
  Begin
    KFindClose(Finds[F].KH);
    Finds[F].Used := False;
    If Finds[F].Pending Then DosFindFirst := ERROR_BUFFER_OVERFLOW
    Else DosFindFirst := ERROR_NO_MORE_FILES;
    Exit;
  End;
  DosFindFirst := NO_ERROR;
End;

Function DosFindFirst2(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level, Res : LongInt) : LongInt;
Begin
  DosFindFirst2 := DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level);
End;

Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt;
Var F, N, Want : LongInt;
Begin
  F := FindSlot(HDir);
  If F < 0 Then
  Begin
    DosFindNext := ERROR_INVALID_HANDLE;
    Exit;
  End;
  Want := PeekL(PCount);
  If Want <= 0 Then Want := 1;
  N := FillFind(F, PBuf, CbBuf, Want, FIL_STANDARD);
  PokeL(PCount, N);
  If N = 0 Then DosFindNext := ERROR_NO_MORE_FILES Else DosFindNext := NO_ERROR;
End;

Function DosFindClose(HDir : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := FindSlot(HDir);
  If F < 0 Then
  Begin
    DosFindClose := ERROR_INVALID_HANDLE;
    Exit;
  End;
  KFindClose(Finds[F].KH);
  Finds[F].Used := False;
  DosFindClose := NO_ERROR;
End;

{ FILESTATUS3 (24 octets, niveau 1) / FILESTATUS4 (28 octets, niveau 2)
  d'apres une entree de recherche (FD) }
Function PutFileStatus(P, Cb, Level : LongInt) : LongInt;
Var Need : LongInt;
Begin
  If Level = FIL_STANDARD Then Need := 24 Else Need := 28;
  If Cb < Need Then
  Begin
    PutFileStatus := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  FtToFd(LongInt(@FD) + 4, P, P + 2);
  FtToFd(LongInt(@FD) + 12, P + 4, P + 6);
  FtToFd(LongInt(@FD) + 20, P + 8, P + 10);
  PokeL(P + 12, FD[8]);
  PokeL(P + 16, (FD[8] + 2047) And Not 2047);
  PokeL(P + 20, FD[0] And $37);
  If Level <> FIL_STANDARD Then PokeL(P + 24, 4);
  PutFileStatus := NO_ERROR;
End;

{ Remplir FD pour un chemin (repertoire racine compris) }
Function StatPath(Path : String) : LongInt;
Var H : LongInt;
Begin
  If (Length(Path) >= 2) And ((Path[Length(Path)] = '\') Or (Path[Length(Path)] = ':')) And
     (Length(Path) <= 3) Then
  Begin
    FillB(LongInt(@FD), 320, 0);
    FD[0] := FILE_DIRECTORY;
    StatPath := NO_ERROR;
    Exit;
  End;
  H := KFindFirstFileA(Z(Path, 0), LongInt(@FD));
  If H = -1 Then
  Begin
    StatPath := ERROR_FILE_NOT_FOUND;
    If KGetLastError = 3 Then StatPath := ERROR_PATH_NOT_FOUND;
    Exit;
  End;
  KFindClose(H);
  StatPath := NO_ERROR;
End;

Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt;
Var R : LongInt; S : String;
Begin
  If Level = FIL_QUERYFULLNAME Then
  Begin
    R := KGetFullPathNameA(PName, Cb, PInfo, 0);
    If R = 0 Then DosQueryPathInfo := ERROR_INVALID_NAME
    Else If R >= Cb Then DosQueryPathInfo := ERROR_BUFFER_OVERFLOW
    Else DosQueryPathInfo := NO_ERROR;
    Exit;
  End;
  If (Level <> FIL_STANDARD) And (Level <> FIL_QUERYEASIZE) And
     (Level <> FIL_QUERYEASFROMLIST) Then
  Begin
    DosQueryPathInfo := ERROR_INVALID_LEVEL;
    Exit;
  End;
  S := GetStr(PName);
  R := StatPath(S);
  If R <> NO_ERROR Then
  Begin
    DosQueryPathInfo := R;
    Exit;
  End;
  If Level = FIL_QUERYEASFROMLIST Then
  Begin
    { EAOP2 : liste FEA2 vide (aucun attribut etendu) }
    If PeekL(PInfo + 4) <> 0 Then PokeL(PeekL(PInfo + 4), 4);
    DosQueryPathInfo := NO_ERROR;
    Exit;
  End;
  DosQueryPathInfo := PutFileStatus(PInfo, Cb, Level);
End;

Function DosQPathInfo(PName, Level, PInfo, Cb, Res : LongInt) : LongInt;
Begin
  DosQPathInfo := DosQueryPathInfo(PName, Level, PInfo, Cb);
End;

Function DosQueryFileInfo(H, Level, PInfo, Cb : LongInt) : LongInt;
Var R, Size : LongInt; Ft : Array[0..1] Of LongInt;
Begin
  If Not HValid(H) Then
  Begin
    DosQueryFileInfo := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If (Level < FIL_STANDARD) Or (Level > FIL_QUERYEASFROMLIST) Then
  Begin
    DosQueryFileInfo := ERROR_INVALID_LEVEL;
    Exit;
  End;
  If HKind(H) <> HK_FILE Then
  Begin
    { peripherique ou tuyau : dates nulles, taille 0 }
    FillB(LongInt(@FD), 320, 0);
    DosQueryFileInfo := PutFileStatus(PInfo, Cb, Level);
    Exit;
  End;
  R := StatPath(Hd[H].Path);
  If R <> NO_ERROR Then FillB(LongInt(@FD), 320, 0);
  { taille et date courantes du fichier ouvert }
  Size := KGetFileSize(Hd[H].KH, 0);
  If Size <> -1 Then FD[8] := Size;
  If KGetFileTime(Hd[H].KH, 0, 0, LongInt(@Ft)) <> 0 Then
  Begin
    FD[5] := Ft[0]; FD[6] := Ft[1];
  End;
  If Level = FIL_QUERYEASFROMLIST Then
  Begin
    If PeekL(PInfo + 4) <> 0 Then PokeL(PeekL(PInfo + 4), 4);
    DosQueryFileInfo := NO_ERROR;
    Exit;
  End;
  DosQueryFileInfo := PutFileStatus(PInfo, Cb, Level);
End;

{ DosQFileInfo (1.x) : FILESTATUS de 22 octets (attribut sur un mot) }
Function DosQFileInfo(H, Level, PInfo, Cb : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Cb < 22 Then
  Begin
    DosQFileInfo := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  R := DosQueryFileInfo(H, FIL_STANDARD, LongInt(@Scratch), 24);
  If R = NO_ERROR Then MoveB(LongInt(@Scratch), PInfo, 22);
  DosQFileInfo := R;
End;

{ Fixer les dates (FDATE/FTIME non nuls) et les attributs }
Function SetInfoFromStatus(Path : String; KH, PInfo : LongInt) : LongInt;
Var Ft : Array[0..1] Of LongInt; D, T : LongInt;
Begin
  D := PeekW(PInfo + 8); T := PeekW(PInfo + 10);
  If (D <> 0) And (KH <> -1) Then
  Begin
    KDosDateTimeToFileTime(D, T, LongInt(@Ft));
    KSetFileTime(KH, 0, 0, LongInt(@Ft));
  End;
  If KSetFileAttributesA(Z(Path, 0), PeekL(PInfo + 20) And $27) = 0 Then
    SetInfoFromStatus := KErr
  Else
    SetInfoFromStatus := NO_ERROR;
End;

Function DosSetFileInfo(H, Level, PInfo, Cb : LongInt) : LongInt;
Begin
  If Not HValid(H) Or (HKind(H) <> HK_FILE) Then
  Begin
    DosSetFileInfo := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If Level = FIL_QUERYEASIZE Then
  Begin
    DosSetFileInfo := NO_ERROR;          { EAOP2 : aucun attribut etendu }
    Exit;
  End;
  If Level <> FIL_STANDARD Then
  Begin
    DosSetFileInfo := ERROR_INVALID_LEVEL;
    Exit;
  End;
  If Cb < 24 Then
  Begin
    DosSetFileInfo := ERROR_INSUFFICIENT_BUFFER;
    Exit;
  End;
  DosSetFileInfo := SetInfoFromStatus(Hd[H].Path, Hd[H].KH, PInfo);
End;

Function DosSetPathInfo(PName, Level, PInfo, Cb, Flags : LongInt) : LongInt;
Begin
  If Level = FIL_QUERYEASIZE Then
  Begin
    DosSetPathInfo := NO_ERROR;
    Exit;
  End;
  If Level <> FIL_STANDARD Then
  Begin
    DosSetPathInfo := ERROR_INVALID_LEVEL;
    Exit;
  End;
  If KGetFileAttributesA(PName) = -1 Then
  Begin
    DosSetPathInfo := ERROR_FILE_NOT_FOUND;
    Exit;
  End;
  DosSetPathInfo := SetInfoFromStatus(GetStr(PName), -1, PInfo);
End;

Function DosQFileMode(PName, PAttr, Res : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := KGetFileAttributesA(PName);
  If A = -1 Then
  Begin
    DosQFileMode := KErr;
    Exit;
  End;
  PokeL(PAttr, A And $37);
  DosQFileMode := NO_ERROR;
End;

Function DosSetFileMode(PName, Attr, Res : LongInt) : LongInt;
Begin
  If KSetFileAttributesA(PName, Attr And $27) = 0 Then DosSetFileMode := KErr
  Else DosSetFileMode := NO_ERROR;
End;

{ Attributs etendus : le CD-ROM et le disque virtuel n'en ont aucun }
Function DosEnumAttribute(RefType, PvFile, Entry, PvBuf, CbBuf, PCount, Level : LongInt) : LongInt;
Begin
  If Level <> 1 Then
  Begin
    DosEnumAttribute := ERROR_INVALID_LEVEL;
    Exit;
  End;
  If (RefType = 0) And Not HValid(PeekL(PvFile)) Then
  Begin
    DosEnumAttribute := ERROR_INVALID_HANDLE;
    Exit;
  End;
  PokeL(PCount, 0);
  DosEnumAttribute := NO_ERROR;
End;

{ Edition d'un nom avec des caracteres globaux (comme REN *.TXT *.BAK) }
Function DosEditName(Level, PSrc, PEdit, PTarget, CbTarget : LongInt) : LongInt;
Var Src, Ed, R : String; I, J : LongInt;
Begin
  If Level <> 1 Then
  Begin
    DosEditName := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Src := GetStr(PSrc);
  Ed := GetStr(PEdit);
  R := '';
  I := 1; J := 1;
  While J <= Length(Ed) Do
  Begin
    If Ed[J] = '?' Then
    Begin
      If (I <= Length(Src)) And (Src[I] <> '.') Then
      Begin
        R := R + Src[I]; Inc(I);
      End;
    End
    Else If Ed[J] = '*' Then
    Begin
      { copier la source jusqu'au prochain caractere de l'edition }
      If J < Length(Ed) Then
        While (I <= Length(Src)) And (Src[I] <> Ed[J + 1]) Do
        Begin
          R := R + Src[I]; Inc(I);
        End
      Else
        While I <= Length(Src) Do
        Begin
          R := R + Src[I]; Inc(I);
        End;
    End
    Else If Ed[J] = '.' Then
    Begin
      While (I <= Length(Src)) And (Src[I] <> '.') Do Inc(I);
      If I <= Length(Src) Then Inc(I);
      R := R + '.';
    End
    Else
    Begin
      R := R + Ed[J];
      If (I <= Length(Src)) And (Src[I] <> '.') Then Inc(I);
    End;
    Inc(J);
  End;
  While (Length(R) > 0) And (R[Length(R)] = '.') Do Delete(R, Length(R), 1);
  If Length(R) + 1 > CbTarget Then
  Begin
    DosEditName := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  PutStr(PTarget, R, CbTarget);
  DosEditName := NO_ERROR;
End;

{ DosScanEnv : adresse de la valeur dans l'environnement }
Function DosScanEnv(PName, PPValue : LongInt) : LongInt;
Var Env, P, L : LongInt; Nm, S : String;
Begin
  Nm := UpStr(GetStr(PName)) + '=';
  Env := KGetEnvironmentStringsA;
  P := Env;
  While PeekB(P) <> 0 Do
  Begin
    L := StrLenA(P);
    S := GetStr(P);
    If UpStr(Copy(S, 1, Length(Nm))) = Nm Then
    Begin
      PokeL(PPValue, P + Length(Nm));
      DosScanEnv := NO_ERROR;
      Exit;
    End;
    P := P + L + 1;
  End;
  DosScanEnv := ERROR_ENVVAR_NOT_FOUND;
End;

{ DosSearchPath(controle, chemins ou variable, fichier, tampon, taille) :
  SEARCH_CUR_DIRECTORY (2) chercher d'abord dans le repertoire courant,
  SEARCH_ENVIRONMENT (2 dans PathOrName = nom de variable) selon le bit 1 }
Function DosSearchPath(Control, PPath, PFile, PBuf, CbBuf : LongInt) : LongInt;
Var Dirs, D, Fn, Path : String; P, V : LongInt;
Begin
  Fn := GetStr(PFile);
  Dirs := '';
  If (Control And 2) <> 0 Then
  Begin
    If DosScanEnv(PPath, LongInt(@V)) = NO_ERROR Then Dirs := GetStr(V);
  End
  Else
    Dirs := GetStr(PPath);
  If (Control And 1) <> 0 Then Dirs := '.;' + Dirs;
  While Dirs <> '' Do
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
      If (D[Length(D)] <> '\') And (D[Length(D)] <> ':') Then D := D + '\';
      Path := D + Fn;
      If KGetFileAttributesA(Z(Path, 0)) <> -1 Then
      Begin
        If KGetFullPathNameA(Z(Path, 0), CbBuf, PBuf, 0) >= CbBuf Then
          DosSearchPath := ERROR_BUFFER_OVERFLOW
        Else
          DosSearchPath := NO_ERROR;
        Exit;
      End;
    End;
  End;
  DosSearchPath := ERROR_FILE_NOT_FOUND;
End;

{ Informations sur le systeme de fichiers }
Function DosQueryFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt;
Var Spc, Bps, Free, Total, Serial : LongInt; Lbl, Root : String;
Begin
  If Not DriveExists(Disk) Then
  Begin
    DosQueryFSInfo := ERROR_INVALID_DRIVE;
    Exit;
  End;
  Root := DriveRoot(Disk);
  If Level = 1 Then
  Begin
    If Cb < 18 Then
    Begin
      DosQueryFSInfo := ERROR_BUFFER_OVERFLOW;
      Exit;
    End;
    KGetDiskFreeSpaceA(Z(Root, 0), LongInt(@Spc), LongInt(@Bps), LongInt(@Free), LongInt(@Total));
    PokeL(PBuf, 0);
    PokeL(PBuf + 4, Spc);
    PokeL(PBuf + 8, Total);
    PokeL(PBuf + 12, Free);
    PokeW(PBuf + 16, Bps);
    DosQueryFSInfo := NO_ERROR;
  End
  Else If Level = 2 Then
  Begin
    If Cb < 17 Then
    Begin
      DosQueryFSInfo := ERROR_BUFFER_OVERFLOW;
      Exit;
    End;
    Serial := 0;
    KGetVolumeInformationA(Z(Root, 0), LongInt(@Scratch2), 64, LongInt(@Serial), 0, 0, 0, 0);
    Lbl := Copy(GetStr(LongInt(@Scratch2)), 1, 11);
    { FSINFO : date et heure de creation (numero de serie), etiquette }
    PokeW(PBuf, Serial And $FFFF);
    PokeW(PBuf + 2, (Serial Shr 16) And $FFFF);
    PokeB(PBuf + 4, Length(Lbl));
    PutStr(PBuf + 5, Lbl, 12);
    DosQueryFSInfo := NO_ERROR;
  End
  Else
    DosQueryFSInfo := ERROR_INVALID_LEVEL;
End;

Function DosQFSInfo(Drive, Level, PBuf, Cb : LongInt) : LongInt;
Begin
  DosQFSInfo := DosQueryFSInfo(Drive, Level, PBuf, Cb);
End;

{ Nom du systeme de fichiers de l'unite (CDFS, HPFS...) }
Function FsNameOf(Disk : LongInt) : String;
Begin
  PutStr(LongInt(@Scratch2), '', 2);
  KGetVolumeInformationA(Z(DriveRoot(Disk), 0), 0, 0, 0, 0, 0, LongInt(@Scratch2), 32);
  FsNameOf := GetStr(LongInt(@Scratch2));
End;

Function CallPtr5(F, A1, A2, A3, A4, A5 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
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
    add esp,20
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPtr5 := R;
End;

{ Nom de volume : le CD-ROM est en lecture seule ; sur un volume IFS, le
  pilote (FS_FSINFO de NOM.IFS) change le nom }
Function DosSetFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt;
Var D, M, F : LongInt;
Begin
  D := Disk;
  If D = 0 Then D := CurDrive;
  If Not DriveExists(D) Then DosSetFSInfo := ERROR_INVALID_DRIVE
  Else If Level <> 2 Then DosSetFSInfo := ERROR_INVALID_LEVEL
  Else If D = 3 Then DosSetFSInfo := ERROR_WRITE_PROTECT    { CD-ROM }
  Else
  Begin
    M := KGetModuleHandleA(Z(FsNameOf(D) + '.IFS', 0));
    F := 0;
    If M <> 0 Then F := KGetProcAddress(M, Z('FS_FSINFO', 1));
    If F = 0 Then DosSetFSInfo := ERROR_NOT_SUPPORTED
    Else DosSetFSInfo := CallPtr5(F, 1, D - 1, PBuf, Cb, 2);
  End;
End;

{ FSQBUFFER2 : iType, cbName, cbFSDName, cbFSAData, szName, szFSDName }
Function DosQueryFSAttach(PDev, Ordinal, Level, PBuf, PCb : LongInt) : LongInt;
Var Nm, Fs : String; D, N, I : LongInt;
Begin
  If (Level <> 1) And (Level <> 2) And (Level <> 3) Then
  Begin
    DosQueryFSAttach := ERROR_INVALID_LEVEL;
    Exit;
  End;
  If PDev <> 0 Then Nm := UpStr(GetStr(PDev)) Else Nm := '';
  If Level = 2 Then
  Begin
    { enumeration : ordinal n = n-ieme unite existante }
    D := 0;
    N := 0;
    For I := 3 To 26 Do
      If (D = 0) And DriveExists(I) Then
      Begin
        Inc(N);
        If N = Ordinal Then D := I;
      End;
    If D = 0 Then
    Begin
      DosQueryFSAttach := ERROR_NO_MORE_ITEMS;
      Exit;
    End;
  End
  Else
  Begin
    D := 0;
    If (Length(Nm) = 2) And (Nm[2] = ':') Then D := Ord(Nm[1]) - 64;
    If (D < 1) Or Not DriveExists(D) Then
    Begin
      DosQueryFSAttach := ERROR_INVALID_DRIVE;
      Exit;
    End;
  End;
  Fs := FsNameOf(D);
  If PeekL(PCb) < 8 + 3 + Length(Fs) + 1 + 1 Then
  Begin
    PokeL(PCb, 8 + 3 + Length(Fs) + 1 + 1);
    DosQueryFSAttach := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  PokeW(PBuf, 3);                { FSAT_LOCALDRV }
  PokeW(PBuf + 2, 2);
  PokeW(PBuf + 4, Length(Fs));
  PokeW(PBuf + 6, 0);
  PutStr(PBuf + 8, Chr(64 + D) + ':', 3);
  PutStr(PBuf + 11, Fs, Length(Fs) + 1);
  PokeB(PBuf + 12 + Length(Fs), 0);
  PokeL(PCb, 13 + Length(Fs));
  DosQueryFSAttach := NO_ERROR;
End;

Function DosQFSAttach(PDev, Ordinal, Level, PBuf, PCb, Res : LongInt) : LongInt;
Begin
  DosQFSAttach := DosQueryFSAttach(PDev, Ordinal, Level, PBuf, PCb);
End;

{ Attacher un systeme de fichiers : aucun FSD installable (ERROR_INVALID_FSD_NAME 252) }
Function DosFSAttach(PDev, PFsd, PData, CbData, Flag : LongInt) : LongInt;
Begin
  If GetStr(PFsd) = '' Then DosFSAttach := ERROR_INVALID_PARAMETER
  Else DosFSAttach := 252;
End;

{ DosFSCtl : interface etendue avec le FSD ; fonction 1 (FSCTL_ERROR_INFO)
  rend un message vide, fonction 2 (FSCTL_MAX_EASIZE) les tailles maximales
  des attributs etendus (aucun) }
Function DosFSCtl(PData, CbData, PcbData, PParm, CbParm, PcbParm, Func, PRoute, H, Method : LongInt) : LongInt;
Begin
  Case Func Of
    1 : Begin
          If CbData > 0 Then PokeB(PData, 0);
          PokeL(PcbData, 0);
          DosFSCtl := NO_ERROR;
        End;
    2 : Begin
          If CbData >= 4 Then
          Begin
            PokeW(PData, 0);
            PokeW(PData + 2, 0);
            PokeL(PcbData, 4);
            DosFSCtl := NO_ERROR;
          End
          Else DosFSCtl := ERROR_BUFFER_OVERFLOW;
        End;
  Else
    DosFSCtl := ERROR_INVALID_FUNCTION;
  End;
End;

{ ==================================================================== }
{ Partie 7 - Tuyaux anonymes et nommes                                 }
{ ==================================================================== }
{ Un tuyau est un ou deux tampons circulaires en memoire partagee. Un
  tuyau anonyme n'utilise que le tampon A (ecriture -> lecture). Un tuyau
  nomme a deux tampons : A (serveur -> client) et B (client -> serveur).
  Comme un seul processus leger s'execute, une lecture d'un tuyau vide ne
  bloque pas : elle rend 0 octet (fin de fichier si l'autre bout est ferme). }

Const
  MaxPipes = 16;
  NP_STATE_DISCONNECTED = 1;
  NP_STATE_LISTENING    = 2;
  NP_STATE_CONNECTED    = 3;
  NP_STATE_CLOSING      = 4;

Type
  TRing = Record
    Buf, Size, Count, RPos, WPos : LongInt;
  End;
  TPipe = Record
    Used      : Boolean;
    Named     : Boolean;
    Name      : String[63];
    A, B      : TRing;
    ReadOpen  : Boolean;      { anonyme : bout de lecture ; nomme : serveur }
    WriteOpen : Boolean;      { anonyme : bout d'ecriture ; nomme : client }
    State     : LongInt;
    OpenMode  : LongInt;
    PipeMode  : LongInt;
    Sem       : LongInt;      { semaphore attachee (DosSetNPipeSem) }
    Key       : LongInt;
  End;

Var
  Pipes : Array[0..MaxPipes - 1] Of TPipe;

Function RingInit(Var R : TRing; Size : LongInt) : Boolean;
Begin
  If Size < 512 Then Size := 512;
  R.Buf := SharedAlloc(Size);
  R.Size := Size; R.Count := 0; R.RPos := 0; R.WPos := 0;
  RingInit := R.Buf <> 0;
End;

Procedure RingFree(Var R : TRing);
Begin
  If R.Buf <> 0 Then KHeapFree(2, 0, R.Buf);
  R.Buf := 0; R.Size := 0; R.Count := 0;
End;

Function RingWrite(Var R : TRing; Src, N : LongInt) : LongInt;
Var Done : LongInt;
Begin
  Done := 0;
  While (Done < N) And (R.Count < R.Size) Do
  Begin
    PokeB(R.Buf + R.WPos, PeekB(Src + Done));
    R.WPos := (R.WPos + 1) Mod R.Size;
    Inc(R.Count);
    Inc(Done);
  End;
  RingWrite := Done;
End;

Function RingRead(Var R : TRing; Dst, N : LongInt; Peek : Boolean) : LongInt;
Var Done, P : LongInt;
Begin
  Done := 0;
  P := R.RPos;
  While (Done < N) And (Done < R.Count) Do
  Begin
    PokeB(Dst + Done, PeekB(R.Buf + P));
    P := (P + 1) Mod R.Size;
    Inc(Done);
  End;
  If Not Peek Then
  Begin
    R.RPos := P;
    R.Count := R.Count - Done;
  End;
  RingRead := Done;
End;

Function NewPipe : LongInt;
Var I : LongInt;
Begin
  NewPipe := -1;
  For I := 0 To MaxPipes - 1 Do
    If Not Pipes[I].Used Then
    Begin
      Pipes[I].Used := True;
      Pipes[I].Named := False;
      Pipes[I].Name := '';
      Pipes[I].A.Buf := 0; Pipes[I].B.Buf := 0;
      Pipes[I].ReadOpen := True;
      Pipes[I].WriteOpen := True;
      Pipes[I].State := 0;
      Pipes[I].Sem := 0;
      Pipes[I].Key := 0;
      NewPipe := I;
      Exit;
    End;
End;

Procedure FreePipe(P : LongInt);
Begin
  RingFree(Pipes[P].A);
  RingFree(Pipes[P].B);
  Pipes[P].Used := False;
End;

Function MakePipe(PRead, PWrite, Size : LongInt) : LongInt;
Var P, HR, HW : LongInt;
Begin
  P := NewPipe;
  If P < 0 Then
  Begin
    MakePipe := ERROR_TOO_MANY_OPEN_FILES;
    Exit;
  End;
  If Size <= 0 Then Size := 4096;
  If Not RingInit(Pipes[P].A, Size) Then
  Begin
    Pipes[P].Used := False;
    MakePipe := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  HR := HAlloc;
  HW := HAlloc;
  If (HR < 0) Or (HW < 0) Then
  Begin
    If HR >= 0 Then Hd[HR].Kind := HK_FREE;
    If HW >= 0 Then Hd[HW].Kind := HK_FREE;
    FreePipe(P);
    MakePipe := ERROR_TOO_MANY_OPEN_FILES;
    Exit;
  End;
  Hd[HR].Kind := HK_PIPER; Hd[HR].Pipe := P; Hd[HR].Mode := OPEN_ACCESS_READONLY;
  Hd[HW].Kind := HK_PIPEW; Hd[HW].Pipe := P; Hd[HW].Mode := OPEN_ACCESS_WRITEONLY;
  PokeL(PRead, HR);
  PokeL(PWrite, HW);
  MakePipe := NO_ERROR;
End;

Function DosCreatePipe(PRead, PWrite, Size : LongInt) : LongInt;
Begin
  DosCreatePipe := MakePipe(PRead, PWrite, Size);
End;

Function DosMakePipe(PRead, PWrite, Size : LongInt) : LongInt;
Begin
  DosMakePipe := MakePipe(PRead, PWrite, Size);
End;

{ Lecture : rend le nombre d'octets lus, ou -code d'erreur }
Function PipeRead(H, Buf, N : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := Hd[H].Pipe;
  If (P < 0) Or Not Pipes[P].Used Then
  Begin
    PipeRead := -ERROR_BROKEN_PIPE;
    Exit;
  End;
  If Hd[H].Kind = HK_PIPER Then
    PipeRead := RingRead(Pipes[P].A, Buf, N, False)
  Else If Hd[H].Kind = HK_NPCLI Then
    PipeRead := RingRead(Pipes[P].A, Buf, N, False)
  Else
  Begin
    { serveur }
    If Pipes[P].State <> NP_STATE_CONNECTED Then
    Begin
      If Pipes[P].State = NP_STATE_CLOSING Then PipeRead := 0
      Else PipeRead := -ERROR_PIPE_NOT_CONNECTED;
      Exit;
    End;
    PipeRead := RingRead(Pipes[P].B, Buf, N, False);
  End;
End;

Function PipeWrite(H, Buf, N : LongInt; Var Written : LongInt) : LongInt;
Var P : LongInt;
Begin
  Written := 0;
  P := Hd[H].Pipe;
  If (P < 0) Or Not Pipes[P].Used Then
  Begin
    PipeWrite := ERROR_BROKEN_PIPE;
    Exit;
  End;
  If Hd[H].Kind = HK_PIPEW Then
  Begin
    If Not Pipes[P].ReadOpen Then
    Begin
      PipeWrite := ERROR_BROKEN_PIPE;
      Exit;
    End;
    Written := RingWrite(Pipes[P].A, Buf, N);
  End
  Else If Hd[H].Kind = HK_NPCLI Then
  Begin
    If Not Pipes[P].ReadOpen Then
    Begin
      PipeWrite := ERROR_BROKEN_PIPE;
      Exit;
    End;
    Written := RingWrite(Pipes[P].B, Buf, N);
  End
  Else
  Begin
    If Pipes[P].State <> NP_STATE_CONNECTED Then
    Begin
      PipeWrite := ERROR_PIPE_NOT_CONNECTED;
      Exit;
    End;
    Written := RingWrite(Pipes[P].A, Buf, N);
  End;
  PipeWrite := NO_ERROR;
End;

Procedure PipeCloseEnd(H : LongInt);
Var P : LongInt;
Begin
  P := Hd[H].Pipe;
  If (P < 0) Or Not Pipes[P].Used Then Exit;
  Case Hd[H].Kind Of
    HK_PIPER, HK_NPSRV : Pipes[P].ReadOpen := False;
    HK_PIPEW, HK_NPCLI : Pipes[P].WriteOpen := False;
  End;
  If Hd[H].Kind = HK_NPCLI Then
  Begin
    If Pipes[P].State = NP_STATE_CONNECTED Then Pipes[P].State := NP_STATE_CLOSING;
  End;
  If Not Pipes[P].ReadOpen And Not Pipes[P].WriteOpen Then FreePipe(P);
End;

{ --- Tuyaux nommes (\PIPE\nom) --- }

Function FindNamedPipe(Name : String; Free : Boolean) : LongInt;
Var I : LongInt;
Begin
  FindNamedPipe := -1;
  Name := UpStr(Name);
  For I := 0 To MaxPipes - 1 Do
    If Pipes[I].Used And Pipes[I].Named And (Pipes[I].Name = Name) Then
      If (Not Free) Or (Pipes[I].State = NP_STATE_LISTENING) Or
         ((Pipes[I].State = NP_STATE_DISCONNECTED) And Not Pipes[I].WriteOpen) Then
      Begin
        FindNamedPipe := I;
        Exit;
      End;
End;

Function DosCreateNPipe(PName, PHPipe, OpenMode, PipeMode, CbOut, CbIn, Msec : LongInt) : LongInt;
Var P, H : LongInt; Name : String;
Begin
  Name := UpStr(GetStr(PName));
  If Copy(Name, 1, 6) <> '\PIPE\' Then
  Begin
    DosCreateNPipe := ERROR_INVALID_NAME;
    Exit;
  End;
  P := NewPipe;
  If P < 0 Then
  Begin
    DosCreateNPipe := ERROR_PIPE_BUSY;
    Exit;
  End;
  If (Not RingInit(Pipes[P].A, CbOut)) Or (Not RingInit(Pipes[P].B, CbIn)) Then
  Begin
    FreePipe(P);
    DosCreateNPipe := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  H := HAlloc;
  If H < 0 Then
  Begin
    FreePipe(P);
    DosCreateNPipe := ERROR_TOO_MANY_OPEN_FILES;
    Exit;
  End;
  Pipes[P].Named := True;
  Pipes[P].Name := Name;
  Pipes[P].OpenMode := OpenMode;
  Pipes[P].PipeMode := PipeMode;
  Pipes[P].WriteOpen := False;          { aucun client }
  Pipes[P].State := NP_STATE_DISCONNECTED;
  Hd[H].Kind := HK_NPSRV; Hd[H].Pipe := P; Hd[H].Mode := OpenMode; Hd[H].Path := Name;
  PokeL(PHPipe, H);
  DosCreateNPipe := NO_ERROR;
End;

Function DosMakeNmPipe(PName, PHPipe, OpenMode, PipeMode, CbOut, CbIn, Timeout : LongInt) : LongInt;
Begin
  DosMakeNmPipe := DosCreateNPipe(PName, PHPipe, OpenMode, PipeMode, CbOut, CbIn, Timeout);
End;

{ Ouverture d'un tuyau nomme par un client (DosOpen("\PIPE\nom")) }
Function NpClientOpen(Name : String; Var H : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := FindNamedPipe(Name, False);
  If P < 0 Then
  Begin
    NpClientOpen := ERROR_FILE_NOT_FOUND;
    Exit;
  End;
  P := FindNamedPipe(Name, True);
  If P < 0 Then
  Begin
    NpClientOpen := ERROR_PIPE_BUSY;
    Exit;
  End;
  H := HAlloc;
  If H < 0 Then
  Begin
    NpClientOpen := ERROR_TOO_MANY_OPEN_FILES;
    Exit;
  End;
  Hd[H].Kind := HK_NPCLI; Hd[H].Pipe := P; Hd[H].Mode := OPEN_ACCESS_READWRITE;
  Hd[H].Path := Pipes[P].Name;
  Pipes[P].WriteOpen := True;
  Pipes[P].State := NP_STATE_CONNECTED;
  NpClientOpen := NO_ERROR;
End;

Function NpServer(H : LongInt) : LongInt;
Begin
  If HValid(H) And (HKind(H) = HK_NPSRV) Then NpServer := Hd[H].Pipe Else NpServer := -1;
End;

Function NpAny(H : LongInt) : LongInt;
Begin
  If HValid(H) And ((HKind(H) = HK_NPSRV) Or (HKind(H) = HK_NPCLI)) Then NpAny := Hd[H].Pipe
  Else NpAny := -1;
End;

{ Le serveur se met a l'ecoute : sans client, mode non bloquant ou
  bloquant, ERROR_PIPE_NOT_CONNECTED (un seul processus leger) }
Function DosConnectNPipe(H : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := NpServer(H);
  If P < 0 Then
  Begin
    DosConnectNPipe := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If Pipes[P].State = NP_STATE_CONNECTED Then
  Begin
    DosConnectNPipe := NO_ERROR;
    Exit;
  End;
  If Pipes[P].State = NP_STATE_CLOSING Then
  Begin
    DosConnectNPipe := ERROR_BROKEN_PIPE;
    Exit;
  End;
  Pipes[P].State := NP_STATE_LISTENING;
  DosConnectNPipe := ERROR_PIPE_NOT_CONNECTED;
End;

Function DosConnectNmPipe(H : LongInt) : LongInt;
Begin
  DosConnectNmPipe := DosConnectNPipe(H);
End;

Function DosDisConnectNPipe(H : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := NpServer(H);
  If P < 0 Then
  Begin
    DosDisConnectNPipe := ERROR_INVALID_HANDLE;
    Exit;
  End;
  Pipes[P].State := NP_STATE_DISCONNECTED;
  Pipes[P].WriteOpen := False;
  Pipes[P].A.Count := 0; Pipes[P].A.RPos := 0; Pipes[P].A.WPos := 0;
  Pipes[P].B.Count := 0; Pipes[P].B.RPos := 0; Pipes[P].B.WPos := 0;
  DosDisConnectNPipe := NO_ERROR;
End;

Function DosDisconnectNmPipe(H : LongInt) : LongInt;
Begin
  DosDisconnectNmPipe := DosDisConnectNPipe(H);
End;

{ Lire sans retirer : AVAILDATA = cbpipe (mot), cbmessage (mot) }
Function DosPeekNPipe(H, PBuf, CbBuf, PcbActual, PAvail, PState : LongInt) : LongInt;
Var P, N : LongInt;
Begin
  P := NpAny(H);
  If P < 0 Then
  Begin
    DosPeekNPipe := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If HKind(H) = HK_NPSRV Then
  Begin
    N := RingRead(Pipes[P].B, PBuf, CbBuf, True);
    PokeW(PAvail, Pipes[P].B.Count);
  End
  Else
  Begin
    N := RingRead(Pipes[P].A, PBuf, CbBuf, True);
    PokeW(PAvail, Pipes[P].A.Count);
  End;
  PokeW(PAvail + 2, 0);
  PokeL(PcbActual, N);
  PokeL(PState, Pipes[P].State);
  DosPeekNPipe := NO_ERROR;
End;

Function DosPeekNmPipe(H, PBuf, CbBuf, PcbActual, PAvail, PState : LongInt) : LongInt;
Begin
  DosPeekNmPipe := DosPeekNPipe(H, PBuf, CbBuf, PcbActual, PAvail, PState);
End;

{ Etat du handle : NP_NBLK ($8000), NP_SERVER ($4000), type et mode de
  lecture, nombre d'instances (octet bas : 1) }
Function DosQueryNPHState(H, PState : LongInt) : LongInt;
Var P, S : LongInt;
Begin
  P := NpAny(H);
  If P < 0 Then
  Begin
    DosQueryNPHState := ERROR_INVALID_HANDLE;
    Exit;
  End;
  S := (Pipes[P].PipeMode And $8F00) Or 1;
  If HKind(H) = HK_NPSRV Then S := S Or $4000;
  PokeL(PState, S);
  DosQueryNPHState := NO_ERROR;
End;

Function DosQNmPHandState(H, PState : LongInt) : LongInt;
Begin
  DosQNmPHandState := DosQueryNPHState(H, PState);
End;

Function DosSetNPHState(H, State : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := NpAny(H);
  If P < 0 Then
  Begin
    DosSetNPHState := ERROR_INVALID_HANDLE;
    Exit;
  End;
  { seuls le mode bloquant et le mode de lecture (message/octet) changent }
  Pipes[P].PipeMode := (Pipes[P].PipeMode And Not $8100) Or (State And $8100);
  DosSetNPHState := NO_ERROR;
End;

Function DosSetNmPHandState(H, State : LongInt) : LongInt;
Begin
  DosSetNmPHandState := DosSetNPHState(H, State);
End;

{ PIPEINFO (niveau 1) : cbOut, cbIn (mots), cbMaxInst, cbCurInst, cbName
  (octets), szName }
Function DosQueryNPipeInfo(H, Level, PBuf, CbBuf : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := NpAny(H);
  If P < 0 Then
  Begin
    DosQueryNPipeInfo := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If Level <> 1 Then
  Begin
    DosQueryNPipeInfo := ERROR_INVALID_LEVEL;
    Exit;
  End;
  If CbBuf < 7 + Length(Pipes[P].Name) + 1 Then
  Begin
    DosQueryNPipeInfo := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  PokeW(PBuf, Pipes[P].A.Size);
  PokeW(PBuf + 2, Pipes[P].B.Size);
  PokeB(PBuf + 4, 1);
  PokeB(PBuf + 5, 1);
  PokeB(PBuf + 6, Length(Pipes[P].Name));
  PutStr(PBuf + 7, Pipes[P].Name, 64);
  DosQueryNPipeInfo := NO_ERROR;
End;

Function DosQNmPipeInfo(H, Level, PBuf, CbBuf : LongInt) : LongInt;
Begin
  DosQNmPipeInfo := DosQueryNPipeInfo(H, Level, PBuf, CbBuf);
End;

Function DosSetNPipeSem(H, HSem, Key : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := NpAny(H);
  If P < 0 Then
  Begin
    DosSetNPipeSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  Pipes[P].Sem := HSem;
  Pipes[P].Key := Key;
  DosSetNPipeSem := NO_ERROR;
End;

Function DosSetNmPipeSem(H, HSem, Key : LongInt) : LongInt;
Begin
  DosSetNmPipeSem := DosSetNPipeSem(H, HSem, Key);
End;

{ PIPESEMSTATE : fStatus (octet : 1 donnees, 2 place libre, 3 fermeture,
  0 fin), fFlag, usKey (mot), usAvail (mot) ; 6 octets par entree }
Function DosQueryNPipeSemState(HSem, PBuf, CbBuf : LongInt) : LongInt;
Var I, P : LongInt;
Begin
  P := PBuf;
  For I := 0 To MaxPipes - 1 Do
    If Pipes[I].Used And Pipes[I].Named And (Pipes[I].Sem = HSem) And (P + 12 <= PBuf + CbBuf) Then
    Begin
      If Pipes[I].B.Count > 0 Then PokeB(P, 1) Else If Pipes[I].State = NP_STATE_CLOSING Then PokeB(P, 3)
      Else PokeB(P, 2);
      PokeB(P + 1, 0);
      PokeW(P + 2, Pipes[I].Key);
      PokeW(P + 4, Pipes[I].B.Count);
      P := P + 6;
    End;
  If P + 6 > PBuf + CbBuf Then
  Begin
    DosQueryNPipeSemState := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  FillB(P, 6, 0);
  DosQueryNPipeSemState := NO_ERROR;
End;

Function DosQNmPipeSemState(HSem, PBuf, CbBuf : LongInt) : LongInt;
Begin
  DosQNmPipeSemState := DosQueryNPipeSemState(HSem, PBuf, CbBuf);
End;

{ Ecrire puis lire (transaction sur un tuyau de messages duplex) }
Function DosTransactNPipe(H, PIn, CbIn, POut, CbOut, PcbRead : LongInt) : LongInt;
Var R, W : LongInt;
Begin
  If NpAny(H) < 0 Then
  Begin
    DosTransactNPipe := ERROR_INVALID_HANDLE;
    Exit;
  End;
  R := DosWrite(H, PIn, CbIn, LongInt(@W));
  If R = NO_ERROR Then R := DosRead(H, POut, CbOut, PcbRead);
  DosTransactNPipe := R;
End;

Function DosTransactNmPipe(H, PIn, CbIn, POut, CbOut, PcbRead : LongInt) : LongInt;
Begin
  DosTransactNmPipe := DosTransactNPipe(H, PIn, CbIn, POut, CbOut, PcbRead);
End;

Function DosCallNPipe(PName, PIn, CbIn, POut, CbOut, PcbActual, Msec : LongInt) : LongInt;
Var H, R : LongInt;
Begin
  R := NpClientOpen(GetStr(PName), H);
  If R <> NO_ERROR Then
  Begin
    DosCallNPipe := R;
    Exit;
  End;
  R := DosTransactNPipe(H, PIn, CbIn, POut, CbOut, PcbActual);
  DosClose(H);
  DosCallNPipe := R;
End;

Function DosCallNmPipe(PName, PIn, CbIn, POut, CbOut, PcbActual, Timeout : LongInt) : LongInt;
Begin
  DosCallNmPipe := DosCallNPipe(PName, PIn, CbIn, POut, CbOut, PcbActual, Timeout);
End;

Function DosWaitNPipe(PName, Msec : LongInt) : LongInt;
Var Name : String;
Begin
  Name := GetStr(PName);
  If FindNamedPipe(Name, False) < 0 Then DosWaitNPipe := ERROR_FILE_NOT_FOUND
  Else If FindNamedPipe(Name, True) >= 0 Then DosWaitNPipe := NO_ERROR
  Else DosWaitNPipe := ERROR_SEM_TIMEOUT;
End;

Function DosWaitNmPipe(PName, Timeout : LongInt) : LongInt;
Begin
  DosWaitNmPipe := DosWaitNPipe(PName, Timeout);
End;

{ ==================================================================== }
{ Partie 8 - Memoire                                                   }
{ ==================================================================== }
{ Les objets memoire sont pris dans le tas du noyau (memoire privee :
  liberee a la fin du processus ; memoire partagee : tas 2, conservee).
  Toute la memoire est engagee des l'allocation : PAG_COMMIT/DECOMMIT ne
  font que changer les attributs memorises. }

Const
  MaxMem  = 128;
  MaxSegs = 64;
  MaxTls  = 32;

Type
  TMemObj = Record
    Used   : Boolean;
    Base   : LongInt;
    Size   : LongInt;
    Flags  : LongInt;
    Owner  : LongInt;
    Shared : Boolean;
    Name   : String[63];     { \SHAREMEM\... pour la memoire nommee }
  End;
  TSeg = Record
    Used   : Boolean;
    Base   : LongInt;
    Size   : LongInt;
    Owner  : LongInt;
    Huge   : LongInt;        { nombre de segments d'un objet huge }
    Shared : Boolean;
    Name   : String[63];
  End;

Var
  MemObjs : Array[0..MaxMem - 1] Of TMemObj;
  Segs    : Array[0..MaxSegs - 1] Of TSeg;
  TlsUsed : Array[0..MaxTls - 1] Of Boolean;
  TlsMem  : Array[0..MaxTls - 1] Of LongInt;

Function MemFind(A : LongInt) : LongInt;
Var I : LongInt;
Begin
  MemFind := -1;
  For I := 0 To MaxMem - 1 Do
    If MemObjs[I].Used And (A >= MemObjs[I].Base) And (A < MemObjs[I].Base + MemObjs[I].Size) Then
      If MemObjs[I].Shared Or (MemObjs[I].Owner = MyPid) Then
      Begin
        MemFind := I;
        Exit;
      End;
End;

Function MemNew(Size, Flags : LongInt; Shared : Boolean; Name : String) : LongInt;
Var I, A, Pid : LongInt;
Begin
  MemNew := -1;
  Pid := MyPid;
  For I := 0 To MaxMem - 1 Do
    If (Not MemObjs[I].Used) Or ((Not MemObjs[I].Shared) And (MemObjs[I].Owner <> Pid) And
       (KHeapSize(1, 0, MemObjs[I].Base) < 0)) Then
    Begin
      If Shared Then A := SharedAlloc(Size) Else A := KHeapAlloc(1, 8, Size);
      If A = 0 Then Exit;
      MemObjs[I].Used := True;
      MemObjs[I].Base := A;
      MemObjs[I].Size := Size;
      MemObjs[I].Flags := Flags;
      MemObjs[I].Owner := Pid;
      MemObjs[I].Shared := Shared;
      MemObjs[I].Name := UpStr(Name);
      MemNew := I;
      Exit;
    End;
End;

Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt;
Var M : LongInt;
Begin
  If (Cb <= 0) Or ((Flag And (PAG_READ Or PAG_WRITE Or PAG_EXECUTE)) = 0) Then
  Begin
    DosAllocMem := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  M := MemNew((Cb + 4095) And Not 4095, Flag, False, '');
  If M < 0 Then
  Begin
    DosAllocMem := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  PokeL(PPb, MemObjs[M].Base);
  DosAllocMem := NO_ERROR;
End;

Function DosAllocSharedMem(PPb, PName, Cb, Flag : LongInt) : LongInt;
Var M, I : LongInt; Name : String;
Begin
  Name := '';
  If PName <> 0 Then
  Begin
    Name := UpStr(GetStr(PName));
    If Copy(Name, 1, 10) <> '\SHAREMEM\' Then
    Begin
      DosAllocSharedMem := ERROR_INVALID_NAME;
      Exit;
    End;
    For I := 0 To MaxMem - 1 Do
      If MemObjs[I].Used And MemObjs[I].Shared And (MemObjs[I].Name = Name) Then
      Begin
        DosAllocSharedMem := ERROR_ALREADY_EXISTS;
        Exit;
      End;
  End;
  If Cb <= 0 Then
  Begin
    DosAllocSharedMem := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  M := MemNew((Cb + 4095) And Not 4095, Flag Or PAG_SHARED, True, Name);
  If M < 0 Then
  Begin
    DosAllocSharedMem := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  PokeL(PPb, MemObjs[M].Base);
  DosAllocSharedMem := NO_ERROR;
End;

Function DosGetNamedSharedMem(PPb, PName, Flag : LongInt) : LongInt;
Var I : LongInt; Name : String;
Begin
  Name := UpStr(GetStr(PName));
  For I := 0 To MaxMem - 1 Do
    If MemObjs[I].Used And MemObjs[I].Shared And (MemObjs[I].Name = Name) Then
    Begin
      PokeL(PPb, MemObjs[I].Base);
      DosGetNamedSharedMem := NO_ERROR;
      Exit;
    End;
  DosGetNamedSharedMem := ERROR_FILE_NOT_FOUND;
End;

Function DosGetSharedMem(Pb, Flag : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := MemFind(Pb);
  If (M < 0) Or Not MemObjs[M].Shared Then DosGetSharedMem := ERROR_INVALID_ADDRESS
  Else DosGetSharedMem := NO_ERROR;
End;

Function DosGiveSharedMem(Pb, Pid, Flag : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := MemFind(Pb);
  If (M < 0) Or Not MemObjs[M].Shared Then DosGiveSharedMem := ERROR_INVALID_ADDRESS
  Else DosGiveSharedMem := NO_ERROR;
End;

Function DosFreeMem(Pb : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := MemFind(Pb);
  If (M < 0) Or (MemObjs[M].Base <> Pb) Then
  Begin
    DosFreeMem := ERROR_INVALID_ADDRESS;
    Exit;
  End;
  If MemObjs[M].Shared Then KHeapFree(2, 0, Pb) Else KHeapFree(1, 0, Pb);
  MemObjs[M].Used := False;
  DosFreeMem := NO_ERROR;
End;

Function DosSetMem(Pb, Cb, Flag : LongInt) : LongInt;
Var M : LongInt;
Begin
  M := MemFind(Pb);
  If (M < 0) Or (Pb + Cb > MemObjs[M].Base + MemObjs[M].Size) Then
  Begin
    DosSetMem := ERROR_INVALID_ADDRESS;
    Exit;
  End;
  If ((Flag And PAG_COMMIT) <> 0) And ((Flag And PAG_DECOMMIT) <> 0) Then
  Begin
    DosSetMem := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If (Flag And PAG_DECOMMIT) <> 0 Then
    MemObjs[M].Flags := MemObjs[M].Flags And Not PAG_COMMIT
  Else
    MemObjs[M].Flags := (MemObjs[M].Flags And Not 7) Or (Flag And $1F);
  DosSetMem := NO_ERROR;
End;

Function DosQueryMem(Pb, PCb, PFlag : LongInt) : LongInt;
Var M, F, Rest : LongInt;
Begin
  M := MemFind(Pb);
  If M < 0 Then
  Begin
    PokeL(PFlag, PAG_FREE);
    DosQueryMem := ERROR_INVALID_ADDRESS;
    Exit;
  End;
  Rest := MemObjs[M].Base + MemObjs[M].Size - Pb;
  If PeekL(PCb) < Rest Then Rest := PeekL(PCb);
  PokeL(PCb, Rest);
  F := (MemObjs[M].Flags And $17) Or PAG_COMMIT;
  If MemObjs[M].Shared Then F := F Or PAG_SHARED;
  If Pb = MemObjs[M].Base Then F := F Or PAG_BASE;
  PokeL(PFlag, F);
  DosQueryMem := NO_ERROR;
End;

{ Etat des pages : un mot double par page (engagee, residente) }
Function DosQueryMemState(Pb, Cb, PFlag : LongInt) : LongInt;
Begin
  If MemFind(Pb) < 0 Then PokeL(PFlag, 0) Else PokeL(PFlag, $3);
  DosQueryMemState := NO_ERROR;
End;

{ Alias : la memoire est projetee a plat, l'alias est la meme adresse }
Function DosAliasMem(Pb, Cb, PPbAlias, Flag : LongInt) : LongInt;
Begin
  If MemFind(Pb) < 0 Then
  Begin
    DosAliasMem := ERROR_INVALID_ADDRESS;
    Exit;
  End;
  PokeL(PPbAlias, Pb);
  DosAliasMem := NO_ERROR;
End;

{ Memoire locale aux processus legers : mots doubles d'une table unique }
Function DosAllocThreadLocalMemory(CbDWords, PPb : LongInt) : LongInt;
Var I, J, Free : LongInt;
Begin
  If (CbDWords <= 0) Or (CbDWords > 8) Then
  Begin
    DosAllocThreadLocalMemory := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  For I := 0 To MaxTls - CbDWords Do
  Begin
    Free := 0;
    For J := I To I + CbDWords - 1 Do
      If Not TlsUsed[J] Then Inc(Free);
    If Free = CbDWords Then
    Begin
      For J := I To I + CbDWords - 1 Do
      Begin
        TlsUsed[J] := True;
        TlsMem[J] := 0;
      End;
      PokeL(PPb, LongInt(@TlsMem) + I * 4);
      DosAllocThreadLocalMemory := NO_ERROR;
      Exit;
    End;
  End;
  DosAllocThreadLocalMemory := ERROR_NOT_ENOUGH_MEMORY;
End;

Function DosFreeThreadLocalMemory(Pb : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := (Pb - LongInt(@TlsMem)) Div 4;
  If (I < 0) Or (I >= MaxTls) Or Not TlsUsed[I] Then
  Begin
    DosFreeThreadLocalMemory := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  TlsUsed[I] := False;
  DosFreeThreadLocalMemory := NO_ERROR;
End;

{ --- Sous-allocation (DosSubSetMem / DosSubAllocMem) ---
  En-tete du pool (16 octets) : signature 'SUBA', taille, premier bloc
  libre (decalage), reserve. Bloc libre : taille, decalage du suivant. }

Const
  SubMagic = $41425553;

Function SubInit(Base, Size : LongInt) : LongInt;
Begin
  If Size < 64 Then
  Begin
    SubInit := ERROR_DOSSUB_BADSIZE;
    Exit;
  End;
  Size := Size And Not 7;
  PokeL(Base, SubMagic);
  PokeL(Base + 4, Size);
  PokeL(Base + 8, 16);
  PokeL(Base + 12, 0);
  PokeL(Base + 16, Size - 16);
  PokeL(Base + 20, 0);
  SubInit := NO_ERROR;
End;

Function SubAlloc(Base, Cb : LongInt; Var Ofs : LongInt) : LongInt;
Var Prev, Cur, Sz, Next : LongInt;
Begin
  If PeekL(Base) <> SubMagic Then
  Begin
    SubAlloc := ERROR_DOSSUB_BADSELECTOR;
    Exit;
  End;
  Cb := (Cb + 7) And Not 7;
  If Cb < 8 Then Cb := 8;
  Prev := 0;
  Cur := PeekL(Base + 8);
  While Cur <> 0 Do
  Begin
    Sz := PeekL(Base + Cur);
    Next := PeekL(Base + Cur + 4);
    If Sz >= Cb Then
    Begin
      If Sz - Cb >= 8 Then
      Begin
        { garder la fin du bloc libre }
        PokeL(Base + Cur + Cb, Sz - Cb);
        PokeL(Base + Cur + Cb + 4, Next);
        Next := Cur + Cb;
      End;
      If Prev = 0 Then PokeL(Base + 8, Next) Else PokeL(Base + Prev + 4, Next);
      Ofs := Cur;
      FillB(Base + Cur, Cb, 0);
      SubAlloc := NO_ERROR;
      Exit;
    End;
    Prev := Cur;
    Cur := Next;
  End;
  SubAlloc := ERROR_DOSSUB_NOMEM;
End;

Function SubFree(Base, Ofs, Cb : LongInt) : LongInt;
Var Prev, Cur : LongInt;
Begin
  If PeekL(Base) <> SubMagic Then
  Begin
    SubFree := ERROR_DOSSUB_BADSELECTOR;
    Exit;
  End;
  Cb := (Cb + 7) And Not 7;
  If Cb < 8 Then Cb := 8;
  If (Ofs < 16) Or (Ofs + Cb > PeekL(Base + 4)) Then
  Begin
    SubFree := ERROR_DOSSUB_OVERLAP;
    Exit;
  End;
  { insertion triee puis fusion avec les voisins }
  Prev := 0;
  Cur := PeekL(Base + 8);
  While (Cur <> 0) And (Cur < Ofs) Do
  Begin
    Prev := Cur;
    Cur := PeekL(Base + Cur + 4);
  End;
  If (Cur <> 0) And (Ofs + Cb > Cur) Then
  Begin
    SubFree := ERROR_DOSSUB_OVERLAP;
    Exit;
  End;
  PokeL(Base + Ofs, Cb);
  PokeL(Base + Ofs + 4, Cur);
  If (Cur <> 0) And (Ofs + Cb = Cur) Then
  Begin
    PokeL(Base + Ofs, Cb + PeekL(Base + Cur));
    PokeL(Base + Ofs + 4, PeekL(Base + Cur + 4));
  End;
  If Prev = 0 Then PokeL(Base + 8, Ofs)
  Else
  Begin
    PokeL(Base + Prev + 4, Ofs);
    If Prev + PeekL(Base + Prev) = Ofs Then
    Begin
      PokeL(Base + Prev, PeekL(Base + Prev) + PeekL(Base + Ofs));
      PokeL(Base + Prev + 4, PeekL(Base + Ofs + 4));
    End;
  End;
  SubFree := NO_ERROR;
End;

Function DosSubSetMem(PbBase, Flag, Cb : LongInt) : LongInt;
Var OldSize : LongInt;
Begin
  If (Flag And DOSSUB_INIT) <> 0 Then
  Begin
    DosSubSetMem := SubInit(PbBase, Cb);
    Exit;
  End;
  { agrandir un pool existant : la nouvelle zone devient un bloc libre }
  If PeekL(PbBase) <> SubMagic Then
  Begin
    DosSubSetMem := ERROR_DOSSUB_BADSELECTOR;
    Exit;
  End;
  OldSize := PeekL(PbBase + 4);
  Cb := Cb And Not 7;
  If Cb < OldSize Then
  Begin
    DosSubSetMem := ERROR_DOSSUB_SHRINK;
    Exit;
  End;
  PokeL(PbBase + 4, Cb);
  If Cb > OldSize Then DosSubSetMem := SubFree(PbBase, OldSize, Cb - OldSize)
  Else DosSubSetMem := NO_ERROR;
End;

Function DosSubAllocMem(PbBase, PPb, Cb : LongInt) : LongInt;
Var Ofs, R : LongInt;
Begin
  Ofs := 0;
  R := SubAlloc(PbBase, Cb, Ofs);
  If R = NO_ERROR Then PokeL(PPb, PbBase + Ofs);
  DosSubAllocMem := R;
End;

Function DosSubFreeMem(PbBase, Pb, Cb : LongInt) : LongInt;
Begin
  DosSubFreeMem := SubFree(PbBase, Pb - PbBase, Cb);
End;

Function DosSubUnsetMem(PbBase : LongInt) : LongInt;
Begin
  If PeekL(PbBase) <> SubMagic Then
  Begin
    DosSubUnsetMem := ERROR_DOSSUB_BADSELECTOR;
    Exit;
  End;
  PokeL(PbBase, 0);
  DosSubUnsetMem := NO_ERROR;
End;

{ --- Segments 16 bits d'OS/2 1.x : selecteur = (index shl 3) or 7 --- }

Function SegIdx(Sel : LongInt) : LongInt;
Var I : LongInt;
Begin
  SegIdx := -1;
  If (Sel And 7) <> 7 Then Exit;
  I := Sel Shr 3;
  If (I >= 1) And (I < MaxSegs) Then
    If Segs[I].Used Then SegIdx := I;
End;

{ Adresse lineaire d'un selecteur (0 si invalide) }
Function SelBase(Sel : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SegIdx(Sel);
  If I < 0 Then SelBase := 0 Else SelBase := Segs[I].Base;
End;

Function SegNew(Size, NSeg : LongInt; Shared : Boolean; Name : String) : LongInt;
Var I, J, A, Free : LongInt;
Begin
  SegNew := -1;
  If NSeg < 1 Then NSeg := 1;
  For I := 1 To MaxSegs - NSeg Do
  Begin
    Free := 0;
    For J := I To I + NSeg - 1 Do
      If Not Segs[J].Used Then Inc(Free);
    If Free = NSeg Then
    Begin
      If Shared Then A := SharedAlloc(Size) Else A := KHeapAlloc(1, 8, Size);
      If A = 0 Then Exit;
      For J := I To I + NSeg - 1 Do
      Begin
        Segs[J].Used := True;
        Segs[J].Base := A + (J - I) * 65536;
        If J = I + NSeg - 1 Then Segs[J].Size := Size - (NSeg - 1) * 65536
        Else Segs[J].Size := 65536;
        Segs[J].Owner := MyPid;
        Segs[J].Huge := 0;
        Segs[J].Shared := Shared;
        Segs[J].Name := UpStr(Name);
      End;
      Segs[I].Huge := NSeg;
      SegNew := I;
      Exit;
    End;
  End;
End;

Function DosAllocSeg(Size, PSel, Flags : LongInt) : LongInt;
Var I : LongInt;
Begin
  If Size = 0 Then Size := 65536;
  If (Size < 0) Or (Size > 65536) Then
  Begin
    DosAllocSeg := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  I := SegNew(Size, 1, (Flags And 3) <> 0, '');
  If I < 0 Then
  Begin
    DosAllocSeg := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  PokeL(PSel, (I Shl 3) Or 7);
  DosAllocSeg := NO_ERROR;
End;

Function DosAllocShrSeg(Size, PName, PSel : LongInt) : LongInt;
Var I : LongInt; Name : String;
Begin
  Name := UpStr(GetStr(PName));
  If Copy(Name, 1, 10) <> '\SHAREMEM\' Then
  Begin
    DosAllocShrSeg := ERROR_INVALID_NAME;
    Exit;
  End;
  For I := 1 To MaxSegs - 1 Do
    If Segs[I].Used And (Segs[I].Name = Name) Then
    Begin
      DosAllocShrSeg := ERROR_ALREADY_EXISTS;
      Exit;
    End;
  If Size = 0 Then Size := 65536;
  I := SegNew(Size, 1, True, Name);
  If I < 0 Then
  Begin
    DosAllocShrSeg := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  PokeL(PSel, (I Shl 3) Or 7);
  DosAllocShrSeg := NO_ERROR;
End;

Function DosGetShrSeg(PName, PSel : LongInt) : LongInt;
Var I : LongInt; Name : String;
Begin
  Name := UpStr(GetStr(PName));
  For I := 1 To MaxSegs - 1 Do
    If Segs[I].Used And (Segs[I].Name = Name) Then
    Begin
      PokeL(PSel, (I Shl 3) Or 7);
      DosGetShrSeg := NO_ERROR;
      Exit;
    End;
  DosGetShrSeg := ERROR_FILE_NOT_FOUND;
End;

{ Objet huge : NumSeg segments de 64 Ko plus Size octets }
Function DosAllocHuge(NumSeg, Size, PSel, MaxSeg, Flags : LongInt) : LongInt;
Var I, Total, N : LongInt;
Begin
  Total := NumSeg * 65536 + Size;
  N := NumSeg;
  If Size > 0 Then Inc(N);
  If (N < 1) Or (Total <= 0) Then
  Begin
    DosAllocHuge := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  I := SegNew(Total, N, (Flags And 3) <> 0, '');
  If I < 0 Then
  Begin
    DosAllocHuge := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  PokeL(PSel, (I Shl 3) Or 7);
  DosAllocHuge := NO_ERROR;
End;

{ les selecteurs d'un objet huge se suivent de 8 : decalage 3 }
Function DosGetHugeShift(PCount : LongInt) : LongInt;
Begin
  PokeL(PCount, 3);
  DosGetHugeShift := NO_ERROR;
End;

Function DosFreeSeg(Sel : LongInt) : LongInt;
Var I, J, N : LongInt;
Begin
  I := SegIdx(Sel);
  If I < 0 Then
  Begin
    DosFreeSeg := ERROR_INVALID_SEGMENT_NUMBER;
    Exit;
  End;
  N := Segs[I].Huge;
  If N = -1 Then
  Begin
    { alias (DosCreateCSAlias) : seul le selecteur est libere }
    Segs[I].Used := False;
    DosFreeSeg := NO_ERROR;
    Exit;
  End;
  If N < 1 Then N := 1;
  If Segs[I].Shared Then KHeapFree(2, 0, Segs[I].Base) Else KHeapFree(1, 0, Segs[I].Base);
  For J := I To I + N - 1 Do Segs[J].Used := False;
  DosFreeSeg := NO_ERROR;
End;

{ Changer la taille : nouvel objet, copie, liberation de l'ancien }
Function ReallocSegs(Sel, NewTotal, NewN : LongInt) : LongInt;
Var I, J, N, A, Old, OldTotal : LongInt;
Begin
  I := SegIdx(Sel);
  If I < 0 Then
  Begin
    ReallocSegs := ERROR_INVALID_SEGMENT_NUMBER;
    Exit;
  End;
  N := Segs[I].Huge;
  If N < 1 Then N := 1;
  If NewN > N Then
    For J := I + N To I + NewN - 1 Do
      If (J >= MaxSegs) Or Segs[J].Used Then
      Begin
        ReallocSegs := ERROR_NOT_ENOUGH_MEMORY;
        Exit;
      End;
  OldTotal := (N - 1) * 65536 + Segs[I + N - 1].Size;
  If Segs[I].Shared Then A := SharedAlloc(NewTotal) Else A := KHeapAlloc(1, 8, NewTotal);
  If A = 0 Then
  Begin
    ReallocSegs := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  Old := Segs[I].Base;
  If OldTotal > NewTotal Then OldTotal := NewTotal;
  MoveB(Old, A, OldTotal);
  If Segs[I].Shared Then KHeapFree(2, 0, Old) Else KHeapFree(1, 0, Old);
  For J := I To I + N - 1 Do Segs[J].Used := False;
  For J := I To I + NewN - 1 Do
  Begin
    Segs[J].Used := True;
    Segs[J].Base := A + (J - I) * 65536;
    If J = I + NewN - 1 Then Segs[J].Size := NewTotal - (NewN - 1) * 65536
    Else Segs[J].Size := 65536;
    Segs[J].Owner := MyPid;
    Segs[J].Huge := 0;
    Segs[J].Shared := Segs[I].Shared;
  End;
  Segs[I].Huge := NewN;
  ReallocSegs := NO_ERROR;
End;

Function DosReallocSeg(Size, Sel : LongInt) : LongInt;
Begin
  If Size = 0 Then Size := 65536;
  DosReallocSeg := ReallocSegs(Sel, Size, 1);
End;

Function DosReallocHuge(NumSeg, Size, Sel : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := NumSeg;
  If Size > 0 Then Inc(N);
  DosReallocHuge := ReallocSegs(Sel, NumSeg * 65536 + Size, N);
End;

Function DosSizeSeg(Sel, PSize : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SegIdx(Sel);
  If I < 0 Then
  Begin
    DosSizeSeg := ERROR_INVALID_SEGMENT_NUMBER;
    Exit;
  End;
  PokeL(PSize, Segs[I].Size);
  DosSizeSeg := NO_ERROR;
End;

Function DosGetSeg(Sel : LongInt) : LongInt;
Begin
  If SegIdx(Sel) < 0 Then DosGetSeg := ERROR_INVALID_SEGMENT_NUMBER
  Else DosGetSeg := NO_ERROR;
End;

Function DosGiveSeg(Sel, Pid, PRecipSel : LongInt) : LongInt;
Begin
  If SegIdx(Sel) < 0 Then
  Begin
    DosGiveSeg := ERROR_INVALID_SEGMENT_NUMBER;
    Exit;
  End;
  PokeL(PRecipSel, Sel);        { memoire plate commune : meme selecteur }
  DosGiveSeg := NO_ERROR;
End;

Function DosLockSeg(Sel : LongInt) : LongInt;
Begin
  If SegIdx(Sel) < 0 Then DosLockSeg := ERROR_INVALID_SEGMENT_NUMBER Else DosLockSeg := NO_ERROR;
End;

Function DosUnlockSeg(Sel : LongInt) : LongInt;
Begin
  If SegIdx(Sel) < 0 Then DosUnlockSeg := ERROR_INVALID_SEGMENT_NUMBER Else DosUnlockSeg := NO_ERROR;
End;

{ Alias de code : nouveau selecteur designant la meme memoire }
Function DosCreateCSAlias(Sel, PCsSel : LongInt) : LongInt;
Var I, J : LongInt;
Begin
  I := SegIdx(Sel);
  If I < 0 Then
  Begin
    DosCreateCSAlias := ERROR_INVALID_SEGMENT_NUMBER;
    Exit;
  End;
  For J := 1 To MaxSegs - 1 Do
    If Not Segs[J].Used Then
    Begin
      Segs[J] := Segs[I];
      Segs[J].Huge := -1;         { alias : la memoire n'est pas liberee }
      PokeL(PCsSel, (J Shl 3) Or 7);
      DosCreateCSAlias := NO_ERROR;
      Exit;
    End;
  DosCreateCSAlias := ERROR_NOT_ENOUGH_MEMORY;
End;

Function DosSubSet(Sel, Flags, Size : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := SelBase(Sel);
  If A = 0 Then
  Begin
    DosSubSet := ERROR_DOSSUB_BADSELECTOR;
    Exit;
  End;
  If Size = 0 Then Size := 65536;
  DosSubSet := DosSubSetMem(A, Flags, Size);
End;

Function DosSubAlloc(Sel, POfs, Size : LongInt) : LongInt;
Var A, Ofs, R : LongInt;
Begin
  A := SelBase(Sel);
  If A = 0 Then
  Begin
    DosSubAlloc := ERROR_DOSSUB_BADSELECTOR;
    Exit;
  End;
  Ofs := 0;
  R := SubAlloc(A, Size, Ofs);
  If R = NO_ERROR Then PokeL(POfs, Ofs);
  DosSubAlloc := R;
End;

Function DosSubFree(Sel, Ofs, Size : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := SelBase(Sel);
  If A = 0 Then DosSubFree := ERROR_DOSSUB_BADSELECTOR
  Else DosSubFree := SubFree(A, Ofs, Size);
End;

{ Plus grand bloc libre }
Function DosMemAvail(PSize : LongInt) : LongInt;
Var MS : Array[0..7] Of LongInt;
Begin
  KGlobalMemoryStatus(LongInt(@MS));
  PokeL(PSize, MS[7]);
  DosMemAvail := NO_ERROR;
End;

Function DosR2StackRealloc(NewSize : LongInt) : LongInt;
Begin
  If NewSize <= 0 Then DosR2StackRealloc := ERROR_INVALID_PARAMETER
  Else DosR2StackRealloc := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 9 - Semaphores                                                }
{ ==================================================================== }
{ Semaphores 32 bits (OS/2 2.x) : evenement (HEV = 00020000h + n),
  mutex (HMTX = 00030000h + n), MuxWait (HMUX = 00040000h + n), nommes
  \SEM32\... Semaphores 16 bits (OS/2 1.x) : semaphores systeme nommes
  \SEM\... (HSEM = 0F000000h + n) ou semaphores RAM (HSEM = adresse d'un
  mot double : 0 libre, autre valeur positionnee).
  Une attente ne peut etre satisfaite que par une minuterie (un seul
  processus leger) : sans minuterie en cours, une attente sans fin rend
  ERROR_INTERRUPT au lieu de bloquer le systeme. }

Const
  MaxSem   = 64;
  MaxSem16 = 32;
  MaxMux   = 16;
  SK_EVENT = 1;
  SK_MUTEX = 2;
  SK_MUX   = 3;

Type
  TSem = Record
    Used    : Boolean;
    Kind    : LongInt;
    Name    : String[63];
    Shared  : Boolean;
    Opens   : LongInt;
    Owner   : LongInt;        { processus createur }
    Posted  : Boolean;
    PostCnt : LongInt;
    MtxPid  : LongInt;        { proprietaire du mutex (0 = libre) }
    MtxTid  : LongInt;
    MtxCnt  : LongInt;
    MuxN    : LongInt;
    MuxAttr : LongInt;
    MuxH    : Array[0..MaxMux - 1] Of LongInt;
    MuxU    : Array[0..MaxMux - 1] Of LongInt;
  End;
  TSem16 = Record
    Used    : Boolean;
    Name    : String[63];
    IsSet   : Boolean;
    Owner   : LongInt;
    Excl    : Boolean;
    Count   : LongInt;
  End;

Var
  Sems  : Array[0..MaxSem - 1] Of TSem;
  Sem16 : Array[0..MaxSem16 - 1] Of TSem16;

Procedure PollTimers; Forward;
Function TimerPendingFor(HSem : LongInt) : Boolean; Forward;

Function SemHandle(I : LongInt) : LongInt;
Begin
  SemHandle := ((Sems[I].Kind + 1) Shl 16) + I;
End;

{ Index d'un semaphore 32 bits du type Kind, -1 si handle invalide }
Function SemIdx(H, Kind : LongInt) : LongInt;
Var I : LongInt;
Begin
  SemIdx := -1;
  I := H And $FFFF;
  If ((H Shr 16) <> Kind + 1) Or (I >= MaxSem) Then Exit;
  If Not Sems[I].Used Or (Sems[I].Kind <> Kind) Then Exit;
  If Not Sems[I].Shared And (Sems[I].Owner <> MyPid) Then Exit;
  SemIdx := I;
End;

Function SemCreate(PName, Kind, Attr : LongInt; Var Idx : LongInt) : LongInt;
Var I : LongInt; Name : String;
Begin
  Name := '';
  If PName <> 0 Then
  Begin
    Name := UpStr(GetStr(PName));
    If (Name <> '') And (Copy(Name, 1, 7) <> '\SEM32\') Then
    Begin
      SemCreate := ERROR_INVALID_NAME;
      Exit;
    End;
  End;
  If Name <> '' Then
    For I := 0 To MaxSem - 1 Do
      If Sems[I].Used And (Sems[I].Name = Name) Then
      Begin
        SemCreate := ERROR_DUPLICATE_NAME;
        Exit;
      End;
  For I := 0 To MaxSem - 1 Do
    If Not Sems[I].Used Then
    Begin
      Sems[I].Used := True;
      Sems[I].Kind := Kind;
      Sems[I].Name := Name;
      Sems[I].Shared := (Name <> '') Or ((Attr And DC_SEM_SHARED) <> 0);
      Sems[I].Opens := 1;
      Sems[I].Owner := MyPid;
      Sems[I].Posted := False;
      Sems[I].PostCnt := 0;
      Sems[I].MtxPid := 0; Sems[I].MtxTid := 0; Sems[I].MtxCnt := 0;
      Sems[I].MuxN := 0; Sems[I].MuxAttr := 0;
      Idx := I;
      SemCreate := NO_ERROR;
      Exit;
    End;
  SemCreate := ERROR_TOO_MANY_HANDLES;
End;

Function SemOpen(PName, PH, Kind : LongInt) : LongInt;
Var I, H : LongInt; Name : String;
Begin
  H := PeekL(PH);
  If H <> 0 Then
  Begin
    I := SemIdx(H, Kind);
    If I < 0 Then
    Begin
      SemOpen := ERROR_INVALID_HANDLE;
      Exit;
    End;
    Inc(Sems[I].Opens);
    SemOpen := NO_ERROR;
    Exit;
  End;
  Name := UpStr(GetStr(PName));
  For I := 0 To MaxSem - 1 Do
    If Sems[I].Used And (Sems[I].Kind = Kind) And (Sems[I].Name = Name) And (Name <> '') Then
    Begin
      Inc(Sems[I].Opens);
      PokeL(PH, SemHandle(I));
      SemOpen := NO_ERROR;
      Exit;
    End;
  SemOpen := ERROR_SEM_NOT_FOUND;
End;

Function SemClose(H, Kind : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SemIdx(H, Kind);
  If I < 0 Then
  Begin
    SemClose := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If (Kind = SK_MUTEX) And (Sems[I].MtxPid <> 0) And (Sems[I].Opens <= 1) Then
  Begin
    SemClose := ERROR_SEM_BUSY;
    Exit;
  End;
  Dec(Sems[I].Opens);
  If Sems[I].Opens <= 0 Then Sems[I].Used := False;
  SemClose := NO_ERROR;
End;

{ --- Semaphores d'evenement --- }

Function DosCreateEventSem(PName, PHev, Attr, State : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := SemCreate(PName, SK_EVENT, Attr, I);
  If R = NO_ERROR Then
  Begin
    Sems[I].Posted := State <> 0;
    If State <> 0 Then Sems[I].PostCnt := 1;
    PokeL(PHev, SemHandle(I));
  End;
  DosCreateEventSem := R;
End;

Function DosOpenEventSem(PName, PHev : LongInt) : LongInt;
Begin
  DosOpenEventSem := SemOpen(PName, PHev, SK_EVENT);
End;

Function DosCloseEventSem(H : LongInt) : LongInt;
Begin
  DosCloseEventSem := SemClose(H, SK_EVENT);
End;

Function EvPost(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SemIdx(H, SK_EVENT);
  If I < 0 Then
  Begin
    EvPost := ERROR_INVALID_HANDLE;
    Exit;
  End;
  Inc(Sems[I].PostCnt);
  If Sems[I].Posted Then
  Begin
    EvPost := ERROR_ALREADY_POSTED;
    Exit;
  End;
  Sems[I].Posted := True;
  EvPost := NO_ERROR;
End;

Function DosPostEventSem(H : LongInt) : LongInt;
Begin
  PollTimers;
  DosPostEventSem := EvPost(H);
End;

Function DosResetEventSem(H, PCount : LongInt) : LongInt;
Var I : LongInt;
Begin
  PollTimers;
  I := SemIdx(H, SK_EVENT);
  If I < 0 Then
  Begin
    DosResetEventSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  PokeL(PCount, Sems[I].PostCnt);
  If Not Sems[I].Posted Then
  Begin
    DosResetEventSem := ERROR_ALREADY_RESET;
    Exit;
  End;
  Sems[I].Posted := False;
  Sems[I].PostCnt := 0;
  DosResetEventSem := NO_ERROR;
End;

Function DosQueryEventSem(H, PCount : LongInt) : LongInt;
Var I : LongInt;
Begin
  PollTimers;
  I := SemIdx(H, SK_EVENT);
  If I < 0 Then
  Begin
    DosQueryEventSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  PokeL(PCount, Sems[I].PostCnt);
  DosQueryEventSem := NO_ERROR;
End;

{ Attente commune : Satisfied(H) est evalue par WaitKind }
Function SemSatisfied(H, Kind : LongInt) : Boolean; Forward;

Function WaitKind(H, Kind, Timeout : LongInt) : LongInt;
Var Start : LongInt;
Begin
  Start := KGetTickCount;
  Repeat
    PollTimers;
    If SemSatisfied(H, Kind) Then
    Begin
      WaitKind := NO_ERROR;
      Exit;
    End;
    If Timeout = 0 Then
    Begin
      WaitKind := ERROR_TIMEOUT;
      Exit;
    End;
    If (Timeout > 0) And (KGetTickCount - Start >= Timeout) Then
    Begin
      WaitKind := ERROR_TIMEOUT;
      Exit;
    End;
    If (Timeout < 0) And Not TimerPendingFor(H) Then
    Begin
      WaitKind := ERROR_INTERRUPT;
      Exit;
    End;
    KSleep(10);
  Until False;
End;

Function DosWaitEventSem(H, Timeout : LongInt) : LongInt;
Begin
  If SemIdx(H, SK_EVENT) < 0 Then
  Begin
    DosWaitEventSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  DosWaitEventSem := WaitKind(H, SK_EVENT, Timeout);
End;

{ --- Semaphores mutex --- }

Function DosCreateMutexSem(PName, PHmtx, Attr, State : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := SemCreate(PName, SK_MUTEX, Attr, I);
  If R = NO_ERROR Then
  Begin
    If State <> 0 Then
    Begin
      Sems[I].MtxPid := MyPid; Sems[I].MtxTid := 1; Sems[I].MtxCnt := 1;
    End;
    PokeL(PHmtx, SemHandle(I));
  End;
  DosCreateMutexSem := R;
End;

Function DosOpenMutexSem(PName, PHmtx : LongInt) : LongInt;
Begin
  DosOpenMutexSem := SemOpen(PName, PHmtx, SK_MUTEX);
End;

Function DosCloseMutexSem(H : LongInt) : LongInt;
Begin
  DosCloseMutexSem := SemClose(H, SK_MUTEX);
End;

Function CurTid : LongInt; Forward;

Function DosRequestMutexSem(H, Timeout : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  I := SemIdx(H, SK_MUTEX);
  If I < 0 Then
  Begin
    DosRequestMutexSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If (Sems[I].MtxPid = MyPid) And (Sems[I].MtxTid = CurTid) Then
  Begin
    If Sems[I].MtxCnt >= 65535 Then
    Begin
      DosRequestMutexSem := ERROR_TOO_MANY_SEM_REQUESTS;
      Exit;
    End;
    Inc(Sems[I].MtxCnt);
    DosRequestMutexSem := NO_ERROR;
    Exit;
  End;
  R := WaitKind(H, SK_MUTEX, Timeout);
  If R = NO_ERROR Then
  Begin
    Sems[I].MtxPid := MyPid; Sems[I].MtxTid := CurTid; Sems[I].MtxCnt := 1;
  End;
  DosRequestMutexSem := R;
End;

Function DosReleaseMutexSem(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SemIdx(H, SK_MUTEX);
  If I < 0 Then
  Begin
    DosReleaseMutexSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If (Sems[I].MtxPid <> MyPid) Or (Sems[I].MtxCnt = 0) Then
  Begin
    DosReleaseMutexSem := ERROR_NOT_OWNER;
    Exit;
  End;
  Dec(Sems[I].MtxCnt);
  If Sems[I].MtxCnt = 0 Then
  Begin
    Sems[I].MtxPid := 0; Sems[I].MtxTid := 0;
  End;
  DosReleaseMutexSem := NO_ERROR;
End;

Function DosQueryMutexSem(H, PPid, PTid, PCount : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := SemIdx(H, SK_MUTEX);
  If I < 0 Then
  Begin
    DosQueryMutexSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  PokeL(PPid, Sems[I].MtxPid);
  PokeL(PTid, Sems[I].MtxTid);
  PokeL(PCount, Sems[I].MtxCnt);
  DosQueryMutexSem := NO_ERROR;
End;

{ --- Semaphores MuxWait (SEMRECORD = hsemCur, ulUser) --- }

Function MuxValidMember(H : LongInt) : Boolean;
Begin
  MuxValidMember := (SemIdx(H, SK_EVENT) >= 0) Or (SemIdx(H, SK_MUTEX) >= 0);
End;

Function DosCreateMuxWaitSem(PName, PHmux, CRec, PRec, Attr : LongInt) : LongInt;
Var I, R, K : LongInt;
Begin
  If ((Attr And (DCMW_WAIT_ANY Or DCMW_WAIT_ALL)) = 0) Or
     ((Attr And (DCMW_WAIT_ANY Or DCMW_WAIT_ALL)) = (DCMW_WAIT_ANY Or DCMW_WAIT_ALL)) Or
     (CRec > MaxMux) Then
  Begin
    DosCreateMuxWaitSem := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  For K := 0 To CRec - 1 Do
    If Not MuxValidMember(PeekL(PRec + K * 8)) Then
    Begin
      DosCreateMuxWaitSem := ERROR_INVALID_HANDLE;
      Exit;
    End;
  R := SemCreate(PName, SK_MUX, Attr, I);
  If R = NO_ERROR Then
  Begin
    Sems[I].MuxAttr := Attr;
    Sems[I].MuxN := CRec;
    For K := 0 To CRec - 1 Do
    Begin
      Sems[I].MuxH[K] := PeekL(PRec + K * 8);
      Sems[I].MuxU[K] := PeekL(PRec + K * 8 + 4);
    End;
    PokeL(PHmux, SemHandle(I));
  End;
  DosCreateMuxWaitSem := R;
End;

Function DosOpenMuxWaitSem(PName, PHmux : LongInt) : LongInt;
Begin
  DosOpenMuxWaitSem := SemOpen(PName, PHmux, SK_MUX);
End;

Function DosCloseMuxWaitSem(H : LongInt) : LongInt;
Begin
  DosCloseMuxWaitSem := SemClose(H, SK_MUX);
End;

Function DosAddMuxWaitSem(H, PRec : LongInt) : LongInt;
Var I, K, Hs : LongInt;
Begin
  I := SemIdx(H, SK_MUX);
  If I < 0 Then
  Begin
    DosAddMuxWaitSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  Hs := PeekL(PRec);
  If Not MuxValidMember(Hs) Then
  Begin
    DosAddMuxWaitSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  For K := 0 To Sems[I].MuxN - 1 Do
    If Sems[I].MuxH[K] = Hs Then
    Begin
      DosAddMuxWaitSem := ERROR_DUPLICATE_NAME;
      Exit;
    End;
  If Sems[I].MuxN >= MaxMux Then
  Begin
    DosAddMuxWaitSem := ERROR_TOO_MANY_SEMAPHORES;
    Exit;
  End;
  Sems[I].MuxH[Sems[I].MuxN] := Hs;
  Sems[I].MuxU[Sems[I].MuxN] := PeekL(PRec + 4);
  Inc(Sems[I].MuxN);
  DosAddMuxWaitSem := NO_ERROR;
End;

Function DosDeleteMuxWaitSem(H, HSem : LongInt) : LongInt;
Var I, K, J : LongInt;
Begin
  I := SemIdx(H, SK_MUX);
  If I < 0 Then
  Begin
    DosDeleteMuxWaitSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  For K := 0 To Sems[I].MuxN - 1 Do
    If Sems[I].MuxH[K] = HSem Then
    Begin
      For J := K To Sems[I].MuxN - 2 Do
      Begin
        Sems[I].MuxH[J] := Sems[I].MuxH[J + 1];
        Sems[I].MuxU[J] := Sems[I].MuxU[J + 1];
      End;
      Dec(Sems[I].MuxN);
      DosDeleteMuxWaitSem := NO_ERROR;
      Exit;
    End;
  DosDeleteMuxWaitSem := ERROR_INVALID_HANDLE;
End;

Function DosQueryMuxWaitSem(H, PCRec, PRec, PAttr : LongInt) : LongInt;
Var I, K : LongInt;
Begin
  I := SemIdx(H, SK_MUX);
  If I < 0 Then
  Begin
    DosQueryMuxWaitSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If PeekL(PCRec) < Sems[I].MuxN Then
  Begin
    PokeL(PCRec, Sems[I].MuxN);
    DosQueryMuxWaitSem := ERROR_PARAM_TOO_SMALL;
    Exit;
  End;
  For K := 0 To Sems[I].MuxN - 1 Do
  Begin
    PokeL(PRec + K * 8, Sems[I].MuxH[K]);
    PokeL(PRec + K * 8 + 4, Sems[I].MuxU[K]);
  End;
  PokeL(PCRec, Sems[I].MuxN);
  PokeL(PAttr, Sems[I].MuxAttr);
  DosQueryMuxWaitSem := NO_ERROR;
End;

Var
  MuxLastUser : LongInt;

{ Un membre est-il satisfait (evenement poste, mutex libre ou a soi) ? }
Function MemberReady(H : LongInt) : Boolean;
Var I : LongInt;
Begin
  MemberReady := False;
  I := SemIdx(H, SK_EVENT);
  If I >= 0 Then
  Begin
    MemberReady := Sems[I].Posted;
    Exit;
  End;
  I := SemIdx(H, SK_MUTEX);
  If I >= 0 Then
    MemberReady := (Sems[I].MtxPid = 0) Or (Sems[I].MtxPid = MyPid);
End;

Function SemSatisfied(H, Kind : LongInt) : Boolean;
Var I, K, N : LongInt;
Begin
  SemSatisfied := False;
  I := SemIdx(H, Kind);
  If I < 0 Then Exit;
  Case Kind Of
    SK_EVENT : SemSatisfied := Sems[I].Posted;
    SK_MUTEX : SemSatisfied := (Sems[I].MtxPid = 0) Or
                               ((Sems[I].MtxPid = MyPid) And (Sems[I].MtxTid = CurTid));
    SK_MUX :
      Begin
        N := 0;
        For K := 0 To Sems[I].MuxN - 1 Do
          If MemberReady(Sems[I].MuxH[K]) Then
          Begin
            Inc(N);
            If (Sems[I].MuxAttr And DCMW_WAIT_ANY) <> 0 Then
            Begin
              MuxLastUser := Sems[I].MuxU[K];
              SemSatisfied := True;
              Exit;
            End;
          End;
        If ((Sems[I].MuxAttr And DCMW_WAIT_ALL) <> 0) And (N = Sems[I].MuxN) And (N > 0) Then
        Begin
          MuxLastUser := 0;
          SemSatisfied := True;
        End;
      End;
  End;
End;

Function DosWaitMuxWaitSem(H, Timeout, PUser : LongInt) : LongInt;
Var I, K, R, J : LongInt;
Begin
  I := SemIdx(H, SK_MUX);
  If I < 0 Then
  Begin
    DosWaitMuxWaitSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If Sems[I].MuxN = 0 Then
  Begin
    DosWaitMuxWaitSem := ERROR_EMPTY_MUXWAIT;
    Exit;
  End;
  R := WaitKind(H, SK_MUX, Timeout);
  If R = NO_ERROR Then
  Begin
    { les mutex obtenus deviennent la propriete de l'appelant }
    For K := 0 To Sems[I].MuxN - 1 Do
    Begin
      J := SemIdx(Sems[I].MuxH[K], SK_MUTEX);
      If (J >= 0) And (((Sems[I].MuxAttr And DCMW_WAIT_ALL) <> 0) Or
         (Sems[I].MuxU[K] = MuxLastUser)) Then
      Begin
        Sems[J].MtxPid := MyPid; Sems[J].MtxTid := CurTid; Inc(Sems[J].MtxCnt);
      End;
    End;
    PokeL(PUser, MuxLastUser);
  End;
  DosWaitMuxWaitSem := R;
End;

{ --- Semaphores 16 bits (systeme et RAM) --- }

Function S16Idx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  S16Idx := -1;
  If (H And $FF000000) <> $0F000000 Then Exit;
  I := H And $FFFF;
  If (I < MaxSem16) And Sem16[I].Used Then S16Idx := I;
End;

{ RAM : toute autre valeur non nulle est l'adresse du mot double }
Function S16IsSet(H : LongInt) : Boolean;
Var I : LongInt;
Begin
  I := S16Idx(H);
  If I >= 0 Then S16IsSet := Sem16[I].IsSet Else S16IsSet := PeekL(H) <> 0;
End;

Procedure S16Put(H : LongInt; Value : Boolean);
Var I : LongInt;
Begin
  I := S16Idx(H);
  If I >= 0 Then
  Begin
    Sem16[I].IsSet := Value;
    If Value Then Sem16[I].Owner := MyPid Else Sem16[I].Owner := 0;
  End
  Else If Value Then PokeL(H, 1) Else PokeL(H, 0);
End;

Function S16Valid(H : LongInt) : Boolean;
Begin
  If (H And $FF000000) = $0F000000 Then S16Valid := S16Idx(H) >= 0
  Else S16Valid := (H <> 0) And ((H And 3) = 0);
End;

Function DosCreateSem(NoExcl, PHSem, PName : LongInt) : LongInt;
Var I : LongInt; Name : String;
Begin
  Name := UpStr(GetStr(PName));
  If Copy(Name, 1, 5) <> '\SEM\' Then
  Begin
    DosCreateSem := ERROR_INVALID_NAME;
    Exit;
  End;
  For I := 0 To MaxSem16 - 1 Do
    If Sem16[I].Used And (Sem16[I].Name = Name) Then
    Begin
      DosCreateSem := ERROR_ALREADY_EXISTS;
      Exit;
    End;
  For I := 0 To MaxSem16 - 1 Do
    If Not Sem16[I].Used Then
    Begin
      Sem16[I].Used := True;
      Sem16[I].Name := Name;
      Sem16[I].IsSet := False;
      Sem16[I].Owner := 0;
      Sem16[I].Excl := NoExcl = 0;
      Sem16[I].Count := 1;
      PokeL(PHSem, $0F000000 + I);
      DosCreateSem := NO_ERROR;
      Exit;
    End;
  DosCreateSem := ERROR_TOO_MANY_SEMAPHORES;
End;

Function DosOpenSem(PHSem, PName : LongInt) : LongInt;
Var I : LongInt; Name : String;
Begin
  Name := UpStr(GetStr(PName));
  For I := 0 To MaxSem16 - 1 Do
    If Sem16[I].Used And (Sem16[I].Name = Name) Then
    Begin
      Inc(Sem16[I].Count);
      PokeL(PHSem, $0F000000 + I);
      DosOpenSem := NO_ERROR;
      Exit;
    End;
  DosOpenSem := ERROR_SEM_NOT_FOUND;
End;

Function DosCloseSem(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := S16Idx(H);
  If I < 0 Then
  Begin
    DosCloseSem := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If Sem16[I].IsSet And Sem16[I].Excl And (Sem16[I].Owner = MyPid) Then
  Begin
    DosCloseSem := ERROR_SEM_IS_SET;
    Exit;
  End;
  Dec(Sem16[I].Count);
  If Sem16[I].Count <= 0 Then Sem16[I].Used := False;
  DosCloseSem := NO_ERROR;
End;

Function DosSemSet(H : LongInt) : LongInt;
Begin
  If Not S16Valid(H) Then
  Begin
    DosSemSet := ERROR_INVALID_HANDLE;
    Exit;
  End;
  S16Put(H, True);
  DosSemSet := NO_ERROR;
End;

Function DosSemClear(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  If Not S16Valid(H) Then
  Begin
    DosSemClear := ERROR_INVALID_HANDLE;
    Exit;
  End;
  I := S16Idx(H);
  If (I >= 0) And Sem16[I].Excl And Sem16[I].IsSet And (Sem16[I].Owner <> MyPid) Then
  Begin
    DosSemClear := ERROR_EXCL_SEM_ALREADY_OWNED;
    Exit;
  End;
  S16Put(H, False);
  DosSemClear := NO_ERROR;
End;

{ Attendre que le semaphore 16 bits soit libre }
Function S16WaitClear(H, Timeout : LongInt) : LongInt;
Var Start : LongInt;
Begin
  Start := KGetTickCount;
  Repeat
    PollTimers;
    If Not S16IsSet(H) Then
    Begin
      S16WaitClear := NO_ERROR;
      Exit;
    End;
    If (Timeout = 0) Or ((Timeout > 0) And (KGetTickCount - Start >= Timeout)) Then
    Begin
      S16WaitClear := ERROR_SEM_TIMEOUT;
      Exit;
    End;
    If (Timeout < 0) And Not TimerPendingFor(H) Then
    Begin
      S16WaitClear := ERROR_INTERRUPT;
      Exit;
    End;
    KSleep(10);
  Until False;
End;

Function DosSemRequest(H, Timeout : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Not S16Valid(H) Then
  Begin
    DosSemRequest := ERROR_INVALID_HANDLE;
    Exit;
  End;
  R := S16WaitClear(H, Timeout);
  If R = NO_ERROR Then S16Put(H, True);
  DosSemRequest := R;
End;

Function DosSemWait(H, Timeout : LongInt) : LongInt;
Begin
  If Not S16Valid(H) Then DosSemWait := ERROR_INVALID_HANDLE
  Else DosSemWait := S16WaitClear(H, Timeout);
End;

Function DosSemSetWait(H, Timeout : LongInt) : LongInt;
Begin
  If Not S16Valid(H) Then
  Begin
    DosSemSetWait := ERROR_INVALID_HANDLE;
    Exit;
  End;
  S16Put(H, True);
  DosSemSetWait := S16WaitClear(H, Timeout);
End;

{ MUXSEMLIST : cmxs (mot), puis des MUXSEM : zero (mot), hsem (mot double) }
Function DosMuxSemWait(PIndex, PList, Timeout : LongInt) : LongInt;
Var N, K, Start : LongInt;
Begin
  N := PeekW(PList);
  If (N < 1) Or (N > 16) Then
  Begin
    DosMuxSemWait := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Start := KGetTickCount;
  Repeat
    PollTimers;
    For K := 0 To N - 1 Do
      If Not S16IsSet(PeekL(PList + 2 + K * 6 + 2)) Then
      Begin
        PokeW(PIndex, K);
        DosMuxSemWait := NO_ERROR;
        Exit;
      End;
    If (Timeout = 0) Or ((Timeout > 0) And (KGetTickCount - Start >= Timeout)) Then
    Begin
      DosMuxSemWait := ERROR_SEM_TIMEOUT;
      Exit;
    End;
    If Timeout < 0 Then
    Begin
      K := 0;
      While (K < N) And Not TimerPendingFor(PeekL(PList + 2 + K * 6 + 2)) Do Inc(K);
      If K >= N Then
      Begin
        DosMuxSemWait := ERROR_INTERRUPT;
        Exit;
      End;
    End;
    KSleep(10);
  Until False;
End;

{ Semaphore RAM Fast-Safe : DOSFSRSEM = cb, pid, tid, cUsage, client
  (mots), sem (mot double en +10) }
Function DosFSRamSemRequest(PFs, Timeout : LongInt) : LongInt;
Var Pid, R : LongInt;
Begin
  Pid := MyPid And $FFFF;
  If (PeekW(PFs + 2) = Pid) And (PeekW(PFs + 4) = CurTid) Then
  Begin
    PokeW(PFs + 6, PeekW(PFs + 6) + 1);
    DosFSRamSemRequest := NO_ERROR;
    Exit;
  End;
  R := S16WaitClear(PFs + 10, Timeout);
  If R = NO_ERROR Then
  Begin
    PokeL(PFs + 10, 1);
    PokeW(PFs + 2, Pid);
    PokeW(PFs + 4, CurTid);
    PokeW(PFs + 6, 1);
  End;
  DosFSRamSemRequest := R;
End;

Function DosFSRamSemClear(PFs : LongInt) : LongInt;
Var N : LongInt;
Begin
  If PeekW(PFs + 2) <> (MyPid And $FFFF) Then
  Begin
    DosFSRamSemClear := ERROR_NOT_OWNER;
    Exit;
  End;
  N := PeekW(PFs + 6) - 1;
  If N <= 0 Then
  Begin
    PokeW(PFs + 2, 0);
    PokeW(PFs + 4, 0);
    PokeW(PFs + 6, 0);
    PokeL(PFs + 10, 0);
  End
  Else
    PokeW(PFs + 6, N);
  DosFSRamSemClear := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 10 - Temps et minuteries                                      }
{ ==================================================================== }

Const
  MaxTimers = 16;

Type
  TTimer = Record
    Used     : Boolean;
    Due      : LongInt;       { echeance (GetTickCount, ms) }
    Interval : LongInt;       { 0 : une seule fois }
    Sem      : LongInt;
    Is32     : Boolean;       { HEV a poster, sinon HSEM 16 bits a liberer }
  End;

Var
  Timers : Array[0..MaxTimers - 1] Of TTimer;

Procedure PollTimers;
Var I, Now : LongInt;
Begin
  Now := KGetTickCount;
  For I := 0 To MaxTimers - 1 Do
    If Timers[I].Used And (Now - Timers[I].Due >= 0) Then
    Begin
      If Timers[I].Is32 Then EvPost(Timers[I].Sem)
      Else S16Put(Timers[I].Sem, False);
      If Timers[I].Interval > 0 Then
      Begin
        Timers[I].Due := Timers[I].Due + Timers[I].Interval;
        If Now - Timers[I].Due > Timers[I].Interval * 4 Then Timers[I].Due := Now + Timers[I].Interval;
      End
      Else
        Timers[I].Used := False;
    End;
End;

Function TimerPendingFor(HSem : LongInt) : Boolean;
Var I : LongInt;
Begin
  TimerPendingFor := False;
  For I := 0 To MaxTimers - 1 Do
    If Timers[I].Used And (Timers[I].Sem = HSem) Then TimerPendingFor := True;
End;

Function NewTimer(Msec, HSem, PHTimer, Interval : LongInt; Is32 : Boolean) : LongInt;
Var I : LongInt;
Begin
  If Is32 And (SemIdx(HSem, SK_EVENT) < 0) Then
  Begin
    NewTimer := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If (Not Is32) And Not S16Valid(HSem) Then
  Begin
    NewTimer := ERROR_TS_SEMHANDLE;
    Exit;
  End;
  For I := 0 To MaxTimers - 1 Do
    If Not Timers[I].Used Then
    Begin
      Timers[I].Used := True;
      Timers[I].Due := KGetTickCount + Msec;
      Timers[I].Interval := Interval;
      Timers[I].Sem := HSem;
      Timers[I].Is32 := Is32;
      PokeL(PHTimer, I + 1);
      NewTimer := NO_ERROR;
      Exit;
    End;
  NewTimer := ERROR_TS_NOTIMER;
End;

Function StopTimer(H : LongInt) : LongInt;
Begin
  If (H < 1) Or (H > MaxTimers) Or Not Timers[H - 1].Used Then
  Begin
    StopTimer := ERROR_TS_HANDLE;
    Exit;
  End;
  Timers[H - 1].Used := False;
  StopTimer := NO_ERROR;
End;

Function DosAsyncTimer(Msec, HSem, PHTimer : LongInt) : LongInt;
Begin
  DosAsyncTimer := NewTimer(Msec, HSem, PHTimer, 0, True);
End;

Function DosStartTimer(Msec, HSem, PHTimer : LongInt) : LongInt;
Begin
  If Msec <= 0 Then DosStartTimer := ERROR_INVALID_PARAMETER
  Else DosStartTimer := NewTimer(Msec, HSem, PHTimer, Msec, True);
End;

Function DosStopTimer(H : LongInt) : LongInt;
Begin
  DosStopTimer := StopTimer(H);
End;

Function DosTimerAsync(Msec, HSem, PHTimer : LongInt) : LongInt;
Begin
  DosTimerAsync := NewTimer(Msec, HSem, PHTimer, 0, False);
End;

Function DosTimerStart(Msec, HSem, PHTimer : LongInt) : LongInt;
Begin
  If Msec <= 0 Then DosTimerStart := ERROR_INVALID_PARAMETER
  Else DosTimerStart := NewTimer(Msec, HSem, PHTimer, Msec, False);
End;

Function DosTimerStop(H : LongInt) : LongInt;
Begin
  DosTimerStop := StopTimer(H);
End;

Function DosSleep(Msec : LongInt) : LongInt;
Var Stop, N : LongInt;
Begin
  PollTimers;
  If Msec > 0 Then
  Begin
    Stop := KGetTickCount + Msec;
    Repeat
      N := Stop - KGetTickCount;
      If N > 50 Then N := 50;
      If N > 0 Then KSleep(N);
      PollTimers;
    Until KGetTickCount - Stop >= 0;
  End;
  DosSleep := NO_ERROR;
End;

{ DATETIME : hours, minutes, seconds, hundredths, day, month (octets),
  year (mot), timezone (mot, minutes), weekday (octet) }
Function DosGetDateTime(P : LongInt) : LongInt;
Var T : Array[0..7] Of Word;
Begin
  KGetLocalTime(LongInt(@T));
  PokeB(P, T[4]);
  PokeB(P + 1, T[5]);
  PokeB(P + 2, T[6]);
  PokeB(P + 3, T[7] Div 10);
  PokeB(P + 4, T[3]);
  PokeB(P + 5, T[1]);
  PokeW(P + 6, T[0]);
  PokeW(P + 8, -300 And $FFFF);     { heure normale de l'Est (Quebec) }
  PokeB(P + 10, T[2]);
  DosGetDateTime := NO_ERROR;
End;

Function DosSetDateTime(P : LongInt) : LongInt;
Var T : Array[0..7] Of Word;
Begin
  If (PeekB(P) > 23) Or (PeekB(P + 1) > 59) Or (PeekB(P + 2) > 59) Or
     (PeekB(P + 4) < 1) Or (PeekB(P + 4) > 31) Or (PeekB(P + 5) < 1) Or
     (PeekB(P + 5) > 12) Or (PeekW(P + 6) < 1980) Or (PeekW(P + 6) > 2079) Then
  Begin
    DosSetDateTime := ERROR_TS_DATETIME;
    Exit;
  End;
  T[0] := PeekW(P + 6); T[1] := PeekB(P + 5); T[2] := PeekB(P + 10);
  T[3] := PeekB(P + 4); T[4] := PeekB(P); T[5] := PeekB(P + 1);
  T[6] := PeekB(P + 2); T[7] := PeekB(P + 3) * 10;
  KSetLocalTime(LongInt(@T));
  DosSetDateTime := NO_ERROR;
End;

{ Minuterie a haute resolution : frequence du 8254 (1 193 167 Hz) }
Function DosTmrQueryFreq(PFreq : LongInt) : LongInt;
Begin
  PokeL(PFreq, 1193167);
  DosTmrQueryFreq := NO_ERROR;
End;

{ QWORD (ulLo, ulHi) : impulsions du 8254 depuis le demarrage }
Function DosTmrQueryTime(PTime : LongInt) : LongInt;
Var Ms, Lo, Hi, Frac : LongInt;
Begin
  Ms := KGetTickCount;
  { Ms * 1193,167 sur 64 bits : Ms * 1193 (MUL 32 x 32 -> 64) + Ms * 167 / 1000 }
  Frac := (Ms Div 1000) * 167 + ((Ms Mod 1000) * 167) Div 1000;
  asm
    mov eax,Ms
    mov ecx,1193
    mul ecx
    mov Lo,eax
    mov Hi,edx
  end;
  { addition 64 bits : retenue si Lo + Frac depasse 2^32 (comparaison non signee) }
  If ((Lo + Frac) Xor $80000000) < (Lo Xor $80000000) Then Inc(Hi);
  Lo := Lo + Frac;
  PokeL(PTime, Lo);
  PokeL(PTime + 4, Hi);
  DosTmrQueryTime := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 11 - Processus et processus legers                            }
{ ==================================================================== }

Const
  MaxPRec   = 16;
  MaxThr    = 32;
  MaxChild  = 32;
  MaxExitL  = 16;

Type
  { Etat par processus (retrouve par son PID) }
  TPRec = Record
    Used      : Boolean;
    Pid       : LongInt;
    Blk       : LongInt;        { TIB (24) + TIB2 (16) + PIB (28) + ligne de commande }
    Stamp     : LongInt;
    ExitN     : LongInt;
    ExitFn    : Array[0..MaxExitL - 1] Of LongInt;
    ExitOrd   : Array[0..MaxExitL - 1] Of LongInt;
    InExit    : Boolean;
    CritSec   : LongInt;
    MustComp  : LongInt;
    Prio      : LongInt;
    PrevFilt  : LongInt;
    FiltOn    : Boolean;
    SigFn     : Array[1..7] Of LongInt;
    SigAct    : Array[1..7] Of LongInt;
    HoldSig   : LongInt;
    SigFocus  : LongInt;
    CpId      : LongInt;        { page de codes du processus }
  End;
  TThr = Record
    Used   : Boolean;
    Pid    : LongInt;
    Tid    : LongInt;
    Fn     : LongInt;
    Param  : LongInt;
    State  : LongInt;           { 0 suspendu, 1 en cours, 2 termine }
    Code   : LongInt;
    Prio   : LongInt;
    Waited : Boolean;
  End;
  TChild = Record
    Used      : Boolean;
    Parent    : LongInt;
    Pid       : LongInt;
    Term      : LongInt;        { codeTerminate }
    Res       : LongInt;        { codeResult }
    Collected : Boolean;
  End;

Var
  PRecs      : Array[0..MaxPRec - 1] Of TPRec;
  Thr        : Array[0..MaxThr - 1] Of TThr;
  Childs     : Array[0..MaxChild - 1] Of TChild;
  StampCnt   : LongInt;
  NextTid    : LongInt;
  CurThread  : LongInt;         { 1 = processus leger principal }
  ThrEsp     : Array[0..15] Of LongInt;
  ThrDepth   : LongInt;
  ThrRet     : LongInt;
  TmpEsp     : LongInt;
  CurCp      : LongInt;

Function CurTid : LongInt;
Begin
  If CurThread < 1 Then CurThread := 1;
  CurTid := CurThread;
End;

{ Construire TIB, TIB2, PIB et la ligne de commande au format OS/2
  (programme#0arguments#0#0) }
Procedure BuildInfoBlocks(P : LongInt);
Var B, Cmd, I, Q : LongInt; S, Prog, Args : String;
Begin
  B := PRecs[P].Blk;
  FillB(B, 512, 0);
  { TIB : pexchain, pstack, pstacklimit, ptib2, version, ordinal }
  PokeL(B, -1);
  PokeL(B + 4, 0);
  PokeL(B + 8, 0);
  PokeL(B + 12, B + 24);
  PokeL(B + 16, 20);
  PokeL(B + 20, 1);
  { TIB2 : tid, priorite, version, MCCount, MCForceFlag }
  PokeL(B + 24, CurTid);
  PokeL(B + 28, PRecs[P].Prio);
  PokeL(B + 32, 20);
  { PIB : pid, ppid, hmte, pchcmd, pchenv, flstatus, type (2 = VIO) }
  PokeL(B + 40, PRecs[P].Pid);
  PokeL(B + 44, KGetParentPid);
  PokeL(B + 48, KGetModuleHandleA(0));
  PokeL(B + 56, KGetEnvironmentStringsA);
  PokeL(B + 60, 0);
  PokeL(B + 64, 2);
  { ligne de commande : programme puis arguments }
  S := GetStr(KGetCommandLineA);
  S := Trim(S);
  If (Length(S) > 0) And (S[1] = '"') Then
  Begin
    Delete(S, 1, 1);
    Q := Pos('"', S);
    If Q = 0 Then Q := Length(S) + 1;
    Prog := Copy(S, 1, Q - 1);
    Args := Trim(Copy(S, Q + 1, 255));
  End
  Else
  Begin
    Q := Pos(' ', S);
    If Q = 0 Then Q := Length(S) + 1;
    Prog := Copy(S, 1, Q - 1);
    Args := Trim(Copy(S, Q + 1, 255));
  End;
  Cmd := B + 128;
  PutStr(Cmd, Prog, 256);
  I := Cmd + Length(Prog) + 1;
  PutStr(I, Args, 256);
  PokeB(I + Length(Args) + 1, 0);
  PokeL(B + 52, Cmd);
End;

{ Etat du processus courant (cree au premier appel) }
Function PRec : LongInt;
Var I, Pid, Old, OldStamp : LongInt;
Begin
  Pid := MyPid;
  Inc(StampCnt);
  For I := 0 To MaxPRec - 1 Do
    If PRecs[I].Used And (PRecs[I].Pid = Pid) Then
    Begin
      PRecs[I].Stamp := StampCnt;
      PRec := I;
      Exit;
    End;
  { nouvelle entree (ou la plus ancienne) }
  Old := 0; OldStamp := $7FFFFFFF;
  For I := 0 To MaxPRec - 1 Do
    If Not PRecs[I].Used Then
    Begin
      Old := I; OldStamp := -1;
    End
    Else If (OldStamp >= 0) And (PRecs[I].Stamp < OldStamp) Then
    Begin
      Old := I; OldStamp := PRecs[I].Stamp;
    End;
  If PRecs[Old].Blk = 0 Then PRecs[Old].Blk := SharedAlloc(1024);
  PRecs[Old].Used := True;
  PRecs[Old].Pid := Pid;
  PRecs[Old].Stamp := StampCnt;
  PRecs[Old].ExitN := 0;
  PRecs[Old].InExit := False;
  PRecs[Old].CritSec := 0;
  PRecs[Old].MustComp := 0;
  PRecs[Old].Prio := $0200;
  PRecs[Old].PrevFilt := 0;
  PRecs[Old].FiltOn := False;
  For I := 1 To 7 Do
  Begin
    PRecs[Old].SigFn[I] := 0;
    PRecs[Old].SigAct[I] := 0;
  End;
  PRecs[Old].HoldSig := 0;
  PRecs[Old].SigFocus := 0;
  PRecs[Old].CpId := CurCp;
  BuildInfoBlocks(Old);
  PRec := Old;
End;

Function DosGetInfoBlocks(PPTib, PPPib : LongInt) : LongInt;
Var P, B : LongInt;
Begin
  P := PRec;
  B := PRecs[P].Blk;
  PokeL(B + 24, CurTid);
  PokeL(PPTib, B);
  PokeL(PPPib, B + 40);
  DosGetInfoBlocks := NO_ERROR;
End;

{ PIDINFO (1.x) : pid, tid, pidParent (mots) }
Function DosGetPID(P : LongInt) : LongInt;
Begin
  PokeW(P, MyPid);
  PokeW(P + 2, CurTid);
  PokeW(P + 4, KGetParentPid);
  DosGetPID := NO_ERROR;
End;

Function DosGetPPID(PidChild, PPidParent : LongInt) : LongInt;
Var I : LongInt;
Begin
  If PidChild = MyPid Then
  Begin
    PokeW(PPidParent, KGetParentPid);
    DosGetPPID := NO_ERROR;
    Exit;
  End;
  For I := 0 To MaxChild - 1 Do
    If Childs[I].Used And (Childs[I].Pid = PidChild) Then
    Begin
      PokeW(PPidParent, Childs[I].Parent);
      DosGetPPID := NO_ERROR;
      Exit;
    End;
  DosGetPPID := ERROR_INVALID_PROCID;
End;

Function DosVerifyPidTid(Pid, Tid : LongInt) : LongInt;
Var I : LongInt;
Begin
  If Pid <> MyPid Then
  Begin
    DosVerifyPidTid := ERROR_INVALID_PROCID;
    Exit;
  End;
  If Tid = 1 Then
  Begin
    DosVerifyPidTid := NO_ERROR;
    Exit;
  End;
  For I := 0 To MaxThr - 1 Do
    If Thr[I].Used And (Thr[I].Pid = Pid) And (Thr[I].Tid = Tid) And (Thr[I].State <> 2) Then
    Begin
      DosVerifyPidTid := NO_ERROR;
      Exit;
    End;
  DosVerifyPidTid := ERROR_INVALID_THREADID;
End;

{ --- Execution des programmes --- }

Function NewChild(Parent, Pid, Term, Res : LongInt) : LongInt;
Var I, J : LongInt;
Begin
  J := -1;
  For I := 0 To MaxChild - 1 Do
    If (J < 0) And (Not Childs[I].Used Or Childs[I].Collected) Then J := I;
  If J < 0 Then J := 0;
  Childs[J].Used := True;
  Childs[J].Parent := Parent;
  Childs[J].Pid := Pid;
  Childs[J].Term := Term;
  Childs[J].Res := Res;
  Childs[J].Collected := False;
  NewChild := J;
End;

{ DosExecPgm : arguments = "programme#0arguments#0#0" ; RESULTCODES =
  codeTerminate, codeResult. Le noyau execute l'enfant jusqu'a sa fin
  (EXEC_SYNC) ; en mode asynchrone codeTerminate rend le PID de l'enfant
  et le resultat est garde pour DosWaitChild. }
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt;
Var Prog, Args, Cmd : String; Code, Term, R, A : LongInt;
Begin
  If (Flags < EXEC_SYNC) Or (Flags > EXEC_ASYNCRESULTDB) Then
  Begin
    DosExecPgm := ERROR_INVALID_FUNCTION;
    Exit;
  End;
  Prog := GetStr(PName);
  Args := '';
  If PArg <> 0 Then
  Begin
    A := PArg + StrLenA(PArg) + 1;      { apres le nom du programme }
    Args := GetStr(A);
  End;
  Cmd := '"' + Prog + '" ' + Args;
  If Flags = EXEC_LOAD Then
  Begin
    { charger sans executer : verifier l'existence du programme }
    If KGetFileAttributesA(PName) = -1 Then
    Begin
      PutStr(PObj, Prog, CbObj);
      DosExecPgm := ERROR_FILE_NOT_FOUND;
    End
    Else
    Begin
      PokeL(PRes, MyPid + 1);
      DosExecPgm := NO_ERROR;
    End;
    Exit;
  End;
  FillB(LongInt(@StartInfo), 68, 0);
  StartInfo[0] := 68;
  FillB(LongInt(@ProcInfo), 16, 0);
  If KCreateProcessA(0, Z(Cmd, 1), 0, 0, 1, 0, 0, 0, LongInt(@StartInfo), LongInt(@ProcInfo)) = 0 Then
  Begin
    R := KErr;
    PutStr(PObj, Prog, CbObj);
    If R = 11 Then R := ERROR_BAD_EXE_FORMAT;
    DosExecPgm := R;
    Exit;
  End;
  Code := 0;
  KGetExitCodeProcess(ProcInfo[0], LongInt(@Code));
  KCloseHandle(ProcInfo[0]);
  If Code = -1 Then Term := TC_TRAP Else Term := TC_EXIT;
  If Flags = EXEC_SYNC Then
  Begin
    PokeL(PRes, Term);
    PokeL(PRes + 4, Code);
  End
  Else
  Begin
    PokeL(PRes, ProcInfo[2]);
    PokeL(PRes + 4, 0);
    NewChild(MyPid, ProcInfo[2], Term, Code);
  End;
  DosExecPgm := NO_ERROR;
End;

Function DosIExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt;
Begin
  DosIExecPgm := DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName);
End;

{ Attendre la fin d'un enfant asynchrone (deja termine dans OS/2-0) }
Function DosWaitChild(Action, Option, PRes, PPid, Pid : LongInt) : LongInt;
Var I, Me : LongInt;
Begin
  If (Action <> DCWA_PROCESS) And (Action <> DCWA_PROCESSTREE) Then
  Begin
    DosWaitChild := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Me := MyPid;
  For I := 0 To MaxChild - 1 Do
    If Childs[I].Used And Not Childs[I].Collected And (Childs[I].Parent = Me) And
       ((Pid = 0) Or (Childs[I].Pid = Pid)) Then
    Begin
      PokeL(PRes, Childs[I].Term);
      PokeL(PRes + 4, Childs[I].Res);
      PokeL(PPid, Childs[I].Pid);
      Childs[I].Collected := True;
      DosWaitChild := NO_ERROR;
      Exit;
    End;
  If Pid <> 0 Then DosWaitChild := ERROR_INVALID_PROCID
  Else DosWaitChild := ERROR_WAIT_NO_CHILDREN;
End;

Function DosCwait(Action, Option, PRes, PPid, Pid : LongInt) : LongInt;
Begin
  DosCwait := DosWaitChild(Action, Option, PRes, PPid, Pid);
End;

{ --- Fin d'un processus et liste de sortie --- }

Procedure RunExitList(Code : LongInt);
Var P, I, J, Best, BestOrd, Fn : LongInt;
Begin
  P := PRec;
  If PRecs[P].InExit Then Exit;
  PRecs[P].InExit := True;
  { par ordre croissant de l'octet d'ordre (EXLST_ADD : bits 8-15) }
  While PRecs[P].ExitN > 0 Do
  Begin
    Best := 0; BestOrd := PRecs[P].ExitOrd[0];
    For I := 1 To PRecs[P].ExitN - 1 Do
      If PRecs[P].ExitOrd[I] < BestOrd Then
      Begin
        Best := I; BestOrd := PRecs[P].ExitOrd[I];
      End;
    Fn := PRecs[P].ExitFn[Best];
    For J := Best To PRecs[P].ExitN - 2 Do
    Begin
      PRecs[P].ExitFn[J] := PRecs[P].ExitFn[J + 1];
      PRecs[P].ExitOrd[J] := PRecs[P].ExitOrd[J + 1];
    End;
    Dec(PRecs[P].ExitN);
    CallPtr1(Fn, Code);
  End;
End;

Function DosExitList(OrderCode, PFn : LongInt) : LongInt;
Var P, I, J, Fn : LongInt;
Begin
  P := PRec;
  Case OrderCode And $FF Of
    EXLST_ADD :
      Begin
        If PRecs[P].ExitN >= MaxExitL Then
        Begin
          DosExitList := ERROR_NOT_ENOUGH_MEMORY;
          Exit;
        End;
        PRecs[P].ExitFn[PRecs[P].ExitN] := PFn;
        PRecs[P].ExitOrd[PRecs[P].ExitN] := (OrderCode Shr 8) And $FF;
        Inc(PRecs[P].ExitN);
      End;
    EXLST_REMOVE :
      Begin
        Fn := -1;
        For I := 0 To PRecs[P].ExitN - 1 Do
          If (Fn < 0) And (PRecs[P].ExitFn[I] = PFn) Then Fn := I;
        If Fn < 0 Then
        Begin
          DosExitList := ERROR_INVALID_FUNCTION;
          Exit;
        End;
        For J := Fn To PRecs[P].ExitN - 2 Do
        Begin
          PRecs[P].ExitFn[J] := PRecs[P].ExitFn[J + 1];
          PRecs[P].ExitOrd[J] := PRecs[P].ExitOrd[J + 1];
        End;
        Dec(PRecs[P].ExitN);
      End;
    EXLST_EXIT :
      If Not PRecs[P].InExit Then
      Begin
        DosExitList := ERROR_INVALID_FUNCTION;
        Exit;
      End;
  Else
    Begin
      DosExitList := ERROR_INVALID_DATA;
      Exit;
    End;
  End;
  DosExitList := NO_ERROR;
End;

{ Retour au point de depart d'un processus leger (DosExit(EXIT_THREAD)) }
Procedure ThreadLongJmp;
Begin
  Dec(ThrDepth);
  TmpEsp := ThrEsp[ThrDepth];
  asm
    mov eax,TmpEsp
    mov esp,eax
    popad
    mov esp,ebp
    pop ebp
    ret
  end;
End;

Procedure ExitProcessNow(Code : LongInt);
Var P : LongInt;
Begin
  RunExitList(TC_EXIT);
  P := PRec;
  PRecs[P].Used := False;
  KExitProcess(Code);
End;

Function DosExit(Action, Result : LongInt) : LongInt;
Begin
  If (Action = EXIT_THREAD) And (ThrDepth > 0) Then
  Begin
    ThrRet := Result;
    ThreadLongJmp;
  End;
  ExitProcessNow(Result);
  DosExit := NO_ERROR;
End;

Function DosKillProcess(Action, Pid : LongInt) : LongInt;
Begin
  If (Action <> 0) And (Action <> 1) Then
  Begin
    DosKillProcess := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If Pid = MyPid Then ExitProcessNow(1);
  DosKillProcess := ERROR_INVALID_PROCID;
End;

{ --- Processus legers --- }

{ Executer la fonction du processus leger ; DosExit(EXIT_THREAD) revient
  ici en restaurant la pile sauvegardee par PUSHAD }
Procedure ThreadCore(F, P : LongInt);
Begin
  asm
    pushad
    mov eax,esp
    mov TmpEsp,eax
  end;
  ThrEsp[ThrDepth] := TmpEsp;
  Inc(ThrDepth);
  ThrRet := CallPtr1(F, P);
  Dec(ThrDepth);
  asm
    popad
  end;
End;

Procedure StartThread(T : LongInt);
Var SaveTid : LongInt;
Begin
  If ThrDepth >= 15 Then Exit;
  SaveTid := CurThread;
  CurThread := Thr[T].Tid;
  Thr[T].State := 1;
  ThreadCore(Thr[T].Fn, Thr[T].Param);
  Thr[T].State := 2;
  Thr[T].Code := ThrRet;
  CurThread := SaveTid;
End;

Function ThrFind(Tid : LongInt) : LongInt;
Var I, Pid : LongInt;
Begin
  ThrFind := -1;
  Pid := MyPid;
  For I := 0 To MaxThr - 1 Do
    If Thr[I].Used And (Thr[I].Pid = Pid) And (Thr[I].Tid = Tid) Then ThrFind := I;
End;

Function DosCreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt;
Var I, T, Pid : LongInt;
Begin
  If PFn = 0 Then
  Begin
    DosCreateThread := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Pid := MyPid;
  T := -1;
  For I := 0 To MaxThr - 1 Do
    If (T < 0) And (Not Thr[I].Used Or ((Thr[I].State = 2) And Thr[I].Waited) Or
       ((Thr[I].Pid <> Pid) And (Thr[I].State = 2))) Then T := I;
  If T < 0 Then
  Begin
    DosCreateThread := ERROR_TOO_MANY_HANDLES;
    Exit;
  End;
  If NextTid < 2 Then NextTid := 2;
  Thr[T].Used := True;
  Thr[T].Pid := Pid;
  Thr[T].Tid := NextTid;
  Inc(NextTid);
  Thr[T].Fn := PFn;
  Thr[T].Param := Param;
  Thr[T].State := 0;
  Thr[T].Code := 0;
  Thr[T].Prio := $0200;
  Thr[T].Waited := False;
  PokeL(PTid, Thr[T].Tid);
  If (Flags And CREATE_SUSPENDED) = 0 Then StartThread(T);
  DosCreateThread := NO_ERROR;
End;

{ DosCreateThread2 : la pile preallouee est ignoree (pile courante) }
Function DosCreateThread2(PTid, PFn, Param, Flags, PStack, CbStack : LongInt) : LongInt;
Begin
  DosCreateThread2 := DosCreateThread(PTid, PFn, Param, Flags, CbStack);
End;

Function DosICreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt;
Begin
  DosICreateThread := DosCreateThread(PTid, PFn, Param, Flags, CbStack);
End;

Function DosResumeThread(Tid : LongInt) : LongInt;
Var T : LongInt;
Begin
  T := ThrFind(Tid);
  If T < 0 Then
  Begin
    DosResumeThread := ERROR_INVALID_THREADID;
    Exit;
  End;
  If Thr[T].State = 0 Then StartThread(T);
  DosResumeThread := NO_ERROR;
End;

Function DosSuspendThread(Tid : LongInt) : LongInt;
Var T : LongInt;
Begin
  T := ThrFind(Tid);
  If (T < 0) Or (Thr[T].State = 2) Then
  Begin
    DosSuspendThread := ERROR_INVALID_THREADID;
    Exit;
  End;
  If Thr[T].State = 1 Then
  Begin
    { le processus leger en cours ne peut pas se suspendre lui-meme ici }
    DosSuspendThread := ERROR_INVALID_THREADID;
    Exit;
  End;
  DosSuspendThread := NO_ERROR;
End;

Function DosKillThread(Tid : LongInt) : LongInt;
Var T : LongInt;
Begin
  If Tid = CurTid Then
  Begin
    DosKillThread := ERROR_INVALID_THREADID;
    Exit;
  End;
  T := ThrFind(Tid);
  If (T < 0) Or (Thr[T].State = 2) Then
  Begin
    DosKillThread := ERROR_INVALID_THREADID;
    Exit;
  End;
  Thr[T].State := 2;
  Thr[T].Code := -1;
  DosKillThread := NO_ERROR;
End;

Function DosWaitThread(PTid, Option : LongInt) : LongInt;
Var I, T, Want : LongInt;
Begin
  Want := PeekL(PTid);
  T := -1;
  If Want = 0 Then
  Begin
    For I := 0 To MaxThr - 1 Do
      If (T < 0) And Thr[I].Used And (Thr[I].Pid = MyPid) And Not Thr[I].Waited Then T := I;
    If T < 0 Then
    Begin
      DosWaitThread := ERROR_INVALID_THREADID;
      Exit;
    End;
  End
  Else
  Begin
    T := ThrFind(Want);
    If (T < 0) Or (Want = CurTid) Then
    Begin
      DosWaitThread := ERROR_INVALID_THREADID;
      Exit;
    End;
  End;
  If Thr[T].State <> 2 Then
  Begin
    If Option = DCWW_NOWAIT Then
    Begin
      DosWaitThread := ERROR_THREAD_NOT_TERMINATED;
      Exit;
    End;
    { attente : un processus leger suspendu est execute jusqu'a sa fin }
    If Thr[T].State = 0 Then StartThread(T);
  End;
  Thr[T].Waited := True;
  PokeL(PTid, Thr[T].Tid);
  DosWaitThread := NO_ERROR;
End;

{ CONTEXTRECORD : drapeaux de contexte puis registres ; un processus
  leger suspendu n'a pas encore de registres (zeros) }
Function DosQueryThreadContext(Tid, Level, PCtx : LongInt) : LongInt;
Var T : LongInt;
Begin
  T := ThrFind(Tid);
  If (T < 0) Or (Thr[T].State <> 0) Then
  Begin
    DosQueryThreadContext := ERROR_INVALID_THREADID;
    Exit;
  End;
  FillB(PCtx + 4, 200, 0);
  PokeL(PCtx, Level);
  DosQueryThreadContext := NO_ERROR;
End;

Function DosEnterCritSec : LongInt;
Var P : LongInt;
Begin
  P := PRec;
  If PRecs[P].CritSec >= 65535 Then
  Begin
    DosEnterCritSec := ERROR_CRITSEC_OVERFLOW;
    Exit;
  End;
  Inc(PRecs[P].CritSec);
  DosEnterCritSec := NO_ERROR;
End;

Function DosExitCritSec : LongInt;
Var P : LongInt;
Begin
  P := PRec;
  If PRecs[P].CritSec <= 0 Then
  Begin
    DosExitCritSec := ERROR_CRITSEC_UNDERFLOW;
    Exit;
  End;
  Dec(PRecs[P].CritSec);
  DosExitCritSec := NO_ERROR;
End;

Function DosEnterMustComplete(PNesting : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := PRec;
  Inc(PRecs[P].MustComp);
  PokeL(PNesting, PRecs[P].MustComp);
  DosEnterMustComplete := NO_ERROR;
End;

Function DosExitMustComplete(PNesting : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := PRec;
  If PRecs[P].MustComp <= 0 Then
  Begin
    DosExitMustComplete := ERROR_INVALID_FUNCTION;
    Exit;
  End;
  Dec(PRecs[P].MustComp);
  PokeL(PNesting, PRecs[P].MustComp);
  DosExitMustComplete := NO_ERROR;
End;

{ Priorites : portee 0 processus, 1 arbre, 2 processus leger ; classe 0
  inchangee, 1 inactive, 2 normale, 3 temps critique, 4 serveur ;
  delta -31..31 }
Function DosSetPriority(Scope, PClass, Delta, Id : LongInt) : LongInt;
Var P, T, V : LongInt;
Begin
  If (Scope < 0) Or (Scope > 2) Then
  Begin
    DosSetPriority := ERROR_INVALID_SCOPE;
    Exit;
  End;
  If (PClass < 0) Or (PClass > 4) Then
  Begin
    DosSetPriority := ERROR_INVALID_PCLASS;
    Exit;
  End;
  If (Delta < -31) Or (Delta > 31) Then
  Begin
    DosSetPriority := ERROR_INVALID_PDELTA;
    Exit;
  End;
  P := PRec;
  If Scope = 2 Then
  Begin
    If (Id = 0) Or (Id = 1) Then V := PRecs[P].Prio
    Else
    Begin
      T := ThrFind(Id);
      If T < 0 Then
      Begin
        DosSetPriority := ERROR_INVALID_THREADID;
        Exit;
      End;
      V := Thr[T].Prio;
    End;
  End
  Else
  Begin
    If (Id <> 0) And (Id <> MyPid) Then
    Begin
      DosSetPriority := ERROR_INVALID_PROCID;
      Exit;
    End;
    V := PRecs[P].Prio;
  End;
  If PClass <> 0 Then V := (PClass Shl 8) Or (V And $FF);
  V := (V And $FF00) Or (((V And $FF) + Delta) And $1F);
  If Scope = 2 Then
  Begin
    If (Id = 0) Or (Id = 1) Then PRecs[P].Prio := V Else Thr[ThrFind(Id)].Prio := V;
  End
  Else
    PRecs[P].Prio := V;
  DosSetPriority := NO_ERROR;
End;

Function DosSetPrty(Scope, PClass, Delta, Id : LongInt) : LongInt;
Begin
  DosSetPrty := DosSetPriority(Scope, PClass, Delta, Id);
End;

Function DosGetPrty(Scope, PPrty, Id : LongInt) : LongInt;
Var P, T : LongInt;
Begin
  P := PRec;
  If Scope = 2 Then
  Begin
    If (Id = 0) Or (Id = 1) Then PokeW(PPrty, PRecs[P].Prio)
    Else
    Begin
      T := ThrFind(Id);
      If T < 0 Then
      Begin
        DosGetPrty := ERROR_INVALID_THREADID;
        Exit;
      End;
      PokeW(PPrty, Thr[T].Prio);
    End;
  End
  Else If (Scope = 0) Or (Scope = 1) Then PokeW(PPrty, PRecs[P].Prio)
  Else
  Begin
    DosGetPrty := ERROR_INVALID_SCOPE;
    Exit;
  End;
  DosGetPrty := NO_ERROR;
End;

{ Un seul processeur : masque d'affinite 1 (MPAFFINITY de 64 bits) }
Function DosQueryThreadAffinity(Scope, PMask : LongInt) : LongInt;
Begin
  PokeL(PMask, 1);
  PokeL(PMask + 4, 0);
  DosQueryThreadAffinity := NO_ERROR;
End;

Function DosSetThreadAffinity(PMask : LongInt) : LongInt;
Begin
  If (PeekL(PMask) And 1) = 0 Then DosSetThreadAffinity := ERROR_INVALID_PARAMETER
  Else DosSetThreadAffinity := NO_ERROR;
End;

Function DosGetProcessorStatus(ProcId, PStatus : LongInt) : LongInt;
Begin
  If ProcId <> 1 Then
  Begin
    DosGetProcessorStatus := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  PokeL(PStatus, 1);          { PROC_ONLINE }
  DosGetProcessorStatus := NO_ERROR;
End;

Function DosSetProcessorStatus(ProcId, Status : LongInt) : LongInt;
Begin
  If (ProcId <> 1) Or (Status <> 1) Then DosSetProcessorStatus := ERROR_INVALID_PARAMETER
  Else DosSetProcessorStatus := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 12 - Exceptions et signaux                                    }
{ ==================================================================== }
{ Les gestionnaires (EXCEPTIONREGISTRATIONRECORD = prev, handler) sont
  chaines depuis TIB.pexchain. Un gestionnaire est appele selon la
  convention _System : handler(pReport, pRegRec, pContext, pDispatch).
  Avec OS2PC, une fonction de rappel a plusieurs parametres les declare
  donc dans l'ordre inverse. Apres une exception materielle, le noyau ne
  peut pas reprendre l'execution : XCPT_CONTINUE_EXECUTION est traite
  comme XCPT_CONTINUE_SEARCH, puis le filtre du runtime (Runtime error N)
  termine le processus. }

Var
  XRep : Array[0..15] Of LongInt;      { EXCEPTIONREPORTRECORD }
  XCtx : Array[0..63] Of LongInt;      { CONTEXTRECORD }

Function ChainHead : LongInt;
Begin
  ChainHead := PeekL(PRecs[PRec].Blk);
End;

Procedure SetChainHead(V : LongInt);
Begin
  PokeL(PRecs[PRec].Blk, V);
End;

{ Appeler les gestionnaires ; vrai si l'un d'eux demande de continuer }
Function DispatchChain(PRep, PCtx : LongInt) : Boolean;
Var R, Rec, Guard : LongInt;
Begin
  DispatchChain := False;
  Rec := ChainHead;
  Guard := 0;
  While (Rec <> 0) And (Rec <> -1) And (Guard < 64) Do
  Begin
    R := CallPtr4(PeekL(Rec + 4), PRep, Rec, PCtx, 0);
    If (R = XCPT_CONTINUE_EXECUTION) And ((PeekL(PRep + 4) And EH_NONCONTINUABLE) = 0) Then
    Begin
      DispatchChain := True;
      Exit;
    End;
    If R = XCPT_CONTINUE_STOP Then Exit;
    Rec := PeekL(Rec);
    Inc(Guard);
  End;
End;

{ Filtre installe dans le noyau (SetUnhandledExceptionFilter) : traduit
  l'EXCEPTION_POINTERS du noyau en EXCEPTIONREPORTRECORD d'OS/2 }
Function ExcDispatch(PExcPtrs : LongInt) : LongInt;
Var Code, Addr, P, Prev : LongInt;
Begin
  Code := PeekL(PeekL(PExcPtrs));
  Addr := PeekL(PeekL(PExcPtrs) + 12);
  If Code = $C0000094 Then Code := XCPT_INTEGER_DIVIDE_BY_ZERO
  Else If Code = $C0000095 Then Code := XCPT_INTEGER_OVERFLOW
  Else If Code = $C000001D Then Code := XCPT_ILLEGAL_INSTRUCTION
  Else If Code = $C0000090 Then Code := XCPT_FLOAT_INVALID_OPERATION;
  FillB(LongInt(@XRep), 64, 0);
  XRep[0] := Code;
  XRep[1] := EH_NONCONTINUABLE;
  XRep[3] := Addr;
  FillB(LongInt(@XCtx), 256, 0);
  XCtx[0] := 7;
  DispatchChain(LongInt(@XRep), LongInt(@XCtx));
  P := PRec;
  Prev := PRecs[P].PrevFilt;
  RunExitList(TC_TRAP);
  If Prev <> 0 Then CallPtr1(Prev, PExcPtrs);
  KExitProcess(-1);
  ExcDispatch := 0;
End;

Procedure HookFilter;
Var P : LongInt;
Begin
  P := PRec;
  If PRecs[P].FiltOn Then Exit;
  PRecs[P].PrevFilt := KSetUnhandledExceptionFilter(LongInt(@ExcDispatch));
  PRecs[P].FiltOn := True;
End;

Function DosSetExceptionHandler(PRegRec : LongInt) : LongInt;
Begin
  If PRegRec = 0 Then
  Begin
    DosSetExceptionHandler := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  HookFilter;
  PokeL(PRegRec, ChainHead);
  SetChainHead(PRegRec);
  DosSetExceptionHandler := NO_ERROR;
End;

Function DosUnsetExceptionHandler(PRegRec : LongInt) : LongInt;
Var Rec, Prev : LongInt;
Begin
  Rec := ChainHead;
  Prev := 0;
  While (Rec <> 0) And (Rec <> -1) Do
  Begin
    If Rec = PRegRec Then
    Begin
      If Prev = 0 Then SetChainHead(PeekL(Rec)) Else PokeL(Prev, PeekL(Rec));
      DosUnsetExceptionHandler := NO_ERROR;
      Exit;
    End;
    Prev := Rec;
    Rec := PeekL(Rec);
  End;
  DosUnsetExceptionHandler := ERROR_INVALID_EXCEPTION_HANDLER;
End;

{ Exception logicielle : les gestionnaires sont appeles ; sans reprise
  le processus se termine (comme une exception non traitee) }
Function DosRaiseException(PExcept : LongInt) : LongInt;
Var S : String; W : LongInt;
Begin
  If PExcept = 0 Then
  Begin
    DosRaiseException := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  FillB(LongInt(@XCtx), 256, 0);
  If DispatchChain(PExcept, LongInt(@XCtx)) Then
  Begin
    DosRaiseException := NO_ERROR;
    Exit;
  End;
  S := CrLf + 'SYS3175: Exception non traitee ' + IStr(PeekL(PExcept)) +
       ' ; le processus est arrete.' + CrLf;
  KWriteFile(KStdOut, Z(S, 0), Length(S), LongInt(@W), 0);
  RunExitList(TC_EXCEPTION);
  KExitProcess(-1);
  DosRaiseException := NO_ERROR;
End;

{ Deroulement : les gestionnaires au-dessus de PHandler (-1 : tous) sont
  appeles avec EH_UNWINDING puis retires de la chaine }
Function DosUnwindException(PHandler, PTargetIP, PReport : LongInt) : LongInt;
Var Rec, Guard : LongInt;
Begin
  If PReport = 0 Then
  Begin
    FillB(LongInt(@XRep), 64, 0);
    XRep[0] := $C0000026;          { XCPT_UNWIND }
    PReport := LongInt(@XRep);
  End;
  PokeL(PReport + 4, PeekL(PReport + 4) Or EH_UNWINDING);
  If PHandler = -1 Then PokeL(PReport + 4, PeekL(PReport + 4) Or EH_EXIT_UNWIND);
  FillB(LongInt(@XCtx), 256, 0);
  Rec := ChainHead;
  Guard := 0;
  While (Rec <> 0) And (Rec <> -1) And (Rec <> PHandler) And (Guard < 64) Do
  Begin
    CallPtr4(PeekL(Rec + 4), PReport, Rec, LongInt(@XCtx), 0);
    Rec := PeekL(Rec);
    SetChainHead(Rec);
    Inc(Guard);
  End;
  DosUnwindException := NO_ERROR;
End;

{ Signaux d'OS/2 2.x : XCPT_SIGNAL avec XCPT_SIGNAL_INTR (Ctrl+C),
  XCPT_SIGNAL_KILLPROC, XCPT_SIGNAL_BREAK (Ctrl+Break) }
Function DosSendSignalException(Pid, Exception : LongInt) : LongInt;
Begin
  If (Exception <> XCPT_SIGNAL_INTR) And (Exception <> XCPT_SIGNAL_BREAK) Then
  Begin
    DosSendSignalException := ERROR_INVALID_FUNCTION;
    Exit;
  End;
  If Pid <> MyPid Then
  Begin
    DosSendSignalException := ERROR_INVALID_PROCID;
    Exit;
  End;
  FillB(LongInt(@XRep), 64, 0);
  XRep[0] := XCPT_SIGNAL;
  XRep[4] := 1;
  XRep[5] := Exception;
  FillB(LongInt(@XCtx), 256, 0);
  If Not DispatchChain(LongInt(@XRep), LongInt(@XCtx)) Then
    ExitProcessNow(1);          { action par defaut : fin du processus }
  DosSendSignalException := NO_ERROR;
End;

Function DosAcknowledgeSignalException(SigNum : LongInt) : LongInt;
Begin
  If (SigNum = XCPT_SIGNAL_INTR) Or (SigNum = XCPT_SIGNAL_KILLPROC) Or
     (SigNum = XCPT_SIGNAL_BREAK) Then DosAcknowledgeSignalException := NO_ERROR
  Else DosAcknowledgeSignalException := ERROR_INVALID_SIGNAL_NUMBER;
End;

Function DosSetSignalExceptionFocus(Flag, PTimes : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := PRec;
  If Flag <> 0 Then Inc(PRecs[P].SigFocus)
  Else If PRecs[P].SigFocus > 0 Then Dec(PRecs[P].SigFocus)
  Else
  Begin
    DosSetSignalExceptionFocus := ERROR_INVALID_FUNCTION;
    Exit;
  End;
  PokeL(PTimes, PRecs[P].SigFocus);
  DosSetSignalExceptionFocus := NO_ERROR;
End;

{ Signaux d'OS/2 1.x : 1 Ctrl+C, 2 tuyau brise, 3 fin du processus,
  4 Ctrl+Break, 5..7 drapeaux A, B, C ; actions 0 defaut, 1 ignorer,
  2 accepter (gestionnaire), 3 erreur pour l'emetteur, 4 acquitter }
Function DosSetSigHandler(PFn, PPrevFn, PPrevAct, Action, SigNum : LongInt) : LongInt;
Var P : LongInt;
Begin
  If (SigNum < 1) Or (SigNum > 7) Then
  Begin
    DosSetSigHandler := ERROR_INVALID_SIGNAL_NUMBER;
    Exit;
  End;
  If (Action < 0) Or (Action > 4) Then
  Begin
    DosSetSigHandler := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  P := PRec;
  PokeL(PPrevFn, PRecs[P].SigFn[SigNum]);
  PokeL(PPrevAct, PRecs[P].SigAct[SigNum]);
  If Action <> 4 Then
  Begin
    PRecs[P].SigAct[SigNum] := Action;
    If Action = 2 Then PRecs[P].SigFn[SigNum] := PFn;
  End;
  DosSetSigHandler := NO_ERROR;
End;

Function DosHoldSignal(Action : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := PRec;
  If Action = 0 Then
  Begin
    If PRecs[P].HoldSig > 0 Then Dec(PRecs[P].HoldSig);
  End
  Else If Action = 1 Then Inc(PRecs[P].HoldSig)
  Else
  Begin
    DosHoldSignal := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  DosHoldSignal := NO_ERROR;
End;

{ Delivrer un signal 1.x au processus courant }
Function Deliver(SigNum, Arg : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := PRec;
  Deliver := NO_ERROR;
  If PRecs[P].HoldSig > 0 Then Exit;
  Case PRecs[P].SigAct[SigNum] Of
    0 : If SigNum <= 4 Then ExitProcessNow(1)
        Else Deliver := ERROR_SIGNAL_REFUSED;
    1 : ;
    2 : CallPtr2(PRecs[P].SigFn[SigNum], Arg, SigNum);
    3 : Deliver := ERROR_SIGNAL_REFUSED;
  End;
End;

Function DosSendSignal(Pid, SigNum : LongInt) : LongInt;
Begin
  If (SigNum <> 1) And (SigNum <> 4) Then
  Begin
    DosSendSignal := ERROR_INVALID_SIGNAL_NUMBER;
    Exit;
  End;
  If Pid <> MyPid Then
  Begin
    DosSendSignal := ERROR_INVALID_PROCID;
    Exit;
  End;
  DosSendSignal := Deliver(SigNum, 0);
End;

Function DosFlagProcess(Pid, Action, FlagNum, Arg : LongInt) : LongInt;
Begin
  If (FlagNum < 0) Or (FlagNum > 2) Then
  Begin
    DosFlagProcess := ERROR_INVALID_FLAG_NUMBER;
    Exit;
  End;
  If Pid <> MyPid Then
  Begin
    DosFlagProcess := ERROR_INVALID_PROCID;
    Exit;
  End;
  DosFlagProcess := Deliver(5 + FlagNum, Arg);
End;

{ Vecteurs d'exceptions 1.x (0 division, 4 debordement, 5 BOUND,
  6 code invalide, 7 coprocesseur absent, 16 erreur du coprocesseur) }
Var
  VecTab : Array[0..16] Of LongInt;

Function DosSetVec(VecNum, PFn, PPrev : LongInt) : LongInt;
Begin
  If (VecNum < 0) Or (VecNum > 16) Or Not ((VecNum = 0) Or (VecNum = 4) Or (VecNum = 5) Or
     (VecNum = 6) Or (VecNum = 7) Or (VecNum = 16)) Then
  Begin
    DosSetVec := ERROR_INVALID_FUNCTION;
    Exit;
  End;
  PokeL(PPrev, VecTab[VecNum]);
  VecTab[VecNum] := PFn;
  DosSetVec := NO_ERROR;
End;

Function DosError(Flag : LongInt) : LongInt;
Begin
  HardErrMode := Flag;
  DosError := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 13 - Modules et ressources                                    }
{ ==================================================================== }
{ HMODULE = adresse de base de l'image : 00400000h pour le programme,
  00C00000h... pour une DLL, 00100000h pour le noyau. }

Var
  ExtLibBegin, ExtLibEnd : String;

Function DosLoadModule(PObj, CbObj, PName, PHmod : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := KLoadLibraryA(PName);
  If H = 0 Then
  Begin
    PutStr(PObj, GetStr(PName), CbObj);
    If KGetLastError = 127 Then DosLoadModule := ERROR_PROC_NOT_FOUND
    Else DosLoadModule := ERROR_MOD_NOT_FOUND;
    Exit;
  End;
  PokeL(PHmod, H);
  DosLoadModule := NO_ERROR;
End;

Function DosFreeModule(H : LongInt) : LongInt;
Begin
  If KFreeLibrary(H) = 0 Then DosFreeModule := ERROR_INVALID_HANDLE
  Else DosFreeModule := NO_ERROR;
End;

{ Par nom (PName <> 0) ou par ordinal }
Function DosQueryProcAddr(H, Ordinal, PName, PPfn : LongInt) : LongInt;
Var A : LongInt;
Begin
  If H = 0 Then H := KGetModuleHandleA(Z('DOSCALLS', 1));
  If PName <> 0 Then A := KGetProcAddress(H, PName)
  Else If (Ordinal > 0) And (Ordinal < 65536) Then A := KGetProcAddress(H, Ordinal)
  Else
  Begin
    DosQueryProcAddr := ERROR_INVALID_ORDINAL;
    Exit;
  End;
  If A = 0 Then
  Begin
    If KGetLastError = 6 Then DosQueryProcAddr := ERROR_INVALID_HANDLE
    Else DosQueryProcAddr := ERROR_PROC_NOT_FOUND;
    Exit;
  End;
  PokeL(PPfn, A);
  DosQueryProcAddr := NO_ERROR;
End;

Function DosGetProcAddr(H, PName, PPfn : LongInt) : LongInt;
Begin
  { 1.x : "#123" designe un ordinal }
  If (PName <> 0) And (PeekB(PName) = Ord('#')) Then
    DosGetProcAddr := DosQueryProcAddr(H, PeekB(PName + 1) - 48, 0, PPfn)
  Else
    DosGetProcAddr := DosQueryProcAddr(H, 0, PName, PPfn);
End;

{ PT_16BIT 0, PT_32BIT 1 : toutes les fonctions sont 32 bits }
Function DosQueryProcType(H, Ordinal, PName, PType : LongInt) : LongInt;
Var A, R : LongInt;
Begin
  R := DosQueryProcAddr(H, Ordinal, PName, LongInt(@A));
  If R = NO_ERROR Then PokeL(PType, 1);
  DosQueryProcType := R;
End;

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := KGetModuleHandleA(PName);
  If H = 0 Then
  Begin
    DosQueryModuleHandle := ERROR_MOD_NOT_FOUND;
    Exit;
  End;
  PokeL(PHmod, H);
  DosQueryModuleHandle := NO_ERROR;
End;

Function DosGetModHandle(PName, PHmod : LongInt) : LongInt;
Begin
  DosGetModHandle := DosQueryModuleHandle(PName, PHmod);
End;

Function DosQueryModuleName(H, Cb, PBuf : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := KGetModuleFileNameA(H, PBuf, Cb);
  If N = 0 Then DosQueryModuleName := ERROR_INVALID_HANDLE
  Else If N >= Cb Then DosQueryModuleName := ERROR_BAD_LENGTH
  Else DosQueryModuleName := NO_ERROR;
End;

Function DosGetModName(H, Cb, PBuf : LongInt) : LongInt;
Begin
  DosGetModName := DosQueryModuleName(H, Cb, PBuf);
End;

{ Module, objet (section) et decalage contenant une adresse }
Function DosQueryModFromEIP(PHmod, PObj, CbBuf, PBuf, POfs, Addr : LongInt) : LongInt;
Var H, Pe, NSec, Sec, I, VA, VS : LongInt; Nm : String;
Begin
  H := KModuleFromAddr(Addr);
  If H = 0 Then
  Begin
    DosQueryModFromEIP := ERROR_INVALID_ADDRESS;
    Exit;
  End;
  PokeL(PHmod, H);
  KGetModuleFileNameA(H, LongInt(@Scratch2), 260);
  Nm := GetStr(LongInt(@Scratch2));
  While Pos('\', Nm) > 0 Do Delete(Nm, 1, Pos('\', Nm));
  If Pos('.', Nm) > 0 Then Nm := Copy(Nm, 1, Pos('.', Nm) - 1);
  PutStr(PBuf, Nm, CbBuf);
  { section PE contenant l'adresse (objets numerotes a partir de 0) }
  Pe := H + PeekL(H + $3C);
  NSec := PeekW(Pe + 6);
  Sec := Pe + 24 + PeekW(Pe + 20);
  PokeL(PObj, 0);
  PokeL(POfs, Addr - H);
  For I := 0 To NSec - 1 Do
  Begin
    VS := PeekL(Sec + I * 40 + 8);
    VA := PeekL(Sec + I * 40 + 12);
    If (Addr >= H + VA) And (Addr < H + VA + VS) Then
    Begin
      PokeL(PObj, I);
      PokeL(POfs, Addr - H - VA);
    End;
  End;
  DosQueryModFromEIP := NO_ERROR;
End;

{ QMOD (1.x) : selecteur de code 16 bits -> module ; dans OS/2-0 le seul
  code est 32 bits (selecteur 08h) : le module rendu est le programme }
Function DosQueryModFromCS(Sel, PQmod : LongInt) : LongInt;
Begin
  If (Sel And $FFF8) <> 8 Then
  Begin
    DosQueryModFromCS := ERROR_INVALID_SEGMENT_NUMBER;
    Exit;
  End;
  PokeL(PQmod, KGetModuleHandleA(0));
  PokeL(PQmod + 4, 1);
  PokeL(PQmod + 8, 0);
  KGetModuleFileNameA(0, PQmod + 12, 260);
  DosQueryModFromCS := NO_ERROR;
End;

{ Ressources : repertoire des ressources de l'image PE (type, nom, langue) }
Function FindRes(H, IdType, IdName : LongInt; Var Addr, Size : LongInt) : Boolean;
Var Pe, Rva, Root, Dir, N, I, E, Id, Ofs, L : LongInt;

  Function Lookup(D, Want : LongInt) : LongInt;
  Var K, Cnt, Ent : LongInt;
  Begin
    Lookup := -1;
    Cnt := PeekW(D + 12) + PeekW(D + 14);
    For K := 0 To Cnt - 1 Do
    Begin
      Ent := D + 16 + K * 8;
      If ((PeekL(Ent) And $80000000) = 0) And ((PeekL(Ent) And $FFFF) = Want) Then
      Begin
        Lookup := PeekL(Ent + 4);
        Exit;
      End;
    End;
  End;

Begin
  FindRes := False;
  If H = 0 Then H := KGetModuleHandleA(0);
  If (H = 0) Or (PeekW(H) <> $5A4D) Then Exit;
  Pe := H + PeekL(H + $3C);
  Rva := PeekL(Pe + 24 + 112);
  If Rva = 0 Then Exit;
  Root := H + Rva;
  Ofs := Lookup(Root, IdType);
  If (Ofs = -1) Or ((Ofs And $80000000) = 0) Then Exit;
  Dir := Root + (Ofs And $7FFFFFFF);
  Ofs := Lookup(Dir, IdName);
  If (Ofs = -1) Or ((Ofs And $80000000) = 0) Then Exit;
  Dir := Root + (Ofs And $7FFFFFFF);
  { premiere langue }
  If PeekW(Dir + 12) + PeekW(Dir + 14) = 0 Then Exit;
  E := Root + PeekL(Dir + 16 + 4);
  Addr := H + PeekL(E);
  Size := PeekL(E + 4);
  FindRes := True;
End;

Function DosGetResource(H, IdType, IdName, PPb : LongInt) : LongInt;
Var A, S : LongInt;
Begin
  If Not FindRes(H, IdType, IdName, A, S) Then
  Begin
    DosGetResource := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  PokeL(PPb, A);
  DosGetResource := NO_ERROR;
End;

Function DosGetResource2(H, IdType, IdName, PPb : LongInt) : LongInt;
Begin
  DosGetResource2 := DosGetResource(H, IdType, IdName, PPb);
End;

Function DosQueryResourceSize(H, IdType, IdName, PSize : LongInt) : LongInt;
Var A, S : LongInt;
Begin
  If Not FindRes(H, IdType, IdName, A, S) Then
  Begin
    DosQueryResourceSize := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  PokeL(PSize, S);
  DosQueryResourceSize := NO_ERROR;
End;

{ Les ressources font partie de l'image : rien a liberer }
Function DosFreeResource(Pb : LongInt) : LongInt;
Begin
  If KModuleFromAddr(Pb) = 0 Then DosFreeResource := ERROR_INVALID_ADDRESS
  Else DosFreeResource := NO_ERROR;
End;

{ Type d'application d'un executable : FAPPTYP_WINDOWCOMPAT (2), DLL
  ($10), DOS ($20) }
Function DosQueryAppType(PName, PFlags : LongInt) : LongInt;
Var H, Got, Lfa, Flags : LongInt; Nm : String;
Begin
  Nm := GetStr(PName);
  If Pos('.', Nm) = 0 Then Nm := Nm + '.EXE';
  H := KCreateFileA(Z(Nm, 0), $80000000, 3, 0, 3, $80, 0);
  If H = -1 Then
  Begin
    DosQueryAppType := ERROR_FILE_NOT_FOUND;
    Exit;
  End;
  Got := 0;
  KReadFile(H, LongInt(@Scratch), 1024, LongInt(@Got), 0);
  KCloseHandle(H);
  If (Got < 64) Or (PeekW(LongInt(@Scratch)) <> $5A4D) Then
  Begin
    DosQueryAppType := ERROR_INVALID_EXE_SIGNATURE;
    Exit;
  End;
  Lfa := PeekL(LongInt(@Scratch) + $3C);
  Flags := $20;                                     { DOS }
  If (Lfa > 0) And (Lfa + 24 < Got) Then
    If PeekL(LongInt(@Scratch) + Lfa) = $00004550 Then
    Begin
      Flags := 2;                                   { fenetre texte (VIO) }
      If (PeekW(LongInt(@Scratch) + Lfa + 22) And $2000) <> 0 Then Flags := Flags Or $10;
    End;
  PokeL(PFlags, Flags);
  DosQueryAppType := NO_ERROR;
End;

Function DosQAppType(PName, PFlags : LongInt) : LongInt;
Begin
  DosQAppType := DosQueryAppType(PName, PFlags);
End;

{ LIBPATH etendu : BEGIN_LIBPATH (1), END_LIBPATH (2) }
Function DosSetExtLIBPATH(PPath, Flags : LongInt) : LongInt;
Begin
  If Flags = 1 Then ExtLibBegin := GetStr(PPath)
  Else If Flags = 2 Then ExtLibEnd := GetStr(PPath)
  Else
  Begin
    DosSetExtLIBPATH := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  DosSetExtLIBPATH := NO_ERROR;
End;

Function DosQueryExtLIBPATH(PPath, Flags : LongInt) : LongInt;
Begin
  If Flags = 1 Then PutStr(PPath, ExtLibBegin, 1024)
  Else If Flags = 2 Then PutStr(PPath, ExtLibEnd, 1024)
  Else
  Begin
    DosQueryExtLIBPATH := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  DosQueryExtLIBPATH := NO_ERROR;
End;

{ Remplacer une DLL : copie de sauvegarde puis copie de la nouvelle }
Function DosReplaceModule(POld, PNew, PBackup : LongInt) : LongInt;
Var R : LongInt;
Begin
  If POld = 0 Then
  Begin
    DosReplaceModule := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If PBackup <> 0 Then
  Begin
    R := DosCopy(POld, PBackup, 1);
    If R <> NO_ERROR Then
    Begin
      DosReplaceModule := R;
      Exit;
    End;
  End;
  If PNew <> 0 Then DosReplaceModule := DosCopy(PNew, POld, 1)
  Else DosReplaceModule := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 14 - Pays, pages de codes, messages et erreurs                }
{ ==================================================================== }

Var
  CtryDefault : LongInt;

{ Remplir COUNTRYINFO (44 octets) pour un pays }
Procedure PutCountry(P, Ctry, Cp : LongInt);
Var DateFmt, CurFmt, TimeFmt, Dec : LongInt; Cur, Th, Dc, DS, TS : String;
Begin
  DateFmt := 1; Cur := '$'; Th := ','; Dc := '.'; DS := '/'; TS := ':';
  CurFmt := 0; TimeFmt := 0; Dec := 2;
  Case Ctry Of
    1  : Begin DateFmt := 0; End;                                  { Etats-Unis }
    2  : Begin DateFmt := 2; Th := ' '; Dc := ','; DS := '-'; CurFmt := 3; TimeFmt := 1; End;
    33 : Begin DateFmt := 1; Cur := 'EUR'; Th := ' '; Dc := ','; DS := '/'; CurFmt := 3; TimeFmt := 1; End;
    32 : Begin DateFmt := 1; Cur := 'EUR'; Th := '.'; Dc := ','; DS := '/'; CurFmt := 3; TimeFmt := 1; End;
    41 : Begin DateFmt := 1; Cur := 'CHF'; Th := ''''; Dc := '.'; DS := '.'; CurFmt := 2; TimeFmt := 1; End;
    49 : Begin DateFmt := 1; Cur := 'EUR'; Th := '.'; Dc := ','; DS := '.'; CurFmt := 3; TimeFmt := 1; End;
    44 : Begin DateFmt := 1; Cur := Chr($9C);   { livre sterling (page 850) } DS := '/'; TimeFmt := 1; End;
    39 : Begin DateFmt := 1; Cur := 'EUR'; Th := '.'; Dc := ','; DS := '/'; CurFmt := 2; TimeFmt := 1; End;
    34 : Begin DateFmt := 1; Cur := 'EUR'; Th := '.'; Dc := ','; DS := '/'; CurFmt := 3; TimeFmt := 1; End;
    61 : Begin DateFmt := 1; End;
  End;
  FillB(P, 44, 0);
  PokeL(P, Ctry);
  PokeL(P + 4, Cp);
  PokeL(P + 8, DateFmt);
  PutStr(P + 12, Cur, 5);
  PutStr(P + 17, Th, 2);
  PutStr(P + 19, Dc, 2);
  PutStr(P + 21, DS, 2);
  PutStr(P + 23, TS, 2);
  PokeB(P + 25, CurFmt);
  PokeB(P + 26, Dec);
  PokeB(P + 27, TimeFmt);
  PutStr(P + 32, ';', 2);
End;

{ Pays connus : 1 Etats-Unis, 2 Canada francais, 32 Belgique, 33 France,
  34 Espagne, 39 Italie, 41 Suisse, 44 Royaume-Uni, 49 Allemagne, 61 Australie }
Function CtryValid(C : LongInt) : Boolean;
Begin
  Case C Of
    1, 2, 32, 33, 34, 39, 41, 44, 49, 61 : CtryValid := True;
  Else
    CtryValid := False;
  End;
End;

{ COUNTRYCODE : country (0 = courant), codepage (0 = courante) }
Function ResolveCountry(Pcc : LongInt; Var Ctry, Cp : LongInt) : LongInt;
Begin
  Ctry := 0; Cp := 0;
  If Pcc <> 0 Then
  Begin
    Ctry := PeekL(Pcc);
    Cp := PeekL(Pcc + 4);
  End;
  If Ctry = 0 Then Ctry := CtryDefault;
  If Cp = 0 Then Cp := CurCp;
  If Not CtryValid(Ctry) Then
  Begin
    ResolveCountry := 396;            { ERROR_NLS_NO_COUNTRY_FILE / pays inconnu }
    Exit;
  End;
  If (Cp <> 437) And (Cp <> 850) And (Cp <> 863) Then
  Begin
    ResolveCountry := ERROR_INVALID_CODE_PAGE;
    Exit;
  End;
  ResolveCountry := NO_ERROR;
End;

Function DosQueryCtryInfo(Cb, Pcc, Pci, PcbActual : LongInt) : LongInt;
Var Ctry, Cp, R, N : LongInt;
Begin
  R := ResolveCountry(Pcc, Ctry, Cp);
  If R <> NO_ERROR Then
  Begin
    DosQueryCtryInfo := R;
    Exit;
  End;
  PutCountry(LongInt(@Scratch2), Ctry, Cp);
  N := 44;
  If Cb < N Then N := Cb;
  MoveB(LongInt(@Scratch2), Pci, N);
  PokeL(PcbActual, N);
  If N < 44 Then DosQueryCtryInfo := ERROR_BUFFER_OVERFLOW Else DosQueryCtryInfo := NO_ERROR;
End;

Function DosGetCtryInfo(Cb, Pcc, Pci, PcbActual : LongInt) : LongInt;
Begin
  DosGetCtryInfo := DosQueryCtryInfo(Cb, Pcc, Pci, PcbActual);
End;

{ Majuscules des lettres accentuees (page de codes 850, et 437/863 :
  lettre sans accent si la majuscule n'existe pas) }
Function UpperChar(C, Cp : LongInt) : LongInt;
Begin
  UpperChar := C;
  If (C >= 97) And (C <= 122) Then
  Begin
    UpperChar := C - 32;
    Exit;
  End;
  If Cp = 850 Then
    Case C Of
      $81 : UpperChar := $9A; $82 : UpperChar := $90; $83 : UpperChar := $B6;
      $84 : UpperChar := $8E; $85 : UpperChar := $B7; $86 : UpperChar := $8F;
      $87 : UpperChar := $80; $88 : UpperChar := $D2; $89 : UpperChar := $D3;
      $8A : UpperChar := $D4; $8B : UpperChar := $D8; $8C : UpperChar := $D7;
      $8D : UpperChar := $DE; $91 : UpperChar := $92; $93 : UpperChar := $E2;
      $94 : UpperChar := $99; $95 : UpperChar := $E3; $96 : UpperChar := $EA;
      $97 : UpperChar := $EB; $98 : UpperChar := $59; $9B : UpperChar := $9D;
      $A0 : UpperChar := $B5; $A1 : UpperChar := $D6; $A2 : UpperChar := $E0;
      $A3 : UpperChar := $E9; $A4 : UpperChar := $A5; $C6 : UpperChar := $C7;
      $D0 : UpperChar := $D1; $E4 : UpperChar := $E5; $E7 : UpperChar := $E8;
      $EC : UpperChar := $ED;
    End
  Else
    Case C Of
      $81 : UpperChar := $9A; $82 : UpperChar := $90; $84 : UpperChar := $8E;
      $86 : UpperChar := $8F; $87 : UpperChar := $80; $91 : UpperChar := $92;
      $94 : UpperChar := $99; $A4 : UpperChar := $A5;
      $83, $85, $A0 : UpperChar := Ord('A');
      $88, $89, $8A : UpperChar := Ord('E');
      $8B, $8C, $8D, $A1 : UpperChar := Ord('I');
      $93, $95, $A2 : UpperChar := Ord('O');
      $96, $97, $A3 : UpperChar := Ord('U');
      $98 : UpperChar := Ord('Y');
    End;
End;

Function DosMapCase(Cb, Pcc, PCh : LongInt) : LongInt;
Var Ctry, Cp, R, I : LongInt;
Begin
  R := ResolveCountry(Pcc, Ctry, Cp);
  If R <> NO_ERROR Then
  Begin
    DosMapCase := R;
    Exit;
  End;
  For I := 0 To Cb - 1 Do PokeB(PCh + I, UpperChar(PeekB(PCh + I), Cp));
  DosMapCase := NO_ERROR;
End;

Function DosCaseMap(Cb, Pcc, PCh : LongInt) : LongInt;
Begin
  DosCaseMap := DosMapCase(Cb, Pcc, PCh);
End;

{ Table de tri (256 octets) : poids = majuscule sans accent }
Function DosQueryCollate(Cb, Pcc, PCh, PcbActual : LongInt) : LongInt;
Var Ctry, Cp, R, I, U, N : LongInt;
Begin
  R := ResolveCountry(Pcc, Ctry, Cp);
  If R <> NO_ERROR Then
  Begin
    DosQueryCollate := R;
    Exit;
  End;
  N := 256;
  If Cb < N Then N := Cb;
  For I := 0 To N - 1 Do
  Begin
    U := UpperChar(I, 437);
    If U >= 128 Then
      Case U Of
        $8E, $8F : U := Ord('A');
        $90 : U := Ord('E');
        $99 : U := Ord('O');
        $9A : U := Ord('U');
        $80 : U := Ord('C');
        $A5 : U := Ord('N');
      End;
    PokeB(PCh + I, U);
  End;
  PokeL(PcbActual, N);
  DosQueryCollate := NO_ERROR;
End;

Function DosGetCollate(Cb, Pcc, PCh, PcbActual : LongInt) : LongInt;
Begin
  DosGetCollate := DosQueryCollate(Cb, Pcc, PCh, PcbActual);
End;

{ Vecteur DBCS : aucune plage de premiers octets (paire 0, 0) }
Function DosQueryDBCSEnv(Cb, Pcc, PBuf : LongInt) : LongInt;
Var Ctry, Cp, R : LongInt;
Begin
  R := ResolveCountry(Pcc, Ctry, Cp);
  If R <> NO_ERROR Then
  Begin
    DosQueryDBCSEnv := R;
    Exit;
  End;
  If Cb < 2 Then
  Begin
    DosQueryDBCSEnv := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  PokeW(PBuf, 0);
  DosQueryDBCSEnv := NO_ERROR;
End;

Function DosGetDBCSEv(Cb, Pcc, PBuf : LongInt) : LongInt;
Begin
  DosGetDBCSEv := DosQueryDBCSEnv(Cb, Pcc, PBuf);
End;

{ Pages de codes : courante puis preparees (850, 437, 863) }
Function DosQueryCp(Cb, PCp, PcbActual : LongInt) : LongInt;
Var N : LongInt;
Begin
  If Cb < 4 Then
  Begin
    DosQueryCp := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  N := 0;
  PokeL(PCp, CurCp); N := 4;
  If Cb >= 8 Then Begin PokeL(PCp + 4, 850); N := 8 End;
  If Cb >= 12 Then Begin PokeL(PCp + 8, 437); N := 12 End;
  If Cb >= 16 Then Begin PokeL(PCp + 12, 863); N := 16 End;
  PokeL(PcbActual, N);
  DosQueryCp := NO_ERROR;
End;

Function DosGetCP(Cb, PCp, PcbActual : LongInt) : LongInt;
Begin
  DosGetCP := DosQueryCp(Cb, PCp, PcbActual);
End;

Function DosSetProcessCp(Cp : LongInt) : LongInt;
Begin
  If (Cp <> 437) And (Cp <> 850) And (Cp <> 863) Then
  Begin
    DosSetProcessCp := ERROR_INVALID_CODE_PAGE;
    Exit;
  End;
  CurCp := Cp;
  PRecs[PRec].CpId := Cp;
  DosSetProcessCp := NO_ERROR;
End;

Function DosSetCP(Cp, Res : LongInt) : LongInt;
Begin
  DosSetCP := DosSetProcessCp(Cp);
End;

Function DosSetProcCP(Cp, Res : LongInt) : LongInt;
Begin
  DosSetProcCP := DosSetProcessCp(Cp);
End;

{ --- Messages --- }

{ --- Messages ---
  DosGetMessage, DosTrueGetMessage, DosInsertMessage, DosInsMessage,
  DosPutMessage, DosQueryMessageCP et DosIQueryMessageCP sont servies par
  MSG.DLL (chargee au premier appel) ; voir MSG.PAS }
Var
  MsgMod  : LongInt;
  MsgFn   : Array[1..9] Of LongInt;      { ordinaux de MSG.DLL }
  MsgNm   : Array[0..15] Of Byte;
  MsgFail : Array[0..31] Of Byte;

Function CallPtr8(F, A1, A2, A3, A4, A5, A6, A7, A8 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A8
    push eax
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
    add esp,32
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPtr8 := R;
End;

{ Fonction Ordinal de MSG.DLL (0 : indisponible) }
Function MsgProc(Ordinal : LongInt) : LongInt;
Var I, A : LongInt; S : String;
Begin
  If MsgMod = 0 Then
  Begin
    S := 'MSG';
    For I := 1 To Length(S) Do MsgNm[I - 1] := Ord(S[I]);
    MsgNm[Length(S)] := 0;
    If DosLoadModule(LongInt(@MsgFail), 32, LongInt(@MsgNm), LongInt(@MsgMod)) <> NO_ERROR Then MsgMod := 0;
    For I := 1 To 9 Do MsgFn[I] := 0;
  End;
  A := 0;
  If MsgMod <> 0 Then
  Begin
    If MsgFn[Ordinal] = 0 Then
      If DosQueryProcAddr(MsgMod, Ordinal, 0, LongInt(@A)) = NO_ERROR Then MsgFn[Ordinal] := A;
    A := MsgFn[Ordinal];
  End;
  MsgProc := A;
End;

Function MsgCall(Ordinal, A1, A2, A3, A4, A5, A6, A7, A8 : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := MsgProc(Ordinal);
  If F = 0 Then MsgCall := ERROR_MR_UN_PERFORM
  Else MsgCall := CallPtr8(F, A1, A2, A3, A4, A5, A6, A7, A8);
End;

Function DosInsertMessage(PTable, CTable, PMsg, CbMsg, PBuf, CbBuf, PcbMsg : LongInt) : LongInt;
Begin
  DosInsertMessage := MsgCall(4, PTable, CTable, PMsg, CbMsg, PBuf, CbBuf, PcbMsg, 0);
End;

Function DosInsMessage(PTable, CTable, PMsg, CbMsg, PBuf, CbBuf, PcbMsg : LongInt) : LongInt;
Begin
  DosInsMessage := MsgCall(4, PTable, CTable, PMsg, CbMsg, PBuf, CbBuf, PcbMsg, 0);
End;

Function DosPutMessage(H, CbMsg, PBuf : LongInt) : LongInt;
Begin
  DosPutMessage := MsgCall(5, H, CbMsg, PBuf, 0, 0, 0, 0, 0);
End;

{ DosTrueGetMessage(table, nb, tampon, taille, numero, fichier, pcbMsg,
  segment de messages) }
Function DosTrueGetMessage(PTable, CTable, PBuf, CbBuf, MsgNum, PFile, PcbMsg, MsgSeg : LongInt) : LongInt;
Begin
  DosTrueGetMessage := MsgCall(6, PTable, CTable, PBuf, CbBuf, MsgNum, PFile, PcbMsg, MsgSeg);
End;

{ DosGetMessage : DosTrueGetMessage sans segment de messages lie }
Function DosGetMessage(PTable, CTable, PBuf, CbBuf, MsgNum, PFile, PcbMsg : LongInt) : LongInt;
Begin
  DosGetMessage := MsgCall(6, PTable, CTable, PBuf, CbBuf, MsgNum, PFile, PcbMsg, 0);
End;

Function DosIQueryMessageCP(PBuf, CbBuf, PFile, PcbBuf, MsgSeg : LongInt) : LongInt;
Begin
  DosIQueryMessageCP := MsgCall(8, PBuf, CbBuf, PFile, PcbBuf, MsgSeg, 0, 0, 0);
End;

{ DosQueryMessageCP : DosIQueryMessageCP sans segment de messages lie }
Function DosQueryMessageCP(PBuf, CbBuf, PFile, PcbBuf : LongInt) : LongInt;
Begin
  DosQueryMessageCP := MsgCall(8, PBuf, CbBuf, PFile, PcbBuf, 0, 0, 0, 0);
End;

{ Classe, action et lieu d'une erreur }
Function DosErrClass(Code, PClass, PAction, PLocus : LongInt) : LongInt;
Var C, A, L : LongInt;
Begin
  C := 13; A := 3; L := 1;               { inconnue, utilisateur, inconnu }
  Case Code Of
    0 : Begin C := 0; A := 0; L := 0; End;
    2, 3, 15, 18, 126, 127, 187, 203 : Begin C := 8; A := 3; L := 2; End;     { introuvable, disque }
    4, 8, 100, 290 : Begin C := 1; A := 4; L := 5; End;                    { ressources, memoire }
    5, 19, 32, 33 : Begin C := 3; A := 3; L := 2; End;                    { autorisation }
    6, 87, 123, 124 : Begin C := 7; A := 4; L := 1; End;                  { erreur de l'application }
    21 : Begin C := 2; A := 1; L := 2; End;                               { temporaire, reessayer }
    109, 231, 232, 233 : Begin C := 2; A := 2; L := 1; End;
    121, 640 : Begin C := 15; A := 1; L := 1; End;                        { delai }
    80, 183, 285, 299, 300 : Begin C := 12; A := 6; L := 1; End;          { deja fait }
    11, 191, 193 : Begin C := 9; A := 4; L := 2; End;                     { mauvais format }
  End;
  PokeL(PClass, C);
  PokeL(PAction, A);
  PokeL(PLocus, L);
  DosErrClass := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 15 - Systeme, peripheriques, moniteurs et VDD                 }
{ ==================================================================== }

Var
  GInfo     : Array[0..31] Of LongInt;     { GINFOSEG }
  LInfo     : Array[0..15] Of LongInt;     { LINFOSEG }
  PopUpMode : LongInt;

{ Secondes depuis le 1er janvier 1970 (heure locale) }
Function DaysBeforeMonth(M : LongInt) : LongInt;
Begin
  Case M Of
    1 : DaysBeforeMonth := 0;    2 : DaysBeforeMonth := 31;   3 : DaysBeforeMonth := 59;
    4 : DaysBeforeMonth := 90;   5 : DaysBeforeMonth := 120;  6 : DaysBeforeMonth := 151;
    7 : DaysBeforeMonth := 181;  8 : DaysBeforeMonth := 212;  9 : DaysBeforeMonth := 243;
    10 : DaysBeforeMonth := 273; 11 : DaysBeforeMonth := 304; 12 : DaysBeforeMonth := 334;
  Else
    DaysBeforeMonth := 0;
  End;
End;

Function UnixTime : LongInt;
Var T : Array[0..7] Of Word; Y, M, Days : LongInt;
Begin
  KGetLocalTime(LongInt(@T));
  Y := T[0]; M := T[1];
  Days := (Y - 1970) * 365 + (Y - 1969) Div 4 + DaysBeforeMonth(M) + T[3] - 1;
  If (M > 2) And ((Y Mod 4) = 0) Then Inc(Days);
  UnixTime := Days * 86400 + T[4] * 3600 + T[5] * 60 + T[6];
End;

Function SysValue(I : LongInt) : LongInt;
Var MS : Array[0..7] Of LongInt;
Begin
  KGlobalMemoryStatus(LongInt(@MS));
  Case I Of
    1  : SysValue := 260;            { QSV_MAX_PATH_LENGTH }
    2  : SysValue := 1;              { QSV_MAX_TEXT_SESSIONS }
    3  : SysValue := 0;              { QSV_MAX_PM_SESSIONS }
    4  : SysValue := 0;              { QSV_MAX_VDM_SESSIONS }
    5  : SysValue := 3;              { QSV_BOOT_DRIVE : C: }
    6  : SysValue := 1;              { QSV_DYN_PRI_VARIATION }
    7  : SysValue := 3;              { QSV_MAX_WAIT }
    8  : SysValue := 32;             { QSV_MIN_SLICE }
    9  : SysValue := 248;            { QSV_MAX_SLICE }
    10 : SysValue := 4096;           { QSV_PAGE_SIZE }
    11 : SysValue := OS2Major;       { QSV_VERSION_MAJOR }
    12 : SysValue := OS2Minor;       { QSV_VERSION_MINOR }
    13 : SysValue := 0;              { QSV_VERSION_REVISION }
    14 : SysValue := KGetTickCount;  { QSV_MS_COUNT }
    15 : SysValue := UnixTime;       { QSV_TIME_LOW }
    16 : SysValue := 0;              { QSV_TIME_HIGH }
    17 : SysValue := MS[2];          { QSV_TOTPHYSMEM }
    18 : SysValue := MS[2] - MS[3];  { QSV_TOTRESMEM }
    19 : SysValue := MS[3];          { QSV_TOTAVAILMEM }
    20 : SysValue := MS[6];          { QSV_MAXPRMEM }
    21 : SysValue := MS[7];          { QSV_MAXSHMEM }
    22 : SysValue := 100;            { QSV_TIMER_INTERVAL : 10,0 ms }
    23 : SysValue := 255;            { QSV_MAX_COMP_LENGTH }
    24 : SysValue := 1;              { QSV_FOREGROUND_FS_SESSION }
    25 : SysValue := MyPid;          { QSV_FOREGROUND_PROCESS }
    26 : SysValue := 1;              { QSV_NUMPROCESSORS }
  Else
    SysValue := 0;
  End;
End;

Function DosQuerySysInfo(IStart, ILast, PBuf, CbBuf : LongInt) : LongInt;
Var I : LongInt;
Begin
  If (IStart < 1) Or (ILast > QSV_MAX) Or (IStart > ILast) Then
  Begin
    DosQuerySysInfo := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If CbBuf < (ILast - IStart + 1) * 4 Then
  Begin
    DosQuerySysInfo := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  For I := IStart To ILast Do PokeL(PBuf + (I - IStart) * 4, SysValue(I));
  DosQuerySysInfo := NO_ERROR;
End;

{ 1.x : index 0 = longueur maximale d'un chemin }
Function DosQSysInfo(Index, PBuf, Cb : LongInt) : LongInt;
Begin
  If Index <> 0 Then
  Begin
    DosQSysInfo := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If Cb < 2 Then
  Begin
    DosQSysInfo := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  PokeW(PBuf, 260);
  DosQSysInfo := NO_ERROR;
End;

{ Version : octet haut majeure, octet bas mineure (20.00 = OS/2 2.x) }
Function DosGetVersion(PVer : LongInt) : LongInt;
Begin
  PokeW(PVer, (OS2Major Shl 8) Or OS2Minor);
  DosGetVersion := NO_ERROR;
End;

Function DosGetMachineMode(PMode : LongInt) : LongInt;
Begin
  PokeB(PMode, 1);            { MODE_PROTECTED }
  DosGetMachineMode := NO_ERROR;
End;

{ Segments d'information globale et locale (1.x) : leurs adresses
  lineaires sont rendues a la place des selecteurs }
Function DosGetInfoSeg(PSelGlobal, PSelLocal : LongInt) : LongInt;
Var G, L : LongInt; T : Array[0..7] Of Word; Env : LongInt;
Begin
  G := LongInt(@GInfo);
  L := LongInt(@LInfo);
  FillB(G, 128, 0);
  FillB(L, 64, 0);
  KGetLocalTime(LongInt(@T));
  PokeL(G, UnixTime);
  PokeL(G + 4, KGetTickCount);
  PokeB(G + 8, T[4]); PokeB(G + 9, T[5]); PokeB(G + 10, T[6]); PokeB(G + 11, T[7] Div 10);
  PokeW(G + 12, 300);
  PokeW(G + 14, 100);
  PokeB(G + 16, T[3]); PokeB(G + 17, T[1]); PokeW(G + 18, T[0]); PokeB(G + 20, T[2]);
  PokeB(G + 21, OS2Major); PokeB(G + 22, OS2Minor);
  PokeB(G + 24, 1); PokeB(G + 25, 1); PokeB(G + 26, 3); PokeB(G + 27, 1);
  PokeW(G + 28, MyPid);
  PokeB(G + 30, 1); PokeB(G + 31, 3);
  PokeW(G + 32, 32); PokeW(G + 34, 248); PokeW(G + 36, 3);
  PokeW(L, MyPid);
  PokeW(L + 2, KGetParentPid);
  PokeW(L + 4, PRecs[PRec].Prio);
  PokeW(L + 6, CurTid);
  PokeW(L + 8, 1);
  PokeW(L + 12, 1);
  PokeB(L + 14, 2);
  Env := KGetEnvironmentStringsA;
  PokeW(L + 16, Env And $FFFF);
  PokeW(L + 18, 0);
  PokeW(L + 26, 0);
  PokeL(PSelGlobal, G);
  PokeL(PSelLocal, L);
  DosGetInfoSeg := NO_ERROR;
End;

{ 1.x : environnement et ligne de commande (adresses lineaires) }
Function DosGetEnv(PSelEnv, POffsetCmd : LongInt) : LongInt;
Begin
  PokeL(PSelEnv, KGetEnvironmentStringsA);
  PokeL(POffsetCmd, PeekL(PRecs[PRec].Blk + 52));
  DosGetEnv := NO_ERROR;
End;

Function DosQueryVerify(PFlag : LongInt) : LongInt;
Begin
  PokeL(PFlag, Verify);
  DosQueryVerify := NO_ERROR;
End;

Function DosQVerify(PFlag : LongInt) : LongInt;
Begin
  DosQVerify := DosQueryVerify(PFlag);
End;

Function DosSetVerify(Flag : LongInt) : LongInt;
Begin
  If (Flag <> 0) And (Flag <> 1) Then
  Begin
    DosSetVerify := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Verify := Flag;
  DosSetVerify := NO_ERROR;
End;

{ Configuration : 0 imprimantes, 1 ports serie, 2 lecteurs de disquettes,
  3 coprocesseur, 4 sous-modele, 5 modele, 6 adaptateur d'ecran }
Function DosDevConfig(PInfo, Item : LongInt) : LongInt;
Begin
  Case Item Of
    0 : PokeB(PInfo, 0);
    1 : PokeB(PInfo, 1);
    2 : PokeB(PInfo, 0);
    3 : PokeB(PInfo, 1);
    4 : PokeB(PInfo, 0);
    5 : PokeB(PInfo, $F8);
    6 : PokeB(PInfo, 1);
  Else
    Begin
      DosDevConfig := ERROR_INVALID_PARAMETER;
      Exit;
    End;
  End;
  DosDevConfig := NO_ERROR;
End;

{ KBDKEYINFO (10 octets) a partir d'un INPUT_RECORD du noyau }
Procedure KeyInfoFrom(PRec, PKi : LongInt);
Begin
  PokeB(PKi, PeekB(PRec + 14));
  PokeB(PKi + 1, PeekB(PRec + 12));
  PokeB(PKi + 2, $40);
  PokeB(PKi + 3, 0);
  PokeW(PKi + 4, PeekL(PRec + 16) And $FFFF);
  PokeL(PKi + 6, KGetTickCount);
End;

Function DosDevIOCtl(H, Category, Func, PParm, CbParmMax, PcbParm, PData, CbDataMax, PcbData : LongInt) : LongInt;
Var InRec : Array[0..4] Of LongInt; N : LongInt;
Begin
  If Not HValid(H) Then
  Begin
    DosDevIOCtl := ERROR_INVALID_HANDLE;
    Exit;
  End;
  DosDevIOCtl := NO_ERROR;
  Case Category Of
    $01 : { IOCTL_ASYNC }
      Case Func Of
        $41, $42, $43, $44, $45, $46, $47, $48 : ;
        $61 : Begin PokeW(PData, 9600); PokeL(PcbData, 2); End;     { vitesse }
        $62 : Begin PokeB(PData, 8); PokeB(PData + 1, 0); PokeB(PData + 2, 0); PokeL(PcbData, 3); End;
      Else
        DosDevIOCtl := ERROR_BAD_COMMAND;
      End;
    $04 : { IOCTL_KEYBOARD }
      Case Func Of
        $51, $53, $54, $56, $5C, $5D : ;
        $71 : Begin PokeB(PData, 0); PokeL(PcbData, 1); End;       { mode ASCII }
        $73 : Begin FillB(PData, 6, 0); PokeL(PcbData, 6); End;    { SHIFTSTATE }
        $74 : Begin                                                 { lire un caractere }
                KReadConsoleInputA(KStdIn, LongInt(@InRec), 1, LongInt(@N));
                KeyInfoFrom(LongInt(@InRec), PData);
                PokeL(PcbData, 10);
              End;
        $75 : Begin                                                 { examiner }
                N := 0;
                KPeekConsoleInputA(KStdIn, LongInt(@InRec), 1, LongInt(@N));
                If N > 0 Then KeyInfoFrom(LongInt(@InRec), PData) Else FillB(PData, 10, 0);
                PokeL(PcbData, 10);
              End;
        $7B : Begin PokeW(PData, CurCp); PokeL(PcbData, 2); End;   { page de codes }
      Else
        DosDevIOCtl := ERROR_BAD_COMMAND;
      End;
    $05 : { IOCTL_PRINTER : aucune imprimante }
      If Func = $66 Then
      Begin
        PokeB(PData, $08);            { erreur d'E/S }
        PokeL(PcbData, 1);
      End
      Else DosDevIOCtl := ERROR_NOT_READY;
    $08 : { IOCTL_DISK }
      Case Func Of
        $00, $01 : ;                                                { verrouiller }
        $02 : DosDevIOCtl := ERROR_ACCESS_DENIED;                   { ejecter }
        $20 : Begin PokeB(PData, 0); PokeL(PcbData, 1); End;       { amovible }
        $63 : Begin                                                 { BIOSPARAMETERBLOCK }
                FillB(PData, 36, 0);
                PokeW(PData, 2048);       { octets par secteur }
                PokeB(PData + 2, 1);      { secteurs par unite d'allocation }
                PokeB(PData + 5, 0);      { FAT : aucune }
                PokeB(PData + 10, $F0);   { support }
                PokeB(PData + 31, 7);     { type d'unite : CD-ROM (autre) }
                PokeW(PData + 32, 1);     { amovible }
                PokeL(PcbData, 36);
              End;
      Else
        DosDevIOCtl := ERROR_BAD_COMMAND;
      End;
    $0B : { IOCTL_GENERAL }
      Case Func Of
        $01, $02, $41, $60 : ;
      Else
        DosDevIOCtl := ERROR_BAD_COMMAND;
      End;
  Else
    DosDevIOCtl := ERROR_INVALID_CATEGORY;
  End;
End;

{ 1.x : (donnees, parametres, fonction, categorie, handle) }
Function DosDevIOCtl2(PData, CbData, PParm, CbParm, Func, Category, H : LongInt) : LongInt;
Var N1, N2 : LongInt;
Begin
  DosDevIOCtl2 := DosDevIOCtl(H, Category, Func, PParm, CbParm, LongInt(@N1), PData, CbData, LongInt(@N2));
End;

{ Disques physiques partitionnables : aucun (CD-ROM seulement) }
Function DosPhysicalDisk(Func, PBuf, CbBuf, PParms, CbParms : LongInt) : LongInt;
Begin
  Case Func Of
    1 : Begin                          { INFO_COUNT_PARTITIONABLE_DISKS }
          If CbBuf < 2 Then
          Begin
            DosPhysicalDisk := ERROR_BUFFER_OVERFLOW;
            Exit;
          End;
          PokeW(PBuf, 0);
          DosPhysicalDisk := NO_ERROR;
        End;
    2, 3 : DosPhysicalDisk := ERROR_INVALID_PARAMETER;   { pas de disque n }
  Else
    DosPhysicalDisk := ERROR_INVALID_FUNCTION;
  End;
End;

{ Les programmes s'executent en anneau 0 : E/S et CLI/STI sont permis }
Function DosPortAccess(Res, TypeOfAccess, FirstPort, LastPort : LongInt) : LongInt;
Begin
  If (FirstPort < 0) Or (LastPort > $FFFF) Or (FirstPort > LastPort) Or
     ((TypeOfAccess <> 0) And (TypeOfAccess <> 1)) Then
    DosPortAccess := ERROR_INVALID_PARAMETER
  Else
    DosPortAccess := NO_ERROR;
End;

Function DosCLIAccess : LongInt;
Begin
  DosCLIAccess := NO_ERROR;
End;

Function DosCallBack(PFn : LongInt) : LongInt;
Begin
  If PFn = 0 Then
  Begin
    DosCallBack := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  DosCallBack := CallPtr0(PFn);
End;

{ Indicateurs ABIOS : aucun ABIOS (machine compatible PC AT) }
Function DosQueryABIOSSupport(Reserved : LongInt) : LongInt;
Begin
  DosQueryABIOSSupport := 0;
End;

{ Mesures de performances : CMD_KI_RDCNT ($63) remplit CPUUTIL }
Function DosPerfSysCall(Cmd, P1, P2, P3 : LongInt) : LongInt;
Var T : Array[0..1] Of LongInt;
Begin
  Case Cmd Of
    $63 : Begin
            DosTmrQueryTime(LongInt(@T));
            PokeL(P1, T[0]); PokeL(P1 + 4, T[1]);        { temps }
            PokeL(P1 + 8, 0); PokeL(P1 + 12, 0);         { inactif }
            PokeL(P1 + 16, T[0]); PokeL(P1 + 20, T[1]);  { occupe }
            PokeL(P1 + 24, 0); PokeL(P1 + 28, 0);        { interruptions }
            DosPerfSysCall := NO_ERROR;
          End;
    $41 : Begin PokeL(P1, 1); DosPerfSysCall := NO_ERROR; End;   { processeurs }
    $14, $60, $61 : DosPerfSysCall := NO_ERROR;
  Else
    DosPerfSysCall := ERROR_INVALID_FUNCTION;
  End;
End;

Function DosBeep(Freq, Duration : LongInt) : LongInt;
Begin
  If (Freq < $25) Or (Freq > $7FFF) Then
  Begin
    DosBeep := 395;              { ERROR_INVALID_FREQUENCY }
    Exit;
  End;
  KBeep(Freq, Duration);
  DosBeep := NO_ERROR;
End;

{ --- Moniteurs de peripheriques ---
  DosMonOpen, DosMonReg, DosMonRead, DosMonWrite et DosMonClose sont
  servis par MONCALLS.DLL (chargee au premier appel) ; voir MONCALLS.PAS }
Var
  MonMod  : LongInt;
  MonFn   : Array[1..5] Of LongInt;      { ordinaux de MONCALLS.DLL }
  MonName : Array[0..15] Of Byte;
  MonFail : Array[0..31] Of Byte;

{ Adresse de la fonction Ordinal de MONCALLS.DLL (0 : indisponible) }
Function MonProc(Ordinal : LongInt) : LongInt;
Var I, F, A : LongInt; S : String;
Begin
  If MonMod = 0 Then
  Begin
    S := 'MONCALLS';
    For I := 1 To Length(S) Do MonName[I - 1] := Ord(S[I]);
    MonName[Length(S)] := 0;
    If DosLoadModule(LongInt(@MonFail), 32, LongInt(@MonName), LongInt(@MonMod)) <> NO_ERROR Then MonMod := 0;
    For I := 1 To 5 Do MonFn[I] := 0;
  End;
  F := 0;
  If MonMod <> 0 Then
  Begin
    If MonFn[Ordinal] = 0 Then
    Begin
      A := 0;
      If DosQueryProcAddr(MonMod, Ordinal, 0, LongInt(@A)) = NO_ERROR Then MonFn[Ordinal] := A;
    End;
    F := MonFn[Ordinal];
  End;
  MonProc := F;
End;

Function MonCall(Ordinal, A1, A2, A3, A4, A5 : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := MonProc(Ordinal);
  If F = 0 Then MonCall := ERROR_INVALID_FUNCTION
  Else MonCall := CallPtr5(F, A1, A2, A3, A4, A5);
End;

Function DosMonOpen(PDev, PHMon : LongInt) : LongInt;
Begin
  DosMonOpen := MonCall(4, PDev, PHMon, 0, 0, 0);
End;

Function DosMonClose(HMon : LongInt) : LongInt;
Begin
  DosMonClose := MonCall(3, HMon, 0, 0, 0, 0);
End;

Function DosMonReg(HMon, PInBuf, POutBuf, PosFlag, Index : LongInt) : LongInt;
Begin
  DosMonReg := MonCall(5, HMon, PInBuf, POutBuf, PosFlag, Index);
End;

Function DosMonRead(PInBuf, WaitFlag, PData, PcbData : LongInt) : LongInt;
Begin
  DosMonRead := MonCall(2, PInBuf, WaitFlag, PData, PcbData, 0);
End;

Function DosMonWrite(POutBuf, PData, CbData : LongInt) : LongInt;
Begin
  DosMonWrite := MonCall(1, POutBuf, PData, CbData, 0, 0);
End;

{ --- Pilotes de peripheriques virtuels : aucune session DOS virtuelle --- }

Function DosOpenVDD(PName, PHvdd : LongInt) : LongInt;
Begin
  PokeL(PHvdd, 0);
  If GetStr(PName) = '' Then DosOpenVDD := ERROR_INVALID_PARAMETER
  Else DosOpenVDD := ERROR_VDD_NOT_FOUND;
End;

Function DosRequestVDD(HVdd, SGid, Cmd, CbIn, PIn, CbOut, POut : LongInt) : LongInt;
Begin
  DosRequestVDD := ERROR_INVALID_HANDLE;
End;

Function DosCloseVDD(HVdd : LongInt) : LongInt;
Begin
  DosCloseVDD := ERROR_INVALID_HANDLE;
End;

{ ==================================================================== }
{ Partie 16 - Fonctions internes et diverses                           }
{ ==================================================================== }

Var
  ShutDone : Boolean;

Function DosShutdown(Reserved : LongInt) : LongInt;
Var I : LongInt;
Begin
  If Reserved <> 0 Then
  Begin
    DosShutdown := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  For I := 3 To MaxH - 1 Do
    If (Hd[I].Kind = HK_FILE) And (Hd[I].Owner = MyPid) Then KFlushFileBuffers(Hd[I].KH);
  ShutDone := True;
  DosShutdown := NO_ERROR;
End;

{ Ecrire une ligne de texte dans un fichier du noyau }
Procedure WLine(KH : LongInt; S : String);
Var W : LongInt;
Begin
  S := S + CrLf;
  KWriteFile(KH, Z(S, 1), Length(S), LongInt(@W), 0);
End;

{ Vidage d'un processus : C:\PDUMP.nnn (texte : processus, handles,
  memoire, segments) }
Function WriteDump(Name : String; Pid : LongInt) : LongInt;
Var KH, I : LongInt;
Begin
  KH := KCreateFileA(Z(Name, 0), $40000000, 0, 0, 2, $80, 0);
  If KH = -1 Then
  Begin
    WriteDump := KErr;
    Exit;
  End;
  WLine(KH, 'OS/2-0 - vidage du processus ' + IStr(Pid));
  WLine(KH, 'Processus parent : ' + IStr(KGetParentPid));
  WLine(KH, 'Ligne de commande : ' + GetStr(KGetCommandLineA));
  WLine(KH, 'Handles ouverts :');
  For I := 0 To MaxH - 1 Do
    If (Hd[I].Kind <> HK_FREE) And (Hd[I].Owner = Pid) Then
      WLine(KH, '  ' + IStr(I) + ' type ' + IStr(Hd[I].Kind) + ' ' + Hd[I].Path);
  WLine(KH, 'Objets memoire :');
  For I := 0 To MaxMem - 1 Do
    If MemObjs[I].Used And (MemObjs[I].Owner = Pid) Then
      WLine(KH, '  base ' + IStr(MemObjs[I].Base) + ' taille ' + IStr(MemObjs[I].Size) +
                ' ' + MemObjs[I].Name);
  WLine(KH, 'Segments :');
  For I := 1 To MaxSegs - 1 Do
    If Segs[I].Used And (Segs[I].Owner = Pid) Then
      WLine(KH, '  selecteur ' + IStr((I Shl 3) Or 7) + ' base ' + IStr(Segs[I].Base) +
                ' taille ' + IStr(Segs[I].Size));
  KCloseHandle(KH);
  WriteDump := NO_ERROR;
End;

Var
  DumpEnabled : Boolean;
  DumpSeq     : LongInt;

{ Flag : 0 desactiver, 1 activer, 2 effectuer le vidage maintenant }
Function DosDumpProcess(Flag, Drive, Pid : LongInt) : LongInt;
Var S : String;
Begin
  Case Flag Of
    0 : DumpEnabled := False;
    1 : DumpEnabled := True;
    2 : Begin
          If (Pid <> 0) And (Pid <> MyPid) Then
          Begin
            DosDumpProcess := ERROR_INVALID_PROCID;
            Exit;
          End;
          Inc(DumpSeq);
          S := IStr(DumpSeq);
          While Length(S) < 3 Do S := '0' + S;
          DosDumpProcess := WriteDump('C:\PDUMP.' + S, MyPid);
          Exit;
        End;
  Else
    Begin
      DosDumpProcess := ERROR_INVALID_PARAMETER;
      Exit;
    End;
  End;
  DosDumpProcess := NO_ERROR;
End;

Function DosForceSystemDump(Reserved : LongInt) : LongInt;
Begin
  DosForceSystemDump := WriteDump('C:\SYSDUMP.TXT', MyPid);
End;

{ Debogage : le noyau n'execute qu'un processus a la fois, un processus
  ne peut donc pas en controler un autre. uDB : Pid, Tid, Cmd, Value... ;
  la reponse est DBG_N_Error (-1) avec le code d'erreur dans Value. }
Function DosDebug(PDbg : LongInt) : LongInt;
Begin
  If PDbg = 0 Then
  Begin
    DosDebug := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  PokeL(PDbg + 8, -1);
  PokeL(PDbg + 12, ERROR_INVALID_PROCID);
  DosDebug := NO_ERROR;
End;

{ PTRACEBUF (1.x) : pid, tid, cmd, value (mots) }
Function DosPtrace(PBuf : LongInt) : LongInt;
Begin
  If PBuf = 0 Then
  Begin
    DosPtrace := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  PokeW(PBuf + 4, $FFFF);
  PokeW(PBuf + 6, ERROR_INVALID_PROCID);
  DosPtrace := ERROR_INVALID_PROCID;
End;

{ Trace systeme : enregistrement memorise (dernier evenement) }
Var
  TraceMajor, TraceMinor, TraceLen : LongInt;

Function DosSysTrace(Major, Cb, Minor, PData : LongInt) : LongInt;
Begin
  If (Major < 0) Or (Major > 255) Then
  Begin
    DosSysTrace := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  TraceMajor := Major; TraceMinor := Minor; TraceLen := Cb;
  DosSysTrace := NO_ERROR;
End;

{ Service 1 : figer les autres processus legers du processus (un seul
  s'execute : sans effet) ; service 2 : les liberer }
Function DosSystemService(Service, PParm, PData : LongInt) : LongInt;
Begin
  If (Service = 1) Or (Service = 2) Then DosSystemService := NO_ERROR
  Else DosSystemService := ERROR_INVALID_FUNCTION;
End;

{ SPU_DISABLESUPPRESSION 0, SPU_ENABLESUPPRESSION 1 (journal POPUPLOG.OS2) }
Function DosSuppressPopUps(Flag, Drive : LongInt) : LongInt;
Begin
  If (Flag <> 0) And (Flag <> 1) Then
  Begin
    DosSuppressPopUps := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  PopUpMode := Flag;
  DosSuppressPopUps := NO_ERROR;
End;

{ Points d'entree internes }
Function DosIRead(H, Buf, Cb, PActual : LongInt) : LongInt;
Begin
  DosIRead := DosRead(H, Buf, Cb, PActual);
End;

Function DosIWrite(H, Buf, Cb, PActual : LongInt) : LongInt;
Begin
  DosIWrite := DosWrite(H, Buf, Cb, PActual);
End;

Function DosISemRequest(H, Timeout : LongInt) : LongInt;
Begin
  DosISemRequest := DosSemRequest(H, Timeout);
End;

Function DosISemWait(H, Timeout : LongInt) : LongInt;
Begin
  DosISemWait := DosSemWait(H, Timeout);
End;

Function DosISysSemClear(H : LongInt) : LongInt;
Begin
  DosISysSemClear := DosSemClear(H);
End;

Function DosISysSemSet(H : LongInt) : LongInt;
Begin
  DosISysSemSet := DosSemSet(H);
End;

{ --- Versions DosProtect* (handle protege par un identificateur de
  verrou rendu a l'ouverture) --- }

Function CheckLock(H, LockId : LongInt) : Boolean;
Begin
  CheckLock := HValid(H) And ((Hd[H].LockId = 0) Or (Hd[H].LockId = LockId));
End;

Function DosProtectOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2, PLockId : LongInt) : LongInt;
Var R, H : LongInt;
Begin
  R := OpenFile(PName, PHf, PAction, CbFile, Attr, Flags, Mode);
  If R = NO_ERROR Then
  Begin
    H := PeekL(PHf);
    Inc(NextLock);
    Hd[H].LockId := NextLock;
    PokeL(PLockId, NextLock);
  End;
  DosProtectOpen := R;
End;

Function DosProtectOpenL(PName, PHf, PAction, CbLo, CbHi, Attr, Flags, Mode, PEaop2, PLockId : LongInt) : LongInt;
Begin
  If CbHi <> 0 Then DosProtectOpenL := ERROR_INVALID_PARAMETER
  Else DosProtectOpenL := DosProtectOpen(PName, PHf, PAction, CbLo, Attr, Flags, Mode, PEaop2, PLockId);
End;

Function DosProtectClose(H, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectClose := ERROR_INVALID_HANDLE
  Else DosProtectClose := DosClose(H);
End;

Function DosProtectRead(H, Buf, Cb, PActual, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectRead := ERROR_INVALID_HANDLE
  Else DosProtectRead := DosRead(H, Buf, Cb, PActual);
End;

Function DosProtectWrite(H, Buf, Cb, PActual, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectWrite := ERROR_INVALID_HANDLE
  Else DosProtectWrite := DosWrite(H, Buf, Cb, PActual);
End;

Function DosProtectSetFilePtr(H, Ib, Method, PActual, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectSetFilePtr := ERROR_INVALID_HANDLE
  Else DosProtectSetFilePtr := DosSetFilePtr(H, Ib, Method, PActual);
End;

Function DosProtectSetFilePtrL(H, IbLo, IbHi, Method, PActual, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectSetFilePtrL := ERROR_INVALID_HANDLE
  Else DosProtectSetFilePtrL := DosSetFilePtrL(H, IbLo, IbHi, Method, PActual);
End;

Function DosProtectSetFileSize(H, Cb, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectSetFileSize := ERROR_INVALID_HANDLE
  Else DosProtectSetFileSize := DosSetFileSize(H, Cb);
End;

Function DosProtectSetFileSizeL(H, CbLo, CbHi, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectSetFileSizeL := ERROR_INVALID_HANDLE
  Else DosProtectSetFileSizeL := DosSetFileSizeL(H, CbLo, CbHi);
End;

Function DosProtectQueryFHState(H, PMode, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectQueryFHState := ERROR_INVALID_HANDLE
  Else DosProtectQueryFHState := DosQueryFHState(H, PMode);
End;

Function DosProtectSetFHState(H, Mode, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectSetFHState := ERROR_INVALID_HANDLE
  Else DosProtectSetFHState := DosSetFHState(H, Mode);
End;

Function DosProtectQueryFileInfo(H, Level, PInfo, Cb, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectQueryFileInfo := ERROR_INVALID_HANDLE
  Else DosProtectQueryFileInfo := DosQueryFileInfo(H, Level, PInfo, Cb);
End;

Function DosProtectSetFileInfo(H, Level, PInfo, Cb, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectSetFileInfo := ERROR_INVALID_HANDLE
  Else DosProtectSetFileInfo := DosSetFileInfo(H, Level, PInfo, Cb);
End;

Function DosProtectSetFileLocks(H, PUnlock, PLock, Timeout, Flags, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectSetFileLocks := ERROR_INVALID_HANDLE
  Else DosProtectSetFileLocks := DosSetFileLocks(H, PUnlock, PLock, Timeout, Flags);
End;

Function DosProtectSetFileLocksL(H, PUnlock, PLock, Timeout, Flags, LockId : LongInt) : LongInt;
Begin
  If Not CheckLock(H, LockId) Then DosProtectSetFileLocksL := ERROR_INVALID_HANDLE
  Else DosProtectSetFileLocksL := DosSetFileLocksL(H, PUnlock, PLock, Timeout, Flags);
End;

Function DosProtectEnumAttribute(RefType, PvFile, Entry, PvBuf, CbBuf, PCount, Level, LockId : LongInt) : LongInt;
Begin
  If (RefType = 0) And Not CheckLock(PeekL(PvFile), LockId) Then
    DosProtectEnumAttribute := ERROR_INVALID_HANDLE
  Else
    DosProtectEnumAttribute := DosEnumAttribute(RefType, PvFile, Entry, PvBuf, CbBuf, PCount, Level);
End;

{ ==================================================================== }
{ Exportations (convention _System) et initialisation                  }
{ ==================================================================== }

exports
  DosAcknowledgeSignalException, DosAddMuxWaitSem, DosAliasMem,
  DosAllocHuge, DosAllocMem, DosAllocSeg, DosAllocSharedMem,
  DosAllocShrSeg, DosAllocThreadLocalMemory, DosAsyncTimer, DosBeep,
  DosBufReset, DosCallBack, DosCallNmPipe, DosCallNPipe,
  DosCancelLockRequest, DosCancelLockRequestL, DosCaseMap, DosChDir,
  DosChgFilePtr, DosCLIAccess, DosClose, DosCloseEventSem,
  DosCloseMutexSem, DosCloseMuxWaitSem, DosCloseSem, DosCloseVDD,
  DosConnectNmPipe, DosConnectNPipe, DosCopy, DosCreateCSAlias,
  DosCreateDir, DosCreateEventSem, DosCreateMutexSem, DosCreateMuxWaitSem,
  DosCreateNPipe, DosCreatePipe, DosCreateSem, DosCreateThread,
  DosCreateThread2, DosCwait, DosDebug, DosDelete, DosDeleteDir,
  DosDeleteMuxWaitSem, DosDevConfig, DosDevIOCtl, DosDevIOCtl2,
  DosDisconnectNmPipe, DosDisConnectNPipe, DosDumpProcess, DosDupHandle,
  DosEditName, DosEnterCritSec, DosEnterMustComplete, DosEnumAttribute,
  DosErrClass, DosError, DosExecPgm, DosExit, DosExitCritSec, DosExitList,
  DosExitMustComplete, DosFileIO, DosFileLocks, DosFindClose, DosFindFirst,
  DosFindFirst2, DosFindNext, DosFlagProcess, DosForceDelete,
  DosForceSystemDump, DosFreeMem, DosFreeModule, DosFreeResource,
  DosFreeSeg, DosFreeThreadLocalMemory, DosFSAttach, DosFSCtl,
  DosFSRamSemClear, DosFSRamSemRequest, DosGetCollate, DosGetCP,
  DosGetCtryInfo, DosGetDateTime, DosGetDBCSEv, DosGetEnv, DosGetHugeShift,
  DosGetInfoBlocks, DosGetInfoSeg, DosGetMachineMode, DosGetModHandle,
  DosGetModName, DosGetNamedSharedMem, DosGetPID, DosGetPPID,
  DosGetProcAddr, DosGetProcessorStatus, DosGetPrty, DosGetResource,
  DosGetResource2, DosGetSeg, DosGetSharedMem, DosGetShrSeg, DosGetVersion,
  DosGiveSeg, DosGiveSharedMem, DosHoldSignal, DosICreateThread,
  DosIExecPgm, DosInsertMessage, DosInsMessage, DosIQueryMessageCP,
  DosGetMessage, DosQueryMessageCP,
  DosIRead, DosISemRequest, DosISemWait, DosISysSemClear, DosISysSemSet,
  DosIWrite, DosKillProcess, DosKillThread, DosListIO, DosListIOL,
  DosLoadModule, DosLockSeg, DosMakeNmPipe, DosMakePipe, DosMapCase,
  DosMemAvail, DosMkDir, DosMkDir2, DosMonClose, DosMonOpen, DosMonRead,
  DosMonReg, DosMonWrite, DosMove, DosMuxSemWait, DosNewSize, DosOpen,
  DosOpen2, DosOpenEventSem, DosOpenL, DosOpenMutexSem, DosOpenMuxWaitSem,
  DosOpenSem, DosOpenVDD, DosPeekNmPipe, DosPeekNPipe, DosPerfSysCall,
  DosPhysicalDisk, DosPortAccess, DosPostEventSem, DosProtectClose,
  DosProtectEnumAttribute, DosProtectOpen, DosProtectOpenL,
  DosProtectQueryFHState, DosProtectQueryFileInfo, DosProtectRead,
  DosProtectSetFHState, DosProtectSetFileInfo, DosProtectSetFileLocks,
  DosProtectSetFileLocksL, DosProtectSetFilePtr, DosProtectSetFilePtrL,
  DosProtectSetFileSize, DosProtectSetFileSizeL, DosProtectWrite,
  DosPtrace, DosPutMessage, DosQAppType, DosQCurDir, DosQCurDisk,
  DosQFHandState, DosQFileInfo, DosQFileMode, DosQFSAttach, DosQFSInfo,
  DosQHandType, DosQNmPHandState, DosQNmPipeInfo, DosQNmPipeSemState,
  DosQPathInfo, DosQSysInfo, DosQueryABIOSSupport, DosQueryAppType,
  DosQueryCollate, DosQueryCp, DosQueryCtryInfo, DosQueryCurrentDir,
  DosQueryCurrentDisk, DosQueryDBCSEnv, DosQueryEventSem,
  DosQueryExtLIBPATH, DosQueryFHState, DosQueryFileInfo, DosQueryFSAttach,
  DosQueryFSInfo, DosQueryHType, DosQueryMem, DosQueryMemState,
  DosQueryModFromCS, DosQueryModFromEIP, DosQueryModuleHandle,
  DosQueryModuleName, DosQueryMutexSem, DosQueryMuxWaitSem,
  DosQueryNPHState, DosQueryNPipeInfo, DosQueryNPipeSemState,
  DosQueryPathInfo, DosQueryProcAddr, DosQueryProcType,
  DosQueryResourceSize, DosQuerySysInfo, DosQueryThreadAffinity,
  DosQueryThreadContext, DosQueryVerify, DosQVerify, DosR2StackRealloc,
  DosRaiseException, DosRead, DosReadAsync, DosReallocHuge, DosReallocSeg,
  DosReleaseMutexSem, DosReplaceModule, DosRequestMutexSem, DosRequestVDD,
  DosResetBuffer, DosResetEventSem, DosResumeThread, DosRmDir, DosScanEnv,
  DosSearchPath, DosSelectDisk, DosSemClear, DosSemRequest, DosSemSet,
  DosSemSetWait, DosSemWait, DosSendSignal, DosSendSignalException,
  DosSetCP, DosSetCurrentDir, DosSetDateTime, DosSetDefaultDisk,
  DosSetExceptionHandler, DosSetExtLIBPATH, DosSetFHandState,
  DosSetFHState, DosSetFileInfo, DosSetFileLocks, DosSetFileLocksL,
  DosSetFileMode, DosSetFilePtr, DosSetFilePtrL, DosSetFileSize,
  DosSetFileSizeL, DosSetFSInfo, DosSetMaxFH, DosSetMem,
  DosSetNmPHandState, DosSetNmPipeSem, DosSetNPHState, DosSetNPipeSem,
  DosSetPathInfo, DosSetProcCP, DosSetProcessCp, DosSetProcessorStatus,
  DosSetPriority, DosSetPrty, DosSetRelMaxFH, DosSetSigHandler,
  DosSetSignalExceptionFocus, DosSetThreadAffinity, DosSetVec,
  DosSetVerify, DosShutdown, DosSizeSeg, DosSleep, DosStartTimer,
  DosStopTimer, DosSubAlloc, DosSubAllocMem, DosSubFree, DosSubFreeMem,
  DosSubSet, DosSubSetMem, DosSubUnsetMem, DosSuppressPopUps,
  DosSuspendThread, DosSystemService, DosSysTrace, DosTimerAsync,
  DosTimerStart, DosTimerStop, DosTmrQueryFreq, DosTmrQueryTime,
  DosTransactNmPipe, DosTransactNPipe, DosTrueGetMessage, DosUnlockSeg,
  DosUnsetExceptionHandler, DosUnwindException, DosVerifyPidTid,
  DosWaitChild, DosWaitEventSem, DosWaitMuxWaitSem, DosWaitNmPipe,
  DosWaitNPipe, DosWaitThread, DosWrite, DosWriteAsync;

{ Initialisation de la DLL (executee une fois, au chargement par le noyau) }
Var
  Tmp : Array[0..15] Of Byte;
  N   : LongInt;

BEGIN
  InitHandles;
  CurCp := 850;
  CtryDefault := 2;                         { Canada (francais) }
  N := KGetEnvironmentVariableA(Z('COUNTRY', 1), LongInt(@Tmp), 16);
  If (N > 0) And (N < 16) Then
  Begin
    Val(GetStr(LongInt(@Tmp)), N, Verify);
    If CtryValid(N) Then CtryDefault := N;
  End;
  Verify := 0;
  NextTid := 2;
  CurThread := 1;
  ThrDepth := 0;
  ExtLibBegin := '';
  ExtLibEnd := '';
END.
