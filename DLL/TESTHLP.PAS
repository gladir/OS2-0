{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de HELPMGR.DLL sous OS/2-0.
}

Program TESTHLP;

{$R-,S-,I-}

{ Compilation : OS2PC TESTHLP.PAS   (produit TESTHLP.EXE)

  TESTHLP verifie les 6 points d'entree de HELPMGR.DLL : instances
  d'aide (HELPINIT, bibliotheques .HLP), associations aux fenetres,
  tables d'aide en memoire et dans les ressources d'un module. OS2PC ne
  produisant pas de ressources, le module est une image PE construite en
  memoire (en-tetes MZ et PE, repertoire des ressources RT_HELPTABLE et
  RT_HELPSUBTABLE). La recherche dans la variable HELP utilise
  D:\AIDE (SET HELP=D:\AIDE; du CONFIG.SYS du CD-ROM). }

Function WinCreateHelpInstance(Hab, PInit : LongInt) : LongInt; External 'HELPMGR' Name 'WINCREATEHELPINSTANCE';
Function WinDestroyHelpInstance(H : LongInt) : LongInt; External 'HELPMGR' Name 'WINDESTROYHELPINSTANCE';
Function WinQueryHelpInstance(Hwnd : LongInt) : LongInt; External 'HELPMGR' Name 'WINQUERYHELPINSTANCE';
Function WinAssociateHelpInstance(H, Hwnd : LongInt) : LongInt; External 'HELPMGR' Name 'WINASSOCIATEHELPINSTANCE';
Function WinLoadHelpTable(H, Id, Hmod : LongInt) : LongInt; External 'HELPMGR' Name 'WINLOADHELPTABLE';
Function WinCreateHelpTable(H, P : LongInt) : LongInt; External 'HELPMGR' Name 'WINCREATEHELPTABLE';
Function HmQueryPanelId(H, IdApp, IdWin : LongInt) : LongInt; External 'HELPMGR' Name 'HMQUERYPANELID';
Function HmQueryInstanceInfo(H, Field, P, Cb : LongInt) : LongInt; External 'HELPMGR' Name 'HMQUERYINSTANCEINFO';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEaop2 : LongInt) : LongInt; External 'DOSCALLS';
Function DosDeleteDir(PName : LongInt) : LongInt; External 'DOSCALLS';

Const
  HMERR_HELPTABLE_UNDEFINE = $1009;
  HMERR_OPEN_LIB_FILE      = $2003;
  HMERR_INVALID_LIB_FILE   = $2006;
  HMERR_NO_MEMORY          = $2007;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, H1, H2, H3 : LongInt;
  Hs : Array[0..9] Of LongInt;
  Name : Array[0..127] Of Byte;
  Hi : Array[0..63] Of Byte;            { HELPINIT }
  Tab, Tab2 : Array[0..63] Of Byte;     { HELPTABLE }
  Sub1, Sub2, SubBad : Array[0..31] Of Byte;  { HELPSUBTABLE }
  Title, Lib, Tutor : Array[0..127] Of Byte;
  Img : Array[0..1023] Of Byte;         { module PE en memoire }
  TBuf : Array[0..255] Of Byte;
  Buf : Array[0..63] Of Byte;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

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

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  K := 0;
  While (RdB(A + K) <> 0) And (K < 250) Do
  Begin
    S := S + Chr(RdB(A + K));
    Inc(K);
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

{ Fichier de Len octets commencant par Sig }
Function MakeFile(F, Sig : String) : LongInt;
Var Hf, Act, W, D : LongInt;
Begin
  For W := 0 To 63 Do Buf[W] := 0;
  PutZ(LongInt(@Buf), Sig);
  D := DosOpen(Z(F), LongInt(@Hf), LongInt(@Act), 0, 0, $12, $41, 0);
  If D = 0 Then
  Begin
    D := DosWrite(Hf, LongInt(@Buf), 32, LongInt(@W));
    A := DosClose(Hf);
  End;
  MakeFile := D;
End;

{ HELPINIT : bibliotheques, table, titre, tutoriel }
Procedure SetInit(Libs : String; Pht, Hmod : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 63 Do Hi[K] := 0;
  WrL(LongInt(@Hi), 44);
  WrL(LongInt(@Hi) + 4, -1);
  PutZ(LongInt(@Tutor), 'TUTOR');
  PutZ(LongInt(@Title), 'Aide d''essai');
  PutZ(LongInt(@Lib), Libs);
  WrL(LongInt(@Hi) + 8, LongInt(@Tutor));
  WrL(LongInt(@Hi) + 12, Pht);
  WrL(LongInt(@Hi) + 16, Hmod);
  WrL(LongInt(@Hi) + 32, LongInt(@Title));
  WrL(LongInt(@Hi) + 36, 1);
  WrL(LongInt(@Hi) + 40, LongInt(@Lib));
End;

Function RetCode : LongInt;
Begin
  RetCode := RdL(LongInt(@Hi) + 4);
End;

Function Info(Hh, F : LongInt) : String;
Begin
  WrB(LongInt(@TBuf), 0);
  A := HmQueryInstanceInfo(Hh, F, LongInt(@TBuf), 256);
  Info := GetZ(LongInt(@TBuf));
End;

{ Sous-table : taille 2, (Win1, Pan1), (Win2, Pan2), fin }
Procedure SetSub(P, W1, P1, W2, P2 : LongInt);
Begin
  WrW(P, 2);
  WrW(P + 2, W1); WrW(P + 4, P1);
  WrW(P + 6, W2); WrW(P + 8, P2);
  WrW(P + 10, 0); WrW(P + 12, 0);
End;

{ Entree K d'une HELPTABLE (8 octets, alignement 2) }
Procedure SetTabE(P, K, App, PSub, Ext : LongInt);
Begin
  WrW(P + K * 8, App);
  WrL(P + K * 8 + 2, PSub);
  WrW(P + K * 8 + 6, Ext);
End;

{ Image PE en memoire avec RT_HELPTABLE 7 et RT_HELPSUBTABLE 8 }
Procedure BuildImage;
Var K, R0 : LongInt;
Begin
  For K := 0 To 1023 Do Img[K] := 0;
  A := LongInt(@Img);
  WrW(A, $5A4D);
  WrL(A + $3C, 64);
  WrL(A + 64, $00004550);
  R0 := 256;
  WrL(A + 64 + 24 + 112, R0);                   { repertoire des ressources }
  { racine : types 18 et 19 }
  WrW(A + R0 + 14, 2);
  WrL(A + R0 + 16, 18); WrL(A + R0 + 20, $80000000 + 48);
  WrL(A + R0 + 24, 19); WrL(A + R0 + 28, $80000000 + 112);
  { type 18 : nom 7 -> langue -> donnees }
  WrW(A + R0 + 48 + 14, 1);
  WrL(A + R0 + 48 + 16, 7); WrL(A + R0 + 48 + 20, $80000000 + 72);
  WrW(A + R0 + 72 + 14, 1);
  WrL(A + R0 + 72 + 16, 0); WrL(A + R0 + 72 + 20, 96);
  WrL(A + R0 + 96, 512); WrL(A + R0 + 100, 14);
  { type 19 : nom 8 }
  WrW(A + R0 + 112 + 14, 1);
  WrL(A + R0 + 112 + 16, 8); WrL(A + R0 + 112 + 20, $80000000 + 136);
  WrW(A + R0 + 136 + 14, 1);
  WrL(A + R0 + 136 + 16, 0); WrL(A + R0 + 136 + 20, 160);
  WrL(A + R0 + 160, 600); WrL(A + R0 + 164, 14);
  { table d'aide : (100, sous-table 8, 900), (200, 0, 901), fin }
  WrW(A + 512, 100); WrW(A + 514, 8); WrW(A + 516, 900);
  WrW(A + 518, 200); WrW(A + 520, 0); WrW(A + 522, 901);
  WrW(A + 524, 0);
  { sous-table 8 : taille 2, (10, 1010), (11, 1011), fin }
  SetSub(A + 600, 10, 1010, 11, 1011);
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTHLP : essai de HELPMGR.DLL');

  { --- module, ordinaux --- }
  R := DosQueryModuleHandle(Z('HELPMGR'), LongInt(@H));
  Check('DosQueryModuleHandle HELPMGR', R = 0);
  Check('ordinaux 51 a 56 (ceux d''OS/2)', OrdIs(51, 'WINCREATEHELPINSTANCE') And OrdIs(52, 'WINDESTROYHELPINSTANCE') And
        OrdIs(53, 'WINQUERYHELPINSTANCE') And OrdIs(54, 'WINASSOCIATEHELPINSTANCE') And
        OrdIs(55, 'WINLOADHELPTABLE') And OrdIs(56, 'WINCREATEHELPTABLE'));
  Check('ordinaux internes 100 et 101 ; ordinal 57 inexistant', OrdIs(100, 'HMQUERYPANELID') And
        OrdIs(101, 'HMQUERYINSTANCEINFO') And (DosQueryProcAddr(H, 57, 0, LongInt(@A)) <> 0));

  { --- bibliotheques d'aide --- }
  R := MakeFile('C:\ESSAI.HLP', 'HSP');
  R2 := MakeFile('C:\MAUVAIS.HLP', 'XYZ');
  A := DosCreateDir(Z('D:\AIDE'), 0);
  B := MakeFile('D:\AIDE\ENVAIDE.HLP', 'HSP');
  Check('fichiers d''aide C:\ESSAI.HLP, C:\MAUVAIS.HLP, D:\AIDE\ENVAIDE.HLP', (R = 0) And (R2 = 0) And (B = 0));

  { --- instance avec table en memoire --- }
  SetSub(LongInt(@Sub1), 10, 1010, 11, 1011);
  For I := 0 To 63 Do Tab[I] := 0;
  SetTabE(LongInt(@Tab), 0, 100, LongInt(@Sub1), 900);
  SetTabE(LongInt(@Tab), 1, 200, 0, 901);
  SetInit('ESSAI C:\ESSAI.HLP', LongInt(@Tab), 0);
  H1 := WinCreateHelpInstance(0, LongInt(@Hi));
  R := RetCode;
  Check('WinCreateHelpInstance (handle ' + IStr(H1) + ')', (H1 <> 0) And (R = 0) And ((H1 And $FFFF0000) = $00030000));
  Check('titre, tutoriel, bibliotheques trouvees', (Info(H1, 1) = 'Aide d''essai') And (Info(H1, 3) = 'TUTOR') And
        (Info(H1, 2) = 'ESSAI.HLP C:\ESSAI.HLP'));
  Check('table d''aide copiee (2 entrees)', HmQueryInstanceInfo(H1, 4, 0, 0) = 2);
  Check('panneaux : sous-table (1010, 1011), aide etendue (900, 901), inconnu (0)',
        (HmQueryPanelId(H1, 100, 10) = 1010) And (HmQueryPanelId(H1, 100, 11) = 1011) And
        (HmQueryPanelId(H1, 100, 12) = 900) And (HmQueryPanelId(H1, 200, 10) = 901) And
        (HmQueryPanelId(H1, 300, 1) = 0));
  SetSub(LongInt(@Sub1), 77, 7777, 0, 0);
  Check('table copiee : independante de l''original', HmQueryPanelId(H1, 100, 10) = 1010);

  { --- HELP=D:\AIDE --- }
  SetInit('ENVAIDE', 0, 0);
  H2 := WinCreateHelpInstance(0, LongInt(@Hi));
  R := RetCode;
  Check('bibliotheque trouvee dans HELP (D:\AIDE)', (H2 <> 0) And (R = 0) And (Info(H2, 2) = 'D:\AIDE\ENVAIDE.HLP'));

  { --- erreurs de creation --- }
  SetInit('NEXISTE', 0, 0);
  A := WinCreateHelpInstance(0, LongInt(@Hi));
  R := RetCode;
  Check('bibliotheque introuvable : HMERR_OPEN_LIB_FILE', (A = 0) And (R = HMERR_OPEN_LIB_FILE));
  SetInit('ESSAI MAUVAIS', 0, 0);
  A := WinCreateHelpInstance(0, LongInt(@Hi));
  R := RetCode;
  Check('bibliotheque sans signature HSP : HMERR_INVALID_LIB_FILE', (A = 0) And (R = HMERR_INVALID_LIB_FILE));
  SetInit('', 0, 0);
  WrL(LongInt(@Hi), 20);
  A := WinCreateHelpInstance(0, LongInt(@Hi));
  R := RetCode;
  B := WinCreateHelpInstance(0, 0);
  Check('HELPINIT trop court, HELPINIT nul refuses', (A = 0) And (R = HMERR_NO_MEMORY) And (B = 0));
  WrW(LongInt(@SubBad), 1);
  WrW(LongInt(@SubBad) + 2, 5);
  For I := 0 To 63 Do Tab2[I] := 0;
  SetTabE(LongInt(@Tab2), 0, 100, LongInt(@SubBad), 900);
  SetInit('', LongInt(@Tab2), 0);
  A := WinCreateHelpInstance(0, LongInt(@Hi));
  R := RetCode;
  Check('sous-table invalide (SUBITEMSIZE 1) : HMERR_HELPTABLE_UNDEFINE', (A = 0) And (R = HMERR_HELPTABLE_UNDEFINE));

  { --- associations --- }
  R := WinAssociateHelpInstance(H1, $1234);
  R2 := WinAssociateHelpInstance(H1, $5678);
  Check('WinAssociateHelpInstance (2 fenetres)', (R = 1) And (R2 = 1));
  Check('WinQueryHelpInstance : fenetres associees, fenetre inconnue', (WinQueryHelpInstance($1234) = H1) And
        (WinQueryHelpInstance($5678) = H1) And (WinQueryHelpInstance($9999) = 0) And (WinQueryHelpInstance(0) = 0));
  R := WinAssociateHelpInstance($00030099, $1234);
  R2 := WinAssociateHelpInstance(H1, 0);
  Check('instance invalide, fenetre nulle refusees', (R = 0) And (R2 = 0) And (WinQueryHelpInstance($1234) = H1));
  R := WinAssociateHelpInstance(H2, $1234);
  Check('nouvelle association de la fenetre', (R = 1) And (WinQueryHelpInstance($1234) = H2));
  R := WinAssociateHelpInstance(0, $1234);
  Check('association retiree (instance nulle)', (R = 1) And (WinQueryHelpInstance($1234) = 0));

  { --- WinCreateHelpTable --- }
  SetSub(LongInt(@Sub2), 20, 2020, 21, 2021);
  For I := 0 To 63 Do Tab2[I] := 0;
  SetTabE(LongInt(@Tab2), 0, 300, LongInt(@Sub2), 950);
  R := WinCreateHelpTable(H1, LongInt(@Tab2));
  Check('WinCreateHelpTable : nouvelle table (1 entree)', (R = 1) And (HmQueryInstanceInfo(H1, 4, 0, 0) = 1) And
        (HmQueryPanelId(H1, 300, 21) = 2021) And (HmQueryPanelId(H1, 100, 10) = 0));
  R := WinCreateHelpTable($00030099, LongInt(@Tab2));
  R2 := WinCreateHelpTable(H1, 0);
  Check('WinCreateHelpTable : instance invalide, table nulle refusees', (R = 0) And (R2 = 0));

  { --- WinLoadHelpTable (ressources d'un module) --- }
  BuildImage;
  R := WinLoadHelpTable(H1, 7, LongInt(@Img));
  Check('WinLoadHelpTable : RT_HELPTABLE 7 et RT_HELPSUBTABLE 8', (R = 1) And (HmQueryInstanceInfo(H1, 4, 0, 0) = 2) And
        (HmQueryPanelId(H1, 100, 10) = 1010) And (HmQueryPanelId(H1, 100, 11) = 1011) And
        (HmQueryPanelId(H1, 100, 3) = 900) And (HmQueryPanelId(H1, 200, 10) = 901));
  R := WinLoadHelpTable(H1, 99, LongInt(@Img));
  R2 := WinLoadHelpTable($00030099, 7, LongInt(@Img));
  Check('WinLoadHelpTable : table absente, instance invalide refusees', (R = 0) And (R2 = 0) And
        (HmQueryInstanceInfo(H1, 4, 0, 0) = 2));
  SetInit('', LongInt($FFFF0007), LongInt(@Img));
  H3 := WinCreateHelpInstance(0, LongInt(@Hi));
  R := RetCode;
  Check('WinCreateHelpInstance : table de ressource FFFF0007h', (H3 <> 0) And (R = 0) And
        (HmQueryPanelId(H3, 100, 11) = 1011));
  SetInit('', LongInt($FFFF0063), LongInt(@Img));
  A := WinCreateHelpInstance(0, LongInt(@Hi));
  R := RetCode;
  Check('table de ressource absente : HMERR_HELPTABLE_UNDEFINE', (A = 0) And (R = HMERR_HELPTABLE_UNDEFINE));

  { --- WinDestroyHelpInstance --- }
  R := WinAssociateHelpInstance(H1, $1234);
  R := WinDestroyHelpInstance(H1);
  R2 := WinDestroyHelpInstance(H1);
  Check('WinDestroyHelpInstance, puis deuxieme appel refuse', (R = 1) And (R2 = 0));
  Check('instance detruite : associations retirees, handle perime', (WinQueryHelpInstance($1234) = 0) And
        (WinQueryHelpInstance($5678) = 0) And (HmQueryPanelId(H1, 100, 10) = 0) And
        (HmQueryInstanceInfo(H1, 1, LongInt(@TBuf), 64) = -1));
  SetInit('ESSAI', 0, 0);
  A := WinCreateHelpInstance(0, LongInt(@Hi));
  Check('place reutilisee : nouveau handle', (A <> 0) And (A <> H1) And ((A And $FF) = (H1 And $FF)));
  B := WinDestroyHelpInstance(A);

  { --- nombre d'instances --- }
  N := 0;
  For I := 0 To 9 Do
  Begin
    SetInit('', 0, 0);
    Hs[I] := WinCreateHelpInstance(0, LongInt(@Hi));
    If Hs[I] <> 0 Then Inc(N);
  End;
  R := RetCode;
  Check('8 instances au plus (' + IStr(N + 2) + ' creees), puis HMERR_NO_MEMORY', (N = 6) And (R = HMERR_NO_MEMORY));
  For I := 0 To 9 Do
    If Hs[I] <> 0 Then A := WinDestroyHelpInstance(Hs[I]);
  A := WinDestroyHelpInstance(H2);
  A := WinDestroyHelpInstance(H3);
  A := DosDelete(Z('C:\ESSAI.HLP'));
  A := DosDelete(Z('C:\MAUVAIS.HLP'));
  A := DosDelete(Z('D:\AIDE\ENVAIDE.HLP'));
  A := DosDeleteDir(Z('D:\AIDE'));

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTHLP : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
