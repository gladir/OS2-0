{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de MSG.DLL sous OS/2-0.
}

Program TESTMSG;

{$R-,S-,I-}

{ Compilation : OS2PC TESTMSG.PAS   (produit TESTMSG.EXE)

  TESTMSG [unite]  verifie les 9 points d'entree de MSG.DLL avec des
                   fichiers de messages au format MKMSGF qu'il fabrique
                   sur l'unite indiquee (D: par defaut, disque virtuel
                   HPFS) : index de mots et de doubles mots, fichier
                   invalide, segment de messages en memoire, recherche
                   dans le repertoire courant, messages systeme integres
                   (OSO001.MSG), insertion des variables, coupure des
                   lignes a l'ecran et pages de codes. }

Function Dos16PutMessage(H, Cb, PBuf : LongInt) : LongInt; External 'MSG';
Function Dos16TrueGetMessage(PTab, CTab, PBuf, Cb, Num, PFile, PcbMsg, PSeg : LongInt) : LongInt; External 'MSG';
Function DosInsMessage(PTab, CTab, PMsg, CbMsg, PBuf, CbBuf, PcbMsg : LongInt) : LongInt; External 'MSG';
Function DosInsertMessage(PTab, CTab, PMsg, CbMsg, PBuf, CbBuf, PcbMsg : LongInt) : LongInt; External 'MSG';
Function DosPutMessage(H, Cb, PBuf : LongInt) : LongInt; External 'MSG';
Function DosTrueGetMessage(PTab, CTab, PBuf, Cb, Num, PFile, PcbMsg, PSeg : LongInt) : LongInt; External 'MSG';
Function Dos16IQueryMessageCP(PB, Cb, PFile, PcbBuf, PSeg : LongInt) : LongInt; External 'MSG';
Function DosIQueryMessageCP(PB, Cb, PFile, PcbBuf, PSeg : LongInt) : LongInt; External 'MSG';
Function DosCloseMessageFile(PFile : LongInt) : LongInt; External 'MSG';

Function DcGetMessage(PTab, CTab, PBuf, Cb, Num, PFile, PcbMsg : LongInt) : LongInt; External 'DOSCALLS' Name 'DosGetMessage';
Function DcQueryMessageCP(PB, Cb, PFile, PcbBuf : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryMessageCP';
Function DcInsertMessage(PTab, CTab, PMsg, CbMsg, PBuf, CbBuf, PcbMsg : LongInt) : LongInt; External 'DOSCALLS' Name 'DosInsertMessage';

Function VioGetCurPos(PRow, PCol, Hvio : LongInt) : LongInt; External 'VIOCALLS';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetDefaultDisk(Disk : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PMap : LongInt) : LongInt; External 'DOSCALLS';

Const
  ERROR_INVALID_PARAMETER = 87;
  ERROR_BUFFER_OVERFLOW = 111;
  ERROR_MR_MSG_TOO_LONG = 316;
  ERROR_MR_MID_NOT_FOUND = 317;
  ERROR_MR_UN_ACC_MSGF = 318;
  ERROR_MR_INV_MSGF_FORMAT = 319;
  ERROR_MR_INV_IVCOUNT = 320;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, Row, Col, Disk, Map : LongInt;
  Drv : String;
  Name : Array[0..127] Of Byte;
  Img : Array[0..2047] Of Byte;
  ImgLen : LongInt;
  Seg : Array[0..2047] Of Byte;
  Buf : Array[0..1023] Of Byte;
  Txt : Array[0..1023] Of Byte;
  Tab : Array[0..9] Of LongInt;
  V1, V2, V3 : Array[0..31] Of Byte;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;
  MsgT : Array[0..7] Of String[60];

Function IStr(V : LongInt) : String;
Var T : String;
Begin
  Str(V, T);
  IStr := T;
End;

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
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

{ Contenu du tampon (N octets), fins de ligne visibles }
Function BufStr(Len : LongInt) : String;
Var T : String; K : LongInt;
Begin
  T := '';
  For K := 0 To Len - 1 Do
    If Buf[K] = 13 Then T := T + '\r'
    Else If Buf[K] = 10 Then T := T + '\n'
    Else T := T + Chr(Buf[K]);
  BufStr := T;
End;

{ --- fabrication d'un fichier de messages (format MKMSGF) --- }
Procedure BuildImg(Off16 : Boolean; FName : String);
Const NMsg = 6;
Var K, W, Ci, P, L : LongInt;
Begin
  For K := 0 To 2047 Do Img[K] := 0;
  Img[0] := $FF;
  PutZ(LongInt(@Img) + 1, 'MKMSGF');
  Img[8] := Ord('T'); Img[9] := Ord('S'); Img[10] := Ord('T');
  WrW(LongInt(@Img) + $0B, NMsg);
  WrW(LongInt(@Img) + $0D, 100);
  If Off16 Then Begin Img[$0F] := 1; W := 2 End Else Begin Img[$0F] := 0; W := 4 End;
  WrW(LongInt(@Img) + $10, 2);
  WrW(LongInt(@Img) + $12, $1F);
  Ci := $1F + NMsg * W;
  WrW(LongInt(@Img) + $14, Ci);
  { bloc du pays : 1 octet/caractere, famille 12, version 1, pages 850 et 437 }
  Img[Ci] := 1;
  WrW(LongInt(@Img) + Ci + 3, 12);
  WrW(LongInt(@Img) + Ci + 5, 1);
  WrW(LongInt(@Img) + Ci + 7, 2);
  WrW(LongInt(@Img) + Ci + 9, 850);
  WrW(LongInt(@Img) + Ci + 11, 437);
  PutZ(LongInt(@Img) + Ci + 41, FName);
  P := Ci + 54;
  For K := 0 To NMsg - 1 Do
  Begin
    If Off16 Then WrW(LongInt(@Img) + $1F + K * 2, P)
    Else WrL(LongInt(@Img) + $1F + K * 4, P);
    L := Length(MsgT[K]);
    PutZ(LongInt(@Img) + P, MsgT[K]);
    P := P + L;
  End;
  ImgLen := P;
End;

Function WriteFile(FName : String; Len : LongInt) : LongInt;
Var Hf, Act, W, Rc : LongInt;
Begin
  Rc := DosOpen(Z(FName), LongInt(@Hf), LongInt(@Act), 0, 0, $12, $41, 0);
  If Rc = 0 Then
  Begin
    Rc := DosWrite(Hf, LongInt(@Img), Len, LongInt(@W));
    DosClose(Hf);
  End;
  WriteFile := Rc;
End;

{ DosTrueGetMessage avec les variables V1, V2 }
Function Get(Num : LongInt; FName : String; CTab, Cb : LongInt) : LongInt;
Begin
  N := 0;
  For I := 0 To 255 Do Buf[I] := 0;
  Get := DosTrueGetMessage(LongInt(@Tab), CTab, LongInt(@Buf), Cb, Num, Z(FName), LongInt(@N), 0);
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  Drv := 'D:';
  If ParamCount > 0 Then Drv := Copy(ParamStr(1), 1, 1) + ':';
  WriteLn('TESTMSG : essai de MSG.DLL (fichiers sur ', Drv, ')');

  { --- module et ordinaux --- }
  R := DosQueryModuleHandle(Z('MSG'), LongInt(@H));
  If R <> 0 Then
  Begin
    Tab[0] := 0;
    R := DosInsertMessage(LongInt(@Tab), 0, Z('x'), 1, LongInt(@Buf), 10, LongInt(@N));
    R := DosQueryModuleHandle(Z('MSG'), LongInt(@H));
  End;
  Check('DosQueryModuleHandle MSG', R = 0);
  Check('ordinaux 1 Dos16PutMessage, 2 Dos16TrueGetMessage, 3 DosInsMessage, 4 DosInsertMessage',
        OrdIs(1, 'Dos16PutMessage') And OrdIs(2, 'Dos16TrueGetMessage') And OrdIs(3, 'DosInsMessage') And
        OrdIs(4, 'DosInsertMessage'));
  Check('ordinaux 5 DosPutMessage, 6 DosTrueGetMessage, 7 Dos16IQueryMessageCP, 8 DosIQueryMessageCP, 9 DosCloseMessageFile',
        OrdIs(5, 'DosPutMessage') And OrdIs(6, 'DosTrueGetMessage') And OrdIs(7, 'Dos16IQueryMessageCP') And
        OrdIs(8, 'DosIQueryMessageCP') And OrdIs(9, 'DosCloseMessageFile'));
  Check('alias Dos32PutMessage, Dos32TrueGetMessage, Dos32IQueryMessageCP, Dos32InsertMessage, Dos32CloseMessageFile',
        OrdIs(5, 'Dos32PutMessage') And OrdIs(6, 'Dos32TrueGetMessage') And OrdIs(8, 'Dos32IQueryMessageCP') And
        OrdIs(4, 'Dos32InsertMessage') And OrdIs(9, 'Dos32CloseMessageFile') And OrdIs(3, 'Dos16InsMessage'));
  Check('ordinal 10 inexistant', DosQueryProcAddr(H, 10, 0, LongInt(@A)) <> 0);

  { --- fichiers de messages --- }
  MsgT[0] := 'EFichier %1 introuvable sur %2.' + Chr(13) + Chr(10);
  MsgT[1] := 'WAttention : disque presque plein.' + Chr(13) + Chr(10);
  MsgT[2] := 'IInformation %1' + Chr(13) + Chr(10);
  MsgT[3] := 'PContinuer (O/N) ? %0' + Chr(13) + Chr(10);
  MsgT[4] := '?';
  MsgT[5] := 'HAide : tapez HELP.' + Chr(13) + Chr(10);
  BuildImg(True, 'TEST.MSG');
  R := WriteFile(Drv + '\TEST.MSG', ImgLen);
  Check('fichier ' + Drv + '\TEST.MSG (index de mots)', R = 0);
  BuildImg(False, 'TEST32.MSG');
  R := WriteFile(Drv + '\TEST32.MSG', ImgLen);
  For I := 0 To 99 Do Img[I] := Ord('x');
  R2 := WriteFile(Drv + '\BAD.MSG', 100);
  Check('fichiers TEST32.MSG (index de doubles mots) et BAD.MSG (invalide)', (R = 0) And (R2 = 0));

  { --- DosTrueGetMessage --- }
  PutZ(LongInt(@V1), 'A.TXT');
  PutZ(LongInt(@V2), 'D:');
  PutZ(LongInt(@V3), 'trois');
  Tab[0] := LongInt(@V1); Tab[1] := LongInt(@V2); Tab[2] := LongInt(@V3);
  R := Get(100, Drv + '\TEST.MSG', 2, 256);
  Check('erreur E avec prefixe et variables : "' + BufStr(N) + '"',
        (R = 0) And (BufStr(N) = 'TST0100: Fichier A.TXT introuvable sur D:.\r\n'));
  R := Get(101, Drv + '\TEST.MSG', 0, 256);
  Check('avertissement W : "' + BufStr(N) + '"', (R = 0) And (BufStr(N) = 'TST0101: Attention : disque presque plein.\r\n'));
  R := Get(102, Drv + '\TEST.MSG', 1, 256);
  Check('information I sans prefixe : "' + BufStr(N) + '"', (R = 0) And (BufStr(N) = 'Information A.TXT\r\n'));
  R := Get(103, Drv + '\TEST.MSG', 0, 256);
  Check('invite P, %0 : sans fin de ligne : "' + BufStr(N) + '"', (R = 0) And (BufStr(N) = 'Continuer (O/N) ? '));
  R := Get(105, Drv + '\TEST.MSG', 0, 256);
  Check('aide H (dernier message) : "' + BufStr(N) + '"', (R = 0) And (BufStr(N) = 'Aide : tapez HELP.\r\n'));
  R := Get(104, Drv + '\TEST.MSG', 0, 256);
  Check('message inutilise (?) : ' + BufStr(N), (R = ERROR_MR_MID_NOT_FOUND) And (Pos('SYS0317', BufStr(N)) = 1) And
        (Pos('0104', BufStr(N)) > 0));
  R := Get(999, Drv + '\TEST.MSG', 0, 256);
  Check('message 999 introuvable (SYS0317)', (R = ERROR_MR_MID_NOT_FOUND) And (Pos('0999', BufStr(N)) > 0));
  R := Get(100, Drv + '\NUL.MSG', 0, 256);
  Check('fichier absent : ' + BufStr(N), (R = ERROR_MR_UN_ACC_MSGF) And (Pos('SYS0318', BufStr(N)) = 1));
  R := Get(100, Drv + '\BAD.MSG', 0, 256);
  Check('fichier invalide (SYS0319)', (R = ERROR_MR_INV_MSGF_FORMAT) And (Pos('SYS0319', BufStr(N)) = 1));
  R := Get(100, Drv + '\TEST32.MSG', 2, 256);
  Check('index de doubles mots : "' + BufStr(N) + '"', (R = 0) And (Pos('TST0100: Fichier A.TXT', BufStr(N)) = 1));
  R := Get(105, Drv + '\TEST32.MSG', 0, 256);
  Check('index de doubles mots, dernier message', (R = 0) And (BufStr(N) = 'Aide : tapez HELP.\r\n'));
  R := Get(100, Drv + '\TEST.MSG', 2, 10);
  Check('tampon de 10 octets : message tronque "' + BufStr(N) + '"', (R = ERROR_MR_MSG_TOO_LONG) And (N = 10) And
        (BufStr(N) = 'TST0100: F'));
  R := Get(100, Drv + '\TEST.MSG', 10, 256);
  Check('10 variables refusees', R = ERROR_MR_INV_IVCOUNT);
  R := DosTrueGetMessage(LongInt(@Tab), 0, 0, 256, 100, Z(Drv + '\TEST.MSG'), LongInt(@N), 0);
  Check('tampon nul refuse', R = ERROR_INVALID_PARAMETER);

  { recherche dans le repertoire courant, puis messages systeme integres }
  DosQueryCurrentDisk(LongInt(@Disk), LongInt(@Map));
  DosSetDefaultDisk(Ord(Drv[1]) - 64);
  R := Get(102, 'TEST.MSG', 1, 256);
  DosSetDefaultDisk(Disk);
  Check('fichier sans chemin trouve dans le repertoire courant', (R = 0) And (BufStr(N) = 'Information A.TXT\r\n'));
  PutZ(LongInt(@V1), 'ESSAI.DAT');
  R := Get(2, 'OSO001.MSG', 1, 256);
  Check('OSO001.MSG : message systeme integre "' + BufStr(N) + '"',
        (R = 0) And (BufStr(N) = 'SYS0002: Le systeme ne trouve pas le fichier ESSAI.DAT.\r\n'));
  PutZ(LongInt(@V1), 'A.TXT');

  { segment de messages en memoire (nom MEM.MSG, absent du disque) }
  MsgT[0] := 'ESegment : %1' + Chr(13) + Chr(10);
  BuildImg(True, 'MEM.MSG');
  For I := 0 To ImgLen Do Seg[I] := Img[I];
  N := 0;
  R := DosTrueGetMessage(LongInt(@Tab), 1, LongInt(@Buf), 256, 100, Z('MEM.MSG'), LongInt(@N), LongInt(@Seg));
  Check('segment de messages : "' + BufStr(N) + '"', (R = 0) And (BufStr(N) = 'TST0100: Segment : A.TXT\r\n'));
  R := DosTrueGetMessage(LongInt(@Tab), 1, LongInt(@Buf), 256, 105, Z('MEM.MSG'), LongInt(@N), LongInt(@Seg));
  Check('segment de messages, dernier message (fin par 0)', (R = 0) And (BufStr(N) = 'Aide : tapez HELP.\r\n'));
  R := DosTrueGetMessage(LongInt(@Tab), 1, LongInt(@Buf), 256, 100, Z('AUTRE.MSG'), LongInt(@N), LongInt(@Seg));
  Check('segment d''un autre fichier ignore', R = ERROR_MR_UN_ACC_MSGF);

  { point d'entree 1.x : longueur USHORT }
  N := -1;
  R := Dos16TrueGetMessage(LongInt(@Tab), 0, LongInt(@Buf), 256, 101, Z(Drv + '\TEST.MSG'), LongInt(@N), 0);
  Check('Dos16TrueGetMessage : longueur dans un mot (' + IStr(N And $FFFF) + ')',
        (R = 0) And ((N And $FFFF) = 44) And ((N Shr 16) And $FFFF = $FFFF));

  { --- DosInsertMessage / DosInsMessage --- }
  PutZ(LongInt(@Txt), '%1 et %2, pas %3 ; 100%');
  R := DosInsertMessage(LongInt(@Tab), 2, LongInt(@Txt), 23, LongInt(@Buf), 256, LongInt(@N));
  Check('DosInsertMessage : "' + BufStr(N) + '"', (R = 0) And (BufStr(N) = 'A.TXT et D:, pas %3 ; 100%'));
  R := DosInsertMessage(LongInt(@Tab), 3, LongInt(@Txt), 23, LongInt(@Buf), 8, LongInt(@N));
  Check('DosInsertMessage tampon trop petit', (R = ERROR_MR_MSG_TOO_LONG) And (N = 8) And (BufStr(N) = 'A.TXT et'));
  R := DosInsertMessage(LongInt(@Tab), 10, LongInt(@Txt), 23, LongInt(@Buf), 256, LongInt(@N));
  Check('DosInsertMessage 10 variables refusees', R = ERROR_MR_INV_IVCOUNT);
  N := -1;
  R := DosInsMessage(LongInt(@Tab), 3, LongInt(@Txt), 23, LongInt(@Buf), 256, LongInt(@N));
  Check('DosInsMessage (1.x, longueur USHORT) : "' + BufStr(N And $FFFF) + '"',
        (R = 0) And ((N Shr 16) And $FFFF = $FFFF) And (BufStr(N And $FFFF) = 'A.TXT et D:, pas trois ; 100%'));
  R := DcInsertMessage(LongInt(@Tab), 1, LongInt(@Txt), 23, LongInt(@Buf), 256, LongInt(@N));
  Check('DosInsertMessage de DOSCALLS.DLL (transmis a MSG)', (R = 0) And (Pos('A.TXT et %2', BufStr(N)) = 1));

  { --- DosGetMessage et DosQueryMessageCP de DOSCALLS.DLL --- }
  R := DcGetMessage(LongInt(@Tab), 2, LongInt(@Buf), 256, 100, Z(Drv + '\TEST.MSG'), LongInt(@N));
  Check('DosGetMessage de DOSCALLS.DLL', (R = 0) And (Pos('TST0100: Fichier A.TXT', BufStr(N)) = 1));

  { --- pages de codes --- }
  For I := 0 To 31 Do Buf[I] := 0;
  R := DosIQueryMessageCP(LongInt(@Buf), 64, Z(Drv + '\TEST.MSG'), LongInt(@N), 0);
  Check('DosIQueryMessageCP : 2 pages (850, 437), langue 12 version 1', (R = 0) And (N = 10) And
        (RdW(LongInt(@Buf)) = 2) And (RdW(LongInt(@Buf) + 2) = 850) And (RdW(LongInt(@Buf) + 4) = 437) And
        (RdW(LongInt(@Buf) + 6) = 12) And (RdW(LongInt(@Buf) + 8) = 1));
  R := DosIQueryMessageCP(LongInt(@Buf), 6, Z(Drv + '\TEST.MSG'), LongInt(@N), 0);
  Check('DosIQueryMessageCP tampon trop petit', R = ERROR_BUFFER_OVERFLOW);
  N := -1;
  R := Dos16IQueryMessageCP(LongInt(@Buf), 64, Z(Drv + '\TEST.MSG'), LongInt(@N), 0);
  Check('Dos16IQueryMessageCP (longueur USHORT)', (R = 0) And ((N And $FFFF) = 10) And ((N Shr 16) And $FFFF = $FFFF));
  R := DosIQueryMessageCP(LongInt(@Buf), 64, Z('MEM.MSG'), LongInt(@N), LongInt(@Seg));
  Check('DosIQueryMessageCP du segment de messages', (R = 0) And (RdW(LongInt(@Buf)) = 2));
  R := DosIQueryMessageCP(LongInt(@Buf), 64, Z(Drv + '\NUL.MSG'), LongInt(@N), 0);
  Check('DosIQueryMessageCP fichier absent', R = ERROR_MR_UN_ACC_MSGF);
  R := DcQueryMessageCP(LongInt(@Buf), 64, Z(Drv + '\TEST32.MSG'), LongInt(@N));
  Check('DosQueryMessageCP de DOSCALLS.DLL', (R = 0) And (RdW(LongInt(@Buf) + 2) = 850));

  { --- DosPutMessage --- }
  PutZ(LongInt(@Txt), 'Message ecrit dans un fichier' + Chr(13) + Chr(10));
  R := DosOpen(Z(Drv + '\PUT.TXT'), LongInt(@A), LongInt(@B), 0, 0, $12, $42, 0);
  R2 := DosPutMessage(A, 31, LongInt(@Txt));
  R := Dos16PutMessage(A, 31, LongInt(@Txt));
  DosClose(A);
  R := DosOpen(Z(Drv + '\PUT.TXT'), LongInt(@A), LongInt(@B), 0, 0, 1, $40, 0);
  N := 0;
  DosRead(A, LongInt(@Buf), 256, LongInt(@N));
  DosClose(A);
  Check('DosPutMessage et Dos16PutMessage dans un fichier (' + IStr(N) + ' octets)', (R2 = 0) And (N = 62) And
        (Copy(BufStr(N), 1, 29) = 'Message ecrit dans un fichier'));
  R := DosPutMessage(999, 3, LongInt(@Txt));
  Check('DosPutMessage handle invalide refuse', R <> 0);
  { ecran : 20 mots de 5 lettres ; la ligne est coupee avant MOT14 }
  For I := 1 To 20 Do
  Begin
    A := (I - 1) * 6;
    Txt[A] := Ord('M'); Txt[A + 1] := Ord('O'); Txt[A + 2] := Ord('T');
    Txt[A + 3] := Ord('0') + I Div 10; Txt[A + 4] := Ord('0') + I Mod 10;
    Txt[A + 5] := 32;
  End;
  Txt[119] := 13; Txt[120] := 10;
  R := DosPutMessage(1, 121, LongInt(@Txt));
  VioGetCurPos(LongInt(@Row), LongInt(@Col), 0);
  A := $B8000 + (Row - 1) * 160;
  B := $B8000 + (Row - 2) * 160;
  Check('DosPutMessage a l''ecran : coupure entre les mots (ligne suivante : MOT14)', (R = 0) And
        (RdB(A) = Ord('M')) And (RdB(A + 6) = Ord('1')) And (RdB(A + 8) = Ord('4')) And
        (RdB(B + 152) = Ord('3')) And (RdB(B) = Ord('M')));

  { --- DosCloseMessageFile --- }
  R := DosCloseMessageFile(Z(Drv + '\TEST.MSG'));
  R2 := DosCloseMessageFile(Z(Drv + '\TEST.MSG'));
  Check('DosCloseMessageFile, puis fichier deja ferme refuse', (R = 0) And (R2 = ERROR_INVALID_PARAMETER));
  R := DosDelete(Z(Drv + '\TEST.MSG'));
  Check('fichier ferme : DosDelete', R = 0);
  R := DosCloseMessageFile(0);
  Check('DosCloseMessageFile(0) : tous les fichiers', R = 0);
  DosDelete(Z(Drv + '\TEST32.MSG'));
  DosDelete(Z(Drv + '\BAD.MSG'));
  DosDelete(Z(Drv + '\PUT.TXT'));

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTMSG : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
