{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 NAMPIPES.DLL de OS/2-0 (tuyaux nommes).
}

Library NAMPIPES;

{$IMAGEBASE $00DB0000}
{$R-,S-,I-}

{ Compilation : OS2PC NAMPIPES.PAS   (produit NAMPIPES.DLL)

  NAMPIPES.DLL gere les tuyaux nommes d'OS/2 (\PIPE\nom) : instances
  multiples d'un meme nom, tuyaux d'octets ou de messages, acces entrant,
  sortant ou bidirectionnel, mode bloquant ou non et mode de lecture
  (octets ou messages) propres a chaque bout, lecture sans retrait,
  transactions, lecture et ecriture brutes et semaphores attachees.

  Les handles des tuyaux sont des handles de DOSCALLS.DLL : DosRead,
  DosWrite et DosClose s'y appliquent (DOSCALLS appelle NpRead, NpWrite et
  NpCloseEnd de cette DLL) et un client ouvre le tuyau par
  DosOpen("\PIPE\nom") (NpOpenClient). Les fonctions DosXxxNPipe d'OS/2
  2.x de DOSCALLS.DLL sont transmises a NAMPIPES.DLL.

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires ; un pointeur vers une valeur simple (phPipe, pcbRead,
  pfsState...) designe un LongInt. Structures d'OS/2 :
    AVAILDATA     cbpipe, cbmessage (mots)
    PIPEINFO      cbOut, cbIn (mots), cbMaxInst, cbCurInst, cbName
                  (octets), szName
    PIPESEMSTATE  fStatus, fFlag (octets), usKey, usAvail (mots)
  Exemple :
    Function DosMakeNmPipe(PName, PH, OpenMode, PipeMode, CbOut, CbIn,
                           TimeOut : LongInt) : LongInt; External 'NAMPIPES';

  Modes : fsOpenMode 0 entrant (client -> serveur), 1 sortant, 2
  bidirectionnel ; fsPipeMode : nombre d'instances (octet bas, FFh sans
  limite), 0100h lecture par messages, 0400h tuyau de messages, 8000h
  non bloquant. Un message est range avec un en-tete de 2 octets (sa
  longueur) : c'est ce que lisent et ecrivent DosRawReadNmPipe et
  DosRawWriteNmPipe.

  Les processus s'executant un a la fois, une operation qui devrait
  attendre l'autre bout ne peut aboutir : une lecture d'un tuyau vide
  rend ERROR_NO_DATA, DosConnectNmPipe sans client rend
  ERROR_PIPE_NOT_CONNECTED (l'instance reste a l'ecoute), DosWaitNmPipe
  sans instance libre ERROR_SEM_TIMEOUT, et une transaction sans reponse
  ERROR_NO_DATA (la demande est remise au serveur). Une instance creee
  est a l'ecoute : un client peut l'ouvrir aussitot.

  Fonctions exportees (ordinaux d'origine de NAMPIPES.DLL) :
     1 DosMakeNmPipe        6 DosSetNmPHandState   11 DosRawReadNmPipe
     2 DosQNmPipeInfo       7 DosPeekNmPipe        12 DosRawWriteNmPipe
     3 DosConnectNmPipe     8 DosWaitNmPipe        13 DosSetNmPipeSem
     4 DosDisConnectNmPipe  9 DosTransactNmPipe    14 DosQNmPipeSemState
     5 DosQNmPHandState    10 DosCallNmPipe
  et pour DOSCALLS.DLL : 101 NpOpenClient, 102 NpRead, 103 NpWrite,
  104 NpCloseEnd.

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services de DOSCALLS.DLL
    Partie 3 - Utilitaires
    Partie 4 - Tampons circulaires et messages
    Partie 5 - Instances et bouts
    Partie 6 - Lecture et ecriture
    Partie 7 - Fonctions DosXxxNmPipe
    Partie 8 - Services de DOSCALLS.DLL (handles des tuyaux)
    Exportations }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  NO_ERROR                 = 0;
  ERROR_FILE_NOT_FOUND     = 2;
  ERROR_PATH_NOT_FOUND     = 3;
  ERROR_TOO_MANY_OPEN_FILES = 4;
  ERROR_ACCESS_DENIED      = 5;
  ERROR_INVALID_HANDLE     = 6;
  ERROR_BAD_FORMAT         = 11;
  ERROR_OUT_OF_STRUCTURES  = 14;
  ERROR_INVALID_PARAMETER  = 87;
  ERROR_BROKEN_PIPE        = 109;
  ERROR_BUFFER_OVERFLOW    = 111;
  ERROR_SEM_TIMEOUT        = 121;
  ERROR_INVALID_LEVEL      = 124;
  ERROR_BAD_PIPE           = 230;
  ERROR_PIPE_BUSY          = 231;
  ERROR_NO_DATA            = 232;
  ERROR_PIPE_NOT_CONNECTED = 233;
  ERROR_MORE_DATA          = 234;

  { etats }
  NP_DISCONNECTED = 1;
  NP_LISTENING    = 2;
  NP_CONNECTED    = 3;
  NP_CLOSING      = 4;

  { modes }
  NP_ACCESS_INBOUND  = 0;
  NP_ACCESS_OUTBOUND = 1;
  NP_ACCESS_DUPLEX   = 2;
  NP_NBLK     = $8000;
  NP_SERVER   = $4000;
  NP_WMESG    = $0400;
  NP_RMESG    = $0100;
  NP_ICOUNT   = $00FF;

  { PIPESEMSTATE }
  NPSS_EOI    = 0;
  NPSS_RDATA  = 1;
  NPSS_WSPACE = 2;
  NPSS_CLOSE  = 3;

  HK_NPSRV = 5;              { genres de handles de DOSCALLS.DLL }
  HK_NPCLI = 6;

  MaxI    = 16;              { instances }
  RingMax = 4096;            { taille maximale d'un tampon }

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  IUsed     : Array[0..MaxI - 1] Of Boolean;
  IName     : Array[0..MaxI - 1] Of String[63];
  IOpenMode : Array[0..MaxI - 1] Of LongInt;
  IPipeMode : Array[0..MaxI - 1] Of LongInt;
  IState    : Array[0..MaxI - 1] Of LongInt;
  ITimeout  : Array[0..MaxI - 1] Of LongInt;
  ISrvTok, ICliTok : Array[0..MaxI - 1] Of LongInt;   { 0 : bout ferme }
  ISrvPid, ICliPid : Array[0..MaxI - 1] Of LongInt;
  ISrvMode, ICliMode : Array[0..MaxI - 1] Of LongInt; { NP_NBLK, NP_RMESG }
  ISrvSem, ICliSem : Array[0..MaxI - 1] Of LongInt;
  ISrvKey, ICliKey : Array[0..MaxI - 1] Of LongInt;

  { tampons : 2 par instance (serveur -> client, client -> serveur) }
  RSize, RCount, RPos : Array[0..MaxI * 2 - 1] Of LongInt;
  RingMem   : Array[0..MaxI * 2 * RingMax - 1] Of Byte;

  NextTok   : LongInt;
  NameZ     : Array[0..127] Of Byte;
  TmpBuf    : Array[0..RingMax + 15] Of Byte;

{ ==================================================================== }
{ Partie 2 - Services de DOSCALLS.DLL                                  }
{ ==================================================================== }

Function NpAllocHandle(Kind, Tok, Mode, PName : LongInt) : LongInt; External 'DOSCALLS' Name 'NpAllocHandle';
Function NpQueryHandle(H, PKind : LongInt) : LongInt; External 'DOSCALLS' Name 'NpQueryHandle';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';
Function DcPostEventSem(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosPostEventSem';
Function DcQueryEventSem(H, PCount : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryEventSem';
Function DcSemClear(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSemClear';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
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
{ Partie 4 - Tampons circulaires et messages                           }
{ ==================================================================== }

{ Tampon R : RingMem[R * RingMax ...], RSize octets, RCount occupes a
  partir de RPos }

Function RAt(R, K : LongInt) : LongInt;
Begin
  RAt := RingMem[R * RingMax + (RPos[R] + K) Mod RSize[R]];
End;

Procedure RSetAt(R, K, V : LongInt);
Begin
  RingMem[R * RingMax + (RPos[R] + K) Mod RSize[R]] := V And $FF;
End;

Function RFree(R : LongInt) : LongInt;
Begin
  RFree := RSize[R] - RCount[R];
End;

{ Ajouter N octets (rend le nombre ajoute) }
Function RPut(R, Src, N : LongInt) : LongInt;
Var K : LongInt;
Begin
  If N > RFree(R) Then N := RFree(R);
  For K := 0 To N - 1 Do
    RingMem[R * RingMax + (RPos[R] + RCount[R] + K) Mod RSize[R]] := RdB(Src + K);
  RCount[R] := RCount[R] + N;
  RPut := N;
End;

Procedure RPutW(R, V : LongInt);
Begin
  RingMem[R * RingMax + (RPos[R] + RCount[R]) Mod RSize[R]] := V And $FF;
  RingMem[R * RingMax + (RPos[R] + RCount[R] + 1) Mod RSize[R]] := (V Shr 8) And $FF;
  RCount[R] := RCount[R] + 2;
End;

{ Copier N octets a partir de la position K (sans retirer) }
Procedure RCopy(R, K, Dst, N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do WrB(Dst + I, RAt(R, K + I));
End;

Procedure RDrop(R, N : LongInt);
Begin
  RPos[R] := (RPos[R] + N) Mod RSize[R];
  RCount[R] := RCount[R] - N;
End;

{ Longueur du message commencant a la position K }
Function MsgLenAt(R, K : LongInt) : LongInt;
Begin
  MsgLenAt := RAt(R, K) Or (RAt(R, K + 1) Shl 8);
End;

{ Octets de donnees (sans les en-tetes) ; Msg : tuyau de messages }
Function DataBytes(R : LongInt; Msg : Boolean) : LongInt;
Var K, N : LongInt;
Begin
  If Not Msg Then
  Begin
    DataBytes := RCount[R];
    Exit;
  End;
  N := 0;
  K := 0;
  While K + 2 <= RCount[R] Do
  Begin
    N := N + MsgLenAt(R, K);
    K := K + 2 + MsgLenAt(R, K);
  End;
  DataBytes := N;
End;

{ Lire ou consulter (Peek) jusqu'a N octets.
  Msg : tuyau de messages ; RMsg : lecture par messages (un message au
  plus ; ERROR_MORE_DATA s'il ne tient pas). Got <- octets lus. }
Function RRead(R, Dst, N : LongInt; Msg, RMsg, Peek : Boolean; Var Got : LongInt) : LongInt;
Var Res, L, C, K, P : LongInt; Done : Boolean;
Begin
  Res := NO_ERROR;
  Got := 0;
  If Not Msg Then
  Begin
    If N > RCount[R] Then N := RCount[R];
    RCopy(R, 0, Dst, N);
    If Not Peek Then RDrop(R, N);
    Got := N;
  End
  Else If RMsg Then
  Begin
    { un message }
    If RCount[R] >= 2 Then
    Begin
      L := MsgLenAt(R, 0);
      C := L;
      If C > N Then
      Begin
        C := N;
        Res := ERROR_MORE_DATA;
      End;
      RCopy(R, 2, Dst, C);
      Got := C;
      If Not Peek Then
      Begin
        If C = L Then RDrop(R, 2 + L)
        Else
        Begin
          { reste du message : nouvel en-tete devant les octets restants }
          RSetAt(R, C, L - C);
          RSetAt(R, C + 1, (L - C) Shr 8);
          RDrop(R, C);
        End;
      End;
    End;
  End
  Else
  Begin
    { flot d'octets a travers les messages }
    P := 0;
    Done := False;
    While (Got < N) And (Not Done) Do
    Begin
      If P + 2 > RCount[R] Then Done := True
      Else
      Begin
        L := MsgLenAt(R, P);
        C := L;
        If C > N - Got Then C := N - Got;
        RCopy(R, P + 2, Dst + Got, C);
        Got := Got + C;
        If Peek Then P := P + 2 + L
        Else If C = L Then RDrop(R, 2 + L)
        Else
        Begin
          RSetAt(R, C, L - C);
          RSetAt(R, C + 1, (L - C) Shr 8);
          RDrop(R, C);
        End;
      End;
    End;
  End;
  RRead := Res;
End;

{ ==================================================================== }
{ Partie 5 - Instances et bouts                                        }
{ ==================================================================== }

Function IsMsgPipe(I : LongInt) : Boolean;
Begin
  IsMsgPipe := (IPipeMode[I] And NP_WMESG) <> 0;
End;

{ Tampon lu par le bout (serveur : client -> serveur) }
Function ReadRing(I : LongInt; Srv : Boolean) : LongInt;
Begin
  If Srv Then ReadRing := I * 2 + 1 Else ReadRing := I * 2;
End;

Function WriteRing(I : LongInt; Srv : Boolean) : LongInt;
Begin
  If Srv Then WriteRing := I * 2 Else WriteRing := I * 2 + 1;
End;

Function CanRead(I : LongInt; Srv : Boolean) : Boolean;
Var A : LongInt;
Begin
  A := IOpenMode[I] And 3;
  If Srv Then CanRead := (A = NP_ACCESS_INBOUND) Or (A = NP_ACCESS_DUPLEX)
  Else CanRead := (A = NP_ACCESS_OUTBOUND) Or (A = NP_ACCESS_DUPLEX);
End;

Function CanWrite(I : LongInt; Srv : Boolean) : Boolean;
Var A : LongInt;
Begin
  A := IOpenMode[I] And 3;
  If Srv Then CanWrite := (A = NP_ACCESS_OUTBOUND) Or (A = NP_ACCESS_DUPLEX)
  Else CanWrite := (A = NP_ACCESS_INBOUND) Or (A = NP_ACCESS_DUPLEX);
End;

Function EndMode(I : LongInt; Srv : Boolean) : LongInt;
Begin
  If Srv Then EndMode := ISrvMode[I] Else EndMode := ICliMode[I];
End;

{ Signaler la semaphore attachee au bout Srv (donnees, place, fermeture) }
Procedure Notify(I : LongInt; Srv : Boolean);
Var S, D : LongInt;
Begin
  If Srv Then S := ISrvSem[I] Else S := ICliSem[I];
  If S <> 0 Then
  Begin
    If (S And $FF000000) = $0F000000 Then D := DcSemClear(S)   { semaphore systeme 1.x }
    Else D := DcPostEventSem(S);
  End;
End;

Procedure FreeInst(I : LongInt);
Begin
  IUsed[I] := False;
  ISrvTok[I] := 0;
  ICliTok[I] := 0;
End;

Function NewTok(I : LongInt) : LongInt;
Begin
  Inc(NextTok);
  If NextTok > $7FFFFF Then NextTok := 1;
  NewTok := (NextTok Shl 8) Or I;
End;

{ Fermer un bout ; l'instance disparait quand les deux sont fermes }
Procedure CloseEnd(I : LongInt; Srv : Boolean);
Begin
  If Srv Then
  Begin
    ISrvTok[I] := 0;
    ISrvSem[I] := 0;
    If ICliTok[I] = 0 Then FreeInst(I) Else Notify(I, False);
  End
  Else
  Begin
    ICliTok[I] := 0;
    ICliSem[I] := 0;
    If ISrvTok[I] = 0 Then FreeInst(I)
    Else
    Begin
      If IState[I] = NP_CONNECTED Then IState[I] := NP_CLOSING;
      Notify(I, True);
    End;
  End;
End;

{ Bouts des processus termines : fermes }
Procedure Purge;
Var I : LongInt;
Begin
  For I := 0 To MaxI - 1 Do
    If IUsed[I] Then
    Begin
      If (ICliTok[I] <> 0) And (KrnMonIo(0, 4, ICliPid[I]) = 0) Then CloseEnd(I, False);
      If IUsed[I] And (ISrvTok[I] <> 0) And (KrnMonIo(0, 4, ISrvPid[I]) = 0) Then CloseEnd(I, True);
    End;
End;

{ Instance d'un jeton (-1 : perime) ; Srv : bout serveur }
Function TokInst(Tok : LongInt; Srv : Boolean) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  I := Tok And $FF;
  If (Tok > 0) And (I < MaxI) Then
    If IUsed[I] Then
    Begin
      If Srv And (ISrvTok[I] = Tok) Then R := I;
      If (Not Srv) And (ICliTok[I] = Tok) Then R := I;
    End;
  TokInst := R;
End;

{ Handle de DOSCALLS -> instance ; Srv <- bout serveur. Rend le code
  d'erreur (ERROR_INVALID_HANDLE, ERROR_PIPE_NOT_CONNECTED : client
  deconnecte par le serveur). }
Function HandleInst(H : LongInt; Var I : LongInt; Var Srv : Boolean) : LongInt;
Var Tok, Kind : LongInt;
Begin
  Purge;
  Kind := 0;
  I := -1;
  Tok := NpQueryHandle(H, LongInt(@Kind));
  If (Tok <= 0) Or ((Kind <> HK_NPSRV) And (Kind <> HK_NPCLI)) Then
  Begin
    HandleInst := ERROR_INVALID_HANDLE;
    Exit;
  End;
  Srv := Kind = HK_NPSRV;
  I := TokInst(Tok, Srv);
  If I < 0 Then
  Begin
    If Srv Then HandleInst := ERROR_INVALID_HANDLE
    Else HandleInst := ERROR_PIPE_NOT_CONNECTED;
    Exit;
  End;
  HandleInst := NO_ERROR;
End;

Function CountInst(Name : String) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxI - 1 Do
    If IUsed[I] And (IName[I] = Name) Then Inc(N);
  CountInst := N;
End;

{ Instance a l'ecoute du nom (-1 : aucune) }
Function FindListening(Name : String) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := MaxI - 1 DownTo 0 Do
    If IUsed[I] And (IName[I] = Name) And (ISrvTok[I] <> 0) And (IState[I] = NP_LISTENING) Then R := I;
  FindListening := R;
End;

Function ValidName(Name : String) : Boolean;
Begin
  ValidName := (Copy(Name, 1, 6) = '\PIPE\') And (Length(Name) > 6) And (Length(Name) <= 63);
End;

{ Ouvrir le bout client d'une instance a l'ecoute ; Tok <- jeton }
Function OpenClient(Name : String; Var Tok : LongInt) : LongInt;
Var I : LongInt;
Begin
  Purge;
  If Not ValidName(Name) Then
  Begin
    OpenClient := ERROR_PATH_NOT_FOUND;
    Exit;
  End;
  If CountInst(Name) = 0 Then
  Begin
    OpenClient := ERROR_FILE_NOT_FOUND;
    Exit;
  End;
  I := FindListening(Name);
  If I < 0 Then
  Begin
    OpenClient := ERROR_PIPE_BUSY;
    Exit;
  End;
  Tok := NewTok(I);
  ICliTok[I] := Tok;
  ICliPid[I] := MyPid;
  ICliMode[I] := 0;                      { bloquant, lecture par octets }
  ICliSem[I] := 0;
  IState[I] := NP_CONNECTED;
  Notify(I, True);
  OpenClient := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 6 - Lecture et ecriture                                       }
{ ==================================================================== }

{ Lire sur le bout Srv de l'instance I ; Raw : avec les en-tetes }
Function EndRead(I : LongInt; Srv : Boolean; Buf, N : LongInt; Raw : Boolean; Var Got : LongInt) : LongInt;
Var R, Rg : LongInt; RMsg, Other : Boolean;
Begin
  Got := 0;
  If N < 0 Then
  Begin
    EndRead := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If Not CanRead(I, Srv) Then
  Begin
    EndRead := ERROR_ACCESS_DENIED;
    Exit;
  End;
  If Srv And ((IState[I] = NP_LISTENING) Or (IState[I] = NP_DISCONNECTED)) Then
  Begin
    EndRead := ERROR_PIPE_NOT_CONNECTED;
    Exit;
  End;
  Rg := ReadRing(I, Srv);
  If RCount[Rg] = 0 Then
  Begin
    { vide : fin de fichier si l'autre bout est ferme }
    If Srv Then Other := ICliTok[I] <> 0 Else Other := ISrvTok[I] <> 0;
    If Other Then EndRead := ERROR_NO_DATA Else EndRead := NO_ERROR;
    Exit;
  End;
  RMsg := (EndMode(I, Srv) And NP_RMESG) <> 0;
  If Raw Then R := RRead(Rg, Buf, N, False, False, False, Got)
  Else R := RRead(Rg, Buf, N, IsMsgPipe(I), RMsg, False, Got);
  Notify(I, Not Srv);                    { place libre pour l'autre bout }
  EndRead := R;
End;

{ Ecrire sur le bout Srv ; Raw : en-tetes fournis par l'appelant }
Function EndWrite(I : LongInt; Srv : Boolean; Buf, N : LongInt; Raw : Boolean; Var Done : LongInt) : LongInt;
Var Rg, K, L : LongInt;
Begin
  Done := 0;
  If N < 0 Then
  Begin
    EndWrite := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If Not CanWrite(I, Srv) Then
  Begin
    EndWrite := ERROR_ACCESS_DENIED;
    Exit;
  End;
  If Srv Then
  Begin
    If (IState[I] = NP_LISTENING) Or (IState[I] = NP_DISCONNECTED) Then
    Begin
      EndWrite := ERROR_PIPE_NOT_CONNECTED;
      Exit;
    End;
    If (IState[I] = NP_CLOSING) Or (ICliTok[I] = 0) Then
    Begin
      EndWrite := ERROR_BROKEN_PIPE;
      Exit;
    End;
  End
  Else If ISrvTok[I] = 0 Then
  Begin
    EndWrite := ERROR_BROKEN_PIPE;
    Exit;
  End;
  Rg := WriteRing(I, Srv);
  If Raw And IsMsgPipe(I) Then
  Begin
    { les en-tetes doivent decrire des messages complets }
    K := 0;
    While K + 2 <= N Do K := K + 2 + (RdB(Buf + K) Or (RdB(Buf + K + 1) Shl 8));
    If K <> N Then
    Begin
      EndWrite := ERROR_INVALID_PARAMETER;
      Exit;
    End;
    If N <= RFree(Rg) Then Done := RPut(Rg, Buf, N);
  End
  Else If IsMsgPipe(I) And Not Raw Then
  Begin
    { un message entier, ou rien s'il ne tient pas }
    If N + 2 <= RFree(Rg) Then
    Begin
      RPutW(Rg, N);
      L := RPut(Rg, Buf, N);
      Done := N;
    End;
  End
  Else
    Done := RPut(Rg, Buf, N);
  If Done > 0 Then Notify(I, Not Srv);
  If (Done = 0) And (N > 0) And IsMsgPipe(I) And Not Raw And (N + 2 > RSize[Rg]) Then
  Begin
    EndWrite := ERROR_MORE_DATA;             { message plus grand que le tampon }
    Exit;
  End;
  EndWrite := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 7 - Fonctions DosXxxNmPipe                                    }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  DosMakeNmPipe(pszName, phPipe, fsOpenMode, fsPipeMode, cbOutBuf,
  cbInBuf, ulTimeOut) : creer une instance du tuyau \PIPE\nom ; *phPipe
  <- handle du serveur. cbOutBuf/cbInBuf : tampons serveur -> client et
  client -> serveur (4096 octets au plus, 0 : 4096). ulTimeOut : attente
  par defaut de DosWaitNmPipe. L'instance est creee a l'ecoute. }
Function DosMakeNmPipe(PName, PH, OpenMode, PipeMode, CbOut, CbIn, TimeOut : LongInt) : LongInt;
Var I, F, H, Tok, Cnt, Max : LongInt; Name : String;
Begin
  Purge;
  Name := GetZ(PName);
  If (PName = 0) Or Not ValidName(Name) Then
  Begin
    DosMakeNmPipe := ERROR_PATH_NOT_FOUND;
    Exit;
  End;
  Max := PipeMode And NP_ICOUNT;
  If (PH = 0) Or ((OpenMode And 3) > NP_ACCESS_DUPLEX) Or ((OpenMode And Not $40C3) <> 0) Or
     ((PipeMode And Not $C5FF) <> 0) Or (Max = 0) Or
     (((PipeMode And NP_RMESG) <> 0) And ((PipeMode And NP_WMESG) = 0)) Then
  Begin
    DosMakeNmPipe := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  { instances du meme nom : meme nombre maximal }
  Cnt := CountInst(Name);
  If Cnt > 0 Then
  Begin
    For I := 0 To MaxI - 1 Do
      If IUsed[I] And (IName[I] = Name) Then Max := IPipeMode[I] And NP_ICOUNT;
    If (Max <> NP_ICOUNT) And (Cnt >= Max) Then
    Begin
      DosMakeNmPipe := ERROR_PIPE_BUSY;
      Exit;
    End;
  End;
  F := -1;
  For I := MaxI - 1 DownTo 0 Do
    If Not IUsed[I] Then F := I;
  If F < 0 Then
  Begin
    DosMakeNmPipe := ERROR_OUT_OF_STRUCTURES;
    Exit;
  End;
  Tok := NewTok(F);
  H := NpAllocHandle(HK_NPSRV, Tok, OpenMode, PName);
  If H < 0 Then
  Begin
    DosMakeNmPipe := ERROR_TOO_MANY_OPEN_FILES;
    Exit;
  End;
  If (CbOut <= 0) Or (CbOut > RingMax) Then CbOut := RingMax;
  If (CbIn <= 0) Or (CbIn > RingMax) Then CbIn := RingMax;
  If CbOut < 16 Then CbOut := 16;
  If CbIn < 16 Then CbIn := 16;
  IUsed[F] := True;
  IName[F] := Name;
  IOpenMode[F] := OpenMode;
  IPipeMode[F] := (PipeMode And Not NP_ICOUNT) Or Max;
  IState[F] := NP_LISTENING;
  ITimeout[F] := TimeOut;
  ISrvTok[F] := Tok;
  ICliTok[F] := 0;
  ISrvPid[F] := MyPid;
  ISrvMode[F] := PipeMode And (NP_NBLK Or NP_RMESG);
  ICliMode[F] := 0;
  ISrvSem[F] := 0; ICliSem[F] := 0;
  RSize[F * 2] := CbOut; RCount[F * 2] := 0; RPos[F * 2] := 0;
  RSize[F * 2 + 1] := CbIn; RCount[F * 2 + 1] := 0; RPos[F * 2 + 1] := 0;
  WrL(PH, H);
  DosMakeNmPipe := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  DosQNmPipeInfo(hPipe, usInfoLevel, pBuf, cbBuf) : niveau 1, PIPEINFO
  (tailles des tampons du serveur, instances maximales (FFh : sans
  limite) et en cours, nom) }
Function DosQNmPipeInfo(H, Level, PBuf, CbBuf : LongInt) : LongInt;
Var R, I, K : LongInt; Srv : Boolean;
Begin
  R := HandleInst(H, I, Srv);
  If R = NO_ERROR Then
  Begin
    If Level <> 1 Then R := ERROR_INVALID_LEVEL
    Else If (PBuf = 0) Or (CbBuf < 8 + Length(IName[I])) Then R := ERROR_BUFFER_OVERFLOW
    Else
    Begin
      WrW(PBuf, RSize[I * 2]);
      WrW(PBuf + 2, RSize[I * 2 + 1]);
      WrB(PBuf + 4, IPipeMode[I] And NP_ICOUNT);
      WrB(PBuf + 5, CountInst(IName[I]));
      WrB(PBuf + 6, Length(IName[I]));
      For K := 1 To Length(IName[I]) Do WrB(PBuf + 6 + K, Ord(IName[I][K]));
      WrB(PBuf + 7 + Length(IName[I]), 0);
    End;
  End;
  DosQNmPipeInfo := R;
End;

{ ---------------------------------------------------------------------
  DosConnectNmPipe(hPipe) : mettre l'instance a l'ecoute d'un client
  (serveur) ; NO_ERROR si un client est connecte, sinon
  ERROR_PIPE_NOT_CONNECTED (l'instance reste a l'ecoute) ;
  ERROR_BROKEN_PIPE si le client a ferme (DosDisConnectNmPipe d'abord) }
Function DosConnectNmPipe(H : LongInt) : LongInt;
Var R, I : LongInt; Srv : Boolean;
Begin
  R := HandleInst(H, I, Srv);
  If (R = NO_ERROR) And Not Srv Then R := ERROR_BAD_PIPE;
  If R = NO_ERROR Then
  Begin
    Case IState[I] Of
      NP_CONNECTED : R := NO_ERROR;
      NP_CLOSING   : R := ERROR_BROKEN_PIPE;
    Else
      IState[I] := NP_LISTENING;
      R := ERROR_PIPE_NOT_CONNECTED;
    End;
  End;
  DosConnectNmPipe := R;
End;

{ ---------------------------------------------------------------------
  DosDisConnectNmPipe(hPipe) : deconnecter le client (serveur) ; les
  donnees sont perdues et le handle du client ne sert plus qu'a DosClose }
Function DosDisConnectNmPipe(H : LongInt) : LongInt;
Var R, I : LongInt; Srv : Boolean;
Begin
  R := HandleInst(H, I, Srv);
  If (R = NO_ERROR) And Not Srv Then R := ERROR_BAD_PIPE;
  If R = NO_ERROR Then
  Begin
    If ICliTok[I] <> 0 Then Notify(I, False);
    ICliTok[I] := 0;
    ICliSem[I] := 0;
    RCount[I * 2] := 0; RPos[I * 2] := 0;
    RCount[I * 2 + 1] := 0; RPos[I * 2 + 1] := 0;
    IState[I] := NP_DISCONNECTED;
  End;
  DosDisConnectNmPipe := R;
End;

{ ---------------------------------------------------------------------
  DosQNmPHandState(hPipe, pfsState) : etat du handle : NP_NBLK (8000h),
  NP_SERVER (4000h), NP_WMESG (0400h), NP_RMESG (0100h), nombre maximal
  d'instances (octet bas) }
Function DosQNmPHandState(H, PState : LongInt) : LongInt;
Var R, I, S : LongInt; Srv : Boolean;
Begin
  R := HandleInst(H, I, Srv);
  If (R = NO_ERROR) And (PState = 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then
  Begin
    S := EndMode(I, Srv) Or (IPipeMode[I] And (NP_WMESG Or NP_ICOUNT));
    If Srv Then S := S Or NP_SERVER;
    WrL(PState, S);
  End;
  DosQNmPHandState := R;
End;

{ ---------------------------------------------------------------------
  DosSetNmPHandState(hPipe, fsState) : mode bloquant (NP_NBLK) et mode
  de lecture (NP_RMESG, tuyau de messages seulement) du handle }
Function DosSetNmPHandState(H, State : LongInt) : LongInt;
Var R, I : LongInt; Srv : Boolean;
Begin
  R := HandleInst(H, I, Srv);
  If R = NO_ERROR Then
  Begin
    If (State And Not (NP_NBLK Or NP_RMESG)) <> 0 Then R := ERROR_INVALID_PARAMETER
    Else If ((State And NP_RMESG) <> 0) And Not IsMsgPipe(I) Then R := ERROR_INVALID_PARAMETER
    Else If Srv Then ISrvMode[I] := State
    Else ICliMode[I] := State;
  End;
  DosSetNmPHandState := R;
End;

{ ---------------------------------------------------------------------
  DosPeekNmPipe(hPipe, pBuf, cbBuf, pcbRead, pAvail, pfsState) : lire
  sans retirer (un message au plus en lecture par messages) ;
  AVAILDATA : octets dans le tuyau, octets du message courant ; *pfsState
  <- etat (NP_DISCONNECTED, NP_LISTENING, NP_CONNECTED, NP_CLOSING) }
Function DosPeekNmPipe(H, PBuf, CbBuf, PcbRead, PAvail, PState : LongInt) : LongInt;
Var R, I, Rg, Got, St, D : LongInt; Srv : Boolean;
Begin
  R := HandleInst(H, I, Srv);
  If (R = NO_ERROR) And ((PBuf = 0) And (CbBuf > 0)) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then
  Begin
    Rg := ReadRing(I, Srv);
    Got := 0;
    If CanRead(I, Srv) Then
      D := RRead(Rg, PBuf, CbBuf, IsMsgPipe(I), (EndMode(I, Srv) And NP_RMESG) <> 0, True, Got);
    WrL(PcbRead, Got);
    WrW(PAvail, DataBytes(Rg, IsMsgPipe(I)));
    If IsMsgPipe(I) And (RCount[Rg] >= 2) Then WrW(PAvail + 2, MsgLenAt(Rg, 0)) Else WrW(PAvail + 2, 0);
    St := IState[I];
    If (Not Srv) And (ISrvTok[I] = 0) Then St := NP_CLOSING;
    WrL(PState, St);
  End
  Else If R = ERROR_PIPE_NOT_CONNECTED Then
  Begin
    { client deconnecte par le serveur }
    WrL(PcbRead, 0);
    WrW(PAvail, 0); WrW(PAvail + 2, 0);
    WrL(PState, NP_DISCONNECTED);
    R := NO_ERROR;
  End;
  DosPeekNmPipe := R;
End;

{ ---------------------------------------------------------------------
  DosWaitNmPipe(pszName, ulTimeOut) : attendre une instance a l'ecoute.
  NO_ERROR si une instance est libre ; aucune autre ne peut le devenir
  pendant l'attente (un processus a la fois) : ERROR_SEM_TIMEOUT }
Function DosWaitNmPipe(PName, TimeOut : LongInt) : LongInt;
Var Name : String;
Begin
  Purge;
  Name := GetZ(PName);
  If Not ValidName(Name) Then DosWaitNmPipe := ERROR_PATH_NOT_FOUND
  Else If CountInst(Name) = 0 Then DosWaitNmPipe := ERROR_FILE_NOT_FOUND
  Else If FindListening(Name) >= 0 Then DosWaitNmPipe := NO_ERROR
  Else DosWaitNmPipe := ERROR_SEM_TIMEOUT;
End;

{ Transaction sur le bout Srv de l'instance I }
Function Transact(I : LongInt; Srv : Boolean; PIn, CbIn, POut, CbOut, PcbRead : LongInt) : LongInt;
Var R, Done, Got : LongInt;
Begin
  WrL(PcbRead, 0);
  If ((IOpenMode[I] And 3) <> NP_ACCESS_DUPLEX) Or Not IsMsgPipe(I) Or
     ((EndMode(I, Srv) And NP_RMESG) = 0) Then
  Begin
    Transact := ERROR_BAD_FORMAT;
    Exit;
  End;
  If RCount[ReadRing(I, Srv)] > 0 Then
  Begin
    Transact := ERROR_PIPE_BUSY;                  { donnees non lues }
    Exit;
  End;
  R := EndWrite(I, Srv, PIn, CbIn, False, Done);
  If (R = NO_ERROR) And (Done <> CbIn) Then R := ERROR_PIPE_BUSY;
  If R = NO_ERROR Then
  Begin
    R := EndRead(I, Srv, POut, CbOut, False, Got);
    WrL(PcbRead, Got);
  End;
  Transact := R;
End;

{ ---------------------------------------------------------------------
  DosTransactNmPipe(hPipe, pInBuf, cbIn, pOutBuf, cbOut, pcbRead) :
  ecrire un message puis lire la reponse (tuyau de messages
  bidirectionnel en lecture par messages ; ERROR_PIPE_BUSY s'il reste
  des donnees non lues) }
Function DosTransactNmPipe(H, PIn, CbIn, POut, CbOut, PcbRead : LongInt) : LongInt;
Var R, I : LongInt; Srv : Boolean;
Begin
  R := HandleInst(H, I, Srv);
  If R = NO_ERROR Then R := Transact(I, Srv, PIn, CbIn, POut, CbOut, PcbRead);
  DosTransactNmPipe := R;
End;

{ ---------------------------------------------------------------------
  DosCallNmPipe(pszName, pInBuf, cbIn, pOutBuf, cbOut, pcbRead,
  ulTimeOut) : ouvrir le tuyau, faire une transaction et le fermer }
Function DosCallNmPipe(PName, PIn, CbIn, POut, CbOut, PcbRead, TimeOut : LongInt) : LongInt;
Var R, I, Tok : LongInt; Name : String;
Begin
  WrL(PcbRead, 0);
  Name := GetZ(PName);
  R := OpenClient(Name, Tok);
  If R = ERROR_PIPE_BUSY Then R := ERROR_SEM_TIMEOUT;     { attente impossible }
  If R = NO_ERROR Then
  Begin
    I := Tok And $FF;
    If IsMsgPipe(I) Then ICliMode[I] := NP_RMESG;
    R := Transact(I, False, PIn, CbIn, POut, CbOut, PcbRead);
    CloseEnd(I, False);
  End;
  DosCallNmPipe := R;
End;

{ ---------------------------------------------------------------------
  DosRawReadNmPipe(hPipe, pBuf, cbBuf, pcbRead) : lire les octets bruts
  du tuyau (avec les en-tetes de 2 octets des messages) }
Function DosRawReadNmPipe(H, PBuf, CbBuf, PcbRead : LongInt) : LongInt;
Var R, I, Got : LongInt; Srv : Boolean;
Begin
  WrL(PcbRead, 0);
  R := HandleInst(H, I, Srv);
  If (R = NO_ERROR) And (PBuf = 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then
  Begin
    R := EndRead(I, Srv, PBuf, CbBuf, True, Got);
    WrL(PcbRead, Got);
  End;
  DosRawReadNmPipe := R;
End;

{ ---------------------------------------------------------------------
  DosRawWriteNmPipe(hPipe, pBuf, cbBuf, pcbWritten) : ecrire des octets
  bruts (tuyau de messages : messages complets precedes de leur
  en-tete ; tout ou rien) }
Function DosRawWriteNmPipe(H, PBuf, CbBuf, PcbWritten : LongInt) : LongInt;
Var R, I, Done : LongInt; Srv : Boolean;
Begin
  WrL(PcbWritten, 0);
  R := HandleInst(H, I, Srv);
  If (R = NO_ERROR) And (PBuf = 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then
  Begin
    R := EndWrite(I, Srv, PBuf, CbBuf, True, Done);
    WrL(PcbWritten, Done);
  End;
  DosRawWriteNmPipe := R;
End;

{ ---------------------------------------------------------------------
  DosSetNmPipeSem(hPipe, hsem, usKeyVal) : attacher une semaphore
  systeme (DosCreateSem) ou d'evenement (DosCreateEventSem) au bout du
  tuyau ; elle est liberee (DosSemClear) ou affichee (DosPostEventSem)
  quand des donnees arrivent, que de la place se libere ou que l'autre
  bout ferme. hsem = 0 : detacher. }
Function DosSetNmPipeSem(H, HSem, Key : LongInt) : LongInt;
Var R, I, C : LongInt; Srv : Boolean;
Begin
  R := HandleInst(H, I, Srv);
  If (R = NO_ERROR) And (HSem <> 0) And ((HSem And $FF000000) <> $0F000000) Then
    If DcQueryEventSem(HSem, LongInt(@C)) <> NO_ERROR Then R := ERROR_INVALID_HANDLE;
  If R = NO_ERROR Then
  Begin
    If Srv Then
    Begin
      ISrvSem[I] := HSem; ISrvKey[I] := Key And $FFFF;
    End
    Else
    Begin
      ICliSem[I] := HSem; ICliKey[I] := Key And $FFFF;
    End;
  End;
  DosSetNmPipeSem := R;
End;

{ ---------------------------------------------------------------------
  DosQNmPipeSemState(hsem, pBuf, cbBuf) : etat des bouts attaches a la
  semaphore : PIPESEMSTATE (NPSS_RDATA donnees a lire, NPSS_WSPACE place
  pour ecrire, NPSS_CLOSE autre bout ferme ; cle, octets), termine par
  NPSS_EOI }
Var
  SsP, SsEnd, SsKey : LongInt;
  SsFull : Boolean;

Procedure SemPut(St, Avail : LongInt);
Begin
  If SsP + 12 > SsEnd Then SsFull := True
  Else
  Begin
    WrB(SsP, St); WrB(SsP + 1, 0); WrW(SsP + 2, SsKey); WrW(SsP + 4, Avail);
    SsP := SsP + 6;
  End;
End;

Function DosQNmPipeSemState(HSem, PBuf, CbBuf : LongInt) : LongInt;
Var I, E, Rr, Wr : LongInt; Srv, Closed, Mine : Boolean;
Begin
  Purge;
  If (HSem = 0) Or (PBuf = 0) Then
  Begin
    DosQNmPipeSemState := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If CbBuf < 6 Then
  Begin
    DosQNmPipeSemState := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  SsP := PBuf;
  SsEnd := PBuf + CbBuf;
  SsFull := False;
  For I := 0 To MaxI - 1 Do
    If IUsed[I] Then
      For E := 0 To 1 Do
      Begin
        Srv := E = 0;
        If Srv Then Mine := (ISrvTok[I] <> 0) And (ISrvSem[I] = HSem)
        Else Mine := (ICliTok[I] <> 0) And (ICliSem[I] = HSem);
        If Mine Then
        Begin
          If Srv Then SsKey := ISrvKey[I] Else SsKey := ICliKey[I];
          Rr := ReadRing(I, Srv);
          Wr := WriteRing(I, Srv);
          If Srv Then Closed := IState[I] = NP_CLOSING
          Else Closed := ISrvTok[I] = 0;
          If CanRead(I, Srv) And (RCount[Rr] > 0) Then SemPut(NPSS_RDATA, DataBytes(Rr, IsMsgPipe(I)));
          If CanWrite(I, Srv) And (RFree(Wr) > 0) And (Not Closed) Then
            If (Not Srv) Or (IState[I] = NP_CONNECTED) Then SemPut(NPSS_WSPACE, RFree(Wr));
          If Closed Then SemPut(NPSS_CLOSE, 0);
        End;
      End;
  WrB(SsP, NPSS_EOI); WrB(SsP + 1, 0); WrW(SsP + 2, 0); WrW(SsP + 4, 0);
  If SsFull Then DosQNmPipeSemState := ERROR_BUFFER_OVERFLOW
  Else DosQNmPipeSemState := NO_ERROR;
End;

{ ==================================================================== }
{ Partie 8 - Services de DOSCALLS.DLL (handles des tuyaux)             }
{ ==================================================================== }

{ NpOpenClient(pszName, pToken) : DosOpen("\PIPE\nom") par un client }
Function NpOpenClient(PName, PTok : LongInt) : LongInt;
Var R, Tok : LongInt;
Begin
  Tok := 0;
  R := OpenClient(GetZ(PName), Tok);
  WrL(PTok, Tok);
  NpOpenClient := R;
End;

{ NpRead(Token, fServeur, pBuf, cb, pcbRead) : DosRead }
Function NpRead(Tok, IsSrv, Buf, N, PGot : LongInt) : LongInt;
Var I, Got, R : LongInt;
Begin
  Purge;
  Got := 0;
  I := TokInst(Tok, IsSrv <> 0);
  If I < 0 Then
  Begin
    If IsSrv <> 0 Then R := ERROR_INVALID_HANDLE Else R := ERROR_PIPE_NOT_CONNECTED;
  End
  Else
    R := EndRead(I, IsSrv <> 0, Buf, N, False, Got);
  WrL(PGot, Got);
  NpRead := R;
End;

{ NpWrite(Token, fServeur, pBuf, cb, pcbWritten) : DosWrite }
Function NpWrite(Tok, IsSrv, Buf, N, PDone : LongInt) : LongInt;
Var I, Done, R : LongInt;
Begin
  Purge;
  Done := 0;
  I := TokInst(Tok, IsSrv <> 0);
  If I < 0 Then
  Begin
    If IsSrv <> 0 Then R := ERROR_INVALID_HANDLE Else R := ERROR_PIPE_NOT_CONNECTED;
  End
  Else
    R := EndWrite(I, IsSrv <> 0, Buf, N, False, Done);
  WrL(PDone, Done);
  NpWrite := R;
End;

{ NpCloseEnd(Token, fServeur) : DosClose }
Function NpCloseEnd(Tok, IsSrv : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := TokInst(Tok, IsSrv <> 0);
  If I >= 0 Then CloseEnd(I, IsSrv <> 0);
  NpCloseEnd := NO_ERROR;
End;

{ ==================================================================== }
{ Exportations                                                         }
{ ==================================================================== }

exports
  DosMakeNmPipe Index 1, DosQNmPipeInfo Index 2, DosConnectNmPipe Index 3,
  DosDisConnectNmPipe Index 4, DosQNmPHandState Index 5,
  DosSetNmPHandState Index 6, DosPeekNmPipe Index 7, DosWaitNmPipe Index 8,
  DosTransactNmPipe Index 9, DosCallNmPipe Index 10,
  DosRawReadNmPipe Index 11, DosRawWriteNmPipe Index 12,
  DosSetNmPipeSem Index 13, DosQNmPipeSemState Index 14,
  NpOpenClient Index 101, NpRead Index 102, NpWrite Index 103,
  NpCloseEnd Index 104;

Var
  InitI : LongInt;

BEGIN
  For InitI := 0 To MaxI - 1 Do IUsed[InitI] := False;
  NextTok := 0;
END.
