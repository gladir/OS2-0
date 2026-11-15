{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 PMSPL.DLL de OS/2-0 (tampon
                d'impression de Presentation Manager : files d'attente,
                travaux, imprimantes, donnees PM_Q_STD, acces direct).
}

Library PMSPL;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC PMSPL.PAS   (produit PMSPL.DLL)

  PMSPL.DLL est le tampon d'impression (spouleur) de Presentation
  Manager. Il garde les files d'attente, les imprimantes et les travaux
  d'impression, ecrit les donnees de chaque travail dans un fichier de
  spoule et les envoie a l'imprimante par le processeur de file d'attente
  (PMPRINT).

  Files d'attente et imprimantes : elles sont lues dans le profil du
  systeme (OS2SYS.INI, par PMMERGE.DLL) a la premiere utilisation et y
  sont ecrites quand elles changent :
    PM_SPOOLER                DIR = repertoire des fichiers de spoule
                              ("C:\SPOOL;"), QUEUE = file par defaut
                              ("LPT1Q;"), PRINTER = imprimante par defaut
                              ("PRINTER1;"), MSGTIMEOUT = delai de
                              SplMessageBox en secondes (180 ; 0 : aucun ;
                              propre a OS/2-0)
    PM_SPOOLER_PRINTER        imprimante = "port;pilote;file;;"
    PM_SPOOLER_PRINTER_DESCR  imprimante = "description;"
    PM_SPOOLER_QUEUE          file = "imprimante;priorite;debut;fin;type;
                              separateur;processeur;parametres;pilote;
                              etat;" (format d'OS/2-0)
    PM_SPOOLER_QUEUE_DESCR    file = "description;"
  Sans file d'attente dans le profil, PMSPL cree l'imprimante PRINTER1
  (port LPT1, pilote IBMNULL) et la file LPT1Q. Le port d'une imprimante
  est PRN, LPT1 a LPT3, COM1 a COM4, NUL ou un nom de fichier (les
  donnees y sont ajoutees a la fin).

  Travaux : numeros 1 a 9999 ; fichier de spoule DIR\file\nnnnn.SPL ;
  priorite 1 (basse) a 99 (haute), 50 par defaut (PRTY=n dans les
  parametres du spouleur) ; les travaux d'une file sont ranges par
  priorite puis par ordre d'arrivee. Un travail est imprime des qu'il est
  complet (SplQmEndDoc, SplQmClose, PrtClose, SplQmWriteFile) si sa file
  n'est pas retenue, si le travail n'est pas retenu et si l'heure est
  dans la plage de la file (uStartTime a uUntilTime, minutes depuis
  minuit ; un travail en attente de sa plage est imprime au prochain
  appel du spouleur). Le processeur de file PMPRINT envoie le fichier
  separateur de la file (s'il y en a un) puis les donnees : PM_Q_RAW
  telles quelles, PM_Q_STD (metafichier de PMGPI.DLL) dessinees par
  PicPrint de PMPIC.DLL (graphique ESC/P) ; COP=n (parametres du
  processeur, de la file ou du travail) imprime n copies. Un port qui ne
  s'ouvre pas laisse le travail retenu avec PRJ_ERROR et
  PRJ_DESTOFFLINE.

  Points d'entree (convention _System ; BOOL et handles : erreur par
  WinGetLastError de PMWIN, PMERR_SPL_* ; les autres rendent un code :
  0, ERROR_INVALID_LEVEL 124, ERROR_MORE_DATA 234, NERR_BufTooSmall
  2123, NERR_QNotFound 2150, NERR_JobNotFound 2151, NERR_DestNotFound
  2152, NERR_QExists 2154, NERR_QNoRoom 2155, NERR_JobNoRoom 2156,
  NERR_DestNoRoom 2157, NERR_QInvalidState 2160, NERR_JobInvalidState
  2164, NERR_DataTypeInvalid 2167, ERROR_INVALID_PARAMETER 87) :

   1 SplQmOpen(pszToken, lCount, pqmdopData) : HSPL (5350xxxxh, 0 :
       erreur). pqmdopData : DEVOPENSTRUC (pszLogAddress = file ou
       imprimante, vide : file par defaut ; pszDriverName, pdriv,
       pszDataType PM_Q_STD (defaut) ou PM_Q_RAW, pszComment,
       pszQueueProcName, pszQueueProcParams, pszSpoolerParams).
   2 SplQmStartDoc(hspl, pszDocName) : BOOL (cree le travail)
   3 SplQmEndDoc(hspl) : numero du travail (0 : erreur)
   4 SplQmWrite(hspl, lCount, pData) : BOOL (sans SplQmStartDoc, un
       document sans nom est commence)
   5 SplQmAbort(hspl) : BOOL (abandonne le document, ferme le handle)
   6 SplQmClose(hspl) : BOOL (termine le document commence)
   7 SplMessageBox(pszLogAddr, fErrInfo, fErrData, pszText, pszCaption,
       idWindow, fStyle) : MBID_* ; la file de messages est creee si
       besoin ; le texte est complete par l'imprimante et les erreurs
       SPLDATA_* ; l'icone suit SPLINFO_* si fStyle n'en a pas ; apres
       MSGTIMEOUT secondes (3 minutes), la boite rend MBID_RETRY.
   8 SplQmAbortDoc(hspl) : BOOL
  20 SplInit() : 0 (lit les files d'attente, imprime ce qui attend)
  21 SplQmListQueues(ulLevel, pBuf, cbBuf, pcReturned, pcTotal,
       pcbNeeded) : niveaux 3 (PRQINFO3), 4 (PRQINFO3 suivie des
       PRJINFO2 de ses travaux), 6 (PRQINFO6)
  22 SplQmQueryQInfo(pszQueue, ulLevel, pBuf, cbBuf, pcbNeeded)
  23 SplQmListJobs(pszQueue, ulLevel, pBuf, cbBuf, pcReturned, pcTotal,
       pcbNeeded) : niveaux 0 (numero, mot), 2 (PRJINFO2), 3 (PRJINFO3) ;
       pszQueue nul : toutes les files
  24 SplQmQueryJInfo(pszQueue, ulJob, ulLevel, pBuf, cbBuf, pcbNeeded)
  25 SplQmHoldQueue(pszQueue), 26 SplQmReleaseQueue(pszQueue)
  27 SplQmHoldJob(pszQueue, ulJob), 28 SplQmReleaseJob(pszQueue, ulJob)
  29 SplQmCancelJob(pszQueue, ulJob) : supprime le travail
  30 SplQmRestartJob(pszQueue, ulJob) : reprend le travail depuis le
       debut (retenue et erreurs effacees)
  31 SplQmRepeatJob(pszQueue, ulJob, pulNewJob) : copie du travail
       placee apres lui
  32 SplQmPrintJobNext(pszQueue, ulJob) : le travail passe en tete
  33 SplQmQueryPInfo(pszPrinter, ulLevel, pBuf, cbBuf, pcbNeeded) :
       niveaux 0 (nom de 9 octets) et 3 (PRDINFO3)
  34 SplQmChangeJobPrty(pszQueue, ulJob, ulPriority) : 1 a 99
  35 SplQmWriteFile(pszQueue, pszFileName, pszDocName, pulJob) : copie
       d'un fichier comme travail PM_Q_RAW (commande PRINT)
  36 SplQmSetStatus(pszQueue, ulJob, fsStatus, pszStatus) : bits
       PRJ_COMPLETE a PRJ_DESTPENCHG et texte d'etat du travail
  37 SplQmCreateQueue(ulLevel, pBuf, cbBuf) : PRQINFO3 ou PRQINFO6 ;
       pszPrinters : imprimante existante, port, ou "nom=port" (cree
       l'imprimante) ; vide : imprimante de la file par defaut
  38 SplQmDestroyQueue(pszQueue) : les travaux sont supprimes
  39 SplQmListAvailQueues(pBuf, cbBuf, pcReturned) : noms des files
       (chaines terminees par un nul, un nul de plus a la fin)
  40 SplQmListDirectPrinters(pBuf, cbBuf, pcReturned) : ports
       paralleles presents (LPT1 a LPT3), meme format
  41 SplQmQueryPrintData(ulJob, ulOffset, pBuf, cbBuf, pcbRead) :
       lecture des donnees du travail
  42 SplQmUpdateQProcParms(pszQueue, ulJob, pszParms) : parametres du
       processeur de la file (ulJob 0) ou du travail
  50 SplStdOpen(hdc), 51 SplStdClose(hdc) : BOOL
  52 SplStdStart(hdc) : BOOL, enregistre les appels de la GPI faits sur
       le DC (PMGPI.DLL)
  53 SplStdStop(hdc) : HSTD (metafichier de PMGPI, 474Dxxxxh)
  54 SplStdDelete(hstd), 55 SplStdGetBits(hstd, offData, cbData,
       pchData) : BOOL ; 56 SplStdQueryLength(hstd) : octets
  70 PrtOpen(pszDevName, phf, pulAction, cbFileSize, ulAttribute,
       fsOpenFlags, fsOpenMode, ulReserved) : si une file d'attente sert
       l'imprimante de ce port, les donnees vont dans un travail
       PM_Q_RAW, sinon le port est ouvert directement (DosOpen)
  71 PrtWrite(hf, pBuf, cbBuf, pcbWritten)
  72 PrtDevIOCtl(pData, pParms, usFunction, usCategory, hDev) : ordre
       d'OS/2 1.x ; categorie 5 (IOCTL_PRINTER) : 42h/62h controle de la
       page, 44h/64h reessai infini, 46h initialisation, 48h/69h/6Ah
       police, 66h etat (port parallele, ou 90h pour un travail) ; les
       autres categories vont a DosDevIOCtl (ouverture directe)
  73 PrtClose(hf) : le travail est termine et imprime
  75 PrtAbort(hf) : le travail est abandonne
  90 SplRing3(pfn, ulParam) : appelle pfn(ulParam) et rend sa valeur
       (les programmes d'OS/2-0 s'executent tous en anneau 0)
  1001 SPLMSGBOXTIMERPROC : procedure interne de la fenetre du delai de
       SplMessageBox.

  Structures (32 bits) : PRQINFO3 44 octets (pszName, uPriority,
  uStartTime, uUntilTime, fsType, pszSepFile, pszPrProc, pszParms,
  pszComment, fsStatus, cJobs, pszPrinters, pszDriverName, pDriverData),
  PRQINFO6 52 (+ pszRemoteComputerName, pszRemoteQueueName), PRJINFO2 28
  (uJobId, uPriority, pszUserName, uPosition, fsStatus, ulSubmitted,
  ulSize, pszComment, pszDocument), PRJINFO3 68 (+ pszNotifyName,
  pszDataType, pszParms, pszStatus, pszQueue, pszQProcName,
  pszQProcParms, pszDriverName, pDriverData, pszPrinterName), PRDINFO3
  32 (pszPrinterName, pszUserName, pszLogAddr, uJobId, fsStatus,
  pszStatus, pszComment, pszDrivers, time, usTimeOut). Les chaines sont
  placees a la fin du tampon. ulSubmitted : secondes depuis 1970.

  Limites : 16 files, 16 imprimantes, 64 travaux, 16 handles HSPL et 16
  handles Prt ; l'impression se fait dans le processus qui termine le
  travail, sans processus d'arriere-plan ; un travail PM_Q_STD est
  imprime sur une page ; les pilotes d'imprimante ne sont pas charges
  (le nom est garde). }

Const
  NO_ERROR = 0; ERROR_INVALID_FUNCTION = 1; ERROR_INVALID_HANDLE = 6; ERROR_INVALID_PARAMETER = 87;
  ERROR_INVALID_LEVEL = 124; ERROR_MORE_DATA = 234;
  NERR_BufTooSmall = 2123; NERR_QNotFound = 2150; NERR_JobNotFound = 2151; NERR_DestNotFound = 2152;
  NERR_QExists = 2154; NERR_QNoRoom = 2155; NERR_JobNoRoom = 2156; NERR_DestNoRoom = 2157;
  NERR_QInvalidState = 2160; NERR_JobInvalidState = 2164; NERR_DataTypeInvalid = 2167;
  PMERR_SPL_DEVICE_ERROR = $4002; PMERR_SPL_QUEUE_ERROR = $4004; PMERR_SPL_INV_HSPL = $4005;
  PMERR_SPL_NO_DISK_SPACE = $4006; PMERR_SPL_NO_MEMORY = $4007; PMERR_SPL_NO_FREE_JOB_ID = $400C;
  PMERR_SPL_NO_DATA = $400D; PMERR_SPL_INV_DATATYPE = $400F; PMERR_INVALID_PARAMETER = $1208;
  HINI_SYSTEMPROFILE = -2;
  PRJ_ERROR = $0010; PRJ_DESTOFFLINE = $0020;
  MaxQu = 16; MaxPr = 16; MaxJb = 64; MaxHs = 16; MaxPt = 16; MaxSd = 16;
  WM_TIMER = $0024; MBID_RETRY = 4; HWND_DESKTOP = 1; HWND_OBJECT = 2; HWND_TOP = 3;

{ --- DOSCALLS.DLL --- }
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosDevIOCtl(H, Cat, Fn, PParm, CbParm, PcbParm, PData, CbData, PcbData : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryModuleHandle(PName, PH : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PP : LongInt) : LongInt; External 'DOSCALLS';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KLxTib(Op, P1, P2, P3 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnTaskCtl';

{ --- PMWIN.DLL --- }
Function WinSetErrorInfo(E, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinTerminate(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyMsgQueue(Hmq : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQueryActiveWindow(HPar : LongInt) : LongInt; External 'PMWIN';
Function WinDismissDlg(H, R : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';

{ --- PMGPI.DLL, PMPIC.DLL, PMMERGE.DLL --- }
Function GpiQueryMetaFileLength(H : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryMetaFileBits(H, Off, Len, P : LongInt) : LongInt; External 'PMGPI';
Function GpiDeleteMetaFile(H : LongInt) : LongInt; External 'PMGPI';
Function GpiStdStart(Hdc : LongInt) : LongInt; External 'PMGPI' Name 'GPISTDSTART';
Function GpiStdStop(Hdc : LongInt) : LongInt; External 'PMGPI' Name 'GPISTDSTOP';
Function PicPrint(Hab, PName, Typ, PPrm : LongInt) : LongInt; External 'PMPIC';
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE';

Var
  Inited, Pumping, NextJob, Dummy, MbFired, MbProc, MbRegistered : LongInt;
  SpoolDir, DefQueue, DefPrinter : String;
  { imprimantes }
  PUse, PStat, PJob : Array[0..MaxPr - 1] Of LongInt;
  PName : Array[0..MaxPr - 1] Of String[31];
  PPort, PDrv, PCmt : Array[0..MaxPr - 1] Of String[79];
  { files d'attente }
  QUse, QPri, QStart, QUntil, QType, QStat, QPrn : Array[0..MaxQu - 1] Of LongInt;
  QName, QProc : Array[0..MaxQu - 1] Of String[31];
  QSep, QParms, QCmt, QDrv : Array[0..MaxQu - 1] Of String[79];
  { travaux }
  JUse, JId, JQ, JPri, JSeq, JStat, JHold, JDev, JSize, JTime, JType, JPid, JHf : Array[0..MaxJb - 1] Of LongInt;
  JDoc, JCmt, JParms, JQPP, JStTxt : Array[0..MaxJb - 1] Of String[79];
  { handles HSPL }
  HUse, HQ, HJob, HType : Array[0..MaxHs - 1] Of LongInt;
  HCmt, HQPP, HParms : Array[0..MaxHs - 1] Of String[79];
  { handles Prt }
  TUse, TKind, TH, TPrn, TCpl, TLpi, TRetry, TCp, TFont : Array[0..MaxPt - 1] Of LongInt;
  { enregistrements PM_Q_STD }
  SUse, SHdc, SHmf : Array[0..MaxSd - 1] Of LongInt;
  { tri des travaux, tampons }
  OrdL : Array[0..MaxJb - 1] Of LongInt;
  OrdN : LongInt;
  CopyBuf : Array[0..4095] Of Byte;
  KeyBuf : Array[0..4095] Of Byte;
  PkBuf, PkCb, PkFix, PkStr, PkNeed, PkWrite : LongInt;

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

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
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

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'a') And (S[K] <= 'z') Then S[K] := Chr(Ord(S[K]) - 32);
  UpStr := S;
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function Pad5(V : LongInt) : String;
Var S : String;
Begin
  S := IStr(V);
  While Length(S) < 5 Do S := '0' + S;
  Pad5 := S;
End;

{ nombre decimal au debut de S ; Df si aucun chiffre }
Function StrToI(S : String; Df : LongInt) : LongInt;
Var K, V : LongInt; Neg, Any : Boolean;
Begin
  K := 1; V := 0; Neg := False; Any := False;
  While (K <= Length(S)) And (S[K] = ' ') Do Inc(K);
  If (K <= Length(S)) And (S[K] = '-') Then
  Begin
    Neg := True;
    Inc(K);
  End;
  While (K <= Length(S)) And (S[K] >= '0') And (S[K] <= '9') Do
  Begin
    V := V * 10 + Ord(S[K]) - 48;
    Any := True;
    Inc(K);
  End;
  If Not Any Then StrToI := Df
  Else If Neg Then StrToI := -V
  Else StrToI := V;
End;

{ champ N (depuis 0) d'une chaine "a;b;c;" }
Function Fld(S : String; N : LongInt) : String;
Var K, I : LongInt; R : String;
Begin
  R := ''; I := 0;
  For K := 1 To Length(S) Do
    If S[K] = ';' Then Inc(I)
    Else If I = N Then R := R + S[K];
  Fld := R;
End;

{ valeur de "CLE=n" dans une liste de parametres }
Function ParmNum(S, Key : String; Df : LongInt) : LongInt;
Var P : LongInt; U : String;
Begin
  U := UpStr(S);
  P := Pos(Key, U);
  If P = 0 Then ParmNum := Df
  Else ParmNum := StrToI(Copy(U, P + Length(Key), 255), Df);
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

Procedure SetErr(Code : LongInt);
Begin
  Dummy := WinSetErrorInfo((4 Shl 16) Or Code, 0);
End;

{ --- appels de procedures (programme OS2PC : convention Pascal) --- }
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

Function CallPas1(F, A1 : LongInt) : LongInt;
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
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPas1 := R;
End;

Function Call1(F, A1 : LongInt) : LongInt;
Begin
  If (F >= $00400000) And (F < $00800000) And (KLxTib(18, 0, 0, 0) = 0) Then Call1 := CallPas1(F, A1)
  Else Call1 := CallSys1(F, A1);
End;

{ --- ports d'E/S (anneau 0) --- }
Function InB(P : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := 0;
  asm
    mov edx,P
    xor eax,eax
    in al,dx
    mov V,eax
  end;
  InB := V;
End;

Procedure OutB(P, V : LongInt);
Begin
  asm
    mov edx,P
    mov eax,V
    out dx,al
  end;
End;

{ secondes depuis 1970 et minutes depuis minuit (heure locale) }
Function NowSecs(Var Mins : LongInt) : LongInt;
Var Dt : Array[0..11] Of Byte; Y, M, D, Era, Yoe, Doy, Doe, Days : LongInt;
Begin
  Dummy := DosGetDateTime(LongInt(@Dt));
  Y := Dt[6] + Dt[7] * 256; M := Dt[5]; D := Dt[4];
  If M <= 2 Then Y := Y - 1;
  Era := Y Div 400;
  Yoe := Y - Era * 400;
  If M > 2 Then Doy := (153 * (M - 3) + 2) Div 5 + D - 1 Else Doy := (153 * (M + 9) + 2) Div 5 + D - 1;
  Doe := Yoe * 365 + Yoe Div 4 - Yoe Div 100 + Doy;
  Days := Era * 146097 + Doe - 719468;
  Mins := Dt[0] * 60 + Dt[1];
  NowSecs := Days * 86400 + Mins * 60 + Dt[2];
End;

{ ==================================================================== }
{ Profil du systeme                                                     }
{ ==================================================================== }

Function PrfQ(App, Key : String) : String;
Var A, K, B : Array[0..259] Of Byte;
Begin
  PutZ(LongInt(@A), App); PutZ(LongInt(@K), Key);
  B[0] := 0;
  Dummy := PrfQueryProfileString(HINI_SYSTEMPROFILE, LongInt(@A), LongInt(@K), 0, LongInt(@B), 256);
  B[255] := 0;
  PrfQ := GetZ(LongInt(@B));
End;

Procedure PrfW(App, Key, Val : String);
Var A, K, B : Array[0..259] Of Byte;
Begin
  PutZ(LongInt(@A), App); PutZ(LongInt(@K), Key); PutZ(LongInt(@B), Val);
  Dummy := PrfWriteProfileString(HINI_SYSTEMPROFILE, LongInt(@A), LongInt(@K), LongInt(@B));
End;

Procedure PrfDel(App, Key : String);
Var A, K : Array[0..259] Of Byte;
Begin
  PutZ(LongInt(@A), App); PutZ(LongInt(@K), Key);
  Dummy := PrfWriteProfileString(HINI_SYSTEMPROFILE, LongInt(@A), LongInt(@K), 0);
End;

{ cles d'une application dans KeyBuf ; rend la longueur }
Function PrfKeys(App : String) : LongInt;
Var A : Array[0..259] Of Byte; N : LongInt;
Begin
  PutZ(LongInt(@A), App);
  KeyBuf[0] := 0; KeyBuf[1] := 0;
  N := PrfQueryProfileString(HINI_SYSTEMPROFILE, LongInt(@A), 0, 0, LongInt(@KeyBuf), 4000);
  If N < 0 Then N := 0;
  PrfKeys := N;
End;

{ ==================================================================== }
{ Imprimantes et files d'attente                                        }
{ ==================================================================== }

Function FindPrinter(S : String) : LongInt;
Var I, R : LongInt;
Begin
  R := -1; S := UpStr(S);
  For I := MaxPr - 1 DownTo 0 Do
    If (PUse[I] <> 0) And (UpStr(PName[I]) = S) Then R := I;
  FindPrinter := R;
End;

Function NormPort(S : String) : String;
Begin
  S := UpStr(S);
  If (Length(S) > 0) And (S[Length(S)] = ':') Then S := Copy(S, 1, Length(S) - 1);
  If S = 'PRN' Then S := 'LPT1';
  NormPort := S;
End;

Function PrinterOfPort(S : String) : LongInt;
Var I, R : LongInt;
Begin
  R := -1; S := NormPort(S);
  For I := MaxPr - 1 DownTo 0 Do
    If (PUse[I] <> 0) And (NormPort(PPort[I]) = S) Then R := I;
  PrinterOfPort := R;
End;

Function FindQueue(S : String) : LongInt;
Var I, R : LongInt;
Begin
  R := -1; S := UpStr(S);
  For I := MaxQu - 1 DownTo 0 Do
    If (QUse[I] <> 0) And (UpStr(QName[I]) = S) Then R := I;
  FindQueue := R;
End;

Procedure SavePrinter(P : LongInt);
Var Qn : String; I : LongInt;
Begin
  Qn := '';
  For I := MaxQu - 1 DownTo 0 Do
    If (QUse[I] <> 0) And (QPrn[I] = P) Then Qn := QName[I];
  PrfW('PM_SPOOLER_PRINTER', PName[P], PPort[P] + ';' + PDrv[P] + ';' + Qn + ';;');
  PrfW('PM_SPOOLER_PRINTER_DESCR', PName[P], PCmt[P] + ';');
End;

Procedure SaveQueue(Q : LongInt);
Var Pn : String;
Begin
  Pn := '';
  If (QPrn[Q] >= 0) And (PUse[QPrn[Q]] <> 0) Then Pn := PName[QPrn[Q]];
  PrfW('PM_SPOOLER_QUEUE', QName[Q], Pn + ';' + IStr(QPri[Q]) + ';' + IStr(QStart[Q]) + ';' + IStr(QUntil[Q]) + ';' +
       IStr(QType[Q]) + ';' + QSep[Q] + ';' + QProc[Q] + ';' + QParms[Q] + ';' + QDrv[Q] + ';' + IStr(QStat[Q]) + ';');
  PrfW('PM_SPOOLER_QUEUE_DESCR', QName[Q], QCmt[Q] + ';');
  If QPrn[Q] >= 0 Then SavePrinter(QPrn[Q]);
End;

Function AddPrinter(N, PortS, Drv, Cmt : String) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxPr - 1 DownTo 0 Do
    If PUse[I] = 0 Then F := I;
  If F >= 0 Then
  Begin
    PUse[F] := 1; PName[F] := N; PPort[F] := PortS; PDrv[F] := Drv; PCmt[F] := Cmt;
    PStat[F] := 0; PJob[F] := 0;
  End;
  AddPrinter := F;
End;

Procedure MkDir2(S : String);
Var B : Array[0..259] Of Byte;
Begin
  PutZ(LongInt(@B), S);
  Dummy := DosCreateDir(LongInt(@B), 0);
End;

Function AddQueue(N : String; Prn : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxQu - 1 DownTo 0 Do
    If QUse[I] = 0 Then F := I;
  If F >= 0 Then
  Begin
    QUse[F] := 1; QName[F] := N; QPrn[F] := Prn; QPri[F] := 5; QStart[F] := 0; QUntil[F] := 0;
    QType[F] := 0; QSep[F] := ''; QProc[F] := 'PMPRINT'; QParms[F] := ''; QCmt[F] := ''; QDrv[F] := 'IBMNULL';
    QStat[F] := 0;
    If (Prn >= 0) And (PDrv[Prn] <> '') Then QDrv[F] := PDrv[Prn];
    MkDir2(SpoolDir);
    MkDir2(SpoolDir + '\' + N);
  End;
  AddQueue := F;
End;

Procedure EnsureInit;
Var N, K, P, Q, I : LongInt; S, V : String;
Begin
  If Inited <> 0 Then Exit;
  Inited := 1;
  If NextJob <= 0 Then NextJob := 1;
  SpoolDir := Fld(PrfQ('PM_SPOOLER', 'DIR'), 0);
  If SpoolDir = '' Then SpoolDir := 'C:\SPOOL';
  If SpoolDir[Length(SpoolDir)] = '\' Then SpoolDir := Copy(SpoolDir, 1, Length(SpoolDir) - 1);
  { imprimantes }
  N := PrfKeys('PM_SPOOLER_PRINTER');
  K := 0;
  While (K < N) And (KeyBuf[K] <> 0) Do
  Begin
    S := GetZ(LongInt(@KeyBuf) + K);
    K := K + Length(S) + 1;
    If FindPrinter(S) < 0 Then
    Begin
      V := PrfQ('PM_SPOOLER_PRINTER', S);
      Dummy := AddPrinter(S, Fld(V, 0), Fld(V, 1), Fld(PrfQ('PM_SPOOLER_PRINTER_DESCR', S), 0));
    End;
  End;
  { files d'attente }
  N := PrfKeys('PM_SPOOLER_QUEUE');
  K := 0;
  While (K < N) And (KeyBuf[K] <> 0) Do
  Begin
    S := GetZ(LongInt(@KeyBuf) + K);
    K := K + Length(S) + 1;
    If FindQueue(S) < 0 Then
    Begin
      V := PrfQ('PM_SPOOLER_QUEUE', S);
      P := FindPrinter(Fld(V, 0));
      Q := AddQueue(S, P);
      If Q >= 0 Then
      Begin
        QPri[Q] := StrToI(Fld(V, 1), 5); QStart[Q] := StrToI(Fld(V, 2), 0); QUntil[Q] := StrToI(Fld(V, 3), 0);
        QType[Q] := StrToI(Fld(V, 4), 0); QSep[Q] := Fld(V, 5); QProc[Q] := Fld(V, 6); QParms[Q] := Fld(V, 7);
        QDrv[Q] := Fld(V, 8); QStat[Q] := StrToI(Fld(V, 9), 0);
        If QProc[Q] = '' Then QProc[Q] := 'PMPRINT';
        QCmt[Q] := Fld(PrfQ('PM_SPOOLER_QUEUE_DESCR', S), 0);
      End;
    End;
  End;
  N := 0;
  For I := 0 To MaxQu - 1 Do
    If QUse[I] <> 0 Then Inc(N);
  If N = 0 Then
  Begin
    P := FindPrinter('PRINTER1');
    If P < 0 Then P := AddPrinter('PRINTER1', 'LPT1', 'IBMNULL', 'Imprimante sur LPT1');
    Q := AddQueue('LPT1Q', P);
    QCmt[Q] := 'File d''attente de LPT1';
    SaveQueue(Q);
    PrfW('PM_SPOOLER', 'QUEUE', 'LPT1Q;');
    PrfW('PM_SPOOLER', 'PRINTER', 'PRINTER1;');
    PrfW('PM_SPOOLER', 'DIR', SpoolDir + ';');
  End;
  DefQueue := Fld(PrfQ('PM_SPOOLER', 'QUEUE'), 0);
  If FindQueue(DefQueue) < 0 Then
  Begin
    DefQueue := '';
    For I := MaxQu - 1 DownTo 0 Do
      If QUse[I] <> 0 Then DefQueue := QName[I];
  End;
  DefPrinter := Fld(PrfQ('PM_SPOOLER', 'PRINTER'), 0);
End;

{ file designee par un pointeur de nom (nul ou vide : file par defaut) }
Function QueueOf(PQ : LongInt) : LongInt;
Var S : String; Q, P, I : LongInt;
Begin
  EnsureInit;
  S := GetZ(PQ);
  If S = '' Then S := DefQueue;
  Q := FindQueue(S);
  If Q < 0 Then
  Begin
    P := FindPrinter(S);
    If P < 0 Then P := PrinterOfPort(S);
    If P >= 0 Then
      For I := MaxQu - 1 DownTo 0 Do
        If (QUse[I] <> 0) And (QPrn[I] = P) Then Q := I;
  End;
  QueueOf := Q;
End;

{ ==================================================================== }
{ Travaux                                                               }
{ ==================================================================== }

Function JobIdx(Id : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := MaxJb - 1 DownTo 0 Do
    If (JUse[I] <> 0) And (JId[I] = Id) Then R := I;
  JobIdx := R;
End;

{ travail ulJob dans la file pszQueue (nul : toute file) ; -1 }
Function JobOf(PQ, Id : LongInt; Var Rc : LongInt) : LongInt;
Var J, Q : LongInt;
Begin
  EnsureInit;
  Rc := NO_ERROR;
  J := JobIdx(Id);
  If (J >= 0) And (PQ <> 0) And (GetZ(PQ) <> '') Then
  Begin
    Q := QueueOf(PQ);
    If Q < 0 Then
    Begin
      Rc := NERR_QNotFound;
      J := -1;
    End
    Else If JQ[J] <> Q Then J := -1;
  End;
  If (J < 0) And (Rc = NO_ERROR) Then Rc := NERR_JobNotFound;
  JobOf := J;
End;

Function JobFile(J : LongInt) : String;
Begin
  JobFile := SpoolDir + '\' + QName[JQ[J]] + '\' + Pad5(JId[J]) + '.SPL';
End;

{ travaux de la file Q tries par JSeq dans OrdL (Q = -1 : tous) }
Procedure SortJobs(Q : LongInt);
Var I, K, T : LongInt;
Begin
  OrdN := 0;
  For I := 0 To MaxJb - 1 Do
    If (JUse[I] <> 0) And ((Q < 0) Or (JQ[I] = Q)) Then
    Begin
      OrdL[OrdN] := I;
      Inc(OrdN);
    End;
  For I := 1 To OrdN - 1 Do
  Begin
    T := OrdL[I]; K := I - 1;
    While (K >= 0) And (JSeq[OrdL[K]] > JSeq[T]) Do
    Begin
      OrdL[K + 1] := OrdL[K];
      Dec(K);
    End;
    OrdL[K + 1] := T;
  End;
End;

Procedure Renumber(Q : LongInt);
Var I : LongInt;
Begin
  SortJobs(Q);
  For I := 0 To OrdN - 1 Do JSeq[OrdL[I]] := (I + 1) * 10;
End;

{ ranger le travail J d'apres sa priorite }
Procedure PlaceJob(J : LongInt);
Var I, S : LongInt;
Begin
  JSeq[J] := 2000000000;
  Renumber(JQ[J]);
  S := 5;
  For I := 0 To OrdN - 1 Do
    If (OrdL[I] <> J) And (JPri[OrdL[I]] >= JPri[J]) Then S := JSeq[OrdL[I]] + 5;
  JSeq[J] := S;
  Renumber(JQ[J]);
End;

Function JobPos(J : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  SortJobs(JQ[J]);
  R := 0;
  For I := 0 To OrdN - 1 Do
    If OrdL[I] = J Then R := I + 1;
  JobPos := R;
End;

Function QueueJobs(Q : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxJb - 1 Do
    If (JUse[I] <> 0) And (JQ[I] = Q) Then Inc(N);
  QueueJobs := N;
End;

Function JobStatus(J : LongInt) : LongInt;
Var S : LongInt;
Begin
  If JStat[J] >= 2 Then S := JStat[J]
  Else If (JHold[J] <> 0) Or ((JDev[J] And PRJ_ERROR) <> 0) Then S := 1
  Else S := 0;
  JobStatus := S Or (JDev[J] And $0FFC);
End;

{ nouveau travail dans la file Q ; -1 }
Function NewJob(Q, Typ : LongInt; Doc, Cmt, Parms, QPP : String) : LongInt;
Var I, F, Id, M, Tries : LongInt;
Begin
  F := -1;
  For I := MaxJb - 1 DownTo 0 Do
    If JUse[I] = 0 Then F := I;
  If F < 0 Then
  Begin
    NewJob := -1;
    Exit;
  End;
  Id := NextJob; Tries := 0;
  While (JobIdx(Id) >= 0) And (Tries < 10000) Do
  Begin
    Inc(Id);
    If Id > 9999 Then Id := 1;
    Inc(Tries);
  End;
  NextJob := Id + 1;
  If NextJob > 9999 Then NextJob := 1;
  JUse[F] := 1; JId[F] := Id; JQ[F] := Q; JType[F] := Typ; JDoc[F] := Doc; JCmt[F] := Cmt;
  JParms[F] := Parms; JQPP[F] := QPP; JStTxt[F] := ''; JStat[F] := 2; JHold[F] := 0; JDev[F] := 0;
  JSize[F] := 0; JPid[F] := MyPid; JHf[F] := 0;
  JTime[F] := NowSecs(M);
  JPri[F] := ParmNum(Parms, 'PRTY=', 50);
  If (JPri[F] < 1) Or (JPri[F] > 99) Then JPri[F] := 50;
  PlaceJob(F);
  NewJob := F;
End;

Procedure FreeJob(J : LongInt);
Var B : Array[0..259] Of Byte;
Begin
  If JHf[J] <> 0 Then Dummy := DosClose(JHf[J]);
  JHf[J] := 0;
  PutZ(LongInt(@B), JobFile(J));
  Dummy := DosDelete(LongInt(@B));
  JUse[J] := 0;
End;

{ creer le fichier de spoule du travail ; FALSE si impossible }
Function CreateSpool(J : LongInt) : Boolean;
Var B : Array[0..259] Of Byte; H, A, R : LongInt;
Begin
  PutZ(LongInt(@B), JobFile(J));
  H := 0; A := 0;
  R := DosOpen(LongInt(@B), LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0);
  If R <> 0 Then
  Begin
    MkDir2(SpoolDir);
    MkDir2(SpoolDir + '\' + QName[JQ[J]]);
    R := DosOpen(LongInt(@B), LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0);
  End;
  If R = 0 Then JHf[J] := H;
  CreateSpool := R = 0;
End;

{ ==================================================================== }
{ Processeur de file d'attente (PMPRINT)                                }
{ ==================================================================== }

Function IsDevPort(S : String) : Boolean;
Begin
  S := NormPort(S);
  IsDevPort := (S = 'LPT1') Or (S = 'LPT2') Or (S = 'LPT3') Or (S = 'NUL') Or
               ((Copy(S, 1, 3) = 'COM') And (Length(S) = 4));
End;

{ ouvrir la sortie d'une imprimante (fichier : ajout a la fin) }
Function OpenOut(PortS : String; Var H : LongInt) : LongInt;
Var B : Array[0..259] Of Byte; A, R, P : LongInt;
Begin
  H := 0; A := 0;
  If IsDevPort(PortS) Then
  Begin
    PutZ(LongInt(@B), NormPort(PortS));
    R := DosOpen(LongInt(@B), LongInt(@H), LongInt(@A), 0, 0, $01, $41, 0);
  End
  Else
  Begin
    PutZ(LongInt(@B), PortS);
    R := DosOpen(LongInt(@B), LongInt(@H), LongInt(@A), 0, 0, $11, $41, 0);
    If R = 0 Then Dummy := DosSetFilePtr(H, 0, 2, LongInt(@P));
  End;
  OpenOut := R;
End;

{ ecrire N octets en entier (un peripherique peut en accepter moins) }
Function WriteAll(H, P, N : LongInt) : Boolean;
Var W, Tries : LongInt;
Begin
  Tries := 0;
  While (N > 0) And (Tries < 1000) Do
  Begin
    W := 0;
    If DosWrite(H, P, N, LongInt(@W)) <> 0 Then Tries := 1000
    Else
    Begin
      If W = 0 Then Inc(Tries);
      P := P + W; N := N - W;
    End;
  End;
  WriteAll := N = 0;
End;

{ copier un fichier vers un handle ; rend le nombre d'octets (-1 erreur) }
Function CopyTo(Name : String; HOut : LongInt) : LongInt;
Var B : Array[0..259] Of Byte; H, A, N, T : LongInt; Ok : Boolean;
Begin
  PutZ(LongInt(@B), Name);
  H := 0; A := 0;
  If DosOpen(LongInt(@B), LongInt(@H), LongInt(@A), 0, 0, $01, $40, 0) <> 0 Then
  Begin
    CopyTo := -1;
    Exit;
  End;
  T := 0; Ok := True;
  Repeat
    N := 0;
    If DosRead(H, LongInt(@CopyBuf), 4096, LongInt(@N)) <> 0 Then N := 0;
    If N > 0 Then
    Begin
      If Not WriteAll(HOut, LongInt(@CopyBuf), N) Then Ok := False;
      T := T + N;
    End;
  Until (N <= 0) Or Not Ok;
  Dummy := DosClose(H);
  If Ok Then CopyTo := T Else CopyTo := -1;
End;

Function InWindow(Q : LongInt) : Boolean;
Var M, S : LongInt;
Begin
  S := NowSecs(M);
  If QStart[Q] = QUntil[Q] Then InWindow := True
  Else If QStart[Q] < QUntil[Q] Then InWindow := (M >= QStart[Q]) And (M < QUntil[Q])
  Else InWindow := (M >= QStart[Q]) Or (M < QUntil[Q]);
End;

Procedure PrintJob(J : LongInt);
Var Q, P, H, C, Cop, R : LongInt; Tmp, Prm : String; B, B2 : Array[0..259] Of Byte; Ok : Boolean;
Begin
  Q := JQ[J]; P := QPrn[Q];
  JStat[J] := 3;
  If P >= 0 Then PJob[P] := JId[J];
  Prm := JQPP[J];
  If Prm = '' Then Prm := QParms[Q];
  Cop := ParmNum(Prm, 'COP=', 1);
  If (Cop < 1) Or (Cop > 99) Then Cop := 1;
  Ok := False;
  If (P >= 0) And (OpenOut(PPort[P], H) = 0) Then
  Begin
    Ok := True;
    If QSep[Q] <> '' Then Dummy := CopyTo(QSep[Q], H);
    For C := 1 To Cop Do
      If JType[J] = 0 Then
      Begin
        If CopyTo(JobFile(J), H) < 0 Then Ok := False;
      End
      Else
      Begin
        { PM_Q_STD : metafichier dessine par PicPrint dans un fichier }
        Tmp := Copy(JobFile(J), 1, Length(JobFile(J)) - 4) + '.PRN';
        PutZ(LongInt(@B), JobFile(J)); PutZ(LongInt(@B2), Tmp);
        R := PicPrint(0, LongInt(@B), 1, LongInt(@B2));
        If (R = 0) Or (CopyTo(Tmp, H) < 0) Then Ok := False;
        Dummy := DosDelete(LongInt(@B2));
      End;
    Dummy := DosClose(H);
  End;
  If P >= 0 Then PJob[P] := 0;
  If Ok Then FreeJob(J)
  Else
  Begin
    JStat[J] := 0;
    JDev[J] := JDev[J] Or PRJ_ERROR Or PRJ_DESTOFFLINE;
  End;
End;

{ imprimer les travaux prets (files par priorite) }
Procedure Pump;
Var Found : Boolean; Pr, Q, I, J : LongInt;
Begin
  If Pumping <> 0 Then Exit;
  Pumping := 1;
  Repeat
    Found := False;
    For Pr := 1 To 9 Do
      For Q := 0 To MaxQu - 1 Do
        If (Not Found) And (QUse[Q] <> 0) And (QPri[Q] = Pr) And (QStat[Q] = 0) And (QPrn[Q] >= 0) Then
          If (PUse[QPrn[Q]] <> 0) And (PStat[QPrn[Q]] = 0) And InWindow(Q) Then
          Begin
            SortJobs(Q);
            J := -1;
            For I := OrdN - 1 DownTo 0 Do
              If (JStat[OrdL[I]] = 0) And (JHold[OrdL[I]] = 0) And ((JDev[OrdL[I]] And PRJ_ERROR) = 0) Then
                J := OrdL[I];
            If J >= 0 Then
            Begin
              Found := True;
              PrintJob(J);
            End;
          End;
  Until Not Found;
  Pumping := 0;
End;

{ ==================================================================== }
{ Handles HSPL                                                          }
{ ==================================================================== }

Function HsIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $53500001;
  If (I < 0) Or (I >= MaxHs) Then I := -1
  Else If HUse[I] = 0 Then I := -1;
  If I < 0 Then SetErr(PMERR_SPL_INV_HSPL);
  HsIdx := I;
End;

Function OpenSpl(Q, Typ : LongInt; Cmt, QPP, Parms : String) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxHs - 1 DownTo 0 Do
    If (HUse[I] = 0) Or (KrnMonIo(0, 4, HUse[I]) = 0) And (HUse[I] <> MyPid) Then F := I;
  If F >= 0 Then
  Begin
    HUse[F] := MyPid; HQ[F] := Q; HJob[F] := -1; HType[F] := Typ; HCmt[F] := Cmt; HQPP[F] := QPP;
    HParms[F] := Parms;
  End;
  OpenSpl := F;
End;

Function StartDocI(K : LongInt; Doc : String) : Boolean;
Var J : LongInt;
Begin
  StartDocI := False;
  If HJob[K] >= 0 Then
  Begin
    SetErr(PMERR_SPL_QUEUE_ERROR);
    Exit;
  End;
  If QUse[HQ[K]] = 0 Then
  Begin
    SetErr(PMERR_SPL_QUEUE_ERROR);
    Exit;
  End;
  J := NewJob(HQ[K], HType[K], Doc, HCmt[K], HParms[K], HQPP[K]);
  If J < 0 Then
  Begin
    SetErr(PMERR_SPL_NO_FREE_JOB_ID);
    Exit;
  End;
  If Not CreateSpool(J) Then
  Begin
    JUse[J] := 0;
    SetErr(PMERR_SPL_NO_DISK_SPACE);
    Exit;
  End;
  HJob[K] := J;
  StartDocI := True;
End;

Function WriteI(K, N, P : LongInt) : Boolean;
Var J, W : LongInt;
Begin
  WriteI := False;
  If HJob[K] < 0 Then
    If Not StartDocI(K, '') Then Exit;
  J := HJob[K];
  If (N < 0) Or ((N > 0) And (P = 0)) Then
  Begin
    SetErr(PMERR_INVALID_PARAMETER);
    Exit;
  End;
  If N > 0 Then
  Begin
    W := 0;
    If (DosWrite(JHf[J], P, N, LongInt(@W)) <> 0) Or (W <> N) Then
    Begin
      SetErr(PMERR_SPL_NO_DISK_SPACE);
      Exit;
    End;
    JSize[J] := JSize[J] + N;
  End;
  WriteI := True;
End;

Function EndDocI(K : LongInt) : LongInt;
Var J : LongInt;
Begin
  EndDocI := 0;
  J := HJob[K];
  If J < 0 Then
  Begin
    SetErr(PMERR_SPL_NO_DATA);
    Exit;
  End;
  If JHf[J] <> 0 Then Dummy := DosClose(JHf[J]);
  JHf[J] := 0;
  JStat[J] := 0;
  HJob[K] := -1;
  EndDocI := JId[J];
  Pump;
End;

Procedure AbortDocI(K : LongInt);
Begin
  If HJob[K] >= 0 Then FreeJob(HJob[K]);
  HJob[K] := -1;
End;

{ ==================================================================== }
{ Points d'entree SplQm* (tampon d'impression)                          }
{ ==================================================================== }

Function SplQmOpen(PTok, N, PDop : LongInt) : LongInt;
Var Q, Typ, K : LongInt; LogS, Dt, Cmt, QPP, Parms : String;
Begin
  SplQmOpen := 0;
  EnsureInit;
  LogS := ''; Dt := ''; Cmt := ''; QPP := ''; Parms := '';
  If PDop <> 0 Then
  Begin
    If N >= 1 Then LogS := GetZ(RdL(PDop));
    If N >= 4 Then Dt := UpStr(GetZ(RdL(PDop + 12)));
    If N >= 5 Then Cmt := GetZ(RdL(PDop + 16));
    If N >= 7 Then QPP := GetZ(RdL(PDop + 24));
    If N >= 8 Then Parms := GetZ(RdL(PDop + 28));
  End;
  If (Dt = '') Or (Dt = 'PM_Q_STD') Then Typ := 1
  Else If Dt = 'PM_Q_RAW' Then Typ := 0
  Else
  Begin
    SetErr(PMERR_SPL_INV_DATATYPE);
    Exit;
  End;
  PutZ(LongInt(@KeyBuf), LogS);
  Q := QueueOf(LongInt(@KeyBuf));
  If Q < 0 Then
  Begin
    SetErr(PMERR_SPL_QUEUE_ERROR);
    Exit;
  End;
  K := OpenSpl(Q, Typ, Cmt, QPP, Parms);
  If K < 0 Then
  Begin
    SetErr(PMERR_SPL_NO_MEMORY);
    Exit;
  End;
  SplQmOpen := $53500001 + K;
End;

Function SplQmStartDoc(Hs, PDoc : LongInt) : LongInt;
Var K : LongInt;
Begin
  SplQmStartDoc := 0;
  K := HsIdx(Hs);
  If K < 0 Then Exit;
  If StartDocI(K, GetZ(PDoc)) Then SplQmStartDoc := 1;
End;

Function SplQmEndDoc(Hs : LongInt) : LongInt;
Var K : LongInt;
Begin
  SplQmEndDoc := 0;
  K := HsIdx(Hs);
  If K >= 0 Then SplQmEndDoc := EndDocI(K);
End;

Function SplQmWrite(Hs, N, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  SplQmWrite := 0;
  K := HsIdx(Hs);
  If K < 0 Then Exit;
  If WriteI(K, N, P) Then SplQmWrite := 1;
End;

Function SplQmAbort(Hs : LongInt) : LongInt;
Var K : LongInt;
Begin
  SplQmAbort := 0;
  K := HsIdx(Hs);
  If K < 0 Then Exit;
  AbortDocI(K);
  HUse[K] := 0;
  SplQmAbort := 1;
End;

Function SplQmClose(Hs : LongInt) : LongInt;
Var K : LongInt;
Begin
  SplQmClose := 0;
  K := HsIdx(Hs);
  If K < 0 Then Exit;
  If HJob[K] >= 0 Then Dummy := EndDocI(K);
  HUse[K] := 0;
  SplQmClose := 1;
End;

Function SplQmAbortDoc(Hs : LongInt) : LongInt;
Var K : LongInt;
Begin
  SplQmAbortDoc := 0;
  K := HsIdx(Hs);
  If K < 0 Then Exit;
  AbortDocI(K);
  SplQmAbortDoc := 1;
End;

Function SplInit : LongInt;
Begin
  EnsureInit;
  Pump;
  SplInit := NO_ERROR;
End;

{ ==================================================================== }
{ Ecriture des structures (chaines a la fin du tampon)                  }
{ ==================================================================== }

Procedure PkStart(P, Cb : LongInt);
Begin
  PkBuf := P; PkCb := Cb; PkFix := 0; PkStr := Cb; PkNeed := 0; PkWrite := 0;
End;

Procedure FixL(Ofs, V : LongInt);
Begin
  If PkWrite <> 0 Then WrL(PkBuf + PkFix + Ofs, V);
End;

Procedure FixW(Ofs, V : LongInt);
Begin
  If PkWrite <> 0 Then WrW(PkBuf + PkFix + Ofs, V);
End;

Procedure FixS(Ofs : LongInt; S : String);
Begin
  PkNeed := PkNeed + Length(S) + 1;
  If PkWrite <> 0 Then
  Begin
    PkStr := PkStr - Length(S) - 1;
    PutZ(PkBuf + PkStr, S);
    WrL(PkBuf + PkFix + Ofs, PkBuf + PkStr);
  End;
End;

Function PrnNameOf(Q : LongInt) : String;
Begin
  If (QPrn[Q] >= 0) And (PUse[QPrn[Q]] <> 0) Then PrnNameOf := PName[QPrn[Q]] Else PrnNameOf := '';
End;

{ PRJINFO de niveau 0, 2 ou 3 ; rend la taille fixe }
Function PutJob(J, Lv : LongInt) : LongInt;
Var Q : LongInt; Dt : String;
Begin
  Q := JQ[J];
  If Lv = 0 Then
  Begin
    FixW(0, JId[J]);
    PutJob := 2;
    Exit;
  End;
  FixW(0, JId[J]); FixW(2, JPri[J]); FixS(4, ''); FixW(8, JobPos(J)); FixW(10, JobStatus(J));
  FixL(12, JTime[J]); FixL(16, JSize[J]); FixS(20, JCmt[J]); FixS(24, JDoc[J]);
  If Lv = 2 Then
  Begin
    PutJob := 28;
    Exit;
  End;
  If JType[J] = 0 Then Dt := 'PM_Q_RAW' Else Dt := 'PM_Q_STD';
  FixS(28, ''); FixS(32, Dt); FixS(36, JParms[J]); FixS(40, JStTxt[J]); FixS(44, QName[Q]); FixS(48, QProc[Q]);
  FixS(52, JQPP[J]); FixS(56, QDrv[Q]); FixL(60, 0); FixS(64, PrnNameOf(Q));
  PutJob := 68;
End;

{ PRQINFO de niveau 3, 4 ou 6 ; rend la taille fixe }
Function PutQueue(Q, Lv : LongInt) : LongInt;
Var N, I, Sz, Sv : LongInt;
Begin
  FixS(0, QName[Q]); FixW(4, QPri[Q]); FixW(6, QStart[Q]); FixW(8, QUntil[Q]); FixW(10, QType[Q]);
  FixS(12, QSep[Q]); FixS(16, QProc[Q]); FixS(20, QParms[Q]); FixS(24, QCmt[Q]); FixW(28, QStat[Q]);
  FixW(30, QueueJobs(Q)); FixS(32, PrnNameOf(Q)); FixS(36, QDrv[Q]); FixL(40, 0);
  Sz := 44;
  If Lv = 6 Then
  Begin
    FixS(44, ''); FixS(48, '');
    Sz := 52;
  End;
  If Lv = 4 Then
  Begin
    SortJobs(Q);
    N := OrdN;
    For I := 0 To N - 1 Do
    Begin
      Sv := PkFix;
      PkFix := PkFix + Sz;
      SortJobs(Q);
      Sz := Sz + PutJob(OrdL[I], 2);
      PkFix := Sv;
    End;
  End;
  PutQueue := Sz;
End;

Function PutPrinter(P, Lv : LongInt) : LongInt;
Var K : LongInt;
Begin
  If Lv = 0 Then
  Begin
    If PkWrite <> 0 Then
      For K := 0 To 8 Do
        If K < Length(PName[P]) Then WrB(PkBuf + PkFix + K, Ord(PName[P][K + 1])) Else WrB(PkBuf + PkFix + K, 0);
    PutPrinter := 9;
    Exit;
  End;
  FixS(0, PName[P]); FixS(4, ''); FixS(8, PPort[P]); FixW(12, PJob[P]); FixW(14, PStat[P]); FixS(16, '');
  FixS(20, PCmt[P]); FixS(24, PDrv[P]); FixW(28, 0); FixW(30, 45);
  PutPrinter := 32;
End;

{ un element : 0 queue, 1 travail, 2 imprimante ; TRUE s'il a ete ecrit }
Function PutItem(Kind, I, Lv : LongInt; Var Total : LongInt) : Boolean;
Var Fx, Sv, Ns : LongInt;
Begin
  { mesure }
  PkWrite := 0; Sv := PkNeed; PkNeed := 0;
  If Kind = 0 Then Fx := PutQueue(I, Lv)
  Else If Kind = 1 Then Fx := PutJob(I, Lv)
  Else Fx := PutPrinter(I, Lv);
  Ns := PkNeed;
  PkNeed := Sv;
  Total := Total + Fx + Ns;
  If PkFix + Fx + Ns <= PkStr Then
  Begin
    PkWrite := 1;
    If Kind = 0 Then Fx := PutQueue(I, Lv)
    Else If Kind = 1 Then Fx := PutJob(I, Lv)
    Else Fx := PutPrinter(I, Lv);
    PkFix := PkFix + Fx;
    PkWrite := 0;
    PutItem := True;
  End
  Else PutItem := False;
End;

Function ListRc(Ret, Tot : LongInt) : LongInt;
Begin
  If Ret = Tot Then ListRc := NO_ERROR
  Else If Ret = 0 Then ListRc := NERR_BufTooSmall
  Else ListRc := ERROR_MORE_DATA;
End;

Function SplQmListQueues(Lv, PBuf, Cb, PcRet, PcTot, PcbNeed : LongInt) : LongInt;
Var Q, Ret, Tot, Need : LongInt; Filling : Boolean;
Begin
  EnsureInit;
  Pump;
  If (Lv <> 3) And (Lv <> 4) And (Lv <> 6) Then
  Begin
    SplQmListQueues := ERROR_INVALID_LEVEL;
    Exit;
  End;
  PkStart(PBuf, Cb);
  If PBuf = 0 Then PkStart(0, 0);
  Ret := 0; Tot := 0; Need := 0; Filling := True;
  For Q := 0 To MaxQu - 1 Do
    If QUse[Q] <> 0 Then
    Begin
      Inc(Tot);
      If Filling Then
      Begin
        If PutItem(0, Q, Lv, Need) Then Inc(Ret) Else Filling := False;
      End
      Else Dummy := LongInt(PutItem(0, Q, Lv, Need));
    End;
  If PcRet <> 0 Then WrL(PcRet, Ret);
  If PcTot <> 0 Then WrL(PcTot, Tot);
  If PcbNeed <> 0 Then WrL(PcbNeed, Need);
  SplQmListQueues := ListRc(Ret, Tot);
End;

Function SplQmQueryQInfo(PQ, Lv, PBuf, Cb, PcbNeed : LongInt) : LongInt;
Var Q, Need : LongInt;
Begin
  Q := QueueOf(PQ);
  If Q < 0 Then
  Begin
    SplQmQueryQInfo := NERR_QNotFound;
    Exit;
  End;
  Pump;
  If (Lv <> 3) And (Lv <> 4) And (Lv <> 6) Then
  Begin
    SplQmQueryQInfo := ERROR_INVALID_LEVEL;
    Exit;
  End;
  PkStart(PBuf, Cb);
  If PBuf = 0 Then PkStart(0, 0);
  Need := 0;
  If PutItem(0, Q, Lv, Need) Then SplQmQueryQInfo := NO_ERROR Else SplQmQueryQInfo := NERR_BufTooSmall;
  If PcbNeed <> 0 Then WrL(PcbNeed, Need);
End;

Function SplQmListJobs(PQ, Lv, PBuf, Cb, PcRet, PcTot, PcbNeed : LongInt) : LongInt;
Var Q, I, Ret, Tot, Need, N : LongInt; Filling : Boolean; L : Array[0..MaxJb - 1] Of LongInt;
Begin
  EnsureInit;
  Q := -1;
  If (PQ <> 0) And (GetZ(PQ) <> '') Then
  Begin
    Q := QueueOf(PQ);
    If Q < 0 Then
    Begin
      SplQmListJobs := NERR_QNotFound;
      Exit;
    End;
  End;
  Pump;
  If (Lv <> 0) And (Lv <> 2) And (Lv <> 3) Then
  Begin
    SplQmListJobs := ERROR_INVALID_LEVEL;
    Exit;
  End;
  SortJobs(Q);
  N := OrdN;
  For I := 0 To N - 1 Do L[I] := OrdL[I];
  PkStart(PBuf, Cb);
  If PBuf = 0 Then PkStart(0, 0);
  Ret := 0; Tot := N; Need := 0; Filling := True;
  For I := 0 To N - 1 Do
    If Filling Then
    Begin
      If PutItem(1, L[I], Lv, Need) Then Inc(Ret) Else Filling := False;
    End
    Else Dummy := LongInt(PutItem(1, L[I], Lv, Need));
  If PcRet <> 0 Then WrL(PcRet, Ret);
  If PcTot <> 0 Then WrL(PcTot, Tot);
  If PcbNeed <> 0 Then WrL(PcbNeed, Need);
  SplQmListJobs := ListRc(Ret, Tot);
End;

Function SplQmQueryJInfo(PQ, Id, Lv, PBuf, Cb, PcbNeed : LongInt) : LongInt;
Var J, Rc, Need : LongInt;
Begin
  J := JobOf(PQ, Id, Rc);
  If J < 0 Then
  Begin
    SplQmQueryJInfo := Rc;
    Exit;
  End;
  If (Lv <> 0) And (Lv <> 2) And (Lv <> 3) Then
  Begin
    SplQmQueryJInfo := ERROR_INVALID_LEVEL;
    Exit;
  End;
  PkStart(PBuf, Cb);
  If PBuf = 0 Then PkStart(0, 0);
  Need := 0;
  If PutItem(1, J, Lv, Need) Then SplQmQueryJInfo := NO_ERROR Else SplQmQueryJInfo := NERR_BufTooSmall;
  If PcbNeed <> 0 Then WrL(PcbNeed, Need);
End;

Function SplQmQueryPInfo(PPrn, Lv, PBuf, Cb, PcbNeed : LongInt) : LongInt;
Var P, Need : LongInt; S : String;
Begin
  EnsureInit;
  S := GetZ(PPrn);
  If S = '' Then S := DefPrinter;
  P := FindPrinter(S);
  If P < 0 Then P := PrinterOfPort(S);
  If P < 0 Then
  Begin
    SplQmQueryPInfo := NERR_DestNotFound;
    Exit;
  End;
  If (Lv <> 0) And (Lv <> 3) Then
  Begin
    SplQmQueryPInfo := ERROR_INVALID_LEVEL;
    Exit;
  End;
  PkStart(PBuf, Cb);
  If PBuf = 0 Then PkStart(0, 0);
  Need := 0;
  If PutItem(2, P, Lv, Need) Then SplQmQueryPInfo := NO_ERROR Else SplQmQueryPInfo := NERR_BufTooSmall;
  If PcbNeed <> 0 Then WrL(PcbNeed, Need);
End;

{ ==================================================================== }
{ Gestion des files et des travaux                                      }
{ ==================================================================== }

Function SplQmHoldQueue(PQ : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := QueueOf(PQ);
  If Q < 0 Then
  Begin
    SplQmHoldQueue := NERR_QNotFound;
    Exit;
  End;
  QStat[Q] := 1;
  SaveQueue(Q);
  SplQmHoldQueue := NO_ERROR;
End;

Function SplQmReleaseQueue(PQ : LongInt) : LongInt;
Var Q : LongInt;
Begin
  Q := QueueOf(PQ);
  If Q < 0 Then
  Begin
    SplQmReleaseQueue := NERR_QNotFound;
    Exit;
  End;
  QStat[Q] := 0;
  SaveQueue(Q);
  Pump;
  SplQmReleaseQueue := NO_ERROR;
End;

Function SplQmHoldJob(PQ, Id : LongInt) : LongInt;
Var J, Rc : LongInt;
Begin
  J := JobOf(PQ, Id, Rc);
  If J >= 0 Then JHold[J] := 1;
  SplQmHoldJob := Rc;
End;

Function SplQmReleaseJob(PQ, Id : LongInt) : LongInt;
Var J, Rc : LongInt;
Begin
  J := JobOf(PQ, Id, Rc);
  If J >= 0 Then
  Begin
    JHold[J] := 0;
    Pump;
  End;
  SplQmReleaseJob := Rc;
End;

Function SplQmCancelJob(PQ, Id : LongInt) : LongInt;
Var J, Rc, K : LongInt;
Begin
  J := JobOf(PQ, Id, Rc);
  If J >= 0 Then
  Begin
    If (JStat[J] = 2) And (JPid[J] <> MyPid) Then Rc := NERR_JobInvalidState
    Else
    Begin
      For K := 0 To MaxHs - 1 Do
        If (HUse[K] <> 0) And (HJob[K] = J) Then HJob[K] := -1;
      FreeJob(J);
    End;
  End;
  SplQmCancelJob := Rc;
End;

Function SplQmRestartJob(PQ, Id : LongInt) : LongInt;
Var J, Rc : LongInt;
Begin
  J := JobOf(PQ, Id, Rc);
  If J >= 0 Then
  Begin
    If JStat[J] = 2 Then Rc := NERR_JobInvalidState
    Else
    Begin
      JHold[J] := 0;
      JDev[J] := 0;
      JStat[J] := 0;
      Pump;
    End;
  End;
  SplQmRestartJob := Rc;
End;

Function SplQmRepeatJob(PQ, Id, PNew : LongInt) : LongInt;
Var J, Rc, N, H, Sz : LongInt;
Begin
  J := JobOf(PQ, Id, Rc);
  If J >= 0 Then
  Begin
    If JStat[J] = 2 Then Rc := NERR_JobInvalidState
    Else
    Begin
      N := NewJob(JQ[J], JType[J], JDoc[J], JCmt[J], JParms[J], JQPP[J]);
      If N < 0 Then Rc := NERR_JobNoRoom
      Else If Not CreateSpool(N) Then
      Begin
        JUse[N] := 0;
        Rc := NERR_JobNoRoom;
      End
      Else
      Begin
        Sz := CopyTo(JobFile(J), JHf[N]);
        H := JHf[N];
        Dummy := DosClose(H);
        JHf[N] := 0;
        If Sz < 0 Then Sz := 0;
        JSize[N] := Sz; JPri[N] := JPri[J];
        JSeq[N] := JSeq[J] + 5;
        Renumber(JQ[J]);
        JStat[N] := 0;
        If PNew <> 0 Then WrL(PNew, JId[N]);
        Pump;
      End;
    End;
  End;
  SplQmRepeatJob := Rc;
End;

Function SplQmPrintJobNext(PQ, Id : LongInt) : LongInt;
Var J, Rc : LongInt;
Begin
  J := JobOf(PQ, Id, Rc);
  If J >= 0 Then
  Begin
    JSeq[J] := -1;
    Renumber(JQ[J]);
    Pump;
  End;
  SplQmPrintJobNext := Rc;
End;

Function SplQmChangeJobPrty(PQ, Id, Pri : LongInt) : LongInt;
Var J, Rc : LongInt;
Begin
  J := JobOf(PQ, Id, Rc);
  If J >= 0 Then
  Begin
    If (Pri < 1) Or (Pri > 99) Then Rc := ERROR_INVALID_PARAMETER
    Else
    Begin
      JPri[J] := Pri;
      PlaceJob(J);
      Pump;
    End;
  End;
  SplQmChangeJobPrty := Rc;
End;

Function SplQmWriteFile(PQ, PFile, PDoc, PJob : LongInt) : LongInt;
Var Q, J, Sz : LongInt; Doc : String;
Begin
  Q := QueueOf(PQ);
  If Q < 0 Then
  Begin
    SplQmWriteFile := NERR_QNotFound;
    Exit;
  End;
  If PFile = 0 Then
  Begin
    SplQmWriteFile := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Doc := GetZ(PDoc);
  If Doc = '' Then Doc := GetZ(PFile);
  J := NewJob(Q, 0, Doc, '', '', '');
  If J < 0 Then
  Begin
    SplQmWriteFile := NERR_JobNoRoom;
    Exit;
  End;
  If Not CreateSpool(J) Then
  Begin
    JUse[J] := 0;
    SplQmWriteFile := NERR_JobNoRoom;
    Exit;
  End;
  Sz := CopyTo(GetZ(PFile), JHf[J]);
  Dummy := DosClose(JHf[J]);
  JHf[J] := 0;
  If Sz < 0 Then
  Begin
    FreeJob(J);
    SplQmWriteFile := 2;           { ERROR_FILE_NOT_FOUND }
    Exit;
  End;
  JSize[J] := Sz;
  JStat[J] := 0;
  If PJob <> 0 Then WrL(PJob, JId[J]);
  Pump;
  SplQmWriteFile := NO_ERROR;
End;

Function SplQmSetStatus(PQ, Id, Fs, PTxt : LongInt) : LongInt;
Var J, Rc : LongInt;
Begin
  J := JobOf(PQ, Id, Rc);
  If J >= 0 Then
  Begin
    JDev[J] := Fs And $0FFC;
    If PTxt <> 0 Then JStTxt[J] := GetZ(PTxt);
  End;
  SplQmSetStatus := Rc;
End;

Function SplQmCreateQueue(Lv, P, Cb : LongInt) : LongInt;
Var N, Pr, Pn, PortS, Drv : String; Q, PIx, K, Dq : LongInt;
Begin
  EnsureInit;
  SplQmCreateQueue := ERROR_INVALID_PARAMETER;
  If (Lv <> 3) And (Lv <> 6) Then
  Begin
    SplQmCreateQueue := ERROR_INVALID_LEVEL;
    Exit;
  End;
  If (P = 0) Or ((Lv = 3) And (Cb < 44)) Or ((Lv = 6) And (Cb < 52)) Then Exit;
  N := GetZ(RdL(P));
  If (N = '') Or (Length(N) > 12) Or (Pos(';', N) > 0) Or (Pos('\', N) > 0) Then Exit;
  If FindQueue(N) >= 0 Then
  Begin
    SplQmCreateQueue := NERR_QExists;
    Exit;
  End;
  { imprimante : nom, port, ou nom=port }
  Pr := GetZ(RdL(P + 32));
  Drv := GetZ(RdL(P + 36));
  If Drv = '' Then Drv := 'IBMNULL';
  PIx := -1;
  If Pr = '' Then
  Begin
    Dq := FindQueue(DefQueue);
    If Dq >= 0 Then PIx := QPrn[Dq];
  End
  Else
  Begin
    K := Pos('=', Pr);
    If K > 0 Then
    Begin
      Pn := Copy(Pr, 1, K - 1); PortS := Copy(Pr, K + 1, 255);
    End
    Else
    Begin
      Pn := Pr; PortS := Pr;
    End;
    PIx := FindPrinter(Pn);
    If (PIx < 0) And (K = 0) Then PIx := PrinterOfPort(PortS);
    If PIx < 0 Then
    Begin
      PIx := AddPrinter(Pn, PortS, Drv, 'Imprimante sur ' + PortS);
      If PIx < 0 Then
      Begin
        SplQmCreateQueue := NERR_DestNoRoom;
        Exit;
      End;
    End
    Else If K > 0 Then PPort[PIx] := PortS;
  End;
  If PIx < 0 Then
  Begin
    SplQmCreateQueue := NERR_DestNotFound;
    Exit;
  End;
  Q := AddQueue(N, PIx);
  If Q < 0 Then
  Begin
    SplQmCreateQueue := NERR_QNoRoom;
    Exit;
  End;
  QPri[Q] := RdL(P + 4) And $FFFF;
  If (QPri[Q] < 1) Or (QPri[Q] > 9) Then QPri[Q] := 5;
  QStart[Q] := RdL(P + 6) And $FFFF; QUntil[Q] := RdL(P + 8) And $FFFF; QType[Q] := RdL(P + 10) And $FFFF;
  QSep[Q] := GetZ(RdL(P + 12)); QProc[Q] := GetZ(RdL(P + 16)); QParms[Q] := GetZ(RdL(P + 20));
  QCmt[Q] := GetZ(RdL(P + 24)); QDrv[Q] := Drv;
  If QProc[Q] = '' Then QProc[Q] := 'PMPRINT';
  SaveQueue(Q);
  If DefQueue = '' Then
  Begin
    DefQueue := N;
    PrfW('PM_SPOOLER', 'QUEUE', N + ';');
  End;
  SplQmCreateQueue := NO_ERROR;
End;

Function SplQmDestroyQueue(PQ : LongInt) : LongInt;
Var Q, J, I : LongInt; N : String;
Begin
  EnsureInit;
  N := GetZ(PQ);
  Q := FindQueue(N);
  If (Q < 0) Or (N = '') Then
  Begin
    SplQmDestroyQueue := NERR_QNotFound;
    Exit;
  End;
  For J := 0 To MaxJb - 1 Do
    If (JUse[J] <> 0) And (JQ[J] = Q) And (JStat[J] = 2) Then
    Begin
      SplQmDestroyQueue := NERR_QInvalidState;
      Exit;
    End;
  For J := 0 To MaxJb - 1 Do
    If (JUse[J] <> 0) And (JQ[J] = Q) Then FreeJob(J);
  For I := 0 To MaxHs - 1 Do
    If (HUse[I] <> 0) And (HQ[I] = Q) Then HUse[I] := 0;
  PrfDel('PM_SPOOLER_QUEUE', QName[Q]);
  PrfDel('PM_SPOOLER_QUEUE_DESCR', QName[Q]);
  QUse[Q] := 0;
  If QPrn[Q] >= 0 Then SavePrinter(QPrn[Q]);
  If UpStr(DefQueue) = UpStr(QName[Q]) Then
  Begin
    DefQueue := '';
    For I := MaxQu - 1 DownTo 0 Do
      If QUse[I] <> 0 Then DefQueue := QName[I];
    PrfW('PM_SPOOLER', 'QUEUE', DefQueue + ';');
  End;
  SplQmDestroyQueue := NO_ERROR;
End;

{ liste de noms (chaines terminees par un nul, un nul de plus) }
Function NameList(Kind, PBuf, Cb, PcRet : LongInt) : LongInt;
Var I, N, Need, Ofs : LongInt; S : String;
Begin
  EnsureInit;
  N := 0; Need := 1;
  For I := 0 To 15 Do
  Begin
    S := '';
    If Kind = 0 Then
    Begin
      If (I < MaxQu) And (QUse[I] <> 0) Then S := QName[I];
    End
    Else If (I < 3) And (KrnMonIo(2 + I, 5, 0) <> 0) Then S := 'LPT' + IStr(I + 1);
    If S <> '' Then
    Begin
      Inc(N);
      Need := Need + Length(S) + 1;
    End;
  End;
  If PcRet <> 0 Then WrL(PcRet, N);
  If (PBuf = 0) Or (Cb < Need) Then
  Begin
    NameList := NERR_BufTooSmall;
    Exit;
  End;
  Ofs := 0;
  For I := 0 To 15 Do
  Begin
    S := '';
    If Kind = 0 Then
    Begin
      If (I < MaxQu) And (QUse[I] <> 0) Then S := QName[I];
    End
    Else If (I < 3) And (KrnMonIo(2 + I, 5, 0) <> 0) Then S := 'LPT' + IStr(I + 1);
    If S <> '' Then
    Begin
      PutZ(PBuf + Ofs, S);
      Ofs := Ofs + Length(S) + 1;
    End;
  End;
  WrB(PBuf + Ofs, 0);
  NameList := NO_ERROR;
End;

Function SplQmListAvailQueues(PBuf, Cb, PcRet : LongInt) : LongInt;
Begin
  SplQmListAvailQueues := NameList(0, PBuf, Cb, PcRet);
End;

Function SplQmListDirectPrinters(PBuf, Cb, PcRet : LongInt) : LongInt;
Begin
  SplQmListDirectPrinters := NameList(1, PBuf, Cb, PcRet);
End;

Function SplQmQueryPrintData(Id, Off, PBuf, Cb, PcbRead : LongInt) : LongInt;
Var J, H, A, N, P : LongInt; B : Array[0..259] Of Byte;
Begin
  EnsureInit;
  J := JobIdx(Id);
  If PcbRead <> 0 Then WrL(PcbRead, 0);
  If J < 0 Then
  Begin
    SplQmQueryPrintData := NERR_JobNotFound;
    Exit;
  End;
  If (PBuf = 0) Or (Cb < 0) Or (Off < 0) Then
  Begin
    SplQmQueryPrintData := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  PutZ(LongInt(@B), JobFile(J));
  H := 0; A := 0; N := 0;
  If DosOpen(LongInt(@B), LongInt(@H), LongInt(@A), 0, 0, $01, $40, 0) = 0 Then
  Begin
    If DosSetFilePtr(H, Off, 0, LongInt(@P)) = 0 Then
      If DosRead(H, PBuf, Cb, LongInt(@N)) <> 0 Then N := 0;
    Dummy := DosClose(H);
  End;
  If PcbRead <> 0 Then WrL(PcbRead, N);
  SplQmQueryPrintData := NO_ERROR;
End;

Function SplQmUpdateQProcParms(PQ, Id, PParms : LongInt) : LongInt;
Var Q, J, Rc : LongInt;
Begin
  If Id = 0 Then
  Begin
    Q := QueueOf(PQ);
    If Q < 0 Then
    Begin
      SplQmUpdateQProcParms := NERR_QNotFound;
      Exit;
    End;
    QParms[Q] := GetZ(PParms);
    SaveQueue(Q);
    SplQmUpdateQProcParms := NO_ERROR;
  End
  Else
  Begin
    J := JobOf(PQ, Id, Rc);
    If J >= 0 Then JQPP[J] := GetZ(PParms);
    SplQmUpdateQProcParms := Rc;
  End;
End;

{ ==================================================================== }
{ Boite de message du tampon d'impression                               }
{ ==================================================================== }

{ procedure de la fenetre du delai (exportee : convention _System) }
Function SplMsgBoxTimerProc(Hw, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var A : LongInt;
Begin
  If Msg = WM_TIMER Then
  Begin
    MbFired := 1;
    A := WinQueryActiveWindow(HWND_DESKTOP);
    If A <> 0 Then Dummy := WinDismissDlg(A, MBID_RETRY);
    SplMsgBoxTimerProc := 0;
  End
  Else SplMsgBoxTimerProc := WinDefWindowProc(Hw, Msg, Mp1, Mp2);
End;

Function SplMessageBox(PLog, ErrInfo, ErrData, PText, PCap, Id, Style : LongInt) : LongInt;
Var Txt, Cap, LogS : String; Hab, Hmq, Hw, Tmo, R, Hm : LongInt; Own : Boolean;
    TB, CB, NB : Array[0..259] Of Byte;
Begin
  EnsureInit;
  Txt := GetZ(PText); LogS := GetZ(PLog);
  If LogS <> '' Then Txt := Txt + ' (imprimante : ' + LogS + ')';
  If (ErrData And $0001) <> 0 Then Txt := Txt + ' Bourrage de papier.';
  If (ErrData And $0002) <> 0 Then Txt := Txt + ' Changement de formulaire requis.';
  If (ErrData And $0004) <> 0 Then Txt := Txt + ' Changement de cartouche requis.';
  If (ErrData And $0008) <> 0 Then Txt := Txt + ' Changement de plume requis.';
  If (ErrData And $0010) <> 0 Then Txt := Txt + ' Erreur dans les donnees.';
  If (ErrData And $0020) <> 0 Then Txt := Txt + ' Erreur inattendue.';
  If (ErrData And $8000) <> 0 Then Txt := Txt + ' Autre erreur.';
  Cap := GetZ(PCap);
  If PCap = 0 Then Cap := 'Gestionnaire d''impression';
  If (Style And $F0) = 0 Then
  Begin
    If (ErrInfo And $0C00) <> 0 Then Style := Style Or $40
    Else If (ErrInfo And $0200) <> 0 Then Style := Style Or $20
    Else If (ErrInfo And $0100) <> 0 Then Style := Style Or $30;
  End;
  PutZ(LongInt(@TB), Copy(Txt, 1, 250));
  PutZ(LongInt(@CB), Copy(Cap, 1, 250));
  { file de messages }
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Own := Hmq <> 0;
  { delai : fenetre objet et minuterie }
  Tmo := StrToI(PrfQ('PM_SPOOLER', 'MSGTIMEOUT'), 180);
  Hw := 0;
  If Tmo > 0 Then
  Begin
    If MbProc = 0 Then
    Begin
      PutZ(LongInt(@NB), 'PMSPL');
      Hm := 0;
      If DosQueryModuleHandle(LongInt(@NB), LongInt(@Hm)) = 0 Then
        If DosQueryProcAddr(Hm, 1001, 0, LongInt(@MbProc)) <> 0 Then MbProc := 0;
    End;
    If MbProc <> 0 Then
    Begin
      PutZ(LongInt(@NB), 'PMSplMsgTimer');
      Dummy := WinRegisterClass(Hab, LongInt(@NB), MbProc, 0, 0);
      Hw := WinCreateWindow(HWND_OBJECT, LongInt(@NB), 0, 0, 0, 0, 0, 0, 0, HWND_TOP, 0, 0, 0);
      If Hw <> 0 Then Dummy := WinStartTimer(Hab, Hw, 1, Tmo * 1000);
    End;
  End;
  MbFired := 0;
  R := WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, LongInt(@TB), LongInt(@CB), Id, Style);
  If Hw <> 0 Then
  Begin
    Dummy := WinStopTimer(Hab, Hw, 1);
    Dummy := WinDestroyWindow(Hw);
  End;
  If MbFired <> 0 Then R := MBID_RETRY;
  If Own Then
  Begin
    Dummy := WinDestroyMsgQueue(Hmq);
    Dummy := WinTerminate(Hab);
  End;
  SplMessageBox := R;
End;

{ ==================================================================== }
{ Donnees PM_Q_STD (metafichier enregistre sur un DC de PMGPI)          }
{ ==================================================================== }

Function StdIdx(Hdc : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := MaxSd - 1 DownTo 0 Do
    If (SUse[I] <> 0) And (SHdc[I] = Hdc) Then R := I;
  StdIdx := R;
End;

Function SplStdOpen(Hdc : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  SplStdOpen := 0;
  If Hdc = 0 Then
  Begin
    SetErr(PMERR_INVALID_PARAMETER);
    Exit;
  End;
  F := StdIdx(Hdc);
  If F < 0 Then
    For I := MaxSd - 1 DownTo 0 Do
      If (SUse[I] = 0) Or (KrnMonIo(0, 4, SUse[I]) = 0) And (SUse[I] <> MyPid) Then F := I;
  If F < 0 Then
  Begin
    SetErr(PMERR_SPL_NO_MEMORY);
    Exit;
  End;
  SUse[F] := MyPid; SHdc[F] := Hdc; SHmf[F] := 0;
  SplStdOpen := 1;
End;

Function SplStdStart(Hdc : LongInt) : LongInt;
Var K : LongInt;
Begin
  SplStdStart := 0;
  K := StdIdx(Hdc);
  If K < 0 Then
  Begin
    SetErr(PMERR_SPL_INV_HSPL);
    Exit;
  End;
  If SHmf[K] <> 0 Then Exit;
  If GpiStdStart(Hdc) <> 0 Then
  Begin
    SHmf[K] := 1;
    SplStdStart := 1;
  End;
End;

Function SplStdStop(Hdc : LongInt) : LongInt;
Var K : LongInt;
Begin
  SplStdStop := 0;
  K := StdIdx(Hdc);
  If (K < 0) Or (SHmf[K] = 0) Then
  Begin
    SetErr(PMERR_SPL_NO_DATA);
    Exit;
  End;
  SHmf[K] := 0;
  SplStdStop := GpiStdStop(Hdc);
End;

Function SplStdClose(Hdc : LongInt) : LongInt;
Var K, M : LongInt;
Begin
  SplStdClose := 0;
  K := StdIdx(Hdc);
  If K < 0 Then
  Begin
    SetErr(PMERR_SPL_INV_HSPL);
    Exit;
  End;
  If SHmf[K] <> 0 Then
  Begin
    M := GpiStdStop(Hdc);
    If M <> 0 Then Dummy := GpiDeleteMetaFile(M);
  End;
  SUse[K] := 0;
  SplStdClose := 1;
End;

Function SplStdDelete(Hst : LongInt) : LongInt;
Begin
  SplStdDelete := GpiDeleteMetaFile(Hst);
End;

Function SplStdGetBits(Hst, Off, Cb, P : LongInt) : LongInt;
Var L : LongInt;
Begin
  SplStdGetBits := 0;
  L := GpiQueryMetaFileLength(Hst);
  If (L < 0) Or (Off < 0) Or (Cb < 0) Or (Off + Cb > L) Or (P = 0) Then
  Begin
    SetErr(PMERR_INVALID_PARAMETER);
    Exit;
  End;
  SplStdGetBits := GpiQueryMetaFileBits(Hst, Off, Cb, P);
End;

Function SplStdQueryLength(Hst : LongInt) : LongInt;
Begin
  SplStdQueryLength := GpiQueryMetaFileLength(Hst);
End;

{ ==================================================================== }
{ Acces a l'imprimante (Prt*)                                           }
{ ==================================================================== }

Function PtIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $50540001;
  If (I < 0) Or (I >= MaxPt) Then I := -1
  Else If TUse[I] = 0 Then I := -1;
  PtIdx := I;
End;

Function PrtOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, Res : LongInt) : LongInt;
Var T, I, P, Q, K, H, Lpt : LongInt; Dev : String;
Begin
  EnsureInit;
  T := -1;
  For I := MaxPt - 1 DownTo 0 Do
    If (TUse[I] = 0) Or (KrnMonIo(0, 4, TUse[I]) = 0) And (TUse[I] <> MyPid) Then T := I;
  If (T < 0) Or (PHf = 0) Or (PName = 0) Then
  Begin
    If T < 0 Then PrtOpen := 4 Else PrtOpen := ERROR_INVALID_PARAMETER;   { ERROR_TOO_MANY_OPEN_FILES }
    Exit;
  End;
  Dev := NormPort(GetZ(PName));
  P := PrinterOfPort(Dev);
  Q := -1;
  If P >= 0 Then
  Begin
    Q := FindQueue(DefQueue);
    If (Q >= 0) And (QPrn[Q] <> P) Then Q := -1;
    If Q < 0 Then
      For I := MaxQu - 1 DownTo 0 Do
        If (QUse[I] <> 0) And (QPrn[I] = P) Then Q := I;
  End;
  Lpt := 0;
  If (Length(Dev) = 4) And (Copy(Dev, 1, 3) = 'LPT') Then Lpt := Ord(Dev[4]) - 48;
  TUse[T] := MyPid; TPrn[T] := Lpt; TCpl[T] := 80; TLpi[T] := 6; TRetry[T] := 0; TCp[T] := 0; TFont[T] := 0;
  If Q >= 0 Then
  Begin
    { travail PM_Q_RAW de la file de l'imprimante }
    K := OpenSpl(Q, 0, '', '', '');
    If (K < 0) Or Not StartDocI(K, Dev) Then
    Begin
      If K >= 0 Then HUse[K] := 0;
      TUse[T] := 0;
      PrtOpen := 4;
      Exit;
    End;
    TKind[T] := 1; TH[T] := K;
    If PAct <> 0 Then WrL(PAct, 1);
  End
  Else
  Begin
    H := 0;
    I := DosOpen(PName, LongInt(@H), PAct, Cb, Attr, Fl, Mode, 0);
    If I <> 0 Then
    Begin
      TUse[T] := 0;
      PrtOpen := I;
      Exit;
    End;
    TKind[T] := 2; TH[T] := H;
  End;
  WrL(PHf, $50540001 + T);
  PrtOpen := NO_ERROR;
End;

Function PrtWrite(Hf, P, Cb, PW : LongInt) : LongInt;
Var T : LongInt;
Begin
  T := PtIdx(Hf);
  If T < 0 Then
  Begin
    PrtWrite := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If TKind[T] = 1 Then
  Begin
    If WriteI(TH[T], Cb, P) Then
    Begin
      If PW <> 0 Then WrL(PW, Cb);
      PrtWrite := NO_ERROR;
    End
    Else
    Begin
      If PW <> 0 Then WrL(PW, 0);
      PrtWrite := 112;              { ERROR_DISK_FULL }
    End;
  End
  Else PrtWrite := DosWrite(TH[T], P, Cb, PW);
End;

Function PrtClose(Hf : LongInt) : LongInt;
Var T : LongInt;
Begin
  T := PtIdx(Hf);
  If T < 0 Then
  Begin
    PrtClose := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If TKind[T] = 1 Then
  Begin
    If HJob[TH[T]] >= 0 Then Dummy := EndDocI(TH[T]);
    HUse[TH[T]] := 0;
    PrtClose := NO_ERROR;
  End
  Else PrtClose := DosClose(TH[T]);
  TUse[T] := 0;
End;

Function PrtAbort(Hf : LongInt) : LongInt;
Var T : LongInt;
Begin
  T := PtIdx(Hf);
  If T < 0 Then
  Begin
    PrtAbort := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If TKind[T] = 1 Then
  Begin
    AbortDocI(TH[T]);
    HUse[TH[T]] := 0;
    PrtAbort := NO_ERROR;
  End
  Else PrtAbort := DosClose(TH[T]);
  TUse[T] := 0;
End;

{ etat de l'imprimante (format d'INT 17h) }
Function PortStatus(T : LongInt) : LongInt;
Var B : LongInt;
Begin
  B := 0;
  If (TPrn[T] >= 1) And (TPrn[T] <= 3) Then B := KrnMonIo(1 + TPrn[T], 5, 0);
  If (TKind[T] = 1) Or (B = 0) Then PortStatus := $90
  Else PortStatus := (InB(B + 1) And $F8) Xor $48;
End;

Function PrtDevIOCtl(PData, PParm, Fn, Cat, Hf : LongInt) : LongInt;
Var T, B, N1, N2, I : LongInt;
Begin
  T := PtIdx(Hf);
  If T < 0 Then
  Begin
    PrtDevIOCtl := ERROR_INVALID_HANDLE;
    Exit;
  End;
  PrtDevIOCtl := NO_ERROR;
  If Cat <> 5 Then
  Begin
    If TKind[T] = 2 Then
    Begin
      N1 := 0; N2 := 0;
      PrtDevIOCtl := DosDevIOCtl(TH[T], Cat, Fn, PParm, 16, LongInt(@N1), PData, 16, LongInt(@N2));
    End
    Else PrtDevIOCtl := 22;          { ERROR_BAD_COMMAND }
    Exit;
  End;
  Case Fn Of
    $42 : If PData <> 0 Then
          Begin
            TCpl[T] := RdB(PData); TLpi[T] := RdB(PData + 1);
          End;
    $44 : If PData <> 0 Then TRetry[T] := RdB(PData);
    $46 : Begin
            If (TKind[T] = 2) And (TPrn[T] >= 1) And (TPrn[T] <= 3) Then
            Begin
              B := KrnMonIo(1 + TPrn[T], 5, 0);
              If B <> 0 Then
              Begin
                OutB(B + 2, $08);
                For I := 0 To 1000 Do Dummy := InB($80);
                OutB(B + 2, $0C);
              End;
            End;
            If PData <> 0 Then WrB(PData, PortStatus(T));
          End;
    $48 : If PData <> 0 Then
          Begin
            TCp[T] := RdB(PData) Or (RdB(PData + 1) Shl 8); TFont[T] := RdB(PData + 2) Or (RdB(PData + 3) Shl 8);
          End;
    $62 : If PData <> 0 Then
          Begin
            WrB(PData, TCpl[T]); WrB(PData + 1, TLpi[T]);
          End;
    $64 : If PData <> 0 Then WrB(PData, TRetry[T]);
    $66 : If PData <> 0 Then WrB(PData, PortStatus(T));
    $69 : If PData <> 0 Then
          Begin
            WrW(PData, TCp[T]); WrW(PData + 2, TFont[T]);
          End;
    $6A : ;
  Else
    PrtDevIOCtl := 22;
  End;
End;

{ SplRing3(pfn, ulParam) }
Function SplRing3(Pfn, Prm : LongInt) : LongInt;
Begin
  If Pfn = 0 Then SplRing3 := 0 Else SplRing3 := Call1(Pfn, Prm);
End;

Exports
  SplQmOpen Index 1 Name 'SPLQMOPEN',
  SplQmStartDoc Index 2 Name 'SPLQMSTARTDOC',
  SplQmEndDoc Index 3 Name 'SPLQMENDDOC',
  SplQmWrite Index 4 Name 'SPLQMWRITE',
  SplQmAbort Index 5 Name 'SPLQMABORT',
  SplQmClose Index 6 Name 'SPLQMCLOSE',
  SplMessageBox Index 7 Name 'SPLMESSAGEBOX',
  SplQmAbortDoc Index 8 Name 'SPLQMABORTDOC',
  SplInit Index 20 Name 'SPLINIT',
  SplQmListQueues Index 21 Name 'SPLQMLISTQUEUES',
  SplQmQueryQInfo Index 22 Name 'SPLQMQUERYQINFO',
  SplQmListJobs Index 23 Name 'SPLQMLISTJOBS',
  SplQmQueryJInfo Index 24 Name 'SPLQMQUERYJINFO',
  SplQmHoldQueue Index 25 Name 'SPLQMHOLDQUEUE',
  SplQmReleaseQueue Index 26 Name 'SPLQMRELEASEQUEUE',
  SplQmHoldJob Index 27 Name 'SPLQMHOLDJOB',
  SplQmReleaseJob Index 28 Name 'SPLQMRELEASEJOB',
  SplQmCancelJob Index 29 Name 'SPLQMCANCELJOB',
  SplQmRestartJob Index 30 Name 'SPLQMRESTARTJOB',
  SplQmRepeatJob Index 31 Name 'SPLQMREPEATJOB',
  SplQmPrintJobNext Index 32 Name 'SPLQMPRINTJOBNEXT',
  SplQmQueryPInfo Index 33 Name 'SPLQMQUERYPINFO',
  SplQmChangeJobPrty Index 34 Name 'SPLQMCHANGEJOBPRTY',
  SplQmWriteFile Index 35 Name 'SPLQMWRITEFILE',
  SplQmSetStatus Index 36 Name 'SPLQMSETSTATUS',
  SplQmCreateQueue Index 37 Name 'SPLQMCREATEQUEUE',
  SplQmDestroyQueue Index 38 Name 'SPLQMDESTROYQUEUE',
  SplQmListAvailQueues Index 39 Name 'SPLQMLISTAVAILQUEUES',
  SplQmListDirectPrinters Index 40 Name 'SPLQMLISTDIRECTPRINTERS',
  SplQmQueryPrintData Index 41 Name 'SPLQMQUERYPRINTDATA',
  SplQmUpdateQProcParms Index 42 Name 'SPLQMUPDATEQPROCPARMS',
  SplStdOpen Index 50 Name 'SPLSTDOPEN',
  SplStdClose Index 51 Name 'SPLSTDCLOSE',
  SplStdStart Index 52 Name 'SPLSTDSTART',
  SplStdStop Index 53 Name 'SPLSTDSTOP',
  SplStdDelete Index 54 Name 'SPLSTDDELETE',
  SplStdGetBits Index 55 Name 'SPLSTDGETBITS',
  SplStdQueryLength Index 56 Name 'SPLSTDQUERYLENGTH',
  PrtOpen Index 70 Name 'PRTOPEN',
  PrtWrite Index 71 Name 'PRTWRITE',
  PrtDevIOCtl Index 72 Name 'PRTDEVIOCTL',
  PrtClose Index 73 Name 'PRTCLOSE',
  PrtAbort Index 75 Name 'PRTABORT',
  SplRing3 Index 90 Name 'SPLRING3',
  SplMsgBoxTimerProc Index 1001 Name 'SPLMSGBOXTIMERPROC';

Begin
End.
