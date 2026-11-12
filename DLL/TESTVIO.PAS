{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de VIOCALLS.DLL sous OS/2-0.
}

Program TESTVIO;

{$R-,S-,I-}

{ Compilation : OS2PC TESTVIO.PAS   (produit TESTVIO.EXE)

  TESTVIO   verifie les 76 fonctions de VIOCALLS.DLL : les resultats sont
            relus par VIO, directement dans la memoire de l'ecran
            (000B8000h) et dans les registres du VGA ; les modes
            graphiques (640 x 480 x 16, 320 x 200 x 256...) sont essayes
            a la fin (pels ecrits en 000A0000h). TESTVIOR.DLL sert
            de sous-systeme de remplacement (VioRegister, VioGlobalReg). }

Function VioEndPopup(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function VioGetPhysBuf(PPhys, Reserved : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetAnsi(PAnsi, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioFree(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSetAnsi(FAnsi, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioDeRegister : LongInt; External 'VIOCALLS';
Function VioScrollUp(Top, Left, Bot, Right, N, PCell, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioPrtSc(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetCurPos(PRow, PCol, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioWrtCellStr(PCells, Cb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioPopUp(PWait, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioScrollRt(Top, Left, Bot, Right, N, PCell, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioWrtCharStr(PStr, Cb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function Avs_Prtsc(PBuf, PCb, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSetCurPos(Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSrfUnblock(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSrfBlock(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioScrUnlock(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioWrtTty(PCh, Cb, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSave(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetMode(PMode, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSetMode(PMode, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioScrLock(FWait, PNot, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioReadCellStr(PBuf, PCb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSavRedrawWait(RedrawInd, PNotify, Reserved : LongInt) : LongInt; External 'VIOCALLS';
Function VioWrtNAttr(PAttr, Cb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetCurType(PInfo, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSavRedrawUndo(OwnerInd, KillInd, Reserved : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetFont(PInfo, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioReadCharStr(PBuf, PCb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetBuf(PLvb, PCb, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSetCurType(PInfo, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSetFont(PInfo, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioHetInit(Reserved : LongInt) : LongInt; External 'VIOCALLS';
Function VioModeUndo(OwnerInd, KillInd, Reserved : LongInt) : LongInt; External 'VIOCALLS';
Function VioSswSwitch(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioModeWait(ReqType, PNotify, Reserved : LongInt) : LongInt; External 'VIOCALLS';
Function Avs_PrtscToggle(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioInit(Reserved : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetCp(Reserved, PCp, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioRestore(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSetCp(Reserved, Cp, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioShowBuf(Ofs, Cb, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioScrollLf(Top, Left, Bot, Right, N, PCell, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioRegister(PMod, PEntry, Fun1, Fun2 : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetConfig(ConfigId, PInfo, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioScrollDn(Top, Left, Bot, Right, N, PCell, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioWrtCharStrAtt(PStr, Cb, Row, Col, PAttr, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetState(PState, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioPrtScToggle(Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioSetState(PState, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioWrtNCell(PCell, Cb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioWrtNChar(PCh, Cb, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioShellInit(Reserved : LongInt) : LongInt; External 'VIOCALLS';
Function VioAssociate(Hdc, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioCreatePS(PHvps, Depth, Width, Format, Attrs, Reserved : LongInt) : LongInt; External 'VIOCALLS';
Function VioDeleteSetId(Lcid, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetDeviceCellSize(PHeight, PWidth, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetOrg(PRow, PCol, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioCreateLogFont(PAttrs, Lcid, PName, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioDestroyPS(Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioQuerySetIds(PLcids, PNames, PTypes, Count, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioSetOrg(Row, Col, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioQueryFonts(PRem, PMetrics, MLen, PCount, PFace, Options, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioSetDeviceCellSize(Height, Width, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioShowPS(Depth, Width, Ofs, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioGetPSAddress(PPBuf, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioQueryConsole(PInfo, Cb, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioRedrawSize(PCb : LongInt) : LongInt; External 'VIOCALLS';
Function VioGlobalReg(PMod, PEntry, Fun1, Fun2, UsReturn : LongInt) : LongInt; External 'VIOCALLS';
Function XVioSetCAState(Hca, FState, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function XVioCheckCharType(PType, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function XVioDestroyCA(Hca, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function XVioCreateCA(PHca, PInfo, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function VioCheckCharType(PType, Row, Col, Hvio : LongInt) : LongInt; External 'VIOCALLS';
Function XVioGetCAState(PHca, PState, Hvio : LongInt) : LongInt; External 'VIOCALLS';

Function ReplCalls : LongInt; External 'TESTVIOR';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';

Const
  ERROR_INTERRUPT = 95;
  ERROR_VIO_INVALID_MASK = 349;
  ERROR_VIO_MODE = 355;
  ERROR_VIO_ROW = 358;
  ERROR_VIO_BOTROW = 361;
  ERROR_VIO_UNLOCK = 367;
  ERROR_VIO_NO_SAVE_RESTORE_THD = 393;
  ERROR_VIO_NO_MODE_THREAD = 395;
  ERROR_VIO_REGISTER = 404;
  ERROR_VIO_NO_POPUP = 405;
  ERROR_VIO_EXISTING_POPUP = 406;
  ERROR_VIO_DEREGISTER = 427;
  ERROR_VIO_INVALID_HANDLE = 436;
  ERROR_VIO_BAD_CP = 465;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, J, N, H, A, B, Y, X, Hps, Hps4, Hca, St, Cb : LongInt;
  Name : Array[0..127] Of Byte;
  Name2 : Array[0..127] Of Byte;
  Buf, Buf2 : Array[0..8191] Of Byte;
  Info : Array[0..255] Of Byte;
  Cell : Array[0..3] Of Byte;
  Attr : Byte;
  S : String;
  OutBuf : Array[0..32767] Of Byte;     { resultats, affiches a la fin (pas de
                                       defilement pendant les essais) }
  OutLen, Dummy, Fs0, Bad, C, P : LongInt;

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

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
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

Function GetZ(A : LongInt) : String;
Var T : String;
Begin
  T := '';
  While (RdB(A) <> 0) And (Length(T) < 255) Do
  Begin
    T := T + Chr(RdB(A));
    A := A + 1;
  End;
  GetZ := T;
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

{ Cellule de l'ecran lue directement en memoire : caractere + attribut * 256 }
Function Scr(Row, Col : LongInt) : LongInt;
Begin
  Scr := RdW($B8000 + (Row * 80 + Col) * 2);
End;

{ Texte de l'ecran (directement en memoire) }
Function ScrText(Row, Col, N : LongInt) : String;
Var T : String; K : LongInt;
Begin
  T := '';
  For K := 0 To N - 1 Do T := T + Chr(Scr(Row, Col + K) And 255);
  ScrText := T;
End;

{ Texte lu par VioReadCharStr }
Function VioText(Row, Col, N, Hv : LongInt) : String;
Var T : String; K, C : LongInt;
Begin
  C := N;
  VioReadCharStr(LongInt(@Buf2), LongInt(@C), Row, Col, Hv);
  T := '';
  For K := 0 To C - 1 Do T := T + Chr(Buf2[K]);
  VioText := T;
End;

{ Ports du VGA }
Procedure PortOut(P, V : LongInt);
Begin
  asm
    mov edx,P
    mov eax,V
    out dx,al
  end;
End;

Function PortIn(P : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := 0;
  asm
    mov edx,P
    xor eax,eax
    in al,dx
    mov V,eax
  end;
  PortIn := V;
End;

{ Registre du controleur graphique (3CEh/3CFh) }
Function GcReg(I : LongInt) : LongInt;
Begin
  PortOut($3CE, I);
  GcReg := PortIn($3CF);
End;

{ Somme de controle de la police du VGA (plan 2, 16 lignes x 256) }
Function FontSum : LongInt;
Var C, L, T : LongInt;
Begin
  PortOut($3C4, 4); PortOut($3C5, 7);
  PortOut($3CE, 4); PortOut($3CF, 2);
  PortOut($3CE, 5); PortOut($3CF, 0);
  PortOut($3CE, 6); PortOut($3CF, 4);
  T := 0;
  For C := 0 To 255 Do
    For L := 0 To 15 Do T := T + RdB($A0000 + C * 32 + L) * (L + 1);
  PortOut($3C4, 4); PortOut($3C5, 3);
  PortOut($3CE, 4); PortOut($3CF, 0);
  PortOut($3CE, 5); PortOut($3CF, $10);
  PortOut($3CE, 6); PortOut($3CF, $0E);
  FontSum := T;
End;

{ Mode graphique : VIOMODEINFO de 12 octets (fbType 3) }
Function GrMode(Bits, W, H : LongInt) : LongInt;
Begin
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 12); Info[2] := 3; Info[3] := Bits;
  WrW(LongInt(@Info) + 8, W); WrW(LongInt(@Info) + 10, H);
  GrMode := VioSetMode(LongInt(@Info), 0);
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 34);
  Dummy := VioGetMode(LongInt(@Info), 0);
End;

{ Registre du CRTC lu directement (port 3D4h/3D5h) }
Function Crtc(Idx : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := 0;
  asm
    mov edx,3D4h
    mov eax,Idx
    out dx,al
    inc edx
    xor eax,eax
    in al,dx
    mov V,eax
  end;
  Crtc := V;
End;

Procedure OutStr(T : String);
Var K : LongInt;
Begin
  For K := 1 To Length(T) Do
    If OutLen < 32760 Then
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

Function Wrt(S : String; Row, Col, Hv : LongInt) : LongInt;
Begin
  PutZ(LongInt(@Buf), S);
  Wrt := VioWrtCharStr(LongInt(@Buf), Length(S), Row, Col, Hv);
End;

Function Tty(S : String; Hv : LongInt) : LongInt;
Begin
  PutZ(LongInt(@Buf), S);
  Tty := VioWrtTty(LongInt(@Buf), Length(S), Hv);
End;

{ Ordinal n de VIOCALLS = fonction de nom S ? }
Function OrdIs(H, Ordinal : LongInt; S : String) : Boolean;
Var Pa, Pb : LongInt;
Begin
  Pa := 0; Pb := 0;
  DosQueryProcAddr(H, 0, Z(S), LongInt(@Pa));
  DosQueryProcAddr(H, Ordinal, 0, LongInt(@Pb));
  OrdIs := (Pa <> 0) And (Pa = Pb);
End;

Function PathSize(S : String) : LongInt;
Begin
  FillChar(Info, 64, 0);
  If DosQueryPathInfo(Z(S), 1, LongInt(@Info), 24) = 0 Then PathSize := RdL(LongInt(@Info) + 12)
  Else PathSize := -1;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTVIO : essai de VIOCALLS.DLL');

  { --- module et ordinaux --- }
  R := DosQueryModuleHandle(Z('VIOCALLS'), LongInt(@H));
  Check('DosQueryModuleHandle VIOCALLS', R = 0);
  Check('ordinaux 1 VioEndPopup, 19 VioWrtTty, 76 XVioGetCAState',
        OrdIs(H, 1, 'VioEndPopup') And OrdIs(H, 19, 'VioWrtTty') And OrdIs(H, 76, 'XVioGetCAState'));
  Check('alias : 12 VioScrollRi, 15 VioSetCursorPos, 44 VioScrollLe',
        OrdIs(H, 12, 'VioScrollRi') And OrdIs(H, 12, 'VioScrollRt') And OrdIs(H, 15, 'VioSetCursorPos') And
        OrdIs(H, 44, 'VioScrollLe') And OrdIs(H, 44, 'VioScrollLf'));
  Check('ordinal 77 inexistant', DosQueryProcAddr(H, 77, 0, LongInt(@A)) <> 0);
  Check('VioInit', VioInit(0) = 0);

  { --- curseur --- }
  R := VioSetCurPos(3, 10, 0);
  VioGetCurPos(LongInt(@Y), LongInt(@X), 0);
  Check('VioSetCurPos / VioGetCurPos (3, 10)', (R = 0) And (Y = 3) And (X = 10));
  R := VioSetCurPos(30, 0, 0);
  Check('VioSetCurPos ligne 30 refusee', R = ERROR_VIO_ROW);
  R := VioGetCurType(LongInt(@Info), 0);
  A := RdW(LongInt(@Info)); B := RdW(LongInt(@Info) + 2);
  Check('VioGetCurType (lignes ' + IStr(A) + '-' + IStr(B) + ')', (R = 0) And (B >= A));
  WrW(LongInt(@Info) + 8, -50); WrW(LongInt(@Info) + 10, -100); WrW(LongInt(@Info) + 12, 0); WrW(LongInt(@Info) + 14, 0);
  R := VioSetCurType(LongInt(@Info) + 8, 0);
  VioGetCurType(LongInt(@Info) + 16, 0);
  Check('VioSetCurType -50 % / -100 % (CRTC 0Ah = 7, 0Bh = 15)', (R = 0) And (RdW(LongInt(@Info) + 16) = 7) And
        (RdW(LongInt(@Info) + 18) = 15) And ((Crtc($0A) And $3F) = 7) And ((Crtc($0B) And $1F) = 15));
  WrW(LongInt(@Info) + 14, $FFFF);
  R := VioSetCurType(LongInt(@Info) + 8, 0);
  Check('VioSetCurType curseur cache (CRTC 0Ah bit 5)', (R = 0) And ((Crtc($0A) And $20) <> 0));
  VioSetCurType(LongInt(@Info), 0);
  Check('curseur retabli', (Crtc($0A) And $3F) = A);

  { --- ecriture et lecture --- }
  Attr := $1E;
  PutZ(LongInt(@Buf), 'Bonjour VIO');
  R := VioWrtCharStrAtt(LongInt(@Buf), 11, 1, 0, LongInt(@Attr), 0);
  Check('VioWrtCharStrAtt (ecran : "Bonjour VIO" jaune sur bleu)', (R = 0) And (ScrText(1, 0, 11) = 'Bonjour VIO') And
        (Scr(1, 0) = $1E42));
  R := Wrt('ABC', 1, 0, 0);
  Check('VioWrtCharStr (attributs gardes)', (R = 0) And (Scr(1, 0) = $1E41) And (ScrText(1, 0, 5) = 'ABCjo'));
  Attr := $4F;
  R := VioWrtNAttr(LongInt(@Attr), 3, 1, 3, 0);
  Check('VioWrtNAttr', (R = 0) And (Scr(1, 3) = $4F6A) And (Scr(1, 5) = $4F75) And (Scr(1, 6) = $1E72));
  PutZ(LongInt(@Buf), '*');
  R := VioWrtNChar(LongInt(@Buf), 4, 1, 7, 0);
  Check('VioWrtNChar', (R = 0) And (ScrText(1, 6, 5) = 'r****'));
  Cell[0] := Ord('#'); Cell[1] := $2A;
  R := VioWrtNCell(LongInt(@Cell), 3, 2, 0, 0);
  Check('VioWrtNCell', (R = 0) And (Scr(2, 0) = $2A23) And (Scr(2, 2) = $2A23));
  Buf[0] := Ord('x'); Buf[1] := $70; Buf[2] := Ord('y'); Buf[3] := $07;
  R := VioWrtCellStr(LongInt(@Buf), 4, 2, 3, 0);
  Check('VioWrtCellStr', (R = 0) And (Scr(2, 3) = $7078) And (Scr(2, 4) = $0779));
  N := 8;
  R := VioReadCellStr(LongInt(@Buf2), LongInt(@N), 2, 0, 0);
  Check('VioReadCellStr (4 cellules)', (R = 0) And (N = 8) And (Buf2[0] = Ord('#')) And (Buf2[1] = $2A) And
        (Buf2[6] = Ord('x')) And (Buf2[7] = $70));
  Check('VioReadCharStr', VioText(1, 0, 5, 0) = 'ABCjo');
  R := Wrt('WXYZ', 3, 78, 0);
  Check('ecriture continuee sur la ligne suivante', (R = 0) And (ScrText(3, 78, 2) = 'WX') And (ScrText(4, 0, 2) = 'YZ'));
  R := Wrt('Q', 25, 0, 0);
  Check('ligne 25 refusee', R = ERROR_VIO_ROW);
  FillChar(Info, 16, 0);
  R := VioGetPhysBuf(LongInt(@Info), 0);
  Check('VioGetPhysBuf (000B8000h, 4000 octets, segment B800h)', (R = 0) And (RdL(LongInt(@Info)) = $B8000) And
        (RdL(LongInt(@Info) + 4) = 4000) And (RdW(LongInt(@Info) + 8) = $B800));

  { --- defilement : rectangle lignes 5-7, colonnes 0-9 --- }
  For I := 0 To 2 Do Wrt('L' + IStr(I) + 'abcdefgh', 5 + I, 0, 0);
  Cell[0] := Ord('.'); Cell[1] := 7;
  R := VioScrollUp(5, 0, 7, 9, 1, LongInt(@Cell), 0);
  Check('VioScrollUp 1 ligne', (R = 0) And (ScrText(5, 0, 2) = 'L1') And (ScrText(6, 0, 2) = 'L2') And
        (ScrText(7, 0, 10) = '..........'));
  R := VioScrollDn(5, 0, 7, 9, 2, LongInt(@Cell), 0);
  Check('VioScrollDn 2 lignes', (R = 0) And (ScrText(7, 0, 2) = 'L1') And (ScrText(5, 0, 3) = '...'));
  Wrt('0123456789', 5, 0, 0);
  R := VioScrollLf(5, 0, 5, 9, 3, LongInt(@Cell), 0);
  Check('VioScrollLf 3 colonnes', (R = 0) And (ScrText(5, 0, 10) = '3456789...'));
  R := VioScrollRt(5, 0, 5, 9, 2, LongInt(@Cell), 0);
  Check('VioScrollRt 2 colonnes', (R = 0) And (ScrText(5, 0, 10) = '..3456789.'));
  R := VioScrollUp(5, 0, 7, 9, $FFFF, LongInt(@Cell), 0);
  Check('VioScrollUp FFFFh efface le rectangle', (R = 0) And (ScrText(7, 0, 10) = '..........') And
        (ScrText(5, 0, 10) = '..........'));
  R := VioScrollUp(7, 0, 5, 9, 1, LongInt(@Cell), 0);
  Check('VioScrollUp bas < haut refuse', R = ERROR_VIO_BOTROW);

  { --- teletype et ANSI --- }
  R := VioGetAnsi(LongInt(@A), 0);
  Check('VioGetAnsi = 1 (actif par defaut)', (R = 0) And (A = 1));
  R := Tty(Chr(27) + '[2;31H' + Chr(27) + '[1;31;44m' + 'ANSI' + Chr(27) + '[0m', 0);
  Check('VioWrtTty ESC[2;31H ESC[1;31;44m (rouge vif sur bleu)', (R = 0) And (ScrText(1, 30, 4) = 'ANSI') And
        (Scr(1, 30) = $1C41));
  R := Tty(Chr(27) + '[s' + Chr(27) + '[5;5H' + Chr(27) + '[u+', 0);
  Check('VioWrtTty ESC[s ESC[u (position sauvee)', (R = 0) And (ScrText(1, 34, 1) = '+'));
  R := Tty(Chr(27) + '[2;3' + 'H', 0);
  R2 := Tty('!' + Chr(27), 0);
  R2 := Tty('[K', 0);
  Check('sequence ANSI repartie sur deux appels, ESC[K', (R = 0) And (ScrText(1, 2, 1) = '!') And
        (ScrText(1, 3, 20) = '                    '));
  VioSetAnsi(0, 0);
  R := Tty(Chr(27) + '[0m', 0);
  VioGetCurPos(LongInt(@Y), LongInt(@X), 0);
  Check('VioSetAnsi 0 : ESC affiche tel quel', (R = 0) And (ScrText(1, 3, 4) = Chr(27) + '[0m'));
  VioSetAnsi(1, 0);
  R := Tty(Chr(13) + Chr(10), 0);
  Check('VioSetAnsi 1', R = 0);

  { --- mode, configuration --- }
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 34);
  R := VioGetMode(LongInt(@Info), 0);
  Check('VioGetMode (texte couleur 80 x 25)', (R = 0) And (Info[2] = 1) And (RdW(LongInt(@Info) + 4) = 80) And
        (RdW(LongInt(@Info) + 6) = 25) And (RdL(LongInt(@Info) + 14) = $B8000));
  WrW(LongInt(@Info) + 4, 40);
  R := VioSetMode(LongInt(@Info), 0);
  Check('VioSetMode 40 colonnes refuse', R = ERROR_VIO_MODE);
  WrW(LongInt(@Info) + 4, 80);
  Info[2] := 3;
  R := VioSetMode(LongInt(@Info), 0);
  Check('VioSetMode graphique 720 x 400 refuse', R = ERROR_VIO_MODE);
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 34);
  R := VioGetConfig(0, LongInt(@Info), 0);
  Check('VioGetConfig (adaptateur VGA, 256 Ko)', (R = 0) And (RdW(LongInt(@Info) + 2) = 3) And
        (RdL(LongInt(@Info) + 6) = 262144));
  R := VioQueryConsole(LongInt(@Info), 16, 0);
  Check('VioQueryConsole (80 colonnes, page 850)', (R = 0) And (RdW(LongInt(@Info)) = 80) And
        (RdW(LongInt(@Info) + 12) = 850));
  R := VioRedrawSize(LongInt(@N));
  Check('VioRedrawSize = 4000', (R = 0) And (N = 4000));

  { --- etats du VGA --- }
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 38); WrW(LongInt(@Info) + 2, 0); WrW(LongInt(@Info) + 4, 0);
  R := VioGetState(LongInt(@Info), 0);
  A := RdW(LongInt(@Info) + 6 + 2);
  Check('VioGetState palette (registre 1 = ' + IStr(A) + ')', (R = 0) And (A <> 0));
  WrW(LongInt(@Info) + 64, 8); WrW(LongInt(@Info) + 66, 0); WrW(LongInt(@Info) + 68, 1); WrW(LongInt(@Info) + 70, $3F);
  R := VioSetState(LongInt(@Info) + 64, 0);
  WrW(LongInt(@Info) + 70, 0);
  VioGetState(LongInt(@Info) + 64, 0);
  Check('VioSetState palette (registre 1 = 3Fh)', (R = 0) And (RdW(LongInt(@Info) + 70) = $3F));
  WrW(LongInt(@Info) + 70, A);
  VioSetState(LongInt(@Info) + 64, 0);
  WrW(LongInt(@Info) + 80, 6); WrW(LongInt(@Info) + 82, 1); WrW(LongInt(@Info) + 84, 4);
  R := VioSetState(LongInt(@Info) + 80, 0);
  WrW(LongInt(@Info) + 84, 0);
  VioGetState(LongInt(@Info) + 80, 0);
  Check('VioSetState bordure (couleur 4)', (R = 0) And (RdW(LongInt(@Info) + 84) = 4));
  WrW(LongInt(@Info) + 84, 0);
  VioSetState(LongInt(@Info) + 80, 0);
  WrW(LongInt(@Info) + 80, 6); WrW(LongInt(@Info) + 82, 2); WrW(LongInt(@Info) + 84, 1);
  R := VioSetState(LongInt(@Info) + 80, 0);
  WrW(LongInt(@Info) + 84, 9);
  VioGetState(LongInt(@Info) + 80, 0);
  Check('VioSetState intensite (fond intense)', (R = 0) And (RdW(LongInt(@Info) + 84) = 1));
  WrW(LongInt(@Info) + 84, 0);
  VioSetState(LongInt(@Info) + 80, 0);
  WrW(LongInt(@Info) + 96, 12); WrW(LongInt(@Info) + 98, 3); WrW(LongInt(@Info) + 100, 1);
  WrW(LongInt(@Info) + 102, 1); WrL(LongInt(@Info) + 104, LongInt(@Buf2));
  R := VioGetState(LongInt(@Info) + 96, 0);
  B := Buf2[0] + Buf2[1] * 256 + Buf2[2] * 65536;
  Buf2[0] := 63; Buf2[1] := 0; Buf2[2] := 63;
  R2 := VioSetState(LongInt(@Info) + 96, 0);
  Buf2[0] := 0; Buf2[1] := 0; Buf2[2] := 0;
  VioGetState(LongInt(@Info) + 96, 0);
  Check('VioGetState/VioSetState registre de couleur 1 (DAC)', (R = 0) And (R2 = 0) And (Buf2[0] = 63) And
        (Buf2[1] = 0) And (Buf2[2] = 63));
  Buf2[0] := B And 255; Buf2[1] := (B Shr 8) And 255; Buf2[2] := B Shr 16;
  VioSetState(LongInt(@Info) + 96, 0);
  WrW(LongInt(@Info) + 80, 6); WrW(LongInt(@Info) + 82, 5);
  VioGetState(LongInt(@Info) + 80, 0);
  A := RdW(LongInt(@Info) + 84);
  WrW(LongInt(@Info) + 84, 15);
  R := VioSetState(LongInt(@Info) + 80, 0);
  Check('VioSetState soulignement (CRTC 14h = 15)', (R = 0) And ((Crtc($14) And $1F) = 15));
  WrW(LongInt(@Info) + 84, A);
  VioSetState(LongInt(@Info) + 80, 0);
  WrW(LongInt(@Info) + 82, 9);
  Check('VioGetState type inconnu refuse', VioGetState(LongInt(@Info) + 80, 0) <> 0);

  { --- polices --- }
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 14); WrW(LongInt(@Info) + 2, 0);
  R := VioGetFont(LongInt(@Info), 0);
  A := RdL(LongInt(@Info) + 8);
  N := RdW(LongInt(@Info) + 6);
  J := 0;
  If A <> 0 Then For I := 0 To N - 1 Do J := J + RdB(A + 65 * N + I);
  Check('VioGetFont (police affichee : ' + IStr(RdW(LongInt(@Info) + 4)) + ' x ' + IStr(N) + ', "A" dessine)',
        (R = 0) And (N >= 8) And (RdW(LongInt(@Info) + 12) = 256 * N) And (J > 0));
  For I := 0 To 256 * N - 1 Do Buf[I] := RdB(A + I);
  For I := 0 To N - 1 Do Buf[1 * N + I] := $FF;
  WrW(LongInt(@Info) + 16, 14); WrW(LongInt(@Info) + 18, 0); WrW(LongInt(@Info) + 20, 9);
  WrW(LongInt(@Info) + 22, N); WrL(LongInt(@Info) + 24, LongInt(@Buf)); WrW(LongInt(@Info) + 28, 256 * N);
  R := VioSetFont(LongInt(@Info) + 16, 0);
  WrL(LongInt(@Info) + 8, LongInt(@Buf2)); WrW(LongInt(@Info) + 12, 8192);
  R2 := VioGetFont(LongInt(@Info), 0);
  J := 0;
  For I := 0 To N - 1 Do If Buf2[1 * N + I] <> $FF Then Inc(J);
  Check('VioSetFont (caractere 1 = pave plein, relu)', (R = 0) And (R2 = 0) And (J = 0));
  WrW(LongInt(@Info) + 2, 1); WrL(LongInt(@Info) + 8, 0);
  R := VioGetFont(LongInt(@Info), 0);
  A := RdL(LongInt(@Info) + 8);
  Check('VioGetFont police d''origine (caractere 1 intact)', (R = 0) And (A <> 0) And (RdB(A + N) <> $FF));
  WrW(LongInt(@Info) + 22, 10);
  Check('VioSetFont hauteur 10 refusee', VioSetFont(LongInt(@Info) + 16, 0) <> 0);
  R := VioHetInit(0);
  WrW(LongInt(@Info) + 2, 0); WrL(LongInt(@Info) + 8, LongInt(@Buf2));
  VioGetFont(LongInt(@Info), 0);
  Check('VioHetInit (police d''origine rechargee)', (R = 0) And (Buf2[N] <> $FF));

  { --- page de codes --- }
  R := VioGetCp(0, LongInt(@A), 0);
  Check('VioGetCp = 850', (R = 0) And (A = 850));
  R := VioSetCp(0, 437, 0);
  VioGetCp(0, LongInt(@A), 0);
  Check('VioSetCp 437', (R = 0) And (A = 437));
  R := VioSetCp(0, 1234, 0);
  Check('VioSetCp 1234 refusee', R = ERROR_VIO_BAD_CP);
  VioSetCp(0, 0, 0);

  { --- tampon video logique --- }
  R := VioGetBuf(LongInt(@A), LongInt(@N), 0);
  Check('VioGetBuf (LVB de 4000 octets, copie de l''ecran)', (R = 0) And (A <> 0) And (N = 4000) And
        (RdW(A + (1 * 80) * 2) = Scr(1, 0)));
  WrW(A + (9 * 80 + 70) * 2, $5F4C);
  WrW(A + (9 * 80 + 71) * 2, $5F56);
  R := VioShowBuf((9 * 80 + 70) * 2, 4, 0);
  Check('VioShowBuf (cellules recopiees a l''ecran)', (R = 0) And (Scr(9, 70) = $5F4C) And (Scr(9, 71) = $5F56));

  { --- fenetre surgissante --- }
  Wrt('Avant la fenetre', 10, 60, 0);
  A := 1;
  R := VioPopUp(LongInt(@A), 0);
  Check('VioPopUp (ecran efface)', (R = 0) And (Scr(10, 60) = $0720));
  Wrt('Fenetre surgissante', 0, 0, 0);
  R := VioPopUp(LongInt(@A), 0);
  Check('VioPopUp deja ouverte refusee', R = ERROR_VIO_EXISTING_POPUP);
  R := VioEndPopup(0);
  Check('VioEndPopup (ecran rendu)', (R = 0) And (ScrText(10, 60, 16) = 'Avant la fenetre'));
  Check('VioEndPopup sans fenetre refusee', VioEndPopup(0) = ERROR_VIO_NO_POPUP);
  A := 3;
  R := VioPopUp(LongInt(@A), 0);
  Check('VioPopUp transparente (ecran garde)', (R = 0) And (ScrText(10, 60, 16) = 'Avant la fenetre'));
  VioEndPopup(0);

  { --- verrou, sauvegarde, bascule, blocage --- }
  R := VioScrLock(0, LongInt(@St), 0);
  Check('VioScrLock', (R = 0) And (St = 0));
  R := VioScrUnlock(0);
  Check('VioScrUnlock', R = 0);
  Check('VioScrUnlock sans verrou refuse', VioScrUnlock(0) = ERROR_VIO_UNLOCK);
  R := VioSave(0);
  Wrt('Ecrase apres VioSave', 10, 60, 0);
  R2 := VioRestore(0);
  Check('VioSave / VioRestore', (R = 0) And (R2 = 0) And (ScrText(10, 60, 16) = 'Avant la fenetre'));
  R := VioSswSwitch(0);
  Wrt('Seconde session', 0, 0, 0);
  R2 := VioSswSwitch(0);
  Check('VioSswSwitch aller et retour', (R = 0) And (R2 = 0) And (ScrText(10, 60, 16) = 'Avant la fenetre'));
  R := VioSrfBlock(0);
  Wrt('Ecriture bloquee', 11, 60, 0);
  Check('VioSrfBlock (ecran inchange, VIO lit l''ecran fantome)', (R = 0) And
        (ScrText(11, 60, 16) <> 'Ecriture bloquee') And (VioText(11, 60, 16, 0) = 'Ecriture bloquee'));
  R := VioSrfUnblock(0);
  Check('VioSrfUnblock (affichage)', (R = 0) And (ScrText(11, 60, 16) = 'Ecriture bloquee'));

  { --- attentes du gestionnaire de sessions --- }
  R := VioSavRedrawWait(0, LongInt(@A), 0);
  Check('VioSavRedrawWait = ERROR_INTERRUPT (une seule session)', R = ERROR_INTERRUPT);
  R := VioSavRedrawUndo(1, 0, 0);
  Check('VioSavRedrawUndo', R = 0);
  Check('VioSavRedrawUndo sans attente refuse', VioSavRedrawUndo(1, 0, 0) = ERROR_VIO_NO_SAVE_RESTORE_THD);
  R := VioModeWait(0, LongInt(@A), 0);
  Check('VioModeWait = ERROR_INTERRUPT', R = ERROR_INTERRUPT);
  R := VioModeUndo(1, 0, 0);
  Check('VioModeUndo', R = 0);
  Check('VioModeUndo sans attente refuse', VioModeUndo(1, 0, 0) = ERROR_VIO_NO_MODE_THREAD);

  { --- impression de l'ecran --- }
  DosDelete(Z('C:\PRTSC.TXT'));
  VioSetCurPos(15, 0, 0);
  R := VioPrtSc(0);
  A := PathSize('C:\PRTSC.TXT');
  Check('VioPrtSc (C:\PRTSC.TXT, ' + IStr(A) + ' octets)', (R = 0) And (A >= 50));
  R := VioPrtScToggle(0);
  Tty('Copie vers l''impression' + Chr(13) + Chr(10), 0);
  R2 := VioPrtScToggle(0);
  Tty('Pas copie' + Chr(13) + Chr(10), 0);
  B := PathSize('C:\PRTSC.TXT');
  Check('VioPrtScToggle (teletype copie)', (R = 0) And (R2 = 0) And (B = A + 25));
  R := Avs_PrtscToggle(0);
  R2 := Avs_PrtscToggle(0);
  Check('Avs_PrtscToggle', (R = 0) And (R2 = 0) And (PathSize('C:\PRTSC.TXT') = B));
  N := 4000;
  R := Avs_Prtsc(LongInt(@Buf2), LongInt(@N), 0);
  Check('Avs_Prtsc (capture de l''ecran)', (R = 0) And (N = 4000) And (Buf2[(11 * 80 + 60) * 2] = Ord('E')));
  DosDelete(Z('C:\PRTSC.TXT'));

  { --- remplacement du sous-systeme --- }
  R := VioRegister(Z('TESTVIOR'), Z2('VioReplace'), 0, 0);
  Check('VioRegister masque vide refuse', R = ERROR_VIO_INVALID_MASK);
  R := VioRegister(Z('TESTVIOR'), Z2('VioReplace'), 1, 0);
  VioSetCurPos(2, 2, 0);
  VioGetCurPos(LongInt(@Y), LongInt(@X), 0);
  Check('VioRegister VR_VIOGETCURPOS (le remplacant rend 7, 7)', (R = 0) And (Y = 7) And (X = 7));
  Check('VioRegister deja fait refuse', VioRegister(Z('TESTVIOR'), Z2('VioReplace'), 1, 0) = ERROR_VIO_REGISTER);
  R := VioDeRegister;
  VioGetCurPos(LongInt(@Y), LongInt(@X), 0);
  Check('VioDeRegister (fonction de base)', (R = 0) And (Y = 2) And (X = 2));
  Check('VioDeRegister sans remplacement refuse', VioDeRegister = ERROR_VIO_DEREGISTER);
  A := ReplCalls;
  R := VioGlobalReg(Z('TESTVIOR'), Z2('VioReplace'), 2, 0, 99);
  R2 := VioGetCurType(LongInt(@Info), 0);
  Check('VioGlobalReg VR_VIOGETCURTYPE (remplacant appele, fonction de base)',
        ((R = 0) Or (R = ERROR_VIO_REGISTER)) And (R2 = 0) And (ReplCalls = A + 1) And (RdW(LongInt(@Info) + 2) > 0));

  { --- espaces de presentation AVIO --- }
  R := VioCreatePS(LongInt(@Hps), 30, 100, 1, 1, 0);
  Check('VioCreatePS 30 x 100 (format CGA)', (R = 0) And (Hps <> 0));
  R := Wrt('Texte dans le PS', 2, 5, Hps);
  Check('VioWrtCharStr dans le PS (ecran inchange)', (R = 0) And (VioText(2, 5, 16, Hps) = 'Texte dans le PS') And
        (ScrText(2, 5, 16) <> 'Texte dans le PS'));
  R := Wrt('Colonne 95', 29, 90, Hps);
  Check('PS : ligne 29, colonne 90', (R = 0) And (VioText(29, 90, 10, Hps) = 'Colonne 95'));
  R := VioGetDeviceCellSize(LongInt(@A), LongInt(@B), Hps);
  Check('VioGetDeviceCellSize (16 x 8)', (R = 0) And (A = 16) And (B = 8));
  Check('VioSetDeviceCellSize 14 x 8', VioSetDeviceCellSize(14, 8, Hps) = 0);
  Check('VioSetDeviceCellSize 10 x 8 refuse', VioSetDeviceCellSize(10, 8, Hps) <> 0);
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 56); PutZ(LongInt(@Info) + 8, 'System VIO'); WrL(LongInt(@Info) + 44, 16); WrL(LongInt(@Info) + 48, 8);
  R := VioCreateLogFont(LongInt(@Info), 1, Z('NORMALE '), Hps);
  Check('VioCreateLogFont lcid 1', R = 0);
  Check('VioCreateLogFont lcid 1 deja pris refuse', VioCreateLogFont(LongInt(@Info), 1, 0, Hps) <> 0);
  FillChar(Buf2, 64, 0);
  R := VioQuerySetIds(LongInt(@Buf2), LongInt(@Buf2) + 16, LongInt(@Buf2) + 32, 4, Hps);
  Check('VioQuerySetIds (lcid 1, "NORMALE ", type 6)', (R = 0) And (RdL(LongInt(@Buf2)) = 1) And
        (Buf2[16] = Ord('N')) And (RdL(LongInt(@Buf2) + 32) = 6));
  R := VioDeleteSetId(1, Hps);
  Check('VioDeleteSetId', (R = 0) And (VioDeleteSetId(1, Hps) <> 0));
  N := 5;
  R := VioQueryFonts(LongInt(@A), LongInt(@Buf2), 228, LongInt(@N), 0, 0, Hps);
  Check('VioQueryFonts (3 polices "System VIO" : 8, 14, 16)', (R = 0) And (N = 3) And (A = 0) And
        (GetZ(LongInt(@Buf2) + 32) = 'System VIO') And (RdL(LongInt(@Buf2) + 228 * 2 + 112) = 16));
  R := VioAssociate(1, Hps);
  Check('VioAssociate (PS affiche a l''ecran)', (R = 0) And (ScrText(2, 5, 16) = 'Texte dans le PS'));
  R := VioSetOrg(2, 5, Hps);
  VioGetOrg(LongInt(@A), LongInt(@B), Hps);
  Check('VioSetOrg / VioGetOrg (2, 5)', (R = 0) And (A = 2) And (B = 5) And (ScrText(0, 0, 16) = 'Texte dans le PS'));
  Wrt('Change', 3, 5, Hps);
  R := VioShowPS(1, 10, 3 * 100 + 5, Hps);
  Check('VioShowPS (ligne 3 du PS -> ligne 1 de l''ecran)', (R = 0) And (ScrText(1, 0, 6) = 'Change'));
  R := VioGetPSAddress(LongInt(@A), Hps);
  Check('VioGetPSAddress', (R = 0) And (A <> 0) And (RdB(A + (2 * 100 + 5) * 2) = Ord('T')));
  VioSetCurPos(0, 0, Hps);
  R := Tty(Chr(27) + '[3;7H' + 'tty', Hps);
  Check('VioWrtTty dans le PS (ANSI)', (R = 0) And (VioText(2, 6, 3, Hps) = 'tty'));
  Cell[0] := 32; Cell[1] := 7;
  R := VioScrollUp(0, 0, 29, 99, 2, LongInt(@Cell), Hps);
  Check('VioScrollUp dans le PS', (R = 0) And (VioText(0, 5, 16, Hps) = 'Tttye dans le PS') And
        (VioText(1, 5, 6, Hps) = 'Change'));
  WrW(LongInt(@Info), 34);
  R := VioGetMode(LongInt(@Info), Hps);
  Check('VioGetMode du PS (100 x 30)', (R = 0) And (RdW(LongInt(@Info) + 4) = 100) And (RdW(LongInt(@Info) + 6) = 30));
  VioAssociate(0, Hps);
  R := VioDestroyPS(Hps);
  Check('VioDestroyPS', R = 0);
  Check('PS detruit : handle refuse', Wrt('x', 0, 0, Hps) = ERROR_VIO_INVALID_HANDLE);
  R := VioCreatePS(LongInt(@Hps4), 5, 10, 3, 3, 0);
  Cell[0] := Ord('Q'); Cell[1] := $1F; Cell[2] := 1; Cell[3] := 0;
  R2 := VioWrtNCell(LongInt(@Cell), 3, 1, 1, Hps4);
  N := 12;
  VioReadCellStr(LongInt(@Buf2), LongInt(@N), 1, 1, Hps4);
  Check('PS a 4 octets par cellule (VioWrtNCell, VioReadCellStr)', (R = 0) And (R2 = 0) And (N = 12) And
        (Buf2[0] = Ord('Q')) And (Buf2[1] = $1F) And (Buf2[2] = 1) And (Buf2[8] = Ord('Q')));
  VioDestroyPS(Hps4);

  { --- attributs etendus et caracteres double octet --- }
  FillChar(Info, 16, 0);
  WrW(LongInt(@Info), 6); WrW(LongInt(@Info) + 2, 2); WrW(LongInt(@Info) + 4, $FFFF);
  R := XVioCreateCA(LongInt(@Hca), LongInt(@Info), 0);
  Check('XVioCreateCA (inverse)', (R = 0) And (Hca <> 0));
  R := XVioSetCAState(Hca, 1, 0);
  Attr := $1E;
  PutZ(LongInt(@Buf), 'Inverse');
  VioWrtCharStrAtt(LongInt(@Buf), 7, 12, 60, LongInt(@Attr), 0);
  Check('XVioSetCAState : attribut 1Eh ecrit en 69h (couleurs inversees)', (R = 0) And (Scr(12, 60) = $6949));
  R := XVioGetCAState(LongInt(@A), LongInt(@B), 0);
  Check('XVioGetCAState', (R = 0) And (A = Hca) And (B = 1));
  XVioSetCAState(0, 0, 0);
  VioWrtCharStrAtt(LongInt(@Buf), 7, 12, 60, LongInt(@Attr), 0);
  Check('XVioSetCAState 0 (attributs normaux)', Scr(12, 60) = $1E49);
  R := XVioDestroyCA(Hca, 0);
  Check('XVioDestroyCA', (R = 0) And (XVioDestroyCA(Hca, 0) = ERROR_VIO_INVALID_HANDLE));
  R := VioCheckCharType(LongInt(@A), 12, 60, 0);
  Check('VioCheckCharType (page 850 : simple)', (R = 0) And (A = 0));
  VioSetCp(0, 932, 0);
  Buf[0] := $82; Buf[1] := $A0; Buf[2] := Ord('A');
  VioWrtCharStr(LongInt(@Buf), 3, 12, 0, 0);
  R := VioCheckCharType(LongInt(@A), 12, 0, 0);
  R2 := XVioCheckCharType(LongInt(@B), 12, 1, 0);
  VioCheckCharType(LongInt(@J), 12, 2, 0);
  Check('VioCheckCharType page 932 (tete, queue, simple)', (R = 0) And (R2 = 0) And (A = 2) And (B = 3) And (J = 0));
  VioSetCp(0, 850, 0);

  { --- liberation et fin --- }
  R := VioGetBuf(LongInt(@A), LongInt(@N), 0);
  Check('VioFree', (R = 0) And (VioFree(0) = 0));
  Check('VioShellInit', VioShellInit(0) = 0);
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 8); Info[2] := 1; Info[3] := 4; WrW(LongInt(@Info) + 4, 80); WrW(LongInt(@Info) + 6, 25);
  R := VioSetMode(LongInt(@Info), 0);
  VioGetCurPos(LongInt(@Y), LongInt(@X), 0);
  Check('VioSetMode 80 x 25 (ecran efface, curseur en haut)', (R = 0) And (Y = 0) And (X = 0) And (Scr(12, 60) = $0720));

  { --- modes graphiques --- }
  Fs0 := FontSum;
  R := GrMode(4, 640, 480);
  Check('VioSetMode 640 x 480 x 16 (VGA 12h), VioGetMode', (R = 0) And (Info[2] = 3) And (Info[3] = 4) And
        (RdW(LongInt(@Info) + 4) = 80) And (RdW(LongInt(@Info) + 6) = 30) And (RdW(LongInt(@Info) + 8) = 640) And
        (RdW(LongInt(@Info) + 10) = 480) And (RdL(LongInt(@Info) + 14) = $A0000) And (RdL(LongInt(@Info) + 18) = 38400));
  Check('registres du VGA : 480 lignes (CRTC 12h = DFh), mode graphique (GC 6)', (Crtc($12) = $DF) And
        ((GcReg(6) And 1) = 1) And ((PortIn($3CC) And $C0) = $C0));
  WrL(LongInt(@Info) + 40, 0); WrL(LongInt(@Info) + 44, 0);
  R := VioGetPhysBuf(LongInt(@Info) + 40, 0);
  Check('VioGetPhysBuf : 000A0000h, 38400 octets par plan', (R = 0) And (RdL(LongInt(@Info) + 40) = $A0000) And
        (RdL(LongInt(@Info) + 44) = 38400));
  Buf[0] := Ord('X');
  R := VioWrtCharStr(LongInt(@Buf), 1, 0, 0, 0);
  R2 := VioSetCurPos(0, 0, 0);
  Check('fonctions du mode texte refusees (ERROR_VIO_MODE)', (R = ERROR_VIO_MODE) And (R2 = ERROR_VIO_MODE));
  { 16 bandes de couleur (plans de bits, masque des plans du sequenceur) }
  For C := 0 To 15 Do
  Begin
    PortOut($3C4, 2); PortOut($3C5, C);
    For Y := 96 To 383 Do
      For X := 0 To 4 Do WrB($A0000 + Y * 80 + C * 5 + X, $FF);
  End;
  PortOut($3C4, 2); PortOut($3C5, $0F);
  { cadre blanc }
  For X := 0 To 79 Do
  Begin
    WrB($A0000 + 40 * 80 + X, $FF); WrB($A0000 + 439 * 80 + X, $FF);
  End;
  For Y := 40 To 439 Do
  Begin
    WrB($A0000 + Y * 80, RdB($A0000 + Y * 80) Or $80); WrB($A0000 + Y * 80 + 79, RdB($A0000 + Y * 80 + 79) Or 1);
  End;
  Bad := 0;
  For C := 0 To 15 Do
    For P := 0 To 3 Do
    Begin
      PortOut($3CE, 4); PortOut($3CF, P);
      If ((RdB($A0000 + 200 * 80 + C * 5 + 2) = $FF) <> (((C Shr P) And 1) = 1)) Then Inc(Bad);
    End;
  PortOut($3CE, 4); PortOut($3CF, 0);
  Check('pels ecrits et relus dans les 4 plans (16 couleurs)', Bad = 0);
  Dummy := DosSleep(1500);
  A := 0;
  R := VioPopUp(LongInt(@A), 0);
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 34);
  Dummy := VioGetMode(LongInt(@Info), 0);
  B := Info[2];
  R2 := VioEndPopup(0);
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 34);
  Dummy := VioGetMode(LongInt(@Info), 0);
  Check('VioPopUp en mode graphique : texte, puis VioEndPopup : 640 x 480', (R = 0) And (B = 1) And (R2 = 0) And
        (Info[2] = 3) And (RdW(LongInt(@Info) + 8) = 640));
  R := GrMode(8, 320, 200);
  Check('VioSetMode 320 x 200 x 256 (VGA 13h)', (R = 0) And (Info[3] = 8) And (RdW(LongInt(@Info) + 8) = 320) And
        (RdL(LongInt(@Info) + 18) = 64000) And ((GcReg(5) And $40) = $40));
  For Y := 0 To 199 Do
    For X := 0 To 319 Do WrB($A0000 + Y * 320 + X, (X Div 20) + (Y Div 25) * 16);
  Bad := 0;
  For X := 0 To 15 Do
    If RdB($A0000 + 100 * 320 + X * 20 + 5) <> X + 64 Then Inc(Bad);
  Check('pels du mode 13h (un octet par pel)', Bad = 0);
  Dummy := DosSleep(1500);
  R := GrMode(4, 320, 200);
  R2 := Info[3];
  A := RdW(LongInt(@Info) + 8);
  B := GrMode(4, 640, 350);
  Check('VioSetMode 320 x 200 x 16 (0Dh) et 640 x 350 x 16 (10h)', (R = 0) And (R2 = 4) And (A = 320) And (B = 0) And
        (RdW(LongInt(@Info) + 10) = 350) And (Crtc($12) = $5D));
  R := GrMode(2, 640, 480);
  R2 := GrMode(1, 640, 480);
  Check('VioSetMode 640 x 480 x 4 refuse, 640 x 480 x 2 (11h)', (R = ERROR_VIO_MODE) And (R2 = 0) And (Info[3] = 1));
  FillChar(Info, 64, 0);
  WrW(LongInt(@Info), 8); Info[2] := 1; Info[3] := 4; WrW(LongInt(@Info) + 4, 80); WrW(LongInt(@Info) + 6, 25);
  R := VioSetMode(LongInt(@Info), 0);
  Buf[0] := Ord('O'); Buf[1] := Ord('K');
  R2 := VioWrtCharStr(LongInt(@Buf), 2, 0, 0, 0);
  Check('retour au texte 80 x 25 : police rechargee, ecriture', (R = 0) And (R2 = 0) And (FontSum = Fs0) And
        (Crtc(9) And $1F = 15) And (Scr(0, 0) And $FF = Ord('O')) And ((GcReg(6) And 1) = 0));

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTVIO : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
