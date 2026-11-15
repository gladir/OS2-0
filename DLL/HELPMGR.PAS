{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 HELPMGR.DLL de OS/2-0 (gestionnaire
                d'aide IPF : instances d'aide et tables d'aide).
}

Library HELPMGR;

{$IMAGEBASE $00880000}
{$R-,S-,I-}

{ Compilation : OS2PC HELPMGR.PAS   (produit HELPMGR.DLL)

  HELPMGR.DLL est le gestionnaire d'aide (IPF, Information Presentation
  Facility) : une application cree une instance d'aide
  (WinCreateHelpInstance) a partir d'une structure HELPINIT (titre de la
  fenetre d'aide, bibliotheques d'aide .HLP, table d'aide), puis
  l'associe a ses fenetres cadres (WinAssociateHelpInstance). La table
  d'aide relie chaque fenetre de l'application (idAppWindow) a une
  sous-table (fenetre ayant le focus -> panneau d'aide) et a un panneau
  d'aide etendue.

  OS/2-0 n'a pas Presentation Manager : les handles de fenetres (HWND)
  sont des valeurs conservees telles quelles et l'instance d'aide est un
  handle propre a HELPMGR ($0003xxxx). Les bibliotheques d'aide sont
  cherchees telles quelles, dans le repertoire courant, dans les
  repertoires de la variable HELP puis dans C:\ ; un fichier .HLP
  commence par la signature HSP.

  Structures (convention _System ; HELPTABLE et HELPSUBTABLE sont
  alignees sur 2 octets, comme dans PMHELP.H) :
    HELPINIT     cb, ulReturnCode, pszTutorialName, phtHelpTable,
                 hmodHelpTableModule, hmodAccelActionBarModule,
                 idAccelTable, idActionBar, pszHelpWindowTitle,
                 fShowPanelId, pszHelpLibraryName              44 octets
                 (phtHelpTable = FFFFxxxxh : table d'aide xxxx dans les
                 ressources de hmodHelpTableModule)
    HELPTABLE    idAppWindow (mot), phstHelpSubTable, idExtPanel (mot) ;
                 8 octets par entree, idAppWindow = 0 a la fin
    HELPSUBTABLE mots : taille d'un element (SUBITEMSIZE, 2 au moins),
                 puis les elements (idWindow, idPanel, ...) ; idWindow = 0
                 a la fin
  Ressources (DosGetResource) : RT_HELPTABLE (18) : elements de 3 mots
  (idAppWindow, identificateur de la sous-table, idExtPanel), 0 a la fin ;
  RT_HELPSUBTABLE (19) : meme format que HELPSUBTABLE.
  Erreurs (HELPINIT.ulReturnCode) : HMERR_HELPTABLE_UNDEFINE (1009h),
  HMERR_OPEN_LIB_FILE (2003h), HMERR_INVALID_LIB_FILE (2006h),
  HMERR_NO_MEMORY (2007h).

  Fonctions exportees (ordinaux d'origine de HELPMGR.DLL) :
     1 WINCREATEHELPINSTANCE      4 WINASSOCIATEHELPINSTANCE
     2 WINDESTROYHELPINSTANCE     5 WINLOADHELPTABLE
     3 WINQUERYHELPINSTANCE       6 WINCREATEHELPTABLE
  Points d'entree internes a OS/2-0 (ce que la fenetre d'aide d'IPF
  ferait a la touche F1) :
   100 HMQUERYPANELID(hwndHelp, idAppWindow, idWindow) : panneau d'aide
       de la fenetre idWindow (sous-table), sinon panneau d'aide etendue
       de idAppWindow ; 0 si aucun
   101 HMQUERYINSTANCEINFO(hwndHelp, champ, psz, cb) : 1 titre, 2
       bibliotheques trouvees, 3 tutoriel, 4 nombre d'entrees de la
       table (rendu) ; rend la longueur de la chaine, -1 si erreur

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services de DOSCALLS
    Partie 3 - Utilitaires
    Partie 4 - Tables d'aide
    Partie 5 - Bibliotheques d'aide
    Partie 6 - Fonctions
    Exportations et initialisation }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  NO_ERROR = 0;
  HMERR_HELPTABLE_UNDEFINE = $1009;
  HMERR_OPEN_LIB_FILE      = $2003;
  HMERR_INVALID_LIB_FILE   = $2006;
  HMERR_NO_MEMORY          = $2007;

  RT_HELPTABLE    = 18;
  RT_HELPSUBTABLE = 19;

  MaxInst  = 8;               { instances d'aide }
  MaxTab   = 32;              { entrees de table d'aide par instance }
  MaxSub   = 256;             { elements de sous-tables par instance }
  MaxAssoc = 32;              { fenetres associees }
  HelpBase = $00030000;       { handle : HelpBase + generation * 256 + n }

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  IUsed   : Array[0..MaxInst - 1] Of Boolean;
  IGen    : Array[0..MaxInst - 1] Of LongInt;
  ITitle, ITutor : Array[0..MaxInst - 1] Of String[79];
  ILib    : Array[0..MaxInst - 1] Of String;
  IShowId : Array[0..MaxInst - 1] Of LongInt;
  IAccel, IActBar : Array[0..MaxInst - 1] Of LongInt;
  { table d'aide : entrees de l'instance I aux indices I * MaxTab ... }
  ITabN   : Array[0..MaxInst - 1] Of LongInt;
  ISubN   : Array[0..MaxInst - 1] Of LongInt;
  TApp, TExt, TSubFirst, TSubN : Array[0..MaxInst * MaxTab - 1] Of LongInt;
  SWin, SPan : Array[0..MaxInst * MaxSub - 1] Of LongInt;
  { associations fenetre -> instance }
  AHwnd, AInst : Array[0..MaxAssoc - 1] Of LongInt;
  { table en construction }
  NTabN, NSubN : LongInt;
  NApp, NExt, NSubFirst, NSubCnt : Array[0..MaxTab - 1] Of LongInt;
  NWin, NPan : Array[0..MaxSub - 1] Of LongInt;
  NameZ   : Array[0..259] Of Byte;
  Hdr     : Array[0..15] Of Byte;
  Dummy   : LongInt;

{ ==================================================================== }
{ Partie 2 - Services de DOSCALLS                                      }
{ ==================================================================== }

Function DcGetResource(H, IdType, IdName, PPb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosGetResource';
Function DcQueryResourceSize(H, IdType, IdName, PSize : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryResourceSize';
Function DcScanEnv(PName, PValue : LongInt) : LongInt; External 'DOSCALLS' Name 'DosScanEnv';
Function DcOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS' Name 'DosOpen';
Function DcRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRead';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';

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

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

{ Handle d'une instance ; indice d'un handle (-1 : invalide) }
Function HHelp(I : LongInt) : LongInt;
Begin
  HHelp := HelpBase + (IGen[I] Shl 8) + I + 1;
End;

Function InstIdx(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  I := (H And $FF) - 1;
  If ((H And $FFFF0000) = HelpBase) And (I >= 0) And (I < MaxInst) Then
    If IUsed[I] And (HHelp(I) = H) Then R := I;
  InstIdx := R;
End;

{ ==================================================================== }
{ Partie 4 - Tables d'aide                                             }
{ ==================================================================== }

{ Ajouter les elements d'une sous-table (mots : taille, elements) a la
  table en construction ; faux si elle est invalide ou trop grande }
Function AddSub(P : LongInt) : Boolean;
Var Sz, Q, Ok : LongInt;
Begin
  AddSub := False;
  If P = 0 Then Exit;
  Sz := RdW(P);
  If Sz < 2 Then Exit;
  Ok := 1;
  Q := P + 2;
  While (Ok = 1) And (RdW(Q) <> 0) Do
  Begin
    If NSubN >= MaxSub Then Ok := 0
    Else
    Begin
      NWin[NSubN] := RdW(Q);
      NPan[NSubN] := RdW(Q + 2);
      Inc(NSubN);
      Q := Q + Sz * 2;
    End;
  End;
  AddSub := Ok = 1;
End;

{ Table d'aide en memoire (HELPTABLE) -> table en construction }
Function BuildFromMem(P : LongInt) : Boolean;
Var Ok, First : LongInt;
Begin
  NTabN := 0; NSubN := 0;
  Ok := 1;
  If P = 0 Then Ok := 0;
  While (Ok = 1) And (RdW(P) <> 0) Do
  Begin
    If NTabN >= MaxTab Then Ok := 0
    Else
    Begin
      First := NSubN;
      NApp[NTabN] := RdW(P);
      NExt[NTabN] := RdW(P + 6);
      If RdL(P + 2) <> 0 Then
        If Not AddSub(RdL(P + 2)) Then Ok := 0;
      NSubFirst[NTabN] := First;
      NSubCnt[NTabN] := NSubN - First;
      Inc(NTabN);
      P := P + 8;
    End;
  End;
  BuildFromMem := Ok = 1;
End;

{ Table d'aide des ressources du module Hmod (RT_HELPTABLE Id) -> table
  en construction ; rend 0 ou un code HMERR_* }
Function BuildFromRes(Id, Hmod : LongInt) : LongInt;
Var P, Q, R, First, Sz : LongInt;
Begin
  NTabN := 0; NSubN := 0;
  P := 0;
  If DcGetResource(Hmod, RT_HELPTABLE, Id, LongInt(@P)) <> NO_ERROR Then
  Begin
    BuildFromRes := HMERR_HELPTABLE_UNDEFINE;
    Exit;
  End;
  R := NO_ERROR;
  While (R = NO_ERROR) And (RdW(P) <> 0) Do
  Begin
    If NTabN >= MaxTab Then R := HMERR_NO_MEMORY
    Else
    Begin
      First := NSubN;
      NApp[NTabN] := RdW(P);
      NExt[NTabN] := RdW(P + 4);
      If RdW(P + 2) <> 0 Then
      Begin
        Q := 0;
        If DcGetResource(Hmod, RT_HELPSUBTABLE, RdW(P + 2), LongInt(@Q)) <> NO_ERROR Then
          R := HMERR_HELPTABLE_UNDEFINE
        Else If Not AddSub(Q) Then R := HMERR_HELPTABLE_UNDEFINE;
      End;
      NSubFirst[NTabN] := First;
      NSubCnt[NTabN] := NSubN - First;
      Inc(NTabN);
      P := P + 6;
    End;
  End;
  BuildFromRes := R;
End;

{ La table en construction devient celle de l'instance I }
Procedure SetTable(I : LongInt);
Var K, B, S : LongInt;
Begin
  B := I * MaxTab;
  S := I * MaxSub;
  For K := 0 To NTabN - 1 Do
  Begin
    TApp[B + K] := NApp[K];
    TExt[B + K] := NExt[K];
    TSubFirst[B + K] := NSubFirst[K];
    TSubN[B + K] := NSubCnt[K];
  End;
  For K := 0 To NSubN - 1 Do
  Begin
    SWin[S + K] := NWin[K];
    SPan[S + K] := NPan[K];
  End;
  ITabN[I] := NTabN;
  ISubN[I] := NSubN;
End;

{ ==================================================================== }
{ Partie 5 - Bibliotheques d'aide                                      }
{ ==================================================================== }

{ Le fichier existe-t-il ? Rend 0 (bibliotheque IPF : signature HSP),
  HMERR_INVALID_LIB_FILE ou HMERR_OPEN_LIB_FILE }
Function CheckLib(Name : String) : LongInt;
Var H, Act, Got, R : LongInt;
Begin
  PutZ(LongInt(@NameZ), Name);
  H := 0;
  If DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) <> NO_ERROR Then
  Begin
    CheckLib := HMERR_OPEN_LIB_FILE;
    Exit;
  End;
  Got := 0;
  R := DcRead(H, LongInt(@Hdr), 3, LongInt(@Got));
  Dummy := DcClose(H);
  If (R = NO_ERROR) And (Got = 3) And (Hdr[0] = 72) And (Hdr[1] = 83) And (Hdr[2] = 80) Then CheckLib := NO_ERROR
  Else CheckLib := HMERR_INVALID_LIB_FILE;
End;

{ Trouver une bibliotheque : nom tel quel (chemin), repertoire courant,
  repertoires de HELP, C:\ ; Found <- son chemin ; rend 0 ou HMERR_* }
Function FindLib(Name : String; Var Found : String) : LongInt;
Var R, E, K, V : LongInt; Path, D : String;
Begin
  Found := '';
  If Pos('.', Name) = 0 Then Name := Name + '.HLP';
  R := CheckLib(Name);
  If R = NO_ERROR Then Found := UpStr(Name);
  If (R = HMERR_OPEN_LIB_FILE) And (Pos('\', Name) = 0) And (Pos(':', Name) = 0) Then
  Begin
    Path := '';
    PutZ(LongInt(@NameZ), 'HELP');
    V := 0;
    If DcScanEnv(LongInt(@NameZ), LongInt(@V)) = NO_ERROR Then Path := GetZ(V);
    Path := Path + ';C:\';
    While (R = HMERR_OPEN_LIB_FILE) And (Path <> '') Do
    Begin
      K := Pos(';', Path);
      If K = 0 Then
      Begin
        D := Path; Path := '';
      End
      Else
      Begin
        D := Copy(Path, 1, K - 1); Path := Copy(Path, K + 1, 255);
      End;
      If D <> '' Then
      Begin
        If D[Length(D)] <> '\' Then D := D + '\';
        E := CheckLib(D + Name);
        If E <> HMERR_OPEN_LIB_FILE Then
        Begin
          R := E;
          If R = NO_ERROR Then Found := UpStr(D + Name);
        End;
      End;
    End;
  End;
  FindLib := R;
End;

{ Liste de bibliotheques (separees par des espaces) ; Res <- leurs
  chemins (separes par des espaces) ; rend 0 ou le code de la premiere
  bibliotheque introuvable ou invalide }
Function FindLibs(List : String; Var Res : String) : LongInt;
Var R, K : LongInt; N, F : String;
Begin
  Res := '';
  R := NO_ERROR;
  While (R = NO_ERROR) And (List <> '') Do
  Begin
    K := Pos(' ', List);
    If K = 0 Then
    Begin
      N := List; List := '';
    End
    Else
    Begin
      N := Copy(List, 1, K - 1); List := Copy(List, K + 1, 255);
    End;
    If N <> '' Then
    Begin
      R := FindLib(N, F);
      If R = NO_ERROR Then
      Begin
        If Res <> '' Then Res := Res + ' ';
        Res := Res + F;
      End;
    End;
  End;
  FindLibs := R;
End;

{ ==================================================================== }
{ Partie 6 - Fonctions                                                 }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  WINCREATEHELPINSTANCE(hab, phinitHMInit) : creer une instance d'aide
  (HELPINIT) : bibliotheques trouvees et verifiees, table d'aide copiee
  (en memoire, ou ressource FFFFxxxxh du module hmodHelpTableModule) ;
  rend son handle, 0 en cas d'erreur (code dans ulReturnCode) }
Function WinCreateHelpInstance(Hab, PInit : LongInt) : LongInt;
Var I, F, R, Pht : LongInt; Libs : String;
Begin
  WinCreateHelpInstance := 0;
  If PInit = 0 Then Exit;
  If RdL(PInit) < 44 Then
  Begin
    WrL(PInit + 4, HMERR_NO_MEMORY);
    Exit;
  End;
  F := -1;
  For I := MaxInst - 1 DownTo 0 Do
    If Not IUsed[I] Then F := I;
  If F < 0 Then
  Begin
    WrL(PInit + 4, HMERR_NO_MEMORY);
    Exit;
  End;
  { bibliotheques d'aide }
  Libs := '';
  R := FindLibs(GetZ(RdL(PInit + 40)), Libs);
  { table d'aide }
  NTabN := 0; NSubN := 0;
  Pht := RdL(PInit + 12);
  If (R = NO_ERROR) And (Pht <> 0) Then
  Begin
    If ((Pht Shr 16) And $FFFF) = $FFFF Then
    Begin
      R := BuildFromRes(Pht And $FFFF, RdL(PInit + 16));
    End
    Else If Not BuildFromMem(Pht) Then R := HMERR_HELPTABLE_UNDEFINE;
  End;
  WrL(PInit + 4, R);
  If R <> NO_ERROR Then Exit;
  IUsed[F] := True;
  ITitle[F] := Copy(GetZ(RdL(PInit + 32)), 1, 79);
  ITutor[F] := Copy(GetZ(RdL(PInit + 8)), 1, 79);
  ILib[F] := Libs;
  IShowId[F] := RdL(PInit + 36);
  IAccel[F] := RdL(PInit + 24);
  IActBar[F] := RdL(PInit + 28);
  SetTable(F);
  WinCreateHelpInstance := HHelp(F);
End;

{ ---------------------------------------------------------------------
  WINDESTROYHELPINSTANCE(hwndHelpInstance) : detruire l'instance (ses
  associations sont retirees) ; BOOL }
Function WinDestroyHelpInstance(H : LongInt) : LongInt;
Var I, K : LongInt;
Begin
  I := InstIdx(H);
  If I < 0 Then WinDestroyHelpInstance := 0
  Else
  Begin
    For K := 0 To MaxAssoc - 1 Do
      If AInst[K] = H Then
      Begin
        AInst[K] := 0;
        AHwnd[K] := 0;
      End;
    IUsed[I] := False;
    Inc(IGen[I]);
    If IGen[I] > $FF Then IGen[I] := 1;
    ITabN[I] := 0; ISubN[I] := 0;
    WinDestroyHelpInstance := 1;
  End;
End;

{ ---------------------------------------------------------------------
  WINQUERYHELPINSTANCE(hwndApp) : instance d'aide associee a la fenetre
  (0 : aucune) }
Function WinQueryHelpInstance(Hwnd : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := 0;
  If Hwnd <> 0 Then
    For K := 0 To MaxAssoc - 1 Do
      If AHwnd[K] = Hwnd Then R := AInst[K];
  WinQueryHelpInstance := R;
End;

{ ---------------------------------------------------------------------
  WINASSOCIATEHELPINSTANCE(hwndHelpInstance, hwndApp) : associer
  l'instance a la fenetre cadre (hwndHelpInstance = 0 : retirer
  l'association) ; BOOL }
Function WinAssociateHelpInstance(H, Hwnd : LongInt) : LongInt;
Var K, F : LongInt;
Begin
  WinAssociateHelpInstance := 0;
  If Hwnd = 0 Then Exit;
  If H = 0 Then
  Begin
    For K := 0 To MaxAssoc - 1 Do
      If AHwnd[K] = Hwnd Then
      Begin
        AHwnd[K] := 0;
        AInst[K] := 0;
      End;
    WinAssociateHelpInstance := 1;
    Exit;
  End;
  If InstIdx(H) < 0 Then Exit;
  F := -1;
  For K := MaxAssoc - 1 DownTo 0 Do
    If AHwnd[K] = Hwnd Then F := K;
  If F < 0 Then
    For K := MaxAssoc - 1 DownTo 0 Do
      If AHwnd[K] = 0 Then F := K;
  If F < 0 Then Exit;
  AHwnd[F] := Hwnd;
  AInst[F] := H;
  WinAssociateHelpInstance := 1;
End;

{ ---------------------------------------------------------------------
  WINLOADHELPTABLE(hwndHelpInstance, idHelpTable, hmod) : la table d'aide
  idHelpTable des ressources du module hmod (0 : l'executable) remplace
  celle de l'instance ; BOOL }
Function WinLoadHelpTable(H, Id, Hmod : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := InstIdx(H);
  If (I < 0) Or (Id = 0) Then WinLoadHelpTable := 0
  Else If BuildFromRes(Id, Hmod) <> NO_ERROR Then WinLoadHelpTable := 0
  Else
  Begin
    SetTable(I);
    WinLoadHelpTable := 1;
  End;
End;

{ ---------------------------------------------------------------------
  WINCREATEHELPTABLE(hwndHelpInstance, phtHelpTable) : la table d'aide
  en memoire (HELPTABLE, copiee) remplace celle de l'instance ; BOOL }
Function WinCreateHelpTable(H, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := InstIdx(H);
  If (I < 0) Or (P = 0) Then WinCreateHelpTable := 0
  Else If Not BuildFromMem(P) Then WinCreateHelpTable := 0
  Else
  Begin
    SetTable(I);
    WinCreateHelpTable := 1;
  End;
End;

{ ---------------------------------------------------------------------
  HMQUERYPANELID(hwndHelpInstance, idAppWindow, idWindow) (OS/2-0) :
  panneau d'aide de la fenetre idWindow dans la sous-table de
  idAppWindow, sinon son panneau d'aide etendue ; 0 si aucun }
Function HmQueryPanelId(H, IdApp, IdWin : LongInt) : LongInt;
Var I, K, J, B, R : LongInt;
Begin
  R := 0;
  I := InstIdx(H);
  If I >= 0 Then
  Begin
    B := I * MaxTab;
    For K := ITabN[I] - 1 DownTo 0 Do
      If TApp[B + K] = IdApp Then
      Begin
        R := TExt[B + K];
        For J := 0 To TSubN[B + K] - 1 Do
          If SWin[I * MaxSub + TSubFirst[B + K] + J] = IdWin Then R := SPan[I * MaxSub + TSubFirst[B + K] + J];
      End;
  End;
  HmQueryPanelId := R;
End;

{ ---------------------------------------------------------------------
  HMQUERYINSTANCEINFO(hwndHelpInstance, champ, psz, cb) (OS/2-0) :
  1 titre de la fenetre d'aide, 2 bibliotheques trouvees, 3 tutoriel,
  4 nombre d'entrees de la table d'aide (rendu, psz ignore) ; rend la
  longueur de la chaine copiee, -1 si erreur }
Function HmQueryInstanceInfo(H, Field, P, Cb : LongInt) : LongInt;
Var I : LongInt; S : String;
Begin
  HmQueryInstanceInfo := -1;
  I := InstIdx(H);
  If I < 0 Then Exit;
  If Field = 4 Then
  Begin
    HmQueryInstanceInfo := ITabN[I];
    Exit;
  End;
  If Field = 1 Then S := ITitle[I]
  Else If Field = 2 Then S := ILib[I]
  Else If Field = 3 Then S := ITutor[I]
  Else Exit;
  If (P = 0) Or (Cb <= 0) Then Exit;
  If Length(S) > Cb - 1 Then S := Copy(S, 1, Cb - 1);
  PutZ(P, S);
  HmQueryInstanceInfo := Length(S);
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  WinCreateHelpInstance Index 51 Name 'WINCREATEHELPINSTANCE',
  WinDestroyHelpInstance Index 52 Name 'WINDESTROYHELPINSTANCE',
  WinQueryHelpInstance Index 53 Name 'WINQUERYHELPINSTANCE',
  WinAssociateHelpInstance Index 54 Name 'WINASSOCIATEHELPINSTANCE',
  WinLoadHelpTable Index 55 Name 'WINLOADHELPTABLE',
  WinCreateHelpTable Index 56 Name 'WINCREATEHELPTABLE',
  HmQueryPanelId Index 100 Name 'HMQUERYPANELID',
  HmQueryInstanceInfo Index 101 Name 'HMQUERYINSTANCEINFO';

Var
  InitI : LongInt;

BEGIN
  For InitI := 0 To MaxInst - 1 Do
  Begin
    IUsed[InitI] := False;
    IGen[InitI] := 1;
    ITabN[InitI] := 0;
    ISubN[InitI] := 0;
  End;
  For InitI := 0 To MaxAssoc - 1 Do
  Begin
    AHwnd[InitI] := 0;
    AInst[InitI] := 0;
  End;
END.
