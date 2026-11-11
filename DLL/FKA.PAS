{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 FKA.DLL de OS/2-0 (zone des touches
                de fonction, Function Key Area).
}

Library FKA;

{$IMAGEBASE $00D00000}
{$R-,S-,I-}

{ Compilation : OS2PC FKA.PAS   (produit FKA.DLL)

  La zone des touches de fonction (FKA, Function Key Area) affiche au bas
  de l'ecran les libelles des touches F1 a F10 (ou F12) d'une application,
  comme dans les versions DBCS d'OS/2. Dans OS/2-0 (ecran texte 80 x 25,
  sans Presentation Manager), une FKA est une "fenetre" en mode texte
  dessinee sur la derniere ligne (forme courte) ou les deux dernieres
  lignes (forme longue) de l'ecran.

  Fonctions exportees (ordinaux d'origine de FKA.DLL) :

    FKAInit                 64  initialiser la FKA pour le processus
    QueryFKADisplayDetails  65  details d'affichage d'une FKA
    WINFKAWNDPROC           66  procedure de fenetre de la FKA
    WINLOADFKA              67  charger une FKA (ressource ou fichier)
    WINCREATEFKA            68  creer une FKA a partir de libelles
    WINSETFKAFORM           69  fixer la forme (masquee, courte, longue)
    WINQUERYFKAFORM         70  demander la forme
    WINGOTOFKA              71  donner le focus a la FKA
    WINGOFROMFKA            72  rendre le focus a l'application

  Convention _System (comme DOSCALLS.DLL) : parametres de 32 bits, empiles
  de droite a gauche, pile nettoyee par l'appelant ; avec OS2PC :

    Function WinCreateFKA(Parent, PLabels, Count, Form : LongInt) : LongInt;
      External 'FKA' Name 'WINCREATEFKA';

  Formes : FKAFORM_OFF (0) masquee, FKAFORM_SHORT (1) une ligne : "F1 Aide",
  FKAFORM_LONG (2) deux lignes : numeros des touches puis libelles. Les
  lignes occupees sont retirees de la zone de defilement de la console
  (SetConsoleScreenBufferSize du noyau) : le texte de l'application ne les
  recouvre pas ; elles sont rendues a la destruction de la FKA ou a la fin
  du processus.

  Libelles : "Texte" ou "Texte,commande" ; la commande (nombre) est rendue
  par WINFKAWNDPROC quand la touche est choisie (par defaut, le numero de
  la touche).

  WINLOADFKA(parent, module, id) lit la ressource de type RT_FKA (300) et
  de numero id du module (DosGetResource), sinon le fichier texte FKAnnnn.TXT
  (nnnn = id) du repertoire courant puis de C:\. Format : une ligne par
  touche "n=Texte[,commande]", et en option "FORM=OFF|SHORT|LONG" et
  "KEYS=10|12" (les lignes peuvent aussi etre separees par des ";").

  Messages de WINFKAWNDPROC(hwnd, msg, mp1, mp2) :
    WM_CREATE ($0001), WM_DESTROY ($0002), WM_PAINT ($0023)
    WM_SETFOCUS ($000F) : mp2 <> 0 donne le focus, 0 le retire
    WM_CHAR ($007A) : mp1 = drapeaux KC_* (mot bas), mp2 = caractere (mot
      bas) et touche virtuelle VK_* (mot haut). F1..F12 rendent la
      commande de la touche ; avec le focus, fleches gauche/droite,
      Debut/Fin choisissent une touche, Entree rend sa commande, Echap
      rend le focus a l'application. Rend 0 si aucune commande.
    FKAM_SETFORM ($0F01) mp1 = forme ; FKAM_QUERYFORM ($0F02)
    FKAM_SETTEXT ($0F03) mp1 = touche, mp2 = libelle (ASCIIZ)
    FKAM_QUERYTEXT ($0F04) mp1 = touche, mp2 = tampon (64 octets) : longueur
    FKAM_SETCMD ($0F05) mp1 = touche, mp2 = commande
    FKAM_QUERYCMD ($0F06) mp1 = touche : commande

  QueryFKADisplayDetails(hwnd, pDetails) remplit FKADISPLAYDETAILS (huit
  mots doubles) : cb, forme, premiere ligne, nombre de lignes, nombre de
  touches, largeur d'une touche, focus, touche choisie. }

{ ==================================================================== }
{ Constantes et types                                                  }
{ ==================================================================== }

Const
  FKAFORM_OFF   = 0;
  FKAFORM_SHORT = 1;
  FKAFORM_LONG  = 2;

  WM_CREATE     = $0001;
  WM_DESTROY    = $0002;
  WM_SETFOCUS   = $000F;
  WM_PAINT      = $0023;
  WM_CHAR       = $007A;
  FKAM_SETFORM  = $0F01;
  FKAM_QUERYFORM = $0F02;
  FKAM_SETTEXT  = $0F03;
  FKAM_QUERYTEXT = $0F04;
  FKAM_SETCMD   = $0F05;
  FKAM_QUERYCMD = $0F06;

  KC_KEYUP      = $0040;
  VK_HOME       = $14;
  VK_LEFT       = $15;
  VK_RIGHT      = $17;
  VK_END        = $13;
  VK_ESC        = $0F;
  VK_NEWLINE    = $08;
  VK_ENTER      = $1E;
  VK_F1         = $20;
  VK_F12        = $2B;

  RT_FKA        = 300;
  MaxFka        = 8;
  HwndBase      = $0FA00000;
  VideoBase     = $000B8000;
  ScrCols       = 80;
  ScrRows       = 25;
  AttrKey       = $70;     { numero de touche : noir sur gris }
  AttrLabel     = $30;     { libelle : noir sur cyan }
  AttrFocus     = $1F;     { touche choisie : blanc sur bleu }

Type
  TFka = Record
    Used    : Boolean;
    Owner   : LongInt;
    Parent  : LongInt;
    Form    : LongInt;
    NKeys   : LongInt;
    Focus   : Boolean;
    Sel     : LongInt;
    Labels  : Array[1..12] Of String[31];
    Cmds    : Array[1..12] Of LongInt;
  End;

  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  Fkas      : Array[0..MaxFka - 1] Of TFka;
  InitPids  : Array[0..15] Of LongInt;
  Buf       : Array[0..2047] Of Byte;
  NameBuf   : Array[0..127] Of Byte;

{ Importations : noyau (couche de base) et DOSCALLS.DLL }
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KGetStdHandle(N : LongInt) : LongInt; External 'DOSCALLS' Name 'GetStdHandle';
Function KSetConsoleScreenBufferSize(H, Size : LongInt) : LongInt; External 'DOSCALLS' Name 'SetConsoleScreenBufferSize';
Function DosGetResource(H, IdType, IdName, PPb : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryResourceSize(H, IdType, IdName, PSize : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';

{ ==================================================================== }
{ Utilitaires                                                          }
{ ==================================================================== }

Function PeekL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  PeekL := P^;
End;

Procedure PokeL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V;
End;

Function PeekB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  PeekB := P^;
End;

Procedure PokeB(A, V : LongInt);
Var P : PByte;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FF;
End;

Procedure PokeW(A, V : LongInt);
Var P : PWord;
Begin
  P := Pointer(A);
  P^ := V And $FFFF;
End;

Function GetStr(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (PeekB(A + N) <> 0) And (N < 255) Do
    Begin
      S := S + Chr(PeekB(A + N));
      Inc(N);
    End;
  End;
  GetStr := S;
End;

Procedure PutStr(A : LongInt; S : String; Max : LongInt);
Var I, L : LongInt;
Begin
  If (A = 0) Or (Max <= 0) Then Exit;
  L := Length(S);
  If L > Max - 1 Then L := Max - 1;
  For I := 1 To L Do PokeB(A + I - 1, Ord(S[I]));
  PokeB(A + L, 0);
End;

Function Trim(S : String) : String;
Begin
  While (Length(S) > 0) And (S[1] = ' ') Do Delete(S, 1, 1);
  While (Length(S) > 0) And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
  Trim := S;
End;

Function UpStr(S : String) : String;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do
    If (S[I] >= 'a') And (S[I] <= 'z') Then S[I] := Chr(Ord(S[I]) - 32);
  UpStr := S;
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function SVal(S : String) : LongInt;
Var V, C : LongInt;
Begin
  Val(Trim(S), V, C);
  If C <> 0 Then V := 0;
  SVal := V;
End;

{ Index d'une FKA du processus courant, -1 si le handle est invalide }
Function FkaIdx(Hwnd : LongInt) : LongInt;
Var I : LongInt;
Begin
  FkaIdx := -1;
  I := Hwnd - HwndBase - 1;
  If (I < 0) Or (I >= MaxFka) Then Exit;
  If Not Fkas[I].Used Or (Fkas[I].Owner <> KGetCurrentProcessId) Then Exit;
  FkaIdx := I;
End;

{ ==================================================================== }
{ Affichage                                                            }
{ ==================================================================== }

Procedure PutCell(Col, Row, Ch, Attr : LongInt);
Begin
  If (Col < 0) Or (Col >= ScrCols) Or (Row < 0) Or (Row >= ScrRows) Then Exit;
  PokeW(VideoBase + (Row * ScrCols + Col) * 2, (Attr Shl 8) Or (Ch And $FF));
End;

Procedure ClearRow(Row : LongInt);
Var C : LongInt;
Begin
  For C := 0 To ScrCols - 1 Do PutCell(C, Row, 32, $07);
End;

Procedure PutText(Col, Row, Width : LongInt; S : String; Attr : LongInt);
Var I : LongInt;
Begin
  For I := 1 To Width Do
    If I <= Length(S) Then PutCell(Col + I - 1, Row, Ord(S[I]), Attr)
    Else PutCell(Col + I - 1, Row, 32, Attr);
End;

Function KeyWidth(I : LongInt) : LongInt;
Begin
  KeyWidth := ScrCols Div Fkas[I].NKeys;
End;

{ Lignes occupees par une forme }
Function FormLines(Form : LongInt) : LongInt;
Begin
  Case Form Of
    FKAFORM_SHORT : FormLines := 1;
    FKAFORM_LONG  : FormLines := 2;
  Else
    FormLines := 0;
  End;
End;

Procedure Paint(I : LongInt);
Var K, W, Col, Row, A : LongInt; Num : String;
Begin
  Reserve(FormLines(Fkas[I].Form));
  W := KeyWidth(I);
  Case Fkas[I].Form Of
    FKAFORM_SHORT :
      Begin
        Row := ScrRows - 1;
        ClearRow(Row);
        For K := 1 To Fkas[I].NKeys Do
        Begin
          Col := (K - 1) * W;
          Num := IStr(K);
          If Fkas[I].Focus And (K = Fkas[I].Sel) Then A := AttrFocus Else A := AttrKey;
          PutText(Col, Row, Length(Num), Num, A);
          If Fkas[I].Focus And (K = Fkas[I].Sel) Then A := AttrFocus Else A := AttrLabel;
          PutText(Col + Length(Num), Row, W - Length(Num) - 1, Fkas[I].Labels[K], A);
        End;
      End;
    FKAFORM_LONG :
      Begin
        ClearRow(ScrRows - 2);
        ClearRow(ScrRows - 1);
        For K := 1 To Fkas[I].NKeys Do
        Begin
          Col := (K - 1) * W;
          If Fkas[I].Focus And (K = Fkas[I].Sel) Then A := AttrFocus Else A := AttrKey;
          PutText(Col, ScrRows - 2, W - 1, 'F' + IStr(K), A);
          If Fkas[I].Focus And (K = Fkas[I].Sel) Then A := AttrFocus Else A := AttrLabel;
          PutText(Col, ScrRows - 1, W - 1, Fkas[I].Labels[K], A);
        End;
      End;
  End;
End;

{ Reserver les lignes du bas pour la FKA : la console (WriteLn, defilement,
  ClrScr) n'utilise plus que les lignes du dessus }
Procedure Reserve(Lines : LongInt);
Begin
  KSetConsoleScreenBufferSize(KGetStdHandle(-11), ScrCols Or ((ScrRows - Lines) Shl 16));
End;

{ Effacer les lignes d'une forme (avant changement ou destruction) }
Procedure EraseForm(Form : LongInt);
Begin
  If Form = FKAFORM_SHORT Then ClearRow(ScrRows - 1)
  Else If Form = FKAFORM_LONG Then
  Begin
    ClearRow(ScrRows - 2);
    ClearRow(ScrRows - 1);
  End;
End;

{ ==================================================================== }
{ Creation, libelles                                                   }
{ ==================================================================== }

Function NewFka(Parent, NKeys, Form : LongInt) : LongInt;
Var I, K, Slot, Pid : LongInt;
Begin
  Pid := KGetCurrentProcessId;
  Slot := -1;
  For I := 0 To MaxFka - 1 Do
    If (Slot < 0) And Not Fkas[I].Used Then Slot := I;
  { table pleine : reprendre une FKA d'un autre processus (termine) }
  If Slot < 0 Then
    For I := 0 To MaxFka - 1 Do
      If (Slot < 0) And (Fkas[I].Owner <> Pid) Then Slot := I;
  NewFka := Slot;
  If Slot < 0 Then Exit;
  Fkas[Slot].Used := True;
  Fkas[Slot].Owner := Pid;
  Fkas[Slot].Parent := Parent;
  Fkas[Slot].Form := Form;
  If NKeys > 10 Then Fkas[Slot].NKeys := 12 Else Fkas[Slot].NKeys := 10;
  Fkas[Slot].Focus := False;
  Fkas[Slot].Sel := 1;
  For K := 1 To 12 Do
  Begin
    Fkas[Slot].Labels[K] := '';
    Fkas[Slot].Cmds[K] := K;
  End;
End;

{ "Texte,commande" -> libelle et commande de la touche K }
Procedure SetLabel(I, K : LongInt; S : String);
Var P : LongInt;
Begin
  If (K < 1) Or (K > 12) Then Exit;
  P := Pos(',', S);
  If P > 0 Then
  Begin
    Fkas[I].Cmds[K] := SVal(Copy(S, P + 1, 255));
    S := Copy(S, 1, P - 1);
  End;
  Fkas[I].Labels[K] := Copy(Trim(S), 1, 31);
End;

{ Interpreter une definition texte "n=Texte[,cmd]" (lignes ou ;) }
Procedure ParseDef(I, A, N : LongInt);
Var P, C : LongInt; Line, U : String;

  Procedure DoLine;
  Var Q : LongInt;
  Begin
    Line := Trim(Line);
    If Line = '' Then Exit;
    U := UpStr(Line);
    Q := Pos('=', Line);
    If Q = 0 Then Exit;
    If Copy(U, 1, 5) = 'FORM=' Then
    Begin
      U := Trim(Copy(U, 6, 255));
      If U = 'OFF' Then Fkas[I].Form := FKAFORM_OFF
      Else If U = 'LONG' Then Fkas[I].Form := FKAFORM_LONG
      Else Fkas[I].Form := FKAFORM_SHORT;
    End
    Else If Copy(U, 1, 5) = 'KEYS=' Then
    Begin
      If SVal(Copy(U, 6, 255)) > 10 Then Fkas[I].NKeys := 12 Else Fkas[I].NKeys := 10;
    End
    Else
    Begin
      If (Length(U) > 0) And (U[1] = 'F') Then Delete(U, 1, 1);
      SetLabel(I, SVal(Copy(U, 1, Pos('=', U) - 1)), Copy(Line, Q + 1, 255));
    End;
  End;

Begin
  Line := '';
  For P := 0 To N - 1 Do
  Begin
    C := PeekB(A + P);
    If (C = 13) Or (C = 10) Or (C = Ord(';')) Or (C = 0) Then
    Begin
      DoLine;
      Line := '';
    End
    Else If (C <> 26) And (Length(Line) < 250) Then Line := Line + Chr(C);
  End;
  DoLine;
End;

{ ==================================================================== }
{ Fonctions exportees                                                  }
{ ==================================================================== }

{ 64 : initialiser la FKA pour le processus (hab ignore) ; TRUE }
Function FKAInit(Hab : LongInt) : LongInt;
Var I, Pid : LongInt;
Begin
  Pid := KGetCurrentProcessId;
  For I := 0 To 15 Do
    If InitPids[I] = Pid Then
    Begin
      FKAInit := 1;
      Exit;
    End;
  For I := 0 To 15 Do
    If InitPids[I] = 0 Then
    Begin
      InitPids[I] := Pid;
      FKAInit := 1;
      Exit;
    End;
  { table pleine : la plus ancienne entree est remplacee }
  For I := 0 To 14 Do InitPids[I] := InitPids[I + 1];
  InitPids[15] := Pid;
  FKAInit := 1;
End;

{ 65 : details d'affichage ; TRUE si le handle est valide }
Function QueryFKADisplayDetails(Hwnd, PDetails : LongInt) : LongInt;
Var I : LongInt;
Begin
  QueryFKADisplayDetails := 0;
  I := FkaIdx(Hwnd);
  If (I < 0) Or (PDetails = 0) Then Exit;
  PokeL(PDetails, 32);
  PokeL(PDetails + 4, Fkas[I].Form);
  PokeL(PDetails + 8, ScrRows - FormLines(Fkas[I].Form));
  PokeL(PDetails + 12, FormLines(Fkas[I].Form));
  PokeL(PDetails + 16, Fkas[I].NKeys);
  PokeL(PDetails + 20, KeyWidth(I));
  If Fkas[I].Focus Then PokeL(PDetails + 24, 1) Else PokeL(PDetails + 24, 0);
  PokeL(PDetails + 28, Fkas[I].Sel);
  QueryFKADisplayDetails := 1;
End;

{ 69 : fixer la forme ; TRUE }
Function WinSetFKAForm(Hwnd, Form : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinSetFKAForm := 0;
  I := FkaIdx(Hwnd);
  If (I < 0) Or (Form < FKAFORM_OFF) Or (Form > FKAFORM_LONG) Then Exit;
  EraseForm(Fkas[I].Form);
  Fkas[I].Form := Form;
  Paint(I);
  WinSetFKAForm := 1;
End;

{ 70 : forme courante ($FFFFFFFF si le handle est invalide) }
Function WinQueryFKAForm(Hwnd : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := FkaIdx(Hwnd);
  If I < 0 Then WinQueryFKAForm := -1 Else WinQueryFKAForm := Fkas[I].Form;
End;

{ 71 : la FKA recoit le focus (premiere touche choisie si aucune) }
Function WinGotoFKA(Hwnd : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinGotoFKA := 0;
  I := FkaIdx(Hwnd);
  If I < 0 Then Exit;
  If (Fkas[I].Sel < 1) Or (Fkas[I].Sel > Fkas[I].NKeys) Then Fkas[I].Sel := 1;
  Fkas[I].Focus := True;
  Paint(I);
  WinGotoFKA := 1;
End;

{ 72 : le focus revient a l'application (formulaire) }
Function WinGoFromFKA(Hwnd : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinGoFromFKA := 0;
  I := FkaIdx(Hwnd);
  If I < 0 Then Exit;
  Fkas[I].Focus := False;
  Paint(I);
  WinGoFromFKA := 1;
End;

{ 66 : procedure de fenetre }
Function WinFKAWndProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I, Vk, K, R : LongInt;
Begin
  WinFKAWndProc := 0;
  I := FkaIdx(Hwnd);
  If I < 0 Then Exit;
  Case Msg Of
    WM_CREATE, WM_PAINT :
      Paint(I);
    WM_DESTROY :
      Begin
        EraseForm(Fkas[I].Form);
        Fkas[I].Used := False;
        Reserve(0);
      End;
    WM_SETFOCUS :
      If Mp2 <> 0 Then WinGotoFKA(Hwnd) Else WinGoFromFKA(Hwnd);
    WM_CHAR :
      Begin
        If (Mp1 And KC_KEYUP) <> 0 Then Exit;
        Vk := (Mp2 Shr 16) And $FFFF;
        R := 0;
        If (Vk >= VK_F1) And (Vk <= VK_F12) Then
        Begin
          K := Vk - VK_F1 + 1;
          If K <= Fkas[I].NKeys Then R := Fkas[I].Cmds[K];
        End
        Else If Fkas[I].Focus Then
        Begin
          Case Vk Of
            VK_LEFT :
              Begin
                Dec(Fkas[I].Sel);
                If Fkas[I].Sel < 1 Then Fkas[I].Sel := Fkas[I].NKeys;
              End;
            VK_RIGHT :
              Begin
                Inc(Fkas[I].Sel);
                If Fkas[I].Sel > Fkas[I].NKeys Then Fkas[I].Sel := 1;
              End;
            VK_HOME : Fkas[I].Sel := 1;
            VK_END : Fkas[I].Sel := Fkas[I].NKeys;
            VK_ENTER, VK_NEWLINE : R := Fkas[I].Cmds[Fkas[I].Sel];
            VK_ESC : Fkas[I].Focus := False;
          End;
          Paint(I);
        End;
        WinFKAWndProc := R;
      End;
    FKAM_SETFORM :
      WinFKAWndProc := WinSetFKAForm(Hwnd, Mp1);
    FKAM_QUERYFORM :
      WinFKAWndProc := Fkas[I].Form;
    FKAM_SETTEXT :
      If (Mp1 >= 1) And (Mp1 <= Fkas[I].NKeys) Then
      Begin
        Fkas[I].Labels[Mp1] := Copy(GetStr(Mp2), 1, 31);
        Paint(I);
        WinFKAWndProc := 1;
      End;
    FKAM_QUERYTEXT :
      If (Mp1 >= 1) And (Mp1 <= Fkas[I].NKeys) Then
      Begin
        PutStr(Mp2, Fkas[I].Labels[Mp1], 64);
        WinFKAWndProc := Length(Fkas[I].Labels[Mp1]);
      End;
    FKAM_SETCMD :
      If (Mp1 >= 1) And (Mp1 <= Fkas[I].NKeys) Then
      Begin
        Fkas[I].Cmds[Mp1] := Mp2;
        WinFKAWndProc := 1;
      End;
    FKAM_QUERYCMD :
      If (Mp1 >= 1) And (Mp1 <= Fkas[I].NKeys) Then
        WinFKAWndProc := Fkas[I].Cmds[Mp1];
  End;
End;

{ 68 : creer une FKA a partir d'un tableau de libelles (adresses ASCIIZ) }
Function WinCreateFKA(Parent, PLabels, Count, Form : LongInt) : LongInt;
Var I, K : LongInt;
Begin
  WinCreateFKA := 0;
  If (Count < 0) Or (Count > 12) Or (Form < FKAFORM_OFF) Or (Form > FKAFORM_LONG) Then Exit;
  I := NewFka(Parent, Count, Form);
  If I < 0 Then Exit;
  For K := 1 To Count Do
    SetLabel(I, K, GetStr(PeekL(PLabels + (K - 1) * 4)));
  Paint(I);
  WinCreateFKA := HwndBase + I + 1;
End;

{ Lire le fichier de definition FKAnnnn.TXT ; rend le nombre d'octets }
Function LoadDefFile(Id : LongInt) : LongInt;
Var Name, Num : String; H, Act, Got, Dir : LongInt;
Begin
  LoadDefFile := 0;
  Num := IStr(Id);
  While Length(Num) < 4 Do Num := '0' + Num;
  For Dir := 0 To 1 Do
  Begin
    If Dir = 0 Then Name := 'FKA' + Num + '.TXT' Else Name := 'C:\FKA' + Num + '.TXT';
    PutStr(LongInt(@NameBuf), Name, 128);
    If DosOpen(LongInt(@NameBuf), LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) = 0 Then
    Begin
      Got := 0;
      DosRead(H, LongInt(@Buf), SizeOf(Buf), LongInt(@Got));
      DosClose(H);
      LoadDefFile := Got;
      Exit;
    End;
  End;
End;

{ 67 : charger une FKA (ressource RT_FKA du module, sinon fichier) }
Function WinLoadFKA(Parent, HMod, Id : LongInt) : LongInt;
Var I, A, Size, N : LongInt;
Begin
  WinLoadFKA := 0;
  A := 0; Size := 0;
  If (DosGetResource(HMod, RT_FKA, Id, LongInt(@A)) = 0) And
     (DosQueryResourceSize(HMod, RT_FKA, Id, LongInt(@Size)) = 0) Then
    N := Size
  Else
  Begin
    N := LoadDefFile(Id);
    A := LongInt(@Buf);
  End;
  If N <= 0 Then Exit;
  I := NewFka(Parent, 10, FKAFORM_SHORT);
  If I < 0 Then Exit;
  ParseDef(I, A, N);
  Paint(I);
  WinLoadFKA := HwndBase + I + 1;
End;

{ ==================================================================== }
{ Exportations (ordinaux d'origine de FKA.DLL) et initialisation       }
{ ==================================================================== }

exports
  FKAInit Index 64,
  QueryFKADisplayDetails Index 65,
  WinFKAWndProc Name 'WINFKAWNDPROC' Index 66,
  WinLoadFKA Name 'WINLOADFKA' Index 67,
  WinCreateFKA Name 'WINCREATEFKA' Index 68,
  WinSetFKAForm Name 'WINSETFKAFORM' Index 69,
  WinQueryFKAForm Name 'WINQUERYFKAFORM' Index 70,
  WinGotoFKA Name 'WINGOTOFKA' Index 71,
  WinGoFromFKA Name 'WINGOFROMFKA' Index 72;

Var
  J : LongInt;

BEGIN
  For J := 0 To MaxFka - 1 Do Fkas[J].Used := False;
  For J := 0 To 15 Do InitPids[J] := 0;
END.
