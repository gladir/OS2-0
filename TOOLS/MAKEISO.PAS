{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
  @description: Fabrique une image CD-ROM ISO 9660 amorcable (El Torito,
                sans emulation) pour OS/2-0.
}

Program MAKEISO;

{ Syntaxe :
    MAKEISO image.iso [/BOOT:fichier] [/LABEL:nom] fichier [fichier ...]

  - Les fichiers sont places a la racine du CD-ROM (ISO 9660 niveau 1,
    noms 8.3 en majuscules, version ;1).
  - /BOOT: designe le fichier d amorce (OS2BOOT) : il est decrit dans le
    catalogue El Torito en mode "sans emulation", charge par le BIOS en
    0000:7C00 (segment de chargement 0 = 07C0h). Le nombre de secteurs
    virtuels de 512 octets a charger est calcule d apres sa taille.
  - Disposition : secteurs 0..15 reserves, 16 descripteur primaire,
    17 descripteur d amorce El Torito, 18 terminateur, 19 table des
    chemins (L), 20 table des chemins (M), 21 catalogue d amorce,
    22.. repertoire racine, puis les fichiers. }

{$IFDEF FPC}
  {$MODE TP}
{$ENDIF}

Const
  SECT       = 2048;
  MAX_FILES  = 128;

Type
  TSector = Array[0..SECT-1] Of Byte;

Var
  IsoName, BootName, VolLabel : String;
  FileNames : Array[1..MAX_FILES] Of String;   { chemins sur l hote }
  IsoNames  : Array[1..MAX_FILES] Of String;   { noms ISO (sans ;1) }
  FileSizes : Array[1..MAX_FILES] Of LongInt;
  FileLBA   : Array[1..MAX_FILES] Of LongInt;
  NFiles    : Integer;
  BootIdx   : Integer;
  RootLBA, RootSectors, TotalSectors : LongInt;
  Iso : File;
  Sec : TSector;
  I, J : Integer;
  Arg, U : String;

Function UpStr(S : String) : String;
Var K : Integer;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

{ Nom de base (sans repertoire) d un chemin }
Function BaseName(Const S : String) : String;
Var K : Integer;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '/') And (S[K] <> '\') And (S[K] <> ':') Do Dec(K);
  BaseName := Copy(S, K + 1, 255);
End;

{ Nom ISO 9660 niveau 1 : NOM.EXT en majuscules (8.3) }
Function IsoFileName(Const S : String) : String;
Var B, N, E : String; K : Integer;
Begin
  B := UpStr(BaseName(S));
  K := Pos('.', B);
  If K > 0 Then
  Begin
    N := Copy(B, 1, K - 1);
    E := Copy(B, K + 1, 255);
  End
  Else
  Begin
    N := B; E := '';
  End;
  If Length(N) > 8 Then N := Copy(N, 1, 8);
  If Length(E) > 3 Then E := Copy(E, 1, 3);
  IsoFileName := N + '.' + E;
End;

Procedure FillSec(B : Byte);
Var K : Integer;
Begin
  For K := 0 To SECT - 1 Do Sec[K] := B;
End;

Procedure WriteSec;
Begin
  BlockWrite(Iso, Sec, 1);
End;

Procedure PutB(Ofs : Integer; B : Byte);
Begin
  Sec[Ofs] := B;
End;

Procedure PutW(Ofs : Integer; W : Word);
Begin
  Sec[Ofs] := Lo(W); Sec[Ofs + 1] := Hi(W);
End;

Procedure PutWBE(Ofs : Integer; W : Word);
Begin
  Sec[Ofs] := Hi(W); Sec[Ofs + 1] := Lo(W);
End;

Procedure PutD(Ofs : Integer; D : LongInt);
Begin
  Sec[Ofs] := D And $FF; Sec[Ofs + 1] := (D Shr 8) And $FF;
  Sec[Ofs + 2] := (D Shr 16) And $FF; Sec[Ofs + 3] := (D Shr 24) And $FF;
End;

Procedure PutDBE(Ofs : Integer; D : LongInt);
Begin
  Sec[Ofs] := (D Shr 24) And $FF; Sec[Ofs + 1] := (D Shr 16) And $FF;
  Sec[Ofs + 2] := (D Shr 8) And $FF; Sec[Ofs + 3] := D And $FF;
End;

{ Valeur 16 bits ecrite dans les deux ordres (LE puis BE) }
Procedure PutW2(Ofs : Integer; W : Word);
Begin
  PutW(Ofs, W); PutWBE(Ofs + 2, W);
End;

Procedure PutD2(Ofs : Integer; D : LongInt);
Begin
  PutD(Ofs, D); PutDBE(Ofs + 4, D);
End;

Procedure PutStr(Ofs, Len : Integer; Const S : String);
Var K : Integer;
Begin
  For K := 1 To Len Do
    If K <= Length(S) Then Sec[Ofs + K - 1] := Ord(S[K])
    Else Sec[Ofs + K - 1] := Ord(' ');
End;

{ Date et heure d enregistrement de repertoire (7 octets) }
Procedure PutDirDate(Ofs : Integer);
Begin
  PutB(Ofs, 126);      { annees depuis 1900 : 2026 }
  PutB(Ofs + 1, 1); PutB(Ofs + 2, 1);
  PutB(Ofs + 3, 0); PutB(Ofs + 4, 0); PutB(Ofs + 5, 0);
  PutB(Ofs + 6, 0);
End;

{ Date de volume (17 octets ASCII) }
Procedure PutVolDate(Ofs : Integer);
Begin
  PutStr(Ofs, 16, '2026010100000000');
  PutB(Ofs + 16, 0);
End;

{ Enregistrement de repertoire ; retourne sa longueur }
Function PutDirRec(Ofs : Integer; LBA, Size : LongInt; Flags : Byte;
                   Const Name : String; Special : Integer) : Integer;
Var Len, NLen : Integer;
Begin
  If Special >= 0 Then NLen := 1 Else NLen := Length(Name);
  Len := 33 + NLen;
  If Odd(Len) Then Inc(Len);
  PutB(Ofs, Len);
  PutB(Ofs + 1, 0);
  PutD2(Ofs + 2, LBA);
  PutD2(Ofs + 10, Size);
  PutDirDate(Ofs + 18);
  PutB(Ofs + 25, Flags);
  PutB(Ofs + 26, 0); PutB(Ofs + 27, 0);
  PutW2(Ofs + 28, 1);
  PutB(Ofs + 32, NLen);
  If Special >= 0 Then PutB(Ofs + 33, Special)
  Else PutStr(Ofs + 33, NLen, Name);
  PutDirRec := Len;
End;

Function SizeOfFile(Const N : String) : LongInt;
Var F : File;
Begin
  Assign(F, N);
  {$I-} Reset(F, 1); {$I+}
  If IOResult <> 0 Then
  Begin
    WriteLn('MAKEISO: fichier introuvable : ', N);
    Halt(1);
  End;
  SizeOfFile := FileSize(F);
  Close(F);
End;

Procedure CopyFileData(Const N : String; Size : LongInt);
Var F : File; Got : Integer; Left : LongInt;
Begin
  Assign(F, N);
  Reset(F, 1);
  Left := Size;
  While Left > 0 Do
  Begin
    FillSec(0);
    If Left >= SECT Then BlockRead(F, Sec, SECT, Got)
    Else BlockRead(F, Sec, Left, Got);
    WriteSec;
    Left := Left - SECT;
  End;
  Close(F);
End;

Procedure WriteRootDir;
Var Ofs, L, K : Integer; Name : String;
Begin
  FillSec(0);
  Ofs := 0;
  Ofs := Ofs + PutDirRec(Ofs, RootLBA, RootSectors * SECT, 2, '', 0);
  Ofs := Ofs + PutDirRec(Ofs, RootLBA, RootSectors * SECT, 2, '', 1);
  For K := 1 To NFiles Do
  Begin
    Name := IsoNames[K] + ';1';
    L := 33 + Length(Name);
    If Odd(L) Then Inc(L);
    If Ofs + L > SECT Then
    Begin
      { un enregistrement ne chevauche jamais deux secteurs }
      WriteSec; FillSec(0); Ofs := 0;
    End;
    Ofs := Ofs + PutDirRec(Ofs, FileLBA[K], FileSizes[K], 0, Name, -1);
  End;
  WriteSec;
End;

Function CountRootSectors : LongInt;
Var Ofs, L, K : Integer; N : LongInt;
Begin
  N := 1; Ofs := 34 + 34;
  For K := 1 To NFiles Do
  Begin
    L := 33 + Length(IsoNames[K]) + 2;
    If Odd(L) Then Inc(L);
    If Ofs + L > SECT Then Begin Inc(N); Ofs := 0 End;
    Ofs := Ofs + L;
  End;
  CountRootSectors := N;
End;

Procedure WriteBootCatalog;
Var Sum : LongInt; K : Integer; LoadCount : LongInt;
Begin
  FillSec(0);
  { entree de validation }
  PutB(0, 1);        { identificateur d en-tete }
  PutB(1, 0);        { plateforme 80x86 }
  PutStr(4, 24, 'OS/2-0');
  PutB($1E, $55); PutB($1F, $AA);
  Sum := 0;
  For K := 0 To 15 Do Sum := Sum + Sec[K * 2] + Sec[K * 2 + 1] * 256;
  PutW($1C, Word(-(Sum And $FFFF)));
  { entree initiale / par defaut }
  If BootIdx > 0 Then
  Begin
    LoadCount := (FileSizes[BootIdx] + 511) Div 512;
    If LoadCount < 1 Then LoadCount := 1;
    PutB($20, $88);     { amorcable }
    PutB($21, 0);       { sans emulation }
    PutW($22, 0);       { segment de chargement : 0 = 07C0h }
    PutB($24, 0);       { type de systeme }
    PutW($26, LoadCount);
    PutD($28, FileLBA[BootIdx]);
  End;
  WriteSec;
End;

Procedure WritePathTable(BigEndian : Boolean);
Begin
  FillSec(0);
  PutB(0, 1);       { longueur de l identificateur }
  PutB(1, 0);
  If BigEndian Then Begin PutDBE(2, RootLBA); PutWBE(6, 1) End
  Else Begin PutD(2, RootLBA); PutW(6, 1) End;
  PutB(8, 0);
  WriteSec;
End;

Procedure WritePVD;
Var Dummy : Integer;
Begin
  FillSec(0);
  PutB(0, 1);
  PutStr(1, 5, 'CD001');
  PutB(6, 1);
  PutStr(8, 32, 'OS2-0');
  PutStr(40, 32, VolLabel);
  PutD2(80, TotalSectors);
  PutW2(120, 1);              { taille de l ensemble }
  PutW2(124, 1);              { numero de sequence }
  PutW2(128, SECT);           { taille de bloc logique }
  PutD2(132, 10);             { taille de la table des chemins }
  PutD(140, 19);              { table L }
  PutD(144, 0);
  PutDBE(148, 20);            { table M }
  PutDBE(152, 0);
  Dummy := PutDirRec(156, RootLBA, RootSectors * SECT, 2, '', 0);
  PutStr(190, 128, '');
  PutStr(318, 128, 'GLADIR.COM');
  PutStr(446, 128, 'MAKEISO');
  PutStr(574, 128, 'OS2-0 MAKEISO');
  PutStr(702, 37, ''); PutStr(739, 37, ''); PutStr(776, 37, '');
  PutVolDate(813); PutVolDate(830);
  PutStr(847, 16, '0000000000000000'); PutB(863, 0);
  PutStr(864, 16, '0000000000000000'); PutB(880, 0);
  PutB(881, 1);
  WriteSec;
End;

Procedure WriteBootRecord;
Begin
  FillSec(0);
  PutB(0, 0);
  PutStr(1, 5, 'CD001');
  PutB(6, 1);
  PutStr(7, 32, 'EL TORITO SPECIFICATION');
  For I := 7 + 23 To 7 + 31 Do Sec[I] := 0;
  PutD($47, 21);               { secteur du catalogue d amorce }
  WriteSec;
End;

Procedure WriteTerminator;
Begin
  FillSec(0);
  PutB(0, 255);
  PutStr(1, 5, 'CD001');
  PutB(6, 1);
  WriteSec;
End;

Procedure ShowHelp;
Begin
  WriteLn('MAKEISO : Cette commande permet de fabriquer une image CD-ROM ISO 9660');
  WriteLn('          amorcable (El Torito, sans emulation) pour OS/2-0.');
  WriteLn;
  WriteLn('Syntaxe : MAKEISO image.iso [/BOOT:fichier] [/LABEL:nom] fichier [...]');
  WriteLn;
  WriteLn('  /BOOT:fichier  Fichier d''amorce (ex. OS2BOOT) charge en 0000:7C00');
  WriteLn('  /LABEL:nom     Etiquette du volume (defaut OS2_0)');
  Halt(0);
End;

BEGIN
  IsoName := ''; BootName := ''; VolLabel := 'OS2_0'; NFiles := 0;
  If ParamCount = 0 Then ShowHelp;
  For I := 1 To ParamCount Do
  Begin
    Arg := ParamStr(I);
    U := UpStr(Arg);
    If (U = '/?') Or (U = '/H') Or (U = '--HELP') Then ShowHelp
    Else If Copy(U, 1, 6) = '/BOOT:' Then BootName := Copy(Arg, 7, 255)
    Else If Copy(U, 1, 7) = '/LABEL:' Then VolLabel := UpStr(Copy(Arg, 8, 255))
    Else If IsoName = '' Then IsoName := Arg
    Else If NFiles < MAX_FILES Then
    Begin
      Inc(NFiles);
      FileNames[NFiles] := Arg;
    End;
  End;
  If IsoName = '' Then ShowHelp;
  { le fichier d amorce fait partie des fichiers du CD }
  BootIdx := 0;
  If BootName <> '' Then
  Begin
    For I := 1 To NFiles Do
      If UpStr(BaseName(FileNames[I])) = UpStr(BaseName(BootName)) Then BootIdx := I;
    If BootIdx = 0 Then
    Begin
      Inc(NFiles); FileNames[NFiles] := BootName; BootIdx := NFiles;
    End;
  End;
  For I := 1 To NFiles Do
  Begin
    IsoNames[I] := IsoFileName(FileNames[I]);
    FileSizes[I] := SizeOfFile(FileNames[I]);
  End;
  { tri des noms (ordre exige par ISO 9660) }
  For I := 1 To NFiles - 1 Do
    For J := I + 1 To NFiles Do
      If IsoNames[J] < IsoNames[I] Then
      Begin
        U := IsoNames[I]; IsoNames[I] := IsoNames[J]; IsoNames[J] := U;
        U := FileNames[I]; FileNames[I] := FileNames[J]; FileNames[J] := U;
        RootLBA := FileSizes[I]; FileSizes[I] := FileSizes[J]; FileSizes[J] := RootLBA;
        If BootIdx = I Then BootIdx := J Else If BootIdx = J Then BootIdx := I;
      End;
  RootLBA := 22;
  RootSectors := CountRootSectors;
  TotalSectors := RootLBA + RootSectors;
  For I := 1 To NFiles Do
  Begin
    FileLBA[I] := TotalSectors;
    TotalSectors := TotalSectors + (FileSizes[I] + SECT - 1) Div SECT;
    If FileSizes[I] = 0 Then FileLBA[I] := 0;
  End;
  Assign(Iso, IsoName);
  {$I-} Rewrite(Iso, SECT); {$I+}
  If IOResult <> 0 Then
  Begin
    WriteLn('MAKEISO: impossible de creer ', IsoName);
    Halt(1);
  End;
  FillSec(0);
  For I := 0 To 15 Do WriteSec;
  WritePVD;
  WriteBootRecord;
  WriteTerminator;
  WritePathTable(False);
  WritePathTable(True);
  WriteBootCatalog;
  WriteRootDir;
  For I := 1 To NFiles Do
    If FileSizes[I] > 0 Then CopyFileData(FileNames[I], FileSizes[I]);
  Close(Iso);
  WriteLn('MAKEISO: ', IsoName, ' : ', NFiles, ' fichier(s), ', TotalSectors,
          ' secteurs de 2048 octets');
  For I := 1 To NFiles Do
  Begin
    Write('  ', IsoNames[I]:12, FileSizes[I]:9, ' octets  LBA ', FileLBA[I]);
    If I = BootIdx Then Write('  (amorce El Torito)');
    WriteLn;
  End;
END.
