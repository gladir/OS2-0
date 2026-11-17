{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: HEX2048 - jeu de 2048 sur une grille hexagonale pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program HEX2048;

{$R-,S-,I-}

{ Compilation : OS2PC HEX2048.PAS   (produit HEX2048.EXE)

  Portage vers OS/2-0 du prototype HEX2048.PAS du depot 7iles (Turbo
  Pascal et BGI, touches Q W E A S D) : fenetre de Presentation Manager
  avec menus, souris, panneau du pointage, rose des directions, barre
  d'etat et apparence d'OS/2.

  But : en faisant glisser toutes les tuiles dans une des six directions
  de la grille hexagonale (19 cases, 3-4-5-4-3), reunir deux tuiles de
  meme valeur pour qu'elles fusionnent (2 + 2 = 4, 4 + 4 = 8...) et
  atteindre la tuile 2048. Chaque glissement ajoute une tuile (2, parfois
  4) ; la partie finit quand plus rien ne peut bouger. Le pointage
  augmente de la valeur de chaque fusion.

  Clavier : Q (haut gauche), W (haut), E (haut droite), A (bas gauche),
  S (bas), D (bas droite), comme le prototype ; aussi 7 8 9 1 2 3 du pave
  numerique, Debut, Pg prec, Fin, Pg suiv et les fleches haut et bas.
  Ctrl+Z (annuler le dernier glissement), F2 ou R (nouvelle partie), F1
  (regles). Souris : cliquer sur le plateau du cote ou glisser les tuiles,
  ou sur la rose des directions.
  Parametres : /SEED:n (hasard reproductible, pour les essais) ; /AUTO
  (l'ordinateur joue seul jusqu'a la fin : demonstration et essais). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14; VK_UP = $16; VK_DOWN = $18;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKPINK = 11; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_UNDO = 102; CM_QUIT = 104;
  CM_RULES = 301; CM_ABOUT = 302;
  NC = 19;                          { cases de la grille }
  { disposition (zone client, Y vers le bas) }
  HR = 36;                          { rayon d'un hexagone (centre - sommet) }
  HH = 31;                          { demi-hauteur (rayon * racine de 3 / 2) }
  GXLeft = 10; GYTop = 12;          { cadre du plateau (320 x 342) }
  BX = 170; BY = 183;               { centre du plateau }
  PnX = 346; PW = 180;
  PadX = 436; PadY = 196;           { centre de la rose des directions }
  CWant = 536; CHWant = 386;
  { directions : 0 haut gauche (Q), 1 haut (W), 2 haut droite (E),
    3 bas gauche (A), 4 bas (S), 5 bas droite (D) }
  DQ : Array[0..5] Of LongInt = (-1, 0, 1, -1, 0, 1);
  DR : Array[0..5] Of LongInt = (0, -1, -1, 1, 1, 0);

Type
  TGrid = Array[0..NC - 1] Of LongInt;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  CQ, CR : Array[0..NC - 1] Of LongInt;  { coordonnees axiales des cases }
  V, Shown, UndoV : TGrid;
  Score, Best, UndoScore, CanUndo, Over, Won, Moves, Seed, AutoAll, PopC, Flash : LongInt;
  LScore, LBest : LongInt;
  Msg, LMsg : String;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;    { police 8 x 16 du VGA (textes agrandis) }
  FontH : LongInt;
  Qmsg : Array[0..7] Of LongInt;


{ --- PMWIN.DLL, PMGPI.DLL, VIOCALLS.DLL, DOSCALLS.DLL --- }
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
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function VioGetFont(PInfo, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetFont';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Type
  PByte = ^Byte;

Procedure WrB(A, V : LongInt);
Var Q : PByte;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Function RdB(A : LongInt) : LongInt;
Var Q : PByte;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Function RdL(A : LongInt) : LongInt;
Begin
  RdL := RdB(A) Or (RdB(A + 1) Shl 8) Or (RdB(A + 2) Shl 16) Or (RdB(A + 3) Shl 24);
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

Function Rnd(N : LongInt) : LongInt;
Begin
  Seed := (Seed * 1103515245 + 12345) And $7FFFFFFF;
  Rnd := (Seed Shr 8) Mod N;
End;

Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

{ ==================================================================== }
{ Grille hexagonale (coordonnees axiales q, r ; |q|, |r|, |q+r| <= 2)   }
{ ==================================================================== }

Procedure InitCells;
Var Q, R, N : LongInt;
Begin
  N := 0;
  For Q := -2 To 2 Do
    For R := -2 To 2 Do
      If Abs(Q + R) <= 2 Then
      Begin
        CQ[N] := Q; CR[N] := R;
        Inc(N);
      End;
End;

Function CellAt(Q, R : LongInt) : LongInt;
Var K : LongInt;
Begin
  CellAt := -1;
  For K := 0 To NC - 1 Do
    If (CQ[K] = Q) And (CR[K] = R) Then CellAt := K;
End;

Function Neighbor(K, D : LongInt) : LongInt;
Begin
  Neighbor := CellAt(CQ[K] + DQ[D], CR[K] + DR[D]);
End;

Function CenterX(K : LongInt) : LongInt;
Begin
  CenterX := BX + CQ[K] * 54;
End;

Function CenterY(K : LongInt) : LongInt;
Begin
  CenterY := BY + (2 * CR[K] + CQ[K]) * HH;
End;

Function Empties : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To NC - 1 Do If V[K] = 0 Then Inc(N);
  Empties := N;
End;

{ nouvelle tuile (2, ou 4 une fois sur dix) dans une case vide au hasard }
Procedure AddTile;
Var K, N, P : LongInt;
Begin
  N := Empties;
  If N = 0 Then Exit;
  P := Rnd(N);
  For K := 0 To NC - 1 Do
    If V[K] = 0 Then
    Begin
      If P = 0 Then
      Begin
        If Rnd(10) = 0 Then V[K] := 4 Else V[K] := 2;
        PopC := K;
      End;
      Dec(P);
    End;
End;

Function CanMove : Boolean;
Var K, D, N : LongInt;
Begin
  CanMove := True;
  For K := 0 To NC - 1 Do
  Begin
    If V[K] = 0 Then Exit;
    For D := 0 To 5 Do
    Begin
      N := Neighbor(K, D);
      If N >= 0 Then If V[N] = V[K] Then Exit;
    End;
  End;
  CanMove := False;
End;

Function MaxTile : LongInt;
Var K, M : LongInt;
Begin
  M := 0;
  For K := 0 To NC - 1 Do If V[K] > M Then M := V[K];
  MaxTile := M;
End;

{ glisse toutes les tuiles dans la direction D (regles du 2048 : chaque
  tuile ne fusionne qu'une fois par glissement) ; Gain = points gagnes }
Function Slide(Var G : TGrid; D : LongInt; Var Gain : LongInt) : Boolean;
Var K, C, N, I, J, Last : LongInt; L, W : Array[0..4] Of LongInt; Moved : Boolean;
Begin
  Moved := False; Gain := 0;
  For K := 0 To NC - 1 Do
    If Neighbor(K, D) < 0 Then
    Begin
      { K est au bout de la ligne : on la parcourt a reculons }
      N := 0; C := K;
      While C >= 0 Do
      Begin
        L[N] := C; Inc(N);
        C := Neighbor(C, 5 - D);
      End;
      J := 0; Last := 0;
      For I := 0 To 4 Do W[I] := 0;
      For I := 0 To N - 1 Do
        If G[L[I]] <> 0 Then
        Begin
          If (Last <> 0) And (G[L[I]] = Last) Then
          Begin
            W[J - 1] := Last * 2;
            Gain := Gain + Last * 2;
            Last := 0;
          End
          Else
          Begin
            W[J] := G[L[I]]; Last := G[L[I]];
            Inc(J);
          End;
        End;
      For I := 0 To N - 1 Do
      Begin
        If G[L[I]] <> W[I] Then Moved := True;
        G[L[I]] := W[I];
      End;
    End;
  Slide := Moved;
End;

{ ==================================================================== }
{ Dessin (Y vers le bas)                                                }
{ ==================================================================== }

{ ==================================================================== }

Procedure FBar(X1, Y1, X2, Y2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  Rc[0] := X1; Rc[1] := CH - 1 - Y2; Rc[2] := X2 + 1; Rc[3] := CH - Y1;
  Dummy := WinFillRect(Hps, LongInt(@Rc), C);
End;

Procedure Edge(X1, Y1, X2, Y2, Lt, Dk : LongInt);
Begin
  FBar(X1, Y1, X2, Y1, Lt); FBar(X1, Y1, X1, Y2, Lt);
  FBar(X1, Y2, X2, Y2, Dk); FBar(X2, Y1, X2, Y2, Dk);
End;

Procedure OutTxt(X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := CH - Y - 16; Rc[2] := X + Length(S) * 8; Rc[3] := CH - Y;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ texte agrandi deux fois (police du VGA) }
Procedure BigText(X, Y : LongInt; S : String; C, Bg : LongInt);
Var I, R, K, B, Run : LongInt;
Begin
  If FontH = 0 Then
  Begin
    OutTxt(X, Y + 8, S, C, Bg);
    Exit;
  End;
  For I := 1 To Length(S) Do
    For R := 0 To FontH - 1 Do
    Begin
      B := Font[Ord(S[I]) * FontH + R];
      K := 0;
      While K < 8 Do
        If (B And ($80 Shr K)) <> 0 Then
        Begin
          Run := K;
          While (K < 8) And ((B And ($80 Shr K)) <> 0) Do Inc(K);
          FBar(X + (I - 1) * 16 + Run * 2, Y + R * 2, X + (I - 1) * 16 + K * 2 - 1, Y + R * 2 + 1, C);
        End
        Else Inc(K);
    End;
End;

{ disque plein de rayon R centre en (X, Y) }
Procedure Disc(X, Y, R, C : LongInt);
Var Dy, W, Rr : LongInt;
Begin
  Rr := R * R + R;
  For Dy := -R To R Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) + Dy * Dy <= Rr Do Inc(W);
    FBar(X - W, Y + Dy, X + W, Y + Dy, C);
  End;
End;

{ hexagone a sommets gauche et droit : moitie haute en CTop, basse en CBot }
Procedure HexFill(X, Y, R, H, CTop, CBot : LongInt);
Var Dy, W, C : LongInt;
Begin
  For Dy := -H To H Do
  Begin
    W := R - Abs(Dy) * R Div (2 * H);
    If Dy < 0 Then C := CTop Else C := CBot;
    FBar(X - W, Y + Dy, X + W, Y + Dy, C);
  End;
End;

Function TileColor(T : LongInt) : LongInt;
Begin
  Case T Of
    0 : TileColor := CLR_PALEGRAY;
    2 : TileColor := CLR_WHITE;
    4 : TileColor := CLR_YELLOW;
    8 : TileColor := CLR_CYAN;
    16 : TileColor := CLR_GREEN;
    32 : TileColor := CLR_PINK;
    64 : TileColor := CLR_RED;
    128 : TileColor := CLR_BLUE;
    256 : TileColor := CLR_DARKCYAN;
    512 : TileColor := CLR_DARKGREEN;
    1024 : TileColor := CLR_DARKPINK;
    2048 : TileColor := CLR_DARKRED;
    4096 : TileColor := CLR_BROWN;
    8192 : TileColor := CLR_DARKBLUE;
  Else
    TileColor := CLR_BLACK;
  End;
End;

Function TxtColor(T : LongInt) : LongInt;
Begin
  If T <= 32 Then TxtColor := CLR_BLACK
  Else If (T = 2048) Or (T >= 8192) Then TxtColor := CLR_YELLOW
  Else TxtColor := CLR_WHITE;
End;

{ case K (Code : valeur, + 1 pendant l'apparition d'une nouvelle tuile) }
Procedure DrawHex(K, Code : LongInt);
Var X, Y, T, N, R, H : LongInt; S : String;
Begin
  X := CenterX(K); Y := CenterY(K);
  T := Code And (Not 1);
  { alveole en creux }
  HexFill(X, Y, HR - 3, HH - 3, CLR_DARKGRAY, CLR_WHITE);
  HexFill(X, Y, HR - 5, HH - 5, CLR_PALEGRAY, CLR_PALEGRAY);
  If T = 0 Then Exit;
  If (Code And 1) <> 0 Then
  Begin
    { nouvelle tuile : d'abord plus petite }
    HexFill(X, Y, HR - 16, HH - 14, CLR_BLACK, CLR_BLACK);
    HexFill(X, Y, HR - 17, HH - 15, TileColor(T), TileColor(T));
    Exit;
  End;
  { tuile en relief }
  R := HR - 4; H := HH - 4;
  HexFill(X + 1, Y + 1, R, H, CLR_BLACK, CLR_BLACK);
  HexFill(X, Y, R, H, CLR_WHITE, CLR_DARKGRAY);
  HexFill(X, Y, R - 2, H - 2, TileColor(T), TileColor(T));
  S := IStr(T); N := Length(S);
  If N <= 3 Then BigText(X - N * 8, Y - 16, S, TxtColor(T), TileColor(T))
  Else OutTxt(X - N * 4, Y - 8, S, TxtColor(T), TileColor(T));
End;

Function CodeOf(K : LongInt) : LongInt;
Begin
  If (K = PopC) And (Flash > 0) Then CodeOf := V[K] + 1 Else CodeOf := V[K];
End;

{ bouton poussoir de PM }
Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

{ rose des directions : six petits hexagones autour du centre }
Procedure PadXY(D : LongInt; Var X, Y : LongInt);
Begin
  X := PadX + DQ[D] * 35;
  Y := PadY + (2 * DR[D] + DQ[D]) * 20;
End;

Procedure DrawPad;
Var D, X, Y : LongInt;
Begin
  HexFill(PadX, PadY, 18, 15, CLR_DARKGRAY, CLR_WHITE);
  HexFill(PadX, PadY, 16, 13, CLR_DARKBLUE, CLR_DARKBLUE);
  Disc(PadX, PadY, 3, CLR_YELLOW);
  For D := 0 To 5 Do
  Begin
    PadXY(D, X, Y);
    HexFill(X + 1, Y + 1, 18, 15, CLR_BLACK, CLR_BLACK);
    HexFill(X, Y, 18, 15, CLR_WHITE, CLR_DARKGRAY);
    HexFill(X, Y, 16, 13, CLR_PALEGRAY, CLR_PALEGRAY);
    OutTxt(X - 4, Y - 8, Copy('QWEASD', D + 1, 1), CLR_DARKBLUE, CLR_PALEGRAY);
  End;
End;

Procedure DrawDyn(All : Boolean);
Var S : String;
Begin
  If All Or (LScore <> Score) Then
  Begin
    FBar(PnX + 3, GYTop + 66, PnX + PW - 4, GYTop + 98, CLR_WHITE);
    S := IStr(Score);
    BigText(PnX + PW - 8 - Length(S) * 16, GYTop + 66, S, CLR_DARKBLUE, CLR_WHITE);
    LScore := Score;
  End;
  If All Or (LBest <> Best) Then
  Begin
    OutTxt(PnX, GYTop + 108, 'Meilleur : ' + IStr(Best) + '     ', CLR_BLACK, CLR_PALEGRAY);
    LBest := Best;
  End;
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
  LMsg := Msg;
End;

Procedure SyncAll;
Var K, C : LongInt;
Begin
  For K := 0 To NC - 1 Do
  Begin
    C := CodeOf(K);
    If C <> Shown[K] Then
    Begin
      DrawHex(K, C);
      Shown[K] := C;
    End;
  End;
  DrawDyn(False);
  If Msg <> LMsg Then DrawStatus;
End;

Procedure Sync;
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  SyncAll;
  Dummy := WinReleasePS(Hps);
End;

Procedure PaintAll(H : LongInt);
Var K : LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  { plateau en creux }
  Edge(GXLeft, GYTop, GXLeft + 319, GYTop + 341, CLR_DARKGRAY, CLR_WHITE);
  Edge(GXLeft + 1, GYTop + 1, GXLeft + 318, GYTop + 340, CLR_BLACK, CLR_PALEGRAY);
  BigText(PnX + (PW - 8 * 16) Div 2, GYTop + 2, 'HEX 2048', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, GYTop + 44, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, GYTop + 62, PnX + PW - 1, GYTop + 102, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, GYTop + 63, PnX + PW - 2, GYTop + 101, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, GYTop + 64, PnX + PW - 3, GYTop + 100, CLR_WHITE);
  DrawPad;
  Button(PnX, GYTop + 266, PW, 28, 'Nouvelle partie');
  Button(PnX, GYTop + 302, PW, 28, 'Annuler');
  For K := 0 To NC - 1 Do Shown[K] := -1;
  DrawDyn(True);
  DrawStatus;
  SyncAll;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure NewGame;
Var K : LongInt;
Begin
  For K := 0 To NC - 1 Do V[K] := 0;
  Score := 0; Over := 0; Won := 0; Moves := 0; CanUndo := 0; Flash := 0;
  AddTile; AddTile;
  PopC := -1;
  Msg := 'Faites glisser les tuiles (Q W E A S D ou clic sur le plateau) pour atteindre 2048.';
  Redraw;
End;

Function DirName(D : LongInt) : String;
Begin
  Case D Of
    0 : DirName := 'en haut ' + Chr(133) + ' gauche';
    1 : DirName := 'en haut';
    2 : DirName := 'en haut ' + Chr(133) + ' droite';
    3 : DirName := 'en bas ' + Chr(133) + ' gauche';
    4 : DirName := 'en bas';
  Else
    DirName := 'en bas ' + Chr(133) + ' droite';
  End;
End;

Procedure Play(D : LongInt);
Var Gain : LongInt; S : String;
Begin
  If Over <> 0 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  UndoV := V; UndoScore := Score;
  If Not Slide(V, D, Gain) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Msg := 'Rien ne peut glisser ' + DirName(D) + '.';
    Sync;
    Exit;
  End;
  CanUndo := 1;
  Score := Score + Gain;
  If Score > Best Then Best := Score;
  Inc(Moves);
  AddTile;
  Flash := 1;
  If Gain > 0 Then Msg := 'Glissement ' + DirName(D) + ' : + ' + IStr(Gain) + ' points.'
  Else Msg := 'Glissement ' + DirName(D) + '.';
  If Not CanMove Then
  Begin
    Over := 1;
    Msg := 'Partie termin' + Chr(130) + 'e : ' + IStr(Score) + ' points, plus grande tuile ' +
           IStr(MaxTile) + '.  F2 : nouvelle partie.';
  End;
  Sync;
  If (Won = 0) And (MaxTile >= 2048) And (Over = 0) Then
  Begin
    Won := 1;
    If AutoAll = 0 Then
      If Ask('Bravo, vous avez atteint la tuile 2048 !' + Chr(10) + Chr(10) + 'Continuer la partie ?',
             'Hex 2048', MB_YESNO Or MB_QUERY) <> MBID_YES Then NewGame;
  End;
  If (Over <> 0) And (AutoAll = 0) Then
  Begin
    S := 'Plus rien ne peut glisser : partie termin' + Chr(130) + 'e.' + Chr(10) + 'Pointage : ' + IStr(Score) +
         ' (plus grande tuile : ' + IStr(MaxTile) + ', ' + IStr(Moves) + ' glissements).' + Chr(10) + Chr(10) +
         'Une nouvelle partie ?';
    If Ask(S, 'Hex 2048', MB_YESNO Or MB_QUERY) = MBID_YES Then NewGame;
  End;
End;

Procedure Undo;
Begin
  If CanUndo = 0 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  V := UndoV; Score := UndoScore;
  CanUndo := 0; Over := 0; Flash := 0;
  If Moves > 0 Then Dec(Moves);
  Msg := 'Dernier glissement annul' + Chr(130) + '.';
  Sync;
End;

{ demonstration (/AUTO) : le glissement qui rapporte le plus, de
  preference vers le bas }
Procedure AutoMove;
Var D, I, G, BestG, BestD : LongInt; T : TGrid;
Begin
  If Over <> 0 Then Exit;
  BestD := -1; BestG := -1;
  For I := 0 To 5 Do
  Begin
    Case I Of
      0 : D := 4;
      1 : D := 5;
      2 : D := 3;
      3 : D := 0;
      4 : D := 2;
    Else
      D := 1;
    End;
    T := V;
    If Slide(T, D, G) Then
      If G > BestG Then
      Begin
        BestG := G; BestD := D;
      End;
  End;
  If BestD >= 0 Then Play(BestD);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_UNDO : Undo;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES : Dummy := Ask('Faites glisser toutes les tuiles dans une des six directions de la grille ' +
                            'hexagonale. Deux tuiles de m' + Chr(136) + 'me valeur qui se rencontrent ' +
                            'fusionnent (2 + 2 = 4, 4 + 4 = 8...) et le pointage augmente de la nouvelle ' +
                            'valeur. Chaque glissement ajoute une tuile (2, parfois 4). Atteignez 2048 ! ' +
                            'La partie finit quand plus rien ne peut glisser.' + Chr(10) + Chr(10) +
                            'Clavier : Q W E (haut gauche, haut, haut droite), A S D (bas gauche, bas, ' +
                            'bas droite), ou 7 8 9 1 2 3 du pav' + Chr(130) + ' num' + Chr(130) + 'rique. ' +
                            'Souris : cliquer sur le plateau du c' + Chr(147) + 't' + Chr(130) +
                            ' o' + Chr(151) + ' glisser, ou sur la rose des directions. ' +
                            'Ctrl+Z : annuler ; F2 : nouvelle partie.',
                            'Hex 2048 - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
    CM_ABOUT : Dummy := Ask('Hex 2048 pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'HEX2048.PAS de 7iles : le 2048 sur une grille hexagonale de 19 cases.' + Chr(10) +
                            'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                            'A propos de Hex 2048', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

{ direction du secteur (six secteurs de 60 degres) ou se trouve (Dx, Dy) }
Function DirSector(Dx, Dy : LongInt) : LongInt;
Begin
  If Dy < 0 Then
  Begin
    If Abs(Dy) * 1000 > Abs(Dx) * 1732 Then DirSector := 1
    Else If Dx > 0 Then DirSector := 2 Else DirSector := 0;
  End
  Else
  Begin
    If Abs(Dy) * 1000 > Abs(Dx) * 1732 Then DirSector := 4
    Else If Dx > 0 Then DirSector := 5 Else DirSector := 3;
  End;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, D, Px, Py : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= GXLeft) And (X < GXLeft + 320) And (Y >= GYTop) And (Y < GYTop + 342) Then
  Begin
    If Abs(X - BX) + Abs(Y - BY) > 12 Then Play(DirSector(X - BX, Y - BY));
    Exit;
  End;
  For D := 0 To 5 Do
  Begin
    PadXY(D, Px, Py);
    If (Abs(X - Px) <= 16) And (Abs(Y - Py) <= 14) Then
    Begin
      Play(D);
      Exit;
    End;
  End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= GYTop + 266) And (Y < GYTop + 294) Then NewGame
    Else If (Y >= GYTop + 302) And (Y < GYTop + 330) Then Undo;
  End;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk, P : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_CTRL) <> 0 Then
  Begin
    If (Ch = 26) Or (Ch = Ord('z')) Or (Ch = Ord('Z')) Then Undo Else KeyChar := False;
    Exit;
  End;
  If ((Fl And KC_CHAR) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 32) Then
  Begin
    If (Ch >= 97) And (Ch <= 122) Then Ch := Ch - 32;
    P := Pos(Chr(Ch), 'QWEASD');
    If P > 0 Then Begin Play(P - 1); Exit; End;
    P := Pos(Chr(Ch), '789123');
    If P > 0 Then Begin Play(P - 1); Exit; End;
    If Ch = Ord('R') Then Begin NewGame; Exit; End;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_HOME Then Begin Play(0); Exit; End;
    If Vk = VK_UP Then Begin Play(1); Exit; End;
    If Vk = VK_PAGEUP Then Begin Play(2); Exit; End;
    If Vk = VK_END Then Begin Play(3); Exit; End;
    If Vk = VK_DOWN Then Begin Play(4); Exit; End;
    If Vk = VK_PAGEDOWN Then Begin Play(5); Exit; End;
  End;
  KeyChar := False;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  MainProc := 0;
  Case Msg Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
      End;
    WM_PAINT : PaintAll(H);
    WM_TIMER :
      Begin
        If (Lo16(Mp1) = 1) And (Flash > 0) Then
        Begin
          Flash := 0;
          Sync;
        End;
        If (Lo16(Mp1) = 2) And (AutoAll <> 0) Then AutoMove;
      End;
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        Click(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := 1;
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CHAR :
      If Not KeyChar(Mp1, Mp2) Then MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2) Else MainProc := 1;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Menus                                                                 }
{ ==================================================================== }

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

{ police 8 x 16 du VGA (VIOCALLS) pour les textes agrandis }
Procedure LoadFont;
Var P, K : LongInt; Inf : Array[0..15] Of Byte;
Begin
  FontH := 0;
  For K := 0 To 15 Do Inf[K] := 0;
  WrW(LongInt(@Inf), 14); WrW(LongInt(@Inf) + 2, 1);
  If VioGetFont(LongInt(@Inf), 0) <> 0 Then Exit;
  P := RdL(LongInt(@Inf) + 8);
  K := Inf[6] Or (Inf[7] Shl 8);
  If (P = 0) Or (K < 8) Or (K > 16) Then Exit;
  FontH := K;
  For K := 0 To 256 * FontH - 1 Do Font[K] := RdB(P + K);
End;

Var
  Fl, H0, H1, H2, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LMsg := ''; AutoAll := 0; Best := 0; PopC := -1; Flash := 0;
  Client := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
    If (S = '/AUTO') Or (S = '/auto') Then AutoAll := 1;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('HEX2048'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  InitCells;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('HEX2048'), Z2('Hex 2048'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le glissement' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Hex 2048');
  MenuClose(H2, 2);
  MenuClose(H0, 2);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CWant; Rc[3] := CHWant;
  Dummy := WinCalcFrameRect(Frame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (Sw - Fw) Div 2; Y := (Sh - Fh) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := Sh - Fh;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 110);
  If AutoAll <> 0 Then Dummy := WinStartTimer(Hab, Client, 2, 150);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
