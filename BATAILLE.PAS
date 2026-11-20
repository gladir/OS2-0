{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BATAILLE - Bataille (jeu de cartes a deux joueurs) pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program BATAILLE;

{$R-,S-,I-}

{ Compilation : OS2PC BATAILLE.PAS   (produit BATAILLE.EXE)

  Portage vers OS/2-0 du prototype BATAILLE.PAS du depot 7iles (Turbo
  Pascal et BGI : cartes en rectangles, Espace pour jouer, N pour
  rejouer) : fenetre de Presentation Manager avec menus, tapis de jeu,
  paquets en relief, cartes dessinees (celles du Poker d'OS/2-0)
  retournees une a une, bataille montree carte par carte, panneau du
  compte des cartes, jeu automatique, barre d'etat et apparence d'OS/2.

  Regles du prototype : 52 cartes, 26 chacun ; chacun retourne la carte
  du dessus, la plus forte (l'as est la plus forte) remporte les deux ;
  a egalite, bataille : chacun pose trois cartes cachees et une
  visible, la plus forte remporte le tout (et ainsi de suite) ; celui qui
  n'a plus de cartes a perdu. Le prototype perdait les cartes d'une
  bataille qu'un joueur ne pouvait pas finir : ici, ce joueur perd la
  partie. Les cartes gagnees vont sous le paquet dans un ordre melange
  (une partie ne peut donc pas tourner en rond sans fin).

  Souris : cliquer le tapis ou le bouton Jouer. Clavier : Espace ou
  Entree (jouer), A (jeu automatique), N ou F2 (nouvelle partie), F1
  (regles).
  Parametres : /SEED:n ; /AUTO (jeu automatique) ; /BATAILLE (essai : le
  premier pli est une bataille). }

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
  DRO_FILL = 1; DRO_OUTLINE = 2;
  CM_NEW = 101; CM_PLAY = 102; CM_AUTO = 103; CM_QUIT = 104;
  CM_SLOW = 201; CM_NORMAL = 202; CM_FAST = 203;
  CM_RULES = 301; CM_ABOUT = 302;
  CardW = 70; CardH = 96;
  TX1 = 6; TY1 = 6; TX2 = 452; TY2 = 412;  { tapis }
  PnX = 462; PW = 150;
  CWant = 618; CHWant = 440;
  BY1 = 250; BY2 = 286; BY3 = 322; BH = 30;  { boutons }
  PileX = 22; PileYC = 24; PileYY = 266;      { paquets : ordinateur en haut, vous en bas }
  RowYC = 60; RowYY = 246; X0 = 128;          { cartes jouees }
  PH_IDLE = 0; PH_REVEAL = 1; PH_DONE = 2; PH_OVER = 3;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  { paquets : 0 vous, 1 ordinateur (la carte du dessus est la premiere) }
  Pile : Array[0..1, 0..51] Of LongInt;
  NPile : Array[0..1] Of LongInt;
  { cartes sur le tapis, dans l'ordre ou elles sont retournees }
  TOwn, TCard, TUp, TLev, TIdx : Array[0..63] Of LongInt;
  NTable, Shown, Levels, RoundWin, GameWin, Phase, Tick0, Rounds, Battles, WinsY, WinsC : LongInt;
  BattleNow, AutoPlay, Speed, Seed, AutoAll, Wait, ForceBattle : LongInt;
  Deck : Array[0..51] Of LongInt;
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

{ force d'une carte : 2 a 14 (l'as est la plus forte) }
Function Force(C : LongInt) : LongInt;
Begin
  If Rank(C) = 0 Then Force := 14 Else Force := Rank(C) + 1;
End;

Function PopTop(P : LongInt) : LongInt;
Var K : LongInt;
Begin
  PopTop := Pile[P, 0];
  For K := 0 To NPile[P] - 2 Do Pile[P, K] := Pile[P, K + 1];
  Dec(NPile[P]);
End;

Procedure PushBottom(P, C : LongInt);
Begin
  If NPile[P] < 52 Then
  Begin
    Pile[P, NPile[P]] := C;
    Inc(NPile[P]);
  End;
End;

Procedure PutTable(Own, C, Up, Lev, Idx : LongInt);
Begin
  TOwn[NTable] := Own; TCard[NTable] := C; TUp[NTable] := Up; TLev[NTable] := Lev; TIdx[NTable] := Idx;
  Inc(NTable);
End;

{ un tour complet (avec ses batailles), retourne ensuite carte par carte }
Procedure BuildRound;
Var A, B, Lev, K, Cmp : LongInt;
Begin
  NTable := 0; Shown := 0; Levels := 0; RoundWin := -1; GameWin := -1;
  Lev := 0;
  A := PopTop(0); B := PopTop(1);
  PutTable(1, B, 1, 0, 3); PutTable(0, A, 1, 0, 3);
  Cmp := Force(A) - Force(B);
  While Cmp = 0 Do
  Begin
    Inc(Battles);
    { bataille : trois cartes cachees et une visible chacun }
    If (NPile[0] < 4) Or (NPile[1] < 4) Then
    Begin
      If NPile[0] < NPile[1] Then GameWin := 1 Else GameWin := 0;
      RoundWin := GameWin;
      Levels := Lev;
      Exit;
    End;
    Inc(Lev);
    For K := 0 To 2 Do
    Begin
      PutTable(1, PopTop(1), 0, Lev, K);
      PutTable(0, PopTop(0), 0, Lev, K);
    End;
    A := PopTop(0); B := PopTop(1);
    PutTable(1, B, 1, Lev, 3); PutTable(0, A, 1, Lev, 3);
    Cmp := Force(A) - Force(B);
  End;
  Levels := Lev;
  If Cmp > 0 Then RoundWin := 0 Else RoundWin := 1;
End;

{ le gagnant ramasse : sous son paquet, dans un ordre melange }
Procedure Collect;
Var K, J, T : LongInt; Tmp : Array[0..63] Of LongInt;
Begin
  If (RoundWin < 0) Or (NTable = 0) Then Exit;
  For K := 0 To NTable - 1 Do Tmp[K] := TCard[K];
  For K := NTable - 1 DownTo 1 Do
  Begin
    J := Rnd(K + 1);
    T := Tmp[K]; Tmp[K] := Tmp[J]; Tmp[J] := T;
  End;
  For K := 0 To NTable - 1 Do PushBottom(RoundWin, Tmp[K]);
  NTable := 0;
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Procedure CardAt(X, Y, C : LongInt; Face : Boolean);
Begin
  If Face Then DrawFace(Hps, X, CH - Y - CardH, C, False) Else DrawBack(Hps, X, CH - Y - CardH);
End;

{ paquet en relief (une epaisseur par six cartes) }
Procedure DrawPile(P, X, Y : LongInt; Lbl : String);
Var N, K : LongInt;
Begin
  N := NPile[P];
  If N = 0 Then
  Begin
    Edge(X, Y, X + CardW - 1, Y + CardH - 1, CLR_BLACK, CLR_GREEN);
    OutTxt(X + 12, Y + 40, 'vide', CLR_PALEGRAY, CLR_DARKGREEN);
  End
  Else
  Begin
    For K := MinI(5, (N - 1) Div 6) DownTo 0 Do CardAt(X + K * 2, Y - K * 2, 0, False);
  End;
  OutTxt(X, Y + CardH + 6, Lbl, CLR_WHITE, CLR_DARKGREEN);
  OutTxt(X, Y + CardH + 22, IStr(N) + ' cartes ', CLR_YELLOW, CLR_DARKGREEN);
End;

{ position d'une carte du tapis : niveau 0 (premier pli), puis une
  colonne par bataille (trois cartes cachees en eventail, puis la carte
  visible) }
Function SlotX(Lev, Idx : LongInt) : LongInt;
Var W, S : LongInt;
Begin
  If Lev = 0 Then
  Begin
    SlotX := X0;
    Exit;
  End;
  W := 110;
  If Levels > 0 Then W := MinI(110, 202 Div Levels);
  S := X0 + 78 + (Lev - 1) * W;
  If Idx < 3 Then SlotX := S + Idx * (W - 38) Div 4
  Else SlotX := S + W - 38;
End;

Procedure Banner(S : String; Bg : LongInt);
Var W, X : LongInt;
Begin
  W := Length(S) * 8 + 24;
  X := (TX1 + TX2) Div 2 - W Div 2 + 40;
  FBar(X, 174, X + W, 222, Bg);
  Edge(X, 174, X + W, 222, CLR_WHITE, CLR_BLACK);
  OutTxt(X + 12, 190, S, CLR_WHITE, Bg);
End;

Procedure DrawTable;
Var K : LongInt;
Begin
  FBar(TX1, TY1, TX2, TY2, CLR_BROWN);
  Edge(TX1, TY1, TX2, TY2, CLR_YELLOW, CLR_BLACK);
  FBar(TX1 + 8, TY1 + 8, TX2 - 8, TY2 - 8, CLR_DARKGREEN);
  Edge(TX1 + 8, TY1 + 8, TX2 - 8, TY2 - 8, CLR_BLACK, CLR_GREEN);
  DrawPile(1, PileX, PileYC, 'Ordinateur');
  DrawPile(0, PileX, PileYY, 'Vous');
  For K := 0 To Shown - 1 Do
    If TOwn[K] = 1 Then CardAt(SlotX(TLev[K], TIdx[K]), RowYC, TCard[K], TUp[K] <> 0)
    Else CardAt(SlotX(TLev[K], TIdx[K]), RowYY, TCard[K], TUp[K] <> 0);
  If Phase = PH_OVER Then
  Begin
    If GameWin = 0 Then Banner('Vous avez gagn' + Chr(130) + ' la partie !', CLR_DARKBLUE)
    Else Banner('L''ordinateur a gagn' + Chr(130) + ' la partie', CLR_DARKRED);
  End
  Else If BattleNow <> 0 Then Banner('B A T A I L L E  !', CLR_RED)
  Else If Phase = PH_DONE Then
  Begin
    If RoundWin = 0 Then Banner('Vous gagnez ' + IStr(NTable) + ' cartes', CLR_DARKBLUE)
    Else Banner('L''ordinateur gagne ' + IStr(NTable) + ' cartes', CLR_DARKRED);
  End
  Else If (Phase = PH_IDLE) And (Rounds = 0) Then
    OutTxt(X0 + 10, 196, 'Espace ou clic : jouer une carte', CLR_YELLOW, CLR_DARKGREEN);
End;

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_DARKGRAY, CLR_PALEGRAY);
End;

{ barre : part des 52 cartes }
Procedure Gauge(Y, N, C : LongInt);
Begin
  Edge(PnX + 6, Y, PnX + PW - 7, Y + 9, CLR_DARKGRAY, CLR_WHITE);
  FBar(PnX + 7, Y + 1, PnX + PW - 8, Y + 8, CLR_PALEGRAY);
  If N > 0 Then FBar(PnX + 7, Y + 1, PnX + 7 + (PW - 15) * N Div 52, Y + 8, C);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 8 * 16) Div 2, 10, 'BATAILLE', CLR_DARKBLUE, CLR_PALEGRAY);
  FBar(PnX, 48, PnX + PW - 1, 236, CLR_WHITE);
  Edge(PnX, 48, PnX + PW - 1, 236, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(PnX + 6, 54, 'Vous : ' + IStr(NPile[0]), CLR_DARKBLUE, CLR_WHITE);
  Gauge(72, NPile[0], CLR_BLUE);
  OutTxt(PnX + 6, 88, 'Ordinateur : ' + IStr(NPile[1]), CLR_DARKRED, CLR_WHITE);
  Gauge(106, NPile[1], CLR_RED);
  OutTxt(PnX + 6, 126, 'Plis : ' + IStr(Rounds), CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 6, 144, 'Batailles : ' + IStr(Battles), CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 6, 168, 'Parties gagn' + Chr(130) + 'es', CLR_DARKGRAY, CLR_WHITE);
  OutTxt(PnX + 6, 186, 'Vous : ' + IStr(WinsY), CLR_DARKBLUE, CLR_WHITE);
  OutTxt(PnX + 6, 204, 'Ordinateur : ' + IStr(WinsC), CLR_DARKRED, CLR_WHITE);
  Button(PnX, BY1, PW, BH, 'Jouer', Phase <> PH_OVER);
  If AutoPlay <> 0 Then Button(PnX, BY2, PW, BH, 'Arr' + Chr(136) + 'ter', True)
  Else Button(PnX, BY2, PW, BH, 'Jeu automatique', Phase <> PH_OVER);
  Button(PnX, BY3, PW, BH, 'Nouvelle partie', True);
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
  { pas d'effacement de toute la fenetre : moins de scintillement }
  FBar(0, 0, TX1 - 1, CH - 1, CLR_PALEGRAY);
  FBar(TX2 + 1, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  FBar(TX1, 0, TX2, TY1 - 1, CLR_PALEGRAY);
  FBar(TX1, TY2 + 1, TX2, CH - 23, CLR_PALEGRAY);
  DrawTable;
  DrawPanel;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  If Client <> 0 Then Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure NewGame;
Var K, J, T : LongInt;
Begin
  For K := 0 To 51 Do Deck[K] := K;
  For K := 51 DownTo 1 Do
  Begin
    J := Rnd(K + 1);
    T := Deck[K]; Deck[K] := Deck[J]; Deck[J] := T;
  End;
  For K := 0 To 25 Do
  Begin
    Pile[0, K] := Deck[K * 2];
    Pile[1, K] := Deck[K * 2 + 1];
  End;
  NPile[0] := 26; NPile[1] := 26;
  { /BATAILLE (essai) : le premier pli est une bataille }
  If ForceBattle <> 0 Then
  Begin
    K := 1;
    While (K < 26) And (Rank(Pile[1, K]) <> Rank(Pile[0, 0])) Do Inc(K);
    If K < 26 Then Begin T := Pile[1, 0]; Pile[1, 0] := Pile[1, K]; Pile[1, K] := T; End;
    ForceBattle := 0;
  End;
  NTable := 0; Shown := 0; Rounds := 0; Battles := 0; BattleNow := 0; RoundWin := -1; GameWin := -1;
  Phase := PH_IDLE; Wait := 0;
  Msg := 'Espace (ou clic sur le tapis) : retourner une carte. A : jeu automatique.';
  Redraw;
End;

Procedure GameOver(W : LongInt);
Begin
  GameWin := W;
  Phase := PH_OVER;
  If W = 0 Then Inc(WinsY) Else Inc(WinsC);
  If W = 0 Then Msg := 'Vous avez gagn' + Chr(130) + ' en ' + IStr(Rounds) + ' plis ! N : nouvelle partie.'
  Else Msg := 'L''ordinateur a gagn' + Chr(130) + ' en ' + IStr(Rounds) + ' plis. N : nouvelle partie.';
  AutoPlay := AutoAll;
  Wait := 0;
  Redraw;
End;

{ jouer : ramasser le pli precedent puis retourner les cartes suivantes }
Procedure PlayNext;
Begin
  If Phase = PH_OVER Then Exit;
  If Phase = PH_REVEAL Then
  Begin
    Shown := NTable;
    Exit;
  End;
  If Phase = PH_DONE Then
  Begin
    Collect;
    If (GameWin >= 0) Or (NPile[0] = 0) Or (NPile[1] = 0) Then
    Begin
      If GameWin < 0 Then
      Begin
        If NPile[0] = 0 Then GameWin := 1 Else GameWin := 0;
      End;
      GameOver(GameWin);
      Exit;
    End;
  End;
  Inc(Rounds);
  BuildRound;
  Phase := PH_REVEAL; Tick0 := 0; BattleNow := 0;
  Msg := 'Pli ' + IStr(Rounds) + '.';
  Redraw;
End;

Procedure RevealDone;
Begin
  Phase := PH_DONE; BattleNow := 0; Wait := 0;
  If GameWin >= 0 Then
  Begin
    If GameWin = 0 Then Msg := 'L''ordinateur n''a plus assez de cartes pour la bataille !'
    Else Msg := 'Vous n''avez plus assez de cartes pour la bataille !';
  End
  Else If RoundWin = 0 Then Msg := 'Vous gagnez le pli (' + IStr(NTable) + ' cartes). Espace : continuer.'
  Else Msg := 'L''ordinateur gagne le pli (' + IStr(NTable) + ' cartes). Espace : continuer.';
  Redraw;
End;

Procedure TimerTick;
Var Step : LongInt;
Begin
  Case Speed Of
    0 : Step := 8;
    2 : Step := 2;
  Else
    Step := 4;
  End;
  If Phase = PH_REVEAL Then
  Begin
    Inc(Tick0);
    If Tick0 >= Step Then
    Begin
      Tick0 := 0;
      { une paire a la fois : l'ordinateur puis vous }
      Shown := MinI(Shown + 2, NTable);
      If (Shown >= 2) And (Shown < NTable) And (TUp[Shown - 1] <> 0) And
         (Force(TCard[Shown - 1]) = Force(TCard[Shown - 2])) Then BattleNow := 1
      Else If (Shown < NTable) And (TUp[Shown - 1] = 0) Then BattleNow := 1
      Else BattleNow := 0;
      If BattleNow <> 0 Then Msg := 'Bataille ! Trois cartes cach' + Chr(130) + 'es et une visible chacun.';
      If Shown >= NTable Then RevealDone Else Redraw;
    End;
  End
  Else If (AutoPlay <> 0) And (Phase <> PH_OVER) Then
  Begin
    Inc(Wait);
    If Wait > Step * 4 Then
    Begin
      Wait := 0;
      PlayNext;
    End;
  End
  Else If (Phase = PH_OVER) And (AutoAll <> 0) Then
  Begin
    Inc(Wait);
    If Wait > 60 Then NewGame;
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
  SetMark(CM_SLOW, Speed = 0); SetMark(CM_NORMAL, Speed = 1); SetMark(CM_FAST, Speed = 2);
  SetMark(CM_AUTO, AutoPlay <> 0);
End;

Procedure ToggleAuto;
Begin
  If AutoPlay <> 0 Then AutoPlay := 0 Else AutoPlay := 1;
  SetMarks;
  If AutoPlay <> 0 Then Msg := 'Jeu automatique : A pour l''arr' + Chr(136) + 'ter.'
  Else Msg := 'Jeu automatique arr' + Chr(136) + 't' + Chr(130) + '. Espace : jouer.';
  Redraw;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_PLAY : PlayNext;
    CM_AUTO : ToggleAuto;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_SLOW, CM_NORMAL, CM_FAST :
      Begin
        Speed := Id - CM_SLOW;
        SetMarks;
      End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Les 52 cartes sont partag' + Chr(130) + 'es : 26 pour vous, 26 pour l''ordinateur. Chacun ' +
             'retourne la carte du dessus de son paquet ; la plus forte remporte les deux cartes. ');
        LAdd('L''as est la plus forte, puis le roi, la dame, le valet, le 10... jusqu''au 2.' + Chr(10) + Chr(10));
        LAdd('A ' + Chr(130) + 'galit' + Chr(130) + ', c''est la bataille : chacun pose trois cartes ' +
             'cach' + Chr(130) + 'es et une visible ; la plus forte remporte toutes les cartes (et s''il y a ' +
             'encore ' + Chr(130) + 'galit' + Chr(130) + ', on recommence). ');
        LAdd('Celui qui n''a plus de cartes, ou plus assez pour une bataille, a perdu.' + Chr(10) + Chr(10));
        LAdd('Espace, Entr' + Chr(130) + 'e ou clic : jouer. A : jeu automatique. N ou F2 : nouvelle partie.');
        Dummy := LMsgBox('Bataille - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Bataille pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'BATAILLE.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et ' +
                            'compil' + Chr(130) + ' par OS2PC.', 'A propos de Bataille', MB_OK Or MB_INFORMATION);
  End;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= BY1) And (Y < BY1 + BH) Then PlayNext
    Else If (Y >= BY2) And (Y < BY2 + BH) Then ToggleAuto
    Else If (Y >= BY3) And (Y < BY3 + BH) Then NewGame;
    Exit;
  End;
  If (X >= TX1) And (X <= TX2) And (Y >= TY1) And (Y <= TY2) Then
  Begin
    If Phase = PH_OVER Then NewGame Else PlayNext;
  End;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And (KC_KEYUP Or KC_CTRL Or KC_ALT)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin NewGame; Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      If Phase = PH_OVER Then NewGame Else PlayNext;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'A' : ToggleAuto;
      'N' : NewGame;
      ' ' : PlayNext;
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
  Msg := ''; AutoAll := 0; AutoPlay := 0; ForceBattle := 0; Speed := 1; Wait := 0; Client := 0; Frame := 0; WinsY := 0; WinsC := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
    If (S = '/AUTO') Or (S = '/auto') Then AutoAll := 1;
    If (S = '/BATAILLE') Or (S = '/bataille') Then ForceBattle := 1;
  End;
  AutoPlay := AutoAll;
  If AutoAll <> 0 Then Speed := 2;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('BATAILLE'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('BATAILLE'), Z2('Bataille'), 0, 0, 0,
                              LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_PLAY, '~Jouer une carte' + Chr(9) + 'Espace');
  MItem(MIS_TEXT, 0, CM_AUTO, 'Jeu ~automatique' + Chr(9) + 'A');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_SLOW, 'Vitesse ~lente');
  MItem(MIS_TEXT, 0, CM_NORMAL, 'Vitesse ~normale');
  MItem(MIS_TEXT, 0, CM_FAST, 'Vitesse ~rapide');
  MenuClose(H3, 3);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Bataille');
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
  Dummy := WinStartTimer(Hab, Client, 1, 45);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
