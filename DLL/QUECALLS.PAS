{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 QUECALLS.DLL de OS/2-0 (files d'attente).
}

Library QUECALLS;

{$IMAGEBASE $00E70000}
{$R-,S-,I-}

{ Compilation : OS2PC QUECALLS.PAS   (produit QUECALLS.DLL)

  QUECALLS.DLL gere les files d'attente d'OS/2 (\QUEUES\nom) : le
  processus qui cree une file (DosCreateQueue) en est le proprietaire et
  le seul a pouvoir la lire (DosReadQueue, DosPeekQueue) et la vider
  (DosPurgeQueue) ; les autres processus l'ouvrent (DosOpenQueue) pour y
  ecrire (DosWriteQueue). Un element porte un code de requete, une
  longueur, une adresse de donnees et une priorite ; les donnees ne sont
  pas copiees (comme sous OS/2, l'ecrivain les place en memoire partagee,
  DosAllocSharedMem, si le lecteur est un autre processus).

  Ordre de lecture (fsQueueFlags) : QUE_FIFO (0), QUE_LIFO (1) ou
  QUE_PRIORITY (2 : priorite 15 la plus haute, puis ordre d'arrivee) ;
  QUE_CONVERT_ADDRESS (4) est accepte (adresses deja lineaires).

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires ; un pointeur vers une valeur simple (phq, ppid, pcbData,
  ppbuf, pulElemCode, pcElements) designe un LongInt, la priorite rendue
  un octet. Les points d'entree d'OS/2 1.x (ordinaux 1 a 8) rendent
  QUEUERESULT (pidProcess, usEventCode : 2 mots) et liberent une
  semaphore 1.x (DosSemClear) ; ceux d'OS/2 2.x (ordinaux 9 a 16)
  rendent REQUESTDATA (pid, ulData : 2 doubles mots) et affichent une
  semaphore d'evenement (DosPostEventSem). Exemple :
    Function DosWriteQueue(Hq, Request, Cb, PData, Priority : LongInt) : LongInt; External 'QUECALLS';

  La semaphore passee a DosReadQueue ou DosPeekQueue sans attente
  (DCWW_NOWAIT) est signalee a chaque element ajoute. Les processus
  s'executant un a la fois, une lecture avec attente d'une file vide ne
  peut aboutir : elle rend ERROR_QUE_EMPTY. Une file disparait quand son
  proprietaire la ferme ou se termine.

  Fonctions exportees (ordinaux d'origine de QUECALLS.DLL) :
     1 DosReadQueue      5 DosPeekQueue       9 Dos32ReadQueue   13 Dos32PeekQueue
     2 DosPurgeQueue     6 DosWriteQueue     10 Dos32PurgeQueue  14 Dos32WriteQueue
     3 DosCloseQueue     7 DosOpenQueue      11 Dos32CloseQueue  15 Dos32OpenQueue
     4 DosQueryQueue     8 DosCreateQueue    12 Dos32QueryQueue  16 Dos32CreateQueue

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services de DOSCALLS.DLL
    Partie 3 - Utilitaires
    Partie 4 - Files, acces et elements
    Partie 5 - Fonctions communes
    Partie 6 - Points d'entree
    Exportations }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  NO_ERROR                    = 0;
  ERROR_INVALID_PARAMETER     = 87;
  ERROR_QUE_PROC_NOT_OWNED    = 330;
  ERROR_QUE_DUPLICATE         = 332;
  ERROR_QUE_ELEMENT_NOT_EXIST = 333;
  ERROR_QUE_NO_MEMORY         = 334;
  ERROR_QUE_INVALID_NAME      = 335;
  ERROR_QUE_INVALID_PRIORITY  = 336;
  ERROR_QUE_INVALID_HANDLE    = 337;
  ERROR_QUE_PROC_NO_ACCESS    = 341;
  ERROR_QUE_EMPTY             = 342;
  ERROR_QUE_NAME_NOT_EXIST    = 343;
  ERROR_QUE_INVALID_WAIT      = 348;

  QUE_FIFO     = 0;
  QUE_LIFO     = 1;
  QUE_PRIORITY = 2;
  DCWW_WAIT    = 0;
  DCWW_NOWAIT  = 1;

  MaxQ    = 32;              { files }
  MaxAcc  = 64;              { acces (file, processus) }
  MaxElem = 256;             { elements en attente, toutes files }

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  { files (indice 0..MaxQ-1) ; handle = generation shl 8 or (indice + 1) }
  QUsed   : Array[0..MaxQ - 1] Of Boolean;
  QName   : Array[0..MaxQ - 1] Of String[63];
  QOwner  : Array[0..MaxQ - 1] Of LongInt;
  QFlags  : Array[0..MaxQ - 1] Of LongInt;
  QGen    : Array[0..MaxQ - 1] Of LongInt;
  QSem    : Array[0..MaxQ - 1] Of LongInt;   { semaphore a signaler }
  QSem16  : Array[0..MaxQ - 1] Of Boolean;   { semaphore 1.x }

  { acces des processus (le proprietaire en a un aussi) }
  AQueue, APid, ACount : Array[0..MaxAcc - 1] Of LongInt;

  { elements : file -1 = libre }
  EQueue, EReq, ECb, EPtr, EPrio, EPid, ESeq : Array[0..MaxElem - 1] Of LongInt;
  NextSeq : LongInt;

{ ==================================================================== }
{ Partie 2 - Services de DOSCALLS.DLL                                  }
{ ==================================================================== }

Function DcPostEventSem(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosPostEventSem';
Function DcSemClear(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSemClear';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';

{ ==================================================================== }
{ Partie 3 - Utilitaires                                               }
{ ==================================================================== }

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V;
End;

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FFFF;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FF;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
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
      S := S + UpCase(Chr(RdB(A + N)));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

{ ==================================================================== }
{ Partie 4 - Files, acces et elements                                  }
{ ==================================================================== }

Procedure FreeQueue(Q : LongInt);
Var I : LongInt;
Begin
  For I := 0 To MaxElem - 1 Do
    If EQueue[I] = Q Then EQueue[I] := -1;
  For I := 0 To MaxAcc - 1 Do
    If AQueue[I] = Q Then AQueue[I] := -1;
  QUsed[Q] := False;
  Inc(QGen[Q]);
  If QGen[Q] > 255 Then QGen[Q] := 1;
End;

{ Files des proprietaires termines supprimees, acces des processus
  termines retires }
Procedure Purge;
Var I : LongInt;
Begin
  For I := 0 To MaxQ - 1 Do
    If QUsed[I] Then
      If KrnMonIo(0, 4, QOwner[I]) = 0 Then FreeQueue(I);
  For I := 0 To MaxAcc - 1 Do
    If AQueue[I] >= 0 Then
      If KrnMonIo(0, 4, APid[I]) = 0 Then AQueue[I] := -1;
End;

Function QHandle(Q : LongInt) : LongInt;
Begin
  QHandle := (QGen[Q] Shl 8) Or (Q + 1);
End;

Function AccIdx(Q, Pid : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxAcc - 1 Do
    If (AQueue[I] = Q) And (APid[I] = Pid) Then R := I;
  AccIdx := R;
End;

Function AddAccess(Q, Pid : LongInt) : Boolean;
Var I, F : LongInt;
Begin
  F := AccIdx(Q, Pid);
  If F >= 0 Then
  Begin
    Inc(ACount[F]);
    AddAccess := True;
    Exit;
  End;
  For I := MaxAcc - 1 DownTo 0 Do
    If AQueue[I] < 0 Then F := I;
  If F >= 0 Then
  Begin
    AQueue[F] := Q;
    APid[F] := Pid;
    ACount[F] := 1;
  End;
  AddAccess := F >= 0;
End;

{ Handle -> file accessible par le processus (Q), ou code d'erreur }
Function CheckHandle(Hq : LongInt; Var Q : LongInt) : LongInt;
Var I : LongInt;
Begin
  Purge;
  Q := -1;
  I := (Hq And $FF) - 1;
  If (I < 0) Or (I >= MaxQ) Or ((Hq Shr 8) <> QGen[I]) Then
  Begin
    CheckHandle := ERROR_QUE_INVALID_HANDLE;
    Exit;
  End;
  If Not QUsed[I] Then
  Begin
    CheckHandle := ERROR_QUE_INVALID_HANDLE;
    Exit;
  End;
  If AccIdx(I, MyPid) < 0 Then
  Begin
    CheckHandle := ERROR_QUE_PROC_NO_ACCESS;
    Exit;
  End;
  Q := I;
  CheckHandle := NO_ERROR;
End;

Function CountElems(Q : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxElem - 1 Do
    If EQueue[I] = Q Then Inc(N);
  CountElems := N;
End;

{ L'element A passe-t-il avant l'element B selon l'ordre de la file ? }
Function Before(Q, A, B : LongInt) : Boolean;
Var O : LongInt;
Begin
  O := QFlags[Q] And 3;
  If O = QUE_LIFO Then Before := ESeq[A] > ESeq[B]
  Else If O = QUE_PRIORITY Then
  Begin
    If EPrio[A] <> EPrio[B] Then Before := EPrio[A] > EPrio[B]
    Else Before := ESeq[A] < ESeq[B];
  End
  Else Before := ESeq[A] < ESeq[B];
End;

{ Element suivant celui de code After (0 : le premier) ; -1 : aucun }
Function NextElem(Q, After : LongInt) : LongInt;
Var I, Best, Ref : LongInt;
Begin
  Ref := -1;
  If After <> 0 Then
    For I := 0 To MaxElem - 1 Do
      If (EQueue[I] = Q) And (ESeq[I] = After) Then Ref := I;
  Best := -1;
  For I := 0 To MaxElem - 1 Do
    If EQueue[I] = Q Then
      If (Ref < 0) Or Before(Q, Ref, I) Then
        If (Best < 0) Or Before(Q, I, Best) Then Best := I;
  NextElem := Best;
End;

Function ElemByCode(Q, Code : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxElem - 1 Do
    If (EQueue[I] = Q) And (ESeq[I] = Code) Then R := I;
  ElemByCode := R;
End;

{ ==================================================================== }
{ Partie 5 - Fonctions communes                                        }
{ ==================================================================== }

Function CreateQ(PHq, Flags, PName : LongInt) : LongInt;
Var I, F : LongInt; N : String;
Begin
  Purge;
  N := GetZ(PName);
  If (PName = 0) Or (Copy(N, 1, 8) <> '\QUEUES\') Or (Length(N) <= 8) Or (Length(N) > 63) Then
  Begin
    CreateQ := ERROR_QUE_INVALID_NAME;
    Exit;
  End;
  If (PHq = 0) Or ((Flags And Not 7) <> 0) Or ((Flags And 3) = 3) Then
  Begin
    CreateQ := ERROR_QUE_INVALID_PRIORITY;
    Exit;
  End;
  For I := 0 To MaxQ - 1 Do
    If QUsed[I] And (QName[I] = N) Then
    Begin
      CreateQ := ERROR_QUE_DUPLICATE;
      Exit;
    End;
  F := -1;
  For I := MaxQ - 1 DownTo 0 Do
    If Not QUsed[I] Then F := I;
  If F < 0 Then
  Begin
    CreateQ := ERROR_QUE_NO_MEMORY;
    Exit;
  End;
  QUsed[F] := True;
  QName[F] := N;
  QOwner[F] := MyPid;
  QFlags[F] := Flags;
  QSem[F] := 0;
  QSem16[F] := False;
  If Not AddAccess(F, MyPid) Then
  Begin
    FreeQueue(F);
    CreateQ := ERROR_QUE_NO_MEMORY;
    Exit;
  End;
  WrL(PHq, QHandle(F));
  CreateQ := NO_ERROR;
End;

Function OpenQ(PPid, PHq, PName : LongInt) : LongInt;
Var I, F : LongInt; N : String;
Begin
  Purge;
  N := GetZ(PName);
  If (PName = 0) Or (Copy(N, 1, 8) <> '\QUEUES\') Then
  Begin
    OpenQ := ERROR_QUE_INVALID_NAME;
    Exit;
  End;
  F := -1;
  For I := 0 To MaxQ - 1 Do
    If QUsed[I] And (QName[I] = N) Then F := I;
  If F < 0 Then
  Begin
    OpenQ := ERROR_QUE_NAME_NOT_EXIST;
    Exit;
  End;
  If PHq = 0 Then
  Begin
    OpenQ := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If Not AddAccess(F, MyPid) Then
  Begin
    OpenQ := ERROR_QUE_NO_MEMORY;
    Exit;
  End;
  WrL(PPid, QOwner[F]);
  WrL(PHq, QHandle(F));
  OpenQ := NO_ERROR;
End;

Function CloseQ(Hq : LongInt) : LongInt;
Var R, Q, A : LongInt;
Begin
  R := CheckHandle(Hq, Q);
  If R = NO_ERROR Then
  Begin
    If QOwner[Q] = MyPid Then FreeQueue(Q)    { le proprietaire supprime la file }
    Else
    Begin
      A := AccIdx(Q, MyPid);
      Dec(ACount[A]);
      If ACount[A] <= 0 Then AQueue[A] := -1;
    End;
  End;
  CloseQ := R;
End;

Function PurgeQ(Hq : LongInt) : LongInt;
Var R, Q, I : LongInt;
Begin
  R := CheckHandle(Hq, Q);
  If (R = NO_ERROR) And (QOwner[Q] <> MyPid) Then R := ERROR_QUE_PROC_NOT_OWNED;
  If R = NO_ERROR Then
    For I := 0 To MaxElem - 1 Do
      If EQueue[I] = Q Then EQueue[I] := -1;
  PurgeQ := R;
End;

Function QueryQ(Hq, PCount : LongInt) : LongInt;
Var R, Q : LongInt;
Begin
  R := CheckHandle(Hq, Q);
  If (R = NO_ERROR) And (PCount = 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then WrL(PCount, CountElems(Q));
  QueryQ := R;
End;

Function WriteQ(Hq, Req, Cb, PData, Prio : LongInt) : LongInt;
Var R, Q, I, F, D : LongInt;
Begin
  R := CheckHandle(Hq, Q);
  If R = NO_ERROR Then
  Begin
    If ((QFlags[Q] And 3) = QUE_PRIORITY) And ((Prio < 0) Or (Prio > 15)) Then
      R := ERROR_QUE_INVALID_PRIORITY
    Else
    Begin
      F := -1;
      For I := MaxElem - 1 DownTo 0 Do
        If EQueue[I] < 0 Then F := I;
      If F < 0 Then R := ERROR_QUE_NO_MEMORY
      Else
      Begin
        Inc(NextSeq);
        EQueue[F] := Q;
        EReq[F] := Req;
        ECb[F] := Cb;
        EPtr[F] := PData;
        If (QFlags[Q] And 3) = QUE_PRIORITY Then EPrio[F] := Prio Else EPrio[F] := 0;
        EPid[F] := MyPid;
        ESeq[F] := NextSeq;
        { semaphore du lecteur }
        If QSem[Q] <> 0 Then
        Begin
          If QSem16[Q] Then D := DcSemClear(QSem[Q]) Else D := DcPostEventSem(QSem[Q]);
        End;
      End;
    End;
  End;
  WriteQ := R;
End;

{ Lire (Peek = False : element retire) ou consulter un element.
  Code : code d'element (Read : 0 = premier ; Peek : adresse du code,
  0 = premier, sinon suivant de celui-ci). Is16 : QUEUERESULT et
  semaphore 1.x. }
Function GetQ(Hq, PReq, PCb, PPBuf, Code, Wait, PPrio, HSem : LongInt; Peek, Is16 : Boolean) : LongInt;
Var R, Q, E, C : LongInt;
Begin
  R := CheckHandle(Hq, Q);
  If (R = NO_ERROR) And (QOwner[Q] <> MyPid) Then R := ERROR_QUE_PROC_NOT_OWNED;
  If (R = NO_ERROR) And (Wait <> DCWW_WAIT) And (Wait <> DCWW_NOWAIT) Then R := ERROR_QUE_INVALID_WAIT;
  If (R = NO_ERROR) And ((PReq = 0) Or (PCb = 0) Or (PPBuf = 0) Or (Peek And (Code = 0))) Then
    R := ERROR_INVALID_PARAMETER;
  If R <> NO_ERROR Then
  Begin
    GetQ := R;
    Exit;
  End;
  If Peek Then C := RdL(Code) Else C := Code;
  E := -1;
  If Peek Then
  Begin
    If (C <> 0) And (ElemByCode(Q, C) < 0) Then R := ERROR_QUE_ELEMENT_NOT_EXIST
    Else E := NextElem(Q, C);
  End
  Else If C <> 0 Then
  Begin
    E := ElemByCode(Q, C);
    If E < 0 Then R := ERROR_QUE_ELEMENT_NOT_EXIST;
  End
  Else
    E := NextElem(Q, 0);
  If (R = NO_ERROR) And (E < 0) Then
  Begin
    { file vide : la semaphore sera signalee au prochain element ; une
      attente ne peut aboutir (un processus a la fois) }
    If (Wait = DCWW_NOWAIT) And (HSem <> 0) Then
    Begin
      QSem[Q] := HSem;
      QSem16[Q] := Is16;
    End;
    R := ERROR_QUE_EMPTY;
  End;
  If R = NO_ERROR Then
  Begin
    If Is16 Then
    Begin
      WrW(PReq, EPid[E]);
      WrW(PReq + 2, EReq[E]);
    End
    Else
    Begin
      WrL(PReq, EPid[E]);
      WrL(PReq + 4, EReq[E]);
    End;
    WrL(PCb, ECb[E]);
    WrL(PPBuf, EPtr[E]);
    WrB(PPrio, EPrio[E]);
    If Peek Then WrL(Code, ESeq[E])
    Else EQueue[E] := -1;
  End;
  GetQ := R;
End;

{ ==================================================================== }
{ Partie 6 - Points d'entree                                           }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  Dos32CreateQueue(phq, ulPriority, pszName) : creer la file \QUEUES\nom
  (QUE_FIFO, QUE_LIFO, QUE_PRIORITY ; QUE_CONVERT_ADDRESS) ; le
  processus en devient le proprietaire }
Function Dos32CreateQueue(PHq, Flags, PName : LongInt) : LongInt;
Begin
  Dos32CreateQueue := CreateQ(PHq, Flags, PName);
End;

Function DosCreateQueue(PHq, Flags, PName : LongInt) : LongInt;
Begin
  DosCreateQueue := CreateQ(PHq, Flags, PName);
End;

{ ---------------------------------------------------------------------
  Dos32OpenQueue(ppid, phq, pszName) : ouvrir une file pour y ecrire ;
  *ppid <- proprietaire }
Function Dos32OpenQueue(PPid, PHq, PName : LongInt) : LongInt;
Begin
  Dos32OpenQueue := OpenQ(PPid, PHq, PName);
End;

Function DosOpenQueue(PPid, PHq, PName : LongInt) : LongInt;
Begin
  DosOpenQueue := OpenQ(PPid, PHq, PName);
End;

{ ---------------------------------------------------------------------
  Dos32CloseQueue(hq) : fermer la file (le proprietaire la supprime) }
Function Dos32CloseQueue(Hq : LongInt) : LongInt;
Begin
  Dos32CloseQueue := CloseQ(Hq);
End;

Function DosCloseQueue(Hq : LongInt) : LongInt;
Begin
  DosCloseQueue := CloseQ(Hq);
End;

{ ---------------------------------------------------------------------
  Dos32PurgeQueue(hq) : retirer tous les elements (proprietaire) }
Function Dos32PurgeQueue(Hq : LongInt) : LongInt;
Begin
  Dos32PurgeQueue := PurgeQ(Hq);
End;

Function DosPurgeQueue(Hq : LongInt) : LongInt;
Begin
  DosPurgeQueue := PurgeQ(Hq);
End;

{ ---------------------------------------------------------------------
  Dos32QueryQueue(hq, pcbEntries) : nombre d'elements }
Function Dos32QueryQueue(Hq, PCount : LongInt) : LongInt;
Begin
  Dos32QueryQueue := QueryQ(Hq, PCount);
End;

Function DosQueryQueue(Hq, PCount : LongInt) : LongInt;
Begin
  DosQueryQueue := QueryQ(Hq, PCount);
End;

{ ---------------------------------------------------------------------
  Dos32WriteQueue(hq, ulRequest, cbData, pbData, ulPriority) : ajouter un
  element (priorite 0 a 15, file QUE_PRIORITY) }
Function Dos32WriteQueue(Hq, Req, Cb, PData, Prio : LongInt) : LongInt;
Begin
  Dos32WriteQueue := WriteQ(Hq, Req, Cb, PData, Prio);
End;

Function DosWriteQueue(Hq, Req, Cb, PData, Prio : LongInt) : LongInt;
Begin
  DosWriteQueue := WriteQ(Hq, Req, Cb, PData, Prio);
End;

{ ---------------------------------------------------------------------
  Dos32ReadQueue(hq, pRequest, pcbData, ppbuf, ulElement, bWait,
  pbPriority, hsem) : retirer un element (proprietaire). REQUESTDATA <-
  processus ecrivain et code de requete ; *pcbData, *ppbuf <- longueur et
  adresse des donnees ; *pbPriority <- priorite. ulElement 0 : selon
  l'ordre de la file, sinon le code rendu par DosPeekQueue. }
Function Dos32ReadQueue(Hq, PReq, PCb, PPBuf, Elem, Wait, PPrio, HSem : LongInt) : LongInt;
Begin
  Dos32ReadQueue := GetQ(Hq, PReq, PCb, PPBuf, Elem, Wait, PPrio, HSem, False, False);
End;

{ DosReadQueue (OS/2 1.x) : QUEUERESULT (pidProcess, usEventCode) }
Function DosReadQueue(Hq, PReq, PCb, PPBuf, Elem, Wait, PPrio, HSem : LongInt) : LongInt;
Begin
  DosReadQueue := GetQ(Hq, PReq, PCb, PPBuf, Elem, Wait, PPrio, HSem, False, True);
End;

{ ---------------------------------------------------------------------
  Dos32PeekQueue(hq, pRequest, pcbData, ppbuf, pElemCode, bWait,
  pbPriority, hsem) : consulter un element sans le retirer.
  *pElemCode : 0 = premier, sinon element suivant de celui-ci ; rendu :
  code de l'element (pour DosReadQueue ou le DosPeekQueue suivant) }
Function Dos32PeekQueue(Hq, PReq, PCb, PPBuf, PCode, Wait, PPrio, HSem : LongInt) : LongInt;
Begin
  Dos32PeekQueue := GetQ(Hq, PReq, PCb, PPBuf, PCode, Wait, PPrio, HSem, True, False);
End;

Function DosPeekQueue(Hq, PReq, PCb, PPBuf, PCode, Wait, PPrio, HSem : LongInt) : LongInt;
Begin
  DosPeekQueue := GetQ(Hq, PReq, PCb, PPBuf, PCode, Wait, PPrio, HSem, True, True);
End;

{ ==================================================================== }
{ Exportations                                                         }
{ ==================================================================== }

exports
  DosReadQueue Index 1, DosPurgeQueue Index 2, DosCloseQueue Index 3,
  DosQueryQueue Index 4, DosPeekQueue Index 5, DosWriteQueue Index 6,
  DosOpenQueue Index 7, DosCreateQueue Index 8,
  Dos32ReadQueue Index 9, Dos32PurgeQueue Index 10, Dos32CloseQueue Index 11,
  Dos32QueryQueue Index 12, Dos32PeekQueue Index 13, Dos32WriteQueue Index 14,
  Dos32OpenQueue Index 15, Dos32CreateQueue Index 16;

Var
  InitI : LongInt;

BEGIN
  For InitI := 0 To MaxQ - 1 Do
  Begin
    QUsed[InitI] := False;
    QGen[InitI] := 1;
  End;
  For InitI := 0 To MaxAcc - 1 Do AQueue[InitI] := -1;
  For InitI := 0 To MaxElem - 1 Do EQueue[InitI] := -1;
  NextSeq := 0;
END.
