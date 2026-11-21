{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: NET - lecteurs reseau (NET USE) d'OS/2-0.
}

Program NET;

{$R-,S-,I-}

{ Compilation : OS2PC NET.PAS   (produit NET.EXE)

  La commande NET USE du Requester d'OS/2 (LAN Server), pour les
  partages SMB (Windows, Samba) par SMB.IFS :

    NET USE                          liste des lecteurs reseau
    NET USE Z: \\serveur\partage [motdepasse | *] [/USER:[domaine\]nom]
    NET USE * \\serveur\partage ...  premiere lettre libre (de Z: vers D:)
    NET USE Z: /DELETE               deconnecter

  * demande le mot de passe sans l'afficher. Le lecteur est attache par
  DosFSAttach(lettre, "SMB", donnees, FS_ATTACH) ; DosQueryFSAttach
  donne le chemin reseau d'un lecteur. }

Function DosFSAttach(PDev, PFsd, PData, CbData, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFSAttach(PDev, Ordinal, Level, PBuf, PCb : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt; External 'DOSCALLS';
Function DosLoadModule(PObj, CbObj, PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function KbdCharIn(PKey, Wait, H : LongInt) : LongInt; External 'KBDCALLS';

Var
  Data : Array[0..767] Of Byte;
  Buf : Array[0..1023] Of Byte;
  Z1, Z2 : Array[0..299] Of Byte;

Type
  PB1 = ^Byte; PW2 = ^Word;

Function RB(A : LongInt) : LongInt;
Var Q : PB1;
Begin
  Q := Pointer(A);
  RB := Q^;
End;

Function RW(A : LongInt) : LongInt;
Var Q : PW2;
Begin
  Q := Pointer(A);
  RW := Q^;
End;

Procedure WB(A, V : LongInt);
Var Q : PB1;
Begin
  Q := Pointer(A);
  Q^ := V And 255;
End;

Function UpStr(S : String) : String;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do S[I] := UpCase(S[I]);
  UpStr := S;
End;

Function PZ(A : LongInt; S : String) : LongInt;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do WB(A + I - 1, Ord(S[I]));
  WB(A + Length(S), 0);
  PZ := A;
End;

Function GetZ(A : LongInt) : String;
Var S : String;
Begin
  S := '';
  While (RB(A) <> 0) And (Length(S) < 255) Do
  Begin
    S := S + Chr(RB(A));
    Inc(A);
  End;
  GetZ := S;
End;

{ texte de la derniere erreur de SMB.IFS (SMBLASTERROR) }
Function SmbText : String;
Var H, F, R : LongInt; Fail : Array[0..63] Of Byte;
Begin
  SmbText := '';
  H := 0; F := 0;
  If DosLoadModule(LongInt(@Fail), 64, PZ(LongInt(@Z1), 'C:\SMB.IFS'), LongInt(@H)) <> 0 Then Exit;
  If DosQueryProcAddr(H, 0, PZ(LongInt(@Z1), 'SMBLASTERROR'), LongInt(@F)) <> 0 Then Exit;
  R := LongInt(@Buf);
  asm
    mov eax,256
    push eax
    mov eax,R
    push eax
    mov eax,F
    call eax
    add esp,8
  end;
  SmbText := GetZ(LongInt(@Buf));
End;

Function ErrText(E : LongInt) : String;
Var S : String;
Begin
  Case E Of
    5 : S := 'Acces refuse.';
    15 : S := 'Lecteur incorrect.';
    53 : S := 'Le chemin reseau est introuvable.';
    59 : S := 'Erreur reseau inattendue.';
    64 : S := 'Le serveur ne repond plus.';
    65 : S := 'Acces au partage refuse.';
    67 : S := 'Le nom du partage est introuvable.';
    85 : S := 'Ce lecteur est deja utilise.';
    86 : S := 'Nom d''utilisateur ou mot de passe incorrect.';
    124 : S := 'Le systeme de fichiers SMB.IFS est absent.';
  Else
    Str(E, S);
    S := 'Erreur ' + S + '.';
  End;
  ErrText := S;
End;

{ mot de passe tape sans echo }
Function AskPassword : String;
Var K : Array[0..9] Of Byte; S : String; C : LongInt;
Begin
  Write('Mot de passe : ');
  S := '';
  Repeat
    FillChar(K, 10, 0);
    KbdCharIn(LongInt(@K), 0, 0);
    C := K[0];
    If (C = 8) And (S <> '') Then Delete(S, Length(S), 1)
    Else If C >= 32 Then S := S + Chr(C);
  Until (C = 13) Or (C = 10);
  WriteLn;
  AskPassword := S;
End;

Procedure ListDrives;
Var D, Cb, N, R, L : LongInt; S, Fs : String; Any : Boolean;
Begin
  Any := False;
  For D := 3 To 26 Do
  Begin
    S := Chr(64 + D) + ':';
    Cb := 1024;
    R := DosQueryFSAttach(PZ(LongInt(@Z1), S), 0, 1, LongInt(@Buf), LongInt(@Cb));
    If (R = 0) And (RW(LongInt(@Buf)) = 4) Then
    Begin
      If Not Any Then
      Begin
        WriteLn('Lecteur  Chemin reseau                         Systeme');
        WriteLn('-------  ------------------------------------  -------');
      End;
      Any := True;
      N := RW(LongInt(@Buf) + 2);
      L := RW(LongInt(@Buf) + 4);
      Fs := GetZ(LongInt(@Buf) + 8 + N + 1);
      S := GetZ(LongInt(@Buf) + 8 + N + 1 + L + 1);
      While Length(S) < 36 Do S := S + ' ';
      WriteLn(Chr(64 + D), ':       ', S, '  ', Fs);
    End;
  End;
  If Not Any Then WriteLn('Aucun lecteur reseau.');
End;

Procedure Usage;
Begin
  WriteLn('NET USE                                     liste des lecteurs reseau');
  WriteLn('NET USE lettre: \\serveur\partage [motdepasse | *] [/USER:[domaine\]nom]');
  WriteLn('NET USE * \\serveur\partage ...             premiere lettre libre');
  WriteLn('NET USE lettre: /DELETE                     deconnecter');
End;

Var
  I, R, P, D, Cur, Map : LongInt;
  A, Dev, Remote, User, Pass, T : String;
  Del : Boolean;

BEGIN
  If (ParamCount = 0) Or (UpStr(ParamStr(1)) <> 'USE') Then
  Begin
    Usage;
    Halt(1);
  End;
  If ParamCount = 1 Then
  Begin
    ListDrives;
    Halt(0);
  End;
  Dev := ''; Remote := ''; User := ''; Pass := ''; Del := False;
  For I := 2 To ParamCount Do
  Begin
    A := ParamStr(I);
    T := UpStr(A);
    If (T = '/DELETE') Or (T = '/D') Then Del := True
    Else If Copy(T, 1, 6) = '/USER:' Then User := Copy(A, 7, 255)
    Else If Copy(T, 1, 2) = '/U' Then User := Copy(A, Pos(':', A) + 1, 255)
    Else If (Dev = '') And (((Length(A) = 2) And (A[2] = ':')) Or (A = '*')) Then Dev := T
    Else If (Remote = '') And (Copy(A, 1, 2) = '\\') Then Remote := A
    Else Pass := A;
  End;
  If Del Then
  Begin
    If Dev = '' Then
    Begin
      Usage;
      Halt(1);
    End;
    R := DosFSAttach(PZ(LongInt(@Z1), Dev), PZ(LongInt(@Z2), 'SMB'), 0, 0, 1);
    If R <> 0 Then
    Begin
      WriteLn(Dev, ' : ', ErrText(R));
      Halt(2);
    End;
    WriteLn(Dev, ' est deconnecte.');
    Halt(0);
  End;
  If Remote = '' Then
  Begin
    Usage;
    Halt(1);
  End;
  If Dev = '*' Then
  Begin
    Cur := 0; Map := 0;
    DosQueryCurrentDisk(LongInt(@Cur), LongInt(@Map));
    Dev := '';
    For D := 25 DownTo 3 Do
      If (Dev = '') And ((Map And (1 Shl D)) = 0) Then Dev := Chr(65 + D) + ':';
    If Dev = '' Then
    Begin
      WriteLn('Aucune lettre libre.');
      Halt(2);
    End;
  End;
  If Dev = '' Then
  Begin
    Usage;
    Halt(1);
  End;
  If Pass = '*' Then Pass := AskPassword;
  P := 0;
  For I := 1 To Length(Remote) Do Begin Data[P] := Ord(Remote[I]); Inc(P); End;
  Data[P] := 0; Inc(P);
  For I := 1 To Length(User) Do Begin Data[P] := Ord(User[I]); Inc(P); End;
  Data[P] := 0; Inc(P);
  For I := 1 To Length(Pass) Do Begin Data[P] := Ord(Pass[I]); Inc(P); End;
  Data[P] := 0; Inc(P);
  R := DosFSAttach(PZ(LongInt(@Z1), Dev), PZ(LongInt(@Z2), 'SMB'), LongInt(@Data), P, 0);
  If R <> 0 Then
  Begin
    WriteLn(Dev, ' ', Remote, ' : ', ErrText(R));
    T := SmbText;
    If T <> '' Then WriteLn(T);
    Halt(2);
  End;
  WriteLn(Dev, ' est connecte a ', Remote, '.');
END.
