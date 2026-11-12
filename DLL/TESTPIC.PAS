{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de PMPIC.DLL sous OS/2-0.
}

Program TESTPIC;

{$R-,S-,I-}

{ Compilation : OS2PC TESTPIC.PAS   (produit TESTPIC.EXE)

  TESTPIC verifie PMPIC.DLL : il ecrit un fichier PIF (ordres GDF/GOCA :
  couleurs, lignes, lignes relatives, boite pleine, cercle, texte EBCDIC,
  zone, ordres inconnus a sauter), le convertit en metafichier (pif2met,
  PicIchg), rejoue le metafichier dans une bitmap avec PMGPI.DLL et en
  verifie les pels, puis imprime (PicPrint) le metafichier et le fichier
  PIF dans des fichiers (graphique ESC/P) et sur PRN (avec QEMU :
  -parallel file:sortie.txt recueille les donnees). }

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';

Function PicPrint(Hab, PName, Typ, PPrm : LongInt) : LongInt; External 'PMPIC';
Function PicIchg(Hab, P1, P2, Typ : LongInt) : LongInt; External 'PMPIC';
Function pif2met(P1, P2 : LongInt) : LongInt; External 'PMPIC';

Function DevOpenDC(Hab, T, PTok, N, PDop, Hc : LongInt) : LongInt; External 'PMGPI';
Function DevCloseDC(H : LongInt) : LongInt; External 'PMGPI';
Function GpiCreatePS(Hab, Hdc, PSz, Fl : LongInt) : LongInt; External 'PMGPI';
Function GpiDestroyPS(H : LongInt) : LongInt; External 'PMGPI';
Function GpiErase(H : LongInt) : LongInt; External 'PMGPI';
Function GpiCreateBitmap(H, PHdr, Fl, PInit, Pbmi : LongInt) : LongInt; External 'PMGPI';
Function GpiSetBitmap(H, Hbm : LongInt) : LongInt; External 'PMGPI';
Function GpiDeleteBitmap(Hbm : LongInt) : LongInt; External 'PMGPI';
Function GpiQueryPel(H, P : LongInt) : LongInt; External 'PMGPI';
Function GpiLoadMetaFile(Hab, P : LongInt) : LongInt; External 'PMGPI';
Function GpiPlayMetaFile(H, M, N1, PO, PS, N2, PD : LongInt) : LongInt; External 'PMGPI';
Function GpiDeleteMetaFile(M : LongInt) : LongInt; External 'PMGPI';

Const
  PIP_MF = 1; PIP_PIF = 2; PIC_PIFTOMET = 0; PIC_SSTOFONT = 2;
  CLR_BACKGROUND = 0; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_YELLOW = 6;

Var
  Ok, Fail, R, R2, I, N, A, P, H, Hmod, Hdc, Hps, Hbm, Hmf, Nb : LongInt;
  Name, Name2 : Array[0..255] Of Byte;
  Pif : Array[0..511] Of Byte;
  Fbuf : Array[0..40959] Of Byte;
  Bmi : Array[0..15] Of LongInt;
  Q : Array[0..1] Of LongInt;
  OutBuf : Array[0..8191] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Name[K - 1] := Ord(S[K]);
  Name[Length(S)] := 0;
  Z := LongInt(@Name);
End;

Function Z2(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Name2[K - 1] := Ord(S[K]);
  Name2[Length(S)] := 0;
  Z2 := LongInt(@Name2);
End;

Procedure OutStr(T : String);
Var K : LongInt;
Begin
  For K := 1 To Length(T) Do
    If OutLen < 8190 Then
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

{ --- fichier PIF : octets et nombres de 16 bits (octet fort d'abord) --- }
Procedure PB(V : LongInt);
Begin
  Pif[Nb] := V And 255;
  Inc(Nb);
End;

Procedure PW(V : LongInt);
Begin
  PB(V Shr 8); PB(V);
End;

Procedure Dummy2(V : LongInt);
Begin
End;

{ fichier entier dans Fbuf ; taille }
Function ReadAll(S : String) : LongInt;
Var Hf, Act, Got : LongInt;
Begin
  ReadAll := -1;
  Hf := 0; Act := 0;
  If DosOpen(Z(S), LongInt(@Hf), LongInt(@Act), 0, 0, 1, $40, 0) <> 0 Then Exit;
  Got := 0;
  If DosRead(Hf, LongInt(@Fbuf), 40960, LongInt(@Got)) <> 0 Then Got := -1;
  Dummy2(DosClose(Hf));
  ReadAll := Got;
End;

Function Pel(X, Y : LongInt) : LongInt;
Begin
  Q[0] := X; Q[1] := Y;
  Pel := GpiQueryPel(Hps, LongInt(@Q));
End;

{ pels differents du fond dans un rectangle }
Function Ink(X1, Y1, X2, Y2 : LongInt) : LongInt;
Var X, Y, C : LongInt;
Begin
  C := 0;
  For Y := Y1 To Y2 Do
    For X := X1 To X2 Do
      If Pel(X, Y) <> CLR_BACKGROUND Then Inc(C);
  Ink := C;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTPIC : essai de PMPIC.DLL');

  { --- ordinaux --- }
  Hmod := 0;
  R := DosQueryModuleHandle(Z('PMPIC'), LongInt(@Hmod));
  N := 0;
  For I := 1 To 3 Do
  Begin
    P := 0;
    If DosQueryProcAddr(Hmod, I, 0, LongInt(@P)) = 0 Then
      If P <> 0 Then Inc(N);
  End;
  P := 0;
  R := DosQueryProcAddr(Hmod, 0, Z('pif2met'), LongInt(@P));
  Check('3 ordinaux de PMPIC, nom pif2met', (N = 3) And (P <> 0));

  { --- fichier PIF --- }
  Nb := 0;
  PB($0A); PB($02);                                          { GSCOL rouge }
  PB($C1); PB(12); PW(10); PW(10); PW(200); PW(10); PW(200); PW(100);
  PB($0A); PB($01);                                          { bleu }
  PB($C0); PB(10); PB($40); PB(0); PW(20); PW(20); PW(60); PW(60);
  PB($0A); PB($04);                                          { vert }
  PB($C7); PB(6); PW(300); PW(200); PB(40); PB(0);           { cercle r = 40 }
  PB($0A); PB($08);                                          { noir }
  PB($C3); PB(9); PW(100); PW(300);
  PB($D7); PB($D4); PB($D7); PB($C9); PB($C3);               { 'PMPIC' en EBCDIC }
  PB($70); PB(3); PB(1); PB(2); PB(3);                       { debut de segment : saute }
  PB($00);                                                   { sans effet }
  PB($01); PB(2); PB($AA); PB($BB);                          { commentaire }
  PB($0A); PB($06);                                          { jaune }
  PB($68); PB(1); PB(0);                                     { GBAR }
  PB($21); PB(4); PW(400); PW(50);                           { GSCP }
  PB($81); PB(8); PW(500); PW(50); PW(450); PW(150);         { GCLINE }
  PB($60); PB(0);                                            { GEAR }
  PB($0A); PB($03);                                          { rose }
  PB($E1); PB(8); PW(10); PW(400); PB(20); PB(0); PB(0); PB(20);
  R := DosDelete(Z('D:\ESSAI.PIF'));
  H := 0; A := 0;
  R := DosOpen(Z('D:\ESSAI.PIF'), LongInt(@H), LongInt(@A), 0, 0, $12, $22, 0);
  R2 := DosWrite(H, LongInt(@Pif), Nb, LongInt(@N));
  Dummy2(DosClose(H));
  Check('fichier PIF ecrit (' + IStr(Nb) + ' octets)', (R = 0) And (N = Nb));

  { --- conversion --- }
  R := DosDelete(Z('D:\ESSAI.MET'));
  R := pif2met(Z('D:\ESSAI.PIF'), Z2('D:\ESSAI.MET'));
  Check('pif2met', R = 1);
  R := pif2met(Z('D:\ABSENT.PIF'), Z2('D:\X.MET'));
  Check('pif2met : fichier absent (FALSE)', R = 0);
  R := PicIchg(0, Z('D:\ESSAI.PIF'), Z2('D:\ICHG.MET'), PIC_PIFTOMET);
  R2 := PicIchg(0, Z('D:\ESSAI.PIF'), Z2('D:\X.FNT'), PIC_SSTOFONT);
  Check('PicIchg PIC_PIFTOMET, PIC_SSTOFONT (FALSE)', (R = 1) And (R2 = 0) And (ReadAll('D:\ICHG.MET') > 12));

  { --- metafichier rejoue dans une bitmap de 640 x 480 --- }
  Hdc := DevOpenDC(0, 8, Z('*'), 0, 0, 0);
  Hps := GpiCreatePS(0, Hdc, 0, 8 Or $4000);
  For I := 0 To 15 Do Bmi[I] := 0;
  Bmi[0] := 16; Bmi[1] := 640; Bmi[2] := 480; Bmi[3] := 1 Or (24 Shl 16);
  Hbm := GpiCreateBitmap(Hps, LongInt(@Bmi), 0, 0, 0);
  R := GpiSetBitmap(Hps, Hbm);
  R := GpiErase(Hps);
  Hmf := GpiLoadMetaFile(0, Z('D:\ESSAI.MET'));
  R := GpiPlayMetaFile(Hps, Hmf, 0, 0, 0, 0, 0);
  Check('GpiLoadMetaFile, GpiPlayMetaFile du metafichier converti', (Hmf <> 0) And (R = 1));
  Check('GLINE (rouge)', (Pel(100, 10) = CLR_RED) And (Pel(200, 50) = CLR_RED) And (Pel(100, 50) = CLR_BACKGROUND));
  Check('GBOX plein (bleu)', (Pel(40, 40) = CLR_BLUE) And (Pel(60, 60) = CLR_BLUE) And (Pel(70, 70) = CLR_BACKGROUND));
  Check('GFARC (cercle vert, rayon 40)', (Pel(340, 200) = CLR_GREEN) And (Pel(300, 240) = CLR_GREEN) And
        (Pel(300, 200) = CLR_BACKGROUND));
  N := Ink(100, 296, 140, 316);
  Check('GCHST : texte EBCDIC (' + IStr(N) + ' pels)', N > 40);
  Check('GBAR, GSCP, GCLINE, GEAR : zone pleine (jaune)', (Pel(450, 80) = CLR_YELLOW) And (Pel(410, 140) = CLR_BACKGROUND));
  Check('GRLINE : lignes relatives (rose), ordres sautes', (Pel(20, 400) = CLR_PINK) And (Pel(30, 410) = CLR_PINK));
  R := GpiDeleteMetaFile(Hmf);
  R := GpiSetBitmap(Hps, 0);
  R := GpiDeleteBitmap(Hbm);
  R := GpiDestroyPS(Hps);
  R := DevCloseDC(Hdc);

  { --- impression (graphique ESC/P) --- }
  R := DosDelete(Z('D:\SORTIE.PRN'));
  R := PicPrint(0, Z('D:\ESSAI.MET'), PIP_MF, Z2('D:\SORTIE.PRN'));
  N := ReadAll('D:\SORTIE.PRN');
  A := 0;
  For I := 0 To N - 1 Do
    If (I > 7) And (Fbuf[I] <> 0) Then Inc(A);
  Check('PicPrint PIP_MF : ESC @, ESC * 1 (640 points), ESC J 24, FF (' + IStr(N) + ' octets)', (R = 1) And
        (N = 2 + 60 * (5 + 640 + 3) + 1) And (Fbuf[0] = 27) And (Fbuf[1] = 64) And (Fbuf[2] = 27) And (Fbuf[3] = 42) And
        (Fbuf[4] = 1) And (Fbuf[5] = 128) And (Fbuf[6] = 2) And (Fbuf[647] = 27) And (Fbuf[648] = 74) And
        (Fbuf[649] = 24) And (Fbuf[N - 1] = 12) And (A > 100));
  { bande du bas : ligne rouge en y = 10 (rangee 469 : bande 58, bit 5 : 04h) }
  P := 2 + 58 * 648 + 5;
  Check('PicPrint : ligne de la bande du bas', (Fbuf[P + 100] And $04) <> 0);
  R := PicPrint(0, Z('D:\ESSAI.PIF'), PIP_PIF, Z2('/W:320 /H:240 D:\S2.PRN'));
  N := ReadAll('D:\S2.PRN');
  Check('PicPrint PIP_PIF, /W:320 /H:240 (' + IStr(N) + ' octets)', (R = 1) And (N = 2 + 30 * (5 + 320 + 3) + 1));
  R := PicPrint(0, Z('D:\ABSENT.MET'), PIP_MF, Z2('D:\S3.PRN'));
  R2 := PicPrint(0, Z('D:\ESSAI.MET'), 9, Z2('D:\S3.PRN'));
  Check('PicPrint : fichier absent, type inconnu (FALSE)', (R = 0) And (R2 = 0));
  R := PicPrint(0, Z('D:\ESSAI.PIF'), PIP_PIF, Z2('/W:64 /H:16 PRN'));
  Check('PicPrint sur PRN', R = 1);

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTPIC : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
