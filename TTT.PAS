{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: TTT - Tic-Tac-Toe pour le Presentation Manager d'OS/2-0
                (dossier Jeux du bureau).
}

Program TTT;

{$R-,S-,I-}

{ Compilation : OS2PC TTT.PAS   (produit TTT.EXE)

  Portage vers OS/2-0 du prototype TTT.PAS du depot 7iles (Turbo Pascal,
  mode texte : grille dessinee en caracteres, cases choisies par les
  touches 1 a 9) : fenetre de Presentation Manager avec menus, grille en
  relief, X et O dessines, ligne gagnante barree, panneau des victoires,
  barre d'etat et apparence d'OS/2.

  But : aligner trois de ses signes (horizontale, verticale ou diagonale)
  sur la grille de 3 x 3. Grille pleine sans alignement : partie nulle.
  Comme le prototype, vous avez les X (verts) et l'ordinateur les O
  (rouges) ; l'ordinateur commence (menu Partie : vous pouvez commencer).
  L'ordinateur joue la strategie du prototype (niveau Moyen : premier coup
  dans le coin, attaque, defense) ; Facile : il ne fait que gagner ou
  jouer au hasard ; Difficile : il cherche tous les coups et ne perd
  jamais. Deux joueurs : X et O a tour de role.

  Souris : cliquer une case. Clavier : 1 a 9 (cases numerotees comme le
  prototype, de gauche a droite et de haut en bas), fleches et Entree ou
  Espace, Ctrl+Z (annuler), F2 (nouvelle partie), F1 (regles).
  Parametres : /SEED:n ; /AUTO (l'ordinateur joue les deux signes). }

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
  VK_UP = $16;
  CM_NEW = 101; CM_UNDO = 102; CM_YOUFIRST = 103; CM_QUIT = 104;
  CM_VSCPU = 111; CM_TWO = 112;
  CM_EASY = 121; CM_MEDIUM = 122; CM_HARD = 123;
  CM_RULES = 301; CM_ABOUT = 302;
  PX = 1; PO = 2;                         { signes du prototype : 1 = X (humain), 2 = O (ordinateur) }
  { disposition (zone client, Y vers le bas) }
  Cs = 110; BX0 = 22; BY0 = 22;
  PnX = 374; PW = 176;
  CWant = 562; CHWant = 400;
  Lines : Array[0..7, 0..2] Of LongInt = ((0, 1, 2), (3, 4, 5), (6, 7, 8), (0, 3, 6), (1, 4, 7), (2, 5, 8),
                                          (0, 4, 8), (2, 4, 6));

Type
  TBd = Array[0..8] Of LongInt;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Bd : TBd;
  Turn, Mode, Level, YouFirst, Sel, Hover, Over, Winner, WinLine, Thinking, Seed, AutoAll, NMoves, Wait : LongInt;
  Hist : Array[0..8] Of LongInt;
  Wins : Array[0..2] Of LongInt;                 { nuls, X, O }
  Msg : String;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;
  FontH : LongInt;
  Qmsg : Array[0..7] Of LongInt;

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
  IsCpu := (AutoAll <> 0) Or ((Mode = 0) And (P = PO));
End;

Function PName(P : LongInt) : String;
Begin
  If P = PX Then
  Begin
    If (Mode = 0) And (AutoAll = 0) Then PName := 'Vous (X)' Else PName := 'Joueur X';
  End
  Else
  Begin
    If Mode = 0 Then PName := 'Ordinateur (O)' Else PName := 'Joueur O';
  End;
End;

{ ==================================================================== }
{ Regles et ordinateur                                                  }
{ ==================================================================== }

{ ligne gagnante de P (0 a 7), -1 sinon }
Function WinOf(Var B : TBd; P : LongInt) : LongInt;
Var L : LongInt;
Begin
  WinOf := -1;
  For L := 0 To 7 Do
    If (B[Lines[L, 0]] = P) And (B[Lines[L, 1]] = P) And (B[Lines[L, 2]] = P) Then
    Begin
      WinOf := L;
      Exit;
    End;
End;

Function Full(Var B : TBd) : Boolean;
Var I : LongInt;
Begin
  Full := True;
  For I := 0 To 8 Do If B[I] = 0 Then Full := False;
End;

{ case qui complete une ligne de P (deux signes de P et une case vide) }
Function Complete(Var B : TBd; P : LongInt) : LongInt;
Var L, K, N, E : LongInt;
Begin
  Complete := -1;
  For L := 0 To 7 Do
  Begin
    N := 0; E := -1;
    For K := 0 To 2 Do
      If B[Lines[L, K]] = P Then Inc(N)
      Else If B[Lines[L, K]] = 0 Then E := Lines[L, K];
    If (N = 2) And (E >= 0) Then
    Begin
      Complete := E;
      Exit;
    End;
  End;
End;

Function Count(Var B : TBd; P : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To 8 Do If B[I] = P Then Inc(N);
  Count := N;
End;

Function RandomFree(Var B : TBd) : LongInt;
Var I, N, K : LongInt;
Begin
  N := 0;
  For I := 0 To 8 Do If B[I] = 0 Then Inc(N);
  RandomFree := -1;
  If N = 0 Then Exit;
  K := Rnd(N);
  For I := 0 To 8 Do
    If B[I] = 0 Then
    Begin
      If K = 0 Then
      Begin
        RandomFree := I;
        Exit;
      End;
      Dec(K);
    End;
End;

{ strategie du prototype (ComputerPlay) : grille vide -> coin en haut a
  droite ; premier coup de l'adversaire -> centre ; attaque (completer une
  ligne), coins opposes, defense (bloquer une ligne), puis premiere case
  libre. Le prototype n'examinait qu'une partie des lignes : toutes le
  sont ici }
Function ProtoMove(Var B : TBd; P : LongInt) : LongInt;
Var M, Me, Op : LongInt;
Begin
  Me := Count(B, P); Op := Count(B, Opp(P));
  M := -1;
  If Me + Op = 0 Then M := 2
  Else If (Op = 1) And (Me = 0) And (B[4] = 0) Then M := 4;
  If M < 0 Then M := Complete(B, P);
  If M < 0 Then
  Begin
    If (B[2] = P) And (B[4] = 0) And (B[6] = 0) And (Me = 1) Then M := 6
    Else If (B[2] = P) And (B[6] = P) And (B[8] = 0) And (Me = 2) Then M := 8
    Else If (B[2] = P) And (B[6] = P) And (B[0] = 0) Then M := 0;
  End;
  If M < 0 Then M := Complete(B, Opp(P));
  If M < 0 Then
  Begin
    M := 0;
    While (M < 8) And (B[M] <> 0) Do Inc(M);
  End;
  ProtoMove := M;
End;

{ recherche complete (minimax) : +10 - profondeur si P gagne }
Function Search(Var B : TBd; P, Me, Depth : LongInt) : LongInt;
Var I, V, Best : LongInt;
Begin
  If WinOf(B, Me) >= 0 Then Begin Search := 10 - Depth; Exit; End;
  If WinOf(B, Opp(Me)) >= 0 Then Begin Search := Depth - 10; Exit; End;
  If Full(B) Then Begin Search := 0; Exit; End;
  If P = Me Then Best := -100 Else Best := 100;
  For I := 0 To 8 Do
    If B[I] = 0 Then
    Begin
      B[I] := P;
      V := Search(B, Opp(P), Me, Depth + 1);
      B[I] := 0;
      If P = Me Then
      Begin
        If V > Best Then Best := V;
      End
      Else If V < Best Then Best := V;
    End;
  Search := Best;
End;

Function PerfectMove(Var B : TBd; P : LongInt) : LongInt;
Var I, V, Best, N, K : LongInt; Cand : Array[0..8] Of LongInt;
Begin
  Best := -100; N := 0;
  For I := 0 To 8 Do
    If B[I] = 0 Then
    Begin
      B[I] := P;
      V := Search(B, Opp(P), P, 1);
      B[I] := 0;
      If V > Best Then
      Begin
        Best := V; N := 0;
      End;
      If V = Best Then
      Begin
        Cand[N] := I;
        Inc(N);
      End;
    End;
  If N = 0 Then PerfectMove := -1
  Else
  Begin
    K := Rnd(N);
    PerfectMove := Cand[K];
  End;
End;

Function BestCell(P : LongInt) : LongInt;
Var M : LongInt;
Begin
  Case Level Of
    0 :
      Begin
        M := Complete(Bd, P);
        If M < 0 Then M := RandomFree(Bd);
      End;
    2 : M := PerfectMove(Bd, P);
  Else
    M := ProtoMove(Bd, P);
  End;
  BestCell := M;
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

{ trait epais de (X1, Y1) a (X2, Y2), demi-epaisseur T }
Procedure Thick(X1, Y1, X2, Y2, T, C : LongInt);
Var K, N, X, Y, Dx, Dy : LongInt;
Begin
  Dx := X2 - X1; Dy := Y2 - Y1;
  If Abs(Dy) >= Abs(Dx) Then
  Begin
    N := Abs(Dy);
    If N = 0 Then N := 1;
    For K := 0 To N Do
    Begin
      Y := Y1 + K * Dy Div N; X := X1 + K * Dx Div N;
      FBar(X - T, Y, X + T, Y, C);
    End;
  End
  Else
  Begin
    N := Abs(Dx);
    For K := 0 To N Do
    Begin
      X := X1 + K * Dx Div N; Y := Y1 + K * Dy Div N;
      FBar(X, Y - T, X, Y + T, C);
    End;
  End;
End;

Procedure Ring(X, Y, R, T, C, Bg : LongInt);
Begin
  Disc(X, Y, R, C);
  Disc(X, Y, R - T, Bg);
End;

Procedure CellXY(Q : LongInt; Var X, Y : LongInt);
Begin
  X := BX0 + (Q Mod 3) * Cs;
  Y := BY0 + (Q Div 3) * Cs;
End;

{ signe P dans une case de coin (X, Y) }
Procedure Sign(X, Y, P, Bg : LongInt);
Var M : LongInt;
Begin
  M := 24;
  If P = PX Then
  Begin
    Thick(X + M + 2, Y + M + 2, X + Cs - M + 2, Y + Cs - M + 2, 6, CLR_DARKGRAY);
    Thick(X + Cs - M + 2, Y + M + 2, X + M + 2, Y + Cs - M + 2, 6, CLR_DARKGRAY);
    Thick(X + M, Y + M, X + Cs - M, Y + Cs - M, 6, CLR_DARKGREEN);
    Thick(X + Cs - M, Y + M, X + M, Y + Cs - M, 6, CLR_DARKGREEN);
    Thick(X + M, Y + M, X + Cs - M, Y + Cs - M, 3, CLR_GREEN);
    Thick(X + Cs - M, Y + M, X + M, Y + Cs - M, 3, CLR_GREEN);
  End
  Else If P = PO Then
  Begin
    Ring(X + Cs Div 2 + 2, Y + Cs Div 2 + 2, Cs Div 2 - M + 6, 12, CLR_DARKGRAY, Bg);
    Ring(X + Cs Div 2, Y + Cs Div 2, Cs Div 2 - M + 6, 12, CLR_DARKRED, Bg);
    Ring(X + Cs Div 2, Y + Cs Div 2, Cs Div 2 - M + 4, 8, CLR_RED, Bg);
  End;
End;

Function InWin(Q : LongInt) : Boolean;
Var K : LongInt;
Begin
  InWin := False;
  If WinLine < 0 Then Exit;
  For K := 0 To 2 Do If Lines[WinLine, K] = Q Then InWin := True;
End;

Procedure DrawCell(Q : LongInt);
Var X, Y, Bg : LongInt;
Begin
  CellXY(Q, X, Y);
  Bg := CLR_WHITE;
  If InWin(Q) Then Bg := CLR_YELLOW
  Else If (Over = 0) And (Bd[Q] = 0) And ((Q = Hover) Or (Q = Sel)) And Not IsCpu(Turn) Then Bg := CLR_CYAN;
  FBar(X + 4, Y + 4, X + Cs - 5, Y + Cs - 5, Bg);
  OutTxt(X + 8, Y + 6, IStr(Q + 1), CLR_PALEGRAY, Bg);
  If (Q = Sel) And (Over = 0) And Not IsCpu(Turn) Then
  Begin
    Edge(X + 6, Y + 6, X + Cs - 7, Y + Cs - 7, CLR_DARKBLUE, CLR_DARKBLUE);
    Edge(X + 7, Y + 7, X + Cs - 8, Y + Cs - 8, CLR_DARKBLUE, CLR_DARKBLUE);
  End;
  Sign(X, Y, Bd[Q], Bg);
End;

{ trait sur la ligne gagnante }
Procedure Strike;
Var X1, Y1, X2, Y2 : LongInt;
Begin
  If WinLine < 0 Then Exit;
  CellXY(Lines[WinLine, 0], X1, Y1);
  CellXY(Lines[WinLine, 2], X2, Y2);
  X1 := X1 + Cs Div 2; Y1 := Y1 + Cs Div 2; X2 := X2 + Cs Div 2; Y2 := Y2 + Cs Div 2;
  If Y1 = Y2 Then Begin X1 := X1 - 40; X2 := X2 + 40; End
  Else If X1 = X2 Then Begin Y1 := Y1 - 40; Y2 := Y2 + 40; End
  Else If X1 < X2 Then Begin X1 := X1 - 30; Y1 := Y1 - 30; X2 := X2 + 30; Y2 := Y2 + 30; End
  Else Begin X1 := X1 + 30; Y1 := Y1 - 30; X2 := X2 - 30; Y2 := Y2 + 30; End;
  Thick(X1, Y1, X2, Y2, 4, CLR_DARKBLUE);
  Thick(X1, Y1, X2, Y2, 2, CLR_BLUE);
End;

Procedure DrawBoard;
Var Q, K : LongInt;
Begin
  Edge(BX0 - 6, BY0 - 6, BX0 + 3 * Cs + 5, BY0 + 3 * Cs + 5, CLR_WHITE, CLR_DARKGRAY);
  Edge(BX0 - 5, BY0 - 5, BX0 + 3 * Cs + 4, BY0 + 3 * Cs + 4, CLR_WHITE, CLR_DARKGRAY);
  FBar(BX0 - 4, BY0 - 4, BX0 + 3 * Cs + 3, BY0 + 3 * Cs + 3, CLR_DARKBLUE);
  For Q := 0 To 8 Do DrawCell(Q);
  For K := 1 To 2 Do
  Begin
    FBar(BX0 + K * Cs - 4, BY0 - 4, BX0 + K * Cs + 3, BY0 + 3 * Cs + 3, CLR_DARKBLUE);
    FBar(BX0 - 4, BY0 + K * Cs - 4, BX0 + 3 * Cs + 3, BY0 + K * Cs + 3, CLR_DARKBLUE);
    FBar(BX0 + K * Cs - 1, BY0 - 4, BX0 + K * Cs, BY0 + 3 * Cs + 3, CLR_BLUE);
    FBar(BX0 - 4, BY0 + K * Cs - 1, BX0 + 3 * Cs + 3, BY0 + K * Cs, CLR_BLUE);
  End;
  Strike;
End;

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

{ petit signe (panneau) }
Procedure MiniSign(X, Y, P : LongInt);
Begin
  If P = PX Then
  Begin
    Thick(X - 12, Y - 12, X + 12, Y + 12, 3, CLR_DARKGREEN);
    Thick(X + 12, Y - 12, X - 12, Y + 12, 3, CLR_DARKGREEN);
    Thick(X - 12, Y - 12, X + 12, Y + 12, 1, CLR_GREEN);
    Thick(X + 12, Y - 12, X - 12, Y + 12, 1, CLR_GREEN);
  End
  Else
  Begin
    Ring(X, Y, 15, 6, CLR_DARKRED, CLR_WHITE);
    Ring(X, Y, 14, 4, CLR_RED, CLR_WHITE);
  End;
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
  MiniSign(PnX + 27, Y + 27, P);
  S := PName(P);
  OutTxt(PnX + 52, Y + 6, S, CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 52, Y + 26, 'Victoires : ' + IStr(Wins[P]), CLR_DARKBLUE, CLR_WHITE);
End;

Procedure DrawPanel;
Var S : String;
Begin
  BigText(PnX + (PW - 11 * 16) Div 2, 18, 'TIC-TAC-TOE', CLR_DARKBLUE, CLR_PALEGRAY);
  PlayerBox(66, PX);
  PlayerBox(128, PO);
  OutTxt(PnX, 194, 'Parties nulles : ' + IStr(Wins[0]), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 212, 'Coups jou' + Chr(130) + 's : ' + IStr(NMoves), CLR_BLACK, CLR_PALEGRAY);
  If Mode = 0 Then
  Begin
    Case Level Of
      0 : S := 'Facile';
      2 : S := 'Difficile';
    Else
      S := 'Moyen';
    End;
    OutTxt(PnX, 230, 'Niveau : ' + S, CLR_BLACK, CLR_PALEGRAY);
  End
  Else OutTxt(PnX, 230, 'Deux joueurs', CLR_BLACK, CLR_PALEGRAY);
  Button(PnX, 284, PW, 30, 'Nouvelle partie');
  Button(PnX, 320, PW, 30, 'Annuler le coup');
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

{ redessiner une case seulement (survol, curseur) }
Procedure ShowCell(Q : LongInt);
Begin
  If (Client = 0) Or (Q < 0) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  DrawCell(Q);
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
  SetMark(CM_YOUFIRST, YouFirst <> 0);
End;

Procedure TurnMsg;
Begin
  If IsCpu(Turn) Then Msg := 'L''ordinateur r' + Chr(130) + 'fl' + Chr(130) + 'chit...'
  Else If Mode = 0 Then Msg := 'A vous (X) : cliquez une case (ou touches 1 ' + Chr(133) + ' 9).'
  Else Msg := 'Au tour du ' + PName(Turn) + '.';
End;

Procedure NewGame;
Var Q : LongInt;
Begin
  For Q := 0 To 8 Do Bd[Q] := 0;
  { comme le prototype, l'ordinateur (O) commence, sauf si vous le choisissez }
  If (Mode = 0) And (YouFirst = 0) Then Turn := PO Else Turn := PX;
  Over := 0; Winner := 0; WinLine := -1; NMoves := 0; Sel := 4; Hover := -1; Thinking := 0;
  TurnMsg;
  If IsCpu(Turn) Then Thinking := 12;
  Redraw;
End;

Procedure GameOver;
Var S : String;
Begin
  Over := 1;
  Inc(Wins[Winner]);
  If Winner = 0 Then S := 'Partie nulle !'
  Else If (Mode = 0) And (AutoAll = 0) Then
  Begin
    If Winner = PX Then S := 'Vous avez gagn' + Chr(130) + ' !' Else S := 'Vous avez perdu !';
  End
  Else S := PName(Winner) + ' gagne : trois signes align' + Chr(130) + 's !';
  Msg := S + '  F2 : nouvelle partie.';
  Redraw;
  If AutoAll = 0 Then
    If Ask(S + Chr(10) + Chr(10) + 'Une nouvelle partie ?', 'Tic-Tac-Toe', MB_YESNO Or MB_QUERY) = MBID_YES Then
      NewGame;
End;

Procedure Play(Q : LongInt);
Begin
  If (Over <> 0) Or (Q < 0) Or (Q > 8) Then Exit;
  If Bd[Q] <> 0 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Msg := 'Cette case est d' + Chr(130) + 'j' + Chr(133) + ' prise.';
    Redraw;
    Exit;
  End;
  Bd[Q] := Turn;
  Hist[NMoves] := Q;
  Inc(NMoves);
  WinLine := WinOf(Bd, Turn);
  If WinLine >= 0 Then
  Begin
    Winner := Turn;
    GameOver;
    Exit;
  End;
  If Full(Bd) Then
  Begin
    Winner := 0;
    GameOver;
    Exit;
  End;
  Turn := Opp(Turn);
  TurnMsg;
  If IsCpu(Turn) Then Thinking := 12;
  Redraw;
End;

Procedure CpuMove;
Begin
  Thinking := 0;
  If (Over <> 0) Or Not IsCpu(Turn) Then Exit;
  Play(BestCell(Turn));
End;

Procedure Undo;
Begin
  If (NMoves = 0) Or (Thinking <> 0) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  If Over <> 0 Then Dec(Wins[Winner]);
  Repeat
    Dec(NMoves);
    Turn := Bd[Hist[NMoves]];
    Bd[Hist[NMoves]] := 0;
  Until (NMoves = 0) Or Not IsCpu(Turn);
  Over := 0; Winner := 0; WinLine := -1;
  TurnMsg;
  If IsCpu(Turn) Then Thinking := 12;
  Redraw;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_UNDO : Undo;
    CM_YOUFIRST : Begin YouFirst := 1 - YouFirst; SetMarks; NewGame; End;
    CM_VSCPU : Begin Mode := 0; SetMarks; NewGame; End;
    CM_TWO : Begin Mode := 1; SetMarks; NewGame; End;
    CM_EASY : Begin Level := 0; SetMarks; Redraw; End;
    CM_MEDIUM : Begin Level := 1; SetMarks; Redraw; End;
    CM_HARD : Begin Level := 2; SetMarks; Redraw; End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        LClr;
        LAdd('Alignez trois de vos signes (horizontale, verticale ou diagonale) sur la grille de 3 x 3. ' +
             'Grille pleine sans alignement : partie nulle.' + Chr(10) + Chr(10));
        LAdd('Contre l''ordinateur, vous avez les X (verts) et l''ordinateur les O (rouges) ; comme dans le ' +
             'prototype, l''ordinateur commence (menu Partie : Vous commencez). Niveaux : Facile, Moyen ' +
             '(la strat' + Chr(130) + 'gie du prototype), Difficile (l''ordinateur ne perd jamais).' + Chr(10) +
             Chr(10));
        LAdd('Souris : cliquer une case. Clavier : 1 ' + Chr(133) + ' 9 (cases num' + Chr(130) +
             'rot' + Chr(130) + 'es de gauche ' + Chr(133) + ' droite et de haut en bas), fl' + Chr(138) +
             'ches et Entr' + Chr(130) + 'e, Ctrl+Z (annuler), F2 (nouvelle partie).');
        Dummy := LMsgBox('Tic-Tac-Toe - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Tic-Tac-Toe pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'TTT.PAS de 7iles (mode texte) : contre l''ordinateur ou ' + Chr(133) +
                            ' deux joueurs.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et compil' +
                            Chr(130) + ' par OS2PC.', 'A propos de Tic-Tac-Toe', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Function CellAt(X, Y : LongInt) : LongInt;
Begin
  CellAt := -1;
  If (X >= BX0) And (X < BX0 + 3 * Cs) And (Y >= BY0) And (Y < BY0 + 3 * Cs) Then
    CellAt := ((Y - BY0) Div Cs) * 3 + (X - BX0) Div Cs;
End;

Function Human : Boolean;
Begin
  Human := (Over = 0) And Not IsCpu(Turn) And (Thinking = 0);
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, Q : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  Q := CellAt(X, Y);
  If Q >= 0 Then
  Begin
    If Human Then Begin Sel := Q; Play(Q); End;
    Exit;
  End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 284) And (Y < 314) Then NewGame
    Else If (Y >= 320) And (Y < 350) Then Undo;
  End;
End;

Procedure MoveSel(D : LongInt);
Var Old : LongInt;
Begin
  Old := Sel;
  Case D Of
    0 : If Sel Mod 3 > 0 Then Dec(Sel);
    1 : If Sel Mod 3 < 2 Then Inc(Sel);
    2 : If Sel > 2 Then Sel := Sel - 3;
    3 : If Sel < 6 Then Sel := Sel + 3;
  End;
  If Old <> Sel Then
  Begin
    ShowCell(Old);
    ShowCell(Sel);
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
    If Vk = VK_LEFT Then Begin MoveSel(0); Exit; End;
    If Vk = VK_RIGHT Then Begin MoveSel(1); Exit; End;
    If Vk = VK_UP Then Begin MoveSel(2); Exit; End;
    If Vk = VK_DOWN Then Begin MoveSel(3); Exit; End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_SPACE) Then
    Begin
      If Human Then Play(Sel);
      Exit;
    End;
  End;
  If ((Fl And KC_CHAR) <> 0) And ((Fl And KC_ALT) = 0) Then
  Begin
    If (Ch >= 49) And (Ch <= 57) Then
    Begin
      If Human Then Begin Sel := Ch - 49; Play(Ch - 49); End;
      Exit;
    End;
    If Ch = 32 Then
    Begin
      If Human Then Play(Sel);
      Exit;
    End;
  End;
  KeyChar := False;
End;

Procedure TimerTick;
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
Var Rc : Array[0..3] Of LongInt; Q, Old : LongInt;
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
        Q := CellAt(S16(Mp1), CH - 1 - S16(Mp1 Shr 16));
        If Q <> Hover Then
        Begin
          Old := Hover;
          Hover := Q;
          If Human Then
          Begin
            ShowCell(Old);
            ShowCell(Q);
          End;
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
  Msg := ''; AutoAll := 0; Mode := 0; Level := 1; YouFirst := 0; Over := 1; Thinking := 0; WinLine := -1;
  Wins[0] := 0; Wins[1] := 0; Wins[2] := 0; Wait := 0; Sel := 4; Hover := -1;
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
  Dummy := WinRegisterClass(Hab, Z('TTT'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('TTT'), Z2('Tic-Tac-Toe'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_TEXT, 0, CM_YOUFIRST, '~Vous commencez');
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
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Tic-Tac-Toe');
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
