{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BADUGI - Badugi (poker coreen a quatre cartes) pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program BADUGI;

{$R-,S-,I-}

{ Compilation : OS2PC BADUGI.PAS   (produit BADUGI.EXE)

  Portage vers OS/2-0 du prototype BADUGI.PAS du depot 7iles (Turbo
  Pascal et BGI, clavier F, C, R, D, S et souris) : fenetre de
  Presentation Manager avec menus, tapis de jeu, cartes dessinees (celles
  du Poker d'OS/2-0), jetons des mises et du pot, bouton du donneur,
  panneau des commandes, barre d'etat et apparence d'OS/2.

  Comme le prototype : vous (Sud) contre Nord, Est et Ouest, 1000 jetons
  chacun, petite et grosse blinde, quatre cartes, quatre tours d'encheres
  separes par trois echanges ; l'ordinateur relance avec une bonne main,
  suit avec une main moyenne et passe avec une main faible, et garde a
  l'echange les cartes de couleurs et de valeurs differentes.

  But : la main la plus basse. Seules comptent les cartes de couleurs
  differentes et de valeurs differentes (l'as vaut 1) : quatre cartes
  ainsi (un « badugi ») battent toute main de trois cartes, qui bat toute
  main de deux cartes ; a nombre egal, on compare la plus haute carte,
  puis la suivante... La meilleure main possible est A-2-3-4 de quatre
  couleurs. Le prototype comptait la somme des valeurs (la plus haute
  gagnait) : la regle du Badugi est appliquee ici. Il fermait aussi un
  tour d'encheres avant que chacun ait parle ; ici chacun parle, et les
  relances sont limitees a quatre par tour.

  Souris : boutons du panneau, cliquer une carte (echange).
  Clavier : C (parole ou suivre), R (relancer), P ou F (passer), cartes 1
  a 4 (echange), D ou Entree (echanger), S (garder tout), Entree ou N
  (donne suivante), F2 (nouvelle partie), F1 (regles).
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
  CM_CALL = 111; CM_RAISE = 112; CM_FOLD = 113; CM_DRAW = 114; CM_STAND = 115;
  CM_RULES = 301; CM_HANDS = 302; CM_ABOUT = 303;
  NP = 4;                                  { Sud (vous), Ouest, Nord, Est }
  SmallBlind = 10; BigBlind = 20; RaiseAmt = 20; MaxRaises = 4; StartChips = 1000;
  PH_BET = 1; PH_DRAW = 2; PH_END = 3; PH_OVER = 4;
  { disposition (zone client, Y vers le bas) }
  CardW = 70; CardH = 96;
  TX1 = 6; TY1 = 6; TX2 = 452; TY2 = 412;  { tapis }
  MidX = 229;
  PnX = 462; PW = 150;
  CWant = 618; CHWant = 440;
  BY1 = 236; BY2 = 272; BY3 = 308; BH = 30;  { boutons }

Type
  THand = Array[0..3] Of LongInt;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Hand : Array[0..NP - 1] Of THand;
  Chips, Bet, Folded, Out, Acted, Shown, Score : Array[0..NP - 1] Of LongInt;
  LastAct : Array[0..NP - 1] Of String[40];
  PickSel : Array[0..3] Of LongInt;
  Deck, Discard : Array[0..51] Of LongInt;
  DeckPos, NDiscard : LongInt;
  Dealer, CurP, CurBet, Pot, Raises, Phase, Round, Thinking, Seed, AutoAll, Wait, HandNo : LongInt;
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


{ ==================================================================== }
{ Regles : valeur d'une main de Badugi                                  }
{ ==================================================================== }

{ valeur 1 (as) a 13 (roi) }
Function BVal(C : LongInt) : LongInt;
Begin
  BVal := Rank(C) + 1;
End;

{ meilleure main : le plus grand groupe de cartes de couleurs et de
  valeurs toutes differentes, le plus bas a nombre egal. Score : plus
  petit = meilleur ; (4 - n) * 14^4, puis les valeurs du groupe de la plus
  haute a la plus basse en base 14. Mask : cartes du groupe }
Function EvalHand(Var H : THand; Var Mask : LongInt) : LongInt;
Var M, I, J, N, Ok, K, T, Best, Sc : LongInt; R : Array[0..3] Of LongInt;
Begin
  Best := 999999; Mask := 0;
  For M := 1 To 15 Do
  Begin
    Ok := 1; N := 0;
    For I := 0 To 3 Do
      If (M And (1 Shl I)) <> 0 Then
      Begin
        For J := I + 1 To 3 Do
          If (M And (1 Shl J)) <> 0 Then
            If (Suit(H[I]) = Suit(H[J])) Or (Rank(H[I]) = Rank(H[J])) Then Ok := 0;
        R[N] := BVal(H[I]);
        Inc(N);
      End;
    If Ok = 1 Then
    Begin
      { valeurs du groupe de la plus haute a la plus basse }
      For I := 0 To N - 2 Do
        For J := I + 1 To N - 1 Do
          If R[J] > R[I] Then Begin T := R[I]; R[I] := R[J]; R[J] := T; End;
      For K := N To 3 Do R[K] := 0;
      Sc := (4 - N) * 38416 + R[0] * 2744 + R[1] * 196 + R[2] * 14 + R[3];
      If Sc < Best Then
      Begin
        Best := Sc;
        Mask := M;
      End;
    End;
  End;
  EvalHand := Best;
End;

Function NCards(Sc : LongInt) : LongInt;
Begin
  NCards := 4 - Sc Div 38416;
End;

{ plus haute carte du groupe }
Function TopVal(Sc : LongInt) : LongInt;
Begin
  TopVal := (Sc Mod 38416) Div 2744;
End;

Function ValName(V : LongInt) : String;
Begin
  Case V Of
    1 : ValName := 'A';
    11 : ValName := 'V';
    12 : ValName := 'D';
    13 : ValName := 'R';
  Else
    ValName := IStr(V);
  End;
End;

Function HandName(Sc : LongInt) : String;
Var S, T : String; N, K, V, Rest : LongInt;
Begin
  N := NCards(Sc);
  Case N Of
    4 : S := 'Badugi';
    3 : S := 'Trois cartes';
    2 : S := 'Deux cartes';
  Else
    S := 'Une carte';
  End;
  Rest := Sc Mod 38416;
  T := '';
  For K := 0 To N - 1 Do
  Begin
    Case K Of
      0 : V := Rest Div 2744;
      1 : V := (Rest Div 196) Mod 14;
      2 : V := (Rest Div 14) Mod 14;
    Else
      V := Rest Mod 14;
    End;
    If T <> '' Then T := T + '-';
    T := T + ValName(V);
  End;
  HandName := S + ' ' + T;
End;

{ ==================================================================== }
{ Joueurs et paquet                                                     }
{ ==================================================================== }

Function PName(P : LongInt) : String;
Begin
  Case P Of
    0 : If AutoAll <> 0 Then PName := 'Sud' Else PName := 'Vous';
    1 : PName := 'Ouest';
    2 : PName := 'Nord';
  Else
    PName := 'Est';
  End;
End;

Function IsCpu(P : LongInt) : Boolean;
Begin
  IsCpu := (P <> 0) Or (AutoAll <> 0);
End;

Function InHand(P : LongInt) : Boolean;
Begin
  InHand := (Out[P] = 0) And (Folded[P] = 0);
End;

Function NextIn(P : LongInt) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To NP Do
  Begin
    P := (P + 1) Mod NP;
    If InHand(P) Then
    Begin
      NextIn := P;
      Exit;
    End;
  End;
  NextIn := P;
End;

Function NextSeat(P : LongInt) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To NP Do
  Begin
    P := (P + 1) Mod NP;
    If Out[P] = 0 Then
    Begin
      NextSeat := P;
      Exit;
    End;
  End;
  NextSeat := P;
End;

Function CountIn : LongInt;
Var P, N : LongInt;
Begin
  N := 0;
  For P := 0 To NP - 1 Do If InHand(P) Then Inc(N);
  CountIn := N;
End;

Procedure Shuffle;
Var I, J, T : LongInt;
Begin
  For I := 0 To 51 Do Deck[I] := I;
  For I := 51 DownTo 1 Do
  Begin
    J := Rnd(I + 1);
    T := Deck[I]; Deck[I] := Deck[J]; Deck[J] := T;
  End;
  DeckPos := 0; NDiscard := 0;
End;

{ une carte du paquet ; paquet vide : les cartes ecartees sont rebattues }
Function DealOne : LongInt;
Var I, J, T : LongInt;
Begin
  If DeckPos >= 52 Then
  Begin
    For I := 0 To NDiscard - 1 Do Deck[52 - NDiscard + I] := Discard[I];
    For I := NDiscard - 1 DownTo 1 Do
    Begin
      J := Rnd(I + 1);
      T := Deck[52 - NDiscard + I]; Deck[52 - NDiscard + I] := Deck[52 - NDiscard + J];
      Deck[52 - NDiscard + J] := T;
    End;
    DeckPos := 52 - NDiscard;
    NDiscard := 0;
  End;
  DealOne := Deck[DeckPos];
  Inc(DeckPos);
End;

{ cartes 0 a 3 dans l'ordre des valeurs (main de Sud) }
Procedure SortHand(Var H : THand);
Var I, J, T : LongInt;
Begin
  For I := 0 To 2 Do
    For J := I + 1 To 3 Do
      If (BVal(H[J]) < BVal(H[I])) Or ((BVal(H[J]) = BVal(H[I])) And (Suit(H[J]) < Suit(H[I]))) Then
      Begin
        T := H[I]; H[I] := H[J]; H[J] := T;
      End;
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

{ carte dont le coin haut gauche est (X, Y) }
Procedure CardAt(X, Y, C : LongInt; Face, Hilite : Boolean);
Var Yb : LongInt;
Begin
  Yb := CH - Y - CardH;
  If Face Then DrawFace(Hps, X, Yb, C, Hilite) Else DrawBack(Hps, X, Yb);
End;

{ jeton de couleur C }
Procedure Chip(X, Y, C : LongInt);
Begin
  Disc(X, Y + 1, 9, CLR_BLACK);
  Disc(X, Y, 9, C);
  Disc(X, Y, 6, CLR_WHITE);
  Disc(X, Y, 4, C);
End;

{ pile de jetons pour une somme (au plus 6 jetons) et son montant }
Procedure Stack(X, Y, V : LongInt);
Var N, K, C : LongInt;
Begin
  If V <= 0 Then Exit;
  N := 1 + V Div 40;
  If N > 6 Then N := 6;
  For K := 0 To N - 1 Do
  Begin
    Case K Mod 3 Of
      0 : C := CLR_RED;
      1 : C := CLR_BLUE;
    Else
      C := CLR_BLACK;
    End;
    Chip(X, Y - K * 3, C);
  End;
  OutTxt(X + 14, Y - 8, IStr(V), CLR_YELLOW, CLR_DARKGREEN);
End;

Procedure DealerButton(X, Y : LongInt);
Begin
  Disc(X, Y + 1, 9, CLR_BLACK);
  Disc(X, Y, 9, CLR_WHITE);
  OutTxt(X - 3, Y - 8, 'D', CLR_BLACK, CLR_WHITE);
End;

{ etiquette d'un joueur (nom, jetons, derniere action ou main) }
Procedure Plate(X, Y, P : LongInt);
Var Bg, Fg : LongInt; S : String;
Begin
  If (CurP = P) And ((Phase = PH_BET) Or (Phase = PH_DRAW)) Then Bg := CLR_DARKBLUE
  Else If (Phase = PH_END) And (Score[P] >= 0) And (Shown[P] = 2) Then Bg := CLR_BROWN
  Else Bg := CLR_BLACK;
  Fg := CLR_WHITE;
  If (Folded[P] <> 0) Or (Out[P] <> 0) Then Fg := CLR_PALEGRAY;
  FBar(X, Y, X + 129, Y + 37, Bg);
  Edge(X, Y, X + 129, Y + 37, CLR_PALEGRAY, CLR_DARKGRAY);
  S := PName(P);
  If Out[P] <> 0 Then S := S + ' (ruin' + Chr(130) + ')';
  OutTxt(X + 4, Y + 2, S, Fg, Bg);
  OutTxt(X + 126 - Length(IStr(Chips[P])) * 8, Y + 2, IStr(Chips[P]), CLR_YELLOW, Bg);
  S := LastAct[P];
  If Length(S) > 16 Then S := Copy(S, 1, 16);
  OutTxt(X + 4, Y + 19, S, CLR_CYAN, Bg);
  If P = Dealer Then DealerButton(X + 140, Y + 18);
End;

{ main face cachee (ou montree a l'abattage) en eventail }
Procedure Fan(X, Y, P : LongInt);
Var K, Mask : LongInt;
Begin
  If (Out[P] <> 0) Or (Folded[P] <> 0) Then Exit;
  Dummy := EvalHand(Hand[P], Mask);
  For K := 0 To 3 Do
    CardAt(X + K * 20, Y, Hand[P][K], Shown[P] <> 0, (Shown[P] <> 0) And ((Mask And (1 Shl K)) <> 0) And
           (Phase = PH_END));
End;

Procedure SouthCards;
Var K, X, Y, Mask : LongInt; Face : Boolean;
Begin
  If Out[0] <> 0 Then Exit;
  If Folded[0] <> 0 Then
  Begin
    OutTxt(MidX - 60, 330, 'Vous avez pass' + Chr(130) + '.', CLR_WHITE, CLR_DARKGREEN);
    Exit;
  End;
  Dummy := EvalHand(Hand[0], Mask);
  Face := (AutoAll = 0) Or (Shown[0] <> 0);
  For K := 0 To 3 Do
  Begin
    X := MidX - 149 + K * 76; Y := 304;
    If PickSel[K] <> 0 Then Y := Y - 16;
    CardAt(X, Y, Hand[0][K], Face, (Phase = PH_END) And ((Mask And (1 Shl K)) <> 0));
    If PickSel[K] <> 0 Then
    Begin
      FBar(X + 8, Y + CardH + 2, X + CardW - 9, Y + CardH + 15, CLR_DARKBLUE);
      OutTxt(X + 11, Y + CardH, 'Echange', CLR_WHITE, CLR_DARKBLUE);
    End;
    If (Phase = PH_DRAW) And (CurP = 0) And (AutoAll = 0) Then
      OutTxt(X + CardW Div 2 - 4, 288 - 16 * PickSel[K], IStr(K + 1), CLR_YELLOW, CLR_DARKGREEN);
  End;
End;

Procedure DrawTable;
Begin
  FBar(TX1, TY1, TX2, TY2, CLR_BROWN);
  Edge(TX1, TY1, TX2, TY2, CLR_YELLOW, CLR_BLACK);
  FBar(TX1 + 8, TY1 + 8, TX2 - 8, TY2 - 8, CLR_DARKGREEN);
  Edge(TX1 + 8, TY1 + 8, TX2 - 8, TY2 - 8, CLR_BLACK, CLR_GREEN);
  { Nord }
  Plate(MidX - 65, 16, 2);
  Fan(MidX - 65, 58, 2);
  Stack(MidX - 30, 170, Bet[2]);
  { Ouest }
  Plate(20, 120, 1);
  Fan(20, 162, 1);
  Stack(170, 220, Bet[1]);
  { Est }
  Plate(306, 120, 3);
  Fan(306, 162, 3);
  Stack(270, 220, Bet[3]);
  { pot }
  If Pot > 0 Then
  Begin
    Chip(MidX - 18, 210, CLR_RED); Chip(MidX - 6, 206, CLR_BLUE); Chip(MidX + 6, 210, CLR_BLACK);
    Chip(MidX - 12, 198, CLR_BLUE); Chip(MidX, 196, CLR_RED);
    OutTxt(MidX - 40, 222, 'Pot : ' + IStr(Pot), CLR_YELLOW, CLR_DARKGREEN);
  End;
  { Sud }
  Stack(MidX - 30, 262, Bet[0]);
  If Dealer = 0 Then DealerButton(MidX + 40, 262);
  SouthCards;
End;

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_DARKGRAY, CLR_PALEGRAY);
End;

Function MyTurn : Boolean;
Begin
  MyTurn := (CurP = 0) And (AutoAll = 0) And (Thinking = 0) And InHand(0);
End;

Function NSel : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To 3 Do N := N + PickSel[K];
  NSel := N;
End;

Function CallLabel : String;
Begin
  If CurBet > Bet[0] Then CallLabel := 'Suivre (' + IStr(MinI(CurBet - Bet[0], Chips[0])) + ')'
  Else CallLabel := 'Parole';
End;

Procedure DrawPanel;
Var Sc, Mask : LongInt; On : Boolean; S : String;
Begin
  BigText(PnX + (PW - 6 * 16) Div 2, 10, 'BADUGI', CLR_DARKBLUE, CLR_PALEGRAY);
  FBar(PnX, 50, PnX + PW - 1, 196, CLR_WHITE);
  Edge(PnX, 50, PnX + PW - 1, 196, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(PnX + 6, 54, 'Donne ' + IStr(HandNo), CLR_BLACK, CLR_WHITE);
  Case Phase Of
    PH_BET : S := 'Ench' + Chr(138) + 'res ' + IStr(Round + 1) + ' / 4';
    PH_DRAW : S := 'Echange ' + IStr(Round + 1) + ' / 3';
    PH_END : S := 'Fin de la donne';
  Else
    S := 'Partie termin' + Chr(130) + 'e';
  End;
  OutTxt(PnX + 6, 72, S, CLR_DARKBLUE, CLR_WHITE);
  OutTxt(PnX + 6, 90, 'Mise : ' + IStr(CurBet), CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 6, 108, 'Pot : ' + IStr(Pot), CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 6, 126, 'Vos jetons : ' + IStr(Chips[0]), CLR_BLACK, CLR_WHITE);
  If (Out[0] = 0) And (Folded[0] = 0) Then
  Begin
    Sc := EvalHand(Hand[0], Mask);
    OutTxt(PnX + 6, 150, 'Votre main :', CLR_DARKGRAY, CLR_WHITE);
    OutTxt(PnX + 6, 168, HandName(Sc), CLR_DARKRED, CLR_WHITE);
  End;
  If (Phase = PH_END) Or (Phase = PH_OVER) Then
  Begin
    If Phase = PH_END Then Button(PnX, BY1, PW, BH, 'Donne suivante', True)
    Else Button(PnX, BY1, PW, BH, 'Nouvelle partie', True);
  End
  Else If Phase = PH_DRAW Then
  Begin
    On := MyTurn;
    If NSel > 0 Then Button(PnX, BY1, PW, BH, 'Echanger (' + IStr(NSel) + ')', On)
    Else Button(PnX, BY1, PW, BH, 'Echanger', False);
    Button(PnX, BY2, PW, BH, 'Garder tout', On);
  End
  Else
  Begin
    On := MyTurn;
    Button(PnX, BY1, PW, BH, CallLabel, On);
    Button(PnX, BY2, PW, BH, 'Relancer (' + IStr(RaiseAmt) + ')', On And (Raises < MaxRaises) And
           (Chips[0] > CurBet - Bet[0]));
    Button(PnX, BY3, PW, BH, 'Passer', On);
  End;
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
  DrawTable;
  DrawPanel;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ ==================================================================== }
{ Donne                                                                 }
{ ==================================================================== }

Procedure SetMsg(S : String);
Begin
  Msg := S;
End;

Procedure Pay(P, V : LongInt);
Begin
  If V > Chips[P] Then V := Chips[P];
  If V < 0 Then V := 0;
  Chips[P] := Chips[P] - V;
  Bet[P] := Bet[P] + V;
  Pot := Pot + V;
End;

Procedure YourTurnMsg;
Begin
  If Phase = PH_BET Then
    SetMsg('A vous : ' + CallLabel + ' (C), Relancer (R) ou Passer (P).')
  Else
    SetMsg('A vous : cartes ' + Chr(133) + ' ' + Chr(130) + 'changer (clic ou 1 ' + Chr(133) +
           ' 4), puis Echanger (D) ou Garder (S).');
End;

{ au joueur suivant (ou a l'ordinateur, apres une pause) }
Procedure Prompt;
Begin
  If IsCpu(CurP) Then
  Begin
    If AutoAll <> 0 Then Thinking := 3 Else Thinking := 14;
  End
  Else YourTurnMsg;
  Redraw;
End;

Procedure StartBetRound(First : LongInt);
Var P : LongInt;
Begin
  Phase := PH_BET;
  For P := 0 To NP - 1 Do Acted[P] := 0;
  If InHand(First) Then CurP := First Else CurP := NextIn(First);
  Prompt;
End;

Procedure EndHand;
Var P, Best, NW, Share, First : LongInt; S : String;
Begin
  Phase := PH_END;
  For P := 0 To NP - 1 Do Score[P] := -1;
  If CountIn = 1 Then
  Begin
    P := NextIn(0);
    If Not InHand(P) Then P := 0;
    Chips[P] := Chips[P] + Pot;
    LastAct[P] := 'gagne ' + IStr(Pot);
    Shown[P] := 2; Score[P] := 0;
    If P = 0 Then S := 'Les autres ont pass' + Chr(130) + ' : vous gagnez le pot (' + IStr(Pot) + ').'
    Else S := PName(P) + ' gagne le pot (' + IStr(Pot) + ') : les autres ont pass' + Chr(130) + '.';
  End
  Else
  Begin
    { abattage : la main la plus basse gagne (partage en cas d'egalite) }
    Best := 999999;
    For P := 0 To NP - 1 Do
      If InHand(P) Then
      Begin
        Score[P] := EvalHand(Hand[P], Share);
        Shown[P] := 1;
        LastAct[P] := HandName(Score[P]);
        If Score[P] < Best Then Best := Score[P];
      End;
    NW := 0; First := -1;
    For P := 0 To NP - 1 Do
      If InHand(P) And (Score[P] = Best) Then
      Begin
        Inc(NW);
        If First < 0 Then First := P;
      End;
    Share := Pot Div NW;
    S := '';
    For P := 0 To NP - 1 Do
      If InHand(P) And (Score[P] = Best) Then
      Begin
        Chips[P] := Chips[P] + Share;
        Shown[P] := 2;
        If S <> '' Then S := S + ' et ';
        S := S + PName(P);
      End;
    Chips[First] := Chips[First] + Pot - Share * NW;
    If NW > 1 Then S := S + ' partagent le pot (' + IStr(Pot) + ') : ' + HandName(Best) + '.'
    Else If First = 0 Then S := 'Vous gagnez le pot (' + IStr(Pot) + ') avec ' + HandName(Best) + ' !'
    Else S := S + ' gagne le pot (' + IStr(Pot) + ') avec ' + HandName(Best) + '.';
  End;
  Pot := 0; CurBet := 0;
  For P := 0 To NP - 1 Do Bet[P] := 0;
  { joueurs ruines }
  For P := 0 To NP - 1 Do
    If (Out[P] = 0) And (Chips[P] < BigBlind) Then Out[P] := 1;
  If (Out[0] <> 0) And (AutoAll = 0) Then
  Begin
    Phase := PH_OVER;
    S := S + ' Vous ' + Chr(136) + 'tes ruin' + Chr(130) + '.';
  End
  Else If (Out[1] <> 0) And (Out[2] <> 0) And (Out[3] <> 0) Then
  Begin
    Phase := PH_OVER;
    S := S + ' Vous avez ruin' + Chr(130) + ' vos adversaires !';
  End
  Else If (AutoAll <> 0) And (Out[0] + Out[1] + Out[2] + Out[3] >= 3) Then Phase := PH_OVER;
  SetMsg(S + '  Entr' + Chr(130) + 'e : ' + 'donne suivante.');
  Wait := 0;
  Redraw;
End;

Procedure NewHand;
Var P, K, Sb, Bb : LongInt;
Begin
  Inc(HandNo);
  Shuffle;
  Dealer := NextSeat(Dealer);
  For P := 0 To NP - 1 Do
  Begin
    Bet[P] := 0; Folded[P] := 0; Acted[P] := 0; Shown[P] := 0; Score[P] := -1;
    If Out[P] <> 0 Then LastAct[P] := '' Else LastAct[P] := '';
  End;
  For K := 0 To 3 Do PickSel[K] := 0;
  For K := 0 To 3 Do
    For P := 0 To NP - 1 Do
      If Out[P] = 0 Then Hand[P][K] := DealOne;
  SortHand(Hand[0]);
  Pot := 0; Round := 0; Raises := 0;
  Sb := NextSeat(Dealer); Bb := NextSeat(Sb);
  Pay(Sb, SmallBlind); LastAct[Sb] := 'petite blinde';
  Pay(Bb, BigBlind); LastAct[Bb] := 'grosse blinde';
  CurBet := BigBlind;
  StartBetRound(NextSeat(Bb));
End;

Procedure NewGame;
Var P : LongInt;
Begin
  For P := 0 To NP - 1 Do
  Begin
    Chips[P] := StartChips; Out[P] := 0;
  End;
  Dealer := Rnd(NP); HandNo := 0;
  NewHand;
End;

{ fin d'un tour d'encheres : echange, ou abattage apres le quatrieme }
Procedure EndBetRound;
Var P : LongInt;
Begin
  If Round >= 3 Then
  Begin
    EndHand;
    Exit;
  End;
  Phase := PH_DRAW;
  { les mises du tour rejoignent le pot }
  CurBet := 0; Raises := 0;
  For P := 0 To NP - 1 Do
  Begin
    Acted[P] := 0;
    Bet[P] := 0;
  End;
  CurP := NextIn(Dealer);
  Prompt;
End;

Function RoundDone : Boolean;
Var P : LongInt;
Begin
  RoundDone := True;
  For P := 0 To NP - 1 Do
    If InHand(P) And (Chips[P] > 0) Then
      If (Acted[P] = 0) Or (Bet[P] <> CurBet) Then RoundDone := False;
End;

{ A : 0 passer, 1 parole ou suivre, 2 relancer }
Procedure Act(P, A : LongInt);
Var V, Q : LongInt;
Begin
  If (Phase <> PH_BET) Or (P <> CurP) Then Exit;
  If (A = 2) And ((Raises >= MaxRaises) Or (Chips[P] <= CurBet - Bet[P])) Then A := 1;
  Case A Of
    0 :
      Begin
        Folded[P] := 1;
        LastAct[P] := 'passe';
      End;
    1 :
      Begin
        V := CurBet - Bet[P];
        If V <= 0 Then LastAct[P] := 'parole'
        Else
        Begin
          Pay(P, V);
          If Chips[P] = 0 Then LastAct[P] := 'tapis' Else LastAct[P] := 'suit ' + IStr(V);
        End;
      End;
  Else
    Begin
      V := CurBet - Bet[P] + RaiseAmt;
      Pay(P, V);
      If Bet[P] > CurBet Then CurBet := Bet[P];
      Inc(Raises);
      LastAct[P] := 'relance ' + IStr(CurBet);
      For Q := 0 To NP - 1 Do If Q <> P Then Acted[Q] := 0;
    End;
  End;
  Acted[P] := 1;
  If P = 0 Then
    SetMsg('Vous : ' + LastAct[0] + '.')
  Else
    SetMsg(PName(P) + ' : ' + LastAct[P] + '.');
  If CountIn = 1 Then
  Begin
    EndHand;
    Exit;
  End;
  If RoundDone Then
  Begin
    EndBetRound;
    Exit;
  End;
  CurP := NextIn(CurP);
  Prompt;
End;

{ echange des cartes choisies de P ; tous ont echange : encheres }
Procedure DrawCards(P : LongInt; Var Pick : Array Of LongInt);
Var K, N, Q, Done : LongInt;
Begin
  If (Phase <> PH_DRAW) Or (P <> CurP) Then Exit;
  N := 0;
  For K := 0 To 3 Do
    If Pick[K] <> 0 Then
    Begin
      Discard[NDiscard] := Hand[P][K];
      If NDiscard < 51 Then Inc(NDiscard);
      Hand[P][K] := DealOne;
      Inc(N);
      Pick[K] := 0;
    End;
  If P = 0 Then SortHand(Hand[0]);
  Case N Of
    0 : LastAct[P] := 'garde tout';
    1 : LastAct[P] := 'prend 1 carte';
  Else
    LastAct[P] := 'prend ' + IStr(N) + ' cartes';
  End;
  If P = 0 Then SetMsg('Vous : ' + LastAct[0] + '.') Else SetMsg(PName(P) + ' ' + LastAct[P] + '.');
  Acted[P] := 1;
  Done := 1;
  For Q := 0 To NP - 1 Do If InHand(Q) And (Acted[Q] = 0) Then Done := 0;
  If Done = 1 Then
  Begin
    Inc(Round);
    CurBet := 0; Raises := 0;
    For Q := 0 To NP - 1 Do Bet[Q] := 0;
    StartBetRound(NextIn(Dealer));
    Exit;
  End;
  CurP := NextIn(CurP);
  Prompt;
End;

{ ==================================================================== }
{ Ordinateur (strategie du prototype, avec la vraie valeur des mains)   }
{ ==================================================================== }

Function CpuAction(P : LongInt) : LongInt;
Var Sc, Mask, N, Top, ToCall, Left, A : LongInt;
Begin
  Sc := EvalHand(Hand[P], Mask);
  N := NCards(Sc); Top := TopVal(Sc);
  ToCall := CurBet - Bet[P];
  Left := 3 - Round;                    { echanges restants }
  A := 1;
  If N = 4 Then
  Begin
    { badugi : relancer (prototype : bonne main) }
    If (Top <= 9) Or (Rnd(3) = 0) Then A := 2;
  End
  Else If N = 3 Then
  Begin
    If (Left >= 2) And (Top <= 6) And (Rnd(2) = 0) Then A := 2
    Else If (Left = 0) And (ToCall > 0) And (Top > 7) And (Rnd(3) <> 0) Then A := 0;
  End
  Else If N = 2 Then
  Begin
    If ToCall > 0 Then
      If (Left = 0) Or (ToCall > BigBlind) Or ((Left = 1) And (Rnd(2) = 0)) Then A := 0;
  End
  Else If ToCall > 0 Then A := 0;
  { petite part de hasard : suivre au lieu de passer }
  If (A = 0) And (ToCall <= BigBlind) And (Rnd(5) = 0) Then A := 1;
  CpuAction := A;
End;

{ cartes a echanger : celles hors du meilleur groupe (prototype) ; avec
  encore des echanges, aussi une carte haute du groupe }
Procedure CpuPick(P : LongInt; Var Pick : Array Of LongInt);
Var Sc, Mask, K, Top, Hi : LongInt;
Begin
  Sc := EvalHand(Hand[P], Mask);
  For K := 0 To 3 Do
    If (Mask And (1 Shl K)) = 0 Then Pick[K] := 1 Else Pick[K] := 0;
  Top := TopVal(Sc);
  If (NCards(Sc) = 4) And (Top >= 10) And (Round < 2) Then
  Begin
    Hi := -1;
    For K := 0 To 3 Do If BVal(Hand[P][K]) = Top Then Hi := K;
    If Hi >= 0 Then Pick[Hi] := 1;
  End;
End;

Procedure CpuTurn;
Var Pick : Array[0..3] Of LongInt;
Begin
  Thinking := 0;
  If Not IsCpu(CurP) Then Exit;
  If Phase = PH_BET Then Act(CurP, CpuAction(CurP))
  Else If Phase = PH_DRAW Then
  Begin
    CpuPick(CurP, Pick);
    DrawCards(CurP, Pick);
  End;
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Procedure NextOrNew;
Begin
  If Phase = PH_END Then NewHand
  Else If Phase = PH_OVER Then NewGame;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW :
      If (Phase = PH_OVER) Or (HandNo = 0) Or
         (Ask('Abandonner la partie en cours et recommencer avec ' + IStr(StartChips) + ' jetons chacun ?',
              'Badugi', MB_YESNO Or MB_QUERY) = MBID_YES) Then NewGame;
    CM_NEXT : NextOrNew;
    CM_CALL : If MyTurn And (Phase = PH_BET) Then Act(0, 1);
    CM_RAISE : If MyTurn And (Phase = PH_BET) Then Act(0, 2);
    CM_FOLD : If MyTurn And (Phase = PH_BET) Then Act(0, 0);
    CM_DRAW : If MyTurn And (Phase = PH_DRAW) Then DrawCards(0, PickSel);
    CM_STAND :
      If MyTurn And (Phase = PH_DRAW) Then
      Begin
        PickSel[0] := 0; PickSel[1] := 0; PickSel[2] := 0; PickSel[3] := 0;
        DrawCards(0, PickSel);
      End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        LClr;
        LAdd('Vous (Sud) jouez contre Nord, Est et Ouest ; chacun commence avec ' + IStr(StartChips) +
             ' jetons. Chaque donne : petite blinde (' + IStr(SmallBlind) + ') et grosse blinde (' +
             IStr(BigBlind) + '), quatre cartes ' + Chr(133) + ' chacun, puis quatre tours d''ench' + Chr(138) +
             'res s' + Chr(130) + 'par' + Chr(130) + 's par trois ' + Chr(130) + 'changes (on remplace les ' +
             'cartes de son choix). Relance : ' + IStr(RaiseAmt) + ' jetons, quatre au plus par tour.' +
             Chr(10) + Chr(10));
        LAdd('La main la plus basse gagne. Seules comptent les cartes de couleurs diff' + Chr(130) +
             'rentes et de valeurs diff' + Chr(130) + 'rentes (l''as vaut 1) : quatre cartes ainsi (un ' +
             'badugi) battent toute main de trois cartes, qui bat toute main de deux cartes. A nombre ' +
             Chr(130) + 'gal, on compare la plus haute carte, puis la suivante. Meilleure main : A-2-3-4 de ' +
             'quatre couleurs.' + Chr(10) + Chr(10));
        LAdd('Clavier : C (parole ou suivre), R (relancer), P (passer), 1 ' + Chr(133) + ' 4 (cartes ' + Chr(133) +
             ' ' + Chr(130) + 'changer), D (' + Chr(130) + 'changer), S (garder tout), Entr' + Chr(130) +
             'e (donne suivante), F2 (nouvelle partie).');
        Dummy := LMsgBox('Badugi - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_HANDS :
      Begin
        LClr;
        LAdd('Exemples, de la meilleure ' + Chr(133) + ' la moins bonne :' + Chr(10) + Chr(10));
        LAdd('A-2-3-4 de quatre couleurs : badugi parfait.' + Chr(10));
        LAdd('2-3-5-7 de quatre couleurs : badugi au 7.' + Chr(10));
        LAdd('V-9-5-2 de quatre couleurs : badugi au valet.' + Chr(10));
        LAdd('A-2-3 de trois couleurs (quatri' + Chr(138) + 'me carte de la m' + Chr(136) +
             'me couleur ou de la m' + Chr(136) + 'me valeur) : trois cartes.' + Chr(10));
        LAdd('Deux cartes, puis une carte (quatre cartes de la m' + Chr(136) + 'me couleur : la plus basse ' +
             'compte seule).');
        Dummy := LMsgBox('Badugi - Mains', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Badugi pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'BADUGI.PAS de 7iles : poker cor' + Chr(130) + 'en ' + Chr(133) + ' quatre cartes, ' +
                            'contre trois adversaires.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal ' +
                            'et compil' + Chr(130) + ' par OS2PC.', 'A propos de Badugi', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Procedure ToggleCard(K : LongInt);
Begin
  If Not MyTurn Or (Phase <> PH_DRAW) Or (K < 0) Or (K > 3) Then Exit;
  PickSel[K] := 1 - PickSel[K];
  Redraw;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, K, Cx : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= BY1) And (Y < BY1 + BH) Then
    Begin
      Case Phase Of
        PH_BET : Command(CM_CALL);
        PH_DRAW : Command(CM_DRAW);
      Else
        NextOrNew;
      End;
    End
    Else If (Y >= BY2) And (Y < BY2 + BH) Then
    Begin
      If Phase = PH_BET Then Command(CM_RAISE) Else If Phase = PH_DRAW Then Command(CM_STAND);
    End
    Else If (Y >= BY3) And (Y < BY3 + BH) And (Phase = PH_BET) Then Command(CM_FOLD);
    Exit;
  End;
  { cartes de Sud (de droite a gauche : la carte du dessus d'abord) }
  If (Y >= 288) And (Y < 304 + CardH) Then
    For K := 3 DownTo 0 Do
    Begin
      Cx := MidX - 149 + K * 76;
      If (X >= Cx) And (X < Cx + CardW) Then
      Begin
        ToggleCard(K);
        Exit;
      End;
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
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      If Phase = PH_DRAW Then Command(CM_DRAW) Else NextOrNew;
      Exit;
    End;
  End;
  If ((Fl And KC_CHAR) <> 0) And ((Fl And (KC_ALT Or KC_CTRL)) = 0) Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'C' : Command(CM_CALL);
      'R' : Command(CM_RAISE);
      'P', 'F' : Command(CM_FOLD);
      'D' : Command(CM_DRAW);
      'S' : Command(CM_STAND);
      'N' : NextOrNew;
      '1', '2', '3', '4' : ToggleCard(Ch - 49);
      ' ' : If Phase = PH_DRAW Then Command(CM_DRAW) Else If Phase = PH_BET Then Command(CM_CALL) Else NextOrNew;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Procedure TimerTick;
Begin
  If (Phase = PH_END) Or (Phase = PH_OVER) Then
  Begin
    If AutoAll <> 0 Then
    Begin
      Inc(Wait);
      If Wait > 30 Then
      Begin
        Wait := 0;
        NextOrNew;
      End;
    End;
    Exit;
  End;
  If Thinking > 0 Then
  Begin
    Dec(Thinking);
    If Thinking = 0 Then CpuTurn;
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
    WM_TIMER : If Lo16(Mp1) = 1 Then TimerTick;
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
  Msg := ''; AutoAll := 0; Thinking := 0; Wait := 0; Phase := PH_OVER; HandNo := 0; CurP := -1;
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
  Dummy := WinRegisterClass(Hab, Z('BADUGI'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('BADUGI'), Z2('Badugi'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_NEXT, '~Donne suivante' + Chr(9) + 'Entr' + Chr(130) + 'e');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_CALL, 'Parole ou ~suivre' + Chr(9) + 'C');
  MItem(MIS_TEXT, 0, CM_RAISE, '~Relancer' + Chr(9) + 'R');
  MItem(MIS_TEXT, 0, CM_FOLD, '~Passer' + Chr(9) + 'P');
  MItem(MIS_TEXT, 0, CM_DRAW, '~Echanger' + Chr(9) + 'D');
  MItem(MIS_TEXT, 0, CM_STAND, '~Garder tout' + Chr(9) + 'S');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 10);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_HANDS, '~Mains');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Badugi');
  MenuClose(H2, 3);
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
  Dummy := WinStartTimer(Hab, Client, 1, 45);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
