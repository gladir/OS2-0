{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BACCARAT - Baccarat (Punto Banco) pour le Presentation
                Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program BACCARAT;

{$R-,S-,I-}

{ Compilation : OS2PC BACCARAT.PAS   (produit BACCARAT.EXE)

  Portage vers OS/2-0 du prototype BACCARAT.PAS du depot 7iles (Turbo
  Pascal et BGI) : fenetre de Presentation Manager avec menus, souris,
  tapis vert, cartes dessinees (comme le Poker), cases de mise, jetons,
  panneau de l'argent, historique des coups, barre d'etat et apparence
  d'OS/2.

  Regles (Punto Banco) : vous misez sur le Joueur (paye 1 pour 1), le
  Banquier (paye 0,95 pour 1 : commission de 5 %) ou l'Egalite (paye 8
  pour 1 ; sur une egalite, les mises Joueur et Banquier sont rendues).
  Le Joueur et le Banquier recoivent deux cartes ; l'as vaut 1, les
  figures et le 10 valent 0, les autres leur valeur ; seul le chiffre des
  unites compte (15 = 5). Un 8 ou un 9 sur deux cartes est un naturel : le
  coup s'arrete. Sinon le Joueur tire une troisieme carte avec 0 a 5 ; le
  Banquier tire selon le tableau classique (comme le prototype). La main
  la plus proche de 9 gagne. Sabot de six jeux. Vous commencez avec
  1000 $ (comme le prototype).

  Differences avec le prototype : la regle du naturel (8 ou 9) est
  appliquee, et les gains rendent la mise en plus du gain (le prototype
  ne rendait que le gain, et 95 % de la mise pour le Banquier).

  Clavier : 1 (Joueur), 2 (Banquier), 3 (Egalite), + et - (mise),
  Espace ou Entree (distribuer), F2 ou N (nouvelle partie), F1 (regles).
  Souris : cliquer une case de mise, les boutons du panneau.
  Parametres : /SEED:n (sabot reproductible, pour les essais). }

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
  CM_NEW = 101; CM_DEAL = 102; CM_PLAYER = 103; CM_BANKER = 104; CM_TIE = 105; CM_MORE = 106; CM_LESS = 107;
  CM_QUIT = 108; CM_FAST = 109;
  CM_RULES = 301; CM_ABOUT = 302;
  { disposition (zone client, Y vers le bas) }
  CardW = 70; CardH = 96;
  TX = 8; TY = 8; TW = 440; THt = 382;   { tapis }
  CStep = 46;                             { pas des cartes d'une main }
  HandY = 44;                             { haut des cartes }
  ZoneY = 262; ZoneH = 84; ZoneW = 130;   { cases de mise }
  PnX = 460; PW = 140;
  CWant = 608; CHWant = 420;
  StartMoney = 1000;
  NDecks = 6; ShoeN = 312;

Type
  THand3 = Array[0..2] Of LongInt;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Shoe : Array[0..ShoeN - 1] Of LongInt;
  ShoePos : LongInt;
  PC, BC : THand3;        { cartes du Joueur et du Banquier }
  NP, NB : LongInt;
  Order : Array[0..5] Of LongInt;         { ordre de la donne : 0..2 Joueur, 10..12 Banquier }
  NOrd, Shown : LongInt;
  Phase, Money, Bet, BetOn, Staked, Gain, Winner, Hands, Won, Seed, Fast : LongInt;
  Hist : Array[0..17] Of LongInt;         { 0 Joueur, 1 Banquier, 2 Egalite }
  NHist : LongInt;
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

Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';

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

{ ==================================================================== }
{ Baccarat : valeurs, sabot, coup                                       }
{ ==================================================================== }

{ valeur au baccarat : as 1, 2 a 9, dix et figures 0 }
Function BVal(C : LongInt) : LongInt;
Begin
  If Rank(C) >= 9 Then BVal := 0 Else BVal := Rank(C) + 1;
End;

Procedure ShuffleShoe;
Var I, J, T : LongInt;
Begin
  For I := 0 To ShoeN - 1 Do Shoe[I] := I Mod 52;
  For I := ShoeN - 1 DownTo 1 Do
  Begin
    J := Rnd(I + 1);
    T := Shoe[I]; Shoe[I] := Shoe[J]; Shoe[J] := T;
  End;
  ShoePos := 0;
End;

Function NextCard : LongInt;
Begin
  If ShoePos >= ShoeN Then ShuffleShoe;
  NextCard := Shoe[ShoePos];
  Inc(ShoePos);
End;

{ total des N premieres cartes d'une main }
Function Total(Var H : THand3; N : LongInt) : LongInt;
Var I, T : LongInt;
Begin
  T := 0;
  For I := 0 To N - 1 Do T := T + BVal(H[I]);
  Total := T Mod 10;
End;

{ tableau du Banquier quand le Joueur a tire sa troisieme carte (valeur P3) }
Function BankerDraws(BT, P3 : LongInt) : Boolean;
Begin
  Case BT Of
    0, 1, 2 : BankerDraws := True;
    3 : BankerDraws := P3 <> 8;
    4 : BankerDraws := (P3 >= 2) And (P3 <= 7);
    5 : BankerDraws := (P3 >= 4) And (P3 <= 7);
    6 : BankerDraws := (P3 = 6) Or (P3 = 7);
  Else
    BankerDraws := False;
  End;
End;

{ nombre de cartes deja montrees de chaque main }
Function ShownP : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To Shown - 1 Do If Order[I] < 10 Then Inc(N);
  ShownP := N;
End;

Function ShownB : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To Shown - 1 Do If Order[I] >= 10 Then Inc(N);
  ShownB := N;
End;

{ le coup entier est tire d'avance ; les cartes sont montrees une a une }
Procedure PlayCoup;
Var PT, BT, P3 : LongInt;
Begin
  If ShoePos > ShoeN - 12 Then ShuffleShoe;
  PC[0] := NextCard; BC[0] := NextCard; PC[1] := NextCard; BC[1] := NextCard;
  NP := 2; NB := 2;
  Order[0] := 0; Order[1] := 10; Order[2] := 1; Order[3] := 11; NOrd := 4;
  PT := Total(PC, 2); BT := Total(BC, 2);
  If (PT < 8) And (BT < 8) Then
  Begin
    P3 := -1;
    If PT <= 5 Then
    Begin
      PC[2] := NextCard; NP := 3; P3 := BVal(PC[2]);
      Order[NOrd] := 2; Inc(NOrd);
    End;
    If ((P3 < 0) And (BT <= 5)) Or ((P3 >= 0) And BankerDraws(BT, P3)) Then
    Begin
      BC[2] := NextCard; NB := 3;
      Order[NOrd] := 12; Inc(NOrd);
    End;
  End;
  Shown := 0;
End;

Function SideName(W : LongInt) : String;
Begin
  Case W Of
    0 : SideName := 'Joueur';
    1 : SideName := 'Banquier';
  Else
    SideName := Chr(144) + 'galit' + Chr(130);
  End;
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

{ carte dont le coin haut gauche est (X, Y) (Y vers le bas) }
Procedure CardAt(X, Y, C : LongInt; Face : Boolean);
Var Yb : LongInt;
Begin
  Yb := CH - Y - CardH;
  If Face Then DrawFace(Hps, X, Yb, C, False) Else DrawBack(Hps, X, Yb);
End;

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure CenterTxt(X0, W, Y : LongInt; S : String; Fg : LongInt);
Begin
  OutTxt(X0 + (W - Length(S) * 8) Div 2, Y, S, Fg, CLR_DARKGREEN);
End;

{ jeton de casino (Y vers le bas) }
Procedure Chip(Cx, Cy, V : LongInt);
Var C, K : LongInt;
Begin
  If V >= 500 Then C := CLR_PINK Else If V >= 100 Then C := CLR_BLACK Else If V >= 50 Then C := CLR_BLUE
  Else If V >= 25 Then C := CLR_DARKGREEN Else C := CLR_RED;
  Disc(Cx + 1, Cy + 2, 15, CLR_BLACK);
  Disc(Cx, Cy, 15, C);
  For K := 0 To 7 Do
    FBar(Cx - 2 + (13 * (K Mod 3 - 1)) * Ord(K < 6), Cy - 14 + (K Div 3) * 12, Cx + 1 + (13 * (K Mod 3 - 1)) * Ord(K < 6),
         Cy - 13 + (K Div 3) * 12, CLR_WHITE);
  Disc(Cx, Cy, 10, CLR_WHITE);
  Disc(Cx, Cy, 9, C);
  If C = CLR_BLACK Then OutTxt(Cx - Length(IStr(V)) * 4, Cy - 8, IStr(V), CLR_WHITE, C)
  Else OutTxt(Cx - Length(IStr(V)) * 4, Cy - 8, IStr(V), CLR_WHITE, C);
End;

Function ZoneX(Z : LongInt) : LongInt;
Begin
  ZoneX := TX + 15 + Z * (ZoneW + 10);
End;

Procedure DrawZone(Z : LongInt);
Var X, Fg, Bg : LongInt; S, Pay : String;
Begin
  X := ZoneX(Z);
  If BetOn = Z Then Bg := CLR_GREEN Else Bg := CLR_DARKGREEN;
  If BetOn = Z Then Fg := CLR_BLACK Else Fg := CLR_WHITE;
  If (Phase = 2) And (Winner = Z) Then Fg := CLR_YELLOW;
  FBar(X, ZoneY, X + ZoneW - 1, ZoneY + ZoneH - 1, Bg);
  Edge(X, ZoneY, X + ZoneW - 1, ZoneY + ZoneH - 1, CLR_YELLOW, CLR_YELLOW);
  Edge(X + 2, ZoneY + 2, X + ZoneW - 3, ZoneY + ZoneH - 3, CLR_YELLOW, CLR_YELLOW);
  Case Z Of
    0 : Begin S := 'JOUEUR'; Pay := '1 pour 1'; End;
    1 : Begin S := 'BANQUIER'; Pay := '0,95 pour 1'; End;
  Else
    Begin S := Chr(144) + 'GALIT' + Chr(144); Pay := '8 pour 1'; End;
  End;
  OutTxt(X + (ZoneW - Length(S) * 8) Div 2, ZoneY + 8, S, Fg, Bg);
  If BetOn = Z Then OutTxt(X + (ZoneW - Length(Pay) * 8) Div 2, ZoneY + 26, Pay, CLR_DARKGREEN, Bg)
  Else OutTxt(X + (ZoneW - Length(Pay) * 8) Div 2, ZoneY + 26, Pay, CLR_PALEGRAY, Bg);
  OutTxt(X + 6, ZoneY + ZoneH - 20, IStr(Z + 1), CLR_PALEGRAY, Bg);
  If BetOn = Z Then
  Begin
    If Phase = 0 Then Chip(X + ZoneW Div 2, ZoneY + 62, Bet) Else Chip(X + ZoneW Div 2, ZoneY + 62, Staked);
  End;
End;

{ une main : titre, cartes montrees, total }
Procedure DrawHand(X0 : LongInt; Var H : THand3; N : LongInt; S : String; Side : LongInt);
Var I, W, T, Fg : LongInt;
Begin
  W := TW Div 2;
  If (Phase = 2) And (Winner = Side) Then Fg := CLR_YELLOW Else Fg := CLR_WHITE;
  CenterTxt(X0, W, TY + 10, S, Fg);
  If N = 0 Then
  Begin
    For I := 0 To 1 Do
      Edge(X0 + 34 + I * CStep, HandY, X0 + 34 + I * CStep + CardW - 1, HandY + CardH - 1, CLR_GREEN, CLR_GREEN);
    Exit;
  End;
  For I := 0 To N - 1 Do CardAt(X0 + 34 + I * CStep, HandY, H[I], True);
  T := Total(H, N);
  { pastille du total }
  Disc(X0 + W Div 2, HandY + CardH + 26, 17, CLR_BLACK);
  Disc(X0 + W Div 2, HandY + CardH + 26, 15, CLR_WHITE);
  BigText(X0 + W Div 2 - 7, HandY + CardH + 10, IStr(T), CLR_DARKBLUE, CLR_WHITE);
  If (N = 2) And (T >= 8) Then CenterTxt(X0, W, HandY + CardH + 46, 'Naturel', CLR_YELLOW);
End;

Procedure DrawTable;
Var S : String; P, B : LongInt;
Begin
  FBar(TX, TY, TX + TW - 1, TY + THt - 1, CLR_DARKGREEN);
  Edge(TX - 2, TY - 2, TX + TW + 1, TY + THt + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(TX - 1, TY - 1, TX + TW, TY + THt, CLR_BLACK, CLR_PALEGRAY);
  FBar(TX + TW Div 2, TY + 8, TX + TW Div 2, TY + 200, CLR_GREEN);
  If Phase = 0 Then
  Begin
    P := 0; B := 0;
  End
  Else
  Begin
    P := ShownP; B := ShownB;
  End;
  DrawHand(TX, PC, P, 'JOUEUR', 0);
  DrawHand(TX + TW Div 2, BC, B, 'BANQUIER', 1);
  If Phase = 2 Then
  Begin
    If Winner = 2 Then S := Chr(144) + 'GALIT' + Chr(144) Else S := SideName(Winner) + ' gagne';
    FBar(TX + 20, TY + 206, TX + TW - 21, TY + 252, CLR_DARKGREEN);
    BigText(TX + (TW - Length(S) * 16) Div 2, TY + 206, S, CLR_YELLOW, CLR_DARKGREEN);
    If Gain > Staked Then S := 'Vous gagnez ' + Dollars(Gain - Staked)
    Else If Gain = Staked Then S := 'Mise rendue (' + Dollars(Staked) + ')'
    Else S := 'Vous perdez ' + Dollars(Staked);
    CenterTxt(TX, TW, TY + 240, S, CLR_WHITE);
  End
  Else If Phase = 0 Then
  Begin
    CenterTxt(TX, TW, TY + 214, 'Choisissez une case (1, 2, 3), la mise (+ -),', CLR_WHITE);
    CenterTxt(TX, TW, TY + 232, 'puis Distribuer (Espace).', CLR_YELLOW);
  End;
  DrawZone(0); DrawZone(1); DrawZone(2);
  CenterTxt(TX, TW, ZoneY + ZoneH + 6, 'Sabot de ' + IStr(NDecks) + ' jeux : ' + IStr(ShoeN - ShoePos) + ' cartes',
            CLR_PALEGRAY);
End;

Procedure DrawPanel;
Var S : String; I, C, X, Y : LongInt;
Begin
  BigText(PnX + (PW - 8 * 16) Div 2, TY + 2, 'BACCARAT', CLR_DARKRED, CLR_PALEGRAY);
  OutTxt(PnX, TY + 40, 'Votre argent', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, TY + 58, PnX + PW - 1, TY + 98, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, TY + 59, PnX + PW - 2, TY + 97, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, TY + 60, PnX + PW - 3, TY + 96, CLR_WHITE);
  S := Dollars(Money);
  BigText(PnX + PW - 8 - Length(S) * 16, TY + 62, S, CLR_DARKGREEN, CLR_WHITE);
  OutTxt(PnX, TY + 106, 'Mise : ' + Dollars(Bet), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, TY + 124, 'Sur : ' + SideName(BetOn), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, TY + 142, 'Coups : ' + IStr(Hands), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, TY + 160, 'Gagn' + Chr(130) + 's : ' + IStr(Won), CLR_BLACK, CLR_PALEGRAY);
  Button(PnX, TY + 184, 68, 28, 'Mise -', Phase <> 1);
  Button(PnX + 72, TY + 184, 68, 28, 'Mise +', Phase <> 1);
  Button(PnX, TY + 218, PW, 30, 'Distribuer', Phase <> 1);
  Button(PnX, TY + 254, PW, 30, 'Nouvelle partie', True);
  { historique des coups : J bleu, B rouge, E vert }
  OutTxt(PnX, TY + 292, 'Derniers coups', CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX, TY + 310, PnX + PW - 1, TY + 380, CLR_WHITE);
  Edge(PnX, TY + 310, PnX + PW - 1, TY + 380, CLR_DARKGRAY, CLR_WHITE);
  For I := 0 To NHist - 1 Do
  Begin
    X := PnX + 12 + (I Mod 6) * 23; Y := TY + 323 + (I Div 6) * 22;
    Case Hist[I] Of
      0 : C := CLR_BLUE;
      1 : C := CLR_RED;
    Else
      C := CLR_DARKGREEN;
    End;
    Disc(X, Y, 8, C);
    S := Copy('JBE', Hist[I] + 1, 1);
    OutTxt(X - 3, Y - 8, S, CLR_WHITE, C);
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
  SetMark(CM_PLAYER, BetOn = 0); SetMark(CM_BANKER, BetOn = 1); SetMark(CM_TIE, BetOn = 2);
  SetMark(CM_FAST, Fast <> 0);
End;

Procedure NewGame;
Begin
  Money := StartMoney; Bet := 50; Hands := 0; Won := 0; Phase := 0; NHist := 0; NP := 0; NB := 0;
  ShuffleShoe;
  Msg := 'Nouvelle partie : vous avez ' + Dollars(Money) + '. Misez sur le Joueur, le Banquier ou l''' +
         Chr(130) + 'galit' + Chr(130) + '.';
  Redraw;
End;

Procedure ChooseSide(Z : LongInt);
Begin
  If Phase = 1 Then Exit;
  BetOn := Z;
  If Phase = 2 Then Phase := 0;
  SetMarks;
  Msg := 'Vous misez ' + Dollars(Bet) + ' sur : ' + SideName(Z) + '.';
  Redraw;
End;

Procedure ChangeBet(D : LongInt);
Var Nb : LongInt;
Begin
  If Phase = 1 Then Exit;
  Nb := Bet + D;
  If Nb < 10 Then Nb := 10;
  If Nb > Money Then Nb := Money;
  If Nb < 10 Then Nb := 10;
  If Nb = Bet Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  Bet := Nb;
  If Phase = 2 Then Phase := 0;
  Msg := 'Mise : ' + Dollars(Bet) + ' sur : ' + SideName(BetOn) + '.';
  Redraw;
End;

Procedure Settle;
Var PT, BT, K : LongInt;
Begin
  PT := Total(PC, NP); BT := Total(BC, NB);
  If PT > BT Then Winner := 0 Else If BT > PT Then Winner := 1 Else Winner := 2;
  Gain := 0;
  If BetOn = Winner Then
  Begin
    Case Winner Of
      0 : Gain := 2 * Staked;
      1 : Gain := Staked + (Staked * 95) Div 100;
    Else
      Gain := 9 * Staked;
    End;
  End
  Else If Winner = 2 Then Gain := Staked;        { egalite : mises Joueur et Banquier rendues }
  Money := Money + Gain;
  Inc(Hands);
  If Gain > Staked Then Inc(Won);
  If NHist = 18 Then
  Begin
    For K := 0 To 16 Do Hist[K] := Hist[K + 1];
    NHist := 17;
  End;
  Hist[NHist] := Winner; Inc(NHist);
  Phase := 2;
  Msg := 'Joueur ' + IStr(PT) + ', Banquier ' + IStr(BT) + ' : ';
  If Winner = 2 Then Msg := Msg + Chr(130) + 'galit' + Chr(130) + '. ' Else Msg := Msg + SideName(Winner) + ' gagne. ';
  If Gain > Staked Then Msg := Msg + 'Vous gagnez ' + Dollars(Gain - Staked) + ' !'
  Else If Gain = Staked Then Msg := Msg + 'Votre mise est rendue.'
  Else Msg := Msg + 'Vous perdez ' + Dollars(Staked) + '.';
  If Bet > Money Then Bet := Money;
  If Bet < 10 Then Bet := 10;
  Redraw;
  If Money < 10 Then
  Begin
    If Ask('Vous ' + Chr(136) + 'tes ruin' + Chr(130) + ' apr' + Chr(138) + 's ' + IStr(Hands) + ' coups.' + Chr(10) +
           Chr(10) + 'Nouvelle partie ?', 'Baccarat', MB_YESNO Or MB_QUERY) = MBID_YES Then NewGame;
  End;
End;

Procedure Deal;
Begin
  If Phase = 1 Then Exit;
  If Bet > Money Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Msg := 'Mise trop forte : vous avez ' + Dollars(Money) + '.';
    Redraw;
    Exit;
  End;
  Money := Money - Bet; Staked := Bet;
  PlayCoup;
  Phase := 1;
  Msg := 'Distribution : ' + Dollars(Staked) + ' sur : ' + SideName(BetOn) + '...';
  If Fast <> 0 Then
  Begin
    Shown := NOrd;
    Settle;
  End
  Else Redraw;
End;

Procedure TimerTick;
Begin
  If Phase <> 1 Then Exit;
  If Shown < NOrd Then
  Begin
    Inc(Shown);
    Redraw;
  End
  Else Settle;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_DEAL : Deal;
    CM_PLAYER : ChooseSide(0);
    CM_BANKER : ChooseSide(1);
    CM_TIE : ChooseSide(2);
    CM_MORE : ChangeBet(10);
    CM_LESS : ChangeBet(-10);
    CM_FAST :
      Begin
        Fast := 1 - Fast;
        SetMarks;
      End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        LClr;
        LAdd('Misez sur le Joueur (paye 1 pour 1), le Banquier (paye 0,95 pour 1 : 5 % de commission) ou l''' +
             Chr(130) + 'galit' + Chr(130) + ' (paye 8 pour 1 ; sur une ' + Chr(130) + 'galit' + Chr(130) +
             ', les mises Joueur et Banquier sont rendues).' + Chr(10) + Chr(10));
        LAdd('Chaque main re' + Chr(135) + 'oit deux cartes. L''as vaut 1, le 10 et les figures 0, les autres ' +
             'cartes leur valeur ; seul le chiffre des unit' + Chr(130) + 's compte (15 = 5). ');
        LAdd('Un 8 ou un 9 sur deux cartes est un naturel : le coup s''arr' + Chr(136) + 'te. Sinon le Joueur ' +
             'tire une troisi' + Chr(138) + 'me carte avec 0 ' + Chr(133) + ' 5 ; le Banquier tire avec 0 ' + Chr(133) +
             ' 2, ou selon la troisi' + Chr(138) + 'me carte du Joueur ');
        LAdd('(3 : sauf un 8 ; 4 : 2 ' + Chr(133) + ' 7 ; 5 : 4 ' + Chr(133) + ' 7 ; 6 : 6 ou 7), ou avec 0 ' +
             Chr(133) + ' 5 si le Joueur n''a pas tir' + Chr(130) + '. La main la plus proche de 9 gagne.' +
             Chr(10) + Chr(10));
        LAdd('Clavier : 1, 2, 3 (case de mise), + et - (mise), Espace ou Entr' + Chr(130) + 'e (distribuer), ' +
             'F2 (nouvelle partie). Souris : les cases du tapis et les boutons.');
        Dummy := LMsgBox('Baccarat - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Baccarat pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'BACCARAT.PAS de 7iles (Turbo Pascal et BGI).' + Chr(10) +
                            'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                            'A propos de Baccarat', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Procedure Click(Mx, My : LongInt);
Var X, Y, Z : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  For Z := 0 To 2 Do
    If (X >= ZoneX(Z)) And (X < ZoneX(Z) + ZoneW) And (Y >= ZoneY) And (Y < ZoneY + ZoneH) Then
    Begin
      ChooseSide(Z);
      Exit;
    End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= TY + 184) And (Y < TY + 212) Then
    Begin
      If X < PnX + 70 Then ChangeBet(-10) Else ChangeBet(10);
    End
    Else If (Y >= TY + 218) And (Y < TY + 248) Then Deal
    Else If (Y >= TY + 254) And (Y < TY + 284) Then NewGame;
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
  If (Fl And (KC_CTRL Or KC_ALT)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Deal; Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case Chr(Ch) Of
      '1' : ChooseSide(0);
      '2' : ChooseSide(1);
      '3' : ChooseSide(2);
      '+', '=' : ChangeBet(10);
      '-', '_' : ChangeBet(-10);
      ' ' : Deal;
      'n', 'N' : NewGame;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
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

Var
  Fl, H0, H1, H2, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Fast := 0; BetOn := 0;
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
  Dummy := WinRegisterClass(Hab, Z('BACCARAT'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('BACCARAT'), Z2('Baccarat'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_DEAL, '~Distribuer' + Chr(9) + 'Espace');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, MIA_CHECKED, CM_PLAYER, 'Miser sur le ~Joueur' + Chr(9) + '1');
  MItem(MIS_TEXT, 0, CM_BANKER, 'Miser sur le ~Banquier' + Chr(9) + '2');
  MItem(MIS_TEXT, 0, CM_TIE, 'Miser sur l''' + Chr(144) + '~galit' + Chr(130) + Chr(9) + '3');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_MORE, '~Augmenter la mise' + Chr(9) + '+');
  MItem(MIS_TEXT, 0, CM_LESS, 'D~iminuer la mise' + Chr(9) + '-');
  MItem(MIS_TEXT, 0, CM_FAST, 'Donne ~rapide');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 12);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Baccarat');
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
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 450);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
