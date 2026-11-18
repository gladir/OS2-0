{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: POWER4 - Puissance 4 pour le Presentation Manager d'OS/2-0
                (dossier Jeux du bureau).
}

Program POWER4;

{$R-,S-,I-}

{ Compilation : OS2PC POWER4.PAS   (produit POWER4.EXE)

  Portage vers OS/2-0 du prototype POWER4.PAS du depot 7iles (Turbo
  Pascal et BGI, fleches et souris) : fenetre de Presentation Manager avec
  menus, chute animee des jetons, panneau des scores, barre d'etat et
  apparence d'OS/2.

  But : aligner quatre jetons de sa couleur (horizontale, verticale ou
  diagonale) sur la grille de 7 colonnes et 6 rangees ; chaque jeton tombe
  au plus bas de la colonne choisie. Grille pleine sans alignement :
  partie nulle.

  Contre l'ordinateur (vous avez les rouges, comme le prototype) ou a deux
  joueurs. L'ordinateur cherche par alpha-beta (Facile : 2 demi-coups et
  du hasard ; Moyen : 5 ; Difficile : 7) en comptant les alignements
  possibles ; le prototype ne voyait que le coup gagnant immediat.
  Souris : cliquer une colonne. Clavier : fleches gauche et droite, Entree,
  Espace ou fleche bas (jouer), 1 a 7 (colonne), Ctrl+Z (annuler),
  F2 (nouvelle partie), F1 (regles).
  Parametres : /SEED:n ; /AUTO (l'ordinateur joue les deux couleurs). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_NEWLINE = $08; VK_SPACE = $10; VK_LEFT = $15; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_UNDO = 102; CM_CPUFIRST = 103; CM_QUIT = 104;
  CM_VSCPU = 111; CM_TWO = 112;
  CM_EASY = 121; CM_MEDIUM = 122; CM_HARD = 123;
  CM_RULES = 301; CM_ABOUT = 302;
  NCol = 7; NRow = 6; NCell = 42;
  PRouge = 1; PJaune = 2;
  { disposition (zone client, Y vers le bas) }
  Cs = 54; BX0 = 14; BY0 = 64; TRad = 21;
  PnX = 418; PW = 186;
  CWant = 614; CHWant = 436;
  Inf = 1000000;

Type
  TBd = Array[0..NCell - 1] Of LongInt;   { rangee * 7 + colonne ; rangee 0 en haut }

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Bd : TBd;
  Turn, Mode, Level, CpuFirst, SelCol, Over, Winner, Thinking, Seed, AutoAll, NMoves, Wait : LongInt;
  Hist : Array[0..NCell - 1] Of LongInt;          { colonnes jouees }
  WinCells : Array[0..3] Of LongInt;
  Wins : Array[0..2] Of LongInt;                 { nuls, rouges, jaunes }
  AnimCol, AnimRow, AnimTo, AnimP : LongInt;     { chute d'un jeton }
  Msg : String;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;
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

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

Function Opp(P : LongInt) : LongInt;
Begin
  Opp := 3 - P;
End;

Function IsCpu(P : LongInt) : Boolean;
Begin
  IsCpu := (AutoAll <> 0) Or ((Mode = 0) And (P = PJaune));
End;

Function PName(P : LongInt) : String;
Begin
  If AutoAll <> 0 Then
  Begin
    If P = PRouge Then PName := 'Rouges' Else PName := 'Jaunes';
  End
  Else If Mode = 0 Then
  Begin
    If P = PRouge Then PName := 'Vous' Else PName := 'Ordinateur';
  End
  Else If P = PRouge Then PName := 'Joueur 1 (rouges)' Else PName := 'Joueur 2 (jaunes)';
End;

{ ==================================================================== }
{ Regles                                                                }
{ ==================================================================== }

{ rangee ou tomberait un jeton dans la colonne C (-1 : pleine) }
Function DropRow(Var B : TBd; C : LongInt) : LongInt;
Var R : LongInt;
Begin
  DropRow := -1;
  For R := NRow - 1 DownTo 0 Do
    If B[R * NCol + C] = 0 Then
    Begin
      DropRow := R;
      Exit;
    End;
End;

{ nombre de jetons P alignes depuis (R, C) dans la direction (Dr, Dc),
  sans compter (R, C) }
Function Run(Var B : TBd; R, C, Dr, Dc, P : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  R := R + Dr; C := C + Dc;
  While (R >= 0) And (R < NRow) And (C >= 0) And (C < NCol) And (N < 4) Do
  Begin
    If B[R * NCol + C] <> P Then
    Begin
      Run := N;
      Exit;
    End;
    Inc(N);
    R := R + Dr; C := C + Dc;
  End;
  Run := N;
End;

{ le jeton en (R, C) fait-il un alignement de quatre ? }
Function Wins4(Var B : TBd; R, C : LongInt) : Boolean;
Var P, D, Dr, Dc : LongInt;
Begin
  Wins4 := False;
  P := B[R * NCol + C];
  If P = 0 Then Exit;
  For D := 0 To 3 Do
  Begin
    Case D Of
      0 : Begin Dr := 0; Dc := 1; End;
      1 : Begin Dr := 1; Dc := 0; End;
      2 : Begin Dr := 1; Dc := 1; End;
    Else
      Begin Dr := 1; Dc := -1; End;
    End;
    If Run(B, R, C, Dr, Dc, P) + Run(B, R, C, -Dr, -Dc, P) >= 3 Then
    Begin
      Wins4 := True;
      Exit;
    End;
  End;
End;

{ cases de l'alignement gagnant passant par (R, C) }
Procedure FindWin(R, C : LongInt);
Var P, D, Dr, Dc, A, K : LongInt;
Begin
  P := Bd[R * NCol + C];
  For D := 0 To 3 Do
  Begin
    Case D Of
      0 : Begin Dr := 0; Dc := 1; End;
      1 : Begin Dr := 1; Dc := 0; End;
      2 : Begin Dr := 1; Dc := 1; End;
    Else
      Begin Dr := 1; Dc := -1; End;
    End;
    A := Run(Bd, R, C, -Dr, -Dc, P);
    If A + Run(Bd, R, C, Dr, Dc, P) >= 3 Then
    Begin
      For K := 0 To 3 Do WinCells[K] := (R + (K - A) * Dr) * NCol + C + (K - A) * Dc;
      Exit;
    End;
  End;
End;

{ ==================================================================== }
{ Ordinateur : alpha-beta                                               }
{ ==================================================================== }

Const
  Order : Array[0..6] Of LongInt = (3, 2, 4, 1, 5, 0, 6);

{ valeur d'une fenetre de quatre cases pour P }
Function Window4(N, M : LongInt) : LongInt;
Begin
  Window4 := 0;
  If (N > 0) And (M > 0) Then Exit;
  If N = 3 Then Window4 := 50
  Else If N = 2 Then Window4 := 10
  Else If N = 1 Then Window4 := 1
  Else If M = 3 Then Window4 := -60
  Else If M = 2 Then Window4 := -10
  Else If M = 1 Then Window4 := -1;
End;

Function Eval(Var B : TBd; P : LongInt) : LongInt;
Var R, C, D, Dr, Dc, K, N, M, V, Q : LongInt;
Begin
  V := 0;
  For R := 0 To NRow - 1 Do
  Begin
    If B[R * NCol + 3] = P Then V := V + 6 Else If B[R * NCol + 3] <> 0 Then V := V - 6;
  End;
  For R := 0 To NRow - 1 Do
    For C := 0 To NCol - 1 Do
      For D := 0 To 3 Do
      Begin
        Case D Of
          0 : Begin Dr := 0; Dc := 1; End;
          1 : Begin Dr := 1; Dc := 0; End;
          2 : Begin Dr := 1; Dc := 1; End;
        Else
          Begin Dr := 1; Dc := -1; End;
        End;
        If (R + 3 * Dr >= 0) And (R + 3 * Dr < NRow) And (C + 3 * Dc >= 0) And (C + 3 * Dc < NCol) Then
        Begin
          N := 0; M := 0;
          For K := 0 To 3 Do
          Begin
            Q := B[(R + K * Dr) * NCol + C + K * Dc];
            If Q = P Then Inc(N) Else If Q <> 0 Then Inc(M);
          End;
          V := V + Window4(N, M);
        End;
      End;
  Eval := V;
End;

Function Search(Var B : TBd; P, Depth, Alpha, Beta, Ply : LongInt) : LongInt;
Var I, C, R, V, Best, Any : LongInt;
Begin
  If Depth <= 0 Then
  Begin
    Search := Eval(B, P);
    Exit;
  End;
  Best := -Inf; Any := 0;
  For I := 0 To NCol - 1 Do
  Begin
    C := Order[I];
    R := DropRow(B, C);
    If R >= 0 Then
    Begin
      Any := 1;
      B[R * NCol + C] := P;
      If Wins4(B, R, C) Then V := Inf - Ply
      Else V := -Search(B, Opp(P), Depth - 1, -Beta, -Alpha, Ply + 1);
      B[R * NCol + C] := 0;
      If V > Best Then Best := V;
      If V > Alpha Then Alpha := V;
      If Alpha >= Beta Then
      Begin
        Search := Best;
        Exit;
      End;
    End;
  End;
  If Any = 0 Then Best := 0;                    { grille pleine : nulle }
  Search := Best;
End;

Function BestCol(P : LongInt) : LongInt;
Var I, C, R, V, Best, BestC, Depth : LongInt; T : TBd;
Begin
  Case Level Of
    0 : Depth := 2;
    2 : Depth := 7;
  Else
    Depth := 5;
  End;
  T := Bd;
  Best := -Inf - 10; BestC := -1;
  For I := 0 To NCol - 1 Do
  Begin
    C := Order[I];
    R := DropRow(T, C);
    If R >= 0 Then
    Begin
      T[R * NCol + C] := P;
      If Wins4(T, R, C) Then V := Inf
      Else V := -Search(T, Opp(P), Depth - 1, -Inf - 1, Inf + 1, 1);
      T[R * NCol + C] := 0;
      If Level = 0 Then V := V + Rnd(40)
      Else V := V * 4 + Rnd(4);
      If V > Best Then
      Begin
        Best := V; BestC := C;
      End;
    End;
  End;
  BestCol := BestC;
End;


{ messages de plus de 255 caracteres (limite des chaines) : texte cumule
  dans LBuf par LAdd, puis affiche par LMsgBox }
Var
  LBuf : Array[0..4095] Of Byte;
  LLen : LongInt;

Procedure LClr;
Begin
  LLen := 0;
  LBuf[0] := 0;
End;

Procedure LAdd(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If LLen < 4094 Then
    Begin
      LBuf[LLen] := Ord(S[K]);
      Inc(LLen);
    End;
  LBuf[LLen] := 0;
End;

Function LMsgBox(Cap : String; Fl : LongInt) : LongInt;
Begin
  LMsgBox := WinMessageBox(HWND_DESKTOP, Frame, LongInt(@LBuf), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;
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

{ ==================================================================== }
{ Dessin (Y vers le bas)                                                }
{ ==================================================================== }

Procedure Token(X, Y, P : LongInt);
Var C, Cd : LongInt;
Begin
  If P = PRouge Then
  Begin
    C := CLR_RED; Cd := CLR_DARKRED;
  End
  Else
  Begin
    C := CLR_YELLOW; Cd := CLR_BROWN;
  End;
  Disc(X, Y, TRad, Cd);
  Disc(X - 1, Y - 1, TRad - 2, C);
  Disc(X - 1, Y - 1, TRad - 7, Cd);
  Disc(X - 2, Y - 2, TRad - 8, C);
  FBar(X - 8, Y - 10, X - 5, Y - 8, CLR_WHITE);
End;

Procedure CellXY(Q : LongInt; Var X, Y : LongInt);
Begin
  X := BX0 + (Q Mod NCol) * Cs + Cs Div 2;
  Y := BY0 + (Q Div NCol) * Cs + Cs Div 2;
End;

Function IsWinCell(Q : LongInt) : Boolean;
Var K : LongInt;
Begin
  IsWinCell := False;
  If Winner <= 0 Then Exit;
  For K := 0 To 3 Do If WinCells[K] = Q Then IsWinCell := True;
End;

{ une case de la grille (trou ou jeton) }
Procedure DrawCell(Q, P : LongInt);
Var X, Y : LongInt;
Begin
  CellXY(Q, X, Y);
  FBar(X - Cs Div 2, Y - Cs Div 2, X + Cs Div 2 - 1, Y + Cs Div 2 - 1, CLR_BLUE);
  Disc(X, Y, TRad + 2, CLR_DARKBLUE);
  If P = 0 Then Disc(X + 1, Y + 1, TRad, CLR_WHITE)
  Else
  Begin
    Disc(X + 1, Y + 1, TRad, CLR_WHITE);
    Token(X, Y, P);
  End;
  If IsWinCell(Q) Then
  Begin
    Disc(X, Y, 6, CLR_BLACK);
    Disc(X, Y, 4, CLR_WHITE);
  End;
End;

{ jeton au-dessus de la grille (colonne choisie) }
Procedure DrawPreview;
Var X : LongInt;
Begin
  FBar(BX0 - 4, 8, BX0 + NCol * Cs + 3, BY0 - 8, CLR_PALEGRAY);
  If (Over <> 0) Or IsCpu(Turn) Or (AnimCol >= 0) Then Exit;
  X := BX0 + SelCol * Cs + Cs Div 2;
  Token(X, 8 + TRad + 2, Turn);
  FBar(X - 4, BY0 - 14, X + 4, BY0 - 12, CLR_DARKGRAY);
  FBar(X - 2, BY0 - 11, X + 2, BY0 - 10, CLR_DARKGRAY);
End;

Procedure DrawBoard;
Var Q, K, X : LongInt;
Begin
  Edge(BX0 - 4, BY0 - 4, BX0 + NCol * Cs + 3, BY0 + NRow * Cs + 3, CLR_CYAN, CLR_DARKBLUE);
  Edge(BX0 - 3, BY0 - 3, BX0 + NCol * Cs + 2, BY0 + NRow * Cs + 2, CLR_CYAN, CLR_DARKBLUE);
  FBar(BX0 - 2, BY0 - 2, BX0 + NCol * Cs + 1, BY0 + NRow * Cs + 1, CLR_BLUE);
  For Q := 0 To NCell - 1 Do
    If (AnimCol >= 0) And (Q = AnimTo * NCol + AnimCol) Then DrawCell(Q, 0) Else DrawCell(Q, Bd[Q]);
  If AnimCol >= 0 Then
  Begin
    X := BX0 + AnimCol * Cs + Cs Div 2;
    If AnimRow >= 0 Then Token(X, BY0 + AnimRow * Cs + Cs Div 2, AnimP);
  End;
  For K := 0 To NCol - 1 Do
    OutTxt(BX0 + K * Cs + Cs Div 2 - 4, BY0 + NRow * Cs + 6, IStr(K + 1), CLR_DARKGRAY, CLR_PALEGRAY);
  DrawPreview;
End;

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PlayerBox(Y, P : LongInt);
Var S : String;
Begin
  FBar(PnX, Y, PnX + PW - 1, Y + 53, CLR_WHITE);
  Edge(PnX, Y, PnX + PW - 1, Y + 53, CLR_DARKGRAY, CLR_WHITE);
  If (Turn = P) And (Over = 0) Then
  Begin
    Edge(PnX + 1, Y + 1, PnX + PW - 2, Y + 52, CLR_BLUE, CLR_BLUE);
    Edge(PnX + 2, Y + 2, PnX + PW - 3, Y + 51, CLR_BLUE, CLR_BLUE);
  End;
  Token(PnX + 28, Y + 27, P);
  S := PName(P);
  If Length(S) > 16 Then S := Copy(S, 1, 8);
  OutTxt(PnX + 56, Y + 6, S, CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 56, Y + 26, 'Victoires : ' + IStr(Wins[P]), CLR_DARKBLUE, CLR_WHITE);
End;

Procedure DrawPanel;
Var S : String;
Begin
  BigText(PnX + (PW - 11 * 16) Div 2, 10, 'PUISSANCE 4', CLR_DARKBLUE, CLR_PALEGRAY);
  PlayerBox(56, PRouge);
  PlayerBox(118, PJaune);
  OutTxt(PnX, 184, 'Parties nulles : ' + IStr(Wins[0]), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 202, 'Jetons jou' + Chr(130) + 's : ' + IStr(NMoves), CLR_BLACK, CLR_PALEGRAY);
  If Mode = 0 Then
  Begin
    Case Level Of
      0 : S := 'Facile';
      2 : S := 'Difficile';
    Else
      S := 'Moyen';
    End;
    OutTxt(PnX, 220, 'Niveau : ' + S, CLR_BLACK, CLR_PALEGRAY);
  End
  Else OutTxt(PnX, 220, 'Deux joueurs', CLR_BLACK, CLR_PALEGRAY);
  Button(PnX, 300, PW, 30, 'Nouvelle partie');
  Button(PnX, 336, PW, 30, 'Annuler le coup');
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  DrawBoard;
  DrawPanel;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ dessin sans effacer (chute du jeton, jeton au-dessus de la grille) }
Procedure ShowAnim(Prev : LongInt);
Var X, Y : LongInt;
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If Prev >= 0 Then DrawCell(Prev * NCol + AnimCol, Bd[Prev * NCol + AnimCol]);
  If AnimRow >= 0 Then
  Begin
    X := BX0 + AnimCol * Cs + Cs Div 2; Y := BY0 + AnimRow * Cs + Cs Div 2;
    Token(X, Y, AnimP);
  End;
  DrawPreview;
  Dummy := WinReleasePS(Hps);
End;

Procedure ShowPreview;
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  DrawPreview;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure SetMark(Id : LongInt; On : Boolean);
Var M : LongInt;
Begin
  M := WinWindowFromID(Frame, $8005);
  If M = 0 Then Exit;
  If On Then Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED);
End;

Procedure SetMarks;
Begin
  SetMark(CM_VSCPU, Mode = 0); SetMark(CM_TWO, Mode = 1);
  SetMark(CM_EASY, Level = 0); SetMark(CM_MEDIUM, Level = 1); SetMark(CM_HARD, Level = 2);
  SetMark(CM_CPUFIRST, CpuFirst <> 0);
End;

Procedure TurnMsg;
Begin
  If IsCpu(Turn) Then Msg := 'L''ordinateur r' + Chr(130) + 'fl' + Chr(130) + 'chit...'
  Else If Mode = 0 Then Msg := 'A vous (rouges) : cliquez une colonne (ou fl' + Chr(138) + 'ches et Entr' + Chr(130) +
    'e).'
  Else Msg := 'Au tour de ' + PName(Turn) + '.';
End;

Procedure NewGame;
Var Q : LongInt;
Begin
  For Q := 0 To NCell - 1 Do Bd[Q] := 0;
  If (CpuFirst <> 0) And (Mode = 0) Then Turn := PJaune Else Turn := PRouge;
  Over := 0; Winner := 0; NMoves := 0; SelCol := 3; AnimCol := -1; Thinking := 0;
  TurnMsg;
  If IsCpu(Turn) Then Thinking := 2;
  Redraw;
End;

Procedure GameOver;
Var S : String;
Begin
  Over := 1;
  Inc(Wins[Winner]);
  If Winner = 0 Then S := 'Partie nulle : la grille est pleine.'
  Else If (Mode = 0) And (AutoAll = 0) Then
  Begin
    If Winner = PRouge Then S := 'Bravo, vous avez align' + Chr(130) + ' quatre jetons !'
    Else S := 'L''ordinateur a align' + Chr(130) + ' quatre jetons.';
  End
  Else S := PName(Winner) + ' gagnent : quatre jetons align' + Chr(130) + 's !';
  Msg := S + '  F2 : nouvelle partie.';
  Redraw;
  If AutoAll = 0 Then
    If Ask(S + Chr(10) + Chr(10) + 'Une nouvelle partie ?', 'Puissance 4', MB_YESNO Or MB_QUERY) = MBID_YES Then
      NewGame;
End;

{ fin de la chute : le jeton est pose }
Procedure Landed;
Var R, C : LongInt;
Begin
  C := AnimCol; R := AnimTo;
  Bd[R * NCol + C] := AnimP;
  Hist[NMoves] := C;
  Inc(NMoves);
  AnimCol := -1;
  If Wins4(Bd, R, C) Then
  Begin
    Winner := AnimP;
    FindWin(R, C);
    GameOver;
    Exit;
  End;
  If NMoves = NCell Then
  Begin
    Winner := 0;
    GameOver;
    Exit;
  End;
  Turn := Opp(Turn);
  TurnMsg;
  If IsCpu(Turn) Then Thinking := 2;
  Redraw;
End;

{ joue dans la colonne C : le jeton tombe (minuterie) }
Procedure Play(C : LongInt);
Var R : LongInt;
Begin
  If (Over <> 0) Or (AnimCol >= 0) Or (C < 0) Or (C >= NCol) Then Exit;
  R := DropRow(Bd, C);
  If R < 0 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Msg := 'Cette colonne est pleine.';
    Redraw;
    Exit;
  End;
  SelCol := C;
  AnimCol := C; AnimRow := -1; AnimTo := R; AnimP := Turn;
  ShowPreview;
End;

Procedure CpuMove;
Begin
  Thinking := 0;
  If (Over <> 0) Or Not IsCpu(Turn) Then Exit;
  Play(BestCol(Turn));
End;

Procedure Undo;
Var C, R, N : LongInt;
Begin
  If (NMoves = 0) Or (AnimCol >= 0) Or (Thinking <> 0) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  { contre l'ordinateur : jusqu'au dernier jeton du joueur }
  If Over <> 0 Then Dec(Wins[Winner]);
  N := 0;
  Repeat
    Dec(NMoves);
    C := Hist[NMoves];
    R := DropRow(Bd, C) + 1;
    Turn := Bd[R * NCol + C];
    Bd[R * NCol + C] := 0;
    Inc(N);
  Until (NMoves = 0) Or Not IsCpu(Turn);
  Over := 0; Winner := 0;
  TurnMsg;
  If IsCpu(Turn) Then Thinking := 2;
  Redraw;
End;

Procedure SetMode(M : LongInt);
Begin
  Mode := M;
  SetMarks;
  NewGame;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_UNDO : Undo;
    CM_CPUFIRST : Begin CpuFirst := 1 - CpuFirst; SetMarks; NewGame; End;
    CM_VSCPU : SetMode(0);
    CM_TWO : SetMode(1);
    CM_EASY : Begin Level := 0; SetMarks; Redraw; End;
    CM_MEDIUM : Begin Level := 1; SetMarks; Redraw; End;
    CM_HARD : Begin Level := 2; SetMarks; Redraw; End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        LClr;
        LAdd('Alignez quatre jetons de votre couleur (horizontale, verticale ou diagonale) sur la grille de ' +
             '7 colonnes et 6 rang' + Chr(130) + 'es. Chaque jeton tombe au plus bas de la colonne choisie. ');
        LAdd('Grille pleine sans alignement : partie nulle. Les rouges commencent (menu Partie : ' +
             'l''ordinateur peut commencer).' + Chr(10) + Chr(10));
        LAdd('Souris : cliquer une colonne. Clavier : fl' + Chr(138) + 'ches gauche et droite, Entr' + Chr(130) +
             'e, Espace ou fl' + Chr(138) + 'che bas (jouer), 1 ' + Chr(133) + ' 7 (colonne), Ctrl+Z (annuler), ' +
             'F2 (nouvelle partie).');
        Dummy := LMsgBox('Puissance 4 - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Puissance 4 pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'POWER4.PAS de 7iles : contre l''ordinateur (alpha-b' + Chr(130) + 'ta) ou ' + Chr(133) +
                            ' deux joueurs.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et compil' +
                            Chr(130) + ' par OS2PC.', 'A propos de Puissance 4', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Function ColAt(X : LongInt) : LongInt;
Begin
  ColAt := -1;
  If (X >= BX0) And (X < BX0 + NCol * Cs) Then ColAt := (X - BX0) Div Cs;
End;

Function Human : Boolean;
Begin
  Human := (Over = 0) And Not IsCpu(Turn) And (AnimCol < 0) And (Thinking = 0);
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, C : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  C := ColAt(X);
  If (C >= 0) And (Y < BY0 + NRow * Cs) Then
  Begin
    If Human Then Play(C);
    Exit;
  End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 300) And (Y < 330) Then NewGame
    Else If (Y >= 336) And (Y < 366) Then Undo;
  End;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
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
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_LEFT Then Begin If SelCol > 0 Then Dec(SelCol); ShowPreview; Exit; End;
    If Vk = VK_RIGHT Then Begin If SelCol < NCol - 1 Then Inc(SelCol); ShowPreview; Exit; End;
    If (Vk = VK_DOWN) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_SPACE) Then
    Begin
      If Human Then Play(SelCol);
      Exit;
    End;
  End;
  If ((Fl And KC_CHAR) <> 0) And ((Fl And KC_ALT) = 0) Then
  Begin
    If (Ch >= 49) And (Ch <= 55) Then
    Begin
      If Human Then Play(Ch - 49);
      Exit;
    End;
    If Ch = 32 Then
    Begin
      If Human Then Play(SelCol);
      Exit;
    End;
  End;
  KeyChar := False;
End;

Procedure TimerTick;
Var Prev : LongInt;
Begin
  If Over <> 0 Then
  Begin
    If AutoAll <> 0 Then
    Begin
      Inc(Wait);
      If Wait > 40 Then
      Begin
        Wait := 0;
        NewGame;
      End;
    End;
    Exit;
  End;
  If AnimCol >= 0 Then
  Begin
    Prev := AnimRow;
    Inc(AnimRow);
    If AnimRow >= AnimTo Then
    Begin
      AnimRow := AnimTo;
      ShowAnim(Prev);
      Landed;
    End
    Else ShowAnim(Prev);
    Exit;
  End;
  If Thinking > 0 Then
  Begin
    Dec(Thinking);
    If Thinking = 0 Then
    Begin
      Thinking := 1;
      CpuMove;
    End;
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
    WM_TIMER : If Lo16(Mp1) = 1 Then TimerTick;
    WM_MOUSEMOVE :
      Begin
        C := ColAt(S16(Mp1));
        If (C >= 0) And (C <> SelCol) And Human Then
        Begin
          SelCol := C;
          ShowPreview;
        End;
        MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
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
  Msg := ''; AutoAll := 0; Mode := 0; Level := 1; CpuFirst := 0; Over := 1; AnimCol := -1; Thinking := 0;
  Wins[0] := 0; Wins[1] := 0; Wins[2] := 0; Wait := 0; SelCol := 3;
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
  Dummy := WinRegisterClass(Hab, Z('POWER4'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('POWER4'), Z2('Puissance 4'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_TEXT, 0, CM_CPUFIRST, 'L''ordinateur ~commence');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, MIA_CHECKED, CM_VSCPU, 'Contre l''~ordinateur');
  MItem(MIS_TEXT, 0, CM_TWO, '~Deux joueurs');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_EASY, '~Facile');
  MItem(MIS_TEXT, MIA_CHECKED, CM_MEDIUM, '~Moyen');
  MItem(MIS_TEXT, 0, CM_HARD, 'Di~fficile');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 12);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Puissance 4');
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
  SetMarks;
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 45);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
