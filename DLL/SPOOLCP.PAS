{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 SPOOLCP.DLL de OS/2-0 (changement de
                page de codes et de police des imprimantes).
}

Library SPOOLCP;

{$IMAGEBASE $00EA0000}
{$R-,S-,I-}

{ Compilation : OS2PC SPOOLCP.PAS   (produit SPOOLCP.DLL)

  SPOOLCP.DLL est le commutateur de polices des imprimantes (Printer Font
  Switcher, PFS) d'OS/2 : pour chaque imprimante (PRN, LPT1 a LPT3), il
  connait les polices residentes et celles du fichier de polices, et pour
  chaque fichier ouvert vers l'imprimante (numero de fichier systeme,
  SFN : handle du port ou du fichier de spoule) la page de codes et la
  police actives. Activer une police ecrit sur ce handle la sequence de
  commande qui la choisit, precedee, la premiere fois, des donnees a
  charger dans l'imprimante (police telechargeable).

  Fichier de polices (texte, format d'OS/2-0) : une definition par ligne,
  octets en hexadecimal ; ';' commence un commentaire.
    TYPE nom                  type d'imprimante (ex. 4201), facultatif ;
                              s'il est present, il doit etre celui de
                              DosPFSInit
    FONT cp police oct...     sequence de commande qui choisit la police
    LOAD cp police oct...     donnees a telecharger avant le premier choix
  (police 0 de la page de codes 0 : etat par defaut de l'imprimante). Une
  police residente (HWFONTS) sans ligne FONT est disponible sans
  sequence.

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires ; un pointeur vers une valeur simple (pcbWritten,
  pusCodePage, pusFontID) designe un LongInt.
    HWFONTS   cFonts (mot), puis cFonts fois idCodePage, idFont (mots)
  Exemple :
    Function DosPFSActivate(Sfn, PcbWritten, PszPrinter, CodePage, FontId,
                            Reserved : LongInt) : LongInt; External 'SPOOLCP';

  Fonctions exportees (ordinaux d'origine de SPOOLCP.DLL) :
    1 DosPFSCloseUser    3 DosPFSInit        5 DosPFSVerifyFont
    2 DosPFSQueryAct     4 DosPFSActivate

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services de DOSCALLS.DLL
    Partie 3 - Utilitaires
    Partie 4 - Imprimantes, polices et utilisateurs
    Partie 5 - Fichier de polices
    Partie 6 - Fonctions DosPFS*
    Exportations }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  NO_ERROR                      = 0;
  ERROR_INVALID_HANDLE          = 6;
  ERROR_INVALID_PARAMETER       = 87;
  { codes du commutateur de polices (bseerr.h) }
  ERROR_CPSIO_CODE_PAGE_INVALID = 65026;
  ERROR_CPSIO_NO_SPOOLER        = 65027;
  ERROR_CPSIO_FONT_ID_INVALID   = 65028;
  ERROR_CPSIO_INTERNAL_ERROR    = 65033;
  ERROR_CPSIO_INVALID_PTR_NAME  = 65034;
  ERROR_CPSIO_NOT_ACTIVE        = 65037;
  ERROR_CPSIO_PID_FULL          = 65039;
  ERROR_CPSIO_PID_NOT_FOUND     = 65040;
  ERROR_CPSIO_READ_CTL_SEQ      = 65043;
  ERROR_CPSIO_READ_FNT_DEF      = 65045;
  ERROR_CPSIO_WRITE_ERROR       = 65047;
  ERROR_CPSIO_WRITE_FULL_ERROR  = 65048;
  ERROR_CPSIO_WRITE_HANDLE_BAD  = 65049;
  ERROR_CPSIO_SWIT_LOAD         = 65074;
  ERROR_CPSIO_INV_COMMAND       = 65077;
  ERROR_CPSIO_NO_FONT_SWIT      = 65078;

  NPrn    = 3;               { LPT1 (PRN), LPT2, LPT3 }
  MaxHw   = 16;              { polices residentes par imprimante }
  MaxDef  = 64;              { definitions du fichier de polices }
  MaxSel  = 64;              { octets d'une sequence de choix }
  MaxLoad = 512;             { octets d'une police a telecharger }
  MaxUser = 32;              { couples (processus, SFN) }
  FileMax = 16384;           { taille maximale du fichier de polices }

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  { imprimantes }
  PInit   : Array[0..NPrn - 1] Of Boolean;
  PTypeNm : Array[0..NPrn - 1] Of String[15];
  PHwN    : Array[0..NPrn - 1] Of LongInt;
  PHwCp, PHwFont : Array[0..NPrn * MaxHw - 1] Of LongInt;

  { definitions du fichier de polices }
  DUsed   : Array[0..MaxDef - 1] Of Boolean;
  DPrn, DCp, DFont, DSelLen, DLoadLen : Array[0..MaxDef - 1] Of LongInt;
  DLoaded : Array[0..MaxDef - 1] Of Boolean;    { police telechargee }
  DSel    : Array[0..MaxDef * MaxSel - 1] Of Byte;
  DLoad   : Array[0..MaxDef * MaxLoad - 1] Of Byte;

  { utilisateurs : page de codes et police actives par (processus, SFN) }
  UUsed   : Array[0..MaxUser - 1] Of Boolean;
  UPid, USfn, UPrn, UCp, UFont : Array[0..MaxUser - 1] Of LongInt;

  FileBuf : Array[0..FileMax - 1] Of Byte;
  OutBuf  : Array[0..MaxLoad + MaxSel] Of Byte;
  NameZ   : Array[0..259] Of Byte;
  Dummy   : LongInt;
  LinePos, LineEnd, FileLen : LongInt;   { lecture du fichier de polices }

{ ==================================================================== }
{ Partie 2 - Services de DOSCALLS.DLL                                  }
{ ==================================================================== }

Function DcOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS' Name 'DosOpen';
Function DcRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRead';
Function DcWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWrite';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';

{ ==================================================================== }
{ Partie 3 - Utilitaires                                               }
{ ==================================================================== }

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
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
  P^ := V And $FF;
End;

Function GetZ(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (RdB(A + N) <> 0) And (N < 255) Do
    Begin
      S := S + UpCase(Chr(RdB(A + N)));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

{ Imprimante designee par pszPrinterName (-1 : nom invalide) }
Function PrnIdx(A : LongInt) : LongInt;
Var S : String;
Begin
  S := GetZ(A);
  If (Length(S) > 1) And (S[Length(S)] = ':') Then S := Copy(S, 1, Length(S) - 1);
  If (S = 'PRN') Or (S = 'LPT1') Then PrnIdx := 0
  Else If S = 'LPT2' Then PrnIdx := 1
  Else If S = 'LPT3' Then PrnIdx := 2
  Else PrnIdx := -1;
End;

{ ==================================================================== }
{ Partie 4 - Imprimantes, polices et utilisateurs                      }
{ ==================================================================== }

{ Utilisateurs des processus termines retires }
Procedure Purge;
Var I : LongInt;
Begin
  For I := 0 To MaxUser - 1 Do
    If UUsed[I] Then
      If KrnMonIo(0, 4, UPid[I]) = 0 Then UUsed[I] := False;
End;

Function FindDef(P, Cp, Font : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxDef - 1 Do
    If DUsed[I] And (DPrn[I] = P) And (DCp[I] = Cp) And (DFont[I] = Font) Then R := I;
  FindDef := R;
End;

Function IsHw(P, Cp, Font : LongInt) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := False;
  For I := 0 To PHwN[P] - 1 Do
    If (PHwCp[P * MaxHw + I] = Cp) And (PHwFont[P * MaxHw + I] = Font) Then R := True;
  IsHw := R;
End;

{ La page de codes et la police sont-elles disponibles ? Rend NO_ERROR,
  ERROR_CPSIO_CODE_PAGE_INVALID ou ERROR_CPSIO_FONT_ID_INVALID }
Function Avail(P, Cp, Font : LongInt) : LongInt;
Var I : LongInt; CpOk : Boolean;
Begin
  If (FindDef(P, Cp, Font) >= 0) Or IsHw(P, Cp, Font) Then
  Begin
    Avail := NO_ERROR;
    Exit;
  End;
  CpOk := False;
  For I := 0 To PHwN[P] - 1 Do
    If PHwCp[P * MaxHw + I] = Cp Then CpOk := True;
  For I := 0 To MaxDef - 1 Do
    If DUsed[I] And (DPrn[I] = P) And (DCp[I] = Cp) Then CpOk := True;
  If CpOk Then Avail := ERROR_CPSIO_FONT_ID_INVALID
  Else Avail := ERROR_CPSIO_CODE_PAGE_INVALID;
End;

Function FindUser(Sfn, P : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxUser - 1 Do
    If UUsed[I] And (UPid[I] = MyPid) And (USfn[I] = Sfn) And (UPrn[I] = P) Then R := I;
  FindUser := R;
End;

{ Retirer l'imprimante P (definitions et utilisateurs) }
Procedure ClearPrinter(P : LongInt);
Var I : LongInt;
Begin
  For I := 0 To MaxDef - 1 Do
    If DUsed[I] And (DPrn[I] = P) Then DUsed[I] := False;
  For I := 0 To MaxUser - 1 Do
    If UUsed[I] And (UPrn[I] = P) Then UUsed[I] := False;
  PInit[P] := False;
  PHwN[P] := 0;
End;

{ ==================================================================== }
{ Partie 5 - Fichier de polices                                        }
{ ==================================================================== }

Function HexVal(C : LongInt) : LongInt;
Begin
  If (C >= Ord('0')) And (C <= Ord('9')) Then HexVal := C - Ord('0')
  Else If (C >= Ord('A')) And (C <= Ord('F')) Then HexVal := C - Ord('A') + 10
  Else If (C >= Ord('a')) And (C <= Ord('f')) Then HexVal := C - Ord('a') + 10
  Else HexVal := -1;
End;

{ Mot suivant de la ligne courante ('' a la fin) }
Function NextWord : String;
Var S : String; C : LongInt; Fin : Boolean;
Begin
  S := '';
  While (LinePos < LineEnd) And ((FileBuf[LinePos] = 32) Or (FileBuf[LinePos] = 9)) Do Inc(LinePos);
  Fin := False;
  While (LinePos < LineEnd) And Not Fin Do
  Begin
    C := FileBuf[LinePos];
    If (C = 32) Or (C = 9) Then Fin := True
    Else
    Begin
      If Length(S) < 60 Then S := S + UpCase(Chr(C));
      Inc(LinePos);
    End;
  End;
  NextWord := S;
End;

Function DecVal(S : String; Var V : LongInt) : Boolean;
Var K : LongInt; Ok : Boolean;
Begin
  V := 0;
  Ok := S <> '';
  For K := 1 To Length(S) Do
    If (S[K] >= '0') And (S[K] <= '9') Then V := V * 10 + Ord(S[K]) - 48
    Else Ok := False;
  DecVal := Ok And (V <= 65535);
End;

{ Lire le fichier de polices Name pour l'imprimante P (type Typ) }
Function LoadFontFile(P : LongInt; Name, Typ : String) : LongInt;
Var H, Act, Got, R, K, Cp, Font, D, N, Hi, Lo, Base : LongInt; W, T : String; IsLoad : Boolean;
Begin
  PutZ(LongInt(@NameZ), Name);
  If DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) <> NO_ERROR Then
  Begin
    LoadFontFile := ERROR_CPSIO_READ_FNT_DEF;
    Exit;
  End;
  Got := 0;
  R := DcRead(H, LongInt(@FileBuf), FileMax, LongInt(@Got));
  D := DcClose(H);
  If R <> NO_ERROR Then
  Begin
    LoadFontFile := ERROR_CPSIO_READ_FNT_DEF;
    Exit;
  End;
  FileLen := Got;
  LinePos := 0;
  R := NO_ERROR;
  While (LinePos < FileLen) And (R = NO_ERROR) Do
  Begin
    LineEnd := LinePos;
    While (LineEnd < FileLen) And (FileBuf[LineEnd] <> 13) And (FileBuf[LineEnd] <> 10) And
          (FileBuf[LineEnd] <> Ord(';')) Do Inc(LineEnd);
    W := NextWord;
    If W = 'TYPE' Then
    Begin
      T := NextWord;
      If (Typ <> '') And (T <> Typ) Then R := ERROR_CPSIO_READ_FNT_DEF;
    End
    Else If (W = 'FONT') Or (W = 'LOAD') Then
    Begin
      IsLoad := W = 'LOAD';
      If Not DecVal(NextWord, Cp) Then R := ERROR_CPSIO_READ_CTL_SEQ
      Else If Not DecVal(NextWord, Font) Then R := ERROR_CPSIO_READ_CTL_SEQ
      Else
      Begin
        D := FindDef(P, Cp, Font);
        If D < 0 Then
        Begin
          For K := MaxDef - 1 DownTo 0 Do
            If Not DUsed[K] Then D := K;
          If D < 0 Then R := ERROR_CPSIO_SWIT_LOAD
          Else
          Begin
            DUsed[D] := True;
            DPrn[D] := P; DCp[D] := Cp; DFont[D] := Font;
            DSelLen[D] := 0; DLoadLen[D] := 0;
            DLoaded[D] := False;
          End;
        End;
        { octets en hexadecimal }
        N := 0;
        If IsLoad Then Base := D * MaxLoad Else Base := D * MaxSel;
        W := NextWord;
        While (W <> '') And (R = NO_ERROR) Do
        Begin
          If Length(W) <> 2 Then R := ERROR_CPSIO_READ_CTL_SEQ
          Else
          Begin
            Hi := HexVal(Ord(W[1]));
            Lo := HexVal(Ord(W[2]));
            If (Hi < 0) Or (Lo < 0) Then R := ERROR_CPSIO_READ_CTL_SEQ
            Else If (IsLoad And (N >= MaxLoad)) Or ((Not IsLoad) And (N >= MaxSel)) Then
              R := ERROR_CPSIO_READ_CTL_SEQ
            Else
            Begin
              If IsLoad Then DLoad[Base + N] := Hi * 16 + Lo Else DSel[Base + N] := Hi * 16 + Lo;
              Inc(N);
            End;
          End;
          W := NextWord;
        End;
        If R = NO_ERROR Then
        Begin
          If IsLoad Then DLoadLen[D] := N Else DSelLen[D] := N;
        End;
      End;
    End
    Else If W <> '' Then R := ERROR_CPSIO_READ_CTL_SEQ;
    { ligne suivante }
    LinePos := LineEnd;
    While (LinePos < FileLen) And (FileBuf[LinePos] <> 10) Do Inc(LinePos);
    If LinePos < FileLen Then Inc(LinePos);
  End;
  LoadFontFile := R;
End;

{ ==================================================================== }
{ Partie 6 - Fonctions DosPFS*                                         }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  DosPFSInit(pHWFonts, pszFontFile, pszPrinterType, pszPrinterName,
  ulReserved) : installer le commutateur de polices de l'imprimante :
  polices residentes (HWFONTS, 0 : aucune) et fichier de polices (0 :
  aucun) ; une nouvelle initialisation remplace la precedente (polices a
  telecharger de nouveau, polices actives oubliees) }
Function DosPFSInit(PHw, PFile, PType, PName, Reserved : LongInt) : LongInt;
Var P, N, I, R : LongInt; F, T : String;
Begin
  Purge;
  P := PrnIdx(PName);
  If P < 0 Then
  Begin
    DosPFSInit := ERROR_CPSIO_INVALID_PTR_NAME;
    Exit;
  End;
  If Reserved <> 0 Then
  Begin
    DosPFSInit := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  N := 0;
  If PHw <> 0 Then N := RdW(PHw);
  If N > MaxHw Then
  Begin
    DosPFSInit := ERROR_CPSIO_SWIT_LOAD;
    Exit;
  End;
  ClearPrinter(P);
  T := GetZ(PType);
  PTypeNm[P] := Copy(T, 1, 15);
  For I := 0 To N - 1 Do
  Begin
    PHwCp[P * MaxHw + I] := RdW(PHw + 2 + I * 4);
    PHwFont[P * MaxHw + I] := RdW(PHw + 4 + I * 4);
  End;
  PHwN[P] := N;
  R := NO_ERROR;
  F := GetZ(PFile);
  If F <> '' Then R := LoadFontFile(P, F, T);
  If R = NO_ERROR Then PInit[P] := True Else ClearPrinter(P);
  DosPFSInit := R;
End;

{ ---------------------------------------------------------------------
  DosPFSVerifyFont(pszPrinterName, usCodePage, usFontID, ulReserved) :
  la page de codes et la police sont-elles disponibles (residentes ou
  dans le fichier de polices) ? }
Function DosPFSVerifyFont(PName, Cp, Font, Reserved : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := PrnIdx(PName);
  If P < 0 Then DosPFSVerifyFont := ERROR_CPSIO_INVALID_PTR_NAME
  Else If Not PInit[P] Then DosPFSVerifyFont := ERROR_CPSIO_NO_FONT_SWIT
  Else If Reserved <> 0 Then DosPFSVerifyFont := ERROR_INVALID_PARAMETER
  Else DosPFSVerifyFont := Avail(P, Cp, Font);
End;

{ ---------------------------------------------------------------------
  DosPFSActivate(hSFN, pcbWritten, pszPrinterName, usCodePage, usFontID,
  ulReserved) : activer la page de codes et la police pour le fichier
  hSFN (handle du port ou du fichier de spoule) : la police est
  telechargee la premiere fois (LOAD), puis choisie (FONT) ; *pcbWritten
  <- octets ecrits sur hSFN }
Function DosPFSActivate(Sfn, PcbWritten, PName, Cp, Font, Reserved : LongInt) : LongInt;
Var P, R, D, U, I, N, W : LongInt;
Begin
  Purge;
  WrL(PcbWritten, 0);
  P := PrnIdx(PName);
  If P < 0 Then R := ERROR_CPSIO_INVALID_PTR_NAME
  Else If Not PInit[P] Then R := ERROR_CPSIO_NO_FONT_SWIT
  Else If Reserved <> 0 Then R := ERROR_INVALID_PARAMETER
  Else R := Avail(P, Cp, Font);
  If R <> NO_ERROR Then
  Begin
    DosPFSActivate := R;
    Exit;
  End;
  U := FindUser(Sfn, P);
  If U < 0 Then
  Begin
    For I := MaxUser - 1 DownTo 0 Do
      If Not UUsed[I] Then U := I;
    If U < 0 Then
    Begin
      DosPFSActivate := ERROR_CPSIO_PID_FULL;
      Exit;
    End;
  End;
  { donnees a ecrire : telechargement eventuel, puis sequence de choix }
  N := 0;
  D := FindDef(P, Cp, Font);
  If D >= 0 Then
  Begin
    If (DLoadLen[D] > 0) And Not DLoaded[D] Then
      For I := 0 To DLoadLen[D] - 1 Do
      Begin
        OutBuf[N] := DLoad[D * MaxLoad + I];
        Inc(N);
      End;
    For I := 0 To DSelLen[D] - 1 Do
    Begin
      OutBuf[N] := DSel[D * MaxSel + I];
      Inc(N);
    End;
  End;
  W := 0;
  If N > 0 Then
  Begin
    R := DcWrite(Sfn, LongInt(@OutBuf), N, LongInt(@W));
    If R = ERROR_INVALID_HANDLE Then R := ERROR_CPSIO_WRITE_HANDLE_BAD
    Else If R <> NO_ERROR Then R := ERROR_CPSIO_WRITE_ERROR
    Else If W <> N Then R := ERROR_CPSIO_WRITE_FULL_ERROR;
  End;
  WrL(PcbWritten, W);
  If R = NO_ERROR Then
  Begin
    If D >= 0 Then
      If DLoadLen[D] > 0 Then DLoaded[D] := True;
    UUsed[U] := True;
    UPid[U] := MyPid;
    USfn[U] := Sfn;
    UPrn[U] := P;
    UCp[U] := Cp;
    UFont[U] := Font;
  End;
  DosPFSActivate := R;
End;

{ ---------------------------------------------------------------------
  DosPFSQueryAct(pszPrinterName, pusCodePage, pusFontID, hSFN,
  ulReserved) : page de codes et police actives pour le fichier hSFN }
Function DosPFSQueryAct(PName, PCp, PFont, Sfn, Reserved : LongInt) : LongInt;
Var P, U : LongInt;
Begin
  Purge;
  P := PrnIdx(PName);
  If P < 0 Then DosPFSQueryAct := ERROR_CPSIO_INVALID_PTR_NAME
  Else If Not PInit[P] Then DosPFSQueryAct := ERROR_CPSIO_NO_FONT_SWIT
  Else If (Reserved <> 0) Or (PCp = 0) Or (PFont = 0) Then DosPFSQueryAct := ERROR_INVALID_PARAMETER
  Else
  Begin
    U := FindUser(Sfn, P);
    If U < 0 Then DosPFSQueryAct := ERROR_CPSIO_NOT_ACTIVE
    Else
    Begin
      WrL(PCp, UCp[U]);
      WrL(PFont, UFont[U]);
      DosPFSQueryAct := NO_ERROR;
    End;
  End;
End;

{ ---------------------------------------------------------------------
  DosPFSCloseUser(hSFN, pszPrinterName, ulReserved) : le fichier hSFN
  est ferme : sa page de codes et sa police actives sont oubliees }
Function DosPFSCloseUser(Sfn, PName, Reserved : LongInt) : LongInt;
Var P, U : LongInt;
Begin
  Purge;
  P := PrnIdx(PName);
  If P < 0 Then DosPFSCloseUser := ERROR_CPSIO_INVALID_PTR_NAME
  Else If Not PInit[P] Then DosPFSCloseUser := ERROR_CPSIO_NO_FONT_SWIT
  Else If Reserved <> 0 Then DosPFSCloseUser := ERROR_INVALID_PARAMETER
  Else
  Begin
    U := FindUser(Sfn, P);
    If U < 0 Then DosPFSCloseUser := ERROR_CPSIO_PID_NOT_FOUND
    Else
    Begin
      UUsed[U] := False;
      DosPFSCloseUser := NO_ERROR;
    End;
  End;
End;

{ ==================================================================== }
{ Exportations                                                         }
{ ==================================================================== }

exports
  DosPFSCloseUser Index 1, DosPFSQueryAct Index 2, DosPFSInit Index 3,
  DosPFSActivate Index 4, DosPFSVerifyFont Index 5;

Var
  InitI : LongInt;

BEGIN
  For InitI := 0 To NPrn - 1 Do
  Begin
    PInit[InitI] := False;
    PHwN[InitI] := 0;
  End;
  For InitI := 0 To MaxDef - 1 Do DUsed[InitI] := False;
  For InitI := 0 To MaxUser - 1 Do UUsed[InitI] := False;
END.
