{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: FREECELL - FreeCell (solitaire) pour le Presentation
                Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program FREECELL;

{$R-,S-,I-}

{ Compilation : OS2PC FREECELL.PAS   (produit FREECELL.EXE)

  Portage vers OS/2-0 du prototype FREECELL.PAS du depot 7iles (Turbo
  Pascal et BGI : cartes en rectangles de 50 x 70, clic pour choisir puis
  clic pour deposer, R nouvelle partie) : fenetre de Presentation Manager
  avec menus, tapis vert, cartes dessinees (celles du Poker d'OS/2-0),
  cellules libres et fondations marquees, cartes choisies surlignees,
  barre d'etat et apparence d'OS/2.

  Regles du prototype : 52 cartes en 8 colonnes (7, 7, 7, 7, 6, 6, 6,
  6), toutes visibles ; 4 cellules libres d'une carte ; 4 fondations
  montees par couleur de l'as au roi ; sur une colonne, une carte se pose
  sur une carte de valeur immediatement superieure et de l'autre couleur
  (rouge sur noir) ; toute carte va sur une colonne vide.
  Ce qui est ajoute : les donnes numerotees (les memes que celles du
  FreeCell de Windows : la donne 1 commence par le valet de carreau), le
  deplacement de plusieurs cartes a la fois (autant que les cellules et
  colonnes vides le permettent), les cartes qui montent seules aux
  fondations quand elles ne servent plus, le double clic, l'annulation
  des coups, les statistiques de la seance.

  Souris : cliquer une carte (ou une suite) puis sa destination ; double
  clic : la carte va a sa fondation ou dans une cellule libre. Clavier :
  1 a 8 (colonnes), A a D (cellules libres), H (fondations), Echap
  (annuler le choix), Retour arriere ou Ctrl+Z (annuler le coup), F2
  (nouvelle donne), F3 (rejouer la donne), F1 (regles).
  Parametres : /DEAL:n (donne numero n, 1 a 32000) ; /SEED:n ; /AUTO
  (l'ordinateur joue les coups evidents). }

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
  VK_BACKSPACE = $05; VK_ESC = $0F; VK_F3 = $22;
  WM_BUTTON1DBLCLK = $0073;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  CM_NEW = 101; CM_RESTART = 102; CM_UNDO = 103; CM_QUIT = 104; CM_NEXT = 105;
  CM_AUTOF = 201; CM_MULTI = 202;
  CM_RULES = 301; CM_ABOUT = 302;
  CardW = 68; CardH = 92;
  SX0 = 12; SDX = 76; TopY = 10; ColY = 116;
  CWant = 626; CHWant = 440;
  MaxCol = 24; SnapSz = 8 * MaxCol + 16; MaxUndo = 240;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Col : Array[0..7, 0..MaxCol - 1] Of Byte;
  ColN : Array[0..7] Of LongInt;
  FreeC : Array[0..3] Of LongInt;          { -1 : cellule vide }
  Found : Array[0..3] Of LongInt;          { cartes montees (par couleur : coeur, carreau, trefle, pique) }
  SelZ, SelI, SelK : LongInt;              { choix : 0 rien, 1 cellule, 2 colonne (SelK : premiere carte) }
  DealNo, Moves, AutoF, Multi, AutoAll, Won, Played, Wins, Streak, Pending, Seed, AutoMoves : LongInt;
  Undo0 : Array[0..MaxUndo * SnapSz - 1] Of Byte;
  NUndo : LongInt;
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



{ ==================================================================== }
{ Regles                                                                }
{ ==================================================================== }

Function RedC(C : LongInt) : Boolean;
Begin
  RedC := Suit(C) <= 1;
End;

{ C se pose-t-elle sur D dans une colonne ? }
Function Fits(C, D : LongInt) : Boolean;
Begin
  Fits := (Rank(C) + 1 = Rank(D)) And (RedC(C) <> RedC(D));
End;

Function FreeCount : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To 3 Do If FreeC[K] < 0 Then Inc(N);
  FreeCount := N;
End;

Function EmptyCols : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To 7 Do If ColN[K] = 0 Then Inc(N);
  EmptyCols := N;
End;

{ cartes deplacables d'un coup (cellules libres et colonnes vides) }
Function MaxMove(ToEmpty : Boolean) : LongInt;
Var E, M, K : LongInt;
Begin
  E := EmptyCols;
  If ToEmpty Then Dec(E);
  If Multi = 0 Then
  Begin
    MaxMove := 1;
    Exit;
  End;
  M := FreeCount + 1;
  For K := 1 To E Do M := M * 2;
  MaxMove := M;
End;

{ la suite de la colonne I a partir de la carte K est-elle ordonnee ? }
Function RunOk(I, K : LongInt) : Boolean;
Var J : LongInt;
Begin
  RunOk := True;
  For J := K To ColN[I] - 2 Do
    If Not Fits(Col[I, J + 1], Col[I, J]) Then RunOk := False;
End;

Function CanFound(C : LongInt) : Boolean;
Begin
  CanFound := Found[Suit(C)] = Rank(C);
End;

{ carte inutile en jeu : les fondations de l'autre couleur sont assez hautes }
Function SafeFound(C : LongInt) : Boolean;
Var R, A, B : LongInt;
Begin
  SafeFound := False;
  If Not CanFound(C) Then Exit;
  R := Rank(C) + 1;
  If R <= 2 Then
  Begin
    SafeFound := True;
    Exit;
  End;
  If RedC(C) Then Begin A := Found[2]; B := Found[3]; End Else Begin A := Found[0]; B := Found[1]; End;
  SafeFound := (A >= R - 1) And (B >= R - 1);
End;

{ ==================================================================== }
{ Donne (algorithme des donnes numerotees de Windows)                   }
{ ==================================================================== }

Procedure DealGame(N : LongInt);
Var Deck : Array[0..51] Of LongInt; I, J, C, S, R, Ms, Left : LongInt;
Begin
  For I := 0 To 51 Do Deck[I] := I;
  For I := 0 To 7 Do ColN[I] := 0;
  S := N;
  For I := 0 To 51 Do
  Begin
    S := (S * 214013 + 2531011) And $7FFFFFFF;
    R := S Shr 16;
    Left := 52 - I;
    J := R Mod Left;
    C := Deck[J]; Deck[J] := Deck[Left - 1];
    { carte de Windows : rang C div 4, couleur trefle, carreau, coeur, pique }
    Case C Mod 4 Of
      0 : Ms := 2;
      1 : Ms := 1;
      2 : Ms := 0;
    Else
      Ms := 3;
    End;
    Col[I Mod 8, ColN[I Mod 8]] := Ms * 13 + C Div 4;
    Inc(ColN[I Mod 8]);
  End;
  For I := 0 To 3 Do Begin FreeC[I] := -1; Found[I] := 0; End;
  SelZ := 0; Moves := 0; NUndo := 0; Won := 0;
End;

{ ==================================================================== }
{ Annulation (etat complet avant chaque coup)                           }
{ ==================================================================== }

Procedure SaveState(A : LongInt);
Var I, J : LongInt;
Begin
  For I := 0 To 7 Do
  Begin
    For J := 0 To MaxCol - 1 Do Undo0[A + I * MaxCol + J] := Col[I, J];
    Undo0[A + 8 * MaxCol + I] := ColN[I];
  End;
  For I := 0 To 3 Do
  Begin
    Undo0[A + 8 * MaxCol + 8 + I] := (FreeC[I] + 1) And 255;
    Undo0[A + 8 * MaxCol + 12 + I] := Found[I];
  End;
End;

Procedure LoadState(A : LongInt);
Var I, J : LongInt;
Begin
  For I := 0 To 7 Do
  Begin
    For J := 0 To MaxCol - 1 Do Col[I, J] := Undo0[A + I * MaxCol + J];
    ColN[I] := Undo0[A + 8 * MaxCol + I];
  End;
  For I := 0 To 3 Do
  Begin
    FreeC[I] := Undo0[A + 8 * MaxCol + 8 + I] - 1;
    Found[I] := Undo0[A + 8 * MaxCol + 12 + I];
  End;
End;

Procedure PushUndo;
Begin
  If NUndo >= MaxUndo Then
  Begin
    Move(Undo0[SnapSz], Undo0[0], (MaxUndo - 1) * SnapSz);
    NUndo := MaxUndo - 1;
  End;
  SaveState(NUndo * SnapSz);
  Inc(NUndo);
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Function SlotX(I : LongInt) : LongInt;
Begin
  SlotX := SX0 + I * SDX;
End;

{ ecart vertical des cartes d'une colonne (resserre si elle est longue) }
Function StepOf(I : LongInt) : LongInt;
Var Av : LongInt;
Begin
  Av := CH - 26 - ColY - CardH;
  If ColN[I] <= 1 Then StepOf := 24
  Else StepOf := MinI(24, Av Div (ColN[I] - 1));
End;

Procedure CardAt(X, Y, C : LongInt; Hilite : Boolean);
Begin
  DrawFace(Hps, X, CH - Y - CardH, C, Hilite);
End;

{ carte recouverte : seuls le haut et le coin sont visibles }
Procedure PartAt(X, Y, C : LongInt; Hilite : Boolean);
Var B, Fg, Bg : LongInt; S : String;
Begin
  B := CH - Y - CardH;
  If Hilite Then Bg := CLR_YELLOW Else Bg := CLR_WHITE;
  GBox(Hps, X, B, X + CardW - 1, B + CardH - 1, Bg, DRO_FILL, 10);
  GBox(Hps, X, B, X + CardW - 1, B + CardH - 1, CLR_BLACK, DRO_OUTLINE, 10);
  If RedC(C) Then Fg := CLR_RED Else Fg := CLR_BLACK;
  S := RankName(Rank(C));
  TextXY(Hps, X + 4, B + CardH - 20, S, Fg, Bg);
  TextXY(Hps, X + 4 + Length(S) * 8, B + CardH - 20, SuitCh(C), Fg, Bg);
  TextXY(Hps, X + CardW - 13, B + CardH - 20, SuitCh(C), Fg, Bg);
End;

{ emplacement vide (cellule libre ou fondation) }
Procedure EmptySlot(X, Y : LongInt; S : String; Hl : Boolean);
Var C : LongInt;
Begin
  If Hl Then C := CLR_YELLOW Else C := CLR_BLACK;
  FBar(X, Y, X + CardW - 1, Y + CardH - 1, CLR_DARKGREEN);
  Edge(X, Y, X + CardW - 1, Y + CardH - 1, C, CLR_GREEN);
  Edge(X + 1, Y + 1, X + CardW - 2, Y + CardH - 2, C, CLR_GREEN);
  If S <> '' Then BigText(X + (CardW - Length(S) * 16) Div 2, Y + (CardH - 32) Div 2, S, CLR_GREEN, CLR_DARKGREEN);
End;

Procedure DrawTop;
Var I : LongInt;
Begin
  For I := 0 To 3 Do
    If FreeC[I] >= 0 Then CardAt(SlotX(I), TopY, FreeC[I], (SelZ = 1) And (SelI = I))
    Else EmptySlot(SlotX(I), TopY, '', False);
  For I := 0 To 3 Do
    If Found[I] > 0 Then CardAt(SlotX(4 + I), TopY, I * 13 + Found[I] - 1, False)
    Else EmptySlot(SlotX(4 + I), TopY, Chr(3 + I), False);
  { etiquettes }
  OutTxt(SlotX(0), TopY + CardH + 2, 'Cellules libres', CLR_YELLOW, CLR_DARKGREEN);
  OutTxt(SlotX(7) + CardW - 10 * 8, TopY + CardH + 2, 'Fondations', CLR_YELLOW, CLR_DARKGREEN);
End;

Procedure DrawColumn(I : LongInt);
Var K, Y, Sp : LongInt; Hl : Boolean;
Begin
  If ColN[I] = 0 Then
  Begin
    EmptySlot(SlotX(I), ColY, '', False);
    Exit;
  End;
  Sp := StepOf(I);
  For K := 0 To ColN[I] - 1 Do
  Begin
    Y := ColY + K * Sp;
    Hl := (SelZ = 2) And (SelI = I) And (K >= SelK);
    If K < ColN[I] - 1 Then PartAt(SlotX(I), Y, Col[I, K], Hl) Else CardAt(SlotX(I), Y, Col[I, K], Hl);
  End;
End;

Procedure DrawStatus;
Var S : String;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
  S := 'Donne ' + IStr(DealNo) + '  Coups ' + IStr(Moves);
  FBar(CW - 12 - Length(S) * 8, CH - 20, CW - 4, CH - 3, CLR_PALEGRAY);
  Edge(CW - 14 - Length(S) * 8, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(CW - 8 - Length(S) * 8, CH - 19, S, CLR_DARKBLUE, CLR_PALEGRAY);
End;

Procedure DrawWin;
Var X, Y, W : LongInt; S : String;
Begin
  If Won = 0 Then Exit;
  W := 380; X := (CW - W) Div 2; Y := 196;
  FBar(X, Y, X + W - 1, Y + 96, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + 96, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + 95, CLR_PALEGRAY, CLR_DARKGRAY);
  FBar(X + 3, Y + 3, X + W - 4, Y + 21, CLR_DARKBLUE);
  OutTxt(X + 8, Y + 4, 'FreeCell', CLR_WHITE, CLR_DARKBLUE);
  BigText(X + (W - 13 * 16) Div 2, Y + 28, 'Vous gagnez !', CLR_DARKGREEN, CLR_PALEGRAY);
  S := 'Donne ' + IStr(DealNo) + ' en ' + IStr(Moves) + ' coups. F2 : nouvelle donne.';
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + 68, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintAll(H : LongInt);
Var I : LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 23, CLR_DARKGREEN);
  DrawTop;
  For I := 0 To 7 Do DrawColumn(I);
  DrawWin;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  If Client <> 0 Then Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ ==================================================================== }
{ Coups                                                                 }
{ ==================================================================== }

Procedure PlayMsg;
Begin
  Msg := 'Cliquez une carte, puis sa destination.';
End;

Procedure CheckWin;
Begin
  If (Won = 0) And (Found[0] + Found[1] + Found[2] + Found[3] = 52) Then
  Begin
    Won := 1;
    Inc(Wins); Inc(Streak);
    Msg := 'Bravo ! Parties gagn' + Chr(130) + 'es : ' + IStr(Wins) + ' sur ' + IStr(Played) + '.';
    Pending := 0;
  End;
End;

{ une carte monte seule si elle ne sert plus (une par tic de l'horloge) }
Function AutoStep : Boolean;
Var I, C : LongInt;
Begin
  AutoStep := False;
  If AutoF = 0 Then Exit;
  For I := 0 To 3 Do
    If (FreeC[I] >= 0) And SafeFound(FreeC[I]) Then
    Begin
      C := FreeC[I]; FreeC[I] := -1; Inc(Found[Suit(C)]);
      AutoStep := True;
      Exit;
    End;
  For I := 0 To 7 Do
    If ColN[I] > 0 Then
      If SafeFound(Col[I, ColN[I] - 1]) Then
      Begin
        C := Col[I, ColN[I] - 1]; Dec(ColN[I]); Inc(Found[Suit(C)]);
        AutoStep := True;
        Exit;
      End;
End;

Procedure AfterMove;
Begin
  Inc(Moves);
  SelZ := 0;
  If Moves = 1 Then Inc(Played);
  PlayMsg;
  Pending := 1;
  CheckWin;
  Redraw;
End;

{ carte (ou suite) choisie ; Count : nombre de cartes }
Procedure SelInfo(Var Top, Count : LongInt);
Begin
  If SelZ = 1 Then Begin Top := FreeC[SelI]; Count := 1; End
  Else Begin Top := Col[SelI, SelK]; Count := ColN[SelI] - SelK; End;
End;

Procedure RemoveSel;
Begin
  If SelZ = 1 Then FreeC[SelI] := -1 Else ColN[SelI] := SelK;
End;

Function ToFreeCell(I : LongInt) : Boolean;
Var Top, Cnt : LongInt;
Begin
  ToFreeCell := False;
  If SelZ = 0 Then Exit;
  SelInfo(Top, Cnt);
  If (Cnt <> 1) Or (FreeC[I] >= 0) Then Exit;
  PushUndo;
  RemoveSel;
  FreeC[I] := Top;
  ToFreeCell := True;
  AfterMove;
End;

Function ToFoundation : Boolean;
Var Top, Cnt : LongInt;
Begin
  ToFoundation := False;
  If SelZ = 0 Then Exit;
  SelInfo(Top, Cnt);
  If (SelZ = 2) And (Cnt > 1) Then
  Begin
    { la derniere carte de la suite seulement }
    SelK := ColN[SelI] - 1;
    SelInfo(Top, Cnt);
  End;
  If Not CanFound(Top) Then Exit;
  PushUndo;
  RemoveSel;
  Inc(Found[Suit(Top)]);
  ToFoundation := True;
  AfterMove;
End;

Function ToColumn(I : LongInt) : Boolean;
Var Top, Cnt, K, M : LongInt;
Begin
  ToColumn := False;
  If SelZ = 0 Then Exit;
  If (SelZ = 2) And (SelI = I) Then Exit;
  SelInfo(Top, Cnt);
  M := MaxMove(ColN[I] = 0);
  If ColN[I] = 0 Then
  Begin
    { colonne vide : la plus longue partie possible de la suite }
    If Cnt > M Then
    Begin
      If SelZ = 2 Then SelK := ColN[SelI] - M;
      SelInfo(Top, Cnt);
    End;
  End
  Else
  Begin
    { la partie de la suite qui se pose sur la carte du bas }
    If SelZ = 2 Then
    Begin
      K := SelK;
      While (K < ColN[SelI]) And Not Fits(Col[SelI, K], Col[I, ColN[I] - 1]) Do Inc(K);
      If K >= ColN[SelI] Then Exit;
      SelK := K;
      SelInfo(Top, Cnt);
    End
    Else If Not Fits(Top, Col[I, ColN[I] - 1]) Then Exit;
    If Cnt > M Then
    Begin
      Msg := 'Pas assez de cellules libres pour d' + Chr(130) + 'placer ' + IStr(Cnt) + ' cartes (au plus ' +
             IStr(M) + ').';
      Exit;
    End;
  End;
  PushUndo;
  For K := 0 To Cnt - 1 Do
  Begin
    If SelZ = 1 Then Col[I, ColN[I]] := Top Else Col[I, ColN[I]] := Col[SelI, SelK + K];
    Inc(ColN[I]);
  End;
  RemoveSel;
  ToColumn := True;
  AfterMove;
End;

{ choix d'une carte de la colonne I a partir de K (la suite doit etre ordonnee) }
Procedure SelectCol(I, K : LongInt);
Begin
  If ColN[I] = 0 Then Exit;
  If K < 0 Then K := ColN[I] - 1;
  If Not RunOk(I, K) Then
  Begin
    { la plus longue suite ordonnee qui finit en bas }
    K := ColN[I] - 1;
    While (K > 0) And Fits(Col[I, K], Col[I, K - 1]) Do Dec(K);
    Msg := 'Seule une suite ordonn' + Chr(130) + 'e (rouge sur noir, en descendant) se d' + Chr(130) + 'place.';
  End
  Else PlayMsg;
  SelZ := 2; SelI := I; SelK := K;
  Redraw;
End;

Procedure ColClick(I, K : LongInt);
Begin
  If SelZ = 0 Then SelectCol(I, K)
  Else If (SelZ = 2) And (SelI = I) Then
  Begin
    SelZ := 0;
    Redraw;
  End
  Else If Not ToColumn(I) Then
  Begin
    If Pos('Pas assez', Msg) = 0 Then
      Msg := 'Ce coup n''est pas permis : une carte va sur la carte suivante de l''autre couleur.';
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    SelZ := 0;
    Redraw;
  End;
End;

Procedure FreeClick(I : LongInt);
Begin
  If SelZ = 0 Then
  Begin
    If FreeC[I] >= 0 Then
    Begin
      SelZ := 1; SelI := I;
      Redraw;
    End;
  End
  Else If (SelZ = 1) And (SelI = I) Then
  Begin
    SelZ := 0;
    Redraw;
  End
  Else If FreeC[I] >= 0 Then
  Begin
    SelZ := 1; SelI := I;
    Redraw;
  End
  Else If Not ToFreeCell(I) Then
  Begin
    Msg := 'Une cellule libre ne re' + Chr(135) + 'oit qu''une carte.';
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    SelZ := 0;
    Redraw;
  End;
End;

Procedure FoundClick;
Begin
  If SelZ = 0 Then Exit;
  If Not ToFoundation Then
  Begin
    Msg := 'Les fondations montent de l''as au roi, une couleur chacune.';
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    SelZ := 0;
    Redraw;
  End;
End;

{ double clic : la carte du bas va a sa fondation, sinon dans une cellule }
Procedure DoubleClick;
Var I : LongInt;
Begin
  If SelZ = 0 Then Exit;
  If SelZ = 2 Then SelK := ColN[SelI] - 1;
  If ToFoundation Then Exit;
  If SelZ = 1 Then Exit;
  For I := 0 To 3 Do
    If FreeC[I] < 0 Then
    Begin
      If ToFreeCell(I) Then Exit;
    End;
End;

Procedure UndoMove;
Begin
  If NUndo = 0 Then Exit;
  Dec(NUndo);
  LoadState(NUndo * SnapSz);
  If Moves > 0 Then Dec(Moves);
  SelZ := 0; Won := 0; Pending := 0;
  Msg := 'Coup annul' + Chr(130) + '.';
  Redraw;
End;

Procedure NewDeal(N : LongInt);
Begin
  If (Moves > 0) And (Won = 0) Then Streak := 0;
  DealNo := N;
  DealGame(N);
  AutoMoves := 0;
  PlayMsg;
  Pending := 1;
  Redraw;
End;

{ demonstration : coups simples (pas un solveur) }
Function AutoPlay : Boolean;
Var I, J, K, Best0, Bk, Sc, Bs : LongInt;
Begin
  AutoPlay := False;
  If AutoMoves > 300 Then Exit;
  { vers une fondation }
  For I := 0 To 3 Do
    If (FreeC[I] >= 0) And CanFound(FreeC[I]) Then
    Begin
      SelZ := 1; SelI := I;
      AutoPlay := ToFoundation;
      Exit;
    End;
  For I := 0 To 7 Do
    If (ColN[I] > 0) And CanFound(Col[I, ColN[I] - 1]) Then
    Begin
      SelZ := 2; SelI := I; SelK := ColN[I] - 1;
      AutoPlay := ToFoundation;
      Exit;
    End;
  { cellule vers colonne }
  For I := 0 To 3 Do
    If FreeC[I] >= 0 Then
      For J := 0 To 7 Do
        If (ColN[J] > 0) And Fits(FreeC[I], Col[J, ColN[J] - 1]) Then
        Begin
          SelZ := 1; SelI := I;
          AutoPlay := ToColumn(J);
          Exit;
        End;
  { suite vers une autre colonne (la plus longue, qui decouvre le plus) }
  Bs := 0; Best0 := -1; Bk := 0;
  For I := 0 To 7 Do
    If ColN[I] > 0 Then
    Begin
      K := ColN[I] - 1;
      While (K > 0) And Fits(Col[I, K], Col[I, K - 1]) Do Dec(K);
      If K > 0 Then
        For J := 0 To 7 Do
          If (J <> I) And (ColN[J] > 0) Then
            If Fits(Col[I, K], Col[J, ColN[J] - 1]) And (ColN[I] - K <= MaxMove(False)) Then
            Begin
              Sc := 10 + ColN[I] - K;
              If Sc > Bs Then Begin Bs := Sc; Best0 := I * 8 + J; Bk := K; End;
            End;
    End;
  If Best0 >= 0 Then
  Begin
    SelZ := 2; SelI := Best0 Div 8; SelK := Bk;
    AutoPlay := ToColumn(Best0 Mod 8);
    Exit;
  End;
  { une carte dans une cellule libre, si elle decouvre une carte utile }
  If FreeCount > 1 Then
    For I := 0 To 7 Do
      If ColN[I] > 1 Then
      Begin
        K := Col[I, ColN[I] - 2];
        Sc := 0;
        If CanFound(K) Then Sc := 1;
        For J := 0 To 7 Do
          If (J <> I) And (ColN[J] > 0) Then If Fits(K, Col[J, ColN[J] - 1]) Then Sc := 1;
        If Sc <> 0 Then
          For J := 0 To 3 Do
            If FreeC[J] < 0 Then
            Begin
              SelZ := 2; SelI := I; SelK := ColN[I] - 1;
              AutoPlay := ToFreeCell(J);
              Exit;
            End;
      End;
  SelZ := 0;
End;

Procedure TimerTick;
Begin
  If Pending <> 0 Then
  Begin
    If AutoStep Then
    Begin
      CheckWin;
      Redraw;
      Exit;
    End;
    Pending := 0;
  End;
  If (AutoAll <> 0) And (Won = 0) Then
  Begin
    If Not AutoPlay Then AutoMoves := 9999 Else Inc(AutoMoves);
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
  SetMark(CM_AUTOF, AutoF <> 0); SetMark(CM_MULTI, Multi <> 0);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewDeal(1 + Rnd(32000));
    CM_NEXT : NewDeal(DealNo Mod 32000 + 1);
    CM_RESTART : NewDeal(DealNo);
    CM_UNDO : UndoMove;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTOF : Begin AutoF := 1 - AutoF; SetMarks; Pending := 1; End;
    CM_MULTI : Begin Multi := 1 - Multi; SetMarks; End;
    CM_RULES :
      Begin
        LClr;
        LAdd('But : monter les 52 cartes sur les quatre fondations (en haut ' + Chr(133) + ' droite), une ' +
             'couleur chacune, de l''as au roi.' + Chr(10) + Chr(10));
        LAdd('Les cartes sont toutes visibles, en huit colonnes. Sur une colonne, une carte se pose sur la ' +
             'carte de valeur imm' + Chr(130) + 'diatement sup' + Chr(130) + 'rieure et de l''autre couleur ' +
             '(un 7 rouge sur un 8 noir). Toute carte va sur une colonne vide. ');
        LAdd('Les quatre cellules libres (en haut ' + Chr(133) + ' gauche) gardent chacune une carte.' +
             Chr(10) + Chr(10));
        LAdd('Une suite ordonn' + Chr(130) + 'e se d' + Chr(130) + 'place d''un coup s''il y a assez de cellules ' +
             'libres et de colonnes vides pour le faire carte par carte. Les cartes qui ne servent plus montent ' +
             'seules aux fondations (menu Options).' + Chr(10) + Chr(10));
        LAdd('Souris : cliquer une carte puis sa destination ; double clic : vers la fondation ou une cellule. ' +
             'Clavier : 1 ' + Chr(133) + ' 8, A ' + Chr(133) + ' D, H, Echap, Retour arri' + Chr(138) + 're ' +
             '(annuler), F2, F3.');
        Dummy := LMsgBox('FreeCell - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('FreeCell pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'FREECELL.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et ' +
                            'compil' + Chr(130) + ' par OS2PC.', 'A propos de FreeCell', MB_OK Or MB_INFORMATION);
  End;
End;

{ ou est le clic ? }
Procedure Click(Mx, My : LongInt; Dbl : Boolean);
Var X, Y, I, K, Sp : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If Won <> 0 Then Exit;
  I := (X - SX0) Div SDX;
  If (X < SX0) Or (I > 7) Or (X - SlotX(I) >= CardW) Then
  Begin
    SelZ := 0;
    Redraw;
    Exit;
  End;
  If (Y >= TopY) And (Y < TopY + CardH) Then
  Begin
    If I < 4 Then
    Begin
      If Dbl And (SelZ = 1) And (SelI = I) Then DoubleClick Else FreeClick(I);
    End
    Else FoundClick;
    Exit;
  End;
  If Y >= ColY Then
  Begin
    If ColN[I] = 0 Then
    Begin
      If SelZ <> 0 Then ColClick(I, 0);
      Exit;
    End;
    Sp := StepOf(I);
    K := (Y - ColY) Div Sp;
    If K >= ColN[I] Then
    Begin
      If Y - ColY - (ColN[I] - 1) * Sp < CardH Then K := ColN[I] - 1 Else
      Begin
        If SelZ <> 0 Then ColClick(I, -1);
        Exit;
      End;
    End;
    If Dbl And (SelZ = 2) And (SelI = I) Then DoubleClick
    Else If Dbl And (SelZ = 0) Then Begin SelectCol(I, -1); DoubleClick; End
    Else ColClick(I, K);
  End;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk, I : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then Begin KeyChar := False; Exit; End;
  If ((Fl And KC_CTRL) <> 0) And ((Ch = 26) Or (UpCase(Chr(Ch)) = 'Z')) Then Begin UndoMove; Exit; End;
  If (Fl And (KC_CTRL Or KC_ALT)) <> 0 Then Begin KeyChar := False; Exit; End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_F3 Then Begin Command(CM_RESTART); Exit; End;
    If Vk = VK_BACKSPACE Then Begin UndoMove; Exit; End;
    If Vk = VK_ESC Then Begin SelZ := 0; Redraw; Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    If Won <> 0 Then Begin KeyChar := False; Exit; End;
    Case UpCase(Chr(Ch)) Of
      '1'..'8' :
        Begin
          I := Ch - Ord('1');
          If SelZ = 0 Then SelectCol(I, -1) Else ColClick(I, -1);
        End;
      'A'..'D' : FreeClick(Ord(UpCase(Chr(Ch))) - Ord('A'));
      'H' : FoundClick;
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
        Click(S16(Mp1), S16(Mp1 Shr 16), False);
        MainProc := 1;
      End;
    WM_BUTTON1DBLCLK :
      Begin
        Click(S16(Mp1), S16(Mp1 Shr 16), True);
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
  Flg, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y, D0 : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; AutoAll := 0; Client := 0; Frame := 0; AutoF := 1; Multi := 1; Wins := 0; Played := 0; Streak := 0;
  Pending := 0; D0 := 0; Moves := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/DEAL:') Then Val(Copy(S, 7, 20), D0, E);
    If S = '/AUTO' Then AutoAll := 1;
  End;
  If (D0 < 1) Or (D0 > 32000) Then D0 := 1 + Rnd(32000);
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('FREECELL'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('FREECELL'), Z2('FreeCell'), 0, 0, 0,
                              LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle donne' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_NEXT, 'Donne ~suivante');
  MItem(MIS_TEXT, 0, CM_RESTART, '~Rejouer la donne' + Chr(9) + 'F3');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_AUTOF, 'Cartes aux ~fondations automatiquement');
  MItem(MIS_TEXT, 0, CM_MULTI, '~D' + Chr(130) + 'placer plusieurs cartes ' + Chr(133) + ' la fois');
  MenuClose(H3, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de FreeCell');
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
  NewDeal(D0);
  If AutoAll <> 0 Then Dummy := WinStartTimer(Hab, Client, 1, 250)
  Else Dummy := WinStartTimer(Hab, Client, 1, 90);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
