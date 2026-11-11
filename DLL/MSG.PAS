{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 MSG.DLL de OS/2-0 (messages : fichiers
                de messages MKMSGF, insertion de variables, affichage).
}

Library MSG;

{$IMAGEBASE $00D80000}
{$R-,S-,I-}

{ Compilation : OS2PC MSG.PAS   (produit MSG.DLL)

  MSG.DLL lit les messages des fichiers de messages d'OS/2 (.MSG, produits
  par MKMSGF), y insere les variables %1 a %9 et les ecrit a l'ecran ou
  dans un fichier. Les fonctions DosGetMessage, DosInsertMessage,
  DosPutMessage et DosQueryMessageCP de DOSCALLS.DLL lui sont transmises.

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires. Les points d'entree d'OS/2 2.x (ordinaux 4, 5, 6, 8 et 9)
  rendent les longueurs dans un ULONG (LongInt) ; ceux d'OS/2 1.x
  (ordinaux 1, 2, 3 et 7 : Dos16*) dans un USHORT. Exemple :
    Function DosTrueGetMessage(PTable, CTable, PBuf, CbBuf, MsgNum, PFile,
                               PcbMsg, PMsgSeg : LongInt) : LongInt; External 'MSG';

  Fichier de messages (format MKMSGF) :
    +00h  signature FFh 'MKMSGF' 00h (8 octets)
    +08h  composant (3 caracteres, ex. SYS)
    +0Bh  nombre de messages (mot)       +0Dh  premier numero (mot)
    +0Fh  1 : index de mots, 0 : index de doubles mots
    +10h  version (mot, 2)                +12h  position de l'index (mot)
    +14h  position du bloc du pays (mot)  +16h  bloc etendu (double mot)
    index : position de chaque message ; un message = type (E erreur,
    W avertissement, I information, H aide, P invite, ? inutilise) suivi
    du texte (jusqu'au message suivant ou a la fin du fichier).
    Bloc du pays : octets par caractere (1), reserve (2), famille de
    langue (mot), version de langue (mot), nombre de pages de codes (mot),
    16 pages de codes (mots), nom du fichier (13 octets).
  DosTrueGetMessage prefixe les messages E et W de "SYS0002: " (composant
  et numero) ; un texte termine par %0 n'a pas de retour a la ligne.
  Si le message est introuvable, le tampon recoit le message d'erreur
  (SYS0317, SYS0318 ou SYS0319) et la fonction rend l'erreur.

  Recherche du fichier : chemin indique, sinon repertoire courant, puis
  repertoires de DPATH, puis C:\ et C:\OS2\SYSTEM. Le fichier ouvert reste
  en antememoire (par processus) jusqu'a DosCloseMessageFile. Le fichier
  des messages systeme OSO001.MSG absent, ses principaux messages sont
  integres a la DLL.

  Segment de messages (pMsgSeg) : adresse d'une image en memoire d'un
  fichier de messages (comme un segment lie par MSGBIND), consultee avant
  le disque si son nom de fichier (bloc du pays) est celui demande ou
  vide ; 0 : aucun. Dans une image, le dernier message se termine par un
  octet nul (ou le double mot +16h donne la taille de l'image).

  Fonctions exportees (ordinaux d'origine de MSG.DLL) :
    1 Dos16PutMessage         6 DosTrueGetMessage (Dos32TrueGetMessage)
    2 Dos16TrueGetMessage     7 Dos16IQueryMessageCP
    3 DosInsMessage           8 DosIQueryMessageCP (Dos32IQueryMessageCP)
    4 DosInsertMessage        9 DosCloseMessageFile
      (Dos32InsertMessage)      (Dos32CloseMessageFile)
    5 DosPutMessage (Dos32PutMessage)

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services de DOSCALLS.DLL
    Partie 3 - Utilitaires
    Partie 4 - Insertion des variables
    Partie 5 - Fichiers de messages
    Partie 6 - Messages integres
    Partie 7 - Fonctions
    Exportations }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  NO_ERROR                 = 0;
  ERROR_INVALID_PARAMETER  = 87;
  ERROR_BUFFER_OVERFLOW    = 111;
  ERROR_MR_MSG_TOO_LONG    = 316;
  ERROR_MR_MID_NOT_FOUND   = 317;
  ERROR_MR_UN_ACC_MSGF     = 318;
  ERROR_MR_INV_MSGF_FORMAT = 319;
  ERROR_MR_INV_IVCOUNT     = 320;
  ERROR_MR_UN_PERFORM      = 321;

  MaxCache = 8;              { fichiers de messages ouverts }
  MsgMax   = 4096;           { taille maximale d'un message }
  ScrCols  = 80;             { largeur de l'ecran (DosPutMessage) }

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  { antememoire des fichiers ouverts }
  CUsed   : Array[0..MaxCache - 1] Of Boolean;
  CPid    : Array[0..MaxCache - 1] Of LongInt;
  CHandle : Array[0..MaxCache - 1] Of LongInt;
  CSize   : Array[0..MaxCache - 1] Of LongInt;
  CName   : Array[0..MaxCache - 1] Of String[127];
  CBase   : Array[0..MaxCache - 1] Of LongInt;   { nom de fichier sans chemin }

  { message lu }
  Hdr     : Array[0..63] Of Byte;     { en-tete et bloc du pays }
  Txt     : Array[0..MsgMax + 15] Of Byte;
  TxtLen  : LongInt;
  MType   : LongInt;                  { E, W, I, H, P }
  Comp    : String[3];
  Work    : Array[0..MsgMax + 255] Of Byte;
  OutB    : Array[0..MsgMax * 2] Of Byte;
  Tab     : Array[0..3] Of LongInt;   { variables des messages d'erreur }
  VarA, VarB : Array[0..127] Of Byte;
  NameZ   : Array[0..259] Of Byte;
  Env     : LongInt;
  Dummy   : LongInt;
  OutLen  : LongInt;                  { longueur rendue par Insert }

{ ==================================================================== }
{ Partie 2 - Services de DOSCALLS.DLL                                  }
{ ==================================================================== }

Function DcOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS' Name 'DosOpen';
Function DcRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRead';
Function DcWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWrite';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';
Function DcSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSetFilePtr';
Function DcQueryHType(H, PType, PAttr : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryHType';
Function DcScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS' Name 'DosScanEnv';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';

{ ==================================================================== }
{ Partie 3 - Utilitaires                                               }
{ ==================================================================== }

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
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
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FFFF;
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
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FF;
End;

Procedure CopyB(Src, Dst, N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do WrB(Dst + I, RdB(Src + I));
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
      S := S + Chr(RdB(A + N));
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

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

Function BaseName(S : String) : String;
Var K, P : LongInt;
Begin
  P := 0;
  For K := 1 To Length(S) Do
    If (S[K] = '\') Or (S[K] = '/') Or (S[K] = ':') Then P := K;
  BaseName := Copy(S, P + 1, 255);
End;

Function Num4(N : LongInt) : String;
Var S : String;
Begin
  Str(N, S);
  While Length(S) < 4 Do S := '0' + S;
  Num4 := S;
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

{ Ecrire une longueur : ULONG (32 bits) ou USHORT (points d'entree 1.x) }
Procedure PutLen(A, V : LongInt; Is16 : Boolean);
Begin
  If Is16 Then WrW(A, V) Else WrL(A, V);
End;

{ ==================================================================== }
{ Partie 4 - Insertion des variables                                   }
{ ==================================================================== }

{ Copier PMsg (CbMsg octets) dans PBuf (CbBuf) en remplacant %1 a %9 par
  les chaines ASCIIZ de la table (CTable adresses) ; un %n sans variable
  reste tel quel. Rend la longueur dans OutLen ; ERROR_MR_MSG_TOO_LONG si
  le resultat est tronque. }
Function InsVars(PTable, CTable, PMsg, CbMsg, PBuf, CbBuf : LongInt) : LongInt;
Var I, O, C, N, K, A, R : LongInt;
Begin
  R := NO_ERROR;
  O := 0;
  I := 0;
  While (I < CbMsg) And (R = NO_ERROR) Do
  Begin
    C := RdB(PMsg + I);
    N := 0;
    If (C = Ord('%')) And (I + 1 < CbMsg) Then
    Begin
      N := RdB(PMsg + I + 1) - Ord('0');
      If (N < 1) Or (N > 9) Or (N > CTable) Then N := 0;
    End;
    If N > 0 Then
    Begin
      A := RdL(PTable + (N - 1) * 4);
      K := 0;
      While (A <> 0) And (RdB(A + K) <> 0) And (R = NO_ERROR) Do
      Begin
        If O >= CbBuf Then R := ERROR_MR_MSG_TOO_LONG
        Else
        Begin
          WrB(PBuf + O, RdB(A + K));
          Inc(O);
          Inc(K);
        End;
      End;
      I := I + 2;
    End
    Else
    Begin
      If O >= CbBuf Then R := ERROR_MR_MSG_TOO_LONG
      Else
      Begin
        WrB(PBuf + O, C);
        Inc(O);
        Inc(I);
      End;
    End;
  End;
  OutLen := O;
  InsVars := R;
End;

{ ==================================================================== }
{ Partie 5 - Fichiers de messages                                      }
{ ==================================================================== }

Function ValidHdr(A : LongInt) : Boolean;
Begin
  ValidHdr := (RdB(A) = $FF) And (RdB(A + 1) = Ord('M')) And (RdB(A + 2) = Ord('K')) And
              (RdB(A + 3) = Ord('M')) And (RdB(A + 4) = Ord('S')) And (RdB(A + 5) = Ord('G')) And
              (RdB(A + 6) = Ord('F'));
End;

{ Ecarter les fichiers des processus termines }
Procedure PurgeCache;
Var I : LongInt;
Begin
  For I := 0 To MaxCache - 1 Do
    If CUsed[I] Then
      If KrnMonIo(0, 4, CPid[I]) = 0 Then CUsed[I] := False;
End;

Function TryOpen(Path : String; Var H : LongInt) : Boolean;
Var Act : LongInt;
Begin
  PutZ(LongInt(@NameZ), Path);
  H := 0;
  TryOpen := DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), 0, 0, 1, $20, 0) = NO_ERROR;
End;

{ Ouvrir le fichier de messages Name (recherche, antememoire) ; rend
  l'entree de l'antememoire, ou -1 (introuvable) }
Function OpenMsgFile(Name : String) : LongInt;
Var I, F, H, P, Sz, D : LongInt; Found : Boolean; Path, U, Dirs, Dir : String;
Begin
  PurgeCache;
  U := UpStr(Name);
  F := -1;
  For I := 0 To MaxCache - 1 Do
    If CUsed[I] And (CPid[I] = MyPid) Then
      If (CName[I] = U) Or ((Pos('\', U) = 0) And (Pos(':', U) = 0) And (UpStr(BaseName(CName[I])) = U)) Then
        F := I;
  If F >= 0 Then
  Begin
    OpenMsgFile := F;
    Exit;
  End;
  Found := False;
  Path := U;
  If (Pos('\', U) > 0) Or (Pos(':', U) > 0) Then
    Found := TryOpen(U, H)
  Else
  Begin
    Found := TryOpen(U, H);                       { repertoire courant }
    If Not Found Then
    Begin
      Env := 0;
      Dirs := '';
      PutZ(LongInt(@NameZ), 'DPATH');
      If DcScanEnv(LongInt(@NameZ), LongInt(@Env)) = NO_ERROR Then Dirs := GetZ(Env);
      Dirs := Dirs + ';C:\;C:\OS2\SYSTEM';
      While (Not Found) And (Dirs <> '') Do
      Begin
        P := Pos(';', Dirs);
        If P = 0 Then P := Length(Dirs) + 1;
        Dir := Copy(Dirs, 1, P - 1);
        Dirs := Copy(Dirs, P + 1, 255);
        If Dir <> '' Then
        Begin
          If Dir[Length(Dir)] <> '\' Then Dir := Dir + '\';
          Path := UpStr(Dir + U);
          Found := TryOpen(Path, H);
        End;
      End;
    End;
  End;
  If Not Found Then
  Begin
    OpenMsgFile := -1;
    Exit;
  End;
  { place libre (sinon la plus ancienne est fermee) }
  F := -1;
  For I := MaxCache - 1 DownTo 0 Do
    If Not CUsed[I] Then F := I;
  If F < 0 Then
  Begin
    F := 0;
    If CPid[0] = MyPid Then D := DcClose(CHandle[0]);
  End;
  Sz := 0;
  D := DcSetFilePtr(H, 0, 2, LongInt(@Sz));
  CUsed[F] := True;
  CPid[F] := MyPid;
  CHandle[F] := H;
  CSize[F] := Sz;
  CName[F] := Path;
  OpenMsgFile := F;
End;

{ Lire N octets a la position Ofs du fichier F (ou de l'image Img) }
Function ReadAt(F, Img, Ofs, Dst, N : LongInt) : Boolean;
Var Got, D : LongInt;
Begin
  If Img <> 0 Then
  Begin
    CopyB(Img + Ofs, Dst, N);
    ReadAt := True;
  End
  Else
  Begin
    Got := 0;
    D := DcSetFilePtr(CHandle[F], Ofs, 0, LongInt(@Dummy));
    ReadAt := (DcRead(CHandle[F], Dst, N, LongInt(@Got)) = NO_ERROR) And (Got = N);
  End;
End;

{ Taille du fichier F ou de l'image Img (fin du dernier message) }
Function MsgFileSize(F, Img : LongInt) : LongInt;
Var E : LongInt;
Begin
  If Img = 0 Then MsgFileSize := CSize[F]
  Else
  Begin
    E := RdL(Img + $16);
    If E = 0 Then E := $7FFFFFFF;
    MsgFileSize := E;
  End;
End;

{ Lire le message Num (fichier F ou image Img) dans Txt/TxtLen, MType et
  Comp. Rend NO_ERROR, ERROR_MR_MID_NOT_FOUND ou
  ERROR_MR_INV_MSGF_FORMAT. }
Function LoadMsg(F, Img, Num : LongInt) : LongInt;
Var Cnt, First, Off16, IdxOfs, K, O1, O2, Ext, Sz : LongInt; Ok : Boolean;
Begin
  LoadMsg := ERROR_MR_INV_MSGF_FORMAT;
  If Not ReadAt(F, Img, 0, LongInt(@Hdr), $1F) Then Exit;
  If Not ValidHdr(LongInt(@Hdr)) Then Exit;
  Comp := Chr(Hdr[8]) + Chr(Hdr[9]) + Chr(Hdr[10]);
  Cnt := RdW(LongInt(@Hdr) + $0B);
  First := RdW(LongInt(@Hdr) + $0D);
  Off16 := Hdr[$0F];
  IdxOfs := RdW(LongInt(@Hdr) + $12);
  Ext := RdL(LongInt(@Hdr) + $16);
  If IdxOfs < $1F Then Exit;
  LoadMsg := ERROR_MR_MID_NOT_FOUND;
  If (Num < First) Or (Num >= First + Cnt) Then Exit;
  K := Num - First;
  O1 := 0; O2 := 0;
  If Off16 <> 0 Then
  Begin
    Ok := ReadAt(F, Img, IdxOfs + K * 2, LongInt(@Work), 4);
    O1 := RdW(LongInt(@Work));
    If K + 1 < Cnt Then O2 := RdW(LongInt(@Work) + 2);
  End
  Else
  Begin
    Ok := ReadAt(F, Img, IdxOfs + K * 4, LongInt(@Work), 8);
    O1 := RdL(LongInt(@Work));
    If K + 1 < Cnt Then O2 := RdL(LongInt(@Work) + 4);
  End;
  If (K + 1 >= Cnt) Or (O2 = 0) Then
  Begin
    { dernier message : jusqu'au bloc etendu ou a la fin du fichier }
    If Ext > O1 Then O2 := Ext Else O2 := MsgFileSize(F, Img);
  End;
  If O2 - O1 > MsgMax Then O2 := O1 + MsgMax;
  If (O1 <= 0) Or (O2 <= O1) Then Exit;
  Sz := O2 - O1;
  If Img = 0 Then
  Begin
    If Not ReadAt(F, 0, O1, LongInt(@Txt), Sz) Then
    Begin
      LoadMsg := ERROR_MR_INV_MSGF_FORMAT;
      Exit;
    End;
  End
  Else
    CopyB(Img + O1, LongInt(@Txt), Sz);
  MType := Txt[0];
  If (MType = Ord('?')) Or (MType = 0) Then Exit;     { message inutilise }
  { texte sans l'octet de type }
  CopyB(LongInt(@Txt) + 1, LongInt(@Txt), Sz - 1);
  TxtLen := Sz - 1;
  { fin de chaine d'un message en memoire : 0 }
  If Img <> 0 Then
    For K := TxtLen - 1 DownTo 0 Do
      If Txt[K] = 0 Then TxtLen := K;
  LoadMsg := NO_ERROR;
End;

{ L'image Img (segment de messages) sert-elle le fichier Name ? }
Function SegMatches(Img : LongInt; Name : String) : Boolean;
Var Ci : LongInt; N : String; K : LongInt;
Begin
  SegMatches := False;
  If Img = 0 Then Exit;
  If Not ValidHdr(Img) Then Exit;
  Ci := RdW(Img + $14);
  N := '';
  If Ci > 0 Then
  Begin
    K := 0;
    While (K < 13) And (RdB(Img + Ci + 41 + K) <> 0) Do
    Begin
      N := N + UpCase(Chr(RdB(Img + Ci + 41 + K)));
      Inc(K);
    End;
  End;
  SegMatches := (N = '') Or (N = UpStr(BaseName(Name)));
End;

{ ==================================================================== }
{ Partie 6 - Messages integres                                         }
{ ==================================================================== }

{ Messages systeme (OSO001.MSG absent) }
Function SysText(N : LongInt) : String;
Var S : String;
Begin
  Case N Of
    1   : S := 'Fonction incorrecte.';
    2   : S := 'Le systeme ne trouve pas le fichier %1.';
    3   : S := 'Le systeme ne trouve pas le chemin d''acces %1.';
    4   : S := 'Le systeme ne peut ouvrir le fichier %1.';
    5   : S := 'Acces refuse.';
    6   : S := 'Handle incorrect.';
    8   : S := 'Memoire insuffisante.';
    15  : S := 'L''unite %1 est introuvable.';
    16  : S := 'Le repertoire courant ne peut etre supprime.';
    18  : S := 'Il n''y a plus de fichiers.';
    19  : S := 'Le disque est protege en ecriture.';
    21  : S := 'L''unite n''est pas prete.';
    32  : S := 'Le fichier est utilise par un autre processus.';
    80  : S := 'Le fichier %1 existe deja.';
    87  : S := 'Parametre incorrect : %1.';
    109 : S := 'Le tuyau est ferme.';
    112 : S := 'Le disque est plein.';
    123 : S := 'Le nom de fichier %1 est incorrect.';
    316 : S := 'Le message est trop long pour le tampon.';
    317 : S := 'Le message %1 est introuvable dans le fichier de messages %2.';
    318 : S := 'Le fichier de messages %1 est introuvable ou inaccessible.';
    319 : S := 'Le format du fichier de messages %1 est incorrect.';
    320 : S := 'Le nombre de variables du message est incorrect.';
    1041 : S := 'Le nom indique n''est pas reconnu comme une commande interne ou externe.';
    3175 : S := 'Une exception s''est produite dans le processus %1.';
  Else
    S := '';
  End;
  SysText := S;
End;

{ Placer "SYSnnnn: texte" CR LF (messages integres) dans Txt/TxtLen }
Procedure SetSysMsg(N : LongInt; S : String);
Begin
  S := 'SYS' + Num4(N) + ': ' + S + Chr(13) + Chr(10);
  PutZ(LongInt(@Txt), S);
  TxtLen := Length(S);
End;

{ Message d'erreur d'acces (317, 318, 319) dans le tampon de l'appelant }
Function ErrorMsg(Code, Num : LongInt; FName : String; PBuf, CbBuf, PcbMsg : LongInt; Is16 : Boolean) : LongInt;
Var R : LongInt;
Begin
  SetSysMsg(Code, SysText(Code));
  If Code = ERROR_MR_MID_NOT_FOUND Then
  Begin
    PutZ(LongInt(@VarA), Num4(Num));
    PutZ(LongInt(@VarB), FName);
  End
  Else
    PutZ(LongInt(@VarA), FName);
  Tab[0] := LongInt(@VarA);
  Tab[1] := LongInt(@VarB);
  R := InsVars(LongInt(@Tab), 2, LongInt(@Txt), TxtLen, PBuf, CbBuf);
  PutLen(PcbMsg, OutLen, Is16);
  ErrorMsg := Code;
End;

{ ==================================================================== }
{ Partie 7 - Fonctions                                                 }
{ ==================================================================== }

{ DosTrueGetMessage (commune aux points d'entree 2 et 6) }
Function GetMsg(PTable, CTable, PBuf, CbBuf, Num, PFile, PcbMsg, PSeg : LongInt; Is16 : Boolean) : LongInt;
Var R, F, Img, P, N : LongInt; FName, S : String;
Begin
  If (PBuf = 0) Or (PcbMsg = 0) Or (PFile = 0) Or (CbBuf < 0) Then
  Begin
    GetMsg := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If (CTable < 0) Or (CTable > 9) Then
  Begin
    GetMsg := ERROR_MR_INV_IVCOUNT;
    Exit;
  End;
  FName := GetZ(PFile);
  { 1. segment de messages ; 2. fichier sur disque }
  R := ERROR_MR_UN_ACC_MSGF;
  If SegMatches(PSeg, FName) Then
  Begin
    R := LoadMsg(0, PSeg, Num);
    If R <> NO_ERROR Then R := ERROR_MR_UN_ACC_MSGF;   { essayer le disque }
  End;
  If R <> NO_ERROR Then
  Begin
    F := OpenMsgFile(FName);
    If F >= 0 Then R := LoadMsg(F, 0, Num)
    Else If UpStr(BaseName(FName)) = 'OSO001.MSG' Then
    Begin
      { messages systeme integres }
      S := SysText(Num);
      If S = '' Then R := ERROR_MR_MID_NOT_FOUND
      Else
      Begin
        SetSysMsg(Num, S);
        R := InsVars(PTable, CTable, LongInt(@Txt), TxtLen, PBuf, CbBuf);
        PutLen(PcbMsg, OutLen, Is16);
        GetMsg := R;
        Exit;
      End;
    End;
  End;
  If R <> NO_ERROR Then
  Begin
    GetMsg := ErrorMsg(R, Num, FName, PBuf, CbBuf, PcbMsg, Is16);
    Exit;
  End;
  { prefixe des erreurs et avertissements ; %0 : pas de retour a la ligne }
  N := TxtLen;
  P := 0;
  While P + 1 < N Do
  Begin
    If (Txt[P] = Ord('%')) And (Txt[P + 1] = Ord('0')) Then
    Begin
      N := P;                         { %0 et la fin de ligne retires }
      P := N;
    End
    Else
      Inc(P);
  End;
  S := '';
  If (MType = Ord('E')) Or (MType = Ord('W')) Then S := Comp + Num4(Num) + ': ';
  PutZ(LongInt(@Work), S);
  CopyB(LongInt(@Txt), LongInt(@Work) + Length(S), N);
  R := InsVars(PTable, CTable, LongInt(@Work), Length(S) + N, PBuf, CbBuf);
  PutLen(PcbMsg, OutLen, Is16);
  GetMsg := R;
End;

{ ---------------------------------------------------------------------
  DosTrueGetMessage(pTable, cTable, pBuf, cbBuf, msgnumber, pszFile,
  pcbMsg, pMsgSeg) (ordinal 6) : lire le message msgnumber du fichier
  pszFile (ou du segment pMsgSeg), y inserer les cTable variables (0 a 9)
  et le copier dans pBuf ; *pcbMsg (ULONG) <- longueur }
Function DosTrueGetMessage(PTable, CTable, PBuf, CbBuf, Num, PFile, PcbMsg, PSeg : LongInt) : LongInt;
Begin
  DosTrueGetMessage := GetMsg(PTable, CTable, PBuf, CbBuf, Num, PFile, PcbMsg, PSeg, False);
End;

{ Dos16TrueGetMessage (ordinal 2) : *pcbMsg est un USHORT }
Function Dos16TrueGetMessage(PTable, CTable, PBuf, CbBuf, Num, PFile, PcbMsg, PSeg : LongInt) : LongInt;
Begin
  Dos16TrueGetMessage := GetMsg(PTable, CTable, PBuf, CbBuf, Num, PFile, PcbMsg, PSeg, True);
End;

{ ---------------------------------------------------------------------
  DosInsertMessage(pTable, cTable, pszMsg, cbMsg, pBuf, cbBuf, pcbMsg)
  (ordinal 4) : inserer les variables %1 a %9 dans le message pszMsg
  (cbMsg octets) ; *pcbMsg (ULONG) <- longueur }
Function InsMsg(PTable, CTable, PMsg, CbMsg, PBuf, CbBuf, PcbMsg : LongInt; Is16 : Boolean) : LongInt;
Var R : LongInt;
Begin
  If (PMsg = 0) Or (PBuf = 0) Or (PcbMsg = 0) Or (CbMsg < 0) Or (CbBuf < 0) Then
    R := ERROR_INVALID_PARAMETER
  Else If (CTable < 0) Or (CTable > 9) Or ((CTable > 0) And (PTable = 0)) Then
    R := ERROR_MR_INV_IVCOUNT
  Else
  Begin
    R := InsVars(PTable, CTable, PMsg, CbMsg, PBuf, CbBuf);
    PutLen(PcbMsg, OutLen, Is16);
  End;
  InsMsg := R;
End;

Function DosInsertMessage(PTable, CTable, PMsg, CbMsg, PBuf, CbBuf, PcbMsg : LongInt) : LongInt;
Begin
  DosInsertMessage := InsMsg(PTable, CTable, PMsg, CbMsg, PBuf, CbBuf, PcbMsg, False);
End;

{ DosInsMessage (ordinal 3, OS/2 1.x) : *pcbMsg est un USHORT }
Function DosInsMessage(PTable, CTable, PMsg, CbMsg, PBuf, CbBuf, PcbMsg : LongInt) : LongInt;
Begin
  DosInsMessage := InsMsg(PTable, CTable, PMsg, CbMsg, PBuf, CbBuf, PcbMsg, True);
End;

{ ---------------------------------------------------------------------
  DosPutMessage(hfile, cbMsg, pBuf) (ordinal 5) : ecrire le message sur
  hfile. Sur un peripherique (ecran), les lignes de plus de 80 colonnes
  sont coupees entre les mots. }
Function PutMsg(H, Cb, PBuf : LongInt) : LongInt;
Var R, T, A, I, J, O, Col, W : LongInt;
Begin
  If (PBuf = 0) And (Cb > 0) Then
  Begin
    PutMsg := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  T := 0;
  R := DcQueryHType(H, LongInt(@T), LongInt(@A));
  If R <> NO_ERROR Then
  Begin
    PutMsg := R;
    Exit;
  End;
  If ((T And $FF) <> 1) Or (Cb > MsgMax) Then
    R := DcWrite(H, PBuf, Cb, LongInt(@W))           { fichier : tel quel }
  Else
  Begin
    { peripherique : coupure des lignes entre les mots }
    O := 0; Col := 0; I := 0;
    While I < Cb Do
    Begin
      If RdB(PBuf + I) = 13 Then
      Begin
        OutB[O] := 13; Inc(O); Col := 0; Inc(I);
      End
      Else If RdB(PBuf + I) = 10 Then
      Begin
        OutB[O] := 10; Inc(O); Inc(I);
      End
      Else If RdB(PBuf + I) = 32 Then
      Begin
        If Col < ScrCols Then
        Begin
          OutB[O] := 32; Inc(O); Inc(Col);
        End;
        Inc(I);
      End
      Else
      Begin
        { mot : longueur jusqu'a l'espace ou la fin de ligne }
        J := I;
        While (J < Cb) And (RdB(PBuf + J) <> 32) And (RdB(PBuf + J) <> 13) And (RdB(PBuf + J) <> 10) Do Inc(J);
        If (Col > 0) And (Col + (J - I) > ScrCols) Then
        Begin
          { le mot passe a la ligne suivante (espaces de fin retires) }
          While (O > 0) And (OutB[O - 1] = 32) Do Dec(O);
          OutB[O] := 13; OutB[O + 1] := 10; O := O + 2;
          Col := 0;
        End;
        While I < J Do
        Begin
          OutB[O] := RdB(PBuf + I); Inc(O); Inc(I);
          Inc(Col);
          If Col >= ScrCols Then Col := 0;      { mot plus long qu'une ligne }
        End;
      End;
    End;
    R := DcWrite(H, LongInt(@OutB), O, LongInt(@W));
  End;
  PutMsg := R;
End;

Function DosPutMessage(H, Cb, PBuf : LongInt) : LongInt;
Begin
  DosPutMessage := PutMsg(H, Cb, PBuf);
End;

{ Dos16PutMessage (ordinal 1, OS/2 1.x) }
Function Dos16PutMessage(H, Cb, PBuf : LongInt) : LongInt;
Begin
  Dos16PutMessage := PutMsg(H, Cb, PBuf);
End;

{ ---------------------------------------------------------------------
  DosIQueryMessageCP(pb, cb, pszFile, pcbBuf, pMsgSeg) (ordinal 8) :
  pages de codes du fichier de messages. pb recoit (mots) : nombre de
  pages de codes, les pages, la famille de langue et sa version ;
  *pcbBuf (ULONG) <- octets ecrits }
Function QueryCP(PB, Cb, PFile, PcbBuf, PSeg : LongInt; Is16 : Boolean) : LongInt;
Var R, F, Ci, N, K, Need : LongInt; FName : String;
Begin
  If (PB = 0) Or (PcbBuf = 0) Or (PFile = 0) Then
  Begin
    QueryCP := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  FName := GetZ(PFile);
  R := NO_ERROR;
  If SegMatches(PSeg, FName) Then
    CopyB(PSeg, LongInt(@Hdr), $1F)
  Else
  Begin
    F := OpenMsgFile(FName);
    If F < 0 Then
    Begin
      If UpStr(BaseName(FName)) = 'OSO001.MSG' Then
      Begin
        { messages integres : page de codes du systeme }
        If Cb < 8 Then R := ERROR_BUFFER_OVERFLOW
        Else
        Begin
          WrW(PB, 1); WrW(PB + 2, 850); WrW(PB + 4, 2); WrW(PB + 6, 1);
          PutLen(PcbBuf, 8, Is16);
        End;
        QueryCP := R;
        Exit;
      End;
      QueryCP := ERROR_MR_UN_ACC_MSGF;
      Exit;
    End;
    PSeg := 0;
    If Not ReadAt(F, 0, 0, LongInt(@Hdr), $1F) Then R := ERROR_MR_INV_MSGF_FORMAT;
  End;
  If (R = NO_ERROR) And Not ValidHdr(LongInt(@Hdr)) Then R := ERROR_MR_INV_MSGF_FORMAT;
  If R = NO_ERROR Then
  Begin
    Ci := RdW(LongInt(@Hdr) + $14);
    If Ci = 0 Then R := ERROR_MR_INV_MSGF_FORMAT
    Else
    Begin
      If PSeg <> 0 Then CopyB(PSeg + Ci, LongInt(@Work), 54)
      Else If Not ReadAt(F, 0, Ci, LongInt(@Work), 41) Then R := ERROR_MR_INV_MSGF_FORMAT;
    End;
  End;
  If R = NO_ERROR Then
  Begin
    N := RdW(LongInt(@Work) + 7);
    If N > 16 Then N := 16;
    Need := 2 + N * 2 + 4;
    If Cb < Need Then R := ERROR_BUFFER_OVERFLOW
    Else
    Begin
      WrW(PB, N);
      For K := 0 To N - 1 Do WrW(PB + 2 + K * 2, RdW(LongInt(@Work) + 9 + K * 2));
      WrW(PB + 2 + N * 2, RdW(LongInt(@Work) + 3));
      WrW(PB + 4 + N * 2, RdW(LongInt(@Work) + 5));
      PutLen(PcbBuf, Need, Is16);
    End;
  End;
  QueryCP := R;
End;

Function DosIQueryMessageCP(PB, Cb, PFile, PcbBuf, PSeg : LongInt) : LongInt;
Begin
  DosIQueryMessageCP := QueryCP(PB, Cb, PFile, PcbBuf, PSeg, False);
End;

{ Dos16IQueryMessageCP (ordinal 7) : *pcbBuf est un USHORT }
Function Dos16IQueryMessageCP(PB, Cb, PFile, PcbBuf, PSeg : LongInt) : LongInt;
Begin
  Dos16IQueryMessageCP := QueryCP(PB, Cb, PFile, PcbBuf, PSeg, True);
End;

{ ---------------------------------------------------------------------
  DosCloseMessageFile(pszFile) (ordinal 9) : fermer le fichier de
  messages garde ouvert pour le processus (0 : tous ses fichiers) ;
  ERROR_INVALID_PARAMETER s'il n'est pas ouvert }
Function DosCloseMessageFile(PFile : LongInt) : LongInt;
Var I, D, R : LongInt; U : String; Hit : Boolean;
Begin
  PurgeCache;
  R := ERROR_INVALID_PARAMETER;
  U := UpStr(GetZ(PFile));
  For I := 0 To MaxCache - 1 Do
    If CUsed[I] And (CPid[I] = MyPid) Then
    Begin
      Hit := (PFile = 0) Or (CName[I] = U) Or (UpStr(BaseName(CName[I])) = UpStr(BaseName(U)));
      If Hit Then
      Begin
        D := DcClose(CHandle[I]);
        CUsed[I] := False;
        R := NO_ERROR;
      End;
    End;
  If PFile = 0 Then R := NO_ERROR;
  DosCloseMessageFile := R;
End;

{ ==================================================================== }
{ Exportations                                                         }
{ ==================================================================== }

exports
  Dos16PutMessage Index 1,
  Dos16TrueGetMessage Index 2,
  DosInsMessage Index 3, DosInsMessage Index 3 Name 'Dos16InsMessage',
  DosInsertMessage Index 4, DosInsertMessage Index 4 Name 'Dos32InsertMessage',
  DosPutMessage Index 5, DosPutMessage Index 5 Name 'Dos32PutMessage',
  DosTrueGetMessage Index 6, DosTrueGetMessage Index 6 Name 'Dos32TrueGetMessage',
  Dos16IQueryMessageCP Index 7,
  DosIQueryMessageCP Index 8, DosIQueryMessageCP Index 8 Name 'Dos32IQueryMessageCP',
  DosCloseMessageFile Index 9, DosCloseMessageFile Index 9 Name 'Dos32CloseMessageFile';

Var
  InitI : LongInt;

BEGIN
  For InitI := 0 To MaxCache - 1 Do CUsed[InitI] := False;
END.
