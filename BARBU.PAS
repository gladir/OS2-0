{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BARBU - Barbu (jeu de levees a quatre, a contrats) pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program BARBU;

{$R-,S-,I-}

{ Compilation : OS2PC BARBU.PAS   (produit BARBU.EXE)

  Portage vers OS/2-0 du prototype BARBU.PAS du depot 7iles (Turbo
  Pascal et BGI : cartes en rectangles, clic pour jouer, C pour changer
  de contrat) : fenetre de Presentation Manager avec menus, tapis de
  jeu, cartes dessinees (celles du Poker d'OS/2-0), mains de l'ordinateur
  en eventail, levee au centre, panneau des pointages, choix du contrat,
  barre d'etat et apparence d'OS/2.

  Comme le prototype : vous (Sud) contre Ouest, Nord et Est, 13 cartes
  chacun ; il faut fournir a la couleur demandee ; la plus haute carte de
  la couleur demandee remporte la levee ; contrats Pas de levees (2 par
  levee), Pas de coeurs (2 par coeur), Pas de dames (6 par dame), Pas le
  roi de coeur (le Barbu, 16) et Pas la derniere levee (16) ; le moins de
  points gagne. Ce qui est ajoute : la Salade (tous les contrats a la
  fois), le donneur qui choisit son contrat, une partie courte (6 donnes,
  chaque contrat une fois) ou complete (24 donnes, chaque donneur joue
  chaque contrat), l'as le plus fort (le prototype en faisait la plus
  basse carte), la fin de la donne quand toutes les penalites sont
  tombees, les coeurs qu'on n'entame pas tant qu'on a autre chose
  (contrats a coeurs), le roi de coeur a defausser des qu'on ne peut pas
  fournir (Barbu), et un ordinateur qui evite les levees et se defait de
  ses cartes dangereuses.

  Souris : cliquer une carte de votre main (les cartes jouables sont
  surlignees), cliquer un contrat. Clavier : fleches gauche et droite et
  Entree (jouer), 1 a 6 (contrat), N ou Entree (donne suivante), F2
  (nouvelle partie), F1 (regles).
  Parametres : /SEED:n ; /AUTO (l'ordinateur joue aussi pour vous). }

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
  CM_NEW = 101; CM_NEXT = 102; CM_QUIT = 104;
  CM_SHORT = 201; CM_LONG = 202;
  CM_RULES = 301; CM_ABOUT = 302;
  CardW = 70; CardH = 96;
  TX1 = 6; TY1 = 6; TX2 = 452; TY2 = 412;  { tapis }
  MidX = 229;
  PnX = 462; PW = 150;
  CWant = 618; CHWant = 440;
  BY1 = 340; BH = 30;
  HandY = 308;
  NK = 6;
  K_TRICKS = 0; K_HEARTS = 1; K_QUEENS = 2; K_BARBU = 3; K_LAST = 4; K_SALADE = 5;
  PH_CHOOSE = 0; PH_PLAY = 1; PH_TRICK = 2; PH_END = 3; PH_OVER = 4;
  KingHearts = 12;                         { roi de coeur : couleur 0, rang 12 }

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  { 0 Sud (vous), 1 Ouest, 2 Nord, 3 Est : dans le sens des aiguilles }
  Hand : Array[0..3, 0..12] Of LongInt;
  NHand, Total, DealPts, Tricks : Array[0..3] Of LongInt;
  TrickC, TrickP : Array[0..3] Of LongInt;
  NTrick, LeadSuit, TrickNo, LastWin, LastPts : LongInt;
  HeartsOut, QueensOut, BarbuOut : LongInt;
  Contract, Dealer, DealNo, NDeals, Short0 : LongInt;
  Remain : Array[0..3, 0..NK - 1] Of Byte;
  Phase, CurP, Sel, Thinking, Wait, Seed, AutoAll, Wins : LongInt;
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

{ valeur d'une carte : 2 a 14 (l'as est la plus forte) }
Function CVal(C : LongInt) : LongInt;
Begin
  If Rank(C) = 0 Then CVal := 14 Else CVal := Rank(C) + 1;
End;

Function IsQueen(C : LongInt) : Boolean;
Begin
  IsQueen := Rank(C) = 11;
End;

Function IsHeart(C : LongInt) : Boolean;
Begin
  IsHeart := Suit(C) = 0;
End;

Function PName(P : LongInt) : String;
Begin
  Case P Of
    0 : PName := 'Vous';
    1 : PName := 'Ouest';
    2 : PName := 'Nord';
  Else
    PName := 'Est';
  End;
End;

Function KName(K : LongInt) : String;
Begin
  Case K Of
    K_TRICKS : KName := 'Pas de lev' + Chr(130) + 'es';
    K_HEARTS : KName := 'Pas de coeurs';
    K_QUEENS : KName := 'Pas de dames';
    K_BARBU : KName := 'Le Barbu (roi de coeur)';
    K_LAST : KName := 'Pas la derni' + Chr(138) + 're';
  Else
    KName := 'La salade';
  End;
End;

Function KShort(K : LongInt) : String;
Begin
  Case K Of
    K_TRICKS : KShort := 'Lev' + Chr(130) + 'es : 2 par lev' + Chr(130) + 'e';
    K_HEARTS : KShort := 'Coeurs : 2 par coeur';
    K_QUEENS : KShort := 'Dames : 6 par dame';
    K_BARBU : KShort := 'Barbu : roi coeur 16';
    K_LAST : KShort := 'Derni' + Chr(138) + 're lev' + Chr(130) + 'e : 16';
  Else
    KShort := 'Salade : tout';
  End;
End;

Function HasSuit(P, S : LongInt) : Boolean;
Var K : LongInt;
Begin
  HasSuit := False;
  For K := 0 To NHand[P] - 1 Do If Suit(Hand[P, K]) = S Then HasSuit := True;
End;

Function HasCard(P, C : LongInt) : Boolean;
Var K : LongInt;
Begin
  HasCard := False;
  For K := 0 To NHand[P] - 1 Do If Hand[P, K] = C Then HasCard := True;
End;

Function OnlyHearts(P : LongInt) : Boolean;
Var K : LongInt;
Begin
  OnlyHearts := True;
  For K := 0 To NHand[P] - 1 Do If Not IsHeart(Hand[P, K]) Then OnlyHearts := False;
End;

Function HeartContract : Boolean;
Begin
  HeartContract := (Contract = K_HEARTS) Or (Contract = K_BARBU) Or (Contract = K_SALADE);
End;

{ carte jouable ? (fournir ; pas d'entame a coeur ; Barbu a defausser) }
Function Legal(P, I : LongInt) : Boolean;
Var C : LongInt;
Begin
  Legal := False;
  If (I < 0) Or (I >= NHand[P]) Then Exit;
  C := Hand[P, I];
  If NTrick = 0 Then
  Begin
    If HeartContract And IsHeart(C) And Not OnlyHearts(P) Then Exit;
    Legal := True;
    Exit;
  End;
  If HasSuit(P, LeadSuit) Then
  Begin
    Legal := Suit(C) = LeadSuit;
    Exit;
  End;
  If ((Contract = K_BARBU) Or (Contract = K_SALADE)) And HasCard(P, KingHearts) Then
  Begin
    Legal := C = KingHearts;
    Exit;
  End;
  Legal := True;
End;

{ joueur qui remporte la levee en cours, et sa plus forte carte }
Function TrickWinner : LongInt;
Var K, Best0, Bv : LongInt;
Begin
  Best0 := 0; Bv := -1;
  For K := 0 To NTrick - 1 Do
    If (Suit(TrickC[K]) = LeadSuit) And (CVal(TrickC[K]) > Bv) Then
    Begin
      Bv := CVal(TrickC[K]); Best0 := K;
    End;
  TrickWinner := TrickP[Best0];
End;

Function TrickHigh : LongInt;
Var K, Bv : LongInt;
Begin
  Bv := 0;
  For K := 0 To NTrick - 1 Do
    If (Suit(TrickC[K]) = LeadSuit) And (CVal(TrickC[K]) > Bv) Then Bv := CVal(TrickC[K]);
  TrickHigh := Bv;
End;

{ penalites de la levee terminee }
Function TrickPenalty : LongInt;
Var K, Hr, Qn, Kh, P : LongInt;
Begin
  Hr := 0; Qn := 0; Kh := 0;
  For K := 0 To 3 Do
  Begin
    If IsHeart(TrickC[K]) Then Inc(Hr);
    If IsQueen(TrickC[K]) Then Inc(Qn);
    If TrickC[K] = KingHearts Then Kh := 1;
  End;
  P := 0;
  If (Contract = K_TRICKS) Or (Contract = K_SALADE) Then P := P + 2;
  If (Contract = K_HEARTS) Or (Contract = K_SALADE) Then P := P + 2 * Hr;
  If (Contract = K_QUEENS) Or (Contract = K_SALADE) Then P := P + 6 * Qn;
  If (Contract = K_BARBU) Or (Contract = K_SALADE) Then P := P + 16 * Kh;
  If ((Contract = K_LAST) Or (Contract = K_SALADE)) And (TrickNo = 13) Then P := P + 16;
  TrickPenalty := P;
End;

Procedure SortHand(P : LongInt);
Var I, J, T : LongInt;
Begin
  For I := 0 To NHand[P] - 2 Do
    For J := I + 1 To NHand[P] - 1 Do
      If (Suit(Hand[P, I]) * 20 + CVal(Hand[P, I])) > (Suit(Hand[P, J]) * 20 + CVal(Hand[P, J])) Then
      Begin
        T := Hand[P, I]; Hand[P, I] := Hand[P, J]; Hand[P, J] := T;
      End;
End;

{ ==================================================================== }
{ Ordinateur                                                            }
{ ==================================================================== }

{ carte a jouer pour le joueur P (indice dans sa main) }
Function CpuCard(P : LongInt) : LongInt;
Var K, C, V, Hi, Best0, Bs, Sc, Cnt : LongInt; Last : Boolean;
Begin
  Best0 := -1;
  { entame : la plus basse, en evitant les couleurs dangereuses }
  If NTrick = 0 Then
  Begin
    Bs := 99999;
    For K := 0 To NHand[P] - 1 Do
      If Legal(P, K) Then
      Begin
        C := Hand[P, K];
        Sc := CVal(C) * 10;
        If IsHeart(C) And HeartContract Then Sc := Sc + 150;
        If ((Contract = K_QUEENS) Or (Contract = K_SALADE)) And (CVal(C) >= 12) Then Sc := Sc + 120;
        If (Contract = K_LAST) And (TrickNo >= 11) Then Sc := 200 - Sc;
        Sc := Sc + Rnd(5);
        If Sc < Bs Then Begin Bs := Sc; Best0 := K; End;
      End;
    CpuCard := Best0;
    Exit;
  End;
  { fournir }
  If HasSuit(P, LeadSuit) Then
  Begin
    Hi := TrickHigh;
    Last := NTrick = 3;
    { passer sous la carte la plus forte, avec la plus haute possible }
    Bs := -1;
    For K := 0 To NHand[P] - 1 Do
      If Legal(P, K) And (CVal(Hand[P, K]) < Hi) And (CVal(Hand[P, K]) > Bs) Then
      Begin
        Bs := CVal(Hand[P, K]); Best0 := K;
      End;
    If Best0 >= 0 Then
    Begin
      CpuCard := Best0;
      Exit;
    End;
    { obligé de prendre : dernier, la plus forte (sauf dame et Barbu) ; sinon la plus basse }
    If Last Then Bs := -1 Else Bs := 99;
    For K := 0 To NHand[P] - 1 Do
      If Legal(P, K) Then
      Begin
        C := Hand[P, K]; V := CVal(C);
        If ((Contract = K_QUEENS) Or (Contract = K_SALADE)) And IsQueen(C) Then V := V - 20;
        If ((Contract = K_BARBU) Or (Contract = K_SALADE)) And (C = KingHearts) Then V := V - 30;
        If Last Then Begin If V > Bs Then Begin Bs := V; Best0 := K; End; End
        Else If V + 40 < Bs + 40 Then Begin Bs := V; Best0 := K; End;
      End;
    If Best0 < 0 Then For K := 0 To NHand[P] - 1 Do If Legal(P, K) Then Best0 := K;
    CpuCard := Best0;
    Exit;
  End;
  { defausse : la carte la plus dangereuse }
  Bs := -1;
  For K := 0 To NHand[P] - 1 Do
    If Legal(P, K) Then
    Begin
      C := Hand[P, K];
      Sc := CVal(C);
      If ((Contract = K_BARBU) Or (Contract = K_SALADE)) And (C = KingHearts) Then Sc := Sc + 500;
      If ((Contract = K_QUEENS) Or (Contract = K_SALADE)) And IsQueen(C) Then Sc := Sc + 300;
      If ((Contract = K_HEARTS) Or (Contract = K_SALADE)) And IsHeart(C) Then Sc := Sc + 100;
      { une couleur courte se vide plus vite }
      Cnt := 0;
      For V := 0 To NHand[P] - 1 Do If Suit(Hand[P, V]) = Suit(C) Then Inc(Cnt);
      Sc := Sc * 10 + (13 - Cnt);
      If Sc > Bs Then Begin Bs := Sc; Best0 := K; End;
    End;
  CpuCard := Best0;
End;

{ contrat choisi par un donneur de l'ordinateur : le moins risque }
Function CpuContract(P : LongInt) : LongInt;
Var K, C, Hr, Qn, Kh, Hi, Lo, Risk, Best0, Br, R : LongInt;
Begin
  Hr := 0; Qn := 0; Kh := 0; Hi := 0; Lo := 0;
  For K := 0 To 12 Do
  Begin
    C := Hand[P, K];
    If IsHeart(C) Then Inc(Hr);
    If IsQueen(C) Then Inc(Qn);
    If C = KingHearts Then Kh := 1;
    If CVal(C) >= 11 Then Inc(Hi);
    If CVal(C) <= 6 Then Inc(Lo);
  End;
  Best0 := -1; Br := 99999;
  If Short0 <> 0 Then R := 0 Else R := P;
  For K := 0 To NK - 1 Do
    If Remain[R, K] <> 0 Then
    Begin
      Case K Of
        K_TRICKS : Risk := Hi * 6 - Lo * 2;
        K_HEARTS : Risk := Hr * 5 - Lo;
        K_QUEENS : Risk := Qn * 14 + Hi * 2 - Lo;
        K_BARBU : Risk := Kh * (40 - Hr * 4);
        K_LAST : Risk := Hi * 3 + 10;
      Else
        Risk := Hi * 6 + Hr * 4 + Qn * 10 + 30;
      End;
      If Risk < Br Then Begin Br := Risk; Best0 := K; End;
    End;
  CpuContract := Best0;
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Procedure CardAt(X, Y, C : LongInt; Face, Hilite : Boolean);
Begin
  If Face Then DrawFace(Hps, X, CH - Y - CardH, C, Hilite) Else DrawBack(Hps, X, CH - Y - CardH);
End;

Function MyTurn : Boolean;
Begin
  MyTurn := (Phase = PH_PLAY) And (CurP = 0) And (AutoAll = 0) And (Thinking = 0);
End;

Function HandSp : LongInt;
Begin
  If NHand[0] <= 1 Then HandSp := 28 Else HandSp := MinI(28, (TX2 - TX1 - 40 - CardW) Div (NHand[0] - 1));
End;

Function HandX0 : LongInt;
Begin
  HandX0 := MidX - ((NHand[0] - 1) * HandSp + CardW) Div 2;
End;

Function TagW(P : LongInt) : LongInt;
Begin
  TagW := Length(PName(P)) * 8 + 8;
  If P = Dealer Then TagW := Length(PName(P)) * 8 + 28;
End;

{ etiquette d'un joueur : nom, D pour le donneur, bleu si c'est son tour }
Procedure NameTag(X, Y, P : LongInt);
Var Bg : LongInt; S : String;
Begin
  If (Phase = PH_PLAY) And (CurP = P) Then Bg := CLR_DARKBLUE Else Bg := CLR_BLACK;
  S := PName(P);
  FBar(X, Y, X + TagW(P) - 1, Y + 17, Bg);
  OutTxt(X + 4, Y + 1, S, CLR_WHITE, Bg);
  If P = Dealer Then
  Begin
    Disc(X + Length(S) * 8 + 18, Y + 9, 8, CLR_WHITE);
    OutTxt(X + Length(S) * 8 + 15, Y + 1, 'D', CLR_BLACK, CLR_WHITE);
  End;
End;

Procedure TrickPos(P : LongInt; Var X, Y : LongInt);
Begin
  Case P Of
    0 : Begin X := MidX - 20; Y := 180; End;
    1 : Begin X := MidX - 124; Y := 150; End;
    2 : Begin X := MidX - 52; Y := 120; End;
  Else
    Begin X := MidX + 52; Y := 150; End;
  End;
End;

Procedure Box(X1, Y1, X2, Y2 : LongInt);
Begin
  FBar(X1, Y1, X2, Y2, CLR_PALEGRAY);
  Edge(X1, Y1, X2, Y2, CLR_WHITE, CLR_BLACK);
  Edge(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, CLR_PALEGRAY, CLR_DARKGRAY);
End;

Procedure DrawChoose;
Var K, Y, R : LongInt;
Begin
  Box(MidX - 150, 96, MidX + 150, 300);
  FBar(MidX - 147, 99, MidX + 147, 117, CLR_DARKBLUE);
  OutTxt(MidX - 140, 100, 'Vous donnez : choisissez le contrat', CLR_WHITE, CLR_DARKBLUE);
  R := 0;
  Y := 126;
  For K := 0 To NK - 1 Do
  Begin
    If Remain[R, K] <> 0 Then
    Begin
      FBar(MidX - 140, Y, MidX + 140, Y + 23, CLR_WHITE);
      Edge(MidX - 140, Y, MidX + 140, Y + 23, CLR_DARKGRAY, CLR_BLACK);
      OutTxt(MidX - 132, Y + 4, IStr(K + 1) + '  ' + KShort(K), CLR_BLACK, CLR_WHITE);
    End
    Else OutTxt(MidX - 132, Y + 4, IStr(K + 1) + '  ' + KShort(K) + ' (jou' + Chr(130) + ')', CLR_DARKGRAY,
                CLR_PALEGRAY);
    Y := Y + 28;
  End;
End;

Procedure DrawEnd;
Var K, Y, Bp, W : LongInt; S : String;
Begin
  Box(MidX - 150, 100, MidX + 150, 290);
  FBar(MidX - 147, 103, MidX + 147, 121, CLR_DARKBLUE);
  If Phase = PH_OVER Then S := 'Partie termin' + Chr(130) + 'e' Else S := 'Fin de la donne ' + IStr(DealNo);
  OutTxt(MidX - 140, 104, S, CLR_WHITE, CLR_DARKBLUE);
  OutTxt(MidX - 140, 128, KName(Contract), CLR_DARKBLUE, CLR_PALEGRAY);
  Bp := 0;
  For K := 1 To 3 Do If Total[K] < Total[Bp] Then Bp := K;
  Y := 152;
  For K := 0 To 3 Do
  Begin
    S := PName(K);
    OutTxt(MidX - 140, Y, S, CLR_BLACK, CLR_PALEGRAY);
    OutTxt(MidX - 40, Y, '+' + IStr(DealPts[K]), CLR_DARKRED, CLR_PALEGRAY);
    OutTxt(MidX + 40, Y, IStr(Total[K]), CLR_BLACK, CLR_PALEGRAY);
    Y := Y + 20;
  End;
  If Phase = PH_OVER Then
  Begin
    If Bp = 0 Then S := 'Vous gagnez la partie !' Else S := PName(Bp) + ' gagne la partie.';
    OutTxt(MidX - 140, 240, S, CLR_DARKBLUE, CLR_PALEGRAY);
  End;
  W := 160;
  Box(MidX - W Div 2, 258, MidX + W Div 2, 282);
  If Phase = PH_OVER Then S := 'Nouvelle partie' Else S := 'Donne suivante';
  OutTxt(MidX - Length(S) * 4, 262, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure DrawTable;
Var K, X, Y, N, Sp : LongInt; Hl : Boolean;
Begin
  FBar(TX1, TY1, TX2, TY2, CLR_BROWN);
  Edge(TX1, TY1, TX2, TY2, CLR_YELLOW, CLR_BLACK);
  FBar(TX1 + 8, TY1 + 8, TX2 - 8, TY2 - 8, CLR_DARKGREEN);
  Edge(TX1 + 8, TY1 + 8, TX2 - 8, TY2 - 8, CLR_BLACK, CLR_GREEN);
  { Nord : en haut ; Ouest et Est : sur les cotes }
  N := NHand[2]; Sp := 12; If AutoAll <> 0 Then Sp := 14;
  X := MidX - ((N - 1) * Sp + CardW) Div 2;
  For K := 0 To N - 1 Do CardAt(X + K * Sp, 18, Hand[2, K], AutoAll <> 0, False);
  If N > 0 Then NameTag(X + (N - 1) * Sp + CardW + 8, 18, 2) Else NameTag(MidX - TagW(2) Div 2, 18, 2);
  N := NHand[1];
  For K := 0 To N - 1 Do CardAt(18, 30 + K * 12, Hand[1, K], AutoAll <> 0, False);
  NameTag(18, 276, 1);
  N := NHand[3];
  For K := 0 To N - 1 Do CardAt(TX2 - 18 - CardW, 30 + K * 12, Hand[3, K], AutoAll <> 0, False);
  NameTag(TX2 - 18 - TagW(3), 276, 3);
  { levee en cours (ou terminee) }
  For K := 0 To NTrick - 1 Do
  Begin
    TrickPos(TrickP[K], X, Y);
    CardAt(X, Y, TrickC[K], True, (Phase = PH_TRICK) And (TrickP[K] = LastWin));
  End;
  { votre main }
  Sp := HandSp;
  For K := 0 To NHand[0] - 1 Do
  Begin
    X := HandX0 + K * Sp; Y := HandY;
    Hl := MyTurn And Legal(0, K);
    If MyTurn And (K = Sel) Then Y := Y - 12;
    CardAt(X, Y, Hand[0, K], True, Hl);
  End;
  NameTag(MidX + 15 - TagW(0) Div 2, 278, 0);
  If Phase = PH_CHOOSE Then DrawChoose
  Else If (Phase = PH_END) Or (Phase = PH_OVER) Then DrawEnd;
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
Var K, Y : LongInt; S : String;
Begin
  BigText(PnX + (PW - 5 * 16) Div 2, 8, 'BARBU', CLR_DARKBLUE, CLR_PALEGRAY);
  FBar(PnX, 46, PnX + PW - 1, 330, CLR_WHITE);
  Edge(PnX, 46, PnX + PW - 1, 330, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(PnX + 6, 50, 'Donne ' + IStr(DealNo) + ' / ' + IStr(NDeals), CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 6, 68, 'Donneur : ' + PName(Dealer), CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 6, 92, 'Contrat :', CLR_DARKGRAY, CLR_WHITE);
  If Phase = PH_CHOOSE Then S := '(' + Chr(133) + ' choisir)' Else S := KName(Contract);
  If Length(S) > 18 Then
  Begin
    OutTxt(PnX + 6, 110, Copy(S, 1, 9), CLR_DARKRED, CLR_WHITE);
    OutTxt(PnX + 6, 128, Copy(S, 10, 18), CLR_DARKRED, CLR_WHITE);
  End
  Else OutTxt(PnX + 6, 110, S, CLR_DARKRED, CLR_WHITE);
  If Phase <> PH_CHOOSE Then OutTxt(PnX + 6, 150, 'Lev' + Chr(130) + 'e ' + IStr(MinI(TrickNo, 13)) + ' / 13',
                                    CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 6, 176, 'Points (le moins', CLR_DARKGRAY, CLR_WHITE);
  OutTxt(PnX + 6, 176 + 16, 'gagne)', CLR_DARKGRAY, CLR_WHITE);
  Y := 214;
  For K := 0 To 3 Do
  Begin
    OutTxt(PnX + 6, Y, PName(K), CLR_BLACK, CLR_WHITE);
    S := IStr(Total[K]);
    OutTxt(PnX + PW - 8 - Length(S) * 8, Y, S, CLR_DARKBLUE, CLR_WHITE);
    If DealPts[K] > 0 Then
    Begin
      S := '+' + IStr(DealPts[K]);
      OutTxt(PnX + 62, Y, S, CLR_DARKRED, CLR_WHITE);
    End;
    Y := Y + 18;
  End;
  OutTxt(PnX + 6, 290, 'Lev' + Chr(130) + 'es : ' + IStr(Tricks[0]), CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 6, 308, 'Victoires : ' + IStr(Wins), CLR_BLACK, CLR_WHITE);
  If (Phase = PH_END) Then Button(PnX, BY1, PW, BH, 'Donne suivante', True)
  Else Button(PnX, BY1, PW, BH, 'Nouvelle partie', True);
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
{ Donne                                                                 }
{ ==================================================================== }

Procedure YourTurnMsg;
Begin
  If NTrick = 0 Then Msg := 'A vous d''entamer : cliquez une carte surlign' + Chr(130) + 'e (ou fl' + Chr(138) +
                            'ches et Entr' + Chr(130) + 'e).'
  Else Msg := 'A vous : fournissez ' + Chr(133) + ' la couleur demand' + Chr(130) + 'e si vous le pouvez.';
End;

Procedure NextTurn;
Begin
  If (CurP = 0) And (AutoAll = 0) Then
  Begin
    Sel := 0;
    While (Sel < NHand[0] - 1) And Not Legal(0, Sel) Do Inc(Sel);
    YourTurnMsg;
  End
  Else Thinking := 12;
  Redraw;
End;

Procedure StartPlay;
Begin
  Phase := PH_PLAY;
  If Short0 <> 0 Then Remain[0, Contract] := 0 Else Remain[Dealer, Contract] := 0;
  CurP := (Dealer + 1) Mod 4;
  NTrick := 0; TrickNo := 1;
  If Dealer = 0 Then Msg := 'Vous avez choisi : ' Else Msg := PName(Dealer) + ' a choisi : ';
  Msg := Msg + KName(Contract) + '.';
  NextTurn;
End;

Procedure NewDeal;
Var K, J, T, P : LongInt;
Begin
  Inc(DealNo);
  Dealer := (DealNo - 1) Mod 4;
  For K := 0 To 51 Do Deck[K] := K;
  For K := 51 DownTo 1 Do
  Begin
    J := Rnd(K + 1);
    T := Deck[K]; Deck[K] := Deck[J]; Deck[J] := T;
  End;
  For P := 0 To 3 Do
  Begin
    For K := 0 To 12 Do Hand[P, K] := Deck[P * 13 + K];
    NHand[P] := 13;
    SortHand(P);
    DealPts[P] := 0; Tricks[P] := 0;
  End;
  NTrick := 0; TrickNo := 1; HeartsOut := 0; QueensOut := 0; BarbuOut := 0;
  If (Dealer = 0) And (AutoAll = 0) Then
  Begin
    Phase := PH_CHOOSE;
    Msg := 'Vous donnez : choisissez le contrat (clic ou 1 ' + Chr(133) + ' 6).';
    Redraw;
  End
  Else
  Begin
    Contract := CpuContract(Dealer);
    StartPlay;
  End;
End;

Procedure NewGame;
Var K, J : LongInt;
Begin
  For K := 0 To 3 Do Begin Total[K] := 0; DealPts[K] := 0; Tricks[K] := 0; End;
  For K := 0 To 3 Do For J := 0 To NK - 1 Do Remain[K, J] := 1;
  If Short0 <> 0 Then NDeals := NK Else NDeals := NK * 4;
  DealNo := 0; Thinking := 0; Wait := 0;
  NewDeal;
End;

{ la donne s'arrete quand toutes les penalites sont tombees }
Function DealOver : Boolean;
Begin
  DealOver := TrickNo > 13;
  If (Contract = K_HEARTS) And (HeartsOut >= 13) Then DealOver := True;
  If (Contract = K_QUEENS) And (QueensOut >= 4) Then DealOver := True;
  If (Contract = K_BARBU) And (BarbuOut <> 0) Then DealOver := True;
End;

Procedure EndDeal;
Var K, Bp : LongInt;
Begin
  If DealNo >= NDeals Then
  Begin
    Phase := PH_OVER;
    Bp := 0;
    For K := 1 To 3 Do If Total[K] < Total[Bp] Then Bp := K;
    If Bp = 0 Then Inc(Wins);
    If Bp = 0 Then Msg := 'Vous gagnez la partie avec ' + IStr(Total[0]) + ' points ! F2 : nouvelle partie.'
    Else Msg := PName(Bp) + ' gagne la partie (' + IStr(Total[Bp]) + ' points). F2 : nouvelle partie.';
  End
  Else
  Begin
    Phase := PH_END;
    Msg := 'Fin de la donne : vous prenez ' + IStr(DealPts[0]) + ' points. Entr' + Chr(130) +
           'e : donne suivante.';
  End;
  Wait := 0;
  Redraw;
End;

{ fin de la levee affichee : le gagnant ramasse et entame }
Procedure CollectTrick;
Begin
  NTrick := 0;
  Inc(TrickNo);
  If DealOver Then
  Begin
    EndDeal;
    Exit;
  End;
  Phase := PH_PLAY;
  CurP := LastWin;
  NextTurn;
End;

Procedure PlayCard(P, I : LongInt);
Var K, C : LongInt;
Begin
  C := Hand[P, I];
  For K := I To NHand[P] - 2 Do Hand[P, K] := Hand[P, K + 1];
  Dec(NHand[P]);
  If NTrick = 0 Then LeadSuit := Suit(C);
  TrickC[NTrick] := C; TrickP[NTrick] := P;
  Inc(NTrick);
  If IsHeart(C) Then Inc(HeartsOut);
  If IsQueen(C) Then Inc(QueensOut);
  If C = KingHearts Then BarbuOut := 1;
  If NTrick = 4 Then
  Begin
    LastWin := TrickWinner;
    LastPts := TrickPenalty;
    DealPts[LastWin] := DealPts[LastWin] + LastPts;
    Total[LastWin] := Total[LastWin] + LastPts;
    Inc(Tricks[LastWin]);
    Phase := PH_TRICK; Wait := 0;
    If LastWin = 0 Then Msg := 'Vous prenez la lev' + Chr(130) + 'e' Else Msg := PName(LastWin) + ' prend la lev' +
                                                                             Chr(130) + 'e';
    If LastPts > 0 Then Msg := Msg + ' : ' + IStr(LastPts) + ' points.' Else Msg := Msg + '.';
    Redraw;
    Exit;
  End;
  CurP := (CurP + 1) Mod 4;
  NextTurn;
End;

Procedure CpuTurn;
Var I : LongInt;
Begin
  If Phase <> PH_PLAY Then Exit;
  I := CpuCard(CurP);
  If I < 0 Then I := 0;
  PlayCard(CurP, I);
End;

Procedure HumanPlay(I : LongInt);
Begin
  If Not MyTurn Then Exit;
  If Not Legal(0, I) Then
  Begin
    If (NTrick > 0) And HasSuit(0, LeadSuit) Then Msg := 'Vous devez fournir ' + Chr(133) + ' la couleur demand' +
                                                     Chr(130) + 'e.'
    Else If NTrick = 0 Then Msg := 'Pas d''entame ' + Chr(133) + ' coeur tant que vous avez autre chose.'
    Else Msg := 'Vous devez vous d' + Chr(130) + 'fausser du roi de coeur (le Barbu).';
    Redraw;
    Exit;
  End;
  PlayCard(0, I);
End;

Procedure ChooseContract(K : LongInt);
Begin
  If Phase <> PH_CHOOSE Then Exit;
  If (K < 0) Or (K >= NK) Then Exit;
  If Remain[0, K] = 0 Then Exit;
  Contract := K;
  StartPlay;
End;

Procedure NextOrNew;
Begin
  If Phase = PH_END Then NewDeal
  Else If Phase = PH_OVER Then NewGame;
End;

Procedure TimerTick;
Begin
  Case Phase Of
    PH_PLAY :
      If Thinking > 0 Then
      Begin
        Dec(Thinking);
        If Thinking = 0 Then CpuTurn;
      End;
    PH_TRICK :
      Begin
        Inc(Wait);
        If Wait > 26 Then CollectTrick;
      End;
    PH_END, PH_OVER :
      If AutoAll <> 0 Then
      Begin
        Inc(Wait);
        If Wait > 40 Then NextOrNew;
      End;
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

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_NEXT : NextOrNew;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_SHORT, CM_LONG :
      Begin
        If Id = CM_SHORT Then Short0 := 1 Else Short0 := 0;
        SetMark(CM_SHORT, Short0 <> 0); SetMark(CM_LONG, Short0 = 0);
        NewGame;
      End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Quatre joueurs, 13 cartes chacun. Le joueur ' + Chr(133) + ' gauche du donneur entame ; il faut ' +
             'fournir ' + Chr(133) + ' la couleur demand' + Chr(130) + 'e ; la plus haute carte de cette ' +
             'couleur (l''as est la plus forte) remporte la lev' + Chr(130) + 'e et entame la suivante. ');
        LAdd('Le donneur choisit le contrat ; le moins de points gagne.' + Chr(10) + Chr(10));
        LAdd('Contrats : Pas de lev' + Chr(130) + 'es (2 par lev' + Chr(130) + 'e), Pas de coeurs (2 par coeur), ' +
             'Pas de dames (6 par dame), Le Barbu (le roi de coeur : 16), Pas la derni' + Chr(138) + 're lev' +
             Chr(130) + 'e (16), La salade (tout ' + Chr(133) + ' la fois). ');
        LAdd('On n''entame pas ' + Chr(133) + ' coeur dans les contrats ' + Chr(133) + ' coeurs tant qu''on a ' +
             'autre chose ; au Barbu, qui ne peut pas fournir doit se d' + Chr(130) + 'fausser du roi de coeur. ');
        LAdd('La donne s''arr' + Chr(136) + 'te quand toutes les p' + Chr(130) + 'nalit' + Chr(130) + 's sont ' +
             'tomb' + Chr(130) + 'es.' + Chr(10) + Chr(10));
        LAdd('Partie courte : 6 donnes (chaque contrat une fois). Partie compl' + Chr(138) + 'te : 24 donnes ' +
             '(chaque donneur joue chaque contrat).');
        Dummy := LMsgBox('Barbu - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Barbu pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'BARBU.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et ' +
                            'compil' + Chr(130) + ' par OS2PC.', 'A propos de Barbu', MB_OK Or MB_INFORMATION);
  End;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, K, Sp, X0 : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) And (Y >= BY1) And (Y < BY1 + BH) Then
  Begin
    If Phase = PH_END Then NewDeal Else NewGame;
    Exit;
  End;
  If Phase = PH_CHOOSE Then
  Begin
    If (X >= MidX - 140) And (X <= MidX + 140) And (Y >= 126) And (Y < 126 + NK * 28) Then
      ChooseContract((Y - 126) Div 28);
    Exit;
  End;
  If (Phase = PH_END) Or (Phase = PH_OVER) Then
  Begin
    If (X >= MidX - 80) And (X <= MidX + 80) And (Y >= 258) And (Y <= 282) Then NextOrNew;
    Exit;
  End;
  If MyTurn And (Y >= HandY - 12) And (Y < HandY + CardH) Then
  Begin
    Sp := HandSp; X0 := HandX0;
    For K := NHand[0] - 1 DownTo 0 Do
      If (X >= X0 + K * Sp) And (X < X0 + K * Sp + CardW) Then
      Begin
        Sel := K;
        HumanPlay(K);
        Exit;
      End;
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
    If (Vk = VK_LEFT) And MyTurn Then
    Begin
      If Sel > 0 Then Dec(Sel);
      Redraw;
      Exit;
    End;
    If (Vk = VK_RIGHT) And MyTurn Then
    Begin
      If Sel < NHand[0] - 1 Then Inc(Sel);
      Redraw;
      Exit;
    End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_SPACE) Then
    Begin
      If MyTurn Then HumanPlay(Sel) Else NextOrNew;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    If (Ch >= Ord('1')) And (Ch <= Ord('6')) And (Phase = PH_CHOOSE) Then
    Begin
      ChooseContract(Ch - Ord('1'));
      Exit;
    End;
    Case UpCase(Chr(Ch)) Of
      'N' : NextOrNew;
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
  Msg := ''; AutoAll := 0; Thinking := 0; Wait := 0; Client := 0; Frame := 0; Wins := 0; Short0 := 1;
  Phase := PH_OVER; DealNo := 0; NDeals := NK; Dealer := 0; Contract := 0;
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
  Dummy := WinRegisterClass(Hab, Z('BARBU'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('BARBU'), Z2('Barbu'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_NEXT, '~Donne suivante' + Chr(9) + 'N');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, MIA_CHECKED, CM_SHORT, 'Partie ~courte (6 donnes)');
  MItem(MIS_TEXT, 0, CM_LONG, 'Partie co~mpl' + Chr(138) + 'te (24 donnes)');
  MenuClose(H3, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Barbu');
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
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 45);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
