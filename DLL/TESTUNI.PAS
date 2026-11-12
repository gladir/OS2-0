{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de LIBUNI.DLL sous OS/2-0.
}

Program TESTUNI;

{$R-,S-,I-}

{ Compilation : OS2PC TESTUNI.PAS   (produit TESTUNI.EXE)

  TESTUNI verifie les 78 points d'entree de LIBUNI.DLL : objets locales,
  elements, attributs et types des caracteres, majuscules, chaines,
  collation, transformations, nombres, dates, montants, locales de
  l'utilisateur et noms des langues et des pays. }

Function UniQueryXdigit(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQuerySpace(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryPrint(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryGraph(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryCntrl(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryAlpha(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniFreeAttrObject(H : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryCharAttr(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryUpper(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryPunct(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryLower(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryDigit(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryBlank(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryAlnum(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniScanForAttr(H, P, N, Inv, POfs : LongInt) : LongInt; External 'LIBUNI';
Function UniCreateAttrObject(H, PName, PAo : LongInt) : LongInt; External 'LIBUNI';
Function UniCreateTransformObject(H, PType, PXo : LongInt) : LongInt; External 'LIBUNI';
Function UniFreeTransformObject(H : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryLocaleObject(H, Cat, Typ, PP : LongInt) : LongInt; External 'LIBUNI';
Function UniCreateLocaleObject(Typ, Spec, PLo : LongInt) : LongInt; External 'LIBUNI';
Function UniFreeLocaleObject(H : LongInt) : LongInt; External 'LIBUNI';
Function UniFreeMem(P : LongInt) : LongInt; External 'LIBUNI';
Function UniFreeLocaleInfo(P : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryLocaleInfo(H, PP : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryLocaleItem(H, Item, PP : LongInt) : LongInt; External 'LIBUNI';
Function UniStrcat(D, S : LongInt) : LongInt; External 'LIBUNI';
Function UniStrchr(S, C : LongInt) : LongInt; External 'LIBUNI';
Function UniStrcmp(A, B : LongInt) : LongInt; External 'LIBUNI';
Function UniStrcmpi(H, A, B : LongInt) : LongInt; External 'LIBUNI';
Function UniStrcoll(H, A, B : LongInt) : LongInt; External 'LIBUNI';
Function UniStrcpy(D, S : LongInt) : LongInt; External 'LIBUNI';
Function UniStrcspn(A, B : LongInt) : LongInt; External 'LIBUNI';
Function UniStrfmon(H, Buf, Max, Fmt, A0, A1, A2, A3 : LongInt) : LongInt; External 'LIBUNI';
Function UniStrftime(H, Buf, Max, Fmt, PTm : LongInt) : LongInt; External 'LIBUNI';
Function UniStrlen(S : LongInt) : LongInt; External 'LIBUNI';
Function UniStrncat(D, S, N : LongInt) : LongInt; External 'LIBUNI';
Function UniStrncmp(A, B, N : LongInt) : LongInt; External 'LIBUNI';
Function UniStrncmpi(H, A, B, N : LongInt) : LongInt; External 'LIBUNI';
Function UniStrncpy(D, S, N : LongInt) : LongInt; External 'LIBUNI';
Function UniStrpbrk(A, B : LongInt) : LongInt; External 'LIBUNI';
Function UniStrptime(H, Buf, Fmt, PTm : LongInt) : LongInt; External 'LIBUNI';
Function UniStrrchr(S, C : LongInt) : LongInt; External 'LIBUNI';
Function UniStrspn(A, B : LongInt) : LongInt; External 'LIBUNI';
Function UniStrstr(A, B : LongInt) : LongInt; External 'LIBUNI';
Function UniStrtod(H, P, PEnd, PRes : LongInt) : LongInt; External 'LIBUNI';
Function UniStrtol(H, P, PEnd, Base, PRes : LongInt) : LongInt; External 'LIBUNI';
Function UniStrtoul(H, P, PEnd, Base, PRes : LongInt) : LongInt; External 'LIBUNI';
Function UniStrxfrm(H, D, S, N : LongInt) : LongInt; External 'LIBUNI';
Function UniLocaleStrToToken(Typ, P, PTok : LongInt) : LongInt; External 'LIBUNI';
Function UniLocaleTokenToStr(Tok, Typ, PP : LongInt) : LongInt; External 'LIBUNI';
Function UniTransformStr(H, PIn, PInN, POut, POutN : LongInt) : LongInt; External 'LIBUNI';
Function UniTransLower(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniTransUpper(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniTolower(C : LongInt) : LongInt; External 'LIBUNI';
Function UniToupper(C : LongInt) : LongInt; External 'LIBUNI';
Function UniStrupr(S : LongInt) : LongInt; External 'LIBUNI';
Function UniStrlwr(S : LongInt) : LongInt; External 'LIBUNI';
Function UniStrtok(A, B : LongInt) : LongInt; External 'LIBUNI';
Function UniMapCtryToLocale(Code, Buf, N : LongInt) : LongInt; External 'LIBUNI';
Function UniMakeKey(H, S, D, N : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryChar(C, M : LongInt) : LongInt; External 'LIBUNI';
Function UniGetOverride(PName, Item, PP : LongInt) : LongInt; External 'LIBUNI';
Function UniGetColval(H, C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryAttr(PName : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryStringType(P, N, POut, Kind : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryCharType(C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryNumericValue(C : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryCharTypeTable(PCount, PPtr : LongInt) : LongInt; External 'LIBUNI';
Function UniProcessUconv(H, PMbs, PUcs, N : LongInt) : LongInt; External 'LIBUNI';
Function Locale(Cat, PName : LongInt) : LongInt; External 'LIBUNI';
Function UniMakeUserLocale(PName, PBase : LongInt) : LongInt; External 'LIBUNI';
Function UniSetUserLocaleItem(PName, Item, Typ, Value : LongInt) : LongInt; External 'LIBUNI';
Function UniDeleteUserLocale(PName : LongInt) : LongInt; External 'LIBUNI';
Function UniCompleteUserLocale : LongInt; External 'LIBUNI';
Function UniQueryLocaleValue(H, Item, PInt : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryLocaleList(Flags, Buf, N : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryLanguageName(PLang, PIso, PP : LongInt) : LongInt; External 'LIBUNI';
Function UniQueryCountryName(PCtry, PIso, PP : LongInt) : LongInt; External 'LIBUNI';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';

Const
  ULS_INVALID     = 14;
  ULS_BADOBJECT   = 15;
  ULS_NOTOKEN     = 16;
  ULS_NOMATCH     = 17;
  ULS_BUFFERFULL  = 18;
  ULS_RANGE       = 19;
  ULS_UNSUPPORTED = 20;
  UCS = 3;
  MBS = 2;
  TOK = 1;
  LC_ALL = -1;
  LC_TIME = 4;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, C, P, Q, T : LongInt;
  LoFR, LoUS, LoDE, LoC, LoIT, Lo, Ao, Xo, InN, OutN : LongInt;
  Name : Array[0..127] Of Byte;
  UB : Array[0..4095] Of Word;          { chaines UniChar (8 x 512) }
  UBi : LongInt;
  Buf, Buf2, Key1, Key2, Key3 : Array[0..255] Of Word;
  Tm : Array[0..8] Of LongInt;
  DRes, DD, GV1, GV2 : Double;
  RBuf : Array[0..8191] Of Byte;
  Bytes : Array[0..15] Of Byte;
  Txt : String;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
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

Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(LongInt(@Name) + K - 1, Ord(S[K]));
  WrB(LongInt(@Name) + Length(S), 0);
  Z := LongInt(@Name);
End;

{ Chaine UniChar (latin-1, 80h = euro) dans le tampon tournant }
Function U(S : String) : LongInt;
Var A, K, C : LongInt;
Begin
  A := LongInt(@UB) + (UBi Mod 8) * 1024;
  Inc(UBi);
  For K := 1 To Length(S) Do
  Begin
    C := Ord(S[K]);
    If C = $80 Then C := $20AC;
    WrW(A + (K - 1) * 2, C);
  End;
  WrW(A + Length(S) * 2, 0);
  U := A;
End;

{ Chaine UniChar de mots donnes (W1..W4, 0 = fin) }
Function UW(W1, W2, W3, W4 : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := LongInt(@UB) + (UBi Mod 8) * 1024;
  Inc(UBi);
  WrW(A, W1); WrW(A + 2, W2); WrW(A + 4, W3); WrW(A + 6, W4); WrW(A + 8, 0);
  UW := A;
End;

{ La chaine UniChar en A vaut-elle S ? }
Function UEq(A : LongInt; S : String) : Boolean;
Var K, C : LongInt; Ok : Boolean;
Begin
  Ok := A <> 0;
  K := 1;
  While Ok And (K <= Length(S)) Do
  Begin
    C := Ord(S[K]);
    If C = $80 Then C := $20AC;
    If RdW(A + (K - 1) * 2) <> C Then Ok := False;
    Inc(K);
  End;
  If Ok Then Ok := RdW(A + Length(S) * 2) = 0;
  UEq := Ok;
End;

{ Element UniChar d'un objet locale ; la memoire est liberee }
Function ItemIs(Lo, Item : LongInt; S : String) : Boolean;
Var P, D : LongInt; Ok : Boolean;
Begin
  P := 0;
  Ok := (UniQueryLocaleItem(Lo, Item, LongInt(@P)) = 0) And UEq(P, S);
  If P <> 0 Then D := UniFreeMem(P);
  ItemIs := Ok;
End;

Function ValOf(Lo, Item : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := -12345;
  If UniQueryLocaleValue(Lo, Item, LongInt(@V)) <> 0 Then V := -12345;
  ValOf := V;
End;

{ Nom (LC_ALL, UniChar) d'un objet locale }
Function LocName(Lo : LongInt; S : String) : Boolean;
Var P, D : LongInt; Ok : Boolean;
Begin
  P := 0;
  Ok := (UniQueryLocaleObject(Lo, LC_ALL, UCS, LongInt(@P)) = 0) And UEq(P, S);
  If P <> 0 Then D := UniFreeMem(P);
  LocName := Ok;
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

{ Montants GV1, GV2 }
Function Fmon(Lo : LongInt; F : String) : String;
Var Lo1, Hi1, Lo2, Hi2, K, N : LongInt; S : String;
Begin
  Lo1 := RdL(LongInt(@GV1)); Hi1 := RdL(LongInt(@GV1) + 4);
  Lo2 := RdL(LongInt(@GV2)); Hi2 := RdL(LongInt(@GV2) + 4);
  N := UniStrfmon(Lo, LongInt(@Buf), 64, U(F), Lo1, Hi1, Lo2, Hi2);
  S := '';
  If N >= 0 Then
    For K := 0 To N - 1 Do
      If Buf[K] = $20AC Then S := S + Chr($80) Else If Buf[K] < 256 Then S := S + Chr(Buf[K]) Else S := S + '?';
  Fmon := S;
End;

Function Ftime(Lo : LongInt; F : String) : String;
Var K, N : LongInt; S : String;
Begin
  N := UniStrftime(Lo, LongInt(@Buf), 64, U(F), LongInt(@Tm));
  S := '';
  For K := 0 To N - 1 Do
    If Buf[K] < 256 Then S := S + Chr(Buf[K]) Else S := S + '?';
  Ftime := S;
End;

Procedure SetTm;
Begin
  Tm[0] := 9; Tm[1] := 5; Tm[2] := 14; Tm[3] := 12; Tm[4] := 10; Tm[5] := 126;
  Tm[6] := 4; Tm[7] := 315; Tm[8] := 0;
End;

{ Le fichier F contient-il le texte S ? }
Function FileHas(F, S : String) : Boolean;
Var Hf, Act, Got, D, K, J : LongInt; Found, Same : Boolean;
Begin
  Got := 0;
  If DosOpen(Z(F), LongInt(@Hf), LongInt(@Act), 0, 0, 1, $40, 0) = 0 Then
  Begin
    D := DosRead(Hf, LongInt(@RBuf), 8000, LongInt(@Got));
    D := DosClose(Hf);
  End;
  Found := False;
  For K := 0 To Got - Length(S) Do
    If Not Found Then
    Begin
      Same := True;
      For J := 1 To Length(S) Do
        If RBuf[K + J - 1] <> Ord(S[J]) Then Same := False;
      If Same Then Found := True;
    End;
  FileHas := Found;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0; UBi := 0;
  WriteLn('TESTUNI : essai de LIBUNI.DLL');

  { --- module, ordinaux --- }
  R := DosQueryModuleHandle(Z('LIBUNI'), LongInt(@H));
  Check('DosQueryModuleHandle LIBUNI', R = 0);
  Check('ordinaux 1 a 22', OrdIs(1, 'UniQueryXdigit') And OrdIs(2, 'UniQuerySpace') And OrdIs(3, 'UniQueryPrint') And
        OrdIs(4, 'UniQueryGraph') And OrdIs(5, 'UniQueryCntrl') And OrdIs(6, 'UniQueryAlpha') And
        OrdIs(7, 'UniFreeAttrObject') And OrdIs(8, 'UniQueryCharAttr') And OrdIs(9, 'UniQueryUpper') And
        OrdIs(10, 'UniQueryPunct') And OrdIs(11, 'UniQueryLower') And OrdIs(12, 'UniQueryDigit') And
        OrdIs(13, 'UniQueryBlank') And OrdIs(14, 'UniQueryAlnum') And OrdIs(15, 'UniScanForAttr') And
        OrdIs(16, 'UniCreateAttrObject') And OrdIs(17, 'UniCreateTransformObject') And
        OrdIs(18, 'UniFreeTransformObject') And OrdIs(19, 'UniQueryLocaleObject') And
        OrdIs(20, 'UniCreateLocaleObject') And OrdIs(21, 'UniFreeLocaleObject') And OrdIs(22, 'UniFreeMem'));
  Check('ordinaux 28 a 46', OrdIs(28, 'UniFreeLocaleInfo') And OrdIs(29, 'UniQueryLocaleInfo') And
        OrdIs(30, 'UniQueryLocaleItem') And OrdIs(31, 'UniStrcat') And OrdIs(32, 'UniStrchr') And
        OrdIs(33, 'UniStrcmp') And OrdIs(34, 'UniStrcmpi') And OrdIs(35, 'UniStrcoll') And OrdIs(36, 'UniStrcpy') And
        OrdIs(37, 'UniStrcspn') And OrdIs(38, 'UniStrfmon') And OrdIs(39, 'UniStrftime') And OrdIs(40, 'UniStrlen') And
        OrdIs(41, 'UniStrncat') And OrdIs(42, 'UniStrncmp') And OrdIs(43, 'UniStrncmpi') And
        OrdIs(44, 'UniStrncpy') And OrdIs(45, 'UniStrpbrk') And OrdIs(46, 'UniStrptime'));
  Check('ordinaux 47 a 67', OrdIs(47, 'UniStrrchr') And OrdIs(48, 'UniStrspn') And OrdIs(49, 'UniStrstr') And
        OrdIs(50, 'UniStrtod') And OrdIs(51, 'UniStrtol') And OrdIs(52, 'UniStrtoul') And OrdIs(53, 'UniStrxfrm') And
        OrdIs(54, 'UniLocaleStrToToken') And OrdIs(55, 'UniLocaleTokenToStr') And OrdIs(56, 'UniTransformStr') And
        OrdIs(57, 'UniTransLower') And OrdIs(58, 'UniTransUpper') And OrdIs(59, 'UniTolower') And
        OrdIs(60, 'UniToupper') And OrdIs(61, 'UniStrupr') And OrdIs(62, 'UniStrlwr') And OrdIs(63, 'UniStrtok') And
        OrdIs(67, 'UniMapCtryToLocale'));
  Check('ordinaux 70 a 80 et 151 a 159', OrdIs(70, 'UniMakeKey') And OrdIs(71, 'UniQueryChar') And
        OrdIs(72, 'UniGetOverride') And OrdIs(73, 'UniGetColval') And OrdIs(74, 'UniQueryAttr') And
        OrdIs(75, 'UniQueryStringType') And OrdIs(76, 'UniQueryCharType') And OrdIs(77, 'UniQueryNumericValue') And
        OrdIs(78, 'UniQueryCharTypeTable') And OrdIs(80, 'UniProcessUconv') And OrdIs(151, 'Locale') And
        OrdIs(152, 'UniMakeUserLocale') And OrdIs(153, 'UniSetUserLocaleItem') And OrdIs(154, 'UniDeleteUserLocale') And
        OrdIs(155, 'UniCompleteUserLocale') And OrdIs(156, 'UniQueryLocaleValue') And OrdIs(157, 'UniQueryLocaleList') And
        OrdIs(158, 'UniQueryLanguageName') And OrdIs(159, 'UniQueryCountryName'));
  Check('ordinaux 23, 64 et 79 inexistants', (DosQueryProcAddr(H, 23, 0, LongInt(@A)) <> 0) And
        (DosQueryProcAddr(H, 64, 0, LongInt(@A)) <> 0) And (DosQueryProcAddr(H, 79, 0, LongInt(@A)) <> 0));

  { --- objets locales --- }
  R := UniCreateLocaleObject(UCS, U('fr_FR'), LongInt(@LoFR));
  R2 := UniCreateLocaleObject(MBS, Z('en_US'), LongInt(@LoUS));
  A := UniCreateLocaleObject(UCS, U('de_DE.IBM-850'), LongInt(@LoDE));
  B := UniCreateLocaleObject(UCS, 0, LongInt(@LoC));
  C := UniCreateLocaleObject(UCS, U('it'), LongInt(@LoIT));
  Check('UniCreateLocaleObject fr_FR, en_US (MBS), de_DE.IBM-850, nul (C), it', (R = 0) And (R2 = 0) And (A = 0) And
        (B = 0) And (C = 0) And (LoFR <> 0) And (LoFR <> LoUS));
  Check('UniQueryLocaleObject : noms', LocName(LoFR, 'fr_FR') And LocName(LoUS, 'en_US') And LocName(LoDE, 'de_DE') And
        LocName(LoC, 'C') And LocName(LoIT, 'it_IT'));
  P := 0;
  R := UniQueryLocaleObject(LoFR, 2, MBS, LongInt(@P));
  Txt := '';
  If P <> 0 Then For I := 0 To 4 Do Txt := Txt + Chr(RdB(P + I));
  A := UniFreeMem(P);
  B := UniFreeMem(P);
  Check('UniQueryLocaleObject MBS, UniFreeMem, puis memoire deja liberee refusee', (R = 0) And (Txt = 'fr_FR') And
        (A = 0) And (B = ULS_BADOBJECT));
  R := UniCreateLocaleObject(UCS, U('xx_YY'), LongInt(@Lo));
  R2 := UniCreateLocaleObject(9, U('fr_FR'), LongInt(@Lo));
  Check('locale inconnue (ULS_UNSUPPORTED), type invalide (ULS_INVALID)', (R = ULS_UNSUPPORTED) And (R2 = ULS_INVALID));
  R := UniCreateLocaleObject(UCS, U('en-GB'), LongInt(@Lo));
  Check('nom avec tiret : en-GB', (R = 0) And LocName(Lo, 'en_GB'));
  A := UniFreeLocaleObject(Lo);
  B := UniFreeLocaleObject(Lo);
  Check('UniFreeLocaleObject, puis objet libere refuse', (A = 0) And (B = ULS_BADOBJECT));
  R := UniCreateLocaleObject(UCS, U(''), LongInt(@Lo));
  Check('nom vide : locale par defaut en_US', (R = 0) And LocName(Lo, 'en_US'));
  A := UniFreeLocaleObject(Lo);
  { Locale rend un tampon statique (comme setlocale) }
  P := Locale(LC_ALL, U('de_DE'));
  B := 0;
  If UEq(P, 'de_DE') Then B := 1;
  Q := Locale(LC_TIME, U('fr'));
  R := UniCreateLocaleObject(UCS, U(''), LongInt(@Lo));
  Check('Locale : LC_ALL de_DE, LC_TIME fr_FR', (B = 1) And UEq(Q, 'fr_FR') And (R = 0) And
        LocName(Lo, 'LC_COLLATE=de_DE;LC_CTYPE=de_DE;LC_NUMERIC=de_DE;LC_MONETARY=de_DE;LC_TIME=fr_FR;LC_MESSAGES=de_DE'));
  A := UniFreeLocaleObject(Lo);
  P := Locale(LC_ALL, U(''));
  Q := Locale(LC_ALL, U('zz_ZZ'));
  Check('Locale : retour aux defauts (en_US), locale inconnue (0)', UEq(P, 'en_US') And (Q = 0));

  { --- jetons --- }
  T := 0;
  R := UniLocaleStrToToken(UCS, U('fr_FR'), LongInt(@T));
  P := 0;
  R2 := UniLocaleTokenToStr(T, UCS, LongInt(@P));
  Check('UniLocaleStrToToken, UniLocaleTokenToStr', (R = 0) And (T <> 0) And (R2 = 0) And UEq(P, 'fr_FR'));
  A := UniFreeMem(P);
  R := UniCreateLocaleObject(TOK, LongInt(@T), LongInt(@Lo));
  Check('UniCreateLocaleObject par jeton', (R = 0) And LocName(Lo, 'fr_FR'));
  A := UniFreeLocaleObject(Lo);
  R := UniLocaleTokenToStr(999, UCS, LongInt(@P));
  R2 := UniLocaleStrToToken(UCS, U('xx'), LongInt(@T));
  Check('jeton inconnu (ULS_NOTOKEN), locale inconnue (ULS_UNSUPPORTED)', (R = ULS_NOTOKEN) And (R2 = ULS_UNSUPPORTED));

  { --- elements --- }
  Check('elements fr_FR : mois, jours', ItemIs(LoFR, 32, 'janvier') And ItemIs(LoFR, 33, 'f' + Chr($E9) + 'vrier') And
        ItemIs(LoFR, 13, 'dimanche') And ItemIs(LoFR, 7, 'lun.') And ItemIs(LoFR, 31, 'd' + Chr($E9) + 'c.'));
  Check('elements fr_FR : nombres, monnaie, formats', ItemIs(LoFR, 44, ',') And ItemIs(LoFR, 45, ' ') And
        ItemIs(LoFR, 48, Chr($80)) And ItemIs(LoFR, 87, 'EUR ') And ItemIs(LoFR, 2, '%d/%m/%Y') And ItemIs(LoFR, 46, 'oui'));
  Check('elements fr_FR : noms', ItemIs(LoFR, 100, 'fr_FR') And ItemIs(LoFR, 103, 'French') And
        ItemIs(LoFR, 104, 'fran' + Chr($E7) + 'ais') And ItemIs(LoFR, 106, 'France') And ItemIs(LoFR, 101, 'fr'));
  Check('elements de_DE et en_US', ItemIs(LoDE, 34, 'M' + Chr($E4) + 'rz') And ItemIs(LoDE, 2, '%d.%m.%Y') And
        ItemIs(LoUS, 3, '%I:%M:%S %p') And ItemIs(LoUS, 106, 'United States') And ItemIs(LoUS, 51, '0409'));
  Check('UniQueryLocaleValue : iCountry, iCodepage, xWinLocale, iMeasure', (ValOf(LoFR, 108) = 33) And
        (ValOf(LoFR, 111) = 850) And (ValOf(LoFR, 51) = $040C) And (ValOf(LoUS, 70) = 2) And (ValOf(LoFR, 70) = 1));
  R := UniQueryLocaleValue(LoFR, 44, LongInt(@A));
  R2 := UniQueryLocaleItem(LoFR, 999, LongInt(@P));
  A := UniQueryLocaleItem(12345, 44, LongInt(@P));
  Check('element chaine par UniQueryLocaleValue, element inconnu, objet invalide refuses', (R = ULS_INVALID) And
        (R2 = ULS_INVALID) And (A = ULS_BADOBJECT));
  P := 0;
  R := UniQueryLocaleInfo(LoFR, LongInt(@P));
  Check('UniQueryLocaleInfo fr_FR', (R = 0) And UEq(RdL(P), ',') And UEq(RdL(P + 4), ' ') And (RdW(RdL(P + 8)) = 3) And
        (RdW(RdL(P + 8) + 2) = 0) And UEq(RdL(P + 12), 'EUR ') And UEq(RdL(P + 16), Chr($80)) And
        (RdW(P + 42) = 2) And (RdW(P + 44) = 0) And (RdW(P + 46) = 1) And UEq(RdL(P + 36), '-') And UEq(RdL(P + 68), '('));
  A := UniFreeLocaleInfo(P);
  Check('UniFreeLocaleInfo', A = 0);
  R := UniMapCtryToLocale(33, LongInt(@Buf), 16);
  R2 := UniMapCtryToLocale(2, LongInt(@Buf2), 16);
  A := UniMapCtryToLocale(999, LongInt(@Buf2), 16);
  B := UniMapCtryToLocale(1, LongInt(@Key1), 3);
  Check('UniMapCtryToLocale 33, 2 ; pays inconnu ; tampon trop petit', (R = 0) And UEq(LongInt(@Buf), 'fr_FR') And
        (R2 = 0) And UEq(LongInt(@Buf2), 'fr_CA') And (A = ULS_INVALID) And (B = ULS_BUFFERFULL));

  { --- attributs --- }
  Check('UniQueryAlpha (A, 1, e accent aigu, 4E00h)', (UniQueryAlpha(LoFR, 65) = 1) And (UniQueryAlpha(LoFR, 49) = 0) And
        (UniQueryAlpha(LoFR, $E9) = 1) And (UniQueryAlpha(LoFR, $4E00) = 1));
  Check('UniQueryDigit, UniQueryXdigit, UniQueryAlnum', (UniQueryDigit(LoFR, 55) = 1) And (UniQueryDigit(LoFR, $0663) = 1) And
        (UniQueryDigit(LoFR, 65) = 0) And (UniQueryXdigit(LoFR, 102) = 1) And (UniQueryXdigit(LoFR, 103) = 0) And
        (UniQueryAlnum(LoFR, 53) = 1) And (UniQueryAlnum(LoFR, 95) = 0));
  Check('UniQuerySpace, UniQueryBlank, UniQueryCntrl', (UniQuerySpace(LoFR, 32) = 1) And (UniQuerySpace(LoFR, $3000) = 1) And
        (UniQuerySpace(LoFR, 97) = 0) And (UniQueryBlank(LoFR, 9) = 1) And (UniQueryBlank(LoFR, 10) = 0) And
        (UniQueryCntrl(LoFR, 7) = 1) And (UniQueryCntrl(LoFR, 65) = 0));
  Check('UniQueryPrint, UniQueryGraph, UniQueryPunct', (UniQueryPrint(LoFR, 32) = 1) And (UniQueryPrint(LoFR, 7) = 0) And
        (UniQueryGraph(LoFR, 32) = 0) And (UniQueryGraph(LoFR, 33) = 1) And (UniQueryPunct(LoFR, 33) = 1) And
        (UniQueryPunct(LoFR, $20AC) = 1) And (UniQueryPunct(LoFR, 97) = 0));
  Check('UniQueryUpper, UniQueryLower', (UniQueryUpper(LoFR, $C9) = 1) And (UniQueryUpper(LoFR, $E9) = 0) And
        (UniQueryLower(LoFR, $E9) = 1) And (UniQueryLower(LoFR, $0391) = 0) And (UniQueryUpper(LoFR, $0391) = 1));
  Check('UniQueryChar, UniQueryAttr', (UniQueryChar(65, $0001 + $0004) = 1) And (UniQueryChar(97, $0001) = 0) And
        (UniQueryAttr(U('alpha digit')) = $0104) And (UniQueryAttr(U('bidon')) = 0));
  R := UniCreateAttrObject(LoFR, U('digit'), LongInt(@Ao));
  Check('UniCreateAttrObject digit, UniQueryCharAttr', (R = 0) And (UniQueryCharAttr(Ao, 53) = 1) And
        (UniQueryCharAttr(Ao, 120) = 0));
  A := -1; B := -1;
  R := UniScanForAttr(Ao, U('abc123'), 6, 0, LongInt(@A));
  R2 := UniScanForAttr(Ao, U('123x'), 4, 1, LongInt(@B));
  C := UniScanForAttr(Ao, U('abc'), 3, 0, LongInt(@A));
  Check('UniScanForAttr : chiffre, inverse, aucun (ULS_NOMATCH)', (R = 0) And (A = 3) And (R2 = 0) And (B = 3) And
        (C = ULS_NOMATCH));
  R := UniCreateAttrObject(LoFR, U('bidon'), LongInt(@A));
  A := UniFreeAttrObject(Ao);
  B := UniFreeAttrObject(Ao);
  Check('attribut inconnu refuse ; UniFreeAttrObject', (R = ULS_UNSUPPORTED) And (A = 0) And (B = ULS_BADOBJECT));

  { --- types --- }
  P := UniQueryCharType(65);
  Check('UniQueryCharType A : itype, bidi L, latin, alpha + demi-chasse, pages 437 850 8859',
        (RdW(P) = $0181) And (RdB(P + 2) = 1) And (RdB(P + 3) = 2) And (RdW(P + 4) = $8040) And
        (RdW(P + 6) = 7));
  P := UniQueryCharType($05D0);
  Q := UniQueryCharType($30A2);
  Check('UniQueryCharType alef (R, hebreu), katakana', (RdB(P + 2) = 2) And (RdB(P + 3) = 6) And
        ((RdW(Q + 4) And $10) <> 0) And (RdB(Q + 3) = 8));
  R := UniQueryStringType(U('A1 '), 3, LongInt(@Buf), 7);
  R2 := UniQueryStringType(U('A1 '), -1, LongInt(@Buf2), 2);
  Check('UniQueryStringType CT_CTYPE1 et CT_BIDI', (R = 0) And (Buf[0] = $181) And (Buf[1] = $84) And (Buf[2] = $48) And
        (R2 = 0) And (Buf2[0] = 1) And (Buf2[1] = 3) And (Buf2[2] = 10));
  R := UniQueryStringType(U('A'), 1, LongInt(@Buf), 99);
  Check('UniQueryStringType genre invalide', R = ULS_INVALID);
  N := 0; P := 0;
  R := UniQueryCharTypeTable(LongInt(@N), LongInt(@P));
  Q := UniQueryCharType(65);
  Check('UniQueryCharTypeTable (' + IStr(N) + ' types)', (R = 0) And (N > 50) And (N <= 1024) And (Q >= P) And
        (Q < P + N * 8) And (((Q - P) Mod 8) = 0));
  Check('UniQueryNumericValue (7, 3 arabe, IV romain, 1 cercle, 1/2, a)', (UniQueryNumericValue(55) = 7) And
        (UniQueryNumericValue($0663) = 3) And (UniQueryNumericValue($2163) = 4) And (UniQueryNumericValue($2460) = 1) And
        (UniQueryNumericValue($BD) = -1) And (UniQueryNumericValue(97) = -1));

  { --- majuscules et minuscules --- }
  Check('UniToupper (a, e aigu, alpha, io, a pleine chasse, eszett)', (UniToupper(97) = 65) And (UniToupper($E9) = $C9) And
        (UniToupper($03B1) = $0391) And (UniToupper($0451) = $0401) And (UniToupper($FF41) = $FF21) And
        (UniToupper($DF) = $DF));
  Check('UniTolower, UniTransUpper, UniTransLower', (UniTolower($C4) = $E4) And (UniTolower(65) = 97) And
        (UniTransUpper(LoFR, 122) = 90) And (UniTransLower(LoFR, 90) = 122));
  A := UniStrupr(U(Chr($E9) + 't' + Chr($E9)));
  B := UniStrlwr(U(Chr($C0) + 'BC'));
  Check('UniStrupr, UniStrlwr', UEq(A, Chr($C9) + 'T' + Chr($C9)) And UEq(B, Chr($E0) + 'bc'));

  { --- chaines --- }
  A := UniStrcpy(LongInt(@Buf), U('abc'));
  B := UniStrcat(LongInt(@Buf), U('def'));
  Check('UniStrcpy, UniStrcat, UniStrlen', (A = LongInt(@Buf)) And UEq(B, 'abcdef') And (UniStrlen(LongInt(@Buf)) = 6));
  A := UniStrncat(LongInt(@Buf), U('xyz'), 2);
  For I := 0 To 7 Do Buf2[I] := 9;
  B := UniStrncpy(LongInt(@Buf2), U('ab'), 4);
  Check('UniStrncat, UniStrncpy (complete de zeros)', UEq(A, 'abcdefxy') And (Buf2[0] = 97) And (Buf2[1] = 98) And
        (Buf2[2] = 0) And (Buf2[3] = 0) And (Buf2[4] = 9));
  Check('UniStrcmp, UniStrncmp', (UniStrcmp(U('abc'), U('abd')) < 0) And (UniStrcmp(U('abc'), U('abc')) = 0) And
        (UniStrcmp(U('b'), U('a')) > 0) And (UniStrncmp(U('abcx'), U('abcy'), 3) = 0) And (UniStrncmp(U('ab'), U('ac'), 5) < 0));
  Check('UniStrcmpi, UniStrncmpi', (UniStrcmpi(LoFR, U('ABC'), U('abc')) = 0) And (UniStrcmpi(LoFR, U('a'), U('B')) < 0) And
        (UniStrncmpi(LoFR, U('ABx'), U('aby'), 2) = 0));
  A := UniStrcpy(LongInt(@Key3), U('banana'));
  Check('UniStrchr, UniStrrchr', (UniStrchr(A, 110) = A + 4) And (UniStrrchr(A, 110) = A + 8) And (UniStrchr(A, 122) = 0) And
        (UniStrchr(A, 0) = A + 12));
  Check('UniStrspn, UniStrcspn, UniStrpbrk', (UniStrspn(U('aab'), U('a')) = 2) And (UniStrcspn(U('abc'), U('c')) = 2) And
        (UniStrpbrk(A, U('nx')) = A + 4) And (UniStrpbrk(A, U('xy')) = 0));
  Check('UniStrstr', (UniStrstr(A, U('nan')) = A + 4) And (UniStrstr(A, U('xy')) = 0) And (UniStrstr(A, U('')) = A));
  B := UniStrcpy(LongInt(@Buf), U('a,b;;c'));
  P := UniStrtok(LongInt(@Buf), U(',;'));
  Q := UniStrtok(0, U(',;'));
  R := UniStrtok(0, U(',;'));
  R2 := UniStrtok(0, U(',;'));
  Check('UniStrtok : a, b, c, fin', UEq(P, 'a') And UEq(Q, 'b') And UEq(R, 'c') And (R2 = 0));

  { --- collation --- }
  Check('UniStrcoll fr_FR : cote < c' + Chr($F4) + 'te < coter, abc < ABC, a < B',
        (UniStrcoll(LoFR, U('cote'), U('c' + Chr($F4) + 'te')) < 0) And
        (UniStrcoll(LoFR, U('c' + Chr($F4) + 'te'), U('coter')) < 0) And (UniStrcoll(LoFR, U('abc'), U('ABC')) < 0) And
        (UniStrcoll(LoFR, U('a'), U('B')) < 0) And (UniStrcoll(LoFR, U('abc'), U('abc')) = 0));
  Check('UniStrcoll C : ordre des codes (B < a)', UniStrcoll(LoC, U('a'), U('B')) > 0);
  A := UniStrxfrm(LoFR, LongInt(@Key1), U('a'), 64);
  B := UniStrxfrm(LoFR, LongInt(@Key2), U('B'), 64);
  C := UniMakeKey(LoFR, U('B'), LongInt(@Key3), 64);
  R := UniStrxfrm(LoFR, LongInt(@Buf), U('abc'), 2);
  Check('UniStrxfrm, UniMakeKey : clefs dans l''ordre de UniStrcoll', (A = 6) And (B = 6) And
        (UniStrcmp(LongInt(@Key1), LongInt(@Key2)) < 0) And (C = 6) And (UniStrcmp(LongInt(@Key2), LongInt(@Key3)) = 0) And
        (R = 14));
  A := UniGetColval(LoFR, 97);
  B := UniGetColval(LoFR, 66);
  C := UniGetColval(LoFR, $E9);
  Check('UniGetColval : a < B, e accent aigu de base e', (A < B) And (((C Shr 10) And $FFFF) = 101));

  { --- transformations --- }
  R := UniCreateTransformObject(LoFR, U('upper'), LongInt(@Xo));
  InN := -1; OutN := 16;
  R2 := UniTransformStr(Xo, U('abc'), LongInt(@InN), LongInt(@Buf), LongInt(@OutN));
  Buf[OutN] := 0;
  Check('UniCreateTransformObject upper, UniTransformStr', (R = 0) And (R2 = 0) And (InN = 3) And (OutN = 3) And
        UEq(LongInt(@Buf), 'ABC'));
  InN := -1; OutN := 2;
  R := UniTransformStr(Xo, U('abc'), LongInt(@InN), LongInt(@Buf), LongInt(@OutN));
  Check('UniTransformStr tampon trop petit (ULS_BUFFERFULL)', (R = ULS_BUFFERFULL) And (InN = 2) And (OutN = 2));
  A := UniFreeTransformObject(Xo);
  B := UniFreeTransformObject(Xo);
  R := UniCreateTransformObject(LoFR, U('bidon'), LongInt(@Xo));
  Check('UniFreeTransformObject ; type inconnu refuse', (A = 0) And (B = ULS_BADOBJECT) And (R = ULS_UNSUPPORTED));
  R := UniCreateTransformObject(LoFR, U('decompose'), LongInt(@Xo));
  InN := -1; OutN := 16;
  R2 := UniTransformStr(Xo, U(Chr($E9) + 'a'), LongInt(@InN), LongInt(@Buf), LongInt(@OutN));
  Check('decompose : e + accent aigu', (R2 = 0) And (OutN = 3) And (Buf[0] = 101) And (Buf[1] = $0301) And (Buf[2] = 97));
  A := UniFreeTransformObject(Xo);
  R := UniCreateTransformObject(LoFR, U('compose'), LongInt(@Xo));
  InN := -1; OutN := 16;
  R2 := UniTransformStr(Xo, UW(101, $0301, 97, 0), LongInt(@InN), LongInt(@Buf), LongInt(@OutN));
  Check('compose : e + accent aigu -> e accent aigu', (R2 = 0) And (InN = 3) And (OutN = 2) And (Buf[0] = $E9) And
        (Buf[1] = 97));
  A := UniFreeTransformObject(Xo);
  R := UniCreateTransformObject(LoFR, U('hiragana'), LongInt(@Xo));
  InN := -1; OutN := 16;
  R2 := UniTransformStr(Xo, UW($30AB, 65, 0, 0), LongInt(@InN), LongInt(@Buf), LongInt(@OutN));
  A := UniFreeTransformObject(Xo);
  B := UniCreateTransformObject(LoFR, U('katakana'), LongInt(@Xo));
  InN := -1; OutN := 16;
  C := UniTransformStr(Xo, UW($304B, 0, 0, 0), LongInt(@InN), LongInt(@Buf2), LongInt(@OutN));
  A := UniFreeTransformObject(Xo);
  Check('hiragana, katakana', (R2 = 0) And (Buf[0] = $304B) And (Buf[1] = 65) And (C = 0) And (Buf2[0] = $30AB));
  R := UniCreateTransformObject(LoFR, U('fullwidth'), LongInt(@Xo));
  InN := -1; OutN := 16;
  R2 := UniTransformStr(Xo, UW(65, 49, $FF76, $FF9E), LongInt(@InN), LongInt(@Buf), LongInt(@OutN));
  A := UniFreeTransformObject(Xo);
  Check('fullwidth : A1, katakana demi-chasse avec voisement', (R2 = 0) And (OutN = 3) And (Buf[0] = $FF21) And
        (Buf[1] = $FF11) And (Buf[2] = $30AC));
  R := UniCreateTransformObject(LoFR, U('halfwidth'), LongInt(@Xo));
  InN := -1; OutN := 16;
  R2 := UniTransformStr(Xo, UW($FF21, $30AC, 0, 0), LongInt(@InN), LongInt(@Buf), LongInt(@OutN));
  A := UniFreeTransformObject(Xo);
  Check('halfwidth : A, ga -> ka + voisement', (R2 = 0) And (OutN = 3) And (Buf[0] = 65) And (Buf[1] = $FF76) And
        (Buf[2] = $FF9E));
  Bytes[0] := $82; Bytes[1] := $9B; Bytes[2] := 65; Bytes[3] := 0;
  R := UniProcessUconv(LoUS, LongInt(@Bytes), LongInt(@Buf), 16);
  R2 := UniProcessUconv(LoFR, LongInt(@Bytes), LongInt(@Buf2), 16);
  A := UniProcessUconv(LoFR, LongInt(@Bytes), LongInt(@Key1), 2);
  Check('UniProcessUconv : page 437 (en_US), 850 (fr_FR), tampon trop petit', (R = 0) And (Buf[0] = $E9) And
        (Buf[1] = $A2) And (Buf[2] = 65) And (Buf[3] = 0) And (R2 = 0) And (Buf2[1] = $F8) And (A = ULS_BUFFERFULL));

  { --- nombres --- }
  A := U('  -1234xyz');
  R := UniStrtol(LoFR, A, LongInt(@P), 10, LongInt(@N));
  Check('UniStrtol -1234 (fin apres 7 caracteres)', (R = 0) And (N = -1234) And (P = A + 14));
  R := UniStrtol(LoFR, U('0x1F'), LongInt(@P), 0, LongInt(@N));
  R2 := UniStrtol(LoFR, U('017'), LongInt(@P), 0, LongInt(@A));
  C := UniStrtol(LoFR, U('ff'), LongInt(@P), 16, LongInt(@B));
  Check('UniStrtol base 0 (0x1F, 017), base 16', (R = 0) And (N = 31) And (R2 = 0) And (A = 15) And (C = 0) And (B = 255));
  R := UniStrtol(LoFR, U('99999999999'), LongInt(@P), 10, LongInt(@N));
  A := U('abc');
  R2 := UniStrtol(LoFR, A, LongInt(@P), 10, LongInt(@B));
  Check('UniStrtol depassement (ULS_RANGE), aucun chiffre (ULS_INVALID)', (R = ULS_RANGE) And (N = $7FFFFFFF) And
        (R2 = ULS_INVALID) And (P = A));
  R := UniStrtol(LoFR, UW($FF11, $FF12, 0, 0), LongInt(@P), 10, LongInt(@N));
  Check('UniStrtol chiffres pleine chasse', (R = 0) And (N = 12));
  R := UniStrtoul(LoFR, U('4294967295'), LongInt(@P), 10, LongInt(@N));
  R2 := UniStrtoul(LoFR, U('4294967296'), LongInt(@P), 10, LongInt(@A));
  Check('UniStrtoul FFFFFFFFh, depassement', (R = 0) And (N = -1) And (R2 = ULS_RANGE));
  R := UniStrtod(LoFR, U('3,25'), LongInt(@P), LongInt(@DRes));
  A := Round(DRes * 100);
  R2 := UniStrtod(LoUS, U('1.5e3'), LongInt(@P), LongInt(@DRes));
  B := Round(DRes);
  C := UniStrtod(LoFR, U('-0,5'), LongInt(@P), LongInt(@DRes));
  N := Round(DRes * 10);
  Check('UniStrtod 3,25 (fr_FR), 1.5e3 (en_US), -0,5', (R = 0) And (A = 325) And (R2 = 0) And (B = 1500) And (C = 0) And
        (N = -5));
  R := UniStrtod(LoUS, U('1e400'), LongInt(@P), LongInt(@DRes));
  B := RdL(LongInt(@DRes) + 4);
  R2 := UniStrtod(LoUS, U('x'), LongInt(@P), LongInt(@DRes));
  Check('UniStrtod depassement (HUGE_VAL), aucun chiffre', (R = ULS_RANGE) And (B = $7FF00000) And (R2 = ULS_INVALID));

  { --- dates --- }
  SetTm;
  Txt := Ftime(LoFR, '%A %d %B %Y, %H:%M');
  Check('UniStrftime fr_FR : ' + Txt, Txt = 'jeudi 12 novembre 2026, 14:05');
  Txt := Ftime(LoUS, '%x|%X|%c');
  Check('UniStrftime en_US %x %X %c : ' + Txt, Txt = '11/12/2026|02:05:09 PM|Thu 12 Nov 2026 02:05:09 PM');
  Txt := Ftime(LoUS, '%j %U %W %u %w %y %C %e %D %T %%');
  Check('UniStrftime %j %U %W %u %w %y %C %e %D %T : ' + Txt, Txt = '316 45 45 4 4 26 20 12 11/12/26 14:05:09 %');
  Txt := Ftime(LoDE, '%x %a %b');
  Check('UniStrftime de_DE : ' + Txt, Txt = '12.11.2026 Do Nov');
  R := UniStrftime(LoUS, LongInt(@Buf), 5, U('%Y-%m-%d'), LongInt(@Tm));
  Check('UniStrftime tampon trop petit (0)', R = 0);
  For I := 0 To 8 Do Tm[I] := 0;
  A := U('11/12/2026 14:05:09');
  P := UniStrptime(LoUS, A, U('%m/%d/%Y %H:%M:%S'), LongInt(@Tm));
  Check('UniStrptime en_US : date, heure, jour de la semaine et de l''annee', (P = A + 38) And (Tm[3] = 12) And
        (Tm[4] = 10) And (Tm[5] = 126) And (Tm[2] = 14) And (Tm[1] = 5) And (Tm[0] = 9) And (Tm[6] = 4) And (Tm[7] = 315));
  For I := 0 To 8 Do Tm[I] := 0;
  P := UniStrptime(LoFR, U('jeudi 12 novembre 2026'), U('%A %d %B %Y'), LongInt(@Tm));
  Q := UniStrptime(LoUS, U('Thu, Nov 12 02:05 PM'), U('%a, %b %d %I:%M %p'), LongInt(@Tm));
  Check('UniStrptime noms des jours et des mois, %I %p', (P <> 0) And (Q <> 0) And (Tm[4] = 10) And (Tm[3] = 12) And
        (Tm[2] = 14) And (Tm[1] = 5));
  P := UniStrptime(LoUS, U('13/45/2026'), U('%m/%d/%Y'), LongInt(@Tm));
  Check('UniStrptime date invalide (0)', P = 0);

  { --- montants --- }
  GV1 := 1234.567; GV2 := 0;
  Txt := Fmon(LoUS, '%n');
  Check('UniStrfmon en_US %n : ' + Txt, Txt = '$1,234.57');
  GV1 := -1234.5; GV2 := 0;
  Txt := Fmon(LoFR, '%n');
  Check('UniStrfmon fr_FR %n negatif : ' + Txt, Txt = '-1 234,50 ' + Chr($80));
  GV1 := 1234.567; GV2 := 0;
  Txt := Fmon(LoUS, '%i');
  Check('UniStrfmon en_US %i : ' + Txt, Txt = 'USD 1,234.57');
  GV1 := 1234.5; GV2 := 1234.5;
  Txt := Fmon(LoDE, '%!n|%^n');
  Check('UniStrfmon de_DE %!n %^n : ' + Txt, Txt = '1.234,50|1234,50 ' + Chr($80));
  GV1 := -5; GV2 := 12.3;
  Txt := Fmon(LoUS, '%(n|%=*#6n');
  Check('UniStrfmon en_US %(n %=*#6n : ' + Txt, Txt = '($5.00)|$****12.30');
  GV1 := 5; GV2 := 1;
  Txt := Fmon(LoUS, '[%12n] [%-8n]');
  Check('UniStrfmon largeur : ' + Txt, Txt = '[       $5.00] [$1.00   ]');
  GV1 := 1234.5; GV2 := 7.6;
  Txt := Fmon(LoIT, '%n et %.0n');
  Check('UniStrfmon it_IT, precision .0 : ' + Txt, Txt = Chr($80) + ' 1.234,50 et ' + Chr($80) + ' 8');
  DD := 1.0;
  R := UniStrfmon(LoUS, LongInt(@Buf), 3, U('%n'), RdL(LongInt(@DD)), RdL(LongInt(@DD) + 4), 0, 0);
  Check('UniStrfmon tampon trop petit (-1)', R = -1);

  { --- locales de l'utilisateur --- }
  R := UniMakeUserLocale(U('fr_TEST'), U('fr_FR'));
  R2 := UniMakeUserLocale(U('fr_TEST'), U('fr_FR'));
  A := UniMakeUserLocale(U('xx_TEST'), U('zz_ZZ'));
  Check('UniMakeUserLocale fr_TEST ; deja existante, base inconnue refusees', (R = 0) And (R2 = ULS_INVALID) And
        (A = ULS_UNSUPPORTED));
  R := UniCreateLocaleObject(UCS, U('fr_TEST'), LongInt(@Lo));
  Check('locale de l''utilisateur : nom, mois de la base', (R = 0) And ItemIs(Lo, 100, 'fr_TEST') And ItemIs(Lo, 32, 'janvier'));
  R := UniSetUserLocaleItem(U('fr_TEST'), 44, 1, U('.'));
  R2 := UniSetUserLocaleItem(U('fr_TEST'), 108, 2, 999);
  Check('UniSetUserLocaleItem chaine et entier', (R = 0) And (R2 = 0) And ItemIs(Lo, 44, '.') And (ValOf(Lo, 108) = 999) And
        ItemIs(LoFR, 44, ','));
  R := UniSetUserLocaleItem(U('fr_TEST'), 44, 3, 0);
  R2 := UniSetUserLocaleItem(U('fr_TEST'), 0, 1, U('x'));
  A := UniSetUserLocaleItem(U('zz_ZZ'), 44, 1, U('x'));
  Check('UniSetUserLocaleItem type, element, locale invalides', (R = ULS_INVALID) And (R2 = ULS_INVALID) And
        (A = ULS_UNSUPPORTED));
  P := 0;
  R := UniGetOverride(U('fr_TEST'), 44, LongInt(@P));
  R2 := UniGetOverride(U('fr_TEST'), 45, LongInt(@Q));
  Check('UniGetOverride : remplacement, aucun (ULS_NOMATCH)', (R = 0) And UEq(P, '.') And (R2 = ULS_NOMATCH));
  A := UniFreeMem(P);
  R := UniQueryLocaleList(2, LongInt(@Buf), 64);
  R2 := UniQueryLocaleList(1, LongInt(@Buf2), 128);
  A := UniQueryLocaleList(3, LongInt(@Key1), 5);
  Txt := '';
  For I := 0 To 22 Do Txt := Txt + Chr(Buf2[I] And $FF);
  Check('UniQueryLocaleList utilisateur, systeme ; tampon trop petit', (R = 0) And UEq(LongInt(@Buf), 'fr_TEST') And
        (R2 = 0) And (Txt = 'C POSIX UNIVERSAL en_US') And (A = ULS_BUFFERFULL));
  R := UniCompleteUserLocale;
  Check('UniCompleteUserLocale : C:\USERLOC.INI', (R = 0) And FileHas('C:\USERLOC.INI', 'USER fr_TEST') And
        FileHas('C:\USERLOC.INI', 'ITEM fr_TEST 44 .'));
  A := UniFreeLocaleObject(Lo);
  R := UniDeleteUserLocale(U('fr_TEST'));
  R2 := UniCreateLocaleObject(UCS, U('fr_TEST'), LongInt(@Lo));
  A := UniDeleteUserLocale(U('fr_TEST'));
  Check('UniDeleteUserLocale ; locale retiree', (R = 0) And (R2 = ULS_UNSUPPORTED) And (A = ULS_UNSUPPORTED));
  R := UniSetUserLocaleItem(U('en_US'), 48, 1, U('US$'));
  Check('remplacement d''un element d''une locale du systeme', (R = 0) And ItemIs(LoUS, 48, 'US$'));
  R := UniDeleteUserLocale(U('en_US'));
  Check('UniDeleteUserLocale du systeme : remplacements retires', (R = 0) And ItemIs(LoUS, 48, '$'));
  R := UniCompleteUserLocale;
  A := DosDelete(Z('C:\USERLOC.INI'));

  { --- noms des langues et des pays --- }
  P := 0;
  R := UniQueryLanguageName(U('fr'), U('en'), LongInt(@P));
  Check('UniQueryLanguageName fr en anglais', (R = 0) And UEq(P, 'French'));
  A := UniFreeMem(P);
  R := UniQueryLanguageName(U('de_DE'), U('de'), LongInt(@P));
  Check('UniQueryLanguageName de en allemand', (R = 0) And UEq(P, 'Deutsch'));
  A := UniFreeMem(P);
  R := UniQueryLanguageName(U('es'), U('fr'), LongInt(@P));
  Check('UniQueryLanguageName es en francais', (R = 0) And UEq(P, 'espagnol'));
  A := UniFreeMem(P);
  R := UniQueryLanguageName(U('zz'), U('en'), LongInt(@P));
  Check('UniQueryLanguageName langue inconnue', R = ULS_UNSUPPORTED);
  R := UniQueryCountryName(U('DE'), U('fr'), LongInt(@P));
  Check('UniQueryCountryName DE en francais', (R = 0) And UEq(P, 'Allemagne'));
  A := UniFreeMem(P);
  R := UniQueryCountryName(U('fr_CA'), U('en'), LongInt(@P));
  Check('UniQueryCountryName fr_CA en anglais', (R = 0) And UEq(P, 'Canada'));
  A := UniFreeMem(P);
  R := UniQueryCountryName(U('ES'), U('es'), LongInt(@P));
  Check('UniQueryCountryName ES en espagnol', (R = 0) And UEq(P, 'Espa' + Chr($F1) + 'a'));
  A := UniFreeMem(P);
  R := UniQueryCountryName(U('ZZ'), U('en'), LongInt(@P));
  Check('UniQueryCountryName pays inconnu', R = ULS_UNSUPPORTED);

  A := UniFreeLocaleObject(LoFR);
  A := UniFreeLocaleObject(LoUS);
  A := UniFreeLocaleObject(LoDE);
  A := UniFreeLocaleObject(LoC);
  A := UniFreeLocaleObject(LoIT);

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTUNI : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
