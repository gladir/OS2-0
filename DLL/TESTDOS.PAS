{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de DOSCALLS.DLL sous OS/2-0.
}

Program TESTDOS;

{ Compilation : OS2PC TESTDOS.PAS   (produit TESTDOS.EXE)

  Appelle un echantillon des fonctions Dos* de DOSCALLS.DLL (fichiers,
  repertoires, recherche, memoire, semaphores, minuteries, tuyaux,
  processus legers, execution de programmes, exceptions, modules, pays,
  messages...) et affiche OK ou ECHEC pour chaque verification. }

{ --- Declarations des fonctions de DOSCALLS.DLL (convention _System) --- }
Function DosBeep(Freq, Dur : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosQuerySysInfo(IStart, ILast, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetInfoBlocks(PPTib, PPPib : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDir(Disk, PBuf, PCb : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, Cb, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, Cb, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosDeleteDir(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosCopy(PSrc, PDst, Opt : LongInt) : LongInt; External 'DOSCALLS';
Function DosMove(POld, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeMem(Pb : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryMem(Pb, PCb, PFlag : LongInt) : LongInt; External 'DOSCALLS';
Function DosSubSetMem(Base, Flag, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosSubAllocMem(Base, PPb, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosSubFreeMem(Base, Pb, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocSeg(Size, PSel, Flags : LongInt) : LongInt; External 'DOSCALLS';
Function DosSizeSeg(Sel, PSize : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeSeg(Sel : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateEventSem(PName, PHev, Attr, State : LongInt) : LongInt; External 'DOSCALLS';
Function DosPostEventSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosResetEventSem(H, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosWaitEventSem(H, Timeout : LongInt) : LongInt; External 'DOSCALLS';
Function DosCloseEventSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosAsyncTimer(Msec, HSem, PHTimer : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateMutexSem(PName, PH, Attr, State : LongInt) : LongInt; External 'DOSCALLS';
Function DosRequestMutexSem(H, Timeout : LongInt) : LongInt; External 'DOSCALLS';
Function DosReleaseMutexSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreatePipe(PRead, PWrite, Size : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateNPipe(PName, PH, OMode, PMode, CbOut, CbIn, Msec : LongInt) : LongInt; External 'DOSCALLS';
Function DosConnectNPipe(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt; External 'DOSCALLS';
Function DosWaitThread(PTid, Option : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosMapCase(Cb, Pcc, PCh : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCtryInfo(Cb, Pcc, Pci, PcbActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosTrueGetMessage(PTab, CTab, PBuf, Cb, Num, PFile, PcbMsg, Seg : LongInt) : LongInt; External 'DOSCALLS';
Function DosErrClass(Code, PClass, PAction, PLocus : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetExceptionHandler(PReg : LongInt) : LongInt; External 'DOSCALLS';
Function DosUnsetExceptionHandler(PReg : LongInt) : LongInt; External 'DOSCALLS';
Function DosRaiseException(PExc : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryModuleName(H, Cb, PBuf : LongInt) : LongInt; External 'DOSCALLS';
Function DosEditName(Level, PSrc, PEdit, PTarget, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetVersion(PVer : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Msec : LongInt) : LongInt; External 'DOSCALLS';

Type
  PLong = ^LongInt;
  PByte = ^Byte;

Var
  Ok, Fail : LongInt;
  H, H2, Act, N, R, I, Pb, Pb2, Sel, Hev, Hmtx, Tmr, Tid, Hd, Cnt, HMod, Pfn : LongInt;
  Buf : Array[0..1023] Of Byte;
  Buf2 : Array[0..255] Of Byte;
  Info : Array[0..15] Of LongInt;
  Res : Array[0..1] Of LongInt;
  RegRec : Array[0..1] Of LongInt;
  ExcRec : Array[0..15] Of LongInt;
  ThreadHits, HandlerHits : LongInt;
  Name : Array[0..127] Of Byte;
  Name2 : Array[0..127] Of Byte;
  Tab : Array[0..1] Of LongInt;

Function PeekL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  PeekL := P^;
End;

Function PeekB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  PeekB := P^;
End;

Function GetStr(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  N := 0;
  While (PeekB(A + N) <> 0) And (N < 255) Do
  Begin
    S := S + Chr(PeekB(A + N));
    Inc(N);
  End;
  GetStr := S;
End;

{ Chaine Pascal -> ASCIIZ dans Name (N = 0) ou Name2 (N = 1) }
Function Z(S : String; N : LongInt) : LongInt;
Var I, A : LongInt; P : PByte;
Begin
  If N = 0 Then A := LongInt(@Name) Else A := LongInt(@Name2);
  For I := 1 To Length(S) Do
  Begin
    P := Pointer(A + I - 1);
    P^ := Ord(S[I]);
  End;
  P := Pointer(A + Length(S));
  P^ := 0;
  Z := A;
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Procedure Check(What : String; Cond : Boolean);
Begin
  If Cond Then
  Begin
    Inc(Ok);
    WriteLn('  OK     ', What);
  End
  Else
  Begin
    Inc(Fail);
    WriteLn('  ECHEC  ', What);
  End;
End;

{ Processus leger : un seul parametre (convention _System) }
Function ThreadFn(Param : LongInt) : LongInt;
Begin
  ThreadHits := ThreadHits + Param;
  ThreadFn := 0;
End;

{ Gestionnaire d'exception : handler(pReport, pRegRec, pContext, pDispatch)
  en convention _System, donc parametres Pascal dans l'ordre inverse }
Function Handler(PDisp, PCtx, PReg, PRep : LongInt) : LongInt;
Begin
  Inc(HandlerHits);
  If PeekL(PRep) = $C000009B Then
    WriteLn('  Gestionnaire : XCPT_INTEGER_DIVIDE_BY_ZERO recue');
  If PeekL(PRep) = $E0000001 Then Handler := -1     { XCPT_CONTINUE_EXECUTION }
  Else Handler := 0;
End;

BEGIN
  Ok := 0; Fail := 0;
  WriteLn('TESTDOS : essai de DOSCALLS.DLL');

  { --- systeme --- }
  Check('DosGetVersion = 20.00', (DosGetVersion(LongInt(@Info)) = 0) And ((Info[0] And $FFFF) = $1400));
  R := DosQuerySysInfo(1, 26, LongInt(@Buf), 1024);
  Check('DosQuerySysInfo (chemin 260, unite C:, page 4 Ko)',
        (R = 0) And (PeekL(LongInt(@Buf)) = 260) And (PeekL(LongInt(@Buf) + 16) = 3) And
        (PeekL(LongInt(@Buf) + 36) = 4096));
  Check('DosGetDateTime (annee >= 2024)', (DosGetDateTime(LongInt(@Buf)) = 0) And
        (PeekB(LongInt(@Buf) + 6) + PeekB(LongInt(@Buf) + 7) * 256 >= 2024));
  R := DosGetInfoBlocks(LongInt(@Info[0]), LongInt(@Info[1]));
  Check('DosGetInfoBlocks (PID ' + IStr(PeekL(Info[1])) + ', programme ' + GetStr(PeekL(Info[1] + 12)) + ')',
        (R = 0) And (PeekL(Info[1]) >= 2));
  N := 256;
  Check('DosQueryCurrentDir', DosQueryCurrentDir(0, LongInt(@Buf2), LongInt(@N)) = 0);
  Check('DosQueryCurrentDisk = 3 (C:)', (DosQueryCurrentDisk(LongInt(@Info[2]), LongInt(@Info[3])) = 0) And
        (Info[2] = 3));
  Check('DosBeep(880, 50)', DosBeep(880, 50) = 0);

  { --- fichiers --- }
  R := DosOpen(Z('C:\ESSAI.DAT', 0), LongInt(@H), LongInt(@Act), 0, 0, $12, $22, 0);
  Check('DosOpen (creation)', (R = 0) And (Act = 2));
  For I := 0 To 99 Do Buf[I] := I;
  Check('DosWrite 100 octets', (DosWrite(H, LongInt(@Buf), 100, LongInt(@N)) = 0) And (N = 100));
  Check('DosSetFilePtr debut', (DosSetFilePtr(H, 10, 0, LongInt(@N)) = 0) And (N = 10));
  Check('DosRead 5 octets', (DosRead(H, LongInt(@Buf2), 5, LongInt(@N)) = 0) And (N = 5) And (Buf2[0] = 10));
  Check('DosClose', DosClose(H) = 0);
  Check('DosQueryPathInfo (taille 100)', (DosQueryPathInfo(Z('C:\ESSAI.DAT', 0), 1, LongInt(@Buf), 24) = 0) And
        (PeekL(LongInt(@Buf) + 12) = 100));
  Check('DosCopy', DosCopy(Z('C:\ESSAI.DAT', 0), Z('C:\ESSAI2.DAT', 1), 0) = 0);
  Check('DosMove', DosMove(Z('C:\ESSAI2.DAT', 0), Z('C:\ESSAI3.DAT', 1)) = 0);
  Check('DosDelete', DosDelete(Z('C:\ESSAI3.DAT', 0)) = 0);
  Check('DosCreateDir', DosCreateDir(Z('C:\TESTDIR', 0), 0) = 0);
  Check('DosDeleteDir', DosDeleteDir(Z('C:\TESTDIR', 0)) = 0);
  Hd := -1; Cnt := 10;
  R := DosFindFirst(Z('C:\*.EXE', 0), LongInt(@Hd), 0, LongInt(@Buf), 1024, LongInt(@Cnt), 1);
  Check('DosFindFirst *.EXE (' + IStr(Cnt) + ' entrees, ' + GetStr(LongInt(@Buf) + 29) + ')',
        (R = 0) And (Cnt >= 1));
  DosFindClose(Hd);
  Check('DosEditName (*.TXT -> *.BAK)', (DosEditName(1, Z('NOTES.TXT', 0), Z('*.BAK', 1), LongInt(@Buf2), 64) = 0) And
        (GetStr(LongInt(@Buf2)) = 'NOTES.BAK'));
  Check('DosScanEnv PATH', (DosScanEnv(Z('PATH', 0), LongInt(@Pb)) = 0) And (GetStr(Pb) <> ''));

  { --- memoire --- }
  Check('DosAllocMem 10 Ko', DosAllocMem(LongInt(@Pb), 10000, $13) = 0);
  N := 100000;
  Check('DosQueryMem', (DosQueryMem(Pb, LongInt(@N), LongInt(@I)) = 0) And (N >= 10000) And
        ((I And $10000) <> 0));
  Check('DosSubSetMem', DosSubSetMem(Pb, 1, 10000) = 0);
  Check('DosSubAllocMem', (DosSubAllocMem(Pb, LongInt(@Pb2), 100) = 0) And (Pb2 > Pb));
  Check('DosSubFreeMem', DosSubFreeMem(Pb, Pb2, 100) = 0);
  Check('DosFreeMem', DosFreeMem(Pb) = 0);
  Check('DosAllocSeg / DosSizeSeg / DosFreeSeg', (DosAllocSeg(1000, LongInt(@Sel), 0) = 0) And
        (DosSizeSeg(Sel, LongInt(@N)) = 0) And (N = 1000) And (DosFreeSeg(Sel) = 0));

  { --- semaphores et minuteries --- }
  Check('DosCreateEventSem', DosCreateEventSem(0, LongInt(@Hev), 0, 0) = 0);
  Check('DosWaitEventSem (0 ms, non poste) = ERROR_TIMEOUT', DosWaitEventSem(Hev, 0) = 640);
  Check('DosPostEventSem', DosPostEventSem(Hev) = 0);
  Check('DosWaitEventSem (poste)', DosWaitEventSem(Hev, -1) = 0);
  Check('DosResetEventSem', (DosResetEventSem(Hev, LongInt(@N)) = 0) And (N = 1));
  N := 0;
  Check('DosAsyncTimer 200 ms', DosAsyncTimer(200, Hev, LongInt(@Tmr)) = 0);
  I := 0;
  R := DosWaitEventSem(Hev, -1);
  Check('DosWaitEventSem (minuterie)', R = 0);
  Check('DosCloseEventSem', DosCloseEventSem(Hev) = 0);
  Check('DosCreateMutexSem / Request / Release', (DosCreateMutexSem(0, LongInt(@Hmtx), 0, 0) = 0) And
        (DosRequestMutexSem(Hmtx, -1) = 0) And (DosRequestMutexSem(Hmtx, -1) = 0) And
        (DosReleaseMutexSem(Hmtx) = 0) And (DosReleaseMutexSem(Hmtx) = 0) And
        (DosReleaseMutexSem(Hmtx) = 288));

  { --- tuyaux --- }
  Check('DosCreatePipe', DosCreatePipe(LongInt(@H), LongInt(@H2), 4096) = 0);
  Check('DosWrite dans le tuyau', (DosWrite(H2, Z('Bonjour', 0), 7, LongInt(@N)) = 0) And (N = 7));
  Check('DosRead du tuyau', (DosRead(H, LongInt(@Buf2), 100, LongInt(@N)) = 0) And (N = 7) And
        (Chr(Buf2[0]) = 'B'));
  DosClose(H); DosClose(H2);
  Check('DosCreateNPipe \PIPE\ESSAI', DosCreateNPipe(Z('\PIPE\ESSAI', 0), LongInt(@H), 2, 8, 512, 512, 0) = 0);
  R := DosOpen(Z('\PIPE\ESSAI', 0), LongInt(@H2), LongInt(@Act), 0, 0, 1, 2, 0);
  Check('DosOpen \PIPE\ESSAI (client)', R = 0);
  Check('DosConnectNPipe (connecte)', DosConnectNPipe(H) = 0);
  DosWrite(H2, Z('ping', 0), 4, LongInt(@N));
  Check('tuyau nomme client -> serveur', (DosRead(H, LongInt(@Buf2), 100, LongInt(@N)) = 0) And (N = 4));
  DosClose(H2); DosClose(H);

  { --- processus legers et programmes --- }
  ThreadHits := 0;
  { le fil s'execute en parallele : son effet est verifie apres DosWaitThread }
  Check('DosCreateThread', DosCreateThread(LongInt(@Tid), LongInt(@ThreadFn), 5, 0, 8192) = 0);
  Check('DosWaitThread (fil termine, ThreadHits = 5)', (DosWaitThread(LongInt(@Tid), 0) = 0) And (ThreadHits = 5));
  FillChar(Buf, 64, 0);
  I := Z('C:\TREE.EXE', 0);
  Check('DosExecPgm TREE.EXE', DosExecPgm(LongInt(@Buf2), 64, 0, 0, 0, LongInt(@Res), I) = 0);
  Check('  code de fin = 0 (TC_EXIT)', Res[0] = 0);
  Check('DosExecPgm INEXISTANT.EXE = 2', DosExecPgm(LongInt(@Buf2), 64, 0, 0, 0, LongInt(@Res),
        Z('C:\INEXISTANT.EXE', 1)) = 2);

  { --- exceptions --- }
  HandlerHits := 0;
  RegRec[0] := 0; RegRec[1] := LongInt(@Handler);
  Check('DosSetExceptionHandler', DosSetExceptionHandler(LongInt(@RegRec)) = 0);
  FillChar(ExcRec, 64, 0);
  ExcRec[0] := $E0000001;
  Check('DosRaiseException (reprise par le gestionnaire)', (DosRaiseException(LongInt(@ExcRec)) = 0) And
        (HandlerHits = 1));
  Check('DosUnsetExceptionHandler', DosUnsetExceptionHandler(LongInt(@RegRec)) = 0);

  { --- modules, pays, messages --- }
  Check('DosQueryModuleHandle DOSCALLS', (DosQueryModuleHandle(Z('DOSCALLS', 0), LongInt(@HMod)) = 0) And
        (HMod = $00C00000));
  Check('DosQueryProcAddr DosBeep', (DosQueryProcAddr(HMod, 0, Z('DosBeep', 0), LongInt(@Pfn)) = 0) And
        (Pfn > HMod));
  Check('DosQueryModuleName', (DosQueryModuleName(HMod, 128, LongInt(@Buf2)) = 0) And
        (GetStr(LongInt(@Buf2)) = 'C:\DOSCALLS.DLL'));
  Info[0] := 0; Info[1] := 0;
  Check('DosQueryCtryInfo (Canada, separateur decimal ",")',
        (DosQueryCtryInfo(44, LongInt(@Info), LongInt(@Buf), LongInt(@N)) = 0) And
        (PeekL(LongInt(@Buf)) = 2) And (Chr(Buf[19]) = ','));
  Z('ete', 0); Name[0] := $82;
  Check('DosMapCase (page 850 : e accent aigu -> E accent aigu)',
        (DosMapCase(3, LongInt(@Info), LongInt(@Name)) = 0) And (Name[0] = $90) And (Chr(Name[1]) = 'T'));
  Tab[0] := Z('ESSAI.DAT', 1);
  R := DosTrueGetMessage(LongInt(@Tab), 1, LongInt(@Buf), 256, 2, Z('OSO001.MSG', 0), LongInt(@N), 0);
  Buf[N] := 0;
  Check('DosTrueGetMessage SYS0002', (R = 0) And (Pos('ESSAI.DAT', GetStr(LongInt(@Buf))) > 0));
  Write('    '); WriteLn(GetStr(LongInt(@Buf)));
  Check('DosErrClass(2) = introuvable', (DosErrClass(2, LongInt(@Info[0]), LongInt(@Info[1]), LongInt(@Info[2])) = 0) And
        (Info[0] = 8));
  DosDelete(Z('C:\ESSAI.DAT', 0));

  WriteLn;
  WriteLn('TESTDOS : ', Ok, ' reussi(s), ', Fail, ' echec(s).');

  { TESTDOS TRAP : exception materielle (division par zero) avec un
    gestionnaire OS/2 : le gestionnaire est appele, puis le runtime
    affiche Runtime error 200 et le processus se termine }
  If (ParamCount > 0) And (ParamStr(1) = 'TRAP') Then
  Begin
    HandlerHits := 0;
    DosSetExceptionHandler(LongInt(@RegRec));
    WriteLn('Division par zero...');
    N := 0;
    N := 10 Div N;
    WriteLn('non atteint');
  End;
END.
