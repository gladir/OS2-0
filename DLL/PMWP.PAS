{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 PMWP.DLL de OS/2-0 (objets du Workplace
                Shell : WinCreateObject, WinQueryObject...).
}

Library PMWP;

{$IMAGEBASE $00E40000}
{$R-,S-,I-}

{ Compilation : OS2PC PMWP.PAS   (produit PMWP.DLL)

  PMWP.DLL est, sous OS/2 2.x, la bibliotheque du Workplace Shell : les
  programmes creent, retrouvent, modifient et detruisent les objets du
  bureau (dossiers, programmes, fichiers de donnees) par leur
  identificateur (<WP_DESKTOP>, <WP_FPWO_FOLD>...). OS/2-0 garde ces
  objets dans OS2.INI (application PMWP_OBJETS : cle = identificateur
  ou titre, valeur = classe;titre;emplacement;reglages) ; le bureau
  (PMSHELL) affiche ceux dont l'emplacement est <WP_DESKTOP> ou un
  dossier d'objets cree ainsi. Fonctions (ordinaux d'OS/2) :

    209 WinLoadFileIcon(pszFileName, fPrivate) : HPOINTER (icone de
          fichier : celle d'un programme ou d'un fichier, pointeur du
          systeme)
    216 WinFreeFileIcon(hptr) : BOOL
    250 WinSetObjectData(hObject, pszSetupString) : BOOL (reglages
          ajoutes a ceux de l'objet)
    251 WinDestroyObject(hObject) : BOOL
    252 WinQueryObject(pszObjectID) : HOBJECT (identificateur entre < >,
          objets predefinis du bureau, ou chemin d'un fichier existant ;
          0 si absent)
    281 WinCreateObject(pszClassName, pszTitle, pszSetupString,
          pszLocation, ulFlags) : HOBJECT ; ulFlags : CO_FAILIFEXISTS 0,
          CO_REPLACEIFEXISTS 1, CO_UPDATEIFEXISTS 2
    200 WinRegisterObjectClass(pszClassName, pszModName) : BOOL
    201 WinDeregisterObjectClass(pszClassName) : BOOL
    263 WinQueryObjectPath(hObject, pszPathName, ulSize) : BOOL
    286 WinOpenObject(hObject, ulView, fFlags) : BOOL (programme : lance)

  Un HOBJECT vaut 50570000h + numero de l'objet (1 a MaxObj) ; les objets
  predefinis ont les numeros 1 a 8. }

Type
  PLong = ^LongInt;
  PByte = ^Byte;

Function PrfQueryProfileString(Hini, PApp, PKey, PDef, PBuf, Max : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryProfileString';
Function PrfWriteProfileString(Hini, PApp, PKey, PData : LongInt) : LongInt; External 'PMMERGE' Name 'PrfWriteProfileString';
Function WinQuerySysPointer(HDesk, Id, Copy : LongInt) : LongInt; External 'PMWIN' Name 'WinQuerySysPointer';
Function DcQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryPathInfo';
Function DcStartSession(P, PSid, PPid : LongInt) : LongInt; External 'SESMGR' Name 'Dos32StartSession';

Const
  HINI_USER = -1;
  MaxObj    = 128;
  HBase     = $50570000;
  NPredef   = 8;

Var
  OId, OClass, OTitle, OLoc : Array[1..MaxObj] Of String[63];
  OSetup : Array[1..MaxObj] Of String;
  OUsed  : Array[1..MaxObj] Of Boolean;
  Loaded : Boolean;
  ZA, ZB, ZC : Array[0..259] Of Byte;
  Buf : Array[0..1023] Of Byte;
  St : Array[0..15] Of LongInt;
  Sd : Array[0..15] Of LongInt;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^ And $FF;
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
  N := 0;
  If A <> 0 Then
    While (N < 255) And (RdB(A + N) <> 0) Do
    Begin
      S := S + Chr(RdB(A + N));
      Inc(N);
    End;
  GetZ := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do WrB(A + I - 1, Ord(S[I]));
  WrB(A + Length(S), 0);
End;

Function UpS(S : String) : String;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do S[I] := UpCase(S[I]);
  UpS := S;
End;

{ valeur d'un reglage NOM=valeur; dans une chaine de reglages }
Function SetupVal(Setup, Nm : String) : String;
Var U : String; P, Q : LongInt;
Begin
  SetupVal := '';
  U := ';' + UpS(Setup);
  P := Pos(';' + UpS(Nm) + '=', U);
  If P = 0 Then Exit;
  U := Copy(Setup, P + Length(Nm) + 1, 255);
  Q := Pos(';', U);
  If Q > 0 Then U := Copy(U, 1, Q - 1);
  SetupVal := U;
End;

Procedure Save(I : LongInt);
Var K : String;
Begin
  If OId[I] <> '' Then K := OId[I] Else K := OTitle[I];
  PutZ(LongInt(@ZA), 'PMWP_OBJETS');
  PutZ(LongInt(@ZB), K);
  If OUsed[I] Then
  Begin
    PutZ(LongInt(@ZC), OClass[I] + '|' + OTitle[I] + '|' + OLoc[I] + '|' + OSetup[I]);
    PrfWriteProfileString(HINI_USER, LongInt(@ZA), LongInt(@ZB), LongInt(@ZC));
  End
  Else PrfWriteProfileString(HINI_USER, LongInt(@ZA), LongInt(@ZB), 0);
End;

{ objets predefinis, puis ceux d'OS2.INI }
Procedure Load;
Var I, N, P, K : LongInt; Key, V : String;
Begin
  If Loaded Then Exit;
  Loaded := True;
  For I := 1 To MaxObj Do OUsed[I] := False;
  OId[1] := '<WP_DESKTOP>'; OTitle[1] := 'Bureau';
  OId[2] := '<WP_OS2SYS>'; OTitle[2] := 'Systeme OS/2';
  OId[3] := '<WP_DRIVES>'; OTitle[3] := 'Lecteurs';
  OId[4] := '<WP_TEMPS>'; OTitle[4] := 'Modeles';
  OId[5] := '<WP_START>'; OTitle[5] := 'Demarrage';
  OId[6] := '<WP_NOWHERE>'; OTitle[6] := '';
  OId[7] := '<WP_CONFIG>'; OTitle[7] := 'Configuration du systeme';
  OId[8] := '<WP_PROMPTS>'; OTitle[8] := 'Invites de commandes';
  For I := 1 To NPredef Do
  Begin
    OUsed[I] := True; OClass[I] := 'WPFolder'; OLoc[I] := ''; OSetup[I] := '';
  End;
  { cles de l'application PMWP_OBJETS (liste separee par des zeros) }
  PutZ(LongInt(@ZA), 'PMWP_OBJETS');
  N := PrfQueryProfileString(HINI_USER, LongInt(@ZA), 0, 0, LongInt(@Buf), SizeOf(Buf));
  P := 0;
  I := NPredef + 1;
  While (P < N) And (RdB(LongInt(@Buf) + P) <> 0) And (I <= MaxObj) Do
  Begin
    Key := GetZ(LongInt(@Buf) + P);
    P := P + Length(Key) + 1;
    PutZ(LongInt(@ZB), Key);
    PrfQueryProfileString(HINI_USER, LongInt(@ZA), LongInt(@ZB), 0, LongInt(@ZC), 256);
    V := GetZ(LongInt(@ZC));
    K := Pos('|', V);
    If K > 0 Then
    Begin
      OClass[I] := Copy(V, 1, K - 1); V := Copy(V, K + 1, 255);
      K := Pos('|', V);
      OTitle[I] := Copy(V, 1, K - 1); V := Copy(V, K + 1, 255);
      K := Pos('|', V);
      OLoc[I] := Copy(V, 1, K - 1); OSetup[I] := Copy(V, K + 1, 255);
      If Copy(Key, 1, 1) = '<' Then OId[I] := Key Else OId[I] := '';
      OUsed[I] := True;
      Inc(I);
    End;
  End;
End;

Function FindId(Id : String) : LongInt;
Var I : LongInt;
Begin
  FindId := 0;
  If Id = '' Then Exit;
  For I := 1 To MaxObj Do
    If OUsed[I] And (UpS(OId[I]) = UpS(Id)) Then
    Begin
      FindId := I;
      Exit;
    End;
End;

Function Slot(H : LongInt) : LongInt;
Begin
  Slot := 0;
  Load;
  If (H > HBase) And (H <= HBase + MaxObj) Then
    If OUsed[H - HBase] Then Slot := H - HBase;
End;

{ 281 }
Function WinCreateObject(PClass, PTitle, PSetup, PLoc, Flags : LongInt) : LongInt;
Var I, K : LongInt; Id, Setup : String;
Begin
  WinCreateObject := 0;
  Load;
  Setup := GetZ(PSetup);
  Id := SetupVal(Setup, 'OBJECTID');
  I := FindId(Id);
  If I > 0 Then
  Begin
    If (Flags And 3) = 0 Then Exit;             { CO_FAILIFEXISTS }
    If (Flags And 3) = 2 Then                   { CO_UPDATEIFEXISTS }
    Begin
      OSetup[I] := OSetup[I] + ';' + Setup;
      Save(I);
      WinCreateObject := HBase + I;
      Exit;
    End;
  End
  Else
  Begin
    I := 0;
    For K := MaxObj DownTo NPredef + 1 Do
      If Not OUsed[K] Then I := K;
    If I = 0 Then Exit;
  End;
  OUsed[I] := True;
  OId[I] := Copy(Id, 1, 63);
  OClass[I] := Copy(GetZ(PClass), 1, 63);
  OTitle[I] := Copy(GetZ(PTitle), 1, 63);
  OLoc[I] := Copy(GetZ(PLoc), 1, 63);
  OSetup[I] := Setup;
  Save(I);
  WinCreateObject := HBase + I;
End;

{ 252 }
Function WinQueryObject(PId : LongInt) : LongInt;
Var I, K : LongInt; Id : String;
Begin
  WinQueryObject := 0;
  Load;
  Id := GetZ(PId);
  If Id = '' Then Exit;
  I := FindId(Id);
  If I = 0 Then
    If Copy(Id, 1, 1) <> '<' Then
    Begin
      { fichier ou repertoire : objet de donnees }
      If DcQueryPathInfo(PId, 1, LongInt(@St), 24) <> 0 Then Exit;
      For K := MaxObj DownTo NPredef + 1 Do
        If Not OUsed[K] Then I := K;
      If I = 0 Then Exit;
      OUsed[I] := True;
      If (St[5] And $10) <> 0 Then OClass[I] := 'WPFolder' Else OClass[I] := 'WPDataFile';
      OId[I] := ''; OTitle[I] := Copy(Id, 1, 63); OLoc[I] := ''; OSetup[I] := '';
    End;
  If I > 0 Then WinQueryObject := HBase + I;
End;

{ 250 }
Function WinSetObjectData(H, PSetup : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinSetObjectData := 0;
  I := Slot(H);
  If I = 0 Then Exit;
  If I > NPredef Then
  Begin
    OSetup[I] := OSetup[I] + ';' + GetZ(PSetup);
    Save(I);
  End;
  WinSetObjectData := 1;
End;

{ 251 }
Function WinDestroyObject(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinDestroyObject := 0;
  I := Slot(H);
  If I <= NPredef Then Exit;
  OUsed[I] := False;
  Save(I);
  WinDestroyObject := 1;
End;

{ 209 : icone du systeme selon le genre du fichier (programme, dossier,
  fichier) }
Function WinLoadFileIcon(PName, Priv : LongInt) : LongInt;
Var S : String;
Begin
  S := UpS(GetZ(PName));
  If DcQueryPathInfo(PName, 1, LongInt(@St), 24) = 0 Then
  Begin
    If (St[5] And $10) <> 0 Then WinLoadFileIcon := WinQuerySysPointer(1, 20, 0)    { SPTR_FOLDER }
    Else If (Pos('.EXE', S) > 0) Or (Pos('.COM', S) > 0) Or (Pos('.CMD', S) > 0) Then
      WinLoadFileIcon := WinQuerySysPointer(1, 22, 0)                              { SPTR_PROGRAM }
    Else WinLoadFileIcon := WinQuerySysPointer(1, 19, 0);                          { SPTR_FILE }
  End
  Else WinLoadFileIcon := 0;
End;

{ 216 }
Function WinFreeFileIcon(Hptr : LongInt) : LongInt;
Begin
  WinFreeFileIcon := 1;
End;

{ 200, 201 : classes (dans OS2.INI, PMWP_CLASSES) }
Function WinRegisterObjectClass(PClass, PMod : LongInt) : LongInt;
Begin
  PutZ(LongInt(@ZA), 'PMWP_CLASSES');
  WinRegisterObjectClass := PrfWriteProfileString(HINI_USER, LongInt(@ZA), PClass, PMod);
End;

Function WinDeregisterObjectClass(PClass : LongInt) : LongInt;
Begin
  PutZ(LongInt(@ZA), 'PMWP_CLASSES');
  WinDeregisterObjectClass := PrfWriteProfileString(HINI_USER, LongInt(@ZA), PClass, 0);
End;

{ 263 }
Function WinQueryObjectPath(H, PPath, Size : LongInt) : LongInt;
Var I : LongInt; S : String;
Begin
  WinQueryObjectPath := 0;
  I := Slot(H);
  If (I = 0) Or (Size <= 0) Then Exit;
  If I = 1 Then S := 'C:\DESKTOP'
  Else If (OClass[I] = 'WPDataFile') Or (OClass[I] = 'WPFolder') And (OId[I] = '') Then S := OTitle[I]
  Else S := 'C:\DESKTOP\' + OTitle[I];
  S := Copy(S, 1, Size - 1);
  PutZ(PPath, S);
  WinQueryObjectPath := 1;
End;

{ 286 : un objet programme est lance (EXENAME, PARAMETERS) }
Function WinOpenObject(H, View, Fl : LongInt) : LongInt;
Var I, K : LongInt; Exe, Prm : String;
Begin
  WinOpenObject := 0;
  I := Slot(H);
  If I = 0 Then Exit;
  Exe := SetupVal(OSetup[I], 'EXENAME');
  If Exe = '' Then Exit;
  Prm := SetupVal(OSetup[I], 'PARAMETERS');
  PutZ(LongInt(@ZA), Exe);
  PutZ(LongInt(@ZB), Prm);
  PutZ(LongInt(@ZC), OTitle[I]);
  For K := 0 To 15 Do Sd[K] := 0;
  { STARTDATA (32 octets) : Length, Related, FgBg, TraceOpt, PgmTitle,
    PgmName, PgmInputs }
  Sd[0] := 32;
  Sd[2] := LongInt(@ZC); Sd[3] := LongInt(@ZA); Sd[4] := LongInt(@ZB);
  WinOpenObject := Ord(DcStartSession(LongInt(@Sd), LongInt(@St), LongInt(@St) + 4) = 0);
End;

exports
  WinRegisterObjectClass Index 200 Name 'WinRegisterObjectClass',
  WinDeregisterObjectClass Index 201 Name 'WinDeregisterObjectClass',
  WinLoadFileIcon Index 209 Name 'WinLoadFileIcon',
  WinFreeFileIcon Index 216 Name 'WinFreeFileIcon',
  WinSetObjectData Index 250 Name 'WinSetObjectData',
  WinDestroyObject Index 251 Name 'WinDestroyObject',
  WinQueryObject Index 252 Name 'WinQueryObject',
  WinQueryObjectPath Index 263 Name 'WinQueryObjectPath',
  WinCreateObject Index 281 Name 'WinCreateObject',
  WinOpenObject Index 286 Name 'WinOpenObject';

BEGIN
  Loaded := False;
END.
