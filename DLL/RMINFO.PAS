{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 RMINFO.DLL de OS/2-0 (gestionnaire de
                ressources materielles, Resource Manager).
}

Library RMINFO;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC RMINFO.PAS   (produit RMINFO.DLL)

  RMINFO.DLL tient l'arbre du gestionnaire de ressources d'OS/2 : pilotes
  (RMCreateDriver), adaptateurs (RMCreateAdapter), peripheriques detectes
  (RMCreateDetected) et ressources materielles (RMAllocResource : ports
  d'entree/sortie, interruptions, memoire, DMA, minuteries). Une
  ressource exclusive ne peut etre allouee deux fois ; une ressource
  partagee (ou multiplexee) peut l'etre par plusieurs pilotes qui la
  demandent tous partagee (ou multiplexee).

  Au chargement, l'arbre decrit le materiel gere par le noyau OS2KRNL
  (pilote OS2KRNL) : controleur d'interruptions, minuterie, horloge,
  controleur du clavier et de la souris, IDE, VGA et les ports COM et LPT
  presents (zone de donnees du BIOS), chacun avec ses ressources et son
  peripherique detecte (identificateur EISA/PnP : PNP0000, PNP0100,
  PNP0B00, PNP0303, PNP0F13, PNP0600, PNP0900, PNP0500, PNP0400).
  RMSaveDetectedData ecrit les peripheriques detectes crees par les
  applications dans C:\RMDETECT.DAT, relu au chargement suivant (meme
  demarrage) ; RMDeleteDetectedData le supprime.

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires. Les fonctions _RMxxx sont les memes que RMxxx (seconds
  points d'entree). Structures (disposition du DDK d'OS/2) :
    DRIVERSTRUCT    DrvrName, DrvrDescript, VendorName (PSZ), MajorVer,
                    MinorVer (octets), Date (Year : mot, Month, Day :
                    octets), DrvrFlags, DrvrType, DrvrSubType (mots),
                    DrvrCallback                                 28 octets
    ADAPTERSTRUCT   AdaptDescriptName (PSZ), AdaptFlags, BaseType,
                    SubType, InterfaceType, HostBusType, HostBusWidth
                    (mots), pAdjunctList, Reserved               24 octets
    DETECTEDSTRUCT  DetectDescriptName (PSZ), DetectFlags, IDType
                    (mots), DeviceID, FunctionID, CompatibleID,
                    VendorID, SerialNumber, pAdjunctList, Reserved 36 octets
    RESOURCESTRUCT  ResourceType (1 E/S, 2 IRQ, 3 memoire, 4 DMA,
                    5 minuterie), union de 12 octets (E/S : BaseIOPort,
                    NumIOPorts, IOFlags, IOAddressLines ; IRQ : IRQLevel,
                    PCIIrqPin, IRQFlags, Reserved, pfnIntHandler ;
                    memoire : MemBase, MemSize, MemFlags, Reserved ;
                    DMA et minuterie : Channel, Flags), Reserved 20 octets
    Indicateurs de partage : 1 exclusif (ou 0), 2 multiplexe, 4 partage
    (memoire : 8 ROM).
    AHRESOURCE      NumResource, hResource[] (doubles mots)
    HANDLELIST      cHandles, cMaxHandles, Handles[] (doubles mots)
    RM_GETNODE_DATA (RMGetNodeInfo, disposition d'OS/2-0) : RMNodeSize,
                    NodeType (0 adaptateur, 4 pilote, 5 detecte,
                    6 ressource), hParent, hDriver, cResources, puis la
                    structure du noeud (pointeurs vers des chaines du
                    tampon)
  Codes RMRC_* : 0 succes, 2 pilote, 3 adaptateur, 4 peripherique,
  5 ressource, 22 detecte ou 23 handle invalide, 9 pointeur nul,
  10 chaine nulle, 12 ressource deja prise, 14 parametre invalide,
  15 memoire insuffisante, 16 recherche sans resultat, 17 tampon trop
  petit, 18 echec general, 24 indicateurs invalides, 25 pas de donnees
  detectees.

  Fonctions exportees (ordinaux d'origine de RMINFO.DLL) :
     1 RMConvertID           13 RMGetSnoopLevel       25 RMSaveDetectedData
     2 RMEnumNodes           14 RMDestroyAdapter      26 _RMDestroyDetected
     3 _RMEnumNodes          15 RMDestroyDriver       27 _RMDeallocResource
     4 _RMConvertID          16 RMSetSnoopLevel       28 RMHandleToResourceHandleList
     5 RMGetNodeInfo         17 _RMCreateDetected     29 _RMHandleToResourceHandleList
     6 RMCreateDriver        18 _RMAllocResource      30 RMDevIDToHandleList
     7 _RMGetNodeInfo        19 _RMDestroyDriver      31 _RMSaveDetectedData
     8 RMAllocResource       20 _RMGetSnoopLevel      32 RMDeleteDetectedData
     9 RMCreateAdapter       21 RMDeallocResource     33 _RMDeleteDetectedData
    10 _RMCreateAdapter      22 _RMSetSnoopLevel      34 _RMDevIDToHandleList
    11 _RMCreateDriver       23 RMDestroyDetected
    12 RMCreateDetected      24 _RMDestroyAdapter

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services de DOSCALLS.DLL
    Partie 3 - Utilitaires
    Partie 4 - Noeuds et ressources
    Partie 5 - Materiel du noyau
    Partie 6 - Fonctions RM*
    Partie 7 - Seconds points d'entree (_RM*)
    Exportations et initialisation }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  RMRC_SUCCESS             = 0;
  RMRC_BAD_DRIVERHANDLE    = 2;
  RMRC_BAD_ADAPTERHANDLE   = 3;
  RMRC_BAD_DEVICEHANDLE    = 4;
  RMRC_BAD_RESOURCEHANDLE  = 5;
  RMRC_NULL_POINTER        = 9;
  RMRC_NULL_STRINGS        = 10;
  RMRC_RES_ALREADY_CLAIMED = 12;
  RMRC_INVALID_PARM_VALUE  = 14;
  RMRC_OUT_OF_MEMORY       = 15;
  RMRC_SEARCH_FAILED       = 16;
  RMRC_BUFFER_TOO_SMALL    = 17;
  RMRC_GENERAL_FAILURE     = 18;
  RMRC_BAD_DETECTHANDLE    = 22;
  RMRC_BAD_RMHANDLE        = 23;
  RMRC_BAD_FLAGS           = 24;
  RMRC_NO_DETECTED_DATA    = 25;

  { types de noeuds }
  RMTYPE_ADAPTER  = 0;
  RMTYPE_DRIVER   = 4;
  RMTYPE_DETECTED = 5;
  RMTYPE_RESOURCE = 6;
  RMTYPE_ALL      = $FFFF;

  { ressources }
  RS_TYPE_IO    = 1;
  RS_TYPE_IRQ   = 2;
  RS_TYPE_MEM   = 3;
  RS_TYPE_DMA   = 4;
  RS_TYPE_TIMER = 5;
  RS_EXCLUSIVE   = 1;
  RS_MULTIPLEXED = 2;
  RS_SHARED      = 4;

  RM_IDTYPE_EISA = 1;
  MaxN    = 160;             { noeuds }
  NF      = 10;              { champs numeriques par noeud }
  DetFile = 'C:\RMDETECT.DAT';

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  NUsed   : Array[0..MaxN - 1] Of Boolean;
  NType   : Array[0..MaxN - 1] Of LongInt;
  NParent : Array[0..MaxN - 1] Of LongInt;   { handle du parent (0 : systeme) }
  NDriver : Array[0..MaxN - 1] Of LongInt;   { handle du pilote proprietaire }
  NGen    : Array[0..MaxN - 1] Of LongInt;
  NBuiltin : Array[0..MaxN - 1] Of Boolean;  { materiel du noyau }
  NName   : Array[0..MaxN - 1] Of String[47];
  NDesc   : Array[0..MaxN - 1] Of String[47];
  NVendor : Array[0..MaxN - 1] Of String[31];
  NFld    : Array[0..MaxN * NF - 1] Of LongInt;
  SnoopLevel : LongInt;
  KrnDrv  : LongInt;                         { pilote OS2KRNL }
  NameZ   : Array[0..259] Of Byte;
  IoBuf   : Array[0..4095] Of Byte;
  TmpRes  : Array[0..7] Of LongInt;
  CurAdapt : LongInt;                        { adaptateur en construction }
  GBase, GStr, GSize : LongInt;              { tampon de RMGetNodeInfo }

{ ==================================================================== }
{ Partie 2 - Services de DOSCALLS.DLL                                  }
{ ==================================================================== }

Function DcOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS' Name 'DosOpen';
Function DcRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRead';
Function DcWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWrite';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';
Function DcDelete(PName : LongInt) : LongInt; External 'DOSCALLS' Name 'DosDelete';
Function KrnMouInfo(P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMouInfo';

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
      S := S + Chr(RdB(A + N));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function Fld(I, K : LongInt) : LongInt;
Begin
  Fld := NFld[I * NF + K];
End;

Procedure SetFld(I, K, V : LongInt);
Begin
  NFld[I * NF + K] := V;
End;

{ Identificateur EISA/PnP compresse (ex. PNP0303 -> 0303D041h) ; -1 si
  la chaine est invalide }
Function CompressID(S : String) : LongInt;
Var K, V, C1, C2, C3 : LongInt; Ok : Boolean;
Begin
  Ok := Length(S) = 7;
  If Ok Then
  Begin
    For K := 1 To 3 Do
      If (UpCase(S[K]) < 'A') Or (UpCase(S[K]) > 'Z') Then Ok := False;
    For K := 4 To 7 Do
      If Not (((S[K] >= '0') And (S[K] <= '9')) Or ((UpCase(S[K]) >= 'A') And (UpCase(S[K]) <= 'F'))) Then
        Ok := False;
  End;
  If Not Ok Then
  Begin
    CompressID := -1;
    Exit;
  End;
  C1 := Ord(UpCase(S[1])) - 64;
  C2 := Ord(UpCase(S[2])) - 64;
  C3 := Ord(UpCase(S[3])) - 64;
  V := ((C1 Shl 2) Or (C2 Shr 3)) Or ((((C2 And 7) Shl 5) Or C3) Shl 8);
  For K := 4 To 7 Do
  Begin
    If S[K] <= '9' Then C1 := Ord(S[K]) - 48 Else C1 := Ord(UpCase(S[K])) - 55;
    If K = 4 Then V := V Or (C1 Shl 20)
    Else If K = 5 Then V := V Or (C1 Shl 16)
    Else If K = 6 Then V := V Or (C1 Shl 28)
    Else V := V Or (C1 Shl 24);
  End;
  CompressID := V;
End;

Function HexCh(D : LongInt) : Char;
Begin
  If D < 10 Then HexCh := Chr(48 + D) Else HexCh := Chr(55 + D);
End;

Function ExpandID(V : LongInt) : String;
Var B0, B1, B2, B3 : LongInt; S : String;
Begin
  B0 := V And $FF;
  B1 := (V Shr 8) And $FF;
  B2 := (V Shr 16) And $FF;
  B3 := (V Shr 24) And $FF;
  S := Chr(64 + ((B0 Shr 2) And 31)) + Chr(64 + (((B0 And 3) Shl 3) Or (B1 Shr 5))) + Chr(64 + (B1 And 31));
  S := S + HexCh(B2 Shr 4) + HexCh(B2 And 15) + HexCh(B3 Shr 4) + HexCh(B3 And 15);
  ExpandID := S;
End;

{ ==================================================================== }
{ Partie 4 - Noeuds et ressources                                      }
{ ==================================================================== }

Function NHandle(I : LongInt) : LongInt;
Begin
  NHandle := (NGen[I] Shl 16) Or (I + 1);
End;

{ Handle -> indice du noeud du type T (-1 : invalide ; T = RMTYPE_ALL :
  tout type) }
Function NodeOf(H, T : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  I := (H And $FFFF) - 1;
  If (I >= 0) And (I < MaxN) Then
    If NUsed[I] And (NGen[I] = ((H Shr 16) And $FFFF)) Then
      If (T = RMTYPE_ALL) Or (NType[I] = T) Then R := I;
  NodeOf := R;
End;

Function NewNode(T, Parent, Drv : LongInt) : LongInt;
Var I, F, K : LongInt;
Begin
  F := -1;
  For I := MaxN - 1 DownTo 0 Do
    If Not NUsed[I] Then F := I;
  If F >= 0 Then
  Begin
    NUsed[F] := True;
    NType[F] := T;
    NParent[F] := Parent;
    NDriver[F] := Drv;
    NBuiltin[F] := False;
    NName[F] := ''; NDesc[F] := ''; NVendor[F] := '';
    For K := 0 To NF - 1 Do SetFld(F, K, 0);
  End;
  NewNode := F;
End;

Procedure FreeNode(I : LongInt);
Begin
  NUsed[I] := False;
  Inc(NGen[I]);
  If NGen[I] > $7FFF Then NGen[I] := 1;
End;

{ Deux ressources du meme type se recouvrent-elles ? }
Function Overlap(I, Typ, A, B : LongInt) : Boolean;
Var R : Boolean;
Begin
  R := False;
  If Fld(I, 0) = Typ Then
    Case Typ Of
      RS_TYPE_IO, RS_TYPE_MEM :
        R := (A < Fld(I, 1) + Fld(I, 2)) And (Fld(I, 1) < A + B);
      RS_TYPE_IRQ, RS_TYPE_DMA, RS_TYPE_TIMER :
        R := Fld(I, 1) = A;
    End;
  Overlap := R;
End;

Function ShareMode(F : LongInt) : LongInt;
Begin
  If (F And RS_SHARED) <> 0 Then ShareMode := RS_SHARED
  Else If (F And RS_MULTIPLEXED) <> 0 Then ShareMode := RS_MULTIPLEXED
  Else ShareMode := RS_EXCLUSIVE;
End;

{ Allouer une ressource (Typ, A, B, indicateurs, champ 4) au pilote Drv ;
  rend l'indice du noeud ou -code }
Function AllocRes(Drv, Typ, A, B, Flags, Extra : LongInt) : LongInt;
Var I, M, F : LongInt;
Begin
  M := ShareMode(Flags);
  For I := 0 To MaxN - 1 Do
    If NUsed[I] And (NType[I] = RMTYPE_RESOURCE) Then
      If Overlap(I, Typ, A, B) Then
        If (M = RS_EXCLUSIVE) Or (ShareMode(Fld(I, 3)) <> M) Then
        Begin
          AllocRes := -RMRC_RES_ALREADY_CLAIMED;
          Exit;
        End;
  F := NewNode(RMTYPE_RESOURCE, 0, Drv);
  If F < 0 Then
  Begin
    AllocRes := -RMRC_OUT_OF_MEMORY;
    Exit;
  End;
  SetFld(F, 0, Typ);
  SetFld(F, 1, A);
  SetFld(F, 2, B);
  SetFld(F, 3, Flags);
  SetFld(F, 4, Extra);
  AllocRes := F;
End;

{ Rattacher les ressources de AHRESOURCE au noeud Parent (pilote Drv) }
Function AttachRes(PAh, Drv, Parent : LongInt) : LongInt;
Var K, N, R, I : LongInt;
Begin
  R := RMRC_SUCCESS;
  If PAh <> 0 Then
  Begin
    N := RdL(PAh);
    { verifier d'abord }
    For K := 0 To N - 1 Do
    Begin
      I := NodeOf(RdL(PAh + 4 + K * 4), RMTYPE_RESOURCE);
      If I < 0 Then R := RMRC_BAD_RESOURCEHANDLE
      Else If NDriver[I] <> Drv Then R := RMRC_BAD_RESOURCEHANDLE
      Else If NParent[I] <> 0 Then R := RMRC_RES_ALREADY_CLAIMED;
    End;
    If R = RMRC_SUCCESS Then
      For K := 0 To N - 1 Do
        NParent[NodeOf(RdL(PAh + 4 + K * 4), RMTYPE_RESOURCE)] := Parent;
  End;
  AttachRes := R;
End;

{ Detruire le noeud I et ses descendants (les ressources rattachees sont
  liberees) }
Procedure DestroyTree(I : LongInt);
Var H, K : LongInt;
Begin
  H := NHandle(I);
  For K := 0 To MaxN - 1 Do
    If NUsed[K] And (K <> I) And ((NParent[K] = H) Or ((NType[I] = RMTYPE_DRIVER) And (NDriver[K] = H))) Then
      If NUsed[K] Then DestroyTree(K);
  FreeNode(I);
End;

{ Liste de handles (HANDLELIST) : ajouter H }
Function ListAdd(PList, H : LongInt) : Boolean;
Var N : LongInt;
Begin
  N := RdL(PList);
  If N < RdL(PList + 4) Then WrL(PList + 8 + N * 4, H);
  WrL(PList, N + 1);
  ListAdd := N < RdL(PList + 4);
End;

Function ListResult(PList : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := RdL(PList);
  If N > RdL(PList + 4) Then
  Begin
    WrL(PList, RdL(PList + 4));
    ListResult := RMRC_BUFFER_TOO_SMALL;
  End
  Else If N = 0 Then ListResult := RMRC_SEARCH_FAILED
  Else ListResult := RMRC_SUCCESS;
End;

{ ==================================================================== }
{ Partie 5 - Materiel du noyau                                         }
{ ==================================================================== }

Procedure KRes(Typ, A, B, Flags : LongInt);
Var I : LongInt;
Begin
  I := AllocRes(KrnDrv, Typ, A, B, Flags, 0);
  If I >= 0 Then
  Begin
    NParent[I] := CurAdapt;
    NBuiltin[I] := True;
  End;
End;

{ Adaptateur du noyau et son peripherique detecte }
Procedure KAdapter(Desc, PnpId : String; BaseType, SubType : LongInt);
Var I, D : LongInt;
Begin
  I := NewNode(RMTYPE_ADAPTER, 0, KrnDrv);
  If I < 0 Then Exit;
  NName[I] := Desc;
  NBuiltin[I] := True;
  SetFld(I, 1, BaseType);
  SetFld(I, 2, SubType);
  SetFld(I, 4, 1);                       { bus ISA }
  SetFld(I, 5, 16);
  CurAdapt := NHandle(I);
  D := NewNode(RMTYPE_DETECTED, 0, KrnDrv);
  If D >= 0 Then
  Begin
    NName[D] := Desc;
    NBuiltin[D] := True;
    SetFld(D, 1, RM_IDTYPE_EISA);
    SetFld(D, 2, CompressID(PnpId));
    SetFld(D, 3, -1);
    SetFld(D, 4, CompressID(PnpId));
    SetFld(D, 5, -1);
    SetFld(D, 6, -1);
  End;
End;

Procedure BuildKernelTree;
Var I, B : LongInt; P : PWord; Info : Array[0..3] Of LongInt;
Begin
  I := NewNode(RMTYPE_DRIVER, 0, 0);
  KrnDrv := NHandle(I);
  NDriver[I] := KrnDrv;
  NBuiltin[I] := True;
  NName[I] := 'OS2KRNL';
  NDesc[I] := 'Noyau OS/2-0';
  NVendor[I] := 'OS/2-0';
  SetFld(I, 0, 0); SetFld(I, 1, 1);
  SetFld(I, 2, 2026); SetFld(I, 3, 1); SetFld(I, 4, 1);
  KAdapter('Controleur d''interruptions 8259', 'PNP0000', 8, 0);
  KRes(RS_TYPE_IO, $20, 2, RS_EXCLUSIVE);
  KRes(RS_TYPE_IO, $A0, 2, RS_EXCLUSIVE);
  KRes(RS_TYPE_IRQ, 2, 0, RS_EXCLUSIVE);
  KAdapter('Minuterie 8254', 'PNP0100', 8, 1);
  KRes(RS_TYPE_IO, $40, 4, RS_EXCLUSIVE);
  KRes(RS_TYPE_IRQ, 0, 0, RS_EXCLUSIVE);
  KAdapter('Horloge temps reel', 'PNP0B00', 8, 3);
  KRes(RS_TYPE_IO, $70, 2, RS_EXCLUSIVE);
  KRes(RS_TYPE_IRQ, 8, 0, RS_EXCLUSIVE);
  KAdapter('Controleur du clavier 8042', 'PNP0303', 9, 0);
  KRes(RS_TYPE_IO, $60, 1, RS_EXCLUSIVE);
  KRes(RS_TYPE_IO, $64, 1, RS_EXCLUSIVE);
  KRes(RS_TYPE_IRQ, 1, 0, RS_EXCLUSIVE);
  If KrnMouInfo(LongInt(@Info)) <> 0 Then
  Begin
    KAdapter('Souris PS/2', 'PNP0F13', 9, 2);
    KRes(RS_TYPE_IRQ, 12, 0, RS_EXCLUSIVE);
  End;
  KAdapter('Controleur IDE', 'PNP0600', 1, 1);
  KRes(RS_TYPE_IO, $1F0, 8, RS_EXCLUSIVE);
  KRes(RS_TYPE_IO, $3F6, 1, RS_EXCLUSIVE);
  KRes(RS_TYPE_IRQ, 14, 0, RS_EXCLUSIVE);
  KAdapter('Affichage VGA', 'PNP0900', 3, 0);
  KRes(RS_TYPE_IO, $3B0, $30, RS_EXCLUSIVE);
  KRes(RS_TYPE_MEM, $A0000, $20000, RS_EXCLUSIVE);
  { ports series et paralleles (zone de donnees du BIOS) }
  For I := 0 To 1 Do
  Begin
    P := Pointer($400 + I * 2);
    B := P^;
    If B <> 0 Then
    Begin
      KAdapter('Port serie COM' + Chr(49 + I), 'PNP0500', 7, 0);
      KRes(RS_TYPE_IO, B, 8, RS_EXCLUSIVE);
      KRes(RS_TYPE_IRQ, 4 - I, 0, RS_SHARED);
    End;
  End;
  For I := 0 To 1 Do
  Begin
    P := Pointer($408 + I * 2);
    B := P^;
    If B <> 0 Then
    Begin
      KAdapter('Port parallele LPT' + Chr(49 + I), 'PNP0400', 7, 1);
      KRes(RS_TYPE_IO, B, 3, RS_EXCLUSIVE);
    End;
  End;
End;

{ ==================================================================== }
{ Partie 6 - Fonctions RM*                                             }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  RMCreateDriver(pDriverStruct, phDriver) : inscrire un pilote }
Function RMCreateDriver(PDs, PH : LongInt) : LongInt;
Var I : LongInt;
Begin
  If (PDs = 0) Or (PH = 0) Then
  Begin
    RMCreateDriver := RMRC_NULL_POINTER;
    Exit;
  End;
  If (RdL(PDs) = 0) Or (GetZ(RdL(PDs)) = '') Then
  Begin
    RMCreateDriver := RMRC_NULL_STRINGS;
    Exit;
  End;
  I := NewNode(RMTYPE_DRIVER, 0, 0);
  If I < 0 Then
  Begin
    RMCreateDriver := RMRC_OUT_OF_MEMORY;
    Exit;
  End;
  NDriver[I] := NHandle(I);
  NName[I] := Copy(GetZ(RdL(PDs)), 1, 47);
  NDesc[I] := Copy(GetZ(RdL(PDs + 4)), 1, 47);
  NVendor[I] := Copy(GetZ(RdL(PDs + 8)), 1, 31);
  SetFld(I, 0, RdB(PDs + 12));
  SetFld(I, 1, RdB(PDs + 13));
  SetFld(I, 2, RdW(PDs + 14));
  SetFld(I, 3, RdB(PDs + 16));
  SetFld(I, 4, RdB(PDs + 17));
  SetFld(I, 5, RdW(PDs + 18));
  SetFld(I, 6, RdW(PDs + 20));
  SetFld(I, 7, RdW(PDs + 22));
  SetFld(I, 8, RdL(PDs + 24));
  WrL(PH, NHandle(I));
  RMCreateDriver := RMRC_SUCCESS;
End;

{ ---------------------------------------------------------------------
  RMDestroyDriver(hDriver) : retirer le pilote, ses adaptateurs, ses
  peripheriques detectes et ses ressources }
Function RMDestroyDriver(HDrv : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := NodeOf(HDrv, RMTYPE_DRIVER);
  If (I < 0) Or NBuiltin[I] Then RMDestroyDriver := RMRC_BAD_DRIVERHANDLE
  Else
  Begin
    DestroyTree(I);
    RMDestroyDriver := RMRC_SUCCESS;
  End;
End;

{ ---------------------------------------------------------------------
  RMAllocResource(hDriver, phResource, pResourceStruct) : allouer une
  ressource (RMRC_RES_ALREADY_CLAIMED si elle est prise
  exclusivement ou dans un autre mode de partage) }
Function RMAllocResource(HDrv, PH, PRs : LongInt) : LongInt;
Var Typ, A, B, F, X, I : LongInt;
Begin
  If NodeOf(HDrv, RMTYPE_DRIVER) < 0 Then
  Begin
    RMAllocResource := RMRC_BAD_DRIVERHANDLE;
    Exit;
  End;
  If (PH = 0) Or (PRs = 0) Then
  Begin
    RMAllocResource := RMRC_NULL_POINTER;
    Exit;
  End;
  Typ := RdL(PRs);
  A := 0; B := 0; F := 0; X := 0;
  Case Typ Of
    RS_TYPE_IO :
      Begin
        A := RdW(PRs + 4); B := RdW(PRs + 6); F := RdW(PRs + 8); X := RdW(PRs + 10);
        If B = 0 Then Typ := -1;
      End;
    RS_TYPE_IRQ :
      Begin
        A := RdW(PRs + 4); B := RdW(PRs + 6); F := RdW(PRs + 8); X := RdL(PRs + 12);
        If A > 15 Then Typ := -1;
      End;
    RS_TYPE_MEM :
      Begin
        A := RdL(PRs + 4); B := RdL(PRs + 8); F := RdW(PRs + 12);
        If B = 0 Then Typ := -1;
      End;
    RS_TYPE_DMA, RS_TYPE_TIMER :
      Begin
        A := RdW(PRs + 4); F := RdW(PRs + 6);
        If (Typ = RS_TYPE_DMA) And (A > 7) Then Typ := -1;
      End;
  Else
    Typ := -1;
  End;
  If Typ < 0 Then
  Begin
    RMAllocResource := RMRC_INVALID_PARM_VALUE;
    Exit;
  End;
  If ((F And 7) <> 0) And ((F And 7) <> RS_EXCLUSIVE) And ((F And 7) <> RS_MULTIPLEXED) And
     ((F And 7) <> RS_SHARED) Then
  Begin
    RMAllocResource := RMRC_BAD_FLAGS;
    Exit;
  End;
  I := AllocRes(HDrv, Typ, A, B, F, X);
  If I < 0 Then RMAllocResource := -I
  Else
  Begin
    WrL(PH, NHandle(I));
    RMAllocResource := RMRC_SUCCESS;
  End;
End;

{ ---------------------------------------------------------------------
  RMDeallocResource(hDriver, hResource) : liberer une ressource du
  pilote }
Function RMDeallocResource(HDrv, HRes : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := NodeOf(HRes, RMTYPE_RESOURCE);
  If NodeOf(HDrv, RMTYPE_DRIVER) < 0 Then RMDeallocResource := RMRC_BAD_DRIVERHANDLE
  Else If (I < 0) Or (NDriver[I] <> HDrv) Or NBuiltin[I] Then RMDeallocResource := RMRC_BAD_RESOURCEHANDLE
  Else
  Begin
    FreeNode(I);
    RMDeallocResource := RMRC_SUCCESS;
  End;
End;

{ ---------------------------------------------------------------------
  RMCreateAdapter(hDriver, phAdapter, pAdapterStruct, hDevice,
  pahResource) : inscrire un adaptateur (sous l'adaptateur hDevice, 0 :
  le systeme) et lui rattacher les ressources du pilote }
Function RMCreateAdapter(HDrv, PH, PAs, HDev, PAh : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  If NodeOf(HDrv, RMTYPE_DRIVER) < 0 Then
  Begin
    RMCreateAdapter := RMRC_BAD_DRIVERHANDLE;
    Exit;
  End;
  If (PH = 0) Or (PAs = 0) Then
  Begin
    RMCreateAdapter := RMRC_NULL_POINTER;
    Exit;
  End;
  If (HDev <> 0) And (NodeOf(HDev, RMTYPE_ADAPTER) < 0) Then
  Begin
    RMCreateAdapter := RMRC_BAD_DEVICEHANDLE;
    Exit;
  End;
  I := NewNode(RMTYPE_ADAPTER, HDev, HDrv);
  If I < 0 Then
  Begin
    RMCreateAdapter := RMRC_OUT_OF_MEMORY;
    Exit;
  End;
  R := AttachRes(PAh, HDrv, NHandle(I));
  If R <> RMRC_SUCCESS Then
  Begin
    FreeNode(I);
    RMCreateAdapter := R;
    Exit;
  End;
  NName[I] := Copy(GetZ(RdL(PAs)), 1, 47);
  SetFld(I, 0, RdW(PAs + 4));
  SetFld(I, 1, RdW(PAs + 6));
  SetFld(I, 2, RdW(PAs + 8));
  SetFld(I, 3, RdW(PAs + 10));
  SetFld(I, 4, RdW(PAs + 12));
  SetFld(I, 5, RdW(PAs + 14));
  WrL(PH, NHandle(I));
  RMCreateAdapter := RMRC_SUCCESS;
End;

{ ---------------------------------------------------------------------
  RMDestroyAdapter(hDriver, hAdapter) : retirer un adaptateur du pilote
  (ses ressources sont liberees) }
Function RMDestroyAdapter(HDrv, HAd : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := NodeOf(HAd, RMTYPE_ADAPTER);
  If NodeOf(HDrv, RMTYPE_DRIVER) < 0 Then RMDestroyAdapter := RMRC_BAD_DRIVERHANDLE
  Else If (I < 0) Or (NDriver[I] <> HDrv) Or NBuiltin[I] Then RMDestroyAdapter := RMRC_BAD_ADAPTERHANDLE
  Else
  Begin
    DestroyTree(I);
    RMDestroyAdapter := RMRC_SUCCESS;
  End;
End;

{ Creer un peripherique detecte (sans controle des pointeurs) }
Function NewDetected(HDrv, PDs : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := NewNode(RMTYPE_DETECTED, 0, HDrv);
  If I >= 0 Then
  Begin
    NName[I] := Copy(GetZ(RdL(PDs)), 1, 47);
    SetFld(I, 0, RdW(PDs + 4));
    SetFld(I, 1, RdW(PDs + 6));
    SetFld(I, 2, RdL(PDs + 8));
    SetFld(I, 3, RdL(PDs + 12));
    SetFld(I, 4, RdL(PDs + 16));
    SetFld(I, 5, RdL(PDs + 20));
    SetFld(I, 6, RdL(PDs + 24));
  End;
  NewDetected := I;
End;

{ ---------------------------------------------------------------------
  RMCreateDetected(hDriver, phDetected, pDetectedStruct, pahResource) :
  inscrire un peripherique detecte (identificateurs, ressources) }
Function RMCreateDetected(HDrv, PH, PDs, PAh : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  If NodeOf(HDrv, RMTYPE_DRIVER) < 0 Then
  Begin
    RMCreateDetected := RMRC_BAD_DRIVERHANDLE;
    Exit;
  End;
  If (PH = 0) Or (PDs = 0) Then
  Begin
    RMCreateDetected := RMRC_NULL_POINTER;
    Exit;
  End;
  I := NewDetected(HDrv, PDs);
  If I < 0 Then
  Begin
    RMCreateDetected := RMRC_OUT_OF_MEMORY;
    Exit;
  End;
  R := AttachRes(PAh, HDrv, NHandle(I));
  If R <> RMRC_SUCCESS Then
  Begin
    FreeNode(I);
    RMCreateDetected := R;
    Exit;
  End;
  WrL(PH, NHandle(I));
  RMCreateDetected := RMRC_SUCCESS;
End;

{ ---------------------------------------------------------------------
  RMDestroyDetected(hDriver, hDetected) }
Function RMDestroyDetected(HDrv, HDet : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := NodeOf(HDet, RMTYPE_DETECTED);
  If NodeOf(HDrv, RMTYPE_DRIVER) < 0 Then RMDestroyDetected := RMRC_BAD_DRIVERHANDLE
  Else If (I < 0) Or (NDriver[I] <> HDrv) Or NBuiltin[I] Then RMDestroyDetected := RMRC_BAD_DETECTHANDLE
  Else
  Begin
    DestroyTree(I);
    RMDestroyDetected := RMRC_SUCCESS;
  End;
End;

{ ---------------------------------------------------------------------
  RMEnumNodes(ulNodeType, pHandleList) : handles des noeuds du type
  (RMTYPE_ALL = FFFFh : tous) ; RMRC_BUFFER_TOO_SMALL si la liste ne
  suffit pas (cHandles <- cMaxHandles) }
Function RMEnumNodes(T, PList : LongInt) : LongInt;
Var I, D : LongInt; Ok : Boolean;
Begin
  If PList = 0 Then
  Begin
    RMEnumNodes := RMRC_NULL_POINTER;
    Exit;
  End;
  WrL(PList, 0);
  For I := 0 To MaxN - 1 Do
    If NUsed[I] And ((T = RMTYPE_ALL) Or (NType[I] = T)) Then Ok := ListAdd(PList, NHandle(I));
  D := ListResult(PList);
  If D = RMRC_SEARCH_FAILED Then D := RMRC_SUCCESS;
  RMEnumNodes := D;
End;

{ ---------------------------------------------------------------------
  RMHandleToResourceHandleList(hNode, pHandleList) : ressources du noeud
  (adaptateur ou peripherique detecte : ressources rattachees ; pilote :
  ressources allouees) }
Function RMHandleToResourceHandleList(H, PList : LongInt) : LongInt;
Var I, K, D : LongInt; Ok : Boolean;
Begin
  I := NodeOf(H, RMTYPE_ALL);
  If I < 0 Then
  Begin
    RMHandleToResourceHandleList := RMRC_BAD_RMHANDLE;
    Exit;
  End;
  If PList = 0 Then
  Begin
    RMHandleToResourceHandleList := RMRC_NULL_POINTER;
    Exit;
  End;
  WrL(PList, 0);
  For K := 0 To MaxN - 1 Do
    If NUsed[K] And (NType[K] = RMTYPE_RESOURCE) Then
      If ((NType[I] = RMTYPE_DRIVER) And (NDriver[K] = H)) Or (NParent[K] = H) Then
        Ok := ListAdd(PList, NHandle(K));
  D := ListResult(PList);
  If D = RMRC_SEARCH_FAILED Then D := RMRC_SUCCESS;
  RMHandleToResourceHandleList := D;
End;

{ ---------------------------------------------------------------------
  RMDevIDToHandleList(IDType, DeviceID, FunctionID, CompatibleID,
  VendorID, SerialNumber, ulSearchFlags, hStartNode, pHandleList) :
  peripheriques detectes dont les identificateurs choisis par
  ulSearchFlags (1 DeviceID, 2 FunctionID, 4 CompatibleID, 8 VendorID,
  16 SerialNumber) sont egaux ; IDType 0 : tout type ; la recherche
  commence apres hStartNode (0 : au debut) }
Function RMDevIDToHandleList(IdType, DevId, FnId, CompId, VendId, Serial, Flags, HStart, PList : LongInt) : LongInt;
Var I, S : LongInt; Ok, M : Boolean;
Begin
  If PList = 0 Then
  Begin
    RMDevIDToHandleList := RMRC_NULL_POINTER;
    Exit;
  End;
  If (Flags And Not 31) <> 0 Then
  Begin
    RMDevIDToHandleList := RMRC_BAD_FLAGS;
    Exit;
  End;
  S := 0;
  If HStart <> 0 Then
  Begin
    S := NodeOf(HStart, RMTYPE_ALL);
    If S < 0 Then
    Begin
      RMDevIDToHandleList := RMRC_BAD_RMHANDLE;
      Exit;
    End;
    Inc(S);
  End;
  WrL(PList, 0);
  For I := S To MaxN - 1 Do
    If NUsed[I] And (NType[I] = RMTYPE_DETECTED) Then
    Begin
      M := (IdType = 0) Or (Fld(I, 1) = IdType);
      If (Flags And 1) <> 0 Then M := M And (Fld(I, 2) = DevId);
      If (Flags And 2) <> 0 Then M := M And (Fld(I, 3) = FnId);
      If (Flags And 4) <> 0 Then M := M And (Fld(I, 4) = CompId);
      If (Flags And 8) <> 0 Then M := M And (Fld(I, 5) = VendId);
      If (Flags And 16) <> 0 Then M := M And (Fld(I, 6) = Serial);
      If M Then Ok := ListAdd(PList, NHandle(I));
    End;
  RMDevIDToHandleList := ListResult(PList);
End;

{ ---------------------------------------------------------------------
  RMGetNodeInfo(hNode, pNodeData, cbBuffer) : informations du noeud
  (RM_GETNODE_DATA, voir l'en-tete) }
{ Ajouter une chaine au tampon et rendre son adresse }
Function GPut(S : String) : LongInt;
Begin
  If GStr + Length(S) + 1 <= GSize Then PutZ(GBase + GStr, S);
  GPut := GBase + GStr;
  GStr := GStr + Length(S) + 1;
End;

Function RMGetNodeInfo(H, PBuf, Cb : LongInt) : LongInt;
Var I, K, N, S, Need : LongInt;
Begin
  I := NodeOf(H, RMTYPE_ALL);
  If I < 0 Then
  Begin
    RMGetNodeInfo := RMRC_BAD_RMHANDLE;
    Exit;
  End;
  If PBuf = 0 Then
  Begin
    RMGetNodeInfo := RMRC_NULL_POINTER;
    Exit;
  End;
  Case NType[I] Of
    RMTYPE_DRIVER   : S := 28;
    RMTYPE_ADAPTER  : S := 24;
    RMTYPE_DETECTED : S := 36;
  Else
    S := 20;
  End;
  Need := 20 + S + Length(NName[I]) + Length(NDesc[I]) + Length(NVendor[I]) + 3;
  If Cb < Need Then
  Begin
    If Cb >= 4 Then WrL(PBuf, Need);
    RMGetNodeInfo := RMRC_BUFFER_TOO_SMALL;
    Exit;
  End;
  N := 0;
  For K := 0 To MaxN - 1 Do
    If NUsed[K] And (NType[K] = RMTYPE_RESOURCE) Then
      If ((NType[I] = RMTYPE_DRIVER) And (NDriver[K] = H)) Or (NParent[K] = H) Then Inc(N);
  For K := 0 To 20 + S - 1 Do WrB(PBuf + K, 0);
  WrL(PBuf, Need);
  WrL(PBuf + 4, NType[I]);
  WrL(PBuf + 8, NParent[I]);
  WrL(PBuf + 12, NDriver[I]);
  WrL(PBuf + 16, N);
  GBase := PBuf; GStr := 20 + S; GSize := Cb;
  K := PBuf + 20;
  Case NType[I] Of
    RMTYPE_DRIVER :
      Begin
        WrL(K, GPut(NName[I]));
        WrL(K + 4, GPut(NDesc[I]));
        WrL(K + 8, GPut(NVendor[I]));
        WrB(K + 12, Fld(I, 0)); WrB(K + 13, Fld(I, 1));
        WrW(K + 14, Fld(I, 2)); WrB(K + 16, Fld(I, 3)); WrB(K + 17, Fld(I, 4));
        WrW(K + 18, Fld(I, 5)); WrW(K + 20, Fld(I, 6)); WrW(K + 22, Fld(I, 7));
        WrL(K + 24, Fld(I, 8));
      End;
    RMTYPE_ADAPTER :
      Begin
        WrL(K, GPut(NName[I]));
        WrW(K + 4, Fld(I, 0)); WrW(K + 6, Fld(I, 1)); WrW(K + 8, Fld(I, 2));
        WrW(K + 10, Fld(I, 3)); WrW(K + 12, Fld(I, 4)); WrW(K + 14, Fld(I, 5));
      End;
    RMTYPE_DETECTED :
      Begin
        WrL(K, GPut(NName[I]));
        WrW(K + 4, Fld(I, 0)); WrW(K + 6, Fld(I, 1));
        WrL(K + 8, Fld(I, 2)); WrL(K + 12, Fld(I, 3)); WrL(K + 16, Fld(I, 4));
        WrL(K + 20, Fld(I, 5)); WrL(K + 24, Fld(I, 6));
      End;
  Else
    Begin
      { RESOURCESTRUCT }
      WrL(K, Fld(I, 0));
      Case Fld(I, 0) Of
        RS_TYPE_IO :
          Begin
            WrW(K + 4, Fld(I, 1)); WrW(K + 6, Fld(I, 2)); WrW(K + 8, Fld(I, 3)); WrW(K + 10, Fld(I, 4));
          End;
        RS_TYPE_IRQ :
          Begin
            WrW(K + 4, Fld(I, 1)); WrW(K + 6, Fld(I, 2)); WrW(K + 8, Fld(I, 3)); WrL(K + 12, Fld(I, 4));
          End;
        RS_TYPE_MEM :
          Begin
            WrL(K + 4, Fld(I, 1)); WrL(K + 8, Fld(I, 2)); WrW(K + 12, Fld(I, 3));
          End;
      Else
        Begin
          WrW(K + 4, Fld(I, 1)); WrW(K + 6, Fld(I, 3));
        End;
      End;
    End;
  End;
  RMGetNodeInfo := RMRC_SUCCESS;
End;

{ ---------------------------------------------------------------------
  RMConvertID(pulCompressedID, pszID, ulFlags) : identificateur EISA/PnP
  compresse <-> texte (7 caracteres, ex. PNP0303). ulFlags 0 : compresse
  -> texte ; 1 : texte -> compresse }
Function RMConvertID(PId, PSz, Flags : LongInt) : LongInt;
Var V : LongInt;
Begin
  If (PId = 0) Or (PSz = 0) Then RMConvertID := RMRC_NULL_POINTER
  Else If Flags = 0 Then
  Begin
    PutZ(PSz, ExpandID(RdL(PId)));
    RMConvertID := RMRC_SUCCESS;
  End
  Else If Flags = 1 Then
  Begin
    V := CompressID(GetZ(PSz));
    If (V = -1) And (Length(GetZ(PSz)) <> 7) Then RMConvertID := RMRC_INVALID_PARM_VALUE
    Else If V = -1 Then RMConvertID := RMRC_INVALID_PARM_VALUE
    Else
    Begin
      WrL(PId, V);
      RMConvertID := RMRC_SUCCESS;
    End;
  End
  Else RMConvertID := RMRC_BAD_FLAGS;
End;

{ ---------------------------------------------------------------------
  RMGetSnoopLevel(pulLevel), RMSetSnoopLevel(ulLevel, ulFlags) : niveau
  de detection du materiel (0 aucune, 1 sure, 2 prudente, 3 complete) }
Function RMGetSnoopLevel(PLevel : LongInt) : LongInt;
Begin
  If PLevel = 0 Then RMGetSnoopLevel := RMRC_NULL_POINTER
  Else
  Begin
    WrL(PLevel, SnoopLevel);
    RMGetSnoopLevel := RMRC_SUCCESS;
  End;
End;

Function RMSetSnoopLevel(Level, Flags : LongInt) : LongInt;
Begin
  If (Level < 0) Or (Level > 3) Then RMSetSnoopLevel := RMRC_INVALID_PARM_VALUE
  Else If Flags <> 0 Then RMSetSnoopLevel := RMRC_BAD_FLAGS
  Else
  Begin
    SnoopLevel := Level;
    RMSetSnoopLevel := RMRC_SUCCESS;
  End;
End;

{ ---------------------------------------------------------------------
  RMSaveDetectedData : ecrire les peripheriques detectes inscrits par
  les applications dans C:\RMDETECT.DAT (une ligne par peripherique :
  indicateurs, type, DeviceID, FunctionID, CompatibleID, VendorID,
  SerialNumber, nom) ; RMRC_NO_DETECTED_DATA s'il n'y en a pas.
  RMDeleteDetectedData : supprimer ce fichier. }
Function HexL(V : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  For K := 7 DownTo 0 Do S := S + HexCh((V Shr (K * 4)) And 15);
  HexL := S;
End;

Function RMSaveDetectedData : LongInt;
Var I, K, N, H, Act, W, R, D : LongInt; S : String;
Begin
  N := 0;
  For I := 0 To MaxN - 1 Do
    If NUsed[I] And (NType[I] = RMTYPE_DETECTED) And Not NBuiltin[I] Then
    Begin
      S := HexL(Fld(I, 0)) + ' ' + HexL(Fld(I, 1));
      For K := 2 To 6 Do S := S + ' ' + HexL(Fld(I, K));
      S := S + ' ' + NName[I] + Chr(13) + Chr(10);
      If N + Length(S) <= 4096 Then
        For K := 1 To Length(S) Do
        Begin
          IoBuf[N] := Ord(S[K]);
          Inc(N);
        End;
    End;
  If N = 0 Then
  Begin
    RMSaveDetectedData := RMRC_NO_DETECTED_DATA;
    Exit;
  End;
  PutZ(LongInt(@NameZ), DetFile);
  R := DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), 0, 0, $12, $41, 0);
  If R = 0 Then
  Begin
    R := DcWrite(H, LongInt(@IoBuf), N, LongInt(@W));
    D := DcClose(H);
  End;
  If R <> 0 Then RMSaveDetectedData := RMRC_GENERAL_FAILURE
  Else RMSaveDetectedData := RMRC_SUCCESS;
End;

Function RMDeleteDetectedData : LongInt;
Begin
  PutZ(LongInt(@NameZ), DetFile);
  If DcDelete(LongInt(@NameZ)) <> 0 Then RMDeleteDetectedData := RMRC_NO_DETECTED_DATA
  Else RMDeleteDetectedData := RMRC_SUCCESS;
End;

{ Relire C:\RMDETECT.DAT (peripheriques detectes du pilote OS2KRNL) }
Function HexOf(Var P : LongInt; N : LongInt) : LongInt;
Var V, K, C : LongInt;
Begin
  V := 0;
  For K := 1 To 8 Do
  Begin
    If P < N Then
    Begin
      C := IoBuf[P];
      If C <= 57 Then C := C - 48 Else C := C - 55;
      V := (V Shl 4) Or (C And 15);
    End;
    Inc(P);
  End;
  Inc(P);                                  { espace }
  HexOf := V;
End;

Procedure LoadDetectedData;
Var H, Act, N, P, I, K, D : LongInt; S : String;
Begin
  PutZ(LongInt(@NameZ), DetFile);
  If DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) <> 0 Then Exit;
  N := 0;
  D := DcRead(H, LongInt(@IoBuf), 4096, LongInt(@N));
  D := DcClose(H);
  P := 0;
  While P + 63 <= N Do
  Begin
    I := NewNode(RMTYPE_DETECTED, 0, KrnDrv);
    If I < 0 Then Exit;
    For K := 0 To 6 Do SetFld(I, K, HexOf(P, N));
    S := '';
    While (P < N) And (IoBuf[P] <> 13) Do
    Begin
      If Length(S) < 47 Then S := S + Chr(IoBuf[P]);
      Inc(P);
    End;
    NName[I] := S;
    P := P + 2;
  End;
End;

{ ==================================================================== }
{ Partie 7 - Seconds points d'entree (_RM*)                            }
{ ==================================================================== }

Function _RMConvertID(PId, PSz, Flags : LongInt) : LongInt;
Begin
  _RMConvertID := RMConvertID(PId, PSz, Flags);
End;

Function _RMEnumNodes(T, PList : LongInt) : LongInt;
Begin
  _RMEnumNodes := RMEnumNodes(T, PList);
End;

Function _RMGetNodeInfo(H, PBuf, Cb : LongInt) : LongInt;
Begin
  _RMGetNodeInfo := RMGetNodeInfo(H, PBuf, Cb);
End;

Function _RMCreateDriver(PDs, PH : LongInt) : LongInt;
Begin
  _RMCreateDriver := RMCreateDriver(PDs, PH);
End;

Function _RMDestroyDriver(HDrv : LongInt) : LongInt;
Begin
  _RMDestroyDriver := RMDestroyDriver(HDrv);
End;

Function _RMAllocResource(HDrv, PH, PRs : LongInt) : LongInt;
Begin
  _RMAllocResource := RMAllocResource(HDrv, PH, PRs);
End;

Function _RMDeallocResource(HDrv, HRes : LongInt) : LongInt;
Begin
  _RMDeallocResource := RMDeallocResource(HDrv, HRes);
End;

Function _RMCreateAdapter(HDrv, PH, PAs, HDev, PAh : LongInt) : LongInt;
Begin
  _RMCreateAdapter := RMCreateAdapter(HDrv, PH, PAs, HDev, PAh);
End;

Function _RMDestroyAdapter(HDrv, HAd : LongInt) : LongInt;
Begin
  _RMDestroyAdapter := RMDestroyAdapter(HDrv, HAd);
End;

Function _RMCreateDetected(HDrv, PH, PDs, PAh : LongInt) : LongInt;
Begin
  _RMCreateDetected := RMCreateDetected(HDrv, PH, PDs, PAh);
End;

Function _RMDestroyDetected(HDrv, HDet : LongInt) : LongInt;
Begin
  _RMDestroyDetected := RMDestroyDetected(HDrv, HDet);
End;

Function _RMGetSnoopLevel(PLevel : LongInt) : LongInt;
Begin
  _RMGetSnoopLevel := RMGetSnoopLevel(PLevel);
End;

Function _RMSetSnoopLevel(Level, Flags : LongInt) : LongInt;
Begin
  _RMSetSnoopLevel := RMSetSnoopLevel(Level, Flags);
End;

Function _RMSaveDetectedData : LongInt;
Begin
  _RMSaveDetectedData := RMSaveDetectedData;
End;

Function _RMDeleteDetectedData : LongInt;
Begin
  _RMDeleteDetectedData := RMDeleteDetectedData;
End;

Function _RMHandleToResourceHandleList(H, PList : LongInt) : LongInt;
Begin
  _RMHandleToResourceHandleList := RMHandleToResourceHandleList(H, PList);
End;

Function _RMDevIDToHandleList(IdType, DevId, FnId, CompId, VendId, Serial, Flags, HStart, PList : LongInt) : LongInt;
Begin
  _RMDevIDToHandleList := RMDevIDToHandleList(IdType, DevId, FnId, CompId, VendId, Serial, Flags, HStart, PList);
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  RMConvertID Index 1, RMEnumNodes Index 2, _RMEnumNodes Index 3,
  _RMConvertID Index 4, RMGetNodeInfo Index 5, RMCreateDriver Index 6,
  _RMGetNodeInfo Index 7, RMAllocResource Index 8, RMCreateAdapter Index 9,
  _RMCreateAdapter Index 10, _RMCreateDriver Index 11,
  RMCreateDetected Index 12, RMGetSnoopLevel Index 13,
  RMDestroyAdapter Index 14, RMDestroyDriver Index 15,
  RMSetSnoopLevel Index 16, _RMCreateDetected Index 17,
  _RMAllocResource Index 18, _RMDestroyDriver Index 19,
  _RMGetSnoopLevel Index 20, RMDeallocResource Index 21,
  _RMSetSnoopLevel Index 22, RMDestroyDetected Index 23,
  _RMDestroyAdapter Index 24, RMSaveDetectedData Index 25,
  _RMDestroyDetected Index 26, _RMDeallocResource Index 27,
  RMHandleToResourceHandleList Index 28,
  _RMHandleToResourceHandleList Index 29, RMDevIDToHandleList Index 30,
  _RMSaveDetectedData Index 31, RMDeleteDetectedData Index 32,
  _RMDeleteDetectedData Index 33, _RMDevIDToHandleList Index 34;

Var
  InitI : LongInt;

BEGIN
  For InitI := 0 To MaxN - 1 Do
  Begin
    NUsed[InitI] := False;
    NGen[InitI] := 1;
  End;
  SnoopLevel := 1;
  CurAdapt := 0;
  BuildKernelTree;
  LoadDetectedData;
END.
