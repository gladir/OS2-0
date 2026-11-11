{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de QUECALLS.DLL sous OS/2-0.
}

Program TESTQUE;

{$R-,S-,I-}

{ Compilation : OS2PC TESTQUE.PAS   (produit TESTQUE.EXE)

  TESTQUE        verifie les 16 fonctions de QUECALLS.DLL : files FIFO,
                 LIFO et a priorites, lecture et consultation, codes
                 d'elements, semaphores 1.x et 2.x, ecrivain d'un autre
                 processus (TESTQUE ECRIT) et file de fin d'une session
                 de SESMGR.DLL (TESTSES FIN42).
  TESTQUE ECRIT  ouvre \QUEUES\ESSAI et y ecrit un element (donnees en
                 memoire partagee) ; rend un code de controle (31 si tout
                 va bien). }

Function DosReadQueue(Hq, PReq, PCb, PPBuf, Elem, Wait, PPrio, HSem : LongInt) : LongInt; External 'QUECALLS';
Function DosPurgeQueue(Hq : LongInt) : LongInt; External 'QUECALLS';
Function DosCloseQueue(Hq : LongInt) : LongInt; External 'QUECALLS';
Function DosQueryQueue(Hq, PCount : LongInt) : LongInt; External 'QUECALLS';
Function DosPeekQueue(Hq, PReq, PCb, PPBuf, PCode, Wait, PPrio, HSem : LongInt) : LongInt; External 'QUECALLS';
Function DosWriteQueue(Hq, Req, Cb, PData, Prio : LongInt) : LongInt; External 'QUECALLS';
Function DosOpenQueue(PPid, PHq, PName : LongInt) : LongInt; External 'QUECALLS';
Function DosCreateQueue(PHq, Flags, PName : LongInt) : LongInt; External 'QUECALLS';
Function Dos32ReadQueue(Hq, PReq, PCb, PPBuf, Elem, Wait, PPrio, HSem : LongInt) : LongInt; External 'QUECALLS';
Function Dos32PurgeQueue(Hq : LongInt) : LongInt; External 'QUECALLS';
Function Dos32CloseQueue(Hq : LongInt) : LongInt; External 'QUECALLS';
Function Dos32QueryQueue(Hq, PCount : LongInt) : LongInt; External 'QUECALLS';
Function Dos32PeekQueue(Hq, PReq, PCb, PPBuf, PCode, Wait, PPrio, HSem : LongInt) : LongInt; External 'QUECALLS';
Function Dos32WriteQueue(Hq, Req, Cb, PData, Prio : LongInt) : LongInt; External 'QUECALLS';
Function Dos32OpenQueue(PPid, PHq, PName : LongInt) : LongInt; External 'QUECALLS';
Function Dos32CreateQueue(PHq, Flags, PName : LongInt) : LongInt; External 'QUECALLS';

Function Dos32StartSession(P, PSid, PPid : LongInt) : LongInt; External 'SESMGR';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosExit(Action, Code : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocSharedMem(PPb, PName, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateEventSem(PName, PHev, Attr, State : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryEventSem(H, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosCloseEventSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateSem(NoExcl, PHSem, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosSemSet(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosSemWait(H, Timeout : LongInt) : LongInt; External 'DOSCALLS';
Function DosCloseSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';

Const
  ERROR_INVALID_PARAMETER = 87;
  ERROR_QUE_PROC_NOT_OWNED = 330;
  ERROR_QUE_DUPLICATE = 332;
  ERROR_QUE_ELEMENT_NOT_EXIST = 333;
  ERROR_QUE_INVALID_NAME = 335;
  ERROR_QUE_INVALID_PRIORITY = 336;
  ERROR_QUE_INVALID_HANDLE = 337;
  ERROR_QUE_PROC_NO_ACCESS = 341;
  ERROR_QUE_EMPTY = 342;
  ERROR_QUE_NAME_NOT_EXIST = 343;
  ERROR_QUE_INVALID_WAIT = 348;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, Hq, Hq2, Hq3, Hl, Hp, Hf, Pid, Me, Cb, PBuf, Code, Ev, Sem, Sid : LongInt;
  Prio : Array[0..3] Of Byte;
  ReqD : Array[0..3] Of LongInt;        { REQUESTDATA (QUEUERESULT : 2 mots) }
  Name : Array[0..127] Of Byte;
  DA, DB, DC : Array[0..15] Of Byte;
  Sd : Array[0..63] Of Byte;
  Prog, Inputs : Array[0..63] Of Byte;
  ArgB, ObjB : Array[0..63] Of Byte;
  Res : Array[0..3] Of LongInt;
  Seq : String;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var T : String;
Begin
  Str(V, T);
  IStr := T;
End;

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name), S);
  Z := LongInt(@Name);
End;

Function GetS(A, N : LongInt) : String;
Var T : String; K : LongInt;
Begin
  T := '';
  For K := 0 To N - 1 Do T := T + Chr(RdB(A + K));
  GetS := T;
End;

Procedure OutStr(T : String);
Var K : LongInt;
Begin
  For K := 1 To Length(T) Do
    If OutLen < 16380 Then
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

Function OrdIs(Ordinal : LongInt; S : String) : Boolean;
Var Pa, Pb : LongInt;
Begin
  Pa := 0; Pb := 0;
  DosQueryProcAddr(H, 0, Z(S), LongInt(@Pa));
  DosQueryProcAddr(H, Ordinal, 0, LongInt(@Pb));
  OrdIs := (Pa <> 0) And (Pa = Pb);
End;

{ Lire un element (2.x, sans attente) : ReqD, Cb, PBuf, Prio }
Function Rd(Q, Elem : LongInt) : LongInt;
Begin
  ReqD[0] := -1; ReqD[1] := -1; Cb := -1; PBuf := 0; Prio[0] := 99;
  Rd := Dos32ReadQueue(Q, LongInt(@ReqD), LongInt(@Cb), LongInt(@PBuf), Elem, 1, LongInt(@Prio), 0);
End;

Function Pk(Q : LongInt) : LongInt;
Begin
  ReqD[0] := -1; ReqD[1] := -1;
  Pk := Dos32PeekQueue(Q, LongInt(@ReqD), LongInt(@Cb), LongInt(@PBuf), LongInt(@Code), 1, LongInt(@Prio), 0);
End;

{ Lire toute la file : codes de requete dans Seq }
Procedure Drain(Q : LongInt);
Begin
  Seq := '';
  While Rd(Q, 0) = 0 Do Seq := Seq + IStr(ReqD[1]) + Chr(48 + Prio[0] Mod 10) + ' ';
End;

{ --- processus ecrivain --- }
Procedure WriterMode;
Var C, P, Q, Op, D : LongInt;
Begin
  C := 0;
  Q := 0; Op := 0;
  If Dos32OpenQueue(LongInt(@Op), LongInt(@Q), Z('\QUEUES\ESSAI')) = 0 Then
    If Op <> KGetCurrentProcessId Then C := C + 1;
  P := 0;
  D := DosAllocSharedMem(LongInt(@P), 0, 64, $213);
  PutZ(P, 'ENFANT');
  If Dos32WriteQueue(Q, 77, 6, P, 0) = 0 Then C := C + 8;
  If Rd(Q, 0) = ERROR_QUE_PROC_NOT_OWNED Then C := C + 2;
  If Dos32PurgeQueue(Q) = ERROR_QUE_PROC_NOT_OWNED Then C := C + 4;
  If (Dos32CloseQueue(Q) = 0) And (Dos32WriteQueue(Q, 1, 0, 0, 0) = ERROR_QUE_PROC_NO_ACCESS) Then C := C + 16;
  D := DosExit(1, C);
End;

BEGIN
  If (ParamCount > 0) And (ParamStr(1) = 'ECRIT') Then WriterMode;
  Ok := 0; Fail := 0; OutLen := 0;
  Me := KGetCurrentProcessId;
  WriteLn('TESTQUE : essai de QUECALLS.DLL');

  { --- module et ordinaux --- }
  R := DosQueryModuleHandle(Z('QUECALLS'), LongInt(@H));
  Check('DosQueryModuleHandle QUECALLS', R = 0);
  Check('ordinaux 1 a 8 (OS/2 1.x)', OrdIs(1, 'DosReadQueue') And OrdIs(2, 'DosPurgeQueue') And
        OrdIs(3, 'DosCloseQueue') And OrdIs(4, 'DosQueryQueue') And OrdIs(5, 'DosPeekQueue') And
        OrdIs(6, 'DosWriteQueue') And OrdIs(7, 'DosOpenQueue') And OrdIs(8, 'DosCreateQueue'));
  Check('ordinaux 9 a 16 (Dos32...)', OrdIs(9, 'Dos32ReadQueue') And OrdIs(10, 'Dos32PurgeQueue') And
        OrdIs(11, 'Dos32CloseQueue') And OrdIs(12, 'Dos32QueryQueue') And OrdIs(13, 'Dos32PeekQueue') And
        OrdIs(14, 'Dos32WriteQueue') And OrdIs(15, 'Dos32OpenQueue') And OrdIs(16, 'Dos32CreateQueue'));

  { --- creation et ouverture --- }
  R := Dos32CreateQueue(LongInt(@Hq), 0, Z('\FILES\X'));
  Check('DosCreateQueue nom sans \QUEUES\ refuse', R = ERROR_QUE_INVALID_NAME);
  R := Dos32CreateQueue(LongInt(@Hq), 3, Z('\QUEUES\X'));
  R2 := Dos32CreateQueue(LongInt(@Hq), $10, Z('\QUEUES\X'));
  Check('DosCreateQueue ordre ou indicateur invalide refuse', (R = ERROR_QUE_INVALID_PRIORITY) And
        (R2 = ERROR_QUE_INVALID_PRIORITY));
  R := Dos32CreateQueue(LongInt(@Hq), 0, Z('\queues\essai'));
  R2 := DosCreateQueue(LongInt(@Hq2), 4, Z('\QUEUES\ESSAI'));
  Check('Dos32CreateQueue \QUEUES\ESSAI (FIFO) ; nom deja pris refuse', (R = 0) And (Hq <> 0) And
        (R2 = ERROR_QUE_DUPLICATE));
  R := Dos32OpenQueue(LongInt(@Pid), LongInt(@Hq2), Z('\QUEUES\AUTRE'));
  Check('DosOpenQueue file inexistante', R = ERROR_QUE_NAME_NOT_EXIST);
  Pid := 0;
  R := DosOpenQueue(LongInt(@Pid), LongInt(@Hq2), Z('\QUEUES\ESSAI'));
  Check('DosOpenQueue : proprietaire et handle', (R = 0) And (Pid = Me) And (Hq2 = Hq));
  R := Dos32QueryQueue(Hq, LongInt(@N));
  Check('DosQueryQueue : file vide', (R = 0) And (N = 0));

  { --- FIFO, consultation et codes d'elements --- }
  PutZ(LongInt(@DA), 'AAA'); PutZ(LongInt(@DB), 'BBBB'); PutZ(LongInt(@DC), 'CC');
  R := Dos32WriteQueue(Hq, 10, 3, LongInt(@DA), 0);
  R2 := Dos32WriteQueue(Hq, 20, 4, LongInt(@DB), 0);
  A := DosWriteQueue(Hq, 30, 2, LongInt(@DC), 0);
  B := DosQueryQueue(Hq, LongInt(@N));
  Check('DosWriteQueue de 3 elements, DosQueryQueue = 3', (R = 0) And (R2 = 0) And (A = 0) And (B = 0) And (N = 3));
  Code := 0;
  R := Pk(Hq);
  A := Code;
  Check('DosPeekQueue : premier element (10, AAA)', (R = 0) And (ReqD[1] = 10) And (ReqD[0] = Me) And (Cb = 3) And
        (GetS(PBuf, 3) = 'AAA') And (A <> 0));
  R := Pk(Hq);
  B := Code;
  Check('DosPeekQueue suivant : 20', (R = 0) And (ReqD[1] = 20) And (B <> A));
  R := Pk(Hq);
  R2 := Pk(Hq);
  Check('DosPeekQueue : 30, puis fin', (R = 0) And (R2 = ERROR_QUE_EMPTY));
  Code := 9999;
  R := Pk(Hq);
  Check('DosPeekQueue code inexistant', R = ERROR_QUE_ELEMENT_NOT_EXIST);
  R := Rd(Hq, B);
  Check('DosReadQueue par code : 20, BBBB', (R = 0) And (ReqD[1] = 20) And (Cb = 4) And (GetS(PBuf, 4) = 'BBBB'));
  R := Rd(Hq, 9999);
  Check('DosReadQueue code inexistant', R = ERROR_QUE_ELEMENT_NOT_EXIST);
  Drain(Hq);
  Check('DosReadQueue FIFO : ' + Seq, Seq = '100 300 ');
  R := Rd(Hq, 0);
  R2 := Dos32ReadQueue(Hq, LongInt(@ReqD), LongInt(@Cb), LongInt(@PBuf), 0, 0, LongInt(@Prio), 0);
  Check('file vide : sans attente et avec attente (ERROR_QUE_EMPTY)', (R = ERROR_QUE_EMPTY) And (R2 = ERROR_QUE_EMPTY));
  R := Dos32ReadQueue(Hq, LongInt(@ReqD), LongInt(@Cb), LongInt(@PBuf), 0, 5, LongInt(@Prio), 0);
  Check('bWait invalide refuse', R = ERROR_QUE_INVALID_WAIT);

  { --- QUEUERESULT (OS/2 1.x) --- }
  R := DosWriteQueue(Hq, $1234, 3, LongInt(@DA), 0);
  ReqD[0] := -1; ReqD[1] := -1;
  R := DosReadQueue(Hq, LongInt(@ReqD), LongInt(@Cb), LongInt(@PBuf), 0, 1, LongInt(@Prio), 0);
  Check('DosReadQueue (1.x) : QUEUERESULT de 2 mots', (R = 0) And (RdW(LongInt(@ReqD)) = Me) And
        (RdW(LongInt(@ReqD) + 2) = $1234) And (ReqD[1] = -1));

  { --- LIFO et priorites --- }
  R := Dos32CreateQueue(LongInt(@Hl), 1, Z('\QUEUES\LIFO'));
  For I := 1 To 3 Do A := Dos32WriteQueue(Hl, I, 0, 0, 0);
  Drain(Hl);
  Check('file LIFO : ' + Seq, (R = 0) And (Seq = '30 20 10 '));
  R := Dos32CreateQueue(LongInt(@Hp), 2, Z('\QUEUES\PRIORITES'));
  A := Dos32WriteQueue(Hp, 1, 0, 0, 5);
  A := Dos32WriteQueue(Hp, 2, 0, 0, 9);
  A := Dos32WriteQueue(Hp, 3, 0, 0, 5);
  A := Dos32WriteQueue(Hp, 4, 0, 0, 15);
  R2 := Dos32WriteQueue(Hp, 5, 0, 0, 16);
  Drain(Hp);
  Check('file a priorites (code, priorite) : ' + Seq, (R = 0) And (Seq = '45 29 15 35 ') And
        (R2 = ERROR_QUE_INVALID_PRIORITY));

  { --- semaphores --- }
  R := DosCreateEventSem(0, LongInt(@Ev), 0, 0);
  R := Dos32ReadQueue(Hq, LongInt(@ReqD), LongInt(@Cb), LongInt(@PBuf), 0, 1, LongInt(@Prio), Ev);
  R2 := Dos32WriteQueue(Hq, 5, 0, 0, 0);
  A := 0;
  B := DosQueryEventSem(Ev, LongInt(@A));
  Check('semaphore d''evenement affichee par DosWriteQueue', (R = ERROR_QUE_EMPTY) And (R2 = 0) And (A >= 1));
  R := Dos32PurgeQueue(Hq);
  R2 := Dos32QueryQueue(Hq, LongInt(@N));
  Check('DosPurgeQueue', (R = 0) And (N = 0));
  R := DosCreateSem(1, LongInt(@Sem), Z('\SEM\FILE'));
  R := DosSemSet(Sem);
  R := DosReadQueue(Hq, LongInt(@ReqD), LongInt(@Cb), LongInt(@PBuf), 0, 1, LongInt(@Prio), Sem);
  R2 := DosWriteQueue(Hq, 6, 0, 0, 0);
  Check('semaphore 1.x liberee par DosWriteQueue', (R = ERROR_QUE_EMPTY) And (R2 = 0) And (DosSemWait(Sem, 0) = 0));
  A := Dos32PurgeQueue(Hq);

  { --- ecrivain d'un autre processus --- }
  PutZ(LongInt(@ArgB), 'TESTQUE');
  PutZ(LongInt(@ArgB) + 8, 'ECRIT');
  ArgB[14] := 0;
  Res[0] := 0; Res[1] := 0;
  R := DosExecPgm(LongInt(@ObjB), 64, 0, LongInt(@ArgB), 0, LongInt(@Res), Z('C:\TESTQUE.EXE'));
  Check('processus ecrivain : ouverture, ecriture ; lecture, purge refusees ; fermeture (' + IStr(Res[1]) + ')',
        (R = 0) And (Res[1] = 31));
  R := Rd(Hq, 0);
  Check('element de l''autre processus : 77, ENFANT (memoire partagee)', (R = 0) And (ReqD[1] = 77) And
        (ReqD[0] <> Me) And (ReqD[0] <> 0) And (Cb = 6) And (GetS(PBuf, 6) = 'ENFANT'));

  { --- file de fin d'une session (SESMGR.DLL) --- }
  R := Dos32CreateQueue(LongInt(@Hf), 0, Z('\QUEUES\FIN'));
  For I := 0 To 63 Do Sd[I] := 0;
  WrW(LongInt(@Sd), 32);
  WrW(LongInt(@Sd) + 2, 1);
  PutZ(LongInt(@Prog), 'C:\TESTSES.EXE');
  PutZ(LongInt(@Inputs), 'FIN42');
  WrL(LongInt(@Sd) + 12, LongInt(@Prog));
  WrL(LongInt(@Sd) + 16, LongInt(@Inputs));
  WrL(LongInt(@Sd) + 20, Z('\QUEUES\FIN'));
  Sid := 0;
  R2 := Dos32StartSession(LongInt(@Sd), LongInt(@Sid), LongInt(@Pid));
  R := Rd(Hf, 0);
  Check('file de fin (TermQ) : session ' + IStr(Sid) + ', code 42', (R2 = 0) And (R = 0) And (ReqD[1] = 0) And
        (Cb = 4) And (RdW(PBuf) = Sid) And (RdW(PBuf + 2) = 42));
  A := Dos32CloseQueue(Hf);

  { --- fermeture --- }
  R := Dos32CloseQueue(Hq);
  R2 := Dos32QueryQueue(Hq, LongInt(@N));
  Check('DosCloseQueue par le proprietaire : file supprimee', (R = 0) And (R2 = ERROR_QUE_INVALID_HANDLE));
  R := Dos32OpenQueue(LongInt(@Pid), LongInt(@Hq3), Z('\QUEUES\ESSAI'));
  Check('file supprimee : DosOpenQueue', R = ERROR_QUE_NAME_NOT_EXIST);
  R := Dos32QueryQueue(0, LongInt(@N));
  Check('handle invalide', R = ERROR_QUE_INVALID_HANDLE);
  A := Dos32CloseQueue(Hl);
  A := Dos32CloseQueue(Hp);
  A := DosCloseEventSem(Ev);
  A := DosCloseSem(Sem);

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTQUE : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
