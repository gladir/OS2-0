{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: KLONDIKE - jeu de patience Klondike (solitaire) pour le
                Presentation Manager d'OS/2-0.
}

Program KLONDIKE;

{$R-,S-,I-}

{ Compilation : OS2PC KLONDIKE.PAS   (produit KLONDIKE.EXE)

  Patience Klondike (le jeu de cartes traditionnel), du dossier Jeux du
  bureau (Systeme OS/2, Jeux) : 52 cartes, une pioche, une defausse,
  quatre fondations (de l'as au roi, par couleur) et sept colonnes (cartes
  descendantes, rouges et noires en alternance ; seul un roi va dans une
  colonne vide).

  Souris : cliquer la pioche retourne une carte (ou trois, selon les
  options) ; glisser une carte (et celles qui la recouvrent) vers une
  colonne ou une fondation, ou cliquer la carte puis sa destination ;
  double clic : la carte va sur sa fondation ; une carte cachee au bas
  d'une colonne se retourne d'un clic.
  Clavier : F2 nouvelle partie, Ctrl+Z annuler, F1 regles.
  Parametre : /SEED:n (donne reproductible, pour les essais).
  Score (comme les patiences habituelles) : vers une fondation +10,
  defausse vers une colonne +5, carte retournee +5, d'une fondation vers
  une colonne -15, pioche recyclee (tirage de 1 carte) -100. }

Const
  WM_CREATE = $0001; WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_CLOSE = $0029;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
  WM_CHAR = $007A; WM_QUIT = $002A;
  WS_VISIBLE = $80000000;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MENU = 4; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20;
  FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_KEYUP = $40; KC_CHAR = 1;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_YELLOW = 6; CLR_DARKGRAY = 8;
  CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12; CLR_DARKCYAN = 13; CLR_PALEGRAY = 15; CLR_GREEN = 4;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  { commandes }
  CM_NEW = 101; CM_UNDO = 102; CM_AUTO = 103; CM_QUIT = 104; CM_DRAW1 = 201; CM_DRAW3 = 202;
  CM_RULES = 301; CM_ABOUT = 302;
  { piles : pioche, defausse, fondations 2 a 5, colonnes 6 a 12 }
  P_STOCK = 0; P_WASTE = 1; P_FOUND = 2; P_TAB = 6; NPile = 13;
  CardW = 70; CardH = 96;
  MaxUndo = 60;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH : LongInt;
  { etat du jeu : cartes et faces (pile * 52 + rang), nombre de cartes
    des piles, score, coups ; copies pour Annuler }
  Cards, Up : Array[0..NPile * 52 - 1] Of Byte;
  PN : Array[0..NPile - 1] Of LongInt;
  Score, Moves : LongInt;
  UCards, UUp : Array[0..MaxUndo * NPile * 52 - 1] Of Byte;
  UN : Array[0..MaxUndo * NPile - 1] Of LongInt;
  UScore, UMoves : Array[0..MaxUndo - 1] Of LongInt;
  NUndo : LongInt;
  Draw3 : Boolean;
  SelPile, SelIdx : LongInt;          { carte choisie (-1) }
  DragPile, DragIdx, DownX, DownY : LongInt;
  Won : Boolean;
  NameZ, NameZ2, TxtBuf : Array[0..511] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  Seed : LongInt;

{ --- PMWIN.DLL, PMGPI.DLL, DOSCALLS.DLL --- }
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
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Procedure WrB(A, V : LongInt);
Type PByte = ^Byte;
Var Q : PByte;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
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

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
End;

Function Rnd(N : LongInt) : LongInt;
Begin
  Seed := (Seed * 1103515245 + 12345) And $7FFFFFFF;
  Rnd := (Seed Shr 8) Mod N;
End;

Procedure ShowMsg(Text, Cap : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
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

{ position de la pile P (coin bas gauche de sa premiere carte) }
Procedure PileXY(P : LongInt; Var X, Y : LongInt);
Var Gap : LongInt;
Begin
  Gap := (CW - 7 * CardW) Div 8;
  Y := CH - 10 - CardH;
  If P = P_STOCK Then X := Gap
  Else If P = P_WASTE Then X := Gap * 2 + CardW
  Else If P < P_TAB Then X := Gap + (P - P_FOUND + 3) * (CardW + Gap)
  Else
  Begin
    X := Gap + (P - P_TAB) * (CardW + Gap);
    Y := CH - 10 - CardH - CardH - 16;
  End;
End;

{ decalage vertical entre les cartes d'une colonne (resserre si elle est
  longue) : cachees, visibles }
Procedure ColStep(P : LongInt; Var DDown, DUp : LongInt);
Var NDown, NUp, Avail, X, Y : LongInt;
Begin
  DDown := 6; DUp := 18;
  NDown := 0; NUp := 0;
  For X := 0 To PN[P] - 2 Do
    If Up[(P) * 52 + X] <> 0 Then Inc(NUp) Else Inc(NDown);
  PileXY(P, X, Y);
  Avail := Y - 26;
  If NDown * DDown + NUp * DUp > Avail Then
    If NUp > 0 Then DUp := MaxI(8, (Avail - NDown * DDown) Div NUp);
End;

{ coin bas gauche de la carte I de la pile P }
Procedure CardXY(P, I : LongInt; Var X, Y : LongInt);
Var K, DDown, DUp, Base : LongInt;
Begin
  PileXY(P, X, Y);
  If P >= P_TAB Then
  Begin
    ColStep(P, DDown, DUp);
    For K := 0 To I - 1 Do
      If Up[(P) * 52 + K] <> 0 Then Y := Y - DUp Else Y := Y - DDown;
  End
  Else If (P = P_WASTE) And Draw3 Then
  Begin
    Base := MaxI(0, PN[P] - 3);
    If I > Base Then X := X + (I - Base) * 16;
  End;
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

Procedure DrawEmpty(Hps, X, Y : LongInt; S : String);
Begin
  GBox(Hps, X, Y, X + CardW - 1, Y + CardH - 1, CLR_GREEN, DRO_OUTLINE, 10);
  GBox(Hps, X + 1, Y + 1, X + CardW - 2, Y + CardH - 2, CLR_GREEN, DRO_OUTLINE, 10);
  If S <> '' Then TextXY(Hps, X + CardW Div 2 - Length(S) * 4, Y + CardH Div 2 - 8, S, CLR_GREEN, CLR_DARKGREEN);
End;

Procedure PaintAll(H : LongInt);
Var Hps, P, I, X, Y, First : LongInt; Rc : Array[0..3] Of LongInt; S : String;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  If Hps = 0 Then Exit;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_DARKGREEN);
  For P := 0 To NPile - 1 Do
  Begin
    PileXY(P, X, Y);
    If PN[P] = 0 Then
    Begin
      If P = P_STOCK Then DrawEmpty(Hps, X, Y, 'O')
      Else If (P >= P_FOUND) And (P < P_TAB) Then DrawEmpty(Hps, X, Y, Chr(3 + P - P_FOUND))
      Else DrawEmpty(Hps, X, Y, '');
    End
    Else
    Begin
      First := 0;
      If P < P_TAB Then
      Begin
        First := PN[P] - 1;
        If (P = P_WASTE) And Draw3 Then First := MaxI(0, PN[P] - 3);
      End;
      For I := First To PN[P] - 1 Do
      Begin
        CardXY(P, I, X, Y);
        If Up[(P) * 52 + I] <> 0 Then DrawFace(Hps, X, Y, Cards[(P) * 52 + I], (P = SelPile) And (I >= SelIdx))
        Else DrawBack(Hps, X, Y);
      End;
    End;
  End;
  S := 'Score : ' + IStr(Score) + '    Coups : ' + IStr(Moves) + '    Pioche : ' + IStr(PN[P_STOCK]);
  If Draw3 Then S := S + '    (tirage de 3 cartes)' Else S := S + '    (tirage de 1 carte)';
  TextXY(Hps, 8, 4, S, CLR_WHITE, CLR_DARKGREEN);
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 1);
End;

{ ==================================================================== }
{ Regles                                                                }
{ ==================================================================== }

{ copie de l'etat S (0..MaxUndo-1) vers l'etat D ; -1 : etat courant }
Procedure CopyState(Src, Dst : LongInt);
Var K, A, B : LongInt;
Begin
  For K := 0 To NPile * 52 - 1 Do
  Begin
    If Src < 0 Then
    Begin
      A := Cards[K]; B := Up[K];
    End
    Else
    Begin
      A := UCards[Src * NPile * 52 + K]; B := UUp[Src * NPile * 52 + K];
    End;
    If Dst < 0 Then
    Begin
      Cards[K] := A; Up[K] := B;
    End
    Else
    Begin
      UCards[Dst * NPile * 52 + K] := A; UUp[Dst * NPile * 52 + K] := B;
    End;
  End;
  For K := 0 To NPile - 1 Do
    If Src < 0 Then UN[Dst * NPile + K] := PN[K]
    Else If Dst < 0 Then PN[K] := UN[Src * NPile + K]
    Else UN[Dst * NPile + K] := UN[Src * NPile + K];
  If Src < 0 Then
  Begin
    UScore[Dst] := Score; UMoves[Dst] := Moves;
  End
  Else If Dst < 0 Then
  Begin
    Score := UScore[Src]; Moves := UMoves[Src];
  End
  Else
  Begin
    UScore[Dst] := UScore[Src]; UMoves[Dst] := UMoves[Src];
  End;
End;

Procedure SaveUndo;
Var K : LongInt;
Begin
  If NUndo >= MaxUndo Then
  Begin
    For K := 1 To MaxUndo - 1 Do CopyState(K, K - 1);
    NUndo := MaxUndo - 1;
  End;
  CopyState(-1, NUndo);
  Inc(NUndo);
End;

Procedure NewGame;
Var Deck : Array[0..51] Of LongInt; K, J, T, P : LongInt;
Begin
  For K := 0 To 51 Do Deck[K] := K;
  For K := 51 DownTo 1 Do
  Begin
    J := Rnd(K + 1);
    T := Deck[K]; Deck[K] := Deck[J]; Deck[J] := T;
  End;
  For P := 0 To NPile - 1 Do PN[P] := 0;
  K := 0;
  For P := 0 To 6 Do
    For J := 0 To P Do
    Begin
      Cards[(P_TAB + P) * 52 + J] := Deck[K];
      If J = P Then Up[(P_TAB + P) * 52 + J] := 1 Else Up[(P_TAB + P) * 52 + J] := 0;
      Inc(K);
    End;
  For P := 0 To 6 Do PN[P_TAB + P] := P + 1;
  While K < 52 Do
  Begin
    Cards[(P_STOCK) * 52 + PN[P_STOCK]] := Deck[K];
    Up[(P_STOCK) * 52 + PN[P_STOCK]] := 0;
    Inc(PN[P_STOCK]);
    Inc(K);
  End;
  Score := 0; Moves := 0;
  NUndo := 0; SelPile := -1; DragPile := -1; Won := False;
  Redraw;
End;

Function TopCard(P : LongInt) : LongInt;
Begin
  If PN[P] = 0 Then TopCard := -1 Else TopCard := Cards[(P) * 52 + PN[P] - 1];
End;

{ la carte C peut-elle aller sur la pile P (Count cartes deplacees) ? }
Function CanDrop(C, P, Count : LongInt) : Boolean;
Var T : LongInt;
Begin
  CanDrop := False;
  T := TopCard(P);
  If (P >= P_FOUND) And (P < P_TAB) Then
  Begin
    If Count <> 1 Then Exit;
    If T < 0 Then CanDrop := (Rank(C) = 0) And (Suit(C) = P - P_FOUND)
    Else CanDrop := (Suit(C) = Suit(T)) And (Rank(C) = Rank(T) + 1);
  End
  Else If P >= P_TAB Then
  Begin
    If T < 0 Then CanDrop := Rank(C) = 12
    Else CanDrop := (Up[(P) * 52 + PN[P] - 1] <> 0) And (IsRed(C) <> IsRed(T)) And (Rank(C) + 1 = Rank(T));
  End;
End;

Procedure CheckWin;
Var P, N : LongInt;
Begin
  N := 0;
  For P := P_FOUND To P_FOUND + 3 Do N := N + PN[P];
  If (N = 52) And Not Won Then
  Begin
    Won := True;
    Redraw;
    ShowMsg('Bravo, vous avez gagne ! Score : ' + IStr(Score) + ', en ' + IStr(Moves) + ' coups.', 'Klondike');
  End;
End;

{ deplacer les cartes From[Idx..] vers To }
Function MoveCards(From, Idx, Dest : LongInt) : Boolean;
Var Count, K : LongInt;
Begin
  MoveCards := False;
  If (From = Dest) Or (Idx < 0) Or (Idx >= PN[From]) Or (Up[(From) * 52 + Idx] = 0) Then Exit;
  Count := PN[From] - Idx;
  If (From < P_TAB) And (Count <> 1) Then Exit;
  If Not CanDrop(Cards[(From) * 52 + Idx], Dest, Count) Then Exit;
  SaveUndo;
  For K := 0 To Count - 1 Do
  Begin
    Cards[(Dest) * 52 + PN[Dest] + K] := Cards[(From) * 52 + Idx + K];
    Up[(Dest) * 52 + PN[Dest] + K] := 1;
  End;
  PN[Dest] := PN[Dest] + Count;
  PN[From] := Idx;
  { score }
  If (Dest >= P_FOUND) And (Dest < P_TAB) Then Score := Score + 10
  Else If From = P_WASTE Then Score := Score + 5
  Else If (From >= P_FOUND) And (From < P_TAB) Then Score := MaxI(0, Score - 15);
  { la carte cachee decouverte se retourne }
  If (From >= P_TAB) And (PN[From] > 0) And (Up[(From) * 52 + PN[From] - 1] = 0) Then
  Begin
    Up[(From) * 52 + PN[From] - 1] := 1;
    Score := Score + 5;
  End;
  Inc(Moves);
  MoveCards := True;
  SelPile := -1;
  Redraw;
  CheckWin;
End;

Procedure DealStock;
Var K, N : LongInt;
Begin
  SaveUndo;
  SelPile := -1;
  If PN[P_STOCK] = 0 Then
  Begin
    { la defausse redevient la pioche }
    If PN[P_WASTE] = 0 Then
    Begin
      Dec(NUndo);
      Exit;
    End;
    For K := PN[P_WASTE] - 1 DownTo 0 Do
    Begin
      Cards[(P_STOCK) * 52 + PN[P_STOCK]] := Cards[(P_WASTE) * 52 + K];
      Up[(P_STOCK) * 52 + PN[P_STOCK]] := 0;
      Inc(PN[P_STOCK]);
    End;
    PN[P_WASTE] := 0;
    If Not Draw3 Then Score := MaxI(0, Score - 100);
  End
  Else
  Begin
    If Draw3 Then N := MinI(3, PN[P_STOCK]) Else N := 1;
    For K := 1 To N Do
    Begin
      Cards[(P_WASTE) * 52 + PN[P_WASTE]] := Cards[(P_STOCK) * 52 + PN[P_STOCK] - 1];
      Up[(P_WASTE) * 52 + PN[P_WASTE]] := 1;
      Inc(PN[P_WASTE]);
      Dec(PN[P_STOCK]);
    End;
  End;
  Inc(Moves);
  Redraw;
End;

{ la carte du dessus de P va sur sa fondation }
Function ToFoundation(P : LongInt) : Boolean;
Var F : LongInt;
Begin
  ToFoundation := False;
  If (PN[P] = 0) Or ((P >= P_FOUND) And (P < P_TAB)) Or (P = P_STOCK) Then Exit;
  For F := P_FOUND To P_FOUND + 3 Do
    If CanDrop(TopCard(P), F, 1) Then
    Begin
      ToFoundation := MoveCards(P, PN[P] - 1, F);
      Exit;
    End;
End;

{ fin automatique : toutes les cartes vont aux fondations }
Procedure AutoFinish;
Var P, Again : LongInt;
Begin
  Repeat
    Again := 0;
    For P := P_WASTE To P_TAB + 6 Do
      If (P < P_FOUND) Or (P >= P_TAB) Then
        If ToFoundation(P) Then Inc(Again);
  Until (Again = 0) Or Won;
End;

{ pile et carte sous le point (X, Y) : P, I (-1 : rien) }
Procedure HitTest(X, Y : LongInt; Var P, I : LongInt);
Var K, Q, Cx, Cy, First : LongInt;
Begin
  P := -1; I := -1;
  For Q := 0 To NPile - 1 Do
  Begin
    PileXY(Q, Cx, Cy);
    If PN[Q] = 0 Then
    Begin
      If (X >= Cx) And (X < Cx + CardW) And (Y >= Cy) And (Y < Cy + CardH) Then
      Begin
        P := Q; I := -1;
      End;
    End
    Else
    Begin
      First := 0;
      If Q < P_TAB Then First := PN[Q] - 1;
      For K := First To PN[Q] - 1 Do
      Begin
        CardXY(Q, K, Cx, Cy);
        If (X >= Cx) And (X < Cx + CardW) And (Y >= Cy) And (Y < Cy + CardH) Then
        Begin
          P := Q; I := K;
        End;
      End;
    End;
  End;
End;

Procedure ButtonDown(X, Y : LongInt);
Var P, I : LongInt;
Begin
  HitTest(X, Y, P, I);
  DragPile := -1;
  If P < 0 Then
  Begin
    SelPile := -1;
    Redraw;
    Exit;
  End;
  If P = P_STOCK Then
  Begin
    DealStock;
    Exit;
  End;
  { carte cachee au bas d'une colonne : retournee }
  If (I >= 0) And (P >= P_TAB) And (I = PN[P] - 1) And (Up[(P) * 52 + I] = 0) Then
  Begin
    SaveUndo;
    Up[(P) * 52 + I] := 1;
    Score := Score + 5;
    Redraw;
    Exit;
  End;
  { une carte choisie et un clic sur une autre pile : deplacement }
  If (SelPile >= 0) And (P <> SelPile) Then
  Begin
    If Not MoveCards(SelPile, SelIdx, P) Then
    Begin
      SelPile := -1;
      Redraw;
    End;
    Exit;
  End;
  If (I >= 0) And (Up[(P) * 52 + I] <> 0) Then
  Begin
    DragPile := P; DragIdx := I; DownX := X; DownY := Y;
    Dummy := WinSetCapture(HWND_DESKTOP, Client);
  End;
End;

Procedure ButtonUp(X, Y : LongInt);
Var P, I : LongInt;
Begin
  Dummy := WinSetCapture(HWND_DESKTOP, 0);
  If DragPile < 0 Then Exit;
  HitTest(X, Y, P, I);
  If (P >= 0) And (P <> DragPile) Then
  Begin
    If Not MoveCards(DragPile, DragIdx, P) Then Redraw;
  End
  Else
  Begin
    { simple clic : la carte (et celles qui la recouvrent) est choisie }
    If (SelPile = DragPile) And (SelIdx = DragIdx) Then SelPile := -1
    Else
    Begin
      SelPile := DragPile; SelIdx := DragIdx;
    End;
    Redraw;
  End;
  DragPile := -1;
End;

Procedure DoUndo;
Begin
  If NUndo = 0 Then Exit;
  Dec(NUndo);
  CopyState(NUndo, -1);
  SelPile := -1; Won := False;
  Redraw;
End;

Procedure SetDraw(Three : Boolean);
Var M : LongInt;
Begin
  Draw3 := Three;
  M := WinWindowFromID(Frame, $8005);
  If Three Then
  Begin
    Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_DRAW3 Or ($10000), MIA_CHECKED Or (MIA_CHECKED Shl 16));
    Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_DRAW1 Or ($10000), MIA_CHECKED);
  End
  Else
  Begin
    Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_DRAW1 Or ($10000), MIA_CHECKED Or (MIA_CHECKED Shl 16));
    Dummy := WinSendMsg(M, MM_SETITEMATTR, CM_DRAW3 Or ($10000), MIA_CHECKED);
  End;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_UNDO : DoUndo;
    CM_AUTO : AutoFinish;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_DRAW1, CM_DRAW3 :
      Begin
        SetDraw(Id = CM_DRAW3);
        NewGame;
      End;
    CM_RULES : ShowMsg('Faites monter les quatre couleurs sur les fondations, de l''as au roi. Dans les colonnes, ' +
                       'posez une carte sur une carte de rang superieur et de couleur opposee ; seul un roi va dans ' +
                       'une colonne vide. Glissez les cartes, ou cliquez une carte puis sa destination ; double clic : ' +
                       'vers la fondation. F2 : nouvelle partie, Ctrl+Z : annuler.', 'Klondike - Regles');
    CM_ABOUT : ShowMsg('Klondike, patience pour OS/2-0 (Presentation Manager). Programme ecrit en Pascal et compile ' +
                       'par OS2PC.', 'A propos de Klondike');
  End;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; P, I : LongInt;
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
        ButtonDown(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := 1;
      End;
    WM_BUTTON1UP :
      Begin
        ButtonUp(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := 1;
      End;
    WM_BUTTON1DBLCLK :
      Begin
        HitTest(S16(Mp1), S16(Mp1 Shr 16), P, I);
        If P = P_STOCK Then DealStock
        Else If (P >= 0) And (I = PN[P] - 1) And (I >= 0) Then
          If Not ToFoundation(P) Then Redraw;
        DragPile := -1;
        MainProc := 1;
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CHAR :
      If (Lo16(Mp1) And KC_KEYUP) = 0 Then
      Begin
        If ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And (Hi16(Mp2) = VK_F2) Then NewGame
        Else If ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And (Hi16(Mp2) = VK_F1) Then Command(CM_RULES)
        Else If ((Lo16(Mp1) And KC_CTRL) <> 0) And ((Lo16(Mp2) = 26) Or (Lo16(Mp2) = Ord('z')) Or
                (Lo16(Mp2) = Ord('Z'))) Then DoUndo
        Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Var
  Fl, H0, H1, H2, H3, Sw, Sh, M : LongInt;
  Dt : Array[0..15] Of Byte;
  K, E : LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919 + Dt[4] * 104729;
  { /SEED:n : donne choisie (parties reproductibles) }
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
  End;
  Draw3 := False; NUndo := 0; SelPile := -1; DragPile := -1;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  Dummy := WinRegisterClass(Hab, Z('KLONDIKE'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('KLONDIKE'), Z2('Klondike'), 0, 0, 0,
                              LongInt(@Client));
  { barre de menus : Partie, Options, Aide }
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_TEXT, 0, CM_AUTO, '~Terminer automatiquement');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H2 := MenuOpen;
  MItem(MIS_TEXT, MIA_CHECKED, CM_DRAW1, 'Tirer ~1 carte');
  MItem(MIS_TEXT, 0, CM_DRAW3, 'Tirer ~3 cartes');
  MenuClose(H2, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~Regles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Klondike');
  MenuClose(H3, 2);
  MenuClose(H0, 3);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, 0, MaxI(0, Sh - 470), MinI(Sw, 640), MinI(Sh, 470),
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  NewGame;
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
