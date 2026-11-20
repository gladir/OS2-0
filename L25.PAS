{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: L25 - parcours du cavalier sur 25 cases pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program L25;

{$R-,S-,I-}

{ Compilation : OS2PC L25.PAS   (produit L25.EXE)

  Portage vers OS/2-0 du prototype L25.PAS du depot 7iles (Turbo Pascal
  et BGI : menu en mode texte, damier de 16 points, cases en ellipses,
  fleches et Entree) : fenetre de Presentation Manager avec menus,
  echiquier de 5 x 5 dans un cadre de bois, cavalier dessine, cases
  parcourues numerotees et reliees par le chemin du cavalier, coups
  possibles marques, panneau, barre d'etat et apparence d'OS/2.

  Regles du prototype : remplir les 25 cases en se deplacant comme le
  cavalier aux echecs, sans jamais passer deux fois par la meme case ;
  depart dans le coin en haut a gauche ; plus aucun coup possible : la
  partie est perdue.
  Ce qui est ajoute : la souris, l'annulation des coups, le depart au
  choix (menu Options), une solution montree coup par coup depuis la
  position atteinte (si elle existe), le meilleur parcours et les
  parties gagnees.

  Souris : cliquer une case marquee. Clavier : fleches et Entree (comme
  le prototype), Retour arriere ou Ctrl+Z (annuler), S (solution), F2
  (nouvelle partie), F1 (regles).
  Parametres : /PLAY (le prototype : jouer tout de suite, toujours le
  cas ici) ; /AUTO (la solution se joue seule, en boucle). }

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
  VK_BACKSPACE = $05; VK_UP = $16;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  CM_NEW = 101; CM_UNDO = 102; CM_SOLVE = 103; CM_QUIT = 104;
  CM_CORNER = 201; CM_FREE = 202; CM_HINTS = 203;
  CM_RULES = 301; CM_ABOUT = 302;
  CardW = 70; CardH = 96;
  N = 5; Cell = 72;
  BX0 = 30; BY0 = 28;                      { coin de l'echiquier }
  PnX = 428; PW = 130;
  CWant = 568; CHWant = 440;
  BY1 = 232; BH = 30;                      { boutons du panneau }

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Num : Array[0..N - 1, 0..N - 1] Of LongInt;   { ordre de passage (0 : libre) }
  PathX, PathY : Array[0..N * N] Of LongInt;
  Steps, CurX, CurY, Hints, FreeStart, Over, Wins, Best, Seed, AutoAll : LongInt;
  SolN, SolI, Solving : LongInt;
  SolX, SolY : Array[0..N * N] Of LongInt;
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


Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
End;

{ --- dessin --- }
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

{ texte : coin bas gauche (X, Y) }
Procedure TextXY(Hps, X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := Y; Rc[2] := X + Length(S) * 8; Rc[3] := Y + 16;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

Function Rank(C : LongInt) : LongInt;
Begin
  Rank := C Mod 13;
End;

Function Suit(C : LongInt) : LongInt;
Begin
  Suit := C Div 13;
End;

Function IsRed(C : LongInt) : Boolean;
Begin
  IsRed := Suit(C) < 2;
End;

Function RankName(R : LongInt) : String;
Begin
  Case R Of
    0 : RankName := 'A';
    10 : RankName := 'V';
    11 : RankName := 'D';
    12 : RankName := 'R';
  Else
    RankName := IStr(R + 1);
  End;
End;

{ symbole de la couleur (police : 3 coeur, 4 carreau, 5 trefle, 6 pique) }
Function SuitCh(C : LongInt) : String;
Begin
  SuitCh := Chr(3 + Suit(C));
End;

Procedure DrawBack(Hps, X, Y : LongInt);
Var K : LongInt;
Begin
  GBox(Hps, X, Y, X + CardW - 1, Y + CardH - 1, CLR_WHITE, DRO_FILL, 10);
  GBox(Hps, X, Y, X + CardW - 1, Y + CardH - 1, CLR_BLACK, DRO_OUTLINE, 10);
  GBox(Hps, X + 4, Y + 4, X + CardW - 5, Y + CardH - 5, CLR_DARKBLUE, DRO_FILL, 6);
  { treillis original : losanges bleus }
  K := 0;
  While K < CardW + CardH - 24 Do
  Begin
    GLn(Hps, X + 5 + MaxI(0, K - CardH + 10), Y + 5 + MinI(K, CardH - 10), X + 5 + MinI(K, CardW - 10),
        Y + 5 + MaxI(0, K - CardW + 10), CLR_BLUE);
    K := K + 8;
  End;
  GBox(Hps, X + CardW Div 2 - 14, Y + CardH Div 2 - 12, X + CardW Div 2 + 14, Y + CardH Div 2 + 12, CLR_YELLOW,
       DRO_FILL, 24);
  TextXY(Hps, X + CardW Div 2 - 4, Y + CardH Div 2 - 8, 'B', CLR_DARKBLUE, CLR_YELLOW);
End;

{ disposition des symboles d'une carte numerotee : colonne (G, C, D) et
  ligne (0 a 6) de chaque symbole }
Function PipLayout(N : LongInt) : String;
Begin
  Case N Of
    1 : PipLayout := 'C3';
    2 : PipLayout := 'C0C6';
    3 : PipLayout := 'C0C3C6';
    4 : PipLayout := 'G0D0G6D6';
    5 : PipLayout := 'G0D0C3G6D6';
    6 : PipLayout := 'G0D0G3D3G6D6';
    7 : PipLayout := 'G0D0C1G3D3G6D6';
    8 : PipLayout := 'G0D0C1G3D3C5G6D6';
    9 : PipLayout := 'G0D0G2D2C3G4D4G6D6';
  Else
    PipLayout := 'G0D0C1G2D2G4D4C5G6D6';
  End;
End;

Procedure DrawPips(Hps, X, Y, C : LongInt; Fg : LongInt);
Var L, S : String; K, Px, Py, Cx : LongInt;
Begin
  L := PipLayout(Rank(C) + 1);
  S := SuitCh(C);
  Cx := X + CardW Div 2 - 4;
  K := 1;
  While K < Length(L) Do
  Begin
    Case L[K] Of
      'G' : Px := Cx - 14;
      'D' : Px := Cx + 14;
    Else
      Px := Cx;
    End;
    Py := Y + CardH - 34 - ((Ord(L[K + 1]) - 48) * (CardH - 50)) Div 6;
    TextXY(Hps, Px, Py, S, Fg, CLR_WHITE);
    K := K + 2;
  End;
End;

Procedure DrawFace(Hps, X, Y, C : LongInt; Hilite : Boolean);
Var Fg, Bg : LongInt; S : String;
Begin
  If Hilite Then Bg := CLR_YELLOW Else Bg := CLR_WHITE;
  GBox(Hps, X, Y, X + CardW - 1, Y + CardH - 1, Bg, DRO_FILL, 10);
  GBox(Hps, X, Y, X + CardW - 1, Y + CardH - 1, CLR_BLACK, DRO_OUTLINE, 10);
  If IsRed(C) Then Fg := CLR_RED Else Fg := CLR_BLACK;
  S := RankName(Rank(C));
  TextXY(Hps, X + 4, Y + CardH - 20, S, Fg, Bg);
  TextXY(Hps, X + 4 + Length(S) * 8, Y + CardH - 20, SuitCh(C), Fg, Bg);
  If Rank(C) >= 10 Then
  Begin
    { figure : cadre colore, lettre et symbole }
    GBox(Hps, X + 16, Y + 22, X + CardW - 17, Y + CardH - 23, CLR_DARKBLUE, DRO_OUTLINE, 0);
    GBox(Hps, X + 17, Y + 23, X + CardW - 18, Y + CardH - 24, CLR_YELLOW, DRO_FILL, 0);
    GBox(Hps, X + 22, Y + CardH Div 2 - 2, X + CardW - 23, Y + CardH - 30, Fg, DRO_FILL, 8);
    TextXY(Hps, X + CardW Div 2 - 8, Y + CardH Div 2 - 18, S + SuitCh(C), Fg, CLR_YELLOW);
    GLn(Hps, X + 22, Y + CardH Div 2 - 2, X + CardW Div 2, Y + CardH - 30, CLR_YELLOW);
    GLn(Hps, X + CardW Div 2, Y + CardH - 30, X + CardW - 23, Y + CardH Div 2 - 2, CLR_YELLOW);
  End
  Else If Rank(C) = 0 Then
  Begin
    GBox(Hps, X + CardW Div 2 - 14, Y + CardH Div 2 - 14, X + CardW Div 2 + 14, Y + CardH Div 2 + 14, Fg,
         DRO_OUTLINE, 28);
    TextXY(Hps, X + CardW Div 2 - 4, Y + CardH Div 2 - 8, SuitCh(C), Fg, Bg);
  End
  Else DrawPips(Hps, X, Y, C, Fg);
  { indice du coin bas droit apres les symboles (leur fond ne le cache pas) }
  TextXY(Hps, X + CardW - 6 - (Length(S) + 1) * 8, Y + 4, S + SuitCh(C), Fg, Bg);
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



{ trait (coordonnees de haut en bas) }
Procedure Ln(X1, Y1, X2, Y2, C : LongInt);
Begin
  GLn(Hps, X1, CH - 1 - Y1, X2, CH - 1 - Y2, C);
End;

{ trait epais }
Procedure ThickLn(X1, Y1, X2, Y2, C : LongInt);
Begin
  Ln(X1, Y1, X2, Y2, C);
  Ln(X1 + 1, Y1, X2 + 1, Y2, C);
  Ln(X1, Y1 + 1, X2, Y2 + 1, C);
End;

{ ==================================================================== }
{ Regles                                                                }
{ ==================================================================== }

Function KnightMove(X1, Y1, X2, Y2 : LongInt) : Boolean;
Var Dx, Dy : LongInt;
Begin
  Dx := Abs(X2 - X1); Dy := Abs(Y2 - Y1);
  KnightMove := ((Dx = 1) And (Dy = 2)) Or ((Dx = 2) And (Dy = 1));
End;

Function Legal(X, Y : LongInt) : Boolean;
Begin
  Legal := False;
  If (X < 0) Or (X >= N) Or (Y < 0) Or (Y >= N) Then Exit;
  If Num[X, Y] <> 0 Then Exit;
  If Steps = 0 Then Legal := True
  Else Legal := KnightMove(PathX[Steps - 1], PathY[Steps - 1], X, Y);
End;

Function MovesFrom(X, Y : LongInt) : LongInt;
Var Dx, Dy, C : LongInt;
Begin
  C := 0;
  For Dx := -2 To 2 Do
    For Dy := -2 To 2 Do
      If (Abs(Dx) + Abs(Dy) = 3) And (X + Dx >= 0) And (X + Dx < N) And (Y + Dy >= 0) And (Y + Dy < N) Then
        If Num[X + Dx, Y + Dy] = 0 Then Inc(C);
  MovesFrom := C;
End;

Function LegalCount : LongInt;
Var X, Y, C : LongInt;
Begin
  C := 0;
  For X := 0 To N - 1 Do For Y := 0 To N - 1 Do If Legal(X, Y) Then Inc(C);
  LegalCount := C;
End;

{ recherche d'un parcours complet depuis la position (retour arriere,
  cases les plus contraintes d'abord) ; Budget limite le travail }
Var Budget : LongInt;

Function Search(X, Y, K : LongInt) : Boolean;
Var Dx, Dy, I, J, Nx, Ny, Cnt : LongInt;
    CX, CY, CM : Array[0..7] Of LongInt;
Begin
  Search := False;
  If K >= N * N Then
  Begin
    Search := True;
    Exit;
  End;
  Dec(Budget);
  If Budget <= 0 Then Exit;
  Cnt := 0;
  For Dx := -2 To 2 Do
    For Dy := -2 To 2 Do
      If Abs(Dx) + Abs(Dy) = 3 Then
      Begin
        Nx := X + Dx; Ny := Y + Dy;
        If (Nx >= 0) And (Nx < N) And (Ny >= 0) And (Ny < N) Then
          If Num[Nx, Ny] = 0 Then
          Begin
            CX[Cnt] := Nx; CY[Cnt] := Ny; CM[Cnt] := MovesFrom(Nx, Ny);
            Inc(Cnt);
          End;
      End;
  { tri par nombre de sorties (regle de Warnsdorff) }
  For I := 0 To Cnt - 2 Do
    For J := I + 1 To Cnt - 1 Do
      If CM[J] < CM[I] Then
      Begin
        Nx := CX[I]; CX[I] := CX[J]; CX[J] := Nx;
        Nx := CY[I]; CY[I] := CY[J]; CY[J] := Nx;
        Nx := CM[I]; CM[I] := CM[J]; CM[J] := Nx;
      End;
  For I := 0 To Cnt - 1 Do
  Begin
    Num[CX[I], CY[I]] := K + 1;
    SolX[K] := CX[I]; SolY[K] := CY[I];
    If Search(CX[I], CY[I], K + 1) Then
    Begin
      Num[CX[I], CY[I]] := 0;
      Search := True;
      Exit;
    End;
    Num[CX[I], CY[I]] := 0;
  End;
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Function SqX(X : LongInt) : LongInt;
Begin
  SqX := BX0 + X * Cell;
End;

Function SqY(Y : LongInt) : LongInt;
Begin
  SqY := BY0 + Y * Cell;
End;

Function DarkSq(X, Y : LongInt) : Boolean;
Begin
  DarkSq := (X + Y) Mod 2 = 1;
End;

{ remplissage d'un polygone (sommets PolyX, PolyY decales de X0, Y0) par
  lignes horizontales }
Var PolyX, PolyY : Array[0..31] Of LongInt;

Procedure FillPoly(Np, X0, Y0, C : LongInt);
Var Y, I, J, K, Ymin, Ymax, Nx, T : LongInt; Xs : Array[0..31] Of LongInt;
Begin
  Ymin := 9999; Ymax := -9999;
  For I := 0 To Np - 1 Do
  Begin
    If PolyY[I] < Ymin Then Ymin := PolyY[I];
    If PolyY[I] > Ymax Then Ymax := PolyY[I];
  End;
  For Y := Ymin To Ymax Do
  Begin
    Nx := 0;
    For I := 0 To Np - 1 Do
    Begin
      J := (I + 1) Mod Np;
      If ((PolyY[I] <= Y) And (PolyY[J] > Y)) Or ((PolyY[J] <= Y) And (PolyY[I] > Y)) Then
        If Nx < 32 Then
        Begin
          Xs[Nx] := PolyX[I] + (Y - PolyY[I]) * (PolyX[J] - PolyX[I]) Div (PolyY[J] - PolyY[I]);
          Inc(Nx);
        End;
    End;
    For I := 0 To Nx - 2 Do
      For K := I + 1 To Nx - 1 Do
        If Xs[K] < Xs[I] Then Begin T := Xs[I]; Xs[I] := Xs[K]; Xs[K] := T; End;
    I := 0;
    While I + 1 < Nx Do
    Begin
      FBar(X0 + Xs[I], Y0 + Y, X0 + Xs[I + 1], Y0 + Y, C);
      I := I + 2;
    End;
  End;
End;

{ le cavalier (tete tournee vers la gauche) dans la case X0, Y0 }
Procedure DrawKnight(X0, Y0 : LongInt);
Var I, Np : LongInt;
Const
  KX : Array[0..19] Of LongInt = (16, 54, 54, 48, 46, 50, 52, 46, 40, 37, 33, 27, 16, 9, 11, 17, 25, 29, 20, 14);
  KY : Array[0..19] Of LongInt = (60, 60, 54, 50, 38, 28, 18, 9, 5, 2, 7, 8, 18, 30, 34, 32, 27, 29, 40, 50);
Begin
  Np := 20;
  { ombre }
  For I := 0 To Np - 1 Do Begin PolyX[I] := KX[I] + 2; PolyY[I] := KY[I] + 2; End;
  FillPoly(Np, X0 + 4, Y0 + 4, CLR_DARKGRAY);
  For I := 0 To Np - 1 Do Begin PolyX[I] := KX[I]; PolyY[I] := KY[I]; End;
  FillPoly(Np, X0 + 4, Y0 + 4, CLR_BLACK);
  { reflets et oeil }
  For I := 0 To Np - 1 Do
    Ln(X0 + 4 + KX[I], Y0 + 4 + KY[I], X0 + 4 + KX[(I + 1) Mod Np], Y0 + 4 + KY[(I + 1) Mod Np], CLR_WHITE);
  Disc(X0 + 4 + 31, Y0 + 4 + 15, 2, CLR_WHITE);
  Ln(X0 + 4 + 44, Y0 + 4 + 20, X0 + 4 + 42, Y0 + 4 + 44, CLR_DARKGRAY);
  FBar(X0 + 4 + 12, Y0 + 4 + 55, X0 + 4 + 57, Y0 + 4 + 62, CLR_BLACK);
  FBar(X0 + 4 + 13, Y0 + 4 + 56, X0 + 4 + 56, Y0 + 4 + 57, CLR_DARKGRAY);
End;

Procedure DrawSquare(X, Y : LongInt);
Var X1, Y1, C, Fg, I : LongInt; S : String;
Begin
  X1 := SqX(X); Y1 := SqY(Y);
  If Num[X, Y] <> 0 Then
  Begin
    If DarkSq(X, Y) Then C := CLR_DARKCYAN Else C := CLR_PALEGRAY;
  End
  Else If DarkSq(X, Y) Then C := CLR_DARKGREEN Else C := CLR_WHITE;
  FBar(X1, Y1, X1 + Cell - 1, Y1 + Cell - 1, C);
  If (Num[X, Y] <> 0) And Not ((Steps > 0) And (PathX[Steps - 1] = X) And (PathY[Steps - 1] = Y)) Then
  Begin
    S := IStr(Num[X, Y]);
    If DarkSq(X, Y) Then Fg := CLR_WHITE Else Fg := CLR_DARKBLUE;
    BigText(X1 + (Cell - Length(S) * 16) Div 2, Y1 + (Cell - 32) Div 2, S, Fg, C);
  End;
  { coup possible : point jaune }
  If (Hints <> 0) And (Over = 0) And Legal(X, Y) And (Steps > 0) Then
  Begin
    Disc(X1 + Cell Div 2, Y1 + Cell Div 2, 9, CLR_BROWN);
    Disc(X1 + Cell Div 2, Y1 + Cell Div 2, 7, CLR_YELLOW);
  End;
  { case du curseur (clavier) }
  If (X = CurX) And (Y = CurY) And (Over = 0) Then
    For I := 0 To 2 Do
      Edge(X1 + I, Y1 + I, X1 + Cell - 1 - I, Y1 + Cell - 1 - I, CLR_RED, CLR_RED);
End;

Procedure DrawBoard;
Var X, Y, K, Cx, Cy : LongInt;
Begin
  { cadre de bois }
  FBar(BX0 - 18, BY0 - 18, BX0 + N * Cell + 17, BY0 + N * Cell + 17, CLR_BROWN);
  Edge(BX0 - 18, BY0 - 18, BX0 + N * Cell + 17, BY0 + N * Cell + 17, CLR_YELLOW, CLR_BLACK);
  Edge(BX0 - 1, BY0 - 1, BX0 + N * Cell, BY0 + N * Cell, CLR_BLACK, CLR_YELLOW);
  For K := 0 To N - 1 Do
  Begin
    OutTxt(BX0 + K * Cell + Cell Div 2 - 4, BY0 + N * Cell + 1, Chr(Ord('a') + K), CLR_YELLOW, CLR_BROWN);
    OutTxt(BX0 - 13, BY0 + K * Cell + Cell Div 2 - 8, IStr(N - K), CLR_YELLOW, CLR_BROWN);
  End;
  For X := 0 To N - 1 Do For Y := 0 To N - 1 Do DrawSquare(X, Y);
  { chemin du cavalier }
  For K := 1 To Steps - 1 Do
    ThickLn(SqX(PathX[K - 1]) + Cell Div 2, SqY(PathY[K - 1]) + Cell Div 2, SqX(PathX[K]) + Cell Div 2,
            SqY(PathY[K]) + Cell Div 2, CLR_RED);
  For K := 0 To Steps - 2 Do
  Begin
    Cx := SqX(PathX[K]) + Cell Div 2; Cy := SqY(PathY[K]) + Cell Div 2;
    Disc(Cx, Cy, 3, CLR_RED);
  End;
  { les numeros par-dessus le chemin }
  For K := 0 To Steps - 2 Do
  Begin
    X := PathX[K]; Y := PathY[K];
    If DarkSq(X, Y) Then Cx := CLR_DARKCYAN Else Cx := CLR_PALEGRAY;
    FBar(SqX(X) + 18, SqY(Y) + 18, SqX(X) + Cell - 19, SqY(Y) + Cell - 19, Cx);
    If DarkSq(X, Y) Then Cy := CLR_WHITE Else Cy := CLR_DARKBLUE;
    BigText(SqX(X) + (Cell - Length(IStr(K + 1)) * 16) Div 2, SqY(Y) + (Cell - 32) Div 2, IStr(K + 1), Cy, Cx);
  End;
  If Steps > 0 Then DrawKnight(SqX(PathX[Steps - 1]), SqY(PathY[Steps - 1]));
End;

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Var Y : LongInt;
Begin
  BigText(PnX + (PW - 3 * 16) Div 2, 10, 'L25', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX + (PW - 13 * 8) Div 2, 44, 'le cavalier', CLR_DARKRED, CLR_PALEGRAY);
  FBar(PnX, 70, PnX + PW - 1, 214, CLR_WHITE);
  Edge(PnX, 70, PnX + PW - 1, 214, CLR_DARKGRAY, CLR_WHITE);
  Y := 76;
  OutTxt(PnX + 6, Y, 'Cases', CLR_DARKGRAY, CLR_WHITE);
  BigText(PnX + 6, Y + 18, IStr(Steps) + '/25', CLR_DARKBLUE, CLR_WHITE);
  OutTxt(PnX + 6, Y + 58, 'Sauts possibles', CLR_DARKGRAY, CLR_WHITE);
  If (Steps = 0) Or (Over <> 0) Then OutTxt(PnX + 6, Y + 76, '-', CLR_BLACK, CLR_WHITE)
  Else OutTxt(PnX + 6, Y + 76, IStr(LegalCount), CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 6, Y + 98, 'Meilleur : ' + IStr(Best), CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 6, Y + 116, 'Gagn' + Chr(130) + 'es : ' + IStr(Wins), CLR_BLACK, CLR_WHITE);
  Button(PnX, BY1, PW, BH, 'Nouvelle partie', True);
  Button(PnX, BY1 + 36, PW, BH, 'Annuler', Steps > 1);
  Button(PnX, BY1 + 72, PW, BH, 'Solution', Over = 0);
  OutTxt(PnX, 352, 'Fl' + Chr(138) + 'ches, Entr' + Chr(130) + 'e', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 368, 'ou la souris', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 384, 'F1 : r' + Chr(138) + 'gles', CLR_DARKGRAY, CLR_PALEGRAY);
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
  FBar(0, 0, BX0 - 19, CH - 23, CLR_PALEGRAY);
  FBar(BX0 + N * Cell + 18, 0, CW - 1, CH - 23, CLR_PALEGRAY);
  FBar(BX0 - 18, 0, BX0 + N * Cell + 17, BY0 - 19, CLR_PALEGRAY);
  FBar(BX0 - 18, BY0 + N * Cell + 18, BX0 + N * Cell + 17, CH - 23, CLR_PALEGRAY);
  DrawPanel;
  DrawStatus;
  DrawBoard;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  If Client <> 0 Then Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure PlayMsg;
Begin
  If Steps = 0 Then Msg := 'Choisissez la case de d' + Chr(130) + 'part du cavalier (clic, ou fl' + Chr(138) +
                           'ches et Entr' + Chr(130) + 'e).'
  Else Msg := 'Cliquez une case marqu' + Chr(130) + 'e (ou fl' + Chr(138) + 'ches et Entr' + Chr(130) +
              'e) : le cavalier y saute.';
End;

Procedure StopSolve;
Begin
  If Solving <> 0 Then
  Begin
    Solving := 0;
    Dummy := WinStopTimer(Hab, Client, 1);
  End;
End;

Procedure CheckEnd;
Begin
  If Steps >= N * N Then
  Begin
    Over := 1;
    If Solving = 0 Then
    Begin
      Inc(Wins);
      Best := N * N;
    End;
    Msg := 'Bravo ! Le cavalier a parcouru les 25 cases. F2 : nouvelle partie.';
    Exit;
  End;
  If (Steps > Best) And (Solving = 0) Then Best := Steps;
  If (Steps > 0) And (LegalCount = 0) Then
  Begin
    Over := 1;
    Msg := 'Plus aucun coup possible : ' + IStr(Steps) + ' cases parcourues. Annuler (Retour) ou F2.';
    Exit;
  End;
  Over := 0;
  PlayMsg;
End;

Procedure MoveTo(X, Y : LongInt);
Begin
  If Not Legal(X, Y) Then
  Begin
    If Num[X, Y] <> 0 Then Msg := 'Le cavalier est d' + Chr(130) + 'j' + Chr(133) + ' pass' + Chr(130) +
                                  ' par cette case.'
    Else Msg := 'Ce n''est pas un saut de cavalier (en L : deux cases, puis une).';
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Redraw;
    Exit;
  End;
  PathX[Steps] := X; PathY[Steps] := Y;
  Inc(Steps);
  Num[X, Y] := Steps;
  CurX := X; CurY := Y;
  CheckEnd;
  Redraw;
End;

Procedure NewGame;
Var X, Y : LongInt;
Begin
  StopSolve;
  For X := 0 To N - 1 Do For Y := 0 To N - 1 Do Num[X, Y] := 0;
  Steps := 0; Over := 0;
  CurX := 0; CurY := 0;
  { prototype : depart dans le coin en haut a gauche }
  If FreeStart = 0 Then MoveTo(0, 0)
  Else
  Begin
    PlayMsg;
    Redraw;
  End;
End;

Procedure Undo;
Begin
  StopSolve;
  If Steps <= 1 Then
  Begin
    If (Steps = 1) And (FreeStart <> 0) Then
    Begin
      Num[PathX[0], PathY[0]] := 0;
      Steps := 0; Over := 0;
      PlayMsg;
      Redraw;
    End;
    Exit;
  End;
  Dec(Steps);
  Num[PathX[Steps], PathY[Steps]] := 0;
  CurX := PathX[Steps - 1]; CurY := PathY[Steps - 1];
  Over := 0;
  PlayMsg;
  Redraw;
End;

{ solution depuis la position atteinte, montree coup par coup }
Procedure Solve;
Var X, Y, K : LongInt; Ok : Boolean;
Begin
  If Solving <> 0 Then Exit;
  If Over <> 0 Then
  Begin
    If Steps >= N * N Then Exit;
    { plus de coup : on reprend depuis le debut }
    NewGame;
  End;
  If Steps = 0 Then MoveTo(0, 0);
  Budget := 200000;
  Ok := Search(PathX[Steps - 1], PathY[Steps - 1], Steps);
  If Not Ok Then
  Begin
    { depuis cette position, pas de parcours complet : depuis le depart }
    X := PathX[0]; Y := PathY[0];
    For K := 0 To N * N - 1 Do Num[K Mod N, K Div N] := 0;
    Steps := 1; Num[X, Y] := 1; PathX[0] := X; PathY[0] := Y;
    Budget := 400000;
    Ok := Search(X, Y, 1);
    If Not Ok Then
    Begin
      { depart sans solution (case de mauvaise couleur) : le coin }
      Num[X, Y] := 0;
      Steps := 1; Num[0, 0] := 1; PathX[0] := 0; PathY[0] := 0;
      Budget := 400000;
      Ok := Search(0, 0, 1);
    End;
    Msg := 'Pas de parcours complet depuis la position atteinte : la solution repart du d' + Chr(130) + 'but.';
  End
  Else Msg := 'Solution depuis la position atteinte...';
  If Not Ok Then Exit;
  SolN := N * N; SolI := Steps;
  Solving := 1;
  Dummy := WinStartTimer(Hab, Client, 1, 330);
  Redraw;
End;

Procedure TimerTick;
Begin
  If Solving = 0 Then
  Begin
    If (AutoAll <> 0) And (Over <> 0) Then
    Begin
      NewGame;
      Solve;
    End;
    Exit;
  End;
  If SolI < SolN Then
  Begin
    PathX[Steps] := SolX[SolI]; PathY[Steps] := SolY[SolI];
    Inc(Steps);
    Num[SolX[SolI], SolY[SolI]] := Steps;
    CurX := SolX[SolI]; CurY := SolY[SolI];
    Inc(SolI);
    If SolI >= SolN Then
    Begin
      CheckEnd;
      Msg := 'Voici un parcours complet des 25 cases. F2 : nouvelle partie.';
      Solving := 0;
      If AutoAll = 0 Then Dummy := WinStopTimer(Hab, Client, 1)
      Else Dummy := WinStartTimer(Hab, Client, 1, 3000);
    End;
    Redraw;
  End;
End;

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
  SetMark(CM_CORNER, FreeStart = 0); SetMark(CM_FREE, FreeStart <> 0); SetMark(CM_HINTS, Hints <> 0);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_UNDO : Undo;
    CM_SOLVE : Solve;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_CORNER, CM_FREE :
      Begin
        If Id = CM_FREE Then FreeStart := 1 Else FreeStart := 0;
        SetMarks;
        NewGame;
      End;
    CM_HINTS :
      Begin
        Hints := 1 - Hints;
        SetMarks;
        Redraw;
      End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Le cavalier doit passer par les 25 cases de l''' + Chr(130) + 'chiquier de 5 x 5, sans jamais ' +
             'repasser par une case d' + Chr(130) + 'j' + Chr(133) + ' parcourue. Il se d' + Chr(130) +
             'place comme aux ' + Chr(130) + 'checs : deux cases dans un sens et une dans l''autre (en L).' +
             Chr(10) + Chr(10));
        LAdd('Le cavalier part du coin en haut ' + Chr(133) + ' gauche (menu Options : d' + Chr(130) +
             'part au choix ; seules les cases de la couleur des coins permettent un parcours complet). ' +
             'Quand il n''a plus aucun saut possible avant la 25e case, la partie est perdue.' + Chr(10) + Chr(10));
        LAdd('Souris : cliquer une case marqu' + Chr(130) + 'e d''un point jaune. Clavier : fl' + Chr(138) +
             'ches et Entr' + Chr(130) + 'e. Retour arri' + Chr(138) + 're ou Ctrl+Z : annuler. S : montrer ' +
             'une solution. F2 : nouvelle partie.');
        Dummy := LMsgBox('L25 - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('L25 pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'L25.PAS de 7iles : le parcours du cavalier sur 25 cases.' + Chr(10) + 'Programme ' +
                            Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos de L25',
                            MB_OK Or MB_INFORMATION);
  End;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= BY1) And (Y < BY1 + BH) Then NewGame
    Else If (Y >= BY1 + 36) And (Y < BY1 + 36 + BH) Then Undo
    Else If (Y >= BY1 + 72) And (Y < BY1 + 72 + BH) Then Solve;
    Exit;
  End;
  If (X < BX0) Or (Y < BY0) Or (X >= BX0 + N * Cell) Or (Y >= BY0 + N * Cell) Then Exit;
  If (Over <> 0) Or (Solving <> 0) Then Exit;
  CurX := (X - BX0) Div Cell; CurY := (Y - BY0) Div Cell;
  MoveTo(CurX, CurY);
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then Begin KeyChar := False; Exit; End;
  If ((Fl And KC_CTRL) <> 0) And ((Ch = 26) Or (UpCase(Chr(Ch)) = 'Z')) Then Begin Undo; Exit; End;
  If (Fl And (KC_CTRL Or KC_ALT)) <> 0 Then Begin KeyChar := False; Exit; End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin NewGame; Exit; End;
    If Vk = VK_BACKSPACE Then Begin Undo; Exit; End;
    If (Solving = 0) And (Over = 0) Then
    Begin
      { fleches : comme le prototype, le curseur fait le tour }
      If Vk = VK_LEFT Then Begin CurX := (CurX + N - 1) Mod N; Redraw; Exit; End;
      If Vk = VK_RIGHT Then Begin CurX := (CurX + 1) Mod N; Redraw; Exit; End;
      If Vk = VK_UP Then Begin CurY := (CurY + N - 1) Mod N; Redraw; Exit; End;
      If Vk = VK_DOWN Then Begin CurY := (CurY + 1) Mod N; Redraw; Exit; End;
      If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_SPACE) Then Begin MoveTo(CurX, CurY); Exit; End;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'S' : Solve;
      'N' : NewGame;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Function MainProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  MainProc := 0;
  Case Msg0 Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
      End;
    WM_PAINT : PaintAll(H);
    WM_TIMER : If Lo16(Mp1) = 1 Then TimerTick;
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        Click(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := 1;
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CHAR :
      If Not KeyChar(Mp1, Mp2) Then MainProc := WinDefWindowProc(H, Msg0, Mp1, Mp2) Else MainProc := 1;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    MainProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
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
  Flg, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; AutoAll := 0; Client := 0; Frame := 0; Wins := 0; Best := 0; Hints := 1; FreeStart := 0;
  Solving := 0; Steps := 0; Over := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If S = '/AUTO' Then AutoAll := 1;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('L25'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('L25'), Z2('L25'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_TEXT, 0, CM_SOLVE, 'Montrer une ~solution' + Chr(9) + 'S');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_CORNER, 'D' + Chr(130) + 'part dans le ~coin');
  MItem(MIS_TEXT, 0, CM_FREE, 'D' + Chr(130) + 'part au ~choix');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_HINTS, '~Montrer les coups possibles');
  MenuClose(H3, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de L25');
  MenuClose(H2, 2);
  MenuClose(H0, 3);
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
  If AutoAll <> 0 Then Solve;
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
