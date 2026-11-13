{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de PMSPL.DLL sous OS/2-0.
}

Program TESTSPL;

{$R-,S-,I-}

{ Compilation : OS2PC TESTSPL.PAS   (produit TESTSPL.EXE)

  TESTSPL verifie PMSPL.DLL : ses 44 ordinaux, la file d'attente par
  defaut (LPT1Q, PRINTER1 sur LPT1), la creation d'une file dont
  l'imprimante ecrit dans le fichier D:\SORTIE.PRN, les travaux PM_Q_RAW
  (SplQmOpen, SplQmStartDoc, SplQmWrite, SplQmEndDoc, SplQmClose), leur
  gestion (liste, informations, priorite, passage en tete, retenue,
  etat, copie, annulation, lecture des donnees, copies COP=n,
  liberation de la file), un port en erreur, SplQmWriteFile, l'acces a
  l'imprimante (PrtOpen, PrtWrite, PrtDevIOCtl, PrtClose et PrtAbort ;
  la sortie va a LPT1), l'enregistrement PM_Q_STD (SplStd*), un DC
  OD_QUEUED de PMGPI.DLL imprime par PicPrint (graphique ESC/P),
  SplMessageBox (delai MSGTIMEOUT de 2 secondes : MBID_RETRY ; l'ecran
  passe brievement en mode graphique) et SplRing3. }

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS';

Function SplQmOpen(T, N, P : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMOPEN';
Function SplQmStartDoc(H, P : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMSTARTDOC';
Function SplQmEndDoc(H : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMENDDOC';
Function SplQmWrite(H, N, P : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMWRITE';
Function SplQmAbort(H : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMABORT';
Function SplQmClose(H : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMCLOSE';
Function SplMessageBox(L, I, D, T, C, Id, St : LongInt) : LongInt; External 'PMSPL' Name 'SPLMESSAGEBOX';
Function SplQmAbortDoc(H : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMABORTDOC';
Function SplInit : LongInt; External 'PMSPL' Name 'SPLINIT';
Function SplQmListQueues(Lv, P, Cb, PR, PT, PN : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMLISTQUEUES';
Function SplQmQueryQInfo(Q, Lv, P, Cb, PN : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMQUERYQINFO';
Function SplQmListJobs(Q, Lv, P, Cb, PR, PT, PN : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMLISTJOBS';
Function SplQmQueryJInfo(Q, J, Lv, P, Cb, PN : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMQUERYJINFO';
Function SplQmHoldQueue(Q : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMHOLDQUEUE';
Function SplQmReleaseQueue(Q : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMRELEASEQUEUE';
Function SplQmHoldJob(Q, J : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMHOLDJOB';
Function SplQmReleaseJob(Q, J : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMRELEASEJOB';
Function SplQmCancelJob(Q, J : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMCANCELJOB';
Function SplQmRestartJob(Q, J : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMRESTARTJOB';
Function SplQmRepeatJob(Q, J, PN : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMREPEATJOB';
Function SplQmPrintJobNext(Q, J : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMPRINTJOBNEXT';
Function SplQmQueryPInfo(P, Lv, B, Cb, PN : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMQUERYPINFO';
Function SplQmChangeJobPrty(Q, J, Pr : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMCHANGEJOBPRTY';
Function SplQmWriteFile(Q, F, D, PJ : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMWRITEFILE';
Function SplQmSetStatus(Q, J, Fs, PT : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMSETSTATUS';
Function SplQmCreateQueue(Lv, P, Cb : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMCREATEQUEUE';
Function SplQmDestroyQueue(Q : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMDESTROYQUEUE';
Function SplQmListAvailQueues(P, Cb, PR : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMLISTAVAILQUEUES';
Function SplQmListDirectPrinters(P, Cb, PR : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMLISTDIRECTPRINTERS';
Function SplQmQueryPrintData(J, Off, P, Cb, PR : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMQUERYPRINTDATA';
Function SplQmUpdateQProcParms(Q, J, P : LongInt) : LongInt; External 'PMSPL' Name 'SPLQMUPDATEQPROCPARMS';
Function SplStdOpen(H : LongInt) : LongInt; External 'PMSPL' Name 'SPLSTDOPEN';
Function SplStdClose(H : LongInt) : LongInt; External 'PMSPL' Name 'SPLSTDCLOSE';
Function SplStdStart(H : LongInt) : LongInt; External 'PMSPL' Name 'SPLSTDSTART';
Function SplStdStop(H : LongInt) : LongInt; External 'PMSPL' Name 'SPLSTDSTOP';
Function SplStdDelete(H : LongInt) : LongInt; External 'PMSPL' Name 'SPLSTDDELETE';
Function SplStdGetBits(H, Off, Cb, P : LongInt) : LongInt; External 'PMSPL' Name 'SPLSTDGETBITS';
Function SplStdQueryLength(H : LongInt) : LongInt; External 'PMSPL' Name 'SPLSTDQUERYLENGTH';
Function PrtOpen(P, PH, PA, Cb, At, Fl, Md, R : LongInt) : LongInt; External 'PMSPL' Name 'PRTOPEN';
Function PrtWrite(H, P, Cb, PW : LongInt) : LongInt; External 'PMSPL' Name 'PRTWRITE';
Function PrtDevIOCtl(PD, PP, Fn, Cat, H : LongInt) : LongInt; External 'PMSPL' Name 'PRTDEVIOCTL';
Function PrtClose(H : LongInt) : LongInt; External 'PMSPL' Name 'PRTCLOSE';
Function PrtAbort(H : LongInt) : LongInt; External 'PMSPL' Name 'PRTABORT';
Function SplRing3(F, P : LongInt) : LongInt; External 'PMSPL' Name 'SPLRING3';

Function DevOpenDC(Hab, Typ, PTok, N, PDop, HComp : LongInt) : LongInt; External 'PMGPI';
Function DevCloseDC(H : LongInt) : LongInt; External 'PMGPI';
Function DevEscape(H, Code, NIn, PIn, PNOut, POut : LongInt) : LongInt; External 'PMGPI';
Function GpiCreatePS(Hab, Hdc, PSize, Fl : LongInt) : LongInt; External 'PMGPI';
Function GpiDestroyPS(Hps : LongInt) : LongInt; External 'PMGPI';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE';
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';

Const
  NOrd = 44;
  Ords : Array[0..43] Of Word = (1, 2, 3, 4, 5, 6, 7, 8, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
    33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 50, 51, 52, 53, 54, 55, 56, 70, 71, 72, 73, 75, 90);

Var
  Ok, Fail, R, R2, I, N, A, B, P, Hmod, Hs, Hdc, Hps, Hst, Hf, J1, J2, J3, J4, J5, NR, NT, NN : LongInt;
  Name, Name2, Buf, SBuf : Array[0..1023] Of Byte;
  Info : Array[0..2047] Of Byte;
  Dop : Array[0..8] Of LongInt;
  Q3 : Array[0..12] Of LongInt;
  Pt : Array[0..3] Of LongInt;
  OutBuf : Array[0..8191] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function RdL(A : LongInt) : LongInt;
Type PLong = ^LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Function RdB(A : LongInt) : LongInt;
Type PByte = ^Byte;
Var Q : PByte;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Function RdW(A : LongInt) : LongInt;
Begin
  RdW := RdB(A) + RdB(A + 1) * 256;
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

Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Name[K - 1] := Ord(S[K]);
  Name[Length(S)] := 0;
  Z := LongInt(@Name);
End;

Function Z2(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Name2[K - 1] := Ord(S[K]);
  Name2[Length(S)] := 0;
  Z2 := LongInt(@Name2);
End;

{ chaine dans SBuf a partir de l'octet Ofs }
Function Zs(Ofs : LongInt; S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do SBuf[Ofs + K - 1] := Ord(S[K]);
  SBuf[Ofs + Length(S)] := 0;
  Zs := LongInt(@SBuf) + Ofs;
End;

{ contenu d'un fichier (255 octets au plus) }
Function FileStr(S : String) : String;
Var H, A, N, K : LongInt; T : String;
Begin
  T := ''; H := 0; A := 0; N := 0;
  If DosOpen(Z(S), LongInt(@H), LongInt(@A), 0, 0, 1, $40, 0) = 0 Then
  Begin
    If DosRead(H, LongInt(@Buf), 255, LongInt(@N)) <> 0 Then N := 0;
    DosClose(H);
  End;
  For K := 0 To N - 1 Do T := T + Chr(Buf[K]);
  FileStr := T;
End;

Procedure OutStr(T : String);
Var K : LongInt;
Begin
  For K := 1 To Length(T) Do
    If OutLen < 8190 Then
    Begin
      OutBuf[OutLen] := Ord(T[K]);
      Inc(OutLen);
    End;
End;

Procedure Check(What : String; Cond : Boolean);
Begin
  If Cond Then
  Begin
    Inc(Ok);
    OutStr('  OK     ' + What + Chr(13) + Chr(10));
  End
  Else
  Begin
    Inc(Fail);
    OutStr('  ECHEC  ' + What + '  (code ' + IStr(R) + ')' + Chr(13) + Chr(10));
  End;
End;

{ fonction appelee par SplRing3 (programme OS2PC : convention Pascal) }
Function Ring3Fn(V : LongInt) : LongInt;
Begin
  Ring3Fn := V * 2;
End;

{ numero du travail a la position I d'une liste de niveau 0 }
Function JobAt(I : LongInt) : LongInt;
Begin
  JobAt := RdW(LongInt(@Info) + I * 2);
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTSPL : essai de PMSPL.DLL');

  { --- ordinaux --- }
  Hmod := 0;
  R := DosQueryModuleHandle(Z('PMSPL'), LongInt(@Hmod));
  N := 0;
  For I := 0 To NOrd - 1 Do
  Begin
    P := 0;
    If DosQueryProcAddr(Hmod, Ords[I], 0, LongInt(@P)) = 0 Then
      If P <> 0 Then Inc(N);
  End;
  P := 0; A := 0;
  R := DosQueryProcAddr(Hmod, 0, Z('SPLQMLISTDIRECTPRINTERS'), LongInt(@P));
  R2 := DosQueryProcAddr(Hmod, 0, Z('PRTDEVIOCTL'), LongInt(@A));
  Check('44 ordinaux de PMSPL (' + IStr(N) + '), noms SPLQMLISTDIRECTPRINTERS et PRTDEVIOCTL', (N = 44) And
        (P <> 0) And (A <> 0));

  { --- file par defaut --- }
  R := SplInit;
  R2 := SplQmListQueues(3, LongInt(@Info), 2048, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  Check('SplInit, SplQmListQueues niveau 3 (' + IStr(NR) + ' : ' + GetZ(RdL(LongInt(@Info))) + ', ' +
        GetZ(RdL(LongInt(@Info) + 32)) + ')', (R = 0) And (R2 = 0) And (NR >= 1) And (NT = NR) And
        (GetZ(RdL(LongInt(@Info))) = 'LPT1Q') And (GetZ(RdL(LongInt(@Info) + 32)) = 'PRINTER1') And
        (GetZ(RdL(LongInt(@Info) + 16)) = 'PMPRINT') And (RdW(LongInt(@Info) + 4) = 5));
  R := SplQmListQueues(3, LongInt(@Info), 20, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  Check('tampon trop petit : NERR_BufTooSmall, pcbNeeded (' + IStr(NN) + ')', (R = 2123) And (NR = 0) And (NN > 44));
  R := SplQmQueryPInfo(Z('PRINTER1'), 3, LongInt(@Info), 2048, LongInt(@NN));
  Check('SplQmQueryPInfo niveau 3 (' + GetZ(RdL(LongInt(@Info) + 8)) + ', ' + GetZ(RdL(LongInt(@Info) + 24)) + ')',
        (R = 0) And (GetZ(RdL(LongInt(@Info) + 8)) = 'LPT1') And (GetZ(RdL(LongInt(@Info) + 24)) = 'IBMNULL'));
  R := SplQmQueryPInfo(Z('PRINTER1'), 0, LongInt(@Info), 2048, LongInt(@NN));
  R2 := SplQmQueryPInfo(Z('ABSENTE'), 3, LongInt(@Info) + 100, 2048, LongInt(@NN));
  Check('SplQmQueryPInfo niveau 0, imprimante inconnue (NERR_DestNotFound)', (R = 0) And
        (GetZ(LongInt(@Info)) = 'PRINTER1') And (R2 = 2152));
  R := SplQmListDirectPrinters(LongInt(@Info), 2048, LongInt(@NR));
  Check('SplQmListDirectPrinters (' + IStr(NR) + ' : ' + GetZ(LongInt(@Info)) + ')', (R = 0) And (NR >= 1) And
        (GetZ(LongInt(@Info)) = 'LPT1'));
  B := PrfQueryProfileString(-2, Z('PM_SPOOLER_QUEUE'), Z2('LPT1Q'), 0, LongInt(@Buf), 200);
  Check('profil du systeme : PM_SPOOLER_QUEUE LPT1Q (' + GetZ(LongInt(@Buf)) + ')',
        Copy(GetZ(LongInt(@Buf)), 1, 9) = 'PRINTER1;');

  { --- nouvelle file : imprimante ecrivant dans D:\SORTIE.PRN --- }
  R := DosDelete(Z('D:\SORTIE.PRN'));
  For I := 0 To 12 Do Q3[I] := 0;
  Q3[0] := Zs(0, 'ESSAIQ'); Q3[1] := 3;                   { priorite 3 }
  Q3[6] := Zs(100, 'File d''essai');
  Q3[8] := Zs(200, 'ESSAI=D:\SORTIE.PRN');
  R := SplQmCreateQueue(3, LongInt(@Q3), 44);
  R2 := SplQmCreateQueue(3, LongInt(@Q3), 44);
  Check('SplQmCreateQueue, deuxieme fois : NERR_QExists', (R = 0) And (R2 = 2154));
  R := SplQmQueryQInfo(Z('ESSAIQ'), 3, LongInt(@Info), 2048, LongInt(@NN));
  Check('SplQmQueryQInfo (' + GetZ(RdL(LongInt(@Info) + 24)) + ', priorite ' + IStr(RdW(LongInt(@Info) + 4)) + ')',
        (R = 0) And (GetZ(RdL(LongInt(@Info) + 24)) = 'File d''essai') And (RdW(LongInt(@Info) + 4) = 3) And
        (GetZ(RdL(LongInt(@Info) + 32)) = 'ESSAI'));
  R := SplQmQueryPInfo(Z('ESSAI'), 3, LongInt(@Info), 2048, LongInt(@NN));
  R2 := SplQmListAvailQueues(LongInt(@Buf), 1024, LongInt(@NR));
  Check('imprimante ESSAI (' + GetZ(RdL(LongInt(@Info) + 8)) + '), SplQmListAvailQueues (' + IStr(NR) + ')',
        (R = 0) And (GetZ(RdL(LongInt(@Info) + 8)) = 'D:\SORTIE.PRN') And (R2 = 0) And (NR = 2) And
        (GetZ(LongInt(@Buf)) = 'LPT1Q') And (GetZ(LongInt(@Buf) + 6) = 'ESSAIQ') And (Buf[13] = 0));
  R := SplQmHoldQueue(Z('ESSAIQ'));
  R2 := SplQmQueryQInfo(Z('ESSAIQ'), 3, LongInt(@Info), 2048, LongInt(@NN));
  Check('SplQmHoldQueue (etat ' + IStr(RdW(LongInt(@Info) + 28)) + ')', (R = 0) And (RdW(LongInt(@Info) + 28) = 1));

  { --- travaux PM_Q_RAW --- }
  For I := 0 To 8 Do Dop[I] := 0;
  Dop[0] := Zs(0, 'ESSAIQ'); Dop[1] := Zs(20, 'IBMNULL'); Dop[3] := Zs(40, 'PM_Q_RAW');
  Dop[4] := Zs(60, 'Commentaire'); Dop[7] := Zs(80, 'PRTY=60');
  Hs := SplQmOpen(Z('*'), 8, LongInt(@Dop));
  R := SplQmStartDoc(Hs, Z('Document 1'));
  R2 := SplQmWrite(Hs, 6, Z('ABCDEF'));
  J1 := SplQmEndDoc(Hs);
  Check('SplQmOpen, SplQmStartDoc, SplQmWrite, SplQmEndDoc (travail ' + IStr(J1) + ')', ((Hs Shr 16) = $5350) And
        (R = 1) And (R2 = 1) And (J1 > 0));
  R := SplQmStartDoc(Hs, Z('Document 2'));
  R2 := SplQmWrite(Hs, 3, Z('XYZ'));
  J2 := SplQmEndDoc(Hs);
  R := SplQmWrite(Hs, 3, Z('123'));
  R2 := SplQmClose(Hs);
  Check('deuxieme document ; SplQmWrite sans SplQmStartDoc, SplQmClose', (J2 > 0) And (J2 <> J1) And (R = 1) And
        (R2 = 1) And (SplQmWrite(Hs, 1, Z('x')) = 0));
  R := SplQmListJobs(Z('ESSAIQ'), 2, LongInt(@Info), 2048, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  J3 := RdW(LongInt(@Info) + 56);
  Check('SplQmListJobs niveau 2 (' + IStr(NR) + ' travaux : ' + GetZ(RdL(LongInt(@Info) + 24)) + ', ' +
        GetZ(RdL(LongInt(@Info) + 52)) + ')', (R = 0) And (NR = 3) And (RdW(LongInt(@Info)) = J1) And
        (RdW(LongInt(@Info) + 28) = J2) And (RdW(LongInt(@Info) + 8) = 1) And (RdW(LongInt(@Info) + 36) = 2) And
        (RdL(LongInt(@Info) + 16) = 6) And (RdL(LongInt(@Info) + 44) = 3) And (RdW(LongInt(@Info) + 10) = 0) And
        (GetZ(RdL(LongInt(@Info) + 24)) = 'Document 1') And (GetZ(RdL(LongInt(@Info) + 52)) = 'Document 2') And
        (RdL(LongInt(@Info) + 12) > 1500000000));
  R := SplQmQueryJInfo(Z('ESSAIQ'), J1, 3, LongInt(@Info), 2048, LongInt(@NN));
  Check('SplQmQueryJInfo niveau 3 (' + GetZ(RdL(LongInt(@Info) + 32)) + ', ' + GetZ(RdL(LongInt(@Info) + 64)) +
        ', priorite ' + IStr(RdW(LongInt(@Info) + 2)) + ')', (R = 0) And
        (GetZ(RdL(LongInt(@Info) + 32)) = 'PM_Q_RAW') And (GetZ(RdL(LongInt(@Info) + 44)) = 'ESSAIQ') And
        (GetZ(RdL(LongInt(@Info) + 48)) = 'PMPRINT') And (GetZ(RdL(LongInt(@Info) + 64)) = 'ESSAI') And
        (GetZ(RdL(LongInt(@Info) + 20)) = 'Commentaire') And (GetZ(RdL(LongInt(@Info) + 36)) = 'PRTY=60') And
        (RdW(LongInt(@Info) + 2) = 60));
  R := SplQmQueryJInfo(Z('LPT1Q'), J1, 2, LongInt(@Info), 2048, LongInt(@NN));
  R2 := SplQmQueryJInfo(0, 9998, 2, LongInt(@Info), 2048, LongInt(@NN));
  Check('travail d''une autre file, travail inconnu : NERR_JobNotFound', (R = 2151) And (R2 = 2151));
  R := SplQmChangeJobPrty(Z('ESSAIQ'), J3, 90);
  R2 := SplQmListJobs(Z('ESSAIQ'), 0, LongInt(@Info), 2048, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  Check('SplQmChangeJobPrty (90 : en tete), liste de niveau 0', (R = 0) And (R2 = 0) And (NR = 3) And
        (JobAt(0) = J3) And (JobAt(1) = J1) And (JobAt(2) = J2));
  R := SplQmPrintJobNext(Z('ESSAIQ'), J2);
  R2 := SplQmListJobs(Z('ESSAIQ'), 0, LongInt(@Info), 2048, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  Check('SplQmPrintJobNext', (R = 0) And (JobAt(0) = J2) And (JobAt(1) = J3) And (JobAt(2) = J1));
  R := SplQmHoldJob(Z('ESSAIQ'), J1);
  R2 := SplQmQueryJInfo(0, J1, 2, LongInt(@Info), 2048, LongInt(@NN));
  Check('SplQmHoldJob (etat ' + IStr(RdW(LongInt(@Info) + 10)) + ')', (R = 0) And (RdW(LongInt(@Info) + 10) = 1));
  R := SplQmSetStatus(Z('ESSAIQ'), J2, $0100, Z2('Plus de papier'));
  R2 := SplQmQueryJInfo(0, J2, 3, LongInt(@Info), 2048, LongInt(@NN));
  Check('SplQmSetStatus (PRJ_DESTNOPAPER, ' + GetZ(RdL(LongInt(@Info) + 40)) + ')', (R = 0) And
        (RdW(LongInt(@Info) + 10) = $0100) And (GetZ(RdL(LongInt(@Info) + 40)) = 'Plus de papier'));
  For I := 0 To 9 Do Buf[I] := 0;
  R := SplQmQueryPrintData(J1, 2, LongInt(@Buf), 3, LongInt(@NR));
  Check('SplQmQueryPrintData (' + GetZ(LongInt(@Buf)) + ')', (R = 0) And (NR = 3) And (GetZ(LongInt(@Buf)) = 'CDE'));
  J4 := 0;
  R := SplQmRepeatJob(Z('ESSAIQ'), J2, LongInt(@J4));
  R2 := SplQmQueryJInfo(0, J4, 2, LongInt(@Info), 2048, LongInt(@NN));
  Check('SplQmRepeatJob (travail ' + IStr(J4) + ', position ' + IStr(RdW(LongInt(@Info) + 8)) + ')', (R = 0) And
        (J4 > 0) And (R2 = 0) And (RdL(LongInt(@Info) + 16) = 3) And (RdW(LongInt(@Info) + 8) = 2));
  R := SplQmCancelJob(Z('ESSAIQ'), J4);
  R2 := SplQmQueryJInfo(0, J4, 2, LongInt(@Info), 2048, LongInt(@NN));
  Check('SplQmCancelJob', (R = 0) And (R2 = 2151));
  R := SplQmUpdateQProcParms(Z('ESSAIQ'), J2, Z2('COP=2'));
  R2 := SplQmQueryJInfo(0, J2, 3, LongInt(@Info), 2048, LongInt(@NN));
  Check('SplQmUpdateQProcParms (travail : COP=2)', (R = 0) And (GetZ(RdL(LongInt(@Info) + 52)) = 'COP=2'));
  R := SplQmListQueues(4, LongInt(@Info), 2048, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  Check('SplQmListQueues niveau 4 (file et travaux)', (R = 0) And (NR = 2) And (RdW(LongInt(@Info) + 30) = 0) And
        (RdW(LongInt(@Info) + 44 + 30) = 3) And (RdW(LongInt(@Info) + 88) = J2));
  R := SplQmReleaseQueue(Z('ESSAIQ'));
  R2 := SplQmListJobs(Z('ESSAIQ'), 0, LongInt(@Info), 2048, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  Check('SplQmReleaseQueue : impression (' + FileStr('D:\SORTIE.PRN') + '), travail retenu garde', (R = 0) And
        (NR = 1) And (JobAt(0) = J1) And (FileStr('D:\SORTIE.PRN') = 'XYZXYZ123'));
  R := SplQmReleaseJob(Z('ESSAIQ'), J1);
  R2 := SplQmListJobs(Z('ESSAIQ'), 0, LongInt(@Info), 2048, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  Check('SplQmReleaseJob : impression', (R = 0) And (NR = 0) And (FileStr('D:\SORTIE.PRN') = 'XYZXYZ123ABCDEF'));
  Hs := SplQmOpen(0, 8, LongInt(@Dop));
  R := SplQmStartDoc(Hs, Z('Abandon'));
  R2 := SplQmWrite(Hs, 5, Z('PERDU'));
  A := SplQmAbortDoc(Hs);
  B := SplQmWrite(Hs, 4, Z('FIN!'));
  R := SplQmAbort(Hs);
  Check('SplQmAbortDoc, SplQmAbort (rien d''imprime)', (A = 1) And (B = 1) And (R = 1) And
        (FileStr('D:\SORTIE.PRN') = 'XYZXYZ123ABCDEF') And (SplQmClose(Hs) = 0));
  R := DosOpen(Z('D:\DONNEES.TXT'), LongInt(@Hf), LongInt(@A), 0, 0, $12, $41, 0);
  R := DosWrite(Hf, Z('Bonjour'), 7, LongInt(@A));
  R := DosClose(Hf);
  J5 := 0;
  R := SplQmWriteFile(Z('ESSAIQ'), Z2('D:\DONNEES.TXT'), 0, LongInt(@J5));
  Check('SplQmWriteFile (travail ' + IStr(J5) + ')', (R = 0) And (J5 > 0) And
        (FileStr('D:\SORTIE.PRN') = 'XYZXYZ123ABCDEFBonjour'));

  { --- port en erreur --- }
  Q3[0] := Zs(0, 'ERRQ'); Q3[6] := 0; Q3[8] := Zs(200, 'MAUVAISE=Q:\ABSENT\SORTIE.PRN');
  R := SplQmCreateQueue(3, LongInt(@Q3), 44);
  R2 := SplQmWriteFile(Z('ERRQ'), Z2('D:\DONNEES.TXT'), Zs(300, 'Erreur'), LongInt(@J5));
  A := SplQmQueryJInfo(0, J5, 2, LongInt(@Info), 2048, LongInt(@NN));
  B := RdW(LongInt(@Info) + 10);
  Check('port impossible : travail retenu, PRJ_ERROR et PRJ_DESTOFFLINE (etat ' + IStr(B) + ')', (R = 0) And
        (R2 = 0) And (A = 0) And (B = $31));
  R := SplQmRestartJob(Z('ERRQ'), J5);
  R2 := SplQmCancelJob(Z('ERRQ'), J5);
  A := SplQmDestroyQueue(Z('ERRQ'));
  Check('SplQmRestartJob, SplQmCancelJob, SplQmDestroyQueue', (R = 0) And (R2 = 0) And (A = 0) And
        (SplQmQueryQInfo(Z('ERRQ'), 3, LongInt(@Info), 2048, LongInt(@NN)) = 2150));

  { --- acces a l'imprimante (LPT1, file LPT1Q) --- }
  Hf := 0;
  R := PrtOpen(Z('LPT1'), LongInt(@Hf), LongInt(@A), 0, 0, 1, $41, 0);
  R2 := PrtWrite(Hf, Z('IMPRIME PAR PRT' + Chr(13) + Chr(10)), 17, LongInt(@N));
  Buf[0] := 0;
  A := PrtDevIOCtl(LongInt(@Buf), LongInt(@Buf) + 10, $66, 5, Hf);
  Check('PrtOpen (travail de LPT1Q), PrtWrite, PrtDevIOCtl etat (' + IStr(Buf[0]) + ')', (R = 0) And (R2 = 0) And
        (N = 17) And (A = 0) And (Buf[0] = $90));
  R := SplQmListJobs(Z('LPT1Q'), 2, LongInt(@Info), 2048, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  Check('travail en cours de spoule (' + GetZ(RdL(LongInt(@Info) + 24)) + ', etat ' + IStr(RdW(LongInt(@Info) + 10)) +
        ')', (R = 0) And (NR = 1) And (RdW(LongInt(@Info) + 10) = 2) And (GetZ(RdL(LongInt(@Info) + 24)) = 'LPT1'));
  Buf[0] := 132; Buf[1] := 8;
  R := PrtDevIOCtl(LongInt(@Buf), LongInt(@Buf) + 10, $42, 5, Hf);
  Buf[0] := 0; Buf[1] := 0;
  R2 := PrtDevIOCtl(LongInt(@Buf), LongInt(@Buf) + 10, $62, 5, Hf);
  Check('PrtDevIOCtl controle de la page (42h, 62h)', (R = 0) And (R2 = 0) And (Buf[0] = 132) And (Buf[1] = 8));
  R := PrtClose(Hf);
  R2 := SplQmListJobs(Z('LPT1Q'), 0, LongInt(@Info), 2048, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  Check('PrtClose : impression sur LPT1', (R = 0) And (NR = 0) And (PrtWrite(Hf, Z('x'), 1, LongInt(@N)) = 6));
  R := PrtOpen(Z('LPT1'), LongInt(@Hf), LongInt(@A), 0, 0, 1, $41, 0);
  R2 := PrtWrite(Hf, Z('PERDU'), 5, LongInt(@N));
  A := PrtAbort(Hf);
  B := SplQmListJobs(Z('LPT1Q'), 0, LongInt(@Info), 2048, LongInt(@NR), LongInt(@NT), LongInt(@NN));
  Check('PrtAbort', (R = 0) And (R2 = 0) And (A = 0) And (NR = 0));
  R := PrtOpen(Z('NUL'), LongInt(@Hf), LongInt(@A), 0, 0, 1, $41, 0);
  R2 := PrtWrite(Hf, Z('rien'), 4, LongInt(@N));
  A := PrtClose(Hf);
  Check('PrtOpen direct (NUL, sans file), PrtWrite, PrtClose', (R = 0) And (R2 = 0) And (N = 4) And (A = 0));

  { --- donnees PM_Q_STD : SplStd* --- }
  Hdc := DevOpenDC(0, 8, Z('*'), 0, 0, 0);
  Pt[0] := 0; Pt[1] := 0;
  Hps := GpiCreatePS(0, Hdc, LongInt(@Pt), $4008);
  R := SplStdOpen(Hdc);
  R2 := SplStdStart(Hdc);
  A := GpiSetColor(Hps, 2);
  Pt[0] := 10; Pt[1] := 10;
  A := GpiMove(Hps, LongInt(@Pt));
  Pt[0] := 200; Pt[1] := 100;
  A := GpiBox(Hps, 3, LongInt(@Pt), 0, 0);
  Hst := SplStdStop(Hdc);
  N := SplStdQueryLength(Hst);
  For I := 0 To 9 Do Buf[I] := 0;
  A := SplStdGetBits(Hst, 0, 8, LongInt(@Buf));
  B := SplStdGetBits(Hst, N - 4, 8, LongInt(@Buf) + 20);
  Check('SplStdOpen, SplStdStart, SplStdStop, SplStdQueryLength (' + IStr(N) + '), SplStdGetBits (' +
        GetZ(LongInt(@Buf)) + ')', (Hdc <> 0) And (Hps <> 0) And (R = 1) And (R2 = 1) And ((Hst Shr 16) = $474D) And
        (N > 40) And (A = 1) And (GetZ(LongInt(@Buf)) = 'OS20MF01') And (B = 0));
  R := SplStdDelete(Hst);
  R2 := SplStdClose(Hdc);
  Check('SplStdDelete, SplStdClose', (R = 1) And (R2 = 1) And (SplStdQueryLength(Hst) = -1) And (SplStdStop(Hdc) = 0));
  A := GpiDestroyPS(Hps);
  A := DevCloseDC(Hdc);

  { --- DC OD_QUEUED de PMGPI : travail PM_Q_STD, PicPrint --- }
  R := SplQmHoldQueue(Z('ESSAIQ'));
  R := DosDelete(Z('D:\SORTIE.PRN'));
  For I := 0 To 8 Do Dop[I] := 0;
  Dop[0] := Zs(0, 'ESSAIQ'); Dop[1] := Zs(20, 'IBMNULL'); Dop[3] := Zs(40, 'PM_Q_STD');
  Hdc := DevOpenDC(0, 2, Z('*'), 4, LongInt(@Dop), 0);
  Pt[0] := 0; Pt[1] := 0;
  Hps := GpiCreatePS(0, Hdc, LongInt(@Pt), $4008);
  R := DevEscape(Hdc, 8150, 6, Z('Dessin'), 0, 0);
  A := GpiSetColor(Hps, 1);
  Pt[0] := 50; Pt[1] := 50;
  A := GpiMove(Hps, LongInt(@Pt));
  Pt[0] := 300; Pt[1] := 200;
  A := GpiBox(Hps, 2, LongInt(@Pt), 0, 0);
  N := 2; J1 := 0;
  R2 := DevEscape(Hdc, 8151, 0, 0, LongInt(@N), LongInt(@J1));
  J1 := J1 And $FFFF;
  A := GpiDestroyPS(Hps);
  B := DevCloseDC(Hdc);
  Check('DevOpenDC OD_QUEUED, DEVESC_STARTDOC, DEVESC_ENDDOC (travail ' + IStr(J1) + ')', (Hdc <> 0) And (R = 1) And
        (R2 = 1) And (J1 > 0) And (B = 1));
  R := SplQmQueryJInfo(0, J1, 3, LongInt(@Info), 2048, LongInt(@NN));
  N := RdL(LongInt(@Info) + 16);
  For I := 0 To 9 Do Buf[I] := 0;
  R2 := SplQmQueryPrintData(J1, 0, LongInt(@Buf), 8, LongInt(@NR));
  Check('travail PM_Q_STD (' + IStr(N) + ' octets, ' + GetZ(LongInt(@Buf)) + ')', (R = 0) And
        (GetZ(RdL(LongInt(@Info) + 32)) = 'PM_Q_STD') And (GetZ(RdL(LongInt(@Info) + 24)) = 'Dessin') And
        (N > 40) And (GetZ(LongInt(@Buf)) = 'OS20MF01'));
  Dop[3] := Zs(40, 'PM_Q_RAW');
  Hdc := DevOpenDC(0, 2, Z('*'), 4, LongInt(@Dop), 0);
  R := DevEscape(Hdc, 8150, 3, Z('Raw'), 0, 0);
  R2 := DevEscape(Hdc, 16303, 4, Z('RAW!'), 0, 0);
  N := 2; J2 := 0;
  A := DevEscape(Hdc, 8151, 0, 0, LongInt(@N), LongInt(@J2));
  J2 := J2 And $FFFF;
  B := DevCloseDC(Hdc);
  R := SplQmQueryJInfo(0, J2, 2, LongInt(@Info), 2048, LongInt(@NN));
  Check('DC OD_QUEUED PM_Q_RAW, DEVESC_RAWDATA (travail ' + IStr(J2) + ')', (R2 = 1) And (A = 1) And (J2 > 0) And
        (R = 0) And (RdL(LongInt(@Info) + 16) = 4));
  R := SplQmReleaseQueue(Z('ESSAIQ'));
  P := DosOpen(Z('D:\SORTIE.PRN'), LongInt(@Hf), LongInt(@A), 0, 0, 1, $40, 0);
  N := 0;
  R2 := DosRead(Hf, LongInt(@Info), 16, LongInt(@N));
  B := 0;
  R2 := DosSetFilePtr(Hf, -4, 2, LongInt(@B));
  N := 0;
  R2 := DosRead(Hf, LongInt(@Info) + 100, 4, LongInt(@N));
  A := DosClose(Hf);
  Check('impression PM_Q_STD par PicPrint (ESC @, ' + IStr(B + 4) + ' octets) puis PM_Q_RAW', (R = 0) And (P = 0) And
        (Info[0] = 27) And (Info[1] = 64) And (B > 1000) And (N = 4) And (Info[100] = Ord('R')) And
        (Info[103] = Ord('!')));
  R := SplQmDestroyQueue(Z('ESSAIQ'));
  R2 := PrfQueryProfileString(-2, Z('PM_SPOOLER_QUEUE'), Z2('ESSAIQ'), 0, LongInt(@Buf), 200);
  Check('SplQmDestroyQueue (profil efface)', (R = 0) And (R2 = 0) And
        (SplQmDestroyQueue(Z('ESSAIQ')) = 2150));

  { --- boite de message (delai de 2 secondes) --- }
  R := PrfWriteProfileString(-2, Z('PM_SPOOLER'), Z2('MSGTIMEOUT'), Zs(0, '2'));
  R := SplMessageBox(Z('LPT1'), $0400, $0001, Zs(100, 'Essai du tampon d''impression.'), Zs(200, 'TESTSPL'), 1, 2);
  R2 := PrfWriteProfileString(-2, Z('PM_SPOOLER'), Z2('MSGTIMEOUT'), 0);
  Check('SplMessageBox : delai, MBID_RETRY (' + IStr(R) + ')', R = 4);

  { --- anneau 3 --- }
  R := SplRing3(LongInt(@Ring3Fn), 21);
  Check('SplRing3 (' + IStr(R) + ')', R = 42);

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTSPL : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
