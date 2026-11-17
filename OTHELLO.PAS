{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: OTHELLO - jeu d'Othello (Reversi) pour le Presentation
                Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program OTHELLO;

{$R-,S-,I-}

{ Compilation : OS2PC OTHELLO.PAS   (produit OTHELLO.EXE)

  Portage vers OS/2-0 du prototype OTHELLO.PAS du depot 7iles (Turbo
  Pascal et BGI, clavier seulement, ecran de titre) : fenetre de
  Presentation Manager avec menus, souris, panneau des scores, barre
  d'etat et apparence d'OS/2.

  But : avoir le plus de pions de sa couleur a la fin. Chaque coup doit
  encadrer, en ligne droite (horizontale, verticale ou diagonale), au moins
  un pion adverse entre le pion pose et un pion de sa couleur ; tous les
  pions encadres sont retournes. Un joueur qui ne peut pas jouer passe son
  tour (automatiquement) ; la partie finit quand personne ne peut jouer.
  Noir commence.

  Modes (comme le prototype) : contre l'ordinateur (vous jouez les Noirs)
  ou deux joueurs. Niveaux de l'ordinateur : Facile (coup glouton avec du
  hasard, comme le prototype), Moyen (poids des cases, mobilite) et
  Difficile (recherche alpha-beta sur quatre demi-coups avec les poids
  des cases, la mobilite et les coins).

  Souris : cliquer une case. Clavier : fleches, Entree ou Espace (jouer),
  H (indices : coups possibles avec le nombre de pions retournes),
  Ctrl+Z (annuler), F2 (nouvelle partie), F1 (regles). Les coups possibles
  sont marques d'un point, le dernier coup d'un carre rouge.
  Parametres : /SEED:n (hasard reproductible, pour les essais) ; /AUTO
  (l'ordinateur joue les deux couleurs : demonstration et essais). }

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
  VK_NEWLINE = $08; VK_SPACE = $0E; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_GREEN = 4; CLR_YELLOW = 6;
  CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_UNDO = 102; CM_HINTS = 103; CM_QUIT = 104;
  CM_VSCPU = 111; CM_TWO = 112;
  CM_EASY = 121; CM_MEDIUM = 122; CM_HARD = 123;
  CM_RULES = 301; CM_ABOUT = 302;
  { pions }
  Empty = 0; PBlack = 1; PWhite = 2;
  { disposition (zone client, Y vers le bas) }
  Cell = 46; GX = 14; GY = 12; Rad = 19;
  PX = 404; PW = 196;
  CWant = 612; CHWant = 412;
  MaxHist = 70;
  Inf = 1000000;

Type
  TBd = Array[0..63] Of LongInt;

Const
  { poids des cases (coins tres bons, cases X et C a eviter) }
  Weight : Array[0..63] Of LongInt = (
    120, -20, 20,  5,  5, 20, -20, 120,
    -20, -40, -5, -5, -5, -5, -40, -20,
     20,  -5, 15,  3,  3, 15,  -5,  20,
      5,  -5,  3,  3,  3,  3,  -5,   5,
      5,  -5,  3,  3,  3,  3,  -5,   5,
     20,  -5, 15,  3,  3, 15,  -5,  20,
    -20, -40, -5, -5, -5, -5, -40, -20,
    120, -20, 20,  5,  5, 20, -20, 120);
  DR : Array[0..7] Of LongInt = (-1, -1, -1, 0, 0, 1, 1, 1);
  DC : Array[0..7] Of LongInt = (-1, 0, 1, -1, 1, -1, 0, 1);

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Bd : TBd;                         { plateau de la partie }
  Turn, Mode, Level, SelC, LastP, Over, Hints, Thinking, Seed, NMoves, AutoAll : LongInt;
  Msg : String;                     { message de la barre d'etat }
  Hist : Array[0..MaxHist - 1] Of TBd;
  HTurn, HLast, HMoves : Array[0..MaxHist - 1] Of LongInt;
  NHist : LongInt;
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

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

Function Opp(P : LongInt) : LongInt;
Begin
  If P = PBlack Then Opp := PWhite Else Opp := PBlack;
End;

Function PlayerName(P : LongInt) : String;
Begin
  If P = PBlack Then PlayerName := 'Noir' Else PlayerName := 'Blanc';
End;

Function LevelName : String;
Begin
  Case Level Of
    0 : LevelName := 'Facile';
    2 : LevelName := 'Difficile';
  Else
    LevelName := 'Moyen';
  End;
End;

{ l'ordinateur joue-t-il la couleur P ? }
Function IsCpu(P : LongInt) : Boolean;
Begin
  IsCpu := ((Mode = 0) And (P = PWhite)) Or (AutoAll <> 0);
End;

{ ==================================================================== }
{ Regles (plateau B : 0 vide, 1 noir, 2 blanc ; case = ligne * 8 + col) }
{ ==================================================================== }

{ pions adverses encadres depuis la case P dans la direction D }
Function FlipsDir(Var B : TBd; P, D, Pl : LongInt) : LongInt;
Var R, C, N, O : LongInt;
Begin
  FlipsDir := 0;
  O := Opp(Pl);
  R := P Div 8 + DR[D]; C := P Mod 8 + DC[D]; N := 0;
  While (R >= 0) And (R < 8) And (C >= 0) And (C < 8) And (B[R * 8 + C] = O) Do
  Begin
    Inc(N);
    R := R + DR[D]; C := C + DC[D];
  End;
  If (N > 0) And (R >= 0) And (R < 8) And (C >= 0) And (C < 8) Then
    If B[R * 8 + C] = Pl Then FlipsDir := N;
End;

{ nombre de pions retournes par un coup en P (0 : coup impossible) }
Function Flips(Var B : TBd; P, Pl : LongInt) : LongInt;
Var D, N : LongInt;
Begin
  N := 0;
  If B[P] = Empty Then
    For D := 0 To 7 Do N := N + FlipsDir(B, P, D, Pl);
  Flips := N;
End;

Function Valid(Var B : TBd; P, Pl : LongInt) : Boolean;
Var D : LongInt;
Begin
  Valid := False;
  If B[P] <> Empty Then Exit;
  For D := 0 To 7 Do
    If FlipsDir(B, P, D, Pl) > 0 Then
    Begin
      Valid := True;
      Exit;
    End;
End;

{ poser un pion en P et retourner les pions encadres }
Procedure DoMove(Var B : TBd; P, Pl : LongInt);
Var D, N, K, R, C : LongInt;
Begin
  For D := 0 To 7 Do
  Begin
    N := FlipsDir(B, P, D, Pl);
    R := P Div 8; C := P Mod 8;
    For K := 1 To N Do
    Begin
      R := R + DR[D]; C := C + DC[D];
      B[R * 8 + C] := Pl;
    End;
  End;
  B[P] := Pl;
End;

Function Mobility(Var B : TBd; Pl : LongInt) : LongInt;
Var P, N : LongInt;
Begin
  N := 0;
  For P := 0 To 63 Do
    If Valid(B, P, Pl) Then Inc(N);
  Mobility := N;
End;

Function CountOf(Var B : TBd; Pl : LongInt) : LongInt;
Var P, N : LongInt;
Begin
  N := 0;
  For P := 0 To 63 Do
    If B[P] = Pl Then Inc(N);
  CountOf := N;
End;

{ ==================================================================== }
{ Ordinateur                                                            }
{ ==================================================================== }

{ evaluation pour Pl : poids des cases, mobilite ; en fin de partie, le
  nombre de pions }
Function Eval(Var B : TBd; Pl : LongInt) : LongInt;
Var P, S, O, Mp, Mo : LongInt;
Begin
  O := Opp(Pl);
  Mp := Mobility(B, Pl); Mo := Mobility(B, O);
  If (Mp = 0) And (Mo = 0) Then
  Begin
    S := CountOf(B, Pl) - CountOf(B, O);
    If S > 0 Then Eval := 100000 + S
    Else If S < 0 Then Eval := -100000 + S
    Else Eval := 0;
    Exit;
  End;
  S := 0;
  For P := 0 To 63 Do
    If B[P] = Pl Then S := S + Weight[P]
    Else If B[P] = O Then S := S - Weight[P];
  Eval := S + (Mp - Mo) * 8;
End;

{ recherche alpha-beta (negamax) : valeur de la position pour Pl, qui a
  le trait ; Depth demi-coups }
Function Search(Var B : TBd; Pl, Depth, Alpha, Beta : LongInt) : LongInt;
Var P, V, Best, Any : LongInt; T : TBd;
Begin
  If Depth <= 0 Then
  Begin
    Search := Eval(B, Pl);
    Exit;
  End;
  Best := -Inf; Any := 0;
  For P := 0 To 63 Do
    If Valid(B, P, Pl) Then
    Begin
      Any := 1;
      Move(B, T, SizeOf(TBd));
      DoMove(T, P, Pl);
      V := -Search(T, Opp(Pl), Depth - 1, -Beta, -Alpha);
      If V > Best Then Best := V;
      If Best > Alpha Then Alpha := Best;
      If Alpha >= Beta Then
      Begin
        Search := Best;
        Exit;
      End;
    End;
  If Any = 0 Then
  Begin
    { pas de coup : passer (ou fin de partie) }
    If Mobility(B, Opp(Pl)) = 0 Then Best := Eval(B, Pl)
    Else Best := -Search(B, Opp(Pl), Depth - 1, -Beta, -Alpha);
  End;
  Search := Best;
End;

{ meilleur coup de Pl selon le niveau (-1 : aucun) }
Function BestMove(Pl : LongInt) : LongInt;
Var P, V, Best, BestP : LongInt; T : TBd;
Begin
  Best := -Inf - 1; BestP := -1;
  For P := 0 To 63 Do
    If Valid(Bd, P, Pl) Then
    Begin
      Move(Bd, T, SizeOf(TBd));
      DoMove(T, P, Pl);
      Case Level Of
        0 : V := Flips(Bd, P, Pl) * 2 + Rnd(10);       { comme le prototype : glouton et hasard }
        1 : V := Eval(T, Pl) + Rnd(6);
      Else
        V := -Search(T, Opp(Pl), 3, -Inf, Inf);
      End;
      If V > Best Then
      Begin
        Best := V; BestP := P;
      End;
    End;
  BestMove := BestP;
End;

{ ==================================================================== }
{ Dessin (Y vers le bas)                                                }
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

{ pion : contour noir, ombre, reflet }
Procedure Piece(X, Y, P : LongInt);
Begin
  Disc(X + 2, Y + 2, Rad, CLR_DARKGRAY);
  Disc(X, Y, Rad, CLR_BLACK);
  If P = PWhite Then
  Begin
    Disc(X, Y, Rad - 1, CLR_PALEGRAY);
    Disc(X - 1, Y - 1, Rad - 3, CLR_WHITE);
  End
  Else
  Begin
    Disc(X - 6, Y - 6, 3, CLR_DARKGRAY);
  End;
End;

Procedure CellXY(P : LongInt; Var X, Y : LongInt);
Begin
  X := GX + 2 + (P Mod 8) * Cell;
  Y := GY + 2 + (P Div 8) * Cell;
End;

Procedure DrawCell(P : LongInt);
Var X, Y, N : LongInt; S : String;
Begin
  CellXY(P, X, Y);
  FBar(X, Y, X + Cell - 1, Y + Cell - 1, CLR_BLACK);
  FBar(X + 1, Y + 1, X + Cell - 1, Y + Cell - 1, CLR_DARKGREEN);
  If Bd[P] <> Empty Then Piece(X + Cell Div 2, Y + Cell Div 2, Bd[P])
  Else If (Over = 0) And Valid(Bd, P, Turn) And Not IsCpu(Turn) Then
  Begin
    { coup possible : point, ou (indices) nombre de pions retournes }
    If Hints <> 0 Then
    Begin
      N := Flips(Bd, P, Turn);
      S := IStr(N);
      FBar(X + 12, Y + 12, X + Cell - 12, Y + Cell - 12, CLR_YELLOW);
      OutTxt(X + (Cell - Length(S) * 8) Div 2, Y + (Cell - 16) Div 2, S, CLR_BLACK, CLR_YELLOW);
    End
    Else Disc(X + Cell Div 2, Y + Cell Div 2, 3, CLR_YELLOW);
  End;
  If P = LastP Then FBar(X + Cell Div 2 - 2, Y + Cell Div 2 - 2, X + Cell Div 2 + 2, Y + Cell Div 2 + 2, CLR_RED);
  If (P = SelC) And (Over = 0) Then
  Begin
    Edge(X + 2, Y + 2, X + Cell - 2, Y + Cell - 2, CLR_YELLOW, CLR_YELLOW);
    Edge(X + 3, Y + 3, X + Cell - 3, Y + Cell - 3, CLR_YELLOW, CLR_YELLOW);
  End;
End;

Procedure DrawBoard;
Var K, W, X, Y : LongInt;
Begin
  W := 8 * Cell + 4;
  Edge(GX - 2, GY - 2, GX + W + 1, GY + W + 1, CLR_DARKGRAY, CLR_WHITE);
  FBar(GX - 1, GY - 1, GX + W, GY + W, CLR_BLACK);
  For K := 0 To 63 Do DrawCell(K);
  { les quatre points du plateau }
  For K := 0 To 3 Do
  Begin
    X := GX + 2 + (2 + (K Mod 2) * 4) * Cell; Y := GY + 2 + (2 + (K Div 2) * 4) * Cell;
    Disc(X, Y, 3, CLR_BLACK);
  End;
End;

{ bouton poussoir de PM }
Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

{ case de score d'un joueur }
Procedure ScoreBox(Y, P : LongInt);
Var S : String;
Begin
  FBar(PX, Y, PX + PW - 1, Y + 53, CLR_WHITE);
  Edge(PX, Y, PX + PW - 1, Y + 53, CLR_DARKGRAY, CLR_WHITE);
  If (Turn = P) And (Over = 0) Then
  Begin
    Edge(PX + 1, Y + 1, PX + PW - 2, Y + 52, CLR_BLUE, CLR_BLUE);
    Edge(PX + 2, Y + 2, PX + PW - 3, Y + 51, CLR_BLUE, CLR_BLUE);
  End;
  Disc(PX + 28, Y + 27, Rad, CLR_BLACK);
  If P = PWhite Then
  Begin
    Disc(PX + 28, Y + 27, Rad - 1, CLR_PALEGRAY);
    Disc(PX + 27, Y + 26, Rad - 3, CLR_WHITE);
  End;
  OutTxt(PX + 56, Y + 6, PlayerName(P), CLR_BLACK, CLR_WHITE);
  S := IStr(CountOf(Bd, P));
  BigText(PX + 56, Y + 22, S, CLR_DARKBLUE, CLR_WHITE);
  If IsCpu(P) Then OutTxt(PX + 104, Y + 30, 'ordinateur', CLR_DARKGRAY, CLR_WHITE)
  Else If Mode = 0 Then OutTxt(PX + 104, Y + 30, 'vous', CLR_DARKGRAY, CLR_WHITE);
End;

Procedure DrawPanel;
Var S : String;
Begin
  BigText(PX + (PW - 7 * 16) Div 2, GY + 2, 'OTHELLO', CLR_DARKGREEN, CLR_PALEGRAY);
  ScoreBox(GY + 48, PBlack);
  ScoreBox(GY + 110, PWhite);
  If Mode = 0 Then S := 'Contre l''ordinateur' Else S := 'Deux joueurs';
  OutTxt(PX, GY + 176, S, CLR_BLACK, CLR_PALEGRAY);
  If Mode = 0 Then OutTxt(PX, GY + 194, 'Niveau : ' + LevelName, CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PX, GY + 212, 'Coups : ' + IStr(NMoves), CLR_BLACK, CLR_PALEGRAY);
  Button(PX, GY + 250, PW, 30, 'Nouvelle partie');
  Button(PX, GY + 288, PW, 30, 'Annuler le coup');
  If Hints <> 0 Then Button(PX, GY + 326, PW, 30, 'Masquer les indices')
  Else Button(PX, GY + 326, PW, 30, 'Indices');
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
  SetMark(CM_HINTS, Hints <> 0);
End;

{ message du tour a jouer }
Procedure TurnMsg;
Begin
  If IsCpu(Turn) Then Msg := 'L''ordinateur r' + Chr(130) + 'fl' + Chr(130) + 'chit...'
  Else If Mode = 0 Then Msg := 'A vous de jouer (Noir) : cliquez une case marqu' + Chr(130) + 'e d''un point.'
  Else Msg := 'Au tour de ' + PlayerName(Turn) + '.';
End;

Procedure NewGame;
Var K : LongInt;
Begin
  For K := 0 To 63 Do Bd[K] := Empty;
  Bd[27] := PWhite; Bd[28] := PBlack; Bd[35] := PBlack; Bd[36] := PWhite;
  Turn := PBlack; Over := 0; LastP := -1; SelC := 19; NHist := 0; NMoves := 0; Thinking := 0;
  If IsCpu(Turn) Then Thinking := 2;
  TurnMsg;
  Redraw;
End;

{ fin de partie : resultat }
Procedure GameOver;
Var Nb, Nw : LongInt; S : String;
Begin
  Over := 1;
  Nb := CountOf(Bd, PBlack); Nw := CountOf(Bd, PWhite);
  If Nb > Nw Then S := 'Noir gagne ' + IStr(Nb) + ' ' + Chr(133) + ' ' + IStr(Nw) + ' !'
  Else If Nw > Nb Then S := 'Blanc gagne ' + IStr(Nw) + ' ' + Chr(133) + ' ' + IStr(Nb) + ' !'
  Else S := 'Match nul (' + IStr(Nb) + ' ' + Chr(133) + ' ' + IStr(Nw) + ').';
  Msg := 'Partie termin' + Chr(130) + 'e : ' + S + '  F2 : nouvelle partie.';
  Redraw;
  If (Mode = 0) And (AutoAll = 0) Then
  Begin
    If Nb > Nw Then S := S + Chr(10) + 'Bravo, vous avez battu l''ordinateur !'
    Else If Nw > Nb Then S := S + Chr(10) + 'L''ordinateur gagne cette fois.';
  End;
  Dummy := Ask(S + Chr(10) + Chr(10) + 'Une nouvelle partie ?', 'Othello', MB_YESNO Or MB_QUERY);
  If Dummy = MBID_YES Then NewGame;
End;

{ apres un coup : joueur suivant, passe automatique, fin de partie }
Procedure NextTurn;
Var O : LongInt;
Begin
  O := Opp(Turn);
  If Mobility(Bd, O) > 0 Then
  Begin
    Turn := O;
    TurnMsg;
  End
  Else If Mobility(Bd, Turn) > 0 Then
  Begin
    { l'adversaire ne peut pas jouer : il passe son tour }
    TurnMsg;
    Msg := PlayerName(O) + ' ne peut pas jouer et passe son tour. ' + Msg;
  End
  Else
  Begin
    GameOver;
    Exit;
  End;
  If IsCpu(Turn) Then Thinking := 2;
  Redraw;
End;

Procedure Play(P : LongInt);
Begin
  If (Over <> 0) Or (P < 0) Or (P > 63) Then Exit;
  If Not Valid(Bd, P, Turn) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Msg := 'Coup impossible : il faut encadrer au moins un pion adverse.';
    Redraw;
    Exit;
  End;
  If NHist < MaxHist Then
  Begin
    Move(Bd, Hist[NHist], SizeOf(TBd));
    HTurn[NHist] := Turn; HLast[NHist] := LastP; HMoves[NHist] := NMoves;
    Inc(NHist);
  End;
  DoMove(Bd, P, Turn);
  LastP := P; SelC := P;
  Inc(NMoves);
  NextTurn;
End;

{ coup de l'ordinateur (minuterie : l'ecran montre d'abord le coup du
  joueur) }
Procedure CpuMove;
Var P : LongInt;
Begin
  If (Over <> 0) Or Not IsCpu(Turn) Then
  Begin
    Thinking := 0;
    Exit;
  End;
  P := BestMove(Turn);
  Thinking := 0;
  If P >= 0 Then
  Begin
    Play(P);
    { le joueur garde le curseur la ou il etait }
  End;
End;

{ annuler : en mode contre l'ordinateur, jusqu'au dernier coup du joueur }
Procedure Undo;
Begin
  If NHist = 0 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  Repeat
    Dec(NHist);
    Move(Hist[NHist], Bd, SizeOf(TBd));
    Turn := HTurn[NHist]; LastP := HLast[NHist]; NMoves := HMoves[NHist];
  Until (NHist = 0) Or Not IsCpu(Turn);
  Over := 0; Thinking := 0;
  If IsCpu(Turn) Then Thinking := 2;
  TurnMsg;
  Redraw;
End;

Procedure SetMode(M : LongInt);
Begin
  If M = Mode Then Exit;
  Mode := M;
  SetMarks;
  NewGame;
End;

Procedure SetLevel(L : LongInt);
Begin
  Level := L;
  SetMarks;
  Redraw;
End;

Procedure ToggleHints;
Begin
  Hints := 1 - Hints;
  SetMarks;
  Redraw;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_UNDO : Undo;
    CM_HINTS : ToggleHints;
    CM_VSCPU : SetMode(0);
    CM_TWO : SetMode(1);
    CM_EASY : SetLevel(0);
    CM_MEDIUM : SetLevel(1);
    CM_HARD : SetLevel(2);
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES : Dummy := Ask('Ayez le plus de pions de votre couleur ' + Chr(133) + ' la fin de la partie. ' +
                            'Chaque coup doit encadrer, en ligne droite (horizontale, verticale ou diagonale), ' +
                            'au moins un pion adverse entre le pion pos' + Chr(130) + ' et un de vos pions : ' +
                            'tous les pions encadr' + Chr(130) + 's sont retourn' + Chr(130) + 's. ' +
                            'Qui ne peut pas jouer passe son tour ; la partie finit quand personne ne peut ' +
                            'jouer. Noir commence.' + Chr(10) + Chr(10) +
                            'Souris : cliquer une case. Clavier : fl' + Chr(138) + 'ches, Entr' + Chr(130) +
                            'e ou Espace (jouer), H (indices), Ctrl+Z (annuler), F2 (nouvelle partie).',
                            'Othello - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
    CM_ABOUT : Dummy := Ask('Othello pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'OTHELLO.PAS de 7iles. Contre l''ordinateur (trois niveaux ; Difficile : ' +
                            'recherche alpha-b' + Chr(130) + 'ta) ou ' + Chr(133) + ' deux joueurs.' + Chr(10) +
                            'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                            'A propos d''Othello', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Function HitCell(X, Y : LongInt) : LongInt;
Var C, R : LongInt;
Begin
  HitCell := -1;
  If (X < GX + 2) Or (Y < GY + 2) Then Exit;
  C := (X - GX - 2) Div Cell; R := (Y - GY - 2) Div Cell;
  If (C >= 0) And (C < 8) And (R >= 0) And (R < 8) Then HitCell := R * 8 + C;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, P : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  P := HitCell(X, Y);
  If P >= 0 Then
  Begin
    SelC := P;
    If (Thinking = 0) And Not IsCpu(Turn) Then Play(P) Else Redraw;
    Exit;
  End;
  If (X >= PX) And (X < PX + PW) Then
  Begin
    If (Y >= GY + 250) And (Y < GY + 280) Then NewGame
    Else If (Y >= GY + 288) And (Y < GY + 318) Then Undo
    Else If (Y >= GY + 326) And (Y < GY + 356) Then ToggleHints;
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
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_LEFT Then Begin If SelC Mod 8 > 0 Then Dec(SelC); Redraw; Exit; End;
    If Vk = VK_RIGHT Then Begin If SelC Mod 8 < 7 Then Inc(SelC); Redraw; Exit; End;
    If Vk = VK_UP Then Begin If SelC >= 8 Then SelC := SelC - 8; Redraw; Exit; End;
    If Vk = VK_DOWN Then Begin If SelC < 56 Then SelC := SelC + 8; Redraw; Exit; End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_SPACE) Then
    Begin
      If (Thinking = 0) And Not IsCpu(Turn) Then Play(SelC);
      Exit;
    End;
  End;
  If (Fl And KC_CTRL) <> 0 Then
  Begin
    If (Ch = 26) Or (Ch = Ord('z')) Or (Ch = Ord('Z')) Then Undo Else KeyChar := False;
    Exit;
  End;
  If ((Fl And KC_CHAR) = 0) Or ((Fl And KC_ALT) <> 0) Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Ch = 72) Or (Ch = 104) Then ToggleHints             { H }
  Else If (Ch = 78) Or (Ch = 110) Then NewGame            { N (comme le prototype) }
  Else If Ch = 32 Then
  Begin
    If (Thinking = 0) And Not IsCpu(Turn) Then Play(SelC);
  End
  Else KeyChar := False;
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
      If Lo16(Mp1) = 1 Then
        If Thinking > 0 Then
        Begin
          { un tour de minuterie d'attente : le coup du joueur est affiche }
          Dec(Thinking);
          If Thinking = 0 Then
          Begin
            Thinking := 1;
            CpuMove;
          End;
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
  Mode := 0; Level := 1; Hints := 0; Msg := ''; AutoAll := 0;
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
  Dummy := WinRegisterClass(Hab, Z('OTHELLO'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('OTHELLO'), Z2('Othello'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_TEXT, 0, CM_HINTS, '~Indices' + Chr(9) + 'H');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, MIA_CHECKED, CM_VSCPU, '~Contre l''ordinateur');
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
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos d''Othello');
  MenuClose(H2, 2);
  MenuClose(H0, 2);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  { zone client de 612 x 412 (ecran plus petit : coin haut gauche) }
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
  Dummy := WinStartTimer(Hab, Client, 1, 300);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
