{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de NTFS.IFS sous OS/2-0.
}

Program TESTNTFS;

{ Compilation : OS2PC TESTNTFS.PAS   (produit TESTNTFS.EXE)

  TESTNTFS [unite] [GARDER] [FORMATER] [NOYAU] [GRAND]
                     verifie les 43 points d'entree de NTFS.IFS sur un
                     volume NTFS monte (D: par defaut : premiere partition
                     de type 07h du disque dur portant un volume NTFS) :
                     les fonctions FS_* sont appelees directement (le
                     pilote est deja charge par le noyau et partage), puis
                     par DOSCALLS.DLL. Les essais travaillent dans le
                     repertoire \TestNtfs du volume, supprime a la fin
                     (sauf avec GARDER, pour verifier le volume sous
                     Linux avec ntfs-3g). Si le volume contient les
                     fichiers de l'essai prepare sous Linux (\README.TXT,
                     \GROS.BIN, \BEAUCOUP...), ils sont relus.
                     FORMATER : le volume est d'abord reformate (NTFS 3.1,
                     FS_FSCTL 8000h, nom de volume OS2NTFS) ; les fichiers
                     sont alors gardes.
                     NOYAU : le volume (partition du premier disque dur)
                     est reformate par le noyau (KrnDiskCtl 11, systeme
                     de fichiers 'NTFS' : demontage, FS_MOUNT 3 puis
                     FS_FSCTL 8000h du pilote NTFS) ; les fichiers sont
                     gardes.
                     GRAND : 700 fichiers de plus dans \TestNtfs\Grand
                     (arbre B+ de trois niveaux, extension de la MFT),
                     dont la moitie est supprimee ; ils sont gardes. }

Function FS_ALLOCATEPAGESPACE(Psffsi, Psffsd, LSize, LWantContig : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_ATTACH(Flag, PDev, PVpfsd, PCdfsd, PParm, PLen : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_CANCELLOCKREQUEST(Psffsi, Psffsd, PLockRange : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_CHDIR(Flag, Pcdfsi, Pcdfsd, PDir, ICurDirEnd : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_CHGFILEPTR(Psffsi, Psffsd, Offset, MType, IOFlag : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_CLOSE(CType, IOFlag, Psffsi, Psffsd : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_COMMIT(CType, IOFlag, Psffsi, Psffsd : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_COPY(Flag, Pcdfsi, Pcdfsd, PSrc, ISrcEnd, PDst, IDstEnd, NameType : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_DELETE(Pcdfsi, Pcdfsd, PFile, ICurDirEnd : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_DOPAGEIO(Psffsi, Psffsd, PList : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_EXIT(Uid, Pid, Pdb : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FILEATTRIBUTE(Flag, Pcdfsi, Pcdfsd, PName, ICurDirEnd, PAttr : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FILEINFO(Flag, Psffsi, Psffsd, Level, PData, CbData, IOFlag : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FILEIO(Psffsi, Psffsd, PCmd, CbCmd, POError, IOFlag : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FILELOCKS(Psffsi, Psffsd, PUnlock, PLock, Timeout, Flags : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FINDCLOSE(Pfsfsi, Pfsfsd : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FINDFIRST(Pcdfsi, Pcdfsd, PName, ICurDirEnd, Attr, Pfsfsi, Pfsfsd, PData, CbData,
                      PcMatch, Level, Flags : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FINDFROMNAME(Pfsfsi, Pfsfsd, PData, CbData, PcMatch, Level, Position, PName, Flags : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FINDNEXT(Pfsfsi, Pfsfsd, PData, CbData, PcMatch, Level, Flag : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FINDNOTIFYCLOSE(Handle : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FINDNOTIFYFIRST(Pcdfsi, Pcdfsd, PName, ICurDirEnd, Attr, PHandle, PData, CbData, PcMatch,
                            Level, Timeout : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FINDNOTIFYNEXT(Handle, PData, CbData, PcMatch, Level, Timeout : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FLUSHBUF(HVpb, Flag : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FSCTL(PArgdat, IArgType, Func, PParm, LenParm, PLenParmIO, PData, LenData, PLenDataIO : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_FSINFO(Flag, HVpb, PData, CbData, Level : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_INIT(PParm, PDevHlp, PMiniFsd : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_IOCTL(Psffsi, Psffsd, Cat, Func, PParm, LenMaxParm, PLenParm, PData, LenMaxData, PLenData : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_MKDIR(Pcdfsi, Pcdfsd, PName, ICurDirEnd, PEABuf, Flags : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_MOUNT(Flag, PVpfsi, PVpfsd, HVpb, PBoot : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_MOVE(Pcdfsi, Pcdfsd, PSrc, ISrcEnd, PDst, IDstEnd, Flags : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_NEWSIZE(Psffsi, Psffsd, Len, IOFlag : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_NMPIPE(Psffsi, Psffsd, OpType, POpRec, PData, PName : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_OPENCREATE(Pcdfsi, Pcdfsd, PName, ICurDirEnd, Psffsi, Psffsd, OpenMode, OpenFlag,
                       PAction, Attr, PEABuf, PGenFlag : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_OPENPAGEFILE(PFlags, PcMaxReq, PName, Psffsi, Psffsd, OpenMode, OpenFlag, Attr, Reserved : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_PATHINFO(Flag, Pcdfsi, Pcdfsd, PName, ICurDirEnd, Level, PData, CbData : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_PROCESSNAME(PNameBuf : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_READ(Psffsi, Psffsd, PData, PLen, IOFlag : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_RMDIR(Pcdfsi, Pcdfsd, PName, ICurDirEnd : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_SETSWAP(Psffsi, Psffsd : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_SHUTDOWN(SType, Reserved : LongInt) : LongInt; External 'NTFS.IFS';
Function FS_WRITE(Psffsi, Psffsd, PData, PLen, IOFlag : LongInt) : LongInt; External 'NTFS.IFS';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFSAttach(PDev, Ordinal, Level, PBuf, PCb : LongInt) : LongInt; External 'DOSCALLS';
Function KDisk(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnDiskCtl';

Const
  NO_ERROR = 0;
  ERROR_FILE_NOT_FOUND = 2;
  ERROR_ACCESS_DENIED = 5;
  ERROR_NOT_DOS_DISK = 26;
  ERROR_LOCK_VIOLATION = 33;
  ERROR_NOT_SUPPORTED = 50;
  ERROR_NO_MORE_FILES = 18;
  ERROR_DIR_NOT_EMPTY = 145;
  ERROR_EAS_NOT_SUPPORTED = 282;
  ERROR_TIMEOUT = 640;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, I, J, N, H, Act, Gen, Cnt, HV, A, Hnd : LongInt;
  Drive : Char;
  Keep, Fmt, Linux, Grand, KFmt : Boolean;
  Part : Array[0..7] Of LongInt;
  Cd : Array[0..271] Of Byte;             { CDFSI }
  Cdd : Array[0..15] Of Byte;             { CDFSD }
  Sfi, Sfi2 : Array[0..63] Of Byte;       { SFFSI }
  Sfd, Sfd2 : Array[0..31] Of Byte;       { SFFSD }
  Fsi : Array[0..7] Of Byte;              { FSFSI }
  Fsd : Array[0..31] Of Byte;             { FSFSD }
  Name, Name2 : Array[0..299] Of Byte;
  Buf, Buf2 : Array[0..8191] Of Byte;
  Big : Array[0..65535] Of Byte;
  Info : Array[0..511] Of Byte;
  Fea : Array[0..511] Of Byte;
  Eaop : Array[0..2] Of LongInt;
  Rng : Array[0..1] Of LongInt;
  Stat : Array[0..15] Of LongInt;
  S : String;

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
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do WrB(A + I - 1, Ord(S[I]));
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

{ Chemin du volume d'essai dans Name (ou Name2) }
Function P1(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name), Drive + ':' + S);
  P1 := LongInt(@Name);
End;

Function P2(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name2), Drive + ':' + S);
  P2 := LongInt(@Name2);
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

{ Ouvrir ou creer (flags OS/2) un fichier dans Sfi/Sfd }
Function Open(Path : String; Mode, Flags : LongInt) : LongInt;
Begin
  FillChar(Sfi, 64, 0);
  FillChar(Sfd, 32, 0);
  WrL(LongInt(@Sfi) + 4, HV);
  WrL(LongInt(@Sfi) + 32, 777);
  Open := FS_OPENCREATE(LongInt(@Cd), LongInt(@Cdd), P1(Path), -1, LongInt(@Sfi), LongInt(@Sfd),
                        Mode, Flags, LongInt(@Act), 0, 0, LongInt(@Gen));
End;

Function Open2(Path : String; Mode, Flags : LongInt) : LongInt;
Begin
  FillChar(Sfi2, 64, 0);
  FillChar(Sfd2, 32, 0);
  WrL(LongInt(@Sfi2) + 4, HV);
  WrL(LongInt(@Sfi2) + 32, 778);
  Open2 := FS_OPENCREATE(LongInt(@Cd), LongInt(@Cdd), P1(Path), -1, LongInt(@Sfi2), LongInt(@Sfd2),
                         Mode, Flags, LongInt(@Act), 0, 0, LongInt(@Gen));
End;

Function Close1 : LongInt;
Begin
  Close1 := FS_CLOSE(2, 0, LongInt(@Sfi), LongInt(@Sfd));
End;

Function Write1(A, Len : LongInt) : LongInt;
Begin
  Cnt := Len;
  Write1 := FS_WRITE(LongInt(@Sfi), LongInt(@Sfd), A, LongInt(@Cnt), 0);
End;

Function Read1(A, Len : LongInt) : LongInt;
Begin
  Cnt := Len;
  Read1 := FS_READ(LongInt(@Sfi), LongInt(@Sfd), A, LongInt(@Cnt), 0);
End;

Function Seek1(Ofs : LongInt) : LongInt;
Begin
  Seek1 := FS_CHGFILEPTR(LongInt(@Sfi), LongInt(@Sfd), Ofs, 0, 0);
End;

{ Taille (FS_PATHINFO niveau 1), ou -1 }
Function SizeOf1(Path : String) : LongInt;
Begin
  R := FS_PATHINFO(0, LongInt(@Cd), LongInt(@Cdd), P1(Path), -1, 1, LongInt(@Info), 24);
  If R = 0 Then SizeOf1 := RdL(LongInt(@Info) + 12) Else SizeOf1 := -1;
End;

{ Nombre d'entrees d'un repertoire (masque), "." et ".." compris }
Function CountDir(Mask : String) : LongInt;
Var C, M, Q : LongInt;
Begin
  C := 0;
  FillChar(Fsi, 8, 0); FillChar(Fsd, 32, 0);
  WrL(LongInt(@Fsi), HV);
  M := 20;
  Q := FS_FINDFIRST(LongInt(@Cd), LongInt(@Cdd), P1(Mask), -1, $37, LongInt(@Fsi), LongInt(@Fsd),
                    LongInt(@Buf), 8192, LongInt(@M), 1, 0);
  While Q = 0 Do
  Begin
    C := C + M;
    M := 20;
    Q := FS_FINDNEXT(LongInt(@Fsi), LongInt(@Fsd), LongInt(@Buf), 8192, LongInt(@M), 1, 0);
  End;
  FS_FINDCLOSE(LongInt(@Fsi), LongInt(@Fsd));
  CountDir := C;
End;

{ EAOP2 avec un FEA2LIST d'un EA (nom, valeur) }
Function MakeEa(EName, EValue : String) : LongInt;
Var F : LongInt;
Begin
  F := LongInt(@Fea);
  FillChar(Fea, 512, 0);
  WrL(F + 4, 0);
  WrB(F + 8, 0);
  WrB(F + 9, Length(EName));
  WrW(F + 10, Length(EValue));
  PutZ(F + 12, EName);
  For I := 1 To Length(EValue) Do WrB(F + 13 + Length(EName) + I - 1, Ord(EValue[I]));
  WrL(F, 4 + 9 + Length(EName) + Length(EValue));
  Eaop[0] := 0;
  Eaop[1] := F;
  Eaop[2] := 0;
  MakeEa := LongInt(@Eaop);
End;

{ Verification du volume (FS_FSCTL 8001h) : erreurs + perdus }
Function Chkdsk : LongInt;
Begin
  Stat[0] := HV; Stat[1] := 0;
  R := FS_FSCTL(0, 3, $8001, LongInt(@Stat), 8, 0, LongInt(@Stat[4]), 36, LongInt(@N));
  If R = 0 Then Chkdsk := Stat[4] + Stat[5] Else Chkdsk := -1;
End;

Function ChkText : String;
Begin
  ChkText := IStr(Stat[6]) + ' repertoire(s), ' + IStr(Stat[7]) + ' fichier(s), ' +
             IStr(Stat[8]) + ' enregistrement(s), ' + IStr(Stat[4]) + ' erreur(s), ' +
             IStr(Stat[5]) + ' perdu(s)';
End;

{ Contenu d'un petit fichier (255 octets au plus) }
Function ReadAll(Path : String) : String;
Var T : String;
Begin
  T := '';
  If Open(Path, $40, $01) = 0 Then
  Begin
    If Read1(LongInt(@Buf2), 255) = 0 Then
      For I := 0 To Cnt - 1 Do T := T + Chr(Buf2[I]);
    Close1;
  End;
  ReadAll := T;
End;

{ Supprimer une arborescence (reste d'un essai precedent lance avec GARDER) }
Procedure RemoveTree(Path : String; Depth : LongInt);
Var Q, M, E, At : LongInt; Nm : String; IsDir : Boolean;
    Fi : Array[0..7] Of Byte; Fd : Array[0..31] Of Byte;
Begin
  If Depth > 8 Then Exit;
  FillChar(Fi, 8, 0); FillChar(Fd, 32, 0);
  WrL(LongInt(@Fi), HV);
  M := 1;
  Q := FS_FINDFIRST(LongInt(@Cd), LongInt(@Cdd), P1(Path + '\*'), -1, $37, LongInt(@Fi), LongInt(@Fd),
                    LongInt(@Buf), 8192, LongInt(@M), 1, 0);
  { la recherche reprend apres le dernier nom rendu : on peut supprimer
    les entrees au fur et a mesure }
  While Q = 0 Do
  Begin
    E := LongInt(@Buf);
    Nm := GetZ(E + 29);
    IsDir := (RdL(E + 24) And $10) <> 0;
    If (Nm <> '.') And (Nm <> '..') Then
    Begin
      If IsDir Then RemoveTree(Path + '\' + Nm, Depth + 1)
      Else
      Begin
        At := $20;
        FS_FILEATTRIBUTE(1, LongInt(@Cd), LongInt(@Cdd), P1(Path + '\' + Nm), -1, LongInt(@At));
        Q := FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1(Path + '\' + Nm), -1);
        If Q <> 0 Then WriteLn('  (suppression de ', Path, '\', Nm, ' : erreur ', Q, ')');
      End;
    End;
    M := 1;
    Q := FS_FINDNEXT(LongInt(@Fi), LongInt(@Fd), LongInt(@Buf), 8192, LongInt(@M), 1, 0);
  End;
  FS_FINDCLOSE(LongInt(@Fi), LongInt(@Fd));
  Q := FS_RMDIR(LongInt(@Cd), LongInt(@Cdd), P1(Path), -1);
  If (Q <> 0) And (Q <> 3) Then WriteLn('  (suppression de ', Path, ' : erreur ', Q, ')');
End;

BEGIN
  Ok := 0; Fail := 0;
  Drive := 'D';
  Keep := False;
  Fmt := False;
  Grand := False;
  KFmt := False;
  For I := 1 To ParamCount Do
  Begin
    S := ParamStr(I);
    If (S = 'GARDER') Or (S = 'garder') Then Keep := True
    Else If (S = 'FORMATER') Or (S = 'formater') Then Fmt := True
    Else If (S = 'GRAND') Or (S = 'grand') Then Grand := True
    Else If (S = 'NOYAU') Or (S = 'noyau') Then KFmt := True
    Else If Length(S) > 0 Then Drive := UpCase(S[1]);
  End;
  If Fmt Or Grand Or KFmt Then Keep := True;
  HV := Ord(Drive) - 65;
  WriteLn('TESTNTFS : essai de NTFS.IFS sur l''unite ', Drive, ':');
  FillChar(Cd, 272, 0);
  WrL(LongInt(@Cd), HV);
  WrL(LongInt(@Cd) + 4, -1);
  PutZ(LongInt(@Cd) + 12, Drive + ':\');

  { --- module, donnees exportees, initialisation --- }
  PutZ(LongInt(@Name), 'NTFS.IFS');
  R := DosQueryModuleHandle(LongInt(@Name), LongInt(@H));
  Check('NTFS.IFS charge par le noyau (IFS= de CONFIG.SYS)', R = 0);
  PutZ(LongInt(@Name), 'FS_NAME');
  R := DosQueryProcAddr(H, 0, LongInt(@Name), LongInt(@A));
  Check('FS_NAME = "NTFS" (donnee exportee)', (R = 0) And (GetZ(A) = 'NTFS'));
  PutZ(LongInt(@Name), 'FS_ATTRIBUTE');
  R := DosQueryProcAddr(H, 0, LongInt(@Name), LongInt(@A));
  Check('FS_ATTRIBUTE = FSA_LVL7 (donnee exportee)', (R = 0) And (RdL(A) = 8));
  PutZ(LongInt(@Name), '/CACHE:64');
  R := FS_INIT(LongInt(@Name), 0, 0);
  Check('FS_INIT (nouvel appel : options seulement)', R = 0);

  { --- formatage par le noyau (KrnDiskCtl 11, systeme 'NTFS') --- }
  If KFmt Then
  Begin
    { partition du premier disque dur montee sous cette lettre }
    Part[0] := 0; Part[1] := 1; Part[2] := LongInt(@Buf);
    R := KDisk(2, 0, LongInt(@Part));
    J := -1;
    If R = 0 Then
      For I := 0 To 3 Do
        If (Buf[446 + I * 16 + 4] = 7) And (KDisk(4, 0, RdL(LongInt(@Buf) + 446 + I * 16 + 8)) = HV) Then J := I;
    Check('partition de ' + Drive + ': trouvee (KrnDiskCtl 2 et 4)', J >= 0);
    If J >= 0 Then
    Begin
      PutZ(LongInt(@Name2), 'NOYAUNTFS');
      PutZ(LongInt(@Name2) + 100, 'NTFS');
      Part[0] := RdL(LongInt(@Buf) + 446 + J * 16 + 8);
      Part[1] := RdL(LongInt(@Buf) + 446 + J * 16 + 12);
      Part[2] := LongInt(@Name2);
      Part[3] := -1;
      Part[4] := LongInt(@Name2) + 100;
      R := KDisk(11, 0, LongInt(@Part));
      Check('KrnDiskCtl 11 : formatage NTFS de ' + Drive + ': par le noyau', (R = 0) And (Part[3] = HV));
      R := FS_FSINFO(0, HV, LongInt(@Info), 40, 2);
      Check('nom du volume formate : NOYAUNTFS', (R = 0) And (GetZ(LongInt(@Info) + 5) = 'NOYAUNTFS'));
      N := Chkdsk;
      Check('FS_FSCTL 8001h : volume formate coherent (' + ChkText + ')', (N = 0) And (Stat[6] = 1) And (Stat[7] = 0));
    End;
  End;

  { --- formatage (FS_FSCTL 8000h) --- }
  If Fmt Then
  Begin
    PutZ(LongInt(@Name2), 'OS2NTFS');
    Stat[0] := HV; Stat[1] := LongInt(@Name2);
    R := FS_FSCTL(0, 3, $8000, LongInt(@Stat), 8, 0, 0, 0, 0);
    Check('FS_FSCTL 8000h : formatage NTFS 3.1 de ' + Drive + ':', R = 0);
    R := FS_FSINFO(0, HV, LongInt(@Info), 40, 2);
    Check('nom du volume formate : OS2NTFS', (R = 0) And (GetZ(LongInt(@Info) + 5) = 'OS2NTFS'));
    N := Chkdsk;
    Check('FS_FSCTL 8001h : volume formate coherent (' + ChkText + ')', (N = 0) And (Stat[6] = 1) And (Stat[7] = 0));
  End;

  { --- volume --- }
  R := FS_FSINFO(0, HV, LongInt(@Info), 18, 1);
  Check('FS_FSINFO niveau 1 (' + IStr(RdL(LongInt(@Info) + 4)) + ' secteur(s) par cluster, ' +
        IStr(RdL(LongInt(@Info) + 12)) + ' clusters libres sur ' + IStr(RdL(LongInt(@Info) + 8)) + ')',
        (R = 0) And (RdW(LongInt(@Info) + 16) = 512) And (RdL(LongInt(@Info) + 8) > 0));
  R := FS_FSINFO(0, HV, LongInt(@Info), 40, 2);
  S := '';
  For I := 1 To RdB(LongInt(@Info) + 4) Do S := S + Chr(RdB(LongInt(@Info) + 4 + I));
  Check('FS_FSINFO niveau 2 (nom de volume "' + S + '")', R = 0);
  WrB(LongInt(@Info) + 100, 5);
  PutZ(LongInt(@Info) + 101, 'ESSAI');
  R := FS_FSINFO(1, HV, LongInt(@Info) + 100, 6, 2);
  FS_FSINFO(0, HV, LongInt(@Info) + 200, 40, 2);
  Check('FS_FSINFO : changer le nom de volume', (R = 0) And (GetZ(LongInt(@Info) + 205) = 'ESSAI'));
  WrB(LongInt(@Info) + 100, Length(S));
  PutZ(LongInt(@Info) + 101, S);
  FS_FSINFO(1, HV, LongInt(@Info) + 100, 1 + Length(S), 2);
  N := 512;
  R := DosQueryFSAttach(P1(''), 0, 1, LongInt(@Buf), LongInt(@N));
  Check('DosQueryFSAttach ' + Drive + ': -> NTFS', (R = 0) And (GetZ(LongInt(@Buf) + 11) = 'NTFS'));
  N := Chkdsk;
  Check('FS_FSCTL 8001h : volume coherent au depart (' + ChkText + ')', N = 0);

  { --- fichiers ecrits sous Linux (ntfs-3g), s'ils sont presents --- }
  Linux := SizeOf1('\README.TXT') > 0;
  If Linux Then
  Begin
    Check('lecture de \README.TXT (resident, ecrit par ntfs-3g)',
          Copy(ReadAll('\readme.txt'), 1, 31) = 'Bonjour depuis Linux (ntfs-3g).');
    R := Open('\GROS.BIN', $40, $01);
    J := 0; N := 0;
    If R = 0 Then
    Begin
      While (Read1(LongInt(@Big), 65536) = 0) And (Cnt > 0) Do
      Begin
        For I := 0 To Cnt - 1 Do If Big[I] <> ((N + I) * 7 + 3) And 255 Then Inc(J);
        N := N + Cnt;
      End;
      Close1;
    End;
    Check('lecture de \GROS.BIN (300000 octets, non resident)', (R = 0) And (N = 300000) And (J = 0));
    Check('nom long : \Un nom de fichier long.texte (1050 octets)', SizeOf1('\UN NOM DE FICHIER LONG.TEXTE') = 1050);
    Check('nom UTF-16 -> page 850 : \R'#130'pertoire '#130't'#130'\Fiche '#133' lire.txt',
          Copy(ReadAll('\R'#130'pertoire '#130't'#130'\Fiche '#133' lire.txt'), 1, 7) = 'accents');
    R := FS_PATHINFO(0, LongInt(@Cd), LongInt(@Cdd), P1('\r'#144'pertoire '#144't'#144), -1, 7, LongInt(@Buf), 300);
    Check('majuscules accentuees ($UpCase) : \r'#144'pertoire '#144't'#144' -> R'#130'pertoire '#130't'#130,
          (R = 0) And (GetZ(LongInt(@Buf)) = Drive + ':\R'#130'pertoire '#130't'#130));
    Check('\BEAUCOUP : 300 fichiers (index B+ de blocs INDX)', CountDir('\BEAUCOUP\*.dat') = 300);
    J := 0;
    For I := 0 To 299 Do
      If (I Mod 7 = 0) And (SizeOf1('\BEAUCOUP\Fichier numero ' + Copy(IStr(10000 + I), 2, 4) +
          ' du repertoire.dat') <> I) Then Inc(J);
    Check('\BEAUCOUP : recherche par nom dans l''arbre B+', J = 0);
    Check('\SOUS\NIVEAU2\PROFOND.TXT', SizeOf1('\Sous\Niveau2\Profond.txt') = 9);
    { \BEAUCOUP a une liste d'attributs ($INDEX_ROOT dans un enregistrement
      d'extension) : ecriture dans son index }
    R := Open('\BEAUCOUP\Ajout depuis OS2.txt', $42, $10);
    If R = 0 Then
    Begin
      PutZ(LongInt(@Buf), 'ajout');
      Write1(LongInt(@Buf), 5);
      Close1;
    End;
    Check('creation dans \BEAUCOUP (index dont la racine est dans une extension)',
          (R = 0) And (CountDir('\BEAUCOUP\*') = 303) And (SizeOf1('\BEAUCOUP\AJOUT DEPUIS OS2.TXT') = 5));
    R := FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\BEAUCOUP\Fichier numero 0150 du repertoire.dat'), -1);
    Check('suppression dans \BEAUCOUP', (R = 0) And (CountDir('\BEAUCOUP\*.dat') = 299) And
          (SizeOf1('\BEAUCOUP\Fichier numero 0151 du repertoire.dat') = 151));
    N := Chkdsk;
    Check('FS_FSCTL 8001h : volume coherent apres les modifications de \BEAUCOUP (' + ChkText + ')', N = 0);
  End;

  { --- repertoires --- }
  RemoveTree('\TestNtfs', 0);
  R := FS_MKDIR(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs'), -1, 0, 0);
  Check('FS_MKDIR \TestNtfs', R = 0);
  R := FS_MKDIR(LongInt(@Cd), LongInt(@Cdd), P1('\TESTNTFS'), -1, 0, 0);
  Check('FS_MKDIR existant refuse (noms sans casse)', R = ERROR_ACCESS_DENIED);
  R := FS_CHDIR(0, LongInt(@Cd), LongInt(@Cdd), P1('\testntfs'), -1);
  Check('FS_CHDIR \testntfs', (R = 0) And (RdL(LongInt(@Cdd)) >= 16));
  FS_CHDIR(2, LongInt(@Cd), LongInt(@Cdd), 0, -1);
  R := FS_CHDIR(0, LongInt(@Cd), LongInt(@Cdd), P1('\Inexistant'), -1);
  Check('FS_CHDIR repertoire inexistant refuse', R <> 0);
  R := FS_MKDIR(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\AvecEA'), -1, MakeEa('.COMMENTS', 'x'), 0);
  Check('FS_MKDIR avec un EA (EA ignores)', R = 0);

  { --- fichier : creation, ecriture, lecture --- }
  R := Open('\TestNtfs\Fichier avec un nom long.texte', $42, $10);
  Check('FS_OPENCREATE creation (nom long avec espaces)', (R = 0) And (Act = 2));
  For I := 0 To 2999 Do Buf[I] := (I * 7 + 3) And 255;
  R := Write1(LongInt(@Buf), 100);
  Check('FS_WRITE 100 octets (donnees residentes)', (R = 0) And (Cnt = 100));
  R := Write1(LongInt(@Buf) + 100, 2900);
  Check('FS_WRITE 2900 octets (passage en non resident)', (R = 0) And (Cnt = 2900) And (RdL(LongInt(@Sfi) + 20) = 3000));
  R := Seek1(0);
  Check('FS_CHGFILEPTR debut', (R = 0) And (RdL(LongInt(@Sfi) + 24) = 0));
  FillChar(Buf2, 3000, 0);
  R := Read1(LongInt(@Buf2), 4000);
  J := 0;
  For I := 0 To 2999 Do If Buf2[I] <> Buf[I] Then Inc(J);
  Check('FS_READ (3000 octets relus, identiques)', (R = 0) And (Cnt = 3000) And (J = 0));
  R := FS_CHGFILEPTR(LongInt(@Sfi), LongInt(@Sfd), -10, 0, 0);
  Check('FS_CHGFILEPTR negatif refuse', R = 131);
  R := FS_NEWSIZE(LongInt(@Sfi), LongInt(@Sfd), 1000, 0);
  Check('FS_NEWSIZE 1000 (troncature)', (R = 0) And (RdL(LongInt(@Sfi) + 20) = 1000));
  R := FS_NEWSIZE(LongInt(@Sfi), LongInt(@Sfd), 5000, 0);
  Seek1(990);
  Read1(LongInt(@Buf2), 100);
  J := 0;
  For I := 0 To 9 Do If Buf2[I] <> Buf[990 + I] Then Inc(J);
  For I := 10 To 99 Do If Buf2[I] <> 0 Then Inc(J);
  Check('FS_NEWSIZE 5000 (extension par des zeros)', (R = 0) And (J = 0) And (RdL(LongInt(@Sfi) + 20) = 5000));
  R := FS_FILEINFO(0, LongInt(@Sfi), LongInt(@Sfd), 1, LongInt(@Info), 24, 0);
  Check('FS_FILEINFO niveau 1 (taille 5000, archive)', (R = 0) And (RdL(LongInt(@Info) + 12) = 5000) And
        ((RdL(LongInt(@Info) + 20) And $20) <> 0));
  R := FS_FILEINFO(1, LongInt(@Sfi), LongInt(@Sfd), 2, MakeEa('.TYPE', 'Plain Text'), 12, 0);
  Check('FS_FILEINFO niveau 2 : EA refuses (ERROR_EAS_NOT_SUPPORTED)', R = ERROR_EAS_NOT_SUPPORTED);
  R := FS_FILEINFO(0, LongInt(@Sfi), LongInt(@Sfd), 2, LongInt(@Info), 28, 0);
  Check('FS_FILEINFO niveau 2 (cbList = 4 : pas d''EA)', (R = 0) And (RdL(LongInt(@Info) + 24) = 4));
  R := FS_COMMIT(0, 0, LongInt(@Sfi), LongInt(@Sfd));
  Check('FS_COMMIT', R = 0);

  { --- verrous et entrees/sorties groupees --- }
  R := Open2('\TestNtfs\Fichier avec un nom long.texte', $40, $01);
  Check('seconde ouverture (partage)', R = 0);
  Rng[0] := 0; Rng[1] := 100;
  R := FS_FILELOCKS(LongInt(@Sfi), LongInt(@Sfd), 0, LongInt(@Rng), 0, 0);
  Check('FS_FILELOCKS verrouiller 0..99', R = 0);
  Cnt := 10;
  R := FS_READ(LongInt(@Sfi2), LongInt(@Sfd2), LongInt(@Buf2), LongInt(@Cnt), 0);
  Check('lecture d''une plage verrouillee refusee', R = ERROR_LOCK_VIOLATION);
  R := FS_CANCELLOCKREQUEST(LongInt(@Sfi2), LongInt(@Sfd2), LongInt(@Rng));
  Check('FS_CANCELLOCKREQUEST', R = 0);
  R := FS_FILELOCKS(LongInt(@Sfi), LongInt(@Sfd), LongInt(@Rng), 0, 0, 0);
  Cnt := 10;
  WrL(LongInt(@Sfi2) + 24, 0);
  J := FS_READ(LongInt(@Sfi2), LongInt(@Sfd2), LongInt(@Buf2), LongInt(@Cnt), 0);
  Check('FS_FILELOCKS deverrouiller (lecture permise)', (R = 0) And (J = 0) And (Cnt = 10));
  A := LongInt(@Info);
  FillChar(Info, 64, 0);
  WrW(A, 2); WrW(A + 2, 0); WrL(A + 4, 20);
  WrW(A + 12, 3); WrL(A + 14, LongInt(@Buf2)); WrW(A + 18, 8);
  R := FS_FILEIO(LongInt(@Sfi2), LongInt(@Sfd2), A, 22, LongInt(@N), 0);
  Check('FS_FILEIO (deplacer + lire)', (R = 0) And (RdL(A + 8) = 20) And (RdW(A + 20) = 8) And (Buf2[0] = Buf[20]));
  FS_CLOSE(2, 0, LongInt(@Sfi2), LongInt(@Sfd2));
  R := FS_IOCTL(LongInt(@Sfi), LongInt(@Sfd), 8, $63, 0, 0, 0, LongInt(@Info), 64, LongInt(@N));
  Check('FS_IOCTL categorie 8 fonction 63h (BPB : 512 octets/secteur)', (R = 0) And (RdW(LongInt(@Info)) = 512));
  R := Close1;
  Check('FS_CLOSE', R = 0);

  { --- informations par chemin --- }
  Check('FS_PATHINFO niveau 1 (taille 5000)', SizeOf1('\TESTNTFS\FICHIER AVEC UN NOM LONG.TEXTE') = 5000);
  R := FS_PATHINFO(0, LongInt(@Cd), LongInt(@Cdd), P1('\TESTNTFS\FICHIER AVEC UN NOM LONG.TEXTE'), -1, 7,
                   LongInt(@Buf), 300);
  Check('FS_PATHINFO niveau 7 (casse conservee)', (R = 0) And
        (GetZ(LongInt(@Buf)) = Drive + ':\TestNtfs\Fichier avec un nom long.texte'));
  A := $21;
  R := FS_FILEATTRIBUTE(1, LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Fichier avec un nom long.texte'), -1, LongInt(@A));
  A := 0;
  J := FS_FILEATTRIBUTE(0, LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Fichier avec un nom long.texte'), -1, LongInt(@A));
  Check('FS_FILEATTRIBUTE lecture seule', (R = 0) And (J = 0) And (A = $21));
  R := FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Fichier avec un nom long.texte'), -1);
  Check('FS_DELETE d''un fichier en lecture seule refuse', R = ERROR_ACCESS_DENIED);
  A := $20;
  FS_FILEATTRIBUTE(1, LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Fichier avec un nom long.texte'), -1, LongInt(@A));

  { --- copie, deplacement --- }
  R := FS_COPY(0, LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Fichier avec un nom long.texte'), -1,
               P2('\TestNtfs\Copie.txt'), -1, 0);
  Check('FS_COPY (donnees)', (R = 0) And (SizeOf1('\TestNtfs\Copie.txt') = 5000));
  R := FS_COPY(0, LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Fichier avec un nom long.texte'), -1,
               P2('\TestNtfs\Copie.txt'), -1, 0);
  Check('FS_COPY sur un fichier existant refuse', R <> 0);
  R := FS_MOVE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Copie.txt'), -1, P2('\TestNtfs\Renomme.TXT'), -1, 0);
  Check('FS_MOVE (renommer)', (R = 0) And (SizeOf1('\TestNtfs\Copie.txt') = -1) And
        (SizeOf1('\TestNtfs\renomme.txt') = 5000));
  FS_MKDIR(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Sous repertoire'), -1, 0, 0);
  R := FS_MOVE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Renomme.TXT'), -1, P2('\TestNtfs\Sous repertoire\Deplace.txt'), -1, 0);
  Check('FS_MOVE (vers un autre repertoire)', (R = 0) And (SizeOf1('\TestNtfs\Sous repertoire\Deplace.txt') = 5000));
  R := FS_MOVE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs'), -1, P2('\TestNtfs\Sous repertoire\X'), -1, 0);
  Check('FS_MOVE d''un repertoire dans lui-meme refuse', R <> 0);
  R := FS_MOVE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Sous repertoire'), -1, P2('\TestNtfs\Sous R'#130'pertoire'), -1, 0);
  Check('FS_MOVE d''un repertoire (nom accentue)', (R = 0) And
        (SizeOf1('\TestNtfs\SOUS R'#144'PERTOIRE\Deplace.txt') = 5000));

  { --- recherche --- }
  FillChar(Fsi, 8, 0); FillChar(Fsd, 32, 0);
  WrL(LongInt(@Fsi), HV);
  N := 10;
  R := FS_FINDFIRST(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\*'), -1, $37, LongInt(@Fsi), LongInt(@Fsd),
                    LongInt(@Buf), 8192, LongInt(@N), 1, 0);
  Check('FS_FINDFIRST * (., .., 1 fichier, 2 repertoires)', (R = 0) And (N = 5) And (GetZ(LongInt(@Buf) + 29) = '.'));
  N := 10;
  R := FS_FINDNEXT(LongInt(@Fsi), LongInt(@Fsd), LongInt(@Buf), 8192, LongInt(@N), 1, 0);
  Check('FS_FINDNEXT : plus de fichiers', R = ERROR_NO_MORE_FILES);
  PutZ(LongInt(@Name2), 'AvecEA');
  N := 1;
  R := FS_FINDFROMNAME(LongInt(@Fsi), LongInt(@Fsd), LongInt(@Buf), 8192, LongInt(@N), 1, 0, LongInt(@Name2), 0);
  Check('FS_FINDFROMNAME "AvecEA" -> "Fichier avec un nom long.texte"', (R = 0) And (N = 1) And
        (GetZ(LongInt(@Buf) + 29) = 'Fichier avec un nom long.texte'));
  R := FS_FINDCLOSE(LongInt(@Fsi), LongInt(@Fsd));
  Check('FS_FINDCLOSE', R = 0);
  N := 4;
  WrL(LongInt(@Buf), 0);
  R := FS_FINDFIRST(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\*.texte'), -1, $37, LongInt(@Fsi), LongInt(@Fsd),
                    LongInt(@Buf), 8192, LongInt(@N), 3, 0);
  Check('FS_FINDFIRST niveau 3 (FEA2LIST vide)', (R = 0) And (N = 1) And (RdL(LongInt(@Buf) + 12 + 28) = 4));
  FS_FINDCLOSE(LongInt(@Fsi), LongInt(@Fsd));

  { --- beaucoup de fichiers : index B+ en blocs INDX --- }
  J := 0;
  For I := 1 To 150 Do
  Begin
    If Open('\TestNtfs\Fichier numero ' + IStr(1000 + I) + ' du grand repertoire.dat', $42, $10) = 0 Then
    Begin
      Write1(LongInt(@Buf), I);
      Close1;
    End
    Else
      Inc(J);
  End;
  Check('150 fichiers crees (index B+)', (J = 0) And (CountDir('\TestNtfs\*.dat') = 150));
  N := Chkdsk;
  Check('FS_FSCTL 8001h : volume coherent apres les creations (' + ChkText + ')', N = 0);
  J := 0;
  For I := 1 To 150 Do
    If Odd(I) Then
      If FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Fichier numero ' + IStr(1000 + I) +
                   ' du grand repertoire.dat'), -1) <> 0 Then Inc(J);
  Check('75 fichiers supprimes', (J = 0) And (CountDir('\TestNtfs\*.dat') = 75));
  J := 0;
  For I := 2 To 150 Do
    If Not Odd(I) Then
      If SizeOf1('\TestNtfs\Fichier numero ' + IStr(1000 + I) + ' du grand repertoire.dat') <> I Then Inc(J);
  Check('les 75 autres sont intacts (taille)', J = 0);
  N := Chkdsk;
  Check('FS_FSCTL 8001h : volume coherent apres les suppressions (' + ChkText + ')', N = 0);

  { --- tres grand repertoire (option GRAND) --- }
  If Grand Then
  Begin
    R := FS_MKDIR(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Grand'), -1, 0, 0);
    J := 0;
    For I := 1 To 700 Do
    Begin
      If Open('\TestNtfs\Grand\Element numero ' + IStr(5000 - I * 7) + ' avec un nom assez long pour remplir les blocs.txt',
              $42, $10) = 0 Then
      Begin
        Write1(LongInt(@Buf), I Mod 300);
        Close1;
      End
      Else
        Inc(J);
    End;
    Check('700 fichiers crees dans \TestNtfs\Grand (arbre B+ de trois niveaux)', (J = 0) And (CountDir('\TestNtfs\Grand\*') = 702));
    J := 0;
    For I := 1 To 700 Do
      If SizeOf1('\TestNtfs\Grand\ELEMENT NUMERO ' + IStr(5000 - I * 7) +
                 ' AVEC UN NOM ASSEZ LONG POUR REMPLIR LES BLOCS.TXT') <> I Mod 300 Then Inc(J);
    Check('700 recherches par nom dans l''arbre B+', J = 0);
    J := 0;
    For I := 1 To 700 Do
      If I Mod 2 = 1 Then
        If FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Grand\Element numero ' + IStr(5000 - I * 7) +
                     ' avec un nom assez long pour remplir les blocs.txt'), -1) <> 0 Then Inc(J);
    Check('350 fichiers supprimes', (J = 0) And (CountDir('\TestNtfs\Grand\*') = 352));
    N := Chkdsk;
    Check('FS_FSCTL 8001h : volume coherent (grand repertoire) (' + ChkText + ')', N = 0);
  End;

  { --- fichiers fragmentes et gros fichier --- }
  R := Open('\TestNtfs\Frag1.bin', $42, $10);
  R := Open2('\TestNtfs\Frag2.bin', $42, $10);
  For I := 0 To 59 Do
  Begin
    For J := 0 To 511 Do Buf[J] := (I + J) And 255;
    Write1(LongInt(@Buf), 512);
    Cnt := 512;
    FS_WRITE(LongInt(@Sfi2), LongInt(@Sfd2), LongInt(@Buf), LongInt(@Cnt), 0);
  End;
  FS_CLOSE(2, 0, LongInt(@Sfi2), LongInt(@Sfd2));
  Seek1(0);
  N := 0;
  For I := 0 To 59 Do
  Begin
    Read1(LongInt(@Buf2), 512);
    For J := 0 To 511 Do If Buf2[J] <> ((I + J) And 255) Then Inc(N);
  End;
  Close1;
  Check('2 fichiers de 60 secteurs entrelaces (plusieurs runs), relus', (N = 0) And (SizeOf1('\TestNtfs\Frag2.bin') = 30720));
  R := Open('\TestNtfs\Gros fichier.bin', $42, $10);
  For I := 0 To 65535 Do Big[I] := (I * 13 + 5) And 255;
  N := 0;
  For J := 0 To 4 Do
    If Write1(LongInt(@Big), 65536) = 0 Then N := N + Cnt;
  Close1;
  R := Open('\TestNtfs\Gros fichier.bin', $40, $01);
  J := 0;
  For I := 0 To 4 Do
  Begin
    FillChar(Big, 65536, 0);
    Read1(LongInt(@Big), 65536);
    If Cnt <> 65536 Then Inc(J);
    For A := 0 To 65535 Do If Big[A] <> ((A * 13 + 5) And 255) Then Inc(J);
  End;
  Close1;
  Check('gros fichier de 320 Ko ecrit et relu', (N = 327680) And (J = 0) And
        (SizeOf1('\TestNtfs\Gros fichier.bin') = 327680));
  N := Chkdsk;
  Check('FS_FSCTL 8001h : volume coherent (runs) (' + ChkText + ')', N = 0);

  { --- surveillance des changements --- }
  N := 0;
  R := FS_FINDNOTIFYFIRST(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\*.txt'), -1, $37, LongInt(@Hnd),
                          LongInt(@Buf), 8192, LongInt(@N), 1, 0);
  Check('FS_FINDNOTIFYFIRST', R = 0);
  Open('\TestNtfs\Nouveau.txt', $42, $10);
  Close1;
  N := 10;
  R := FS_FINDNOTIFYNEXT(Hnd, LongInt(@Buf), 8192, LongInt(@N), 1, 0);
  Check('FS_FINDNOTIFYNEXT (Nouveau.txt cree)', (R = 0) And (N = 1) And (GetZ(LongInt(@Buf) + 29) = 'Nouveau.txt'));
  N := 10;
  R := FS_FINDNOTIFYNEXT(Hnd, LongInt(@Buf), 8192, LongInt(@N), 1, 0);
  Check('FS_FINDNOTIFYNEXT sans changement : ERROR_TIMEOUT', R = ERROR_TIMEOUT);
  R := FS_FINDNOTIFYCLOSE(Hnd);
  Check('FS_FINDNOTIFYCLOSE', R = 0);

  { --- fichier d'echange --- }
  FillChar(Sfi, 64, 0); FillChar(Sfd, 32, 0);
  WrL(LongInt(@Sfi) + 4, HV);
  R := FS_OPENPAGEFILE(LongInt(@N), LongInt(@Cnt), P1('\TestNtfs\SWAPPER.DAT'), LongInt(@Sfi), LongInt(@Sfd),
                       $42, $12, 0, 0);
  Check('FS_OPENPAGEFILE', (R = 0) And (Cnt > 0));
  R := FS_SETSWAP(LongInt(@Sfi), LongInt(@Sfd));
  Check('FS_SETSWAP', R = 0);
  R := FS_ALLOCATEPAGESPACE(LongInt(@Sfi), LongInt(@Sfd), 65536, 4096);
  Check('FS_ALLOCATEPAGESPACE 64 Ko', (R = 0) And (RdL(LongInt(@Sfi) + 20) = 65536));
  For I := 0 To 4095 Do Buf[I] := (I Xor 85) And 255;
  A := LongInt(@Info);
  FillChar(Info, 64, 0);
  WrL(A, 2);
  WrL(A + 12, 2); WrL(A + 20, LongInt(@Buf)); WrL(A + 24, 8192);
  WrL(A + 28, 1); WrL(A + 36, LongInt(@Buf2)); WrL(A + 40, 8192);
  FillChar(Buf2, 4096, 0);
  R := FS_DOPAGEIO(LongInt(@Sfi), LongInt(@Sfd), A);
  J := 0;
  For I := 0 To 4095 Do If Buf2[I] <> Buf[I] Then Inc(J);
  Check('FS_DOPAGEIO (ecrire puis relire une page)', (R = 0) And (J = 0) And (RdL(A + 16) = 0));
  Close1;

  { --- controles divers --- }
  WrL(LongInt(@Info), ERROR_NOT_DOS_DISK);
  R := FS_FSCTL(0, 3, 1, LongInt(@Info), 4, 0, LongInt(@Buf), 200, LongInt(@N));
  Check('FS_FSCTL 1 (texte d''erreur)', (R = 0) And (Length(GetZ(LongInt(@Buf))) > 10));
  R := FS_FSCTL(0, 3, 2, 0, 0, 0, LongInt(@Buf), 6, LongInt(@N));
  Check('FS_FSCTL 2 (pas d''EA : taille maximale 0)', (R = 0) And (RdL(LongInt(@Buf) + 2) = 0));
  Stat[0] := HV;
  R := FS_FSCTL(0, 3, $8002, LongInt(@Stat), 4, 0, LongInt(@Stat[4]), 32, LongInt(@N));
  Check('FS_FSCTL 8002h (statistiques : ' + IStr(Stat[4]) + ' lectures en antememoire, ' +
        IStr(Stat[8]) + ' enregistrements dans la MFT)', (R = 0) And (Stat[7] > 0) And (Stat[8] >= 64));
  R := FS_FSCTL(0, 3, $7777, 0, 0, 0, 0, 0, 0);
  Check('FS_FSCTL fonction inconnue refusee', R = 1);
  PutZ(LongInt(@Name), 'D:\Rep. \Nom..');
  R := FS_PROCESSNAME(LongInt(@Name));
  Check('FS_PROCESSNAME (D:\Rep. \Nom.. -> D:\Rep\Nom)', (R = 0) And (GetZ(LongInt(@Name)) = 'D:\Rep\Nom'));
  Check('FS_NMPIPE : pas de tuyaux nommes sur NTFS', FS_NMPIPE(0, 0, 0, 0, 0, 0) = ERROR_NOT_SUPPORTED);
  Check('FS_ATTACH : NTFS est local', FS_ATTACH(0, 0, 0, 0, 0, 0) = ERROR_NOT_SUPPORTED);
  FillChar(Buf, 512, 0);
  FillChar(Info, 512, 0);
  WrL(LongInt(@Info) + 12, 100);
  R := FS_MOUNT(0, LongInt(@Info), LongInt(@Info) + 100, 20, LongInt(@Buf));
  Check('FS_MOUNT d''un volume non NTFS refuse', R = ERROR_NOT_DOS_DISK);
  PutZ(LongInt(@Buf) + 3, 'HPFS    ');
  R := FS_MOUNT(0, LongInt(@Info), LongInt(@Info) + 100, 20, LongInt(@Buf));
  Check('FS_MOUNT d''un volume HPFS (type 07h) refuse', R = ERROR_NOT_DOS_DISK);
  Check('FS_EXIT', FS_EXIT(0, 12345, 0) = 0);
  Check('FS_FLUSHBUF', FS_FLUSHBUF(HV, 0) = 0);
  Check('FS_SHUTDOWN (debut : tout ecrire)', FS_SHUTDOWN(0, 0) = 0);

  { --- par DOSCALLS.DLL (le noyau aiguille l'unite vers NTFS.IFS) --- }
  R := DosOpen(P1('\TestNtfs\Par DOSCALLS.txt'), LongInt(@H), LongInt(@Act), 0, 0, $12, $42, 0);
  If R = 0 Then
  Begin
    PutZ(LongInt(@Buf), 'Bonjour NTFS');
    R := DosWrite(H, LongInt(@Buf), 12, LongInt(@N));
    DosClose(H);
  End;
  Check('DosOpen/DosWrite sur ' + Drive + ': (nom long)', (R = 0) And (SizeOf1('\TestNtfs\Par DOSCALLS.txt') = 12));
  R := DosQueryFSInfo(HV + 1, 1, LongInt(@Info), 18);
  Check('DosQueryFSInfo ' + Drive + ':', (R = 0) And (RdW(LongInt(@Info) + 16) = 512));

  { --- nettoyage --- }
  R := FS_RMDIR(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs'), -1);
  Check('FS_RMDIR d''un repertoire non vide refuse', R = ERROR_DIR_NOT_EMPTY);
  If Keep Then
  Begin
    N := Chkdsk;
    Check('FS_FSCTL 8001h : volume coherent (fichiers gardes) (' + ChkText + ')', N = 0);
    FS_FLUSHBUF(HV, 0);
    WriteLn;
    WriteLn('TESTNTFS : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
    Halt(0);
  End;
  For I := 2 To 150 Do
    If Not Odd(I) Then
      FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Fichier numero ' + IStr(1000 + I) +
                ' du grand repertoire.dat'), -1);
  FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Fichier avec un nom long.texte'), -1);
  FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Sous r'#130'pertoire\Deplace.txt'), -1);
  FS_RMDIR(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Sous r'#130'pertoire'), -1);
  FS_RMDIR(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\AvecEA'), -1);
  FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Frag1.bin'), -1);
  FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Frag2.bin'), -1);
  FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Gros fichier.bin'), -1);
  FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\Nouveau.txt'), -1);
  FS_DELETE(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs\SWAPPER.DAT'), -1);
  DosDelete(P1('\TestNtfs\Par DOSCALLS.txt'));
  R := FS_RMDIR(LongInt(@Cd), LongInt(@Cdd), P1('\TestNtfs'), -1);
  Check('FS_RMDIR \TestNtfs (vide)', R = 0);
  N := Chkdsk;
  Check('FS_FSCTL 8001h : volume coherent a la fin (' + ChkText + ')', N = 0);
  FS_FLUSHBUF(HV, 0);

  WriteLn;
  WriteLn('TESTNTFS : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
