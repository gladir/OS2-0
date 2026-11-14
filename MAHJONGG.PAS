{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: MAHJONGG - patience Mahjongg (jeu de tuiles) pour le
                Presentation Manager d'OS/2-0.
}

Program MAHJONGG;

{$R-,S-,I-}

{ Compilation : OS2PC MAHJONGG.PAS   (produit MAHJONGG.EXE)

  Mahjongg Solitaire (la patience traditionnelle aux tuiles de mah-jong),
  du dossier Jeux du bureau (Systeme OS/2, Jeux). 144 tuiles empilees
  en cinq etages selon la disposition classique de la tortue : 4 tuiles de
  chacune des 34 figures (cercles, bambous et caracteres de 1 a 9, quatre
  vents E, S, O, N, trois dragons rouge, vert et blanc) et 8 tuiles
  uniques (4 fleurs, 4 saisons ; deux fleurs ou deux saisons forment une
  paire).

  But : retirer toutes les tuiles, par paires de tuiles semblables. Une
  tuile est libre si aucune tuile ne la recouvre et si son cote gauche
  ou son cote droit est degage. Chaque donne est faisable : elle est
  construite en retirant des paires d'un plateau plein.

  Souris : cliquer une tuile libre (elle s'eclaire), puis sa pareille.
  Clavier : F2 nouvelle partie, Ctrl+Z annuler, I indice, F1 regles.
  Parametre : /SEED:n (donne reproductible, pour les essais). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MB_OK = 0; MB_INFORMATION = $30; MB_MOVEABLE = $4000;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_KEYUP = $40; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKPINK = 11; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  CM_NEW = 101; CM_RESTART = 102; CM_UNDO = 103; CM_HINT = 104; CM_QUIT = 105; CM_RULES = 301; CM_ABOUT = 302;
  NT = 144;                     { tuiles }
  TW = 36; TH = 44;             { face d'une tuile (pels) }
  Lift = 4;                     { decalage d'un etage }
  { figures : 0..8 cercles, 9..17 bambous, 18..26 caracteres, 27..30 vents,
    31..33 dragons, 34..37 fleurs, 38..41 saisons }
  K_BAMBOO = 9; K_CHAR = 18; K_WIND = 27; K_DRAGON = 31; K_FLOWER = 34; K_SEASON = 38;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH : LongInt;
  { plateau : position en demi-tuiles (X2, Y2, ligne 0 en haut), etage Z,
    figure, presence ; ordre de dessin }
  TX2, TY2, TZ, Kind, Alive, Order : Array[0..NT - 1] Of LongInt;
  NPos : LongInt;
  { tuiles retirees (par paires, pour Annuler) }
  Removed : Array[0..NT - 1] Of LongInt;
  NRem : LongInt;
  Sel, HintA, HintB : LongInt;
  Seed, GameNo : LongInt;
  OX, OY : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..511] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  Pairs : Array[0..NT - 1] Of LongInt;       { figures a placer, par paires }
  Free : Array[0..NT - 1] Of LongInt;

{ --- PMWIN.DLL, PMGPI.DLL, DOSCALLS.DLL --- }
Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Procedure WrB(A, V : LongInt);
Type PByte = ^Byte;
Var Q : PByte;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@NameZ), S);
  Z := LongInt(@NameZ);
End;

Function Z2(S : String) : LongInt;
Begin
  PutZ(LongInt(@NameZ2), S);
  Z2 := LongInt(@NameZ2);
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function Lo16(V : LongInt) : LongInt;
Begin
  Lo16 := V And $FFFF;
End;

Function Hi16(V : LongInt) : LongInt;
Begin
  Hi16 := (V Shr 16) And $FFFF;
End;

Function S16(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V >= $8000 Then V := V - $10000;
  S16 := V;
End;

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
End;

Function AbsI(A : LongInt) : LongInt;
Begin
  If A < 0 Then AbsI := -A Else AbsI := A;
End;

Function Rnd(N : LongInt) : LongInt;
Begin
  Seed := (Seed * 1103515245 + 12345) And $7FFFFFFF;
  Rnd := (Seed Shr 8) Mod N;
End;

Procedure ShowMsg(Text, Cap : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure GBox(Hps, X1, Y1, X2, Y2, C, Fl, R : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiBox(Hps, Fl, LongInt(@P), R, R);
End;

Procedure GLn(Hps, X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiLine(Hps, LongInt(@P));
End;

{ disque de centre (X, Y) et de rayon R }
Procedure Disc(Hps, X, Y, R, C : LongInt);
Begin
  GBox(Hps, X - R, Y - R, X + R, Y + R, C, DRO_FILL, 2 * R);
End;

Procedure TextXY(Hps, X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := Y; Rc[2] := X + Length(S) * 8; Rc[3] := Y + 16;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

Procedure MB(V : LongInt);
Begin
  MenuT[MenuLen] := V And 255;
  Inc(MenuLen);
End;

Procedure MW(V : LongInt);
Begin
  MB(V And 255); MB((V Shr 8) And 255);
End;

Function MenuOpen : LongInt;
Begin
  MenuOpen := MenuLen;
  MW(0); MW(0); MW(0);
End;

Procedure MenuClose(H, Count : LongInt);
Begin
  WrW(LongInt(@MenuT) + H, MenuLen - H);
  WrW(LongInt(@MenuT) + H + 4, Count);
End;

Procedure MItem(Style, Attr, Id : LongInt; S : String);
Var K : LongInt;
Begin
  MW(Style); MW(Attr); MW(Id);
  If (Style And MIS_SEPARATOR) = 0 Then
  Begin
    For K := 1 To Length(S) Do MB(Ord(S[K]));
    MB(0);
  End;
End;

{ ==================================================================== }
{ Plateau : la tortue                                                   }
{ ==================================================================== }

Procedure AddPos(X2, Y2, Zz : LongInt);
Begin
  TX2[NPos] := X2; TY2[NPos] := Y2; TZ[NPos] := Zz;
  Inc(NPos);
End;

{ une rangee de tuiles (en tuiles entieres) de X1 a X2 a la ligne Y }
Procedure AddRow(X1, X2, Y, Zz : LongInt);
Var X : LongInt;
Begin
  For X := X1 To X2 Do AddPos(X * 2, Y * 2, Zz);
End;

Procedure BuildLayout;
Var Y, K, J, T : LongInt;
Begin
  NPos := 0;
  { etage 0 : 84 tuiles et les trois tuiles des extremites }
  AddRow(1, 12, 0, 0);
  AddRow(3, 10, 1, 0);
  AddRow(2, 11, 2, 0);
  AddRow(1, 12, 3, 0);
  AddRow(1, 12, 4, 0);
  AddRow(2, 11, 5, 0);
  AddRow(3, 10, 6, 0);
  AddRow(1, 12, 7, 0);
  AddPos(0, 7, 0);
  AddPos(26, 7, 0);
  AddPos(28, 7, 0);
  { etage 1 : 6 x 6 ; etage 2 : 4 x 4 ; etage 3 : 2 x 2 ; sommet }
  For Y := 1 To 6 Do AddRow(4, 9, Y, 1);
  For Y := 2 To 5 Do AddRow(5, 8, Y, 2);
  For Y := 3 To 4 Do AddRow(6, 7, Y, 3);
  AddPos(13, 7, 4);
  { ordre de dessin : etages croissants, puis lignes du haut vers le bas,
    puis de droite a gauche (le flanc d'une tuile est a sa gauche et en
    bas : la tuile voisine de gauche le recouvre) }
  For K := 0 To NT - 1 Do Order[K] := K;
  For K := 1 To NT - 1 Do
  Begin
    T := Order[K]; J := K - 1;
    While (J >= 0) And ((TZ[Order[J]] * 10000 + TY2[Order[J]] * 100 + (40 - TX2[Order[J]])) >
                        (TZ[T] * 10000 + TY2[T] * 100 + (40 - TX2[T]))) Do
    Begin
      Order[J + 1] := Order[J];
      Dec(J);
    End;
    Order[J + 1] := T;
  End;
End;

{ la tuile I est-elle libre ? }
Function IsFree(I : LongInt) : Boolean;
Var K : LongInt; Left, Right : Boolean;
Begin
  IsFree := False;
  Left := False; Right := False;
  For K := 0 To NT - 1 Do
    If (Alive[K] <> 0) And (K <> I) Then
    Begin
      If (TZ[K] = TZ[I] + 1) And (AbsI(TX2[K] - TX2[I]) < 2) And (AbsI(TY2[K] - TY2[I]) < 2) Then Exit;
      If (TZ[K] = TZ[I]) And (AbsI(TY2[K] - TY2[I]) < 2) Then
      Begin
        If TX2[K] = TX2[I] - 2 Then Left := True;
        If TX2[K] = TX2[I] + 2 Then Right := True;
      End;
    End;
  IsFree := Not (Left And Right);
End;

Function Match(A, B : LongInt) : Boolean;
Begin
  If (Kind[A] >= K_SEASON) Then Match := Kind[B] >= K_SEASON
  Else If (Kind[A] >= K_FLOWER) Then Match := (Kind[B] >= K_FLOWER) And (Kind[B] < K_SEASON)
  Else Match := Kind[A] = Kind[B];
End;

{ donne faisable : on vide un plateau plein en retirant des paires de
  tuiles libres, auxquelles on donne les figures dans cet ordre }
Procedure Deal;
Var K, J, T, N, A, B, Tries : LongInt; Ok : Boolean;
Begin
  { 72 paires : 2 de chaque figure ordinaire, fleurs et saisons }
  N := 0;
  For K := 0 To K_FLOWER - 1 Do
  Begin
    Pairs[N] := K; Pairs[N + 1] := K; Pairs[N + 2] := K; Pairs[N + 3] := K;
    N := N + 4;
  End;
  For K := K_FLOWER To K_SEASON + 3 Do
  Begin
    Pairs[N] := K;
    Inc(N);
  End;
  { melange des paires (les fleurs 34-35, 36-37 et les saisons 38-39,
    40-41 restent ensemble) }
  For K := 71 DownTo 1 Do
  Begin
    J := Rnd(K + 1);
    T := Pairs[K * 2]; Pairs[K * 2] := Pairs[J * 2]; Pairs[J * 2] := T;
    T := Pairs[K * 2 + 1]; Pairs[K * 2 + 1] := Pairs[J * 2 + 1]; Pairs[J * 2 + 1] := T;
  End;
  Tries := 0;
  Repeat
    Inc(Tries);
    For K := 0 To NT - 1 Do Alive[K] := 1;
    Ok := True;
    K := 0;
    While Ok And (K < 72) Do
    Begin
      N := 0;
      For J := 0 To NT - 1 Do
        If (Alive[J] <> 0) And IsFree(J) Then
        Begin
          Free[N] := J;
          Inc(N);
        End;
      If N < 2 Then Ok := False
      Else
      Begin
        A := Free[Rnd(N)];
        Repeat
          B := Free[Rnd(N)];
        Until B <> A;
        Kind[A] := Pairs[K * 2]; Kind[B] := Pairs[K * 2 + 1];
        Alive[A] := 0; Alive[B] := 0;
        { deux tuiles libres en meme temps : la seconde ne doit pas
          devenir libre seulement apres le retrait de la premiere }
        Inc(K);
      End;
    End;
  Until Ok Or (Tries > 200);
  For K := 0 To NT - 1 Do Alive[K] := 1;
  NRem := 0; Sel := -1; HintA := -1; HintB := -1;
End;

Function Remaining : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To NT - 1 Do If Alive[K] <> 0 Then Inc(N);
  Remaining := N;
End;

{ paires jouables ; la premiere dans HintA, HintB }
Function CountMoves : LongInt;
Var K, J, N, C : LongInt;
Begin
  N := 0;
  For K := 0 To NT - 1 Do
    If (Alive[K] <> 0) And IsFree(K) Then
    Begin
      Free[N] := K;
      Inc(N);
    End;
  C := 0; HintA := -1; HintB := -1;
  For K := 0 To N - 2 Do
    For J := K + 1 To N - 1 Do
      If Match(Free[K], Free[J]) Then
      Begin
        If C = 0 Then
        Begin
          HintA := Free[K]; HintB := Free[J];
        End;
        Inc(C);
      End;
  CountMoves := C;
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

{ coin bas gauche de la face de la tuile I }
Procedure TileXY(I : LongInt; Var X, Y : LongInt);
Begin
  X := OX + TX2[I] * (TW Div 2) + TZ[I] * Lift;
  Y := OY + (14 - TY2[I]) * (TH Div 2) + TZ[I] * Lift;
End;

{ figure de la grille 3 x 3 (0 en haut a gauche ... 8 en bas a droite) }
Function GridOf(N : LongInt) : String;
Begin
  Case N Of
    1 : GridOf := '4';
    2 : GridOf := '17';
    3 : GridOf := '048';
    4 : GridOf := '0268';
    5 : GridOf := '02468';
    6 : GridOf := '023568';
    7 : GridOf := '0243568';
    8 : GridOf := '01235678';
  Else
    GridOf := '012345678';
  End;
End;

Procedure GridXY(X, Y, Cell : LongInt; Var Px, Py : LongInt);
Begin
  Px := X + 8 + (Cell Mod 3) * 10;
  Py := Y + TH - 10 - (Cell Div 3) * 12;
End;

Procedure DrawFace(Hps, X, Y, K : LongInt);
Var G : String; J, Px, Py, N, C : LongInt;
Begin
  If K < K_BAMBOO Then
  Begin
    { cercles }
    G := GridOf(K + 1);
    For J := 1 To Length(G) Do
    Begin
      GridXY(X, Y, Ord(G[J]) - 48, Px, Py);
      If K = 0 Then
      Begin
        Disc(Hps, X + TW Div 2, Y + TH Div 2, 13, CLR_DARKBLUE);
        Disc(Hps, X + TW Div 2, Y + TH Div 2, 9, CLR_RED);
        Disc(Hps, X + TW Div 2, Y + TH Div 2, 4, CLR_DARKGREEN);
      End
      Else
      Begin
        Case J Mod 3 Of
          0 : C := CLR_DARKBLUE;
          1 : C := CLR_DARKGREEN;
        Else
          C := CLR_RED;
        End;
        Disc(Hps, Px, Py, 4, C);
      End;
    End;
  End
  Else If K < K_CHAR Then
  Begin
    { bambous }
    N := K - K_BAMBOO + 1;
    If N = 1 Then
    Begin
      { un bambou : une tige et ses noeuds }
      GBox(Hps, X + TW Div 2 - 3, Y + 6, X + TW Div 2 + 3, Y + TH - 7, CLR_DARKGREEN, DRO_FILL, 4);
      GLn(Hps, X + TW Div 2 - 4, Y + 16, X + TW Div 2 + 4, Y + 16, CLR_WHITE);
      GLn(Hps, X + TW Div 2 - 4, Y + 28, X + TW Div 2 + 4, Y + 28, CLR_WHITE);
      Disc(Hps, X + TW Div 2, Y + TH - 8, 4, CLR_RED);
    End
    Else
    Begin
      G := GridOf(N);
      For J := 1 To Length(G) Do
      Begin
        GridXY(X, Y, Ord(G[J]) - 48, Px, Py);
        If (N >= 5) And ((Ord(G[J]) - 48) = 4) Then C := CLR_RED Else C := CLR_DARKGREEN;
        GBox(Hps, Px - 2, Py - 5, Px + 2, Py + 5, C, DRO_FILL, 2);
        GLn(Hps, Px - 2, Py, Px + 2, Py, CLR_WHITE);
      End;
    End;
  End
  Else If K < K_WIND Then
  Begin
    { caracteres : le nombre, et dessous un signe rouge }
    N := K - K_CHAR + 1;
    TextXY(Hps, X + TW Div 2 - 4, Y + TH - 20, IStr(N), CLR_DARKBLUE, CLR_WHITE);
    GLn(Hps, X + 9, Y + 20, X + TW - 10, Y + 20, CLR_RED);
    GLn(Hps, X + 11, Y + 15, X + TW - 12, Y + 15, CLR_RED);
    GLn(Hps, X + TW Div 2, Y + 22, X + TW Div 2, Y + 6, CLR_RED);
    GLn(Hps, X + TW Div 2, Y + 13, X + 9, Y + 5, CLR_RED);
    GLn(Hps, X + TW Div 2, Y + 13, X + TW - 9, Y + 5, CLR_RED);
  End
  Else If K < K_DRAGON Then
  Begin
    { vents : Est, Sud, Ouest, Nord }
    Case K - K_WIND Of
      0 : G := 'E';
      1 : G := 'S';
      2 : G := 'O';
    Else
      G := 'N';
    End;
    GBox(Hps, X + 9, Y + 9, X + TW - 10, Y + TH - 10, CLR_DARKBLUE, DRO_OUTLINE, 6);
    TextXY(Hps, X + TW Div 2 - 4, Y + TH Div 2 - 8, G, CLR_DARKBLUE, CLR_WHITE);
  End
  Else If K < K_FLOWER Then
  Begin
    Case K - K_DRAGON Of
      0 :
        Begin
          { dragon rouge }
          GBox(Hps, X + 8, Y + 16, X + TW - 9, Y + 30, CLR_RED, DRO_OUTLINE, 0);
          GBox(Hps, X + 9, Y + 17, X + TW - 10, Y + 29, CLR_RED, DRO_OUTLINE, 0);
          GBox(Hps, X + TW Div 2 - 1, Y + 6, X + TW Div 2 + 1, Y + TH - 6, CLR_RED, DRO_FILL, 0);
        End;
      1 :
        Begin
          { dragon vert }
          GBox(Hps, X + 9, Y + 26, X + 16, Y + 36, CLR_DARKGREEN, DRO_FILL, 0);
          GBox(Hps, X + TW - 17, Y + 26, X + TW - 10, Y + 36, CLR_DARKGREEN, DRO_FILL, 0);
          GLn(Hps, X + 8, Y + 22, X + TW - 9, Y + 22, CLR_DARKGREEN);
          GBox(Hps, X + TW Div 2 - 1, Y + 6, X + TW Div 2 + 1, Y + 22, CLR_DARKGREEN, DRO_FILL, 0);
          GLn(Hps, X + TW Div 2, Y + 16, X + 9, Y + 7, CLR_DARKGREEN);
          GLn(Hps, X + TW Div 2, Y + 16, X + TW - 10, Y + 7, CLR_DARKGREEN);
        End;
    Else
      Begin
        { dragon blanc : double cadre bleu }
        GBox(Hps, X + 6, Y + 6, X + TW - 7, Y + TH - 7, CLR_DARKBLUE, DRO_OUTLINE, 0);
        GBox(Hps, X + 9, Y + 9, X + TW - 10, Y + TH - 10, CLR_BLUE, DRO_OUTLINE, 0);
      End;
    End;
  End
  Else If K < K_SEASON Then
  Begin
    { fleurs : petales autour d'un coeur jaune, et le numero }
    Case K - K_FLOWER Of
      0 : C := CLR_RED;
      1 : C := CLR_PINK;
      2 : C := CLR_BLUE;
    Else
      C := CLR_DARKPINK;
    End;
    Px := X + TW Div 2; Py := Y + TH Div 2 + 2;
    GLn(Hps, Px, Py, Px, Y + 5, CLR_DARKGREEN);
    Disc(Hps, Px - 6, Py, 5, C); Disc(Hps, Px + 6, Py, 5, C);
    Disc(Hps, Px, Py - 6, 5, C); Disc(Hps, Px, Py + 6, 5, C);
    Disc(Hps, Px, Py, 3, CLR_YELLOW);
    TextXY(Hps, X + 3, Y + TH - 18, IStr(K - K_FLOWER + 1), CLR_DARKRED, CLR_WHITE);
  End
  Else
  Begin
    { saisons : un arbre de la couleur de la saison, et le numero }
    Case K - K_SEASON Of
      0 : C := CLR_GREEN;
      1 : C := CLR_DARKGREEN;
      2 : C := CLR_BROWN;
    Else
      C := CLR_CYAN;
    End;
    Px := X + TW Div 2;
    GBox(Hps, Px - 2, Y + 5, Px + 2, Y + 18, CLR_BROWN, DRO_FILL, 0);
    Disc(Hps, Px, Y + 24, 10, C);
    TextXY(Hps, X + 3, Y + TH - 18, IStr(K - K_SEASON + 1), CLR_DARKBLUE, CLR_WHITE);
  End;
End;

Procedure DrawTile(Hps, I : LongInt);
Var X, Y, Bg : LongInt;
Begin
  TileXY(I, X, Y);
  { flanc (epaisseur) a gauche et en bas }
  GBox(Hps, X - Lift, Y - Lift, X + TW - 1 - Lift, Y + TH - 1 - Lift, CLR_DARKGRAY, DRO_FILL, 4);
  GBox(Hps, X - Lift, Y - Lift, X + TW - 1 - Lift, Y + TH - 1 - Lift, CLR_BLACK, DRO_OUTLINE, 4);
  If I = Sel Then Bg := CLR_YELLOW
  Else If (I = HintA) Or (I = HintB) Then Bg := CLR_CYAN
  Else Bg := CLR_WHITE;
  GBox(Hps, X, Y, X + TW - 1, Y + TH - 1, Bg, DRO_FILL, 4);
  GBox(Hps, X, Y, X + TW - 1, Y + TH - 1, CLR_BLACK, DRO_OUTLINE, 4);
  If Bg = CLR_WHITE Then DrawFace(Hps, X, Y, Kind[I])
  Else
  Begin
    { face eclairee : on dessine la figure puis on garde le cadre colore }
    GBox(Hps, X + 2, Y + 2, X + TW - 3, Y + TH - 3, CLR_WHITE, DRO_FILL, 2);
    DrawFace(Hps, X, Y, Kind[I]);
    GBox(Hps, X + 1, Y + 1, X + TW - 2, Y + TH - 2, Bg, DRO_OUTLINE, 3);
    GBox(Hps, X + 2, Y + 2, X + TW - 3, Y + TH - 3, Bg, DRO_OUTLINE, 2);
    GBox(Hps, X + 3, Y + 3, X + TW - 4, Y + TH - 4, Bg, DRO_OUTLINE, 0);
  End;
End;

Procedure PaintAll(H : LongInt);
Var Hps, K, N, M : LongInt; Rc : Array[0..3] Of LongInt; S : String;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  If Hps = 0 Then Exit;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_DARKCYAN);
  OX := (CW - 15 * TW) Div 2 + Lift;
  OY := 26 + Lift;
  For K := 0 To NT - 1 Do
    If Alive[Order[K]] <> 0 Then DrawTile(Hps, Order[K]);
  N := Remaining;
  M := HintA; K := HintB;
  S := 'Tuiles : ' + IStr(N) + '    Paires jouables : ' + IStr(CountMoves) + '    Partie n' + Chr(248) + ' ' +
       IStr(GameNo);
  HintA := M; HintB := K;
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CW; Rc[3] := 20;
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
  TextXY(Hps, 8, 2, S, CLR_BLACK, CLR_PALEGRAY);
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 1);
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure NewGame;
Begin
  GameNo := Seed Mod 100000;
  Seed := GameNo;
  Deal;
  Redraw;
End;

Procedure Restart;
Var K : LongInt;
Begin
  For K := 0 To NT - 1 Do Alive[K] := 1;
  NRem := 0; Sel := -1; HintA := -1; HintB := -1;
  Redraw;
End;

Procedure CheckEnd;
Var M : LongInt;
Begin
  If Remaining = 0 Then
  Begin
    Redraw;
    ShowMsg('Bravo ! Toutes les tuiles sont retirees.', 'Mahjongg');
    Exit;
  End;
  M := CountMoves;
  HintA := -1; HintB := -1;
  If M = 0 Then
  Begin
    Redraw;
    ShowMsg('Plus aucune paire jouable (' + IStr(Remaining) + ' tuiles restent). Annulez des coups (Ctrl+Z) ou ' +
            'recommencez la partie.', 'Mahjongg');
  End;
End;

Function HitTile(X, Y : LongInt) : LongInt;
Var K, I, Tx, Ty : LongInt;
Begin
  HitTile := -1;
  For K := NT - 1 DownTo 0 Do
  Begin
    I := Order[K];
    If Alive[I] <> 0 Then
    Begin
      TileXY(I, Tx, Ty);
      If (X >= Tx - Lift) And (X < Tx + TW) And (Y >= Ty - Lift) And (Y < Ty + TH) Then
      Begin
        HitTile := I;
        Exit;
      End;
    End;
  End;
End;

Procedure Click(X, Y : LongInt);
Var I : LongInt;
Begin
  I := HitTile(X, Y);
  HintA := -1; HintB := -1;
  If (I < 0) Or Not IsFree(I) Then
  Begin
    Sel := -1;
    Redraw;
    Exit;
  End;
  If Sel = I Then Sel := -1
  Else If (Sel >= 0) And Match(Sel, I) Then
  Begin
    Alive[Sel] := 0; Alive[I] := 0;
    Removed[NRem] := Sel; Removed[NRem + 1] := I;
    NRem := NRem + 2;
    Sel := -1;
    Redraw;
    CheckEnd;
    Exit;
  End
  Else Sel := I;
  Redraw;
End;

Procedure UndoPair;
Begin
  If NRem < 2 Then Exit;
  NRem := NRem - 2;
  Alive[Removed[NRem]] := 1; Alive[Removed[NRem + 1]] := 1;
  Sel := -1; HintA := -1; HintB := -1;
  Redraw;
End;

Procedure Hint;
Begin
  Sel := -1;
  If CountMoves = 0 Then
  Begin
    Redraw;
    ShowMsg('Aucune paire jouable.', 'Mahjongg');
  End
  Else Redraw;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW :
      Begin
        Seed := Seed + 7919;
        NewGame;
      End;
    CM_RESTART : Restart;
    CM_UNDO : UndoPair;
    CM_HINT : Hint;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES : ShowMsg('Retirez les tuiles par paires semblables. Une tuile est libre si rien ne la recouvre et si ' +
                       'son cote gauche ou droit est degage. Deux fleurs, ou deux saisons, forment une paire. ' +
                       'I : indice, Ctrl+Z : annuler, F2 : nouvelle partie.', 'Mahjongg - Regles');
    CM_ABOUT : ShowMsg('Mahjongg pour OS/2-0 (Presentation Manager) : 144 tuiles, disposition de la tortue, ' +
                       'donnes toujours faisables. Programme ecrit en Pascal et compile par OS2PC.',
                       'A propos de Mahjongg');
  End;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; C : LongInt;
Begin
  MainProc := 0;
  Case Msg Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
      End;
    WM_PAINT : PaintAll(H);
    WM_BUTTON1DOWN :
      Begin
        Click(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := 1;
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CHAR :
      If (Lo16(Mp1) And KC_KEYUP) = 0 Then
      Begin
        C := Lo16(Mp2);
        If ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And (Hi16(Mp2) = VK_F2) Then Command(CM_NEW)
        Else If ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And (Hi16(Mp2) = VK_F1) Then Command(CM_RULES)
        Else If ((Lo16(Mp1) And KC_CTRL) <> 0) And ((C = 26) Or (C = Ord('z')) Or (C = Ord('Z'))) Then
          Command(CM_UNDO)
        Else If ((Lo16(Mp1) And KC_CHAR) <> 0) And ((C = Ord('i')) Or (C = Ord('I'))) Then Command(CM_HINT)
        Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Var
  Fl, H0, H1, H2, Sw, Sh, M, K, E : LongInt;
  Dt : Array[0..15] Of Byte;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
  End;
  Sel := -1; HintA := -1; HintB := -1; NRem := 0;
  BuildLayout;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  Dummy := WinRegisterClass(Hab, Z('MAHJONGG'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('MAHJONGG'), Z2('Mahjongg Solitaire'), 0, 0, 0,
                              LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_RESTART, '~Recommencer la partie');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_TEXT, 0, CM_HINT, '~Indice' + Chr(9) + 'I');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~Regles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Mahjongg');
  MenuClose(H2, 2);
  MenuClose(H0, 2);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, 0, MaxI(0, Sh - 470), MinI(Sw, 640), MinI(Sh, 470),
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  NewGame;
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
