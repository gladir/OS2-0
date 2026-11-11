{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 NLS.DLL de OS/2-0 (support des langues
                nationales : pays, pages de codes, majuscules, tri, DBCS).
}

Library NLS;

{$IMAGEBASE $00D40000}
{$R-,S-,I-}

{ Compilation : OS2PC NLS.PAS   (produit NLS.DLL)

  NLS.DLL fournit les informations de langue nationale d'OS/2 : formats
  d'un pays (date, heure, monnaie, separateurs), conversion en
  majuscules, table de tri et vecteur des caracteres a double octet
  (DBCS), selon un code de pays et une page de codes. Les donnees sont
  celles du fichier de pays d'OS/2 (COUNTRY.SYS), integrees a la DLL.

  Fonctions exportees (ordinaux d'origine de NLS.DLL) :
    1 DosCaseMap        convertir une chaine en majuscules (OS/2 1.x)
    2 DosGetCollate     table de tri (OS/2 1.x)
    3 DosGetCtryInfo    informations du pays (OS/2 1.x)
    4 DosGetDBCSEv      vecteur DBCS (OS/2 1.x)
    5 DosQueryCtryInfo  informations du pays
    6 DosQueryDBCSEnv   vecteur DBCS
    7 DosMapCase        convertir une chaine en majuscules
    8 DosQueryCollate   table de tri

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires ; un pointeur vers une taille rendue (pcbActual...) designe
  un LongInt. Les fonctions d'OS/2 1.x (1 a 4) recoivent les structures
  dans leur disposition de 16 bits, les autres dans celle de 32 bits :

    COUNTRYCODE   16 bits : country (2), codepage (2)
                  32 bits : country (4), codepage (4)
                  0 = pays courant, page de codes courante du processus
    COUNTRYINFO   16 bits (38 octets) : country, codepage, fsDateFmt (2
                  chacun), szCurrency[5], szThousandsSeparator[2],
                  szDecimal[2], szDateSeparator[2], szTimeSeparator[2],
                  fsCurrencyFmt, cDecimalPlace, fsTimeFmt (1 chacun),
                  abReserved1 (4), szDataSeparator[2], abReserved2 (10)
                  32 bits (44 octets) : country, codepage, fsDateFmt (4
                  chacun), puis les memes champs, abReserved1 (4),
                  szDataSeparator[2], abReserved2 (10)
    fsDateFmt     0 mois-jour-annee, 1 jour-mois-annee, 2 annee-mois-jour
    fsCurrencyFmt bit 0 : symbole apres le montant ; bit 1 : espace entre
                  les deux ; bit 2 : le symbole remplace le separateur
                  decimal
    fsTimeFmt     0 : 12 heures, 1 : 24 heures
    Table de tri  256 poids (un par octet) : une lettre accentuee a le
                  poids de sa lettre de base, minuscules et majuscules ont
                  le meme poids ; en danois et en norvegien AE, O barre et
                  A rond, en suedois et en finnois A rond, A trema et O
                  trema se trient apres Z
    Vecteur DBCS  paires (premier, dernier) d'octets de tete, terminees
                  par la paire (0, 0)

  Pays (code, pages de codes) : 1 Etats-Unis (437 850), 2 Canada
  francais (863 850), 3 Amerique latine (850 437), 7 Russie (866 850),
  31 Pays-Bas, 32 Belgique, 33 France, 34 Espagne, 39 Italie, 41 Suisse,
  44 Royaume-Uni, 49 Allemagne, 55 Bresil, 358 Finlande (850 437),
  36 Hongrie, 38 Yougoslavie, 42 Tchecoslovaquie, 48 Pologne (852 850),
  45 Danemark, 47 Norvege (865 850), 46 Suede (850 437), 61 anglais
  international (437 850), 81 Japon (932 942 437 850), 82 Coree (949
  437), 86 Chine (936 437), 88 Taiwan (950 437), 90 Turquie (857 850),
  351 Portugal (860 850), 354 Islande (861 850).

  Erreurs : 39 ERROR_NO_COUNTRY_OR_CODEPAGE (pays ou page de codes
  inconnus), 40 ERROR_NLS_TABLE_TRUNCATED (tampon trop petit : les
  donnees qui tiennent sont rendues), 87 ERROR_INVALID_PARAMETER. }

{ ==================================================================== }
{ Constantes, types et variables                                       }
{ ==================================================================== }

Const
  NO_ERROR                     = 0;
  ERROR_NO_COUNTRY_OR_CODEPAGE = 39;
  ERROR_NLS_TABLE_TRUNCATED    = 40;
  ERROR_INVALID_PARAMETER      = 87;

  NCp     = 9;                  { pages de codes a un octet }
  MaxCtry = 32;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  { majuscules et poids de tri des octets 80h a FFh, par page de codes }
  UpTab     : Array[0..NCp * 128 - 1] Of Byte;
  ColTab    : Array[0..NCp * 128 - 1] Of Byte;

  { pays }
  NCtry     : LongInt;
  CCode, CDate, CCurFmt, CDec, CTime : Array[0..MaxCtry - 1] Of LongInt;
  CCur      : Array[0..MaxCtry - 1] Of String[7];
  CThou, CDecSep, CDateSep, CTimeSep, CDataSep : Array[0..MaxCtry - 1] Of String[3];
  CCps      : Array[0..MaxCtry * 4 - 1] Of LongInt;

  Info      : Array[0..63] Of Byte;
  Cc        : Array[0..1] Of LongInt;
  CpBuf     : Array[0..7] Of LongInt;

{ ==================================================================== }
{ Services de DOSCALLS.DLL (pays et page de codes courants)            }
{ ==================================================================== }

Function DcQueryCtryInfo(Cb, Pcc, Pci, PcbActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryCtryInfo';
Function DcQueryCp(Cb, PCp, PcbActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryCp';

{ ==================================================================== }
{ Utilitaires                                                          }
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

Procedure MoveB(Src, Dst, N : LongInt);
Var PS, PD : PByte;
Begin
  If (N <= 0) Or (Src = 0) Or (Dst = 0) Then Exit;
  PS := Pointer(Src);
  PD := Pointer(Dst);
  Move(PS^, PD^, N);
End;

Procedure FillB(Dst, N, V : LongInt);
Var PD : PByte;
Begin
  If (N <= 0) Or (Dst = 0) Then Exit;
  PD := Pointer(Dst);
  FillChar(PD^, N, V);
End;

{ Chaine Pascal -> champ ASCIIZ de Max octets }
Procedure PutField(A : LongInt; S : String; Max : LongInt);
Var I, L : LongInt;
Begin
  FillB(A, Max, 0);
  L := Length(S);
  If L > Max - 1 Then L := Max - 1;
  For I := 1 To L Do WrB(A + I - 1, Ord(S[I]));
End;

Function HexVal(C : Char) : LongInt;
Begin
  If (C >= '0') And (C <= '9') Then HexVal := Ord(C) - 48
  Else HexVal := Ord(UpCase(C)) - 55;
End;

{ Octets ecrits en hexadecimal (S) -> memoire en A }
Procedure HexTo(A : LongInt; S : String);
Var I : LongInt;
Begin
  I := 1;
  While I < Length(S) Do
  Begin
    WrB(A + (I - 1) Div 2, HexVal(S[I]) * 16 + HexVal(S[I + 1]));
    I := I + 2;
  End;
End;

{ ==================================================================== }
{ Pages de codes                                                       }
{ ==================================================================== }

{ Rang d'une page de codes a un octet dans les tables, ou -1 }
Function CpIndex(Cp : LongInt) : LongInt;
Begin
  Case Cp Of
    437 : CpIndex := 0;
    850 : CpIndex := 1;
    852 : CpIndex := 2;
    857 : CpIndex := 3;
    860 : CpIndex := 4;
    861 : CpIndex := 5;
    863 : CpIndex := 6;
    865 : CpIndex := 7;
    866 : CpIndex := 8;
  Else
    CpIndex := -1;
  End;
End;

Function IsDbcsCp(Cp : LongInt) : Boolean;
Begin
  IsDbcsCp := (Cp = 932) Or (Cp = 942) Or (Cp = 936) Or (Cp = 949) Or (Cp = 950);
End;

{ Plages d'octets de tete (paires) ; rend le nombre de paires }
Function DbcsRanges(Cp : LongInt; Var A1, B1, A2, B2 : LongInt) : LongInt;
Begin
  A1 := 0; B1 := 0; A2 := 0; B2 := 0;
  If (Cp = 932) Or (Cp = 942) Then
  Begin
    A1 := $81; B1 := $9F; A2 := $E0; B2 := $FC;
    DbcsRanges := 2;
  End
  Else If IsDbcsCp(Cp) Then
  Begin
    A1 := $81; B1 := $FE;
    DbcsRanges := 1;
  End
  Else
    DbcsRanges := 0;
End;

Function IsLead(Cp, B : LongInt) : Boolean;
Var A1, B1, A2, B2, N : LongInt;
Begin
  N := DbcsRanges(Cp, A1, B1, A2, B2);
  IsLead := ((N >= 1) And (B >= A1) And (B <= B1)) Or ((N >= 2) And (B >= A2) And (B <= B2));
End;

{ ==================================================================== }
{ Pays                                                                 }
{ ==================================================================== }

Procedure AddCtry(Code, DateFmt : LongInt; Cur, Thou, Dc, DSep, TSep : String;
                  CurFmt, Dec, TimeFmt : LongInt; DataSep : String; Cp1, Cp2, Cp3, Cp4 : LongInt);
Var N : LongInt;
Begin
  N := NCtry;
  If N >= MaxCtry Then Exit;
  CCode[N] := Code; CDate[N] := DateFmt; CCur[N] := Cur; CThou[N] := Thou;
  CDecSep[N] := Dc; CDateSep[N] := DSep; CTimeSep[N] := TSep; CCurFmt[N] := CurFmt;
  CDec[N] := Dec; CTime[N] := TimeFmt; CDataSep[N] := DataSep;
  CCps[N * 4] := Cp1; CCps[N * 4 + 1] := Cp2; CCps[N * 4 + 2] := Cp3; CCps[N * 4 + 3] := Cp4;
  Inc(NCtry);
End;

Procedure InitCountries;
Begin
  NCtry := 0;
  AddCtry(1, 0, '$', ',', '.', '-', ':', 0, 2, 0, ',', 437, 850, 0, 0);
  AddCtry(2, 2, '$', ' ', ',', '-', ':', 3, 2, 1, ';', 863, 850, 0, 0);
  AddCtry(3, 1, '$', ',', '.', '/', ':', 0, 2, 0, ',', 850, 437, 0, 0);
  AddCtry(7, 1, 'p.', ' ', ',', '.', ':', 3, 2, 1, ';', 866, 850, 0, 0);
  AddCtry(31, 1, 'EUR', '.', ',', '-', ':', 2, 2, 1, ';', 850, 437, 0, 0);
  AddCtry(32, 1, 'EUR', '.', ',', '/', ':', 3, 2, 1, ';', 850, 437, 0, 0);
  AddCtry(33, 1, 'EUR', ' ', ',', '/', ':', 3, 2, 1, ';', 850, 437, 0, 0);
  AddCtry(34, 1, 'EUR', '.', ',', '/', ':', 3, 2, 1, ';', 850, 437, 0, 0);
  AddCtry(36, 2, 'Ft', ' ', ',', '.', ':', 3, 2, 1, ';', 852, 850, 0, 0);
  AddCtry(38, 1, 'Din', '.', ',', '.', ':', 3, 2, 1, ';', 852, 850, 0, 0);
  AddCtry(39, 1, 'EUR', '.', ',', '/', '.', 2, 2, 1, ';', 850, 437, 0, 0);
  AddCtry(41, 1, 'Fr.', '''', '.', '.', ',', 2, 2, 1, ';', 850, 437, 0, 0);
  AddCtry(42, 1, 'Kc', ' ', ',', '.', ':', 3, 2, 1, ';', 852, 850, 0, 0);
  AddCtry(44, 1, 'L', ',', '.', '/', ':', 0, 2, 1, ',', 850, 437, 0, 0);
  AddCtry(45, 1, 'kr', '.', ',', '-', '.', 2, 2, 1, ';', 865, 850, 0, 0);
  AddCtry(46, 2, 'kr', ' ', ',', '-', '.', 3, 2, 1, ';', 850, 437, 0, 0);
  AddCtry(47, 1, 'kr', ' ', ',', '.', ':', 2, 2, 1, ';', 865, 850, 0, 0);
  AddCtry(48, 2, 'Zl', ' ', ',', '-', ':', 3, 2, 1, ';', 852, 850, 0, 0);
  AddCtry(49, 1, 'EUR', '.', ',', '.', ':', 3, 2, 1, ';', 850, 437, 0, 0);
  AddCtry(55, 1, 'R$', '.', ',', '/', ':', 2, 2, 1, ';', 850, 437, 0, 0);
  AddCtry(61, 1, '$', ',', '.', '-', ':', 0, 2, 0, ',', 437, 850, 0, 0);
  AddCtry(81, 2, 'Y', ',', '.', '-', ':', 0, 0, 1, ',', 932, 942, 437, 850);
  AddCtry(82, 2, 'W', ',', '.', '.', ':', 0, 0, 1, ',', 949, 437, 0, 0);
  AddCtry(86, 2, 'Y', ',', '.', '-', ':', 0, 2, 1, ',', 936, 437, 0, 0);
  AddCtry(88, 2, 'NT$', ',', '.', '/', ':', 0, 2, 1, ',', 950, 437, 0, 0);
  AddCtry(90, 1, 'TL', '.', ',', '/', ':', 1, 2, 1, ';', 857, 850, 0, 0);
  AddCtry(351, 1, 'EUR', '.', ',', '-', ':', 3, 2, 1, ';', 860, 850, 0, 0);
  AddCtry(354, 2, 'kr', '.', ',', '-', ':', 3, 2, 1, ';', 861, 850, 0, 0);
  AddCtry(358, 1, 'EUR', ' ', ',', '.', '.', 3, 2, 1, ';', 850, 437, 0, 0);
End;

Function CtryIndex(Code : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To NCtry - 1 Do
    If CCode[I] = Code Then R := I;
  CtryIndex := R;
End;

Function CpAllowed(Ci, Cp : LongInt) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := False;
  For I := 0 To 3 Do
    If (CCps[Ci * 4 + I] = Cp) And (Cp <> 0) Then R := True;
  CpAllowed := R;
End;

{ Pays et page de codes demandes (0 = courants) -> rang du pays et page
  de codes effective }
Function Resolve(Ctry, Cp : LongInt; Var Ci, CpOut : LongInt) : LongInt;
Var R, N, ExplicitCp : LongInt;
Begin
  R := NO_ERROR;
  If Ctry = 0 Then
  Begin
    Cc[0] := 0; Cc[1] := 0;
    Ctry := 1;
    If DcQueryCtryInfo(44, LongInt(@Cc), LongInt(@Info), LongInt(@N)) = NO_ERROR Then Ctry := RdL(LongInt(@Info));
  End;
  ExplicitCp := Cp;
  If Cp = 0 Then
  Begin
    Cp := 850;
    If DcQueryCp(8, LongInt(@CpBuf), LongInt(@N)) = NO_ERROR Then Cp := CpBuf[0];
  End;
  Ci := CtryIndex(Ctry);
  If Ci < 0 Then R := ERROR_NO_COUNTRY_OR_CODEPAGE
  Else If Not CpAllowed(Ci, Cp) Then
  Begin
    { page courante non preparee pour ce pays : sa premiere page }
    If ExplicitCp = 0 Then Cp := CCps[Ci * 4]
    Else R := ERROR_NO_COUNTRY_OR_CODEPAGE;
  End;
  CpOut := Cp;
  Resolve := R;
End;

{ COUNTRYCODE de 16 ou de 32 bits }
Function ResolveCC(Pcc : LongInt; Wide : Boolean; Var Ci, Cp : LongInt) : LongInt;
Var Ctry, C : LongInt;
Begin
  Ctry := 0; C := 0;
  If Pcc <> 0 Then
  Begin
    If Wide Then
    Begin
      Ctry := RdL(Pcc); C := RdL(Pcc + 4);
    End
    Else
    Begin
      Ctry := RdW(Pcc); C := RdW(Pcc + 2);
    End;
  End;
  ResolveCC := Resolve(Ctry, C, Ci, Cp);
End;

{ Symbole monetaire dans la page de codes }
Function Currency(Ci, Cp : LongInt) : String;
Var S : String;
Begin
  S := CCur[Ci];
  If CCode[Ci] = 44 Then
  Begin
    If (Cp = 437) Or (Cp = 850) Then S := Chr($9C);               { livre sterling }
  End
  Else If CCode[Ci] = 81 Then
  Begin
    If (Cp = 932) Or (Cp = 942) Then S := Chr($5C)                { yen (JIS) }
    Else If Cp = 437 Then S := Chr($9D)
    Else If Cp = 850 Then S := Chr($BE);
  End;
  Currency := S;
End;

{ COUNTRYINFO de 32 bits (44 octets) ou de 16 bits (38 octets) }
Procedure FillInfo(P, Ci, Cp : LongInt; Wide : Boolean);
Var O : LongInt;
Begin
  If Wide Then
  Begin
    FillB(P, 44, 0);
    WrL(P, CCode[Ci]); WrL(P + 4, Cp); WrL(P + 8, CDate[Ci]);
    O := 12;
  End
  Else
  Begin
    FillB(P, 38, 0);
    WrW(P, CCode[Ci]); WrW(P + 2, Cp); WrW(P + 4, CDate[Ci]);
    O := 6;
  End;
  PutField(P + O, Currency(Ci, Cp), 5);
  PutField(P + O + 5, CThou[Ci], 2);
  PutField(P + O + 7, CDecSep[Ci], 2);
  PutField(P + O + 9, CDateSep[Ci], 2);
  PutField(P + O + 11, CTimeSep[Ci], 2);
  WrB(P + O + 13, CCurFmt[Ci]);
  WrB(P + O + 14, CDec[Ci]);
  WrB(P + O + 15, CTime[Ci]);
  PutField(P + O + 20, CDataSep[Ci], 2);
End;

{ Majuscule de l'octet B (pays Ci, page Cp) }
Function UpperOf(Ci, Cp, B : LongInt) : LongInt;
Var X, R : LongInt;
Begin
  R := B;
  If (B >= 97) And (B <= 122) Then
  Begin
    R := B - 32;
    { turc : i pointe -> I pointe (page 857) }
    If (B = 105) And (CCode[Ci] = 90) And (Cp = 857) Then R := $98;
  End
  Else If B >= 128 Then
  Begin
    X := CpIndex(Cp);
    If X >= 0 Then R := UpTab[X * 128 + B - 128];
  End;
  UpperOf := R;
End;

{ Convertir N octets en A (les octets de queue DBCS sont gardes) }
Procedure MapString(Ci, Cp, A, N : LongInt);
Var I, B : LongInt;
Begin
  I := 0;
  While I < N Do
  Begin
    B := RdB(A + I);
    If IsLead(Cp, B) And (I + 1 < N) Then I := I + 2
    Else
    Begin
      WrB(A + I, UpperOf(Ci, Cp, B));
      Inc(I);
    End;
  End;
End;

{ Poids de tri de l'octet B }
Function WeightOf(Ci, Cp, B : LongInt) : LongInt;
Var X, W, C : LongInt;
Begin
  W := B;
  If (B >= 97) And (B <= 122) Then W := B - 32
  Else If (B >= 128) And Not IsDbcsCp(Cp) Then
  Begin
    X := CpIndex(Cp);
    If X >= 0 Then W := ColTab[X * 128 + B - 128];
  End;
  C := CCode[Ci];
  If ((Cp = 850) Or (Cp = 865) Or (Cp = 437) Or (Cp = 861)) And (B >= 128) Then
  Begin
    { lettres scandinaves apres Z }
    If (C = 45) Or (C = 47) Then
    Begin
      If (B = $92) Or (B = $91) Then W := $5B                       { AE }
      Else If ((B = $9D) Or (B = $9B)) And (Cp <> 437) Then W := $5C  { O barre }
      Else If (B = $8F) Or (B = $86) Then W := $5D;                 { A rond }
    End
    Else If (C = 46) Or (C = 358) Then
    Begin
      If (B = $8F) Or (B = $86) Then W := $5B                       { A rond }
      Else If (B = $8E) Or (B = $84) Or (B = $92) Or (B = $91) Then W := $5C  { A trema }
      Else If (B = $99) Or (B = $94) Then W := $5D;                 { O trema }
    End;
  End;
  WeightOf := W;
End;

{ Table de tri : N octets au plus en A ; rend le nombre ecrit }
Function FillCollate(Ci, Cp, A, N : LongInt) : LongInt;
Var I : LongInt;
Begin
  If N > 256 Then N := 256;
  If N < 0 Then N := 0;
  For I := 0 To N - 1 Do WrB(A + I, WeightOf(Ci, Cp, I));
  FillCollate := N;
End;

{ Vecteur DBCS : Cb octets au plus en A ; rend le code d'erreur }
Function FillDbcs(Cp, A, Cb : LongInt) : LongInt;
Var A1, B1, A2, B2, N, I : LongInt;
Begin
  N := DbcsRanges(Cp, A1, B1, A2, B2);
  Info[0] := A1; Info[1] := B1; Info[2] := A2; Info[3] := B2;
  Info[N * 2] := 0; Info[N * 2 + 1] := 0;
  If Cb >= N * 2 + 2 Then
  Begin
    MoveB(LongInt(@Info), A, N * 2 + 2);
    FillDbcs := NO_ERROR;
  End
  Else
  Begin
    For I := 0 To Cb - 1 Do WrB(A + I, Info[I]);
    FillDbcs := ERROR_NLS_TABLE_TRUNCATED;
  End;
End;

{ ==================================================================== }
{ Fonctions exportees                                                  }
{ ==================================================================== }

{ Informations du pays (commun aux formes 16 et 32 bits) }
Function CtryInfo(Cb, Pcc, Pci, PcbActual : LongInt; Wide : Boolean) : LongInt;
Var R, Ci, Cp, Size, N : LongInt;
Begin
  R := ResolveCC(Pcc, Wide, Ci, Cp);
  If (R = NO_ERROR) And (Pci = 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then
  Begin
    If Wide Then Size := 44 Else Size := 38;
    FillInfo(LongInt(@Info), Ci, Cp, Wide);
    N := Size;
    If Cb < N Then N := Cb;
    If N < 0 Then N := 0;
    MoveB(LongInt(@Info), Pci, N);
    WrL(PcbActual, N);
    If N < Size Then R := ERROR_NLS_TABLE_TRUNCATED;
  End;
  CtryInfo := R;
End;

{ ---------------------------------------------------------------------
  DosQueryCtryInfo(cb, pcc, pci, pcbActual) : COUNTRYINFO de 32 bits du
  pays pcc (cb octets au plus ; *pcbActual <- taille rendue) }
Function DosQueryCtryInfo(Cb, Pcc, Pci, PcbActual : LongInt) : LongInt;
Begin
  DosQueryCtryInfo := CtryInfo(Cb, Pcc, Pci, PcbActual, True);
End;

{ ---------------------------------------------------------------------
  DosGetCtryInfo(cbBuf, pctryc, pctryi, pcbCtryInfo) : COUNTRYINFO de 16
  bits (OS/2 1.x) }
Function DosGetCtryInfo(Cb, Pcc, Pci, PcbActual : LongInt) : LongInt;
Begin
  DosGetCtryInfo := CtryInfo(Cb, Pcc, Pci, PcbActual, False);
End;

{ ---------------------------------------------------------------------
  DosMapCase(cb, pcc, pch) : convertir cb octets en majuscules selon le
  pays et la page de codes (lettres accentuees comprises ; les
  caracteres a double octet sont gardes) }
Function DosMapCase(Cb, Pcc, PCh : LongInt) : LongInt;
Var R, Ci, Cp : LongInt;
Begin
  R := ResolveCC(Pcc, True, Ci, Cp);
  If (R = NO_ERROR) And (PCh = 0) And (Cb > 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then MapString(Ci, Cp, PCh, Cb);
  DosMapCase := R;
End;

{ ---------------------------------------------------------------------
  DosCaseMap(usLength, pctryc, pchStr) : comme DosMapCase (COUNTRYCODE
  de 16 bits, OS/2 1.x) }
Function DosCaseMap(Len, Pcc, PCh : LongInt) : LongInt;
Var R, Ci, Cp : LongInt;
Begin
  R := ResolveCC(Pcc, False, Ci, Cp);
  If (R = NO_ERROR) And (PCh = 0) And (Len > 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then MapString(Ci, Cp, PCh, Len);
  DosCaseMap := R;
End;

{ ---------------------------------------------------------------------
  DosQueryCollate(cb, pcc, pch, pcbActual) : table de tri (256 poids ;
  cb octets au plus) }
Function DosQueryCollate(Cb, Pcc, PCh, PcbActual : LongInt) : LongInt;
Var R, Ci, Cp, N : LongInt;
Begin
  R := ResolveCC(Pcc, True, Ci, Cp);
  If (R = NO_ERROR) And (PCh = 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then
  Begin
    N := FillCollate(Ci, Cp, PCh, Cb);
    WrL(PcbActual, N);
    If N < 256 Then R := ERROR_NLS_TABLE_TRUNCATED;
  End;
  DosQueryCollate := R;
End;

{ ---------------------------------------------------------------------
  DosGetCollate(usLength, pctryc, pchBuf, pcbTable) : table de tri
  (COUNTRYCODE de 16 bits, OS/2 1.x) }
Function DosGetCollate(Len, Pcc, PBuf, PcbTable : LongInt) : LongInt;
Var R, Ci, Cp, N : LongInt;
Begin
  R := ResolveCC(Pcc, False, Ci, Cp);
  If (R = NO_ERROR) And (PBuf = 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then
  Begin
    N := FillCollate(Ci, Cp, PBuf, Len);
    WrL(PcbTable, N);
    If N < 256 Then R := ERROR_NLS_TABLE_TRUNCATED;
  End;
  DosGetCollate := R;
End;

{ ---------------------------------------------------------------------
  DosQueryDBCSEnv(cb, pcc, pBuf) : vecteur des octets de tete DBCS de la
  page de codes (paire 0, 0 seule pour une page a un octet) }
Function DosQueryDBCSEnv(Cb, Pcc, PBuf : LongInt) : LongInt;
Var R, Ci, Cp : LongInt;
Begin
  R := ResolveCC(Pcc, True, Ci, Cp);
  If (R = NO_ERROR) And (PBuf = 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then R := FillDbcs(Cp, PBuf, Cb);
  DosQueryDBCSEnv := R;
End;

{ ---------------------------------------------------------------------
  DosGetDBCSEv(cbBuf, pctryc, pchBuf) : vecteur DBCS (COUNTRYCODE de 16
  bits, OS/2 1.x) }
Function DosGetDBCSEv(Cb, Pcc, PBuf : LongInt) : LongInt;
Var R, Ci, Cp : LongInt;
Begin
  R := ResolveCC(Pcc, False, Ci, Cp);
  If (R = NO_ERROR) And (PBuf = 0) Then R := ERROR_INVALID_PARAMETER;
  If R = NO_ERROR Then R := FillDbcs(Cp, PBuf, Cb);
  DosGetDBCSEv := R;
End;

{ ==================================================================== }
{ Tables des pages de codes (generees d'apres les pages de codes :   }
{ majuscule, puis poids de tri, des octets 80h a FFh)                  }
{ ==================================================================== }

Procedure InitTables;
Begin
  { page 437 }
  HexTo(LongInt(@UpTab) + 0 * 128, '809A90418E418F804545454949498E8F9092924F994F555559999A9B9C9D9E9F41494F55A5A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@UpTab) + 0 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E4E6E7E8E9EAEBECE8EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  HexTo(LongInt(@ColTab) + 0 * 128, '435545414141414345454549494941414592924F4F4F5555594F559B9C9D9E9F41494F554E4EA6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@ColTab) + 0 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE053E2E3E4E4E6E7E8E9EAEBECE8EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  { page 850 }
  HexTo(LongInt(@UpTab) + 1 * 128, '809A90B68EB78F80D2D3D4D8D7DE8E8F909292E299E3EAEB59999A9D9C9D9E9FB5D6E0E9A5A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@UpTab) + 1 * 128 + 64, 'C0C1C2C3C4C5C7C7C8C9CACBCCCDCECFD1D1D2D3D449D6D7D8D9DADBDCDDDEDFE0E1E2E3E5E5E6E8E8E9EAEBEDEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  HexTo(LongInt(@ColTab) + 1 * 128, '435545414141414345454549494941414592924F4F4F5555594F559D9C9D9E9F41494F554E4EA6A7A8A9AAABACADAEAFB0B1B2B3B4414141B8B9BABBBCBDBEBF');
  HexTo(LongInt(@ColTab) + 1 * 128 + 64, 'C0C1C2C3C4C54141C8C9CACBCCCDCECFD1D145454549494949D9DADBDCDD49DF4F534F4F4F4FE6E8E85555555959EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  { page 852 }
  HexTo(LongInt(@UpTab) + 2 * 128, '809A90B68EDE8F809DD38A8AD78D8E8F909191E29995959797999A9B9B9D9EACB5D6E0E9A4A4A6A6A8A8AA8DACB8AEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBDBF');
  HexTo(LongInt(@UpTab) + 2 * 128 + 64, 'C0C1C2C3C4C5C6C6C8C9CACBCCCDCECFD1D1D2D3D2D5D6D7B7D9DADBDCDDDEDFE0E1E2E3E3D5E6E6E8E9E8EBEDEDDDEFF0F1F2F3F4F5F6F7F8F9FAEBFCFCFEFF');
  HexTo(LongInt(@ColTab) + 2 * 128, '43554541415543439D454F4F495A4143454C4C4F4F4C4C53534F5554549D9E4341494F5541415A5A4545AA5A4353AEAFB0B1B2B3B441414553B9BABBBC5A5ABF');
  HexTo(LongInt(@ColTab) + 2 * 128 + 64, 'C0C1C2C3C4C54141C8C9CACBCCCDCECFD1D14445444E494945D9DADBDC5455DF4F534F4E4E4E535352555255595954EFF0F1F2F3F4F5F6F7F8F9FA555252FEFF');
  { page 857 }
  HexTo(LongInt(@UpTab) + 3 * 128, '809A90B68EB78F80D2D3D4D8D7498E8F909292E299E3EAEB98999A9D9C9D9E9EB5D6E0E9A5A5A6A6A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@UpTab) + 3 * 128 + 64, 'C0C1C2C3C4C5C7C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E5E5E6E7E8E9EAEBDE59EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  HexTo(LongInt(@ColTab) + 3 * 128, '435545414141414345454549494941414592924F4F4F5555494F559D9C9D535341494F554E4E4747A8A9AAABACADAEAFB0B1B2B3B4414141B8B9BABBBCBDBEBF');
  HexTo(LongInt(@ColTab) + 3 * 128 + 64, 'C0C1C2C3C4C54141C8C9CACBCCCDCECFD0D1454545D5494949D9DADBDCDD49DF4F534F4F4F4FE6E7E85555554959EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  { page 860 }
  HexTo(LongInt(@UpTab) + 4 * 128, '809A908F8E9186808989928B8C988E8F9091928C99A9969D98999A9B9C9D9E9F868B9F96A5A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@UpTab) + 4 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E4E6E7E8E9EAEBECE8EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  HexTo(LongInt(@ColTab) + 4 * 128, '4355454141414143454545494F4941414541454F4F4F5555494F559B9C559E4F41494F554E4EA6A7A84FAAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@ColTab) + 4 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE053E2E3E4E4E6E7E8E9EAEBECE8EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  { page 861 }
  HexTo(LongInt(@UpTab) + 5 * 128, '809A90418E418F804545458B8B8D8E8F9092924F998D559797999A9D9C9D9E9FA4A5A6A7A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@UpTab) + 5 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E4E6E7E8E9EAEBECE8EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  HexTo(LongInt(@ColTab) + 5 * 128, '43554541414141434545458B8B8D41414592924F4F8D5559594F559D9C9D9E9F41494F5541494F55A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@ColTab) + 5 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE053E2E3E4E4E6E7E8E9EAEBECE8EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  { page 863 }
  HexTo(LongInt(@UpTab) + 6 * 128, '809A9084848E868092949195A88D8E8F9091929994959E9D98999A9B9C9D9E9FA0A14F55A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@UpTab) + 6 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E4E6E7E8E9EAEBECE8EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  HexTo(LongInt(@ColTab) + 6 * 128, '435545414141864345454549498D418F4545454F45495555984F559B9C55559FA0A14F55A4A5A6A749A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@ColTab) + 6 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE053E2E3E4E4E6E7E8E9EAEBECE8EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  { page 865 }
  HexTo(LongInt(@UpTab) + 7 * 128, '809A90418E418F804545454949498E8F9092924F994F555559999A9D9C9D9E9F41494F55A5A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@UpTab) + 7 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E4E6E7E8E9EAEBECE8EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  HexTo(LongInt(@ColTab) + 7 * 128, '435545414141414345454549494941414592924F4F4F5555594F559D9C9D9E9F41494F554E4EA6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@ColTab) + 7 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE053E2E3E4E4E6E7E8E9EAEBECE8EEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF');
  { page 866 }
  HexTo(LongInt(@UpTab) + 8 * 128, '808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9F808182838485868788898A8B8C8D8E8FB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@UpTab) + 8 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDF909192939495969798999A9B9C9D9E9FF0F0F2F2F4F4F6F6F8F9FAFBFCFDFEFF');
  HexTo(LongInt(@ColTab) + 8 * 128, '808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9F808182838485868788898A8B8C8D8E8FB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF');
  HexTo(LongInt(@ColTab) + 8 * 128 + 64, 'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDF909192939495969798999A9B9C9D9E9FF0F0F2F2F4F4F6F6F8F9FAFBFCFDFEFF');
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  DosCaseMap Index 1, DosGetCollate Index 2, DosGetCtryInfo Index 3,
  DosGetDBCSEv Index 4, DosQueryCtryInfo Index 5, DosQueryDBCSEnv Index 6,
  DosMapCase Index 7, DosQueryCollate Index 8;

BEGIN
  InitTables;
  InitCountries;
END.
