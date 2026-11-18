{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: POKER - poker a cinq cartes (draw) contre l'ordinateur pour
                le Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program POKER;

{$R-,S-,I-}

{ Compilation : OS2PC POKER.PAS   (produit POKER.EXE)

  Portage vers OS/2-0 du prototype POKER.PAS du depot 7iles (Turbo Pascal
  et BGI) : fenetre de Presentation Manager avec menus, souris, tapis,
  cartes dessinees (comme le Solitaire - Klondike), panneau de l'argent,
  barre d'etat et apparence d'OS/2.

  Une donne : chacun mise (la mise choisie dans le menu, 50 $ comme le
  prototype) et recoit cinq cartes ; vous choisissez les cartes a echanger
  (clic ou touches 1 a 5) puis Echanger ; l'ordinateur echange les siennes.
  Ensuite : Abattre (montrer les mains), Relancer (doubler la mise :
  l'ordinateur suit ou se couche) ou Se coucher (vous perdez la mise).
  La meilleure main gagne le pot ; a combinaison egale, les hauteurs des
  cartes departagent (le prototype ne comparait que les combinaisons).
  Combinaisons : carte haute, paire, double paire, brelan, quinte (l'as
  compte aussi pour 1), couleur, full, carre, quinte flush, quinte flush
  royale. Vous commencez avec 1000 $.

  Clavier : Espace ou Entree (Distribuer, Echanger, Abattre, donne
  suivante), 1 a 5 (choisir les cartes a echanger), R (relancer), C (se
  coucher), F2 (nouvelle partie), F1 (regles).
  Parametres : /SEED:n (donnes reproductibles, pour les essais). }

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
  VK_NEWLINE = $08; VK_SPACE = $10; VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  CM_NEW = 101; CM_ACT = 102; CM_RAISE = 103; CM_FOLD = 104; CM_QUIT = 105;
  CM_BET10 = 111; CM_BET25 = 112; CM_BET50 = 113; CM_BET100 = 114;
  CM_RULES = 301; CM_HANDS = 302; CM_ABOUT = 303;
  { combinaisons }
  HIGH_CARD = 0; ONE_PAIR = 1; TWO_PAIR = 2; THREE_KIND = 3; STRAIGHT = 4; C_FLUSH = 5; FULL_HOUSE = 6;
  FOUR_KIND = 7; STRAIGHT_FLUSH = 8; ROYAL_FLUSH = 9;
  { disposition (zone client, Y vers le bas) }
  CardW = 70; CardH = 96;
  TX = 8; TY = 8; TW = 440; THt = 382;   { tapis }
  HX = 26; HStep = 84;                    { premiere carte, pas }
  CpuY = 36; PlyY = 258;                  { haut des cartes }
  PnX = 460; PW = 140;
  CWant = 608; CHWant = 420;
  StartMoney = 1000;

Type
  THand = Array[0..4] Of LongInt;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Deck : Array[0..51] Of LongInt;
  NDeck : LongInt;
  PH, CHd : THand;                       { mains : vous, l'ordinateur }
  PSel : THand;                          { cartes a echanger }
  Phase, Money, Bet, HandBet, Pot, Seed, CpuSwap, Result, Hands, Won, Folded, Raised : LongInt;
  PName, CName, Msg, LMsg : String;
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

Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

Function Dollars(V : LongInt) : String;
Begin
  Dollars := IStr(V) + ' $';
End;

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

{ --- barre de menus : modele de PM (cb, version, nombre, articles) --- }
{ ==================================================================== }
{ Cartes                                                                }
{ ==================================================================== }
{ carte : couleur * 13 + rang (0 as ... 12 roi) ; couleurs : 0 coeur,
  1 carreau, 2 trefle, 3 pique }

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
  While K < CardW + CardH Do
  Begin
    GLn(Hps, X + 5 + MaxI(0, K - CardH + 10), Y + 5 + MinI(K, CardH - 10), X + 5 + MinI(K, CardW - 10),
        Y + 5 + MaxI(0, K - CardW + 10), CLR_BLUE);
    K := K + 8;
  End;
  GBox(Hps, X + CardW Div 2 - 14, Y + CardH Div 2 - 12, X + CardW Div 2 + 14, Y + CardH Div 2 + 12, CLR_YELLOW,
       DRO_FILL, 24);
  TextXY(Hps, X + CardW Div 2 - 8, Y + CardH Div 2 - 8, '2', CLR_DARKBLUE, CLR_YELLOW);
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

{ valeur d'une carte pour le poker : 2 .. 14 (l'as est haut) }
Function CVal(C : LongInt) : LongInt;
Begin
  If Rank(C) = 0 Then CVal := 14 Else CVal := Rank(C) + 1;
End;

Var
  GV, GN : Array[0..4] Of LongInt;      { groupes de la derniere main analysee }
  NGroups, HType, HHigh : LongInt;

{ analyse : combinaison (HType), groupes (valeur, nombre) tries par nombre
  puis par valeur ; HHigh = carte haute d'une quinte }
Procedure Analyse(Var H : THand);
Var Cnt : Array[2..14] Of LongInt; I, J, V, N, T : LongInt; Fl, St : Boolean;
Begin
  For V := 2 To 14 Do Cnt[V] := 0;
  For I := 0 To 4 Do Inc(Cnt[CVal(H[I])]);
  NGroups := 0;
  For N := 4 DownTo 1 Do
    For V := 14 DownTo 2 Do
      If Cnt[V] = N Then
      Begin
        GV[NGroups] := V; GN[NGroups] := N;
        Inc(NGroups);
      End;
  Fl := True;
  For I := 1 To 4 Do If Suit(H[I]) <> Suit(H[0]) Then Fl := False;
  St := False; HHigh := 0;
  If NGroups = 5 Then
  Begin
    If GV[0] - GV[4] = 4 Then
    Begin
      St := True; HHigh := GV[0];
    End
    Else If (GV[0] = 14) And (GV[1] = 5) Then
    Begin
      { quinte blanche : A 2 3 4 5 (l'as compte pour 1) }
      St := True; HHigh := 5;
      For J := 0 To 3 Do GV[J] := GV[J + 1];
      GV[4] := 1;
    End;
  End;
  If St And Fl Then
  Begin
    If HHigh = 14 Then T := ROYAL_FLUSH Else T := STRAIGHT_FLUSH;
  End
  Else If GN[0] = 4 Then T := FOUR_KIND
  Else If (GN[0] = 3) And (GN[1] = 2) Then T := FULL_HOUSE
  Else If Fl Then T := C_FLUSH
  Else If St Then T := STRAIGHT
  Else If GN[0] = 3 Then T := THREE_KIND
  Else If (GN[0] = 2) And (GN[1] = 2) Then T := TWO_PAIR
  Else If GN[0] = 2 Then T := ONE_PAIR
  Else T := HIGH_CARD;
  HType := T;
End;

{ force de la main : combinaison puis hauteurs (pour departager) }
Function HandScore(Var H : THand) : LongInt;
Var S, I : LongInt;
Begin
  Analyse(H);
  S := HType;
  For I := 0 To 4 Do
    If I < NGroups Then S := S * 15 + GV[I] Else S := S * 15;
  HandScore := S;
End;

Function ValName(V : LongInt; Plural : Boolean) : String;
Begin
  Case V Of
    1, 14 : ValName := 'as';
    13 : If Plural Then ValName := 'rois' Else ValName := 'roi';
    12 : If Plural Then ValName := 'dames' Else ValName := 'dame';
    11 : If Plural Then ValName := 'valets' Else ValName := 'valet';
  Else
    ValName := IStr(V);
  End;
End;

{ << de rois >>, << d'as >> }
Function DeVal(V : LongInt) : String;
Begin
  If (V = 14) Or (V = 1) Then DeVal := 'd''as' Else DeVal := 'de ' + ValName(V, True);
End;

Function AuVal(V : LongInt) : String;
Begin
  If V = 14 Then AuVal := Chr(133) + ' l''as'
  Else If V >= 11 Then
  Begin
    If V = 12 Then AuVal := Chr(133) + ' la dame' Else AuVal := 'au ' + ValName(V, False);
  End
  Else AuVal := 'au ' + IStr(V);
End;

Function HandName(Var H : THand) : String;
Begin
  Analyse(H);
  Case HType Of
    HIGH_CARD : HandName := 'Hauteur ' + ValName(GV[0], False);
    ONE_PAIR : HandName := 'Paire ' + DeVal(GV[0]);
    TWO_PAIR : HandName := 'Double paire (' + ValName(GV[0], True) + ' et ' + ValName(GV[1], True) + ')';
    THREE_KIND : HandName := 'Brelan ' + DeVal(GV[0]);
    STRAIGHT : HandName := 'Quinte ' + AuVal(HHigh);
    C_FLUSH : HandName := 'Couleur ' + AuVal(GV[0]);
    FULL_HOUSE : HandName := 'Full aux ' + ValName(GV[0], True) + ' par les ' + ValName(GV[1], True);
    FOUR_KIND : HandName := 'Carr' + Chr(130) + ' ' + DeVal(GV[0]);
    STRAIGHT_FLUSH : HandName := 'Quinte flush ' + AuVal(HHigh);
  Else
    HandName := 'Quinte flush royale';
  End;
End;

{ ==================================================================== }
{ Donne                                                                 }
{ ==================================================================== }

Procedure Shuffle;
Var I, J, T : LongInt;
Begin
  For I := 0 To 51 Do Deck[I] := I;
  For I := 51 DownTo 1 Do
  Begin
    J := Rnd(I + 1);
    T := Deck[I]; Deck[I] := Deck[J]; Deck[J] := T;
  End;
  NDeck := 52;
End;

Function DrawCard : LongInt;
Begin
  Dec(NDeck);
  DrawCard := Deck[NDeck];
End;

{ cartes que l'ordinateur garde (Keep[i] = 1) }
Procedure CpuChoose(Var H : THand; Var Keep : THand);
Var I, J, N, S, V, Lo, Hi, Best : LongInt; Cnt : Array[0..3] Of LongInt;
Begin
  For I := 0 To 4 Do Keep[I] := 0;
  Analyse(H);
  If HType >= STRAIGHT Then
  Begin
    For I := 0 To 4 Do Keep[I] := 1;
    Exit;
  End;
  If HType >= ONE_PAIR Then
  Begin
    { garde les paires, brelans et carres }
    For I := 0 To 4 Do
      For J := 0 To NGroups - 1 Do
        If (GN[J] >= 2) And (CVal(H[I]) = GV[J]) Then Keep[I] := 1;
    Exit;
  End;
  { quatre cartes de la meme couleur : on tire a la couleur }
  For S := 0 To 3 Do Cnt[S] := 0;
  For I := 0 To 4 Do Inc(Cnt[Suit(H[I])]);
  For S := 0 To 3 Do
    If Cnt[S] = 4 Then
    Begin
      For I := 0 To 4 Do If Suit(H[I]) = S Then Keep[I] := 1;
      Exit;
    End;
  { quatre cartes qui se suivent (quinte ouverte) }
  For J := 0 To 4 Do
  Begin
    Lo := 15; Hi := 0;
    For I := 0 To 4 Do
      If I <> J Then
      Begin
        V := CVal(H[I]);
        If V < Lo Then Lo := V;
        If V > Hi Then Hi := V;
      End;
    If (Hi - Lo = 3) And (Hi < 14) Then
    Begin
      For I := 0 To 4 Do If I <> J Then Keep[I] := 1;
      Exit;
    End;
  End;
  { sinon : la plus haute carte si c'est une figure ou un as }
  Best := 0;
  For I := 1 To 4 Do If CVal(H[I]) > CVal(H[Best]) Then Best := I;
  If CVal(H[Best]) >= 11 Then Keep[Best] := 1;
  N := 0;
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
{ Dessin                                                                }
{ ==================================================================== }

{ carte dont le coin haut gauche est (X, Y) (Y vers le bas) }
Procedure CardAt(X, Y, C : LongInt; Face, Hilite : Boolean);
Var Yb : LongInt;
Begin
  Yb := CH - Y - CardH;
  If Face Then DrawFace(Hps, X, Yb, C, Hilite) Else DrawBack(Hps, X, Yb);
End;

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_DARKGRAY, CLR_PALEGRAY);
End;

Function Label1 : String;
Begin
  Case Phase Of
    0 : Label1 := 'Distribuer';
    1 : Label1 := Chr(144) + 'changer';
    2 : Label1 := 'Abattre';
  Else
    Label1 := 'Donne suivante';
  End;
End;

Procedure CenterTxt(Y : LongInt; S : String; Fg : LongInt);
Begin
  OutTxt(TX + (TW - Length(S) * 8) Div 2, Y, S, Fg, CLR_DARKGREEN);
End;

Procedure DrawTable;
Var I, X, Y : LongInt; S : String;
Begin
  FBar(TX, TY, TX + TW - 1, TY + THt - 1, CLR_DARKGREEN);
  Edge(TX - 2, TY - 2, TX + TW + 1, TY + THt + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(TX - 1, TY - 1, TX + TW, TY + THt, CLR_BLACK, CLR_PALEGRAY);
  S := 'Ordinateur';
  If (Phase >= 2) And (Folded <> 2) Then
  Begin
    If CpuSwap = 0 Then S := S + ' (servi)'
    Else S := S + ' (' + IStr(CpuSwap) + ' carte(s) ' + Chr(130) + 'chang' + Chr(130) + 'e(s))';
  End;
  If Folded = 2 Then S := S + ' : se couche';
  OutTxt(TX + HX, TY + 6, S, CLR_WHITE, CLR_DARKGREEN);
  If Phase = 0 Then
  Begin
    CenterTxt(TY + 170, 'Mise : ' + Dollars(Bet) + ' par donne', CLR_WHITE);
    CenterTxt(TY + 194, 'Cliquez Distribuer (ou Espace).', CLR_YELLOW);
    Exit;
  End;
  For I := 0 To 4 Do
    CardAt(TX + HX + I * HStep, CpuY, CHd[I], (Phase = 3) And (Folded = 0), False);
  If (Phase = 3) And (Folded = 0) Then CenterTxt(CpuY + CardH + 6, CName, CLR_YELLOW);
  CenterTxt(TY + 156, 'Pot : ' + Dollars(Pot), CLR_WHITE);
  If Phase = 3 Then
  Begin
    If Result = 1 Then S := 'GAGN' + Chr(144) + ' !' Else If Result = 2 Then S := 'PERDU'
    Else S := Chr(144) + 'GALIT' + Chr(144);
    If Result = 1 Then BigText(TX + (TW - Length(S) * 16) Div 2, TY + 178, S, CLR_YELLOW, CLR_DARKGREEN)
    Else BigText(TX + (TW - Length(S) * 16) Div 2, TY + 178, S, CLR_WHITE, CLR_DARKGREEN);
  End;
  CenterTxt(PlyY - 30, 'Vous : ' + PName, CLR_YELLOW);
  For I := 0 To 4 Do
  Begin
    X := TX + HX + I * HStep; Y := PlyY;
    If PSel[I] <> 0 Then
    Begin
      Y := PlyY - 12;
      OutTxt(X + (CardW - 56) Div 2, PlyY + CardH + 4, Chr(144) + 'CHANGE', CLR_YELLOW, CLR_DARKGREEN);
    End;
    CardAt(X, Y, PH[I], (Folded <> 1) Or True, PSel[I] <> 0);
    If Phase = 1 Then OutTxt(X + CardW Div 2 - 4, PlyY + CardH + 20, IStr(I + 1), CLR_PALEGRAY, CLR_DARKGREEN);
  End;
End;

Procedure DrawPanel;
Var S : String;
Begin
  BigText(PnX + (PW - 5 * 16) Div 2, TY + 2, 'POKER', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, TY + 44, 'Votre argent', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, TY + 62, PnX + PW - 1, TY + 102, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, TY + 63, PnX + PW - 2, TY + 101, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, TY + 64, PnX + PW - 3, TY + 100, CLR_WHITE);
  S := Dollars(Money);
  BigText(PnX + PW - 8 - Length(S) * 16, TY + 66, S, CLR_DARKGREEN, CLR_WHITE);
  OutTxt(PnX, TY + 112, 'Mise : ' + Dollars(Bet), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, TY + 130, 'Donnes : ' + IStr(Hands), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, TY + 148, 'Gagn' + Chr(130) + 'es : ' + IStr(Won), CLR_BLACK, CLR_PALEGRAY);
  Button(PnX, TY + 214, PW, 30, Label1, True);
  Button(PnX, TY + 250, PW, 30, 'Relancer', Phase = 2);
  Button(PnX, TY + 286, PW, 30, 'Se coucher', Phase = 2);
  Button(PnX, TY + 340, PW, 30, 'Nouvelle partie', True);
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
  SetMark(CM_BET10, Bet = 10); SetMark(CM_BET25, Bet = 25);
  SetMark(CM_BET50, Bet = 50); SetMark(CM_BET100, Bet = 100);
End;

Procedure NewGame;
Var I : LongInt;
Begin
  Money := StartMoney; Hands := 0; Won := 0; Phase := 0; Pot := 0; Folded := 0;
  For I := 0 To 4 Do PSel[I] := 0;
  Msg := 'Nouvelle partie : vous avez ' + Dollars(Money) + '. Cliquez Distribuer (Espace).';
  Redraw;
End;

Procedure Deal;
Var I : LongInt;
Begin
  If Money < Bet Then
  Begin
    If Ask('Vous n''avez plus assez d''argent pour miser ' + Dollars(Bet) + '.' + Chr(10) + Chr(10) +
           'Une nouvelle partie (' + Dollars(StartMoney) + ') ?', 'Poker', MB_YESNO Or MB_QUERY) = MBID_YES Then
      NewGame;
    Exit;
  End;
  HandBet := Bet;
  Money := Money - HandBet;
  Pot := 2 * HandBet;
  Shuffle;
  For I := 0 To 4 Do
  Begin
    PH[I] := DrawCard;
    CHd[I] := DrawCard;
    PSel[I] := 0;
  End;
  PName := HandName(PH);
  Phase := 1; Folded := 0; Raised := 0; CpuSwap := 0; Result := 0;
  Msg := 'Choisissez les cartes ' + Chr(133) + ' ' + Chr(130) + 'changer (clic ou 1 ' + Chr(133) +
         ' 5), puis ' + Chr(144) + 'changer.';
  Redraw;
End;

Procedure Exchange;
Var I, N : LongInt; Keep : THand;
Begin
  N := 0;
  For I := 0 To 4 Do
    If PSel[I] <> 0 Then
    Begin
      PH[I] := DrawCard;
      PSel[I] := 0;
      Inc(N);
    End;
  CpuChoose(CHd, Keep);
  CpuSwap := 0;
  For I := 0 To 4 Do
    If Keep[I] = 0 Then
    Begin
      CHd[I] := DrawCard;
      Inc(CpuSwap);
    End;
  PName := HandName(PH);
  Phase := 2;
  If N = 0 Then Msg := 'Vous ' + Chr(136) + 'tes servi. ' Else Msg := IStr(N) + ' carte(s) ' + Chr(130) + 'chang' +
    Chr(130) + 'e(s). ';
  Msg := Msg + 'Abattre, Relancer (+' + Dollars(HandBet) + ') ou Se coucher ?';
  Redraw;
End;

Procedure Showdown;
Var Ps, Cs : LongInt;
Begin
  Ps := HandScore(PH); Cs := HandScore(CHd);
  PName := HandName(PH); CName := HandName(CHd);
  Inc(Hands);
  If Ps > Cs Then
  Begin
    Result := 1; Money := Money + Pot; Inc(Won);
    Msg := 'Vous gagnez ' + Dollars(Pot) + ' : ' + PName + ' contre ' + CName + '.';
  End
  Else If Cs > Ps Then
  Begin
    Result := 2;
    Msg := 'L''ordinateur gagne le pot avec : ' + CName + '.';
  End
  Else
  Begin
    Result := 0; Money := Money + Pot Div 2;
    Msg := Chr(144) + 'galit' + Chr(130) + ' : le pot est partag' + Chr(130) + '.';
  End;
  Phase := 3;
  Redraw;
End;

Procedure DoRaise;
Var Call : Boolean;
Begin
  If Phase <> 2 Then Exit;
  If Money < HandBet Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Msg := 'Pas assez d''argent pour relancer.';
    Redraw;
    Exit;
  End;
  Money := Money - HandBet;
  Raised := 1;
  { l'ordinateur suit avec une double paire ou mieux, une paire de 9 ou
    mieux, ou parfois pour voir }
  Analyse(CHd);
  Call := (HType >= TWO_PAIR) Or ((HType = ONE_PAIR) And (GV[0] >= 9)) Or (Rnd(4) = 0);
  If Call Then
  Begin
    Pot := Pot + 2 * HandBet;
    Showdown;
    Msg := 'L''ordinateur suit. ' + Msg;
    Redraw;
  End
  Else
  Begin
    Folded := 2; Result := 1; Inc(Hands); Inc(Won);
    Money := Money + Pot + HandBet;
    Msg := 'L''ordinateur se couche : vous gagnez le pot (' + Dollars(Pot) + ').';
    Phase := 3;
    Redraw;
  End;
End;

Procedure Fold;
Begin
  If Phase <> 2 Then Exit;
  Folded := 1; Result := 2; Inc(Hands);
  Msg := 'Vous vous couchez : l''ordinateur ramasse le pot (' + Dollars(Pot) + ').';
  Phase := 3;
  Redraw;
End;

Procedure MainAction;
Begin
  Case Phase Of
    1 : Exchange;
    2 : Showdown;
  Else
    Deal;
  End;
End;

Procedure ToggleCard(I : LongInt);
Begin
  If Phase <> 1 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  PSel[I] := 1 - PSel[I];
  Redraw;
End;

Procedure SetBet(B : LongInt);
Begin
  Bet := B;
  SetMarks;
  If (Phase = 1) Or (Phase = 2) Then Msg := 'La nouvelle mise (' + Dollars(B) + ') vaudra pour la prochaine donne.';
  Redraw;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_ACT : MainAction;
    CM_RAISE : DoRaise;
    CM_FOLD : Fold;
    CM_BET10 : SetBet(10);
    CM_BET25 : SetBet(25);
    CM_BET50 : SetBet(50);
    CM_BET100 : SetBet(100);
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES : Dummy := Ask('Poker ' + Chr(133) + ' cinq cartes contre l''ordinateur. Chacun mise et re' + Chr(135) +
                            'oit cinq cartes. Choisissez les cartes ' + Chr(133) + ' ' + Chr(130) + 'changer ' +
                            '(clic ou touches 1 ' + Chr(133) + ' 5) puis ' + Chr(144) + 'changer ; l''ordinateur ' +
                            Chr(130) + 'change les siennes. Ensuite : Abattre (comparer les mains), Relancer ' +
                            '(doubler la mise ; l''ordinateur suit ou se couche) ou Se coucher (perdre la mise). ' +
                            'La meilleure main ramasse le pot ; ' + Chr(133) + ' combinaison ' + Chr(130) + 'gale, ' +
                            'les hauteurs des cartes d' + Chr(130) + 'partagent.' + Chr(10) + Chr(10) +
                            'Clavier : Espace ou Entr' + Chr(130) + 'e (action principale), R (relancer), C (se ' +
                            'coucher), F2 (nouvelle partie).', 'Poker - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
    CM_HANDS : Dummy := Ask('Du plus faible au plus fort :' + Chr(10) +
                            'Carte haute' + Chr(10) + 'Paire (deux cartes de m' + Chr(136) + 'me valeur)' + Chr(10) +
                            'Double paire' + Chr(10) + 'Brelan (trois cartes de m' + Chr(136) + 'me valeur)' +
                            Chr(10) + 'Quinte (cinq cartes qui se suivent ; l''as compte aussi pour 1)' + Chr(10) +
                            'Couleur (cinq cartes de la m' + Chr(136) + 'me couleur)' + Chr(10) +
                            'Full (un brelan et une paire)' + Chr(10) + 'Carr' + Chr(130) + ' (quatre cartes de ' +
                            'm' + Chr(136) + 'me valeur)' + Chr(10) + 'Quinte flush (quinte dans une couleur)' +
                            Chr(10) + 'Quinte flush royale (du 10 ' + Chr(133) + ' l''as)', 'Poker - Combinaisons',
                            MB_OK Or MB_INFORMATION);
    CM_ABOUT : Dummy := Ask('Poker pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'POKER.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et ' +
                            'compil' + Chr(130) + ' par OS2PC.', 'A propos du Poker', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Procedure Click(Mx, My : LongInt);
Var X, Y, I, Cx : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (Y >= PlyY - 12) And (Y < PlyY + CardH) Then
    For I := 0 To 4 Do
    Begin
      Cx := TX + HX + I * HStep;
      If (X >= Cx) And (X < Cx + CardW) Then
      Begin
        ToggleCard(I);
        Exit;
      End;
    End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= TY + 214) And (Y < TY + 244) Then MainAction
    Else If (Y >= TY + 250) And (Y < TY + 280) Then DoRaise
    Else If (Y >= TY + 286) And (Y < TY + 316) Then Fold
    Else If (Y >= TY + 340) And (Y < TY + 370) Then NewGame;
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
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin MainAction; Exit; End;
  End;
  If ((Fl And KC_CHAR) = 0) Or ((Fl And (KC_ALT Or KC_CTRL)) <> 0) Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Ch >= 49) And (Ch <= 53) Then ToggleCard(Ch - 49)
  Else If Ch = 32 Then MainAction
  Else If (Ch = 82) Or (Ch = 114) Then DoRaise
  Else If (Ch = 67) Or (Ch = 99) Then Fold
  Else If (Ch = 78) Or (Ch = 110) Then MainAction
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
  Msg := ''; LMsg := ''; Bet := 50; Phase := 0;
  Client := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('POKER'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('POKER'), Z2('Poker'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_ACT, '~Distribuer / action' + Chr(9) + 'Espace');
  MItem(MIS_TEXT, 0, CM_RAISE, '~Relancer' + Chr(9) + 'R');
  MItem(MIS_TEXT, 0, CM_FOLD, 'Se ~coucher' + Chr(9) + 'C');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_BET10, 'Mise de 10 $');
  MItem(MIS_TEXT, 0, CM_BET25, 'Mise de 25 $');
  MItem(MIS_TEXT, MIA_CHECKED, CM_BET50, 'Mise de 50 $');
  MItem(MIS_TEXT, 0, CM_BET100, 'Mise de 100 $');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 11);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_HANDS, '~Combinaisons');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos du Poker');
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
  SetMarks;
  NewGame;
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
