{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: SUDOKU - jeu de Sudoku pour le Presentation Manager
                d'OS/2-0 (dossier Jeux du bureau).
}

Program SUDOKU;

{$R-,S-,I-}

{ Compilation : OS2PC SUDOKU.PAS   (produit SUDOKU.EXE)

  Portage vers OS/2-0 du prototype SODOKU.PAS du depot 7iles (Turbo
  Pascal et BGI, clavier seulement) : fenetre de Presentation Manager avec
  menus, souris, pave numerique, barre d'etat et apparence d'OS/2.

  But : remplir la grille de 9 x 9 cases pour que chaque ligne, chaque
  colonne et chaque carre de 3 x 3 contienne une fois chacun des chiffres
  de 1 a 9. Les chiffres donnes (sur fond gris) ne se changent pas.

  Chaque grille est construite ici : une solution complete (retour
  arriere, chiffres dans un ordre au hasard), puis des cases retirees par
  paires symetriques tant que la grille garde une seule solution (le
  prototype ne verifiait que les lignes et les colonnes). Niveaux : Facile
  (38 chiffres donnes environ), Moyen (30), Difficile (25).

  Souris : cliquer une case, puis un chiffre du pave (ou taper le
  chiffre) ; bouton 2 sur une case : l'effacer. Clavier : fleches, 1 a 9,
  0, Suppr, Retour arriere ou Espace (effacer), Ctrl+Z (annuler), I
  (indice : le bon chiffre dans la case choisie), V (verifier), F2
  (nouvelle partie), F1 (regles). Les chiffres en conflit (meme chiffre
  deux fois dans une ligne, une colonne ou un carre) sont en rouge.
  Parametre : /SEED:n (grille reproductible, pour les essais). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_BUTTON2DOWN = $0074; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_SPACE = $0E; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_DELETE = $1B;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_GREEN = 4; CLR_CYAN = 5; CLR_YELLOW = 6;
  CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12; CLR_DARKCYAN = 13; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_RESTART = 102; CM_UNDO = 103; CM_HINT = 104; CM_CHECK = 105; CM_SOLVE = 106; CM_QUIT = 107;
  CM_EASY = 111; CM_MEDIUM = 112; CM_HARD = 113;
  CM_RULES = 301; CM_ABOUT = 302;
  { disposition (coordonnees de la zone client, Y vers le bas) }
  Cell = 40; GX = 20; GY = 18;
  PX = 410; PY = 40; BW = 58; BH = 46;
  MaxUndo = 400;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  { grille : solution, chiffres donnes, chiffres de la case (0 vide),
    indices montres, erreurs signalees par Verifier }
  Sol, Given, Cur, Hinted, Wrong : Array[0..80] Of LongInt;
  Work : Array[0..80] Of LongInt;
  UCell, UOld : Array[0..MaxUndo - 1] Of LongInt;
  NUndo, SelC, Level, Seed, GameNo, Elapsed, Done, Solved, Count : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..511] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;     { police 8 x 16 du VGA (chiffres agrandis) }
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
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
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

Function Two(V : LongInt) : String;
Begin
  If V < 10 Then Two := '0' + IStr(V) Else Two := IStr(V);
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

Function LevelName : String;
Begin
  Case Level Of
    0 : LevelName := 'Facile';
    2 : LevelName := 'Difficile';
  Else
    LevelName := 'Moyen';
  End;
End;

Function TimeStr : String;
Begin
  TimeStr := Two(Elapsed Div 60) + ':' + Two(Elapsed Mod 60);
End;

{ ==================================================================== }
{ Grilles : construction et resolution                                  }
{ ==================================================================== }

{ le chiffre D peut-il aller dans la case P de Work ? }
Function CanPut(P, D : LongInt) : Boolean;
Var R, C, K, BR, BC : LongInt;
Begin
  CanPut := False;
  R := P Div 9; C := P Mod 9;
  For K := 0 To 8 Do
  Begin
    If Work[R * 9 + K] = D Then Exit;
    If Work[K * 9 + C] = D Then Exit;
  End;
  BR := (R Div 3) * 3; BC := (C Div 3) * 3;
  For K := 0 To 8 Do
    If Work[(BR + K Div 3) * 9 + BC + K Mod 3] = D Then Exit;
  CanPut := True;
End;

{ remplir Work a partir de la case P (chiffres dans un ordre au hasard) }
Function Fill(P : LongInt) : Boolean;
Var Ord9 : Array[0..8] Of LongInt; K, J, T : LongInt;
Begin
  If P >= 81 Then
  Begin
    Fill := True;
    Exit;
  End;
  Fill := False;
  K := 0;
  While K < 9 Do
  Begin
    Ord9[K] := K + 1;
    Inc(K);
  End;
  K := 8;
  While K > 0 Do
  Begin
    J := Rnd(K + 1);
    T := Ord9[K]; Ord9[K] := Ord9[J]; Ord9[J] := T;
    Dec(K);
  End;
  K := 0;
  While K < 9 Do
  Begin
    If CanPut(P, Ord9[K]) Then
    Begin
      Work[P] := Ord9[K];
      If Fill(P + 1) Then
      Begin
        Fill := True;
        Exit;
      End;
      Work[P] := 0;
    End;
    Inc(K);
  End;
End;

{ nombre de solutions de Work (on s'arrete a 2) : case vide qui a le
  moins de chiffres possibles d'abord }
Procedure Solve;
Var P, Best, BestN, N, D : LongInt;
Begin
  If Count >= 2 Then Exit;
  Best := -1; BestN := 10;
  P := 0;
  While P < 81 Do
  Begin
    If Work[P] = 0 Then
    Begin
      N := 0;
      D := 1;
      While D <= 9 Do
      Begin
        If CanPut(P, D) Then Inc(N);
        Inc(D);
      End;
      If N < BestN Then
      Begin
        BestN := N; Best := P;
      End;
      If N = 0 Then P := 81;
    End;
    Inc(P);
  End;
  If Best < 0 Then
  Begin
    Inc(Count);
    Exit;
  End;
  If BestN = 0 Then Exit;
  D := 1;
  While (D <= 9) And (Count < 2) Do
  Begin
    If CanPut(Best, D) Then
    Begin
      Work[Best] := D;
      Solve;
      Work[Best] := 0;
    End;
    Inc(D);
  End;
End;

Function Unique : Boolean;
Begin
  Count := 0;
  Solve;
  Unique := Count = 1;
End;

{ nouvelle grille au niveau courant }
Procedure Build;
Var Perm : Array[0..40] Of LongInt; K, J, T, P, Q, A, B, Target, Left : LongInt;
Begin
  For K := 0 To 80 Do Work[K] := 0;
  If Fill(0) Then ;
  For K := 0 To 80 Do Sol[K] := Work[K];
  Case Level Of
    0 : Target := 38;
    2 : Target := 25;
  Else
    Target := 30;
  End;
  { cases retirees par paires symetriques (P et 80 - P) }
  For K := 0 To 40 Do Perm[K] := K;
  K := 40;
  While K > 0 Do
  Begin
    J := Rnd(K + 1);
    T := Perm[K]; Perm[K] := Perm[J]; Perm[J] := T;
    Dec(K);
  End;
  Left := 81;
  K := 0;
  While (K <= 40) And (Left > Target) Do
  Begin
    P := Perm[K]; Q := 80 - P;
    A := Work[P]; B := Work[Q];
    Work[P] := 0; Work[Q] := 0;
    If Unique Then
    Begin
      If P = Q Then Dec(Left) Else Left := Left - 2;
    End
    Else
    Begin
      Work[P] := A; Work[Q] := B;
    End;
    Inc(K);
  End;
  For K := 0 To 80 Do
  Begin
    Cur[K] := Work[K];
    If Work[K] <> 0 Then Given[K] := 1 Else Given[K] := 0;
    Hinted[K] := 0; Wrong[K] := 0;
  End;
End;

{ le chiffre de la case P est-il en conflit (ligne, colonne, carre) ? }
Function Conflict(P : LongInt) : Boolean;
Var R, C, K, Q, BR, BC, D : LongInt;
Begin
  Conflict := False;
  D := Cur[P];
  If D = 0 Then Exit;
  R := P Div 9; C := P Mod 9;
  BR := (R Div 3) * 3; BC := (C Div 3) * 3;
  For K := 0 To 8 Do
  Begin
    Q := R * 9 + K;
    If (Q <> P) And (Cur[Q] = D) Then Conflict := True;
    Q := K * 9 + C;
    If (Q <> P) And (Cur[Q] = D) Then Conflict := True;
    Q := (BR + K Div 3) * 9 + BC + K Mod 3;
    If (Q <> P) And (Cur[Q] = D) Then Conflict := True;
  End;
End;

Function Empty : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To 80 Do
    If Cur[K] = 0 Then Inc(N);
  Empty := N;
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

{ chiffre agrandi deux fois (police du VGA) centre dans la case }
Procedure BigDigit(X, Y, D, C, Bg : LongInt);
Var R, K, B, X0, Run : LongInt;
Begin
  If FontH = 0 Then
  Begin
    OutTxt(X + 16, Y + 12, Chr(48 + D), C, Bg);
    Exit;
  End;
  X0 := X + (Cell - 16) Div 2; Y := Y + (Cell - FontH * 2) Div 2;
  For R := 0 To FontH - 1 Do
  Begin
    B := Font[(48 + D) * FontH + R];
    K := 0;
    While K < 8 Do
      If (B And ($80 Shr K)) <> 0 Then
      Begin
        Run := K;
        While (K < 8) And ((B And ($80 Shr K)) <> 0) Do Inc(K);
        FBar(X0 + Run * 2, Y + R * 2, X0 + K * 2 - 1, Y + R * 2 + 1, C);
      End
      Else Inc(K);
  End;
End;

Procedure CellXY(P : LongInt; Var X, Y : LongInt);
Begin
  X := GX + (P Mod 9) * Cell + 3 + ((P Mod 9) Div 3) * 2;
  Y := GY + (P Div 9) * Cell + 3 + ((P Div 9) Div 3) * 2;
End;

Procedure DrawCell(P : LongInt);
Var X, Y, Bg, Fg : LongInt;
Begin
  CellXY(P, X, Y);
  If Given[P] <> 0 Then Bg := CLR_PALEGRAY Else Bg := CLR_WHITE;
  If P = SelC Then Bg := CLR_YELLOW
  Else If (SelC >= 0) And (Cur[SelC] <> 0) And (Cur[P] = Cur[SelC]) Then Bg := CLR_CYAN;
  If Wrong[P] <> 0 Then Bg := CLR_RED;
  FBar(X, Y, X + Cell - 2, Y + Cell - 2, Bg);
  If Cur[P] <> 0 Then
  Begin
    If Given[P] <> 0 Then Fg := CLR_BLACK
    Else If Hinted[P] <> 0 Then Fg := CLR_DARKGREEN
    Else Fg := CLR_DARKBLUE;
    If (Given[P] = 0) And Conflict(P) Then Fg := CLR_RED;
    If Wrong[P] <> 0 Then Fg := CLR_WHITE;
    BigDigit(X, Y, Cur[P], Fg, Bg);
  End;
End;

Procedure DrawGrid;
Var K, X, Y, W : LongInt;
Begin
  W := 9 * Cell + 2 * 2 + 4;
  { cadre en creux, traits epais des carres, traits fins des cases }
  Edge(GX - 2, GY - 2, GX + W + 1, GY + W + 1, CLR_DARKGRAY, CLR_WHITE);
  FBar(GX - 1, GY - 1, GX + W, GY + W, CLR_BLACK);
  For K := 0 To 80 Do
  Begin
    CellXY(K, X, Y);
    FBar(X - 1, Y - 1, X + Cell - 1, Y + Cell - 1, CLR_DARKGRAY);
  End;
  For K := 0 To 80 Do DrawCell(K);
End;

{ bouton poussoir de PM (relief blanc, noir, gris fonce) }
Procedure Button(X, Y, W, H : LongInt; S : String; Fg : LongInt; Big : LongInt);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If Big > 0 Then BigDigit(X + (W - Cell) Div 2, Y + (H - Cell) Div 2, Big, Fg, CLR_PALEGRAY)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, Fg, CLR_PALEGRAY);
End;

Procedure DrawPad;
Var K : LongInt;
Begin
  OutTxt(PX, PY - 26, 'Chiffres', CLR_BLACK, CLR_PALEGRAY);
  For K := 0 To 8 Do Button(PX + (K Mod 3) * (BW + 6), PY + (K Div 3) * (BH + 6), BW, BH, '', CLR_DARKBLUE, K + 1);
  Button(PX, PY + 3 * (BH + 6), 3 * BW + 12, 30, 'Effacer', CLR_BLACK, 0);
  Button(PX, PY + 3 * (BH + 6) + 38, 3 * BW + 12, 30, 'Indice', CLR_BLACK, 0);
  Button(PX, PY + 3 * (BH + 6) + 76, 3 * BW + 12, 30, 'V'#130'rifier', CLR_BLACK, 0);
End;

Procedure DrawStatus;
Var S : String;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  S := 'Niveau : ' + LevelName + '   Cases vides : ' + IStr(Empty) + '   Temps : ' + TimeStr +
       '   Partie n' + Chr(248) + ' ' + IStr(GameNo);
  OutTxt(8, CH - 19, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  DrawGrid;
  DrawPad;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ barre d'etat seulement (chronometre) }
Procedure RedrawStatus;
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CW; Rc[3] := 22;
  Dummy := WinInvalidateRect(Client, LongInt(@Rc), 0);
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure SetLevelMarks;
Var M : LongInt;
Begin
  M := WinWindowFromID(Frame, $8005);
  If M = 0 Then Exit;
  If Level = 0 Then Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_EASY Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_EASY Or $10000, MIA_CHECKED);
  If Level = 1 Then Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_MEDIUM Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_MEDIUM Or $10000, MIA_CHECKED);
  If Level = 2 Then Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_HARD Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_HARD Or $10000, MIA_CHECKED);
End;

Procedure NewGame;
Begin
  GameNo := Seed Mod 100000;
  Build;
  NUndo := 0; Elapsed := 0; Done := 0; Solved := 0;
  SelC := 0;
  While (SelC < 80) And (Given[SelC] <> 0) Do Inc(SelC);
  Redraw;
End;

Procedure Restart;
Var K : LongInt;
Begin
  For K := 0 To 80 Do
  Begin
    If Given[K] = 0 Then Cur[K] := 0;
    Hinted[K] := 0; Wrong[K] := 0;
  End;
  NUndo := 0; Elapsed := 0; Done := 0; Solved := 0;
  Redraw;
End;

{ grille complete et juste : fin de la partie }
Procedure CheckWin;
Var K : LongInt;
Begin
  If Done <> 0 Then Exit;
  For K := 0 To 80 Do
    If (Cur[K] = 0) Or Conflict(K) Then Exit;
  Done := 1;
  Redraw;
  If Solved = 0 Then
    Dummy := Ask('F' + Chr(130) + 'licitations ! Grille ' + LevelName + ' r' + Chr(130) + 'solue en ' + TimeStr +
                 '.' + Chr(10) + 'F2 : nouvelle partie.', 'Sudoku', MB_OK Or MB_INFORMATION);
End;

{ mettre D (0 : effacer) dans la case choisie }
Procedure Put(D : LongInt);
Var K : LongInt;
Begin
  If (SelC < 0) Or (Done <> 0) Then Exit;
  If Given[SelC] <> 0 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  If Cur[SelC] = D Then Exit;
  If NUndo >= MaxUndo Then
  Begin
    For K := 1 To MaxUndo - 1 Do
    Begin
      UCell[K - 1] := UCell[K]; UOld[K - 1] := UOld[K];
    End;
    Dec(NUndo);
  End;
  UCell[NUndo] := SelC; UOld[NUndo] := Cur[SelC];
  Inc(NUndo);
  Cur[SelC] := D;
  Hinted[SelC] := 0;
  For K := 0 To 80 Do Wrong[K] := 0;
  Redraw;
  CheckWin;
End;

Procedure Undo;
Begin
  If (NUndo = 0) Or (Done <> 0) Then Exit;
  Dec(NUndo);
  Cur[UCell[NUndo]] := UOld[NUndo];
  Hinted[UCell[NUndo]] := 0;
  SelC := UCell[NUndo];
  Redraw;
End;

{ indice : le bon chiffre dans la case choisie (ou la premiere case vide) }
Procedure Hint;
Var P : LongInt;
Begin
  If Done <> 0 Then Exit;
  P := SelC;
  If (P < 0) Or (Given[P] <> 0) Or (Cur[P] = Sol[P]) Then
  Begin
    P := 0;
    While (P < 81) And (Cur[P] = Sol[P]) Do Inc(P);
    If P >= 81 Then Exit;
  End;
  SelC := P;
  Put(Sol[P]);
  Hinted[P] := 1;
  Redraw;
End;

{ verifier : les chiffres faux sur fond rouge }
Procedure Check;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To 80 Do
  Begin
    Wrong[K] := 0;
    If (Cur[K] <> 0) And (Cur[K] <> Sol[K]) Then
    Begin
      Wrong[K] := 1;
      Inc(N);
    End;
  End;
  Redraw;
  If N = 0 Then
    Dummy := Ask('Aucune erreur pour l''instant. Cases vides : ' + IStr(Empty) + '.', 'Sudoku - V' + Chr(130) +
                 'rifier', MB_OK Or MB_INFORMATION)
  Else
    Dummy := Ask(IStr(N) + ' chiffre(s) faux, sur fond rouge.', 'Sudoku - V' + Chr(130) + 'rifier',
                 MB_OK Or MB_INFORMATION);
End;

Procedure ShowSolution;
Var K : LongInt;
Begin
  If Done <> 0 Then Exit;
  If Ask('Afficher la solution ? La partie sera termin' + Chr(130) + 'e.', 'Sudoku',
         MB_YESNO Or MB_QUERY) <> MBID_YES Then Exit;
  For K := 0 To 80 Do
  Begin
    Cur[K] := Sol[K]; Wrong[K] := 0;
  End;
  Solved := 1;
  CheckWin;
  Redraw;
End;

Procedure SetLevel(L : LongInt);
Begin
  Level := L;
  SetLevelMarks;
  Seed := Seed + 7919;
  NewGame;
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
    CM_UNDO : Undo;
    CM_HINT : Hint;
    CM_CHECK : Check;
    CM_SOLVE : ShowSolution;
    CM_EASY : SetLevel(0);
    CM_MEDIUM : SetLevel(1);
    CM_HARD : SetLevel(2);
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES : Begin
      LClr;
      LAdd('' + 'Remplissez la grille : chaque ligne, chaque colonne et chaque carr' + Chr(130) +
           ' de 3 x 3 doit contenir une fois chacun des chiffres de 1 ' + Chr(133) + ' 9. ' +
           'Les chiffres donn' + Chr(130) + 's (fond gris) ne se changent pas ; un chiffre en ');
      LAdd('' + 'conflit est en rouge.' + Chr(10) + Chr(10) + 'Souris : cliquer une case puis un chiffre du pav' +
           Chr(130) + ' ; bouton 2 : effacer. ' + 'Clavier : fl' + Chr(138) + 'ches, 1 ' + Chr(133) +
           ' 9, Suppr ou Espace (effacer), ' + 'Ctrl+Z (annuler), I (indice), V (v' + Chr(130));
      LAdd('' + 'rifier), F2 (nouvelle partie).');
      Dummy := LMsgBox('Sudoku - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
    End;
    CM_ABOUT : Dummy := Ask('Sudoku pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'SODOKU.PAS de 7iles. Grilles construites au hasard, ' + Chr(133) + ' solution ' +
                            'unique, trois niveaux.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et ' +
                            'compil' + Chr(130) + ' par OS2PC.', 'A propos de Sudoku', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Function HitCell(X, Y : LongInt) : LongInt;
Var P, Cx, Cy : LongInt;
Begin
  HitCell := -1;
  For P := 0 To 80 Do
  Begin
    CellXY(P, Cx, Cy);
    If (X >= Cx - 1) And (X < Cx + Cell) And (Y >= Cy - 1) And (Y < Cy + Cell) Then HitCell := P;
  End;
End;

Procedure Click(Mx, My : LongInt; Btn2 : Boolean);
Var X, Y, P, K : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  P := HitCell(X, Y);
  If P >= 0 Then
  Begin
    SelC := P;
    For K := 0 To 80 Do Wrong[K] := 0;
    If Btn2 Then Put(0) Else Redraw;
    Exit;
  End;
  If Btn2 Then Exit;
  { pave : chiffres, Effacer, Indice, Verifier }
  For K := 0 To 8 Do
    If (X >= PX + (K Mod 3) * (BW + 6)) And (X < PX + (K Mod 3) * (BW + 6) + BW) And
       (Y >= PY + (K Div 3) * (BH + 6)) And (Y < PY + (K Div 3) * (BH + 6) + BH) Then
    Begin
      Put(K + 1);
      Exit;
    End;
  If (X >= PX) And (X < PX + 3 * BW + 12) Then
  Begin
    If (Y >= PY + 3 * (BH + 6)) And (Y < PY + 3 * (BH + 6) + 30) Then Put(0)
    Else If (Y >= PY + 3 * (BH + 6) + 38) And (Y < PY + 3 * (BH + 6) + 68) Then Hint
    Else If (Y >= PY + 3 * (BH + 6) + 76) And (Y < PY + 3 * (BH + 6) + 106) Then Check;
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
    Case Vk Of
      VK_F1 : Begin Command(CM_RULES); Exit; End;
      VK_F2 : Begin Command(CM_NEW); Exit; End;
      VK_LEFT : Begin If SelC Mod 9 > 0 Then Dec(SelC); Redraw; Exit; End;
      VK_RIGHT : Begin If SelC Mod 9 < 8 Then Inc(SelC); Redraw; Exit; End;
      VK_UP : Begin If SelC >= 9 Then SelC := SelC - 9; Redraw; Exit; End;
      VK_DOWN : Begin If SelC < 72 Then SelC := SelC + 9; Redraw; Exit; End;
      VK_DELETE, VK_BACKSPACE, VK_SPACE : Begin Put(0); Exit; End;
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
  Case Ch Of
    49..57 : Put(Ch - 48);
    48, 32 : Put(0);
    73, 105 : Hint;             { I }
    86, 118 : Check;            { V }
    69, 101 : Put(0);           { E (comme le prototype) }
  Else
    KeyChar := False;
  End;
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
      If (Done = 0) And (Lo16(Mp1) = 1) Then
      Begin
        Inc(Elapsed);
        RedrawStatus;
      End;
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        Click(S16(Mp1), S16(Mp1 Shr 16), False);
        MainProc := 1;
      End;
    WM_BUTTON2DOWN :
      Begin
        Click(S16(Mp1), S16(Mp1 Shr 16), True);
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

{ police 8 x 16 du VGA (VIOCALLS) pour les gros chiffres }
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
  Fl, H0, H1, H2, Sw, Sh, Sw0, Sh0, M, K, E : LongInt;
  Dt : Array[0..15] Of Byte;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Level := 1;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('SUDOKU'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('SUDOKU'), Z2('Sudoku'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_RESTART, '~Recommencer la partie');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_HINT, 'Indice' + Chr(9) + 'I');
  MItem(MIS_TEXT, 0, CM_CHECK, '~V' + Chr(130) + 'rifier' + Chr(9) + 'V');
  MItem(MIS_TEXT, 0, CM_SOLVE, '~Solution...');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_EASY, '~Facile');
  MItem(MIS_TEXT, MIA_CHECKED, CM_MEDIUM, '~Moyen');
  MItem(MIS_TEXT, 0, CM_HARD, '~Difficile');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 13);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Sudoku');
  MenuClose(H2, 2);
  MenuClose(H0, 2);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  { fenetre de 640 x 470 (ecran plus petit : tout l'ecran), centree }
  If Sw > 640 Then Sw0 := 640 Else Sw0 := Sw;
  If Sh > 470 Then Sh0 := 470 Else Sh0 := Sh;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, (Sw - Sw0) Div 2, (Sh - Sh0) Div 2, Sw0, Sh0,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 1000);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
