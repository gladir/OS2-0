{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de NLS.DLL sous OS/2-0.
}

Program TESTNLS;

{$R-,S-,I-}

{ Compilation : OS2PC TESTNLS.PAS   (produit TESTNLS.EXE)

  TESTNLS   verifie les 8 fonctions de NLS.DLL (pays, majuscules, tri et
            DBCS) ; elles sont importees sous des noms Nls* pour ne pas
            les confondre avec celles de DOSCALLS.DLL. }

Function NlsCaseMap(Len, Pcc, PCh : LongInt) : LongInt; External 'NLS' Name 'DosCaseMap';
Function NlsGetCollate(Len, Pcc, PBuf, PcbTable : LongInt) : LongInt; External 'NLS' Name 'DosGetCollate';
Function NlsGetCtryInfo(Cb, Pcc, Pci, PcbActual : LongInt) : LongInt; External 'NLS' Name 'DosGetCtryInfo';
Function NlsGetDBCSEv(Cb, Pcc, PBuf : LongInt) : LongInt; External 'NLS' Name 'DosGetDBCSEv';
Function NlsQueryCtryInfo(Cb, Pcc, Pci, PcbActual : LongInt) : LongInt; External 'NLS' Name 'DosQueryCtryInfo';
Function NlsQueryDBCSEnv(Cb, Pcc, PBuf : LongInt) : LongInt; External 'NLS' Name 'DosQueryDBCSEnv';
Function NlsMapCase(Cb, Pcc, PCh : LongInt) : LongInt; External 'NLS' Name 'DosMapCase';
Function NlsQueryCollate(Cb, Pcc, PCh, PcbActual : LongInt) : LongInt; External 'NLS' Name 'DosQueryCollate';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';

Const
  ERROR_NO_COUNTRY_OR_CODEPAGE = 39;
  ERROR_NLS_TABLE_TRUNCATED = 40;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, N, H, I : LongInt;
  Cc : Array[0..1] Of LongInt;       { COUNTRYCODE 32 bits }
  Cc16 : Array[0..1] Of Word;        { COUNTRYCODE 16 bits }
  Ci : Array[0..63] Of Byte;         { COUNTRYINFO }
  Tb : Array[0..255] Of Byte;
  Sb : Array[0..15] Of Byte;
  Name : Array[0..63] Of Byte;

Function IStr(V : LongInt) : String;
Var T : String;
Begin
  Str(V, T);
  IStr := T;
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

Function GetZ(A : LongInt) : String;
Var T : String; P : PByte;
Begin
  T := '';
  P := Pointer(A);
  While (P^ <> 0) And (Length(T) < 32) Do
  Begin
    T := T + Chr(P^);
    A := A + 1;
    P := Pointer(A);
  End;
  GetZ := T;
End;

Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Name[K - 1] := Ord(S[K]);
  Name[Length(S)] := 0;
  Z := LongInt(@Name);
End;

Procedure Check(What : String; Cond : Boolean);
Begin
  If Cond Then
  Begin
    Inc(Ok);
    WriteLn('  OK     ', What);
  End
  Else
  Begin
    Inc(Fail);
    WriteLn('  ECHEC  ', What, '  (code ', R, ')');
  End;
End;

Function Ctry(C, Cp : LongInt) : LongInt;
Begin
  Cc[0] := C; Cc[1] := Cp;
  Ctry := LongInt(@Cc);
End;

Function Ctry16(C, Cp : LongInt) : LongInt;
Begin
  Cc16[0] := C; Cc16[1] := Cp;
  Ctry16 := LongInt(@Cc16);
End;

Function OrdIs(Ordinal : LongInt; S : String) : Boolean;
Var Pa, Pb : LongInt;
Begin
  Pa := 0; Pb := 0;
  DosQueryProcAddr(H, 0, Z(S), LongInt(@Pa));
  DosQueryProcAddr(H, Ordinal, 0, LongInt(@Pb));
  OrdIs := (Pa <> 0) And (Pa = Pb);
End;

Procedure SetSb(B0, B1, B2, B3, B4 : LongInt);
Begin
  Sb[0] := B0; Sb[1] := B1; Sb[2] := B2; Sb[3] := B3; Sb[4] := B4; Sb[5] := 0;
End;

BEGIN
  Ok := 0; Fail := 0;
  WriteLn('TESTNLS : essai de NLS.DLL');

  { --- module et ordinaux --- }
  R := DosQueryModuleHandle(Z('NLS'), LongInt(@H));
  Check('DosQueryModuleHandle NLS', R = 0);
  Check('ordinaux 1 DosCaseMap ... 8 DosQueryCollate', OrdIs(1, 'DosCaseMap') And OrdIs(2, 'DosGetCollate') And
        OrdIs(3, 'DosGetCtryInfo') And OrdIs(4, 'DosGetDBCSEv') And OrdIs(5, 'DosQueryCtryInfo') And
        OrdIs(6, 'DosQueryDBCSEnv') And OrdIs(7, 'DosMapCase') And OrdIs(8, 'DosQueryCollate'));
  Check('ordinal 9 inexistant', DosQueryProcAddr(H, 9, 0, LongInt(@I)) <> 0);

  { --- informations des pays --- }
  R := NlsQueryCtryInfo(44, 0, LongInt(@Ci), LongInt(@N));
  Check('DosQueryCtryInfo pays courant (' + GetZ(LongInt(@Ci) + 12) + ', pays ' + IStr(RdL(LongInt(@Ci))) + ')',
        (R = 0) And (N = 44) And (RdL(LongInt(@Ci)) <> 0));
  R := NlsQueryCtryInfo(44, Ctry(33, 850), LongInt(@Ci), LongInt(@N));
  Check('France (33, 850) : JJ/MM/AAAA, EUR, "1 234,56", 24 h, ";"', (R = 0) And (RdL(LongInt(@Ci)) = 33) And
        (RdL(LongInt(@Ci) + 4) = 850) And (RdL(LongInt(@Ci) + 8) = 1) And (GetZ(LongInt(@Ci) + 12) = 'EUR') And
        (GetZ(LongInt(@Ci) + 17) = ' ') And (GetZ(LongInt(@Ci) + 19) = ',') And (GetZ(LongInt(@Ci) + 21) = '/') And
        (Ci[25] = 3) And (Ci[26] = 2) And (Ci[27] = 1) And (GetZ(LongInt(@Ci) + 32) = ';'));
  R := NlsQueryCtryInfo(44, Ctry(1, 437), LongInt(@Ci), LongInt(@N));
  Check('Etats-Unis (1, 437) : MM-JJ-AAAA, $, 12 h', (R = 0) And (RdL(LongInt(@Ci) + 8) = 0) And
        (GetZ(LongInt(@Ci) + 12) = '$') And (Ci[27] = 0) And (GetZ(LongInt(@Ci) + 21) = '-'));
  R := NlsQueryCtryInfo(44, Ctry(44, 437), LongInt(@Ci), LongInt(@N));
  Check('Royaume-Uni (44, 437) : livre sterling (9Ch)', (R = 0) And (Ci[12] = $9C) And (Ci[13] = 0));
  R := NlsQueryCtryInfo(44, Ctry(81, 932), LongInt(@Ci), LongInt(@N));
  Check('Japon (81, 932) : AAAA-MM-JJ, yen 5Ch, 0 decimale', (R = 0) And (RdL(LongInt(@Ci) + 8) = 2) And
        (Ci[12] = $5C) And (Ci[26] = 0));
  R := NlsQueryCtryInfo(44, Ctry(81, 850), LongInt(@Ci), LongInt(@N));
  Check('Japon (81, 850) : yen BEh', (R = 0) And (Ci[12] = $BE));
  R := NlsQueryCtryInfo(44, Ctry(41, 850), LongInt(@Ci), LongInt(@N));
  Check('Suisse (41, 850) : separateur des milliers apostrophe', (R = 0) And (GetZ(LongInt(@Ci) + 17) = ''''));
  R := NlsQueryCtryInfo(44, Ctry(999, 850), LongInt(@Ci), LongInt(@N));
  Check('pays 999 refuse', R = ERROR_NO_COUNTRY_OR_CODEPAGE);
  R := NlsQueryCtryInfo(44, Ctry(33, 932), LongInt(@Ci), LongInt(@N));
  Check('France avec la page 932 refusee', R = ERROR_NO_COUNTRY_OR_CODEPAGE);
  R := NlsQueryCtryInfo(20, Ctry(33, 850), LongInt(@Ci), LongInt(@N));
  Check('tampon de 20 octets : ERROR_NLS_TABLE_TRUNCATED, 20 rendus', (R = ERROR_NLS_TABLE_TRUNCATED) And (N = 20));
  FillChar(Ci, 64, $FF);
  R := NlsGetCtryInfo(64, Ctry16(33, 850), LongInt(@Ci), LongInt(@N));
  Check('DosGetCtryInfo (16 bits, 38 octets : 33, 850, EUR, ",")', (R = 0) And (N = 38) And (RdW(LongInt(@Ci)) = 33) And
        (RdW(LongInt(@Ci) + 2) = 850) And (RdW(LongInt(@Ci) + 4) = 1) And (GetZ(LongInt(@Ci) + 6) = 'EUR') And
        (GetZ(LongInt(@Ci) + 13) = ',') And (Ci[38] = $FF));

  { --- majuscules --- }
  SetSb(Ord('a'), $82, $85, $87, $A4);
  R := NlsMapCase(5, Ctry(33, 850), LongInt(@Sb));
  Check('DosMapCase page 850 (a e-aigu a-grave c-cedille n-tilde)', (R = 0) And (Sb[0] = Ord('A')) And (Sb[1] = $90) And
        (Sb[2] = $B7) And (Sb[3] = $80) And (Sb[4] = $A5));
  SetSb($85, $82, $83, Ord('z'), Ord('1'));
  R := NlsMapCase(5, Ctry(1, 437), LongInt(@Sb));
  Check('DosMapCase page 437 (a-grave -> A, e-aigu -> E-aigu)', (R = 0) And (Sb[0] = Ord('A')) And (Sb[1] = $90) And
        (Sb[2] = Ord('A')) And (Sb[3] = Ord('Z')) And (Sb[4] = Ord('1')));
  SetSb(Ord('i'), $8D, $87, Ord('a'), 0);
  R := NlsMapCase(4, Ctry(90, 857), LongInt(@Sb));
  Check('DosMapCase turc (857 : i -> I pointe, i sans point -> I)', (R = 0) And (Sb[0] = $98) And (Sb[1] = Ord('I')) And
        (Sb[2] = $80) And (Sb[3] = Ord('A')));
  SetSb($A0, $EF, $AE, 0, 0);
  R := NlsMapCase(3, Ctry(7, 866), LongInt(@Sb));
  Check('DosMapCase russe (866 : a, ya, o cyrilliques)', (R = 0) And (Sb[0] = $80) And (Sb[1] = $9F) And (Sb[2] = $8E));
  SetSb($82, Ord('a'), Ord('b'), 0, 0);
  R := NlsMapCase(3, Ctry(81, 932), LongInt(@Sb));
  Check('DosMapCase japonais (932 : octet de queue garde)', (R = 0) And (Sb[0] = $82) And (Sb[1] = Ord('a')) And
        (Sb[2] = Ord('B')));
  SetSb(Ord('x'), $81, $94, 0, 0);
  R := NlsCaseMap(3, Ctry16(49, 850), LongInt(@Sb));
  Check('DosCaseMap (16 bits, allemand : u-trema, o-trema)', (R = 0) And (Sb[0] = Ord('X')) And (Sb[1] = $9A) And
        (Sb[2] = $99));
  Check('DosMapCase pays inconnu refuse', NlsMapCase(1, Ctry(5, 0), LongInt(@Sb)) = ERROR_NO_COUNTRY_OR_CODEPAGE);

  { --- tri --- }
  R := NlsQueryCollate(256, Ctry(33, 850), LongInt(@Tb), LongInt(@N));
  Check('DosQueryCollate France (256 poids, a = A, e-aigu = E, A < B)', (R = 0) And (N = 256) And
        (Tb[Ord('a')] = Tb[Ord('A')]) And (Tb[$82] = Tb[Ord('E')]) And (Tb[$90] = Tb[Ord('E')]) And
        (Tb[Ord('A')] < Tb[Ord('B')]) And (Tb[Ord('1')] < Tb[Ord('A')]));
  R := NlsQueryCollate(256, Ctry(45, 865), LongInt(@Tb), LongInt(@N));
  Check('danois (865) : AE < O barre < A rond, apres Z', (R = 0) And (Tb[$92] > Tb[Ord('Z')]) And (Tb[$9D] > Tb[$92]) And
        (Tb[$8F] > Tb[$9D]) And (Tb[$86] = Tb[$8F]));
  R := NlsQueryCollate(256, Ctry(46, 850), LongInt(@Tb), LongInt(@N));
  Check('suedois (850) : A rond < A trema < O trema, apres Z', (R = 0) And (Tb[$8F] > Tb[Ord('Z')]) And
        (Tb[$8E] > Tb[$8F]) And (Tb[$99] > Tb[$8E]) And (Tb[$84] = Tb[$8E]));
  R := NlsQueryCollate(256, Ctry(7, 866), LongInt(@Tb), LongInt(@N));
  Check('russe (866) : minuscules et majuscules cyrilliques de meme poids', (R = 0) And (Tb[$A0] = Tb[$80]) And
        (Tb[$EF] = Tb[$9F]) And (Tb[$80] < Tb[$9F]));
  R := NlsGetCollate(100, Ctry16(33, 850), LongInt(@Tb), LongInt(@N));
  Check('DosGetCollate (16 bits) tampon de 100 : tronque', (R = ERROR_NLS_TABLE_TRUNCATED) And (N = 100));

  { --- DBCS --- }
  FillChar(Sb, 16, $FF);
  R := NlsQueryDBCSEnv(16, Ctry(33, 850), LongInt(@Sb));
  Check('DosQueryDBCSEnv page 850 : vide (0, 0)', (R = 0) And (Sb[0] = 0) And (Sb[1] = 0));
  R := NlsQueryDBCSEnv(16, Ctry(81, 932), LongInt(@Sb));
  Check('DosQueryDBCSEnv page 932 : 81h-9Fh, E0h-FCh', (R = 0) And (Sb[0] = $81) And (Sb[1] = $9F) And
        (Sb[2] = $E0) And (Sb[3] = $FC) And (Sb[4] = 0) And (Sb[5] = 0));
  R := NlsQueryDBCSEnv(16, Ctry(82, 949), LongInt(@Sb));
  Check('DosQueryDBCSEnv page 949 : 81h-FEh', (R = 0) And (Sb[0] = $81) And (Sb[1] = $FE) And (Sb[2] = 0));
  R := NlsQueryDBCSEnv(2, Ctry(81, 932), LongInt(@Sb));
  Check('DosQueryDBCSEnv tampon de 2 : tronque', R = ERROR_NLS_TABLE_TRUNCATED);
  FillChar(Sb, 16, $FF);
  R := NlsGetDBCSEv(16, Ctry16(86, 936), LongInt(@Sb));
  Check('DosGetDBCSEv (16 bits) page 936 : 81h-FEh', (R = 0) And (Sb[0] = $81) And (Sb[1] = $FE) And
        (Sb[2] = 0) And (Sb[3] = 0));

  WriteLn;
  WriteLn('TESTNLS : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
