{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de RMINFO.DLL sous OS/2-0.
}

Program TESTRM;

{$R-,S-,I-}

{ Compilation : OS2PC TESTRM.PAS   (produit TESTRM.EXE)

  TESTRM       verifie les 34 points d'entree de RMINFO.DLL : arbre du
               materiel du noyau, identificateurs PnP, pilotes,
               ressources (exclusives, partagees, multiplexees),
               adaptateurs, peripheriques detectes, recherche, niveau de
               detection, sauvegarde.
  TESTRM LISTE affiche aussi l'arbre (pilotes, adaptateurs, ressources). }

Function RMConvertID(PId, PSz, Flags : LongInt) : LongInt; External 'RMINFO';
Function RMEnumNodes(T, PList : LongInt) : LongInt; External 'RMINFO';
Function _RMEnumNodes(T, PList : LongInt) : LongInt; External 'RMINFO';
Function _RMConvertID(PId, PSz, Flags : LongInt) : LongInt; External 'RMINFO';
Function RMGetNodeInfo(H, PBuf, Cb : LongInt) : LongInt; External 'RMINFO';
Function RMCreateDriver(PDs, PH : LongInt) : LongInt; External 'RMINFO';
Function _RMGetNodeInfo(H, PBuf, Cb : LongInt) : LongInt; External 'RMINFO';
Function RMAllocResource(HDrv, PH, PRs : LongInt) : LongInt; External 'RMINFO';
Function RMCreateAdapter(HDrv, PH, PAs, HDev, PAh : LongInt) : LongInt; External 'RMINFO';
Function _RMCreateAdapter(HDrv, PH, PAs, HDev, PAh : LongInt) : LongInt; External 'RMINFO';
Function _RMCreateDriver(PDs, PH : LongInt) : LongInt; External 'RMINFO';
Function RMCreateDetected(HDrv, PH, PDs, PAh : LongInt) : LongInt; External 'RMINFO';
Function RMGetSnoopLevel(PLevel : LongInt) : LongInt; External 'RMINFO';
Function RMDestroyAdapter(HDrv, HAd : LongInt) : LongInt; External 'RMINFO';
Function RMDestroyDriver(HDrv : LongInt) : LongInt; External 'RMINFO';
Function RMSetSnoopLevel(Level, Flags : LongInt) : LongInt; External 'RMINFO';
Function _RMCreateDetected(HDrv, PH, PDs, PAh : LongInt) : LongInt; External 'RMINFO';
Function _RMAllocResource(HDrv, PH, PRs : LongInt) : LongInt; External 'RMINFO';
Function _RMDestroyDriver(HDrv : LongInt) : LongInt; External 'RMINFO';
Function _RMGetSnoopLevel(PLevel : LongInt) : LongInt; External 'RMINFO';
Function RMDeallocResource(HDrv, HRes : LongInt) : LongInt; External 'RMINFO';
Function _RMSetSnoopLevel(Level, Flags : LongInt) : LongInt; External 'RMINFO';
Function RMDestroyDetected(HDrv, HDet : LongInt) : LongInt; External 'RMINFO';
Function _RMDestroyAdapter(HDrv, HAd : LongInt) : LongInt; External 'RMINFO';
Function RMSaveDetectedData : LongInt; External 'RMINFO';
Function _RMDestroyDetected(HDrv, HDet : LongInt) : LongInt; External 'RMINFO';
Function _RMDeallocResource(HDrv, HRes : LongInt) : LongInt; External 'RMINFO';
Function RMHandleToResourceHandleList(H, PList : LongInt) : LongInt; External 'RMINFO';
Function _RMHandleToResourceHandleList(H, PList : LongInt) : LongInt; External 'RMINFO';
Function RMDevIDToHandleList(IdType, DevId, FnId, CompId, VendId, Serial, Flags, HStart, PList : LongInt) : LongInt; External 'RMINFO';
Function _RMSaveDetectedData : LongInt; External 'RMINFO';
Function RMDeleteDetectedData : LongInt; External 'RMINFO';
Function _RMDeleteDetectedData : LongInt; External 'RMINFO';
Function _RMDevIDToHandleList(IdType, DevId, FnId, CompId, VendId, Serial, Flags, HStart, PList : LongInt) : LongInt; External 'RMINFO';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';

Const
  RMRC_BAD_DRIVERHANDLE = 2;
  RMRC_BAD_DEVICEHANDLE = 4;
  RMRC_BAD_RESOURCEHANDLE = 5;
  RMRC_NULL_POINTER = 9;
  RMRC_NULL_STRINGS = 10;
  RMRC_RES_ALREADY_CLAIMED = 12;
  RMRC_INVALID_PARM_VALUE = 14;
  RMRC_SEARCH_FAILED = 16;
  RMRC_BUFFER_TOO_SMALL = 17;
  RMRC_BAD_DETECTHANDLE = 22;
  RMRC_BAD_RMHANDLE = 23;
  RMRC_BAD_FLAGS = 24;
  RMRC_NO_DETECTED_DATA = 25;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, C, K, Id, HKrn, HKbd, HDrv, HDrv2, HIo, HMem, HIrq, HIrq2, HAd, HAd2, HDet : LongInt;
  Name, Txt, Txt2, Txt3 : Array[0..127] Of Byte;
  Ds : Array[0..63] Of Byte;        { DRIVERSTRUCT, ADAPTERSTRUCT, DETECTEDSTRUCT }
  Rs : Array[0..31] Of Byte;        { RESOURCESTRUCT }
  Ah : Array[0..7] Of LongInt;      { AHRESOURCE }
  Lst : Array[0..63] Of LongInt;    { HANDLELIST }
  Nd : Array[0..511] Of Byte;       { RM_GETNODE_DATA }
  Info : Array[0..63] Of Byte;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var T : String;
Begin
  Str(V, T);
  IStr := T;
End;

Function HStr(V : LongInt) : String;
Var T : String; K, D : LongInt;
Begin
  T := '';
  For K := 7 DownTo 0 Do
  Begin
    D := (V Shr (K * 4)) And 15;
    If D < 10 Then T := T + Chr(48 + D) Else T := T + Chr(55 + D);
  End;
  HStr := T;
End;

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
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

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
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

Function GetZ(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  N := 0;
  While (A <> 0) And (RdB(A + N) <> 0) And (N < 80) Do
  Begin
    S := S + Chr(RdB(A + N));
    Inc(N);
  End;
  GetZ := S;
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

Procedure ClearDs;
Var K : LongInt;
Begin
  For K := 0 To 63 Do Ds[K] := 0;
End;

{ Ressource : type, a, b, indicateurs }
Function Alloc(Drv, Typ, A, B, F : LongInt; Var Hr : LongInt) : LongInt;
Var K : LongInt;
Begin
  For K := 0 To 31 Do Rs[K] := 0;
  WrL(LongInt(@Rs), Typ);
  Case Typ Of
    1 : Begin WrW(LongInt(@Rs) + 4, A); WrW(LongInt(@Rs) + 6, B); WrW(LongInt(@Rs) + 8, F); End;
    2 : Begin WrW(LongInt(@Rs) + 4, A); WrW(LongInt(@Rs) + 8, F); End;
    3 : Begin WrL(LongInt(@Rs) + 4, A); WrL(LongInt(@Rs) + 8, B); WrW(LongInt(@Rs) + 12, F); End;
  Else
    Begin WrW(LongInt(@Rs) + 4, A); WrW(LongInt(@Rs) + 6, F); End;
  End;
  Hr := 0;
  Alloc := RMAllocResource(Drv, LongInt(@Hr), LongInt(@Rs));
End;

Function Info0(Hn : LongInt) : LongInt;
Begin
  Info0 := RMGetNodeInfo(Hn, LongInt(@Nd), 512);
End;

Function NdL(Ofs : LongInt) : LongInt;
Begin
  NdL := RdL(LongInt(@Nd) + Ofs);
End;

Function NdW(Ofs : LongInt) : LongInt;
Begin
  NdW := RdW(LongInt(@Nd) + Ofs);
End;

Procedure ListInit(Max : LongInt);
Begin
  Lst[0] := -1;
  Lst[1] := Max;
End;

{ La liste de ressources du noeud contient-elle Typ/A ? }
Function HasRes(Hn, Typ, A : LongInt) : Boolean;
Var K, Rc : LongInt; F : Boolean;
Begin
  F := False;
  ListInit(60);
  Rc := RMHandleToResourceHandleList(Hn, LongInt(@Lst));
  For K := 0 To Lst[0] - 1 Do
    If Info0(Lst[2 + K]) = 0 Then
      If (NdL(20) = Typ) And (NdW(24) = A) Then F := True;
  HasRes := F;
End;

Procedure ShowTree;
Var K, J, M : LongInt; T : String;
Begin
  ListInit(60);
  R := RMEnumNodes($FFFF, LongInt(@Lst));
  M := Lst[0];
  For K := 0 To M - 1 Do
    If Info0(Lst[2 + K]) = 0 Then
    Begin
      Case NdL(4) Of
        0 : T := 'adaptateur ' + GetZ(NdL(20));
        4 : T := 'pilote ' + GetZ(NdL(20));
        5 : T := 'detecte ' + GetZ(NdL(20)) + ' ' + HStr(NdL(28));
      Else
        T := 'ressource ' + IStr(NdL(20)) + ' ' + HStr(NdW(24)) + ' ' + IStr(NdW(26));
      End;
      WriteLn('  ', HStr(Lst[2 + K]), ' ', T);
    End;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTRM : essai de RMINFO.DLL');

  { --- module et ordinaux --- }
  R := DosQueryModuleHandle(Z('RMINFO'), LongInt(@H));
  Check('DosQueryModuleHandle RMINFO', R = 0);
  Check('ordinaux 1 a 12', OrdIs(1, 'RMConvertID') And OrdIs(2, 'RMEnumNodes') And OrdIs(3, '_RMEnumNodes') And
        OrdIs(4, '_RMConvertID') And OrdIs(5, 'RMGetNodeInfo') And OrdIs(6, 'RMCreateDriver') And
        OrdIs(7, '_RMGetNodeInfo') And OrdIs(8, 'RMAllocResource') And OrdIs(9, 'RMCreateAdapter') And
        OrdIs(10, '_RMCreateAdapter') And OrdIs(11, '_RMCreateDriver') And OrdIs(12, 'RMCreateDetected'));
  Check('ordinaux 13 a 24', OrdIs(13, 'RMGetSnoopLevel') And OrdIs(14, 'RMDestroyAdapter') And
        OrdIs(15, 'RMDestroyDriver') And OrdIs(16, 'RMSetSnoopLevel') And OrdIs(17, '_RMCreateDetected') And
        OrdIs(18, '_RMAllocResource') And OrdIs(19, '_RMDestroyDriver') And OrdIs(20, '_RMGetSnoopLevel') And
        OrdIs(21, 'RMDeallocResource') And OrdIs(22, '_RMSetSnoopLevel') And OrdIs(23, 'RMDestroyDetected') And
        OrdIs(24, '_RMDestroyAdapter'));
  Check('ordinaux 25 a 34', OrdIs(25, 'RMSaveDetectedData') And OrdIs(26, '_RMDestroyDetected') And
        OrdIs(27, '_RMDeallocResource') And OrdIs(28, 'RMHandleToResourceHandleList') And
        OrdIs(29, '_RMHandleToResourceHandleList') And OrdIs(30, 'RMDevIDToHandleList') And
        OrdIs(31, '_RMSaveDetectedData') And OrdIs(32, 'RMDeleteDetectedData') And
        OrdIs(33, '_RMDeleteDetectedData') And OrdIs(34, '_RMDevIDToHandleList'));

  { --- identificateurs EISA/PnP --- }
  Id := $0303D041;
  R := RMConvertID(LongInt(@Id), LongInt(@Txt), 0);
  Check('RMConvertID 0303D041h -> ' + GetZ(LongInt(@Txt)), (R = 0) And (GetZ(LongInt(@Txt)) = 'PNP0303'));
  PutZ(LongInt(@Txt), 'PNP0F13');
  Id := 0;
  R := _RMConvertID(LongInt(@Id), LongInt(@Txt), 1);
  Check('_RMConvertID PNP0F13 -> ' + HStr(Id), (R = 0) And (Id = $130FD041));
  PutZ(LongInt(@Txt), 'PN03');
  R := RMConvertID(LongInt(@Id), LongInt(@Txt), 1);
  R2 := RMConvertID(LongInt(@Id), LongInt(@Txt), 5);
  Check('RMConvertID chaine invalide ; indicateur invalide', (R = RMRC_INVALID_PARM_VALUE) And (R2 = RMRC_BAD_FLAGS));

  { --- materiel du noyau --- }
  ListInit(60);
  R := RMEnumNodes(4, LongInt(@Lst));
  HKrn := Lst[2];
  R2 := Info0(HKrn);
  Check('RMEnumNodes des pilotes : OS2KRNL (' + GetZ(NdL(20)) + ', ' + GetZ(NdL(24)) + ')', (R = 0) And (Lst[0] = 1) And
        (R2 = 0) And (NdL(4) = 4) And (GetZ(NdL(20)) = 'OS2KRNL'));
  ListInit(2);
  R := _RMEnumNodes($FFFF, LongInt(@Lst));
  Check('RMEnumNodes de tous les noeuds, liste de 2 : RMRC_BUFFER_TOO_SMALL', (R = RMRC_BUFFER_TOO_SMALL) And (Lst[0] = 2));
  ListInit(8);
  R := RMDevIDToHandleList(1, $0303D041, 0, 0, 0, 0, 1, 0, LongInt(@Lst));
  HKbd := Lst[2];
  R2 := Info0(HKbd);
  Check('RMDevIDToHandleList PNP0303 : ' + GetZ(NdL(20)), (R = 0) And (Lst[0] = 1) And (R2 = 0) And (NdL(4) = 5) And
        (NdL(28) = $0303D041) And (NdL(12) = HKrn));
  ListInit(8);
  R := _RMDevIDToHandleList(1, $12345678, 0, 0, 0, 0, 1, 0, LongInt(@Lst));
  R2 := RMDevIDToHandleList(1, 0, 0, 0, 0, 0, $40, 0, LongInt(@Lst));
  Check('RMDevIDToHandleList identificateur inconnu ; indicateurs invalides', (R = RMRC_SEARCH_FAILED) And
        (R2 = RMRC_BAD_FLAGS));
  Check('ressources du noyau : IRQ 1, ports 60h et 1F0h, memoire A0000h', HasRes(HKrn, 2, 1) And HasRes(HKrn, 1, $60) And
        HasRes(HKrn, 1, $1F0) And HasRes(HKrn, 3, 0));
  R := RMGetNodeInfo($7777, LongInt(@Nd), 512);
  R2 := RMGetNodeInfo(HKrn, LongInt(@Nd), 10);
  Check('RMGetNodeInfo handle invalide ; tampon trop petit (taille ' + IStr(NdL(0)) + ')', (R = RMRC_BAD_RMHANDLE) And
        (R2 = RMRC_BUFFER_TOO_SMALL) And (NdL(0) > 48));

  { --- pilote --- }
  ClearDs;
  R := RMCreateDriver(0, LongInt(@HDrv));
  R2 := RMCreateDriver(LongInt(@Ds), LongInt(@HDrv));
  Check('RMCreateDriver pointeur nul ; nom nul', (R = RMRC_NULL_POINTER) And (R2 = RMRC_NULL_STRINGS));
  PutZ(LongInt(@Txt), 'TESTRM.SYS');
  PutZ(LongInt(@Txt2), 'Pilote d''essai');
  PutZ(LongInt(@Txt3), 'Gladir');
  WrL(LongInt(@Ds), LongInt(@Txt)); WrL(LongInt(@Ds) + 4, LongInt(@Txt2)); WrL(LongInt(@Ds) + 8, LongInt(@Txt3));
  Ds[12] := 1; Ds[13] := 2; WrW(LongInt(@Ds) + 14, 2026); Ds[16] := 11; Ds[17] := 11;
  WrW(LongInt(@Ds) + 20, 3);
  R := RMCreateDriver(LongInt(@Ds), LongInt(@HDrv));
  PutZ(LongInt(@Txt), 'AUTRE.SYS');
  R2 := _RMCreateDriver(LongInt(@Ds), LongInt(@HDrv2));
  A := Info0(HDrv);
  Check('RMCreateDriver TESTRM.SYS ; _RMCreateDriver AUTRE.SYS', (R = 0) And (R2 = 0) And (A = 0) And
        (GetZ(NdL(20)) = 'TESTRM.SYS') And (GetZ(NdL(28)) = 'Gladir') And (Nd[32] = 1) And (Nd[33] = 2) And
        (NdW(34) = 2026) And (NdW(40) = 3));

  { --- ressources --- }
  R := Alloc(HDrv, 1, $60, 1, 1, A);
  R2 := Alloc(HDrv, 2, 1, 0, 0, A);
  Check('ports 60h et IRQ 1 deja pris par le noyau', (R = RMRC_RES_ALREADY_CLAIMED) And (R2 = RMRC_RES_ALREADY_CLAIMED));
  R := Alloc(HDrv, 1, $300, 8, 1, HIo);
  R2 := Alloc(HDrv2, 1, $304, 2, 1, A);
  Check('ports 300h-307h ; recouvrement 304h refuse', (R = 0) And (R2 = RMRC_RES_ALREADY_CLAIMED));
  R := Alloc(HDrv, 2, 5, 0, 4, HIrq);
  R2 := Alloc(HDrv2, 2, 5, 0, 4, HIrq2);
  A := Alloc(HDrv2, 2, 5, 0, 2, B);
  Check('IRQ 5 partagee par deux pilotes ; multiplexee refusee', (R = 0) And (R2 = 0) And
        (A = RMRC_RES_ALREADY_CLAIMED));
  R := Alloc(HDrv, 3, $D0000, $1000, 1, HMem);
  R2 := Alloc(HDrv, 4, 9, 0, 1, A);
  B := Alloc(HDrv, 9, 0, 0, 1, A);
  C := Alloc(HDrv, 1, $310, 2, 3, A);
  Check('memoire D0000h ; DMA 9, type 9 et indicateurs 3 refuses', (R = 0) And (R2 = RMRC_INVALID_PARM_VALUE) And
        (B = RMRC_INVALID_PARM_VALUE) And (C = RMRC_BAD_FLAGS));
  R := RMDeallocResource(HDrv2, HIrq2);
  R2 := _RMDeallocResource(HDrv, HIrq2);
  Check('RMDeallocResource ; ressource liberee refusee', (R = 0) And (R2 = RMRC_BAD_RESOURCEHANDLE));
  ListInit(8);
  R := RMHandleToResourceHandleList(HKrn, LongInt(@Lst));
  A := Lst[2];
  R := RMDeallocResource(HDrv, A);
  Check('RMDeallocResource d''une ressource du noyau refuse', R = RMRC_BAD_RESOURCEHANDLE);

  { --- adaptateurs --- }
  ClearDs;
  PutZ(LongInt(@Txt), 'Carte d''essai');
  WrL(LongInt(@Ds), LongInt(@Txt));
  WrW(LongInt(@Ds) + 6, 4); WrW(LongInt(@Ds) + 12, 1); WrW(LongInt(@Ds) + 14, 16);
  Ah[0] := 2; Ah[1] := HIo; Ah[2] := HMem;
  R := RMCreateAdapter(HDrv, LongInt(@HAd), LongInt(@Ds), 0, LongInt(@Ah));
  A := Info0(HAd);
  Check('RMCreateAdapter avec 2 ressources', (R = 0) And (A = 0) And (NdL(4) = 0) And (NdL(8) = 0) And
        (NdL(12) = HDrv) And (NdL(16) = 2) And (GetZ(NdL(20)) = 'Carte d''essai') And (NdW(26) = 4));
  Check('RMHandleToResourceHandleList de l''adaptateur : ports 300h, memoire', HasRes(HAd, 1, $300) And
        HasRes(HAd, 3, 0) And Not HasRes(HAd, 2, 5));
  R := RMCreateAdapter(HDrv, LongInt(@B), LongInt(@Ds), 0, LongInt(@Ah));
  Ah[0] := 1; Ah[1] := HIrq;
  R2 := RMCreateAdapter(HDrv2, LongInt(@B), LongInt(@Ds), 0, LongInt(@Ah));
  A := RMCreateAdapter(HDrv, LongInt(@B), LongInt(@Ds), $7777, 0);
  Check('ressource deja rattachee ; d''un autre pilote ; parent invalide', (R = RMRC_RES_ALREADY_CLAIMED) And
        (R2 = RMRC_BAD_RESOURCEHANDLE) And (A = RMRC_BAD_DEVICEHANDLE));
  PutZ(LongInt(@Txt), 'Sous-adaptateur');
  R := _RMCreateAdapter(HDrv, LongInt(@HAd2), LongInt(@Ds), HAd, 0);
  A := Info0(HAd2);
  Check('_RMCreateAdapter sous l''adaptateur', (R = 0) And (A = 0) And (NdL(8) = HAd));

  { --- peripherique detecte --- }
  ClearDs;
  PutZ(LongInt(@Txt), 'GLD0001');
  Id := 0;
  R := RMConvertID(LongInt(@Id), LongInt(@Txt), 1);
  PutZ(LongInt(@Txt), 'Peripherique d''essai');
  WrL(LongInt(@Ds), LongInt(@Txt));
  WrW(LongInt(@Ds) + 6, 1);
  WrL(LongInt(@Ds) + 8, Id); WrL(LongInt(@Ds) + 12, -1); WrL(LongInt(@Ds) + 16, Id);
  WrL(LongInt(@Ds) + 20, -1); WrL(LongInt(@Ds) + 24, 1234);
  Ah[0] := 1; Ah[1] := HIrq;
  R := RMCreateDetected(HDrv, LongInt(@HDet), LongInt(@Ds), LongInt(@Ah));
  ListInit(8);
  R2 := RMDevIDToHandleList(1, Id, 0, 0, 0, 1234, 1 + 16, 0, LongInt(@Lst));
  Check('RMCreateDetected GLD0001 ; RMDevIDToHandleList (DeviceID, SerialNumber)', (R = 0) And (R2 = 0) And
        (Lst[0] = 1) And (Lst[2] = HDet) And HasRes(HDet, 2, 5));
  ListInit(8);
  R := RMDevIDToHandleList(1, Id, 0, 0, 0, 0, 1, HDet, LongInt(@Lst));
  Check('RMDevIDToHandleList apres hStartNode : rien', R = RMRC_SEARCH_FAILED);
  R := RMDestroyDetected(HDrv2, HDet);
  Check('RMDestroyDetected par un autre pilote refuse', R = RMRC_BAD_DETECTHANDLE);

  { --- niveau de detection, sauvegarde --- }
  A := -1;
  R := RMGetSnoopLevel(LongInt(@A));
  R2 := RMSetSnoopLevel(3, 0);
  B := -1;
  C := _RMGetSnoopLevel(LongInt(@B));
  Check('RMGetSnoopLevel 1 ; RMSetSnoopLevel 3', (R = 0) And (A = 1) And (R2 = 0) And (C = 0) And (B = 3));
  R := RMSetSnoopLevel(4, 0);
  R2 := _RMSetSnoopLevel(2, 1);
  A := RMSetSnoopLevel(1, 0);
  Check('RMSetSnoopLevel niveau ou indicateurs invalides', (R = RMRC_INVALID_PARM_VALUE) And (R2 = RMRC_BAD_FLAGS));
  R := RMSaveDetectedData;
  R2 := DosQueryPathInfo(Z('C:\RMDETECT.DAT'), 1, LongInt(@Info), 24);
  Check('RMSaveDetectedData : C:\RMDETECT.DAT', (R = 0) And (R2 = 0));
  R := _RMDeleteDetectedData;
  R2 := RMDeleteDetectedData;
  Check('RMDeleteDetectedData, puis rien a supprimer', (R = 0) And (R2 = RMRC_NO_DETECTED_DATA));

  If (ParamCount > 0) And ((ParamStr(1) = 'LISTE') Or (ParamStr(1) = 'liste')) Then ShowTree;

  { --- destruction --- }
  R := _RMDestroyDetected(HDrv, HDet);
  R2 := Info0(HDet);
  Check('_RMDestroyDetected', (R = 0) And (R2 = RMRC_BAD_RMHANDLE));
  R := RMDestroyAdapter(HDrv2, HAd);
  R2 := _RMDestroyAdapter(HDrv, HAd);
  A := Info0(HAd2);
  B := Alloc(HDrv2, 1, $300, 8, 1, C);
  Check('RMDestroyAdapter : sous-adaptateur et ressources liberes', (R = 3) And (R2 = 0) And
        (A = RMRC_BAD_RMHANDLE) And (B = 0));
  R := RMDestroyDriver(HDrv);
  R2 := Alloc(HDrv2, 2, 5, 0, 1, A);
  Check('RMDestroyDriver : ressources du pilote liberees (IRQ 5 exclusive)', (R = 0) And (R2 = 0));
  R := _RMDestroyDriver(HDrv2);
  R2 := RMDestroyDriver(HKrn);
  A := RMDestroyDriver(HDrv);
  Check('_RMDestroyDriver ; pilote du noyau et pilote detruit refuses', (R = 0) And (R2 = RMRC_BAD_DRIVERHANDLE) And
        (A = RMRC_BAD_DRIVERHANDLE));
  B := Alloc(HDrv, 1, $300, 8, 1, C);
  Check('RMAllocResource par un pilote detruit refuse', B = RMRC_BAD_DRIVERHANDLE);

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTRM : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
