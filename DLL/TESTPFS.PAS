{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de SPOOLCP.DLL sous OS/2-0.
}

Program TESTPFS;

{$R-,S-,I-}

{ Compilation : OS2PC TESTPFS.PAS   (produit TESTPFS.EXE)

  TESTPFS [unite]  verifie les 5 fonctions de SPOOLCP.DLL avec un fichier
                   de polices fabrique sur l'unite (D: par defaut) : les
                   sequences sont ecrites sur LPT1 (avec QEMU :
                   -parallel file:lpt.txt recoit 1B 3D 00 05 41 42 43 44
                   45 1B 25 31, 1B 25 31, 1B 36, 1B 40, puis de nouveau
                   1B 3D 00 05 41 42 43 44 45 1B 25 31) et sur un fichier
                   de spoule. }

Function DosPFSCloseUser(Sfn, PName, Reserved : LongInt) : LongInt; External 'SPOOLCP';
Function DosPFSQueryAct(PName, PCp, PFont, Sfn, Reserved : LongInt) : LongInt; External 'SPOOLCP';
Function DosPFSInit(PHw, PFile, PType, PName, Reserved : LongInt) : LongInt; External 'SPOOLCP';
Function DosPFSActivate(Sfn, PcbWritten, PName, Cp, Font, Reserved : LongInt) : LongInt; External 'SPOOLCP';
Function DosPFSVerifyFont(PName, Cp, Font, Reserved : LongInt) : LongInt; External 'SPOOLCP';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';

Const
  ERROR_INVALID_PARAMETER = 87;
  ERROR_CPSIO_CODE_PAGE_INVALID = 65026;
  ERROR_CPSIO_FONT_ID_INVALID = 65028;
  ERROR_CPSIO_INVALID_PTR_NAME = 65034;
  ERROR_CPSIO_NOT_ACTIVE = 65037;
  ERROR_CPSIO_PID_NOT_FOUND = 65040;
  ERROR_CPSIO_READ_CTL_SEQ = 65043;
  ERROR_CPSIO_READ_FNT_DEF = 65045;
  ERROR_CPSIO_WRITE_HANDLE_BAD = 65049;
  ERROR_CPSIO_NO_FONT_SWIT = 65078;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, C, Hl, Hs, Act, Cp, Font : LongInt;
  Drv : String;
  Name, Name2, Name3 : Array[0..127] Of Byte;
  Hw : Array[0..15] Of Byte;
  Txt : Array[0..1023] Of Byte;
  Buf : Array[0..63] Of Byte;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var T : String;
Begin
  Str(V, T);
  IStr := T;
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

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name), S);
  Z := LongInt(@Name);
End;

Function Z2(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name2), S);
  Z2 := LongInt(@Name2);
End;

Function Z3(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name3), S);
  Z3 := LongInt(@Name3);
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

{ Ecrire un fichier texte (lignes separees par |) }
Function MakeFile(FName, Content : String) : LongInt;
Var Hf, K, N, W, Rc : LongInt;
Begin
  N := 0;
  For K := 1 To Length(Content) Do
    If Content[K] = '|' Then
    Begin
      Txt[N] := 13; Txt[N + 1] := 10; N := N + 2;
    End
    Else
    Begin
      Txt[N] := Ord(Content[K]); Inc(N);
    End;
  Rc := DosOpen(Z(FName), LongInt(@Hf), LongInt(@Act), 0, 0, $12, $42, 0);
  If Rc = 0 Then
  Begin
    Rc := DosWrite(Hf, LongInt(@Txt), N, LongInt(@W));
    DosClose(Hf);
  End;
  MakeFile := Rc;
End;

Function Activate(Sfn, PCp, PFont : LongInt) : LongInt;
Begin
  N := -1;
  Activate := DosPFSActivate(Sfn, LongInt(@N), Z('LPT1'), PCp, PFont, 0);
End;

Function Query(Sfn : LongInt) : LongInt;
Begin
  Cp := -1; Font := -1;
  Query := DosPFSQueryAct(Z('LPT1'), LongInt(@Cp), LongInt(@Font), Sfn, 0);
End;

Function Verify(PCp, PFont : LongInt) : LongInt;
Begin
  Verify := DosPFSVerifyFont(Z('LPT1'), PCp, PFont, 0);
End;

Function Init(FName, PType : String) : LongInt;
Begin
  Init := DosPFSInit(LongInt(@Hw), Z2(FName), Z3(PType), Z('LPT1'), 0);
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  Drv := 'D:';
  If ParamCount > 0 Then Drv := Copy(ParamStr(1), 1, 1) + ':';
  WriteLn('TESTPFS : essai de SPOOLCP.DLL (fichiers sur ', Drv, ')');

  { --- module et ordinaux --- }
  R := DosQueryModuleHandle(Z('SPOOLCP'), LongInt(@H));
  Check('DosQueryModuleHandle SPOOLCP', R = 0);
  Check('ordinaux 1 DosPFSCloseUser, 2 DosPFSQueryAct, 3 DosPFSInit, 4 DosPFSActivate, 5 DosPFSVerifyFont',
        OrdIs(1, 'DosPFSCloseUser') And OrdIs(2, 'DosPFSQueryAct') And OrdIs(3, 'DosPFSInit') And
        OrdIs(4, 'DosPFSActivate') And OrdIs(5, 'DosPFSVerifyFont'));

  { --- fichiers de polices --- }
  R := MakeFile(Drv + '\4201.PFS', '; polices de l''imprimante 4201|TYPE 4201|FONT 0 0 1B 40|' +
       'FONT 437 0 1B 36|FONT 850 0 1B 37 ; page 850|LOAD 850 1 1B 3D 00 05 41 42 43 44 45|' +
       'FONT 850 1 1B 25 31|');
  R2 := MakeFile(Drv + '\MAUVAIS.PFS', 'FONT 850 0 1B 4G|');
  Check('fichiers de polices 4201.PFS et MAUVAIS.PFS', (R = 0) And (R2 = 0));
  { polices residentes : 437/0 et 863/1 }
  WrW(LongInt(@Hw), 2);
  WrW(LongInt(@Hw) + 2, 437); WrW(LongInt(@Hw) + 4, 0);
  WrW(LongInt(@Hw) + 6, 863); WrW(LongInt(@Hw) + 8, 1);

  { --- avant DosPFSInit --- }
  R := Verify(437, 0);
  R2 := DosPFSVerifyFont(Z('LPT9'), 437, 0, 0);
  Check('DosPFSVerifyFont sans commutateur ; imprimante invalide', (R = ERROR_CPSIO_NO_FONT_SWIT) And
        (R2 = ERROR_CPSIO_INVALID_PTR_NAME));

  { --- DosPFSInit --- }
  R := Init(Drv + '\NEXISTE.PFS', '4201');
  Check('DosPFSInit fichier de polices absent', R = ERROR_CPSIO_READ_FNT_DEF);
  R := Init(Drv + '\MAUVAIS.PFS', '4201');
  Check('DosPFSInit sequence invalide (4G)', R = ERROR_CPSIO_READ_CTL_SEQ);
  R := Init(Drv + '\4201.PFS', '5202');
  Check('DosPFSInit fichier d''un autre type d''imprimante', R = ERROR_CPSIO_READ_FNT_DEF);
  R := DosPFSInit(LongInt(@Hw), Z2(Drv + '\4201.PFS'), Z3('4201'), Z('LPT1'), 1);
  Check('DosPFSInit ulReserved <> 0 refuse', R = ERROR_INVALID_PARAMETER);
  R := Init(Drv + '\4201.PFS', '4201');
  Check('DosPFSInit LPT1, type 4201, 2 polices residentes', R = 0);

  { --- DosPFSVerifyFont --- }
  R := Verify(437, 0);
  R2 := Verify(850, 1);
  A := Verify(863, 1);
  Check('DosPFSVerifyFont : 437/0 (residente et FONT), 850/1 (LOAD), 863/1 (residente)', (R = 0) And
        (R2 = 0) And (A = 0));
  R := Verify(850, 9);
  R2 := Verify(999, 0);
  Check('DosPFSVerifyFont police ou page de codes inconnue', (R = ERROR_CPSIO_FONT_ID_INVALID) And
        (R2 = ERROR_CPSIO_CODE_PAGE_INVALID));

  { --- DosPFSActivate sur LPT1 --- }
  R := DosOpen(Z('LPT1'), LongInt(@Hl), LongInt(@Act), 0, 0, 1, $41, 0);
  Check('DosOpen LPT1', R = 0);
  R := Activate(Hl, 850, 1);
  Check('DosPFSActivate 850/1 : telechargement et choix (' + IStr(N) + ' octets)', (R = 0) And (N = 12));
  R := Activate(Hl, 850, 1);
  Check('DosPFSActivate 850/1 de nouveau : choix seul (' + IStr(N) + ' octets)', (R = 0) And (N = 3));
  R := Activate(Hl, 437, 0);
  Check('DosPFSActivate 437/0 (' + IStr(N) + ' octets)', (R = 0) And (N = 2));
  R := Activate(Hl, 0, 0);
  R2 := Query(Hl);
  Check('DosPFSActivate 0/0 (etat par defaut) ; DosPFSQueryAct 0/0', (R = 0) And (N = 2) And (R2 = 0) And
        (Cp = 0) And (Font = 0));
  R := Activate(Hl, 863, 1);
  R2 := Query(Hl);
  Check('police residente sans sequence (0 octet) ; DosPFSQueryAct 863/1', (R = 0) And (N = 0) And (R2 = 0) And
        (Cp = 863) And (Font = 1));
  R := Activate(Hl, 850, 9);
  Check('DosPFSActivate police inconnue', R = ERROR_CPSIO_FONT_ID_INVALID);
  R := Activate(999, 437, 0);
  Check('DosPFSActivate handle invalide', R = ERROR_CPSIO_WRITE_HANDLE_BAD);
  R := DosPFSActivate(Hl, LongInt(@N), Z('LPT2'), 437, 0, 0);
  Check('DosPFSActivate sur LPT2 (sans commutateur)', R = ERROR_CPSIO_NO_FONT_SWIT);

  { --- fichier de spoule --- }
  R := DosOpen(Z(Drv + '\SPOOL.PRN'), LongInt(@Hs), LongInt(@Act), 0, 0, $12, $42, 0);
  R2 := Activate(Hs, 850, 0);
  A := Query(Hs);
  B := Cp;
  C := Query(Hl);
  Check('fichier de spoule : DosPFSActivate 850/0 ; chaque fichier garde sa police', (R = 0) And (R2 = 0) And
        (N = 2) And (A = 0) And (B = 850) And (C = 0) And (Cp = 863));
  DosClose(Hs);
  R := DosOpen(Z(Drv + '\SPOOL.PRN'), LongInt(@Hs), LongInt(@Act), 0, 0, 1, $40, 0);
  N := 0;
  R2 := DosRead(Hs, LongInt(@Buf), 64, LongInt(@N));
  DosClose(Hs);
  Check('fichier de spoule : 1B 37', (R = 0) And (N = 2) And (Buf[0] = $1B) And (Buf[1] = $37));

  { --- DosPFSCloseUser --- }
  R := DosPFSCloseUser(Hs, Z('LPT1'), 0);
  R2 := Query(Hs);
  Check('DosPFSCloseUser ; DosPFSQueryAct : pas de police active', (R = 0) And (R2 = ERROR_CPSIO_NOT_ACTIVE));
  R := DosPFSCloseUser(Hs, Z('LPT1'), 0);
  Check('DosPFSCloseUser deja ferme', R = ERROR_CPSIO_PID_NOT_FOUND);

  { --- nouvelle initialisation : polices a telecharger de nouveau --- }
  R := Init(Drv + '\4201.PFS', '');
  R2 := Query(Hl);
  Check('DosPFSInit de nouveau (type non verifie) : polices actives oubliees', (R = 0) And
        (R2 = ERROR_CPSIO_NOT_ACTIVE));
  R := Activate(Hl, 850, 1);
  Check('DosPFSActivate 850/1 : telechargement de nouveau (' + IStr(N) + ' octets)', (R = 0) And (N = 12));
  DosClose(Hl);
  DosDelete(Z(Drv + '\4201.PFS'));
  DosDelete(Z(Drv + '\MAUVAIS.PFS'));
  DosDelete(Z(Drv + '\SPOOL.PRN'));

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTPFS : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
