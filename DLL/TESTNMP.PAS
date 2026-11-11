{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de NAMPIPES.DLL sous OS/2-0.
}

Program TESTNMP;

{$R-,S-,I-}

{ Compilation : OS2PC TESTNMP.PAS   (produit TESTNMP.EXE)

  TESTNMP  verifie les 14 fonctions de NAMPIPES.DLL : le serveur et le
           client d'un tuyau nomme sont deux handles du meme processus
           (instances multiples, tuyaux de messages et d'octets, modes
           de lecture, lecture sans retrait, ecriture et lecture brutes,
           transactions, semaphores, deconnexion et fermeture). }

Function DosMakeNmPipe(PName, PH, OMode, PMode, CbOut, CbIn, TimeOut : LongInt) : LongInt; External 'NAMPIPES';
Function DosQNmPipeInfo(H, Level, PBuf, CbBuf : LongInt) : LongInt; External 'NAMPIPES';
Function DosConnectNmPipe(H : LongInt) : LongInt; External 'NAMPIPES';
Function DosDisConnectNmPipe(H : LongInt) : LongInt; External 'NAMPIPES';
Function DosQNmPHandState(H, PState : LongInt) : LongInt; External 'NAMPIPES';
Function DosSetNmPHandState(H, State : LongInt) : LongInt; External 'NAMPIPES';
Function DosPeekNmPipe(H, PBuf, CbBuf, PcbRead, PAvail, PState : LongInt) : LongInt; External 'NAMPIPES';
Function DosWaitNmPipe(PName, TimeOut : LongInt) : LongInt; External 'NAMPIPES';
Function DosTransactNmPipe(H, PIn, CbIn, POut, CbOut, PcbRead : LongInt) : LongInt; External 'NAMPIPES';
Function DosCallNmPipe(PName, PIn, CbIn, POut, CbOut, PcbRead, TimeOut : LongInt) : LongInt; External 'NAMPIPES';
Function DosRawReadNmPipe(H, PBuf, CbBuf, PcbRead : LongInt) : LongInt; External 'NAMPIPES';
Function DosRawWriteNmPipe(H, PBuf, CbBuf, PcbWritten : LongInt) : LongInt; External 'NAMPIPES';
Function DosSetNmPipeSem(H, HSem, Key : LongInt) : LongInt; External 'NAMPIPES';
Function DosQNmPipeSemState(HSem, PBuf, CbBuf : LongInt) : LongInt; External 'NAMPIPES';

Function DcQueryNPHState(H, PState : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryNPHState';
Function DcCreateNPipe(PName, PH, OMode, PMode, CbOut, CbIn, Msec : LongInt) : LongInt; External 'DOSCALLS' Name 'DosCreateNPipe';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateSem(NoExcl, PHSem, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosSemSet(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosSemWait(H, Timeout : LongInt) : LongInt; External 'DOSCALLS';
Function DosCloseSem(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateEventSem(PName, PHev, Attr, State : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryEventSem(H, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosCloseEventSem(H : LongInt) : LongInt; External 'DOSCALLS';

Const
  ERROR_FILE_NOT_FOUND = 2;
  ERROR_PATH_NOT_FOUND = 3;
  ERROR_ACCESS_DENIED = 5;
  ERROR_INVALID_HANDLE = 6;
  ERROR_BAD_FORMAT = 11;
  ERROR_INVALID_PARAMETER = 87;
  ERROR_BROKEN_PIPE = 109;
  ERROR_BUFFER_OVERFLOW = 111;
  ERROR_SEM_TIMEOUT = 121;
  ERROR_INVALID_LEVEL = 124;
  ERROR_BAD_PIPE = 230;
  ERROR_PIPE_BUSY = 231;
  ERROR_NO_DATA = 232;
  ERROR_PIPE_NOT_CONNECTED = 233;
  ERROR_MORE_DATA = 234;

  { fsPipeMode / etat }
  NP_RMESG = $0100;
  NP_WMESG = $0400;
  NP_NBLK  = $8000;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, Hs1, Hs2, Hs3, Hc, Hc2, Hb, Hbc, Act, St, Sem, Ev : LongInt;
  Name : Array[0..127] Of Byte;
  Buf : Array[0..511] Of Byte;
  Txt : Array[0..127] Of Byte;
  Avail : Array[0..3] Of Byte;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var T : String;
Begin
  Str(V, T);
  IStr := T;
End;

Function HStr(V : LongInt) : String;
Const Dg = '0123456789ABCDEF';
Var T : String; K : LongInt;
Begin
  T := '';
  For K := 3 DownTo 0 Do T := T + Dg[((V Shr (K * 4)) And 15) + 1];
  HStr := T;
End;

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
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

Function BufStr(Len : LongInt) : String;
Var T : String; K : LongInt;
Begin
  T := '';
  For K := 0 To Len - 1 Do T := T + Chr(Buf[K]);
  BufStr := T;
End;

{ Ecrire un texte (N <- octets ecrits) }
Function Put(Hp : LongInt; S : String) : LongInt;
Begin
  PutZ(LongInt(@Txt), S);
  N := 0;
  Put := DosWrite(Hp, LongInt(@Txt), Length(S), LongInt(@N));
End;

{ Lire jusqu'a Cb octets (N <- octets lus) }
Function Get(Hp, Cb : LongInt) : LongInt;
Begin
  N := 0;
  For I := 0 To 31 Do Buf[I] := 0;
  Get := DosRead(Hp, LongInt(@Buf), Cb, LongInt(@N));
End;

Function Peek(Hp, Cb : LongInt) : LongInt;
Begin
  N := 0; St := 0;
  For I := 0 To 31 Do Buf[I] := 0;
  Peek := DosPeekNmPipe(Hp, LongInt(@Buf), Cb, LongInt(@N), LongInt(@Avail), LongInt(@St));
End;

Function HState(Hp : LongInt) : LongInt;
Begin
  St := 0;
  R2 := DosQNmPHandState(Hp, LongInt(@St));
  HState := St;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTNMP : essai de NAMPIPES.DLL');

  { --- module et ordinaux --- }
  R := DosQueryModuleHandle(Z('NAMPIPES'), LongInt(@H));
  Check('DosQueryModuleHandle NAMPIPES', R = 0);
  Check('ordinaux 1 a 7 (DosMakeNmPipe ... DosPeekNmPipe)',
        OrdIs(1, 'DosMakeNmPipe') And OrdIs(2, 'DosQNmPipeInfo') And OrdIs(3, 'DosConnectNmPipe') And
        OrdIs(4, 'DosDisConnectNmPipe') And OrdIs(5, 'DosQNmPHandState') And OrdIs(6, 'DosSetNmPHandState') And
        OrdIs(7, 'DosPeekNmPipe'));
  Check('ordinaux 8 a 14 (DosWaitNmPipe ... DosQNmPipeSemState)',
        OrdIs(8, 'DosWaitNmPipe') And OrdIs(9, 'DosTransactNmPipe') And OrdIs(10, 'DosCallNmPipe') And
        OrdIs(11, 'DosRawReadNmPipe') And OrdIs(12, 'DosRawWriteNmPipe') And OrdIs(13, 'DosSetNmPipeSem') And
        OrdIs(14, 'DosQNmPipeSemState'));

  { --- DosMakeNmPipe --- }
  R := DosMakeNmPipe(Z('\TUYAU\A'), LongInt(@Hs1), 2, $0502, 512, 512, 0);
  Check('DosMakeNmPipe nom sans \PIPE\ refuse', R = ERROR_PATH_NOT_FOUND);
  R := DosMakeNmPipe(Z('\PIPE\ESSAI'), LongInt(@Hs1), 2, $0500, 512, 512, 0);
  Check('DosMakeNmPipe 0 instance refuse', R = ERROR_INVALID_PARAMETER);
  R := DosMakeNmPipe(Z('\PIPE\ESSAI'), LongInt(@Hs1), 2, $0102, 512, 512, 0);
  Check('DosMakeNmPipe lecture par messages d''un tuyau d''octets refusee', R = ERROR_INVALID_PARAMETER);
  R := DosMakeNmPipe(Z('\PIPE\ESSAI'), LongInt(@Hs1), 2, $0502, 512, 512, 100);
  R2 := DosMakeNmPipe(Z('\pipe\essai'), LongInt(@Hs2), 2, $0502, 512, 512, 100);
  Check('DosMakeNmPipe deux instances (messages, bidirectionnel)', (R = 0) And (R2 = 0) And (Hs1 <> Hs2));
  R := DosMakeNmPipe(Z('\PIPE\ESSAI'), LongInt(@Hs3), 2, $0502, 512, 512, 0);
  Check('DosMakeNmPipe troisieme instance refusee', R = ERROR_PIPE_BUSY);

  { --- DosQNmPipeInfo, DosQNmPHandState --- }
  For I := 0 To 63 Do Buf[I] := 0;
  R := DosQNmPipeInfo(Hs1, 1, LongInt(@Buf), 64);
  PutZ(LongInt(@Txt), '\PIPE\ESSAI');
  N := 0;
  For I := 0 To 10 Do
    If Buf[7 + I] = Txt[I] Then Inc(N);
  Check('DosQNmPipeInfo : tampons 512 et 512, 2 instances (2 en cours), \PIPE\ESSAI', (R = 0) And
        (RdW(LongInt(@Buf)) = 512) And (RdW(LongInt(@Buf) + 2) = 512) And (Buf[4] = 2) And (Buf[5] = 2) And
        (Buf[6] = 11) And (N = 11) And (Buf[18] = 0));
  R := DosQNmPipeInfo(Hs1, 2, LongInt(@Buf), 64);
  R2 := DosQNmPipeInfo(Hs1, 1, LongInt(@Buf), 10);
  Check('DosQNmPipeInfo niveau 2 et tampon trop petit refuses', (R = ERROR_INVALID_LEVEL) And (R2 = ERROR_BUFFER_OVERFLOW));
  A := HState(Hs1);
  Check('DosQNmPHandState du serveur : ' + HStr(A), (R2 = 0) And (A = $4502));
  R := DosQNmPHandState(77, LongInt(@A));
  Check('DosQNmPHandState handle invalide refuse', R = ERROR_INVALID_HANDLE);

  { --- client --- }
  R := DosWaitNmPipe(Z('\PIPE\ESSAI'), 0);
  R2 := DosWaitNmPipe(Z('\PIPE\AUTRE'), 0);
  Check('DosWaitNmPipe : instance libre ; tuyau inexistant', (R = 0) And (R2 = ERROR_FILE_NOT_FOUND));
  R := DosOpen(Z('\PIPE\ESSAI'), LongInt(@Hc), LongInt(@Act), 0, 0, 1, $42, 0);
  Check('DosOpen \PIPE\ESSAI (client)', R = 0);
  A := HState(Hc);
  Check('etat du client : lecture par octets, bloquant (' + HStr(A) + ')', A = $0402);
  R := DosConnectNmPipe(Hs1);
  Check('DosConnectNmPipe : client connecte', R = 0);
  R := DosConnectNmPipe(Hc);
  Check('DosConnectNmPipe par le client refuse', R = ERROR_BAD_PIPE);

  { --- messages --- }
  R := Put(Hc, 'Bonjour');
  R2 := Put(Hc, 'Monde!!');
  Check('DosWrite de deux messages par le client', (R = 0) And (R2 = 0) And (N = 7));
  R := Peek(Hs1, 64);
  Check('DosPeekNmPipe : "' + BufStr(N) + '", 14 octets, message de 7, connecte', (R = 0) And (N = 7) And
        (BufStr(7) = 'Bonjour') And (RdW(LongInt(@Avail)) = 14) And (RdW(LongInt(@Avail) + 2) = 7) And (St = 3));
  R := Get(Hs1, 4);
  Check('DosRead par messages, tampon de 4 : "' + BufStr(N) + '" et ERROR_MORE_DATA', (R = ERROR_MORE_DATA) And
        (N = 4) And (BufStr(4) = 'Bonj'));
  R := Get(Hs1, 64);
  Check('DosRead : suite du message "' + BufStr(N) + '"', (R = 0) And (BufStr(N) = 'our'));
  R := Get(Hs1, 64);
  Check('DosRead : message suivant "' + BufStr(N) + '"', (R = 0) And (BufStr(N) = 'Monde!!'));
  R := Get(Hs1, 64);
  Check('DosRead d''un tuyau vide : ERROR_NO_DATA', R = ERROR_NO_DATA);
  R := Put(Hs1, 'AB');
  R2 := Put(Hs1, 'CD');
  R := Get(Hc, 64);
  Check('lecture par octets d''un tuyau de messages : "' + BufStr(N) + '"', (R = 0) And (BufStr(N) = 'ABCD'));

  { --- mode du handle --- }
  R := DosSetNmPHandState(Hc, NP_RMESG Or NP_NBLK);
  A := HState(Hc);
  Check('DosSetNmPHandState client : messages, non bloquant (' + HStr(A) + ')', (R = 0) And (A = $8502));
  R := DosSetNmPHandState(Hc, $0400);
  Check('DosSetNmPHandState bit invalide refuse', R = ERROR_INVALID_PARAMETER);

  { --- lecture et ecriture brutes --- }
  R := Put(Hs1, 'XYZ');
  N := 0;
  R := DosRawReadNmPipe(Hc, LongInt(@Buf), 64, LongInt(@N));
  Check('DosRawReadNmPipe : en-tete (3, 0) et "XYZ"', (R = 0) And (N = 5) And (Buf[0] = 3) And (Buf[1] = 0) And
        (Buf[2] = Ord('X')) And (Buf[4] = Ord('Z')));
  Txt[0] := 2; Txt[1] := 0; Txt[2] := Ord('O'); Txt[3] := Ord('K');
  R := DosRawWriteNmPipe(Hc, LongInt(@Txt), 4, LongInt(@N));
  R2 := Get(Hs1, 64);
  Check('DosRawWriteNmPipe d''un message complet : le serveur lit "' + BufStr(N) + '"', (R = 0) And (R2 = 0) And
        (BufStr(N) = 'OK'));
  Txt[0] := 9; Txt[1] := 0;
  R := DosRawWriteNmPipe(Hc, LongInt(@Txt), 4, LongInt(@N));
  Check('DosRawWriteNmPipe en-tete incoherent refuse', R = ERROR_INVALID_PARAMETER);

  { --- transactions --- }
  R := Put(Hs1, 'R1');
  N := 0;
  R := DosTransactNmPipe(Hc, LongInt(@Txt), 3, LongInt(@Buf), 64, LongInt(@N));
  Check('DosTransactNmPipe avec des donnees non lues : ERROR_PIPE_BUSY', R = ERROR_PIPE_BUSY);
  R := Get(Hc, 64);
  PutZ(LongInt(@Txt), 'REQ');
  R := DosTransactNmPipe(Hc, LongInt(@Txt), 3, LongInt(@Buf), 64, LongInt(@N));
  R2 := Get(Hs1, 64);
  Check('DosTransactNmPipe : demande "' + BufStr(N) + '" remise au serveur, pas de reponse (ERROR_NO_DATA)',
        (R = ERROR_NO_DATA) And (R2 = 0) And (BufStr(N) = 'REQ'));

  { --- tuyau d'octets entrant --- }
  R := DosMakeNmPipe(Z('\PIPE\OCTETS'), LongInt(@Hb), 0, $0001, 64, 64, 0);
  R2 := DosOpen(Z('\PIPE\OCTETS'), LongInt(@Hbc), LongInt(@Act), 0, 0, 1, $42, 0);
  Check('tuyau d''octets entrant', (R = 0) And (R2 = 0));
  R := Get(Hbc, 10);
  R2 := Put(Hb, 'x');
  Check('acces entrant : le client ne lit pas, le serveur n''ecrit pas', (R = ERROR_ACCESS_DENIED) And
        (R2 = ERROR_ACCESS_DENIED));
  R := Put(Hbc, '0123456789012345678901234567890123456789012345678901234567890123456789');
  Check('tuyau d''octets plein : ecriture partielle (' + IStr(N) + ' octets)', (R = 0) And (N = 64));
  R := DosTransactNmPipe(Hbc, LongInt(@Txt), 3, LongInt(@Buf), 64, LongInt(@N));
  Check('DosTransactNmPipe sur un tuyau d''octets : ERROR_BAD_FORMAT', R = ERROR_BAD_FORMAT);
  R := DosSetNmPHandState(Hbc, NP_RMESG);
  Check('lecture par messages d''un tuyau d''octets refusee', R = ERROR_INVALID_PARAMETER);
  DosClose(Hbc);
  DosClose(Hb);

  { --- semaphores --- }
  R := DosCreateSem(1, LongInt(@Sem), Z('\SEM\NMP'));
  R2 := DosSemSet(Sem);
  R := DosSetNmPipeSem(Hs1, Sem, 7);
  Check('DosSetNmPipeSem : semaphore systeme sur le serveur (cle 7)', R = 0);
  R := Put(Hc, 'S');
  R2 := DosSemWait(Sem, 0);
  Check('le client ecrit : semaphore liberee', (R = 0) And (R2 = 0));
  For I := 0 To 31 Do Buf[I] := 0;
  R := DosQNmPipeSemState(Sem, LongInt(@Buf), 64);
  Check('DosQNmPipeSemState : NPSS_RDATA (cle 7, 1 octet), NPSS_WSPACE, NPSS_EOI', (R = 0) And
        (Buf[0] = 1) And (RdW(LongInt(@Buf) + 2) = 7) And (RdW(LongInt(@Buf) + 4) = 1) And (Buf[6] = 2) And
        (Buf[12] = 0));
  R := DosQNmPipeSemState(Sem, LongInt(@Buf), 8);
  Check('DosQNmPipeSemState tampon trop petit', R = ERROR_BUFFER_OVERFLOW);
  R := DosCreateEventSem(0, LongInt(@Ev), 0, 0);
  R2 := DosSetNmPipeSem(Hc, Ev, 9);
  R := Put(Hs1, 'E');
  A := 0;
  R := DosQueryEventSem(Ev, LongInt(@A));
  Check('semaphore d''evenement sur le client : affichee par l''ecriture du serveur', (R2 = 0) And (A >= 1));
  R := DosSetNmPipeSem(Hc, 12345, 1);
  Check('DosSetNmPipeSem semaphore invalide refusee', R = ERROR_INVALID_HANDLE);

  { --- fermeture du client --- }
  R := Get(Hc, 64);
  R := Get(Hs1, 64);
  R := Put(Hc, 'FIN');
  R := DosClose(Hc);
  R2 := Peek(Hs1, 64);
  Check('client ferme : etat NP_CLOSING, "' + BufStr(N) + '" encore lisible', (R = 0) And (St = 4) And
        (BufStr(N) = 'FIN'));
  R := Get(Hs1, 64);
  R2 := Get(Hs1, 64);
  Check('lecture puis fin de fichier (0 octet)', (R = 0) And (R2 = 0) And (N = 0));
  R := Put(Hs1, 'x');
  R2 := DosConnectNmPipe(Hs1);
  Check('ecriture et DosConnectNmPipe apres fermeture : ERROR_BROKEN_PIPE', (R = ERROR_BROKEN_PIPE) And
        (R2 = ERROR_BROKEN_PIPE));
  R := DosDisConnectNmPipe(Hs1);
  R2 := Peek(Hs1, 64);
  Check('DosDisConnectNmPipe : NP_DISCONNECTED', (R = 0) And (St = 1));
  R := DosConnectNmPipe(Hs1);
  R2 := Peek(Hs1, 64);
  Check('DosConnectNmPipe sans client : ERROR_PIPE_NOT_CONNECTED, a l''ecoute', (R = ERROR_PIPE_NOT_CONNECTED) And
        (St = 2));

  { --- deconnexion d'un client --- }
  R := DosOpen(Z('\PIPE\ESSAI'), LongInt(@Hc2), LongInt(@Act), 0, 0, 1, $42, 0);
  R2 := DosConnectNmPipe(Hs1);
  If R2 <> 0 Then R2 := DosConnectNmPipe(Hs2);
  Check('nouveau client connecte', (R = 0) And (R2 = 0));
  R := DosDisConnectNmPipe(Hs1);
  R2 := DosDisConnectNmPipe(Hs2);
  R := Put(Hc2, 'x');
  R2 := Peek(Hc2, 64);
  Check('client deconnecte par le serveur : ERROR_PIPE_NOT_CONNECTED, NP_DISCONNECTED', (R = ERROR_PIPE_NOT_CONNECTED) And
        (St = 1));
  Check('DosClose du client deconnecte', DosClose(Hc2) = 0);

  { --- DosCallNmPipe --- }
  R := DosConnectNmPipe(Hs1);
  PutZ(LongInt(@Txt), 'APPEL');
  N := 0;
  R := DosCallNmPipe(Z('\PIPE\ESSAI'), LongInt(@Txt), 5, LongInt(@Buf), 64, LongInt(@N), 100);
  R2 := Get(Hs1, 64);
  Check('DosCallNmPipe : "' + BufStr(N) + '" recu par le serveur, pas de reponse (ERROR_NO_DATA)',
        (R = ERROR_NO_DATA) And (R2 = 0) And (BufStr(N) = 'APPEL'));
  R := Peek(Hs1, 64);
  Check('DosCallNmPipe : client referme (NP_CLOSING)', (R = 0) And (St = 4));
  R := DosDisConnectNmPipe(Hs1);
  R := DosConnectNmPipe(Hs2);
  R := DosOpen(Z('\PIPE\ESSAI'), LongInt(@Hc), LongInt(@Act), 0, 0, 1, $42, 0);
  R := DosCallNmPipe(Z('\PIPE\ESSAI'), LongInt(@Txt), 5, LongInt(@Buf), 64, LongInt(@N), 100);
  Check('DosCallNmPipe sans instance libre : ERROR_SEM_TIMEOUT', R = ERROR_SEM_TIMEOUT);
  R := DosWaitNmPipe(Z('\PIPE\ESSAI'), 100);
  Check('DosWaitNmPipe sans instance libre : ERROR_SEM_TIMEOUT', R = ERROR_SEM_TIMEOUT);
  DosClose(Hc);

  { --- DOSCALLS.DLL (OS/2 2.x) --- }
  R := DcCreateNPipe(Z('\PIPE\DC'), LongInt(@Hb), 2, $0001, 0, 0, 0);
  A := 0;
  R2 := DcQueryNPHState(Hb, LongInt(@A));
  Check('DosCreateNPipe et DosQueryNPHState de DOSCALLS.DLL (' + HStr(A) + ')', (R = 0) And (R2 = 0) And (A = $4001));
  DosClose(Hb);

  { --- fermeture des serveurs --- }
  R := DosClose(Hs1);
  R2 := DosClose(Hs2);
  Check('DosClose des serveurs', (R = 0) And (R2 = 0));
  R := DosWaitNmPipe(Z('\PIPE\ESSAI'), 0);
  Check('tuyau supprime : DosWaitNmPipe ERROR_FILE_NOT_FOUND', R = ERROR_FILE_NOT_FOUND);
  R := DosQNmPHandState(Hs1, LongInt(@A));
  Check('handle ferme refuse', R = ERROR_INVALID_HANDLE);
  DosCloseSem(Sem);
  DosCloseEventSem(Ev);

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTNMP : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
